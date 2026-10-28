import { createHash } from 'node:crypto';
import { Timestamp, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import {
  familyCan,
  markHandoverRequestSchema,
  notificationSettingsOf,
  sendHandoverRequestSchema,
  type MemberGrant,
} from '@child-life/contracts';
import { AiSummaryError } from './ai-summary.js';
import { isActiveMember } from './family.js';
import { createOnce } from './social.js';
import { canTakeDuty, careDutyRef, writeCareDuty } from './care-duty.js';
import { dateKeyIn } from './care-plan.js';

// D-093 "Gửi cho Jun": a stored handover sent to one family member inside the app. The send is
// recorded in `babies/{b}/handoverSends/{id}` (its sender and recipient read it: sent, seen,
// received) and announced through the family notice pipeline (`deliverFamilyNotice`), so the
// push, the inbox row, the "Bàn giao" switch, quiet hours and dedupe are the ones every family
// notice has. The push carries who sent it, never anything about the child.

/** One send per summary and recipient: a second tap returns the first one. */
export function handoverSendId(summaryId: string, recipientUid: string): string {
  return `hs_${createHash('sha256').update(`${summaryId}|${recipientUid}`).digest('hex').slice(0, 32)}`;
}

function parse<T>(
  schema: { safeParse(d: unknown): { success: boolean; data?: T } },
  data: unknown,
): T {
  const r = schema.safeParse(data);
  if (!r.success) throw new AiSummaryError('invalid-argument', 'bad-request');
  return r.data as T;
}

function grantOf(member: DocumentSnapshot): MemberGrant {
  return {
    role: member.get('role'),
    isOwner: member.get('isOwner') === true,
    extraRights: member.get('extraRights') ?? null,
  };
}

const iso = (v: unknown): string | null =>
  v instanceof Timestamp ? v.toDate().toISOString() : null;

export interface HandoverSendResult {
  sendId: string;
  /** Every send this call made (several when a helper sends to the parents). */
  sendIds: string[];
  sentAt: string;
  /** False when no recipient has a signed-in device with "Bàn giao" on: the app says so and
   *  offers the system share sheet instead. */
  pushable: boolean;
}

/** Open tasks of today's plan that are not [uid]'s ("Còn 2 việc chờ bố mẹ"). */
async function openTasksNotOf(
  db: Firestore,
  babyId: string,
  uid: string,
  now: Date,
): Promise<number> {
  const baby = await db.doc(`babies/${babyId}`).get();
  const zone = (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh';
  const items = await db
    .collection(`babies/${babyId}/carePlanDays/${dateKeyIn(zone, now)}/items`)
    .where('status', '==', 'open')
    .get();
  // A draft's tasks are not the family's plan yet (D-136 #3).
  return items.docs.filter(
    (d) =>
      d.get('draft') !== true &&
      !((d.get('assignees') as string[] | undefined) ?? []).includes(uid),
  ).length;
}

async function reachable(db: Firestore, uid: string): Promise<boolean> {
  const [devices, settings] = await Promise.all([
    db.collection(`users/${uid}/devices`).get(),
    db.doc(`users/${uid}/settings/notifications`).get(),
  ]);
  const hasDevice = devices.docs.some((d) => !!d.get('token') && !d.get('signedOutAt'));
  return hasDevice && notificationSettingsOf(settings.data() ?? null).handovers;
}

/**
 * `sendHandover`: the caller (any member who reads care, either direction) sends one ready
 * handover of this baby to another member who reads care, or (a helper, D-135) to every active
 * Cùng nuôi at once: one send each, one family notice ("Cô Lan gửi lời bàn giao cho cả nhà").
 */
export async function sendHandover(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<HandoverSendResult> {
  const req = parse(sendHandoverRequestSchema, data);
  if (req.recipientUid === uid) throw new AiSummaryError('invalid-argument', 'self');
  const [sender, summary] = await Promise.all([
    db.doc(`babies/${req.babyId}/members/${uid}`).get(),
    db.doc(`babies/${req.babyId}/summaries/${req.summaryId}`).get(),
  ]);
  if (!isActiveMember(sender, now) || !familyCan(grantOf(sender), 'history.read')) {
    throw new AiSummaryError('permission-denied', 'ROLE_DENIED');
  }
  if (
    !summary.exists ||
    summary.get('kind') !== 'handover' ||
    ['pending', 'deleted'].includes(summary.get('status') as string)
  ) {
    throw new AiSummaryError('not-found', 'summary-not-found');
  }

  let recipients: string[];
  if (req.toParents) {
    // Only a helper sends "to the parents": Ba and Mẹ are equal and both receive it (Q1).
    if (sender.get('role') !== 'caregiver') {
      throw new AiSummaryError('permission-denied', 'ROLE_DENIED');
    }
    const parents = await db
      .collection(`babies/${req.babyId}/members`)
      .where('role', '==', 'coParent')
      .get();
    recipients = parents.docs
      .filter((m) => m.id !== uid && isActiveMember(m, now))
      .map((m) => m.id)
      .sort();
    if (recipients.length === 0) {
      throw new AiSummaryError('failed-precondition', 'recipient-cannot-read');
    }
  } else {
    const recipient = await db.doc(`babies/${req.babyId}/members/${req.recipientUid}`).get();
    if (!isActiveMember(recipient, now) || !familyCan(grantOf(recipient), 'history.read')) {
      throw new AiSummaryError('failed-precondition', 'recipient-cannot-read');
    }
    recipients = [req.recipientUid!];
  }

  const family = req.toParents === true;
  const openTasks = family ? await openTasksNotOf(db, req.babyId, uid, now) : 0;
  // The helper's shift start, so the parents read "Trong ca" from the same moment (§3.1).
  const duty = family ? await careDutyRef(db, req.babyId).get() : null;
  const shiftSince =
    duty?.get('uid') === uid && duty.get('since') instanceof Timestamp
      ? (duty.get('since') as Timestamp)
      : null;
  const sendIds = recipients.map((r) => handoverSendId(req.summaryId, r));
  const made = await Promise.all(
    recipients.map((recipientUid, i) =>
      createOnce(db.doc(`babies/${req.babyId}/handoverSends/${sendIds[i]}`), {
        id: sendIds[i],
        babyId: req.babyId,
        summaryId: req.summaryId,
        senderUid: uid,
        recipientUid,
        note: req.note ? req.note : null,
        sentAt: Timestamp.fromDate(now),
        seenAt: null,
        receivedAt: null,
        ...(family ? { family: true, receivedBy: null, openTasks, shiftSince } : {}),
      }),
    ),
  );
  const created = made.some((c) => c);
  if (created) {
    await createOnce(
      db.doc(
        `babies/${req.babyId}/notifications/handover_${family ? `family_${req.summaryId}` : sendIds[0]}`,
      ),
      {
        kind: 'handoverSent',
        babyId: req.babyId,
        count: 1,
        actor: { name: (sender.get('displayName') as string | undefined) ?? '' },
        actorUid: uid,
        recipients,
        sourceCollection: 'summaries',
        sourceId: req.summaryId,
        ...(family ? { context: { family: true, openTasks } } : {}),
        createdAt: now,
        delivered: false,
      },
    );
  }
  const sentAt = created
    ? now.toISOString()
    : (iso(
        (await db.doc(`babies/${req.babyId}/handoverSends/${sendIds[0]}`).get()).get('sentAt'),
      ) ?? now.toISOString());
  const pushable = (await Promise.all(recipients.map((r) => reachable(db, r)))).some((p) => p);
  return { sendId: sendIds[0]!, sendIds, sentAt, pushable };
}

/**
 * `markHandover`: the recipient opened it (`seen`) or acknowledged it (`received`); once each.
 * A helper receiving it takes over (P-181). A parent receiving a helper's handover for the
 * family settles it for both parents and ends the helper's shift; parents never take a duty
 * (D-135 Q1).
 */
export async function markHandover(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ seenAt: string | null; receivedAt: string | null }> {
  const req = parse(markHandoverRequestSchema, data);
  const ref = db.doc(`babies/${req.babyId}/handoverSends/${req.sendId}`);
  return db.runTransaction(async (tx) => {
    const send = await tx.get(ref);
    if (!send.exists || send.get('recipientUid') !== uid) {
      throw new AiSummaryError('not-found', 'send-not-found');
    }
    const receiving = req.action === 'received' && !send.get('receivedAt');
    const family = send.get('family') === true;
    const dutyRef = careDutyRef(db, req.babyId);
    const senderUid = send.get('senderUid') as string;
    const [member, duty, siblings] = receiving
      ? await Promise.all([
          tx.get(db.doc(`babies/${req.babyId}/members/${uid}`)),
          tx.get(dutyRef),
          family
            ? tx.get(
                db
                  .collection(`babies/${req.babyId}/handoverSends`)
                  .where('summaryId', '==', send.get('summaryId'))
                  .where('senderUid', '==', senderUid),
              )
            : null,
        ])
      : [null, null, null];
    const at = Timestamp.fromDate(now);
    const seenAt = (send.get('seenAt') as Timestamp | null) ?? at;
    const receivedAt =
      (send.get('receivedAt') as Timestamp | null) ?? (req.action === 'received' ? at : null);
    tx.update(ref, { seenAt, receivedAt, ...(receiving && family ? { receivedBy: uid } : {}) });
    for (const other of siblings?.docs ?? []) {
      if (other.id === ref.id || other.get('receivedAt')) continue;
      tx.update(other.ref, { receivedAt: at, receivedBy: uid });
    }
    if (duty && family) {
      // The helper's shift ends when the family has it, but only the shift this handover closed:
      // receiving an old send must not end a shift the helper started after sending it.
      const since = duty.get('since');
      const sentAt = send.get('sentAt');
      const sameShift =
        !(since instanceof Timestamp) ||
        !(sentAt instanceof Timestamp) ||
        since.toMillis() <= sentAt.toMillis();
      if (sameShift) writeCareDuty(tx, dutyRef, duty, senderUid, 'end', 'handover', now);
    } else if (member && duty && canTakeDuty(member, now)) {
      writeCareDuty(tx, dutyRef, duty, uid, 'take', 'handover', now);
    }
    return { seenAt: iso(seenAt), receivedAt: iso(receivedAt) };
  });
}
