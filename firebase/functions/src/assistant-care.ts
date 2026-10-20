import { noticePart } from './assistant-talk.js';
import { personalFilters } from './personalization-state.js';
import { solidsContext, legacyReactionIngredientIds } from './assistant-solids.js';
import { FieldValue, Timestamp, type Firestore } from 'firebase-admin/firestore';
import {
  foldVi,
  contentFitsCountry,
  addDaysIso,
  ageInFullMonths,
  assistantTaskLimits,
  daysBetweenIso,
  eligibleRecipes,
  familyCan,
  feedbackMemory,
  localDateIn,
  planAssistantActivityRequestSchema,
  recFeedbackSchema,
  recipesOf,
  recommend,
  type Activity,
  type ApprovedContentText,
  type AssistantCarePlan,
  type AssistantCareView,
  type AssistantPart,
  type AssistantResponse,
  type CareFeedbackOutcome,
  type FeedbackMemory,
  type Interest,
  type Need,
  type Recipe,
  type RecipeListItem,
  type RhythmContent,
  type SleepConcern,
} from '@child-life/contracts';
import {
  checkInIdFor,
  fail,
  loadTrustedScope,
  parseRequest,
  requireAssistant,
  respond,
  sha,
  taskRef,
  withRequest,
  assistantFlagOn,
  type TrustedScope,
} from './assistant-common.js';
import type { CareTopic } from './assistant-care-model.js';
import type { ClarificationField, ModelExtraction } from './assistant-model.js';
import type { StoredTask } from './assistant-store.js';
import { localInstant, moduleRegistry, type PreparedDraft } from './assistant-tools.js';
import {
  readFeedback,
  readPreferences,
  readRhythmContent,
  readRhythmRules,
  sleepFacts,
} from './rhythm.js';
import type { AssistantDeps } from './assistant.js';

/**
 * Child Life Assistant — care (slice A5: CH15–CH18, CH28; brief p.4, p.16, p.23 J06 / J07).
 *
 * - Sleep concern (CH15 → CH16): clarified in the SAME task, one short question at a time from the
 *   server catalog (khó vào giấc / hay thức → ngày / đêm → onset only when asked for), within the
 *   task's round cap and its single reservation (no extra credit). Then `findApprovedGuidance`, a
 *   deterministic tool: published activities for the need, the baby's actual age, the locale, the
 *   household's country and the concern's time of day (the prerequisite activities carry), ranked
 *   by the contracts `recommend()` with the baby's feedback memory. The part carries the content's
 *   own words (never the model's), `reviewed: review != null`, and a reason from what the person
 *   reported; logged sleep supports it only when the rhythm engine's valid days show a drop
 *   (DATA_INSIGHT), never a Wonder Weeks cause. No eligible content → an honest fallback (released).
 *   An optional observation draft (a check-in, G01: an observation, not a reminder) may be saved or
 *   discarded.
 * - "Thử tối nay" (`planAssistantActivity`): an intention — a plan marker on the task and the
 *   module's `recFeedback` kind `started` ("Mình sẽ thử" in `feedbackKinds`), never "đã thử".
 *   CH17's question opens only after the chance to try and always offers "Chưa thử".
 * - "Hôm nay con ăn gì?" (CH18): `findRecipes` — approved (published + reviewed) recipes for the
 *   household's country and the baby's age in full months, excluding any recipe with an ingredient
 *   the family recorded a reaction to (Phase 2 reads the actual solids diary; the caveat always distinguishes recorded symptoms
 *   from a diagnosis or established tolerance).
 * - Health (CH28): `health_support` with the emergency number approved for the household's
 *   country in the published health pack (none when the country has no entry; never a default).
 * - Kill switch `assistant_care` off, or a country outside the care regions → no guidance or
 *   recipes; logging, summaries and health keep working.
 *
 * Nothing here logs the person's words, the baby's facts or content choices.
 */

const L = (vi: string, en: string) => ({ vi, en });
const fold = (s: string) => s.normalize('NFC').toLocaleLowerCase('vi').replace(/\s+/g, ' ');

// ---------- Stored state on the task (`assistantTasks/{t}.care`) ----------

export interface StoredCare {
  topic: CareTopic;
  sleep: SleepConcern | null;
  guidance: {
    contentId: string;
    contentVersion: number;
    reasonCode: 'SELF_REPORTED_NEED' | 'DATA_INSIGHT' | 'PREVIOUS_HELPFUL';
    reviewed: boolean;
    title: { vi: string; en: string };
    timeOfDay: Activity['timeOfDay'];
  } | null;
  recipeIds: string[];
  plan: AssistantCarePlan | null;
  feedback: {
    contentId: string;
    contentVersion: number;
    outcome: CareFeedbackOutcome;
    at: string;
  } | null;
}

export const careOf = (t: StoredTask): StoredCare | null =>
  ((t as StoredTask & { care?: StoredCare | null }).care ?? null) || null;

