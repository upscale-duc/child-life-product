import { z } from 'zod';
import { staffReasonSchema } from './staff-reason.js';

/**
 * Premium v2 (Figma `958:13863`, plan `docs/product/premium-v2-plan.md`, D-101): one source of
 * plans and limits for the app, backend, website and portal (PV00). Two plans at launch, Free
 * and Premium; one Premium product paid monthly or yearly; storage add-ons +20 / +50 GB for
 * Premium; credit is never sold. In-app purchase comes later (owner, 2026-10-25): nothing here
 * charges anyone.
 */

const money = z.object({ month: z.number().min(0), year: z.number().min(0) });

export const storageAddOnIds = ['storage_20', 'storage_50'] as const;
export type StorageAddOnId = (typeof storageAddOnIds)[number];

/** Task costs in credit as staff see them (PT03); charging uses `quotas.assistant`. */
export const lumiTasks = ['quickAnswer', 'voiceLog', 'writeCaption', 'review7d', 'photo'] as const;
export type LumiTask = (typeof lumiTasks)[number];

export const premiumPlansSchema = z.object({
  free: z.object({
    /** "30 credit trải nghiệm một lần": never refilled (PV40B). */
    lumiCreditsOneTime: z.number().int().min(0).max(100000),
    /** "2 lượt trải nghiệm một lần". */
    videoExportsTrial: z.number().int().min(0).max(1000),
    storageGB: z.number().min(0).max(10000),
    caregiverSeats: z.number().int().min(1).max(100),
  }),
  premium: z.object({
    /** Refilled every month on the subscription day, also on a yearly plan (PV40). */
    lumiCreditsPerCycle: z.number().int().min(0).max(100000),
    videoExportsPerCycle: z.number().int().min(0).max(1000),
    storageGB: z.number().min(0).max(10000),
    caregiverSeats: z.number().int().min(1).max(100),
    price: z.object({ vn: money, intl: money }),
  }),
  storageAddOns: z
    .array(
      z.object({
        id: z.enum(storageAddOnIds),
        gb: z.number().min(1).max(10000),
        price: z.object({ vn: money, intl: money }),
      }),
    )
    .max(storageAddOnIds.length),
  /** "Không bán credit lẻ": always false at launch (PV00); kept so the portal shows it. */
  creditTopUps: z.literal(false),
  taskCosts: z.record(z.enum(lumiTasks), z.number().int().min(0).max(100)),
});
export type PremiumPlans = z.infer<typeof premiumPlansSchema>;

/** PV00 §1 and §5 "entitlements 2.0-launch", verbatim. */
export const defaultPremiumPlans: PremiumPlans = {
  free: { lumiCreditsOneTime: 30, videoExportsTrial: 2, storageGB: 1, caregiverSeats: 3 },
  premium: {
    lumiCreditsPerCycle: 200,
    videoExportsPerCycle: 4,
    storageGB: 10,
    caregiverSeats: 6,
    price: { vn: { month: 59000, year: 599000 }, intl: { month: 5.99, year: 49.99 } },
  },
  storageAddOns: [
    {
      id: 'storage_20',
      gb: 20,
      price: { vn: { month: 39000, year: 399000 }, intl: { month: 1.99, year: 19.99 } },
    },
    {
      id: 'storage_50',
      gb: 50,
      price: { vn: { month: 79000, year: 799000 }, intl: { month: 3.99, year: 39.99 } },
    },
  ],
  creditTopUps: false,
  // PT03; photo reading 3 credit (P-159, D-101 Q-104).
  taskCosts: { quickAnswer: 1, voiceLog: 1, writeCaption: 2, review7d: 5, photo: 3 },
};

export const GB = 1024 ** 3;

/** The plan's limits a family has now (PV40 / PV40B / PV45). */
export interface PlanLimits {
  plan: 'free' | 'premium';
  /** Free: one time (`once`), Premium: per monthly cycle. */
  lumi: { limit: number; refill: 'once' | 'monthly' };
  video: { limit: number; refill: 'once' | 'monthly' };
  storageBytes: number;
  caregiverSeats: number;
  premiumTemplates: boolean;
}

