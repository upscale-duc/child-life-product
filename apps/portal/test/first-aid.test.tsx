import { firstAidPackSchema, type FirstAidPack } from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider, createIntl } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, type Api, type FirstAidView } from '../src/api';
import { StaffContext } from '../src/context';
import { messages } from '../src/messages';
import { Sidebar } from '../src/Shell';
import { ActDialog, FirstAidBody, reviewFrom } from '../src/screens/FirstAid';
import {
  IssuesContext,
  LibraryContext,
  SituationEditor,
  blankSituation,
  blankStep,
  issueText,
  kebabName,
  moveItem,
  saveFirstAidDraft,
  validatePack,
} from '../src/screens/FirstAidEditor';
import { levelsForRoles, staffRoles, type StaffRole } from './fixtures';

// Sơ cứu on the portal (D-058, P-141): status, history, the two-person approval with the medical
// review, permissions, and the editor's pack passing the shared schema. Server-rendered, no network.
const noApi: Api = { call: () => Promise.reject(new Error('no network in tests')) };

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
      <ApiContext.Provider value={noApi}>
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
    .replace(/\s+/g, ' ');

const t = (vi: string, en: string) => ({ vi, en });

const pack: FirstAidPack = {
  emergencyNumber: '115',
  categories: [
    { id: 'urgent', title: t('Khẩn cấp', 'Urgent'), layout: 'grid', tone: 'danger' },
    { id: 'health', title: t('Sức khoẻ', 'Health'), layout: 'list', tone: 'mint' },
  ],
  situations: [
    {
      id: 'choking',
      code: 'TH02',
      category: 'urgent',
      emergency: true,
      monitoring: false,
      title: t('Hóc dị vật', 'Choking'),
      lead: t('Bé ho sặc, khó thở', 'Baby is coughing, struggling to breathe'),
      keywords: [t('Sặc', 'Gagging')],
      icon: 'icon-choking_0a1b2c3d',
      hero: 'hoc-di-vat_1a2b3c4d',
      ageMonths: null,
      variantKind: 'age',
      variants: [
        {
          id: 'under-1',
          label: t('Dưới 1 tuổi', 'Under 1'),
          ageMonths: { from: 0, to: 12 },
          hero: null,
          banner: t('Gọi 115 nếu bé không thở', 'Call 115 if the baby is not breathing'),
          steps: [
            {
              title: t('Vỗ lưng 5 lần', 'Give 5 back blows'),
              body: t('Đặt bé nằm sấp trên cánh tay.', 'Lay the baby face down on your forearm.'),
              image: 'vo-lung_2b3c4d5e',
              chips: [{ label: t('× 5', '× 5'), tone: 'mint' }],
              count: 5,
              cprRole: null,
            },
          ],
          callouts: [
            {
              tone: 'negative',
              heading: t('Không được làm', 'Do not'),
              items: [t('Móc họng bé', "Sweep the baby's mouth blindly")],
            },
          ],
          cpr: null,
        },
        {
          id: 'from-1',
          label: t('Từ 1 tuổi', 'From 1'),
          ageMonths: { from: 12, to: null },
          hero: null,
          banner: null,
          steps: [
            {
              title: t('Ấn bụng', 'Abdominal thrusts'),
              body: t('Đứng sau lưng bé.', 'Stand behind the child.'),
              image: null,
              chips: [],
              count: null,
              cprRole: null,
            },
          ],
          callouts: [],
          cpr: null,
        },
      ],
      tool: null,
    },
    {
      id: 'fever',
      code: 'TH21',
      category: 'health',
      emergency: false,
      monitoring: true,
      title: t('Sốt', 'Fever'),
      lead: t('Nhiệt độ từ 38 °C', 'Temperature of 38 °C or more'),
      keywords: [],
      icon: 'icon-fever_3c4d5e6f',
      hero: 'sot_4d5e6f70',
      ageMonths: null,
      variantKind: null,
      variants: [
        {
          id: 'default',
          label: null,
          ageMonths: null,
          hero: null,
          banner: null,
          steps: [
            {
              title: t('Đo nhiệt độ', 'Take the temperature'),
              body: t('Dùng nhiệt kế điện tử.', 'Use a digital thermometer.'),
              image: null,
              chips: [],
              count: null,
              cprRole: null,
            },
          ],
          callouts: [],
          cpr: null,
        },
      ],
      tool: null,
    },
  ],
  cpr: [],
  quickSearch: [t('khó thở', 'trouble breathing')],
  review: null,
};

