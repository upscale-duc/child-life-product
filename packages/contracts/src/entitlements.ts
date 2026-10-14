import { z } from 'zod';
import type { FamilyAction } from './family-actions.js';
import type { FlagKey } from './config.js';

/**
 * Child Life Premium & Cá nhân hoá (brief v2.0 p.3, plan `docs/product/premium-personalization-plan.md`).
 * Capabilities are the product contract; roles still decide who reads and writes (`familyCan`).
 */
export const capabilities = [
  'module.basic',
  'personalization.basic',
  'wonder.reference',
  'rhythm.checkin',
  'health.guidance',
  'moments.basic',
  'history.read',
  /** Group A. */
  'personalization.cross_module',
  'rhythm.advanced',
  'ai.assistance',
  /** Group B. */
  'templates.premium',
  /** Every plan, limited by its own quota (free / premium budget), not by a grant. */
  'render.video',
] as const;
export type Capability = (typeof capabilities)[number];

/** Free for every member in every plan state, including after a plan ends (brief p.3). */
export const freeCapabilities: readonly Capability[] = [
  'module.basic',
  'personalization.basic',
  'wonder.reference',
  'rhythm.checkin',
  'health.guidance',
  'moments.basic',
  'history.read',
  'render.video',
];

export const groupACapabilities: readonly Capability[] = [
  'personalization.cross_module',
  'rhythm.advanced',
  'ai.assistance',
];
/** What a verified paid subscription grants: A + B (one SKU, two entry points). */
export const premiumCapabilities: readonly Capability[] = [
  ...groupACapabilities,
  'templates.premium',
];

export function isFreeCapability(c: Capability): boolean {
  return freeCapabilities.includes(c);
}

/** The family action a capability is used for, when a callable does not name a narrower one. */
export const capabilityAction: Record<Capability, FamilyAction> = {
  'module.basic': 'history.read',
  'personalization.basic': 'preferences.own',
  'wonder.reference': 'history.read',
  'rhythm.checkin': 'rhythm.checkin',
  'health.guidance': 'health.read',
  'moments.basic': 'moments.create',
  'history.read': 'history.read',
  'personalization.cross_module': 'rhythm.suggestions',
  'rhythm.advanced': 'rhythm.suggestions',
  'ai.assistance': 'ai.generate',
  'templates.premium': 'moments.create',
  'render.video': 'moments.create',
};

/**
 * The kill switch / rollout flag in front of a capability (PN01 "Công tắc khẩn cấp"); `null` = none.
 * Templates and video keep the Kỷ niệm 2.0 flags, checked where they are used.
 */
export const capabilityFlag: Record<Capability, FlagKey | null> = {
  'module.basic': null,
  'personalization.basic': null,
  'wonder.reference': 'rhythm',
  'rhythm.checkin': 'rhythm',
  'health.guidance': null,
  'moments.basic': null,
  'history.read': null,
  'personalization.cross_module': 'personalization',
  'rhythm.advanced': 'personalization',
  'ai.assistance': 'ai_assist',
  'templates.premium': null,
  'render.video': 'memory_story',
};

/** Reason codes (brief p.8). The app maps each to its own state; only PREMIUM_REQUIRED may show a paywall. */
export const gateReasons = [
  'NOT_MEMBER',
  'ROLE_DENIED',
  'FEATURE_DISABLED',
  'REGION_UNAVAILABLE',
  'PREMIUM_REQUIRED',
  'CONSENT_REQUIRED',
  'QUOTA_EXCEEDED',
] as const;
export type GateReason = (typeof gateReasons)[number];

export const grantSources = ['paid', 'beta', 'promo'] as const;
export type GrantSource = (typeof grantSources)[number];

/**
 * Provider-neutral grant status. Only `active` and `grace` give access; `grace` only while the
 * provider confirms it (brief p.9). `pending` (unverified purchase) never does.
 */
export const grantStatuses = [
  'pending',
  'active',
  'grace',
  'on_hold',
  'expired',
  'revoked',
  'refunded',
] as const;
export type GrantStatus = (typeof grantStatuses)[number];

/** Store sandbox and dev produce `test`; only `production` counts on prod (M08). */
export const grantEnvironments = ['test', 'production'] as const;
export type GrantEnvironment = (typeof grantEnvironments)[number];

/** `families/{f}/grants/{grantId}`: server-written only (Rules deny clients, M04). */
export const grantSchema = z.object({
  familyId: z.string().min(1).max(128),
  source: z.enum(grantSources),
  status: z.enum(grantStatuses),
  environment: z.enum(grantEnvironments),
  capabilities: z.array(z.enum(capabilities)).min(1),
  /** Inclusive start, exclusive end (brief p.8). */
  validFrom: z.date(),
  validUntil: z.date(),
  /** Paid only: who bought it and manages it in the store (D-072 #1). */
  billingOwnerUid: z.string().nullable(),
  provider: z.enum(['apple', 'google', 'staff']).nullable(),
  /** Paid: `billingAccounts` id (provider + original transaction); never a raw token. */
  sourceRef: z.string().max(200).nullable(),
  /** Beta: the campaign; promo: the staff audit id. */
  campaignId: z.string().max(80).nullable(),
  autoRenew: z.boolean().nullable(),
  updatedAt: z.date(),
});
export type Grant = z.infer<typeof grantSchema>;

