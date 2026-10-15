import { describe, expect, it } from 'vitest';
import {
  campaignOpen,
  capabilities,
  capabilityAction,
  defaultEntitlementsConfig,
  entitlementsConfigSchema,
  familyCan,
  householdPlan,
  premiumCapabilities,
  resolveCapability,
  type Capability,
  type GrantView,
  type MemberGrant,
} from '../src/index.js';
import pack from './vectors/premium-v2.json' with { type: 'json' };

/**
 * Fixture pack v2.0 (`qa-policy-v2`, synthetic only): the entitlement cases E01–E15 through the
 * real resolver. The pack's `editor` / `viewer` map onto Child Life roles (plan §2 row 1): editor →
 * Cùng nuôi, viewer → Người thân with "Chăm sóc hằng ngày" (the only relative who may read history).
 */
interface FixtureGrant {
  source: GrantView['source'];
  status: GrantView['status'];
  environment: GrantView['environment'];
  from: string;
  until: string;
  capabilities: string[];
  autoRenew?: boolean;
}
interface EntitlementCase {
  id: string;
  kind: 'entitlement';
  input: {
    now: string;
    member: boolean;
    role: 'editor' | 'viewer';
    capability: Capability;
    region_supported: boolean;
    feature_enabled: boolean;
    environment: GrantView['environment'];
    grants: FixtureGrant[];
  };
  expected: string;
}

const roleOf: Record<EntitlementCase['input']['role'], MemberGrant> = {
  editor: { role: 'coParent' },
  viewer: { role: 'relative', extraRights: { viewDailyCare: true } },
};

const cases = (pack.cases as { kind: string }[]).filter(
  (c): c is EntitlementCase => c.kind === 'entitlement',
);

describe('fixture pack premium-v2', () => {
  it('is the synthetic v2.0 pack and has all 15 entitlement cases', () => {
    expect(pack.schema_version).toBe('2.0');
    expect(pack.synthetic_only).toBe(true);
    expect(pack.not_production_seed).toBe(true);
    expect(cases.map((c) => c.id)).toEqual(
      Array.from({ length: 15 }, (_, i) => `E${String(i + 1).padStart(2, '0')}`),
    );
  });

  it.each(cases.map((c) => [c.id, c] as const))('%s', (_id, c) => {
    const x = c.input;
    const result = resolveCapability({
      capability: x.capability,
      now: new Date(x.now),
      member: x.member,
      roleAllows: familyCan(roleOf[x.role], capabilityAction[x.capability]),
      featureEnabled: x.feature_enabled,
      regionSupported: x.region_supported,
      environment: x.environment,
      grants: x.grants.map((g) => ({
        source: g.source,
        status: g.status,
        environment: g.environment,
        capabilities: g.capabilities as Capability[],
        validFrom: new Date(g.from),
        validUntil: new Date(g.until),
      })),
    });
    expect(result.allowed ? 'ALLOWED' : result.reason).toBe(c.expected);
  });
});

const t = (iso: string) => new Date(iso);
const grant = (over: Partial<GrantView> = {}): GrantView => ({
  source: 'paid',
  status: 'active',
  environment: 'production',
  capabilities: [...premiumCapabilities],
  validFrom: t('2026-10-01T00:00:00Z'),
  validUntil: t('2026-11-01T00:00:00Z'),
  ...over,
});
const base = {
  now: t('2026-10-14T12:00:00Z'),
  member: true,
  roleAllows: true,
  featureEnabled: true,
  regionSupported: true,
  environment: 'production' as const,
};

