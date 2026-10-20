import { describe, expect, it } from 'vitest';
import {
  assistantReadsIn,
  taskVisibilityFor,
  understandingSchema,
  readCardSchema,
} from '../src/index.js';

describe('Lumi Phase 2 questions', () => {
  it.each([
    ['Hôm nay bé thế nào?', 'day_overview'],
    ['How is my baby today?', 'day_overview'],
    ['Bé thay mấy tã hôm nay?', 'diaper_summary'],
    ['Hút được bao nhiêu trong 7 ngày?', 'pump_summary'],
    ['Bé nặng bao nhiêu, có chuẩn không?', 'growth_snapshot'],
    ['Bé ngủ được bao lâu rồi?', 'running_timer'],
    ['Sắp tới bé tiêm gì?', 'vaccine_next'],
    ['Hôm nay có nhắc gì?', 'reminders_today'],
    ['Tháng này tiêu bao nhiêu?', 'spending_month'],
    ['How much did we spend this month?', 'spending_month'],
    ['Bé đã ăn thử những gì?', 'solids_history'],
    ['Bé biết làm gì rồi?', 'milestones'],
    ['Tháng này bé nên làm gì?', 'stage'],
    ['Bé sốt thì làm gì?', 'first_aid'],
    ['Bài về giấc ngủ', 'library_search'],
    ['Bé bú mấy cữ hôm nay?', 'care_summary'],
    ['Tuần này ngủ ít hơn không?', 'sleep_facts'],
    ['Show my reminders', 'reminders_today'],
  ])('%s → %s', (text, tool) => expect(assistantReadsIn(text).map((r) => r.tool)).toEqual([tool]));

  it.each([
    'Bé bú 120ml rồi, hôm nay bú mấy cữ?',
    'Ghi bé thay tã và xem hôm nay',
    'bé đang ngủ',
    'bé biết lẫy rồi',
    'mua sữa nào tốt?',
  ])('does not swallow logs or unrelated questions: %s', (text) =>
    expect(assistantReadsIn(text)).toEqual([]),
  );
  it('combines read-only questions and preserves yesterday', () => {
    expect(assistantReadsIn('Hôm qua bú mấy cữ và thay mấy tã?')).toEqual([
      { tool: 'diaper_summary', dayOffset: -1 },
      { tool: 'care_summary', dayOffset: -1 },
    ]);
  });
  it('keeps money and personal milestones out of the shared caregiver thread', () => {
    for (const text of [
      'Tháng này tiêu bao nhiêu?',
      'How much did we spend this month?',
      'Bé biết làm gì rồi?',
    ]) {
      expect(
        taskVisibilityFor({
          scope: { type: 'child', babyId: 'b' },
          modality: 'text',
          intentHint: null,
          role: 'coParent',
          text,
        }),
      ).toBe('private');
    }
  });
  it('the model cannot return an unknown read tool', () => {
    expect(
      understandingSchema.safeParse({
        act: 'read',
        target: null,
        confidence: 1,
        events: [],
        reads: [{ tool: 'export_everything', dayOffset: 0 }],
        ask: null,
        care: null,
        healthSigns: [],
      }).success,
    ).toBe(false);
  });
  it('read cards have bounded rows and no unexpected fields', () => {
    const c = {
      type: 'read_card',
      schemaVersion: 1,
      tool: 'day_overview',
      title: 'Day',
      asOf: '2026-10-20T04:00:00.000Z',
      rows: [],
      caveat: null,
      action: { label: 'Open', link: '/today' },
      sourceIds: [],
    };
    expect(readCardSchema.safeParse(c).success).toBe(true);
    expect(
      readCardSchema.safeParse({ ...c, rows: Array(25).fill({ label: '', value: 'x' }) }).success,
    ).toBe(false);
  });
});
