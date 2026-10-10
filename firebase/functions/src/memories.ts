import {
  FieldValue,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import {
  batchReadyToNotify,
  cancelUploadsRequestSchema,
  createMemoryRequestSchema,
  dayBoundsIn,
  defaultLimits,
  effectiveAudience,
  limitsSchema,
  memoryLimits,
  reserveUploadsRequestSchema,
  sniffMedia,
  updateMediaRequestSchema,
  type Audience,
  type CreateMemoryResponse,
  type MediaStatus,
  type UploadItem,
} from '@child-life/contracts';

/**
 * Memories (S9). The server owns `memories` and `media`: the app asks for an upload session
 * (quota reserved, P-031), uploads raw bytes to `babies/{b}/uploads/{mediaId}` (Storage Rules
 * check the reservation), and `processUpload` validates the real content, strips metadata
 * (P-033), writes renditions, commits the quota and lets the media trigger publish the memory and
 * send the batch's single notification (P-030). Captions, photos and names are never logged.
 */

import { familyNotice, recomputeAlbum, recomputeEffective } from './albums.js';

export class MemoryError extends Error {
  constructor(
    readonly code:
      | 'invalid-argument'
      | 'permission-denied'
      | 'not-found'
      | 'failed-precondition'
      | 'resource-exhausted',
    readonly reason: string,
  ) {
    super(reason);
  }
}

/** Storage surface (Admin SDK bucket in production, an in-memory fake in tests). */
export interface MediaStore {
  head(path: string, bytes: number): Promise<Uint8Array | null>;
  read(path: string): Promise<Uint8Array | null>;
  save(path: string, bytes: Uint8Array, contentType: string): Promise<void>;
  move(from: string, to: string, contentType: string): Promise<void>;
  size(path: string): Promise<number | null>;
  delete(path: string): Promise<void>;
}

/** Image work (sharp in production): auto-orient, fit inside [max], JPEG without metadata. */
export interface ImageOps {
  jpeg(
    input: Uint8Array,
    max: number,
    quality: number,
  ): Promise<{ bytes: Uint8Array; width: number; height: number }>;
}

const HOUR_MS = 3_600_000;
const DAY_MS = 86_400_000;

/** Renditions add a display copy and a thumbnail; reserve room for them up front. */
function reservationFor(item: { type: string; sizeBytes: number }): number {
  return item.type === 'photo'
    ? item.sizeBytes + 1_000_000
    : item.sizeBytes + memoryLimits.posterMaxBytes;
}

export const mediaPaths = (babyId: string, mediaId: string) => ({
  upload: `babies/${babyId}/uploads/${mediaId}`,
  poster: `babies/${babyId}/uploads/${mediaId}.poster`,
  dir: `babies/${babyId}/media/${mediaId}`,
});

async function readLimits(db: Firestore) {
  const snap = await db.doc('config/limits').get();
  const parsed = limitsSchema.safeParse(snap.data());
  return parsed.success ? parsed.data : defaultLimits;
}

interface Member {
  role: string;
  displayName: string;
  relation: string;
  relationCustom: string | null;
}

async function activeMember(
  tx: Transaction,
  db: Firestore,
  babyId: string,
  uid: string,
  now: Date,
): Promise<Member | null> {
  const snap = await tx.get(db.doc(`babies/${babyId}/members/${uid}`));
  if (!snap.exists || snap.get('status') !== 'active') return null;
  const until = snap.get('accessUntilAt') as Timestamp | null | undefined;
  if (until && until.toMillis() <= now.getTime()) return null;
  return {
    role: snap.get('role') as string,
    displayName: (snap.get('displayName') as string | undefined) ?? '',
    relation: (snap.get('relation') as string | undefined) ?? 'other',
    relationCustom: (snap.get('relationCustom') as string | null | undefined) ?? null,
  };
}

/** Adding, editing and deleting memories is for Cùng nuôi only (§5, R-111, R-119). */
async function requireParent(
  tx: Transaction,
  db: Firestore,
  babyId: string,
  uid: string,
  now: Date,
): Promise<Member> {
  const me = await activeMember(tx, db, babyId, uid, now);
  if (!me || me.role !== 'coParent') throw new MemoryError('permission-denied', 'not-allowed');
  return me;
}

/** [iso] moved to [date] in [zone], keeping the wall-clock time of day. */
export function onDateInZone(zone: string, iso: Date, date: string): Date {
  const local = new Intl.DateTimeFormat('en-GB', {
    timeZone: zone,
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(iso);
  const part = (t: string) => Number(local.find((p) => p.type === t)?.value ?? 0);
  const { start } = dayBoundsIn(zone, date);
  return new Date(
    start.getTime() + (part('hour') * 3600 + part('minute') * 60 + part('second')) * 1000,
  );
}

// ---------- createMemory (10h, 10a2 "Viết ghi chú") ----------

export async function createMemory(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<CreateMemoryResponse> {
  const parsed = createMemoryRequestSchema.safeParse(data);
  if (!parsed.success) throw new MemoryError('invalid-argument', 'malformed');
  const req = parsed.data;
  const limits = await readLimits(db);
  if (req.items.length > limits.mediaItemsPerAdd) {
    throw new MemoryError('invalid-argument', 'too-many-items');
  }
  if (req.items.some((i) => i.type === 'video' && i.sizeBytes > limits.videoMaxBytes)) {
    throw new MemoryError('invalid-argument', 'video-too-large');
  }
  const memoryRef = db.doc(`babies/${req.babyId}/memories/${req.memoryId}`);

  return db.runTransaction(async (tx) => {
    const me = await requireParent(tx, db, req.babyId, uid, now);
    const baby = await tx.get(db.doc(`babies/${req.babyId}`));
    if (!baby.exists) throw new MemoryError('not-found', 'not-found');
    // Writes are locked while the profile is being deleted (13l, Q-037).
    if (baby.get('state') === 'deleting') throw new MemoryError('failed-precondition', 'deleting');
    const existing = await tx.get(memoryRef);
    const mediaRefs = req.items.map((i) => db.doc(`babies/${req.babyId}/media/${i.mediaId}`));
    const mediaSnaps = mediaRefs.length ? await tx.getAll(...mediaRefs) : [];
    if (existing.exists) {
      // A retried request: answer with what was decided the first time (idempotent).
      if (existing.get('createdBy') !== uid) throw new MemoryError('permission-denied', 'taken');
      return {
        memoryId: req.memoryId,
        reserved: mediaSnaps.filter((s) => s.get('status') === 'uploading').map((s) => s.id),
        waitingQuota: mediaSnaps.filter((s) => s.get('status') === 'waitingQuota').map((s) => s.id),
      };
    }
    if (mediaSnaps.some((s) => s.exists)) throw new MemoryError('invalid-argument', 'taken');
    // 10h5: the albums must exist; a Gia đình album shares what joins it (D-002).
    const albumSnaps = req.albumIds.length
      ? await tx.getAll(...req.albumIds.map((a) => db.doc(`babies/${req.babyId}/albums/${a}`)))
      : [];
    if (albumSnaps.some((a) => !a.exists)) throw new MemoryError('not-found', 'album');
    const albumAudiences = albumSnaps.map((a) => a.get('audience') as Audience);

    const familyId = baby.get('familyId') as string;
    const zone = (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh';
    const familyRef = db.doc(`families/${familyId}`);
    const family = await tx.get(familyRef);
    const quota = (family.get('quotaBytes') as number | undefined) ?? limits.familyQuotaBytes;
    const used = (family.get('usedBytes') as number | undefined) ?? 0;
    const reservedNow = (family.get('reservedBytes') as number | undefined) ?? 0;
    let free = quota - used - reservedNow;

    const author = {
      name: me.displayName,
      relation: me.relation,
      relationCustom: me.relationCustom,
    };
    const captureOf = (i: UploadItem) =>
      req.dateMode === 'single' && req.date
        ? onDateInZone(zone, new Date(i.captureAt), req.date)
        : new Date(i.captureAt);
    const reserved: string[] = [];
    const waiting: string[] = [];
    let reservedTotal = 0;
    const expiresAt = new Date(now.getTime() + memoryLimits.reservationHours * HOUR_MS);

    req.items.forEach((item, index) => {
      const bytes = reservationFor(item);
      const fits = bytes <= free;
      if (fits) {
        free -= bytes;
        reservedTotal += bytes;
        reserved.push(item.mediaId);
        tx.set(db.doc(`families/${familyId}/reservations/${item.mediaId}`), {
          babyId: req.babyId,
          mediaId: item.mediaId,
          bytes,
          state: 'reserved',
          createdAt: now,
          expiresAt,
        });
      } else {
        waiting.push(item.mediaId);
      }
      for (const a of req.albumIds) {
        tx.set(db.doc(`babies/${req.babyId}/albums/${a}/items/${item.mediaId}`), {
          mediaId: item.mediaId,
          addedAt: now,
          addedBy: uid,
        });
      }
      tx.set(mediaRefs[index]!, {
        id: item.mediaId,
        babyId: req.babyId,
        memoryId: req.memoryId,
        batchId: req.batchId,
        familyId,
        position: index,
        type: item.type,
        contentType: item.contentType,
        sizeBytes: item.sizeBytes,
        reservedBytes: fits ? bytes : 0,
        storedBytes: 0,
        hasPoster: item.hasPoster,
        captureAt: captureOf(item),
        durationMs: item.durationMs,
        width: item.width,
        height: item.height,
        audience: req.audience,
        effectiveAudience: effectiveAudience(req.audience, albumAudiences),
        albumIds: req.albumIds,
        milestone: req.milestone,
        status: (fits ? 'uploading' : 'waitingQuota') satisfies MediaStatus,
        clientState: null,
        paths: null,
        createdBy: uid,
        author,
        createdAt: now,
        updatedAt: now,
        readyAt: null,
        deleted: false,
        deletedAt: null,
        deletedBy: null,
      });
    });

    const captures = req.items.map(captureOf).map((d) => d.getTime());
    const occurredAt = captures.length
      ? new Date(Math.min(...captures))
      : req.dateMode === 'single' && req.date
        ? onDateInZone(zone, now, req.date)
        : now;
    const isNote = req.items.length === 0;
    tx.set(memoryRef, {
      id: req.memoryId,
      babyId: req.babyId,
      batchId: req.batchId,
      caption: req.caption && req.caption.length > 0 ? req.caption : null,
      audience: req.audience,
      notifyFamily: req.notifyFamily,
      dateMode: req.dateMode,
      occurredAt,
      milestone: req.milestone,
      mediaIds: req.items.map((i) => i.mediaId),
      counts: { photos: 0, videos: 0 },
      coverMediaId: null,
      state: isNote ? 'published' : 'uploading',
      publishedAt: isNote ? now : null,
      createdBy: uid,
      author,
      createdAt: now,
      updatedAt: now,
      deleted: false,
    });
    tx.set(db.doc(`babies/${req.babyId}/uploadBatches/${req.batchId}`), {
      id: req.batchId,
      babyId: req.babyId,
      memoryId: req.memoryId,
      mediaIds: req.items.map((i) => i.mediaId),
      audience: req.audience,
      notifyFamily: req.notifyFamily,
      createdBy: uid,
      author,
      createdAt: now,
      notifiedAt: null,
      notified: [],
      closed: false,
    });
    if (reservedTotal > 0) {
      tx.update(familyRef, { reservedBytes: FieldValue.increment(reservedTotal) });
    }
    return { memoryId: req.memoryId, reserved, waitingQuota: waiting };
  });
}

// ---------- reserveUploads / cancelUploads (10i, 13d) ----------

export async function reserveUploads(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ reserved: string[]; waitingQuota: string[] }> {
  const parsed = reserveUploadsRequestSchema.safeParse(data);
  if (!parsed.success) throw new MemoryError('invalid-argument', 'malformed');
  const { babyId, mediaIds } = parsed.data;
  return db.runTransaction(async (tx) => {
    await requireParent(tx, db, babyId, uid, now);
    const snaps = await tx.getAll(...mediaIds.map((m) => db.doc(`babies/${babyId}/media/${m}`)));
    const familyId = snaps.find((s) => s.exists)?.get('familyId') as string | undefined;
    if (!familyId) throw new MemoryError('not-found', 'not-found');
    const familyRef = db.doc(`families/${familyId}`);
    const family = await tx.get(familyRef);
    let free =
      ((family.get('quotaBytes') as number) ?? 0) -
      ((family.get('usedBytes') as number) ?? 0) -
      ((family.get('reservedBytes') as number) ?? 0);
    const reserved: string[] = [];
    const waiting: string[] = [];
    let total = 0;
    for (const s of snaps) {
      if (!s.exists || s.get('createdBy') !== uid) continue;
      if (s.get('status') === 'uploading') {
        reserved.push(s.id);
        continue;
      }
      if (s.get('status') !== 'waitingQuota' || s.get('deleted') === true) continue;
      const bytes = reservationFor({
        type: s.get('type') as string,
        sizeBytes: s.get('sizeBytes') as number,
      });
      if (bytes > free) {
        waiting.push(s.id);
        continue;
      }
      free -= bytes;
      total += bytes;
      reserved.push(s.id);
      tx.update(s.ref, {
        status: 'uploading',
        reservedBytes: bytes,
        createdAt: now,
        updatedAt: now,
      });
      tx.set(db.doc(`families/${familyId}/reservations/${s.id}`), {
        babyId,
        mediaId: s.id,
        bytes,
        state: 'reserved',
        createdAt: now,
        expiresAt: new Date(now.getTime() + memoryLimits.reservationHours * HOUR_MS),
      });
    }
    if (total > 0) tx.update(familyRef, { reservedBytes: FieldValue.increment(total) });
    return { reserved, waitingQuota: waiting };
  });
}

/** Releases what an item still holds and moves it to a terminal state. */
function releaseIn(
  tx: Transaction,
  db: Firestore,
  media: DocumentSnapshot,
  status: Extract<MediaStatus, 'cancelled' | 'unreadable'>,
  now: Date,
): void {
  const bytes = (media.get('reservedBytes') as number | undefined) ?? 0;
  const familyId = media.get('familyId') as string;
  if (bytes > 0) {
    tx.update(db.doc(`families/${familyId}`), { reservedBytes: FieldValue.increment(-bytes) });
    tx.set(
      db.doc(`families/${familyId}/reservations/${media.id}`),
      { state: 'released', releasedAt: now },
      { merge: true },
    );
  }
  tx.update(media.ref, { status, reservedBytes: 0, updatedAt: now });
}

export async function cancelUploads(
  db: Firestore,
  store: MediaStore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ cancelled: string[] }> {
  const parsed = cancelUploadsRequestSchema.safeParse(data);
  if (!parsed.success) throw new MemoryError('invalid-argument', 'malformed');
  const { babyId, mediaIds } = parsed.data;
  const cancelled = await db.runTransaction(async (tx) => {
    const me = await activeMember(tx, db, babyId, uid, now);
    if (!me || me.role !== 'coParent') throw new MemoryError('permission-denied', 'not-allowed');
    const snaps = await tx.getAll(...mediaIds.map((m) => db.doc(`babies/${babyId}/media/${m}`)));
    const out: string[] = [];
    for (const s of snaps) {
      if (!s.exists) continue;
      const status = s.get('status') as MediaStatus;
      if (status !== 'uploading' && status !== 'waitingQuota') continue;
      releaseIn(tx, db, s, 'cancelled', now);
      out.push(s.id);
    }
    return out;
  });
  for (const id of cancelled) {
    const p = mediaPaths(babyId, id);
    await store.delete(p.upload);
    await store.delete(p.poster);
  }
  return { cancelled };
}

// ---------- processUpload (Storage finalize) ----------

const photoMax = { original: 4096, display: 1600, thumb: 480, poster: 1280 } as const;

/**
 * Handles an object written under `babies/{b}/uploads/`. The poster of a video is turned into
 * `poster.jpg` + `thumb.jpg`; the item itself is validated by its first bytes, never by the
 * declared type, then photos are re-encoded without metadata (EXIF, GPS — P-033) into
 * `original.jpg`, `display.jpg` and `thumb.jpg`, videos are moved as they are (SP-3 pending).
 */
export async function processUpload(
  db: Firestore,
  store: MediaStore,
  images: ImageOps,
  objectPath: string,
  now: Date,
): Promise<'ready' | 'unreadable' | 'poster' | 'ignored'> {
  const match = /^babies\/([^/]+)\/uploads\/(med_[a-f0-9]{32})(\.poster)?$/.exec(objectPath);
  if (!match) return 'ignored';
  const [, babyId, mediaId, poster] = match as unknown as [string, string, string, string?];
  const ref = db.doc(`babies/${babyId}/media/${mediaId}`);
  const media = await ref.get();
  const paths = mediaPaths(babyId, mediaId);
  if (!media.exists || media.get('status') !== 'uploading' || media.get('deleted') === true) {
    await store.delete(objectPath);
    return 'ignored';
  }

  if (poster) {
    const bytes = await store.read(objectPath);
    await store.delete(objectPath);
    if (!bytes || media.get('type') !== 'video') return 'ignored';
    try {
      const big = await images.jpeg(bytes, photoMax.poster, 80);
      const thumb = await images.jpeg(bytes, photoMax.thumb, 72);
      await store.save(`${paths.dir}/poster.jpg`, big.bytes, 'image/jpeg');
      await store.save(`${paths.dir}/thumb.jpg`, thumb.bytes, 'image/jpeg');
      await ref.update({
        posterBytes: big.bytes.length + thumb.bytes.length,
        width: media.get('width') ?? big.width,
        height: media.get('height') ?? big.height,
        updatedAt: now,
      });
    } catch {
      // A broken poster only costs the frame; the video still plays.
    }
    return 'poster';
  }

  const head = await store.head(objectPath, 64);
  const size = await store.size(objectPath);
  const kind = head ? sniffMedia(head) : null;
  const type = media.get('type') as string;
  const declared = media.get('sizeBytes') as number;
  const tooBig = size === null || size > declared;
  const ok =
    !tooBig &&
    ((type === 'photo' && (kind === 'jpeg' || kind === 'png')) ||
      (type === 'video' && (kind === 'mp4' || kind === 'quicktime')));

  let stored = 0;
  let out: Record<string, unknown> | null = null;
  if (ok && type === 'photo') {
    const bytes = await store.read(objectPath);
    try {
      if (!bytes) throw new Error('missing');
      const original = await images.jpeg(bytes, photoMax.original, 90);
      const display = await images.jpeg(bytes, photoMax.display, 82);
      const thumb = await images.jpeg(bytes, photoMax.thumb, 72);
      await store.save(`${paths.dir}/original.jpg`, original.bytes, 'image/jpeg');
      await store.save(`${paths.dir}/display.jpg`, display.bytes, 'image/jpeg');
      await store.save(`${paths.dir}/thumb.jpg`, thumb.bytes, 'image/jpeg');
      stored = original.bytes.length + display.bytes.length + thumb.bytes.length;
      out = {
        paths: {
          original: `${paths.dir}/original.jpg`,
          display: `${paths.dir}/display.jpg`,
          thumb: `${paths.dir}/thumb.jpg`,
          poster: null,
        },
        width: original.width,
        height: original.height,
        contentType: 'image/jpeg',
      };
    } catch {
      out = null;
    }
  } else if (ok && type === 'video') {
    const ext = kind === 'quicktime' ? 'mov' : 'mp4';
    const contentType = kind === 'quicktime' ? 'video/quicktime' : 'video/mp4';
    await store.move(objectPath, `${paths.dir}/original.${ext}`, contentType);
    const fresh = await ref.get();
    const posterBytes = (fresh.get('posterBytes') as number | undefined) ?? 0;
    stored = (size ?? 0) + posterBytes;
    out = {
      paths: {
        original: `${paths.dir}/original.${ext}`,
        display: null,
        thumb: posterBytes > 0 ? `${paths.dir}/thumb.jpg` : null,
        poster: posterBytes > 0 ? `${paths.dir}/poster.jpg` : null,
      },
      contentType,
    };
  }
  await store.delete(objectPath);

  const result = await db.runTransaction(async (tx) => {
    const fresh = await tx.get(ref);
    if (fresh.get('status') !== 'uploading') return 'ignored' as const;
    if (!out) {
      releaseIn(tx, db, fresh, 'unreadable', now);
      return 'unreadable' as const;
    }
    const familyId = fresh.get('familyId') as string;
    const reserved = (fresh.get('reservedBytes') as number | undefined) ?? 0;
    tx.update(db.doc(`families/${familyId}`), {
      reservedBytes: FieldValue.increment(-reserved),
      usedBytes: FieldValue.increment(stored),
    });
    tx.set(
      db.doc(`families/${familyId}/reservations/${mediaId}`),
      { state: 'committed', committedAt: now, storedBytes: stored },
      { merge: true },
    );
    tx.update(ref, {
      ...out,
      status: 'ready',
      storedBytes: stored,
      reservedBytes: 0,
      clientState: null,
      readyAt: now,
      updatedAt: now,
    });
    return 'ready' as const;
  });
  if (result === 'unreadable') {
    for (const f of ['original.jpg', 'display.jpg', 'thumb.jpg', 'poster.jpg']) {
      await store.delete(`${paths.dir}/${f}`);
    }
  }
  return result;
}

// ---------- Derived state: memory and the batch notification (P-030) ----------

/** Counts, cover, publish state of a memory from its items; idempotent. */
export async function recomputeMemory(
  db: Firestore,
  babyId: string,
  memoryId: string,
  now: Date,
): Promise<void> {
  const ref = db.doc(`babies/${babyId}/memories/${memoryId}`);
  const items = await db
    .collection(`babies/${babyId}/media`)
    .where('memoryId', '==', memoryId)
    .get();
  await db.runTransaction(async (tx) => {
    const memory = await tx.get(ref);
    if (!memory.exists) return;
    const order = (memory.get('mediaIds') as string[] | undefined) ?? [];
    const byId = new Map(items.docs.map((d) => [d.id, d]));
    const live = order
      .map((id) => byId.get(id))
      .filter((d): d is NonNullable<typeof d> => !!d && d.get('deleted') !== true);
    const ready = live.filter((d) => d.get('status') === 'ready');
    const photos = ready.filter((d) => d.get('type') === 'photo').length;
    const videos = ready.length - photos;
    const hadItems = order.length > 0;
    const pendingLeft = live.some((d) =>
      ['uploading', 'waitingQuota'].includes(d.get('status') as string),
    );
    const published = !hadItems || ready.length > 0;
    const deleted =
      hadItems &&
      items.docs.some((d) => d.get('deleted') === true) &&
      ready.length === 0 &&
      !pendingLeft;
    const occurredAt = ready.length
      ? new Date(Math.min(...ready.map((d) => (d.get('captureAt') as Timestamp).toMillis())))
      : (memory.get('occurredAt') as Timestamp).toDate();
    tx.update(ref, {
      counts: { photos, videos },
      coverMediaId: ready[0]?.id ?? null,
      state: published ? 'published' : pendingLeft ? 'uploading' : 'failed',
      publishedAt: memory.get('publishedAt') ?? (published ? now : null),
      occurredAt,
      deleted,
      updatedAt: now,
    });
  });
}

/** Who hears about a Gia đình batch: other Cùng nuôi and relatives, never caregivers (R-118). */
async function familyRecipients(db: Firestore, babyId: string, except: string, now: Date) {
  const members = await db
    .collection(`babies/${babyId}/members`)
    .where('status', '==', 'active')
    .get();
  return members.docs
    .filter((m) => {
      const until = m.get('accessUntilAt') as Timestamp | null | undefined;
      return (
        m.id !== except &&
        ['coParent', 'relative'].includes(m.get('role') as string) &&
        (!until || until.toMillis() > now.getTime())
      );
    })
    .map((m) => ({
      uid: m.id,
      name: (m.get('displayName') as string | undefined) ?? '',
      relation: (m.get('relation') as string | undefined) ?? 'other',
      relationCustom: (m.get('relationCustom') as string | null | undefined) ?? null,
      role: m.get('role') as string,
    }));
}

/**
 * P-030: one generic notification per batch — "Có 7 khoảnh khắc mới / Mai vừa chia sẻ với gia
 * đình" (R-120) — once every item is terminal or only Wi-Fi waits remain. Recorded in
 * `babies/{b}/notifications/{batchId}` (delivery to devices comes with S10); idempotent.
 */
export async function maybeNotifyBatch(
  db: Firestore,
  babyId: string,
  batchId: string,
  now: Date,
): Promise<'notified' | 'skipped' | 'waiting' | 'done'> {
  const batchRef = db.doc(`babies/${babyId}/uploadBatches/${batchId}`);
  const batch = await batchRef.get();
  if (!batch.exists || batch.get('closed') === true) return 'done';
  const items = await db.collection(`babies/${babyId}/media`).where('batchId', '==', batchId).get();
  const states = items.docs.map((d) => ({
    status: d.get('status') as MediaStatus,
    waitingWifi: d.get('clientState') === 'waitingWifi',
  }));
  const everyTerminal = states.every(
    (s) => s.status === 'ready' || s.status === 'unreadable' || s.status === 'cancelled',
  );
  const wantsNotice = batch.get('notifyFamily') === true && batch.get('audience') === 'family';
  if (!wantsNotice) {
    if (everyTerminal) await batchRef.update({ closed: true, closedAt: now });
    return everyTerminal ? 'skipped' : 'waiting';
  }
  if (!batchReadyToNotify(states)) {
    if (everyTerminal) {
      await batchRef.update({ closed: true, closedAt: now });
      return 'skipped';
    }
    return 'waiting';
  }
  const recipients = await familyRecipients(db, babyId, batch.get('createdBy') as string, now);
  const count = states.filter((s) => s.status === 'ready').length;
  return db.runTransaction(async (tx) => {
    const fresh = await tx.get(batchRef);
    if (fresh.get('notifiedAt') || fresh.get('closed') === true) return 'done' as const;
    tx.set(db.doc(`babies/${babyId}/notifications/${batchId}`), {
      kind: 'memories',
      babyId,
      batchId,
      count,
      actor: fresh.get('author'),
      recipients: recipients.map((r) => r.uid),
      createdAt: now,
      delivered: false,
    });
    tx.update(batchRef, {
      notifiedAt: now,
      notified: recipients.filter((r) => r.role === 'relative' || r.role === 'coParent'),
      closed: everyTerminal,
      closedAt: everyTerminal ? now : null,
    });
    return 'notified' as const;
  });
}

/** After any change to an item: its memory and its batch follow (idempotent). */
export async function onMediaWritten(
  db: Firestore,
  babyId: string,
  after: DocumentSnapshot | null,
  before: DocumentSnapshot | null,
  now: Date,
): Promise<void> {
  const doc = after?.exists ? after : before;
  if (!doc?.exists) return;
  await applyUsageDelta(db, before, after);
  const memoryId = doc.get('memoryId') as string | undefined;
  const batchId = doc.get('batchId') as string | undefined;
  if (memoryId) await recomputeMemory(db, babyId, memoryId, now);
  if (batchId && after?.exists) await maybeNotifyBatch(db, babyId, batchId, now);
  // Album counts and covers follow their items (ready, deleted, joined, left).
  const watched = ['status', 'deleted', 'albumIds', 'type'] as const;
  const changed =
    !before?.exists ||
    !after?.exists ||
    watched.some((k) => JSON.stringify(before.get(k)) !== JSON.stringify(after.get(k)));
  if (!changed) return;
  const albums = new Set([
    ...((before?.get('albumIds') as string[] | undefined) ?? []),
    ...((after?.get('albumIds') as string[] | undefined) ?? []),
  ]);
  for (const a of albums) await recomputeAlbum(db, babyId, a, now);
}

// ---------- Storage breakdown (13b, R-042, G-041) ----------

type Usage = { babyId: string; familyId: string; video: boolean; bytes: number; bin: boolean };

/** What one stored item adds to its family's breakdown (ready items only). */
export function usageOf(doc: DocumentSnapshot | null): Usage | null {
  if (!doc?.exists || doc.get('status') !== 'ready') return null;
  const bytes = (doc.get('storedBytes') as number | undefined) ?? 0;
  if (bytes <= 0) return null;
  return {
    babyId: doc.get('babyId') as string,
    familyId: doc.get('familyId') as string,
    video: doc.get('type') === 'video',
    bytes,
    bin: doc.get('deleted') === true,
  };
}

/**
 * Keeps `families/{f}.usage.{babyId}` (photos, videos and their bytes) and `binBytes` in step with
 * item changes. Triggers may repeat, so `reconcileFamilyUsage` rebuilds it from the items daily.
 */
export async function applyUsageDelta(
  db: Firestore,
  before: DocumentSnapshot | null,
  after: DocumentSnapshot | null,
): Promise<void> {
  const a = usageOf(before);
  const b = usageOf(after);
  if (JSON.stringify(a) === JSON.stringify(b)) return;
  const delta: Record<string, number> = {};
  const add = (u: Usage, sign: 1 | -1) => {
    const inc = (key: string, n: number) => (delta[key] = (delta[key] ?? 0) + n);
    if (u.bin) {
      inc('binBytes', sign * u.bytes);
      return;
    }
    const base = `usage.${u.babyId}.${u.video ? 'video' : 'photo'}`;
    inc(`${base}Bytes`, sign * u.bytes);
    inc(`${base}s`, sign);
  };
  if (a) add(a, -1);
  if (b) add(b, 1);
  const patch: Record<string, FieldValue> = {};
  for (const [k, n] of Object.entries(delta)) if (n !== 0) patch[k] = FieldValue.increment(n);
  if (Object.keys(patch).length === 0) return;
  const familyId = (b ?? a)!.familyId;
  const ref = db.doc(`families/${familyId}`);
  if (!(await ref.get()).exists) return;
  await ref.update(patch);
}

/** Rebuilds a family's used, reserved and per-baby bytes from its items (reconciliation). */
export async function reconcileFamilyUsage(db: Firestore, familyId: string): Promise<void> {
  const family = await db.doc(`families/${familyId}`).get();
  if (!family.exists) return;
  const babyIds = (family.get('babyIds') as string[] | undefined) ?? [];
  const usage: Record<string, Record<string, number>> = {};
  let used = 0;
  let reserved = 0;
  let bin = 0;
  for (const babyId of babyIds) {
    const u = { photos: 0, videos: 0, photoBytes: 0, videoBytes: 0 };
    const items = await db
      .collection(`babies/${babyId}/media`)
      .select('status', 'storedBytes', 'reservedBytes', 'type', 'deleted', 'babyId', 'familyId')
      .get();
    for (const d of items.docs) {
      reserved += (d.get('reservedBytes') as number | undefined) ?? 0;
      const c = usageOf(d);
      if (!c) continue;
      used += c.bytes;
      if (c.bin) bin += c.bytes;
      else if (c.video) {
        u.videos++;
        u.videoBytes += c.bytes;
      } else {
        u.photos++;
        u.photoBytes += c.bytes;
      }
    }
    usage[babyId] = u;
  }
  await family.ref.update({
    usage,
    usedBytes: used,
    reservedBytes: reserved,
    binBytes: bin,
    usageReconciledAt: new Date(),
  });
}

// ---------- updateMedia (10b3, 10b4, 10o) ----------

export async function updateMedia(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ updated: string[]; notificationId: string | null }> {
  const parsed = updateMediaRequestSchema.safeParse(data);
  if (!parsed.success) throw new MemoryError('invalid-argument', 'malformed');
  const { babyId, mediaIds, change } = parsed.data;
  const me = await db.runTransaction((tx) => requireParent(tx, db, babyId, uid, now));
  const baby = await db.doc(`babies/${babyId}`).get();
  const zone = (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh';
  const refs = mediaIds.map((m) => db.doc(`babies/${babyId}/media/${m}`));
  const snaps = await db.getAll(...refs);
  const updated: string[] = [];
  const widened: string[] = [];
  let writer = db.batch();
  let pending = 0;
  const flush = async () => {
    if (pending > 0) await writer.commit();
    writer = db.batch();
    pending = 0;
  };
  for (const s of snaps) {
    if (!s.exists) continue;
    const deleted = s.get('deleted') === true;
    let patch: Record<string, unknown> | null = null;
    switch (change.kind) {
      case 'audience':
        // Effective audience (albums included) is recomputed below (D-002, P-035).
        if (!deleted) patch = { audience: change.audience };
        break;
      case 'date': {
        if (deleted) break;
        const at = (s.get('captureAt') as Timestamp).toDate();
        patch = { captureAt: onDateInZone(zone, at, change.date) };
        break;
      }
      case 'milestone':
        if (!deleted) patch = { milestone: change.milestone };
        break;
      case 'delete':
        if (!deleted) patch = { deleted: true, deletedAt: now, deletedBy: uid };
        break;
      case 'restore': {
        const at = (s.get('deletedAt') as Timestamp | null | undefined)?.toMillis() ?? 0;
        if (deleted && now.getTime() - at < memoryLimits.binDays * DAY_MS) {
          patch = { deleted: false, deletedAt: null, deletedBy: null };
        }
        break;
      }
    }
    if (!patch) continue;
    writer.update(s.ref, { ...patch, updatedAt: now, updatedBy: uid });
    updated.push(s.id);
    if (++pending >= 400) await flush();
  }
  await flush();
  if (change.kind === 'audience') {
    widened.push(...(await recomputeEffective(db, babyId, updated, now)));
  }

  // "Chia sẻ với gia đình?" + "Báo cho gia đình": one generic notice, no photos (R-118).
  let notificationId: string | null = null;
  if (change.kind === 'audience' && change.notifyFamily && widened.length > 0) {
    notificationId = await familyNotice(
      db,
      babyId,
      'shared',
      widened.length,
      uid,
      { name: me.displayName, relation: me.relation, relationCustom: me.relationCustom },
      now,
    );
  }
  return { updated, notificationId };
}

// ---------- Jobs ----------

/** "Đã xoá gần đây" ends after 30 days: bytes go, quota comes back (R-111, P-034). */
export async function purgeMediaBin(db: Firestore, store: MediaStore, now: Date): Promise<number> {
  const cutoff = new Date(now.getTime() - memoryLimits.binDays * DAY_MS);
  const snap = await db
    .collectionGroup('media')
    .where('deleted', '==', true)
    .where('deletedAt', '<', cutoff)
    .limit(200)
    .get();
  for (const doc of snap.docs) {
    const p = (doc.get('paths') as Record<string, string | null> | null) ?? {};
    for (const path of Object.values(p)) if (path) await store.delete(path);
    const familyId = doc.get('familyId') as string;
    const stored = (doc.get('storedBytes') as number | undefined) ?? 0;
    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (!fresh.exists) return;
      if (stored > 0) {
        tx.update(db.doc(`families/${familyId}`), { usedBytes: FieldValue.increment(-stored) });
      }
      tx.delete(doc.ref);
    });
  }
  return snap.size;
}

/**
 * Reservations not used within 24 h are released and the items cancelled (P-031). Items waiting
 * for quota hold nothing and stay on the device until space is freed (R-121).
 */
export async function releaseStaleUploads(
  db: Firestore,
  store: MediaStore,
  now: Date,
): Promise<number> {
  const cutoff = new Date(now.getTime() - memoryLimits.reservationHours * HOUR_MS);
  const snap = await db
    .collectionGroup('media')
    .where('status', '==', 'uploading')
    .where('createdAt', '<', cutoff)
    .limit(200)
    .get();
  for (const doc of snap.docs) {
    const babyId = doc.get('babyId') as string;
    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(doc.ref);
      if (fresh.get('status') !== 'uploading') return;
      releaseIn(tx, db, fresh, 'cancelled', now);
    });
    const p = mediaPaths(babyId, doc.id);
    await store.delete(p.upload);
    await store.delete(p.poster);
  }
  return snap.size;
}
