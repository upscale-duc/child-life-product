import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  CarePlanError,
  saveCarePlanItem,
  setCarePlanItemStatus,
  startCarePlanDay,
} from '../functions/src/care-plan.js';
import {
  onCarePlanItemDone,
  reactCarePlanItem,
  taskDoneCopy,
  thanksCopy,
} from '../functions/src/care-plan-thanks.js';
import type { PushSender } from '../functions/src/social.js';

// Cùng Chăm Con N2 / 10 / N3 against the Firestore emulator: who hears that a task is done, the
// hearts and thanks, and the push back to the one who did it. Hồ Chí Minh times on 6 Nov 2026.
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const babyId = 'b_cpt0000000000000000001';
const date = '2026-11-06';
const vn = (hh: number, mm = 0) => new Date(Date.UTC(2026, 10, 6, hh - 7, mm));
let run = 0;
const id = (n: number) => `pi_${(run * 16 + n).toString(16).padStart(32, 'd')}`;
const mom = 'cpt_mom';
const dad = 'cpt_dad';
const nanny = 'cpt_nanny';
const aunt = 'cpt_aunt';

const sent: ({ token: string } & Parameters<PushSender['send']>[1])[] = [];
const sender: PushSender = {
  async send(tokens, message) {
    for (const token of tokens) sent.push({ token, ...message });
    return [];
  },
};
const to = (uid: string) => sent.filter((s) => s.token === `t-${uid}`);
const item = (n: number) => db.doc(`babies/${babyId}/carePlanDays/${date}/items/${id(n)}`);

/** Saves task [n], ticks it as [by], and runs the N2 trigger on that write. */
async function done(n: number, task: string, by: string, at = vn(12)) {
  await saveCarePlanItem(
    db,
    mom,
    {
      babyId,
      date,
      itemId: id(n),
      task,
      title: null,
      time: '12:00',
      assignees: [by],
      scope: 'today',
    },
    vn(6),
  );
  const before = await item(n).get();
  await setCarePlanItemStatus(db, by, { babyId, date, itemId: id(n), status: 'done' }, at);
  return onCarePlanItemDone(db, sender, babyId, date, id(n), before, await item(n).get(), at);
}

