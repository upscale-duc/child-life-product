import { createHash } from 'node:crypto';
import {
  babyAvatarPath,
  createBabyRequestSchema,
  getBabyAvatarRequestSchema,
  localDateIn,
  maxAvatarBytes,
  maxBabyAgeYears,
  maxOwnedBabies,
  setBabyAvatarRequestSchema,
  type BabyAvatar,
  type CreateBabyRequest,
  type CreateBabyResponse,
} from '@child-life/contracts';
import { FieldValue, type Firestore } from 'firebase-admin/firestore';

/** Minimal Storage surface used here (Admin SDK bucket in production, a fake in unit tests). */
export interface AvatarStore {
  save(path: string, bytes: Buffer): Promise<void>;
  read(path: string): Promise<Buffer | null>;
  delete(path: string): Promise<void>;
}

export type BabyErrorCode =
  | 'invalid-argument'
  | 'failed-precondition'
  | 'permission-denied'
  | 'not-found';

/** `reason` is a stable machine code the app maps to copy (never shown raw). */
export class BabyError extends Error {
  constructor(
    readonly code: BabyErrorCode,
    readonly reason: string,
  ) {
    super(reason);
  }
}

/** Deterministic id per (account, request) so a retried createBaby never makes a second baby. */
export function babyIdFor(uid: string, requestId: string): string {
  return `b_${createHash('sha256').update(`${uid}:${requestId}`).digest('hex').slice(0, 20)}`;
}

/** Validates the request, including the date of birth against "today" in the baby's own zone. */
export function parseCreateBaby(data: unknown, now: Date): CreateBabyRequest {
  const parsed = createBabyRequestSchema.safeParse(data);
  if (!parsed.success) throw new BabyError('invalid-argument', 'malformed');
  const request = parsed.data;
  const today = localDateIn(request.timeZone.zone, now);
  // DateWheel: "default = today, cannot pick a future date" (R-009).
  if (request.dateOfBirth > today) throw new BabyError('invalid-argument', 'dob-in-future');
  const oldest = `${Number(today.slice(0, 4)) - maxBabyAgeYears}${today.slice(4)}`;
  if (request.dateOfBirth < oldest) throw new BabyError('invalid-argument', 'dob-too-old');
  return request;
}

/**
 * Creates a baby, its restricted profile and the creator's owner membership in one transaction.
 * The first baby also creates the account's family (P-001, pending Q-011); every baby counts
 * toward the 3-profile cap (R-043), which the transaction enforces even for concurrent calls.
 */
export async function createBaby(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
  familyQuotaBytes: number,
): Promise<CreateBabyResponse> {
  const request = parseCreateBaby(data, now);
  const babyId = babyIdFor(uid, request.requestId);

  return db.runTransaction(async (tx) => {
    const userRef = db.doc(`users/${uid}`);
    const babyRef = db.doc(`babies/${babyId}`);
    const user = await tx.get(userRef);
    const existing = await tx.get(babyRef);

    if (existing.exists) {
      if (existing.get('ownerUid') !== uid) throw new BabyError('permission-denied', 'not-owner');
      return { babyId, familyId: existing.get('familyId') as string, created: false };
    }

    const owned = (user.get('ownedBabyCount') as number | undefined) ?? 0;
    if (owned >= maxOwnedBabies) throw new BabyError('failed-precondition', 'baby-limit');

    let familyId = user.get('ownedFamilyId') as string | undefined;
    if (familyId) {
      tx.update(db.doc(`families/${familyId}`), {
        babyIds: FieldValue.arrayUnion(babyId),
        updatedAt: now,
      });
    } else {
      familyId = db.collection('families').doc().id;
      tx.create(db.doc(`families/${familyId}`), {
        ownerUid: uid,
        quotaBytes: familyQuotaBytes,
        usedBytes: 0,
        reservedBytes: 0,
        babyIds: [babyId],
        createdAt: now,
        updatedAt: now,
        schemaVersion: 1,
      });
    }

    tx.create(babyRef, {
      familyId,
      ownerUid: uid,
      nickname: request.nickname,
      avatar: { kind: 'preset', preset: request.avatarPreset } satisfies BabyAvatar,
      trackers: request.trackers,
      timeZone: request.timeZone,
      state: 'active',
      createdAt: now,
      updatedAt: now,
      schemaVersion: 1,
    });
    // DOB and gender are not visible to caregivers or to relatives without viewBabyInfo (§5).
    tx.create(babyRef.collection('restricted').doc('profile'), {
      dateOfBirth: request.dateOfBirth,
      gender: request.gender,
      updatedAt: now,
    });
    tx.create(babyRef.collection('members').doc(uid), {
      uid,
      babyId,
      role: 'coParent',
      isOwner: true,
      relation: request.self.relation,
      relationCustom: request.self.relationCustom ?? null,
      displayName: request.self.displayName,
      status: 'active',
      joinedAt: now,
      invitedBy: null,
    });
    tx.set(
      userRef,
      {
        displayName: request.self.displayName,
        ownedFamilyId: familyId,
        ownedBabyCount: owned + 1,
        updatedAt: now,
        ...(user.exists ? {} : { createdAt: now }),
      },
      { merge: true },
    );
    return { babyId, familyId, created: true };
  });
}

