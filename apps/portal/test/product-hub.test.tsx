import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import {
  levelsForRoles,
  productCoverage,
  type FeatureSection,
  type ProductConflictRecord,
  type StaffRole,
} from '@child-life/contracts';
import type { ReactNode } from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider } from 'react-intl';
import { describe, expect, it } from 'vitest';
import { ApiContext, type Api } from '../src/api';
import { StaffContext, routeOf } from '../src/context';
import { messages } from '../src/messages';
import { allowedRoute } from '../src/Shell';
import { CatalogView, filterFeatures, filtersOf, noFilters, searchOf } from '../src/screens/product/Catalog';
import { FeatureView } from '../src/screens/product/Feature';
import { ProductHubScreen, productPlaceOf } from '../src/screens/product/index';
import { OverviewView } from '../src/screens/product/Overview';
import { PlansView } from '../src/screens/product/Plans';
import { ChangeSetDetail, LibraryView, ReviewQueue } from '../src/screens/product/Sources';
import type {
  ChangeSetView,
  FeatureRow,
  FeatureView as FeatureData,
  OverviewView as OverviewData,
  PlansView as PlansData,
} from '../src/screens/product/types';

// Sản phẩm · Product Hub (D-155): routes, access, filters and the views, from fixtures.

function render(node: ReactNode, roles: StaffRole[] = ['admin'], locale: 'vi' | 'en' = 'vi', uid = 's1') {
  const api: Api = { call: () => new Promise(() => undefined) } as unknown as Api;
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
        <StaffContext.Provider value={{ uid, email: 'linh@example.com', name: 'Linh', roles, levels: levelsForRoles(roles) }}>
          {node}
        </StaffContext.Provider>
      </ApiContext.Provider>
    </IntlProvider>,
  );
}
const text = (html: string) =>
  html.replace(/<[^>]+>/g, ' ').replace(/&amp;/g, '&').replace(/\s+/g, ' ');

const row = (over: Partial<FeatureRow>): FeatureRow => ({
  id: 'care.feeding',
  name: { vi: 'Cho ăn', en: 'Feeding' },
  pillar: 'care',
  chapters: ['ch01'],
  platforms: ['ios', 'android'],
  lifecycle: 'built',
  implementation: 'implemented',
  verification: 'code_read',
  release: 'not_released',
  confidence: 'high',
  hubKey: null,
  tier: null,
  coverage: 30,
  band: 'low',
  missing: ['problem'],
  stale: 0,
  conflicts: 0,
  syncedAt: '2026-10-31T09:00:00Z',
  revision: 'e60e569bad3225cf',
  ...over,
});
const rows: FeatureRow[] = [
  row({}),
  row({ id: 'platform.lumi', name: { vi: 'Lumi', en: 'Lumi assistant' }, pillar: 'platform', hubKey: 'assistant', tier: 'premium', coverage: 75, band: 'high', conflicts: 1 }),
  row({ id: 'remember.letter', name: { vi: 'Thư của con', en: 'Letter' }, pillar: 'remember', lifecycle: 'designed', implementation: 'not_found', verification: 'unverified', stale: 1 }),
  row({ id: 'grow.insights', name: { vi: 'Hiểu con', en: 'Care insights' }, pillar: 'grow', lifecycle: 'in_development', verification: 'tests_pass' }),
];

const conflict: ProductConflictRecord = {
  id: 'cf_1',
  topic: 'plan_model',
  feature: null,
  summary: 'docs/product/plans-credits-analysis.md names plans (Free / Plus / Pro) that the code does not have (Free · Premium · Beta).',
  tiers: null,
  claims: [
    { path: 'docs/product/plans-credits-analysis.md', anchor: 'top', authority: 'draft_spec', text: 'Free / Plus / Pro', date: '2026-10-16' },
    { path: 'packages/contracts/src/features-hub.ts', anchor: 'featureTiers', authority: 'code', text: "featureTiers = ['free', 'premium', 'beta']", date: null },
  ],
  status: 'open',
};

