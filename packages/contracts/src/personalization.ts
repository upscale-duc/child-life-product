import { z } from 'zod';
import {
  addDaysIso,
  contentReviewSchema,
  contentSourceSchema,
  referenceModelSchema,
  rhythmRulesSchema,
  type Observation,
} from './rhythm.js';

/**
 * One personalization engine for every module (brief p.11, plan §5.4): preferences → current need
 * → eligible approved content → ranking → one primary action (+ ≤2 secondary) → feedback → the
 * next visit changes. Pure: the server ranks, the app draws; the reason is always explicable.
 */

const localized = z.object({ vi: z.string().min(1).max(2000), en: z.string().min(1).max(2000) });
const localizedList = z.object({
  vi: z.array(z.string().min(1).max(400)).max(12),
  en: z.array(z.string().min(1).max(400)).max(12),
});

// ---------- Preferences (EN01, EN02; per person, free) ----------

/** EN01 "điều bạn quan tâm": enduring interests, not today's need. */
export const interests = [
  'sleep',
  'feeding',
  'milestones',
  'vaccines',
  'nutrition',
  'moments',
] as const;
export type Interest = (typeof interests)[number];

/** `users/{uid}/settings/personalization` (client-written, per person, never a household fact). */
export const userPreferencesSchema = z.object({
  interests: z.array(z.enum(interests)).max(interests.length),
  /** EN02: when to gather suggestions, "HH:mm" local; null = no digest. */
  digestTime: z
    .string()
    .regex(/^([01]\d|2[0-3]):[0-5]\d$/)
    .nullable(),
  /** Quiet hours for suggestions only; reminders the person set always ring (EN07). */
  quietHours: z
    .object({
      from: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/),
      to: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/),
    })
    .nullable(),
  /** "Ít gợi ý kiểu này hơn" (EN05): kinds this person sees less of; free forever. */
  fewer: z.array(z.enum(interests)).max(interests.length),
  updatedAt: z.string().nullable(),
});
export type UserPreferences = z.infer<typeof userPreferencesSchema>;

export const defaultUserPreferences: UserPreferences = {
  interests: [],
  digestTime: null,
  quietHours: { from: '22:00', to: '06:00' },
  fewer: [],
  updatedAt: null,
};

// ---------- Content (PN03; published like first aid, reviewed later, D-073 #2) ----------

/** The current need a check-in reports (C01), as content tags. */
export const needs = ['sleep', 'feeding', 'soothing', 'play', 'milestone', 'bonding'] as const;
export type Need = (typeof needs)[number];

export function needOf(o: Observation): Need | null {
  switch (o) {
    case 'sleep':
      return 'sleep';
    case 'feeding':
      return 'feeding';
    case 'soothing':
      return 'soothing';
    case 'new_skill':
      return 'milestone';
    case 'usual':
    case 'health':
      return null;
  }
}

export const contentStatuses = ['draft', 'published', 'retired'] as const;

/** One suggested activity (AC01, NL08): steps, age, needs, safety, sources, review. */
export const activitySchema = z
  .object({
    id: z.string().regex(/^act_[a-z0-9_]{2,40}$/),
    version: z.number().int().min(1),
    status: z.enum(contentStatuses),
    title: localized,
    summary: localized,
    steps: localizedList,
    /** "Không khi…": when not to do it. */
    safety: localized.nullable(),
    durationMin: z.number().int().min(1).max(120),
    ageDays: z.object({ from: z.number().int().min(0), to: z.number().int().min(0) }),
    needs: z.array(z.enum(needs)).min(1),
    interests: z.array(z.enum(interests)),
    /** Best time of day, for "Thử tối nay" vs "Thử hôm nay". */
    timeOfDay: z.enum(['any', 'evening', 'day']),
    locales: z.array(z.enum(['vi', 'en'])).min(1),
    /** Empty = every region with approved health content. */
    regions: z.array(z.string().regex(/^[A-Z]{2}$/)).max(50),
    sources: z.array(contentSourceSchema).max(6),
    review: contentReviewSchema,
  })
  .refine((a) => a.ageDays.to >= a.ageDays.from, 'Age range ends before it starts');
