import {
  defaultFlags,
  defaultRhythmRules,
  interests,
  needs,
  referenceModelSchema,
  rhythmActSchema,
  rhythmContentSchema,
  rhythmDraftSchema,
  setRhythmRulesSchema,
  type ReferenceModel,
  type RhythmContent,
} from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider, createIntl } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, ApiError, type Api, type RhythmRulesView, type RhythmView } from '../src/api';
import { StaffContext } from '../src/context';
import { messages } from '../src/messages';
import { Sidebar } from '../src/Shell';
import { ActDialog, RhythmBody, RulesPanel, ruleGroups } from '../src/screens/Rhythm';
import { IssuesContext } from '../src/screens/FirstAidEditor';
import {
  ActivityEditor,
  StageEditor,
  blankActivity,
  blankStage,
  contentDraftFrom,
  forbiddenPhrases,
  referenceDraftFrom,
  rhythmActRequest,
  rhythmIssueText,
  rhythmReviewFrom,
  saveRhythmDraft,
  saveRhythmRules,
  sendRhythmAct,
  validateRhythmDraft,
  windowPreview,
  withNewVersions,
} from '../src/screens/RhythmEditor';
import { errorMessageId } from '../src/ui';
import { levelsForRoles, type StaffRole } from './fixtures';

// Nhịp lớn lên on the portal (PN01–PN04, D-073 #2): the two published documents on the Sơ cứu
// workflow and the rules in config/rhythm. Server-rendered, no network: callables go to a fake
// api that records them.

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
const tl = (vi: string[], en: string[]) => ({ vi, en });
const review = { reviewer: 'BS. Hà', credential: 'nhi khoa', reviewedOn: '2026-10-01' };

const reference: ReferenceModel = {
  version: 'ref_20261010_01',
  label: 'Wonder Weeks',
  stages: [
    {
      id: 'stage_01',
      number: 1,
      startOffsetDays: 21,
      endOffsetDays: 30,
      name: t('Giai đoạn 1 (Wonder Weeks)', 'Stage 1 (Wonder Weeks)'),
      signs: tl(
        [
          'Có thể cần được bế, dỗ nhiều hơn',
          'Một số bé không có thay đổi rõ — điều đó bình thường',
        ],
        ['May want more holding', 'Some babies show no clear change — that is normal'],
      ),
      skills: tl(['Nhìn theo khuôn mặt'], ['Follows faces']),
      activityIds: ['act_skin_to_skin'],
      notice: {
        title: t('Sắp đến giai đoạn 1', 'Stage 1 coming up'),
        body: t(
          'Vài ngày tới con có thể cần được dỗ nhiều hơn.',
          'Your baby may want more comfort.',
        ),
      },
    },
    {
      id: 'stage_02',
      number: 2,
      startOffsetDays: 49,
      endOffsetDays: 60,
      name: t('Giai đoạn 2', 'Stage 2'),
      signs: tl(['Có thể khó vào giấc hơn'], ['May take longer to settle']),
      skills: tl([], []),
      activityIds: [],
      notice: null,
    },
  ],
  sources: [{ label: 'The Wonder Weeks', url: 'https://www.thewonderweeks.com/' }],
  review: null,
  publishedAt: '2026-10-10T02:00:00Z',
};

const content: RhythmContent = {
  version: 'rc_20261010_01',
  activities: [
    {
      id: 'act_skin_to_skin',
      version: 1,
      status: 'published',
      title: t('Bế áp da trong phòng ánh sáng dịu', 'Skin-to-skin in a softly lit room'),
      summary: t('Áp da giúp nhiều bé dịu lại.', 'Skin-to-skin helps many babies settle.'),
      steps: tl(['Giảm đèn', 'Đặt bé áp lên ngực'], ['Dim the lights', 'Lay baby on your chest']),
      safety: t('Chỉ khi người lớn tỉnh táo.', 'Only while the adult is awake.'),
      durationMin: 10,
      ageDays: { from: 0, to: 91 },
      needs: ['soothing', 'bonding'],
      interests: ['moments'],
      timeOfDay: 'any',
      locales: ['vi', 'en'],
      regions: [],
      sources: [{ label: 'UNICEF UK', url: 'https://www.unicef.org.uk/babyfriendly/' }],
      review,
    },
    {
      id: 'act_white_noise',
      version: 2,
      status: 'draft',
      title: t('Tiếng ồn trắng trước giấc đêm', 'White noise before night sleep'),
      summary: t('Âm lượng thấp, đặt xa bé.', 'Low volume, away from the baby.'),
      steps: tl(['Bật âm lượng thấp'], []),
      safety: null,
      durationMin: 15,
      ageDays: { from: 0, to: 182 },
      needs: ['sleep'],
      interests: ['sleep'],
      timeOfDay: 'evening',
      locales: ['vi'],
      regions: ['VN'],
      sources: [],
      review: null,
    },
  ],
  ageCards: [
    {
      id: 'age_w01',
      version: 1,
      status: 'published',
      ageDays: { from: 0, to: 6 },
      title: t('Tuần đầu tiên', 'The first week'),
      body: t('Mỗi bé mỗi khác.', 'Every baby is different.'),
      tips: tl(['Nghỉ khi con ngủ'], ['Rest when the baby sleeps']),
      watchFor: tl([], []),
      interests: ['sleep'],
      sources: [],
      review: null,
    },
  ],
  health: {
    signs: [
      {
        id: 'fever_young',
        label: t('Sốt từ 38°C ở bé dưới 3 tháng', 'Fever in a baby under 3 months'),
        maxAgeDays: 90,
      },
      { id: 'breathing', label: t('Khó thở', 'Trouble breathing'), maxAgeDays: null },
    ],
    whileWaiting: tl(['Giữ bé ấm'], ['Keep the baby warm']),
    disclaimer: t('Không thay cho bác sĩ.', 'Not a substitute for a doctor.'),
    regions: [{ country: 'VN', emergencyNumber: '115' }],
    sources: [],
    review,
  },
  publishedAt: '2026-10-10T02:00:00Z',
};

