import {
  FieldPath,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
} from 'firebase-admin/firestore';
import {
  carePlanAssignable,
  carePlanCan,
  carePlanDidPhrases,
  carePlanPrefsOf,
  carePlanTaskNames,
  reactCarePlanItemSchema,
  type CarePlanTask,
  type CarePlanThanks,
} from '@child-life/contracts';
import { CarePlanError, dateKeyIn, editableDate } from './care-plan.js';
import { memberLabel } from './care-plan-reminders.js';
import { isActiveMember } from './family.js';
import { notifyUsers, type Language } from './notifications.js';
import type { PushSender } from './social.js';

/**
 * Cùng Chăm Con 10 Vừa xong, N2 and N3 (Figma 1353:22588 / 1353:22683, ANALYSIS §6.1):
 * - N2: a task done today tells the other carers ("Teddy no bụng rồi, nhờ có Mẹ đó!"), never the
 *   one who did it, without amounts (D-135 Q7), with "Thả tim" on the lock screen;
 * - 10: the others send a heart and / or a thanks (`reactions.{uid}` on the task; hearts stay);
 * - N3: the one who did it hears who thanked them ("Mẹ thả tim cho Ba ❤️").
 * Each person's "Khi người khác làm xong" (`settings/carePlan.team`, on by default) silences both.
 * Copy names catalogue tasks and our own thanks lines only, never a typed title; the baby's name
 * follows each recipient's "Hiện tên bé" (D-094). Nothing about the child is logged.
 */

type Label = { vi: string; en: string };

const fill = (s: string, values: Record<string, string>) =>
  s.replace(/\{(\w+)\}/g, (_, k: string) => values[k] ?? '');

const capitalized = (s: string) => s.charAt(0).toLocaleUpperCase('vi') + s.slice(1);

/** "Ba vừa tắm cho Teddy" / "Teddy no bụng rồi, nhờ có Mẹ đó!" with "Bú bình · Cảm ơn Mẹ nhé!". */
export function taskDoneCopy(
  task: CarePlanTask,
  doer: Label | null,
  baby: string | null,
  language: Language,
): { title: string; body: string } {
  const en = language === 'en';
  const who = doer?.[language] ?? (en ? 'Someone' : 'Cả nhà');
  const b = baby ?? (en ? 'your baby' : 'bé');
  const name = carePlanTaskNames[task][language];
  const fed = task === 'bottle' || task === 'breast';
  if (en) {
    return {
      title: fed
        ? `${capitalized(b)}’s tummy is full, thanks to ${who}!`
        : `${who} just ${fill(carePlanDidPhrases[task].en, { baby: b })}`,
      body: `${name} · Say thanks to ${who}!`,
    };
  }
  return {
    title: fed
      ? `${capitalized(b)} no bụng rồi, nhờ có ${who} đó!`
      : `${who} vừa ${fill(carePlanDidPhrases[task].vi, { baby: b })}`,
    body: `${name} · Cảm ơn ${who} nhé!`,
  };
}

/** "Mẹ thả tim cho Ba ❤️" · “Cảm ơn Ba đã tắm cho Teddy nha!” */
export function thanksCopy(
  task: CarePlanTask,
  heart: boolean,
  thanks: CarePlanThanks | null,
  from: Label | null,
  to: Label | null,
  baby: string | null,
  language: Language,
): { title: string; body: string } {
  const en = language === 'en';
  const actor = from?.[language] ?? (en ? 'Your family' : 'Cả nhà');
  const you = to?.[language] ?? (en ? 'you' : 'bạn');
  const b = baby ?? (en ? 'your baby' : 'bé');
  const did = fill(carePlanDidPhrases[task][language], { baby: b });
  const line = en
    ? {
        thanks: `Thanks for ${did.replace(/^(\w+)/, (v) => gerund[v] ?? v)}!`,
        great: `Great job, ${you}!`,
        thanksName: `Thank you, ${you}!`,
        proud: `You’re amazing, ${you}`,
        love: `Love you, ${you}`,
      }
    : {
        thanks: `Cảm ơn ${you} đã ${did} nha!`,
        great: `${capitalized(you)} tuyệt quá!`,
        thanksName: `Cảm ơn ${you}!`,
        proud: `${capitalized(you)} giỏi quá`,
        love: `Thương ${you}`,
      };
  const quote = line[thanks ?? 'thanks'];
  return {
    title: heart
      ? en
        ? `${actor} sent ${you} a heart ❤️`
        : `${actor} thả tim cho ${you} ❤️`
      : en
        ? `${actor} says thank you`
        : `${actor} gửi lời cảm ơn ${you}`,
    body: `“${quote}”`,
  };
}

