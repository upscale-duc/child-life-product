import { z } from 'zod';
import type {
  Activity,
  ActivityKind,
  FeedbackMemory,
  Interest,
  Need,
  ReasonCode,
} from './personalization.js';
import { daysBetweenIso, type RhythmRules } from './rhythm.js';

/**
 * D-154 (owner, 2026-10-31, on `docs/product/suggestion-logic-analysis.md`): rank-v2 for Hôm nay's
 * "Ý tưởng hôm nay" and ENG-06. rank-v1 (`recommend`) broke ties by id and only remembered an idea
 * when someone answered it, so a family saw the same idea for a whole age window. Here:
 *
 * - one pick per baby and day, shared by the household and stable through the day;
 * - an exposure log per baby (`babies/{b}/personalization/exposure`): no repeat inside a gap,
 *   "Đã thử" rests, "Có ích" comes back after a rest, ideas scrolled past lose ground;
 * - safety checks and cards for the parents never lead (Q1): they ride along as one extra card;
 * - ties broken by a hash of (baby, date, activity) instead of the id.
 *
 * Pure: no clock, no randomness; the same input gives the same pick.
 */

/**
 * D-154 P1: the published items that are a safety check or are for the parents, for packs
 * published before the `kind` field (P2). A pack's own `kind` always wins.
 */
const derivedKinds: Readonly<Record<string, ActivityKind>> = {
  act_safe_sleep_check: 'check',
  act_bed_sharing_safer: 'check',
  act_car_seat_every_trip: 'check',
  act_water_safety_home: 'check',
  act_sun_and_mosquitoes: 'check',
  act_choking_safe_foods: 'check',
  act_hot_weather_comfort: 'check',
  act_vitamin_d_drops: 'check',
  act_potty_readiness: 'check',
  act_parent_break: 'parent',
  act_parent_check_in: 'parent',
  act_partner_care_time: 'parent',
};
export function activityKindOf(
  a: Pick<Activity, 'id'> & { kind?: ActivityKind | undefined },
): ActivityKind {
  return a.kind ?? derivedKinds[a.id] ?? 'activity';
}

/** Versioned weights of the daily pick (rank-v2); the rests and gaps are rules (`config/rhythm`). */
export const dailyRankingWeights = {
  version: 'rank-v2',
  need: 3,
  interest: 1,
  /** "Có ích" before, and its rest is over. */
  helpfulAgain: 1,
  /** It became right for the baby's age less than `newForAgeDays` ago. */
  newForAge: 1,
  newForAgeDays: 14,
  /** A short age window (≤ `narrowWindowDays`) is more about now than a year-long one. */
  narrowWindow: 0.5,
  narrowWindowDays: 120,
  /** Never shown to this baby. */
  novelty: 0.5,
  /** Per day it led without anyone answering, up to `ignoredCap`. */
  ignored: -1,
  ignoredCap: 3,
  /** At most this much from the (baby, date, activity) hash: picks among equals, never over a signal. */
  jitter: 0.9,
  /** A check shown for the first time, ahead of the other extras. */
  firstCheck: 1.5,
  /** P3: linked to the reference stage the baby is in now (`ReferenceStage.activityIds`). */
  stage: 1,
  /** P3: what the diary shows (Premium sleep facts), under a need the family reported (3). */
  diary: 1.5,
} as const;

/** Why the pick: rank-v1's codes, plus STAGE (P3); DATA_INSIGHT is the diary signal. */
export type DailyReason = ReasonCode | 'STAGE';

const isoDate = z.iso.date();
// Every field has a default: answers are merged into an item the pick may not have written yet.
export const exposureItemSchema = z.object({
  lastShown: isoDate.nullable().default(null),
  /** The `lastShown` before it: a re-pick later the same day ranks as if today had not happened. */
  prevShown: isoDate.nullable().default(null),
  shown: z.number().int().min(0).default(0),
  /** Days it led and nobody answered it by the next pick. */
  ignored: z.number().int().min(0).default(0),
  lastAnswered: isoDate.nullable().default(null),
  lastTried: isoDate.nullable().default(null),
  lastHelpful: isoDate.nullable().default(null),
});
export type ExposureItem = z.infer<typeof exposureItemSchema>;

