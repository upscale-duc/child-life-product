import { describe, expect, it } from 'vitest';
import {
  coverageBand,
  coverageWeights,
  levelsForRoles,
  productCoverage,
  productRegistrySchema,
  staffCan,
  type CoverageInput,
} from '../src/index.js';

// Product Hub (D-155): the deterministic coverage score (doc 05 §4) and the `product` function.
const full: CoverageInput = {
  sections: {
    problem: { state: 'approved', stale: false, sources: 1 },
    value: { state: 'approved', stale: false, sources: 1 },
    ux: { state: 'approved', stale: false, sources: 1 },
    rules: { state: 'approved', stale: false, sources: 2 },
    edgeCases: { state: 'approved', stale: false, sources: 1 },
    metrics: { state: 'approved', stale: false, sources: 1 },
  },
  hasTier: true,
  openTierConflict: false,
  moduleCount: 3,
  testCount: 2,
  decisionCount: 4,
  metricsInstrumented: true,
  openConflicts: 0,
};

describe('productCoverage', () => {
  it('weights add up to 100 and a complete feature scores 100', () => {
    expect(Object.values(coverageWeights).reduce((a, b) => a + b, 0)).toBe(100);
    const r = productCoverage(full);
    expect(r.score).toBe(100);
    expect(r.missing).toEqual([]);
  });

  it('an empty feature with only code facts shows what is missing (Scenario F)', () => {
    const r = productCoverage({
      ...full,
      sections: {},
      hasTier: false,
      decisionCount: 0,
      metricsInstrumented: false,
    });
    expect(r.score).toBe(10);
    expect(r.missing).toEqual(['problem', 'value', 'ux', 'rules', 'edgeCases', 'entitlements', 'metrics', 'decisions']);
  });

  it('drafts count 40 %, unsourced rules 60 %, stale approvals half', () => {
    const r = productCoverage({
      ...full,
      sections: {
        ...full.sections,
        problem: { state: 'draft', stale: false, sources: 0 },
        rules: { state: 'approved', stale: false, sources: 0 },
        ux: { state: 'approved', stale: true, sources: 1 },
      },
    });
    const earned = Object.fromEntries(r.dimensions.map((d) => [d.key, d.earned]));
    expect(earned.problem).toBe(4.8);
    expect(earned.rules).toBe(9.6);
    expect(earned.ux).toBe(7);
    expect(r.unverified).toEqual(['problem', 'rules']);
    expect(r.stale).toEqual(['ux']);
  });

  it('an open conflict caps the score at 69 and halves entitlements when it is about the tier', () => {
    const r = productCoverage({ ...full, openConflicts: 1, openTierConflict: true });
    expect(r.capped).toBe(true);
    expect(r.score).toBe(69);
    expect(r.dimensions.find((d) => d.key === 'entitlements')!.state).toBe('conflict');
  });

  it('metrics count fully only when instrumented', () => {
    const r = productCoverage({ ...full, metricsInstrumented: false });
    expect(r.score).toBe(97);
  });

  it('bands', () => {
    expect([coverageBand(10), coverageBand(40), coverageBand(70)]).toEqual(['low', 'mid', 'high']);
  });
});

describe('registry schema', () => {
  const base = {
    name: { vi: 'Cho ăn', en: 'Feeding' },
    pillar: 'care',
    platforms: ['ios'],
    lifecycle: 'built',
    implementation: 'implemented',
    verification: 'code_read',
    release: 'not_released',
    confidence: 'high',
  };
  it('refuses duplicate ids and unknown dependencies', () => {
    expect(
      productRegistrySchema.safeParse({ version: 1, features: [{ ...base, id: 'care.a' }, { ...base, id: 'care.a' }] })
        .success,
    ).toBe(false);
    expect(
      productRegistrySchema.safeParse({ version: 1, features: [{ ...base, id: 'care.a', dependsOn: ['care.b'] }] })
        .success,
    ).toBe(false);
  });
  it('refuses an id outside the pillars', () => {
    expect(productRegistrySchema.safeParse({ version: 1, features: [{ ...base, id: 'misc.a' }] }).success).toBe(false);
  });
});

describe('Sản phẩm staff function (D-155)', () => {
  it('owner and admin approve, engineering edits, analyst and ops view, support has none', () => {
    const can = (role: string, a: Parameters<typeof staffCan>[1]) => staffCan(levelsForRoles([role]), a);
    expect(can('owner', 'product.approve')).toBe(true);
    expect(can('admin', 'product.approve')).toBe(true);
    expect([can('eng', 'product.edit'), can('eng', 'product.approve')]).toEqual([true, false]);
    expect([can('analyst', 'product.view'), can('analyst', 'product.edit')]).toEqual([true, false]);
    expect(can('ops', 'product.view')).toBe(true);
    expect(can('support', 'product.view')).toBe(false);
    expect(can('expert', 'product.view')).toBe(false);
  });
});
