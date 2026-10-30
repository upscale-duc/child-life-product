import { describe, expect, it } from 'vitest';
import {
  calendarState,
  currentStages,
  dayQuality,
  defaultRhythmRules,
  estimateDueDate,
  feedbackMemory,
  observationState,
  rankCandidates,
  recommend,
  sleepBaseline,
  sleepWindows,
  stageWindow,
  suggestEpisode,
  type Activity,
  type RankFlags,
  type ReferenceStage,
  cardAgeDays,
} from '../src/index.js';
import pack from './vectors/premium-v2.json' with { type: 'json' };

/**
 * Fixture pack v2.0 (`qa-policy-v2`, synthetic): baseline B01–B06, calendar C01–C06, ranking
 * R01–R06 and observations X01–X03 through the real functions. The calendar offsets 21/30 are
 * technical test values, never a published stage.
 */
type Case = { id: string; kind: string; input: Record<string, unknown>; expected: unknown };
const cases = (kind: string) => (pack.cases as Case[]).filter((c) => c.kind === kind);

describe('fixture pack · baseline B01–B06', () => {
  it.each(cases('baseline').map((c) => [c.id, c] as const))('%s', (_id, c) => {
    const x = c.input as { baseline_minutes: (number | null)[]; recent_minutes: (number | null)[] };
    const r = sleepBaseline(x.baseline_minutes, x.recent_minutes);
    const actual =
      r.status === 'insufficient_data'
        ? { status: r.status }
        : { status: r.status, baseline: r.baseline, recent: r.recent, delta: r.delta };
    expect(actual).toEqual(c.expected);
  });
});

describe('fixture pack · calendar C01–C06', () => {
  it.each(cases('calendar').map((c) => [c.id, c] as const))('%s', (_id, c) => {
    const x = c.input as {
      due_date: string | null;
      today: string;
      start_offset_days: number;
      end_offset_days: number;
    };
    expect(
      calendarState(x.due_date, x.today, {
        startOffsetDays: x.start_offset_days,
        endOffsetDays: x.end_offset_days,
      }),
    ).toBe(c.expected);
  });
});

describe('fixture pack · ranking R01–R06', () => {
  it.each(cases('ranking').map((c) => [c.id, c] as const))('%s', (_id, c) => {
    const x = c.input as { locale: string; candidates: RankFlags[] };
    expect(rankCandidates(x.locale, x.candidates)[0]?.id ?? null).toBe(c.expected);
  });
});

describe('fixture pack · observations X01–X03', () => {
  it.each(cases('observations').map((c) => [c.id, c] as const))('%s', (_id, c) => {
    const x = c.input as { rows: { state: 'normal' | 'changed' }[] };
    expect(observationState(x.rows)).toBe(c.expected);
  });
});

describe('calendar', () => {
  const stage = { startOffsetDays: 21, endOffsetDays: 30 };
  it('windows are inclusive date-only offsets from the due date', () => {
    expect(stageWindow('2026-09-21', stage)).toEqual({ start: '2026-10-12', end: '2026-10-21' });
  });
  it('overlapping windows show both; otherwise the next one', () => {
    const s = (id: string, a: number, b: number) =>
      ({ id, startOffsetDays: a, endOffsetDays: b }) as ReferenceStage;
    const stages = [s('a', 21, 30), s('b', 28, 40), s('c', 50, 60)];
    expect(currentStages('2026-09-21', '2026-10-20', stages).current.map((x) => x.id)).toEqual([
      'a',
      'b',
    ]);
    expect(currentStages('2026-09-21', '2026-10-05', stages).next?.id).toBe('a');
    expect(currentStages(null, '2026-10-05', stages)).toEqual({ current: [], next: null });
  });
  it('estimates the due date from gestational age at birth (NL02b)', () => {
    expect(estimateDueDate('2026-09-18', 39, 4)).toBe('2026-09-21');
    expect(estimateDueDate('2026-09-01', 40, 0)).toBe('2026-09-01');
  });
});

