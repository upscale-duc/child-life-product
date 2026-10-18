import type { FoodDraft, RecipeDraft } from '@child-life/contracts';
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
  FoodsBody,
  GuidesBody,
  RecipesBody,
  blankSolidsGuide,
  filterFoods,
  filterRecipes,
} from '../src/screens/Solids';
import {
  FoodEditor,
  RecipeEditor,
  blankFood,
  blankRecipe,
  prepareFood,
  prepareRecipe,
} from '../src/screens/SolidsEditors';
import {
  catalogueOf,
  foodCoverageOf,
  recipeCoverageOf,
  solidsEditorUrl,
  solidsPathOf,
  solidsPlace,
  solidsUrl,
} from '../src/screens/solids-common';
import type {
  ContentItemView,
  ContentListView,
  ContentQueueView,
  ContentRow,
} from '../src/screens/content-common';
import { errorMessageId } from '../src/ui';
import { levelsForRoles, type StaffRole } from './fixtures';

// Ăn dặm on the portal (D-085, P-164 #8–#11; plan §6): the Thực phẩm, Công thức and Hướng dẫn
// tabs with their coverage, the food and recipe editors with their phone previews (5e, 5g) and
// the live checks (`unsafe-copy`, `food-too-young`), and the review queue. Server-rendered with a
// fake api, like nutrition.test.tsx; the rows follow `content-solids.ts`.

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

/** A workflow button in the editor bar (notices may name the steps too). */
const hasButton = (raw: string, label: string) => raw.includes(`>${label}</button>`);

const t = (vi: string, en: string) => ({ vi, en });
const counts = {
  inApp: 2,
  pending: 1,
  inReview: 1,
  approved: 0,
  drafts: 2,
  dueForReview: 0,
  archived: 0,
  total: 5,
};
const live = {
  revision: 1,
  publishedAt: '2026-10-01T00:00:00.000Z',
  reviewDueOn: '2027-10-01',
  illustrative: true,
  reviewer: null,
  dueForReview: false,
};

const row = (over: Partial<ContentRow>): ContentRow => ({
  id: 'fd_pumpkin',
  kind: 'food',
  status: 'draft',
  displayStatus: 'draft',
  live: null,
  title: t('Bí đỏ', 'Pumpkin'),
  reviewerLabel: null,
  lastEditorName: 'Hà Vũ',
  updatedAt: '2026-10-18T03:00:00.000Z',
  submittedByName: null,
  approverName: null,
  rejection: null,
  links: { articles: [], milestones: [] },
  ...over,
});

// The food rows of `content-solids.ts` (synonyms and prep are counts there).
const foodRows: ContentRow[] = [
  row({
    status: 'published',
    displayStatus: 'published',
    live,
    group: 'vegetable',
    allergen: null,
    ironRich: false,
    minAgeMonths: 6,
    suggest: true,
    priority: 80,
    prep: 3,
    synonyms: 1,
  }),
  row({
    id: 'fd_egg',
    title: t('Trứng gà', 'Egg'),
    status: 'published',
    displayStatus: 'published',
    live,
    group: 'animalProtein',
    allergen: 'egg',
    ironRich: true,
    minAgeMonths: 6,
    suggest: true,
  }),
  row({
    id: 'fd_honey',
    title: t('Mật ong', 'Honey'),
    group: 'fat',
    allergen: null,
    ironRich: false,
    minAgeMonths: 12,
    suggest: false,
  }),
  row({
    id: 'fd_beef',
    title: t('Thịt bò', 'Beef'),
    status: 'in_review',
    displayStatus: 'in_review',
    group: 'animalProtein',
    allergen: null,
    ironRich: true,
    minAgeMonths: 6,
    suggest: true,
  }),
  row({
    id: 'fd_old',
    title: t('Cũ', 'Old'),
    status: 'archived',
    displayStatus: 'archived',
    group: 'fruit',
    allergen: 'sesame',
  }),
];

const recipeRow = (over: Partial<ContentRow>) =>
  row({
    id: 'rcp_pumpkin_congee',
    kind: 'recipe',
    title: t('Cháo bí đỏ cho bé mới tập', 'Pumpkin congee for beginners'),
    ageMonths: { from: 6, to: 9 },
    ageLabel: { from: 6, to: 8 },
    texture: 'smooth',
    methods: ['spoon'],
    servings: 2,
    prepMinutes: 5,
    cookMinutes: 10,
    totalMinutes: 15,
    ingredients: 3,
    foodIds: ['fd_pumpkin'],
    allergens: [],
    ageProblems: [],
    steps: 3,
    hasCover: false,
    ...over,
  });