/**
 * [addOnGb]: an active storage add-on (Premium only, PV00). [extraBytes]: storage staff granted
 * on top (P-120 grants, kept as they were).
 */
export function planLimits(
  plans: PremiumPlans,
  premium: boolean,
  options: { addOnGb?: number; extraBytes?: number } = {},
): PlanLimits {
  const extra = Math.max(0, options.extraBytes ?? 0);
  if (!premium) {
    return {
      plan: 'free',
      lumi: { limit: plans.free.lumiCreditsOneTime, refill: 'once' },
      video: { limit: plans.free.videoExportsTrial, refill: 'once' },
      storageBytes: Math.round(plans.free.storageGB * GB) + extra,
      caregiverSeats: plans.free.caregiverSeats,
      premiumTemplates: false,
    };
  }
  return {
    plan: 'premium',
    lumi: { limit: plans.premium.lumiCreditsPerCycle, refill: 'monthly' },
    video: { limit: plans.premium.videoExportsPerCycle, refill: 'monthly' },
    storageBytes:
      Math.round((plans.premium.storageGB + Math.max(0, options.addOnGb ?? 0)) * GB) + extra,
    caregiverSeats: plans.premium.caregiverSeats,
    premiumTemplates: true,
  };
}

/** The Free trial window key: one per policy generation, so v2 starts everyone fresh (Q-096). */
export const freeTrialKey = 'v2';

/**
 * The monthly cycle containing [now] for a subscription that started at [anchor] (PV40 "mỗi
 * tháng theo ngày đăng ký", also on a yearly plan): same day of month and time as the anchor,
 * clamped to the month's last day; cut to [until]. UTC arithmetic, like the store's instants.
 */
export function monthlyCycle(anchor: Date, now: Date, until: Date): { start: Date; end: Date } {
  const at = (months: number) => {
    const y = anchor.getUTCFullYear();
    const m = anchor.getUTCMonth() + months;
    const last = new Date(Date.UTC(y, m + 1, 0)).getUTCDate();
    return new Date(
      Date.UTC(
        y,
        m,
        Math.min(anchor.getUTCDate(), last),
        anchor.getUTCHours(),
        anchor.getUTCMinutes(),
        anchor.getUTCSeconds(),
      ),
    );
  };
  if (now.getTime() < anchor.getTime()) {
    return { start: anchor, end: new Date(Math.min(at(1).getTime(), until.getTime())) };
  }
  let k =
    (now.getUTCFullYear() - anchor.getUTCFullYear()) * 12 +
    (now.getUTCMonth() - anchor.getUTCMonth());
  while (k > 0 && at(k).getTime() > now.getTime()) k -= 1;
  while (at(k + 1).getTime() <= now.getTime()) k += 1;
  return { start: at(k), end: new Date(Math.min(at(k + 1).getTime(), until.getTime())) };
}

// ---------- Seats (PV00 §2, E12, PV44, D-101 Q-097) ----------

/** Roles with write access take a caregiver seat; relatives (view Kỷ niệm) never do. */
export const seatRoles = ['coParent', 'caregiver'] as const;

/**
 * Whether one more writer fits: existing writers above the limit keep their access (Q-097), only
 * a new writer is refused once [writers] reach [seats].
 */
export function seatAvailable(writers: number, seats: number): boolean {
  return writers < seats;
}

// ---------- Entry points and paywall cards (PV00C) ----------

export const premiumCards = ['video', 'card', 'lumi', 'storage', 'caregivers', 'explore'] as const;
export type PremiumCard = (typeof premiumCards)[number];

export const premiumEntries = [
  'E01',
  'E02',
  'E03',
  'E04',
  'E05',
  'E06',
  'E07',
  'E08',
  'E09',
  'E10',
  'E11',
  'E12',
  'E13',
] as const;
export type PremiumEntry = (typeof premiumEntries)[number];

