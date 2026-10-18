import { randomBytes } from 'node:crypto';
import {
  contentCollections,
  contentDraftsCollection,
  contentNutrientSchema,
  contentNutritionRuleSchema,
  contentNutritionStageSchema,
  coverageStates,
  nutrientDraftSchema,
  nutrientIdSchema,
  nutrientStrictSchema,
  nutritionAgeContains,
  nutritionAgeLabel,
  nutritionAgeSchema,
  nutritionAgesOverlap,
  nutritionCopyProblems,
  nutritionGaps,
  nutritionLimits,
  nutritionRuleDraftSchema,
  nutritionRuleIdSchema,
  nutritionRuleStrictSchema,
  nutritionStageDraftSchema,
  nutritionStageIdSchema,
  nutritionStageStrictSchema,
  sortNutritionStages,
  type CoverageState,
  type EditorialStatus,
  type NutritionAge,
} from '@child-life/contracts';
import type { Firestore, Transaction } from 'firebase-admin/firestore';
import type { ContentGateStep, ContentKindAdapter } from './content-library.js';
import { seedNutrients, seedNutritionRules, seedNutritionStages } from './nutrition-seed.js';
import { StaffError } from './staff.js';

/**
 * Dinh dưỡng theo giai đoạn (D-083, P-163; plan `docs/product/nutrition-plan.md` §3, §5) on the
 * editorial workflow of `content-library.ts`: nutrition stages (`nst_…` → contentNutritionStages),
 * micronutrients (`nut_…` → contentNutrients) and suggestion rules (`nru_…` →
 * contentNutritionRules). Besides the common workflow the kinds are gated (P-163 #16, #17):
 * - `unsafe-copy`: Gửi duyệt (and, defensively, Duyệt / Xuất bản) is refused while any text holds
 *   a forbidden word or a dose (`nutritionCopyProblems`);
 * - `stage-overlap`: Duyệt / Xuất bản of a stage is refused while its months overlap another stage
 *   that is on the app or approved;
 * - `link-missing`: a stage submitted with a micronutrient that does not exist (or was archived).
 */

type Data = Record<string, unknown>;
type Loc = { vi: string; en: string };
const count = (xs: unknown) => (Array.isArray(xs) ? xs.length : 0);
const ageOf = (v: unknown): NutritionAge | null => {
  const r = nutritionAgeSchema.safeParse(v);
  return r.success ? r.data : null;
};
const locOf = (v: unknown): Loc | null => {
  const o = v as Partial<Loc> | null | undefined;
  return o && typeof o === 'object' ? { vi: o.vi ?? '', en: o.en ?? '' } : null;
};
const rangeOf = (v: unknown) => {
  const r = v as { min?: unknown; max?: unknown } | null | undefined;
  return r && typeof r.min === 'number' && typeof r.max === 'number'
    ? { min: r.min, max: r.max }
    : null;
};
const seeded = (xs: readonly { id: string; reviewerLabel: string | null; data: unknown }[]) =>
  xs.map((s) => ({ id: s.id, reviewerLabel: s.reviewerLabel, data: s.data as Data }));

// ---------- Gates ----------

/** P-163 #16: no forbidden word and no dose anywhere in the item's text (sources excepted). */
export function assertSafeCopy(data: unknown) {
  if (nutritionCopyProblems(data).length)
    throw new StaffError('failed-precondition', 'unsafe-copy');
}

/**
 * P-163 #17: the first stage among [others] whose months overlap [age] (`to` exclusive), or null.
 * [others] are the stages on the app (their published range) and the approved ones (their draft
 * range); the item itself is left out by the caller.
 */
export function overlappingStage(
  age: NutritionAge,
  others: readonly { id: string; ageMonths: unknown }[],
): string | null {
  for (const o of others) {
    const a = ageOf(o.ageMonths);
    if (a && nutritionAgesOverlap(age, a)) return o.id;
  }
  return null;
}

async function assertNoStageOverlap(tx: Transaction, db: Firestore, id: string, data: Data) {
  const age = ageOf(data.ageMonths);
  if (!age) throw new StaffError('failed-precondition', 'invalid-content');
  const live = await tx.get(db.collection(contentCollections.nutritionStage));
  const all = await tx.get(
    db.collection(contentDraftsCollection).where('kind', '==', 'nutritionStage'),
  );
  const others = [
    ...live.docs.map((d) => ({ id: d.id, ageMonths: d.get('ageMonths') as unknown })),
    ...all.docs
      .filter((d) => d.get('status') === 'approved')
      .map((d) => ({ id: d.id, ageMonths: d.get('data.ageMonths') as unknown })),
  ].filter((o) => o.id !== id);
  if (overlappingStage(age, others)) throw new StaffError('failed-precondition', 'stage-overlap');
}

