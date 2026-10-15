import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { commitQuotaNow, readQuotaSnapshot, reserveQuotaNow } from '../functions/src/quota.js';
import { sweepAiReservations } from '../functions/src/quota-sweeper.js';

// Leaked AI reservations (a function that died mid-call) are released once, never twice, and a
// late commit after the sweep is a no-op. Video reservations are left alone. Synthetic data.
const projectId = 'demo-child-life-quota-sweeper';
const t0 = new Date('2026-10-15T03:00:00Z');
const later = new Date(t0.getTime() + 45 * 60_000);
let app: App;
let db: Firestore;

const ai = (id: string, at: Date) =>
  reserveQuotaNow(db, {
    familyId: 'test_f1',
    reservationId: id,
    windows: [
      {
        window: { kind: 'day', feature: 'ai_day', babyId: 'test_b1', zone: 'Asia/Ho_Chi_Minh' },
        limit: 1,
      },
      {
        window: { kind: 'calendar_month', feature: 'ai_month', zone: 'Asia/Ho_Chi_Minh' },
        limit: 10,
      },
    ],
    now: at,
  });

beforeAll(() => {
  app = initializeApp({ projectId }, `quota-sweeper-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  await db.recursiveDelete(db.collection('families'));
});

describe('sweepAiReservations', () => {
  it('releases a stale AI reservation once; a late commit does nothing; fresh ones stay', async () => {
    await ai('ai_old', t0);
    expect(await sweepAiReservations(db, new Date(t0.getTime() + 10 * 60_000))).toBe(0);
    expect(await sweepAiReservations(db, later)).toBe(1);
    expect(await sweepAiReservations(db, later)).toBe(0);
    expect(
      (await commitQuotaNow(db, { familyId: 'test_f1', reservationId: 'ai_old', now: later }))
        .outcome,
    ).toBe('noop');
    const day = await readQuotaSnapshot(
      db,
      'test_f1',
      {
        window: { kind: 'day', feature: 'ai_day', babyId: 'test_b1', zone: 'Asia/Ho_Chi_Minh' },
        limit: 1,
      },
      later,
    );
    expect(day).toMatchObject({ used: 0, reserved: 0 });
  });

  it('D-075 #1: releases a stale summary credit (su_*) but leaves assistant tasks to their sweeper', async () => {
    const pool = (id: string) =>
      reserveQuotaNow(db, {
        familyId: 'test_f1',
        reservationId: id,
        windows: [
          {
            window: { kind: 'calendar_month', feature: 'assistant', zone: 'Asia/Ho_Chi_Minh' },
            limit: 20,
          },
        ],
        now: t0,
      });
    await pool('su_old');
    await pool('tk_old');
    expect(await sweepAiReservations(db, later)).toBe(1);
    const month = await readQuotaSnapshot(
      db,
      'test_f1',
      {
        window: { kind: 'calendar_month', feature: 'assistant', zone: 'Asia/Ho_Chi_Minh' },
        limit: 20,
      },
      later,
    );
    expect(month).toMatchObject({ used: 0, reserved: 1 });
  });

  it('leaves video reservations to the keepsake sweeper', async () => {
    await reserveQuotaNow(db, {
      familyId: 'test_f1',
      reservationId: 'video_job_1',
      windows: [
        {
          window: { kind: 'calendar_month', feature: 'video', zone: 'Asia/Ho_Chi_Minh' },
          limit: 1,
        },
      ],
      holder: 'lease-0',
      now: t0,
    });
    expect(await sweepAiReservations(db, later)).toBe(0);
  });
});
