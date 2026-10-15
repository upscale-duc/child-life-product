import { describe, expect, it } from 'vitest';
import {
  addMonthsIso,
  ageInUnit,
  articleDraftSchema,
  articleFitsAge,
  articleOverlapsWeeks,
  contentActRequestSchema,
  contentArticleSchema,
  contentSaveRequestSchema,
  contentStageSchema,
  editorialChecks,
  editorialDisplayStatus,
  isPlainText,
  readingMinutesOf,
  reviewDueFrom,
  stageBuckets,
  stageCoverage,
  stageFor,
  sortStages,
  type ContentArticle,
  type ContentStage,
} from '../src/index.js';

// Editorial content (D-076 #5–#7): the safe block model, the published shapes the app reads,
// the review workflow helpers, ages and the 0–24 month coverage.

const t = (vi: string, en: string) => ({ vi, en });
const meta = {
  status: 'published' as const,
  revision: 1,
  review: null,
  illustrative: true,
  reviewDueOn: '2027-10-15',
  publishedAt: '2026-10-15T03:00:00.000Z',
  firstPublishedAt: '2026-10-15T03:00:00.000Z',
};

const article: ContentArticle = {
  id: 'art_newborn_sleep',
  library: 'care',
  topic: 'sleep',
  format: 'article',
  ageWeeks: { from: 0, to: 13 },
  readingMinutes: 6,
  cover: { image: 'cover-sleep_0a1b2c3d', alt: t('Bé ngủ', 'Baby asleep') },
  title: t('Giấc ngủ của bé sơ sinh', 'Newborn sleep'),
  summary: t('Bé ngủ nhiều giấc ngắn.', 'Babies sleep in short stretches.'),
  body: {
    vi: [
      { type: 'paragraph', text: 'Trong những tuần đầu…' },
      { type: 'heading', text: 'Nhận biết bé buồn ngủ' },
      { type: 'bullets', items: ['Ngáp', 'Dụi mắt'] },
      { type: 'image', image: 'room-dark_0a1b2c3d', caption: '', alt: 'Phòng tối' },
      { type: 'callout', tone: 'doctor', title: 'Khi nào hỏi bác sĩ', text: 'Nếu bạn lo lắng…' },
    ],
    en: [{ type: 'paragraph', text: 'In the first weeks…' }],
  },
  keywords: { vi: ['ngủ'], en: ['sleep'] },
  relatedArticleIds: ['art_day_night'],
  milestoneIds: [],
  sources: [{ label: 'AAP', url: 'https://www.healthychildren.org/' }],
  ...meta,
};

const stage = (id: string, unit: 'week' | 'month', from: number, to: number): ContentStage => ({
  id,
  age: { unit, from, to },
  title: t('Bé nhìn theo mặt người', 'Baby follows faces'),
  doing: { vi: ['Nhìn rõ ở 20–30 cm'], en: ['Sees best at 20–30 cm'] },
  tryThis: { vi: ['Nói chuyện với bé'], en: ['Talk with baby'] },
  articleIds: [],
  milestoneIds: [],
  audience: ['coParent', 'caregiver'],
  cover: null,
  sources: [],
  ...meta,
});

