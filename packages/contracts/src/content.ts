import { z } from 'zod';
import { memberRoles } from './baby.js';
import {
  nutrientDraftSchema,
  nutrientIdSchema,
  nutrientSchema,
  nutritionRuleDraftSchema,
  nutritionRuleIdSchema,
  nutritionRuleSchema,
  nutritionStageDraftSchema,
  nutritionStageIdSchema,
  nutritionStageSchema,
  ruleFits,
} from './nutrition.js';
import { contentReviewSchema, contentSourceSchema, daysBetweenIso } from './rhythm.js';
import {
  foodDraftSchema,
  foodIdSchema,
  solidsFoodSchema,
  recipeDraftSchema,
  recipeIdSchema,
  solidsRecipeSchema,
  recipeStepsSame,
} from './solids.js';

/**
 * Editorial content (D-076 #5–#7; Figma portal B01–B08, app 2a/2b, 3a–3g, 4a–4f): Thư viện chăm bé
 * articles, "Giai đoạn của bé" stage content (portal "Nội dung theo giai đoạn"; was "Thẻ theo
 * tuổi") and reference Mốc phát triển. Staff write drafts in the portal; a different person
 * approves (D-058 pattern), then it is published one document per item:
 *
 * - `contentArticles/{id}`   — {@link ContentArticle}
 * - `contentStages/{id}`     — {@link ContentStage}
 * - `contentMilestones/{id}` — the reference milestone (`milestones.ts`, milestones slice)
 *
 * Signed-in users read published documents only; the app queries
 * `where('status', '==', 'published')` (the Rules require it for lists). Drafts live in
 * `contentDrafts/{id}` and are reached only through staff callables. Bodies are a safe block model
 * of plain text (no HTML or markup from staff ever reaches the app). Every string is vi + en
 * (D-012). Engineering drafts (D-073 #2) are published with `review: null` and
 * `illustrative: true`, shown "Nội dung minh hoạ · chờ chuyên môn duyệt" until a qualified reviewer
 * signs them; on prod publishing needs the review. Every published item is re-reviewed after
 * 12 months (B01 "Cần rà soát lại").
 */

// ---------- Kinds, collections, limits ----------

export const contentKinds = [
  'article',
  'stage',
  'milestone',
  // Dinh dưỡng theo giai đoạn (D-083): stages, micronutrients, suggestion rules.
  'nutritionStage',
  'nutrient',
  'nutritionRule',
  // Ăn dặm (D-085): the food catalogue and recipes.
  'food',
  'recipe',
] as const;
export type ContentKind = (typeof contentKinds)[number];

/** Where the app reads each published kind. */
export const contentCollections: Record<ContentKind, string> = {
  article: 'contentArticles',
  stage: 'contentStages',
  milestone: 'contentMilestones',
  nutritionStage: 'contentNutritionStages',
  nutrient: 'contentNutrients',
  nutritionRule: 'contentNutritionRules',
  food: 'contentFoods',
  recipe: 'contentRecipes',
};
/** Staff-only drafts (one per item, same id as the published document). */
export const contentDraftsCollection = 'contentDrafts';

export const contentLimits = {
  articleTitle: 90,
  summary: 240,
  paragraph: 2000,
  heading: 120,
  bullet: 400,
  bullets: 12,
  calloutTitle: 80,
  calloutText: 600,
  caption: 200,
  alt: 200,
  blocks: 60,
  keywords: 12,
  keyword: 40,
  relatedArticles: 4,
  articleMilestones: 6,
  articleSources: 8,
  readingMinutes: 60,
  /** Ages are counted from the date of birth; editorial content stops at 5 years. */
  maxAgeWeeks: 260,
  maxAgeMonths: 60,
  /** B06 "Tiêu đề trên thẻ · 60 ký tự". */
  stageTitle: 60,
  stagePoint: 140,
  /** B06 "tối đa 3 ý" per list. */
  stagePoints: 3,
  /** B06 "Bài viết liên quan (tối đa 2)". */
  stageArticles: 2,
  stageMilestones: 8,
  stageSources: 6,
  reviewerLabel: 80,
  notes: 500,
  /** B01 / B08: a published item is due for re-review 12 months after its review. */
  reReviewMonths: 12,
  /** Uploaded images (PNG / JPEG / WebP in, WebP out). */
  imageBytes: 1.5 * 1024 * 1024,
} as const;

