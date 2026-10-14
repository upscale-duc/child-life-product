import { z } from 'zod';
import { dayBoundsIn, type SummaryRecord } from './care.js';

/**
 * Nhịp lớn lên (Growing Rhythm), plan `docs/product/premium-personalization-plan.md` §5.4, brief
 * v2.0 p.12–13. Two layers that never mix: the **reference calendar** (a published, versioned model
 * counted from the due date; free) and **the baby's own rhythm** (what the family logged; facts,
 * never a diagnosis). Pure functions: the server and the app compute the same answers.
 */

// ---------- Dates (date-only, YYYY-MM-DD, in the baby's time zone) ----------

export function addDaysIso(date: string, days: number): string {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(y, m - 1, d + days)).toISOString().slice(0, 10);
}

export function daysBetweenIso(from: string, to: string): number {
  const ms = (s: string) => {
    const [y, m, d] = s.split('-').map(Number) as [number, number, number];
    return Date.UTC(y, m - 1, d);
  };
  return Math.round((ms(to) - ms(from)) / 86_400_000);
}

const isoDate = z.iso.date();
const localized = z.object({ vi: z.string().min(1).max(2000), en: z.string().min(1).max(2000) });
const localizedList = z.object({
  vi: z.array(z.string().min(1).max(400)).max(12),
  en: z.array(z.string().min(1).max(400)).max(12),
});

/** Who signed the content off; `null` = engineering draft, shown "chờ chuyên môn duyệt" (D-073 #2). */
export const contentReviewSchema = z
  .object({
    reviewer: z.string().min(1).max(120),
    credential: z.string().min(1).max(120),
    reviewedOn: isoDate,
  })
  .nullable();
export const contentSourceSchema = z.object({
  label: z.string().min(1).max(200),
  url: z.url().max(500),
});

// ---------- Due date (NL02b) ----------

/**
 * The due date lives with the date of birth in `babies/{b}/restricted/profile`. Estimated from the
 * gestational age at birth when the parent does not remember it; the UI keeps the "ước tính" label.
 * Never silently replaced by the birth date (brief p.13).
 */
export const dueDateSchema = z.object({
  date: isoDate,
  estimated: z.boolean(),
  /** Gestational age at birth, when the due date was estimated from it. */
  gestation: z
    .object({ weeks: z.number().int().min(22).max(44), days: z.number().int().min(0).max(6) })
    .nullable(),
});
export type DueDate = z.infer<typeof dueDateSchema>;

/** Due date = birth + (280 − gestational age in days). */
export function estimateDueDate(birthDate: string, weeks: number, days: number): string {
  return addDaysIso(birthDate, 280 - (weeks * 7 + days));
}

export const setDueDateRequestSchema = z.object({
  babyId: z.string().min(1).max(128),
  /** `null` clears it: the calendar goes back to "chưa thiết lập". */
  dueDate: dueDateSchema.nullable(),
});

// ---------- Reference calendar (NL03, NL04; PN01, PN02) ----------

export const referenceStageSchema = z
  .object({
    id: z.string().regex(/^[a-z0-9_-]{2,40}$/),
    number: z.number().int().min(1).max(30),
    /** Days after the due date, inclusive on both ends. */
    startOffsetDays: z.number().int().min(0).max(1200),
    endOffsetDays: z.number().int().min(0).max(1200),
    name: localized,
    /** "Dấu hiệu có thể gặp": possible, never certain ("một số bé không có thay đổi rõ"). */
    signs: localizedList,
    /** "Kỹ năng tham khảo theo tuổi": not required to match the window. */
    skills: localizedList,
    /** Linked activities (`content_activities`). */
    activityIds: z.array(z.string().min(1).max(60)).max(8),
    /** Optional reminder before the window (≤40 / ≤90 characters, PN02). */
    notice: z.object({ title: localized, body: localized }).nullable(),
  })
  .refine((s) => s.endOffsetDays >= s.startOffsetDays, 'Window ends before it starts');
export type ReferenceStage = z.infer<typeof referenceStageSchema>;

/** `publicConfig/rhythm_reference` (PN01): one published version at a time, rollback-able. */
export const referenceModelSchema = z.object({
  version: z.string().regex(/^ref_\d{8}_\d{2}$/),
  /** Label combining both (D-072 #7), e.g. "Wonder Weeks": shown as a reference, not a partner. */
  label: z.string().min(1).max(60),
  stages: z.array(referenceStageSchema).min(1).max(30),
  sources: z.array(contentSourceSchema).max(10),
  review: contentReviewSchema,
  publishedAt: z.string().nullable(),
});
export type ReferenceModel = z.infer<typeof referenceModelSchema>;

