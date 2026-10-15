import { z } from 'zod';

/**
 * Child Life Assistant v3 (brief "Child-Life-Chat-Assistant-Implementation-v3", Figma CH01–CH28,
 * plan `docs/assistant/`). Say it or send a photo → the app understands → the parent checks →
 * it goes to the right place. The model only READS and PREPARES; every domain write is a typed
 * draft confirmed by the person through a deterministic endpoint that uses the same services as
 * the forms. Free and Premium share every task type with different credit budgets.
 */

export const assistantContractVersion = 1;

// ---------- Errors (brief p.11) ----------

export const assistantErrors = [
  'AUTH_REQUIRED',
  'NOT_MEMBER',
  'READ_DENIED',
  'WRITE_DENIED',
  'CONSENT_REQUIRED',
  'USAGE_EXHAUSTED',
  'QUOTE_EXPIRED',
  'QUOTE_MISMATCH',
  'SCOPE_CHANGED',
  'DRAFT_STALE',
  'DRAFT_EXPIRED',
  'DRAFT_SAVED',
  'REVIEW_REQUIRED',
  'DUPLICATE_SUSPECTED',
  'DOMAIN_CONFLICT',
  'MODULE_UNAVAILABLE',
  'REGION_UNSUPPORTED',
  'FEATURE_DISABLED',
  'OCR_UNREADABLE',
  'AI_UNAVAILABLE',
  'VALIDATION_FAILED',
  'IDEMPOTENCY_CONFLICT',
  'INVALID_STATE',
] as const;
export type AssistantError = (typeof assistantErrors)[number];

// ---------- Scope, conversation, message ----------

/** A conversation is about one child or the household (expenses, notes). */
export const assistantScopeSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('child'), babyId: z.string().min(1).max(128) }),
  z.object({
    type: z.literal('household'),
    /** Any of the caller's babies in that household; it only identifies the household. */
    babyId: z.string().min(1).max(128),
  }),
]);
export type AssistantScope = z.infer<typeof assistantScopeSchema>;

/**
 * `assistantConversations/{id}`: private to its owner by default (brief p.8); domain records are
 * shared by role, chats are not. The owner must still be a member of the scope to use it.
 */
export interface AssistantConversation {
  id: string;
  ownerUid: string;
  familyId: string;
  scope: AssistantScope;
  title: string | null;
  locale: 'vi' | 'en';
  createdAt: string;
  updatedAt: string;
  archivedAt: string | null;
}

/** Typed result parts (brief p.11): the app renders only these; unknown → a safe placeholder. */
export const assistantPartTypes = [
  'text',
  'clarification',
  'draft_reference',
  'source_summary',
  'approved_content',
  'recipe_list',
  'usage_notice',
  'action_result',
  'health_support',
] as const;
export type AssistantPartType = (typeof assistantPartTypes)[number];

export const clarificationSchema = z.object({
  id: z.string().min(1).max(60),
  /** The field the answer fills (e.g. `sleep.period`, `bottle.ampm`, `expense.date`, `intent`). */
  field: z.string().min(1).max(60),
  question: z.object({ vi: z.string(), en: z.string() }),
  choices: z
    .array(
      z.object({
        id: z.string().min(1).max(40),
        label: z.object({ vi: z.string(), en: z.string() }),
      }),
    )
    .max(6),
  /** Free answer allowed (e.g. a time). */
  allowText: z.boolean(),
});
export type Clarification = z.infer<typeof clarificationSchema>;

export type AssistantPart =
  | { type: 'text'; schemaVersion: 1; text: string }
  | { type: 'clarification'; schemaVersion: 1; clarification: Clarification }
  | { type: 'draft_reference'; schemaVersion: 1; draftId: string; revision: number }
  | {
      type: 'source_summary';
      schemaVersion: 1;
      /** Engine-computed figures; the model never adds numbers. */
      summary: CareSummary;
      sourceIds: string[];
    }
  | {
      type: 'approved_content';
      schemaVersion: 1;
      contentId: string;
      contentVersion: number;
      /** Why this was chosen (from the facts, e.g. the reported need). */
      reason: string;
      reviewed: boolean;
    }
  | { type: 'recipe_list'; schemaVersion: 1; recipeIds: string[]; caveat: string | null }
  | {
      type: 'usage_notice';
      schemaVersion: 1;
      reason: 'USAGE_EXHAUSTED' | 'QUOTE_EXPIRED' | 'NEAR_LIMIT';
      remaining: number;
    }
  | {
      type: 'action_result';
      schemaVersion: 1;
      items: {
        draftId: string;
        status: 'saved' | 'failed' | 'conflict';
        recordLink: string | null;
        errorCode: string | null;
      }[];
    }
  | { type: 'health_support'; schemaVersion: 1; signs: string[] };