describe('valid days, automatic (D-073 #1)', () => {
  const zone = 'Asia/Ho_Chi_Minh';
  const at = (h: number, m = 0, day = 13) => new Date(Date.UTC(2026, 9, day, h - 7, m));
  const sleep = (a: Date, b: Date | null) => ({
    type: 'sleep' as const,
    occurredAt: a,
    endedAt: b,
  });
  const feed = (a: Date) => ({ type: 'bottle' as const, occurredAt: a, endedAt: null });
  const now = new Date('2026-10-15T00:00:00Z');
  const fullDay = [
    sleep(at(0, 0, 13), at(5, 0, 13)),
    feed(at(5, 30)),
    sleep(at(8), at(10)),
    feed(at(11)),
    feed(at(14)),
    sleep(at(15), at(16)),
    feed(at(18)),
    sleep(at(20), at(23, 59)),
  ];

  it('a well-logged finished day counts, with its sleep', () => {
    const q = dayQuality({
      zone,
      date: '2026-10-13',
      now,
      records: fullDay,
      openSleepTimerSince: null,
      openConflicts: 0,
    });
    expect(q).toMatchObject({ valid: true, reasons: [], sleepMinutes: 5 * 60 + 120 + 60 + 239 });
  });

  it('missing is not zero: sparse, no sleep, open timer, overlap or today do not count', () => {
    const base = { zone, date: '2026-10-13', now, openSleepTimerSince: null, openConflicts: 0 };
    expect(dayQuality({ ...base, records: [feed(at(9)), feed(at(18))] }).reasons).toEqual([
      'no_sleep',
      'sparse',
    ]);
    expect(dayQuality({ ...base, records: fullDay.slice(0, 4) }).reasons).toEqual(['sparse']);
    expect(dayQuality({ ...base, records: fullDay, openSleepTimerSince: at(21) }).reasons).toEqual([
      'open_timer',
    ]);
    expect(dayQuality({ ...base, records: fullDay, openConflicts: 1 }).reasons).toEqual([
      'overlap',
    ]);
    expect(dayQuality({ ...base, records: fullDay, now: at(22) }).reasons).toEqual([
      'not_finished',
    ]);
  });

  it('windows: 3 recent completed days, baseline from the 14 days before', () => {
    const days = Array.from({ length: 17 }, (_, i) => {
      const date = `2026-10-${String(i + 1).padStart(2, '0')}`;
      return { date, valid: i % 4 !== 0, reasons: [], sleepMinutes: 700 + i, longestGapMinutes: 0 };
    });
    const w = sleepWindows('2026-10-18', days);
    expect(w.recentDates).toEqual(['2026-10-15', '2026-10-16', '2026-10-17']);
    // 17 Oct is one of the invalid days in this series: null, never zero.
    expect(w.recent).toEqual([714, 715, null]);
    expect(w.baseline).toHaveLength(defaultRhythmRules.baselineMaxDays);
    expect(w.baseline.at(-1)).toBe(713);
  });
});

describe('episodes (NL07b)', () => {
  it('suggests grouping after two changed days among the last three with updates', () => {
    expect(
      suggestEpisode([
        { date: '2026-10-06', state: 'reported_change' },
        { date: '2026-10-07', state: 'normal' },
        { date: '2026-10-08', state: 'mixed' },
      ]),
    ).toBe(true);
    expect(suggestEpisode([{ date: '2026-10-08', state: 'reported_change' }])).toBe(false);
  });
});

