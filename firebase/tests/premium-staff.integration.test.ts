import { randomUUID } from 'node:crypto';
import { defaultEntitlementsConfig, defaultFlags } from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { requireCapability } from '../functions/src/entitlements.js';
import {
  familyPremium,
  grantPromo,
  readPremium,
  revokeGrant,
  setEntitlementsConfig,
} from '../functions/src/premium-staff.js';
import { familyCode, type Staff } from '../functions/src/staff.js';

// Portal "Premium" (plan §5.6, E3): campaigns, promo grants, audit. Own project; synthetic data.
const projectId = 'demo-child-life-premium-staff';
const now = new Date('2026-10-14T12:00:00Z');
const owner: Staff = { uid: 's_owner', name: 'Owner', roles: ['owner'] };
const ops: Staff = { uid: 's_ops', name: 'Vận hành', roles: ['ops'] };
const eng: Staff = { uid: 's_eng', name: 'Kỹ sư', roles: ['eng'] };
const support: Staff = { uid: 's_support', name: 'Hỗ trợ', roles: ['support'] };
const familyId = 'test_f1';
const code = familyCode(familyId);
let app: App;
let db: Firestore;

const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason,
  );
const campaign = {
  id: 'beta-a',
  capabilities: ['personalization.cross_module', 'rhythm.advanced', 'ai.assistance'] as const,
  validFrom: '2026-10-01T00:00:00Z',
  validUntil: '2026-12-01T00:00:00Z',
  countries: [],
  scope: 'internal' as const,
  percent: 0,
  families: [code],
};

