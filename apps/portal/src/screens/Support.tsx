import { staffCan } from '@child-life/contracts';
import { ChevronLeft, ChevronRight, ImageIcon, Inbox, Mail, X } from 'lucide-react';
import { useEffect, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Badge } from '@/components/ui/badge';
import { Button as UiButton } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Sheet, SheetContent, SheetTitle } from '@/components/ui/sheet';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Textarea } from '@/components/ui/textarea';
import {
  ApiError,
  useApi,
  useLoad,
  type TicketDetail,
  type TicketList,
  type TicketRow,
  type TicketStatus,
} from '../api';
import { EmptyState, Notice, SearchInput } from '../content-kit';
import { useRefreshBadges, useStaff } from '../context';
import { ago, gb, num } from '../format';
import {
  Button,
  Loaded,
  LockNote,
  ConfirmModal,
  Page,
  SelectMenu,
  UsageBar,
  errorMessageId,
} from '../ui';

type Filter = 'open' | TicketStatus;
type Kind = 'all' | 'help' | 'feedback';

/** Status badges (shadcn Badge): unclaimed stands out, closed fades. */
const statusClass: Record<TicketStatus, string> = {
  new: 'border-destructive/30 bg-destructive/10 text-destructive',
  claimed: 'border-primary/30 bg-primary/10 text-primary',
  waiting: 'border-warning/40 bg-warning/10 text-warning',
  closed: 'border-transparent bg-muted text-muted-foreground',
};

export const kindOf = (t: TicketRow): Exclude<Kind, 'all'> =>
  t.category === 'feedback' ? 'feedback' : 'help';

/**
 * A03 Hỗ trợ (portal UX 2026-10-21, shadcn): the queue as a table with status tabs, a type filter
 * and search; a ticket opens in a sheet (account metadata, the diagnostics the user agreed to send,
 * the thread and the allowed actions), with previous / next through the list.
 */
export function SupportScreen() {
  const intl = useIntl();
  const [filter, setFilter] = useState<Filter>('open');
  const [kind, setKind] = useState<Kind>('all');
  const [q, setQ] = useState('');
  const [query, setQuery] = useState('');
  const [selected, setSelected] = useState<string | null>(null);
  useEffect(() => {
    const t = setTimeout(() => setQuery(q.trim()), 300);
    return () => clearTimeout(t);
  }, [q]);
  const [load, reload] = useLoad<TicketList>(
    'staffTickets',
    { status: filter, ...(query ? { q: query } : {}) },
    `${filter}|${query}`,
  );
  const rows =
    load.status === 'ok' ? load.data.rows.filter((t) => kind === 'all' || kindOf(t) === kind) : [];
  const at = selected ? rows.findIndex((t) => t.id === selected) : -1;
  const step = (d: -1 | 1) => {
    const next = rows[at + d];
    return at >= 0 && next ? () => setSelected(next.id) : undefined;
  };
  return (
    <Page
      title={<FormattedMessage id="support.title" />}
      actions={
        <SearchInput
          value={q}
          onChange={setQ}
          placeholder={intl.formatMessage({ id: 'support.search' })}
        />
      }
    >
      <Card className="gap-0 overflow-hidden py-0">
        <Loaded load={load} reload={reload}>
          {(data) => (
            <TicketListView
              data={data}
              filter={filter}
              onFilter={(f) => {
                setFilter(f);
                setSelected(null);
              }}
              kind={kind}
              onKind={setKind}
              selected={selected}
              onSelect={setSelected}
              now={new Date()}
            />
          )}
        </Loaded>
      </Card>
      {selected && (
        <TicketSheet
          title={rows[at]?.ticket ?? intl.formatMessage({ id: 'support.title' })}
          onClose={() => setSelected(null)}
          onPrev={step(-1)}
          onNext={step(1)}
        >
          <TicketPanel key={selected} ticketId={selected} onChanged={reload} />
        </TicketSheet>
      )}
    </Page>
  );
}

const filters: Filter[] = ['open', 'new', 'claimed', 'waiting', 'closed'];