const refDraftData = {
  ...referenceDraftFrom(reference),
  label: 'Wonder Weeks',
  stages: [
    ...reference.stages,
    {
      ...blankStage(reference.stages),
      name: t('Giai đoạn 3', 'Stage 3'),
      // A forbidden phrasing slipped in (brief p.13).
      signs: tl(['Bé chắc chắn sẽ quấy khóc'], ['Baby will definitely fuss']),
    },
  ],
};

const view: RhythmView = {
  reference: {
    current: reference,
    draft: {
      versionId: 'rv_00112233445566aa',
      status: 'pending',
      label: null,
      notes: 'Thêm giai đoạn 3',
      authorName: 'Minh Phạm',
      approverName: null,
      createdAt: '2026-10-11T01:00:00Z',
      updatedAt: '2026-10-11T02:00:00Z',
      approvedAt: null,
      rejection: { by: 'BS. Hà', reason: 'Thiếu nguồn' },
      review: null,
      stages: 3,
      data: refDraftData,
    },
    history: [
      {
        versionId: 'rv_00112233445566aa',
        status: 'pending',
        label: null,
        notes: 'Thêm giai đoạn 3',
        authorName: 'Minh Phạm',
        approverName: null,
        createdAt: '2026-10-11T01:00:00Z',
        updatedAt: '2026-10-11T02:00:00Z',
        approvedAt: null,
        rejection: null,
        review: null,
        stages: 3,
      },
      {
        versionId: 'rv_aabbccddeeff0011',
        status: 'published',
        label: 'ref_20261010_01',
        notes: 'Bản đầu',
        authorName: 'Minh Phạm',
        approverName: 'Linh Trần',
        createdAt: '2026-10-09T01:00:00Z',
        updatedAt: '2026-10-10T02:00:00Z',
        approvedAt: '2026-10-10T02:00:00Z',
        rejection: null,
        review: null,
        stages: 2,
      },
      {
        versionId: 'rv_aabbccddeeff0022',
        status: 'retired',
        label: 'ref_20261001_01',
        notes: 'Bản thử',
        authorName: 'Minh Phạm',
        approverName: 'BS. Hà',
        createdAt: '2026-09-30T01:00:00Z',
        updatedAt: '2026-10-01T02:00:00Z',
        approvedAt: '2026-10-01T02:00:00Z',
        rejection: null,
        review,
        stages: 1,
      },
      {
        versionId: 'rv_aabbccddeeff0033',
        status: 'discarded',
        label: null,
        notes: 'Bỏ',
        authorName: 'Minh Phạm',
        approverName: null,
        createdAt: '2026-09-29T01:00:00Z',
        updatedAt: '2026-09-29T02:00:00Z',
        approvedAt: null,
        rejection: null,
        review: null,
        stages: 1,
      },
    ],
  },
  content: {
    current: content,
    draft: null,
    history: [
      {
        versionId: 'rv_ccddeeff00112233',
        status: 'published',
        label: 'rc_20261010_01',
        notes: '',
        authorName: 'Minh Phạm',
        approverName: 'Linh Trần',
        createdAt: '2026-10-09T01:00:00Z',
        updatedAt: '2026-10-10T02:00:00Z',
        approvedAt: '2026-10-10T02:00:00Z',
        rejection: null,
        review: null,
        activities: 2,
        ageCards: 1,
      },
    ],
  },
  requireReview: true,
};

