import { describe, expect, it } from 'vitest';
import { assistantReadTools, type MemberGrant } from '@child-life/contracts';
import { allowsAssistantRead, articleQuery } from '../src/assistant-reads.js';
import { growthPercentile } from '../src/assistant-growth.js';

describe('Phase 2 authorisation mirrors module Rules', () => {
  it('co-parents read every module', () => {
    for (const tool of assistantReadTools)
      expect(allowsAssistantRead(tool, { role: 'coParent' })).toBe(true);
  });
  it('care access never grants reminders, money or personal milestones to relatives', () => {
    const m: MemberGrant = { role: 'relative', extraRights: { viewDailyCare: true } };
    expect(allowsAssistantRead('diaper_summary', m)).toBe(true);
    for (const tool of ['reminders_today', 'spending_month', 'milestones'] as const)
      expect(allowsAssistantRead(tool, m)).toBe(false);
    expect(allowsAssistantRead('milestones', { role: 'caregiver' })).toBe(false);
  });
  it('a right to record own spending cannot expose all spending', () => {
    expect(
      allowsAssistantRead('spending_month', {
        role: 'caregiver',
        extraRights: { recordSpending: true },
      }),
    ).toBe(false);
    expect(
      allowsAssistantRead('spending_month', {
        role: 'relative',
        extraRights: { viewSpending: true },
      }),
    ).toBe(true);
    expect(allowsAssistantRead('day_overview', { role: 'relative' })).toBe(false);
  });
});

describe('WHO percentiles use the app LMS source', () => {
  it.each([
    ['weight', 3.3464],
    ['length', 49.8842],
    ['head', 34.4618],
  ] as const)('WHO boy newborn median for %s is P50', (measure, value) =>
    expect(growthPercentile(measure, 'boy', 0, value)).toBeCloseTo(50, 1),
  );
  it('never extrapolates, guesses a sex, or computes for invalid measurements', () => {
    expect(growthPercentile('weight', 'unspecified', 100, 6)).toBeNull();
    expect(growthPercentile('weight', 'girl', -1, 6)).toBeNull();
    expect(growthPercentile('weight', 'girl', 1900, 6)).toBeNull();
    expect(growthPercentile('head', 'boy', 1, 0)).toBeNull();
  });
  it('search removes request words while retaining the actual topic', () =>
    expect(articleQuery('Tìm cho mình bài viết về giấc ngủ')).toEqual(['giac', 'ngu']));
});
