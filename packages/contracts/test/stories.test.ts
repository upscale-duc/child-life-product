import { describe, expect, it } from 'vitest';
import {
  guardAiText,
  storyAssistSchema,
  storyBlockSchema,
  storyMediaIds,
  type StorySources,
} from '../src/index.js';

const sources: StorySources = {
  nickname: 'Teddy',
  locale: 'vi',
  rangeStart: '2026-10-01',
  rangeEnd: '2026-10-08',
  photos: 9,
  videos: 1,
  milestone: { name: 'Lần đầu cười', date: '2026-10-05' },
  notes: [{ date: '2026-10-05', text: 'Sáng thứ Hai Teddy cười khi mẹ hát ru.', by: 'Mẹ' }],
  people: ['Mẹ', 'Ba'],
};

describe('story guardrails (P-092, R-136)', () => {
  it('accepts text built from the sources', () => {
    expect(
      guardAiText(
        'Sáng thứ Hai, khi Mẹ hát ru, Teddy cười. Tuần này có 9 ảnh từ 1 tháng 10.',
        sources,
      ),
    ).toEqual([]);
  });

  it('flags invented numbers, names and links', () => {
    expect(guardAiText('Teddy nặng 7 ký vào ngày 12.', sources)).toEqual(
      expect.arrayContaining(['number:7', 'number:12']),
    );
    expect(guardAiText('Hôm đó cô Lan bế Teddy ra Hà Nội.', sources)).toEqual(
      expect.arrayContaining(['name:Lan', 'name:Hà', 'name:Nội']),
    );
    expect(guardAiText('Xem thêm ở https://x.y', sources)).toContain('link');
  });
});

describe('story shapes', () => {
  it('photo groups hold 1–4 memories (R-133)', () => {
    const photo = (n: number) => ({ mediaId: `med_${String(n).padStart(32, '0')}`, caption: null });
    expect(
      storyBlockSchema.safeParse({ id: 'b1', type: 'photos', items: [1, 2, 3, 4].map(photo) })
        .success,
    ).toBe(true);
    expect(
      storyBlockSchema.safeParse({ id: 'b1', type: 'photos', items: [1, 2, 3, 4, 5].map(photo) })
        .success,
    ).toBe(false);
    expect(storyBlockSchema.safeParse({ id: 'b1', type: 'photos', items: [] }).success).toBe(false);
  });

  it('media ids: cover first, no repeats', () => {
    const a = `med_${'a'.repeat(32)}`;
    const b = `med_${'b'.repeat(32)}`;
    expect(
      storyMediaIds({
        coverMediaId: a,
        blocks: [
          { id: 'b0', type: 'paragraph', text: 'x', ai: false },
          {
            id: 'b1',
            type: 'photos',
            items: [
              { mediaId: a, caption: null },
              { mediaId: b, caption: 'c' },
            ],
          },
        ],
      }),
    ).toEqual([a, b]);
  });

  it('assist ops are the drawn ones (R-132)', () => {
    const base = {
      babyId: 'b_00000000000000000001',
      storyId: `sto_${'1'.repeat(32)}`,
      blockId: 'b1',
      text: 'x',
      locale: 'vi',
    };
    for (const op of ['rewrite', 'shorter', 'warmer', 'suggest']) {
      expect(storyAssistSchema.safeParse({ ...base, op }).success).toBe(true);
    }
    expect(storyAssistSchema.safeParse({ ...base, op: 'translate' }).success).toBe(false);
  });
});
