import {
  analyticsAgeBands,
  analyticsModules,
  engagementKinds,
  engagementStages,
  productAnalyticsSections,
} from '@child-life/contracts';
import { reduceProductAnalytics, type ProductFactRow } from './product-analytics-reducer.js';

/**
 * Which analytics metrics the code can compute (D-155, Phase 4 before launch). The reducer is fed
 * a synthetic, dense data set — 25 verified users, one fact of every event name the reducer
 * itself refers to, every engagement kind and stage with matured windows, cost rows and credits —
 * so a metric still answering "not_instrumented" or "no_source" has no producer in code, whatever
 * data arrives. Empty input cannot tell that apart from "no data yet". Never usage numbers.
 */
export function metricProbe(reducerSource: string, now: Date): Record<string, string> {
  const events = [...new Set([...reducerSource.matchAll(/'([a-z]+(?:_[a-z]+)+)'/g)].map((m) => m[1]!))];
  const day = (d: Date) => d.toISOString().slice(0, 10);
  const DAY = 86_400_000;
  const facts: ProductFactRow[] = [];
  for (let u = 0; u < 25; u++) {
    for (let d = 3; d < 20; d += 4) {
      const at = now.getTime() - d * DAY;
      const base = {
        day: day(new Date(at)),
        at,
        receivedAt: at,
        uid: `u${u}`,
        familyId: `f${u}`,
        platform: 'ios',
        locale: 'vi',
        context: 'current' as const,
        ageBand: analyticsAgeBands[0],
        template: 't1',
        meaningful: true,
        reason: 'none' as const,
        windowClosesAt: null,
        kind: null,
        stage: null,
        opportunity: null,
      };
      for (const event of events) for (const module of analyticsModules) facts.push({ ...base, event, module });
      for (const kind of engagementKinds) {
        for (const stage of engagementStages) {
          facts.push({ ...base, event: 'engagement_stage', module: null, kind, stage, opportunity: `o${u}${kind}${d}`, windowClosesAt: at - 5 * DAY });
        }
      }
    }
  }
  const accounts = Array.from({ length: 25 }, (_, u) => ({
    uid: `u${u}`,
    registeredAt: now.getTime() - 25 * DAY,
    registrationVerified: true,
    ageBand: analyticsAgeBands[0],
    locale: 'vi',
    primaryContextAt: now.getTime() - 24 * DAY,
    creator: true,
  }));
  const costs = [
    { calls: 10, knownUsage: 10, unknownUsage: 0, inputTokens: 1000, outputTokens: 100, cachedInputTokens: 10, knownCachedUsage: 10, ratedCalls: 10, estimatedCostUsdMicros: 5000 },
  ];
  const out: Record<string, string> = {};
  for (const section of productAnalyticsSections) {
    const r = reduceProductAnalytics({
      request: {
        schemaVersion: 2,
        section,
        from: day(new Date(now.getTime() - 25 * DAY)),
        to: day(new Date(now.getTime() - 3 * DAY)),
        platform: 'all',
        locale: 'all',
        ageBand: 'all',
        context: 'all',
        chapter: 'all',
        comparison: true,
      },
      facts,
      accounts,
      costs,
      credits: 10,
      now,
      sourceStartAt: new Date(now.getTime() - 60 * DAY),
      collectionEnabled: true,
    });
    for (const m of r.metrics) out[m.id] = `${m.status}/${m.reason}`;
  }
  return out;
}