const rulesView: RhythmRulesView = {
  rules: { ...defaultRhythmRules, version: 'rules-v1' },
  stored: true,
  updatedAt: '2026-10-12T03:00:00Z',
  updatedByName: 'Linh Trần',
};

const body = (
  v: RhythmView,
  can: { edit: boolean; approve: boolean; rules?: boolean; editRules?: boolean },
  tab: 'reference' | 'content' | 'rules' = 'reference',
) => (
  <RhythmBody
    view={v}
    canEdit={can.edit}
    canApprove={can.approve}
    canViewRules={can.rules ?? true}
    canEditRules={can.editRules ?? false}
    onChanged={() => undefined}
    initialTab={tab}
    rules={rulesView}
    flags={{
      ...defaultFlags,
      rhythm: { enabled: true, scope: 'percent', percent: 25, notice: null },
    }}
    today="2026-09-21"
  />
);

describe('Nhịp lớn lên: fixtures and messages', () => {
  it('the fixtures are what the app and the server accept', () => {
    expect(referenceModelSchema.safeParse(reference).success).toBe(true);
    expect(rhythmContentSchema.safeParse(content).success).toBe(true);
    expect(
      rhythmDraftSchema.safeParse({ doc: 'reference', data: refDraftData, notes: '' }).success,
    ).toBe(true);
  });

  it('every dynamic id exists in both catalogs (D-012)', () => {
    const ids = [
      'nav.rhythm',
      'error.invalid-content',
      ...['reference', 'content', 'rules'].map((x) => `rhythm.tab.${x}`),
      ...['draft', 'pending', 'published', 'retired', 'discarded'].map((s) => `rhythm.status.${s}`),
      ...['submit', 'approve', 'reject', 'discard', 'rollback'].flatMap((a) => [
        `rhythm.act.${a}`,
        `rhythm.confirm.${a}`,
        `rhythm.confirm.${a}.note`,
      ]),
      ...['reference', 'content'].flatMap((d) => [
        `rhythm.history.${d}`,
        `rhythm.openVersion.${d}`,
        `rhythm.saveTitle.${d}`,
        ...['draft', 'submit', 'approve', 'reject', 'discard', 'rollback'].map(
          (a) => `audit.content.rhythm.${d}.${a}`,
        ),
      ]),
      'audit.features.rhythm.rules',
      ...needs.map((n) => `rhythm.need.${n}`),
      ...interests.map((n) => `rhythm.interest.${n}`),
      ...['any', 'evening', 'day'].map((x) => `rhythm.timeOfDay.${x}`),
      ...['draft', 'published', 'retired'].map((x) => `rhythm.itemStatus.${x}`),
      ...['name', 'signs', 'skills', 'notice'].map((x) => `rhythm.hitField.${x}`),
      ...['calc', 'noDue', 'estimated', 'change', 'overlap'].flatMap((x) => [
        `rhythm.how.${x}`,
        `rhythm.how.${x}.value`,
      ]),
      ...['activity', 'ageCard'].map((x) => `rhythm.back.${x}`),
      ...['activities', 'ageCards', 'health'].map((x) => `rhythm.sub.${x}`),
      ...['baseline', 'validDay', 'change', 'repeat'].flatMap((x) => [
        `rhythm.rules.summary.${x}`,
        `rhythm.rules.summary.${x}.value`,
      ]),
      ...ruleGroups.flatMap((g) => [
        `rhythm.rules.group.${g.id}`,
        ...g.keys.flatMap((k) => [`rhythm.rule.${k}`, `rhythm.rule.${k}.help`]),
      ]),
      ...['minutes', 'days'].map((u) => `rhythm.unit.${u}`),
    ];
    for (const id of ids) {
      expect(messages.vi[id], id).toBeTruthy();
      expect(messages.en[id], id).toBeTruthy();
    }
    // Every rule in the contract has a field.
    expect(ruleGroups.flatMap((g) => g.keys).sort()).toEqual(
      Object.keys(defaultRhythmRules)
        .filter((k) => k !== 'version')
        .sort(),
    );
    expect(errorMessageId(new ApiError('failed-precondition', 'invalid-content'))).toBe(
      'error.invalid-content',
    );
  });
});

