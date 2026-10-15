import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { Timestamp, getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  defaultEntitlementsConfig,
  keepsakeSeedV1,
  premiumCapabilities,
  quotaInvariantHolds,
} from '@child-life/contracts';
import {
  completeKeepsakeJob,
  getVideoQuota,
  keepsakeJobChanged,
  requestMemoryStory,
  reservationIdOf,
  retryMemoryStory,
  sweepKeepsakeJobs,
  type RenderDispatcher,
} from '../functions/src/keepsake-jobs.js';
import type { ImageOps, MediaStore } from '../functions/src/memories.js';

// Video kỷ niệm quota ledger (Q2, brief p.10, plan §5.3) against the Firestore emulator: M10
// (concurrency), M11 (one commit or one release), M12 (expiry), gating before the ledger, MO04.
// Its own project: it rewrites `config/*`. Synthetic `test_` ids only.
const projectId = 'demo-child-life-video-quota';
let app: App;
let db: Firestore;
const now = new Date('2026-10-14T03:00:00Z');
const babyId = 'test_vq_b1';
const familyId = 'test_vq_f1';
const zone = 'Asia/Ho_Chi_Minh';
const calWindow = 'video_cal_2026-10';

class FakeStore implements MediaStore {
  files = new Map<string, Uint8Array>();
  async head(path: string, n: number) {
    return this.files.get(path)?.slice(0, n) ?? null;
  }
  async read(path: string) {
    return this.files.get(path) ?? null;
  }
  async save(path: string, bytes: Uint8Array) {
    this.files.set(path, bytes);
  }
  async move(from: string, to: string) {
    this.files.set(to, this.files.get(from)!);
    this.files.delete(from);
  }
  async size(path: string) {
    return this.files.get(path)?.length ?? null;
  }
  async delete(path: string) {
    this.files.delete(path);
  }
}
const images = {
  jpeg: async (input: Uint8Array) => ({ bytes: input.slice(0, 10), width: 1080, height: 1920 }),
} as unknown as ImageOps;

const photo = (i: number) => `med_${String(i).padStart(32, '0')}`;
const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason ?? String(e),
  );
const on = () => ({ enabled: true, scope: 'all', percent: 0, notice: null });
const request = (over: Record<string, unknown> = {}) => ({
  requestId: randomUUID(),
  babyId,
  templateId: 'video_first_month',
  templateVersion: 1,
  mediaIds: [1, 2, 3, 4, 5, 6].map(photo),
  texts: { title: '', message: '' },
  audience: 'parents',
  occasion: 'm1',
  ...over,
});
const setVideoLimits = (free: number, premium = 5) =>
  db.doc('config/entitlements').set({
    ...defaultEntitlementsConfig,
    regions: { advanced: ['VN'] },
    quotas: {
      ...defaultEntitlementsConfig.quotas,
      video: {
        free: { limit: free, window: 'calendar_month' },
        premium: { limit: premium, window: 'billing_period' },
      },
    },
  });
const window = async (id: string) => {
  const d = await db.doc(`families/${familyId}/quota/${id}`).get();
  return {
    limit: (d.get('limit') as number) ?? 0,
    used: (d.get('used') as number) ?? 0,
    reserved: (d.get('reserved') as number) ?? 0,
  };
};
const opState = async (id: string) =>
  (await db.doc(`families/${familyId}/quotaOps/${id}`).get()).get('state') as string | undefined;
const jobDoc = (jobId: string) => db.doc(`babies/${babyId}/keepsakeJobs/${jobId}`);
/** What the renderer does: claim with a lease, then complete carrying it. */
const renderDone = async (jobId: string, lease = 1) => {
  await jobDoc(jobId).update({
    status: 'completed',
    lease,
    output: { durationMs: 30_000, width: 1080, height: 1920, bytes: 1000, lease },
  });
};
const fail = async (jobId: string) => {
  const before = await jobDoc(jobId).get();
  await jobDoc(jobId).update({ status: 'failed', error: 'render-failed' });
  return { before, after: await jobDoc(jobId).get() };
};

