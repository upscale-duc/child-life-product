import { randomUUID } from 'node:crypto';
import { contentFoodSchema, contentRecipeSchema, editorialChecks } from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  contentAct,
  contentItem,
  contentList,
  contentSave,
  contentSeed,
  type ContentLibraryDeps,
} from '../functions/src/content-library.js';
import { seedFoods, seedRecipes } from '../functions/src/solids-catalog-seed.js';
import type { Staff } from '../functions/src/staff.js';
import {
  eggFixture,
  foodFixture,
  milkFixture,
  recipeFixture,
} from '../functions/test/solids-fixtures.js';

// Ăn dặm (D-085, P-164 #8–#10; plan §6, §10 #8) on the editorial workflow against the Firestore
// emulator: save → submit → approve → publish for foods and recipes, the `food-too-young`,
// `unsafe-copy` and `link-missing` gates, the Thực phẩm / Công thức lists with their coverage and
// allergens, the review queue and the catalogue seed. Its own project.
const projectId = 'demo-child-life-content-solids';
let app: App;
let db: Firestore;
const now = new Date('2026-10-19T03:00:00Z');

const ops: Staff = { uid: 's_ops', name: 'Hà Vũ', roles: ['ops'] };
const expert: Staff = { uid: 's_expert', name: 'BS. Lan', roles: ['expert'] };
const support: Staff = { uid: 's_support', name: 'Mai', roles: ['support'] };

const deps = (requireReview = false): ContentLibraryDeps => ({
  requireReview,
  images: {
    exists: async () => false,
    save: async () => undefined,
    list: async () => [],
    publicUrl: (i) => `https://img.test/${i}`,
    encode: async (bytes) => Buffer.from(bytes),
  },
});
const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason,
  );
const checks = [...editorialChecks];
type Kind = 'food' | 'recipe' | 'article';

async function save(kind: Kind, data: unknown, id: string | null = null, by: Staff = ops) {
  const r = await contentSave(
    db,
    deps(),
    by,
    { kind, id, data, reviewerLabel: 'BS. Hà · Dinh dưỡng', notes: '' },
    now,
  );
  return r.id;
}
const act = (by: Staff, kind: Kind, id: string, action: string, extra = {}) =>
  contentAct(db, deps(), by, { kind, id, action, reason: '', ...extra }, now);
const approveIt = async (kind: Kind, id: string) => {
  await act(ops, kind, id, 'submit');
  return act(expert, kind, id, 'approve', { checks });
};
const publishIt = async (kind: Kind, id: string) => {
  await approveIt(kind, id);
  return act(expert, kind, id, 'publish');
};
/** A draft food under a readable id (as "Nhập bản nháp mẫu" would import it). */
const draftFood = async (id: string, data = foodFixture()) => {
  const fresh = await save('food', data);
  const snap = await db.doc(`contentDrafts/${fresh}`).get();
  await db.doc(`contentDrafts/${id}`).set(snap.data()!);
  await db.doc(`contentDrafts/${fresh}`).delete();
  return id;
};
/** A food straight to the app under [id]. */
const liveFood = async (id: string, data = foodFixture()) => {
  await draftFood(id, data);
  await publishIt('food', id);
  return id;
};

