import {
  keepsakeJobLimits,
  type KeepsakeJobErrorCode,
  type KeepsakeJobInput,
  type KeepsakeJobStep,
} from '@child-life/contracts';
import type { Firestore } from 'firebase-admin/firestore';
import { createHash } from 'node:crypto';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import type { MemoryStoryProps } from './compositions/MemoryStory';

/**
 * One render (D-068; plan §5): claim the job, fetch its photos and music to a private folder,
 * render the MP4 and a poster frame, upload them next to where the video will live in Kỷ niệm,
 * and mark the job completed — Functions then file it. Logs carry ids and codes only, never the
 * baby's name, texts or paths.
 *
 * Cloud Tasks may deliver a task twice and retries a failure: a completed or failed job is left
 * alone, a crash mid-render is picked up again (attempts counted), and the outputs always go to
 * the same paths, so nothing is duplicated.
 *
 * Fencing (Q2, plan §5.3): every claim bumps the job's `lease`, which is never reset. The worker
 * finishes (completed, failed or back in the queue) only while it still holds that lease and the
 * job is still rendering; a stale worker (the sweeper failed it, or a retry handed it to another
 * worker) is refused, so its quota unit is never committed or released twice.
 */

export interface RenderStore {
  download(path: string, dest: string): Promise<void>;
  /** Returns the bytes written. */
  upload(src: string, path: string, contentType: string): Promise<number>;
  delete(path: string): Promise<void>;
}

export interface Renderer {
  render(opts: {
    composition: string;
    props: MemoryStoryProps;
    video: string;
    poster: string;
    onProgress: (fraction: number) => void;
  }): Promise<{ durationMs: number; width: number; height: number }>;
}

export interface JobDeps {
  db: Firestore;
  store: RenderStore;
  renderer: Renderer;
  /** Serves a local folder to the browser (`serveFolder`). */
  serve: (dir: string) => Promise<{ url: (file: string) => string; close: () => Promise<void> }>;
  now: () => Date;
}

/**
 * `done`/`skipped`/`failed`/`stale`: answer 200 (no retry). `retry`: answer 500 (Cloud Tasks
 * retries). `stale`: this worker lost its lease; whatever it rendered is not recorded.
 */
export type JobOutcome = 'done' | 'skipped' | 'failed' | 'retry' | 'stale';

class StepError extends Error {
  constructor(readonly code: KeepsakeJobErrorCode) {
    super(code);
  }
}

/**
 * What went wrong in Remotion or Chrome, without anything from the job: URLs, paths and quoted
 * text (where a title or a name could appear) are cut, and it is kept short.
 */