const L = contentLimits;

// ---------- Plain text (never markup) ----------

/** True when [s] has no HTML-like tag or script URL: staff text is shown as plain text. */
export function isPlainText(s: string): boolean {
  return !/<\s*\/?\s*[a-zA-Z!?]/.test(s) && !/javascript\s*:/i.test(s);
}

const text = (max: number, min: number) =>
  z.string().trim().min(min).max(max).refine(isPlainText, 'Plain text only, no markup');
const loc = (max: number, min: number) =>
  z.object({ vi: text(max, min), en: text(max, min) }).strict();
const locList = (max: number, items: number, min: number) =>
  z
    .object({
      vi: z.array(text(max, 1)).min(min).max(items),
      en: z.array(text(max, 1)).min(min).max(items),
    })
    .strict();

// ---------- Images ----------

/** Images live at `content/library/{id}.webp` (public, immutable: a new image is a new id). */
export const contentImageIdSchema = z.string().regex(/^[a-z0-9-]{2,48}_[a-f0-9]{8}$/);
export const contentImagePath = (id: string) => `content/library/${id}.webp`;

export const contentImageUploadSchema = z
  .object({
    /** Becomes `{name}_{hash}`. */
    name: z.string().regex(/^[a-z0-9-]{2,40}$/),
    /** PNG, JPEG or WebP, base64. */
    data: z.base64().max(Math.ceil((L.imageBytes * 4) / 3) + 4),
  })
  .strict();

// ---------- Ids ----------

export const articleIdSchema = z.string().regex(/^art_[a-z0-9_]{2,60}$/);
export const stageIdSchema = z.string().regex(/^stg_[a-z0-9_]{2,40}$/);
/**
 * Reference milestone ids are owned by `milestones.ts`; here only their outer shape is checked
 * (links from articles and stages) so the two slices stay independent.
 */
export const contentMilestoneRefSchema = z.string().regex(/^[a-z][a-z0-9_]{1,63}$/);

// ---------- Taxonomy ----------

/** B01 "Thư viện": Chăm bé, Ăn dặm (5f). */
export const contentLibraries = ['care', 'solids'] as const;
export type ContentLibrary = (typeof contentLibraries)[number];

/** 4a topic tiles, in order: Bú & sữa, Giấc ngủ, Mọc răng, Sốt & ốm vặt, Chăm hằng ngày, Phát triển. */
export const articleTopics = [
  'feeding',
  'sleep',
  'teething',
  'illness',
  'daily_care',
  'development',
] as const;
export type ArticleTopic = (typeof articleTopics)[number];

/**
 * Thư viện ăn dặm groups (D-087): each has its own picture in the app, so the list does not repeat
 * one icon. Bắt đầu · Cách cho ăn · Kết cấu · Dinh dưỡng · Dị ứng · An toàn · Thực đơn · Kỹ năng ăn
 * · Sức khoẻ · Đồ dùng · Ăn cùng gia đình.
 */
export const solidsSubtopics = [
  'start',
  'methods',
  'textures',
  'nutrition',
  'allergy',
  'safety',
  'menus',
  'skills',
  'health',
  'gear',
  'family',
] as const;
export type SolidsSubtopic = (typeof solidsSubtopics)[number];

/**
 * The family's emergency number in content text (D-078, D-087): the app writes the number of the
 * family's country (115 in Việt Nam, 911 in the US…), so content never says "115" itself.
 */
export const contentEmergencyToken = '{emergency}';

/**
 * Places where a text says "115" instead of `{emergency}` (sources excluded): the portal warns,
 * the seed tests refuse.
 */
export function literalEmergencyProblems(data: unknown): { path: string; match: string }[] {
  const out: { path: string; match: string }[] = [];
  const visit = (v: unknown, path: string[]) => {
    if (typeof v === 'string') {
      if (path.includes('sources')) return;
      const m = v.match(/(?<![\d.,])115(?!\d|[.,]\d)/);
      if (m) out.push({ path: path.join('.'), match: m[0] });
    } else if (Array.isArray(v)) v.forEach((x, i) => visit(x, [...path, String(i)]));
    else if (v && typeof v === 'object') {
      for (const [k, x] of Object.entries(v)) visit(x, [...path, k]);
    }
  };
  visit(data, []);
  return out;
}

