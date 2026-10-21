import {
  type NutrientDraft,
  type NutritionRuleDraft,
  type NutritionStageDraft,
} from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider, createIntl } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, ApiError, type Api } from '../src/api';
import { StaffContext, routeOf } from '../src/context';
import { messages } from '../src/messages';
import { Sidebar } from '../src/Shell';
import { ReviewBody, ReviewDetail, editorUrlOf } from '../src/screens/ContentReview';
import {
  NutrientsBody,
  NutritionCoverageStrip,
  NutritionRulesBody,
  NutritionStagesBody,
  coverageMonths,
} from '../src/screens/Nutrition';
import {
  NutrientEditor,
  NutritionRuleEditor,
  NutritionStageEditor,
  blankNutrient,
  blankNutritionRule,
  blankNutritionStage,
  conditionOptions,
  missesNotDiagnosis,
  withCondition,
  withMetric,
} from '../src/screens/NutritionEditors';
import {
  milkCell,
  nextRound,
  nutritionCoverageOf,
  nutritionEditorUrl,
  nutritionPathOf,
  nutritionPlace,
  nutritionUrl,
} from '../src/screens/nutrition-common';
import type {
  ContentItemView,
  ContentListView,
  ContentQueueView,
  ContentRow,
} from '../src/screens/content-common';
import { errorMessageId } from '../src/ui';
import { levelsForRoles, type StaffRole } from './fixtures';

// Dinh dưỡng theo giai đoạn on the portal (D-083, P-163; Figma D01–D04): the tabs' lists with the
// 0–36 month coverage, the three editors with their phone previews and the copy check, and the
// review queue. Server-rendered with a fake api, like content.test.tsx.

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
const counts = {
  inApp: 4,
  pending: 1,
  inReview: 1,
  approved: 0,
  drafts: 2,
  dueForReview: 0,
  archived: 0,
  total: 7,
};
const live = {
  revision: 2,
  publishedAt: '2026-08-15T00:00:00.000Z',
  reviewDueOn: '2027-08-15',
  illustrative: false,
  reviewer: 'BS. Mai Hồ',
  dueForReview: false,
};

const row = (over: Partial<ContentRow>): ContentRow => ({
  id: 'nst_6_8',
  kind: 'nutritionStage',
  status: 'draft',
  displayStatus: 'draft',
  live: null,
  title: t('Bắt đầu ăn dặm', 'Starting solids'),
  reviewerLabel: null,
  lastEditorName: 'Hà Vũ',
  updatedAt: '2026-10-15T03:00:00.000Z',
  submittedByName: null,
  approverName: null,
  rejection: null,
  links: { articles: [], milestones: [] },
  ...over,
});

// The row shapes of `content-nutrition.ts` (the server adds the kind's fields).
const stageRows: ContentRow[] = [
  row({
    status: 'published',
    displayStatus: 'published',
    live,
    ageMonths: { from: 6, to: 9 },
    ageLabel: { from: 6, to: 8 },
    milk: {
      perFeedMl: { min: 180, max: 240 },
      feedsPerDay: { min: 4, max: 5 },
      perDayMl: { min: 600, max: 900 },
    },
    solidsMeals: t('2–3 bữa', '2–3 meals'),
    nutrientIds: ['nut_iron', 'nut_zinc'],
    sampleDay: 5,
    tips: 2,
    sources: 3,
  }),
  row({
    id: 'nst_0_1',
    title: t('Những ngày đầu', 'The first days'),
    reviewerLabel: 'BS. Mai Hồ',
    ageMonths: { from: 0, to: 1 },
    ageLabel: { from: 0, to: 1 },
    milk: { perFeedMl: { min: 30, max: 90 }, feedsPerDay: { min: 8, max: 12 }, perDayMl: null },
    solidsMeals: null,
    nutrientIds: ['nut_d'],
  }),
  row({
    id: 'nst_12_24',
    title: t('Ăn cùng gia đình', 'Eating with the family'),
    status: 'in_review',
    displayStatus: 'in_review',
    ageMonths: { from: 12, to: 24 },
    milk: { perFeedMl: null, feedsPerDay: null, perDayMl: { min: 400, max: 500 } },
    solidsMeals: t('3 bữa + 2 phụ', '3 meals + 2 snacks'),
    nutrientIds: [],
  }),
];

