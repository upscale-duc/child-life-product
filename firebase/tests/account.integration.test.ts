import { randomUUID } from 'node:crypto';
import type { Readable } from 'node:stream';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  AccountError,
  answerOwnership,
  createSupportTicket,
  expireExports,
  familyStorage,
  maybeStorageNotice,
  offerOwnership,
  requestAccountDeletion,
  requestBabyDeletion,
  requestExport,
  requestStorage,
  runDeletionJob,
  runExport,
  signOutDevice,
  updateBabyProfile,
  updateMyProfile,
  type AccountCaller,
  type JobDeps,
  type PurgeStore,
} from '../functions/src/account.js';
import { applyUsageDelta, reconcileFamilyUsage } from '../functions/src/memories.js';
import { deliverNotice, type PushSender } from '../functions/src/social.js';

// S11 server side against the Firestore emulator: storage breakdown and requests (13b–13e),
// baby edit and the resumable, verified purge (13k, 13l, P-110, flow F), profile (13m), ownership
// transfer and account deletion (13n, Q-016), devices, exports (R-187) and help tickets.
const projectId = 'demo-child-life';
const now = new Date('2026-10-08T08:05:00Z');
const GB = 1024 ** 3;
let app: App;
let db: Firestore;
const TEDDY = 'b_5e1100000000000000a1';
const NA = 'b_5e1100000000000000b2';
const FAMILY = 'f_s11';

const caller = (uid: string, email: string | null = `${uid}@example.com`): AccountCaller => ({
  uid,
  email,
  anonymous: false,
  locale: 'vi',
});

class FakeStore implements PurgeStore {
  objects = new Map<string, number>();
  zips = new Map<string, string[]>();
  failOn: string | null = null;
  calls: string[] = [];
  async deletePrefix(prefix: string) {
    this.calls.push(`delete:${prefix}`);
    if (this.failOn === 'delete') {
      this.failOn = null;
      throw new Error('storage unavailable');
    }
    for (const k of [...this.objects.keys()]) if (k.startsWith(prefix)) this.objects.delete(k);
  }
  async countPrefix(prefix: string) {
    return [...this.objects.keys()].filter((k) => k.startsWith(prefix)).length;
  }
  async zip(path: string, entries: AsyncIterable<{ name: string; open: () => Promise<Readable> }>) {
    const names: string[] = [];
    let bytes = 0;
    for await (const e of entries) {
      names.push(e.name);
      for await (const chunk of await e.open()) bytes += (chunk as Buffer).length;
    }
    this.zips.set(path, names);
    this.objects.set(path, bytes);
    return bytes;
  }
}

let store: FakeStore;
let deletedAuth: string[];
const deps = (): JobDeps => ({
  store,
  deleteAuthUser: async (uid) => {
    deletedAuth.push(uid);
  },
});

const get = async (path: string) => (await db.doc(path).get()).data();

async function item(
  babyId: string,
  id: string,
  type: 'photo' | 'video',
  bytes: number,
  extra = {},
) {
  const ref = db.doc(`babies/${babyId}/media/${id}`);
  await ref.set({
    id,
    babyId,
    familyId: FAMILY,
    type,
    status: 'ready',
    storedBytes: bytes,
    reservedBytes: 0,
    deleted: false,
    createdBy: 'mom',
    author: { name: 'Mai', relation: 'mother', relationCustom: null },
    captureAt: new Date(now.getTime() - bytes),
    durationMs: type === 'video' ? 42_000 : null,
    paths: { original: `babies/${babyId}/media/${id}/original.jpg` },
    ...extra,
  });
  store.objects.set(`babies/${babyId}/media/${id}/original.jpg`, bytes);
  await applyUsageDelta(db, null, await ref.get());
}

