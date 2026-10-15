import { randomUUID } from 'node:crypto';
import {
  defaultEntitlementsConfig,
  defaultFlags,
  premiumCapabilities,
} from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  getCapabilities,
  requireCapability,
  setFamilySettings,
} from '../functions/src/entitlements.js';

// Premium & Cá nhân hoá: the capability resolver against the Firestore emulator (plan §5.1,
// integration matrix M01, M02, M05, M08, M09). Its own project: it rewrites `config/*`.
// Synthetic data only, `test_` ids (fixture pack rule).
const projectId = 'demo-child-life-entitlements';
const now = new Date('2026-10-14T12:00:00Z');
let app: App;
let db: Firestore;

const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason,
  );
const on = (scope: 'all' | 'internal' = 'all') => ({
  ...defaultFlags.rhythm,
  enabled: true,
  scope,
});
const ts = (iso: string) => Timestamp.fromDate(new Date(iso));
const paidGrant = (over: Record<string, unknown> = {}) => ({
  familyId: 'test_f1',
  source: 'paid',
  status: 'active',
  environment: 'test',
  capabilities: [...premiumCapabilities],
  validFrom: ts('2026-10-01T00:00:00Z'),
  validUntil: ts('2026-11-01T00:00:00Z'),
  billingOwnerUid: 'test_mom',
  provider: 'apple',
  sourceRef: 'apple_test_1',
  campaignId: null,
  autoRenew: true,
  updatedAt: ts('2026-10-01T00:00:00Z'),
  ...over,
});
const betaA = {
  id: 'beta-a',
  capabilities: ['personalization.cross_module', 'rhythm.advanced', 'ai.assistance'],
  validFrom: '2026-10-01T00:00:00Z',
  validUntil: '2026-10-20T00:00:00Z',
  countries: [],
  scope: 'all',
  percent: 0,
};
const allowed = (uid: string, capability: Parameters<typeof requireCapability>[3], at = now) =>
  reason(requireCapability(db, uid, 'test_b1', capability, at, 'test'));

