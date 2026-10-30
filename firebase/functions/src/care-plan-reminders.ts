import {
  FieldPath,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
} from 'firebase-admin/firestore';
import {
  carePlanAssignable,
  carePlanGroupMinutes,
  carePlanPrefsOf,
  carePlanReminderLeads,
  carePlanTaskNames,
  type CarePlanTask,
} from '@child-life/contracts';
import { isActiveMember } from './family.js';
import { notifyUsers, type Language } from './notifications.js';
import type { PushSender } from './social.js';

/**
 * Cùng Chăm Con N1 (D-135, ANALYSIS §6.1): a task's assignees are pushed before it is due, by
 * their own "Nhắc trước" (5 / 10 / 15 minutes, or Tắt; 5 by default). One person's tasks less
 * than [carePlanGroupMinutes] apart ring as one push. Quiet hours hold it only for those who
 * turned "Nhắc cả trong giờ yên lặng" off (on by default, Q5).
 *
 * Idempotent per task + revision + person: a transaction writes `reminded.{uid} = revision` on
 * every task of the push before anything is sent, and the notice id names the first task and its
 * revision (the ledger dedups a retried run). Moving a task or changing its people bumps its
 * revision (`care-plan.ts`), so the new time or the new person is reminded again. Pushes carry
 * catalogue task names and times only; nothing about the child is logged.
 */

const MINUTE = 60_000;
const maxLead = Math.max(...carePlanReminderLeads);

interface Task {
  ref: DocumentSnapshot['ref'];
  id: string;
  babyId: string;
  date: string;
  task: CarePlanTask;
  time: string;
  dueAt: Date;
  revision: number;
  assignees: string[];
  reminded: Record<string, number>;
}

function taskOf(d: DocumentSnapshot): Task | null {
  // `items` is also an album sub-collection: only plan tasks (babies/*/carePlanDays/*/items/*).
  const day = d.ref.parent.parent;
  if (!day || day.parent.id !== 'carePlanDays') return null;
  const dueAt = d.get('dueAt');
  if (!(dueAt instanceof Timestamp)) return null;
  // A draft's tasks wait for "Dùng lịch này" (D-136 #3).
  if (d.get('draft') === true) return null;
  return {
    ref: d.ref,
    id: d.id,
    babyId: day.parent.parent!.id,
    date: day.id,
    task: d.get('task') as CarePlanTask,
    time: d.get('time') as string,
    dueAt: dueAt.toDate(),
    revision: (d.get('revision') as number | undefined) ?? 0,
    assignees: (d.get('assignees') as string[] | undefined) ?? [],
    reminded: (d.get('reminded') as Record<string, number> | undefined) ?? {},
  };
}

/** "09:00 Vitamin · 09:10 Bú bình" (N5's first task). */
export function taskLine(tasks: { task: CarePlanTask; time: string }[], language: Language) {
  return tasks.map((t) => `${t.time} ${carePlanTaskNames[t.task][language]}`).join(' · ');
}

/** "Vitamin · Bú bình" (Figma N1: the names, the title already says when). */
export function taskNames(tasks: { task: CarePlanTask }[], language: Language) {
  return tasks.map((t) => carePlanTaskNames[t.task][language]).join(' · ');
}

const relationLabels: Record<string, { vi: string; en: string }> = {
  mother: { vi: 'Mẹ', en: 'Mum' },
  father: { vi: 'Ba', en: 'Dad' },
  grandmother: { vi: 'Bà', en: 'Grandma' },
  grandfather: { vi: 'Ông', en: 'Grandpa' },
};

/** What the family calls a member ("Ba", "Cô Lan"); null when nothing is known. */
export function memberLabel(
  member: DocumentSnapshot | undefined,
): { vi: string; en: string } | null {
  if (!member?.exists) return null;
  const known = relationLabels[(member.get('relation') as string | undefined) ?? ''];
  if (known) return known;
  const own =
    (member.get('relationCustom') as string | undefined)?.trim() ||
    (member.get('displayName') as string | undefined)?.trim();
  return own ? { vi: own.slice(0, 40), en: own.slice(0, 40) } : null;
}

/** The built-in copy (template version 0): "Ba ơi, 5 phút nữa bé cần Ba rồi nè". */
export function careTaskCopy(
  tasks: { task: CarePlanTask; time: string }[],
  minutes: number,
  language: Language,
  person?: { vi: string; en: string } | null,
): { title: string; body: string } {
  if (language === 'en') {
    const lead = person ? `${person.en}, your` : 'Your';
    return { title: `${lead} baby needs you in ${minutes} min`, body: taskNames(tasks, 'en') };
  }
  const title = person
    ? `${person.vi} ơi, ${minutes} phút nữa bé cần ${person.vi} rồi nè`
    : `${minutes} phút nữa bé cần bạn rồi nè`;
  return { title, body: taskNames(tasks, 'vi') };
}

/** Tasks the app must open for (a log to write or the sleep timer, D-138); others are done from the lock screen. */
const opensApp = new Set<CarePlanTask>(['bottle', 'breast', 'pump', 'diaper', 'sleep']);

/** For each person, the tasks that ring now: the first one due within their lead, plus theirs
 * less than [carePlanGroupMinutes] after it that were not reminded yet. */
