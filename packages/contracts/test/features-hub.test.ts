import { describe, expect, it } from 'vitest';
import {
  activeOverride,
  appUpdateEmpty,
  appUpdateSaveSchema,
  capabilities,
  capabilityFlag,
  catalogueFeature,
  decideFeature,
  defaultFlags,
  familyFeatureDecision,
  featureCatalogue,
  featureGateReason,
  featureKeys,
  featureOfCapability,
  featureOfFlag,
  featurePremium,
  featuresConfigSchema,
  featureTierOf,
  featureVisible,
  flagKeys,
  grantPromoSchema,
  hubFullPremiumSchema,
  hubSetOverrideSchema,
  hubSetTierSchema,
  inFeatureGrace,
  isOpenEndedUntil,
  keepsakeActSchema,
  OPEN_ENDED_GRANT_UNTIL,
  premiumCapabilities,
  resolveFeatureCapability,
  setContentPolicyRequestSchema,
  setFlagSchema,
  staffReasonSchema,
  systemFlagKeys,
  type CapabilityCheck,
  type FamilyFeatureFacts,
  type FeatureGrace,
  type FeatureRuleInput,
  type Flags,
  type GrantView,
} from '../src/index.js';

const now = new Date('2026-10-21T12:00:00Z');
const base: FeatureRuleInput = {
  tier: 'premium',
  killSwitchOn: true,
  rolloutOn: false,
  override: null,
  paid: false,
  staff: false,
  betaGrant: false,
  regionSupported: true,
  regionApplies: true,
  betaListed: false,
  grace: false,
  credits: false,
};
const why = (over: Partial<FeatureRuleInput>) => decideFeature({ ...base, ...over });
const grant = (over: Partial<GrantView> = {}): GrantView => ({
  source: 'paid',
  status: 'active',
  environment: 'test',
  capabilities: [...premiumCapabilities],
  validFrom: new Date('2026-10-01T00:00:00Z'),
  validUntil: new Date('2026-11-01T00:00:00Z'),
  ...over,
});

describe('catalogue v1 (plan §2.1)', () => {
  it('has the nine features with the plan’s default tiers and portal message ids', () => {
    expect(featureCatalogue.map((f) => [f.key, f.defaultTier])).toEqual([
      ['rhythm', 'free'],
      ['personalization', 'premium'],
      ['ai_assist', 'premium'],
      ['assistant', 'premium'],
      ['templates_premium', 'premium'],
      ['milestone_cards', 'beta'],
      ['memory_story', 'beta'],
      ['auto_save', 'beta'],
      ['ai_story_drafts', 'beta'],
    ]);
    expect(featureCatalogue.map((f) => f.key)).toEqual([...featureKeys]);
    expect(catalogueFeature('rhythm')).toMatchObject({
      labelId: 'hub.feature.rhythm',
      helpId: 'hub.feature.rhythm.help',
      group: 'personalization',
      tierable: true,
    });
    expect(featureCatalogue.filter((f) => f.credits).map((f) => f.key)).toEqual([
      'ai_assist',
      'assistant',
    ]);
  });

  it('every flag and capability belongs to at most one feature, consistent with capabilityFlag', () => {
    const flags = featureCatalogue.flatMap((f) => f.flags);
    expect(new Set(flags).size).toBe(flags.length);
    const caps = featureCatalogue.flatMap((f) => f.capabilities);
    expect(new Set(caps).size).toBe(caps.length);
    for (const c of capabilities) {
      const f = featureOfCapability(c);
      if (f) expect(capabilityFlag[c]).toBe(f.flags[0] ?? null);
    }
    // The Premium credit budget follows grants, never the hub.
    expect(featureOfCapability('assistant.premium_budget')).toBeNull();
    expect(featureOfCapability('module.basic')).toBeNull();
    expect(featureOfFlag('assistant_images')?.key).toBe('assistant');
  });

  it('engineering switches are the system flags, never tierable', () => {
    expect(systemFlagKeys).toEqual(
      expect.arrayContaining([
        'media_upload',
        'video_upload',
        'invites',
        'assistant_live',
        'assistant_writes',
        'premium_billing',
        'engagementEnabled',
      ]),
    );
    for (const k of flagKeys) {
      expect(systemFlagKeys.includes(k)).toBe(featureOfFlag(k) === null);
    }
  });

  it('config/features: missing document or feature reads as the default tier', () => {
    const empty = featuresConfigSchema.parse({});
    for (const f of featureCatalogue) {
      expect(empty.features[f.key]).toEqual({ tier: f.defaultTier, betaFamilies: [], grace: null });
    }
    const partial = featuresConfigSchema.parse({ features: { rhythm: { tier: 'premium' } } });
    expect(featureTierOf(partial, 'rhythm')).toBe('premium');
    expect(featureTierOf(partial, 'auto_save')).toBe('beta');
    expect(featuresConfigSchema.safeParse({ features: { rhythm: { tier: 'gold' } } }).success).toBe(
      false,
    );
  });
});

