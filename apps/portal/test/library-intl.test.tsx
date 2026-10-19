import type {
  ArticleDraft,
  NutrientDraft,
  RecipeDraft,
  ReferenceMilestoneDraft,
} from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider, createIntl } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, ApiError, type Api } from '../src/api';
import { StaffContext } from '../src/context';
import { messages } from '../src/messages';
import {
  ArticleEditor,
  ArticlePreview,
  blankArticle,
  filterArticles,
} from '../src/screens/Articles';
import { MilestoneEditor, blankMilestone } from '../src/screens/Milestones';
import { NutrientEditor, blankNutrient, blankNutritionRule } from '../src/screens/NutritionEditors';
import { NutrientPreview, NutritionRulePreview } from '../src/screens/NutritionPreviews';
import { GuidesBody, blankSolidsGuide } from '../src/screens/Solids';
import { RecipeEditor, blankRecipe } from '../src/screens/SolidsEditors';
import { RecipePreview } from '../src/screens/SolidsPreviews';
import {
  calloutToneOptions,
  fillEmergency,
  subtopicOf,
  subtopicOptions,
  withEmergency,
  type ContentItemView,
  type ContentListView,
  type ContentRow,
} from '../src/screens/content-common';
import { levelsForRoles, type StaffRole } from './fixtures';

// Library readability and families abroad on the portal (D-087, P-166 #1, #2, #5): the solids
// group of a guide (editor, list column and filter), the urgent callout, `{emergency}` shown as
// 115 in the previews, and the warning when a text writes 115 itself. Server-rendered with a
// fake api, like content.test.tsx.

const api: Api = { call: () => Promise.reject(new ApiError('internal', null)) };

