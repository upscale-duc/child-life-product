import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import {
  featureCatalogue,
  featureExplanations,
  featureOfFlag,
  flagKeys,
  featureGroups,
  featureTiers,
  staffRoleTemplates,
  staffRoles,
  type FeatureTier,
  type StaffFeatureHub,
  type StaffHubFamily,
  type StaffHubFamilyAnswer,
  type StaffHubRow,
} from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider } from 'react-intl';
import { describe, expect, it } from 'vitest';
import {
  ApiContext,
  ApiError,
  type Api,
  type FlagsView,
  type JobRow,
  type StaffPremiumView,
  type StaffTeam,
  type StorageRow,
  type TicketDetail,
} from '../src/api';
import { StaffContext, canonicalPath, routeOf, routePaths } from '../src/context';
import { messages } from '../src/messages';
import { Sidebar, allowedRoute } from '../src/Shell';
import { ActDialog as ContentActDialog } from '../src/screens/content-common';
import { FlagDialog } from '../src/screens/Features';
import {
  FeatureDetail,
  FeatureHubScreen,
  HubFeaturesView,
  HubHistory,
  ScopeDialog,
  SwitchDetail,
  TierDialog,
  ToggleDialog,
  applyTierChange,
  hubTabOf,
  hubTabs,
  listFilters,
  listGroups,
  listRows,
  listSwitchKeys,
  previewTierChange,
  scopeChoice,
  scopeChoices,
  scopeFields,
  setEnabled,
  setScope,
  switchGroupOf,
  tierNoteId,
  type SwitchTarget,
} from '../src/screens/FeatureHub';
import { ActDialog as FirstAidActDialog } from '../src/screens/FirstAid';
import {
  FamilyCard,
  FamilyFeatures,
  FullPremiumDialog,
  HubFamilies,
  endOfDay,
  findHubFamily,
  grantRevocable,
  setBetaMember,
  setFeatureOverride,
  setFullPremium,
} from '../src/screens/HubFamily';
import { RerunDialog } from '../src/screens/Jobs';
import { ActDialog as KeepsakesActDialog } from '../src/screens/Keepsakes';
import { PremiumPlanView } from '../src/screens/Premium';
import { ActDialog as RhythmActDialog } from '../src/screens/Rhythm';
import { InviteDialog, MemberDialog } from '../src/screens/Staff';
import { DecideDialog } from '../src/screens/Storage';
import { TicketDetailView } from '../src/screens/Support';
import { launchedFlagDefaults, levelsForRoles, type StaffRole } from './fixtures';

// Tính năng & Premium (D-089, plan docs/product/features-premium-hub-plan.md) and "no reasons
// anywhere" (D-090). Server-rendered, no network: callables go to a fake api that records them.
const now = new Date('2026-10-21T05:00:00Z');

const flagState = (key: string, over: Partial<StaffHubRow['flag'] & object> = {}) => ({
  key: key as never,
  enabled: true,
  scope: 'internal' as const,
  percent: 0,
  notice: null,
  families: [] as string[],
  ...over,
});

const row = (key: StaffHubRow['key'], over: Partial<StaffHubRow> = {}): StaffHubRow => {
  const f = featureCatalogue.find((x) => x.key === key)!;
  return {
    key,
    group: f.group,
    labelId: f.labelId,
    helpId: f.helpId,
    tier: f.defaultTier,
    defaultTier: f.defaultTier,
    tierable: f.tierable,
    credits: f.credits,
    capabilities: [...f.capabilities],
    flag: f.flags[0] ? flagState(f.flags[0]) : null,
    subFlags: f.flags.slice(1).map((k) => flagState(k)),
    betaFamilies: [],
    grace: null,
    overrides: { on: 0, off: 0 },
    lastEdit: null,
    ...over,
  };
};

const hub: StaffFeatureHub = {
  groups: [...featureGroups],
  features: [
    row('rhythm', { flag: flagState('rhythm', { scope: 'all' }) }),
    row('personalization', {
      flag: flagState('personalization', { scope: 'percent', percent: 25 }),
      overrides: { on: 1, off: 0 },
      lastEdit: { by: 'Linh Trần', at: '2026-10-20T03:00:00Z' },
    }),
    row('assistant', {
      flag: flagState('assistant', { families: ['F-7Q2K'] }),
      subFlags: [
        flagState('assistant_images', { enabled: false }),
        flagState('assistant_care', { scope: 'all' }),
        flagState('assistant_upsell', { scope: 'percent', percent: 0 }),
      ],
    }),
    row('templates_premium'),
    row('memory_story', {
      tier: 'premium',
      grace: {
        since: '2026-10-21T05:00:00.000Z',
        until: '2026-11-20T05:00:00.000Z',
        from: 'beta',
      },
    }),
    row('auto_save', {
      betaFamilies: ['F-7Q2K', 'F-ABCD'],
      flag: flagState('auto_save', { enabled: false }),
    }),
  ],
  systemFlags: [],
  premium: { families: 12, paid: 9, admin: 3, full: 2, capped: false },
  environment: 'test',
  recent: [
    {
      action: 'hub.tier',
      target: 'memory_story',
      by: 'Linh Trần',
      at: '2026-10-21T04:00:00Z',
      detail: { feature: 'memory_story', before: 'beta', after: 'premium', affected: 4 },
    },
    {
      action: 'hub.override',
      target: 'F-7Q2K',
      by: 'Linh Trần',
      at: '2026-10-21T04:10:00Z',
      detail: { feature: 'assistant', before: null, after: { state: 'on', until: null } },
    },
    {
      action: 'premium.full.on',
      target: 'F-7Q2K',
      by: 'Linh Trần',
      at: '2026-10-21T04:20:00Z',
      detail: { grantId: 'promo_full', until: null },
    },
  ],
};