describe('content · safe block model', () => {
  it('accepts a complete published article', () => {
    expect(contentArticleSchema.safeParse(article).success).toBe(true);
  });

  it('refuses markup in any text', () => {
    expect(isPlainText('Sốt < 38 độ là bình thường')).toBe(true);
    expect(isPlainText('<b>đậm</b>')).toBe(false);
    expect(isPlainText('<script>alert(1)</script>')).toBe(false);
    expect(isPlainText('xem javascript:alert(1)')).toBe(false);
    const bad = structuredClone(article);
    bad.body.vi[0] = { type: 'paragraph', text: 'Xin chào <img src=x onerror=alert(1)>' };
    expect(contentArticleSchema.safeParse(bad).success).toBe(false);
  });

  it('refuses unknown block types and extra fields', () => {
    const bad = structuredClone(article) as unknown as { body: { vi: unknown[] } };
    bad.body.vi.push({ type: 'html', html: '<p>x</p>' });
    expect(contentArticleSchema.safeParse(bad).success).toBe(false);
    const extra = { ...article, html: '<p>x</p>' };
    expect(contentArticleSchema.safeParse(extra).success).toBe(false);
  });

  it('lets drafts be incomplete but published items must have both languages', () => {
    const draft = { ...article, title: t('Giấc ngủ', ''), body: { vi: [], en: [] } };
    const { id: _id, status: _s, revision: _r, review: _rv, illustrative: _i, ...rest } = draft;
    void [_id, _s, _r, _rv, _i];
    const {
      reviewDueOn: _d,
      publishedAt: _p,
      firstPublishedAt: _f,
      ...content
    } = rest as typeof rest & Record<string, unknown>;
    void [_d, _p, _f];
    expect(articleDraftSchema.safeParse(content).success).toBe(true);
    expect(contentArticleSchema.safeParse(draft).success).toBe(false);
  });

  it('keeps illustrative in step with the review', () => {
    const reviewed = {
      ...article,
      review: { reviewer: 'BS. Hà', credential: 'Nhi khoa', reviewedOn: '2026-10-01' },
    };
    expect(contentArticleSchema.safeParse(reviewed).success).toBe(false);
    expect(contentArticleSchema.safeParse({ ...reviewed, illustrative: false }).success).toBe(true);
  });

  it('estimates reading time from the words', () => {
    const words = Array.from({ length: 1200 }, () => 'chữ').join(' ');
    expect(readingMinutesOf([{ type: 'paragraph', text: words }])).toBe(6);
    expect(readingMinutesOf([])).toBe(1);
  });
});

describe('content · stages', () => {
  it('limits the title to 60 characters and each list to 3 points', () => {
    expect(contentStageSchema.safeParse(stage('stg_w3', 'week', 3, 5)).success).toBe(true);
    const long = stage('stg_w3', 'week', 3, 5);
    long.title.vi = 'x'.repeat(61);
    expect(contentStageSchema.safeParse(long).success).toBe(false);
    const many = stage('stg_w3', 'week', 3, 5);
    many.doing = { vi: ['a', 'b', 'c', 'd'], en: ['a', 'b', 'c', 'd'] };
    expect(contentStageSchema.safeParse(many).success).toBe(false);
    const uneven = stage('stg_w3', 'week', 3, 5);
    uneven.tryThis = { vi: ['a', 'b'], en: ['a'] };
    expect(contentStageSchema.safeParse(uneven).success).toBe(false);
  });

  it('counts completed weeks and calendar months', () => {
    expect(ageInUnit('2026-09-17', '2026-10-08', 'week')).toBe(3);
    expect(ageInUnit('2026-01-31', '2026-02-27', 'month')).toBe(0);
    expect(ageInUnit('2026-01-31', '2026-02-28', 'month')).toBe(1);
    expect(ageInUnit('2026-01-15', '2027-01-14', 'month')).toBe(11);
    expect(ageInUnit('2026-01-15', '2027-01-15', 'month')).toBe(12);
    expect(ageInUnit('2026-10-20', '2026-10-15', 'week')).toBe(0);
  });

  it('picks the narrowest stage when weeks and months overlap', () => {
    const stages = [
      stage('stg_w0', 'week', 0, 3),
      stage('stg_w3', 'week', 3, 5),
      stage('stg_m1', 'month', 1, 2),
    ];
    expect(stageFor(stages, '2026-09-17', '2026-10-08')?.id).toBe('stg_w3');
    // Day 31: 4 weeks and 1 month both hold; the 2-week range wins.
    expect(stageFor(stages, '2026-09-01', '2026-10-02')?.id).toBe('stg_w3');
    // Day 36: past 5 weeks, so 1–2 months.
    expect(stageFor(stages, '2026-09-01', '2026-10-07')?.id).toBe('stg_m1');
    expect(stageFor(stages, '2026-10-20', '2026-10-15')).toBeNull();
    expect(sortStages([stages[2]!, stages[0]!, stages[1]!]).map((s) => s.id)).toEqual([
      'stg_w0',
      'stg_w3',
      'stg_m1',
    ]);
  });

  it('reports coverage over the 16 ranges, drafts included, with the gaps', () => {
    expect(stageBuckets).toHaveLength(16);
    const c = stageCoverage([
      { age: { unit: 'week', from: 0, to: 3 }, status: 'published', live: true },
      { age: { unit: 'week', from: 3, to: 5 }, status: 'draft', live: true },
      { age: { unit: 'month', from: 1, to: 2 }, status: 'in_review', live: false },
      { age: { unit: 'month', from: 2, to: 3 }, status: 'draft', live: false },
      { age: { unit: 'month', from: 12, to: 18 }, status: 'approved', live: false },
      { age: { unit: 'month', from: 3, to: 4 }, status: 'archived', live: false },
    ]);
    const state = Object.fromEntries(c.buckets.map((b) => [b.id, b.state]));
    expect(state).toMatchObject({
      w0: 'published',
      w3: 'published',
      m1: 'pending',
      m2: 'draft',
      m3: 'missing',
      m12: 'pending',
      m15: 'pending',
      m18: 'missing',
    });
    expect(c.covered).toBe(6);
    expect(c.published).toBe(2);
    expect(c.total).toBe(16);
    expect(c.gaps).toContain('m3');
  });
});

