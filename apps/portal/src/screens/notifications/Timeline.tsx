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
import { History, Search } from 'lucide-react';
import { useEffect, useRef, useState, type FormEvent, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { Input } from '@/components/ui/input';
import { Sheet, SheetContent, SheetTitle } from '@/components/ui/sheet';
import { ApiError, useApi, useLoad } from '../../api';
import { EmptyState, Notice, Section, StatTiles } from '../../content-kit';
import { Button, Loaded, Loading, Pill, Segmented, SelectMenu, TableScroll } from '../../ui';
import {
  DeliveryPill,
  ErrorLine,
  RangePicker,
  at,
  defaultRange,
  destinationName,
  labelOr,
  normalizeFamilyCode,
  templateName,
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
  const [state, setState] = useState<State>({ status: 'idle' });
  const [recipients, setRecipients] = useState<TimelineRecipient[]>([]);
  const [more, setMore] = useState<{ busy: boolean; error: ApiError | null }>({
    busy: false,
    error: null,
  });
  const [open, setOpen] = useState<string | null>(null);
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
  }, [api, code, range, filters]);

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

  return (
    <div className="stack">
      <Notice tone="warn">
        <FormattedMessage id="ntf.timeline.audited" />
      </Notice>
      <form className="flex flex-wrap items-end gap-2" onSubmit={submit}>
        <label className="grid gap-1 text-[13px] font-medium">
          <FormattedMessage id="ntf.timeline.code" />
          <Input
            className="w-36 font-mono uppercase"
            value={input}
            placeholder="F-7Q2K"
            aria-invalid={invalid || undefined}
            onChange={(e) => setInput(e.target.value)}
          />
        </label>
        <Button type="submit" kind="primary">
          <Search className="size-4" aria-hidden="true" />
          <FormattedMessage id="ntf.timeline.open" />
        </Button>
      </form>
      {invalid && (
        <p className="error" role="alert">
          <FormattedMessage id="ntf.timeline.badCode" />
        </p>
      )}
      {code && (
        <div className="grid gap-2">
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
                label: g === 'all' ? all : label(`ntf.group.${g}`),
              }))}
              onChange={(group) => set({ group })}
            />
            <SelectMenu
              label={label('ntf.col.kind')}
              value={filters.kind}
              options={(['all', ...notificationKinds] as const).map((k) => ({
                value: k,
                label: k === 'all' ? all : label(`ntf.kind.${k}`),
              }))}
              onChange={(kind) => set({ kind })}
            />
            <SelectMenu
              label={label('ntf.col.scenario')}
              value={filters.scenario}
              options={(['all', ...engagementKinds] as const).map((s) => ({
                value: s,
                label: s === 'all' ? all : `${s} · ${label(`ntf.eng.${s}`)}`,
              }))}
              onChange={(scenario) => set({ scenario })}
            />
            <SelectMenu
              label={label('ntf.col.delivery')}
              value={filters.delivery}
              options={(['all', ...notificationDeliveryStates] as const).map((s) => ({
                value: s,
                label: s === 'all' ? all : label(`ntf.delivery.${s}`),
              }))}
              onChange={(delivery) => set({ delivery })}
            />
            {recipients.length > 0 && (
              <SelectMenu
                label={label('ntf.col.recipient')}
                value={filters.recipient ?? 'all'}
                options={[
                  { value: 'all', label: all },
                  ...recipients.map((r) => ({
                    value: r.ref,
                    label: recipientLabel(intl, recipients, r.ref),
                  })),
                ]}
                onChange={(r) => set({ recipient: r === 'all' ? undefined : r })}
              />
            )}
          </div>
        </div>
      )}
      {!code ? (
        <EmptyState icon={History} title={<FormattedMessage id="ntf.timeline.start" />}>
          <FormattedMessage id="ntf.timeline.startNote" />
        </EmptyState>
      ) : state.status === 'loading' || state.status === 'idle' ? (
        <Loading />
      ) : state.status === 'error' ? (
        <ErrorLine error={state.error} />
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

/** The loaded timeline: summary, entries, upcoming (confirmed vs predicted) and preferences. */
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
  const label = (id: string, raw: string | null) => (raw ? labelOr(intl, id, raw) : '—');
  return (
    <div className="stack">
      <p className="text-[13px] text-muted-foreground">
        <FormattedMessage
          id="ntf.timeline.family"
          values={{ code: data.family.code, a: data.family.babies, c: data.family.members }}
        />
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
          },
          {
            key: 'c',
            label: <FormattedMessage id="ntf.sum.completed" />,
            value: intl.formatNumber(s.completed),
            tone: 'ok',
          },
          {
            key: 'p',
            label: <FormattedMessage id="ntf.sum.pending" />,
            value: intl.formatNumber(s.pending),
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
          {
            key: 'l',
            label: <FormattedMessage id="ntf.sum.lastActivity" />,
            value: <span className="text-base">{at(intl, s.lastActivityAt)}</span>,
          },
        ]}
      />
      <Section title={<FormattedMessage id="ntf.timeline.entries" />} flush>
        {entries.length === 0 ? (
          <EmptyState title={<FormattedMessage id="ntf.timeline.noEntries" />} />
        ) : (
          <TableScroll min={1300}>
            <table className="table">
              <thead>
                <tr>
                  {[
                    'time',
                    'kind',
                    'scenario',
                    'recipient',
                    'template',
                    'channel',
                    'lifecycle',
                    'delivery',
                    'read',
                    'action',
                    'reason',
                  ].map((c) => (
                    <th key={c}>
                      <FormattedMessage id={`ntf.col.${c}`} />
                    </th>
                  ))}
                  <th />
                </tr>
              </thead>
              <tbody>
                {entries.map((e) => (
                  <tr key={e.entry} data-entry={e.entry}>
                    <td className="nowrap">{at(intl, e.at)}</td>
                    <td>{e.kind ? <FormattedMessage id={`ntf.kind.${e.kind}`} /> : '—'}</td>
                    <td className="nowrap">
                      {e.scenario ? (
                        <>
                          <Pill tone="purple">{e.scenario}</Pill>{' '}
                          {labelOr(intl, `ntf.eng.${e.scenario}`, '')}
                        </>
                      ) : (
                        '—'
                      )}
                    </td>
                    <td data-recipient={e.recipient}>
                      {recipientLabel(intl, recipients, e.recipient)}
                    </td>
                    <td className="text-[13px]">
                      {e.templateId ? (
                        <>
                          {templateName(intl, e.templateId)}
                          <span className="text-muted-foreground">@{e.templateVersion ?? 0}</span>
                        </>
                      ) : (
                        '—'
                      )}
                    </td>
                    <td>{label(`ntf.channel.${e.channel}`, e.channel)}</td>
                    <td>{label(`ntf.lifecycle.${e.lifecycle}`, e.lifecycle)}</td>
                    <td>
                      <DeliveryPill state={e.delivery} />
                    </td>
                    <td>{label(`ntf.read.${e.read}`, e.read)}</td>
                    <td>
                      {e.action
                        ? label(`ntf.action.${e.action}`, e.action)
                        : e.engagementStatus
                          ? intentLabel(intl, e.engagementStatus)
                          : '—'}
                    </td>
                    <td>{reasonLabel(intl, e.reason)}</td>
                    <td className="text-right">
                      <Button kind="ghost" onClick={() => onOpen(e.entry)}>
                        <FormattedMessage id="ntf.timeline.details" />
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </TableScroll>
        )}
        {onMore && (
          <div className="flex justify-center border-t p-3">
            <Button disabled={loadingMore} onClick={onMore}>
              <FormattedMessage id="ntf.timeline.more" />
            </Button>
          </div>
        )}
      </Section>
      <Section
        title={<FormattedMessage id="ntf.timeline.upcoming" />}
        description={
          <span className="flex flex-wrap items-center gap-2">
            <Pill tone="ok">
              <FormattedMessage id="ntf.certainty.confirmed" />
            </Pill>
            <FormattedMessage id="ntf.certainty.confirmed.def" />
            <Pill tone="wait">
              <FormattedMessage id="ntf.certainty.predicted" />
            </Pill>
            <FormattedMessage id="ntf.certainty.predicted.def" />
          </span>
        }
        flush
      >
        {data.upcoming.length === 0 ? (
          <EmptyState title={<FormattedMessage id="ntf.timeline.noUpcoming" />} />
        ) : (
          <TableScroll min={900}>
            <table className="table">
              <thead>
                <tr>
                  {[
                    'scenario',
                    'certainty',
                    'state',
                    'at',
                    'expires',
                    'recipient',
                    'conditions',
                  ].map((c) => (
                    <th key={c}>
                      <FormattedMessage id={`ntf.col.${c}`} />
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {data.upcoming.map((u, i) => (
                  <tr key={`${u.scenario}-${i}`} data-certainty={u.certainty}>
                    <td className="nowrap">
                      <Pill tone="purple">{u.scenario}</Pill>{' '}
                      {labelOr(intl, `ntf.eng.${u.scenario}`, '')}
                    </td>
                    <td>
                      <Pill tone={u.certainty === 'confirmed' ? 'ok' : 'wait'}>
                        <FormattedMessage id={`ntf.certainty.${u.certainty}`} />
                      </Pill>
                    </td>
                    <td>
                      <FormattedMessage id={`ntf.upState.${u.state}`} />
                    </td>
                    <td className="nowrap">{at(intl, u.at)}</td>
                    <td className="nowrap">{at(intl, u.expiresAt)}</td>
                    <td>{recipientLabel(intl, recipients, u.recipient)}</td>
                    <td>
                      {u.conditions.length ? (
                        <ul className="list-disc pl-4 text-[13px]">
                          {u.conditions.map((c) => (
                            <li key={c}>{labelOr(intl, `ntf.condition.${c}`, c)}</li>
                          ))}
                        </ul>
                      ) : (
                        '—'
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </TableScroll>
        )}
      </Section>
      <Section title={<FormattedMessage id="ntf.timeline.preferences" />} flush collapsible>
        {data.preferences.length === 0 ? (
          <EmptyState title={<FormattedMessage id="ntf.timeline.noPreferences" />} />
        ) : (
          <TableScroll min={600}>
            <table className="table">
              <thead>
                <tr>
                  <th>
                    <FormattedMessage id="ntf.col.recipient" />
                  </th>
                  <th>
                    <FormattedMessage id="ntf.col.muted" />
                  </th>
                  <th>
                    <FormattedMessage id="ntf.col.consent" />
                  </th>
                </tr>
              </thead>
              <tbody>
                {data.preferences.map((p) => (
                  <tr key={p.recipient}>
                    <td>{recipientLabel(intl, recipients, p.recipient)}</td>
                    <td>
                      {p.muted.length ? (
                        p.muted.map((m) => labelOr(intl, `ntf.setting.${m}`, m)).join(', ')
                      ) : (
                        <span className="muted">
                          <FormattedMessage id="ntf.timeline.noneMuted" />
                        </span>
                      )}
                    </td>
                    <td>
                      <FormattedMessage
                        id={
                          p.engagementConsent === null
                            ? 'ntf.consent.unset'
                            : p.engagementConsent
                              ? 'ntf.consent.yes'
                              : 'ntf.consent.no'
                        }
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </TableScroll>
        )}
      </Section>
    </div>
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
        className="w-full gap-0 overflow-y-auto sm:max-w-2xl"
      >
        <div className="border-b px-6 py-5">
          <SheetTitle className="text-base">
            <FormattedMessage id="ntf.detail.title" />
          </SheetTitle>
          <p className="font-mono text-[12px] text-muted-foreground">{entry}</p>
        </div>
        <div className="p-6">
          <Loaded load={load} reload={reload}>
            {(d) => <EntryDetailView detail={d} />}
          </Loaded>
        </div>
      </SheetContent>
    </Sheet>
  );
}

const yesNo = (v: boolean | null) =>
  v === null ? 'ntf.detail.unknown' : v ? 'ntf.detail.yes' : 'ntf.detail.no';

/** Why a notification was created, the checks it passed, and what happened to it. */
export function EntryDetailView({ detail: d }: { detail: NotificationEntryDetail }) {
  const intl = useIntl();
  const stateOf = (dimension: string, to: string) => {
    const prefix: Record<string, string> = {
      lifecycle: 'ntf.lifecycle',
      delivery: 'ntf.delivery',
      read: 'ntf.read',
      action: 'ntf.action',
      engagement: 'ntf.stage',
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
  return (
    <div className="grid gap-5">
      <dl className="grid grid-cols-[minmax(0,11rem)_minmax(0,1fr)] gap-x-3 gap-y-1.5 text-sm">
        {row('ntf.col.kind', d.kind ? <FormattedMessage id={`ntf.kind.${d.kind}`} /> : '—')}
        {row(
          'ntf.col.scenario',
          d.scenario ? `${d.scenario} · ${labelOr(intl, `ntf.eng.${d.scenario}`, '')}` : '—',
        )}
        {row('ntf.detail.why', whyLabel(intl, d.why))}
        {row('ntf.detail.decision', intentLabel(intl, d.decision))}
        {row('ntf.col.reason', reasonLabel(intl, d.reason))}
        {row(
          'ntf.col.template',
          d.templateId ? `${templateName(intl, d.templateId)} @${d.templateVersion ?? 0}` : '—',
        )}
        {row('ntf.col.destination', destinationName(intl, d.destination))}
      </dl>
      <div>
        <h3 className="mb-2 text-sm font-semibold">
          <FormattedMessage id="ntf.detail.outcome" />
        </h3>
        <dl className="grid grid-cols-[minmax(0,11rem)_minmax(0,1fr)] gap-x-3 gap-y-1.5 text-sm">
          {row('ntf.detail.pushAttempted', <FormattedMessage id={yesNo(d.pushAttempted)} />)}
          {row('ntf.detail.providerAccepted', <FormattedMessage id={yesNo(d.providerAccepted)} />)}
          {row('ntf.detail.opened', <FormattedMessage id={yesNo(d.opened)} />)}
          {row(
            'ntf.detail.navigation',
            d.navigated ? <FormattedMessage id={`ntf.nav.${d.navigated}`} /> : '—',
          )}
          {row('ntf.detail.completed', <FormattedMessage id={yesNo(d.completed)} />)}
          {d.cancelledOrExpired &&
            row('ntf.detail.cancelled', reasonLabel(intl, d.cancelledOrExpired))}
        </dl>
        <p className="mt-2 text-[12px] text-muted-foreground">
          <FormattedMessage id="ntf.acceptedNotDelivered" />
        </p>
      </div>
      <div>
        <h3 className="mb-2 text-sm font-semibold">
          <FormattedMessage id="ntf.detail.checks" />
        </h3>
        {d.checks.length === 0 ? (
          <p className="text-sm text-muted-foreground">—</p>
        ) : (
          <table className="table">
            <thead>
              <tr>
                <th>
                  <FormattedMessage id="ntf.col.rule" />
                </th>
                <th>
                  <FormattedMessage id="ntf.col.result" />
                </th>
                <th>
                  <FormattedMessage id="ntf.col.note" />
                </th>
              </tr>
            </thead>
            <tbody>
              {d.checks.map((c, i) => (
                <tr key={`${c.rule}-${i}`}>
                  <td>{labelOr(intl, `ntf.rule.${c.rule}`, c.rule)}</td>
                  <td>
                    <Pill
                      tone={c.result === 'pass' ? 'ok' : c.result === 'fail' ? 'error' : 'muted'}
                    >
                      <FormattedMessage id={`ntf.check.${c.result}`} />
                    </Pill>
                  </td>
                  <td>{c.detail ? reasonLabel(intl, c.detail) : '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
      <div>
        <h3 className="mb-2 text-sm font-semibold">
          <FormattedMessage id="ntf.detail.transitions" />
        </h3>
        {d.timeline.length === 0 ? (
          <p className="text-sm text-muted-foreground">—</p>
        ) : (
          <ol className="grid gap-2 border-l pl-4">
            {d.timeline.map((t, i) => (
              <li key={i} className="text-sm">
                <span className="text-muted-foreground tabular-nums">{at(intl, t.at)}</span>{' '}
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
      </div>
      {d.errors.length > 0 && (
        <Notice tone="error" title={<FormattedMessage id="ntf.detail.errors" />}>
          <ul className="list-disc pl-4 text-[12px]">
            {d.errors.map((e) =>
              e === 'delivery_failed' || e === 'delivery_unknown' ? (
                <li key={e}>
                  <FormattedMessage id={`ntf.deliveryError.${e}`} />
                </li>
              ) : (
                <li key={e} className="font-mono">
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
