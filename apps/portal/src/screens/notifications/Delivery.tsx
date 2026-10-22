import {
  staffCan,
  type NotificationStatCounts,
  type NotificationStatMetric,
  type NotificationStatsResponse,
} from '@child-life/contracts';
import { CircleCheck } from 'lucide-react';
import { useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { ApiError, useApi } from '../../api';
import { EmptyState, Hint, Notice, Section, useConfirm } from '../../content-kit';
import { useStaff } from '../../context';
import { Button, Panel, TableScroll } from '../../ui';
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

export function DeliveryTab({ onTimeline }: { onTimeline?: (code: string) => void }) {
  const [range, setRange] = useState<RangeChoice>(() => defaultRange(7));
  return (
    <div className="stack">
      <RangePicker value={range} onChange={setRange} />
      <StatsLoader from={range.from} to={range.to}>
        {(data, reload) => <DeliveryView data={data} onChanged={reload} onTimeline={onTimeline} />}
      </StatsLoader>
    </div>
  );
}

function CountCells({ counts }: { counts: NotificationStatCounts }) {
  const intl = useIntl();
  return (
    <>
      {deliveryColumns.map((m) => (
        <td key={m} className="text-right tabular-nums">
          {intl.formatNumber(counts[m] ?? 0)}
        </td>
      ))}
    </>
  );
}

function CountHeads() {
  return (
    <>
      {deliveryColumns.map((m) => (
        <th key={m} className="text-right">
          <span className="inline-flex items-center gap-1">
            <FormattedMessage id={`ntf.metric.${m}`} />
            <Hint>
              <FormattedMessage id={`ntf.metric.${m}.def`} />
            </Hint>
          </span>
        </th>
      ))}
    </>
  );
}

/** Gửi & lỗi: per kind, per template version, and the deliveries that failed or wait to retry. */
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
  return (
    <div className="stack">
      <Freshness data={data} />
      <Notice>
        <FormattedMessage id="ntf.acceptedNotDelivered" />
      </Notice>
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
        title={<FormattedMessage id="ntf.delivery.problems" />}
        description={<FormattedMessage id="ntf.delivery.problemsNote" />}
        flush
      >
        {data.problems.length === 0 ? (
          <EmptyState
            icon={CircleCheck}
            title={<FormattedMessage id="ntf.delivery.noProblems" />}
          />
        ) : (
          <TableScroll min={900}>
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
                  <th>
                    <FormattedMessage id="ntf.col.reason" />
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
                  <th />
                </tr>
              </thead>
              <tbody>
                {data.problems.map((p) => (
                  <tr key={p.entry} data-entry={p.entry}>
                    <td className="nowrap">{at(intl, p.createdAt)}</td>
                    <td>
                      <FormattedMessage id={`ntf.kind.${p.kind}`} />
                    </td>
                    <td>
                      <DeliveryPill state={p.delivery} />
                    </td>
                    <td>{labelOr(intl, `ntf.reason.${p.reason}`, p.reason)}</td>
                    <td className="text-right tabular-nums">{p.attempts}</td>
                    <td className="font-mono text-[12px]">{p.errorCode ?? '—'}</td>
                    <td>
                      {p.familyCode ? (
                        canTimeline && onTimeline ? (
                          <button
                            type="button"
                            className="font-mono text-primary hover:underline"
                            onClick={() => onTimeline(p.familyCode!)}
                            aria-label={intl.formatMessage(
                              { id: 'ntf.delivery.openTimeline' },
                              { code: p.familyCode },
                            )}
                          >
                            {p.familyCode}
                          </button>
                        ) : (
                          <span className="font-mono">{p.familyCode}</span>
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
          </TableScroll>
        )}
      </Section>
      <Panel className="panel--flush" title={<FormattedMessage id="ntf.delivery.byKind" />}>
        {!hasData || data.byKind.length === 0 ? (
          <EmptyState title={<FormattedMessage id="ntf.noStats" />} />
        ) : (
          <TableScroll min={1100}>
            <table className="table">
              <thead>
                <tr>
                  <th>
                    <FormattedMessage id="ntf.col.kind" />
                  </th>
                  <CountHeads />
                </tr>
              </thead>
              <tbody>
                {data.byKind.map((r) => (
                  <tr key={r.kind}>
                    <td className="nowrap">
                      <FormattedMessage id={`ntf.kind.${r.kind}`} />
                    </td>
                    <CountCells counts={r.counts} />
                  </tr>
                ))}
              </tbody>
            </table>
          </TableScroll>
        )}
      </Panel>
      <Panel className="panel--flush" title={<FormattedMessage id="ntf.delivery.byTemplate" />}>
        {!hasData || data.byTemplate.length === 0 ? (
          <EmptyState title={<FormattedMessage id="ntf.noStats" />} />
        ) : (
          <TableScroll min={1200}>
            <table className="table">
              <thead>
                <tr>
                  <th>
                    <FormattedMessage id="ntf.col.template" />
                  </th>
                  <th>
                    <FormattedMessage id="ntf.col.version" />
                  </th>
                  <CountHeads />
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
          </TableScroll>
        )}
      </Panel>
      {dialog}
    </div>
  );
}
