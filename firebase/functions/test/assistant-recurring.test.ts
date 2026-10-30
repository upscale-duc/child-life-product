import { describe, expect, it } from 'vitest';
import { recurringRuleIn, ruleEditorLink, saysRecurring } from '../src/assistant-recurring.js';

// Lumi L5: a recurring care reminder read by rules (no model) → the app's rule editor, prefilled.
describe('recurringRuleIn', () => {
  it.each([
    ['nhắc cữ bú mỗi 3 tiếng', { type: 'feed', mode: 'afterLast', intervalMinutes: 180 }],
    ['nhắc cho bé bú cứ 2 tiếng rưỡi', { type: 'feed', mode: 'afterLast', intervalMinutes: 150 }],
    ['nhắc mình hút sữa mỗi 3 tiếng', { type: 'pump', mode: 'afterLast', intervalMinutes: 180 }],
    [
      'remind me to feed every 2.5 hours',
      { type: 'feed', mode: 'afterLast', intervalMinutes: 150 },
    ],
    ['nhắc thay tã mỗi 90 phút', { type: 'diaper', mode: 'afterLast', intervalMinutes: 90 }],
  ])('%s', (text, rule) => expect(recurringRuleIn(text)).toMatchObject(rule));

  it('fixed times with their own period words, every day unless narrowed', () => {
    expect(recurringRuleIn('nhắc thay tã lúc 8h, 12h và 4h chiều hằng ngày')).toEqual({
      type: 'diaper',
      mode: 'fixed',
      intervalMinutes: null,
      times: ['08:00', '12:00', '16:00'],
      days: [1, 2, 3, 4, 5, 6, 7],
    });
    expect(recurringRuleIn('nhắc cho bé ngủ trưa 12h30 mỗi ngày thường')).toMatchObject({
      type: 'sleep',
      times: ['12:30'],
      days: [1, 2, 3, 4, 5],
    });
  });

  it('not a recurring care reminder: null', () => {
    for (const text of [
      'bé bú 120ml',
      'nhắc mai 9h đi tiêm',
      'nhắc cho bé uống vitamin D mỗi sáng 8h',
      'mỗi 3 tiếng bé bú một lần',
      'nhắc cữ bú mỗi 20 tiếng',
    ]) {
      expect(recurringRuleIn(text), text).toBeNull();
    }
  });

  it('builds the editor link', () => {
    expect(ruleEditorLink(recurringRuleIn('nhắc cữ bú mỗi 3 tiếng')!)).toBe(
      '/care/reminders/rules/new?type=feed&interval=180',
    );
    expect(ruleEditorLink(recurringRuleIn('nhắc thay tã 8h và 14h mỗi cuối tuần')!)).toBe(
      '/care/reminders/rules/new?type=diaper&times=08%3A00%2C14%3A00&days=6%2C7',
    );
  });

  it('reads "mỗi" / "cứ" with their marks: "mới" and "cũ" are not a repeat', () => {
    expect(saysRecurring('nhắc mua sữa mỗi tuần')).toBe(true);
    expect(saysRecurring('remind me daily')).toBe(true);
    expect(saysRecurring('nhắc mai đi mua sữa mới')).toBe(false);
    expect(saysRecurring('nhắc bỏ bình sữa cũ')).toBe(false);
    expect(recurringRuleIn('nhắc cho bé bú bình mới lúc 8h')).toBeNull();
  });
});
