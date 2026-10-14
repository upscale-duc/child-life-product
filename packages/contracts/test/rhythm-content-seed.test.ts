import { describe, expect, it } from 'vitest';
import {
  ageCardFor,
  healthSigns,
  referenceModelSchema,
  rhythmContentSchema,
} from '../src/index.js';
import referenceSeed from '../../../content/rhythm/reference.seed.json' with { type: 'json' };
import contentSeed from '../../../content/rhythm/content.seed.json' with { type: 'json' };

/**
 * The Nhịp lớn lên seed (`content/rhythm/*.seed.json`): engineering draft per D-073 #2, so every
 * item stays `review: null` until a qualified reviewer signs it. These checks keep the draft
 * publishable on dev: schema-valid, linked, bilingual, gap-free and never certain about a stage.
 */
const reference = referenceModelSchema.parse(referenceSeed);
const content = rhythmContentSchema.parse(contentSeed);

const chars = (s: string) => Array.from(s).length;
const duplicates = (ids: readonly string[]) => ids.filter((id, i) => ids.indexOf(id) !== i);

/** Every `{vi, en}` pair in [value], with its path. */
function localizedPairs(value: unknown, path = '$'): { path: string; vi: unknown; en: unknown }[] {
  if (Array.isArray(value)) return value.flatMap((v, i) => localizedPairs(v, `${path}[${i}]`));
  if (value === null || typeof value !== 'object') return [];
  const o = value as Record<string, unknown>;
  const keys = Object.keys(o).sort();
  if (keys.length === 2 && keys[0] === 'en' && keys[1] === 'vi')
    return [{ path, vi: o.vi, en: o.en }];
  return Object.entries(o).flatMap(([k, v]) => localizedPairs(v, `${path}.${k}`));
}

describe('rhythm content seed · reference model', () => {
  it('parses as a draft model labelled Wonder Weeks', () => {
    expect(reference.version).toMatch(/^ref_\d{8}_\d{2}$/);
    expect(reference.label).toBe('Wonder Weeks');
    expect(reference.publishedAt).toBeNull();
    expect(reference.review).toBeNull();
    expect(reference.stages).toHaveLength(10);
  });

  it('numbers stages 1..n in order, with unique ids and windows that never run backwards', () => {
    expect(duplicates(reference.stages.map((s) => s.id))).toEqual([]);
    reference.stages.forEach((s, i) => {
      expect(s.number).toBe(i + 1);
      expect(s.endOffsetDays).toBeGreaterThanOrEqual(s.startOffsetDays);
      if (i > 0)
        expect(s.startOffsetDays).toBeGreaterThan(reference.stages[i - 1]!.startOffsetDays);
    });
  });

  it('links only activities that exist and suit the stage window', () => {
    const byId = new Map(content.activities.map((a) => [a.id, a]));
    for (const s of reference.stages) {
      expect(s.activityIds.length).toBeGreaterThan(0);
      for (const id of s.activityIds) {
        const a = byId.get(id);
        expect(a, `${s.id} → ${id}`).toBeDefined();
        expect(a!.status).toBe('published');
        // Due-date offsets ≈ age for a term baby: the activity's age range must touch the window.
        expect(
          a!.ageDays.from <= s.endOffsetDays && a!.ageDays.to >= s.startOffsetDays,
          `${s.id} → ${id}`,
        ).toBe(true);
      }
    }
  });

  it('phrases signs as possibilities, never certainties (PN02 "Không được viết")', () => {
    for (const s of reference.stages) {
      expect(s.signs.vi.length).toBeGreaterThan(0);
      expect(s.skills.vi.length).toBeGreaterThan(0);
      for (const line of s.signs.vi) expect(line.toLowerCase(), s.id).not.toContain('chắc chắn');
      for (const line of s.signs.en) {
        expect(line, s.id).not.toMatch(/\bdefinitely\b/i);
        expect(line, s.id).not.toMatch(/\bwill\b/i);
      }
      // "Một số bé không có thay đổi rõ" is always there.
      expect(s.signs.vi.some((l) => l.startsWith('Một số bé không có thay đổi rõ'))).toBe(true);
    }
  });

  it('keeps reminders within 40 / 90 characters (PN02)', () => {
    for (const s of reference.stages) {
      expect(s.notice).not.toBeNull();
      for (const lang of ['vi', 'en'] as const) {
        expect(chars(s.notice!.title[lang]), `${s.id} title ${lang}`).toBeLessThanOrEqual(40);
        expect(chars(s.notice!.body[lang]), `${s.id} body ${lang}`).toBeLessThanOrEqual(90);
      }
    }
  });
});

