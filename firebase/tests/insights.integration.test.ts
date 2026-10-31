import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { defaultEntitlementsConfig, defaultFlags } from '@child-life/contracts';
import {
  computeBabyInsights,
  insightEditDelayMs,
  queueInsights,
  runInsightQueue,
} from '../functions/src/insights.js';

/**
 * Hiểu con P1 (D-150, D-151): the server reads 14 nights of records, stores the insights with
 * their evidence, keeps the figures from a Free household and schedules its own recomputes.
 * Synthetic records only.
 */
const app = initializeApp({ projectId: 'demo-child-life-insights' }, `ins-${randomUUID()}`);
const db = getFirestore(app);
const now = new Date('2026-10-26T07:30:00+07:00');
const at = (date: string, hhmm: string) => new Date(`${date}T${hhmm}:00+07:00`);
const day = (base: string, offset: number) => {
  const [y, m, d] = base.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(y, m - 1, d + offset)).toISOString().slice(0, 10);
};

let seq = 0;
async function put(type: string, from: Date, to: Date | null, by: string) {
  const id = `r_${(seq += 1).toString(16).padStart(32, '0')}`;
  await db.doc(`babies/baby/records/${id}`).set({
    id,
    babyId: 'baby',
    type,
    occurredAt: Timestamp.fromDate(from),
    endedAt: to ? Timestamp.fromDate(to) : null,
    data: type === 'bottle' ? { amountMl: 90, milk: 'formula' } : {},
    createdBy: by,
    author: { name: by === 'parent' ? 'Mẹ' : 'Ba', relation: 'other', relationCustom: null },
    deleted: false,
  });
  return id;
}

/** Asleep 20:00 for [first] min, a bottle, then shorter sleeps until 06:00. */
async function night(date: string, first: number, by = 'parent') {
  const end = at(day(date, 1), '06:00').getTime();
  const ids = [await put('sleep', at(date, '20:00'), new Date(at(date, '20:00').getTime() + first * 60_000), by)];
  let cursor = at(date, '20:00').getTime() + first * 60_000;
  let fed = false;
  while (cursor + 10 * 60_000 < end) {
    if (!fed) {
      await put('bottle', new Date(cursor + 5 * 60_000), null, by);
      fed = true;
    }
    const from = cursor + 10 * 60_000;
    const until = Math.min(from + (first - 10) * 60_000, end);
    ids.push(await put('sleep', new Date(from), new Date(until), by));
    cursor = until;
  }
  return ids;
}
async function twoWeeks(baseline: number, recent: number) {
  for (let i = 0; i < 7; i += 1) await night(day('2026-10-12', i), baseline);
  for (let i = 0; i < 7; i += 1) await night(day('2026-10-19', i), recent, i % 2 ? 'carer' : 'parent');
}

const grantPremium = () =>
  db.doc('config/entitlements').set({
    ...defaultEntitlementsConfig,
    regions: { advanced: ['VN'] },
    betaCampaigns: [
      {
        id: 'beta-insights',
        capabilities: ['personalization.cross_module', 'rhythm.advanced', 'ai.assistance'],
        validFrom: '2026-10-01T00:00:00Z',
        validUntil: '2026-12-01T00:00:00Z',
        countries: [],
        scope: 'internal',
        percent: 0,
        families: ['f'],
      },
    ],
  });
const current = async () => (await db.doc('babies/baby/insights/current').get()).data()!;

beforeAll(() => {
  expect(process.env.FIRESTORE_EMULATOR_HOST).toBeTruthy();
});
afterAll(() => deleteApp(app));
beforeEach(async () => {
  for (const collection of await db.listCollections()) await db.recursiveDelete(collection);
  const flag = { ...defaultFlags.rhythm, enabled: true, scope: 'all' };
  await db.doc('config/flags').set({ rhythm: flag, personalization: flag });
  await db.doc('families/f').set({ ownerUid: 'parent', country: 'VN' });
  await db
    .doc('babies/baby')
    .set({ familyId: 'f', state: 'active', timeZone: { zone: 'Asia/Ho_Chi_Minh' } });
  await db.doc('babies/baby/restricted/profile').set({ dateOfBirth: '2026-06-01' });
});