describe('Nhịp lớn lên: versions and workflow (PN01)', () => {
  it('renders the published model, the open draft and the history from the server', async () => {
    const { api, calls } = fakeApi({ staffRhythm: view });
    const data = await api.call<RhythmView>('staffRhythm', {});
    expect(calls[0]!.name).toBe('staffRhythm');
    const html = text(render(body(data, { edit: true, approve: true })));
    expect(html).toContain('Mô hình tham khảo Hoạt động & thẻ theo tuổi Quy tắc');
    expect(html).toContain('● Đang phát hành · ref_20261010_01');
    expect(html).toContain('Xuất bản 09:00 10/10/2026');
    // Nobody qualified signed the live model off yet (D-073 #2).
    expect(html).toContain('Bản nháp kỹ thuật · chờ chuyên môn duyệt');
    expect(html).toContain('Bản nháp · chờ duyệt Phiên bản mô hình đang soạn');
    expect(html).toContain('Soạn: Minh Phạm');
    expect(html).toContain('3 giai đoạn');
    expect(html).toContain('BS. Hà trả lại: “Thiếu nguồn”');
    expect(html).toContain('Thêm giai đoạn 3');
    // The draft is shown: three stages, the window for the sample due date (PN02 21/09 + 21..30).
    expect(html).toContain('Giai đoạn · 3/30');
    expect(html).toContain('+21 → +30 ngày 12/10/2026 – 21/10/2026');
    expect(html).toContain('Giai đoạn 3');
    // History (PN01): status, reviewer, languages; discarded versions are not listed.
    expect(html).toContain('Danh sách phiên bản mô hình');
    expect(html).toContain(
      'ref_20261001_01 Đã thay thế 1 giai đoạn BS. Hà (nhi khoa) · 01/10/2026 VI · EN',
    );
    expect(html).toContain(
      'ref_20261010_01 Đang phát hành 2 giai đoạn Chưa duyệt chuyên môn VI · EN',
    );
    expect(html).not.toContain('Bỏ');
    // Only the replaced version can come back; the approver sees the pending actions.
    expect(html.match(/Dùng lại bản này/g)).toHaveLength(1);
    expect(html).toContain('Trả lại');
    expect(html).toContain('Duyệt & xuất bản');
    expect(html).toContain('Sửa bản nháp');
    // PN01 kill switches and how the app counts.
    expect(html).toContain('Công tắc khẩn cấp');
    expect(html).toContain('Nhịp lớn lên (lịch tham khảo & check-in) Đang bật Mở dần · 25%');
    expect(html).toContain('Gợi ý theo nhu cầu (nhóm A) Đang tắt');
    expect(html).toContain('không dùng ngày sinh thay thế');
  });

  it('the content tab lists activities and age cards with status, review and languages', () => {
    const html = text(render(body(view, { edit: true, approve: true }, 'content')));
    expect(html).toContain('● Đang phát hành · rc_20261010_01');
    expect(html).toContain('2/4 mục đã duyệt chuyên môn');
    expect(html).toContain('Thư viện hoạt động · 2');
    expect(html).toContain(
      'Bế áp da trong phòng ánh sáng dịu 10 phút · act_skin_to_skin · v1 0–91 ngày (~0–3 tháng) Cần được dỗ · Gắn kết Phát hành BS. Hà (nhi khoa) · 01/10/2026 VI · EN',
    );
    expect(html).toContain(
      'Tiếng ồn trắng trước giấc đêm 15 phút · act_white_noise · v2 0–182 ngày (~0–6 tháng) Ngủ Nháp Chờ chuyên môn VI',
    );
    expect(html).toContain('+ Tạo phiên bản mới');
    expect(html).toContain('Danh sách phiên bản nội dung');
    expect(html).toContain('rc_20261010_01 Đang phát hành 2 hoạt động · 1 thẻ theo tuổi');
  });

  it('a viewer sees everything read-only', () => {
    // Hỗ trợ: Nội dung "Xem", no Tính năng.
    const viewer = text(
      render(body(view, { edit: false, approve: false, rules: false }), ['support']),
    );
    expect(viewer).toContain('● Đang phát hành · ref_20261010_01');
    for (const label of [
      'Tạo phiên bản mới',
      'Sửa bản nháp',
      'Gửi duyệt',
      'Huỷ nháp',
      'Duyệt & xuất bản',
      'Trả lại',
      'Dùng lại bản này',
      '+ Thêm giai đoạn',
    ]) {
      expect(viewer, label).not.toContain(label);
    }
    expect(viewer).toContain('Cần quyền “Tính năng · Xem” để thấy trạng thái công tắc.');
    const contentViewer = text(
      render(body(view, { edit: false, approve: false }, 'content'), ['support']),
    );
    expect(contentViewer).not.toContain('Tạo phiên bản mới');
    expect(contentViewer).not.toContain('Thêm hoạt động');
    // No Tính năng: the rules tab says why instead of loading.
    const rules = text(
      render(body(view, { edit: false, approve: false, rules: false }, 'rules'), ['support']),
    );
    expect(rules).toContain('Cần quyền “Tính năng · Xem” để xem quy tắc.');
    expect(rules).toContain('Xếp hạng gợi ý');
    // An editor on a draft: Gửi duyệt and Huỷ nháp, nothing to approve.
    const draft: RhythmView = {
      ...view,
      reference: { ...view.reference, draft: { ...view.reference.draft!, status: 'draft' } },
    };
    const editor = text(render(body(draft, { edit: true, approve: false }), ['ops']));
    expect(editor).toContain('Gửi duyệt');
    expect(editor).toContain('Huỷ nháp');
    expect(editor).not.toContain('Duyệt & xuất bản');
    expect(editor).not.toContain('Dùng lại bản này');
  });

  it('flags stage texts that promise or count down', () => {
    const hits = forbiddenPhrases(refDraftData.stages);
    expect(hits.map((h) => [h.stage, h.field, h.lang, h.phrase])).toEqual([
      [2, 'signs', 'vi', 'chắc chắn'],
      [2, 'signs', 'en', 'definitely'],
    ]);
    const countdown = structuredClone(reference.stages[0]!);
    countdown.signs.vi = ['Còn 3 ngày hết khủng hoảng', 'Bé chậm hơn chuẩn'];
    expect(forbiddenPhrases([countdown]).map((h) => h.phrase)).toEqual([
      'Còn 3 ngày',
      'chậm hơn chuẩn',
    ]);
    expect(forbiddenPhrases(reference.stages)).toEqual([]);
    // NFD input (macOS) is caught too.
    countdown.signs.vi = ['Chắc chắn'.normalize('NFD')];
    expect(forbiddenPhrases([countdown])).toHaveLength(1);

    const html = text(render(body(view, { edit: false, approve: false })));
    expect(html).toContain('Không được viết');
    expect(html).toContain('Có 2 chỗ cần viết lại:');
    expect(html).toContain(
      'Giai đoạn 3 · Dấu hiệu (VI): “Bé chắc chắn sẽ quấy khóc” · có “chắc chắn”',
    );
    expect(html).toContain('2 cụm từ không được viết');
    // The live model has none.
    const live: RhythmView = { ...view, reference: { ...view.reference, draft: null } };
    expect(text(render(body(live, { edit: false, approve: false })))).not.toContain('cần viết lại');
  });
});

