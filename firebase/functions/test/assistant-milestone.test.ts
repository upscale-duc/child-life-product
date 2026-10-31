import { describe, expect, it } from 'vitest';
import { milestoneSaidIn } from '../src/assistant-milestone.js';

// Lumi L5 (Mốc): the reference milestone a new skill names, read with its diacritics.
describe('milestoneSaidIn', () => {
  it.each([
    ['bé biết lẫy rồi', 'rolls_over'],
    ['hôm nay bé biết ngồi', 'sits_up'],
    ['be biet bo roi', 'crawls'],
    ['bé bò được rồi', 'crawls'],
    ['bé vịn đứng được rồi', 'stands'],
    ['con đi men theo thành giường', 'cruises'],
    ['bé tự đi được 3 bước', 'first_steps'],
    ['bé biết gọi bố rồi', 'first_word'],
    ['bé cười thành tiếng lần đầu', 'laughs'],
    ['bé biết vẫy tay bai bai', 'waves_bye'],
    ['she rolled over today', 'rolls_over'],
    ['he took his first steps', 'first_steps'],
  ])('%s', (text, id) => expect(milestoneSaidIn(text)).toBe(id));

  it.each(['bé biết gọi bố', 'bé hôm nay vui', 'bé ngủ ngon', 'bé thích tắm'])(
    'not crawling or nothing: %s',
    (text) => expect(milestoneSaidIn(text)).not.toBe('crawls'),
  );

  it('nothing for a skill the reference list lacks', () => {
    expect(milestoneSaidIn('bé biết nói cảm ơn')).toBeNull();
  });
});
