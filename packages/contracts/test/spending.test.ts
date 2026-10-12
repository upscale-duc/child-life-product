import { describe, expect, it } from 'vitest';
import {
  builtInCategories,
  dueDatesBetween,
  expenseSchema,
  otherCategoryId,
  recurringScheduleSchema,
} from '../src/spending.js';

describe('recurring due dates (8i, D-057)', () => {
  it('monthly on two days, a 31st falling on the last day of short months', () => {
    expect(dueDatesBetween({ kind: 'monthly', days: [1, 16] }, '2026-10-01', '2026-11-01')).toEqual(
      ['2026-10-16', '2026-11-01'],
    );
    expect(dueDatesBetween({ kind: 'monthly', days: [31] }, '2026-10-31', '2026-12-31')).toEqual([
      '2026-11-30',
      '2026-12-31',
    ]);
  });

  it('every N weeks from the start day, never before it', () => {
    expect(
      dueDatesBetween(
        { kind: 'weeks', every: 2, startOn: '2026-10-12' },
        '2026-10-01',
        '2026-11-10',
      ),
    ).toEqual(['2026-10-12', '2026-10-26', '2026-11-09']);
  });

  it('yearly on a date; 29/2 falls on 28/2 in a common year', () => {
    expect(
      dueDatesBetween({ kind: 'yearly', month: 3, day: 5 }, '2026-01-01', '2027-12-31'),
    ).toEqual(['2026-03-05', '2027-03-05']);
    expect(
      dueDatesBetween({ kind: 'yearly', month: 2, day: 29 }, '2027-01-01', '2028-12-31'),
    ).toEqual(['2027-02-28', '2028-02-29']);
  });

  it('rejects malformed schedules', () => {
    expect(recurringScheduleSchema.safeParse({ kind: 'monthly', days: [] }).success).toBe(false);
    expect(
      recurringScheduleSchema.safeParse({ kind: 'weeks', every: 9, startOn: '2026-10-12' }).success,
    ).toBe(false);
  });
});

describe('expenses', () => {
  it('whole VND only, a known source, Khác as a payer of null', () => {
    const base = {
      amount: 1_020_000,
      categoryId: 'c_milk',
      note: 'Sữa công thức ×2',
      spentOn: '2026-10-12',
      payer: null,
      receiptPath: null,
      source: 'manual',
      sourceRef: null,
      createdBy: 'mom',
      author: { name: 'Mai', relation: 'mother', relationCustom: null },
      createdAt: new Date(),
      updatedAt: new Date(),
      updatedBy: 'mom',
      deleted: false,
    };
    expect(expenseSchema.safeParse(base).success).toBe(true);
    expect(expenseSchema.safeParse({ ...base, amount: 10.5 }).success).toBe(false);
    expect(expenseSchema.safeParse({ ...base, amount: 0 }).success).toBe(false);
    expect(expenseSchema.safeParse({ ...base, source: 'import' }).success).toBe(false);
  });

  it('the built-ins end with Khác, which cannot be deleted', () => {
    expect(builtInCategories.at(-1)?.id).toBe(otherCategoryId);
  });
});