export function errorCause(e: unknown): string {
  if (!(e instanceof Error)) return 'unknown';
  return `${e.name}: ${e.message}`
    .replace(/https?:\/\/\S+/g, '<url>')
    .replace(/(["'“”‘’`]).*?\1/g, '<text>')
    .replace(/(?:\/[\w.@-]+){2,}/g, '<path>')
    .replace(/\s+/g, ' ')
    .slice(0, 300);
}

const hex32 = (s: string) => createHash('sha256').update(s).digest('hex').slice(0, 32);
/** The same ids Functions files the video under (`outputIdsOf`). */
export const outputMediaIdOf = (jobId: string) => `med_${hex32(`${jobId}|media`)}`;

export async function runJob(deps: JobDeps, babyId: string, jobId: string): Promise<JobOutcome> {
  const { db } = deps;
  const ref = db.doc(`babies/${babyId}/keepsakeJobs/${jobId}`);
  const claimed = await db.runTransaction(async (tx) => {
    const job = await tx.get(ref);
    if (!job.exists) return null;
    const status = job.get('status') as string;
    if (status !== 'queued' && status !== 'rendering') return null;
    const attempts = ((job.get('attempts') as number | undefined) ?? 0) + 1;
    if (attempts > keepsakeJobLimits.attempts) {
      tx.update(ref, {
        status: 'failed',
        error: 'render-failed',
        updatedAt: deps.now(),
        finishedAt: deps.now(),
      });
      return 'exhausted' as const;
    }
    const lease = ((job.get('lease') as number | undefined) ?? 0) + 1;
    tx.update(ref, {
      status: 'rendering',
      step: 'arrange',
      progress: 2,
      attempts,
      lease,
      startedAt: deps.now(),
      updatedAt: deps.now(),
    });
    return { input: job.get('input') as KeepsakeJobInput, attempts, lease };
  });
  if (claimed === null) return 'skipped';
  if (claimed === 'exhausted') return 'failed';
  const { input, attempts, lease } = claimed;
  /** Writes [update] only while this worker still holds the job (fencing). */
  const finish = (update: Record<string, unknown>) =>
    db.runTransaction(async (tx) => {
      const job = await tx.get(ref);
      if (!job.exists || job.get('status') !== 'rendering' || job.get('lease') !== lease) {
        return false;
      }
      tx.update(ref, update);
      return true;
    });
  const started = Date.now();
  console.info('render started', { jobId, template: input.template.id, attempts });

  let lastProgress = 0;
  const progress = async (step: KeepsakeJobStep, value: number) => {
    if (value - lastProgress < 5 && value < 100) return;
    lastProgress = value;
    await ref.update({ step, progress: Math.round(value), updatedAt: deps.now() });
  };

  const dir = await mkdtemp(join(tmpdir(), 'ks-'));
  const served = await deps.serve(dir);
  try {
    // 1. "Sắp xếp ảnh theo mẫu": the photos (display renditions) and the music, in order.
    const photos: string[] = [];
    for (const [i, path] of input.photos.entries()) {
      const file = `p${String(i).padStart(2, '0')}.jpg`;
      try {
        await deps.store.download(path, join(dir, file));
      } catch {
        throw new StepError('photo-missing');
      }
      photos.push(served.url(file));
      await progress('arrange', 2 + (8 * (i + 1)) / input.photos.length);
    }
    let music: string | null = null;
    if (input.music) {
      const file = `music.${input.music.split('.').pop()}`;
      try {
        await deps.store.download(input.music, join(dir, file));
        music = served.url(file);
      } catch {
        // A missing track never stops the video.
      }
    }

    // 2. "Thêm chữ, lời nhắn và nhạc" + 3. "Xuất video 9:16".
    await progress('compose', 12);
    const props: MemoryStoryProps = {
      photos,
      title: input.texts.title,
      message: input.texts.message,
      name: input.name,
      dateLine: input.dateLine,
      mark: input.mark,
      palette: input.template.palette,
      music,
      // Frozen with the template when the video was asked for (D-068 #10); older jobs: none.
      brand: input.template.brand ?? null,
      // Chapter 01 (E-8): the extra texts, the photos' ages, the language and the birth stats.
      headline: input.texts.headline,
      closing: input.texts.closing,
      lines: input.texts.lines,
      letter: input.texts.letter,
      photoInfo: input.photoInfo,
      locale: input.locale,
      birthStats: input.birthStats ?? null,
      durationSec: input.template.durationSec ?? 30,
    };
    const video = join(dir, 'out.mp4');
    const poster = join(dir, 'frame.jpg');
    let rendered: Awaited<ReturnType<Renderer['render']>>;
    try {
      rendered = await deps.renderer.render({
        composition: input.template.composition ?? 'LittleMoments',
        props,
        video,
        poster,
        onProgress: (f) => void progress('export', 15 + f * 80).catch(() => undefined),
      });
    } catch (e) {
      console.error('render failed', { jobId, error: errorCause(e) });
      throw new StepError('render-failed');
    }

    const mediaDir = `babies/${babyId}/media/${outputMediaIdOf(jobId)}`;
    let bytes: number;
    try {
      bytes = await deps.store.upload(video, `${mediaDir}/original.mp4`, 'video/mp4');
      await deps.store.upload(poster, `${mediaDir}/frame.jpg`, 'image/jpeg');
    } catch {
      throw new StepError('upload-failed');
    }
    const won = await finish({
      status: 'completed',
      step: 'export',
      progress: 100,
      output: { ...rendered, bytes, lease },
      error: null,
      updatedAt: deps.now(),
      finishedAt: deps.now(),
    });
    if (!won) {
      console.warn('render stale', { jobId, lease });
      return 'stale';
    }
    console.info('render done', { jobId, ms: Date.now() - started, bytes });
    return 'done';
  } catch (e) {
    const code = e instanceof StepError ? e.code : 'render-failed';
    // A photo that is gone will not come back: fail now. Anything else is retried.
    const final = code === 'photo-missing' || attempts >= keepsakeJobLimits.attempts;
    const won = await finish({
      status: final ? 'failed' : 'queued',
      error: final ? code : null,
      step: null,
      updatedAt: deps.now(),
      ...(final ? { finishedAt: deps.now() } : {}),
    });
    if (!won) {
      console.warn('render stale', { jobId, lease });
      return 'stale';
    }
    console.warn('render stopped', { jobId, code, final });
    return final ? 'failed' : 'retry';
  } finally {
    await served.close();
    await rm(dir, { recursive: true, force: true });
  }
}
