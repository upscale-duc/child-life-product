import { describe, expect, it } from 'vitest';
import {
  premium48Phase4,
  keepsakeTemplateSchema,
  resolveKeepsakeCopy,
  freezeKeepsakePresentation,
} from '../src/index.js';
import fixtures from './vectors/premium48-phase4.json';
describe('Premium 48 phase 4', () => {
  it('delivers two cards and two videos with distinct media counts and retained branding', () => {
    const ts = premium48Phase4();
    expect(ts.map((t) => t.id)).toEqual([
      'card_premium48_07',
      'card_premium48_08',
      'video_premium48_07',
      'video_premium48_08',
    ]);
    expect(ts.map((t) => t.photos.max)).toEqual([3, 2, 5, 2]);
    for (const t of ts) {
      expect(t.personalization!.group).toEqual({ vi: 'Lớn từng ngày', en: 'Growing Every Day' });
      expect(keepsakeTemplateSchema.safeParse(t).success).toBe(true);
      if (t.kind === 'video') {
        expect(t.durationSec).toBe(35);
        expect(t.brand).toEqual({ corner: true, endCard: true, opacity: 0.75 });
      }
    }
  });
  for (const f of fixtures.cases)
    it(`${f.id}/${f.locale} matches Dart for ${f.values.thenDate || f.values.monthNumber || 'unknown dates'}`, () => {
      expect(
        resolveKeepsakeCopy(
          premium48Phase4().find((t) => t.id === f.id)!.personalization!,
          f.values,
          f.locale as 'vi' | 'en',
        ),
      ).toEqual(f.expected);
    });
  it('accepts months 01–12 and rejects zero, 13, fractional or fabricated month values', () => {
    const spec = premium48Phase4()[0]!.personalization!;
    for (let m = 1; m <= 12; m++)
      expect(
        resolveKeepsakeCopy(spec, { babyName: 'An', monthNumber: String(m) }, 'en').ageNumber,
      ).toBe(String(m).padStart(2, '0'));
    for (const m of ['', '0', '13', '-1', '1.5', 'xx'])
      expect(() => resolveKeepsakeCopy(spec, { babyName: 'An', monthNumber: m }, 'en')).toThrow();
    expect(resolveKeepsakeCopy(spec, { babyName: 'An', monthNumber: '01' }, 'en').message).toBe(
      'Something new, every day.',
    );
    expect(resolveKeepsakeCopy(spec, { babyName: 'An', monthNumber: '01' }, 'en').detail0).toBe('');
  });
  it('does not invent dates or an interval when either date is missing', () => {
    for (const t of premium48Phase4().filter((t) => t.id.endsWith('_08')))
      for (const locale of ['vi', 'en'] as const)
        for (const dates of [{}, { thenDate: '2026-09-01' }, { nowDate: '2026-10-01' }]) {
          const copy = resolveKeepsakeCopy(
            t.personalization!,
            { babyName: 'An', ...dates },
            locale,
          );
          expect(copy.photoLabel0).toBe(locale === 'vi' ? 'Ngày ấy' : 'Then');
          expect(copy.photoLabel1).toBe(locale === 'vi' ? 'Bây giờ' : 'Now');
          expect(copy.detail1).toBe('');
          expect(copy.detail2).toBe('');
        }
  });
  it('derives exact UTC day counts, including zero, one, leap years and daylight-saving boundaries', () => {
    const spec = premium48Phase4()[1]!.personalization!;
    for (const [start, end, count] of [
      ['2026-07-01', '2026-10-01', '92'],
      ['2026-10-01', '2026-10-01', '0'],
      ['2024-02-28', '2024-02-29', '1'],
      ['2024-02-28', '2024-03-01', '2'],
      ['2026-03-07', '2026-03-09', '2'],
    ]) {
      const copy = resolveKeepsakeCopy(
        spec,
        { babyName: 'An', thenDate: start!, nowDate: end! },
        'en',
      );
      expect(copy.detail1).toBe(count);
      expect(copy.detail2).toBe(count === '1' ? 'day' : 'days');
    }
    expect(() =>
      resolveKeepsakeCopy(
        spec,
        { babyName: 'An', thenDate: '2026-10-01', nowDate: '2026-09-01' },
        'en',
      ),
    ).toThrow('date-order');
    expect(() =>
      resolveKeepsakeCopy(
        spec,
        { babyName: 'An', thenDate: '2026-02-30', nowDate: '2026-03-01' },
        'en',
      ),
    ).toThrow('date');
    expect(() => resolveKeepsakeCopy(spec, { babyName: 'An', elapsedDays: '999' }, 'en')).toThrow(
      'field',
    );
    expect(() => resolveKeepsakeCopy(spec, { babyName: 'An' }, 'en', { detail1: '999' })).toThrow(
      'copy',
    );
  });
  it('uses exactly two selected photos for all five V08 beats and keeps the second crop independent', () => {
    const spec = premium48Phase4()[3]!.personalization!;
    expect(spec.beats.map((b) => b.slots)).toEqual([[0], [0], [0, 1], [1], [0, 1]]);
    const crops = Array.from({ length: 5 }, (_, i) => ({
      x: i * 0.1,
      y: 0,
      zoom: 1 + i * 0.1,
      fit: 'contain',
    }));
    const frozen = freezeKeepsakePresentation(
      spec,
      { values: { babyName: 'An' }, overrides: {}, crops, format: 'story', reducedMotion: false },
      'en',
    );
    expect(frozen.crops[1]).toEqual(crops[1]);
    expect(frozen.crops[1]).not.toEqual(frozen.crops[0]);
    expect(premium48Phase4()[2]!.personalization!.beats[4]!.slots).toEqual([4, 0, 1, 2, 3]);
  });
});
