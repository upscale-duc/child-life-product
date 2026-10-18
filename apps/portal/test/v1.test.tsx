import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider, createIntl } from 'react-intl';
import { describe, expect, it } from 'vitest';
import {
  ApiContext,
  type AnalyticsFeatures,
  type AnalyticsGrowth,
  type Api,
  type FamilyDetail,
  type FamilyList,
  type JobRow,
  type StaffTeam,
} from '../src/api';
import { StaffContext } from '../src/context';
import { messages } from '../src/messages';
import { FeaturesView, GrowthView, analyticsCsv } from '../src/screens/Analytics';
import { FamilyDetailView, FamilyListView, TransferDialog } from '../src/screens/Families';
import { RerunDialog } from '../src/screens/Jobs';
import {
  BottleTable,
  CsvError,
  GrowthTable,
  ReferenceFor,
  VaccineTable,
  bandLabel,
} from '../src/screens/Reference';
import {
  MemberTable,
  RoleMatrix,
  functionGroups,
  maxLevel,
  memberActions,
  scopeOf,
} from '../src/screens/Staff';
import { Sidebar } from '../src/Shell';
import {
  bottleQuickPicksV1,
  levelsForRoles,
  referenceV1,
  staffFunctions,
  staffRoleTemplates,
  staffRoles,
  type StaffRole,
} from './fixtures';

// Portal v1.0 (S15b): staff & permissions, families, analytics, reference data, the two-person
// re-run and the permission-driven sidebar — server-rendered, no network.
const now = new Date('2026-10-11T03:00:00Z'); // 10:00 in Vietnam
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

describe('dynamic message ids (D-012)', () => {
  it('every v1.0 id family exists in both catalogs', () => {
    const ids = [
      ...[
        'mother',
        'father',
        'grandmother',
        'grandfather',
        'nanny',
        'relative',
        'friend',
        'other',
      ].map((r) => `relation.${r}`),
      ...['owner', 'coParent', 'caregiver', 'relative'].map((r) => `familyRole.${r}`),
      ...['ios', 'android'].map((p) => `platform.${p}`),
      ...['all', 'ios', 'android', 'both'].map((p) => `families.platform.${p}`),
      ...['all', 'over80', 'expanded'].map((p) => `families.storage.${p}`),
      ...['active', 'low'].map((a) => `families.activity.${a}`),
      ...['pending', 'expired'].map((a) => `families.invite.${a}`),
      ...['vi', 'en'].map((l) => `families.lang.${l}`),
      ...[1, 2, 3].map((n) => `families.transferStep${n}`),
      ...[
        'feeding',
        'sleep',
        'diaper',
        'pump',
        'growth',
        'vaccines',
        'memories',
        'stories',
        'reminders',
      ].flatMap((f) => [`analytics.feature.${f}`, `analytics.feature.${f}.note`]),
      ...['dau', 'wau', 'mau'].map((s) => `analytics.series.${s}`),
      ...['invite', 'website', 'store'].map((c) => `analytics.channel.${c}`),
      ...['all', 'ios', 'android'].map((p) => `analytics.platform.${p}`),
      ...['photo', 'video', 'other', 'base', 'expanded', 'over80'].map(
        (s) => `analytics.storage.${s}`,
      ),
      ...['weight', 'length', 'bottle', 'vaccines'].map((t) => `reference.tab.${t}`),
      ...['draft', 'pending', 'published', 'retired', 'discarded'].map(
        (s) => `reference.status.${s}`,
      ),
      ...['submit', 'approve', 'reject', 'discard', 'rollback'].flatMap((a) => [
        `reference.act.${a}`,
        `reference.confirm.${a}`,
        `reference.confirm.${a}.note`,
      ]),
      ...['boy', 'girl'].map((s) => `reference.sex.${s}`),
      ...['week', 'month'].flatMap((u) => [
        `reference.unit.${u}`,
        `reference.rows.${u}`,
        `reference.age.${u}`,
      ]),
      ...['normal', 'below', 'above'].map((b) => `reference.band.${b}`),
      ...['all', 'epi', 'service', 'hospital', 'choice'].map((p) => `reference.programme.${p}`),
      ...['growth', 'bottle'].flatMap((k) => [
        `reference.csvTitle.${k}`,
        `reference.csvColumns.${k}`,
      ]),
      ...staffRoles.map((r) => `role.${r}`),
      ...staffFunctions.map((f) => `fn.${f}`),
    ];
    for (const id of ids) {
      expect(messages.vi[id], id).toBeTruthy();
      expect(messages.en[id], id).toBeTruthy();
    }
    // English plural forms compile.
    const intl = createIntl({ locale: 'en', messages: messages.en });
    expect(intl.formatMessage({ id: 'families.people' }, { n: 1 })).toBe('1 person');
  });
});

