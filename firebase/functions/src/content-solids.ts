import { randomBytes } from 'node:crypto';
import {
  contentCollections,
  contentDraftsCollection,
  contentFoodSchema,
  contentRecipeSchema,
  foodAllergens,
  foodContentSchema,
  foodDraftSchema,
  foodGroups,
  foodIdSchema,
  nutritionAgeLabel,
  nutritionAgesOverlap,
  recipeAgeProblems,
  recipeAllergens,
  recipeContentSchema,
  recipeDraftSchema,
  recipeIdSchema,
  solidsAgeSchema,
  solidsCopyProblems,
  solidsLimits,
  type EditorialStatus,
  type FoodAllergen,
  type FoodGroup,
  type SolidsAge,
} from '@child-life/contracts';
import type {
  DocumentReference,
  DocumentSnapshot,
  Firestore,
  Transaction,
} from 'firebase-admin/firestore';
import type { ContentGateStep, ContentKindAdapter } from './content-library.js';
import { seedFoods, seedRecipes } from './solids-catalog-seed.js';
import { StaffError } from './staff.js';

/**
 * Ăn dặm (D-085, P-164; plan `docs/product/solids-plan.md` §3 #8–#10, §6) on the editorial
 * workflow of `content-library.ts`: the food catalogue (`fd_…` → contentFoods) and recipes
 * (`rcp_…` → contentRecipes). Besides the common workflow the kinds are gated (P-164 #10):
 * - `food-too-young`: a recipe is refused on Gửi duyệt, Duyệt and Xuất bản while it starts below an
 *   ingredient's `minAgeMonths` (`recipeAgeProblems`), read from the food's latest data: the
 *   stricter of its draft and its published revision (checked first);
 * - `unsafe-copy`: Gửi duyệt (and, defensively, Duyệt / Xuất bản) is refused while any text holds
 *   a forbidden word, a dose or, for recipes, an added seasoning (`solidsCopyProblems`);
 * - `link-missing`: a recipe naming a food or a guide that does not exist (Gửi duyệt) or is not on
 *   the app (Xuất bản).
 * The portal lists get the coverage of §6: recipes per age band (6–8 · 9–11 · 12–23 · 24–36, at
 * least 6 on the app per band), foods per group, the common allergens covered and iron-rich foods.
 */

type Data = Record<string, unknown>;
type Loc = { vi: string; en: string };
const count = (xs: unknown) => (Array.isArray(xs) ? xs.length : 0);
const locOf = (v: unknown): Loc | null => {
  const o = v as Partial<Loc> | null | undefined;
  return o && typeof o === 'object' ? { vi: o.vi ?? '', en: o.en ?? '' } : null;
};
const ageOf = (v: unknown): SolidsAge | null => {
  const r = solidsAgeSchema.safeParse(v);
  return r.success ? r.data : null;
};
const num = (v: unknown) => (typeof v === 'number' ? v : null);
const strings = (v: unknown) =>
  Array.isArray(v) ? v.filter((x): x is string => typeof x === 'string') : [];
const seeded = (xs: readonly { id: string; reviewerLabel: string | null; data: unknown }[]) =>
  xs.map((s) => ({ id: s.id, reviewerLabel: s.reviewerLabel, data: s.data as Data }));

/** The catalogue foods a recipe names (null ingredients, e.g. water, left out), once each. */
export function recipeFoodIds(d: Data): string[] {
  const ings = Array.isArray(d.ingredients) ? (d.ingredients as Array<{ foodId?: unknown }>) : [];
  const ids = ings.map((i) => i?.foodId).filter((x): x is string => typeof x === 'string');
  return [...new Set(ids)];
}
const articleIdsOf = (d: Data) =>
  Array.isArray(d.relatedArticleIds)
    ? [...new Set((d.relatedArticleIds as unknown[]).filter((x) => typeof x === 'string'))]
    : [];

// ---------- What the gates and lists know about a food ----------

