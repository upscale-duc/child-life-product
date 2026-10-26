import { randomUUID } from 'node:crypto';
import {
  defaultEntitlementsConfig,
  premiumCapabilities,
  type Flag,
  type FlagKey,
} from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { assistantPool } from '../functions/src/assistant-usage.js';
import {
  familyFeatureEnabled,
  getCapabilities,
  loadEntitlementContext,
  requireCapability,
} from '../functions/src/entitlements.js';
import { featureAccess } from '../functions/src/features.js';
import {
  featuresHub,
  hubFamily,
  setBetaFamily,
  setFeatureOverride,
  setFeatureRollout,
  setFeatureTier,
  setFullPremium,
} from '../functions/src/features-hub.js';
import { keepsakeView } from '../functions/src/keepsake-content.js';
import { grantPromo, revokeGrant, setEntitlementsConfig } from '../functions/src/premium-staff.js';
import { familyCode, setFlag, type Staff } from '../functions/src/staff.js';

// "Tính năng & Premium" hub (D-089 / P-172) and "no reasons" (D-090) against the Firestore
// emulator: the callables, and the app's answers (getCapabilities, featureAccess, server gates)
// following the one rule. Its own project; synthetic data only.
const projectId = 'demo-child-life-features-hub';
const now = new Date('2026-10-21T12:00:00Z');
const owner: Staff = { uid: 's_owner', name: 'Owner', roles: ['owner'] };
const ops: Staff = { uid: 's_ops', name: 'Vận hành', roles: ['ops'] };
const eng: Staff = { uid: 's_eng', name: 'Kỹ sư', roles: ['eng'] };
const support: Staff = { uid: 's_support', name: 'Hỗ trợ', roles: ['support'] };
const vn = familyCode('f_vn');
const us = familyCode('f_us');
let app: App;
let db: Firestore;

const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason,
  );
const flag = (over: Partial<Flag> = {}): Flag => ({
  enabled: true,
  scope: 'all',
  percent: 0,
  notice: null,
  ...over,
});
const setFlags = (over: Partial<Record<FlagKey, Flag>> = {}) =>
  db.doc('config/flags').set({
    rhythm: flag(),
    personalization: flag({ scope: 'internal' }),
    ai_assist: flag(),
    assistant: flag(),
    assistant_images: flag({ scope: 'internal' }),
    auto_save: flag({ scope: 'internal' }),
    milestone_cards: flag({ scope: 'internal' }),
    memory_story: flag({ scope: 'internal' }),
    ...over,
  });
const caps = (uid = 'mom', babyId = 'b_vn', at = now) =>
  getCapabilities(db, uid, { babyId }, at, 'test');
const allowed = (capability: Parameters<typeof requireCapability>[3], uid = 'mom', baby = 'b_vn') =>
  reason(requireCapability(db, uid, baby, capability, now, 'test'));
const access = (uid = 'mom', babyId = 'b_vn', at = now) => featureAccess(db, uid, { babyId }, at);
const audit = async (category = 'features') =>
  (await db.collection('staffAudit').where('category', '==', category).get()).docs.map((d) => ({
    action: d.get('action') as string,
    target: d.get('target') as string,
    reason: d.get('reason') as string,
  }));

async function family(id: string, babyId: string, uid: string, country: string, nickname: string) {
  await db.doc(`families/${id}`).set({
    ownerUid: uid,
    country,
    babyIds: [babyId],
    createdAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00Z')),
  });
  await db
    .doc(`familyDirectory/${id}`)
    .set({ code: familyCode(id), ownerMasked: `${uid[0]}***@example.com`, babies: 1 });
  await db.doc(`babies/${babyId}`).set({ familyId: id, nickname, state: 'active' });
  await db
    .doc(`babies/${babyId}/members/${uid}`)
    .set({ uid, babyId, role: 'coParent', isOwner: true, status: 'active' });
}

