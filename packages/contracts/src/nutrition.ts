import { z } from 'zod';
import { contentSourceSchema } from './rhythm.js';

/**
 * Dinh dưỡng theo giai đoạn (D-083, P-163; Figma app 9a–9g, portal D01–D04; plan
 * `docs/product/nutrition-plan.md`). Three editorial kinds on the D-076 workflow:
 * - **NutritionStage** (`nst_…`): what to feed at an age (milk reference, solids, a sample day,
 *   micronutrients to watch, tips);
 * - **Nutrient** (`nut_…`): a micronutrient article (why, foods, by age, the medical note), with
 *   the vitamin A campaign days as structured rounds;
 * - **NutritionRule** (`nru_…`): when the baby's own data matches (growth outside WHO P3–P97 on
 *   the 2 latest measurements, milk outside the stage band, no measurement for a while), the app
 *   shows the rule's calm banner and tips. Rules are evaluated on the device; no child data goes
 *   to the server for them.
 * Text is `{vi, en}` plain text. Copy never names a condition ("suy dinh dưỡng", "béo phì",
 * "chậm lớn", "thiếu chất") and never gives a dose (`nutritionCopyProblems`).
 */

export const nutritionLimits = {
  /** Stages run on completed months from the date of birth, up to 36 months (D-083). */
  maxAgeMonths: 36,
  stageTitle: 60,
  stageSummary: 220,
  amountText: 80,
  sampleDay: 8,
  sampleText: 100,
  stageNutrients: 6,
  tips: 4,
  tipTitle: 60,
  tipBody: 220,
  sources: 8,
  nutrientName: 40,
  nutrientSubtitle: 90,
  focusLabel: 60,
  focusNote: 90,
  why: 400,
  foods: 12,
  food: 30,
  tip: 240,
  byAge: 6,
  byAgeLabel: 30,
  byAgeText: 160,
  warning: 240,
  rounds: 4,
  place: 80,
  banner: 240,
  /** Daily milk amounts are entered in ml, at most 2 litres. */
  maxMl: 2000,
  maxFeeds: 16,
} as const;
const N = nutritionLimits;

// ---------- Plain text ----------

const plain = (s: string) => !/<\s*\/?\s*[a-zA-Z!?]/.test(s) && !/javascript\s*:/i.test(s);
const text = (max: number, min: number) =>
  z.string().trim().min(min).max(max).refine(plain, 'Plain text only, no markup');
const loc = (max: number, min: number) =>
  z.object({ vi: text(max, min), en: text(max, min) }).strict();

// ---------- Ids ----------

export const nutritionStageIdSchema = z.string().regex(/^nst_[a-z0-9_]{2,40}$/);
export const nutrientIdSchema = z.string().regex(/^nut_[a-z0-9_]{2,40}$/);
export const nutritionRuleIdSchema = z.string().regex(/^nru_[a-z0-9_]{2,40}$/);

// ---------- Shared pieces ----------

/** Completed months from the date of birth, `to` exclusive (the last stage may end at 36). */
export const nutritionAgeSchema = z
  .object({
    from: z.number().int().min(0).max(N.maxAgeMonths),
    to: z
      .number()
      .int()
      .min(1)
      .max(N.maxAgeMonths + 1),
  })
  .strict()
  .refine((a) => a.to > a.from, 'The range must end after it starts');
export type NutritionAge = z.infer<typeof nutritionAgeSchema>;

const rangeSchema = (max: number) =>
  z
    .object({ min: z.number().int().min(0).max(max), max: z.number().int().min(0).max(max) })
    .strict()
    .refine((r) => r.max >= r.min, 'max must be at least min');
export type NumberRange = { min: number; max: number };

const tipSchema = (min: number) =>
  z.object({ title: loc(N.tipTitle, min), body: loc(N.tipBody, min) }).strict();

// ---------- NutritionStage ----------