/** A catalogue food as the recipe checks see it. */
export interface FoodFacts {
  /** The stricter of the draft's and the published revision's minimum age. */
  minAgeMonths: number;
  /** The draft's (latest) allergen, else the published one. */
  allergen: FoodAllergen | null;
  /** A draft that is not archived, or a published revision. */
  exists: boolean;
  /** On the app now. */
  published: boolean;
}

type GetAll = (...refs: DocumentReference[]) => Promise<DocumentSnapshot[]>;
/** The recipe checks only read `foodId` and `ageMonths`. */
type RecipeCheck = Parameters<typeof recipeAgeProblems>[0];

/** Facts for [ids] from their drafts and published documents (unknown ids are left out). */
export async function readFoodFacts(
  getAll: GetAll,
  db: Firestore,
  ids: readonly string[],
): Promise<Map<string, FoodFacts>> {
  const want = [...new Set(ids)].filter((id) => foodIdSchema.safeParse(id).success);
  const out = new Map<string, FoodFacts>();
  if (!want.length) return out;
  const snaps = await getAll(
    ...want.map((id) => db.collection(contentDraftsCollection).doc(id)),
    ...want.map((id) => db.collection(contentCollections.food).doc(id)),
  );
  want.forEach((id, i) => {
    const facts = foodFactsOf(snaps[i], snaps[want.length + i]);
    if (facts) out.set(id, facts);
  });
  return out;
}

/** Null when there is neither a food draft nor a published food under the id. */
function foodFactsOf(
  draft: DocumentSnapshot | undefined,
  pub: DocumentSnapshot | undefined,
): FoodFacts | null {
  const d = draft?.exists && draft.get('kind') === 'food' ? (draft.get('data') as Data) : null;
  const p = pub?.exists && pub.get('status') === 'published' ? (pub.data() as Data) : null;
  if (!d && !p) return null;
  const ages = [num(d?.minAgeMonths), num(p?.minAgeMonths)].filter((x): x is number => x !== null);
  const allergen = (d ? d.allergen : p?.allergen) as FoodAllergen | null | undefined;
  return {
    minAgeMonths: ages.length ? Math.max(...ages) : solidsLimits.startMonths,
    allergen: allergen ?? null,
    exists: (!!d && draft!.get('status') !== 'archived') || !!p,
    published: !!p,
  };
}

/** Every food the portal knows (drafts and published), for the recipe list. */
export async function allFoodFacts(db: Firestore): Promise<Map<string, FoodFacts>> {
  const [drafts, pubs] = await Promise.all([
    db.collection(contentDraftsCollection).where('kind', '==', 'food').get(),
    db.collection(contentCollections.food).get(),
  ]);
  const byId = new Map<string, { draft?: DocumentSnapshot; pub?: DocumentSnapshot }>();
  for (const s of drafts.docs) byId.set(s.id, { draft: s });
  for (const s of pubs.docs) byId.set(s.id, { ...byId.get(s.id), pub: s });
  const out = new Map<string, FoodFacts>();
  for (const [id, { draft, pub }] of byId) {
    const facts = foodFactsOf(draft, pub);
    if (facts) out.set(id, facts);
  }
  return out;
}

/** Guides (articles) a recipe links to: exists (a draft not archived, or on the app) / on the app. */
async function readArticleState(getAll: GetAll, db: Firestore, ids: readonly string[]) {
  const out = new Map<string, { exists: boolean; published: boolean }>();
  if (!ids.length) return out;
  const snaps = await getAll(
    ...ids.map((id) => db.collection(contentDraftsCollection).doc(id)),
    ...ids.map((id) => db.collection(contentCollections.article).doc(id)),
  );
  ids.forEach((id, i) => {
    const draft = snaps[i];
    const pub = snaps[ids.length + i];
    const published = !!pub?.exists && pub.get('status') === 'published';
    const drafted =
      !!draft?.exists && draft.get('kind') === 'article' && draft.get('status') !== 'archived';
    out.set(id, { exists: drafted || published, published });
  });
  return out;
}

// ---------- Gates ----------

/** P-164 #10: no forbidden word, dose or added seasoning in the item's text (sources excepted). */
export function assertSolidsCopy(data: unknown) {
  if (solidsCopyProblems(data).length) throw new StaffError('failed-precondition', 'unsafe-copy');
}

