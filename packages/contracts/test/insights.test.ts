import { describe, expect, it } from 'vitest';
import {
  chooseShown,
  computeInsights,
  defaultInsightRules,
  insightRulesFrom,
  insightSchema,
  lastEndedNight,
  nightBoundsIn,
  nightFacts,
  type InsightRecord,
} from '../src/index.js';

/**
 * Hiểu con P1 (D-150, D-151; analysis §4): synthetic logs only. Viet Nam is UTC+7 all year;
 * Berlin moves its clocks back on 25 Oct 2026, which makes that night 13 h long.
 */
const VN = 'Asia/Ho_Chi_Minh';
const rules = defaultInsightRules;
const at = (date: string, hhmm: string) => new Date(`${date}T${hhmm}:00+07:00`);
const day = (base: string, offset: number) => {
  const [y, m, d] = base.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(y, m - 1, d + offset)).toISOString().slice(0, 10);
};

let seq = 0;
const sleep = (date: string, from: string, minutes: number, by = 'Mẹ'): InsightRecord => {
  const start = at(date, from);
  return {
    id: `s${(seq += 1)}`,
    type: 'sleep',
    occurredAt: start,
    endedAt: new Date(start.getTime() + minutes * 60_000),
    data: {},
    author: { name: by, relation: by === 'Mẹ' ? 'mother' : 'father' },
  };
};
const bottle = (date: string, hhmm: string): InsightRecord => ({
  id: `b${(seq += 1)}`,
  type: 'bottle',
  occurredAt: at(date, hhmm),
  endedAt: null,
  data: { amountMl: 90 },
  author: { name: 'Ba', relation: 'father' },
});

/**
 * One logged night starting on [date]: asleep 20:00 for [first] min, then shorter sleeps until
 * 06:00, [feeds] of them after a bottle — a real diary shape with no uncovered stretch.
 */
function night(date: string, first: number, feeds = 1, by = 'Mẹ'): InsightRecord[] {
  const end = at(day(date, 1), '06:00').getTime();
  const rows: InsightRecord[] = [sleep(date, '20:00', first, by)];
  let cursor = at(date, '20:00').getTime() + first * 60_000;
  let left = feeds;
  while (cursor + 10 * 60_000 < end) {
    if (left > 0) {
      rows.push({ ...bottle(date, '00:00'), occurredAt: new Date(cursor + 5 * 60_000) });
      left -= 1;
    }
    const from = cursor + 10 * 60_000;
    const until = Math.min(from + (first - 10) * 60_000, end);
    rows.push({
      ...sleep(date, '20:00', 1, by),
      occurredAt: new Date(from),
      endedAt: new Date(until),
    });
    cursor = until;
  }
  return rows;
}

/** Nights 12–25 Oct, read on the morning of 26 Oct (recent 19–25, baseline 12–18). */
const now = at('2026-10-26', '07:30');
function weeks(baseline: number[], recent: number[], feeds: [number[], number[]] = [[], []]) {
  return [
    ...baseline.flatMap((m, i) => night(day('2026-10-12', i), m, feeds[0][i] ?? 1)),
    ...recent.flatMap((m, i) =>
      night(day('2026-10-19', i), m, feeds[1][i] ?? 1, i % 2 ? 'Ba' : 'Mẹ'),
    ),
  ];
}
const run = (
  records: InsightRecord[],
  extra: Partial<Parameters<typeof computeInsights>[0]> = {},
) =>
  computeInsights({
    zone: VN,
    now,
    records,
    openSleepTimerSince: null,
    conflictRecordIds: new Set(),
    ageDays: 120,
    rules,
    ...extra,
  });
const outcome = (c: ReturnType<typeof run>, kind: string) =>
  c.outcomes.find((o) => o.kind === kind)!;

