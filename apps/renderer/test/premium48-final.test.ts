import { describe, expect, it } from 'vitest';
import { premium48FinalFrame, premium48MonthSlot } from '../src/compositions/premium48-final';
import { stories } from '../src/compositions/registry';
import { premium48FinalDesigns } from '@child-life/contracts';
import type { StoryProps } from '../src/kit/core';
describe('Final premium compositions', () => {
  it('registers all twelve stories with exact durations and settled posters', () => {
    for (const d of premium48FinalDesigns) {
      expect(stories[d.composition].frames({} as StoryProps)).toBe(d.n === 22 ? 1500 : 1050);
      expect(stories[d.composition].poster({} as StoryProps)).toBe(d.n === 22 ? 1440 : 990);
    }
  });
  it('keeps transitions within the five authored beats', () => {
    for (const n of [13, 22, 24]) {
      const ends = n === 22 ? [329, 659, 989, 1319, 1499] : [209, 419, 629, 839, 1049];
      ends.forEach((end, beat) => {
        expect(premium48FinalFrame(n, end).beat).toBe(beat);
        if (beat < 4) expect(premium48FinalFrame(n, end + 1).beat).toBe(beat + 1);
      });
    }
  });
  it('uses the full 50-second month cue sheet, with no accelerated final month', () => {
    for (const [frame, slot] of [
      [0, null],
      [44, null],
      [45, 0],
      [119, 0],
      [120, 1],
      [195, 2],
      [270, null],
      [330, 3],
      [405, 4],
      [480, 5],
      [555, null],
      [660, 6],
      [735, 7],
      [810, 8],
      [885, null],
      [990, 9],
      [1065, 10],
      [1140, 11],
      [1215, null],
      [1320, null],
      [1409, null],
      [1410, 11],
      [1499, 11],
    ] as const)
      expect(premium48MonthSlot(frame), String(frame)).toBe(slot);
  });
});