// ---------- Region, flag ----------

/**
 * Care content in chat is offered where the household's country is a care region — the same
 * region list as the advanced capabilities (`config/entitlements.regions.advanced`). Logging,
 * summaries and health support never depend on it.
 */
export function careRegionSupported(s: TrustedScope): boolean {
  const country = s.ctx.family.country;
  return country !== null && s.ctx.config.regions.advanced.includes(country);
}

// ---------- Health (CH28) ----------

/** The approved emergency number for [country] in the published health pack, else none. */
export function emergencyFor(
  content: RhythmContent | null,
  country: string | null,
): { country: string; number: string } | null {
  if (!content || !country) return null;
  const r = content.health.regions.find((x) => x.country === country);
  return r ? { country, number: r.emergencyNumber } : null;
}

/**
 * `health_support` with the household's approved emergency number when the health pack has one
 * for its country; absent otherwise (never a default hotline). Free, no model, no consent needed.
 */
export async function healthSupportPart(
  db: Firestore,
  s: TrustedScope,
  signs: string[],
): Promise<AssistantPart> {
  const emergency = emergencyFor(await readRhythmContent(db), s.ctx.family.country);
  return {
    type: 'health_support',
    schemaVersion: 1,
    signs,
    ...(emergency ? { emergency } : {}),
  };
}

// ---------- Planning one round of a care task ----------

export type CarePlanStep =
  | { kind: 'none' }
  | { kind: 'health'; signs: string[] }
  | { kind: 'blocked'; code: 'FEATURE_DISABLED' | 'REGION_UNSUPPORTED' }
  | { kind: 'ask'; field: ClarificationField; care: StoredCare }
  | { kind: 'ready'; care: StoredCare };

const blockedText = {
  FEATURE_DISABLED: L(
    'Gợi ý chăm sóc qua trò chuyện đang tạm dừng. Ghi nhanh, hỏi nhật ký và hướng dẫn sức khoẻ vẫn dùng được.',
    'Care suggestions in chat are paused. Quick logging, log questions and health guidance still work.',
  ),
  REGION_UNSUPPORTED: L(
    'Gợi ý chăm sóc qua chat chưa mở ở khu vực của hộ. Ghi nhanh và hỏi dữ liệu vẫn dùng được.',
    'Care suggestions in chat aren’t available in your household’s region yet. Quick logging and data questions still work.',
  ),
};

const periodAnswer: Record<string, SleepConcern['kind']> = {
  falling_asleep: 'falling_asleep',
  night_waking: 'night_waking',
  both: 'both',
};
const whenAnswer: Record<string, SleepConcern['when']> = { night: 'night', day: 'day' };
const sinceAnswer: Record<string, SleepConcern['since']> = {
  today: 'today',
  days_2_3: 'days_2_3',
  longer: 'longer',
};

export interface CarePlanInput {
  s: TrustedScope;
  stored: StoredCare | null;
  ext: ModelExtraction;
  /** Answered clarifications of this task (field + choice id). */
  answers: { field: string; choiceId: string | null }[];
  /** Fields already asked in this task (each is asked once). */
  asked: ReadonlySet<string>;
  /** The person's words and answers (grounding for the model's facts). */
  texts: string[];
  round: number;
}

/**
 * Decides this round's care step, deterministically: structured health signs first (free), then
 * the kill switch and the region, then the next missing fact (one question per round, each asked
 * once, within the round cap — at the cap the guidance uses what is known), else ready. The
 * model's facts count only when their evidence is in the person's words; answers win.
 */