export function dueGroups(
  tasks: Task[],
  leadOf: (uid: string) => number,
  now: Date,
): Map<string, Task[]> {
  const out = new Map<string, Task[]>();
  const sorted = [...tasks].sort((a, b) => a.dueAt.getTime() - b.dueAt.getTime());
  const people = new Set(sorted.flatMap((t) => t.assignees));
  for (const uid of people) {
    const lead = leadOf(uid);
    if (lead <= 0) continue;
    const mine = sorted.filter(
      (t) => t.assignees.includes(uid) && t.reminded[uid] !== t.revision && t.dueAt > now,
    );
    const first = mine.find((t) => t.dueAt.getTime() - lead * MINUTE <= now.getTime());
    if (!first) continue;
    const until = first.dueAt.getTime() + carePlanGroupMinutes * MINUTE;
    out.set(
      uid,
      mine.filter((t) => t.dueAt >= first.dueAt && t.dueAt.getTime() < until),
    );
  }
  return out;
}

/** Every minute (`ringCareTaskReminders`): see the file comment. */
export async function ringCareTaskReminders(
  db: Firestore,
  sender: PushSender | null,
  now: Date,
): Promise<{ pushes: number; sent: number }> {
  // Far enough ahead for the longest lead plus a group after it.
  const snap = await db
    .collectionGroup('items')
    .where('status', '==', 'open')
    .where('dueAt', '>', Timestamp.fromDate(now))
    .where(
      'dueAt',
      '<=',
      Timestamp.fromMillis(now.getTime() + (maxLead + carePlanGroupMinutes) * MINUTE),
    )
    .limit(500)
    .get();
  const byBaby = new Map<string, Task[]>();
  for (const d of snap.docs) {
    const t = taskOf(d);
    if (!t || t.assignees.length === 0) continue;
    byBaby.set(t.babyId, [...(byBaby.get(t.babyId) ?? []), t]);
  }
  let pushes = 0;
  let sent = 0;
  for (const [babyId, tasks] of byBaby) {
    const baby = await db.doc(`babies/${babyId}`).get();
    if (!baby.exists || (baby.get('state') ?? 'active') !== 'active') continue;
    const zone = (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh';
    const people = [...new Set(tasks.flatMap((t) => t.assignees))];
    const [members, prefDocs] = await Promise.all([
      db.getAll(...people.map((u) => db.doc(`babies/${babyId}/members/${u}`))),
      db.getAll(...people.map((u) => db.doc(`users/${u}/settings/carePlan`))),
    ]);
    // Someone who left, or is now a relative (D-018), is not reminded.
    const prefs = new Map(
      people.map((u, i) => [
        u,
        isActiveMember(members[i]!, now) && carePlanAssignable(members[i]!.get('role'))
          ? carePlanPrefsOf(prefDocs[i]!.data())
          : null,
      ]),
    );
    const labels = new Map(people.map((u, i) => [u, memberLabel(members[i])]));
    const groups = dueGroups(tasks, (u) => prefs.get(u)?.leadMinutes ?? 0, now);
    for (const [uid, group] of groups) {
      const claimed = await db.runTransaction(async (tx) => {
        const fresh = await tx.getAll(...group.map((t) => t.ref));
        const keep = fresh
          .map((d) => (d.exists && d.get('status') === 'open' ? taskOf(d) : null))
          .filter(
            (t): t is Task =>
              t !== null &&
              t.assignees.includes(uid) &&
              t.reminded[uid] !== t.revision &&
              t.dueAt > now,
          );
        for (const t of keep) tx.update(t.ref, new FieldPath('reminded', uid), t.revision);
        return keep;
      });
      if (claimed.length === 0) continue;
      const first = claimed[0]!;
      const minutes = Math.max(1, Math.round((first.dueAt.getTime() - now.getTime()) / MINUTE));
      const lines = claimed.map((t) => ({ task: t.task, time: t.time }));
      const person = labels.get(uid) ?? null;
      pushes += 1;
      const result = await notifyUsers(
        db,
        sender,
        [uid],
        {
          kind: 'careTaskDue',
          id: `ct-${first.id}-r${first.revision}`,
          babyId,
          data: {
            babyId,
            date: first.date,
            items: claimed.map((t) => t.id).join(','),
            // "Xong" opens the app when a task writes a log or starts the sleep timer (D-138).
            opensApp: claimed.some((t) => opensApp.has(t.task)) ? '1' : '0',
          },
          message: (language) => ({
            ...careTaskCopy(lines, minutes, language, person),
            // Stale after the task's time: the push says "in 5 min".
            expiresAt: first.dueAt.getTime() + 30 * MINUTE,
            // Figma N1: "Xong" · "Nhắc lại 10 phút" (RuleNotifications.swift, Push.kt).
            apns: {
              category: claimed.some((t) => opensApp.has(t.task))
                ? 'CL_CARE_TASK_APP'
                : 'CL_CARE_TASK',
              collapseId: `ct-${first.id}`,
              threadId: `ct-${babyId}`,
            },
            androidDraws: true,
          }),
          template: {
            id: 'care.task_due',
            values: {
              minutes,
              task_line: { vi: taskNames(lines, 'vi'), en: taskNames(lines, 'en') },
              ...(person ? { recipient_name: person } : {}),
            },
          },
          quietHours: prefs.get(uid)?.quietHours === false ? 'held' : 'rings',
          zone,
        },
        now,
      );
      sent += result.sent;
    }
  }
  return { pushes, sent };
}
