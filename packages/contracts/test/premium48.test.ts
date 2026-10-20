import { describe, expect, it } from 'vitest';
import {
  freezeKeepsakePresentation,
  premium48Phase1,
  resolveKeepsakeCopy,
  keepsakeTemplateSchema,
} from '../src/index.js';
import fixtures from './vectors/premium48.json';

describe('Premium 48 phase 1', () => {
  it('only ships two cards and two videos, with distinct IDs and existing logo', () => {
    const ts = premium48Phase1();
    expect(ts.filter((t) => t.kind === 'card')).toHaveLength(2);
    expect(ts.filter((t) => t.kind === 'video')).toHaveLength(2);
    for (const t of ts) {
      expect(t.tier).toBe('premium');
      if (t.kind === 'video')
        expect(t.brand).toEqual({ corner: true, endCard: true, opacity: 0.75 });
      else
        for (const layers of Object.values(t.layouts!))
          expect(layers!.filter((l) => l.type === 'brand')).toHaveLength(1);
    }
  });
  for (const test of fixtures.cases)
    it(`${test.id}/${test.locale}/${test.values.firstConfirmed ?? 'birth'} matches shared Dart fixtures`, () => {
      const spec = premium48Phase1().find((t) => t.id === test.id)!.personalization!;
      expect(resolveKeepsakeCopy(spec, test.values, test.locale as 'vi' | 'en')).toEqual(
        test.expected,
      );
    });
  it('unknown dates are omitted; an unconfirmed first is rewritten in every locale', () => {
    for (const t of premium48Phase1())
      for (const locale of ['vi', 'en'] as const) {
        const result = resolveKeepsakeCopy(t.personalization!, { babyName: 'An' }, locale);
        expect(result.detail0 ?? '').toBe('');
        expect(Object.values(result).some((v) => /[{}]/.test(v))).toBe(false);
        if (t.id.endsWith('_02')) expect(result.title.toLowerCase()).not.toMatch(/first|lần đầu/);
      }
  });
  it('validates fields, dates, tokens, output edits and explicit crops before queuing', () => {
    const spec = premium48Phase1()[2]!.personalization!;
    expect(() =>
      resolveKeepsakeCopy(spec, { babyName: 'An', birthDate: '2026-02-30' }, 'vi'),
    ).toThrow();
    expect(() => resolveKeepsakeCopy(spec, { babyName: 'An', birthTime: '25:00' }, 'vi')).toThrow();
    expect(() => resolveKeepsakeCopy(spec, { babyName: '{name}' }, 'en')).toThrow();
    expect(() => resolveKeepsakeCopy(spec, { babyName: 'An', unexpected: 'x' }, 'vi')).toThrow();
    expect(() =>
      resolveKeepsakeCopy(spec, { babyName: 'An' }, 'en', { scene1: '{birthDate}' }),
    ).toThrow();
    expect(() =>
      resolveKeepsakeCopy(spec, { babyName: 'An' }, 'en', { scene1: 'x'.repeat(161) }),
    ).toThrow();
    expect(() =>
      freezeKeepsakePresentation(
        spec,
        {
          values: { babyName: 'An' },
          overrides: {},
          crops: [],
          format: 'story',
          reducedMotion: false,
        },
        'vi',
      ),
    ).toThrow();
    const frozen = freezeKeepsakePresentation(
      spec,
      {
        values: { babyName: 'An' },
        overrides: { scene1: 'My own words' },
        crops: Array.from({ length: 5 }, () => ({ x: 0, y: 0, zoom: 1 })),
        format: 'portrait',
        reducedMotion: true,
      },
      'en',
    );
    expect(frozen.copy.scene1).toBe('My own words');
    expect(frozen.format).toBe('portrait');
  });
  it('preserves locale-specific preview and thumbnail assets through validation', () => {
    const t = premium48Phase1()[2]!;
    const parsed = keepsakeTemplateSchema.parse({
      ...t,
      previews: { vi: 'p48-vi_12345678.mp4', en: 'p48-en_12345678.mp4' },
      thumbs: { vi: 'p48-vi_12345678.webp', en: 'p48-en_12345678.webp' },
    });
    expect(parsed.previews?.en).toBe('p48-en_12345678.mp4');
    expect(
      keepsakeTemplateSchema.safeParse({
        ...premium48Phase1()[0]!,
        previews: { vi: 'p48-vi_12345678.mp4' },
      }).success,
    ).toBe(false);
  });
  it('keeps media slots separate from beats and rejects references to unselected slots', () => {
    const t = premium48Phase1()[3]!;
    expect(t.photos).toEqual({ min: 4, max: 4 });
    expect(t.personalization!.beats.map((b) => b.slots[0])).toEqual([0, 1, 2, 3, 2]);
    const changed = structuredClone(t);
    changed.personalization!.beats[4]!.slots = [4];
    expect(keepsakeTemplateSchema.safeParse(changed).success).toBe(false);
  });
});
