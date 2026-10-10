import { defaultFlags, defaultLimits } from '@child-life/contracts';
import { describe, expect, it } from 'vitest';
import { isMirroredConfigId, publicProjection } from '../src/config-mirror.js';

describe('publicProjection', () => {
  it('only mirrors flags and limits', () => {
    expect(isMirroredConfigId('flags')).toBe(true);
    expect(isMirroredConfigId('limits')).toBe(true);
    expect(isMirroredConfigId('secrets')).toBe(false);
  });

  it('passes valid documents and blocks invalid ones', () => {
    expect(publicProjection('flags', defaultFlags)).toEqual(defaultFlags);
    expect(publicProjection('limits', defaultLimits)).toEqual(defaultLimits);
    expect(publicProjection('limits', { ...defaultLimits, familyQuotaBytes: -1 })).toBeNull();
    expect(publicProjection('flags', { media_upload: true })).toBeNull();
  });

  it('strips unknown fields', () => {
    const projection = publicProjection('limits', { ...defaultLimits, internalNote: 'x' });
    expect(projection).not.toHaveProperty('internalNote');
  });
});
