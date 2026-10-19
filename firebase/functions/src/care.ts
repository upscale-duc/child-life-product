import type { DocumentSnapshot, Firestore, Timestamp } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import {
  conflictIdOf,
  datesTouched,
  dayBoundsIn,
  resolveConflictRequestSchema,
  spansOverlap,
  summarizeDay,
  type CareType,
  type SummaryRecord,
} from '@child-life/contracts';

/**
 * Care records (S4). The app writes records itself (Rules validate); the server derives:
 * - `babies/{b}/days/{date}` — "Đã ghi hôm nay" per baby-local date, recomputed from scratch
 *   for every day a write touches, so retries and out-of-order triggers converge (idempotent);
 * - `members/{uid}.recordCount` — "đã ghi 46 lần" on 14f (R-038);
 * - the 30-day bin: soft-deleted records are purged after 30 days (P-009, "Đã xoá gần đây"), and
 *   so are soft-deleted Ăn dặm meals (D-085, P-164 #4) and family recipes ("Công thức nhà mình",
 *   D-086), each with its photo.
 * Care payloads are never logged.
 */

export const binDays = 30;
const DAY_MS = 86_400_000;
/** Longest span a record can have that still touches a day (overnight sleep, S5). */
const maxSpanMs = DAY_MS;

function toSummaryRecord(doc: DocumentSnapshot): SummaryRecord | null {
  const d = doc.data();
  if (!d || d.deleted === true) return null;
  const occurredAt = (d.occurredAt as Timestamp | undefined)?.toDate();
  if (!occurredAt) return null;
  return {
    type: d.type as CareType,
    occurredAt,
    endedAt: (d.endedAt as Timestamp | null | undefined)?.toDate() ?? null,
    data: (d.data as Record<string, unknown> | undefined) ?? {},
  };
}

