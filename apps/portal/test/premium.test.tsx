import {
  capabilities,
  defaultEntitlementsConfig,
  grantStatuses,
  householdPlans,
  staffEntitlementsConfigSchema,
} from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, ApiError, type Api, type StaffPremiumView } from '../src/api';
import { StaffContext } from '../src/context';
import { messages } from '../src/messages';
import { EnvPill, PremiumPlanView, draftChanges, savePremiumConfig } from '../src/screens/Premium';
import { RecentList } from '../src/screens/Features';
import type { FlagsView } from '../src/api';
import { errorMessageId } from '../src/ui';
import { launchedFlagDefaults, levelsForRoles, type StaffRole } from './fixtures';

// Tính năng & Premium › Gói Premium (D-089; was Premium › Cấu hình): Mua gói trong app, regions,
// quotas, credits and the old beta campaigns, read-only. Server-rendered, no network: callables go
// to a fake api that records them. No reason is sent (D-090).
const now = new Date('2026-10-14T03:00:00Z');

const view: StaffPremiumView = {
  config: {
    ...defaultEntitlementsConfig,
    policyVersion: 'policy-v2',
    regions: { advanced: ['VN', 'SG'] },
    betaCampaigns: [
      {
        id: 'beta-a-vn',
        capabilities: ['personalization.cross_module', 'rhythm.advanced'],
        validFrom: '2026-10-01T00:00:00.000Z',
        validUntil: '2026-12-01T00:00:00.000Z',
        countries: ['VN'],
        scope: 'internal',
        percent: 0,
        families: ['F-7Q2K'],
      },
      {
        id: 'beta-a-share',
        capabilities: ['ai.assistance'],
        validFrom: '2026-11-01T00:00:00.000Z',
        validUntil: '2027-01-01T00:00:00.000Z',
        countries: [],
        scope: 'percent',
        percent: 25,
      },
    ],
  },
  stored: true,
  environment: 'test',
  recent: [
    {
      action: 'premium.grant',
      target: 'F-7Q2K',
      by: 'Linh Trần',
      at: '2026-10-13T03:00:00Z',
      reason: 'Hỗ trợ khiếu nại',
    },
  ],
};