export type Activity = z.infer<typeof activitySchema>;

/** "Tuần này của {bé}" (Q-067): one free card per week of age, then per month. */
export const ageCardSchema = z
  .object({
    id: z.string().regex(/^age_[a-z0-9_]{2,40}$/),
    version: z.number().int().min(1),
    status: z.enum(contentStatuses),
    /** Age in days, from the date of birth (actual age; never the corrected one, brief p.13). */
    ageDays: z.object({ from: z.number().int().min(0), to: z.number().int().min(0) }),
    title: localized,
    /** What families often notice at this age, without a schedule ("mỗi bé mỗi khác"). */
    body: localized,
    tips: localizedList,
    /** When to ask a doctor at this age; empty when none. */
    watchFor: localizedList,
    interests: z.array(z.enum(interests)),
    sources: z.array(contentSourceSchema).max(6),
    review: contentReviewSchema,
  })
  .refine((a) => a.ageDays.to >= a.ageDays.from, 'Age range ends before it starts');
export type AgeCard = z.infer<typeof ageCardSchema>;

/**
 * Health routing (NL05b, NL06, HL01; free in every plan state). Region numbers come only from
 * this list: a region without an entry shows "gọi bác sĩ của bé", never a default hotline.
 */
export const healthPackSchema = z.object({
  signs: z
    .array(
      z.object({
        id: z.string().min(1).max(40),
        label: localized,
        /** Shown only below this age (e.g. fever under 3 months); null = any age. */
        maxAgeDays: z.number().int().min(0).nullable(),
      }),
    )
    .min(1)
    .max(20),
  /** "Trong lúc chờ": what to do while getting help. */
  whileWaiting: localizedList,
  disclaimer: localized,
  regions: z
    .array(
      z.object({
        country: z.string().regex(/^[A-Z]{2}$/),
        emergencyNumber: z.string().regex(/^[0-9]{2,4}$/),
      }),
    )
    .max(60),
  sources: z.array(contentSourceSchema).max(10),
  review: contentReviewSchema,
});
export type HealthPack = z.infer<typeof healthPackSchema>;

/** `publicConfig/content_rhythm`: activities, age cards and health routing, one version. */
export const rhythmContentSchema = z.object({
  version: z.string().regex(/^rc_\d{8}_\d{2}$/),
  activities: z.array(activitySchema).max(300),
  ageCards: z.array(ageCardSchema).max(200),
  health: healthPackSchema,
  publishedAt: z.string().nullable(),
});
export type RhythmContent = z.infer<typeof rhythmContentSchema>;

// ---------- Ranking (R01–R06, brief p.11) ----------

export interface RankFlags {
  id: string;
  published: boolean;
  locale: string;
  needMatch: boolean;
  interestMatch: boolean;
  previousHelpful: boolean;
  recentlyShown: boolean;
  notSuitable: boolean;
  cooldown: boolean;
  ageEligible: boolean;
}

/** Versioned weights; each flag is 0/1 (brief p.11). */
export const rankingWeights = {
  version: 'rank-v1',
  need: 3,
  interest: 2,
  helpful: 1,
  recent: -2,
  notSuitable: -4,
} as const;

export function rankScore(c: RankFlags): number {
  const w = rankingWeights;
  return (
    w.need * +c.needMatch +
    w.interest * +c.interestMatch +
    w.helpful * +c.previousHelpful +
    w.recent * +c.recentlyShown +
    w.notSuitable * +c.notSuitable
  );
}

/** Eligibility first (published, locale, age, not cooling down), then score, then id ascending. */
export function rankCandidates(locale: string, candidates: readonly RankFlags[]): RankFlags[] {
  return candidates
    .filter((c) => c.published && c.locale === locale && c.ageEligible && !c.cooldown)
    .sort((a, b) => rankScore(b) - rankScore(a) || a.id.localeCompare(b.id));
}

// ---------- Feedback (AC01, AC02, EN05) ----------

