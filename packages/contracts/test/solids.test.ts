import { describe, expect, it } from 'vitest';
import {
  contentFoodSchema,
  contentRecipeSchema,
  familyRecipeSchema,
  foodContentSchema,
  mealSchema,
  recipeAgeProblems,
  recipeAllergens,
  recipeContentSchema,
  slotForTime,
  solidsAgeState,
  solidsCopyProblems,
  solidsSettingsSchema,
  type FoodContent,
  type RecipeContent,
} from '../src/index.js';

// Ăn dặm (D-085, P-164): the catalogue and recipe shapes, the safety gates, the per-baby documents
// and the pure helpers the app mirrors.

const t = (vi: string, en: string) => ({ vi, en });
const none = t('', '');

const egg = (): FoodContent => ({
  name: t('Trứng gà', 'Egg'),
  synonyms: { vi: ['lòng đỏ trứng'], en: ['egg yolk'] },
  group: 'animalProtein',
  allergen: 'egg',
  ironRich: true,
  minAgeMonths: 6,
  prep: [{ texture: 'smooth', text: t('Luộc chín kỹ, nghiền mịn.', 'Hard-boil and mash smooth.') }],
  chokingNote: none,
  suggest: true,
  priority: 60,
  sources: [],
});

const recipe = (): RecipeContent => ({
  title: t('Cháo trứng bí đỏ', 'Egg and pumpkin congee'),
  summary: none,
  cover: null,
  ageMonths: { from: 7, to: 12 },
  texture: 'mashed',
  methods: ['spoon'],
  servings: 2,
  prepMinutes: 10,
  cookMinutes: 30,
  ingredients: [
    { foodId: 'fd_rice', name: t('Gạo tẻ', 'Rice'), qty: 30, unit: 'g', note: none },
    { foodId: 'fd_egg', name: t('Trứng gà', 'Egg'), qty: 1, unit: 'piece', note: none },
    { foodId: null, name: t('Nước', 'Water'), qty: 400, unit: 'ml', note: none },
  ],
  steps: {
    vi: ['Nấu cháo nhừ.', 'Thêm trứng chín kỹ, khuấy đều. Không nêm muối.'],
    en: ['Cook the congee until soft.', 'Stir in the well-cooked egg. No added salt.'],
  },
  storage: none,
  tip: none,
  relatedArticleIds: ['art_allergen_intro'],
  sources: [],
});

const meta = {
  status: 'published' as const,
  revision: 1,
  review: null,
  illustrative: true,
  reviewDueOn: '2027-10-19',
  publishedAt: '2026-10-19T03:00:00.000Z',
  firstPublishedAt: '2026-10-19T03:00:00.000Z',
};

