import { z } from 'zod';
import { nutritionCopyProblems } from './nutrition.js';
import { contentSourceSchema } from './rhythm.js';

/**
 * Ăn dặm (D-085, P-164; Figma app 5a–5h; plan `docs/product/solids-plan.md`).
 *
 * Editorial kinds on the D-076 workflow (published like the other content kinds):
 * - **Food** (`fd_…`, `contentFoods`): the catalogue behind the ingredient picker, "lần đầu", the
 *   5e groups and the suggestions (group, common allergen, iron, minimum age, preparation by
 *   texture);
 * - **Recipe** (`rcp_…`, `contentRecipes`): 5g, with quantities, texture, methods and storage.
 * Solids guides stay articles (`library: 'solids'`).
 *
 * Per baby, written by the app (Rules mirror these shapes):
 * - `babies/{babyId}/solids/settings` ({@link solidsSettingsSchema}), Cùng nuôi only;
 * - `babies/{babyId}/meals/{mealId}` ({@link mealSchema}), like care records: client ids, the
 *   Firestore cache as the offline outbox, soft delete and the 30-day bin.
 * Meals are child data: never in logs, analytics or crash keys. Suggestions run on the device.
 */

export const solidsLimits = {
  /** The diary opens at 6 completed months (owner, D-085 #4). */
  startMonths: 6,
  /** "Sắp đến lúc ăn dặm" from 4 months. */
  soonMonths: 4,
  maxAgeMonths: 36,
  foodName: 40,
  synonyms: 8,
  synonym: 40,
  prep: 5,
  prepText: 160,
  chokingNote: 200,
  recipeTitle: 90,
  recipeSummary: 200,
  alt: 160,
  ingredients: 15,
  ingredientName: 40,
  ingredientNote: 60,
  maxQty: 2000,
  steps: 8,
  step: 300,
  storage: 240,
  tip: 240,
  servings: 10,
  minutes: 240,
  relatedArticles: 4,
  sources: 8,
  mealDish: 60,
  mealNote: 300,
  mealFoods: 12,
  mealFree: 3,
  freeName: 40,
  amountMax: 1000,
  hidden: 50,
  /** A meal can be logged up to 7 days back (5c date field). */
  backDays: 7,
  /** "Công thức nhà mình" (D-086). */
  familyTitle: 60,
  familyIngredients: 15,
  familySteps: 12,
  familyStep: 300,
  familyNote: 300,
} as const;
const S = solidsLimits;

// ---------- Taxonomy ----------

/** 5e groups: Rau củ · Trái cây · Tinh bột · Đạm động vật · Đậu và hạt · Sữa và chế phẩm · Chất béo. */
export const foodGroups = [
  'vegetable',
  'fruit',
  'grain',
  'animalProtein',
  'legumeNut',
  'dairy',
  'fat',
] as const;
export type FoodGroup = (typeof foodGroups)[number];

/** The common food allergens (ASCIA, BSACI). */
export const foodAllergens = [
  'egg',
  'peanut',
  'milk',
  'wheat',
  'soy',
  'fish',
  'shellfish',
  'sesame',
  'treeNut',
] as const;
export type FoodAllergen = (typeof foodAllergens)[number];

/** The order rule S3 introduces them in (plan §7). */
export const allergenIntroOrder: readonly FoodAllergen[] = [
  'egg',
  'peanut',
  'milk',
  'wheat',
  'fish',
  'soy',
  'sesame',
  'shellfish',
  'treeNut',
];

/** Nghiền mịn · Nghiền lợn cợn · Cắt nhỏ, mềm · Cầm tay · Ăn cùng gia đình. */
export const textureStages = ['smooth', 'mashed', 'softPieces', 'finger', 'family'] as const;
export type TextureStage = (typeof textureStages)[number];

/** 5a "Cách cho ăn": Truyền thống · BLW · Kết hợp. */
export const feedingMethods = ['spoon', 'blw', 'mixed'] as const;
export type FeedingMethod = (typeof feedingMethods)[number];
/** A recipe suits spoon feeding, BLW, or both. */
export const recipeMethods = ['spoon', 'blw'] as const;
export type RecipeMethod = (typeof recipeMethods)[number];

export const ingredientUnits = ['g', 'ml', 'tbsp', 'tsp', 'bowl', 'piece'] as const;
export type IngredientUnit = (typeof ingredientUnits)[number];