describe('resolveCapability', () => {
  it('free capabilities never need a grant or a supported region', () => {
    for (const c of [
      'rhythm.checkin',
      'health.guidance',
      'history.read',
      'render.video',
    ] as const) {
      expect(
        resolveCapability({ ...base, capability: c, regionSupported: false, grants: [] }),
      ).toEqual({ allowed: true, via: 'free' });
    }
  });

  it('reports paid over beta when both are valid', () => {
    const beta = grant({ source: 'beta', capabilities: ['personalization.cross_module'] });
    expect(
      resolveCapability({
        ...base,
        capability: 'personalization.cross_module',
        grants: [beta, grant()],
      }),
    ).toEqual({ allowed: true, via: 'paid' });
  });

  it('a pending purchase grants nothing (M06)', () => {
    expect(
      resolveCapability({
        ...base,
        capability: 'templates.premium',
        grants: [grant({ status: 'pending' })],
      }),
    ).toEqual({ allowed: false, reason: 'PREMIUM_REQUIRED' });
  });

  it('D-075 #1: AI is open to Free in an advanced region (credits limit it), never elsewhere', () => {
    expect(resolveCapability({ ...base, capability: 'ai.assistance', grants: [] })).toEqual({
      allowed: true,
      via: 'free',
    });
    expect(resolveCapability({ ...base, capability: 'ai.assistance', grants: [grant()] })).toEqual({
      allowed: true,
      via: 'paid',
    });
    expect(
      resolveCapability({
        ...base,
        capability: 'ai.assistance',
        regionSupported: false,
        grants: [],
      }),
    ).toEqual({ allowed: false, reason: 'REGION_UNAVAILABLE' });
    expect(
      resolveCapability({ ...base, capability: 'ai.assistance', roleAllows: false, grants: [] }),
    ).toEqual({ allowed: false, reason: 'ROLE_DENIED' });
    expect(
      resolveCapability({ ...base, capability: 'assistant.premium_budget', grants: [] }),
    ).toEqual({ allowed: false, reason: 'PREMIUM_REQUIRED' });
  });

  it('D-075 #1: a beta grant may open templates and the Premium credit budget', () => {
    const beta = grant({ source: 'beta', capabilities: [...premiumCapabilities] });
    for (const c of ['templates.premium', 'assistant.premium_budget'] as const) {
      expect(resolveCapability({ ...base, capability: c, grants: [beta] })).toEqual({
        allowed: true,
        via: 'beta',
      });
    }
    // Still a beta in PR03: only a paid or promo grant with templates shows Premium.
    expect(householdPlan([beta], 'production', base.now).plan).toBe('beta');
  });

  it('validUntil is exclusive and validFrom inclusive', () => {
    const g = grant();
    const at = (now: Date) =>
      resolveCapability({ ...base, now, capability: 'templates.premium', grants: [g] }).allowed;
    expect(at(g.validFrom)).toBe(true);
    expect(at(new Date(g.validUntil.getTime() - 1))).toBe(true);
    expect(at(g.validUntil)).toBe(false);
  });
});

describe('familyCan (D-072 #1–#2)', () => {
  const coParent: MemberGrant = { role: 'coParent' };
  const owner: MemberGrant = { role: 'coParent', isOwner: true };
  const caregiver: MemberGrant = { role: 'caregiver' };
  const relative: MemberGrant = { role: 'relative' };

  it('only the family owner manages billing and household settings', () => {
    expect(familyCan(owner, 'billing.manage')).toBe(true);
    expect(familyCan(coParent, 'billing.manage')).toBe(false);
    expect(familyCan(caregiver, 'family.settings')).toBe(false);
  });

  it('caregivers check in and give feedback but never generate AI', () => {
    expect(familyCan(caregiver, 'rhythm.checkin')).toBe(true);
    expect(familyCan(caregiver, 'rhythm.feedback')).toBe(true);
    expect(familyCan(caregiver, 'history.read')).toBe(true);
    expect(familyCan(caregiver, 'ai.generate')).toBe(false);
    expect(familyCan(caregiver, 'moments.create')).toBe(false);
  });

  it('relatives read history only with daily-care rights; health is for everyone', () => {
    expect(familyCan(relative, 'history.read')).toBe(false);
    expect(familyCan({ ...relative, extraRights: { viewDailyCare: true } }, 'history.read')).toBe(
      true,
    );
    expect(familyCan(relative, 'rhythm.checkin')).toBe(false);
    expect(familyCan(relative, 'health.read')).toBe(true);
  });

  it('maps every capability to an action', () => {
    expect(Object.keys(capabilityAction).sort()).toEqual([...capabilities].sort());
  });
});

