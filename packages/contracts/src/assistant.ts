import { z } from 'zod';
// Chi tiêu currencies (D-075 #4).
import { amountMaxFor, expenseCurrencies, isExpenseCurrency, legacyCurrency } from './spending.js';
// Lumi rework 2026-10-15: the spending detector (D-075 #2).
import { looksLikeSpending } from './assistant-text.js';
// Lumi 2026-10-16 (LUMI-01): pump / diaper / growth drafts use the care module's own limits.
import { careLimits } from './care.js';

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
  // ---- Lumi timers 2026-10-16 (confirm conflicts of a `timer` draft) ----
  /** "Bắt đầu tính giờ": someone already started that timer (it is shown instead). */
  'TIMER_RUNNING',
  /** "Kết thúc": the running timer changed hands or ended elsewhere without this session's record. */
  'TIMER_CHANGED',
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
 * `assistantConversations/{id}`. D-075 #2: one SHARED thread per baby (`shared: true`, id
 * `sharedConversationIdFor(babyId)`, `ownerUid` null) for Cùng nuôi and Người chăm sóc; every
 * other conversation (household / spending, relatives, threads from before D-075) stays private
 * to its owner, who must still be a member of the scope to use it.
 */
export interface AssistantConversation {
  id: string;
  /** Null for the shared baby thread (D-075 #2). */
  ownerUid: string | null;
  /** D-075 #2: the baby's shared thread (absent / false = private to `ownerUid`). */
  shared?: boolean;
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
  | {
      type: 'text';
      schemaVersion: 1;
      text: string;
      /** Slice A5: a notice code the app may attach an action to (`assistantNoticeCodes`). */
      code?: AssistantNoticeCode;
      /**
       * Rework 2026-10-15: an app route the notice points to (e.g. `PREVIOUS_SAVED` → the saved
       * record to edit in its module); built by the server, never by the model.
       */
      link?: string;
    }
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
      /** Slice A5 (optional; A2 messages lack it): which rule the reason rests on. */
      reasonCode?: 'SELF_REPORTED_NEED' | 'DATA_INSIGHT' | 'PREVIOUS_HELPFUL';
      /**
       * Slice A5: the published item's own words in the task locale, copied from the content pack
       * (never written by the model) so the card renders even after a newer version is published.
       */
      content?: ApprovedContentText;
      /** Other eligible items for "Gợi ý khác", best first (≤ 2). */
      alternatives?: { contentId: string; contentVersion: number }[];
    }
  | {
      type: 'recipe_list';
      schemaVersion: 1;
      recipeIds: string[];
      caveat: string | null;
      /** Slice A5: the approved candidates (≤ 3) with their content words and why. */
      items?: RecipeListItem[];
      /** Approved, age- and region-eligible recipes left out for a recorded reaction. */
      excludedCount?: number;
      /** "Ghi bữa ăn" needs a meal-log module (none yet, P-157). */
      mealLogAvailable?: boolean;
    }
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
  | {
      type: 'health_support';
      schemaVersion: 1;
      signs: string[];
      /**
       * Slice A5: the emergency number approved for the household's country in the published
       * health pack. Absent when the country has no entry: the app then says "gọi bác sĩ của bé",
       * never a default hotline.
       */
      emergency?: { country: string; number: string };
    };

// ---------- Care parts (slice A5, CH15–CH18, CH28) ----------

/** Notice codes on `text` parts; the app may add an action (e.g. open the care library). */
export const assistantNoticeCodes = [
  /** No approved guidance fits: "chưa có gợi ý phù hợp", link to the care library. */
  'CARE_NO_APPROVED_CONTENT',
  /** No approved recipe fits (or none is published yet): "chưa có công thức được duyệt". */
  'RECIPES_NONE_APPROVED',
  /** `assistant_care` is off: guidance and recipes paused; logging and summaries still work. */
  'CARE_FEATURE_DISABLED',
  /** The household's country has no care content in chat (CH27). */
  'REGION_UNSUPPORTED',
  /** The baby has no date of birth: age-based content cannot be chosen. */
  'CARE_AGE_UNKNOWN',
  // ---- Rework 2026-10-15 ----
  /** A thank-you / hello / ok answered with a short reply: 0 credits. */
  'SMALL_TALK',
  /** Nothing to log or read: what Lumi can do (never a dead end): 0 credits. */
  'HELP',
  /** Money was mentioned: this task stays in the author's private thread (D-075 #2). */
  'SPENDING_PRIVATE',
  /** A correction ("à không, 150ml") replaced the previous unsaved draft. */
  'CORRECTION_APPLIED',
  /** A correction of something already saved: edit it in its module (`link`). */
  'PREVIOUS_SAVED',
  /** A medicine reminder is never scheduled by the assistant (add it in Nhắc việc). */
  'MEDICINE_NOT_SCHEDULED',
  /** Something very similar was just logged: check before saving. */
  'DUPLICATE_SUSPECTED',
  // ---- Lumi timers 2026-10-16 ----
  /**
   * The sleep / breastfeeding timer the message would start is already running (since the
   * time in the text): a `timer` stop draft follows ("Kết thúc" / "Để tiếp tục").
   */
  'TIMER_RUNNING',
  /**
   * The same message was sent again while its draft is still waiting above: nothing new was
   * drafted (0 credits); the person saves or fixes the one above.
   */
  'SAME_AS_PENDING',
  // ---- Lumi fixes 2026-10-16 (LUMI-05, LUMI-13) ----
  /**
   * Part of the message was not drafted (named in the words: "vòng đầu", a meal, an item this app
   * build cannot show yet); `link` opens the module where the person can add it directly.
   */
  'PART_NOT_SAVED',
  /**
   * The app build that sent the message cannot show this kind of draft (it declared its kinds in
   * `clientDraftKinds`, or sent none = an app from before 2026-10-16): update the app, or open the
   * module (`link`) to add it directly. Nothing was drafted for it, 0 credits for that part.
   */
  'APP_UPDATE_NEEDED',
] as const;
export type AssistantNoticeCode = (typeof assistantNoticeCodes)[number];