export const dailyPickSchema = z.object({
  date: isoDate,
  primary: z.string().min(1).max(60),
  secondary: z.array(z.string().min(1).max(60)).max(3),
  extra: z.string().min(1).max(60).nullable(),
  reasonCode: z.string().min(1).max(40),
  /** What the pick was made for: another need makes a new household pick. */
  need: z.string().max(20).nullable(),
  context: z.string().max(20),
  rankVersion: z.string().min(1).max(20),
});
export type DailyPick = z.infer<typeof dailyPickSchema>;

/** `babies/{b}/personalization/exposure` (server-written; ids, dates and counts only). */
export const suggestionExposureSchema = z.object({
  day: dailyPickSchema.nullable().default(null),
  lastExtraOn: isoDate.nullable().default(null),
  items: z.record(z.string().min(1).max(60), exposureItemSchema).default({}),
});
export type SuggestionExposure = z.infer<typeof suggestionExposureSchema>;
export const emptyExposure: SuggestionExposure = { day: null, lastExtraOn: null, items: {} };

/** The stored log, or an empty one when it is missing or malformed (never an error). */
export function readExposure(data: unknown): SuggestionExposure {
  const parsed = suggestionExposureSchema.safeParse(data);
  return parsed.success ? parsed.data : emptyExposure;
}

const emptyItem: ExposureItem = {
  lastShown: null,
  prevShown: null,
  shown: 0,
  ignored: 0,
  lastAnswered: null,
  lastTried: null,
  lastHelpful: null,
};

export type DailyRules = Pick<
  RhythmRules,
  | 'rotationMaxGapDays'
  | 'triedRestDays'
  | 'helpfulRestDays'
  | 'extraEveryDays'
  | 'checkEveryDays'
  | 'parentEveryDays'
>;

export interface DailyPickInput {
  /** Seeds the tie-break so siblings and families do not move in step. */
  babyId: string;
  locale: 'vi' | 'en';
  today: string;
  ageDays: number;
  need: Need | null;
  /** `dailyContexts`: "busy" / "few_minutes" filter durations before this runs. */
  context: string;
  interests: readonly Interest[];
  fewer: readonly Interest[];
  country: string | null;
  healthFlag: boolean;
  /** Household feedback (empty without `rhythm.advanced`): "Không hợp", "Để sau", dates. */
  memory: FeedbackMemory;
  exposure: SuggestionExposure;
  rules: DailyRules;
  /** Published pack minus what this person or the family excluded or put off today. */
  activities: readonly Activity[];
  /** P3: ids linked to the current reference stage(s); empty without a due date. */
  stageActivityIds?: readonly string[];
  /** P3: a need the diary shows (sleep shorter than usual), never a reported one. */
  diaryNeed?: Need | null;
}

export type DailyPickOutcome =
  | { kind: 'health' }
  | { kind: 'none' }
  | {
      kind: 'suggestion';
      primary: Activity;
      secondary: Activity[];
      extra: Activity | null;
      reasonCode: DailyReason;
      /** True when today's stored pick was reused as is. */
      reused: boolean;
    };