describe('catalogue and recipes', () => {
  it('a complete food and recipe publish; drafts may be half written', () => {
    expect(foodContentSchema.safeParse(egg()).success).toBe(true);
    expect(contentFoodSchema.safeParse({ ...egg(), id: 'fd_egg', ...meta }).success).toBe(true);
    expect(recipeContentSchema.safeParse(recipe()).success).toBe(true);
    expect(
      contentRecipeSchema.safeParse({ ...recipe(), id: 'rcp_egg_pumpkin', ...meta }).success,
    ).toBe(true);
    // Before 6 months nothing is a food or a recipe (D-085 #4); vi and en steps must pair up.
    expect(foodContentSchema.safeParse({ ...egg(), minAgeMonths: 4 }).success).toBe(false);
    expect(
      recipeContentSchema.safeParse({ ...recipe(), ageMonths: { from: 5, to: 8 } }).success,
    ).toBe(false);
    const odd = recipe();
    odd.steps.en.pop();
    expect(recipeContentSchema.safeParse(odd).success).toBe(false);
  });

  it('derives allergens and refuses foods too young for the recipe', () => {
    const foods = new Map([
      ['fd_egg', { allergen: 'egg' as const, minAgeMonths: 6 }],
      ['fd_rice', { allergen: null, minAgeMonths: 6 }],
      ['fd_honey', { allergen: null, minAgeMonths: 12 }],
    ]);
    expect(recipeAllergens(recipe(), foods)).toEqual(['egg']);
    expect(recipeAgeProblems(recipe(), foods)).toEqual([]);
    const sweet = recipe();
    sweet.ingredients.push({
      foodId: 'fd_honey',
      name: t('Mật ong', 'Honey'),
      qty: 1,
      unit: 'tsp',
      note: none,
    });
    expect(recipeAgeProblems(sweet, foods)).toEqual([{ foodId: 'fd_honey', minAgeMonths: 12 }]);
  });

  it('copy: amounts and "to taste" phrasings are seasonings too; plain cooking words are not', () => {
    const hit = (x: string) => solidsCopyProblems({ tip: { vi: x, en: '' } }).map((p) => p.match);
    expect(hit('Nêm chút nước mắm cho thơm.')).toEqual(['Nêm chút nước mắm']);
    expect(hit('Thêm một chút đường.')).toEqual(['Thêm một chút đường']);
    expect(hit('Nêm nếm vừa ăn.')).toEqual(['Nêm nếm vừa ăn']);
    expect(hit('Add a pinch of salt.')).toEqual(['Add a pinch of salt']);
    expect(hit('Season to taste.')).toEqual(['Season to taste']);
    for (const ok of [
      'Không nêm muối, đường.',
      'Không cần thêm đường.',
      'No added salt or sugar.',
      'Do not add honey before 12 months.',
      'Cho thêm rau.',
      'Đường tiêu hoá của bé còn non.',
    ]) {
      expect(hit(ok), ok).toEqual([]);
    }
  });

  it('copy: seasonings as ingredients or instructions, unless negated; doses and words as nutrition', () => {
    expect(solidsCopyProblems(recipe())).toEqual([]);
    const salty = recipe();
    salty.ingredients.push({
      foodId: null,
      name: t('Nước mắm', 'Fish sauce'),
      qty: null,
      unit: null,
      note: none,
    });
    salty.steps.vi[1] = 'Nêm thêm hạt nêm cho vừa.';
    salty.steps.en[1] = 'Add salt to taste.';
    expect(solidsCopyProblems(salty).map((p) => [p.path, p.match])).toEqual([
      ['ingredients.3.name.vi', 'nước mắm'],
      ['ingredients.3.name.en', 'fish sauce'],
      ['steps.vi.1', 'Nêm thêm hạt nêm'],
      ['steps.en.1', 'Add salt'],
    ]);
    const dose = recipe();
    dose.tip = t('Cho bé uống 10 mg sắt.', 'Give 10 mg of iron.');
    expect(solidsCopyProblems(dose).map((p) => p.problem)).toEqual(['dose', 'dose']);
  });
});