export function planCare(x: CarePlanInput): CarePlanStep {
  const signs = x.ext.healthSigns ?? [];
  if (signs.length > 0) return { kind: 'health', signs: [...new Set(signs)] };
  const topic = x.stored?.topic ?? x.ext.care?.topic ?? null;
  if (!topic) return { kind: 'none' };
  if (!assistantFlagOn(x.s, 'assistant_care')) return { kind: 'blocked', code: 'FEATURE_DISABLED' };
  if (!careRegionSupported(x.s)) return { kind: 'blocked', code: 'REGION_UNSUPPORTED' };
  const base: StoredCare = {
    topic,
    sleep: null,
    guidance: null,
    recipeIds: [],
    plan: null,
    feedback: null,
  };
  if (topic === 'meal_ideas') return { kind: 'ready', care: base };

  // Sleep concern: answers > earlier rounds > grounded model facts.
  const haystack = fold(x.texts.join(' \n '));
  const ext = x.ext.care?.topic === 'sleep_concern' ? x.ext.care : null;
  const grounded = (field: 'kind' | 'when' | 'since') =>
    ext?.evidence.some((e) => e.field === field && haystack.includes(fold(e.text).trim())) ?? false;
  const answer = (field: string) => x.answers.find((a) => a.field === field)?.choiceId ?? null;
  const prev = x.stored?.sleep ?? { kind: null, when: null, since: null };
  const pick = <T>(
    field: string,
    map: Record<string, T>,
    earlier: T,
    model: T,
    key: 'kind' | 'when' | 'since',
  ) => {
    const a = answer(field);
    if (a !== null) return map[a] ?? null;
    if (earlier !== null) return earlier;
    return model !== null && grounded(key) ? model : null;
  };
  const sleep: SleepConcern = {
    kind: pick('sleep.period', periodAnswer, prev.kind, ext?.sleep?.kind ?? null, 'kind'),
    when: pick('sleep.when', whenAnswer, prev.when, ext?.sleep?.when ?? null, 'when'),
    since: pick('sleep.onset', sinceAnswer, prev.since, ext?.sleep?.since ?? null, 'since'),
  };
  const care: StoredCare = { ...base, sleep };
  let field: ClarificationField | null = null;
  if (sleep.kind === null && !x.asked.has('sleep.period')) field = 'sleep.period';
  else if (sleep.when === null && !x.asked.has('sleep.when')) field = 'sleep.when';
  else if (
    sleep.since === null &&
    x.ext.clarification?.field === 'sleep.onset' &&
    !x.asked.has('sleep.onset')
  ) {
    field = 'sleep.onset';
  }
  if (field && x.round < assistantTaskLimits.maxClarificationRounds) {
    return { kind: 'ask', field, care };
  }
  return { kind: 'ready', care };
}

/** The notice text for a blocked care step in [locale]. */
export function blockedPart(
  code: 'FEATURE_DISABLED' | 'REGION_UNSUPPORTED',
  locale: 'vi' | 'en',
): AssistantPart {
  return {
    type: 'text',
    schemaVersion: 1,
    text: blockedText[code][locale],
    code: code === 'FEATURE_DISABLED' ? 'CARE_FEATURE_DISABLED' : 'REGION_UNSUPPORTED',
  };
}

// ---------- findApprovedGuidance (deterministic tool) ----------

export interface GuidanceInput {
  activities: readonly Activity[];
  need: Need;
  /** The concern's time of day: night → evening / any items; day → day / any; else all. */
  when: SleepConcern['when'];
  locale: 'vi' | 'en';
  today: string;
  ageDays: number;
  country: string | null;
  memory: FeedbackMemory;
  interests: readonly Interest[];
  fewer: readonly Interest[];
}

export type GuidanceResult =
  | { kind: 'none' }
  | {
      kind: 'found';
      primary: Activity;
      alternatives: Activity[];
      reasonCode: 'SELF_REPORTED_NEED' | 'PREVIOUS_HELPFUL';
    };

/** A night concern needs an evening (or any-time) item; a nap concern a day (or any-time) one. */
export function fitsWhen(a: Pick<Activity, 'timeOfDay'>, when: SleepConcern['when']): boolean {
  if (when === 'night') return a.timeOfDay !== 'day';
  if (when === 'day') return a.timeOfDay !== 'evening';
  return true;
}

/**
 * Published activities only (`recommend` drops drafts and retired items), for the need, the
 * baby's actual age, the locale and the household's country (an item's `regions`, empty = all),
 * the concern's time of day, excluding "Không phù hợp" and cooling-down items, ranked with the
 * versioned weights. Unreviewed items are eligible (D-073 #2 publishes them on dev) but the part
 * says `reviewed: false`, shown as "chờ chuyên môn duyệt".
 */
export function findApprovedGuidance(x: GuidanceInput): GuidanceResult {
  const out = recommend({
    locale: x.locale,
    today: x.today,
    ageDays: x.ageDays,
    need: x.need,
    interests: x.interests,
    fewer: x.fewer,
    country: x.country,
    healthFlag: false,
    memory: x.memory,
    activities: x.activities.filter((a) => fitsWhen(a, x.when)),
  });
  if (out.kind !== 'suggestion') return { kind: 'none' };
  return {
    kind: 'found',
    primary: out.primary,
    alternatives: out.secondary,
    reasonCode: out.reasonCode === 'PREVIOUS_HELPFUL' ? 'PREVIOUS_HELPFUL' : 'SELF_REPORTED_NEED',
  };
}

// ---------- findRecipes (deterministic tool) ----------

export interface RecipesInput {
  recipes: readonly Recipe[];
  ageMonths: number;
  country: string;
  /** Ingredient ids the family recorded a reaction to (self-reported, never a diagnosis). */
  reactionIngredientIds: readonly string[];
  locale: 'vi' | 'en';
}

export interface RecipesResult {
  items: RecipeListItem[];
  /** Eligible but for a recorded reaction. */
  excludedCount: number;
}

export const maxRecipeCandidates = 3;

/**
 * Contracts `eligibleRecipes` on the published pack: approved = published AND reviewed; the
 * household's country; minimum age in full months; no ingredient with a recorded reaction. At most
 * three, closest to the baby's age first, then by id. Words come from the content.
 */