/** FNV-1a over the key, as a number in [0, 1). */
export function stableUnit(key: string): number {
  let h = 0x811c9dc5;
  for (let i = 0; i < key.length; i++) {
    h ^= key.charCodeAt(i);
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return h / 0x1_0000_0000;
}

const later = (a: string | null | undefined, b: string | null | undefined) =>
  !a ? (b ?? null) : !b ? a : a > b ? a : b;

/** Today's pick for one baby (H02 "một gợi ý chính"); health always wins. */
export function pickDailySuggestion(x: DailyPickInput): DailyPickOutcome {
  if (x.healthFlag) return { kind: 'health' };
  const w = dailyRankingWeights;
  const r = x.rules;
  const item = (id: string) => x.exposure.items[id] ?? emptyItem;
  const since = (date: string | null) => (date ? daysBetweenIso(date, x.today) : Infinity);
  // Marks made today (by this pick or someone else's) never move a later pick the same day.
  const shownBefore = (id: string) => {
    const e = item(id);
    return e.lastShown === x.today ? e.prevShown : e.lastShown;
  };
  const shownCount = (id: string) => {
    const e = item(id);
    return e.shown - +(e.lastShown === x.today);
  };

  // Same eligibility as rank-v1: published, locale, age, region; "Không hợp" and "Để sau" out.
  const base = x.activities.filter(
    (a) =>
      a.status === 'published' &&
      a.locales.includes(x.locale) &&
      x.ageDays >= a.ageDays.from &&
      x.ageDays <= a.ageDays.to &&
      (a.regions.length === 0 || (x.country !== null && a.regions.includes(x.country))) &&
      !x.memory.notSuitable.has(a.id) &&
      (x.memory.cooldownUntil.get(a.id) ?? '') < x.today,
  );
  const needMatch = (a: Activity) => x.need !== null && a.needs.includes(x.need);
  const leads = base.filter(
    (a) => activityKindOf(a) === 'activity' && (x.need === null || needMatch(a)),
  );
  if (leads.length === 0) return { kind: 'none' };

  const interestMatch = (a: Activity) =>
    a.interests.some((i) => x.interests.includes(i)) &&
    !a.interests.every((i) => x.fewer.includes(i));
  const lastTried = (id: string) => later(item(id).lastTried, x.memory.startedOn?.get(id));
  const lastHelpful = (id: string) => later(item(id).lastHelpful, x.memory.helpfulOn?.get(id));
  const helpful = (id: string) => x.memory.helpful.has(id) || item(id).lastHelpful !== null;
  const stageMatch = (a: Activity) => x.stageActivityIds?.includes(a.id) ?? false;
  const diaryMatch = (a: Activity) =>
    x.need === null && x.diaryNeed != null && a.needs.includes(x.diaryNeed);
  const reasonOf = (a: Activity): DailyReason =>
    helpful(a.id) && since(lastHelpful(a.id)) >= r.helpfulRestDays
      ? 'PREVIOUS_HELPFUL'
      : x.need
        ? 'SELF_REPORTED_NEED'
        : diaryMatch(a)
          ? 'DATA_INSIGHT'
          : stageMatch(a)
            ? 'STAGE'
            : interestMatch(a)
              ? 'INTEREST'
              : 'AGE_CONTENT';

  // The household's pick for today stands while it is still eligible for this person and was made
  // for the same need (a day context only narrows `activities`).
  const day = x.exposure.day;
  if (
    day &&
    day.date === x.today &&
    day.need === x.need &&
    leads.some((a) => a.id === day.primary)
  ) {
    const byId = (id: string) => base.find((a) => a.id === id);
    return {
      kind: 'suggestion',
      primary: byId(day.primary)!,
      secondary: day.secondary.flatMap((id) => byId(id) ?? []),
      extra: day.extra ? (byId(day.extra) ?? null) : null,
      reasonCode: reasonOf(byId(day.primary)!),
      reused: true,
    };
  }

  const score = (a: Activity) => {
    const e = item(a.id);
    return (
      w.need * +needMatch(a) +
      w.interest * +interestMatch(a) +
      w.stage * +stageMatch(a) +
      w.diary * +diaryMatch(a) +
      w.helpfulAgain * +helpful(a.id) +
      w.newForAge * +(x.ageDays - a.ageDays.from < w.newForAgeDays) +
      w.narrowWindow * +(a.ageDays.to - a.ageDays.from <= w.narrowWindowDays) +
      w.novelty * +(shownCount(a.id) === 0) +
      w.ignored * Math.min(w.ignoredCap, e.ignored) +
      w.jitter * stableUnit(`${x.babyId}|${x.today}|${a.id}`)
    );
  };
  const rank = (pool: readonly Activity[]) =>
    pool
      .map((a) => ({ a, s: score(a) }))
      .sort((p, q) => q.s - p.s || p.a.id.localeCompare(q.a.id))
      .map((p) => p.a);

  // One lead a day: a pool of n keeps a gap of n / 2 days (at most the rule), so it never runs dry.
  const gap = Math.min(r.rotationMaxGapDays, Math.max(2, Math.floor(leads.length / 2)));
  const resting = (a: Activity) =>
    since(lastTried(a.id)) < r.triedRestDays ||
    (helpful(a.id) && since(lastHelpful(a.id)) < r.helpfulRestDays);
  const fresh = leads.filter((a) => !resting(a) && since(shownBefore(a.id)) >= gap);
  const rested = leads.filter((a) => !resting(a));
  // Never emptier than rank-v1: with everything resting, the longest unseen comes back first.
  const ranked =
    fresh.length > 0
      ? rank(fresh)
      : rank(rested.length > 0 ? rested : leads).sort((p, q) => {
          const a = since(shownBefore(p.id));
          const b = since(shownBefore(q.id));
          return a === b ? 0 : a > b ? -1 : 1;
        });
  const primary = ranked[0]!;

  const lastExtra = x.exposure.lastExtraOn;
  const extraDue =
    lastExtra === x.today ? x.exposure.day?.extra != null : since(lastExtra) >= r.extraEveryDays;
  const extra = extraDue
    ? (base
        .filter((a) => {
          const k = activityKindOf(a);
          const last = since(shownBefore(a.id));
          return (
            (k === 'check' && last >= r.checkEveryDays) ||
            (k === 'parent' && last >= r.parentEveryDays)
          );
        })
        .map((a) => ({
          a,
          s:
            w.firstCheck * +(activityKindOf(a) === 'check' && shownCount(a.id) === 0) +
            w.newForAge * +(x.ageDays - a.ageDays.from < w.newForAgeDays) +
            w.jitter * stableUnit(`${x.babyId}|${x.today}|${a.id}`),
        }))
        .sort((p, q) => q.s - p.s || p.a.id.localeCompare(q.a.id))[0]?.a ?? null)
    : null;

  // Two more ideas, other needs first so the three are not all about sleep.
  const rest = ranked.slice(1);
  const lead = primary.needs[0];
  const secondary = [
    ...rest.filter((a) => a.needs[0] !== lead),
    ...rest.filter((a) => a.needs[0] === lead),
  ].slice(0, extra ? 1 : 2);

  return {
    kind: 'suggestion',
    primary,
    secondary,
    extra,
    reasonCode: reasonOf(primary),
    reused: false,
  };
}

/**
 * Before the first pick of a new day: the last day's lead that nobody answered counts as scrolled
 * past once, and that day is closed (so rolling again changes nothing). The server stores the
 * result only together with a new pick.
 */
export function rollExposure(e: SuggestionExposure, today: string): SuggestionExposure {
  const day = e.day;
  if (!day || day.date >= today) return e;
  const lead = e.items[day.primary] ?? emptyItem;
  const answered = lead.lastAnswered !== null && lead.lastAnswered >= day.date;
  return {
    ...e,
    day: null,
    items: answered
      ? e.items
      : { ...e.items, [day.primary]: { ...lead, ignored: lead.ignored + 1 } },
  };
}

/**
 * Records [pick] as shown today, once per day: the lead and the extra card; the two smaller ideas
 * under the lead do not use up the rotation. It becomes the household's pick when there
 * is none for today yet or the stored one was made for another need; a re-pick for one person
 * (their own "Ẩn", a busy day) only marks what they were shown.
 */
export function recordDailyPick(
  e: SuggestionExposure,
  pick: Omit<DailyPick, 'rankVersion'>,
): SuggestionExposure {
  const items = { ...e.items };
  for (const id of [pick.primary, ...(pick.extra ? [pick.extra] : [])]) {
    const it = items[id] ?? emptyItem;
    if (it.lastShown !== pick.date)
      items[id] = { ...it, prevShown: it.lastShown, lastShown: pick.date, shown: it.shown + 1 };
  }
  const replace = !e.day || e.day.date !== pick.date || e.day.need !== pick.need;
  return {
    day: replace ? { ...pick, rankVersion: dailyRankingWeights.version } : e.day,
    lastExtraOn: replace && pick.extra ? pick.date : e.lastExtraOn,
    items,
  };
}

/** What an answer on the personal screen or Home writes into the log (merged, no read needed). */
export function exposureAnswer(value: string, date: string): Partial<ExposureItem> {
  return {
    lastAnswered: date,
    ...(value === 'tried' || value === 'intend' ? { lastTried: date } : {}),
    ...(value === 'helpful' ? { lastHelpful: date, lastTried: date } : {}),
  };
}
