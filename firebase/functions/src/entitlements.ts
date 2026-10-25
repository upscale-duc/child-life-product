import type { Firestore, Timestamp } from 'firebase-admin/firestore';
import {
  campaignOpen,
  capabilities,
  capabilitiesRequestSchema,
  capabilityAction,
  capabilityFlag,
  defaultEntitlementsConfig,
  entitlementsConfigSchema,
  familyCan,
  familyFeatureDecision,
  familySettingsRequestSchema,
  featurePremium,
  featureOfCapability,
  featureOfFlag,
  featureOverrideSchema,
  featureVisible,
  featuresConfigSchema,
  firebaseProjectIds,
  flagsSchema,
  grantSchema,
  householdPlan,
  isFlagOnForFamily,
  isIanaTimeZone,
  isOpenEndedUntil,
  resolveFeatureCapability,
  type CapabilitiesAnswer,
  type Capability,
  type CapabilityResult,
  type CapabilityState,
  type EntitlementsConfig,
  type FamilyAction,
  type FamilyFeatureFacts,
  type FeatureDecision,
  type FeatureKey,
  type FeatureOverride,
  type FeaturesConfig,
  type FlagKey,
  type Flags,
  type GateReason,
  type Grant,
  type GrantEnvironment,
  type GrantView,
  type MemberGrant,
} from '@child-life/contracts';
import { currentProjectId } from './env.js';
import { familyBucket } from './bucket.js';

/**
 * Child Life Premium & Cá nhân hoá: the server capability resolver (brief p.8, plan §5.1). Every
 * gated callable goes through `requireCapability`; a client flag or cached badge grants nothing.
 */
export class EntitlementError extends Error {
  constructor(
    readonly code:
      | 'invalid-argument'
      | 'permission-denied'
      | 'not-found'
      | 'failed-precondition'
      | 'resource-exhausted',
    /** A gate reason (NOT_MEMBER, PREMIUM_REQUIRED…) or a slug for request problems. */
    readonly reason: GateReason | 'bad-request' | 'no-family' | 'not-a-member',
  ) {
    super(reason);
  }
}

export function gateError(reason: GateReason): EntitlementError {
  return new EntitlementError(
    reason === 'QUOTA_EXCEEDED' ? 'resource-exhausted' : 'permission-denied',
    reason,
  );
}

/** Store sandbox and dev give `test` grants; only prod honours `production` (M08). */
export function grantEnvironmentFor(env: 'dev' | 'prod'): GrantEnvironment {
  return env === 'prod' ? 'production' : 'test';
}

/** The running project's grant environment; anything but the prod project (emulators, tests,
 * dev) is `test`, so a misconfigured runtime never honours production grants by accident. */
export function serverGrantEnvironment(): GrantEnvironment {
  return currentProjectId() === firebaseProjectIds.prod ? 'production' : 'test';
}

/** What decides a family's features and capabilities, without a caller (D-089 hub rule). */
export interface FamilyEntitlements {
  familyId: string;
  family: {
    ownerUid: string | null;
    country: string | null;
    timeZone: string | null;
    internal: boolean;
    entitlementVersion: number;
    /** Families created after a move to Premium are outside its grace. */
    createdAt: Date | null;
  };
  flags: Flags;
  config: EntitlementsConfig;
  environment: GrantEnvironment;
  /** Stored grants (paid / promo / any beta written by staff) plus open beta campaigns
   * (`id` = `campaign:<campaignId>`). */
  grants: (GrantView &
    Partial<Pick<Grant, 'autoRenew' | 'billingOwnerUid' | 'provider'>> & { id: string })[];
  /** `config/features`: tiers, beta lists, graces (defaults when missing). */
  hub: FeaturesConfig;
  /** `families/{f}/featureOverrides`: the admin overrides, ended ones included. */
  overrides: Partial<Record<FeatureKey, FeatureOverride>>;
  /** The instant the state was read for: overrides, graces and grants are judged at it. */
  now: Date;
}

export interface EntitlementContext extends FamilyEntitlements {
  uid: string;
  babyId: string;
  /** Null when the caller is not an active member (left, expired, never invited). */
  member: (MemberGrant & { uid: string }) | null;
}

const toDate = (v: unknown): Date | null =>
  v && typeof (v as Timestamp).toDate === 'function' ? (v as Timestamp).toDate() : null;

/** `config/entitlements`; a missing or invalid document reads as the safe default (no region). */
export async function readEntitlementsConfig(db: Firestore): Promise<EntitlementsConfig> {
  const parsed = entitlementsConfigSchema.safeParse(
    (await db.doc('config/entitlements').get()).data(),
  );
  return parsed.success ? parsed.data : defaultEntitlementsConfig;
}