export function findRecipes(x: RecipesInput): RecipesResult {
  const candidates = x.recipes.map((r) => ({
    id: r.id,
    ingredientIds: r.ingredientIds,
    minAgeMonths: r.minAgeMonths,
    approved: r.status === 'published' && r.review !== null,
    region: r.regions.includes(x.country) ? x.country : '',
  }));
  const eligible = new Set(
    eligibleRecipes(candidates, x.ageMonths, x.reactionIngredientIds, x.country),
  );
  const withoutReactions = eligibleRecipes(candidates, x.ageMonths, [], x.country);
  const chosen = x.recipes
    .filter((r) => eligible.has(r.id))
    .sort((a, b) => b.minAgeMonths - a.minAgeMonths || a.id.localeCompare(b.id))
    .slice(0, maxRecipeCandidates);
  return {
    items: chosen.map((r) => ({
      recipeId: r.id,
      recipeVersion: r.version,
      title: r.title[x.locale],
      summary: r.summary[x.locale],
      durationMin: r.durationMin,
      minAgeMonths: r.minAgeMonths,
      why:
        x.locale === 'vi'
          ? `Từ ${r.minAgeMonths} tháng · đã được chuyên môn duyệt`
          : `From ${r.minAgeMonths} months · expert-reviewed`,
    })),
    excludedCount: withoutReactions.length - eligible.size,
  };
}

/** Ingredients excluded by the actual solids diary, including related allergens. */
export async function recordedReactionIngredientIds(
  db: Firestore,
  babyId: string,
): Promise<{ ids: string[]; source: 'diary' }> {
  const context = await solidsContext(db, babyId, new Date());
  return { ids: legacyReactionIngredientIds(context), source: 'diary' };
}

// ---------- The care answer of a task ----------

export interface CareAnswerInput {
  db: Firestore;
  s: TrustedScope;
  care: StoredCare;
  anchor: Date;
  now: Date;
  locale: 'vi' | 'en';
  /** The caller may read the care log (`history.read`): logged facts may support the reason. */
  canRead: boolean;
  /** TEST-ONLY fixture input (no module records reactions yet); never set in production. */
  reactionIngredientIds?: readonly string[] | undefined;
}

export interface CareAnswer {
  parts: AssistantPart[];
  drafts: PreparedDraft[];
  /** A grounded answer exists (guidance or ≥ 1 recipe): commit; else a released fallback. */
  useful: boolean;
  care: StoredCare;
}

const kindLabel: Record<NonNullable<SleepConcern['kind']>, { vi: string; en: string }> = {
  falling_asleep: L('khó vào giấc', 'hard to fall asleep'),
  night_waking: L('hay thức giấc', 'waking often'),
  both: L('khó vào giấc và hay thức giấc', 'hard to fall asleep and waking often'),
};
const whenLabel: Record<NonNullable<SleepConcern['when']>, { vi: string; en: string }> = {
  night: L('giấc đêm', 'night'),
  day: L('giấc ngày', 'naps'),
  both: L('cả ngày và đêm', 'day and night'),
};

async function babyAge(db: Firestore, babyId: string, today: string) {
  const dob = (
    (await db.doc(`babies/${babyId}/restricted/profile`).get()).get('dateOfBirth') as
      string | undefined
  )?.slice(0, 10);
  if (!dob || dob > today) return null;
  return { days: daysBetweenIso(dob, today), months: ageInFullMonths(dob, today) };
}

function fallback(
  care: StoredCare,
  code: 'CARE_NO_APPROVED_CONTENT' | 'RECIPES_NONE_APPROVED' | 'CARE_AGE_UNKNOWN',
  locale: 'vi' | 'en',
  extra: AssistantPart[] = [],
): CareAnswer {
  const text = {
    CARE_NO_APPROVED_CONTENT: L(
      'Chưa có gợi ý đã duyệt phù hợp với con lúc này. Bạn có thể xem Thư viện chăm bé.',
      'There’s no reviewed suggestion that fits your baby right now. You can browse the Care library.',
    ),
    RECIPES_NONE_APPROVED: L(
      'Chưa có công thức được duyệt phù hợp với con.',
      'There’s no reviewed recipe that fits your baby yet.',
    ),
    CARE_AGE_UNKNOWN: L(
      'Mình cần ngày sinh của con để chọn nội dung đúng tuổi. Bạn có thể thêm trong hồ sơ của con.',
      'I need your baby’s date of birth to pick age-appropriate content. You can add it in the profile.',
    ),
  }[code][locale];
  return {
    parts: [...extra, { type: 'text', schemaVersion: 1, text, code }],
    drafts: [],
    useful: false,
    care,
  };
}

function contentText(a: Activity, locale: 'vi' | 'en'): ApprovedContentText {
  return {
    title: a.title[locale],
    summary: a.summary[locale],
    steps: [...a.steps[locale]],
    safety: a.safety ? a.safety[locale] : null,
    durationMin: a.durationMin,
    timeOfDay: a.timeOfDay,
  };
}

