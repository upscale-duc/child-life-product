import { describe, expect, it } from 'vitest';
import { type ProductAnalyticsRequest } from '@child-life/contracts';
import {
  reduceProductAnalytics,
  type ProductAccountRow,
  type ProductFactRow,
} from '../src/product-analytics-reducer.js';
import { analyticsAgeBand } from '../src/product-analytics-store.js';

const request: ProductAnalyticsRequest = {
  schemaVersion: 2,
  section: 'acquisition',
  from: '2026-10-01',
  to: '2026-10-08',
  platform: 'all',
  locale: 'all',
  context: 'all',
  ageBand: 'all',
  chapter: 'all',
  comparison: true,
};
const at = (day: string) => Date.parse(`${day}T10:00:00+07:00`);
const accounts: ProductAccountRow[] = Array.from({ length: 21 }, (_, i) => ({
  uid: `private-user-${i}`,
  registeredAt: at('2026-10-01'),
  registrationVerified: true,
  ageBand: '6_to_9m',
  locale: 'vi',
  creator: true,
  primaryContextAt: at('2026-10-01'),
}));
function fact(i: number, day: string, extra: Partial<ProductFactRow> = {}): ProductFactRow {
  return {
    event: 'app_foreground_observed',
    uid: accounts[i]!.uid,
    familyId: `private-family-${i}`,
    day,
    at: at(day),
    receivedAt: at(day),
    module: null,
    platform: 'ios',
    locale: 'vi',
    context: 'current',
    ageBand: '6_to_9m',
    kind: null,
    stage: null,
    opportunity: null,
    template: null,
    meaningful: false,
    windowClosesAt: null,
    reason: 'none',
    ...extra,
  };
}
const foreground = accounts.map((_, i) => fact(i, '2026-10-02'));
const outcome = accounts.map((_, i) =>
  fact(i, '2026-10-03', { event: 'memory_ready', meaningful: true, module: 'remember' }),
);
function reduce(extra: Partial<Parameters<typeof reduceProductAnalytics>[0]> = {}) {
  return reduceProductAnalytics({
    request,
    facts: [...foreground, ...outcome],
    accounts,
    costs: [],
    credits: null,
    now: new Date('2026-11-10T12:00:00Z'),
    sourceStartAt: new Date('2026-09-01'),
    collectionEnabled: true,
    ...extra,
  });
}

