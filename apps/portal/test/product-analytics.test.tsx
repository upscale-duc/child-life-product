import { renderToStaticMarkup } from 'react-dom/server';
import { IntlProvider } from 'react-intl';
import { describe, expect, it } from 'vitest';
import {
  engagementKinds,
  engagementStages,
  type ProductAnalyticsResult,
} from '@child-life/contracts';
import { messages } from '../src/messages';
import { productAnalyticsEn, productAnalyticsVi } from '../src/messages-product-analytics';
import {
  ProductAnalyticsView,
  analyticsClosedRange,
  productAnalyticsCsv,
} from '../src/screens/ProductAnalytics';

const result: ProductAnalyticsResult = {
  schemaVersion: 2,
  definitionVersion: 1,
  section: 'overview',
  range: { from: '2026-10-01', to: '2026-10-20' },
  reportingZone: 'Asia/Ho_Chi_Minh',
  status: 'ready',
  computedAt: '2026-10-21T03:00:00Z',
  observedThrough: '2026-10-20T03:00:00Z',
  sourceStartAt: '2026-10-01T03:00:00Z',
  collectionEnabled: true,
  stale: false,
  privacyThreshold: 20,
  unsupportedFilters: [],
  metrics: [
    {
      id: 'A02',
      unit: 'users',
      value: 21,
      numerator: null,
      denominator: null,
      status: 'ready',
      reason: 'none',
      windowDays: 20,
      previous: 20,
    },
  ],
  series: [],
  retention: [],
  breakdowns: [],
  engagement: [],
  quality: { unknownActor: null, lateObservations: null, sourceCoverage: 'partial' },
};
function render(data: ProductAnalyticsResult, locale: 'vi' | 'en') {
  return renderToStaticMarkup(
    <IntlProvider
      locale={locale}
      messages={messages[locale]}
      onError={(e) => {
        throw e;
      }}
    >
      <ProductAnalyticsView data={data} />
    </IntlProvider>,
  );
}
describe('live product analytics presentation contracts', () => {
  it('maintains bilingual message parity and renders every section without billing or fixtures', () => {
    expect(Object.keys(productAnalyticsVi).sort()).toEqual(Object.keys(productAnalyticsEn).sort());
    for (const locale of ['vi', 'en'] as const)
      for (const section of [
        'overview',
        'acquisition',
        'memories',
        'engagement',
        'features',
        'cost',
      ] as const) {
        const html = render(
          {
            ...result,
            section,
            ...(section === 'engagement'
              ? {
                  metrics: engagementKinds.map((kind) => ({
                    ...result.metrics[0]!,
                    id: `E_${kind}`,
                  })),
                  engagement: engagementKinds.map((kind) => ({
                    kind,
                    stages: Object.fromEntries(
                      engagementStages.map((s) => [s, null]),
                    ) as ProductAnalyticsResult['engagement'][number]['stages'],
                    conversion: { ...result.metrics[0]!, id: `E_${kind}` },
                    reasons: [{ reason: 'quiet_hours', count: 20 }],
                  })),
                }
              : {}),
          },
          locale,
        );
        expect(html).not.toContain('purchaseStarted');
        expect(html).not.toContain('MRR');
        expect(html).not.toContain('demo data');
      }
  });
  it('distinguishes missing/immature and suppressed data from zero conversions', () => {
    const data = {
      ...result,
      metrics: [
        {
          ...result.metrics[0]!,
          value: null,
          status: 'insufficient' as const,
          reason: 'small_cohort' as const,
        },
      ],
    };
    const html = render(data, 'en');
    expect(html).toContain('Insufficient data');
    expect(html).not.toContain('0%');
    expect(productAnalyticsCsv(data)).toContain('insufficient');
    expect(productAnalyticsCsv(data)).not.toContain('private-user');
  });
  it('exports aggregate metadata, preserves unknown cells and neutralizes CSV formulas', () => {
    const csv = productAnalyticsCsv({
      ...result,
      breakdowns: [{ dimension: 'template', key: '=forged()', count: null }],
    });
    expect(csv).toContain('computed_at');
    expect(csv).toContain('Asia/Ho_Chi_Minh');
    // The cell starts with a fixed dimension prefix, so an injected key cannot become a formula.
    expect(csv).toContain('template:=forged()');
    expect(csv).toContain('"insufficient"');
    expect(csv).not.toContain('NaN');
  });
  it('is easy to scan: KPI tiles first, definitions behind "?", details and caveats folded', () => {
    const html = render(
      {
        ...result,
        breakdowns: [{ dimension: 'platform', key: 'ios', count: 21 }],
        series: [{ day: '2026-10-20', users: 21, families: 20, actions: 40 }],
      } as ProductAnalyticsResult,
      'vi',
    );
    const kpis = html.indexOf('class="kpis"');
    expect(kpis).toBeGreaterThan(-1);
    expect(kpis).toBeLessThan(html.indexOf('Người dùng hoạt động theo ngày'));
    expect(html.indexOf('Người dùng hoạt động theo ngày')).toBeLessThan(
      html.indexOf('Phân nhóm tổng hợp'),
    );
    // Definitions are hints, not paragraphs; the metric table and data caveats are folded.
    expect(html).toContain('aria-label="Xem định nghĩa"');
    expect(html).not.toContain('<details');
    expect(html).toContain('Chi tiết chỉ số');
    expect(html).toContain('1 chỉ số');
    expect(html).not.toContain('Đã tổng hợp từ dữ liệu hiện có</td>');
    expect(html).toContain('Độ phủ và giới hạn dữ liệu');
    expect(html).not.toContain('Chỉ hiển thị dữ liệu có nguồn');
    expect(html).not.toContain('Các nhóm nhỏ hoặc thiếu bằng chứng được ẩn');
  });

  it('selects closed reporting days using Vietnam time rather than the host timezone', () => {
    expect(analyticsClosedRange(7, new Date('2026-10-21T18:00:00Z'))).toEqual({
      from: '2026-10-15',
      to: '2026-10-21',
    });
  });
});