describe('rhythm content seed · activities, age cards, health', () => {
  it('parses as an unpublished content version', () => {
    expect(content.version).toMatch(/^rc_\d{8}_\d{2}$/);
    expect(content.publishedAt).toBeNull();
    expect(content.activities.length).toBeGreaterThanOrEqual(25);
  });

  it('has unique activity and age-card ids', () => {
    expect(duplicates(content.activities.map((a) => a.id))).toEqual([]);
    expect(duplicates(content.ageCards.map((c) => c.id))).toEqual([]);
  });

  it('leaves every item unreviewed (D-073 #2: "chờ chuyên môn duyệt")', () => {
    for (const a of content.activities) expect(a.review, a.id).toBeNull();
    for (const c of content.ageCards) expect(c.review, c.id).toBeNull();
    expect(content.health.review).toBeNull();
    expect(reference.review).toBeNull();
  });

  it('publishes activities in both languages, with steps and at least one source', () => {
    for (const a of content.activities) {
      expect(a.status, a.id).toBe('published');
      expect([...a.locales].sort(), a.id).toEqual(['en', 'vi']);
      expect(a.steps.vi.length, a.id).toBeGreaterThanOrEqual(3);
      expect(a.steps.vi.length, a.id).toBeLessThanOrEqual(5);
      expect(a.sources.length, a.id).toBeGreaterThan(0);
      expect(a.ageDays.to, a.id).toBeLessThanOrEqual(760);
    }
  });

  it('covers every day from 0 to 730 with a published age card', () => {
    const gaps: number[] = [];
    for (let day = 0; day <= 730; day++) {
      const covered = content.ageCards.some(
        (c) => c.status === 'published' && day >= c.ageDays.from && day <= c.ageDays.to,
      );
      if (!covered || ageCardFor(content.ageCards, day) === null) gaps.push(day);
    }
    expect(gaps).toEqual([]);
  });

  it('gives every age card tips and sources', () => {
    for (const c of content.ageCards) {
      expect(c.tips.vi.length, c.id).toBeGreaterThanOrEqual(2);
      expect(c.tips.vi.length, c.id).toBeLessThanOrEqual(4);
      expect(c.sources.length, c.id).toBeGreaterThan(0);
    }
  });

  it('routes exactly the check-in health signs, fever only under 3 months', () => {
    expect(content.health.signs.map((s) => s.id)).toEqual([...healthSigns]);
    const fever = content.health.signs.find((s) => s.id === 'fever_young')!;
    expect(fever.maxAgeDays).toBe(90);
    for (const s of content.health.signs.filter((x) => x.id !== 'fever_young')) {
      expect(s.maxAgeDays, s.id).toBeNull();
    }
    expect(content.health.whileWaiting.vi.length).toBeGreaterThanOrEqual(3);
    expect(content.health.whileWaiting.vi.length).toBeLessThanOrEqual(5);
  });

  it('lists each country once, with no default hotline', () => {
    const countries = content.health.regions.map((r) => r.country);
    expect(duplicates(countries)).toEqual([]);
    expect(content.health.regions.find((r) => r.country === 'VN')?.emergencyNumber).toBe('115');
  });
});

describe('rhythm content seed · both languages everywhere (D-012)', () => {
  const pairs = [...localizedPairs(referenceSeed), ...localizedPairs(contentSeed)];

  it('finds the localized fields', () => {
    expect(pairs.length).toBeGreaterThan(300);
  });

  it('has non-empty vi and en for every string and list item, lists of equal length', () => {
    const bad: string[] = [];
    for (const { path, vi, en } of pairs) {
      if (typeof vi === 'string' || typeof en === 'string') {
        if (typeof vi !== 'string' || typeof en !== 'string' || !vi.trim() || !en.trim())
          bad.push(path);
      } else if (Array.isArray(vi) || Array.isArray(en)) {
        if (!Array.isArray(vi) || !Array.isArray(en) || vi.length !== en.length) bad.push(path);
        else if ([...vi, ...en].some((s) => typeof s !== 'string' || !s.trim())) bad.push(path);
      } else {
        bad.push(path);
      }
    }
    expect(bad).toEqual([]);
  });

  it('cites https sources only', () => {
    const urls = [
      ...reference.sources,
      ...content.activities.flatMap((a) => a.sources),
      ...content.ageCards.flatMap((c) => c.sources),
      ...content.health.sources,
    ].map((s) => s.url);
    expect(urls.filter((u) => !u.startsWith('https://'))).toEqual([]);
  });
});
