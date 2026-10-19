import { backfillVideoRenditionsSchema, requeueVideoRenditionSchema } from '@child-life/contracts';
import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { StaffError, parse, requireStaff, staffAudit, type Staff } from './staff.js';
import { renditionJobDoc, renditionJobId } from './video-renditions.js';

/**
 * Streaming renditions in the portal (P-170; R-185 "Thử xử lý lại video", R-188 System): staff
 * see job counts and codes in `systemHealth` and may run one video's job again, or queue the
 * videos from before the feature (the prod rollout). Both need `system.video`, a reason, and
 * write the audit log (A12). Nothing here reads or returns the video, a caption or a name:
 * media ids, job ids and error codes only.
 */

const mediaIdRe = /^med_[a-f0-9]{32}$/;

/**
 * `med_…`, the job id `med_…~2`, or the item's path `babies/{b}/media/{m}` (with or without the
 * console's `projects/…/documents/` prefix). Null when it is none of these.
 */
export function parseMediaRef(raw: string): { mediaId: string; babyId: string | null } | null {
  const s = raw.trim();
  const path =
    /^(?:projects\/[^/]+\/databases\/[^/]+\/documents\/)?babies\/([^/\s]+)\/media\/([^/\s~]+)(?:~\d+)?$/.exec(
      s,
    );
  if (path) return mediaIdRe.test(path[2]!) ? { mediaId: path[2]!, babyId: path[1]! } : null;
  const bare = /^([^/\s~]+)(?:~\d+)?$/.exec(s);
  if (bare && mediaIdRe.test(bare[1]!)) return { mediaId: bare[1]!, babyId: null };
  return null;
}

const toMs = (v: unknown) =>
  v instanceof Timestamp ? v.toMillis() : v instanceof Date ? v.getTime() : 0;

/**
 * "Thử xử lý lại video": a new attempt for one ready, undeleted video that has no rendition.
 * Refused while an attempt is queued or running (`already-queued`), once the rendition exists
 * (`has-rendition`), and for anything that is not a ready video (`not-video`).
 */
export async function requeueVideoRendition(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
): Promise<{ jobId: string; attempt: number }> {
  const s = requireStaff(staff, 'system.video');
  const req = parse(requeueVideoRenditionSchema, data);
  const ref = parseMediaRef(req.media);
  if (!ref) throw new StaffError('invalid-argument', 'malformed');
  const jobsQuery = db.collection('videoRenditionJobs').where('mediaId', '==', ref.mediaId);
  // The baby comes with the path, or from an earlier job of the same item.
  const babyId =
    ref.babyId ??
    ((await jobsQuery.limit(1).get()).docs[0]?.get('babyId') as string | undefined) ??
    null;
  if (!babyId) throw new StaffError('not-found', 'not-found');
  const mediaRef = db.doc(`babies/${babyId}/media/${ref.mediaId}`);
  return db.runTransaction(async (tx) => {
    const [media, jobs] = await Promise.all([tx.get(mediaRef), tx.get(jobsQuery)]);
    if (!media.exists) throw new StaffError('not-found', 'not-found');
    if (
      media.get('type') !== 'video' ||
      media.get('status') !== 'ready' ||
      media.get('deleted') === true ||
      !media.get('paths.original')
    ) {
      throw new StaffError('failed-precondition', 'not-video');
    }
    if (media.get('paths.display')) throw new StaffError('failed-precondition', 'has-rendition');
    if (jobs.docs.some((j) => j.get('activeSince'))) {
      throw new StaffError('failed-precondition', 'already-queued');
    }
    const attempt =
      jobs.docs.reduce((n, j) => Math.max(n, (j.get('attempt') as number | undefined) ?? 1), 0) + 1;
    const jobId = renditionJobId(ref.mediaId, attempt);
    tx.create(
      db.doc(`videoRenditionJobs/${jobId}`),
      renditionJobDoc(babyId, ref.mediaId, now, attempt),
    );
    tx.update(mediaRef, { 'rendition.state': 'queued', 'rendition.updatedAt': now });
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'system.videoRequeue',
        category: 'data',
        target: ref.mediaId,
        reason: req.reason,
        detail: {
          jobId,
          attempt,
          previous: {
            state: (media.get('rendition.state') as string | undefined) ?? null,
            reason: (media.get('rendition.reason') as string | undefined) ?? null,
          },
        },
      },
      now,
    );
    return { jobId, attempt };
  });
}

/**
 * Prod rollout (P-170): queues the ready, undeleted videos that have neither `paths.display`
 * nor a `rendition.state` — the ones uploaded before the feature — `limit` per call, oldest
 * first, so the owner runs it from the portal in batches of what five instances finish in a
 * few minutes. Idempotent: a queued item carries `rendition.state`, so the next call passes it.
 * Returns how many were queued, how many changed under it, and how many are left for later.
 */
export async function backfillVideoRenditions(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
): Promise<{ queued: number; skipped: number; remaining: number }> {
  const s = requireStaff(staff, 'system.video');
  const req = parse(backfillVideoRenditionsSchema, data);
  const ready = await db
    .collectionGroup('media')
    .where('type', '==', 'video')
    .where('status', '==', 'ready')
    .select('deleted', 'paths.display', 'paths.original', 'rendition.state', 'createdAt')
    .get();
  const candidates = ready.docs
    .filter(
      (d) =>
        d.get('deleted') !== true &&
        !d.get('paths.display') &&
        !d.get('rendition.state') &&
        !!d.get('paths.original'),
    )
    .sort((a, b) => toMs(a.get('createdAt')) - toMs(b.get('createdAt')));
  let queued = 0;
  let skipped = 0;
  for (const d of candidates.slice(0, req.limit)) {
    const babyId = d.ref.parent.parent!.id;
    const jobRef = db.doc(`videoRenditionJobs/${renditionJobId(d.id, 1)}`);
    const did = await db.runTransaction(async (tx) => {
      const [fresh, job] = await Promise.all([tx.get(d.ref), tx.get(jobRef)]);
      if (
        job.exists ||
        !fresh.exists ||
        fresh.get('deleted') === true ||
        fresh.get('status') !== 'ready' ||
        fresh.get('paths.display') ||
        fresh.get('rendition.state')
      ) {
        return false;
      }
      tx.create(jobRef, renditionJobDoc(babyId, d.id, now));
      tx.update(d.ref, { rendition: { state: 'queued', updatedAt: now } });
      return true;
    });
    if (did) queued++;
    else skipped++;
  }
  const remaining = candidates.length - queued - skipped;
  const batch = db.batch();
  staffAudit(
    batch,
    db,
    s,
    {
      action: 'system.videoBackfill',
      category: 'data',
      target: 'videos',
      reason: req.reason,
      detail: { limit: req.limit, queued, skipped, remaining },
    },
    now,
  );
  await batch.commit();
  return { queued, skipped, remaining };
}
