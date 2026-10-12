import {
  qaLevels,
  qaModules,
  qaPlatforms,
  qaStatuses,
  staffCan,
  type QaCaseContent,
  type QaEnvironment,
  type QaLevel,
  type QaModule,
  type QaPlatform,
  type QaStatus,
} from '@child-life/contracts';
import { useEffect, useId, useMemo, useRef, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import {
  ApiError,
  useApi,
  useLoad,
  type QaCase,
  type QaComment,
  type QaHandbook,
  type QaResult,
  type QaRun,
} from '../api';
import { useStaff } from '../context';
import { ZONE, when } from '../format';
import {
  Button,
  Empty,
  Loaded,
  Modal,
  Page,
  Panel,
  Pill,
  Segmented,
  errorMessageId,
  TableScroll,
  useEscape,
  useScrollLock,
  type PillTone,
} from '../ui';

/**
 * Phát triển › Sổ tay kiểm thử (P-132): what each module does, its smoke and core cases, and the
 * results of one test run. Every staff member may record results; Kiểm thử, Kỹ thuật and trưởng
 * nhóm open runs and write cases. Nothing here shows family data.
 */

export const statusTone: Record<QaStatus, PillTone> = {
  notRun: 'muted',
  passed: 'ok',
  failed: 'error',
  blocked: 'wait',
  skipped: 'info',
};
const levelTone: Record<QaLevel, PillTone> = { smoke: 'error', core: 'muted' };

export type QaView =
  { kind: 'start' } | { kind: 'all' } | { kind: 'module'; module: QaModule } | { kind: 'archived' };

export interface QaFilters {
  q: string;
  level: 'all' | QaLevel;
  platform: 'all' | QaPlatform;
  status: 'all' | QaStatus;
}
const noFilters: QaFilters = { q: '', level: 'all', platform: 'all', status: 'all' };

const runPattern = /^r_[a-f0-9]{20}$/;
const runKey = 'childlife.portal.qaRun';
function rememberedRun(): string | null {
  try {
    return globalThis.localStorage?.getItem(runKey) ?? null;
  } catch {
    return null;
  }
}
function rememberRun(id: string | null): void {
  try {
    if (id) globalThis.localStorage?.setItem(runKey, id);
  } catch {
    // Storage can be unavailable (private mode); the run simply isn't remembered.
  }
}

/** Search ignores Vietnamese tone marks: "dang nhap" finds "Đăng nhập". */
export function fold(s: string): string {
  return s.normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[đĐ]/g, 'd').toLowerCase();
}

const statusOf = (results: Record<string, QaResult>, id: string): QaStatus =>
  results[id]?.status ?? 'notRun';

/** Progress of a run; archived cases are left out of every count. */
export function qaProgress(cases: QaCase[], results: Record<string, QaResult>) {
  const active = cases.filter((c) => !c.archived);
  const done = (list: QaCase[]) => list.filter((c) => statusOf(results, c.id) !== 'notRun').length;
  const smoke = active.filter((c) => c.level === 'smoke');
  const counts = Object.fromEntries(qaStatuses.map((s) => [s, 0])) as Record<QaStatus, number>;
  for (const c of active) counts[statusOf(results, c.id)]++;
  const modules = Object.fromEntries(
    qaModules.map((m) => {
      const list = active.filter((c) => c.module === m);
      return [m, { done: done(list), total: list.length }];
    }),
  ) as Record<QaModule, { done: number; total: number }>;
  return {
    smoke: { done: done(smoke), total: smoke.length },
    all: { done: done(active), total: active.length },
    counts,
    modules,
    archived: cases.length - active.length,
  };
}

export function filterCases(
  cases: QaCase[],
  results: Record<string, QaResult>,
  view: QaView,
  filters: QaFilters,
): QaCase[] {
  const q = fold(filters.q.trim());
  return cases.filter((c) => {
    if (view.kind === 'archived' ? !c.archived : c.archived) return false;
    if (view.kind === 'module' && c.module !== view.module) return false;
    if (filters.level !== 'all' && c.level !== filters.level) return false;
    if (filters.platform !== 'all' && !c.platforms.includes(filters.platform)) return false;
    if (filters.status !== 'all' && statusOf(results, c.id) !== filters.status) return false;
    if (q) {
      const haystack = [c.id, c.title, c.account, ...c.steps, ...c.expected].join('\n');
      if (!fold(haystack).includes(q)) return false;
    }
    return true;
  });
}

function dateTime(intl: IntlShape, iso: string): string {
  return intl.formatDate(iso, {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    timeZone: ZONE,
  });
}

const asApiError = (e: unknown) => (e instanceof ApiError ? e : new ApiError('unknown', null));

type Dialog = { kind: 'run' } | { kind: 'case'; edit: QaCase | null };

