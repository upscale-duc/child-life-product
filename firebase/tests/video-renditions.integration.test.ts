import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import sharp from 'sharp';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { sharpImages } from '../functions/src/images.js';
import { type MediaStore } from '../functions/src/memories.js';
import {
  renditionJobDoc,
  renditionJobId,
  renditionLimits,
  requeueStaleVideoRenditions,
  runVideoRendition,
  type OpenedVideo,
  type RenditionSpec,
  type VideoInfo,
  type VideoOps,
} from '../functions/src/video-renditions.js';

// Streaming renditions (P-170) against the Firestore emulator: the job after a video is ready,
// the item's `paths.display`, posters made when the phone sent none, bytes kept off the quota
// (Q-079), and the hourly re-queue of a stalled job. ffmpeg is a fake here (its own tests run
// the binary); Storage is in memory.
const projectId = 'demo-child-life';
const now = new Date('2026-10-19T07:00:00Z');
let app: App;
let db: Firestore;
const babyId = 'b_ca5e0000000000000011';
const familyId = 'f_ca5e0000000000000011';

class FakeStore implements MediaStore {
  files = new Map<string, { bytes: Uint8Array; contentType: string }>();
  async head(path: string, n: number) {
    return this.files.get(path)?.bytes.slice(0, n) ?? null;
  }
  async read(path: string) {
    return this.files.get(path)?.bytes ?? null;
  }
  async save(path: string, bytes: Uint8Array, contentType: string) {
    this.files.set(path, { bytes, contentType });
  }
  async move(from: string, to: string, contentType: string) {
    const f = this.files.get(from);
    if (!f) throw new Error('missing');
    this.files.delete(from);
    this.files.set(to, { bytes: f.bytes, contentType });
  }
  async size(path: string) {
    return this.files.get(path)?.bytes.length ?? null;
  }
  async delete(path: string) {
    this.files.delete(path);
  }
}

const iphone4k: VideoInfo = {
  width: 2160,
  height: 3840,
  durationMs: 24_000,
  fps: 59.94,
  hdr: true,
  videoCodec: 'hevc',
  hasAudio: true,
};

/** A transcoder that writes a stand-in rendition (and poster) into the fake store. */
class FakeVideo implements VideoOps {
  constructor(
    private readonly store: FakeStore,
    public info: VideoInfo | null = iphone4k,
    public failWith: string | null = null,
  ) {}
  opened: string[] = [];
  closed = 0;
  specs: RenditionSpec[] = [];
  async open(objectPath: string): Promise<OpenedVideo | null> {
    this.opened.push(objectPath);
    if (!this.info) return null;
    const info = this.info;
    return {
      info,
      transcode: async (outPath, spec, { poster }) => {
        this.specs.push(spec);
        if (this.failWith) throw new Error(this.failWith);
        const bytes = new Uint8Array(5_000_000);
        await this.store.save(outPath, bytes, 'video/mp4');
        const frame = poster
          ? new Uint8Array(
              await sharp({
                create: { width: 1080, height: 1920, channels: 3, background: '#9ad' },
              })
                .jpeg()
                .toBuffer(),
            )
          : null;
        return { bytes: bytes.length, poster: frame };
      },
      close: async () => {
        this.closed++;
      },
    };
  }
}

let seq = 0;
const id = (prefix: string) => `${prefix}_${(++seq).toString(16).padStart(32, '0')}`;

async function readyVideo(mediaId: string, over: Record<string, unknown> = {}) {
  const dir = `babies/${babyId}/media/${mediaId}`;
  await db.doc(dir).set({
    id: mediaId,
    babyId,
    familyId,
    memoryId: id('mem'),
    batchId: id('bat'),
    type: 'video',
    status: 'ready',
    deleted: false,
    contentType: 'video/quicktime',
    sizeBytes: 420_000_000,
    storedBytes: 420_300_000,
    reservedBytes: 0,
    paths: {
      original: `${dir}/original.mov`,
      display: null,
      thumb: `${dir}/thumb.jpg`,
      poster: `${dir}/poster.jpg`,
    },
    audience: 'family',
    effectiveAudience: 'family',
    createdBy: 'mom',
    createdAt: now,
    updatedAt: now,
    readyAt: now,
    rendition: { state: 'queued', updatedAt: now },
    ...over,
  });
  return dir;
}

const job = async (mediaId: string, attempt = 1) => {
  const jobId = renditionJobId(mediaId, attempt);
  await db.doc(`videoRenditionJobs/${jobId}`).set(renditionJobDoc(babyId, mediaId, now, attempt));
  return jobId;
};