export const sampleSlots = ['morning', 'noon', 'afternoon', 'evening', 'night'] as const;
export type SampleSlot = (typeof sampleSlots)[number];
export const sampleKinds = ['milk', 'solids', 'snack', 'sleep'] as const;
export type SampleKind = (typeof sampleKinds)[number];

/** The stage object (unrefined, so published documents can extend it). */
export function nutritionStageSchema(strict: boolean) {
  const min = strict ? 1 : 0;
  return z
    .object({
      ageMonths: nutritionAgeSchema,
      title: loc(N.stageTitle, min),
      summary: loc(N.stageSummary, min),
      /** Reference amounts for bottle feeding; each part optional (0–1 month has no daily band). */
      milk: z
        .object({
          perFeedMl: rangeSchema(N.maxMl).nullable(),
          feedsPerDay: rangeSchema(N.maxFeeds).nullable(),
          perDayMl: rangeSchema(N.maxMl).nullable(),
          /** "Cho bú theo nhu cầu." */
          breastfeedingNote: loc(N.amountText, 0),
        })
        .strict()
        .nullable(),
      solids: z
        .object({
          /** "2–3 bữa", "3 bữa + 1–2 bữa phụ". */
          meals: loc(N.amountText, min),
          /** "Bột loãng → cháo rây, nghiền". */
          texture: loc(N.amountText, 0),
        })
        .strict()
        .nullable(),
      sampleDay: z
        .array(
          z
            .object({
              slot: z.enum(sampleSlots),
              kind: z.enum(sampleKinds),
              text: loc(N.sampleText, min),
            })
            .strict(),
        )
        .max(N.sampleDay),
      nutrientIds: z.array(nutrientIdSchema).max(N.stageNutrients),
      /** "Gợi ý cho {bé}" while no growth rule fires. */
      tips: z.array(tipSchema(min)).max(N.tips),
      sources: z.array(contentSourceSchema).max(N.sources),
    })
    .strict();
}
export const nutritionStageDraftSchema = nutritionStageSchema(false);
export type NutritionStageDraft = z.infer<typeof nutritionStageDraftSchema>;
export const nutritionStageStrictSchema = nutritionStageSchema(true);
export type NutritionStageContent = z.infer<typeof nutritionStageStrictSchema>;

// ---------- Nutrient ----------

/** Picks the icon and tint in the app; `other` uses a neutral leaf. */
export const nutrientKeys = [
  'iron',
  'zinc',
  'vitaminD',
  'vitaminA',
  'calcium',
  'dha',
  'iodine',
  'fibre',
  'other',
] as const;
export type NutrientKey = (typeof nutrientKeys)[number];

/** One campaign round: a month and its days (1–2/6 and 1–2/12 for vitamin A in Việt Nam). */
export const nutrientRoundSchema = z
  .object({
    month: z.number().int().min(1).max(12),
    fromDay: z.number().int().min(1).max(31),
    toDay: z.number().int().min(1).max(31),
  })
  .strict()
  .refine((r) => r.toDay >= r.fromDay, 'toDay must be on or after fromDay');
export type NutrientRound = z.infer<typeof nutrientRoundSchema>;