const team: StaffTeam = {
  members: [
    {
      uid: 'u1',
      name: 'Minh Phạm',
      email: 'minh@childlife.vn',
      roles: ['owner'],
      status: 'active',
      accessUntil: null,
      lastSeenAt: '2026-10-11T01:00:00Z',
      createdAt: null,
    },
    {
      uid: 'u2',
      name: 'Thảo Lê',
      email: 'thao@gmail.com',
      roles: ['support'],
      status: 'paused',
      accessUntil: '2026-11-10T16:59:59Z',
      lastSeenAt: null,
      createdAt: null,
    },
    {
      uid: 'u3',
      name: 'Mai Hồ',
      email: 'mai@x.vn',
      roles: ['r_0123456789ab'],
      status: 'active',
      accessUntil: null,
      lastSeenAt: null,
      createdAt: null,
    },
  ],
  invites: [],
  roles: [
    ...staffRoles.map((id) => ({
      id,
      name: id,
      levels: staffRoleTemplates[id],
      builtin: true,
      locked: ['owner', 'admin', 'qa'].includes(id),
      members: id === 'owner' ? 1 : 0,
      updatedBy: null,
      updatedAt: null,
    })),
    {
      id: 'r_0123456789ab',
      name: 'Trực đêm',
      levels: staffRoleTemplates.support,
      builtin: false,
      locked: false,
      members: 1,
      updatedBy: 'Linh Trần',
      updatedAt: null,
    },
  ],
  kpis: { members: 2, sensitive: 1, invites: 0 },
};

describe('Nhân sự & phân quyền (A18–A21)', () => {
  it('members with roles, scope, access and status; actions only for managers', () => {
    const html = text(
      render(
        <MemberTable team={team} canManage now={now} selfUid="u1" onAction={() => undefined} />,
      ),
    );
    expect(html).toContain('Minh Phạm minh@childlife.vn Owner Toàn bộ Không giới hạn');
    expect(html).toContain('Thảo Lê thao@gmail.com Hỗ trợ');
    expect(html).toContain('Mai Hồ mai@x.vn Trực đêm');
    // Row actions sit behind "⋯": pause or resume by status, never on yourself (P-134).
    const raw = render(
      <MemberTable team={team} canManage now={now} selfUid="u1" onAction={() => undefined} />,
    );
    expect(raw).toContain('aria-label="Thao tác cho Thảo Lê"');
    const byName = (name: string) => team.members.find((m) => m.name === name)!;
    expect(memberActions(byName('Thảo Lê'), 'u1')).toContain(
      byName('Thảo Lê').status === 'active' ? 'pause' : 'resume',
    );
    expect(team.members.map((m) => memberActions(m, 'u1')).flat()).toEqual(
      expect.arrayContaining(['pause', 'resume', 'remove']),
    );
    expect(
      memberActions(
        team.members.find((m) => m.uid === 'u1')!,
        'u1',
      ),
    ).toEqual(['roles', 'access']);
    const readOnly = text(
      render(
        <MemberTable
          team={team}
          canManage={false}
          now={now}
          selfUid="u1"
          onAction={() => undefined}
        />,
      ),
    );
    expect(readOnly).not.toContain('Thao tác cho');
  });

  it('the matrix shows levels per role, grouped; locked roles are marked', () => {
    const html = text(render(<RoleMatrix team={team} onOpen={() => undefined} />));
    expect(html).toContain('Owner 🔒 1 người');
    expect(html).toContain('TỔNG QUAN');
    expect(html).toContain('PHÁT TRIỂN Phát triển · Sổ tay kiểm thử');
    expect(html).toContain('Toàn quyền');
    expect(html).toContain('Xem · che');
    // Every portal function has its row, Sơ cứu included (D-058).
    expect(html).toContain('NỘI DUNG Nội dung · Sơ cứu');
    expect(functionGroups.flatMap((g) => g.fns).sort()).toEqual([...staffFunctions].sort());
  });

  it('editing never grants above the editor, the role ceiling, or people management', () => {
    const admin = levelsForRoles(['admin']);
    expect(maxLevel('support', 'familyTransfer', admin)).toBe('none');
    expect(maxLevel('support', 'dataJobs', admin)).toBe('view');
    expect(maxLevel('ops', 'staff', admin)).toBe('view');
    expect(maxLevel('ops', 'storage', levelsForRoles(['ops']))).toBe('edit');
    const intl = createIntl({ locale: 'vi', messages: messages.vi });
    expect(scopeOf(intl, staffRoleTemplates.qa)).toBe('Phát triển · Sổ tay kiểm thử');
    expect(scopeOf(intl, staffRoleTemplates.owner)).toBe('Toàn bộ');
  });
});