beforeAll(() => {
  app = initializeApp({ projectId }, `premium-staff-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  for (const c of ['babies', 'families', 'config', 'familyDirectory', 'staffAudit']) {
    await db.recursiveDelete(db.collection(c));
  }
  await db.doc(`familyDirectory/${familyId}`).set({ code });
  await db
    .doc(`families/${familyId}`)
    .set({ ownerUid: 'test_mom', country: 'VN', babyIds: ['test_b1'] });
  await db.doc('babies/test_b1').set({ familyId });
  await db
    .doc('babies/test_b1/members/test_mom')
    .set({ role: 'coParent', isOwner: true, status: 'active' });
  const on = { ...defaultFlags.personalization, enabled: true, scope: 'all' };
  await db.doc('config/flags').set({ personalization: on, ai_assist: on, rhythm: on });
});

describe('config/entitlements from the portal', () => {
  it('eng saves regions and a campaign by family code; ids stay on the server; audit written', async () => {
    const config = {
      ...defaultEntitlementsConfig,
      regions: { advanced: ['VN'] },
      betaCampaigns: [campaign],
    };
    await setEntitlementsConfig(db, eng, { config, reason: 'Mở beta A cho nhóm thử' }, now);
    const stored = (await db.doc('config/entitlements').get()).data()!;
    expect(stored.betaCampaigns[0].families).toEqual([familyId]);
    const read = await readPremium(db, ops);
    expect(read.config.betaCampaigns[0]!.families).toEqual([code]);
    expect(read.recent[0]).toMatchObject({
      action: 'premium.config',
      reason: 'Mở beta A cho nhóm thử',
    });
    expect(
      await reason(requireCapability(db, 'test_mom', 'test_b1', 'rhythm.advanced', now, 'test')),
    ).toBe('ok');
  });

  it('refuses support staff, unknown codes, bad dates and a campaign with a free capability', async () => {
    const config = {
      ...defaultEntitlementsConfig,
      regions: { advanced: ['VN'] },
      betaCampaigns: [campaign],
    };
    expect(await reason(setEntitlementsConfig(db, support, { config, reason: 'x x x' }, now))).toBe(
      'role',
    );
    expect(
      await reason(
        setEntitlementsConfig(
          db,
          eng,
          {
            config: { ...config, betaCampaigns: [{ ...campaign, families: ['F-ZZZZ'] }] },
            reason: 'thử',
          },
          now,
        ),
      ),
    ).toBe('family-not-found');
    expect(
      await reason(
        setEntitlementsConfig(
          db,
          eng,
          {
            config: { ...config, betaCampaigns: [{ ...campaign, validUntil: campaign.validFrom }] },
            reason: 'thử lại',
          },
          now,
        ),
      ),
    ).toBe('bad-dates');
    expect(
      await reason(
        setEntitlementsConfig(
          db,
          eng,
          {
            config: {
              ...config,
              betaCampaigns: [
                // D-075 #1: templates are allowed in a beta now; a free capability never is.
                { ...campaign, capabilities: [...campaign.capabilities, 'rhythm.checkin'] },
              ],
            },
            reason: 'thử lại',
          },
          now,
        ),
      ),
    ).toBe('malformed');
    // D-075 #1: a beta campaign may open every Premium feature (templates, the credit budget).
    const all = {
      ...config,
      betaCampaigns: [
        {
          ...campaign,
          capabilities: [...campaign.capabilities, 'templates.premium', 'assistant.premium_budget'],
        },
      ],
    };
    expect(
      await reason(setEntitlementsConfig(db, eng, { config: all, reason: 'beta đủ Premium' }, now)),
    ).toBe('ok');
    expect(
      (await db.doc('config/entitlements').get()).get('betaCampaigns')[0].capabilities,
    ).toEqual(expect.arrayContaining(['templates.premium', 'assistant.premium_budget']));
  });
});

describe('promo grants', () => {
  it('only owner / admin grant; the family gets templates; revoking ends it; audit both', async () => {
    await db
      .doc('config/entitlements')
      .set({ ...defaultEntitlementsConfig, regions: { advanced: ['VN'] } });
    const req = {
      code,
      capabilities: ['templates.premium'],
      validUntil: '2026-11-14T00:00:00Z',
      reason: 'Đối tác thử mẫu Cao cấp',
    };
    expect(await reason(grantPromo(db, ops, req, now, 'test'))).toBe('role');
    const { grantId } = await grantPromo(db, owner, req, now, 'test');
    expect(
      await reason(requireCapability(db, 'test_mom', 'test_b1', 'templates.premium', now, 'test')),
    ).toBe('ok');
    const view = await familyPremium(db, ops, { code }, now, 'test');
    expect(view).toMatchObject({ code, plan: 'premium', entitlementVersion: 1, country: 'VN' });
    expect(view.grants[0]).toMatchObject({
      id: grantId,
      source: 'promo',
      provider: 'staff',
      fromCampaign: false,
    });

    await revokeGrant(db, owner, { code, grantId, reason: 'Hết thời gian thử' }, now);
    expect(
      await reason(requireCapability(db, 'test_mom', 'test_b1', 'templates.premium', now, 'test')),
    ).toBe('PREMIUM_REQUIRED');
    const audit = await db.collection('staffAudit').where('category', '==', 'premium').get();
    expect(audit.docs.map((d) => d.get('action')).sort()).toEqual([
      'premium.grant',
      'premium.revoke',
    ]);
    expect((await db.doc(`families/${familyId}`).get()).get('entitlementVersion')).toBe(2);
  });

  it('free capabilities, past dates and more than a year are refused; paid grants cannot be revoked', async () => {
    const req = { code, capabilities: ['templates.premium'], reason: 'thử nghiệm' };
    expect(
      await reason(
        grantPromo(
          db,
          owner,
          { ...req, capabilities: ['rhythm.checkin'], validUntil: '2026-11-01T00:00:00Z' },
          now,
        ),
      ),
    ).toBe('malformed');
    expect(
      await reason(grantPromo(db, owner, { ...req, validUntil: '2026-10-01T00:00:00Z' }, now)),
    ).toBe('bad-dates');
    expect(
      await reason(grantPromo(db, owner, { ...req, validUntil: '2028-01-01T00:00:00Z' }, now)),
    ).toBe('bad-dates');
    await db
      .doc(`families/${familyId}/grants/promo_paidlike`)
      .set({ source: 'paid', status: 'active' });
    expect(
      await reason(
        revokeGrant(db, owner, { code, grantId: 'promo_paidlike', reason: 'không được' }, now),
      ),
    ).toBe('paid-grant');
  });

  it('a family view lists open campaign grants as not revocable', async () => {
    await db.doc('config/entitlements').set({
      ...defaultEntitlementsConfig,
      regions: { advanced: ['VN'] },
      betaCampaigns: [{ ...campaign, families: [familyId] }],
    });
    const view = await familyPremium(db, ops, { code }, now, 'test');
    expect(view.plan).toBe('beta');
    expect(view.grants).toEqual([
      expect.objectContaining({ id: 'campaign:beta-a', source: 'beta', fromCampaign: true }),
    ]);
  });
});
