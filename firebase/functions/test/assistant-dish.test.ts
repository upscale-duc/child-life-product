import { describe, expect, it } from 'vitest';
import { dishOf } from '../src/assistant-text.js';

// Lumi L5: the meal's dish as the Ăn dặm diary keeps it, whatever sentence the model returned.
describe('dishOf', () => {
  it.each([
    ['bé vừa ăn chuối', 'chuối'],
    ['trưa nay bé ăn cháo bí đỏ lúc 11h30', 'cháo bí đỏ'],
    ['cháo bí đỏ', 'cháo bí đỏ'],
    ['cho bé ăn thử bơ rồi', 'bơ'],
    ['bữa trưa ăn cháo cà rốt thịt gà', 'cháo cà rốt thịt gà'],
    ['baby ate banana this morning', 'banana'],
    ['ăn', 'ăn'],
  ])('%s → %s', (said, dish) => expect(dishOf(said)).toBe(dish));
});