export type CalendarState =
  'unset' | 'upcoming' | 'in_reference_window' | 'completed_reference_range';

/** One stage's window: due date + offsets, inclusive, date-only (C01–C06). */
export function stageWindow(
  dueDate: string,
  stage: Pick<ReferenceStage, 'startOffsetDays' | 'endOffsetDays'>,
): { start: string; end: string } {
  return {
    start: addDaysIso(dueDate, stage.startOffsetDays),
    end: addDaysIso(dueDate, stage.endOffsetDays),
  };
}

export function calendarState(
  dueDate: string | null,
  today: string,
  stage: Pick<ReferenceStage, 'startOffsetDays' | 'endOffsetDays'>,
): CalendarState {
  if (!dueDate) return 'unset';
  const w = stageWindow(dueDate, stage);
  if (today < w.start) return 'upcoming';
  return today <= w.end ? 'in_reference_window' : 'completed_reference_range';
}

/** The stages whose windows hold [today] (overlapping windows show both, brief p.13), else the next. */
export function currentStages(
  dueDate: string | null,
  today: string,
  stages: readonly ReferenceStage[],
): { current: ReferenceStage[]; next: ReferenceStage | null } {
  if (!dueDate) return { current: [], next: null };
  const sorted = [...stages].sort((a, b) => a.startOffsetDays - b.startOffsetDays);
  return {
    current: sorted.filter((s) => calendarState(dueDate, today, s) === 'in_reference_window'),
    next: sorted.find((s) => calendarState(dueDate, today, s) === 'upcoming') ?? null,
  };
}

// ---------- Valid days, automatic (D-073 #1) ----------

/** Versioned thresholds (`config/rhythm.rules`), not clinical norms. */
export const rhythmRulesSchema = z.object({
  version: z.string().min(1).max(40),
  /** A day with a longer stretch without any logged care is not counted (sparse). */
  maxGapMinutes: z.number().int().min(60).max(1440),
  /** A point record (feed, diaper) counts as care for this long around it. */
  pointCoverMinutes: z.number().int().min(0).max(240),
  baselineMinDays: z.number().int().min(1).max(14),
  baselineMaxDays: z.number().int().min(1).max(14),
  baselineLookbackDays: z.number().int().min(1).max(28),
  recentDays: z.number().int().min(1).max(7),
  recentMinDays: z.number().int().min(1).max(7),
  /** |delta| ≥ max(minDeltaMinutes, minDeltaShare × baseline). */
  minDeltaMinutes: z.number().int().min(0).max(600),
  minDeltaShare: z.number().min(0).max(1),
  /** Recent valid days beyond the threshold in the same direction. */
  minSameDirectionDays: z.number().int().min(1).max(7),
  /** "Không lặp cùng bài trong N ngày" (PN04). */
  cooldownDays: z.number().int().min(0).max(30),
});
export type RhythmRules = z.infer<typeof rhythmRulesSchema>;

export const defaultRhythmRules: RhythmRules = {
  version: 'rules-v1-draft',
  maxGapMinutes: 360,
  pointCoverMinutes: 30,
  baselineMinDays: 5,
  baselineMaxDays: 7,
  baselineLookbackDays: 14,
  recentDays: 3,
  recentMinDays: 2,
  minDeltaMinutes: 60,
  minDeltaShare: 0.15,
  minSameDirectionDays: 2,
  cooldownDays: 3,
};

export type DayInvalidReason = 'not_finished' | 'open_timer' | 'overlap' | 'no_sleep' | 'sparse';

export interface DayQuality {
  date: string;
  valid: boolean;
  reasons: DayInvalidReason[];
  /** Logged sleep clipped to the day; reported for every day, used only when valid. */
  sleepMinutes: number;
  /** Longest stretch in the day without any logged care. */
  longestGapMinutes: number;
}

/**
 * Whether [date] counts toward the baseline, with no question to the parent (D-073 #1): finished,
 * no sleep timer still running from it, no unresolved overlap on it, at least one sleep record,
 * and no stretch longer than `maxGapMinutes` without logged care. Missing is never zero (brief p.12).
 */