// ---------- Tasks ----------

export const taskModalities = ['text', 'image'] as const;
export type TaskModality = (typeof taskModalities)[number];

/** Generation states (brief p.9); `ready` = a useful answer or drafts exist, nothing written yet. */
export const taskStates = [
  'received',
  'blocked',
  'uploading',
  'queued',
  'processing',
  'awaiting_clarification',
  'ready',
  'failed',
  'canceled',
] as const;
export type TaskState = (typeof taskStates)[number];

export const terminalTaskStates: readonly TaskState[] = ['ready', 'failed', 'canceled', 'blocked'];

/** What the worker's model step produced (fake gateways return these in tests). */
export type TaskOutcome =
  | { kind: 'drafts'; items: DraftPayload[]; answer?: string | null }
  | { kind: 'answer'; parts: AssistantPart[] }
  | { kind: 'clarification'; clarification: Clarification }
  | { kind: 'health_route'; signs: string[] }
  | { kind: 'unreadable' }
  | { kind: 'error'; code: 'AI_UNAVAILABLE' | 'VALIDATION_FAILED' | 'timeout' }
  /** Anything outside the allowlist (an unknown tool, an unknown part): rejected, never executed. */
  | { kind: 'rejected'; detail: string };

/**
 * Usage decision for a finished model step (brief p.17): commit exactly once on a useful validated
 * result (an answer with grounds, or readable drafts — even if later discarded); keep the
 * reservation while asking; release on unreadable input, failures, rejected output and health
 * routes (support is free).
 */
export function usageForOutcome(o: TaskOutcome): 'commit' | 'hold' | 'release' {
  switch (o.kind) {
    case 'drafts':
      return o.items.length > 0 ? 'commit' : 'release';
    case 'answer':
      return 'commit';
    case 'clarification':
      return 'hold';
    case 'health_route':
    case 'unreadable':
    case 'error':
    case 'rejected':
      return 'release';
  }
}

export function taskStateForOutcome(o: TaskOutcome): TaskState {
  switch (o.kind) {
    case 'drafts':
      return o.items.length > 0 ? 'ready' : 'failed';
    case 'answer':
    case 'health_route':
      return 'ready';
    case 'clarification':
      return 'awaiting_clarification';
    case 'unreadable':
    case 'error':
    case 'rejected':
      return 'failed';
  }
}

/** Technical limits per task (brief p.9): QA values, config later. */
export const assistantTaskLimits = {
  maxClarificationRounds: 4,
  maxToolCallsPerRound: 6,
  quoteTtlMinutes: 5,
  clarificationTtlMinutes: 30,
  draftTtlHours: 24,
  maxImagesPerTask: 3,
  maxImageBytes: 8 * 1024 * 1024,
  maxTextChars: 2000,
} as const;

// ---------- Credits (brief p.17–18; QA values, not commercial) ----------

export const assistantCreditPolicySchema = z.object({
  policyVersion: z.string().min(1).max(40),
  textCredits: z.number().int().min(0).max(20),
  imageCredits: z.number().int().min(0).max(20),
  free: z.object({ limit: z.number().int().min(0) }),
  premium: z.object({ limit: z.number().int().min(0) }),
});
export type AssistantCreditPolicy = z.infer<typeof assistantCreditPolicySchema>;

export const defaultAssistantCreditPolicy: AssistantCreditPolicy = {
  policyVersion: 'assistant-qa-v3',
  textCredits: 1,
  imageCredits: 3,
  free: { limit: 20 },
  premium: { limit: 200 },
};

/** Exact charge for a task: images cost per task (not per image), text 1; health routes are free. */
export function creditsFor(
  modality: TaskModality,
  policy: AssistantCreditPolicy = defaultAssistantCreditPolicy,
): number {
  return modality === 'image' ? policy.imageCredits : policy.textCredits;
}

