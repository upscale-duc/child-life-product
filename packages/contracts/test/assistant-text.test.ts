import { describe, expect, it } from 'vitest';
import {
  agoIn,
  asksWhatToEat,
  bottleMlIn,
  breastSideIn,
  categoryHintIn,
  clockTimeIn,
  completeSpan,
  durationsIn,
  hasDayPeriod,
  looksLikeSpending,
  mentionsMedicine,
  moneyAmountsIn,
  parseLooseNumber,
  parseMoney,
  relativeDateIn,
  smallTalkIn,
  spendingSignalsIn,
  taskVisibilityFor,
} from '../src/index.js';

// Lumi rework 2026-10-15 (docs/assistant/api.md "Rework 2026-10-15"): deterministic text rules.
// Synthetic phrases only. Today = 2026-10-15, a Thursday.
const TODAY = '2026-10-15';

describe('money: Vietnamese shorthand and other currencies, minor units', () => {
  const one = (t: string) => {
    const m = moneyAmountsIn(t);
    return m.length ? { minor: m[0]!.minor, currency: m[0]!.currency } : null;
  };
  it.each([
    ['Mua sữa hết 500k', 500_000],
    ['mua sữa hết 500 k', 500_000],
    ['50 nghìn tã', 50_000],
    ['50 ngàn tã', 50_000],
    ['50 nghin ta', 50_000],
    ['đóng tiền học bơi 1tr2', 1_200_000],
    ['1tr25 tiền học', 1_250_000],
    ['1tr250', 1_250_000],
    ['1.2tr tiền khám', 1_200_000],
    ['1,5 triệu', 1_500_000],
    ['1 triệu rưỡi', 1_500_000],
    ['4 triệu', 4_000_000],
    ['tiền học 1 triệu 2', 1_200_000],
    ['350.000đ ở Con Cưng', 350_000],
    ['350.000 đ', 350_000],
    ['500,000 vnd', 500_000],
    ['1.200.000 VNĐ', 1_200_000],
    ['500000 dong', 500_000],
    ['500 đồng', 500],
  ])('%s → %i VND', (text, minor) => {
    expect(one(text)).toEqual({ minor, currency: 'VND' });
  });
  it.each([
    ['$20 diapers', 2000, 'USD'],
    ['20$', 2000, 'USD'],
    ['Paid 35 dollars', 3500, 'USD'],
    ['20 USD', 2000, 'USD'],
    ['USD 12.50', 1250, 'USD'],
    ['20 đô', 2000, 'USD'],
    ['20 đô la', 2000, 'USD'],
    ['€15 for wipes', 1500, 'EUR'],
    ['15 euros', 1500, 'EUR'],
    ['£8.99', 899, 'GBP'],
    ['300 baht', 30_000, 'THB'],
    ['1000 yen', 1000, 'JPY'],
    ['20 sgd', 2000, 'SGD'],
  ])('%s → %i %s', (text, minor, currency) => {
    expect(one(text)).toEqual({ minor, currency });
  });
  it('never reads measures, times, temperatures or kg as money', () => {
    for (const t of [
      'bé bú 120ml lúc 8h',
      'bé nặng 6kg',
      'sốt 39 độ',
      'ngủ 9 tiếng',
      '12 trưa ngủ',
      'bú 15 phút',
      '5 trẻ',
      'đi 3 km',
    ]) {
      expect(moneyAmountsIn(t)).toEqual([]);
    }
  });
  it('several amounts in reading order', () => {
    expect(moneyAmountsIn('sữa 500k, tã 300k').map((m) => m.minor)).toEqual([500_000, 300_000]);
  });
  it('a bare number takes the household currency; a small VND one is uncertain', () => {
    expect(parseMoney('450,000', 'VND')).toMatchObject({
      minor: 450_000,
      currency: 'VND',
      explicitCurrency: false,
      uncertain: false,
    });
    expect(parseMoney('hết 500', 'VND')).toMatchObject({ minor: 500, uncertain: true });
    expect(parseMoney('20', 'USD')).toMatchObject({ minor: 2000, currency: 'USD' });
    expect(parseMoney('120ml', 'VND')).toBeNull();
    expect(parseMoney('$20', 'VND')).toMatchObject({ minor: 2000, currency: 'USD' });
  });
  it('loose numbers: thousands vs decimals', () => {
    expect(parseLooseNumber('350.000')).toBe(350_000);
    expect(parseLooseNumber('1.200.000')).toBe(1_200_000);
    expect(parseLooseNumber('500,000')).toBe(500_000);
    expect(parseLooseNumber('12.50')).toBe(12.5);
    expect(parseLooseNumber('1,5')).toBe(1.5);
    expect(parseLooseNumber('1.200,50')).toBe(1200.5);
  });
});