export function dayQuality(input: {
  zone: string;
  date: string;
  now: Date;
  records: readonly Pick<SummaryRecord, 'type' | 'occurredAt' | 'endedAt'>[];
  /** Start of a sleep timer still running, if any. */
  openSleepTimerSince: Date | null;
  /** Unresolved overlap conflicts touching the day. */
  openConflicts: number;
  rules?: RhythmRules;
}): DayQuality {
  const rules = input.rules ?? defaultRhythmRules;
  const { start, end } = dayBoundsIn(input.zone, input.date);
  const s = start.getTime();
  const e = end.getTime();
  const reasons: DayInvalidReason[] = [];
  if (input.now.getTime() < e) reasons.push('not_finished');
  if (input.openSleepTimerSince && input.openSleepTimerSince.getTime() < e)
    reasons.push('open_timer');
  if (input.openConflicts > 0) reasons.push('overlap');

  const cover = rules.pointCoverMinutes * 60_000;
  const spans: [number, number][] = [];
  let sleepMs = 0;
  let sleeps = 0;
  for (const r of input.records) {
    const from = r.occurredAt.getTime();
    if (r.type === 'sleep') {
      if (!r.endedAt) continue;
      const a = Math.max(from, s);
      const b = Math.min(r.endedAt.getTime(), e);
      if (b <= a) continue;
      sleeps += 1;
      sleepMs += b - a;
      spans.push([a, b]);
    } else if (from >= s - cover && from < e + cover) {
      spans.push([Math.max(from - cover, s), Math.min(from + cover, e)]);
    }
  }
  if (sleeps === 0) reasons.push('no_sleep');
  spans.sort((x, y) => x[0] - y[0]);
  let cursor = s;
  let gap = 0;
  for (const [a, b] of spans) {
    if (a > cursor) gap = Math.max(gap, a - cursor);
    cursor = Math.max(cursor, b);
  }
  gap = Math.max(gap, e - cursor);
  const longestGapMinutes = Math.round(gap / 60_000);
  if (longestGapMinutes > rules.maxGapMinutes) reasons.push('sparse');
  return {
    date: input.date,
    valid: reasons.length === 0,
    reasons,
    sleepMinutes: Math.round(sleepMs / 60_000),
    longestGapMinutes,
  };
}

// ---------- Sleep baseline (B01–B06, brief p.12) ----------

export type BaselineResult =
  | { status: 'insufficient_data'; validBaselineDays: number; validRecentDays: number }
  | {
      status: 'change_detected' | 'no_change';
      baseline: number;
      recent: number;
      delta: number;
      threshold: number;
      validBaselineDays: number;
      validRecentDays: number;
    };

function median(values: readonly number[]): number {
  const v = [...values].sort((a, b) => a - b);
  const mid = Math.floor(v.length / 2);
  return v.length % 2 ? v[mid]! : (v[mid - 1]! + v[mid]!) / 2;
}

/**
 * Compares the recent window with the baseline. Arrays hold one value per completed day in each
 * window (disjoint), `null` for a day that is not valid. Thresholds are experimental config.
 */
export function sleepBaseline(
  baselineMinutes: readonly (number | null)[],
  recentMinutes: readonly (number | null)[],
  rules: RhythmRules = defaultRhythmRules,
): BaselineResult {
  const b = baselineMinutes.filter((v): v is number => v !== null);
  const r = recentMinutes.filter((v): v is number => v !== null);
  if (b.length < rules.baselineMinDays || r.length < rules.recentMinDays) {
    return { status: 'insufficient_data', validBaselineDays: b.length, validRecentDays: r.length };
  }
  const baseline = median(b);
  const recent = median(r);
  const delta = recent - baseline;
  const threshold = Math.max(rules.minDeltaMinutes, rules.minDeltaShare * baseline);
  const same = r.filter((v) =>
    delta < 0 ? v - baseline <= -threshold : delta > 0 ? v - baseline >= threshold : false,
  ).length;
  return {
    status:
      Math.abs(delta) >= threshold && same >= rules.minSameDirectionDays
        ? 'change_detected'
        : 'no_change',
    baseline,
    recent,
    delta,
    threshold,
    validBaselineDays: b.length,
    validRecentDays: r.length,
  };
}

