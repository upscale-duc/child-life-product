import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  commitQuotaNow,
  readQuotaSnapshot,
  releaseQuotaNow,
  reserveQuotaNow,
  _resolveWindowForTest,
  type QuotaWindowRequest,
} from '../functions/src/quota.js';

// Quota ledger on Firestore (plan §5.3, brief p.10): fixtures Q01–Q04 through real transactions,
// all-or-none over two windows, fencing, zone changes (M16) and a 20-way concurrent reserve on a
// limit-1 window (M10, best effort: the emulator serialises transactions differently from
// production, so this is evidence of the logic, not of production concurrency — that run is
// `scripts/src/qa-quota-race.ts` on dev). Its own project; synthetic `test_` data.
const projectId = 'demo-child-life-quota';
let app: App;
let db: Firestore;
const F = 'test_fq';
const now = new Date('2026-10-14T12:00:00Z');
const month = (limit: number, zone = 'Asia/Ho_Chi_Minh'): QuotaWindowRequest => ({
  window: { kind: 'calendar_month', feature: 'video', zone },
  limit,
});

interface Fixture {
  id: string;
  kind: string;
  input: { limit: number; operations: [string, string][] };
  expected: { used: number; reserved: number; accepted_jobs: string[]; denied: number };
}
const fixtures = (
  JSON.parse(
    readFileSync(
      resolve(import.meta.dirname, '../../packages/contracts/test/vectors/premium-v2.json'),
      'utf8',
    ),
  ) as { cases: Fixture[] }
).cases.filter((c) => c.kind === 'quota');

