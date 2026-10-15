import { createHash } from 'node:crypto';
import sharp from 'sharp';
import {
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import type { getStorage } from 'firebase-admin/storage';
import {
  createAttachmentUploadRequestSchema,
  type AssistantAttachmentView,
  type AssistantResponse,
  type AssistantScope,
  type AssistantUploadTarget,
  type AttachmentRetention,
  type AttachmentState,
  type GrantEnvironment,
} from '@child-life/contracts';
import {
  assistantConsentGranted,
  assistantFlagOn,
  consentRef,
  fail,
  loadTrustedScope,
  parseRequest,
  quoteRef,
  requireAssistant,
  respond,
  sameScope,
  sha,
  taskRef,
  toDate,
  toIso,
  withRequest,
  type TrustedScope,
} from './assistant-common.js';
import { assistantUsage } from './assistant-usage.js';

/**
 * Child Life Assistant, slice A3: photo attachments (brief p.14, p.19; CH09–CH12; G05, M06, M07).
 *
 * - `createAttachmentUpload` hands out an owned upload target only for an image quote that is
 *   still allowed (enough credits now, consent, flags): no credits → no upload (U03, J08).
 * - The app uploads once to `assistant/{uid}/{at_*}` (Storage Rules: the uploader, once, the
 *   declared type, no larger than declared, before the target expires; nobody reads it back).
 * - `startTask` verifies ownership, scope, state, expiry and the uploaded object (size, type,
 *   generation) before reserving credits; the worker re-checks, sniffs the magic bytes and
 *   decodes with sharp (pixel limit) BEFORE any provider call, and sends only a re-encoded JPEG
 *   (metadata stripped). Anything wrong → rejected before the provider, credits released.
 * - Retention is honest: `deleted` only once Storage confirmed the deletion; a failed deletion is
 *   `deletion_pending` and retried by the sweeper (never shown as deleted).
 *
 * Nothing here logs a path with content, a photo, a reading or a hash.
 */

// ---------- Storage port ----------

export interface StoredObject {
  size: number;
  contentType: string;
  /** The object generation: the worker reads exactly the version verified at start. */
  generation: string;
}

/** The default bucket behind one port (tests use memory). */
export interface AttachmentStore {
  stat(path: string): Promise<StoredObject | null>;
  /** The bytes of [generation] of [path]; throws when that version is gone. */
  read(path: string, generation: string): Promise<Buffer>;
  write(path: string, bytes: Buffer, contentType: string): Promise<void>;
  /** Deletes the live object; a missing object is not an error. */
  delete(path: string): Promise<void>;
  exists(path: string): Promise<boolean>;
}

type Bucket = ReturnType<ReturnType<typeof getStorage>['bucket']>;

export function bucketAttachmentStore(bucket: Bucket): AttachmentStore {
  return {
    async stat(path) {
      const file = bucket.file(path);
      const [exists] = await file.exists();
      if (!exists) return null;
      const [meta] = await file.getMetadata();
      return {
        size: Number(meta.size ?? 0),
        contentType: meta.contentType ?? '',
        generation: String(meta.generation ?? ''),
      };
    },
    async read(path, generation) {
      const [data] = await bucket.file(path, { generation: Number(generation) }).download();
      return data;
    },
    async write(path, bytes, contentType) {
      await bucket.file(path).save(bytes, {
        contentType,
        resumable: false,
        metadata: { cacheControl: 'private, max-age=31536000' },
      });
    },
    async delete(path) {
      await bucket.file(path).delete({ ignoreNotFound: true });
    },
    async exists(path) {
      return (await bucket.file(path).exists())[0];
    },
  };
}

/** In-memory store for tests: `put` stands for the app's upload; `failDeletes` for M07. */
export function memoryAttachmentStore(): AttachmentStore & {
  objects: Map<string, { bytes: Buffer; contentType: string; generation: string }>;
  put(path: string, bytes: Buffer, contentType: string): void;
  failDeletes: boolean;
} {
  const objects = new Map<string, { bytes: Buffer; contentType: string; generation: string }>();
  let gen = 1000;
  const store = {
    objects,
    failDeletes: false,
    put(path: string, bytes: Buffer, contentType: string) {
      gen += 1;
      objects.set(path, { bytes: Buffer.from(bytes), contentType, generation: String(gen) });
    },
    async stat(path: string) {
      const o = objects.get(path);
      return o
        ? { size: o.bytes.length, contentType: o.contentType, generation: o.generation }
        : null;
    },
    async read(path: string, generation: string) {
      const o = objects.get(path);
      if (!o || o.generation !== generation) throw new Error('gone');
      return Buffer.from(o.bytes);
    },
    async write(path: string, bytes: Buffer, contentType: string) {
      store.put(path, bytes, contentType);
    },
    async delete(path: string) {
      if (store.failDeletes) throw new Error('storage unavailable');
      objects.delete(path);
    },
    async exists(path: string) {
      return objects.has(path);
    },
  };
  return store;
}

// ---------- Documents ----------

/** Upload targets expire after this (the quote itself lives 5 minutes). */
export const uploadTtlMinutes = 15;
/** Unbound uploads and blocked tasks' photos are deleted after this. */
const staleUploadMs = 60 * 60_000;
const blockedKeepMs = 24 * 3_600_000;

export const attachmentRef = (db: Firestore, id: string) => db.doc(`assistantAttachments/${id}`);
export const attachmentPath = (uid: string, id: string) => `assistant/${uid}/${id}`;
/** Same uid + clientRequestId → the same attachment (a replayed `createAttachmentUpload`). */
export const attachmentIdFor = (uid: string, clientRequestId: string) =>
  `at_${sha(`attachment|${uid}|${clientRequestId}`).slice(0, 32)}`;

export interface StoredAttachment {
  id: string;
  ownerUid: string;
  familyId: string;
  scope: AssistantScope;
  quoteId: string;
  storagePath: string;
  mime: string;
  bytes: number;
  sha256: string;
  retention: AttachmentRetention;
  state: AttachmentState;
  generation: string | null;
  taskId: string | null;
  uploadExpiresAt: Timestamp;
  rejected: boolean;
  keptPath: string | null;
  savedExpenseIds: string[];
  deletion: { attempts: number; nextAttemptAt: Timestamp; lastError: string } | null;
  deletedAt: Timestamp | null;
}

export const storedAttachment = (snap: DocumentSnapshot) => snap.data() as StoredAttachment;

export function attachmentView(snap: DocumentSnapshot): AssistantAttachmentView {
  const a = storedAttachment(snap);
  return {
    id: snap.id,
    mime: a.mime,
    bytes: a.bytes,
    retention: a.retention,
    state: a.state,
    keptWithRecord: a.keptPath !== null && a.keptPath !== undefined,
    deletedAt: a.state === 'deleted' ? toIso(a.deletedAt) : null,
    rejected: a.rejected === true,
  };
}

/** The views of [ids] in order (missing ones skipped). */
export async function attachmentViews(
  db: Firestore,
  ids: readonly string[],
): Promise<AssistantAttachmentView[]> {
  if (ids.length === 0) return [];
  const snaps = await db.getAll(...ids.map((id) => attachmentRef(db, id)));
  return snaps.filter((s) => s.exists).map(attachmentView);
}

// ---------- createAttachmentUpload ----------

export interface AttachmentDeps {
  db: Firestore;
  now: Date;
  environment: GrantEnvironment;
}

/**
 * `createAttachmentUpload` (CH09 → CH10): an owned upload target for one photo of an image
 * quote. The quote must be the caller's, for images, unexpired, not yet used, and allowed — and
 * the household must still have its credits now (U03: "thiếu credit → không upload"); consent
 * and the photo flags hold. One target per photo the quote counted. Replays (same
 * clientRequestId) answer the same target; nothing is reserved here.
 */
export async function createAttachmentUpload(
  deps: AttachmentDeps,
  uid: string,
  data: unknown,
): Promise<AssistantResponse<AssistantUploadTarget>> {
  const { db, now } = deps;
  const req = parseRequest(createAttachmentUploadRequestSchema, data);
  const { contractVersion: _c, clientRequestId, locale: _l, ...input } = req;
  void _c;
  void _l;
  return withRequest(db, uid, 'attach', clientRequestId, input, now, async () => {
    const q = await quoteRef(db, req.quoteId).get();
    if (!q.exists || q.get('ownerUid') !== uid || q.get('modality') !== 'image') {
      throw fail('QUOTE_MISMATCH');
    }
    if ((toDate(q.get('expiresAt'))?.getTime() ?? 0) <= now.getTime()) throw fail('QUOTE_EXPIRED');
    if (q.get('usedBy') !== null) throw fail('QUOTE_MISMATCH');
    if (q.get('allowed') !== true) {
      throw fail(
        (q.get('reason') as Parameters<typeof fail>[0] | null | undefined) ?? 'USAGE_EXHAUSTED',
      );
    }
    const s = await loadTrustedScope(
      db,
      uid,
      q.get('scope') as AssistantScope,
      now,
      deps.environment,
    );
    requireAssistant(s);
    if (!assistantFlagOn(s, 'assistant_images')) throw fail('FEATURE_DISABLED');
    if (!assistantConsentGranted(await consentRef(db, uid).get())) throw fail('CONSENT_REQUIRED');
    // The pool may have moved since the quote (another member's task): no upload without credits.
    const usage = await assistantUsage(db, s, now);
    if (usage.remaining < (q.get('credits') as number)) throw fail('USAGE_EXHAUSTED');

    const id = attachmentIdFor(uid, clientRequestId);
    const path = attachmentPath(uid, id);
    const expiresAt = new Date(now.getTime() + uploadTtlMinutes * 60_000);
    await db.runTransaction(async (tx) => {
      const [quote, existing] = await Promise.all([tx.get(q.ref), tx.get(attachmentRef(db, id))]);
      if (existing.exists) return;
      if (quote.get('usedBy') !== null) throw fail('QUOTE_MISMATCH');
      const issued = (quote.get('attachmentsIssued') as number | undefined) ?? 0;
      if (issued >= (quote.get('attachmentCount') as number)) {
        throw fail('VALIDATION_FAILED', { field: 'attachmentCount' });
      }
      const at = Timestamp.fromDate(now);
      tx.update(quote.ref, { attachmentsIssued: issued + 1 });
      tx.create(attachmentRef(db, id), {
        id,
        ownerUid: uid,
        uploaderUid: uid,
        familyId: s.familyId,
        scope: q.get('scope'),
        quoteId: req.quoteId,
        storagePath: path,
        mime: req.mime,
        bytes: req.bytes,
        sha256: req.sha256,
        // Computed by the worker from the bytes (the client's sha256 is never trusted).
        sha256Server: null,
        retention: req.retention,
        state: 'uploading',
        generation: null,
        taskId: null,
        uploadExpiresAt: Timestamp.fromDate(expiresAt),
        rejected: false,
        keptPath: null,
        savedExpenseIds: [],
        deletion: null,
        deletedAt: null,
        createdAt: at,
        updatedAt: at,
      });
    });
    const stored = storedAttachment(await attachmentRef(db, id).get());
    return respond(clientRequestId, now, {
      attachmentId: id,
      uploadPath: stored.storagePath,
      mime: stored.mime,
      maxBytes: stored.bytes,
      expiresAt: toIso(stored.uploadExpiresAt) ?? expiresAt.toISOString(),
      retention: stored.retention,
    });
  });
}

// ---------- startTask: verify before reserving ----------

export interface VerifiedAttachment {
  id: string;
  generation: string;
}

/**
 * The photos of a new task, checked before any credit moves (M06): the caller's own, for the
 * same scope and household, not used by another task, not deleted or refused, uploaded before
 * the target expired, and the stored object is there with the declared type and no larger than
 * declared. The generation verified here is the one the worker reads.
 */
export async function verifyAttachmentsForStart(
  db: Firestore,
  files: AttachmentStore,
  s: TrustedScope,
  uid: string,
  scope: AssistantScope,
  taskId: string,
  ids: readonly string[],
  now: Date,
): Promise<VerifiedAttachment[]> {
  if (new Set(ids).size !== ids.length) throw fail('VALIDATION_FAILED', { field: 'attachmentIds' });
  const out: VerifiedAttachment[] = [];
  for (const id of ids) {
    const snap = await attachmentRef(db, id).get();
    if (!snap.exists || snap.get('ownerUid') !== uid) throw fail('NOT_MEMBER');
    const a = storedAttachment(snap);
    if (a.familyId !== s.familyId || !sameScope(a.scope, scope)) throw fail('SCOPE_CHANGED');
    if (a.taskId !== null && a.taskId !== taskId) {
      throw fail('VALIDATION_FAILED', { field: 'attachmentIds', problem: 'attachment_used' });
    }
    // Bound to this very task already (a replay or a resume): the task decides what follows.
    if (a.taskId === taskId) {
      out.push({ id, generation: a.generation ?? '' });
      continue;
    }
    if (a.rejected || a.state === 'deleted' || a.state === 'deletion_pending') {
      throw fail('VALIDATION_FAILED', { field: 'attachmentIds', problem: 'attachment_gone' });
    }
    if ((toDate(a.uploadExpiresAt)?.getTime() ?? 0) <= now.getTime()) {
      throw fail('VALIDATION_FAILED', { field: 'attachmentIds', problem: 'attachment_expired' });
    }
    const obj = await files.stat(a.storagePath);
    if (!obj)
      throw fail('VALIDATION_FAILED', { field: 'attachmentIds', problem: 'upload_missing' });
    if (obj.size <= 0 || obj.size > a.bytes || obj.contentType !== a.mime) {
      throw fail('VALIDATION_FAILED', { field: 'attachmentIds', problem: 'upload_mismatch' });
    }
    out.push({ id, generation: obj.generation });
  }
  return out;
}

/** Reads the attachment documents inside the start transaction (reads before writes). */
export function readAttachmentsTx(
  tx: Transaction,
  db: Firestore,
  ids: readonly string[],
): Promise<DocumentSnapshot[]> {
  return Promise.all(ids.map((id) => tx.get(attachmentRef(db, id))));
}

/** Binds the verified photos to the task (same transaction as the reservation). */
export function bindAttachmentsTx(
  tx: Transaction,
  snaps: readonly DocumentSnapshot[],
  verified: readonly VerifiedAttachment[],
  taskId: string,
  now: Date,
): void {
  snaps.forEach((snap, i) => {
    const a = storedAttachment(snap);
    if (a.taskId !== null && a.taskId !== taskId) {
      throw fail('VALIDATION_FAILED', { field: 'attachmentIds', problem: 'attachment_used' });
    }
    if (a.state === 'deleted' || a.state === 'deletion_pending' || a.rejected) {
      throw fail('VALIDATION_FAILED', { field: 'attachmentIds', problem: 'attachment_gone' });
    }
    if (a.taskId === taskId && a.state === 'ready') return;
    tx.update(snap.ref, {
      state: 'ready',
      taskId,
      generation: verified[i]!.generation,
      updatedAt: Timestamp.fromDate(now),
    });
  });
}

// ---------- Worker: load and validate before the provider ----------

const HEIF_BRANDS = new Set(['heic', 'heix', 'hevc', 'hevx', 'heim', 'heis', 'mif1', 'msf1']);

/** The image type the bytes really are (magic numbers), never the client's word. */
export function sniffImage(bytes: Buffer): string | null {
  if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return 'image/jpeg';
  }
  if (
    bytes.length >= 8 &&
    bytes.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))
  ) {
    return 'image/png';
  }
  if (
    bytes.length >= 12 &&
    bytes.subarray(0, 4).toString('latin1') === 'RIFF' &&
    bytes.subarray(8, 12).toString('latin1') === 'WEBP'
  ) {
    return 'image/webp';
  }
  if (
    bytes.length >= 12 &&
    bytes.subarray(4, 8).toString('latin1') === 'ftyp' &&
    HEIF_BRANDS.has(bytes.subarray(8, 12).toString('latin1'))
  ) {
    return 'image/heic';
  }
  return null;
}