async function activeMembership(db: Firestore, babyId: string, uid: string) {
  const member = await db.doc(`babies/${babyId}/members/${uid}`).get();
  if (!member.exists || member.get('status') !== 'active') {
    throw new BabyError('permission-denied', 'not-a-member');
  }
  return member;
}

const isJpeg = (bytes: Buffer) =>
  bytes.length > 4 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;

/** Sets a preset or a new photo (Cùng nuôi only — "Edit baby profile", §5). Returns the avatar. */
export async function setBabyAvatar(
  db: Firestore,
  store: AvatarStore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<BabyAvatar> {
  const parsed = setBabyAvatarRequestSchema.safeParse(data);
  if (!parsed.success) throw new BabyError('invalid-argument', 'malformed');
  const { babyId, avatar } = parsed.data;

  const member = await activeMembership(db, babyId, uid);
  if (member.get('role') !== 'coParent') throw new BabyError('permission-denied', 'not-co-parent');

  const babyRef = db.doc(`babies/${babyId}`);
  const before = (await babyRef.get()).get('avatar') as BabyAvatar | undefined;

  let next: BabyAvatar;
  if (avatar.kind === 'preset') {
    next = { kind: 'preset', preset: avatar.preset };
  } else {
    const bytes = Buffer.from(avatar.jpegBase64, 'base64');
    if (bytes.length > maxAvatarBytes) throw new BabyError('invalid-argument', 'too-large');
    if (!isJpeg(bytes)) throw new BabyError('invalid-argument', 'not-jpeg');
    next = { kind: 'photo', version: now.getTime() };
    await store.save(babyAvatarPath(babyId, next.version), bytes);
  }

  await babyRef.update({ avatar: next, updatedAt: now });
  if (before?.kind === 'photo' && (next.kind !== 'photo' || next.version !== before.version)) {
    await store.delete(babyAvatarPath(babyId, before.version)).catch(() => undefined);
  }
  return next;
}

/** Returns the current profile photo to any active member ("Chỉ người trong gia đình", 11c). */
export async function getBabyAvatar(
  db: Firestore,
  store: AvatarStore,
  uid: string,
  data: unknown,
): Promise<{ version: number; jpegBase64: string } | null> {
  const parsed = getBabyAvatarRequestSchema.safeParse(data);
  if (!parsed.success) throw new BabyError('invalid-argument', 'malformed');
  const { babyId } = parsed.data;
  await activeMembership(db, babyId, uid);

  const avatar = (await db.doc(`babies/${babyId}`).get()).get('avatar') as BabyAvatar | undefined;
  if (avatar?.kind !== 'photo') return null;
  const bytes = await store.read(babyAvatarPath(babyId, avatar.version));
  return bytes ? { version: avatar.version, jpegBase64: bytes.toString('base64') } : null;
}