describe('the rule (plan §2.2)', () => {
  it('1 · the kill switch beats everything, even an override and paid Premium', () => {
    expect(why({ killSwitchOn: false, override: 'on', paid: true, staff: true })).toEqual({
      on: false,
      why: 'killed',
      via: null,
    });
  });

  it('2 · the admin override beats tier, rollout and Premium', () => {
    expect(why({ override: 'on' })).toEqual({ on: true, why: 'override_on', via: 'promo' });
    expect(why({ tier: 'beta', override: 'on' }).via).toBe('beta');
    expect(why({ tier: 'free', override: 'on', regionSupported: false }).via).toBe('free');
    expect(why({ override: 'off', paid: true, staff: true, rolloutOn: true }).why).toBe(
      'override_off',
    );
  });

  it('3 · Premium: paid (in region) or admin-granted Premium skips the rollout', () => {
    expect(why({ paid: true })).toEqual({ on: true, why: 'premium_paid', via: 'paid' });
    // A paid grant keeps today's region rule…
    expect(why({ paid: true, regionSupported: false, rolloutOn: true }).why).toBe('region');
    expect(why({ paid: true, regionSupported: false }).why).toBe('not_released');
    // …even where the region does not gate the free path (a switch's visibility).
    expect(why({ paid: true, regionSupported: false, regionApplies: false }).why).toBe(
      'not_released',
    );
    // An admin grant skips the country check.
    expect(why({ staff: true, regionSupported: false })).toEqual({
      on: true,
      why: 'premium_admin',
      via: 'promo',
    });
    // Paid is reported first when both run.
    expect(why({ paid: true, staff: true }).why).toBe('premium_paid');
  });

  it('3 · Premium: grace, then the rollout for everyone else', () => {
    expect(why({ grace: true })).toEqual({ on: true, why: 'grace', via: 'free' });
    expect(why({ grace: true, regionSupported: false }).why).toBe('not_released');
    expect(why({ grace: true, regionSupported: false, regionApplies: false }).why).toBe('grace');
    expect(why({}).why).toBe('not_released');
    expect(why({ rolloutOn: true, regionSupported: false }).why).toBe('region');
    expect(why({ rolloutOn: true, betaGrant: true })).toEqual({
      on: true,
      why: 'beta_campaign',
      via: 'beta',
    });
    expect(why({ rolloutOn: true, credits: true })).toEqual({
      on: true,
      why: 'credits',
      via: 'free',
    });
    expect(why({ rolloutOn: true })).toEqual({ on: false, why: 'premium_required', via: null });
    // No flag (Mẫu Premium): released to everyone, the paywall decides.
    expect(why({ killSwitchOn: null, rolloutOn: null }).why).toBe('premium_required');
  });

  it('4 · Beta: picked families or the rollout; Premium alone does not give it', () => {
    const beta = { tier: 'beta' as const, regionApplies: false };
    expect(why({ ...beta, betaListed: true })).toEqual({ on: true, why: 'beta', via: 'beta' });
    expect(why({ ...beta, rolloutOn: true }).why).toBe('beta');
    expect(why({ ...beta, paid: true, staff: true }).why).toBe('not_in_beta');
    // No flag: only the picked families.
    expect(why({ ...beta, rolloutOn: null }).why).toBe('not_in_beta');
    expect(why({ ...beta, rolloutOn: null, betaListed: true }).why).toBe('beta');
    expect(
      why({ ...beta, betaListed: true, regionApplies: true, regionSupported: false }).why,
    ).toBe('region');
  });

  it('5 · Miễn phí: the rollout', () => {
    const free = { tier: 'free' as const, regionApplies: false };
    expect(why({ ...free, rolloutOn: true })).toEqual({ on: true, why: 'free', via: 'free' });
    expect(why({ ...free, rolloutOn: false, paid: true }).why).toBe('not_released');
    expect(why({ ...free, rolloutOn: null }).why).toBe('free');
    expect(why({ ...free, rolloutOn: true, regionApplies: true, regionSupported: false }).why).toBe(
      'region',
    );
  });

  it('visibility and gate reasons', () => {
    expect(featureVisible(why({ rolloutOn: true }))).toBe(true);
    expect(featureVisible(why({ rolloutOn: true, regionSupported: false }))).toBe(true);
    expect(featureVisible(why({}))).toBe(false);
    expect(featureVisible(why({ killSwitchOn: false }))).toBe(false);
    expect(featureGateReason(why({ rolloutOn: true }))).toBe('PREMIUM_REQUIRED');
    expect(featureGateReason(why({ rolloutOn: true, regionSupported: false }))).toBe(
      'REGION_UNAVAILABLE',
    );
    for (const w of [{ killSwitchOn: false }, { override: 'off' as const }, {}]) {
      expect(featureGateReason(why(w))).toBe('FEATURE_DISABLED');
    }
    expect(featureGateReason(why({ tier: 'beta' }))).toBe('FEATURE_DISABLED');
  });
});