function featureData(sections: Partial<Record<string, Partial<FeatureSection>>> = {}): FeatureData {
  const keys = ['summary', 'problem', 'value', 'ux', 'rules', 'edgeCases', 'access', 'metrics', 'issues', 'decisions'] as const;
  return {
    feature: {
      id: 'care.feeding',
      name: { vi: 'Cho ăn', en: 'Feeding' },
      pillar: 'care',
      aliases: [],
      hubKey: null,
      capabilities: ['module.basic'],
      platforms: ['ios', 'android'],
      chapters: ['ch01'],
      lifecycle: 'built',
      implementation: 'implemented',
      verification: 'code_read',
      release: 'not_released',
      confidence: 'high',
      dependsOn: [],
      note: '',
      facts: {
        modules: ['apps/mobile/lib/features/care/care_sheets.dart'],
        functions: ['firebase/functions/src/care.ts'],
        callables: ['saveCareRecord'],
        tests: ['apps/mobile/test/features/care_test.dart'],
        docs: [],
        figma: [],
        decisions: ['D-001'],
        codeCitations: [{ id: 'D-001', at: 'apps/mobile/lib/features/care/care_sheets.dart:1' }],
        deadGlobs: [],
      },
      revision: 'e60e569bad3225cf',
      syncedAt: '2026-10-31T09:00:00Z',
    },
    sections: keys.map((k) => ({ key: k, draft: null, approved: null, stale: null, ...sections[k] })),
    supersededCitations: [],
    coverage: productCoverage({
      sections: {},
      hasTier: true,
      openTierConflict: false,
      moduleCount: 1,
      testCount: 1,
      decisionCount: 1,
      metricsInstrumented: false,
      openConflicts: 0,
    }),
    access: { hubKey: null, defaultTier: null, liveTier: null, credits: false, flags: [], capabilities: ['module.basic'] },
    sources: [],
    decisions: [{ id: 'D-001', kind: 'D', title: 'Pumping is not intake', date: '2026-10-10', status: 'approved' }],
    conflicts: [],
    dependents: ['platform.lumi'],
    canEdit: true,
    canApprove: true,
  };
}

describe('routes and access', () => {
  it('opens tabs and items from the address', () => {
    expect(routeOf('/product/features/care.feeding')).toBe('product');
    expect(productPlaceOf('/product')).toEqual({ tab: 'overview' });
    expect(productPlaceOf('/product/features/care.feeding')).toEqual({ tab: 'features', feature: 'care.feeding' });
    expect(productPlaceOf('/product/sources/review/cs1')).toEqual({ tab: 'sources', source: null, changeSet: 'cs1' });
    expect(productPlaceOf('/product/sources/src_1')).toEqual({ tab: 'sources', source: 'src_1', changeSet: null });
  });
  it('analysts reach Sản phẩm; support does not', () => {
    expect(allowedRoute(levelsForRoles(['analyst']), 'product')).toBe('product');
    expect(allowedRoute(levelsForRoles(['support']), 'product')).not.toBe('product');
  });
  it('shows only the Phase 1 tabs', () => {
    const html = text(render(<ProductHubScreen initial={{ tab: 'plans' }} />));
    for (const t of ['Tổng quan', 'Tính năng', 'Gói & quyền', 'Nguồn tri thức']) expect(html).toContain(t);
    expect(html).not.toContain('Copilot');
  });
});

