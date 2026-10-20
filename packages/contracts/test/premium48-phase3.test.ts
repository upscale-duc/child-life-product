import { describe, expect, it } from 'vitest';
import {
  premium48Phase3,
  keepsakeTemplateSchema,
  resolveKeepsakeCopy,
  freezeKeepsakePresentation,
  keepsakeTemplateAssets,
} from '../src/index.js';
import fixtures from './vectors/premium48-phase3.json';
describe('Premium 48 phase 3', () => {
  it('delivers C05/C06/V05/V06 with original art, month grouping and retained branding', () => {
    const ts = premium48Phase3();
    expect(ts.map((t) => t.id)).toEqual([
      'card_premium48_05',
      'card_premium48_06',
      'video_premium48_05',
      'video_premium48_06',
    ]);
    expect(ts.map((t) => t.photos.max)).toEqual([1, 1, 5, 5]);
    for (const t of ts) {
      expect(t.personalization!.group).toEqual({ vi: 'Tháng đầu', en: 'Our First Month' });
      expect(t.tier).toBe('premium');
      if (t.kind === 'video') {
        expect(t.durationSec).toBe(35);
        expect(t.brand).toEqual({ corner: true, endCard: true, opacity: 0.75 });
        expect(t.personalization!.beats.map((b) => b.slots)).toEqual([[0], [1], [2], [3], [4]]);
      } else
        for (const layers of Object.values(t.layouts!))
          expect(layers!.filter((l) => l.type === 'brand')).toHaveLength(1);
    }
    for (const t of fixtures.templates) {
      const parsed = keepsakeTemplateSchema.parse(t);
      for (const asset of Object.values(t.assets))
        expect(keepsakeTemplateAssets(parsed)).toContain(asset);
    }
  });
  for (const f of fixtures.cases)
    it(`${f.id}/${f.locale} matches Dart fixtures with ${f.values.favoriteThing ? 'accepted' : 'empty'} notes`, () => {
      const t = premium48Phase3().find((t) => t.id === f.id)!;
      expect(resolveKeepsakeCopy(t.personalization!, f.values, f.locale as 'vi' | 'en')).toEqual(
        f.expected,
      );
    });
  it('does not assign proposed preferences until the parent supplies or explicitly adopts them', () => {
    const ts = premium48Phase3();
    for (const locale of ['vi', 'en'] as const) {
      const spec = ts[2]!.personalization!;
      const neutral = resolveKeepsakeCopy(spec, { babyName: 'An' }, locale);
      expect(neutral.scene2).toBe(
        locale === 'vi'
          ? 'Mình vẫn đang khám phá điều con thích.'
          : 'We are still discovering what you love.',
      );
      expect(neutral.scene2).not.toContain('cuddles');
      const accepted = Object.fromEntries(
        spec.fields.map((f) => [
          f.key,
          f.key === 'babyName' ? 'An' : (f.suggestion?.[locale] ?? ''),
        ]),
      );
      expect(resolveKeepsakeCopy(spec, accepted, locale).scene2).toContain(
        locale === 'vi' ? 'những cái ôm' : 'cuddles',
      );
    }
  });
  it('keeps the entire letter editable and uses a localized family signature when the writer is omitted', () => {
    for (const locale of ['vi', 'en'] as const)
      for (const t of premium48Phase3().filter((t) => t.id.endsWith('_06'))) {
        const copy = resolveKeepsakeCopy(t.personalization!, { babyName: 'An' }, locale);
        expect(copy.signature).toBe(
          locale === 'vi' ? 'Thương con, Nhà mình.' : 'With love, Your family.',
        );
        const key = t.kind === 'card' ? 'message' : 'scene4';
        expect(
          resolveKeepsakeCopy(t.personalization!, { babyName: 'An' }, locale, {
            [key]: 'Our own letter.',
          })[key],
        ).toBe('Our own letter.');
      }
  });
  it('freezes the chosen detail crop, language and words instead of guessing from the photo', () => {
    const t = premium48Phase3()[2]!;
    const frozen = freezeKeepsakePresentation(
      t.personalization!,
      {
        values: { babyName: 'An', littleDetail: 'tiny fingers' },
        overrides: { scene3: 'The detail we chose.' },
        crops: Array.from({ length: 5 }, () => ({ x: 0.4, y: -0.6, zoom: 1.8, fit: 'contain' })),
        format: 'portrait',
        reducedMotion: true,
      },
      'en',
    );
    expect(frozen.copy.scene3).toBe('The detail we chose.');
    expect(frozen.crops[2]).toEqual({ x: 0.4, y: -0.6, zoom: 1.8, fit: 'contain' });
    expect(frozen.reducedMotion).toBe(true);
  });
});
