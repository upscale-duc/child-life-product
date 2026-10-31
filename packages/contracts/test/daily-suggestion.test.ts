import { describe, expect, it } from 'vitest';
import {
  activityKindOf,
  addDaysIso,
  defaultRhythmRules,
  emptyExposure,
  exposureAnswer,
  feedbackMemory,
  pickDailySuggestion,
  readExposure,
  recordDailyPick,
  rollExposure,
  type Activity,
  type DailyPickInput,
  type SuggestionExposure,
} from '../src/index.js';
import seed from '../../../content/rhythm/content.seed.json' with { type: 'json' };

/** D-154 rank-v2: the shared daily pick, its rests and the exposure log. */
const act = (id: string, over: Partial<Activity> = {}): Activity => ({
  id,
  version: 1,
  status: 'published',
  title: { vi: id, en: id },
  summary: { vi: id, en: id },
  steps: { vi: ['x'], en: ['x'] },
  safety: null,
  durationMin: 10,
  ageDays: { from: 0, to: 365 },
  needs: ['play'],
  interests: [],
  timeOfDay: 'any',
  locales: ['vi', 'en'],
  regions: [],
  sources: [],
  review: null,
  ...over,
});
const pack = seed.activities as Activity[];
const base: DailyPickInput = {
  babyId: 'baby_1',
  locale: 'vi',
  today: '2026-11-01',
  ageDays: 45,
  need: null,
  context: 'usual',
  interests: ['sleep', 'feeding', 'nutrition', 'moments'],
  fewer: [],
  country: 'VN',
  healthFlag: false,
  memory: feedbackMemory([], 3),
  exposure: emptyExposure,
  rules: defaultRhythmRules,
  activities: pack,
};

type Answer = 'none' | 'tried' | 'helpful';
/** The server's daily step: roll, pick, record, then the family's answer (if any). */
function simulate(
  days: number,
  over: Partial<DailyPickInput> = {},
  answer: (day: number) => Answer = () => 'none',
) {
  let exposure: SuggestionExposure = emptyExposure;
  const picks: { primary: string; extra: string | null; secondary: string[] }[] = [];
  for (let d = 0; d < days; d++) {
    const today = addDaysIso(base.today, d);
    exposure = rollExposure(exposure, today);
    const x = { ...base, ...over, today, ageDays: (over.ageDays ?? base.ageDays) + d, exposure };
    const out = pickDailySuggestion(x);
    if (out.kind !== 'suggestion') throw new Error(`no pick on ${today}`);
    exposure = recordDailyPick(exposure, {
      date: today,
      primary: out.primary.id,
      secondary: out.secondary.map((a) => a.id),
      extra: out.extra?.id ?? null,
      reasonCode: out.reasonCode,
      need: x.need,
      context: x.context,
    });
    const a = answer(d);
    if (a !== 'none') {
      const it = exposure.items[out.primary.id]!;
      exposure = {
        ...exposure,
        items: { ...exposure.items, [out.primary.id]: { ...it, ...exposureAnswer(a, today) } },
      };
    }
    picks.push({
      primary: out.primary.id,
      extra: out.extra?.id ?? null,
      secondary: out.secondary.map((s) => s.id),
    });
  }
  return { picks, exposure };
}
const repeatsWithin = (ids: string[], days: number) =>
  ids.filter((id, i) => ids.slice(Math.max(0, i - days), i).includes(id)).length;

