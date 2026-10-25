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

// D-093 "Gửi cho Jun": a stored handover sent to one family member inside the app. The send is
// recorded in `babies/{b}/handoverSends/{id}` (its sender and recipient read it: sent, seen,
// received) and announced through the family notice pipeline (`deliverFamilyNotice`), so the
// push, the inbox row, the "Bàn giao" switch, quiet hours and dedupe are the ones every family
// notice has. The push carries who sent it, never anything about the child.

/** One send per summary and recipient: a second tap returns the first one. */
export function handoverSendId(summaryId: string, recipientUid: string): string {
  return `hs_${createHash('sha256').update(`${summaryId}|${recipientUid}`).digest('hex').slice(0, 32)}`;
}

function parse<T>(schema: { safeParse(d: unknown): { success: boolean; data?: T } }, data: unknown): T {
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

const iso = (v: unknown): string | null => (v instanceof Timestamp ? v.toDate().toISOString() : null);

export interface HandoverSendResult {
  sendId: string;
  sentAt: string;
  /** False when the recipient has no signed-in device or turned "Bàn giao" off: the app says so
   *  and offers the system share sheet instead. */
  pushable: boolean;
}

/**
 * `sendHandover`: the caller (any member who reads care, either direction) sends one ready
 * handover of this baby to another member who reads care.
 */
export async function sendHandover(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<HandoverSendResult> {
  const req = parse(sendHandoverRequestSchema, data);
  if (req.recipientUid === uid) throw new AiSummaryError('invalid-argument', 'self');
  const [sender, recipient, summary] = await Promise.all([
    db.doc(`babies/${req.babyId}/members/${uid}`).get(),
    db.doc(`babies/${req.babyId}/members/${req.recipientUid}`).get(),
    db.doc(`babies/${req.babyId}/summaries/${req.summaryId}`).get(),
  ]);
  if (!isActiveMember(sender, now) || !familyCan(grantOf(sender), 'history.read')) {
    throw new AiSummaryError('permission-denied', 'ROLE_DENIED');
  }
  if (!isActiveMember(recipient, now) || !familyCan(grantOf(recipient), 'history.read')) {
    throw new AiSummaryError('failed-precondition', 'recipient-cannot-read');
  }
  if (
    !summary.exists ||
    summary.get('kind') !== 'handover' ||
    ['pending', 'deleted'].includes(summary.get('status') as string)
  ) {
    throw new AiSummaryError('not-found', 'summary-not-found');
  }

  const sendId = handoverSendId(req.summaryId, req.recipientUid);
  const ref = db.doc(`babies/${req.babyId}/handoverSends/${sendId}`);
  const created = await createOnce(ref, {
    id: sendId,
    babyId: req.babyId,
    summaryId: req.summaryId,
    senderUid: uid,
    recipientUid: req.recipientUid,
    note: req.note ? req.note : null,
    sentAt: Timestamp.fromDate(now),
    seenAt: null,
    receivedAt: null,
  });
  if (created) {
    await createOnce(db.doc(`babies/${req.babyId}/notifications/handover_${sendId}`), {
      kind: 'handoverSent',
      babyId: req.babyId,
      count: 1,
      actor: { name: (sender.get('displayName') as string | undefined) ?? '' },
      actorUid: uid,
      recipients: [req.recipientUid],
      sourceCollection: 'summaries',
      sourceId: req.summaryId,
      createdAt: now,
      delivered: false,
    });
  }
  const sentAt = created ? now.toISOString() : (iso((await ref.get()).get('sentAt')) ?? now.toISOString());

  const [devices, settings] = await Promise.all([
    db.collection(`users/${req.recipientUid}/devices`).get(),
    db.doc(`users/${req.recipientUid}/settings/notifications`).get(),
  ]);
  const hasDevice = devices.docs.some((d) => !!d.get('token') && !d.get('signedOutAt'));
  const on = notificationSettingsOf(settings.data() ?? null).handovers;
  return { sendId, sentAt, pushable: hasDevice && on };
}

/** `markHandover`: the recipient opened it (`seen`) or acknowledged it (`received`); once each. */
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
    const at = Timestamp.fromDate(now);
    const seenAt = (send.get('seenAt') as Timestamp | null) ?? at;
    const receivedAt =
      (send.get('receivedAt') as Timestamp | null) ?? (req.action === 'received' ? at : null);
    tx.update(ref, { seenAt, receivedAt });
    return { seenAt: iso(seenAt), receivedAt: iso(receivedAt) };
  });
}
