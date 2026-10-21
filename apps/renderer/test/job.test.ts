import { keepsakeSeedV1, premium48Phase2, type KeepsakeJobInput } from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { randomUUID } from 'node:crypto';
import { writeFile } from 'node:fs/promises';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  errorCause,
  outputMediaIdOf,
  runJob,
  type JobDeps,
  type Renderer,
  type RenderStore,
} from '../src/job';

// The renderer's job handling (D-068) against the Firestore emulator (run under
// `firebase emulators:exec`), with a fake store and renderer: claim, progress, outputs,
// idempotency, retries and the final failure.
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const babyId = 'b_render0000000000001';
const jobId = `ksj_${'a'.repeat(32)}`;
const ref = () => db.doc(`babies/${babyId}/keepsakeJobs/${jobId}`);
const template = keepsakeSeedV1.templates.find((t) => t.id === 'video_first_month')!;
const input: KeepsakeJobInput = {
  template,
  photos: ['p/1.jpg', 'p/2.jpg'],
  texts: { title: 'T', message: 'M' },
  name: 'Teddy',
  dateLine: '17.09 – 17.10.2026',
  mark: '1',
  music: 'content/keepsakes/lullaby_1a2b3c4d.mp3',
};

class Store implements RenderStore {
  uploaded: string[] = [];
  downloaded: string[] = [];
  missing = new Set<string>();
  async download(path: string, dest: string) {
    this.downloaded.push(path);
    if (this.missing.has(path)) throw new Error('404');
    await writeFile(dest, 'x');
  }
  async upload(_src: string, path: string) {
    this.uploaded.push(path);
    return 1234;
  }
  async delete() {}
}
const okRenderer: Renderer = {
  async render({ onProgress, props }) {
    expect(props.photos).toHaveLength(2);
    expect(props.photos[0]).toMatch(/^http:\/\/127\.0\.0\.1:\d+\/p00\.jpg$/);
    onProgress(0.5);
    onProgress(1);
    return { durationMs: 45_000, width: 1080, height: 1920 };
  },
};
const deps = (over: Partial<JobDeps> = {}): JobDeps => ({
  db,
  store: new Store(),
  renderer: okRenderer,
  serve: async () => ({ url: (f) => `http://127.0.0.1:1234/${f}`, close: async () => {} }),
  now: () => new Date('2026-10-14T03:00:00Z'),
  ...over,
});

