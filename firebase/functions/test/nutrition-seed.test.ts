import {
  conditionsFor,
  nutrientIdSchema,
  nutrientStrictSchema,
  nutritionAgeLabel,
  nutritionAgesOverlap,
  nutritionCopyProblems,
  nutritionGaps,
  nutritionLimits,
  nutritionRuleIdSchema,
  nutritionRuleStrictSchema,
  nutritionStageFor,
  nutritionStageIdSchema,
  nutritionStageStrictSchema,
  ruleFits,
  sortNutritionStages,
} from '@child-life/contracts';
import { describe, expect, it } from 'vitest';
import { seedNutrients, seedNutritionRules, seedNutritionStages } from '../src/nutrition-seed.js';

// The expert drafts of Dinh dưỡng theo giai đoạn (D-083, P-163) that "Nhập bản nháp mẫu" imports:
// publishable as they are (strict schemas, no forbidden word or dose), one stage per month from 0
// to 36 with no gap or overlap, links that resolve, and rules that fit their metric.

const stages = seedNutritionStages;
const nutrients = seedNutrients;
const rules = seedNutritionRules;
const nutrientIds = new Set(nutrients.map((n) => n.id));

/** Every string anywhere in [value], with its dotted path. */
function strings(value: unknown, path = ''): { path: string; s: string }[] {
  if (typeof value === 'string') return [{ path, s: value }];
  if (Array.isArray(value)) return value.flatMap((v, i) => strings(v, `${path}.${i}`));
  if (value && typeof value === 'object') {
    return Object.entries(value).flatMap(([k, v]) => strings(v, path ? `${path}.${k}` : k));
  }
  return [];
}

/** Every `{vi, en}` pair anywhere in [value] (sources excluded). */
function pairs(value: unknown, path = ''): { path: string; vi: string; en: string }[] {
  if (Array.isArray(value)) return value.flatMap((v, i) => pairs(v, `${path}.${i}`));
  if (value && typeof value === 'object') {
    const o = value as Record<string, unknown>;
    if (typeof o.vi === 'string' && typeof o.en === 'string') {
      return [{ path, vi: o.vi, en: o.en }];
    }
    return Object.entries(o)
      .filter(([k]) => k !== 'sources')
      .flatMap(([k, v]) => pairs(v, path ? `${path}.${k}` : k));
  }
  return [];
}

/** Shared copy checks: NFC text (so the forbidden-word check matches), real translations. */
function checkCopy(id: string, data: unknown) {
  expect(nutritionCopyProblems(data), id).toEqual([]);
  for (const { path, s } of strings(data)) {
    expect(s, `${id} ${path} is NFC`).toBe(s.normalize('NFC'));
    expect(s, `${id} ${path} has no stray whitespace`).toBe(s.trim());
    // The only placeholder the app fills is {name}.
    expect(s.replaceAll('{name}', ''), `${id} ${path} placeholder`).not.toMatch(/[{}]/);
  }
  for (const { path, vi, en } of pairs(data)) {
    // Names such as "Vitamin D" read the same; anything longer must be translated.
    if (vi.length > 16) expect(en, `${id} ${path} translated`).not.toBe(vi);
    expect(
      /[ăâđêôơưạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ]/i.test(en),
      `${id} ${path}.en`,
    ).toBe(
      // Vietnamese place names in the English text are fine ("Việt Nam").
      /Việt Nam/.test(en),
    );
  }
}

function checkSources(id: string, sources: readonly { label: string; url: string }[]) {
  expect(sources.length, `${id} cites sources`).toBeGreaterThanOrEqual(3);
  expect(new Set(sources.map((s) => s.url)).size, `${id} sources unique`).toBe(sources.length);
  for (const s of sources) expect(s.url, `${id} source`).toMatch(/^https:\/\/[^\s]+$/);
}

describe('nutrition seed: ids', () => {
  it('7 stages, 7 nutrients, 5 rules with unique ids matching the id schemas', () => {
    expect(stages).toHaveLength(7);
    expect(nutrients).toHaveLength(7);
    expect(rules).toHaveLength(5);
    const all = [...stages, ...nutrients, ...rules].map((x) => x.id);
    expect(new Set(all).size).toBe(all.length);
    for (const s of stages) expect(nutritionStageIdSchema.safeParse(s.id).success, s.id).toBe(true);
    for (const n of nutrients) expect(nutrientIdSchema.safeParse(n.id).success, n.id).toBe(true);
    for (const r of rules) expect(nutritionRuleIdSchema.safeParse(r.id).success, r.id).toBe(true);
  });

  it('names the expected reviewer and never claims a review', () => {
    for (const x of [...stages, ...nutrients, ...rules]) {
      expect(x.reviewerLabel, x.id).toBe('Nhóm chuyên môn · Dinh dưỡng nhi');
      for (const { s } of strings(x.data)) {
        expect(s, x.id).not.toMatch(
          /đã được (bác sĩ|chuyên gia|chuyên môn)|reviewed by|approved by/i,
        );
      }
    }
  });
});

