import { describe, expect, it } from 'vitest';
import {
  answerReminderRuleSchema,
  nextDueOf,
  ruleTypeOfRecord,
  saveReminderRuleSchema,
  type RuleSchedule,
} from '../src/index.js';

// Rule reminders (370:1247) in Hồ Chí Minh (UTC+7); Thursday 8 Oct 2026 as in the mocks.
const zone = 'Asia/Ho_Chi_Minh';
const vn = (day: number, hh: number, mm = 0) => new Date(Date.UTC(2026, 9, day, hh - 7, mm));

const afterLast = (over: Partial<RuleSchedule> = {}): RuleSchedule => ({
  mode: 'afterLast',
  enabled: true,
  intervalMinutes: 180,
  times: [],
  days: [1, 2, 3, 4, 5, 6, 7],
  quietNight: false,
  anchorAt: vn(8, 11, 45),
  skipBase: null,
  snoozedUntil: null,
  pendingDueAt: null,
  ...over,
});

const fixed = (over: Partial<RuleSchedule> = {}): RuleSchedule => ({
  ...afterLast(),
  mode: 'fixed',
  intervalMinutes: null,
  times: ['09:00', '13:00', '19:30'],
  anchorAt: null,
  ...over,
});

describe('after the latest log (1c)', () => {
  it('fed at 11:45, every 3 h → 14:45', () => {
    expect(nextDueOf(zone, afterLast(), vn(8, 12))).toEqual(vn(8, 14, 45));
  });

  it('waits for a first log, and while a due one is unanswered', () => {
    expect(nextDueOf(zone, afterLast({ anchorAt: null }), vn(8, 12))).toBeNull();
    expect(nextDueOf(zone, afterLast({ pendingDueAt: vn(8, 14, 45) }), vn(8, 15))).toBeNull();
  });

  it('a snooze wins; a skip counts the next one from the skipped time', () => {
    expect(nextDueOf(zone, afterLast({ snoozedUntil: vn(8, 15) }), vn(8, 14, 50))).toEqual(
      vn(8, 15),
    );
    expect(nextDueOf(zone, afterLast({ skipBase: vn(8, 14, 45) }), vn(8, 14, 50))).toEqual(
      vn(8, 17, 45),
    );
  });

  it('quiet nights wait for 06:00 (P-130)', () => {
    const rule = afterLast({ anchorAt: vn(8, 20), quietNight: true });
    expect(nextDueOf(zone, rule, vn(8, 20, 30))).toEqual(vn(9, 6));
    const early = afterLast({ anchorAt: vn(8, 1), quietNight: true });
    expect(nextDueOf(zone, early, vn(8, 2))).toEqual(vn(8, 6));
  });

  it('days it does not apply move to the next allowed day', () => {
    // Thursday 8 Oct is 4; only Fridays (5).
    const rule = afterLast({ days: [5] });
    expect(nextDueOf(zone, rule, vn(8, 12))).toEqual(vn(9, 0));
  });

  it('long overdue rings now; paused never', () => {
    expect(nextDueOf(zone, afterLast({ anchorAt: vn(7, 8) }), vn(8, 12))).toEqual(vn(8, 12));
    expect(nextDueOf(zone, afterLast({ enabled: false }), vn(8, 12))).toBeNull();
  });
});

describe('fixed times (1c2)', () => {
  it('the next time today, then tomorrow', () => {
    expect(nextDueOf(zone, fixed(), vn(8, 10))).toEqual(vn(8, 13));
    expect(nextDueOf(zone, fixed(), vn(8, 20))).toEqual(vn(9, 9));
  });

  it('moves past the one that just rang, even while it is unanswered', () => {
    expect(nextDueOf(zone, fixed({ pendingDueAt: vn(8, 13) }), vn(8, 13), vn(8, 13))).toEqual(
      vn(8, 19, 30),
    );
  });

  it('only on the chosen days', () => {
    // Saturday (6) only.
    expect(nextDueOf(zone, fixed({ days: [6] }), vn(8, 10))).toEqual(vn(10, 9));
  });
});

describe('shapes', () => {
  const base = {
    babyId: 'b_1',
    ruleId: `rr_${'a'.repeat(32)}`,
    type: 'feed',
    days: [1, 2, 3, 4, 5, 6, 7],
    quietNight: false,
    recipients: ['mai', 'lan'],
  };

  it('each mode carries only its own timing', () => {
    expect(
      saveReminderRuleSchema.safeParse({
        ...base,
        mode: 'afterLast',
        intervalMinutes: 180,
        times: [],
      }).success,
    ).toBe(true);
    expect(
      saveReminderRuleSchema.safeParse({
        ...base,
        mode: 'afterLast',
        intervalMinutes: 170,
        times: [],
      }).success,
    ).toBe(false);
    expect(
      saveReminderRuleSchema.safeParse({
        ...base,
        mode: 'fixed',
        intervalMinutes: null,
        times: ['09:00', '09:00'],
      }).success,
    ).toBe(false);
  });

  it('snooze needs 10, 15 or 30 minutes', () => {
    const a = { babyId: 'b_1', ruleId: base.ruleId, dueAt: 1 };
    expect(
      answerReminderRuleSchema.safeParse({ ...a, action: 'snooze', minutes: 15 }).success,
    ).toBe(true);
    expect(
      answerReminderRuleSchema.safeParse({ ...a, action: 'snooze', minutes: 20 }).success,
    ).toBe(false);
    expect(answerReminderRuleSchema.safeParse({ ...a, action: 'skip' }).success).toBe(true);
  });

  it('bottle and breast both count as Bú', () => {
    expect(ruleTypeOfRecord('bottle')).toBe('feed');
    expect(ruleTypeOfRecord('breast')).toBe('feed');
    expect(ruleTypeOfRecord('growth')).toBeNull();
  });
});