beforeAll(() => {
  app = initializeApp({ projectId }, `account-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080'}/emulator/v1/projects/${projectId}/databases/(default)/documents`,
    {
      method: 'DELETE',
    },
  );
  store = new FakeStore();
  deletedAuth = [];
  await db.doc(`families/${FAMILY}`).set({
    ownerUid: 'mom',
    quotaBytes: 10 * GB,
    usedBytes: 0,
    reservedBytes: 0,
    binBytes: 0,
    usage: {},
    babyIds: [TEDDY, NA],
  });
  await db.doc('users/mom').set({ displayName: 'Mai', ownedFamilyId: FAMILY, ownedBabyCount: 2 });
  await db.doc('users/dad').set({ displayName: 'Minh' });
  for (const [babyId, nickname] of [
    [TEDDY, 'Teddy'],
    [NA, 'Na'],
  ] as const) {
    await db.doc(`babies/${babyId}`).set({
      nickname,
      familyId: FAMILY,
      ownerUid: 'mom',
      state: 'active',
      timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' },
    });
    await db
      .doc(`babies/${babyId}/restricted/profile`)
      .set({ dateOfBirth: '2026-09-17', gender: 'boy' });
    for (const [uid, role, relation, name] of [
      ['mom', 'coParent', 'mother', 'Mai'],
      ['dad', 'coParent', 'father', 'Minh'],
      ['nanny', 'caregiver', 'nanny', 'Cô Lan'],
      ['grandma', 'relative', 'grandmother', 'Bà nội Hoa'],
    ] as const) {
      await db.doc(`babies/${babyId}/members/${uid}`).set({
        uid,
        babyId,
        role,
        relation,
        relationCustom: null,
        displayName: name,
        status: 'active',
        isOwner: uid === 'mom',
      });
    }
  }
});

const reason = async (p: Promise<unknown>) => {
  try {
    await p;
    return 'ok';
  } catch (e) {
    return e instanceof AccountError ? e.reason : String(e);
  }
};

