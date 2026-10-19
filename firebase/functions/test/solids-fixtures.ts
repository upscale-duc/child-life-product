import type { FamilyRecipe, FoodContent, RecipeContent } from '@child-life/contracts';

// Small, complete Ăn dặm items (D-085) for the server tests, independent of the catalogue seed
// (`solids-catalog-seed.ts`), which the content team fills on its own schedule.

const l = (vi: string, en: string) => ({ vi, en });

export function foodFixture(over: Partial<FoodContent> = {}): FoodContent {
  return {
    name: l('Bí đỏ', 'Pumpkin'),
    synonyms: { vi: ['bí ngô'], en: ['squash'] },
    group: 'vegetable',
    allergen: null,
    ironRich: false,
    minAgeMonths: 6,
    prep: [
      { texture: 'smooth', text: l('Hấp chín, nghiền mịn.', 'Steam until soft, mash smooth.') },
      { texture: 'finger', text: l('Cắt thanh dài, hấp mềm.', 'Cut into soft sticks.') },
    ],
    chokingNote: l('', ''),
    suggest: true,
    priority: 80,
    sources: [{ label: 'NHS Start for Life', url: 'https://www.nhs.uk/start-for-life/' }],
    ...over,
  };
}

export const eggFixture = () =>
  foodFixture({
    name: l('Trứng gà', 'Egg'),
    synonyms: { vi: [], en: [] },
    group: 'animalProtein',
    allergen: 'egg',
    ironRich: true,
    priority: 70,
    prep: [{ texture: 'mashed', text: l('Luộc chín kỹ, nghiền.', 'Hard-boil, then mash.') }],
    chokingNote: l('Luôn nấu chín kỹ.', 'Always cook through.'),
  });

/** Cow's milk as a drink: 12 months (P-164 #8). */
export const milkFixture = () =>
  foodFixture({
    name: l('Sữa bò tươi', "Cow's milk"),
    synonyms: { vi: [], en: [] },
    group: 'dairy',
    allergen: 'milk',
    minAgeMonths: 12,
    suggest: false,
    priority: 10,
    prep: [],
  });

export function recipeFixture(
  foodIds: Array<string | null> = ['fd_pumpkin', null],
  from = 6,
  to = 9,
  over: Partial<RecipeContent> = {},
): RecipeContent {
  return {
    title: l('Cháo bí đỏ', 'Pumpkin congee'),
    summary: l('Cháo mịn cho bữa đầu.', 'A smooth congee for first meals.'),
    cover: null,
    ageMonths: { from, to },
    texture: 'smooth',
    methods: ['spoon'],
    servings: 2,
    prepMinutes: 10,
    cookMinutes: 25,
    ingredients: foodIds.map((foodId, i) => ({
      foodId,
      name: foodId ? l(`Món ${i + 1}`, `Food ${i + 1}`) : l('Nước', 'Water'),
      qty: foodId ? 50 : 200,
      unit: foodId ? 'g' : 'ml',
      note: l('', ''),
    })),
    steps: {
      vi: ['Hấp bí đỏ cho mềm.', 'Nấu cháo nhừ rồi trộn bí nghiền.'],
      en: ['Steam the pumpkin until soft.', 'Cook the congee, then stir in the mash.'],
    },
    storage: l('Ngăn mát tối đa 24 giờ.', 'Fridge up to 24 hours.'),
    tip: l('Không nêm muối.', 'No added salt.'),
    relatedArticleIds: [],
    sources: [{ label: 'WHO complementary feeding', url: 'https://www.who.int/' }],
    ...over,
  };
}

/**
 * A complete "Công thức nhà mình" (D-086, `familyRecipeSchema`) by Mẹ Na: catalogue and free
 * ingredients, with and without quantities, two steps. Dates as the server reads them back.
 */
export function familyRecipeFixture(
  id: string,
  babyId: string,
  over: Partial<FamilyRecipe> = {},
): FamilyRecipe {
  const at = new Date('2026-10-18T04:31:00Z');
  return {
    id,
    babyId,
    title: 'Cháo cá hồi bí đỏ',
    photoPath: null,
    ingredients: [
      { foodId: 'fd_salmon', name: 'Cá hồi', qty: 30, unit: 'g' },
      { foodId: 'fd_pumpkin', name: 'Bí đỏ', qty: 2, unit: 'tbsp' },
      { foodId: null, name: 'Nước dùng rau', qty: null, unit: null },
    ],
    steps: ['Hấp cá và bí cho chín mềm.', 'Nghiền mịn, trộn với cháo trắng.'],
    note: 'Na thích ăn ấm, "không quá đặc"',
    createdBy: 'mom',
    author: { name: 'Mẹ Na', relation: 'mother', relationCustom: null },
    createdAt: at,
    clientCreatedAt: at,
    updatedAt: at,
    updatedBy: 'mom',
    deleted: false,
    deletedAt: null,
    deletedBy: null,
    ...over,
  };
}