/** Decode limits: no decompression bombs, no thumbnails too small to read. */
export const imageLimits = { maxPixels: 40_000_000, minSide: 32, sendMaxSide: 2048 } as const;

export interface ValidatedImage {
  /** Re-encoded JPEG: orientation applied, EXIF / GPS / ICC dropped (P-033). */
  jpeg: Buffer;
  width: number;
  height: number;
}

/**
 * The bytes are the declared image type and decode within the limits; returns the JPEG the
 * provider may see (≤ 2048 px). Null when not (refused before any provider call).
 */
export async function validateImage(bytes: Buffer, mime: string): Promise<ValidatedImage | null> {
  if (sniffImage(bytes) !== mime) return null;
  try {
    const opts = { failOn: 'error' as const, limitInputPixels: imageLimits.maxPixels };
    const meta = await sharp(bytes, opts).metadata();
    if (!meta.width || !meta.height) return null;
    if (Math.min(meta.width, meta.height) < imageLimits.minSide) return null;
    const { data, info } = await sharp(bytes, opts)
      .rotate()
      .resize({
        width: imageLimits.sendMaxSide,
        height: imageLimits.sendMaxSide,
        fit: 'inside',
        withoutEnlargement: true,
      })
      .jpeg({ quality: 85, mozjpeg: true })
      .toBuffer({ resolveWithObject: true });
    return { jpeg: data, width: info.width, height: info.height };
  } catch {
    return null;
  }
}

