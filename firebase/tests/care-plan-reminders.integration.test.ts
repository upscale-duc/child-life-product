import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  assignCarePlanItems,
  saveCarePlanItem,
  setCarePlanItemStatus,
  startCarePlanDay,
} from '../functions/src/care-plan.js';
import { careTaskCopy, ringCareTaskReminders } from '../functions/src/care-plan-reminders.js';
import type { PushSender } from '../functions/src/social.js';

// Cùng Chăm Con N1 (D-135) against the Firestore emulator: who is pushed and when (their own
// "Nhắc trước"), grouping, once per task + revision, and quiet hours per person (Q5). Times are
// Hồ Chí Minh (UTC+7); 5 Nov 2026 keeps clear of other suites' plans.
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const babyId = 'b_cpr0000000000000000001';
const date = '2026-11-05';
const vn = (hh: number, mm = 0) => new Date(Date.UTC(2026, 10, 5, hh - 7, mm));
// Fresh ids per test: the notification ledger (dedup by task + revision) outlives a test.
let run = 0;
const id = (n: number) => `pi_${(run * 16 + n).toString(16).padStart(32, 'c')}`;
const mom = 'cpr_mom';
const dad = 'cpr_dad';
const nanny = 'cpr_nanny';
const aunt = 'cpr_aunt';

const member = (uid: string, role: string) => ({
  uid,
  babyId,
  role,
  status: 'active',
  displayName: uid,
  relation: uid === dad ? 'father' : 'other',
  relationCustom: uid === nanny ? 'Cô Lan' : null,
});

const sent: ({ token: string } & Parameters<PushSender['send']>[1])[] = [];
const sender: PushSender = {
  async send(tokens, message) {
    for (const token of tokens) sent.push({ token, ...message });
    return [];
  },
};
const to = (uid: string) => sent.filter((s) => s.token === `t-${uid}`);

async function task(n: number, time: string, assignees: string[], task = 'vitamin') {
  await saveCarePlanItem(
    db,
    mom,
    { babyId, date, itemId: id(n), task, title: null, time, assignees, scope: 'today' },
    vn(6),
  );
}

beforeAll(() => {
  app = initializeApp({ projectId }, `care-plan-reminders-${randomUUID()}`);
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
  for (const [uid, role] of [
    [mom, 'coParent'],
    [dad, 'coParent'],
    [nanny, 'caregiver'],
    [aunt, 'relative'],
  ] as const) {
    await db.doc(`babies/${babyId}/members/${uid}`).set(member(uid, role));
    await db.doc(`users/${uid}/devices/d1`).set({ token: `t-${uid}`, language: 'vi' });
    await db.doc(`users/${uid}/settings/carePlan`).delete();
    await db.doc(`users/${uid}/settings/personalization`).delete();
    await db.recursiveDelete(db.collection(`users/${uid}/notifications`)).catch(() => undefined);
  }
  await startCarePlanDay(db, mom, { babyId, date, from: 'empty' }, vn(6));
});

