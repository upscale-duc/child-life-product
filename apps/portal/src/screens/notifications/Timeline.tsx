import {
  engagementKinds,
  engagementReasonCodes,
  inboxGroups,
  notificationDeliveryReasons,
  notificationDeliveryStates,
  notificationKinds,
  type NotificationEntryDetail,
  type NotificationTimelineResponse,
  type StaffNotificationTimelineRequest,
  type TimelineEntry,
  type TimelineRecipient,
} from '@child-life/contracts';
import { History, Search, ShieldAlert, SlidersHorizontal } from 'lucide-react';
import { useEffect, useRef, useState, type FormEvent, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { Input } from '@/components/ui/input';
import { Sheet, SheetContent, SheetTitle } from '@/components/ui/sheet';
import { ApiError, useApi, useLoad } from '../../api';
import { EmptyState, Notice, Section, StatTiles } from '../../content-kit';
import { ZONE } from '../../format';
import { Button, Segmented, SelectMenu } from '../../ui';
import {
  CodeText,
  DataTable,
  ErrorPanel,
  LoadedSkeleton,
  PageSkeleton,
  StatusDot,
  TabHeader,
  TableSkeleton,
  type DotTone,
} from './kit';
import {
  ErrorLine,
  RangePicker,
  at,
  dayLabel,
  defaultRange,
  destinationName,
  labelOr,
  normalizeFamilyCode,
  templateName,
  vnToday,
  type RangeChoice,
} from './shared';

type Filters = Pick<
  StaffNotificationTimelineRequest,
  'view' | 'group' | 'kind' | 'scenario' | 'delivery' | 'recipient'
>;
const noFilters: Filters = {
  view: 'all',
  group: 'all',
  kind: 'all',
  scenario: 'all',
  delivery: 'all',
  recipient: undefined,
};

/** The request for a family's timeline (the server validates the same shape). */
export function timelineRequest(
  code: string,
  range: { from: string; to: string },
  filters: Filters,
  cursor?: string,
): StaffNotificationTimelineRequest {
  return {
    code,
    from: range.from,
    to: range.to,
    view: filters.view,
    group: filters.group,
    kind: filters.kind,
    scenario: filters.scenario,
    delivery: filters.delivery,
    ...(filters.recipient ? { recipient: filters.recipient } : {}),
    ...(cursor ? { cursor } : {}),
  };
}

/** A server reason (delivery or engagement) as words; an unknown code is shown as it is. */
export function reasonLabel(intl: IntlShape, reason: string | null): string {
  if (!reason) return '—';
  if ((notificationDeliveryReasons as readonly string[]).includes(reason))
    return intl.formatMessage({ id: `ntf.reason.${reason}` });
  if ((engagementReasonCodes as readonly string[]).includes(reason))
    return intl.formatMessage({ id: `ntf.engReason.${reason}` });
  return reason;
}

/** The masked recipient ("Ba mẹ 1"), never a uid or email. */
export function recipientLabel(
  intl: IntlShape,
  recipients: readonly TimelineRecipient[],
  ref: string | null,
): string {
  if (!ref) return '—';
  const r = recipients.find((x) => x.ref === ref);
  if (ref === 'former' || r?.role === 'former')
    return intl.formatMessage({ id: 'ntf.recipient.former' });
  if (!r) return ref;
  // The server's label is "<role> <n>"; it is rebuilt from role + ref so it is translated.
  const n = /^m(\d{1,2})$/.exec(r.ref)?.[1];
  const id = `ntf.recipient.${r.role}`;
  if (n && intl.messages[id]) return intl.formatMessage({ id }, { n: Number(n) });
  return r.label || r.role;
}

/** Engagement intent statuses the server emits as `decision` / `engagementStatus`. */
export const intentStatuses = [
  'eligible',
  'deferred',
  'in_app_only',
  'suppressed',
  'cancelled',
  'expired',
  'attempted',
  'accepted',
  'failed',
  'unknown',
  'completed',
] as const;

/** An intent status, else a delivery state, else the raw code. */
export function intentLabel(intl: IntlShape, status: string | null): string {
  if (!status) return '—';
  if ((intentStatuses as readonly string[]).includes(status))
    return intl.formatMessage({ id: `ntf.intent.${status}` });
  return labelOr(intl, `ntf.delivery.${status}`, status);
}

/** "ENG-01:pending" → "Ảnh chờ chọn · Ảnh đang chờ"; a producer id → its name. */
export function whyLabel(intl: IntlShape, why: string | null): string {
  if (!why) return '—';
  const m = /^(ENG-0[1-6]):([a-z_]+)$/.exec(why);
  if (m) {
    const eng = labelOr(intl, `ntf.eng.${m[1]}`, m[1]!);
    return `${m[1]} ${eng} · ${labelOr(intl, `ntf.whySource.${m[2]}`, m[2]!)}`;
  }
  return labelOr(intl, `ntf.producer.${why}`, why);
}

/** Filters that differ from the defaults ("Bộ lọc (n)"). */
export function activeFilterCount(f: Filters): number {
  return (
    (f.view !== 'all' ? 1 : 0) +
    (f.group !== 'all' ? 1 : 0) +
    (f.kind !== 'all' ? 1 : 0) +
    (f.scenario !== 'all' ? 1 : 0) +
    (f.delivery !== 'all' ? 1 : 0) +
    (f.recipient ? 1 : 0)
  );
}

/** Entries by Vietnam day, newest day first, in the server's order inside a day. */
export function groupByDay(entries: readonly TimelineEntry[]) {
  const out: Array<{ day: string; entries: TimelineEntry[] }> = [];
  for (const e of entries) {
    const day = vnToday(new Date(e.at));
    const last = out[out.length - 1];
    if (last && last.day === day) last.entries.push(e);
    else out.push({ day, entries: [e] });
  }
  return out;
}

/** The dot of an entry's status: delivery when it was pushed, else the engagement status. */
export function entryTone(e: TimelineEntry): DotTone {
  const s = e.delivery ?? e.engagementStatus;
  if (!s) return 'muted';
  if (['accepted', 'completed'].includes(s)) return 'ok';
  if (['failed', 'rejected'].includes(s)) return 'error';
  if (['retry_pending', 'unknown', 'deferred'].includes(s)) return 'warn';
  if (['pending', 'scheduled', 'attempted', 'eligible'].includes(s)) return 'wait';
  return 'muted';
}

type State =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'error'; error: ApiError }
  | { status: 'ok'; data: NotificationTimelineResponse; entries: TimelineEntry[] };