describe('householdPlan (PR03)', () => {
  const now = t('2026-10-14T12:00:00Z');
  it('free with no grants, premium over beta, expired after a paid grant ends', () => {
    expect(householdPlan([], 'production', now).plan).toBe('free');
    const beta = grant({ source: 'beta', capabilities: ['rhythm.advanced'] });
    expect(householdPlan([beta], 'production', now).plan).toBe('beta');
    expect(householdPlan([beta, grant()], 'production', now).plan).toBe('premium');
    const ended = grant({ validUntil: t('2026-10-10T00:00:00Z'), status: 'expired' });
    expect(householdPlan([ended], 'production', now)).toMatchObject({
      plan: 'expired',
      validUntil: t('2026-10-10T00:00:00Z'),
    });
    expect(householdPlan([grant({ status: 'pending' })], 'production', now).plan).toBe('pending');
  });

  it('ignores grants from the other environment (M08)', () => {
    expect(householdPlan([grant({ environment: 'test' })], 'production', now).plan).toBe('free');
  });
});

describe('entitlements config', () => {
  it('defaults validate, open no region and keep fixture quotas', () => {
    expect(entitlementsConfigSchema.parse(defaultEntitlementsConfig)).toEqual(
      defaultEntitlementsConfig,
    );
    expect(defaultEntitlementsConfig.regions.advanced).toEqual([]);
  });

  it('D-075 #1: a beta campaign may give every Premium capability, never a free one', () => {
    const campaign = {
      id: 'beta-a',
      capabilities: [...premiumCapabilities],
      validFrom: '2026-10-01T00:00:00Z',
      validUntil: '2026-12-01T00:00:00Z',
      countries: ['VN'],
      scope: 'all',
      percent: 0,
    };
    const parse = (c: object) =>
      entitlementsConfigSchema.safeParse({ ...defaultEntitlementsConfig, betaCampaigns: [c] })
        .success;
    expect(premiumCapabilities).toEqual(
      expect.arrayContaining(['templates.premium', 'assistant.premium_budget']),
    );
    expect(parse(campaign)).toBe(true);
    expect(parse({ ...campaign, capabilities: ['templates.premium'] })).toBe(true);
    expect(parse({ ...campaign, capabilities: ['rhythm.checkin'] })).toBe(false);
  });

  it('a stored config without assistant credits reads the shipped defaults', () => {
    const { assistant: _a, ...quotas } = defaultEntitlementsConfig.quotas;
    void _a;
    const parsed = entitlementsConfigSchema.parse({ ...defaultEntitlementsConfig, quotas });
    expect(parsed.quotas.assistant).toEqual({
      free: 20,
      premium: 200,
      textCredits: 1,
      imageCredits: 3,
    });
  });

  it('campaignOpen follows validity and scope', () => {
    const c = {
      id: 'beta-a',
      capabilities: ['rhythm.advanced' as const],
      validFrom: '2026-10-01T00:00:00Z',
      validUntil: '2026-10-20T00:00:00Z',
      countries: [],
      scope: 'internal' as const,
      percent: 0,
      families: ['f_test_1'],
    };
    expect(campaignOpen(c, t('2026-10-14T00:00:00Z'), 'f_test_1', 50, false)).toBe(true);
    expect(campaignOpen(c, t('2026-10-14T00:00:00Z'), 'f_test_2', 50, false)).toBe(false);
    expect(campaignOpen(c, t('2026-10-20T00:00:00Z'), 'f_test_1', 50, false)).toBe(false);
    expect(
      campaignOpen(
        { ...c, scope: 'percent', percent: 30 },
        t('2026-10-14T00:00:00Z'),
        'x',
        29,
        false,
      ),
    ).toBe(true);
  });
});