describe('N1 task reminders', () => {
  it('rings each assignee 5 minutes before by default, once', async () => {
    await task(1, '09:00', [dad, nanny]);
    await ringCareTaskReminders(db, sender, vn(8, 54));
    expect(sent).toHaveLength(0);
    await ringCareTaskReminders(db, sender, vn(8, 55));
    expect(to(dad)).toHaveLength(1);
    expect(to(nanny)).toHaveLength(1);
    expect(to(mom)).toHaveLength(0);
    expect(to(dad)[0]!.title).toBe('Ba ơi, 5 phút nữa Teddy cần Ba rồi nè');
    expect(to(dad)[0]!.body).toBe('Vitamin');
    expect(to(nanny)[0]!.title).toBe('Cô Lan ơi, 5 phút nữa Teddy cần Cô Lan rồi nè');
    expect(to(dad)[0]!.data).toMatchObject({
      kind: 'careTaskDue',
      destination: 'CARE_TASK_DUE',
      babyId,
      date,
      items: id(1),
      // Vitamin needs no log: "Xong" answers from the lock screen.
      opensApp: '0',
    });
    // Figma N1: Xong · Nhắc lại 10 phút, drawn by the app on Android.
    expect(to(dad)[0]).toMatchObject({ androidDraws: true, apns: { category: 'CL_CARE_TASK' } });
    // The next minutes, and a retried run, send nothing more.
    await ringCareTaskReminders(db, sender, vn(8, 56));
    await ringCareTaskReminders(db, sender, vn(8, 56));
    expect(sent).toHaveLength(2);
  });

  it('follows each person’s own lead; Tắt sends nothing', async () => {
    await db.doc(`users/${dad}/settings/carePlan`).set({ leadMinutes: 15 });
    await db.doc(`users/${nanny}/settings/carePlan`).set({ leadMinutes: 0 });
    await task(1, '09:00', [dad, nanny]);
    await ringCareTaskReminders(db, sender, vn(8, 45));
    expect(to(dad)).toHaveLength(1);
    expect(to(dad)[0]!.title).toBe('Ba ơi, 15 phút nữa Teddy cần Ba rồi nè');
    await ringCareTaskReminders(db, sender, vn(8, 59));
    expect(to(nanny)).toHaveLength(0);
  });

  it('groups one person’s tasks under 15 minutes apart into one push', async () => {
    await task(1, '09:00', [dad]);
    await task(2, '09:10', [dad], 'bottle');
    await task(3, '09:20', [dad], 'bath');
    await ringCareTaskReminders(db, sender, vn(8, 55));
    expect(to(dad)).toHaveLength(1);
    expect(to(dad)[0]!.body).toBe('Vitamin · Bú bình');
    // Bú bình writes a log first (D-138): "Xong" opens the app.
    expect(to(dad)[0]!.data.opensApp).toBe('1');
    expect(to(dad)[0]!.data.items).toBe(`${id(1)},${id(2)}`);
    // 09:10 was in that push; 09:20 rings on its own.
    await ringCareTaskReminders(db, sender, vn(9, 5));
    expect(to(dad)).toHaveLength(1);
    await ringCareTaskReminders(db, sender, vn(9, 15));
    expect(to(dad)).toHaveLength(2);
    expect(to(dad)[1]!.body).toBe('Tắm');
  });

  it('a moved task or a new person is reminded again; done or skipped tasks are not', async () => {
    await task(1, '09:00', [dad]);
    await ringCareTaskReminders(db, sender, vn(8, 55));
    expect(to(dad)).toHaveLength(1);
    await task(1, '09:30', [dad]);
    await ringCareTaskReminders(db, sender, vn(9, 25));
    expect(to(dad)).toHaveLength(2);
    await assignCarePlanItems(
      db,
      mom,
      { babyId, date, itemIds: [id(1)], assignees: [dad, nanny] },
      vn(9, 26),
    );
    await ringCareTaskReminders(db, sender, vn(9, 26));
    expect(to(nanny)).toHaveLength(1);
    expect(to(dad)).toHaveLength(3);

    await task(2, '10:00', [dad]);
    await setCarePlanItemStatus(
      db,
      dad,
      { babyId, date, itemId: id(2), status: 'done' },
      vn(9, 50),
    );
    await ringCareTaskReminders(db, sender, vn(9, 55));
    expect(to(dad)).toHaveLength(3);
  });

  it('never a relative or someone who left; never a typed title', async () => {
    await task(1, '09:00', [dad]);
    await db.doc(`babies/${babyId}/members/${dad}`).update({ role: 'relative' });
    await ringCareTaskReminders(db, sender, vn(8, 55));
    expect(to(dad)).toHaveLength(0);

    await saveCarePlanItem(
      db,
      mom,
      {
        babyId,
        date,
        itemId: id(2),
        task: 'custom',
        title: 'Siro ho 5 ml',
        time: '10:00',
        assignees: [nanny],
        scope: 'today',
      },
      vn(6),
    );
    await ringCareTaskReminders(db, sender, vn(9, 55));
    expect(to(nanny)[0]!.body).toBe('Việc riêng');
  });

  it('rings in quiet hours by default; held for who turned that off (Q5)', async () => {
    for (const uid of [dad, nanny]) {
      await db
        .doc(`users/${uid}/settings/personalization`)
        .set({ quietHours: { enabled: true, from: '22:00', to: '06:00' } });
    }
    await db.doc(`users/${nanny}/settings/carePlan`).set({ quietHours: false });
    await task(1, '05:00', [dad, nanny]);
    await ringCareTaskReminders(db, sender, vn(4, 55));
    expect(to(dad)).toHaveLength(1);
    expect(to(nanny)).toHaveLength(0);
    // Held, not lost: the inbox has it.
    const inbox = await db.collection(`users/${nanny}/notifications`).get();
    expect(inbox.size).toBe(1);
  });

  it('copy without the baby’s name reads “bé”', () => {
    expect(careTaskCopy([{ task: 'bottle', time: '07:00' }], 10, 'vi')).toEqual({
      title: '10 phút nữa bé cần bạn rồi nè',
      body: 'Bú bình',
    });
    expect(careTaskCopy([{ task: 'bottle', time: '07:00' }], 10, 'en').body).toBe('Bottle');
    expect(
      careTaskCopy([{ task: 'bottle', time: '07:00' }], 10, 'vi', { vi: 'Ba', en: 'Dad' }).title,
    ).toBe('Ba ơi, 10 phút nữa bé cần Ba rồi nè');
  });
});