/** PV00C "Paywall mở ở": the card the paywall opens on; null = no paywall (E07 information). */
export const entryCard: Record<PremiumEntry, PremiumCard | 'addOn' | null> = {
  E01: 'video',
  E02: 'card',
  E03: 'video',
  E04: 'video',
  E05: 'lumi',
  E06: 'lumi',
  E07: null,
  // Premium families buy the add-on (PW10); Free families see PW04 (D-101 / plan §2 #6).
  E08: 'addOn',
  E09: 'addOn',
  E10: 'storage',
  E11: 'storage',
  E12: 'caregivers',
  E13: 'explore',
};

// ---------- Usage history (PV41: person · task · amount, never content) ----------

export const usageKinds = ['lumi', 'video', 'grant', 'refund'] as const;
export type UsageKind = (typeof usageKinds)[number];

export const usageHistoryRowSchema = z.object({
  id: z.string(),
  kind: z.enum(usageKinds),
  /** A label id the app translates: use lumi.chat / lumi.summary / lumi.photo / video.export;
   * allowance lumi.trial / lumi.cycle / video.trial / video.cycle; staff lumi.grant / video.grant.
   * A refund keeps the task it gives back. Never a question or a caption. */
  task: z.string().max(40),
  /** Member uid, or null for the system. */
  uid: z.string().nullable(),
  /** Credit for Lumi, lượt for video; negative = used, positive = granted / refunded. */
  amount: z.number().int(),
  state: z.enum(['held', 'debited', 'granted', 'refunded']),
  at: z.string(),
});
export type UsageHistoryRow = z.infer<typeof usageHistoryRowSchema>;

export const usageHistoryRequestSchema = z.object({
  babyId: z.string().min(1).max(128),
  kind: z.enum(['all', 'lumi', 'video', 'grants']).default('all'),
  /** Manager only; a member always gets their own rows (PV45). */
  everyone: z.boolean().default(false),
});

// ---------- Seat picker (PV44, Q-101) ----------

/** The manager keeps write access for [keep]; every other writer becomes view-only (nobody is
 * removed). The manager always keeps a seat and is not listed. */
export const chooseWriteSeatsRequestSchema = z.object({
  babyId: z.string().min(1).max(128),
  keep: z.array(z.string().min(1).max(128)).max(100),
});
export type ChooseWriteSeatsRequest = z.infer<typeof chooseWriteSeatsRequestSchema>;

// ---------- Gói của gia đình (PV40 / PV40B / PV45, D-101) ----------

export const familyPlanRequestSchema = z.object({ babyId: z.string().min(1).max(128) });

export interface PlanBalance {
  limit: number;
  used: number;
  reserved: number;
  /** When it refills (Premium cycle end); null for a Free one-time allowance. */
  resetsAt: string | null;
}

export interface PlanOffer {
  lumiCredits: number;
  videoExports: number;
  storageBytes: number;
  caregiverSeats: number;
}

/** `getFamilyPlan`: what Gói của gia đình draws. Balances are for the plan screens only — never
 * shown on buttons or in Lumi's header (D-081, Q-098). */
export interface FamilyPlanAnswer {
  v2: boolean;
  plan: 'free' | 'premium';
  /** The family manager (owner): sees everyone, picks seats, manages the plan. */
  isManager: boolean;
  /** The current monthly cycle (Premium), else null. */
  cycle: { start: string; end: string } | null;
  /** End of the Premium period (the grant), else null. */
  validUntil: string | null;
  lumi: PlanBalance;
  video: PlanBalance;
  storage: { usedBytes: number; limitBytes: number; addOnGb: number };
  /** Writers (Cùng nuôi + Người chăm sóc) against the plan's seats; [suspended] are view-only
   * after a downgrade (PV44). [overLimit]: the manager has a choice to make. */
  seats: { used: number; limit: number; suspended: string[]; overLimit: boolean };
  premiumTemplates: boolean;
  /** Both plans as configured, for the paywall comparison and PV42 ("sau ngày đó, nhà mình
   * về Free"). */
  offer: Record<'free' | 'premium', PlanOffer>;
  prices: PremiumPlans['premium']['price'];
  storageAddOns: PremiumPlans['storageAddOns'];
}

// ---------- Portal (PT01–PT04): versions, two approvers, adjustments, refunds ----------

const familyCode = z.string().regex(/^F-[A-Z2-9]{4}$/);
const proposalId = z.string().regex(/^p[pa]_[A-Za-z0-9_-]{8,40}$/);

