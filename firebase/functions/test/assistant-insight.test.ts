import { describe, expect, it } from 'vitest';
import { insightBasis, insightCaveat } from '../src/assistant-insight.js';

/** Hiểu con (D-151 #7): Lumi's 0-credit explanation reads the stored insight, nothing else. */
const longest = {
  kind: 'night_longest',
  direction: 'up',
  unit: 'minutes',
  value: 172,
  baselineValue: 141,
  delta: 31,
  recent: { from: '2026-10-19', to: '2026-10-25' },
  baseline: { from: '2026-10-12', to: '2026-10-18' },
  coverage: { valid: 6, total: 7 },
  baselineCoverage: { valid: 7, total: 7 },
  points: [
    ...Array.from({ length: 7 }, (_, i) => ({
      date: `2026-10-${12 + i}`,
      value: 141,
      reason: null,
    })),
    ...Array.from({ length: 7 }, (_, i) => ({
      date: `2026-10-${19 + i}`,
      value: i === 1 ? null : 172,
      reason: i === 1 ? 'no_sleep' : null,
    })),
  ],
  peak: { date: '2026-10-23', value: 185, startedAt: '2026-10-23T15:40:00.000Z' },
  authors: [
    { name: 'Mẹ', relation: 'mother' },
    { name: 'Ba', relation: 'father' },
  ],
  todayEligible: true,
  score: 1.5,
};
const doc = (extra: Record<string, unknown> = {}) => ({
  computedAt: new Date('2026-10-26T00:30:00Z'),
  items: [longest],
  progress: { validNights: 6, neededNights: 5 },
  ...extra,
});

describe('insightBasis', () => {
  it('explains the figures, the nights left out, the window and who logged', () => {
    const b = insightBasis(doc(), true);
    expect(b.kind).toBe('items');
    if (b.kind !== 'items') return;
    expect(b.link).toBe('/care/insights/night_longest');
    expect(b.rows[0]!.label).toBe('Khoảng ngủ đêm dài nhất đang dài hơn');
    const v = b.rows[0]!.value;
    expect(v).toContain('từ 18:00 đến 06:00');
    expect(v).toContain('6 đêm gần đây (19/10–25/10) trung bình 2 giờ 52 phút');
    expect(v).toContain('7 đêm trước đó (12/10–18/10) trung bình 2 giờ 21 phút');
    expect(v).toContain('Dài nhất là đêm 23/10: 3 giờ 5 phút');
    expect(v).toContain('Đêm 20/10 chưa ghi đủ nên không tính');
    expect(v).toContain('Ghi bởi Mẹ, Ba');
  });

  it('in English too', () => {
    const b = insightBasis(doc(), false);
    if (b.kind !== 'items') throw new Error(b.kind);
    expect(b.rows[0]!.label).toBe('Longest night stretch is getting longer');
    expect(b.rows[0]!.value).toContain('The last 6 nights (19/10–25/10) averaged 2 h 52 min');
  });

  it('not enough nights or nothing new is said plainly, with no figures', () => {
    expect(insightBasis(undefined, true)).toMatchObject({ kind: 'sparse' });
    expect(
      insightBasis(doc({ items: [], progress: { validNights: 2, neededNights: 5 } }), true),
    ).toMatchObject({ kind: 'sparse', text: expect.stringContaining('2/5') });
    expect(insightBasis(doc({ items: [] }), true)).toMatchObject({ kind: 'none' });
    // A broken item is skipped, never guessed.
    expect(insightBasis(doc({ items: [{ kind: 'night_longest' }] }), true).kind).toBe('none');
  });

  it('never claims a cause', () => {
    expect(insightCaveat(true)).toContain('chưa cho biết nguyên nhân');
    expect(insightCaveat(false)).toContain("can't tell the cause");
  });
});