const flags: FlagsView = {
  flags: {
    ...launchedFlagDefaults,
    premium_billing: { enabled: true, scope: 'internal', percent: 0, notice: null },
  },
  limits: {
    familyQuotaBytes: 5 * 1024 ** 3,
    videoMaxDurationSec: 300,
    videoMaxBytes: 1024 ** 3,
    videoWifiOnlyDefault: true,
    mediaItemsPerAdd: 30,
    exportLinkTtlHours: 72,
    storageRequestAmountsGb: [5, 10, 20],
    autoSaveItemsPerApprove: 200,
  },
  lastEdit: {},
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
    .replace(/\s+/g, ' ');

describe('Gói Premium: configuration', () => {
  it('the fixture config is what the server accepts', () => {
    expect(staffEntitlementsConfigSchema.safeParse(view.config).success).toBe(true);
  });

  it('shows Mua gói trong app, regions, quotas and credits; history is in Lịch sử', async () => {
    const { api } = fakeApi({ staffPremium: view });
    const data = await api.call<StaffPremiumView>('staffPremium');
    const raw = render(
      <PremiumPlanView data={data} flags={flags} onChanged={() => {}} now={now} />,
    );
    const html = text(raw);
    expect(html).toContain('Cấu hình Gói & hạn mức (v2) Chính sách AI Chiến dịch beta (cũ)');
    expect(html).toContain('Mua gói trong app');
    expect(html).toContain(messages.vi['flag.premium_billing']!);
    expect(raw).toContain('role="switch"');
    expect(html).toContain('Vùng mở Premium');
    expect(html).toContain('Premium được cấp (Bật toàn bộ Premium) không xét quốc gia');
    expect(html).toContain('Việt Nam · VN');
    expect(html).toContain('Singapore · SG');
    // The policy version is folded, its value in the summary.
    expect(html).toContain('Phiên bản chính sách policy-v2');
    // D-075 #1: the assistant credit pool is editable here (shared by chat and AI summaries).
    expect(html).toContain('Credit trợ lý AI · một quỹ chung cho trò chuyện và tóm tắt AI');
    expect(raw).toContain('value="200"');
    expect(html).not.toContain('AI · mỗi bé mỗi ngày');
    // Nothing unsaved yet: no save bar; the history moved to the hub's Lịch sử.
    expect(html).not.toContain('Lưu thay đổi…');
    expect(html).not.toContain('Thay đổi gần đây');
    expect(text(render(<RecentList recent={view.recent} />))).toContain(
      'Linh · 13/10 · Hỗ trợ khiếu nại',
    );
    expect(text(render(<EnvPill env="test" />))).toContain('Môi trường quyền: thử nghiệm (test)');
    expect(text(render(<EnvPill env="production" />, ['admin'], 'en'))).toContain(
      'Grant environment: production',
    );
    // English: country names follow the portal language.
    expect(
      text(
        render(<PremiumPlanView data={view} flags={flags} onChanged={() => {}} />, ['admin'], 'en'),
      ),
    ).toContain('Vietnam · VN');
  });

  it('a viewer without premium.config sees it read-only', () => {
    // Vận hành: Tính năng "Xem" → premium.view, not premium.config.
    const raw = render(<PremiumPlanView data={view} flags={flags} onChanged={() => {}} />, ['ops']);
    const html = text(raw);
    expect(html).toContain('Bạn chỉ xem được');
    expect(html).toContain('1 video · mỗi tháng lịch');
    expect(html).toContain('5 video · mỗi kỳ thanh toán');
    expect(html).toContain('Credit · Premium (kỳ thanh toán; beta: mỗi tháng) 200 credit');
    expect(html).toContain('Credit cho một tác vụ ảnh 3 credit');
    expect(raw).not.toContain('type="number"');
    expect(raw).not.toContain('Bỏ Việt Nam');
    // The billing switch follows Tính năng · Sửa like every switch.
    expect(raw).toMatch(/role="switch"[^>]*disabled=""/);
    // An engineer (Sửa) may edit.
    const eng = render(<PremiumPlanView data={view} flags={flags} onChanged={() => {}} />, ['eng']);
    expect(eng).toContain('type="number"');
    expect(eng).toContain('aria-label="Bỏ Việt Nam"');
    expect(eng).not.toMatch(/role="switch"[^>]*disabled=""/);
  });

  it('saving sends the whole config, families as codes, and no reason', async () => {
    const { api, calls } = fakeApi({ staffSetPremiumConfig: null });
    const next = { ...view.config, regions: { advanced: ['VN', 'SG', 'US'] } };
    expect(await savePremiumConfig(api, next)).toEqual({ ok: true });
    expect(calls).toHaveLength(1);
    expect(calls[0]!.name).toBe('staffSetPremiumConfig');
    const sent = calls[0]!.data as Record<string, unknown> & { config: typeof view.config };
    expect(Object.keys(sent)).toEqual(['config']);
    expect(sent.config.regions.advanced).toEqual(['VN', 'SG', 'US']);
    expect(sent.config.betaCampaigns[0]!.families).toEqual(['F-7Q2K']);
    // An invalid config never leaves the browser.
    const bad = {
      ...view.config,
      betaCampaigns: [{ ...view.config.betaCampaigns[0]!, families: ['someone@example.com'] }],
    };
    expect((await savePremiumConfig(api, bad)).ok).toBe(false);
    expect(calls).toHaveLength(1);
  });

  it('D-075 #1: assistant credits edited in the draft are saved with the config', async () => {
    const { api, calls } = fakeApi({ staffSetPremiumConfig: null });
    const next = {
      ...view.config,
      quotas: {
        ...view.config.quotas,
        assistant: { free: 30, premium: 300, textCredits: 1, imageCredits: 3 },
      },
    };
    expect((await savePremiumConfig(api, next)).ok).toBe(true);
    const sent = calls[0]!.data as { config: typeof view.config };
    expect(sent.config.quotas.assistant).toEqual({
      free: 30,
      premium: 300,
      textCredits: 1,
      imageCredits: 3,
    });
    // The legacy summary pair is kept untouched in the document.
    expect(sent.config.quotas.ai).toEqual(view.config.quotas.ai);
    // Over the per-task maximum is refused before sending.
    const bad = {
      ...next,
      quotas: { ...next.quotas, assistant: { ...next.quotas.assistant, imageCredits: 21 } },
    };
    expect((await savePremiumConfig(api, bad)).ok).toBe(false);
    expect(calls).toHaveLength(1);
  });

  it('the unsaved bar says what changed', () => {
    const next = { ...view.config, regions: { advanced: ['VN', 'SG', 'US'] }, policyVersion: 'v3' };
    expect(draftChanges(view.config, next)).toEqual(['regions', 'policy']);
  });

  it('server reasons read as friendly messages', () => {
    for (const reason of ['bad-dates', 'duplicate-campaign', 'no-grant', 'paid-grant', 'no-baby']) {
      expect(errorMessageId(new ApiError('invalid-argument', reason))).toBe(`error.${reason}`);
    }
    expect(errorMessageId(new ApiError('not-found', 'family-not-found'))).toBe(
      'error.family-not-found',
    );
    expect(errorMessageId(new ApiError('invalid-argument', 'malformed'))).toBe('error.invalid');
    expect(errorMessageId(new ApiError('permission-denied', 'role'))).toBe('error.role');
  });
});

describe('Gói Premium: the old beta campaigns, read-only', () => {
  it('lists them with their dates, reach and capabilities, and says Beta features replace them', () => {
    for (const roles of [['ops'], ['owner']] as StaffRole[][]) {
      const raw = render(
        <PremiumPlanView
          data={view}
          flags={flags}
          onChanged={() => {}}
          now={now}
          initialSection="campaigns"
        />,
        roles,
      );
      const html = text(raw);
      expect(html).toContain('Chỉ để xem. Beta giờ là gói của từng tính năng');
      expect(html).toContain('beta-a-vn');
      expect(html).toContain('Đang chạy');
      expect(html).toContain('Sắp chạy');
      expect(html).toContain('Gợi ý xuyên mô-đun Nhịp lớn lên nâng cao');
      // Ends are exclusive: 1/12 00:00 UTC is 07:00 in Vietnam, so 1/12 is the last day included.
      expect(html).toContain('1/10/2026 – 1/12/2026');
      expect(html).toContain('1 gia đình được chọn');
      expect(html).toContain('F-7Q2K');
      expect(html).toContain('Mọi khu vực mở');
      expect(html).toContain('Mở dần · 25%');
      // Nothing to add, edit or remove: only the section switcher's buttons.
      expect(html).not.toContain('Thêm chiến dịch');
      expect(raw).not.toMatch(/<input|<textarea|role="switch"/);
    }
  });
});

describe('Gói Premium: messages', () => {
  it('every dynamic id exists in both catalogs', () => {
    const ids = [
      ...capabilities.map((c) => `premium.cap.${c}`),
      ...householdPlans.map((p) => `premium.plan.${p}`),
      ...grantStatuses.map((s) => `premium.status.${s}`),
      ...['paid', 'beta', 'promo'].map((s) => `premium.source.${s}`),
      ...['apple', 'google', 'staff'].map((p) => `premium.provider.${p}`),
      ...['test', 'production'].map((e) => `premium.env.${e}`),
      ...['calendar_month', 'billing_period'].map((w) => `premium.window.${w}`),
      ...['regions', 'quotas', 'policy'].map((w) => `premium.changed.${w}`),
      ...['config', 'beta', 'free', 'paid'].map((r) => `premium.rule.${r}`),
      ...['config', 'grant', 'revoke', 'full.on', 'full.off'].map((a) => `audit.premium.${a}`),
      'auditCategory.premium',
    ];
    for (const id of ids) {
      expect(messages.vi[id], id).toBeTruthy();
      expect(messages.en[id], id).toBeTruthy();
    }
  });
});
