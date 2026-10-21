import {
  productAnalyticsSections,
  analyticsAgeBands,
  engagementStages,
  staffCan,
  type ProductAnalyticsRequest,
  type ProductAnalyticsResult,
  type ProductAnalyticsSection,
  type ProductMetric,
} from '@child-life/contracts';
import { RefreshCw } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { Button as UiButton } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { ApiError, useApi, useLoad } from '../api';
import { PersonalizationMetricsLoader } from './PersonalizationMetrics';
import { Hint, MoreFilters, Notice, Section } from '../content-kit';
import { useStaff } from '../context';
import { downloadCsv, pct, shortDate, toCsv } from '../format';
import {
  Button,
  Empty,
  errorMessageId,
  Kpi,
  LineChart,
  Loaded,
  LockNote,
  Page,
  Panel,
  Segmented,
  SelectMenu,
  TableScroll,
} from '../ui';

export function analyticsClosedRange(days: number, now = new Date()) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Ho_Chi_Minh',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(now);
  const part = (type: string) => parts.find((p) => p.type === type)!.value;
  const today = Date.parse(`${part('year')}-${part('month')}-${part('day')}T00:00:00Z`);
  return {
    from: new Date(today - days * 86_400_000).toISOString().slice(0, 10),
    to: new Date(today - 86_400_000).toISOString().slice(0, 10),
  };
}

export function productMetricValue(intl: IntlShape, metric: ProductMetric): string {
  if (metric.value === null) return '—';
  if (metric.unit === 'usd')
    return intl.formatNumber(metric.value, {
      style: 'currency',
      currency: 'USD',
      maximumFractionDigits: 4,
    });
  if (metric.denominator !== null) return pct(intl, metric.value, 1);
  return intl.formatNumber(metric.value);
}

export function productAnalyticsCsv(result: ProductAnalyticsResult): string {
  const meta = [
    result.section,
    result.range.from,
    result.range.to,
    result.reportingZone,
    result.computedAt,
    result.sourceStartAt,
    result.observedThrough,
  ];
  const rows: unknown[][] = result.metrics.map((m) => [
    ...meta,
    'metric',
    m.id,
    m.unit,
    m.value,
    m.numerator,
    m.denominator,
    m.status,
    m.reason,
    m.windowDays,
    m.previous,
  ]);
  for (const row of result.series)
    for (const field of ['users', 'families', 'actions'] as const)
      rows.push([
        ...meta,
        'series',
        `${row.day}:${field}`,
        field,
        row[field],
        null,
        null,
        'aggregate',
        null,
        null,
        null,
      ]);
  for (const row of result.breakdowns)
    rows.push([
      ...meta,
      'breakdown',
      `${row.dimension}:${row.key}`,
      'count',
      row.count,
      null,
      null,
      row.count === null ? 'insufficient' : 'aggregate',
      null,
      null,
      null,
    ]);
  for (const e of result.engagement)
    for (const [stage, n] of Object.entries(e.stages))
      rows.push([
        ...meta,
        'engagement',
        `${e.kind}:${stage}`,
        'opportunities',
        n,
        null,
        null,
        n === null ? 'unavailable' : 'aggregate',
        null,
        null,
        null,
      ]);
  for (const e of result.engagement)
    for (const row of e.reasons)
      rows.push([
        ...meta,
        'engagement_reason',
        `${e.kind}:${row.reason}`,
        'opportunities',
        row.count,
        null,
        null,
        row.count === null ? 'unavailable' : 'aggregate',
        row.reason,
        null,
        null,
      ]);
  return toCsv(
    [
      'section',
      'from',
      'to',
      'zone',
      'computed_at',
      'source_start',
      'observed_through',
      'type',
      'metric',
      'unit',
      'value',
      'numerator',
      'denominator',
      'status',
      'reason',
      'window_days',
      'previous',
    ],
    rows,
  );
}

const paths: Record<ProductAnalyticsSection, string> = {
  overview: '/analytics',
  acquisition: '/analytics/acquisition',
  memories: '/analytics/memories',
  engagement: '/analytics/engagement',
  features: '/analytics/features',
  cost: '/analytics/cost',
};
/** Cá nhân hoá (Nhịp lớn lên's counts, moved here on 2026-10-21): its own view, no filters. */
const personalizationPath = '/analytics/personalization';