// ---------- Drafts ----------

export const draftKinds = [
  'bottle',
  'breast',
  'sleep',
  'expense',
  'reminder',
  'observation',
  'meal',
] as const;
export type DraftKind = (typeof draftKinds)[number];

/** Draft states map the "Thẻ nháp" component (611:7695). Badge text is never the source of state. */
export const draftStates = [
  'draft',
  'needs_review',
  'saving',
  'saved',
  'failed',
  'discarded',
] as const;
export type DraftState = (typeof draftStates)[number];

const iso = z.iso.datetime({ offset: true });

export const bottleDraftSchema = z.object({
  kind: z.literal('bottle'),
  /** Positive, within the module's limits. */
  amountMl: z.number().positive().nullable(),
  occurredAt: iso.nullable(),
  milk: z.enum(['breast_milk', 'formula', 'other']).nullable(),
});
export const breastDraftSchema = z.object({
  kind: z.literal('breast'),
  occurredAt: iso.nullable(),
  /** Nursing is minutes, never converted to ml. */
  durationMin: z.number().int().positive().nullable(),
  side: z.enum(['left', 'right', 'both']).nullable(),
});
export const sleepDraftSchema = z.object({
  kind: z.literal('sleep'),
  startedAt: iso.nullable(),
  endedAt: iso.nullable(),
});
export const expenseDraftSchema = z.object({
  kind: z.literal('expense'),
  merchant: z.string().max(120).nullable(),
  /** Integer minor units (VND đồng, USD cents); never a float. */
  totalMinor: z.number().int().nullable(),
  currency: z
    .string()
    .regex(/^[A-Z]{3}$/)
    .nullable(),
  /** Local date on the receipt. */
  date: z.iso.date().nullable(),
  /** Informational only; never added to the total (brief p.14). */
  subtotalMinor: z.number().int().nullable(),
  taxMinor: z.number().int().nullable(),
  categoryId: z.string().max(80).nullable(),
  /** Optional child attribution; the expense stays the household's. */
  babyId: z.string().max(128).nullable(),
  keepReceipt: z.boolean(),
});
export const reminderDraftSchema = z.object({
  kind: z.literal('reminder'),
  title: z.string().min(1).max(120),
  date: z.iso.date().nullable(),
  /** "HH:mm" local, or null for date-only when the module supports it; never a silent 09:00. */
  time: z
    .string()
    .regex(/^([01]\d|2[0-3]):[0-5]\d$/)
    .nullable(),
  /** A verified member uid chosen by the person; never a name read from the photo. */
  assigneeUid: z.string().max(128).nullable(),
});
export const observationDraftSchema = z.object({
  kind: z.literal('observation'),
  observation: z.enum(['sleep', 'feeding', 'soothing', 'new_skill', 'usual']),
  date: z.iso.date(),
  when: z.enum(['night', 'day', 'both']).nullable(),
  note: z.string().max(500).nullable(),
});
export const mealDraftSchema = z.object({
  kind: z.literal('meal'),
  recipeId: z.string().max(80).nullable(),
  title: z.string().min(1).max(120),
  occurredAt: iso.nullable(),
});

export const draftPayloadSchema = z.discriminatedUnion('kind', [
  bottleDraftSchema,
  breastDraftSchema,
  sleepDraftSchema,
  expenseDraftSchema,
  reminderDraftSchema,
  observationDraftSchema,
  mealDraftSchema,
]);
export type DraftPayload = z.infer<typeof draftPayloadSchema>;

/**
 * `assistantTasks/{taskId}/drafts/{draftId}`: server-written; the person edits through
 * `patchDraft` (revision +1) and saves through `confirmDrafts`.
 */
export interface ActionDraft {
  id: string;
  taskId: string;
  itemIndex: number;
  scope: AssistantScope;
  payload: DraftPayload;
  /** Fields the person must fill or confirm before saving (e.g. `date` on CH11). */
  missingFields: string[];
  uncertainFields: string[];
  revision: number;
  state: DraftState;
  expiresAt: string;
  sourceRefs: string[];
  /** Set once saved: the domain record and its deep link (built by the module adapter). */
  recordId: string | null;
  recordLink: string | null;
  errorCode: string | null;
  /** Warning the person must acknowledge to save anyway (duplicate expense, near-duplicate feed). */
  warnings: ('duplicate_suspected' | 'overlap')[];
}

