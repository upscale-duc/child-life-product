import {
  planLimits,
  premiumOverviewRequestSchema,
  type GrantEnvironment,
  type PremiumOverviewRange,
  type StaffPremiumOverview,
} from '@child-life/contracts';
import { Timestamp, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import { readEntitlementsConfig, serverGrantEnvironment } from './entitlements.js';
import { SCAN_CAP } from './features-hub.js';
import { parse, requireStaff, type Staff } from './staff.js';

/**
 * Portal "Tổng quan Premium" (Figma 970:14756 PT01, D-101): Free / Premium families, conversion,
 * storage add-ons, new families and new Premium over the range, how often allowances run out,
 * store renewals and what needs a hand. Counts only — never a question, a photo or a caption.
 * Revenue, store fees and the cost to serve need in-app purchase and cost metering: null.
 * Every scan is capped (SCAN_CAP) without new indexes; `capped` says when a number is a floor.
 */

const DAY = 86_400_000;
const ms = (v: unknown) =>
  v instanceof Timestamp ? v.toMillis() : v instanceof Date ? v.getTime() : 0;

const rangeDays: Record<PremiumOverviewRange, number> = { '7d': 7, '30d': 30, '12m': 365 };

/** Bucket starts, oldest first: 7 days, 5 weeks, or 12 months. */
function buckets(range: PremiumOverviewRange, now: Date): number[] {
  const day = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  if (range === '7d') return Array.from({ length: 7 }, (_, i) => day - (6 - i) * DAY);
  if (range === '30d') return Array.from({ length: 5 }, (_, i) => day - (34 - i * 7) * DAY + DAY);
  return Array.from({ length: 12 }, (_, i) =>
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 11 + i, 1),
  );
}

function bucketOf(starts: number[], t: number): number {
  for (let i = starts.length - 1; i >= 0; i -= 1) if (t >= starts[i]!) return i;
  return -1;
}

async function getAll(db: Firestore, paths: string[]): Promise<DocumentSnapshot[]> {
  const out: DocumentSnapshot[] = [];
  for (let i = 0; i < paths.length; i += 300) {
    const refs = paths.slice(i, i + 300).map((p) => db.doc(p));
    if (refs.length) out.push(...(await db.getAll(...refs)));
  }
  return out;
}