/** "gave" → "giving" for "Thanks for giving Teddy a bottle!". */
const gerund: Record<string, string> = {
  gave: 'giving',
  breastfed: 'breastfeeding',
  pumped: 'pumping',
  fed: 'feeding',
  put: 'putting',
  changed: 'changing',
  did: 'doing',
  read: 'reading',
  took: 'taking',
  checked: 'checking',
  brushed: 'brushing',
  helped: 'helping',
};

/** The baby's name for [uid], or null when they turned "Hiện tên bé" off (D-094). */
async function babyNameFor(db: Firestore, uid: string, nickname: string | null) {
  if (!nickname) return null;
  const s = await db.doc(`users/${uid}/settings/notifications`).get();
  return s.get('babyName') === false ? null : nickname;
}

const nicknameOf = (baby: DocumentSnapshot) => {
  const n = baby.get('nickname');
  return typeof n === 'string' && n.trim() ? n.trim() : null;
};

/** Whether [uid] wants N2 / N3 ("Khi người khác làm xong"). */
async function wantsTeam(db: Firestore, uid: string) {
  return carePlanPrefsOf((await db.doc(`users/${uid}/settings/carePlan`).get()).data()).team;
}

/** N2, from the task's write (`onCarePlanItemWrite`): open → done, today, not a draft. */
export async function onCarePlanItemDone(
  db: Firestore,
  sender: PushSender | null,
  babyId: string,
  date: string,
  itemId: string,
  before: DocumentSnapshot | null,
  after: DocumentSnapshot | null,
  now: Date,
): Promise<{ sent: number }> {
  if (!after?.exists || after.get('status') !== 'done' || after.get('draft') === true) {
    return { sent: 0 };
  }
  if (before?.exists && before.get('status') === 'done') return { sent: 0 };
  const doer = after.get('doneBy') as string | null;
  const doneAt = after.get('doneAt');
  if (!doer || !(doneAt instanceof Timestamp)) return { sent: 0 };
  const baby = await db.doc(`babies/${babyId}`).get();
  if (!baby.exists || (baby.get('state') ?? 'active') !== 'active') return { sent: 0 };
  const zone = (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh';
  // Ticking off a past day is tidying up, not news.
  if (date !== dateKeyIn(zone, now)) return { sent: 0 };
  const members = await db.collection(`babies/${babyId}/members`).get();
  const doerDoc = members.docs.find((m) => m.id === doer);
  const doerLabel = memberLabel(doerDoc);
  const task = after.get('task') as CarePlanTask;
  const nickname = nicknameOf(baby);
  let sent = 0;
  for (const m of members.docs) {
    if (m.id === doer || !isActiveMember(m, now) || !carePlanAssignable(m.get('role'))) continue;
    if (!(await wantsTeam(db, m.id))) continue;
    const name = await babyNameFor(db, m.id, nickname);
    const result = await notifyUsers(
      db,
      sender,
      [m.id],
      {
        kind: 'careTaskDone',
        id: `cd-${itemId}-${doneAt.toMillis()}`,
        babyId,
        data: { babyId, date, item: itemId },
        message: (language) => ({
          ...taskDoneCopy(task, doerLabel, name, language),
          // Figma N2: "Thả tim" without opening the app (RuleNotifications.swift, Push.kt).
          // A newer task by the same person replaces this one on the lock screen.
          apns: {
            category: 'CL_CARE_DONE',
            collapseId: `cd-${babyId}-${doer}`,
            threadId: `ct-${babyId}`,
          },
          androidDraws: true,
        }),
        zone,
      },
      now,
    );
    sent += result.sent;
  }
  return { sent };
}

/** 10 Thả tim / Cảm ơn, then N3 to the one who did it. */
export async function reactCarePlanItem(
  db: Firestore,
  sender: PushSender | null,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ hearts: number }> {
  const parsed = reactCarePlanItemSchema.safeParse(data);
  if (!parsed.success) throw new CarePlanError('invalid-argument', 'invalid');
  const req = parsed.data;
  const ref = db.doc(`babies/${req.babyId}/carePlanDays/${req.date}/items/${req.itemId}`);
  const out = await db.runTransaction(async (tx) => {
    const [baby, me, item] = await Promise.all([
      tx.get(db.doc(`babies/${req.babyId}`)),
      tx.get(db.doc(`babies/${req.babyId}/members/${uid}`)),
      tx.get(ref),
    ]);
    if (!baby.exists || !item.exists) throw new CarePlanError('not-found', 'not-found');
    if (!isActiveMember(me, now) || !carePlanCan(me.get('role'), 'complete')) {
      throw new CarePlanError('permission-denied', 'not-allowed');
    }
    const zone = (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh';
    if (!editableDate(zone, req.date, now)) {
      throw new CarePlanError('failed-precondition', 'day-closed');
    }
    const doer = item.get('doneBy') as string | null;
    if (item.get('status') !== 'done' || !doer) {
      throw new CarePlanError('failed-precondition', 'not-done');
    }
    if (doer === uid) throw new CarePlanError('failed-precondition', 'own-task');
    const reactions = (item.get('reactions') as Record<string, Record<string, unknown>>) ?? {};
    const mine = reactions[uid] ?? {};
    const newHeart = req.heart && mine.heart !== true;
    const newThanks = req.thanks !== null && req.thanks !== mine.thanks;
    const hearts = (heart: boolean) =>
      Object.entries(reactions).filter(([u, r]) => u !== uid && r.heart === true).length +
      (heart ? 1 : 0);
    if (!newHeart && !newThanks) return { hearts: hearts(mine.heart === true), push: null };
    const at = Timestamp.fromDate(now);
    tx.update(ref, new FieldPath('reactions', uid), {
      heart: mine.heart === true || req.heart,
      thanks: req.thanks ?? (mine.thanks as string | undefined) ?? null,
      at,
    });
    if (newHeart) {
      // Báo cáo counts these ("tim"); 20 Lịch sử thay đổi leaves them out.
      tx.set(db.collection(`babies/${req.babyId}/carePlanHistory`).doc(), {
        at,
        by: uid,
        action: 'heart',
        date: req.date,
        itemIds: [req.itemId],
        task: item.get('task'),
        title: null,
        time: item.get('time'),
        scope: null,
        assignees: [doer],
        from: null,
        oldTime: null,
      });
    }
    return {
      hearts: hearts(mine.heart === true || req.heart),
      push: {
        doer,
        zone,
        task: item.get('task') as CarePlanTask,
        heart: newHeart,
        thanks: newThanks ? req.thanks : null,
        nickname: nicknameOf(baby),
      },
    };
  });
  const push = out.push;
  if (push && (await wantsTeam(db, push.doer))) {
    const [from, to, name] = await Promise.all([
      db.doc(`babies/${req.babyId}/members/${uid}`).get(),
      db.doc(`babies/${req.babyId}/members/${push.doer}`).get(),
      babyNameFor(db, push.doer, push.nickname),
    ]);
    await notifyUsers(
      db,
      sender,
      [push.doer],
      {
        kind: 'careThanks',
        id: `ch-${req.itemId}-${uid}-${now.getTime()}`,
        babyId: req.babyId,
        data: { babyId: req.babyId, date: req.date, item: req.itemId },
        message: (language) => ({
          ...thanksCopy(
            push.task,
            push.heart,
            push.thanks,
            memberLabel(from),
            memberLabel(to),
            name,
            language,
          ),
          // Several hearts for one task are one notice on the lock screen.
          apns: { collapseId: `ch-${req.itemId}`, threadId: `ct-${req.babyId}` },
        }),
        zone: push.zone,
      },
      now,
    );
  }
  return { hearts: out.hearts };
}