const list: FamilyList = {
  kpis: { total: 3050, active: 2310, low: 740, multiCarerRate: 0.41, nearFull: 86 },
  rows: [
    {
      code: 'F-7Q2K',
      owner: 'n***@gmail.com',
      members: 5,
      carers: 2,
      pendingInvites: 0,
      babies: 2,
      usedBytes: 8.2 * 1024 ** 3,
      quotaBytes: 10 * 1024 ** 3,
      platforms: ['android', 'ios'],
      lastActiveAt: '2026-10-11T02:48:00Z',
      activity: 'active',
    },
    {
      code: 'F-3M8D',
      owner: 'h***@gmail.com',
      members: 4,
      carers: 1,
      pendingInvites: 1,
      babies: 1,
      usedBytes: 19.4 * 1024 ** 3,
      quotaBytes: 20 * 1024 ** 3,
      platforms: ['ios'],
      lastActiveAt: '2026-09-29T02:00:00Z',
      activity: 'low',
    },
  ],
  next: 'f_next',
};

const detail: FamilyDetail = {
  code: 'F-7Q2K',
  createdAt: '2026-03-12T00:00:00Z',
  owner: 'n***@gmail.com',
  platforms: ['android', 'ios'],
  usedBytes: 8.2 * 1024 ** 3,
  quotaBytes: 10 * 1024 ** 3,
  expanded: false,
  language: 'vi',
  lastActiveAt: '2026-10-11T02:48:00Z',
  activity: 'active',
  members: [
    {
      uid: 'mom',
      email: 'n***@gmail.com',
      relation: 'mother',
      isOwner: true,
      roles: [
        { baby: 1, role: 'coParent' },
        { baby: 2, role: 'coParent' },
      ],
      lastActiveAt: '2026-10-11T02:48:00Z',
      platform: 'ios',
      model: 'iPhone',
      appVersion: '1.0.3',
      eligible: false,
    },
    {
      uid: 'dad',
      email: 't***@gmail.com',
      relation: 'father',
      isOwner: false,
      roles: [
        { baby: 1, role: 'coParent' },
        { baby: 2, role: 'coParent' },
      ],
      lastActiveAt: null,
      platform: 'android',
      model: null,
      appVersion: '1.0.3',
      eligible: true,
    },
    {
      uid: 'gm',
      email: 'b***@gmail.com',
      relation: 'grandmother',
      isOwner: false,
      roles: [{ baby: 1, role: 'caregiver' }],
      lastActiveAt: null,
      platform: null,
      model: null,
      appVersion: null,
      eligible: false,
    },
  ],
  invites: [
    {
      relation: 'grandfather',
      role: 'relative',
      state: 'expired',
      createdAt: '2026-10-02T00:00:00Z',
    },
  ],
  babies: [
    { ordinal: 1, records7d: 142, media7d: 18, stories: 3 },
    { ordinal: 2, records7d: 0, media7d: 0, stories: 0 },
  ],
  tickets: [
    {
      id: 't1',
      ticket: 'CL-1042',
      title: 'Không tải được video',
      status: 'new',
      createdAt: '2026-10-11T02:48:00Z',
    },
  ],
  transfer: {
    id: 'ft_1',
    to: 't***@gmail.com',
    ticket: 'CL-1042',
    openedBy: 'Hà Vũ',
    expiresAt: '2026-10-13T03:00:00Z',
  },
};

