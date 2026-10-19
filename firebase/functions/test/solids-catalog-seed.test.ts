import {
  foodAllergens,
  foodContentSchema,
  foodGroups,
  foodIdSchema,
  isPlainText,
  literalEmergencyProblems,
  recipeAgeProblems,
  recipeContentSchema,
  recipeIdSchema,
  solidsCopyProblems,
} from '@child-life/contracts';
import { describe, expect, it } from 'vitest';
import { seedArticles } from '../src/content-seed.js';
import { seedFoods, seedRecipes } from '../src/solids-catalog-seed.js';

// The Ăn dặm catalogue and recipes (D-085, P-164; plan §3 #8–#10, §7, §8) that "Nhập bản nháp
// mẫu" imports: publishable as they are (strict schemas, the server's `unsafe-copy` and
// `food-too-young` gates find nothing), ids unique, links that resolve, the coverage the
// suggestions need (every group and allergen suggestable, enough iron-rich foods), recipes for
// every age band, plain text and no claimed review.

const foods = new Map(seedFoods.map((f) => [f.id, f.data]));
const articleIds = new Set(seedArticles.map((a) => a.id));
const REVIEWER = 'Nhóm chuyên môn · Dinh dưỡng nhi';
const reviewClaim =
  /đã được (bác sĩ|chuyên gia|chuyên môn)|kiểm duyệt bởi|đã duyệt|reviewed by|approved by/i;