describe('content · workflow', () => {
  it('shows a published item past its date as due for re-review', () => {
    expect(
      editorialDisplayStatus({ status: 'published', reviewDueOn: '2026-10-14' }, '2026-10-15'),
    ).toBe('needs_rereview');
    expect(
      editorialDisplayStatus({ status: 'published', reviewDueOn: '2026-10-15' }, '2026-10-15'),
    ).toBe('published');
    expect(
      editorialDisplayStatus({ status: 'draft', reviewDueOn: '2020-01-01' }, '2026-10-15'),
    ).toBe('draft');
  });

  it('adds 12 months, clamping to the month end', () => {
    expect(reviewDueFrom('2026-10-15')).toBe('2027-10-15');
    expect(addMonthsIso('2028-02-29', 12)).toBe('2029-02-28');
    expect(addMonthsIso('2026-01-31', 1)).toBe('2026-02-28');
  });

  it('needs a reason to reject or unpublish and every check to approve', () => {
    const base = { kind: 'article', id: 'art_newborn_sleep', reason: '' } as const;
    expect(contentActRequestSchema.safeParse({ ...base, action: 'submit' }).success).toBe(true);
    expect(contentActRequestSchema.safeParse({ ...base, action: 'reject' }).success).toBe(false);
    expect(contentActRequestSchema.safeParse({ ...base, action: 'unpublish' }).success).toBe(false);
    expect(contentActRequestSchema.safeParse({ ...base, action: 'approve' }).success).toBe(false);
    expect(
      contentActRequestSchema.safeParse({
        ...base,
        action: 'approve',
        checks: [...editorialChecks],
      }).success,
    ).toBe(true);
  });

  it('validates the save payload per kind', () => {
    const { id: _id, ...content } = article;
    void _id;
    const data = Object.fromEntries(
      Object.entries(content).filter(
        ([k]) =>
          ![
            'status',
            'revision',
            'review',
            'illustrative',
            'reviewDueOn',
            'publishedAt',
            'firstPublishedAt',
          ].includes(k),
      ),
    );
    const req = { kind: 'article', id: null, data, reviewerLabel: null, notes: '' };
    expect(contentSaveRequestSchema.safeParse(req).success).toBe(true);
    expect(contentSaveRequestSchema.safeParse({ ...req, kind: 'stage' }).success).toBe(false);
  });
});

describe('content · age filters', () => {
  it('matches articles by overlap and by the baby age in weeks', () => {
    expect(articleOverlapsWeeks(article, 0, 13)).toBe(true);
    expect(articleOverlapsWeeks(article, 13, 26)).toBe(false);
    expect(articleFitsAge(article, '2026-09-17', '2026-10-08')).toBe(true);
    expect(articleFitsAge(article, '2026-01-01', '2026-10-08')).toBe(false);
  });
});
