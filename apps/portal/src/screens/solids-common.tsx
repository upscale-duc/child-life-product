import {
  foodAllergens,
  foodGroups,
  nutritionAgeLabel,
  recipeMethods,
  solidsLimits,
  textureStages,
  type ContentKind,
  type FoodAllergen,
  type FoodGroup,
  type RecipeMethod,
  type SolidsAge,
  type SolidsCopyProblem,
  type TextureStage,
} from '@child-life/contracts';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { Badge } from '@/components/ui/badge';
import type { ApiError } from '../api';
import { Notice } from '../content-kit';
import { routePaths } from '../context';
import { RejectedBy, errorMessageId } from '../ui';
import {
  textOf,
  type ContentCounts,
  type ContentRow,
  type Loc,
  type ParseIssue,
} from './content-common';
import { locOf } from './nutrition-common';

/**
 * Shared pieces of the Ăn dặm screens (D-085, P-164 #8–#11; plan `docs/product/solids-plan.md` §6):
 * addresses, reading the `food` / `recipe` list rows defensively (the server adds the kind's fields
 * to each row and may not send all of them), labels, the coverage of the catalogue (foods per
 * group, allergens, iron) and of the recipes (per age band, 6 each), and the notices that block
 * "Gửi duyệt" (`unsafe-copy`, `food-too-young`).
 */

const S = solidsLimits;

// ---------- Kinds and addresses ----------

export type SolidsKind = Extract<ContentKind, 'food' | 'recipe'>;
export type SolidsTab = 'foods' | 'recipes' | 'guides';
export const solidsTabs: readonly SolidsTab[] = ['foods', 'recipes', 'guides'];
export const isSolidsKind = (k: ContentKind): k is SolidsKind => k === 'food' || k === 'recipe';

/**
 * "/solids" (foods), "/solids/recipes", "/solids/recipes/rcp_x", "/solids/foods/new",
 * "/solids/guides/art_x" (the article editor). `id` undefined = the list, null = new.
 */
export type SolidsPath = { tab: SolidsTab; id?: string | null };

export function solidsPathOf(segments: string[]): SolidsPath {
  const first = segments[0] ?? '';
  const tab = (solidsTabs as readonly string[]).includes(first) ? (first as SolidsTab) : 'foods';
  const id = segments[1];
  if (!id) return { tab };
  return { tab, id: id === 'new' ? null : id };
}

export function solidsUrl(p: SolidsPath): string {
  const base = routePaths.solids;
  if (p.id === undefined) return p.tab === 'foods' ? base : `${base}/${p.tab}`;
  return `${base}/${p.tab}/${p.id === null ? 'new' : encodeURIComponent(p.id)}`;
}

export const solidsEditorUrl = (kind: SolidsKind, id: string) =>
  solidsUrl({ tab: kind === 'food' ? 'foods' : 'recipes', id });

// ---------- Reading rows defensively ----------

const oneOf = <T extends string>(list: readonly T[], v: unknown): T | null =>
  (list as readonly unknown[]).includes(v) ? (v as T) : null;
const num = (v: unknown): number | null => (typeof v === 'number' && Number.isFinite(v) ? v : null);

export const groupOf = (v: unknown) => oneOf(foodGroups, v);
export const allergenOf = (v: unknown) => oneOf(foodAllergens, v);
export const textureOf = (v: unknown) => oneOf(textureStages, v);

/** A recipe's months (6–36, `to` exclusive), or null. */
export function solidsAgeOf(v: unknown): SolidsAge | null {
  const a = v as { from?: unknown; to?: unknown } | null | undefined;
  const from = num(a?.from);
  const to = num(a?.to);
  if (from === null || to === null || !Number.isInteger(from) || !Number.isInteger(to)) return null;
  if (from < S.startMonths || to > S.maxAgeMonths + 1 || to <= from) return null;
  return { from, to };
}

/** The strings of a list or of a `{vi, en}` list (search terms). */
function wordsOf(v: unknown): string[] {
  if (Array.isArray(v)) return v.filter((x): x is string => typeof x === 'string');
  const o = v as { vi?: unknown; en?: unknown } | null | undefined;
  if (!o || typeof o !== 'object') return [];
  return [...wordsOf(o.vi), ...wordsOf(o.en)];
}