/** 4c "Dạng nội dung": Bài viết, Hướng dẫn từng bước, Hỏi nhanh (all use the same blocks). */
export const articleFormats = ['article', 'step_guide', 'quick_qa'] as const;
export type ArticleFormat = (typeof articleFormats)[number];

/**
 * Callout tints: "Khi nào nên hỏi bác sĩ" (4d, sunshine-soft), a plain note, a tip, and
 * `urgent` ("Gọi {emergency} ngay khi…", D-087): red, with a call button to the family's number.
 */
export const calloutTones = ['doctor', 'note', 'tip', 'urgent'] as const;
export type CalloutTone = (typeof calloutTones)[number];

// ---------- Body blocks (4d) ----------

function blockSchema(min: number) {
  return z.discriminatedUnion('type', [
    z.object({ type: z.literal('paragraph'), text: text(L.paragraph, min) }).strict(),
    z.object({ type: z.literal('heading'), text: text(L.heading, min) }).strict(),
    z
      .object({
        type: z.literal('bullets'),
        items: z.array(text(L.bullet, min)).min(min).max(L.bullets),
      })
      .strict(),
    z
      .object({
        type: z.literal('callout'),
        tone: z.enum(calloutTones),
        title: text(L.calloutTitle, min),
        text: text(L.calloutText, min),
      })
      .strict(),
    z
      .object({
        type: z.literal('image'),
        image: contentImageIdSchema,
        /** Shown under the picture; empty = none. */
        caption: text(L.caption, 0),
        /** Read by screen readers. */
        alt: text(L.alt, min),
      })
      .strict(),
  ]);
}
export const contentBlockSchema = blockSchema(1);
export type ContentBlock = z.infer<typeof contentBlockSchema>;
export const contentBlockTypes = ['paragraph', 'heading', 'bullets', 'callout', 'image'] as const;
export type ContentBlockType = (typeof contentBlockTypes)[number];

/** Image ids used by [blocks] (cover excluded). */
export function blockImages(blocks: readonly ContentBlock[]): string[] {
  return blocks.flatMap((b) => (b.type === 'image' ? [b.image] : []));
}

/** Words in a block list (for the reading time). */
export function blockWords(blocks: readonly ContentBlock[]): number {
  const words = (s: string) => s.split(/\s+/).filter(Boolean).length;
  return blocks.reduce((n, b) => {
    switch (b.type) {
      case 'paragraph':
      case 'heading':
        return n + words(b.text);
      case 'bullets':
        return n + b.items.reduce((m, i) => m + words(i), 0);
      case 'callout':
        return n + words(b.title) + words(b.text);
      case 'image':
        return n + words(b.caption);
    }
  }, 0);
}

/** "6 phút đọc": about 200 words a minute (Vietnamese counts syllables as words), at least 1. */
export function readingMinutesOf(blocks: readonly ContentBlock[]): number {
  return Math.max(1, Math.min(L.readingMinutes, Math.round(blockWords(blocks) / 200)));
}

// ---------- Article (4a–4f, B01/B02) ----------

/** Age range in completed weeks from the date of birth, `to` exclusive (4b matches on overlap). */
const ageWeeksSchema = z
  .object({
    from: z.number().int().min(0).max(L.maxAgeWeeks),
    to: z.number().int().min(1).max(L.maxAgeWeeks),
  })
  .strict()
  .refine((a) => a.to > a.from, 'Age range ends before it starts');

const imageRefSchema = (min: number) =>
  z.object({ image: contentImageIdSchema, alt: loc(L.alt, min) }).strict();

function articleContentSchema(strict: boolean) {
  const min = strict ? 1 : 0;
  const block = blockSchema(min);
  return z
    .object({
      library: z.enum(contentLibraries),
      topic: z.enum(articleTopics),
      /** Thư viện ăn dặm group (D-087); absent on care articles and older drafts. */
      subtopic: z.enum(solidsSubtopics).nullable().optional(),
      format: z.enum(articleFormats),
      ageWeeks: ageWeeksSchema,
      readingMinutes: z.number().int().min(1).max(L.readingMinutes),
      cover: imageRefSchema(min).nullable(),
      title: loc(L.articleTitle, min),
      summary: loc(L.summary, min),
      body: z
        .object({
          vi: z.array(block).min(min).max(L.blocks),
          en: z.array(block).min(min).max(L.blocks),
        })
        .strict(),
      /** Search terms beyond the title ("ngủ ngày, nấc, hăm tã"). */
      keywords: locList(L.keyword, L.keywords, 0),
      relatedArticleIds: z.array(articleIdSchema).max(L.relatedArticles),
      milestoneIds: z.array(contentMilestoneRefSchema).max(L.articleMilestones),
      sources: z.array(contentSourceSchema).max(L.articleSources),
    })
    .strict();
}