export type DraftProblem =
  | 'MISSING_AMOUNT'
  | 'INVALID_AMOUNT'
  | 'MISSING_TIME'
  | 'FUTURE_TIME'
  | 'INVALID_TIME'
  | 'MISSING_DATE'
  | 'CURRENCY_UNSUPPORTED'
  | 'MISSING_TITLE';

export const supportedCurrencies = [
  'VND',
  'USD',
  'EUR',
  'SGD',
  'AUD',
  'GBP',
  'JPY',
  'KRW',
  'TWD',
  'NZD',
  'CAD',
] as const;

/** Technical limits for a single bottle feed (module-level; not a clinical norm). */
export const bottleLimits = { maxMl: 500 };

/**
 * Same checks as the forms, before any save (brief p.12): positive amounts within limits, a
 * time for completed logs not after the anchor, sleep end after start, an explicit date and a
 * supported currency for expenses, a title and a date for reminders. Uncertain fields
 * (`needs_review`) also block until the person confirms them.
 */
export function draftProblems(p: DraftPayload, anchor: Date): DraftProblem[] {
  const out: DraftProblem[] = [];
  const after = (v: string | null) => v !== null && Date.parse(v) > anchor.getTime();
  switch (p.kind) {
    case 'bottle':
      if (p.amountMl === null) out.push('MISSING_AMOUNT');
      else if (p.amountMl <= 0 || p.amountMl > bottleLimits.maxMl) out.push('INVALID_AMOUNT');
      if (p.occurredAt === null) out.push('MISSING_TIME');
      else if (after(p.occurredAt)) out.push('FUTURE_TIME');
      break;
    case 'breast':
      if (p.occurredAt === null) out.push('MISSING_TIME');
      else if (after(p.occurredAt)) out.push('FUTURE_TIME');
      if (p.durationMin !== null && p.durationMin > 180) out.push('INVALID_AMOUNT');
      break;
    case 'sleep':
      if (p.startedAt === null || p.endedAt === null) out.push('MISSING_TIME');
      else {
        if (Date.parse(p.endedAt) <= Date.parse(p.startedAt)) out.push('INVALID_TIME');
        if (after(p.endedAt)) out.push('FUTURE_TIME');
      }
      break;
    case 'expense':
      if (p.totalMinor === null) out.push('MISSING_AMOUNT');
      else if (p.totalMinor <= 0) out.push('INVALID_AMOUNT');
      if (p.date === null) out.push('MISSING_DATE');
      if (p.currency === null || !(supportedCurrencies as readonly string[]).includes(p.currency)) {
        out.push('CURRENCY_UNSUPPORTED');
      }
      break;
    case 'reminder':
      if (p.title.trim() === '') out.push('MISSING_TITLE');
      if (p.date === null) out.push('MISSING_DATE');
      break;
    case 'observation':
      break;
    case 'meal':
      if (p.occurredAt !== null && after(p.occurredAt)) out.push('FUTURE_TIME');
      break;
  }
  return out;
}

/** Confirm preconditions shared by server and app (D04, D05, review). */
export function confirmBlocker(
  d: Pick<ActionDraft, 'state' | 'revision' | 'expiresAt' | 'uncertainFields' | 'missingFields'>,
  seenRevision: number,
  now: Date,
): AssistantError | null {
  if (d.state === 'saved') return 'DRAFT_SAVED';
  if (d.state === 'discarded') return 'INVALID_STATE';
  if (now.getTime() >= Date.parse(d.expiresAt)) return 'DRAFT_EXPIRED';
  if (d.revision !== seenRevision) return 'DRAFT_STALE';
  if (d.state === 'needs_review' || d.uncertainFields.length > 0 || d.missingFields.length > 0) {
    return 'REVIEW_REQUIRED';
  }
  return null;
}

// ---------- Read summary (CH08, R01) ----------