describe('storage (13b–13e)', () => {
  it('breaks usage down by baby and type, bin apart; reconcile agrees', async () => {
    await item(TEDDY, 'm1', 'photo', 3_000_000);
    await item(TEDDY, 'm2', 'video', 90_000_000);
    await item(NA, 'm3', 'photo', 2_000_000);
    await db.doc(`families/${FAMILY}`).update({ usedBytes: 95_000_000 });
    // Moving an item to the bin keeps its bytes counted but out of the baby's photos (G-041).
    const ref = db.doc(`babies/${NA}/media/m3`);
    const before = await ref.get();
    await ref.update({ deleted: true });
    await applyUsageDelta(db, before, await ref.get());

    const s = await familyStorage(db, caller('dad'), { babyId: TEDDY }, now);
    expect(s.isOwner).toBe(false);
    expect(s.babies.find((b) => b.babyId === TEDDY)).toMatchObject({
      photos: 1,
      videos: 1,
      photoBytes: 3_000_000,
      videoBytes: 90_000_000,
    });
    expect(s.babies.find((b) => b.babyId === NA)).toMatchObject({ photos: 0, photoBytes: 0 });
    expect(s.binBytes).toBe(2_000_000);
    expect(s.largestVideos.map((v) => v.mediaId)).toEqual(['m2']);

    const norm = (u: Record<string, Record<string, number>>) =>
      Object.fromEntries(
        Object.entries(u).map(([b, v]) => [
          b,
          { photos: 0, videos: 0, photoBytes: 0, videoBytes: 0, ...v },
        ]),
      );
    const live = (await get(`families/${FAMILY}`))!;
    await reconcileFamilyUsage(db, FAMILY);
    const rebuilt = (await get(`families/${FAMILY}`))!;
    expect(norm(rebuilt.usage)).toEqual(norm(live.usage));
    expect(rebuilt.usedBytes).toBe(95_000_000);
    expect(rebuilt.binBytes).toBe(2_000_000);
  });

  it('only Cùng nuôi see storage (13g, 13h)', async () => {
    expect(await reason(familyStorage(db, caller('grandma'), { babyId: TEDDY }, now))).toBe(
      'parents-only',
    );
    expect(await reason(familyStorage(db, caller('nanny'), { babyId: TEDDY }, now))).toBe(
      'parents-only',
    );
  });

  it('one open request per family, +10 / +20 GB only, mails without the message', async () => {
    const req = { requestId: randomUUID(), babyId: TEDDY, amountGb: 10, message: 'Nhà có 2 bé' };
    expect(
      await reason(
        requestStorage(db, caller('mom'), { ...req, amountGb: 5 }, now, { staffInbox: 's@x' }),
      ),
    ).toBe('malformed');
    expect(
      await reason(requestStorage(db, caller('mom', null), req, now, { staffInbox: 's@x' })),
    ).toBe('email-required');
    const first = await requestStorage(db, caller('mom'), req, now, { staffInbox: 'staff@x' });
    expect(first.created).toBe(true);
    const again = await requestStorage(db, caller('mom'), req, now, { staffInbox: 'staff@x' });
    expect(again).toEqual({ id: first.id, created: false });
    const other = await requestStorage(
      db,
      caller('dad'),
      { ...req, requestId: randomUUID(), amountGb: 20 },
      now,
      { staffInbox: 'staff@x' },
    );
    expect(other).toEqual({ id: first.id, created: false });
    const mail = (await db.collection('mail').get()).docs.map((d) => d.data());
    expect(mail.map((m) => m.to).sort()).toEqual(['mom@example.com', 'staff@x']);
    expect(JSON.stringify(mail)).not.toContain('Nhà có 2 bé');
    const s = await familyStorage(db, caller('mom'), { babyId: NA }, now);
    expect(s.openRequest?.amountGb).toBe(10);
  });

  it('80 % and 100 % notices go once per state to the parents', async () => {
    await db.doc(`families/${FAMILY}`).update({ usedBytes: 8.2 * GB });
    expect(await maybeStorageNotice(db, FAMILY, now)).toMatch(/^storage_/);
    expect(await maybeStorageNotice(db, FAMILY, now)).toBeNull();
    await db.doc(`families/${FAMILY}`).update({ usedBytes: 10 * GB });
    const full = await maybeStorageNotice(db, FAMILY, now);
    const notice = (await get(`babies/${TEDDY}/notifications/${full}`))!;
    expect(notice.count).toBe(100);
    expect([...notice.recipients].sort()).toEqual(['dad', 'mom']);
  });

  it('a muted kind is not pushed (G-056)', async () => {
    await db
      .doc('users/dad/settings/notifications')
      .set({ memories: true, messages: true, reminders: true, storage: false });
    await db.doc('users/mom/devices/d1').set({ token: 'tm', language: 'vi' });
    await db.doc('users/dad/devices/d2').set({ token: 'td', language: 'vi' });
    await db.doc(`families/${FAMILY}`).update({ usedBytes: 9 * GB });
    const id = (await maybeStorageNotice(db, FAMILY, now))!;
    const sent: string[] = [];
    const sender: PushSender = {
      send: async (tokens) => {
        sent.push(...tokens);
        return [];
      },
    };
    await deliverNotice(db, sender, TEDDY, id, now);
    expect(sent).toEqual(['tm']);
  });
});

