import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, type Api, type QaCase, type QaResult, type QaRun } from '../src/api';
import { StaffContext } from '../src/context';
import { messages } from '../src/messages';
import {
  QaCaseDetail,
  QaCaseTable,
  QaCommentList,
  QaNav,
  QaRunPanel,
  QaStart,
  caseFormValid,
  filterCases,
  fold,
  qaProgress,
} from '../src/screens/Qa';
import { Sidebar, allowedRoute } from '../src/Shell';
import { levelsForRoles, type StaffRole } from './fixtures';

// P-132: the QA handbook on the portal — progress, filters, the case sheet and who sees what.
const now = new Date('2026-10-10T03:52:00Z'); // 10:52 in Vietnam
const noApi: Api = { call: () => Promise.reject(new Error('no network in tests')) };

function render(node: ReactNode, roles: StaffRole[] = ['qa'], locale: 'vi' | 'en' = 'vi') {
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
            email: 'qa@example.com',
            name: 'An QA',
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

const base = {
  refs: [],
  builtin: true,
  edited: false,
  archived: false,
  updatedBy: null,
  updatedAt: null,
};
const cases: QaCase[] = [
  {
    ...base,
    id: 'ONB-001',
    module: 'onboarding',
    title: 'Đăng nhập bằng email và mật khẩu',
    level: 'smoke',
    platforms: ['ios', 'android'],
    account: 'Chủ hồ sơ, 1 bé',
    steps: ['Mở app', 'Chạm "Dùng email"'],
    expected: ['Mở màn Hôm nay'],
    refs: ['R-001'],
  },
  {
    ...base,
    id: 'CARE-001',
    module: 'care',
    title: 'Ghi một bình sữa 90 ml',
    level: 'smoke',
    platforms: ['ios', 'android'],
    account: 'Chủ hồ sơ, 1 bé',
    steps: ['Chạm "Bình sữa"'],
    expected: ['Hôm nay hiện "Mẹ ghi"'],
  },
  {
    ...base,
    id: 'ADM-001',
    module: 'portal',
    title: 'Portal hiện email đã che',
    level: 'core',
    platforms: ['portal'],
    account: 'Nhân viên Hỗ trợ',
    steps: ['Mở Hỗ trợ'],
    expected: ['Email dạng x***@domain'],
  },
  {
    ...base,
    id: 'CARE-Q01',
    module: 'care',
    title: 'Ca cũ đã bỏ',
    level: 'core',
    platforms: ['android'],
    account: '',
    steps: ['x'],
    expected: ['y'],
    builtin: false,
    archived: true,
  },
];
const results: Record<string, QaResult> = {
  'ONB-001': { status: 'passed', by: 'An QA', at: '2026-10-10T03:40:00Z', comments: 0 },
  'ADM-001': { status: 'failed', by: 'An QA', at: '2026-10-10T03:45:00Z', comments: 2 },
  'CARE-Q01': { status: 'passed', by: 'An QA', at: '2026-10-10T03:45:00Z', comments: 0 },
};
const run: QaRun = {
  id: 'r_0123456789abcdef0123',
  name: '1.0.3 (38) DEV',
  environment: 'dev',
  notes: '',
  createdBy: 'An QA',
  createdAt: '2026-10-02T04:37:00Z',
  archived: false,
};

describe('progress and filters', () => {
  it('counts executed cases per level, status and module, without archived ones', () => {
    const p = qaProgress(cases, results);
    expect(p.smoke).toEqual({ done: 1, total: 2 });
    expect(p.all).toEqual({ done: 2, total: 3 });
    expect(p.counts).toEqual({ notRun: 1, passed: 1, failed: 1, blocked: 0, skipped: 0 });
    expect(p.modules.care).toEqual({ done: 0, total: 1 });
    expect(p.modules.widgets).toEqual({ done: 0, total: 0 });
    expect(p.archived).toBe(1);
  });

  it('search ignores tone marks and covers steps; filters combine', () => {
    expect(fold('Đăng nhập')).toBe('dang nhap');
    const all = { q: '', level: 'all', platform: 'all', status: 'all' } as const;
    const ids = (f: Partial<typeof all> | object, view = { kind: 'all' } as const) =>
      filterCases(cases, results, view, { ...all, ...f }).map((c) => c.id);
    expect(ids({ q: 'dang nhap' })).toEqual(['ONB-001']);
    expect(ids({ q: 'dùng email' })).toEqual(['ONB-001']);
    expect(ids({ level: 'smoke' })).toEqual(['ONB-001', 'CARE-001']);
    expect(ids({ platform: 'portal' })).toEqual(['ADM-001']);
    expect(ids({ status: 'notRun' })).toEqual(['CARE-001']);
    expect(
      filterCases(cases, results, { kind: 'module', module: 'care' }, all).map((c) => c.id),
    ).toEqual(['CARE-001']);
    expect(filterCases(cases, results, { kind: 'archived' }, all).map((c) => c.id)).toEqual([
      'CARE-Q01',
    ]);
  });
});

describe('run panel', () => {
  it('shows the run, both progress bars and the status counts', () => {
    const html = text(
      render(
        <QaRunPanel
          runs={[run]}
          run={run}
          progress={qaProgress(cases, results)}
          showArchived={false}
          canManage
          busy={false}
          onShowArchived={() => undefined}
          onSelect={() => undefined}
          onArchive={() => undefined}
          onNew={() => undefined}
        />,
      ),
    );
    expect(html).toContain('Lượt kiểm thử');
    expect(html).toContain('1.0.3 (38) DEV · Dev');
    expect(html).toContain('Dev · Tạo bởi An QA · 11:37 02/10/2026');
    expect(html).toContain('Smoke 1/2');
    expect(html).toContain('Tất cả ca 2/3');
    expect(html).toContain('Chưa chạy: 1');
    expect(html).toContain('Lỗi: 1');
    expect(html).toContain('Lưu trữ lượt');
    expect(html).toContain('+ Lượt kiểm thử mới');
  });

  it('without the manage right there are no run buttons, and an empty state asks for a run', () => {
    const html = text(
      render(
        <QaRunPanel
          runs={[]}
          run={null}
          progress={qaProgress(cases, {})}
          showArchived={false}
          canManage={false}
          busy={false}
          onShowArchived={() => undefined}
          onSelect={() => undefined}
          onArchive={() => undefined}
          onNew={() => undefined}
        />,
        ['support'],
      ),
    );
    expect(html).not.toContain('Lượt kiểm thử mới');
    expect(html).toContain('Nhờ Kiểm thử hoặc Kỹ sư tạo lượt');
  });
});

describe('contents and table', () => {
  it('lists modules that have cases with done/total, and archived cases last', () => {
    const html = text(
      render(
        <QaNav
          progress={qaProgress(cases, results)}
          view={{ kind: 'all' }}
          onView={() => undefined}
        />,
      ),
    );
    expect(html).toContain('Bắt đầu');
    expect(html).toContain('Tất cả ca kiểm thử 3');
    expect(html).toContain('Chào mừng & đăng nhập 1/1');
    expect(html).toContain('Ghi chăm sóc 0/1');
    expect(html).toContain('Cổng vận hành 1/1');
    expect(html).not.toContain('Widget & màn hình khoá');
    expect(html).toContain('Ca đã lưu trữ 1');
  });

  it('rows show level, platforms, status and comment counts (English too)', () => {
    const table = (locale: 'vi' | 'en') =>
      text(
        render(
          <QaCaseTable
            rows={cases.slice(0, 3)}
            results={results}
            hasRun
            filters={{ q: '', level: 'all', platform: 'all', status: 'all' }}
            onFilters={() => undefined}
            onOpen={() => undefined}
          />,
          ['qa'],
          locale,
        ),
      );
    const vi = table('vi');
    expect(vi).toContain(
      'ONB-001 Đăng nhập bằng email và mật khẩu Chào mừng & đăng nhập Smoke iOS Android Đạt',
    );
    expect(vi).toContain(
      'ADM-001 Portal hiện email đã che Cổng vận hành Core Portal Lỗi 2 bình luận',
    );
    expect(vi).toContain(
      'CARE-001 Ghi một bình sữa 90 ml Ghi chăm sóc Smoke iOS Android Chưa chạy',
    );
    const en = table('en');
    expect(en).toContain('Welcome & sign-in Smoke iOS Android Passed');
    expect(en).toContain('Failed 2 comments');
  });

  it('the start page explains smoke vs core and the statuses', () => {
    const html = text(render(<QaStart />));
    expect(html).toContain('Smoke — đường đi quan trọng nhất');
    expect(html).toContain('Core — các luồng chính');
    expect(html).toContain('Bị chặn — chưa chạy được');
    expect(html).toContain('Không dán ảnh, tên, ngày sinh');
  });
});

describe('the case sheet', () => {
  const detail = (over: Partial<Parameters<typeof QaCaseDetail>[0]>, roles: StaffRole[] = ['qa']) =>
    text(
      render(
        <QaCaseDetail
          item={cases[0]!}
          run={run}
          result={results['ONB-001']!}
          canTest
          canManage
          busy={false}
          error={null}
          now={now}
          onStatus={() => undefined}
          onEdit={() => undefined}
          onArchive={() => undefined}
          {...over}
        />,
        roles,
      ),
    );

  it('shows account, steps, expected result, refs, the result switch and who set it', () => {
    const html = detail({});
    expect(html).toContain('ONB-001 · Chào mừng & đăng nhập');
    expect(html).toContain('Tài khoản kiểm thử Chủ hồ sơ, 1 bé');
    expect(html).toContain('Các bước Mở app Chạm "Dùng email"');
    expect(html).toContain('Kết quả mong đợi Mở màn Hôm nay');
    expect(html).toContain('Tham chiếu: R-001');
    expect(html).toContain('Chưa chạy Đạt Lỗi Bị chặn Bỏ qua');
    expect(html).toContain('Cập nhật bởi An QA · 10:40 hôm nay');
    expect(html).toContain('Sửa ca');
    expect(html).toContain('Lưu trữ ca');
  });

  it('an archived run is read-only; no run asks for one; testers cannot edit cases', () => {
    const archived = detail({ run: { ...run, archived: true } });
    expect(archived).toContain('Lượt này đã lưu trữ nên chỉ xem được.');
    expect(archived).not.toContain('Chưa chạy Đạt Lỗi');
    expect(detail({ run: null, result: null })).toContain('Tạo hoặc chọn một lượt kiểm thử');
    const tester = detail({ canManage: false }, ['support']);
    expect(tester).toContain('Chưa chạy Đạt Lỗi Bị chặn Bỏ qua');
    expect(tester).not.toContain('Sửa ca');
  });

  it('comments show who and when', () => {
    const html = text(
      render(
        <QaCommentList
          now={now}
          comments={[
            {
              id: 'c1',
              by: 'An QA',
              text: 'iPhone 15, iOS 26.1 — CL-88',
              at: '2026-10-10T03:50:00Z',
            },
          ]}
        />,
      ),
    );
    expect(html).toContain('An QA · 10:50 hôm nay iPhone 15, iOS 26.1 — CL-88');
    expect(text(render(<QaCommentList now={now} comments={[]} />))).toContain('Chưa có bình luận.');
  });

  it('the editor only submits what the server accepts', () => {
    const ok = {
      module: 'care',
      level: 'core',
      platforms: ['ios'],
      title: 'Ghi tã',
      account: '',
      steps: ['a'],
      expected: ['b'],
    } as const;
    expect(
      caseFormValid({
        ...ok,
        platforms: [...ok.platforms],
        steps: [...ok.steps],
        expected: [...ok.expected],
      }),
    ).toBe(true);
    expect(
      caseFormValid({ ...ok, title: 'ab', platforms: ['ios'], steps: ['a'], expected: ['b'] }),
    ).toBe(false);
    expect(caseFormValid({ ...ok, platforms: [], steps: ['a'], expected: ['b'] })).toBe(false);
    expect(caseFormValid({ ...ok, platforms: ['ios'], steps: [], expected: ['b'] })).toBe(false);
    expect(
      caseFormValid({ ...ok, platforms: ['ios'], steps: ['x'.repeat(501)], expected: ['b'] }),
    ).toBe(false);
  });
});

describe('who reaches the handbook (P-132)', () => {
  const sidebar = (roles: StaffRole[]) =>
    text(
      render(
        <Sidebar
          route="qa"
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

  it('Kiểm thử sees only the handbook; other staff see it under Phát triển', () => {
    const qa = sidebar(['qa']);
    expect(qa).toContain('PHÁT TRIỂN Sổ tay kiểm thử');
    expect(qa).not.toContain('Tổng quan');
    expect(qa).not.toContain('HỆ THỐNG');
    expect(qa).toContain('Kiểm thử');
    const ops = sidebar(['ops']);
    expect(ops).toContain('Tổng quan');
    expect(ops).toContain('Nhật ký thao tác PHÁT TRIỂN Sổ tay kiểm thử');
  });

  it('a page the roles cannot open falls back to one they can', () => {
    expect(allowedRoute(levelsForRoles(['qa']), 'overview')).toBe('qa');
    expect(allowedRoute(levelsForRoles(['qa']), 'audit')).toBe('qa');
    expect(allowedRoute(levelsForRoles(['qa']), 'qa')).toBe('qa');
    expect(allowedRoute(levelsForRoles(['ops']), 'overview')).toBe('overview');
    expect(allowedRoute(levelsForRoles(['support']), 'qa')).toBe('qa');
  });
});