/** 5c slots: Sáng · Trưa · Chiều · Tối · Phụ. */
export const mealSlots = ['morning', 'noon', 'afternoon', 'evening', 'snack'] as const;
export type MealSlot = (typeof mealSlots)[number];
/** 5c "Lượng bé ăn": Vài thìa · ½ chén · 1 chén (or "Tự nhập"). */
export const mealAmountPresets = ['fewSpoons', 'halfBowl', 'fullBowl'] as const;
export const mealAmountUnits = ['spoon', 'bowl', 'ml', 'g'] as const;
/** 5c "Bé ăn thế nào": Thích · Bình thường · Chưa hợp. */
export const mealReactions = ['liked', 'neutral', 'notYet'] as const;
export type MealReaction = (typeof mealReactions)[number];
/**
 * "Có dấu hiệu bất thường sau khi ăn?" (P-164 #6): Nổi mẩn, mề đay · Nôn · Tiêu chảy · Quấy khóc
 * bất thường · Sưng môi, mặt · Khó thở, ho, khò khè · Khác.
 */
export const mealSymptoms = [
  'rash',
  'vomit',
  'diarrhea',
  'fussy',
  'swelling',
  'breathing',
  'other',
] as const;
export type MealSymptom = (typeof mealSymptoms)[number];
/** These show the "Gọi 115" card before saving. */
export const urgentSymptoms: readonly MealSymptom[] = ['swelling', 'breathing'];

// ---------- Plain text ----------

const plain = (s: string) => !/<\s*\/?\s*[a-zA-Z!?]/.test(s) && !/javascript\s*:/i.test(s);
const text = (max: number, min: number) =>
  z.string().trim().min(min).max(max).refine(plain, 'Plain text only, no markup');
const loc = (max: number, min: number) =>
  z.object({ vi: text(max, min), en: text(max, min) }).strict();
const locList = (max: number, items: number, min: number) =>
  z
    .object({
      vi: z.array(text(max, 1)).min(min).max(items),
      en: z.array(text(max, 1)).min(min).max(items),
    })
    .strict();

// ---------- Ids ----------

export const foodIdSchema = z.string().regex(/^fd_[a-z0-9_]{2,40}$/);
export const recipeIdSchema = z.string().regex(/^rcp_[a-z0-9_]{2,40}$/);
/** Client ids like care records: `m_` + 32 hex, stable across retries. */
export const mealIdSchema = z.string().regex(/^m_[a-f0-9]{32}$/);
/** "Công thức nhà mình" (D-086): client ids `fr_` + 32 hex. */
export const familyRecipeIdSchema = z.string().regex(/^fr_[a-f0-9]{32}$/);
/** What a meal was cooked from: a Child Life recipe or one of the family's own. */
export const mealRecipeRefSchema = z.union([recipeIdSchema, familyRecipeIdSchema]);
/** Same shapes as `content.ts` (kept here so this file does not import it). */
const imageIdSchema = z.string().regex(/^[a-z0-9-]{2,48}_[a-f0-9]{8}$/);
const articleRefSchema = z.string().regex(/^art_[a-z0-9_]{2,60}$/);

/** Completed months, `to` exclusive, within 6–36 (the diary opens at 6, D-085 #4). */
export const solidsAgeSchema = z
  .object({
    from: z.number().int().min(S.startMonths).max(S.maxAgeMonths),
    to: z
      .number()
      .int()
      .min(S.startMonths + 1)
      .max(S.maxAgeMonths + 1),
  })
  .strict()
  .refine((a) => a.to > a.from, 'The range must end after it starts');
export type SolidsAge = z.infer<typeof solidsAgeSchema>;

// ---------- Food (catalogue) ----------

export function solidsFoodSchema(strict: boolean) {
  const min = strict ? 1 : 0;
  return z
    .object({
      name: loc(S.foodName, min),
      /** Search terms ("bí ngô" for Bí đỏ). */
      synonyms: locList(S.synonym, S.synonyms, 0),
      group: z.enum(foodGroups),
      allergen: z.enum(foodAllergens).nullable(),
      ironRich: z.boolean(),
      /** Never suggested or allowed in a recipe for a younger baby (honey, cow's milk as a drink: 12). */
      minAgeMonths: z.number().int().min(S.startMonths).max(S.maxAgeMonths),
      /** How to prepare it at each texture stage ("Nho: cắt dọc làm tư"). */
      prep: z
        .array(z.object({ texture: z.enum(textureStages), text: loc(S.prepText, min) }).strict())
        .max(S.prep),
      chokingNote: loc(S.chokingNote, 0),
      /** Whether the suggestions may propose it (plan §7). */
      suggest: z.boolean(),
      /** Higher first among equals (0–100). */
      priority: z.number().int().min(0).max(100),
      sources: z.array(contentSourceSchema).max(S.sources),
    })
    .strict();
}
export const foodDraftSchema = solidsFoodSchema(false);
export type FoodDraft = z.infer<typeof foodDraftSchema>;
export const foodContentSchema = solidsFoodSchema(true);
export type FoodContent = z.infer<typeof foodContentSchema>;