/** `staffFlags` for the engineering switches in the list (and the limits). */
const listFlags: FlagsView = {
  flags: {
    ...launchedFlagDefaults,
    engagementEnabled: { enabled: true, scope: 'percent', percent: 25, notice: null },
    invites: { enabled: false, scope: 'all', percent: 0, notice: 'Tạm dừng mời' },
    night_auto: {
      enabled: true,
      scope: 'internal',
      percent: 0,
      notice: null,
      families: ['F-7Q2K', 'F-ABCD'],
    },
  },
  limits: {
    familyQuotaBytes: 10 * 1024 ** 3,
    videoMaxDurationSec: null,
    videoMaxBytes: 4 * 1024 ** 3,
    videoWifiOnlyDefault: true,
    mediaItemsPerAdd: 30,
    exportLinkTtlHours: 24,
    storageRequestAmountsGb: [10, 20],
    autoSaveItemsPerApprove: 200,
  },
  lastEdit: { night_auto: { by: 'Minh Kỹ sư', at: '2026-10-20T03:00:00Z' } },
  recent: [],
};

const family: StaffHubFamily = {
  code: 'F-7Q2K',
  country: 'US',
  regionSupported: false,
  internal: true,
  plan: 'premium',
  validUntil: null,
  fullPremium: { on: true, until: null },
  grants: [
    {
      id: 'promo_full',
      source: 'promo',
      status: 'active',
      environment: 'test',
      capabilities: ['personalization.cross_module'],
      validFrom: '2026-10-01T00:00:00.000Z',
      validUntil: null,
      provider: 'staff',
      fromCampaign: false,
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
      fromCampaign: false,
    },
  ],
  features: [
    {
      key: 'rhythm',
      tier: 'free',
      on: true,
      visible: true,
      why: 'free',
      override: null,
      betaListed: false,
      graceUntil: null,
    },
    {
      key: 'personalization',
      tier: 'premium',
      on: true,
      visible: true,
      why: 'premium_admin',
      override: null,
      betaListed: false,
      graceUntil: null,
    },
    {
      key: 'assistant',
      tier: 'premium',
      on: true,
      visible: true,
      why: 'override_on',
      override: { state: 'on', until: '2026-11-01T17:00:00.000Z', by: 'Linh Trần', at: '' },
      betaListed: false,
      graceUntil: null,
    },
    {
      key: 'memory_story',
      tier: 'premium',
      on: true,
      visible: true,
      why: 'grace',
      override: null,
      betaListed: false,
      graceUntil: '2026-11-20T05:00:00.000Z',
    },
    {
      key: 'auto_save',
      tier: 'beta',
      on: false,
      visible: false,
      why: 'not_in_beta',
      override: null,
      betaListed: false,
      graceUntil: null,
    },
    {
      key: 'milestone_cards',
      tier: 'beta',
      on: true,
      visible: true,
      why: 'beta',
      override: null,
      betaListed: true,
      graceUntil: null,
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
const text = (raw: string) =>
  raw
    .replace(/<[^>]+>/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#x27;/g, "'")
    .replace(/\s+/g, ' ');
const tabs = (raw: string) =>
  [...raw.matchAll(/<button[^>]*role="tab"[^>]*>(.*?)<\/button>/g)].map((m) => text(m[1]!).trim());
const switches = (raw: string) => raw.match(/role="switch"/g)?.length ?? 0;
const disabledSwitches = (raw: string) =>
  raw.match(/<button[^>]*role="switch"[^>]*disabled=""/g)?.length ?? 0;
const noop = () => undefined;

const rowGroups = (raw: string) =>
  [...raw.matchAll(/<th colSpan="5" scope="rowgroup">(.*?)<\/th>/gi)].map((m) =>
    text(m[1]!).trim(),
  );

describe('Tính năng & Premium › the page', () => {
  it('four tabs; /premium, /features/<tab> and the old /features/switches open their tab', () => {
    const raw = render(<FeatureHubScreen initialTab="families" />);
    expect(tabs(raw)).toEqual(['Tổng quan', 'Tính năng', 'Gia đình', 'Gói Premium', 'Lịch sử']);
    expect(raw).toMatch(/aria-selected="true"[^>]*>Gia đình/);
    // The page's name is for screen readers; the rule behind the "i".
    expect(raw).toContain('<h1 class="sr-only">Tính năng &amp; Premium</h1>');
    expect(hubTabs.map((t) => messages.en[`hub.tab.${t}`])).toEqual([
      'Overview',
      'Features',
      'Families',
      'Premium plan',
      'History',
    ]);
    expect(routePaths.features).toBe('/features');
    expect(Object.keys(routePaths)).not.toContain('premium');
    expect(routeOf('/features/plan')).toBe('features');
    expect(routeOf('/premium')).toBe('features');
    expect(canonicalPath('/premium')).toBe('/features/plan');
    // Công tắc hệ thống joined the Tính năng list.
    expect(canonicalPath('/features/switches')).toBe('/features');
    expect(hubTabOf('/features/switches')).toBe('features');
    expect(hubTabOf('/premium')).toBe('plan');
    expect(hubTabOf('/features')).toBe('features');
    expect(hubTabOf('/features/history')).toBe('history');
    expect(hubTabOf('/features/nope')).toBe('features');
    for (const role of ['owner', 'admin', 'ops', 'eng'] as StaffRole[]) {
      expect(allowedRoute(levelsForRoles([role]), 'features')).toBe('features');
    }
  });

  it('the sidebar has one "Tính năng & Premium" item under HỆ THỐNG', () => {
    const t = text(
      render(
        <Sidebar
          route="features"
          badges={null}
          environment="dev"
          locale="vi"
          onLocale={noop}
          onSignOut={noop}
          navigate={noop}
        />,
      ),
    );
    expect(t).toContain('HỆ THỐNG Hệ thống & AI Tính năng & Premium Cập nhật ứng dụng');
    expect(t).not.toContain('Premium & Cá nhân hoá');
    expect(t).not.toContain('Trợ lý AI');
    expect(t).not.toContain('Tính năng & phát hành');
  });
});

describe('Tính năng & Premium › Tính năng: one list (owner 2026-10-21)', () => {
  it('every catalogue feature and every engineering switch, each in one group', () => {
    const rows = listRows(hub, listFlags);
    const keys = rows.map((r) => r.key);
    expect(new Set(keys).size).toBe(keys.length);
    // Every flag is in the list once (as a feature's main flag, a part, or a switch) except Mua
    // gói trong app, which is on Gói Premium.
    for (const k of flagKeys) {
      const asFeature = featureOfFlag(k);
      if (k === 'premium_billing') expect(keys).not.toContain(k);
      else if (!asFeature) expect(keys).toContain(k);
    }
    expect(listSwitchKeys).not.toContain('premium_billing');
    for (const k of listSwitchKeys) expect(listGroups).toContain(switchGroupOf(k));
    // The assistant's engineering switches sit with the assistant; engagement has its own group.
    expect(switchGroupOf('assistant_live')).toBe('assistant');
    expect(switchGroupOf('assistant_writes')).toBe('assistant');
    expect(switchGroupOf('engagementLumiEnabled')).toBe('engagement');
    expect(switchGroupOf('story_share_link')).toBe('keepsakes');
    expect(listSwitchKeys.map(switchGroupOf)).not.toContain('other');
    // Before `staffFlags` answers, the catalogue alone.
    expect(listRows(hub, null).every((r) => r.kind === 'feature')).toBe(true);
  });

  it('the same columns on every row: Tính năng, Gói, Ai được dùng, Bật, the detail', () => {
    const raw = render(<HubFeaturesView hub={hub} flags={listFlags} onChanged={noop} />, ['admin']);
    const t = text(raw);
    // One KPI row, then the tier chips and the search.
    expect(t).toContain('Gia đình có Premium 12 9 trả phí · 3 được cấp');
    const listed = listRows(hub, listFlags);
    const offRows = listed.filter((r) =>
      r.kind === 'feature' ? r.row.flag?.enabled === false : !r.flag.enabled,
    ).length;
    expect(offRows).toBe(19);
    expect(t).toContain(`Đang bật ${listed.length - offRows} Đang tắt ${offRows} Beta 1`);
    expect(t).toContain('Tất cả 29 Miễn phí 1 Premium 4 Beta 1 Công tắc hệ thống 23');
    expect(t).toContain('Tính năng Gói Ai được dùng Bật');
    for (const old of ['Công tắc khẩn', 'Phát hành']) {
      expect(t).not.toContain(old);
    }
    // Groups: the catalogue's areas and the switches' together, each once.
    expect(rowGroups(raw)).toEqual([
      'Kỷ niệm · 4',
      'Cá nhân hoá · 4',
      'Trợ lý AI · 3',
      'Tải lên · 2',
      'Nhắc nhở & gợi ý · 11',
      'Gia đình & tiện ích · 4',
      'Đo lường sản phẩm · 1',
    ]);
    for (const r of hub.features) expect(t).toContain(messages.vi[r.labelId]!);
    for (const k of ['assistant_live', 'media_upload', 'engagementEnabled', 'invites']) {
      expect(t).toContain(messages.vi[`flag.${k}`]!);
    }
    // Help behind "?" for features and switches alike.
    expect(raw).toContain(`aria-label="${messages.vi['hub.feature.rhythm.help']}"`);
    expect(raw).toContain(`aria-label="${messages.vi['flag.invites.desc']}"`);
    // Gói: a select on catalogue rows, "Kỹ thuật" (not editable) on switches.
    expect(raw).toContain('aria-label="Gói của “Nhịp lớn lên”"');
    expect(raw).not.toContain(`aria-label="Gói của “${messages.vi['flag.invites']}”"`);
    expect(t.match(/Công tắc hệ thống/g)?.length).toBe(24);
    // Ai được dùng: one control; Premium rows say who has it first.
    expect(raw).toContain('aria-label="Ai được dùng “Nhịp lớn lên”"');
    expect(raw).toContain(
      'aria-label="Người khác được dùng “Gợi ý cá nhân hoá &amp; Nhịp nâng cao”"',
    );
    expect(raw).toContain(`aria-label="Ai được dùng “${messages.vi['flag.night_auto']}”"`);
    expect(t).toContain('Người có Premium');
    expect(t).toContain('Mọi gia đình');
    expect(t).toContain('Theo tỷ lệ · 25%');
    expect(t).toContain('Một số gia đình · 1');
    expect(t).toContain('Một số gia đình · 2');
    expect(t).toContain('Gia đình nội bộ');
    // Who has it beyond that: Premium families, the beta list, per-family choices.
    expect(t).toContain('12 gia đình Premium');
    expect(t).toContain('Bật riêng 1 · tắt riêng 0');
    expect(t).toContain('2 gia đình trong beta');
    // Bật: one switch per row with a flag (Mẫu kỷ niệm Premium has none); off ones say so.
    expect(switches(raw)).toBe(28);
    expect(raw).toContain('aria-label="Bật “Nhịp lớn lên”"');
    expect(t.match(/Đang tắt/g)?.length).toBe(offRows + 1);
    expect(disabledSwitches(raw)).toBe(0);
    // The limits fold under the list; Mua gói trong app is on Gói Premium.
    expect(t).toContain('Giới hạn hiện tại');
    expect(t).toContain('Mua gói trong app ở Gói Premium');
    expect(listFilters.map((f) => messages.en[`hub.filter.${f}`])).toEqual([
      'All',
      'Free',
      'Premium',
      'Beta',
      'Technical',
    ]);
  });

  it('Vận hành reads it all; Kỹ sư may change tiers, who uses what and the switches', () => {
    const ops = render(<HubFeaturesView hub={hub} flags={listFlags} onChanged={noop} />, ['ops']);
    expect(ops).not.toContain('aria-label="Gói của');
    expect(ops).not.toContain('aria-label="Ai được dùng “');
    expect(disabledSwitches(ops)).toBe(switches(ops));
    const eng = render(<HubFeaturesView hub={hub} flags={listFlags} onChanged={noop} />, ['eng']);
    expect(eng).toContain('aria-label="Gói của “Nhịp lớn lên”"');
    expect(eng).toContain('aria-label="Ai được dùng “Nhịp lớn lên”"');
    expect(disabledSwitches(eng)).toBe(0);
    // Without `staffFlags` yet: the catalogue rows, no limits.
    const early = text(render(<HubFeaturesView hub={hub} flags={null} onChanged={noop} />));
    expect(early).not.toContain(messages.vi['flag.invites']!);
    expect(early).not.toContain('Giới hạn hiện tại');
  });

  it("a feature's detail shows its parts and beta list; a switch's what turning it off does", () => {
    const can = { tier: true, toggle: true, rollout: true };
    const assistant = text(
      render(
        <FeatureDetail
          row={hub.features[2]!}
          premiumFamilies={12}
          can={can}
          onScope={noop}
          onToggle={noop}
          onChanged={noop}
        />,
      ),
    );
    for (const k of ['assistant', 'assistant_images', 'assistant_care', 'assistant_upsell']) {
      expect(assistant).toContain(messages.vi[`flag.${k}`]!);
    }
    expect(assistant).toContain('Chính');
    expect(assistant).toContain(
      `Công tắc kỹ thuật cùng nhóm, cũng trong danh sách: ${messages.vi['flag.assistant_live']}, ${messages.vi['flag.assistant_writes']}.`,
    );
    expect(assistant).toContain('F-7Q2K');
    expect(assistant).toContain('Chưa mở cho người khác');
    const beta = text(
      render(
        <FeatureDetail
          row={hub.features[5]!}
          premiumFamilies={12}
          can={can}
          onScope={noop}
          onToggle={noop}
          onChanged={noop}
        />,
      ),
    );
    expect(beta).toContain('Danh sách beta · 2 gia đình');
    expect(beta).toContain('F-ABCD');
    const graced = text(
      render(
        <FeatureDetail
          row={hub.features[4]!}
          premiumFamilies={12}
          can={can}
          onScope={noop}
          onToggle={noop}
          onChanged={noop}
        />,
      ),
    );
    expect(graced).toContain('Chuyển từ Beta sang Premium: gia đình đã dùng trước đó giữ quyền');
    expect(graced).toContain('mặc định: Beta');
    const night = listRows(hub, listFlags).find((r) => r.key === 'night_auto')!;
    if (night.kind !== 'system') throw new Error('night_auto is a switch');
    const sw = text(render(<SwitchDetail r={night} can={can} onScope={noop} onToggle={noop} />));
    expect(sw).toContain(messages.vi['flag.night_auto.desc']!);
    expect(sw).toContain(`Khi tắt: ${messages.vi['flag.night_auto.offEffect']}`);
    expect(sw).toContain('Gói Công tắc hệ thống');
    expect(sw).toContain('Một số gia đình · 2');
    expect(sw).toContain('F-ABCD');
    expect(sw).toContain('Minh Kỹ sư · 20/10');
  });

  it('a tier change asks the server how many families it touches first (dry run), then applies', async () => {
    const answer = {
      feature: 'memory_story' as const,
      from: 'beta' as FeatureTier,
      tier: 'premium' as FeatureTier,
      affected: 4,
      graceUntil: '2026-11-20T05:00:00.000Z',
      applied: false,
    };
    const { api, calls } = fakeApi({ staffFeatureSetTier: answer });
    expect(await previewTierChange(api, 'memory_story', 'premium')).toEqual(answer);
    await applyTierChange(api, 'memory_story', 'premium');
    expect(calls).toEqual([
      {
        name: 'staffFeatureSetTier',
        data: { feature: 'memory_story', tier: 'premium', dryRun: true },
      },
      { name: 'staffFeatureSetTier', data: { feature: 'memory_story', tier: 'premium' } },
    ]);
    const beta = row('memory_story');
    const raw = render(
      <TierDialog row={beta} tier="premium" onClose={noop} onDone={noop} initialAnswer={answer} />,
    );
    const t = text(raw);
    expect(t).toContain('Đổi gói “Video kỷ niệm”: Beta → Premium?');
    expect(t).toContain('4 gia đình trong beta sẽ giữ quyền 30 ngày, đến hết 20/11/2026');
    expect(raw).not.toMatch(/<button[^>]*disabled=""[^>]*>Chuyển sang Premium/);
    // While the count is on its way, nothing can be confirmed.
    const waiting = render(<TierDialog row={beta} tier="premium" onClose={noop} onDone={noop} />);
    expect(text(waiting)).toContain('Đang đếm số gia đình bị ảnh hưởng');
    expect(waiting).toMatch(/<button[^>]*disabled=""[^>]*>Chuyển sang Premium/);
    // Every move has its sentence, in both languages.
    for (const from of featureTiers)
      for (const to of featureTiers.filter((x) => x !== from)) {
        expect(messages.vi[tierNoteId(from, to)], `${from}→${to}`).toBeTruthy();
        expect(messages.en[tierNoteId(from, to)], `${from}→${to}`).toBeTruthy();
      }
  });

  it('Ai được dùng is one choice, for features and switches alike; "none" is not "Bật" off', async () => {
    expect(scopeChoice({ scope: 'all', percent: 0 })).toBe('all');
    expect(scopeChoice({ scope: 'internal', percent: 0 })).toBe('internal');
    expect(scopeChoice({ scope: 'internal', percent: 0, families: ['F-7Q2K'] })).toBe('some');
    expect(scopeChoice({ scope: 'percent', percent: 25 })).toBe('percent');
    expect(scopeChoice({ scope: 'percent', percent: 0 })).toBe('none');
    expect(scopeChoice({ scope: 'percent', percent: 100 })).toBe('all');
    expect(scopeChoices.map((c) => scopeFields(c, 25, ['F-7Q2K']))).toEqual([
      { scope: 'all' },
      { scope: 'internal', families: ['F-7Q2K'] },
      { scope: 'percent', percent: 25 },
      { scope: 'internal', families: [] },
      { scope: 'percent', percent: 0 },
    ]);
    const { api, calls } = fakeApi({ staffFeatureSetRollout: {}, staffSetFlag: {} });
    const assistant = hub.features[2]!;
    const main: SwitchTarget = { kind: 'feature', row: assistant, flag: assistant.flag! };
    const part: SwitchTarget = { kind: 'feature', row: assistant, flag: assistant.subFlags[1]! };
    const night = listRows(hub, listFlags).find((r) => r.key === 'night_auto')!;
    const sw: SwitchTarget = { kind: 'system', flag: night.kind === 'system' ? night.flag : null! };
    await setScope(api, main, scopeFields('some', 10, ['F-ABCD']));
    await setScope(api, part, scopeFields('percent', 50));
    await setScope(api, sw, scopeFields('all'));
    await setEnabled(api, main, false, 'Tạm dừng');
    await setEnabled(api, sw, false, null);
    expect(calls).toEqual([
      {
        name: 'staffFeatureSetRollout',
        data: { feature: 'assistant', scope: 'internal', families: ['F-ABCD'] },
      },
      {
        name: 'staffFeatureSetRollout',
        data: { feature: 'assistant', flag: 'assistant_care', scope: 'percent', percent: 50 },
      },
      {
        name: 'staffSetFlag',
        data: { key: 'night_auto', enabled: true, scope: 'all', percent: 100, notice: null },
      },
      {
        name: 'staffFeatureSetRollout',
        data: { feature: 'assistant', enabled: false, notice: 'Tạm dừng' },
      },
      {
        name: 'staffSetFlag',
        data: { key: 'night_auto', enabled: false, scope: 'internal', percent: 0, notice: null },
      },
    ]);
    for (const c of calls) expect(c.data).not.toHaveProperty('reason');
    // "Một số gia đình" picks families; a Beta feature also edits its beta list; off says so.
    const beta = hub.features[5]!;
    const some = text(
      render(
        <ScopeDialog
          target={{ kind: 'feature', row: beta, flag: beta.flag! }}
          choice="some"
          onClose={noop}
          onDone={noop}
        />,
      ),
    );
    expect(some).toContain('Ai được dùng “Tự lưu kỷ niệm”');
    expect(some).toContain('Gia đình được chọn (cùng nhóm thử nội bộ)');
    expect(some).toContain('Danh sách beta · 2 gia đình');
    expect(some).toContain('Đang tắt: lựa chọn chỉ có hiệu lực khi bật lại.');
    const share = render(<ScopeDialog target={sw} choice="percent" onClose={noop} onDone={noop} />);
    expect(text(share)).toContain('10% 25% 50%');
    expect(text(share)).not.toContain('Danh sách beta');
    const premium = text(
      render(
        <ScopeDialog
          target={{ kind: 'feature', row: hub.features[1]!, flag: hub.features[1]!.flag! }}
          choice="all"
          onClose={noop}
          onDone={noop}
        />,
      ),
    );
    expect(premium).toContain('người có Premium luôn dùng được');
  });

  it('Bật off turns a feature, one part or a switch off for everyone, with the in-app notice', () => {
    const assistant = hub.features[2]!;
    const off = text(
      render(
        <ToggleDialog
          target={{ kind: 'feature', row: assistant, flag: assistant.flag! }}
          onClose={noop}
          onDone={noop}
        />,
      ),
    );
    expect(off).toContain('Tắt “Trợ lý (chat, ảnh, hướng dẫn chăm sóc)” cho mọi gia đình?');
    expect(off).toContain('kể cả người có Premium');
    expect(off).toContain('Báo cho gia đình trong app');
    expect(off).toContain(
      '“Trợ lý (chat, ảnh, hướng dẫn chăm sóc)” đang tạm dừng một chút, chúng mình sẽ mở lại sớm.',
    );
    expect(off).not.toContain('khẩn');
    const part = text(
      render(
        <ToggleDialog
          target={{ kind: 'feature', row: assistant, flag: assistant.subFlags[0]! }}
          onClose={noop}
          onDone={noop}
        />,
      ),
    );
    expect(part).toContain(`Bật lại “${messages.vi['flag.assistant_images']}”?`);
    expect(part).not.toContain('Báo cho gia đình');
    const media = listRows(hub, listFlags).find((r) => r.key === 'media_upload')!;
    const sw = text(
      render(
        <ToggleDialog
          target={{ kind: 'system', flag: media.kind === 'system' ? media.flag : null! }}
          onClose={noop}
          onDone={noop}
        />,
      ),
    );
    expect(sw).toContain(`Tắt “${messages.vi['flag.media_upload']}” cho mọi gia đình?`);
    expect(sw).toContain(messages.vi['flag.media_upload.offEffect']!);
  });
});

describe('Tính năng & Premium › Gia đình', () => {
  const answer: StaffHubFamilyAnswer = {
    matchedBy: 'code',
    matches: [{ code: 'F-7Q2K', owner: 'n***@gmail.com', babies: 2 }],
    family,
  };

  it('finds a family by code, email or nickname; several matches are listed to pick from', async () => {
    const { api, calls } = fakeApi({ staffFeatureFamily: answer });
    expect(await findHubFamily(api, '  Bông ')).toEqual(answer);
    expect(calls).toEqual([{ name: 'staffFeatureFamily', data: { q: 'Bông' } }]);
    const many: StaffHubFamilyAnswer = {
      matchedBy: 'nickname',
      matches: [
        { code: 'F-7Q2K', owner: 'n***@gmail.com', babies: 2 },
        { code: 'F-ABCD', owner: 't***@gmail.com', babies: 1 },
      ],
      family: null,
    };
    const t = text(render(<HubFamilies initial={many} now={now} />));
    expect(t).toContain('2 gia đình khớp');
    expect(t).toContain('Theo tên gọi của bé: chọn đúng gia đình');
    expect(t).toContain('F-ABCD t***@gmail.com 1 bé');
    expect(t).not.toContain('Bật toàn bộ Premium');
    const none = text(
      render(<HubFamilies initial={{ matchedBy: 'email', matches: [], family: null }} />),
    );
    expect(none).toContain('Không tìm thấy gia đình nào.');
  });

  it('the family card: one Free | Premium switch; per-feature settings behind Nâng cao', () => {
    const card = text(render(<HubFamilies initial={answer} now={now} />, ['admin']));
    expect(card).toContain(
      'Gói của gia đình Premium toàn bộ · không thời hạn Đổi ngày kết thúc Miễn phí Premium',
    );
    expect(card).toContain('Tuỳ chỉnh riêng từng tính năng (nâng cao)');
    expect(card).not.toContain('Lý do');
    const raw = render(
      <>
        <FamilyFeatures family={family} canOverride canBeta onChanged={noop} />
      </>,
      ['admin'],
    );
    const t = card + text(raw);
    expect(t).toContain('F-7Q2K');
    expect(t).toContain('Gói Premium');
    expect(t).toContain('Hoa Kỳ · US');
    expect(t).toContain('Gia đình nội bộ');
    // Admin Premium skips the country (D-089): said plainly, not as a blocker.
    expect(t).toContain('Premium được cấp (Bật toàn bộ Premium) vẫn dùng được');
    expect(t).toContain('5/6 đang dùng được');
    expect(t).toContain('Có · Miễn phí');
    expect(t).toContain('Có · Premium được cấp');
    expect(t).toContain('Có · được bật riêng');
    // The override ends at the start of 2/11 in Vietnam: 1/11 is its last day.
    expect(t).toContain('Chọn riêng bởi Linh · đến hết 1/11/2026');
    expect(t).toContain('Có · giữ quyền sau khi chuyển sang Premium');
    expect(t).toContain('đến hết 20/11/2026');
    expect(t).toContain('Không · chưa ở trong beta');
    // Bật / Tắt / Theo quy tắc on every row; the current choice is pressed.
    expect(raw.match(/aria-label="Bật riêng “/g)?.length).toBe(family.features.length);
    expect(t).toContain('Bật Tắt Theo quy tắc');
    expect(raw).toMatch(/aria-checked="true"[^>]*>Bật</);
    // Beta features: add or remove this family.
    expect(t).toContain('Thêm vào beta');
    expect(t).toContain('Bỏ khỏi beta');
    expect(t).not.toContain('Lý do');
  });

  it('Vận hành reads; only Toàn quyền (premium.grant) turns Premium or overrides on', () => {
    const planSwitch = 'aria-label="Gói của gia đình"';
    const features = (roles: StaffRole[], grant: boolean, beta: boolean) =>
      render(
        <FamilyFeatures family={family} canOverride={grant} canBeta={beta} onChanged={noop} />,
        roles,
      );
    const opsCard = render(<FamilyCard family={family} now={now} onChanged={noop} />, ['ops']);
    expect(opsCard).not.toContain(planSwitch);
    const ops = features(['ops'], false, false);
    const lockedChoices = (raw: string) => raw.match(/role="radio"[^>]*disabled=""/g)?.length ?? 0;
    expect(lockedChoices(ops)).toBe(3 * family.features.length);
    expect(text(ops)).not.toContain('Thêm vào beta');
    const engCard = render(<FamilyCard family={family} now={now} onChanged={noop} />, ['eng']);
    expect(engCard).not.toContain(planSwitch);
    const eng = features(['eng'], false, true);
    // Kỹ sư (Tính năng · Sửa) manages beta lists, not Premium.
    expect(text(eng)).toContain('Thêm vào beta');
    expect(lockedChoices(eng)).toBe(3 * family.features.length);
    expect(render(<FamilyCard family={family} now={now} onChanged={noop} />, ['admin'])).toContain(
      planSwitch,
    );
    const admin = features(['admin'], true, true);
    expect(lockedChoices(admin)).toBe(0);
  });

  it('overrides, "Bật toàn bộ Premium" and beta send no reason', async () => {
    const { api, calls } = fakeApi({
      staffFeatureSetOverride: {},
      staffFeatureFullPremium: { on: true, until: null },
      staffFeatureSetBeta: {},
    });
    await setFeatureOverride(api, 'F-7Q2K', 'assistant', 'on');
    await setFeatureOverride(api, 'F-7Q2K', 'assistant', null);
    await setFullPremium(api, 'F-7Q2K', true, null);
    await setFullPremium(api, 'F-7Q2K', true, '2026-11-30');
    await setFullPremium(api, 'F-7Q2K', false, '2026-11-30');
    await setBetaMember(api, 'F-7Q2K', 'auto_save', true);
    expect(calls).toEqual([
      {
        name: 'staffFeatureSetOverride',
        data: { code: 'F-7Q2K', feature: 'assistant', state: 'on' },
      },
      {
        name: 'staffFeatureSetOverride',
        data: { code: 'F-7Q2K', feature: 'assistant', state: null },
      },
      // No end date by default ("đến khi tắt").
      { name: 'staffFeatureFullPremium', data: { code: 'F-7Q2K', on: true } },
      // A last day is included: the grant ends at the start of the next Vietnam day.
      {
        name: 'staffFeatureFullPremium',
        data: { code: 'F-7Q2K', on: true, until: '2026-11-30T17:00:00.000Z' },
      },
      { name: 'staffFeatureFullPremium', data: { code: 'F-7Q2K', on: false } },
      {
        name: 'staffFeatureSetBeta',
        data: { code: 'F-7Q2K', feature: 'auto_save', member: true },
      },
    ]);
    expect(endOfDay('2026-11-30')).toBe('2026-11-30T17:00:00.000Z');
    for (const c of calls) expect(c.data).not.toHaveProperty('reason');
    // The dialog: an optional end date, empty by default.
    const raw = render(<FullPremiumDialog code="F-7Q2K" onClose={noop} onDone={noop} />);
    expect(text(raw)).toContain('Bật toàn bộ Premium cho F-7Q2K?');
    expect(text(raw)).toContain('Ngày kết thúc (không bắt buộc)');
    expect(text(raw)).toContain('Để trống: đến khi tắt.');
    expect(raw).toContain('type="date"');
    expect(raw).toContain('value=""');
  });

  it('only old staff-written grants can be revoked here; "toàn bộ" has its switch', () => {
    const [full, promo] = family.grants;
    expect(grantRevocable(full!)).toBe(false);
    expect(grantRevocable(promo!)).toBe(true);
    expect(grantRevocable({ ...promo!, status: 'revoked' })).toBe(false);
    expect(grantRevocable({ ...promo!, fromCampaign: true })).toBe(false);
    expect(grantRevocable({ ...promo!, source: 'paid', id: 'promo_x' })).toBe(false);
  });
});

describe('Tính năng & Premium › Lịch sử', () => {
  it('the hub lines read as actions, who and when, no reason', () => {
    const t = text(render(<HubHistory recent={hub.recent} />, ['admin']));
    expect(t).toContain('Đổi gói “Video kỷ niệm” sang Premium');
    expect(t).toContain('Bật riêng “Trợ lý (chat, ảnh, hướng dẫn chăm sóc)” cho F-7Q2K');
    expect(t).toContain('Bật toàn bộ Premium cho F-7Q2K');
    expect(t).toContain('Linh · 21/10');
    expect(t).toContain('Nhật ký 30 ngày');
    const en = text(render(<HubHistory recent={hub.recent} />, ['admin'], 'en'));
    expect(en).toContain('Moved “Memory videos” to Premium');
    expect(en).toContain('Turned “Assistant (chat, photos, care guidance)” on for F-7Q2K');
  });
});

describe('Tính năng & Premium › messages', () => {
  it('the catalogue, groups, tiers, reasons and tabs have vi and en', () => {
    const ids = [
      ...featureCatalogue.flatMap((f) => [f.labelId, f.helpId]),
      ...featureGroups.map((g) => `hub.group.${g}`),
      ...featureTiers.map((t) => `hub.tier.${t}`),
      'hub.tier.system',
      ...listGroups.map((g) => `hub.group.${g}`),
      ...listFilters.map((f) => `hub.filter.${f}`),
      ...scopeChoices.flatMap((c) => [`hub.scopeNote.${c}`]),
      ...['all', 'some', 'percent', 'internal'].map((c) => `hub.scope.${c}`),
      ...['premium', 'beta', 'other'].map((t) => `hub.scope.none.${t}`),
      ...featureExplanations.map((w) => `hub.why.${w}`),
      ...hubTabs.map((t) => `hub.tab.${t}`),
      ...['on', 'off', 'rule'].map((c) => `hub.override.${c}`),
      ...['code', 'email', 'nickname'].map((m) => `hub.family.matchedBy.${m}`),
      ...['config', 'ai'].map((s) => `hub.plan.${s}`),
      ...['kill', 'override', 'premium', 'beta', 'free'].map((r) => `hub.rules.${r}`),
      ...['tier', 'beta', 'beta.add', 'beta.remove', 'override', 'override.clear'].map(
        (a) => `audit.hub.${a}`,
      ),
    ];
    for (const id of ids) {
      expect(messages.vi[id], id).toBeTruthy();
      expect(messages.en[id], id).toBeTruthy();
    }
  });
});

// ---------- D-090: no reason fields anywhere ----------

const team: StaffTeam = {
  members: [
    {
      uid: 'u2',
      name: 'Hà Vũ',
      email: 'ha@example.com',
      roles: ['support'],
      status: 'active',
      accessUntil: null,
      lastSeenAt: null,
      createdAt: null,
    },
  ],
  invites: [],
  roles: staffRoles.map((id) => ({
    id,
    name: id,
    levels: staffRoleTemplates[id],
    builtin: true,
    locked: ['owner', 'admin', 'qa'].includes(id),
    members: 1,
    updatedBy: null,
    updatedAt: null,
  })),
  kpis: { members: 1, sensitive: 0, invites: 0 },
};

const ticket: TicketDetail = {
  id: 't_00000000000000000001',
  ticket: 'CL-1042',
  title: 'Không tải được video',
  category: 'memories',
  email: 'n***@gmail.com',
  status: 'claimed',
  createdAt: '2026-10-21T03:00:00Z',
  claimedBy: 'Linh Trần',
  feedbackType: null,
  contactable: true,
  message: 'Video không lên.',
  role: 'owner',
  family: null,
  diagnostics: null,
  thread: [],
  hasScreenshot: false,
};

const storageRow: StorageRow = {
  id: 'sr_1',
  code: 'F-7Q2K',
  family: 'F-7Q2K',
  babies: 1,
  people: 2,
  usedBytes: 9 * 1024 ** 3,
  quotaBytes: 10 * 1024 ** 3,
  requestedGb: 10,
  message: null,
  createdAt: '2026-10-21T03:00:00Z',
  decidedAt: null,
  grantedGb: null,
  metrics: {
    photoBytes: 1,
    videoBytes: 1,
    otherBytes: 1,
    freeBytes: 1,
    previousGrants: 0,
    ownerCreatedAt: null,
    requesterIsOwner: true,
  },
};

const job: JobRow = {
  id: 'del_x',
  code: 'DJ-2226',
  type: 'deleteAccount',
  email: 'n***@gmail.com',
  createdAt: '2026-10-21T01:00:00Z',
  progress: 0.6,
  state: 'failed',
  steps: ['storage', 'personal'],
  step: 1,
  failedStep: 'personal',
  rerunRequest: { byUid: 'u9', by: 'Minh Phạm', reason: '', at: '2026-10-21T02:00:00Z' },
};

const flagsView: FlagsView = {
  flags: launchedFlagDefaults,
  limits: {
    familyQuotaBytes: 10 * 1024 ** 3,
    videoMaxDurationSec: null,
    videoMaxBytes: 4 * 1024 ** 3,
    videoWifiOnlyDefault: true,
    mediaItemsPerAdd: 30,
    exportLinkTtlHours: 24,
    storageRequestAmountsGb: [10, 20],
    autoSaveItemsPerApprove: 200,
  },
  lastEdit: {},
  recent: [],
};

const premiumView: StaffPremiumView = {
  config: {
    policyVersion: 'policy-v1',
    regions: { advanced: ['VN'] },
    quotas: {
      video: {
        free: { limit: 1, window: 'calendar_month' },
        premium: { limit: 5, window: 'billing_period' },
      },
      ai: { perBabyPerDay: 1, perFamilyPerMonth: 10 },
      assistant: { free: 20, premium: 200, textCredits: 1, imageCredits: 3 },
    },
    betaCampaigns: [],
  } as unknown as StaffPremiumView['config'],
  stored: true,
  environment: 'test',
  recent: [],
};

describe('No reason fields anywhere (D-090)', () => {
  // A reason field was a "Lý do (…)" label over a textarea; nothing on these screens asks one.
  const screens: Array<[string, ReactNode, StaffRole[]]> = [
    ['support reply', <TicketDetailView ticket={ticket} now={now} onChanged={noop} />, ['support']],
    [
      'storage grant',
      <DecideDialog row={storageRow} kind="grant" onClose={noop} onDone={noop} />,
      ['admin'],
    ],
    [
      'storage decline',
      <DecideDialog row={storageRow} kind="decline" onClose={noop} onDone={noop} />,
      ['ops'],
    ],
    ['jobs rerun', <RerunDialog row={job} mode="request" onClose={noop} onDone={noop} />, ['eng']],
    [
      'jobs approve',
      <RerunDialog row={job} mode="approve" onClose={noop} onDone={noop} />,
      ['admin'],
    ],
    ['staff invite', <InviteDialog team={team} onClose={noop} onDone={noop} />, ['owner']],
    [
      'staff remove',
      <MemberDialog
        team={team}
        member={team.members[0]}
        op="remove"
        onClose={noop}
        onDone={noop}
      />,
      ['owner'],
    ],
    [
      'content reject',
      <ContentActDialog
        kind="article"
        id="art_a1"
        action="reject"
        title="Bài"
        requireReview={false}
        today="2026-10-21"
        sameEditor={false}
        onClose={noop}
        onDone={noop}
      />,
      ['admin'],
    ],
    [
      'content unpublish',
      <ContentActDialog
        kind="article"
        id="art_a1"
        action="unpublish"
        title="Bài"
        requireReview={false}
        today="2026-10-21"
        sameEditor={false}
        onClose={noop}
        onDone={noop}
      />,
      ['admin'],
    ],
    [
      'first aid reject',
      <FirstAidActDialog
        act="reject"
        versionId="fv_00112233445566aa"
        requireReview
        initialReview={null}
        onClose={noop}
        onDone={noop}
      />,
      ['admin'],
    ],
    [
      'rhythm reject',
      <RhythmActDialog
        doc="reference"
        act="reject"
        versionId="rv_00112233445566aa"
        requireReview
        onClose={noop}
        onDone={noop}
      />,
      ['admin'],
    ],
    [
      'keepsakes discard',
      <KeepsakesActDialog
        act="discard"
        versionId="kv_00112233445566aa"
        onClose={noop}
        onDone={noop}
      />,
      ['admin'],
    ],
    [
      'flag off',
      <FlagDialog
        change={{
          key: 'invites',
          kind: 'off',
          next: { ...launchedFlagDefaults.invites, enabled: false },
        }}
        onClose={noop}
        onDone={noop}
      />,
      ['eng'],
    ],
    ['hub features', <HubFeaturesView hub={hub} flags={listFlags} onChanged={noop} />, ['admin']],
    [
      'hub tier',
      <TierDialog row={hub.features[0]!} tier="premium" onClose={noop} onDone={noop} />,
      ['admin'],
    ],
    [
      'hub off',
      <ToggleDialog
        target={{ kind: 'feature', row: hub.features[0]!, flag: hub.features[0]!.flag! }}
        onClose={noop}
        onDone={noop}
      />,
      ['admin'],
    ],
    [
      'hub who',
      <ScopeDialog
        target={{ kind: 'feature', row: hub.features[5]!, flag: hub.features[5]!.flag! }}
        choice="some"
        onClose={noop}
        onDone={noop}
      />,
      ['admin'],
    ],
    ['hub family', <FamilyCard family={family} now={now} onChanged={noop} />, ['admin']],
    ['full premium', <FullPremiumDialog code="F-7Q2K" onClose={noop} onDone={noop} />, ['admin']],
    [
      'premium plan',
      <PremiumPlanView data={premiumView} flags={flagsView} onChanged={noop} />,
      ['admin'],
    ],
  ];
  for (const [name, node, roles] of screens) {
    it(name, () => {
      const raw = render(node, roles);
      expect(text(raw)).not.toMatch(/Lý do|lý do/);
      expect(raw).not.toMatch(/name="reason"|id="reason"/);
      expect(text(render(node, roles, 'en'))).not.toMatch(/\breason\b/i);
    });
  }

  it('no source file has a reason field, and no catalog has its label', () => {
    const src = join(__dirname, '../src');
    const files = (dir: string): string[] =>
      readdirSync(dir, { withFileTypes: true }).flatMap((e) =>
        e.isDirectory()
          ? files(join(dir, e.name))
          : /\.tsx?$/.test(e.name)
            ? [join(dir, e.name)]
            : [],
      );
    for (const f of files(src)) {
      const code = readFileSync(f, 'utf8');
      expect(code, f).not.toMatch(/ReasonField|reasonOk|ReasonDialog|reason\.label/);
    }
    for (const catalog of [messages.vi, messages.en]) {
      expect(Object.keys(catalog).filter((id) => id.startsWith('reason.'))).toEqual([]);
    }
  });
});