describe('inputs', () => {
  it('featurePremium: the grant must give one of the feature’s Premium capabilities', () => {
    const promoTemplates = grant({ source: 'promo', capabilities: ['templates.premium'] });
    expect(featurePremium([promoTemplates], ['personalization.cross_module'], 'test', now)).toEqual(
      { paid: false, staff: false, beta: false },
    );
    expect(featurePremium([promoTemplates], ['templates.premium'], 'test', now).staff).toBe(true);
    // No Premium capability (a flag-only or free feature moved to Premium): any grant counts.
    expect(featurePremium([promoTemplates], [], 'test', now).staff).toBe(true);
    expect(featurePremium([promoTemplates], ['rhythm.checkin'], 'test', now).staff).toBe(true);
    // Environment, status and dates still apply.
    expect(featurePremium([grant()], [], 'production', now).paid).toBe(false);
    expect(featurePremium([grant({ status: 'revoked' })], [], 'test', now).paid).toBe(false);
    expect(
      featurePremium([grant({ validUntil: new Date('2026-10-21T12:00:00Z') })], [], 'test', now)
        .paid,
    ).toBe(false);
    expect(featurePremium([grant({ source: 'beta' })], [], 'test', now)).toEqual({
      paid: false,
      staff: false,
      beta: true,
    });
  });

  it('inFeatureGrace: who had it at the move keeps it until the end', () => {
    const grace: FeatureGrace = {
      since: '2026-10-20T00:00:00.000Z',
      until: '2026-11-19T00:00:00.000Z',
      from: 'beta',
      rollout: { enabled: true, scope: 'percent', percent: 25 },
      betaFamilies: ['f_picked'],
    };
    const fam = (over: Partial<Parameters<typeof inFeatureGrace>[1]> = {}) => ({
      familyId: 'f_x',
      bucket: 10,
      internal: false,
      createdAt: new Date('2026-01-01T00:00:00Z'),
      now,
      ...over,
    });
    expect(inFeatureGrace(grace, fam())).toBe(true);
    expect(inFeatureGrace(grace, fam({ bucket: 30 }))).toBe(false);
    expect(inFeatureGrace(grace, fam({ bucket: 30, familyId: 'f_picked' }))).toBe(true);
    expect(
      inFeatureGrace({ ...grace, from: 'free' }, fam({ bucket: 30, familyId: 'f_picked' })),
    ).toBe(false);
    expect(inFeatureGrace(grace, fam({ now: new Date('2026-11-19T00:00:00Z') }))).toBe(false);
    expect(inFeatureGrace(grace, fam({ createdAt: new Date('2026-10-20T01:00:00Z') }))).toBe(false);
    expect(inFeatureGrace(grace, fam({ createdAt: null }))).toBe(true);
    expect(inFeatureGrace({ ...grace, rollout: { ...grace.rollout, enabled: false } }, fam())).toBe(
      false,
    );
    expect(inFeatureGrace(null, fam())).toBe(false);
  });

  it('activeOverride: an ended override is no override', () => {
    expect(activeOverride({ state: 'on', until: null }, now)).toBe('on');
    expect(activeOverride({ state: 'off', until: new Date('2026-10-22T00:00:00Z') }, now)).toBe(
      'off',
    );
    expect(activeOverride({ state: 'on', until: now }, now)).toBeNull();
    expect(activeOverride(undefined, now)).toBeNull();
  });
});

