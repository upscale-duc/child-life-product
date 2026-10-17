import { editorialChecks, type ArticleDraft, type StageDraft } from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, ApiError, type Api } from '../src/api';
import { StaffContext } from '../src/context';
import { messages } from '../src/messages';
import { Sidebar } from '../src/Shell';
import { ArticleEditor, ArticlesBody, blankArticle, filterArticles } from '../src/screens/Articles';
import { ReviewBody, ReviewDetail, queueRows } from '../src/screens/ContentReview';
import { MilestoneEditor, MilestonesBody } from '../src/screens/Milestones';
import { StageEditor, StagesBody, blankStage } from '../src/screens/Stages';
import {
  actionsFor,
  blankActInput,
  contentActRequest,
  issuePlace,
  stageAgeText,
  weeksLabel,
  type ContentItemView,
  type ContentListView,
  type ContentQueueView,
  type ContentRow,
} from '../src/screens/content-common';
import { errorMessageId } from '../src/ui';
import { createIntl } from 'react-intl';
import { levelsForRoles, type StaffRole } from './fixtures';

// Editorial content on the portal (D-076 #5–#7, B01–B08): lists, editors, coverage and the review
// queue, server-rendered with a fake api that records calls.

type Call = { name: string; data: unknown };
function fakeApi(answers: Record<string, unknown> = {}) {
  const calls: Call[] = [];
  const api: Api = {
    call: <T,>(name: string, data?: unknown) => {
      calls.push({ name, data });
      return name in answers
        ? Promise.resolve(answers[name] as T)
        : Promise.reject(new ApiError('internal', null));
    },
  };
  return { api, calls };
}