export type LoadedImages =
  | {
      ok: true;
      images: ValidatedImage[];
      sha256s: string[];
      keepReceipt: boolean;
    }
  | { ok: false; reason: 'attachment' | 'invalid_image' };

/**
 * The worker's re-check (M06): every photo still belongs to this task's owner, household and
 * task, is `ready` with the verified generation, and its bytes are a real, decodable image of the
 * declared type. A refused photo is marked (`rejected`) so the app can say why.
 */
export async function loadTaskImages(
  db: Firestore,
  files: AttachmentStore,
  t: { id: string; ownerUid: string; familyId: string; input: { attachmentIds: string[] } },
  now: Date,
): Promise<LoadedImages> {
  const images: ValidatedImage[] = [];
  const hashes: string[] = [];
  let keepReceipt = false;
  for (const id of t.input.attachmentIds ?? []) {
    const snap = await attachmentRef(db, id).get();
    if (!snap.exists) return { ok: false, reason: 'attachment' };
    const a = storedAttachment(snap);
    if (
      a.ownerUid !== t.ownerUid ||
      a.familyId !== t.familyId ||
      a.taskId !== t.id ||
      a.state !== 'ready' ||
      !a.generation
    ) {
      return { ok: false, reason: 'attachment' };
    }
    let bytes: Buffer;
    try {
      bytes = await files.read(a.storagePath, a.generation);
    } catch {
      return { ok: false, reason: 'attachment' };
    }
    const valid = bytes.length <= a.bytes ? await validateImage(bytes, a.mime) : null;
    if (!valid) {
      await snap.ref.update({ rejected: true, updatedAt: Timestamp.fromDate(now) });
      return { ok: false, reason: 'invalid_image' };
    }
    images.push(valid);
    const hash = sha256Of(bytes);
    hashes.push(hash);
    // Kept for the household duplicate check ("same photo already saved"), never sent anywhere.
    if (snap.get('sha256Server') !== hash) {
      await snap.ref.update({ sha256Server: hash, updatedAt: Timestamp.fromDate(now) });
    }
    if (a.retention === 'keep_with_record') keepReceipt = true;
  }
  if (images.length === 0) return { ok: false, reason: 'attachment' };
  return { ok: true, images, sha256s: hashes, keepReceipt };
}

