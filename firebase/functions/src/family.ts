import { createHash, randomBytes, randomInt } from 'node:crypto';
import {
  acceptInviteRequestSchema,
  claimAnonymousRequestSchema,
  createInviteRequestSchema,
  declineInviteRequestSchema,
  defaultExtraRights,
  inviteEmailMinGapSeconds,
  inviteLookupLockMinutes,
  inviteLookupMaxFailures,
  inviteLookupSchema,
  inviteLookupWindowMinutes,
  inviteMaxEmails,
  inviteRefSchema,
  inviteTtlDays,
  localDateIn,
  removeMemberRequestSchema,
  sendInviteEmailRequestSchema,
  updateMemberRequestSchema,
  type ExtraRights,
  type InviteLookup,
  type ClaimAnonymousResponse,
  type InvitePreview,
  type InviteTicket,
  type MyInvitesResponse,
  chooseWriteSeatsRequestSchema,
  seatAvailable,
  seatRoles,
} from '@child-life/contracts';
import {
  FieldValue,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import { familyPlan } from './premium-v2.js';

export type FamilyErrorCode =
  | 'invalid-argument'
  | 'failed-precondition'
  | 'permission-denied'
  | 'not-found'
  | 'resource-exhausted';

/** `reason` is a stable code mapped to copy by the app (G-001, G-035, G-036). */
export class FamilyError extends Error {
  constructor(
    readonly code: FamilyErrorCode,
    readonly reason: string,
  ) {
    super(reason);
  }
}

/** The caller as the Functions runtime sees it. */
export interface Caller {
  uid: string;
  anonymous: boolean;
  /** Verified email, or a provider that verifies email itself (Google, Apple). D-015. */
  emailTrusted: boolean;
  /**
   * The account's email when trusted, lower-cased: matches invites mailed to it (accept or
   * decline without the code). Null otherwise (anonymous, unverified, Apple's hidden relay is
   * still an address but only matches if the invite was mailed to it).
   */
  email?: string | null;
}

const DAY_MS = 24 * 60 * 60 * 1000;
const sha256 = (value: string) => createHash('sha256').update(value).digest('hex');
const newToken = () => randomBytes(24).toString('base64url');
const newCode = () => String(randomInt(0, 1_000_000)).padStart(6, '0');

const invitesPath = (id: string) => `invites/${id}`;
const pendingPath = (babyId: string, id: string) => `babies/${babyId}/pendingInvites/${id}`;
const memberPath = (babyId: string, uid: string) => `babies/${babyId}/members/${uid}`;

/** An active membership whose access end date (if any) has not passed (R-024, P-005). */
export function isActiveMember(member: DocumentSnapshot, now: Date): boolean {
  if (!member.exists || member.get('status') !== 'active') return false;
  const until = member.get('accessUntilAt') as Timestamp | null | undefined;
  return !until || until.toMillis() > now.getTime();
}

async function requireCoParent(
  db: Firestore,
  babyId: string,
  uid: string,
  now: Date,
  tx?: Transaction,
) {
  const ref = db.doc(memberPath(babyId, uid));
  const member = tx ? await tx.get(ref) : await ref.get();
  if (!isActiveMember(member, now)) throw new FamilyError('permission-denied', 'not-a-member');
  if (member.get('role') !== 'coParent')
    throw new FamilyError('permission-denied', 'not-co-parent');
  return member;
}

const isSeatRole = (role: unknown) => (seatRoles as readonly unknown[]).includes(role);

/**
 * D-101 Q-097: a new writer (Cùng nuôi / Người chăm sóc) needs a free seat in the family.
 * Families already over the limit keep every member; only the next writer is refused, and the
 * app opens E12 → PW05. Pending write invites hold a seat so the limit cannot be oversold.
 * Nothing changes while `premium_v2` is off for the family.
 */
async function requireSeat(
  db: Firestore,
  tx: Transaction,
  familyId: string,
  now: Date,
  options: { joiningUid?: string; exceptInviteId?: string } = {},
): Promise<void> {
  if (await seatsFullFor(db, familyId, now, { ...options, tx }))
    throw new FamilyError('resource-exhausted', 'seats-full');
}

/**
 * Whether a new writer would find no seat: the seat arithmetic of [requireSeat], also used by
 * the invite preview so a joiner learns it before "Tham gia" (D-127 Q3). False while
 * `premium_v2` is off for the family.
 */
async function seatsFullFor(
  db: Firestore,
  familyId: string,
  now: Date,
  options: { joiningUid?: string; exceptInviteId?: string; tx?: Transaction } = {},
): Promise<boolean> {
  const plan = await familyPlan(db, familyId, now);
  if (!plan.v2) return false;
  const { tx } = options;
  const read = <T>(q: FirebaseFirestore.Query<T>) => (tx ? tx.get(q) : q.get());
  const babies = await read(db.collection('babies').where('familyId', '==', familyId));
  const writers = new Set<string>();
  let pending = 0;
  for (const baby of babies.docs) {
    const [members, invites] = await Promise.all([
      read(db.collection(`babies/${baby.id}/members`).where('role', 'in', [...seatRoles])),
      read(db.collection(`babies/${baby.id}/pendingInvites`).where('role', 'in', [...seatRoles])),
    ]);
    for (const m of members.docs) {
      if (isActiveMember(m, now) && m.get('writeSuspended') !== true) writers.add(m.id);
    }
    for (const i of invites.docs) {
      const expires = i.get('expiresAt') as Timestamp | undefined;
      if (i.id !== options.exceptInviteId && (!expires || expires.toMillis() > now.getTime()))
        pending += 1;
    }
  }
  // Someone who already writes for another baby of the family keeps their one seat.
  if (options.joiningUid && writers.has(options.joiningUid)) return false;
  return !seatAvailable(writers.size + pending, plan.limits.caregiverSeats);
}

function audit(tx: Transaction, db: Firestore, entry: Record<string, unknown>, now: Date) {
  tx.create(db.collection('audit').doc(), { ...entry, at: now });
}

/** Creates an invite (14b → 14c): 6-digit code + link token, 7-day expiry (R-032, P-020). */
export async function createInvite(
  db: Firestore,
  caller: Caller,
  data: unknown,
  now: Date,
): Promise<InviteTicket> {
  const parsed = createInviteRequestSchema.safeParse(data);
  if (!parsed.success) throw new FamilyError('invalid-argument', 'malformed');
  const req = parsed.data;
  if (caller.anonymous) throw new FamilyError('permission-denied', 'account-required');
  // D-015 / P-008: invites need a verified email (abuse control).
  if (!caller.emailTrusted) throw new FamilyError('failed-precondition', 'email-unverified');

  const inviteId = `i_${sha256(`${caller.uid}:${req.requestId}`).slice(0, 20)}`;
  return db.runTransaction(async (tx) => {
    const existing = await tx.get(db.doc(invitesPath(inviteId)));
    if (existing.exists) {
      const pending = await tx.get(db.doc(pendingPath(req.babyId, inviteId)));
      if (!pending.exists) throw new FamilyError('failed-precondition', 'invite-closed');
      return {
        inviteId,
        code: pending.get('code') as string,
        token: pending.get('token') as string,
        expiresAt: (pending.get('expiresAt') as Timestamp).toDate().toISOString(),
      };
    }
    const inviter = await requireCoParent(db, req.babyId, caller.uid, now, tx);
    // Q-013 → D-017: only the owner manages co-parents.
    if (req.role === 'coParent' && inviter.get('isOwner') !== true) {
      throw new FamilyError('permission-denied', 'owner-only');
    }
    const baby = await tx.get(db.doc(`babies/${req.babyId}`));
    if (!baby.exists) throw new FamilyError('not-found', 'baby-not-found');
    if (isSeatRole(req.role)) await requireSeat(db, tx, baby.get('familyId') as string, now);

    const code = await freeCode(db, tx, now);
    const token = newToken();
    const expiresAt = new Date(now.getTime() + inviteTtlDays * DAY_MS);
    const extraRights: ExtraRights | null =
      req.role === 'relative' ? (req.extraRights ?? defaultExtraRights) : null;
    const invite = {
      babyId: req.babyId,
      familyId: baby.get('familyId') as string,
      babyNickname: baby.get('nickname') as string,
      inviterUid: caller.uid,
      inviterName: inviter.get('displayName') as string,
      inviterRelation: inviter.get('relation') as string,
      inviterRelationCustom: (inviter.get('relationCustom') as string | null) ?? null,
      relation: req.relation,
      relationCustom: req.relationCustom ?? null,
      role: req.role,
      extraRights,
      code,
      tokenHash: sha256(token),
      status: 'pending',
      recipientEmail: null,
      emailCount: 0,
      lastEmailAt: null,
      createdAt: now,
      expiresAt,
    };
    tx.create(db.doc(invitesPath(inviteId)), invite);
    tx.create(db.doc(`inviteCodes/${code}`), { inviteId, expiresAt });
    tx.create(db.doc(`inviteTokens/${sha256(token)}`), { inviteId });
    // What Cùng nuôi see on 14a ("Đang chờ nhận lời") and need to re-share the invite.
    tx.create(db.doc(pendingPath(req.babyId, inviteId)), {
      inviteId,
      relation: req.relation,
      relationCustom: req.relationCustom ?? null,
      role: req.role,
      extraRights,
      code,
      token,
      recipientEmail: null,
      inviterUid: caller.uid,
      createdAt: now,
      expiresAt,
    });
    return { inviteId, code, token, expiresAt: expiresAt.toISOString() };
  });
}

/** A 6-digit code not used by any live invite (P-020). */
async function freeCode(db: Firestore, tx: Transaction, now: Date): Promise<string> {
  for (let attempt = 0; attempt < 12; attempt += 1) {
    const code = newCode();
    const taken = await tx.get(db.doc(`inviteCodes/${code}`));
    if (!taken.exists || (taken.get('expiresAt') as Timestamp).toMillis() <= now.getTime())
      return code;
  }
  throw new FamilyError('resource-exhausted', 'no-free-code');
}

async function loadInviteForInviter(
  db: Firestore,
  tx: Transaction,
  caller: Caller,
  inviteId: string,
  now: Date,
) {
  const invite = await tx.get(db.doc(invitesPath(inviteId)));
  if (!invite.exists) throw new FamilyError('not-found', 'not-found');
  const inviter = await requireCoParent(db, invite.get('babyId') as string, caller.uid, now, tx);
  if (invite.get('role') === 'coParent' && inviter.get('isOwner') !== true) {
    throw new FamilyError('permission-denied', 'owner-only');
  }
  if (invite.get('status') !== 'pending')
    throw new FamilyError('failed-precondition', 'invite-closed');
  return invite;
}

/** "Tạo mã mới" (14c2): the old code and link stop working; expiry resets to 7 days (P-020). */
export async function regenerateInvite(
  db: Firestore,
  caller: Caller,
  data: unknown,
  now: Date,
): Promise<InviteTicket> {
  const parsed = inviteRefSchema.safeParse(data);
  if (!parsed.success) throw new FamilyError('invalid-argument', 'malformed');
  const { inviteId } = parsed.data;
  return db.runTransaction(async (tx) => {
    const invite = await loadInviteForInviter(db, tx, caller, inviteId, now);
    const babyId = invite.get('babyId') as string;
    const pending = await tx.get(db.doc(pendingPath(babyId, inviteId)));
    const code = await freeCode(db, tx, now);
    const token = newToken();
    const expiresAt = new Date(now.getTime() + inviteTtlDays * DAY_MS);
    tx.delete(db.doc(`inviteCodes/${invite.get('code') as string}`));
    tx.delete(db.doc(`inviteTokens/${invite.get('tokenHash') as string}`));
    tx.update(invite.ref, { code, tokenHash: sha256(token), expiresAt, regeneratedAt: now });
    tx.create(db.doc(`inviteCodes/${code}`), { inviteId, expiresAt });
    tx.create(db.doc(`inviteTokens/${sha256(token)}`), { inviteId });
    if (pending.exists) tx.update(pending.ref, { code, token, expiresAt });
    return { inviteId, code, token, expiresAt: expiresAt.toISOString() };
  });
}

/** Cancels a pending invite (G-033, engineering-supplied). */
export async function revokeInvite(
  db: Firestore,
  caller: Caller,
  data: unknown,
  now: Date,
): Promise<void> {
  const parsed = inviteRefSchema.safeParse(data);
  if (!parsed.success) throw new FamilyError('invalid-argument', 'malformed');
  const { inviteId } = parsed.data;
  await db.runTransaction(async (tx) => {
    const invite = await loadInviteForInviter(db, tx, caller, inviteId, now);
    const babyId = invite.get('babyId') as string;
    tx.update(invite.ref, { status: 'revoked', revokedAt: now, revokedBy: caller.uid });
    tx.delete(db.doc(`inviteCodes/${invite.get('code') as string}`));
    tx.delete(db.doc(`inviteTokens/${invite.get('tokenHash') as string}`));
    tx.delete(db.doc(pendingPath(babyId, inviteId)));
    audit(
      tx,
      db,
      { action: 'invite.revoke', actor: caller.uid, babyId, target: inviteId, category: 'family' },
      now,
    );
  });
}

export const emailHash = (email: string) => sha256(email.trim().toLowerCase());

/** Queues the invite email (14c Email tab, "Gửi lại", "Gửi qua email thay thế") — R-034. */
export async function sendInviteEmail(
  db: Firestore,
  caller: Caller,
  data: unknown,
  now: Date,
): Promise<{ queued: true }> {
  const parsed = sendInviteEmailRequestSchema.safeParse(data);
  if (!parsed.success) throw new FamilyError('invalid-argument', 'malformed');
  const { inviteId, locale } = parsed.data;
  const email = parsed.data.email.trim().toLowerCase();
  if (!caller.emailTrusted) throw new FamilyError('failed-precondition', 'email-unverified');
  await db.runTransaction(async (tx) => {
    const invite = await loadInviteForInviter(db, tx, caller, inviteId, now);
    if ((invite.get('expiresAt') as Timestamp).toMillis() <= now.getTime()) {
      throw new FamilyError('failed-precondition', 'expired');
    }
    const suppressed = await tx.get(db.doc(`emailSuppressions/${emailHash(email)}`));
    if (suppressed.exists) throw new FamilyError('failed-precondition', 'suppressed');
    const count = (invite.get('emailCount') as number | undefined) ?? 0;
    if (count >= inviteMaxEmails) throw new FamilyError('resource-exhausted', 'too-many-emails');
    const last = invite.get('lastEmailAt') as Timestamp | null;
    if (last && now.getTime() - last.toMillis() < inviteEmailMinGapSeconds * 1000) {
      throw new FamilyError('resource-exhausted', 'too-soon');
    }
    const babyId = invite.get('babyId') as string;
    const pending = await tx.get(db.doc(pendingPath(babyId, inviteId)));
    const unsubscribeToken = newToken();
    tx.create(db.collection('mail').doc(), {
      to: email,
      template: 'invite',
      locale,
      data: {
        inviterName: invite.get('inviterName'),
        babyNickname: invite.get('babyNickname'),
        role: invite.get('role'),
        code: invite.get('code'),
        token: pending.exists ? pending.get('token') : null,
        expiresAt: (invite.get('expiresAt') as Timestamp).toDate().toISOString(),
      },
      unsubscribeToken,
      status: 'queued',
      attempts: 0,
      createdAt: now,
    });
    tx.create(db.doc(`emailUnsubscribeTokens/${unsubscribeToken}`), {
      emailHash: emailHash(email),
      createdAt: now,
    });
    tx.update(invite.ref, { recipientEmail: email, emailCount: count + 1, lastEmailAt: now });
    if (pending.exists) tx.update(pending.ref, { recipientEmail: email });
  });
  return { queued: true };
}

// ---------- Redemption (15, 16, 16a, 17) ----------

type LookupResult =
  | { status: 'valid'; invite: DocumentSnapshot }
  | { status: 'expired' | 'revoked' | 'used' | 'not-found' };

async function findInvite(
  db: Firestore,
  lookup: InviteLookup,
  now: Date,
  tx?: Transaction,
): Promise<LookupResult> {
  const get = (path: string) => (tx ? tx.get(db.doc(path)) : db.doc(path).get());
  const index =
    'code' in lookup
      ? await get(`inviteCodes/${lookup.code}`)
      : await get(`inviteTokens/${sha256(lookup.token)}`);
  if (!index.exists) return { status: 'not-found' };
  const invite = await get(invitesPath(index.get('inviteId') as string));
  if (!invite.exists) return { status: 'not-found' };
  const status = invite.get('status') as string;
  if (status === 'accepted') return { status: 'used' };
  // Declined by the invitee: closed for everyone, like a revoked one.
  if (status === 'revoked' || status === 'declined') return { status: 'revoked' };
  if ((invite.get('expiresAt') as Timestamp).toMillis() <= now.getTime())
    return { status: 'expired' };
  return { status: 'valid', invite };
}

/**
 * An invite by id, for its recipient only: the caller's trusted email must be the address it was
 * mailed to (owner, 2026-10-11: accept or decline from the app without the code). Anyone else
 * gets "not-found", as for an unknown code.
 */
async function findMailedInvite(
  db: Firestore,
  caller: Caller,
  inviteId: string,
  now: Date,
  tx?: Transaction,
): Promise<LookupResult> {
  const invite = await (tx
    ? tx.get(db.doc(invitesPath(inviteId)))
    : db.doc(invitesPath(inviteId)).get());
  if (!invite.exists || !mailedTo(invite, caller)) return { status: 'not-found' };
  const status = invite.get('status') as string;
  if (status === 'accepted') return { status: 'used' };
  if (status === 'revoked' || status === 'declined') return { status: 'revoked' };
  if ((invite.get('expiresAt') as Timestamp).toMillis() <= now.getTime())
    return { status: 'expired' };
  return { status: 'valid', invite };
}

const mailedTo = (invite: DocumentSnapshot, caller: Caller) => {
  const to = invite.get('recipientEmail') as string | null;
  return (
    !caller.anonymous &&
    caller.emailTrusted &&
    !!caller.email &&
    !!to &&
    to.trim().toLowerCase() === caller.email.trim().toLowerCase()
  );
};

/** Live invites mailed to the caller's email, for babies they are not in yet. */
export async function listMyInvites(
  db: Firestore,
  caller: Caller,
  now: Date,
): Promise<MyInvitesResponse> {
  if (caller.anonymous || !caller.emailTrusted || !caller.email) return { invites: [] };
  const snap = await db
    .collection('invites')
    .where('recipientEmail', '==', caller.email.trim().toLowerCase())
    .where('status', '==', 'pending')
    .get();
  const invites: MyInvitesResponse['invites'] = [];
  const seen = new Set<string>();
  // Newest first; one per baby (a re-sent invite replaces the older one in the list).
  const live = snap.docs
    .filter((d) => (d.get('expiresAt') as Timestamp).toMillis() > now.getTime())
    .sort(
      (a, b) =>
        (b.get('createdAt') as Timestamp).toMillis() - (a.get('createdAt') as Timestamp).toMillis(),
    );
  for (const invite of live) {
    const babyId = invite.get('babyId') as string;
    if (seen.has(babyId)) continue;
    seen.add(babyId);
    if (isActiveMember(await db.doc(memberPath(babyId, caller.uid)).get(), now)) continue;
    invites.push({
      inviteId: invite.id,
      babyNickname: invite.get('babyNickname') as string,
      inviterName: invite.get('inviterName') as string,
      inviterRelation: invite.get('inviterRelation') as never,
      inviterRelationCustom: (invite.get('inviterRelationCustom') as string | null) ?? null,
      role: invite.get('role') as never,
      relation: invite.get('relation') as never,
      relationCustom: (invite.get('relationCustom') as string | null) ?? null,
      extraRights: (invite.get('extraRights') as ExtraRights | null) ?? null,
      expiresAt: (invite.get('expiresAt') as Timestamp).toDate().toISOString(),
    });
  }
  return { invites };
}

/** "Từ chối" (owner, 2026-10-11): the recipient closes the invite; its code and link stop working. */
export async function declineInvite(
  db: Firestore,
  caller: Caller,
  data: unknown,
  now: Date,
): Promise<void> {
  const parsed = declineInviteRequestSchema.safeParse(data);
  if (!parsed.success) throw new FamilyError('invalid-argument', 'malformed');
  const { inviteId } = parsed.data;
  await db.runTransaction(async (tx) => {
    const found = await findMailedInvite(db, caller, inviteId, now, tx);
    if (found.status !== 'valid') throw new FamilyError('failed-precondition', found.status);
    const invite = found.invite;
    const babyId = invite.get('babyId') as string;
    tx.update(invite.ref, { status: 'declined', declinedAt: now, declinedBy: caller.uid });
    const inviter = invite.get('inviterUid') as string | undefined;
    if (inviter && inviter !== caller.uid)
      membershipNotice(tx, db, babyId, `invite_declined_${inviteId}`, 'inviteDeclined', now, {
        actorUid: caller.uid,
        recipients: [inviter],
      });
    tx.delete(db.doc(`inviteCodes/${invite.get('code') as string}`));
    tx.delete(db.doc(`inviteTokens/${invite.get('tokenHash') as string}`));
    tx.delete(db.doc(pendingPath(babyId, inviteId)));
    audit(
      tx,
      db,
      { action: 'invite.decline', actor: caller.uid, babyId, target: inviteId, category: 'family' },
      now,
    );
  });
}

/** P-021: lockout after repeated unknown codes, per caller and per network address. */
async function lockedFor(db: Firestore, keys: string[], now: Date): Promise<number> {
  let retry = 0;
  for (const key of keys) {
    const doc = await db.doc(`rateLimits/${key}`).get();
    const until = doc.get('lockedUntil') as Timestamp | undefined;
    if (until && until.toMillis() > now.getTime()) {
      retry = Math.max(retry, Math.ceil((until.toMillis() - now.getTime()) / 1000));
    }
  }
  return retry;
}

async function recordFailure(db: Firestore, keys: string[], now: Date): Promise<void> {
  await Promise.all(
    keys.map((key) =>
      db.runTransaction(async (tx) => {
        const ref = db.doc(`rateLimits/${key}`);
        const doc = await tx.get(ref);
        const windowStart = doc.get('windowStart') as Timestamp | undefined;
        const fresh =
          !windowStart ||
          now.getTime() - windowStart.toMillis() > inviteLookupWindowMinutes * 60_000;
        const failures = fresh ? 1 : ((doc.get('failures') as number) ?? 0) + 1;
        tx.set(ref, {
          failures,
          windowStart: fresh ? now : windowStart,
          lockedUntil:
            failures >= inviteLookupMaxFailures
              ? new Date(now.getTime() + inviteLookupLockMinutes * 60_000)
              : null,
          updatedAt: now,
        });
      }),
    ),
  );
}

export function rateKeys(uid: string | null, ip: string | null): string[] {
  return [
    uid ? `invite_uid_${sha256(uid).slice(0, 32)}` : null,
    ip ? `invite_ip_${sha256(ip).slice(0, 32)}` : null,
  ].filter((k): k is string => k !== null);
}

/** 16 "Mẹ Mai mời bạn…" — what the invitee sees before joining. Works signed out. */
export async function previewInvite(
  db: Firestore,
  uid: string | null,
  ip: string | null,
  data: unknown,
  now: Date,
): Promise<InvitePreview> {
  const parsed = inviteLookupSchema.safeParse(data);
  if (!parsed.success) throw new FamilyError('invalid-argument', 'malformed');
  const keys = rateKeys(uid, ip);
  const retry = await lockedFor(db, keys, now);
  if (retry > 0) return { status: 'locked', retryAfterSeconds: retry };
  const found = await findInvite(db, parsed.data, now);
  if (found.status !== 'valid') {
    if (found.status === 'not-found') await recordFailure(db, keys, now);
    return { status: found.status };
  }
  const invite = found.invite;
  const babyId = invite.get('babyId') as string;
  const alreadyMember = uid
    ? isActiveMember(await db.doc(memberPath(babyId, uid)).get(), now)
    : false;
  // D-127 Q3: the joiner learns a full family before "Tham gia" (this invite's own seat is free).
  const seatsFull =
    !alreadyMember &&
    isSeatRole(invite.get('role')) &&
    (await seatsFullFor(db, invite.get('familyId') as string, now, {
      ...(uid ? { joiningUid: uid } : {}),
      exceptInviteId: invite.id,
    }));
  return previewOf(invite, alreadyMember, {
    ...(alreadyMember ? { babyId } : {}),
    seatsFull,
  });
}

function previewOf(
  invite: DocumentSnapshot,
  alreadyMember: boolean,
  extra: { babyId?: string; seatsFull?: boolean } = {},
): InvitePreview {
  return {
    ...extra,
    status: 'valid',
    babyNickname: invite.get('babyNickname') as string,
    inviterName: invite.get('inviterName') as string,
    inviterRelation: invite.get('inviterRelation') as never,
    inviterRelationCustom: (invite.get('inviterRelationCustom') as string | null) ?? null,
    role: invite.get('role') as never,
    relation: invite.get('relation') as never,
    relationCustom: (invite.get('relationCustom') as string | null) ?? null,
    extraRights: (invite.get('extraRights') as ExtraRights | null) ?? null,
    expiresAt: (invite.get('expiresAt') as Timestamp).toDate().toISOString(),
    alreadyMember,
  };
}

/** 16a "Vào xem Teddy": the invitee joins with the invite's role; relation is theirs to fix. */
export async function acceptInvite(
  db: Firestore,
  caller: Caller,
  ip: string | null,
  data: unknown,
  now: Date,
): Promise<{ babyId: string; role: string }> {
  const parsed = acceptInviteRequestSchema.safeParse(data);
  if (!parsed.success) throw new FamilyError('invalid-argument', 'malformed');
  const req = parsed.data;
  const keys = rateKeys(caller.uid, ip);
  if ((await lockedFor(db, keys, now)) > 0) throw new FamilyError('resource-exhausted', 'locked');
  const byId = 'inviteId' in req ? req.inviteId : null;
  const lookup: InviteLookup | null =
    'code' in req ? { code: req.code } : 'token' in req ? { token: req.token } : null;

  const result = await db.runTransaction(async (tx) => {
    const found = lookup
      ? await findInvite(db, lookup, now, tx)
      : await findMailedInvite(db, caller, byId!, now, tx);
    if (found.status !== 'valid') return { failure: found.status };
    const invite = found.invite;
    const babyId = invite.get('babyId') as string;
    const memberRef = db.doc(memberPath(babyId, caller.uid));
    const existing = await tx.get(memberRef);
    if (isActiveMember(existing, now))
      throw new FamilyError('failed-precondition', 'already-member');
    const user = await tx.get(db.doc(`users/${caller.uid}`));
    const parents = await tx.get(
      db.collection(`babies/${babyId}/members`).where('role', '==', 'coParent'),
    );
    if (isSeatRole(invite.get('role'))) {
      await requireSeat(db, tx, invite.get('familyId') as string, now, {
        joiningUid: caller.uid,
        exceptInviteId: invite.id,
      });
    }

    tx.set(memberRef, {
      uid: caller.uid,
      babyId,
      role: invite.get('role'),
      isOwner: false,
      relation: req.relation,
      relationCustom: req.relationCustom ?? null,
      displayName: req.displayName,
      extraRights: invite.get('extraRights') ?? null,
      status: 'active',
      joinedAt: now,
      invitedBy: invite.get('inviterUid'),
      inviteId: invite.id,
      accessUntil: null,
      accessUntilAt: null,
    });
    tx.update(invite.ref, { status: 'accepted', acceptedBy: caller.uid, acceptedAt: now });
    // G-109 (D-092): the co-parents hear that someone joined (delivered by deliverFamilyNotice).
    membershipNotice(tx, db, babyId, `member_joined_${invite.id}`, 'memberJoined', now, {
      actorUid: caller.uid,
      actor: { name: req.displayName },
      recipients: parents.docs
        .filter((p) => isActiveMember(p, now) && p.id !== caller.uid)
        .map((p) => p.id),
    });
    tx.delete(db.doc(`inviteCodes/${invite.get('code') as string}`));
    tx.delete(db.doc(`inviteTokens/${invite.get('tokenHash') as string}`));
    tx.delete(db.doc(pendingPath(babyId, invite.id)));
    tx.set(
      db.doc(`users/${caller.uid}`),
      {
        displayName: req.displayName,
        anonymous: caller.anonymous,
        updatedAt: now,
        ...(user.exists ? {} : { createdAt: now, ownedBabyCount: 0 }),
      },
      { merge: true },
    );
    audit(
      tx,
      db,
      { action: 'invite.accept', actor: caller.uid, babyId, target: invite.id, category: 'family' },
      now,
    );
    return { babyId, role: invite.get('role') as string };
  });
  if ('failure' in result) {
    if (result.failure === 'not-found') await recordFailure(db, keys, now);
    throw new FamilyError('failed-precondition', result.failure);
  }
  return result;
}

/** The web landing `/i/{token}`: preview plus the code to type in the app (token holders only). */
export async function inviteForLanding(
  db: Firestore,
  token: string,
  now: Date,
): Promise<{ preview: InvitePreview; code: string | null }> {
  if (!/^[A-Za-z0-9_-]{32}$/.test(token)) return { preview: { status: 'not-found' }, code: null };
  const found = await findInvite(db, { token }, now);
  if (found.status !== 'valid') return { preview: { status: found.status }, code: null };
  return { preview: previewOf(found.invite, false), code: found.invite.get('code') as string };
}

// ---------- Membership management (14f) ----------

/** End of [date] in [zone], as an instant (access ends after that day, R-024). */
export function endOfDayIn(zone: string, date: string): Date {
  // Find the instant whose local date in `zone` rolls over to the next day.
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  let guess = Date.UTC(y, m - 1, d + 1) - 14 * 3_600_000;
  for (let i = 0; i < 48 && localDateIn(zone, new Date(guess)) <= date; i += 1) guess += 3_600_000;
  for (let i = 0; i < 120 && localDateIn(zone, new Date(guess - 60_000)) > date; i += 1)
    guess -= 60_000;
  return new Date(guess);
}

async function loadTarget(
  db: Firestore,
  tx: Transaction,
  caller: Caller,
  babyId: string,
  uid: string,
  now: Date,
) {
  const actor = await requireCoParent(db, babyId, caller.uid, now, tx);
  if (uid === caller.uid) throw new FamilyError('failed-precondition', 'self');
  const target = await tx.get(db.doc(memberPath(babyId, uid)));
  if (!target.exists || target.get('status') !== 'active')
    throw new FamilyError('not-found', 'not-found');
  // Q-013 → D-017: the owner cannot be changed or removed; only the owner manages co-parents.
  if (target.get('isOwner') === true) throw new FamilyError('permission-denied', 'owner-protected');
  return { actor, target, actorIsOwner: actor.get('isOwner') === true };
}

export async function updateMember(
  db: Firestore,
  caller: Caller,
  data: unknown,
  now: Date,
): Promise<void> {
  const parsed = updateMemberRequestSchema.safeParse(data);
  if (!parsed.success) throw new FamilyError('invalid-argument', 'malformed');
  const req = parsed.data;
  await db.runTransaction(async (tx) => {
    const { target, actorIsOwner } = await loadTarget(db, tx, caller, req.babyId, req.uid, now);
    const fromRole = target.get('role') as string;
    const toRole = req.role ?? fromRole;
    if ((fromRole === 'coParent' || toRole === 'coParent') && !actorIsOwner) {
      throw new FamilyError('permission-denied', 'owner-only');
    }
    if (isSeatRole(toRole) && !isSeatRole(fromRole)) {
      const baby = await tx.get(db.doc(`babies/${req.babyId}`));
      await requireSeat(db, tx, baby.get('familyId') as string, now, { joiningUid: req.uid });
    }
    const update: Record<string, unknown> = { updatedAt: now, updatedBy: caller.uid };
    if (req.role) update.role = req.role;
    const rights = req.extraRights ?? (target.get('extraRights') as ExtraRights | null) ?? null;
    if (toRole === 'relative') {
      const r = rights ?? defaultExtraRights;
      update.extraRights = {
        viewBabyInfo: r.viewBabyInfo,
        viewDailyCare: r.viewDailyCare,
        recordSpending: r.recordSpending ?? false,
        viewSpending: r.viewSpending ?? false,
      } satisfies ExtraRights;
    } else if (toRole === 'caregiver') {
      // D-055 (8l): a Người chăm sóc may carry the two spending rights, nothing else.
      if (req.extraRights?.viewBabyInfo || req.extraRights?.viewDailyCare) {
        throw new FamilyError('invalid-argument', 'extra-rights-relatives-only');
      }
      update.extraRights = {
        viewBabyInfo: false,
        viewDailyCare: false,
        recordSpending: rights?.recordSpending ?? false,
        viewSpending: rights?.viewSpending ?? false,
      } satisfies ExtraRights;
    } else {
      // Cùng nuôi have every right already.
      if (req.extraRights) throw new FamilyError('invalid-argument', 'extra-rights-relatives-only');
      update.extraRights = null;
    }
    if (req.relation) {
      if ((req.relation === 'other') !== (req.relationCustom != null)) {
        throw new FamilyError('invalid-argument', 'malformed');
      }
      update.relation = req.relation;
      update.relationCustom = req.relationCustom ?? null;
    }
    if (req.accessUntil !== undefined) {
      if (req.accessUntil === null) {
        update.accessUntil = null;
        update.accessUntilAt = null;
      } else {
        const baby = await tx.get(db.doc(`babies/${req.babyId}`));
        const zone = (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh';
        if (req.accessUntil < localDateIn(zone, now))
          throw new FamilyError('invalid-argument', 'date-in-past');
        update.accessUntil = req.accessUntil;
        update.accessUntilAt = endOfDayIn(zone, req.accessUntil);
      }
    }
    tx.update(target.ref, update);
    if (toRole !== fromRole)
      membershipNotice(
        tx,
        db,
        req.babyId,
        `role_${req.uid}_${now.getTime().toString(36)}`,
        'roleChanged',
        now,
        { actorUid: caller.uid, recipients: [req.uid] },
      );
    audit(
      tx,
      db,
      {
        action: 'member.update',
        actor: caller.uid,
        babyId: req.babyId,
        target: req.uid,
        before: {
          role: fromRole,
          relation: target.get('relation'),
          accessUntil: target.get('accessUntil') ?? null,
        },
        after: {
          role: toRole,
          relation: update.relation ?? target.get('relation'),
          accessUntil: update.accessUntil ?? target.get('accessUntil') ?? null,
        },
        category: 'family',
      },
      now,
    );
  });
}

/**
 * G-109 (D-092): a membership event becomes a family notice that `deliverFamilyNotice` sends
 * through the notification platform. The id names the event, so a retried transaction writes
 * the same notice; generic copy, no baby name (R-120).
 */
function membershipNotice(
  tx: Transaction,
  db: Firestore,
  babyId: string,
  id: string,
  kind: 'memberJoined' | 'inviteDeclined' | 'roleChanged' | 'memberRemoved',
  now: Date,
  extra: { actorUid: string; actor?: { name: string }; recipients: string[] },
) {
  if (extra.recipients.length === 0) return;
  tx.set(db.doc(`babies/${babyId}/notifications/${id}`), {
    kind,
    babyId,
    count: 1,
    actor: extra.actor ?? null,
    actorUid: extra.actorUid,
    recipients: extra.recipients,
    createdAt: now,
    delivered: false,
  });
}

/**
 * PV44 "Chọn ai giữ quyền ghi" (D-101 Q-101): after a downgrade the manager picks who keeps
 * write access. The others get `writeSuspended` (Rules: view-only), are never removed, and hear
 * once. Until the manager chooses, everyone keeps writing. Choosing again (or with room for all)
 * gives write access back.
 */
export async function chooseWriteSeats(
  db: Firestore,
  caller: Caller,
  data: unknown,
  now: Date,
): Promise<{ suspended: number }> {
  const parsed = chooseWriteSeatsRequestSchema.safeParse(data);
  if (!parsed.success) throw new FamilyError('invalid-argument', 'malformed');
  const req = parsed.data;
  const baby = await db.doc(`babies/${req.babyId}`).get();
  if (!baby.exists) throw new FamilyError('not-found', 'baby-not-found');
  const familyId = baby.get('familyId') as string;
  const plan = await familyPlan(db, familyId, now);
  if (!plan.v2) throw new FamilyError('failed-precondition', 'not-available');
  return db.runTransaction(async (tx) => {
    const family = await tx.get(db.doc(`families/${familyId}`));
    const owner = family.get('ownerUid') as string | undefined;
    if (owner !== caller.uid) throw new FamilyError('permission-denied', 'owner-only');
    const keep = new Set([owner, ...req.keep]);
    if (keep.size > plan.limits.caregiverSeats)
      throw new FamilyError('resource-exhausted', 'seats-full');
    const babies = await tx.get(db.collection('babies').where('familyId', '==', familyId));
    const writers: DocumentSnapshot[] = [];
    for (const b of babies.docs) {
      const members = await tx.get(
        db.collection(`babies/${b.id}/members`).where('role', 'in', [...seatRoles]),
      );
      writers.push(...members.docs.filter((m) => isActiveMember(m, now)));
    }
    const suspended = new Set<string>();
    for (const m of writers) {
      const off = !keep.has(m.id);
      if (off) suspended.add(m.id);
      if ((m.get('writeSuspended') === true) === off) continue;
      tx.update(m.ref, { writeSuspended: off, updatedAt: now, updatedBy: caller.uid });
      if (off)
        membershipNotice(
          tx,
          db,
          m.get('babyId') as string,
          `seat_${m.id}_${now.getTime().toString(36)}`,
          'roleChanged',
          now,
          { actorUid: caller.uid, recipients: [m.id] },
        );
    }
    audit(
      tx,
      db,
      {
        action: 'member.writeSeats',
        actor: caller.uid,
        babyId: req.babyId,
        target: familyId,
        after: { kept: keep.size, suspended: suspended.size },
        category: 'family',
      },
      now,
    );
    return { suspended: suspended.size };
  });
}

/** "Xoá Cô Lan khỏi gia đình" — records are kept (R-023); access ends at once (R-025). */
export async function removeMember(
  db: Firestore,
  caller: Caller,
  data: unknown,
  now: Date,
): Promise<void> {
  const parsed = removeMemberRequestSchema.safeParse(data);
  if (!parsed.success) throw new FamilyError('invalid-argument', 'malformed');
  const { babyId, uid } = parsed.data;
  await db.runTransaction(async (tx) => {
    const { target, actorIsOwner } = await loadTarget(db, tx, caller, babyId, uid, now);
    if (target.get('role') === 'coParent' && !actorIsOwner)
      throw new FamilyError('permission-denied', 'owner-only');
    tx.update(target.ref, { status: 'removed', removedAt: now, removedBy: caller.uid });
    if (uid !== caller.uid)
      membershipNotice(
        tx,
        db,
        babyId,
        `removed_${uid}_${now.getTime().toString(36)}`,
        'memberRemoved',
        now,
        { actorUid: caller.uid, recipients: [uid] },
      );
    audit(
      tx,
      db,
      { action: 'member.remove', actor: caller.uid, babyId, target: uid, category: 'family' },
      now,
    );
  });
}

/** P-005: memberships whose "Thời hạn" has passed become expired (Rules already deny access). */
export async function expireMemberships(db: Firestore, now: Date): Promise<number> {
  const due = await db
    .collectionGroup('members')
    .where('status', '==', 'active')
    .where('accessUntilAt', '<=', now)
    .limit(400)
    .get();
  if (due.empty) return 0;
  const batch = db.batch();
  for (const doc of due.docs) batch.update(doc.ref, { status: 'expired', expiredAt: now });
  await batch.commit();
  return due.size;
}

// ---------- Saving a temporary identity into an existing account (16d, P-007) ----------

export interface TokenVerifier {
  /** Verifies a Firebase ID token and returns its uid and sign-in provider. */
  verify(idToken: string): Promise<{ uid: string; provider: string }>;
  deleteUser(uid: string): Promise<void>;
}

export async function claimAnonymous(
  db: Firestore,
  verifier: TokenVerifier,
  caller: Caller,
  data: unknown,
  now: Date,
): Promise<ClaimAnonymousResponse> {
  const parsed = claimAnonymousRequestSchema.safeParse(data);
  if (!parsed.success) throw new FamilyError('invalid-argument', 'malformed');
  if (caller.anonymous) throw new FamilyError('permission-denied', 'account-required');
  let anon: { uid: string; provider: string };
  try {
    anon = await verifier.verify(parsed.data.anonymousIdToken);
  } catch {
    throw new FamilyError('permission-denied', 'bad-token');
  }
  if (anon.provider !== 'anonymous' || anon.uid === caller.uid)
    throw new FamilyError('permission-denied', 'bad-token');

  const memberships = await db.collectionGroup('members').where('uid', '==', anon.uid).get();
  let moved = 0;
  const babyIds: string[] = [];
  for (const old of memberships.docs) {
    const babyId = old.get('babyId') as string;
    await db.runTransaction(async (tx) => {
      const current = await tx.get(old.ref);
      if (current.get('status') !== 'active') return;
      const mine = await tx.get(db.doc(memberPath(babyId, caller.uid)));
      babyIds.push(babyId);
      if (!isActiveMember(mine, now)) {
        tx.set(mine.ref, {
          ...current.data(),
          uid: caller.uid,
          mergedFrom: anon.uid,
          updatedAt: now,
        });
        moved += 1;
      }
      tx.update(old.ref, { status: 'merged', mergedInto: caller.uid, mergedAt: now });
      audit(
        tx,
        db,
        { action: 'member.merge', actor: caller.uid, babyId, target: anon.uid, category: 'family' },
        now,
      );
    });
  }
  await db.doc(`users/${anon.uid}`).set({ mergedInto: caller.uid, mergedAt: now }, { merge: true });
  await verifier.deleteUser(anon.uid).catch(() => undefined);
  return { moved, babyIds: [...new Set(babyIds)] };
}

export const _test = { sha256, newCode, newToken, FieldValue };