const nutrientRows: ContentRow[] = [
  row({
    id: 'nut_iron',
    kind: 'nutrient',
    title: t('Sắt', 'Iron'),
    status: 'published',
    displayStatus: 'published',
    live,
    key: 'iron',
    focus: { ageMonths: { from: 6, to: 24 }, label: t('Từ 6 tháng', 'From 6 months') },
    foods: 7,
    byAge: 4,
    hasCampaign: false,
    rounds: [],
    sources: 2,
  }),
  row({
    id: 'nut_zinc',
    kind: 'nutrient',
    title: t('Kẽm', 'Zinc'),
    key: 'zinc',
    focus: { ageMonths: { from: 6, to: 24 }, label: t('', '') },
    // A list the row may carry later: shown as chips.
    foods: [t('Thịt', 'Meat'), t('Cá', 'Fish'), t('Trứng', 'Egg'), t('Đậu', 'Beans')],
    hasCampaign: false,
    rounds: [],
  }),
  row({
    id: 'nut_vita',
    kind: 'nutrient',
    title: t('Vitamin A', 'Vitamin A'),
    key: 'vitaminA',
    focus: { ageMonths: { from: 6, to: 37 }, label: t('6–36 tháng', '6–36 months') },
    foods: 3,
    hasCampaign: true,
    rounds: [
      { month: 6, fromDay: 1, toDay: 2 },
      { month: 12, fromDay: 1, toDay: 2 },
    ],
  }),
];

const ruleRows: ContentRow[] = [
  row({
    id: 'nru_weight_low',
    kind: 'nutritionRule',
    title: t('2 lần đo gần nhất của {name} thấp hơn khoảng chuẩn.', 'Two latest are low.'),
    status: 'published',
    displayStatus: 'published',
    live,
    metric: 'weight',
    condition: 'belowRange',
    days: null,
    ageMonths: { from: 0, to: 37 },
    ageLabel: { from: 0, to: 36 },
    remindAfterDays: 14,
    export: true,
    tips: 4,
  }),
  row({
    id: 'nru_no_measure',
    kind: 'nutritionRule',
    title: t('Đã lâu chưa cập nhật cân nặng của {name}.', 'No measurement lately.'),
    metric: 'measurement',
    condition: 'noMeasurement',
    days: 30,
    ageMonths: { from: 0, to: 25 },
    remindAfterDays: null,
    export: false,
    tips: 1,
  }),
];