describe('Gia đình (A15–A17)', () => {
  it('the list shows codes, masked owners, counts and status — never names', () => {
    const html = text(
      render(
        <FamilyListView
          data={list}
          now={now}
          activity="all"
          onActivity={() => undefined}
          platform="all"
          onPlatform={() => undefined}
          storage="all"
          onStorage={() => undefined}
          q=""
          onQ={() => undefined}
          page={0}
          onNext={() => undefined}
          onOpen={() => undefined}
          searchLabel="Tìm"
        />,
      ),
    );
    expect(html).toContain('Tổng gia đình 3.050');
    expect(html).toContain('Có từ 2 người chăm 41%');
    expect(html).toContain('Tất cả · 3050');
    expect(html).toContain('F-7Q2K Chủ: n***@gmail.com 5 người 2 người chăm 2');
    expect(html).toContain('8,2 GB / 10 GB Android · iOS 12 phút trước Hoạt động');
    expect(html).toContain('F-3M8D Chủ: h***@gmail.com 4 người 1 lời mời chờ');
    expect(html).toContain('Ít hoạt động');
    expect(html).not.toContain('Nhà ');
  });

  it('the detail: product roles, relationship labels, counts, transfer pending, view logged', () => {
    const html = text(
      render(
        <FamilyDetailView data={detail} now={now} canTransfer onCancelTransfer={() => undefined} />,
      ),
    );
    expect(html).toContain('Tạo 12/03/2026 · Android · iOS · gói 10 GB');
    expect(html).toContain(
      'Đang chờ chủ hiện tại xác nhận chuyển cho t***@gmail.com (mở bởi Hà Vũ)',
    );
    expect(html).toContain('n***@gmail.com Mẹ Chủ hồ sơ Hoạt động 12 phút trước iPhone · 1.0.3');
    expect(html).toContain('t***@gmail.com Ba Cùng nuôi');
    expect(html).toContain('b***@gmail.com Bà Người chăm sóc (bé 1)');
    expect(html).toContain('Người được mời Ông Người thân Lời mời hết hạn');
    expect(html).toContain('Bé thứ 1 Tên và tuổi được ẩn 7 ngày: 142 lần ghi');
    expect(html).toContain('Không tải được video CL-1042');
    expect(html).toContain('Mỗi lần mở trang này được ghi vào nhật ký');
  });

  it('the transfer dialog offers only eligible co-parents', () => {
    const html = render(
      <TransferDialog data={detail} onClose={() => undefined} onDone={() => undefined} />,
      ['ops'],
    );
    expect(text(html)).toContain('Cần là Cùng nuôi của tất cả các bé');
    expect(html.match(/disabled=""/g)?.length).toBeGreaterThanOrEqual(1);
    expect(text(html)).toContain('Chỉ chuyển khi họ đồng ý trong 48 giờ');
  });
});

const growth: AnalyticsGrowth = {
  empty: false,
  range: { from: '2026-10-04', to: '2026-10-10' },
  days: 2,
  kpis: {
    dau: { value: 1284, change: 0.09 },
    wau: { value: 2310, change: 0.07 },
    mau: { value: 3050, change: -0.11 },
    stickiness: { value: 0.42, points: 0.02 },
    d30: { value: 0.38, points: -0.01 },
  },
  series: [
    { date: '2026-10-09', dau: 1200, wau: 2200, mau: 3000 },
    { date: '2026-10-10', dau: 1284, wau: 2310, mau: 3050 },
  ],
  channels: { invite: 480, website: 268, store: 588 },
  platforms: { ios: 775, android: 561 },
  newFamilies: 1336,
  cohorts: [{ week: '2026-W33', families: 412, retention: [1, 0.71, 0.58, null] }],
  totalFamilies: 3050,
};
const feats: AnalyticsFeatures = {
  empty: false,
  range: { from: '2026-10-04', to: '2026-10-10' },
  days: 7,
  kpis: {
    carePerDay: { value: 18420, change: 0.06 },
    memoriesPerWeek: { value: 6310, change: 0.12 },
    storiesPerWeek: { value: 412, change: null },
    relativesShare: { value: 0.41, points: 0.032 },
  },
  features: [{ feature: 'feeding', share: 0.88, perDay: 9640, change: 0.04 }],
  storage: {
    usedBytes: 4.8 * 1024 ** 4,
    photoBytes: 2.9 * 1024 ** 4,
    videoBytes: 1.7 * 1024 ** 4,
    otherBytes: 0.2 * 1024 ** 4,
    baseFamilies: 2874,
    expandedFamilies: 176,
    over80Families: 86,
  },
  versions: [{ platform: 'ios', version: '1.0.3', devices: 1402 }],
};

