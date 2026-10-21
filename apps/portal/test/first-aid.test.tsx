import { firstAidPackSchema, type FirstAidPack } from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider, createIntl } from 'react-intl';
import { TooltipProvider } from '@/components/ui/tooltip';
import { describe, expect, it } from 'vitest';
import { ApiContext, type Api, type FirstAidView } from '../src/api';
import { StaffContext } from '../src/context';
import { messages } from '../src/messages';
import { Sidebar } from '../src/Shell';
import {
  ActDialog,
  FirstAidBody,
  GeneralSummary,
  HistoryTable,
  Library,
  SituationList,
  canReuseVersion,
  draftActions,
  issuePlace,
  reviewFrom,
} from '../src/screens/FirstAid';
import {
  GeneralEditor,
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
// review, permissions, and the editor's pack passing the shared schema. Server-rendered, no network:
// Radix menus, folded sections and dialogs do not render here, so what sits behind "⋯" is checked
// through the functions that build it (draftActions, canReuseVersion).
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
      'firstAid.toast.saved',
      ...['submit', 'approve', 'reject', 'discard', 'rollback'].map((a) => `firstAid.toast.${a}`),
    ];
    for (const id of ids) {
      expect(messages.vi[id], id).toBeTruthy();
      expect(messages.en[id], id).toBeTruthy();
    }
  });

  it('no development notes in the Sơ cứu copy (vi and en)', () => {
    const devNote =
      /\b(dev|figma|seed|engineering)\b|môi trường|environment|kỹ thuật|chưa vẽ|\b[DPRGQ]-\d{3}\b/i;
    for (const catalog of [messages.vi, messages.en]) {
      for (const [id, copy] of Object.entries(catalog)) {
        if (id.startsWith('firstAid.')) expect(copy, id).not.toMatch(devNote);
      }
    }
  });
});

