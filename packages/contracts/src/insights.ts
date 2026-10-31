import { z } from 'zod';
import { localDateIn } from './baby.js';
import { careNightWindow, dayBoundsIn, type CareType } from './care.js';
import { addDaysIso, daysBetweenIso } from './rhythm.js';

/**
 * Hiểu con · "Điều đáng chú ý" (D-150 Premium, D-151; analysis
 * `docs/product/hieu-con-insights-analysis.md` §4). Deterministic: the numbers come from the
 * records, never from a model; a rule decides when a change is worth saying; Lumi only words it.
 * Pure (no I/O) so every rule is tested with tables; the server computes and stores the result in
 * `babies/{b}/insights/current` (`firebase/functions/src/insights.ts`).
 *
 * P1 catalogue (analysis §4.4): S1 `night_longest`, S2 `night_total`, F3 `night_feeds`.
 */

export const insightRuleVersion = 1;

export const insightKinds = ['night_longest', 'night_total', 'night_feeds'] as const;
export type InsightKind = (typeof insightKinds)[number];

/** Why a night is not counted ("không có ghi nhận" is never "không ngủ"). */
export const nightExclusions = ['not_ended', 'timer_open', 'overlap', 'no_sleep', 'gap'] as const;
export type NightExclusion = (typeof nightExclusions)[number];

/** Starting values (analysis §4.2); server config `config/insights` may override any of them. */
export const insightRulesSchema = z.object({
  /** Nights in "gần đây"; the baseline is the same number of nights just before. */
  windowNights: z.number().int().min(3).max(14),
  /** Valid nights needed in each window before anything is compared. */
  minValidNights: z.number().int().min(2).max(14),
  /** Longest stretch of a night with nothing logged (edges included) that still counts. */
  maxUncoveredMinutes: z.number().int().min(60).max(720),
  /** Minutes a point record (feed, diaper) covers on each side. */
  pointCoverMinutes: z.number().int().min(0).max(120),
  /** Recent nights that must sit on the side of the change against the baseline mean. */
  sameDirectionNights: z.number().int().min(1).max(14),
  /** Days before the same kind may lead Hôm nay again. */
  cooldownDays: z.number().int().min(1).max(60),
  /** Days the Free invite waits before another one (D-151 #9: at most once a week). */
  teaserCooldownDays: z.number().int().min(1).max(60),
  /** Corrected age below which S1 "longer" and F3 "fewer" never reach Hôm nay (D-151 #5). */
  youngAgeDays: z.number().int().min(0).max(365),
  minDelta: z.object({
    night_longest: z.number().min(1),
    night_total: z.number().min(1),
    night_feeds: z.number().min(0.1),
  }),
});
export type InsightRules = z.infer<typeof insightRulesSchema>;

export const defaultInsightRules: InsightRules = {
  windowNights: 7,
  minValidNights: 5,
  maxUncoveredMinutes: 240,
  pointCoverMinutes: 30,
  sameDirectionNights: 3,
  cooldownDays: 7,
  teaserCooldownDays: 7,
  youngAgeDays: 42,
  minDelta: { night_longest: 20, night_total: 30, night_feeds: 1 },
};

/** `config/insights` merged over the defaults; a broken document falls back to the defaults. */
export function insightRulesFrom(raw: unknown): InsightRules {
  const merged =
    raw && typeof raw === 'object'
      ? {
          ...defaultInsightRules,
          ...(raw as Record<string, unknown>),
          minDelta: {
            ...defaultInsightRules.minDelta,
            ...((raw as { minDelta?: object }).minDelta ?? {}),
          },
        }
      : defaultInsightRules;
  const parsed = insightRulesSchema.safeParse(merged);
  return parsed.success ? parsed.data : defaultInsightRules;
}

// ---------- Nights ----------

/** The instant of [hour]:00 on [date] in [zone] (daylight-saving safe). */
function localInstant(zone: string, date: string, hour: number): Date {
  let guess = dayBoundsIn(zone, date).start.getTime() + hour * 3_600_000;
  // Across a clock change the day is 23 or 25 h long: walk back to the wanted wall time.
  for (let i = 0; i < 3; i += 1) {
    const parts = new Intl.DateTimeFormat('en-GB', {
      timeZone: zone,
      hour: 'numeric',
      minute: 'numeric',
      hourCycle: 'h23',
    }).formatToParts(new Date(guess));
    const get = (t: string) => Number(parts.find((p) => p.type === t)?.value ?? 0);
    let diff = hour * 60 - (get('hour') * 60 + get('minute'));
    if (diff > 720) diff -= 1440;
    if (diff < -720) diff += 1440;
    if (diff === 0) break;
    guess += diff * 60_000;
  }
  return new Date(guess);
}

