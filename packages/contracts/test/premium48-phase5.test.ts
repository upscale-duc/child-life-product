import { describe, expect, it } from 'vitest';
import {
  premium48Phase5,
  keepsakeTemplateSchema,
  resolveKeepsakeCopy,
  freezeKeepsakePresentation,
} from '../src/index.js';
import fixtures from './vectors/premium48-phase5.json';
describe('Premium 48 phase 5', () => {
  it('adds exactly two cards and two 35-second videos with independent counts and groups', () => {
    const ts = premium48Phase5();
    expect(ts.map((t) => t.id)).toEqual([
      'card_premium48_09',
      'card_premium48_10',
      'video_premium48_09',
      'video_premium48_10',
    ]);
    expect(ts.map((t) => t.photos.max)).toEqual([3, 1, 5, 3]);
    for (const t of ts) {
      expect(keepsakeTemplateSchema.safeParse(t).success).toBe(true);
      expect(t.personalization!.group.en).toBe(
        t.id.endsWith('_10') ? 'Little Firsts' : 'Growing Every Day',
      );
      if (t.kind === 'video') {
        expect(t.durationSec).toBe(35);
        expect(t.brand?.corner).toBe(true);
        expect(t.brand?.endCard).toBe(true);
      }
    }
  });
  for (const f of fixtures.cases)
    it(`${f.id}/${f.locale}/${f.values.outgrownConfirmed || 'smile'} matches mobile fixture`, () => {
      expect(
        resolveKeepsakeCopy(
          premium48Phase5().find((t) => t.id === f.id)!.personalization!,
          f.values,
          f.locale as 'vi' | 'en',
        ),
      ).toEqual(f.expected);
    });
  it('gates every growth claim and title behind explicit confirmation', () => {
    for (const locale of ['vi', 'en'] as const)
      for (const value of [undefined, 'false', 'true'])
        for (const t of premium48Phase5().filter((t) => t.id.endsWith('_09'))) {
          const copy = resolveKeepsakeCopy(
            t.personalization!,
            { babyName: 'Noah', ...(value ? { outgrownConfirmed: value } : {}) },
            locale,
          );
          const all = Object.values(copy).join(' ');
          if (value !== 'true') {
            expect(all).not.toMatch(
              /no longer fit|You grew|it fit you|đã chật|không còn vừa|Con lớn lên|Đã từng vừa/,
            );
            expect(t.kind === 'video' ? copy.title : copy.headline).toMatch(
              locale === 'vi' ? /Món đồ|MÓN ĐỒ/ : /Keepsake|KEEPSAKE/,
            );
          } else
            expect(t.kind === 'video' ? copy.scene3 : copy.message).toMatch(
              locale === 'vi' ? /vừa/ : /fit/,
            );
          expect(copy.label0).toBe(locale === 'vi' ? 'Món đồ bé xíu' : 'A tiny keepsake');
          expect(copy.label1).toBe('');
        }
  });
  it('does not invent a smile date, first event or relatives’ reaction', () => {
    const t = premium48Phase5()[3]!;
    const copy = resolveKeepsakeCopy(t.personalization!, { babyName: 'Lily' }, 'en');
    expect(Object.values(copy).join(' ')).not.toMatch(/first|all eyes|on \./i);
    expect(copy.scene5).toBe('A smile to keep, always.');
    expect(copy.label1).toBe('');
    const known = resolveKeepsakeCopy(
      t.personalization!,
      { babyName: 'Lily', momentDate: '2026-10-20', reactionConfirmed: 'true' },
      'en',
    );
    expect(known.scene3).toBe('And all eyes turned to you.');
    expect(known.scene5).toContain('20 October 2026');
  });
  it('freezes intentional reprises without filling missing inputs', () => {
    const t = premium48Phase5()[3]!;
    const request = {
      values: { babyName: 'Lily' },
      overrides: {},
      format: 'portrait' as const,
      reducedMotion: true,
      crops: Array.from({ length: 5 }, () => ({ x: 0, y: 0, zoom: 1 })),
    };
    expect(
      freezeKeepsakePresentation(t.personalization!, request, 'en').beats.map((b) => b.slots),
    ).toEqual([[0], [1], [2, 1], [1], [1]]);
    expect(() =>
      freezeKeepsakePresentation(
        t.personalization!,
        { ...request, crops: request.crops.slice(1) },
        'en',
      ),
    ).toThrow('crops');
  });
  it('rejects fabricated confirmations and dates; preserves English names in either language', () => {
    for (const t of premium48Phase5())
      for (const locale of ['vi', 'en'] as const) {
        const name = t.id.endsWith('_10') ? 'Lily' : 'Noah';
        expect(resolveKeepsakeCopy(t.personalization!, { babyName: name }, locale).signature).toBe(
          name,
        );
      }
    expect(() =>
      resolveKeepsakeCopy(
        premium48Phase5()[0]!.personalization!,
        { babyName: 'Noah', outgrownConfirmed: 'yes' },
        'en',
      ),
    ).toThrow('confirmation');
    expect(() =>
      resolveKeepsakeCopy(
        premium48Phase5()[1]!.personalization!,
        { babyName: 'Lily', momentDate: '2026-02-30' },
        'en',
      ),
    ).toThrow('date');
  });
});