/** A stage lists micronutrients that exist: a nutrient draft not archived, or a published one. */
async function assertNutrientsExist(tx: Transaction, db: Firestore, data: Data) {
  const ids = [...new Set((data.nutrientIds as string[] | undefined) ?? [])];
  if (!ids.length) return;
  const snaps = await tx.getAll(...ids.map((x) => db.collection(contentDraftsCollection).doc(x)));
  const pubs = await tx.getAll(
    ...ids.map((x) => db.collection(contentCollections.nutrient).doc(x)),
  );
  for (const [i, snap] of snaps.entries()) {
    const draftOk =
      snap.exists && snap.get('kind') === 'nutrient' && snap.get('status') !== 'archived';
    if (!draftOk && !pubs[i]?.exists) throw new StaffError('failed-precondition', 'link-missing');
  }
}

const copyGate: NonNullable<ContentKindAdapter['gate']> = async (_step, { data }) =>
  assertSafeCopy(data);

// ---------- Rule title ----------

/**
 * Rules have no title: lists show the start of the banner (the expert's own `{vi, en}` copy, so no
 * server-made UI text, D-012), cut at the first sentence or at a word before 60 characters with
 * "…". The portal may put its own metric · condition label next to it from the row fields.
 */
export function nutritionRuleTitle(d: Data): Loc {
  const banner = locOf(d.banner) ?? { vi: '', en: '' };
  return { vi: shorten(banner.vi), en: shorten(banner.en) };
}

const TITLE_MAX = 60;
function shorten(s: string): string {
  const t = s.trim().replace(/\s+/g, ' ');
  const sentence = /^(.+?[.!?])(\s|$)/.exec(t)?.[1] ?? t;
  if (sentence.length <= TITLE_MAX) return sentence;
  const cut = sentence.slice(0, TITLE_MAX);
  const at = cut.lastIndexOf(' ');
  return `${(at > TITLE_MAX / 2 ? cut.slice(0, at) : cut).replace(/[\s,.;:–-]+$/, '')}…`;
}

// ---------- Adapters ----------

export const nutritionStageAdapter: ContentKindAdapter = {
  newId: () => `nst_${randomBytes(4).toString('hex')}`,
  isId: (id) => nutritionStageIdSchema.safeParse(id).success,
  draft: nutritionStageDraftSchema,
  strict: nutritionStageStrictSchema,
  published: (id, data, meta) => contentNutritionStageSchema.parse({ id, ...data, ...meta }),
  /** D01 row: age, milk reference, solids, micronutrient tags, counts. */
  row: (d) => {
    const age = ageOf(d.ageMonths);
    const milk = d.milk as Data | null | undefined;
    const solids = d.solids as Data | null | undefined;
    return {
      ageMonths: age,
      ageLabel: age ? nutritionAgeLabel(age) : null,
      milk: milk
        ? {
            perFeedMl: rangeOf(milk.perFeedMl),
            feedsPerDay: rangeOf(milk.feedsPerDay),
            perDayMl: rangeOf(milk.perDayMl),
          }
        : null,
      solidsMeals: solids ? locOf(solids.meals) : null,
      nutrientIds: Array.isArray(d.nutrientIds) ? (d.nutrientIds as string[]) : [],
      sampleDay: count(d.sampleDay),
      tips: count(d.tips),
      sources: count(d.sources),
    };
  },
  seed: () => seeded(seedNutritionStages),
  gate: async (step: ContentGateStep, { tx, db, id, data }) => {
    assertSafeCopy(data);
    if (step === 'submit') await assertNutrientsExist(tx, db, data);
    else await assertNoStageOverlap(tx, db, id, data);
  },
};

export const nutrientAdapter: ContentKindAdapter = {
  newId: () => `nut_${randomBytes(4).toString('hex')}`,
  isId: (id) => nutrientIdSchema.safeParse(id).success,
  draft: nutrientDraftSchema,
  strict: nutrientStrictSchema,
  published: (id, data, meta) => contentNutrientSchema.parse({ id, ...data, ...meta }),
  title: (d) => locOf(d.name) ?? { vi: '', en: '' },
  /** D03 row: key (icon), focus age and label, foods, campaign rounds, counts. */
  row: (d) => {
    const focus = d.focus as Data | null | undefined;
    const campaign = d.campaign as { rounds?: unknown[] } | null | undefined;
    return {
      key: (d.key as string | undefined) ?? null,
      subtitle: locOf(d.subtitle),
      focus: focus
        ? {
            ageMonths: ageOf(focus.ageMonths),
            label: locOf(focus.label) ?? { vi: '', en: '' },
            note: locOf(focus.note),
          }
        : null,
      // The chips and the medical note are short; D03 lists them.
      foods: Array.isArray(d.foods) ? d.foods.map((f) => locOf(f) ?? { vi: '', en: '' }) : [],
      warning: locOf(d.warning),
      byAge: count(d.byAge),
      hasCampaign: !!campaign,
      rounds: Array.isArray(campaign?.rounds) ? campaign.rounds : [],
      sources: count(d.sources),
    };
  },
  seed: () => seeded(seedNutrients),
  gate: copyGate,
};

