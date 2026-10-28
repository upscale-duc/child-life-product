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
// previousUntil, updatedAt, coCarerUid?}. One carer or a verified parent pair; the family reads it (rules: canReadCare), the
// server writes it. No push: who is on duty shows in the app (owner chose reminders later).

export const careDutyRef = (db: Firestore, babyId: string) =>
  db.doc(`babies/${babyId}/careDuty/current`);

/**
 * Whether this member may be on duty: a helper who logs care (Người chăm sóc). Ba and Mẹ care
 * equally and never take or hold a duty (D-135 Q1, supersedes the parent side of P-181).
 */
export function canTakeDuty(member: DocumentSnapshot, now: Date): boolean {
  if (!isActiveMember(member, now) || member.get('role') !== 'caregiver') return false;
  const grant: MemberGrant = {
    role: member.get('role'),
    isOwner: member.get('isOwner') === true,
    extraRights: member.get('extraRights') ?? null,
  };
  return familyCan(grant, careDutyFamilyAction);
}

interface DutyState {
  uid: string | null;
  coCarerUid: string | null;
  since: Timestamp | null;
}

/** Reads before writes; fresh retries are idempotent, expired shifts can be renewed. */
export function writeCareDuty(
  tx: Transaction,
  ref: DocumentReference,
  current: DocumentSnapshot,
  uid: string,
  action: 'take' | 'end' | 'together',
  via: 'manual' | 'handover',
  now: Date,
  coCarerUid: string | null = null,
): DutyState {
  const old: DutyState = {
    uid: current.get('uid') ?? null,
    coCarerUid: current.get('coCarerUid') ?? null,
    since: current.get('since') instanceof Timestamp ? current.get('since') : null,
  };
  const fresh = old.since !== null && now.getTime() - old.since.toMillis() < 24 * 60 * 60_000;
  const at = Timestamp.fromDate(now);
  let next: DutyState;
  let previousUid = old.uid ?? current.get('previousUid') ?? null;
  let previousCoCarerUid = old.uid ? old.coCarerUid : (current.get('previousCoCarerUid') ?? null);
  let previousUntil = old.uid ? at : (current.get('previousUntil') ?? null);
  if (action === 'end') {
    if (old.uid !== uid && old.coCarerUid !== uid) return old;
    const remaining = old.uid === uid ? old.coCarerUid : old.uid;
    next = { uid: remaining, coCarerUid: null, since: remaining ? old.since : null };
    previousUid = uid;
    previousCoCarerUid = null;
    previousUntil = at;
  } else {
    const joint = action === 'together' ? coCarerUid : null;
    const samePair =
      joint !== null &&
      ((old.uid === uid && old.coCarerUid === joint) ||
        (old.uid === joint && old.coCarerUid === uid));
    if (fresh && (samePair || (joint === null && old.uid === uid && old.coCarerUid === null)))
      return old;
    next = { uid, coCarerUid: joint, since: at };
  }
  tx.set(ref, { ...next, via, previousUid, previousCoCarerUid, previousUntil, updatedAt: at });
  return next;
}

/** Take one's own shift, start a verified parent pair, or end only one's own part. */
export async function setCareDuty(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ uid: string | null; since: string | null; coCarerUid?: string }> {
  const parsed = careDutyRequestSchema.safeParse(data);
  if (!parsed.success) throw new AiSummaryError('invalid-argument', 'bad-request');
  const req = parsed.data;
  const ref = careDutyRef(db, req.babyId);
  return db.runTransaction(async (tx) => {
    const [member, current, coCarer] = await Promise.all([
      tx.get(db.doc(`babies/${req.babyId}/members/${uid}`)),
      tx.get(ref),
      req.coCarerUid ? tx.get(db.doc(`babies/${req.babyId}/members/${req.coCarerUid}`)) : null,
    ]);
    if (!canTakeDuty(member, now)) throw new AiSummaryError('permission-denied', 'not-a-carer');
    if (req.action === 'together') {
      const a = member.get('relation');
      const b = coCarer?.get('relation');
      if (
        !coCarer ||
        req.coCarerUid === uid ||
        !canTakeDuty(coCarer, now) ||
        !((a === 'mother' && b === 'father') || (a === 'father' && b === 'mother'))
      ) {
        throw new AiSummaryError('permission-denied', 'not-a-parent-pair');
      }
    }
    const next = writeCareDuty(
      tx,
      ref,
      current,
      uid,
      req.action,
      'manual',
      now,
      req.coCarerUid ?? null,
    );
    return {
      uid: next.uid,
      since: next.uid ? (next.since?.toDate().toISOString() ?? null) : null,
      ...(next.coCarerUid ? { coCarerUid: next.coCarerUid } : {}),
    };
  });
}
