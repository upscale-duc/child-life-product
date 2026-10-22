import { assistantReadTools } from './assistant-reads.js';
import { z } from 'zod';
import { draftKinds, type DraftKind } from './assistant.js';

/**
 * Lumi L9 — understanding v1 (P-169, docs/product/lumi-plan.md §12.3). One model call reads ONE
 * message against the author's dialogue state and returns what the parent MEANT: a dialogue act
 * and typed events whose time semantics are written out (`status`, `started`, `ended`,
 * `durationMin`). The server never re-reads the words: it resolves the instants, validates, asks
 * and writes. No `phase`, no `correctsPrevious`: "ongoing since 10 minutes" is one event,
 * `{kind: sleep, status: ongoing, started: {how: ago, minutes: 10}}`.
 */

export const understandingActs = [
  /** New facts to log (events). */
  'log',
  /** The words answer the server's open question. */
  'answer',
  /** A waiting draft or a record just saved is corrected (`target`, the corrected event in full). */
  'correct',
  /** "xoá cái vừa ghi": the target is dropped or deleted. */
  'undo',
  /** "rồi ngủ lúc 10h": a new log after the last item. */
  'continue',
  /** A question about what was logged (`reads`). */
  'read',
  /** The model cannot read the message without an answer (`ask`): only an ambiguous clock. */
  'ask',
  /** "là sao", "sao không ghi": the person asks what Lumi is doing. */
  'meta',
  /** Thanks, hello, ok, bye. */
  'talk',
  /** Nothing the app does. */
  'none',
] as const;
export type UnderstandingAct = (typeof understandingActs)[number];

export const eventStatuses = ['ongoing', 'finished', 'planned'] as const;
export type EventStatus = (typeof eventStatuses)[number];

/** When something started or ended, as the words say it — never computed by the model. */
export const timeSpecSchema = z
  .object({
    how: z.enum(['ago', 'clock', 'unknown']),
    /** `ago`: minutes before the message (0 = just now). */
    minutes: z
      .number()
      .int()
      .min(0)
      .max(72 * 60)
      .nullable(),
    /** `clock`: 24 h "HH:mm" as written (the server decides morning / evening and the day). */
    hhmm: z
      .string()
      .regex(/^([01]\d|2[0-3]):[0-5]\d$/)
      .nullable(),
    /** `clock`: 0 = the anchor day, -1 = the day before, -2 = two days before, 1 = tomorrow. */
    dayOffset: z.number().int().min(-2).max(1).nullable(),
  })
  .strict();
export type TimeSpec = z.infer<typeof timeSpecSchema>;

/** The kinds an understanding event may have (timers are the server's; meal writes through chat remain Phase 3). */
export const eventKinds = draftKinds.filter((k) => k !== 'timer') as Exclude<DraftKind, 'timer'>[];
export type EventKind = (typeof eventKinds)[number];

/** Care logs with a time line: `status` / `started` / `ended` / `durationMin` apply. */
export const timedEventKinds = ['bottle', 'breast', 'sleep', 'pump', 'diaper'] as const;
export type TimedEventKind = (typeof timedEventKinds)[number];
export const isTimedEventKind = (k: string): k is TimedEventKind =>
  (timedEventKinds as readonly string[]).includes(k);

/** The fields each kind writes (its own, besides the time line). */
export const eventKindFields: Record<EventKind, readonly string[]> = {
  bottle: ['amountMl', 'milk'],
  breast: ['side'],
  sleep: [],
  pump: ['amountMl', 'side'],
  diaper: ['diaper'],
  growth: ['weightKg', 'lengthCm', 'headCm', 'dayOffset'],
  observation: ['observation', 'when', 'note', 'dayOffset'],
  expense: ['title', 'amount', 'currency', 'categoryId', 'merchant', 'date'],
  reminder: ['title', 'date', 'time', 'assigneeText'],
  meal: ['title'],
};

export const eventFieldNames = [
  'amountMl',
  'milk',
  'side',
  'diaper',
  'weightKg',
  'lengthCm',
  'headCm',
  'dayOffset',
  'observation',
  'when',
  'note',
  'title',
  'amount',
  'currency',
  'categoryId',
  'merchant',
  'date',
  'time',
  'assigneeText',
  // The time line, named in evidence / uncertain lists.
  'started',
  'ended',
  'durationMin',
  'status',
] as const;
export type EventFieldName = (typeof eventFieldNames)[number];

const clip = (n: number) => z.string().transform((v) => v.slice(0, n));
const hhmm = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/);

