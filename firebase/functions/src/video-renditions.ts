import { FieldValue, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { mediaPaths, type ImageOps, type MediaStore } from './memories.js';

/**
 * Streaming renditions for videos (SP-3, P-170). The original stays as recorded (D-036, ADR-004);
 * after it is `ready`, a job turns it into `display.mp4` — H.264/AAC, the short side at most
 * 1080 px, at most 30 fps, SDR, index first ("fast start") — which the app plays and which any
 * phone decodes over a normal connection. Phone originals (4K HEVC, 30–80 Mbit/s, HDR) could
 * not: playback stalled for anything but a short clip. A missing poster is taken from the
 * rendition. Rendition bytes do not count toward the family quota (Q-079); the original does.
 *
 * Jobs live in `videoRenditionJobs/{jobId}` (created by processUpload, run by
 * buildVideoRendition); the hourly sweep re-queues one that stalled. Nothing about the child
 * is logged: codes and sizes only.
 */

export const renditionLimits = {
  /** Short side of the rendition, in pixels. */
  shortSide: 1080,
  maxFps: 30,
  /** Longer or larger originals keep playing from the original (no rendition). */
  maxDurationMs: 20 * 60_000,
  maxInputBytes: 3 * 1024 ** 3,
  /** A job without progress for this long is run again (at most this many times). */
  staleAfterMs: 30 * 60_000,
  maxAttempts: 3,
} as const;

export type RenditionState = 'queued' | 'running' | 'ready' | 'failed' | 'skipped' | 'lost';

/** What the probe says about the original, as displayed (rotation applied). */
export interface VideoInfo {
  width: number;
  height: number;
  durationMs: number;
  fps: number | null;
  /** PQ / HLG transfer or BT.2020 primaries: tone-mapped to SDR. */
  hdr: boolean;
  videoCodec: string | null;
  hasAudio: boolean;
}

export interface RenditionSpec {
  width: number;
  height: number;
  /** Output frame rate cap, or null to keep the source's. */
  fps: number | null;
  hdr: boolean;
  maxrateKbps: number;
  crf: number;
}

/** The transcoder's view of one original (ffmpeg in production, a fake in tests). */
export interface OpenedVideo {
  info: VideoInfo;
  /** Writes the rendition to [outPath] in the bucket; a poster frame (JPEG) when asked. */
  transcode(
    outPath: string,
    spec: RenditionSpec,
    opts: { deadlineMs: number; poster: boolean },
  ): Promise<{ bytes: number; poster: Uint8Array | null }>;
  close(): Promise<void>;
}

export interface VideoOps {
  /** Fetches and probes the original; null when it does not read as a video. */
  open(objectPath: string): Promise<OpenedVideo | null>;
}

const even = (n: number) => Math.max(2, Math.round(n / 2) * 2);

/** The rendition for a source: short side ≤ 1080, ≤ 30 fps, bitrate cap by size. */
export function renditionSpecFor(info: VideoInfo): RenditionSpec {
  const short = Math.min(info.width, info.height);
  const scale = short > renditionLimits.shortSide ? renditionLimits.shortSide / short : 1;
  const width = even(info.width * scale);
  const height = even(info.height * scale);
  const outShort = Math.min(width, height);
  const maxrateKbps = outShort >= 1080 ? 6000 : outShort >= 720 ? 3500 : 2000;
  return {
    width,
    height,
    fps: info.fps !== null && info.fps > renditionLimits.maxFps + 1 ? renditionLimits.maxFps : null,
    hdr: info.hdr,
    maxrateKbps,
    crf: 23,
  };
}

/** Why an original is left as it is. */
export function renditionSkipReason(
  info: VideoInfo,
  sizeBytes: number,
): 'too-long' | 'too-large' | 'no-picture' | null {
  if (info.width <= 0 || info.height <= 0) return 'no-picture';
  if (info.durationMs > renditionLimits.maxDurationMs) return 'too-long';
  if (sizeBytes > renditionLimits.maxInputBytes) return 'too-large';
  return null;
}

export const renditionJobId = (mediaId: string, attempt: number) =>
  attempt <= 1 ? mediaId : `${mediaId}~${attempt}`;

/** The job document processUpload writes once a video is ready (inside its transaction). */
export function renditionJobDoc(babyId: string, mediaId: string, now: Date, attempt = 1) {
  return {
    babyId,
    mediaId,
    state: 'queued' satisfies RenditionState,
    attempt,
    createdAt: now,
    updatedAt: now,
    /** Set while queued / running; cleared when done, so the sweep's range query skips it. */
    activeSince: now,
    startedAt: null,
    finishedAt: null,
    error: null,
  };
}

export type RenditionResult = 'ready' | 'skipped' | 'failed' | 'ignored' | 'gone' | 'already';

/**
 * Runs one job. Idempotent: a job not `queued` is ignored; an item that already has its
 * rendition, or is gone, is left alone. Failures are recorded on the job and the item and never
 * thrown (the trigger must not retry a transcode that will fail again the same way).
 */
export async function runVideoRendition(
  db: Firestore,
  store: MediaStore,
  images: ImageOps,
  video: VideoOps,
  jobId: string,
  now: Date,
  /** Wall-clock budget for the transcode itself. */
  budgetMs = 450_000,
): Promise<RenditionResult> {
  const jobRef = db.doc(`videoRenditionJobs/${jobId}`);
  const claimed = await db.runTransaction(async (tx) => {
    const job = await tx.get(jobRef);
    if (!job.exists || job.get('state') !== 'queued') return null;
    tx.update(jobRef, { state: 'running', startedAt: now, updatedAt: now, activeSince: now });
    return { babyId: job.get('babyId') as string, mediaId: job.get('mediaId') as string };
  });
  if (!claimed) return 'ignored';
  const { babyId, mediaId } = claimed;
  const ref = db.doc(`babies/${babyId}/media/${mediaId}`);
  const paths = mediaPaths(babyId, mediaId);
  const outPath = `${paths.dir}/display.mp4`;

  const finish = async (
    state: RenditionState,
    patch: Record<string, unknown>,
    error: string | null = null,
  ) => {
    await jobRef.update({
      state,
      error,
      finishedAt: new Date(),
      updatedAt: new Date(),
      activeSince: null,
      ...patch,
    });
  };

  const media = await ref.get();
  const original = media.get('paths.original') as string | undefined;
  if (
    !media.exists ||
    media.get('deleted') === true ||
    media.get('status') !== 'ready' ||
    media.get('type') !== 'video' ||
    !original
  ) {
    await finish('skipped', {}, 'gone');
    return 'gone';
  }
  if (media.get('paths.display')) {
    await finish('ready', {}, null);
    return 'already';
  }
  await ref.update({ 'rendition.state': 'running', 'rendition.updatedAt': now });

  let opened: OpenedVideo | null = null;
  try {
    opened = await video.open(original);
    if (!opened) {
      await ref.update({ 'rendition.state': 'skipped', 'rendition.reason': 'unreadable' });
      await finish('skipped', {}, 'unreadable');
      return 'skipped';
    }
    const skip = renditionSkipReason(opened.info, (media.get('sizeBytes') as number) ?? 0);
    if (skip) {
      await ref.update({ 'rendition.state': 'skipped', 'rendition.reason': skip });
      await finish('skipped', {}, skip);
      return 'skipped';
    }
    const spec = renditionSpecFor(opened.info);
    const needsPoster = !media.get('paths.poster');
    const started = Date.now();
    const out = await opened.transcode(outPath, spec, {
      deadlineMs: budgetMs,
      poster: needsPoster,
    });

    // A poster from the rendition when the phone sent none (files picked from "Tệp", shares).
    let posterBytes = 0;
    if (needsPoster && out.poster) {
      try {
        const big = await images.jpeg(out.poster, 1280, 80);
        const thumb = await images.jpeg(out.poster, 480, 72);
        await store.save(`${paths.dir}/poster.jpg`, big.bytes, 'image/jpeg');
        await store.save(`${paths.dir}/thumb.jpg`, thumb.bytes, 'image/jpeg');
        posterBytes = big.bytes.length + thumb.bytes.length;
      } catch {
        posterBytes = 0;
      }
    }

    const result = await db.runTransaction(async (tx) => {
      const fresh = await tx.get(ref);
      if (!fresh.exists || fresh.get('deleted') === true || fresh.get('status') !== 'ready') {
        return 'gone' as const;
      }
      if (fresh.get('paths.display')) return 'already' as const;
      const patch: Record<string, unknown> = {
        'paths.display': outPath,
        rendition: {
          state: 'ready',
          width: spec.width,
          height: spec.height,
          fps: spec.fps,
          bytes: out.bytes,
          hdrSource: spec.hdr,
          sourceCodec: opened!.info.videoCodec,
          tookMs: Date.now() - started,
          readyAt: new Date(),
          updatedAt: new Date(),
        },
        // Service copy: shown in the portal's storage view, not charged to the family (Q-079).
        renditionBytes: out.bytes,
        updatedAt: new Date(),
      };
      if (posterBytes > 0 && !fresh.get('paths.poster')) {
        patch['paths.poster'] = `${paths.dir}/poster.jpg`;
        patch['paths.thumb'] = `${paths.dir}/thumb.jpg`;
        patch.storedBytes = FieldValue.increment(posterBytes);
        tx.update(db.doc(`families/${fresh.get('familyId') as string}`), {
          usedBytes: FieldValue.increment(posterBytes),
        });
      }
      tx.update(ref, patch);
      return 'ready' as const;
    });
    if (result !== 'ready') {
      // Deleted meanwhile, or another run got there first: nothing of ours stays behind.
      if (result === 'gone') {
        await store.delete(outPath);
        if (posterBytes > 0) {
          await store.delete(`${paths.dir}/poster.jpg`);
          await store.delete(`${paths.dir}/thumb.jpg`);
        }
      }
      await finish(result === 'gone' ? 'skipped' : 'ready', {}, result === 'gone' ? 'gone' : null);
      return result;
    }
    await finish('ready', { bytes: out.bytes, tookMs: Date.now() - started });
    return 'ready';
  } catch (e) {
    // Codes only (timeout, exit status): the message may name the temp file, never the child.
    const code = e instanceof Error ? e.message.split('\n')[0]!.slice(0, 120) : 'unknown';
    try {
      await store.delete(outPath);
    } catch {
      // Nothing written.
    }
    await ref.update({
      'rendition.state': 'failed',
      'rendition.reason': code,
      'rendition.updatedAt': new Date(),
    });
    await finish('failed', {}, code);
    return 'failed';
  } finally {
    await opened?.close();
  }
}

/**
 * Hourly: a job queued or running for longer than `staleAfterMs` (an instance died, an event
 * was lost) is marked `lost` and queued again, up to `maxAttempts` in all. Returns how many.
 */
export async function requeueStaleVideoRenditions(db: Firestore, now: Date): Promise<number> {
  const cutoff = Timestamp.fromMillis(now.getTime() - renditionLimits.staleAfterMs);
  const stale = await db
    .collection('videoRenditionJobs')
    .where('activeSince', '<=', cutoff)
    .limit(100)
    .get();
  let n = 0;
  for (const doc of stale.docs) {
    const attempt = (doc.get('attempt') as number | undefined) ?? 1;
    const babyId = doc.get('babyId') as string;
    const mediaId = doc.get('mediaId') as string;
    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (!fresh.exists || !fresh.get('activeSince')) return;
      tx.update(doc.ref, {
        state: 'lost',
        activeSince: null,
        finishedAt: now,
        updatedAt: now,
        error: 'stale',
      });
      if (attempt < renditionLimits.maxAttempts) {
        tx.set(
          db.doc(`videoRenditionJobs/${renditionJobId(mediaId, attempt + 1)}`),
          renditionJobDoc(babyId, mediaId, now, attempt + 1),
        );
      } else {
        tx.update(db.doc(`babies/${babyId}/media/${mediaId}`), {
          'rendition.state': 'failed',
          'rendition.reason': 'stale',
          'rendition.updatedAt': now,
        });
      }
      n++;
    });
  }
  return n;
}
