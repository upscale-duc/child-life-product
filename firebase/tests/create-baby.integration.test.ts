import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  BabyError,
  createBaby,
  getBabyAvatar,
  setBabyAvatar,
  type AvatarStore,
} from '../functions/src/babies.js';

// Runs the Functions handlers against the Firestore emulator (FIRESTORE_EMULATOR_HOST is set by
// `pnpm test:rules`). Plan S2: owner membership, 3-baby cap including concurrent creates.
const projectId = 'demo-child-life';
const now = new Date('2026-10-08T03:00:00Z'); // 10:00 in Ho Chi Minh City
const quota = 10 * 1024 ** 3;
let app: App;
let db: Firestore;

const request = (overrides: Record<string, unknown> = {}) => ({
  requestId: randomUUID(),
  nickname: 'Teddy',
  dateOfBirth: '2026-09-17',
  gender: 'girl',
  timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' },
  avatarPreset: 1,
  trackers: ['bottle', 'breast', 'sleep', 'diaper'],
  self: { displayName: 'Mai', relation: 'mother' },
  ...overrides,
});

const memoryStore = () => {
  const files = new Map<string, Buffer>();
  const store: AvatarStore = {
    save: async (path, bytes) => void files.set(path, bytes),
    read: async (path) => files.get(path) ?? null,
    delete: async (path) => void files.delete(path),
  };
  return { files, store };
};

const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3, 0xff, 0xd9]);

async function reasonOf(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (error) {
    if (error instanceof BabyError) return error.reason;
    throw error;
  }
  throw new Error('expected a BabyError');
}

beforeAll(() => {
  app = initializeApp({ projectId }, `create-baby-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host) throw new Error('Run with the Firestore emulator (pnpm test:rules)');
  await fetch(`http://${host}/emulator/v1/projects/${projectId}/databases/(default)/documents`, {
    method: 'DELETE',
  });
});

describe('createBaby', () => {
  it('creates the family, baby, restricted profile, owner membership and account', async () => {
    const res = await createBaby(db, 'mom', request(), now, quota);
    expect(res.created).toBe(true);

    const baby = (await db.doc(`babies/${res.babyId}`).get()).data()!;
    expect(baby).toMatchObject({
      ownerUid: 'mom',
      familyId: res.familyId,
      nickname: 'Teddy',
      state: 'active',
    });
    expect(baby.avatar).toEqual({ kind: 'preset', preset: 1 });
    expect(baby).not.toHaveProperty('dateOfBirth');
    expect((await db.doc(`babies/${res.babyId}/restricted/profile`).get()).data()).toMatchObject({
      dateOfBirth: '2026-09-17',
      gender: 'girl',
    });
    expect((await db.doc(`babies/${res.babyId}/members/mom`).get()).data()).toMatchObject({
      role: 'coParent',
      isOwner: true,
      relation: 'mother',
      displayName: 'Mai',
      status: 'active',
    });
    expect((await db.doc(`families/${res.familyId}`).get()).data()).toMatchObject({
      ownerUid: 'mom',
      quotaBytes: quota,
      babyIds: [res.babyId],
    });
    expect((await db.doc('users/mom').get()).data()).toMatchObject({
      displayName: 'Mai',
      ownedFamilyId: res.familyId,
      ownedBabyCount: 1,
    });
  });

  it('is idempotent per request id', async () => {
    const body = request();
    const first = await createBaby(db, 'mom', body, now, quota);
    const again = await createBaby(db, 'mom', body, now, quota);
    expect(again).toEqual({ ...first, created: false });
    expect((await db.doc('users/mom').get()).get('ownedBabyCount')).toBe(1);
  });

  it('puts later babies in the same family (P-001)', async () => {
    const a = await createBaby(db, 'mom', request(), now, quota);
    const b = await createBaby(db, 'mom', request({ nickname: 'Na' }), now, quota);
    expect(b.familyId).toBe(a.familyId);
    expect((await db.doc(`families/${a.familyId}`).get()).get('babyIds')).toEqual([
      a.babyId,
      b.babyId,
    ]);
  });

  it('allows at most 3 own babies (R-043)', async () => {
    for (let i = 0; i < 3; i += 1) await createBaby(db, 'mom', request(), now, quota);
    expect(await reasonOf(createBaby(db, 'mom', request(), now, quota))).toBe('baby-limit');
  });

  it('keeps the cap under concurrent creates', async () => {
    const results = await Promise.allSettled(
      Array.from({ length: 5 }, () => createBaby(db, 'racer', request(), now, quota)),
    );
    const created = results.filter((r) => r.status === 'fulfilled');
    expect(created).toHaveLength(3);
    for (const r of results.filter((x) => x.status === 'rejected')) {
      expect((r as PromiseRejectedResult).reason).toBeInstanceOf(BabyError);
    }
    expect((await db.doc('users/racer').get()).get('ownedBabyCount')).toBe(3);
    const babies = await db.collection('babies').where('ownerUid', '==', 'racer').get();
    expect(babies.size).toBe(3);
  });

  it('rejects a date of birth in the future of the baby time zone', async () => {
    // 2026-10-08 03:00 UTC is already the 8th in Asia/Ho_Chi_Minh but still the 7th in New York.
    expect(
      await reasonOf(createBaby(db, 'mom', request({ dateOfBirth: '2026-10-09' }), now, quota)),
    ).toBe('dob-in-future');
    await createBaby(db, 'mom', request({ dateOfBirth: '2026-10-08' }), now, quota);
    expect(
      await reasonOf(
        createBaby(
          db,
          'dad',
          request({
            dateOfBirth: '2026-10-08',
            timeZone: { mode: 'manual', zone: 'America/New_York' },
          }),
          now,
          quota,
        ),
      ),
    ).toBe('dob-in-future');
  });

  it('rejects malformed input', async () => {
    for (const bad of [
      request({ nickname: '   ' }),
      request({ trackers: [] }),
      request({ trackers: ['bottle', 'bottle'] }),
      request({ timeZone: { mode: 'auto', zone: 'GMT+7' } }),
      request({ self: { displayName: 'Mai', relation: 'other' } }),
      request({ avatarPreset: 5 }),
      request({ dateOfBirth: '1990-01-01' }),
    ]) {
      expect(['malformed', 'dob-too-old']).toContain(
        await reasonOf(createBaby(db, 'mom', bad, now, quota)),
      );
    }
  });
});