export interface ApprovedContentText {
  title: string;
  summary: string;
  steps: string[];
  /** "Không khi…" from the content, or null. */
  safety: string | null;
  durationMin: number;
  timeOfDay: 'any' | 'evening' | 'day';
}

export interface RecipeListItem {
  recipeId: string;
  recipeVersion: number;
  title: string;
  summary: string;
  durationMin: number;
  minAgeMonths: number;
  /** Server-written, from the rule that chose it (age, region, review); never a health claim. */
  why: string;
}

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
  | { kind: 'rejected'; detail: string }
  /**
   * Slice A5: a care question answered honestly without grounds — no approved guidance or recipe
   * fits ("chưa có gợi ý phù hợp" / "chưa có công thức được duyệt"). Shown as an answer, but
   * nothing useful came from the assistant, so the credit is released.
   */
  | { kind: 'fallback'; parts: AssistantPart[] };

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
    case 'fallback':
      return 'release';
  }
}

export function taskStateForOutcome(o: TaskOutcome): TaskState {
  switch (o.kind) {
    case 'drafts':
      return o.items.length > 0 ? 'ready' : 'failed';
    case 'answer':
    case 'health_route':
    case 'fallback':
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
  // Lumi timers 2026-10-16: start / stop the app's sleep or breastfeeding timer.
  'timer',
  // Lumi fixes 2026-10-16 (LUMI-01): the care module's other logs (care.ts `careTypes`).
  'pump',
  'diaper',
  'growth',
] as const;
export type DraftKind = (typeof draftKinds)[number];

/**
 * LUMI-05: the kinds an app build from before 2026-10-16 can show (it sends no
 * `clientDraftKinds`). The server never sends such a client a draft of another kind.
 */
export const legacyClientDraftKinds: readonly DraftKind[] = [
  'bottle',
  'breast',
  'sleep',
  'expense',
  'reminder',
  'observation',
  'meal',
];

/** The kinds a client can show: what it declared (known kinds only), else the legacy set. */
export function clientDraftKindsOf(declared: readonly string[] | null | undefined): DraftKind[] {
  if (!declared) return [...legacyClientDraftKinds];
  return draftKinds.filter((k) => declared.includes(k));
}

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

/**
 * Rework 2026-10-15: which field of a span the server computed from the others, so the app keeps
 * start, end and duration linked while the person edits (`docs/assistant/api.md`). Absent / null
 * = nothing derived.
 */
export const spanLinkSchema = z
  .object({ derived: z.enum(['startedAt', 'endedAt', 'occurredAt', 'durationMin']) })
  .nullable();
export type SpanLink = z.infer<typeof spanLinkSchema>;

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
  /** Rework 2026-10-15: `{ derived: 'occurredAt' }` when the start was computed from an end. */
  linked: spanLinkSchema.optional(),
});

