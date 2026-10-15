import { describe, expect, it } from 'vitest';
import {
  aiCacheKey,
  aiGate,
  aiOutputSchema,
  applyQuotaOp,
  calendarMonthWindow,
  claimProblems,
  normalizeApple,
  normalizeGoogle,
  quotaInvariantHolds,
  quotaWindowId,
  type AiGateInput,
  type QuotaOp,
  type QuotaWindow,
  type ReservationState,
} from '../src/index.js';
import pack from './vectors/premium-v2.json' with { type: 'json' };

/** Fixture pack v2.0 (`qa-policy-v2`, synthetic): quota Q01–Q04 and AI gate A01–A08. */
type Case = { id: string; kind: string; input: Record<string, unknown>; expected: unknown };
const cases = (kind: string) => (pack.cases as Case[]).filter((c) => c.kind === kind);

describe('fixture pack · quota Q01–Q04 (sequential; concurrency is proven on dev)', () => {
  it.each(cases('quota').map((c) => [c.id, c] as const))('%s', (_id, c) => {
    const x = c.input as { limit: number; operations: [string, string][] };
    let window: QuotaWindow = { limit: x.limit, used: 0, reserved: 0 };
    const jobs = new Map<string, ReservationState>();
    let denied = 0;
    const op: Record<string, QuotaOp> = { reserve: 'reserve', success: 'commit', fail: 'release' };
    for (const [name, id] of x.operations) {
      const r = applyQuotaOp(window, jobs.get(id), op[name]!);
      window = r.window;
      if (r.state) jobs.set(id, r.state);
      if (r.outcome === 'denied') denied += 1;
      expect(quotaInvariantHolds(window)).toBe(true);
    }
    expect({
      used: window.used,
      reserved: window.reserved,
      accepted_jobs: [...jobs.keys()],
      denied,
    }).toEqual(c.expected);
  });
});

describe('fixture pack · AI gate A01–A08', () => {
  it.each(cases('ai_gate').map((c) => [c.id, c] as const))('%s', (_id, c) => {
    const x = c.input as Record<string, unknown>;
    const input: AiGateInput = {
      entitled: x.entitled as boolean,
      consent: x.consent as boolean,
      healthFlag: x.health_flag as boolean,
      cached: x.cached as boolean,
      schemaValid: x.schema_valid as boolean,
      timeout: x.timeout as boolean,
      locale: x.locale as string,
      outputLocale: x.output_locale as string,
      allowedFacts: x.allowed_facts as string[],
      outputFactIds: x.output_fact_ids as string[],
      allowedContent: x.allowed_content as string[],
      suggestionId: x.suggestion_id as string,
    };
    expect(aiGate(input)).toBe(c.expected);
  });
});

describe('AI output checks', () => {
  const ok = {
    sections: [
      { kind: 'noticed' as const, text: 'Teddy khó vào giấc đêm 2–3 ngày.', factIds: ['ci_a'] },
    ],
    suggestionContentId: null,
    language: 'vi' as const,
  };
  it('schema is strict and claims are screened', () => {
    expect(aiOutputSchema.safeParse(ok).success).toBe(true);
    expect(aiOutputSchema.safeParse({ ...ok, extra: 1 }).success).toBe(false);
    expect(claimProblems(ok)).toEqual([]);
    expect(
      claimProblems({
        ...ok,
        sections: [
          {
            kind: 'note',
            text: 'Con không có gì đáng lo, chắc chắn do giai đoạn.',
            factIds: ['ci_a'],
          },
        ],
      }).length,
    ).toBeGreaterThanOrEqual(2);
    expect(
      claimProblems({ ...ok, sections: [{ kind: 'note', text: 'Con ngủ 11 giờ.', factIds: [] }] }),
    ).toEqual(['number-without-fact']);
  });
  it('the cache key changes with language, facts and consent', () => {
    const k = {
      babyId: 'b',
      kind: 'handover' as const,
      dataVersion: 3,
      contentVersion: 'rc_1',
      locale: 'vi' as const,
      promptVersion: 'p1',
      model: 'm',
      consentVersion: 'c1',
    };
    expect(aiCacheKey(k)).not.toBe(aiCacheKey({ ...k, locale: 'en' }));
    expect(aiCacheKey(k)).not.toBe(aiCacheKey({ ...k, dataVersion: 4 }));
    expect(aiCacheKey(k)).not.toBe(aiCacheKey({ ...k, consentVersion: 'c2' }));
  });
});

