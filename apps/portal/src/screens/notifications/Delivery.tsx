import {
  staffCan,
  type NotificationStatCounts,
  type NotificationStatMetric,
  type NotificationStatsResponse,
} from '@child-life/contracts';
import { CircleCheck } from 'lucide-react';
import { Fragment, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { ApiError, useApi } from '../../api';
import { EmptyState, Hint, Notice, Section, useConfirm } from '../../content-kit';
import { useStaff } from '../../context';
import { Button, Panel, StackedBars, useSort } from '../../ui';
import { CodeText, DataTable, PageSkeleton, StatusDot, TabHeader } from './kit';
import { Freshness, StatsLoader } from './Overview';
import {
  DeliveryPill,
  ErrorLine,
  RangePicker,
  at,
  defaultRange,
  labelOr,
  templateName,
  type RangeChoice,
} from './shared';

export const deliveryColumns: NotificationStatMetric[] = [
  'created',
  'muted',
  'inbox',
  'held',
  'no_device',
  'attempted',
  'accepted',
  'rejected',
  'retry',
  'failed',
  'unknown',
];

/** Outcomes of one kind's rows for the stacked bar: accepted, not pushed, failed, unknown. */
export function deliveryOutcomes(counts: NotificationStatCounts) {
  return {
    accepted: counts.accepted ?? 0,
    notPushed: (counts.muted ?? 0) + (counts.held ?? 0) + (counts.no_device ?? 0),
    failed: (counts.failed ?? 0) + (counts.rejected ?? 0),
    unknown: counts.unknown ?? 0,
  };
}

export function DeliveryTab({ onTimeline }: { onTimeline?: (code: string) => void }) {
  const [range, setRange] = useState<RangeChoice>(() => defaultRange(7));
  return (
    <div className="stack">
      <TabHeader
        title={<FormattedMessage id="ntf.tab.delivery" />}
        purpose={<FormattedMessage id="ntf.purpose.delivery" />}
        actions={<RangePicker value={range} onChange={setRange} />}
      />
      <StatsLoader from={range.from} to={range.to} skeleton={<PageSkeleton />}>
        {(data, reload) => <DeliveryView data={data} onChanged={reload} onTimeline={onTimeline} />}
      </StatsLoader>
    </div>
  );
}

function CountCells({ counts }: { counts: NotificationStatCounts }) {
  const intl = useIntl();
  return (
    <>
      {deliveryColumns.map((m) => {
        const v = counts[m] ?? 0;
        return (
          <td
            key={m}
            className={`text-right tabular-nums ${v === 0 ? 'text-muted-foreground' : ''} ${
              (m === 'failed' || m === 'rejected') && v > 0 ? 'font-medium text-destructive' : ''
            }`}
          >
            {intl.formatNumber(v)}
          </td>
        );
      })}
    </>
  );
}

function MetricHead({ m, children }: { m: NotificationStatMetric; children?: ReactNode }) {
  return (
    <span className="inline-flex items-center gap-1">
      {children ?? <FormattedMessage id={`ntf.metric.${m}`} />}
      <Hint>
        <FormattedMessage id={`ntf.metric.${m}.def`} />
      </Hint>
    </span>
  );
}

/** Gửi & lỗi: what needs action first (failed deliveries), then outcomes per kind and version. */
export function DeliveryView({
  data,
  onChanged,
  onTimeline,
}: {
  data: NotificationStatsResponse;
  onChanged?: () => void;
  onTimeline?: (code: string) => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const staff = useStaff();
  const canOps = staffCan(staff.levels, 'notifications.ops');
  const canTimeline = staffCan(staff.levels, 'notifications.timeline');
  const { ask, dialog } = useConfirm();
  const [error, setError] = useState<ApiError | null>(null);
  const [done, setDone] = useState<string | null>(null);
  const hasData = !!data.sourceStartDay;
  type KindRow = NotificationStatsResponse['byKind'][number];
  const sortBy: Record<string, (r: KindRow) => string | number> = {
    kind: (r) => intl.formatMessage({ id: `ntf.kind.${r.kind}` }),
  };
  for (const m of deliveryColumns) sortBy[m] = (r) => r.counts[m] ?? 0;
  const byKind = useSort(data.byKind, sortBy);
  const retry = async (entry: string) => {
    setError(null);
    setDone(null);
    try {
      const res = await api.call<{ ok: boolean }>('staffRetryNotification', { entry });
      if (res.ok) {
        setDone(entry);
        onChanged?.();
      } else setError(new ApiError('failed-precondition', 'not-retryable'));
    } catch (e) {
      setError(e instanceof ApiError ? e : new ApiError('unknown', null));
    }
  };
  const outcomeKeys = (['accepted', 'notPushed', 'failed', 'unknown'] as const).map((k) => ({
    key: k,
    label: intl.formatMessage({ id: `ntf.outcome.${k}` }),
    className: '',
  }));
  const kindsWithRows = data.byKind.filter((r) => (r.counts.created ?? 0) > 0);
  return (
    <div className="stack">
      <Freshness data={data} />
      {!data.ops.retryEnabled && (
        <Notice tone="warn">
          <FormattedMessage id="ntf.delivery.retryOff" />
        </Notice>
      )}
      <ErrorLine error={error} />
      {done && (
        <Notice tone="ok">
          <FormattedMessage id="ntf.delivery.retried" />
        </Notice>
      )}
      <Section
        title={
          <span className="inline-flex items-center gap-2">
            <FormattedMessage id="ntf.delivery.problems" />
            <span
              className={`rounded-full px-2 text-[12px] font-medium tabular-nums ${
                data.problems.length
                  ? 'bg-destructive/15 text-destructive'
                  : 'bg-muted text-muted-foreground'
              }`}
            >
              {intl.formatNumber(data.problems.length)}
            </span>
          </span>
        }
        description={<FormattedMessage id="ntf.delivery.problemsNote" />}
        flush
      >
        {data.problems.length === 0 ? (
          <EmptyState
            icon={CircleCheck}
            title={<FormattedMessage id="ntf.delivery.noProblems" />}
          />
        ) : (
          <DataTable min={860} label={intl.formatMessage({ id: 'ntf.delivery.problems' })}>
            <table className="table">
              <thead>
                <tr>
                  <th>
                    <FormattedMessage id="ntf.col.time" />
                  </th>
                  <th>
                    <FormattedMessage id="ntf.col.kind" />
                  </th>
                  <th>
                    <FormattedMessage id="ntf.col.delivery" />
                  </th>
                  <th className="text-right">
                    <FormattedMessage id="ntf.col.attempts" />
                  </th>
                  <th>
                    <FormattedMessage id="ntf.col.error" />
                  </th>
                  <th>
                    <FormattedMessage id="ntf.col.family" />
                  </th>
                  <th>
                    <span className="sr-only">
                      <FormattedMessage id="ntf.col.actions" />
                    </span>
                  </th>
                </tr>
              </thead>
              <tbody>
                {data.problems.map((p) => (
                  <tr key={p.entry} data-entry={p.entry}>
                    <td className="nowrap text-[13px]">{at(intl, p.createdAt)}</td>
                    <td>
                      <FormattedMessage id={`ntf.kind.${p.kind}`} />
                    </td>
                    <td>
                      <DeliveryPill state={p.delivery} />
                      <span className="block text-[12px] text-muted-foreground">
                        {labelOr(intl, `ntf.reason.${p.reason}`, p.reason)}
                      </span>
                    </td>
                    <td className="text-right tabular-nums">{intl.formatNumber(p.attempts)}</td>
                    <td>
                      {p.errorCode ? (
                        <CodeText value={p.errorCode} />
                      ) : (
                        <span className="muted">—</span>
                      )}
                    </td>
                    <td>
                      {p.familyCode ? (
                        canTimeline && onTimeline ? (
                          <button
                            type="button"
                            className="font-mono text-[13px] text-primary hover:underline"
                            onClick={() => onTimeline(p.familyCode!)}
                            aria-label={intl.formatMessage(
                              { id: 'ntf.delivery.openTimeline' },
                              { code: p.familyCode },
                            )}
                          >
                            {p.familyCode}
                          </button>
                        ) : (
                          <span className="font-mono text-[13px]">{p.familyCode}</span>
                        )
                      ) : (
                        <span className="muted">—</span>
                      )}
                    </td>
                    <td className="text-right">
                      {canOps && p.delivery === 'failed' && (
                        <Button
                          disabled={!data.ops.retryEnabled}
                          onClick={() =>
                            ask({
                              title: intl.formatMessage({ id: 'ntf.delivery.retry.title' }),
                              body: intl.formatMessage({ id: 'ntf.delivery.retry.body' }),
                              confirmLabel: intl.formatMessage({ id: 'ntf.delivery.retry' }),
                              onConfirm: () => void retry(p.entry),
                            })
                          }
                        >
                          <FormattedMessage id="ntf.delivery.retry" />
                        </Button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </DataTable>
        )}
      </Section>
      {hasData && kindsWithRows.length > 0 && (
        <Panel
          title={<FormattedMessage id="ntf.delivery.outcomes" />}
          hint={<FormattedMessage id="ntf.acceptedNotDelivered" />}
        >
          <StackedBars
            title={intl.formatMessage({ id: 'ntf.delivery.outcomes' })}
            labels={kindsWithRows.map((r) => intl.formatMessage({ id: `ntf.kind.${r.kind}` }))}
            series={kindsWithRows.map((r) => deliveryOutcomes(r.counts))}
            keys={outcomeKeys}
          />
          <p className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-[12px] text-muted-foreground">
            {(['accepted', 'notPushed', 'failed', 'unknown'] as const).map((k) => (
              <span key={k}>
                <FormattedMessage id={`ntf.outcome.${k}.def`} />
              </span>
            ))}
          </p>
        </Panel>
      )}
      <Section
        flush
        collapsible
        title={<FormattedMessage id="ntf.delivery.byKind" />}
        summary={intl.formatNumber(data.byKind.length)}
      >
        {!hasData || data.byKind.length === 0 ? (
          <EmptyState title={<FormattedMessage id="ntf.noStats" />} />
        ) : (
          <DataTable min={1100} label={intl.formatMessage({ id: 'ntf.delivery.byKind' })}>
            <table className="table">
              <thead>
                <tr>
                  {byKind.th('kind', <FormattedMessage id="ntf.col.kind" />)}
                  {deliveryColumns.map((m) => (
                    <Fragment key={m}>
                      {byKind.th(m, <FormattedMessage id={`ntf.metric.${m}`} />)}
                    </Fragment>
                  ))}
                </tr>
              </thead>
              <tbody>
                {byKind.rows.map((r) => (
                  <tr key={r.kind}>
                    <td className="nowrap">
                      <FormattedMessage id={`ntf.kind.${r.kind}`} />
                    </td>
                    <CountCells counts={r.counts} />
                  </tr>
                ))}
              </tbody>
            </table>
          </DataTable>
        )}
      </Section>
      <Section
        flush
        collapsible
        defaultOpen={false}
        title={<FormattedMessage id="ntf.delivery.byTemplate" />}
        summary={intl.formatNumber(data.byTemplate.length)}
      >
        {!hasData || data.byTemplate.length === 0 ? (
          <EmptyState title={<FormattedMessage id="ntf.noStats" />} />
        ) : (
          <DataTable min={1200} label={intl.formatMessage({ id: 'ntf.delivery.byTemplate' })}>
            <table className="table">
              <thead>
                <tr>
                  <th>
                    <FormattedMessage id="ntf.col.template" />
                  </th>
                  <th>
                    <FormattedMessage id="ntf.col.version" />
                  </th>
                  {deliveryColumns.map((m) => (
                    <th key={m} className="text-right">
                      <MetricHead m={m} />
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {data.byTemplate.map((r) => (
                  <tr key={`${r.templateId}@${r.version}`}>
                    <td>{templateName(intl, r.templateId)}</td>
                    <td className="nowrap tabular-nums">
                      {r.version === 0 ? (
                        <FormattedMessage id="ntf.tpl.v0short" />
                      ) : (
                        <FormattedMessage id="ntf.tpl.version" values={{ v: r.version }} />
                      )}
                    </td>
                    <CountCells counts={r.counts} />
                  </tr>
                ))}
              </tbody>
            </table>
          </DataTable>
        )}
      </Section>
      <p className="text-[12px] text-muted-foreground">
        <StatusDot tone="muted">
          <FormattedMessage id="ntf.zeroVsNoData" />
        </StatusDot>
      </p>
      {dialog}
    </div>
  );
}