/** The reason line: what the person reported, logged facts only when valid, never a cause. */
function reasonText(
  sleep: SleepConcern,
  code: 'SELF_REPORTED_NEED' | 'DATA_INSIGHT' | 'PREVIOUS_HELPFUL',
  facts: { recent: number; baseline: number } | null,
  locale: 'vi' | 'en',
): string {
  const vi = locale === 'vi';
  const chosen = [sleep.kind ? kindLabel[sleep.kind][locale] : null]
    .concat(sleep.when ? [whenLabel[sleep.when][locale]] : [])
    .filter((v): v is string => v !== null);
  const parts = [
    chosen.length
      ? vi
        ? `Vì sao: bạn chọn “${chosen.join(', ')}”.`
        : `Why: you chose “${chosen.join(', ')}”.`
      : vi
        ? 'Vì sao: bạn cho biết con khó ngủ.'
        : 'Why: you said your baby is having trouble sleeping.',
  ];
  if (code === 'DATA_INSIGHT' && facts) {
    parts.push(
      vi
        ? `Nhật ký các ngày ghi đầy đủ: gần đây khoảng ${Math.round(facts.recent)} phút ngủ mỗi ngày, trước đó khoảng ${Math.round(facts.baseline)} phút.`
        : `Fully logged days: recently about ${Math.round(facts.recent)} min of sleep a day, before that about ${Math.round(facts.baseline)} min.`,
    );
  }
  if (code === 'PREVIOUS_HELPFUL') {
    parts.push(
      vi
        ? 'Gia đình từng đánh giá cách này là “Có ích”.'
        : 'Your family rated this “Helpful” before.',
    );
  }
  return parts.join(' ');
}