/** P-164 #10: the recipe starts at or after every ingredient's minimum age. */
export function assertRecipeAge(data: Data, foods: ReadonlyMap<string, FoodFacts>) {
  const age = ageOf(data.ageMonths);
  if (!age) throw new StaffError('failed-precondition', 'invalid-content');
  const ingredients = recipeFoodIds(data).map((foodId) => ({ foodId }));
  if (recipeAgeProblems({ ingredients, ageMonths: age } as RecipeCheck, foods).length) {
    throw new StaffError('failed-precondition', 'food-too-young');
  }
}

/**
 * The recipe's foods and guides: on Gửi duyệt they must exist (a draft not archived, or on the
 * app); on Xuất bản they must be on the app, so the app never shows a link to nothing.
 */
export function assertRecipeLinks(
  step: ContentGateStep,
  data: Data,
  foods: ReadonlyMap<string, FoodFacts>,
  articles: ReadonlyMap<string, { exists: boolean; published: boolean }>,
) {
  if (step === 'approve') return;
  const ok = (x: { exists: boolean; published: boolean } | undefined) =>
    !!x && (step === 'publish' ? x.published : x.exists);
  const links = [
    ...recipeFoodIds(data).map((id) => foods.get(id)),
    ...articleIdsOf(data).map((id) => articles.get(id)),
  ];
  if (!links.every(ok)) throw new StaffError('failed-precondition', 'link-missing');
}

async function recipeGate(
  step: ContentGateStep,
  ctx: { tx: Transaction; db: Firestore; data: Data },
) {
  const { tx, db, data } = ctx;
  const getAll: GetAll = (...refs) => tx.getAll(...refs);
  const foods = await readFoodFacts(getAll, db, recipeFoodIds(data));
  // Age first: a 6-month recipe with honey is `food-too-young` (plan §10 #8), even though the
  // honey line is also a seasoning for the copy check.
  assertRecipeAge(data, foods);
  assertSolidsCopy(data);
  const articles =
    step === 'approve' ? new Map() : await readArticleState(getAll, db, articleIdsOf(data));
  assertRecipeLinks(step, data, foods, articles);
}

// ---------- Adapters ----------

export const foodAdapter: ContentKindAdapter = {
  newId: () => `fd_${randomBytes(4).toString('hex')}`,
  isId: (id) => foodIdSchema.safeParse(id).success,
  draft: foodDraftSchema,
  strict: foodContentSchema,
  published: (id, data, meta) => contentFoodSchema.parse({ id, ...data, ...meta }),
  title: (d) => locOf(d.name) ?? { vi: '', en: '' },
  /** Thực phẩm row: group, allergen, iron, minimum age, suggestion flags, other names, counts. */
  row: (d) => {
    const synonyms = d.synonyms as { vi?: unknown; en?: unknown } | null | undefined;
    const choking = locOf(d.chokingNote);
    return {
      group: (d.group as FoodGroup | undefined) ?? null,
      allergen: (d.allergen as FoodAllergen | null | undefined) ?? null,
      ironRich: d.ironRich === true,
      minAgeMonths: num(d.minAgeMonths),
      suggest: d.suggest === true,
      priority: num(d.priority),
      /** Preparation notes by texture (count), and which textures they cover. */
      prep: count(d.prep),
      prepTextures: Array.isArray(d.prep)
        ? (d.prep as Array<{ texture?: unknown }>).map((p) => p?.texture).filter(Boolean)
        : [],
      /** Other names, for the portal search and the ingredient picker. */
      synonyms: { vi: strings(synonyms?.vi), en: strings(synonyms?.en) },
      synonymCount: count(synonyms?.vi),
      hasChokingNote: !!(choking && (choking.vi.trim() || choking.en.trim())),
      sources: count(d.sources),
    };
  },
  seed: () => seeded(seedFoods),
  gate: async (_step, { data }) => assertSolidsCopy(data),
};