/**
 * Dòng thời gian gia đình: one family's notifications and Smart Engagement, by family code.
 * Restricted (notifications.timeline) and audited on every load; recipients are masked refs.
 */
export function TimelineTab({
  initialCode,
  onCode,
}: {
  initialCode?: string;
  onCode?: (code: string) => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const [input, setInput] = useState(initialCode ?? '');
  const [code, setCode] = useState<string | null>(initialCode ?? null);
  const [invalid, setInvalid] = useState(false);
  const [range, setRange] = useState<RangeChoice>(() => defaultRange(30));
  const [filters, setFilters] = useState<Filters>(noFilters);
  const [showFilters, setShowFilters] = useState(false);
  const [state, setState] = useState<State>({ status: 'idle' });
  const [recipients, setRecipients] = useState<TimelineRecipient[]>([]);
  const [more, setMore] = useState<{ busy: boolean; error: ApiError | null }>({
    busy: false,
    error: null,
  });
  const [open, setOpen] = useState<string | null>(null);
  const [tick, setTick] = useState(0);
  const seq = useRef(0);

  useEffect(() => {
    if (!code) return;
    const mine = ++seq.current;
    setState({ status: 'loading' });
    api
      .call<NotificationTimelineResponse>(
        'staffNotificationTimeline',
        timelineRequest(code, range, filters),
      )
      .then((data) => {
        if (mine !== seq.current) return;
        setState({ status: 'ok', data, entries: data.entries });
        if (filters.recipient === undefined) setRecipients(data.recipients);
      })
      .catch((e: unknown) => {
        if (mine !== seq.current) return;
        setState({
          status: 'error',
          error: e instanceof ApiError ? e : new ApiError('unknown', null),
        });
      });
  }, [api, code, range, filters, tick]);

  const loadMore = async () => {
    if (state.status !== 'ok' || !state.data.nextCursor || !code) return;
    setMore({ busy: true, error: null });
    try {
      const next = await api.call<NotificationTimelineResponse>(
        'staffNotificationTimeline',
        timelineRequest(code, range, filters, state.data.nextCursor),
      );
      setState({ status: 'ok', data: next, entries: [...state.entries, ...next.entries] });
      setMore({ busy: false, error: null });
    } catch (e) {
      setMore({ busy: false, error: e instanceof ApiError ? e : new ApiError('unknown', null) });
    }
  };

  const submit = (e: FormEvent) => {
    e.preventDefault();
    const c = normalizeFamilyCode(input);
    setInvalid(!c);
    if (!c) return;
    setInput(c);
    if (c !== code) {
      setFilters(noFilters);
      setRecipients([]);
    }
    setCode(c);
    onCode?.(c);
  };

  const set = (next: Partial<Filters>) => setFilters((f) => ({ ...f, ...next }));
  const label = (id: string) => intl.formatMessage({ id });
  const all = label('ntf.filter.all');
  const nFilters = activeFilterCount(filters);

  return (
    <div className="stack">
      <TabHeader
        title={<FormattedMessage id="ntf.tab.timeline" />}
        purpose={<FormattedMessage id="ntf.purpose.timeline" />}
      />
      <div className="flex items-start gap-2 rounded-lg border border-warning/40 bg-warning/5 px-3 py-2 text-[13px]">
        <ShieldAlert className="mt-0.5 size-4 shrink-0 text-warning" aria-hidden="true" />
        <FormattedMessage id="ntf.timeline.audited" />
      </div>
      <form className="grid gap-1.5" onSubmit={submit} role="search">
        <label className="text-[13px] font-medium" htmlFor="ntf-timeline-code">
          <FormattedMessage id="ntf.timeline.code" />
        </label>
        <div className="flex flex-wrap gap-2">
          <div className="relative">
            <Search
              className="pointer-events-none absolute top-1/2 left-2.5 size-4 -translate-y-1/2 text-muted-foreground"
              aria-hidden="true"
            />
            <Input
              id="ntf-timeline-code"
              className="w-44 pl-8 font-mono uppercase"
              value={input}
              placeholder="F-XXXX"
              autoComplete="off"
              spellCheck={false}
              aria-invalid={invalid || undefined}
              aria-describedby="ntf-timeline-code-hint"
              onChange={(e) => setInput(e.target.value)}
            />
          </div>
          <Button type="submit" kind="primary">
            <FormattedMessage id="ntf.timeline.open" />
          </Button>
          {code && (
            <Button
              onClick={() => setShowFilters((v) => !v)}
              title={label('ntf.timeline.filters.toggle')}
            >
              <SlidersHorizontal className="size-4" aria-hidden="true" />
              <FormattedMessage id="ntf.timeline.filters" values={{ n: nFilters }} />
            </Button>
          )}
        </div>
        <p
          id="ntf-timeline-code-hint"
          className={invalid ? 'text-xs text-destructive' : 'text-xs text-muted-foreground'}
          role={invalid ? 'alert' : undefined}
        >
          <FormattedMessage id="ntf.timeline.badCode" />
        </p>
      </form>
      {code && showFilters && (
        <div
          className="grid gap-3 rounded-xl border bg-card p-4"
          aria-label={label('ntf.timeline.filters.toggle')}
          role="group"
        >
          <RangePicker value={range} onChange={setRange} />
          <div className="flex flex-wrap items-center gap-2">
            <Segmented
              label={label('ntf.timeline.view')}
              value={filters.view}
              options={(['all', 'engagement'] as const).map((v) => ({
                value: v,
                label: <FormattedMessage id={`ntf.timeline.view.${v}`} />,
              }))}
              onChange={(view) => set({ view })}
            />
            <SelectMenu
              label={label('ntf.col.group')}
              value={filters.group}
              options={(['all', ...inboxGroups] as const).map((g) => ({
                value: g,
                label: g === 'all' ? `${label('ntf.col.group')}: ${all}` : label(`ntf.group.${g}`),
              }))}
              onChange={(group) => set({ group })}
            />
            <SelectMenu
              label={label('ntf.col.kind')}
              value={filters.kind}
              options={(['all', ...notificationKinds] as const).map((k) => ({
                value: k,
                label: k === 'all' ? `${label('ntf.col.kind')}: ${all}` : label(`ntf.kind.${k}`),
              }))}
              onChange={(kind) => set({ kind })}
            />
            <SelectMenu
              label={label('ntf.col.scenario')}
              value={filters.scenario}
              options={(['all', ...engagementKinds] as const).map((s) => ({
                value: s,
                label:
                  s === 'all'
                    ? `${label('ntf.col.scenario')}: ${all}`
                    : `${s} · ${label(`ntf.eng.${s}`)}`,
              }))}
              onChange={(scenario) => set({ scenario })}
            />
            <SelectMenu
              label={label('ntf.col.delivery')}
              value={filters.delivery}
              options={(['all', ...notificationDeliveryStates] as const).map((s) => ({
                value: s,
                label:
                  s === 'all' ? `${label('ntf.col.delivery')}: ${all}` : label(`ntf.delivery.${s}`),
              }))}
              onChange={(delivery) => set({ delivery })}
            />
            {recipients.length > 0 && (
              <SelectMenu
                label={label('ntf.col.recipient')}
                value={filters.recipient ?? 'all'}
                options={[
                  { value: 'all', label: `${label('ntf.col.recipient')}: ${all}` },
                  ...recipients.map((r) => ({
                    value: r.ref,
                    label: recipientLabel(intl, recipients, r.ref),
                  })),
                ]}
                onChange={(r) => set({ recipient: r === 'all' ? undefined : r })}
              />
            )}
            {nFilters > 0 && (
              <Button kind="ghost" onClick={() => setFilters(noFilters)}>
                <FormattedMessage id="kit.clearFilters" />
              </Button>
            )}
          </div>
        </div>
      )}
      {!code ? (
        <EmptyState icon={History} title={<FormattedMessage id="ntf.timeline.start" />}>
          <FormattedMessage id="ntf.timeline.startNote" />
        </EmptyState>
      ) : state.status === 'loading' || state.status === 'idle' ? (
        <PageSkeleton />
      ) : state.status === 'error' ? (
        <ErrorPanel error={state.error} onRetry={() => setTick((t) => t + 1)} />
      ) : (
        <>
          <TimelineView
            data={state.data}
            entries={state.entries}
            recipients={recipients.length ? recipients : state.data.recipients}
            onOpen={setOpen}
            onMore={state.data.nextCursor ? () => void loadMore() : undefined}
            loadingMore={more.busy}
          />
          <ErrorLine error={more.error} />
        </>
      )}
      {code && open && <DetailSheet code={code} entry={open} onClose={() => setOpen(null)} />}
    </div>
  );
}

const legend: Array<[DotTone, string]> = [
  ['ok', 'ntf.legend.ok'],
  ['wait', 'ntf.legend.wait'],
  ['warn', 'ntf.legend.warn'],
  ['error', 'ntf.legend.error'],
  ['muted', 'ntf.legend.muted'],
];

/** The loaded timeline: summary, entries by day, upcoming (confirmed vs predicted), preferences. */
export function TimelineView({
  data,
  entries,
  recipients,
  onOpen,
  onMore,
  loadingMore,
}: {
  data: NotificationTimelineResponse;
  entries: TimelineEntry[];
  recipients: TimelineRecipient[];
  onOpen: (entry: string) => void;
  onMore?: () => void;
  loadingMore?: boolean;
}) {
  const intl = useIntl();
  const s = data.summary;
  const label = (id: string, raw: string | null) => (raw ? labelOr(intl, id, raw) : null);
  const days = groupByDay(entries);
  return (
    <div className="stack">
      <p className="text-[13px] text-muted-foreground">
        <FormattedMessage
          id="ntf.timeline.family"
          values={{ code: data.family.code, a: data.family.babies, c: data.family.members }}
        />
        {' · '}
        <FormattedMessage id="ntf.sum.lastActivity" />: {at(intl, s.lastActivityAt)}
      </p>
      {data.truncated && (
        <Notice tone="warn">
          <FormattedMessage id="ntf.timeline.truncated" />
        </Notice>
      )}
      <StatTiles
        items={[
          {
            key: 'n',
            label: <FormattedMessage id="ntf.sum.notifications" />,
            value: intl.formatNumber(s.notifications),
          },
          {
            key: 'e',
            label: <FormattedMessage id="ntf.sum.engagements" />,
            value: intl.formatNumber(s.engagements),
            foot: (
              <FormattedMessage
                id="ntf.sum.engagementsFoot"
                values={{ a: s.completed, c: s.pending }}
              />
            ),
          },
          {
            key: 's',
            label: <FormattedMessage id="ntf.sum.suppressed" />,
            value: intl.formatNumber(s.suppressed),
            tone: 'muted',
          },
          {
            key: 'f',
            label: <FormattedMessage id="ntf.sum.failed" />,
            value: intl.formatNumber(s.failed),
            tone: s.failed > 0 ? 'error' : 'default',
          },
        ]}
      />
      <div className="grid items-start gap-4 xl:grid-cols-[minmax(0,1fr)_minmax(300px,360px)]">
        <Section
          flush
          title={<FormattedMessage id="ntf.timeline.entries" />}
          description={
            <span
              className="flex flex-wrap gap-x-3 gap-y-1"
              aria-label={intl.formatMessage({ id: 'ntf.legend' })}
            >
              {legend.map(([tone, id]) => (
                <StatusDot key={tone} tone={tone}>
                  <FormattedMessage id={id} />
                </StatusDot>
              ))}
            </span>
          }
        >
          {entries.length === 0 ? (
            <EmptyState title={<FormattedMessage id="ntf.timeline.noEntries" />} />
          ) : (
            <DataTable min={860} label={intl.formatMessage({ id: 'ntf.timeline.entries' })}>
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
                      <FormattedMessage id="ntf.col.recipient" />
                    </th>
                    <th>
                      <FormattedMessage id="ntf.col.status" />
                    </th>
                    <th>
                      <FormattedMessage id="ntf.col.reason" />
                    </th>
                    <th>
                      <span className="sr-only">
                        <FormattedMessage id="ntf.timeline.details" />
                      </span>
                    </th>
                  </tr>
                </thead>
                {days.map((d) => (
                  <tbody key={d.day}>
                    <tr className="hover:bg-transparent">
                      <th
                        colSpan={6}
                        scope="rowgroup"
                        className="bg-background text-[12px] font-semibold text-foreground"
                      >
                        {dayLabel(intl, d.day)}
                        <span className="ml-2 font-normal text-muted-foreground">
                          <FormattedMessage
                            id="ntf.timeline.dayCount"
                            values={{ n: d.entries.length }}
                          />
                        </span>
                      </th>
                    </tr>
                    {d.entries.map((e) => {
                      const status = e.delivery
                        ? labelOr(intl, `ntf.delivery.${e.delivery}`, e.delivery)
                        : intentLabel(intl, e.engagementStatus);
                      const extra = [
                        label(`ntf.channel.${e.channel}`, e.channel),
                        label(`ntf.lifecycle.${e.lifecycle}`, e.lifecycle),
                        label(`ntf.read.${e.read}`, e.read),
                        e.action && e.action !== 'none'
                          ? label(`ntf.action.${e.action}`, e.action)
                          : null,
                      ].filter(Boolean);
                      return (
                        <tr key={e.entry} data-entry={e.entry}>
                          <td className="nowrap text-[13px] tabular-nums">
                            {intl.formatTime(e.at, {
                              hour: '2-digit',
                              minute: '2-digit',
                              timeZone: ZONE,
                            })}
                          </td>
                          <td>
                            {e.kind ? <FormattedMessage id={`ntf.kind.${e.kind}`} /> : '—'}
                            <span className="block text-[12px] text-muted-foreground">
                              {e.scenario && (
                                <>
                                  {e.scenario} {labelOr(intl, `ntf.eng.${e.scenario}`, '')}
                                </>
                              )}
                              {e.templateId && (
                                <>
                                  {e.scenario ? ' · ' : ''}
                                  {templateName(intl, e.templateId)}@{e.templateVersion ?? 0}
                                </>
                              )}
                            </span>
                          </td>
                          <td className="text-[13px]" data-recipient={e.recipient}>
                            {recipientLabel(intl, recipients, e.recipient)}
                          </td>
                          <td>
                            <StatusDot tone={entryTone(e)}>{status}</StatusDot>
                            {extra.length > 0 && (
                              <span className="block text-[12px] text-muted-foreground">
                                {extra.join(' · ')}
                              </span>
                            )}
                          </td>
                          <td className="text-[13px]">{reasonLabel(intl, e.reason)}</td>
                          <td className="text-right">
                            <Button kind="ghost" onClick={() => onOpen(e.entry)}>
                              <FormattedMessage id="ntf.timeline.details" />
                            </Button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                ))}
              </table>
            </DataTable>
          )}
          {onMore && (
            <div className="flex justify-center border-t p-3">
              <Button disabled={loadingMore} onClick={onMore}>
                <FormattedMessage id="ntf.timeline.more" />
              </Button>
            </div>
          )}
        </Section>
        <div className="grid gap-4">
          <UpcomingPanel upcoming={data.upcoming} recipients={recipients} />
          <Section title={<FormattedMessage id="ntf.timeline.preferences" />} flush collapsible>
            {data.preferences.length === 0 ? (
              <EmptyState title={<FormattedMessage id="ntf.timeline.noPreferences" />} />
            ) : (
              <ul>
                {data.preferences.map((p) => (
                  <li
                    key={p.recipient}
                    className="grid gap-0.5 border-b px-5 py-3 text-[13px] last:border-b-0"
                  >
                    <span className="font-medium">
                      {recipientLabel(intl, recipients, p.recipient)}
                    </span>
                    <span>
                      <span className="text-muted-foreground">
                        <FormattedMessage id="ntf.col.muted" />:{' '}
                      </span>
                      {p.muted.length ? (
                        p.muted.map((m) => labelOr(intl, `ntf.setting.${m}`, m)).join(', ')
                      ) : (
                        <FormattedMessage id="ntf.timeline.noneMuted" />
                      )}
                    </span>
                    <span>
                      <span className="text-muted-foreground">
                        <FormattedMessage id="ntf.col.consent" />:{' '}
                      </span>
                      <FormattedMessage
                        id={
                          p.engagementConsent === null
                            ? 'ntf.consent.unset'
                            : p.engagementConsent
                              ? 'ntf.consent.yes'
                              : 'ntf.consent.no'
                        }
                      />
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </Section>
        </div>
      </div>
    </div>
  );
}

/** Sắp tới: confirmed sends are solid cards, predicted ones dashed (and labelled, not colour only). */
export function UpcomingPanel({
  upcoming,
  recipients,
}: {
  upcoming: NotificationTimelineResponse['upcoming'];
  recipients: TimelineRecipient[];
}) {
  const intl = useIntl();
  return (
    <Section
      title={<FormattedMessage id="ntf.timeline.upcoming" />}
      description={
        <span className="grid gap-1">
          <span className="flex items-center gap-2">
            <span
              className="h-3 w-5 rounded-sm border-2 border-solid border-success"
              aria-hidden="true"
            />
            <FormattedMessage id="ntf.certainty.confirmed" />
            <span className="text-muted-foreground">
              <FormattedMessage id="ntf.certainty.confirmed.def" />
            </span>
          </span>
          <span className="flex items-center gap-2">
            <span
              className="h-3 w-5 rounded-sm border-2 border-dashed border-muted-foreground"
              aria-hidden="true"
            />
            <FormattedMessage id="ntf.certainty.predicted" />
            <span className="text-muted-foreground">
              <FormattedMessage id="ntf.certainty.predicted.def" />
            </span>
          </span>
        </span>
      }
    >
      {upcoming.length === 0 ? (
        <p className="text-sm text-muted-foreground">
          <FormattedMessage id="ntf.timeline.noUpcoming" />
        </p>
      ) : (
        <ul className="grid gap-2">
          {upcoming.map((u, i) => (
            <li
              key={`${u.scenario}-${i}`}
              data-certainty={u.certainty}
              className={
                u.certainty === 'confirmed'
                  ? 'grid gap-1 rounded-lg border-2 border-solid border-success/50 bg-success/5 p-3 text-[13px]'
                  : 'grid gap-1 rounded-lg border-2 border-dashed border-muted-foreground/40 p-3 text-[13px]'
              }
            >
              <span className="flex flex-wrap items-center gap-2">
                <span className="font-semibold">
                  {u.scenario} {labelOr(intl, `ntf.eng.${u.scenario}`, '')}
                </span>
                <span className="ml-auto text-[12px] font-medium uppercase">
                  <FormattedMessage id={`ntf.certainty.${u.certainty}`} />
                </span>
              </span>
              <span className="text-muted-foreground">
                <FormattedMessage id={`ntf.upState.${u.state}`} /> · {at(intl, u.at)}
                {u.expiresAt && (
                  <>
                    {' · '}
                    <FormattedMessage id="ntf.col.expires" /> {at(intl, u.expiresAt)}
                  </>
                )}
              </span>
              {u.recipient && <span>{recipientLabel(intl, recipients, u.recipient)}</span>}
              {u.conditions.length > 0 && (
                <ul className="list-disc pl-4 text-[12px] text-muted-foreground">
                  {u.conditions.map((c) => (
                    <li key={c}>{labelOr(intl, `ntf.condition.${c}`, c)}</li>
                  ))}
                </ul>
              )}
            </li>
          ))}
        </ul>
      )}
    </Section>
  );
}

function DetailSheet({
  code,
  entry,
  onClose,
}: {
  code: string;
  entry: string;
  onClose: () => void;
}) {
  const intl = useIntl();
  const [load, reload] = useLoad<NotificationEntryDetail>(
    'staffNotificationDetail',
    { code, entry },
    `ntf-detail:${code}:${entry}`,
  );
  return (
    <Sheet open onOpenChange={(o) => !o && onClose()}>
      <SheetContent
        side="right"
        aria-describedby={undefined}
        closeLabel={intl.formatMessage({ id: 'action.close' })}
        className="w-full gap-0 overflow-y-auto sm:max-w-xl"
      >
        <div className="border-b px-6 py-5">
          <SheetTitle className="text-base">
            <FormattedMessage id="ntf.detail.title" />
          </SheetTitle>
          <CodeText value={entry} max="max-w-full" />
        </div>
        <div className="p-6">
          <LoadedSkeleton load={load} reload={reload} skeleton={<TableSkeleton rows={8} />}>
            {(d) => <EntryDetailView detail={d} />}
          </LoadedSkeleton>
        </div>
      </SheetContent>
    </Sheet>
  );
}

const yesNo = (v: boolean | null) =>
  v === null ? 'ntf.detail.unknown' : v ? 'ntf.detail.yes' : 'ntf.detail.no';
const yesNoTone = (v: boolean | null): DotTone => (v === null ? 'muted' : v ? 'ok' : 'warn');

function DetailSection({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="grid gap-2">
      <h3 className="text-[13px] font-semibold tracking-wide text-muted-foreground uppercase">
        <FormattedMessage id={title} />
      </h3>
      {children}
    </section>
  );
}

/** Why · Checks · Delivery · Outcome, with the state transitions as a vertical timeline. */
export function EntryDetailView({ detail: d }: { detail: NotificationEntryDetail }) {
  const intl = useIntl();
  const stateOf = (dimension: string, to: string) => {
    const prefix: Record<string, string> = {
      lifecycle: 'ntf.lifecycle',
      delivery: 'ntf.delivery',
      read: 'ntf.read',
      action: 'ntf.action',
      engagement: 'ntf.intent',
    };
    return prefix[dimension] ? labelOr(intl, `${prefix[dimension]}.${to}`, to) : to;
  };
  const row = (id: string, value: ReactNode) => (
    <>
      <dt className="text-muted-foreground">
        <FormattedMessage id={id} />
      </dt>
      <dd className="min-w-0">{value}</dd>
    </>
  );
  const dl = 'grid grid-cols-[minmax(0,10rem)_minmax(0,1fr)] gap-x-3 gap-y-1.5 text-sm';
  return (
    <div className="grid gap-6">
      <DetailSection title="ntf.detail.section.why">
        <dl className={dl}>
          {row('ntf.detail.why', whyLabel(intl, d.why))}
          {row('ntf.col.kind', d.kind ? <FormattedMessage id={`ntf.kind.${d.kind}`} /> : '—')}
          {row(
            'ntf.col.scenario',
            d.scenario ? `${d.scenario} · ${labelOr(intl, `ntf.eng.${d.scenario}`, '')}` : '—',
          )}
          {row('ntf.detail.decision', intentLabel(intl, d.decision))}
          {row('ntf.col.reason', reasonLabel(intl, d.reason))}
        </dl>
      </DetailSection>
      <DetailSection title="ntf.detail.checks">
        {d.checks.length === 0 ? (
          <p className="text-sm text-muted-foreground">—</p>
        ) : (
          <ul className="grid gap-1.5 text-sm">
            {d.checks.map((c, i) => (
              <li key={`${c.rule}-${i}`} className="flex flex-wrap items-baseline gap-x-2">
                <StatusDot
                  tone={c.result === 'pass' ? 'ok' : c.result === 'fail' ? 'error' : 'muted'}
                >
                  <span className="sr-only">
                    <FormattedMessage id={`ntf.check.${c.result}`} />:{' '}
                  </span>
                  {labelOr(intl, `ntf.rule.${c.rule}`, c.rule)}
                </StatusDot>
                <span className="text-[12px] text-muted-foreground" aria-hidden="true">
                  <FormattedMessage id={`ntf.check.${c.result}`} />
                </span>
                {c.detail && (
                  <span className="w-full pl-3.5 text-[12px] text-muted-foreground">
                    {reasonLabel(intl, c.detail)}
                  </span>
                )}
              </li>
            ))}
          </ul>
        )}
      </DetailSection>
      <DetailSection title="ntf.detail.section.delivery">
        <dl className={dl}>
          {row(
            'ntf.col.template',
            d.templateId ? `${templateName(intl, d.templateId)} @${d.templateVersion ?? 0}` : '—',
          )}
          {row('ntf.col.destination', destinationName(intl, d.destination))}
          {row(
            'ntf.detail.pushAttempted',
            <StatusDot tone={yesNoTone(d.pushAttempted)}>
              <FormattedMessage id={yesNo(d.pushAttempted)} />
            </StatusDot>,
          )}
          {row(
            'ntf.detail.providerAccepted',
            <StatusDot tone={yesNoTone(d.providerAccepted)}>
              <FormattedMessage id={yesNo(d.providerAccepted)} />
            </StatusDot>,
          )}
        </dl>
        <p className="text-[12px] text-muted-foreground">
          <FormattedMessage id="ntf.acceptedNotDelivered" />
        </p>
        {d.timeline.length > 0 && (
          <ol className="relative ml-1.5 grid gap-3 border-l pl-5">
            {d.timeline.map((t, i) => (
              <li key={i} className="relative text-sm">
                <span
                  className="absolute top-1.5 -left-[25px] size-2.5 rounded-full border-2 border-background bg-primary"
                  aria-hidden="true"
                />
                <span className="block text-[12px] text-muted-foreground tabular-nums">
                  {at(intl, t.at)}
                </span>
                <span className="font-medium">
                  {labelOr(intl, `ntf.dimension.${t.dimension}`, t.dimension)}
                </span>
                {' → '}
                {stateOf(t.dimension, t.to)}
                {t.reason && (
                  <span className="text-muted-foreground"> · {reasonLabel(intl, t.reason)}</span>
                )}
              </li>
            ))}
          </ol>
        )}
      </DetailSection>
      <DetailSection title="ntf.detail.outcome">
        <dl className={dl}>
          {row(
            'ntf.detail.opened',
            <StatusDot tone={yesNoTone(d.opened)}>
              <FormattedMessage id={yesNo(d.opened)} />
            </StatusDot>,
          )}
          {row(
            'ntf.detail.navigation',
            d.navigated ? <FormattedMessage id={`ntf.nav.${d.navigated}`} /> : '—',
          )}
          {row(
            'ntf.detail.completed',
            <StatusDot tone={yesNoTone(d.completed)}>
              <FormattedMessage id={yesNo(d.completed)} />
            </StatusDot>,
          )}
          {d.cancelledOrExpired &&
            row('ntf.detail.cancelled', reasonLabel(intl, d.cancelledOrExpired))}
        </dl>
      </DetailSection>
      {d.errors.length > 0 && (
        <Notice tone="error" title={<FormattedMessage id="ntf.detail.errors" />}>
          <ul className="list-disc pl-4 text-[12px]">
            {d.errors.map((e) =>
              e === 'delivery_failed' || e === 'delivery_unknown' ? (
                <li key={e}>
                  <FormattedMessage id={`ntf.deliveryError.${e}`} />
                </li>
              ) : (
                <li key={e} className="font-mono break-all">
                  {e}
                </li>
              ),
            )}
          </ul>
        </Notice>
      )}
    </div>
  );
}
