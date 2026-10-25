import { describe, expect, it } from 'vitest';
import {
  adjustUsageSchema,
  adjustmentApprovalThreshold,
  chooseWriteSeatsRequestSchema,
  decideProposalSchema,
  proposePlansSchema,
  refundVideoJobSchema,
  defaultEntitlementsConfig,
  defaultPremiumPlans,
  entitlementsConfigSchema,
  entryCard,
  GB,
  monthlyCycle,
  planLimits,
  premiumEntries,
  quotaWindowId,
  seatAvailable,
} from '../src/index.js';

describe('Premium v2 plans (PV00, D-101)', () => {
  it('ships the PV00 values and an older config still parses with them', () => {
    expect(defaultPremiumPlans.free).toEqual({
      lumiCreditsOneTime: 30,
      videoExportsTrial: 2,
      storageGB: 1,
      caregiverSeats: 3,
    });
    expect(defaultPremiumPlans.premium.lumiCreditsPerCycle).toBe(200);
    expect(defaultPremiumPlans.premium.price.vn).toEqual({ month: 59000, year: 599000 });
    const older = { ...defaultEntitlementsConfig } as Record<string, unknown>;
    delete older.plans;
    expect(entitlementsConfigSchema.parse(older).plans).toEqual(defaultPremiumPlans);
  });

  it('credit is never sold', () => {
    const plans = { ...defaultPremiumPlans, creditTopUps: true };
    expect(
      entitlementsConfigSchema.safeParse({ ...defaultEntitlementsConfig, plans }).success,
    ).toBe(false);
  });

  it('limits per plan: Free once, Premium monthly, storage with add-on and staff extra', () => {
    const free = planLimits(defaultPremiumPlans, false, { extraBytes: 0 });
    expect(free).toMatchObject({
      plan: 'free',
      lumi: { limit: 30, refill: 'once' },
      video: { limit: 2, refill: 'once' },
      storageBytes: GB,
      caregiverSeats: 3,
      premiumTemplates: false,
    });
    const premium = planLimits(defaultPremiumPlans, true, { addOnGb: 20, extraBytes: GB });
    expect(premium.storageBytes).toBe(31 * GB);
    expect(premium.caregiverSeats).toBe(6);
    expect(premium.lumi).toEqual({ limit: 200, refill: 'monthly' });
  });

  it('a monthly cycle follows the subscription day, also on a yearly plan', () => {
    const anchor = new Date('2026-10-24T08:00:00Z');
    const year = new Date('2027-10-24T08:00:00Z');
    expect(monthlyCycle(anchor, new Date('2026-11-30T00:00:00Z'), year)).toEqual({
      start: new Date('2026-11-24T08:00:00Z'),
      end: new Date('2026-12-24T08:00:00Z'),
    });
    // The last cycle ends with the plan.
    expect(monthlyCycle(anchor, new Date('2027-10-01T00:00:00Z'), year).end).toEqual(
      new Date('2027-10-24T08:00:00Z'),
    );
    // A 31st clamps to shorter months.
    const jan31 = new Date('2027-01-31T00:00:00Z');
    expect(
      monthlyCycle(jan31, new Date('2027-03-01T00:00:00Z'), new Date('2028-01-31Z')).start,
    ).toEqual(new Date('2027-02-28T00:00:00Z'));
  });

  it('seats: a new writer only while below the limit (existing ones stay, Q-097)', () => {
    expect(seatAvailable(2, 3)).toBe(true);
    expect(seatAvailable(3, 3)).toBe(false);
    expect(seatAvailable(5, 3)).toBe(false);
  });

  it('every entry opens a card, E07 none, storage entries split by plan', () => {
    expect(premiumEntries.every((e) => e in entryCard)).toBe(true);
    expect(entryCard.E07).toBeNull();
    expect(entryCard.E08).toBe('addOn');
    expect(entryCard.E10).toBe('storage');
  });

  it('the Free trial has its own window, so v2 starts every family fresh (Q-096)', () => {
    expect(quotaWindowId('assistant', { kind: 'trial', key: 'v2' })).toBe('assistant_trial_v2');
    expect(quotaWindowId('video', { kind: 'trial', key: 'v2' })).toBe('video_trial_v2');
  });
});

describe('portal requests (PT02–PT04, D-101)', () => {
  it('a plans version needs a name and valid values; no reason is required (D-090)', () => {
    expect(
      proposePlansSchema.safeParse({ version: '2.1', plans: defaultPremiumPlans }).success,
    ).toBe(true);
    expect(
      proposePlansSchema.safeParse({ version: ' bad', plans: defaultPremiumPlans }).success,
    ).toBe(false);
    expect(
      proposePlansSchema.safeParse({
        version: '2.1',
        plans: { ...defaultPremiumPlans, creditTopUps: true },
      }).success,
    ).toBe(false);
  });

  it('an adjustment is never zero; refunds name the Render ops job code', () => {
    expect(
      adjustUsageSchema.safeParse({ code: 'F-7Q2K', feature: 'lumi', amount: 0 }).success,
    ).toBe(false);
    expect(
      adjustUsageSchema.safeParse({ code: 'F-7Q2K', feature: 'video', amount: -3 }).success,
    ).toBe(true);
    expect(adjustmentApprovalThreshold).toBe(50);
    expect(refundVideoJobSchema.safeParse({ code: 'F-7Q2K', job: 'KJ-1A2B' }).success).toBe(true);
    expect(refundVideoJobSchema.safeParse({ code: 'F-7Q2K', job: 'job_1' }).success).toBe(false);
    expect(decideProposalSchema.safeParse({ id: 'pp_Ab-_1234', approve: true }).success).toBe(true);
  });

  it('the seat picker lists who keeps writing', () => {
    expect(chooseWriteSeatsRequestSchema.safeParse({ babyId: 'b1', keep: ['u1'] }).success).toBe(
      true,
    );
    expect(chooseWriteSeatsRequestSchema.safeParse({ babyId: 'b1' }).success).toBe(false);
  });
});
