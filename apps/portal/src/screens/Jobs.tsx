import { staffCan } from '@child-life/contracts';
import { Fragment, useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { ApiError, useApi, useLoad, type JobList, type JobRow } from '../api';
import { useRefreshBadges, useStaff } from '../context';
import { duration, num, pct, when } from '../format';
import { RenderOpsLoader } from './PremiumOps';
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
  ReasonField,
  reasonOk,
  Segmented,
  TableScroll,
  UsageBar,
  useSort,
  type PillTone,
} from '../ui';

type DataKind = 'all' | 'export' | 'deletion';
/** `render`: keepsake video render jobs (read-only, plan §5.6) instead of data jobs. */
export type Kind = DataKind | 'render';

/** A06 Yêu cầu dữ liệu: status and re-run only; staff can never open or download an export. */
export function JobsScreen() {
  const intl = useIntl();
  const [kind, setKind] = useState<Kind>('all');
  const filterLabel = intl.formatMessage({ id: 'jobs.filter' });
  return (
    <Page
      title={<FormattedMessage id="jobs.title" />}
      subtitle={<FormattedMessage id="jobs.sub" />}
    >
      {kind === 'render' ? (
        <RenderOpsLoader
          toolbar={<JobKinds label={filterLabel} value={kind} onChange={setKind} />}
        />
      ) : (
        <DataJobs kind={kind} onKind={setKind} filterLabel={filterLabel} />
      )}
    </Page>
  );
}

function DataJobs({
  kind,
  onKind,
  filterLabel,
}: {
  kind: DataKind;
  onKind: (k: Kind) => void;
  filterLabel: string;
}) {
  const [load, reload] = useLoad<JobList>('staffJobs', { kind }, kind);
  return (
    <Loaded load={load} reload={reload}>
      {(data) => (
        <JobsView
          data={data}
          kind={kind}
          onKind={onKind}
          now={new Date()}
          onChanged={reload}
          filterLabel={filterLabel}
        />
      )}
    </Loaded>
  );
}

/** The job filter, shared by data jobs and video renders. */
export function JobKinds({
  label,
  value,
  onChange,
}: {
  label: string;
  value: Kind;
  onChange: (k: Kind) => void;
}) {
  return (
    <Segmented
      label={label}
      value={value}
      onChange={onChange}
      options={[
        { value: 'all', label: <FormattedMessage id="jobs.all" /> },
        { value: 'export', label: <FormattedMessage id="jobs.exports" /> },
        { value: 'deletion', label: <FormattedMessage id="jobs.deletionsTab" /> },
        { value: 'render', label: <FormattedMessage id="jobs.render" /> },
      ]}
    />
  );
}

export function jobState(row: JobRow): { tone: PillTone; id: string } {
  const deletion = row.type.startsWith('delete');
  switch (row.state) {
    case 'queued':
      return { tone: 'info', id: 'job.queued' };
    case 'running':
      return { tone: 'info', id: deletion ? 'job.deleting' : 'job.preparing' };
    case 'ready':
      return { tone: 'ok', id: 'job.ready' };
    case 'expired':
      return { tone: 'muted', id: 'job.expired' };
    case 'failed':
      return { tone: 'error', id: 'job.failed' };
    case 'done':
      return { tone: 'ok', id: 'job.done' };
    default:
      return { tone: 'muted', id: 'job.unknown' };
  }
}