describe('Nhịp lớn lên: drafts', () => {
  it('the reference draft sent on save matches the schema', async () => {
    const { api, calls } = fakeApi({ staffRhythmDraft: { versionId: 'rv_0011223344556677' } });
    // From the live model: no version, no publishedAt, not reviewed yet.
    const draft = referenceDraftFrom({ ...reference, review });
    expect(draft).not.toHaveProperty('version');
    expect(draft).not.toHaveProperty('publishedAt');
    expect(draft.review).toBeNull();
    const added = blankStage(draft.stages);
    expect(added.id).toBe('stage_03');
    expect(added.number).toBe(3);
    expect(added.startOffsetDays).toBe(67);
    added.name = t('Giai đoạn 3', 'Stage 3');
    added.signs = tl(['Có thể bám mẹ hơn'], ['May be clingier']);
    added.activityIds = ['act_skin_to_skin'];
    draft.stages.push(added);

    const res = await saveRhythmDraft(api, 'reference', draft, '  Thêm giai đoạn 3  ');
    expect(res).toEqual({ ok: true, versionId: 'rv_0011223344556677' });
    expect(calls).toHaveLength(1);
    expect(calls[0]!.name).toBe('staffRhythmDraft');
    const sent = calls[0]!.data as { doc: string; data: { stages: unknown[] }; notes: string };
    expect(rhythmDraftSchema.safeParse(sent).success).toBe(true);
    expect(sent.doc).toBe('reference');
    expect(sent.notes).toBe('Thêm giai đoạn 3');
    expect(sent.data.stages).toHaveLength(3);
    expect(sent.data).not.toHaveProperty('version');
  });

  it('the content draft bumps edited items and clears their old sign-off', async () => {
    const { api, calls } = fakeApi({ staffRhythmDraft: { versionId: 'rv_0011223344556677' } });
    const draft = contentDraftFrom(content);
    draft.activities[0]!.summary.vi = 'Áp da kề da giúp nhiều bé dịu lại.';
    draft.activities[1]!.status = 'published'; // status only: same text, same version
    const added = blankActivity(draft.activities);
    added.title = t('Hát nhẹ khi bé tỉnh', 'Sing softly while awake');
    added.summary = t('Giọng quen giúp bé dịu.', 'A familiar voice soothes.');
    added.steps = tl(['Hát chậm'], ['Sing slowly']);
    added.needs = ['play', 'bonding'];
    draft.activities.push(added);
    const next = withNewVersions(draft, content);
    expect(next.activities[0]!.version).toBe(2);
    expect(next.activities[0]!.review).toBeNull();
    expect(next.activities[1]!.version).toBe(2);
    expect(next.activities[2]!.id).toBe('act_new_01');
    expect(next.health.review).toEqual(review);

    const res = await saveRhythmDraft(api, 'content', next, '');
    expect(res.ok).toBe(true);
    const sent = calls[0]!.data as { doc: string; data: RhythmContent };
    expect(rhythmDraftSchema.safeParse(sent).success).toBe(true);
    expect(sent.doc).toBe('content');
    expect(sent.data.activities).toHaveLength(3);
    expect(sent.data).not.toHaveProperty('version');
  });

  it('an invalid draft is not sent, and each problem has a field and a message', async () => {
    const { api, calls } = fakeApi({ staffRhythmDraft: { versionId: 'rv_0011223344556677' } });
    const draft = referenceDraftFrom(reference);
    draft.stages[0]!.notice!.title.vi = 'Teddy sắp đến giai đoạn 1 (Wonder Weeks)!'; // 41
    draft.stages[1]!.endOffsetDays = 40; // before the start (49)
    draft.stages[1]!.id = 'stage_01'; // used twice
    draft.stages[1]!.name.en = '';
    draft.sources[0]!.url = 'not a link';
    const res = await saveRhythmDraft(api, 'reference', draft, '');
    expect(res.ok).toBe(false);
    expect(calls).toHaveLength(0);
    const check = validateRhythmDraft('reference', draft);
    const intl = createIntl({ locale: 'vi', messages: messages.vi });
    const say = (key: string) => rhythmIssueText(intl, check.issues.get(key)!);
    expect(say('stages.0.notice.title.vi')).toBe('Tối đa 40 ký tự.');
    expect(say('stages.1')).toBe('Ngày kết thúc phải từ ngày bắt đầu trở đi.');
    expect(say('stages.1.id')).toBe('Mã này đã được dùng.');
    expect(say('stages.1.name.en')).toBe('Bắt buộc.');
    expect(say('sources.0.url')).toBe('Nhập một đường dẫn đầy đủ (https://…).');
    // Content: an activity needs at least one need, and a valid age range.
    const c = contentDraftFrom(content);
    c.activities[0]!.needs = [];
    c.activities[1]!.ageDays = { from: 30, to: 10 };
    const cc = validateRhythmDraft('content', c);
    expect(rhythmIssueText(intl, cc.issues.get('activities.0.needs')!)).toBe('Cần ít nhất 1 mục.');
    expect(rhythmIssueText(intl, cc.issues.get('activities.1')!)).toBe(
      'Tuổi “đến” phải từ tuổi “từ” trở lên.',
    );
  });

  it('the stage editor shows the window preview, counters and VI/EN tabs', () => {
    const draft = referenceDraftFrom(reference);
    draft.stages[0]!.notice!.title.vi = 'Teddy sắp đến giai đoạn 1 (Wonder Weeks)!';
    const raw = render(
      <IssuesContext.Provider
        value={{ issues: validateRhythmDraft('reference', draft).issues, show: true }}
      >
        <StageEditor
          model={draft}
          index={0}
          edit={() => undefined}
          idLocked
          dueDate="2026-09-21"
          activities={[{ id: 'act_skin_to_skin', title: 'Bế áp da', durationMin: 10 }]}
        />
      </IssuesContext.Provider>,
    );
    const html = text(raw);
    expect(html).toContain('Xem trước với dự sinh 21/09/2026 → giai đoạn 12/10/2026 – 21/10/2026.');
    expect(html).toContain('startOffsetDays');
    expect(html).toContain('Tiếng Việt • English');
    expect(raw).toContain('value="Giai đoạn 1 (Wonder Weeks)"');
    expect(html).toContain('Có thể cần được bế, dỗ nhiều hơn');
    expect(html).toContain('Tiêu đề (≤40 ký tự) 41/40');
    expect(html).toContain('Tối đa 40 ký tự.');
    expect(html).toContain('Nội dung (≤90 ký tự) 46/90');
    expect(html).toContain('Hoạt động gắn kèm · 1/8');
    expect(html).toContain('Bế áp da · 10 phút');
    expect(html).toContain('Đã phát hành nên không đổi mã được');
    expect(windowPreview('2026-09-21', { startOffsetDays: 21, endOffsetDays: 30 })).toEqual({
      start: '2026-10-12',
      end: '2026-10-21',
    });
    expect(windowPreview('', { startOffsetDays: 21, endOffsetDays: 30 })).toBeNull();
  });

  it('the activity form has vi and en side by side, ages, needs and sources', () => {
    const raw = render(
      <ActivityEditor
        data={contentDraftFrom(content)}
        index={1}
        edit={() => undefined}
        idLocked={false}
      />,
    );
    const html = text(raw);
    expect(raw).toContain('value="Tiếng ồn trắng trước giấc đêm"');
    expect(raw).toContain('value="White noise before night sleep"');
    expect(html).toContain('Các bước Tiếng Việt 1/12');
    expect(html).toContain('English 0/12');
    expect(html).toContain('Cần được dỗ');
    expect(html).toContain('Khoảnh khắc');
    expect(html).toContain('Thời điểm phù hợp');
    expect(html).toContain('≈ 0–6 tháng');
    expect(raw).toContain('value="VN"');
    expect(html).toContain('+ Thêm nguồn');
  });
});

