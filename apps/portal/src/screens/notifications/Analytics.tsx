import {
  staffCan,
  type NotificationStatCounts,
  type NotificationStatMetric,
  type NotificationStatsResponse,
} from '@child-life/contracts';
import { ExternalLink } from 'lucide-react';
import { useState } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { EmptyState, Hint, Notice } from '../../content-kit';
import { useNavigate, useStaff } from '../../context';
import { downloadCsv, toCsv } from '../../format';
import { Button, Kpi, LineChart, Panel, Segmented, TableScroll } from '../../ui';
import { Freshness, StatsLoader } from './Overview';
import {
  RangePicker,
  dayLabel,
  daysWithData,
  defaultRange,
  notificationRates,
  rateDefinition,
  rateIds,
  rateText,
  sumCounts,
  templateName,
  type RangeChoice,
  type RateId,
} from './shared';

export function AnalyticsTab() {
  const [range, setRange] = useState<RangeChoice>(() => defaultRange(30));
  return (
    <div className="stack">
      <RangePicker value={range} onChange={setRange} />
      <StatsLoader from={range.from} to={range.to}>
        {(data) => <NotificationAnalyticsView data={data} />}
      </StatsLoader>
    </div>
  );
}

/** "Đã mở / Đã vào hộp thư": the rate's definition with its numerator and denominator. */
export function RateHint({ id }: { id: RateId }) {
  const intl = useIntl();
  const d = rateDefinition[id];
  return (
    <Hint>
      <span className="grid gap-1">
        <span>
          <FormattedMessage id={`ntf.rate.${id}.def`} />
        </span>
        <span className="font-medium">
          <FormattedMessage
            id="ntf.rate.formula"
            values={{
              a: intl.formatMessage({ id: `ntf.metric.${d.numerator}` }),
              c: intl.formatMessage({ id: `ntf.metric.${d.denominator}` }),
            }}
          />
        </span>
      </span>
    </Hint>
  );
}

/** One CSV of the range: each day's totals, then per group and per template version. */
export function notificationStatsCsv(data: NotificationStatsResponse): string {
  const metrics: NotificationStatMetric[] = [
    'created',
    'muted',
    'inbox',
    'held',
    'no_device',
    'cancelled',
    'attempted',
    'accepted',
    'rejected',
    'retry',
    'failed',
    'unknown',
    'read',
    'opened',
    'opened_push',
    'opened_inbox',
    'navigated',
    'fallback',
    'unavailable',
    'action_completed',
    'render_error',
  ];
  const row = (type: string, key: string, counts: NotificationStatCounts | null) => [
    data.range.from,
    data.range.to,
    data.reportingZone,
    data.computedAt,
    data.sourceStartDay,
    type,
    key,
    ...metrics.map((m) => (counts ? (counts[m] ?? 0) : null)),
  ];
  const rows: unknown[][] = [
    // Days before the ledger existed are unavailable (empty cells), not zero.
    ...data.days.map((d) =>
      row('day', d.day, data.sourceStartDay && d.day >= data.sourceStartDay ? d.totals : null),
    ),
    ...data.byGroup.map((g) => row('group', g.group, g.counts)),
    ...data.byTemplate.map((t) => row('template', `${t.templateId}@${t.version}`, t.counts)),
  ];
  return toCsv(
    ['from', 'to', 'zone', 'computed_at', 'source_start', 'type', 'key', ...metrics],
    rows,
  );
}

function RateCells({ intl, counts }: { intl: IntlShape; counts: NotificationStatCounts }) {
  return (
    <>
      {notificationRates(counts).map((r) => (
        <td
          key={r.id}
          className="text-right tabular-nums"
          title={`${intl.formatNumber(r.numerator)} / ${intl.formatNumber(r.denominator)}`}
        >
          {rateText(intl, r.value)}
          <span className="block text-[11px] text-muted-foreground">
            {intl.formatNumber(r.numerator)}/{intl.formatNumber(r.denominator)}
          </span>
        </td>
      ))}
    </>
  );
}

function RateHeads() {
  return (
    <>
      {rateIds.map((id) => (
        <th key={id} className="text-right">
          <span className="inline-flex items-center gap-1">
            <FormattedMessage id={`ntf.rate.${id}`} />
            <RateHint id={id} />
          </span>
        </th>
      ))}
    </>
  );
}

const trendMetrics = ['created', 'accepted', 'opened', 'failed'] as const;

/**
 * Phân tích: delivery and engagement rates with explicit numerators and denominators (no rate
 * over an empty denominator), by group and template version, a daily trend where days before the
 * ledger read "no data", and the CSV. Executive and retention metrics stay in Phân tích sản phẩm.
 */
