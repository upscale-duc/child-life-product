import type { DocumentSnapshot, Firestore, Timestamp } from 'firebase-admin/firestore';
import {
  datesTouched,
  dayBoundsIn,
  summarizeDay,
  type CareType,
  type SummaryRecord,
} from '@child-life/contracts';

/**
 * Care records (S4). The app writes records itself (Rules validate); the server derives:
 * - `babies/{b}/days/{date}` — "Đã ghi hôm nay" per baby-local date, recomputed from scratch
 *   for every day a write touches, so retries and out-of-order triggers converge (idempotent);
 * - `members/{uid}.recordCount` — "đã ghi 46 lần" on 14f (R-038);
 * - the 30-day bin: soft-deleted records are purged after 30 days (P-009, "Đã xoá gần đây").
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
): Promise<{ days: string[] }> {
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
  return { days: [...dates].sort() };
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

/** Hard-deletes records that have been in the bin for 30 days. Returns how many. */
export async function purgeDeletedRecords(db: Firestore, now: Date): Promise<number> {
  const cutoff = new Date(now.getTime() - binDays * DAY_MS);
  const due = await db
    .collectionGroup('records')
    .where('deleted', '==', true)
    .where('deletedAt', '<=', cutoff)
    .limit(400)
    .get();
  if (due.empty) return 0;
  const batch = db.batch();
  for (const doc of due.docs) batch.delete(doc.ref);
  await batch.commit();
  return due.size;
}