describe('nights', () => {
  it('a night is 18:00 to 06:00 in the baby zone', () => {
    const b = nightBoundsIn(VN, '2026-10-20');
    expect(b.start.toISOString()).toBe('2026-10-20T11:00:00.000Z');
    expect(b.end.toISOString()).toBe('2026-10-20T23:00:00.000Z');
  });

  it('keeps wall times across a clock change (Berlin, 25 Oct 2026)', () => {
    const b = nightBoundsIn('Europe/Berlin', '2026-10-24');
    expect(b.start.toISOString()).toBe('2026-10-24T16:00:00.000Z'); // 18:00 CEST
    expect(b.end.toISOString()).toBe('2026-10-25T05:00:00.000Z'); // 06:00 CET
    expect((b.end.getTime() - b.start.getTime()) / 3_600_000).toBe(13);
  });

  it('the last ended night turns over at 06:00', () => {
    expect(lastEndedNight(VN, at('2026-10-26', '05:59'))).toBe('2026-10-24');
    expect(lastEndedNight(VN, at('2026-10-26', '06:00'))).toBe('2026-10-25');
  });

  const facts = (records: InsightRecord[], extra: Partial<Parameters<typeof nightFacts>[0]> = {}) =>
    nightFacts({
      zone: VN,
      date: '2026-10-20',
      now,
      records,
      openSleepTimerSince: null,
      conflictRecordIds: new Set(),
      rules,
      ...extra,
    });

  it('counts the longest single sleep, its whole length, and the night total clipped', () => {
    const f = facts([
      sleep('2026-10-20', '19:00', 240),
      bottle('2026-10-20', '23:10'),
      sleep('2026-10-20', '23:30', 420), // until 06:30: 7 h, of which 6 h 30 in the night
    ]);
    expect(f).toMatchObject({ valid: true, longestMinutes: 420, totalMinutes: 630, feeds: 1 });
  });

  it('never merges two sleeps into one stretch', () => {
    const f = facts([sleep('2026-10-20', '20:00', 180), sleep('2026-10-20', '23:05', 415)]);
    expect(f.longestMinutes).toBe(415);
  });

  it('"không có ghi nhận" is not "không ngủ"', () => {
    expect(facts([]).reason).toBe('no_sleep');
    // One nap logged at 18:30, then nothing: the night is not counted.
    expect(facts([sleep('2026-10-20', '18:30', 30)]).reason).toBe('gap');
    // A sleep that started before 18:00 is the day's, not the night's.
    expect(facts([sleep('2026-10-20', '17:30', 120)]).reason).toBe('no_sleep');
  });

  it('a running timer, an open overlap or a night not over yet is not counted', () => {
    const rows = night('2026-10-20', 300);
    expect(facts(rows, { openSleepTimerSince: at('2026-10-20', '21:00') }).reason).toBe(
      'timer_open',
    );
    expect(facts(rows, { conflictRecordIds: new Set([rows[0]!.id]) }).reason).toBe('overlap');
    expect(facts(rows, { now: at('2026-10-21', '05:00') }).reason).toBe('not_ended');
    expect(facts(rows).valid).toBe(true);
  });
});

describe('S1 night_longest', () => {
  it('says "dài hơn" with the coverage, the peak and who logged', () => {
    const c = run(weeks([140, 135, 145, 140, 141, 139, 140], [170, 175, 172, 168, 171, 174, 175]));
    const o = outcome(c, 'night_longest');
    expect(o.status).toBe('insight');
    if (o.status !== 'insight') return;
    const i = o.insight;
    expect(insightSchema.parse(i)).toEqual(i);
    expect(i).toMatchObject({
      direction: 'up',
      unit: 'minutes',
      value: 172,
      baselineValue: 140,
      delta: 32,
      recent: { from: '2026-10-19', to: '2026-10-25' },
      baseline: { from: '2026-10-12', to: '2026-10-18' },
      coverage: { valid: 7, total: 7 },
      todayEligible: true,
    });
    expect(i.peak).toMatchObject({ value: 175 });
    expect(i.authors.map((a) => a.name).sort()).toEqual(['Ba', 'Mẹ']);
    expect(i.points).toHaveLength(14);
  });

  it('a night left out is shown as such and the rest still compare (6/7)', () => {
    const rows = weeks([140, 140, 140, 140, 140, 140, 140], [172, 172, 172, 172, 172, 172, 172]);
    const missing = rows.filter(
      (r) =>
        !(r.occurredAt >= at('2026-10-20', '18:00') && r.occurredAt < at('2026-10-21', '06:00')),
    );
    const o = outcome(run(missing), 'night_longest');
    expect(o.status).toBe('insight');
    if (o.status !== 'insight') return;
    expect(o.insight.coverage).toEqual({ valid: 6, total: 7 });
    expect(o.insight.points.find((p) => p.date === '2026-10-20')).toEqual({
      date: '2026-10-20',
      value: null,
      reason: 'no_sleep',
    });
  });

  it('below the threshold or without three nights on that side: nothing', () => {
    expect(
      outcome(run(weeks(Array(7).fill(140), Array(7).fill(155))), 'night_longest').status,
    ).toBe('none');
    // One very long night pulls the mean up, but only two nights are longer.
    expect(
      outcome(run(weeks(Array(7).fill(140), [400, 150, 135, 130, 138, 139, 137])), 'night_longest')
        .status,
    ).toBe('none');
  });

  it('fewer than 5 counted nights in either week: progress, no comparison', () => {
    const rows = weeks(Array(7).fill(140), [172, 172]);
    const c = run(rows);
    expect(outcome(c, 'night_longest')).toMatchObject({
      status: 'insufficient',
      validRecent: 2,
      validBaseline: 7,
    });
    expect(c.progress).toEqual({ validNights: 2, neededNights: 5 });
  });

  it('under 6 weeks of corrected age, "longer" stays off Hôm nay (D-151 #5)', () => {
    const c = run(weeks(Array(7).fill(140), Array(7).fill(175)), { ageDays: 30 });
    const o = outcome(c, 'night_longest');
    expect(o.status === 'insight' && o.insight.todayEligible).toBe(false);
    const shorter = outcome(
      run(weeks(Array(7).fill(175), Array(7).fill(140)), { ageDays: 30 }),
      'night_longest',
    );
    expect(shorter.status === 'insight' && shorter.insight.todayEligible).toBe(true);
  });
});

