import { describe, expect, it } from 'vitest';
import {
  assertSafeCopy,
  nutrientAdapter,
  nutritionCoverage,
  nutritionRuleAdapter,
  nutritionRuleTitle,
  nutritionStageAdapter,
  overlappingStage,
} from '../src/content-nutrition.js';
import { seedNutrients, seedNutritionRules, seedNutritionStages } from '../src/nutrition-seed.js';
import { nutrientFixture, ruleFixture, stageFixture } from './nutrition-fixtures.js';

// Dinh dưỡng theo giai đoạn on the editorial workflow (D-083, P-163): the adapters' ids, schemas
// and list rows, the rule title, the safe-copy and overlap gates, and the D01 coverage strip.

const reason = (fn: () => unknown) => {
  try {
    fn();
    return 'ok';
  } catch (e) {
    return (e as { reason?: string }).reason;
  }
};
const meta = {
  status: 'published' as const,
  revision: 1,
  review: null,
  illustrative: true,
  reviewDueOn: '2027-10-18',
  publishedAt: '2026-10-18T03:00:00.000Z',
  firstPublishedAt: '2026-10-18T03:00:00.000Z',
};

describe('adapters', () => {
  it('make and accept their own ids only', () => {
    expect(nutritionStageAdapter.newId()).toMatch(/^nst_[a-f0-9]{8}$/);
    expect(nutrientAdapter.newId()).toMatch(/^nut_[a-f0-9]{8}$/);
    expect(nutritionRuleAdapter.newId()).toMatch(/^nru_[a-f0-9]{8}$/);
    expect(nutritionStageAdapter.isId('nst_6_8')).toBe(true);
    expect(nutritionStageAdapter.isId('nut_iron')).toBe(false);
    expect(nutrientAdapter.isId('nut_iron')).toBe(true);
    expect(nutritionRuleAdapter.isId('nru_weight_low')).toBe(true);
    expect(nutritionRuleAdapter.isId('stg_x1')).toBe(false);
  });

  it('accept half-written drafts, submit only complete ones, publish the app documents', () => {
    const half = { ...stageFixture(), title: { vi: 'Ăn dặm', en: '' } };
    expect(nutritionStageAdapter.draft.safeParse(half).success).toBe(true);
    expect(nutritionStageAdapter.strict.safeParse(half).success).toBe(false);
    expect(nutritionStageAdapter.strict.safeParse(stageFixture()).success).toBe(true);
    const doc = nutritionStageAdapter.published('nst_6_8', stageFixture(), meta);
    expect(doc).toMatchObject({ id: 'nst_6_8', status: 'published', ageMonths: { from: 6 } });
    expect(nutrientAdapter.published('nut_vitamin_a', nutrientFixture(true), meta)).toMatchObject({
      key: 'vitaminA',
    });
    expect(nutritionRuleAdapter.published('nru_weight_low', ruleFixture(), meta)).toMatchObject({
      metric: 'weight',
    });
    // A condition that does not belong to the metric never publishes.
    const odd = { ...ruleFixture(), condition: 'milkOutsideStage' };
    expect(nutritionRuleAdapter.draft.safeParse(odd).success).toBe(false);
    expect(() => nutritionRuleAdapter.published('nru_weight_low', odd, meta)).toThrow();
  });

  it('give the D01, D03 and D04 list rows', () => {
    expect(nutritionStageAdapter.row(stageFixture(6, 9, ['nut_iron']))).toEqual({
      ageMonths: { from: 6, to: 9 },
      ageLabel: { from: 6, to: 8 },
      milk: {
        perFeedMl: { min: 180, max: 240 },
        feedsPerDay: { min: 4, max: 5 },
        perDayMl: { min: 600, max: 900 },
      },
      solidsMeals: { vi: '2–3 bữa', en: '2–3 meals' },
      nutrientIds: ['nut_iron'],
      sampleDay: 2,
      tips: 1,
      sources: 1,
    });
    expect(
      nutritionStageAdapter.row({ ...stageFixture(), milk: null, solids: null }),
    ).toMatchObject({ milk: null, solidsMeals: null });
    expect(nutrientAdapter.row(nutrientFixture(true))).toMatchObject({
      key: 'vitaminA',
      focus: {
        ageMonths: { from: 6, to: 24 },
        label: { vi: 'Quan trọng từ 6 tháng', en: 'Important from 6 months' },
      },
      foods: expect.arrayContaining([expect.objectContaining({ vi: expect.any(String) })]),
      byAge: 1,
      hasCampaign: true,
      rounds: [
        { month: 6, fromDay: 1, toDay: 2 },
        { month: 12, fromDay: 1, toDay: 2 },
      ],
      sources: 0,
    });
    expect(nutrientAdapter.row(nutrientFixture())).toMatchObject({
      hasCampaign: false,
      rounds: [],
    });
    expect(nutritionRuleAdapter.row(ruleFixture())).toEqual({
      metric: 'weight',
      condition: 'belowRange',
      days: null,
      ageMonths: { from: 0, to: 37 },
      ageLabel: { from: 0, to: 36 },
      remindAfterDays: 14,
      export: true,
      tips: 1,
    });
    // An empty draft still lists.
    expect(nutritionStageAdapter.row({})).toMatchObject({ ageMonths: null, milk: null });
  });

  it('title nutrients by name and rules by the start of their banner', () => {
    expect(nutrientAdapter.title?.(nutrientFixture())).toEqual({ vi: 'Sắt', en: 'Iron' });
    expect(nutritionRuleTitle(ruleFixture())).toEqual({
      vi: 'Hai lần cân gần nhất của bé thấp hơn khoảng chuẩn WHO.',
      en: 'The last two weights are below the WHO range.',
    });
    const long = 'Mỗi bé mỗi khác và lượng sữa thay đổi theo ngày, hãy theo dõi thêm vài hôm nữa';
    const t = nutritionRuleTitle({ banner: { vi: long, en: '' } });
    expect(t.vi.endsWith('…')).toBe(true);
    expect(t.vi.length).toBeLessThanOrEqual(61);
    expect(long.startsWith(t.vi.slice(0, -1))).toBe(true);
    expect(nutritionRuleTitle({})).toEqual({ vi: '', en: '' });
  });

  it('import the expert drafts as given (valid drafts with their own ids)', () => {
    const all = [
      [nutritionStageAdapter, seedNutritionStages],
      [nutrientAdapter, seedNutrients],
      [nutritionRuleAdapter, seedNutritionRules],
    ] as const;
    for (const [adapter, seed] of all) {
      const items = adapter.seed() ?? [];
      expect(items.map((i) => i.id)).toEqual(seed.map((s) => s.id));
      for (const i of items) {
        expect(adapter.isId(i.id)).toBe(true);
        expect(adapter.draft.safeParse(i.data).success).toBe(true);
      }
    }
  });
});

