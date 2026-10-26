import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, expect, it } from 'vitest';
import { engagementHealth } from '../functions/src/engagement-health.js';
import { familyCode, type Staff } from '../functions/src/staff.js';

// "Trước khi gửi" (owner, 2026-10-26): the overview's delivery numbers said 0 % failures while
// every suggestion of one account stayed in the app and the next day's daily suggestion was
// closed the day before. These checks see what never became a push. Dates are in 2031 so other
// files on this emulator never fall in the range.
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const owner: Staff = { uid: 's_owner', name: 'Owner', roles: ['owner'] };
const expert: Staff = { uid: 's_expert', name: 'Chuyên gia', roles: ['expert'] };
const fam = 'f_eh0001';
const baby = 'b_eh0000000000000000001';
const uid = 'eh-mom';
const day = '2031-03-10';
const now = new Date('2031-03-12T05:00:00Z');
const t = (iso: string) => Date.parse(iso);

beforeAll(async () => {
  app = initializeApp({ projectId }, `eh-${randomUUID()}`);
  db = getFirestore(app);
  const intent = (id: string, v: Record<string, unknown>) =>
    db.doc(`engagementIntents/eh_${id}`).set({
      uid,
      babyId: baby,
      familyId: fam,
      zone: 'Asia/Ho_Chi_Minh',
      proactive: true,
      dismissed: false,
      reason: 'none',
      ...v,
    });
  // Two weekly recaps kept in the app for want of a channel, one pushed.
  for (const id of ['w1', 'w2'])
    await intent(id, {
      kind: 'ENG-03',
      dueAt: t('2031-03-10T02:00:00Z'),
      status: 'in_app_only',
      reason: 'channel_unavailable',
    });
  await intent('w3', { kind: 'ENG-03', dueAt: t('2031-03-10T02:00:00Z'), status: 'accepted' });
  // 11/3's daily suggestion closed at 08:08 on 10/3: before its own day.
  await intent('d1', {
    kind: 'ENG-06',
    dueAt: t('2031-03-11T01:00:00Z'),
    windowClosesAt: t('2031-03-11T04:00:00Z'),
    sourceData: { date: '2031-03-11' },
    status: 'completed',
    reason: 'source_resolved',
    completedAt: t('2031-03-10T01:08:00Z'),
  });
  // 10/3's slot: its window passed and nothing decided it.
  await intent('d2', {
    kind: 'ENG-06',
    dueAt: t('2031-03-10T01:00:00Z'),
    windowClosesAt: t('2031-03-10T04:00:00Z'),
    sourceData: { date: day },
    status: 'eligible',
  });
  // A daily suggestion closed on its own day is normal.
  await intent('d3', {
    kind: 'ENG-06',
    dueAt: t('2031-03-12T01:00:00Z'),
    windowClosesAt: t('2031-03-12T04:00:00Z'),
    sourceData: { date: '2031-03-12' },
    status: 'cancelled',
    reason: 'source_resolved',
    closedAt: t('2031-03-12T00:30:00Z'),
  });
  // The lease says "not allowed" while the phone still gets pushes.
  await db.doc(`babies/${baby}`).set({ familyId: fam });
  await db.doc(`users/${uid}/devices/d_eh1`).set({ token: 't-eh', platform: 'ios' });
  await db.doc(`users/${uid}/settings/engagementDevice`).set({
    babyId: baby,
    deviceId: 'd_eh1',
    pushAllowed: false,
    validUntil: t('2031-04-01T00:00:00Z'),
  });
  await db.doc(`notificationDeliveries/d_eh_${randomUUID()}`).set({
    uid,
    delivery: 'accepted',
    createdAt: new Date('2031-03-11T10:00:00Z'),
  });
});

afterAll(async () => {
  await deleteApp(app);
});

it('sees what never became a push: no channel, a wrong lease, closed early, missed', async () => {
  await expect(
    engagementHealth(db, expert, { from: '2031-03-06', to: '2031-03-12' }, now),
  ).rejects.toMatchObject({ code: 'permission-denied' });
  const h = await engagementHealth(db, owner, { from: '2031-03-06', to: '2031-03-12' }, now);
  expect(h.outcomes).toMatchObject({ pushed: 1, in_app_only: 2, closed: 2, pending: 1 });
  expect(h.reasons.channel_unavailable).toBe(2);
  const signal = Object.fromEntries(h.signals.map((s) => [s.id, s]));
  expect(signal.channel_unavailable).toMatchObject({ n: 2, families: [familyCode(fam)] });
  expect(signal.permission_mismatch).toMatchObject({ n: 1, families: [familyCode(fam)] });
  expect(signal.closed_early).toMatchObject({ n: 1 });
  expect(signal.daily_missed).toMatchObject({ n: 1 });
  expect(h.daily).toEqual([
    { day: '2031-03-10', slots: 1, pushed: 0, missed: 1 },
    { day: '2031-03-11', slots: 1, pushed: 0, missed: 0 },
    { day: '2031-03-12', slots: 1, pushed: 0, missed: 0 },
  ]);
  // Never uids or child data.
  expect(JSON.stringify(h)).not.toContain(uid);
});

it('a healthy lease raises nothing', async () => {
  await db.doc(`users/${uid}/settings/engagementDevice`).update({ pushAllowed: true });
  const h = await engagementHealth(db, owner, { from: '2031-03-06', to: '2031-03-12' }, now);
  expect(h.signals.find((s) => s.id === 'permission_mismatch')).toBeUndefined();
});
