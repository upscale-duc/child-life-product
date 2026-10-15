import { describe, expect, it } from 'vitest';
import {
  foldText,
  guessDateOrder,
  isAmbiguousDay,
  detectCurrency,
  parseAmount,
  parseDay,
} from '../src/spending-import.js';

describe('reading days', () => {
  it('reads what spreadsheets and apps write', () => {
    expect(parseDay('2026-10-12')).toBe('2026-10-12');
    expect(parseDay('2026/10/12 08:30')).toBe('2026-10-12');
    expect(parseDay('12/10/2026')).toBe('2026-10-12');
    expect(parseDay('12-10-26')).toBe('2026-10-12');
    expect(parseDay('12.10.2026 14:20')).toBe('2026-10-12');
    expect(parseDay('3/4/2026')).toBe('2026-04-03');
    expect(parseDay('3/4/2026', 'mdy')).toBe('2026-03-04');
    expect(parseDay('12 thg 10, 2026')).toBe('2026-10-12');
    expect(parseDay('12 tháng 10 năm 2026')).toBe('2026-10-12');
    expect(parseDay('Oct 12, 2026')).toBe('2026-10-12');
    expect(parseDay('12 October 2026')).toBe('2026-10-12');
    expect(parseDay('46307')).toBe('2026-10-12');
    expect(parseDay('31/02/2026')).toBeNull();
    expect(parseDay('hôm qua')).toBeNull();
  });

  it('guesses the order and flags ambiguous days', () => {
    expect(guessDateOrder(['12/10/2026', '03/04/2026'])).toBe('dmy');
    expect(guessDateOrder(['10/12/2026', '04/25/2026'])).toBe('mdy');
    expect(isAmbiguousDay('03/04/2026')).toBe(true);
    expect(isAmbiguousDay('13/04/2026')).toBe(false);
  });
});

describe('reading money', () => {
  it('reads the usual Vietnamese and English forms', () => {
    const v = (s: string) => parseAmount(s)?.value;
    expect(v('1.020.000')).toBe(1020000);
    expect(v('1,020,000')).toBe(1020000);
    expect(v('1.020.000 ₫')).toBe(1020000);
    expect(v('1.020.000đ')).toBe(1020000);
    expect(v('1020000 VND')).toBe(1020000);
    expect(v('1020000.00')).toBe(1020000);
    expect(v('1.020.000,50')).toBe(1020001);
    expect(v('-500.000')).toBe(-500000);
    expect(v('(500.000)')).toBe(-500000);
    expect(v('−285,000')).toBe(-285000);
    expect(v('500k')).toBe(500000);
    expect(v('1tr2')).toBe(1200000);
    expect(v('1,5 tr')).toBe(1500000);
    expect(v('2 triệu')).toBe(2000000);
    expect(v('300 nghìn')).toBe(300000);
    expect(v('120')).toBe(120);
    expect(v('abc')).toBeUndefined();
    expect(parseAmount('$12.50')?.foreign).toBe(true);
  });

  it('names the currency of a cell (D-075 #4)', () => {
    const c = (s: string, household?: Parameters<typeof detectCurrency>[1]) =>
      parseAmount(s, household)?.currency;
    expect(c('1.020.000 ₫')).toBe('VND');
    expect(c('1.020.000đ')).toBe('VND');
    expect(c('500k')).toBeNull();
    expect(c('2 triệu')).toBeNull();
    expect(c('$12.50')).toBe('USD');
    expect(c('$12.50', 'AUD')).toBe('AUD');
    expect(c('US$12.50', 'AUD')).toBe('USD');
    expect(c('S$ 8.90')).toBe('SGD');
    expect(c('12,50 €')).toBe('EUR');
    expect(c('£3.20')).toBe('GBP');
    expect(c('¥1,500')).toBe('JPY');
    expect(c('¥1,500', 'CNY')).toBe('CNY');
    expect(c('₩12,000')).toBe('KRW');
    expect(c('฿120')).toBe('THB');
    expect(c('NT$300')).toBe('TWD');
    expect(c('RM 25.90')).toBe('MYR');
    expect(c('12.50 usd')).toBe('USD');
    expect(c('EUR 7')).toBe('EUR');
    expect(c('500 INR')).toBe('other');
    expect(parseAmount('$12.50')).toMatchObject({ major: 12.5, value: 13 });
    expect(parseAmount('12,50 €')?.major).toBe(12.5);
    expect(parseAmount('-1,500 JPY')?.major).toBe(-1500);
    expect(parseAmount('1tr2 VND')?.major).toBe(1_200_000);
    expect(detectCurrency('')).toBeNull();
    expect(detectCurrency('VND')).toBe('VND');
    expect(detectCurrency('đ')).toBe('VND');
    expect(detectCurrency('usd')).toBe('USD');
    expect(detectCurrency('Rp')).toBeNull();
  });

  it('folds Vietnamese for matching', () => {
    expect(foldText('  Sữa  Công THỨC ')).toBe('sua cong thuc');
    expect(foldText('Đồ dùng')).toBe('do dung');
  });
});