export function ProductAnalyticsScreen() {
  const intl = useIntl();
  const staff = useStaff();
  const canCost = staffCan(staff.levels, 'premium.view');
  const [request, setRequest] = useState<ProductAnalyticsRequest>(() => ({
    schemaVersion: 2,
    section:
      productAnalyticsSections.find((s) => paths[s] === window.location.pathname) ?? 'overview',
    ...analyticsClosedRange(30),
    platform: 'all',
    locale: 'all',
    ageBand: 'all',
    context: 'all',
    chapter: 'all',
    comparison: true,
  }));
  const [range, setRange] = useState('30');
  const [draftFrom, setDraftFrom] = useState(request.from);
  const [draftTo, setDraftTo] = useState(request.to);
  const [dateError, setDateError] = useState(false);
  const update = (next: Partial<ProductAnalyticsRequest>) => setRequest((r) => ({ ...r, ...next }));
  useEffect(() => {
    if (window.location.pathname !== personalizationPath) {
      window.history.replaceState({}, '', paths[request.section]);
    }
  }, [request.section]);
  const sections = productAnalyticsSections.filter((s) => s !== 'cost' || canCost);
  // Its counts come with Nhịp lớn lên's content (Nội dung · Xem).
  const canPersonal = staffCan(staff.levels, 'content.view');
  const [personal, setPersonal] = useState(
    () => canPersonal && window.location.pathname === personalizationPath,
  );
  useEffect(() => {
    if (personal) window.history.replaceState({}, '', personalizationPath);
  }, [personal]);
  const withContext = ['memories', 'engagement'].includes(request.section);
  // The filters used less often sit behind "Bộ lọc khác"; its button counts the ones set.
  const moreSet =
    [request.locale, request.ageBand, request.chapter].filter((v) => v !== 'all').length +
    (withContext && request.context !== 'all' ? 1 : 0) +
    (request.comparison ? 0 : 1);
  return (
    <Page title={<FormattedMessage id="pa.title" />} info={<FormattedMessage id="pa.subtitle" />}>
      <div className="stack">
        <div className="toolbar">
          <Segmented
            label={intl.formatMessage({ id: 'pa.sections' })}
            value={personal ? 'personalization' : request.section}
            options={[
              ...sections.map((s) => ({
                value: s as ProductAnalyticsSection | 'personalization',
                label: <FormattedMessage id={`pa.section.${s}`} />,
              })),
              ...(canPersonal
                ? [
                    {
                      value: 'personalization' as const,
                      label: <FormattedMessage id="analytics.personalization.tab" />,
                    },
                  ]
                : []),
            ]}
            onChange={(section) => {
              if (section === 'personalization') {
                setPersonal(true);
                return;
              }
              setPersonal(false);
              window.history.replaceState({}, '', paths[section]);
              update({ section, context: 'all' });
            }}
          />
        </div>
        {personal ? (
          <PersonalizationMetricsLoader />
        ) : (
          <>
            <div className="flex flex-wrap items-center gap-2">
              <SelectMenu
                label={intl.formatMessage({ id: 'analytics.range' })}
                value={range}
                options={[
                  ...['7', '30', '90'].map((d) => ({
                    value: d,
                    label: intl.formatMessage({ id: 'analytics.rangeDays' }, { n: Number(d) }),
                  })),
                  { value: 'custom', label: intl.formatMessage({ id: 'pa.custom' }) },
                ]}
                onChange={(v) => {
                  setRange(v);
                  if (v !== 'custom') update(analyticsClosedRange(Number(v)));
                }}
              />
              <SelectMenu
                label={intl.formatMessage({ id: 'analytics.platform' })}
                value={request.platform}
                options={(['all', 'ios', 'android'] as const).map((p) => ({
                  value: p,
                  label: intl.formatMessage({ id: `analytics.platform.${p}` }),
                }))}
                onChange={(platform) => update({ platform })}
              />
              <MoreFilters count={moreSet}>
                <SelectMenu
                  label={intl.formatMessage({ id: 'pa.locale' })}
                  value={request.locale}
                  options={(['all', 'vi', 'en'] as const).map((l) => ({
                    value: l,
                    label: intl.formatMessage({ id: `pa.locale.${l}` }),
                  }))}
                  onChange={(locale) => update({ locale })}
                />
                <SelectMenu
                  label={intl.formatMessage({ id: 'pa.ageBand' })}
                  value={request.ageBand}
                  options={['all' as const, ...analyticsAgeBands].map((v) => ({
                    value: v,
                    label: intl.formatMessage({ id: `pa.age.${v}` }),
                  }))}
                  onChange={(ageBand) => update({ ageBand })}
                />
                <SelectMenu
                  label={intl.formatMessage({ id: 'pa.chapter' })}
                  value={request.chapter}
                  options={(['all', 'chapter01', 'unknown'] as const).map((chapter) => ({
                    value: chapter,
                    label: intl.formatMessage({ id: `pa.chapter.${chapter}` }),
                  }))}
                  onChange={(chapter) => update({ chapter })}
                />
                {withContext && (
                  <SelectMenu
                    label={intl.formatMessage({ id: 'pa.context' })}
                    value={request.context}
                    options={(['all', 'current', 'retrospective', 'unknown'] as const).map(
                      (context) => ({
                        value: context,
                        label: intl.formatMessage({ id: `pa.context.${context}` }),
                      }),
                    )}
                    onChange={(context) => update({ context })}
                  />
                )}
                <label className="flex items-center gap-2 text-sm">
                  <input
                    type="checkbox"
                    checked={request.comparison}
                    onChange={(e) => update({ comparison: e.target.checked })}
                  />
                  <FormattedMessage id="pa.compare" />
                </label>
              </MoreFilters>
              <Hint>
                <FormattedMessage id="pa.filtersNote" />
              </Hint>
            </div>
            {range === 'custom' && (
              <div className="flex flex-wrap items-end gap-2">
                <label className="grid gap-1 text-[13px] font-medium">
                  <FormattedMessage id="pa.from" />
                  <Input
                    type="date"
                    className="w-40"
                    value={draftFrom}
                    onChange={(e) => setDraftFrom(e.target.value)}
                  />
                </label>
                <label className="grid gap-1 text-[13px] font-medium">
                  <FormattedMessage id="pa.to" />
                  <Input
                    type="date"
                    className="w-40"
                    value={draftTo}
                    max={analyticsClosedRange(1).to}
                    onChange={(e) => setDraftTo(e.target.value)}
                  />
                </label>
                <Button
                  onClick={() => {
                    const valid =
                      /^\d{4}-\d{2}-\d{2}$/.test(draftFrom) &&
                      /^\d{4}-\d{2}-\d{2}$/.test(draftTo) &&
                      draftFrom <= draftTo &&
                      draftTo <= analyticsClosedRange(1).to &&
                      Date.parse(draftTo) - Date.parse(draftFrom) < 366 * 86_400_000;
                    setDateError(!valid);
                    if (valid) update({ from: draftFrom, to: draftTo });
                  }}
                >
                  <FormattedMessage id="pa.apply" />
                </Button>
              </div>
            )}
            {dateError && (
              <p className="error" role="alert">
                <FormattedMessage id="pa.invalidDates" />
              </p>
            )}
            {request.section === 'cost' && !canCost ? (
              <LockNote>
                <FormattedMessage id="pa.costPermission" />
              </LockNote>
            ) : (
              <ProductAnalyticsQuery key={JSON.stringify(request)} request={request} />
            )}
          </>
        )}
      </div>
    </Page>
  );
}