describe('Phân tích (A13 / A14)', () => {
  it('growth: KPIs with change vs the previous period, channels and cohorts', () => {
    const html = text(render(<GrowthView data={growth} />));
    expect(html).toContain('Hoạt động ngày 1.284 ↑ 9% so với kỳ trước');
    expect(html).toContain('Hoạt động tháng 3.050 ↓ 11% so với kỳ trước');
    expect(html).toContain('Gắn bó ngày/tháng 42% ↑ 2 điểm');
    expect(html).toContain('Giữ chân ngày 30 38% ↓ 1 điểm');
    expect(html).toContain('Lời mời người thân 480 · 36%');
    expect(html).toContain('Website (Android) 268 · 20%');
    expect(html).toContain('Tuần 33 412 100% 71% 58%');
  });

  it('features: usage, storage, versions; CSV holds the aggregates only', () => {
    const html = text(render(<FeaturesView data={feats} />, ['analyst']));
    expect(html).toContain('Lần ghi chăm sóc / ngày 18.420');
    expect(html).toContain('Bú bình · bú mẹ Nhật ký chăm sóc 88% 9.640 ↑ 4% so với kỳ trước');
    expect(html).toContain('Ảnh 2,9 TB · 60%');
    expect(html).toContain('Gói 10 GB 2.874 gia đình');
    expect(html).toContain('iOS 1.0.3 1.402 · 100%');
    // Góp ý & đánh giá (P-145): shown only when the server sends the counters.
    expect(html).not.toContain('Góp ý & đánh giá');
    const withFeedback = {
      ...feats,
      feedback: { idea: 6, bug: 3, other: 1 },
      reviewPrompt: { eligible: 40, requested: 10 },
    };
    const fb = text(render(<FeaturesView data={withFeedback} />, ['analyst']));
    expect(fb).toContain('Góp ý & đánh giá');
    expect(fb).toContain('Góp ý đã gửi · 10');
    expect(fb).toContain('Báo lỗi 3 · 30%');
    expect(fb).toContain('Đã hiện lời mời đánh giá 10 · 25%');
    expect(analyticsCsv(withFeedback)).toContain('"feedback","bug","3"');
    const csv = analyticsCsv(growth);
    expect(csv.split('\r\n')[0]).toBe('"section","key","value"');
    expect(csv).toContain('"channel","invite","480"');
  });
});

describe('Dữ liệu tham chiếu (C01–C04)', () => {
  it('WHO table with P3 / median / P97; bottle bands; the vaccine schedule by dose', () => {
    const growthHtml = text(
      render(
        <GrowthTable
          dataset="growth.length"
          rows={referenceV1('growth.length')}
          changed={new Set()}
        />,
      ),
    );
    expect(growthHtml).toContain('Ngưỡng dưới (P3) Trung vị Ngưỡng trên (P97)');
    expect(growthHtml).toContain('Mới sinh 46,3 49,9 53,4');
    expect(growthHtml).toContain('0–13 tuần · 14 dòng');
    const bottle = text(render(<BottleTable rows={bottleQuickPicksV1} changed={new Set(['7'])} />));
    expect(bottle).toContain('0–6 ngày 30 ml 45 ml 60 ml 75 ml 5 ml');
    expect(bottle).toContain('Từ 4 tháng 150 ml');
    expect(bottle).toContain('1–2 tháng 90 ml');
    expect(bottle).toContain('1–4 tuần 60 ml');
    const vaccines = text(
      render(<VaccineTable rows={referenceV1('vaccines.schedule')} changed={new Set()} />),
    );
    expect(vaccines).toMatch(/\d+ mũi · 0–\d+ tháng/);
    expect(vaccines).toContain('Mới sinh Vitamin K 1 Bệnh viện');
    const intl = createIntl({ locale: 'en', messages: messages.en });
    expect(bandLabel(intl, { fromDay: 7, toDay: 28, picks: [1, 2, 3, 4], stepMl: 10 })).toBe(
      '1–4 weeks',
    );
  });

  it('CSV row problems read in words, not parser codes (D-012)', () => {
    expect(text(render(<CsvError line={3} message="low < median < high" />))).toContain(
      'Dòng 3: P3 phải nhỏ hơn trung vị, trung vị nhỏ hơn P97',
    );
    expect(text(render(<CsvError line={1} message="header:age,low,median,high" />))).toContain(
      'Dòng 1: hàng đầu phải là age,low,median,high',
    );
    expect(
      text(render(<CsvError line={4} message="Invalid input: expected number" />, ['admin'], 'en')),
    ).toContain('Line 4: invalid value (a number is expected)');
  });

  it('a tab switch waits for the new table instead of drawing it with the old rows', () => {
    const lengthView = {
      dataset: 'growth.length',
      current: {
        versionId: 'builtin',
        label: 'v1',
        rows: referenceV1('growth.length') as unknown[],
        publishedAt: null,
        approver: null,
      },
      draft: null,
      history: [],
    };
    const props = { canEdit: true, canApprove: false, selfUid: 's1', onChanged: () => {} };
    // Length → Lượng sữa gợi ý: the answer on screen is still the length table's.
    const switching = render(
      <ReferenceFor view={lengthView} dataset="bottle.quickPicks" {...props} />,
    );
    expect(switching).toContain('role="status"');
    const shown = text(
      render(<ReferenceFor view={lengthView} dataset="growth.length" {...props} />),
    );
    expect(shown).toContain('Mới sinh 46,3 49,9 53,4');
  });
});