describe('quota windows', () => {
  it('calendar month in the household zone, not the server clock', () => {
    // 31 Oct 18:00 UTC is already 1 Nov in Hồ Chí Minh.
    expect(calendarMonthWindow('Asia/Ho_Chi_Minh', new Date('2026-10-31T18:00:00Z'))).toEqual({
      key: '2026-11',
      startDate: '2026-11-01',
      endDate: '2026-12-01',
    });
    expect(calendarMonthWindow('America/New_York', new Date('2026-12-31T23:00:00Z')).endDate).toBe(
      '2027-01-01',
    );
    expect(quotaWindowId('video', { kind: 'calendar', key: '2026-10' })).toBe('video_cal_2026-10');
    expect(
      quotaWindowId('video', {
        kind: 'paid',
        grantId: 'paid_x',
        periodStart: '2026-10-01T00:00:00Z',
      }),
    ).toBe('video_paid_paid_x_2026-10-01');
  });
});

describe('billing normalisation (M05, M07, M08)', () => {
  const now = new Date('2026-10-14T00:00:00Z');
  it('Apple: active, grace until its end, retry without grace is on hold, revoked, sandbox = test', () => {
    const t = {
      originalTransactionId: '2000000000000001',
      productId: 'premium.monthly',
      expiresDate: Date.parse('2026-11-01T00:00:00Z'),
      appAccountToken: 'b9c0b2a4-1111-4c3c-9a6e-000000000001',
      environment: 'Sandbox' as const,
    };
    expect(
      normalizeApple({ status: 1, transaction: t, renewal: { autoRenewStatus: 0 } }),
    ).toMatchObject({
      status: 'active',
      autoRenew: false,
      environment: 'test',
      accountToken: t.appAccountToken,
    });
    expect(
      normalizeApple({
        status: 4,
        transaction: t,
        renewal: { gracePeriodExpiresDate: Date.parse('2026-11-17T00:00:00Z') },
      }).validUntil,
    ).toEqual(new Date('2026-11-17T00:00:00Z'));
    expect(normalizeApple({ status: 3, transaction: t }).status).toBe('on_hold');
    expect(normalizeApple({ status: 1, transaction: { ...t, revocationDate: 1 } }).status).toBe(
      'revoked',
    );
    expect(
      normalizeApple({ status: 2, transaction: { ...t, environment: 'Production' } }),
    ).toMatchObject({
      status: 'expired',
      environment: 'production',
    });
  });

  it('Google: cancelled keeps access until expiry, pending grants nothing, test purchases are test', () => {
    const base = {
      lineItems: [{ productId: 'premium_monthly', expiryTime: '2026-11-01T00:00:00Z' }],
      acknowledgementState: 'ACKNOWLEDGEMENT_STATE_PENDING' as const,
      externalAccountIdentifiers: { obfuscatedExternalAccountId: 'intent-1' },
    };
    expect(
      normalizeGoogle({ ...base, subscriptionState: 'SUBSCRIPTION_STATE_CANCELED' }, 'tok', now),
    ).toMatchObject({
      status: 'active',
      autoRenew: false,
      environment: 'production',
      needsAcknowledge: true,
      accountToken: 'intent-1',
    });
    expect(
      normalizeGoogle(
        { ...base, subscriptionState: 'SUBSCRIPTION_STATE_CANCELED' },
        'tok',
        new Date('2026-11-02T00:00:00Z'),
      ).status,
    ).toBe('expired');
    expect(
      normalizeGoogle({ ...base, subscriptionState: 'SUBSCRIPTION_STATE_PENDING' }, 'tok', now),
    ).toMatchObject({ status: 'pending', needsAcknowledge: false });
    expect(
      normalizeGoogle(
        { ...base, subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE', testPurchase: {} },
        'tok',
        now,
      ).environment,
    ).toBe('test');
    expect(
      normalizeGoogle(
        { ...base, subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE', linkedPurchaseToken: 'root' },
        'tok',
        now,
      ).originalId,
    ).toBe('root');
  });
});

describe('multi-unit reservations (assistant credits: text 1, image 3)', () => {
  it('reserves, commits and releases the same units; an image does not fit 2 left', () => {
    const w = { limit: 20, used: 18, reserved: 0 };
    expect(applyQuotaOp(w, undefined, 'reserve', 3).outcome).toBe('denied');
    const r = applyQuotaOp(w, undefined, 'reserve', 2);
    expect(r.window).toEqual({ limit: 20, used: 18, reserved: 2 });
    expect(applyQuotaOp(r.window, 'reserved', 'commit', 2).window).toEqual({
      limit: 20,
      used: 20,
      reserved: 0,
    });
    expect(applyQuotaOp(r.window, 'reserved', 'release', 2).window).toEqual({
      limit: 20,
      used: 18,
      reserved: 0,
    });
  });
  it('a 0-credit task (health support) is allowed even with nothing left', () => {
    expect(applyQuotaOp({ limit: 0, used: 0, reserved: 0 }, undefined, 'reserve', 0).outcome).toBe(
      'reserved',
    );
    expect(() =>
      applyQuotaOp({ limit: 1, used: 0, reserved: 0 }, undefined, 'reserve', -1),
    ).toThrow();
  });
});