/** The status tabs, the type filter and the queue as a table. */
export function TicketListView({
  data,
  filter,
  onFilter,
  kind: kindProp,
  onKind,
  selected,
  onSelect,
  now,
}: {
  data: TicketList;
  filter: Filter;
  onFilter: (f: Filter) => void;
  /** Hỗ trợ and Góp ý (P-145) share the queue; the type narrows it on screen. */
  kind?: Kind;
  onKind?: (k: Kind) => void;
  selected: string | null;
  onSelect: (id: string) => void;
  now: Date;
}) {
  const intl = useIntl();
  const [ownKind, setOwnKind] = useState<Kind>('all');
  const kind = kindProp ?? ownKind;
  const setKind = onKind ?? setOwnKind;
  const rows = kind === 'all' ? data.rows : data.rows.filter((t) => kindOf(t) === kind);
  const label = (f: Filter) =>
    f === 'closed' ? (
      <FormattedMessage id="support.closedTab" />
    ) : (
      <FormattedMessage
        id={f === 'open' ? 'support.all' : `support.${f}`}
        values={{ n: data.counts[f] }}
      />
    );
  return (
    <div>
      <div className="flex flex-wrap items-center gap-2 border-b px-4 py-3">
        <Tabs value={filter} onValueChange={(v) => onFilter(v as Filter)}>
          <TabsList
            aria-label={intl.formatMessage({ id: 'support.filter' })}
            className="h-auto flex-wrap"
          >
            {filters.map((f) => (
              <TabsTrigger key={f} value={f} className="px-3">
                {label(f)}
              </TabsTrigger>
            ))}
          </TabsList>
        </Tabs>
        <SelectMenu
          value={kind}
          onChange={setKind}
          label={intl.formatMessage({ id: 'support.kind' })}
          options={(['all', 'help', 'feedback'] as Kind[]).map((k) => ({
            value: k,
            label: intl.formatMessage({ id: `support.kind.${k}` }),
          }))}
          className="ml-auto"
        />
      </div>
      {rows.length === 0 ? (
        <EmptyState icon={Inbox} title={<FormattedMessage id="support.empty" />} />
      ) : (
        <Table className="min-w-[640px]">
          <TableHeader>
            <TableRow className="hover:bg-transparent">
              <TableHead className="pl-4">
                <FormattedMessage id="support.col.request" />
              </TableHead>
              <TableHead>
                <FormattedMessage id="support.col.status" />
              </TableHead>
              <TableHead>
                <FormattedMessage id="support.col.handler" />
              </TableHead>
              <TableHead className="pr-4 text-right">
                <FormattedMessage id="support.col.sent" />
              </TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {rows.map((t) => (
              <TableRow
                key={t.id}
                data-state={t.id === selected ? 'selected' : undefined}
                className="cursor-pointer"
                onClick={() => onSelect(t.id)}
              >
                <TableCell className="max-w-0 min-w-72 pl-4 whitespace-normal">
                  <button
                    type="button"
                    className="block max-w-full truncate text-left font-medium hover:underline focus-visible:underline focus-visible:outline-none"
                    aria-current={t.id === selected}
                    onClick={(e) => {
                      e.stopPropagation();
                      onSelect(t.id);
                    }}
                  >
                    {t.title}
                  </button>
                  <span className="block truncate text-xs text-muted-foreground">
                    {t.ticket} · <TicketKind ticket={t} /> ·{' '}
                    {t.contactable ? t.email : <FormattedMessage id="support.noContactShort" />}
                  </span>
                </TableCell>
                <TableCell>
                  <StatusBadge status={t.status} />
                </TableCell>
                <TableCell className="text-muted-foreground">{t.claimedBy ?? '—'}</TableCell>
                <TableCell className="pr-4 text-right text-muted-foreground tabular-nums">
                  {ago(intl, t.createdAt, now)}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}
    </div>
  );
}

/** "Kỷ niệm & media", or "Góp ý · Báo lỗi" for feedback (P-145). */
function TicketKind({ ticket }: { ticket: TicketRow }) {
  return (
    <>
      <FormattedMessage id={`category.${ticket.category}`} />
      {ticket.feedbackType && (
        <>
          {' · '}
          <FormattedMessage id={`feedbackType.${ticket.feedbackType}`} />
        </>
      )}
    </>
  );
}

export function StatusBadge({ status }: { status: TicketStatus }) {
  return (
    <Badge variant="outline" className={statusClass[status]}>
      <FormattedMessage id={`ticket.${status}`} />
    </Badge>
  );
}

/** The ticket in a sheet from the right, with previous / next through the list. */
function TicketSheet({
  title,
  onClose,
  onPrev,
  onNext,
  children,
}: {
  title: string;
  onClose: () => void;
  onPrev?: () => void;
  onNext?: () => void;
  children: ReactNode;
}) {
  const intl = useIntl();
  const t = (id: string) => intl.formatMessage({ id });
  return (
    <Sheet open onOpenChange={(open) => !open && onClose()}>
      <SheetContent
        side="right"
        showCloseButton={false}
        aria-describedby={undefined}
        className="w-full gap-0 overflow-y-auto overscroll-contain p-0 sm:max-w-xl"
      >
        <SheetTitle className="sr-only">{title}</SheetTitle>
        <div className="sticky top-0 z-10 flex items-center gap-1 border-b bg-background/95 px-3 py-2 backdrop-blur">
          <UiButton
            variant="ghost"
            size="icon"
            className="size-8"
            onClick={onPrev}
            disabled={!onPrev}
            aria-label={t('support.prev')}
            title={t('support.prev')}
          >
            <ChevronLeft />
          </UiButton>
          <UiButton
            variant="ghost"
            size="icon"
            className="size-8"
            onClick={onNext}
            disabled={!onNext}
            aria-label={t('support.next')}
            title={t('support.next')}
          >
            <ChevronRight />
          </UiButton>
          <span className="ml-1 font-mono text-sm text-muted-foreground">{title}</span>
          <UiButton
            variant="ghost"
            size="icon"
            className="ml-auto size-8"
            onClick={onClose}
            aria-label={t('action.close')}
            title={t('action.close')}
          >
            <X />
          </UiButton>
        </div>
        {children}
      </SheetContent>
    </Sheet>
  );
}

function TicketPanel({ ticketId, onChanged }: { ticketId: string; onChanged: () => void }) {
  const [load, reload] = useLoad<TicketDetail>('staffTicket', { ticketId }, ticketId);
  return (
    <div className="p-5">
      <Loaded load={load} reload={reload}>
        {(t) => (
          <TicketDetailView
            ticket={t}
            now={new Date()}
            onChanged={() => {
              reload();
              onChanged();
            }}
          />
        )}
      </Loaded>
    </div>
  );
}

type Dialog = { kind: 'wifi' } | { kind: 'close' } | null;

function SectionLabel({ children }: { children: ReactNode }) {
  return (
    <h3 className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
      {children}
    </h3>
  );
}

function Fact({ label, children }: { label: ReactNode; children: ReactNode }) {
  return (
    <div className="grid min-w-0 gap-1 rounded-lg border bg-muted/40 px-3 py-2.5">
      <span className="text-xs text-muted-foreground">{label}</span>
      <span className="grid gap-1.5 text-sm font-medium">{children}</span>
    </div>
  );
}

/** One ticket: who wrote what, their account in numbers, diagnostics, the thread and actions. */
export function TicketDetailView({
  ticket,
  now,
  onChanged,
}: {
  ticket: TicketDetail;
  now: Date;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const staff = useStaff();
  const refreshBadges = useRefreshBadges();
  const [text, setText] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const [dialog, setDialog] = useState<Dialog>(null);
  const canClaim = staffCan(staff.levels, 'support.claim');
  const canReply = staffCan(staff.levels, 'support.reply');
  const canClose = staffCan(staff.levels, 'support.close');
  const closed = ticket.status === 'closed';
  // P-145: without "Cho phép liên hệ lại" there is nobody to write to.
  const canAnswer = canReply && ticket.contactable;
  const claim = ticket.status === 'new' && canClaim;

  const run = async (fn: () => Promise<unknown>) => {
    setBusy(true);
    setError(null);
    try {
      await fn();
      setDialog(null);
      setText('');
      refreshBadges();
      onChanged();
    } catch (e) {
      setError(e instanceof ApiError ? e : new ApiError('unknown', null));
    } finally {
      setBusy(false);
    }
  };
  const d = ticket.diagnostics;
  const diag: Array<[string, ReactNode]> = d
    ? [
        [
          'diag.app',
          [
            d.platform === 'ios' ? 'iOS' : d.platform === 'android' ? 'Android' : null,
            d.appVersion,
            d.deviceModel,
          ]
            .filter(Boolean)
            .join(' · ') || '—',
        ],
        ['diag.os', d.osVersion ?? '—'],
        ['diag.pending', num(intl, d.pendingUploads ?? 0)],
        [
          'diag.sync',
          d.lastSyncAt ? (
            <FormattedMessage id="diag.lastSync" values={{ ago: ago(intl, d.lastSyncAt, now) }} />
          ) : (
            '—'
          ),
        ],
      ]
    : [];
  return (
    <div className="grid gap-5">
      <header className="grid gap-2">
        <div className="flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
          <span>
            {ticket.ticket} · <TicketKind ticket={ticket} /> ·{' '}
            <FormattedMessage
              id="support.sent"
              values={{ ago: ago(intl, ticket.createdAt, now) }}
            />
          </span>
          <StatusBadge status={ticket.status} />
        </div>
        <h2 className="text-lg leading-7 font-semibold tracking-tight">{ticket.title}</h2>
        {ticket.claimedBy && (
          <p className="text-sm text-muted-foreground">
            <FormattedMessage id="support.claimedBy" values={{ name: ticket.claimedBy }} />
          </p>
        )}
        {!closed && (claim || canAnswer || canClose) && (
          <div className="flex flex-wrap gap-2 pt-1">
            {claim && (
              <Button
                kind="primary"
                disabled={busy}
                onClick={() => run(() => api.call('staffClaimTicket', { ticketId: ticket.id }))}
              >
                <FormattedMessage id="support.claim" />
              </Button>
            )}
            {canAnswer && (
              <Button onClick={() => setDialog({ kind: 'wifi' })} disabled={busy}>
                <FormattedMessage id="support.wifiGuide" />
              </Button>
            )}
            {canClose && (
              <Button onClick={() => setDialog({ kind: 'close' })} disabled={busy}>
                <FormattedMessage id="support.close" />
              </Button>
            )}
          </div>
        )}
      </header>

      {!ticket.contactable && (
        <Notice tone="warn">
          <FormattedMessage id="support.noContact" />
        </Notice>
      )}
      {error && (
        <p className="text-sm text-destructive" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}

      <section className="grid gap-2">
        <SectionLabel>
          <FormattedMessage id="support.userWrote" />
        </SectionLabel>
        <Card className="gap-0 bg-muted/40 py-0 shadow-none">
          <CardContent className="px-4 py-3 text-sm whitespace-pre-wrap">
            {ticket.message}
          </CardContent>
        </Card>
      </section>

      {ticket.hasScreenshot && <Screenshot ticketId={ticket.id} ticket={ticket.ticket} />}

      <section className="grid gap-2">
        <SectionLabel>
          <FormattedMessage id="support.account" />
        </SectionLabel>
        <div className="grid gap-2 sm:grid-cols-3">
          <Fact label={<FormattedMessage id="support.role" />}>
            {ticket.role ? <FormattedMessage id={`memberRole.${ticket.role}`} /> : '—'}
          </Fact>
          <Fact label={<FormattedMessage id="support.family" />}>
            {ticket.family ? (
              <FormattedMessage
                id="family.shape"
                values={{ babies: ticket.family.babies, people: ticket.family.people }}
              />
            ) : (
              '—'
            )}
          </Fact>
          <Fact label={<FormattedMessage id="support.storage" />}>
            <span>
              {ticket.family
                ? `${gb(intl, ticket.family.usedBytes)} / ${gb(intl, ticket.family.quotaBytes, 0)}`
                : '—'}
            </span>
            {ticket.family && (
              <UsageBar
                ratio={ticket.family.usedBytes / Math.max(1, ticket.family.quotaBytes)}
                tone="ok"
              />
            )}
          </Fact>
        </div>
      </section>

      <section className="grid gap-2">
        <SectionLabel>
          <FormattedMessage id="support.diagnostics" />
        </SectionLabel>
        {d ? (
          <dl className="grid grid-cols-[auto_minmax(0,1fr)] gap-x-6 gap-y-1.5 text-sm">
            {diag.map(([id, value]) => (
              <div key={id} className="contents">
                <dt className="text-muted-foreground">
                  <FormattedMessage id={id} />
                </dt>
                <dd>{value}</dd>
              </div>
            ))}
          </dl>
        ) : (
          <p className="text-sm text-muted-foreground">
            <FormattedMessage id="support.noDiagnostics" />
          </p>
        )}
      </section>

      {ticket.thread.length > 0 && (
        <section className="grid gap-2">
          <SectionLabel>
            <FormattedMessage id="support.thread" />
          </SectionLabel>
          <ul className="grid gap-2">
            {ticket.thread.map((m, i) => (
              <li key={i} className="rounded-lg border px-3 py-2">
                <p className="text-xs text-muted-foreground">
                  {m.by} · {ago(intl, m.at, now)}
                </p>
                <p className="text-sm whitespace-pre-wrap">{m.text}</p>
              </li>
            ))}
          </ul>
        </section>
      )}

      {!closed && canAnswer && (
        <form
          className="grid gap-2 rounded-lg border p-3"
          onSubmit={(e) => {
            e.preventDefault();
            void run(() =>
              api.call('staffReplyTicket', {
                ticketId: ticket.id,
                text: text.trim(),
                macro: null,
              }),
            );
          }}
        >
          <Textarea
            rows={3}
            maxLength={4000}
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder={intl.formatMessage({ id: 'support.replyPlaceholder' })}
            aria-label={intl.formatMessage({ id: 'support.replyPlaceholder' })}
          />
          <div className="flex flex-wrap items-center justify-between gap-2">
            <span className="flex items-center gap-1.5 text-xs text-muted-foreground">
              <Mail className="size-3.5" aria-hidden="true" />
              <FormattedMessage id="support.replyChannel" />
            </span>
            <Button kind="primary" type="submit" disabled={busy || !text.trim()}>
              <FormattedMessage id="support.send" />
            </Button>
          </div>
        </form>
      )}

      <LockNote>
        <FormattedMessage id="support.lock" />
      </LockNote>

      {dialog && (
        // No reason (D-090): the server writes the audit line itself.
        <ConfirmModal
          title={
            <FormattedMessage
              id={dialog.kind === 'wifi' ? 'support.wifiTitle' : 'support.closeTitle'}
              values={{ id: ticket.ticket }}
            />
          }
          confirm={
            <FormattedMessage id={dialog.kind === 'wifi' ? 'support.wifiSend' : 'support.close'} />
          }
          busy={busy}
          error={error}
          onCancel={() => setDialog(null)}
          onConfirm={() =>
            void run(() =>
              dialog.kind === 'wifi'
                ? api.call('staffReplyTicket', {
                    ticketId: ticket.id,
                    text: 'wifiGuide',
                    macro: 'wifiGuide',
                  })
                : api.call('staffCloseTicket', { ticketId: ticket.id }),
            )
          }
        >
          <FormattedMessage
            id={dialog.kind === 'wifi' ? 'support.wifiBody' : 'support.closeBody'}
          />
        </ConfirmModal>
      )}
    </div>
  );
}

/** P-145: the Góp ý screenshot, loaded on request (each view is logged on the server). */
function Screenshot({ ticketId, ticket }: { ticketId: string; ticket: string }) {
  const intl = useIntl();
  const api = useApi();
  const [src, setSrc] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const show = async () => {
    setBusy(true);
    setError(null);
    try {
      const r = await api.call<{ dataUrl: string }>('staffTicketScreenshot', { ticketId });
      setSrc(r.dataUrl);
    } catch (e) {
      setError(e instanceof ApiError ? e : new ApiError('unknown', null));
    } finally {
      setBusy(false);
    }
  };
  return (
    <section className="grid gap-2">
      <SectionLabel>
        <FormattedMessage id="support.screenshot" />
      </SectionLabel>
      {src ? (
        <img
          className="max-h-[28rem] w-auto max-w-full justify-self-start rounded-lg border"
          src={src}
          alt={intl.formatMessage({ id: 'support.screenshotAlt' }, { id: ticket })}
        />
      ) : (
        <div>
          <Button onClick={() => void show()} disabled={busy}>
            <ImageIcon />
            <FormattedMessage id="support.showScreenshot" />
          </Button>
        </div>
      )}
      {error && (
        <p className="text-sm text-destructive" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
      <LockNote>
        <FormattedMessage id="support.screenshotLogged" />
      </LockNote>
    </section>
  );
}