export function QaScreen() {
  const api = useApi();
  const staff = useStaff();
  const canTest = staffCan(staff.levels, 'qa.test');
  const canManage = staffCan(staff.levels, 'qa.manage');
  const [initial] = useState(() => new URLSearchParams(window.location.search));
  const [wanted, setWanted] = useState<string | null>(() => {
    const id = initial.get('run') ?? rememberedRun();
    return id && runPattern.test(id) ? id : null;
  });
  const [load, reload] = useLoad<QaHandbook>('staffQa', { runId: wanted }, wanted ?? '');
  const [showArchived, setShowArchived] = useState(false);
  const [view, setView] = useState<QaView>(() =>
    initial.get('case') ? { kind: 'all' } : { kind: 'start' },
  );
  const [filters, setFilters] = useState<QaFilters>(noFilters);
  const [openId, setOpenId] = useState<string | null>(() => initial.get('case'));
  const [dialog, setDialog] = useState<Dialog | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  // Results set in this session show at once, until the reloaded handbook carries them.
  const [pending, setPending] = useState<Record<string, QaResult>>({});

  const data = load.status === 'ok' ? load.data : null;
  const runId = data?.runId ?? null;
  useEffect(() => {
    if (!data) return;
    rememberRun(data.runId);
    setPending((p) =>
      Object.fromEntries(
        Object.entries(p).filter(([id, r]) => data.results[id]?.status !== r.status),
      ),
    );
  }, [data]);

  // The address carries the run and the open case, so a case can be linked from a ticket.
  useEffect(() => {
    const url = new URL(window.location.href);
    for (const [key, value] of [
      ['run', runId],
      ['case', openId],
    ] as const) {
      if (value) url.searchParams.set(key, value);
      else url.searchParams.delete(key);
    }
    if (url.href !== window.location.href) window.history.replaceState({}, '', url);
  }, [runId, openId]);

  const act = async <T,>(call: () => Promise<T>): Promise<T | null> => {
    setBusy(true);
    setError(null);
    try {
      const out = await call();
      reload();
      return out;
    } catch (e) {
      setError(asApiError(e));
      return null;
    } finally {
      setBusy(false);
    }
  };

  const setStatus = async (run: QaRun, caseId: string, status: QaStatus) => {
    const before = pending[caseId];
    setPending((p) => ({
      ...p,
      [caseId]: {
        status,
        by: staff.name,
        at: new Date().toISOString(),
        comments: data?.results[caseId]?.comments ?? 0,
      },
    }));
    const ok = await act(() =>
      api.call('staffQaUpdate', { op: 'setResult', runId: run.id, caseId, status }),
    );
    if (ok === null) {
      setPending((p) => {
        const rest = { ...p };
        delete rest[caseId];
        return before ? { ...rest, [caseId]: before } : rest;
      });
    }
  };

  return (
    <Page
      title={<FormattedMessage id="qa.title" />}
      subtitle={<FormattedMessage id="qa.sub" />}
      actions={
        canManage && (
          <Button
            kind="primary"
            onClick={() => {
              setError(null);
              setDialog({ kind: 'case', edit: null });
            }}
          >
            <FormattedMessage id="qa.add" />
          </Button>
        )
      }
    >
      <Loaded load={load} reload={reload}>
        {(loaded) => {
          const results = { ...loaded.results, ...pending };
          const run = loaded.runs.find((r) => r.id === loaded.runId) ?? null;
          const progress = qaProgress(loaded.cases, results);
          const rows = filterCases(loaded.cases, results, view, filters);
          const open = loaded.cases.find((c) => c.id === openId) ?? null;
          // Previous / next walk the table as filtered, or the whole catalog from "Bắt đầu".
          const walk = view.kind === 'start' ? loaded.cases.filter((c) => !c.archived) : rows;
          const at = open ? walk.findIndex((c) => c.id === open.id) : -1;
          const now = new Date();
          return (
            <div className="stack">
              {error && !dialog && !open && (
                <p className="error" role="alert">
                  <FormattedMessage id={errorMessageId(error)} />
                </p>
              )}
              <QaRunPanel
                runs={loaded.runs}
                run={run}
                progress={progress}
                showArchived={showArchived}
                canManage={canManage}
                busy={busy}
                onShowArchived={setShowArchived}
                onSelect={(id) => {
                  setPending({});
                  setWanted(id);
                }}
                onArchive={() => {
                  if (!run) return;
                  // Stay on this run: once archived it is no longer the default one.
                  setWanted(run.id);
                  void act(() =>
                    api.call('staffQaUpdate', {
                      op: 'archiveRun',
                      runId: run.id,
                      archived: !run.archived,
                    }),
                  );
                }}
                onNew={() => {
                  setError(null);
                  setDialog({ kind: 'run' });
                }}
              />
              <div className="qa">
                <QaNav progress={progress} view={view} onView={setView} />
                <div className="stack">
                  {view.kind === 'start' ? (
                    <QaStart />
                  ) : (
                    <>
                      {view.kind === 'module' && <QaModuleAbout module={view.module} />}
                      <QaCaseTable
                        rows={rows}
                        results={results}
                        hasRun={!!run}
                        filters={filters}
                        onFilters={setFilters}
                        onOpen={(id) => {
                          setError(null);
                          setOpenId(id);
                        }}
                      />
                    </>
                  )}
                </div>
              </div>
              {open && (
                <QaCaseDrawer
                  title={open.title}
                  onClose={() => setOpenId(null)}
                  onPrev={at > 0 ? () => setOpenId(walk[at - 1]!.id) : undefined}
                  onNext={
                    at >= 0 && at < walk.length - 1 ? () => setOpenId(walk[at + 1]!.id) : undefined
                  }
                >
                  <QaCaseDetail
                    item={open}
                    run={run}
                    result={results[open.id] ?? null}
                    canTest={canTest}
                    canManage={canManage}
                    busy={busy}
                    error={dialog ? null : error}
                    now={now}
                    onStatus={(s) => run && void setStatus(run, open.id, s)}
                    onEdit={() => {
                      setError(null);
                      setDialog({ kind: 'case', edit: open });
                    }}
                    onArchive={() =>
                      void act(() =>
                        api.call('staffQaUpdate', {
                          op: 'archiveCase',
                          caseId: open.id,
                          archived: !open.archived,
                        }),
                      )
                    }
                  >
                    {run && (
                      <QaComments
                        key={`${run.id}|${open.id}`}
                        runId={run.id}
                        caseId={open.id}
                        canComment={canTest && !run.archived}
                        now={now}
                        onAdded={reload}
                      />
                    )}
                  </QaCaseDetail>
                </QaCaseDrawer>
              )}
            </div>
          );
        }}
      </Loaded>

      {dialog?.kind === 'run' && (
        <QaRunDialog
          busy={busy}
          error={error}
          onClose={() => setDialog(null)}
          onCreate={async (req) => {
            const out = await act(() =>
              api.call<{ runId: string }>('staffQaUpdate', { op: 'createRun', ...req }),
            );
            if (out) {
              setPending({});
              setWanted(out.runId);
              setDialog(null);
            }
          }}
        />
      )}
      {dialog?.kind === 'case' && (
        <QaCaseDialog
          edit={dialog.edit}
          defaultModule={view.kind === 'module' ? view.module : 'onboarding'}
          busy={busy}
          error={error}
          onClose={() => setDialog(null)}
          onSave={async (content) => {
            const out = await act(() =>
              api.call<{ caseId: string }>('staffQaUpdate', {
                op: 'saveCase',
                caseId: dialog.edit?.id ?? null,
                ...content,
              }),
            );
            if (out) {
              setDialog(null);
              setOpenId(out.caseId);
            }
          }}
        />
      )}
    </Page>
  );
}

