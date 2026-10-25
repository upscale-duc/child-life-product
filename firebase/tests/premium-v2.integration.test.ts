import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { GB, defaultEntitlementsConfig, defaultFlags } from '@child-life/contracts';
import { createBaby } from '../functions/src/babies.js';
import {
  FamilyError,
  acceptInvite,
  chooseWriteSeats,
  createInvite,
  updateMember,
  type Caller,
} from '../functions/src/family.js';
import {
  familyPlanAnswer,
  familyUsageHistory,
  storageLimitBytes,
} from '../functions/src/premium-v2.js';
import { renderJobCode } from '../functions/src/premium-ops.js';
import { commitQuota, reserveQuota } from '../functions/src/quota.js';
import {
  adjustUsage,
  decideProposal,
  listProposals,
  proposePlans,
  refundVideoJob,
} from '../functions/src/premium-plans-staff.js';
import { familyCode, StaffError, type Staff } from '../functions/src/staff.js';
import { setFamilyPlan } from '../functions/src/features-hub.js';
import { premiumOverview } from '../functions/src/premium-overview.js';

// Premium v2 (Figma 958:13863, D-101): the plan's storage limit and the write seats
// (Q-095, Q-097, Q-101) against the Firestore emulator.
const projectId = 'demo-child-life';
const now = new Date('2026-10-25T03:00:00Z');
let app: App;
let db: Firestore;
let babyId: string;
let familyId: string;

const mom: Caller = { uid: 'mom', anonymous: false, emailTrusted: true };
const caller = (uid: string): Caller => ({ uid, anonymous: false, emailTrusted: true });

async function reasonOf(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (error) {
    if (error instanceof FamilyError) return error.reason;
    throw error;
  }
  throw new Error('expected a FamilyError');
}

const invite = (role: 'coParent' | 'caregiver' | 'relative') =>
  createInvite(db, mom, { requestId: randomUUID(), babyId, relation: 'grandmother', role }, now);

const join = (uid: string, code: string) =>
  acceptInvite(
    db,
    caller(uid),
    '203.0.113.7',
    { code, displayName: uid, relation: 'grandmother' },
    now,
  );

async function v2(enabled: boolean) {
  await db.doc('config/flags').set({
    premium_v2: { ...defaultFlags.premium_v2, enabled, scope: 'all' },
  });
}

beforeAll(() => {
  app = initializeApp({ projectId }, `premium-v2-${randomUUID()}`);
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
  await db.doc('config/entitlements').set(structuredClone(defaultEntitlementsConfig));
  ({ babyId, familyId } = await createBaby(
    db,
    'mom',
    {
      requestId: randomUUID(),
      nickname: 'Teddy',
      dateOfBirth: '2026-09-17',
      gender: 'girl',
      timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' },
      avatarPreset: 1,
      trackers: ['bottle'],
      self: { displayName: 'Mai', relation: 'mother' },
    },
    now,
    10 * GB,
  ));
});

describe('storage limit (Q-095)', () => {
  it('keeps the stored quota while v2 is off; Free 1 GB for everyone once on', async () => {
    const family = () => db.doc(`families/${familyId}`).get();
    await v2(false);
    expect(await storageLimitBytes(db, familyId, await family(), now)).toBe(10 * GB);
    await v2(true);
    expect(await storageLimitBytes(db, familyId, await family(), now)).toBe(1 * GB);
  });

  it('the portal value per plan applies at once', async () => {
    await v2(true);
    const config = structuredClone(defaultEntitlementsConfig);
    config.plans.free.storageGB = 2;
    await db.doc('config/entitlements').set(config);
    const family = await db.doc(`families/${familyId}`).get();
    expect(await storageLimitBytes(db, familyId, family, now)).toBe(2 * GB);
  });
});

