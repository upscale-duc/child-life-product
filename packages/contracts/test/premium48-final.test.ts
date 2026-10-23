import { describe, expect, it } from 'vitest';
import {
  premium48FinalDesigns,
  premium48FinalPhase,
  resolveKeepsakeCopy,
  keepsakeTemplateSchema,
  freezeKeepsakePresentation,
} from '../src/index.js';
import { readFileSync } from 'node:fs';
describe('Premium 48 final six phases', () => {
  for (let phase = 7; phase <= 12; phase++) {
    const templates = premium48FinalPhase(phase);
    it(`phase ${phase} has exactly two cards and two branded videos`, () => {
      expect(templates.map((t) => t.kind)).toEqual(['card', 'card', 'video', 'video']);
      expect(new Set(templates.map((t) => t.id)).size).toBe(4);
      for (const t of templates) {
        expect(keepsakeTemplateSchema.safeParse(t).success).toBe(true);
        expect(t.personalization?.group).toEqual(t.description);
        if (t.kind === 'video') {
          expect(t.brand?.corner && t.brand.endCard).toBe(true);
          expect(t.durationSec).toBe(t.id.endsWith('_22') ? 50 : 35);
        } else {
          expect(t.layouts?.portrait.filter((l) => l.type === 'photo')).toHaveLength(t.photos.max);
          expect(t.layouts?.story.filter((l) => l.type === 'photo')).toHaveLength(t.photos.max);
        }
      }
    });
    const fixtures = JSON.parse(
      readFileSync(new URL(`./vectors/premium48-phase${phase}.json`, import.meta.url), 'utf8'),
    );
    for (const c of fixtures.cases)
      it(`phase ${phase} parity ${c.id}/${c.locale}/${c.values.momentDate || 'unknown date'}`, () =>
        expect(
          resolveKeepsakeCopy(
            templates.find((t) => t.id === c.id)!.personalization!,
            c.values,
            c.locale,
          ),
        ).toEqual(c.expected));
  }
  const spec = (n: number, video = false) =>
    premium48FinalPhase(Math.ceil(n / 2)).find(
      (t) => t.id === `${video ? 'video' : 'card'}_premium48_${n}`,
    )!.personalization!;
  it('never assumes a parent, hand, sleeping state or meeting date', () => {
    expect(resolveKeepsakeCopy(spec(13), { babyName: 'Henry' }, 'en').title).toBe(
      'Held with love.',
    );
    const relative = resolveKeepsakeCopy(spec(14, true), { babyName: 'Grace' }, 'en');
    expect(Object.values(relative).join(' ')).not.toMatch(
      /today|finally|tiny hand|Grandma|Grandpa/i,
    );
    expect(relative.label1).toBe('');
    expect(resolveKeepsakeCopy(spec(17, true), { babyName: 'Leo' }, 'en').scene3).toBe(
      'Another close little look.',
    );
    expect(resolveKeepsakeCopy(spec(18), { babyName: 'Sophie' }, 'en').title).toBe(
      'A quiet evening.',
    );
  });
  it('changes the whole day story when dates and sequence are not confirmed', () => {
    const c = resolveKeepsakeCopy(spec(16, true), { babyName: 'Isla' }, 'en');
    expect(Object.values(c).join(' ')).not.toMatch(/morning|evening|feeding|sleeping/i);
    expect(c.scene5).toBe('Days with you, worth remembering.');
  });
  it('requires a named occasion and an explicit valid theme independent of locale', () => {
    const s = spec(20),
      base = { babyName: 'Chloe', occasionName: 'Lunar New Year' };
    for (const locale of ['vi', 'en'] as const) {
      expect(() => resolveKeepsakeCopy(s, base, locale)).toThrow('required');
      expect(() => resolveKeepsakeCopy(s, { ...base, celebrationTheme: 'easter' }, locale)).toThrow(
        'option',
      );
      for (const theme of ['tet', 'christmas', 'neutral'])
        expect(resolveKeepsakeCopy(s, { ...base, celebrationTheme: theme }, locale).theme).toBe(
          theme,
        );
    }
    expect(resolveKeepsakeCopy(s, { ...base, celebrationTheme: 'tet' }, 'en').title).not.toMatch(
      /first/,
    );
    expect(
      resolveKeepsakeCopy(s, { ...base, celebrationTheme: 'tet', firstConfirmed: 'true' }, 'en')
        .title,
    ).toMatch(/first Lunar New Year/);
  });
  it('shows the numeral only for the actively confirmed hundred-day milestone', () => {
    expect(resolveKeepsakeCopy(spec(19), { babyName: 'Lucas' }, 'en').hundredMark).toBe('');
    expect(
      resolveKeepsakeCopy(spec(19), { babyName: 'Lucas', hundredConfirmed: 'true' }, 'en')
        .hundredMark,
    ).toBe('100');
  });
  it('never invents a first trip or an unknown location', () => {
    const c = resolveKeepsakeCopy(spec(21), { babyName: 'Theo' }, 'en');
    expect(c.title).toBe('An adventure with you.');
    expect(Object.values(c).join(' ')).not.toMatch(/first|undefined|\{/);
  });
  it('uses all twelve ordered inputs without filling missing months by repetition', () => {
    for (const video of [false, true]) {
      const t = premium48FinalPhase(11).find(
        (t) => t.id === `${video ? 'video' : 'card'}_premium48_22`,
      )!;
      expect(t.photos).toEqual({ min: 12, max: 12 });
      const unknown = resolveKeepsakeCopy(t.personalization!, { babyName: 'Alice' }, 'en');
      expect(unknown.monthLabels).toBe('false');
      const confirmed = resolveKeepsakeCopy(
        t.personalization!,
        { babyName: 'Alice', monthsConfirmed: 'true' },
        'en',
      );
      expect(confirmed.monthLabels).toBe('true');
      if (!video)
        expect(Array.from({ length: 12 }, (_, i) => confirmed[`photoLabel${i}`])).toEqual(
          Array.from({ length: 12 }, (_, i) => String(i + 1).padStart(2, '0')),
        );
      if (video) {
        expect(t.personalization!.beats.map((b) => b.slots)).toEqual([
          [0, 1, 2],
          [3, 4, 5],
          [6, 7, 8],
          [9, 10, 11],
          [11],
        ]);
        expect(() =>
          freezeKeepsakePresentation(
            t.personalization!,
            {
              values: { babyName: 'Alice' },
              overrides: {},
              crops: [],
              format: 'story',
              reducedMotion: true,
            },
            'en',
          ),
        ).toThrow('crops');
      }
    }
  });
  it('keeps entered names intact in both languages', () => {
    expect(premium48FinalDesigns).toHaveLength(12);
    for (let phase = 7; phase <= 12; phase++)
      for (const t of premium48FinalPhase(phase))
        for (const locale of ['vi', 'en'] as const) {
          const values = {
            babyName: 'Nguyễn An',
            ...(t.id.endsWith('_20') ? { occasionName: 'Tết', celebrationTheme: 'tet' } : {}),
          };
          expect(resolveKeepsakeCopy(t.personalization!, values, locale).signature).toBe(
            'Nguyễn An',
          );
        }
  });
});