/** The photo's content hash (hex), computed by the server — the client's value is not trusted. */
export const sha256Of = (bytes: Buffer) => createHash('sha256').update(bytes).digest('hex');

// ---------- Retention (G05, I05, M07) ----------

const backoffMs = (attempts: number) => Math.min(2 ** attempts * 60_000, 6 * 3_600_000);

/**
 * Deletes the uploaded original of [id]. `deleted` only once Storage confirmed it (the delete
 * returned and the object is gone); otherwise `deletion_pending` with a retry time — the app
 * never shows "đã xoá" before that.
 */
export async function deleteAttachmentObject(
  db: Firestore,
  files: AttachmentStore,
  id: string,
  now: Date,
): Promise<AttachmentState | null> {
  const ref = attachmentRef(db, id);
  const snap = await ref.get();
  if (!snap.exists) return null;
  const a = storedAttachment(snap);
  if (a.state === 'deleted') return 'deleted';
  try {
    await files.delete(a.storagePath);
    if (await files.exists(a.storagePath)) throw new Error('still present');
  } catch {
    const attempts = (a.deletion?.attempts ?? 0) + 1;
    await ref.update({
      state: 'deletion_pending',
      deletion: {
        attempts,
        nextAttemptAt: Timestamp.fromMillis(now.getTime() + backoffMs(attempts)),
        lastError: 'storage',
      },
      updatedAt: Timestamp.fromDate(now),
    });
    return 'deletion_pending';
  }
  await ref.update({
    state: 'deleted',
    deletedAt: Timestamp.fromDate(now),
    deletion: null,
    updatedAt: Timestamp.fromDate(now),
  });
  return 'deleted';
}