const recipeRows: ContentRow[] = [
  recipeRow({ status: 'published', displayStatus: 'published', live }),
  recipeRow({
    id: 'rcp_egg_toast',
    title: t('Bánh mì trứng cầm tay', 'Egg toast fingers'),
    ageMonths: { from: 9, to: 13 },
    texture: 'finger',
    methods: ['spoon', 'blw'],
    prepMinutes: 5,
    cookMinutes: 5,
    foodIds: ['fd_egg'],
    // An older server sends no allergens: derived from the catalogue.
    allergens: undefined,
  }),
  recipeRow({
    id: 'rcp_honey',
    title: t('Sữa chua mật ong', 'Honey yoghurt'),
    ageMonths: { from: 6, to: 12 },
    texture: 'mashed',
    foodIds: ['fd_honey'],
    ageProblems: [{ foodId: 'fd_honey', minAgeMonths: 12 }],
  }),
];

const view = (kind: ContentListView['view'], rows: ContentRow[], extra = {}): ContentListView => ({
  view: kind,
  today: '2026-10-19',
  rows,
  counts,
  available: ['article', 'food', 'recipe'],
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
          route="solids"
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

  it('adds NỘI DUNG › Ăn dặm after Dinh dưỡng for Nội dung · Xem', () => {
    for (const role of ['admin', 'ops', 'expert'] as const) {
      expect(sidebar([role])).toContain('Dinh dưỡng Ăn dặm Duyệt nội dung');
    }
    expect(sidebar(['eng'])).not.toContain('Ăn dặm');
    expect(sidebar(['admin'], 'en')).toContain('Nutrition Solid foods Content review');
  });

  it('routes the tabs and editors under /solids', () => {
    expect(routeOf('/solids')).toBe('solids');
    expect(routeOf('/solids/recipes/rcp_a')).toBe('solids');
    expect(solidsPathOf([])).toEqual({ tab: 'foods' });
    expect(solidsPathOf(['recipes'])).toEqual({ tab: 'recipes' });
    expect(solidsPathOf(['guides', 'art_a'])).toEqual({ tab: 'guides', id: 'art_a' });
    expect(solidsPathOf(['foods', 'new'])).toEqual({ tab: 'foods', id: null });
    expect(solidsPathOf(['nope'])).toEqual({ tab: 'foods' });
    expect(solidsUrl({ tab: 'foods' })).toBe('/solids');
    expect(solidsUrl({ tab: 'guides' })).toBe('/solids/guides');
    expect(solidsUrl({ tab: 'recipes', id: null })).toBe('/solids/recipes/new');
    expect(solidsEditorUrl('food', 'fd_egg')).toBe('/solids/foods/fd_egg');
    expect(editorUrlOf('recipe', 'rcp_a')).toBe('/solids/recipes/rcp_a');
    expect(editorUrlOf('food', 'fd_a')).toBe('/solids/foods/fd_a');
  });

  it('has messages for the server refusals', () => {
    for (const r of ['food-too-young', 'unsafe-copy', 'link-missing']) {
      expect(errorMessageId(new ApiError('failed-precondition', r))).toBe(`error.${r}`);
    }
    expect(vi.formatMessage({ id: 'error.food-too-young' })).toContain('mật ong');
    expect(vi.formatMessage({ id: 'error.unsafe-copy' })).toContain('gia vị');
    expect(vi.formatMessage({ id: 'error.link-missing' })).toContain('thực phẩm');
  });
});

