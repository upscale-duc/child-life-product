import {
  defaultNotificationOpsConfig,
  engagementHealthSignalIds,
  engagementKinds,
  engagementOutcomes,
  engagementReasonCodes,
  engagementStages,
  inboxGroups,
  type EngagementHealthResponse,
  notificationActionStates,
  notificationDeliveryReasons,
  notificationDeliveryStates,
  notificationLifecycleStates,
  notificationProducers,
  notificationReadStates,
  notificationSettingKeys,
  notificationStatMetrics,
  notificationTemplateStatuses,
  notificationCatalogGaps,
  notificationDestinationIds,
  notificationKinds,
  notificationTemplates,
  defaultEngagementPolicy,
  type NotificationEntryDetail,
  type NotificationOpsResponse,
  type NotificationTestResult,
  type NotificationTestTargets,
  type NotificationStatsResponse,
  type NotificationTemplateDetail,
  type NotificationTemplateRow,
  type NotificationTimelineResponse,
} from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, ApiError, type Api } from '../src/api';
import { StaffContext, routeOf, routePaths } from '../src/context';
import { messages } from '../src/messages';
import {
  notificationMessageIds,
  notificationsEn,
  notificationsVi,
} from '../src/messages-notifications';
import { allowedRoute } from '../src/Shell';
import { NotificationsScreen, tabBadges } from '../src/screens/notifications';
import {
  NotificationAnalyticsView,
  notificationStatsCsv,
} from '../src/screens/notifications/Analytics';
import { CatalogView } from '../src/screens/notifications/Catalog';
import { DeliveryView, deliveryOutcomes } from '../src/screens/notifications/Delivery';
import { JourneysView, funnelOf, kindsOfScenario } from '../src/screens/notifications/Journeys';
import { OverviewView, overviewHealth } from '../src/screens/notifications/Overview';
import {
  SettingsView,
  policyDiff,
  policyErrors,
  policyFields,
} from '../src/screens/notifications/Settings';
import {
  TemplateEditorView,
  initialSample,
  insertAt,
  sampleValues,
} from '../src/screens/notifications/TemplateEditor';
import { TemplatesView, templateCounts } from '../src/screens/notifications/Templates';
import {
  EntryDetailView,
  TimelineView,
  intentLabel,
  reasonLabel,
  recipientLabel,
  timelineRequest,
  whyLabel,
} from '../src/screens/notifications/Timeline';
import {
  locationOf,
  notificationRates,
  pathOf,
  rate,
  rateText,
  validRange,
  visibleTabs,
} from '../src/screens/notifications/shared';
import { createIntl } from 'react-intl';
import {
  TestResultPanel,
  TestSendView,
  defaultTarget,
  hasDraft,
  memberLabel,
  pollDone,
} from '../src/screens/notifications/TestSend';
import { versionLabel } from '../src/screens/notifications/Timeline';
import { nextStep } from '../src/screens/notifications/TemplateEditor';
import { activeFilterCount, groupByDay } from '../src/screens/notifications/Timeline';
import { levelsForRoles, type StaffRole } from './fixtures';

// Thông báo & Gắn kết (P-174). Server-rendered, no network: callables go to a fake api.
type Call = { name: string; data: unknown };
function fakeApi(answers: Record<string, unknown> = {}) {
  const calls: Call[] = [];
  const api: Api = {
    call: <T,>(name: string, data?: unknown) => {
      calls.push({ name, data });
      return name in answers
        ? Promise.resolve(answers[name] as T)
        : Promise.reject(new ApiError('permission-denied', 'role'));
    },
  };
  return { api, calls };
}

