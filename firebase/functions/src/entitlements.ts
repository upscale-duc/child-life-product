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
  familySettingsRequestSchema,
  firebaseProjectIds,
  flagsSchema,
  grantSchema,
  householdPlan,
  isFlagOnForFamily,
  isIanaTimeZone,
  resolveCapability,
  type CapabilitiesAnswer,
  type Capability,
  type CapabilityResult,
  type CapabilityState,
  type EntitlementsConfig,
  type FamilyAction,
  type FlagKey,
  type Flags,
  type GateReason,
  type Grant,
  type GrantEnvironment,
  type GrantView,
  type MemberGrant,
} from '@child-life/contracts';
import { currentProjectId } from './env.js';
import { familyBucket } from './features.js';

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

export interface EntitlementContext {
  uid: string;
  babyId: string;
  familyId: string;
  /** Null when the caller is not an active member (left, expired, never invited). */
  member: (MemberGrant & { uid: string }) | null;
  family: {
    ownerUid: string | null;
    country: string | null;
    timeZone: string | null;
    internal: boolean;
    entitlementVersion: number;
  };
  flags: Flags;
  config: EntitlementsConfig;
  environment: GrantEnvironment;
  /** Stored grants (paid / promo / any beta written by staff) plus open beta campaigns
   * (`id` = `campaign:<campaignId>`). */
  grants: (GrantView &
    Partial<Pick<Grant, 'autoRenew' | 'billingOwnerUid' | 'provider'>> & { id: string })[];
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
  const [familySnap, flagsSnap, config, grantDocs] = await Promise.all([
    db.doc(`families/${familyId}`).get(),
    db.doc('config/flags').get(),
    readEntitlementsConfig(db),
    db.collection(`families/${familyId}/grants`).get(),
  ]);
  const flags = flagsSchema.safeParse(flagsSnap.data() ?? {});
  const family = {
    ownerUid: (familySnap.get('ownerUid') as string | undefined) ?? null,
    country: (familySnap.get('country') as string | undefined) ?? null,
    timeZone: (familySnap.get('timeZone') as string | undefined) ?? null,
    internal: familySnap.get('internal') === true,
    entitlementVersion: (familySnap.get('entitlementVersion') as number | undefined) ?? 0,
  };
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
    uid,
    babyId,
    familyId,
    member: active
      ? {
          uid,
          role: memberSnap.get('role'),
          isOwner: memberSnap.get('isOwner') === true,
          extraRights: memberSnap.get('extraRights') ?? null,
        }
      : null,
    family,
    flags: flags.success ? flags.data : flagsSchema.parse({}),
    config,
    environment,
    grants,
  };
}

/** Whether flag [key] is on for the context's family (rollout bucket, internal families). */
export function flagOn(ctx: EntitlementContext, key: FlagKey): boolean {
  return isFlagOnForFamily(
    ctx.flags[key],
    ctx.familyId,
    familyBucket(ctx.familyId),
    ctx.family.internal,
  );
}

/** Membership → role → kill switch → free → region → grants, for one capability. */
export function checkCapability(
  ctx: EntitlementContext,
  capability: Capability,
  now: Date,
  action: FamilyAction = capabilityAction[capability],
): CapabilityResult {
  const flagKey = capabilityFlag[capability];
  const featureEnabled = flagKey === null || flagOn(ctx, flagKey);
  return resolveCapability({
    capability,
    now,
    member: ctx.member !== null,
    roleAllows: ctx.member !== null && familyCan(ctx.member, action),
    featureEnabled,
    regionSupported:
      ctx.family.country !== null && ctx.config.regions.advanced.includes(ctx.family.country),
    environment: ctx.environment,
    grants: ctx.grants,
  });
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
    validUntil: plan.validUntil?.toISOString() ?? null,
    autoRenew: plan.autoRenew,
    isBillingOwner: plan.billingOwnerUid !== null && plan.billingOwnerUid === uid,
    provider:
      plan.plan === 'premium' || plan.plan === 'expired' || plan.plan === 'pending'
        ? (ctx.grants
            .filter((g) => g.source !== 'beta' && g.validUntil.getTime() === plan.validUntil?.getTime())
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
 * `templates.premium` (paid or promo; Beta A never). Role and flags are checked by the caller.
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