/** The nutrient object (unrefined, so published documents can extend it). */
export function nutrientSchema(strict: boolean) {
  const min = strict ? 1 : 0;
  return z
    .object({
      key: z.enum(nutrientKeys),
      name: loc(N.nutrientName, min),
      /** The 9b row line: "Dự trữ từ lúc sinh giảm dần · thịt, trứng, gan". */
      subtitle: loc(N.nutrientSubtitle, min),
      focus: z
        .object({
          ageMonths: nutritionAgeSchema,
          /** "Quan trọng từ 6 tháng". */
          label: loc(N.focusLabel, min),
          /** "4–6 tháng nếu bú mẹ". */
          note: loc(N.focusNote, 0),
        })
        .strict(),
      why: loc(N.why, min),
      foods: z.array(loc(N.food, min)).max(N.foods),
      tip: loc(N.tip, min).nullable(),
      byAge: z
        .array(
          z
            .object({
              ageMonths: nutritionAgeSchema.nullable(),
              label: loc(N.byAgeLabel, min),
              text: loc(N.byAgeText, min),
            })
            .strict(),
        )
        .max(N.byAge),
      /** The medical note: "Dạng thuốc chỉ theo chỉ định bác sĩ. Thừa sắt có thể gây hại." */
      warning: loc(N.warning, min),
      /** Vitamin A: national campaign days, free at the ward / commune health station. */
      campaign: z
        .object({
          rounds: z.array(nutrientRoundSchema).min(1).max(N.rounds),
          ageMonths: nutritionAgeSchema,
          place: loc(N.place, min),
        })
        .strict()
        .nullable(),
      sources: z.array(contentSourceSchema).max(N.sources),
    })
    .strict();
}
export const nutrientDraftSchema = nutrientSchema(false);
export type NutrientDraft = z.infer<typeof nutrientDraftSchema>;
export const nutrientStrictSchema = nutrientSchema(true);
export type NutrientContent = z.infer<typeof nutrientStrictSchema>;

// ---------- NutritionRule ----------

export const nutritionMetrics = ['weight', 'length', 'milk', 'measurement'] as const;
export type NutritionMetric = (typeof nutritionMetrics)[number];
export const nutritionConditions = [
  'belowRange',
  'aboveRange',
  'milkOutsideStage',
  'noMeasurement',
] as const;
export type NutritionCondition = (typeof nutritionConditions)[number];

/** Which conditions make sense for a metric (the portal offers only these). */
export const conditionsFor: Record<NutritionMetric, readonly NutritionCondition[]> = {
  weight: ['belowRange', 'aboveRange'],
  length: ['belowRange', 'aboveRange'],
  milk: ['milkOutsideStage'],
  measurement: ['noMeasurement'],
};

/** The rule object (unrefined, so published documents can extend it); see `ruleFits`. */
export function nutritionRuleSchema(strict: boolean) {
  const min = strict ? 1 : 0;
  return z
    .object({
      metric: z.enum(nutritionMetrics),
      condition: z.enum(nutritionConditions),
      /** `noMeasurement`: days without a weight or length (default 30). */
      days: z.number().int().min(7).max(120).nullable(),
      ageMonths: nutritionAgeSchema,
      banner: loc(N.banner, min),
      tips: z.array(tipSchema(min)).max(N.tips),
      /** "Nhắc đo lại sau 2 tuần": an all-day reminder this many days ahead. */
      remindAfterDays: z.number().int().min(7).max(60).nullable(),
      /** "Xuất báo cáo cho bác sĩ" (growth rules). */
      export: z.boolean(),
    })
    .strict();
}
/** The condition must belong to the metric (`conditionsFor`). */
export const ruleFits = (r: { metric: NutritionMetric; condition: NutritionCondition }) =>
  conditionsFor[r.metric].includes(r.condition);
const ruleFitsIssue = {
  message: 'This condition does not apply to the metric',
  path: ['condition'],
};
export const nutritionRuleDraftSchema = nutritionRuleSchema(false).refine(ruleFits, ruleFitsIssue);
export type NutritionRuleDraft = z.infer<typeof nutritionRuleDraftSchema>;
export const nutritionRuleStrictSchema = nutritionRuleSchema(true).refine(ruleFits, ruleFitsIssue);
export type NutritionRuleContent = z.infer<typeof nutritionRuleStrictSchema>;

// ---------- Safe copy (P-163) ----------

/**
 * Words the copy never uses: the app describes a position against the WHO range and suggests a
 * check-up, it never names a condition.
 */
export const nutritionForbiddenWords = [
  'suy dinh dưỡng',
  'béo phì',
  'chậm lớn',
  'thiếu chất',
  'còi xương',
  'malnutrition',
  'malnourished',
  'obese',
  'obesity',
  'stunted',
  'failure to thrive',
] as const;

/** A dose: a number followed by mg, mcg, µg, IU / UI or ml/kg. */
const dosePattern = /\d[\d.,]*\s*(mg|mcg|µg|μg|iu|ui|đvqt|ml\/kg)\b/i;