describe('Nhịp lớn lên: approve, reject, roll back', () => {
  const id = 'rv_00112233445566aa';
  const filled = { reviewer: ' BS. Hà ', credential: 'nhi khoa', reviewedOn: '2026-10-12' };
  const empty = { reviewer: '', credential: '', reviewedOn: '2026-10-12' };

  it('approve sends the review with the reason; prod refuses it without one', async () => {
    const { api, calls } = fakeApi({ staffRhythmAct: { status: 'published', version: 'ref_x' } });
    expect(await sendRhythmAct(api, 'reference', id, 'approve', 'Đã rà soát', empty, true)).toEqual(
      {
        ok: false,
      },
    );
    expect(await sendRhythmAct(api, 'reference', id, 'approve', 'ok', filled, true)).toEqual({
      ok: false,
    });
    expect(calls).toHaveLength(0);
    const res = await sendRhythmAct(api, 'reference', id, 'approve', ' Đã rà soát ', filled, true);
    expect(res).toEqual({ ok: true, status: 'published' });
    expect(calls[0]).toEqual({
      name: 'staffRhythmAct',
      data: {
        doc: 'reference',
        versionId: id,
        action: 'approve',
        reason: 'Đã rà soát',
        review: { reviewer: 'BS. Hà', credential: 'nhi khoa', reviewedOn: '2026-10-12' },
      },
    });
    expect(rhythmActSchema.safeParse(calls[0]!.data).success).toBe(true);
    // Dev: approving without a reviewer is allowed (review null), a half-filled one is not.
    expect(rhythmActRequest('content', id, 'approve', 'Thử trên dev', empty, false)?.review).toBe(
      null,
    );
    expect(
      rhythmActRequest('content', id, 'approve', 'Thử', { ...empty, reviewer: 'BS. Hà' }, false),
    ).toBeNull();
    expect(rhythmReviewFrom({ ...filled, reviewedOn: '' }, true).ok).toBe(false);
  });

  it('reject, discard, submit and rollback send the act with the reason and no review', async () => {
    const { api, calls } = fakeApi({ staffRhythmAct: { status: 'draft' } });
    await sendRhythmAct(api, 'content', id, 'reject', 'Thiếu nguồn', filled, true);
    await sendRhythmAct(
      api,
      'reference',
      'rv_aabbccddeeff0022',
      'rollback',
      'Quay lại',
      null,
      true,
    );
    await sendRhythmAct(api, 'reference', id, 'submit', 'Xin duyệt', null, true);
    await sendRhythmAct(api, 'reference', id, 'discard', 'Không cần', null, false);
    expect(calls.map((c) => c.data)).toEqual([
      { doc: 'content', versionId: id, action: 'reject', reason: 'Thiếu nguồn', review: null },
      {
        doc: 'reference',
        versionId: 'rv_aabbccddeeff0022',
        action: 'rollback',
        reason: 'Quay lại',
        review: null,
      },
      { doc: 'reference', versionId: id, action: 'submit', reason: 'Xin duyệt', review: null },
      { doc: 'reference', versionId: id, action: 'discard', reason: 'Không cần', review: null },
    ]);
    for (const c of calls) expect(rhythmActSchema.safeParse(c.data).success).toBe(true);
    // A bad version id or a short reason never leaves the browser.
    expect(rhythmActRequest('reference', 'fv_123', 'reject', 'Thiếu nguồn', null, true)).toBeNull();
    expect(rhythmActRequest('reference', id, 'reject', 'no', null, true)).toBeNull();
  });

  it('the approve dialog asks for reviewer, credential and date on prod', () => {
    const props = { doc: 'reference' as const, versionId: id, onClose: () => {}, onDone: () => {} };
    const html = text(render(<ActDialog act="approve" requireReview {...props} />));
    expect(html).toContain('Rà soát chuyên môn (bắt buộc)');
    expect(html).toContain('Người rà soát');
    expect(html).toContain('Chuyên môn (ví dụ: bác sĩ nhi khoa)');
    expect(html).toContain('Ngày rà soát');
    expect(render(<ActDialog act="approve" requireReview {...props} />)).toMatch(
      /<button data-slot="button" data-variant="default"[^>]* disabled="">Duyệt &amp; xuất bản/,
    );
    const dev = text(render(<ActDialog act="approve" requireReview={false} {...props} />));
    expect(dev).toContain('Rà soát chuyên môn (tuỳ chọn trên dev)');
    const reject = text(render(<ActDialog act="reject" requireReview {...props} />));
    expect(reject).not.toContain('Người rà soát');
    expect(reject).toContain('Bản quay về nháp');
  });
});

