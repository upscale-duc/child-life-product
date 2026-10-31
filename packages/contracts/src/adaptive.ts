import { z } from 'zod';
import { interests, type Interest } from './personalization.js';

/**
 * Adaptive Experience (Figma `930:11858`, AX00–AX45; plan `docs/product/adaptive-experience-plan.md`).
 * One app and one nav for every age: the child's age band + the person's goals only ORDER what V1
 * already has and set the "Gợi ý cho …" labels. Nothing is locked by age (AX00 rule 1), nothing
 * unbuilt is offered as if it worked (rule 2), and a birthday never hides anything by itself
 * (rule 5, AX33). Pure functions; `apps/mobile/lib/features/adaptive/adaptive_engine.dart` mirrors
 * them on the same fixtures.
 */

// ---------- Age (AX00 rule 7: from the date of birth, in the child's time zone) ----------

export const ageBands = ['b0_1', 'b1_3', 'b3_6', 'b6_12'] as const;
export type AgeBand = (typeof ageBands)[number];

/** AX33: the stage card is offered once at each of these ages (months). */
export const stageMilestones = [12, 36, 72] as const;
export type StageMilestone = (typeof stageMilestones)[number];

/** Whole calendar months from `dob` to `today`, both `YYYY-MM-DD` local dates of the child. */
export function ageInMonths(dob: string, today: string): number {
  const [dy, dm, dd] = dob.split('-').map(Number) as [number, number, number];
  const [ty, tm, td] = today.split('-').map(Number) as [number, number, number];
  let months = (ty - dy) * 12 + (tm - dm);
  // A birthday on the 31st counts from the month's last day in shorter months.
  const lastDay = new Date(Date.UTC(ty, tm, 0)).getUTCDate();
  if (td < Math.min(dd, lastDay)) months -= 1;
  return Math.max(0, months);
}

/** 0–1 under 12 months, 1–3 to 35, 3–6 to 71, then 6–12 (open-ended until a later chapter, Q-094). */
export function ageBandFor(months: number): AgeBand {
  if (months < 12) return 'b0_1';
  if (months < 36) return 'b1_3';
  if (months < 72) return 'b3_6';
  return 'b6_12';
}

/** The latest stage milestone reached, or null before 12 months. */
export function milestoneReached(months: number): StageMilestone | null {
  let reached: StageMilestone | null = null;
  for (const m of stageMilestones) if (months >= m) reached = m;
  return reached;
}

// ---------- Goals (AX03 / AX04 "Bạn muốn Child Life giúp gì cho …?") ----------

export const goals = [
  'track_care',
  'memories',
  'growth_vaccines',
  'family',
  'spending',
  'reminders',
] as const;
export type Goal = (typeof goals)[number];

/** AX00 "Mục tiêu gợi ý sẵn": pre-ticked, badge "Gợi ý cho {tuổi}". */
export const presetGoals: Record<AgeBand, readonly Goal[]> = {
  b0_1: ['track_care', 'memories'],
  b1_3: ['memories', 'growth_vaccines'],
  b3_6: ['memories', 'spending', 'family'],
  b6_12: ['memories', 'reminders', 'spending'],
};

/**
 * D-143 (4): the goals replace EN01's interests, so the content topics come from the child's
 * goals. Mirrors `interestsForGoals` in `apps/mobile/lib/features/adaptive/experience_repository.dart`.
 * Spending, family and reminders have no content topic.
 */
const goalInterests: Record<Goal, readonly Interest[]> = {
  track_care: ['sleep', 'feeding', 'nutrition'],
  memories: ['moments'],
  growth_vaccines: ['milestones', 'vaccines'],
  family: [],
  spending: [],
  reminders: [],
};

/** The content topics of [goals], in `interests` order, without duplicates. */
export function interestsForGoals(chosen: readonly Goal[]): Interest[] {
  const picked = new Set(chosen.flatMap((g) => goalInterests[g]));
  return interests.filter((i) => picked.has(i));
}

