import {
  defaultLimits,
  limitsSchema,
  GB,
  familyPlanRequestSchema,
  monthlyCycle,
  planLimits,
  seatRoles,
  usageHistoryRequestSchema,
  type FamilyPlanAnswer,
  type QuotaSnapshot,
  type GrantEnvironment,
  type UsageHistoryRow,
  type PlanLimits,
} from '@child-life/contracts';
import type { DocumentSnapshot, Firestore } from 'firebase-admin/firestore';
import { assistantUsage, premiumBudgetGrant } from './assistant-usage.js';
import { NEVER } from './quota.js';
import { readVideoQuota, videoWindowFor } from './video-quota.js';
import {
  flagOn,
  loadEntitlementContext,
  loadFamilyEntitlements,
  serverGrantEnvironment,
  type FamilyEntitlements,
} from './entitlements.js';

/**
 * Premium v2 (Figma 958:13863, D-101) on the server: which plan a family is on and the limits it
 * has, from the stored grants and the open campaigns, never from the client. Off (`premium_v2`):
 * `v2: false` and every caller keeps today's behaviour.
 */
export interface FamilyPlan {
  v2: boolean;
  premium: boolean;
  limits: PlanLimits;
  /** The grant giving Premium (its id, start = the subscription day, end). */
  grant: { id: string; validFrom: Date; validUntil: Date } | null;
}

const toDate = (v: unknown): Date | null =>
  v instanceof Date
    ? v
    : v && typeof (v as { toDate?: () => Date }).toDate === 'function'
      ? (v as { toDate: () => Date }).toDate()
      : null;

/** A storage add-on still paid for (`families/{f}.storageAddOn {id, gb, until}`, PW10). */
export function activeAddOnGb(family: DocumentSnapshot | undefined, now: Date): number {
  const addOn = family?.get('storageAddOn') as { gb?: unknown; until?: unknown } | undefined;
  const until = toDate(addOn?.until);
  return addOn && typeof addOn.gb === 'number' && until && until > now ? addOn.gb : 0;
}

export function planOf(
  ctx: FamilyEntitlements,
  now: Date,
  options: { addOnGb?: number; extraBytes?: number } = {},
): FamilyPlan {
  const v2 = flagOn(ctx, 'premium_v2');
  const grant = premiumBudgetGrant(ctx, now) ?? null;
  return {
    v2,
    premium: grant !== null,
    limits: planLimits(ctx.config.plans, grant !== null, {
      // Add-ons are Premium only (PV00).
      addOnGb: grant !== null ? (options.addOnGb ?? 0) : 0,
      extraBytes: options.extraBytes ?? 0,
    }),
    grant: grant
      ? { id: grant.id, validFrom: grant.validFrom, validUntil: grant.validUntil }
      : null,
  };
}

/**
 * Storage staff granted on top of the base (P-120): what `quotaBytes` holds beyond the base every
 * family was created with. Kept on every plan.
 */
export function staffExtraBytes(family: DocumentSnapshot | undefined, legacyBase: number): number {
  const stored = family?.get('quotaBytes') as number | undefined;
  return Math.max(0, (stored ?? legacyBase) - legacyBase);
}

export async function legacyBaseBytes(db: Firestore): Promise<number> {
  const parsed = limitsSchema.safeParse((await db.doc('config/limits').get()).data());
  return parsed.success ? parsed.data.familyQuotaBytes : defaultLimits.familyQuotaBytes;
}

/**
 * The storage limit in force (D-101 Q-095: Free 1 GB for every family, Premium 10 GB, plus an
 * add-on and staff grants). Without v2: the stored `quotaBytes`, exactly as before.
 */