function render(
  node: ReactNode,
  roles: StaffRole[] = ['admin'],
  locale: 'vi' | 'en' = 'vi',
  api: Api = fakeApi().api,
) {
  return renderToStaticMarkup(
    <IntlProvider
      locale={locale}
      defaultLocale="vi"
      messages={messages[locale]}
      onError={(e) => {
        throw e;
      }}
    >
      <ApiContext.Provider value={api}>
        <StaffContext.Provider
          value={{
            uid: 's1',
            email: 'linh@example.com',
            name: 'Linh Trần',
            roles,
            levels: levelsForRoles(roles),
          }}
        >
          {node}
        </StaffContext.Provider>
      </ApiContext.Provider>
    </IntlProvider>,
  );
}
const text = (html: string) =>
  html
    .replace(/<[^>]+>/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#x27;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/\s+/g, ' ');

const t = (vi: string, en: string) => ({ vi, en });
const counts = {
  inApp: 9,
  pending: 3,
  inReview: 2,
  approved: 1,
  drafts: 4,
  dueForReview: 1,
  archived: 0,
  total: 14,
};

const row = (over: Partial<ContentRow>): ContentRow => ({
  id: 'art_newborn_sleep',
  kind: 'article',
  status: 'draft',
  displayStatus: 'draft',
  live: null,
  title: t('Giấc ngủ của bé sơ sinh', 'Newborn sleep'),
  reviewerLabel: 'Nhóm chuyên môn · Nhi khoa',
  lastEditorName: 'Hà Vũ',
  updatedAt: '2026-10-15T03:00:00.000Z',
  submittedByName: null,
  approverName: null,
  rejection: null,
  links: { articles: [], milestones: [] },
  ...over,
});

const articleRows: ContentRow[] = [
  row({
    library: 'care',
    topic: 'sleep',
    ageWeeks: { from: 0, to: 13 },
    readingMinutes: 6,
    blocks: { vi: 9, en: 9 },
  }),
  row({
    id: 'art_fever_when_to_call',
    title: t('Khi bé sốt: những điều ba mẹ cần biết', ''),
    status: 'published',
    displayStatus: 'needs_rereview',
    topic: 'illness',
    library: 'care',
    ageWeeks: { from: 0, to: 104 },
    readingMinutes: 7,
    blocks: { vi: 10, en: 0 },
    live: {
      revision: 2,
      publishedAt: '2025-09-01T00:00:00.000Z',
      reviewDueOn: '2026-09-01',
      illustrative: true,
      reviewer: null,
      dueForReview: true,
    },
  }),
];

const articleView: ContentListView = {
  view: 'article',
  today: '2026-10-15',
  rows: articleRows,
  counts,
  available: ['article', 'stage', 'milestone'],
  requireReview: false,
};

describe('navigation', () => {
  it('adds the four content pages for anyone with Nội dung · Xem', () => {
    const sidebar = (roles: StaffRole[], locale: 'vi' | 'en' = 'vi') =>
      text(
        render(
          <Sidebar
            route="articles"
            badges={null}
            environment="dev"
            locale={locale}
            onLocale={() => undefined}
            onSignOut={() => undefined}
            navigate={() => undefined}
          />,
          roles,
          locale,
        ),
      );
    for (const role of ['admin', 'ops', 'support', 'expert'] as const) {
      const s = sidebar([role]);
      for (const label of [
        'Bài viết',
        'Nội dung theo giai đoạn',
        'Mốc phát triển',
        'Duyệt nội dung',
      ]) {
        expect(s).toContain(label);
      }
    }
    expect(sidebar(['eng'])).not.toContain('Duyệt nội dung');
    expect(sidebar(['admin'], 'en')).toContain('Stage content');
  });

  it('has a message for the new server reasons', () => {
    for (const r of ['not-approved', 'not-live', 'link-missing']) {
      expect(errorMessageId(new ApiError('failed-precondition', r))).toBe(`error.${r}`);
    }
  });
});

describe('B01 articles list', () => {
  it('shows the counts, rows, status and re-review flags', () => {
    const html = text(render(<ArticlesBody view={articleView} onOpen={() => undefined} />));
    expect(html).toContain('Đang trên app 9');
    expect(html).toContain('Chờ duyệt 3');
    expect(html).toContain('1 đã duyệt, chờ xuất bản');
    expect(html).toContain('Cần rà soát lại 1');
    expect(html).toContain('Giấc ngủ của bé sơ sinh');
    expect(html).toContain('0–3 tháng');
    expect(html).toContain('0–24 tháng');
    expect(html).toContain('Minh hoạ');
    expect(html).toContain('Nhóm chuyên môn · Nhi khoa');
  });

  it('filters by topic, age band (overlap), status and missing language', () => {
    const base = {
      q: '',
      library: 'all',
      topic: 'all',
      age: 'all',
      status: 'all',
      reviewer: 'all',
      lang: 'all',
    };
    expect(filterArticles(articleRows, { ...base, topic: 'illness' }).map((r) => r.id)).toEqual([
      'art_fever_when_to_call',
    ]);
    expect(filterArticles(articleRows, { ...base, age: '12-24' }).map((r) => r.id)).toEqual([
      'art_fever_when_to_call',
    ]);
    expect(filterArticles(articleRows, { ...base, status: 'needs_rereview' })).toHaveLength(1);
    expect(filterArticles(articleRows, { ...base, lang: 'missingEn' }).map((r) => r.id)).toEqual([
      'art_fever_when_to_call',
    ]);
    expect(filterArticles(articleRows, { ...base, q: 'ngủ' })).toHaveLength(1);
  });

  it('labels article ages in months when whole, else weeks', () => {
    const intl = createIntl({ locale: 'vi', messages: messages.vi });
    expect(weeksLabel(intl, { from: 0, to: 13 })).toBe('0–3 tháng');
    expect(weeksLabel(intl, { from: 2, to: 26 })).toBe('2–25 tuần');
    expect(stageAgeText(intl, { unit: 'week', from: 3, to: 5 })).toBe('3–4 tuần');
    expect(stageAgeText(intl, { unit: 'month', from: 12, to: 15 })).toBe('12–15 tháng');
  });
});

const fullArticle = (): ArticleDraft => ({
  ...blankArticle(),
  title: t('Giấc ngủ của bé sơ sinh', 'Newborn sleep'),
  summary: t('Bé ngủ nhiều giấc ngắn.', 'Short stretches of sleep.'),
  body: {
    vi: [
      { type: 'paragraph', text: 'Trong những tuần đầu, bé ngủ nhiều.' },
      { type: 'heading', text: 'Nhận biết bé buồn ngủ' },
      { type: 'bullets', items: ['Ngáp', 'Dụi mắt'] },
      { type: 'callout', tone: 'doctor', title: 'Khi nào nên hỏi bác sĩ', text: 'Nếu bạn lo.' },
    ],
    en: [{ type: 'paragraph', text: 'In the first weeks, babies sleep a lot.' }],
  },
  sources: [{ label: 'AAP', url: 'https://www.healthychildren.org/' }],
});

const itemOf = <T,>(data: T, over: Partial<ContentRow> = {}, lastEditorUid = 'u_other') =>
  ({
    row: row(over),
    data,
    notes: '',
    lastEditorUid,
    pendingReview: null,
    published: null,
  }) as ContentItemView<T>;

describe('B02 article editor', () => {
  const editor = (
    item: ContentItemView<ArticleDraft> | null,
    roles: StaffRole[] = ['admin'],
    locale: 'vi' | 'en' = 'vi',
  ) =>
    text(
      render(
        <ArticleEditor
          item={item}
          articles={articleRows}
          requireReview={false}
          today="2026-10-15"
          staffUid="s1"
          canEdit
          canApprove={roles.includes('admin') || roles.includes('expert')}
          onBack={() => undefined}
          onSaved={() => undefined}
          onChanged={() => undefined}
        />,
        roles,
        locale,
      ),
    );

  it('edits the safe blocks and shows the app reader preview', () => {
    const html = editor(itemOf(fullArticle()));
    // The editor bar: back to the list, the title, the status, the next step.
    expect(html).toContain('Bài viết Giấc ngủ của bé sơ sinh Nháp');
    expect(html).toContain('Nội dung bài (4/60 khối)');
    for (const kind of ['Đoạn văn', 'Tiêu đề mục', 'Danh sách', 'Hộp lưu ý']) {
      expect(html).toContain(kind);
    }
    expect(html).toContain('Tiêu đề 23/90');
    expect(html).toContain('Xem trước trên app');
    expect(html).toContain('Nội dung minh hoạ · chờ chuyên môn duyệt');
    expect(html).toContain('Khi nào nên hỏi bác sĩ');
    expect(html).toContain('Gửi duyệt');
    expect(html).not.toContain('<b>');
  });

  it('a new article starts as an unsaved draft without workflow buttons', () => {
    const html = editor(null);
    expect(html).toContain('Bài viết mới');
    expect(html).toContain('Chưa lưu');
    expect(html).not.toContain('Gửi duyệt');
  });

  it('an incomplete draft lists what blocks review and hides "Gửi duyệt"', () => {
    const half = fullArticle();
    half.title.en = '';
    const html = editor(itemOf(half));
    expect(html).toContain('chỗ cần hoàn thiện');
    expect(html).toContain('Tiêu đề · EN');
    expect(html).not.toContain('Gửi duyệt');
  });

  it('approvers see the step for the status; English catalog renders', () => {
    const html = editor(itemOf(fullArticle(), { status: 'approved', displayStatus: 'approved' }));
    expect(html).toContain('Xuất bản');
    expect(html).toContain('Trả lại');
    const en = editor(
      itemOf(fullArticle(), { status: 'in_review', displayStatus: 'in_review' }),
      ['admin'],
      'en',
    );
    expect(en).toContain('Approve');
    expect(en).toContain('Settings');
  });
});

const stageRows: ContentRow[] = [
  row({
    id: 'stg_w3',
    kind: 'stage',
    title: t('Bé nhìn theo mặt người, nghe giọng quen', 'Baby follows faces'),
    status: 'published',
    displayStatus: 'published',
    age: { unit: 'week', from: 3, to: 5 },
    points: { doing: 3, tryThis: 3 },
    audience: ['coParent', 'caregiver'],
    links: { articles: ['art_tummy_time', 'art_newborn_sleep'], milestones: ['smiles_back'] },
    live: {
      revision: 1,
      publishedAt: '2026-09-01T00:00:00.000Z',
      reviewDueOn: '2027-09-01',
      illustrative: true,
      reviewer: null,
      dueForReview: false,
    },
  }),
  row({
    id: 'stg_m8',
    kind: 'stage',
    title: t('Bò, bám đứng', 'Crawling, pulling up'),
    age: { unit: 'month', from: 8, to: 9 },
    points: { doing: 2, tryThis: 3 },
    audience: ['coParent'],
  }),
];

const stageView: ContentListView = {
  view: 'stage',
  today: '2026-10-15',
  rows: stageRows,
  counts: { ...counts, inApp: 1, drafts: 1 },
  coverage: {
    buckets: [
      { id: 'w0', unit: 'week', from: 0, to: 3, state: 'missing', itemIds: [] },
      { id: 'w3', unit: 'week', from: 3, to: 5, state: 'published', itemIds: ['stg_w3'] },
      { id: 'm8', unit: 'month', from: 8, to: 9, state: 'draft', itemIds: ['stg_m8'] },
      { id: 'm12', unit: 'month', from: 12, to: 15, state: 'missing', itemIds: [] },
    ],
    covered: 14,
    published: 12,
    total: 16,
    gaps: ['w0', 'm12'],
  },
  available: ['article', 'stage', 'milestone'],
  requireReview: false,
};

describe('B05 / B06 stage content', () => {
  it('shows the 0–24 month coverage with the gaps, and the list by age', () => {
    const html = text(
      render(
        <StagesBody view={stageView} canEdit onOpen={() => undefined} onCreate={() => undefined} />,
      ),
    );
    expect(html).toContain('Độ phủ 0–24 tháng');
    expect(html).toContain('14 / 16 khoảng có nội dung');
    expect(html).toContain('Chưa có · 0–2 tuần, 12–15 tháng');
    expect(html).toContain('3–4 tuần');
    expect(html).toContain('3/3 · 3/3');
    expect(html).toContain('2/3 · 3/3');
    expect(html).toContain('2/2');
    expect(html.indexOf('3–4 tuần Bé nhìn')).toBeLessThan(html.indexOf('8–9 tháng Bò'));
  });

  it('the editor has the age range, 60-character title, 3 + 3 points and the 2b preview', () => {
    const data: StageDraft = {
      ...blankStage('w3'),
      title: t('Bé nhìn theo mặt người, nghe giọng quen', 'Baby follows faces, knows voices'),
      doing: {
        vi: ['Nhìn rõ nhất ở khoảng cách 20–30 cm', 'Quay về phía giọng nói quen thuộc'],
        en: ['Sees best at 20–30 cm', 'Turns to familiar voices'],
      },
      tryThis: { vi: ['Nói chuyện, hát nhẹ khi bé thức'], en: ['Talk and sing softly'] },
      articleIds: ['art_newborn_sleep'],
    };
    const html = text(
      render(
        <StageEditor
          item={itemOf(data, { kind: 'stage', id: 'stg_w3' })}
          bucket={null}
          articles={articleRows}
          milestones={[]}
          requireReview={false}
          today="2026-10-15"
          staffUid="s1"
          canEdit
          canApprove
          onBack={() => undefined}
          onSaved={() => undefined}
          onChanged={() => undefined}
        />,
      ),
    );
    expect(html).toContain('Nội dung theo giai đoạn 3–4 tuần · Bé nhìn theo mặt người');
    expect(html).toContain('Tiêu đề trên thẻ 39/60');
    expect(html).toContain('Bé đang thế nào (tối đa 3 ý) 2/3');
    expect(html).toContain('Ba mẹ có thể thử (tối đa 3 ý) 1/3');
    expect(html).toContain('Bài viết liên quan (tối đa 2) 1/2');
    expect(html).toContain('Bố mẹ');
    expect(html).toContain('Teddy · 3 tuần');
    expect(html).toContain('Mỗi bé phát triển theo nhịp riêng.');
    expect(blankStage('m12').age).toEqual({ unit: 'month', from: 12, to: 15 });
  });
});

describe('B07 / B08 milestones', () => {
  const milestoneView: ContentListView = {
    ...articleView,
    view: 'milestone',
    rows: [
      row({
        id: 'smiles_back',
        kind: 'milestone',
        title: t('Mỉm cười đáp lại', 'Smiles back'),
        group: 'socialEmotional',
        order: 10,
        ageRange: { unit: 'months', from: 1, to: 3 },
      }),
      row({
        id: 'lifts_head',
        kind: 'milestone',
        title: t('Ngẩng đầu khi nằm sấp', 'Lifts head on tummy'),
        group: 'motor',
        order: 10,
        ageRange: { unit: 'weeks', from: 4, to: 12 },
      }),
    ],
  };

  it('lists by group with the reference ages and the no-judgement note', () => {
    const raw = render(<MilestonesBody view={milestoneView} onOpen={() => undefined} />);
    const html = text(raw);
    // The no-judgement note sits behind the "?" of the reference-age column.
    expect(raw).toMatch(/Độ tuổi tham khảo<button[^>]*aria-label="Giải thích"/);
    expect(html).toContain('Đang trên app 9');
    expect(html.indexOf('Vận động')).toBeLessThan(html.indexOf('Cảm xúc – xã hội'));
    expect(html).toContain('1–3 tháng');
    expect(html).toContain('4–12 tuần');
  });

  it('the editor previews 3b', () => {
    const html = text(
      render(
        <MilestoneEditor
          item={null}
          requireReview={false}
          today="2026-10-15"
          staffUid="s1"
          canEdit
          canApprove
          onBack={() => undefined}
          onSaved={() => undefined}
          onChanged={() => undefined}
        />,
      ),
    );
    expect(html).toContain('Mốc mới');
    expect(html).toContain('Cách nhận biết');
    expect(html).toContain('Tham khảo: 1–3 tháng');
  });
});

describe('B03 / B04 review queue', () => {
  const queue: ContentQueueView = {
    view: 'queue',
    today: '2026-10-15',
    rows: [
      row({ status: 'in_review', displayStatus: 'in_review', submittedByName: 'Hà Vũ' }),
      row({
        id: 'stg_m15',
        kind: 'stage',
        title: t('Bé đi vững, thích khám phá', 'Steady on feet'),
        status: 'approved',
        displayStatus: 'approved',
        approverName: 'BS. Lan',
        age: { unit: 'month', from: 15, to: 18 },
      }),
      articleRows[1]!,
    ],
    counts: { article: counts, stage: counts, milestone: counts },
    totals: counts,
    available: ['article', 'stage', 'milestone'],
    requireReview: false,
  };

  it('splits review, publish and re-review across kinds', () => {
    expect(queueRows(queue.rows, 'in_review')).toHaveLength(1);
    expect(queueRows(queue.rows, 'approved').map((r) => r.kind)).toEqual(['stage']);
    expect(queueRows(queue.rows, 'due').map((r) => r.id)).toEqual(['art_fever_when_to_call']);
    const html = text(render(<ReviewBody view={queue} onChanged={() => undefined} />));
    expect(html).toContain('Chờ duyệt · 1');
    expect(html).toContain('Đã duyệt · 1');
    expect(html).toContain('Cần rà soát lại · 1');
    expect(html).toContain('Nháp Chờ duyệt Đã duyệt Đã xuất bản');
    const published = text(
      render(<ReviewBody view={queue} onChanged={() => undefined} initialTab="approved" />),
    );
    expect(published).toContain('Bé đi vững, thích khám phá');
    expect(published).toContain('15–18 tháng');
  });

  it('the detail shows sources, the same-person rule and the step actions', () => {
    const item = itemOf(
      fullArticle(),
      { status: 'in_review', displayStatus: 'in_review' },
      's1',
    ) as unknown as ContentItemView;
    const html = text(
      render(
        <ReviewDetail
          item={item}
          requireReview={false}
          today="2026-10-15"
          staffUid="s1"
          can={{ edit: true, approve: true }}
          onChanged={() => undefined}
        />,
      ),
    );
    expect(html).toContain('AAP');
    expect(html).toContain('Bạn là người sửa lần cuối');
    expect(html).toContain('Duyệt');
    expect(html).not.toContain('Huỷ bản nháp');
    const viewer = text(
      render(<ReviewBody view={queue} onChanged={() => undefined} />, ['support']),
    );
    expect(viewer).toContain('Bạn đang xem');
  });
});

describe('workflow requests', () => {
  it('offers the actions of the status and role', () => {
    const can = { edit: true, approve: true };
    expect(actionsFor({ status: 'draft', live: null }, can)).toEqual(['submit', 'archive']);
    expect(actionsFor({ status: 'in_review', live: null }, can)).toEqual([
      'approve',
      'reject',
      'archive',
    ]);
    expect(actionsFor({ status: 'approved', live: null }, { edit: true, approve: false })).toEqual([
      'archive',
    ]);
    const live = articleRows[1]!.live;
    expect(actionsFor({ status: 'published', live }, can)).toEqual(['reconfirm', 'unpublish']);
  });

  it('builds the act request only when complete', () => {
    const input = blankActInput('2026-10-15');
    expect(contentActRequest('article', 'art_a1', 'submit', input, false)).toEqual({
      kind: 'article',
      id: 'art_a1',
      action: 'submit',
      reason: '',
    });
    expect(contentActRequest('article', 'art_a1', 'reject', input, false)).toBeNull();
    expect(
      contentActRequest('article', 'art_a1', 'reject', { ...input, reason: 'Thiếu nguồn' }, false),
    ).toMatchObject({ reason: 'Thiếu nguồn' });
    expect(contentActRequest('article', 'art_a1', 'approve', input, false)).toBeNull();
    const checked = { ...input, checks: [...editorialChecks] };
    expect(contentActRequest('article', 'art_a1', 'approve', checked, false)).toEqual({
      kind: 'article',
      id: 'art_a1',
      action: 'approve',
      reason: '',
      checks: [...editorialChecks],
    });
    // Prod: the qualified review is required.
    expect(contentActRequest('article', 'art_a1', 'approve', checked, true)).toBeNull();
    const reviewed = {
      ...checked,
      review: { reviewer: 'BS. Hà', credential: 'Nhi khoa', reviewedOn: '2026-10-10' },
    };
    expect(contentActRequest('article', 'art_a1', 'approve', reviewed, true)).toMatchObject({
      review: { reviewer: 'BS. Hà' },
    });
  });

  it('names schema issue places readably', () => {
    const intl = createIntl({ locale: 'vi', messages: messages.vi });
    expect(issuePlace(intl, ['body', 'en', 2, 'text'])).toBe('Nội dung · EN · mục 3 · Nội dung');
  });
});
