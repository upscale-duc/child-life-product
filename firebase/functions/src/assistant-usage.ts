import type { Firestore } from 'firebase-admin/firestore';
import {
  calendarMonthWindow,
  dayBoundsIn,
  defaultAssistantCreditPolicy,
  freeTrialKey,
  monthlyCycle,
  grantGives,
  isOpenEndedUntil,
  type AssistantCreditPolicy,
  type AssistantUsage,
  type AssistantUsageEntry,
  type EntitlementsConfig,
} from '@child-life/contracts';
import { toDate, type TrustedScope } from './assistant-common.js';
import { flagOn, type EntitlementContext, type FamilyEntitlements } from './entitlements.js';
import { peekQuotaWindow, type QuotaWindowRef, type QuotaWindowRequest } from './quota.js';

/**
 * Assistant credits (P-159, D-075 #1, brief p.17–18): ONE household pool `assistant` in the shared
 * quota ledger (`families/{f}/quota/assistant_*`, multi-unit reservations) for the chat and the
 * AI summaries. The Premium budget applies while a valid grant gives `assistant.premium_budget`
 * (paid, promo or a beta campaign that includes it); a paid or promo grant stored before D-075
 * (templates without the new capability) still counts. Otherwise the Free budget, per calendar
 * month in the household zone.
 *
 * Windows: a paid / promo grant — its paid period (a repeated verified purchase event keeps the
 * same grant id and period, hence the same window: no second pool, M08); a beta grant — the
 * calendar month in the household zone, cut to the grant's validity, keyed by the grant (never
 * the Free window, whose limit is frozen). Limits come from `config/entitlements.quotas.assistant`
 * (QA values, not an offer) and are frozen into each window when it is created.
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

/** What the pool needs: the trusted scope of a chat task, or an AI summary's context. */
export type PoolScope = Pick<TrustedScope, 'familyId' | 'householdZone'> & {
  ctx: EntitlementContext;
};

const sourceRank = { paid: 0, promo: 1, beta: 2 } as const;

/** The grant giving the Premium budget now (paid over promo over beta, then the latest end). */
export function premiumBudgetGrant(ctx: FamilyEntitlements, now: Date) {
  return ctx.grants
    .filter(
      (g) =>
        grantGives(g, 'assistant.premium_budget', ctx.environment, now) ||
        // Paid / promo grants written before D-075 #1 (templates, no budget capability).
        (g.source !== 'beta' && grantGives(g, 'templates.premium', ctx.environment, now)),
    )
    .sort(
      (a, b) =>
        sourceRank[a.source] - sourceRank[b.source] ||
        b.validUntil.getTime() - a.validUntil.getTime(),
    )[0];
}

/**
 * The pool a new task (or AI summary) counts against right now. Never from the client: the plan
 * is read from the stored grants and the open beta campaigns.
 */
export async function assistantPool(
  db: Firestore,
  s: PoolScope,
  now: Date,
): Promise<AssistantPool> {
  const policy = creditPolicy(s.ctx.config);
  const premium = premiumBudgetGrant(s.ctx, now);
  // Premium v2 (D-101): Free has 30 credit once (a window that never resets; v2 starts every
  // family fresh, Q-096); Premium has 200 per monthly cycle on the subscription day, also on a
  // yearly plan (PV40).
  if (flagOn(s.ctx, 'premium_v2')) {
    const plans = s.ctx.config.plans;
    if (!premium) {
      return {
        plan: 'free',
        request: {
          window: { kind: 'trial', feature: 'assistant', key: freeTrialKey },
          limit: plans.free.lumiCreditsOneTime,
        },
        grantId: null,
      };
    }
    const cycle = monthlyCycle(premium.validFrom, now, premium.validUntil);
    return {
      plan: 'premium',
      request: {
        window: {
          kind: 'paid',
          feature: 'assistant',
          grantId: premium.id.replace(/[^A-Za-z0-9_-]/g, '-'),
          periodStart: cycle.start,
          periodEnd: cycle.end,
        },
        limit: plans.premium.lumiCreditsPerCycle,
      },
      grantId: premium.id,
    };
  }
  if (premium && (premium.source === 'beta' || isOpenEndedUntil(premium.validUntil))) {
    // A beta, or "Bật toàn bộ Premium" with no end date (D-089): monthly, in the household
    // zone, inside the grant's validity (one window per month, not one for ever).
    const m = calendarMonthWindow(s.householdZone, now);
    const monthStart = dayBoundsIn(s.householdZone, m.startDate).start;
    const monthEnd = dayBoundsIn(s.householdZone, m.endDate).start;
    const window: QuotaWindowRef = {
      kind: 'paid',
      feature: 'assistant',
      grantId: premium.id.replace(/[^A-Za-z0-9_-]/g, '-'),
      periodStart: new Date(Math.max(monthStart.getTime(), premium.validFrom.getTime())),
      periodEnd: new Date(Math.min(monthEnd.getTime(), premium.validUntil.getTime())),
    };
    return {
      plan: 'premium',
      request: { window, limit: policy.premium.limit },
      grantId: premium.id,
    };
  }
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
  s: PoolScope,
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

/**
 * CH19 "Gần đây": the newest [limit] credit lines of the pool window (ledger ops), with the kind
 * and the asking member's label from the task — never text, drafts or photos. Summary credits
 * (`su_*`, D-075 #1) have no author on the ledger and show without one.
 */
export async function recentUsage(
  db: Firestore,
  familyId: string,
  windowId: string,
  limit = 20,
): Promise<AssistantUsageEntry[]> {
  const ops = await db
    .collection(`families/${familyId}/quotaOps`)
    .where('windowId', '==', windowId)
    .orderBy('reservedAt', 'desc')
    .limit(limit)
    .get();
  // Chat tasks reserve as `assistant_<taskId>` (`reservationIdFor`); summaries as `su_*`.
  const taskIdOf = (opId: string) => (opId.startsWith('assistant_tk_') ? opId.slice(10) : null);
  const taskIds = ops.docs.map((d) => taskIdOf(d.id)).filter((id): id is string => id !== null);
  const tasks = taskIds.length
    ? await db.getAll(...taskIds.map((id) => db.doc(`assistantTasks/${id}`)), {
        fieldMask: ['modality', 'author'],
      })
    : [];
  const byId = new Map(tasks.filter((s) => s.exists).map((s) => [s.id, s]));
  const out: AssistantUsageEntry[] = [];
  for (const d of ops.docs) {
    const at = toDate(d.get('reservedAt'));
    const state = d.get('state') as AssistantUsageEntry['state'];
    if (!at || !['reserved', 'committed', 'released'].includes(state)) continue;
    const taskId = taskIdOf(d.id);
    const task = taskId ? byId.get(taskId) : undefined;
    const author = task?.get('author') as
      { name?: string | null; relationCustom?: string | null } | null | undefined;
    out.push({
      kind: d.id.startsWith('su_')
        ? 'summary'
        : task?.get('modality') === 'image'
          ? 'image'
          : 'text',
      state,
      credits: (d.get('units') as number | undefined) ?? 1,
      at: at.toISOString(),
      who: author?.relationCustom || author?.name || null,
    });
  }
  return out;
}