/** The answer for a settled care step (no model involved). */
export async function careAnswer(x: CareAnswerInput): Promise<CareAnswer> {
  const { db, s, locale } = x;
  const today = localDateIn(s.zone, x.anchor);
  const [content, age] = await Promise.all([readRhythmContent(db), babyAge(db, s.babyId, today)]);
  const country = s.ctx.family.country!;

  if (x.care.topic === 'meal_ideas') {
    if (!x.canRead)
      return {
        parts: [noticePart({ code: 'READ_DENIED' }, locale)],
        drafts: [],
        useful: false,
        care: x.care,
      };
    const diary = await solidsContext(db, s.babyId, x.anchor);
    if (age && diary.recipes.size > 0) {
      const excluded = new Set([...diary.excluded, ...(x.reactionIngredientIds ?? [])]);
      const eligible = [...diary.recipes.values()].filter(
        (r) =>
          r.review !== null &&
          contentFitsCountry(r, country) &&
          age.months >= r.ageMonths.from &&
          age.months < r.ageMonths.to &&
          ((diary.method !== 'spoon' && diary.method !== 'blw') ||
            r.methods.includes(diary.method)) &&
          r.ingredients.every(
            (i) =>
              !i.foodId ||
              (diary.foods.has(i.foodId) && diary.foods.get(i.foodId)!.minAgeMonths <= age.months),
          ),
      );
      const ranked = eligible
        .filter((r) =>
          r.ingredients.every((i) =>
            i.foodId
              ? !excluded.has(i.foodId)
              : !excluded.has(`free:${foldVi(i.name[locale].trim())}`),
          ),
        )
        .map((r) => ({
          r,
          familiar: r.ingredients.filter((i) => i.foodId && diary.tried.has(i.foodId)).length,
        }))
        .sort((a, b) => b.familiar - a.familiar || a.r.id.localeCompare(b.r.id))
        .slice(0, 3);
      if (!ranked.length) return fallback(x.care, 'RECIPES_NONE_APPROVED', locale);
      const vi = locale === 'vi';
      const part: AssistantPart = {
        type: 'read_card',
        schemaVersion: 1,
        tool: 'solids_history',
        title: vi ? 'Gợi ý món từ nhật ký ăn dặm' : 'Meal ideas from your solids diary',
        asOf: x.anchor.toISOString(),
        rows: ranked.map(({ r, familiar }) => ({
          label: r.title[locale],
          value: `${r.summary[locale]} · ${vi ? 'Nguyên liệu đã thử' : 'Previously tried ingredients'}: ${familiar}`,
          link: `/care/solids/recipe/${r.id}`,
        })),
        action: { label: vi ? 'Mở Ăn dặm' : 'Open Solids', link: '/care/solids' },
        sourceIds: [...diary.sourceIds, ...ranked.map(({ r }) => r.id)].slice(0, 200),
        caveat: vi
          ? 'Đã đối chiếu thực phẩm đã thử, dấu hiệu sau ăn, nhóm dị nguyên và món gia đình đã ẩn. Ghi nhận sau một bữa ăn không xác định nguyên liệu gây dị ứng; chưa ghi phản ứng không có nghĩa đã dung nạp tốt.'
          : 'Uses tried foods, recorded symptoms, allergen groups and hidden foods. Symptoms after a meal do not identify an allergen; no recorded reaction does not establish tolerance.',
      };
      return {
        parts: [part],
        drafts: [],
        useful: true,
        care: { ...x.care, recipeIds: ranked.map(({ r }) => r.id) },
      };
    }
    const recipes = recipesOf(content);
    const empty = (): AssistantPart => ({
      type: 'recipe_list',
      schemaVersion: 1,
      recipeIds: [],
      caveat: null,
      items: [],
      excludedCount: 0,
      mealLogAvailable: true,
    });
    if (!age) return fallback(x.care, 'CARE_AGE_UNKNOWN', locale);
    if (!recipes.length) return fallback(x.care, 'RECIPES_NONE_APPROVED', locale, [empty()]);
    const reactions = x.reactionIngredientIds
      ? { ids: [...x.reactionIngredientIds], source: 'fixture' as const }
      : { ids: legacyReactionIngredientIds(diary), source: 'diary' as const };
    const r = findRecipes({
      recipes,
      ageMonths: age.months,
      country,
      reactionIngredientIds: reactions.ids,
      locale,
    });
    if (!r.items.length) return fallback(x.care, 'RECIPES_NONE_APPROVED', locale, [empty()]);
    const vi = locale === 'vi';
    const caveat = [
      reactions.ids.length > 0
        ? vi
          ? 'Đã loại món có nguyên liệu con từng có phản ứng (theo ghi nhận của gia đình, không phải chẩn đoán dị ứng).'
          : 'Dishes with an ingredient your baby had a recorded reaction to are left out (a family note, not an allergy diagnosis).'
        : vi
          ? 'Nhật ký ăn dặm chưa có ghi nhận dấu hiệu sau ăn; điều này không xác định khả năng dung nạp.'
          : 'The solids diary has no recorded symptoms after eating; this does not establish tolerance.',
      vi
        ? 'Món chưa có ghi nhận phản ứng không có nghĩa là con đã dung nạp tốt.'
        : 'No recorded reaction doesn’t mean a food is well tolerated.',
    ].join(' ');
    return {
      parts: [
        {
          type: 'recipe_list',
          schemaVersion: 1,
          recipeIds: r.items.map((i) => i.recipeId),
          caveat,
          items: r.items,
          excludedCount: r.excludedCount,
          mealLogAvailable: true,
        },
      ],
      drafts: [],
      useful: true,
      care: { ...x.care, recipeIds: r.items.map((i) => i.recipeId) },
    };
  }

  // Sleep concern.
  const sleep = x.care.sleep ?? { kind: null, when: null, since: null };
  if (!content || content.activities.length === 0) {
    return fallback(x.care, 'CARE_NO_APPROVED_CONTENT', locale);
  }
  if (!age) return fallback(x.care, 'CARE_AGE_UNKNOWN', locale);
  const [rules, rows, prefs, filters] = await Promise.all([
    readRhythmRules(db),
    readFeedback(db, s.babyId),
    readPreferences(db, s.uid),
    personalFilters(db, s.babyId, s.uid, x.now),
  ]);
  const found = findApprovedGuidance({
    activities: content.activities.filter(
      (a) =>
        !filters.hidden.has(a.id) &&
        (filters.maxMinutes === null || a.durationMin <= filters.maxMinutes),
    ),
    need: 'sleep',
    when: sleep.when,
    locale,
    today,
    ageDays: age.days,
    country,
    memory: feedbackMemory(rows, rules.cooldownDays),
    interests: prefs.interests,
    fewer: prefs.fewer,
  });
  if (found.kind === 'none') return fallback(x.care, 'CARE_NO_APPROVED_CONTENT', locale);

  // Logged facts support the reason only on valid days showing less sleep (DATA_INSIGHT).
  let reasonCode: 'SELF_REPORTED_NEED' | 'DATA_INSIGHT' | 'PREVIOUS_HELPFUL' = found.reasonCode;
  let facts: { recent: number; baseline: number } | null = null;
  if (reasonCode === 'SELF_REPORTED_NEED' && x.canRead) {
    const f = await sleepFacts(db, s.babyId, s.zone, today, x.anchor, rules);
    if (
      f.status === 'change_detected' &&
      f.recent !== null &&
      f.baseline !== null &&
      f.recent < f.baseline
    ) {
      reasonCode = 'DATA_INSIGHT';
      facts = { recent: f.recent, baseline: f.baseline };
    }
  }
  const a = found.primary;
  const reviewed = a.review !== null;
  const parts: AssistantPart[] = [
    {
      type: 'approved_content',
      schemaVersion: 1,
      contentId: a.id,
      contentVersion: a.version,
      reason: reasonText(sleep, reasonCode, facts, locale),
      reviewed,
      reasonCode,
      content: contentText(a, locale),
      alternatives: found.alternatives.map((b) => ({ contentId: b.id, contentVersion: b.version })),
    },
  ];

  // P-172 E3: confirmed shared notes are quoted data, never model instructions. Private
  // notebook text must not be echoed into the shared baby conversation.
  const sharedNotes = filters.notes
    .filter((n) => n.scope === 'baby' && ['sleep', 'soothing', 'routine'].includes(n.category))
    .slice(0, 2);
  if (sharedNotes.length > 0)
    parts.unshift({
      type: 'text',
      schemaVersion: 1,
      text:
        (locale === 'vi' ? 'Nhà mình đã ghi: ' : 'Your family recorded: ') +
        sharedNotes.map((n) => `“${n.text}”`).join(' · '),
    });

  // The optional observation (a check-in for Nhịp lớn lên), only when this person can save it
  // and has not already written that observation today.
  const drafts: PreparedDraft[] = [];
  const mod = moduleRegistry.observation;
  if (mod.available && mod.action && familyCan(s.member, mod.action)) {
    const ciId = checkInIdFor(s.babyId, s.uid, today, 'sleep');
    const exists = (await db.doc(`babies/${s.babyId}/checkins/${ciId}`).get()).exists;
    if (!exists) {
      drafts.push({
        payload: {
          kind: 'observation',
          observation: 'sleep',
          date: today,
          when: sleep.when,
          note: null,
        },
        missingFields: [],
        uncertainFields: [],
        problems: [],
        warnings: [],
      });
    }
  }
  return {
    parts,
    drafts,
    useful: true,
    care: {
      ...x.care,
      guidance: {
        contentId: a.id,
        contentVersion: a.version,
        reasonCode,
        reviewed,
        title: { vi: a.title.vi, en: a.title.en },
        timeOfDay: a.timeOfDay,
      },
    },
  };
}

