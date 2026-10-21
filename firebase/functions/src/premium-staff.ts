import { FieldValue, Timestamp, type Firestore } from 'firebase-admin/firestore';
import {
  capabilities,
  defaultEntitlementsConfig,
  entitlementsConfigSchema,
  familyPremiumSchema,
  flagKeys,
  grantPromoSchema,
  householdPlan,
  revokeGrantSchema,
  setEntitlementsConfigSchema,
  type Capability,
  type CapabilityState,
  type EntitlementsConfig,
  type FlagKey,
  type GrantEnvironment,
  type StaffFamilyPremium,
} from '@child-life/contracts';
import {
  capabilityStateAsOwner,
  flagOn,
  loadEntitlementContext,
  serverGrantEnvironment,
} from './entitlements.js';
import {
  familyCode,
  familyIdsOf,
  parse,
  requireStaff,
  StaffError,
  staffAudit,
  type Staff,
} from './staff.js';

/**
 * Portal "Premium" (plan §5.6): regions, quotas and Beta A campaigns in `config/entitlements`,
 * and promo grants per family. Every change needs a reason and writes the audit log; paid grants
 * come only from verified store purchases, never from here (brief p.17).
 */

const iso = (v: unknown) =>
  new Date(
    v instanceof Timestamp ? v.toMillis() : v instanceof Date ? v.getTime() : 0,
  ).toISOString();

/** Campaign families as codes for the portal. */
function withCodes(config: EntitlementsConfig) {
  return {
    ...config,
    betaCampaigns: config.betaCampaigns.map((c) =>
      c.families?.length ? { ...c, families: c.families.map(familyCode) } : c,
    ),
  };
}

export async function readPremium(db: Firestore, staff: Staff | null) {
  requireStaff(staff, 'premium.view');
  const parsed = entitlementsConfigSchema.safeParse(
    (await db.doc('config/entitlements').get()).data(),
  );
  const recent = await db
    .collection('staffAudit')
    .where('category', '==', 'premium')
    .orderBy('at', 'desc')
    .limit(10)
    .get();
  return {
    config: withCodes(parsed.success ? parsed.data : defaultEntitlementsConfig),
    stored: parsed.success,
    environment: serverGrantEnvironment(),
    recent: recent.docs.map((a) => ({
      action: a.get('action') as string,
      target: a.get('target') as string,
      by: a.get('actorName') as string,
      at: iso(a.get('at')),
      reason: a.get('reason') as string,
    })),
  };
}

export async function setEntitlementsConfig(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const req = parse(setEntitlementsConfigSchema, data);
  const s = requireStaff(staff, 'premium.config');
  const campaigns = [];
  for (const c of req.config.betaCampaigns) {
    if (Date.parse(c.validUntil) <= Date.parse(c.validFrom)) {
      throw new StaffError('invalid-argument', 'bad-dates');
    }
    campaigns.push(c.families?.length ? { ...c, families: await familyIdsOf(db, c.families) } : c);
  }
  if (new Set(campaigns.map((c) => c.id)).size !== campaigns.length) {
    throw new StaffError('invalid-argument', 'duplicate-campaign');
  }
  const config: EntitlementsConfig = { ...req.config, betaCampaigns: campaigns };
  await db.runTransaction(async (tx) => {
    const ref = db.doc('config/entitlements');
    const before = entitlementsConfigSchema.safeParse((await tx.get(ref)).data());
    tx.set(ref, config);
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'premium.config',
        category: 'premium',
        target: config.policyVersion,
        reason: req.reason,
        detail: {
          before: before.success ? withCodes(before.data) : null,
          after: withCodes(config),
        },
      },
      now,
    );
  });
}

async function familyOf(db: Firestore, code: string): Promise<string> {
  return (await familyIdsOf(db, [code]))[0]!;
}