/** The fields the resolver reads; fixtures and Firestore documents both map onto it. */
export type GrantView = Pick<
  Grant,
  'source' | 'status' | 'environment' | 'capabilities' | 'validFrom' | 'validUntil'
>;

export function grantGives(g: GrantView, c: Capability, env: GrantEnvironment, now: Date): boolean {
  const t = now.getTime();
  return (
    g.environment === env &&
    (g.status === 'active' || g.status === 'grace') &&
    g.validFrom.getTime() <= t &&
    t < g.validUntil.getTime() &&
    g.capabilities.includes(c)
  );
}

export interface CapabilityCheck {
  capability: Capability;
  now: Date;
  /** An active, unexpired membership of the baby. */
  member: boolean;
  /** `familyCan(member, action)` for the action being performed. */
  roleAllows: boolean;
  /** The capability's flag is on for this family (`capabilityFlag`); true when it has none. */
  featureEnabled: boolean;
  /** The family's country is in the advanced regions (`entitlementsConfig.regions.advanced`). */
  regionSupported: boolean;
  environment: GrantEnvironment;
  grants: readonly GrantView[];
}

export type CapabilityResult =
  { allowed: true; via: GrantSource | 'free' } | { allowed: false; reason: GateReason };

/**
 * Steps 2–4 of the resolver (brief p.8): membership, role, kill switch, free capabilities, region,
 * then the union of valid grants. A revoked grant never removes what another valid grant gives
 * (E11). Consent and quota (steps 5–6) are checked by the caller after this. Order matches the
 * fixture pack `qa-policy-v2` (E01–E15).
 */
export function resolveCapability(x: CapabilityCheck): CapabilityResult {
  if (!x.member) return { allowed: false, reason: 'NOT_MEMBER' };
  if (!x.roleAllows) return { allowed: false, reason: 'ROLE_DENIED' };
  if (!x.featureEnabled) return { allowed: false, reason: 'FEATURE_DISABLED' };
  if (isFreeCapability(x.capability)) return { allowed: true, via: 'free' };
  if (!x.regionSupported) return { allowed: false, reason: 'REGION_UNAVAILABLE' };
  // Paid first so a paying family is reported as paid while a beta also runs.
  for (const source of grantSources) {
    if (
      x.grants.some((g) => g.source === source && grantGives(g, x.capability, x.environment, x.now))
    ) {
      return { allowed: true, via: source };
    }
  }
  return { allowed: false, reason: 'PREMIUM_REQUIRED' };
}

/** What PR03 shows for the household (one label; the capabilities are the real contract). */
export const householdPlans = ['free', 'beta', 'premium', 'pending', 'expired'] as const;
export type HouseholdPlan = (typeof householdPlans)[number];

export interface HouseholdPlanView {
  plan: HouseholdPlan;
  /** End of the grant behind `plan` (exclusive), when there is one. */
  validUntil: Date | null;
  autoRenew: boolean | null;
  billingOwnerUid: string | null;
}

/**
 * Premium (a valid paid or promo grant giving templates) wins over beta; a purchase being verified
 * shows `pending` only when nothing else is valid; an ended paid grant shows `expired` (PR04).
 */
export function householdPlan(
  grants: readonly (GrantView & Partial<Pick<Grant, 'autoRenew' | 'billingOwnerUid'>>)[],
  env: GrantEnvironment,
  now: Date,
): HouseholdPlanView {
  const mine = grants.filter((g) => g.environment === env);
  const valid = (g: GrantView) =>
    (g.status === 'active' || g.status === 'grace') &&
    g.validFrom.getTime() <= now.getTime() &&
    now.getTime() < g.validUntil.getTime();
  const latest = <T extends GrantView>(list: T[]) =>
    list.sort((a, b) => b.validUntil.getTime() - a.validUntil.getTime())[0];
  const view = (plan: HouseholdPlan, g?: GrantView & Partial<Grant>): HouseholdPlanView => ({
    plan,
    validUntil: g?.validUntil ?? null,
    autoRenew: g?.autoRenew ?? null,
    billingOwnerUid: g?.billingOwnerUid ?? null,
  });
  const premium = latest(
    mine.filter(
      (g) => g.source !== 'beta' && valid(g) && g.capabilities.includes('templates.premium'),
    ),
  );
  if (premium) return view('premium', premium);
  const beta = latest(mine.filter((g) => valid(g)));
  if (beta) return view('beta', beta);
  const pending = latest(mine.filter((g) => g.source === 'paid' && g.status === 'pending'));
  if (pending) return view('pending', pending);
  const ended = latest(mine.filter((g) => g.source === 'paid'));
  if (ended) return view('expired', ended);
  return view('free');
}

