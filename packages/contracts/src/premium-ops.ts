import { z } from 'zod';
import { reportSummaryRequestSchema, type SummaryFallbackReason } from './ai-summary.js';
import type { BillingProvider } from './billing.js';
import type { rolloutScopes } from './config.js';
import type { GrantEnvironment, GrantStatus } from './entitlements.js';
import type { KeepsakeJobErrorCode, KeepsakeJobStatus, KeepsakeJobStep } from './keepsake-jobs.js';
import type { QuotaFeature, ReservationState } from './quota.js';
import { familyCodeSchema, type AiBudget } from './staff.js';

/**
 * Premium operations views on the portal (plan §5.6, brief "Portal cần thêm"): AI policy, video
 * render operations and one family's quota windows and billing records. Read-only, for staff:
 * family codes and hashed ids only — never baby names, captions, media paths, uids, store
 * transaction ids or purchase tokens.
 */

/** "Chưa đúng? Báo lại" problems (`aiReports.problem`). */
export const aiReportProblems = reportSummaryRequestSchema.shape.problem.options;
export type AiReportProblem = (typeof aiReportProblems)[number];

/** Technical template fallbacks (the model was asked or should have been, and did not answer). */
export const technicalFallbackReasons = ['timeout', 'invalid', 'unavailable'] as const;

/** `staffAiPolicy`: the AI settings in force and the last 30 days of summary counters. */
export interface StaffAiPolicy {
  /** The provider behind summaries; `template` while no model key is configured. No secrets. */
  provider: { name: 'openai' | 'template'; model: string | null };
  consentVersion: string;
  promptVersion: string;
  /** Pipeline settings (contracts `aiSummaryLimits`). */
  limits: {
    rangeDays: number;
    maxFacts: number;
    maxCandidates: number;
    timeoutMs: number;
    costVnd: number;
  };
  /** The `ai_assist` kill switch (portal Tính năng); `families` = how many picked families. */
  flag: {
    enabled: boolean;
    scope: (typeof rolloutScopes)[number];
    percent: number;
    families: number;
  };
  /** `config/entitlements.quotas.ai` (portal Premium); `stored` false = shipped defaults. The
   * `ai` pair is legacy since D-075 #1: summaries charge `assistant` credits (1 each). */
  quotas: {
    perBabyPerDay: number;
    perFamilyPerMonth: number;
    stored: boolean;
    /** D-075 #1: the assistant credit pool (absent from servers before D-075). */
    assistant?: { free: number; premium: number; textCredits: number; imageCredits: number };
  };
  budget: AiBudget;
  /** One row per Vietnam day, oldest first (`appEventsDaily`). */
  days: Array<{ day: string; generated: number; ai: number; cache: number; fallback: number }>;
  totals: {
    generated: number;
    ai: number;
    cache: number;
    fallback: number;
    /** Template answers / all answers; null without answers. */
    fallbackRate: number | null;
    /** timeout + invalid + unavailable / all answers; null without answers. */
    technicalRate: number | null;
  };
  /** `summaryFallback__*` over the same days, largest first; zero rows left out. */
  fallbackReasons: Array<{ reason: SummaryFallbackReason; count: number }>;
  /** Open `aiReports` by problem (no summary text, no child data). */
  reports: { open: number; byProblem: Record<AiReportProblem, number> };
}

/** What the reservation's state should be for the job's state (`null` = no expectation). */
export type RenderLedgerIssue = 'not-released' | 'not-committed' | 'not-held' | 'missing';

/** `staffRenderOps`: one keepsake video job across families. */
export interface StaffRenderJob {
  /** "KJ-1A2B": a stable short code of the job id. */
  code: string;
  family: string;
  templateId: string;
  templateVersion: number | null;
  status: KeepsakeJobStatus;
  step: KeepsakeJobStep | null;
  progress: number;
  attempts: number;
  lease: number;
  error: KeepsakeJobErrorCode | null;
  /** The quota reservation (ids with their hashes shortened). */
  reservation: {
    id: string;
    window: string;
    seq: number;
    state: ReservationState | null;
    issue: RenderLedgerIssue | null;
  } | null;
  createdAt: string;
  updatedAt: string;
  startedAt: string | null;
  finishedAt: string | null;
}

export interface StaffRenderOps {
  kpis: {
    active: number;
    failed24h: number;
    completed24h: number;
    /** Reservations still held by jobs that are no longer running, or missing. */
    ledgerIssues: number;
  };
  /** Failed jobs of the listing by error code. */
  failures: Partial<Record<KeepsakeJobErrorCode, number>>;
  /** Newest first, at most 100. */
  jobs: StaffRenderJob[];
}

export const familyQuotaSchema = z.object({ code: familyCodeSchema });

/** `staffFamilyQuota`: one family's quota windows and billing records. */
export interface StaffFamilyQuota {
  code: string;
  /** Windows that ended in the last 62 days or are still open, latest end first (≤ 40). */
  windows: Array<{
    /** Window id with baby ids as codes and hashes shortened. */
    window: string;
    feature: QuotaFeature;
    scope: 'calendar_month' | 'day' | 'paid';
    limit: number;
    used: number;
    reserved: number;
    startsAt: string | null;
    resetsAt: string | null;
    open: boolean;
  }>;
  /** Reservations still `reserved` (held units). */
  held: number;
  accounts: Array<{
    /** `apple_1a2b3c4d…`: the provider and a short hash; never the store id. */
    id: string;
    provider: BillingProvider;
    productId: string | null;
    status: GrantStatus;
    validUntil: string | null;
    environment: GrantEnvironment;
    autoRenew: boolean | null;
    boundAt: string | null;
    fetchedAt: string | null;
  }>;
  /** Store notifications applied to these accounts, newest first (≤ 20). */
  events: Array<{
    provider: BillingProvider;
    type: string;
    outcome: string | null;
    at: string;
    processedAt: string | null;
  }>;
}