export interface FoodFacts {
  group: FoodGroup | null;
  allergen: FoodAllergen | null;
  ironRich: boolean;
  minAgeMonths: number | null;
  /** null when the row does not say. */
  suggest: boolean | null;
  priority: number | null;
  synonyms: string[];
}

export function foodFactsOf(r: ContentRow): FoodFacts {
  return {
    group: groupOf(r.group),
    allergen: allergenOf(r.allergen),
    ironRich: r.ironRich === true,
    minAgeMonths: num(r.minAgeMonths),
    suggest: typeof r.suggest === 'boolean' ? r.suggest : null,
    priority: num(r.priority),
    synonyms: wordsOf(r.synonyms),
  };
}

export interface RecipeFacts {
  ageMonths: SolidsAge | null;
  texture: TextureStage | null;
  methods: RecipeMethod[];
  /** Prep + cook, or the total the row sends. */
  minutes: number | null;
  /** The row's own allergens when it sends them (else derive them from the foods). */
  allergens: FoodAllergen[] | null;
  foodIds: string[];
  /** Ingredient names the row lists (search). */
  ingredientNames: string[];
  servings: number | null;
  /** Ingredients too young for the recipe's first month, as the server counted them. */
  ageProblems: number;
}

export function recipeFactsOf(r: ContentRow): RecipeFacts {
  const prep = num(r.prepMinutes);
  const cook = num(r.cookMinutes);
  const minutes =
    prep !== null || cook !== null
      ? (prep ?? 0) + (cook ?? 0)
      : (num(r.minutes) ?? num(r.totalMinutes));
  const ingredients = Array.isArray(r.ingredients) ? (r.ingredients as unknown[]) : [];
  const ids = Array.isArray(r.foodIds)
    ? (r.foodIds as unknown[])
    : ingredients.map((i) => (i as { foodId?: unknown } | null)?.foodId);
  return {
    ageMonths: solidsAgeOf(r.ageMonths),
    texture: textureOf(r.texture),
    methods: Array.isArray(r.methods)
      ? recipeMethods.filter((m) => (r.methods as unknown[]).includes(m))
      : [],
    minutes,
    allergens: Array.isArray(r.allergens)
      ? foodAllergens.filter((a) => (r.allergens as unknown[]).includes(a))
      : null,
    foodIds: ids.filter((x): x is string => typeof x === 'string'),
    // The list row sends `ingredientNames` ({vi, en} per ingredient); an item sends `ingredients`.
    ingredientNames: (Array.isArray(r.ingredientNames)
      ? (r.ingredientNames as unknown[])
      : ingredients
    ).flatMap((i) => {
      const x = i as { name?: unknown } | string | null;
      if (typeof x === 'string') return [x];
      const name = locOf(x?.name) ?? locOf(x);
      return name ? [name.vi, name.en] : [];
    }),
    servings: num(r.servings),
    ageProblems: Array.isArray(r.ageProblems) ? r.ageProblems.length : 0,
  };
}

/** What a recipe needs to know about a catalogue food (the derivations and the checks). */
export interface CatalogueFood {
  id: string;
  name: Loc;
  group: FoodGroup | null;
  allergen: FoodAllergen | null;
  minAgeMonths: number;
  ironRich: boolean;
  /** A published revision is on the app (publishing a recipe needs its foods there). */
  live: boolean;
  archived: boolean;
  synonyms: string[];
}

/** The catalogue from the food list rows, by id (rows without a minimum age read as 6). */
export function catalogueOf(rows: readonly ContentRow[]): Map<string, CatalogueFood> {
  return new Map(
    rows.map((r) => {
      const f = foodFactsOf(r);
      return [
        r.id,
        {
          id: r.id,
          name: r.title,
          group: f.group,
          allergen: f.allergen,
          minAgeMonths: f.minAgeMonths ?? S.startMonths,
          ironRich: f.ironRich,
          live: !!r.live,
          archived: r.status === 'archived',
          synonyms: f.synonyms,
        },
      ];
    }),
  );
}