describe('baby avatar', () => {
  it('Cùng nuôi set a photo; every active member reads it; the old photo is deleted', async () => {
    const { babyId } = await createBaby(db, 'mom', request(), now, quota);
    await db
      .doc(`babies/${babyId}/members/nanny`)
      .set({ uid: 'nanny', role: 'caregiver', status: 'active' });
    const { files, store } = memoryStore();

    const first = await setBabyAvatar(
      db,
      store,
      'mom',
      { babyId, avatar: { kind: 'photo', jpegBase64: jpeg.toString('base64') } },
      now,
    );
    expect(first.kind).toBe('photo');
    const read = await getBabyAvatar(db, store, 'nanny', { babyId });
    expect(read?.jpegBase64).toBe(jpeg.toString('base64'));

    const later = new Date(now.getTime() + 1000);
    await setBabyAvatar(
      db,
      store,
      'mom',
      { babyId, avatar: { kind: 'photo', jpegBase64: jpeg.toString('base64') } },
      later,
    );
    expect(files.size).toBe(1);
    await setBabyAvatar(db, store, 'mom', { babyId, avatar: { kind: 'preset', preset: 3 } }, later);
    expect(files.size).toBe(0);
    expect(await getBabyAvatar(db, store, 'mom', { babyId })).toBeNull();
  });

  it('caregivers and strangers cannot change it; strangers cannot read it', async () => {
    const { babyId } = await createBaby(db, 'mom', request(), now, quota);
    await db
      .doc(`babies/${babyId}/members/nanny`)
      .set({ uid: 'nanny', role: 'caregiver', status: 'active' });
    const { store } = memoryStore();
    const preset = { babyId, avatar: { kind: 'preset', preset: 2 } };
    expect(await reasonOf(setBabyAvatar(db, store, 'nanny', preset, now))).toBe('not-co-parent');
    expect(await reasonOf(setBabyAvatar(db, store, 'stranger', preset, now))).toBe('not-a-member');
    expect(await reasonOf(getBabyAvatar(db, store, 'stranger', { babyId }))).toBe('not-a-member');
  });

  it('accepts only JPEG bytes', async () => {
    const { babyId } = await createBaby(db, 'mom', request(), now, quota);
    const { store } = memoryStore();
    const png = Buffer.from([0x89, 0x50, 0x4e, 0x47, 1, 2]).toString('base64');
    expect(
      await reasonOf(
        setBabyAvatar(
          db,
          store,
          'mom',
          { babyId, avatar: { kind: 'photo', jpegBase64: png } },
          now,
        ),
      ),
    ).toBe('not-jpeg');
  });
});