/**
 * The two windows from per-day qualities (newest last): recent = the last `recentDays` completed
 * days before [today]; baseline = up to `baselineMaxDays` latest valid days in the
 * `baselineLookbackDays` before the recent window. Days missing from [days] count as invalid.
 */
export function sleepWindows(
  today: string,
  days: readonly DayQuality[],
  rules: RhythmRules = defaultRhythmRules,
): { baseline: (number | null)[]; recent: (number | null)[]; recentDates: string[] } {
  const byDate = new Map(days.map((d) => [d.date, d]));
  const value = (date: string) => {
    const d = byDate.get(date);
    return d?.valid ? d.sleepMinutes : null;
  };
  const recentDates = Array.from({ length: rules.recentDays }, (_, i) =>
    addDaysIso(today, -rules.recentDays + i),
  );
  const firstRecent = recentDates[0]!;
  const lookback = Array.from({ length: rules.baselineLookbackDays }, (_, i) =>
    addDaysIso(firstRecent, -rules.baselineLookbackDays + i),
  );
  const validBaseline = lookback.map(value).filter((v): v is number => v !== null);
  return {
    baseline: validBaseline.slice(-rules.baselineMaxDays),
    recent: recentDates.map(value),
    recentDates,
  };
}

// ---------- Check-in (C01, C02, NL05b) ----------

/** C01: one observation, never a default answer. */
export const observations = [
  'sleep',
  'feeding',
  'soothing',
  'new_skill',
  'usual',
  'health',
] as const;
export type Observation = (typeof observations)[number];

/** NL05b: signs that route to health support (HL01) before anything else; no paywall, no AI. */
export const healthSigns = [
  'fever_young',
  'breathing',
  'lethargic',
  'poor_feeding',
  'inconsolable',
  'lost_skill',
  'dehydration',
  'seizure',
] as const;
export type HealthSign = (typeof healthSigns)[number];

export const triedSoothing = [
  'rocking',
  'white_noise',
  'feeding',
  'skin_to_skin',
  'swaddle',
  'none',
] as const;

/**
 * `babies/{b}/checkins/{checkInId}`: written by the phone (offline-safe; the id is the
 * idempotency key), one per author per observation per day; edits bump `revision`.
 */
export const checkInSchema = z.object({
  id: z.string().regex(/^ci_[a-f0-9]{32}$/),
  babyId: z.string().min(1).max(128),
  /** Baby-local date the observation is about. */
  date: isoDate,
  authorUid: z.string().min(1).max(128),
  observation: z.enum(observations),
  /** C02, all optional ("Bỏ qua câu hỏi"). */
  when: z.enum(['night', 'day', 'both']).nullable(),
  since: z.enum(['today', 'days_2_3', 'longer']).nullable(),
  tried: z.array(z.enum(triedSoothing)).max(triedSoothing.length),
  /** NL05b answers: only the signs answered "Có". */
  healthSigns: z.array(z.enum(healthSigns)).max(healthSigns.length),
  /** Free text: untrusted data, never instructions (brief p.14). */
  note: z.string().max(500).nullable(),
  revision: z.number().int().min(1),
});
export type CheckIn = z.infer<typeof checkInSchema>;

export type ObservationState = 'normal' | 'reported_change' | 'mixed';

/** X01–X03: what a day's check-ins say together; both authors are kept (brief p.12). */
export function observationState(
  rows: readonly { state: 'normal' | 'changed' }[],
): ObservationState {
  const normal = rows.some((r) => r.state === 'normal');
  const changed = rows.some((r) => r.state === 'changed');
  return normal && changed ? 'mixed' : changed ? 'reported_change' : 'normal';
}

export function checkInState(c: Pick<CheckIn, 'observation'>): 'normal' | 'changed' {
  return c.observation === 'usual' ? 'normal' : 'changed';
}

/** The health route wins over everything (brief p.11 #1, p.13). */
export function needsHealthSupport(c: Pick<CheckIn, 'observation' | 'healthSigns'>): boolean {
  return c.healthSigns.length > 0;
}

/**
 * NL07b: suggest grouping into an observation episode when ≥2 of the last 3 days with updates
 * report a change. Only a suggestion: parents confirm; silence never ends an episode.
 */
export function suggestEpisode(
  days: readonly { date: string; state: ObservationState }[],
): boolean {
  const lastThree = [...days].sort((a, b) => a.date.localeCompare(b.date)).slice(-3);
  return lastThree.filter((d) => d.state !== 'normal').length >= 2;
}
