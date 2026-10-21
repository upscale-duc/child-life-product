import { describe, expect, it } from 'vitest';
import {
  premium48Phase6,
  keepsakeTemplateSchema,
  resolveKeepsakeCopy,
  freezeKeepsakePresentation,
} from '../src/index.js';
import fixtures from './vectors/premium48-phase6.json';
describe('Premium 48 phase 6', () => {
  it('adds two cards and two branded 35-second videos under the existing group', () => {
    const ts = premium48Phase6();
    expect(ts.map((t) => t.id)).toEqual([
      'card_premium48_11',
      'card_premium48_12',
      'video_premium48_11',
      'video_premium48_12',
    ]);
    expect(ts.map((t) => t.photos.max)).toEqual([3, 2, 5, 5]);
    for (const t of ts) {
      expect(keepsakeTemplateSchema.safeParse(t).success).toBe(true);
      expect(t.personalization!.group).toEqual({ vi: 'Lần đầu', en: 'Little Firsts' });
      if (t.kind === 'video') {
        expect(t.durationSec).toBe(35);
        expect(t.brand?.corner).toBe(true);
        expect(t.brand?.endCard).toBe(true);
      }
    }
  });
  for (const f of fixtures.cases)
    it(`${f.id}/${f.locale}/${f.values.momentPhotoConfirmed || 'discovery'} matches mobile fixtures`, () => {
      expect(
        resolveKeepsakeCopy(
          premium48Phase6().find((t) => t.id === f.id)!.personalization!,
          f.values,
          f.locale as 'vi' | 'en',
        ),
      ).toEqual(f.expected);
    });
  it('requires the parent-entered milestone and does not infer one from a profile', () => {
    for (const t of premium48Phase6().filter((t) => t.id.endsWith('_11')))
      for (const milestoneName of [undefined, '', ' '])
        expect(() =>
          resolveKeepsakeCopy(
            t.personalization!,
            { babyName: 'Oliver', ...(milestoneName === undefined ? {} : { milestoneName }) },
            'en',
          ),
        ).toThrow('required');
  });
  it('switches every relevant scene when the actual milestone moment is not pictured', () => {
    for (const locale of ['vi', 'en'] as const)
      for (const t of premium48Phase6().filter((t) => t.id.endsWith('_11'))) {
        const values = {
          babyName: 'Oliver',
          milestoneName: locale === 'vi' ? 'những bước nhỏ' : 'little steps',
        };
        const memory = resolveKeepsakeCopy(t.personalization!, values, locale),
          actual = resolveKeepsakeCopy(
            t.personalization!,
            { ...values, momentPhotoConfirmed: 'true' },
            locale,
          );
        expect(memory.title).toMatch(locale === 'vi' ? /Nhớ ngày/ : /Remembering/);
        expect(Object.values(memory).join(' ')).not.toMatch(
          /And then|One little try|YOU DID IT|CON LÀM ĐƯỢC RỒI|Và hôm nay|Một lần thử/,
        );
        expect(actual.title).toMatch(locale === 'vi' ? /Con làm được/ : /You did it/i);
      }
  });
  it('does not invent an object, companion, date or a first event', () => {
    for (const t of premium48Phase6().filter((t) => t.id.endsWith('_12'))) {
      const copy = resolveKeepsakeCopy(t.personalization!, { babyName: 'Emma' }, 'en');
      expect(copy.label0).toBe('Something new');
      expect(Object.values(copy).join(' ')).not.toMatch(
        /first|gentle touch|colour|sound|with you|undefined|\{/i,
      );
      if (t.kind === 'video') {
        expect(copy.label1).toBe('');
        expect(copy.scene3).toBe('Today, it was something new.');
      }
    }
  });
  it('keeps entered discoveries and confirmed companion/object wording in both locales', () => {
    const t = premium48Phase6()[3]!;
    const copy = resolveKeepsakeCopy(
      t.personalization!,
      {
        babyName: 'Emma',
        discovery: 'tiny leaves',
        momentDate: '2026-10-21',
        objectPhotoConfirmed: 'true',
        companionConfirmed: 'true',
      },
      'en',
    );
    expect(copy.scene3).toContain('tiny leaves');
    expect(copy.scene4).toContain('with you');
    expect(copy.label1).toBe('21 October 2026');
  });
  it('uses exactly five independent inputs and validates crop count', () => {
    for (const t of premium48Phase6().filter((t) => t.kind === 'video')) {
      const request = {
        values: t.id.endsWith('_11')
          ? { babyName: 'Oliver', milestoneName: 'little steps' }
          : { babyName: 'Emma' },
        overrides: {},
        crops: Array.from({ length: 5 }, () => ({ x: 0, y: 0, zoom: 1 })),
        format: 'story' as const,
        reducedMotion: true,
      };
      expect(
        freezeKeepsakePresentation(t.personalization!, request, 'en').beats.map((b) => b.slots),
      ).toEqual([[0], [1], [2], [3], [4]]);
      expect(() =>
        freezeKeepsakePresentation(t.personalization!, { ...request, crops: [] }, 'en'),
      ).toThrow('crops');
    }
  });
  it('rejects fake confirmation/date values and never translates demo names', () => {
    const t = premium48Phase6()[2]!;
    expect(() =>
      resolveKeepsakeCopy(
        t.personalization!,
        { babyName: 'Oliver', milestoneName: 'little steps', momentPhotoConfirmed: 'yes' },
        'en',
      ),
    ).toThrow('confirmation');
    expect(() =>
      resolveKeepsakeCopy(
        t.personalization!,
        { babyName: 'Oliver', milestoneName: 'little steps', momentDate: '2026-02-30' },
        'en',
      ),
    ).toThrow('date');
    for (const template of premium48Phase6())
      for (const locale of ['vi', 'en'] as const) {
        const babyName = template.id.endsWith('_12') ? 'Emma' : 'Oliver';
        expect(
          resolveKeepsakeCopy(
            template.personalization!,
            { babyName, ...(template.id.endsWith('_11') ? { milestoneName: 'little steps' } : {}) },
            locale,
          ).signature,
        ).toBe(babyName);
      }
  });
});
