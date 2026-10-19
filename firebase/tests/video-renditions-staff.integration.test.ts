import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  StaffError,
  overview,
  systemHealth,
  type AccountLister,
  type Staff,
} from '../functions/src/staff.js';
import {
  backfillVideoRenditions,
  parseMediaRef,
  requeueVideoRendition,
} from '../functions/src/staff-video.js';
import {
  renditionJobDoc,
  renditionJobId,
  renditionStats,
  type RenditionState,
} from '../functions/src/video-renditions.js';

// Streaming renditions in the portal (P-170; R-185 "Thử xử lý lại video", R-188) against the
// Firestore emulator: the day's counts, median and codes in A08, the "Cần xử lý" alert at three
// failures, a staff re-run of one video, and the prod backfill in batches — each audited with a
// reason, none carrying a caption or a name.
const projectId = 'demo-child-life';
const now = new Date('2026-10-19T09:00:00Z');
let app: App;
let db: Firestore;
const babyId = 'b_ca5e0000000000000012';
const familyId = 'f_ca5e0000000000000012';

const eng: Staff = { uid: 's_minh', name: 'Minh Phạm', roles: ['eng'] };
const ops: Staff = { uid: 's_linh', name: 'Linh Trần', roles: ['ops'] };
const accounts: AccountLister = { list: async () => [] };

let seq = 0;
const id = () => `med_${(++seq).toString(16).padStart(32, '0')}`;
const hoursAgo = (h: number) => new Date(now.getTime() - h * 3_600_000);

async function video(mediaId: string, over: Record<string, unknown> = {}) {
  const dir = `babies/${babyId}/media/${mediaId}`;
  await db.doc(dir).set({
    babyId,
    familyId,
    memoryId: 'mem_00000000000000000000000000000001',
    type: 'video',
    status: 'ready',
    deleted: false,
    contentType: 'video/quicktime',
    sizeBytes: 100_000_000,
    storedBytes: 100_000_000,
    paths: {
      original: `${dir}/original.mov`,
      thumb: `${dir}/thumb.jpg`,
      poster: `${dir}/poster.jpg`,
    },
    caption: 'Teddy tập đi lần đầu',
    createdBy: 'mom',
    createdAt: hoursAgo(48),
    updatedAt: hoursAgo(48),
    readyAt: hoursAgo(48),
    ...over,
  });
  return dir;
}

async function job(mediaId: string, attempt: number, patch: Record<string, unknown> = {}) {
  const jobId = renditionJobId(mediaId, attempt);
  await db
    .doc(`videoRenditionJobs/${jobId}`)
    .set({ ...renditionJobDoc(babyId, mediaId, hoursAgo(2), attempt), ...patch });
  return jobId;
}

/** A finished job: `activeSince` cleared, finished `agoH` hours ago. */
const done = (state: RenditionState, error: string | null, agoH = 1, tookMs?: number) => ({
  state,
  error,
  activeSince: null,
  finishedAt: hoursAgo(agoH),
  ...(tookMs === undefined ? {} : { tookMs }),
});

const reason = async (p: Promise<unknown>) => {
  try {
    await p;
    return 'ok';
  } catch (e) {
    return e instanceof StaffError ? e.reason : String(e);
  }
};

const audit = async (action: string) =>
  (await db.collection('staffAudit').where('action', '==', action).get()).docs.map((d) => d.data());

