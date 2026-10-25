import { z } from 'zod';
import type { GateReason } from './entitlements.js';
import type { QuotaSnapshot } from './quota.js';

/**
 * Grounded AI (brief p.14, plan §5.5): a handover for the next carer (SU01 / NL10), an explanation
 * of one suggestion, and a nudge to keep a confirmed milestone. The model may only reword facts
 * the engine produced and pick a suggestion from approved candidates; every number comes from the
 * engine. Anything else falls back to the free template summary built from the same facts.
 */

export const aiSummaryKinds = ['handover', 'explain', 'moment'] as const;
export type AiSummaryKind = (typeof aiSummaryKinds)[number];

/** Bumped when the consent text changes; older consents no longer count (brief p.14). */
export const aiConsentVersion = 'ai-consent-v1';

/**
 * Assistant chat consent (P-160): messages, photos and the context read for a task go to the AI
 * provider. Separate from summaries; stored as `assistant` on `users/{uid}/settings/ai`.
 */
export const assistantConsentVersion = 'assistant-consent-v1';

/**
 * `users/{uid}/settings/ai`: per person; a household's Premium never replaces it. Notes written
 * by someone else are sent only when that person's own consent allows it (`shareMyNotes`).
 */
export const aiConsentSchema = z.object({
  consent: z
    .object({
      version: z.string().min(1).max(40),
      grantedAt: z.string(),
      /** Let my own free-text notes be included when someone in the family asks for a summary. */
      shareMyNotes: z.boolean(),
    })
    .nullable(),
  updatedAt: z.string().nullable(),
  assistant: z
    .object({ version: z.string().min(1).max(40), grantedAt: z.string() })
    .nullable()
    .optional(),
});
export type AiConsent = z.infer<typeof aiConsentSchema>;

/** One fact the engine extracted; the only thing a summary may talk about. */
export interface SummaryFact {
  /** `ci_…` check-in, `fb_…` feedback, `ms_…` milestone, `sleep` comparison. */
  id: string;
  kind: 'checkin' | 'feedback' | 'milestone' | 'sleep';
  date: string;
  authorUid: string | null;
  /** Short engine-written line (template), e.g. "Khó vào giấc · giấc đêm · 2–3 ngày". */
  text: string;
}

export const summarySectionKinds = ['noticed', 'helped', 'next', 'note'] as const;

/** What the model must return (JSON schema mode). */
export const aiOutputSchema = z
  .object({
    sections: z
      .array(
        z.object({
          kind: z.enum(summarySectionKinds),
          text: z.string().min(1).max(600),
          factIds: z.array(z.string().min(1).max(60)).max(12),
        }),
      )
      .min(1)
      .max(6),
    suggestionContentId: z.string().max(60).nullable(),
    language: z.enum(['vi', 'en']),
  })
  .strict();
export type AiOutput = z.infer<typeof aiOutputSchema>;

export type AiGateResult = 'AI_VALID' | 'FALLBACK' | 'CACHE' | 'HEALTH_FLOW';

export interface AiGateInput {
  entitled: boolean;
  consent: boolean;
  healthFlag: boolean;
  cached: boolean;
  schemaValid: boolean;
  timeout: boolean;
  locale: string;
  outputLocale: string;
  allowedFacts: readonly string[];
  outputFactIds: readonly string[];
  allowedContent: readonly string[];
  suggestionId: string | null;
}

/**
 * A01–A08: health first (no model at all), then entitlement + consent, cache, then the output
 * checks (time, schema, language, fact ids within the snapshot, suggestion within the approved
 * candidates). ID checks do not prove the sentences are right: a human audit is still required.
 */
export function aiGate(x: AiGateInput): AiGateResult {
  if (x.healthFlag) return 'HEALTH_FLOW';
  if (!x.entitled || !x.consent) return 'FALLBACK';
  if (x.cached) return 'CACHE';
  if (x.timeout || !x.schemaValid || x.outputLocale !== x.locale) return 'FALLBACK';
  const facts = new Set(x.allowedFacts);
  if (!x.outputFactIds.every((f) => facts.has(f))) return 'FALLBACK';
  if (x.suggestionId !== null && !x.allowedContent.includes(x.suggestionId)) return 'FALLBACK';
  return 'AI_VALID';
}

/** Claims a summary must never make (brief p.6, p.14); checked on every section before use. */
export const forbiddenClaimPatterns: readonly RegExp[] = [
  /không (có gì )?đáng lo/iu,
  /\bnothing to worry\b/i,
  /\b(definitely|certainly|guaranteed?)\b/i,
  /chắc chắn/iu,
  /\b(because of|caused by|due to) (the )?(leap|wonder week)/i,
  /(do|vì) (giai đoạn|wonder week|bước nhảy)/iu,
  /\bdiagnos/i,
  /chẩn đoán (là|bé bị)/iu,
];

export function claimProblems(output: AiOutput): string[] {
  const out: string[] = [];
  for (const s of output.sections) {
    for (const p of forbiddenClaimPatterns) if (p.test(s.text)) out.push(p.source);
    // Any digit in a sentence must come from a fact (numbers belong to the engine).
    if (/\d/u.test(s.text) && s.factIds.length === 0) out.push('number-without-fact');
  }
  return out;
}

/** Cache key (brief p.14): same facts in another language never answer from this one. */
export function aiCacheKey(k: {
  babyId: string;
  kind: AiSummaryKind;
  dataVersion: number;
  contentVersion: string;
  locale: 'vi' | 'en';
  promptVersion: string;
  model: string;
  consentVersion: string;
}): string {
  return [
    k.babyId,
    k.kind,
    `d${k.dataVersion}`,
    k.contentVersion,
    k.locale,
    k.promptVersion,
    k.model,
    k.consentVersion,
  ].join('|');
}