/** What staff edit (a draft may be incomplete). */
export const articleDraftSchema = articleContentSchema(false);
export type ArticleDraft = z.infer<typeof articleDraftSchema>;
/** What can be submitted and published: complete in vi and en. */
export const articleContentStrictSchema = articleContentSchema(true);
export type ArticleContent = z.infer<typeof articleContentStrictSchema>;

// ---------- Stage content: "Giai đoạn của bé" (2a/2b, B05/B06) ----------

export const stageUnits = ['week', 'month'] as const;
export type StageUnit = (typeof stageUnits)[number];

/** B06 "Từ … Đến (trước)": completed weeks or months from the date of birth, `to` exclusive. */
export const stageAgeSchema = z
  .object({
    unit: z.enum(stageUnits),
    from: z.number().int().min(0),
    to: z.number().int().min(1),
  })
  .strict()
  .refine((a) => a.to > a.from, 'Age range ends before it starts')
  .refine(
    (a) => a.to <= (a.unit === 'week' ? L.maxAgeWeeks : L.maxAgeMonths),
    'Age range too long',
  );
export type StageAge = z.infer<typeof stageAgeSchema>;

/** B06 "Hiện với": Bố mẹ (Cùng nuôi), Người chăm, Gia đình (relatives). */
export const stageAudienceSchema = z.array(z.enum(memberRoles)).min(1).max(memberRoles.length);

function stageContentSchema(strict: boolean) {
  const min = strict ? 1 : 0;
  return z
    .object({
      age: stageAgeSchema,
      title: loc(L.stageTitle, min),
      /** "Bé đang thế nào" (≤ 3). */
      doing: locList(L.stagePoint, L.stagePoints, min),
      /** "Ba mẹ có thể thử" (≤ 3). */
      tryThis: locList(L.stagePoint, L.stagePoints, min),
      articleIds: z.array(articleIdSchema).max(L.stageArticles),
      milestoneIds: z.array(contentMilestoneRefSchema).max(L.stageMilestones),
      audience: stageAudienceSchema,
      cover: imageRefSchema(min).nullable(),
      sources: z.array(contentSourceSchema).max(L.stageSources),
    })
    .strict();
}
export const stageDraftSchema = stageContentSchema(false);
export type StageDraft = z.infer<typeof stageDraftSchema>;
const sameLists = (s: StageDraft) =>
  s.doing.vi.length === s.doing.en.length && s.tryThis.vi.length === s.tryThis.en.length;
export const stageContentStrictSchema = stageContentSchema(true).refine(
  sameLists,
  'vi and en lists differ in length',
);
export type StageContent = z.infer<typeof stageContentStrictSchema>;

// ---------- Published documents (what the app reads) ----------

/**
 * Who signed the item off (`null` = engineering draft, D-073 #2). Re-exported from `rhythm.ts`
 * so both content families share one review shape.
 */
export const editorialReviewSchema = contentReviewSchema;
export type EditorialReview = z.infer<typeof editorialReviewSchema>;

const publishedMeta = {
  status: z.literal('published'),
  /** 1 on first publish, +1 on every later publish (the app refreshes its copy when it grows). */
  revision: z.number().int().min(1),
  review: editorialReviewSchema,
  /** True until a qualified reviewer signs it: "Nội dung minh hoạ · chờ chuyên môn duyệt". */
  illustrative: z.boolean(),
  /** 12 months after the review (or the publish when not reviewed yet). */
  reviewDueOn: z.iso.date(),
  /** ISO timestamps. */
  publishedAt: z.iso.datetime(),
  /** First publish of the item ("Mới cập nhật" sorts by `publishedAt`). */
  firstPublishedAt: z.iso.datetime(),
};
const reviewConsistent = (d: { review: EditorialReview; illustrative: boolean }) =>
  d.illustrative === (d.review === null);