beforeAll(() => {
  app = initializeApp({ projectId }, `care-plan-thanks-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  sent.length = 0;
  run += 1;
  await db.recursiveDelete(db.doc(`babies/${babyId}`)).catch(() => undefined);
  await db.doc(`babies/${babyId}`).set({
    nickname: 'Teddy',
    timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' },
  });
  for (const [uid, role, relation] of [
    [mom, 'coParent', 'mother'],
    [dad, 'coParent', 'father'],
    [nanny, 'caregiver', 'other'],
    [aunt, 'relative', 'other'],
  ] as const) {
    await db.doc(`babies/${babyId}/members/${uid}`).set({
      uid,
      babyId,
      role,
      status: 'active',
      displayName: uid,
      relation,
      relationCustom: uid === nanny ? 'Cô Lan' : null,
    });
    await db.doc(`users/${uid}/devices/d1`).set({ token: `t-${uid}`, language: 'vi' });
    await db.doc(`users/${uid}/settings/carePlan`).delete();
    await db.doc(`users/${uid}/settings/notifications`).delete();
    await db.recursiveDelete(db.collection(`users/${uid}/notifications`)).catch(() => undefined);
  }
  await startCarePlanDay(db, mom, { babyId, date, from: 'empty' }, vn(6));
});

describe('N2: a task done tells the other carers', () => {
  it('Mẹ, Cô Lan hear that Ba gave a bottle; never Ba, never a relative; no amounts', async () => {
    await done(1, 'bottle', dad);
    expect(to(dad)).toHaveLength(0);
    expect(to(aunt)).toHaveLength(0);
    expect(to(mom)).toHaveLength(1);
    expect(to(nanny)).toHaveLength(1);
    expect(to(mom)[0]).toMatchObject({
      title: 'Teddy no bụng rồi, nhờ có Ba đó!',
      body: 'Bú bình · Cảm ơn Ba nhé!',
      androidDraws: true,
      apns: { category: 'CL_CARE_DONE' },
    });
    expect(to(mom)[0]!.data).toMatchObject({
      kind: 'careTaskDone',
      destination: 'CARE_TASK_DONE',
      babyId,
      date,
      item: id(1),
    });
  });

  it('follows "Khi người khác làm xong" and "Hiện tên bé"; a past day says nothing', async () => {
    await db.doc(`users/${nanny}/settings/carePlan`).set({ team: false });
    await db.doc(`users/${mom}/settings/notifications`).set({ babyName: false });
    await done(1, 'bath', dad);
    expect(to(nanny)).toHaveLength(0);
    expect(to(mom)[0]!.title).toBe('Ba vừa tắm cho bé');
    sent.length = 0;
    // Ticked the next morning: tidying up, not news.
    await done(2, 'bath', dad, vn(24 + 8));
    expect(sent).toHaveLength(0);
  });
});

describe('10 / N3: hearts and thanks', () => {
  it('Mẹ sends a heart and a thanks; Ba hears it; hearts count once', async () => {
    await done(1, 'bath', dad);
    sent.length = 0;
    const r = await reactCarePlanItem(
      db,
      sender,
      mom,
      { babyId, date, itemId: id(1), heart: true, thanks: 'thanks' },
      vn(12, 5),
    );
    expect(r.hearts).toBe(1);
    expect(to(dad)).toHaveLength(1);
    expect(to(dad)[0]).toMatchObject({
      title: 'Mẹ thả tim cho Ba ❤️',
      body: '“Cảm ơn Ba đã tắm cho Teddy nha!”',
    });
    expect(to(dad)[0]!.data).toMatchObject({ kind: 'careThanks', destination: 'CARE_PLAN_READY' });
    // The same heart again: nothing new, nothing sent.
    const again = await reactCarePlanItem(
      db,
      sender,
      mom,
      { babyId, date, itemId: id(1), heart: true },
      vn(12, 6),
    );
    expect(again.hearts).toBe(1);
    expect(to(dad)).toHaveLength(1);
    expect((await item(1).get()).get(`reactions.${mom}`)).toMatchObject({
      heart: true,
      thanks: 'thanks',
    });
    const hearts = await db
      .collection(`babies/${babyId}/carePlanHistory`)
      .where('action', '==', 'heart')
      .get();
    expect(hearts.size).toBe(1);
  });

  it('never for a task not done, your own task, or a relative', async () => {
    await saveCarePlanItem(
      db,
      mom,
      {
        babyId,
        date,
        itemId: id(1),
        task: 'bath',
        title: null,
        time: '12:00',
        assignees: [dad],
        scope: 'today',
      },
      vn(6),
    );
    const react = (uid: string) =>
      reactCarePlanItem(db, sender, uid, { babyId, date, itemId: id(1), heart: true }, vn(12));
    await expect(react(mom)).rejects.toThrow(CarePlanError);
    await setCarePlanItemStatus(db, dad, { babyId, date, itemId: id(1), status: 'done' }, vn(12));
    await expect(react(dad)).rejects.toMatchObject({ reason: 'own-task' });
    await expect(react(aunt)).rejects.toMatchObject({ reason: 'not-allowed' });
  });
});

describe('copy', () => {
  it('names catalogue tasks and our own lines in both languages', () => {
    const ba = { vi: 'Ba', en: 'Dad' };
    const me = { vi: 'Mẹ', en: 'Mum' };
    expect(taskDoneCopy('sleep', ba, 'Teddy', 'vi').title).toBe('Ba vừa ru Teddy ngủ');
    expect(taskDoneCopy('breast', me, null, 'en').title).toBe(
      'Your baby’s tummy is full, thanks to Mum!',
    );
    expect(taskDoneCopy('custom', ba, 'Teddy', 'vi').body).toBe('Việc riêng · Cảm ơn Ba nhé!');
    expect(thanksCopy('bottle', true, null, me, ba, 'Teddy', 'en')).toEqual({
      title: 'Mum sent Dad a heart ❤️',
      body: '“Thanks for giving Teddy a bottle!”',
    });
    expect(thanksCopy('bath', false, 'proud', me, ba, 'Teddy', 'vi')).toEqual({
      title: 'Mẹ gửi lời cảm ơn Ba',
      body: '“Ba giỏi quá”',
    });
  });
});
