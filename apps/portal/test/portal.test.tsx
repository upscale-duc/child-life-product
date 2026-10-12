import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import {
  accountDeletionSteps,
  auditCategories,
  babyDeletionSteps,
  flagKeys,
  launchedFlagDefaults,
  levelsForRoles,
  staffFunctions,
  staffLevels,
  memberRoles,
  qaLevels,
  qaModules,
  qaPlatforms,
  qaStatuses,
  staffRoles,
  supportCategories,
  type StaffRole,
} from './fixtures';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider, createIntl } from 'react-intl';
import { describe, expect, it } from 'vitest';
import {
  ApiContext,
  type Api,
  type AuditRow,
  type FlagsView,
  type Overview,
  type StorageRow,
} from '../src/api';
import { StaffContext, routeOf, routePaths } from '../src/context';
import { ago, csvCell, gb, pct, usageTone, when } from '../src/format';
import { messages } from '../src/messages';
import { reasonMessages } from '../src/ui';
import { AuditTable } from '../src/screens/Audit';
import { FeaturesView, defaultNotice, nextStep } from '../src/screens/Features';
import { jobState } from '../src/screens/Jobs';
import { OverviewView } from '../src/screens/Overview';
import { SignInScreen, authErrorId, type SignInActions } from '../src/screens/SignIn';
import { DecideDialog, StorageView, needsLead } from '../src/screens/Storage';
import { TicketDetailView, TicketListView } from '../src/screens/Support';
import { Sidebar } from '../src/Shell';
import { IDLE_MS, idleExpired, staffFromClaims, type StaffIdentity } from '../src/session';

const now = new Date('2026-10-10T03:52:00Z'); // 10:52 in Vietnam
const noApi: Api = { call: () => Promise.reject(new Error('no network in tests')) };

function staff(...roles: StaffRole[]): StaffIdentity {
  return {
    uid: 's1',
    email: 'linh@example.com',
    name: 'Linh Trần',
    roles,
    levels: levelsForRoles(roles),
  };
}