function render(
  node: ReactNode,
  roles: StaffRole[] = ['admin'],
  locale: 'vi' | 'en' = 'vi',
  api: Api = { call: () => new Promise(() => undefined) },
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
    .replace(/\s+/g, ' ')
    .trim();

const intlVi = createIntl({ locale: 'vi', messages: messages.vi });

const tplDetail = (over: Partial<NotificationTemplateDetail> = {}): NotificationTemplateDetail => {
  const def = notificationTemplates['memories.new_moments'];
  return {
    id: def.id,
    kind: def.kind,
    group: 'memories',
    status: 'published',
    draftState: 'none',
    liveVersion: 2,
    latestVersion: 2,
    hasVi: true,
    hasEn: true,
    destination: 'MEMORIES',
    updatedAt: '2026-10-20T03:00:00Z',
    updatedBy: 'Linh Trần',
    sent30d: 120,
    live: def.builtin,
    draft: null,
    draftBy: null,
    submittedBy: null,
    versions: [
      {
        version: 1,
        copy: def.builtin,
        publishedAt: '2026-10-01T03:00:00Z',
        publishedBy: 'Linh Trần',
        note: 'Bản đầu',
      },
      {
        version: 2,
        copy: def.builtin,
        publishedAt: '2026-10-10T03:00:00Z',
        publishedBy: 'Minh',
        note: '',
      },
    ],
    issues: [],
    ...over,
  };
};

const stats = (over: Partial<NotificationStatsResponse> = {}): NotificationStatsResponse => ({
  range: { from: '2026-10-16', to: '2026-10-22' },
  reportingZone: 'Asia/Ho_Chi_Minh',
  computedAt: '2026-10-22T02:00:00Z',
  sourceStartDay: '2026-10-18',
  days: [
    { day: '2026-10-16', totals: {} },
    { day: '2026-10-17', totals: {} },
    {
      day: '2026-10-18',
      totals: {
        created: 10,
        inbox: 9,
        attempted: 8,
        accepted: 7,
        failed: 1,
        opened: 3,
        read: 4,
        navigated: 3,
      },
    },
    {
      day: '2026-10-19',
      totals: { created: 5, inbox: 5, attempted: 5, accepted: 5, opened: 1, read: 1, navigated: 0 },
    },
  ],
  byKind: [
    {
      kind: 'memories',
      counts: { created: 15, inbox: 14, attempted: 13, accepted: 12, failed: 1 },
    },
  ],
  byGroup: [
    {
      group: 'memories',
      counts: {
        created: 15,
        inbox: 14,
        attempted: 13,
        accepted: 12,
        failed: 1,
        opened: 4,
        read: 5,
        navigated: 3,
      },
    },
    { group: 'care', counts: { created: 0 } },
  ],
  byTemplate: [
    {
      templateId: 'memories.new_moments',
      version: 2,
      counts: { created: 15, attempted: 13, accepted: 12 },
    },
  ],
  problems: [
    {
      entry: 'd_0123456789abcdef01234567',
      kind: 'memories',
      delivery: 'failed',
      reason: 'retry_exhausted',
      attempts: 3,
      createdAt: '2026-10-19T03:00:00Z',
      errorCode: 'messaging/internal-error',
      familyCode: 'F-7Q2K',
    },
  ],
  ops: defaultNotificationOpsConfig,
  ...over,
});

const opsResponse = (over: Partial<NotificationOpsResponse> = {}): NotificationOpsResponse => ({
  ops: defaultNotificationOpsConfig,
  engagementPolicy: defaultEngagementPolicy,
  engagementPolicyStored: false,
  ...over,
});

const timeline: NotificationTimelineResponse = {
  family: { code: 'F-7Q2K', babies: 1, members: 3 },
  summary: {
    notifications: 4,
    engagements: 2,
    completed: 1,
    pending: 1,
    suppressed: 1,
    failed: 0,
    lastActivityAt: '2026-10-21T03:00:00Z',
  },
  recipients: [
    { ref: 'm1', role: 'coParent', label: 'Thành viên 1' },
    { ref: 'm2', role: 'relative', label: 'Thành viên 2' },
  ],
  entries: [
    {
      entry: 'd_aaaaaaaaaaaaaaaaaaaaaaaa',
      at: '2026-10-21T03:00:00Z',
      kind: 'photoSuggestion',
      scenario: 'ENG-01',
      group: 'memories',
      recipient: 'm1',
      templateId: 'eng.pending_photos',
      templateVersion: 0,
      channel: 'push_inbox',
      lifecycle: 'persisted',
      delivery: 'accepted',
      read: 'unread',
      action: 'not_started',
      engagementStatus: null,
      reason: null,
      destination: 'MEMORIES_PENDING_REVIEW',
    },
    {
      entry: 'e_bbbbbbbbbbbbbbbbbbbbbbbb',
      at: '2026-10-20T03:00:00Z',
      kind: null,
      scenario: 'ENG-05',
      group: 'family',
      recipient: 'm2',
      templateId: null,
      templateVersion: null,
      channel: 'none',
      lifecycle: null,
      delivery: null,
      read: null,
      action: null,
      engagementStatus: 'suppressed',
      reason: 'fatigue_paused',
      destination: null,
    },
  ],
  nextCursor: 'c1',
  upcoming: [
    {
      scenario: 'ENG-03',
      certainty: 'confirmed',
      state: 'scheduled',
      at: '2026-10-26T02:00:00Z',
      expiresAt: null,
      conditions: [],
      recipient: 'm1',
    },
    {
      scenario: 'ENG-02',
      certainty: 'predicted',
      state: 'waiting',
      at: '2026-11-01T02:00:00Z',
      expiresAt: '2026-11-04T02:00:00Z',
      conditions: ['has_photos'],
      recipient: 'm1',
    },
  ],
  preferences: [
    { recipient: 'm1', muted: ['familyActivity'], engagementConsent: true },
    { recipient: 'm2', muted: [], engagementConsent: null },
  ],
  truncated: true,
};

describe('Thông báo & Gắn kết: route and permissions', () => {
  it('has its own nested route', () => {
    expect(routePaths.notifications).toBe('/notifications');
    expect(routeOf('/notifications/templates/care.rule_due')).toBe('notifications');
    expect(routeOf('/notifications/timeline/F-7Q2K')).toBe('notifications');
  });

  it('opens with view or edit; experts reach Templates only; timeline needs its permission', () => {
    expect(allowedRoute(levelsForRoles(['support']), 'notifications')).toBe('notifications');
    expect(allowedRoute(levelsForRoles(['expert']), 'notifications')).toBe('notifications');
    expect(allowedRoute(levelsForRoles(['qa']), 'notifications')).not.toBe('notifications');
    expect(visibleTabs(levelsForRoles(['expert']))).toEqual(['templates', 'test']);
    expect(visibleTabs(levelsForRoles(['support']))).not.toContain('test');
    expect(visibleTabs(levelsForRoles(['support']))).not.toContain('timeline');
    expect(visibleTabs(levelsForRoles(['ops']))).toContain('timeline');
    expect(visibleTabs(levelsForRoles(['admin']))).toHaveLength(9);
  });

  it('maps addresses to tabs, the editor and a family code', () => {
    const all = visibleTabs(levelsForRoles(['admin']));
    expect(locationOf('/notifications', all)).toEqual({ tab: 'overview' });
    expect(locationOf('/notifications/delivery', all)).toEqual({ tab: 'delivery' });
    expect(locationOf('/notifications/templates/care.rule_due', all)).toEqual({
      tab: 'templates',
      template: 'care.rule_due',
    });
    expect(locationOf('/notifications/timeline/f-7q2k', all)).toEqual({
      tab: 'timeline',
      code: 'F-7Q2K',
    });
    expect(locationOf('/notifications/timeline/F-7Q2K', ['overview'])).toEqual({ tab: 'overview' });
    expect(locationOf('/notifications', ['templates'])).toEqual({ tab: 'templates' });
    expect(pathOf({ tab: 'timeline', code: 'F-7Q2K' })).toBe('/notifications/timeline/F-7Q2K');
    expect(pathOf({ tab: 'overview' })).toBe('/notifications');
  });

  it('a viewer without notifications.timeline gets no timeline tab', () => {
    const support = text(render(<NotificationsScreen initial={{ tab: 'catalog' }} />, ['support']));
    expect(support).not.toContain('Dòng thời gian gia đình');
    expect(support).toContain('Mẫu nội dung');
    const ops = text(render(<NotificationsScreen initial={{ tab: 'catalog' }} />, ['ops']));
    expect(ops).toContain('Dòng thời gian gia đình');
  });
});

describe('Family timeline: nothing loads before a code', () => {
  it('opening the tab calls no callable until a family code is entered', () => {
    const { api, calls } = fakeApi({ staffNotificationTimeline: timeline });
    const t = text(
      render(<NotificationsScreen initial={{ tab: 'timeline' }} />, ['ops'], 'vi', api),
    );
    expect(t).toContain('Mỗi lần xem được ghi vào nhật ký kiểm toán');
    expect(t).toContain('Nhập mã gia đình để xem');
    expect(calls).toEqual([]);
  });
});

describe('Catalog and destinations', () => {
  it('lists every kind, every gap and every destination', () => {
    const html = render(<CatalogView />);
    for (const k of notificationKinds) expect(html).toContain(`data-kind="${k}"`);
    for (const g of notificationCatalogGaps) expect(html).toContain(`data-gap="${g.id}"`);
    for (const d of notificationDestinationIds) expect(html).toContain(`data-destination="${d}"`);
    const t = text(html);
    expect(t).toContain('Chưa gửi trong V1');
    expect(t).toContain('Luôn gửi');
    expect(t).toContain('Hộp thông báo');
  });

  it('renders in English too', () => {
    const t = text(render(<CatalogView />, ['admin'], 'en'));
    expect(t).toContain('Not sent in V1');
    expect(t).toContain('Notification Center');
  });

  it('journeys cover ENG-01…06 with their kinds', () => {
    expect(kindsOfScenario('ENG-04').map((d) => d.kind)).toEqual(['reminderRule']);
    const html = render(<JourneysView data={null} />);
    for (const e of engagementKinds) expect(html).toContain(`data-scenario="${e}"`);
  });
});

describe('Template editor', () => {
  it('renders the sample in the previews and the version history', () => {
    const t = text(render(<TemplateEditorView initial={tplDetail()} onBack={() => undefined} />));
    expect(t).toContain('Có 7 khoảnh khắc mới');
    expect(t).toContain('Mai vừa chia sẻ với gia đình');
    expect(t).toContain('Phiên bản 0 (trong mã)');
    expect(t).toContain('Tên thành viên gia đình');
    expect(t).toContain('Lưu nháp');
  });

  it('shows validation issues inline', () => {
    const def = notificationTemplates['memories.new_moments'];
    const bad = tplDetail({
      draftState: 'draft',
      draft: { vi: { title: 'Có {{baby_dob}}', body: '' }, en: def.builtin.en },
    });
    const t = text(render(<TemplateEditorView initial={bad} onBack={() => undefined} />));
    expect(t).toContain('Biến “baby_dob” không tồn tại.');
    expect(t).toContain('Không được để trống.');
  });

  it('a viewer without notifications.edit sees no Save, an expert can publish', () => {
    const viewer = text(
      render(<TemplateEditorView initial={tplDetail()} onBack={() => undefined} />, ['support']),
    );
    expect(viewer).not.toContain('Lưu nháp');
    expect(viewer).toContain('Bạn chỉ xem được mẫu này');
    const review = tplDetail({
      draftState: 'ready_for_review',
      draft: notificationTemplates['memories.new_moments'].builtin,
    });
    const expert = text(
      render(<TemplateEditorView initial={review} onBack={() => undefined} />, ['expert']),
    );
    expect(expert).toMatch(/ Xuất bản (?!lúc)/);
    const ops = text(
      render(<TemplateEditorView initial={review} onBack={() => undefined} />, ['ops']),
    );
    expect(ops).not.toMatch(/ Xuất bản (?!lúc)/);
  });

  it('explains a paused template', () => {
    const t = text(
      render(
        <TemplateEditorView initial={tplDetail({ status: 'paused' })} onBack={() => undefined} />,
      ),
    );
    expect(t).toContain('Mẫu đang tạm dừng');
    expect(t).toContain('Dùng lại');
  });

  it('inserts at the cursor and renders sample values', () => {
    expect(insertAt('Có  mới', '{{count}}', 3, 3)).toEqual({
      text: 'Có {{count}} mới',
      cursor: 12,
    });
    expect(insertAt('abc', '{{x}}', null, null).text).toBe('abc{{x}}');
    const def = notificationTemplates['memories.new_moments'];
    const s = initialSample(def);
    expect(sampleValues(def, s, 'vi')).toEqual({ count: 7, actor_name: 'Mai', baby_name: 'Bin' });
    expect(sampleValues(def, { ...s, actor_name: { vi: '', en: '' } }, 'vi')).toEqual({
      count: 7,
      baby_name: 'Bin',
    });
  });

  it('the list shows status, draft and live version', () => {
    const row: NotificationTemplateRow = { ...tplDetail(), draftState: 'ready_for_review' };
    const t = text(render(<TemplatesView rows={[row]} onOpen={() => undefined} />));
    expect(t).toContain('Khoảnh khắc mới');
    expect(t).toContain('Nháp chờ duyệt');
    expect(t).toContain('v2');
    expect(t).toContain('Đang dùng');
  });
});

describe('Delivery, overview, analytics and settings', () => {
  it('rates: a zero denominator is “—”, never 0 %', () => {
    expect(rate(0, 0)).toBeNull();
    expect(rate(3, 0)).toBeNull();
    expect(rate(1, 4)).toBe(0.25);
    expect(rateText(intlVi, null)).toBe('—');
    const rates = notificationRates({ attempted: 0, inbox: 10, opened: 0, read: 5 });
    expect(rates.find((r) => r.id === 'acceptance')!.value).toBeNull();
    expect(rates.find((r) => r.id === 'navigation')!.value).toBeNull();
    expect(rates.find((r) => r.id === 'read')!.value).toBe(0.5);
    expect(rates.find((r) => r.id === 'open')!.value).toBe(0);
  });

  it('ranges stay within 92 days and not after today', () => {
    const now = new Date('2026-10-22T05:00:00Z');
    expect(validRange('2026-08-01', '2026-10-22', now)).toBe(true);
    expect(validRange('2026-07-01', '2026-10-22', now)).toBe(false);
    expect(validRange('2026-10-20', '2026-10-23', now)).toBe(false);
    expect(validRange('2026-10-21', '2026-10-20', now)).toBe(false);
  });

  it('overview counts only days with data and says accepted ≠ delivered', () => {
    const t = text(render(<OverviewView data={stats()} />));
    expect(t).toContain('không chứng minh thông báo đã hiện trên máy');
    expect(t).toMatch(/Đã tạo .*15/);
  });

  it('an empty range says so instead of showing zeros', () => {
    const t = text(
      render(<OverviewView data={stats({ sourceStartDay: null, days: [], problems: [] })} />),
    );
    expect(t).toContain('Chưa có dữ liệu gửi trong khoảng này');
    const a = text(
      render(<NotificationAnalyticsView data={stats({ sourceStartDay: null, days: [] })} />),
    );
    expect(a).toContain('Chưa có dữ liệu gửi trong khoảng này');
  });

  it('delivery lists problems; Retry needs notifications.ops', () => {
    const admin = text(render(<DeliveryView data={stats()} onTimeline={() => undefined} />));
    expect(admin).toContain('Thử gửi lại');
    expect(admin).toContain('F-7Q2K');
    expect(admin).toContain('Hết lượt thử lại');
    const support = text(render(<DeliveryView data={stats()} />, ['support']));
    expect(support).not.toContain('Thử gửi lại');
  });

  it('analytics shows rates with numerator/denominator, partial-data notice and CSV', () => {
    const t = text(render(<NotificationAnalyticsView data={stats()} />));
    expect(t).toContain('Tỉ lệ nhà cung cấp nhận');
    expect(t).toContain('12 / 13');
    expect(t).toContain('chưa có dữ liệu');
    const csv = notificationStatsCsv(stats());
    // Days before the ledger are empty cells, not 0.
    expect(csv.split('\r\n')[1]).toContain('"2026-10-16",""');
    expect(csv).toContain('"memories.new_moments@2"');
    expect(text(render(<NotificationAnalyticsView data={stats()} />, ['admin']))).toContain(
      'Xuất CSV',
    );
    expect(text(render(<NotificationAnalyticsView data={stats()} />, ['support']))).not.toContain(
      'Xuất CSV',
    );
  });

  it('settings: read-only without notifications.ops, care pause warns', () => {
    const ro = text(render(<SettingsView data={opsResponse()} />, ['support']));
    expect(ro).toContain('Bạn chỉ xem được các công tắc');
    expect(ro).not.toContain('Lưu công tắc');
    const paused = text(
      render(
        <SettingsView
          data={opsResponse({
            ops: {
              ...defaultNotificationOpsConfig,
              pushPaused: { ...defaultNotificationOpsConfig.pushPaused, care: true },
            },
          })}
        />,
      ),
    );
    expect(paused).toContain('Push Chăm sóc đang tạm dừng');
    expect(paused).toContain('Lưu công tắc');
  });
});

describe('Family timeline', () => {
  it('renders entries, masked recipients, upcoming confirmed vs predicted, preferences', () => {
    const html = render(
      <TimelineView
        data={timeline}
        entries={timeline.entries}
        recipients={timeline.recipients}
        onOpen={() => undefined}
        onMore={() => undefined}
      />,
    );
    const t = text(html);
    expect(t).toContain('Cùng nuôi 1');
    expect(t).toContain('Người thân 2');
    expect(t).not.toContain('Thành viên 1');
    expect(t).not.toContain('linh@example.com');
    expect(t).toContain('Ảnh chờ chọn');
    expect(t).toContain('Nhà cung cấp đã nhận');
    expect(t).toContain('Tạm dừng vì gửi nhiều');
    expect(html).toContain('data-certainty="confirmed"');
    expect(html).toContain('data-certainty="predicted"');
    expect(t).toContain('Đã xác nhận');
    expect(t).toContain('Dự đoán');
    expect(t).toContain('Hoạt động của gia đình');
    expect(t).toContain('Chưa chọn');
    expect(t).toContain('Tải thêm');
    expect(t).toContain('nhiều dòng hơn số đã quét');
  });

  it('builds the request and labels reasons', () => {
    const req = timelineRequest(
      'F-7Q2K',
      { from: '2026-10-01', to: '2026-10-22' },
      {
        view: 'engagement',
        group: 'all',
        kind: 'all',
        scenario: 'ENG-01',
        delivery: 'all',
        recipient: 'm1',
      },
      'c1',
    );
    expect(req).toEqual({
      code: 'F-7Q2K',
      from: '2026-10-01',
      to: '2026-10-22',
      view: 'engagement',
      group: 'all',
      kind: 'all',
      scenario: 'ENG-01',
      delivery: 'all',
      recipient: 'm1',
      cursor: 'c1',
    });
    expect(reasonLabel(intlVi, 'quiet_hours')).toBe('Giờ yên tĩnh');
    expect(reasonLabel(intlVi, 'brand_new_reason')).toBe('brand_new_reason');
    expect(reasonLabel(intlVi, null)).toBe('—');
  });

  it('the detail drawer explains checks, decision and outcome', () => {
    const d: NotificationEntryDetail = {
      entry: 'd_aaaaaaaaaaaaaaaaaaaaaaaa',
      scenario: 'ENG-01',
      kind: 'photoSuggestion',
      why: 'pending ≥ 24h',
      checks: [
        { rule: 'consent', result: 'pass' },
        { rule: 'quiet_hours', result: 'fail', detail: '22:00–06:00' },
        { rule: 'fatigue', result: 'unknown' },
      ],
      decision: 'send',
      reason: 'none',
      templateId: 'eng.pending_photos',
      templateVersion: 0,
      destination: 'MEMORIES_PENDING_REVIEW',
      timeline: [
        { at: '2026-10-21T03:00:00Z', dimension: 'delivery', to: 'accepted', reason: null },
      ],
      pushAttempted: true,
      providerAccepted: true,
      opened: false,
      navigated: null,
      completed: null,
      cancelledOrExpired: null,
      errors: ['messaging/registration-token-not-registered'],
    };
    const t = text(render(<EntryDetailView detail={d} />));
    expect(t).toContain('Đạt');
    expect(t).toContain('Không đạt');
    expect(t).toContain('Không rõ');
    expect(t).toContain('Gửi → Nhà cung cấp đã nhận');
    expect(t).toContain('Tự lưu · Ảnh chờ chọn');
    expect(t).toContain('messaging/registration-token-not-registered');
  });
});

const serverRules = [
  'feature_enabled',
  'authorized',
  'source_open',
  'not_dismissed',
  'not_sent_before',
  'window_open',
  'source_verified',
  'not_fatigued',
  'consent_and_category',
  'post_completion_quiet',
  'not_holdout',
  'not_grouped',
  'due',
  'outside_quiet_hours',
  'within_caps',
  'setting_on',
  'push_not_paused',
  'device_registered',
];
const serverConditions = [
  'flag',
  'consent',
  'category',
  'device_lease',
  'fresh_source',
  'caps',
  'quiet_hours',
  'ready_photos',
  'usable_template',
  'no_keepsake',
  'saved_this_week',
  'rule_enabled',
  'recipient_member',
  'reminders_setting',
  'unseen_family_content',
  'personal_day_ready',
  'seven_day_spacing',
];

describe('server codes in the timeline', () => {
  it('every check rule and upcoming condition has a label in both languages', () => {
    for (const r of serverRules) {
      expect(notificationsVi[`ntf.rule.${r}`], r).toBeTruthy();
      expect(notificationsEn[`ntf.rule.${r}`], r).toBeTruthy();
    }
    for (const c of serverConditions) {
      expect(notificationsVi[`ntf.condition.${c}`], c).toBeTruthy();
      expect(notificationsEn[`ntf.condition.${c}`], c).toBeTruthy();
    }
  });

  it('labels why, decisions, recipients; unknown codes stay raw', () => {
    expect(whyLabel(intlVi, 'ENG-01:pending')).toBe('ENG-01 Ảnh chờ chọn · Ảnh đang chờ chọn');
    expect(whyLabel(intlVi, 'care.rules')).toBe('Nhắc việc (quy tắc)');
    expect(whyLabel(intlVi, 'something_new')).toBe('something_new');
    expect(intentLabel(intlVi, 'in_app_only')).toBe('Chỉ hiện trong app');
    expect(intentLabel(intlVi, 'retry_pending')).toBe('Chờ thử lại');
    expect(intentLabel(intlVi, 'mystery')).toBe('mystery');
    expect(recipientLabel(intlVi, timeline.recipients, 'm1')).toBe('Cùng nuôi 1');
    expect(recipientLabel(intlVi, timeline.recipients, 'former')).toBe('Không còn trong gia đình');
  });

  it('the drawer labels rules, reason details and delivery errors', () => {
    const t = text(
      render(
        <EntryDetailView
          detail={{
            entry: 'e_cccccccccccccccccccccccc',
            scenario: 'ENG-03',
            kind: 'weeklySummary',
            why: 'ENG-03:week',
            checks: [{ rule: 'not_fatigued', result: 'fail', detail: 'fatigue_paused' }],
            decision: 'suppressed',
            reason: 'fatigue_paused',
            templateId: null,
            templateVersion: null,
            destination: null,
            timeline: [],
            pushAttempted: false,
            providerAccepted: null,
            opened: null,
            navigated: null,
            completed: null,
            cancelledOrExpired: null,
            errors: ['delivery_unknown', 'messaging/internal-error'],
          }}
        />,
      ),
    );
    expect(t).toContain('Không gửi quá nhiều');
    expect(t).toContain('Tạm dừng vì gửi nhiều');
    expect(t).toContain('Nhìn lại tuần · Tuần đã đóng');
    expect(t).toContain('Kết quả gửi không rõ');
    expect(t).toContain('messaging/internal-error');
  });
});

describe('message catalog (D-012)', () => {
  it('vi and en carry the same ids, none empty, none defined twice', () => {
    expect(Object.keys(notificationsEn).sort()).toEqual(Object.keys(notificationsVi).sort());
    expect(new Set(notificationMessageIds).size).toBe(notificationMessageIds.length);
    for (const v of [...Object.values(notificationsVi), ...Object.values(notificationsEn)])
      expect(v.trim()).not.toBe('');
  });

  it('every enum the screens label has a message', () => {
    for (const k of notificationKinds) expect(notificationsVi[`ntf.kind.${k}`], k).toBeTruthy();
    for (const e of engagementKinds) expect(notificationsVi[`ntf.eng.${e}`], e).toBeTruthy();
    for (const g of notificationCatalogGaps)
      expect(notificationsVi[`ntf.gap.${g.id}`], g.id).toBeTruthy();
    const families: Array<[string, readonly string[]]> = [
      ['ntf.group', inboxGroups],
      ['ntf.delivery', notificationDeliveryStates],
      ['ntf.reason', notificationDeliveryReasons],
      ['ntf.lifecycle', notificationLifecycleStates],
      ['ntf.read', notificationReadStates],
      ['ntf.action', notificationActionStates],
      ['ntf.tplStatus', notificationTemplateStatuses],
      ['ntf.metric', notificationStatMetrics],
      ['ntf.setting', notificationSettingKeys],
      ['ntf.producer', notificationProducers],
      ['ntf.stage', engagementStages],
      ['ntf.engReason', engagementReasonCodes],
      ['ntf.channel', ['push_inbox', 'inbox', 'in_app', 'none']],
      ['ntf.eng.outcome', engagementOutcomes],
      ['ntf.eng.check', engagementHealthSignalIds],
      ['ntf.health.signal.eng', engagementHealthSignalIds],
    ];
    for (const [prefix, values] of families)
      for (const v of values)
        expect(notificationsEn[`${prefix}.${v}`], `${prefix}.${v}`).toBeTruthy();
    expect(notificationsVi['nav.notifications']).toBe('Thông báo & Gắn kết');
    expect(notificationsVi['auditCategory.notifications']).toBe('Thông báo');
  });
});

// D-092: engagement policy panel, G-109 membership kinds and the UI review's pure helpers.
describe('D-092 additions', () => {
  it('G-109 membership kinds are in the catalog with labels', () => {
    for (const k of ['memberJoined', 'inviteDeclined', 'roleChanged', 'memberRemoved']) {
      expect(notificationsVi[`ntf.kind.${k}`], k).toBeTruthy();
      expect(notificationsEn[`ntf.kind.${k}`], k).toBeTruthy();
    }
    expect(notificationsVi['ntf.producer.family.members']).toBeTruthy();
    expect(notificationsVi['ntf.setting.familyMembers']).toBeTruthy();
    const html = render(<CatalogView />);
    expect(html).toContain('data-kind="memberJoined"');
    expect(html).toContain('data-destination="FAMILY_MEMBERS"');
    expect(text(html)).toContain('Thành viên gia đình');
    expect(html).not.toContain('data-gap="family.role_changed"');
  });

  it('overview health: no data, ok, attention signals', () => {
    expect(overviewHealth(stats({ sourceStartDay: null, days: [], problems: [] })).level).toBe(
      'no_data',
    );
    const ok = overviewHealth(
      stats({
        problems: [],
        days: [{ day: '2026-10-18', totals: { attempted: 100, accepted: 99, failed: 1 } }],
      }),
    );
    expect(ok.level).toBe('ok');
    expect(ok.failureRate).toBe(0.01);
    const bad = overviewHealth(
      stats({
        days: [{ day: '2026-10-18', totals: { attempted: 50, failed: 2, render_error: 1 } }],
        problems: [{ ...stats().problems[0]!, delivery: 'retry_pending' }],
        ops: {
          ...defaultNotificationOpsConfig,
          pushPaused: { ...defaultNotificationOpsConfig.pushPaused, care: true },
        },
      }),
    );
    expect(bad.level).toBe('attention');
    expect(bad.signals.map((s) => s.id)).toEqual(['failure', 'backlog', 'render', 'paused']);
    const t = text(render(<OverviewView data={stats()} reviewCount={2} />));
    expect(t).toContain('Cần chú ý');
    expect(t).toContain('Bản nháp chờ duyệt');
  });

  // Owner, 2026-10-26: 0 % failures while suggestions never became pushes.
  it('overview: what never became a push raises attention and lists the families', () => {
    const engagement: EngagementHealthResponse = {
      range: { from: '2026-10-20', to: '2026-10-26' },
      computedAt: '2026-10-26T05:00:00.000Z',
      outcomes: { pushed: 1, in_app_only: 9, held: 0, closed: 2, expired: 0, pending: 1 },
      reasons: { channel_unavailable: 9, source_resolved: 2 },
      signals: [
        { id: 'channel_unavailable', n: 9, families: ['F-AB23'] },
        { id: 'permission_mismatch', n: 1, families: ['F-AB23'] },
      ],
      daily: [],
      truncated: false,
    };
    const ok = stats({
      problems: [],
      days: [{ day: '2026-10-18', totals: { attempted: 100, accepted: 100 } }],
    });
    expect(overviewHealth(ok).level).toBe('ok');
    const h = overviewHealth(ok, ok.ops, engagement);
    expect(h.level).toBe('attention');
    expect(h.signals.map((s) => s.id)).toEqual([
      'eng.channel_unavailable',
      'eng.permission_mismatch',
    ]);
    const t = text(
      render(
        <OverviewView data={ok} engagement={engagement} canTimeline onTimeline={() => undefined} />,
      ),
    );
    expect(t).toContain('Cần chú ý');
    expect(t).toContain('9 gợi ý chỉ hiện trong app vì không có kênh push.');
    expect(t).toContain('Gợi ý thông minh trước khi gửi');
    expect(t).toContain('Chỉ hiện trong app');
    expect(t).toContain('Quyền thông báo bị báo sai');
    expect(t).toContain('F-AB23');
    expect(t).toContain('Đóng trước ngày');
  });

  it('settings show the policy panel, its safe-default notice and read-only state', () => {
    const t = text(render(<SettingsView data={opsResponse()} />));
    expect(t).toContain('Chính sách Gợi ý thông minh');
    expect(t).toContain('Hệ thống đang chạy với mặc định an toàn (tắt)');
    expect(t).toContain('Thời hạn thiết bị nhận gợi ý');
    expect(t).toContain('Lưu chính sách');
    const stored = text(
      render(
        <SettingsView
          data={opsResponse({
            engagementPolicyStored: true,
            engagementPolicy: { ...defaultEngagementPolicy, approved: true },
          })}
        />,
      ),
    );
    expect(stored).not.toContain('mặc định an toàn');
    expect(stored).toContain('Chính sách đã duyệt');
    const ro = render(<SettingsView data={opsResponse()} />, ['support']);
    expect(ro).not.toContain('>Lưu chính sách<');
    expect(render(<SettingsView data={opsResponse()} />)).toContain('>Lưu chính sách<');
  });

  it('policy bounds, diff and validation follow the contract', () => {
    const keys = policyFields.map((f) => f.key);
    expect(keys).toContain('deviceLeaseDays');
    const d = policyFields.find((f) => f.key === 'deviceLeaseDays')!;
    expect([d.min, d.max]).toEqual([1, 60]);
    const after = {
      ...defaultEngagementPolicy,
      approved: true,
      weeklyCap: 2,
      quietDefault: { from: '21:30', to: '07:00' },
    };
    expect(policyDiff(defaultEngagementPolicy, after)).toEqual([
      { field: 'approved', before: 'false', after: 'true' },
      { field: 'weeklyCap', before: '3', after: '2' },
      { field: 'quiet.from', before: '22:00', after: '21:30' },
    ]);
    expect(policyErrors(after).size).toBe(0);
    const bad = policyErrors({
      ...after,
      weeklyCap: 4,
      deviceLeaseDays: Number.NaN,
      quietDefault: { from: '25:00', to: '07:00' },
    });
    expect([...bad].sort()).toEqual(['deviceLeaseDays', 'quiet.from', 'weeklyCap']);
    for (const f of policyFields) {
      expect(notificationsVi[`ntf.policy.${f.key}`], f.key).toBeTruthy();
      expect(notificationsEn[`ntf.policy.${f.key}.note`], f.key).toBeTruthy();
    }
  });

  it('pure helpers: badges, counts, workflow step, outcomes, funnel, day groups, filters', () => {
    const row = (draftState: NotificationTemplateRow['draftState']): NotificationTemplateRow => ({
      ...tplDetail(),
      draftState,
    });
    expect(tabBadges(stats(), [row('ready_for_review'), row('none')])).toEqual({
      delivery: { n: 1, tone: 'error' },
      templates: { n: 1, tone: 'warn' },
    });
    expect(tabBadges(stats({ problems: [] }), [])).toEqual({});
    expect(templateCounts([row('draft'), row('ready_for_review')])).toMatchObject({
      drafts: 1,
      review: 1,
      published: 2,
    });
    expect(nextStep({ draftState: 'draft' }, true, 0, true, false)).toBe('save');
    expect(nextStep({ draftState: 'draft' }, false, 0, true, false)).toBe('submit');
    expect(nextStep({ draftState: 'draft' }, false, 2, true, false)).toBeNull();
    expect(nextStep({ draftState: 'ready_for_review' }, false, 0, false, true)).toBe('publish');
    expect(
      deliveryOutcomes({ accepted: 5, muted: 1, held: 2, no_device: 1, failed: 1, rejected: 2 }),
    ).toEqual({ accepted: 5, notPushed: 4, failed: 3, unknown: 0 });
    expect(funnelOf(undefined)).toBeNull();
    expect(funnelOf({ eligible: 0 })).toBeNull();
    const f = funnelOf({ eligible: 10, scheduled: 8, accepted: 6, opened: 3, completed: null })!;
    expect(f.map((x) => x.ratio)).toEqual([1, 0.8, 0.6, 0.3, 0]);
    expect(f[4]!.n).toBeNull();
    expect(groupByDay(timeline.entries).map((g) => g.day)).toEqual(['2026-10-21', '2026-10-20']);
    expect(
      activeFilterCount({
        view: 'engagement',
        group: 'all',
        kind: 'all',
        scenario: 'ENG-01',
        delivery: 'all',
        recipient: 'm1',
      }),
    ).toBe(3);
  });

  it('journeys show an honest state when analytics is disabled', () => {
    const t = text(
      render(
        <JourneysView
          data={{
            schemaVersion: 2,
            definitionVersion: 1,
            section: 'engagement',
            range: { from: '2026-09-22', to: '2026-10-21' },
            reportingZone: 'Asia/Ho_Chi_Minh',
            status: 'disabled',
            computedAt: null,
            observedThrough: null,
            sourceStartAt: null,
            collectionEnabled: false,
            stale: false,
            privacyThreshold: 5,
            unsupportedFilters: [],
            metrics: [],
            series: [],
            retention: [],
            breakdowns: [],
            engagement: [],
            quality: { unknownActor: null, lateObservations: null, sourceCoverage: 'none' },
          }}
        />,
      ),
    );
    expect(t).toContain('Đo lường Gợi ý thông minh đang tắt');
    expect(t).toContain('không có phễu');
  });
});

// D-092: Gửi thử — a real push to the staff member's own phone, dev only.
describe('Gửi thử (D-092)', () => {
  const targets = (over: Partial<NotificationTestTargets> = {}): NotificationTestTargets => ({
    enabled: true,
    families: [
      {
        code: 'F-7Q2K',
        mine: true,
        internal: false,
        babies: 2,
        members: [
          { ref: 'm1', role: 'coParent', me: true, devices: 1 },
          { ref: 'm2', role: 'relative', me: false, devices: 0 },
        ],
      },
      {
        code: 'F-TEST',
        mine: false,
        internal: true,
        babies: 1,
        members: [{ ref: 'm1', role: 'caregiver', me: false, devices: 2 }],
      },
    ],
    usedThisHour: 3,
    ...over,
  });

  it('outside dev it only explains why', () => {
    const t = text(render(<TestSendView targets={targets({ enabled: false })} rows={null} />));
    expect(t).toContain('Chỉ có trên môi trường dev');
    expect(t).not.toContain('Gửi thử Đã gửi');
    expect(
      render(<TestSendView targets={targets({ enabled: false })} rows={null} />),
    ).not.toContain('data-family');
  });

  it('the form lists families with mine / internal badges and members with "Bạn"', () => {
    const html = render(<TestSendView targets={targets()} rows={[]} />);
    const t = text(html);
    expect(html).toContain('data-family="F-7Q2K"');
    expect(html).toContain('data-family="F-TEST"');
    expect(t).toContain('Gia đình của bạn');
    expect(t).toContain('Nội bộ');
    expect(t).toContain('Cùng nuôi 1');
    expect(t).toContain('Bạn');
    expect(t).toContain('Người thân 2');
    expect(t).toContain('Đã gửi 3/20 trong giờ này');
    expect(t).toContain('Bé 1');
    // The first template has no draft: the draft option is disabled.
    expect(html).toMatch(/<input(?=[^>]*value="draft")(?=[^>]*disabled="")[^>]*>/);
    expect(t).toContain('Mẫu này chưa có bản nháp.');
  });

  it('helpers: draft detection, default target, member label, polling end', () => {
    const row = { ...tplDetail(), draftState: 'draft' as const };
    expect(hasDraft([row], 'memories.new_moments')).toBe(true);
    expect(hasDraft([row], 'care.rule_due')).toBe(false);
    expect(hasDraft(null, 'memories.new_moments')).toBe(false);
    expect(defaultTarget(targets())).toEqual({ code: 'F-7Q2K', recipient: 'm1' });
    expect(defaultTarget(targets({ families: [targets().families[1]!] }))).toEqual({
      code: 'F-TEST',
      recipient: 'm1',
    });
    expect(memberLabel(intlVi, { ref: 'm2', role: 'relative' })).toBe('Người thân 2');
    expect(pollDone(null, 0)).toBe(false);
    expect(pollDone(null, 40)).toBe(true);
    expect(pollDone({ navigated: 'fallback' } as NotificationEntryDetail, 3)).toBe(true);
  });

  it('the result panel shows destination, ids, missing params and acceptance', () => {
    const result: NotificationTestResult = {
      code: 'F-7Q2K',
      entry: 'd_0123456789abcdef01234567',
      inboxId: 'n_test_123456',
      kind: 'album',
      destination: 'MEMORIES_ALBUM',
      params: { babyId: 'baby_1', albumId: 'alb_42' },
      missing: ['albumId'],
      templateVersion: 'draft',
      devices: 1,
      accepted: 1,
      testSuggestion: false,
    };
    const html = render(<TestResultPanel result={result} />);
    const t = text(html);
    expect(t).toContain('Album');
    expect(t).toContain('alb_42');
    expect(t).toContain('Không có albumId cho bé này');
    expect(t).toContain('Nhà cung cấp đã nhận 1/1 thiết bị');
    expect(t).toContain('Bản nháp');
    expect(t).toContain('Theo dõi trực tiếp');
  });

  it('the timeline marks test sends and draft versions', () => {
    expect(versionLabel(intlVi, -1)).toBe('Bản nháp');
    expect(versionLabel(intlVi, 'draft')).toBe('Bản nháp');
    expect(versionLabel(intlVi, 0)).toBe('v0 · trong mã');
    const entries = [{ ...timeline.entries[0]!, test: true, templateVersion: -1 }];
    const t = text(
      render(
        <TimelineView
          data={{ ...timeline, entries }}
          entries={entries}
          recipients={timeline.recipients}
          onOpen={() => undefined}
        />,
      ),
    );
    expect(t).toContain('Thử');
    expect(t).toContain('Bản nháp');
  });

  it('every Gửi thử error reason has a label in both languages', () => {
    for (const r of [
      'dev-only',
      'test-recipient',
      'no-draft',
      'rate-limited',
      'not-a-member',
      'not-found',
    ]) {
      expect(notificationsVi[`ntf.error.${r}`], r).toBeTruthy();
      expect(notificationsEn[`ntf.error.${r}`], r).toBeTruthy();
    }
    expect(Object.keys(notificationsEn).sort()).toEqual(Object.keys(notificationsVi).sort());
  });
});