describe('computeBabyInsights', () => {
  it('Premium: stores the insight with its evidence and picks it for Hôm nay', async () => {
    await grantPremium();
    await twoWeeks(140, 172);
    expect(await computeBabyInsights(db, 'baby', now)).toBe('written');
    const s = await current();
    expect(s).toMatchObject({
      ruleVersion: 1,
      premium: true,
      from: '2026-10-12',
      to: '2026-10-25',
      today: 'night_longest',
      todayOn: '2026-10-26',
      progress: { validNights: 7, neededNights: 5 },
    });
    const longest = (s.items as { kind: string }[]).find((i) => i.kind === 'night_longest');
    expect(longest).toMatchObject({
      direction: 'up',
      value: 172,
      baselineValue: 140,
      coverage: { valid: 7, total: 7 },
    });
    expect((longest as { authors: { name: string }[] }).authors.map((a) => a.name).sort()).toEqual(['Ba', 'Mẹ']);
  });

  it('Free: no figures leave the server, only the kind for the invite (D-151 #9)', async () => {
    await twoWeeks(140, 172);
    await computeBabyInsights(db, 'baby', now);
    const s = await current();
    expect(s.premium).toBe(false);
    expect(s.items).toEqual([]);
    expect(s.today).toBeNull();
    expect(s.teaser).toEqual({ kind: 'night_longest', direction: 'up' });
  });

  it('a deleted record is not counted; a missing week gives progress only', async () => {
    await grantPremium();
    for (let i = 0; i < 7; i += 1) await night(day('2026-10-12', i), 140);
    const ids = await night('2026-10-19', 172);
    await night('2026-10-20', 172);
    for (const id of ids) await db.doc(`babies/baby/records/${id}`).update({ deleted: true });
    await computeBabyInsights(db, 'baby', now);
    const s = await current();
    expect(s.items).toEqual([]);
    expect(s.progress).toEqual({ validNights: 1, neededNights: 5 });
  });

  it('a profile being deleted is left alone', async () => {
    await db.doc('babies/baby').update({ state: 'deleting' });
    expect(await computeBabyInsights(db, 'baby', now)).toBe('skipped');
    expect((await db.doc('babies/baby/insights/current').get()).exists).toBe(false);
  });
});

describe('queue', () => {
  it('an edit of a counted night is due in 10 minutes, a new log the next morning', async () => {
    const id = await put('bottle', at('2026-10-21', '02:00'), null, 'parent');
    const edited = await db.doc(`babies/baby/records/${id}`).get();
    const due = await queueInsights(db, 'baby', edited, edited, now);
    expect(due!.getTime()).toBe(now.getTime() + insightEditDelayMs);

    await db.doc('insightQueue/baby').delete();
    const fresh = await db.doc(`babies/baby/records/${await put('bottle', now, null, 'parent')}`).get();
    const morning = await queueInsights(db, 'baby', null, fresh, now);
    expect(morning!.toISOString()).toBe(at('2026-10-27', '06:30').toISOString());
    // A later write never pushes an earlier due time back.
    const again = await queueInsights(db, 'baby', null, fresh, new Date(now.getTime() + 60_000));
    expect(again!.toISOString()).toBe(morning!.toISOString());
  });

  it('runs what is due and books the next morning', async () => {
    await grantPremium();
    await twoWeeks(140, 172);
    await db.doc('insightQueue/baby').set({
      babyId: 'baby',
      dueAt: Timestamp.fromDate(new Date(now.getTime() - 60_000)),
      lastCareAt: Timestamp.fromDate(now),
    });
    expect(await runInsightQueue(db, now)).toEqual({ computed: 1, skipped: 0, idle: 0 });
    expect((await current()).today).toBe('night_longest');
    const next = (await db.doc('insightQueue/baby').get()).get('dueAt') as Timestamp;
    expect(next.toDate().toISOString()).toBe(at('2026-10-27', '06:30').toISOString());
  });

  it('a baby idle for 3 days leaves the queue', async () => {
    await db.doc('insightQueue/baby').set({
      babyId: 'baby',
      dueAt: Timestamp.fromDate(now),
      lastCareAt: Timestamp.fromDate(new Date(now.getTime() - 4 * 86_400_000)),
    });
    expect(await runInsightQueue(db, now)).toEqual({ computed: 0, skipped: 0, idle: 1 });
    expect((await db.doc('insightQueue/baby').get()).exists).toBe(false);
  });
});