/** Night [date] = [date 18:00, date+1 06:00) in the baby's zone (`careNightWindow`). */
export function nightBoundsIn(zone: string, date: string): { start: Date; end: Date } {
  return {
    start: localInstant(zone, date, careNightWindow.fromHour),
    end: localInstant(zone, addDaysIso(date, 1), careNightWindow.toHour),
  };
}

/** The latest night that has ended at [now]. */
export function lastEndedNight(zone: string, now: Date): string {
  const today = localDateIn(zone, now);
  const yesterday = addDaysIso(today, -1);
  return now >= nightBoundsIn(zone, yesterday).end ? yesterday : addDaysIso(today, -2);
}

export interface InsightRecord {
  id: string;
  type: CareType;
  occurredAt: Date;
  endedAt: Date | null;
  data: Record<string, unknown>;
  /** Frozen when logged (D-024); null on very old records. */
  author: { name: string; relation: string | null } | null;
}

export interface NightFacts {
  date: string;
  valid: boolean;
  reason: NightExclusion | null;
  /** Longest single sleep that started in the night (its whole length, also past 06:00). */
  longestMinutes: number | null;
  longestStartedAt: Date | null;
  /** Finished sleep clipped to the night. */
  totalMinutes: number | null;
  /** Bottle and breast feeds started in the night. */
  feeds: number | null;
  /** Records that made the night: the authors of the evidence. */
  recordIds: string[];
}

export interface NightInput {
  zone: string;
  date: string;
  now: Date;
  records: readonly InsightRecord[];
  /** Start of a running sleep timer, if any. */
  openSleepTimerSince: Date | null;
  /** Records named by an open overlap (`babies/{b}/conflicts`). */
  conflictRecordIds: ReadonlySet<string>;
  rules: InsightRules;
}

const MIN = 60_000;
const feedTypes: readonly CareType[] = ['bottle', 'breast'];
const pointTypes: readonly CareType[] = ['bottle', 'breast', 'diaper', 'pump'];

export function nightFacts(x: NightInput): NightFacts {
  const { start, end } = nightBoundsIn(x.zone, x.date);
  const s = start.getTime();
  const e = end.getTime();
  const out = (reason: NightExclusion, recordIds: string[] = []): NightFacts => ({
    date: x.date,
    valid: false,
    reason,
    longestMinutes: null,
    longestStartedAt: null,
    totalMinutes: null,
    feeds: null,
    recordIds,
  });
  if (x.now.getTime() < e) return out('not_ended');
  if (x.openSleepTimerSince && x.openSleepTimerSince.getTime() < e) return out('timer_open');

  const sleeps = x.records.filter(
    (r) =>
      r.type === 'sleep' &&
      r.endedAt !== null &&
      r.occurredAt.getTime() < e &&
      r.endedAt.getTime() > s,
  );
  const points = x.records.filter((r) => {
    const t = r.occurredAt.getTime();
    return pointTypes.includes(r.type) && t >= s && t < e;
  });
  const touching = [...sleeps, ...points];
  const ids = touching.map((r) => r.id);
  if (touching.some((r) => x.conflictRecordIds.has(r.id))) return out('overlap', ids);

  const started = sleeps.filter((r) => r.occurredAt.getTime() >= s);
  if (started.length === 0) return out('no_sleep', ids);

  // Coverage: sleeps as spans, point records ± cover (a breastfeed also over its length).
  const cover = x.rules.pointCoverMinutes * MIN;
  const spans: [number, number][] = [
    ...sleeps.map((r): [number, number] => [r.occurredAt.getTime(), r.endedAt!.getTime()]),
    ...points.map((r): [number, number] => {
      const t = r.occurredAt.getTime();
      const len = typeof r.data.durationMin === 'number' ? r.data.durationMin * MIN : 0;
      return [t - cover, t + len + cover];
    }),
  ]
    .map(([a, b]): [number, number] => [Math.max(a, s), Math.min(b, e)])
    .filter(([a, b]) => b > a)
    .sort((p, q) => p[0] - q[0]);
  let cursor = s;
  let widest = 0;
  for (const [a, b] of spans) {
    widest = Math.max(widest, a - cursor);
    cursor = Math.max(cursor, b);
  }
  widest = Math.max(widest, e - cursor);
  if (widest > x.rules.maxUncoveredMinutes * MIN) return out('gap', ids);

  let longest = started[0]!;
  for (const r of started) {
    const len = r.endedAt!.getTime() - r.occurredAt.getTime();
    if (len > longest.endedAt!.getTime() - longest.occurredAt.getTime()) longest = r;
  }
  const total = sleeps.reduce(
    (sum, r) => sum + (Math.min(r.endedAt!.getTime(), e) - Math.max(r.occurredAt.getTime(), s)),
    0,
  );
  return {
    date: x.date,
    valid: true,
    reason: null,
    longestMinutes: Math.round((longest.endedAt!.getTime() - longest.occurredAt.getTime()) / MIN),
    longestStartedAt: longest.occurredAt,
    totalMinutes: Math.round(total / MIN),
    feeds: points.filter((r) => feedTypes.includes(r.type)).length,
    recordIds: ids,
  };
}