beforeAll(() => {
  app = initializeApp({ projectId }, `quota-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  await db.recursiveDelete(db.collection('families'));
});

const windowDoc = async (id: string) => (await db.doc(`families/${F}/quota/${id}`).get()).data();

describe('Q01–Q04 through Firestore transactions', () => {
  it('has the four fixtures', () => {
    expect(fixtures.map((f) => f.id)).toEqual(['Q01', 'Q02', 'Q03', 'Q04']);
  });

  for (const fx of fixtures) {
    it(`${fx.id}`, async () => {
      await db.recursiveDelete(db.collection('families'));
      const accepted: string[] = [];
      let denied = 0;
      for (const [op, job] of fx.input.operations) {
        if (op === 'reserve') {
          const r = await reserveQuotaNow(db, {
            familyId: F,
            reservationId: job,
            windows: [month(fx.input.limit)],
            now,
          });
          if (r.outcome === 'reserved') accepted.push(job);
          if (r.outcome === 'denied') denied++;
        } else {
          const settle = op === 'success' ? commitQuotaNow : releaseQuotaNow;
          await settle(db, { familyId: F, reservationId: job, now });
        }
      }
      const w = await windowDoc('video_cal_2026-10');
      expect({ used: w?.used, reserved: w?.reserved }).toEqual({
        used: fx.expected.used,
        reserved: fx.expected.reserved,
      });
      expect(accepted).toEqual(fx.expected.accepted_jobs);
      expect(denied).toBe(fx.expected.denied);
      // Invariant at the end: used + reserved ≤ limit.
      expect(w!.used + w!.reserved).toBeLessThanOrEqual(w!.limit);
    });
  }
});

describe('ledger documents', () => {
  it('a window stores its zone, local dates, instants and the limit frozen at creation', async () => {
    await reserveQuotaNow(db, { familyId: F, reservationId: 'j1', windows: [month(1)], now });
    // Config raised later: the running window keeps its limit.
    await reserveQuotaNow(db, { familyId: F, reservationId: 'j2', windows: [month(9)], now });
    const w = await windowDoc('video_cal_2026-10');
    expect(w).toMatchObject({
      feature: 'video',
      scope: 'calendar_month',
      zone: 'Asia/Ho_Chi_Minh',
      startDate: '2026-10-01',
      endDate: '2026-11-01',
      limit: 1,
      used: 0,
      reserved: 1,
    });
    expect(w!.resetsAt.toDate().toISOString()).toBe('2026-10-31T17:00:00.000Z');
    const op = (await db.doc(`families/${F}/quotaOps/j1`).get()).data();
    expect(op).toMatchObject({
      state: 'reserved',
      windowIds: ['video_cal_2026-10'],
      feature: 'video',
    });
    expect(await db.doc(`families/${F}/quotaOps/j2`).get()).toHaveProperty('exists', false);
  });

  it('two windows: both or none (ai_day full → ai_month untouched)', async () => {
    const zone = 'Asia/Ho_Chi_Minh';
    const both = (limitDay: number): QuotaWindowRequest[] => [
      { window: { kind: 'day', feature: 'ai_day', babyId: 'test_b', zone }, limit: limitDay },
      { window: { kind: 'calendar_month', feature: 'ai_month', zone }, limit: 10 },
    ];
    const a = await reserveQuotaNow(db, {
      familyId: F,
      reservationId: 's1',
      windows: both(1),
      now,
    });
    expect(a.outcome).toBe('reserved');
    expect(a.windows.map((w) => w.windowId)).toEqual([
      'ai_day_test_b_2026-10-14',
      'ai_month_cal_2026-10',
    ]);
    const b = await reserveQuotaNow(db, {
      familyId: F,
      reservationId: 's2',
      windows: both(1),
      now,
    });
    expect(b.outcome).toBe('denied');
    expect((await windowDoc('ai_month_cal_2026-10'))?.reserved).toBe(1);
    await commitQuotaNow(db, { familyId: F, reservationId: 's1', now });
    expect(await windowDoc('ai_day_test_b_2026-10-14')).toMatchObject({ used: 1, reserved: 0 });
    expect(await windowDoc('ai_month_cal_2026-10')).toMatchObject({ used: 1, reserved: 0 });
    // The next local day is a new window.
    const tomorrow = new Date('2026-10-14T17:30:00Z');
    const c = await reserveQuotaNow(db, {
      familyId: F,
      reservationId: 's3',
      windows: both(1),
      now: tomorrow,
    });
    expect(c.outcome).toBe('reserved');
    expect(c.windows[0]!.windowId).toBe('ai_day_test_b_2026-10-15');
  });

  it('fencing: only the holder commits; a stale attempt is refused, release is once', async () => {
    await reserveQuotaNow(db, {
      familyId: F,
      reservationId: 'job1',
      windows: [month(2)],
      holder: 'attempt-2',
      now,
    });
    const stale = await commitQuotaNow(db, {
      familyId: F,
      reservationId: 'job1',
      holder: 'attempt-1',
      now,
    });
    expect(stale.outcome).toBe('fenced');
    const ok = await commitQuotaNow(db, {
      familyId: F,
      reservationId: 'job1',
      holder: 'attempt-2',
      now,
    });
    expect(ok.outcome).toBe('committed');
    const late = await releaseQuotaNow(db, { familyId: F, reservationId: 'job1', now });
    expect(late.outcome).toBe('noop');
    expect(await windowDoc('video_cal_2026-10')).toMatchObject({ used: 1, reserved: 0 });
  });

  it('paid billing period: fixed instants, refused outside the period', async () => {
    const paid: QuotaWindowRequest = {
      window: {
        kind: 'paid',
        feature: 'video',
        grantId: 'paid_x',
        periodStart: new Date('2026-10-05T03:00:00Z'),
        periodEnd: new Date('2026-11-05T03:00:00Z'),
      },
      limit: 5,
    };
    const r = await reserveQuotaNow(db, {
      familyId: F,
      reservationId: 'p1',
      windows: [paid],
      now,
    });
    expect(r.windows[0]!.windowId).toBe('video_paid_paid_x_2026-10-05');
    await expect(
      reserveQuotaNow(db, {
        familyId: F,
        reservationId: 'p2',
        windows: [paid],
        now: new Date('2026-11-06T00:00:00Z'),
      }),
    ).rejects.toMatchObject({ reason: 'outside-period' });
  });

  it('snapshot for the app (MO04)', async () => {
    expect(await readQuotaSnapshot(db, F, month(1), now)).toEqual({
      limit: 1,
      used: 0,
      reserved: 0,
      resetsAt: '2026-10-31T17:00:00.000Z',
    });
    await reserveQuotaNow(db, { familyId: F, reservationId: 'j1', windows: [month(1)], now });
    expect(await readQuotaSnapshot(db, F, month(1), now)).toMatchObject({ reserved: 1 });
  });

  it('rejects a reservation id that is not a plain key', async () => {
    await expect(
      reserveQuotaNow(db, { familyId: F, reservationId: 'a/b', windows: [month(1)], now }),
    ).rejects.toMatchObject({ reason: 'bad-reservation' });
  });
});

describe('time-zone change keeps the current window to its end (M16)', () => {
  it('moved east: the previous month window (old zone) still runs until its own end', async () => {
    // Window cut in New York; ends 2026-11-01 04:00Z (EDT).
    await reserveQuotaNow(db, {
      familyId: F,
      reservationId: 'j1',
      windows: [month(3, 'America/New_York')],
      now,
    });
    // 2026-10-31 20:00Z is already November in Hồ Chí Minh, still October's window.
    const at = new Date('2026-10-31T20:00:00Z');
    const r = await _resolveWindowForTest(db, F, month(3), at);
    expect(r).toMatchObject({ windowId: 'video_cal_2026-10', exists: true });
    expect(r.window.zone).toBe('America/New_York');
    // After its end the next window is cut in the new zone, starting where the old one ended.
    const after = new Date('2026-11-01T05:00:00Z');
    const n = await _resolveWindowForTest(db, F, month(3), after);
    expect(n).toMatchObject({ windowId: 'video_cal_2026-11', exists: false });
    expect(n.window.zone).toBe('Asia/Ho_Chi_Minh');
    expect(n.window.startsAt.toISOString()).toBe('2026-11-01T04:00:00.000Z');
  });

  it('moved west: an ended window is never reused; the next starts at its end', async () => {
    await reserveQuotaNow(db, { familyId: F, reservationId: 'j1', windows: [month(3)], now });
    await commitQuotaNow(db, { familyId: F, reservationId: 'j1', now });
    // 18:00Z on Oct 31: October ended in Hồ Chí Minh (17:00Z) but not in New York.
    const at = new Date('2026-10-31T18:00:00Z');
    const r = await reserveQuotaNow(db, {
      familyId: F,
      reservationId: 'j2',
      windows: [month(3, 'America/New_York')],
      now: at,
    });
    expect(r.outcome).toBe('reserved');
    expect(r.windows[0]).toMatchObject({
      windowId: 'video_cal_2026-11',
      zone: 'America/New_York',
      used: 0,
      reserved: 1,
    });
    expect(r.windows[0]!.startsAt.toISOString()).toBe('2026-10-31T17:00:00.000Z');
    expect(r.windows[0]!.resetsAt.toISOString()).toBe('2026-12-01T05:00:00.000Z');
    expect(await windowDoc('video_cal_2026-10')).toMatchObject({ used: 1, reserved: 0 });
  });
});

describe('concurrency (M10, emulator best effort)', () => {
  it('20 parallel reserves on a limit-1 window: exactly one wins, never over the limit', async () => {
    const results = await Promise.all(
      Array.from({ length: 20 }, (_, i) =>
        reserveQuotaNow(db, {
          familyId: F,
          reservationId: `race_${i}`,
          windows: [month(1)],
          now,
        }),
      ),
    );
    expect(results.filter((r) => r.outcome === 'reserved')).toHaveLength(1);
    expect(results.filter((r) => r.outcome === 'denied')).toHaveLength(19);
    expect(await windowDoc('video_cal_2026-10')).toMatchObject({ limit: 1, used: 0, reserved: 1 });
    const ops = await db.collection(`families/${F}/quotaOps`).get();
    expect(ops.size).toBe(1);
  });

  it('20 parallel retries of one reservation id take one unit', async () => {
    const results = await Promise.all(
      Array.from({ length: 20 }, () =>
        reserveQuotaNow(db, { familyId: F, reservationId: 'same', windows: [month(5)], now }),
      ),
    );
    expect(results.filter((r) => r.outcome === 'reserved')).toHaveLength(1);
    expect(results.every((r) => r.state === 'reserved')).toBe(true);
    expect(await windowDoc('video_cal_2026-10')).toMatchObject({ reserved: 1 });
  });

  it('parallel commit and release of one reservation settle it once', async () => {
    await reserveQuotaNow(db, { familyId: F, reservationId: 'j', windows: [month(1)], now });
    // A transaction that gives up under contention (ABORTED after retries) is an error the
    // caller retries, never a second settlement: at most one call may change the reservation.
    const out = await Promise.allSettled([
      commitQuotaNow(db, { familyId: F, reservationId: 'j', now }),
      releaseQuotaNow(db, { familyId: F, reservationId: 'j', now }),
      commitQuotaNow(db, { familyId: F, reservationId: 'j', now }),
    ]);
    const settled = out.filter((o) => o.status === 'fulfilled' && o.value.outcome !== 'noop');
    expect(settled.length).toBeLessThanOrEqual(1);
    if (settled.length === 0) {
      // Every call lost the race: a retry settles it once.
      await commitQuotaNow(db, { familyId: F, reservationId: 'j', now });
    }
    const w = await windowDoc('video_cal_2026-10');
    expect(w!.used + w!.reserved).toBe(w!.used === 1 ? 1 : 0);
    expect(w!.reserved).toBe(0);
  }, 60_000);
});