describe('S2 and F3', () => {
  it('night_total follows the clipped total', () => {
    // Same total night (20:00–06:00 asleep but for 15 min a feed): no S2 change.
    const o = outcome(run(weeks(Array(7).fill(140), Array(7).fill(175))), 'night_total');
    expect(o.status).toBe('none');
  });

  it('night_feeds: fewer feeds, guarded under 6 weeks', () => {
    const rows = weeks(Array(7).fill(150), Array(7).fill(150), [
      Array(7).fill(3),
      Array(7).fill(1),
    ]);
    const o = outcome(run(rows), 'night_feeds');
    expect(o).toMatchObject({
      status: 'insight',
      insight: { direction: 'down', value: 1, baselineValue: 3, unit: 'count' },
    });
    const young = outcome(run(rows, { ageDays: 20 }), 'night_feeds');
    expect(young.status === 'insight' && young.insight.todayEligible).toBe(false);
  });
});

describe('what is shown', () => {
  const comp = run(
    weeks(Array(7).fill(140), Array(7).fill(175), [Array(7).fill(3), Array(7).fill(1)]),
  );

  it('one insight for Hôm nay, the best one, then a 7-day rest for that kind', () => {
    const first = chooseShown({
      computation: comp,
      previous: null,
      premium: true,
      today: '2026-10-26',
      rules,
    });
    expect(first.today).toBe('night_longest');
    expect(first.items.length).toBeGreaterThanOrEqual(2);
    // Same day: the pick holds.
    const again = chooseShown({
      computation: comp,
      previous: first,
      premium: true,
      today: '2026-10-26',
      rules,
    });
    expect(again.today).toBe('night_longest');
    // Next day: night_longest rests, the next kind may lead.
    const next = chooseShown({
      computation: comp,
      previous: first,
      premium: true,
      today: '2026-10-27',
      rules,
    });
    expect(next.today).toBe('night_feeds');
    // A week later it may lead again.
    const later = chooseShown({
      computation: comp,
      previous: { ...next, todayOn: '2026-11-01' },
      premium: true,
      today: '2026-11-02',
      rules,
    });
    expect(later.today).toBe('night_longest');
  });

  it('Free: no figures, only the kind, at most once a week (D-151 #9)', () => {
    const free = chooseShown({
      computation: comp,
      previous: null,
      premium: false,
      today: '2026-10-26',
      rules,
    });
    expect(free.items).toEqual([]);
    expect(free.today).toBeNull();
    expect(free.teaser).toEqual({ kind: 'night_longest', direction: 'up' });
    expect(JSON.stringify(free)).not.toMatch(/"value"|"delta"|"points"/);
    const tomorrow = chooseShown({
      computation: comp,
      previous: free,
      premium: false,
      today: '2026-10-27',
      rules,
    });
    expect(tomorrow.teaser).toBeNull();
    const nextWeek = chooseShown({
      computation: comp,
      previous: { ...tomorrow, lastTodayOn: {} },
      premium: false,
      today: '2026-11-02',
      rules,
    });
    expect(nextWeek.teaser).not.toBeNull();
  });
});

describe('rules config', () => {
  it('merges config over the defaults and falls back when broken', () => {
    expect(insightRulesFrom({ minValidNights: 4, minDelta: { night_total: 45 } })).toMatchObject({
      minValidNights: 4,
      minDelta: { night_longest: 20, night_total: 45, night_feeds: 1 },
    });
    expect(insightRulesFrom({ windowNights: 'x' })).toEqual(defaultInsightRules);
    expect(insightRulesFrom(null)).toEqual(defaultInsightRules);
  });
});
