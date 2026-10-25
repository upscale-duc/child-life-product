import {
  FEATURE_GRACE_DAYS,
  FULL_PREMIUM_GRANT_ID,
  OPEN_ENDED_GRANT_UNTIL,
  activeOverride,
  catalogueFeature,
  featureCatalogue,
  featureGroups,
  featureTierOf,
  featureVisible,
  featuresConfigSchema,
  flagsSchema,
  householdPlan,
  hubBetaFamilySchema,
  hubFamilySchema,
  hubFullPremiumSchema,
  setFamilyPlanSchema,
  hubSetOverrideSchema,
  hubSetRolloutSchema,
  hubSetTierSchema,
  inFeatureGrace,
  isOpenEndedUntil,
  premiumCapabilities,
  systemFlagKeys,
  type FeatureGrace,
  type FeatureHubEntry,
  type FeatureKey,
  type FeaturesConfig,
  type Flag,
  type FlagKey,
  type Flags,
  type GrantEnvironment,
  type StaffFeatureHub,
  type StaffHubFamily,
  type StaffHubFamilyAnswer,
  type StaffHubFamilyMatch,
  type StaffHubFlagState,
  type StaffHubTierAnswer,
} from '@child-life/contracts';
import {
  FieldValue,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import { familyBucket } from './bucket.js';
import {
  featureDecision,
  loadFamilyEntitlements,
  readFeaturesConfig,
  serverGrantEnvironment,
} from './entitlements.js';
import type { FamilyDeps } from './staff-families.js';
import {
  StaffError,
  familyCode,
  familyIdsOf,
  launchedFlags,
  parse,
  requireStaff,
  setFlag,
  staffAudit,
  type Staff,
} from './staff.js';

/**
 * "Tính năng & Premium" hub (D-089 / P-172, plan `docs/product/features-premium-hub-plan.md`):
 * the catalogue with its tier, rollout and kill switch; the tier change with its 30-day grace;
 * one family's effective state of every feature with the reason; per-family overrides, beta
 * membership and "Bật toàn bộ Premium". No reason is asked (D-090); every change writes the
 * audit line (actor, action, before / after). Codes only, never family ids, names or emails.
 */

/** Collection-group scans (grants, overrides, families for a percent rollout) stop here. */
export const SCAN_CAP = 5000;
const FAMILY_SCAN_CAP = 20_000;
const DAY_MS = 86_400_000;

const ms = (v: unknown) =>
  v instanceof Timestamp ? v.toMillis() : v instanceof Date ? v.getTime() : 0;
const iso = (v: unknown) => new Date(ms(v)).toISOString();
const toDate = (v: unknown): Date | null => (ms(v) ? new Date(ms(v)) : null);

/** The flags as staff see them (the shipped set when no document exists yet, like A10). */
async function readStaffFlags(db: Firestore): Promise<Flags> {
  const parsed = flagsSchema.safeParse((await db.doc('config/flags').get()).data());
  return parsed.success ? parsed.data : structuredClone(launchedFlags);
}

function flagState(flags: Flags, key: FlagKey): StaffHubFlagState {
  const f = flags[key];
  return {
    key,
    enabled: f.enabled,
    scope: f.scope,
    percent: f.percent,
    notice: f.notice,
    families: (f.families ?? []).map(familyCode),
  };
}

/** Valid grants giving Premium now, by family (paid, staff, "toàn bộ"); one capped scan. */
export async function premiumFamilies(db: Firestore, now: Date, environment: GrantEnvironment) {
  const snap = await db
    .collectionGroup('grants')
    .select('source', 'status', 'environment', 'validFrom', 'validUntil')
    .limit(SCAN_CAP)
    .get();
  const paid = new Set<string>();
  const admin = new Set<string>();
  const full = new Set<string>();
  const t = now.getTime();
  for (const d of snap.docs) {
    const family = d.ref.parent.parent;
    if (!family || family.parent.id !== 'families') continue;
    const valid =
      d.get('environment') === environment &&
      ['active', 'grace'].includes(d.get('status') as string) &&
      ms(d.get('validFrom')) <= t &&
      t < ms(d.get('validUntil'));
    if (!valid) continue;
    if (d.get('source') === 'paid') paid.add(family.id);
    if (d.get('source') === 'promo') admin.add(family.id);
    if (d.id === FULL_PREMIUM_GRANT_ID) full.add(family.id);
  }
  return { paid, admin, full, capped: snap.size >= SCAN_CAP };
}

/**
 * Families that have the feature under a Miễn phí or Beta tier: its rollout (and beta list),
 * counted from `families` (an exact count for "everyone", a capped id scan for a percentage).
 */
async function familiesReached(
  db: Firestore,
  flag: Flag | null,
  tier: 'free' | 'beta',
  betaFamilies: readonly string[],
): Promise<number> {
  if (flag && !flag.enabled) return 0;
  const picked = new Set(tier === 'beta' ? betaFamilies : []);
  const countAll = async () => (await db.collection('families').count().get()).data().count;
  if (!flag) return tier === 'beta' ? picked.size : countAll();
  switch (flag.scope) {
    case 'all':
      return countAll();
    case 'internal': {
      const internal = await db.collection('families').where('internal', '==', true).select().get();
      return new Set([...internal.docs.map((d) => d.id), ...(flag.families ?? []), ...picked]).size;
    }
    case 'percent': {
      const all = await db.collection('families').select().limit(FAMILY_SCAN_CAP).get();
      return all.docs.filter((d) => familyBucket(d.id) < flag.percent || picked.has(d.id)).length;
    }
  }
}

// ---------- The hub ----------

export async function featuresHub(
  db: Firestore,
  staff: Staff | null,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<StaffFeatureHub> {
  requireStaff(staff, 'features.view');
  const [flags, hub, featureAudit, premiumAudit, premium, overrideDocs] = await Promise.all([
    readStaffFlags(db),
    readFeaturesConfig(db),
    db
      .collection('staffAudit')
      .where('category', '==', 'features')
      .orderBy('at', 'desc')
      .limit(40)
      .get(),
    db
      .collection('staffAudit')
      .where('category', '==', 'premium')
      .orderBy('at', 'desc')
      .limit(10)
      .get(),
    premiumFamilies(db, now, environment),
    db
      .collectionGroup('featureOverrides')
      .select('feature', 'state', 'until')
      .limit(SCAN_CAP)
      .get(),
  ]);
  const overrides = new Map<string, { on: number; off: number }>();
  for (const d of overrideDocs.docs) {
    const state = activeOverride(
      { state: d.get('state') as 'on' | 'off', until: toDate(d.get('until')) },
      now,
    );
    if (state !== 'on' && state !== 'off') continue;
    const row = overrides.get(d.get('feature') as string) ?? { on: 0, off: 0 };
    row[state] += 1;
    overrides.set(d.get('feature') as string, row);
  }
  const audit = [...featureAudit.docs, ...premiumAudit.docs].sort(
    (a, b) => ms(b.get('at')) - ms(a.get('at')),
  );
  const lastEdit = (key: FeatureKey, flagKeys: readonly FlagKey[]) => {
    const hit = audit.find((a) => {
      const target = a.get('target') as string;
      const detail = a.get('detail') as { feature?: string } | null;
      return target === key || flagKeys.includes(target as FlagKey) || detail?.feature === key;
    });
    return hit ? { by: hit.get('actorName') as string, at: iso(hit.get('at')) } : null;
  };
  return {
    groups: [...featureGroups],
    features: featureCatalogue.map((f) => {
      const entry = hub.features[f.key];
      const grace =
        entry.grace && now.getTime() < Date.parse(entry.grace.until)
          ? { since: entry.grace.since, until: entry.grace.until, from: entry.grace.from }
          : null;
      return {
        key: f.key,
        group: f.group,
        labelId: f.labelId,
        helpId: f.helpId,
        tier: featureTierOf(hub, f.key),
        defaultTier: f.defaultTier,
        tierable: f.tierable,
        credits: f.credits,
        capabilities: [...f.capabilities],
        flag: f.flags[0] ? flagState(flags, f.flags[0]) : null,
        subFlags: f.flags.slice(1).map((k) => flagState(flags, k)),
        betaFamilies: entry.betaFamilies.map(familyCode),
        grace,
        overrides: overrides.get(f.key) ?? { on: 0, off: 0 },
        lastEdit: lastEdit(f.key, f.flags),
      };
    }),
    systemFlags: [...systemFlagKeys],
    premium: {
      families: new Set([...premium.paid, ...premium.admin]).size,
      paid: premium.paid.size,
      admin: premium.admin.size,
      full: premium.full.size,
      capped: premium.capped || overrideDocs.size >= SCAN_CAP,
    },
    environment,
    recent: audit
      .filter((a) => {
        const action = a.get('action') as string;
        return (
          action.startsWith('hub.') || action.startsWith('premium.') || action.startsWith('flags.')
        );
      })
      .slice(0, 20)
      .map((a) => ({
        action: a.get('action') as string,
        target: a.get('target') as string,
        by: a.get('actorName') as string,
        at: iso(a.get('at')),
        detail: (a.get('detail') as Record<string, unknown> | null) ?? null,
      })),
  };
}

/** Rewrites one feature's entry of `config/features` in a transaction, with its audit line. */
async function updateEntry(
  db: Firestore,
  staff: Staff,
  key: FeatureKey,
  now: Date,
  change: (entry: FeatureHubEntry, config: FeaturesConfig) => FeatureHubEntry,
  audit: (
    before: FeatureHubEntry,
    after: FeatureHubEntry,
  ) => {
    action: string;
    target: string;
    reason: string;
    detail: Record<string, unknown>;
  } | null,
  more?: (tx: Transaction) => void,
) {
  await db.runTransaction(async (tx) => {
    const ref = db.doc('config/features');
    const parsed = featuresConfigSchema.safeParse((await tx.get(ref)).data() ?? {});
    const config = parsed.success ? parsed.data : featuresConfigSchema.parse({});
    const before = config.features[key];
    const after = change(before, config);
    const line = audit(before, after);
    if (!line) return;
    tx.set(ref, { ...config, features: { ...config.features, [key]: after } });
    more?.(tx);
    staffAudit(tx, db, staff, { ...line, category: 'features' }, now);
  });
}

/**
 * Gói of a catalogue feature. Moving from Miễn phí or Beta to Premium keeps every family that
 * has it now on it for 30 days (plan §2.4) and answers how many; `dryRun` only counts.
 */
export async function setFeatureTier(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<StaffHubTierAnswer> {
  const req = parse(hubSetTierSchema, data);
  const s = requireStaff(staff, 'premium.config');
  const feature = catalogueFeature(req.feature);
  if (!feature.tierable) throw new StaffError('failed-precondition', 'not-tierable');
  const [hub, flags] = await Promise.all([readFeaturesConfig(db), readStaffFlags(db)]);
  const from = featureTierOf(hub, req.feature);
  const entry = hub.features[req.feature];
  const main = feature.flags[0] ? flags[feature.flags[0]] : null;
  const affected =
    from === 'premium'
      ? await premiumFamilies(db, now, environment).then(
          (p) => new Set([...p.paid, ...p.admin]).size,
        )
      : await familiesReached(db, main, from, entry.betaFamilies);
  const toPremium = req.tier === 'premium' && from !== 'premium';
  const grace: FeatureGrace | null = toPremium
    ? {
        since: now.toISOString(),
        until: new Date(now.getTime() + FEATURE_GRACE_DAYS * DAY_MS).toISOString(),
        from: from as 'free' | 'beta',
        rollout: main
          ? {
              enabled: main.enabled,
              scope: main.scope,
              percent: main.percent,
              ...(main.families?.length ? { families: main.families } : {}),
            }
          : { enabled: true, scope: 'all', percent: 0 },
        betaFamilies: from === 'beta' ? entry.betaFamilies : [],
      }
    : null;
  const answer = (applied: boolean): StaffHubTierAnswer => ({
    feature: req.feature,
    from,
    tier: req.tier,
    affected,
    graceUntil: grace?.until ?? null,
    applied,
  });
  if (req.dryRun || req.tier === from) return answer(false);
  await updateEntry(
    db,
    s,
    req.feature,
    now,
    // Leaving Premium ends a grace (everyone the tier now reaches has it anyway).
    (e) => ({ ...e, tier: req.tier, grace: req.tier === 'premium' ? (grace ?? e.grace) : null }),
    (before, after) => ({
      action: 'hub.tier',
      target: req.feature,
      reason: req.reason,
      detail: {
        feature: req.feature,
        before: before.tier,
        after: after.tier,
        affected,
        graceUntil: after.grace?.until ?? null,
      },
    }),
  );
  return answer(true);
}

/**
 * Phát hành and Công tắc khẩn of a feature (its main flag, or one of its sub-switches) through
 * `setFlag` (same roles: rollout = Vận hành level of Tính năng, kill switch = Kỹ thuật), and its
 * whole beta list. Omitted fields stay as they are.
 */
export async function setFeatureRollout(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
): Promise<{ feature: FeatureKey; flag: FlagKey | null }> {
  const req = parse(hubSetRolloutSchema, data);
  const s = requireStaff(staff, 'flags.rollout');
  const feature = catalogueFeature(req.feature);
  const key = req.flag ?? feature.flags[0] ?? null;
  const touchesFlag = [req.enabled, req.scope, req.percent, req.notice, req.families].some(
    (v) => v !== undefined,
  );
  if (touchesFlag) {
    if (!key || !feature.flags.includes(key)) throw new StaffError('invalid-argument', 'no-flag');
    const current = (await readStaffFlags(db))[key];
    const scope = req.scope ?? current.scope;
    await setFlag(
      db,
      staff,
      {
        key,
        enabled: req.enabled ?? current.enabled,
        scope,
        percent: scope === 'percent' ? (req.percent ?? current.percent) : 0,
        notice: req.notice !== undefined ? req.notice : current.notice,
        ...(req.families ? { families: req.families } : {}),
        reason: req.reason,
      },
      now,
    );
  }
  if (req.betaFamilies) {
    const ids = await familyIdsOf(db, req.betaFamilies);
    await updateEntry(
      db,
      s,
      req.feature,
      now,
      (e) => ({ ...e, betaFamilies: ids }),
      (before) => ({
        action: 'hub.beta',
        target: req.feature,
        reason: req.reason,
        detail: {
          feature: req.feature,
          before: before.betaFamilies.map(familyCode),
          after: ids.map(familyCode),
        },
      }),
    );
  }
  return { feature: req.feature, flag: touchesFlag ? key : null };
}

/** "Thêm vào beta" (or out) for one family; the family's app refetches its features. */
export async function setBetaFamily(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const req = parse(hubBetaFamilySchema, data);
  const s = requireStaff(staff, 'flags.rollout');
  const [familyId] = await familyIdsOf(db, [req.code]);
  await updateEntry(
    db,
    s,
    req.feature,
    now,
    (e) => {
      const rest = e.betaFamilies.filter((id) => id !== familyId);
      if (req.member && rest.length >= 500)
        throw new StaffError('failed-precondition', 'beta-full');
      return { ...e, betaFamilies: req.member ? [...rest, familyId!] : rest };
    },
    (before, after) =>
      before.betaFamilies.length === after.betaFamilies.length &&
      before.betaFamilies.every((id) => after.betaFamilies.includes(id))
        ? null
        : {
            action: req.member ? 'hub.beta.add' : 'hub.beta.remove',
            target: req.code,
            reason: req.reason,
            detail: { feature: req.feature, member: req.member },
          },
    (tx) => bumpVersion(tx, db, familyId!),
  );
  return { code: req.code, feature: req.feature, member: req.member };
}

function bumpVersion(tx: Transaction, db: Firestore, familyId: string) {
  tx.set(
    db.doc(`families/${familyId}`),
    { entitlementVersion: FieldValue.increment(1) },
    { merge: true },
  );
}

// ---------- Gia đình ----------

const capitalized = (q: string) => q.charAt(0).toLocaleUpperCase('vi') + q.slice(1);

/** Family ids for a code, an account email or a baby nickname (exact); at most 10. */
async function findFamilies(
  db: Firestore,
  q: string,
  deps: Pick<FamilyDeps, 'uidByEmail'>,
): Promise<{ by: StaffHubFamilyAnswer['matchedBy']; ids: string[] }> {
  if (/^F-[A-Z2-9]{4}$/i.test(q)) {
    const hit = await db
      .collection('familyDirectory')
      .where('code', '==', q.toUpperCase())
      .limit(5)
      .get();
    return { by: 'code', ids: hit.docs.map((d) => d.id) };
  }
  if (q.includes('@')) {
    const uid = await deps.uidByEmail(q.toLowerCase());
    if (!uid) return { by: 'email', ids: [] };
    const memberships = await db
      .collectionGroup('members')
      .where('uid', '==', uid)
      .where('status', '==', 'active')
      .select('babyId')
      .get();
    const babyIds = [...new Set(memberships.docs.map((m) => m.get('babyId') as string))];
    const babies = babyIds.length
      ? await db.getAll(...babyIds.map((b) => db.doc(`babies/${b}`)))
      : [];
    return {
      by: 'email',
      ids: [...new Set(babies.map((b) => b.get('familyId') as string).filter(Boolean))].slice(
        0,
        10,
      ),
    };
  }
  // A nickname is child data: matched here, never logged, stored or sent back.
  const variants = [...new Set([q, capitalized(q), q.toLocaleLowerCase('vi')])];
  const babies = await db
    .collection('babies')
    .where('nickname', 'in', variants)
    .select('familyId', 'state')
    .limit(20)
    .get();
  return {
    by: 'nickname',
    ids: [
      ...new Set(
        babies.docs
          .filter((b) => b.get('state') !== 'deleting')
          .map((b) => b.get('familyId') as string)
          .filter(Boolean),
      ),
    ].slice(0, 10),
  };
}

function matchOf(id: string, dir: DocumentSnapshot, family: DocumentSnapshot): StaffHubFamilyMatch {
  return {
    code: (dir.get('code') as string | undefined) ?? familyCode(id),
    owner: (dir.get('ownerMasked') as string | undefined) ?? '—',
    babies:
      (dir.get('babies') as number | undefined) ??
      ((family.get('babyIds') as string[] | undefined) ?? []).length,
  };
}

async function familyView(
  db: Firestore,
  familyId: string,
  code: string,
  now: Date,
  environment: GrantEnvironment,
): Promise<StaffHubFamily> {
  const state = await loadFamilyEntitlements(db, familyId, now, environment);
  const plan = householdPlan(state.grants, environment, now);
  const t = now.getTime();
  const full = state.grants.find((g) => g.id === FULL_PREMIUM_GRANT_ID);
  const fullOn =
    !!full &&
    full.environment === environment &&
    (full.status === 'active' || full.status === 'grace') &&
    full.validFrom.getTime() <= t &&
    t < full.validUntil.getTime();
  const until = (d: Date) => (isOpenEndedUntil(d) ? null : d.toISOString());
  const bucket = familyBucket(familyId);
  return {
    code,
    country: state.family.country,
    regionSupported:
      state.family.country !== null && state.config.regions.advanced.includes(state.family.country),
    internal: state.family.internal,
    plan: plan.plan,
    validUntil: plan.validUntil ? until(plan.validUntil) : null,
    fullPremium: { on: fullOn, until: fullOn ? until(full.validUntil) : null },
    grants: state.grants.map((g) => ({
      id: g.id,
      source: g.source,
      status: g.status,
      environment: g.environment,
      capabilities: [...g.capabilities],
      validFrom: g.validFrom.toISOString(),
      validUntil: until(g.validUntil),
      provider: g.provider ?? null,
      fromCampaign: g.id.startsWith('campaign:'),
    })),
    features: featureCatalogue.map((f) => {
      const d = featureDecision(state, f.key);
      const entry = state.hub.features[f.key];
      const o = state.overrides[f.key];
      const graced = inFeatureGrace(entry.grace, {
        familyId,
        bucket,
        internal: state.family.internal,
        createdAt: state.family.createdAt,
        now,
      });
      return {
        key: f.key,
        tier: featureTierOf(state.hub, f.key),
        on: d.on,
        visible: featureVisible(d),
        why: d.why,
        override:
          o && activeOverride(o, now)
            ? {
                state: o.state,
                until: o.until?.toISOString() ?? null,
                by: o.byName,
                at: o.at.toISOString(),
              }
            : null,
        betaListed: entry.betaFamilies.includes(familyId),
        graceUntil: graced ? entry.grace!.until : null,
      };
    }),
  };
}

/**
 * "Gia đình" tab: find families by code, email or baby nickname; with exactly one match, every
 * catalogue feature with its effective state and why, its overrides, beta lists and Premium.
 */
export async function hubFamily(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  deps: Pick<FamilyDeps, 'uidByEmail'>,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<StaffHubFamilyAnswer> {
  requireStaff(staff, 'premium.view');
  const { q } = parse(hubFamilySchema, data);
  const found = await findFamilies(db, q, deps);
  const [dirs, families] = found.ids.length
    ? await Promise.all([
        db.getAll(...found.ids.map((id) => db.doc(`familyDirectory/${id}`))),
        db.getAll(...found.ids.map((id) => db.doc(`families/${id}`))),
      ])
    : [[], []];
  const matches = found.ids
    .map((id, i) => ({ id, family: families[i]!, dir: dirs[i]! }))
    .filter((m) => m.family.exists)
    .map((m) => ({ id: m.id, row: matchOf(m.id, m.dir, m.family) }));
  const only = matches.length === 1 ? matches[0]! : null;
  return {
    matchedBy: found.by,
    matches: matches.map((m) => m.row),
    family: only ? await familyView(db, only.id, only.row.code, now, environment) : null,
  };
}

async function familyIdOf(db: Firestore, code: string): Promise<string> {
  return (await familyIdsOf(db, [code]))[0]!;
}

/** Bật / Tắt / Theo quy tắc for one family and one feature (the override of plan §2.2 #2). */
export async function setFeatureOverride(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const req = parse(hubSetOverrideSchema, data);
  const s = requireStaff(staff, 'premium.grant');
  const until = req.until ? new Date(req.until) : null;
  if (until && until.getTime() <= now.getTime()) {
    throw new StaffError('invalid-argument', 'bad-dates');
  }
  const familyId = await familyIdOf(db, req.code);
  const ref = db.doc(`families/${familyId}/featureOverrides/${req.feature}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const before = snap.exists
      ? {
          state: snap.get('state') as string,
          until: toDate(snap.get('until'))?.toISOString() ?? null,
        }
      : null;
    if (req.state === null) {
      if (!snap.exists) return;
      tx.delete(ref);
    } else {
      tx.set(ref, {
        feature: req.feature,
        state: req.state,
        until,
        byUid: s.uid,
        byName: s.name,
        at: now,
      });
    }
    bumpVersion(tx, db, familyId);
    staffAudit(
      tx,
      db,
      s,
      {
        action: req.state === null ? 'hub.override.clear' : 'hub.override',
        category: 'features',
        target: req.code,
        reason: req.reason,
        detail: {
          feature: req.feature,
          before,
          after:
            req.state === null ? null : { state: req.state, until: until?.toISOString() ?? null },
        },
      },
      now,
    );
  });
  return { code: req.code, feature: req.feature, state: req.state };
}

/**
 * "Bật toàn bộ Premium": one staff grant of every Premium capability (`promo_full`), no end date
 * unless one is given; an admin grant skips the country check (D-089). "Tắt" revokes it. Turning
 * it on again while it runs only moves the end (the credit month is kept).
 */
export async function setFullPremium(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<{ on: boolean; until: string | null }> {
  const req = parse(hubFullPremiumSchema, data);
  const s = requireStaff(staff, 'premium.grant');
  const until = new Date(req.until ?? OPEN_ENDED_GRANT_UNTIL);
  if (req.on && until.getTime() <= now.getTime()) {
    throw new StaffError('invalid-argument', 'bad-dates');
  }
  const familyId = await familyIdOf(db, req.code);
  const ref = db.doc(`families/${familyId}/grants/${FULL_PREMIUM_GRANT_ID}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const t = now.getTime();
    const running =
      snap.exists &&
      snap.get('environment') === environment &&
      ['active', 'grace'].includes(snap.get('status') as string) &&
      ms(snap.get('validFrom')) <= t &&
      t < ms(snap.get('validUntil'));
    if (req.on) {
      tx.set(ref, {
        familyId,
        source: 'promo',
        status: 'active',
        environment,
        capabilities: [...premiumCapabilities],
        validFrom: running ? snap.get('validFrom') : now,
        validUntil: until,
        billingOwnerUid: null,
        provider: 'staff',
        sourceRef: null,
        campaignId: s.uid.slice(0, 80),
        autoRenew: null,
        updatedAt: now,
      });
    } else {
      if (!snap.exists || snap.get('status') === 'revoked') return;
      tx.update(ref, { status: 'revoked', updatedAt: now });
    }
    bumpVersion(tx, db, familyId);
    staffAudit(
      tx,
      db,
      s,
      {
        action: req.on ? 'premium.full.on' : 'premium.full.off',
        category: 'premium',
        target: req.code,
        reason: req.reason,
        detail: {
          grantId: FULL_PREMIUM_GRANT_ID,
          until: req.on && !isOpenEndedUntil(until) ? until.toISOString() : null,
          environment,
        },
      },
      now,
    );
  });
  return { on: req.on, until: req.on && !isOpenEndedUntil(until) ? until.toISOString() : null };
}

/**
 * "Gói: Free | Premium" (owner, 2026-10-25): one switch per family. Premium is the one staff grant
 * of every Premium capability (as "Bật toàn bộ Premium", optional last day). Free revokes every
 * stored grant staff gave (promo, "toàn bộ", old staff grants) and clears the per-feature "on"
 * overrides, so nothing Premium is left behind; a store subscription is the buyer's and stays.
 */
export async function setFamilyPlan(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<{ plan: 'free' | 'premium'; revoked: number; paidRemains: boolean }> {
  const req = parse(setFamilyPlanSchema, data);
  const s = requireStaff(staff, 'premium.grant');
  if (req.plan === 'premium') {
    await setFullPremium(
      db,
      staff,
      { code: req.code, on: true, until: req.until ?? null, reason: req.reason },
      now,
      environment,
    );
    return { plan: 'premium', revoked: 0, paidRemains: false };
  }
  const familyId = await familyIdOf(db, req.code);
  const grantsCol = db.collection(`families/${familyId}/grants`);
  const overridesCol = db.collection(`families/${familyId}/featureOverrides`);
  return db.runTransaction(async (tx) => {
    const [grants, overrides] = await Promise.all([tx.get(grantsCol), tx.get(overridesCol)]);
    const t = now.getTime();
    let revoked = 0;
    let paidRemains = false;
    for (const g of grants.docs) {
      const live =
        ['active', 'grace'].includes(g.get('status') as string) && t < ms(g.get('validUntil'));
      if (!live) continue;
      if (g.get('source') === 'paid') {
        paidRemains = true;
        continue;
      }
      tx.update(g.ref, { status: 'revoked', updatedAt: now });
      revoked += 1;
    }
    for (const o of overrides.docs) if (o.get('state') === 'on') tx.delete(o.ref);
    bumpVersion(tx, db, familyId);
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'premium.plan.free',
        category: 'premium',
        target: req.code,
        reason: req.reason,
        detail: { revoked, paidRemains, environment },
      },
      now,
    );
    return { plan: 'free' as const, revoked, paidRemains };
  });
}
