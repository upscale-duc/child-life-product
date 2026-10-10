import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { Timestamp, getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { onRecordWritten, purgeDeletedRecords } from '../functions/src/care.js';

// S4 server derivations against the Firestore emulator (`pnpm test:rules`): day summaries in the
// baby's zone, "đã ghi N lần" per member and the 30-day bin (P-009).
const projectId = 'demo-child-life';
const now = new Date('2026-10-08T08:05:00Z'); // 15:05 in Hồ Chí Minh, as in the mocks
let app: App;
let db: Firestore;
const babyId = 'b_care';

let seq = 0;
async function put(
  type: string,
  occurredAt: string,
  data: Record<string, unknown>,
  extra: Record<string, unknown> = {},
) {
  const id = `r_${(++seq).toString(16).padStart(32, '0')}`;
  const ref = db.doc(`babies/${babyId}/records/${id}`);
  await ref.set({
    id,
    babyId,
    type,
    occurredAt: Timestamp.fromDate(new Date(occurredAt)),
    endedAt: null,
    data,
    createdBy: 'mom',
    deleted: false,
    deletedAt: null,
    ...extra,
  });
  const snap = await ref.get();
  await onRecordWritten(db, babyId, null, snap, now);
  return ref;
}

beforeAll(() => {
  app = initializeApp({ projectId }, `care-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  const all = await db.recursiveDelete(db.doc(`babies/${babyId}`)).catch(() => undefined);
  void all;
  await db.doc(`babies/${babyId}`).set({ timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' } });
  await db.doc(`babies/${babyId}/members/mom`).set({ uid: 'mom', status: 'active' });
});

describe('day summaries', () => {
  it('"Đã ghi hôm nay" follows the records of the local day', async () => {
    await put('bottle', '2026-10-08T01:00:00Z', { amountMl: 120, milk: 'breastMilk' });
    await put('bottle', '2026-10-08T07:20:00Z', { amountMl: 120, milk: 'formula' });
    await put('diaper', '2026-10-08T02:10:00Z', { kind: 'both' });
    await put('pump', '2026-10-08T03:15:00Z', { side: 'both', amountMl: 90, durationMin: 15 });
    // 23:30 local on the 7th belongs to yesterday
    await put('bottle', '2026-10-07T16:30:00Z', { amountMl: 100, milk: 'formula' });

    const today = (await db.doc(`babies/${babyId}/days/2026-10-08`).get()).data();
    expect(today?.bottle).toEqual({ count: 2, ml: 240 });
    expect(today?.diaper).toEqual({ count: 1, wet: 1, dirty: 1 });
    expect(today?.pump).toEqual({ count: 1, ml: 90 });
    const yesterday = (await db.doc(`babies/${babyId}/days/2026-10-07`).get()).data();
    expect(yesterday?.bottle).toEqual({ count: 1, ml: 100 });
  });

  it('a soft delete, an edit across days and a purge all recompute', async () => {
    const ref = await put('bottle', '2026-10-08T01:00:00Z', { amountMl: 120, milk: 'formula' });
    const before = await ref.get();
    await ref.update({ deleted: true, deletedAt: Timestamp.fromDate(now) });
    await onRecordWritten(db, babyId, before, await ref.get(), now);
    expect((await db.doc(`babies/${babyId}/days/2026-10-08`).get()).get('bottle')).toEqual({
      count: 0,
      ml: 0,
    });

    const moved = await put('diaper', '2026-10-08T01:00:00Z', { kind: 'wet' });
    const beforeMove = await moved.get();
    await moved.update({ occurredAt: Timestamp.fromDate(new Date('2026-10-07T10:00:00Z')) });
    const { days } = await onRecordWritten(db, babyId, beforeMove, await moved.get(), now);
    expect(days).toEqual(['2026-10-07', '2026-10-08']);
    expect((await db.doc(`babies/${babyId}/days/2026-10-08`).get()).get('diaper.count')).toBe(0);
    expect((await db.doc(`babies/${babyId}/days/2026-10-07`).get()).get('diaper.count')).toBe(1);
  });
});

describe('member record count and the 30-day bin', () => {
  it('"đã ghi N lần" counts live records only', async () => {
    await put('diaper', '2026-10-08T01:00:00Z', { kind: 'wet' });
    const ref = await put('diaper', '2026-10-08T02:00:00Z', { kind: 'dirty' });
    expect((await db.doc(`babies/${babyId}/members/mom`).get()).get('recordCount')).toBe(2);
    const before = await ref.get();
    await ref.update({ deleted: true, deletedAt: Timestamp.fromDate(now) });
    await onRecordWritten(db, babyId, before, await ref.get(), now);
    expect((await db.doc(`babies/${babyId}/members/mom`).get()).get('recordCount')).toBe(1);
  });

  it('purges after 30 days, not before', async () => {
    const old = await put(
      'diaper',
      '2026-09-01T01:00:00Z',
      { kind: 'wet' },
      {
        deleted: true,
        deletedAt: Timestamp.fromDate(new Date('2026-09-07T00:00:00Z')),
      },
    );
    const recent = await put(
      'diaper',
      '2026-10-01T01:00:00Z',
      { kind: 'wet' },
      {
        deleted: true,
        deletedAt: Timestamp.fromDate(new Date('2026-10-01T00:00:00Z')),
      },
    );
    expect(await purgeDeletedRecords(db, now)).toBe(1);
    expect((await old.get()).exists).toBe(false);
    expect((await recent.get()).exists).toBe(true);
  });
});