describe('write seats (Q-097)', () => {
  it('Free has 3: a pending write invite holds a seat, the 4th writer is refused', async () => {
    await v2(true);
    const dad = await invite('coParent');
    await invite('caregiver');
    expect(await reasonOf(invite('caregiver'))).toBe('seats-full');
    // Relatives never take a seat.
    await invite('relative');
    await join('dad', dad.code);
    expect(await reasonOf(invite('caregiver'))).toBe('seats-full');
  });

  it('nothing changes while v2 is off, and existing members keep writing', async () => {
    await v2(false);
    for (const uid of ['dad', 'nanny', 'aunt']) {
      const t = await invite(uid === 'dad' ? 'coParent' : 'caregiver');
      await join(uid, t.code);
    }
    await v2(true);
    // Over the limit: nobody loses access, only the next writer is refused.
    expect((await db.doc(`babies/${babyId}/members/aunt`).get()).get('writeSuspended')).toBe(
      undefined,
    );
    expect(await reasonOf(invite('caregiver'))).toBe('seats-full');
    const relative = await invite('relative');
    await join('grandpa', relative.code);
    expect(
      await reasonOf(updateMember(db, mom, { babyId, uid: 'grandpa', role: 'caregiver' }, now)),
    ).toBe('seats-full');
  });

  it('the seat count comes from the plan config (portal-editable)', async () => {
    await v2(true);
    const config = structuredClone(defaultEntitlementsConfig);
    config.plans.free.caregiverSeats = 4;
    await db.doc('config/entitlements').set(config);
    await invite('coParent');
    await invite('caregiver');
    await invite('caregiver');
    expect(await reasonOf(invite('caregiver'))).toBe('seats-full');
  });
});

describe('Chọn ai giữ quyền ghi (PV44, Q-101)', () => {
  async function overLimit() {
    await v2(false);
    for (const uid of ['dad', 'nanny', 'aunt']) {
      const t = await invite(uid === 'dad' ? 'coParent' : 'caregiver');
      await join(uid, t.code);
    }
    await v2(true);
  }
  const suspended = async (uid: string) =>
    (await db.doc(`babies/${babyId}/members/${uid}`).get()).get('writeSuspended') === true;

  it('the manager keeps up to the seats; the others become view-only and hear once', async () => {
    await overLimit();
    expect(
      await reasonOf(chooseWriteSeats(db, mom, { babyId, keep: ['dad', 'nanny', 'aunt'] }, now)),
    ).toBe('seats-full');
    expect(await chooseWriteSeats(db, mom, { babyId, keep: ['dad', 'nanny'] }, now)).toEqual({
      suspended: 1,
    });
    expect(await suspended('aunt')).toBe(true);
    expect(await suspended('dad')).toBe(false);
    expect((await db.doc(`babies/${babyId}/members/aunt`).get()).get('status')).toBe('active');
    const notices = await db
      .collection(`babies/${babyId}/notifications`)
      .where('recipients', 'array-contains', 'aunt')
      .get();
    expect(notices.size).toBe(1);
    // Choosing again gives the seat back.
    await chooseWriteSeats(db, mom, { babyId, keep: ['dad', 'aunt'] }, now);
    expect(await suspended('aunt')).toBe(false);
    expect(await suspended('nanny')).toBe(true);
  });

  it('only the manager chooses, and only while v2 runs', async () => {
    await overLimit();
    expect(await reasonOf(chooseWriteSeats(db, caller('dad'), { babyId, keep: [] }, now))).toBe(
      'owner-only',
    );
    await v2(false);
    expect(await reasonOf(chooseWriteSeats(db, mom, { babyId, keep: [] }, now))).toBe(
      'not-available',
    );
  });
});