/** ISO 3166-1 alpha-2, upper case: the household's country of residence (D-072 #3). */
export const countryCodeSchema = z.string().regex(/^[A-Z]{2}$/);

const betaCampaignSchema = z.object({
  id: z.string().regex(/^[a-z0-9_-]{2,40}$/),
  /** Beta A never includes `templates.premium` unless a distinct promo says so (brief p.3). */
  capabilities: z
    .array(z.enum(capabilities))
    .min(1)
    .refine((c) => !c.includes('templates.premium'), 'A beta campaign never opens templates'),
  validFrom: z.iso.datetime(),
  validUntil: z.iso.datetime(),
  /** Countries the campaign runs in; empty = every advanced region. */
  countries: z.array(countryCodeSchema).max(50),
  scope: z.enum(['internal', 'percent', 'all']),
  percent: z.number().int().min(0).max(100),
  /** Scope `internal`: picked families (never mirrored to clients). */
  families: z.array(z.string().min(1).max(128)).max(500).optional(),
});
export type BetaCampaign = z.infer<typeof betaCampaignSchema>;

const quotaWindows = ['calendar_month', 'billing_period'] as const;

/**
 * `config/entitlements` (server; projection in `publicConfig/entitlements` without `families`).
 * Every number is configuration, not a commercial commitment (Q-071); defaults are the fixture
 * values from the brief p.10 and ship with no region open.
 */
export const entitlementsConfigSchema = z.object({
  policyVersion: z.string().min(1).max(40),
  regions: z.object({
    /** Where group A (and the paid plan) is offered; elsewhere → REGION_UNAVAILABLE. */
    advanced: z.array(countryCodeSchema).max(250),
  }),
  quotas: z.object({
    video: z.object({
      free: z.object({ limit: z.number().int().min(0), window: z.enum(quotaWindows) }),
      premium: z.object({ limit: z.number().int().min(0), window: z.enum(quotaWindows) }),
    }),
    ai: z.object({
      perBabyPerDay: z.number().int().min(0),
      perFamilyPerMonth: z.number().int().min(0),
    }),
  }),
  betaCampaigns: z.array(betaCampaignSchema).max(20),
});
export type EntitlementsConfig = z.infer<typeof entitlementsConfigSchema>;

export const defaultEntitlementsConfig: EntitlementsConfig = {
  policyVersion: 'policy-v2-draft',
  regions: { advanced: [] },
  quotas: {
    video: {
      free: { limit: 1, window: 'calendar_month' },
      premium: { limit: 5, window: 'billing_period' },
    },
    ai: { perBabyPerDay: 1, perFamilyPerMonth: 10 },
  },
  betaCampaigns: [],
};

/** A campaign is open for a family at [now] (rollout like flags; country checked separately). */
export function campaignOpen(
  c: BetaCampaign,
  now: Date,
  familyId: string,
  bucket: number,
  isInternalFamily: boolean,
): boolean {
  const t = now.getTime();
  if (t < Date.parse(c.validFrom) || t >= Date.parse(c.validUntil)) return false;
  switch (c.scope) {
    case 'all':
      return true;
    case 'internal':
      return isInternalFamily || (c.families ?? []).includes(familyId);
    case 'percent':
      return bucket < c.percent;
  }
}

/** `getCapabilities` request and answer (the app's view; the server re-checks every action). */
export const capabilitiesRequestSchema = z.object({ babyId: z.string().min(1).max(128) });

export interface CapabilityState {
  allowed: boolean;
  reason: GateReason | null;
  via: GrantSource | 'free' | null;
}

export interface CapabilitiesAnswer {
  familyId: string;
  policyVersion: string;
  /** Bumped on every grant change; the app refetches when it moves. */
  entitlementVersion: number;
  plan: HouseholdPlan;
  /** ISO instant (exclusive end) of the plan shown, or null. */
  validUntil: string | null;
  autoRenew: boolean | null;
  isBillingOwner: boolean;
  /** The caller may buy / manage (family owner, D-072 #1). */
  canManageBilling: boolean;
  /** Null until the owner answers the first-open question (D-072 #3). */
  country: string | null;
  capabilities: Record<Capability, CapabilityState>;
}

/**
 * `setFamilySettings` (owner only, D-072 #1/#3): the household's country of residence, asked on
 * first open of Nhịp lớn lên, and the time zone used for quota windows. A time-zone change applies
 * from the next quota window (brief p.10).
 */
export const familySettingsRequestSchema = z
  .object({
    babyId: z.string().min(1).max(128),
    country: countryCodeSchema.optional(),
    timeZone: z.string().min(1).max(64).optional(),
  })
  .refine((v) => v.country !== undefined || v.timeZone !== undefined, 'Nothing to change');
export type FamilySettingsRequest = z.infer<typeof familySettingsRequestSchema>;
