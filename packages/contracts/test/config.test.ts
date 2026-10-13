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

  it('a stored document written before a flag existed still parses, the new flag off', () => {
    const older: Partial<typeof defaultFlags> = { ...defaultFlags };
    delete older.auto_save;
    const live = { ...older, media_upload: { ...older.media_upload, enabled: true } };
    const parsed = flagsSchema.parse(live);
    expect(parsed.media_upload.enabled).toBe(true);
    expect(parsed.auto_save).toEqual(defaultFlags.auto_save);
    // Each parse gets its own copy of the default.
    parsed.auto_save.enabled = true;
    expect(flagsSchema.parse(live).auto_save.enabled).toBe(false);
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