/** One family's plan and grants (stored and from open campaigns), for support and QA. */
export async function familyPremium(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<StaffFamilyPremium> {
  requireStaff(staff, 'premium.view');
  const { code } = parse(familyPremiumSchema, data);
  const familyId = await familyOf(db, code);
  const babyId = (
    (await db.doc(`families/${familyId}`).get()).get('babyIds') as string[] | undefined
  )?.[0];
  if (!babyId) throw new StaffError('not-found', 'no-baby');
  // The staff member is not a member: the context is used for grants and family fields only.
  const ctx = await loadEntitlementContext(db, 'portal-staff', babyId, now, environment);
  const plan = householdPlan(ctx.grants, environment, now);
  // What the app is told (getCapabilities), seen as the owner: the hub's rule (D-089) for
  // catalogue features, flags → region → grants for the rest.
  const regionSupported =
    ctx.family.country !== null && ctx.config.regions.advanced.includes(ctx.family.country);
  const flags = Object.fromEntries(flagKeys.map((k) => [k, flagOn(ctx, k)])) as Record<
    FlagKey,
    boolean
  >;
  const caps = Object.fromEntries(
    capabilities.map((capability): [Capability, CapabilityState] => [
      capability,
      capabilityStateAsOwner(ctx, capability, now),
    ]),
  ) as Record<Capability, CapabilityState>;
  return {
    code,
    country: ctx.family.country,
    plan: plan.plan,
    validUntil: plan.validUntil?.toISOString() ?? null,
    entitlementVersion: ctx.family.entitlementVersion,
    grants: ctx.grants.map((g) => ({
      id: g.id,
      source: g.source,
      status: g.status,
      environment: g.environment,
      capabilities: g.capabilities,
      validFrom: g.validFrom.toISOString(),
      validUntil: g.validUntil.toISOString(),
      provider: g.provider ?? null,
      autoRenew: g.autoRenew ?? null,
      fromCampaign: g.id.startsWith('campaign:'),
    })),
    access: { internal: ctx.family.internal, regionSupported, flags, capabilities: caps },
  };
}

/** A promo grant (support, partners, QA): never more than one year, audit id as campaign. */
export async function grantPromo(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
) {
  const req = parse(grantPromoSchema, data);
  const s = requireStaff(staff, 'premium.grant');
  const until = new Date(req.validUntil);
  if (until.getTime() <= now.getTime() || until.getTime() > now.getTime() + 366 * 86_400_000) {
    throw new StaffError('invalid-argument', 'bad-dates');
  }
  const familyId = await familyOf(db, req.code);
  const ref = db.collection(`families/${familyId}/grants`).doc();
  const grantId = `promo_${ref.id}`;
  await db.runTransaction(async (tx) => {
    tx.create(db.doc(`families/${familyId}/grants/${grantId}`), {
      familyId,
      source: 'promo',
      status: 'active',
      environment,
      capabilities: req.capabilities,
      validFrom: now,
      validUntil: until,
      billingOwnerUid: null,
      provider: 'staff',
      sourceRef: null,
      campaignId: s.uid,
      autoRenew: null,
      updatedAt: now,
    });
    tx.set(
      db.doc(`families/${familyId}`),
      { entitlementVersion: FieldValue.increment(1) },
      { merge: true },
    );
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'premium.grant',
        category: 'premium',
        target: req.code,
        reason: req.reason,
        detail: {
          grantId,
          capabilities: req.capabilities,
          validUntil: req.validUntil,
          environment,
        },
      },
      now,
    );
  });
  return { grantId };
}

/** Revokes a staff-written grant (promo, or a beta written by hand). Paid grants follow the store. */
export async function revokeGrant(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const req = parse(revokeGrantSchema, data);
  const s = requireStaff(staff, 'premium.grant');
  const familyId = await familyOf(db, req.code);
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`families/${familyId}/grants/${req.grantId}`);
    const snap = await tx.get(ref);
    if (!snap.exists) throw new StaffError('not-found', 'no-grant');
    if (snap.get('source') === 'paid') throw new StaffError('failed-precondition', 'paid-grant');
    if (snap.get('status') === 'revoked') return;
    tx.update(ref, { status: 'revoked', updatedAt: now });
    tx.set(
      db.doc(`families/${familyId}`),
      { entitlementVersion: FieldValue.increment(1) },
      { merge: true },
    );
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'premium.revoke',
        category: 'premium',
        target: req.code,
        reason: req.reason,
        detail: { grantId: req.grantId },
      },
      now,
    );
  });
}