export function JobsView({
  data,
  kind,
  onKind,
  now,
  onChanged,
  filterLabel,
}: {
  data: JobList;
  kind: Kind;
  onKind: (k: Kind) => void;
  now: Date;
  onChanged: () => void;
  filterLabel: string;
}) {
  const intl = useIntl();
  const staff = useStaff();
  const canRerun = staffCan(staff.levels, 'jobs.rerun');
  const canApprove = staffCan(staff.levels, 'jobs.approve');
  const [open, setOpen] = useState<string | null>(null);
  const [rerun, setRerun] = useState<{ row: JobRow; mode: 'request' | 'approve' } | null>(null);
  const sort = useSort(data.rows, {
    code: (r) => r.code,
    type: (r) => r.type,
    email: (r) => r.email,
    created: (r) => r.createdAt,
    progress: (r) => r.progress,
    state: (r) => r.state,
  });
  const k = data.kpis;
  return (
    <div className="grid">
      <div className="kpis">
        <Kpi
          label={<FormattedMessage id="jobs.running" />}
          value={num(intl, k.running)}
          foot={
            <FormattedMessage
              id="jobs.runningSplit"
              values={{ exports: k.runningExports, deletions: k.running - k.runningExports }}
            />
          }
        />
        <Kpi
          label={<FormattedMessage id="jobs.failed" />}
          value={num(intl, k.failed24h)}
          foot={<FormattedMessage id={k.failed24h ? 'jobs.needsRerun' : 'jobs.noFailures'} />}
          tone={k.failed24h ? 'error' : 'muted'}
        />
        <Kpi
          label={<FormattedMessage id="jobs.exportTime" />}
          value={duration(intl, k.medianExportMinutes)}
          foot={<FormattedMessage id="jobs.last30" />}
        />
        <Kpi
          label={<FormattedMessage id="jobs.deletions" />}
          value={pct(intl, k.deletionsTotal ? k.deletionsDone / k.deletionsTotal : null)}
          foot={
            <FormattedMessage
              id="jobs.deletionsOf"
              values={{ done: k.deletionsDone, total: k.deletionsTotal }}
            />
          }
        />
      </div>
      <Panel className="panel--flush">
        <div className="panel__pad toolbar">
          <JobKinds label={filterLabel} value={kind} onChange={onKind} />
          <span className="muted">
            <FormattedMessage id="jobs.linkTtl" />
          </span>
        </div>
        {data.rows.length === 0 ? (
          <Empty>
            <FormattedMessage id="jobs.empty" />
          </Empty>
        ) : (
          <TableScroll min={820}>
            <table className="table">
              <thead>
                <tr>
                  {sort.th('code', <FormattedMessage id="col.id" />)}
                  {sort.th('type', <FormattedMessage id="col.type" />)}
                  {sort.th('email', <FormattedMessage id="col.requester" />)}
                  {sort.th('created', <FormattedMessage id="col.created" />)}
                  {sort.th('progress', <FormattedMessage id="col.progress" />)}
                  {sort.th('state', <FormattedMessage id="col.status" />)}
                  <th />
                </tr>
              </thead>
              <tbody>
                {sort.rows.map((r) => {
                  const s = jobState(r);
                  const deletion = r.type.startsWith('delete');
                  return (
                    <Fragment key={r.id}>
                      <tr>
                        <td className="mono">{r.code}</td>
                        <td>
                          <FormattedMessage id={`jobType.${r.type}`} />
                        </td>
                        <td>{r.email}</td>
                        <td>{when(intl, r.createdAt, now)}</td>
                        <td className="cell-progress">
                          <UsageBar
                            ratio={r.progress}
                            tone={r.state === 'failed' ? 'error' : 'ok'}
                          />
                          <span className="muted">
                            <ProgressText row={r} now={now} />
                          </span>
                        </td>
                        <td>
                          <Pill tone={s.tone}>
                            <FormattedMessage id={s.id} />
                          </Pill>
                        </td>
                        <td className="cell-actions">
                          {/* P-139: one person asks, a second one with "Duyệt" approves. */}
                          {deletion && r.state === 'failed' && r.rerunRequest ? (
                            <>
                              <span className="muted">
                                <FormattedMessage
                                  id="jobs.rerunPending"
                                  values={{ name: r.rerunRequest.by }}
                                />
                              </span>
                              {canApprove && r.rerunRequest.byUid !== staff.uid && (
                                <Button
                                  kind="primary"
                                  onClick={() => setRerun({ row: r, mode: 'approve' })}
                                >
                                  <FormattedMessage id="jobs.rerunApprove" />
                                </Button>
                              )}
                            </>
                          ) : deletion && r.state === 'failed' && canRerun ? (
                            <Button
                              kind="primary"
                              onClick={() => setRerun({ row: r, mode: 'request' })}
                            >
                              <FormattedMessage id="jobs.rerun" />
                            </Button>
                          ) : deletion ? (
                            <Button
                              kind="ghost"
                              onClick={() => setOpen(open === r.id ? null : r.id)}
                            >
                              <FormattedMessage id="jobs.steps" />
                            </Button>
                          ) : null}
                        </td>
                      </tr>
                      {open === r.id && r.steps && (
                        <tr className="table__detail">
                          <td colSpan={7}>
                            <Steps row={r} />
                          </td>
                        </tr>
                      )}
                    </Fragment>
                  );
                })}
              </tbody>
            </table>
          </TableScroll>
        )}
        <div className="panel__pad">
          <LockNote>
            <FormattedMessage id="jobs.lock1" />
          </LockNote>
          <LockNote>
            <FormattedMessage id="jobs.lock2" />
          </LockNote>
          <LockNote>
            <FormattedMessage id="jobs.lock3" />
          </LockNote>
        </div>
      </Panel>
      {rerun && (
        <RerunDialog
          row={rerun.row}
          mode={rerun.mode}
          onClose={() => setRerun(null)}
          onDone={() => {
            setRerun(null);
            onChanged();
          }}
        />
      )}
    </div>
  );
}

