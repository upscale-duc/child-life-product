import { staffCan } from '@child-life/contracts';
import { useEffect, useId, useState } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import {
  ApiError,
  useApi,
  useLoad,
  type FamilyDetail,
  type FamilyList,
  type FamilyRow,
} from '../api';
import { routePaths, subPath, useStaff } from '../context';
import { ZONE, ago, gb, pct } from '../format';
import {
  Button,
  Empty,
  errorMessageId,
  Kpi,
  Loaded,
  LockNote,
  Modal,
  Page,
  Panel,
  Pill,
  ConfirmModal,
  Segmented,
  SelectMenu,
  TableScroll,
  UsageBar,
} from '../ui';

/**
 * Gia đình (Figma A15–A17; P-136). A family is its anonymous code: no family or baby name, no
 * age, no custom relationship label, no device name and never a full email. Opening a detail is
 * logged. "Tạm khoá" and "Gửi lại lời mời" are not built (owner, 2026-10-11; P-136).
 */

type Activity = 'all' | 'active' | 'low';
type Platform = 'all' | 'ios' | 'android' | 'both';
type Storage = 'all' | 'over80' | 'expanded';

const asApiError = (e: unknown) => (e instanceof ApiError ? e : new ApiError('unknown', null));

function storageTone(used: number, quota: number): 'ok' | 'warn' | 'error' {
  const r = quota ? used / quota : 0;
  return r >= 0.95 ? 'error' : r >= 0.8 ? 'warn' : 'ok';
}

function platformText(intl: IntlShape, platforms: string[]): string {
  if (!platforms.length) return '—';
  return platforms.map((p) => intl.formatMessage({ id: `platform.${p}` })).join(' · ');
}

function date(intl: IntlShape, iso: string | null): string {
  return iso
    ? intl.formatDate(iso, { day: '2-digit', month: '2-digit', year: 'numeric', timeZone: ZONE })
    : '—';
}