const images = [
  'icon-choking_0a1b2c3d',
  'hoc-di-vat_1a2b3c4d',
  'vo-lung_2b3c4d5e',
  'icon-fever_3c4d5e6f',
  'sot_4d5e6f70',
].map((id) => ({ id, url: `https://example.test/${id}.webp` }));

const view: FirstAidView = {
  current: { version: 'fa_20261010_01', publishedAt: '2026-10-10T02:00:00Z', pack },
  draft: {
    versionId: 'fv_00112233445566aa',
    status: 'pending',
    label: null,
    notes: 'Thêm biến thể từ 1 tuổi',
    authorName: 'Minh Phạm',
    approverName: null,
    createdAt: '2026-10-11T01:00:00Z',
    updatedAt: '2026-10-11T02:00:00Z',
    approvedAt: null,
    rejection: { by: 'BS. Hà', reason: 'Thiếu nguồn' },
    situations: 2,
    pack,
  },
  history: [
    {
      versionId: 'fv_00112233445566aa',
      status: 'pending',
      label: null,
      notes: '',
      authorName: 'Minh Phạm',
      approverName: null,
      createdAt: '2026-10-11T01:00:00Z',
      updatedAt: '2026-10-11T02:00:00Z',
      approvedAt: null,
      rejection: null,
      situations: 2,
    },
    {
      versionId: 'fv_aabbccddeeff0011',
      status: 'published',
      label: 'fa_20261010_01',
      notes: 'Bản đầu',
      authorName: 'Minh Phạm',
      approverName: 'BS. Hà',
      createdAt: '2026-10-09T01:00:00Z',
      updatedAt: '2026-10-10T02:00:00Z',
      approvedAt: '2026-10-10T02:00:00Z',
      rejection: null,
      situations: 2,
    },
    {
      versionId: 'fv_aabbccddeeff0022',
      status: 'retired',
      label: 'fa_20261001_01',
      notes: 'Bản thử',
      authorName: 'Linh Trần',
      approverName: 'BS. Hà',
      createdAt: '2026-09-30T01:00:00Z',
      updatedAt: '2026-10-01T02:00:00Z',
      approvedAt: '2026-10-01T02:00:00Z',
      rejection: null,
      situations: 1,
    },
  ],
  images,
  requireReview: true,
};

const body = (v: FirstAidView, canEdit: boolean, canApprove: boolean, situation?: string) => (
  <FirstAidBody
    view={v}
    canEdit={canEdit}
    canApprove={canApprove}
    onChanged={() => undefined}
    initialSituation={situation ?? null}
  />
);

describe('Sơ cứu: messages (D-012)', () => {
  it('dynamic ids exist in both catalogs', () => {
    const ids = [
      'nav.firstAid',
      'nav.section.content',
      ...['image-missing', 'image-unreadable', 'review-required', 'same-person'].map(
        (r) => `error.${r}`,
      ),
      ...['submit', 'approve', 'reject', 'discard', 'rollback'].flatMap((a) => [
        `firstAid.act.${a}`,
        `firstAid.confirm.${a}`,
        `firstAid.confirm.${a}.note`,
      ]),
      ...['draft', 'pending', 'published', 'retired', 'discarded'].map(
        (s) => `firstAid.status.${s}`,
      ),
      ...[
        'required',
        'tooShort',
        'tooLong',
        'tooFew',
        'tooMany',
        'min',
        'max',
        'format',
        'number',
        'image',
        'category',
        'duplicate',
        'variantLabels',
        'invalid',
      ].map((e) => `firstAid.err.${e}`),
      ...['situations', 'general', 'library'].map((x) => `firstAid.tab.${x}`),
      ...['all', 'picture', 'icon'].map((x) => `firstAid.filter.${x}`),
      ...['vi', 'en'].map((x) => `firstAid.lang.${x}`),
      ...['grid', 'list'].map((x) => `firstAid.layout.${x}`),
      ...['danger', 'sunshine', 'mint'].map((x) => `firstAid.categoryTone.${x}`),
      ...['mint', 'neutral'].map((x) => `firstAid.chipTone.${x}`),
      ...['negative', 'warning', 'positive'].map((x) => `firstAid.tone.${x}`),
      ...['infant', 'child'].map((x) => `firstAid.cpr.${x}`),
      'firstAid.tool.seizureTimer',
    ];
    for (const id of ids) {
      expect(messages.vi[id], id).toBeTruthy();
      expect(messages.en[id], id).toBeTruthy();
    }
  });
});