/** `config/features` (D-089); a missing or invalid document reads as the catalogue defaults. */
export async function readFeaturesConfig(db: Firestore): Promise<FeaturesConfig> {
  const parsed = featuresConfigSchema.safeParse(
    (await db.doc('config/features').get()).data() ?? {},
  );
  return parsed.success ? parsed.data : featuresConfigSchema.parse({});
}

/** A family's flags, config, grants (with open campaigns), hub tiers and overrides at [now]. */
export async function loadFamilyEntitlements(
  db: Firestore,
  familyId: string,
  now: Date,
  environment: GrantEnvironment,
): Promise<FamilyEntitlements> {
  const [familySnap, flagsSnap, config, grantDocs, hub, overrideDocs] = await Promise.all([
    db.doc(`families/${familyId}`).get(),
    db.doc('config/flags').get(),
    readEntitlementsConfig(db),
    db.collection(`families/${familyId}/grants`).get(),
    readFeaturesConfig(db),
    db.collection(`families/${familyId}/featureOverrides`).get(),
  ]);
  const flags = flagsSchema.safeParse(flagsSnap.data() ?? {});
  const family = {
    ownerUid: (familySnap.get('ownerUid') as string | undefined) ?? null,
    country: (familySnap.get('country') as string | undefined) ?? null,
    timeZone: (familySnap.get('timeZone') as string | undefined) ?? null,
    internal: familySnap.get('internal') === true,
    entitlementVersion: (familySnap.get('entitlementVersion') as number | undefined) ?? 0,
    createdAt: toDate(familySnap.get('createdAt')),
  };
  const overrides: FamilyEntitlements['overrides'] = {};
  for (const doc of overrideDocs.docs) {
    const d = doc.data();
    const parsed = featureOverrideSchema.safeParse({
      ...d,
      until: toDate(d.until),
      at: toDate(d.at),
    });
    // A malformed override is no override: the rule applies.
    if (parsed.success && parsed.data.feature === doc.id)
      overrides[parsed.data.feature] = parsed.data;
  }
  const grants: EntitlementContext['grants'] = [];
  for (const doc of grantDocs.docs) {
    const d = doc.data();
    const parsed = grantSchema.safeParse({
      ...d,
      validFrom: toDate(d.validFrom),
      validUntil: toDate(d.validUntil),
      updatedAt: toDate(d.updatedAt),
    });
    // A malformed grant gives nothing; it never blocks the others (E11).
    if (parsed.success) grants.push({ ...parsed.data, id: doc.id });
  }
  // Beta A (brief p.3): an open campaign in the family's country is a grant of its own.
  if (family.country) {
    const bucket = familyBucket(familyId);
    for (const c of config.betaCampaigns) {
      const countries = c.countries.length > 0 ? c.countries : config.regions.advanced;
      if (!countries.includes(family.country)) continue;
      if (!campaignOpen(c, now, familyId, bucket, family.internal)) continue;
      grants.push({
        id: `campaign:${c.id}`,
        source: 'beta',
        status: 'active',
        environment,
        capabilities: c.capabilities,
        validFrom: new Date(c.validFrom),
        validUntil: new Date(c.validUntil),
        autoRenew: false,
        billingOwnerUid: null,
      });
    }
  }
  return {
    familyId,
    family,
    flags: flags.success ? flags.data : flagsSchema.parse({}),
    config,
    environment,
    grants,
    hub,
    overrides,
    now,
  };
}

export async function loadEntitlementContext(
  db: Firestore,
  uid: string,
  babyId: string,
  now: Date,
  environment: GrantEnvironment,
): Promise<EntitlementContext> {
  const [memberSnap, babySnap] = await Promise.all([
    db.doc(`babies/${babyId}/members/${uid}`).get(),
    db.doc(`babies/${babyId}`).get(),
  ]);
  const familyId = babySnap.get('familyId') as string | undefined;
  if (!familyId) throw new EntitlementError('not-found', 'no-family');
  const until = toDate(memberSnap.get('accessUntilAt'));
  const active =
    memberSnap.exists &&
    memberSnap.get('status') === 'active' &&
    (!until || until.getTime() > now.getTime());
  const state = await loadFamilyEntitlements(db, familyId, now, environment);
  return {
    ...state,
    uid,
    babyId,
    member: active
      ? {
          uid,
          role: memberSnap.get('role'),
          isOwner: memberSnap.get('isOwner') === true,
          extraRights: memberSnap.get('extraRights') ?? null,
        }
      : null,
  };
}