// ---------- Recipe ----------

const stepsSame = (r: { steps: { vi: string[]; en: string[] } }) =>
  r.steps.vi.length === r.steps.en.length;

export function solidsRecipeSchema(strict: boolean) {
  const min = strict ? 1 : 0;
  return z
    .object({
      title: loc(S.recipeTitle, min),
      summary: loc(S.recipeSummary, 0),
      cover: z
        .object({ image: imageIdSchema, alt: loc(S.alt, min) })
        .strict()
        .nullable(),
      ageMonths: solidsAgeSchema,
      texture: z.enum(textureStages),
      methods: z.array(z.enum(recipeMethods)).min(min).max(recipeMethods.length),
      servings: z.number().int().min(1).max(S.servings),
      prepMinutes: z.number().int().min(0).max(S.minutes),
      cookMinutes: z.number().int().min(0).max(S.minutes),
      ingredients: z
        .array(
          z
            .object({
              /** The catalogue food (null: water, a free name). */
              foodId: foodIdSchema.nullable(),
              name: loc(S.ingredientName, min),
              qty: z.number().positive().max(S.maxQty).nullable(),
              unit: z.enum(ingredientUnits).nullable(),
              note: loc(S.ingredientNote, 0),
            })
            .strict(),
        )
        .min(min)
        .max(S.ingredients),
      steps: locList(S.step, S.steps, min),
      storage: loc(S.storage, 0),
      tip: loc(S.tip, 0),
      relatedArticleIds: z.array(articleRefSchema).max(S.relatedArticles),
      sources: z.array(contentSourceSchema).max(S.sources),
    })
    .strict();
}
export const recipeDraftSchema = solidsRecipeSchema(false);
export type RecipeDraft = z.infer<typeof recipeDraftSchema>;
/** Submit / publish: complete in vi and en, the step lists the same length. */
export const recipeContentSchema = solidsRecipeSchema(true).refine(
  stepsSame,
  'vi and en steps differ',
);
export type RecipeContent = z.infer<typeof recipeContentSchema>;
export { stepsSame as recipeStepsSame };

/** The common allergens a recipe contains, from its catalogue foods. */
export function recipeAllergens(
  recipe: Pick<RecipeDraft, 'ingredients'>,
  foods: ReadonlyMap<string, { allergen: FoodAllergen | null }>,
): FoodAllergen[] {
  const found = new Set<FoodAllergen>();
  for (const i of recipe.ingredients) {
    const a = i.foodId ? foods.get(i.foodId)?.allergen : null;
    if (a) found.add(a);
  }
  return foodAllergens.filter((a) => found.has(a));
}

/** `food-too-young`: ingredients whose minimum age is above the recipe's first month. */
export function recipeAgeProblems(
  recipe: Pick<RecipeDraft, 'ingredients' | 'ageMonths'>,
  foods: ReadonlyMap<string, { minAgeMonths: number }>,
): { foodId: string; minAgeMonths: number }[] {
  const out: { foodId: string; minAgeMonths: number }[] = [];
  for (const i of recipe.ingredients) {
    const f = i.foodId ? foods.get(i.foodId) : undefined;
    if (f && f.minAgeMonths > recipe.ageMonths.from) {
      out.push({ foodId: i.foodId!, minAgeMonths: f.minAgeMonths });
    }
  }
  return out;
}

// ---------- Safe copy (P-164 #10) ----------

/** Seasonings a recipe for a baby never adds (WHO, NHS: no added salt or sugar). */
export const solidsSeasonings = [
  'muối',
  'đường',
  'nước mắm',
  'hạt nêm',
  'bột nêm',
  'bột canh',
  'bột ngọt',
  'mì chính',
  'nước tương',
  'xì dầu',
  'dầu hào',
  'mật ong',
  'salt',
  'sugar',
  'fish sauce',
  'stock cube',
  'msg',
  'soy sauce',
  'oyster sauce',
  'honey',
] as const;