describe('Sơ cứu: status, history and actions', () => {
  it('shows the version in use as a badge, the open draft as a notice, then the list', () => {
    const raw = render(body(view, true, true));
    const html = text(raw);
    // Owner 2026-10-21: no "● Bản đang dùng · … Xuất bản …" banner; a badge with the details in
    // its popover and tooltip.
    expect(html).not.toContain('● Bản đang dùng');
    expect(html).toContain('Đang dùng');
    expect(raw).toContain(
      'title="Bản đang dùng fa_20261010_01 · Xuất bản 09:00 10/10/2026 · 2 tình huống',
    );
    expect(html).toContain('Chờ duyệt Bản đang soạn');
    expect(html).toContain('Soạn: Minh Phạm');
    expect(html).toContain('BS. Hà trả lại: “Thiếu nguồn”');
    expect(html).toContain('Thêm biến thể từ 1 tuổi');
    // Tabs (shadcn) with counts.
    expect(html).toContain('Tình huống 2 Cài đặt chung Thư viện ảnh 5');
    // The list of situations: code, name and lead, group, badges, counts.
    expect(html).toContain(
      'TH02 Hóc dị vật Bé ho sặc, khó thở Khẩn cấp Khẩn cấp 2 biến thể · 2 bước',
    );
    expect(html).toContain('TH21 Sốt');
    expect(html).toContain('Theo dõi');
    expect(render(body(view, true, true))).toContain('placeholder="Tìm theo tên hoặc mã"');
    // History is folded away: its title and size show, its rows (and notes) do not.
    expect(html).toContain('Lịch sử phiên bản');
    expect(html).toContain('2 phiên bản');
    expect(html).not.toContain('Bản thử');
  });

  it('the history table: published and replaced versions, the open one not repeated', () => {
    const history = (canApprove: boolean) =>
      render(<HistoryTable view={view} canApprove={canApprove} onRollback={() => undefined} />);
    const html = text(history(true));
    expect(html).toContain('fa_20261010_01 Đang dùng 2 Soạn: Minh Phạm · Duyệt: BS. Hà');
    expect(html).toContain('fa_20261001_01 Đã thay 1 Soạn: Linh Trần · Duyệt: BS. Hà');
    expect(html).toContain('Bản thử');
    // Only the replaced version can come back ("Dùng lại bản này" in its row menu).
    expect(canReuseVersion(view, view.history[1]!)).toBe(false);
    expect(canReuseVersion(view, view.history[2]!)).toBe(true);
    expect(history(true)).toContain('aria-label="Thao tác cho fa_20261001_01"');
    expect(history(true)).not.toContain('aria-label="Thao tác cho fa_20261010_01"');
    expect(history(false)).not.toContain('Thao tác cho');
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
    for (const label of ['Sửa', 'Gửi duyệt', 'Huỷ bản nháp', 'Duyệt & xuất bản', 'Trả lại']) {
      expect(viewer).not.toContain(label);
    }
    expect(draftActions('pending', false, false)).toEqual({ next: [], more: [] });
    expect(draftActions('draft', false, false)).toEqual({ next: [], more: [] });
    // Sửa (Vận hành) on a pending version: may edit, may not approve or send back.
    const editor = text(render(body(view, true, false), ['ops']));
    expect(editor).toContain('Tiếp tục sửa bản nháp');
    expect(editor).not.toContain('Duyệt & xuất bản');
    expect(editor).not.toContain('Trả lại');
    expect(editor).not.toContain('Gửi duyệt'); // already submitted
    expect(draftActions('pending', true, false)).toEqual({ next: [], more: [] });
    // A draft: Gửi duyệt as the next step, Huỷ bản nháp behind "⋯", nothing to approve yet.
    const draft: FirstAidView = { ...view, draft: { ...view.draft!, status: 'draft' } };
    const editorDraft = render(body(draft, true, false), ['ops']);
    expect(text(editorDraft)).toContain('Gửi duyệt');
    expect(editorDraft).toContain('aria-label="Thao tác khác"');
    expect(draftActions('draft', true, false)).toEqual({ next: ['submit'], more: ['discard'] });
    // Duyệt (chuyên gia) on a pending version: approve first, send back next to it.
    const approver = text(render(body(view, true, true), ['expert']));
    expect(approver).toContain('Duyệt & xuất bản Trả lại');
    expect(draftActions('pending', true, true)).toEqual({ next: ['approve', 'reject'], more: [] });
  });

  it('a situation page shows the phone preview of what the app shows', () => {
    const html = text(render(body(view, false, false, 'choking')));
    expect(html).toContain('Tất cả tình huống');
    expect(html).toContain('TH02 · Hóc dị vật');
    expect(html).toContain('Xem trước trên app');
    expect(html).toContain('Hóc dị vật Bé ho sặc, khó thở Dưới 1 tuổi Từ 1 tuổi');
    expect(html).toContain('Gọi 115 nếu bé không thở');
    expect(html).toContain('1 Vỗ lưng 5 lần Đặt bé nằm sấp trên cánh tay.');
    expect(html).toContain('Không được làm Móc họng bé');
    expect(html).toContain('Gọi 115');
    expect(render(body(view, false, false, 'choking'))).toContain(
      'https://example.test/hoc-di-vat_1a2b3c4d.webp',
    );
    // Read-only facts; ids and codes folded under "Nâng cao"; "Sửa" only for editors.
    expect(html).toContain('Nâng cao');
    expect(html).not.toContain('Sửa');
    expect(text(render(body(view, true, false, 'choking')))).toContain('Tiếp tục sửa bản nháp');
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
    // The approve button stays off until the review is there.
    expect(render(<ActDialog act="approve" requireReview {...props} />)).toMatch(
      /<button data-slot="button" data-variant="default"[^>]* disabled="">Duyệt &amp; xuất bản/,
    );
    const reject = text(render(<ActDialog act="reject" requireReview {...props} />));
    expect(reject).not.toContain('Người rà soát');
    // No reason (D-090): the dialog says what happens and confirms.
    expect(reject).not.toContain('Lý do');
    expect(reject).toContain('Bản quay về nháp để người soạn sửa tiếp.');
    // Where the server does not require it, the review is optional, said plainly.
    const optional = text(render(<ActDialog act="approve" requireReview={false} {...props} />));
    expect(optional).toContain('Rà soát chuyên môn (không bắt buộc)');
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
    // Not required: no review is fine; a half-filled one is not.
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

  const editor = (p: FirstAidPack, index: number, show: boolean) =>
    render(
      <IssuesContext.Provider value={{ issues: validatePack(p).issues, show }}>
        <LibraryContext.Provider value={{ images, canUpload: true, onUploaded: () => undefined }}>
          <SituationEditor
            pack={p}
            index={index}
            edit={() => undefined}
            idLocked
            variant={0}
            onVariant={() => undefined}
          />
        </LibraryContext.Provider>
      </IssuesContext.Provider>,
    );

  it('the editor shows vi and en side by side, and per-field errors once saving was tried', () => {
    const broken = structuredClone(pack);
    broken.situations[1]!.lead.en = '';
    const html = editor(broken, 1, true);
    expect(html).toContain('value="Sốt"');
    expect(html).toContain('value="Fever"');
    expect(text(html)).toContain('Tên tình huống Tiếng Việt 3/60 English 5/60');
    expect(text(html)).toContain('Mô tả ngắn');
    expect(text(html)).toContain('English 0/120 Bắt buộc.');
    expect(html).toContain('https://example.test/icon-fever_3c4d5e6f.webp');
    expect(text(html)).toContain('Bước 1');
    expect(text(html)).toContain('Thêm lưu ý');
    expect(text(editor(broken, 1, false))).not.toContain('Bắt buộc.');
    // Sections in working order; ids, codes and keywords folded under "Nâng cao".
    expect(text(html)).toMatch(
      /Thông tin chung.*Biến thể.*Các bước \(1\/8\).*Lưu ý \(0\/4\).*Nâng cao/,
    );
    expect(html).not.toContain('value="TH21"');
    // shadcn controls (D-063): no browser select, checkbox or arrow buttons left.
    expect(html).not.toMatch(/<select[^>]*class="field__input|class="icon-btn"/);
    expect(html).toContain('data-slot="select-trigger"');
    expect(html).toContain('data-slot="checkbox"');
  });

  it('long step lists fold to one line per step; a step or section with an issue opens', () => {
    const long = structuredClone(pack);
    const steps = long.situations[1]!.variants[0]!.steps;
    steps.push(
      { ...blankStep(), title: t('Lau mát', 'Sponge'), body: t('Bằng nước ấm.', 'Warm water.') },
      { ...blankStep(), title: t('Cho bé bú', 'Feed'), body: t('Bú nhiều hơn.', 'More often.') },
    );
    const folded = editor(long, 1, false);
    // Step 1 open; steps 2 and 3 show their title on one line only.
    expect(folded).toContain('value="Đo nhiệt độ"');
    expect(text(folded)).toContain('Cho bé bú');
    expect(folded).not.toContain('value="Cho bé bú"');
    expect(text(folded)).toContain('Mở tất cả');
    // An issue in step 3 and in a keyword: both open once saving was tried.
    long.situations[1]!.variants[0]!.steps[2]!.body.en = '';
    long.situations[1]!.keywords = [t('', 'heat')];
    const open = editor(long, 1, true);
    expect(open).toContain('value="Cho bé bú"');
    expect(open).toContain('value="heat"');
    expect(open).toContain('data-path="situations.1.keywords.0.vi"');
  });

  it('the issues summary names the place in words', () => {
    const intl = createIntl({ locale: 'vi', messages: messages.vi });
    const at = (path: Array<string | number>) =>
      issuePlace(intl, pack, { path, code: 'too_small', message: '' });
    expect(at(['situations', 0, 'variants', 0, 'steps', 0, 'count'])).toBe(
      'TH02 Hóc dị vật · Dưới 1 tuổi · Bước 1 · Số lần đếm (2–10)',
    );
    expect(at(['situations', 0, 'variants', 1, 'steps', 0, 'chips', 0, 'label', 'vi'])).toBe(
      'TH02 Hóc dị vật · Từ 1 tuổi · Bước 1 · Nhãn nhỏ 1 · Tiếng Việt',
    );
    expect(at(['situations', 1, 'variants', 0, 'callouts', 1, 'items', 2, 'en'])).toBe(
      'TH21 Sốt · Biến thể 1 · Lưu ý 2 · Ý 3 · English',
    );
    expect(at(['categories', 1, 'title', 'en'])).toBe('Sức khoẻ · Tên nhóm · English');
    expect(at(['emergencyNumber'])).toBe('Số gọi cấp cứu');
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

describe('Sơ cứu: list, settings and pictures', () => {
  const withLibrary = (node: ReactNode) => (
    <TooltipProvider>
      <LibraryContext.Provider value={{ images, canUpload: true, onUploaded: () => undefined }}>
        {node}
      </LibraryContext.Provider>
    </TooltipProvider>
  );

  it('while editing, the list adds situations and each row has its own menu', () => {
    const list = (editing: boolean) =>
      render(
        withLibrary(
          <SituationList
            pack={pack}
            editing={editing}
            edit={() => undefined}
            issues={validatePack({ ...pack, emergencyNumber: '' }).list}
            onOpen={() => undefined}
            onAdd={() => undefined}
            onRemove={() => undefined}
          />,
        ),
      );
    expect(text(list(true))).toContain('Thêm tình huống');
    expect(list(true)).toContain('aria-label="Thao tác cho Hóc dị vật"');
    expect(text(list(false))).not.toContain('Thêm tình huống');
    expect(list(false)).not.toContain('Thao tác cho');
  });

  it('the settings: read-only summary, and the editor with groups folded to one line', () => {
    const summary = text(render(withLibrary(<GeneralSummary pack={pack} />)));
    expect(summary).toContain('Số khẩn cấp 115');
    expect(summary).toContain('Khẩn cấp Lưới thẻ 1 tình huống');
    expect(summary).toContain('khó thở');
    const editor = render(withLibrary(<GeneralEditor pack={pack} edit={() => undefined} />));
    expect(editor).toContain('value="115"');
    expect(text(editor)).toContain('Khẩn cấp Lưới thẻ · Đỏ · 1 tình huống');
    expect(text(editor)).toContain('Thêm nhóm');
    expect(editor).toContain('value="khó thở"');
  });

  it('the picture library: a grid with how often each picture is used, upload behind a button', () => {
    const html = render(withLibrary(<Library pack={pack} canUpload />));
    expect(text(html)).toContain('Thư viện ảnh');
    expect(text(html)).toContain('5 ảnh');
    expect(text(html)).toContain('Tải ảnh lên');
    expect(text(html)).toContain('vo-lung_2b3c4d5e Dùng ở 1 tình huống');
    expect(html).toContain('https://example.test/sot_4d5e6f70.webp');
    expect(text(render(withLibrary(<Library pack={pack} canUpload={false} />)))).not.toContain(
      'Tải ảnh lên',
    );
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