beforeAll(() => {
  app = initializeApp({ projectId }, `video-renditions-${randomUUID()}`);
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
    usedBytes: 420_300_000,
    reservedBytes: 0,
  });
  await db.doc(`babies/${babyId}`).set({ id: babyId, familyId, state: 'active' });
});

describe('runVideoRendition', () => {
  it('turns a ready video into display.mp4 the app plays; the quota does not move', async () => {
    const m = id('med');
    const dir = await readyVideo(m);
    const store = new FakeStore();
    const video = new FakeVideo(store);
    const jobId = await job(m);
    expect(await runVideoRendition(db, store, sharpImages, video, jobId, now)).toBe('ready');

    const item = (await db.doc(dir).get()).data()!;
    expect(item.paths.display).toBe(`${dir}/display.mp4`);
    expect(store.files.get(`${dir}/display.mp4`)?.contentType).toBe('video/mp4');
    // 4K60 HDR portrait → 1080×1920, 30 fps, tone-mapped.
    expect(video.specs.single()).toMatchObject({ width: 1080, height: 1920, fps: 30, hdr: true });
    expect(item.rendition).toMatchObject({
      state: 'ready',
      width: 1080,
      height: 1920,
      bytes: 5_000_000,
    });
    expect(item.renditionBytes).toBe(5_000_000);
    expect(item.storedBytes).toBe(420_300_000);
    expect((await db.doc(`families/${familyId}`).get()).get('usedBytes')).toBe(420_300_000);
    // The phone had sent a poster: none made here.
    expect(store.files.has(`${dir}/poster.jpg`)).toBe(false);
    const j = (await db.doc(`videoRenditionJobs/${jobId}`).get()).data()!;
    expect(j.state).toBe('ready');
    expect(j.activeSince).toBeNull();
    expect(video.closed).toBe(1);
    expect(video.opened).toEqual([`${dir}/original.mov`]);

    // Running the same job again changes nothing.
    expect(await runVideoRendition(db, store, sharpImages, video, jobId, now)).toBe('ignored');
    expect(video.opened).toHaveLength(1);
  });

  it('makes the poster and thumbnail from the rendition when the phone sent none', async () => {
    const m = id('med');
    const path = `babies/${babyId}/media/${m}`;
    const dir = await readyVideo(m, {
      paths: { original: `${path}/original.mp4`, display: null, thumb: null, poster: null },
    });
    const store = new FakeStore();
    const jobId = await job(m);
    expect(await runVideoRendition(db, store, sharpImages, new FakeVideo(store), jobId, now)).toBe(
      'ready',
    );
    const item = (await db.doc(dir).get()).data()!;
    expect(item.paths.poster).toBe(`${dir}/poster.jpg`);
    expect(item.paths.thumb).toBe(`${dir}/thumb.jpg`);
    const poster = store.files.get(`${dir}/poster.jpg`)!;
    expect((await sharp(poster.bytes).metadata()).height).toBe(1280);
    const posterBytes = poster.bytes.length + store.files.get(`${dir}/thumb.jpg`)!.bytes.length;
    // Posters are stored media, like a phone-made one: counted; the rendition is not.
    expect(item.storedBytes).toBe(420_300_000 + posterBytes);
    expect((await db.doc(`families/${familyId}`).get()).get('usedBytes')).toBe(
      420_300_000 + posterBytes,
    );
  });

  it('leaves a long original as it is (plays from the original)', async () => {
    const m = id('med');
    const dir = await readyVideo(m);
    const store = new FakeStore();
    const video = new FakeVideo(store, {
      ...iphone4k,
      durationMs: renditionLimits.maxDurationMs + 1,
    });
    const jobId = await job(m);
    expect(await runVideoRendition(db, store, sharpImages, video, jobId, now)).toBe('skipped');
    const item = (await db.doc(dir).get()).data()!;
    expect(item.paths.display).toBeNull();
    expect(item.rendition).toMatchObject({ state: 'skipped', reason: 'too-long' });
    expect((await db.doc(`videoRenditionJobs/${jobId}`).get()).get('error')).toBe('too-long');
    expect(video.closed).toBe(1);
  });

  it('records a failed transcode on the job and the item, and never throws', async () => {
    const m = id('med');
    const dir = await readyVideo(m);
    const store = new FakeStore();
    const jobId = await job(m);
    expect(
      await runVideoRendition(
        db,
        store,
        sharpImages,
        new FakeVideo(store, iphone4k, 'exit 1: Invalid data'),
        jobId,
        now,
      ),
    ).toBe('failed');
    expect((await db.doc(dir).get()).get('rendition')).toMatchObject({
      state: 'failed',
      reason: 'exit 1: Invalid data',
    });
    const j = (await db.doc(`videoRenditionJobs/${jobId}`).get()).data()!;
    expect(j.state).toBe('failed');
    expect(j.activeSince).toBeNull();
    expect(store.files.size).toBe(0);
  });

  it('an item deleted meanwhile keeps nothing of the rendition', async () => {
    const m = id('med');
    const dir = await readyVideo(m);
    const store = new FakeStore();
    const jobId = await job(m);
    const video = new FakeVideo(store);
    // The deletion lands while ffmpeg runs.
    const original = video.open.bind(video);
    video.open = async (p) => {
      const o = await original(p);
      await db.doc(dir).update({ deleted: true });
      return o;
    };
    expect(await runVideoRendition(db, store, sharpImages, video, jobId, now)).toBe('gone');
    expect(store.files.size).toBe(0);
    expect((await db.doc(dir).get()).get('paths.display')).toBeNull();
  });

  it('is not for photos, items still uploading, or ones already done', async () => {
    const photo = id('med');
    await readyVideo(photo, { type: 'photo' });
    const uploading = id('med');
    await readyVideo(uploading, { status: 'uploading' });
    const done = id('med');
    const dir = await readyVideo(done);
    await db.doc(dir).update({ 'paths.display': `${dir}/display.mp4` });
    const store = new FakeStore();
    const video = new FakeVideo(store);
    expect(await runVideoRendition(db, store, sharpImages, video, await job(photo), now)).toBe(
      'gone',
    );
    expect(await runVideoRendition(db, store, sharpImages, video, await job(uploading), now)).toBe(
      'gone',
    );
    expect(await runVideoRendition(db, store, sharpImages, video, await job(done), now)).toBe(
      'already',
    );
    expect(video.opened).toEqual([]);
  });
});