describe('Gói của gia đình and Lịch sử sử dụng (PV40B, PV41, PV45)', () => {
  async function useCredits(uid: string, id: string, units: number) {
    const request = {
      window: { kind: 'trial' as const, feature: 'assistant' as const, key: 'v2' },
      limit: 30,
    };
    await db.runTransaction((tx) =>
      reserveQuota(tx, db, {
        familyId,
        reservationId: id,
        windows: [request],
        units,
        actorUid: uid,
        task: 'lumi.chat',
        now,
      }),
    );
    await db.runTransaction((tx) => commitQuota(tx, db, { familyId, reservationId: id, now }));
  }

  it('Free: 30 credit and 2 video once (no refill date), 1 GB, 3 seats', async () => {
    await v2(true);
    const answer = await familyPlanAnswer(db, 'mom', { babyId }, now, 'test');
    expect(answer).toMatchObject({
      v2: true,
      plan: 'free',
      isManager: true,
      cycle: null,
      lumi: { limit: 30, used: 0, resetsAt: null },
      video: { limit: 2, used: 0, resetsAt: null },
      storage: { limitBytes: 1 * GB, addOnGb: 0 },
      seats: { used: 1, limit: 3, suspended: [], overLimit: false },
      premiumTemplates: false,
    });
  });

  it('the manager sees everyone; a member only their own lines; never content', async () => {
    await v2(true);
    const t = await invite('coParent');
    await join('dad', t.code);
    await useCredits('mom', 'op_mom', 2);
    await useCredits('dad', 'op_dad', 3);
    const all = await familyUsageHistory(db, 'mom', { babyId, everyone: true }, now);
    expect(all.everyone).toBe(true);
    expect(all.rows.filter((r) => r.kind === 'lumi').map((r) => [r.uid, r.amount])).toEqual(
      expect.arrayContaining([
        ['mom', -2],
        ['dad', -3],
      ]),
    );
    expect(all.rows.filter((r) => r.kind === 'lumi').map((r) => r.state)).toEqual(
      expect.arrayContaining(['debited', 'debited']),
    );
    expect(all.rows.find((r) => r.kind === 'grant')).toMatchObject({
      task: 'lumi.trial',
      amount: 30,
    });
    const own = await familyUsageHistory(db, 'dad', { babyId, everyone: true }, now);
    expect(own.everyone).toBe(false);
    expect(own.rows.filter((r) => r.kind === 'lumi').map((r) => r.uid)).toEqual(['dad']);
    expect(Object.keys(own.rows[0]!).sort()).toEqual(
      ['amount', 'at', 'id', 'kind', 'state', 'task', 'uid'].sort(),
    );
    const plan = await familyPlanAnswer(db, 'dad', { babyId }, now, 'test');
    expect(plan).toMatchObject({ isManager: false, lumi: { used: 5 }, seats: { used: 2 } });
  });
});