/** The goal list as AX03/AX04 show it: the band's presets first, then the rest in a fixed order. */
export function goalOrder(band: AgeBand): Goal[] {
  const preset = presetGoals[band];
  return [...preset, ...goals.filter((g) => !preset.includes(g))];
}

// ---------- Today widgets (feature registry for Hôm nay) ----------

/**
 * Ids keep the names of the existing `TodaySection`s so saved layouts map one to one; the new
 * ones are the AX10–AX13 widgets.
 */
export const widgetIds = [
  'tiles',
  'forYou',
  'solids',
  'reminders',
  'quickActions',
  'vaccine',
  'spending',
  'rhythm',
  'recent_memories',
  'moment_today',
  'create_from_memories',
  'growth',
  'family_view',
  // Hiểu con · "Điều đáng chú ý" (D-151 #4).
  'insight',
  // P-181: "Ai đang trông bé" (the app's WidgetId.careDuty).
  'care_duty',
] as const;
export type WidgetId = (typeof widgetIds)[number];

export interface WidgetEntry {
  id: WidgetId;
  /** Goals this widget serves ("Vì: …", "Theo mục tiêu …"); none = "Luôn có". */
  goals: readonly Goal[];
  /** Product priority, 0–1 (AX00 weight 10 %). All 0 at launch; tuned from analytics. */
  product: number;
}

export const widgetRegistry: readonly WidgetEntry[] = [
  { id: 'tiles', goals: ['track_care'], product: 0 },
  { id: 'forYou', goals: ['track_care'], product: 0 },
  { id: 'solids', goals: ['track_care'], product: 0 },
  { id: 'reminders', goals: ['reminders'], product: 0 },
  { id: 'quickActions', goals: [], product: 0 },
  { id: 'vaccine', goals: ['growth_vaccines'], product: 0 },
  { id: 'spending', goals: ['spending'], product: 0 },
  { id: 'rhythm', goals: [], product: 0 },
  { id: 'recent_memories', goals: ['memories'], product: 0 },
  { id: 'moment_today', goals: ['memories'], product: 0 },
  { id: 'create_from_memories', goals: ['memories'], product: 0 },
  { id: 'growth', goals: ['growth_vaccines'], product: 0 },
  { id: 'family_view', goals: ['family'], product: 0 },
  { id: 'insight', goals: ['track_care'], product: 0 },
  { id: 'care_duty', goals: ['family'], product: 0 },
];

/**
 * AX00 "Hôm nay · thứ tự mặc định", with the existing sections in their D-076 places (Dành cho
 * bé hôm nay and Ăn dặm hôm nay right after the tiles). These lists already encode the band's
 * preset goals, which is why the goal term is scored relative to the presets.
 */
export const bandDefaults: Record<AgeBand, readonly WidgetId[]> = {
  b0_1: [
    'tiles',
    'insight',
    'forYou',
    'solids',
    'reminders',
    'recent_memories',
    'growth',
    'care_duty',
  ],
  b1_3: [
    'recent_memories',
    'tiles',
    'insight',
    'forYou',
    'solids',
    'reminders',
    'growth',
    'care_duty',
  ],
  b3_6: [
    'moment_today',
    'create_from_memories',
    'spending',
    'reminders',
    'family_view',
    'care_duty',
  ],
  b6_12: ['recent_memories', 'reminders', 'spending', 'growth'],
};

/** AX00 weights, "trọng số khởi tạo để thử nghiệm". */
export const rankWeights = {
  goal: 0.35,
  age: 0.25,
  usage: 0.2,
  recent: 0.1,
  product: 0.1,
} as const;

// ---------- The person's arrangement: users/{uid}/experience/{babyId} ----------

export const goalsSources = ['chosen', 'skipped', 'migrated'] as const;
export const stagePromptAnswers = ['applied', 'kept'] as const;

const widgetList = z
  .array(z.enum(widgetIds))
  .max(widgetIds.length)
  .refine((l) => new Set(l).size === l.length, 'duplicate');

/**
 * Per person × child (P-175): "what do you want help with" is the person's, and Mẹ and Ba may
 * arrange Hôm nay differently. Client-written; Rules mirror this schema.
 */