function ProductAnalyticsQuery({ request }: { request: ProductAnalyticsRequest }) {
  const intl = useIntl();
  const staff = useStaff(),
    api = useApi();
  const [load, reload] = useLoad<ProductAnalyticsResult>(
    'staffProductAnalytics',
    request,
    JSON.stringify(request),
  );
  const [error, setError] = useState<ApiError | null>(null);
  const attempts = useRef(0);
  useEffect(() => {
    if (load.status !== 'ok' || load.data.status !== 'preparing' || attempts.current >= 20) return;
    attempts.current++;
    const timer = window.setTimeout(reload, 1500);
    return () => window.clearTimeout(timer);
  }, [load, reload]);
  const refresh = intl.formatMessage({ id: 'pa.refresh' });
  return (
    <>
      <div className="flex flex-wrap items-center gap-2">
        {load.status === 'ok' && <ProductAnalyticsMeta data={load.data} />}
        <div className="ml-auto flex items-center gap-2">
          <UiButton
            variant="ghost"
            size="icon"
            className="size-8 text-muted-foreground"
            aria-label={refresh}
            title={refresh}
            onClick={reload}
          >
            <RefreshCw />
          </UiButton>
          {staffCan(staff.levels, 'analytics.export') && (
            <Button
              onClick={async () => {
                setError(null);
                try {
                  const result = await api.call<ProductAnalyticsResult>(
                    'staffExportProductAnalytics',
                    request,
                  );
                  if (result.status === 'preparing') {
                    reload();
                    return;
                  }
                  downloadCsv(
                    `child-life-${request.section}-${request.from}-${request.to}.csv`,
                    productAnalyticsCsv(result),
                  );
                } catch (e) {
                  setError(e instanceof ApiError ? e : new ApiError('unknown', null));
                }
              }}
            >
              <FormattedMessage id="action.exportCsv" />
            </Button>
          )}
        </div>
      </div>
      {error && (
        <p role="alert" className="error">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
      <Loaded load={load} reload={reload}>
        {(data) => <ProductAnalyticsView data={data} />}
      </Loaded>
    </>
  );
}

/** "01/10 – 20/10 · Asia/Ho_Chi_Minh · Tính lúc …": one muted line next to the buttons. */
export function ProductAnalyticsMeta({ data }: { data: ProductAnalyticsResult }) {
  const intl = useIntl();
  return (
    <span className="text-[13px] text-muted-foreground tabular-nums">
      <FormattedMessage
        id="pa.metadata"
        values={{
          from: data.range.from,
          to: data.range.to,
          zone: data.reportingZone,
          at: data.computedAt
            ? intl.formatDate(data.computedAt, {
                dateStyle: 'short',
                timeStyle: 'short',
                timeZone: data.reportingZone,
              })
            : '—',
        }}
      />
    </span>
  );
}

/** A metric's definition and why it may read "—", behind a "?" (no paragraphs on the page). */
function MetricHint({ metric: m }: { metric: ProductMetric }) {
  const intl = useIntl();
  return (
    <Hint label={intl.formatMessage({ id: 'pa.help' })}>
      <span className="grid gap-1">
        <span>
          <FormattedMessage
            id={`pa.definition.${m.id}`}
            values={{ id: m.id, days: m.windowDays ?? '—' }}
          />
        </span>
        <span>
          <FormattedMessage id={`pa.reason.${m.reason}`} />
        </span>
      </span>
    </Hint>
  );
}

/**
 * One analytics section, easy to scan (owner, 2026-10-21): what is not usable first (notices),
 * then the KPI tiles, the trend and the section's tables; definitions and data caveats sit behind
 * "?" hints or in sections folded by default.
 */
export function ProductAnalyticsView({ data }: { data: ProductAnalyticsResult }) {
  const intl = useIntl();
  const [dimension, setDimension] = useState<
    'module' | 'platform' | 'locale' | 'ageBand' | 'template'
  >(data.section === 'features' ? 'module' : data.section === 'memories' ? 'template' : 'platform');
  const [kind, setKind] = useState('all');
  const [seriesUnit, setSeriesUnit] = useState<'users' | 'families'>('users');
  const rowCount = data.series.some((s) => s[seriesUnit] !== null);
  const kinds = data.engagement.filter((e) => kind === 'all' || e.kind === kind);
  const reasons = kinds.flatMap((e) => e.reasons.map((r) => ({ kind: e.kind, ...r })));
  const trend = seriesUnit === 'users' ? 'pa.activityTrend' : 'pa.familyTrend';
  const sourceStart = data.sourceStartAt
    ? intl.formatDate(data.sourceStartAt, { dateStyle: 'short', timeZone: data.reportingZone })
    : '—';
  return (
    <div className="stack">
      {!data.collectionEnabled && (
        <Notice tone="warn">
          <FormattedMessage id="pa.recordingOff" />
        </Notice>
      )}
      {data.status === 'preparing' ? (
        <Notice>
          <FormattedMessage id="pa.preparing" />
        </Notice>
      ) : data.status === 'unavailable' ? (
        <Panel>
          <Empty>
            <FormattedMessage id="pa.unavailable" />
          </Empty>
        </Panel>
      ) : (
        <>
          {data.status === 'no_data' || data.status === 'disabled' ? (
            <Panel>
              <Empty>
                <FormattedMessage id="pa.noData" />
              </Empty>
            </Panel>
          ) : null}
          {data.unsupportedFilters.length > 0 && (
            <Notice>
              <FormattedMessage id="pa.unsupported" />
            </Notice>
          )}
          {data.metrics.length > 0 && (
            <div className="kpis">
              {data.metrics.slice(0, 6).map((m) => (
                <Kpi
                  key={m.id}
                  label={
                    <span className="inline-flex items-center gap-1">
                      <FormattedMessage id={`pa.metric.${m.id}`} />
                      <MetricHint metric={m} />
                    </span>
                  }
                  value={productMetricValue(intl, m)}
                  foot={
                    m.denominator !== null && m.numerator !== null
                      ? `${intl.formatNumber(m.numerator)} / ${intl.formatNumber(m.denominator)}`
                      : intl.formatMessage({ id: `pa.status.${m.status}` })
                  }
                  tone="muted"
                />
              ))}
            </div>
          )}
          {data.section !== 'cost' && data.section !== 'engagement' && (
            <Panel
              title={<FormattedMessage id={trend} />}
              aside={
                <Segmented
                  label={intl.formatMessage({ id: 'pa.activityTrend' })}
                  value={seriesUnit}
                  options={[
                    { value: 'users' as const, label: <FormattedMessage id="pa.metric.A02" /> },
                    { value: 'families' as const, label: <FormattedMessage id="pa.metric.A03" /> },
                  ]}
                  onChange={setSeriesUnit}
                />
              }
            >
              {rowCount ? (
                <LineChart
                  title={intl.formatMessage({ id: trend })}
                  points={data.series.map((s) => s[seriesUnit])}
                  labels={data.series.map((s) => shortDate(intl, `${s.day}T05:00:00Z`))}
                />
              ) : (
                <Empty>
                  <FormattedMessage id="pa.insufficient" values={{ n: data.privacyThreshold }} />
                </Empty>
              )}
            </Panel>
          )}
          {data.section === 'engagement' && (
            <Panel
              className="panel--flush"
              title={<FormattedMessage id="pa.engagement" />}
              hint={
                <span className="grid gap-1">
                  <span>
                    <FormattedMessage id="pa.deliveryNote" />
                  </span>
                  <span>
                    <FormattedMessage id="pa.noExperiment" />
                  </span>
                </span>
              }
              aside={
                <SelectMenu
                  label={intl.formatMessage({ id: 'pa.kind' })}
                  value={kind}
                  options={['all', ...data.engagement.map((e) => e.kind)].map((k) => ({
                    value: k,
                    label: k === 'all' ? intl.formatMessage({ id: 'analytics.platform.all' }) : k,
                  }))}
                  onChange={setKind}
                />
              }
            >
              <TableScroll min={980}>
                <table className="table">
                  <thead>
                    <tr>
                      <th>
                        <FormattedMessage id="pa.kind" />
                      </th>
                      {engagementStages.map((s) => (
                        <th key={s} className="text-right">
                          <FormattedMessage id={`pa.stage.${s}`} />
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {kinds.map((e) => (
                      <tr key={e.kind}>
                        <td className="nowrap font-medium">{e.kind}</td>
                        {engagementStages.map((stage) => (
                          <td key={stage} className="text-right tabular-nums">
                            {e.stages[stage] == null ? '—' : intl.formatNumber(e.stages[stage])}
                          </td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </TableScroll>
            </Panel>
          )}
          {data.section === 'engagement' && reasons.length > 0 && (
            <Section
              flush
              collapsible
              defaultOpen={false}
              title={<FormattedMessage id="pa.reasons" />}
              summary={intl.formatNumber(reasons.length)}
            >
              <TableScroll min={480}>
                <table className="table">
                  <thead>
                    <tr>
                      <th>
                        <FormattedMessage id="pa.kind" />
                      </th>
                      <th>
                        <FormattedMessage id="pa.col.reason" />
                      </th>
                      <th className="text-right">
                        <FormattedMessage id="pa.col.count" />
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {reasons.map((r) => (
                      <tr key={`${r.kind}:${r.reason}`}>
                        <td className="nowrap">{r.kind}</td>
                        <td>
                          <FormattedMessage id={`pa.suppression.${r.reason}`} />
                        </td>
                        <td className="text-right tabular-nums">
                          {r.count === null ? '—' : intl.formatNumber(r.count)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </TableScroll>
            </Section>
          )}
          {data.section === 'acquisition' && (
            <Panel className="panel--flush" title={<FormattedMessage id="pa.retention" />}>
              <TableScroll min={640}>
                <table className="table heat">
                  <thead>
                    <tr>
                      <th>
                        <FormattedMessage id="pa.cohort" />
                      </th>
                      <th>
                        <FormattedMessage id="pa.col.users" />
                      </th>
                      {[1, 7, 30].map((n) => (
                        <th key={n}>D{n}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {data.retention.map((row) => (
                      <tr key={row.day}>
                        <td>{row.day}</td>
                        <td>{row.users ?? '—'}</td>
                        {[row.d1, row.d7, row.d30].map((m) => (
                          <td
                            key={m.id}
                            className="heat__cell"
                            title={intl.formatMessage({ id: `pa.status.${m.status}` })}
                          >
                            {m.value === null ? '—' : pct(intl, m.value, 1)}
                          </td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </TableScroll>
            </Panel>
          )}
          {data.section !== 'cost' && data.section !== 'engagement' && (
            <Panel
              className="panel--flush"
              title={<FormattedMessage id="pa.breakdown" />}
              hint={<FormattedMessage id="pa.breakdownNote" />}
              aside={
                <SelectMenu
                  label={intl.formatMessage({ id: 'pa.breakdown' })}
                  value={dimension}
                  options={(['module', 'platform', 'locale', 'ageBand', 'template'] as const).map(
                    (d) => ({ value: d, label: intl.formatMessage({ id: `pa.dimension.${d}` }) }),
                  )}
                  onChange={setDimension}
                />
              }
            >
              <TableScroll min={500}>
                <table className="table">
                  <thead>
                    <tr>
                      <th>
                        <FormattedMessage id="pa.col.group" />
                      </th>
                      <th className="text-right">
                        <FormattedMessage id="pa.col.count" />
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.breakdowns
                      .filter((b) => b.dimension === dimension)
                      .map((b) => (
                        <tr key={`${b.dimension}:${b.key}`}>
                          <td>
                            {b.dimension === 'module' ? (
                              <FormattedMessage id={`pa.module.${b.key}`} />
                            ) : b.dimension === 'ageBand' ? (
                              <FormattedMessage id={`pa.age.${b.key}`} />
                            ) : (
                              b.key
                            )}
                          </td>
                          <td className="text-right tabular-nums">
                            {b.count === null ? '—' : intl.formatNumber(b.count)}
                          </td>
                        </tr>
                      ))}
                  </tbody>
                </table>
              </TableScroll>
            </Panel>
          )}
          <Section
            flush
            collapsible
            defaultOpen={false}
            title={<FormattedMessage id="pa.metricDetails" />}
            summary={<FormattedMessage id="pa.metricCount" values={{ n: data.metrics.length }} />}
          >
            <TableScroll min={760}>
              <table className="table">
                <thead>
                  <tr>
                    {['metric', 'value', 'denominator', 'previous', 'status'].map((s) => (
                      <th key={s}>
                        <FormattedMessage id={`pa.col.${s}`} />
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {data.metrics.map((m) => (
                    <tr key={m.id}>
                      <td>
                        <span className="inline-flex items-center gap-1 font-medium">
                          <FormattedMessage id={`pa.metric.${m.id}`} />
                          <MetricHint metric={m} />
                        </span>
                      </td>
                      <td className="tabular-nums">{productMetricValue(intl, m)}</td>
                      <td className="tabular-nums">
                        {m.numerator !== null && m.denominator !== null
                          ? `${m.numerator} / ${m.denominator}`
                          : '—'}
                      </td>
                      <td className="tabular-nums">
                        {m.previous === null ? '—' : intl.formatNumber(m.previous)}
                      </td>
                      <td>
                        <FormattedMessage id={`pa.status.${m.status}`} />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </TableScroll>
          </Section>
          <Section
            collapsible
            defaultOpen={false}
            title={<FormattedMessage id="pa.quality" />}
            hint={<FormattedMessage id="pa.coverageNote" />}
          >
            <ul className="grid gap-1.5 text-sm text-muted-foreground">
              <li>
                <FormattedMessage
                  id="pa.unknownActors"
                  values={{ n: data.quality.unknownActor ?? '—' }}
                />
              </li>
              <li>
                <FormattedMessage
                  id="pa.lateObservations"
                  values={{ n: data.quality.lateObservations ?? '—' }}
                />
              </li>
              <li>
                <FormattedMessage id="pa.sourceStart" values={{ at: sourceStart }} />
              </li>
              {data.section === 'cost' && (
                <li>
                  <FormattedMessage id="pa.costNote" />
                </li>
              )}
              {data.section === 'memories' && (
                <li>
                  <FormattedMessage id="pa.memoriesNote" />
                </li>
              )}
            </ul>
          </Section>
        </>
      )}
    </div>
  );
}