describe('Sơ cứu: status, history and actions', () => {
  it('shows the version in use, the open version and the history', () => {
    const html = text(render(body(view, true, true)));
    expect(html).toContain('● Bản đang dùng · fa_20261010_01');
    expect(html).toContain('Xuất bản 09:00 10/10/2026 · 2 tình huống');
    expect(html).toContain('2 tình huống');
    expect(html).toContain('Chờ duyệt Bản đang soạn');
    expect(html).toContain('Soạn: Minh Phạm');
    expect(html).toContain('BS. Hà trả lại: “Thiếu nguồn”');
    expect(html).toContain('Thêm biến thể từ 1 tuổi');
    // History: published and retired rows; the open version is not repeated there.
    expect(html).toContain('Lịch sử phiên bản');
    expect(html).toContain('fa_20261010_01 Đang dùng 2 Soạn: Minh Phạm · Duyệt: BS. Hà');
    expect(html).toContain('fa_20261001_01 Đã thay 1 Soạn: Linh Trần · Duyệt: BS. Hà');
    // Only the replaced version can come back.
    expect(html.match(/Dùng lại bản này/g)).toHaveLength(1);
    // The list of situations with badges and counts.
    expect(html).toContain(
      'TH02 Hóc dị vật Bé ho sặc, khó thở Khẩn cấp Khẩn cấp 2 biến thể · 2 bước',
    );
    expect(html).toContain('TH21 Sốt');
    expect(html).toContain('Theo dõi');
  });

  it('nothing published yet: an empty state, and "Sửa" for editors', () => {
    const empty: FirstAidView = { ...view, current: null, draft: null, history: [] };
    expect(text(render(body(empty, true, false)))).toContain('Chưa xuất bản bản nào');
    expect(text(render(body(empty, true, false)))).toContain('Bấm “Sửa” để soạn bản đầu tiên');
    expect(text(render(body(empty, false, false)))).not.toContain('Sửa');
  });

  it('actions follow the permission and the status', () => {
    // Xem only (Hỗ trợ): nothing to press.
    const viewer = text(render(body(view, false, false), ['support']));
    for (const label of ['Sửa', 'Gửi duyệt', 'Huỷ nháp', 'Duyệt & xuất bản', 'Trả lại']) {
      expect(viewer).not.toContain(label);
    }
    expect(viewer).not.toContain('Dùng lại bản này');
    // Sửa (Vận hành) on a pending version: may edit, may not approve or send back.
    const editor = text(render(body(view, true, false), ['ops']));
    expect(editor).toContain('Sửa bản nháp');
    expect(editor).not.toContain('Duyệt & xuất bản');
    expect(editor).not.toContain('Trả lại');
    expect(editor).not.toContain('Gửi duyệt'); // already submitted
    // A draft: Gửi duyệt and Huỷ nháp for editors, nothing to approve yet.
    const draft: FirstAidView = { ...view, draft: { ...view.draft!, status: 'draft' } };
    const editorDraft = text(render(body(draft, true, false), ['ops']));
    expect(editorDraft).toContain('Gửi duyệt');
    expect(editorDraft).toContain('Huỷ nháp');
    // Duyệt (chuyên gia) on a pending version.
    const approver = text(render(body(view, true, true), ['expert']));
    expect(approver).toContain('Duyệt & xuất bản');
    expect(approver).toContain('Trả lại');
    expect(approver).toContain('Dùng lại bản này');
  });

  it('a situation page shows the phone preview of what the app shows', () => {
    const html = text(render(body(view, false, false, 'choking')));
    expect(html).toContain('Tất cả tình huống');
    expect(html).toContain('Xem trước trên app');
    expect(html).toContain('Hóc dị vật Bé ho sặc, khó thở Dưới 1 tuổi Từ 1 tuổi');
    expect(html).toContain('Gọi 115 nếu bé không thở');
    expect(html).toContain('1 Vỗ lưng 5 lần Đặt bé nằm sấp trên cánh tay.');
    expect(html).toContain('Không được làm Móc họng bé');
    expect(html).toContain('Gọi 115');
    expect(render(body(view, false, false, 'choking'))).toContain(
      'https://example.test/hoc-di-vat_1a2b3c4d.webp',
    );
  });
});