export const experienceSchema = z.object({
  v: z.literal(1),
  /** The path's baby, so deleting the baby purges every viewer's copy (account.ts). */
  babyId: z.string().min(1).max(128),
  goals: z
    .array(z.enum(goals))
    .max(goals.length)
    .refine((l) => new Set(l).size === l.length, 'duplicate'),
  goalsSource: z.enum(goalsSources),
  /** The band whose defaults are in force. Changes only on "Áp dụng" (AX33), "Khôi phục gợi ý
   * theo tuổi" (AX14) or a goal edit, never on a birthday alone. */
  bandApplied: z.enum(ageBands),
  /** The person's own order; empty = ranked. */
  order: widgetList,
  /** "Ghim · luôn ở đầu", in pin order. */
  pinned: widgetList,
  /** Turned on although hidden by default. */
  shown: widgetList,
  /** Turned off; never comes back by itself. */
  hidden: widgetList,
  stagePrompts: z
    .object({
      m12: z.enum(stagePromptAnswers).optional(),
      m36: z.enum(stagePromptAnswers).optional(),
      m72: z.enum(stagePromptAnswers).optional(),
    })
    .strict(),
  updatedAt: z.unknown(),
});
export type Experience = z.infer<typeof experienceSchema>;

export function defaultExperience(
  band: AgeBand,
  babyId = 'b',
  source: (typeof goalsSources)[number] = 'skipped',
): Experience {
  return {
    v: 1,
    babyId,
    goals: [...presetGoals[band]],
    goalsSource: source,
    bandApplied: band,
    order: [],
    pinned: [],
    shown: [],
    hidden: [],
    stagePrompts: {},
    updatedAt: null,
  };
}

// ---------- Ranking (AX00 rules 3–5) ----------

export interface RankSignals {
  /** 0–1 per widget: this person's opens of its module over 28 days, normalised. */
  usage?: Partial<Record<WidgetId, number>>;
  /** Widgets whose module had activity for this child in the last 48 h. */
  recent?: ReadonlySet<WidgetId>;
}

export type WidgetReason =
  { kind: 'goal'; goal: Goal } | { kind: 'age' } | { kind: 'always' } | { kind: 'pinned' };

export interface RankedWidget {
  id: WidgetId;
  visible: boolean;
  pinned: boolean;
  /** Why it is there ("Vì: …") or why it is hidden by default ("Ẩn theo gợi ý tuổi"). */
  reason: WidgetReason;
  score: number;
}

const entryOf = (id: WidgetId): WidgetEntry => widgetRegistry.find((w) => w.id === id)!;

/**
 * [explicit]: the person ticked the goals (AX03/AX04 or "Sửa"). Then every ticked goal counts
 * the same; before that (skipped, migrated) the goal term is relative to the band's presets, so
 * Hôm nay is exactly the AX00 default (D-097 Q-087). Owner, 2026-10-24: a 17-month-old's ticked
 * "Lưu giữ kỷ niệm" and "Tăng trưởng & tiêm chủng" ranked last, under the goals added to them.
 */
export function scoreWidget(
  id: WidgetId,
  band: AgeBand,
  chosen: readonly Goal[],
  signals: RankSignals = {},
  explicit = false,
): number {
  const entry = entryOf(id);
  const serves = (gs: readonly Goal[]) => entry.goals.some((g) => gs.includes(g));
  const goal = explicit
    ? serves(chosen)
      ? 1
      : 0
    : (serves(chosen) ? 1 : 0) - (serves(presetGoals[band]) ? 1 : 0);
  const list = bandDefaults[band];
  const at = list.indexOf(id);
  const age = at < 0 ? 0 : 1 - at / list.length;
  const usage = Math.min(1, Math.max(0, signals.usage?.[id] ?? 0));
  const recent = signals.recent?.has(id) ? 1 : 0;
  return (
    rankWeights.goal * goal +
    rankWeights.age * age +
    rankWeights.usage * usage +
    rankWeights.recent * recent +
    rankWeights.product * entry.product
  );
}