function render(
  node: ReactNode,
  roles: StaffRole[] = ['ops', 'support'],
  locale: 'vi' | 'en' = 'vi',
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
      <ApiContext.Provider value={noApi}>
        <StaffContext.Provider value={staff(...roles)}>{node}</StaffContext.Provider>
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

describe('message catalogs (D-012)', () => {
  const src = join(__dirname, '../src');
  const files = (dir: string): string[] =>
    readdirSync(dir, { withFileTypes: true }).flatMap((e) =>
      e.isDirectory()
        ? files(join(dir, e.name))
        : e.name.endsWith('.tsx') || e.name.endsWith('.ts')
          ? [join(dir, e.name)]
          : [],
    );
  const literalIds = new Set<string>();
  for (const f of files(src)) {
    const code = readFileSync(f, 'utf8');
    for (const m of code.matchAll(/\bid(?:=|: )['"]([a-zA-Z][\w.]+)['"]/g)) literalIds.add(m[1]!);
  }

  it('every literal id in the source exists in both catalogs', () => {
    const ids = [...literalIds].filter((id) => id.includes('.'));
    expect(ids.length).toBeGreaterThan(150);
    for (const id of ids) {
      expect(messages.vi[id], id).toBeTruthy();
      expect(messages.en[id], id).toBeTruthy();
    }
  });

  it('every dynamic id family is covered', () => {
    const dynamic = [
      ...Object.keys(routePaths).map((r) => `nav.${r}`),
      ...flagKeys.flatMap((k) => [`flag.${k}`, `flag.${k}.desc`, `flag.${k}.offEffect`]),
      ...supportCategories.map((c) => `category.${c}`),
      ...['owner', ...memberRoles].map((r) => `memberRole.${r}`),
      ...staffRoles.map((r) => `role.${r}`),
      ...[...babyDeletionSteps, ...accountDeletionSteps].map((s) => `step.${s}`),
      ...['exportCare', 'exportMedia', 'deleteBaby', 'deleteAccount'].map((t) => `jobType.${t}`),
      ...['error', 'high', 'warn', 'wait'].map((s) => `severity.${s}`),
      ...['deletionFailed', 'storagePending', 'videoQueue', 'ticketsUnclaimed'].map(
        (a) => `alert.${a}`,
      ),
      ...['firstOpen', 'account', 'verified', 'baby', 'firstLog', 'invite'].map(
        (s) => `funnel.${s}`,
      ),
      ...['all', ...auditCategories].map((c) => `auditCategory.${c}`),
      ...['new', 'claimed', 'waiting', 'closed'].map((s) => `ticket.${s}`),
      ...['open', 'granted', 'declined'].flatMap((s) => [
        `storage.table.${s}`,
        `storage.empty.${s}`,
      ]),
      ...['dev', 'prod'].map((e) => `env.${e}`),
      ...['ops', 'system', 'develop'].map((s) => `nav.section.${s}`),
      ...staffFunctions.flatMap((f) => [`fn.${f}`, `fn.${f}.note`]),
      ...staffLevels.map((l) => `level.${l}`),
      ...['overview', 'ops', 'system', 'develop'].map((g) => `staff.group.${g}`),
      ...['active', 'paused', 'expired', 'removed'].map((st) => `staff.status.${st}`),
      ...['roles', 'access', 'pause', 'resume', 'remove', 'revokeInvite'].flatMap((o) => [
        `staff.dialog.${o}`,
        `staff.confirm.${o}`,
      ]),
      ...['unlimited', 'days', 'until'].map((a) => `staff.access.${a}`),
      ...reasonMessages.map((r) => `error.${r}`),
      ...qaModules.flatMap((m) => [`qa.module.${m}`, `qa.module.${m}.about`]),
      ...qaPlatforms.map((p) => `qa.platform.${p}`),
      ...qaLevels.map((l) => `qa.level.${l}`),
      ...qaStatuses.map((s) => `qa.status.${s}`),
      ...['level', 'platform', 'status'].map((f) => `qa.filter.${f}`),
      ...['create', 'follow', 'record', 'archive'].map((s) => `qa.start.run.${s}`),
      ...['passed', 'failed', 'blocked', 'skipped'].map((s) => `qa.start.status.${s}`),
      ...['owner', 'coParent', 'caregiver', 'relative', 'guest', 'staff'].map(
        (a) => `qa.start.accounts.${a}`,
      ),
    ];
    for (const id of dynamic) {
      expect(messages.vi[id], id).toBeTruthy();
      expect(messages.en[id], id).toBeTruthy();
    }
  });

  it('every message compiles in both locales', () => {
    for (const locale of ['vi', 'en'] as const) {
      const intl = createIntl({
        locale,
        messages: messages[locale],
        onError: (e) => {
          throw e;
        },
      });
      for (const id of Object.keys(messages[locale])) {
        expect(() =>
          intl.formatMessage(
            { id },
            {
              n: 1,
              p: 1,
              babies: 1,
              people: 1,
              flag: 'x',
              action: 'x',
              ago: 'x',
              time: 'x',
              email: 'x',
              id: 'x',
              code: 'x',
              name: 'x',
              step: 'x',
              type: 'x',
              d: 'x',
              used: 'x',
              quota: 'x',
              day: 1,
              days: 1,
              month: 'x',
              exports: 1,
              deletions: 1,
              done: 1,
              total: 1,
              env: 'x',
              when: 'x',
              status: 'x',
              filter: 'x',
              refs: 'x',
              reason: 'x',
              v: 'x',
              w: 'x',
              lo: 1,
              hi: 2,
              role: 'x',
              unit: 'day',
              date: 'x',
              platforms: 'x',
              plan: 'x',
              to: 'x',
              by: 'x',
              until: 'x',
              records: 1,
              media: 1,
              stories: 1,
              size: 'x',
              owner: 'x',
              line: 1,
              message: 'x',
              added: 1,
              changed: 1,
              removed: 1,
              author: 'x',
              approver: 'x',
              max: 1,
              b: (chunks: ReactNode[]) => chunks,
            },
          ),
        ).not.toThrow();
      }
    }
  });
});

describe('session (A01, D-043)', () => {
  it('only accounts with the staff claim and a role get in; levels start from the templates', () => {
    expect(staffFromClaims('u', 'a@b.c', {})).toBeNull();
    expect(staffFromClaims('u', 'a@b.c', { staff: true })).toBeNull();
    expect(staffFromClaims('u', 'a@b.c', { staff: 'true', roles: ['ops'] })).toBeNull();
    expect(staffFromClaims('u', 'a@b.c', { staff: true, roles: [] })).toBeNull();
    // Roles made on the portal ("r_…") are resolved by `staffMe` (P-134).
    expect(
      staffFromClaims('u', 'a@b.c', {
        staff: true,
        roles: ['ops', 'r_0123456789ab'],
        name: 'Linh',
      }),
    ).toEqual({
      uid: 'u',
      email: 'a@b.c',
      name: 'Linh',
      roles: ['ops', 'r_0123456789ab'],
      levels: levelsForRoles(['ops']),
    });
    expect(staffFromClaims('u', 'a@b.c', { staff: true, roles: ['eng'] })?.name).toBe('a@b.c');
    // S15 trưởng nhóm claims read as Admin.
    expect(staffFromClaims('u', 'a@b.c', { staff: true, roles: ['lead'] })?.levels.storage).toBe(
      'full',
    );
  });

  it('signs out after 30 idle minutes, not before', () => {
    const t = 1_000_000_000;
    expect(idleExpired(null, t)).toBe(false);
    expect(idleExpired(t - IDLE_MS + 1000, t)).toBe(false);
    expect(idleExpired(t - IDLE_MS, t)).toBe(true);
  });

  it('auth errors never reveal whether an account exists', () => {
    expect(authErrorId('auth/user-not-found')).toBe(authErrorId('auth/wrong-password'));
    expect(authErrorId('auth/invalid-credential')).toBe('signIn.error.credentials');
    expect(authErrorId('portal/denied')).toBe('signIn.notice.denied');
    expect(authErrorId('auth/expired-action-code')).toBe('signIn.notice.linkInvalid');
  });

  it('the sign-in card offers a password and an email link, and no 2-step code', () => {
    const actions = {} as SignInActions;
    const html = text(
      render(<SignInScreen actions={actions} notice="denied" pendingLink={false} />),
    );
    expect(html).toContain('Không xem được ảnh, video, chú thích hay ghi chép');
    expect(html).toContain('Mật khẩu');
    expect(html).toContain('Link qua email');
    expect(html).toContain('Quên mật khẩu?');
    expect(html).toContain('Tự đăng xuất sau 30 phút không hoạt động');
    expect(html).toContain('chưa được cấp quyền');
    expect(html).not.toMatch(/xác minh 2 bước/i);
    const pending = text(render(<SignInScreen actions={actions} notice={null} pendingLink />));
    expect(pending).toContain('Nhập lại email');
    expect(pending).not.toContain('Quên mật khẩu?');
  });
});

describe('formatting', () => {
  const vi = createIntl({ locale: 'vi', messages: messages.vi });
  const en = createIntl({ locale: 'en', messages: messages.en });
  it('sizes and shares read naturally in both languages', () => {
    expect(gb(vi, 9.6 * 1024 ** 3)).toBe('9,6 GB');
    expect(gb(en, 9.6 * 1024 ** 3)).toBe('9.6 GB');
    expect(pct(vi, 0.69)).toMatch(/^69\s?%$/);
    expect(pct(vi, null)).toBe('—');
    expect(usageTone(9.1, 10)).toBe('warn');
    expect(usageTone(8.6, 10)).toBe('ok');
  });
  it('times are Vietnam time', () => {
    expect(ago(vi, '2026-10-10T03:40:00Z', now)).toBe('12 phút trước');
    expect(ago(vi, '2026-10-09T10:00:00Z', now)).toBe('hôm qua');
    expect(when(vi, '2026-10-10T03:42:00Z', now)).toBe('10:42 hôm nay');
    expect(when(vi, '2026-10-09T14:03:00Z', now)).toBe('Hôm qua 21:03');
  });
  it('CSV cells are quoted and formula prefixes are neutralised', () => {
    expect(csvCell('a"b')).toBe('"a""b"');
    expect(csvCell('=HYPERLINK("x")')).toBe(`"'=HYPERLINK(""x"")"`);
    expect(csvCell(null)).toBe('""');
  });
  it('routes map to screens', () => {
    expect(routeOf('/support/')).toBe('support');
    expect(routeOf('/system/ai')).toBe('systemAi');
    expect(routeOf('/nope')).toBe('overview');
  });
});

describe('A02 overview', () => {
  const data: Overview = {
    kpis: {
      activeFamilies: 1284,
      activeFamiliesPrev: 1035,
      newAccounts: 1336,
      newAccountsPrev: 0,
      setupRate: 0.69,
      multiCarerRate: 0.41,
    },
    daily: [
      { date: '2026-10-09', families: 1200 },
      { date: '2026-10-10', families: 1284 },
    ],
    funnel: [
      { step: 'firstOpen', count: null },
      { step: 'account', count: 1540 },
      { step: 'verified', count: 1470 },
      { step: 'baby', count: 1260 },
      { step: 'firstLog', count: 1046 },
      { step: 'invite', count: 612 },
    ],
    weekly: [{ weekStart: '2026-10-03T00:00:00Z', feed: 12000, sleep: 8000, diaper: 6000 }],
    alerts: [
      { severity: 'error', module: 'jobs', kind: 'deletionFailed', count: 1 },
      { severity: 'wait', module: 'support', kind: 'ticketsUnclaimed', count: 5 },
    ],
  };
  it('shows aggregates, the funnel and what needs action', () => {
    const html = text(render(<OverviewView data={data} days={30} />));
    expect(html).toContain('1.284');
    expect(html).toContain('↑ 24% so với 30 ngày trước');
    expect(html).toContain('Chưa có kỳ trước để so');
    expect(html).toContain('1 lần xoá dữ liệu thất bại, cần chạy lại');
    expect(html).toContain('5 yêu cầu hỗ trợ chưa ai nhận quá 4 giờ');
    expect(html).toContain('Mở app lần đầu Chưa đo');
    expect(html).toContain('612 · 40%');
  });
  it('reads in English too', () => {
    const html = text(render(<OverviewView data={data} days={30} />, ['ops'], 'en'));
    expect(html).toContain('1,284');
    expect(html).toContain('Needs action');
  });
});

describe('A03 support', () => {
  const list = {
    counts: { open: 2, new: 1, claimed: 1, waiting: 0 },
    rows: [
      {
        id: 't_1',
        ticket: 'CL-1042',
        title: 'Không tải được video lên album',
        category: 'memories',
        email: 'n***@gmail.com',
        status: 'new' as const,
        createdAt: '2026-10-10T03:40:00Z',
        claimedBy: null,
      },
    ],
  };
  const detail = {
    ...list.rows[0]!,
    message: 'Mình chọn video 2 phút của con mà app cứ báo "chưa tải được".',
    role: 'owner',
    family: { babies: 2, people: 5, usedBytes: 8.2 * 1024 ** 3, quotaBytes: 10 * 1024 ** 3 },
    diagnostics: {
      platform: 'ios',
      appVersion: '1.0.3',
      osVersion: '18.1',
      deviceModel: 'iPhone 13',
      pendingUploads: 1,
      lastSyncAt: '2026-10-10T03:50:00Z',
    },
    thread: [],
  };
  it('lists tickets with masked emails and status counts', () => {
    const html = text(
      render(
        <TicketListView
          data={list}
          filter="open"
          onFilter={() => undefined}
          selected="t_1"
          onSelect={() => undefined}
          now={now}
        />,
      ),
    );
    expect(html).toContain('Tất cả · 2');
    expect(html).toContain('Chưa nhận · 1');
    expect(html).toContain('CL-1042 · Kỷ niệm & media · n***@gmail.com');
    expect(html).toContain('12 phút trước');
  });
  it('support may claim, reply and use the Wi-Fi guide; engineering only reads', () => {
    const support = text(
      render(<TicketDetailView ticket={detail} now={now} onChanged={() => undefined} />, [
        'support',
      ]),
    );
    expect(support).toContain('Nhận xử lý');
    expect(support).toContain('Gửi hướng dẫn tải qua Wi-Fi');
    expect(support).toContain('Chủ tài khoản');
    expect(support).toContain('2 bé · 5 người');
    expect(support).toContain('8,2 GB / 10 GB');
    expect(support).toContain('iOS · 1.0.3 · iPhone 13');
    expect(support).toContain('Hỗ trợ không mở được ảnh');
    const eng = text(
      render(<TicketDetailView ticket={detail} now={now} onChanged={() => undefined} />, ['eng']),
    );
    expect(eng).not.toContain('Nhận xử lý');
    expect(eng).not.toContain('Gửi hướng dẫn');
    expect(eng).not.toContain('Trả lời người dùng…');
  });
});

describe('A04/A05 storage', () => {
  const row: StorageRow = {
    id: 'sr_00000000000000000001',
    code: 'MR-0000',
    family: 'F-7Q2K',
    babies: 2,
    people: 6,
    usedBytes: 9.6 * 1024 ** 3,
    quotaBytes: 10 * 1024 ** 3,
    requestedGb: 10,
    message: 'Con thứ hai mới sinh, cả nhà quay video nhiều.',
    createdAt: '2026-10-08T03:00:00Z',
    decidedAt: null,
    grantedGb: null,
    metrics: {
      photoBytes: 5.1 * 1024 ** 3,
      videoBytes: 4.2 * 1024 ** 3,
      otherBytes: 0.3 * 1024 ** 3,
      freeBytes: 0.4 * 1024 ** 3,
      previousGrants: 0,
      ownerCreatedAt: '2025-03-10T00:00:00Z',
      requesterIsOwner: true,
    },
  };
  const data = {
    kpis: {
      pending: 1,
      oldestAt: row.createdAt,
      over80: 42,
      grantedThisMonth: 11,
      grantedGbThisMonth: 85,
      medianHours: 5,
    },
    rows: [row],
  };
  it('decides on metadata only, behind the ops role', () => {
    const html = text(
      render(<StorageView data={data} status="open" now={now} onChanged={() => undefined} />, [
        'ops',
      ]),
    );
    expect(html).toContain('F-7Q2K');
    expect(html).toContain('9,6 GB / 10 GB · 96%');
    expect(html).toContain('+10 GB');
    expect(html).toContain('Ảnh 5,1 GB');
    expect(html).toContain('Ba mẹ · chủ tài khoản');
    expect(html).toContain('Duyệt');
    const support = text(
      render(<StorageView data={data} status="open" now={now} onChanged={() => undefined} />, [
        'support',
      ]),
    );
    expect(support).not.toContain('Từ chối Duyệt');
  });
  it('more than 20 GB or a custom amount needs a team lead (P-120)', () => {
    expect(needsLead(5)).toBe(false);
    expect(needsLead(20)).toBe(false);
    expect(needsLead(15)).toBe(true);
    expect(needsLead(30)).toBe(true);
    const big = { ...row, requestedGb: 30 };
    const ops = render(
      <DecideDialog row={big} kind="grant" onClose={() => undefined} onDone={() => undefined} />,
      ['ops'],
    );
    expect(text(ops)).toContain('cần trưởng nhóm duyệt');
    expect(ops).toMatch(/<button[^>]*disabled=""[^>]*>Duyệt và báo gia đình/);
    const lead = text(
      render(
        <DecideDialog row={big} kind="grant" onClose={() => undefined} onDone={() => undefined} />,
        ['lead'],
      ),
    );
    expect(lead).not.toContain('Nhờ trưởng nhóm');
    expect(lead).toContain('10 GB → 40 GB');
  });
  it('a routine grant starts on the requested amount with the new quota shown', () => {
    const html = text(
      render(
        <DecideDialog row={row} kind="grant" onClose={() => undefined} onDone={() => undefined} />,
        ['ops'],
      ),
    );
    expect(html).toContain('Duyệt thêm dung lượng cho F-7Q2K');
    expect(html).toContain('10 GB → 20 GB');
    expect(html).toContain('Gửi qua thông báo trong app và email của chủ tài khoản');
  });
});

describe('A06 jobs, A10 features, A12 audit', () => {
  it('job states map to the A06 pills', () => {
    const base = {
      id: 'j',
      code: 'DJ-1',
      email: 'v***@gmail.com',
      createdAt: now.toISOString(),
      progress: 0.7,
    };
    expect(jobState({ ...base, type: 'deleteAccount', state: 'failed' })).toEqual({
      tone: 'error',
      id: 'job.failed',
    });
    expect(jobState({ ...base, type: 'deleteBaby', state: 'running' }).id).toBe('job.deleting');
    expect(jobState({ ...base, type: 'exportCare', state: 'running' }).id).toBe('job.preparing');
    expect(jobState({ ...base, type: 'exportMedia', state: 'ready' }).id).toBe('job.ready');
  });

  const flags: FlagsView = {
    flags: {
      ...launchedFlagDefaults,
      ai_story_drafts: { enabled: true, scope: 'percent', percent: 50, notice: null },
    },
    limits: {
      familyQuotaBytes: 10 * 1024 ** 3,
      videoMaxDurationSec: null,
      videoMaxBytes: 4 * 1024 ** 3,
      videoWifiOnlyDefault: true,
      mediaItemsPerAdd: 30,
      exportLinkTtlHours: 24,
      storageRequestAmountsGb: [10, 20],
    },
    lastEdit: { ai_story_drafts: { by: 'Linh Trần', at: '2026-10-02T07:05:00Z' } },
    recent: [
      {
        action: 'flags.rollout',
        target: 'ai_story_drafts',
        by: 'Linh Trần',
        at: '2026-10-02T07:05:00Z',
        reason: 'Chi phí ổn định sau 1 tuần ở 25%.',
        detail: { after: { enabled: true, scope: 'percent', percent: 50, notice: null } },
      },
    ],
  };
  it('the default family notice is the Vietnamese copy, whatever the staff language', () => {
    expect(defaultNotice('video_upload')).toBe(
      '“Tải video” đang tạm dừng một chút, chúng mình sẽ mở lại sớm.',
    );
  });
  it('the rollout ladder moves 10 → 25 → 50 → 100', () => {
    expect(nextStep({ enabled: false, scope: 'internal', percent: 0, notice: null })).toBe(10);
    expect(nextStep({ enabled: true, scope: 'percent', percent: 25, notice: null })).toBe(50);
    expect(nextStep({ enabled: true, scope: 'percent', percent: 50, notice: null })).toBe(100);
    expect(nextStep({ enabled: true, scope: 'all', percent: 0, notice: null })).toBeNull();
  });
  it('kill switches are for engineering; rollout steps for operations', () => {
    const ops = render(<FeaturesView data={flags} ai={null} onChanged={() => undefined} />, [
      'ops',
    ]);
    expect(text(ops)).toContain('Mở dần · 50%');
    expect(text(ops)).toContain('Mở cho 100% gia đình');
    expect(text(ops)).toContain('Linh · 2/10');
    expect(text(ops)).toContain('Mở “AI gợi ý câu chuyện” lên 50%');
    expect(ops.match(/role="switch"[^>]*disabled=""/g)?.length).toBe(flagKeys.length);
    const eng = render(<FeaturesView data={flags} ai={null} onChanged={() => undefined} />, [
      'eng',
    ]);
    expect(eng).not.toMatch(/role="switch"[^>]*disabled=""/);
  });
  it('audit rows read as actions with the reason, no family content', () => {
    const rows: AuditRow[] = [
      {
        id: 'a1',
        at: '2026-10-10T03:52:00Z',
        actor: 'Linh Trần',
        role: 'Vận hành',
        action: 'storage.grant',
        category: 'storage',
        target: 'F-7Q2K',
        reason: 'Gia đình 2 bé, tốc độ tăng 0,8 GB/tháng.',
        detail: { grantGb: 10 },
      },
      {
        id: 'a2',
        at: '2026-10-10T03:40:00Z',
        actor: 'Hà Nguyễn',
        role: 'Hỗ trợ',
        action: 'support.claim',
        category: 'support',
        target: 'CL-1042',
        reason: null,
        detail: null,
      },
    ];
    const html = text(render(<AuditTable rows={rows} now={now} />));
    expect(html).toContain('10:52 hôm nay');
    expect(html).toContain('Duyệt mở rộng +10 GB');
    expect(html).toContain('Nhận xử lý yêu cầu hỗ trợ');
    expect(html).toContain('CL-1042 —');
  });
});

describe('shell', () => {
  it('the sidebar shows counts, the environment and the signed-in staff member', () => {
    const html = text(
      render(
        <Sidebar
          route="systemAi"
          badges={{ tickets: 12, storage: 4, jobs: 0 }}
          environment="dev"
          locale="vi"
          onLocale={() => undefined}
          onSignOut={() => undefined}
          navigate={() => undefined}
        />,
        ['support', 'ops'],
      ),
    );
    expect(html).toContain('Hỗ trợ 12');
    expect(html).toContain('Mở rộng dung lượng 4');
    expect(html).not.toContain('Yêu cầu dữ liệu 0');
    expect(html).toContain('● Dev');
    expect(html).toContain('Linh Trần');
    expect(html).toContain('Vận hành · Hỗ trợ');
  });
});
