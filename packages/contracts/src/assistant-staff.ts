import { z } from 'zod';
import type {
  AssistantError,
  AttachmentRetention,
  AttachmentState,
  DraftKind,
  DraftState,
  TaskEventType,
  TaskModality,
  TaskState,
  TaskUsageState,
} from './assistant.js';
import type { FlagKey, Flags } from './config.js';
import type { ReservationState } from './quota.js';
import type { AiBudget } from './staff.js';

/**
 * Portal "Trợ lý AI" (docs/assistant/architecture.md §5 slice A6): usage of the household credit
 * pool, one task looked up by id for support, and the assistant kill switches (P-161). Staff
 * views are aggregates and closed codes only: family and baby ids as codes (F-XXXX / B-XXXX), no
 * names, no message or draft text, no photos, no paths, no uids.
 */

/** Which budget a credit counted against, read from the window id (D-075 #1). */
export const assistantPoolPlans = ['free', 'premium', 'beta'] as const;
export type AssistantPoolPlan = (typeof assistantPoolPlans)[number];

/**
 * `assistant_cal_*` = Free; `assistant_paid_campaign-*` / `assistant_paid_beta_*` = a beta grant
 * (`assistant-usage.ts` keys the beta window by the grant id); any other `assistant_paid_*` = a
 * paid or promo grant. Null for windows of other features.
 */
export function assistantPoolPlanOf(windowId: string): AssistantPoolPlan | null {
  if (windowId.startsWith('assistant_cal_')) return 'free';
  if (
    windowId.startsWith('assistant_paid_campaign-') ||
    windowId.startsWith('assistant_paid_beta_')
  ) {
    return 'beta';
  }
  if (windowId.startsWith('assistant_paid_')) return 'premium';
  return null;
}

/** The assistant kill switches (P-161), in the order the portal lists them. */
export const assistantSwitchKeys = [
  'assistant',
  'assistant_live',
  'assistant_images',
  'assistant_care',
  'assistant_writes',
  'assistant_upsell',
] as const satisfies readonly FlagKey[];
export type AssistantSwitchKey = (typeof assistantSwitchKeys)[number];

/** `assistantTasks/{tk}.outcome.kind` as the worker stores it (contracts `TaskOutcome`). */
export const assistantOutcomeKinds = [
  'drafts',
  'answer',
  'clarification',
  'health_route',
  'unreadable',
  'error',
  'rejected',
  'fallback',
] as const;
export type AssistantOutcomeKind = (typeof assistantOutcomeKinds)[number];

/** Days covered by `staffAssistantUsage`. */
export const assistantUsageDays = 30;

/** `staffAssistantUsage`: the last 30 Vietnam days, aggregates only. */
export interface StaffAssistantUsage {
  /** Start of the first day (ISO); the listing covers `since` → now. */
  since: string;
  /**
   * The bounded reads hit their cap (newest kept): the numbers then cover fewer days than 30.
   * `tasks` = `assistantTasks` created in the period, `ops` = assistant credit reservations.
   */
  truncated: { tasks: boolean; ops: boolean };
  /** One row per budget, from the credit ledger (`quotaOps`, chat and AI summaries). */
  pool: Array<{
    plan: AssistantPoolPlan;
    /** Credits counted (committed) / given back (released) / still held, reserved in the period. */
    committed: number;
    released: number;
    held: number;
    /** Committed credits by source: chat tasks and AI summaries (D-075 #1). */
    chat: number;
    summaries: number;
    /** Households with a reservation in the period. */
    households: number;
    /** Households whose window of this budget is still open and fully used or held. */
    exhausted: number;
  }>;
  /** One row per Vietnam day, oldest first: credits committed / released that day. */
  daily: Array<{ day: string; committed: number; released: number }>;
  tasks: {
    total: number;
    byState: Partial<Record<TaskState, number>>;
    /** `none` = no model result yet (blocked, queued, processing, canceled before a result). */
    byOutcome: Partial<Record<AssistantOutcomeKind | 'none', number>>;
    byModality: Partial<Record<TaskModality, number>>;
    /** Health support answers (keyword signs at start or from the model; 0 credits). */
    health: number;
    /** Error codes of failed / blocked tasks, largest first. */
    errors: Array<{ code: AssistantError; count: number }>;
  };
  model: {
    /** Provider calls recorded on tasks (`modelCalls`). */
    calls: number;
    tasksWithCalls: number;
    /** Calls × the per-call charge of the AI budget (text 300 đ, photo reading 900 đ). */
    estimatedCostVnd: number;
    /** By `model` / `promptVersion` as stored on the task (no key, no prompt text). */
    byModel: Array<{ model: string; promptVersion: string | null; tasks: number; calls: number }>;
    /**
     * Created → ready of tasks that called the model (queue + model + settle; the worker records
     * no per-call latency). Null without samples.
     */
    timeToReady: { samples: number; p50Ms: number | null; p95Ms: number | null };
  };
  /** The monthly AI budget shared with summaries and story drafts (`config/ai`). */
  budget: AiBudget;
  /** `config/entitlements.quotas.assistant` in force (edited in Premium › Cấu hình). */
  credits: {
    free: number;
    premium: number;
    textCredits: number;
    imageCredits: number;
    aiSummaryCredits: number;
    stored: boolean;
  };
}