describe('message catalogs', () => {
  it('every ph.* id the screens use exists in both languages', () => {
    const dir = join(import.meta.dirname, '../src/screens/product');
    const used = new Set<string>();
    for (const f of readdirSync(dir)) {
      const src = readFileSync(join(dir, f), 'utf8');
      for (const m of src.matchAll(/id[=:] ?["'`](ph\.[a-zA-Z0-9_.-]+)["'`]/g)) used.add(m[1]!);
    }
    expect(used.size).toBeGreaterThan(80);
    for (const id of used) {
      expect(messages.vi[id], id).toBeTruthy();
      expect(messages.en[id], id).toBeTruthy();
    }
  });
});

describe('catalog', () => {
  it('reads and writes filters in the address', () => {
    const f = filtersOf('?pillar=care&lifecycle=built&stale=1&bogus=x&tier=nope');
    expect(f).toEqual({ ...noFilters, pillar: 'care', lifecycle: 'built', stale: true });
    expect(searchOf(f)).toBe('?pillar=care&lifecycle=built&stale=1');
    expect(searchOf(noFilters)).toBe('');
  });
  it('filters by pillar, tier, verification, flags and accent-free search', () => {
    expect(filterFeatures(rows, { ...noFilters, tier: 'none' }, '').map((r) => r.id)).toEqual(['care.feeding', 'remember.letter', 'grow.insights']);
    expect(filterFeatures(rows, { ...noFilters, verification: 'open' }, '').map((r) => r.id)).toEqual(['care.feeding', 'platform.lumi', 'remember.letter']);
    expect(filterFeatures(rows, { ...noFilters, conflicts: true }, '').map((r) => r.id)).toEqual(['platform.lumi']);
    expect(filterFeatures(rows, noFilters, 'hieu con').map((r) => r.id)).toEqual(['grow.insights']);
  });
  it('shows four separate statuses, flags code not found, and an empty state', () => {
    const html = text(render(<CatalogView data={{ features: rows, conflictsWithoutFeature: 0 }} />));
    expect(html).toContain('Thư của con');
    expect(html).toContain('Chưa thấy mã');
    expect(html).toContain('1 xung đột');
    const none = text(render(<CatalogView data={{ features: rows, conflictsWithoutFeature: 0 }} initial={{ ...noFilters, pillar: 'care', lifecycle: 'deprecated' }} />));
    expect(none).toContain('Không có tính năng nào khớp bộ lọc');
  });
  it('renders in English', () => {
    expect(text(render(<CatalogView data={{ features: rows, conflictsWithoutFeature: 0 }} />, ['admin'], 'en'))).toContain('Lumi assistant');
  });
});

describe('feature page', () => {
  it('shows the coverage gap and next steps for an undocumented feature (Scenario F)', () => {
    const html = text(render(<FeatureView data={featureData()} />));
    expect(html).toContain('Độ đầy đủ');
    expect(html).toContain('Viết vấn đề người dùng');
    expect(html).toContain('Chưa phát hành');
    expect(html).toContain('Chưa có nội dung.');
  });
  it('keeps the approved text, says it is stale, and shows the draft waiting for approval', () => {
    const approved = {
      body: { vi: 'Bình = thể tích.', en: '' },
      sources: ['docs/product/feeding.md#rules'],
      by: 'Kỹ sư',
      at: '2026-10-30T00:00:00Z',
      approvedBy: 'Admin',
      approvedAt: '2026-10-30T01:00:00Z',
      version: 1,
    };
    const html = text(
      render(
        <FeatureView
          data={featureData({
            summary: {
              approved,
              stale: { since: '2026-10-31T00:00:00Z', paths: ['docs/product/feeding.md'] },
              draft: { ...approved, body: { vi: 'Bình theo ml.', en: '' }, origin: 'staff' },
            },
          })}
        />,
      ),
    );
    expect(html).toContain('Bình = thể tích.');
    expect(html).toContain('Nguồn đã đổi sau khi duyệt: docs/product/feeding.md');
    expect(html).toContain('Bản nháp');
    expect(html).toContain('Bình theo ml.');
    expect(html).toContain('Bản 1 · viết bởi Kỹ sư · duyệt bởi Admin');
  });
  it('a viewer without Sửa sees no edit button', () => {
    const html = render(<FeatureView data={{ ...featureData(), canEdit: false, canApprove: false }} />, ['analyst']);
    expect(html).not.toMatch(/<button[^>]*>\s*Viết\s*<\/button>/);
    expect(render(<FeatureView data={featureData()} />)).toMatch(/<button[^>]*>\s*Viết\s*<\/button>/);
  });
});

describe('overview', () => {
  const base: OverviewData = {
    total: 0,
    byLifecycle: {},
    byPillar: {},
    byPillarLifecycle: {},
    byTier: {},
    byBand: {},
    needVerification: 0,
    released: 0,
    staleFeatures: 0,
    openConflicts: 0,
    sources: 0,
    pending: 1,
    lastSync: null,
    recentDecisions: [],
    recentChanges: [],
  };
  it('before the first approval says so, never zero tiles', () => {
    const html = text(render(<OverviewView data={base} />));
    expect(html).toContain('Chưa có tri thức đã duyệt');
    expect(html).toContain('Đang có 1 bộ thay đổi chờ duyệt.');
  });
  it('labels usage data as unavailable instead of inventing it', () => {
    const html = text(
      render(
        <OverviewView
          data={{ ...base, total: 49, byLifecycle: { built: 40 }, byPillar: { care: 14 }, byPillarLifecycle: { 'care:built': 13 }, lastSync: { revision: 'e60e569bad', at: '2026-10-31T09:00:00Z', by: 'Admin' } }}
        />,
      ),
    );
    expect(html).toContain('Chưa có số liệu sử dụng');
    expect(html).toContain('Revision e60e569b');
  });
});

describe('plans', () => {
  it('is read only, shows default vs live tier and the open conflict (Scenario C)', () => {
    const data: PlansData = {
      catalogue: [{ key: 'assistant', group: 'assistant', defaultTier: 'premium', liveTier: 'free', credits: true, flags: ['assistant'], capabilities: [], features: ['platform.lumi'] }],
      capabilities: [{ key: 'ai.assistance', free: false, premium: true, credits: true }],
      conflicts: [conflict],
      decisions: [{ id: 'D-075', title: 'Assistant v3 answers', date: '2026-10-15' }],
    };
    const html = text(render(<PlansView data={data} />));
    expect(html).toContain('Trang này chỉ để xem');
    expect(html).toContain('Khác mặc định');
    expect(html).toContain('docs/product/plans-credits-analysis.md nêu các gói Free / Plus / Pro');
    expect(html).toContain('Đặc tả nháp');
    expect(html).toContain('D-075');
  });
});

describe('sources and review', () => {
  it('library and empty queue', () => {
    expect(text(render(<LibraryView data={{ sources: [] }} />))).toContain('Chưa có nguồn nào');
    expect(text(render(<ReviewQueue data={{ changeSets: [] }} />))).toContain('Không có gì chờ duyệt');
  });
  const cs: ChangeSetView = {
    id: 'cs1',
    status: 'pending',
    revision: 'e60e569bad3225cf',
    summary: { added: 0, changed: 1, moved: 0, deleted: 0, unchanged: 3, warnings: [] },
    createdBy: 'Kỹ sư',
    createdByUid: 's_eng',
    createdAt: '2026-10-31T09:00:00Z',
    sources: [
      {
        change: 'changed',
        id: 'src_1',
        path: 'docs/product/feeding.md',
        beforePath: 'docs/product/feeding.md',
        title: 'Cho ăn',
        authority: 'draft_spec',
        features: ['care.feeding'],
        chunkCount: 1,
        diff: [{ heading: 'Cho ăn › Rules', change: 'changed', before: 'Bottle = volume.', after: 'Bottle = volume; breast = time.' }],
      },
    ],
    decisions: [],
    features: [],
    conflicts: [],
  };
  it('shows the diff and lets another approver decide (Scenario D)', () => {
    const html = text(render(<ChangeSetDetail data={cs} />, ['admin']));
    expect(html).toContain('Tài liệu đổi (1)');
    expect(html).toContain('Bottle = volume; breast = time.');
    expect(html).toContain('Duyệt và áp dụng');
  });
  it('tells the submitter they cannot approve their own set', () => {
    const html = render(<ChangeSetDetail data={cs} />, ['admin'], 'vi', 's_eng');
    expect(text(html)).toContain('Người gửi không tự duyệt');
    expect(html).toMatch(/<button[^>]*disabled[^>]*>[^<]*<[^>]*>?[^<]*Duyệt và áp dụng|disabled=""[^>]*>Duyệt và áp dụng/);
  });
});