beforeAll(() => {
  app = initializeApp({ projectId }, `video-renditions-staff-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080'}/emulator/v1/projects/${projectId}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  await db.doc(`families/${familyId}`).set({
    id: familyId,
    babyIds: [babyId],
    quotaBytes: 10 * 1024 ** 3,
    usedBytes: 300_000_000,
    reservedBytes: 0,
  });
  await db.doc(`babies/${babyId}`).set({ id: babyId, familyId, state: 'active' });
});

describe('A08 rendition figures (R-188)', () => {
  it('counts the day by state, takes the median of ready jobs and lists codes newest first', async () => {
    const [a, b, c, d, e, f, g] = [id(), id(), id(), id(), id(), id(), id()];
    await job(a, 1, done('ready', null, 1, 40_000));
    await job(b, 1, done('ready', null, 1, 10_000));
    await job(c, 1, done('ready', null, 1, 90_000));
    await job(d, 1, done('failed', 'ffmpeg exit 1', 1));
    await job(e, 2, done('skipped', 'too-long', 3));
    // Deleted meanwhile: not worth a row.
    await job(f, 1, done('skipped', 'gone', 1));
    await job(g, 1);
    // Yesterday's jobs are outside the window.
    await job(id(), 1, { ...done('ready', null, 30, 5_000), createdAt: hoursAgo(30) });

    const s = await renditionStats(db, now);
    expect(s.counts).toEqual({ queued: 1, running: 0, ready: 3, failed: 1, skipped: 2, lost: 0 });
    expect(s.medianTookMs).toBe(40_000);
    expect(s.failedThreshold).toBe(3);
    expect(s.recent.map((r) => [r.jobId, r.mediaId, r.attempt, r.state, r.reason])).toEqual([
      [d, d, 1, 'failed', 'ffmpeg exit 1'],
      [`${e}~2`, e, 2, 'skipped', 'too-long'],
    ]);
    expect(s.recent[0]!.at).toBe(hoursAgo(1).toISOString());

    const h = await systemHealth(db, ops, now);
    expect(h.rendition).toEqual(s);
    expect(await reason(systemHealth(db, { ...ops, roles: ['support'] }, now))).toBe('role');
  });

  it('an empty day has no median; three failures in a day raise the "Cần xử lý" warning', async () => {
    expect((await renditionStats(db, now)).medianTookMs).toBeNull();
    await job(id(), 1, done('failed', 'timeout'));
    await job(id(), 1, done('failed', 'timeout'));
    const before = await overview(db, ops, { days: 7 }, now, accounts);
    expect(before.alerts.some((a) => a.kind === 'renditionFailed')).toBe(false);
    await job(id(), 1, done('failed', 'ffmpeg exit 1'));
    const after = await overview(db, ops, { days: 7 }, now, accounts);
    expect(after.alerts).toContainEqual({
      severity: 'warn',
      module: 'system',
      kind: 'renditionFailed',
      count: 3,
    });
  });
});

describe('"Thử xử lý lại video" (R-185)', () => {
  it('takes a media id, a job id or the item path', () => {
    const m = id();
    expect(parseMediaRef(m)).toEqual({ mediaId: m, babyId: null });
    expect(parseMediaRef(` ${m}~3 `)).toEqual({ mediaId: m, babyId: null });
    expect(parseMediaRef(`babies/${babyId}/media/${m}`)).toEqual({ mediaId: m, babyId });
    expect(
      parseMediaRef(
        `projects/child-life-prod/databases/(default)/documents/babies/${babyId}/media/${m}`,
      ),
    ).toEqual({ mediaId: m, babyId });
    expect(parseMediaRef('med_123')).toBeNull();
    expect(parseMediaRef(`babies/${babyId}/photos/${m}`)).toBeNull();
    expect(parseMediaRef(`families/${familyId}`)).toBeNull();
  });

  it('a failed video gets the next attempt, the item is queued again, and the log says why', async () => {
    const m = id();
    const dir = await video(m, {
      rendition: { state: 'failed', reason: 'ffmpeg exit 1', updatedAt: hoursAgo(1) },
    });
    await job(m, 1, done('failed', 'ffmpeg exit 1'));

    const r = await requeueVideoRendition(
      db,
      eng,
      { media: m, reason: 'Ticket T-1: ffmpeg sửa xong' },
      now,
    );
    expect(r).toEqual({ jobId: `${m}~2`, attempt: 2 });
    const j = (await db.doc(`videoRenditionJobs/${m}~2`).get()).data()!;
    expect(j).toMatchObject({ babyId, mediaId: m, state: 'queued', attempt: 2, error: null });
    expect(j.activeSince).not.toBeNull();
    const item = (await db.doc(dir).get()).data()!;
    expect(item.rendition.state).toBe('queued');
    expect(item.paths.display).toBeUndefined();
    expect(item.caption).toBe('Teddy tập đi lần đầu');

    const log = await audit('system.videoRequeue');
    expect(log).toHaveLength(1);
    expect(log[0]).toMatchObject({
      category: 'data',
      target: m,
      reason: 'Ticket T-1: ffmpeg sửa xong',
      actorUid: 's_minh',
      detail: {
        jobId: `${m}~2`,
        attempt: 2,
        previous: { state: 'failed', reason: 'ffmpeg exit 1' },
      },
    });
    expect(JSON.stringify(log)).not.toContain('Teddy');
    // Attempt 2 is queued now: no third one until it is done.
    expect(await reason(requeueVideoRendition(db, eng, { media: m, reason: 'again' }, now))).toBe(
      'already-queued',
    );
  });

  it('a video from before the feature is found by its path; by id only once a job named it', async () => {
    const m = id();
    await video(m);
    expect(
      await reason(requeueVideoRendition(db, eng, { media: m, reason: 'no job yet' }, now)),
    ).toBe('not-found');
    const r = await requeueVideoRendition(
      db,
      eng,
      { media: `babies/${babyId}/media/${m}`, reason: 'first rendition' },
      now,
    );
    expect(r).toEqual({ jobId: m, attempt: 1 });
    expect((await db.doc(`videoRenditionJobs/${m}`).get()).get('state')).toBe('queued');
  });

  it('refuses the wrong role, a finished rendition, photos, deleted items and unknown ids', async () => {
    const withDisplay = id();
    const dir = await video(withDisplay, { rendition: { state: 'ready' } });
    await db.doc(dir).update({ 'paths.display': `${dir}/display.mp4` });
    await job(withDisplay, 1, done('ready', null, 1, 30_000));
    const photo = id();
    await video(photo, { type: 'photo', contentType: 'image/jpeg' });
    await job(photo, 1, done('skipped', 'unreadable'));
    const gone = id();
    await video(gone, { deleted: true, rendition: { state: 'failed', reason: 'stale' } });
    await job(gone, 1, done('lost', 'stale'));
    const uploading = id();
    await video(uploading, { status: 'uploading' });
    await job(uploading, 1, done('skipped', 'gone'));

    const ask = (media: string, staff: Staff = eng) =>
      reason(requeueVideoRendition(db, staff, { media, reason: 'ticket' }, now));
    expect(await ask(withDisplay, ops)).toBe('role');
    expect(await ask(withDisplay, { ...eng, roles: ['support'] })).toBe('role');
    expect(await ask(withDisplay)).toBe('has-rendition');
    expect(await ask(photo)).toBe('not-video');
    expect(await ask(gone)).toBe('not-video');
    expect(await ask(uploading)).toBe('not-video');
    expect(await ask(`babies/${babyId}/media/${id()}`)).toBe('not-found');
    expect(await ask('abc')).toBe('malformed');
    expect(await reason(requeueVideoRendition(db, eng, { media: withDisplay }, now))).toBe(
      'malformed',
    );
    expect(await audit('system.videoRequeue')).toHaveLength(0);
  });
});

describe('backfillVideoRenditions (prod rollout, P-170)', () => {
  it('queues the ready videos without a rendition, oldest first, `limit` per call, until none is left', async () => {
    const old = id();
    await video(old, { createdAt: hoursAgo(300) });
    const mid = id();
    await video(mid, { createdAt: hoursAgo(200) });
    const young = id();
    await video(young, { createdAt: hoursAgo(100) });
    // Not candidates: has its rendition, already tried, deleted, a photo, still uploading.
    const hasDisplay = id();
    const dir = await video(hasDisplay);
    await db
      .doc(dir)
      .update({ 'paths.display': `${dir}/display.mp4`, rendition: { state: 'ready' } });
    await video(id(), {
      rendition: { state: 'failed', reason: 'too-long', updatedAt: hoursAgo(1) },
    });
    await video(id(), { deleted: true });
    await video(id(), { type: 'photo' });
    await video(id(), { status: 'uploading' });

    const first = await backfillVideoRenditions(
      db,
      eng,
      { limit: 2, reason: 'Prod rollout, batch 1' },
      now,
    );
    expect(first).toEqual({ queued: 2, skipped: 0, remaining: 1 });
    for (const m of [old, mid]) {
      expect((await db.doc(`videoRenditionJobs/${m}`).get()).data()).toMatchObject({
        babyId,
        mediaId: m,
        state: 'queued',
        attempt: 1,
      });
      const rendition = (await db.doc(`babies/${babyId}/media/${m}`).get()).get('rendition');
      expect(rendition.state).toBe('queued');
      expect(rendition.updatedAt.toMillis()).toBe(now.getTime());
    }
    expect((await db.doc(`videoRenditionJobs/${young}`).get()).exists).toBe(false);

    const second = await backfillVideoRenditions(db, eng, { limit: 2, reason: 'batch 2' }, now);
    expect(second).toEqual({ queued: 1, skipped: 0, remaining: 0 });
    expect((await db.doc(`videoRenditionJobs/${young}`).get()).exists).toBe(true);
    // The default is 50 per call; nothing is left.
    expect(await backfillVideoRenditions(db, eng, { reason: 'batch 3' }, now)).toEqual({
      queued: 0,
      skipped: 0,
      remaining: 0,
    });
    expect(
      await db
        .collection('videoRenditionJobs')
        .count()
        .get()
        .then((c) => c.data().count),
    ).toBe(3);

    // One entry per run (the query has no order: same instant, random ids).
    const log = await audit('system.videoBackfill');
    expect(log).toHaveLength(3);
    expect(log.map((l) => l.detail)).toEqual(
      expect.arrayContaining([
        { limit: 2, queued: 2, skipped: 0, remaining: 1 },
        { limit: 2, queued: 1, skipped: 0, remaining: 0 },
        { limit: 50, queued: 0, skipped: 0, remaining: 0 },
      ]),
    );
    expect(log.find((l) => l.reason === 'Prod rollout, batch 1')).toMatchObject({
      category: 'data',
      target: 'videos',
      actorUid: 's_minh',
    });
    expect(JSON.stringify(log)).not.toContain('Teddy');
  });

  it('needs the system edit level and a reason; a job that already exists is passed over', async () => {
    const m = id();
    await video(m);
    expect(await reason(backfillVideoRenditions(db, ops, { reason: 'rollout' }, now))).toBe('role');
    expect(await reason(backfillVideoRenditions(db, null, { reason: 'rollout' }, now))).toBe(
      'not-staff',
    );
    expect(await reason(backfillVideoRenditions(db, eng, {}, now))).toBe('malformed');
    expect(
      await reason(backfillVideoRenditions(db, eng, { limit: 0, reason: 'rollout' }, now)),
    ).toBe('malformed');
    await job(m, 1, done('ready', null, 1, 20_000));
    expect(await backfillVideoRenditions(db, eng, { reason: 'rollout' }, now)).toEqual({
      queued: 0,
      skipped: 1,
      remaining: 0,
    });
    expect((await db.doc(`babies/${babyId}/media/${m}`).get()).get('rendition')).toBeUndefined();
  });
});