describe('pickDailySuggestion (D-154 rank-v2)', () => {
  it('health always wins', () => {
    expect(pickDailySuggestion({ ...base, healthFlag: true })).toEqual({ kind: 'health' });
  });

  it('is deterministic: the same input gives the same pick', () => {
    expect(pickDailySuggestion(base)).toEqual(pickDailySuggestion(base));
  });

  it.each([
    [21, '3 weeks'],
    [45, '6 weeks'],
    [200, '6.5 months'],
    [500, '16 months'],
  ])('rotates through the pack for a family that never answers (%i days, %s)', (ageDays) => {
    const ids = simulate(30, { ageDays }).picks.map((p) => p.primary);
    expect(new Set(ids).size).toBeGreaterThanOrEqual(15);
    expect(repeatsWithin(ids, 7)).toBeLessThanOrEqual(3);
  });

  it('never leads with a safety check or a card for the parents (Q1), 0–24 months', () => {
    const { picks } = simulate(730, { ageDays: 0 }, (d) => (d % 3 === 0 ? 'tried' : 'none'));
    expect(picks.filter((p) => activityKindOf({ id: p.primary }) !== 'activity')).toEqual([]);
    expect(picks.every((p) => !p.extra || activityKindOf({ id: p.extra }) !== 'activity')).toBe(
      true,
    );
  });

  it('shows an extra card at most once every extraEveryDays, each check at most monthly', () => {
    const { picks } = simulate(120, { ageDays: 0 });
    const extraDays = picks.flatMap((p, d) => (p.extra ? [d] : []));
    expect(extraDays.length).toBeGreaterThan(0);
    for (let i = 1; i < extraDays.length; i++)
      expect(extraDays[i]! - extraDays[i - 1]!).toBeGreaterThanOrEqual(4);
    const byId = new Map<string, number[]>();
    picks.forEach((p, d) => p.extra && byId.set(p.extra, [...(byId.get(p.extra) ?? []), d]));
    for (const [id, days] of byId)
      if (activityKindOf({ id }) === 'check')
        for (let i = 1; i < days.length; i++)
          expect(days[i]! - days[i - 1]!, id).toBeGreaterThanOrEqual(30);
  });

  it('lets an idea rest triedRestDays after "Đã thử"', () => {
    const activities = ['act_a', 'act_b', 'act_c'].map((id) => act(id));
    const { picks } = simulate(10, { activities }, (d) => (d === 0 ? 'tried' : 'none'));
    const first = picks[0]!.primary;
    const back = picks.findIndex((p, d) => d > 0 && p.primary === first);
    expect(back === -1 || back >= 7).toBe(true);
  });

  it('brings a "Có ích" idea back after helpfulRestDays, with PREVIOUS_HELPFUL', () => {
    const activities = ['act_a', 'act_b', 'act_c', 'act_d', 'act_e'].map((id) => act(id));
    const day0 = pickDailySuggestion({ ...base, activities });
    if (day0.kind !== 'suggestion') throw new Error('no pick');
    const id = day0.primary.id;
    const exposure: SuggestionExposure = {
      ...emptyExposure,
      items: {
        [id]: {
          lastShown: base.today,
          prevShown: null,
          shown: 1,
          ignored: 0,
          ...exposureAnswer('helpful', base.today),
        } as SuggestionExposure['items'][string],
      },
    };
    for (let d = 1; d < 7; d++) {
      const out = pickDailySuggestion({
        ...base,
        activities,
        exposure,
        today: addDaysIso(base.today, d),
      });
      expect(out.kind === 'suggestion' && out.primary.id).not.toBe(id);
    }
    const back = pickDailySuggestion({
      ...base,
      activities,
      exposure,
      today: addDaysIso(base.today, 7),
    });
    expect(back).toMatchObject({ primary: { id }, reasonCode: 'PREVIOUS_HELPFUL' });
  });

  it('a small pool never runs dry: everything resting brings back the longest unseen', () => {
    const activities = [act('act_a'), act('act_b')];
    const { picks } = simulate(12, { activities }, () => 'tried');
    expect(picks).toHaveLength(12);
  });

  it('keeps the need filter of rank-v1: no matching idea → none', () => {
    expect(pickDailySuggestion({ ...base, need: 'sleep', activities: [act('act_a')] })).toEqual({
      kind: 'none',
    });
  });
});