export const feedbackKinds = [
  /** "Mình sẽ thử" / "Thử tối nay". */
  'started',
  'helpful',
  'unsure',
  /** "Không phù hợp với con": this item is excluded for this baby until reset. */
  'not_suitable',
  /** "Không phải hôm nay" / "Để sau": cooldown only. */
  'not_today',
] as const;
export type FeedbackKind = (typeof feedbackKinds)[number];

/** `babies/{b}/recFeedback/{id}`: written by the phone (free data; using it needs rhythm.advanced). */
export const recFeedbackSchema = z.object({
  id: z.string().regex(/^fb_[a-f0-9]{32}$/),
  babyId: z.string().min(1).max(128),
  authorUid: z.string().min(1).max(128),
  contentId: z.string().min(1).max(60),
  contentVersion: z.number().int().min(1),
  kind: z.enum(feedbackKinds),
  /** Baby-local date the feedback is about ("Tối qua thế nào?"). */
  date: z.iso.date(),
  note: z.string().max(300).nullable(),
});
export type RecFeedback = z.infer<typeof recFeedbackSchema>;

export interface FeedbackMemory {
  helpful: Set<string>;
  notSuitable: Set<string>;
  /** contentId → last baby-local date it may not be suggested again (inclusive). */
  cooldownUntil: Map<string, string>;
  /** contentId → last date shown or started. */
  lastShown: Map<string, string>;
}

/** Folds a baby's feedback (any author) into what the ranking uses; newest wins per kind. */
export function feedbackMemory(
  rows: readonly Pick<RecFeedback, 'contentId' | 'kind' | 'date'>[],
  cooldownDays: number,
): FeedbackMemory {
  const m: FeedbackMemory = {
    helpful: new Set(),
    notSuitable: new Set(),
    cooldownUntil: new Map(),
    lastShown: new Map(),
  };
  const sorted = [...rows].sort((a, b) => a.date.localeCompare(b.date));
  for (const r of sorted) {
    switch (r.kind) {
      case 'helpful':
        m.helpful.add(r.contentId);
        m.notSuitable.delete(r.contentId);
        break;
      case 'not_suitable':
        m.notSuitable.add(r.contentId);
        m.helpful.delete(r.contentId);
        break;
      case 'not_today':
        m.cooldownUntil.set(r.contentId, addDaysIso(r.date, cooldownDays - 1));
        break;
      case 'started':
      case 'unsure':
        break;
    }
    if (r.kind === 'started' || r.kind === 'not_today') m.lastShown.set(r.contentId, r.date);
    // "Có ích" after trying it: the family may want it again tonight (PS02 "Thử lại tối nay"), so
    // the recently-shown penalty no longer applies; "Để sau" still cools it down.
    if (r.kind === 'helpful') m.lastShown.delete(r.contentId);
  }
  return m;
}

// ---------- Recommendation (H02, PS01, PS02) ----------

export const reasonCodes = [
  /** From what the family just reported (sparse data never claims more, brief p.11). */
  'SELF_REPORTED_NEED',
  /** From logged facts that pass the data-quality rules. */
  'DATA_INSIGHT',
  /** It helped before (AC02 "Có ích"); PS02 "Dựa trên phản hồi của bạn". */
  'PREVIOUS_HELPFUL',
  /** Free: age content. */
  'AGE_CONTENT',
  /** Free: the person's interests. */
  'INTEREST',
] as const;
export type ReasonCode = (typeof reasonCodes)[number];

export interface Recommendation {
  id: string;
  contentId: string;
  contentVersion: number;
  reasonCode: ReasonCode;
  /** Check-in / feedback ids the reason rests on (readable links, never "[F1]"). */
  supportingIds: string[];
  requiredCapability: 'personalization.cross_module' | 'module.basic';
  state: 'suggested' | 'started' | 'done' | 'dismissed';
  /** What changed since the last suggestion because of feedback (PS02 "Đã thay đổi"). */
  changes: ('prefers_helpful' | 'excluded_not_suitable' | 'cooling_down')[];
  cooldownUntil: string | null;
  generatedAt: string;
}