function ProgressText({ row, now }: { row: JobRow; now: Date }) {
  const intl = useIntl();
  if (row.state === 'failed' && row.failedStep) {
    return (
      <FormattedMessage
        id="jobs.stoppedAt"
        values={{ step: intl.formatMessage({ id: `step.${row.failedStep}` }) }}
      />
    );
  }
  if (row.state === 'ready' && row.expiresAt) {
    const hours = Math.max(0, Math.round((Date.parse(row.expiresAt) - now.getTime()) / 3_600_000));
    return <FormattedMessage id="jobs.expiresIn" values={{ n: hours }} />;
  }
  if (row.state === 'expired') return <FormattedMessage id="jobs.notDownloaded" />;
  if (row.state === 'done' && row.finishedAt) {
    return (
      <FormattedMessage
        id="jobs.doneAfter"
        values={{
          d: duration(intl, (Date.parse(row.finishedAt) - Date.parse(row.createdAt)) / 60_000),
        }}
      />
    );
  }
  if (row.state === 'running' && row.type.startsWith('delete')) {
    return <FormattedMessage id="jobs.lockedDeleting" />;
  }
  return <>{pct(intl, row.progress)}</>;
}

/** The step list (A07): ✓ done, ✗ where it stopped, ○ still to run. */
function Steps({ row }: { row: JobRow }) {
  const steps = row.steps ?? [];
  const at = row.step ?? 0;
  return (
    <ol className="steps">
      {steps.map((name, i) => {
        const state =
          i < at || row.state === 'done'
            ? 'done'
            : i === at && row.state === 'failed'
              ? 'failed'
              : 'todo';
        return (
          <li key={name} className={`steps__item steps__item--${state}`}>
            <span aria-hidden="true">
              {state === 'done' ? '✓' : state === 'failed' ? '✕' : '○'}
            </span>
            <FormattedMessage id={`step.${name}`} />
          </li>
        );
      })}
    </ol>
  );
}

export function RerunDialog({
  row,
  mode,
  onClose,
  onDone,
}: {
  row: JobRow;
  mode: 'request' | 'approve';
  onClose: () => void;
  onDone: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const refreshBadges = useRefreshBadges();
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const submit = async () => {
    setBusy(true);
    setError(null);
    try {
      await api.call(mode === 'approve' ? 'staffApproveRerun' : 'staffRerunJob', {
        jobId: row.id,
        reason: reason.trim(),
      });
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
          id="jobs.rerunTitle"
          values={{ type: intl.formatMessage({ id: `jobType.${row.type}` }), code: row.code }}
        />
      }
      onClose={onClose}
    >
      <p className="modal__sub">
        <FormattedMessage
          id="jobs.rerunSub"
          values={{
            step: row.failedStep ? intl.formatMessage({ id: `step.${row.failedStep}` }) : '—',
          }}
        />
      </p>
      <Steps row={row} />
      {mode === 'approve' && row.rerunRequest ? (
        <p className="quote">
          <FormattedMessage
            id="jobs.rerunAskedBy"
            values={{ name: row.rerunRequest.by, reason: row.rerunRequest.reason }}
          />
        </p>
      ) : (
        <p className="note">
          <FormattedMessage id="jobs.rerunTwoPerson" />
        </p>
      )}
      <ReasonField value={reason} onChange={setReason} required />
      <p className="field__help">
        <FormattedMessage id="jobs.emailOnDone" />
      </p>
      {error && (
        <p className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
      <div className="modal__actions">
        <Button onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button kind="primary" disabled={busy || !reasonOk(reason)} onClick={() => void submit()}>
          <FormattedMessage id={mode === 'approve' ? 'jobs.rerunConfirm' : 'jobs.rerunRequest'} />
        </Button>
      </div>
    </Modal>
  );
}
