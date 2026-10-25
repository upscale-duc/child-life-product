import {
  aiConsentVersion,
  aiReportProblems,
  aiSummaryLimits,
  aiSummaryPromptVersion,
  appEventDims,
  defaultEntitlementsConfig,
  keepsakeJobErrors,
  keepsakeJobStatuses,
  keepsakeJobSteps,
  quotaFeatures,
  type StaffAiPolicy,
  type StaffFamilyQuota,
  type StaffRenderOps,
} from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, ApiError, type Api, type StaffPremiumView } from '../src/api';
import { StaffContext } from '../src/context';
import { messages } from '../src/messages';
import { allowedRoute } from '../src/Shell';
import { JobKinds, JobsScreen } from '../src/screens/Jobs';
import { PremiumPlanView } from '../src/screens/Premium';
import {
  AiPolicyView,
  FamilyQuotaView,
  RenderOpsView,
  aiSwitchNote,
} from '../src/screens/PremiumOps';
import { levelsForRoles, type StaffRole } from './fixtures';

// Premium operations on the portal (plan §5.6, brief "Portal cần thêm"): Tính năng & Premium ›
// Gói Premium › Chính sách AI, a family's Lượt dùng & thanh toán, and Yêu cầu dữ liệu › Video
// kỷ niệm. Server-rendered, no network:
// callables go to a fake api that records them.
const now = new Date('2026-10-15T05:00:00Z');

const days = Array.from({ length: 30 }, (_, i) => ({
  day: new Date(Date.UTC(2026, 8, 16 + i)).toISOString().slice(0, 10),
  generated: i === 29 ? 10 : 0,
  ai: i === 29 ? 6 : 0,
  cache: i === 29 ? 1 : 0,
  fallback: i === 29 ? 3 : 0,
}));

const policy: StaffAiPolicy = {
  provider: { name: 'openai', model: 'gpt-4.1-mini' },
  consentVersion: aiConsentVersion,
  promptVersion: aiSummaryPromptVersion,
  limits: { ...aiSummaryLimits },
  flag: { enabled: true, scope: 'internal', percent: 0, families: 2 },
  quotas: { perBabyPerDay: 2, perFamilyPerMonth: 20, stored: true },
  budget: { monthlyBudgetVnd: 1_000_000, month: '2026-10', spentVnd: 250_000 },
  days,
  totals: { generated: 10, ai: 6, cache: 1, fallback: 3, fallbackRate: 0.3, technicalRate: 0.1 },
  fallbackReasons: [
    { reason: 'QUOTA_EXCEEDED', count: 2 },
    { reason: 'timeout', count: 1 },
  ],
  reports: {
    open: 3,
    byProblem: { wrong_fact: 2, wrong_person: 0, unsafe_advice: 1, language: 0, other: 0 },
  },
};

const quota: StaffFamilyQuota = {
  code: 'F-7Q2K',
  windows: [
    {
      window: 'video_cal_2026-10',
      feature: 'video',
      scope: 'calendar_month',
      limit: 1,
      used: 0,
      reserved: 1,
      startsAt: '2026-09-30T17:00:00.000Z',
      resetsAt: '2026-10-31T17:00:00.000Z',
      open: true,
    },
    {
      window: 'ai_day_B-K3QZ_2026-10-15',
      feature: 'ai_day',
      scope: 'day',
      limit: 1,
      used: 1,
      reserved: 0,
      startsAt: '2026-10-14T17:00:00.000Z',
      resetsAt: '2026-10-15T17:00:00.000Z',
      open: true,
    },
    {
      window: 'video_paid_paid_apple_aaaaaaaa…_2026-09-01',
      feature: 'video',
      scope: 'paid',
      limit: 5,
      used: 2,
      reserved: 0,
      startsAt: '2026-09-01T00:00:00.000Z',
      resetsAt: '2026-10-01T00:00:00.000Z',
      open: false,
    },
  ],
  held: 1,
  accounts: [
    {
      id: 'apple_aaaaaaaa…',
      provider: 'apple',
      productId: 'premium.monthly',
      status: 'active',
      validUntil: '2026-11-01T00:00:00.000Z',
      environment: 'test',
      autoRenew: true,
      boundAt: '2026-09-01T00:00:00.000Z',
      fetchedAt: '2026-10-01T00:00:00.000Z',
    },
  ],
  events: [
    {
      provider: 'apple',
      type: 'DID_RENEW',
      outcome: 'active',
      at: '2026-10-01T00:00:00.000Z',
      processedAt: '2026-10-01T00:00:00.000Z',
    },
    {
      provider: 'apple',
      type: 'SUBSCRIBED.INITIAL_BUY',
      outcome: null,
      at: '2026-09-01T00:00:00.000Z',
      processedAt: null,
    },
  ],
};

