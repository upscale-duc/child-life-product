import { inboxGroups, type NotificationStatsResponse } from '@child-life/contracts';
import { BellOff } from 'lucide-react';
import type { ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { useLoad } from '../../api';
import { EmptyState, Hint, Notice, StatTiles } from '../../content-kit';
import { Button, LineChart, Loaded, Panel } from '../../ui';
import {
  OnOffPill,
  at,
  dayLabel,
  daysWithData,
  rangeEnding,
  sumCounts,
  type NotificationTab,
} from './shared';

/** `staffNotificationStats` for a range; every tab that reads aggregates goes through it. */
export function StatsLoader({
  from,
  to,
  children,
}: {
  from: string;
  to: string;
  children: (data: NotificationStatsResponse, reload: () => void) => ReactNode;
}) {
  const [load, reload] = useLoad<NotificationStatsResponse>(
    'staffNotificationStats',
    { from, to },
    `ntf-stats:${from}:${to}`,
  );
  return (
    <Loaded load={load} reload={reload}>
      {(data) => children(data, reload)}
    </Loaded>
  );
}

export function OverviewTab({ onTab }: { onTab: (tab: NotificationTab) => void }) {
  const range = rangeEnding(7);
  return (
    <StatsLoader {...range}>{(data) => <OverviewView data={data} onTab={onTab} />}</StatsLoader>
  );
}

/** Freshness: "Tính lúc … · Có dữ liệu từ …" (days before the ledger started have no data). */
export function Freshness({ data }: { data: NotificationStatsResponse }) {
  const intl = useIntl();
  return (
    <p className="text-[13px] text-muted-foreground tabular-nums">
      <FormattedMessage
        id="ntf.freshness"
        values={{
          from: data.range.from,
          to: data.range.to,
          at: at(intl, data.computedAt),
          date: data.sourceStartDay ?? '—',
        }}
      />
    </p>
  );
}

/** Tổng quan: the last 7 days in six numbers, the daily trend, problems and the switches. */
export function OverviewView({
  data,
  onTab,
}: {
  data: NotificationStatsResponse;
  onTab?: (tab: NotificationTab) => void;
}) {
  const intl = useIntl();
  const days = daysWithData(data.days, data.sourceStartDay);
  const totals = sumCounts(days.map((d) => d.totals));
  const hasData = days.length > 0;
  const n = (v: number | undefined) => (hasData ? intl.formatNumber(v ?? 0) : '—');
  const anyPaused = inboxGroups.some((g) => data.ops.pushPaused[g]);
  return (
    <div className="stack">
      <Notice title={<FormattedMessage id="ntf.acceptedNotDelivered.title" />}>
        <FormattedMessage id="ntf.acceptedNotDelivered" />
      </Notice>
      {anyPaused && (
        <Notice tone="warn">
          <FormattedMessage id="ntf.ov.pausedGroups" />
        </Notice>
      )}
      <Freshness data={data} />
      {!hasData ? (
        <EmptyState icon={BellOff} title={<FormattedMessage id="ntf.noStats" />}>
          <FormattedMessage id="ntf.noStatsNote" />
        </EmptyState>
      ) : null}
      <StatTiles
        items={(
          [
            ['created', 'default'],
            ['inbox', 'default'],
            ['accepted', 'ok'],
            ['failed', (totals.failed ?? 0) > 0 ? 'error' : 'default'],
            ['opened', 'default'],
            ['read', 'default'],
          ] as const
        ).map(([m, tone]) => ({
          key: m,
          label: (
            <span className="inline-flex items-center gap-1">
              <FormattedMessage id={`ntf.metric.${m}`} />
              <Hint>
                <FormattedMessage id={`ntf.metric.${m}.def`} />
              </Hint>
            </span>
          ),
          value: n(totals[m]),
          tone,
        }))}
      />
      {hasData && (
        <Panel title={<FormattedMessage id="ntf.ov.trend" />}>
          <LineChart
            title={intl.formatMessage({ id: 'ntf.ov.trend' })}
            points={data.days.map((d) =>
              data.sourceStartDay && d.day >= data.sourceStartDay ? (d.totals.created ?? 0) : null,
            )}
            labels={data.days.map((d) => dayLabel(intl, d.day))}
          />
        </Panel>
      )}
      <div className="grid gap-4 lg:grid-cols-2">
        <Panel
          title={<FormattedMessage id="ntf.ov.problems" />}
          aside={
            onTab && (
              <Button kind="ghost" onClick={() => onTab('delivery')}>
                <FormattedMessage id="ntf.ov.openDelivery" />
              </Button>
            )
          }
        >
          <p className="text-2xl font-bold tabular-nums" data-problems={data.problems.length}>
            {intl.formatNumber(data.problems.length)}
          </p>
          <p className="text-[13px] text-muted-foreground">
            <FormattedMessage id="ntf.ov.problemsNote" />
          </p>
        </Panel>
        <Panel
          title={<FormattedMessage id="ntf.ov.switches" />}
          aside={
            onTab && (
              <Button kind="ghost" onClick={() => onTab('settings')}>
                <FormattedMessage id="ntf.ov.openSettings" />
              </Button>
            )
          }
        >
          <ul className="grid gap-2 text-sm">
            <li className="flex items-center justify-between gap-2">
              <FormattedMessage id="ntf.ops.templatesEnabled" />
              <OnOffPill on={data.ops.templatesEnabled} onId="ntf.on" offId="ntf.off" />
            </li>
            <li className="flex items-center justify-between gap-2">
              <FormattedMessage id="ntf.ops.retryEnabled" />
              <OnOffPill on={data.ops.retryEnabled} onId="ntf.on" offId="ntf.off" />
            </li>
            {inboxGroups.map((g) => (
              <li key={g} className="flex items-center justify-between gap-2">
                <FormattedMessage
                  id="ntf.ops.pushFor"
                  values={{ name: intl.formatMessage({ id: `ntf.group.${g}` }) }}
                />
                <OnOffPill
                  on={!data.ops.pushPaused[g]}
                  onId="ntf.ops.sending"
                  offId="ntf.ops.paused"
                />
              </li>
            ))}
          </ul>
        </Panel>
      </div>
    </div>
  );
}