// ---------- Plan ("Thử tối nay") and follow-up (CH16 → CH17) ----------

/** The `recFeedback` id of the intention (distinct from the outcome's `feedbackIdFor`). */
export const startedFeedbackIdFor = (
  uid: string,
  taskId: string,
  contentId: string,
  version: number,
) => `fb_${sha(`feedback-started|${uid}|${taskId}|${contentId}|${version}`).slice(0, 32)}`;

/**
 * When feedback opens after a plan: an evening (or any-time) item the next local morning at
 * 05:00; a daytime item the same day at 18:00 when planned before then, else the next morning.
 */
export function feedbackOpensAt(
  zone: string,
  plannedFor: string,
  timeOfDay: Activity['timeOfDay'],
  now: Date,
): Date {
  const nextMorning = localInstant(zone, addDaysIso(plannedFor, 1), '05:00');
  if (timeOfDay !== 'day') return nextMorning;
  const evening = localInstant(zone, plannedFor, '18:00');
  return now < evening ? evening : nextMorning;
}

const followUpChoices: { id: CareFeedbackOutcome; label: { vi: string; en: string } }[] = [
  { id: 'helpful', label: L('Có ích', 'Helpful') },
  { id: 'unsure', label: L('Chưa rõ', 'Not sure') },
  { id: 'not_suitable', label: L('Không phù hợp', 'Not a fit') },
  { id: 'not_tried', label: L('Chưa thử', 'Didn’t try') },
];

/** The app's view of a task's care thread; the follow-up only once the chance has passed. */
export function careView(t: StoredTask, now: Date | null): AssistantCareView | null {
  const c = careOf(t);
  if (!c) return null;
  const g = c.guidance;
  const due =
    g !== null &&
    c.plan !== null &&
    c.plan.contentId === g.contentId &&
    c.feedback === null &&
    now !== null &&
    now.getTime() >= Date.parse(c.plan.feedbackOpensAt);
  return {
    topic: c.topic,
    sleep: c.sleep,
    guidance: g
      ? {
          contentId: g.contentId,
          contentVersion: g.contentVersion,
          reasonCode: g.reasonCode,
          reviewed: g.reviewed,
        }
      : null,
    recipeIds: c.recipeIds,
    plan: c.plan,
    followUp: due
      ? {
          contentId: g.contentId,
          contentVersion: g.contentVersion,
          // Never "bạn đã thử": the person only said they would.
          question: L(
            `Bạn có dịp thử “${g.title.vi}” chưa? Nếu đã thử, thấy thế nào?`,
            `Did you get a chance to try “${g.title.en}”? If you did, how did it go?`,
          ),
          choices: followUpChoices,
        }
      : null,
    feedback: c.feedback
      ? {
          contentId: c.feedback.contentId,
          contentVersion: c.feedback.contentVersion,
          outcome: c.feedback.outcome,
        }
      : null,
  };
}