export const recipeAdapter: ContentKindAdapter = {
  newId: () => `rcp_${randomBytes(4).toString('hex')}`,
  isId: (id) => recipeIdSchema.safeParse(id).success,
  draft: recipeDraftSchema,
  strict: recipeContentSchema,
  published: (id, data, meta) => contentRecipeSchema.parse({ id, ...data, ...meta }),
  title: (d) => locOf(d.title) ?? { vi: '', en: '' },
  /**
   * Công thức row: age and label, texture, methods, servings, minutes, ingredients (count and
   * names), the catalogue foods. `allergens` and `ageProblems` need the foods: the list fills them (`withRecipeFoods`).
   * `links` replaces the generic (empty) one with the related guides.
   */
  row: (d) => {
    const age = ageOf(d.ageMonths);
    const steps = d.steps as { vi?: unknown[] } | null | undefined;
    const prep = num(d.prepMinutes);
    const cook = num(d.cookMinutes);
    return {
      ageMonths: age,
      ageLabel: age ? nutritionAgeLabel(age) : null,
      texture: (d.texture as string | undefined) ?? null,
      methods: Array.isArray(d.methods) ? (d.methods as string[]) : [],
      servings: num(d.servings),
      prepMinutes: prep,
      cookMinutes: cook,
      totalMinutes: prep !== null && cook !== null ? prep + cook : null,
      ingredients: count(d.ingredients),
      /** Every ingredient's name in list order (free names included), for the portal search. */
      ingredientNames: Array.isArray(d.ingredients)
        ? (d.ingredients as Array<{ name?: unknown }>).map(
            (i) => locOf(i?.name) ?? { vi: '', en: '' },
          )
        : [],
      foodIds: recipeFoodIds(d),
      allergens: [] as FoodAllergen[],
      ageProblems: [] as Array<{ foodId: string; minAgeMonths: number }>,
      steps: count(steps?.vi),
      hasCover: !!d.cover,
      links: { articles: articleIdsOf(d), milestones: [] as string[] },
      sources: count(d.sources),
    };
  },
  seed: () => seeded(seedRecipes),
  gate: (step, ctx) => recipeGate(step, ctx),
};

// ---------- Lists ----------

type ListRow = Data & { id: string; status: EditorialStatus; live: unknown };

/**
 * Recipe rows with what needs the catalogue: the common allergens (from the foods' latest data)
 * and the ingredients too old for the recipe's first month (`food-too-young` before Gửi duyệt).
 */
export function withRecipeFoods<T extends ListRow>(
  rows: readonly T[],
  foods: ReadonlyMap<string, FoodFacts>,
): T[] {
  return rows.map((r) => {
    const ingredients = ((r.foodIds as string[] | undefined) ?? []).map((foodId) => ({ foodId }));
    const age = r.ageMonths as SolidsAge | null | undefined;
    return {
      ...r,
      allergens: recipeAllergens({ ingredients } as RecipeCheck, foods),
      ageProblems: age
        ? recipeAgeProblems({ ingredients, ageMonths: age } as RecipeCheck, foods)
        : [],
    };
  });
}

/** One recipe row (the editor's item) with its foods. */
export async function recipeItemRow<T extends ListRow>(db: Firestore, row: T): Promise<T> {
  const ids = (row.foodIds as string[] | undefined) ?? [];
  const foods = await readFoodFacts((...refs) => db.getAll(...refs), db, ids);
  return withRecipeFoods([row], foods)[0]!;
}

/** The list extras of the two kinds: recipe rows with their foods, and each kind's coverage. */
export async function solidsList<T extends ListRow>(
  db: Firestore,
  view: 'food' | 'recipe',
  rows: readonly T[],
) {
  if (view === 'food') {
    return {
      rows: [...rows],
      coverage: foodCoverage(
        rows.map((r) => ({
          id: r.id,
          group: (r.group as FoodGroup | null) ?? null,
          allergen: (r.allergen as FoodAllergen | null) ?? null,
          ironRich: r.ironRich === true,
          status: r.status,
          live: !!r.live,
        })),
      ),
    };
  }
  const withFoods = withRecipeFoods(rows, await allFoodFacts(db));
  return {
    rows: withFoods,
    coverage: recipeCoverage(
      withFoods.flatMap((r) => {
        const age = r.ageMonths as SolidsAge | null;
        return age ? [{ id: r.id, ageMonths: age, status: r.status, live: !!r.live }] : [];
      }),
    ),
  };
}