/** The facts the hub's rule reads for this family (`familyFeatureDecision`). */
export function featureFacts(state: FamilyEntitlements, now: Date = state.now): FamilyFeatureFacts {
  return {
    familyId: state.familyId,
    bucket: familyBucket(state.familyId),
    internal: state.family.internal,
    createdAt: state.family.createdAt,
    country: state.family.country,
    advancedRegions: state.config.regions.advanced,
    flags: state.flags,
    hub: state.hub,
    overrides: state.overrides,
    grants: state.grants,
    environment: state.environment,
    now,
  };
}

/**
 * D-089 (plan §2.2): kill switch → admin override → Premium (skips the rollout; an admin grant
 * skips the region) → Beta → Miễn phí, for one catalogue feature of this family.
 */
export function featureDecision(
  state: FamilyEntitlements,
  key: FeatureKey,
  at: { flag?: FlagKey; capability?: Capability } = {},
  now: Date = state.now,
): FeatureDecision {
  return familyFeatureDecision(featureFacts(state, now), key, at);
}

/** Whether the family has the feature (server gates for Tự lưu, Kỷ niệm 2.0 and AI drafts). */
export function familyFeatureOn(state: FamilyEntitlements, key: FeatureKey): boolean {
  return featureDecision(state, key).on;
}