/** `contentArticles/{id}`. */
export const contentArticleSchema = articleContentSchema(true)
  .extend({ id: articleIdSchema, ...publishedMeta })
  .strict()
  .refine(reviewConsistent, 'illustrative must match review');
export type ContentArticle = z.infer<typeof contentArticleSchema>;

/** `contentStages/{id}`. */
export const contentStageSchema = stageContentSchema(true)
  .extend({ id: stageIdSchema, ...publishedMeta })
  .strict()
  .refine(reviewConsistent, 'illustrative must match review')
  .refine(sameLists, 'vi and en lists differ in length');
export type ContentStage = z.infer<typeof contentStageSchema>;

/** `contentNutritionStages/{id}` (D-083). */
export const contentNutritionStageSchema = nutritionStageSchema(true)
  .extend({ id: nutritionStageIdSchema, ...publishedMeta })
  .strict()
  .refine(reviewConsistent, 'illustrative must match review');
export type ContentNutritionStage = z.infer<typeof contentNutritionStageSchema>;

/** `contentNutrients/{id}` (D-083). */
export const contentNutrientSchema = nutrientSchema(true)
  .extend({ id: nutrientIdSchema, ...publishedMeta })
  .strict()
  .refine(reviewConsistent, 'illustrative must match review');
export type ContentNutrient = z.infer<typeof contentNutrientSchema>;

/** `contentNutritionRules/{id}` (D-083). */
export const contentNutritionRuleSchema = nutritionRuleSchema(true)
  .extend({ id: nutritionRuleIdSchema, ...publishedMeta })
  .strict()
  .refine(reviewConsistent, 'illustrative must match review')
  .refine(ruleFits, 'This condition does not apply to the metric');
export type ContentNutritionRule = z.infer<typeof contentNutritionRuleSchema>;

/** `contentFoods/{id}` (D-085). */
export const contentFoodSchema = solidsFoodSchema(true)
  .extend({ id: foodIdSchema, ...publishedMeta })
  .strict()
  .refine(reviewConsistent, 'illustrative must match review');
export type ContentFood = z.infer<typeof contentFoodSchema>;

/** `contentRecipes/{id}` (D-085). */
export const contentRecipeSchema = solidsRecipeSchema(true)
  .extend({ id: recipeIdSchema, ...publishedMeta })
  .strict()
  .refine(reviewConsistent, 'illustrative must match review')
  .refine(recipeStepsSame, 'vi and en steps differ');
export type ContentRecipe = z.infer<typeof contentRecipeSchema>;

// ---------- Review workflow (B03/B04) ----------

/** Nháp → Chờ duyệt → Đã duyệt → Xuất bản; Lưu trữ = taken off the app or dropped. */
export const editorialStatuses = [
  'draft',
  'in_review',
  'approved',
  'published',
  'archived',
] as const;
export type EditorialStatus = (typeof editorialStatuses)[number];
/** What lists show: a published item past its re-review date is "Cần rà soát lại". */
export const editorialDisplayStatuses = [...editorialStatuses, 'needs_rereview'] as const;
export type EditorialDisplayStatus = (typeof editorialDisplayStatuses)[number];

export function editorialDisplayStatus(
  item: { status: EditorialStatus; reviewDueOn: string | null },
  today: string,
): EditorialDisplayStatus {
  return item.status === 'published' && item.reviewDueOn !== null && item.reviewDueOn < today
    ? 'needs_rereview'
    : item.status;
}

/** B03 checklist: the approver ticks every line. */
export const editorialChecks = ['accuracy', 'safety', 'sources', 'tone', 'bilingual'] as const;
export type EditorialCheck = (typeof editorialChecks)[number];

/** "2026-10-15" + 12 months → "2027-10-15" (end-of-month clamps: Jan 31 + 1 → Feb 28/29). */
export function addMonthsIso(date: string, months: number): string {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  const total = y * 12 + (m - 1) + months;
  const ny = Math.floor(total / 12);
  const nm = total % 12;
  const last = new Date(Date.UTC(ny, nm + 1, 0)).getUTCDate();
  return `${String(ny).padStart(4, '0')}-${String(nm + 1).padStart(2, '0')}-${String(Math.min(d, last)).padStart(2, '0')}`;
}