/** The common allergens among catalogue foods (a list row's foods, when it sends no allergens). */
export function allergensOfFoods(
  ids: readonly string[],
  foods: ReadonlyMap<string, { allergen: FoodAllergen | null }>,
): FoodAllergen[] {
  return foodAllergens.filter((a) => ids.some((id) => foods.get(id)?.allergen === a));
}

// ---------- Labels ----------

/** "6–8 tháng" for [6, 9), "6–7 tháng" for [6, 7) (as the Dinh dưỡng labels). */
export function solidsMonthsText(intl: IntlShape, a: SolidsAge): string {
  const l = nutritionAgeLabel(a);
  return intl.formatMessage({ id: 'content.age.months' }, { from: l.from, to: l.to });
}

export const fromMonthsText = (intl: IntlShape, n: number) =>
  intl.formatMessage({ id: 'solids.fromMonths' }, { n });

export const foodName = (intl: IntlShape, f: CatalogueFood | undefined, id: string) =>
  (f && textOf(intl, f.name)) || id;

/** The recipe list bands (5f; the 4–5 band has no recipes, the diary opens at 6). */
export const recipeBands = [
  { id: '6-8', from: 6, to: 9 },
  { id: '9-11', from: 9, to: 12 },
  { id: '12-23', from: 12, to: 24 },
  { id: '24-36', from: 24, to: 37 },
] as const;
export type RecipeBand = (typeof recipeBands)[number];
/** "At least 6 per band 6–8 · 9–11 · 12–23 before the tile goes live" (plan §6). */
export const recipeTarget = 6;
export const launchBands: readonly string[] = ['6-8', '9-11', '12-23'];

export const bandOverlaps = (b: RecipeBand, a: SolidsAge) => a.from < b.to && b.from < a.to;
/** The band a recipe is listed under: the one its first month falls in. */
export const bandOf = (a: SolidsAge | null) =>
  a ? (recipeBands.find((b) => a.from >= b.from && a.from < b.to) ?? null) : null;

/** The counts the server sends with a list, for a subset of its rows (e.g. solids guides). */
export function countsOfRows(rows: readonly ContentRow[]): ContentCounts {
  return {
    inApp: rows.filter((r) => r.live).length,
    pending: rows.filter((r) => r.status === 'in_review' || r.status === 'approved').length,
    inReview: rows.filter((r) => r.status === 'in_review').length,
    approved: rows.filter((r) => r.status === 'approved').length,
    drafts: rows.filter((r) => r.status === 'draft').length,
    dueForReview: rows.filter((r) => r.live?.dueForReview).length,
    archived: rows.filter((r) => r.status === 'archived').length,
    total: rows.length,
  };
}

// ---------- Coverage (plan §6) ----------

/** `{ key: n }` or `[{ group | allergen | key | id, count | n | total }]`, else null. */
function countMap(v: unknown): Map<string, number> | null {
  if (Array.isArray(v)) {
    const out = new Map<string, number>();
    for (const x of v) {
      const o = x as Record<string, unknown> | null;
      const key = o?.group ?? o?.allergen ?? o?.key ?? o?.id;
      const n = num(o?.count) ?? num(o?.n) ?? num(o?.total) ?? num(o?.foods);
      if (typeof key === 'string' && n !== null) out.set(key, n);
    }
    return out.size ? out : null;
  }
  if (v && typeof v === 'object') {
    const out = new Map<string, number>();
    for (const [k, n] of Object.entries(v)) if (num(n) !== null) out.set(k, n as number);
    return out.size ? out : null;
  }
  return null;
}

export interface FoodCoverage {
  total: number;
  live: number;
  byGroup: Record<FoodGroup, number>;
  /** Allergens with at least one food. */
  allergens: FoodAllergen[];
  ironRich: number;
}

/**
 * "N món theo nhóm, N món giàu sắt, 9/9 nhóm dị ứng có món": the server's `coverage` when the list
 * has it, else counted from the rows (archived foods count for nothing).
 */