export interface CopyProblem {
  /** Dotted path of the field ("tips.0.body.vi"). */
  path: string;
  /** A forbidden word, a dose, or a growth banner without "không phải chẩn đoán". */
  problem: 'forbidden' | 'dose' | 'disclaimer';
  /** The word or dose found. */
  match: string;
}

/** Forbidden words and dose patterns anywhere in an item's text (blocks "Gửi duyệt"). */
export function nutritionCopyProblems(data: unknown): CopyProblem[] {
  const out: CopyProblem[] = [];
  const visit = (v: unknown, path: string[]) => {
    if (typeof v === 'string') {
      // Source URLs and labels may cite anything.
      if (path.includes('sources')) return;
      const lower = v.toLowerCase();
      for (const w of nutritionForbiddenWords) {
        if (lower.includes(w)) out.push({ path: path.join('.'), problem: 'forbidden', match: w });
      }
      const dose = v.match(dosePattern);
      if (dose) out.push({ path: path.join('.'), problem: 'dose', match: dose[0] });
    } else if (Array.isArray(v)) {
      v.forEach((x, i) => visit(x, [...path, String(i)]));
    } else if (v && typeof v === 'object') {
      for (const [k, x] of Object.entries(v)) visit(x, [...path, k]);
    }
  };
  visit(data, []);
  // Growth rules say plainly that they are not a diagnosis (P-163 #16), in both languages.
  const rule = data as { metric?: unknown; banner?: { vi?: unknown; en?: unknown } } | null;
  if (rule && (rule.metric === 'weight' || rule.metric === 'length') && rule.banner) {
    const said = (v: unknown, phrase: string) =>
      typeof v !== 'string' || !v.trim() || v.normalize('NFC').toLowerCase().includes(phrase);
    if (!said(rule.banner.vi, 'không phải chẩn đoán')) {
      out.push({ path: 'banner.vi', problem: 'disclaimer', match: 'không phải chẩn đoán' });
    }
    if (!said(rule.banner.en, 'not a diagnosis')) {
      out.push({ path: 'banner.en', problem: 'disclaimer', match: 'not a diagnosis' });
    }
  }
  return out;
}

// ---------- Ages, stages and rounds (shared by app logic tests, server and portal) ----------

/** Completed calendar months between [birthDate] and [today] (YYYY-MM-DD), ≥ 0. */
export function monthsOld(birthDate: string, today: string): number {
  const [by, bm, bd] = birthDate.split('-').map(Number) as [number, number, number];
  const [ty, tm, td] = today.split('-').map(Number) as [number, number, number];
  let m = (ty - by) * 12 + (tm - bm);
  if (td < bd) m -= 1;
  return Math.max(0, m);
}

/** True when [months] is inside the range (`to` exclusive; the last stage ends at 37 to keep 36). */
export function nutritionAgeContains(range: NutritionAge, months: number): boolean {
  return months >= range.from && months < range.to;
}

/**
 * The numbers a label shows, as the design writes them: [0,1) "0–1", [1,4) "1–3", [6,9) "6–8",
 * [24,37) "24–36" (the last month shown is `to − 1`, except a one-month range).
 */
export function nutritionAgeLabel(age: NutritionAge): { from: number; to: number } {
  return { from: age.from, to: age.to - age.from === 1 ? age.to : age.to - 1 };
}

/**
 * The stage for a baby [months] old: the one covering the age (narrowest first); past the last
 * stage, the last one (P-163 #9); none when nothing is published.
 */
export function nutritionStageFor<T extends { ageMonths: NutritionAge }>(
  stages: readonly T[],
  months: number,
): { stage: T; past: boolean } | null {
  const sorted = sortNutritionStages(stages);
  const hits = sorted.filter((s) => nutritionAgeContains(s.ageMonths, months));
  if (hits.length) {
    const best = [...hits].sort(
      (a, b) => a.ageMonths.to - a.ageMonths.from - (b.ageMonths.to - b.ageMonths.from),
    )[0]!;
    return { stage: best, past: false };
  }
  const last = sorted[sorted.length - 1];
  if (last && months >= last.ageMonths.to) return { stage: last, past: true };
  return null;
}

