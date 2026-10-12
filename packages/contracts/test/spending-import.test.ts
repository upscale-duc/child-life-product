import { describe, expect, it } from 'vitest';
import {
  foldText,
  guessDateOrder,
  isAmbiguousDay,
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

  it('folds Vietnamese for matching', () => {
    expect(foldText('  Sữa  Công THỨC ')).toBe('sua cong thuc');
    expect(foldText('Đồ dùng')).toBe('do dung');
  });
});
