import { describe, expect, it } from 'vitest';
import {
  amountFits,
  amountMaxFor,
  budgetSchema,
  builtInCategories,
  currencyForCountry,
  currencyInfo,
  currencyOfDoc,
  dueDatesBetween,
  expenseCurrencies,
  expenseSchema,
  isExpenseCurrency,
  minorToPlain,
  otherCategoryId,
  recurringScheduleSchema,
  spendingLimits,
  spendingSettingsSchema,
  toMinorUnits,
} from '../src/spending.js';
import { expenseCurrencySupported, supportedCurrencies } from '../src/assistant.js';

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
    expect(expenseSchema.safeParse({ ...base, source: 'import' }).success).toBe(true);
    expect(expenseSchema.safeParse({ ...base, source: 'bank' }).success).toBe(false);
  });

  it('the built-ins end with Khác, which cannot be deleted', () => {
    expect(builtInCategories.at(-1)?.id).toBe(otherCategoryId);
  });
});

describe('currencies (D-075 #4)', () => {
  it('ISO 4217 exponents and a ceiling per currency; VND unchanged', () => {
    expect(currencyInfo.VND).toEqual({ exponent: 0, max: spendingLimits.amountMax });
    expect(currencyInfo.USD.exponent).toBe(2);
    expect(currencyInfo.JPY.exponent).toBe(0);
    expect(currencyInfo.KRW.exponent).toBe(0);
    expect(amountMaxFor('USD')).toBe(100_000_000);
    expect(amountFits(1, 'USD')).toBe(true);
    expect(amountFits(100_000_001, 'USD')).toBe(false);
    expect(amountFits(1.5, 'VND')).toBe(false);
    expect(amountFits(0, 'JPY')).toBe(false);
  });

  it('every currency the assistant reads is one Chi tiêu keeps', () => {
    for (const c of supportedCurrencies) {
      expect(isExpenseCurrency(c)).toBe(true);
      expect(expenseCurrencySupported(c)).toBe(true);
    }
    expect(expenseCurrencies).toContain('THB');
    expect(isExpenseCurrency('XAF')).toBe(false);
    expect(isExpenseCurrency(null)).toBe(false);
  });

  it('minor units both ways', () => {
    expect(toMinorUnits(12.5, 'USD')).toBe(1250);
    expect(toMinorUnits(0.1 + 0.2, 'USD')).toBe(30);
    expect(toMinorUnits(486000, 'VND')).toBe(486000);
    expect(toMinorUnits(1500, 'JPY')).toBe(1500);
    expect(minorToPlain(1250, 'USD')).toBe('12.50');
    expect(minorToPlain(5, 'EUR')).toBe('0.05');
    expect(minorToPlain(-1205, 'GBP')).toBe('-12.05');
    expect(minorToPlain(1_020_000, 'VND')).toBe('1020000');
  });

  it('documents without a currency are VND; the household default follows the country', () => {
    expect(currencyOfDoc(undefined)).toBe('VND');
    expect(currencyOfDoc(null)).toBe('VND');
    expect(currencyOfDoc('USD')).toBe('USD');
    expect(currencyForCountry('VN')).toBe('VND');
    expect(currencyForCountry('us')).toBe('USD');
    expect(currencyForCountry('DE')).toBe('EUR');
    expect(currencyForCountry('BR')).toBe('VND');
    expect(currencyForCountry(null)).toBe('VND');
  });

  it('the schemas accept old documents and new ones with a currency', () => {
    const base = {
      amount: 1_020_000,
      categoryId: 'c_milk',
      note: '',
      spentOn: '2026-10-12',
      payer: null,
      receiptPath: null,
      source: 'manual',
      sourceRef: null,
      createdBy: 'u',
      author: { name: 'Mẹ', relation: 'mother', relationCustom: null },
      createdAt: new Date(),
      updatedAt: new Date(),
      updatedBy: 'u',
      deleted: false,
    };
    expect(expenseSchema.safeParse(base).success).toBe(true);
    expect(expenseSchema.safeParse({ ...base, amount: 1250, currency: 'USD' }).success).toBe(true);
    expect(expenseSchema.safeParse({ ...base, currency: 'XAF' }).success).toBe(false);
    expect(
      budgetSchema.safeParse({
        monthlyTotal: 200_000,
        caps: {},
        alert80: true,
        currency: 'USD',
        updatedAt: new Date(),
        updatedBy: 'u',
      }).success,
    ).toBe(true);
    expect(
      spendingSettingsSchema.safeParse({ currency: 'EUR', updatedAt: new Date(), updatedBy: 'u' })
        .success,
    ).toBe(true);
  });
});
