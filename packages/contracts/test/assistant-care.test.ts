import { describe, expect, it } from 'vitest';
import {
  ageInFullMonths,
  assistantNoticeCodes,
  eligibleRecipes,
  feedbackKinds,
  planAssistantActivityRequestSchema,
  recipeSchema,
  recipesOf,
  rhythmContentSchema,
  taskStateForOutcome,
  usageForOutcome,
  type Recipe,
} from '../src/index.js';
import contentSeed from '../../../content/rhythm/content.seed.json' with { type: 'json' };

/** Slice A5 (assistant care) contract additions: recipes, care outcome, plan request, age. */
const L = (s: string) => ({ vi: s, en: s });
const recipe = (over: Partial<Recipe> = {}): Recipe => ({
  id: 'rcp_test_pumpkin',
  version: 1,
  status: 'published',
  title: L('TEST_ONLY'),
  summary: L('TEST_ONLY'),
  ingredientIds: ['pumpkin', 'rice'],
  minAgeMonths: 6,
  regions: ['VN'],
  steps: { vi: ['TEST_ONLY'], en: ['TEST_ONLY'] },
  durationMin: 15,
  sources: [],
  review: null,
  ...over,
});

describe('recipes in the rhythm content pack', () => {
  it('the published pack without recipes stays valid; absent reads as none', () => {
    const parsed = rhythmContentSchema.parse(contentSeed);
    expect(parsed.recipes).toBeUndefined();
    expect(recipesOf(parsed)).toEqual([]);
    expect(recipesOf(null)).toEqual([]);
  });

  it('a pack with recipes parses; ids, ingredient ids and regions are checked', () => {
    const withRecipes = rhythmContentSchema.parse({ ...contentSeed, recipes: [recipe()] });
    expect(recipesOf(withRecipes).map((r) => r.id)).toEqual(['rcp_test_pumpkin']);
    expect(recipeSchema.safeParse(recipe({ id: 'test_recipe_1' })).success).toBe(false);
    expect(recipeSchema.safeParse(recipe({ ingredientIds: ['Egg!'] })).success).toBe(false);
    expect(recipeSchema.safeParse(recipe({ regions: [] })).success).toBe(false);
    expect(recipeSchema.safeParse(recipe({ ingredientIds: [] })).success).toBe(false);
  });

  it('approved = published and reviewed (R02 rule through eligibleRecipes)', () => {
    const toCandidate = (r: Recipe) => ({
      id: r.id,
      ingredientIds: r.ingredientIds,
      minAgeMonths: r.minAgeMonths,
      approved: r.status === 'published' && r.review !== null,
      region: r.regions.includes('VN') ? 'VN' : '',
    });
    const reviewed = { reviewer: 'TEST_ONLY', credential: 'TEST_ONLY', reviewedOn: '2026-10-01' };
    const list = [
      recipe({ id: 'rcp_ok', review: reviewed }),
      recipe({ id: 'rcp_unreviewed' }),
      recipe({ id: 'rcp_draft', status: 'draft', review: reviewed }),
      recipe({ id: 'rcp_egg', ingredientIds: ['egg'], review: reviewed }),
    ];
    expect(eligibleRecipes(list.map(toCandidate), 7, ['egg'], 'VN')).toEqual(['rcp_ok']);
  });
});

describe('care outcome, plan, age', () => {
  it('a fallback answer is shown (ready) and releases the credit', () => {
    const o = { kind: 'fallback' as const, parts: [] };
    expect(usageForOutcome(o)).toBe('release');
    expect(taskStateForOutcome(o)).toBe('ready');
  });

  it('"Thử tối nay" maps to the module’s intention kind, never an outcome', () => {
    expect(feedbackKinds).toContain('started');
    expect(
      planAssistantActivityRequestSchema.safeParse({
        contractVersion: 1,
        clientRequestId: '00000000-0000-4000-8000-000000000000',
        locale: 'vi',
        taskId: 'tk_x',
        contentId: 'act_wind_down_night',
        contentVersion: 1,
      }).success,
    ).toBe(true);
  });

  it('age in full months from the date of birth (Bé Na 10/03 → 7 months on 15/10)', () => {
    expect(ageInFullMonths('2026-03-10', '2026-10-15')).toBe(7);
    expect(ageInFullMonths('2026-03-16', '2026-10-15')).toBe(6);
    expect(ageInFullMonths('2026-09-17', '2026-10-15')).toBe(0);
    expect(ageInFullMonths('2026-10-20', '2026-10-15')).toBe(0);
  });

  it('notice codes are a closed list', () => {
    expect(assistantNoticeCodes).toEqual([
      'CARE_NO_APPROVED_CONTENT',
      'RECIPES_NONE_APPROVED',
      'CARE_FEATURE_DISABLED',
      'REGION_UNSUPPORTED',
      'CARE_AGE_UNKNOWN',
    ]);
  });
});