// ---------- Insights ----------

export const insightPointSchema = z.object({
  date: z.iso.date(),
  value: z.number().nullable(),
  reason: z.enum(nightExclusions).nullable(),
});

const windowSchema = z.object({ from: z.iso.date(), to: z.iso.date() });

export const insightSchema = z.object({
  kind: z.enum(insightKinds),
  direction: z.enum(['up', 'down']),
  unit: z.enum(['minutes', 'count']),
  /** Mean over the valid recent nights (minutes, or feeds a night to one decimal). */
  value: z.number(),
  baselineValue: z.number(),
  delta: z.number(),
  recent: windowSchema,
  baseline: windowSchema,
  coverage: z.object({ valid: z.number().int(), total: z.number().int() }),
  baselineCoverage: z.object({ valid: z.number().int(), total: z.number().int() }),
  /** Baseline nights first, then recent; null with the reason when a night is not counted. */
  points: z.array(insightPointSchema).max(28),
  /** S1: the longest night of the recent window ("Dài nhất là đêm 23/10: 3 giờ 05, từ 22:40"). */
  peak: z
    .object({ date: z.iso.date(), value: z.number(), startedAt: z.iso.datetime().nullable() })
    .nullable(),
  /** Who logged the recent nights (names as frozen on the records), never ranked (D-151 #6). */
  authors: z
    .array(z.object({ name: z.string().max(80), relation: z.string().max(40).nullable() }))
    .max(8),
  /** False when the age guard keeps it off Hôm nay (D-151 #5). */
  todayEligible: z.boolean(),
  score: z.number(),
});
export type Insight = z.infer<typeof insightSchema>;

export type InsightOutcome =
  | { kind: InsightKind; status: 'insight'; insight: Insight }
  | { kind: InsightKind; status: 'none' }
  | { kind: InsightKind; status: 'insufficient'; validRecent: number; validBaseline: number };

const metricOf: Record<InsightKind, (n: NightFacts) => number | null> = {
  night_longest: (n) => n.longestMinutes,
  night_total: (n) => n.totalMinutes,
  night_feeds: (n) => n.feeds,
};
const unitOf: Record<InsightKind, Insight['unit']> = {
  night_longest: 'minutes',
  night_total: 'minutes',
  night_feeds: 'count',
};
/** Sleep first (analysis §4.3). */
const priorityOf: Record<InsightKind, number> = {
  night_longest: 1,
  night_total: 0.9,
  night_feeds: 0.8,
};

const mean = (v: readonly number[]) => v.reduce((a, b) => a + b, 0) / v.length;
const round = (v: number, unit: Insight['unit']) =>
  unit === 'minutes' ? Math.round(v) : Math.round(v * 10) / 10;

export interface CompareInput {
  kind: InsightKind;
  baseline: readonly NightFacts[];
  recent: readonly NightFacts[];
  records: readonly InsightRecord[];
  /** Corrected age in days (D-141 #1), null when unknown. */
  ageDays: number | null;
  rules: InsightRules;
}

