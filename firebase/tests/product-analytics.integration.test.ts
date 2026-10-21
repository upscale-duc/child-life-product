import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import {
  initializeTestEnvironment,
  assertFails,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { getDoc, doc, setDoc } from 'firebase/firestore';
import { beforeAll, afterAll, beforeEach, it, expect } from 'vitest';
import {
  recordAnalyticsRegistration,
  recordAnalyticsObservation,
  recordAnalyticsDomain,
  purgeProductAnalytics,
  recordAnalyticsFact,
} from '../functions/src/product-analytics-store.js';
import {
  productAnalytics,
  buildProductAnalyticsQuery,
  exportProductAnalytics,
} from '../functions/src/product-analytics.js';
import type { Staff } from '../functions/src/staff.js';

const projectId = 'demo-child-life-product-analytics';
const app = initializeApp({ projectId }, randomUUID()),
  db = getFirestore(app);
const admin: Staff = { uid: 'staff', name: 'Test operator', roles: ['admin'] };
const qa: Staff = { uid: 'qa', name: 'QA', roles: ['qa'] };
const created = new Date('2026-10-01T03:00:00.000Z');
const now = new Date('2026-10-15T03:00:00.000Z');
const query = {
  schemaVersion: 2,
  section: 'overview',
  from: '2026-10-01',
  to: '2026-10-08',
  platform: 'all',
  locale: 'all',
  ageBand: 'all',
  chapter: 'all',
  context: 'all',
  comparison: true,
};
let rules: RulesTestEnvironment;

beforeAll(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw Error('Firestore emulator required');
  const [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(':');
  rules = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: host!,
      port: Number(port),
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});
afterAll(async () => {
  await rules.cleanup();
  await deleteApp(app);
});
beforeEach(async () => {
  await rules.clearFirestore();
  await db
    .doc('config/flags')
    .set({ product_analytics: { enabled: true, scope: 'all', percent: 100, notice: null } });
});
async function family(i: number) {
  const uid = `user_${i}`,
    babyId = `baby_${i}`,
    familyId = `family_${i}`;
  await db.doc(`families/${familyId}`).set({ babyIds: [babyId], ownerUid: uid });
  await db
    .doc(`babies/${babyId}`)
    .set({ familyId, state: 'active', timeZone: { zone: 'Asia/Ho_Chi_Minh' } });
  await db.doc(`babies/${babyId}/members/${uid}`).set({ uid, role: 'coParent', status: 'active' });
  await db
    .doc(`babies/${babyId}/restricted/profile`)
    .set({ dateOfBirth: '2026-04-01', nickname: 'PRIVATE_CHILD_NAME' });
  await recordAnalyticsRegistration(db, uid, created, created);
  return {
    uid,
    babyId,
    familyId,
    caller: { uid, email: null, anonymous: false, locale: 'vi' as const },
  };
}
function observation(uid: string, babyId?: string) {
  return {
    schemaVersion: 1,
    receiptId: randomUUID(),
    ownerUid: uid,
    occurredAt: created.toISOString(),
    event: babyId ? 'family_context_viewed' : 'app_foreground_observed',
    platform: 'ios',
    locale: 'vi',
    ...(babyId ? { babyId } : {}),
  };
}
async function finishQueries() {
  const jobs = await db.collection('productAnalyticsQueries').where('state', '==', 'pending').get();
  for (const q of jobs.docs) await buildProductAnalyticsQuery(db, q.id, now);
}

it('validates actual shared media visibility before recording a family view', async () => {
  const f = await family(2);
  const media = db.doc(`babies/${f.babyId}/media/photo`);
  await media.set({
    status: 'ready',
    deleted: false,
    effectiveAudience: 'family',
    createdBy: 'another-parent',
  });
  await db.doc(`babies/${f.babyId}/members/${f.uid}`).update({ role: 'relative' });
  const event = {
    ...observation(f.uid, f.babyId),
    event: 'family_content_viewed',
    sourceId: 'photo',
  };
  expect(await recordAnalyticsObservation(db, f.caller, event, created)).toEqual({
    recorded: true,
  });
  await media.update({ effectiveAudience: 'parents' });
  await expect(
    recordAnalyticsObservation(db, f.caller, { ...event, receiptId: randomUUID() }, created),
  ).rejects.toMatchObject({ reason: 'not-a-member' });
  await media.update({ effectiveAudience: 'family', deleted: true });
  await expect(
    recordAnalyticsObservation(db, f.caller, { ...event, receiptId: randomUUID() }, created),
  ).rejects.toMatchObject({ reason: 'not-a-member' });
});

it('does not turn metadata recovery into a selected registration denominator', async () => {
  await recordAnalyticsRegistration(db, 'recovered', created, now, 'auth_metadata');
  const ref = db.doc('productAnalyticsAccounts/recovered');
  expect((await ref.get()).get('registrationVerified')).toBe(false);
  await recordAnalyticsRegistration(db, 'recovered', created, now, 'auth_create');
  expect((await ref.get()).get('registrationVerified')).toBe(true);
});

it('uses ready time for historical imports and stops new collection through the kill switch', async () => {
  const f = await family(4);
  await recordAnalyticsDomain(
    db,
    f.babyId,
    'historical',
    'memory_ready',
    {
      createdBy: f.uid,
      captureAt: new Date('2026-04-10'),
      readyAt: created,
    },
    now,
    { meaningful: true },
  );
  const rows = await db.collection('productAnalyticsFacts').get();
  expect(rows.size).toBe(1);
  expect(rows.docs[0]!.get('day')).toBe('2026-10-01');
  expect(rows.docs[0]!.get('captureAt')).toBeUndefined();
  await db.doc('config/flags').set({});
  expect(await recordAnalyticsObservation(db, f.caller, observation(f.uid), created)).toEqual({
    recorded: false,
  });
  expect((await db.collection('productAnalyticsFacts').get()).size).toBe(1);
});

it('attributes a saved Story to the actual saver rather than the original draft author', async () => {
  const f = await family(5);
  await recordAnalyticsDomain(
    db,
    f.babyId,
    'story',
    'story_saved',
    {
      createdBy: 'original-draft-author',
      savedBy: f.uid,
      savedAt: created,
    },
    now,
    { meaningful: true },
  );
  const rows = await db.collection('productAnalyticsFacts').get();
  expect(rows.docs[0]!.get('uid')).toBe(f.uid);
});

it('connects real registration/domain receipts through aggregates to the staff API, idempotently', async () => {
  for (let i = 0; i < 21; i++) {
    const f = await family(i);
    const foreground = observation(f.uid),
      context = observation(f.uid, f.babyId);
    await recordAnalyticsObservation(db, f.caller, foreground, created);
    await recordAnalyticsObservation(db, f.caller, foreground, created);
    await recordAnalyticsObservation(db, f.caller, context, created);
    const data = { createdBy: f.uid, readyAt: new Date('2026-10-02T03:00:00Z') };
    await recordAnalyticsDomain(db, f.babyId, 'media_1', 'memory_ready', data, now, {
      meaningful: true,
    });
    await recordAnalyticsDomain(db, f.babyId, 'media_1', 'memory_ready', data, now, {
      meaningful: true,
    });
  }
  expect((await productAnalytics(db, admin, query, now)).status).toBe('preparing');
  await finishQueries();
  const result = await productAnalytics(db, admin, query, now);
  expect(result.status).toBe('ready');
  expect(result.metrics.find((m) => m.id === 'A01')?.value).toBe(21);
  expect(result.metrics.find((m) => m.id === 'A02')?.value).toBe(21);
  expect(result.metrics.find((m) => m.id === 'A03')?.value).toBe(21);
  expect(result.metrics.find((m) => m.id === 'A08')).toMatchObject({
    numerator: 21,
    denominator: 21,
  });
  const memories = await productAnalytics(db, admin, { ...query, section: 'memories' }, now);
  expect(memories.metrics.find((m) => m.id === 'M_ready')?.value).toBe(21);
  expect(memories.metrics.find((m) => m.id === 'M_cloud_conversion')?.value).toBeNull();
  expect(JSON.stringify(result)).not.toMatch(/PRIVATE_CHILD_NAME|user_0|family_0|baby_0/);
  expect((await db.collection('productAnalyticsFacts').get()).size).toBe(63);
}, 40_000);

it('rejects client completions, raw data, stale-owner queues and revoked source access', async () => {
  const f = await family(1),
    valid = observation(f.uid, f.babyId);
  await expect(
    recordAnalyticsObservation(db, f.caller, { ...valid, ownerUid: 'another' }, created),
  ).rejects.toMatchObject({ reason: 'stale-owner' });
  await expect(
    recordAnalyticsObservation(db, f.caller, { ...valid, event: 'memory_ready' }, created),
  ).rejects.toMatchObject({ reason: 'malformed' });
  await expect(
    recordAnalyticsObservation(db, f.caller, { ...valid, photoKitId: 'private' }, created),
  ).rejects.toMatchObject({ reason: 'malformed' });
  await db.doc(`babies/${f.babyId}/members/${f.uid}`).update({ status: 'removed' });
  await expect(recordAnalyticsObservation(db, f.caller, valid, created)).rejects.toMatchObject({
    reason: 'not-a-member',
  });
  expect((await db.collection('productAnalyticsFacts').get()).empty).toBe(true);
});

it('denies direct client reads/writes, including their own private observation and query documents', async () => {
  const f = await family(1);
  await recordAnalyticsObservation(db, f.caller, observation(f.uid), created);
  const fact = (await db.collection('productAnalyticsFacts').get()).docs[0]!;
  const client = rules.authenticatedContext(f.uid).firestore();
  await assertFails(getDoc(doc(client, fact.ref.path)));
  await assertFails(getDoc(doc(client, `productAnalyticsAccounts/${f.uid}`)));
  await assertFails(setDoc(doc(client, 'productAnalyticsQueries/forged'), { request: query }));
  await assertFails(setDoc(doc(client, 'productAnalyticsFacts/forged'), { event: 'memory_ready' }));
});

it('purges identity contributions, fences stale writers and invalidates cached aggregates', async () => {
  const f = await family(1);
  await recordAnalyticsObservation(db, f.caller, observation(f.uid), created);
  await productAnalytics(db, admin, query, now);
  await finishQueries();
  const old = (await db.collection('productAnalyticsQueries').get()).docs[0]!;
  const epoch = old.get('privacyEpoch');
  await purgeProductAnalytics(db, 'uid', f.uid, now);
  expect((await db.collection('productAnalyticsFacts').get()).empty).toBe(true);
  expect((await db.doc(`productAnalyticsAccounts/${f.uid}`).get()).exists).toBe(false);
  expect(
    await recordAnalyticsFact(
      db,
      'late-in-flight',
      { event: 'app_foreground_observed', uid: f.uid, at: now },
      now,
    ),
  ).toBe(false);
  expect((await db.doc('productAnalyticsState/current').get()).get('privacyEpoch')).toBeGreaterThan(
    epoch,
  );
  expect((await productAnalytics(db, admin, query, now)).status).toBe('preparing');
});

it('keeps deletion barriers correct under duplicate concurrent deletion deliveries', async () => {
  const f = await family(3);
  await recordAnalyticsObservation(db, f.caller, observation(f.uid), created);
  await Promise.all([
    purgeProductAnalytics(db, 'uid', f.uid, now),
    purgeProductAnalytics(db, 'uid', f.uid, now),
  ]);
  expect((await db.doc('productAnalyticsState/current').get()).get('purgesActive')).toBe(0);
  expect((await db.collection('productAnalyticsFacts').where('uid', '==', f.uid).get()).empty).toBe(
    true,
  );
});

it('enforces cost/export permissions and shows unknown invoice costs without synthetic values', async () => {
  await expect(productAnalytics(db, qa, query, now)).rejects.toMatchObject({ reason: 'role' });
  await db.doc('aiUsageDaily/2026-10-03').set({
    day: '2026-10-03',
    calls: 3,
    knownUsage: 2,
    unknownUsage: 1,
    inputTokens: 100,
    outputTokens: 20,
    cachedInputTokens: 0,
    ratedCalls: 2,
    estimatedCostUsdMicros: 1234,
  });
  const costQuery = { ...query, section: 'cost' };
  await productAnalytics(db, admin, costQuery, now);
  await finishQueries();
  const cost = await exportProductAnalytics(db, admin, costQuery, now);
  expect(cost.metrics.find((m) => m.id === 'C_estimate')?.value).toBe(0.001234);
  expect(cost.metrics.find((m) => m.id === 'C_actual')).toMatchObject({
    value: null,
    reason: 'no_source',
  });
  expect(
    (await db.collection('staffAudit').where('action', '==', 'analytics.export').get()).size,
  ).toBe(1);
});
