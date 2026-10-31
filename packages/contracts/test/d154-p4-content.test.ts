import { describe, expect, it } from 'vitest';
import { activitySchema, ageCardSchema } from '../src/index.js';
import draft from '../../../content/rhythm/d154-p4.draft.json' with { type: 'json' };
import contentSeed from '../../../content/rhythm/content.seed.json' with { type: 'json' };
import toddlerV2 from '../../../content/rhythm/toddler-v2.draft.json' with { type: 'json' };

/**
 * D-154 P4 content pack (`content/rhythm/d154-p4.draft.json`): drafted by engineering "như một
 * chuyên gia" (D-073 #2), unreviewed (`review: null`). It fills measured gaps in the published
 * pack: newborn activities, 0–3-month milestones, 6–12-month soothing, 2–3-year bonding and
 * milestones, and the monthly "Tuần này của {bé}" cards from 25 months to 3 years.
 */
const activities = draft.activities.map((a) => activitySchema.parse(a));
const ageCards = draft.ageCards.map((c) => ageCardSchema.parse(c));

const duplicates = (ids: readonly string[]) => ids.filter((id, i) => ids.indexOf(id) !== i);
const short = (a: { durationMin: number }) => a.durationMin <= 5;

describe('D-154 P4 content · schema and ids', () => {
  it('parses every activity and age card', () => {
    expect(activities).toHaveLength(draft.activities.length);
    expect(ageCards).toHaveLength(draft.ageCards.length);
  });

  it('marks every activity as a doable activity (kind) and keeps the raw items publishable', () => {
    for (const a of draft.activities) expect(a.kind, a.id).toBe('activity');
    for (const x of [...draft.activities, ...draft.ageCards]) {
      expect(x.status, x.id).toBe('published');
      expect(x.version, x.id).toBe(1);
      expect(x.review, x.id).toBeNull();
      expect(x.sources.length, x.id).toBeGreaterThanOrEqual(1);
      expect(x.sources.length, x.id).toBeLessThanOrEqual(4);
      for (const s of x.sources) expect(s.url, x.id).toMatch(/^https:\/\//);
    }
    for (const a of activities) {
      expect([...a.locales].sort(), a.id).toEqual(['en', 'vi']);
      expect(a.regions, a.id).toEqual([]);
      expect(a.steps.vi.length, a.id).toBeGreaterThanOrEqual(3);
      expect(a.steps.vi.length, a.id).toBeLessThanOrEqual(5);
      expect(a.steps.en.length, a.id).toBe(a.steps.vi.length);
    }
    for (const c of ageCards) {
      expect(c.tips.vi.length, c.id).toBeGreaterThanOrEqual(2);
      expect(c.tips.vi.length, c.id).toBeLessThanOrEqual(4);
      expect(c.tips.en.length, c.id).toBe(c.tips.vi.length);
      expect(c.watchFor.en.length, c.id).toBe(c.watchFor.vi.length);
    }
  });

  it('uses new ids, merged into the seed unchanged (not taken from the 1–3-year pack)', () => {
    const ids = [...activities.map((a) => a.id), ...ageCards.map((c) => c.id)];
    expect(duplicates(ids)).toEqual([]);
    expect(ids.filter((id) => toddlerV2.some((a) => a.id === id))).toEqual([]);
    for (const a of activities) expect(a.id).toMatch(/^act_p4_/);
    // The seed carries each item exactly as drafted (scripts merge it, D-154 P4).
    const seeded = new Map<string, unknown>(
      [...contentSeed.activities, ...contentSeed.ageCards].map((x) => [x.id, x]),
    );
    for (const x of [...activities, ...ageCards]) expect(seeded.get(x.id), x.id).toEqual(x);
  });
});

describe('D-154 P4 content · the gaps it fills', () => {
  const newborn = activities.filter((a) => a.ageDays.from === 0 && a.ageDays.to <= 60);
  const milestone0to90 = activities.filter((a) => a.ageDays.to <= 90 && a.needs[0] === 'milestone');
  const soothing6to12 = activities.filter(
    (a) => a.ageDays.from >= 183 && a.ageDays.to <= 365 && a.needs[0] === 'soothing',
  );
  const toddler = activities.filter((a) => a.ageDays.from === 731 && a.ageDays.to === 1095);

  it('has 6 newborn activities, at least 4 of them ≤ 5 minutes, across five needs', () => {
    const newbornOnly = newborn.filter((a) => a.needs[0] !== 'milestone');
    expect(newbornOnly).toHaveLength(6);
    expect(newbornOnly.filter(short).length).toBeGreaterThanOrEqual(4);
    const needs = new Set(newbornOnly.flatMap((a) => a.needs));
    for (const n of ['soothing', 'bonding', 'play', 'feeding', 'sleep'])
      expect(needs.has(n as never), n).toBe(true);
  });

  it('has 3 milestone activities for 0–90 days, each ≤ 5 minutes', () => {
    expect(milestone0to90).toHaveLength(3);
    for (const a of milestone0to90) expect(short(a), a.id).toBe(true);
  });

  it('has 3 soothing activities for 183–365 days, each ≤ 5 minutes', () => {
    expect(soothing6to12).toHaveLength(3);
    for (const a of soothing6to12) expect(short(a), a.id).toBe(true);
  });

  it('has 4 bonding and 3 milestone activities for 2–3 years, mostly ≤ 5 minutes', () => {
    expect(toddler.filter((a) => a.needs[0] === 'bonding')).toHaveLength(4);
    expect(toddler.filter((a) => a.needs[0] === 'milestone')).toHaveLength(3);
    expect(toddler).toHaveLength(7);
    expect(toddler.filter(short).length).toBeGreaterThanOrEqual(5);
  });

  it('accounts for every activity in exactly one group', () => {
    expect(activities).toHaveLength(6 + 3 + 3 + 7);
  });

  it('continues the monthly cards from day 761 to day 1095, contiguous and non-overlapping', () => {
    const sorted = [...ageCards].sort((a, b) => a.ageDays.from - b.ageDays.from);
    expect(sorted[0]!.ageDays.from).toBe(761);
    expect(sorted.at(-1)!.ageDays.to).toBe(1095);
    sorted.forEach((c, i) => {
      // SEED-NOTES §4: month m starts at round(m × 30.4375).
      const m = Number(c.id.replace('age_m', ''));
      expect(c.ageDays.from, c.id).toBe(Math.round(m * 30.4375));
      expect(c.title.vi, c.id).toBe(`${m} tháng tuổi`);
      expect(c.title.en, c.id).toBe(`${m} months old`);
      if (i > 0) expect(c.ageDays.from, c.id).toBe(sorted[i - 1]!.ageDays.to + 1);
    });
  });
});

describe('D-154 P4 content · wording', () => {
  it('never sounds certain in summaries or card bodies (PN02 "Không được viết")', () => {
    const texts = [
      ...activities.map((a) => ({ id: a.id, ...a.summary })),
      ...ageCards.map((c) => ({ id: c.id, ...c.body })),
    ];
    for (const t of texts) {
      expect(t.vi.toLowerCase(), t.id).not.toContain('chắc chắn');
      expect(t.en, t.id).not.toMatch(/\bdefinitely\b/i);
      expect(t.en, t.id).not.toMatch(/\bwill\b/i);
    }
  });

  it('frames every card as "mỗi bé mỗi khác" and flags a lost skill', () => {
    for (const c of ageCards) {
      expect(c.body.vi, c.id).toContain('Mỗi bé mỗi khác');
      expect(c.body.en, c.id).toContain('Every child is different');
      expect(c.watchFor.vi, c.id).toContain('Con mất đi một kỹ năng từng làm được');
    }
  });

  it('writes "diaper", never "nappy", in English copy (app_en.arb)', () => {
    const english = [
      ...activities.flatMap((a) => [a.title.en, a.summary.en, ...a.steps.en, a.safety?.en ?? '']),
      ...ageCards.flatMap((c) => [c.body.en, ...c.tips.en, ...c.watchFor.en]),
    ];
    expect(english.filter((s) => /\bnapp(y|ies)\b/i.test(s))).toEqual([]);
  });
});