const view = (kind: ContentListView['view'], rows: ContentRow[], extra = {}): ContentListView => ({
  view: kind,
  today: '2026-10-18',
  rows,
  counts,
  available: ['nutritionStage', 'nutrient', 'nutritionRule'],
  requireReview: false,
  ...extra,
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

const vi = createIntl({ locale: 'vi', messages: messages.vi });

describe('navigation and addresses', () => {
  const sidebar = (roles: StaffRole[], locale: 'vi' | 'en' = 'vi') =>
    text(
      render(
        <Sidebar
          route="nutrition"
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

  it('adds NỘI DUNG › Dinh dưỡng for Nội dung · Xem, before Duyệt nội dung', () => {
    for (const role of ['admin', 'ops', 'expert'] as const) {
      // Ăn dặm (D-085) follows Dinh dưỡng.
      expect(sidebar([role])).toContain('Mốc phát triển Dinh dưỡng Ăn dặm Duyệt nội dung');
    }
    expect(sidebar(['eng'])).not.toContain('Dinh dưỡng');
    expect(sidebar(['admin'], 'en')).toContain('Nutrition');
  });

  it('routes the tabs and editors under /nutrition', () => {
    expect(routeOf('/nutrition')).toBe('nutrition');
    expect(routeOf('/nutrition/rules/nru_weight_low')).toBe('nutrition');
    expect(nutritionPathOf([])).toEqual({ tab: 'stages' });
    expect(nutritionPathOf(['nutrients'])).toEqual({ tab: 'nutrients' });
    expect(nutritionPathOf(['rules', 'nru_a'])).toEqual({ tab: 'rules', id: 'nru_a' });
    expect(nutritionPathOf(['stages', 'new', '9-12'])).toEqual({
      tab: 'stages',
      id: null,
      range: { from: 9, to: 12 },
    });
    expect(nutritionPathOf(['stages', 'new', '12-9'])).toMatchObject({ id: null, range: null });
    expect(nutritionUrl({ tab: 'stages' })).toBe('/nutrition');
    expect(nutritionUrl({ tab: 'rules' })).toBe('/nutrition/rules');
    expect(nutritionUrl({ tab: 'stages', id: null, range: { from: 9, to: 12 } })).toBe(
      '/nutrition/stages/new/9-12',
    );
    expect(nutritionEditorUrl('nutrient', 'nut_iron')).toBe('/nutrition/nutrients/nut_iron');
    expect(editorUrlOf('nutritionRule', 'nru_a')).toBe('/nutrition/rules/nru_a');
    expect(editorUrlOf('article', 'art_a')).toBe('/articles/art_a');
  });

  it('has messages for the server refusals', () => {
    for (const r of ['unsafe-copy', 'stage-overlap', 'link-missing']) {
      expect(errorMessageId(new ApiError('failed-precondition', r))).toBe(`error.${r}`);
    }
    expect(vi.formatMessage({ id: 'error.unsafe-copy' })).toContain('liều thuốc');
  });
});

describe('D01 Giai đoạn', () => {
  it('lists by age with milk, solids, micronutrients, reviewer and the safety note', () => {
    const html = text(
      render(
        <NutritionStagesBody
          view={view('nutritionStage', stageRows)}
          nutrients={nutrientRows}
          canEdit
          onOpen={() => undefined}
          onCreate={() => undefined}
        />,
      ),
    );
    expect(html).toContain('Đang trên app 4');
    expect(html).toContain(
      '6–8 tháng Bắt đầu ăn dặm 180–240 ml/cữ 600–900 ml/ngày 2–3 bữa Sắt Kẽm BS. Mai Hồ 08/2026',
    );
    expect(html).toContain('0–1 tháng Những ngày đầu 30–90 ml/cữ 8–12 cữ —');
    expect(html).toContain('Dự kiến: BS. Mai Hồ');
    expect(html).toContain('400–500 ml/ngày');
    expect(html.indexOf('0–1 tháng Những')).toBeLessThan(html.indexOf('6–8 tháng Bắt'));
    expect(html.indexOf('6–8 tháng Bắt')).toBeLessThan(html.indexOf('12–23 tháng Ăn'));
    expect(html).toContain('Lượng sữa là khoảng tham khảo cho bé bú bình');
  });

  it('shows the 0–36 month coverage with the gaps (from the rows)', () => {
    const c = nutritionCoverageOf(view('nutritionStage', stageRows));
    expect(c.gaps).toEqual([
      { from: 1, to: 6 },
      { from: 9, to: 12 },
      { from: 24, to: 37 },
    ]);
    expect(c.liveGaps[0]).toEqual({ from: 0, to: 6 });
    expect(c.covered).toBe(1 + 3 + 12);
    const html = text(
      render(
        <NutritionStagesBody
          view={view('nutritionStage', stageRows)}
          nutrients={nutrientRows}
          canEdit
          onOpen={() => undefined}
          onCreate={() => undefined}
        />,
      ),
    );
    expect(html).toContain('Độ phủ 0–36 tháng');
    expect(html).toContain('16 / 37 tháng có giai đoạn');
    expect(html).toContain('Chưa có · 1–5 tháng, 9–11 tháng, 24–36 tháng');
    expect(html).toContain('ô Dinh dưỡng hiện “Sớm ra mắt”');
  });

  it('uses the server coverage items and names overlaps', () => {
    const coverage = {
      total: 37,
      covered: 37,
      published: 9,
      months: [],
      gaps: [],
      liveGaps: [],
      items: [
        { id: 'nst_0_1', ageMonths: { from: 0, to: 9 }, state: 'published', ageLabel: {} },
        { id: 'nst_6_8', ageMonths: { from: 6, to: 37 }, state: 'draft', ageLabel: {} },
      ],
      overlaps: [],
    };
    const c = nutritionCoverageOf(view('nutritionStage', stageRows, { coverage }));
    expect(c.gaps).toEqual([]);
    expect(c.overlaps).toEqual([{ ids: ['nst_0_1', 'nst_6_8'], ageMonths: { from: 6, to: 9 } }]);
    const html = text(
      render(
        <NutritionStagesBody
          view={view('nutritionStage', stageRows, { coverage })}
          nutrients={nutrientRows}
          canEdit
          onOpen={() => undefined}
          onCreate={() => undefined}
        />,
      ),
    );
    expect(html).toContain('37 / 37 tháng có giai đoạn');
    expect(html).toContain('Không còn khoảng trống');
    expect(html).toContain(
      'Trùng tháng: 0–8 tháng · Những ngày đầu và 6–36 tháng · Bắt đầu ăn dặm',
    );
  });

  it('draws the coverage as a month ruler 0…36: a state per month, gaps, a legend (UX 2026-10-21)', () => {
    const c = nutritionCoverageOf(view('nutritionStage', stageRows));
    const months = coverageMonths(c);
    expect(months).toHaveLength(37);
    expect(months[0]!.item?.state).toBe('draft');
    expect(months[7]!.item?.id).toBe('nst_6_8');
    expect(months[13]!.item?.state).toBe('pending');
    expect(months[10]!.item).toBeNull();
    expect(months[10]!.gap).toEqual({ from: 9, to: 12 });
    const raw = render(
      <NutritionCoverageStrip
        coverage={c}
        rows={stageRows}
        canEdit
        onOpen={() => undefined}
        onCreate={() => undefined}
      />,
    );
    // One cell per month with its tooltip text, the stages lane and the ruler.
    expect(raw).toContain('aria-label="Tháng 7 · Bắt đầu ăn dặm · Đã xuất bản"');
    expect(raw).toContain('aria-label="Tháng 10 · chưa có giai đoạn"');
    expect(raw).toContain('aria-label="Thêm giai đoạn 9–11 tháng"');
    const html = text(raw);
    expect(html).toContain('Theo tháng');
    expect(html).toContain('Giai đoạn 0–1 · Những ngày đầu');
    expect(html).toContain('0 3 6 9 12 15 18 21 24 27 30 33 36');
    expect(html).toContain('Đã xuất bản · 3 tháng Chờ duyệt · 12 tháng Nháp · 1 tháng');
    expect(html).toContain('Chưa có · 1–5 tháng, 9–11 tháng, 24–36 tháng');
  });

  it('reads milk cells defensively', () => {
    expect(milkCell(vi, null)).toEqual({ main: null, sub: null });
    expect(
      milkCell(vi, { perFeedMl: null, feedsPerDay: { min: 3, max: 4 }, perDayMl: null }),
    ).toEqual({ main: '3–4 cữ', sub: null });
    expect(
      milkCell(vi, { perFeedMl: null, feedsPerDay: null, perDayMl: { min: 500, max: 500 } }).main,
    ).toBe('500 ml/ngày');
  });
});

describe('D03 Vi chất and D04 Quy tắc gợi ý', () => {
  it('lists micronutrients with focus, foods and campaign rounds', () => {
    const html = text(
      render(<NutrientsBody view={view('nutrient', nutrientRows)} onOpen={() => undefined} />),
    );
    expect(html).toContain('Sắt Từ 6 tháng 6–23 tháng 7 thực phẩm');
    expect(html).toContain('Kẽm 6–23 tháng Thịt Cá Trứng +1');
    expect(html).toContain('Vitamin A 6–36 tháng 6–36 tháng 3 thực phẩm 1–2/6, 1–2/12');
    // A medical note the row may carry later shows in "Ghi chú y khoa".
    const withNote = [{ ...nutrientRows[0]!, warning: t('Dạng uống theo chỉ định bác sĩ', 'x') }];
    expect(
      text(render(<NutrientsBody view={view('nutrient', withNote)} onOpen={() => undefined} />)),
    ).toContain('7 thực phẩm Dạng uống theo chỉ định bác sĩ');
    expect(html).toContain('không ghi liều');
    expect(
      nextRound(
        [
          { month: 6, fromDay: 1, toDay: 2 },
          { month: 12, fromDay: 1, toDay: 2 },
        ],
        '2026-10-18',
      ),
    ).toEqual({ month: 12, fromDay: 1, toDay: 2 });
    expect(nextRound([{ month: 6, fromDay: 1, toDay: 2 }], '2026-10-18')).toEqual({
      month: 6,
      fromDay: 1,
      toDay: 2,
    });
  });

  it('lists rules with the condition in words and what the app shows', () => {
    const html = text(
      render(
        <NutritionRulesBody view={view('nutritionRule', ruleRows)} onOpen={() => undefined} />,
      ),
    );
    expect(html).toContain(
      'Cân nặng Dưới khoảng chuẩn WHO 2 lần đo gần nhất, dưới P3 0–36 tháng 2 lần đo gần nhất của {name} thấp hơn khoảng chuẩn. 4 gợi ý · nhắc đo lại 14 ngày · xuất báo cáo',
    );
    expect(html).toContain(
      'Đo đạc Chưa có lần đo trong 30 ngày cân nặng hoặc chiều dài 0–24 tháng',
    );
    expect(html).toContain('Không dùng từ “suy dinh dưỡng”');
    const en = text(
      render(
        <NutritionRulesBody view={view('nutritionRule', ruleRows)} onOpen={() => undefined} />,
        ['admin'],
        'en',
      ),
    );
    expect(en).toContain('Weight Below the WHO range');
    expect(en).toContain('4 tips · remeasure reminder in 14 days · doctor report');
  });
});

const fullStage = (): NutritionStageDraft => ({
  ...blankNutritionStage({ from: 6, to: 9 }),
  title: t('Bắt đầu ăn dặm', 'Starting solids'),
  summary: t(
    'Sữa vẫn là nguồn dinh dưỡng chính. Thêm 2–3 bữa ăn dặm mỗi ngày.',
    'Milk is still the main food. Add 2–3 solid meals a day.',
  ),
  milk: {
    perFeedMl: { min: 180, max: 240 },
    feedsPerDay: { min: 4, max: 5 },
    perDayMl: { min: 600, max: 900 },
    breastfeedingNote: t('cho bú theo nhu cầu.', 'feed on demand.'),
  },
  solids: { meals: t('2–3 bữa', '2–3 meals'), texture: t('Bột loãng', 'Thin purée') },
  sampleDay: [
    { slot: 'morning', kind: 'milk', text: t('Sữa · 180–240 ml', 'Milk · 180–240 ml') },
    { slot: 'noon', kind: 'solids', text: t('Ăn dặm · cháo rây', 'Solids · porridge') },
  ],
  nutrientIds: ['nut_iron', 'nut_vita'],
  tips: [
    {
      title: t('Mỗi ngày một món giàu sắt', 'An iron-rich dish a day'),
      body: t('Thịt bò, gan gà, lòng đỏ trứng.', 'Beef, chicken liver, egg yolk.'),
    },
  ],
  sources: [{ label: 'WHO 2023', url: 'https://www.who.int/' }],
});

describe('D02 stage editor', () => {
  const editor = (
    item: ContentItemView<NutritionStageDraft> | null,
    stages: ContentRow[] = [],
    locale: 'vi' | 'en' = 'vi',
  ) =>
    render(
      <NutritionStageEditor
        item={item}
        stages={stages}
        nutrients={nutrientRows}
        requireReview={false}
        today="2026-10-18"
        staffUid="s1"
        canEdit
        canApprove
        onBack={() => undefined}
        onSaved={() => undefined}
        onChanged={() => undefined}
        initialLang={locale}
      />,
      ['admin'],
      locale,
    );

  it('edits the months (last month shown, stored exclusive) and previews 9b', () => {
    const raw = editor(itemOf(fullStage()));
    const html = text(raw);
    expect(html).toContain('Dinh dưỡng 6–8 tháng · Bắt đầu ăn dặm Nháp');
    // "Đến tháng tuổi (gồm cả)" shows 8 for `to: 9`.
    expect(raw).toMatch(/Đến tháng tuổi \(gồm cả\)[\s\S]*?value="8"/);
    expect(html).toContain('Cho bé từ 6 đến 8 tháng tuổi tròn · nhãn trong app “6–8 tháng”');
    expect(html).toContain('Tên giai đoạn 14/60');
    expect(html).toContain('Gửi duyệt');
    expect(html).toContain('Không nhập liều thuốc hay vi chất dạng uống');
    // 9b: stage card, milk band with the sample average, micronutrients, sample day, tips.
    expect(html).toContain('7 tháng · giai đoạn 6–8 tháng');
    expect(html).toContain(
      'Teddy trung bình 720 ml/ngày (7 ngày qua) · 4–5 cữ, 180–240 ml mỗi cữ. Bú mẹ: cho bú theo nhu cầu.',
    );
    expect(html).toContain('Cần chú ý ở giai đoạn này Sắt Vitamin A 1–2/12');
    expect(html).toContain('Sáng Sữa · 180–240 ml');
    expect(html).toContain('Gợi ý cho Teddy Mỗi ngày một món giàu sắt');
    expect(html).toContain(
      'Biên soạn theo hướng dẫn WHO, AAP, NHS · Tham khảo, không thay thế bác sĩ',
    );
  });

  it('a dose or a forbidden word names the field and hides "Gửi duyệt"', () => {
    const bad = fullStage();
    bad.summary.vi = 'Bổ sung sắt 50 mg mỗi ngày.';
    bad.tips[0]!.body.en = 'Avoid obesity later.';
    const html = text(editor(itemOf(bad)));
    expect(html).toContain('Chưa gửi duyệt được: 2 chỗ cần sửa');
    expect(html).toContain('Mô tả ngắn · VI: “50 mg” trông như một liều thuốc');
    expect(html).toContain('Gợi ý · mục 1 · Nội dung · EN: “obesity” là từ app không dùng');
    expect(html).not.toContain('Gửi duyệt');
    expect(nutritionPlace(vi, ['tips', 0, 'title', 'vi'])).toBe('Gợi ý · mục 1 · Tiêu đề · VI');
  });

  it('warns about an overlap with a live stage; a new stage has no workflow yet', () => {
    const other = row({ id: 'nst_old', live, status: 'published', ageMonths: { from: 8, to: 12 } });
    expect(text(editor(itemOf(fullStage()), [other]))).toContain(
      'Trùng tháng với 8–11 tháng · Bắt đầu ăn dặm',
    );
    const fresh = text(editor(null));
    expect(fresh).toContain('0–1 tháng');
    expect(fresh).toContain('Chưa lưu');
    expect(fresh).not.toContain('Gửi duyệt');
    expect(blankNutritionStage().milk).toEqual({
      perFeedMl: null,
      feedsPerDay: null,
      perDayMl: null,
      breastfeedingNote: { vi: '', en: '' },
    });
    const en = text(editor(itemOf(fullStage()), [], 'en'));
    expect(en).toContain('Milk (reference for bottle feeding)');
    expect(en).toContain('Teddy averages 720 ml/day (last 7 days)');
  });
});

const fullNutrient = (): NutrientDraft => ({
  ...blankNutrient(),
  key: 'vitaminA',
  name: t('Vitamin A', 'Vitamin A'),
  subtitle: t('Uống bổ sung tại trạm y tế', 'Given at the health station'),
  focus: {
    ageMonths: { from: 6, to: 37 },
    label: t('6–36 tháng', '6–36 months'),
    note: t('', ''),
  },
  why: t('Giúp mắt và sức đề kháng.', 'Helps the eyes and immunity.'),
  foods: [t('Gan', 'Liver'), t('Cà rốt', 'Carrot')],
  tip: t('Ăn kèm chút dầu.', 'Eat with a little oil.'),
  byAge: [
    {
      ageMonths: { from: 6, to: 12 },
      label: t('6–11 tháng', '6–11 months'),
      text: t('Uống đợt đầu.', 'First dose round.'),
    },
  ],
  warning: t('Chỉ uống theo chỉ định bác sĩ.', 'Only as prescribed by a doctor.'),
  campaign: {
    rounds: [
      { month: 6, fromDay: 1, toDay: 2 },
      { month: 12, fromDay: 1, toDay: 2 },
    ],
    ageMonths: { from: 6, to: 37 },
    place: t('trạm y tế phường, xã', 'the ward health station'),
  },
  sources: [{ label: 'Bộ Y tế', url: 'https://moh.gov.vn/' }],
});

describe('D03 micronutrient editor', () => {
  it('edits focus, foods, by-age rows and the campaign, and previews 9d', () => {
    const raw = render(
      <NutrientEditor
        item={itemOf(fullNutrient(), { kind: 'nutrient', id: 'nut_vita' })}
        requireReview={false}
        today="2026-10-18"
        staffUid="s1"
        canEdit
        canApprove
        onBack={() => undefined}
        onSaved={() => undefined}
        onChanged={() => undefined}
      />,
    );
    const html = text(raw);
    expect(html).toContain('Dinh dưỡng Vitamin A');
    expect(html).toContain('Thực phẩm giàu vi chất 2/12');
    expect(raw).toContain('value="Cà rốt"');
    expect(html).toContain('Đợt uống tại trạm y tế');
    expect(html).toContain('Gửi duyệt');
    // 9d
    expect(html).toContain('Vì sao cần Giúp mắt và sức đề kháng.');
    expect(html).toContain('Thực phẩm cho bé Gan Cà rốt');
    expect(html).toContain('Mẹo Ăn kèm chút dầu.');
    expect(html).toContain('Uống tại trạm y tế phường, xã: 1–2/6, 1–2/12 · bé 6–36 tháng');
    expect(html).toContain('Chỉ uống theo chỉ định bác sĩ.');
    expect(html).toContain('Nguồn: Bộ Y tế');
  });

  it('a new micronutrient has no campaign and no workflow', () => {
    const html = text(
      render(
        <NutrientEditor
          item={null}
          requireReview={false}
          today="2026-10-18"
          staffUid="s1"
          canEdit
          canApprove
          onBack={() => undefined}
          onSaved={() => undefined}
          onChanged={() => undefined}
        />,
      ),
    );
    expect(html).toContain('Vi chất mới');
    expect(html).toContain('Không có');
    expect(html).not.toContain('Gửi duyệt');
  });
});

const fullRule = (): NutritionRuleDraft => ({
  ...blankNutritionRule(),
  banner: t(
    '2 lần đo gần nhất của {name} thấp hơn khoảng chuẩn. Đây không phải chẩn đoán.',
    'The two latest weights of {name} are under the range. This is not a diagnosis.',
  ),
  tips: [
    {
      title: t('Duy trì sữa đều đặn', 'Keep milk regular'),
      body: t('Không giảm cữ sữa.', 'Do not cut feeds.'),
    },
  ],
});

describe('D04 rule editor', () => {
  const editor = (data: NutritionRuleDraft, locale: 'vi' | 'en' = 'vi') =>
    text(
      render(
        <NutritionRuleEditor
          item={itemOf(data, { kind: 'nutritionRule', id: 'nru_weight_low' })}
          requireReview={false}
          today="2026-10-18"
          staffUid="s1"
          canEdit
          canApprove
          onBack={() => undefined}
          onSaved={() => undefined}
          onChanged={() => undefined}
          initialLang={locale}
        />,
        ['admin'],
        locale,
      ),
    );

  it('previews 9e with the baby name and the actions', () => {
    const html = editor(fullRule());
    expect(html).toContain('Dinh dưỡng Cân nặng · Dưới khoảng chuẩn WHO');
    expect(html).toContain('App hiện thẻ khi: Dưới khoảng chuẩn WHO · bé 0–36 tháng.');
    expect(html).toContain('Viết {name} ở chỗ tên bé');
    expect(html).toContain('Cân nặng của Teddy');
    expect(html).toContain(
      '2 lần đo gần nhất của Teddy thấp hơn khoảng chuẩn. Đây không phải chẩn đoán.',
    );
    expect(html).toContain('Gợi ý trong lúc chờ khám Duy trì sữa đều đặn');
    expect(html).toContain('Nhắc đo lại sau 14 ngày');
    expect(html).toContain('Xuất báo cáo cho bác sĩ');
    expect(html).toContain('Gửi duyệt');
    expect(html).not.toContain('cần có “không phải chẩn đoán”');
    const missing = fullRule();
    missing.banner.vi = 'Cân nặng của {name} thấp hơn khoảng chuẩn.';
    expect(editor(missing)).toContain('cần có “không phải chẩn đoán”');
    expect(editor(fullRule(), 'en')).toContain('Teddy’s weight');
  });

  it('offers only the conditions of the metric', () => {
    expect(conditionOptions(vi, 'weight').map((o) => o.value)).toEqual([
      'belowRange',
      'aboveRange',
    ]);
    expect(conditionOptions(vi, 'milk').map((o) => o.value)).toEqual(['milkOutsideStage']);
    const rule = blankNutritionRule();
    expect(withMetric(rule, 'length')).toMatchObject({ metric: 'length', condition: 'belowRange' });
    expect(withMetric(rule, 'measurement')).toMatchObject({
      condition: 'noMeasurement',
      days: 30,
    });
    expect(withCondition({ ...rule, days: 45 }, 'aboveRange').days).toBeNull();
    expect(missesNotDiagnosis({ metric: 'milk', banner: t('Mỗi bé mỗi khác.', '') })).toBe(false);
  });
});

describe('Duyệt nội dung with the nutrition kinds', () => {
  const queue: ContentQueueView = {
    view: 'queue',
    today: '2026-10-18',
    rows: [
      { ...stageRows[2]!, submittedByName: 'Hà Vũ' },
      row({
        id: 'nut_zinc',
        kind: 'nutrient',
        title: t('Kẽm', 'Zinc'),
        status: 'in_review',
        displayStatus: 'in_review',
        focus: { ageMonths: { from: 6, to: 24 }, label: t('', '') },
      }),
      { ...ruleRows[1]!, status: 'in_review', displayStatus: 'in_review' },
    ],
    counts: { nutritionStage: counts },
    totals: counts,
    available: ['article', 'stage', 'milestone', 'nutritionStage', 'nutrient', 'nutritionRule'],
    requireReview: false,
  };

  it('lists the three kinds with their months', () => {
    const html = text(render(<ReviewBody view={queue} onChanged={() => undefined} />));
    expect(html).toContain('Chờ duyệt 3');
    expect(html).toContain('Giai đoạn dinh dưỡng 12–23 tháng Ăn cùng gia đình');
    expect(html).toContain('Vi chất 6–23 tháng Kẽm');
    expect(html).toContain('Quy tắc gợi ý 0–24 tháng');
  });

  it('previews each kind; rules have no sources; unsafe copy is flagged', () => {
    const detail = (item: ContentItemView) =>
      text(
        render(
          <ReviewDetail
            item={item}
            requireReview={false}
            today="2026-10-18"
            staffUid="s1"
            can={{ edit: true, approve: true }}
            onChanged={() => undefined}
          />,
        ),
      );
    const stage = detail(
      itemOf(fullStage(), {
        status: 'in_review',
        displayStatus: 'in_review',
      }) as unknown as ContentItemView,
    );
    expect(stage).toContain('WHO 2023');
    expect(stage).toContain('Gợi ý cho Teddy');
    expect(stage).toContain('Mở trang soạn');
    const rule = detail(
      itemOf(fullRule(), {
        id: 'nru_weight_low',
        kind: 'nutritionRule',
        status: 'in_review',
        displayStatus: 'in_review',
      }) as unknown as ContentItemView,
    );
    expect(rule).toContain('Cân nặng của Teddy');
    expect(rule).not.toContain('Chưa có nguồn tham khảo');
    const bad = fullNutrient();
    bad.warning.vi = 'Uống 200.000 IU.';
    const nutrient = detail(
      itemOf(bad, {
        id: 'nut_vita',
        kind: 'nutrient',
        status: 'in_review',
        displayStatus: 'in_review',
      }) as unknown as ContentItemView,
    );
    expect(nutrient).toContain('Lưu ý y khoa · VI: “200.000 IU” trông như một liều thuốc');
    expect(nutrient).toContain('Uống tại trạm y tế phường, xã');
  });
});