beforeAll(() => {
  app = initializeApp({ projectId }, `renderer-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => deleteApp(app));
beforeEach(async () => {
  await db.doc(`babies/${babyId}`).set({ state: 'active' });
  await ref().set({ status: 'queued', attempts: 0, input, uid: 'mom' });
});

describe('errorCause', () => {
  it('keeps the cause, never a URL, a path or quoted text', () => {
    const e = new Error(
      'Could not load http://localhost:4000/p00.jpg for "Tháng đầu tiên của Teddy" at /tmp/ks-1/out.mp4',
    );
    expect(errorCause(e)).toBe('Error: Could not load <url> for <text> at <path>');
  });
});

describe('runJob', () => {
  it('renders, uploads next to the future video, completes; a second delivery is skipped', async () => {
    const store = new Store();
    expect(await runJob(deps({ store }), babyId, jobId)).toBe('done');
    const media = `babies/${babyId}/media/${outputMediaIdOf(jobId)}`;
    expect(store.uploaded).toEqual([`${media}/original-1.mp4`, `${media}/frame-1.jpg`]);
    const job = await ref().get();
    expect(job.get('status')).toBe('completed');
    expect(job.get('progress')).toBe(100);
    expect(job.get('output')).toEqual({
      durationMs: 45_000,
      width: 1080,
      height: 1920,
      bytes: 1234,
      lease: 1,
      videoPath: `${media}/original-1.mp4`,
      framePath: `${media}/frame-1.jpg`,
    });
    expect(await runJob(deps({ store }), babyId, jobId)).toBe('skipped');
  });

  it('a missing photo fails for good; a render error is retried, then fails', async () => {
    const store = new Store();
    store.missing.add('p/2.jpg');
    expect(await runJob(deps({ store }), babyId, jobId)).toBe('failed');
    expect((await ref().get()).get('error')).toBe('photo-missing');

    await ref().set({ status: 'queued', attempts: 0, input, uid: 'mom' });
    const broken: Renderer = { render: async () => Promise.reject(new Error('chrome')) };
    expect(await runJob(deps({ renderer: broken }), babyId, jobId)).toBe('retry');
    expect((await ref().get()).get('status')).toBe('queued');
    expect(await runJob(deps({ renderer: broken }), babyId, jobId)).toBe('retry');
    expect(await runJob(deps({ renderer: broken }), babyId, jobId)).toBe('failed');
    expect((await ref().get()).get('error')).toBe('render-failed');
  });

  it('a missing track never stops the video', async () => {
    const store = new Store();
    store.missing.add('content/keepsakes/lullaby_1a2b3c4d.mp3');
    const seen: (string | null)[] = [];
    const renderer: Renderer = {
      async render(o) {
        seen.push(o.props.music);
        return { durationMs: 1, width: 1080, height: 1920 };
      },
    };
    expect(await runJob(deps({ store, renderer }), babyId, jobId)).toBe('done');
    expect(seen).toEqual([null]);
  });

  it('the logo comes from the template frozen in the job; older jobs have none (D-068 #10)', async () => {
    const seen: unknown[] = [];
    const renderer: Renderer = {
      async render(o) {
        seen.push(o.props.brand);
        return { durationMs: 1, width: 1080, height: 1920 };
      },
    };
    expect(await runJob(deps({ renderer }), babyId, jobId)).toBe('done');
    expect(seen).toEqual([{ corner: true, endCard: true, opacity: 0.75 }]);
    // A job asked for before templates had a logo renders as it always did.
    const old: Record<string, unknown> = { ...template };
    delete old.brand;
    await ref().update({ status: 'queued', input: { ...input, template: old }, attempts: 0 });
    expect(await runJob(deps({ renderer }), babyId, jobId)).toBe('done');
    expect(seen[1]).toBe(null);
  });
});

describe('fencing (Q2)', () => {
  it('downloads phase-2 artwork from the frozen immutable asset names', async () => {
    const template = premium48Phase2({
      'p48-home-door-left': 'art-door-left_12345678.webp',
      'p48-home-house': 'art-house_12345678.webp',
    })[2]!;
    const store = new Store();
    await ref().update({ input: { ...input, template } });
    const renderer: Renderer = {
      async render(o) {
        expect(Object.keys(o.props.artAssets ?? {})).toEqual(['homeDoorLeft', 'homeHouse']);
        expect((o.props.artAssets as Record<string, string>).homeHouse).toMatch(
          /art-homeHouse\.webp$/,
        );
        return { durationMs: 35000, width: 1080, height: 1920 };
      },
    };
    expect(await runJob(deps({ store, renderer }), babyId, jobId)).toBe('done');
    expect(store.downloaded).toContain('content/keepsakes/art-door-left_12345678.webp');
    expect(store.downloaded).toContain('content/keepsakes/art-house_12345678.webp');
  });
  it('each claim takes a new lease; the completion carries it', async () => {
    await ref().set({ status: 'queued', attempts: 0, input, uid: 'mom', lease: 4 });
    expect(await runJob(deps(), babyId, jobId)).toBe('done');
    const job = await ref().get();
    expect(job.get('lease')).toBe(5);
    expect(job.get('output.lease')).toBe(5);
  });

  it('a worker whose job was swept and handed to another worker cannot complete it', async () => {
    const renderer: Renderer = {
      async render() {
        // Meanwhile: the sweeper failed the job, "Thử lại" queued it and another worker claimed it.
        await ref().update({ status: 'rendering', lease: 2, attempts: 1 });
        return { durationMs: 1, width: 1080, height: 1920 };
      },
    };
    expect(await runJob(deps({ renderer }), babyId, jobId)).toBe('stale');
    const job = await ref().get();
    expect(job.get('status')).toBe('rendering');
    expect(job.get('lease')).toBe(2);
    expect(job.get('output')).toBeUndefined();
  });

  it('a worker whose job the sweeper failed cannot complete it nor put it back in the queue', async () => {
    const swept = async () => {
      await ref().update({ status: 'failed', error: 'timeout' });
    };
    const ok: Renderer = {
      async render() {
        await swept();
        return { durationMs: 1, width: 1080, height: 1920 };
      },
    };
    expect(await runJob(deps({ renderer: ok }), babyId, jobId)).toBe('stale');
    expect((await ref().get()).get('status')).toBe('failed');
    expect((await ref().get()).get('output')).toBeUndefined();

    await ref().set({ status: 'queued', attempts: 0, input, uid: 'mom' });
    const broken: Renderer = {
      async render() {
        await swept();
        throw new Error('chrome');
      },
    };
    expect(await runJob(deps({ renderer: broken }), babyId, jobId)).toBe('stale');
    const job = await ref().get();
    expect(job.get('status')).toBe('failed');
    expect(job.get('error')).toBe('timeout');
  });
});

describe('product audit storage/deletion fences', () => {
  it('does not claim a missing or deleting baby, even with a surviving queued task', async () => {
    await db.doc(`babies/${babyId}`).update({ state: 'deleting' });
    expect(await runJob(deps(), babyId, jobId)).toBe('skipped');
    await db.doc(`babies/${babyId}`).delete();
    expect(await runJob(deps(), babyId, jobId)).toBe('skipped');
    expect((await ref().get()).get('attempts')).toBe(0);
  });
  it('a duplicate delivery retries without stealing a live lease', async () => {
    await ref().update({ status: 'rendering', lease: 1, startedAt: deps().now() });
    expect(await runJob(deps(), babyId, jobId)).toBe('retry');
    expect((await ref().get()).get('lease')).toBe(1);
  });
  it('a stale upload cannot overwrite the winning lease bytes or progress', async () => {
    const winner = `babies/${babyId}/media/${outputMediaIdOf(jobId)}/original-2.mp4`;
    const files = new Map([[winner, 'winner']]);
    const store = new Store();
    store.upload = async (_src, path) => {
      await ref().update({ status: 'completed', lease: 2, progress: 100, output: { lease: 2 } });
      files.set(path, 'stale');
      return 123;
    };
    store.delete = async (path?: string) => {
      if (path) files.delete(path);
    };
    expect(await runJob(deps({ store }), babyId, jobId)).toBe('stale');
    expect(files.get(winner)).toBe('winner');
    expect([...files.keys()]).toEqual([winner]);
    expect((await ref().get()).get('output.lease')).toBe(2);
    expect((await ref().get()).get('progress')).toBe(100);
  });
});