// ---------- Coverage (portal §6) ----------

type ItemState = 'published' | 'pending' | 'draft';
/** On the app › waiting for review / approved › draft; archived (and off the app) counts nothing. */
function stateOf(i: { status: EditorialStatus; live: boolean }): ItemState | null {
  if (i.live) return 'published';
  if (i.status === 'in_review' || i.status === 'approved') return 'pending';
  return i.status === 'draft' ? 'draft' : null;
}

/** "Công thức theo độ tuổi": the library's age bands from 6 months (`to` exclusive). */
export const recipeBands: readonly SolidsAge[] = [
  { from: 6, to: 9 },
  { from: 9, to: 12 },
  { from: 12, to: 24 },
  { from: 24, to: 37 },
];
/** Recipes on the app per band before the tile goes live (plan §6), for 6–8 · 9–11 · 12–23. */
export const recipeBandTarget = 6;
const launchBands = 3;

export interface RecipeCoverageItem {
  id: string;
  ageMonths: SolidsAge;
  status: EditorialStatus;
  live: boolean;
}

/**
 * Recipes per age band by state. A recipe counts in every band its months overlap (the app's
 * library filter shows it there). `ready`: the first three bands each have the target on the app.
 */
export function recipeCoverage(items: readonly RecipeCoverageItem[]) {
  const counted = items.flatMap((i) => {
    const state = stateOf(i);
    return state ? [{ ...i, state }] : [];
  });
  const bands = recipeBands.map((band) => {
    const here = counted.filter((i) => nutritionAgesOverlap(i.ageMonths, band));
    const n = (s: ItemState) => here.filter((h) => h.state === s).length;
    return {
      ageMonths: band,
      ageLabel: nutritionAgeLabel(band),
      published: n('published'),
      pending: n('pending'),
      draft: n('draft'),
      total: here.length,
      target: recipeBandTarget,
      met: n('published') >= recipeBandTarget,
      itemIds: here.map((h) => h.id),
    };
  });
  return {
    target: recipeBandTarget,
    bands,
    /** Recipes counted (archived ones left out) and those on the app. */
    total: counted.length,
    published: counted.filter((i) => i.state === 'published').length,
    ready: bands.slice(0, launchBands).every((b) => b.met),
  };
}

export interface FoodCoverageItem {
  id: string;
  group: FoodGroup | null;
  allergen: FoodAllergen | null;
  ironRich: boolean;
  status: EditorialStatus;
  live: boolean;
}

/**
 * "N món theo nhóm, N món giàu sắt, 9/9 nhóm dị ứng có món": per group, per common allergen and
 * iron-rich, the foods counted (drafts included, archived left out) and those on the app.
 */
export function foodCoverage(items: readonly FoodCoverageItem[]) {
  const counted = items.filter((i) => stateOf(i) !== null);
  const live = counted.filter((i) => i.live);
  const tally = (pick: (i: FoodCoverageItem) => boolean) => ({
    total: counted.filter(pick).length,
    published: live.filter(pick).length,
  });
  const allergens = foodAllergens.map((allergen) => ({
    allergen,
    ...tally((i) => i.allergen === allergen),
  }));
  return {
    total: counted.length,
    published: live.length,
    groups: foodGroups.map((group) => ({ group, ...tally((i) => i.group === group) })),
    allergens: {
      total: foodAllergens.length,
      /** Allergens with at least one food (drafts included) / on the app. */
      covered: allergens.filter((a) => a.total > 0).length,
      published: allergens.filter((a) => a.published > 0).length,
      missing: allergens.filter((a) => a.total === 0).map((a) => a.allergen),
      liveMissing: allergens.filter((a) => a.published === 0).map((a) => a.allergen),
      byAllergen: allergens,
    },
    ironRich: tally((i) => i.ironRich),
  };
}
