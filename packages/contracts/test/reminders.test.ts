import { describe, expect, it } from 'vitest';
import {
  reminderFireAt,
  reminderLeadMinutes,
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