export interface RecommendInput {
  locale: 'vi' | 'en';
  today: string;
  ageDays: number;
  need: Need | null;
  interests: readonly Interest[];
  fewer: readonly Interest[];
  country: string | null;
  healthFlag: boolean;
  memory: FeedbackMemory;
  activities: readonly Activity[];
}

export type RecommendOutcome =
  | { kind: 'health' }
  | { kind: 'none' }
  | {
      kind: 'suggestion';
      primary: Activity;
      secondary: Activity[];
      reasonCode: ReasonCode;
      changes: Recommendation['changes'];
    };

/** Builds the ranking flags for real content and picks; health always wins (brief p.11 #1). */
export function recommend(x: RecommendInput): RecommendOutcome {
  if (x.healthFlag) return { kind: 'health' };
  const flags = x.activities.map((a): RankFlags & { a: Activity } => ({
    a,
    id: a.id,
    published: a.status === 'published',
    locale: a.locales.includes(x.locale) ? x.locale : '—',
    needMatch: x.need !== null && a.needs.includes(x.need),
    interestMatch:
      a.interests.some((i) => x.interests.includes(i)) &&
      !a.interests.every((i) => x.fewer.includes(i)),
    previousHelpful: x.memory.helpful.has(a.id),
    recentlyShown: (() => {
      const last = x.memory.lastShown.get(a.id);
      return last !== undefined && last >= addDaysIso(x.today, -2);
    })(),
    notSuitable: x.memory.notSuitable.has(a.id),
    cooldown: (x.memory.cooldownUntil.get(a.id) ?? '') >= x.today,
    ageEligible:
      x.ageDays >= a.ageDays.from &&
      x.ageDays <= a.ageDays.to &&
      (a.regions.length === 0 || (x.country !== null && a.regions.includes(x.country))),
  }));
  // "Không phù hợp" excludes the item outright for this baby (brief p.6).
  const ranked = rankCandidates(
    x.locale,
    flags.filter((f) => !f.notSuitable),
  ) as (RankFlags & { a: Activity })[];
  const relevant = x.need === null ? ranked : ranked.filter((f) => f.needMatch);
  if (relevant.length === 0) return { kind: 'none' };
  const top = relevant[0]!;
  const changes: Recommendation['changes'] = [];
  if (top.previousHelpful) changes.push('prefers_helpful');
  if (flags.some((f) => f.notSuitable && f.needMatch)) changes.push('excluded_not_suitable');
  if (flags.some((f) => f.cooldown && f.needMatch)) changes.push('cooling_down');
  return {
    kind: 'suggestion',
    primary: top.a,
    secondary: relevant.slice(1, 3).map((f) => f.a),
    reasonCode: top.previousHelpful
      ? 'PREVIOUS_HELPFUL'
      : x.need
        ? 'SELF_REPORTED_NEED'
        : 'INTEREST',
    changes,
  };
}

/** The free card for the baby's age (PS01F, H01): the narrowest range holding [ageDays]. */
export function ageCardFor(cards: readonly AgeCard[], ageDays: number): AgeCard | null {
  return (
    cards
      .filter(
        (c) => c.status === 'published' && ageDays >= c.ageDays.from && ageDays <= c.ageDays.to,
      )
      .sort((a, b) => a.ageDays.to - a.ageDays.from - (b.ageDays.to - b.ageDays.from))[0] ?? null
  );
}

// ---------- Callables ----------

export const nextActionRequestSchema = z.object({
  babyId: z.string().min(1).max(128),
  checkInId: z.string().regex(/^ci_[a-f0-9]{32}$/),
  locale: z.enum(['vi', 'en']),
});

export const composeHomeRequestSchema = z.object({
  babyId: z.string().min(1).max(128),
  locale: z.enum(['vi', 'en']),
});

/**
 * `nextAction` (PS01 / PS01F) and `composeHome` (H02 / PS02) answers. `gate` explains why only the
 * free result came back (PREMIUM_REQUIRED, REGION_UNAVAILABLE…); the free path never disappears.
 */
