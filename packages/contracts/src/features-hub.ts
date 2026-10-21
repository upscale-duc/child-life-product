import { z } from 'zod';
import {
  flagKeys,
  flagSchema,
  isFlagOnForFamily,
  rolloutScopes,
  type Flag,
  type FlagKey,
  type Flags,
} from './config.js';
import {
  grantGives,
  isFreeCapability,
  resolveCapability,
  type Capability,
  type CapabilityCheck,
  type CapabilityResult,
  type GateReason,
  type GrantEnvironment,
  type GrantSource,
  type GrantStatus,
  type GrantView,
  type HouseholdPlan,
} from './entitlements.js';
import { staffReasonSchema } from './staff-reason.js';
import { familyCodeSchema } from './staff.js';

/**
 * "Tính năng & Premium" hub (proposed D-089 / P-172, `docs/product/features-premium-hub-plan.md`
 * §2): one catalogue of user-facing features, a tier per feature (Miễn phí · Premium · Beta) in
 * `config/features`, per-family admin overrides in `families/{f}/featureOverrides/{feature}`, and
 * ONE rule (`decideFeature`, §2.2) that the server applies in `getCapabilities`, `featureAccess`
 * and every gated callable. The flags in `config/flags` stay the kill switches and the rollout
 * ("Phát hành"); engineering switches outside the catalogue are the "Công tắc hệ thống".
 */

// ---------- Catalogue v1 (plan §2.1) ----------

export const featureKeys = [
  'rhythm',
  'personalization',
  'ai_assist',
  'assistant',
  'templates_premium',
  'milestone_cards',
  'memory_story',
  'auto_save',
  'ai_story_drafts',
] as const;
export type FeatureKey = (typeof featureKeys)[number];

/** Display order of the hub groups: Ghi chép · Kỷ niệm · Cá nhân hoá · Trợ lý AI · Nội dung. */
export const featureGroups = [
  'records',
  'keepsakes',
  'personalization',
  'assistant',
  'content',
] as const;
export type FeatureGroup = (typeof featureGroups)[number];

/** Gói: Miễn phí · Premium · Beta (plan §2.4). */
export const featureTiers = ['free', 'premium', 'beta'] as const;
export type FeatureTier = (typeof featureTiers)[number];

export interface CatalogueFeature {
  key: FeatureKey;
  group: FeatureGroup;
  /** Portal message ids (web `messages.ts`, vi and en): the row name and its one-line help. */
  labelId: string;
  helpId: string;
  /**
   * Flags in front of the feature. The first is its kill switch ("Công tắc khẩn") and its rollout
   * ("Phát hành"); the others switch parts of it (the assistant's photos, care, upsell), each with
   * its own kill switch and rollout, under the same tier and overrides. Empty: no flag.
   */
  flags: readonly FlagKey[];
  /** Capabilities the feature stands for in `getCapabilities` (and every server gate). */
  capabilities: readonly Capability[];
  defaultTier: FeatureTier;
  /** Whether staff may change the tier (engineering switches are never in the catalogue). */
  tierable: boolean;
  /**
   * Premium tier only: families without Premium still use it inside the rollout, limited by the
   * household's assistant credits (D-075 #1). The Premium credit budget itself always follows the
   * grants (`assistant.premium_budget`), whatever the tier.
   */
  credits: boolean;
}

const feature = (
  key: FeatureKey,
  group: FeatureGroup,
  flags: readonly FlagKey[],
  capabilities: readonly Capability[],
  defaultTier: FeatureTier,
  credits = false,
): CatalogueFeature => ({
  key,
  group,
  labelId: `hub.feature.${key}`,
  helpId: `hub.feature.${key}.help`,
  flags,
  capabilities,
  defaultTier,
  tierable: true,
  credits,
});

