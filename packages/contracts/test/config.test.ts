import { describe, expect, it } from 'vitest';
import {
  defaultFlags,
  defaultLimits,
  flagKeys,
  flagsSchema,
  isFlagOnForBucket,
  limitsSchema,
} from '../src/index.js';

describe('config contracts', () => {
  it('default flags cover every flag key and validate', () => {
    expect(Object.keys(defaultFlags).sort()).toEqual([...flagKeys].sort());
    expect(flagsSchema.parse(defaultFlags)).toEqual(defaultFlags);
  });

  it('default limits match owner decisions', () => {
    const limits = limitsSchema.parse(defaultLimits);
    expect(limits.familyQuotaBytes).toBe(10 * 1024 ** 3);
    expect(limits.videoMaxDurationSec).toBeNull();
    expect(limits.storageRequestAmountsGb).toEqual([10, 20]);
  });

  it('rejects an empty storage-request amount list', () => {
    expect(() => limitsSchema.parse({ ...defaultLimits, storageRequestAmountsGb: [] })).toThrow();
  });

  it('evaluates rollout scopes', () => {
    const base = { enabled: true, percent: 25, notice: null } as const;
    expect(isFlagOnForBucket({ ...base, enabled: false, scope: 'all' }, 0, true)).toBe(false);
    expect(isFlagOnForBucket({ ...base, scope: 'all' }, 99, false)).toBe(true);
    expect(isFlagOnForBucket({ ...base, scope: 'internal' }, 0, false)).toBe(false);
    expect(isFlagOnForBucket({ ...base, scope: 'internal' }, 0, true)).toBe(true);
    expect(isFlagOnForBucket({ ...base, scope: 'percent' }, 24, false)).toBe(true);
    expect(isFlagOnForBucket({ ...base, scope: 'percent' }, 25, false)).toBe(false);
  });
});