export function FamiliesScreen() {
  const [path, setPath] = useState(() => subPath('families', window.location.pathname));
  useEffect(() => {
    const onPop = () => setPath(subPath('families', window.location.pathname));
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, []);
  const open = (code: string | null) => {
    window.history.pushState({}, '', code ? `${routePaths.families}/${code}` : routePaths.families);
    setPath(code ? [code] : []);
    window.scrollTo(0, 0);
  };
  return path[0] ? (
    <FamilyScreen code={path[0]} onBack={() => open(null)} />
  ) : (
    <FamilyListScreen onOpen={open} />
  );
}

function FamilyListScreen({ onOpen }: { onOpen: (code: string) => void }) {
  const intl = useIntl();
  const [activity, setActivity] = useState<Activity>('all');
  const [platform, setPlatform] = useState<Platform>('all');
  const [storage, setStorage] = useState<Storage>('all');
  const [q, setQ] = useState('');
  const [query, setQuery] = useState('');
  // Page cursors: the stack of "after" ids that led to this page.
  const [pages, setPages] = useState<string[]>([]);
  useEffect(() => {
    const t = setTimeout(() => setQuery(q.trim()), 400);
    return () => clearTimeout(t);
  }, [q]);
  useEffect(() => setPages([]), [activity, platform, storage, query]);
  const after = pages[pages.length - 1];
  const req = {
    activity,
    platform,
    storage,
    ...(query ? { q: query } : {}),
    ...(after ? { after } : {}),
  };
  const [load, reload] = useLoad<FamilyList>(
    'staffFamilies',
    req,
    `${activity}|${platform}|${storage}|${query}|${after ?? ''}`,
  );
  return (
    <Page
      title={<FormattedMessage id="families.title" />}
      info={<FormattedMessage id="families.sub" />}
    >
      <Loaded load={load} reload={reload}>
        {(data) => (
          <FamilyListView
            data={data}
            now={new Date()}
            activity={activity}
            onActivity={setActivity}
            platform={platform}
            onPlatform={setPlatform}
            storage={storage}
            onStorage={setStorage}
            q={q}
            onQ={setQ}
            page={pages.length}
            onNext={data.next ? () => setPages([...pages, data.next!]) : undefined}
            onPrev={pages.length ? () => setPages(pages.slice(0, -1)) : undefined}
            onOpen={onOpen}
            searchLabel={intl.formatMessage({ id: 'families.search' })}
          />
        )}
      </Loaded>
    </Page>
  );
}

export function FamilyListView({
  data,
  now,
  activity,
  onActivity,
  platform,
  onPlatform,
  storage,
  onStorage,
  q,
  onQ,
  page,
  onNext,
  onPrev,
  onOpen,
  searchLabel,
}: {
  data: FamilyList;
  now: Date;
  activity: Activity;
  onActivity: (a: Activity) => void;
  platform: Platform;
  onPlatform: (p: Platform) => void;
  storage: Storage;
  onStorage: (s: Storage) => void;
  q: string;
  onQ: (q: string) => void;
  page: number;
  onNext?: (() => void) | undefined;
  onPrev?: (() => void) | undefined;
  onOpen: (code: string) => void;
  searchLabel: string;
}) {
  const intl = useIntl();
  const k = data.kpis;
  return (
    <div className="stack">
      <div className="kpis">
        <Kpi
          label={<FormattedMessage id="families.kpi.total" />}
          value={intl.formatNumber(k.total)}
        />
        <Kpi
          label={<FormattedMessage id="families.kpi.active" />}
          value={intl.formatNumber(k.active)}
          foot={pct(intl, k.total ? k.active / k.total : null)}
        />
        <Kpi
          label={<FormattedMessage id="families.kpi.multi" />}
          value={pct(intl, k.multiCarerRate)}
          foot={<FormattedMessage id="families.kpi.multiFoot" />}
        />
        <Kpi
          label={<FormattedMessage id="families.kpi.nearFull" />}
          value={intl.formatNumber(k.nearFull)}
          foot={<FormattedMessage id="families.kpi.nearFullFoot" />}
          tone="warn"
        />
      </div>
      <Panel className="panel--flush">
        <div className="panel__pad toolbar">
          <input
            className="search"
            type="search"
            value={q}
            onChange={(e) => onQ(e.target.value)}
            placeholder={searchLabel}
            aria-label={searchLabel}
          />
          <Segmented
            label={intl.formatMessage({ id: 'families.title' })}
            value={activity}
            onChange={onActivity}
            options={[
              {
                value: 'all' as Activity,
                label: <FormattedMessage id="families.tab.all" values={{ n: k.total }} />,
              },
              {
                value: 'active' as Activity,
                label: <FormattedMessage id="families.tab.active" values={{ n: k.active }} />,
              },
              {
                value: 'low' as Activity,
                label: <FormattedMessage id="families.tab.low" values={{ n: k.low }} />,
              },
            ]}
          />
          <div className="qa-filters">
            <SelectMenu
              value={platform}
              onChange={onPlatform}
              label={intl.formatMessage({ id: 'families.filter.platform' })}
              options={(['all', 'ios', 'android', 'both'] as Platform[]).map((p) => ({
                value: p,
                label: intl.formatMessage({ id: `families.platform.${p}` }),
              }))}
            />
            <SelectMenu
              value={storage}
              onChange={onStorage}
              label={intl.formatMessage({ id: 'families.filter.storage' })}
              options={(['all', 'over80', 'expanded'] as Storage[]).map((s) => ({
                value: s,
                label: intl.formatMessage({ id: `families.storage.${s}` }),
              }))}
            />
          </div>
        </div>
        {data.rows.length === 0 ? (
          <Empty>
            <FormattedMessage id={q.trim() ? 'families.noMatch' : 'families.empty'} />
          </Empty>
        ) : (
          <TableScroll min={880}>
            <table className="table">
              <thead>
                <tr>
                  <th>
                    <FormattedMessage id="families.col.family" />
                  </th>
                  <th>
                    <FormattedMessage id="families.col.members" />
                  </th>
                  <th>
                    <FormattedMessage id="families.col.babies" />
                  </th>
                  <th>
                    <FormattedMessage id="families.col.storage" />
                  </th>
                  <th>
                    <FormattedMessage id="families.col.platform" />
                  </th>
                  <th>
                    <FormattedMessage id="families.col.last" />
                  </th>
                  <th>
                    <FormattedMessage id="families.col.status" />
                  </th>
                </tr>
              </thead>
              <tbody>
                {data.rows.map((r) => (
                  <FamilyTableRow key={r.code} row={r} now={now} onOpen={onOpen} />
                ))}
              </tbody>
            </table>
          </TableScroll>
        )}
        <div className="panel__pad toolbar">
          <span className="muted">
            <FormattedMessage id="families.page" values={{ n: page + 1, total: data.kpis.total }} />
          </span>
          <div className="actions">
            <Button onClick={onPrev} disabled={!onPrev}>
              <FormattedMessage id="families.prev" />
            </Button>
            <Button onClick={onNext} disabled={!onNext}>
              <FormattedMessage id="families.next" />
            </Button>
          </div>
        </div>
      </Panel>
    </div>
  );
}

function FamilyTableRow({
  row: r,
  now,
  onOpen,
}: {
  row: FamilyRow;
  now: Date;
  onOpen: (c: string) => void;
}) {
  const intl = useIntl();
  return (
    <tr className="qa-table__row" onClick={() => onOpen(r.code)}>
      <td>
        <button
          type="button"
          className="qa-title-btn mono"
          onClick={(e) => {
            e.stopPropagation();
            onOpen(r.code);
          }}
        >
          {r.code}
        </button>
        <br />
        <span className="muted">
          <FormattedMessage id="families.ownerLine" values={{ email: r.owner }} />
        </span>
      </td>
      <td>
        <FormattedMessage id="families.people" values={{ n: r.members }} />
        <br />
        <span className="muted">
          {r.pendingInvites > 0 ? (
            <FormattedMessage id="families.pendingInvites" values={{ n: r.pendingInvites }} />
          ) : (
            <FormattedMessage id="families.carers" values={{ n: r.carers }} />
          )}
        </span>
      </td>
      <td>{intl.formatNumber(r.babies)}</td>
      <td className="cell-progress">
        <UsageBar
          ratio={r.quotaBytes ? r.usedBytes / r.quotaBytes : 0}
          tone={storageTone(r.usedBytes, r.quotaBytes)}
        />
        <span className="muted nowrap">
          {gb(intl, r.usedBytes)} / {gb(intl, r.quotaBytes, 0)}
        </span>
      </td>
      <td className="nowrap">{platformText(intl, r.platforms)}</td>
      <td className="nowrap">{r.lastActiveAt ? ago(intl, r.lastActiveAt, now) : '—'}</td>
      <td>
        <Pill tone={r.activity === 'active' ? 'ok' : 'wait'}>
          <FormattedMessage id={`families.activity.${r.activity}`} />
        </Pill>
      </td>
    </tr>
  );
}

function FamilyScreen({ code, onBack }: { code: string; onBack: () => void }) {
  const staff = useStaff();
  const [load, reload] = useLoad<FamilyDetail>('staffFamily', { code }, code);
  const [dialog, setDialog] = useState<'transfer' | 'cancel' | null>(null);
  const canTransfer = staffCan(staff.levels, 'families.transfer');
  return (
    <Page
      title={code}
      // A detail page: back to the list and the family's code on the row on top.
      lead={
        <>
          <button type="button" className="linkbtn" onClick={onBack}>
            <FormattedMessage id="families.back" />
          </button>
          <span className="mono font-semibold" aria-hidden="true">
            {code}
          </span>
        </>
      }
      actions={
        canTransfer &&
        load.status === 'ok' &&
        !load.data.transfer && (
          <Button onClick={() => setDialog('transfer')}>
            <FormattedMessage id="families.transfer" />
          </Button>
        )
      }
    >
      <Loaded load={load} reload={reload}>
        {(d) => (
          <>
            <FamilyDetailView
              data={d}
              now={new Date()}
              canTransfer={canTransfer}
              onCancelTransfer={() => setDialog('cancel')}
            />
            {dialog === 'transfer' && (
              <TransferDialog data={d} onClose={() => setDialog(null)} onDone={reload} />
            )}
            {dialog === 'cancel' && d.transfer && (
              <CancelTransferDialog
                transferId={d.transfer.id}
                onClose={() => setDialog(null)}
                onDone={reload}
              />
            )}
          </>
        )}
      </Loaded>
    </Page>
  );
}

function roleLine(
  intl: IntlShape,
  member: FamilyDetail['members'][number],
  babies: number,
): string {
  if (member.isOwner) return intl.formatMessage({ id: 'familyRole.owner' });
  const roles = [...new Set(member.roles.map((r) => r.role))];
  if (roles.length === 1 && member.roles.length === babies) {
    return intl.formatMessage({ id: `familyRole.${roles[0]}` });
  }
  return member.roles
    .map((r) =>
      intl.formatMessage(
        { id: 'families.rolePerBaby' },
        { role: intl.formatMessage({ id: `familyRole.${r.role}` }), n: r.baby },
      ),
    )
    .join(' · ');
}

export function FamilyDetailView({
  data: d,
  now,
  canTransfer,
  onCancelTransfer,
}: {
  data: FamilyDetail;
  now: Date;
  canTransfer: boolean;
  onCancelTransfer: () => void;
}) {
  const intl = useIntl();
  const totals = d.babies.reduce(
    (t, b) => ({
      records: t.records + b.records7d,
      media: t.media + b.media7d,
      stories: t.stories + b.stories,
    }),
    { records: 0, media: 0, stories: 0 },
  );
  return (
    <div className="stack">
      <p className="muted">
        <FormattedMessage
          id="families.detailSub"
          values={{
            date: date(intl, d.createdAt),
            platforms: platformText(intl, d.platforms),
            plan: gb(intl, d.quotaBytes, 0),
          }}
        />
      </p>
      {d.transfer && (
        <div className="note note--warn toolbar">
          <span>
            <FormattedMessage
              id="families.transferPending"
              values={{
                to: d.transfer.to,
                by: d.transfer.openedBy,
                until: d.transfer.expiresAt
                  ? intl.formatDate(d.transfer.expiresAt, {
                      hour: '2-digit',
                      minute: '2-digit',
                      day: '2-digit',
                      month: '2-digit',
                      timeZone: ZONE,
                    })
                  : '—',
              }}
            />
          </span>
          {canTransfer && (
            <Button kind="ghost" onClick={onCancelTransfer}>
              <FormattedMessage id="families.transferCancel" />
            </Button>
          )}
        </div>
      )}
      <div className="cols cols--2-1">
        <div className="stack">
          <Panel
            className="panel--flush"
            title={<FormattedMessage id="families.members" />}
            note={<FormattedMessage id="families.people" values={{ n: d.members.length }} />}
          >
            <TableScroll min={620}>
              <table className="table">
                <thead>
                  <tr>
                    <th>
                      <FormattedMessage id="families.col.member" />
                    </th>
                    <th>
                      <FormattedMessage id="families.col.role" />
                    </th>
                    <th>
                      <FormattedMessage id="families.col.status" />
                    </th>
                    <th>
                      <FormattedMessage id="families.col.last" />
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {d.members.map((m) => (
                    <tr key={m.uid}>
                      <td>
                        <strong>{m.email}</strong>
                        <br />
                        <span className="muted">
                          <FormattedMessage id={`relation.${m.relation}`} />
                        </span>
                      </td>
                      <td>
                        <Pill tone={m.isOwner ? 'ok' : 'muted'}>
                          {roleLine(intl, m, d.babies.length)}
                        </Pill>
                      </td>
                      <td>
                        <Pill tone="ok">
                          <FormattedMessage id="families.memberActive" />
                        </Pill>
                      </td>
                      <td className="nowrap">
                        {m.lastActiveAt ? ago(intl, m.lastActiveAt, now) : '—'}
                        <br />
                        <span className="muted">
                          {[
                            m.model ??
                              (m.platform
                                ? intl.formatMessage({ id: `platform.${m.platform}` })
                                : null),
                            m.appVersion,
                          ]
                            .filter(Boolean)
                            .join(' · ') || '—'}
                        </span>
                      </td>
                    </tr>
                  ))}
                  {d.invites.map((i, n) => (
                    <tr key={`invite-${n}`}>
                      <td>
                        <span className="muted">
                          <FormattedMessage id="families.invitee" />
                        </span>
                        <br />
                        <span className="muted">
                          <FormattedMessage id={`relation.${i.relation}`} />
                        </span>
                      </td>
                      <td>
                        <Pill tone="muted">
                          <FormattedMessage id={`familyRole.${i.role}`} />
                        </Pill>
                      </td>
                      <td>
                        <Pill tone={i.state === 'pending' ? 'info' : 'wait'}>
                          <FormattedMessage id={`families.invite.${i.state}`} />
                        </Pill>
                      </td>
                      <td className="nowrap muted">
                        {i.createdAt ? (
                          <FormattedMessage
                            id="families.inviteSent"
                            values={{ ago: ago(intl, i.createdAt, now) }}
                          />
                        ) : (
                          '—'
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </TableScroll>
          </Panel>
          <Panel
            title={<FormattedMessage id="families.babies" />}
            note={<FormattedMessage id="families.countsOnly" />}
          >
            <div className="tiles">
              {d.babies.map((b) => (
                <div key={b.ordinal} className="tile">
                  <p className="tile__value">
                    <FormattedMessage id="families.babyOrdinal" values={{ n: b.ordinal }} />
                  </p>
                  <p className="tile__label">
                    <FormattedMessage id="families.babyHidden" />
                  </p>
                  <p className="tile__label">
                    <FormattedMessage
                      id="families.babyCounts"
                      values={{ records: b.records7d, media: b.media7d, stories: b.stories }}
                    />
                  </p>
                </div>
              ))}
            </div>
            <div className="tiles">
              <Tile label="families.records7d" value={intl.formatNumber(totals.records)} />
              <Tile label="families.media7d" value={intl.formatNumber(totals.media)} />
              <Tile label="families.stories" value={intl.formatNumber(totals.stories)} />
            </div>
          </Panel>
        </div>
        <div className="stack">
          <Panel title={<FormattedMessage id="families.info" />}>
            <dl className="kv">
              <dt>
                <FormattedMessage id="families.code" />
              </dt>
              <dd className="mono">{d.code}</dd>
              <dt>
                <FormattedMessage id="families.owner" />
              </dt>
              <dd>{d.owner}</dd>
              <dt>
                <FormattedMessage id="families.language" />
              </dt>
              <dd>
                {d.language ? intl.formatMessage({ id: `families.lang.${d.language}` }) : '—'}
              </dd>
              <dt>
                <FormattedMessage id="families.plan" />
              </dt>
              <dd>
                <FormattedMessage
                  id={d.expanded ? 'families.planExpanded' : 'families.planBase'}
                  values={{ size: gb(intl, d.quotaBytes, 0) }}
                />
              </dd>
              <dt>
                <FormattedMessage id="families.col.storage" />
              </dt>
              <dd>
                <UsageBar
                  ratio={d.quotaBytes ? d.usedBytes / d.quotaBytes : 0}
                  tone={storageTone(d.usedBytes, d.quotaBytes)}
                />
                <span className="muted">
                  {gb(intl, d.usedBytes)} / {gb(intl, d.quotaBytes, 0)}
                </span>
              </dd>
              <dt>
                <FormattedMessage id="families.col.last" />
              </dt>
              <dd>{d.lastActiveAt ? ago(intl, d.lastActiveAt, now) : '—'}</dd>
            </dl>
          </Panel>
          <Panel title={<FormattedMessage id="families.tickets" />}>
            {d.tickets.length === 0 ? (
              <p className="muted">
                <FormattedMessage id="families.noTickets" />
              </p>
            ) : (
              <ul className="thread">
                {d.tickets.map((t) => (
                  <li key={t.id}>
                    <p>{t.title}</p>
                    <p className="muted">
                      {t.ticket} · {t.createdAt ? ago(intl, t.createdAt, now) : '—'} ·{' '}
                      <FormattedMessage id={`ticket.${t.status}`} />
                    </p>
                  </li>
                ))}
              </ul>
            )}
          </Panel>
          <LockNote>
            <FormattedMessage id="families.lock" />
          </LockNote>
        </div>
      </div>
    </div>
  );
}

function Tile({ label, value }: { label: string; value: string }) {
  return (
    <div className="tile">
      <p className="tile__label">
        <FormattedMessage id={label} />
      </p>
      <p className="tile__value">{value}</p>
    </div>
  );
}

/** A17 "Chuyển chủ gia đình": a request the current owner must confirm in the app. */
export function TransferDialog({
  data: d,
  onClose,
  onDone,
}: {
  data: FamilyDetail;
  onClose: () => void;
  onDone: () => void;
}) {
  const api = useApi();
  const intl = useIntl();
  const ticketId = useId();
  const candidates = d.members.filter((m) => !m.isOwner);
  const [to, setTo] = useState<string | null>(candidates.find((m) => m.eligible)?.uid ?? null);
  const [ticket, setTicket] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const ticketOk = !ticket.trim() || /^CL-\d{3,6}$/i.test(ticket.trim());
  return (
    <Modal wide title={<FormattedMessage id="families.transfer" />} onClose={onClose}>
      <p className="modal__sub">
        <FormattedMessage id="families.transferSub" values={{ code: d.code, owner: d.owner }} />
      </p>
      <form
        className="stack"
        onSubmit={(e) => {
          e.preventDefault();
          if (!to) return;
          setBusy(true);
          setError(null);
          api
            .call('staffOpenTransfer', {
              code: d.code,
              toUid: to,
              ticket: ticket.trim() ? ticket.trim().toUpperCase() : null,
            })
            .then(() => {
              onClose();
              onDone();
            })
            .catch((err: unknown) => setError(asApiError(err)))
            .finally(() => setBusy(false));
        }}
      >
        <div className="field">
          <span className="field__label">
            <FormattedMessage id="families.newOwner" />
          </span>
          <div
            className="role-grid"
            role="radiogroup"
            aria-label={intl.formatMessage({ id: 'families.newOwner' })}
          >
            {candidates.map((m) => (
              <button
                key={m.uid}
                type="button"
                role="radio"
                aria-checked={to === m.uid}
                disabled={!m.eligible}
                className={`role-card ${to === m.uid ? 'role-card--on' : ''}`}
                onClick={() => setTo(m.uid)}
              >
                <strong>
                  {m.email} · <FormattedMessage id={`relation.${m.relation}`} />
                </strong>
                <span className="muted">
                  {m.eligible ? (
                    roleLine(intl, m, d.babies.length)
                  ) : (
                    <FormattedMessage id="families.notEligible" />
                  )}
                </span>
              </button>
            ))}
          </div>
          {!candidates.some((m) => m.eligible) && (
            <p className="note note--warn">
              <FormattedMessage id="families.noCandidate" />
            </p>
          )}
        </div>
        <div className="field">
          <label className="field__label" htmlFor={ticketId}>
            <FormattedMessage id="families.ticket" />
          </label>
          <input
            id={ticketId}
            className="field__input"
            value={ticket}
            maxLength={9}
            placeholder="CL-1046"
            onChange={(e) => setTicket(e.target.value)}
          />
        </div>
        <ol className="steps">
          {[1, 2, 3].map((n) => (
            <li key={n} className="steps__item">
              <span aria-hidden="true">{n}</span>
              <FormattedMessage id={`families.transferStep${n}`} />
            </li>
          ))}
        </ol>
        {error && (
          <p className="error" role="alert">
            <FormattedMessage id={errorMessageId(error)} />
          </p>
        )}
        <div className="modal__actions">
          <Button onClick={onClose}>
            <FormattedMessage id="action.cancel" />
          </Button>
          <Button kind="primary" type="submit" disabled={busy || !to || !ticketOk}>
            <FormattedMessage id="families.transferSend" />
          </Button>
        </div>
      </form>
    </Modal>
  );
}

function CancelTransferDialog({
  transferId,
  onClose,
  onDone,
}: {
  transferId: string;
  onClose: () => void;
  onDone: () => void;
}) {
  const api = useApi();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  return (
    <ConfirmModal
      title={<FormattedMessage id="families.transferCancel" />}
      confirm={<FormattedMessage id="families.transferCancel" />}
      danger
      busy={busy}
      error={error}
      onCancel={onClose}
      onConfirm={() => {
        setBusy(true);
        api
          .call('staffCancelTransfer', { transferId })
          .then(() => {
            onClose();
            onDone();
          })
          .catch((err: unknown) => setError(asApiError(err)))
          .finally(() => setBusy(false));
      }}
    />
  );
}