export function NotificationAnalyticsView({ data }: { data: NotificationStatsResponse }) {
  const intl = useIntl();
  const staff = useStaff();
  const navigate = useNavigate();
  const [metric, setMetric] = useState<(typeof trendMetrics)[number]>('created');
  const days = daysWithData(data.days, data.sourceStartDay);
  const totals = sumCounts(days.map((d) => d.totals));
  const rates = notificationRates(totals);
  const partial = !!data.sourceStartDay && data.range.from < data.sourceStartDay;
  return (
    <div className="stack">
      <div className="flex flex-wrap items-center gap-2">
        <Freshness data={data} />
        <div className="ml-auto flex flex-wrap gap-2">
          <Button kind="ghost" onClick={() => navigate('analytics', 'engagement')}>
            <ExternalLink className="size-4" aria-hidden="true" />
            <FormattedMessage id="ntf.analytics.product" />
          </Button>
          {staffCan(staff.levels, 'analytics.export') && (
            <Button
              onClick={() =>
                downloadCsv(
                  `child-life-notifications-${data.range.from}-${data.range.to}.csv`,
                  notificationStatsCsv(data),
                )
              }
            >
              <FormattedMessage id="action.exportCsv" />
            </Button>
          )}
        </div>
      </div>
      <Notice>
        <FormattedMessage id="ntf.acceptedNotDelivered" />
      </Notice>
      {!data.sourceStartDay ? (
        <EmptyState title={<FormattedMessage id="ntf.noStats" />}>
          <FormattedMessage id="ntf.noStatsNote" />
        </EmptyState>
      ) : (
        <>
          {partial && (
            <Notice tone="warn">
              <FormattedMessage
                id="ntf.analytics.partial"
                values={{ date: dayLabel(intl, data.sourceStartDay) }}
              />
            </Notice>
          )}
          <div className="kpis kpis--5">
            {rates.map((r) => (
              <Kpi
                key={r.id}
                label={
                  <span className="inline-flex items-center gap-1">
                    <FormattedMessage id={`ntf.rate.${r.id}`} />
                    <RateHint id={r.id} />
                  </span>
                }
                value={<span data-rate={r.id}>{rateText(intl, r.value)}</span>}
                foot={`${intl.formatNumber(r.numerator)} / ${intl.formatNumber(r.denominator)}`}
                tone={r.id === 'failure' && (r.value ?? 0) > 0.05 ? 'error' : 'muted'}
              />
            ))}
          </div>
          <Panel
            title={<FormattedMessage id="ntf.analytics.trend" />}
            aside={
              <Segmented
                label={intl.formatMessage({ id: 'ntf.analytics.trend' })}
                value={metric}
                options={trendMetrics.map((m) => ({
                  value: m,
                  label: <FormattedMessage id={`ntf.metric.${m}`} />,
                }))}
                onChange={setMetric}
              />
            }
          >
            <LineChart
              title={intl.formatMessage({ id: `ntf.metric.${metric}` })}
              points={data.days.map((d) =>
                data.sourceStartDay && d.day >= data.sourceStartDay
                  ? (d.totals[metric] ?? 0)
                  : null,
              )}
              labels={data.days.map((d) => dayLabel(intl, d.day))}
            />
          </Panel>
          <Panel className="panel--flush" title={<FormattedMessage id="ntf.analytics.byGroup" />}>
            <TableScroll min={820}>
              <table className="table">
                <thead>
                  <tr>
                    <th>
                      <FormattedMessage id="ntf.col.group" />
                    </th>
                    <th className="text-right">
                      <FormattedMessage id="ntf.metric.created" />
                    </th>
                    <RateHeads />
                  </tr>
                </thead>
                <tbody>
                  {data.byGroup.map((g) => (
                    <tr key={g.group}>
                      <td>
                        <FormattedMessage id={`ntf.group.${g.group}`} />
                      </td>
                      <td className="text-right tabular-nums">
                        {intl.formatNumber(g.counts.created ?? 0)}
                      </td>
                      <RateCells intl={intl} counts={g.counts} />
                    </tr>
                  ))}
                </tbody>
              </table>
            </TableScroll>
          </Panel>
          <Panel
            className="panel--flush"
            title={<FormattedMessage id="ntf.analytics.byTemplate" />}
          >
            <TableScroll min={960}>
              <table className="table">
                <thead>
                  <tr>
                    <th>
                      <FormattedMessage id="ntf.col.template" />
                    </th>
                    <th>
                      <FormattedMessage id="ntf.col.version" />
                    </th>
                    <th className="text-right">
                      <FormattedMessage id="ntf.metric.created" />
                    </th>
                    <RateHeads />
                  </tr>
                </thead>
                <tbody>
                  {data.byTemplate.map((t) => (
                    <tr key={`${t.templateId}@${t.version}`}>
                      <td>{templateName(intl, t.templateId)}</td>
                      <td className="nowrap tabular-nums">
                        {t.version === 0 ? (
                          <FormattedMessage id="ntf.tpl.v0short" />
                        ) : (
                          <FormattedMessage id="ntf.tpl.version" values={{ v: t.version }} />
                        )}
                      </td>
                      <td className="text-right tabular-nums">
                        {intl.formatNumber(t.counts.created ?? 0)}
                      </td>
                      <RateCells intl={intl} counts={t.counts} />
                    </tr>
                  ))}
                </tbody>
              </table>
            </TableScroll>
          </Panel>
        </>
      )}
    </div>
  );
}