describe('gates', () => {
  it('unsafe-copy: a dose or a condition word anywhere but the sources', () => {
    expect(reason(() => assertSafeCopy(stageFixture()))).toBe('ok');
    const dose = stageFixture();
    dose.summary.vi = 'Bổ sung 50 mg sắt mỗi ngày.';
    expect(reason(() => assertSafeCopy(dose))).toBe('unsafe-copy');
    const word = ruleFixture();
    word.tips[0]!.body.en = 'Signs of malnutrition need a doctor.';
    expect(reason(() => assertSafeCopy(word))).toBe('unsafe-copy');
    const cited = stageFixture();
    cited.sources = [{ label: 'Vitamin D 400 IU (AAP)', url: 'https://www.aap.org/' }];
    expect(reason(() => assertSafeCopy(cited))).toBe('ok');
  });

  it('stage-overlap: shares a month with another stage (to exclusive)', () => {
    const others = [
      { id: 'nst_a', ageMonths: { from: 0, to: 6 } },
      { id: 'nst_b', ageMonths: { from: 9, to: 12 } },
      { id: 'nst_bad', ageMonths: 'x' },
    ];
    expect(overlappingStage({ from: 6, to: 9 }, others)).toBeNull();
    expect(overlappingStage({ from: 5, to: 9 }, others)).toBe('nst_a');
    expect(overlappingStage({ from: 8, to: 10 }, others)).toBe('nst_b');
  });
});

describe('D01 coverage over 0–36 months', () => {
  const item = (id: string, from: number, to: number, status: string, live = false) => ({
    id,
    ageMonths: { from, to },
    status: status as 'draft' | 'in_review' | 'approved' | 'published' | 'archived',
    live,
  });

  it('nothing yet: one gap over every month', () => {
    const c = nutritionCoverage([]);
    expect(c).toMatchObject({ total: 37, covered: 0, published: 0, items: [], overlaps: [] });
    expect(c.gaps).toEqual([{ from: 0, to: 37 }]);
    expect(c.liveGaps).toEqual([{ from: 0, to: 37 }]);
    expect(c.months).toHaveLength(37);
  });

  it('per month the best state, gaps with and without drafts, archived ignored, overlaps', () => {
    const c = nutritionCoverage([
      item('nst_0', 0, 6, 'published', true),
      item('nst_6', 6, 9, 'in_review'),
      item('nst_9', 9, 12, 'draft'),
      item('nst_12', 12, 24, 'archived'),
      item('nst_24', 24, 37, 'draft', true),
      item('nst_8', 8, 10, 'approved'),
    ]);
    expect(c.covered).toBe(25);
    expect(c.published).toBe(6 + 13);
    expect(c.gaps).toEqual([{ from: 12, to: 24 }]);
    expect(c.liveGaps).toEqual([{ from: 6, to: 24 }]);
    expect(c.months[0]).toEqual({ month: 0, state: 'published', itemIds: ['nst_0'] });
    expect(c.months[8]).toEqual({ month: 8, state: 'pending', itemIds: ['nst_6', 'nst_8'] });
    expect(c.months[10]).toEqual({ month: 10, state: 'draft', itemIds: ['nst_9'] });
    expect(c.months[12]).toEqual({ month: 12, state: 'missing', itemIds: [] });
    expect(c.months[36]!.state).toBe('published');
    expect(c.items.map((i) => [i.id, i.state])).toEqual([
      ['nst_0', 'published'],
      ['nst_6', 'pending'],
      ['nst_8', 'pending'],
      ['nst_9', 'draft'],
      ['nst_24', 'published'],
    ]);
    expect(c.items[4]!.ageLabel).toEqual({ from: 24, to: 36 });
    expect(c.overlaps).toEqual([
      { ids: ['nst_6', 'nst_8'], ageMonths: { from: 8, to: 9 } },
      { ids: ['nst_8', 'nst_9'], ageMonths: { from: 9, to: 10 } },
    ]);
  });
});