describe('nutrition seed: stages', () => {
  it.each(stages.map((s) => [s.id, s] as const))('%s is publishable', (id, s) => {
    const parsed = nutritionStageStrictSchema.safeParse(s.data);
    expect(parsed.success, JSON.stringify(parsed.error?.issues.slice(0, 3))).toBe(true);
    checkCopy(id, s.data);
    checkSources(id, s.data.sources);

    // Nutrients resolve, once each, and every stage has tips and a sample day.
    expect(s.data.nutrientIds.length).toBeGreaterThan(0);
    for (const n of s.data.nutrientIds) expect(nutrientIds.has(n), `${id} → ${n}`).toBe(true);
    expect(new Set(s.data.nutrientIds).size).toBe(s.data.nutrientIds.length);
    expect(s.data.tips.length).toBeGreaterThanOrEqual(2);
    expect(s.data.sampleDay.length).toBeGreaterThanOrEqual(4);
  });

  it('cover 0–36 months with no gap and no overlap, labelled as 9f draws them', () => {
    const sorted = sortNutritionStages(stages.map((s) => ({ id: s.id, ...s.data })));
    expect(nutritionGaps(sorted)).toEqual([]);
    for (let i = 0; i < sorted.length; i++) {
      for (let j = i + 1; j < sorted.length; j++) {
        expect(
          nutritionAgesOverlap(sorted[i]!.ageMonths, sorted[j]!.ageMonths),
          `${sorted[i]!.id} / ${sorted[j]!.id}`,
        ).toBe(false);
      }
      if (i > 0) expect(sorted[i]!.ageMonths.from).toBe(sorted[i - 1]!.ageMonths.to);
    }
    expect(sorted[0]!.ageMonths.from).toBe(0);
    expect(sorted.at(-1)!.ageMonths.to).toBe(nutritionLimits.maxAgeMonths + 1);
    expect(
      sorted.map((s) => {
        const l = nutritionAgeLabel(s.ageMonths);
        return `${l.from}–${l.to}`;
      }),
    ).toEqual(['0–1', '1–3', '4–5', '6–8', '9–11', '12–23', '24–36']);
    // Every age 0–36 finds its own stage; a 7-month baby gets "Bắt đầu ăn dặm" (acceptance #1).
    for (let m = 0; m <= 36; m++) expect(nutritionStageFor(sorted, m)?.past, `${m}`).toBe(false);
    expect(nutritionStageFor(sorted, 7)?.stage.id).toBe('nst_6_8m');
    expect(nutritionStageFor(sorted, 7)?.stage.title.vi).toBe('Bắt đầu ăn dặm');
  });

  it('milk and solids follow the feeding guidance', () => {
    for (const s of stages) {
      const { ageMonths, milk, solids } = s.data;
      expect(milk, s.id).not.toBeNull();
      // Breastfeeding is always mentioned.
      expect(milk!.breastfeedingNote.vi.length, s.id).toBeGreaterThan(0);
      // Solids from 6 months only (WHO: exclusive breastfeeding to 6 months).
      if (ageMonths.from < 6) expect(solids, s.id).toBeNull();
      else expect(solids, s.id).not.toBeNull();
      expect(
        s.data.sampleDay.some((r) => r.kind === 'solids'),
        `${s.id} sample day`,
      ).toBe(ageMonths.from >= 6);
      // Daily bands within the AAP average maximum (about 960 ml) when present.
      if (milk!.perDayMl) expect(milk!.perDayMl.max, s.id).toBeLessThanOrEqual(960);
    }
    const byId = Object.fromEntries(stages.map((s) => [s.id, s.data]));
    // No daily band in the first month; the 6–8 month band as designed (9b); milk is a drink
    // of about 350–500 ml a day from 12 months.
    expect(byId.nst_0_1m!.milk!.perDayMl).toBeNull();
    expect(byId.nst_6_8m!.milk!.perDayMl).toEqual({ min: 600, max: 900 });
    expect(byId.nst_12_23m!.milk!.perDayMl).toEqual({ min: 350, max: 500 });
    expect(byId.nst_24_36m!.milk!.perDayMl).toEqual({ min: 350, max: 500 });
    // Every stage the milk rule covers (under 12 months) after the first has a band to compare to.
    for (const s of stages.filter((x) => x.data.ageMonths.to <= 12 && x.data.ageMonths.from > 0)) {
      expect(s.data.milk!.perDayMl, s.id).not.toBeNull();
    }
  });
});