describe('Sơ cứu: approving needs the medical review on prod', () => {
  const props = {
    versionId: 'fv_00112233445566aa',
    initialReview: null,
    onClose: () => undefined,
    onDone: () => undefined,
  };
  it('the approve dialog asks for reviewer, date and sources', () => {
    const html = text(render(<ActDialog act="approve" requireReview {...props} />));
    expect(html).toContain('Rà soát chuyên môn (bắt buộc)');
    expect(html).toContain('Người rà soát');
    expect(html).toContain('Ngày rà soát');
    expect(html).toContain('Nguồn tham khảo');
    expect(html).toContain('Ghi đủ người rà soát');
    // The approve button stays off until the review and the reason are there.
    expect(render(<ActDialog act="approve" requireReview {...props} />)).toMatch(
      /<button type="button" class="btn btn--primary" disabled="">Duyệt &amp; xuất bản/,
    );
    const reject = text(render(<ActDialog act="reject" requireReview {...props} />));
    expect(reject).not.toContain('Người rà soát');
  });

  it('review fields are required when the server requires them', () => {
    const empty = { reviewer: '', reviewedOn: '2026-10-12', sources: '' };
    expect(reviewFrom(empty, true).ok).toBe(false);
    expect(reviewFrom({ ...empty, reviewer: 'BS. Hà' }, true).ok).toBe(false);
    expect(
      reviewFrom({ ...empty, reviewer: 'BS. Hà', reviewedOn: '', sources: 'WHO' }, true).ok,
    ).toBe(false);
    const full = reviewFrom(
      { reviewer: ' BS. Hà ', reviewedOn: '2026-10-12', sources: 'WHO 2024\n\n Bộ Y tế ' },
      true,
    );
    expect(full).toEqual({
      ok: true,
      review: { reviewer: 'BS. Hà', reviewedOn: '2026-10-12', sources: ['WHO 2024', 'Bộ Y tế'] },
    });
    // Dev: no review is fine; a half-filled one is not.
    expect(reviewFrom(empty, false)).toEqual({ ok: true, review: null });
    expect(reviewFrom({ ...empty, reviewer: 'B' }, false).ok).toBe(false);
  });
});