describe('Thực phẩm', () => {
  it('lists by food group with allergen, minimum age, iron and "Gợi ý"', () => {
    const html = text(render(<FoodsBody view={view('food', foodRows)} onOpen={() => undefined} />));
    expect(html).toContain('Đang trên app 2');
    expect(html).toContain('Rau củ · 1 Bí đỏ Rau củ — Từ 6 tháng — Có');
    expect(html).toContain(
      'Đạm động vật · 2 Thịt bò Đạm động vật — Từ 6 tháng Giàu sắt Có Chờ duyệt',
    );
    expect(html).toContain('Trứng gà Đạm động vật Trứng Từ 6 tháng Giàu sắt Có');
    expect(html).toContain('Chất béo · 1 Mật ong Chất béo — Từ 12 tháng — Không');
    // 5e order: vegetables before protein before fats.
    expect(html.indexOf('Rau củ · 1')).toBeLessThan(html.indexOf('Đạm động vật · 2'));
    expect(html.indexOf('Đạm động vật · 2')).toBeLessThan(html.indexOf('Chất béo · 1'));
    expect(html).toContain('mật ong, sữa bò dạng uống: 12 tháng');
  });

  it('counts the coverage from the rows (archived foods count for nothing)', () => {
    const c = foodCoverageOf(view('food', foodRows));
    expect(c.total).toBe(4);
    expect(c.live).toBe(2);
    expect(c.byGroup).toMatchObject({ vegetable: 1, animalProtein: 2, fat: 1, fruit: 0 });
    expect(c.allergens).toEqual(['egg']);
    expect(c.ironRich).toBe(2);
    const html = text(render(<FoodsBody view={view('food', foodRows)} onOpen={() => undefined} />));
    expect(html).toContain('Độ phủ danh mục');
    expect(html).toContain('4 món · 1/9 nhóm dị ứng có món · 2 món giàu sắt');
    expect(html).toContain('Chưa có món: Đậu phộng, Sữa bò, Lúa mì');
    expect(html).toContain('2 / 4 món đang trên app');
  });

  it('uses the server coverage when the list has it', () => {
    const coverage = {
      total: 120,
      published: 100,
      groups: [
        { group: 'vegetable', total: 30, published: 28 },
        { group: 'fruit', total: 20, published: 20 },
      ],
      allergens: {
        total: 9,
        covered: 8,
        published: 7,
        missing: ['treeNut'],
        liveMissing: ['treeNut', 'sesame'],
        byAllergen: [
          { allergen: 'egg', total: 3, published: 3 },
          { allergen: 'treeNut', total: 0, published: 0 },
          { allergen: 'sesame', total: 1, published: 0 },
        ],
      },
      ironRich: { total: 18, published: 15 },
    };
    const c = foodCoverageOf(view('food', foodRows, { coverage }));
    expect(c.total).toBe(120);
    expect(c.live).toBe(100);
    expect(c.byGroup.vegetable).toBe(30);
    expect(c.byGroup.dairy).toBe(0);
    expect(c.allergens).toEqual(['egg', 'sesame']);
    expect(c.ironRich).toBe(18);
    // Only the missing list sent: every other allergen counts as covered.
    expect(
      foodCoverageOf(view('food', [], { coverage: { allergens: { missing: ['treeNut'] } } }))
        .allergens,
    ).toHaveLength(8);
  });

  it('filters by group, allergen, iron and suggestion', () => {
    const base = {
      q: '',
      group: 'all',
      allergen: 'all',
      iron: 'all',
      suggest: 'all',
      status: 'all',
      tile: 'all',
    } as const;
    const ids = (f: Partial<Parameters<typeof filterFoods>[1]>) =>
      filterFoods(foodRows, { ...base, ...f }).map((r) => r.id);
    expect(ids({ group: 'animalProtein' })).toEqual(['fd_egg', 'fd_beef']);
    expect(ids({ allergen: 'any' })).toEqual(['fd_egg', 'fd_old']);
    expect(ids({ allergen: 'egg' })).toEqual(['fd_egg']);
    expect(ids({ allergen: 'none' })).not.toContain('fd_egg');
    expect(ids({ iron: 'yes' })).toEqual(['fd_egg', 'fd_beef']);
    expect(ids({ suggest: 'no' })).toEqual(['fd_honey', 'fd_old']);
    expect(ids({ q: 'honey' })).toEqual(['fd_honey']);
    expect(ids({ tile: 'live' })).toEqual(['fd_pumpkin', 'fd_egg']);
  });
});