/** The re-review date for an item reviewed (or published) on [on]. */
export function reviewDueFrom(on: string): string {
  return addMonthsIso(on, L.reReviewMonths);
}

// ---------- Ages (app and server compute the same answers) ----------

/** Completed weeks or calendar months between [birthDate] and [today] (YYYY-MM-DD), ≥ 0. */
export function ageInUnit(birthDate: string, today: string, unit: StageUnit): number {
  const days = daysBetweenIso(birthDate, today);
  if (days <= 0) return 0;
  if (unit === 'week') return Math.floor(days / 7);
  const [by, bm, bd] = birthDate.split('-').map(Number) as [number, number, number];
  const [ty, tm, td] = today.split('-').map(Number) as [number, number, number];
  let months = (ty - by) * 12 + (tm - bm);
  // A month is complete on the same day of the month (or the month's last day when shorter).
  const lastOfThisMonth = new Date(Date.UTC(ty, tm, 0)).getUTCDate();
  if (td < Math.min(bd, lastOfThisMonth)) months -= 1;
  return Math.max(0, months);
}

const DAYS_PER_MONTH = 30.4375;
/** Approximate day span of a stage age (for ordering, coverage and the narrowest match). */
export function stageAgeDays(age: { unit: StageUnit; from: number; to: number }) {
  const k = age.unit === 'week' ? 7 : DAYS_PER_MONTH;
  return { from: age.from * k, to: age.to * k };
}

/** True when the baby born on [birthDate] is inside [age] on [today]. */
export function stageAgeContains(
  age: { unit: StageUnit; from: number; to: number },
  birthDate: string,
  today: string,
): boolean {
  if (daysBetweenIso(birthDate, today) < 0) return false;
  const n = ageInUnit(birthDate, today, age.unit);
  return n >= age.from && n < age.to;
}

/**
 * 2a "Bé đang ở đây": the stage for the baby's age today. When ranges overlap (3–4 tuần and
 * 1–2 tháng around day 30–34), the narrowest wins, then the later start. Null before birth or
 * when nothing covers the age.
 */
export function stageFor<T extends { age: StageAge }>(
  stages: readonly T[],
  birthDate: string,
  today: string,
): T | null {
  const hits = stages.filter((s) => stageAgeContains(s.age, birthDate, today));
  hits.sort((a, b) => {
    const x = stageAgeDays(a.age);
    const y = stageAgeDays(b.age);
    return x.to - x.from - (y.to - y.from) || y.from - x.from;
  });
  return hits[0] ?? null;
}

/** 2a order: by start age, then by end. */
export function sortStages<T extends { age: StageAge }>(stages: readonly T[]): T[] {
  return [...stages].sort((a, b) => {
    const x = stageAgeDays(a.age);
    const y = stageAgeDays(b.age);
    return x.from - y.from || x.to - y.to;
  });
}

/** 4b age filter: an article matches an age band when the ranges overlap (`to` exclusive). */
export function articleOverlapsWeeks(
  article: { ageWeeks: { from: number; to: number } },
  from: number,
  to: number,
): boolean {
  return article.ageWeeks.from < to && from < article.ageWeeks.to;
}

/** "Hợp với {bé}": articles whose range holds the baby's age in completed weeks. */
export function articleFitsAge(
  article: { ageWeeks: { from: number; to: number } },
  birthDate: string,
  today: string,
): boolean {
  const w = ageInUnit(birthDate, today, 'week');
  return w >= article.ageWeeks.from && w < article.ageWeeks.to;
}

// ---------- Coverage 0–24 months (B05 "14 / 16 khoảng có thẻ") ----------

export interface StageBucket {
  id: string;
  unit: StageUnit;
  from: number;
  to: number;
}

/** The 16 fixed ranges: 0–2 and 3–4 weeks, months 1–12 one by one, then 12–15, 15–18, 18–24. */
export const stageBuckets: readonly StageBucket[] = [
  { id: 'w0', unit: 'week', from: 0, to: 3 },
  { id: 'w3', unit: 'week', from: 3, to: 5 },
  ...Array.from({ length: 11 }, (_, i) => ({
    id: `m${i + 1}`,
    unit: 'month' as const,
    from: i + 1,
    to: i + 2,
  })),
  { id: 'm12', unit: 'month', from: 12, to: 15 },
  { id: 'm15', unit: 'month', from: 15, to: 18 },
  { id: 'm18', unit: 'month', from: 18, to: 24 },
  // 24–36 months (D-080): two half-year stages.
  { id: 'm24', unit: 'month', from: 24, to: 30 },
  { id: 'm30', unit: 'month', from: 30, to: 36 },
];