beforeAll(() => {
  app = initializeApp({ projectId }, `features-hub-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  for (const c of ['babies', 'families', 'config', 'familyDirectory', 'staffAudit']) {
    await db.recursiveDelete(db.collection(c));
  }
  await family('f_vn', 'b_vn', 'mom', 'VN', 'Bơ');
  await family('f_us', 'b_us', 'dad', 'US', 'Na');
  await db
    .doc('config/entitlements')
    .set({ ...defaultEntitlementsConfig, regions: { advanced: ['VN'] } });
  await setFlags();
});

describe('defaults: the hub changes nothing until staff change it', () => {
  it('a free family keeps today’s answers', async () => {
    const c = await caps();
    expect(c.features).toMatchObject({ rhythm: true, personalization: false, assistant: true });
    expect(c.features.assistantImages).toBe(false);
    expect(c.capabilities['personalization.cross_module']).toEqual({
      allowed: false,
      reason: 'FEATURE_DISABLED',
      via: null,
    });
    expect(c.capabilities['templates.premium'].reason).toBe('PREMIUM_REQUIRED');
    expect(c.capabilities['ai.assistance']).toEqual({ allowed: true, reason: null, via: 'free' });
    expect(await access()).toEqual({
      autoSave: false,
      milestoneCards: false,
      memoryStory: false,
      autoSaveBeta: true,
    });
  });
});

describe('"Bật toàn bộ Premium" (no reason, no end date)', () => {
  it('opens every Premium feature whatever the rollout and the country; Tắt revokes it', async () => {
    expect(await reason(setFullPremium(db, ops, { code: vn, on: true }, now, 'test'))).toBe('role');
    expect(await setFullPremium(db, owner, { code: vn, on: true }, now, 'test')).toEqual({
      on: true,
      until: null,
    });
    const c = await caps();
    expect(c).toMatchObject({ plan: 'premium', validUntil: null, provider: 'staff' });
    expect(c.features).toMatchObject({ personalization: true, assistantImages: true });
    expect(c.capabilities['personalization.cross_module']).toEqual({
      allowed: true,
      reason: null,
      via: 'promo',
    });
    expect(c.entitlementVersion).toBe(1);

    // An admin grant skips the country check (US is not an advanced region).
    await setFullPremium(db, owner, { code: us, on: true }, now, 'test');
    expect(await allowed('templates.premium', 'dad', 'b_us')).toBe('ok');
    expect(await allowed('rhythm.advanced', 'dad', 'b_us')).toBe('ok');
    expect((await caps('dad', 'b_us')).capabilities['assistant.premium_budget']).toEqual({
      allowed: true,
      reason: null,
      via: 'promo',
    });

    // The credit pool of a grant with no end runs month by month.
    const ctx = await loadEntitlementContext(db, 'mom', 'b_vn', now, 'test');
    const pool = await assistantPool(db, { familyId: 'f_vn', householdZone: 'UTC', ctx }, now);
    expect(pool.plan).toBe('premium');
    expect((pool.request.window as { periodEnd: Date }).periodEnd.toISOString().slice(0, 10)).toBe(
      '2026-11-01',
    );

    await setFullPremium(db, owner, { code: vn, on: false }, now, 'test');
    expect(await allowed('templates.premium')).toBe('PREMIUM_REQUIRED');
    expect(await allowed('rhythm.advanced')).toBe('FEATURE_DISABLED');
    expect((await audit('premium')).filter((a) => a.target === vn)).toEqual(
      expect.arrayContaining([
        { action: 'premium.full.on', target: vn, reason: '' },
        { action: 'premium.full.off', target: vn, reason: '' },
      ]),
    );
  });

  it('an optional end date ends it; a past one is refused', async () => {
    expect(
      await reason(
        setFullPremium(db, owner, { code: vn, on: true, until: '2026-10-01T00:00:00Z' }, now),
      ),
    ).toBe('bad-dates');
    const end = '2026-11-01T00:00:00.000Z';
    expect(
      await setFullPremium(db, owner, { code: vn, on: true, until: end }, now, 'test'),
    ).toEqual({ on: true, until: end });
    expect((await caps()).validUntil).toBe(end);
    expect(
      await reason(
        requireCapability(db, 'mom', 'b_vn', 'templates.premium', new Date(end), 'test'),
      ),
    ).toBe('PREMIUM_REQUIRED');
  });
});

describe('paid Premium keeps the region rule and skips the rollout', () => {
  it('in VN the paid family gets personalization (internal rollout); in the US it does not', async () => {
    const paid = (familyId: string) => ({
      familyId,
      source: 'paid',
      status: 'active',
      environment: 'test',
      capabilities: [...premiumCapabilities],
      validFrom: Timestamp.fromDate(new Date('2026-10-01T00:00:00Z')),
      validUntil: Timestamp.fromDate(new Date('2026-11-01T00:00:00Z')),
      billingOwnerUid: 'x',
      provider: 'apple',
      sourceRef: 'apple_1',
      campaignId: null,
      autoRenew: true,
      updatedAt: Timestamp.fromDate(new Date('2026-10-01T00:00:00Z')),
    });
    await db.doc('families/f_vn/grants/paid_1').set(paid('f_vn'));
    await db.doc('families/f_us/grants/paid_1').set(paid('f_us'));
    expect(await allowed('rhythm.advanced')).toBe('ok');
    expect((await caps()).features.personalization).toBe(true);
    expect(await allowed('templates.premium', 'dad', 'b_us')).toBe('REGION_UNAVAILABLE');
    expect(await allowed('rhythm.advanced', 'dad', 'b_us')).toBe('FEATURE_DISABLED');
    // The kill switch still wins (E08).
    await setFlags({ personalization: flag({ enabled: false }) });
    expect(await allowed('rhythm.advanced')).toBe('FEATURE_DISABLED');
  });
});

describe('overrides (Bật / Tắt / Theo quy tắc)', () => {
  it('reach getFeatureAccess, getCapabilities and the server gates; audited without a reason', async () => {
    expect(
      await reason(
        setFeatureOverride(db, ops, { code: vn, feature: 'auto_save', state: 'on' }, now),
      ),
    ).toBe('role');
    await setFeatureOverride(db, owner, { code: vn, feature: 'auto_save', state: 'on' }, now);
    await setFeatureOverride(db, owner, { code: vn, feature: 'memory_story', state: 'on' }, now);
    expect(await access()).toEqual({
      autoSave: true,
      milestoneCards: false,
      memoryStory: true,
      autoSaveBeta: true,
    });
    expect(await familyFeatureEnabled(db, 'f_vn', 'memory_story', now, 'test')).toBe(true);
    expect(await familyFeatureEnabled(db, 'f_us', 'memory_story', now, 'test')).toBe(false);

    await setFeatureOverride(db, owner, { code: vn, feature: 'rhythm', state: 'off' }, now);
    const c = await caps();
    expect(c.features.rhythm).toBe(false);
    expect(c.capabilities['rhythm.checkin'].reason).toBe('FEATURE_DISABLED');

    await setFeatureOverride(db, owner, { code: vn, feature: 'rhythm', state: null }, now);
    expect((await caps()).features.rhythm).toBe(true);
    // Per family: the other household is untouched.
    expect((await access('dad', 'b_us')).autoSave).toBe(false);

    const stored = (await db.doc('families/f_vn/featureOverrides/auto_save').get()).data()!;
    expect(stored).toMatchObject({
      feature: 'auto_save',
      state: 'on',
      until: null,
      byName: 'Owner',
    });
    expect((await db.doc('families/f_vn').get()).get('entitlementVersion')).toBe(4);
    expect((await audit()).map((a) => [a.action, a.target, a.reason]).sort()).toEqual([
      ['hub.override', vn, ''],
      ['hub.override', vn, ''],
      ['hub.override', vn, ''],
      ['hub.override.clear', vn, ''],
    ]);
  });

  it('an override with an end stops at it; a past end is refused', async () => {
    expect(
      await reason(
        setFeatureOverride(
          db,
          owner,
          { code: vn, feature: 'auto_save', state: 'on', until: '2026-10-20T00:00:00Z' },
          now,
        ),
      ),
    ).toBe('bad-dates');
    await setFeatureOverride(
      db,
      owner,
      { code: vn, feature: 'auto_save', state: 'on', until: '2026-10-22T00:00:00Z' },
      now,
    );
    expect((await access()).autoSave).toBe(true);
    expect((await access('mom', 'b_vn', new Date('2026-10-22T00:00:00Z'))).autoSave).toBe(false);
  });
});

describe('tier (Gói) with the 30-day grace', () => {
  it('a dry run counts; moving to Premium keeps who had it for 30 days, not new families', async () => {
    await setFlags({ auto_save: flag({ scope: 'all' }) });
    expect((await access()).autoSave).toBe(true);
    expect(
      await reason(setFeatureTier(db, support, { feature: 'auto_save', tier: 'premium' }, now)),
    ).toBe('role');
    const dry = await setFeatureTier(
      db,
      eng,
      { feature: 'auto_save', tier: 'premium', dryRun: true },
      now,
      'test',
    );
    expect(dry).toEqual({
      feature: 'auto_save',
      from: 'beta',
      tier: 'premium',
      affected: 2,
      graceUntil: '2026-11-20T12:00:00.000Z',
      applied: false,
    });
    expect((await db.doc('config/features').get()).exists).toBe(false);

    const done = await setFeatureTier(db, eng, { feature: 'auto_save', tier: 'premium' }, now);
    expect(done).toMatchObject({ applied: true, affected: 2 });
    expect((await access()).autoSave).toBe(true);
    // A family created after the move is not in the grace.
    await family('f_new', 'b_new', 'newmom', 'VN', 'Mít');
    await db
      .doc('families/f_new')
      .set({ createdAt: Timestamp.fromDate(new Date('2026-10-21T13:00:00Z')) }, { merge: true });
    expect((await access('newmom', 'b_new', new Date('2026-10-21T14:00:00Z'))).autoSave).toBe(
      false,
    );
    // After the grace only Premium families keep it.
    const later = new Date('2026-11-21T00:00:00Z');
    expect((await access('mom', 'b_vn', later)).autoSave).toBe(false);
    await setFullPremium(db, owner, { code: vn, on: true }, now, 'test');
    expect((await access('mom', 'b_vn', later)).autoSave).toBe(true);

    // Back to Beta: the grace ends, the rollout decides again.
    await setFeatureTier(db, owner, { feature: 'auto_save', tier: 'beta' }, now);
    expect((await db.doc('config/features').get()).get('features.auto_save')).toMatchObject({
      tier: 'beta',
      grace: null,
    });
    expect((await audit()).filter((a) => a.action === 'hub.tier')).toEqual([
      { action: 'hub.tier', target: 'auto_save', reason: '' },
      { action: 'hub.tier', target: 'auto_save', reason: '' },
    ]);
  });

  it('a Premium feature made free opens to everyone in its rollout', async () => {
    expect(await allowed('templates.premium')).toBe('PREMIUM_REQUIRED');
    await setFeatureTier(db, owner, { feature: 'templates_premium', tier: 'free' }, now);
    expect(await allowed('templates.premium')).toBe('ok');
    expect((await caps()).capabilities['templates.premium'].via).toBe('free');
  });
});

describe('rollout and beta from the hub', () => {
  it('Thêm vào beta works whatever the scope; the rollout goes through the flag', async () => {
    expect((await access()).milestoneCards).toBe(false);
    await setBetaFamily(db, owner, { code: vn, feature: 'milestone_cards', member: true }, now);
    expect((await access()).milestoneCards).toBe(true);
    expect((await access('dad', 'b_us')).milestoneCards).toBe(false);
    await setBetaFamily(db, owner, { code: vn, feature: 'milestone_cards', member: false }, now);
    expect((await access()).milestoneCards).toBe(false);

    await setFeatureRollout(db, owner, { feature: 'milestone_cards', betaFamilies: [us] }, now);
    expect((await access('dad', 'b_us')).milestoneCards).toBe(true);

    // Phát hành: scope only (no reason); the kill switch needs the Kỹ thuật level.
    expect(
      await reason(setFeatureRollout(db, ops, { feature: 'milestone_cards', scope: 'all' }, now)),
    ).toBe('role');
    expect(
      await reason(setFeatureRollout(db, eng, { feature: 'milestone_cards', scope: 'all' }, now)),
    ).toBe('ok');
    expect((await access()).milestoneCards).toBe(true);
    expect(
      await reason(
        setFeatureRollout(
          db,
          eng,
          { feature: 'assistant', flag: 'assistant_images', scope: 'all' },
          now,
        ),
      ),
    ).toBe('ok');
    expect((await caps()).features.assistantImages).toBe(true);
    expect(
      await reason(
        setFeatureRollout(db, eng, { feature: 'rhythm', flag: 'assistant', enabled: false }, now),
      ),
    ).toBe('no-flag');
    expect(
      await reason(setFeatureRollout(db, eng, { feature: 'templates_premium', scope: 'all' }, now)),
    ).toBe('no-flag');
    await setFeatureRollout(db, eng, { feature: 'milestone_cards', enabled: false }, now);
    expect((await access()).milestoneCards).toBe(false);
    const flags = (await db.doc('config/flags').get()).data()!;
    expect(flags.milestone_cards).toMatchObject({ enabled: false, scope: 'all' });
  });
});

describe('the hub and the family view', () => {
  it('lists every catalogue feature with tier, rollout, kill switch and counts', async () => {
    await setFullPremium(db, owner, { code: vn, on: true }, now, 'test');
    await setFeatureOverride(db, owner, { code: us, feature: 'auto_save', state: 'on' }, now);
    await setFeatureOverride(db, owner, { code: vn, feature: 'rhythm', state: 'off' }, now);
    await setBetaFamily(db, owner, { code: us, feature: 'memory_story', member: true }, now);
    expect(await reason(featuresHub(db, null, now))).toBe('not-staff');
    const hub = await featuresHub(db, ops, now, 'test');
    expect(hub.features.map((f) => f.key)).toHaveLength(9);
    const autoSave = hub.features.find((f) => f.key === 'auto_save')!;
    expect(autoSave).toMatchObject({
      tier: 'beta',
      group: 'keepsakes',
      flag: { key: 'auto_save', enabled: true, scope: 'internal' },
      overrides: { on: 1, off: 0 },
    });
    expect(hub.features.find((f) => f.key === 'memory_story')!.betaFamilies).toEqual([us]);
    expect(hub.features.find((f) => f.key === 'templates_premium')!.flag).toBeNull();
    expect(hub.features.find((f) => f.key === 'assistant')!.subFlags.map((f) => f.key)).toEqual([
      'assistant_images',
      'assistant_care',
      'assistant_upsell',
    ]);
    expect(hub.premium).toMatchObject({ families: 1, admin: 1, full: 1, paid: 0 });
    expect(hub.systemFlags).toEqual(expect.arrayContaining(['media_upload', 'assistant_live']));
    expect(hub.recent.map((r) => r.action)).toEqual(
      expect.arrayContaining(['hub.override', 'hub.beta.add', 'premium.full.on']),
    );
    expect(JSON.stringify(hub)).not.toContain('f_vn');
  });

  it('finds a family by code, email or baby nickname and explains every feature', async () => {
    await setFeatureOverride(db, owner, { code: vn, feature: 'auto_save', state: 'on' }, now);
    const deps = { uidByEmail: async (e: string) => (e === 'mom@example.com' ? 'mom' : null) };
    expect(await reason(hubFamily(db, support, { q: vn }, now, deps))).toBe('role');
    const byCode = await hubFamily(db, ops, { q: vn.toLowerCase() }, now, deps, 'test');
    expect(byCode.matchedBy).toBe('code');
    expect(byCode.matches).toEqual([{ code: vn, owner: 'm***@example.com', babies: 1 }]);
    const f = byCode.family!;
    expect(f).toMatchObject({ code: vn, country: 'VN', regionSupported: true, plan: 'free' });
    const by = Object.fromEntries(f.features.map((x) => [x.key, x]));
    expect(by.auto_save).toMatchObject({ on: true, why: 'override_on', override: { state: 'on' } });
    expect(by.rhythm).toMatchObject({ on: true, why: 'free' });
    expect(by.personalization).toMatchObject({ on: false, why: 'not_released', visible: false });
    expect(by.templates_premium).toMatchObject({
      on: false,
      why: 'premium_required',
      visible: true,
    });
    expect(by.ai_assist).toMatchObject({ on: true, why: 'credits' });
    expect(by.milestone_cards).toMatchObject({ on: false, why: 'not_in_beta' });

    expect((await hubFamily(db, ops, { q: 'Mom@Example.com' }, now, deps)).family?.code).toBe(vn);
    const byName = await hubFamily(db, ops, { q: 'bơ' }, now, deps);
    expect(byName).toMatchObject({ matchedBy: 'nickname', matches: [{ code: vn }] });
    expect(JSON.stringify(byName)).not.toContain('Bơ');
    expect((await hubFamily(db, ops, { q: 'không có' }, now, deps)).matches).toEqual([]);
    // The same nickname in two families: both listed, no detail until one is picked.
    await db.doc('babies/b_us').set({ nickname: 'Bơ' }, { merge: true });
    const two = await hubFamily(db, ops, { q: 'Bơ' }, now, deps);
    expect(two.matches.map((m) => m.code).sort()).toEqual([vn, us].sort());
    expect(two.family).toBeNull();
    // A US family with "toàn bộ Premium": the view says Premium (admin), with no end date.
    await setFullPremium(db, owner, { code: us, on: true }, now, 'test');
    const usView = (await hubFamily(db, ops, { q: us }, now, deps, 'test')).family!;
    expect(usView).toMatchObject({
      regionSupported: false,
      plan: 'premium',
      validUntil: null,
      fullPremium: { on: true, until: null },
    });
    expect(usView.features.find((x) => x.key === 'personalization')).toMatchObject({
      on: true,
      why: 'premium_admin',
    });
  });
});

describe('D-090: the old callables accept a missing reason and audit ""', () => {
  it('flags, Premium config, promo grant and revoke', async () => {
    await setFlag(
      db,
      eng,
      { key: 'rhythm', enabled: true, scope: 'all', percent: 0, notice: null },
      now,
    );
    await setEntitlementsConfig(
      db,
      eng,
      { config: { ...defaultEntitlementsConfig, regions: { advanced: ['VN'] } } },
      now,
    );
    const { grantId } = await grantPromo(
      db,
      owner,
      { code: vn, capabilities: ['templates.premium'], validUntil: '2026-11-01T00:00:00Z' },
      now,
      'test',
    );
    await revokeGrant(db, owner, { code: vn, grantId }, now);
    const lines = [...(await audit('features')), ...(await audit('premium'))];
    expect(lines.map((l) => l.action).sort()).toEqual([
      'flags.rollout',
      'premium.config',
      'premium.grant',
      'premium.revoke',
    ]);
    expect(lines.every((l) => l.reason === '')).toBe(true);
  });
});

describe('Mẫu kỷ niệm: videos exported per template', () => {
  it('counts completed render jobs all time and in the last 30 days', async () => {
    const job = (id: string, templateId: string, status: string, finishedDaysAgo: number) =>
      db.doc(`babies/b_vn/keepsakeJobs/${id}`).set({
        familyId: 'f_vn',
        templateId,
        status,
        createdAt: Timestamp.fromDate(new Date(now.getTime() - (finishedDaysAgo + 1) * 86_400_000)),
        finishedAt: Timestamp.fromDate(new Date(now.getTime() - finishedDaysAgo * 86_400_000)),
      });
    await job('j1', 'tpl_a', 'completed', 1);
    await job('j2', 'tpl_a', 'completed', 40);
    await job('j3', 'tpl_b', 'failed', 2);
    await job('j4', 'tpl_b', 'completed', 2);
    await job('j5', 'tpl_c', 'rendering', 0);
    const assets = {
      list: async () => [],
      publicUrl: (a: string) => a,
    } as unknown as Parameters<typeof keepsakeView>[1]['assets'];
    const view = await keepsakeView(db, { assets }, ops, now);
    expect(view.usage).toEqual({
      tpl_a: { exports: 2, exports30d: 1 },
      tpl_b: { exports: 1, exports30d: 1 },
    });
    expect(view.usageCapped).toBe(false);
  });
});