describe('Công thức', () => {
  it('lists by age band with texture, methods, minutes, allergens and status', () => {
    const html = text(
      render(
        <RecipesBody view={view('recipe', recipeRows)} foods={foodRows} onOpen={() => undefined} />,
      ),
    );
    expect(html).toContain(
      '6–8 tháng Cháo bí đỏ cho bé mới tập 2 phần ăn 6–8 tháng Nghiền mịn Truyền thống (đút thìa) 15 phút — Đã xuất bản',
    );
    // Allergens derived from the catalogue when the row has none.
    expect(html).toContain(
      '9–11 tháng Bánh mì trứng cầm tay 2 phần ăn 9–12 tháng Cầm tay Truyền thống (đút thìa) BLW (bé tự ăn) 10 phút Trứng',
    );
    expect(html).toContain('Sữa chua mật ong 2 phần ăn Chưa hợp tuổi · 1 nguyên liệu 6–11 tháng');
    expect(html).toContain('Không nêm muối, đường, nước mắm, hạt nêm');
  });

  it('counts recipes per band against 6 (overlap, archived left out)', () => {
    const bands = recipeCoverageOf(view('recipe', recipeRows));
    expect(bands.map((b) => [b.band.id, b.count, b.live])).toEqual([
      ['6-8', 2, 1],
      ['9-11', 2, 0],
      ['12-23', 1, 0],
      ['24-36', 0, 0],
    ]);
    const html = text(
      render(
        <RecipesBody view={view('recipe', recipeRows)} foods={foodRows} onOpen={() => undefined} />,
      ),
    );
    expect(html).toContain('Công thức theo độ tuổi');
    expect(html).toContain('0/3 độ tuổi ra mắt đủ 6 công thức trên app');
    expect(html).toContain('6–8 tháng 2/6');
    expect(html).toContain('24–36 tháng 0/6 0 trên app · không bắt buộc khi ra mắt');
  });

  it('uses the server bands when the list has them', () => {
    const coverage = {
      target: 6,
      bands: [
        { ageMonths: { from: 6, to: 9 }, published: 7, pending: 0, draft: 1, total: 8 },
        { ageMonths: { from: 9, to: 12 }, published: 6, pending: 0, draft: 0, total: 6 },
        { ageMonths: { from: 12, to: 24 }, published: 6, pending: 1, draft: 0, total: 7 },
      ],
    };
    const bands = recipeCoverageOf(view('recipe', recipeRows, { coverage }));
    expect(bands.map((b) => [b.count, b.live])).toEqual([
      [8, 7],
      [6, 6],
      [7, 6],
      [0, 0],
    ]);
    expect(
      text(
        render(
          <RecipesBody
            view={view('recipe', recipeRows, { coverage })}
            foods={foodRows}
            onOpen={() => undefined}
          />,
        ),
      ),
    ).toContain('3/3 độ tuổi ra mắt đủ 6 công thức trên app');
  });

  it('filters by band (overlap), texture and method', () => {
    const base = {
      q: '',
      band: 'all',
      texture: 'all',
      method: 'all',
      status: 'all',
      tile: 'all',
    } as const;
    const ids = (f: Partial<Parameters<typeof filterRecipes>[1]>) =>
      filterRecipes(recipeRows, { ...base, ...f }).map((r) => r.id);
    expect(ids({ band: '9-11' })).toEqual(['rcp_egg_toast', 'rcp_honey']);
    expect(ids({ band: '12-23' })).toEqual(['rcp_egg_toast']);
    expect(ids({ texture: 'finger' })).toEqual(['rcp_egg_toast']);
    expect(ids({ method: 'blw' })).toEqual(['rcp_egg_toast']);
  });
});

describe('Hướng dẫn', () => {
  const article = (over: Partial<ContentRow>) =>
    row({
      id: 'art_solids_readiness',
      kind: 'article',
      title: t('Dấu hiệu bé sẵn sàng ăn dặm', 'Signs of readiness'),
      library: 'solids',
      topic: 'feeding',
      format: 'article',
      ageWeeks: { from: 17, to: 30 },
      readingMinutes: 5,
      ...over,
    });

  it('lists only the solids articles, with their own counts', () => {
    const rows = [
      article({ status: 'published', displayStatus: 'published', live }),
      article({ id: 'art_solids_methods', title: t('BLW hay truyền thống?', 'BLW or spoon?') }),
      article({ id: 'art_sleep', title: t('Giấc ngủ ngắn', 'Naps'), library: 'care' }),
    ];
    const html = text(render(<GuidesBody view={view('article', rows)} onOpen={() => undefined} />));
    expect(html).toContain('Dấu hiệu bé sẵn sàng ăn dặm');
    expect(html).toContain('BLW hay truyền thống?');
    expect(html).not.toContain('Giấc ngủ ngắn');
    expect(html).toContain('Đang trên app 1');
    expect(html).toContain('Nháp 1');
    expect(html).toContain('chủ đề “Bú & sữa”');
  });

  it('a new guide starts in the solids library, topic feeding', () => {
    expect(blankSolidsGuide()).toMatchObject({
      library: 'solids',
      topic: 'feeding',
      ageWeeks: { from: 26, to: 52 },
    });
  });
});