// ---------- Run panel ----------

function Meter({
  label,
  done,
  total,
  tone,
}: {
  label: ReactNode;
  done: number;
  total: number;
  tone: 'smoke' | 'all';
}) {
  const ratio = total ? done / total : 0;
  return (
    <div className="qa-meter">
      <p className="qa-meter__label">{label}</p>
      <span
        className="qa-meter__track"
        role="progressbar"
        aria-valuemin={0}
        aria-valuemax={total}
        aria-valuenow={done}
      >
        <span
          className={`qa-meter__fill qa-meter__fill--${tone}`}
          style={{ width: `${ratio * 100}%` }}
        />
      </span>
    </div>
  );
}

export function QaRunPanel({
  runs,
  run,
  progress,
  showArchived,
  canManage,
  busy,
  onShowArchived,
  onSelect,
  onArchive,
  onNew,
}: {
  runs: QaRun[];
  run: QaRun | null;
  progress: ReturnType<typeof qaProgress>;
  showArchived: boolean;
  canManage: boolean;
  busy: boolean;
  onShowArchived: (v: boolean) => void;
  onSelect: (runId: string) => void;
  onArchive: () => void;
  onNew: () => void;
}) {
  const intl = useIntl();
  const selectId = useId();
  const visible = runs.filter((r) => showArchived || !r.archived || r.id === run?.id);
  const env = (e: QaEnvironment) => intl.formatMessage({ id: `env.${e}` });
  return (
    <Panel className="qa-run">
      <div className="toolbar">
        <div className="qa-run__pick">
          {runs.length > 0 && (
            <div className="field">
              <label className="field__label" htmlFor={selectId}>
                <FormattedMessage id="qa.run.label" />
              </label>
              <select
                id={selectId}
                className="select qa-run__select"
                value={run?.id ?? ''}
                onChange={(e) => e.target.value && onSelect(e.target.value)}
              >
                {!run && <option value="">—</option>}
                {visible.map((r) => (
                  <option key={r.id} value={r.id}>
                    {intl.formatMessage(
                      { id: r.archived ? 'qa.run.optionArchived' : 'qa.run.option' },
                      { name: r.name, env: env(r.environment) },
                    )}
                  </option>
                ))}
              </select>
            </div>
          )}
          {runs.some((r) => r.archived) && (
            <label className="check-row">
              <input
                type="checkbox"
                checked={showArchived}
                onChange={(e) => onShowArchived(e.target.checked)}
              />
              <FormattedMessage id="qa.run.showArchived" />
            </label>
          )}
        </div>
        {canManage && (
          <div className="actions">
            {run && (
              <Button onClick={onArchive} disabled={busy}>
                <FormattedMessage id={run.archived ? 'qa.run.unarchive' : 'qa.run.archive'} />
              </Button>
            )}
            <Button kind="primary" onClick={onNew}>
              <FormattedMessage id="qa.run.new" />
            </Button>
          </div>
        )}
      </div>
      {run ? (
        <>
          <p className="muted">
            <FormattedMessage
              id="qa.run.meta"
              values={{
                env: env(run.environment),
                name: run.createdBy,
                when: dateTime(intl, run.createdAt),
              }}
            />
            {run.archived && (
              <>
                {' '}
                <Pill tone="muted">
                  <FormattedMessage id="qa.run.archivedTag" />
                </Pill>
              </>
            )}
          </p>
          {run.notes && <p className="qa-run__notes">{run.notes}</p>}
          <div className="qa-meters">
            <Meter
              tone="smoke"
              done={progress.smoke.done}
              total={progress.smoke.total}
              label={<FormattedMessage id="qa.run.smoke" values={progress.smoke} />}
            />
            <Meter
              tone="all"
              done={progress.all.done}
              total={progress.all.total}
              label={<FormattedMessage id="qa.run.all" values={progress.all} />}
            />
          </div>
          <div className="chips">
            {qaStatuses.map((s) => (
              <Pill key={s} tone={statusTone[s]}>
                <FormattedMessage
                  id="qa.run.count"
                  values={{
                    status: intl.formatMessage({ id: `qa.status.${s}` }),
                    n: progress.counts[s],
                  }}
                />
              </Pill>
            ))}
          </div>
        </>
      ) : (
        <p className="muted">
          <FormattedMessage id={canManage ? 'qa.run.none' : 'qa.run.noneAsk'} />
        </p>
      )}
    </Panel>
  );
}