/** One kind over the two windows: an insight, nothing worth saying, or not enough nights yet. */
export function compareNights(x: CompareInput): InsightOutcome {
  const metric = metricOf[x.kind];
  const values = (nights: readonly NightFacts[]) =>
    nights.filter((n) => n.valid && metric(n) !== null).map((n) => metric(n)!);
  const r = values(x.recent);
  const b = values(x.baseline);
  const need = x.rules.minValidNights;
  if (r.length < need || b.length < need)
    return { kind: x.kind, status: 'insufficient', validRecent: r.length, validBaseline: b.length };

  const unit = unitOf[x.kind];
  const value = round(mean(r), unit);
  const baselineValue = round(mean(b), unit);
  const delta = round(value - baselineValue, unit);
  const minDelta = x.rules.minDelta[x.kind];
  if (Math.abs(delta) < minDelta || delta === 0) return { kind: x.kind, status: 'none' };
  const up = delta > 0;
  const baseMean = mean(b);
  const sameSide = r.filter((v) => (up ? v > baseMean : v < baseMean)).length;
  if (sameSide < x.rules.sameDirectionNights) return { kind: x.kind, status: 'none' };

  const young = x.ageDays !== null && x.ageDays < x.rules.youngAgeDays;
  const guarded =
    young && ((x.kind === 'night_longest' && up) || (x.kind === 'night_feeds' && !up));
  const point = (n: NightFacts) => ({
    date: n.date,
    value: n.valid ? metric(n) : null,
    reason: n.reason,
  });
  const validRecent = x.recent.filter((n) => n.valid);
  let peak: Insight['peak'] = null;
  if (x.kind === 'night_longest') {
    for (const n of validRecent)
      if (n.longestMinutes !== null && (peak === null || n.longestMinutes > peak.value))
        peak = {
          date: n.date,
          value: n.longestMinutes,
          startedAt: n.longestStartedAt?.toISOString() ?? null,
        };
  }
  const evidence = new Set(validRecent.flatMap((n) => n.recordIds));
  const authors: Insight['authors'] = [];
  for (const rec of x.records) {
    if (!evidence.has(rec.id) || !rec.author) continue;
    if (authors.some((a) => a.name === rec.author!.name)) continue;
    if (authors.length < 8) authors.push({ name: rec.author.name, relation: rec.author.relation });
  }
  const recentDates = x.recent.map((n) => n.date);
  const baselineDates = x.baseline.map((n) => n.date);
  return {
    kind: x.kind,
    status: 'insight',
    insight: {
      kind: x.kind,
      direction: up ? 'up' : 'down',
      unit,
      value,
      baselineValue,
      delta,
      recent: { from: recentDates[0]!, to: recentDates[recentDates.length - 1]! },
      baseline: { from: baselineDates[0]!, to: baselineDates[baselineDates.length - 1]! },
      coverage: { valid: r.length, total: x.recent.length },
      baselineCoverage: { valid: b.length, total: x.baseline.length },
      points: [...x.baseline.map(point), ...x.recent.map(point)],
      peak,
      authors,
      todayEligible: !guarded,
      score:
        Math.min(Math.abs(delta) / minDelta, 3) * (r.length / x.recent.length) * priorityOf[x.kind],
    },
  };
}

export interface InsightInput {
  zone: string;
  now: Date;
  records: readonly InsightRecord[];
  openSleepTimerSince: Date | null;
  conflictRecordIds: ReadonlySet<string>;
  ageDays: number | null;
  rules: InsightRules;
}

export interface InsightComputation {
  /** The window read: baseline's first night to recent's last. */
  from: string;
  to: string;
  /** Instants the records must cover (a sleep starting up to a day earlier can overlap). */
  readFrom: Date;
  readTo: Date;
  outcomes: InsightOutcome[];
  /** "Chưa đủ ngày" progress (AI04): valid recent nights against what is needed. */
  progress: { validNights: number; neededNights: number };
}

/** The two windows for [now]: baseline nights then recent nights, oldest first. */
export function insightWindows(zone: string, now: Date, rules: InsightRules) {
  const last = lastEndedNight(zone, now);
  const n = rules.windowNights;
  const dates = Array.from({ length: n * 2 }, (_, i) => addDaysIso(last, i - n * 2 + 1));
  return { baseline: dates.slice(0, n), recent: dates.slice(n) };
}