export async function premiumOverview(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<StaffPremiumOverview> {
  requireStaff(staff, 'premium.view');
  const { range } = parse(premiumOverviewRequestSchema, data ?? {});
  const t = now.getTime();
  const span = rangeDays[range] * DAY;
  const config = await readEntitlementsConfig(db);

  const [familySnap, grantSnap, opSnap, jobSnap, accountSnap, eventSnap] = await Promise.all([
    db
      .collection('families')
      .select('createdAt', 'usedBytes', 'quotaBytes', 'storageAddOn')
      .limit(SCAN_CAP)
      .get(),
    db
      .collectionGroup('grants')
      .select('source', 'status', 'environment', 'validFrom', 'validUntil')
      .limit(SCAN_CAP)
      .get(),
    db.collectionGroup('quotaOps').select('state', 'reservedAt', 'createdAt').limit(SCAN_CAP).get(),
    db
      .collectionGroup('keepsakeJobs')
      .orderBy('createdAt', 'desc')
      .select('status', 'updatedAt', 'createdAt')
      .limit(300)
      .get(),
    db
      .collection('billingAccounts')
      .select('status', 'expiresAt', 'autoRenew', 'environment')
      .limit(SCAN_CAP)
      .get(),
    db.collection('billingEvents').select('outcome', 'receivedAt').limit(SCAN_CAP).get(),
  ]);

  // Premium now, by family, and when each family's current Premium began.
  const paid = new Set<string>();
  const granted = new Set<string>();
  const premiumSince = new Map<string, number>();
  for (const g of grantSnap.docs) {
    const family = g.ref.parent.parent;
    if (!family || family.parent.id !== 'families') continue;
    const from = ms(g.get('validFrom'));
    const live =
      g.get('environment') === environment &&
      ['active', 'grace'].includes(g.get('status') as string) &&
      from <= t &&
      t < ms(g.get('validUntil'));
    if (!live) continue;
    (g.get('source') === 'paid' ? paid : granted).add(family.id);
    premiumSince.set(family.id, Math.min(premiumSince.get(family.id) ?? from, from));
  }
  const premiumIds = new Set([...paid, ...granted]);

  const starts = buckets(range, now);
  const trend = starts.map((s) => ({
    start: new Date(s).toISOString(),
    newFamilies: 0,
    newPremium: 0,
  }));
  let newInRange = 0;
  let newBefore = 0;
  let addOn20 = 0;
  let addOn50 = 0;
  let storage80 = 0;
  const freeIds: string[] = [];
  for (const f of familySnap.docs) {
    const created = ms(f.get('createdAt'));
    if (created > t - span) newInRange += 1;
    else if (created > t - 2 * span) newBefore += 1;
    const b = bucketOf(starts, created);
    if (b >= 0 && created <= t) trend[b]!.newFamilies += 1;
    const premium = premiumIds.has(f.id);
    if (!premium) freeIds.push(f.id);
    const addOn = f.get('storageAddOn') as
      { id?: string; gb?: number; until?: unknown } | undefined;
    const addOnLive = premium && !!addOn && ms(addOn.until) > t;
    if (addOnLive && addOn?.id === 'storage_20') addOn20 += 1;
    if (addOnLive && addOn?.id === 'storage_50') addOn50 += 1;
    const limit = planLimits(config.plans, premium, {
      addOnGb: addOnLive ? (addOn?.gb ?? 0) : 0,
    }).storageBytes;
    const used = (f.get('usedBytes') as number | undefined) ?? 0;
    if (limit > 0 && used >= 0.8 * limit) storage80 += 1;
  }
  for (const [, since] of premiumSince) {
    const b = bucketOf(starts, since);
    if (b >= 0 && since <= t) trend[b]!.newPremium += 1;
  }

  // Allowances: Free trial windows used up; Premium windows of the current cycle used up.
  const trial = await getAll(
    db,
    freeIds.map((id) => `families/${id}/quota/assistant_trial_v2`),
  );
  const freeTrialOut = trial.filter(
    (w) =>
      w.exists &&
      (w.get('used') as number) + ((w.get('reserved') as number) ?? 0) >=
        (w.get('limit') as number),
  ).length;
  let lumiOut = 0;
  let videoOut = 0;
  const premiumList = [...premiumIds].slice(0, 500);
  for (const id of premiumList) {
    const windows = await db.collection(`families/${id}/quota`).limit(40).get();
    let lumi = false;
    let video = false;
    for (const w of windows.docs) {
      const end = ms(w.get('resetsAt') ?? w.get('windowEnd'));
      const start = ms(w.get('startsAt') ?? w.get('windowStart'));
      if (!(start <= t && t < end)) continue;
      const out =
        ((w.get('used') as number | undefined) ?? 0) >=
          ((w.get('limit') as number | undefined) ?? 0) &&
        ((w.get('limit') as number | undefined) ?? 0) > 0;
      if (!out) continue;
      if (w.get('feature') === 'assistant') lumi = true;
      if (w.get('feature') === 'video') video = true;
    }
    if (lumi) lumiOut += 1;
    if (video) videoOut += 1;
  }

  // Store subscriptions (none before in-app purchase).
  let active = 0;
  let dueInRange = 0;
  let cancelled = 0;
  let billingIssue = 0;
  let refunded = 0;
  for (const a of accountSnap.docs) {
    if (a.get('environment') !== environment) continue;
    const status = a.get('status') as string;
    const expires = ms(a.get('expiresAt'));
    if (status === 'active' || status === 'grace') active += 1;
    if (status === 'active' && expires > t && expires <= t + span) dueInRange += 1;
    if (status === 'active' && a.get('autoRenew') === false) cancelled += 1;
    if (status === 'grace' || status === 'billing_retry') billingIssue += 1;
    if (status === 'revoked' || status === 'refunded') refunded += 1;
  }

  const failedJobs24h = jobSnap.docs.filter(
    (j) => j.get('status') === 'failed' && ms(j.get('updatedAt') ?? j.get('createdAt')) >= t - DAY,
  ).length;
  // A hold older than 15 minutes should have been settled (quota-sweeper releases it).
  const held = opSnap.docs.filter(
    (o) =>
      o.get('state') === 'reserved' &&
      ms(o.get('reservedAt') ?? o.get('createdAt')) < t - 15 * 60_000,
  ).length;
  const unmatched = eventSnap.docs.filter((e) => e.get('outcome') === 'not_found').length;

  const total = familySnap.size;
  const premium = premiumIds.size;
  return {
    range,
    families: {
      total,
      free: Math.max(0, total - premium),
      premium,
      paid: paid.size,
      granted: [...granted].filter((id) => !paid.has(id)).length,
      newInRange,
      growthPct: newBefore > 0 ? Math.round(((newInRange - newBefore) / newBefore) * 100) : null,
    },
    addOns: { total: addOn20 + addOn50, storage20: addOn20, storage50: addOn50 },
    revenue: { gross: null, net: null, costPerPremium: null },
    trend,
    limits: {
      premiumLumiOut: { n: lumiOut, of: premiumList.length },
      premiumVideoOut: { n: videoOut, of: premiumList.length },
      storage80: { n: storage80, of: total },
      freeTrialOut: { n: freeTrialOut, of: freeIds.length },
    },
    renewals: { active, dueInRange, cancelled, billingIssue, refunded },
    attention: { failedJobs24h, held, unmatched },
    capped:
      familySnap.size >= SCAN_CAP ||
      grantSnap.size >= SCAN_CAP ||
      opSnap.size >= SCAN_CAP ||
      premiumIds.size > premiumList.length,
  };
}
