import { describe, expect, it } from 'vitest';
import {
  campaignRounds,
  contentKinds,
  contentSaveRequestSchema,
  monthsOld,
  nutritionAgeLabel,
  nutritionAgesOverlap,
  nutritionCopyProblems,
  nutritionGaps,
  nutritionRuleDraftSchema,
  nutritionStageFor,
} from '../src/index.js';

// Dinh dưỡng theo giai đoạn (D-083, P-163): ages, stages, vitamin A rounds and safe copy.

const stage = (from: number, to: number) => ({ id: `${from}-${to}`, ageMonths: { from, to } });
const stages = [
  stage(0, 1),
  stage(1, 4),
  stage(4, 6),
  stage(6, 9),
  stage(9, 12),
  stage(12, 24),
  stage(24, 37),
];

describe('ages and stages', () => {
  it('counts completed calendar months', () => {
    expect(monthsOld('2026-03-18', '2026-10-18')).toBe(7);
    expect(monthsOld('2026-03-19', '2026-10-18')).toBe(6);
    expect(monthsOld('2026-10-20', '2026-10-18')).toBe(0);
  });
  it('labels ranges as the design writes them', () => {
    expect(nutritionAgeLabel({ from: 0, to: 1 })).toEqual({ from: 0, to: 1 });
    expect(nutritionAgeLabel({ from: 6, to: 9 })).toEqual({ from: 6, to: 8 });
    expect(nutritionAgeLabel({ from: 24, to: 37 })).toEqual({ from: 24, to: 36 });
  });
  it('picks the stage for an age; past the last stage the last one', () => {
    expect(nutritionStageFor(stages, 7)!.stage.id).toBe('6-9');
    expect(nutritionStageFor(stages, 36)).toMatchObject({ stage: { id: '24-37' }, past: false });
    expect(nutritionStageFor(stages, 40)).toMatchObject({ stage: { id: '24-37' }, past: true });
    expect(nutritionStageFor([], 7)).toBeNull();
    expect(nutritionStageFor([stage(6, 9)], 3)).toBeNull();
  });
  it('finds gaps and overlaps', () => {
    expect(nutritionGaps(stages)).toEqual([]);
    expect(nutritionGaps([stage(0, 6), stage(9, 37)])).toEqual([{ from: 6, to: 9 }]);
    expect(nutritionAgesOverlap({ from: 6, to: 9 }, { from: 8, to: 12 })).toBe(true);
    expect(nutritionAgesOverlap({ from: 6, to: 9 }, { from: 9, to: 12 })).toBe(false);
  });
});

describe('vitamin A rounds (9g)', () => {
  const campaign = {
    rounds: [
      { month: 12, fromDay: 1, toDay: 2 },
      { month: 6, fromDay: 1, toDay: 2 },
    ],
    ageMonths: { from: 6, to: 37 },
  };
  it('a 7-month baby on 18/10: June too young, December next', () => {
    const r = campaignRounds(campaign, '2026-03-18', '2026-10-18', {});
    expect(r.map((x) => [x.key, x.state])).toEqual([
      ['2026-06', 'tooYoung'],
      ['2026-12', 'next'],
      ['2027-06', 'later'],
      ['2027-12', 'later'],
    ]);
  });
  it('a recorded round is taken; a missed one is past', () => {
    const r = campaignRounds(campaign, '2025-01-10', '2026-10-18', { '2026-06': '2026-06-01' });
    expect(r[0]).toMatchObject({ key: '2026-06', state: 'taken', takenOn: '2026-06-01' });
    const missed = campaignRounds(campaign, '2025-01-10', '2026-10-18', {});
    expect(missed[0]!.state).toBe('past');
  });
});

describe('safe copy and the content kinds', () => {
  it('flags condition words and doses, never in sources', () => {
    const problems = nutritionCopyProblems({
      summary: { vi: 'Bé có thể bị suy dinh dưỡng', en: 'Give 400 IU a day' },
      sources: [{ label: 'Malnutrition guide', url: 'https://www.who.int/' }],
    });
    expect(problems).toEqual([
      { path: 'summary.vi', problem: 'forbidden', match: 'suy dinh dưỡng' },
      { path: 'summary.en', problem: 'dose', match: '400 IU' },
    ]);
  });
  it('a growth banner must say it is not a diagnosis', () => {
    const banner = (vi: string, en: string) => ({ metric: 'weight', banner: { vi, en } });
    expect(
      nutritionCopyProblems(
        banner('Cân nặng thấp hơn khoảng chuẩn.', 'Weight is below the range.'),
      ),
    ).toEqual([
      { path: 'banner.vi', problem: 'disclaimer', match: 'không phải chẩn đoán' },
      { path: 'banner.en', problem: 'disclaimer', match: 'not a diagnosis' },
    ]);
    expect(
      nutritionCopyProblems(banner('Đây không phải chẩn đoán.', 'This is not a diagnosis.')),
    ).toEqual([]);
    expect(
      nutritionCopyProblems({ metric: 'milk', banner: { vi: 'Mỗi bé mỗi khác.', en: 'x' } }),
    ).toEqual([]);
  });
  it('a rule condition must fit its metric', () => {
    const rule = {
      metric: 'milk',
      condition: 'belowRange',
      days: null,
      ageMonths: { from: 0, to: 12 },
      banner: { vi: '', en: '' },
      tips: [],
      remindAfterDays: null,
      export: false,
    };
    expect(nutritionRuleDraftSchema.safeParse(rule).success).toBe(false);
    expect(
      nutritionRuleDraftSchema.safeParse({ ...rule, condition: 'milkOutsideStage' }).success,
    ).toBe(true);
  });
  it('the editorial workflow knows the three kinds', () => {
    expect(contentKinds).toEqual(
      expect.arrayContaining(['nutritionStage', 'nutrient', 'nutritionRule']),
    );
    expect(
      contentSaveRequestSchema.safeParse({
        kind: 'nutrient',
        id: null,
        reviewerLabel: null,
        notes: '',
        data: {
          key: 'iron',
          name: { vi: 'Sắt', en: 'Iron' },
          subtitle: { vi: '', en: '' },
          focus: {
            ageMonths: { from: 6, to: 24 },
            label: { vi: '', en: '' },
            note: { vi: '', en: '' },
          },
          why: { vi: '', en: '' },
          foods: [],
          tip: null,
          byAge: [],
          warning: { vi: '', en: '' },
          campaign: null,
          sources: [],
        },
      }).success,
    ).toBe(true);
  });
});
