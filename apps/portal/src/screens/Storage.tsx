import { routineGrantGb, staffCan } from '@child-life/contracts';
import { useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { ApiError, useApi, useLoad, type StorageList, type StorageRow } from '../api';
import { useRefreshBadges, useStaff } from '../context';
import { ZONE, ago, duration, gb, num, pct, usageTone } from '../format';
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
  Segmented,
  TableScroll,
  UsageBar,
  useSort,
} from '../ui';

type Status = 'open' | 'granted' | 'declined';
const GB = 1024 ** 3;

/** A04 Mở rộng dung lượng: decide on metadata only, never content. */
export function StorageScreen() {
  const intl = useIntl();
  const [status, setStatus] = useState<Status>('open');
  const [load, reload] = useLoad<StorageList>('staffStorageRequests', { status }, status);
  return (
    <Page
      title={<FormattedMessage id="storage.title" />}
      info={<FormattedMessage id="storage.sub" />}
      actions={
        <Segmented
          label={intl.formatMessage({ id: 'storage.filter' })}
          value={status}
          onChange={setStatus}
          options={[
            {
              value: 'open',
              label:
                load.status === 'ok' ? (
                  <FormattedMessage id="storage.pendingN" values={{ n: load.data.kpis.pending }} />
                ) : (
                  <FormattedMessage id="storage.pending" />
                ),
            },
            { value: 'granted', label: <FormattedMessage id="storage.granted" /> },
            { value: 'declined', label: <FormattedMessage id="storage.declined" /> },
          ]}
        />
      }
    >
      <Loaded load={load} reload={reload}>
        {(data) => <StorageView data={data} status={status} now={new Date()} onChanged={reload} />}
      </Loaded>
    </Page>
  );
}

