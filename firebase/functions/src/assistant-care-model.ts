import { z } from 'zod';
import { healthSigns, sleepConcernKinds } from '@child-life/contracts';

/**
 * Care at the model boundary (slice A5, CH15–CH18, CH28; brief p.16). The model may only SAY that
 * a message is a care question — a sleep concern or "Hôm nay con ăn gì?" — with the facts the
 * person gave (and the exact words for each), and list structured health signs it read. It never
 * writes advice, steps, recipes, causes or questions: the server asks from its own catalog, picks
 * published content with deterministic tools, and rejects any other key (strict schema → the task
 * is `rejected`, 0 credits). Kept apart from `assistant-model.ts` so the slices edit separate
 * files; that module plugs these in.
 */

export const careTopics = ['sleep_concern', 'meal_ideas'] as const;
export type CareTopic = (typeof careTopics)[number];

const careFactFields = ['kind', 'when', 'since'] as const;

export const careExtractionSchema = z
  .object({
    topic: z.enum(careTopics),
    /** Only what the text says; null otherwise (the server asks). */
    sleep: z
      .object({
        kind: z.enum(sleepConcernKinds).nullable(),
        when: z.enum(['night', 'day', 'both']).nullable(),
        since: z.enum(['today', 'days_2_3', 'longer']).nullable(),
      })
      .strict()
      .nullable(),
    /** The exact words each sleep fact comes from (checked against the person's text). */
    evidence: z
      .array(z.object({ field: z.enum(careFactFields), text: z.string().max(200) }).strict())
      .max(6),
  })
  .strict();
export type CareExtraction = z.infer<typeof careExtractionSchema>;

/** Structured health signs the model read (contracts `healthSigns`); any → health support. */
export const healthSignsExtractionSchema = z.array(z.enum(healthSigns)).max(healthSigns.length);

const nullableEnum = (values: readonly string[]) => ({
  anyOf: [{ type: 'string', enum: [...values] }, { type: 'null' }],
});

/** Strict JSON schema for `care` (OpenAI structured outputs need every key; nullable). */
export const careExtractionJsonSchema = {
  anyOf: [
    {
      type: 'object',
      additionalProperties: false,
      required: ['topic', 'sleep', 'evidence'],
      properties: {
        topic: { type: 'string', enum: [...careTopics] },
        sleep: {
          anyOf: [
            {
              type: 'object',
              additionalProperties: false,
              required: ['kind', 'when', 'since'],
              properties: {
                kind: nullableEnum(sleepConcernKinds),
                when: nullableEnum(['night', 'day', 'both']),
                since: nullableEnum(['today', 'days_2_3', 'longer']),
              },
            },
            { type: 'null' },
          ],
        },
        evidence: {
          type: 'array',
          items: {
            type: 'object',
            additionalProperties: false,
            required: ['field', 'text'],
            properties: {
              field: { type: 'string', enum: [...careFactFields] },
              text: { type: 'string' },
            },
          },
        },
      },
    },
    { type: 'null' },
  ],
} as const;

export const healthSignsJsonSchema = {
  type: 'array',
  items: { type: 'string', enum: [...healthSigns] },
} as const;

/** Prompt lines for care (appended to the extraction system prompt). */
export function careSystemPromptLines(): string[] {
  return [
    'Care questions: if the parent describes a sleep concern (khó ngủ, khó vào giấc, hay thức đêm, ngủ ít, trouble sleeping, waking at night), set "care" to {"topic":"sleep_concern"} and fill care.sleep.kind (falling_asleep, night_waking, both), care.sleep.when (night, day, both) and care.sleep.since (today, days_2_3, longer) ONLY when the text says so, each with an evidence item; otherwise leave them null (the app asks). If the parent asks what the baby could eat or cook (hôm nay ăn gì, món ăn dặm, công thức, what should baby eat), set "care" to {"topic":"meal_ideas"}. Otherwise "care" is null.',
    'Never write advice, steps, activities, recipes, foods, causes or explanations: the app shows only reviewed content it chooses itself. Never say a developmental leap or "Wonder Weeks" causes anything.',
    'If the text describes a health warning sign, list it in "healthSigns" using only these ids: fever_young (fever in a young baby), breathing (trouble breathing), lethargic (very drowsy, hard to wake), poor_feeding (refuses feeds), inconsolable (crying that cannot be soothed), lost_skill (lost a skill), dehydration (no wet diapers, dry mouth), seizure. Otherwise return [].',
    'You may ask {"field":"sleep.onset"} only when when the concern started matters and the text does not say it; the app asks "sleep.period" and "sleep.when" itself.',
  ];
}
