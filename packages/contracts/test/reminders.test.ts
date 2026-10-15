import { describe, expect, it } from 'vitest';
import {
  assistantModuleProblems,
  reminderAllDayDueAt,
  reminderAssigneeSupported,
  reminderFireAt,
  reminderInstantIn,
  reminderLeadMinutes,
  reminderNeedsTime,
  reminderSchema,
  reminderStatus,
} from '../src/index.js';

const author = { name: 'Mai', relation: 'mother', relationCustom: null };
const base = {
  id: `rm_${'a'.repeat(32)}`,
  babyId: 'b_00000000000000000001',
  title: 'Tiêm 6 trong 1',
  dueAt: new Date('2026-10-10T01:30:00Z'),
  leadMinutes: 60,
  notifyDevice: { id: `d_${'b'.repeat(32)}`, uid: 'u_mai', label: 'iPhone', owner: 'Mai' },
  createdBy: 'u_mai',
  author,
  createdAt: new Date('2026-10-08T03:00:00Z'),
  updatedAt: new Date('2026-10-08T03:00:00Z'),
  updatedBy: 'u_mai',
  done: false,
  doneAt: null,
  doneBy: null,
  doneAuthor: null,
};

describe('reminders (S7)', () => {
  it('accepts the 8b shape and only the D-031 lead times', () => {
    expect(reminderSchema.parse(base).title).toBe('Tiêm 6 trong 1');
    expect([...reminderLeadMinutes]).toEqual([0, 10, 30, 60, 120, 1440]);
    expect(reminderSchema.safeParse({ ...base, leadMinutes: 45 }).success).toBe(false);
    expect(reminderSchema.safeParse({ ...base, title: '  ' }).success).toBe(false);
    expect(reminderSchema.safeParse({ ...base, title: 'x'.repeat(81) }).success).toBe(false);
    expect(reminderSchema.safeParse({ ...base, notifyDevice: null }).success).toBe(true);
    expect(
      reminderSchema.safeParse({ ...base, notifyDevice: { ...base.notifyDevice, id: 'iphone' } })
        .success,
    ).toBe(false);
  });

  it('derives overdue from the due time (R-093)', () => {
    const now = new Date('2026-10-10T02:00:00Z');
    expect(reminderStatus(base, now)).toBe('overdue');
    expect(reminderStatus(base, new Date('2026-10-10T01:00:00Z'))).toBe('upcoming');
    expect(reminderStatus({ ...base, done: true }, now)).toBe('done');
  });

  it('fires once at due time minus "Báo trước" (D-032)', () => {
    expect(reminderFireAt(base).toISOString()).toBe('2026-10-10T00:30:00.000Z');
    expect(reminderFireAt({ ...base, leadMinutes: 0 }).toISOString()).toBe(
      '2026-10-10T01:30:00.000Z',
    );
  });
});

describe('date-only and assignee (D-075 #5)', () => {
  const zone = 'Asia/Ho_Chi_Minh';
  const allDay = {
    ...base,
    allDay: true,
    dueDate: '2026-10-10',
    dueAt: reminderAllDayDueAt(zone, '2026-10-10'),
    leadMinutes: 0,
    assigneeUid: 'u_lan',
  };

  it('old documents (no new keys) still parse; all day needs a date and a day lead', () => {
    expect(reminderSchema.safeParse(base).success).toBe(true);
    expect(reminderSchema.safeParse(allDay).success).toBe(true);
    expect(reminderSchema.safeParse({ ...allDay, dueDate: null }).success).toBe(false);
    expect(reminderSchema.safeParse({ ...allDay, dueDate: '2026-13-01' }).success).toBe(false);
    expect(reminderSchema.safeParse({ ...allDay, leadMinutes: 60 }).success).toBe(false);
    expect(reminderSchema.safeParse({ ...allDay, leadMinutes: 1440 }).success).toBe(true);
    expect(reminderSchema.safeParse({ ...base, dueDate: '2026-10-10' }).success).toBe(false);
    expect(reminderSchema.safeParse({ ...base, assigneeUid: '' }).success).toBe(false);
    expect(reminderSchema.safeParse({ ...base, assigneeUid: null }).success).toBe(true);
  });

  it('dueAt of an all-day reminder is 23:59 that day in the baby zone (DST-safe)', () => {
    expect(allDay.dueAt.toISOString()).toBe('2026-10-10T16:59:00.000Z');
    expect(reminderInstantIn('America/New_York', '2026-03-08', '08:00').toISOString()).toBe(
      '2026-03-08T12:00:00.000Z',
    );
  });

  it('is due all day and overdue from the next day, by date in the baby zone', () => {
    // 23:30 on the 10th in Vietnam: still that day.
    expect(reminderStatus(allDay, new Date('2026-10-10T16:30:00Z'), zone)).toBe('upcoming');
    // 00:10 on the 11th.
    expect(reminderStatus(allDay, new Date('2026-10-10T17:10:00Z'), zone)).toBe('overdue');
    expect(reminderStatus({ ...allDay, done: true }, new Date('2026-10-12T00:00:00Z'), zone)).toBe(
      'done',
    );
  });

  it('fires at the person’s chosen time (default 08:00) on the day, or the day before', () => {
    expect(reminderFireAt(allDay, zone).toISOString()).toBe('2026-10-10T01:00:00.000Z');
    expect(reminderFireAt(allDay, zone, '06:30').toISOString()).toBe('2026-10-09T23:30:00.000Z');
    expect(reminderFireAt({ ...allDay, leadMinutes: 1440 }, zone).toISOString()).toBe(
      '2026-10-09T01:00:00.000Z',
    );
    // Month boundary.
    expect(
      reminderFireAt({ ...allDay, dueDate: '2026-11-01', leadMinutes: 1440 }, zone).toISOString(),
    ).toBe('2026-10-31T01:00:00.000Z');
  });

  it('the assistant takes date-only reminders and an assignee', () => {
    expect(reminderNeedsTime()).toBe(false);
    expect(reminderAssigneeSupported()).toBe(true);
    expect(
      assistantModuleProblems({
        kind: 'reminder',
        title: 'Mua bỉm',
        date: '2026-10-16',
        time: null,
        assigneeUid: 'u_lan',
      }),
    ).toEqual([]);
  });
});