describe('the shared daily pick (Q2)', () => {
  const first = pickDailySuggestion(base);
  if (first.kind !== 'suggestion') throw new Error('no pick');
  const stored = recordDailyPick(emptyExposure, {
    date: base.today,
    primary: first.primary.id,
    secondary: first.secondary.map((a) => a.id),
    extra: first.extra?.id ?? null,
    reasonCode: first.reasonCode,
    need: null,
    context: 'usual',
  });

  it('is reused for the rest of the day, by anyone in the household', () => {
    const again = pickDailySuggestion({ ...base, exposure: stored, interests: [] });
    expect(again).toMatchObject({ reused: true, primary: { id: first.primary.id } });
  });

  it('a person who hid it gets their own pick, stable through the day, without moving the household', () => {
    const mine = {
      ...base,
      exposure: stored,
      activities: pack.filter((a) => a.id !== first.primary.id),
    };
    const a = pickDailySuggestion(mine);
    if (a.kind !== 'suggestion') throw new Error('no pick');
    const marked = recordDailyPick(stored, {
      date: base.today,
      primary: a.primary.id,
      secondary: a.secondary.map((s) => s.id),
      extra: a.extra?.id ?? null,
      reasonCode: a.reasonCode,
      need: null,
      context: 'usual',
    });
    expect(marked.day?.primary).toBe(first.primary.id);
    expect(pickDailySuggestion({ ...mine, exposure: marked })).toMatchObject({
      primary: { id: a.primary.id },
    });
  });

  it('a new need (a check-in) makes a new household pick', () => {
    const sleep = pickDailySuggestion({ ...base, exposure: stored, need: 'sleep' });
    expect(sleep).toMatchObject({ reused: false });
    if (sleep.kind !== 'suggestion') throw new Error('no pick');
    const next = recordDailyPick(stored, {
      date: base.today,
      primary: sleep.primary.id,
      secondary: [],
      extra: null,
      reasonCode: sleep.reasonCode,
      need: 'sleep',
      context: 'usual',
    });
    expect(next.day).toMatchObject({ primary: sleep.primary.id, need: 'sleep' });
  });
});

describe('exposure log', () => {
  const day = (primary: string) =>
    recordDailyPick(emptyExposure, {
      date: '2026-11-01',
      primary,
      secondary: [],
      extra: null,
      reasonCode: 'AGE_CONTENT',
      need: null,
      context: 'usual',
    });

  it('counts an unanswered lead as scrolled past once, on the next day only', () => {
    const rolled = rollExposure(day('act_a'), '2026-11-02');
    expect(rolled.items.act_a).toMatchObject({ ignored: 1, shown: 1 });
    expect(rollExposure(rolled, '2026-11-02')).toEqual(rolled);
  });

  it('an answer that day keeps it from counting', () => {
    const e = day('act_a');
    const answered = {
      ...e,
      items: { act_a: { ...e.items.act_a!, ...exposureAnswer('snooze', '2026-11-01') } },
    };
    expect(rollExposure(answered, '2026-11-02').items.act_a?.ignored).toBe(0);
  });

  it('reads a missing or malformed document as empty', () => {
    expect(readExposure(undefined)).toEqual(emptyExposure);
    expect(readExposure({ day: 'x' })).toEqual(emptyExposure);
  });

  it('old config/rhythm documents get the rotation defaults', async () => {
    const { rhythmRulesSchema } = await import('../src/index.js');
    const rotation = [
      'rotationMaxGapDays',
      'triedRestDays',
      'helpfulRestDays',
      'extraEveryDays',
      'checkEveryDays',
      'parentEveryDays',
    ];
    const v1 = Object.fromEntries(
      Object.entries(defaultRhythmRules).filter(([k]) => !rotation.includes(k)),
    );
    expect(rhythmRulesSchema.parse(v1)).toEqual(defaultRhythmRules);
  });
});

describe('exposure documents written in parts', () => {
  it('an answer merged before any pick still reads as a full item', () => {
    const e = readExposure({ items: { act_a: exposureAnswer('tried', '2026-11-01') } });
    expect(e.items.act_a).toEqual({
      lastShown: null,
      prevShown: null,
      shown: 0,
      ignored: 0,
      lastAnswered: '2026-11-01',
      lastTried: '2026-11-01',
      lastHelpful: null,
    });
    expect(e.day).toBeNull();
  });
});