export interface CareSummary {
  /** Local date (or range start) the summary is about. */
  date: string;
  bottle: { count: number; ml: number };
  /** Nursing kept apart: minutes, never ml. */
  breast: { count: number; minutes: number };
  sleep: { count: number; minutes: number };
  /** "các cữ đã ghi": coverage unknown unless the day passes the automatic valid-day rule. */
  coverage: 'complete' | 'partial' | 'unknown';
  /** Until when it counts (a running day stops at "now"). */
  until: string;
}

/** Deterministic figures from logged records only; the model may only word them. */
export function careSummary(
  records: readonly {
    id: string;
    kind: 'bottle' | 'breast' | 'nursing' | 'sleep' | string;
    ml?: number;
    minutes?: number;
  }[],
  date: string,
  until: string,
  coverage: CareSummary['coverage'] = 'unknown',
): { summary: CareSummary; sourceIds: string[] } {
  const s: CareSummary = {
    date,
    bottle: { count: 0, ml: 0 },
    breast: { count: 0, minutes: 0 },
    sleep: { count: 0, minutes: 0 },
    coverage,
    until,
  };
  const ids: string[] = [];
  for (const r of records) {
    if (r.kind === 'bottle') {
      s.bottle.count += 1;
      s.bottle.ml += r.ml ?? 0;
    } else if (r.kind === 'breast' || r.kind === 'nursing') {
      s.breast.count += 1;
      s.breast.minutes += r.minutes ?? 0;
    } else if (r.kind === 'sleep') {
      s.sleep.count += 1;
      s.sleep.minutes += r.minutes ?? 0;
    } else continue;
    ids.push(r.id);
  }
  return { summary: s, sourceIds: ids };
}

// ---------- Recipes (CH18, R02) ----------

export interface RecipeCandidate {
  id: string;
  ingredientIds: string[];
  minAgeMonths: number;
  approved: boolean;
  region: string;
}

/**
 * Published + reviewed + region + age, excluding any recipe with an ingredient the family recorded
 * a reaction to. A recorded reaction is self-reported data, never an allergy diagnosis; an unknown
 * tolerance is not "safe" (the caller adds a caveat).
 */
export function eligibleRecipes(
  recipes: readonly RecipeCandidate[],
  ageMonths: number,
  reactionIngredientIds: readonly string[],
  region: string,
): string[] {
  const avoid = new Set(reactionIngredientIds);
  return recipes
    .filter(
      (r) =>
        r.approved &&
        r.minAgeMonths <= ageMonths &&
        r.region === region &&
        !r.ingredientIds.some((i) => avoid.has(i)),
    )
    .map((r) => r.id);
}

// ---------- Note photos (CH13, I06) ----------

export const noteLineKinds = [
  'actionCandidate',
  'informational',
  'medicalText',
  'unclear',
] as const;
export type NoteLineKind = (typeof noteLineKinds)[number];

/**
 * Which note lines may become drafts: only action candidates, only into a module the household
 * has (no Tasks module → reminders, and only with the person's explicit choice). Medicine text,
 * notes and unclear lines never become schedules.
 */
export function noteActions<T extends { kind: string }>(
  lines: readonly T[],
  modules: { tasks: boolean; reminders: boolean },
  explicitReminderFallback: boolean,
): T[] {
  const actions = lines.filter((l) => l.kind === 'actionCandidate');
  if (modules.tasks) return actions;
  if (modules.reminders && explicitReminderFallback) return actions;
  return [];
}

/** "Thứ Hai 20/10" in 2026 is a Tuesday (gap G03): ask, never pick for the person. */
export function weekdayMatches(date: string, weekday: number): boolean {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay() === weekday;
}

// ---------- Idempotency ----------

/** Stable input hash for `startTask` replay (same request id + different input → conflict). */
export function taskInputKey(x: {
  conversationId: string;
  scope: AssistantScope;
  modality: TaskModality;
  text: string | null;
  attachmentIds: readonly string[];
}): string {
  return JSON.stringify([
    x.conversationId,
    x.scope.type,
    x.scope.babyId,
    x.modality,
    (x.text ?? '').trim(),
    [...x.attachmentIds].sort(),
  ]);
}

// ---------- Callables (DTOs) ----------

const envelope = {
  contractVersion: z.literal(assistantContractVersion),
  clientRequestId: z.uuid(),
  locale: z.enum(['vi', 'en']),
};