/** Markdown or links in copy: emphasis, code, headings, quotes, list markers, [text](url), URLs. */
const markup = /\*\*|__|`|^\s*(#|>|[-*+]\s)|\[[^\]]*\]\(|https?:\/\/|www\./im;

/** Every string in [value] with its dotted path, sources left out (they cite pages by URL). */
function strings(value: unknown, path = ''): { path: string; s: string }[] {
  if (typeof value === 'string') return [{ path, s: value }];
  if (Array.isArray(value)) return value.flatMap((v, i) => strings(v, `${path}.${i}`));
  if (value && typeof value === 'object') {
    return Object.entries(value)
      .filter(([k]) => k !== 'sources')
      .flatMap(([k, v]) => strings(v, path ? `${path}.${k}` : k));
  }
  return [];
}

function checkCopy(id: string, data: unknown) {
  expect(solidsCopyProblems(data), id).toEqual([]);
  for (const { path, s } of strings(data)) {
    expect(isPlainText(s), `${id} ${path} plain`).toBe(true);
    expect(s, `${id} ${path} no markdown or URL`).not.toMatch(markup);
    expect(s, `${id} ${path} one line`).not.toMatch(/[\n\r\t]/);
    expect(s, `${id} ${path} trimmed`).toBe(s.trim());
    expect(s, `${id} ${path} NFC`).toBe(s.normalize('NFC'));
    expect(s, `${id} ${path} claims a review`).not.toMatch(reviewClaim);
  }
}

describe('solids catalogue seed: ids and review', () => {
  it('about 120 foods and at least 30 recipes, ids unique and matching the id schemas', () => {
    expect(seedFoods.length).toBeGreaterThanOrEqual(110);
    expect(seedRecipes.length).toBeGreaterThanOrEqual(30);
    const all = [...seedFoods, ...seedRecipes].map((x) => x.id);
    expect(new Set(all).size).toBe(all.length);
    for (const f of seedFoods) expect(foodIdSchema.safeParse(f.id).success, f.id).toBe(true);
    for (const r of seedRecipes) expect(recipeIdSchema.safeParse(r.id).success, r.id).toBe(true);
  });

  it('names the expected reviewer and never claims a review', () => {
    for (const x of [...seedFoods, ...seedRecipes]) {
      expect(x.reviewerLabel, x.id).toBe(REVIEWER);
      for (const { s } of strings(x.data)) expect(s, x.id).not.toMatch(reviewClaim);
    }
  });
});

describe('solids catalogue seed: foods', () => {
  it.each(seedFoods.map((f) => [f.id, f] as const))('%s is publishable', (id, f) => {
    const parsed = foodContentSchema.safeParse(f.data);
    expect(parsed.success, JSON.stringify(parsed.error?.issues.slice(0, 3))).toBe(true);
    checkCopy(id, f.data);
    const textures = f.data.prep.map((p) => p.texture);
    expect(new Set(textures).size, `${id} one note per texture`).toBe(textures.length);
    // Suggestable foods say how to prepare them.
    if (f.data.suggest) expect(textures.length, `${id} prep`).toBeGreaterThan(0);
  });

  it('every group and every common allergen has a suggestable food from 6 months', () => {
    const suggestable = seedFoods
      .map((f) => f.data)
      .filter((f) => f.suggest && f.minAgeMonths === 6);
    for (const g of foodGroups) {
      expect(
        suggestable.some((f) => f.group === g),
        g,
      ).toBe(true);
    }
    for (const a of foodAllergens) {
      expect(
        suggestable.some((f) => f.allergen === a),
        a,
      ).toBe(true);
    }
  });

  it('at least 20 suggestable iron-rich foods', () => {
    const iron = seedFoods.filter((f) => f.data.ironRich && f.data.suggest);
    expect(iron.length).toBeGreaterThanOrEqual(20);
  });

  it('minimum ages: 6 for food, 12 for honey and milk drinks, later only for choking hazards', () => {
    expect(foods.get('fd_honey')?.minAgeMonths).toBe(12);
    expect(foods.get('fd_cow_milk_drink')?.minAgeMonths).toBe(12);
    expect(foods.get('fd_cow_milk_drink')?.name.vi).toBe('Sữa tươi (uống)');
    expect(foods.get('fd_yogurt')?.minAgeMonths).toBe(6);
    expect(foods.get('fd_cheese')?.minAgeMonths).toBe(6);
    expect(foods.get('fd_cow_milk_cooking')?.minAgeMonths).toBe(6);
    for (const [id, f] of foods) {
      // Anything held back is never suggested, and a choking hazard says why.
      if (f.minAgeMonths > 6) expect(f.suggest, id).toBe(false);
      if (f.minAgeMonths > 12) expect(f.chokingNote.vi, id).not.toBe('');
    }
    // The classic hazards are kept for the picker but never suggested, with a note.
    for (const id of ['fd_grape', 'fd_cherry_tomato', 'fd_sausage', 'fd_popcorn', 'fd_honey']) {
      expect(foods.get(id)?.suggest, id).toBe(false);
    }
    for (const id of ['fd_grape', 'fd_cherry_tomato', 'fd_sausage', 'fd_popcorn', 'fd_carrot']) {
      expect(foods.get(id)?.chokingNote.vi, id).not.toBe('');
    }
  });

  it('nuts appear only as smooth pastes, with the choking note', () => {
    for (const f of seedFoods.filter((x) =>
      ['peanut', 'treeNut'].includes(x.data.allergen ?? ''),
    )) {
      expect(f.data.name.en, f.id).toMatch(/butter|paste/i);
      expect(f.data.chokingNote.vi, f.id).toMatch(/nguyên/);
    }
  });
});

describe('solids catalogue seed: recipes', () => {
  it.each(seedRecipes.map((r) => [r.id, r] as const))('%s is publishable and safe', (id, r) => {
    const parsed = recipeContentSchema.safeParse(r.data);
    expect(parsed.success, JSON.stringify(parsed.error?.issues.slice(0, 3))).toBe(true);
    checkCopy(id, r.data);
    // food-too-young: no ingredient above the recipe's first month.
    expect(recipeAgeProblems(r.data, foods), id).toEqual([]);
    // Every linked food exists; at least two foods are linked.
    const linked = r.data.ingredients.filter((i) => i.foodId !== null);
    expect(linked.length, `${id} links foods`).toBeGreaterThanOrEqual(2);
    for (const i of linked) expect(foods.has(i.foodId!), `${id} → ${i.foodId}`).toBe(true);
    // Related guides exist, once each.
    expect(r.data.relatedArticleIds.length, `${id} related`).toBeGreaterThan(0);
    expect(new Set(r.data.relatedArticleIds).size).toBe(r.data.relatedArticleIds.length);
    for (const a of r.data.relatedArticleIds) expect(articleIds.has(a), `${id} → ${a}`).toBe(true);
    // Guidance is cited.
    expect(r.data.sources.length, `${id} sources`).toBeGreaterThan(0);
    // Texture fits the age: smooth only for the first months, family food from 12 months.
    if (r.data.texture === 'smooth') expect(r.data.ageMonths.from, id).toBeLessThanOrEqual(8);
    if (r.data.texture === 'family') expect(r.data.ageMonths.from, id).toBeGreaterThanOrEqual(12);
  });

  it("name the family's emergency number as {emergency}, never 115 (D-087)", () => {
    for (const x of [...seedFoods, ...seedRecipes]) {
      expect(literalEmergencyProblems(x.data), x.id).toEqual([]);
    }
  });

  it('at least 7 recipes start in each band 6–8, 9–11 and 12–23 months, and some at 24–36', () => {
    const band = (from: number) =>
      from <= 8 ? '6–8' : from <= 11 ? '9–11' : from <= 23 ? '12–23' : '24–36';
    const counts = new Map<string, number>();
    for (const r of seedRecipes) {
      const b = band(r.data.ageMonths.from);
      counts.set(b, (counts.get(b) ?? 0) + 1);
    }
    expect(counts.get('6–8') ?? 0).toBeGreaterThanOrEqual(7);
    expect(counts.get('9–11') ?? 0).toBeGreaterThanOrEqual(7);
    expect(counts.get('12–23') ?? 0).toBeGreaterThanOrEqual(7);
    expect(counts.get('24–36') ?? 0).toBeGreaterThanOrEqual(3);
  });
});