export interface NextActionAnswer {
  state: 'normal' | 'health' | 'suggestion' | 'free_content' | 'no_suggestion';
  recommendation: Recommendation | null;
  secondary: { contentId: string; contentVersion: number }[];
  ageCardId: string | null;
  gate: string | null;
  /** "Từ nhật ký": the sleep comparison when the data allows it (DATA_INSIGHT), else null. */
  sleep: {
    status: 'insufficient_data' | 'change_detected' | 'no_change';
    baseline: number | null;
    recent: number | null;
    validDays: number;
  } | null;
}

// ---------- Publishing (portal PN01–PN04; first-aid workflow, D-058 / D-073 #2) ----------

/** Two published documents: the reference model and the content pack. */
export const rhythmDocs = ['reference', 'content'] as const;
export type RhythmDoc = (typeof rhythmDocs)[number];
export const rhythmPublicDocIds: Record<RhythmDoc, string> = {
  reference: 'rhythm_reference',
  content: 'content_rhythm',
};

export const rhythmVersionIdSchema = z.string().regex(/^rv_[a-f0-9]{16}$/);

/** Save the open draft of one document (editing a version under review withdraws it). */
export const rhythmDraftSchema = z.discriminatedUnion('doc', [
  z
    .object({
      doc: z.literal('reference'),
      data: referenceModelSchema.omit({ version: true, publishedAt: true }),
      notes: z.string().trim().max(500),
    })
    .strict(),
  z
    .object({
      doc: z.literal('content'),
      data: rhythmContentSchema.omit({ version: true, publishedAt: true }),
      notes: z.string().trim().max(500),
    })
    .strict(),
]);

/**
 * Gửi duyệt · Duyệt & xuất bản (a second person) · Trả lại · Huỷ nháp · Dùng lại bản này.
 * On prod, approving needs `review` (a qualified reviewer); on dev, drafts may publish with items
 * still `review: null`, shown in the app as "Nội dung minh hoạ · chờ chuyên môn duyệt".
 */
export const rhythmActSchema = z
  .object({
    doc: z.enum(rhythmDocs),
    versionId: rhythmVersionIdSchema,
    action: z.enum(['submit', 'approve', 'reject', 'discard', 'rollback']),
    reason: z.string().trim().min(3).max(500),
    review: contentReviewSchema,
  })
  .strict();

/** `config/rhythm` (server): versioned rules, edited in PN04. */
export const rhythmConfigSchema = z.object({ rules: rhythmRulesSchema });

// ---------- Slice 2 server answers (added 2026-10-15) ----------

/** The stored recommendation a check-in produced: one id per check-in (idempotent `nextAction`). */
export function recommendationIdFor(checkInId: string): string {
  return `rec_${checkInId.replace(/^ci_/, '')}`;
}

/** The feedback a recommendation rests on, for PS02 ("Tối 08/10 Mẹ chọn Có ích…"). */
export interface FeedbackRef {
  id: string;
  contentId: string;
  kind: FeedbackKind;
  /** Baby-local date the feedback is about. */
  date: string;
  authorUid: string;
}

/** `composeHome` (H02 / PS02): the current primary recommendation plus the feedback behind it. */
export interface ComposeHomeAnswer extends NextActionAnswer {
  lastFeedback: FeedbackRef | null;
}

/** `staffSetRhythmRules` (PN04): the thresholds in `config/rhythm`, with a reason for the audit. */
export const setRhythmRulesSchema = z
  .object({
    rules: rhythmRulesSchema
      .refine((r) => r.baselineMinDays <= r.baselineMaxDays, 'baselineMinDays > baselineMaxDays')
      .refine((r) => r.recentMinDays <= r.recentDays, 'recentMinDays > recentDays')
      .refine((r) => r.baselineMaxDays <= r.baselineLookbackDays, 'baseline window too long'),
    reason: z.string().trim().min(3).max(500),
  })
  .strict();