/** Catalogue v1, mapped onto today's flags and capabilities (plan §2.1 table). */
export const featureCatalogue: readonly CatalogueFeature[] = [
  // Nhịp lớn lên: reference calendar and check-in.
  feature('rhythm', 'personalization', ['rhythm'], ['wonder.reference', 'rhythm.checkin'], 'free'),
  // Gợi ý cá nhân hoá liên mục, Nhịp lớn lên nâng cao (group A).
  feature(
    'personalization',
    'personalization',
    ['personalization'],
    ['personalization.cross_module', 'rhythm.advanced'],
    'premium',
  ),
  // AI tóm tắt và giải thích: open to every plan within credits (D-075 #1).
  feature('ai_assist', 'assistant', ['ai_assist'], ['ai.assistance'], 'premium', true),
  // Trợ lý (chat, ảnh, hướng dẫn chăm sóc): Premium = the bigger credit budget.
  feature(
    'assistant',
    'assistant',
    ['assistant', 'assistant_images', 'assistant_care', 'assistant_upsell'],
    [],
    'premium',
    true,
  ),
  // Mẫu kỷ niệm Premium (group B); the portal's Cao cấp mode still applies per template.
  feature('templates_premium', 'keepsakes', [], ['templates.premium'], 'premium'),
  feature('milestone_cards', 'keepsakes', ['milestone_cards'], [], 'beta'),
  feature('memory_story', 'keepsakes', ['memory_story'], ['render.video'], 'beta'),
  feature('auto_save', 'keepsakes', ['auto_save'], [], 'beta'),
  feature('ai_story_drafts', 'keepsakes', ['ai_story_drafts'], [], 'beta'),
];

const byKey = new Map(featureCatalogue.map((f) => [f.key, f]));

export function catalogueFeature(key: FeatureKey): CatalogueFeature {
  return byKey.get(key)!;
}

/** The catalogue feature a flag belongs to, or null for an engineering switch. */
export function featureOfFlag(flag: FlagKey): CatalogueFeature | null {
  return featureCatalogue.find((f) => f.flags.includes(flag)) ?? null;
}

/** The catalogue feature a capability belongs to, or null (basic modules, the credit budget). */
export function featureOfCapability(capability: Capability): CatalogueFeature | null {
  return featureCatalogue.find((f) => f.capabilities.includes(capability)) ?? null;
}

/** "Công tắc hệ thống": flags outside the catalogue (uploads, invites, live model calls…). */
export const systemFlagKeys: readonly FlagKey[] = flagKeys.filter((k) => !featureOfFlag(k));

// ---------- `config/features` (server only) ----------

const familyIdSchema = z.string().min(1).max(128);

/** Days a family that had a feature keeps it after the feature moves to Premium (plan §2.4). */
export const FEATURE_GRACE_DAYS = 30;

/**
 * The 30-day grace written when a feature moves from Miễn phí or Beta to Premium: the rollout of
 * its main flag (and its beta list) at that moment, so every family that had it then keeps it
 * until `until`. Stored as the rule rather than one override per family, so a move with an
 * "everyone" rollout writes one document.
 */
export const featureGraceSchema = z.object({
  since: z.iso.datetime(),
  until: z.iso.datetime(),
  from: z.enum(['free', 'beta']),
  rollout: flagSchema.pick({ enabled: true, scope: true, percent: true, families: true }),
  betaFamilies: z.array(familyIdSchema).max(500).default([]),
});
export type FeatureGrace = z.infer<typeof featureGraceSchema>;

export const featureHubEntrySchema = z.object({
  tier: z.enum(featureTiers),
  /** Beta: families picked for the beta (ids; codes on the portal), on top of the rollout. */
  betaFamilies: z.array(familyIdSchema).max(500).default([]),
  grace: featureGraceSchema.nullable().default(null),
});
export type FeatureHubEntry = z.infer<typeof featureHubEntrySchema>;

export function defaultFeatureEntry(key: FeatureKey): FeatureHubEntry {
  return { tier: catalogueFeature(key).defaultTier, betaFamilies: [], grace: null };
}

