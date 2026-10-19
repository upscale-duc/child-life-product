import { familyRecipeSchema, foodAllergens } from '@child-life/contracts';
import type { DocumentSnapshot, Firestore } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';
import {
  assertRecipeAge,
  assertRecipeLinks,
  assertSolidsCopy,
  foodAdapter,
  foodCoverage,
  readFoodFacts,
  recipeAdapter,
  recipeBands,
  recipeCoverage,
  recipeFoodIds,
  withRecipeFoods,
  type FoodFacts,
} from '../src/content-solids.js';
import { seedFoods, seedRecipes } from '../src/solids-catalog-seed.js';
import {
  eggFixture,
  familyRecipeFixture,
  foodFixture,
  milkFixture,
  recipeFixture,
} from './solids-fixtures.js';

// Ăn dặm on the editorial workflow (D-085, P-164 #8–#10, plan §6): the food and recipe adapters'
// ids, schemas, list rows and titles, the food-too-young / unsafe-copy / link-missing gates, the
// food facts the gates read (the stricter of draft and published), and the portal coverage.

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
  reviewDueOn: '2027-10-19',
  publishedAt: '2026-10-19T03:00:00.000Z',
  firstPublishedAt: '2026-10-19T03:00:00.000Z',
};
const facts = (minAgeMonths: number, over: Partial<FoodFacts> = {}): FoodFacts => ({
  minAgeMonths,
  allergen: null,
  exists: true,
  published: true,
  ...over,
});