describe('two-person re-run (P-139) and the v1.0 sidebar', () => {
  const job: JobRow = {
    id: 'del_x',
    code: 'DJ-2226',
    type: 'deleteAccount',
    email: 'n***@gmail.com',
    createdAt: '2026-10-11T01:00:00Z',
    progress: 0.6,
    state: 'failed',
    steps: ['storage', 'personal'],
    step: 1,
    failedStep: 'personal',
    rerunRequest: { byUid: 'u9', by: 'Minh Phạm', reason: 'Kho đã ổn', at: '2026-10-11T02:00:00Z' },
  };
  it('the approver sees who asked and why', () => {
    const html = text(
      render(
        <RerunDialog row={job} mode="approve" onClose={() => undefined} onDone={() => undefined} />,
      ),
    );
    expect(html).toContain('Minh Phạm đề nghị: “Kho đã ổn”');
    const ask = text(
      render(
        <RerunDialog row={job} mode="request" onClose={() => undefined} onDone={() => undefined} />,
        ['eng'],
      ),
    );
    expect(ask).toContain('Việc xoá chỉ chạy lại khi một người khác có quyền Duyệt đồng ý.');
    expect(ask).toContain('Gửi đề nghị chạy lại');
  });

  it('each role sees only what it may open, in the v1.0 order', () => {
    const sidebar = (roles: StaffRole[]) =>
      text(
        render(
          <Sidebar
            route="overview"
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
    expect(sidebar(['admin'])).toContain(
      'Tổng quan Phân tích VẬN HÀNH Gia đình Hỗ trợ Mở rộng dung lượng Yêu cầu dữ liệu Dữ liệu tham chiếu NỘI DUNG Sơ cứu Nhịp lớn lên Mẫu kỷ niệm Thư viện chăm bé Nội dung theo giai đoạn Mốc phát triển Dinh dưỡng Duyệt nội dung HỆ THỐNG Hệ thống & AI Tính năng & phát hành Premium & Cá nhân hoá Trợ lý AI Cập nhật ứng dụng Nhân sự & phân quyền Nhật ký thao tác PHÁT TRIỂN Sổ tay kiểm thử',
    );
    expect(sidebar(['analyst'])).toContain('Tổng quan Phân tích PHÁT TRIỂN Sổ tay kiểm thử');
    expect(sidebar(['analyst'])).not.toContain('Gia đình');
    expect(sidebar(['expert'])).toContain(
      'VẬN HÀNH Dữ liệu tham chiếu NỘI DUNG Sơ cứu Nhịp lớn lên Mẫu kỷ niệm Thư viện chăm bé Nội dung theo giai đoạn Mốc phát triển Dinh dưỡng Duyệt nội dung PHÁT TRIỂN',
    );
    expect(sidebar(['admin'])).toContain('Admin');
  });
});