describe('baby profile (13k, 13l)', () => {
  it('Cùng nuôi edit; dates stay in range', async () => {
    await updateBabyProfile(
      db,
      caller('dad'),
      { babyId: TEDDY, nickname: 'Tí', gender: 'unspecified' },
      now,
    );
    expect((await get(`babies/${TEDDY}`))!.nickname).toBe('Tí');
    expect((await get(`babies/${TEDDY}/restricted/profile`))!.gender).toBe('unspecified');
    expect(
      await reason(updateBabyProfile(db, caller('nanny'), { babyId: TEDDY, nickname: 'X' }, now)),
    ).toBe('parents-only');
    expect(
      await reason(
        updateBabyProfile(db, caller('mom'), { babyId: TEDDY, dateOfBirth: '2026-10-09' }, now),
      ),
    ).toBe('dob-in-future');
  });

  it('only the owner deletes, by typing the nickname', async () => {
    expect(
      await reason(
        requestBabyDeletion(db, caller('dad'), { babyId: TEDDY, confirmNickname: 'Teddy' }, now),
      ),
    ).toBe('owner-only');
    expect(
      await reason(
        requestBabyDeletion(db, caller('mom'), { babyId: TEDDY, confirmNickname: 'Tedy' }, now),
      ),
    ).toBe('nickname-mismatch');
    const { jobId } = await requestBabyDeletion(
      db,
      caller('mom'),
      { babyId: TEDDY, confirmNickname: ' teddy ' },
      now,
    );
    expect((await get(`babies/${TEDDY}`))!.state).toBe('deleting');
    expect((await get(`deletionJobs/${jobId}`))!.state).toBe('queued');
  });

  it('the purge leaves nothing of the baby, other babies intact, quota back (flow F)', async () => {
    await item(TEDDY, 'm1', 'photo', 3_000_000);
    await item(NA, 'm2', 'photo', 2_000_000);
    await db.doc(`families/${FAMILY}`).update({ usedBytes: 5_000_000 });
    await db.doc(`babies/${TEDDY}/records/r1`).set({ type: 'bottle' });
    await db.doc(`babies/${TEDDY}/albums/a1`).set({ name: 'Giờ tắm' });
    await db.doc(`babies/${TEDDY}/albums/a1/items/m1`).set({ at: now });
    await db.doc('invites/i1').set({ babyId: TEDDY });
    await db.doc(`families/${FAMILY}/reservations/m9`).set({ babyId: TEDDY });
    store.objects.set(`babies/${TEDDY}/avatar/v1.jpg`, 10);
    store.failOn = 'delete';

    const { jobId } = await requestBabyDeletion(
      db,
      caller('mom'),
      { babyId: TEDDY, confirmNickname: 'Teddy' },
      now,
    );
    // First run stops at "storage"; "đã xoá" is not shown early.
    expect(await runDeletionJob(db, deps(), jobId, () => now)).toBe('failed');
    expect((await get(`deletionJobs/${jobId}`))!.failedStep).toBe('storage');
    expect(await get(`babies/${TEDDY}`)).toBeDefined();
    // The re-run resumes at the failed step.
    const later = new Date(now.getTime() + 60 * 60_000);
    expect(await runDeletionJob(db, deps(), jobId, () => later)).toBe('done');
    expect(store.calls.filter((c) => c.startsWith(`delete:babies/${TEDDY}`))).toHaveLength(2);

    expect(await get(`babies/${TEDDY}`)).toBeUndefined();
    expect(await db.doc(`babies/${TEDDY}`).listCollections()).toHaveLength(0);
    expect(await store.countPrefix(`babies/${TEDDY}/`)).toBe(0);
    expect((await db.collection('invites').where('babyId', '==', TEDDY).get()).size).toBe(0);
    expect(await get(`families/${FAMILY}/reservations/m9`)).toBeUndefined();
    const family = (await get(`families/${FAMILY}`))!;
    expect(family.babyIds).toEqual([NA]);
    expect(family.usedBytes).toBe(2_000_000);
    expect(family.usage[TEDDY]).toBeUndefined();
    expect((await get('users/mom'))!.ownedBabyCount).toBe(1);
    expect(await get(`babies/${NA}/media/m2`)).toBeDefined();
    expect(await store.countPrefix(`babies/${NA}/`)).toBe(1);
    const mails = (await db.collection('mail').where('template', '==', 'babyDeleted').get()).docs;
    expect(mails).toHaveLength(1);
    expect(JSON.stringify(mails[0]!.data())).not.toContain('Teddy');
  });

  it('verification failing keeps the profile until a clean re-run', async () => {
    const { jobId } = await requestBabyDeletion(
      db,
      caller('mom'),
      { babyId: TEDDY, confirmNickname: 'Teddy' },
      now,
    );
    const stubborn = new FakeStore();
    stubborn.deletePrefix = async () => {};
    stubborn.objects.set(`babies/${TEDDY}/media/x/original.jpg`, 1);
    expect(await runDeletionJob(db, { ...deps(), store: stubborn }, jobId, () => now)).toBe(
      'failed',
    );
    expect((await get(`deletionJobs/${jobId}`))!.failedStep).toBe('verify');
    expect(await get(`babies/${TEDDY}`)).toBeDefined();
  });
});