const render: StaffRenderOps = {
  kpis: { active: 1, failed24h: 1, completed24h: 1, ledgerIssues: 1 },
  failures: { 'render-failed': 1 },
  jobs: [
    {
      code: 'KJ-3C3C',
      family: 'F-7Q2K',
      templateId: 'ch1-birthday',
      templateVersion: 3,
      status: 'rendering',
      step: 'compose',
      progress: 0.4,
      attempts: 1,
      lease: 1,
      error: null,
      reservation: {
        id: 'video_ksj_33333333…_1',
        window: 'video_cal_2026-10',
        seq: 1,
        state: 'reserved',
        issue: null,
      },
      createdAt: '2026-10-15T04:00:00.000Z',
      updatedAt: '2026-10-15T04:01:00.000Z',
      startedAt: '2026-10-15T04:01:00.000Z',
      finishedAt: null,
    },
    {
      code: 'KJ-1A1A',
      family: 'F-7Q2K',
      templateId: 'ch1-birthday',
      templateVersion: 3,
      status: 'failed',
      step: null,
      progress: 0,
      attempts: 2,
      lease: 2,
      error: 'render-failed',
      reservation: {
        id: 'video_ksj_11111111…_0',
        window: 'video_cal_2026-10',
        seq: 0,
        state: 'reserved',
        issue: 'not-released',
      },
      createdAt: '2026-10-15T01:00:00.000Z',
      updatedAt: '2026-10-15T01:20:00.000Z',
      startedAt: '2026-10-15T01:01:00.000Z',
      finishedAt: '2026-10-15T01:20:00.000Z',
    },
  ],
};

const view: StaffPremiumView = {
  config: defaultEntitlementsConfig,
  stored: true,
  environment: 'test',
  recent: [],
};

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