describe('adapters', () => {
  it('make and accept their own ids only', () => {
    expect(foodAdapter.newId()).toMatch(/^fd_[a-f0-9]{8}$/);
    expect(recipeAdapter.newId()).toMatch(/^rcp_[a-f0-9]{8}$/);
    expect(foodAdapter.isId('fd_pumpkin')).toBe(true);
    expect(foodAdapter.isId('rcp_pumpkin')).toBe(false);
    expect(foodAdapter.isId('fd_Pumpkin')).toBe(false);
    expect(recipeAdapter.isId('rcp_chao_bi_do')).toBe(true);
    expect(recipeAdapter.isId('fd_egg')).toBe(false);
  });

  it('accept half-written drafts, submit only complete ones, publish the app documents', () => {
    const half = { ...foodFixture(), name: { vi: 'Bí đỏ', en: '' } };
    expect(foodAdapter.draft.safeParse(half).success).toBe(true);
    expect(foodAdapter.strict.safeParse(half).success).toBe(false);
    expect(foodAdapter.strict.safeParse(foodFixture()).success).toBe(true);
    expect(foodAdapter.published('fd_pumpkin', foodFixture(), meta)).toMatchObject({
      id: 'fd_pumpkin',
      status: 'published',
      group: 'vegetable',
      minAgeMonths: 6,
    });
    // Below the diary's 6 months never saves (D-085 #4).
    expect(foodAdapter.draft.safeParse(foodFixture({ minAgeMonths: 4 })).success).toBe(false);

    const recipe = recipeFixture();
    expect(recipeAdapter.strict.safeParse(recipe).success).toBe(true);
    const uneven = { ...recipe, steps: { vi: recipe.steps.vi, en: ['Only one step.'] } };
    expect(recipeAdapter.draft.safeParse(uneven).success).toBe(true);
    expect(recipeAdapter.strict.safeParse(uneven).success).toBe(false);
    expect(() => recipeAdapter.published('rcp_chao', uneven, meta)).toThrow();
    expect(recipeAdapter.published('rcp_chao', recipe, meta)).toMatchObject({
      id: 'rcp_chao',
      ageMonths: { from: 6, to: 9 },
      illustrative: true,
    });
    const young = recipeFixture(['fd_pumpkin'], 4, 9);
    expect(recipeAdapter.draft.safeParse(young).success).toBe(false);
  });

  it('give the Thực phẩm and Công thức rows', () => {
    expect(foodAdapter.row(eggFixture())).toEqual({
      group: 'animalProtein',
      allergen: 'egg',
      ironRich: true,
      minAgeMonths: 6,
      suggest: true,
      priority: 70,
      prep: 1,
      prepTextures: ['mashed'],
      synonyms: { vi: [], en: [] },
      synonymCount: 0,
      hasChokingNote: true,
      sources: 1,
    });
    expect(foodAdapter.row(foodFixture())).toMatchObject({
      allergen: null,
      prep: 2,
      prepTextures: ['smooth', 'finger'],
      synonyms: { vi: ['bí ngô'], en: ['squash'] },
      synonymCount: 1,
      hasChokingNote: false,
    });
    const recipe = recipeFixture(['fd_pumpkin', 'fd_egg', 'fd_pumpkin', null], 9, 12, {
      methods: ['spoon', 'blw'],
      relatedArticleIds: ['art_first_meals'],
      cover: { image: 'chao-bi-do_0a1b2c3d', alt: { vi: 'Bát cháo', en: 'A bowl' } },
    });
    expect(recipeAdapter.row(recipe)).toEqual({
      ageMonths: { from: 9, to: 12 },
      ageLabel: { from: 9, to: 11 },
      texture: 'smooth',
      methods: ['spoon', 'blw'],
      servings: 2,
      prepMinutes: 10,
      cookMinutes: 25,
      totalMinutes: 35,
      ingredients: 4,
      ingredientNames: [
        { vi: 'Món 1', en: 'Food 1' },
        { vi: 'Món 2', en: 'Food 2' },
        { vi: 'Món 3', en: 'Food 3' },
        { vi: 'Nước', en: 'Water' },
      ],
      foodIds: ['fd_pumpkin', 'fd_egg'],
      allergens: [],
      ageProblems: [],
      steps: 2,
      hasCover: true,
      links: { articles: ['art_first_meals'], milestones: [] },
      sources: 1,
    });
    // An empty draft still lists.
    expect(foodAdapter.row({})).toMatchObject({
      group: null,
      minAgeMonths: null,
      prep: 0,
      synonyms: { vi: [], en: [] },
    });
    expect(recipeAdapter.row({})).toMatchObject({
      ageMonths: null,
      ageLabel: null,
      foodIds: [],
      ingredientNames: [],
      totalMinutes: null,
    });
  });

  it('title foods by name and recipes by title', () => {
    expect(foodAdapter.title?.(eggFixture())).toEqual({ vi: 'Trứng gà', en: 'Egg' });
    expect(recipeAdapter.title?.(recipeFixture())).toEqual({
      vi: 'Cháo bí đỏ',
      en: 'Pumpkin congee',
    });
    expect(foodAdapter.title?.({})).toEqual({ vi: '', en: '' });
  });

  it('import the catalogue drafts as given (valid drafts with their own ids)', () => {
    const all = [
      [foodAdapter, seedFoods],
      [recipeAdapter, seedRecipes],
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
  it('unsafe-copy: a dose, a condition word or an added seasoning, sources excepted', () => {
    expect(reason(() => assertSolidsCopy(recipeFixture()))).toBe('ok');
    expect(reason(() => assertSolidsCopy(foodFixture()))).toBe('ok');
    const salted = recipeFixture();
    salted.steps.vi[1] = 'Nấu cháo nhừ, nêm muối cho vừa.';
    expect(reason(() => assertSolidsCopy(salted))).toBe('unsafe-copy');
    const sugared = recipeFixture();
    sugared.steps.en[0] = 'Add sugar to the pumpkin.';
    expect(reason(() => assertSolidsCopy(sugared))).toBe('unsafe-copy');
    const sauce = recipeFixture(['fd_pumpkin', null]);
    sauce.ingredients[1]!.name = { vi: 'Nước mắm', en: 'Fish sauce' };
    expect(reason(() => assertSolidsCopy(sauce))).toBe('unsafe-copy');
    const dosed = foodFixture();
    dosed.prep[0]!.text.vi = 'Bổ sung 10 mg sắt mỗi ngày.';
    expect(reason(() => assertSolidsCopy(dosed))).toBe('unsafe-copy');
    const cited = recipeFixture();
    cited.sources = [{ label: 'No added salt or sugar (NHS)', url: 'https://www.nhs.uk/' }];
    expect(reason(() => assertSolidsCopy(cited))).toBe('ok');
  });

  it('food-too-young: an ingredient whose minimum age is above the first month', () => {
    const foods = new Map([
      ['fd_pumpkin', facts(6)],
      ['fd_milk', facts(12, { allergen: 'milk' })],
    ]);
    expect(reason(() => assertRecipeAge(recipeFixture(['fd_pumpkin', null]), foods))).toBe('ok');
    expect(reason(() => assertRecipeAge(recipeFixture(['fd_pumpkin', 'fd_milk']), foods))).toBe(
      'food-too-young',
    );
    expect(
      reason(() => assertRecipeAge(recipeFixture(['fd_pumpkin', 'fd_milk'], 12, 24), foods)),
    ).toBe('ok');
    // A food not in the catalogue is a link problem, not an age one.
    expect(reason(() => assertRecipeAge(recipeFixture(['fd_unknown']), foods))).toBe('ok');
    expect(reason(() => assertRecipeAge({ ...recipeFixture(), ageMonths: 'x' }, foods))).toBe(
      'invalid-content',
    );
  });

  it('link-missing: foods and guides exist to submit, are on the app to publish', () => {
    const recipe = recipeFixture(['fd_pumpkin', 'fd_egg', null], 6, 9, {
      relatedArticleIds: ['art_first_meals'],
    });
    const foods = new Map([
      ['fd_pumpkin', facts(6)],
      ['fd_egg', facts(6, { published: false })],
    ]);
    const live = new Map([['art_first_meals', { exists: true, published: true }]]);
    expect(reason(() => assertRecipeLinks('submit', recipe, foods, live))).toBe('ok');
    expect(reason(() => assertRecipeLinks('approve', recipe, foods, live))).toBe('ok');
    expect(reason(() => assertRecipeLinks('publish', recipe, foods, live))).toBe('link-missing');
    foods.set('fd_egg', facts(6));
    expect(reason(() => assertRecipeLinks('publish', recipe, foods, live))).toBe('ok');
    const drafted = new Map([['art_first_meals', { exists: true, published: false }]]);
    expect(reason(() => assertRecipeLinks('publish', recipe, foods, drafted))).toBe('link-missing');
    expect(reason(() => assertRecipeLinks('submit', recipe, foods, new Map()))).toBe(
      'link-missing',
    );
    foods.delete('fd_pumpkin');
    expect(reason(() => assertRecipeLinks('submit', recipe, foods, live))).toBe('link-missing');
    expect(recipeFoodIds(recipe)).toEqual(['fd_pumpkin', 'fd_egg']);
  });
});

describe('food facts (the latest data)', () => {
  // A stand-in for Firestore: refs carry their path; getAll answers from [docs].
  const fake = (docs: Record<string, Record<string, unknown>>) => {
    const db = {
      collection: (c: string) => ({ doc: (id: string) => ({ path: `${c}/${id}` }) }),
    } as unknown as Firestore;
    const getAll = async (...refs: Array<{ path: string }>) =>
      refs.map((r) => {
        const d = docs[r.path];
        return {
          exists: !!d,
          get: (k: string) => d?.[k],
          data: () => d,
        } as unknown as DocumentSnapshot;
      });
    return { db, getAll: getAll as never };
  };

  it('the stricter minimum age of draft and published, the draft allergen, existence', async () => {
    const { db, getAll } = fake({
      // Published at 12, a draft lowering it to 6 waits for review: still 12.
      'contentDrafts/fd_milk': {
        kind: 'food',
        status: 'draft',
        data: { ...milkFixture(), minAgeMonths: 6 },
      },
      'contentFoods/fd_milk': { ...milkFixture(), status: 'published' },
      // A draft raising the age counts at once.
      'contentDrafts/fd_egg': {
        kind: 'food',
        status: 'in_review',
        data: { ...eggFixture(), minAgeMonths: 8 },
      },
      'contentFoods/fd_egg': { ...eggFixture(), status: 'published' },
      'contentDrafts/fd_old': { kind: 'food', status: 'archived', data: foodFixture() },
      'contentDrafts/fd_odd': { kind: 'article', status: 'draft', data: {} },
      'contentFoods/fd_pub_only': { ...foodFixture({ allergen: 'soy' }), status: 'published' },
    });
    const f = await readFoodFacts(getAll, db, [
      'fd_milk',
      'fd_egg',
      'fd_old',
      'fd_odd',
      'fd_pub_only',
      'fd_none',
      'not-an-id',
      'fd_milk',
    ]);
    expect(Object.fromEntries(f)).toEqual({
      fd_milk: { minAgeMonths: 12, allergen: 'milk', exists: true, published: true },
      fd_egg: { minAgeMonths: 8, allergen: 'egg', exists: true, published: true },
      fd_old: { minAgeMonths: 6, allergen: null, exists: false, published: false },
      fd_pub_only: { minAgeMonths: 6, allergen: 'soy', exists: true, published: true },
    });
    expect((await readFoodFacts(getAll, db, [])).size).toBe(0);
  });

  it('recipe rows get their allergens and age problems from the catalogue', () => {
    const foods = new Map([
      ['fd_pumpkin', facts(6)],
      ['fd_egg', facts(6, { allergen: 'egg' })],
      ['fd_milk', facts(12, { allergen: 'milk' })],
    ]);
    const row = (id: string, foodIds: string[], from: number) => ({
      id,
      status: 'draft' as const,
      live: null,
      foodIds,
      ageMonths: { from, to: from + 3 },
    });
    const [a, b, c] = withRecipeFoods(
      [
        row('rcp_a', ['fd_milk', 'fd_egg', 'fd_pumpkin'], 6),
        row('rcp_b', ['fd_milk'], 12),
        { ...row('rcp_c', [], 6), ageMonths: null },
      ],
      foods,
    );
    expect(a).toMatchObject({
      allergens: ['egg', 'milk'],
      ageProblems: [{ foodId: 'fd_milk', minAgeMonths: 12 }],
    });
    expect(b).toMatchObject({ allergens: ['milk'], ageProblems: [] });
    expect(c).toMatchObject({ allergens: [], ageProblems: [] });
  });
});

describe('coverage (portal §6)', () => {
  const recipe = (id: string, from: number, to: number, status: string, live = false) => ({
    id,
    ageMonths: { from, to },
    status: status as 'draft' | 'in_review' | 'approved' | 'published' | 'archived',
    live,
  });

  it('recipes per age band by state; a recipe counts in every band it overlaps', () => {
    const c = recipeCoverage([
      recipe('rcp_a', 6, 12, 'published', true),
      recipe('rcp_b', 6, 9, 'in_review'),
      recipe('rcp_c', 9, 12, 'draft'),
      recipe('rcp_d', 12, 37, 'draft', true),
      recipe('rcp_e', 24, 37, 'archived'),
      recipe('rcp_f', 8, 10, 'approved'),
    ]);
    expect(c.target).toBe(6);
    expect(c.total).toBe(5);
    expect(c.published).toBe(2);
    expect(c.ready).toBe(false);
    expect(c.bands.map((b) => b.ageMonths)).toEqual(recipeBands);
    expect(c.bands[0]).toEqual({
      ageMonths: { from: 6, to: 9 },
      ageLabel: { from: 6, to: 8 },
      published: 1,
      pending: 2,
      draft: 0,
      total: 3,
      target: 6,
      met: false,
      itemIds: ['rcp_a', 'rcp_b', 'rcp_f'],
    });
    expect(c.bands[1]).toMatchObject({ published: 1, pending: 1, draft: 1, total: 3 });
    expect(c.bands[2]).toMatchObject({ published: 1, total: 1, itemIds: ['rcp_d'] });
    expect(c.bands[3]).toMatchObject({ published: 1, total: 1, ageLabel: { from: 24, to: 36 } });
  });

  it('ready once 6–8, 9–11 and 12–23 each have six recipes on the app', () => {
    const live = (band: number, n: number) =>
      Array.from({ length: n }, (_, i) => {
        const b = recipeBands[band]!;
        return recipe(`rcp_${band}_${i}`, b.from, b.to, 'published', true);
      });
    expect(recipeCoverage([...live(0, 6), ...live(1, 6), ...live(2, 5)]).ready).toBe(false);
    const c = recipeCoverage([...live(0, 6), ...live(1, 6), ...live(2, 6)]);
    expect(c.ready).toBe(true);
    expect(c.bands.map((b) => b.met)).toEqual([true, true, true, false]);
    expect(recipeCoverage([]).bands.every((b) => b.total === 0)).toBe(true);
  });

  it('foods per group, the nine allergens covered and iron-rich, drafts and on the app', () => {
    const food = (
      id: string,
      group: string,
      allergen: string | null,
      ironRich: boolean,
      status: string,
      live = false,
    ) => ({
      id,
      group: group as 'vegetable',
      allergen: allergen as 'egg' | null,
      ironRich,
      status: status as 'draft' | 'archived' | 'published' | 'in_review',
      live,
    });
    const c = foodCoverage([
      food('fd_pumpkin', 'vegetable', null, false, 'published', true),
      food('fd_egg', 'animalProtein', 'egg', true, 'published', true),
      food('fd_beef', 'animalProtein', null, true, 'draft'),
      food('fd_peanut', 'legumeNut', 'peanut', false, 'in_review'),
      food('fd_shrimp', 'animalProtein', 'shellfish', false, 'archived'),
    ]);
    expect(c.total).toBe(4);
    expect(c.published).toBe(2);
    expect(c.groups.find((g) => g.group === 'animalProtein')).toEqual({
      group: 'animalProtein',
      total: 2,
      published: 1,
    });
    expect(c.groups.find((g) => g.group === 'fruit')).toEqual({
      group: 'fruit',
      total: 0,
      published: 0,
    });
    expect(c.allergens).toMatchObject({ total: 9, covered: 2, published: 1 });
    expect(c.allergens.missing).toEqual(foodAllergens.filter((a) => a !== 'egg' && a !== 'peanut'));
    expect(c.allergens.liveMissing).toEqual(foodAllergens.filter((a) => a !== 'egg'));
    expect(c.allergens.byAllergen).toHaveLength(9);
    expect(c.ironRich).toEqual({ total: 2, published: 1 });
  });
});

// The family recipe the rules and server suites write (D-086) is a valid contract document, so
// they test the real shape; the contract and Rules agree it needs an ingredient.
describe('family recipe fixture (D-086)', () => {
  const id = `fr_${'a'.repeat(32)}`;
  it('parses with familyRecipeSchema', () => {
    expect(familyRecipeSchema.safeParse(familyRecipeFixture(id, 'b1')).success).toBe(true);
    expect(
      familyRecipeSchema.safeParse(
        familyRecipeFixture(id, 'b1', { photoPath: 'babies/b1/recipes/photo_rec_1.jpg' }),
      ).success,
    ).toBe(true);
  });

  it('is refused without an ingredient or with a markup title', () => {
    expect(
      familyRecipeSchema.safeParse(familyRecipeFixture(id, 'b1', { ingredients: [] })).success,
    ).toBe(false);
    expect(
      familyRecipeSchema.safeParse(familyRecipeFixture(id, 'b1', { title: '<b>x</b>' })).success,
    ).toBe(false);
  });
});