beforeAll(() => {
  app = initializeApp({ projectId }, `content-solids-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  for (const c of [
    'contentDrafts',
    'contentFoods',
    'contentRecipes',
    'contentArticles',
    'staffAudit',
  ]) {
    await db.recursiveDelete(db.collection(c));
  }
  await db.doc('config/content').delete();
});

describe('workflow', () => {
  it('a food and then a recipe go Nháp → Gửi duyệt → Duyệt → Xuất bản to the app', async () => {
    const food = await save('food', foodFixture());
    expect(food).toMatch(/^fd_[a-f0-9]{8}$/);
    await act(ops, 'food', food, 'submit');
    // Two people (D-058) as for every kind.
    expect(
      await reason(act({ ...expert, uid: ops.uid }, 'food', food, 'approve', { checks })),
    ).toBe('same-person');
    await act(expert, 'food', food, 'approve', { checks });
    expect(await act(expert, 'food', food, 'publish')).toEqual({
      status: 'published',
      revision: 1,
    });
    const pubFood = contentFoodSchema.parse((await db.doc(`contentFoods/${food}`).get()).data());
    expect(pubFood).toMatchObject({ id: food, status: 'published', group: 'vegetable' });

    const recipe = await save('recipe', recipeFixture([food, null]));
    expect(recipe).toMatch(/^rcp_[a-f0-9]{8}$/);
    expect(await reason(publishIt('recipe', recipe))).toBe('ok');
    const pub = contentRecipeSchema.parse((await db.doc(`contentRecipes/${recipe}`).get()).data());
    expect(pub).toMatchObject({
      id: recipe,
      revision: 1,
      illustrative: true,
      ageMonths: { from: 6, to: 9 },
    });
    const item = await contentItem(db, support, { kind: 'recipe', id: recipe }, now);
    expect(item.row).toMatchObject({
      kind: 'recipe',
      status: 'published',
      title: { vi: 'Cháo bí đỏ', en: 'Pumpkin congee' },
      foodIds: [food],
      allergens: [],
      live: { revision: 1 },
    });
    await act(expert, 'recipe', recipe, 'unpublish', { reason: 'Sửa định lượng' });
    expect((await db.doc(`contentRecipes/${recipe}`).get()).exists).toBe(false);
  });

  it('prod needs the qualified review; incomplete drafts save but cannot be submitted', async () => {
    const food = await save('food', eggFixture());
    await act(ops, 'food', food, 'submit');
    const prod = (action: string, extra = {}) =>
      contentAct(
        db,
        deps(true),
        expert,
        { kind: 'food', id: food, action, reason: '', ...extra },
        now,
      );
    expect(await reason(prod('approve', { checks }))).toBe('review-required');
    const review = { reviewer: 'BS. Thu Hà', credential: 'Dinh dưỡng', reviewedOn: '2026-10-18' };
    await prod('approve', { checks, review });
    await prod('publish');
    expect((await db.doc(`contentFoods/${food}`).get()).get('illustrative')).toBe(false);

    const half = { ...recipeFixture([food]), title: { vi: 'Cháo trứng', en: '' } };
    const id = await save('recipe', half);
    expect(await reason(act(ops, 'recipe', id, 'submit'))).toBe('invalid-content');
    expect(await reason(save('food', foodFixture(), 'rcp_wrong_kind'))).toBe('malformed');
    expect(await reason(save('food', foodFixture({ minAgeMonths: 4 })))).toBe('malformed');
  });
});

describe('food-too-young (P-164 #10)', () => {
  it('a 6-month recipe with honey or cow’s milk is refused at Gửi duyệt (§10 #8)', async () => {
    await liveFood(
      'fd_honey',
      foodFixture({ name: { vi: 'Mật ong', en: 'Honey' }, minAgeMonths: 12 }),
    );
    const honey = recipeFixture(['fd_honey', null]);
    honey.ingredients[0]!.name = { vi: 'Mật ong', en: 'Honey' };
    const a = await save('recipe', honey);
    expect(await reason(act(ops, 'recipe', a, 'submit'))).toBe('food-too-young');
    expect((await db.doc(`contentDrafts/${a}`).get()).get('status')).toBe('draft');

    await liveFood('fd_milk', milkFixture());
    const b = await save('recipe', recipeFixture(['fd_milk']));
    expect(await reason(act(ops, 'recipe', b, 'submit'))).toBe('food-too-young');
    // From 12 months it is fine.
    const c = await save('recipe', recipeFixture(['fd_milk'], 12, 24));
    expect(await reason(publishIt('recipe', c))).toBe('ok');
  });

  it('reads the latest food data: a raised draft age counts, a lowered one waits', async () => {
    await liveFood('fd_egg', eggFixture());
    const r = await save('recipe', recipeFixture(['fd_egg']));
    await act(ops, 'recipe', r, 'submit');
    // The food is edited (draft) to 8 months: approving the 6-month recipe is refused.
    await save('food', { ...eggFixture(), minAgeMonths: 8 }, 'fd_egg');
    expect(await reason(act(expert, 'recipe', r, 'approve', { checks }))).toBe('food-too-young');
    // Back to 6 in the draft: approve; then a later edit blocks Xuất bản.
    await save('food', eggFixture(), 'fd_egg');
    await act(expert, 'recipe', r, 'approve', { checks });
    await save('food', { ...eggFixture(), minAgeMonths: 9 }, 'fd_egg');
    expect(await reason(act(expert, 'recipe', r, 'publish'))).toBe('food-too-young');
    expect((await db.doc(`contentRecipes/${r}`).get()).exists).toBe(false);

    // Published at 12, a draft lowering it to 6 does not unlock a 6-month recipe before review.
    await liveFood('fd_milk', milkFixture());
    await save('food', { ...milkFixture(), minAgeMonths: 6 }, 'fd_milk');
    const m = await save('recipe', recipeFixture(['fd_milk']));
    expect(await reason(act(ops, 'recipe', m, 'submit'))).toBe('food-too-young');
  });
});

describe('unsafe-copy (P-164 #10)', () => {
  it('an added seasoning, a dose or a condition word blocks Gửi duyệt; sources may cite anything', async () => {
    await liveFood('fd_pumpkin');
    const salted = recipeFixture(['fd_pumpkin']);
    salted.steps.vi[1] = 'Nấu cháo nhừ, nêm muối cho vừa.';
    const a = await save('recipe', salted);
    expect(await reason(act(ops, 'recipe', a, 'submit'))).toBe('unsafe-copy');

    const sauce = recipeFixture(['fd_pumpkin', null]);
    sauce.ingredients[1]!.name = { vi: 'Nước mắm', en: 'Fish sauce' };
    const b = await save('recipe', sauce);
    expect(await reason(act(ops, 'recipe', b, 'submit'))).toBe('unsafe-copy');

    const dosed = foodFixture();
    dosed.prep[0]!.text.en = 'Give 10 mg of iron a day.';
    const c = await save('food', dosed);
    expect(await reason(act(ops, 'food', c, 'submit'))).toBe('unsafe-copy');

    const cited = recipeFixture(['fd_pumpkin']);
    cited.sources = [{ label: 'NHS: no added salt or sugar', url: 'https://www.nhs.uk/' }];
    const d = await save('recipe', cited);
    expect(await reason(act(ops, 'recipe', d, 'submit'))).toBe('ok');
  });

  it('Duyệt and Xuất bản check again (a draft changed outside the portal)', async () => {
    const id = await save('food', foodFixture());
    await act(ops, 'food', id, 'submit');
    await db.doc(`contentDrafts/${id}`).update({ 'data.prep.0.text.vi': 'Thêm đường cho dễ ăn.' });
    expect(await reason(act(expert, 'food', id, 'approve', { checks }))).toBe('unsafe-copy');
    await db.doc(`contentDrafts/${id}`).update({ 'data.prep.0.text.vi': 'Hấp chín, nghiền.' });
    await act(expert, 'food', id, 'approve', { checks });
    await db.doc(`contentDrafts/${id}`).update({ 'data.chokingNote.en': 'Add salt sparingly.' });
    expect(await reason(act(expert, 'food', id, 'publish'))).toBe('unsafe-copy');
    expect((await db.doc(`contentFoods/${id}`).get()).exists).toBe(false);
  });
});

describe('link-missing', () => {
  it('Gửi duyệt needs every food and guide to exist (not archived)', async () => {
    const missing = await save('recipe', recipeFixture(['fd_missing_one']));
    expect(await reason(act(ops, 'recipe', missing, 'submit'))).toBe('link-missing');
    const archived = await draftFood('fd_old');
    await act(ops, 'food', archived, 'archive');
    const r = await save('recipe', recipeFixture([archived]));
    expect(await reason(act(ops, 'recipe', r, 'submit'))).toBe('link-missing');
    await draftFood('fd_pumpkin');
    const guide = await save(
      'recipe',
      recipeFixture(['fd_pumpkin'], 6, 9, {
        relatedArticleIds: ['art_missing'],
      }),
    );
    expect(await reason(act(ops, 'recipe', guide, 'submit'))).toBe('link-missing');
    // A draft food is enough to submit and approve.
    const ok = await save('recipe', recipeFixture(['fd_pumpkin']));
    expect(await reason(approveIt('recipe', ok))).toBe('ok');
  });

  it('Xuất bản needs every food and guide on the app', async () => {
    await draftFood('fd_pumpkin');
    await db
      .doc('contentDrafts/art_first_meals')
      .set({ kind: 'article', status: 'draft', data: {} });
    const r = await save(
      'recipe',
      recipeFixture(['fd_pumpkin'], 6, 9, {
        relatedArticleIds: ['art_first_meals'],
      }),
    );
    await approveIt('recipe', r);
    expect(await reason(act(expert, 'recipe', r, 'publish'))).toBe('link-missing');
    await publishIt('food', 'fd_pumpkin');
    expect(await reason(act(expert, 'recipe', r, 'publish'))).toBe('link-missing');
    await db.doc('contentArticles/art_first_meals').set({ status: 'published' });
    expect(await reason(act(expert, 'recipe', r, 'publish'))).toBe('ok');
  });
});

type ListOut = {
  rows: Array<Record<string, unknown> & { id: string; kind: string }>;
  counts: Record<string, unknown>;
  coverage?: Record<string, unknown> & { bands?: Array<Record<string, unknown>> };
};
const list = async (view: string) =>
  (await contentList(db, deps(), support, { view }, now)) as unknown as ListOut;

describe('lists, coverage and the queue', () => {
  it('Thực phẩm rows and coverage: groups, allergens, iron', async () => {
    await liveFood('fd_egg', eggFixture());
    await draftFood('fd_pumpkin');
    await draftFood(
      'fd_peanut',
      foodFixture({ name: { vi: 'Lạc', en: 'Peanut' }, group: 'legumeNut', allergen: 'peanut' }),
    );
    const foods = await list('food');
    expect(foods.counts).toMatchObject({ inApp: 1, drafts: 2, total: 3 });
    expect(foods.rows.find((r) => r.id === 'fd_egg')).toMatchObject({
      title: { vi: 'Trứng gà', en: 'Egg' },
      group: 'animalProtein',
      allergen: 'egg',
      ironRich: true,
      minAgeMonths: 6,
      suggest: true,
      priority: 70,
      prep: 1,
      synonyms: { vi: [], en: [] },
      live: { revision: 1 },
    });
    expect(foods.rows.find((r) => r.id === 'fd_pumpkin')).toMatchObject({
      synonyms: { vi: ['bí ngô'], en: ['squash'] },
      synonymCount: 1,
    });
    expect(foods.coverage).toMatchObject({
      total: 3,
      published: 1,
      allergens: { total: 9, covered: 2, published: 1 },
      ironRich: { total: 1, published: 1 },
    });
  });

  it('Công thức rows with allergens and age problems; recipes per age band', async () => {
    await liveFood('fd_egg', eggFixture());
    await liveFood('fd_milk', milkFixture());
    await liveFood('fd_pumpkin');
    const a = await save('recipe', recipeFixture(['fd_egg', 'fd_pumpkin'], 6, 12));
    await publishIt('recipe', a);
    const b = await save('recipe', recipeFixture(['fd_milk', 'fd_egg'], 6, 9));
    const c = await save('recipe', recipeFixture(['fd_milk'], 12, 24));
    await act(ops, 'recipe', c, 'submit');
    const recipes = await list('recipe');
    expect(recipes.rows.find((r) => r.id === a)).toMatchObject({
      ageMonths: { from: 6, to: 12 },
      ageLabel: { from: 6, to: 11 },
      texture: 'smooth',
      methods: ['spoon'],
      servings: 2,
      prepMinutes: 10,
      cookMinutes: 25,
      ingredients: 2,
      ingredientNames: [
        { vi: 'Món 1', en: 'Food 1' },
        { vi: 'Món 2', en: 'Food 2' },
      ],
      foodIds: ['fd_egg', 'fd_pumpkin'],
      allergens: ['egg'],
      ageProblems: [],
    });
    expect(recipes.rows.find((r) => r.id === b)).toMatchObject({
      allergens: ['egg', 'milk'],
      ageProblems: [{ foodId: 'fd_milk', minAgeMonths: 12 }],
    });
    const bands = recipes.coverage!.bands!;
    expect(bands[0]).toMatchObject({ published: 1, draft: 1, total: 2, target: 6, met: false });
    expect(bands[1]).toMatchObject({ published: 1, total: 1 });
    expect(bands[2]).toMatchObject({ pending: 1, total: 1 });
    expect(recipes.coverage).toMatchObject({ ready: false, total: 3, published: 1 });
  });

  it('the review queue lists foods and recipes and counts them per kind', async () => {
    const food = await save('food', foodFixture());
    await act(ops, 'food', food, 'submit');
    await liveFood('fd_egg', eggFixture());
    const recipe = await save('recipe', recipeFixture(['fd_egg']));
    await approveIt('recipe', recipe);
    const q = (await contentList(db, deps(), expert, { view: 'queue' }, now)) as unknown as {
      rows: Array<{ id: string; kind: string }>;
      counts: Record<string, { inReview: number; approved: number }>;
      available: string[];
    };
    expect(q.rows.map((r) => r.kind).sort()).toEqual(['food', 'recipe']);
    expect(q.counts.food).toMatchObject({ inReview: 1 });
    expect(q.counts.recipe).toMatchObject({ approved: 1 });
    expect(q.available).toEqual(expect.arrayContaining(['food', 'recipe']));
  });

  it('imports the catalogue drafts once, as Nháp, and audits without content text', async () => {
    const sizes = { food: seedFoods.length, recipe: seedRecipes.length };
    const added = Object.fromEntries(Object.entries(sizes).filter(([, n]) => n > 0));
    const total = sizes.food + sizes.recipe;
    expect(await contentSeed(db, ops, { kinds: ['food', 'recipe'] }, now)).toEqual({
      added,
      skipped: 0,
    });
    expect(await contentSeed(db, ops, { kinds: ['food', 'recipe'] }, now)).toEqual({
      added: {},
      skipped: total,
    });
    const id = await save('food', eggFixture());
    await publishIt('food', id);
    const audit = await db.collection('staffAudit').get();
    expect(audit.docs.map((d) => d.get('action') as string)).toEqual(
      expect.arrayContaining(['content.food.save', 'content.food.submit', 'content.food.publish']),
    );
    expect(JSON.stringify(audit.docs.map((d) => d.data()))).not.toContain('Trứng gà');
  });
});