async function babyZone(db: Firestore, babyId: string): Promise<string> {
  const baby = await db.doc(`babies/${babyId}`).get();
  return (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh';
}

/** Recomputes the summaries of every local day touched by the record before and after. */
export async function onRecordWritten(
  db: Firestore,
  babyId: string,
  before: DocumentSnapshot | null,
  after: DocumentSnapshot | null,
  now: Date,
): Promise<{ days: string[]; conflicts: string[] }> {
  const zone = await babyZone(db, babyId);
  const dates = new Set<string>();
  for (const snap of [before, after]) {
    if (!snap?.exists) continue;
    const occurredAt = (snap.get('occurredAt') as Timestamp | undefined)?.toDate();
    if (!occurredAt) continue;
    const endedAt = (snap.get('endedAt') as Timestamp | null | undefined)?.toDate() ?? null;
    for (const date of datesTouched(zone, { occurredAt, endedAt })) dates.add(date);
  }
  for (const date of dates) await recomputeDay(db, babyId, zone, date, now);

  const authors = new Set<string>();
  for (const snap of [before, after]) {
    const uid = snap?.exists ? (snap.get('createdBy') as string | undefined) : undefined;
    if (uid) authors.add(uid);
  }
  for (const uid of authors) await recountMember(db, babyId, uid, now);

  const recordId = (after ?? before)?.id;
  let conflicts: string[] = [];
  if (recordId && (after ?? before)?.get('type') === 'sleep') {
    conflicts = await checkSleepOverlaps(db, babyId, recordId, after?.exists ? after : null, now);
  }
  return { days: [...dates].sort(), conflicts };
}

// ---------- Overlapping sleeps (27, R-075) ----------

function spanOf(doc: DocumentSnapshot): { start: Date; end: Date } | null {
  if (!doc.exists || doc.get('deleted') === true || doc.get('type') !== 'sleep') return null;
  const start = (doc.get('occurredAt') as Timestamp | undefined)?.toDate();
  const end = (doc.get('endedAt') as Timestamp | null | undefined)?.toDate();
  return start && end ? { start, end } : null;
}

/**
 * Opens a conflict for every live sleep that overlaps [after] ("Chỉ hiện khi đồng bộ phát hiện
 * 2 giấc ngủ chồng thời gian") and closes open conflicts that no longer hold (a record was
 * deleted or moved). Never merges or overwrites ("App không tự gộp hay ghi đè").
 */
export async function checkSleepOverlaps(
  db: Firestore,
  babyId: string,
  recordId: string,
  after: DocumentSnapshot | null,
  now: Date,
): Promise<string[]> {
  const conflicts = db.collection(`babies/${babyId}/conflicts`);
  const opened: string[] = [];
  const span = after ? spanOf(after) : null;
  if (after && span) {
    const candidates = await db
      .collection(`babies/${babyId}/records`)
      .where('type', '==', 'sleep')
      .where('deleted', '==', false)
      .where('occurredAt', '>=', new Date(span.start.getTime() - maxSpanMs))
      .where('occurredAt', '<', span.end)
      .get();
    for (const other of candidates.docs) {
      if (other.id === recordId) continue;
      const otherSpan = spanOf(other);
      if (!otherSpan || !spansOverlap(span, otherSpan)) continue;
      const id = conflictIdOf(recordId, other.id);
      const created = (d: DocumentSnapshot) =>
        (d.get('createdAt') as Timestamp | undefined)?.toMillis() ?? 0;
      const later = created(after) >= created(other) ? after : other;
      await db.runTransaction(async (tx) => {
        const ref = conflicts.doc(id);
        const existing = await tx.get(ref);
        if (existing.exists && existing.get('status') === 'open') return;
        tx.set(ref, {
          babyId,
          recordIds: [recordId, other.id].sort(),
          status: 'open',
          // The device that synced last is shown 27 (business map §9).
          laterAuthor: later.get('createdBy') ?? null,
          detectedAt: now,
          resolvedAt: null,
          resolvedBy: null,
          keptRecordId: null,
        });
      });
      opened.push(id);
    }
  }
  // Close what no longer overlaps.
  const open = await conflicts
    .where('recordIds', 'array-contains', recordId)
    .where('status', '==', 'open')
    .get();
  for (const conflict of open.docs) {
    if (opened.includes(conflict.id)) continue;
    const [a, b] = conflict.get('recordIds') as [string, string];
    const [da, dbDoc] = await Promise.all([
      db.doc(`babies/${babyId}/records/${a}`).get(),
      db.doc(`babies/${babyId}/records/${b}`).get(),
    ]);
    const sa = spanOf(da);
    const sb = spanOf(dbDoc);
    if (!sa || !sb || !spansOverlap(sa, sb)) {
      await conflict.ref.update({ status: 'resolved', resolvedAt: now, resolvedBy: null });
    }
  }
  return opened;
}

export class CareError extends Error {
  constructor(
    readonly code: 'invalid-argument' | 'permission-denied' | 'not-found' | 'failed-precondition',
    readonly reason: string,
  ) {
    super(reason);
  }
}

/**
 * "Giữ bản đã chọn": keeps one sleep and moves the other to the 30-day bin (P-013). Allowed
 * for Cùng nuôi, or for the author of the sleep that goes (D-022).
 */
export async function resolveSleepConflict(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ removedRecordId: string }> {
  const parsed = resolveConflictRequestSchema.safeParse(data);
  if (!parsed.success) throw new CareError('invalid-argument', 'malformed');
  const { babyId, conflictId, keepRecordId } = parsed.data;
  return db.runTransaction(async (tx) => {
    const conflict = await tx.get(db.doc(`babies/${babyId}/conflicts/${conflictId}`));
    if (!conflict.exists) throw new CareError('not-found', 'not-found');
    const ids = conflict.get('recordIds') as string[];
    if (!ids.includes(keepRecordId)) throw new CareError('invalid-argument', 'malformed');
    const loserId = ids.find((id) => id !== keepRecordId) as string;
    const member = await tx.get(db.doc(`babies/${babyId}/members/${uid}`));
    const until = member.get('accessUntilAt') as Timestamp | null | undefined;
    const active =
      member.exists &&
      member.get('status') === 'active' &&
      (!until || until.toMillis() > now.getTime());
    const role = member.get('role') as string | undefined;
    if (!active || (role !== 'coParent' && role !== 'caregiver')) {
      throw new CareError('permission-denied', 'not-allowed');
    }
    const loser = await tx.get(db.doc(`babies/${babyId}/records/${loserId}`));
    if (conflict.get('status') !== 'open') {
      return { removedRecordId: loserId };
    }
    if (role !== 'coParent' && loser.get('createdBy') !== uid) {
      throw new CareError('permission-denied', 'not-allowed');
    }
    if (loser.exists && loser.get('deleted') !== true) {
      tx.update(loser.ref, {
        deleted: true,
        deletedAt: now,
        deletedBy: uid,
        deletedReason: 'overlap',
        updatedAt: now,
        updatedBy: uid,
      });
    }
    tx.update(conflict.ref, {
      status: 'resolved',
      resolvedAt: now,
      resolvedBy: uid,
      keptRecordId: keepRecordId,
    });
    return { removedRecordId: loserId };
  });
}

export async function recomputeDay(
  db: Firestore,
  babyId: string,
  zone: string,
  date: string,
  now: Date,
): Promise<void> {
  const { start, end } = dayBoundsIn(zone, date);
  const snap = await db
    .collection(`babies/${babyId}/records`)
    .where('occurredAt', '>=', new Date(start.getTime() - maxSpanMs))
    .where('occurredAt', '<', end)
    .get();
  const records = snap.docs.map(toSummaryRecord).filter((r): r is SummaryRecord => r !== null);
  await db
    .doc(`babies/${babyId}/days/${date}`)
    .set({ ...summarizeDay(zone, date, records), babyId, updatedAt: now });
}

/** "đã ghi N lần": the member's live (not deleted) records on this baby. */
export async function recountMember(
  db: Firestore,
  babyId: string,
  uid: string,
  now: Date,
): Promise<void> {
  const count = await db
    .collection(`babies/${babyId}/records`)
    .where('createdBy', '==', uid)
    .where('deleted', '==', false)
    .count()
    .get();
  const member = db.doc(`babies/${babyId}/members/${uid}`);
  if (!(await member.get()).exists) return;
  await member.update({ recordCount: count.data().count, recordCountAt: now });
}

/** Removes one Storage object (a purged meal's or recipe's photo); a missing object is fine. */
export interface BinPhotoStore {
  delete(path: string): Promise<void>;
}

/** The default bucket, opened only when a purged meal or recipe has a photo. */
const bucketPhotos: BinPhotoStore = {
  async delete(path) {
    await getStorage().bucket().file(path).delete({ ignoreNotFound: true });
  },
};

/** Photo names as Rules allow them, per bin group with photos (meals, family recipes). */
const photoNames = {
  meals: /^babies\/[^/]+\/meals\/[A-Za-z0-9_-]{8,64}\.jpg$/,
  recipes: /^babies\/[^/]+\/recipes\/[A-Za-z0-9_-]{8,64}\.jpg$/,
};

/**
 * The document's own photo (`babies/{babyId}/{group}/{file}.jpg`), else null: a path elsewhere
 * (another baby, another folder) is never deleted from Storage.
 */
function ownPhotoPath(doc: DocumentSnapshot, group: keyof typeof photoNames): string | null {
  const path = doc.get('photoPath') as unknown;
  const babyId = doc.ref.parent.parent?.id;
  if (typeof path !== 'string' || !babyId) return null;
  return path.startsWith(`babies/${babyId}/${group}/`) && photoNames[group].test(path)
    ? path
    : null;
}

/** Only family recipes (`babies/{babyId}/recipes/{id}`) are purged from the `recipes` group. */
const isBabyDoc = (doc: DocumentSnapshot) => doc.ref.parent.parent?.parent.id === 'babies';

/**
 * Hard-deletes care records, Ăn dặm meals and family recipes that have been in the bin for 30
 * days; a meal's or recipe's photo goes first, so a failure leaves the document to retry the next
 * day. Returns how many documents.
 */
export async function purgeDeletedRecords(
  db: Firestore,
  now: Date,
  photos: BinPhotoStore = bucketPhotos,
): Promise<number> {
  const cutoff = new Date(now.getTime() - binDays * DAY_MS);
  let purged = 0;
  for (const group of ['records', 'meals', 'recipes'] as const) {
    const snap = await db
      .collectionGroup(group)
      .where('deleted', '==', true)
      .where('deletedAt', '<=', cutoff)
      .limit(400)
      .get();
    const due = group === 'recipes' ? snap.docs.filter(isBabyDoc) : snap.docs;
    if (due.length === 0) continue;
    if (group !== 'records') {
      for (const doc of due) {
        const path = ownPhotoPath(doc, group);
        if (path) await photos.delete(path);
      }
    }
    const batch = db.batch();
    for (const doc of due) batch.delete(doc.ref);
    await batch.commit();
    purged += due.length;
  }
  return purged;
}