describe('spending detector (D-075 #2): money never reaches the shared thread', () => {
  it.each([
    'Mua sữa hết 500k',
    'mua sua het 500k',
    'mua binh sua',
    'đóng tiền học bơi 1tr2',
    'hôm qua mua bỉm 350.000đ ở Con Cưng',
    'trả 200k tiền điện nước',
    'học phí tháng này',
    'hết 300 nghìn',
    '$20 diapers',
    'Paid 35 dollars for her vaccine',
    'we bought formula',
    'bé bú 120ml, mua sữa 500k',
    'nhắc mai 9h mua bỉm',
    'chi tiêu tuần này',
  ])('%s → private', (text) => {
    expect(looksLikeSpending(text)).toBe(true);
  });
  it.each([
    'bé bú bình 120ml lúc 8h sáng',
    'đêm qua bé ngủ từ 9h tối đến 6h sáng',
    'bé sốt 39 độ',
    'hôm nay con bú thế nào?',
    'thứ 6 đưa bé đi tiêm',
    'trời mưa, bé ngủ ngon',
    'mùa này bé hay ốm',
    'cảm ơn Lumi',
    'bé nặng 6kg',
  ])('%s → stays shareable', (text) => {
    expect(spendingSignalsIn(text)).toEqual([]);
  });
  it('taskVisibilityFor: a child text task with money words is private', () => {
    const base = {
      scope: { type: 'child' as const, babyId: 'b' },
      modality: 'text' as const,
      intentHint: null,
      role: 'coParent',
    };
    expect(taskVisibilityFor({ ...base, text: 'bé bú 120ml' })).toBe('shared');
    expect(taskVisibilityFor({ ...base, text: 'bé bú 120ml, mua sữa 500k' })).toBe('private');
    expect(taskVisibilityFor({ ...base, text: null })).toBe('shared');
  });
});

describe('durations and "trước"', () => {
  const mins = (t: string) => durationsIn(t).map((d) => d.minutes);
  it.each([
    ['Báo ngủ 9 tiếng', [540]],
    ['ngủ trưa 1 tiếng rưỡi', [90]],
    ['ngu trua 1 tieng ruoi', [90]],
    ['bú 15 phút', [15]],
    ['bú 15p bên trái', [15]],
    ['ngủ 1 tiếng 15 phút', [75]],
    ['nửa tiếng', [30]],
    ['ngủ được 2 giờ', [120]],
    ['slept 2 hours', [120]],
    ['nursed for 20 mins', [20]],
    ['an hour', [60]],
    ['ngủ hai tiếng', [120]],
  ])('%s → %j', (text, expected) => {
    expect(mins(text)).toEqual(expected);
  });
  it('a clock time is not a duration', () => {
    expect(mins('9h ngủ đến 10h')).toEqual([]);
    expect(mins('lúc 2 giờ')).toEqual([]);
  });
  it('ago / just now', () => {
    expect(agoIn('2 tiếng trước bé bú 4oz')).toMatchObject({ minutes: 120, justNow: false });
    expect(agoIn('30 phút trước')).toMatchObject({ minutes: 30 });
    expect(agoIn('2 hours ago')).toMatchObject({ minutes: 120 });
    expect(agoIn('vừa bú mẹ 20 phút')).toMatchObject({ minutes: 0, justNow: true });
    expect(agoIn('bú 15 phút trước khi ngủ')).toBeNull();
    expect(agoIn('bé bú 120ml')).toBeNull();
  });
  it('spans: two of start / end / duration give the third, overnight included', () => {
    const h = 3_600_000;
    expect(completeSpan({ start: 0, end: null, durationMin: 540 })).toMatchObject({
      end: 9 * h,
      derived: 'end',
    });
    expect(completeSpan({ start: null, end: 9 * h, durationMin: 540 })).toMatchObject({
      start: 0,
      derived: 'start',
    });
    expect(completeSpan({ start: 0, end: 2 * h, durationMin: null })).toMatchObject({
      durationMin: 120,
      derived: 'duration',
    });
    expect(completeSpan({ start: 0, end: 2 * h, durationMin: 60 }).inconsistent).toBe(true);
  });
});