export function sortNutritionStages<T extends { ageMonths: NutritionAge }>(
  stages: readonly T[],
): T[] {
  return [...stages].sort(
    (a, b) => a.ageMonths.from - b.ageMonths.from || a.ageMonths.to - b.ageMonths.to,
  );
}

/** True when two month ranges share at least one month (`to` exclusive). */
export function nutritionAgesOverlap(a: NutritionAge, b: NutritionAge): boolean {
  return a.from < b.to && b.from < a.to;
}

/** Months 0–36 that no stage in [stages] covers, as ranges ("gaps" on the D01 strip). */
export function nutritionGaps(stages: readonly { ageMonths: NutritionAge }[]): NutritionAge[] {
  const gaps: NutritionAge[] = [];
  let start: number | null = null;
  for (let m = 0; m <= N.maxAgeMonths; m++) {
    const covered = stages.some((s) => nutritionAgeContains(s.ageMonths, m));
    if (!covered && start === null) start = m;
    if (covered && start !== null) {
      gaps.push({ from: start, to: m });
      start = null;
    }
  }
  if (start !== null) gaps.push({ from: start, to: N.maxAgeMonths + 1 });
  return gaps;
}

export type RoundState = 'taken' | 'next' | 'past' | 'tooYoung' | 'later' | 'tooOld';

export interface VitaminRound {
  /** "2026-12": the key the taken record uses. */
  key: string;
  /** First and last day of the round (YYYY-MM-DD). */
  from: string;
  to: string;
  state: RoundState;
  /** The date recorded as taken, when taken. */
  takenOn: string | null;
}

const pad = (n: number) => String(n).padStart(2, '0');
const lastDayOf = (y: number, m: number) => new Date(Date.UTC(y, m, 0)).getUTCDate();
const isoDay = (y: number, m: number, d: number) =>
  `${y}-${pad(m)}-${pad(Math.min(d, lastDayOf(y, m)))}`;

/**
 * This year's and next year's rounds of a campaign for a baby born on [birthDate], on [today]
 * (all YYYY-MM-DD in the baby's zone), with what each round is for that baby (9g):
 * taken (recorded), the next one ahead, a past one not recorded (neutral), before the
 * eligible age, later ones, or past the eligible age.
 */
export function campaignRounds(
  campaign: { rounds: readonly NutrientRound[]; ageMonths: NutritionAge },
  birthDate: string,
  today: string,
  taken: Readonly<Record<string, string>>,
): VitaminRound[] {
  const year = Number(today.slice(0, 4));
  const rounds = [year, year + 1]
    .flatMap((y) =>
      [...campaign.rounds]
        .sort((a, b) => a.month - b.month)
        .map((r) => ({
          key: `${y}-${pad(r.month)}`,
          from: isoDay(y, r.month, r.fromDay),
          to: isoDay(y, r.month, r.toDay),
        })),
    )
    .sort((a, b) => a.from.localeCompare(b.from));
  let nextGiven = false;
  return rounds.map((r) => {
    const months = monthsOld(birthDate, r.from);
    const takenOn = taken[r.key] ?? null;
    let state: RoundState;
    if (takenOn) state = 'taken';
    else if (months < campaign.ageMonths.from) state = 'tooYoung';
    else if (months >= campaign.ageMonths.to) state = 'tooOld';
    else if (r.to < today) state = 'past';
    else if (!nextGiven) {
      state = 'next';
      nextGiven = true;
    } else state = 'later';
    return { ...r, state, takenOn };
  });
}

/** A vitamin A taken record: `{ "2026-06": "2026-06-01" }`. */
export const vitaminTakenSchema = z.record(
  z.string().regex(/^\d{4}-(0[1-9]|1[0-2])$/),
  z.iso.date(),
);