const fullFood = (): FoodDraft => ({
  ...blankFood(),
  name: t('Trứng gà', 'Egg'),
  synonyms: { vi: ['trứng', ''], en: ['hen egg'] },
  group: 'animalProtein',
  allergen: 'egg',
  ironRich: true,
  prep: [
    {
      texture: 'smooth',
      text: t('Luộc chín kỹ, nghiền lòng đỏ với sữa.', 'Hard-boil; mash the yolk with milk.'),
    },
    {
      texture: 'finger',
      text: t('Trứng tráng chín kỹ, cắt thanh.', 'Well-cooked omelette strips.'),
    },
  ],
  chokingNote: t('Luôn nấu chín kỹ.', 'Always cook through.'),
  sources: [{ label: 'ASCIA', url: 'https://www.allergy.org.au/' }],
});

describe('food editor', () => {
  const editor = (item: ContentItemView<FoodDraft> | null, others: ContentRow[] = []) =>
    text(
      render(
        <FoodEditor
          item={item}
          foods={others}
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

  it('edits the food and previews the 5e row and the food detail', () => {
    const html = editor(itemOf(fullFood(), { id: 'fd_egg' }));
    expect(html).toContain('Ăn dặm Trứng gà Nháp');
    expect(html).toContain('Tên 8/40');
    expect(html).toContain('Tên gọi khác (VI) 1/8');
    expect(html).toContain('Tuổi tối thiểu');
    expect(html).toContain('Gửi duyệt');
    // 5e row and food detail.
    expect(html).toContain(
      'Món đã thử Tất cả · 1 Đạm động vật · 1 Trứng gà Lần đầu hôm nay · 1 lần Thích',
    );
    expect(html).toContain(
      'Đây là ghi chép của gia đình bạn, không phải đánh giá hay khuyến nghị dinh dưỡng.',
    );
    expect(html).toContain('Đạm động vật Từ 6 tháng Giàu sắt Dễ gây dị ứng: trứng');
    expect(html).toContain(
      'Cách chuẩn bị theo độ đặc Nghiền mịn Luộc chín kỹ, nghiền lòng đỏ với sữa.',
    );
    expect(html).toContain('Luôn nấu chín kỹ.');
    expect(html).toContain('Không gợi ý món này');
    expect(html).toContain(
      'Biên soạn theo hướng dẫn WHO, AAP, NHS · Tham khảo, không thay thế bác sĩ',
    );
    expect(html).toContain('Nguồn: ASCIA');
  });

  it('a dose names the field and hides "Gửi duyệt"; same names warn', () => {
    const bad = fullFood();
    bad.prep[0]!.text.vi = 'Thêm 5 mg sắt.';
    const html = editor(itemOf(bad, { id: 'fd_egg' }), [
      row({ id: 'fd_egg2', title: t('Trứng gà', 'Hen egg') }),
    ]);
    expect(html).toContain('Chưa gửi duyệt được: 1 chỗ cần sửa');
    expect(html).toContain(
      'Cách chuẩn bị · mục 1 · Nội dung · VI: “5 mg” trông như một liều thuốc',
    );
    expect(html).not.toContain('Gửi duyệt');
    expect(html).toContain('Đã có thực phẩm cùng tên: Trứng gà.');
  });

  it('a new food has no workflow; empty synonyms are not saved', () => {
    const html = editor(null);
    expect(html).toContain('Thực phẩm mới');
    expect(html).toContain('Chưa lưu');
    expect(html).not.toContain('Gửi duyệt');
    expect(prepareFood(fullFood()).synonyms).toEqual({ vi: ['trứng'], en: ['hen egg'] });
  });
});

const fullRecipe = (): RecipeDraft => ({
  ...blankRecipe(),
  title: t('Cháo trứng bí đỏ', 'Egg and pumpkin congee'),
  summary: t('Bữa đầu có trứng chín kỹ.', 'A first meal with well-cooked egg.'),
  ageMonths: { from: 7, to: 12 },
  texture: 'mashed',
  methods: ['spoon'],
  servings: 2,
  prepMinutes: 10,
  cookMinutes: 20,
  ingredients: [
    {
      foodId: 'fd_pumpkin',
      name: t('Bí đỏ', 'Pumpkin'),
      qty: 50,
      unit: 'g',
      note: t('hấp chín', 'steamed'),
    },
    {
      foodId: 'fd_egg',
      name: t('Lòng đỏ trứng', 'Egg yolk'),
      qty: 1,
      unit: 'piece',
      note: t('', ''),
    },
    {
      foodId: null,
      name: t('Nước dùng rau', 'Vegetable stock'),
      qty: 150,
      unit: 'ml',
      note: t('', ''),
    },
  ],
  steps: {
    vi: ['Nấu cháo nhừ.', 'Hấp bí, nghiền.', 'Trộn lòng đỏ chín kỹ.', ''],
    en: ['Cook the congee soft.', 'Steam and mash the pumpkin.', 'Stir in the cooked yolk.'],
  },
  storage: t('Ngăn mát tối đa 24 giờ.', 'Fridge up to 24 hours.'),
  sources: [{ label: 'NHS', url: 'https://www.nhs.uk/' }],
});

describe('recipe editor', () => {
  const editorRaw = (item: ContentItemView<RecipeDraft> | null, foods: ContentRow[] = foodRows) =>
    render(
      <RecipeEditor
        item={item}
        foods={foods}
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
  const recipeItem = (data: RecipeDraft, over: Partial<ContentRow> = {}) =>
    itemOf(data, { id: 'rcp_egg', kind: 'recipe', ...over });

  it('derives the allergens and previews 5g', () => {
    const raw = editorRaw(recipeItem(fullRecipe()));
    const html = text(raw);
    expect(html).toContain('Ăn dặm Cháo trứng bí đỏ · 7–11 tháng Nháp');
    expect(hasButton(raw, 'Gửi duyệt')).toBe(true);
    expect(html).toContain('Nguyên liệu 1 Bí đỏ · Rau củ');
    expect(html).toContain('Nguyên liệu 2 Trứng gà · Đạm động vật Trứng');
    expect(html).toContain('Nguyên liệu 3 Tên khác');
    expect(html).toContain('Dị ứng (tự tính): Trứng');
    expect(html).toContain('2 nguyên liệu từ danh mục');
    expect(html).toContain('1 tên khác');
    // 5g
    expect(html).toContain('Công thức 7–11 tháng 30 phút Nghiền lợn cợn Truyền thống');
    expect(html).toContain('Nguyên liệu 2 phần ăn Bí đỏ hấp chín 50 g Lòng đỏ trứng 1 miếng');
    expect(html).toContain('Nước dùng rau 150 ml');
    expect(html).toContain('Có trứng');
    expect(html).toContain('Cách làm 1 Nấu cháo nhừ. 2 Hấp bí, nghiền. 3 Trộn lòng đỏ chín kỹ.');
    expect(html).toContain('Bảo quản Ngăn mát tối đa 24 giờ.');
    expect(html).toContain('Độ đặc, lượng và thời điểm thử món mới tuỳ từng bé');
    expect(html).toContain(
      'Biên soạn theo hướng dẫn WHO, AAP, NHS · Tham khảo, không thay thế bác sĩ',
    );
    expect(html).toContain('Lưu Ghi vào nhật ký');
    expect(prepareRecipe(fullRecipe()).steps.vi).toHaveLength(3);
  });

  it('honey for a 6-month recipe: "Mật ong chỉ từ 12 tháng", no Gửi duyệt, Duyệt or Xuất bản', () => {
    const honey = fullRecipe();
    honey.ageMonths = { from: 6, to: 9 };
    honey.ingredients.push({
      foodId: 'fd_honey',
      name: t('Mật ong', 'Honey'),
      qty: 1,
      unit: 'tsp',
      note: t('', ''),
    });
    const raw = editorRaw(recipeItem(honey));
    const html = text(raw);
    expect(html).toContain('Chưa hợp tuổi: 1 nguyên liệu');
    expect(html).toContain('Mật ong chỉ từ 12 tháng');
    expect(html).toContain('Từ 12 tháng');
    // The honey line is a seasoning too.
    expect(html).toContain('Nguyên liệu · mục 4 · Tên hiển thị · VI: “mật ong”');
    expect(hasButton(raw, 'Gửi duyệt')).toBe(false);
    // Honey is not on the app yet: Xuất bản would be refused (`link-missing`).
    expect(html).toContain('Chưa có trên app: Mật ong.');
    const approved = (data: RecipeDraft) =>
      editorRaw(recipeItem(data, { status: 'approved', displayStatus: 'approved' }));
    expect(hasButton(approved(honey), 'Xuất bản')).toBe(false);
    expect(hasButton(approved(honey), 'Trả lại')).toBe(true);
    honey.ageMonths = { from: 12, to: 24 };
    expect(hasButton(approved(honey), 'Xuất bản')).toBe(true);
  });

  it('an added seasoning names the step; steps must match in vi and en', () => {
    const salty = fullRecipe();
    salty.steps.vi[1] = 'Nêm thêm nước mắm cho vừa.';
    salty.steps.en.pop();
    const raw = editorRaw(recipeItem(salty));
    const html = text(raw);
    expect(html).toContain(
      'Cách làm · VI · mục 2: “Nêm thêm nước mắm”: món của bé không nêm thêm gia vị',
    );
    expect(html).toContain('Tiếng Việt có 3 bước, tiếng Anh có 2 bước');
    expect(hasButton(raw, 'Gửi duyệt')).toBe(false);
    expect(solidsPlace(vi, ['ingredients', 2, 'name', 'en'])).toBe(
      'Nguyên liệu · mục 3 · Tên hiển thị · EN',
    );
  });

  it('a new recipe starts at 6 months with no workflow', () => {
    const raw = editorRaw(null);
    const html = text(raw);
    expect(html).toContain('Công thức mới · 6–8 tháng');
    expect(hasButton(raw, 'Gửi duyệt')).toBe(false);
    expect(html).toContain('Chưa có nguyên liệu nào.');
    expect(catalogueOf(foodRows).get('fd_honey')).toMatchObject({ minAgeMonths: 12, live: false });
  });
});

describe('Duyệt nội dung with the solids kinds', () => {
  const queue: ContentQueueView = {
    view: 'queue',
    today: '2026-10-19',
    rows: [
      { ...foodRows[3]!, submittedByName: 'Hà Vũ' },
      recipeRow({ status: 'in_review', displayStatus: 'in_review', id: 'rcp_q' }),
    ],
    counts: { food: counts },
    totals: counts,
    available: ['article', 'food', 'recipe'],
    requireReview: false,
  };

  it('lists foods and recipes with their ages', () => {
    const html = text(render(<ReviewBody view={queue} onChanged={() => undefined} />));
    expect(html).toContain('Chờ duyệt 2');
    expect(html).toContain('Thực phẩm ăn dặm Từ 6 tháng Thịt bò');
    expect(html).toContain('Công thức ăn dặm 6–8 tháng Cháo bí đỏ cho bé mới tập');
  });

  it('previews each kind and flags an added seasoning', () => {
    const detail = (item: ContentItemView) =>
      text(
        render(
          <ReviewDetail
            item={item}
            requireReview={false}
            today="2026-10-19"
            staffUid="s1"
            can={{ edit: true, approve: true }}
            onChanged={() => undefined}
          />,
        ),
      );
    const food = detail(
      itemOf(fullFood(), {
        id: 'fd_egg',
        status: 'in_review',
        displayStatus: 'in_review',
      }) as unknown as ContentItemView,
    );
    expect(food).toContain('Thực phẩm ăn dặm');
    expect(food).toContain('ASCIA');
    expect(food).toContain('Dễ gây dị ứng: trứng');
    const salty = fullRecipe();
    salty.steps.vi[0] = 'Nấu cháo, thêm muối.';
    const raw = render(
      <ReviewDetail
        item={
          itemOf(salty, {
            id: 'rcp_egg',
            kind: 'recipe',
            status: 'in_review',
            displayStatus: 'in_review',
          }) as unknown as ContentItemView
        }
        requireReview={false}
        today="2026-10-19"
        staffUid="s1"
        can={{ edit: true, approve: true }}
        onChanged={() => undefined}
      />,
    );
    const recipe = text(raw);
    expect(raw).toContain('href="/solids/recipes/rcp_egg"');
    expect(recipe).toContain(
      'Cách làm · VI · mục 1: “thêm muối”: món của bé không nêm thêm gia vị',
    );
    expect(recipe).toContain('Ghi vào nhật ký');
    expect(recipe).toContain('NHS');
  });
});