beforeAll(() => {
  app = initializeApp({ projectId }, `entitlements-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  for (const c of ['babies', 'families', 'config']) {
    await db.recursiveDelete(db.collection(c));
  }
  await db.doc('config/flags').set({
    rhythm: on(),
    personalization: on(),
    ai_assist: on(),
    memory_story: on(),
  });
  await db
    .doc('config/entitlements')
    .set({ ...defaultEntitlementsConfig, regions: { advanced: ['VN'] } });
  await db.doc('babies/test_b1').set({ familyId: 'test_f1' });
  await db.doc('families/test_f1').set({ ownerUid: 'test_mom', country: 'VN' });
  await db
    .doc('babies/test_b1/members/test_mom')
    .set({ role: 'coParent', isOwner: true, status: 'active' });
  await db.doc('babies/test_b1/members/test_dad').set({ role: 'coParent', status: 'active' });
  await db.doc('babies/test_b1/members/test_nanny').set({ role: 'caregiver', status: 'active' });
  await db.doc('babies/test_b1/members/test_grandma').set({
    role: 'relative',
    status: 'active',
    extraRights: { viewBabyInfo: false, viewDailyCare: true },
  });
  await db.doc('babies/test_b1/members/test_left').set({
    role: 'coParent',
    status: 'active',
    accessUntilAt: ts('2026-10-10T00:00:00Z'),
  });
});

describe('M01 · free family', () => {
  it('advanced is PREMIUM_REQUIRED; check-in, health, history and video budget stay open', async () => {
    expect(await allowed('test_mom', 'personalization.cross_module')).toBe('PREMIUM_REQUIRED');
    expect(await allowed('test_mom', 'ai.assistance')).toBe('PREMIUM_REQUIRED');
    expect(await allowed('test_mom', 'templates.premium')).toBe('PREMIUM_REQUIRED');
    for (const c of [
      'rhythm.checkin',
      'health.guidance',
      'history.read',
      'render.video',
    ] as const) {
      expect(await allowed('test_mom', c)).toBe('ok');
    }
  });

  it('getCapabilities says free and explains each gate', async () => {
    const a = await getCapabilities(db, 'test_mom', { babyId: 'test_b1' }, now, 'test');
    expect(a).toMatchObject({
      plan: 'free',
      country: 'VN',
      canManageBilling: true,
      isBillingOwner: false,
      features: {
        rhythm: true,
        personalization: true,
        aiAssist: true,
        billing: false,
        assistant: false,
        assistantImages: false,
        assistantCare: false,
        assistantUpsell: false,
      },
    });
    expect(a.capabilities['rhythm.checkin']).toEqual({ allowed: true, reason: null, via: 'free' });
    expect(a.capabilities['rhythm.advanced']).toEqual({
      allowed: false,
      reason: 'PREMIUM_REQUIRED',
      via: null,
    });
  });
});

describe('M02 · roles are not changed by Premium (D-072 #2)', () => {
  beforeEach(async () => {
    await db.doc('families/test_f1/grants/paid_1').set(paidGrant());
  });

  it('a relative is ROLE_DENIED for AI / suggestions / render but still reads history', async () => {
    expect(await allowed('test_grandma', 'ai.assistance')).toBe('ROLE_DENIED');
    expect(await allowed('test_grandma', 'personalization.cross_module')).toBe('ROLE_DENIED');
    expect(await allowed('test_grandma', 'render.video')).toBe('ROLE_DENIED');
    expect(await allowed('test_grandma', 'history.read')).toBe('ok');
    expect(await allowed('test_grandma', 'health.guidance')).toBe('ok');
  });

  it('a caregiver gets suggestions and checks in, but cannot generate AI', async () => {
    expect(await allowed('test_nanny', 'personalization.cross_module')).toBe('ok');
    expect(await allowed('test_nanny', 'rhythm.checkin')).toBe('ok');
    expect(await allowed('test_nanny', 'ai.assistance')).toBe('ROLE_DENIED');
  });

  it('only the owner may manage billing; everyone sees the household plan', async () => {
    const dad = await getCapabilities(db, 'test_dad', { babyId: 'test_b1' }, now, 'test');
    expect(dad).toMatchObject({ plan: 'premium', canManageBilling: false, isBillingOwner: false });
    const mom = await getCapabilities(db, 'test_mom', { babyId: 'test_b1' }, now, 'test');
    expect(mom).toMatchObject({
      plan: 'premium',
      canManageBilling: true,
      isBillingOwner: true,
      provider: 'apple',
    });
  });

  it('ended access and strangers are NOT_MEMBER', async () => {
    expect(await allowed('test_left', 'history.read')).toBe('NOT_MEMBER');
    expect(await allowed('test_stranger', 'history.read')).toBe('NOT_MEMBER');
    expect(await reason(getCapabilities(db, 'test_left', { babyId: 'test_b1' }, now, 'test'))).toBe(
      'not-a-member',
    );
  });
});

describe('grants, beta and environment', () => {
  it('beta A opens group A only, never templates (E03), and only in a supported country', async () => {
    await db.doc('config/entitlements').set({
      ...defaultEntitlementsConfig,
      regions: { advanced: ['VN'] },
      betaCampaigns: [betaA],
    });
    expect(await allowed('test_mom', 'rhythm.advanced')).toBe('ok');
    expect(await allowed('test_mom', 'templates.premium')).toBe('PREMIUM_REQUIRED');
    const a = await getCapabilities(db, 'test_mom', { babyId: 'test_b1' }, now, 'test');
    expect(a).toMatchObject({ plan: 'beta', validUntil: '2026-10-20T00:00:00.000Z' });

    await db.doc('families/test_f1').set({ country: 'DE' }, { merge: true });
    expect(await allowed('test_mom', 'rhythm.advanced')).toBe('REGION_UNAVAILABLE');
    expect(await allowed('test_mom', 'rhythm.checkin')).toBe('ok');
  });

  it('M09 · after the beta ends, new advanced requests are gated; free stays', async () => {
    await db.doc('config/entitlements').set({
      ...defaultEntitlementsConfig,
      regions: { advanced: ['VN'] },
      betaCampaigns: [betaA],
    });
    const after = new Date('2026-10-20T00:00:00Z');
    expect(await allowed('test_mom', 'rhythm.advanced', after)).toBe('PREMIUM_REQUIRED');
    expect(await allowed('test_mom', 'history.read', after)).toBe('ok');
  });

  it('no country yet: advanced is REGION_UNAVAILABLE, free works (D-072 #3)', async () => {
    await db.doc('families/test_f1').set({ ownerUid: 'test_mom' });
    await db.doc('families/test_f1/grants/paid_1').set(paidGrant());
    expect(await allowed('test_mom', 'rhythm.advanced')).toBe('REGION_UNAVAILABLE');
    expect(await allowed('test_mom', 'rhythm.checkin')).toBe('ok');
  });

  it('M05 · auto-renew off keeps access until validUntil (exclusive)', async () => {
    await db.doc('families/test_f1/grants/paid_1').set(paidGrant({ autoRenew: false }));
    expect(await allowed('test_mom', 'templates.premium')).toBe('ok');
    expect(await allowed('test_mom', 'templates.premium', new Date('2026-11-01T00:00:00Z'))).toBe(
      'PREMIUM_REQUIRED',
    );
  });

  it('M08 · a sandbox grant never counts on production; a revoked one gives nothing (E11)', async () => {
    await db.doc('families/test_f1/grants/paid_1').set(paidGrant());
    expect(
      await reason(
        requireCapability(db, 'test_mom', 'test_b1', 'templates.premium', now, 'production'),
      ),
    ).toBe('PREMIUM_REQUIRED');
    await db.doc('families/test_f1/grants/paid_1').set(paidGrant({ status: 'revoked' }));
    expect(await allowed('test_mom', 'templates.premium')).toBe('PREMIUM_REQUIRED');
  });

  it('a malformed grant document is ignored, not trusted', async () => {
    await db
      .doc('families/test_f1/grants/bad')
      .set({ source: 'paid', capabilities: ['templates.premium'] });
    expect(await allowed('test_mom', 'templates.premium')).toBe('PREMIUM_REQUIRED');
  });

  it('kill switch: personalization off → FEATURE_DISABLED even when paid (E08)', async () => {
    await db.doc('families/test_f1/grants/paid_1').set(paidGrant());
    await db
      .doc('config/flags')
      .set({ rhythm: on(), personalization: { ...on(), enabled: false } });
    expect(await allowed('test_mom', 'rhythm.advanced')).toBe('FEATURE_DISABLED');
    expect(await allowed('test_mom', 'templates.premium')).toBe('ok');
  });
});

describe('setFamilySettings (D-072 #1, #3)', () => {
  it('the owner sets country and time zone; others are refused', async () => {
    expect(
      await setFamilySettings(
        db,
        'test_mom',
        { babyId: 'test_b1', country: 'SG', timeZone: 'Asia/Singapore' },
        now,
      ),
    ).toEqual({ country: 'SG', timeZone: 'Asia/Singapore' });
    const family = (await db.doc('families/test_f1').get()).data();
    expect(family).toMatchObject({
      country: 'SG',
      timeZone: 'Asia/Singapore',
      ownerUid: 'test_mom',
    });
    expect(
      await reason(setFamilySettings(db, 'test_dad', { babyId: 'test_b1', country: 'VN' }, now)),
    ).toBe('ROLE_DENIED');
    expect(
      await reason(setFamilySettings(db, 'test_mom', { babyId: 'test_b1', country: 'vn' }, now)),
    ).toBe('bad-request');
    expect(
      await reason(
        setFamilySettings(db, 'test_mom', { babyId: 'test_b1', timeZone: 'Mars/Base' }, now),
      ),
    ).toBe('bad-request');
  });
});