export const generateSummaryRequestSchema = z.object({
  babyId: z.string().min(1).max(128),
  kind: z.enum(aiSummaryKinds),
  locale: z.enum(['vi', 'en']),
  /** Idempotency: retrying with the same id returns the same snapshot, one quota use at most. */
  requestId: z.uuid(),
  /** `explain`: the recommendation to explain. */
  recommendationId: z.string().max(80).optional(),
  /** `moment`: the confirmed milestone. */
  milestoneId: z.string().max(80).optional(),
});

export const setAiConsentRequestSchema = z.object({
  /** null withdraws consent: queued work stops, cached AI summaries are deleted. */
  consent: z.object({ version: z.string().min(1).max(40), shareMyNotes: z.boolean() }).nullable(),
});

export const reportSummaryRequestSchema = z.object({
  babyId: z.string().min(1).max(128),
  summaryId: z.string().min(1).max(80),
  /** "Chưa đúng? Báo lại": what was wrong, chosen, never free text about the child. */
  problem: z.enum(['wrong_fact', 'wrong_person', 'unsafe_advice', 'language', 'other']),
});

/**
 * D-093 "Gửi cho Jun": send one stored handover to one family member, in the app (a push and an
 * inbox row with no child data). Idempotent per summary and recipient.
 */
export const sendHandoverRequestSchema = z
  .object({
    babyId: z.string().min(1).max(128),
    summaryId: z.string().regex(/^su_[a-f0-9]{32}$/),
    recipientUid: z.string().min(1).max(128),
    /** Owner, 2026-10-25: the sender's own words for the next person (never logged or pushed). */
    note: z.string().trim().max(300).nullish(),
  })
  .strict();

/** The recipient opened the handover (`seen`) or tapped "Tôi đã nhận bàn giao" (`received`). */
export const markHandoverRequestSchema = z
  .object({
    babyId: z.string().min(1).max(128),
    sendId: z.string().regex(/^hs_[a-f0-9]{32}$/),
    action: z.enum(['seen', 'received']),
  })
  .strict();

/** `babies/{b}/handoverSends/{id}`: read by its sender and its recipient only. */
export interface HandoverSend {
  id: string;
  babyId: string;
  summaryId: string;
  senderUid: string;
  recipientUid: string;
  /** ISO instants. */
  sentAt: string;
  seenAt: string | null;
  receivedAt: string | null;
}

export interface SummaryAnswer {
  id: string;
  kind: AiSummaryKind;
  /** `ai` (validated model output), `cache`, or `fallback` (template; free, no quota used). */
  method: 'ai' | 'cache' | 'fallback';
  /** Why the template was used: CONSENT_REQUIRED, PREMIUM_REQUIRED, QUOTA_EXCEEDED, FEATURE_DISABLED,
   * HEALTH_FLOW (health signs in the range: no model, point to health support), or the technical
   * `timeout` / `invalid` / `unavailable`. */
  fallbackReason: SummaryFallbackReason | null;
  sections: { kind: (typeof summarySectionKinds)[number]; text: string; factIds: string[] }[];
  facts: SummaryFact[];
  suggestionContentId: string | null;
  range: { from: string; to: string };
  authorUids: string[];
  language: 'vi' | 'en';
  generatedAt: string;
  dataVersion: number;
  /**
   * The credit window after this answer, for older apps: `month` is the household's assistant
   * pool window (D-075 #1), `day` is always null now. Summaries stored before D-075 carry the old
   * `ai_day` / `ai_month` pair. Null when no credit was involved (cache, template before credits).
   */
  quota: { day: QuotaSnapshot | null; month: QuotaSnapshot } | null;
  /** D-075 #1: the assistant credit pool after this answer (null when no credit was involved). */
  credits?: SummaryCredits | null;
}

/** D-075 #1: one generated summary costs this many assistant credits (cache and template: 0). */
export const aiSummaryCredits = 1;

/** The household assistant pool as a summary answer shows it ("Còn 12 lượt"). */
export interface SummaryCredits {
  pool: 'assistant';
  plan: 'free' | 'premium';
  /** Credits this answer used (0 for cache / template). */
  charged: number;
  limit: number;
  used: number;
  reserved: number;
  remaining: number;
  /** Exclusive end of the window (ISO instant). */
  resetsAt: string;
}

/** Why a summary is the template (`SummaryAnswer.fallbackReason`). */
export type SummaryFallbackReason =
  GateReason | 'HEALTH_FLOW' | 'timeout' | 'invalid' | 'unavailable';

/** Server pipeline settings (plan §5.5); credits live in `config/entitlements.quotas.assistant`
 * (D-075 #1; `quotas.ai` is legacy). */
export const aiSummaryLimits = {
  /** Facts come from the last N baby-local days, today included (brief "3–7 ngày"). */
  rangeDays: 7,
  maxFacts: 30,
  /** Approved activities offered to the model as the only possible suggestions. */
  maxCandidates: 12,
  /** The model call is abandoned after this; the template answers (A05). */
  timeoutMs: 20_000,
  /** Budget charge per model call (A09 budget in `config/ai`). */
  costVnd: 150,
} as const;

/** Bumped with any change to the summary prompt; part of the cache key. */
export const aiSummaryPromptVersion = 'summary-prompt-v1';

/** A stored summary as read back (SU01 history): `stale` when the facts changed since. */
export interface SummaryView extends SummaryAnswer {
  /** Who asked for it (history: "Mẹ đã tạo"). */
  requestedBy: string;
  stale: boolean;
}

export const listSummariesRequestSchema = z.object({
  babyId: z.string().min(1).max(128),
  kind: z.enum(aiSummaryKinds).optional(),
  limit: z.number().int().min(1).max(20).default(5),
});
