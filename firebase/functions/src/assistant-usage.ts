import type { Firestore } from 'firebase-admin/firestore';
import {
  defaultAssistantCreditPolicy,
  grantGives,
  type AssistantCreditPolicy,
  type AssistantUsage,
  type EntitlementsConfig,
} from '@child-life/contracts';
import { toDate, type TrustedScope } from './assistant-common.js';
import { peekQuotaWindow, type QuotaWindowRef, type QuotaWindowRequest } from './quota.js';

/**
 * Assistant credits (P-159, brief p.17–18): one household pool `assistant` in the shared quota
 * ledger (`families/{f}/quota/assistant_*`, multi-unit reservations). Free: calendar month in the
 * household zone. Premium: the paid period of a valid paid or promo grant (the one that makes the
 * household Premium, `householdPlan`); a repeated verified purchase event keeps the same grant id
 * and period, hence the same window (no second pool, M08). Limits come from
 * `config/entitlements.quotas.assistant` (QA values, not an offer) and are frozen into each window
 * when it is created.
 */

export function creditPolicy(config: EntitlementsConfig): AssistantCreditPolicy {
  const q = config.quotas.assistant;
  return {
    policyVersion: `${defaultAssistantCreditPolicy.policyVersion}/${config.policyVersion}`.slice(
      0,
      40,
    ),
    textCredits: q.textCredits,
    imageCredits: q.imageCredits,
    free: { limit: q.free },
    premium: { limit: q.premium },
  };
}

export interface AssistantPool {
  plan: 'free' | 'premium';
  request: QuotaWindowRequest;
  grantId: string | null;
}

/**
 * The pool a new task counts against right now. Never from the client: the plan is read from the
 * stored grants (paid / promo, valid in this environment, giving the Premium capabilities).
 */
export async function assistantPool(
  db: Firestore,
  s: TrustedScope,
  now: Date,
): Promise<AssistantPool> {
  const policy = creditPolicy(s.ctx.config);
  const premium = s.ctx.grants
    .filter(
      (g) => g.source !== 'beta' && grantGives(g, 'templates.premium', s.ctx.environment, now),
    )
    .sort((a, b) => b.validUntil.getTime() - a.validUntil.getTime())[0];
  if (premium) {
    const stored = await db.doc(`families/${s.familyId}/grants/${premium.id}`).get();
    const periodStart = toDate(stored.get('periodStart'));
    const start =
      periodStart && periodStart.getTime() <= now.getTime() ? periodStart : premium.validFrom;
    const window: QuotaWindowRef = {
      kind: 'paid',
      feature: 'assistant',
      grantId: premium.id,
      periodStart: start,
      periodEnd: premium.validUntil,
    };
    return {
      plan: 'premium',
      request: { window, limit: policy.premium.limit },
      grantId: premium.id,
    };
  }
  return {
    plan: 'free',
    request: {
      window: { kind: 'calendar_month', feature: 'assistant', zone: s.householdZone },
      limit: policy.free.limit,
    },
    grantId: null,
  };
}

/** CH19 "Mức dùng": the household pool now (an unused window reads as empty). */
export async function assistantUsage(
  db: Firestore,
  s: TrustedScope,
  now: Date,
  pool?: AssistantPool,
): Promise<AssistantUsage & { windowId: string }> {
  const p = pool ?? (await assistantPool(db, s, now));
  const policy = creditPolicy(s.ctx.config);
  const w = await peekQuotaWindow(db, s.familyId, p.request, now);
  return {
    plan: p.plan,
    limit: w.window.limit,
    used: w.window.used,
    reserved: w.window.reserved,
    remaining: Math.max(0, w.window.limit - w.window.used - w.window.reserved),
    resetsAt: w.window.resetsAt.toISOString(),
    policyVersion: policy.policyVersion,
    textCredits: policy.textCredits,
    imageCredits: policy.imageCredits,
    windowId: w.windowId,
  };
}