export const nutritionRuleAdapter: ContentKindAdapter = {
  newId: () => `nru_${randomBytes(4).toString('hex')}`,
  isId: (id) => nutritionRuleIdSchema.safeParse(id).success,
  draft: nutritionRuleDraftSchema,
  strict: nutritionRuleStrictSchema,
  published: (id, data, meta) => contentNutritionRuleSchema.parse({ id, ...data, ...meta }),
  title: nutritionRuleTitle,
  /** D04 row: metric, condition, age, reminder days, export. */
  row: (d) => {
    const age = ageOf(d.ageMonths);
    return {
      metric: (d.metric as string | undefined) ?? null,
      condition: (d.condition as string | undefined) ?? null,
      days: (d.days as number | null | undefined) ?? null,
      ageMonths: age,
      ageLabel: age ? nutritionAgeLabel(age) : null,
      remindAfterDays: (d.remindAfterDays as number | null | undefined) ?? null,
      export: d.export === true,
      tips: count(d.tips),
    };
  },
  seed: () => seeded(seedNutritionRules),
  gate: copyGate,
};

// ---------- D01 coverage strip (0–36 months) ----------

export interface NutritionCoverageItem {
  id: string;
  ageMonths: NutritionAge;
  status: EditorialStatus;
  /** A published revision is on the app (possibly with a newer draft being edited). */
  live: boolean;
}

/**
 * The D01 strip over months 0–36 (P-163 #17), from the stages' current draft ranges: per month the
 * best state of the stages covering it (on the app › waiting for review / approved › draft), the
 * gaps (no stage at all, and no stage on the app), every stage as a segment, and the overlapping
 * pairs (Duyệt / Xuất bản refuses an overlap with a live or approved stage: `stage-overlap`).
 * Archived stages count for nothing.
 */
export function nutritionCoverage(items: readonly NutritionCoverageItem[]) {
  const stateOf = (i: NutritionCoverageItem): Exclude<CoverageState, 'missing'> | null =>
    i.live
      ? 'published'
      : i.status === 'in_review' || i.status === 'approved'
        ? 'pending'
        : i.status === 'draft'
          ? 'draft'
          : null;
  const counted = sortNutritionStages(
    items.flatMap((i) => {
      const state = stateOf(i);
      return state ? [{ id: i.id, ageMonths: i.ageMonths, state }] : [];
    }),
  );
  const months = Array.from({ length: nutritionLimits.maxAgeMonths + 1 }, (_, month) => {
    const here = counted.filter((i) => nutritionAgeContains(i.ageMonths, month));
    const state: CoverageState =
      coverageStates.find((s) => s !== 'missing' && here.some((h) => h.state === s)) ?? 'missing';
    return { month, state, itemIds: here.map((h) => h.id) };
  });
  const overlaps: Array<{ ids: [string, string]; ageMonths: NutritionAge }> = [];
  counted.forEach((a, i) => {
    for (const b of counted.slice(i + 1)) {
      if (!nutritionAgesOverlap(a.ageMonths, b.ageMonths)) continue;
      overlaps.push({
        ids: [a.id, b.id],
        ageMonths: {
          from: Math.max(a.ageMonths.from, b.ageMonths.from),
          to: Math.min(a.ageMonths.to, b.ageMonths.to),
        },
      });
    }
  });
  return {
    /** Months 0–36. */
    total: months.length,
    /** Months with any stage, drafts included. */
    covered: months.filter((m) => m.state !== 'missing').length,
    /** Months with a stage on the app. */
    published: months.filter((m) => m.state === 'published').length,
    months,
    /** Months no stage covers (drafts included), as ranges (`to` exclusive). */
    gaps: nutritionGaps(counted),
    /** Months no stage on the app covers: the app shows the teaser there (P-163 #11). */
    liveGaps: nutritionGaps(counted.filter((i) => i.state === 'published')),
    items: counted.map((i) => ({ ...i, ageLabel: nutritionAgeLabel(i.ageMonths) })),
    overlaps,
  };
}