describe('nutrition seed: nutrients', () => {
  it.each(nutrients.map((n) => [n.id, n] as const))('%s is publishable', (id, n) => {
    const parsed = nutrientStrictSchema.safeParse(n.data);
    expect(parsed.success, JSON.stringify(parsed.error?.issues.slice(0, 3))).toBe(true);
    checkCopy(id, n.data);
    checkSources(id, n.data.sources);
    expect(n.data.foods.length).toBeGreaterThanOrEqual(5);
    expect(n.data.byAge.length).toBeGreaterThanOrEqual(2);
    expect(n.data.tip).not.toBeNull();
    // The medical note always sends supplements to a doctor.
    expect(n.data.warning.vi).toMatch(/bác sĩ/);
    expect(n.data.warning.en).toMatch(/doctor/);
  });

  it('are the seven of the plan, one per key, each used by a stage', () => {
    expect(nutrients.map((n) => n.data.key).sort()).toEqual(
      ['calcium', 'dha', 'iodine', 'iron', 'vitaminA', 'vitaminD', 'zinc'].sort(),
    );
    const used = new Set(stages.flatMap((s) => s.data.nutrientIds));
    for (const n of nutrients) expect(used.has(n.id), n.id).toBe(true);
  });

  it('vitamin A carries the national campaign days; nothing else has a campaign', () => {
    const withCampaign = nutrients.filter((n) => n.data.campaign);
    expect(withCampaign.map((n) => n.id)).toEqual(['nut_vitamin_a']);
    const c = withCampaign[0]!.data.campaign!;
    expect(c.rounds).toEqual([
      { month: 6, fromDay: 1, toDay: 2 },
      { month: 12, fromDay: 1, toDay: 2 },
    ]);
    expect(c.ageMonths).toEqual({ from: 6, to: 37 });
    expect(c.place.vi).toBe('Trạm y tế phường, xã');
    // Every stage from 6 months lists vitamin A so 9b can show the next round.
    for (const s of stages.filter((x) => x.data.ageMonths.from >= 6)) {
      expect(s.data.nutrientIds, s.id).toContain('nut_vitamin_a');
    }
  });
});

describe('nutrition seed: rules', () => {
  it.each(rules.map((r) => [r.id, r] as const))('%s is publishable and fits', (id, r) => {
    const parsed = nutritionRuleStrictSchema.safeParse(r.data);
    expect(parsed.success, JSON.stringify(parsed.error?.issues.slice(0, 3))).toBe(true);
    checkCopy(id, r.data);
    expect(ruleFits(r.data)).toBe(true);
    expect(conditionsFor[r.data.metric]).toContain(r.data.condition);
    expect(r.data.days !== null, id).toBe(r.data.condition === 'noMeasurement');
    expect(r.data.tips.length).toBeGreaterThanOrEqual(1);
    // Calm wording: never a judgement on the child's body.
    for (const { s } of strings(r.data))
      expect(s.toLowerCase(), id).not.toMatch(/béo|\bfat\b|overweight/);
  });

  it('growth rules say they are not a diagnosis and name the baby', () => {
    for (const r of rules.filter((x) => x.data.metric === 'weight' || x.data.metric === 'length')) {
      expect(r.data.banner.vi, r.id).toContain('không phải chẩn đoán');
      expect(r.data.banner.en, r.id).toContain('not a diagnosis');
      expect(r.data.banner.vi, r.id).toContain('{name}');
      expect(r.data.banner.en, r.id).toContain('{name}');
      expect(r.data.ageMonths, r.id).toEqual({ from: 0, to: 37 });
      expect(r.data.export, r.id).toBe(true);
    }
  });

  it('match the D04 table', () => {
    const byId = Object.fromEntries(rules.map((r) => [r.id, r.data]));
    expect(byId.nru_weight_below).toMatchObject({
      metric: 'weight',
      condition: 'belowRange',
      remindAfterDays: 14,
      export: true,
    });
    expect(byId.nru_weight_below!.tips).toHaveLength(4);
    expect(byId.nru_weight_below!.banner.vi).toBe(
      '2 lần đo gần nhất của {name} thấp hơn khoảng chuẩn. Đây không phải chẩn đoán. Hãy cho bé đi khám dinh dưỡng để bác sĩ đánh giá.',
    );
    expect(byId.nru_weight_above).toMatchObject({ metric: 'weight', condition: 'aboveRange' });
    expect(byId.nru_length_below).toMatchObject({ metric: 'length', condition: 'belowRange' });
    expect(byId.nru_milk_outside).toMatchObject({
      metric: 'milk',
      condition: 'milkOutsideStage',
      ageMonths: { from: 0, to: 12 },
      remindAfterDays: null,
      export: false,
    });
    expect(byId.nru_milk_outside!.banner.vi).toMatch(/Mỗi bé mỗi khác/);
    expect(byId.nru_milk_outside!.banner.vi).toMatch(/trao đổi bác sĩ nếu kéo dài/);
    expect(byId.nru_no_measurement).toMatchObject({
      metric: 'measurement',
      condition: 'noMeasurement',
      days: 30,
      ageMonths: { from: 0, to: 25 },
      remindAfterDays: null,
      export: false,
    });
    expect(nutritionAgeLabel(byId.nru_no_measurement!.ageMonths)).toEqual({ from: 0, to: 24 });
    expect(byId.nru_no_measurement!.banner.vi).toMatch(/^Đã lâu chưa cập nhật cân nặng, chiều dài/);
  });
});