/**
 * Whether a "Giữ ảnh hoá đơn" photo must stay for now: its task may still save an expense that
 * keeps the receipt (a live, unsaved expense draft with keepReceipt), or the task is still
 * running / asking. Everything else lets the temporary original go.
 */
async function keepPending(db: Firestore, taskId: string, now: Date): Promise<boolean> {
  const task = await taskRef(db, taskId).get();
  if (!task.exists) return false;
  const state = task.get('state') as string;
  if (state === 'queued' || state === 'processing') return true;
  if (state === 'awaiting_clarification') {
    // Only a photo that can still become an expense (a receipt was read) waits for the answer.
    const reading = await task.ref.collection('imageReading').doc('current').get();
    return reading.get('reading.receipt') != null;
  }
  if (state === 'blocked') {
    return now.getTime() - (toDate(task.get('updatedAt'))?.getTime() ?? 0) < blockedKeepMs;
  }
  if (state !== 'ready') return false;
  const drafts = await task.ref.collection('drafts').get();
  return drafts.docs.some(
    (d) =>
      d.get('payload.kind') === 'expense' &&
      d.get('payload.keepReceipt') === true &&
      !['saved', 'discarded'].includes(d.get('state') as string) &&
      (toDate(d.get('expiresAt'))?.getTime() ?? 0) > now.getTime(),
  );
}