export const defaultFeaturesConfig = (): { features: Record<FeatureKey, FeatureHubEntry> } => ({
  features: Object.fromEntries(featureKeys.map((k) => [k, defaultFeatureEntry(k)])) as Record<
    FeatureKey,
    FeatureHubEntry
  >,
});

/**
 * `config/features`. A missing document, or a feature added after it was written, reads as the
 * catalogue's default tier, so the hub never changes what families get until staff change it.
 */
export const featuresConfigSchema = z.object({
  features: z
    .object(
      Object.fromEntries(
        featureKeys.map((k) => [k, featureHubEntrySchema.default(() => defaultFeatureEntry(k))]),
      ) as Record<FeatureKey, z.ZodDefault<typeof featureHubEntrySchema>>,
    )
    .default(() => defaultFeaturesConfig().features),
});
export type FeaturesConfig = z.infer<typeof featuresConfigSchema>;

/** The tier in force: the stored one, or the default for a feature that is not tierable. */
export function featureTierOf(config: FeaturesConfig, key: FeatureKey): FeatureTier {
  const f = catalogueFeature(key);
  return f.tierable ? config.features[key].tier : f.defaultTier;
}

// ---------- `families/{familyId}/featureOverrides/{featureKey}` ----------

export const featureOverrideStates = ['on', 'off'] as const;
export type FeatureOverrideState = (typeof featureOverrideStates)[number];

/** Written by staff callables only (Rules deny clients); the household shares it. */
export const featureOverrideSchema = z.object({
  feature: z.enum(featureKeys),
  state: z.enum(featureOverrideStates),
  /** Exclusive end; null = until staff set it back to "Theo quy tắc". */
  until: z.date().nullable(),
  byUid: z.string().min(1).max(128),
  byName: z.string().max(120),
  at: z.date(),
});
export type FeatureOverride = z.infer<typeof featureOverrideSchema>;

/** The override in force at [now], or null (none, or ended). */
export function activeOverride(
  o: Pick<FeatureOverride, 'state' | 'until'> | null | undefined,
  now: Date,
): FeatureOverrideState | null {
  if (!o) return null;
  if (o.until && o.until.getTime() <= now.getTime()) return null;
  return o.state;
}

// ---------- The rule (plan §2.2) ----------

/** Why a family has, or lacks, a feature: the portal shows one line per code. */
export const featureExplanations = [
  /** Kill switch off: nobody. */
  'killed',
  /** Admin override "Bật" for this family. */
  'override_on',
  /** Admin override "Tắt" for this family. */
  'override_off',
  /** Premium feature, paid Premium (in a supported region). */
  'premium_paid',
  /** Premium feature, Premium granted by an admin (no region check). */
  'premium_admin',
  /** Premium feature the family had before it moved to Premium (30 days). */
  'grace',
  /** Premium feature through a beta campaign grant, inside the rollout and region. */
  'beta_campaign',
  /** Premium feature open within the household credits, inside the rollout and region. */
  'credits',
  /** Beta feature: picked for the beta or inside its rollout. */
  'beta',
  /** Free feature inside its rollout. */
  'free',
  /** The rollout does not reach this family yet. */
  'not_released',
  /** Beta feature and the family is not in the beta. */
  'not_in_beta',
  /** The household's country is not an advanced region. */
  'region',
  /** Premium feature, released, and no Premium: the paywall (when billing is on). */
  'premium_required',
] as const;
export type FeatureExplanation = (typeof featureExplanations)[number];