export const staffAssistantTaskSchema = z.object({
  taskId: z
    .string()
    .trim()
    .regex(/^tk_[a-f0-9]{32}$/),
});

/** `staffAssistantTask`: one task for support. States, codes, counts and times only. */
export interface StaffAssistantTask {
  taskId: string;
  family: string;
  /** "B-XXXX" code of the scope's baby. */
  baby: string;
  scope: 'child' | 'household';
  visibility: 'shared' | 'private';
  state: TaskState;
  modality: TaskModality;
  plan: 'free' | 'premium';
  /** The budget of its window, when a window was used. */
  pool: AssistantPoolPlan | null;
  credits: number;
  usage: TaskUsageState;
  errorCode: AssistantError | null;
  outcome: { kind: AssistantOutcomeKind; drafts: number; parts: string[] } | null;
  /** Health support (the signs themselves are not shown). */
  health: boolean;
  round: number;
  /** Questions asked (catalog field ids) and whether each was answered; never the answer. */
  clarifications: Array<{ field: string; round: number; answered: boolean }>;
  attempt: number;
  modelCalls: number;
  model: string | null;
  promptVersion: string | null;
  policyVersion: string | null;
  /** Care thread topic (slice A5), never the reported facts. */
  careTopic: string | null;
  createdAt: string;
  updatedAt: string;
  readyAt: string | null;
  clarificationExpiresAt: string | null;
  leaseUntil: string | null;
  /** The credit reservation in the ledger (ids with hashes shortened). */
  reservation: {
    id: string;
    window: string;
    units: number;
    state: ReservationState | null;
    reservedAt: string | null;
    committedAt: string | null;
    releasedAt: string | null;
    releaseReason: string | null;
  } | null;
  drafts: Array<{
    id: string;
    kind: DraftKind | null;
    state: DraftState;
    revision: number;
    /** Field names only. */
    missingFields: string[];
    uncertainFields: string[];
    warnings: string[];
    errorCode: string | null;
    expiresAt: string | null;
    savedAt: string | null;
  }>;
  attachments: Array<{
    state: AttachmentState;
    retention: AttachmentRetention | null;
    rejected: boolean;
    deleted: boolean;
  }>;
  /** Newest 50 events, oldest first; no payload. */
  events: Array<{ sequence: number; type: TaskEventType; at: string }>;
}

/** `staffAssistantSwitches`: the assistant flags (family codes only) and their recent changes. */
export interface StaffAssistantSwitches {
  flags: Pick<Flags, AssistantSwitchKey>;
  lastEdit: Partial<Record<AssistantSwitchKey, { by: string; at: string }>>;
  recent: Array<{
    action: string;
    target: string;
    by: string;
    at: string;
    reason: string;
    detail: Record<string, unknown> | null;
  }>;
}
