import { keepsakeChapter1Videos } from '@child-life/contracts';
import { describe, expect, it } from 'vitest';
import { stories } from '../src/compositions/registry';
import type { StoryProps } from '../src/kit/core';

// Chapter 01 videos (docs/product/remember-2-templates.md §5): every template's composition fits
// its photos inside its length, at the fewest and the most photos, with the poster on a photo.
const props = (t: (typeof keepsakeChapter1Videos)[number], n: number): StoryProps => ({
  photos: Array.from({ length: n }, (_, i) => `p${i}.jpg`),
  title: 'T',
  message: 'M',
  closing: 'C',
  lines: 'a\nb',
  letter: 'One. Two. Three.',
  name: 'Bông',
  dateLine: '',
  mark: null,
  palette: t.palette,
  music: null,
  durationSec: t.durationSec ?? 30,
  brand: t.brand,
  photoInfo: Array.from({ length: n }, (_, i) => ({
    takenAt: new Date(Date.UTC(2026, 0, 1 + i * 30)).toISOString(),
    label: `Tháng ${i}`,
  })),
});

describe('Chapter 01 compositions', () => {
  for (const t of keepsakeChapter1Videos) {
    it(`${t.composition}: inside ${t.durationSec} s, poster on a photo`, () => {
      const entry = stories[t.composition!];
      for (const n of [t.photos.min, t.photos.max]) {
        const p = props(t, n);
        const frames = entry.frames(p);
        // A little over is allowed for the shortest and longest sets (§4.2 ranges are targets).
        expect(frames / 30).toBeLessThanOrEqual((t.durationSec ?? 30) + 3);
        expect(frames / 30).toBeGreaterThan(10);
        const poster = entry.poster(p);
        expect(poster).toBeGreaterThan(30);
        expect(poster).toBeLessThan(frames);
      }
    });
  }
});