// ---------- Contents ----------

export function QaNav({
  progress,
  view,
  onView,
}: {
  progress: ReturnType<typeof qaProgress>;
  view: QaView;
  onView: (v: QaView) => void;
}) {
  const intl = useIntl();
  const item = (key: string, on: boolean, next: QaView, label: ReactNode, count?: string) => (
    <button
      key={key}
      type="button"
      className={`qa-nav__item ${on ? 'qa-nav__item--on' : ''}`}
      aria-current={on ? 'true' : undefined}
      onClick={() => onView(next)}
    >
      <span>{label}</span>
      {count !== undefined && <span className="qa-nav__count">{count}</span>}
    </button>
  );
  return (
    <nav className="panel qa-nav" aria-label={intl.formatMessage({ id: 'qa.nav.label' })}>
      {item(
        'start',
        view.kind === 'start',
        { kind: 'start' },
        <FormattedMessage id="qa.nav.start" />,
      )}
      {item(
        'all',
        view.kind === 'all',
        { kind: 'all' },
        <FormattedMessage id="qa.nav.all" />,
        intl.formatNumber(progress.all.total),
      )}
      <p className="qa-nav__head">
        <FormattedMessage id="qa.nav.modules" />
      </p>
      {qaModules
        .filter((m) => progress.modules[m].total > 0)
        .map((m) =>
          item(
            m,
            view.kind === 'module' && view.module === m,
            { kind: 'module', module: m },
            <FormattedMessage id={`qa.module.${m}`} />,
            `${progress.modules[m].done}/${progress.modules[m].total}`,
          ),
        )}
      {progress.archived > 0 &&
        item(
          'archived',
          view.kind === 'archived',
          { kind: 'archived' },
          <FormattedMessage id="qa.nav.archived" />,
          intl.formatNumber(progress.archived),
        )}
    </nav>
  );
}

/** "Bắt đầu": what the handbook is for and how a run works. */
export function QaStart() {
  const p = (id: string) => (
    <p>
      <FormattedMessage id={id} />
    </p>
  );
  const li = (id: string) => (
    <li key={id}>
      <FormattedMessage
        id={id}
        values={{ b: (chunks: ReactNode[]) => <strong>{chunks}</strong> }}
      />
    </li>
  );
  return (
    <>
      <Panel title={<FormattedMessage id="qa.start.purpose.title" />}>
        <div className="qa-prose">
          {p('qa.start.purpose.body')}
          {p('qa.start.purpose.history')}
        </div>
      </Panel>
      <Panel title={<FormattedMessage id="qa.start.levels.title" />}>
        <ul className="qa-prose qa-prose--list">
          {li('qa.start.levels.smoke')}
          {li('qa.start.levels.core')}
          {li('qa.start.levels.explore')}
        </ul>
      </Panel>
      <Panel title={<FormattedMessage id="qa.start.run.title" />}>
        <ol className="qa-prose qa-prose--list">
          {['create', 'follow', 'record', 'archive'].map((s) => li(`qa.start.run.${s}`))}
        </ol>
      </Panel>
      <Panel title={<FormattedMessage id="qa.start.status.title" />}>
        <ul className="qa-prose qa-prose--list">
          {(['passed', 'failed', 'blocked', 'skipped'] as const).map((s) =>
            li(`qa.start.status.${s}`),
          )}
        </ul>
      </Panel>
      <Panel title={<FormattedMessage id="qa.start.accounts.title" />}>
        <div className="qa-prose">
          {p('qa.start.accounts.body')}
          <ul className="qa-prose--list">
            {['owner', 'coParent', 'caregiver', 'relative', 'guest', 'staff'].map((a) =>
              li(`qa.start.accounts.${a}`),
            )}
          </ul>
          {p('qa.start.accounts.devices')}
        </div>
      </Panel>
      <Panel title={<FormattedMessage id="qa.start.bugs.title" />}>
        <div className="qa-prose">
          {p('qa.start.bugs.body')}
          {p('qa.start.bugs.privacy')}
        </div>
      </Panel>
    </>
  );
}

function QaModuleAbout({ module }: { module: QaModule }) {
  return (
    <Panel title={<FormattedMessage id={`qa.module.${module}`} />}>
      <p className="qa-prose">
        <FormattedMessage id={`qa.module.${module}.about`} />
      </p>
    </Panel>
  );
}