describe('familyFeatureDecision (what the server asks)', () => {
  const flags = (over: Partial<Flags> = {}): Flags => ({
    ...structuredClone(defaultFlags),
    rhythm: { enabled: true, scope: 'all', percent: 0, notice: null },
    personalization: { enabled: true, scope: 'internal', percent: 0, notice: null },
    ai_assist: { enabled: true, scope: 'all', percent: 0, notice: null },
    assistant: { enabled: true, scope: 'all', percent: 0, notice: null },
    assistant_images: { enabled: true, scope: 'internal', percent: 0, notice: null },
    auto_save: { enabled: true, scope: 'internal', percent: 0, notice: null },
    ...over,
  });
  const facts = (over: Partial<FamilyFeatureFacts> = {}): FamilyFeatureFacts => ({
    familyId: 'f1',
    bucket: 50,
    internal: false,
    createdAt: null,
    country: 'VN',
    advancedRegions: ['VN'],
    flags: flags(),
    hub: featuresConfigSchema.parse({}),
    overrides: {},
    grants: [],
    environment: 'test',
    now,
    ...over,
  });

  it('a free family sees personalization only inside the rollout; Premium skips it', () => {
    expect(familyFeatureDecision(facts(), 'personalization').why).toBe('not_released');
    const paid = facts({ grants: [grant()] });
    expect(familyFeatureDecision(paid, 'personalization').why).toBe('premium_paid');
    expect(
      familyFeatureDecision(paid, 'personalization', { capability: 'rhythm.advanced' }).via,
    ).toBe('paid');
    // Sub-switches follow too: the assistant's photos for a Premium family.
    expect(familyFeatureDecision(facts(), 'assistant', { flag: 'assistant_images' }).on).toBe(
      false,
    );
    expect(familyFeatureDecision(paid, 'assistant', { flag: 'assistant_images' }).on).toBe(true);
    // The credit budget keeps the assistant open to everyone in the rollout.
    expect(familyFeatureDecision(facts(), 'assistant', { flag: 'assistant' }).why).toBe('credits');
  });

  it('region: a paid grant needs it, a staff grant does not; a switch is never hidden by it', () => {
    const us = { country: 'US' };
    expect(
      familyFeatureDecision(facts({ ...us, grants: [grant()] }), 'templates_premium').why,
    ).toBe('region');
    expect(
      familyFeatureDecision(
        facts({ ...us, grants: [grant({ source: 'promo' })] }),
        'templates_premium',
      ).why,
    ).toBe('premium_admin');
    const rhythmFlag = familyFeatureDecision(facts(us), 'ai_assist', { flag: 'ai_assist' });
    expect(rhythmFlag.why).toBe('credits');
    expect(familyFeatureDecision(facts(us), 'ai_assist', { capability: 'ai.assistance' }).why).toBe(
      'region',
    );
  });

  it('a capability asks for its own grant; overrides and beta lists apply per family', () => {
    const promoCross = facts({
      flags: flags({ personalization: { enabled: true, scope: 'all', percent: 0, notice: null } }),
      grants: [grant({ source: 'promo', capabilities: ['personalization.cross_module'] })],
    });
    expect(
      familyFeatureDecision(promoCross, 'personalization', {
        capability: 'personalization.cross_module',
      }).why,
    ).toBe('premium_admin');
    expect(
      familyFeatureDecision(promoCross, 'personalization', { capability: 'rhythm.advanced' }).why,
    ).toBe('premium_required');

    const overridden = facts({
      overrides: { auto_save: { state: 'on', until: null }, rhythm: { state: 'off', until: null } },
    });
    expect(familyFeatureDecision(overridden, 'auto_save').why).toBe('override_on');
    expect(familyFeatureDecision(overridden, 'rhythm').why).toBe('override_off');

    const hub = featuresConfigSchema.parse({
      features: { auto_save: { tier: 'beta', betaFamilies: ['f1'] } },
    });
    expect(familyFeatureDecision(facts({ hub }), 'auto_save').why).toBe('beta');
    expect(familyFeatureDecision(facts(), 'auto_save').why).toBe('not_in_beta');
  });

  it('a tier moved to Premium keeps the grace families; a new family is not in it', () => {
    const hub = featuresConfigSchema.parse({
      features: {
        auto_save: {
          tier: 'premium',
          grace: {
            since: '2026-10-20T00:00:00.000Z',
            until: '2026-11-19T00:00:00.000Z',
            from: 'beta',
            rollout: { enabled: true, scope: 'all', percent: 0 },
          },
        },
      },
    });
    expect(familyFeatureDecision(facts({ hub }), 'auto_save').why).toBe('grace');
    expect(
      familyFeatureDecision(
        facts({ hub, createdAt: new Date('2026-10-21T00:00:00Z') }),
        'auto_save',
      ).why,
    ).toBe('not_released');
  });
});