export interface FeatureRuleInput {
  tier: FeatureTier;
  /** The flag's `enabled`; null when the feature has no flag (nothing to kill). */
  killSwitchOn: boolean | null;
  /** The flag's rollout reaches the family; null when there is no flag: everyone for Miễn phí
   * and Premium, only the picked families for Beta. */
  rolloutOn: boolean | null;
  override: FeatureOverrideState | null;
  /** A valid paid grant gives it (counts only in a supported region: today's rule). */
  paid: boolean;
  /** A valid staff grant (promo, "Bật toàn bộ Premium") gives it: no region check. */
  staff: boolean;
  /** A valid beta grant (campaign or hand-written) gives it. */
  betaGrant: boolean;
  regionSupported: boolean;
  /** The region also gates the paths without Premium (true for Premium capabilities). */
  regionApplies: boolean;
  /** In the feature's beta list (`config/features`). */
  betaListed: boolean;
  /** Reached by the feature's grace when it moved to Premium (`inFeatureGrace`). */
  grace: boolean;
  /** `CatalogueFeature.credits`. */
  credits: boolean;
}

export interface FeatureDecision {
  on: boolean;
  why: FeatureExplanation;
  /** For `getCapabilities`: where an open feature comes from; null when closed. */
  via: GrantSource | 'free' | null;
}

/**
 * Plan §2.2, in order: (1) kill switch off → nobody; (2) the admin override → that; (3) Premium →
 * every family with Premium, whatever the rollout (a paid grant in a supported region, or a staff
 * grant anywhere), then the 30-day grace, then the rollout for everyone else (beta campaign,
 * credits, or the paywall); (4) Beta → its picked families and its rollout; (5) Miễn phí → its
 * rollout.
 */
export function decideFeature(x: FeatureRuleInput): FeatureDecision {
  const on = (why: FeatureExplanation, via: GrantSource | 'free'): FeatureDecision => ({
    on: true,
    why,
    via,
  });
  const off = (why: FeatureExplanation): FeatureDecision => ({ on: false, why, via: null });
  if (x.killSwitchOn === false) return off('killed');
  if (x.override === 'on') {
    return on('override_on', x.tier === 'premium' ? 'promo' : x.tier === 'beta' ? 'beta' : 'free');
  }
  if (x.override === 'off') return off('override_off');
  const released = x.rolloutOn ?? x.tier !== 'beta';
  const regionOk = !x.regionApplies || x.regionSupported;
  switch (x.tier) {
    case 'premium':
      // Paid first, so a paying family is reported as paid while a promo also runs.
      if (x.paid && x.regionSupported) return on('premium_paid', 'paid');
      if (x.staff) return on('premium_admin', 'promo');
      if (x.grace && regionOk) return on('grace', 'free');
      if (!released) return off('not_released');
      if (!regionOk) return off('region');
      if (x.betaGrant) return on('beta_campaign', 'beta');
      if (x.credits) return on('credits', 'free');
      return off('premium_required');
    case 'beta':
      if (!x.betaListed && !released) return off('not_in_beta');
      if (!regionOk) return off('region');
      return on('beta', 'beta');
    case 'free':
      if (!released) return off('not_released');
      if (!regionOk) return off('region');
      return on('free', 'free');
  }
}

/**
 * The feature is shown to the family (its entry points; the app's paywall or region notice takes
 * over inside): open, or closed only for want of Premium or of a supported region. This is what
 * `getCapabilities.features` and the assistant switches report.
 */
export function featureVisible(d: FeatureDecision): boolean {
  return d.on || d.why === 'premium_required' || d.why === 'region';
}

/** The app's gate reason for a closed feature (only PREMIUM_REQUIRED may show a paywall). */
export function featureGateReason(d: FeatureDecision): GateReason {
  switch (d.why) {
    case 'region':
      return 'REGION_UNAVAILABLE';
    case 'premium_required':
      return 'PREMIUM_REQUIRED';
    default:
      return 'FEATURE_DISABLED';
  }
}

/**
 * Which valid grants give the feature. A grant counts when it gives one of the feature's Premium
 * capabilities; for a feature with none (a free or flag-only feature moved to Premium) any valid
 * grant of that source counts: the family "has Premium".
 */