/** Negations that make a seasoning phrase safe ("không nêm muối", "no added salt", "do not add sugar"). */
const negated = String.raw`(?<!(?:không|đừng|chưa|không cần|no|without|don't|do not|never)\s)`;
const viSeasoning = String.raw`(?:muối|đường|nước mắm|hạt nêm|bột nêm|bột canh|bột ngọt|mì chính|nước tương|xì dầu|dầu hào|mật ong)`;
const viAmount = String.raw`(?:(?:một|1|nửa)\s+)?(?:chút|chút xíu|ít|tí|tẹo|xíu|nhúm|giọt|vài giọt|thìa(?:\s+cà phê)?)\s+`;
const enSeasoning = String.raw`(?:salt|sugar|honey|fish sauce|soy sauce|oyster sauce|stock(?: cube)?|msg)`;
const enAmount = String.raw`(?:(?:a|one|1|half a)\s+)?(?:pinch|dash|drop|few drops|little|bit|touch|splash|teaspoon|tsp|tablespoon|tbsp|spoon)(?:\s+of)?\s+|some\s+`;
/**
 * Adding a seasoning, in any of the usual phrasings ("nêm chút nước mắm", "thêm một ít đường",
 * "nêm nếm vừa ăn", "add a pinch of salt", "season to taste"), unless negated.
 */
const seasoningActions = [
  String.raw`(?:nêm|thêm|cho|rắc|chấm)(?:\s+thêm)?\s+(?:${viAmount})?${viSeasoning}`,
  String.raw`nêm(?:\s+nếm)?(?:\s+cho)?\s+vừa(?:\s+(?:ăn|miệng))?`,
  String.raw`nêm nếm`,
  String.raw`\b(?:add(?:ed|ing)?|sprinkle|stir in|mix in|season with)\s+(?:${enAmount})?${enSeasoning}`,
  String.raw`\b(?:a\s+)?(?:pinch|dash)\s+of\s+(?:salt|sugar)`,
  String.raw`\b(?:salt|sugar|season(?:ing)?)\s+to taste`,
  String.raw`\bseason with\b`,
].map((a) => new RegExp(`${negated}${a}`, 'iu'));

export interface SolidsCopyProblem {
  /** Dotted path of the field ("ingredients.2.name.vi"). */
  path: string;
  /** A forbidden word or a dose (as nutrition), or an added seasoning. */
  problem: 'forbidden' | 'dose' | 'disclaimer' | 'seasoning';
  match: string;
}

/**
 * Words and doses the copy never uses (`nutritionCopyProblems`), plus, for recipes, a seasoning
 * listed as an ingredient or an instruction to add one.
 */
export function solidsCopyProblems(data: unknown): SolidsCopyProblem[] {
  const out: SolidsCopyProblem[] = [...nutritionCopyProblems(data)];
  const recipe = data as Partial<RecipeDraft> | null;
  recipe?.ingredients?.forEach((i, n) => {
    for (const lang of ['vi', 'en'] as const) {
      const name = i?.name?.[lang]?.normalize('NFC').toLowerCase().trim() ?? '';
      const hit = solidsSeasonings.find(
        (w) => name === w || name.startsWith(`${w} `) || name.endsWith(` ${w}`),
      );
      if (hit)
        out.push({ path: `ingredients.${n}.name.${lang}`, problem: 'seasoning', match: hit });
    }
  });
  const visit = (v: unknown, path: string[]) => {
    if (typeof v === 'string') {
      if (path[0] === 'sources' || path[0] === 'ingredients') return;
      const value = v.normalize('NFC');
      for (const action of seasoningActions) {
        const m = value.match(action);
        if (m) {
          out.push({ path: path.join('.'), problem: 'seasoning', match: m[0] });
          break;
        }
      }
    } else if (Array.isArray(v)) v.forEach((x, i) => visit(x, [...path, String(i)]));
    else if (v && typeof v === 'object') {
      for (const [k, x] of Object.entries(v)) visit(x, [...path, k]);
    }
  };
  visit(data, []);
  return out;
}

// ---------- Per baby ----------

/** `babies/{babyId}/solids/settings` (5a; Cùng nuôi write, members who read care read it). */
export const solidsSettingsSchema = z
  .object({
    enabled: z.boolean(),
    /** The first meal's date, editable (`YYYY-MM-DD`). */
    startedOn: z.iso.date().nullable(),
    /** "Hiện “Ăn dặm hôm nay” trên Hôm nay". */
    showOnToday: z.boolean(),
    method: z.enum(feedingMethods),
    /** "Không gợi ý món này". */
    hidden: z.array(foodIdSchema).max(S.hidden),
    /** "Bác sĩ đã cho ăn lại": foods with past symptoms that may be suggested again. */
    cleared: z.array(foodIdSchema).max(S.hidden),
    updatedAt: z.date(),
    updatedBy: z.string(),
  })
  .strict();
export type SolidsSettings = z.infer<typeof solidsSettingsSchema>;

