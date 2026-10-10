import { describe, expect, it } from 'vitest';
import {
  createBabyRequestSchema,
  isIanaTimeZone,
  localDateIn,
  setBabyAvatarRequestSchema,
} from '../src/baby.js';

const valid = {
  requestId: '6f1c2b8e-1d2a-4c3b-9e8f-0a1b2c3d4e5f',
  nickname: ' Teddy ',
  dateOfBirth: '2026-09-17',
  gender: 'unspecified',
  timeZone: { mode: 'manual', zone: 'Asia/Ho_Chi_Minh' },
  avatarPreset: 4,
  trackers: ['sleep'],
  self: { displayName: 'Mai', relation: 'other', relationCustom: 'Dì' },
};

describe('baby contracts', () => {
  it('accepts a valid create request and trims the nickname', () => {
    expect(createBabyRequestSchema.parse(valid).nickname).toBe('Teddy');
  });

  it('requires custom text exactly for "Khác…"', () => {
    expect(
      createBabyRequestSchema.safeParse({
        ...valid,
        self: { displayName: 'Mai', relation: 'other' },
      }).success,
    ).toBe(false);
    expect(
      createBabyRequestSchema.safeParse({
        ...valid,
        self: { displayName: 'Mai', relation: 'mother', relationCustom: 'x' },
      }).success,
    ).toBe(false);
  });

  it('accepts IANA zones only (P-014)', () => {
    expect(isIanaTimeZone('Asia/Ho_Chi_Minh')).toBe(true);
    expect(isIanaTimeZone('America/Argentina/Buenos_Aires')).toBe(true);
    expect(isIanaTimeZone('UTC')).toBe(true);
    expect(isIanaTimeZone('GMT+7')).toBe(false);
    expect(isIanaTimeZone('Mars/Olympus')).toBe(false);
  });

  it('computes the calendar date in a zone', () => {
    const now = new Date('2026-10-07T20:00:00Z');
    expect(localDateIn('Asia/Ho_Chi_Minh', now)).toBe('2026-10-08');
    expect(localDateIn('America/New_York', now)).toBe('2026-10-07');
  });

  it('limits avatar photos to about 1 MB of base64', () => {
    const big = 'A'.repeat(1_500_000);
    expect(
      setBabyAvatarRequestSchema.safeParse({
        babyId: 'b_0123456789abcdef0123',
        avatar: { kind: 'photo', jpegBase64: big },
      }).success,
    ).toBe(false);
    expect(
      setBabyAvatarRequestSchema.safeParse({
        babyId: 'nope',
        avatar: { kind: 'preset', preset: 1 },
      }).success,
    ).toBe(false);
  });
});
