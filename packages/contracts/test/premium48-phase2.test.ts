import { describe, expect, it } from 'vitest';
import {
  premium48Phase1,
  premium48Phase2,
  keepsakeTemplateAssets,
  keepsakeTemplateSchema,
  freezeKeepsakePresentation,
  resolveKeepsakeCopy,
} from '../src/index.js';
import fixtures from './vectors/premium48-phase2.json';

describe('Premium 48 phase 2', () => {
  it('adds exactly 2 cards and 2 videos with distinct IDs, group names and retained branding', () => {
    const ts = premium48Phase2();
    expect(ts.map((t) => t.id)).toEqual([
      'card_premium48_03',
      'card_premium48_04',
      'video_premium48_03',
      'video_premium48_04',
    ]);
    expect(ts.some((t) => premium48Phase1().some((old) => old.id === t.id))).toBe(false);
    expect(ts.slice(0, 2).map((t) => t.photos.max)).toEqual([2, 3]);
    for (const t of ts) {
      expect(t.tier).toBe('premium');
      expect(t.description).toEqual(t.personalization!.group);
      if (t.kind === 'video') {
        expect(t.durationSec).toBe(35);
        expect(t.photos).toEqual({ min: 5, max: 5 });
        expect(t.brand).toEqual({ corner: true, endCard: true, opacity: 0.75 });
      } else
        for (const layers of Object.values(t.layouts!)) {
          expect(layers!.filter((l) => l.type === 'photo').map((l) => l.slot)).toEqual(
            Array.from({ length: t.photos.max }, (_, i) => i),
          );
          expect(layers!.filter((l) => l.type === 'brand')).toHaveLength(1);
        }
    }
  });
  for (const f of fixtures.cases)
    it(`${f.id}/${f.locale}/${JSON.stringify(f.values)} resolves identically to Dart`, () => {
      const t = premium48Phase2().find((t) => t.id === f.id)!;
      expect(resolveKeepsakeCopy(t.personalization!, f.values, f.locale as 'vi' | 'en')).toEqual(
        f.expected,
      );
    });
  it('uses neutral copy until a parent confirms the journey or a birth-day photo', () => {
    const ts = premium48Phase2();
    for (const locale of ['vi', 'en'] as const) {
      const home = resolveKeepsakeCopy(ts[2]!.personalization!, { babyName: 'An' }, locale);
      const month = resolveKeepsakeCopy(ts[3]!.personalization!, { babyName: 'An' }, locale);
      expect(home.scene2).toBe(locale === 'vi' ? 'Một ngày đáng nhớ.' : 'A day to remember.');
      expect(home.detail0).toBe('');
      expect(month.scene1).toBe(
        locale === 'vi' ? 'Những ngày đầu bên con.' : 'Our first days with you.',
      );
      expect(
        resolveKeepsakeCopy(
          ts[2]!.personalization!,
          { babyName: 'An', journeyConfirmed: 'true' },
          locale,
        ).scene2,
      ).not.toBe(home.scene2);
      expect(
        resolveKeepsakeCopy(
          ts[3]!.personalization!,
          { babyName: 'An', birthPhotoConfirmed: 'true' },
          locale,
        ).scene1,
      ).not.toBe(month.scene1);
    }
  });
  it('declares previous photos in scrapbook collages and freezes all selected slots', () => {
    const t = premium48Phase2()[3]!;
    const spec = t.personalization!;
    expect(spec.beats.map((b) => b.slots)).toEqual([[0], [1, 0], [2, 1], [3, 2, 1], [4]]);
    const frozen = freezeKeepsakePresentation(
      spec,
      {
        values: { babyName: 'An' },
        overrides: { scene4: 'Our own words.' },
        crops: Array.from({ length: 5 }, () => ({ x: 0.2, y: -0.3, zoom: 1.2, fit: 'contain' })),
        format: 'portrait',
        reducedMotion: true,
      },
      'en',
    );
    expect(frozen.copy.scene4).toBe('Our own words.');
    expect(frozen.beats[3]!.slots).toEqual([3, 2, 1]);
    expect(frozen.format).toBe('portrait');
    expect(
      keepsakeTemplateSchema.safeParse({
        ...t,
        personalization: { ...spec, beats: [{ slots: [5], textKey: 'scene1' }] },
      }).success,
    ).toBe(false);
  });
  it('retains immutable assets for every card layer and every video motif', () => {
    const assets = Object.fromEntries(fixtures.templates.flatMap((t) => Object.entries(t.assets)));
    expect(Object.keys(assets).length).toBe(21);
    for (const t of fixtures.templates) {
      const parsed = keepsakeTemplateSchema.parse(t);
      const used = keepsakeTemplateAssets(parsed);
      for (const asset of Object.values(t.assets)) expect(used).toContain(asset);
      expect(used.every((a) => a.endsWith('.webp'))).toBe(true);
    }
  });
});
