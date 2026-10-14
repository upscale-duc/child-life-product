import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { Timestamp, getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  defaultEntitlementsConfig,
  keepsakeChapter1Videos,
  keepsakeSeedV1,
  type KeepsakeJobInput,
} from '@child-life/contracts';
import {
  attachKeepsakeLive,
  completeKeepsakeJob,
  deleteMemoryStory,
  keepsakeJobChanged,
  jobIdOf,
  outputIdsOf,
  requestMemoryStory,
  retryMemoryStory,
  sweepKeepsakeJobs,
  type LiveSender,
  type RenderDispatcher,
} from '../functions/src/keepsake-jobs.js';
import type { ImageOps, MediaStore } from '../functions/src/memories.js';

// Video kỷ niệm jobs (D-068) against the Firestore emulator, with a fake dispatcher, store and
// image ops: request (checks, snapshot, idempotency), complete (filed once), retry and sweep.
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const now = new Date('2026-10-14T03:00:00Z');
const babyId = 'b_ks0000000000000001';
const familyId = 'f_ks0000000000000001';

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
const images: ImageOps = {
  jpeg: async (input) => ({ bytes: input.slice(0, 10), width: 1080, height: 1920 }),
} as ImageOps;

class FakeDispatcher implements RenderDispatcher {
  sent: string[] = [];
  async dispatch(_babyId: string, jobId: string, attempt: number) {
    this.sent.push(`${jobId}-${attempt}`);
  }
}

const photo = (i: number) => `med_${String(i).padStart(32, '0')}`;
const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason,
  );
const on = (scope = 'all') => ({ enabled: true, scope, percent: 0, notice: null });
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