describe('clock times, day periods, relative dates', () => {
  it.each([
    ['21h', '21:00', true],
    ['21:30', '21:30', true],
    ['9h tối', '21:00', true],
    ['9 giờ rưỡi tối', '21:30', true],
    ['10pm', '22:00', true],
    ['8h sáng', '08:00', true],
    ['12h trưa', '12:00', true],
    ['1h trưa', '13:00', true],
    ['2h đêm', '02:00', true],
    ['11h đêm', '23:00', true],
    ['9h', '09:00', false],
    ['9 giờ kém 15', '08:45', false],
  ])('%s → %s (explicit %s)', (text, hhmm, explicit) => {
    expect(clockTimeIn(text)).toMatchObject({ hhmm, explicit });
  });
  it('day offsets in an answer', () => {
    expect(clockTimeIn('22h tối qua')).toMatchObject({ hhmm: '22:00', dayOffset: -1 });
    expect(clockTimeIn('nửa đêm')).toMatchObject({ hhmm: '00:00', explicit: true });
  });
  it('day periods with or without diacritics', () => {
    expect(hasDayPeriod('lúc 8h sáng')).toBe(true);
    expect(hasDayPeriod('luc 9h sang')).toBe(true);
    expect(hasDayPeriod('toi qua bu 100ml')).toBe(true);
    expect(hasDayPeriod('at 3pm')).toBe(true);
    expect(hasDayPeriod('8 giờ bú 120ml')).toBe(false);
    expect(hasDayPeriod('sang nha ba luc 8h')).toBe(false);
  });
  it.each([
    ['nhắc mai 9h mua bỉm', 'future', '2026-10-16'],
    ['ngày mai', 'future', '2026-10-16'],
    ['thứ 6 đưa bé đi tiêm', 'future', '2026-10-16'],
    ['nhắc thứ 2 tuần sau đưa bé đi khám', 'future', '2026-10-19'],
    ['tuần sau thứ 6', 'future', '2026-10-23'],
    ['chủ nhật', 'future', '2026-10-18'],
    ['ngày 20/10 tiêm', 'future', '2026-10-20'],
    ['ngày 20 tháng 10', 'future', '2026-10-20'],
    ['mốt đi khám', 'future', '2026-10-17'],
    ['hôm qua mua bỉm', 'past', '2026-10-14'],
    ['tối qua 10h', 'past', '2026-10-14'],
    ['hôm kia', 'past', '2026-10-13'],
    ['thứ 2 mua sữa', 'past', '2026-10-12'],
    ['Remind me tomorrow at 8am', 'future', '2026-10-16'],
    ['yesterday', 'past', '2026-10-14'],
    ['chiều nay 5 giờ', 'future', '2026-10-15'],
  ])('%s (%s) → %s', (text, direction, date) => {
    expect(relativeDateIn(text, TODAY, direction as 'future' | 'past')?.date).toBe(date);
  });
  it('a weekday equal to today is uncertain; ranges and amounts are not dates', () => {
    expect(relativeDateIn('thứ 5', TODAY, 'future')).toMatchObject({
      date: '2026-10-22',
      certain: false,
    });
    expect(relativeDateIn('napped 2-3:30', TODAY, 'past')).toBeNull();
    expect(relativeDateIn('1.2tr tiền khám', TODAY, 'past')).toBeNull();
    expect(relativeDateIn('bú 2-3 lần', TODAY, 'past')).toBeNull();
    expect(relativeDateIn('nhắn Mai mua sữa', TODAY, 'future')).toBeNull();
    expect(relativeDateIn('bé bú 120ml', TODAY, 'past')).toBeNull();
  });
});

