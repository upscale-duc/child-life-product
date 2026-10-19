import { describe, expect, it } from 'vitest';
import { agoIn, careStatesIn, dayHalfAnswerIn, hourInDayHalf } from '../src/assistant-text.js';

// L1 (D-088, P-167 #1–#3): the device case of 2026-10-19 and its neighbours.
const states = (text: string) =>
  careStatesIn(text).map(
    (s) =>
      `${s.timer}:${s.action}${s.side ? `:${s.side}` : ''}${s.sinceMin !== null ? `@${s.sinceMin}` : ''}`,
  );

describe('careStatesIn: a state still going on starts its timer, even with a length', () => {
  it.each([
    ['Bé đang ngủ. Vừa ngủ được 5p rồi', ['sleep:start@5']],
    ['Đang ngủ và ngủ cách đây 5p', ['sleep:start@5']],
    ['con dang ngu duoc 5p roi', ['sleep:start@5']],
    ['bé ngủ được 2 tiếng rồi', ['sleep:start@120']],
    ['bé vẫn chưa dậy, ngủ được 1 tiếng rồi', ['sleep:start@60']],
    ['bé ngủ từ 11h20', ['sleep:start']],
    ['bé ngủ từ 9h đến giờ', ['sleep:start']],
    ['đang bú bên trái được 10 phút', ['breast:start:left@10']],
    ['đang cho bú 10 phút rồi', ['breast:start@10']],
    ['Con đang ngủ', ['sleep:start']],
  ])('%s', (text, want) => expect(states(text)).toEqual(want));

  it.each([
    // sl-08: it ended ("dậy"), so it is a finished sleep with its length.
    'vừa ngủ dậy, ngủ được 2 tiếng',
    'bé ngủ từ 21h tối qua, ngủ 9 tiếng',
    'bé ngủ từ 9h đến 11h',
    'bé ngủ 2 tiếng',
    'bé bú 15 phút xong',
    'đang cho bú 15 phút xong rồi',
  ])('finished, not a running state: %s', (text) => expect(states(text)).toEqual([]));
});

describe('agoIn: relative times (L1)', () => {
  it('reads "cách đây X", "X rồi", "được X rồi", "khoảng X trước"', () => {
    expect(agoIn('ngủ cách đây 5p')).toMatchObject({ minutes: 5, justNow: false });
    expect(agoIn('Vừa ngủ được 5p rồi')).toMatchObject({ minutes: 5, justNow: false });
    expect(agoIn('bé bú 15 phút rồi')).toMatchObject({ minutes: 15, justNow: false });
    expect(agoIn('khoảng nửa tiếng trước')).toMatchObject({ minutes: 30, justNow: false });
    expect(agoIn('cach day 1 tieng')).toMatchObject({ minutes: 60, justNow: false });
  });
  it('keeps "vừa" (about now) and words with no length', () => {
    expect(agoIn('vừa bú mẹ 20 phút')).toMatchObject({ minutes: 0, justNow: true });
    expect(agoIn('bé ngủ rồi')).toBeNull();
    expect(agoIn('bú 15 phút trước khi ngủ')).toBeNull();
  });
});

describe('dayHalfAnswerIn: a typed morning / evening answer', () => {
  it.each([
    // The device case: the first period word wins over "sáng hay tối" later on.
    ['Sáng. Hiện tại thì biết sáng hay tối chứ', 'am'],
    ['sang', 'am'],
    ['buổi sáng', 'am'],
    ['tối', 'pm'],
    ['chiều nha', 'pm'],
    ['pm', 'pm'],
    ['8am', 'am'],
    ['23:21', 'pm'],
    ['9h tối', 'pm'],
    ['trưa', 'noon'],
    ['đêm', 'night'],
    ['Morning', 'am'],
  ] as const)('%s → %s', (text, want) => expect(dayHalfAnswerIn(text)).toBe(want));

  it.each(['hả?', '11:21', 'ok', ''])('unreadable: %s', (text) =>
    expect(dayHalfAnswerIn(text)).toBeNull(),
  );

  it('keeps the hours of the half it names', () => {
    expect([8, 20].filter((h) => hourInDayHalf(h, 'am'))).toEqual([8]);
    expect([8, 20].filter((h) => hourInDayHalf(h, 'pm'))).toEqual([20]);
    expect([11, 23].filter((h) => hourInDayHalf(h, 'noon'))).toEqual([11]);
    expect([1, 13].filter((h) => hourInDayHalf(h, 'noon'))).toEqual([13]);
    expect([10, 22].filter((h) => hourInDayHalf(h, 'night'))).toEqual([22]);
    expect([2, 14].filter((h) => hourInDayHalf(h, 'night'))).toEqual([2]);
  });
});