export const quoteTaskRequestSchema = z.object({
  ...envelope,
  conversationId: z.string().min(1).max(80).nullable(),
  scope: assistantScopeSchema,
  modality: z.enum(taskModalities),
  attachmentCount: z.number().int().min(0).max(assistantTaskLimits.maxImagesPerTask),
  intentHint: z.enum(['care', 'expense', 'reminder', 'question', 'meal']).nullable(),
});

export const createAttachmentUploadRequestSchema = z.object({
  ...envelope,
  quoteId: z.string().min(1).max(80),
  mime: z.enum(['image/jpeg', 'image/png', 'image/heic', 'image/webp']),
  bytes: z.number().int().positive().max(assistantTaskLimits.maxImageBytes),
  sha256: z.string().regex(/^[a-f0-9]{64}$/),
  /** "Xoá ảnh sau khi đọc" (default) or keep it with the expense. */
  retention: z.enum(['delete_after_read', 'keep_with_record']),
});

export const startTaskRequestSchema = z.object({
  ...envelope,
  conversationId: z.string().min(1).max(80).nullable(),
  scope: assistantScopeSchema,
  quoteId: z.string().min(1).max(80),
  text: z.string().max(assistantTaskLimits.maxTextChars).nullable(),
  attachmentIds: z.array(z.string().min(1).max(80)).max(assistantTaskLimits.maxImagesPerTask),
});

export const submitClarificationRequestSchema = z.object({
  ...envelope,
  taskId: z.string().min(1).max(80),
  expectedVersion: z.number().int().min(1),
  clarificationId: z.string().min(1).max(60),
  choiceId: z.string().max(40).nullable(),
  text: z.string().max(200).nullable(),
});

export const patchDraftRequestSchema = z.object({
  ...envelope,
  draftId: z.string().min(1).max(120),
  expectedRevision: z.number().int().min(1),
  payload: draftPayloadSchema,
  /** Fields the person explicitly confirmed (clears uncertainty, e.g. the receipt date). */
  confirmedFields: z.array(z.string().max(60)).max(20),
});

export const confirmDraftsRequestSchema = z.object({
  ...envelope,
  taskId: z.string().min(1).max(80),
  selected: z
    .array(
      z.object({
        draftId: z.string().min(1).max(120),
        revision: z.number().int().min(1),
        /** "Vẫn lưu" after a duplicate / overlap warning the module allows. */
        acknowledge: z.array(z.enum(['duplicate_suspected', 'overlap'])).max(2),
      }),
    )
    .min(1)
    .max(20),
});

export const discardDraftRequestSchema = z.object({
  ...envelope,
  draftId: z.string().min(1).max(120),
  expectedRevision: z.number().int().min(1),
});

export const cancelTaskRequestSchema = z.object({
  ...envelope,
  taskId: z.string().min(1).max(80),
});

export const assistantFeedbackRequestSchema = z.object({
  ...envelope,
  taskId: z.string().min(1).max(80),
  contentId: z.string().min(1).max(60),
  contentVersion: z.number().int().min(1),
  /** "Chưa thử" is a valid answer (CH17). */
  outcome: z.enum(['helpful', 'unsure', 'not_suitable', 'not_tried']),
});

export const assistantUsageRequestSchema = z.object({
  ...envelope,
  babyId: z.string().min(1).max(128),
});

/** `getUsage` / quote snapshot (CH19 "Mức dùng"): household pool, reset date, plan. */
export interface AssistantUsage {
  plan: 'free' | 'premium';
  limit: number;
  used: number;
  reserved: number;
  remaining: number;
  resetsAt: string;
  policyVersion: string;
  textCredits: number;
  imageCredits: number;
}

export interface AssistantQuote {
  quoteId: string;
  modality: TaskModality;
  /** Exact credits charged on a useful result; never more. */
  credits: number;
  allowed: boolean;
  reason: AssistantError | null;
  expiresAt: string;
  usage: AssistantUsage;
}

/** Event envelope (brief p.11) kept on the task as an ordered log; snapshot is the authority. */
export const taskEventTypes = [
  'accepted',
  'progress',
  'clarification_required',
  'drafts_ready',
  'answer_ready',
  'usage_updated',
  'item_saved',
  'item_failed',
  'task_failed',
] as const;
