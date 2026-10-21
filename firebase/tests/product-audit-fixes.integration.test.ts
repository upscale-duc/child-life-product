import { randomUUID } from 'node:crypto';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, afterAll, it, expect } from 'vitest';
import { keepsakeSeedV1, localDateIn } from '@child-life/contracts';
import {
  completeKeepsakeJob,
  outputIdsOf,
  retryMemoryStory,
} from '../functions/src/keepsake-jobs.js';
import { requestBabyDeletion, runDeletionJob, type JobDeps } from '../functions/src/account.js';
import { storyLocale } from '../functions/src/stories.js';
import { recordAiCall, type AiCallUsage } from '../functions/src/ai-telemetry.js';
import { recordProductOutcome } from '../functions/src/product-outcomes.js';
import type { MediaStore, ImageOps } from '../functions/src/memories.js';
const app = initializeApp({ projectId: 'demo-child-life-product-fixes' }, randomUUID());
const db = getFirestore(app);
const babyId = 'b_aaaaaaaaaaaaaaaaaaaa',
  familyId = 'f_test',
  uid = 'parent';
const jobId = `ksj_${'a'.repeat(32)}`;
const now = new Date('2026-10-21T12:00:00Z');
const store = {
  read: async () => null,
  delete: async () => {},
  save: async () => {},
} as unknown as MediaStore;
const images = {} as ImageOps;
beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw Error('Emulator required');
});
afterAll(() => deleteApp(app));
beforeEach(async () => {
  for (const c of await db.listCollections()) await db.recursiveDelete(c);
  await db.doc(`babies/${babyId}`).set({
    state: 'active',
    familyId,
    ownerUid: uid,
    nickname: 'Test',
    timeZone: { zone: 'Pacific/Honolulu' },
  });
  await db.doc(`families/${familyId}`).set({ usedBytes: 0, babyIds: [babyId] });
  await db
    .doc(`babies/${babyId}/members/${uid}`)
    .set({ uid, role: 'coParent', isOwner: true, status: 'active' });
});
async function completed() {
  const template = keepsakeSeedV1.templates.find((t) => t.id === 'video_first_month')!;
  await db.doc(`babies/${babyId}/keepsakeJobs/${jobId}`).set({
    status: 'completed',
    lease: 1,
    uid,
    familyId,
    audience: 'parents',
    occasion: 'm1',
    occasionDate: '2026-10-20',
    input: { template, locale: 'en', texts: { title: 'Title' } },
    output: { lease: 1, bytes: 123, width: 1080, height: 1920, durationMs: 1000 },
  });
}
it('does not recreate media or send a ready notice while the baby is deleting', async () => {
  await completed();
  await db.doc(`babies/${babyId}`).update({ state: 'deleting' });
  expect(await completeKeepsakeJob(db, store, images, babyId, jobId, now)).toBe('ignored');
  expect((await db.doc(`babies/${babyId}/media/${outputIdsOf(jobId).mediaId}`).get()).exists).toBe(
    false,
  );
  expect((await db.collection(`babies/${babyId}/notifications`).get()).empty).toBe(true);
});
it('files on the selected baby-local day and freezes English milestone metadata, once', async () => {
  await completed();
  expect(await completeKeepsakeJob(db, store, images, babyId, jobId, now)).toBe('filed');
  expect(await completeKeepsakeJob(db, store, images, babyId, jobId, now)).toBe('ignored');
  const media = await db.doc(`babies/${babyId}/media/${outputIdsOf(jobId).mediaId}`).get();
  expect(localDateIn('Pacific/Honolulu', media.get('captureAt').toDate())).toBe('2026-10-20');
  expect(media.get('milestone.name')).toBe(
    keepsakeSeedV1.templates.find((t) => t.id === 'video_first_month')!.name.en,
  );
  expect((await db.doc(`families/${familyId}`).get()).get('usedBytes')).toBe(123);
});
it('deletion waits for a bounded writer without exhausting retries, then verifies purge', async () => {
  const until = new Date(now.getTime() + 60_000);
  await db
    .doc(`babies/${babyId}/keepsakeJobs/${jobId}`)
    .set({ status: 'rendering', leaseUntilAt: until });
  const job = await requestBabyDeletion(
    db,
    { uid, email: null, anonymous: false, locale: 'en' },
    { babyId, confirmNickname: 'Test' },
    now,
  );
  const deps: JobDeps = {
    deleteAuthUser: async () => {},
    store: { deletePrefix: async () => {}, countPrefix: async () => 0, zip: async () => 0 },
  };
  expect(await runDeletionJob(db, deps, job.jobId, () => now)).toBe('skipped');
  const waiting = await db.doc(`deletionJobs/${job.jobId}`).get();
  expect(waiting.get('state')).toBe('queued');
  expect(waiting.get('attempts')).toBe(0);
  expect(await runDeletionJob(db, deps, job.jobId, () => new Date(until.getTime() + 1))).toBe(
    'done',
  );
  expect((await db.doc(`babies/${babyId}`).get()).exists).toBe(false);
});
it('scheduled locale uses the owner app language; explicit story choice wins', async () => {
  await db.doc(`users/${uid}/devices/test`).set({ language: 'en', updatedAt: now });
  expect(await storyLocale(db, babyId)).toBe('en');
  await db.doc(`babies/${babyId}/storyPreferences/locale`).set({ locale: 'vi' });
  expect(await storyLocale(db, babyId)).toBe('vi');
});
it('outcomes deduplicate replay and count an explicit household denominator', async () => {
  const calls = await Promise.all(
    [1, 2, 3].map(() => recordProductOutcome(db, babyId, 'media1', 'memoryReady', now)),
  );
  expect(calls.filter(Boolean)).toHaveLength(1);
  await recordProductOutcome(db, babyId, 'media2', 'memoryReady', now);
  await recordProductOutcome(db, babyId, 'story1', 'storySaved', now);
  const daily = await db.doc('productOutcomesDaily/2026-10-21').get();
  expect(daily.get('qualifiedFamilies')).toBe(1);
  expect(daily.get('actions.memoryReady')).toBe(2);
  expect(daily.get('households.memoryReady')).toBe(1);
  expect(daily.get('households.storySaved')).toBe(1);
  expect(JSON.stringify(daily.data())).not.toContain(babyId);
});
it('records actual model tokens, unknown usage and optional rate coverage, once per call', async () => {
  const call: AiCallUsage = {
    callId: randomUUID(),
    operation: 'understand',
    model: 'test-model',
    promptVersion: 'test',
    status: 'ok',
    durationMs: 10,
    inputTokens: 100,
    outputTokens: 20,
    cachedInputTokens: 10,
  };
  await db.doc('config/aiModelRates').set({
    currency: 'USD',
    version: 'test-v1',
    models: {
      'test-model': { inputPerMillion: 2, outputPerMillion: 4, cachedInputPerMillion: 1 },
    },
  });
  await recordAiCall(db, call, now);
  await recordAiCall(db, call, now);
  await recordAiCall(
    db,
    {
      ...call,
      callId: randomUUID(),
      status: 'timeout',
      inputTokens: null,
      outputTokens: null,
      cachedInputTokens: null,
    },
    now,
  );
  const day = await db.doc('aiUsageDaily/2026-10-21').get();
  expect(day.get('calls')).toBe(2);
  expect(day.get('knownUsage')).toBe(1);
  expect(day.get('unknownUsage')).toBe(1);
  expect(day.get('inputTokens')).toBe(100);
  expect(day.get('outputTokens')).toBe(20);
  expect(day.get('estimatedCostUsdMicros')).toBe(270);
  expect(day.get('unratedCalls')).toBe(1);
});

