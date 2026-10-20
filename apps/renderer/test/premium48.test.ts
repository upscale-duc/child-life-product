import { premium48Phase5Slots } from '../src/compositions/premium48-phase5';
import { describe, expect, it } from 'vitest';
import { premium48Frame, PREMIUM48_FRAMES, PREMIUM48_POSTER } from '../src/compositions/premium48';
import { stories } from '../src/compositions/registry';
import { premium48Phase4Slots } from '../src/compositions/premium48-phase4';
import { premium48Phase2Slots } from '../src/compositions/premium48-phase2';
import type { StoryProps } from '../src/kit/core';

describe('Premium phase 1 timeline', () => {
  it('owns exactly 1050 frames, with every boundary inside its beat (no duration added for crossfades)', () => {
    expect(PREMIUM48_FRAMES).toBe(35 * 30);
    for (let beat = 0; beat < 5; beat++) {
      expect(premium48Frame(beat * 210)).toEqual({ beat, local: 0 });
      expect(premium48Frame(beat * 210 + 209)).toEqual({ beat, local: 209 });
    }
    expect(premium48Frame(PREMIUM48_POSTER)).toEqual({ beat: 4, local: 150 });
  });
  it('registers both distinct compositions with a settled closing poster', () => {
    for (const id of [
      'PremiumArrival',
      'PremiumEmbrace',
      'PremiumHomecoming',
      'PremiumFirstMonth',
      'PremiumLittleThings',
      'PremiumMonthLetter',
      'PremiumMonthlyChapter',
      'PremiumThenNow',
      'PremiumOutgrownKeepsake',
      'PremiumSmileToKeep',
    ] as const) {
      expect(stories[id].frames({} as StoryProps)).toBe(1050);
      expect(stories[id].poster({} as StoryProps)).toBe(990);
    }
  });
  it('keeps the three-photo smile reprise explicit', () => {
    expect(Array.from({ length: 5 }, (_, i) => premium48Phase5Slots(true, i))).toEqual([
      [0],
      [1],
      [2, 1],
      [1],
      [1],
    ]);
    expect(premium48Phase5Slots(false, 3)).toEqual([3, 0]);
  });
  it('keeps the phase 4 two-photo story and five-photo closing grid explicit', () => {
    expect(Array.from({ length: 5 }, (_, i) => premium48Phase4Slots(true, i))).toEqual([
      [0],
      [0],
      [0, 1],
      [1],
      [0, 1],
    ]);
    expect(premium48Phase4Slots(false, 4)).toEqual([4, 0, 1, 2, 3]);
  });
  it('keeps the scrapbook reprise explicit and never cycles photos to fill a beat', () => {
    expect(Array.from({ length: 5 }, (_, i) => premium48Phase2Slots(true, i))).toEqual([
      [0],
      [1, 0],
      [2, 1],
      [3, 2, 1],
      [4],
    ]);
    expect(Array.from({ length: 5 }, (_, i) => premium48Phase2Slots(false, i))).toEqual([
      [0],
      [1],
      [2],
      [3],
      [4],
    ]);
  });
});