export function featurePremium(
  grants: readonly GrantView[],
  capabilities: readonly Capability[],
  env: GrantEnvironment,
  now: Date,
): { paid: boolean; staff: boolean; beta: boolean } {
  const wanted = capabilities.filter((c) => !isFreeCapability(c));
  const gives = (g: GrantView) =>
    (wanted.length ? wanted : g.capabilities).some((c) => grantGives(g, c, env, now));
  return {
    paid: grants.some((g) => g.source === 'paid' && gives(g)),
    staff: grants.some((g) => g.source === 'promo' && gives(g)),
    beta: grants.some((g) => g.source === 'beta' && gives(g)),
  };
}

/** Whether a family is inside a feature's grace: it had the feature when it moved to Premium. */
export function inFeatureGrace(
  grace: FeatureGrace | null | undefined,
  f: {
    familyId: string;
    bucket: number;
    internal: boolean;
    /** Families created after the move never had it. */
    createdAt: Date | null;
    now: Date;
  },
): boolean {
  if (!grace) return false;
  if (f.now.getTime() >= Date.parse(grace.until)) return false;
  if (f.createdAt && f.createdAt.getTime() >= Date.parse(grace.since)) return false;
  if (grace.from === 'beta' && grace.betaFamilies.includes(f.familyId)) return true;
  const flag: Flag = { ...grace.rollout, notice: null };
  return isFlagOnForFamily(flag, f.familyId, f.bucket, f.internal);
}

/** Everything the rule needs about one family, read by the server in one place. */
export interface FamilyFeatureFacts {
  familyId: string;
  /** `familyBucket(familyId)`, 0–99. */
  bucket: number;
  internal: boolean;
  createdAt: Date | null;
  country: string | null;
  advancedRegions: readonly string[];
  flags: Flags;
  hub: FeaturesConfig;
  overrides: Partial<Record<FeatureKey, Pick<FeatureOverride, 'state' | 'until'>>>;
  grants: readonly GrantView[];
  environment: GrantEnvironment;
  now: Date;
}

/**
 * The decision for one catalogue feature and one family. `at.flag` asks about one of the
 * feature's switches (visibility: the region never hides an entry point); `at.capability` about
 * one capability (Premium grants must give it; the region gates Premium capabilities); neither:
 * the feature as a whole, as the portal shows it.
 */
export function familyFeatureDecision(
  f: FamilyFeatureFacts,
  key: FeatureKey,
  at: { flag?: FlagKey; capability?: Capability } = {},
): FeatureDecision {
  const feature = catalogueFeature(key);
  const flagKey = at.flag ?? feature.flags[0] ?? null;
  const flag = flagKey ? f.flags[flagKey] : null;
  const capabilities = at.capability ? [at.capability] : feature.capabilities;
  const premium = featurePremium(f.grants, capabilities, f.environment, f.now);
  const entry = f.hub.features[key];
  return decideFeature({
    tier: featureTierOf(f.hub, key),
    killSwitchOn: flag ? flag.enabled : null,
    rolloutOn: flag ? isFlagOnForFamily(flag, f.familyId, f.bucket, f.internal) : null,
    override: activeOverride(f.overrides[key], f.now),
    paid: premium.paid,
    staff: premium.staff,
    betaGrant: premium.beta,
    regionSupported: f.country !== null && f.advancedRegions.includes(f.country),
    regionApplies: at.flag ? false : capabilities.some((c) => !isFreeCapability(c)),
    betaListed: entry.betaFamilies.includes(f.familyId),
    grace: inFeatureGrace(entry.grace, {
      familyId: f.familyId,
      bucket: f.bucket,
      internal: f.internal,
      createdAt: f.createdAt,
      now: f.now,
    }),
    credits: feature.credits,
  });
}

/**
 * `resolveCapability` with the hub's rule: membership and role first (unchanged), then, for a
 * capability in the catalogue, the feature decision instead of flag → region → grants. Without a
 * decision (basic modules, the credit budget) it is `resolveCapability` itself.
 */
