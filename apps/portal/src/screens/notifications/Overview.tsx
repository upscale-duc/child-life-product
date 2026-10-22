import {
  inboxGroups,
  type NotificationOpsResponse,
  type NotificationStatsResponse,
} from '@child-life/contracts';
import { ArrowRight, BellOff, Search } from 'lucide-react';
import { useState, type FormEvent, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Input } from '@/components/ui/input';
import { useLoad, type Load } from '../../api';
import { EmptyState, Hint, Notice, StatTiles } from '../../content-kit';
import { Button, Panel } from '../../ui';
import { LoadedSkeleton, PageSkeleton, Sparkline, StatusDot, TabHeader } from './kit';
import {
  at,
  daysWithData,
  normalizeFamilyCode,
  rate,
  rateText,
  sumCounts,
  type NotificationTab,
} from './shared';

/** `staffNotificationStats` for a range; every tab that reads aggregates goes through it. */
export function StatsLoader({
  from,
  to,
  children,
  skeleton,
}: {
  from: string;
  to: string;
  children: (data: NotificationStatsResponse, reload: () => void) => ReactNode;
  skeleton?: ReactNode;
}) {
  const [load, reload] = useLoad<NotificationStatsResponse>(
    'staffNotificationStats',
    { from, to },
    `ntf-stats:${from}:${to}`,
  );
  return (
    <LoadedSkeleton load={load} reload={reload} skeleton={skeleton}>
      {(data) => children(data, reload)}
    </LoadedSkeleton>
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

export type HealthSignal = 'failure' | 'backlog' | 'render' | 'paused' | 'templatesOff';
export interface OverviewHealth {
  level: 'no_data' | 'ok' | 'attention';
  signals: Array<{ id: HealthSignal; n: number }>;
  failureRate: number | null;
}

/** A failure rate at or above this (failed / attempted) needs a look. */
export const FAILURE_ATTENTION_RATE = 0.02;

/**
 * The health line of the overview: attention when the failure rate reaches 2 %, deliveries wait
 * for a retry, templates failed to render, or a group's push is paused; no data before the
 * ledger exists (never "OK" on an empty week).
 */
export function overviewHealth(
  data: NotificationStatsResponse,
  ops: NotificationOpsResponse['ops'] | null = data.ops,
): OverviewHealth {
  const days = daysWithData(data.days, data.sourceStartDay);
  const totals = sumCounts(days.map((d) => d.totals));
  const failureRate = rate(totals.failed ?? 0, totals.attempted ?? 0);
  const signals: OverviewHealth['signals'] = [];
  if (failureRate !== null && failureRate >= FAILURE_ATTENTION_RATE)
    signals.push({ id: 'failure', n: totals.failed ?? 0 });
  const backlog = data.problems.filter((p) => p.delivery === 'retry_pending').length;
  if (backlog > 0) signals.push({ id: 'backlog', n: backlog });
  if ((totals.render_error ?? 0) > 0) signals.push({ id: 'render', n: totals.render_error ?? 0 });
  const paused = ops ? inboxGroups.filter((g) => ops.pushPaused[g]).length : 0;
  if (paused > 0) signals.push({ id: 'paused', n: paused });
  if (ops && !ops.templatesEnabled) signals.push({ id: 'templatesOff', n: 1 });
  if (!days.length) return { level: 'no_data', signals, failureRate };
  return { level: signals.length ? 'attention' : 'ok', signals, failureRate };
}

const tiles = [
  ['created', 'default'],
  ['inbox', 'default'],
  ['accepted', 'ok'],
  ['failed', 'error'],
  ['opened', 'default'],
  ['read', 'default'],
] as const;

/**
 * Tổng quan: an at-a-glance dashboard of the last 7 days — a health line, six numbers with their
 * daily sparkline, quick links (problems, drafts in review, a family's timeline) and the switches.
 */
export function OverviewView({
  data,
  ops,
  reviewCount,
  canTimeline,
  onTab,
  onTimeline,
}: {
  data: NotificationStatsResponse;
  ops?: NotificationOpsResponse | null;
  reviewCount?: number | null;
  canTimeline?: boolean;
  onTab?: (tab: NotificationTab) => void;
  onTimeline?: (code: string) => void;
}) {
  const intl = useIntl();
  const switches = ops?.ops ?? data.ops;
  const health = overviewHealth(data, switches);
  const days = daysWithData(data.days, data.sourceStartDay);
  const totals = sumCounts(days.map((d) => d.totals));
  const hasData = days.length > 0;
  const series = (m: (typeof tiles)[number][0]) =>
    data.days.map((d) =>
      data.sourceStartDay && d.day >= data.sourceStartDay ? (d.totals[m] ?? 0) : null,
    );
  return (
    <div className="stack">
      <TabHeader
        title={<FormattedMessage id="ntf.tab.overview" />}
        purpose={<FormattedMessage id="ntf.purpose.overview" />}
      />
      <HealthLine health={health} onTab={onTab} />
      <Freshness data={data} />
      {!hasData && (
        <EmptyState icon={BellOff} title={<FormattedMessage id="ntf.noStats" />}>
          <FormattedMessage id="ntf.noStatsNote" />
        </EmptyState>
      )}
      <StatTiles
        items={tiles.map(([m, tone]) => ({
          key: m,
          label: (
            <span className="inline-flex items-center gap-1">
              <FormattedMessage id={`ntf.metric.${m}`} />
              <Hint>
                <FormattedMessage id={`ntf.metric.${m}.def`} />
              </Hint>
            </span>
          ),
          value: hasData ? intl.formatNumber(totals[m] ?? 0) : '—',
          tone: m === 'failed' ? ((totals.failed ?? 0) > 0 ? tone : 'default') : tone,
          foot: hasData ? (
            <Sparkline
              points={series(m)}
              label={intl.formatMessage(
                { id: 'ntf.ov.sparkline' },
                { label: intl.formatMessage({ id: `ntf.metric.${m}` }) },
              )}
            />
          ) : undefined,
        }))}
      />
      <p className="text-[12px] text-muted-foreground">
        <FormattedMessage id="ntf.acceptedNotDelivered" />
      </p>
      <div className="grid grid-cols-[minmax(0,1fr)] gap-4 lg:grid-cols-2">
        <Panel title={<FormattedMessage id="ntf.ov.quick" />}>
          <ul className="grid gap-1">
            <QuickLink
              label={<FormattedMessage id="ntf.ov.problems" />}
              count={data.problems.length}
              tone={data.problems.length ? 'error' : 'ok'}
              onClick={onTab ? () => onTab('delivery') : undefined}
            />
            {reviewCount !== undefined && (
              <QuickLink
                label={<FormattedMessage id="ntf.ov.inReview" />}
                count={reviewCount}
                tone={reviewCount ? 'warn' : 'muted'}
                onClick={onTab ? () => onTab('templates') : undefined}
              />
            )}
          </ul>
          {canTimeline && onTimeline && <TimelineLookup onOpen={onTimeline} />}
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
            <SwitchLine
              label={<FormattedMessage id="ntf.ops.templatesEnabled" />}
              on={switches.templatesEnabled}
            />
            <SwitchLine
              label={<FormattedMessage id="ntf.ops.retryEnabled" />}
              on={switches.retryEnabled}
            />
            {inboxGroups.map((g) => (
              <SwitchLine
                key={g}
                label={
                  <FormattedMessage
                    id="ntf.ops.pushFor"
                    values={{ name: intl.formatMessage({ id: `ntf.group.${g}` }) }}
                  />
                }
                on={!switches.pushPaused[g]}
                onId="ntf.ops.sending"
                offId="ntf.ops.paused"
              />
            ))}
            {ops && (
              <SwitchLine
                label={<FormattedMessage id="ntf.policy.title" />}
                on={ops.engagementPolicyStored && ops.engagementPolicy.approved}
                onId="ntf.policy.approvedShort"
                offId="ntf.policy.offShort"
              />
            )}
          </ul>
        </Panel>
      </div>
    </div>
  );
}

function HealthLine({
  health,
  onTab,
}: {
  health: OverviewHealth;
  onTab?: (tab: NotificationTab) => void;
}) {
  const intl = useIntl();
  if (health.level === 'no_data')
    return (
      <Notice title={<FormattedMessage id="ntf.health.no_data" />}>
        <FormattedMessage id="ntf.health.no_data.note" />
      </Notice>
    );
  if (health.level === 'ok')
    return (
      <Notice tone="ok" title={<FormattedMessage id="ntf.health.ok" />}>
        <FormattedMessage
          id="ntf.health.ok.note"
          values={{ v: rateText(intl, health.failureRate) }}
        />
      </Notice>
    );
  return (
    <Notice
      tone="warn"
      title={<FormattedMessage id="ntf.health.attention" />}
      action={
        onTab && (
          <Button onClick={() => onTab('delivery')}>
            <FormattedMessage id="ntf.ov.openDelivery" />
          </Button>
        )
      }
    >
      <ul className="list-disc pl-4">
        {health.signals.map((s) => (
          <li key={s.id}>
            <FormattedMessage
              id={`ntf.health.signal.${s.id}`}
              values={{ n: s.n, v: rateText(intl, health.failureRate) }}
            />
          </li>
        ))}
      </ul>
    </Notice>
  );
}

function QuickLink({
  label,
  count,
  tone,
  onClick,
}: {
  label: ReactNode;
  count: number | null;
  tone: 'ok' | 'warn' | 'error' | 'muted';
  onClick?: () => void;
}) {
  const intl = useIntl();
  const body = (
    <>
      <StatusDot tone={tone}>{label}</StatusDot>
      <span className="ml-auto font-semibold tabular-nums">
        {count === null ? '—' : intl.formatNumber(count)}
      </span>
      {onClick && <ArrowRight className="size-4 text-muted-foreground" aria-hidden="true" />}
    </>
  );
  return (
    <li>
      {onClick ? (
        <button
          type="button"
          onClick={onClick}
          className="flex w-full items-center gap-3 rounded-md px-2 py-2 text-left text-sm outline-none hover:bg-muted focus-visible:ring-[3px] focus-visible:ring-ring/50"
        >
          {body}
        </button>
      ) : (
        <div className="flex items-center gap-3 px-2 py-2 text-sm">{body}</div>
      )}
    </li>
  );
}

function SwitchLine({
  label,
  on,
  onId = 'ntf.on',
  offId = 'ntf.off',
}: {
  label: ReactNode;
  on: boolean;
  onId?: string;
  offId?: string;
}) {
  return (
    <li className="flex items-center justify-between gap-2">
      <span>{label}</span>
      <StatusDot tone={on ? 'ok' : 'warn'}>
        <FormattedMessage id={on ? onId : offId} />
      </StatusDot>
    </li>
  );
}

/** "Tra cứu gia đình": a family code straight into the timeline tab. */
export function TimelineLookup({ onOpen }: { onOpen: (code: string) => void }) {
  const intl = useIntl();
  const [value, setValue] = useState('');
  const [invalid, setInvalid] = useState(false);
  const submit = (e: FormEvent) => {
    e.preventDefault();
    const code = normalizeFamilyCode(value);
    setInvalid(!code);
    if (code) onOpen(code);
  };
  return (
    <form className="mt-3 grid gap-1.5 border-t pt-3" onSubmit={submit}>
      <label className="text-[13px] font-medium" htmlFor="ntf-ov-lookup">
        <FormattedMessage id="ntf.ov.lookup" />
      </label>
      <div className="flex gap-2">
        <Input
          id="ntf-ov-lookup"
          className="w-36 font-mono uppercase"
          placeholder="F-XXXX"
          value={value}
          aria-invalid={invalid || undefined}
          aria-describedby="ntf-ov-lookup-hint"
          onChange={(e) => setValue(e.target.value)}
        />
        <Button type="submit">
          <Search className="size-4" aria-hidden="true" />
          {intl.formatMessage({ id: 'ntf.timeline.open' })}
        </Button>
      </div>
      <p
        id="ntf-ov-lookup-hint"
        className={invalid ? 'text-xs text-destructive' : 'text-xs text-muted-foreground'}
      >
        <FormattedMessage id="ntf.timeline.badCode" />
      </p>
    </form>
  );
}

/** The overview with the page-level loads (stats 7 days, ops, templates in review). */
export function OverviewTab({
  stats,
  reloadStats,
  ops,
  reviewCount,
  canTimeline,
  onTab,
  onTimeline,
}: {
  stats: Load<NotificationStatsResponse> | null;
  reloadStats: () => void;
  ops: Load<NotificationOpsResponse> | null;
  reviewCount?: number | null;
  canTimeline: boolean;
  onTab: (tab: NotificationTab) => void;
  onTimeline: (code: string) => void;
}) {
  if (!stats) return <PageSkeleton />;
  return (
    <LoadedSkeleton load={stats} reload={reloadStats}>
      {(data) => (
        <OverviewView
          data={data}
          ops={ops?.status === 'ok' ? ops.data : null}
          reviewCount={reviewCount}
          canTimeline={canTimeline}
          onTab={onTab}
          onTimeline={onTimeline}
        />
      )}
    </LoadedSkeleton>
  );
}