function html(
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
const text = (raw: string) =>
  raw
    .replace(/<[^>]+>/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#x27;/g, "'")
    .replace(/\s+/g, ' ');
/** Buttons in the markup, by their text. */
const buttons = (raw: string) =>
  [...raw.matchAll(/<button[^>]*>(.*?)<\/button>/g)].map((m) => text(m[1]!).trim());

describe('Premium › AI', () => {
  it('renders the policy the server returns', async () => {
    const { api, calls } = fakeApi({ staffAiPolicy: policy });
    const data = await api.call<StaffAiPolicy>('staffAiPolicy');
    expect(calls).toEqual([{ name: 'staffAiPolicy', data: undefined }]);
    const raw = html(<AiPolicyView data={data} onOpenLimits={() => {}} />, ['ops']);
    const t = text(raw);
    expect(t).toContain('kiểm tra thủ công song ngữ (vi và en)');
    expect(t).toContain('OpenAI');
    expect(t).toContain('gpt-4.1-mini');
    expect(t).toContain(aiConsentVersion);
    expect(t).toContain(aiSummaryPromptVersion);
    expect(t).toContain('Đang bật cho gia đình nội bộ và 2 gia đình được chọn');
    expect(t).toContain('AI · mỗi bé mỗi ngày 2 lượt');
    expect(t).toContain('AI · mỗi gia đình mỗi tháng 20 lượt');
    expect(t).toContain('Tóm tắt 30 ngày 10');
    expect(t).toContain('6 từ mô hình · 1 từ bộ nhớ đệm');
    expect(t).toContain('Tỉ lệ dùng mẫu 30%');
    expect(t).toContain('Lỗi kỹ thuật 10%');
    expect(t).toContain('Hết lượt');
    expect(t).toContain('Mô hình quá giờ');
    expect(t).toContain('Báo lỗi đang mở 3');
    expect(t).toContain('Lời khuyên không an toàn');
    expect(t).toContain('20 giây, sau đó dùng mẫu');
    // Links: the kill switch lives in Tính năng, the limits in Premium › Cấu hình.
    expect(buttons(raw)).toEqual(['Mở Tính năng', 'Sửa ở Cấu hình']);
    const en = text(html(<AiPolicyView data={data} onOpenLimits={() => {}} />, ['ops'], 'en'));
    expect(en).toContain('audit AI answers by hand in both languages (vi and en)');
    expect(en).toContain('On for internal families and 2 picked families');
  });

  it('D-075 #1: with the assistant pool, AI limits read as credits shared with chat', () => {
    const data = {
      ...policy,
      quotas: {
        ...policy.quotas,
        assistant: { free: 20, premium: 200, textCredits: 1, imageCredits: 3 },
      },
    };
    const t = text(html(<AiPolicyView data={data} onOpenLimits={() => {}} />, ['ops']));
    expect(t).toContain('Credit · Miễn phí (mỗi tháng lịch) 20 credit');
    expect(t).toContain('Credit · Premium (kỳ thanh toán; beta: mỗi tháng) 200 credit');
    expect(t).toContain('Mỗi tóm tắt AI tạo mới dùng 1 credit');
    expect(t).not.toContain('AI · mỗi bé mỗi ngày');
    const en = text(html(<AiPolicyView data={data} onOpenLimits={() => {}} />, ['ops'], 'en'));
    expect(en).toContain('200 credits');
  });

  it('a template provider, the switch off and default limits read as such', () => {
    const t = text(
      html(
        <AiPolicyView
          data={{
            ...policy,
            provider: { name: 'template', model: null },
            flag: { enabled: false, scope: 'all', percent: 0, families: 0 },
            quotas: { perBabyPerDay: 1, perFamilyPerMonth: 10, stored: false },
            fallbackReasons: [],
            totals: { ...policy.totals, fallbackRate: null, technicalRate: null },
          }}
          onOpenLimits={() => {}}
        />,
      ),
    );
    expect(t).toContain('Mẫu có sẵn (chưa có khoá mô hình)');
    expect(t).toContain('Đang tắt: chỉ tóm tắt theo mẫu, không gọi mô hình');
    expect(t).toContain('Đang dùng mặc định (chưa lưu cấu hình).');
    expect(t).toContain('Chưa có lần dùng mẫu nào trong 30 ngày.');
    expect(aiSwitchNote({ enabled: true, scope: 'percent', percent: 25, families: 0 }).id).toBe(
      'premium.ai.switchPercent',
    );
    expect(aiSwitchNote({ enabled: true, scope: 'all', percent: 0, families: 0 }).tone).toBe('ok');
  });

  it('Gói Premium holds Cấu hình, Chính sách AI and the old campaigns; the hub needs features.view', () => {
    const raw = html(
      <PremiumPlanView
        data={view}
        flags={null}
        onChanged={() => {}}
        now={now}
        initialSection="ai"
      />,
    );
    expect(buttons(raw).slice(0, 4)).toEqual([
      'Cấu hình',
      'Gói & hạn mức (v2)',
      'Chính sách AI',
      'Chiến dịch beta (cũ)',
    ]);
    expect(raw).toMatch(/aria-selected="true"[^>]*>Chính sách AI/);
    for (const role of ['owner', 'admin', 'ops', 'eng'] as StaffRole[]) {
      expect(allowedRoute(levelsForRoles([role]), 'features')).toBe('features');
    }
    for (const role of ['support', 'analyst', 'expert', 'qa'] as StaffRole[]) {
      expect(allowedRoute(levelsForRoles([role]), 'features')).not.toBe('features');
    }
  });
});

describe('Tính năng & Premium › Gia đình › Lượt dùng & thanh toán', () => {
  it('shows windows, held units, hashed store accounts, events and the not-connected note', () => {
    const raw = html(<FamilyQuotaView data={quota} now={now} />, ['ops']);
    const t = text(raw);
    expect(t).toContain('Quota & thanh toán');
    expect(t).toContain('Google Play chưa kết nối: chưa có giao dịch');
    expect(t).toContain('video_cal_2026-10');
    expect(t).toContain('0 đã dùng · 1 giữ chỗ · hạn mức 1');
    expect(t).toContain('ai_day_B-K3QZ_2026-10-15');
    expect(t).toContain('Kỳ thanh toán');
    expect(t).toContain('Đã kết thúc');
    expect(t).toContain('1 lượt đang giữ chỗ');
    expect(t).toContain('apple_aaaaaaaa…');
    expect(t).toContain('premium.monthly');
    expect(t).toContain('1/11/2026');
    expect(t).toContain('DID_RENEW');
    expect(t).toContain('Chưa xử lý');
    expect(t).toContain('Không hiện mã giao dịch, token mua hay người mua');
    // Read-only for everyone: the section adds no button, whatever the role.
    for (const roles of [['ops'], ['owner']] as StaffRole[][]) {
      const section = html(<FamilyQuotaView data={quota} now={now} />, roles);
      expect(buttons(section)).toEqual([]);
    }
    const en = text(html(<FamilyQuotaView data={quota} now={now} />, ['ops'], 'en'));
    expect(en).toContain('payments are not connected yet: there are no real');
    expect(en).toContain('1 unit held');
  });

  it('nothing bound yet: empty lists say so', () => {
    const t = text(
      html(
        <FamilyQuotaView
          data={{ code: 'F-7Q2K', windows: [], held: 0, accounts: [], events: [] }}
          now={now}
        />,
      ),
    );
    expect(t).toContain('Gia đình chưa dùng lượt nào.');
    expect(t).toContain('Không có lượt nào đang giữ chỗ.');
    expect(t).toContain('Chưa có tài khoản cửa hàng nào gắn với gia đình này.');
    expect(t).toContain('Chưa có sự kiện nào.');
  });
});

describe('Yêu cầu dữ liệu › Video kỷ niệm', () => {
  it('lists render jobs with status, failure reason and reservation state, read-only', async () => {
    const { api, calls } = fakeApi({ staffRenderOps: render });
    const data = await api.call<StaffRenderOps>('staffRenderOps');
    expect(calls.map((c) => c.name)).toEqual(['staffRenderOps']);
    const raw = html(
      <RenderOpsView
        data={data}
        now={now}
        toolbar={<JobKinds label="Lọc" value="render" onChange={() => {}} />}
      />,
      ['owner'],
    );
    const t = text(raw);
    expect(t).toContain('KJ-3C3C');
    expect(t).toContain('F-7Q2K');
    expect(t).toContain('ch1-birthday');
    expect(t).toContain('Đang dựng');
    expect(t).toContain('Thêm chữ và nhạc · 40%');
    expect(t).toContain('Máy dựng báo lỗi');
    expect(t).toContain('2 lần · lease 2');
    expect(t).toContain('Đang giữ');
    expect(t).toContain('Chưa trả lượt');
    expect(t).toContain('video_cal_2026-10 · video_ksj_11111111…_0');
    expect(t).toContain('Lệch sổ lượt 1');
    expect(t).toContain('Lỗi dựng 1');
    expect(t).toContain('Chỉ xem: không có nút chạy lại');
    // Even an owner gets no retry: the only buttons are the filter.
    expect(buttons(raw)).toEqual(['Tất cả', 'Xuất dữ liệu', 'Xoá dữ liệu', 'Video kỷ niệm']);
    const en = text(html(<RenderOpsView data={data} now={now} />, ['owner'], 'en'));
    expect(en).toContain('The renderer reported an error');
    expect(en).toContain('Not given back');
  });

  it('an empty listing and the screen gating', () => {
    const t = text(
      html(
        <RenderOpsView
          data={{
            kpis: { active: 0, failed24h: 0, completed24h: 0, ledgerIssues: 0 },
            failures: {},
            jobs: [],
          }}
          now={now}
        />,
      ),
    );
    expect(t).toContain('Chưa có video nào được dựng.');
    expect(t).toContain('Sổ lượt khớp');
    expect(t).toContain('Không có lỗi');
    expect(text(html(<JobsScreen />, ['support']))).toContain('Yêu cầu dữ liệu');
    expect(allowedRoute(levelsForRoles(['support']), 'jobs')).toBe('jobs');
    expect(allowedRoute(levelsForRoles(['analyst']), 'jobs')).not.toBe('jobs');
  });
});

describe('Premium operations: messages', () => {
  it('every dynamic id exists in both catalogs', () => {
    const ids = [
      ...(appEventDims.summaryFallback ?? []).map((r) => `premium.ai.reason.${r}`),
      ...aiReportProblems.map((p) => `premium.ai.problem.${p}`),
      ...['openai', 'template'].map((p) => `premium.ai.provider.${p}`),
      ...['ai', 'cache', 'fallback'].map((m) => `premium.ai.method.${m}`),
      ...quotaFeatures.map((f) => `premium.fq.feature.${f}`),
      ...['calendar_month', 'day', 'paid'].map((s) => `premium.fq.scope.${s}`),
      ...keepsakeJobStatuses.map((s) => `render.status.${s}`),
      ...keepsakeJobSteps.map((s) => `render.step.${s}`),
      ...keepsakeJobErrors.flatMap((e) => [`render.error.${e}`, `render.errorShort.${e}`]),
      ...['reserved', 'committed', 'released', 'none'].map((s) => `render.state.${s}`),
      ...['not-released', 'not-committed', 'not-held', 'missing'].map((i) => `render.issue.${i}`),
      ...['config', 'ai', 'campaigns'].map((t) => `hub.plan.${t}`),
    ];
    for (const locale of ['vi', 'en'] as const) {
      for (const id of ids) expect(messages[locale][id], `${locale} ${id}`).toBeTruthy();
    }
  });
});
