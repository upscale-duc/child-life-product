import { describe, expect, it } from 'vitest';
import {
  analyticsObservationSchema,
  productAnalyticsRequestSchema,
  flagsSchema,
} from '../src/index.js';

const observation = {
  schemaVersion: 1,
  ownerUid: 'owner',
  receiptId: '71971221-6436-4ec3-b0fe-d279090a41a6',
  occurredAt: '2026-10-20T03:00:00.000Z',
  event: 'app_foreground_observed',
  platform: 'ios',
  locale: 'vi',
};
const query = { schemaVersion: 2, section: 'overview', from: '2026-10-01', to: '2026-10-20' };

describe('MET-01 analytics privacy and versioned contracts', () => {
  it('accepts observations but refuses invented server completions and private content', () => {
    expect(analyticsObservationSchema.safeParse(observation).success).toBe(true);
    for (const event of ['memory_ready', 'engagement_completed', 'registration_completed'])
      expect(analyticsObservationSchema.safeParse({ ...observation, event }).success).toBe(false);
    for (const key of [
      'babyName',
      'photoKitId',
      'caption',
      'birthDate',
      'chat',
      'token',
      'inputTokens',
    ])
      expect(
        analyticsObservationSchema.safeParse({ ...observation, [key]: 'private' }).success,
      ).toBe(false);
  });
  it('refuses invalid dates, unbounded and arbitrary queries, including deferred billing', () => {
    expect(productAnalyticsRequestSchema.safeParse(query).success).toBe(true);
    for (const change of [
      { from: '2026-02-30' },
      { to: '2025-01-01' },
      { section: 'billing' },
      { plan: 'pro' },
      { familyId: 'private' },
      { groupBy: 'babyName' },
      { to: '2028-01-01' },
    ])
      expect(productAnalyticsRequestSchema.safeParse({ ...query, ...change }).success).toBe(false);
  });
  it('adds a dark collection kill switch without breaking older flags', () => {
    const flags = flagsSchema.parse({});
    expect(flags.product_analytics.enabled).toBe(false);
    expect(flags.media_upload.enabled).toBe(false);
  });
});