export function computeInsights(x: InsightInput): InsightComputation {
  const w = insightWindows(x.zone, x.now, x.rules);
  const facts = (date: string) =>
    nightFacts({
      zone: x.zone,
      date,
      now: x.now,
      records: x.records,
      openSleepTimerSince: x.openSleepTimerSince,
      conflictRecordIds: x.conflictRecordIds,
      rules: x.rules,
    });
  const baseline = w.baseline.map(facts);
  const recent = w.recent.map(facts);
  const outcomes = insightKinds
    .map((kind) =>
      compareNights({
        kind,
        baseline,
        recent,
        records: x.records,
        ageDays: x.ageDays,
        rules: x.rules,
      }),
    )
    .sort(
      (a, b) =>
        (b.status === 'insight' ? b.insight.score : -1) -
        (a.status === 'insight' ? a.insight.score : -1),
    );
  const first = w.baseline[0]!;
  const last = w.recent[w.recent.length - 1]!;
  return {
    from: first,
    to: last,
    readFrom: new Date(nightBoundsIn(x.zone, first).start.getTime() - 24 * 3_600_000),
    readTo: nightBoundsIn(x.zone, last).end,
    outcomes,
    progress: {
      validNights: recent.filter((n) => n.valid).length,
      neededNights: x.rules.minValidNights,
    },
  };
}

// ---------- What is shown (cooldown, Hôm nay, Free invite) ----------

/** `babies/{b}/insights/current`, written by the server only. */
export interface InsightState {
  ruleVersion: number;
  computedAt: Date;
  /** First instant of the baseline: the app hides the card once a record from here on changes. */
  windowStart: Date;
  /** End of the last night counted (06:00): records from here on do not touch the figures. */
  windowEnd: Date;
  from: string;
  to: string;
  /** False for a Free household: `items` is empty and only `teaser` names a kind (D-151 #9). */
  premium: boolean;
  items: Insight[];
  progress: { validNights: number; neededNights: number };
  /** The one insight for Hôm nay today (D-151 #4), or null. */
  today: InsightKind | null;
  todayOn: string | null;
  /** Free: the kind the invite names, shown at most once a teaser cooldown. */
  teaser: { kind: InsightKind; direction: 'up' | 'down' } | null;
  teaserOn: string | null;
  /** Last day each kind led Hôm nay (cooldown). */
  lastTodayOn: Partial<Record<InsightKind, string>>;
}

export interface ShowInput {
  computation: InsightComputation;
  previous: Pick<InsightState, 'today' | 'todayOn' | 'teaser' | 'teaserOn' | 'lastTodayOn'> | null;
  premium: boolean;
  /** Baby-local date of now. */
  today: string;
  rules: InsightRules;
}

export type InsightShown = Pick<
  InsightState,
  'premium' | 'items' | 'progress' | 'today' | 'todayOn' | 'teaser' | 'teaserOn' | 'lastTodayOn'
>;

/** Applies the per-kind cooldown and the one-a-day rule; Free gets the kind only. */
export function chooseShown(x: ShowInput): InsightShown {
  const items = x.computation.outcomes.flatMap((o) => (o.status === 'insight' ? [o.insight] : []));
  const lastTodayOn = { ...(x.previous?.lastTodayOn ?? {}) };
  const eligible = items.filter((i) => i.todayEligible);
  let today: InsightKind | null = null;
  // Keep today's pick for the rest of the day while it still holds.
  if (x.previous?.todayOn === x.today && x.previous.today)
    today = eligible.some((i) => i.kind === x.previous!.today) ? x.previous.today : null;
  else {
    const rested = eligible.find((i) => {
      const last = lastTodayOn[i.kind];
      return !last || daysBetweenIso(last, x.today) >= x.rules.cooldownDays;
    });
    if (rested) {
      today = rested.kind;
      lastTodayOn[rested.kind] = x.today;
    }
  }
  const todayOn = today ? x.today : (x.previous?.todayOn ?? null);

  let teaser: InsightShown['teaser'] = null;
  let teaserOn = x.previous?.teaserOn ?? null;
  if (!x.premium) {
    const picked = today ? items.find((i) => i.kind === today)! : null;
    if (teaserOn === x.today && x.previous?.teaser)
      teaser = items.some((i) => i.kind === x.previous!.teaser!.kind) ? x.previous.teaser : null;
    else if (
      picked &&
      (!teaserOn || daysBetweenIso(teaserOn, x.today) >= x.rules.teaserCooldownDays)
    ) {
      teaser = { kind: picked.kind, direction: picked.direction };
      teaserOn = x.today;
    }
  }
  return {
    premium: x.premium,
    // Figures never leave the server for a Free household (D-151 #9).
    items: x.premium ? items : [],
    progress: x.computation.progress,
    today: x.premium ? today : null,
    todayOn,
    teaser,
    teaserOn,
    lastTodayOn,
  };
}