describe('your profile (13m)', () => {
  it('name everywhere, relation per baby, own memberships only', async () => {
    await updateMyProfile(
      db,
      caller('dad'),
      {
        displayName: 'Anh Minh',
        relations: [{ babyId: NA, relation: 'other', relationCustom: 'Bố' }],
      },
      now,
    );
    expect((await get(`babies/${TEDDY}/members/dad`))!.displayName).toBe('Anh Minh');
    expect((await get(`babies/${TEDDY}/members/dad`))!.relation).toBe('father');
    expect((await get(`babies/${NA}/members/dad`))!.relationCustom).toBe('Bố');
    expect((await get('users/dad'))!.displayName).toBe('Anh Minh');
    await db.doc(`babies/${NA}/members/nanny`).update({ status: 'removed' });
    expect(
      await reason(
        updateMyProfile(
          db,
          caller('nanny'),
          { relations: [{ babyId: NA, relation: 'nanny', relationCustom: null }] },
          now,
        ),
      ),
    ).toBe('not-a-member');
  });
});

describe('ownership and account deletion (13n, Q-016)', () => {
  const emailOf = async (uid: string) => `${uid}@example.com`;

  it('offered to a Cùng nuôi of every baby, who accepts', async () => {
    expect(
      await reason(offerOwnership(db, caller('mom'), { toUid: 'grandma' }, now, emailOf)),
    ).toBe('receiver-not-parent');
    expect(await reason(offerOwnership(db, caller('dad'), { toUid: 'mom' }, now, emailOf))).toBe(
      'not-owner',
    );
    await offerOwnership(db, caller('mom'), { toUid: 'dad' }, now, emailOf);
    expect((await get('users/dad'))!.pendingOwnership.familyId).toBe(FAMILY);
    expect(
      await reason(answerOwnership(db, caller('mom'), { familyId: FAMILY, answer: 'accept' }, now)),
    ).toBe('not-allowed');
    expect(
      await answerOwnership(db, caller('dad'), { familyId: FAMILY, answer: 'accept' }, now),
    ).toEqual({
      state: 'accepted',
    });
    expect((await get(`families/${FAMILY}`))!.ownerUid).toBe('dad');
    expect((await get(`babies/${NA}`))!.ownerUid).toBe('dad');
    expect((await get(`babies/${NA}/members/dad`))!.isOwner).toBe(true);
    expect((await get(`babies/${NA}/members/mom`))!.isOwner).toBe(false);
    expect((await get('users/dad'))!).toMatchObject({ ownedFamilyId: FAMILY, ownedBabyCount: 2 });
    expect((await get('users/dad'))!.pendingOwnership).toBeUndefined();
    expect((await get('users/mom'))!.ownedBabyCount).toBe(0);
  });

  it('declined or cancelled offers leave everything as it was', async () => {
    await offerOwnership(db, caller('mom'), { toUid: 'dad' }, now, emailOf);
    await answerOwnership(db, caller('dad'), { familyId: FAMILY, answer: 'decline' }, now);
    expect((await get(`families/${FAMILY}`))!.transfer).toBeUndefined();
    expect((await get(`families/${FAMILY}`))!.ownerUid).toBe('mom');
  });

  it('an owner cannot delete the account; a member can, and stays as "Người dùng đã xoá"', async () => {
    expect(await reason(requestAccountDeletion(db, caller('mom'), { confirm: true }, now))).toBe(
      'owns-babies',
    );
    await db
      .doc(`babies/${TEDDY}/records/r1`)
      .set({ createdBy: 'dad', author: { name: 'Minh', relation: 'father' } });
    await db
      .doc(`babies/${TEDDY}/memories/x1`)
      .set({ createdBy: 'dad', author: { name: 'Minh', relation: 'father' } });
    await db.doc(`babies/${TEDDY}/reactions/memory__x1__dad`).set({ uid: 'dad' });
    await db.doc(`babies/${TEDDY}/favorites/dad__m1`).set({ uid: 'dad' });
    await db.doc('users/dad/devices/d1').set({ token: 't' });
    // Premium Slice 3: NL07b episodes (who confirmed, who closed) and stored AI summaries stay.
    await db
      .doc(`babies/${TEDDY}/episodes/ep_1`)
      .set({ confirmedBy: 'dad', closedBy: 'mom', status: 'closed' });
    await db
      .doc(`babies/${TEDDY}/episodes/ep_2`)
      .set({ confirmedBy: 'mom', closedBy: 'dad', status: 'closed' });
    await db.doc(`babies/${TEDDY}/summaries/su_1`).set({ requestedBy: 'dad', kind: 'handover' });
    await db.doc('users/dad/settings/ai').set({ consent: null });

    const { jobId } = await requestAccountDeletion(db, caller('dad'), { confirm: true }, now);
    expect(await runDeletionJob(db, deps(), jobId, () => now)).toBe('done');
    expect((await get(`babies/${TEDDY}/members/dad`))!.status).toBe('removed');
    expect((await get(`babies/${TEDDY}/records/r1`))!).toMatchObject({
      author: { name: '', relation: 'deleted' },
      authorDeleted: true,
    });
    expect((await get(`babies/${TEDDY}/memories/x1`))!.authorDeleted).toBe(true);
    expect((await get(`babies/${TEDDY}/episodes/ep_1`))!).toMatchObject({
      status: 'closed',
      authorDeleted: true,
    });
    expect((await get(`babies/${TEDDY}/episodes/ep_1`))!.closedByDeleted).toBeUndefined();
    expect((await get(`babies/${TEDDY}/episodes/ep_2`))!).toMatchObject({ closedByDeleted: true });
    expect((await get(`babies/${TEDDY}/episodes/ep_2`))!.authorDeleted).toBeUndefined();
    expect((await get(`babies/${TEDDY}/summaries/su_1`))!.authorDeleted).toBe(true);
    expect(await get('users/dad/settings/ai')).toBeUndefined();
    expect(await get(`babies/${TEDDY}/reactions/memory__x1__dad`)).toBeUndefined();
    expect(await get(`babies/${TEDDY}/favorites/dad__m1`)).toBeUndefined();
    expect(await get('users/dad')).toBeUndefined();
    expect(await get('users/dad/devices/d1')).toBeUndefined();
    expect(deletedAuth).toEqual(['dad']);
    expect((await get(`deletionJobs/${jobId}`))!.email).toBeNull();
    expect((await db.collection('mail').where('template', '==', 'accountDeleted').get()).size).toBe(
      1,
    );
  });
});