/** PT03: a new plans version takes effect only once a second person approves it (D-058). */
export const proposePlansSchema = z.object({
  version: z.string().regex(/^[0-9A-Za-z][0-9A-Za-z.-]{0,39}$/),
  plans: premiumPlansSchema,
  reason: staffReasonSchema,
});
export const decideProposalSchema = z.object({
  id: proposalId,
  approve: z.boolean(),
  reason: staffReasonSchema,
});

/** PT02: an adjustment above this many credit / lượt needs a second approver. */
export const adjustmentApprovalThreshold = 50;

/** PT02 "Điều chỉnh": credit (Lumi) or lượt (video) added to (or taken from) the family's
 * current allowance, with a reason; never below what is already used. */
export const adjustUsageSchema = z.object({
  code: familyCode,
  feature: z.enum(['lumi', 'video']),
  amount: z
    .number()
    .int()
    .min(-1000)
    .max(1000)
    .refine((v) => v !== 0),
  reason: staffReasonSchema,
});

/** PT04: give back the lượt of a video that rendered wrongly (a failed render refunds itself). */
export const refundVideoJobSchema = z.object({
  code: familyCode,
  /** The job as Render ops shows it ("KJ-1A2B"). */
  job: z.string().regex(/^KJ-[0-9A-F]{4}$/),
  reason: staffReasonSchema,
});

export const proposalKinds = ['plans', 'adjustment'] as const;

export interface StaffProposal {
  id: string;
  kind: (typeof proposalKinds)[number];
  status: 'pending' | 'approved' | 'rejected';
  /** Plans: the version and its values; adjustment: the family code, feature and amount. */
  version: string | null;
  plans: PremiumPlans | null;
  adjustment: { code: string; feature: 'lumi' | 'video'; amount: number } | null;
  reason: string;
  by: string;
  at: string;
  decidedBy: string | null;
  decidedAt: string | null;
  /** The caller wrote it and may not approve it (unless the Owner self-approve switch). */
  mine: boolean;
}

// ---------- Portal: Tổng quan Premium (PT01) and the family plan switch ----------

export const premiumOverviewRanges = ['7d', '30d', '12m'] as const;
export type PremiumOverviewRange = (typeof premiumOverviewRanges)[number];
export const premiumOverviewRequestSchema = z.object({
  range: z.enum(premiumOverviewRanges).default('30d'),
});

/** A share: [n] of [of] (null when there is nobody to count). */
export interface OverviewShare {
  n: number;
  of: number;
}

/** `staffPremiumOverview`: counts only, never a family's content. Revenue, store fees and the
 * cost to serve come with in-app purchase and cost metering; until then they are null. */
export interface StaffPremiumOverview {
  range: PremiumOverviewRange;
  families: {
    total: number;
    free: number;
    premium: number;
    /** Premium from a store subscription / given by staff. */
    paid: number;
    granted: number;
    /** Families created in the range, and the change against the range before (%). */
    newInRange: number;
    growthPct: number | null;
  };
  addOns: { total: number; storage20: number; storage50: number };
  revenue: { gross: number | null; net: number | null; costPerPremium: number | null };
  /** Buckets of the range (days for 7d, weeks for 30d, months for 12m), oldest first. */
  trend: Array<{ start: string; newFamilies: number; newPremium: number }>;
  limits: {
    premiumLumiOut: OverviewShare;
    premiumVideoOut: OverviewShare;
    storage80: OverviewShare;
    freeTrialOut: OverviewShare;
  };
  renewals: { active: number; dueInRange: number; cancelled: number; billingIssue: number; refunded: number };
  attention: { failedJobs24h: number; held: number; unmatched: number };
  /** A scan hit its cap: counts are a floor. */
  capped: boolean;
}

/** "Gói: Free | Premium" for one family. Premium: every Premium capability (the one staff grant,
 * optional last day). Free: every staff / promo grant revoked; a store subscription stays. */
export const setFamilyPlanSchema = z.object({
  code: familyCode,
  plan: z.enum(['free', 'premium']),
  until: z.string().datetime().nullish(),
  reason: staffReasonSchema,
});