describe('product cohort reducer', () => {
  it('deduplicates user/family windows across platforms and never adds daily unique counts', () => {
    const result = reduce({
      facts: [
        ...foreground,
        ...foreground.map((f) => ({ ...f, platform: 'android' })),
        ...accounts.map((_, i) => fact(i, '2026-10-04')),
        ...outcome,
      ],
    });
    expect(result.metrics.find((m) => m.id === 'A02')?.value).toBe(21);
    expect(result.metrics.find((m) => m.id === 'A03')?.value).toBe(21);
    expect(result.metrics.find((m) => m.id === 'A08')).toMatchObject({
      value: 1,
      numerator: 21,
      denominator: 21,
    });
    expect(JSON.stringify(result)).not.toMatch(/private-user|private-family/);
  });
  it('uses strict D1, D7 and D30 with mature eligible denominators', () => {
    const result = reduce();
    expect(result.metrics.find((m) => m.id === 'A05_1')).toMatchObject({
      value: 1,
      numerator: 21,
      denominator: 21,
    });
    expect(result.metrics.find((m) => m.id === 'A05_7')).toMatchObject({
      value: 0,
      numerator: 0,
      denominator: 21,
    });
    const immature = reduce({ now: new Date('2026-10-12T12:00:00Z') });
    expect(immature.metrics.find((m) => m.id === 'A05_30')).toMatchObject({
      value: null,
      status: 'immature',
    });
  });
  it('does not select the registration denominator by notification permission or activity', () => {
    const active = reduce({ facts: [...foreground.slice(0, 10), ...outcome.slice(0, 5)] });
    expect(active.metrics.find((m) => m.id === 'A08')).toMatchObject({
      numerator: 5,
      denominator: 21,
      value: 5 / 21,
    });
    expect(active.metrics.find((m) => m.id === 'A02')).toMatchObject({
      value: null,
      status: 'insufficient',
    });
  });
  it('withholds small groups and unsupported backend outcome filters', () => {
    const small = reduce({ accounts: accounts.slice(0, 1), facts: foreground.slice(0, 1) });
    expect(small.series.every((p) => p.users === null)).toBe(true);
    expect(small.retention.every((p) => p.users === null && p.d1.denominator === null)).toBe(true);
    const filtered = reduce({ request: { ...request, section: 'memories', platform: 'android' } });
    expect(filtered.metrics.find((m) => m.id === 'M_ready')).toMatchObject({
      value: null,
      reason: 'unsupported_filter',
    });
  });
  it('separates observed usage, unknown usage and rated estimates from actual invoices', () => {
    const result = reduce({
      request: { ...request, section: 'cost' },
      costs: [
        {
          calls: 3,
          knownUsage: 2,
          unknownUsage: 1,
          inputTokens: 100,
          outputTokens: 20,
          cachedInputTokens: 0,
          ratedCalls: 2,
          estimatedCostUsdMicros: 1234,
        },
      ],
    });
    expect(result.metrics.find((m) => m.id === 'C_estimate')?.value).toBe(0.001234);
    expect(result.metrics.find((m) => m.id === 'C_actual')).toMatchObject({
      value: null,
      reason: 'no_source',
    });
    expect(result.metrics.find((m) => m.id === 'C_unknown')?.value).toBe(1);
    expect(result.metrics.find((m) => m.id === 'C_cached')?.value).toBeNull();
    const missing = reduce({
      request: { ...request, section: 'cost' },
      costs: [
        {
          calls: 1,
          knownUsage: 0,
          unknownUsage: 1,
          inputTokens: 0,
          outputTokens: 0,
          cachedInputTokens: 0,
          ratedCalls: 0,
          estimatedCostUsdMicros: 0,
        },
      ],
    });
    expect(missing.metrics.find((m) => m.id === 'C_input')?.value).toBeNull();
    const knownZero = reduce({
      request: { ...request, section: 'cost' },
      costs: [
        {
          calls: 1,
          knownUsage: 1,
          unknownUsage: 0,
          knownCachedUsage: 1,
          inputTokens: 10,
          outputTokens: 2,
          cachedInputTokens: 0,
          ratedCalls: 0,
          estimatedCostUsdMicros: 0,
        },
      ],
    });
    expect(knownZero.metrics.find((m) => m.id === 'C_cached')?.value).toBe(0);
  });
  it('uses calendar months for late-onboarding bands, including end-of-month babies', () => {
    expect(
      analyticsAgeBand('2026-01-31', new Date('2026-02-28T12:00:00Z'), 'Asia/Ho_Chi_Minh'),
    ).toBe('1_to_3m');
    expect(
      analyticsAgeBand('2026-04-01', new Date('2026-10-01T12:00:00Z'), 'Asia/Ho_Chi_Minh'),
    ).toBe('6_to_9m');
    expect(analyticsAgeBand(null, new Date(), 'UTC')).toBe('unknown');
  });
  it('measures completed actions against a mature eligible window, including actions after the selected range', () => {
    const eligible = accounts.map((_, i) =>
      fact(i, '2026-10-02', {
        event: 'engagement_eligible',
        kind: 'ENG-01',
        stage: 'eligible',
        opportunity: `opportunity-${i}`,
        windowClosesAt: at('2026-10-10'),
      }),
    );
    const completed = eligible.map((f) => ({
      ...f,
      event: 'engagement_completed',
      stage: 'completed' as const,
      at: at('2026-10-09'),
      day: '2026-10-09',
    }));
    const result = reduce({
      request: { ...request, section: 'engagement' },
      facts: [...eligible, ...completed],
      now: new Date('2026-10-20'),
    });
    expect(result.engagement[0]?.conversion).toMatchObject({
      value: 1,
      numerator: 21,
      denominator: 21,
    });
    expect(result.engagement[0]?.stages.opened).toBe(0);
    const immature = reduce({
      request: { ...request, section: 'engagement' },
      facts: eligible,
      now: new Date('2026-10-11'),
    });
    expect(immature.engagement[0]?.conversion.status).toBe('immature');
    const expiredHistory = reduce({
      request: { ...request, section: 'engagement' },
      facts: [...eligible, ...completed],
    });
    expect(expiredHistory.engagement[0]?.conversion).toMatchObject({
      value: null,
      reason: 'history_unavailable',
    });
  });
  it('keeps observed-only account metadata out of registration cohorts and counts real family viewing', () => {
    const fallback = reduce({
      accounts: accounts.map((p) => ({ ...p, registrationVerified: false })),
    });
    expect(fallback.metrics.find((m) => m.id === 'A01')?.value).toBeNull();
    const viewer = reduce({
      facts: [
        ...foreground,
        ...accounts.map((_, i) =>
          fact(i, '2026-10-03', {
            event: 'family_content_viewed',
            module: 'family',
          }),
        ),
      ],
    });
    expect(viewer.metrics.find((m) => m.id === 'A08')?.value).toBe(1);
    expect(
      viewer.breakdowns.find((b) => b.dimension === 'module' && b.key === 'family')?.count,
    ).toBe(21);
    const context = reduce({
      facts: [
        ...foreground,
        ...accounts.map((_, i) => fact(i, '2026-10-03', { event: 'family_context_viewed' })),
      ],
    });
    expect(
      context.breakdowns.find((b) => b.dimension === 'module' && b.key === 'family')?.count,
    ).toBeNull();
  });
});

it('Adaptive Experience: people per stage band and per event·detail, only above the threshold', () => {
  const adaptive = accounts.map((_, i) =>
    fact(i, '2026-10-03', {
      event: 'adaptive_widget_opened',
      module: 'personalization',
      template: i < 20 ? 'moment_today' : 'growth',
      stageBand: 'b3_6',
    }),
  );
  const result = reduce({
    request: { ...request, section: 'features' },
    facts: [...foreground, ...adaptive],
  });
  const rows = result.breakdowns.filter((b) => b.dimension === 'adaptive');
  expect(rows).toContainEqual({
    dimension: 'adaptive',
    key: 'widget_opened:moment_today',
    count: 20,
  });
  // The one who opened growth stays hidden (below 20).
  expect(rows.find((b) => b.key === 'widget_opened:growth')).toBeUndefined();
  expect(result.breakdowns).toContainEqual({
    dimension: 'stageBand',
    key: 'b3_6',
    count: accounts.length,
  });
});