export const eventFieldsSchema = z
  .object({
    amountMl: z.number().finite().nullable().optional(),
    milk: z.enum(['breast_milk', 'formula', 'other']).nullable().optional(),
    side: z.enum(['left', 'right', 'both']).nullable().optional(),
    diaper: z.enum(['wet', 'dirty', 'both']).nullable().optional(),
    weightKg: z.number().finite().nullable().optional(),
    lengthCm: z.number().finite().nullable().optional(),
    headCm: z.number().finite().nullable().optional(),
    dayOffset: z.number().int().min(-2).max(1).nullable().optional(),
    observation: z
      .enum(['sleep', 'feeding', 'soothing', 'new_skill', 'usual'])
      .nullable()
      .optional(),
    when: z.enum(['night', 'day', 'both']).nullable().optional(),
    note: clip(500).nullable().optional(),
    title: clip(120).nullable().optional(),
    amount: z.number().finite().nullable().optional(),
    currency: z.string().max(8).nullable().optional(),
    categoryId: z.string().max(40).nullable().optional(),
    merchant: clip(120).nullable().optional(),
    date: z.string().max(10).nullable().optional(),
    time: hhmm.nullable().optional(),
    assigneeText: clip(60).nullable().optional(),
  })
  .strict();
export type EventFields = z.infer<typeof eventFieldsSchema>;

export const understandingEventSchema = z
  .object({
    kind: z.enum(eventKinds as [EventKind, ...EventKind[]]),
    /** Timed kinds: still going on, over, or a plan (never logged). Others: finished. */
    status: z.enum(eventStatuses),
    // The model's JSON schema leaves the time line out for untimed kinds (an expense, a
    // reminder): absent reads as null, or every such message was rejected (VALIDATION_FAILED).
    started: timeSpecSchema.nullable().default(null),
    ended: timeSpecSchema.nullable().default(null),
    /** Minutes, only when a time unit is written. */
    durationMin: z
      .number()
      .int()
      .min(0)
      .max(72 * 60)
      .nullable()
      .default(null),
    fields: eventFieldsSchema,
    /** The exact words each filled field (or time) comes from (grounding, checked by the server). */
    evidence: z
      .array(z.object({ field: z.enum(eventFieldNames), text: clip(200) }).strict())
      .max(12),
    uncertainFields: z.array(z.enum(eventFieldNames)).max(12),
  })
  .strict();
export type UnderstandingEvent = z.infer<typeof understandingEventSchema>;

export const understandingReadTools = assistantReadTools;

/**
 * The only questions the model may raise: an ambiguous written clock (the server phrases and
 * owns it), and slice A5's care facts about a sleep concern (`planCare` asks them).
 */
export const understandingAskFields = [
  'time.ampm',
  'sleep.period',
  'sleep.when',
  'sleep.onset',
] as const;

export const understandingSchema = z
  .object({
    act: z.enum(understandingActs),
    /** Only for `correct` / `undo`: the id of the waiting draft or saved record (as given). */
    target: z.string().max(16).nullable(),
    confidence: z.number().min(0).max(1),
    events: z.array(understandingEventSchema).max(6),
    reads: z
      .array(
        z
          .object({
            tool: z.enum(understandingReadTools),
            dayOffset: z.number().int().min(-6).max(0),
          })
          .strict(),
      )
      .max(3),
    /** `ask` only: which clock is open and why (the server phrases and owns the question). */
    ask: z
      .object({ field: z.enum(understandingAskFields), why: clip(120) })
      .strict()
      .nullable(),
    /** Slice A5: a care topic (sleep concern, meal ideas) — same shape as before. */
    care: z
      .object({
        topic: z.enum(['sleep_concern', 'meal_ideas']),
        sleep: z
          .object({
            kind: z.string().max(40).nullable(),
            when: z.string().max(10).nullable(),
            since: z.string().max(40).nullable(),
          })
          .strict()
          .nullable(),
        evidence: z.array(z.object({ field: z.string().max(20), text: clip(200) }).strict()).max(6),
      })
      .strict()
      .nullable()
      .optional(),
    healthSigns: z.array(z.string().max(60)).max(8).optional(),
  })
  .strict();
export type Understanding = z.infer<typeof understandingSchema>;

/** The prompt / schema version of understanding v1 (bump on any change to either). */
export const understandingVersion = 'assistant-understand-v2';

/** A time spec that says nothing (the server takes now for a finished log). */
export const unknownTime: TimeSpec = { how: 'unknown', minutes: null, hhmm: null, dayOffset: null };