describe('portal: versions, two approvers, adjustments (PT02, PT03)', () => {
  const owner: Staff = { uid: 's_owner', name: 'Owner', roles: ['owner'] };
  const owner2: Staff = { uid: 's_owner2', name: 'Owner 2', roles: ['owner'] };
  const eng: Staff = { uid: 's_eng', name: 'Kỹ sư', roles: ['eng'] };
  const reason = 'Điều chỉnh theo vận hành tháng 11';
  const staffReason = async (p: Promise<unknown>) => {
    try {
      await p;
    } catch (e) {
      if (e instanceof StaffError) return e.reason;
      throw e;
    }
    throw new Error('expected a StaffError');
  };

  beforeEach(async () => {
    await db.doc(`familyDirectory/${familyId}`).set({ code: familyCode(familyId) });
    await v2(true);
  });

  it('a plans version applies only once someone else approves it', async () => {
    const plans = structuredClone(defaultEntitlementsConfig.plans);
    plans.free.storageGB = 2;
    const { id } = await proposePlans(db, eng, { version: '2.1', plans, reason }, now);
    const family = () => db.doc(`families/${familyId}`).get();
    expect(await storageLimitBytes(db, familyId, await family(), now)).toBe(1 * GB);
    expect(await staffReason(decideProposal(db, eng, { id, approve: true, reason }, now))).toBe(
      'second-approver',
    );
    expect((await listProposals(db, eng))[0]).toMatchObject({ id, status: 'pending', mine: true });
    await decideProposal(db, owner, { id, approve: true, reason }, now);
    expect(await storageLimitBytes(db, familyId, await family(), now)).toBe(2 * GB);
    const config = (await db.doc('config/entitlements').get()).data()!;
    expect(config.plansVersion).toBe('2.1');
    expect(await staffReason(decideProposal(db, owner, { id, approve: true, reason }, now))).toBe(
      'decided',
    );
  });

  it('up to 50 credit applies at once; more waits for a second approver', async () => {
    const code = familyCode(familyId);
    expect(
      await adjustUsage(db, owner, { code, feature: 'lumi', amount: 10, reason }, now, 'test'),
    ).toMatchObject({ status: 'applied', before: 30, after: 40 });
    const big = await adjustUsage(
      db,
      owner,
      { code, feature: 'video', amount: 60, reason },
      now,
      'test',
    );
    expect(big.status).toBe('pending');
    let plan = await familyPlanAnswer(db, 'mom', { babyId }, now, 'test');
    expect(plan).toMatchObject({ lumi: { limit: 40 }, video: { limit: 2 } });
    await decideProposal(db, owner2, { id: big.id, approve: true, reason }, now, 'test');
    plan = await familyPlanAnswer(db, 'mom', { babyId }, now, 'test');
    expect(plan.video.limit).toBe(62);
    const history = await familyUsageHistory(db, 'mom', { babyId, kind: 'grants' }, now);
    expect(history.rows.map((r) => [r.task, r.amount])).toEqual(
      expect.arrayContaining([
        ['lumi.grant', 10],
        ['video.grant', 60],
      ]),
    );
  });

  it('a wrong video gets its lượt back once (PT04)', async () => {
    const code = familyCode(familyId);
    await db
      .doc(`families/${familyId}/quota/video_w`)
      .set({ feature: 'video', limit: 2, used: 1, reserved: 0 });
    await db
      .doc(`families/${familyId}/quotaOps/vr_1`)
      .set({ feature: 'video', windowId: 'video_w', state: 'committed', reservedAt: now });
    await db.doc(`babies/${babyId}/keepsakeJobs/job_1`).set({
      familyId,
      createdAt: now,
      quota: { reservationId: 'vr_1', windowId: 'video_w', seq: 0 },
    });
    const req = { code, job: renderJobCode('job_1'), reason };
    expect(await refundVideoJob(db, owner, req, now)).toEqual({ outcome: 'refunded' });
    expect(await refundVideoJob(db, owner, req, now)).toEqual({ outcome: 'already' });
    expect((await db.doc(`families/${familyId}/quota/video_w`).get()).get('used')).toBe(0);
    expect(await staffReason(refundVideoJob(db, eng, req, now))).toBe('role');
  });
});

describe('Gói: Free | Premium and Tổng quan Premium (owner, 2026-10-25)', () => {
  const owner: Staff = { uid: 's_owner', name: 'Owner', roles: ['owner'] };

  beforeEach(async () => {
    await db.doc(`familyDirectory/${familyId}`).set({ code: familyCode(familyId) });
    await v2(true);
  });

  it('one switch: Premium gives everything, Free takes every staff grant back', async () => {
    const code = familyCode(familyId);
    // An old promo grant on top of the switch.
    await db.doc(`families/${familyId}/grants/promo_old`).set({
      familyId,
      source: 'promo',
      status: 'active',
      environment: 'test',
      capabilities: ['templates.premium'],
      validFrom: new Date(now.getTime() - 86_400_000),
      validUntil: new Date(now.getTime() + 30 * 86_400_000),
      provider: 'staff',
    });
    await setFamilyPlan(db, owner, { code, plan: 'premium' }, now, 'test');
    let plan = await familyPlanAnswer(db, 'mom', { babyId }, now, 'test');
    expect(plan.plan).toBe('premium');
    let overview = await premiumOverview(db, owner, { range: '30d' }, now, 'test');
    expect(overview.families).toMatchObject({ total: 1, premium: 1, free: 0, granted: 1 });

    const r = await setFamilyPlan(db, owner, { code, plan: 'free' }, now, 'test');
    expect(r).toEqual({ plan: 'free', revoked: 2, paidRemains: false });
    plan = await familyPlanAnswer(db, 'mom', { babyId }, now, 'test');
    expect(plan.plan).toBe('free');
    overview = await premiumOverview(db, owner, { range: '30d' }, now, 'test');
    expect(overview.families).toMatchObject({ total: 1, premium: 0, free: 1, newInRange: 1 });
    expect(overview.revenue).toEqual({ gross: null, net: null, costPerPremium: null });
    expect(overview.trend).toHaveLength(5);
  });
});