it('only one completed-job filer may write while its bounded lease is live', async () => {
  await completed();
  let release!: () => void;
  let entered!: () => void;
  const gate = new Promise<void>((r) => {
    release = r;
  });
  const reading = new Promise<void>((r) => {
    entered = r;
  });
  const blocked = {
    ...store,
    read: async () => {
      entered();
      await gate;
      return null;
    },
  } as MediaStore;
  const first = completeKeepsakeJob(db, blocked, images, babyId, jobId, now);
  await reading;
  await expect(completeKeepsakeJob(db, store, images, babyId, jobId, now)).rejects.toMatchObject({
    reason: 'busy',
  });
  release();
  expect(await first).toBe('filed');
  expect((await db.doc(`families/${familyId}`).get()).get('usedBytes')).toBe(123);
});

it.each(['UTC', 'Asia/Ho_Chi_Minh', 'Pacific/Kiritimati', 'America/New_York'])(
  'keeps the selected calendar date in %s, including the DST transition day',
  async (zone) => {
    await completed();
    await db.doc(`babies/${babyId}`).update({ timeZone: { zone } });
    await db.doc(`babies/${babyId}/keepsakeJobs/${jobId}`).update({ occasionDate: '2026-03-08' });
    expect(await completeKeepsakeJob(db, store, images, babyId, jobId, now)).toBe('filed');
    const media = await db.doc(`babies/${babyId}/media/${outputIdsOf(jobId).mediaId}`).get();
    expect(localDateIn(zone, media.get('captureAt').toDate())).toBe('2026-03-08');
  },
);

it.each(['deleting', 'revoked'] as const)(
  'refuses retry before reserving quota when the child is %s',
  async (boundary) => {
    await completed();
    await db.doc(`babies/${babyId}/keepsakeJobs/${jobId}`).update({ status: 'failed' });
    if (boundary === 'deleting') await db.doc(`babies/${babyId}`).update({ state: 'deleting' });
    else await db.doc(`babies/${babyId}/members/${uid}`).update({ status: 'removed' });
    await expect(retryMemoryStory(db, null, uid, { babyId, jobId }, now)).rejects.toMatchObject({
      reason: boundary === 'deleting' ? 'deleting' : 'not-allowed',
    });
    expect((await db.collection(`families/${familyId}/quotaOps`).get()).empty).toBe(true);
  },
);