/**
 * After a task settles, is cancelled or stopped: "xoá sau khi đọc" photos are deleted at once
 * (the reading the task still needs is cached server-side); "giữ ảnh hoá đơn" photos stay only
 * while an expense that keeps them can still be saved. Returns the attachment states.
 */
export async function settleTaskAttachments(
  db: Firestore,
  files: AttachmentStore | undefined,
  taskId: string,
  now: Date,
  force = false,
): Promise<Record<string, AttachmentState | null>> {
  const out: Record<string, AttachmentState | null> = {};
  if (!files) return out;
  const snaps = await db.collection('assistantAttachments').where('taskId', '==', taskId).get();
  if (snaps.empty) return out;
  if (!force) {
    // A run (re)claimed the task meanwhile: it may still need the photo; it settles it itself.
    const state = (await taskRef(db, taskId).get()).get('state') as string | undefined;
    if (state === 'queued' || state === 'processing') return out;
  }
  const keep = force ? false : await keepPending(db, taskId, now);
  for (const d of snaps.docs) {
    const a = storedAttachment(d);
    if (a.state === 'deleted') {
      out[d.id] = 'deleted';
      continue;
    }
    if (!force && a.retention === 'keep_with_record' && keep) {
      out[d.id] = a.state;
      continue;
    }
    out[d.id] = await deleteAttachmentObject(db, files, d.id, now);
  }
  return out;
}

/**
 * Sweeper (every 15 minutes): retries pending deletions when due, deletes uploads never bound to
 * a task once their target expired (+1 h), and lets go of photos whose task no longer needs them
 * (finished, discarded, expired drafts, deleted task). Bounded per run.
 */
export async function sweepAssistantAttachments(
  db: Firestore,
  files: AttachmentStore,
  now: Date,
): Promise<{ deleted: number; pending: number }> {
  let deleted = 0;
  let pending = 0;
  const snaps = await db
    .collection('assistantAttachments')
    .where('state', 'in', ['uploading', 'ready', 'deletion_pending'])
    .limit(500)
    .get();
  const decided = new Map<string, boolean>();
  for (const d of snaps.docs) {
    const a = storedAttachment(d);
    let go: boolean;
    if (a.state === 'deletion_pending') {
      go = (toDate(a.deletion?.nextAttemptAt)?.getTime() ?? 0) <= now.getTime();
    } else if (a.taskId === null) {
      go = (toDate(a.uploadExpiresAt)?.getTime() ?? 0) + staleUploadMs <= now.getTime();
    } else if (a.retention === 'delete_after_read') {
      const task = await taskRef(db, a.taskId).get();
      go = !task.exists || ['ready', 'failed', 'canceled'].includes(task.get('state') as string);
      if (task.exists && task.get('state') === 'blocked') {
        go = now.getTime() - (toDate(task.get('updatedAt'))?.getTime() ?? 0) >= blockedKeepMs;
      }
    } else {
      if (!decided.has(a.taskId)) decided.set(a.taskId, !(await keepPending(db, a.taskId, now)));
      go = decided.get(a.taskId)!;
    }
    if (!go) continue;
    const r = await deleteAttachmentObject(db, files, d.id, now);
    if (r === 'deleted') deleted += 1;
    else if (r === 'deletion_pending') pending += 1;
  }
  return { deleted, pending };
}