describe('per baby', () => {
  const at = new Date('2026-10-08T09:10:00Z');
  const meal = {
    id: `m_${'a'.repeat(32)}`,
    babyId: 'b1',
    occurredAt: at,
    slot: 'morning',
    dish: 'Cháo bí đỏ',
    foodIds: ['fd_rice', 'fd_pumpkin'],
    freeFoods: [],
    amount: { preset: 'halfBowl' },
    reaction: 'liked',
    symptoms: [],
    note: '',
    recipeId: null,
    photoPath: null,
    createdBy: 'u1',
    author: { name: 'Mai', relation: 'mother', relationCustom: null },
    createdAt: at,
    clientCreatedAt: at,
    updatedAt: at,
    updatedBy: 'u1',
    deleted: false,
    deletedAt: null,
    deletedBy: null,
  };

  it('a meal needs a dish or an ingredient; amounts are a preset or a value with a unit', () => {
    expect(mealSchema.safeParse(meal).success).toBe(true);
    expect(mealSchema.safeParse({ ...meal, amount: { value: 4, unit: 'spoon' } }).success).toBe(
      true,
    );
    expect(mealSchema.safeParse({ ...meal, dish: ' ', foodIds: [] }).success).toBe(false);
    expect(mealSchema.safeParse({ ...meal, symptoms: ['breathing', 'swelling'] }).success).toBe(
      true,
    );
    expect(mealSchema.safeParse({ ...meal, id: 'r_x' }).success).toBe(false);
  });

  it("a meal links a Child Life recipe or one of the family's own (D-086)", () => {
    expect(mealSchema.safeParse({ ...meal, recipeId: 'rcp_chao_bi_do' }).success).toBe(true);
    expect(mealSchema.safeParse({ ...meal, recipeId: `fr_${'b'.repeat(32)}` }).success).toBe(true);
    expect(mealSchema.safeParse({ ...meal, recipeId: 'fd_egg' }).success).toBe(false);
  });

  it('a family recipe: a title and at least one ingredient; steps and quantities optional', () => {
    const own = {
      id: `fr_${'c'.repeat(32)}`,
      babyId: 'b1',
      title: 'Cháo gà bí đỏ của bà',
      photoPath: null,
      ingredients: [
        { foodId: 'fd_chicken', name: 'Thịt gà', qty: 30, unit: 'g' },
        { foodId: null, name: 'Nước dùng xương', qty: null, unit: null },
      ],
      steps: ['Nấu cháo nhừ.', 'Thêm gà xay và bí đỏ nghiền.'],
      note: '',
      createdBy: 'u1',
      author: { name: 'Mai', relation: 'mother', relationCustom: null },
      createdAt: at,
      clientCreatedAt: at,
      updatedAt: at,
      updatedBy: 'u1',
      deleted: false,
      deletedAt: null,
      deletedBy: null,
    };
    expect(familyRecipeSchema.safeParse(own).success).toBe(true);
    expect(familyRecipeSchema.safeParse({ ...own, steps: [] }).success).toBe(true);
    expect(familyRecipeSchema.safeParse({ ...own, ingredients: [] }).success).toBe(false);
    expect(familyRecipeSchema.safeParse({ ...own, title: ' ' }).success).toBe(false);
    expect(familyRecipeSchema.safeParse({ ...own, id: 'rcp_x1' }).success).toBe(false);
  });

  it('settings', () => {
    expect(
      solidsSettingsSchema.safeParse({
        enabled: true,
        startedOn: '2026-09-28',
        showOnToday: true,
        method: 'mixed',
        hidden: ['fd_carrot'],
        cleared: [],
        updatedAt: at,
        updatedBy: 'u1',
      }).success,
    ).toBe(true);
  });

  it('age states and slots', () => {
    expect([3, 4, 5, 6, 30].map(solidsAgeState)).toEqual([
      'tooYoung',
      'soon',
      'soon',
      'ready',
      'ready',
    ]);
    expect([5, 9, 10, 13, 14, 16, 17, 20, 21, 2].map(slotForTime)).toEqual([
      'morning',
      'morning',
      'noon',
      'noon',
      'afternoon',
      'afternoon',
      'evening',
      'evening',
      'snack',
      'snack',
    ]);
  });
});

describe('library readability and families abroad (D-087)', () => {
  it('"115" in content text is reported (sources excluded); 1150 or 0,115 are not', async () => {
    const { literalEmergencyProblems, articleDraftSchema, calloutTones } =
      await import('../src/index.js');
    expect(
      literalEmergencyProblems({
        body: { vi: [{ text: 'Gọi 115 ngay' }, { text: '1150 ml' }, { text: '0,115' }] },
        sources: [{ label: 'Cấp cứu 115', url: 'https://x.vn/' }],
      }),
    ).toEqual([{ path: 'body.vi.0.text', match: '115' }]);
    expect(literalEmergencyProblems({ text: 'Gọi {emergency} ngay' })).toEqual([]);
    // The usual forms: a full stop or a comma right after the number.
    expect(
      literalEmergencyProblems({ a: 'hãy gọi 115.', b: 'gọi 115, rồi', c: '1.150 ml' }),
    ).toEqual([
      { path: 'a', match: '115' },
      { path: 'b', match: '115' },
    ]);
    expect(calloutTones).toContain('urgent');
    expect(articleDraftSchema.shape.subtopic).toBeDefined();
  });
});
