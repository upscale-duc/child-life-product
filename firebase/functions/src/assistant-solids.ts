import type { Firestore } from 'firebase-admin/firestore';
import {
  contentFoodSchema,
  contentRecipeSchema,
  foldVi,
  type ContentFood,
  type ContentRecipe,
} from '@child-life/contracts';
import { toDate } from './assistant-common.js';

/** One source for Phase 2's tried-food answer and meal suggestions (D-085/086). */
export async function solidsContext(db: Firestore, babyId: string, until: Date) {
  const [meals, settings, foodDocs, recipeDocs] = await Promise.all([
    db.collection(`babies/${babyId}/meals`).where('occurredAt', '<=', until).get(),
    db.doc(`babies/${babyId}/solids/settings`).get(),
    db.collection('contentFoods').where('status', '==', 'published').get(),
    db.collection('contentRecipes').where('status', '==', 'published').get(),
  ]);
  const foods = new Map<string, ContentFood>();
  for (const d of foodDocs.docs) {
    const p = contentFoodSchema.safeParse(d.data());
    if (p.success) foods.set(d.id, p.data);
  }
  const recipes = new Map<string, ContentRecipe>();
  for (const d of recipeDocs.docs) {
    const p = contentRecipeSchema.safeParse(d.data());
    if (p.success) recipes.set(d.id, p.data);
  }
  const foodByName = new Map<string, string>();
  for (const [id, f] of foods)
    for (const name of [f.name.vi, f.name.en, ...f.synonyms.vi, ...f.synonyms.en])
      foodByName.set(foldVi(name.trim()), id);
  const cleared = new Set<string>(settings.get('cleared') ?? []);
  const hidden = new Set<string>(settings.get('hidden') ?? []);
  const tried = new Map<
    string,
    {
      name: { vi: string; en: string };
      count: number;
      symptoms: Set<string>;
      lastAt: Date;
      reaction: string | null;
    }
  >();
  const reacted = new Set<string>();
  const sourceIds: string[] = [];
  for (const d of meals.docs) {
    if (d.get('deleted') === true) continue;
    const at = toDate(d.get('occurredAt'));
    if (!at) continue;
    sourceIds.push(d.id);
    const ids: string[] = Array.isArray(d.get('foodIds')) ? d.get('foodIds') : [];
    const free: string[] = Array.isArray(d.get('freeFoods')) ? d.get('freeFoods') : [];
    const symptoms: string[] = Array.isArray(d.get('symptoms')) ? d.get('symptoms') : [];
    for (const id of new Set([
      ...ids,
      ...free.map((f) => foodByName.get(foldVi(f.trim())) ?? `free:${foldVi(f.trim())}`),
    ])) {
      const freeName = free.find((f) => `free:${foldVi(f.trim())}` === id);
      const name = foods.get(id)?.name ?? { vi: freeName ?? id, en: freeName ?? id };
      const old = tried.get(id) ?? {
        name,
        count: 0,
        symptoms: new Set<string>(),
        lastAt: at,
        reaction: null,
      };
      if (at >= old.lastAt)
        old.reaction = typeof d.get('reaction') === 'string' ? d.get('reaction') : null;
      old.count++;
      if (at > old.lastAt) old.lastAt = at;
      symptoms.forEach((s) => old.symptoms.add(s));
      tried.set(id, old);
      if (symptoms.length > 0 && !cleared.has(id)) reacted.add(id);
    }
  }
  // Exclude the whole allergen group after a reported reaction, as the solids suggestions do.
  const allergens = new Set([...reacted].flatMap((id) => foods.get(id)?.allergen ?? []));
  const excluded = new Set([...hidden, ...reacted]);
  for (const [id, f] of foods)
    if (f.allergen && allergens.has(f.allergen) && !cleared.has(id)) excluded.add(id);
  return {
    foods,
    recipes,
    tried,
    reacted,
    excluded,
    allergens,
    sourceIds,
    method: settings.get('method') as string | undefined,
  };
}

/** The older reviewed recipe pack uses ingredient slugs rather than fd_ catalogue ids. */
export function legacyReactionIngredientIds(context: {
  excluded: ReadonlySet<string>;
  allergens: ReadonlySet<string>;
  foods: ReadonlyMap<string, ContentFood>;
}): string[] {
  const keys = new Set<string>(context.allergens);
  for (const id of context.excluded) {
    keys.add(id);
    keys.add(id.replace(/^fd_|^free:/u, ''));
    const food = context.foods.get(id);
    if (food)
      for (const name of [food.name.vi, food.name.en, ...food.synonyms.vi, ...food.synonyms.en])
        keys.add(foldVi(name.trim()).replace(/\s+/gu, '_'));
  }
  return [...keys];
}