describe('small talk, categories, medicine, bottle units, sides', () => {
  it.each([
    ['cảm ơn Lumi', 'thanks'],
    ['Cám ơn nhé!', 'thanks'],
    ['Thanks!', 'thanks'],
    ['chào Lumi', 'greeting'],
    ['ok', 'ack'],
    ['👍', 'ack'],
    ['vừa ghi rồi', 'ack'],
    ['tạm biệt', 'bye'],
  ])('%s → %s', (text, kind) => {
    expect(smallTalkIn(text)).toBe(kind);
  });
  it.each([
    'ok bé bú 120ml',
    'cảm ơn, nhắc mai 9h mua bỉm',
    'hôm nay con bú thế nào?',
    'giúp mình với',
    'thời tiết hôm nay thế nào?',
  ])('%s → not small talk', (text) => {
    expect(smallTalkIn(text)).toBeNull();
  });
  it.each([
    ['Mua sữa hết 500k', 'c_milk'],
    ['50 nghìn tã', 'c_diaper'],
    ['mua bỉm', 'c_diaper'],
    ['$20 diapers', 'c_diaper'],
    ['1.2tr tiền khám cho bé', 'c_health'],
    ['đóng tiền học bơi', 'c_childcare'],
    ['tiền trông trẻ', 'c_childcare'],
    ['mua quần áo cho bé', 'c_clothes'],
    ['trả 200k tiền điện nước', null],
  ])('%s → %s', (text, id) => {
    expect(categoryHintIn(text)).toBe(id);
  });
  it('"what can the baby eat" questions are recognised', () => {
    expect(asksWhatToEat('con 7 tháng ăn gì được?')).toBe(true);
    expect(asksWhatToEat('gợi ý món ăn dặm cho bé')).toBe(true);
    expect(asksWhatToEat('what can she eat at 8 months?')).toBe(true);
    expect(asksWhatToEat('bé bú 120ml')).toBe(false);
    expect(asksWhatToEat('hôm nay con bú thế nào?')).toBe(false);
  });
  it('medicine reminders are recognised', () => {
    expect(mentionsMedicine('nhắc 8h cho bé uống thuốc')).toBe(true);
    expect(mentionsMedicine('siro ho 5ml')).toBe(true);
    expect(mentionsMedicine('give her the medicine at 8')).toBe(true);
    expect(mentionsMedicine('thứ 6 đưa bé đi tiêm')).toBe(false);
  });
  it('bottle amounts: ml, oz → ml', () => {
    expect(bottleMlIn('bú 120ml')).toEqual({ ml: 120, fromOz: false });
    expect(bottleMlIn('4oz')).toEqual({ ml: 118, fromOz: true });
    expect(bottleMlIn('5 oz')).toEqual({ ml: 148, fromOz: true });
  });
  it('breast sides', () => {
    expect(breastSideIn('bên trái')).toBe('left');
    expect(breastSideIn('ben phai')).toBe('right');
    expect(breastSideIn('cả hai bên')).toBe('both');
    expect(breastSideIn('right side')).toBe('right');
    expect(breastSideIn('bú 15 phút')).toBeNull();
  });
});