beforeAll(() => {
  app = initializeApp({ projectId }, `keepsake-jobs-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => deleteApp(app));
beforeEach(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080';
  await fetch(`http://${host}/emulator/v1/projects/${projectId}/databases/(default)/documents`, {
    method: 'DELETE',
  });
  await db.doc(`babies/${babyId}`).set({ familyId, nickname: 'Teddy', state: 'active' });
  await db.doc(`babies/${babyId}/restricted/profile`).set({ dateOfBirth: '2026-09-17' });
  for (const [uid, role] of [
    ['mom', 'coParent'],
    ['dad', 'coParent'],
    ['grandma', 'relative'],
  ] as const) {
    await db.doc(`babies/${babyId}/members/${uid}`).set({
      uid,
      role,
      status: 'active',
      displayName: uid === 'mom' ? 'Mai' : uid,
      relation: 'mother',
      relationCustom: null,
    });
  }
  await db.doc(`families/${familyId}`).set({ quotaBytes: 10 * 1024 ** 3, usedBytes: 0 });
  await db.doc('config/flags').set({ media_upload: on(), memory_story: on() });
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

describe('requestMemoryStory', () => {
  it('Chapter 01: extra texts, the language, photo ages and birth stats are frozen (E-8, E-9)', async () => {
    await db.doc('publicConfig/keepsakes').set({
      version: 'ks_test',
      templates: [...keepsakeSeedV1.templates, ...keepsakeChapter1Videos],
      premium: keepsakeSeedV1.premium,
    });
    const tasks = new FakeDispatcher();
    const story = await requestMemoryStory(
      db,
      tasks,
      'mom',
      request({
        templateId: 'video_little_love_story',
        mediaIds: [1, 2, 3, 4, 5].map(photo),
        texts: { title: '', message: '', lines: 'One\nTwo' },
        locale: 'en',
      }),
      now,
    );
    const input = (await db.doc(`babies/${babyId}/keepsakeJobs/${story.jobId}`).get()).get(
      'input',
    ) as KeepsakeJobInput;
    expect(input.locale).toBe('en');
    expect(input.texts.title).toBe('A little love story began…');
    expect(input.texts.lines).toBe('One\nTwo');
    expect(input.texts.closing).toBe('You are our greatest love.');
    // Born 17.09, the first photo on 01.10 (in Asia/Ho_Chi_Minh): two weeks old.
    expect(input.photoInfo?.[0]).toEqual({ takenAt: '2026-10-01T02:00:00.000Z', label: 'Week 3' });

    // One video at a time per baby: the first one is done.
    await db.doc(`babies/${babyId}/keepsakeJobs/${story.jobId}`).update({ status: 'completed' });
    // V01: weight and length from the first growth record, no big mark at birth.
    await db.doc(`babies/${babyId}/records/g1`).set({
      type: 'growth',
      deleted: false,
      occurredAt: new Date('2026-09-18T03:00:00Z'),
      measuredOn: '2026-09-18',
      weightKg: 3.2,
      lengthCm: 50,
    });
    const welcome = await requestMemoryStory(
      db,
      tasks,
      'dad',
      request({
        templateId: 'video_welcome_world',
        mediaIds: [1, 2, 3, 4, 5].map(photo),
        occasion: 'birth',
      }),
      now,
    );
    const w = (await db.doc(`babies/${babyId}/keepsakeJobs/${welcome.jobId}`).get()).get(
      'input',
    ) as KeepsakeJobInput;
    expect(w.birthStats).toBe('3,2 kg · 50 cm');
    expect(w.mark).toBe(null);
    expect(w.texts.title).toBe('Chào con, Teddy');
  });

  it('freezes the inputs, dispatches once, and a repeated request is the same job', async () => {
    const tasks = new FakeDispatcher();
    const req = request();
    const r = await requestMemoryStory(db, tasks, 'mom', req, now);
    expect(r).toEqual({ jobId: jobIdOf('mom', req.requestId), status: 'queued' });
    const job = await db.doc(`babies/${babyId}/keepsakeJobs/${r.jobId}`).get();
    const input = job.get('input') as KeepsakeJobInput;
    expect(input.template.id).toBe('video_first_month');
    expect(input.photos).toEqual(
      [1, 2, 3, 4, 5, 6].map((i) => `babies/${babyId}/media/${photo(i)}/display.jpg`),
    );
    expect(input.texts.title).toBe('Tháng đầu tiên của Teddy');
    expect(input.mark).toBe('1');
    expect(input.dateLine).toBe('17.09 – 17.10.2026');
    expect(job.get('occasionDate')).toBe('2026-10-17');
    expect(tasks.sent).toEqual([`${r.jobId}-0`]);
    expect(await requestMemoryStory(db, tasks, 'mom', req, now)).toEqual(r);
    expect(tasks.sent).toHaveLength(1);
  });

  it('refuses: beta off, not a Cùng nuôi, photo count, a deleted photo, one at a time', async () => {
    const tasks = new FakeDispatcher();
    expect(await reason(requestMemoryStory(db, tasks, 'grandma', request(), now))).toBe(
      'not-allowed',
    );
    expect(
      await reason(
        requestMemoryStory(db, tasks, 'mom', request({ mediaIds: [photo(1), photo(2)] }), now),
      ),
    ).toBe('photo-count');
    await db.doc(`babies/${babyId}/media/${photo(3)}`).update({ deleted: true });
    expect(await reason(requestMemoryStory(db, tasks, 'mom', request(), now))).toBe(
      'photo-unavailable',
    );
    await db.doc(`babies/${babyId}/media/${photo(3)}`).update({ deleted: false });
    await requestMemoryStory(db, tasks, 'mom', request(), now);
    expect(await reason(requestMemoryStory(db, tasks, 'dad', request(), now))).toBe('busy');
    await db
      .doc('config/flags')
      .set({ media_upload: on(), memory_story: { ...on(), enabled: false } });
    expect(await reason(requestMemoryStory(db, tasks, 'dad', request(), now))).toBe('not-enabled');
  });

  it('a Cao cấp template is refused once the portal hides Cao cấp (D-068 #8)', async () => {
    await db.doc('publicConfig/keepsakes').set({
      version: 'ks_test',
      templates: keepsakeSeedV1.templates.map((t) =>
        t.id === 'video_first_month' ? { ...t, tier: 'premium' } : t,
      ),
      premium: { access: 'hidden', badges: true },
    });
    expect(await reason(requestMemoryStory(db, null, 'mom', request(), now))).toBe(
      'template-unavailable',
    );
  });

  it('subscribers mode: a Cao cấp video needs templates.premium, never from Beta A (Q1, E03)', async () => {
    await db.doc('publicConfig/keepsakes').set({
      version: 'ks_test',
      templates: keepsakeSeedV1.templates.map((t) =>
        t.id === 'video_first_month' ? { ...t, tier: 'premium' } : t,
      ),
      premium: { access: 'subscribers', badges: true },
    });
    await db.doc(`families/${familyId}`).set({ country: 'VN' }, { merge: true });
    await db.doc('config/entitlements').set({
      ...defaultEntitlementsConfig,
      regions: { advanced: ['VN'] },
      betaCampaigns: [
        {
          id: 'beta-a',
          capabilities: ['personalization.cross_module', 'rhythm.advanced', 'ai.assistance'],
          validFrom: '2026-10-01T00:00:00Z',
          validUntil: '2026-12-01T00:00:00Z',
          countries: [],
          scope: 'all',
          percent: 0,
        },
      ],
    });
    expect(await reason(requestMemoryStory(db, null, 'mom', request(), now))).toBe(
      'PREMIUM_REQUIRED',
    );
    await db.doc(`families/${familyId}/grants/promo_test`).set({
      familyId,
      source: 'promo',
      status: 'active',
      environment: 'test',
      capabilities: ['templates.premium'],
      validFrom: Timestamp.fromDate(new Date('2026-10-01T00:00:00Z')),
      validUntil: Timestamp.fromDate(new Date('2026-11-01T00:00:00Z')),
      billingOwnerUid: null,
      provider: 'staff',
      sourceRef: null,
      campaignId: 'audit_test',
      autoRenew: null,
      updatedAt: Timestamp.fromDate(new Date('2026-10-01T00:00:00Z')),
    });
    expect(await reason(requestMemoryStory(db, null, 'mom', request(), now))).toBe('ok');
  });
});

describe('completion, retry and the sweeper', () => {
  it('files the video once in Kỷ niệm, counts it, and tells only the person who asked', async () => {
    const store = new FakeStore();
    const { jobId } = await requestMemoryStory(db, null, 'mom', request(), now);
    const ids = outputIdsOf(jobId);
    store.files.set(`babies/${babyId}/media/${ids.mediaId}/frame.jpg`, new Uint8Array(500));
    await db.doc(`babies/${babyId}/keepsakeJobs/${jobId}`).update({
      status: 'completed',
      output: { durationMs: 45_000, width: 1080, height: 1920, bytes: 9_000_000 },
    });
    expect(await completeKeepsakeJob(db, store, images, babyId, jobId, now)).toBe('filed');
    expect(await completeKeepsakeJob(db, store, images, babyId, jobId, now)).toBe('ignored');
    const media = await db.doc(`babies/${babyId}/media/${ids.mediaId}`).get();
    expect(media.get('status')).toBe('ready');
    expect(media.get('type')).toBe('video');
    expect(media.get('audience')).toBe('parents');
    expect(media.get('generated')).toMatchObject({
      kind: 'video',
      templateId: 'video_first_month',
    });
    expect(media.get('paths.poster')).toBe(`babies/${babyId}/media/${ids.mediaId}/poster.jpg`);
    const memory = await db.doc(`babies/${babyId}/memories/${ids.memoryId}`).get();
    expect(memory.get('state')).toBe('published');
    expect(memory.get('notifyFamily')).toBe(false);
    expect(memory.get('caption')).toBe('Tháng đầu tiên của Teddy');
    expect((await db.doc(`families/${familyId}`).get()).get('usedBytes')).toBe(9_000_020);
    const notice = await db.doc(`babies/${babyId}/notifications/keepsake_${jobId}`).get();
    expect(notice.get('recipients')).toEqual(['mom']);
    expect(notice.get('kind')).toBe('keepsakeVideo');
  });

  it('a failed job can be tried again by the person who asked; the sweeper fails stuck ones', async () => {
    const tasks = new FakeDispatcher();
    const store = new FakeStore();
    const { jobId } = await requestMemoryStory(db, tasks, 'mom', request(), now);
    const ref = db.doc(`babies/${babyId}/keepsakeJobs/${jobId}`);
    await ref.update({ status: 'rendering', startedAt: new Date(now.getTime() - 20 * 60_000) });
    expect(await sweepKeepsakeJobs(db, store, now)).toBe(1);
    expect((await ref.get()).get('error')).toBe('timeout');
    expect(await reason(retryMemoryStory(db, tasks, 'dad', { babyId, jobId }, now))).toBe(
      'not-found',
    );
    expect(await retryMemoryStory(db, tasks, 'mom', { babyId, jobId }, now)).toEqual({
      jobId,
      status: 'queued',
    });
    expect(tasks.sent.at(-1)).toBe(`${jobId}-10`);
    expect((await ref.get()).get('status')).toBe('queued');
  });

  it('MM14 Xoá bản nháp: only the asker, only a failed video, with its partial files', async () => {
    const store = new FakeStore();
    const { jobId } = await requestMemoryStory(db, new FakeDispatcher(), 'mom', request(), now);
    const ref = db.doc(`babies/${babyId}/keepsakeJobs/${jobId}`);
    expect(await reason(deleteMemoryStory(db, store, 'mom', { babyId, jobId }))).toBe('not-failed');
    await ref.update({ status: 'failed', error: 'render-failed' });
    const dir = `babies/${babyId}/media/${outputIdsOf(jobId).mediaId}`;
    await store.save(`${dir}/frame.jpg`, new Uint8Array([1]));
    expect(await reason(deleteMemoryStory(db, store, 'dad', { babyId, jobId }))).toBe('not-found');
    expect(await deleteMemoryStory(db, store, 'mom', { babyId, jobId })).toEqual({
      jobId,
      status: 'deleted',
    });
    expect((await ref.get()).exists).toBe(false);
    expect(store.files.size).toBe(0);
    // Asked again: nothing left to delete.
    expect((await deleteMemoryStory(db, store, 'mom', { babyId, jobId })).status).toBe('unchanged');
  });

  it('MM08 Live Activity: attached by the asker, follows each step, ends; a failure tells them', async () => {
    const { jobId } = await requestMemoryStory(db, new FakeDispatcher(), 'mom', request(), now);
    const ref = db.doc(`babies/${babyId}/keepsakeJobs/${jobId}`);
    const live = { token: 'ab'.repeat(32), fcm: 'f'.repeat(40) };
    expect(await reason(attachKeepsakeLive(db, 'dad', { babyId, jobId, ...live }, now))).toBe(
      'not-found',
    );
    expect(
      await reason(attachKeepsakeLive(db, 'mom', { babyId, jobId, token: 'x', fcm: 'y' }, now)),
    ).toBe('malformed');
    await attachKeepsakeLive(db, 'mom', { babyId, jobId, ...live }, now);
    const sent: string[] = [];
    let gone = false;
    const sender: LiveSender = {
      async send(to, event, state) {
        expect(to).toEqual(live);
        sent.push(`${event}:${state.status}:${state.step}:${state.progress}`);
        return !gone;
      },
      async android() {
        throw new Error('an iPhone job does not go to Android');
      },
    };
    // Each write: what the trigger sees before and after.
    const step = async (update: Record<string, unknown>) => {
      const before = await ref.get();
      await ref.update(update);
      await keepsakeJobChanged(db, sender, babyId, jobId, before, await ref.get(), now);
    };
    await step({ status: 'rendering', step: 'arrange', progress: 2 });
    await step({ progress: 6 }); // the same 10 %: nothing sent
    await step({ step: 'compose', progress: 12 });
    await step({ step: 'export', progress: 35 });
    await step({ status: 'failed', error: 'render-failed' });
    expect(sent).toEqual([
      'update:rendering:arrange:2',
      'update:rendering:compose:12',
      'update:rendering:export:35',
      'end:failed:export:35',
    ]);
    const notice = await db.doc(`babies/${babyId}/notifications/keepsake_${jobId}_failed_0`).get();
    expect(notice.get('kind')).toBe('keepsakeVideoFailed');
    expect(notice.get('recipients')).toEqual(['mom']);
    expect(notice.get('context')).toEqual({ jobId });
    // An activity the phone ended is forgotten.
    gone = true;
    await step({ status: 'queued', step: null, progress: 0, retries: 1 });
    expect((await ref.get()).get('live')).toBeUndefined();
  });

  it('MM08 on Android: no activity token, the same moments go to the phone (A6)', async () => {
    const { jobId } = await requestMemoryStory(db, new FakeDispatcher(), 'mom', request(), now);
    const ref = db.doc(`babies/${babyId}/keepsakeJobs/${jobId}`);
    const fcm = 'a'.repeat(40);
    await attachKeepsakeLive(db, 'mom', { babyId, jobId, fcm }, now);
    expect((await ref.get()).get('live.token')).toBeNull();
    const sent: string[] = [];
    const sender: LiveSender = {
      async send() {
        throw new Error('an Android job has no Live Activity');
      },
      async android(to, job, event, state) {
        expect(to).toBe(fcm);
        expect(job).toEqual({ babyId, jobId });
        sent.push(`${event}:${state.status}:${state.step}:${state.progress}`);
        return true;
      },
    };
    const step = async (update: Record<string, unknown>) => {
      const before = await ref.get();
      await ref.update(update);
      await keepsakeJobChanged(db, sender, babyId, jobId, before, await ref.get(), now);
    };
    await step({ status: 'rendering', step: 'arrange', progress: 3 });
    await step({ progress: 8 });
    await step({ step: 'export', progress: 64 });
    await step({ status: 'completed', progress: 100 });
    expect(sent).toEqual([
      'update:rendering:arrange:3',
      'update:rendering:export:64',
      'end:completed:export:100',
    ]);
  });

  it('music: the template’s default, the parent’s pick, or none (MM07)', async () => {
    const track = {
      id: 'music_lullaby',
      title: { vi: 'Ru con', en: 'Lullaby' },
      artist: '',
      mood: 'gentle',
      durationSec: 60,
      asset: 'lullaby_1a2b3c4d.mp3',
      licence: { kind: 'licensed', source: 'Store', reference: 'INV-1', expiresOn: null },
      status: 'published',
      order: 1,
    };
    await db.doc('publicConfig/keepsakes').set({
      version: 'ks_test',
      templates: keepsakeSeedV1.templates.map((t) =>
        t.id === 'video_first_month' ? { ...t, defaultMusic: 'music_lullaby' } : t,
      ),
      premium: keepsakeSeedV1.premium,
      music: [track, { ...track, id: 'music_happy', asset: 'happy_1a2b3c4d.mp3' }],
    });
    const input = async (over: Record<string, unknown>) => {
      const { jobId } = await requestMemoryStory(db, null, 'mom', request(over), now);
      const job = await db.doc(`babies/${babyId}/keepsakeJobs/${jobId}`).get();
      await job.ref.update({ status: 'failed' });
      return (job.get('input') as KeepsakeJobInput).music;
    };
    expect(await input({})).toBe('content/keepsakes/lullaby_1a2b3c4d.mp3');
    expect(await input({ musicId: 'music_happy' })).toBe('content/keepsakes/happy_1a2b3c4d.mp3');
    expect(await input({ musicId: null })).toBe(null);
    expect(
      await reason(requestMemoryStory(db, null, 'mom', request({ musicId: 'music_nope' }), now)),
    ).toBe('music-unavailable');
  });
});