export const sleepDraftSchema = z.object({
  kind: z.literal('sleep'),
  startedAt: iso.nullable(),
  endedAt: iso.nullable(),
  /**
   * Rework 2026-10-15: the sleep's length in minutes as said ("ngủ 9 tiếng") or as computed from
   * the two ends; the server keeps it equal to end − start whenever both are set (patchDraft
   * recomputes it). Optional: drafts from before the rework lack it.
   */
  durationMin: z.number().int().positive().nullable().optional(),
  linked: spanLinkSchema.optional(),
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
  /**
   * Rework 2026-10-15: what was bought ("Sữa", "Học bơi") from a typed message; saved as the
   * expense note (with the merchant, ≤ 80). Optional: photo drafts and older drafts lack it.
   */
  note: z.string().max(80).nullable().optional(),
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

/**
 * Lumi timers 2026-10-16 (`docs/assistant/api.md` "Timers"): "con đang ngủ", "đang cho bú bên
 * trái", "bé dậy rồi", "bú xong rồi" drive the app's own running timers
 * (`babies/{b}/timers/{sleep|breast}`, contracts `care.ts`), the one source of truth every family
 * member's app listens to. Confirming a `start` creates that timer exactly as the app's "Bắt
 * đầu" would (the confirmer as `startedBy`); confirming a `stop` ends the running session exactly
 * as the app's "Kết thúc" would: the record `r_<sessionId>` (contracts `timerRecordAt`) and the
 * timer's deletion in one transaction.
 */
export const timerDraftSchema = z.object({
  kind: z.literal('timer'),
  timer: z.enum(['sleep', 'breast']),
  action: z.enum(['start', 'stop']),
  /** start: when it began ("lúc 21h", else the send time); stop: when it ended. */
  at: iso.nullable(),
  /** breast start: the side that runs first (one side at a time, like the timer); else null. */
  side: z.enum(['left', 'right']).nullable(),
  /** stop: the running session this ends (the record is `r_<sessionId>`); start: null. */
  sessionId: z
    .string()
    .regex(/^[a-f0-9]{32}$/)
    .nullable(),
  /** stop: when the running timer started (shown; the record's start); start: null. */
  startedAt: iso.nullable(),
});

/**
 * Lumi fixes 2026-10-16 (LUMI-01): "hút sữa 120ml", "thay tã ướt", "bé nặng 5,2kg" are the app's
 * own care logs (`care_sheets.dart` PumpSheet / DiaperSheet, `care_screens.dart` GrowthScreen);
 * confirming writes exactly the record those forms write (contracts `careDataSchemas`, Rules
 * `validCareData`), never a bottle feed, an observation or an expense.
 */
export const pumpDraftSchema = z.object({
  kind: z.literal('pump'),
  /** Millilitres pumped (the form: 1…1000, whole ml). */
  amountMl: z.number().positive().nullable(),
  /** When pumping started (the form's "Bắt đầu"). */
  occurredAt: iso.nullable(),
  /** The form's side (default: the last pump's side, else both). */
  side: z.enum(['left', 'right', 'both']).nullable(),
  /** Optional length (the form's "Thời lượng", 1…240). */
  durationMin: z.number().int().positive().nullable(),
  /** `{ derived: 'occurredAt' }` when the start was computed from "vừa hút xong" + a length. */
  linked: spanLinkSchema.optional(),
});
export const diaperDraftSchema = z.object({
  kind: z.literal('diaper'),
  /** Ướt / Bẩn / Cả hai (the sheet's three tiles); null when the words do not say. */
  diaper: z.enum(['wet', 'dirty', 'both']).nullable(),
  occurredAt: iso.nullable(),
});
export const growthDraftSchema = z.object({
  kind: z.literal('growth'),
  /** Kilograms, one decimal as the form keeps it (0.3…40); required by the module. */
  weightKg: z.number().positive().nullable(),
  /** Centimetres, one decimal (20…150); optional. The module has no head circumference. */
  lengthCm: z.number().positive().nullable(),
  /** The form's "Ngày đo" (baby-local date). */
  measuredOn: z.iso.date().nullable(),
});

export const draftPayloadSchema = z.discriminatedUnion('kind', [
  bottleDraftSchema,
  breastDraftSchema,
  sleepDraftSchema,
  expenseDraftSchema,
  reminderDraftSchema,
  observationDraftSchema,
  mealDraftSchema,
  timerDraftSchema,
  pumpDraftSchema,
  diaperDraftSchema,
  growthDraftSchema,
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
  | 'MISSING_TITLE'
  /** Slice A3: a reminder title longer than the module allows (80). */
  | 'INVALID_TITLE'
  /** Slice A3: a reminder due before now (reminders are set for later, D-031). */
  | 'PAST_TIME'
  /** D-075 #5: the reminder's assignee is no longer an active Cùng nuôi / Người chăm sóc. */
  | 'INVALID_ASSIGNEE';

/** The currencies a draft may carry: exactly the ones Chi tiêu keeps (D-075 #4, `currencyInfo`). */
export const supportedCurrencies = expenseCurrencies;

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
    case 'timer': {
      if (p.at === null) {
        out.push('MISSING_TIME');
        break;
      }
      const at = Date.parse(p.at);
      if (after(p.at)) out.push('FUTURE_TIME');
      if (p.action === 'start') {
        // A timer that would already have run past what its record can hold (24 h sleep,
        // 240 min feed) is no longer "running": log it as a finished sleep / feed instead.
        if (anchor.getTime() - at > timerMaxRunMs[p.timer]) out.push('INVALID_TIME');
      } else if (p.startedAt === null || at <= Date.parse(p.startedAt)) {
        out.push('INVALID_TIME');
      }
      break;
    }
    // ---- Lumi fixes 2026-10-16 (LUMI-01): the care forms' own checks ----
    case 'pump':
      if (p.amountMl === null) out.push('MISSING_AMOUNT');
      else if (
        !Number.isInteger(p.amountMl) ||
        p.amountMl < careLimits.pumpMl.min ||
        p.amountMl > careLimits.pumpMl.max
      )
        out.push('INVALID_AMOUNT');
      if (p.durationMin !== null && p.durationMin > careLimits.durationMin.max) {
        out.push('INVALID_AMOUNT');
      }
      if (p.occurredAt === null) out.push('MISSING_TIME');
      else if (after(p.occurredAt)) out.push('FUTURE_TIME');
      break;
    case 'diaper':
      if (p.occurredAt === null) out.push('MISSING_TIME');
      else if (after(p.occurredAt)) out.push('FUTURE_TIME');
      break;
    case 'growth':
      if (p.weightKg === null) out.push('MISSING_AMOUNT');
      if (
        (p.weightKg !== null && !growthWeightOk(p.weightKg)) ||
        (p.lengthCm !== null && !growthLengthOk(p.lengthCm))
      ) {
        out.push('INVALID_AMOUNT');
      }
      if (p.measuredOn === null) out.push('MISSING_DATE');
      // A date after the anchor's local date in any zone (UTC+14) is in the future.
      else if (
        p.measuredOn > new Date(anchor.getTime() + 14 * 3_600_000).toISOString().slice(0, 10)
      )
        out.push('FUTURE_TIME');
      break;
  }
  return out;
}

/** The growth form's ranges (`careLimits`). */
export const growthWeightOk = (kg: number) =>
  kg >= careLimits.weightKg.min && kg <= careLimits.weightKg.max;
export const growthLengthOk = (cm: number) =>
  cm >= careLimits.lengthCm.min && cm <= careLimits.lengthCm.max;

/** How long a timer may already have run when it is started from chat (`timerRecordAt` caps). */
export const timerMaxRunMs = { sleep: 24 * 3_600_000, breast: 240 * 60_000 } as const;

// ---------- Review fields (Lumi 2026-10-16: every flagged field names a real field) ----------

/** The payload keys of each draft kind (from the schemas), for review lists and tests. */
export const draftFieldKeys: Record<DraftKind, readonly string[]> = {
  bottle: Object.keys(bottleDraftSchema.shape),
  breast: Object.keys(breastDraftSchema.shape),
  sleep: Object.keys(sleepDraftSchema.shape),
  expense: Object.keys(expenseDraftSchema.shape),
  reminder: Object.keys(reminderDraftSchema.shape),
  observation: Object.keys(observationDraftSchema.shape),
  meal: Object.keys(mealDraftSchema.shape),
  timer: Object.keys(timerDraftSchema.shape),
  pump: Object.keys(pumpDraftSchema.shape),
  diaper: Object.keys(diaperDraftSchema.shape),
  growth: Object.keys(growthDraftSchema.shape),
};

/**
 * Fields a draft cannot be saved without (null → `missingFields`, blocking). Everything else is
 * optional: an observation saves without `when` / `note`, a feed without a length, a breastfeed
 * whose side was not said takes the form's default (other side of the last feed, else both), a
 * reminder without a time is all day.
 */
export const requiredDraftFields: Record<DraftKind, readonly string[]> = {
  // Milk is preset to the baby's last bottle milk (the form's memory); null only for "other".
  bottle: ['amountMl', 'occurredAt', 'milk'],
  breast: ['occurredAt'],
  sleep: ['startedAt', 'endedAt'],
  expense: ['totalMinor', 'date', 'currency'],
  reminder: ['title', 'date'],
  observation: ['observation', 'date'],
  meal: ['title'],
  timer: ['at'],
  // LUMI-01: what each care form cannot save without (a pump's side takes the form's default).
  pump: ['amountMl', 'occurredAt'],
  diaper: ['diaper', 'occurredAt'],
  growth: ['weightKg', 'measuredOn'],
};

/**
 * The field each form / module problem points at, per kind (`null` = that problem never applies
 * to the kind). Total on purpose: adding a kind or a problem fails to compile until it is mapped,
 * and contracts tests check every field exists on its kind. `MISSING_TIME` on a sleep names
 * whichever end is null (see `draftReviewFields`).
 */
export const draftProblemFields: Record<DraftKind, Record<DraftProblem, string | null>> = {
  bottle: {
    MISSING_AMOUNT: 'amountMl',
    INVALID_AMOUNT: 'amountMl',
    MISSING_TIME: 'occurredAt',
    FUTURE_TIME: 'occurredAt',
    INVALID_TIME: 'occurredAt',
    MISSING_DATE: null,
    CURRENCY_UNSUPPORTED: null,
    MISSING_TITLE: null,
    INVALID_TITLE: null,
    PAST_TIME: null,
    INVALID_ASSIGNEE: null,
  },
  breast: {
    MISSING_AMOUNT: null,
    INVALID_AMOUNT: 'durationMin',
    MISSING_TIME: 'occurredAt',
    FUTURE_TIME: 'occurredAt',
    INVALID_TIME: 'occurredAt',
    MISSING_DATE: null,
    CURRENCY_UNSUPPORTED: null,
    MISSING_TITLE: null,
    INVALID_TITLE: null,
    PAST_TIME: null,
    INVALID_ASSIGNEE: null,
  },
  sleep: {
    MISSING_AMOUNT: null,
    INVALID_AMOUNT: null,
    MISSING_TIME: 'startedAt',
    FUTURE_TIME: 'endedAt',
    INVALID_TIME: 'endedAt',
    MISSING_DATE: null,
    CURRENCY_UNSUPPORTED: null,
    MISSING_TITLE: null,
    INVALID_TITLE: null,
    PAST_TIME: null,
    INVALID_ASSIGNEE: null,
  },
  expense: {
    MISSING_AMOUNT: 'totalMinor',
    INVALID_AMOUNT: 'totalMinor',
    MISSING_TIME: null,
    FUTURE_TIME: 'date',
    INVALID_TIME: 'date',
    MISSING_DATE: 'date',
    CURRENCY_UNSUPPORTED: 'currency',
    MISSING_TITLE: null,
    INVALID_TITLE: null,
    PAST_TIME: 'date',
    INVALID_ASSIGNEE: null,
  },
  reminder: {
    MISSING_AMOUNT: null,
    INVALID_AMOUNT: null,
    MISSING_TIME: 'time',
    FUTURE_TIME: null,
    INVALID_TIME: 'date',
    MISSING_DATE: 'date',
    CURRENCY_UNSUPPORTED: null,
    MISSING_TITLE: 'title',
    INVALID_TITLE: 'title',
    PAST_TIME: 'date',
    INVALID_ASSIGNEE: 'assigneeUid',
  },
  observation: {
    MISSING_AMOUNT: null,
    INVALID_AMOUNT: null,
    MISSING_TIME: null,
    FUTURE_TIME: 'date',
    INVALID_TIME: 'date',
    MISSING_DATE: 'date',
    CURRENCY_UNSUPPORTED: null,
    MISSING_TITLE: null,
    INVALID_TITLE: null,
    PAST_TIME: null,
    INVALID_ASSIGNEE: null,
  },
  meal: {
    MISSING_AMOUNT: null,
    INVALID_AMOUNT: null,
    MISSING_TIME: 'occurredAt',
    FUTURE_TIME: 'occurredAt',
    INVALID_TIME: 'occurredAt',
    MISSING_DATE: null,
    CURRENCY_UNSUPPORTED: null,
    MISSING_TITLE: 'title',
    INVALID_TITLE: 'title',
    PAST_TIME: null,
    INVALID_ASSIGNEE: null,
  },
  timer: {
    MISSING_AMOUNT: null,
    INVALID_AMOUNT: null,
    MISSING_TIME: 'at',
    FUTURE_TIME: 'at',
    INVALID_TIME: 'at',
    MISSING_DATE: null,
    CURRENCY_UNSUPPORTED: null,
    MISSING_TITLE: null,
    INVALID_TITLE: null,
    PAST_TIME: null,
    INVALID_ASSIGNEE: null,
  },
  // INVALID_AMOUNT names whichever value is out of range (see `draftReviewFields`).
  pump: {
    MISSING_AMOUNT: 'amountMl',
    INVALID_AMOUNT: 'amountMl',
    MISSING_TIME: 'occurredAt',
    FUTURE_TIME: 'occurredAt',
    INVALID_TIME: 'occurredAt',
    MISSING_DATE: null,
    CURRENCY_UNSUPPORTED: null,
    MISSING_TITLE: null,
    INVALID_TITLE: null,
    PAST_TIME: null,
    INVALID_ASSIGNEE: null,
  },
  diaper: {
    MISSING_AMOUNT: null,
    INVALID_AMOUNT: null,
    MISSING_TIME: 'occurredAt',
    FUTURE_TIME: 'occurredAt',
    INVALID_TIME: 'occurredAt',
    MISSING_DATE: null,
    CURRENCY_UNSUPPORTED: null,
    MISSING_TITLE: null,
    INVALID_TITLE: null,
    PAST_TIME: null,
    INVALID_ASSIGNEE: null,
  },
  growth: {
    MISSING_AMOUNT: 'weightKg',
    INVALID_AMOUNT: 'weightKg',
    MISSING_TIME: null,
    FUTURE_TIME: 'measuredOn',
    INVALID_TIME: 'measuredOn',
    MISSING_DATE: 'measuredOn',
    CURRENCY_UNSUPPORTED: null,
    MISSING_TITLE: null,
    INVALID_TITLE: null,
    PAST_TIME: null,
    INVALID_ASSIGNEE: null,
  },
};

const isMissingProblem = (pr: DraftProblem) =>
  pr === 'MISSING_AMOUNT' ||
  pr === 'MISSING_TIME' ||
  pr === 'MISSING_DATE' ||
  pr === 'MISSING_TITLE';

/**
 * The review lists of a draft, from its payload and the form + module problems: `missing` = the
 * required fields that are empty (plus a missing-problem's field), `uncertain` = fields whose
 * value a problem questions, plus [uncertain] candidates (the model's doubts, grounding) that are
 * real fields of the kind and hold a value. Never a field the kind does not have, never a filled
 * field as "missing" (Lumi 2026-10-16: an observation said `date` was missing while it was set;
 * a breastfeed kept `occurredAt` "missing" after "Vừa xong" filled it).
 */
export function draftReviewFields(
  p: DraftPayload,
  problems: readonly DraftProblem[],
  uncertainCandidates: Iterable<string> = [],
): { missing: string[]; uncertain: string[] } {
  const keys = new Set(draftFieldKeys[p.kind]);
  const value = (k: string) => (p as Record<string, unknown>)[k];
  const empty = (k: string) => {
    const v = value(k);
    return v === null || v === undefined || (typeof v === 'string' && v.trim() === '');
  };
  const missing = new Set<string>();
  const uncertain = new Set<string>();
  for (const f of requiredDraftFields[p.kind]) if (empty(f)) missing.add(f);
  for (const pr of new Set([...problems, ...assistantModuleProblems(p)])) {
    if (p.kind === 'sleep' && pr === 'MISSING_TIME') {
      if (p.startedAt === null) missing.add('startedAt');
      if (p.endedAt === null) missing.add('endedAt');
      continue;
    }
    if (p.kind === 'expense' && pr === 'CURRENCY_UNSUPPORTED' && p.currency === null) {
      missing.add('currency');
      continue;
    }
    // LUMI-01: an out-of-range value names the value that is out of range.
    if (p.kind === 'pump' && pr === 'INVALID_AMOUNT') {
      const ml = p.amountMl;
      if (ml !== null && (!Number.isInteger(ml) || ml < 1 || ml > careLimits.pumpMl.max)) {
        uncertain.add('amountMl');
      }
      if (p.durationMin !== null && p.durationMin > careLimits.durationMin.max) {
        uncertain.add('durationMin');
      }
      continue;
    }
    if (p.kind === 'growth' && pr === 'INVALID_AMOUNT') {
      if (p.weightKg !== null && !growthWeightOk(p.weightKg)) uncertain.add('weightKg');
      if (p.lengthCm !== null && !growthLengthOk(p.lengthCm)) uncertain.add('lengthCm');
      continue;
    }
    // LUMI-11: a reminder for a time already gone names the time when one is set.
    if (p.kind === 'reminder' && pr === 'PAST_TIME') {
      uncertain.add(p.time !== null ? 'time' : 'date');
      continue;
    }
    const f = draftProblemFields[p.kind][pr];
    if (f === null) continue;
    if (isMissingProblem(pr) && empty(f)) missing.add(f);
    else uncertain.add(f);
  }
  for (const f of uncertainCandidates) if (keys.has(f) && !empty(f)) uncertain.add(f);
  return {
    missing: [...missing].filter((f) => keys.has(f)).sort(),
    uncertain: [...uncertain].filter((f) => keys.has(f) && !missing.has(f)).sort(),
  };
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
  /**
   * LUMI-05 (2026-10-16): the draft kinds this app build can show and save (`draftKinds` it
   * knows; unknown names are ignored). Absent = an app from before this field
   * (`legacyClientDraftKinds`): the server never sends it a kind it cannot render (a timer, a
   * pump / diaper / growth log) and says so instead (`APP_UPDATE_NEEDED`).
   */
  clientDraftKinds: z.array(z.string().min(1).max(20)).max(30).optional(),
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
  /**
   * Keep the receipt with the expense (default, D-075 #3) or "Xoá ảnh sau khi đọc". The uploaded
   * original is always deleted once a copy is kept (or nothing can use it).
   */
  retention: z.enum(['delete_after_read', 'keep_with_record']).default('keep_with_record'),
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
  /** The scope the app is showing (M05): a different one than the task's → SCOPE_CHANGED, so a
   * draft never lands on the child the person switched to. Optional for older clients. */
  scope: assistantScopeSchema.optional(),
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
  /**
   * `getAssistantUsage` only: the newest credit lines of this period (≤ 20), never content —
   * kind, ledger state, credits held or counted, when, and who asked (task author label).
   */
  recent?: AssistantUsageEntry[];
}

/** One credit line of the household pool ("Gần đây", CH19). */
export interface AssistantUsageEntry {
  /** `summary`: an AI summary (D-075 #1); `text` / `image`: a chat task. */
  kind: 'text' | 'image' | 'summary';
  state: 'reserved' | 'committed' | 'released';
  credits: number;
  at: string;
  /** The asking member's custom relation or name; null when unknown (summaries, old tasks). */
  who: string | null;
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
export type TaskEventType = (typeof taskEventTypes)[number];

// ---------- Server core (slice A2; docs/assistant/api.md) ----------

/** `setAssistantConsent` (P-160): the current version, or null to withdraw. */
export const setAssistantConsentRequestSchema = z.object({
  ...envelope,
  consent: z.object({ version: z.string().min(1).max(40) }).nullable(),
});

/** `getAssistantTask`: the authoritative snapshot (M11); events after [afterSequence] only. */
export const getAssistantTaskRequestSchema = z.object({
  ...envelope,
  taskId: z.string().min(1).max(80),
  afterSequence: z.number().int().min(0).nullable(),
});

/**
 * `listAssistantHistory` (CH03): the baby's shared thread first (D-075 #2, Cùng nuôi and Người
 * chăm sóc) then the caller's own private conversations about [babyId] (newest first), or the
 * messages of one of them (newest first). `cursor` is the `nextCursor` of the previous page.
 */
export const listAssistantHistoryRequestSchema = z.object({
  ...envelope,
  babyId: z.string().min(1).max(128),
  conversationId: z.string().min(1).max(80).nullable(),
  cursor: z.string().min(1).max(200).nullable(),
  limit: z.number().int().min(1).max(50),
});

/**
 * `deleteAssistantConversation` (CH03 "Xoá cuộc trò chuyện"): explicit confirmation required. A
 * private one by its owner; the shared baby thread by a Cùng nuôi only (D-075 #2), for everyone.
 * Saved records (care, check-ins, reminders, expenses) always stay in their modules.
 */
export const deleteAssistantConversationRequestSchema = z.object({
  ...envelope,
  conversationId: z.string().min(1).max(80),
  confirm: z.literal(true),
});

/**
 * Every assistant callable answers with this envelope (brief p.10). Hard failures are errors with
 * `details: { reason: AssistantError, retryable }`; `blocked` (e.g. USAGE_EXHAUSTED at start, kept
 * for resume) and `partial` (some confirmed items not saved) are answers, not errors.
 */
export interface AssistantResponse<T> {
  contractVersion: typeof assistantContractVersion;
  /** Echo of `clientRequestId`. */
  requestId: string;
  taskId: string | null;
  serverTime: string;
  /** Version of what `data` describes (task version, draft revision, …); 0 when not versioned. */
  dataVersion: number;
  status: 'ok' | 'blocked' | 'partial';
  reasonCode: AssistantError | null;
  retryable: boolean;
  data: T;
}

/** Where the reservation of a task stands (never the model cost). */
export type TaskUsageState = 'none' | 'reserved' | 'committed' | 'released';

export interface AssistantTaskView {
  id: string;
  conversationId: string;
  scope: AssistantScope;
  state: TaskState;
  version: number;
  modality: TaskModality;
  /** Credits quoted for this task (0 for health support). */
  credits: number;
  plan: 'free' | 'premium';
  usage: TaskUsageState;
  errorCode: AssistantError | null;
  round: number;
  /** The open question while `awaiting_clarification`. */
  clarification: Clarification | null;
  clarificationExpiresAt: string | null;
  anchorInstant: string;
  timezone: string;
  createdAt: string;
  updatedAt: string;
  /** Slice A5: the care thread of this task (CH15–CH18); absent for other tasks. */
  care?: AssistantCareView | null;
  /** D-075 #2: `shared` = in the baby's shared thread (absent on tasks from before D-075). */
  visibility?: AssistantVisibility;
  /** D-075 #2: who asked (the task's author); absent on tasks from before D-075. */
  author?: AssistantAuthor | null;
  /**
   * Rework 2026-10-15: why a task is private although it was sent from the shared thread —
   * `spending` (money in the words, or an expense found by the model): the task, its message and
   * its drafts live in the author's private thread (`conversationId`), never in the shared one.
   */
  routing?: AssistantRouting | null;
}

/** Rework 2026-10-15: `task.routing` (see `AssistantTaskView`). */
export interface AssistantRouting {
  reason: 'spending';
  /** Where the person sent it from. */
  from: 'shared_thread';
  /** `start`: detected in the words at `startTask`; `worker`: moved after the model found an expense. */
  at: 'start' | 'worker';
}

export interface AssistantDraftView extends ActionDraft {
  /** Same checks as the form (`draftProblems`), against the confirm time. */
  problems: DraftProblem[];
  /** D-075 #2: who saved it (the confirmer, maybe not the task's author); null until saved. */
  confirmedBy?: AssistantAuthor | null;
}

export interface AssistantEvent {
  taskId: string;
  eventId: string;
  sequence: number;
  type: TaskEventType;
  emittedAt: string;
  payload: Record<string, unknown>;
}

export interface AssistantMessage {
  id: string;
  conversationId: string;
  role: 'user' | 'assistant';
  parts: AssistantPart[];
  taskId: string | null;
  sequence: number;
  createdAt: string;
  attachmentIds: string[];
  /**
   * D-075 #2: who wrote it — the sender of a user message, the confirmer of an `action_result`;
   * null for the assistant's own replies; absent on messages from before D-075.
   */
  author?: AssistantAuthor | null;
}

export interface AssistantTaskSnapshot {
  task: AssistantTaskView;
  drafts: AssistantDraftView[];
  /** Ordered by `sequence`; the snapshot (not the events) is the authority. */
  events: AssistantEvent[];
  /** The task's messages (user input, clarification answers, results), ordered. */
  messages: AssistantMessage[];
  /** Slice A3: the task's photos and their real retention state (G05); absent for text tasks. */
  attachments?: AssistantAttachmentView[];
}

export interface ConfirmItemResult {
  draftId: string;
  status: 'saved' | 'failed' | 'conflict';
  revision: number;
  recordId: string | null;
  recordLink: string | null;
  errorCode: AssistantError | null;
  /** `VALIDATION_FAILED` details (field-level, never values). */
  problems: DraftProblem[];
}

export interface ConfirmDraftsResult {
  items: ConfirmItemResult[];
  /** Some selected items were not saved; saved ones stay saved (CH07). */
  partial: boolean;
}

export interface AssistantConversationView extends AssistantConversation {
  lastTaskId: string | null;
}

export interface AssistantHistoryPage<T> {
  items: T[];
  nextCursor: string | null;
}

// ---------- Photos (slice A3; docs/assistant/api.md, security.md) ----------

/** Keep a copy with the saved expense ("Giữ ảnh hoá đơn", default, D-075 #3) or delete after reading. */
export const attachmentRetentions = ['delete_after_read', 'keep_with_record'] as const;
export type AttachmentRetention = (typeof attachmentRetentions)[number];

/**
 * Where an uploaded photo stands. `deleted` is set only once Storage confirmed the deletion;
 * a failed deletion is `deletion_pending` and retried (G05, M07) — never shown as deleted.
 */
export const attachmentStates = ['uploading', 'ready', 'deletion_pending', 'deleted'] as const;
export type AttachmentState = (typeof attachmentStates)[number];

/** `createAttachmentUpload`: where the app uploads the chosen photo, once, before `startTask`. */
export interface AssistantUploadTarget {
  attachmentId: string;
  /** Owned Storage path `assistant/{uid}/{attachmentId}` (Storage Rules: create once, no read). */
  uploadPath: string;
  mime: string;
  /** The declared size: the upload may not be larger. */
  maxBytes: number;
  /** The upload must happen before this instant (then `startTask` with the attachment id). */
  expiresAt: string;
  retention: AttachmentRetention;
}

export interface AssistantAttachmentView {
  id: string;
  mime: string;
  bytes: number;
  retention: AttachmentRetention;
  state: AttachmentState;
  /** A re-encoded copy was kept with the saved expense (its `receiptPath`). */
  keptWithRecord: boolean;
  /** Set only once Storage confirmed the deletion of the uploaded original. */
  deletedAt: string | null;
  /** The file was refused before any reading (not an image, undecodable, too large). */
  rejected: boolean;
}

/** D-075 #3: receipt photos are kept with the expense unless the person chose otherwise. */
export const defaultAttachmentRetention: AttachmentRetention = 'keep_with_record';

// ---- Chi tiêu currencies (D-075 #4; owned by Chi tiêu, `spending.ts` `currencyInfo`) ----
/** What an expense without a currency is in (older documents); not a limit any more. */
export const expenseModuleCurrency = legacyCurrency;

// The three module limits below are the ONLY places the assistant encodes them; the D-075 #5
// follow-up (date-only reminders with an assignee) flips the two reminder functions.

/** Whether Chi tiêu can store an expense in [currency]: any of `expenseCurrencies` (D-075 #4). */
export function expenseCurrencySupported(currency: string | null): boolean {
  return isExpenseCurrency(currency);
}
// ---- end Chi tiêu currencies ----

// ---- One-off reminders: date-only and assignee (D-075 #5; owned by reminders) ----
/**
 * Whether a one-off reminder needs a time: no since D-075 #5 — a date without a time is an
 * all-day reminder, notified at the person's chosen time (never a silent 09:00).
 */
export function reminderNeedsTime(): boolean {
  return false;
}

/**
 * Whether one-off reminders take an assignee: yes since D-075 #5 — a member the person picks
 * (Cùng nuôi or Người chăm sóc, `reminderAssigneeRoles`), never a name read from a photo.
 */
export function reminderAssigneeSupported(): boolean {
  return true;
}
// ---- end one-off reminders ----
/** One-off reminders: title length the module accepts (Rules `validReminderFields`). */
export const reminderModuleTitleMax = 80;

/**
 * Module checks beyond the form checks (`draftProblems`) for what a module can store today:
 * Chi tiêu takes the currencies of `currencyInfo`, each up to its own ceiling in minor units
 * (1 000 000 000 đ for VND); a one-off reminder takes a date with or without a time (no time =
 * all day, D-075 #5; never a silent 09:00) and a title of at most 80 characters.
 */
export function assistantModuleProblems(p: DraftPayload): DraftProblem[] {
  const out: DraftProblem[] = [];
  if (p.kind === 'expense') {
    if (p.currency !== null && !expenseCurrencySupported(p.currency)) {
      out.push('CURRENCY_UNSUPPORTED');
    }
    // Chi tiêu currencies (D-075 #4): the ceiling of the receipt's currency, VND when unknown.
    const ceiling = amountMaxFor(isExpenseCurrency(p.currency) ? p.currency : legacyCurrency);
    if (p.totalMinor !== null && p.totalMinor > ceiling) out.push('INVALID_AMOUNT');
  } else if (p.kind === 'reminder') {
    if (p.time === null && reminderNeedsTime()) out.push('MISSING_TIME');
    if (p.title.trim().length > reminderModuleTitleMax) out.push('INVALID_TITLE');
  }
  return out;
}

// ---------- Care: guidance, plan, follow-up, recipes (slice A5; docs/assistant/tools.md) ----------

export const sleepConcernKinds = ['falling_asleep', 'night_waking', 'both'] as const;
export type SleepConcernKind = (typeof sleepConcernKinds)[number];

/** What the person reported about a sleep concern (CH15); a fact they gave, never a cause. */
export interface SleepConcern {
  kind: SleepConcernKind | null;
  when: 'night' | 'day' | 'both' | null;
  /** Onset, asked only when needed and always skippable ("Chưa rõ"). */
  since: 'today' | 'days_2_3' | 'longer' | null;
}

/** The outcomes CH17 offers; "Chưa thử" is always one of them. */
export const careFeedbackOutcomes = ['helpful', 'unsure', 'not_suitable', 'not_tried'] as const;
export type CareFeedbackOutcome = (typeof careFeedbackOutcomes)[number];

/**
 * "Thử tối nay" (CH16) is an **intention**, not "đã thử": the plan and the moment feedback opens
 * (the next morning after an evening plan). Before it, a tried outcome is refused.
 */
export interface AssistantCarePlan {
  contentId: string;
  contentVersion: number;
  /** Baby-local date the person plans to try it. */
  plannedFor: string;
  plannedAt: string;
  feedbackOpensAt: string;
}

export interface AssistantCareView {
  topic: 'sleep_concern' | 'meal_ideas';
  sleep: SleepConcern | null;
  guidance: {
    contentId: string;
    contentVersion: number;
    reasonCode: 'SELF_REPORTED_NEED' | 'DATA_INSIGHT' | 'PREVIOUS_HELPFUL';
    reviewed: boolean;
  } | null;
  recipeIds: string[];
  plan: AssistantCarePlan | null;
  /**
   * CH17: the question to show once the plan's chance to try has passed and nothing was answered
   * yet; never phrased as if it was tried, and always with "Chưa thử". Null otherwise.
   */
  followUp: {
    contentId: string;
    contentVersion: number;
    question: { vi: string; en: string };
    choices: { id: CareFeedbackOutcome; label: { vi: string; en: string } }[];
  } | null;
  /** The latest answer for this task's guidance (any outcome, "Chưa thử" included). */
  feedback: { contentId: string; contentVersion: number; outcome: CareFeedbackOutcome } | null;
}

/** `planAssistantActivity` ("Thử tối nay"): 0 credits, no model; the guidance of this task only. */
export const planAssistantActivityRequestSchema = z.object({
  ...envelope,
  taskId: z.string().min(1).max(80),
  contentId: z.string().min(1).max(60),
  contentVersion: z.number().int().min(1),
});

/** Actual age in full months between two local dates (date of birth, today); never corrected. */
export function ageInFullMonths(dateOfBirth: string, today: string): number {
  const [by, bm, bd] = dateOfBirth.slice(0, 10).split('-').map(Number) as [number, number, number];
  const [ty, tm, td] = today.slice(0, 10).split('-').map(Number) as [number, number, number];
  return Math.max(0, (ty - by) * 12 + (tm - bm) - (td < bd ? 1 : 0));
}

// ---------- D-075 #2: one shared conversation per baby (docs/assistant/data.md) ----------

/** Who wrote a message / asked a task / saved a draft: the member block the app labels. */
export interface AssistantAuthor {
  uid: string;
  name: string;
  /** `mother`, `father`, `nanny`… (the app shows "Mẹ", "Ba", "Cô Hoa"). */
  relation: string;
  relationCustom: string | null;
}

export const assistantVisibilities = ['shared', 'private'] as const;
export type AssistantVisibility = (typeof assistantVisibilities)[number];

/** Roles that read and write the baby's shared thread; relatives never do. */
export const sharedThreadRoles = ['coParent', 'caregiver'] as const;

export function inSharedThread(role: string): boolean {
  return (sharedThreadRoles as readonly string[]).includes(role);
}

/**
 * Where a new task goes (D-075 #2, spending excluded): a TEXT task about a child, asked by a Cùng
 * nuôi or Người chăm sóc and not hinted as an expense, joins the baby's shared thread. Household
 * scope, an `expense` hint and every photo task (a photo may be a receipt; that is known only
 * after reading it) stay private to their author, as do all tasks of a relative. Rework
 * 2026-10-15: so does a text whose words look like money ([looksLikeSpending]: an amount
 * "500k" / "$20", or mua, trả tiền, tiền, học phí, spent, paid…), mixed messages included.
 */
export function taskVisibilityFor(x: {
  scope: AssistantScope;
  modality: TaskModality;
  intentHint: string | null;
  role: string;
  text?: string | null;
}): AssistantVisibility {
  return x.scope.type === 'child' &&
    x.modality === 'text' &&
    x.intentHint !== 'expense' &&
    !(x.text && looksLikeSpending(x.text)) &&
    inSharedThread(x.role)
    ? 'shared'
    : 'private';
}

/** The baby's shared thread id (deterministic: every member lands on the same document). */
export function sharedConversationIdFor(babyId: string): string {
  return `cv_${babyId}`;
}
