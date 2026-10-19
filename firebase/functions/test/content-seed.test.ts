import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  articleContentStrictSchema,
  type ContentBlock,
  contentEmergencyToken,
  isPlainText,
  literalEmergencyProblems,
  readingMinutesOf,
  solidsSubtopics,
  stageBuckets,
  stageContentStrictSchema,
  stageCoverage,
} from '@child-life/contracts';
import { describe, expect, it } from 'vitest';
import { seedArticles, seedStages } from '../src/content-seed.js';

// The engineering drafts (D-073 #2) that staffContentSeed imports: complete in vi and en, linked
// only to ids that exist, one stage per fixed 0–24 month range, every article ending on the
// "Khi nào nên hỏi bác sĩ" doctor callout and never claiming a review it has not had.
const ids = seedArticles.map((a) => a.id);
const milestonesSeed = JSON.parse(
  readFileSync(
    resolve(import.meta.dirname, '../../../content/milestones/milestones.seed.json'),
    'utf8',
  ),
) as { milestones: { id: string }[] };
const milestoneIds: string[] = milestonesSeed.milestones.map((m) => m.id);

/** Every string anywhere in [value] (titles, blocks, keywords, stage points, source labels). */
function strings(value: unknown): string[] {
  if (typeof value === 'string') return [value];
  if (Array.isArray(value)) return value.flatMap(strings);
  if (value && typeof value === 'object') return Object.values(value).flatMap(strings);
  return [];
}

const shape = (blocks: readonly ContentBlock[]) =>
  blocks.map((b) =>
    b.type === 'bullets'
      ? `bullets:${b.items.length}`
      : b.type === 'callout'
        ? `callout:${b.tone}`
        : b.type,
  );

/** "4–7 phút đọc" per format (4c): articles 3–7, step guides 2–6, quick Q&A 1–2 minutes. */
const minutes = { article: [3, 7], step_guide: [2, 6], quick_qa: [1, 2] } as const;

/** Never claim a qualified review: these items ship as "Nội dung minh hoạ · chờ chuyên môn duyệt". */
const reviewClaim =
  /đã được (bác sĩ|chuyên gia|chuyên môn)|kiểm duyệt bởi|reviewed by|approved by/i;