describe('requeueStaleVideoRenditions', () => {
  it('queues a stalled job again, up to the limit, then marks the item failed', async () => {
    const m = id('med');
    const dir = await readyVideo(m);
    const stale = new Date(now.getTime() - renditionLimits.staleAfterMs - 1000);
    await db.doc(`videoRenditionJobs/${m}`).set({
      ...renditionJobDoc(babyId, m, stale),
      state: 'running',
    });
    const fresh = id('med');
    await readyVideo(fresh);
    await job(fresh);

    expect(await requeueStaleVideoRenditions(db, now)).toBe(1);
    expect((await db.doc(`videoRenditionJobs/${m}`).get()).data()).toMatchObject({
      state: 'lost',
      activeSince: null,
    });
    const next = (await db.doc(`videoRenditionJobs/${renditionJobId(m, 2)}`).get()).data()!;
    expect(next).toMatchObject({ state: 'queued', attempt: 2 });
    expect((await db.doc(`videoRenditionJobs/${fresh}`).get()).get('state')).toBe('queued');
    // The second attempt runs like the first.
    const store = new FakeStore();
    expect(
      await runVideoRendition(
        db,
        store,
        sharpImages,
        new FakeVideo(store),
        renditionJobId(m, 2),
        now,
      ),
    ).toBe('ready');

    // A job on its last allowed attempt that stalls gives up on the item.
    const tired = id('med');
    const tiredDir = await readyVideo(tired);
    await db.doc(`videoRenditionJobs/${renditionJobId(tired, renditionLimits.maxAttempts)}`).set({
      ...renditionJobDoc(babyId, tired, stale, renditionLimits.maxAttempts),
      state: 'running',
    });
    expect(await requeueStaleVideoRenditions(db, now)).toBe(1);
    expect((await db.doc(tiredDir).get()).get('rendition')).toMatchObject({
      state: 'failed',
      reason: 'stale',
    });
    expect(
      (
        await db
          .doc(`videoRenditionJobs/${renditionJobId(tired, renditionLimits.maxAttempts + 1)}`)
          .get()
      ).exists,
    ).toBe(false);
    void dir;
  });
});

declare global {
  interface Array<T> {
    single(): T;
  }
}
Array.prototype.single = function single<T>(this: T[]): T {
  if (this.length !== 1) throw new Error(`expected one, got ${this.length}`);
  return this[0]!;
};