/**
 * Shown unless the person changed it: in the band's default list, or serving a goal the person
 * added beyond the band's presets (the presets are already in the list).
 */
export function defaultVisible(id: WidgetId, band: AgeBand, chosen: readonly Goal[]): boolean {
  const added = chosen.filter((g) => !presetGoals[band].includes(g));
  return bandDefaults[band].includes(id) || entryOf(id).goals.some((g) => added.includes(g));
}

function reasonFor(id: WidgetId, band: AgeBand, chosen: readonly Goal[]): WidgetReason {
  const goal = entryOf(id).goals.find((g) => chosen.includes(g));
  if (goal) return { kind: 'goal', goal };
  if (bandDefaults[band].includes(id)) return { kind: 'age' };
  return { kind: 'always' };
}

/**
 * Hôm nay for one child. [available] = the widgets this viewer can have right now (released,
 * flag, role, capability, data such as trackers), decided by the caller; nothing else is listed.
 * Order: pinned (in pin order, never moved) → the person's manual order if any (new widgets
 * inserted by score) → otherwise by score. Hidden widgets are returned with `visible: false` so
 * "Đã ẩn" can list them.
 */
export function rankToday(
  exp: Experience,
  available: readonly WidgetId[],
  signals: RankSignals = {},
): RankedWidget[] {
  const band = exp.bandApplied;
  const tie = (id: WidgetId) => {
    const at = bandDefaults[band].indexOf(id);
    return (at < 0 ? bandDefaults[band].length : at) * 100 + widgetIds.indexOf(id);
  };
  const avail = widgetIds.filter((id) => available.includes(id));
  const explicit = exp.goalsSource === 'chosen';
  const scored = new Map(
    avail.map((id) => [id, scoreWidget(id, band, exp.goals, signals, explicit)]),
  );
  const byScore = (a: WidgetId, b: WidgetId) => scored.get(b)! - scored.get(a)! || tie(a) - tie(b);

  const pinned = exp.pinned.filter((id) => scored.has(id));
  const rest = avail.filter((id) => !pinned.includes(id));
  let ordered: WidgetId[];
  if (exp.order.length > 0) {
    // P-176: a dragged order is kept as is; usage and recency never reshuffle it. Widgets the
    // order does not know yet (a feature released later) follow it, by score.
    const known = exp.order.filter((id) => rest.includes(id));
    ordered = [...known, ...rest.filter((w) => !known.includes(w)).sort(byScore)];
  } else {
    ordered = [...rest].sort(byScore);
  }

  return [...pinned, ...ordered].map((id) => ({
    id,
    pinned: pinned.includes(id),
    visible: exp.shown.includes(id)
      ? true
      : exp.hidden.includes(id)
        ? false
        : pinned.includes(id) || defaultVisible(id, band, exp.goals),
    reason: pinned.includes(id) ? { kind: 'pinned' } : reasonFor(id, band, exp.goals),
    score: scored.get(id)!,
  }));
}

/**
 * AX33: offer the stage card when the child passed a milestone the person has not answered and
 * whose band is newer than the one applied. Never changes anything by itself.
 */
export function stagePromptDue(exp: Experience, months: number): StageMilestone | null {
  const m = milestoneReached(months);
  if (m === null) return null;
  if (exp.stagePrompts[`m${m}`] !== undefined) return null;
  return ageBands.indexOf(ageBandFor(m)) > ageBands.indexOf(exp.bandApplied) ? m : null;
}

/**
 * "Áp dụng" (AX33): the new band's defaults take over; pins and the person's hides survive, the
 * manual order resets so the new order shows. "Khôi phục gợi ý theo tuổi" (AX14) also clears the
 * hides (`restore`): it is the person asking for the defaults back, not the app deciding.
 */
export function applyBand(exp: Experience, band: AgeBand, restore = false): Experience {
  return {
    ...exp,
    bandApplied: band,
    order: [],
    shown: [],
    hidden: restore ? [] : exp.hidden,
  };
}