describe('editorial seed', () => {
  it('a 0–24 month library in both libraries, ids unique', () => {
    expect(seedArticles.length).toBeGreaterThanOrEqual(28);
    expect(new Set(ids).size).toBe(ids.length);
    expect(seedArticles.filter((a) => a.data.library === 'solids').length).toBeGreaterThanOrEqual(
      4,
    );
    // Thư viện ăn dặm (D-085): the 7 seeded guides plus the 16 in solids-seed.ts.
    expect(
      seedArticles.filter((a) => a.data.library === 'solids').length,
      'solids articles',
    ).toBeGreaterThanOrEqual(20);
    // Every 4c age band has something to read.
    for (const [from, to] of [
      [0, 13],
      [13, 26],
      [26, 52],
      [52, 104],
    ] as const) {
      expect(
        seedArticles.filter((a) => a.data.ageWeeks.from < to && from < a.data.ageWeeks.to).length,
        `${from}–${to} weeks`,
      ).toBeGreaterThanOrEqual(8);
    }
  });

  it.each(seedArticles.map((a) => [a.id, a] as const))(
    '%s is publishable and consistent',
    (_, a) => {
      const d = a.data;
      const parsed = articleContentStrictSchema.safeParse(d);
      expect(parsed.success, JSON.stringify(parsed.error?.issues.slice(0, 3))).toBe(true);

      // Links resolve: related articles exist (never itself), milestones exist in the milestones seed.
      for (const r of d.relatedArticleIds) {
        expect(ids).toContain(r);
        expect(r).not.toBe(a.id);
      }
      expect(new Set(d.relatedArticleIds).size).toBe(d.relatedArticleIds.length);
      for (const m of d.milestoneIds) expect(milestoneIds).toContain(m);

      // Reading time is what the reader computes, within the range of the format.
      expect(d.readingMinutes).toBe(readingMinutesOf(d.body.vi));
      const [lo, hi] = minutes[d.format];
      expect(d.readingMinutes).toBeGreaterThanOrEqual(lo);
      expect(d.readingMinutes).toBeLessThanOrEqual(hi);

      // vi and en say the same thing in the same order; both end on "when to see a doctor".
      expect(shape(d.body.en)).toEqual(shape(d.body.vi));
      expect(d.keywords.en).toHaveLength(d.keywords.vi.length);
      for (const body of [d.body.vi, d.body.en]) {
        const last = body.at(-1);
        expect(last?.type === 'callout' && last.tone === 'doctor').toBe(true);
        expect(body[0]?.type === 'callout' && body[0].tone === 'note').toBe(true);
      }

      // Sources: real pages over https (a help line's home page counts), at least two per article.
      expect(d.sources.length).toBeGreaterThanOrEqual(2);
      for (const s of d.sources) expect(s.url).toMatch(/^https:\/\/[^/]+\//);

      // Plain text everywhere, no claimed review, no markdown.
      for (const s of strings(d)) {
        if (s.startsWith('https://')) continue;
        expect(isPlainText(s), s).toBe(true);
        expect(s, s).not.toMatch(reviewClaim);
        expect(s, s).not.toMatch(/\*\*|^#|https?:\/\//);
      }
    },
  );

  it('health articles carry {emergency}', () => {
    for (const a of seedArticles.filter((x) => x.data.topic === 'illness')) {
      for (const body of [a.data.body.vi, a.data.body.en]) {
        const text = body
          .map((b) =>
            b.type === 'callout' && (b.tone === 'doctor' || b.tone === 'urgent')
              ? `${b.title} ${b.text}`
              : '',
          )
          .join(' ');
        expect(text, a.id).toContain(contentEmergencyToken);
      }
    }
  });

  // Families abroad (D-087, P-166 #1–#2): content names the family's number as `{emergency}`, never
  // "115"; the app fills it in. Titles say "gọi cấp cứu" rather than a number.
  it('no literal emergency number anywhere in the articles or the milestones seed', () => {
    for (const a of seedArticles) expect(literalEmergencyProblems(a.data), a.id).toEqual([]);
    expect(literalEmergencyProblems(milestonesSeed)).toEqual([]);
  });

  it('titles hold neither {emergency} nor 115', () => {
    for (const a of seedArticles) {
      for (const title of [a.data.title.vi, a.data.title.en]) {
        expect(title, a.id).not.toContain(contentEmergencyToken);
        expect(title, a.id).not.toMatch(/115/);
      }
    }
  });

  it('urgent callouts say "Gọi {emergency} ngay khi" and come before the final doctor callout', () => {
    for (const a of seedArticles) {
      for (const [body, title] of [
        [a.data.body.vi, `Gọi ${contentEmergencyToken} ngay khi`],
        [a.data.body.en, `Call ${contentEmergencyToken} now if`],
      ] as const) {
        body.forEach((b, i) => {
          if (b.type !== 'callout' || b.tone !== 'urgent') return;
          expect(b.title, a.id).toBe(title);
          expect(i, a.id).toBeLessThan(body.length - 1);
        });
      }
    }
  });

  // Thư viện ăn dặm readability (D-087, P-166 #4–#5): every guide has its group (and its picture);
  // paragraphs are split at about 450 characters.
  it('every solids guide has a subtopic; care guides have none', () => {
    for (const a of seedArticles) {
      if (a.data.library === 'solids') expect(solidsSubtopics, a.id).toContain(a.data.subtopic);
      else expect(a.data.subtopic ?? null, a.id).toBeNull();
    }
  });

  it('solids guides keep paragraphs to 480 characters', () => {
    for (const a of seedArticles.filter((x) => x.data.library === 'solids')) {
      for (const body of [a.data.body.vi, a.data.body.en]) {
        for (const b of body) {
          if (b.type === 'paragraph')
            expect(b.text.length, `${a.id}: ${b.text}`).toBeLessThanOrEqual(480);
        }
      }
    }
  });

  it('one stage per range, 3 + 3 points, linked to seed articles and milestones, covering 0–36 months', () => {
    expect(seedStages.map((s) => s.data.age)).toEqual(
      stageBuckets.map((b) => ({ unit: b.unit, from: b.from, to: b.to })),
    );
    expect(new Set(seedStages.map((s) => s.id)).size).toBe(seedStages.length);
    for (const s of seedStages) {
      const parsed = stageContentStrictSchema.safeParse(s.data);
      expect(parsed.success, `${s.id} ${JSON.stringify(parsed.error?.issues.slice(0, 3))}`).toBe(
        true,
      );
      for (const lang of ['vi', 'en'] as const) {
        expect(s.data.doing[lang], s.id).toHaveLength(3);
        expect(s.data.tryThis[lang], s.id).toHaveLength(3);
      }
      expect(s.data.articleIds.length, s.id).toBeGreaterThanOrEqual(1);
      for (const a of s.data.articleIds) expect(ids, s.id).toContain(a);
      expect(s.data.milestoneIds.length, s.id).toBeGreaterThanOrEqual(1);
      for (const m of s.data.milestoneIds) expect(milestoneIds, s.id).toContain(m);
      expect(s.data.sources.length, s.id).toBeGreaterThanOrEqual(1);
      for (const str of strings(s.data)) {
        if (str.startsWith('https://')) continue;
        expect(isPlainText(str), str).toBe(true);
        expect(str, str).not.toMatch(reviewClaim);
      }
    }
    const c = stageCoverage(
      seedStages.map((s) => ({ age: s.data.age, status: 'draft', live: false })),
    );
    expect(c.covered).toBe(18);
    expect(c.gaps).toEqual([]);
  });
});