describe('Nhịp lớn lên: rules (PN04)', () => {
  it('saving sends the values and the reason', async () => {
    const { api, calls } = fakeApi({ staffSetRhythmRules: { rules: rulesView.rules } });
    const next = {
      ...rulesView.rules,
      version: 'rules-v2',
      maxGapMinutes: 300,
      minDeltaShare: 0.2,
    };
    const res = await saveRhythmRules(api, next, '  Ít ngày bị loại hơn  ');
    expect(res.ok).toBe(true);
    expect(calls).toEqual([
      { name: 'staffSetRhythmRules', data: { rules: next, reason: 'Ít ngày bị loại hơn' } },
    ]);
    expect(setRhythmRulesSchema.safeParse(calls[0]!.data).success).toBe(true);
    // A short reason or inconsistent windows are not sent.
    expect((await saveRhythmRules(api, next, 'ok')).ok).toBe(false);
    expect(
      (
        await saveRhythmRules(
          api,
          { ...next, baselineMinDays: 9, baselineMaxDays: 7 },
          'Thử ngưỡng',
        )
      ).ok,
    ).toBe(false);
    expect((await saveRhythmRules(api, { ...next, maxGapMinutes: 30 }, 'Thử ngưỡng')).ok).toBe(
      false,
    );
    expect(calls).toHaveLength(1);
  });

  it('explains every threshold; editable only with Tính năng · Sửa', () => {
    const editor = render(<RulesPanel view={rulesView} canEdit onSaved={() => {}} />, ['eng']);
    expect(editor).toContain('type="number"');
    expect(editor).toContain('value="360"');
    expect(text(editor)).toContain('Lưu quy tắc…');
    expect(text(editor)).toContain(
      'Ngày có một quãng dài hơn số phút này mà không ghi gì sẽ không được tính (D-073 #1).',
    );
    expect(text(editor)).toContain(
      '7 ngày hợp lệ gần nhất trong 14 ngày trước 3 ngày đang so sánh · tối thiểu 5 ngày',
    );
    expect(text(editor)).toContain(
      '|chênh lệch| ≥ max(60 phút, 15% baseline) và cùng chiều ≥ 2 ngày',
    );
    expect(text(editor)).toContain('Lưu bởi Linh Trần');
    const viewer = render(<RulesPanel view={rulesView} canEdit={false} onSaved={() => {}} />, [
      'ops',
    ]);
    expect(viewer).not.toContain('type="number"');
    expect(text(viewer)).not.toContain('Lưu quy tắc');
    expect(text(viewer)).toContain('Bạn chỉ xem được. Cần quyền “Tính năng · Sửa” để đổi quy tắc.');
    expect(text(viewer)).toContain('Quãng trống tối đa trong ngày (phút) 360 phút');
    expect(text(viewer)).toContain('Chênh lệch tối thiểu (tỉ lệ của mốc) 15%');
    const unsaved = text(
      render(
        <RulesPanel view={{ ...rulesView, stored: false }} canEdit={false} onSaved={() => {}} />,
      ),
    );
    expect(unsaved).toContain('Đang dùng mặc định trong mã');
    // The rules tab also shows the ranking and the health routing, read-only.
    const tab = text(
      render(body(view, { edit: false, approve: false, rules: true }, 'rules'), ['ops']),
    );
    expect(tab).toContain(
      '3×khớp nhu cầu + 2×khớp sở thích + 1×từng có ích − 2×đã xem gần đây − 4×không phù hợp',
    );
    expect(tab).toContain('VN (115)');
    expect(tab).toContain('Sốt từ 38°C ở bé dưới 3 tháng · Khó thở');
  });
});

describe('Nhịp lớn lên: the sidebar', () => {
  it('NỘI DUNG › Nhịp lớn lên for every role that may view content', () => {
    const sidebar = (roles: StaffRole[]) =>
      text(
        render(
          <Sidebar
            route="rhythm"
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
      expect(sidebar([role]), role).toContain('NỘI DUNG Sơ cứu Nhịp lớn lên Mẫu kỷ niệm');
    }
    expect(sidebar(['analyst'])).not.toContain('Nhịp lớn lên');
    expect(sidebar(['eng'])).not.toContain('Nhịp lớn lên');
  });
});