describe('Sơ cứu: the editor', () => {
  it('the fixture pack is valid', () => {
    expect(firstAidPackSchema.safeParse(pack).success).toBe(true);
  });

  it('saves a pack that passes firstAidPackSchema', async () => {
    const calls: Array<{ name: string; data: unknown }> = [];
    const api: Api = {
      call: <T,>(name: string, data?: unknown) => {
        calls.push({ name, data });
        return Promise.resolve({ versionId: 'fv_0011223344556677' } as T);
      },
    };
    // Edits as the editor makes them: a new step, reorder, a new situation filled in.
    const next = structuredClone(pack);
    const v = next.situations[0]!.variants[1]!;
    v.steps.push({
      ...blankStep(),
      title: t('Gọi 115', 'Call 115'),
      body: t('Nếu bé ngất.', 'If the child faints.'),
    });
    moveItem(v.steps, 1, -1);
    const s = blankSituation(next);
    s.title = t('Bỏng', 'Burns');
    s.lead = t('Bỏng nước sôi, bỏng lửa', 'Scalds and burns');
    s.icon = 'icon-fever_3c4d5e6f';
    s.hero = 'sot_4d5e6f70';
    s.variants[0]!.steps[0] = {
      ...blankStep(),
      title: t('Làm mát', 'Cool the burn'),
      body: t('Dội nước mát 20 phút.', 'Run cool water over it for 20 minutes.'),
    };
    next.situations.push(s);

    const res = await saveFirstAidDraft(api, next, '  Thêm bỏng  ');
    expect(res).toEqual({ ok: true, versionId: 'fv_0011223344556677' });
    expect(calls).toHaveLength(1);
    expect(calls[0]!.name).toBe('staffFirstAidDraft');
    const sent = calls[0]!.data as { pack: FirstAidPack; notes: string };
    expect(sent.notes).toBe('Thêm bỏng');
    expect(firstAidPackSchema.safeParse(sent.pack).success).toBe(true);
    expect(sent.pack.situations[0]!.variants[1]!.steps[0]!.title.vi).toBe('Gọi 115');
    expect(sent.pack.situations[2]!.id).toBe('tinh-huong-1');
  });

  it('an invalid pack is not sent, and every problem has a field and a message', async () => {
    let called = false;
    const api: Api = {
      call: () => {
        called = true;
        return Promise.reject(new Error('should not be called'));
      },
    };
    const next = structuredClone(pack);
    next.situations.push(blankSituation(next)); // empty texts, no pictures
    next.situations[0]!.title.en = '';
    next.situations[0]!.variants[0]!.steps[0]!.count = 20;
    next.situations[1]!.variants.push({ ...next.situations[1]!.variants[0]!, id: 'second' });
    const res = await saveFirstAidDraft(api, next, '');
    expect(called).toBe(false);
    expect(res.ok).toBe(false);
    const check = validatePack(next);
    expect(check.issues.has('situations.0.title.en')).toBe(true);
    expect(check.issues.has('situations.2.icon')).toBe(true);
    expect(check.issues.has('situations.1.variants')).toBe(true);
    const intl = createIntl({ locale: 'vi', messages: messages.vi });
    expect(issueText(intl, check.issues.get('situations.0.title.en')!)).toBe('Bắt buộc.');
    expect(issueText(intl, check.issues.get('situations.2.icon')!)).toBe(
      'Chọn một ảnh trong thư viện.',
    );
    expect(issueText(intl, check.issues.get('situations.0.variants.0.steps.0.count')!)).toBe(
      'Lớn nhất là 10.',
    );
    expect(issueText(intl, check.issues.get('situations.1.variants')!)).toContain('đặt nhãn');
  });

  it('the editor shows vi and en side by side, and per-field errors once saving was tried', () => {
    const broken = structuredClone(pack);
    broken.situations[1]!.lead.en = '';
    const editor = (show: boolean) =>
      render(
        <IssuesContext.Provider value={{ issues: validatePack(broken).issues, show }}>
          <LibraryContext.Provider value={{ images, canUpload: true, onUploaded: () => undefined }}>
            <SituationEditor
              pack={broken}
              index={1}
              edit={() => undefined}
              idLocked
              variant={0}
              onVariant={() => undefined}
            />
          </LibraryContext.Provider>
        </IssuesContext.Provider>,
      );
    const html = editor(true);
    expect(html).toContain('value="Sốt"');
    expect(html).toContain('value="Fever"');
    expect(text(html)).toContain('Tên tình huống Tiếng Việt English');
    expect(text(html)).toContain('Mô tả ngắn Tiếng Việt English Bắt buộc.');
    expect(html).toContain('https://example.test/icon-fever_3c4d5e6f.webp');
    expect(text(html)).toContain('Bước 1');
    expect(text(html)).toContain('Thêm lưu ý');
    expect(text(editor(false))).not.toContain('Bắt buộc.');
  });

  it('picture names come from the file name, kebab-cased', () => {
    expect(kebabName('Vỗ lưng ở bé.PNG', false)).toBe('vo-lung-o-be');
    expect(kebabName('Đuối nước (1).jpg', false)).toBe('duoi-nuoc-1');
    expect(kebabName('choking.webp', true)).toBe('icon-choking');
    expect(kebabName('icon-fever.png', true)).toBe('icon-fever');
    expect(kebabName('x'.repeat(60) + '.png', false)).toHaveLength(40);
    expect(kebabName('!.png', false)).toBe('anh');
  });
});

describe('Sơ cứu: the sidebar', () => {
  it('NỘI DUNG › Sơ cứu for every role that may view content', () => {
    const sidebar = (roles: StaffRole[]) =>
      text(
        render(
          <Sidebar
            route="firstAid"
            badges={null}
            environment="dev"
            locale="vi"
            onLocale={() => undefined}
            onSignOut={() => undefined}
            navigate={() => undefined}
          />,
          roles,
        ),
      );
    for (const role of ['admin', 'ops', 'support', 'expert'] as const) {
      expect(sidebar([role]), role).toContain('NỘI DUNG Sơ cứu');
    }
    expect(sidebar(['analyst'])).not.toContain('Sơ cứu');
    expect(staffRoles).toContain('expert');
  });
});