export function foodCoverageOf(view: { rows: ContentRow[]; coverage?: unknown }): FoodCoverage {
  const rows = view.rows.filter((r) => r.status !== 'archived');
  const facts = rows.map(foodFactsOf);
  const server = (view.coverage ?? null) as Record<string, unknown> | null;
  const groups = countMap(server?.byGroup ?? server?.groups);
  const byGroup = Object.fromEntries(
    foodGroups.map((g) => [
      g,
      groups ? (groups.get(g) ?? 0) : facts.filter((f) => f.group === g).length,
    ]),
  ) as Record<FoodGroup, number>;
  const allergens = foodAllergens.filter((a) => {
    const covered = allergensCovered(server?.allergens);
    return covered ? covered.has(a) : facts.some((f) => f.allergen === a);
  });
  const iron = server?.ironRich as { total?: unknown } | number | null | undefined;
  return {
    total: num(server?.total) ?? rows.length,
    live: num(server?.live) ?? num(server?.published) ?? rows.filter((r) => r.live).length,
    byGroup,
    allergens,
    ironRich:
      num(iron) ??
      num((iron as { total?: unknown } | null | undefined)?.total) ??
      facts.filter((f) => f.ironRich).length,
  };
}

/**
 * The allergens with a food, from what the server sends: `{ byAllergen: [{ allergen, total }] }`
 * or `{ missing: [...] }` (`content-solids.ts`), a list of allergens, or a count map.
 */
function allergensCovered(v: unknown): Set<FoodAllergen> | null {
  if (Array.isArray(v) && v.every((a) => typeof a === 'string')) {
    return new Set(foodAllergens.filter((a) => (v as string[]).includes(a)));
  }
  const o = v as { byAllergen?: unknown; missing?: unknown } | null | undefined;
  const counts = countMap(Array.isArray(v) ? v : (o?.byAllergen ?? null));
  if (counts) return new Set(foodAllergens.filter((a) => (counts.get(a) ?? 0) > 0));
  if (Array.isArray(o?.missing)) {
    return new Set(foodAllergens.filter((a) => !(o.missing as unknown[]).includes(a)));
  }
  return null;
}

export interface RecipeBandCoverage {
  band: RecipeBand;
  /** Recipes whose months overlap the band (what the app lists for a baby in it). */
  count: number;
  live: number;
}

/** "Công thức theo độ tuổi": per band, the server's numbers when sent, else from the rows. */
export function recipeCoverageOf(view: {
  rows: ContentRow[];
  coverage?: unknown;
}): RecipeBandCoverage[] {
  const server = (view.coverage ?? null) as Record<string, unknown> | null;
  const sent = Array.isArray(server?.bands) ? (server.bands as unknown[]) : [];
  const rows = view.rows.filter((r) => r.status !== 'archived');
  return recipeBands.map((band) => {
    const hit = sent.find((x) => {
      const o = x as Record<string, unknown> | null;
      const age = solidsAgeOf(o?.ageMonths) ?? solidsAgeOf(o);
      return o?.id === band.id || (!!age && age.from === band.from && age.to === band.to);
    }) as Record<string, unknown> | undefined;
    const here = rows.filter((r) => {
      const a = solidsAgeOf(r.ageMonths);
      return !!a && bandOverlaps(band, a);
    });
    return {
      band,
      count: num(hit?.count) ?? num(hit?.total) ?? num(hit?.n) ?? here.length,
      live: num(hit?.live) ?? num(hit?.published) ?? here.filter((r) => r.live).length,
    };
  });
}

// ---------- Notices (P-164 #10) ----------

/**
 * A readable place for a schema issue or a copy problem: "Nguyên liệu · mục 3 · Tên · VI". Field
 * names come from `solids.field.*` (a parent-specific one first), then the shared `content.field.*`.
 */
export function solidsPlace(intl: IntlShape, path: ReadonlyArray<PropertyKey>): string {
  const parts: string[] = [];
  let parent: string | null = null;
  for (const p of path) {
    const key = String(p);
    if (key === 'vi' || key === 'en') parts.push(key.toUpperCase());
    else if (typeof p === 'number' || /^\d+$/.test(key)) {
      parts.push(intl.formatMessage({ id: 'content.issue.item' }, { n: Number(key) + 1 }));
    } else {
      const ids = [
        parent ? `solids.field.${parent}.${key}` : '',
        `solids.field.${key}`,
        `content.field.${key}`,
      ];
      const id = ids.find((i) => i && intl.messages[i]);
      parts.push(id ? intl.formatMessage({ id }) : key);
      parent = key;
    }
  }
  return parts.join(' · ') || '—';
}