/** Bucket state, best first: on the app, waiting for review / publish, a draft, nothing. */
export const coverageStates = ['published', 'pending', 'draft', 'missing'] as const;
export type CoverageState = (typeof coverageStates)[number];

/** True when [age] spans the whole bucket (half a day of slack for week/month rounding). */
export function stageCoversBucket(
  age: { unit: StageUnit; from: number; to: number },
  bucket: StageBucket,
): boolean {
  const a = stageAgeDays(age);
  const b = stageAgeDays(bucket);
  return a.from <= b.from + 0.5 && a.to >= b.to - 0.5;
}

export interface CoverageItem {
  age: { unit: StageUnit; from: number; to: number };
  status: EditorialStatus;
  /** A published revision is on the app (possibly with a newer draft being edited). */
  live: boolean;
}

export function stageCoverage(items: readonly CoverageItem[]) {
  const stateOf = (i: CoverageItem): CoverageState | null =>
    i.live
      ? 'published'
      : i.status === 'in_review' || i.status === 'approved'
        ? 'pending'
        : i.status === 'draft'
          ? 'draft'
          : null;
  const buckets = stageBuckets.map((bucket) => {
    const states = items
      .filter((i) => stageCoversBucket(i.age, bucket))
      .map(stateOf)
      .filter((s): s is CoverageState => s !== null);
    const state =
      coverageStates.find((s) => s !== 'missing' && states.includes(s)) ?? ('missing' as const);
    return { ...bucket, state };
  });
  return {
    buckets,
    /** "14 / 16 khoảng có thẻ": buckets with any card, drafts included. */
    covered: buckets.filter((b) => b.state !== 'missing').length,
    published: buckets.filter((b) => b.state === 'published').length,
    total: buckets.length,
    gaps: buckets.filter((b) => b.state === 'missing').map((b) => b.id),
  };
}

// ---------- Staff callables ----------

const reasonText = z.string().trim().max(500);

export const contentListRequestSchema = z
  .object({ view: z.enum([...contentKinds, 'queue']) })
  .strict();
export const contentItemRequestSchema = z
  .object({ kind: z.enum(contentKinds), id: z.string().min(3).max(80) })
  .strict();

const saveCommon = {
  /** B01 filter "Người duyệt": who is expected to review (free text, e.g. "BS. Hà · Nhi khoa"). */
  reviewerLabel: text(L.reviewerLabel, 0).nullable(),
  notes: text(L.notes, 0),
};
/**
 * "Lưu nháp" (B02, B06, B08). `id: null` creates an item (the server picks the id). The
 * milestone payload is validated by the milestones contract on the server.
 */
export const contentSaveRequestSchema = z.discriminatedUnion('kind', [
  z
    .object({
      kind: z.literal('article'),
      id: articleIdSchema.nullable(),
      data: articleDraftSchema,
      ...saveCommon,
    })
    .strict(),
  z
    .object({
      kind: z.literal('stage'),
      id: stageIdSchema.nullable(),
      data: stageDraftSchema,
      ...saveCommon,
    })
    .strict(),
  z
    .object({
      kind: z.literal('milestone'),
      id: contentMilestoneRefSchema.nullable(),
      data: z.record(z.string(), z.unknown()),
      ...saveCommon,
    })
    .strict(),
  z
    .object({
      kind: z.literal('nutritionStage'),
      id: nutritionStageIdSchema.nullable(),
      data: nutritionStageDraftSchema,
      ...saveCommon,
    })
    .strict(),
  z
    .object({
      kind: z.literal('nutrient'),
      id: nutrientIdSchema.nullable(),
      data: nutrientDraftSchema,
      ...saveCommon,
    })
    .strict(),
  z
    .object({
      kind: z.literal('nutritionRule'),
      id: nutritionRuleIdSchema.nullable(),
      data: nutritionRuleDraftSchema,
      ...saveCommon,
    })
    .strict(),
  z
    .object({
      kind: z.literal('food'),
      id: foodIdSchema.nullable(),
      data: foodDraftSchema,
      ...saveCommon,
    })
    .strict(),
  z
    .object({
      kind: z.literal('recipe'),
      id: recipeIdSchema.nullable(),
      data: recipeDraftSchema,
      ...saveCommon,
    })
    .strict(),
]);
export type ContentSaveRequest = z.infer<typeof contentSaveRequestSchema>;