function render(node: ReactNode, roles: StaffRole[] = ['admin'], locale: 'vi' | 'en' = 'vi') {
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

const row = (over: Partial<ContentRow>): ContentRow => ({
  id: 'art_solids_allergy',
  kind: 'article',
  status: 'draft',
  displayStatus: 'draft',
  live: null,
  title: t('Giới thiệu thực phẩm dễ dị ứng', 'Introducing allergens'),
  reviewerLabel: null,
  lastEditorName: 'Hà Vũ',
  updatedAt: '2026-10-19T03:00:00.000Z',
  submittedByName: null,
  approverName: null,
  rejection: null,
  links: { articles: [], milestones: [] },
  library: 'solids',
  topic: 'feeding',
  format: 'article',
  ageWeeks: { from: 26, to: 52 },
  readingMinutes: 5,
  ...over,
});

const itemOf = <T,>(data: T, over: Partial<ContentRow> = {}) =>
  ({
    row: row(over),
    data,
    notes: '',
    lastEditorUid: 'u_other',
    pendingReview: null,
    published: null,
  }) as ContentItemView<T>;

/** A workflow button in the editor bar. */
const hasButton = (raw: string, label: string) => raw.includes(`>${label}</button>`);

describe('{emergency} in the previews', () => {
  it('reads as 115 in every text of a draft, other values untouched', () => {
    expect(withEmergency('Gọi {emergency} ngay, rồi gọi lại {emergency}.')).toBe(
      'Gọi 115 ngay, rồi gọi lại 115.',
    );
    const filled = fillEmergency({
      title: t('Khi nào gọi cấp cứu', 'When to call'),
      body: { vi: [{ type: 'paragraph', text: 'Gọi {emergency}.' }], en: [] },
      readingMinutes: 4,
      cover: null,
    });
    expect(filled.body.vi[0]!.text).toBe('Gọi 115.');
    expect(filled.readingMinutes).toBe(4);
    expect(filled.cover).toBeNull();
  });
});

const urgentGuide = (): ArticleDraft => ({
  ...blankSolidsGuide(),
  subtopic: 'safety',
  title: t('Hóc khi ăn: khi nào gọi cấp cứu', 'Choking: when to call for help'),
  summary: t('Phân biệt ho và hóc.', 'Gagging or choking.'),
  body: {
    vi: [
      { type: 'paragraph', text: 'Ho là phản xạ tự nhiên.' },
      {
        type: 'callout',
        tone: 'urgent',
        title: 'Gọi {emergency} ngay khi',
        text: 'Bé không khóc, không ho được hoặc tím tái.',
      },
    ],
    en: [
      {
        type: 'callout',
        tone: 'urgent',
        title: 'Call {emergency} now if',
        text: 'Your baby cannot cry or cough.',
      },
    ],
  },
  sources: [{ label: 'NHS', url: 'https://www.nhs.uk/' }],
});

describe('article editor (D-087)', () => {
  const editor = (
    data: ArticleDraft,
    over: { initialTab?: 'content' | 'settings'; locale?: 'vi' | 'en' } = {},
  ) =>
    render(
      <ArticleEditor
        item={itemOf(data)}
        articles={[]}
        requireReview={false}
        today="2026-10-19"
        staffUid="s1"
        canEdit
        canApprove
        onBack={() => undefined}
        onSaved={() => undefined}
        onChanged={() => undefined}
        initialTab={over.initialTab}
      />,
      ['admin'],
      over.locale,
    );

  it('a solids guide picks its group in Cài đặt; a care article has none', () => {
    const html = text(editor(urgentGuide(), { initialTab: 'settings' }));
    expect(html).toContain(
      'Thư viện Nhóm ăn dặm Mỗi nhóm có hình và màu riêng trong Thư viện ăn dặm. Chủ đề Dạng nội dung',
    );
    const care = text(
      editor({ ...blankArticle(), title: t('Ngủ', 'Sleep') }, { initialTab: 'settings' }),
    );
    expect(care).toContain('Thư viện Chủ đề Dạng nội dung');
    expect(care).not.toContain('Nhóm ăn dặm');
    // The select's labels (Radix renders the value on the client only).
    const intl = createIntl({ locale: 'vi', messages: messages.vi });
    expect(subtopicOptions(intl).map((o) => o.label)).toEqual([
      'Bắt đầu',
      'Cách cho ăn',
      'Kết cấu',
      'Dinh dưỡng',
      'Dị ứng',
      'An toàn',
      'Thực đơn',
      'Kỹ năng ăn',
      'Sức khoẻ',
      'Đồ dùng',
      'Ăn cùng gia đình',
    ]);
    expect(calloutToneOptions(intl).find((o) => o.value === 'urgent')?.label).toBe('Gọi cấp cứu');
  });

  it('the urgent callout: the token help, red in the preview with "Gọi 115"', () => {
    const raw = editor(urgentGuide());
    const html = text(raw);
    expect(html).toContain('Hộp màu đỏ, có nút gọi số cấp cứu của gia đình.');
    expect(html).toContain(
      'Dùng {emergency} thay cho số 115: app tự điền số cấp cứu theo nước của gia đình (115 ở Việt Nam, 911 ở Mỹ…)',
    );
    expect(raw).toContain('cl-callout cl-callout--urgent');
    expect(html).toContain('Gọi 115 ngay khi Bé không khóc, không ho được hoặc tím tái. Gọi 115');
    // The form keeps the token; only the preview fills it in.
    expect(raw).toContain('value="Gọi {emergency} ngay khi"');
    // Written with the token: no warning.
    expect(html).not.toContain('ghi thẳng số 115');
  });

  it('the English preview says "Call 115"', () => {
    const html = text(
      render(<ArticlePreview data={urgentGuide()} lang="en" review={null} />, ['admin'], 'en'),
    );
    expect(html).toContain('Call 115 now if Your baby cannot cry or cough. Call 115');
  });

  it('"115" written into a text warns and names the field, without blocking review', () => {
    const data = urgentGuide();
    data.body.vi.push({ type: 'paragraph', text: 'Nếu bé ngừng thở, gọi 115 ngay.' });
    data.summary.en = 'Call 115 if your baby stops breathing.';
    const raw = editor(data);
    const html = text(raw);
    expect(html).toContain('Có 2 chỗ ghi thẳng số 115');
    expect(html).toContain('Tóm tắt · EN');
    expect(html).toContain('Nội dung · VI · mục 3 · Nội dung');
    expect(html).toContain('Dùng {emergency} thay cho số 115');
    expect(hasButton(raw, 'Gửi duyệt')).toBe(true);
    // A source may say 115 (sources are left out of the check).
    const sourced = urgentGuide();
    sourced.sources = [{ label: 'Cấp cứu 115 Hà Nội', url: 'https://example.vn/' }];
    expect(text(editor(sourced))).not.toContain('ghi thẳng số 115');
    // English portal.
    const en = text(editor(data, { locale: 'en' }));
    expect(en).toContain('2 places write the number 115 itself');
    expect(en).toContain('Write {emergency} instead of 115');
  });
});

describe('Ăn dặm › Hướng dẫn by solids group', () => {
  const view = (rows: ContentRow[]): ContentListView => ({
    view: 'article',
    today: '2026-10-19',
    rows,
    counts: {
      inApp: 0,
      pending: 0,
      inReview: 0,
      approved: 0,
      drafts: rows.length,
      dueForReview: 0,
      archived: 0,
      total: rows.length,
    },
    available: ['article'],
    requireReview: false,
  });
  const rows = [
    row({ subtopic: 'allergy' }),
    row({ id: 'art_solids_first', title: t('Bữa ăn dặm đầu tiên', 'First meal') }),
    row({ id: 'art_solids_cup', title: t('Tập uống cốc', 'Cup drinking'), subtopic: 'skills' }),
    row({ id: 'art_sleep', title: t('Giấc ngủ ngắn', 'Naps'), library: 'care', topic: 'sleep' }),
  ];

  it('shows the group column and filter instead of the topic', () => {
    const html = text(render(<GuidesBody view={view(rows)} onOpen={() => undefined} />));
    expect(html).toContain('Nhóm: Tất cả');
    expect(html).not.toContain('Chủ đề: Tất cả');
    expect(html).toContain('Tiêu đề Nhóm Độ tuổi');
    expect(html).toContain('Giới thiệu thực phẩm dễ dị ứng Ăn dặm · Bài viết Dị ứng');
    expect(html).toContain('Bữa ăn dặm đầu tiên Ăn dặm · Bài viết Chưa chọn');
    expect(html).toContain('Kỹ năng ăn');
    expect(html).not.toContain('Giấc ngủ ngắn');
  });

  it('filters by group or "not chosen yet"', () => {
    const base = {
      q: '',
      library: 'all',
      topic: 'all',
      age: 'all',
      status: 'all',
      reviewer: 'all',
      lang: 'all',
    };
    const ids = (subtopic: string) => filterArticles(rows, { ...base, subtopic }).map((r) => r.id);
    expect(ids('allergy')).toEqual(['art_solids_allergy']);
    expect(ids('none')).toEqual(['art_solids_first', 'art_sleep']);
    expect(ids('all')).toHaveLength(4);
    expect(subtopicOf('gear')).toBe('gear');
    expect(subtopicOf('dessert')).toBeNull();
  });

  it('a new guide has no group yet', () => {
    expect(blankSolidsGuide().subtopic).toBeNull();
  });
});

const recipe = (): RecipeDraft => ({
  ...blankRecipe(),
  title: t('Cháo bí đỏ', 'Pumpkin congee'),
  summary: t('Món đầu tiên.', 'A first dish.'),
  ingredients: [{ foodId: null, name: t('Bí đỏ', 'Pumpkin'), qty: 50, unit: 'g', note: t('', '') }],
  steps: { vi: ['Hấp bí, nghiền mịn.'], en: ['Steam and mash the pumpkin.'] },
  tip: t('Nếu bé hóc, gọi {emergency}.', 'If your baby chokes, call {emergency}.'),
  sources: [{ label: 'NHS', url: 'https://www.nhs.uk/' }],
});

describe('recipe editor and preview', () => {
  const editor = (data: RecipeDraft) =>
    render(
      <RecipeEditor
        item={itemOf(data, { id: 'rcp_pumpkin', kind: 'recipe' })}
        foods={[]}
        articles={[]}
        requireReview={false}
        today="2026-10-19"
        staffUid="s1"
        canEdit
        canApprove
        onBack={() => undefined}
        onSaved={() => undefined}
        onChanged={() => undefined}
      />,
    );

  it('previews the token as 115 and hints at it near the steps', () => {
    const html = text(editor(recipe()));
    expect(html).toContain('Mẹo Nếu bé hóc, gọi 115.');
    expect(html).toContain('Dùng {emergency} thay cho số 115');
    expect(html).not.toContain('ghi thẳng số 115');
    const en = text(
      render(<RecipePreview data={recipe()} lang="en" review={null} foods={new Map()} />),
    );
    expect(en).toContain('If your baby chokes, call 115.');
  });

  it('a step that writes 115 warns with the step named', () => {
    const data = recipe();
    data.steps.vi = ['Nếu bé hóc, gọi 115 ngay lập tức.'];
    const raw = editor(data);
    const html = text(raw);
    expect(html).toContain('Có 1 chỗ ghi thẳng số 115');
    expect(html).toContain('Cách làm · VI · mục 1');
    expect(hasButton(raw, 'Gửi duyệt')).toBe(true);
  });
});

describe('milestone editor', () => {
  const milestone = (doctor: string): ReferenceMilestoneDraft => ({
    ...blankMilestone(),
    title: t('Lật người', 'Rolls over'),
    howToRecognise: t('Bé lật từ ngửa sang sấp.', 'Rolls from back to tummy.'),
    talkToDoctor: t(doctor, 'Call {emergency} if your baby stops breathing.'),
    sources: [{ label: 'CDC', url: 'https://www.cdc.gov/' }],
  });
  const editor = (data: ReferenceMilestoneDraft) =>
    text(
      render(
        <MilestoneEditor
          item={itemOf(data, { id: 'rolls_over', kind: 'milestone' })}
          requireReview={false}
          today="2026-10-19"
          staffUid="s1"
          canEdit
          canApprove
          onBack={() => undefined}
          onSaved={() => undefined}
          onChanged={() => undefined}
        />,
      ),
    );

  it('previews the token as 115; a literal 115 warns', () => {
    const ok = editor(milestone('Gọi {emergency} nếu bé ngừng thở.'));
    expect(ok).toContain('Khi nào nên hỏi bác sĩ Gọi 115 nếu bé ngừng thở.');
    expect(ok).toContain('Dùng {emergency} thay cho số 115');
    expect(ok).not.toContain('ghi thẳng số 115');
    const bad = editor(milestone('Gọi 115 nếu bé ngừng thở.'));
    expect(bad).toContain('Gọi 115 nếu bé ngừng thở.');
    expect(bad).toContain('Có 1 chỗ ghi thẳng số 115');
    expect(bad).toContain('Khi nào nên hỏi bác sĩ · VI');
  });
});

describe('nutrition editors and previews', () => {
  const nutrient = (warning: string): NutrientDraft => ({
    ...blankNutrient(),
    name: t('Sắt', 'Iron'),
    warning: t(warning, 'Call {emergency} if your baby swallowed iron tablets.'),
  });

  it('the micronutrient warning names the field; the preview shows 115', () => {
    const html = text(
      render(
        <NutrientEditor
          item={itemOf(nutrient('Nuốt nhầm viên sắt: gọi 115 ngay.'), {
            kind: 'nutrient',
            id: 'nut_iron',
          })}
          requireReview={false}
          today="2026-10-19"
          staffUid="s1"
          canEdit
          canApprove
          onBack={() => undefined}
          onSaved={() => undefined}
          onChanged={() => undefined}
        />,
      ),
    );
    expect(html).toContain('Có 1 chỗ ghi thẳng số 115');
    expect(html).toContain('Lưu ý y khoa · VI');
    expect(html).toContain('Dùng {emergency} thay cho số 115');
    const preview = text(
      render(<NutrientPreview data={nutrient('Gọi {emergency}.')} lang="en" review={null} />),
    );
    expect(preview).toContain('Call 115 if your baby swallowed iron tablets.');
  });

  it('a rule banner shows the baby name and 115', () => {
    const rule = {
      ...blankNutritionRule(),
      banner: t(
        '{name} khó thở: gọi {emergency}.',
        '{name} struggles to breathe: call {emergency}.',
      ),
    };
    const html = text(render(<NutritionRulePreview data={rule} lang="vi" />));
    expect(html).toContain('Teddy khó thở: gọi 115.');
  });
});
