import {
  capabilities,
  defaultEntitlementsConfig,
  flagKeys,
  grantStatuses,
  householdPlans,
  staffEntitlementsConfigSchema,
  type BetaCampaign,
  type FlagKey,
  type StaffFamilyPremium,
} from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, ApiError, type Api, type StaffPremiumView } from '../src/api';
import { StaffContext } from '../src/context';
import { messages } from '../src/messages';
import {
  CampaignDialog,
  EnvPill,
  GrantDialog,
  PremiumBody,
  blankCampaign,
  campaignIssues,
  grantRevocable,
  savePremiumConfig,
  withCampaign,
  campaignFamilyIssues,
  draftChanges,
} from '../src/screens/Premium';
import { RecentList } from '../src/screens/Features';
import { errorMessageId } from '../src/ui';
import { levelsForRoles, type StaffRole } from './fixtures';

// Premium & Cá nhân hoá on the portal (plan §5.6): regions, quotas, Beta A campaigns and one
// family's grants. Server-rendered, no network: callables go to a fake api that records them.
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

const family: StaffFamilyPremium = {
  code: 'F-7Q2K',
  country: 'VN',
  plan: 'beta',
  validUntil: '2026-12-01T00:00:00.000Z',
  entitlementVersion: 4,
  grants: [
    {
      id: 'paid_apple_1',
      source: 'paid',
      status: 'expired',
      environment: 'test',
      capabilities: ['personalization.cross_module', 'templates.premium'],
      validFrom: '2026-08-01T00:00:00.000Z',
      validUntil: '2026-09-01T00:00:00.000Z',
      provider: 'apple',
      autoRenew: false,
      fromCampaign: false,
    },
    {
      id: 'campaign:beta-a-vn',
      source: 'beta',
      status: 'active',
      environment: 'test',
      capabilities: ['personalization.cross_module', 'rhythm.advanced'],
      validFrom: '2026-10-01T00:00:00.000Z',
      validUntil: '2026-12-01T00:00:00.000Z',
      provider: null,
      autoRenew: null,
      fromCampaign: true,
    },
    {
      id: 'promo_AbC123',
      source: 'promo',
      status: 'active',
      environment: 'test',
      capabilities: ['ai.assistance'],
      validFrom: '2026-10-10T00:00:00.000Z',
      validUntil: '2026-11-10T00:00:00.000Z',
      provider: 'staff',
      autoRenew: null,
      fromCampaign: false,
    },
  ],
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

describe('Premium: configuration', () => {
  it('the fixture config is what the server accepts', () => {
    expect(staffEntitlementsConfigSchema.safeParse(view.config).success).toBe(true);
  });

  it('renders the campaigns, then the configuration tab: regions, quotas, credits', async () => {
    const { api } = fakeApi({ staffPremium: view });
    const data = await api.call<StaffPremiumView>('staffPremium');
    const campaigns = text(render(<PremiumBody data={data} onChanged={() => {}} now={now} />));
    expect(campaigns).toContain('Chiến dịch 2 Gia đình Cấu hình Chính sách AI');
    expect(campaigns).toContain('Chiến dịch beta');
    expect(campaigns).toContain('beta-a-vn');
    expect(campaigns).toContain('Đang chạy');
    expect(campaigns).toContain('Sắp chạy');
    expect(campaigns).toContain('Gợi ý xuyên mô-đun Nhịp lớn lên nâng cao');
    // Ends are exclusive: 1/12 00:00 UTC is 07:00 in Vietnam, so 1/12 is the last day included.
    expect(campaigns).toContain('1/10/2026 – 1/12/2026');
    expect(campaigns).toContain('1 gia đình được chọn');
    expect(campaigns).toContain('F-7Q2K');
    expect(campaigns).toContain('Mọi khu vực mở');
    expect(campaigns).toContain('Mở dần · 25%');
    expect(campaigns).toContain('Thêm chiến dịch');
    // Nothing unsaved yet: no save bar.
    expect(campaigns).not.toContain('Lưu thay đổi…');
    const raw = render(
      <PremiumBody data={data} onChanged={() => {}} now={now} initialTab="config" />,
    );
    const html = text(raw);
    expect(html).toContain('Vùng mở Premium');
    expect(html).toContain('Việt Nam · VN');
    expect(html).toContain('Singapore · SG');
    // The policy version is folded, its value in the summary.
    expect(html).toContain('Phiên bản chính sách policy-v2');
    // D-075 #1: the assistant credit pool is editable here (shared by chat and AI summaries).
    expect(html).toContain('Credit trợ lý AI · một quỹ chung cho trò chuyện và tóm tắt AI');
    expect(html).toContain('Credit · Miễn phí (mỗi tháng lịch)');
    expect(raw).toContain('value="200"');
    expect(html).toContain('Mỗi tóm tắt AI tạo mới dùng 1 credit');
    expect(html).not.toContain('AI · mỗi bé mỗi ngày');
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
        render(
          <PremiumBody data={view} onChanged={() => {}} now={now} initialTab="config" />,
          ['admin'],
          'en',
        ),
      ),
    ).toContain('Vietnam · VN');
  });

  it('a viewer without premium.config sees it read-only', () => {
    // Vận hành: Tính năng "Xem" → premium.view, not premium.config.
    const raw = render(
      <PremiumBody data={view} onChanged={() => {}} now={now} initialTab="config" />,
      ['ops'],
    );
    const html = text(raw);
    expect(html).toContain('Bạn chỉ xem được');
    expect(html).toContain('1 video · mỗi tháng lịch');
    expect(html).toContain('5 video · mỗi kỳ thanh toán');
    expect(html).toContain('Credit · Premium (kỳ thanh toán; beta: mỗi tháng) 200 credit');
    expect(html).toContain('Credit cho một tác vụ ảnh 3 credit');
    expect(html).toContain('policy-v2');
    expect(raw).not.toContain('type="number"');
    expect(raw).not.toContain('Bỏ Việt Nam');
    const campaigns = text(
      render(<PremiumBody data={view} onChanged={() => {}} now={now} />, ['ops']),
    );
    expect(campaigns).toContain('beta-a-vn');
    expect(campaigns).not.toContain('Thêm chiến dịch');
    // An engineer (Sửa) may edit.
    const eng = render(
      <PremiumBody data={view} onChanged={() => {}} now={now} initialTab="config" />,
      ['eng'],
    );
    expect(eng).toContain('type="number"');
    expect(eng).toContain('aria-label="Bỏ Việt Nam"');
    expect(
      text(render(<PremiumBody data={view} onChanged={() => {}} now={now} />, ['eng'])),
    ).toContain('Thêm chiến dịch');
  });

  it('saving a campaign sends the whole config with family codes and the reason', async () => {
    const { api, calls } = fakeApi({ staffSetPremiumConfig: null });
    const campaign: BetaCampaign = {
      ...blankCampaign(now),
      id: 'beta-a-internal',
      // D-075 #1: a beta may open templates and the Premium budget; free ones are dropped.
      capabilities: [
        'assistant.premium_budget',
        'templates.premium',
        'ai.assistance',
        'rhythm.checkin',
      ],
      countries: ['SG'],
      families: ['F-ABCD', 'F-7Q2K'],
    };
    expect(campaignIssues(campaign, view.config.betaCampaigns, null)).toEqual([]);
    const next = withCampaign(view.config, campaign, null);
    const res = await savePremiumConfig(api, next, '  Mở beta cho nhóm nội bộ  ');
    expect(res).toEqual({ ok: true });
    expect(calls).toHaveLength(1);
    expect(calls[0]!.name).toBe('staffSetPremiumConfig');
    const sent = calls[0]!.data as { config: typeof view.config; reason: string };
    expect(sent.reason).toBe('Mở beta cho nhóm nội bộ');
    expect(sent.config.betaCampaigns).toHaveLength(3);
    const added = sent.config.betaCampaigns[2]!;
    expect(added.families).toEqual(['F-ABCD', 'F-7Q2K']);
    expect(added.capabilities).toEqual([
      'ai.assistance',
      'templates.premium',
      'assistant.premium_budget',
    ]);
    expect(added.validFrom).toBe('2026-10-13T17:00:00.000Z');
    expect(added.validUntil).toBe('2026-11-12T17:00:00.000Z');
    expect(sent.config.betaCampaigns[0]!.families).toEqual(['F-7Q2K']);
    expect(sent.config.regions.advanced).toEqual(['VN', 'SG']);

    // Editing a campaign to "Mọi gia đình" drops its family list.
    const all = withCampaign(view.config, { ...view.config.betaCampaigns[0]!, scope: 'all' }, 0);
    expect(all.betaCampaigns[0]).not.toHaveProperty('families');
    expect(all.betaCampaigns[0]!.percent).toBe(100);
  });

  it('a short reason or an invalid campaign is not sent', async () => {
    const { api, calls } = fakeApi({ staffSetPremiumConfig: null });
    expect((await savePremiumConfig(api, view.config, 'ok')).ok).toBe(false);
    const bad = {
      ...view.config,
      betaCampaigns: [{ ...view.config.betaCampaigns[0]!, families: ['someone@example.com'] }],
    };
    expect((await savePremiumConfig(api, bad, 'Lý do đủ dài')).ok).toBe(false);
    expect(calls).toHaveLength(0);
    // Form checks: id, duplicate, capabilities, dates, percent.
    const c = view.config.betaCampaigns[1]!;
    expect(campaignIssues({ ...c, id: 'beta-a-vn' }, view.config.betaCampaigns, null)).toEqual([
      'premium.issue.duplicate',
    ]);
    expect(campaignIssues(c, view.config.betaCampaigns, 1)).toEqual([]);
    expect(
      campaignIssues(
        { ...c, id: 'X', capabilities: ['rhythm.checkin'], validUntil: c.validFrom, percent: 0 },
        [],
        null,
      ),
    ).toEqual([
      'premium.issue.id',
      'premium.issue.caps',
      'premium.issue.dates',
      'premium.issue.percent',
    ]);
    // A templates-only (or budget-only) beta is a valid campaign now.
    for (const cap of ['templates.premium', 'assistant.premium_budget'] as const) {
      expect(campaignIssues({ ...c, capabilities: [cap] }, view.config.betaCampaigns, 1)).toEqual(
        [],
      );
    }
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
    expect((await savePremiumConfig(api, next, 'Tăng credit cho QA')).ok).toBe(true);
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
    expect((await savePremiumConfig(api, bad, 'Tăng credit cho QA')).ok).toBe(false);
    expect(calls).toHaveLength(1);
  });

  it('D-075 #1: the campaign form offers every Premium feature, grouped and labelled', () => {
    const html = text(
      render(
        <CampaignDialog
          initial={blankCampaign(now)}
          index={null}
          all={view.config.betaCampaigns}
          regions={view.config.regions.advanced}
          onClose={() => {}}
          onApply={() => {}}
        />,
      ),
    );
    expect(html).toContain('Thêm chiến dịch beta');
    for (const label of [
      'Nhóm A · Nhịp lớn lên và AI',
      'Gợi ý xuyên mô-đun',
      'Nhịp lớn lên nâng cao',
      'Trợ lý AI',
      'Kỷ niệm',
      'Mẫu kỷ niệm Cao cấp',
      'Hạn mức trợ lý Premium',
      'Dùng hạn mức credit Premium thay cho Miễn phí',
    ]) {
      expect(html).toContain(label);
    }
    expect(html).not.toContain('Check-in Nhịp lớn lên');
    expect(html).toContain('Việt Nam');
    expect(html).toContain('Không chọn gia đình nào = chỉ gia đình nội bộ.');
    const en = text(
      render(
        <CampaignDialog
          initial={blankCampaign(now)}
          index={null}
          all={[]}
          regions={['VN']}
          onClose={() => {}}
          onApply={() => {}}
        />,
        ['admin'],
        'en',
      ),
    );
    expect(en).toContain('Premium memory templates');
    expect(en).toContain('Premium assistant budget');
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

describe('Premium: will a campaign reach its families?', () => {
  const allFlags = Object.fromEntries(flagKeys.map((k) => [k, true])) as Record<FlagKey, boolean>;
  const reach = (
    over: Partial<StaffFamilyPremium>,
    flags: Partial<Record<FlagKey, boolean>> = {},
  ) =>
    campaignFamilyIssues(
      {
        ...blankCampaign(now),
        id: 'qa',
        capabilities: ['ai.assistance', 'assistant.premium_budget'],
      },
      ['VN'],
      {
        ...family,
        ...over,
        access: {
          internal: false,
          regionSupported: true,
          flags: { ...allFlags, ...flags },
          capabilities: {} as never,
        },
      },
    );
  it('a family outside the open regions, or without a country, is not reached', () => {
    expect(reach({ country: 'US' }).country).toBe('outside');
    expect(reach({ country: null }).country).toBe('none');
    expect(reach({ country: 'VN' }).country).toBeNull();
  });
  it('names the flags the family still needs for what the campaign opens', () => {
    expect(reach({}, { assistant: false, ai_assist: false }).flags).toEqual([
      'ai_assist',
      'assistant',
    ]);
    expect(reach({}).flags).toEqual([]);
  });
  it('the unsaved bar says what changed', () => {
    const next = {
      ...view.config,
      regions: { advanced: ['VN', 'SG', 'US'] },
      betaCampaigns: [{ ...view.config.betaCampaigns[0]!, families: ['F-7Q2K', 'F-NJAT'] }],
    };
    expect(draftChanges(view.config, next)).toEqual(['campaigns:2', 'regions']);
  });
});

describe('Premium: one family', () => {
  const body = (roles: StaffRole[]) =>
    render(
      // No recent audit rows, so "Cấp quyền khuyến mãi" can only be the button.
      <PremiumBody
        data={{ ...view, recent: [] }}
        onChanged={() => {}}
        now={now}
        initialFamily={family}
      />,
      roles,
    );

  it('shows the plan, country, version and every grant', () => {
    const html = text(body(['ops']));
    expect(html).toContain('Beta đến hết 1/12/2026');
    expect(html).toContain('Việt Nam · VN');
    expect(html).toContain('Phiên bản quyền 4');
    expect(html).toContain('Trả phí');
    expect(html).toContain('App Store');
    expect(html).toContain('Hết hạn');
    expect(html).toContain('Từ chiến dịch');
    expect(html).toContain('Khuyến mãi');
    expect(html).toContain('Môi trường quyền: thử nghiệm (test)');
  });

  it('the grant form is hidden without premium.grant', () => {
    for (const roles of [['ops'], ['eng']] as StaffRole[][]) {
      const html = text(body(roles));
      expect(html).not.toContain('Cấp quyền khuyến mãi');
      expect(html).not.toContain('Thu hồi');
    }
    expect(text(body(['admin']))).toContain('Cấp quyền khuyến mãi');
    expect(text(body(['owner']))).toContain('Cấp quyền khuyến mãi');
  });

  it('revoke is offered only on staff-written grants, never on campaign or paid rows', () => {
    const html = text(body(['admin']));
    expect(html.match(/Thu hồi/g)?.length).toBe(1);
    const [paid, campaign, promo] = family.grants;
    expect(grantRevocable(paid!)).toBe(false);
    expect(grantRevocable(campaign!)).toBe(false);
    expect(grantRevocable(promo!)).toBe(true);
    expect(grantRevocable({ ...promo!, status: 'revoked' })).toBe(false);
    expect(grantRevocable({ ...promo!, id: 'beta_hand1', source: 'beta' })).toBe(true);
    // A paid grant is never revocable, whatever its id looks like.
    expect(grantRevocable({ ...paid!, id: 'promo_x' })).toBe(false);
  });

  it('the promo form offers group A and Cao cấp templates', () => {
    const html = text(
      render(<GrantDialog code="F-7Q2K" now={now} onClose={() => {}} onDone={() => {}} />),
    );
    expect(html).toContain('Cấp quyền khuyến mãi cho F-7Q2K');
    expect(html).toContain('Mẫu kỷ niệm Cao cấp');
    expect(html).toContain('Trợ lý AI');
  });
});

describe('Premium: messages', () => {
  it('every dynamic id exists in both catalogs', () => {
    const ids = [
      ...capabilities.map((c) => `premium.cap.${c}`),
      ...['groupA', 'templates', 'assistant'].map((g) => `premium.capGroup.${g}`),
      ...['templates', 'assistant'].map((g) => `premium.capHelp.${g}`),
      ...householdPlans.map((p) => `premium.plan.${p}`),
      ...grantStatuses.map((s) => `premium.status.${s}`),
      ...['paid', 'beta', 'promo'].map((s) => `premium.source.${s}`),
      ...['apple', 'google', 'staff'].map((p) => `premium.provider.${p}`),
      ...['test', 'production'].map((e) => `premium.env.${e}`),
      ...['calendar_month', 'billing_period'].map((w) => `premium.window.${w}`),
      ...['internal', 'percent', 'all'].map((s) => `premium.scope.${s}`),
      ...['config', 'beta', 'free', 'paid'].map((r) => `premium.rule.${r}`),
      ...['config', 'grant', 'revoke'].map((a) => `audit.premium.${a}`),
      'nav.premium',
      'auditCategory.premium',
    ];
    for (const id of ids) {
      expect(messages.vi[id], id).toBeTruthy();
      expect(messages.en[id], id).toBeTruthy();
    }
  });
});