export async function storageLimitBytes(
  db: Firestore,
  familyId: string,
  family: DocumentSnapshot,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<number> {
  const ctx = await loadFamilyEntitlements(db, familyId, now, environment);
  const legacyBase = await legacyBaseBytes(db);
  if (!flagOn(ctx, 'premium_v2')) {
    return (family.get('quotaBytes') as number | undefined) ?? legacyBase;
  }
  return planOf(ctx, now, {
    addOnGb: activeAddOnGb(family, now),
    extraBytes: staffExtraBytes(family, legacyBase),
  }).limits.storageBytes;
}

/** The family's plan with storage folded in (getCapabilities, seats, Gói của gia đình). */
export async function familyPlan(
  db: Firestore,
  familyId: string,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<FamilyPlan & { ctx: FamilyEntitlements }> {
  const [ctx, family, legacyBase] = await Promise.all([
    loadFamilyEntitlements(db, familyId, now, environment),
    db.doc(`families/${familyId}`).get(),
    legacyBaseBytes(db),
  ]);
  return {
    ...planOf(ctx, now, {
      addOnGb: activeAddOnGb(family, now),
      extraBytes: staffExtraBytes(family, legacyBase),
    }),
    ctx,
  };
}

// ---------- Lịch sử sử dụng (PV41 / PV45, D-101) ----------

export class UsageHistoryError extends Error {
  constructor(
    readonly code: 'invalid-argument' | 'permission-denied' | 'not-found',
    readonly reason: string,
  ) {
    super(reason);
  }
}

const iso = (v: unknown) => toDate(v)?.toISOString() ?? new Date(0).toISOString();

function rowOfOp(op: DocumentSnapshot): UsageHistoryRow | null {
  const feature = op.get('feature') as string | undefined;
  const video = feature === 'video';
  if (!video && feature !== 'assistant' && feature !== 'ai_day' && feature !== 'ai_month')
    return null;
  const units = (op.get('units') as number | undefined) ?? 1;
  const state = op.get('state') as string;
  // A free Lumi read (0 credit) is not a line of the history.
  if (units === 0) return null;
  const task =
    (op.get('task') as string | null | undefined) ??
    (video ? 'video.export' : feature === 'assistant' ? 'lumi.chat' : 'lumi.summary');
  if (state === 'granted') {
    return {
      id: op.id,
      kind: 'grant',
      task: (op.get('task') as string | undefined) ?? (video ? 'video.grant' : 'lumi.grant'),
      uid: null,
      amount: units,
      state: 'granted',
      at: iso(op.get('createdAt') ?? op.get('reservedAt')),
    };
  }
  const released = state === 'released';
  return {
    id: op.id,
    kind: released ? 'refund' : video ? 'video' : 'lumi',
    task,
    uid: (op.get('actorUid') as string | null | undefined) ?? null,
    amount: released ? units : -units,
    state: released ? 'refunded' : state === 'committed' ? 'debited' : 'held',
    at: iso(op.get('releasedAt') ?? op.get('createdAt') ?? op.get('reservedAt')),
  };
}

function rowOfWindow(w: DocumentSnapshot): UsageHistoryRow | null {
  const feature = w.get('feature') as string | undefined;
  if (feature !== 'video' && feature !== 'assistant') return null;
  const trial = w.id.includes('_trial_');
  return {
    id: w.id,
    kind: 'grant',
    task: `${feature === 'video' ? 'video' : 'lumi'}.${trial ? 'trial' : 'cycle'}`,
    uid: null,
    amount: (w.get('limit') as number | undefined) ?? 0,
    state: 'granted',
    at: iso(w.get('createdAt') ?? w.get('startsAt') ?? w.get('windowStart')),
  };
}

/**
 * PV41 "Lịch sử sử dụng": person · task · amount for the household's Lumi credit and video
 * lượt, plus each allowance granted. The manager sees everyone ([everyone]); a member always
 * gets their own lines (PV45). Never a question, a photo or a caption — only label ids.
 */
export async function familyUsageHistory(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ rows: UsageHistoryRow[]; everyone: boolean }> {
  const parsed = usageHistoryRequestSchema.safeParse(data);
  if (!parsed.success) throw new UsageHistoryError('invalid-argument', 'malformed');
  const req = parsed.data;
  const [baby, member] = await Promise.all([
    db.doc(`babies/${req.babyId}`).get(),
    db.doc(`babies/${req.babyId}/members/${uid}`).get(),
  ]);
  const until = toDate(member.get('accessUntilAt'));
  if (!baby.exists || member.get('status') !== 'active' || (until && until <= now))
    throw new UsageHistoryError('permission-denied', 'not-a-member');
  const familyId = baby.get('familyId') as string;
  const family = await db.doc(`families/${familyId}`).get();
  const everyone = req.everyone && family.get('ownerUid') === uid;
  const ops = db.collection(`families/${familyId}/quotaOps`);
  const quota = db.collection(`families/${familyId}/quota`);
  // Ledger windows carry `startsAt`, video windows `windowStart` (video-quota.ts).
  const [lumi, video, lumiWindows, videoWindows] = await Promise.all([
    ops.orderBy('createdAt', 'desc').limit(200).get(),
    ops.orderBy('reservedAt', 'desc').limit(100).get(),
    quota.orderBy('startsAt', 'desc').limit(24).get(),
    quota.orderBy('windowStart', 'desc').limit(12).get(),
  ]);
  const windows = {
    docs: [...new Map([...lumiWindows.docs, ...videoWindows.docs].map((d) => [d.id, d])).values()],
  };
  const rows = [
    ...[...new Map([...lumi.docs, ...video.docs].map((d) => [d.id, d])).values()].map(rowOfOp),
    ...windows.docs.map(rowOfWindow),
  ].filter((r): r is UsageHistoryRow => {
    if (!r) return false;
    if (!everyone && r.kind !== 'grant' && r.uid !== uid) return false;
    if (req.kind === 'grants') return r.kind === 'grant';
    if (req.kind === 'lumi') return r.kind !== 'grant' && r.task.startsWith('lumi');
    if (req.kind === 'video') return r.kind !== 'grant' && r.task === 'video.export';
    return true;
  });
  rows.sort((a, b) => b.at.localeCompare(a.at));
  return { rows: rows.slice(0, 100), everyone };
}

// ---------- Gói của gia đình (PV40 / PV40B / PV45) ----------

/** Active writers of the family (one seat each, across its babies) and who is suspended. */
export async function familyWriters(
  db: Firestore,
  familyId: string,
  now: Date,
): Promise<{ writers: Set<string>; suspended: Set<string> }> {
  const babies = await db.collection('babies').where('familyId', '==', familyId).get();
  const lists = await Promise.all(
    babies.docs.map((b) =>
      db
        .collection(`babies/${b.id}/members`)
        .where('role', 'in', [...seatRoles])
        .get(),
    ),
  );
  const writers = new Set<string>();
  const suspended = new Set<string>();
  for (const m of lists.flatMap((l) => l.docs)) {
    const until = toDate(m.get('accessUntilAt'));
    if (m.get('status') !== 'active' || (until && until <= now)) continue;
    if (m.get('writeSuspended') === true) suspended.add(m.id);
    else writers.add(m.id);
  }
  for (const uid of writers) suspended.delete(uid);
  return { writers, suspended };
}

const balanceOf = (q: QuotaSnapshot) => ({
  limit: q.limit,
  used: q.used,
  reserved: q.reserved,
  resetsAt: q.resetsAt && new Date(q.resetsAt) < NEVER ? q.resetsAt : null,
});

/** `getFamilyPlan`: the plan, its limits and balances for one of my babies (any member). */
export async function familyPlanAnswer(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<FamilyPlanAnswer> {
  const parsed = familyPlanRequestSchema.safeParse(data);
  if (!parsed.success) throw new UsageHistoryError('invalid-argument', 'malformed');
  const { babyId } = parsed.data;
  const ctx = await loadEntitlementContext(db, uid, babyId, now, environment);
  if (!ctx.member) throw new UsageHistoryError('permission-denied', 'not-a-member');
  const [plan, baby, family, seats] = await Promise.all([
    familyPlan(db, ctx.familyId, now, environment),
    db.doc(`babies/${babyId}`).get(),
    db.doc(`families/${ctx.familyId}`).get(),
    familyWriters(db, ctx.familyId, now),
  ]);
  const zone =
    ctx.family.timeZone ?? (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh';
  const [lumi, video] = await Promise.all([
    assistantUsage(db, { ctx, familyId: ctx.familyId, householdZone: zone }, now),
    videoWindowFor(db, ctx.familyId, babyId, ctx.config, environment, now).then((w) =>
      readVideoQuota(db, ctx.familyId, w),
    ),
  ]);
  const cycle =
    plan.premium && plan.grant
      ? monthlyCycle(plan.grant.validFrom, now, plan.grant.validUntil)
      : null;
  const plans = ctx.config.plans;
  return {
    v2: plan.v2,
    plan: plan.limits.plan,
    isManager: family.get('ownerUid') === uid,
    cycle: cycle ? { start: cycle.start.toISOString(), end: cycle.end.toISOString() } : null,
    validUntil:
      plan.grant && plan.grant.validUntil < NEVER ? plan.grant.validUntil.toISOString() : null,
    lumi: balanceOf({ ...lumi, resetsAt: lumi.resetsAt }),
    video: balanceOf(video),
    storage: {
      usedBytes: Math.max(0, (family.get('usedBytes') as number | undefined) ?? 0),
      limitBytes: await storageLimitBytes(db, ctx.familyId, family, now, environment),
      addOnGb: plan.premium ? activeAddOnGb(family, now) : 0,
    },
    seats: {
      used: seats.writers.size,
      limit: plan.limits.caregiverSeats,
      suspended: [...seats.suspended],
      overLimit: plan.v2 && seats.writers.size > plan.limits.caregiverSeats,
    },
    premiumTemplates: plan.limits.premiumTemplates,
    offer: {
      free: {
        lumiCredits: plans.free.lumiCreditsOneTime,
        videoExports: plans.free.videoExportsTrial,
        storageBytes: Math.round(plans.free.storageGB * GB),
        caregiverSeats: plans.free.caregiverSeats,
      },
      premium: {
        lumiCredits: plans.premium.lumiCreditsPerCycle,
        videoExports: plans.premium.videoExportsPerCycle,
        storageBytes: Math.round(plans.premium.storageGB * GB),
        caregiverSeats: plans.premium.caregiverSeats,
      },
    },
    prices: plans.premium.price,
    storageAddOns: plans.storageAddOns,
  };
}