export type AgeProblem = { foodId: string; minAgeMonths: number };

/** "Mật ong chỉ từ 12 tháng": the ingredients too young for the recipe's first month. */
export function AgeProblemsNotice({
  problems,
  foods,
  from,
}: {
  problems: readonly AgeProblem[];
  foods: ReadonlyMap<string, CatalogueFood>;
  from: number;
}) {
  const intl = useIntl();
  if (!problems.length) return null;
  return (
    <Notice
      tone="error"
      title={<FormattedMessage id="solids.age.title" values={{ n: problems.length }} />}
    >
      <ul className="mt-1 grid list-disc gap-0.5 pl-4">
        {problems.map((p) => (
          <li key={p.foodId}>
            <FormattedMessage
              id="solids.age.problem"
              values={{ name: foodName(intl, foods.get(p.foodId), p.foodId), n: p.minAgeMonths }}
            />
          </li>
        ))}
      </ul>
      <p className="mt-2 text-xs">
        <FormattedMessage id="solids.age.help" values={{ from }} />
      </p>
    </Notice>
  );
}

/** The forbidden words, doses and seasonings (`solidsCopyProblems`), naming the field. */
export function CopyProblemsNotice({ problems }: { problems: readonly SolidsCopyProblem[] }) {
  const intl = useIntl();
  if (!problems.length) return null;
  return (
    <Notice
      tone="error"
      title={<FormattedMessage id="solids.copy.title" values={{ n: problems.length }} />}
    >
      <ul className="mt-1 grid list-disc gap-0.5 pl-4">
        {problems.slice(0, 12).map((p, i) => (
          <li key={i}>
            <FormattedMessage
              id={`solids.copy.${p.problem}`}
              values={{ place: solidsPlace(intl, p.path.split('.')), match: p.match }}
            />
          </li>
        ))}
        {problems.length > 12 && <li>+{problems.length - 12}</li>}
      </ul>
      <p className="mt-2 text-xs">
        <FormattedMessage id="solids.copy.help" />
      </p>
    </Notice>
  );
}

/** What blocks "Gửi duyệt" and what the server said, above the form. */
export function SolidsNotices({
  error,
  rejection,
  issues,
  problems,
  ageProblems = [],
  foods,
  from = S.startMonths,
  className = 'mb-4 grid gap-3',
}: {
  error: ApiError | null;
  rejection: { by: string; reason: string } | null | undefined;
  issues: ReadonlyArray<ParseIssue>;
  problems: readonly SolidsCopyProblem[];
  ageProblems?: readonly AgeProblem[];
  foods?: ReadonlyMap<string, CatalogueFood>;
  from?: number;
  className?: string;
}) {
  const intl = useIntl();
  if (!error && !rejection && !issues.length && !problems.length && !ageProblems.length) {
    return null;
  }
  const places = [...new Set(issues.map((i) => solidsPlace(intl, i.path)))];
  return (
    <div className={className}>
      {error && (
        <Notice tone="error">
          <FormattedMessage id={errorMessageId(error)} />
        </Notice>
      )}
      {rejection && (
        <Notice tone="warn" title={<FormattedMessage id="content.rejectedTitle" />}>
          <RejectedBy id="content.rejected" by={rejection.by} reason={rejection.reason} />
        </Notice>
      )}
      <AgeProblemsNotice problems={ageProblems} foods={foods ?? new Map()} from={from} />
      <CopyProblemsNotice problems={problems} />
      {places.length > 0 && (
        <Notice
          tone="warn"
          title={<FormattedMessage id="content.issues" values={{ n: issues.length }} />}
        >
          <ul className="mt-1 flex flex-wrap gap-1.5">
            {places.slice(0, 12).map((p) => (
              <li key={p}>
                <Badge variant="outline" className="font-normal">
                  {p}
                </Badge>
              </li>
            ))}
            {places.length > 12 && (
              <li className="text-xs text-muted-foreground">+{places.length - 12}</li>
            )}
          </ul>
        </Notice>
      )}
    </div>
  );
}