export const mealAmountSchema = z.union([
  z.object({ preset: z.enum(mealAmountPresets) }).strict(),
  z
    .object({
      value: z.number().positive().max(S.amountMax),
      unit: z.enum(mealAmountUnits),
    })
    .strict(),
]);

const mealAuthorSchema = z
  .object({
    name: z.string(),
    relation: z.string(),
    relationCustom: z.string().nullable(),
  })
  .strict();

/** `babies/{babyId}/meals/{mealId}` (5c). Timestamps are Firestore timestamps (dates here). */
export const mealSchema = z
  .object({
    id: mealIdSchema,
    babyId: z.string(),
    occurredAt: z.date(),
    slot: z.enum(mealSlots),
    dish: text(S.mealDish, 0),
    foodIds: z.array(foodIdSchema).max(S.mealFoods),
    freeFoods: z.array(text(S.freeName, 1)).max(S.mealFree),
    amount: mealAmountSchema.nullable(),
    reaction: z.enum(mealReactions).nullable(),
    symptoms: z.array(z.enum(mealSymptoms)).max(mealSymptoms.length),
    note: text(S.mealNote, 0),
    /** The recipe it was cooked from (`rcp_…` or the family's own `fr_…`, D-086). */
    recipeId: mealRecipeRefSchema.nullable(),
    /** `babies/{babyId}/meals/{file}.jpg` in Storage (owner: photos allowed, D-085 #2). */
    photoPath: z.string().max(200).nullable(),
    createdBy: z.string(),
    /** "Mẹ ghi" / "Cô Lan ghi": the writer's own membership (as care records). */
    author: mealAuthorSchema,
    createdAt: z.date(),
    clientCreatedAt: z.date(),
    updatedAt: z.date(),
    updatedBy: z.string(),
    deleted: z.boolean(),
    deletedAt: z.date().nullable(),
    deletedBy: z.string().nullable(),
  })
  .strict()
  .refine(
    (m) => m.dish.trim() !== '' || m.foodIds.length > 0 || m.freeFoods.length > 0,
    'A meal needs a dish or an ingredient',
  );
export type Meal = z.infer<typeof mealSchema>;

/**
 * `babies/{babyId}/recipes/{familyRecipeId}`: "Công thức nhà mình" (D-086), written by whoever
 * logs care for the baby (Cùng nuôi, Người chăm sóc) like meals: client ids, soft delete, the
 * 30-day bin; caregivers edit their own. The family's own text, so it is never blocked like
 * editorial copy: the app only nudges (honey under 12 months, added seasonings, choking notes).
 */
export const familyRecipeSchema = z
  .object({
    id: familyRecipeIdSchema,
    babyId: z.string(),
    title: text(S.familyTitle, 1),
    /** `babies/{babyId}/recipes/{file}.jpg` in Storage. */
    photoPath: z.string().max(200).nullable(),
    ingredients: z
      .array(
        z
          .object({
            foodId: foodIdSchema.nullable(),
            name: text(S.ingredientName, 1),
            qty: z.number().positive().max(S.maxQty).nullable(),
            unit: z.enum(ingredientUnits).nullable(),
          })
          .strict(),
      )
      .max(S.familyIngredients),
    steps: z.array(text(S.familyStep, 1)).max(S.familySteps),
    note: text(S.familyNote, 0),
    createdBy: z.string(),
    author: mealAuthorSchema,
    createdAt: z.date(),
    clientCreatedAt: z.date(),
    updatedAt: z.date(),
    updatedBy: z.string(),
    deleted: z.boolean(),
    deletedAt: z.date().nullable(),
    deletedBy: z.string().nullable(),
  })
  .strict()
  .refine((r) => r.ingredients.length > 0, 'A recipe needs at least one ingredient');
export type FamilyRecipe = z.infer<typeof familyRecipeSchema>;

// ---------- Pure helpers (mirrored in the app) ----------

/** The Care tile and 5a by age: "Từ 6 tháng" · "Sắp đến lúc ăn dặm" · ready. */
export function solidsAgeState(months: number): 'tooYoung' | 'soon' | 'ready' {
  if (months >= S.startMonths) return 'ready';
  return months >= S.soonMonths ? 'soon' : 'tooYoung';
}

/** 5c preselects the slot from the local time: Sáng 5–10 · Trưa 10–14 · Chiều 14–17 · Tối 17–21 · else Phụ. */
export function slotForTime(hour: number): MealSlot {
  if (hour >= 5 && hour < 10) return 'morning';
  if (hour >= 10 && hour < 14) return 'noon';
  if (hour >= 14 && hour < 17) return 'afternoon';
  if (hour >= 17 && hour < 21) return 'evening';
  return 'snack';
}