/** `familyFeatureOn` for a family id: loads the state first (callers without a context). */
export async function familyFeatureEnabled(
  db: Firestore,
  familyId: string,
  key: FeatureKey,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<boolean> {
  return familyFeatureOn(await loadFamilyEntitlements(db, familyId, now, environment), key);
}

/**
 * Whether flag [key] is on for the context's family. An engineering switch: its rollout bucket
 * and internal families. A catalogue feature's switch (D-089): shown when the hub's rule opens
 * the feature, or closes it only for the paywall / region (Premium skips the rollout, overrides
 * win), so the app's entry points and the server's gates agree.
 */
export function flagOn(ctx: FamilyEntitlements, key: FlagKey): boolean {
  const feature = featureOfFlag(key);
  if (feature) return featureVisible(featureDecision(ctx, feature.key, { flag: key }));
  return isFlagOnForFamily(
    ctx.flags[key],
    ctx.familyId,
    familyBucket(ctx.familyId),
    ctx.family.internal,
  );
}

function capabilityResult(
  ctx: FamilyEntitlements,
  capability: Capability,
  now: Date,
  member: boolean,
  roleAllows: boolean,
): CapabilityResult {
  const flagKey = capabilityFlag[capability];
  const feature = featureOfCapability(capability);
  // Outside the catalogue (the Premium credit budget): an admin grant skips the country check
  // too (D-089); a paid grant keeps it.
  const staffGrant =
    !feature && featurePremium(ctx.grants, [capability], ctx.environment, now).staff;
  return resolveFeatureCapability(
    {
      capability,
      now,
      member,
      roleAllows,
      featureEnabled: flagKey === null || flagOn(ctx, flagKey),
      regionSupported:
        staffGrant ||
        (ctx.family.country !== null && ctx.config.regions.advanced.includes(ctx.family.country)),
      environment: ctx.environment,
      grants: ctx.grants,
    },
    feature ? featureDecision(ctx, feature.key, { capability }, now) : null,
  );
}

/**
 * Membership → role, then for a catalogue capability the hub's rule (D-089: kill switch →
 * override → Premium → Beta → Miễn phí, with region and credits), else kill switch → free →
 * region → grants.
 */
export function checkCapability(
  ctx: EntitlementContext,
  capability: Capability,
  now: Date,
  action: FamilyAction = capabilityAction[capability],
): CapabilityResult {
  return capabilityResult(
    ctx,
    capability,
    now,
    ctx.member !== null,
    ctx.member !== null && familyCan(ctx.member, action),
  );
}

/** What the app is told about [capability], seen as the family owner (portal views). */
export function capabilityStateAsOwner(
  state: FamilyEntitlements,
  capability: Capability,
  now: Date = state.now,
): CapabilityState {
  const r = capabilityResult(state, capability, now, true, true);
  return r.allowed
    ? { allowed: true, reason: null, via: r.via }
    : { allowed: false, reason: r.reason, via: null };
}

/** Loads the context and throws the gate reason unless [capability] is allowed for [action]. */
export async function requireCapability(
  db: Firestore,
  uid: string,
  babyId: string,
  capability: Capability,
  now: Date,
  environment: GrantEnvironment,
  action?: FamilyAction,
): Promise<EntitlementContext> {
  const ctx = await loadEntitlementContext(db, uid, babyId, now, environment);
  const result = checkCapability(ctx, capability, now, action);
  if (!result.allowed) throw gateError(result.reason);
  return ctx;
}

/** `getCapabilities` (H01, PR03, ST02): what the app may draw. The server re-checks each action. */
export async function getCapabilities(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
  environment: GrantEnvironment,
): Promise<CapabilitiesAnswer> {
  const parsed = capabilitiesRequestSchema.safeParse(data);
  if (!parsed.success) throw new EntitlementError('invalid-argument', 'bad-request');
  const ctx = await loadEntitlementContext(db, uid, parsed.data.babyId, now, environment);
  if (!ctx.member) throw new EntitlementError('permission-denied', 'not-a-member');
  const states = Object.fromEntries(
    capabilities.map((c): [Capability, CapabilityState] => {
      const r = checkCapability(ctx, c, now);
      return [
        c,
        r.allowed
          ? { allowed: true, reason: null, via: r.via }
          : { allowed: false, reason: r.reason, via: null },
      ];
    }),
  ) as Record<Capability, CapabilityState>;
  const plan = householdPlan(ctx.grants, environment, now);
  return {
    familyId: ctx.familyId,
    policyVersion: ctx.config.policyVersion,
    entitlementVersion: ctx.family.entitlementVersion,
    plan: plan.plan,
    // "Bật toàn bộ Premium" with no end date: no date to show.
    validUntil:
      plan.validUntil && !isOpenEndedUntil(plan.validUntil) ? plan.validUntil.toISOString() : null,
    autoRenew: plan.autoRenew,
    isBillingOwner: plan.billingOwnerUid !== null && plan.billingOwnerUid === uid,
    provider:
      plan.plan === 'premium' || plan.plan === 'expired' || plan.plan === 'pending'
        ? (ctx.grants
            .filter(
              (g) => g.source !== 'beta' && g.validUntil.getTime() === plan.validUntil?.getTime(),
            )
            .map((g) => g.provider ?? null)[0] ?? null)
        : null,
    canManageBilling: familyCan(ctx.member, 'billing.manage'),
    country: ctx.family.country,
    capabilities: states,
    features: {
      rhythm: flagOn(ctx, 'rhythm'),
      personalization: flagOn(ctx, 'personalization'),
      aiAssist: flagOn(ctx, 'ai_assist'),
      billing: flagOn(ctx, 'premium_billing'),
      assistant: flagOn(ctx, 'assistant'),
      assistantImages: flagOn(ctx, 'assistant_images'),
      assistantCare: flagOn(ctx, 'assistant_care'),
      assistantUpsell: flagOn(ctx, 'assistant_upsell'),
      adaptiveExperience: flagOn(ctx, 'adaptive_experience'),
      adaptiveNav: flagOn(ctx, 'adaptive_experience') && flagOn(ctx, 'adaptive_nav'),
      premiumV2: flagOn(ctx, 'premium_v2'),
    },
  };
}

/**
 * `setFamilySettings` (D-072 #1/#3): the owner sets the household's country (first open of Nhịp
 * lớn lên) and time zone. Only these two fields; never grants or quota.
 */
export async function setFamilySettings(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ country: string | null; timeZone: string | null }> {
  const parsed = familySettingsRequestSchema.safeParse(data);
  if (!parsed.success) throw new EntitlementError('invalid-argument', 'bad-request');
  const { babyId, country, timeZone } = parsed.data;
  if (timeZone !== undefined && !isIanaTimeZone(timeZone)) {
    throw new EntitlementError('invalid-argument', 'bad-request');
  }
  const ctx = await loadEntitlementContext(db, uid, babyId, now, 'test');
  if (!ctx.member) throw new EntitlementError('permission-denied', 'not-a-member');
  if (!familyCan(ctx.member, 'family.settings')) throw gateError('ROLE_DENIED');
  const update: Record<string, unknown> = { settingsUpdatedAt: now, settingsUpdatedBy: uid };
  if (country !== undefined) update.country = country;
  if (timeZone !== undefined) update.timeZone = timeZone;
  await db.doc(`families/${ctx.familyId}`).set(update, { merge: true });
  return {
    country: country ?? ctx.family.country,
    timeZone: timeZone ?? ctx.family.timeZone,
  };
}

/**
 * Kỷ niệm 2.0 Cao cấp templates in `subscribers` mode (Q1): the caller's family has
 * `templates.premium` (paid, promo, or a beta campaign that includes it, D-075 #1). Role and
 * flags are checked by the caller.
 */
export async function hasPremiumTemplates(
  db: Firestore,
  uid: string,
  babyId: string,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<boolean> {
  const ctx = await loadEntitlementContext(db, uid, babyId, now, environment);
  return checkCapability(ctx, 'templates.premium', now).allowed;
}