/**
 * Feedback rules for a care task (CH17): only on the guidance this task gave; a tried outcome
 * (helpful / unsure / not suitable) is refused before the planned chance to try (INVALID_STATE);
 * "Chưa thử" is always accepted. Tasks without care keep the A2 behaviour.
 */
export function careFeedbackGate(
  t: StoredTask,
  req: { contentId: string; contentVersion: number; outcome: CareFeedbackOutcome },
  now: Date,
): void {
  const c = careOf(t);
  if (!c || c.topic !== 'sleep_concern') return;
  const g = c.guidance;
  if (!g || g.contentId !== req.contentId || g.contentVersion !== req.contentVersion) {
    throw fail('VALIDATION_FAILED', { field: 'contentId' });
  }
  if (
    req.outcome !== 'not_tried' &&
    c.plan !== null &&
    c.plan.contentId === req.contentId &&
    now.getTime() < Date.parse(c.plan.feedbackOpensAt)
  ) {
    throw fail('INVALID_STATE');
  }
}

/** Extra task fields to write with a feedback (the latest answer on a care task). */
export function careFeedbackFields(
  t: StoredTask,
  req: { contentId: string; contentVersion: number; outcome: CareFeedbackOutcome },
  now: Date,
): Record<string, unknown> {
  if (!careOf(t)) return {};
  return {
    'care.feedback': {
      contentId: req.contentId,
      contentVersion: req.contentVersion,
      outcome: req.outcome,
      at: now.toISOString(),
    },
  };
}

/**
 * `planAssistantActivity` ("Thử tối nay", CH16): 0 credits, no model. Stores the plan on the task
 * and the module's intention (`recFeedback` kind `started`, which `feedbackKinds` defines as
 * "Mình sẽ thử" / "Thử tối nay" and `composeHome` reads as "started", never as tried). Only the
 * guidance this task gave, still published; role `rhythm.feedback`. Idempotent: the same plan
 * again returns it; another item of the same task is VALIDATION_FAILED.
 */
export async function planAssistantActivity(
  deps: AssistantDeps,
  uid: string,
  data: unknown,
): Promise<AssistantResponse<{ plan: AssistantCarePlan; feedbackId: string }>> {
  const { db, now } = deps;
  const req = parseRequest(planAssistantActivityRequestSchema, data);
  const { contractVersion: _c, clientRequestId, locale: _l, ...input } = req;
  void _c;
  void _l;
  return withRequest(db, uid, 'plan', clientRequestId, input, now, async () => {
    const ref = taskRef(db, req.taskId);
    const pre = await ref.get();
    if (!pre.exists || pre.get('ownerUid') !== uid) throw fail('NOT_MEMBER');
    const s = await loadTrustedScope(
      db,
      uid,
      (pre.data() as StoredTask).scope,
      now,
      deps.environment,
    );
    requireAssistant(s);
    if (!familyCan(s.member, 'rhythm.feedback')) throw fail('WRITE_DENIED');
    const content = await readRhythmContent(db);
    const published = content?.activities.some(
      (a) => a.id === req.contentId && a.version === req.contentVersion && a.status === 'published',
    );
    const today = localDateIn(s.zone, now);
    const feedbackId = startedFeedbackIdFor(uid, req.taskId, req.contentId, req.contentVersion);
    const fbRef = db.doc(`babies/${s.babyId}/recFeedback/${feedbackId}`);
    const plan = await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const t = snap.data() as StoredTask;
      const c = careOf(t);
      const g = c?.guidance;
      if (!c || !g || g.contentId !== req.contentId || g.contentVersion !== req.contentVersion) {
        throw fail('VALIDATION_FAILED', { field: 'contentId' });
      }
      if (!published) throw fail('VALIDATION_FAILED', { field: 'contentId' });
      if (c.plan && c.plan.contentId === req.contentId) return c.plan;
      const existing = await tx.get(fbRef);
      const next: AssistantCarePlan = {
        contentId: req.contentId,
        contentVersion: req.contentVersion,
        plannedFor: today,
        plannedAt: now.toISOString(),
        feedbackOpensAt: feedbackOpensAt(s.zone, today, g.timeOfDay, now).toISOString(),
      };
      if (!existing.exists) {
        // Module semantics: `started` = "Mình sẽ thử" (an intention), not "đã thử". Same keys as
        // the app's document (Rules `validNewFeedback`, contracts `recFeedbackSchema`).
        const doc = recFeedbackSchema.parse({
          id: feedbackId,
          babyId: s.babyId,
          authorUid: uid,
          contentId: req.contentId,
          contentVersion: req.contentVersion,
          kind: 'started',
          date: today,
          note: null,
        });
        tx.create(fbRef, { ...doc, createdAt: FieldValue.serverTimestamp() });
      }
      tx.update(ref, { 'care.plan': next, updatedAt: Timestamp.fromDate(now) });
      return next;
    });
    return respond(clientRequestId, now, { plan, feedbackId }, { taskId: req.taskId });
  });
}