describe('devices, exports and help', () => {
  it('signs another device out and drops its push token', async () => {
    const id = `d_${'e'.repeat(32)}`;
    await db.doc(`users/mom/devices/${id}`).set({ token: 't', platform: 'ios' });
    await signOutDevice(db, caller('mom'), { deviceId: id }, now);
    const d = (await get(`users/mom/devices/${id}`))!;
    expect(d.signedOutAt).toBeInstanceOf(Timestamp);
    expect(d.token).toBeUndefined();
    expect(await reason(signOutDevice(db, caller('dad'), { deviceId: id }, now))).toBe('device');
  });

  it('care exports for Cùng nuôi, media for the owner; 24 h, then gone (R-187)', async () => {
    await db.doc(`babies/${TEDDY}/records/r1`).set({
      id: 'r1',
      type: 'bottle',
      occurredAt: now,
      endedAt: null,
      data: { ml: 90 },
      deleted: false,
      author: { name: 'Mai' },
      createdAt: now,
    });
    expect(
      await reason(
        requestExport(
          db,
          caller('dad'),
          { requestId: randomUUID(), babyId: TEDDY, kind: 'media' },
          now,
        ),
      ),
    ).toBe('owner-only');
    expect(
      await reason(
        requestExport(
          db,
          caller('grandma'),
          { requestId: randomUUID(), babyId: TEDDY, kind: 'care' },
          now,
        ),
      ),
    ).toBe('parents-only');
    const { jobId } = await requestExport(
      db,
      caller('dad'),
      { requestId: randomUUID(), babyId: TEDDY, kind: 'care' },
      now,
    );
    expect(
      await reason(
        requestExport(
          db,
          caller('dad'),
          { requestId: randomUUID(), babyId: NA, kind: 'care' },
          now,
        ),
      ),
    ).toBe('export-running');
    expect(await runExport(db, store, async () => null as never, jobId, now, 24)).toBe('ready');
    const job = (await get(`dataJobs/${jobId}`))!;
    // Ăn dặm meals (D-085 #3) ride along as their own sheet.
    expect(store.zips.get(job.path)).toEqual(['care.json', 'care.csv', 'meals.csv']);
    expect((job.expiresAt as Timestamp).toMillis()).toBe(now.getTime() + 24 * 3_600_000);
    // "Tải tệp về" in the email: the token's hash on the job, the token in the queued mail only.
    expect(job.downloadTokenHash).toMatch(/^[a-f0-9]{64}$/);
    const exportMail = (await db.collection('mail').where('template', '==', 'exportReady').get())
      .docs[0]!;
    expect(exportMail.get('data')).toMatchObject({ jobId, size: '1 MB' });
    expect(exportMail.get('data.token')).toMatch(/^[A-Za-z0-9_-]{32}$/);

    await item(TEDDY, 'm1', 'photo', 1_000);
    const media = await requestExport(
      db,
      caller('mom'),
      { requestId: randomUUID(), babyId: TEDDY, kind: 'media' },
      now,
    );
    const { Readable } = await import('node:stream');
    expect(
      await runExport(
        db,
        store,
        async () => Readable.from([Buffer.alloc(10)]),
        media.jobId,
        now,
        24,
      ),
    ).toBe('ready');
    expect(store.zips.get((await get(`dataJobs/${media.jobId}`))!.path)).toHaveLength(1);

    expect(await expireExports(db, store, new Date(now.getTime() + 25 * 3_600_000))).toBe(2);
    expect((await get(`dataJobs/${jobId}`))!.state).toBe('expired');
    expect(await store.countPrefix('exports/')).toBe(0);
  });

  it('help tickets are numbered once per request', async () => {
    const t = {
      requestId: randomUUID(),
      category: 'storage',
      message: 'Không tải được video',
      diagnostics: null,
      locale: 'vi',
    };
    const first = await createSupportTicket(db, caller('mom'), t, now, { staffInbox: 's@x' });
    expect(first.ticket).toBe('CL-1001');
    expect(await createSupportTicket(db, caller('mom'), t, now, { staffInbox: 's@x' })).toEqual(
      first,
    );
    const second = await createSupportTicket(
      db,
      caller('dad'),
      { ...t, requestId: randomUUID() },
      now,
      {
        staffInbox: 's@x',
      },
    );
    expect(second.ticket).toBe('CL-1002');
    const mail = (await db.collection('mail').get()).docs.map((d) => d.data());
    expect(JSON.stringify(mail)).not.toContain('Không tải được video');
  });
});
