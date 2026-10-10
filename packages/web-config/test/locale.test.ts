import { describe, expect, it } from 'vitest';
import { resolveLocale } from '../src/locale.js';

describe('resolveLocale', () => {
  it('prefers an explicit saved choice', () => {
    expect(resolveLocale('en', ['vi-VN'])).toBe('en');
  });
  it('uses the first supported browser language', () => {
    expect(resolveLocale(null, ['fr-FR', 'en-US', 'vi'])).toBe('en');
    expect(resolveLocale('de', ['vi-VN'])).toBe('vi');
  });
  it('falls back to Vietnamese', () => {
    expect(resolveLocale(null, ['ja-JP'])).toBe('vi');
    expect(resolveLocale(undefined, [])).toBe('vi');
  });
});