export function StorageView({
  data,
  status,
  now,
  onChanged,
}: {
  data: StorageList;
  status: Status;
  now: Date;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const staff = useStaff();
  const canDecide = staffCan(staff.levels, 'storage.decide');
  const [selected, setSelected] = useState<string | null>(null);
  const [dialog, setDialog] = useState<{ row: StorageRow; kind: 'grant' | 'decline' } | null>(null);
  const row = data.rows.find((r) => r.id === selected) ?? data.rows[0] ?? null;
  const sort = useSort(data.rows, {
    code: (r) => r.code,
    family: (r) => r.family,
    using: (r) => (r.quotaBytes ? r.usedBytes / r.quotaBytes : null),
    requested: (r) => r.requestedGb,
    sent: (r) => r.createdAt,
  });
  const k = data.kpis;
  return (
    <div className="grid">
      <div className="kpis">
        <Kpi
          label={<FormattedMessage id="storage.kpiPending" />}
          value={num(intl, k.pending)}
          foot={
            k.oldestAt ? (
              <FormattedMessage id="storage.oldest" values={{ ago: ago(intl, k.oldestAt, now) }} />
            ) : (
              <FormattedMessage id="storage.none" />
            )
          }
          tone={k.oldestAt ? 'warn' : 'muted'}
        />
        <Kpi
          label={<FormattedMessage id="storage.kpiOver80" />}
          value={num(intl, k.over80)}
          foot={<FormattedMessage id="storage.reminded" />}
        />
        <Kpi
          label={<FormattedMessage id="storage.kpiMonth" />}
          value={num(intl, k.grantedThisMonth)}
          foot={<FormattedMessage id="storage.monthGb" values={{ n: k.grantedGbThisMonth }} />}
        />
        <Kpi
          label={<FormattedMessage id="storage.kpiMedian" />}
          value={duration(intl, k.medianHours === null ? null : k.medianHours * 60)}
          foot={<FormattedMessage id="storage.target" />}
        />
      </div>
      <Panel
        title={<FormattedMessage id={`storage.table.${status}`} />}
        aside={
          <span className="muted">
            <FormattedMessage id="storage.anon" />
          </span>
        }
        className="panel--flush"
      >
        {data.rows.length === 0 ? (
          <Empty>
            <FormattedMessage id={`storage.empty.${status}`} />
          </Empty>
        ) : (
          <TableScroll min={880}>
            <table className="table">
              <thead>
                <tr>
                  {sort.th('code', <FormattedMessage id="col.id" />)}
                  {sort.th('family', <FormattedMessage id="col.family" />)}
                  {sort.th('using', <FormattedMessage id="col.using" />)}
                  {sort.th('requested', <FormattedMessage id="col.requested" />)}
                  <th>
                    <FormattedMessage id="col.message" />
                  </th>
                  {sort.th('sent', <FormattedMessage id="col.sent" />)}
                  {status === 'open' && canDecide && <th />}
                </tr>
              </thead>
              <tbody>
                {sort.rows.map((r) => {
                  const ratio = r.usedBytes / Math.max(1, r.quotaBytes);
                  return (
                    <tr
                      key={r.id}
                      className={r.id === row?.id ? 'table__row--on' : ''}
                      onClick={() => setSelected(r.id)}
                    >
                      <td className="mono nowrap">{r.code}</td>
                      <td>
                        <strong className="mono nowrap">{r.family}</strong>
                        <br />
                        <span className="muted">
                          <FormattedMessage
                            id="family.shape"
                            values={{ babies: r.babies, people: r.people }}
                          />
                        </span>
                      </td>
                      <td className="nowrap">
                        {gb(intl, r.usedBytes)} / {gb(intl, r.quotaBytes, 0)} · {pct(intl, ratio)}
                        <UsageBar ratio={ratio} tone={usageTone(r.usedBytes, r.quotaBytes)} />
                      </td>
                      <td>
                        <strong>+{r.requestedGb} GB</strong>
                        {r.grantedGb !== null && (
                          <>
                            <br />
                            <span className="muted">
                              <FormattedMessage id="storage.grantedN" values={{ n: r.grantedGb }} />
                            </span>
                          </>
                        )}
                      </td>
                      <td className="cell-message">{r.message ?? '—'}</td>
                      <td className="nowrap">{ago(intl, r.createdAt, now)}</td>
                      {status === 'open' && canDecide && (
                        <td className="cell-actions">
                          <Button onClick={() => setDialog({ row: r, kind: 'decline' })}>
                            <FormattedMessage id="storage.decline" />
                          </Button>
                          <Button
                            kind="primary"
                            onClick={() => setDialog({ row: r, kind: 'grant' })}
                          >
                            <FormattedMessage id="storage.approve" />
                          </Button>
                        </td>
                      )}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </TableScroll>
        )}
      </Panel>
      <div className="cols cols--1-1">
        {row && <MetricsPanel row={row} />}
        <Panel title={<FormattedMessage id="storage.guide" />}>
          <dl className="kv kv--guide">
            <dt>+5 GB</dt>
            <dd>
              <FormattedMessage id="storage.guide5" />
            </dd>
            <dt>+10 GB</dt>
            <dd>
              <FormattedMessage id="storage.guide10" />
            </dd>
            <dt>
              <FormattedMessage id="storage.custom" />
            </dt>
            <dd>
              <FormattedMessage id="storage.guideCustom" />
            </dd>
          </dl>
          <LockNote>
            <FormattedMessage id="storage.lock" />
          </LockNote>
        </Panel>
      </div>
      {dialog && (
        <DecideDialog
          row={dialog.row}
          kind={dialog.kind}
          onClose={() => setDialog(null)}
          onDone={() => {
            setDialog(null);
            onChanged();
          }}
        />
      )}
    </div>
  );
}

function MetricsPanel({ row }: { row: StorageRow }) {
  const intl = useIntl();
  const m = row.metrics;
  const total = Math.max(1, row.quotaBytes);
  const parts = [
    { key: 'photos', bytes: m.photoBytes, cls: 'seg-photo' },
    { key: 'videos', bytes: m.videoBytes, cls: 'seg-video' },
    { key: 'other', bytes: m.otherBytes, cls: 'seg-other' },
    { key: 'free', bytes: m.freeBytes, cls: 'seg-free' },
  ];
  return (
    <Panel
      title={<FormattedMessage id="storage.metrics" values={{ code: row.family }} />}
      note={<FormattedMessage id="storage.metaOnly" />}
    >
      <div className="stackbar" aria-hidden="true">
        {parts.map((p) => (
          <span key={p.key} className={p.cls} style={{ width: `${(p.bytes / total) * 100}%` }} />
        ))}
      </div>
      <ul className="legend">
        {parts.map((p) => (
          <li key={p.key}>
            <span className={`legend__dot ${p.cls}`} />
            <FormattedMessage id={`storage.part.${p.key}`} /> {gb(intl, p.bytes)}
          </li>
        ))}
      </ul>
      <dl className="kv">
        <dt>
          <FormattedMessage id="storage.previous" />
        </dt>
        <dd>
          {m.previousGrants ? (
            <FormattedMessage id="storage.previousN" values={{ n: m.previousGrants }} />
          ) : (
            <FormattedMessage id="storage.previousNone" />
          )}
        </dd>
        <dt>
          <FormattedMessage id="storage.created" />
        </dt>
        <dd>
          {m.ownerCreatedAt
            ? intl.formatDate(m.ownerCreatedAt, { month: 'long', year: 'numeric', timeZone: ZONE })
            : '—'}
        </dd>
        <dt>
          <FormattedMessage id="storage.requester" />
        </dt>
        <dd>
          <FormattedMessage id={m.requesterIsOwner ? 'storage.byOwner' : 'storage.byParent'} />
        </dd>
      </dl>
    </Panel>
  );
}

/** "Tuỳ chỉnh" or above 20 GB needs a team lead (P-120); others see why the button is off. */
export function needsLead(grantGb: number): boolean {
  return grantGb > 20 || !(routineGrantGb as readonly number[]).includes(grantGb);
}

export function DecideDialog({
  row,
  kind,
  onClose,
  onDone,
}: {
  row: StorageRow;
  kind: 'grant' | 'decline';
  onClose: () => void;
  onDone: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const staff = useStaff();
  const refreshBadges = useRefreshBadges();
  const routine = (routineGrantGb as readonly number[]).includes(row.requestedGb);
  const [choice, setChoice] = useState<number | 'custom'>(routine ? row.requestedGb : 'custom');
  const [custom, setCustom] = useState(String(row.requestedGb));
  const grantGb = choice === 'custom' ? Number(custom) : choice;
  const validGb = Number.isInteger(grantGb) && grantGb >= 1 && grantGb <= 500;
  const [message, setMessage] = useState(() =>
    intl.formatMessage(
      { id: kind === 'grant' ? 'storage.grantMessage' : 'storage.declineMessage' },
      { n: row.requestedGb },
    ),
  );
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const leadNeeded = kind === 'grant' && validGb && needsLead(grantGb);
  const blocked = leadNeeded && !staffCan(staff.levels, 'storage.large');
  const submit = async () => {
    setBusy(true);
    setError(null);
    try {
      await api.call(
        'staffDecideStorage',
        kind === 'grant'
          ? {
              decision: 'grant',
              requestId: row.id,
              grantGb,
              message: message.trim(),
            }
          : {
              decision: 'decline',
              requestId: row.id,
              message: message.trim(),
            },
      );
      refreshBadges();
      onDone();
    } catch (e) {
      setError(e instanceof ApiError ? e : new ApiError('unknown', null));
    } finally {
      setBusy(false);
    }
  };
  return (
    <Modal
      title={
        <FormattedMessage
          id={kind === 'grant' ? 'storage.grantTitle' : 'storage.declineTitle'}
          values={{ code: row.family, n: row.requestedGb }}
        />
      }
      onClose={onClose}
    >
      <p className="modal__sub">
        <FormattedMessage
          id="storage.dialogSub"
          values={{
            used: gb(intl, row.usedBytes),
            quota: gb(intl, row.quotaBytes, 0),
            babies: row.babies,
            people: row.people,
          }}
        />
      </p>
      {kind === 'grant' && (
        <div
          className="chips"
          role="radiogroup"
          aria-label={intl.formatMessage({ id: 'storage.amount' })}
        >
          {routineGrantGb.map((n) => (
            <button
              key={n}
              type="button"
              role="radio"
              aria-checked={choice === n}
              className={`chip ${choice === n ? 'chip--on' : ''}`}
              onClick={() => setChoice(n)}
            >
              +{n} GB
            </button>
          ))}
          <button
            type="button"
            role="radio"
            aria-checked={choice === 'custom'}
            className={`chip ${choice === 'custom' ? 'chip--on' : ''}`}
            onClick={() => setChoice('custom')}
          >
            <FormattedMessage id="storage.custom" />
          </button>
          {choice === 'custom' && (
            <label className="chip-input">
              +
              <input
                type="number"
                min={1}
                max={500}
                value={custom}
                onChange={(e) => setCustom(e.target.value)}
                aria-label={intl.formatMessage({ id: 'storage.customGb' })}
              />
              GB
            </label>
          )}
        </div>
      )}
      {blocked && (
        <p className="note note--warn">
          <FormattedMessage id="storage.leadNeeded" />
        </p>
      )}
      <div className="field">
        <label className="field__label" htmlFor="family-message">
          <FormattedMessage id="storage.familyMessage" />
        </label>
        <textarea
          id="family-message"
          className="field__input"
          rows={3}
          maxLength={1000}
          value={message}
          onChange={(e) => setMessage(e.target.value)}
        />
        <p className="field__help">
          <FormattedMessage
            id={kind === 'grant' ? 'storage.grantChannel' : 'storage.declineChannel'}
          />
        </p>
      </div>
      {kind === 'grant' && validGb && (
        <p className="summary">
          <FormattedMessage id="storage.newQuota" />{' '}
          <strong>
            {gb(intl, row.quotaBytes, 0)} → {gb(intl, row.quotaBytes + grantGb * GB, 0)}
          </strong>
        </p>
      )}
      {error && (
        <p className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
      <div className="modal__actions">
        <Button onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button
          kind={kind === 'grant' ? 'primary' : 'danger'}
          disabled={busy || blocked || (kind === 'grant' && !validGb)}
          onClick={() => void submit()}
        >
          <FormattedMessage
            id={kind === 'grant' ? 'storage.grantConfirm' : 'storage.declineConfirm'}
          />
        </Button>
      </div>
    </Modal>
  );
}
