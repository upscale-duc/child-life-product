import { staffCan } from '@child-life/contracts';
import { useEffect, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import {
  ApiError,
  useApi,
  useLoad,
  type TicketDetail,
  type TicketList,
  type TicketRow,
  type TicketStatus,
} from '../api';
import { useRefreshBadges, useStaff } from '../context';
import { ago, gb, num } from '../format';
import {
  Button,
  Empty,
  Loaded,
  LockNote,
  Modal,
  Page,
  Panel,
  Pill,
  ReasonField,
  Segmented,
  SelectMenu,
  UsageBar,
  errorMessageId,
  reasonOk,
  type PillTone,
} from '../ui';

type Filter = 'open' | TicketStatus;

const statusTone: Record<TicketStatus, PillTone> = {
  new: 'high',
  claimed: 'info',
  waiting: 'wait',
  closed: 'muted',
};

/** A03 Hỗ trợ: the inbox, account metadata and the diagnostics the user agreed to send. */
export function SupportScreen() {
  const intl = useIntl();
  const [filter, setFilter] = useState<Filter>('open');
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
  const rows = load.status === 'ok' ? load.data.rows : [];
  const current = selected ?? rows[0]?.id ?? null;
  return (
    <Page
      title={<FormattedMessage id="support.title" />}
      subtitle={<FormattedMessage id="support.sub" />}
      actions={
        <input
          className="search"
          type="search"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder={intl.formatMessage({ id: 'support.search' })}
          aria-label={intl.formatMessage({ id: 'support.search' })}
        />
      }
    >
      <div className="cols cols--list">
        <Panel className="panel--flush">
          <Loaded load={load} reload={reload}>
            {(data) => (
              <TicketListView
                data={data}
                filter={filter}
                onFilter={(f) => {
                  setFilter(f);
                  setSelected(null);
                }}
                selected={current}
                onSelect={setSelected}
                now={new Date()}
              />
            )}
          </Loaded>
        </Panel>
        {current ? (
          <TicketPanel key={current} ticketId={current} onChanged={reload} />
        ) : (
          load.status === 'ok' && (
            <Panel>
              <Empty>
                <FormattedMessage id="support.pick" />
              </Empty>
            </Panel>
          )
        )}
      </div>
    </Page>
  );
}

type Kind = 'all' | 'help' | 'feedback';
const kindOf = (t: TicketRow): Exclude<Kind, 'all'> =>
  t.category === 'feedback' ? 'feedback' : 'help';

export function TicketListView({
  data,
  filter,
  onFilter,
  selected,
  onSelect,
  now,
}: {
  data: TicketList;
  filter: Filter;
  onFilter: (f: Filter) => void;
  selected: string | null;
  onSelect: (id: string) => void;
  now: Date;
}) {
  const intl = useIntl();
  // Hỗ trợ and Góp ý (P-145) share the queue; the type narrows the list on screen.
  const [kind, setKind] = useState<Kind>('all');
  const rows = kind === 'all' ? data.rows : data.rows.filter((t) => kindOf(t) === kind);
  return (
    <div>
      <div className="panel__pad stack">
        <Segmented
          label={intl.formatMessage({ id: 'support.filter' })}
          value={filter}
          onChange={onFilter}
          options={[
            {
              value: 'open',
              label: <FormattedMessage id="support.all" values={{ n: data.counts.open }} />,
            },
            {
              value: 'new',
              label: <FormattedMessage id="support.new" values={{ n: data.counts.new }} />,
            },
            {
              value: 'claimed',
              label: <FormattedMessage id="support.claimed" values={{ n: data.counts.claimed }} />,
            },
            {
              value: 'waiting',
              label: <FormattedMessage id="support.waiting" values={{ n: data.counts.waiting }} />,
            },
            { value: 'closed', label: <FormattedMessage id="support.closedTab" /> },
          ]}
        />
        <SelectMenu
          value={kind}
          onChange={setKind}
          label={intl.formatMessage({ id: 'support.kind' })}
          options={(['all', 'help', 'feedback'] as Kind[]).map((k) => ({
            value: k,
            label: intl.formatMessage({ id: `support.kind.${k}` }),
          }))}
          className="justify-self-start"
        />
      </div>
      {rows.length === 0 ? (
        <Empty>
          <FormattedMessage id="support.empty" />
        </Empty>
      ) : (
        <ul className="tickets">
          {rows.map((t) => (
            <li key={t.id}>
              <button
                type="button"
                className={`tickets__row ${t.id === selected ? 'tickets__row--on' : ''}`}
                onClick={() => onSelect(t.id)}
                aria-current={t.id === selected}
              >
                <span className="tickets__top">
                  <span className="tickets__title">{t.title}</span>
                  <StatusPill status={t.status} />
                </span>
                <span className="tickets__meta">
                  {t.ticket} · <TicketKind ticket={t} /> ·{' '}
                  {t.contactable ? t.email : <FormattedMessage id="support.noContactShort" />}
                </span>
                <span className="tickets__age">{ago(intl, t.createdAt, now)}</span>
              </button>
            </li>
          ))}
        </ul>
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

function StatusPill({ status }: { status: TicketStatus }) {
  return (
    <Pill tone={statusTone[status]}>
      <FormattedMessage id={`ticket.${status}`} />
    </Pill>
  );
}

function TicketPanel({ ticketId, onChanged }: { ticketId: string; onChanged: () => void }) {
  const [load, reload] = useLoad<TicketDetail>('staffTicket', { ticketId }, ticketId);
  return (
    <Panel>
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
    </Panel>
  );
}

type Dialog = { kind: 'wifi' } | { kind: 'close' } | null;

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
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const [dialog, setDialog] = useState<Dialog>(null);
  const canClaim = staffCan(staff.levels, 'support.claim');
  const canReply = staffCan(staff.levels, 'support.reply');
  const canClose = staffCan(staff.levels, 'support.close');
  const closed = ticket.status === 'closed';
  // P-145: without "Cho phép liên hệ lại" there is nobody to write to.
  const canAnswer = canReply && ticket.contactable;

  const run = async (fn: () => Promise<unknown>) => {
    setBusy(true);
    setError(null);
    try {
      await fn();
      setDialog(null);
      setText('');
      setReason('');
      refreshBadges();
      onChanged();
    } catch (e) {
      setError(e instanceof ApiError ? e : new ApiError('unknown', null));
    } finally {
      setBusy(false);
    }
  };
  const d = ticket.diagnostics;
  return (
    <div className="ticket">
      <div className="ticket__head">
        <div>
          <p className="muted">
            {ticket.ticket} · <TicketKind ticket={ticket} /> ·{' '}
            <FormattedMessage
              id="support.sent"
              values={{ ago: ago(intl, ticket.createdAt, now) }}
            />
          </p>
          <h2 className="ticket__title">{ticket.title}</h2>
          {ticket.claimedBy && (
            <p className="muted">
              <FormattedMessage id="support.claimedBy" values={{ name: ticket.claimedBy }} />
            </p>
          )}
        </div>
        {ticket.status === 'new' && canClaim && (
          <Button
            kind="primary"
            disabled={busy}
            onClick={() => run(() => api.call('staffClaimTicket', { ticketId: ticket.id }))}
          >
            <FormattedMessage id="support.claim" />
          </Button>
        )}
      </div>

      {!ticket.contactable && (
        <p className="note note--warn" role="status">
          <FormattedMessage id="support.noContact" />
        </p>
      )}

      <h3 className="label">
        <FormattedMessage id="support.userWrote" />
      </h3>
      <blockquote className="quote">{ticket.message}</blockquote>

      {ticket.hasScreenshot && <Screenshot ticketId={ticket.id} ticket={ticket.ticket} />}

      <div className="tiles">
        <div className="tile">
          <p className="tile__label">
            <FormattedMessage id="support.role" />
          </p>
          <p className="tile__value">
            {ticket.role ? <FormattedMessage id={`memberRole.${ticket.role}`} /> : '—'}
          </p>
        </div>
        <div className="tile">
          <p className="tile__label">
            <FormattedMessage id="support.family" />
          </p>
          <p className="tile__value">
            {ticket.family ? (
              <FormattedMessage
                id="family.shape"
                values={{ babies: ticket.family.babies, people: ticket.family.people }}
              />
            ) : (
              '—'
            )}
          </p>
        </div>
        <div className="tile">
          <p className="tile__label">
            <FormattedMessage id="support.storage" />
          </p>
          <p className="tile__value">
            {ticket.family
              ? `${gb(intl, ticket.family.usedBytes)} / ${gb(intl, ticket.family.quotaBytes, 0)}`
              : '—'}
          </p>
          {ticket.family && (
            <UsageBar
              ratio={ticket.family.usedBytes / Math.max(1, ticket.family.quotaBytes)}
              tone="ok"
            />
          )}
        </div>
      </div>

      <h3 className="label">
        <FormattedMessage id="support.diagnostics" />
      </h3>
      {d ? (
        <dl className="kv">
          <dt>
            <FormattedMessage id="diag.app" />
          </dt>
          <dd>
            {[
              d.platform === 'ios' ? 'iOS' : d.platform === 'android' ? 'Android' : null,
              d.appVersion,
              d.deviceModel,
            ]
              .filter(Boolean)
              .join(' · ')}
          </dd>
          <dt>
            <FormattedMessage id="diag.os" />
          </dt>
          <dd>{d.osVersion ?? '—'}</dd>
          <dt>
            <FormattedMessage id="diag.pending" />
          </dt>
          <dd>{num(intl, d.pendingUploads ?? 0)}</dd>
          <dt>
            <FormattedMessage id="diag.sync" />
          </dt>
          <dd>
            {d.lastSyncAt ? (
              <FormattedMessage id="diag.lastSync" values={{ ago: ago(intl, d.lastSyncAt, now) }} />
            ) : (
              '—'
            )}
          </dd>
        </dl>
      ) : (
        <p className="muted">
          <FormattedMessage id="support.noDiagnostics" />
        </p>
      )}

      {ticket.thread.length > 0 && (
        <>
          <h3 className="label">
            <FormattedMessage id="support.thread" />
          </h3>
          <ul className="thread">
            {ticket.thread.map((m, i) => (
              <li key={i}>
                <p className="muted">
                  {m.by} · {ago(intl, m.at, now)}
                </p>
                <p className="thread__text">{m.text}</p>
              </li>
            ))}
          </ul>
        </>
      )}

      {!closed && (canAnswer || canClose) && (
        <>
          <h3 className="label">
            <FormattedMessage id="support.allowed" />
          </h3>
          <div className="actions">
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
        </>
      )}

      <LockNote>
        <FormattedMessage id="support.lock" />
      </LockNote>

      {error && (
        <p className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}

      {!closed && canAnswer && (
        <form
          className="composer"
          onSubmit={(e) => {
            e.preventDefault();
            void run(() =>
              api.call('staffReplyTicket', {
                ticketId: ticket.id,
                text: text.trim(),
                macro: null,
                reason: reason.trim(),
              }),
            );
          }}
        >
          <textarea
            className="field__input"
            rows={3}
            maxLength={4000}
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder={intl.formatMessage({ id: 'support.replyPlaceholder' })}
            aria-label={intl.formatMessage({ id: 'support.replyPlaceholder' })}
          />
          <input
            className="field__input"
            value={reason}
            maxLength={500}
            onChange={(e) => setReason(e.target.value)}
            placeholder={intl.formatMessage({ id: 'reason.label' })}
            aria-label={intl.formatMessage({ id: 'reason.label' })}
          />
          <div className="composer__foot">
            <span className="muted">
              <FormattedMessage id="support.replyChannel" />
            </span>
            <Button
              kind="primary"
              type="submit"
              disabled={busy || !text.trim() || !reasonOk(reason)}
            >
              <FormattedMessage id="support.send" />
            </Button>
          </div>
        </form>
      )}

      {dialog && (
        <ReasonDialog
          title={
            <FormattedMessage
              id={dialog.kind === 'wifi' ? 'support.wifiTitle' : 'support.closeTitle'}
              values={{ id: ticket.ticket }}
            />
          }
          body={
            <FormattedMessage
              id={dialog.kind === 'wifi' ? 'support.wifiBody' : 'support.closeBody'}
            />
          }
          confirm={
            <FormattedMessage id={dialog.kind === 'wifi' ? 'support.wifiSend' : 'support.close'} />
          }
          busy={busy}
          error={error}
          onCancel={() => setDialog(null)}
          onConfirm={(r) =>
            run(() =>
              dialog.kind === 'wifi'
                ? api.call('staffReplyTicket', {
                    ticketId: ticket.id,
                    text: 'wifiGuide',
                    macro: 'wifiGuide',
                    reason: r,
                  })
                : api.call('staffCloseTicket', { ticketId: ticket.id, reason: r }),
            )
          }
        />
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
    <div className="stack">
      <h3 className="label">
        <FormattedMessage id="support.screenshot" />
      </h3>
      {src ? (
        <img
          className="ticket__shot"
          src={src}
          alt={intl.formatMessage({ id: 'support.screenshotAlt' }, { id: ticket })}
        />
      ) : (
        <div className="actions">
          <Button onClick={() => void show()} disabled={busy}>
            <FormattedMessage id="support.showScreenshot" />
          </Button>
        </div>
      )}
      {error && (
        <p className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
      <LockNote>
        <FormattedMessage id="support.screenshotLogged" />
      </LockNote>
    </div>
  );
}

/** A reason-only confirmation (support macro, close). */
export function ReasonDialog({
  title,
  body,
  confirm,
  busy,
  error,
  danger,
  onCancel,
  onConfirm,
}: {
  title: ReactNode;
  body: ReactNode;
  confirm: ReactNode;
  busy: boolean;
  error: ApiError | null;
  danger?: boolean;
  onCancel: () => void;
  onConfirm: (reason: string) => void;
}) {
  const [reason, setReason] = useState('');
  return (
    <Modal title={title} onClose={onCancel}>
      <p className="modal__sub">{body}</p>
      <ReasonField value={reason} onChange={setReason} required />
      {error && (
        <p className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
      <div className="modal__actions">
        <Button onClick={onCancel}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button
          kind={danger ? 'danger' : 'primary'}
          disabled={busy || !reasonOk(reason)}
          onClick={() => onConfirm(reason.trim())}
        >
          {confirm}
        </Button>
      </div>
    </Modal>
  );
}
