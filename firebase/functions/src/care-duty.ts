import {
  Timestamp,
  type DocumentReference,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import {
  careDutyFamilyAction,
  careDutyRequestSchema,
  familyCan,
  type MemberGrant,
} from '@child-life/contracts';
import { AiSummaryError } from './ai-summary.js';
import { isActiveMember } from './family.js';

// P-181 "Ai đang trông bé": `babies/{b}/careDuty/current` = {uid, since, via, previousUid,
// previousUntil, updatedAt}. One person per baby; the family reads it (rules: canReadCare), the
// server writes it. No push: who is on duty shows in the app (owner chose reminders later).

export const careDutyRef = (db: Firestore, babyId: string) =>
  db.doc(`babies/${babyId}/careDuty/current`);

/** Whether this member may be on duty (logs care: Cùng nuôi, Người chăm sóc). */
export function canTakeDuty(member: DocumentSnapshot, now: Date): boolean {
  if (!isActiveMember(member, now)) return false;
  const grant: MemberGrant = {
    role: member.get('role'),
    isOwner: member.get('isOwner') === true,
    extraRights: member.get('extraRights') ?? null,
  };
  return familyCan(grant, careDutyFamilyAction);
}

/**
 * Writes a take or an end into a transaction, from a [current] already read in it (reads come
 * first in a transaction). Taking it again changes nothing; ending is only one's own.
 */
export function writeCareDuty(
  tx: Transaction,
  ref: DocumentReference,
  current: DocumentSnapshot,
  uid: string,
  action: 'take' | 'end',
  via: 'manual' | 'handover',
  now: Date,
): boolean {
  const on = (current.get('uid') as string | null | undefined) ?? null;
  const at = Timestamp.fromDate(now);
  if (action === 'take') {
    if (on === uid) return false;
    tx.set(ref, {
      uid,
      since: at,
      via,
      previousUid: on ?? current.get('previousUid') ?? null,
      previousUntil: on ? at : (current.get('previousUntil') ?? null),
      updatedAt: at,
    });
    return true;
  }
  if (on !== uid) return false;
  tx.set(ref, {
    uid: null,
    since: null,
    via,
    previousUid: uid,
    previousUntil: at,
    updatedAt: at,
  });
  return true;
}

/** `setCareDuty`: "Tôi trông bé" (take) or "Kết thúc ca của tôi" (end). */
export async function setCareDuty(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ uid: string | null; since: string | null }> {
  const parsed = careDutyRequestSchema.safeParse(data);
  if (!parsed.success) throw new AiSummaryError('invalid-argument', 'bad-request');
  const req = parsed.data;
  const ref = careDutyRef(db, req.babyId);
  return db.runTransaction(async (tx) => {
    const [member, current] = await Promise.all([
      tx.get(db.doc(`babies/${req.babyId}/members/${uid}`)),
      tx.get(ref),
    ]);
    if (!canTakeDuty(member, now)) throw new AiSummaryError('permission-denied', 'not-a-carer');
    writeCareDuty(tx, ref, current, uid, req.action, 'manual', now);
    const on = req.action === 'take' ? uid : null;
    return {
      uid: on ?? (current.get('uid') === uid ? null : ((current.get('uid') as string) ?? null)),
      since: on ? now.toISOString() : null,
    };
  });
}