export const editorialActions = [
  /** Nháp → Chờ duyệt (Nội dung · Sửa). */
  'submit',
  /** Chờ duyệt → Đã duyệt (Nội dung · Duyệt, never the last editor). */
  'approve',
  /** Chờ duyệt / Đã duyệt → Nháp, with a reason. */
  'reject',
  /** Đã duyệt → Xuất bản: written to the app (Nội dung · Duyệt). */
  'publish',
  /** Take a published item off the app, with a reason. */
  'unpublish',
  /** Drop a draft that never reached the app. */
  'archive',
  /** "Cần rà soát lại": a reviewer confirms the published text still holds (new review date). */
  'reconfirm',
] as const;
export type EditorialAction = (typeof editorialActions)[number];

export const contentActRequestSchema = z
  .object({
    kind: z.enum(contentKinds),
    id: z.string().min(3).max(80),
    action: z.enum(editorialActions),
    reason: reasonText,
    /** Approve / reconfirm: the qualified review (required on prod). */
    review: editorialReviewSchema.optional(),
    /** Approve: every B03 checklist line. */
    checks: z.array(z.enum(editorialChecks)).max(editorialChecks.length).optional(),
  })
  .strict()
  .superRefine((r, ctx) => {
    if (['reject', 'unpublish'].includes(r.action) && r.reason.length < 3) {
      ctx.addIssue({ code: 'custom', message: 'A reason is required', path: ['reason'] });
    }
    if (r.action === 'approve' && !editorialChecks.every((c) => r.checks?.includes(c))) {
      ctx.addIssue({ code: 'custom', message: 'Every check is required', path: ['checks'] });
    }
  });
export type ContentActRequest = z.infer<typeof contentActRequestSchema>;

/** Imports the engineering drafts (D-073 #2) that are not there yet; never overwrites. */
export const contentSeedRequestSchema = z
  .object({
    kinds: z.array(z.enum(contentKinds)).min(1).max(contentKinds.length),
    /**
     * Reference milestones come from the milestones slice's seed file
     * (`content/milestones/milestones.seed.json`, `milestoneSeedSchema`), picked in the portal;
     * articles and stages are bundled with the server.
     */
    milestoneSeed: z.unknown().optional(),
  })
  .strict();

// ---------- Helpers shared by server and portal ----------

/** "0–2 tuần" style label parts for an age (the portal and app localise the unit). */
export function stageAgeLabel(age: { unit: StageUnit; from: number; to: number }) {
  return { unit: age.unit, from: age.from, last: age.to - 1 };
}

/** The ids an item links to (to check they exist before publishing). */
export function contentLinks(kind: ContentKind, data: Record<string, unknown>) {
  if (kind === 'article') {
    const a = data as Partial<ArticleDraft>;
    return { articles: a.relatedArticleIds ?? [], milestones: a.milestoneIds ?? [] };
  }
  if (kind === 'stage') {
    const s = data as Partial<StageDraft>;
    return { articles: s.articleIds ?? [], milestones: s.milestoneIds ?? [] };
  }
  return { articles: [] as string[], milestones: [] as string[] };
}

/** Image ids an article or stage uses (cover and figures). */
export function contentImages(kind: ContentKind, data: Record<string, unknown>): string[] {
  const out = new Set<string>();
  const cover = (data.cover as { image?: string } | null | undefined)?.image;
  if (cover) out.add(cover);
  if (kind === 'article') {
    const body = (data as Partial<ArticleDraft>).body;
    for (const b of [...(body?.vi ?? []), ...(body?.en ?? [])]) {
      if (b.type === 'image') out.add(b.image);
    }
  }
  // Reference milestones (milestones.ts): the 3b illustration.
  const illustration = (data as { illustration?: { image?: string } | null }).illustration?.image;
  if (illustration) out.add(illustration);
  return [...out];
}