export function resolveFeatureCapability(
  x: CapabilityCheck,
  decision: FeatureDecision | null,
): CapabilityResult {
  if (!decision) return resolveCapability(x);
  if (!x.member) return { allowed: false, reason: 'NOT_MEMBER' };
  if (!x.roleAllows) return { allowed: false, reason: 'ROLE_DENIED' };
  return decision.on
    ? { allowed: true, via: decision.via ?? 'free' }
    : { allowed: false, reason: featureGateReason(decision) };
}

// ---------- "Bật toàn bộ Premium" ----------

/** The staff grant behind "Bật toàn bộ Premium": one per family, revoked by "Tắt". */
export const FULL_PREMIUM_GRANT_ID = 'promo_full';
/** `validUntil` of a grant with no end date ("đến khi tắt"); shown as null to the app. */
export const OPEN_ENDED_GRANT_UNTIL = '9999-12-31T00:00:00.000Z';
export function isOpenEndedUntil(d: Date): boolean {
  return d.getUTCFullYear() >= 9000;
}

// ---------- Staff callables (codes, never family ids; no reason needed, D-090) ----------

const featureKeySchema = z.enum(featureKeys);

/**
 * `staffFeatureSetTier`. Moving to Premium from Miễn phí or Beta stores the 30-day grace and
 * answers how many families had it; `dryRun` answers the count for the confirmation, writing
 * nothing.
 */
export const hubSetTierSchema = z.object({
  feature: featureKeySchema,
  tier: z.enum(featureTiers),
  dryRun: z.boolean().default(false),
  reason: staffReasonSchema,
});

/**
 * `staffFeatureSetRollout`: the kill switch and rollout of the feature's main flag, or of one of
 * its sub-switches (`flag`), and optionally its whole beta list (codes). Omitted fields stay.
 */
export const hubSetRolloutSchema = z.object({
  feature: featureKeySchema,
  flag: z.enum(flagKeys).optional(),
  enabled: z.boolean().optional(),
  scope: z.enum(rolloutScopes).optional(),
  percent: z
    .union([z.literal(0), z.literal(10), z.literal(25), z.literal(50), z.literal(100)])
    .optional(),
  /** Shown in the app while the kill switch is off (A11). */
  notice: z.string().trim().max(280).nullable().optional(),
  /** Scope `internal`: the flag's picked families. */
  families: z.array(familyCodeSchema).max(50).optional(),
  /** The beta list in `config/features` (any scope). */
  betaFamilies: z.array(familyCodeSchema).max(500).optional(),
  reason: staffReasonSchema,
});

/**
 * `staffFeatureFamily`: a family code ("F-7Q2K"), an account email or a baby's nickname (exact,
 * as typed). Matched on the server and never echoed back.
 */
export const hubFamilySchema = z.object({ q: z.string().trim().min(1).max(254) });

/** `staffFeatureSetOverride`: Bật / Tắt for one family; `state: null` = Theo quy tắc. */
export const hubSetOverrideSchema = z.object({
  code: familyCodeSchema,
  feature: featureKeySchema,
  state: z.enum(featureOverrideStates).nullable(),
  until: z.iso.datetime().nullable().default(null),
  reason: staffReasonSchema,
});

/** `staffFeatureFullPremium`: "Bật toàn bộ Premium" (no end date by default) or "Tắt". */
export const hubFullPremiumSchema = z.object({
  code: familyCodeSchema,
  on: z.boolean(),
  until: z.iso.datetime().nullable().default(null),
  reason: staffReasonSchema,
});

/** `staffFeatureSetBeta`: "Thêm vào beta" (or take a family out) for one feature. */
export const hubBetaFamilySchema = z.object({
  code: familyCodeSchema,
  feature: featureKeySchema,
  member: z.boolean(),
  reason: staffReasonSchema,
});

export interface StaffHubFlagState {
  key: FlagKey;
  enabled: boolean;
  scope: (typeof rolloutScopes)[number];
  percent: number;
  notice: string | null;
  /** Scope `internal`: picked families, as codes. */
  families: string[];
}