function PlatformTags({ platforms }: { platforms: QaPlatform[] }) {
  return (
    <span className="qa-tags">
      {platforms.map((p) => (
        <span key={p} className="qa-tag">
          <FormattedMessage id={`qa.platform.${p}`} />
        </span>
      ))}
    </span>
  );
}

export function QaCaseTable({
  rows,
  results,
  hasRun,
  filters,
  onFilters,
  onOpen,
}: {
  rows: QaCase[];
  results: Record<string, QaResult>;
  hasRun: boolean;
  filters: QaFilters;
  onFilters: (f: QaFilters) => void;
  onOpen: (caseId: string) => void;
}) {
  const intl = useIntl();
  const t = (id: string) => intl.formatMessage({ id });
  const select = <K extends 'level' | 'platform' | 'status'>(
    key: K,
    options: readonly string[],
    labelPrefix: string,
  ) => (
    <select
      className="select"
      value={filters[key]}
      aria-label={t(`qa.filter.${key}`)}
      onChange={(e) => onFilters({ ...filters, [key]: e.target.value })}
    >
      <option value="all">
        {intl.formatMessage({ id: 'qa.filter.any' }, { filter: t(`qa.filter.${key}`) })}
      </option>
      {options.map((o) => (
        <option key={o} value={o}>
          {t(`${labelPrefix}.${o}`)}
        </option>
      ))}
    </select>
  );
  return (
    <Panel className="panel--flush">
      <div className="panel__pad toolbar">
        <h2 className="panel__title">
          <FormattedMessage id="qa.table.title" />{' '}
          <span className="count">{intl.formatNumber(rows.length)}</span>
        </h2>
        <div className="qa-filters">
          <input
            className="search"
            type="search"
            value={filters.q}
            onChange={(e) => onFilters({ ...filters, q: e.target.value })}
            placeholder={t('qa.table.search')}
            aria-label={t('qa.table.search')}
          />
          {select('level', qaLevels, 'qa.level')}
          {select('platform', qaPlatforms, 'qa.platform')}
          {hasRun && select('status', qaStatuses, 'qa.status')}
        </div>
      </div>
      {rows.length === 0 ? (
        <Empty>
          <FormattedMessage id="qa.table.empty" />
        </Empty>
      ) : (
        <TableScroll min={760}>
          <table className="table qa-table">
            <thead>
              <tr>
                <th>
                  <FormattedMessage id="qa.col.id" />
                </th>
                <th>
                  <FormattedMessage id="qa.col.case" />
                </th>
                <th>
                  <FormattedMessage id="qa.col.module" />
                </th>
                <th>
                  <FormattedMessage id="qa.col.level" />
                </th>
                <th>
                  <FormattedMessage id="qa.col.platforms" />
                </th>
                {hasRun && (
                  <th>
                    <FormattedMessage id="qa.col.status" />
                  </th>
                )}
              </tr>
            </thead>
            <tbody>
              {rows.map((c) => {
                const r = results[c.id];
                const status = r?.status ?? 'notRun';
                return (
                  <tr key={c.id} className="qa-table__row" onClick={() => onOpen(c.id)}>
                    <td className="mono">{c.id}</td>
                    <td>
                      <button
                        type="button"
                        className="qa-title-btn"
                        onClick={(e) => {
                          e.stopPropagation();
                          onOpen(c.id);
                        }}
                      >
                        {c.title}
                      </button>
                    </td>
                    <td className="muted">
                      <FormattedMessage id={`qa.module.${c.module}`} />
                    </td>
                    <td>
                      <Pill tone={levelTone[c.level]}>
                        <FormattedMessage id={`qa.level.${c.level}`} />
                      </Pill>
                    </td>
                    <td>
                      <PlatformTags platforms={c.platforms} />
                    </td>
                    {hasRun && (
                      <td className="nowrap">
                        <Pill tone={statusTone[status]}>
                          <FormattedMessage id={`qa.status.${status}`} />
                        </Pill>
                        {(r?.comments ?? 0) > 0 && (
                          <p className="muted">
                            <FormattedMessage id="qa.table.comments" values={{ n: r!.comments }} />
                          </p>
                        )}
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
  );
}

// ---------- One case ----------

function Icon({ d }: { d: string }) {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true">
      <path fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" d={d} />
    </svg>
  );
}

/** The case sheet on the right: Escape or the backdrop closes it. */
export function QaCaseDrawer({
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
  const ref = useRef<HTMLElement>(null);
  useScrollLock();
  useEscape(onClose);
  useEffect(() => {
    ref.current?.focus();
  }, []);
  return (
    <div
      className="scrim scrim--drawer"
      onMouseDown={(e) => e.target === e.currentTarget && onClose()}
    >
      <aside
        className="drawer"
        role="dialog"
        aria-modal="true"
        aria-label={title}
        ref={ref}
        tabIndex={-1}
      >
        <div className="drawer__tools">
          <button
            type="button"
            className="icon-btn"
            onClick={onPrev}
            disabled={!onPrev}
            aria-label={intl.formatMessage({ id: 'qa.case.prev' })}
          >
            <Icon d="M15 18l-6-6 6-6" />
          </button>
          <button
            type="button"
            className="icon-btn"
            onClick={onNext}
            disabled={!onNext}
            aria-label={intl.formatMessage({ id: 'qa.case.next' })}
          >
            <Icon d="M9 18l6-6-6-6" />
          </button>
          <button
            type="button"
            className="icon-btn"
            onClick={onClose}
            aria-label={intl.formatMessage({ id: 'qa.case.close' })}
          >
            <Icon d="M6 6l12 12M18 6L6 18" />
          </button>
        </div>
        {children}
      </aside>
    </div>
  );
}

export function QaCaseDetail({
  item,
  run,
  result,
  canTest,
  canManage,
  busy,
  error,
  now,
  onStatus,
  onEdit,
  onArchive,
  children,
}: {
  item: QaCase;
  run: QaRun | null;
  result: QaResult | null;
  canTest: boolean;
  canManage: boolean;
  busy: boolean;
  error: ApiError | null;
  now: Date;
  onStatus: (s: QaStatus) => void;
  onEdit: () => void;
  onArchive: () => void;
  children?: ReactNode;
}) {
  const intl = useIntl();
  const status = result?.status ?? 'notRun';
  const editable = !!run && !run.archived && canTest && !item.archived;
  return (
    <>
      <header className="drawer__head">
        <p className="mono muted">
          {item.id} · <FormattedMessage id={`qa.module.${item.module}`} />
        </p>
        <h2 className="drawer__title">{item.title}</h2>
        <div className="chips">
          <Pill tone={levelTone[item.level]}>
            <FormattedMessage id={`qa.level.${item.level}`} />
          </Pill>
          <PlatformTags platforms={item.platforms} />
          {item.archived && (
            <Pill tone="muted">
              <FormattedMessage id="qa.case.archivedTag" />
            </Pill>
          )}
          {!item.builtin && (
            <Pill tone="purple">
              <FormattedMessage id="qa.case.added" />
            </Pill>
          )}
          {item.edited && (
            <Pill tone="info">
              <FormattedMessage id="qa.case.edited" />
            </Pill>
          )}
        </div>
      </header>
      <div className="drawer__body">
        {item.account && (
          <section>
            <h3 className="label">
              <FormattedMessage id="qa.case.account" />
            </h3>
            <p className="qa-prose">{item.account}</p>
          </section>
        )}
        <section>
          <h3 className="label">
            <FormattedMessage id="qa.case.steps" />
          </h3>
          <ol className="qa-list">
            {item.steps.map((s, i) => (
              <li key={i}>{s}</li>
            ))}
          </ol>
        </section>
        <section>
          <h3 className="label">
            <FormattedMessage id="qa.case.expected" />
          </h3>
          <ul className="qa-list">
            {item.expected.map((s, i) => (
              <li key={i}>{s}</li>
            ))}
          </ul>
        </section>
        {item.refs.length > 0 && (
          <p className="muted">
            <FormattedMessage id="qa.case.refs" values={{ refs: item.refs.join(' · ') }} />
          </p>
        )}

        <hr className="qa-divider" />
        <section className="qa-result">
          <div className="qa-result__head">
            <h3 className="label">
              <FormattedMessage id="qa.case.result" />
            </h3>
            {run && (
              <Pill tone={statusTone[status]}>
                <FormattedMessage id={`qa.status.${status}`} />
              </Pill>
            )}
          </div>
          {!run ? (
            <p className="muted">
              <FormattedMessage id="qa.case.noRun" />
            </p>
          ) : (
            <>
              {editable && (
                <Segmented
                  label={intl.formatMessage({ id: 'qa.case.result' })}
                  value={status}
                  onChange={(s) => !busy && s !== status && onStatus(s)}
                  options={qaStatuses.map((s) => ({
                    value: s,
                    label: <FormattedMessage id={`qa.status.${s}`} />,
                  }))}
                />
              )}
              {result?.by && result.at && (
                <p className="muted">
                  <FormattedMessage
                    id="qa.case.lastSet"
                    values={{ name: result.by, when: when(intl, result.at, now) }}
                  />
                </p>
              )}
              {run.archived && (
                <p className="note note--warn">
                  <FormattedMessage id="qa.case.archivedRun" />
                </p>
              )}
            </>
          )}
          {error && (
            <p className="error" role="alert">
              <FormattedMessage id={errorMessageId(error)} />
            </p>
          )}
        </section>

        {children}

        {canManage && (
          <>
            <hr className="qa-divider" />
            <div className="actions">
              <Button onClick={onEdit} disabled={busy}>
                <FormattedMessage id="qa.case.edit" />
              </Button>
              <Button kind="ghost" onClick={onArchive} disabled={busy}>
                <FormattedMessage id={item.archived ? 'qa.case.restore' : 'qa.case.archive'} />
              </Button>
            </div>
            {item.updatedBy && item.updatedAt && (
              <p className="muted">
                <FormattedMessage
                  id="qa.case.updated"
                  values={{ name: item.updatedBy, when: when(intl, item.updatedAt, now) }}
                />
              </p>
            )}
          </>
        )}
      </div>
    </>
  );
}

export function QaCommentList({ comments, now }: { comments: QaComment[]; now: Date }) {
  const intl = useIntl();
  if (comments.length === 0) {
    return (
      <p className="muted">
        <FormattedMessage id="qa.case.noComments" />
      </p>
    );
  }
  return (
    <ul className="thread">
      {comments.map((c) => (
        <li key={c.id}>
          <p className="muted">
            {c.by} · {when(intl, c.at, now)}
          </p>
          <p className="thread__text">{c.text}</p>
        </li>
      ))}
    </ul>
  );
}

function QaComments({
  runId,
  caseId,
  canComment,
  now,
  onAdded,
}: {
  runId: string;
  caseId: string;
  canComment: boolean;
  now: Date;
  onAdded: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const [load, reload] = useLoad<{ comments: QaComment[] }>(
    'staffQaCase',
    { runId, caseId },
    `${runId}|${caseId}`,
  );
  const [text, setText] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const placeholder = intl.formatMessage({ id: 'qa.case.commentPlaceholder' });
  return (
    <section className="qa-comments">
      <h3 className="label">
        <FormattedMessage id="qa.case.comments" />
      </h3>
      <Loaded load={load} reload={reload}>
        {(d) => <QaCommentList comments={d.comments} now={now} />}
      </Loaded>
      {canComment && (
        <form
          className="composer"
          onSubmit={(e) => {
            e.preventDefault();
            setBusy(true);
            setError(null);
            api
              .call('staffQaUpdate', { op: 'comment', runId, caseId, text: text.trim() })
              .then(() => {
                setText('');
                reload();
                onAdded();
              })
              .catch((err: unknown) => setError(asApiError(err)))
              .finally(() => setBusy(false));
          }}
        >
          <textarea
            className="field__input"
            rows={3}
            maxLength={2000}
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder={placeholder}
            aria-label={placeholder}
          />
          {error && (
            <p className="error" role="alert">
              <FormattedMessage id={errorMessageId(error)} />
            </p>
          )}
          <div className="composer__foot">
            <span className="muted">
              <FormattedMessage id="qa.case.privacy" />
            </span>
            <Button kind="primary" type="submit" disabled={busy || !text.trim()}>
              <FormattedMessage id="qa.case.addComment" />
            </Button>
          </div>
        </form>
      )}
    </section>
  );
}

// ---------- Dialogs ----------

export function QaRunDialog({
  busy,
  error,
  onClose,
  onCreate,
}: {
  busy: boolean;
  error: ApiError | null;
  onClose: () => void;
  onCreate: (req: { name: string; environment: QaEnvironment; notes: string }) => void;
}) {
  const intl = useIntl();
  const nameId = useId();
  const notesId = useId();
  const [name, setName] = useState('');
  const [environment, setEnvironment] = useState<QaEnvironment>('dev');
  const [notes, setNotes] = useState('');
  return (
    <Modal title={<FormattedMessage id="qa.newRun.title" />} onClose={onClose}>
      <form
        className="stack"
        onSubmit={(e) => {
          e.preventDefault();
          onCreate({ name: name.trim(), environment, notes: notes.trim() });
        }}
      >
        <div className="field">
          <label className="field__label" htmlFor={nameId}>
            <FormattedMessage id="qa.newRun.name" />
          </label>
          <input
            id={nameId}
            className="field__input"
            value={name}
            maxLength={60}
            onChange={(e) => setName(e.target.value)}
            placeholder={intl.formatMessage({ id: 'qa.newRun.namePlaceholder' })}
          />
        </div>
        <div className="field">
          <span className="field__label">
            <FormattedMessage id="qa.newRun.env" />
          </span>
          <Segmented
            label={intl.formatMessage({ id: 'qa.newRun.env' })}
            value={environment}
            onChange={setEnvironment}
            options={(['dev', 'prod'] as const).map((e) => ({
              value: e,
              label: <FormattedMessage id={`env.${e}`} />,
            }))}
          />
        </div>
        <div className="field">
          <label className="field__label" htmlFor={notesId}>
            <FormattedMessage id="qa.newRun.notes" />
          </label>
          <textarea
            id={notesId}
            className="field__input"
            rows={3}
            maxLength={500}
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder={intl.formatMessage({ id: 'qa.newRun.notesPlaceholder' })}
          />
        </div>
        {error && (
          <p className="error" role="alert">
            <FormattedMessage id={errorMessageId(error)} />
          </p>
        )}
        <div className="modal__actions">
          <Button onClick={onClose}>
            <FormattedMessage id="action.cancel" />
          </Button>
          <Button kind="primary" type="submit" disabled={busy || !name.trim()}>
            <FormattedMessage id="qa.newRun.create" />
          </Button>
        </div>
      </form>
    </Modal>
  );
}

const lines = (s: string) =>
  s
    .split('\n')
    .map((l) => l.trim())
    .filter(Boolean);

/** Mirrors `qaCaseContentSchema`, so the form only submits what the server accepts. */
export function caseFormValid(c: QaCaseContent): boolean {
  const ok = (list: string[]) =>
    list.length >= 1 && list.length <= 20 && list.every((l) => l.length <= 500);
  return (
    c.title.length >= 3 &&
    c.title.length <= 160 &&
    c.account.length <= 200 &&
    c.platforms.length >= 1 &&
    ok(c.steps) &&
    ok(c.expected)
  );
}

export function QaCaseDialog({
  edit,
  defaultModule,
  busy,
  error,
  onClose,
  onSave,
}: {
  edit: QaCase | null;
  defaultModule: QaModule;
  busy: boolean;
  error: ApiError | null;
  onClose: () => void;
  onSave: (content: QaCaseContent) => void;
}) {
  const intl = useIntl();
  const ids = {
    module: useId(),
    title: useId(),
    account: useId(),
    steps: useId(),
    expected: useId(),
  };
  const [module, setModule] = useState<QaModule>(edit?.module ?? defaultModule);
  const [level, setLevel] = useState<QaLevel>(edit?.level ?? 'core');
  const [platforms, setPlatforms] = useState<QaPlatform[]>(edit?.platforms ?? ['ios', 'android']);
  const [title, setTitle] = useState(edit?.title ?? '');
  const [account, setAccount] = useState(edit?.account ?? '');
  const [steps, setSteps] = useState(edit?.steps.join('\n') ?? '');
  const [expected, setExpected] = useState(edit?.expected.join('\n') ?? '');
  const content = useMemo<QaCaseContent>(
    () => ({
      module,
      level,
      // Kept in the catalog order, whatever order they were ticked in.
      platforms: qaPlatforms.filter((p) => platforms.includes(p)),
      title: title.trim(),
      account: account.trim(),
      steps: lines(steps),
      expected: lines(expected),
    }),
    [module, level, platforms, title, account, steps, expected],
  );
  const t = (id: string) => intl.formatMessage({ id });
  return (
    <Modal
      wide
      title={
        edit ? (
          <FormattedMessage id="qa.caseForm.editTitle" values={{ id: edit.id }} />
        ) : (
          <FormattedMessage id="qa.caseForm.newTitle" />
        )
      }
      onClose={onClose}
    >
      <form
        className="stack"
        onSubmit={(e) => {
          e.preventDefault();
          onSave(content);
        }}
      >
        {edit?.builtin && (
          <p className="note">
            <FormattedMessage id="qa.caseForm.builtinNote" />
          </p>
        )}
        <div className="qa-form__row">
          <div className="field">
            <label className="field__label" htmlFor={ids.module}>
              <FormattedMessage id="qa.caseForm.module" />
            </label>
            <select
              id={ids.module}
              className="field__input"
              value={module}
              onChange={(e) => setModule(e.target.value as QaModule)}
            >
              {qaModules.map((m) => (
                <option key={m} value={m}>
                  {t(`qa.module.${m}`)}
                </option>
              ))}
            </select>
          </div>
          <div className="field">
            <span className="field__label">
              <FormattedMessage id="qa.caseForm.level" />
            </span>
            <Segmented
              label={t('qa.caseForm.level')}
              value={level}
              onChange={setLevel}
              options={qaLevels.map((l) => ({
                value: l,
                label: <FormattedMessage id={`qa.level.${l}`} />,
              }))}
            />
          </div>
        </div>
        <div className="field">
          <span className="field__label">
            <FormattedMessage id="qa.caseForm.platforms" />
          </span>
          <div className="chips" role="group" aria-label={t('qa.caseForm.platforms')}>
            {qaPlatforms.map((p) => {
              const on = platforms.includes(p);
              return (
                <button
                  key={p}
                  type="button"
                  className={`chip ${on ? 'chip--on' : ''}`}
                  aria-pressed={on}
                  onClick={() =>
                    setPlatforms((list) => (on ? list.filter((x) => x !== p) : [...list, p]))
                  }
                >
                  <FormattedMessage id={`qa.platform.${p}`} />
                </button>
              );
            })}
          </div>
        </div>
        <div className="field">
          <label className="field__label" htmlFor={ids.title}>
            <FormattedMessage id="qa.caseForm.title" />
          </label>
          <input
            id={ids.title}
            className="field__input"
            value={title}
            maxLength={160}
            onChange={(e) => setTitle(e.target.value)}
          />
        </div>
        <div className="field">
          <label className="field__label" htmlFor={ids.account}>
            <FormattedMessage id="qa.caseForm.account" />
          </label>
          <input
            id={ids.account}
            className="field__input"
            value={account}
            maxLength={200}
            onChange={(e) => setAccount(e.target.value)}
            placeholder={t('qa.caseForm.accountPlaceholder')}
          />
        </div>
        <div className="field">
          <label className="field__label" htmlFor={ids.steps}>
            <FormattedMessage id="qa.caseForm.steps" />
          </label>
          <textarea
            id={ids.steps}
            className="field__input"
            rows={5}
            value={steps}
            onChange={(e) => setSteps(e.target.value)}
          />
        </div>
        <div className="field">
          <label className="field__label" htmlFor={ids.expected}>
            <FormattedMessage id="qa.caseForm.expected" />
          </label>
          <textarea
            id={ids.expected}
            className="field__input"
            rows={4}
            value={expected}
            onChange={(e) => setExpected(e.target.value)}
          />
          <p className="field__help">
            <FormattedMessage id="qa.caseForm.linesHelp" />
          </p>
        </div>
        {error && (
          <p className="error" role="alert">
            <FormattedMessage id={errorMessageId(error)} />
          </p>
        )}
        <div className="modal__actions">
          <Button onClick={onClose}>
            <FormattedMessage id="action.cancel" />
          </Button>
          <Button kind="primary" type="submit" disabled={busy || !caseFormValid(content)}>
            <FormattedMessage id="qa.caseForm.save" />
          </Button>
        </div>
      </form>
    </Modal>
  );
}