describe('recommend (H02, PS01, AC02 → PS02)', () => {
  const act = (id: string, over: Partial<Activity> = {}): Activity => ({
    id,
    version: 1,
    status: 'published',
    title: { vi: id, en: id },
    summary: { vi: id, en: id },
    steps: { vi: ['x'], en: ['x'] },
    safety: null,
    durationMin: 10,
    ageDays: { from: 0, to: 90 },
    needs: ['sleep'],
    interests: ['sleep'],
    timeOfDay: 'evening',
    locales: ['vi', 'en'],
    regions: [],
    sources: [],
    review: null,
    ...over,
  });
  const base = {
    locale: 'vi' as const,
    today: '2026-10-09',
    ageDays: 21,
    need: 'sleep' as const,
    interests: [],
    fewer: [],
    country: 'VN',
    healthFlag: false,
    memory: feedbackMemory([], 3),
    activities: [
      act('act_wind_down'),
      act('act_skin_to_skin'),
      act('act_play', { needs: ['play'] }),
    ],
  };

  it('health always wins, before any content', () => {
    expect(recommend({ ...base, healthFlag: true })).toEqual({ kind: 'health' });
  });

  it('first visit: the need picks, ties by id; the reason is what the family reported', () => {
    const r = recommend(base);
    expect(r).toMatchObject({ kind: 'suggestion', reasonCode: 'SELF_REPORTED_NEED', changes: [] });
    expect(r.kind === 'suggestion' && r.primary.id).toBe('act_skin_to_skin');
  });

  it('feedback changes the next visit: helpful leads, not suitable is gone, not today cools down', () => {
    const memory = feedbackMemory(
      [
        { contentId: 'act_skin_to_skin', kind: 'not_suitable', date: '2026-10-08' },
        { contentId: 'act_wind_down', kind: 'started', date: '2026-10-05' },
        { contentId: 'act_wind_down', kind: 'helpful', date: '2026-10-05' },
      ],
      3,
    );
    const r = recommend({ ...base, memory });
    expect(r).toMatchObject({
      kind: 'suggestion',
      reasonCode: 'PREVIOUS_HELPFUL',
      changes: ['prefers_helpful', 'excluded_not_suitable'],
    });
    expect(r.kind === 'suggestion' && r.primary.id).toBe('act_wind_down');

    const later = feedbackMemory(
      [{ contentId: 'act_wind_down', kind: 'not_today', date: '2026-10-09' }],
      3,
    );
    const r2 = recommend({ ...base, memory: later, activities: [act('act_wind_down')] });
    expect(r2).toEqual({ kind: 'none' });
    expect(
      recommend({ ...base, today: '2026-10-12', memory: later, activities: [act('act_wind_down')] })
        .kind,
    ).toBe('suggestion');
  });

  it('tried, then helpful: it leads again the next day (PS02), not pushed down as recently shown', () => {
    const memory = feedbackMemory(
      [
        { contentId: 'act_wind_down', kind: 'started', date: '2026-10-08' },
        { contentId: 'act_wind_down', kind: 'helpful', date: '2026-10-08' },
      ],
      3,
    );
    const r = recommend({ ...base, memory });
    expect(r.kind === 'suggestion' && r.primary.id).toBe('act_wind_down');
    expect(r).toMatchObject({ reasonCode: 'PREVIOUS_HELPFUL', changes: ['prefers_helpful'] });
  });

  it('without a need, INTEREST only when the pick matches a chosen interest (P-172 audit P2 #7)', () => {
    const activities = [act('act_a'), act('act_b', { interests: ['milestones'] })];
    expect(recommend({ ...base, need: null, activities })).toMatchObject({
      reasonCode: 'AGE_CONTENT',
    });
    const r = recommend({ ...base, need: null, activities, interests: ['milestones'] });
    expect(r.kind === 'suggestion' && r.primary.id).toBe('act_b');
    expect(r).toMatchObject({ reasonCode: 'INTEREST' });
  });

  it('drafts, the wrong locale, age or region are never offered', () => {
    expect(recommend({ ...base, activities: [act('act_a', { status: 'draft' })] }).kind).toBe(
      'none',
    );
    expect(recommend({ ...base, activities: [act('act_a', { locales: ['en'] })] }).kind).toBe(
      'none',
    );
    expect(recommend({ ...base, ageDays: 200 }).kind).toBe('none');
    expect(recommend({ ...base, activities: [act('act_a', { regions: ['SG'] })] }).kind).toBe(
      'none',
    );
  });
});

describe('cardAgeDays (expert review 2026-10-30, D3; same cases as the app)', () => {
  it('preterm (6 weeks early): the corrected age', () => {
    expect(cardAgeDays('2026-01-01', '2026-02-12', '2026-04-01')).toBe(90 - 42);
    expect(cardAgeDays('2026-01-01', '2026-02-12', '2026-01-20')).toBe(0);
  });
  it('2 weeks early, no due date, or past 24 months: the actual age', () => {
    expect(cardAgeDays('2026-01-01', '2026-01-15', '2026-04-01')).toBe(90);
    expect(cardAgeDays('2026-01-01', null, '2026-04-01')).toBe(90);
    expect(cardAgeDays('2026-01-01', '2026-02-12', '2028-01-02')).toBe(731);
  });
});