describe('resolveFeatureCapability', () => {
  const check: CapabilityCheck = {
    capability: 'templates.premium',
    now,
    member: true,
    roleAllows: true,
    featureEnabled: true,
    regionSupported: true,
    environment: 'test',
    grants: [],
  };
  it('membership and role come first; no decision = resolveCapability', () => {
    const open = why({ paid: true });
    expect(resolveFeatureCapability({ ...check, member: false }, open)).toEqual({
      allowed: false,
      reason: 'NOT_MEMBER',
    });
    expect(resolveFeatureCapability({ ...check, roleAllows: false }, open)).toEqual({
      allowed: false,
      reason: 'ROLE_DENIED',
    });
    expect(resolveFeatureCapability(check, open)).toEqual({ allowed: true, via: 'paid' });
    expect(resolveFeatureCapability(check, why({ rolloutOn: true }))).toEqual({
      allowed: false,
      reason: 'PREMIUM_REQUIRED',
    });
    expect(resolveFeatureCapability(check, null)).toEqual({
      allowed: false,
      reason: 'PREMIUM_REQUIRED',
    });
  });
});

describe('staff requests (D-090: no reason needed)', () => {
  it('every reason is optional and reads as ""', () => {
    expect(staffReasonSchema.parse(undefined)).toBe('');
    expect(staffReasonSchema.parse(null)).toBe('');
    expect(staffReasonSchema.parse('  x ')).toBe('x');
    expect(
      setFlagSchema.parse({ key: 'rhythm', enabled: true, scope: 'all', percent: 0, notice: null })
        .reason,
    ).toBe('');
    expect(
      grantPromoSchema.safeParse({
        code: 'F-ABCD',
        capabilities: ['templates.premium'],
        validUntil: '2026-11-01T00:00:00Z',
      }).success,
    ).toBe(true);
    expect(
      keepsakeActSchema.safeParse({ versionId: 'kv_0123456789abcdef', action: 'reject' }).success,
    ).toBe(true);
    expect(setContentPolicyRequestSchema.safeParse({ ownerSelfApprove: true }).success).toBe(true);
    expect(appUpdateSaveSchema.safeParse({ config: appUpdateEmpty }).success).toBe(true);
  });

  it('hub requests default to no dry run, no end date, no reason', () => {
    expect(hubSetTierSchema.parse({ feature: 'auto_save', tier: 'premium' })).toEqual({
      feature: 'auto_save',
      tier: 'premium',
      dryRun: false,
      reason: '',
    });
    expect(hubFullPremiumSchema.parse({ code: 'F-ABCD', on: true })).toMatchObject({
      until: null,
      reason: '',
    });
    expect(
      hubSetOverrideSchema.safeParse({ code: 'F-ABCD', feature: 'rhythm', state: null }).success,
    ).toBe(true);
    expect(
      hubSetOverrideSchema.safeParse({ code: 'f1', feature: 'rhythm', state: 'on' }).success,
    ).toBe(false);
    expect(isOpenEndedUntil(new Date(OPEN_ENDED_GRANT_UNTIL))).toBe(true);
    expect(isOpenEndedUntil(new Date('2027-10-21T00:00:00Z'))).toBe(false);
  });
});