export interface StaffHubRow {
  key: FeatureKey;
  group: FeatureGroup;
  labelId: string;
  helpId: string;
  tier: FeatureTier;
  defaultTier: FeatureTier;
  tierable: boolean;
  credits: boolean;
  capabilities: Capability[];
  /** "Công tắc khẩn" and "Phát hành": the main flag; null when there is none (Mẫu Premium). */
  flag: StaffHubFlagState | null;
  /** Switches in front of parts of the feature (the assistant's photos, care, upsell). */
  subFlags: StaffHubFlagState[];
  /** Beta: picked families, as codes, on top of the rollout. */
  betaFamilies: string[];
  /** Set while the 30-day grace of a move to Premium runs. */
  grace: { since: string; until: string; from: 'free' | 'beta' } | null;
  /** Active admin overrides (scan capped like `StaffFeatureHub.premium.capped`). */
  overrides: { on: number; off: number };
  lastEdit: { by: string; at: string } | null;
}

export interface StaffFeatureHub {
  groups: FeatureGroup[];
  features: StaffHubRow[];
  /** Flags outside the catalogue ("Công tắc hệ thống"); read and set with staffFlags / staffSetFlag. */
  systemFlags: FlagKey[];
  /** Families with valid Premium now (this environment): paid, granted by staff, "toàn bộ". */
  premium: { families: number; paid: number; admin: number; full: number; capped: boolean };
  environment: GrantEnvironment;
  /** The latest hub changes (Lịch sử): actor, action, target, before / after in `detail`. */
  recent: Array<{
    action: string;
    target: string;
    by: string;
    at: string;
    detail: Record<string, unknown> | null;
  }>;
}

export interface StaffHubTierAnswer {
  feature: FeatureKey;
  from: FeatureTier;
  tier: FeatureTier;
  /** Families that have it under the current tier (the confirmation's number). */
  affected: number;
  /** End of the grace stored by a move to Premium; null otherwise. */
  graceUntil: string | null;
  /** False for a dry run or a tier that did not change. */
  applied: boolean;
}

export interface StaffHubFamilyMatch {
  code: string;
  /** Masked owner email ("n***@gmail.com"). */
  owner: string;
  babies: number;
}

export interface StaffHubFamilyFeature {
  key: FeatureKey;
  tier: FeatureTier;
  /** The family has it ("Có"). */
  on: boolean;
  /** Its entry points show (open, or closed only by the paywall / region). */
  visible: boolean;
  why: FeatureExplanation;
  override: { state: FeatureOverrideState; until: string | null; by: string; at: string } | null;
  betaListed: boolean;
  /** The grace this family is inside, if any. */
  graceUntil: string | null;
}

export interface StaffHubFamily {
  code: string;
  country: string | null;
  regionSupported: boolean;
  internal: boolean;
  plan: HouseholdPlan;
  /** Null when the plan shown has no end ("đến khi tắt") or there is none. */
  validUntil: string | null;
  /** "Bật toàn bộ Premium": on, and its end (null = until turned off). */
  fullPremium: { on: boolean; until: string | null };
  grants: Array<{
    id: string;
    source: GrantSource;
    status: GrantStatus;
    environment: GrantEnvironment;
    capabilities: Capability[];
    validFrom: string;
    /** Null = no end date. */
    validUntil: string | null;
    provider: 'apple' | 'google' | 'staff' | null;
    /** From open campaigns, not stored: cannot be revoked one family at a time. */
    fromCampaign: boolean;
  }>;
  features: StaffHubFamilyFeature[];
}

export interface StaffHubFamilyAnswer {
  matchedBy: 'code' | 'email' | 'nickname' | null;
  /** Every family the query found (at most 10). */
  matches: StaffHubFamilyMatch[];
  /** The detail when exactly one family matched. */
  family: StaffHubFamily | null;
}