beforeAll(() => {
  app = initializeApp({ projectId }, `video-quota-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => deleteApp(app));
beforeEach(async () => {
  for (const c of ['babies', 'families', 'config', 'publicConfig']) {
    await db.recursiveDelete(db.collection(c));
  }
  await db.doc(`babies/${babyId}`).set({
    familyId,
    nickname: 'Teddy',
    state: 'active',
    timeZone: { mode: 'auto', zone },
  });
  await db.doc(`babies/${babyId}/restricted/profile`).set({ dateOfBirth: '2026-09-17' });
  for (const [uid, role] of [
    ['test_mom', 'coParent'],
    ['test_dad', 'coParent'],
    ['test_grandma', 'relative'],
  ] as const) {
    await db.doc(`babies/${babyId}/members/${uid}`).set({
      uid,
      role,
      isOwner: uid === 'test_mom',
      status: 'active',
      displayName: uid,
      relation: 'mother',
      relationCustom: null,
    });
  }
  await db.doc(`families/${familyId}`).set({
    ownerUid: 'test_mom',
    country: 'VN',
    timeZone: zone,
    quotaBytes: 10 * 1024 ** 3,
    usedBytes: 0,
  });
  await db.doc('config/flags').set({ media_upload: on(), memory_story: on() });
  await setVideoLimits(1);
  await db.doc('publicConfig/keepsakes').set({
    version: 'ks_test',
    templates: keepsakeSeedV1.templates,
    premium: keepsakeSeedV1.premium,
  });
  for (let i = 1; i <= 8; i++) {
    await db.doc(`babies/${babyId}/media/${photo(i)}`).set({
      id: photo(i),
      babyId,
      type: 'photo',
      status: 'ready',
      deleted: false,
      captureAt: new Date(`2026-10-0${i}T02:00:00Z`),
      paths: { display: `babies/${babyId}/media/${photo(i)}/display.jpg` },
    });
  }
});

describe('reserve with the job (Q2)', () => {
  it('free template + quota left: one job, one reservation, the snapshot in the answer', async () => {
    const r = await requestMemoryStory(db, null, 'test_mom', request(), now, 'test');
    expect(r.quota).toEqual({
      limit: 1,
      used: 0,
      reserved: 1,
      // Next month starts at 00:00 in Asia/Ho_Chi_Minh (UTC+7).
      resetsAt: '2026-10-31T17:00:00.000Z',
    });
    const job = await jobDoc(r.jobId).get();
    expect(job.get('quota')).toEqual({
      reservationId: reservationIdOf(r.jobId, 0),
      windowId: calWindow,
      seq: 0,
    });
    expect(job.get('lease')).toBe(0);
    expect(await opState(reservationIdOf(r.jobId, 0))).toBe('reserved');
    // The same press again: the same job, nothing more held.
    const again = await requestMemoryStory(
      db,
      null,
      'test_mom',
      { ...request(), requestId: job.get('requestId') as string },
      now,
      'test',
    );
    expect(again.jobId).toBe(r.jobId);
    expect(await window(calWindow)).toEqual({ limit: 1, used: 0, reserved: 1 });
  });

  it('QUOTA_EXCEEDED when the window is full; MO04 shows it', async () => {
    const r = await requestMemoryStory(db, null, 'test_mom', request(), now, 'test');
    await renderDone(r.jobId);
    await completeKeepsakeJob(db, new FakeStore(), images, babyId, r.jobId, now);
    expect(await reason(requestMemoryStory(db, null, 'test_dad', request(), now, 'test'))).toBe(
      'QUOTA_EXCEEDED',
    );
    expect(await getVideoQuota(db, 'test_dad', { babyId }, now, 'test')).toEqual({
      limit: 1,
      used: 1,
      reserved: 0,
      resetsAt: '2026-10-31T17:00:00.000Z',
      // Free budget: the paid plan's limit is offered for "Khi hết lượt".
      premiumLimit: 5,
    });
    expect(await reason(getVideoQuota(db, 'test_grandma', { babyId }, now, 'test'))).toBe(
      'not-allowed',
    );
  });

  it('a Cao cấp template is refused with quota left and no entitlement; nothing is held', async () => {
    await db.doc('publicConfig/keepsakes').set({
      version: 'ks_test',
      templates: keepsakeSeedV1.templates.map((t) =>
        t.id === 'video_first_month' ? { ...t, tier: 'premium' } : t,
      ),
      premium: { access: 'subscribers', badges: true },
    });
    expect(await reason(requestMemoryStory(db, null, 'test_mom', request(), now, 'test'))).toBe(
      'PREMIUM_REQUIRED',
    );
    expect((await db.doc(`families/${familyId}/quota/${calWindow}`).get()).exists).toBe(false);
    expect((await db.collection(`families/${familyId}/quotaOps`).get()).size).toBe(0);
  });
});

describe('M10 · twenty presses at once on one slot', () => {
  it('at most one is accepted and the invariant holds', async () => {
    const results = await Promise.all(
      Array.from({ length: 20 }, (_, i) =>
        reason(
          requestMemoryStory(db, null, i % 2 ? 'test_dad' : 'test_mom', request(), now, 'test'),
        ),
      ),
    );
    const accepted = results.filter((r) => r === 'ok').length;
    expect(accepted).toBeLessThanOrEqual(1);
    expect(accepted).toBe(1);
    for (const r of results.filter((x) => x !== 'ok')) {
      expect(['QUOTA_EXCEEDED', 'busy']).toContain(r);
    }
    const w = await window(calWindow);
    expect(quotaInvariantHolds(w)).toBe(true);
    expect(w).toEqual({ limit: 1, used: 0, reserved: 1 });
    expect((await db.collection(`babies/${babyId}/keepsakeJobs`).get()).size).toBe(1);
    expect((await db.collection(`families/${familyId}/quotaOps`).get()).size).toBe(1);
  });
});

describe('M11 · one commit or one release per reservation', () => {
  it('the success callback twice (and at once) commits once', async () => {
    const r = await requestMemoryStory(db, null, 'test_mom', request(), now, 'test');
    await renderDone(r.jobId);
    const store = new FakeStore();
    const both = await Promise.all([
      completeKeepsakeJob(db, store, images, babyId, r.jobId, now),
      completeKeepsakeJob(db, store, images, babyId, r.jobId, now),
    ]);
    expect(both.filter((x) => x === 'filed')).toHaveLength(1);
    expect(await completeKeepsakeJob(db, store, images, babyId, r.jobId, now)).toBe('ignored');
    expect(await window(calWindow)).toEqual({ limit: 1, used: 1, reserved: 0 });
    expect(await opState(reservationIdOf(r.jobId, 0))).toBe('committed');
  });

  it('a stale worker completion (old lease) is refused and commits nothing', async () => {
    const r = await requestMemoryStory(db, null, 'test_mom', request(), now, 'test');
    await jobDoc(r.jobId).update({
      status: 'completed',
      lease: 2,
      output: { durationMs: 1, width: 1080, height: 1920, bytes: 1, lease: 1 },
    });
    expect(await completeKeepsakeJob(db, new FakeStore(), images, babyId, r.jobId, now)).toBe(
      'ignored',
    );
    expect(await window(calWindow)).toEqual({ limit: 1, used: 0, reserved: 1 });
  });

  it('the failure callback twice releases once; a retry takes a new reservation', async () => {
    const r = await requestMemoryStory(db, null, 'test_mom', request(), now, 'test');
    const { before, after } = await fail(r.jobId);
    await keepsakeJobChanged(db, null, babyId, r.jobId, before, after, now);
    await keepsakeJobChanged(db, null, babyId, r.jobId, before, after, now);
    expect(await window(calWindow)).toEqual({ limit: 1, used: 0, reserved: 0 });
    expect(await opState(reservationIdOf(r.jobId, 0))).toBe('released');

    const retried = await retryMemoryStory(
      db,
      null,
      'test_mom',
      { babyId, jobId: r.jobId },
      now,
      'test',
    );
    expect(retried).toMatchObject({ status: 'queued', quota: { used: 0, reserved: 1 } });
    expect((await jobDoc(r.jobId).get()).get('quota.reservationId')).toBe(
      reservationIdOf(r.jobId, 1),
    );
    // The first failure's trigger delivered late: the new reservation is untouched.
    await keepsakeJobChanged(db, null, babyId, r.jobId, before, after, now);
    expect(await opState(reservationIdOf(r.jobId, 1))).toBe('reserved');
    expect(await window(calWindow)).toEqual({ limit: 1, used: 0, reserved: 1 });
    await renderDone(r.jobId);
    await completeKeepsakeJob(db, new FakeStore(), images, babyId, r.jobId, now);
    expect(await window(calWindow)).toEqual({ limit: 1, used: 1, reserved: 0 });
    expect((await db.collection(`babies/${babyId}/keepsakeJobs`).get()).size).toBe(1);
  });

  it('a retry before the failure trigger ran releases and re-reserves in one go', async () => {
    const r = await requestMemoryStory(db, null, 'test_mom', request(), now, 'test');
    await jobDoc(r.jobId).update({ status: 'failed', error: 'render-failed' });
    const retried = await retryMemoryStory(
      db,
      null,
      'test_mom',
      { babyId, jobId: r.jobId },
      now,
      'test',
    );
    expect(retried.status).toBe('queued');
    expect(await opState(reservationIdOf(r.jobId, 0))).toBe('released');
    expect(await opState(reservationIdOf(r.jobId, 1))).toBe('reserved');
    expect(await window(calWindow)).toEqual({ limit: 1, used: 0, reserved: 1 });
  });

  it('a retry with the window full is refused and the job stays failed', async () => {
    await setVideoLimits(2);
    const a = await requestMemoryStory(db, null, 'test_mom', request(), now, 'test');
    const { before, after } = await fail(a.jobId);
    await keepsakeJobChanged(db, null, babyId, a.jobId, before, after, now);
    const b = await requestMemoryStory(db, null, 'test_dad', request(), now, 'test');
    await renderDone(b.jobId);
    await completeKeepsakeJob(db, new FakeStore(), images, babyId, b.jobId, now);
    await setVideoLimits(1);
    expect(
      await reason(retryMemoryStory(db, null, 'test_mom', { babyId, jobId: a.jobId }, now, 'test')),
    ).toBe('QUOTA_EXCEEDED');
    expect((await jobDoc(a.jobId).get()).get('status')).toBe('failed');
  });

  it('the sweeper releases an abandoned job once; dispatch failure releases before any worker', async () => {
    const r = await requestMemoryStory(db, null, 'test_mom', request(), now, 'test');
    await jobDoc(r.jobId).update({
      status: 'rendering',
      lease: 1,
      startedAt: new Date(now.getTime() - 60 * 60_000),
    });
    const store = new FakeStore();
    expect(await sweepKeepsakeJobs(db, store, now)).toBe(1);
    expect(await sweepKeepsakeJobs(db, store, now)).toBe(0);
    expect((await jobDoc(r.jobId).get()).get('error')).toBe('timeout');
    expect(await window(calWindow)).toEqual({ limit: 1, used: 0, reserved: 0 });
    expect(await opState(reservationIdOf(r.jobId, 0))).toBe('released');

    const broken: RenderDispatcher = {
      dispatch: async () => Promise.reject(new Error('queue down')),
    };
    await db.recursiveDelete(db.collection(`babies/${babyId}/keepsakeJobs`));
    const req = request();
    expect(await reason(requestMemoryStory(db, broken, 'test_mom', req, now, 'test'))).not.toBe(
      'ok',
    );
    const jobs = await db.collection(`babies/${babyId}/keepsakeJobs`).get();
    expect(jobs.docs[0]!.get('status')).toBe('failed');
    expect(jobs.docs[0]!.get('error')).toBe('unavailable');
    expect(await window(calWindow)).toEqual({ limit: 1, used: 0, reserved: 0 });
  });
});

describe('M12 · a paid period ends while a job runs', () => {
  it('reserved before expiry completes after it; a new request uses the free window', async () => {
    await setVideoLimits(1, 3);
    const grantId = 'paid_apple_test';
    await db.doc(`families/${familyId}/grants/${grantId}`).set({
      familyId,
      source: 'paid',
      status: 'active',
      environment: 'test',
      capabilities: [...premiumCapabilities],
      validFrom: Timestamp.fromDate(new Date('2026-09-14T03:00:00Z')),
      validUntil: Timestamp.fromDate(new Date('2026-10-14T04:00:00Z')),
      periodStart: Timestamp.fromDate(new Date('2026-09-14T03:00:00Z')),
      billingOwnerUid: 'test_mom',
      provider: 'apple',
      sourceRef: 'apple_test',
      campaignId: null,
      autoRenew: false,
      updatedAt: Timestamp.fromDate(new Date('2026-09-14T03:00:00Z')),
    });
    // Cao cấp in subscribers mode: allowed while the grant is valid.
    await db.doc('publicConfig/keepsakes').set({
      version: 'ks_test',
      templates: keepsakeSeedV1.templates.map((t) =>
        t.id === 'video_first_month' ? { ...t, tier: 'premium' } : t,
      ),
      premium: { access: 'subscribers', badges: true },
    });
    const paidWindow = `video_paid_${grantId}_2026-09-14`;
    const r = await requestMemoryStory(db, null, 'test_mom', request(), now, 'test');
    expect(r.quota).toEqual({
      limit: 3,
      used: 0,
      reserved: 1,
      resetsAt: '2026-10-14T04:00:00.000Z',
    });
    const template = (await jobDoc(r.jobId).get()).get('input.template.tier');
    expect(template).toBe('premium');

    // The period ends; the job, frozen on its template, still completes and commits there.
    const later = new Date('2026-10-14T05:00:00Z');
    await renderDone(r.jobId);
    expect(await completeKeepsakeJob(db, new FakeStore(), images, babyId, r.jobId, later)).toBe(
      'filed',
    );
    expect(await window(paidWindow)).toEqual({ limit: 3, used: 1, reserved: 0 });

    // A new request: the Cao cấp template is now refused, a free one counts in the free month.
    expect(await reason(requestMemoryStory(db, null, 'test_mom', request(), later, 'test'))).toBe(
      'PREMIUM_REQUIRED',
    );
    await db.doc('publicConfig/keepsakes').set({
      version: 'ks_test',
      templates: keepsakeSeedV1.templates,
      premium: keepsakeSeedV1.premium,
    });
    const free = await requestMemoryStory(db, null, 'test_mom', request(), later, 'test');
    expect(free.quota).toMatchObject({ limit: 1, used: 0, reserved: 1 });
    expect((await jobDoc(free.jobId).get()).get('quota.windowId')).toBe(calWindow);
  });
});
