import {
  assistantSwitchKeys,
  staffCan,
  type AssistantPoolPlan,
  type StaffAssistantSwitches,
  type StaffAssistantTask,
  type StaffAssistantUsage,
} from '@child-life/contracts';
import { Fragment, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { Input } from '@/components/ui/input';
import { Switch } from '@/components/ui/switch';
import { ApiError, useApi, useLoad, type Api } from '../api';
import { useNavigate, useStaff } from '../context';
import { ZONE, num, shortDate, vnd, when } from '../format';
import {
  Button,
  Empty,
  HBars,
  Kpi,
  Loaded,
  LockNote,
  Page,
  Panel,
  Pill,
  Segmented,
  StackedBars,
  TableScroll,
  errorMessageId,
  type PillTone,
} from '../ui';
import { AuditActionText, FlagDialog, ScopePill, type FlagChange } from './Features';
import { reservationTone } from './PremiumOps';

/**
 * Trợ lý AI (docs/assistant/architecture.md §5, slice A6): Usage (the household credit pool by
 * budget, tasks, errors, model counters), Tasks (one task by id, for support) and Switches (the
 * assistant kill switches, P-161). Aggregates, codes and states only — never a message, a draft's
 * content, a clarification answer, a health sign or a photo; families and babies as codes.
 * Credit settings stay in Premium › Cấu hình (D-075 #1); switching uses the Features dialog
 * (`staffSetFlag`: role `flags.toggle`, reason, audit).
 */
export function AssistantScreen() {
  const intl = useIntl();
  const [tab, setTab] = useState<AssistantTab>('usage');
  return (
    <Page
      title={<FormattedMessage id="assistant.title" />}
      subtitle={<FormattedMessage id="assistant.sub" />}
      actions={
        <AssistantTabs
          label={intl.formatMessage({ id: 'assistant.tabs' })}
          value={tab}
          onChange={setTab}
        />
      }
    >
      {tab === 'usage' ? <UsageLoader /> : tab === 'tasks' ? <TaskLookup /> : <SwitchesLoader />}
    </Page>
  );
}

export type AssistantTab = 'usage' | 'tasks' | 'switches';

export function AssistantTabs({
  label,
  value,
  onChange,
}: {
  label: string;
  value: AssistantTab;
  onChange: (t: AssistantTab) => void;
}) {
  return (
    <Segmented
      label={label}
      value={value}
      onChange={onChange}
      options={(['usage', 'tasks', 'switches'] as const).map((t) => ({
        value: t,
        label: <FormattedMessage id={`assistant.tab.${t}`} />,
      }))}
    />
  );
}

function Th({ id }: { id: string }) {
  return (
    <th>
      <FormattedMessage id={id} />
    </th>
  );
}

const seconds = (intl: IntlShape, ms: number | null) =>
  ms === null
    ? '—'
    : intl.formatMessage(
        { id: 'assistant.seconds' },
        { n: intl.formatNumber(ms / 1000, { maximumFractionDigits: 1 }) },
      );

// ---------- Usage ----------

function UsageLoader() {
  const [load, reload] = useLoad<StaffAssistantUsage>('staffAssistantUsage', {}, 'assistantUsage');
  return (
    <Loaded load={load} reload={reload}>
      {(data) => <UsageView data={data} />}
    </Loaded>
  );
}

const planTone: Record<AssistantPoolPlan, PillTone> = {
  free: 'muted',
  premium: 'ok',
  beta: 'purple',
};

/** Counts as horizontal bars, largest first, with a label per key. */
function CountBars({ counts, prefix }: { counts: Record<string, number>; prefix: string }) {
  const intl = useIntl();
  const rows = Object.entries(counts)
    .filter(([, n]) => n > 0)
    .sort((a, b) => b[1] - a[1]);
  const max = Math.max(1, ...rows.map(([, n]) => n));
  if (rows.length === 0) {
    return (
      <p className="muted">
        <FormattedMessage id="assistant.noTasks" />
      </p>
    );
  }
  return (
    <HBars
      rows={rows.map(([k, n]) => ({
        label: <FormattedMessage id={`${prefix}.${k}`} />,
        value: num(intl, n),
        ratio: n / max,
      }))}
    />
  );
}

export function UsageView({ data }: { data: StaffAssistantUsage }) {
  const intl = useIntl();
  const navigate = useNavigate();
  const committed = data.pool.reduce((n, p) => n + p.committed, 0);
  const released = data.pool.reduce((n, p) => n + p.released, 0);
  const held = data.pool.reduce((n, p) => n + p.held, 0);
  const t = data.tasks;
  const m = data.model;
  const top = t.errors[0];
  const errorMax = Math.max(1, ...t.errors.map((e) => e.count));
  const c = data.credits;
  return (
    <div className="grid">
      <LockNote>
        <FormattedMessage id="assistant.usage.lock" />
      </LockNote>
      {(data.truncated.tasks || data.truncated.ops) && (
        <p className="muted" role="note">
          <FormattedMessage id="assistant.usage.truncated" />
        </p>
      )}
      <div className="kpis">
        <Kpi
          label={<FormattedMessage id="assistant.kpi.tasks" />}
          value={num(intl, t.total)}
          foot={
            <FormattedMessage
              id="assistant.kpi.tasksFoot"
              values={{ health: t.health, blocked: t.byState.blocked ?? 0 }}
            />
          }
        />
        <Kpi
          label={<FormattedMessage id="assistant.kpi.credits" />}
          value={num(intl, committed)}
          foot={<FormattedMessage id="assistant.kpi.creditsFoot" values={{ released, held }} />}
        />
        <Kpi
          label={<FormattedMessage id="assistant.kpi.failed" />}
          value={num(intl, t.byState.failed ?? 0)}
          tone={t.byState.failed ? 'warn' : 'muted'}
          foot={
            top ? (
              <FormattedMessage id="assistant.kpi.failedFoot" values={{ code: top.code }} />
            ) : (
              <FormattedMessage id="assistant.noErrors" />
            )
          }
        />
        <Kpi
          label={<FormattedMessage id="assistant.kpi.calls" />}
          value={num(intl, m.calls)}
          foot={
            <FormattedMessage
              id="assistant.kpi.callsFoot"
              values={{ cost: vnd(intl, m.estimatedCostVnd) }}
            />
          }
        />
      </div>
      <div className="cols cols--2-1">
        <Panel
          title={<FormattedMessage id="assistant.daily" />}
          note={<FormattedMessage id="assistant.daily.note" />}
        >
          <StackedBars
            title={intl.formatMessage({ id: 'assistant.daily' })}
            series={data.daily}
            labels={data.daily.map((d) => shortDate(intl, `${d.day}T12:00:00+07:00`))}
            keys={(['committed', 'released'] as const).map((key) => ({
              key,
              label: intl.formatMessage({ id: `assistant.daily.${key}` }),
              className: `credits-${key}`,
            }))}
          />
        </Panel>
        <Panel
          title={<FormattedMessage id="assistant.credits" />}
          note={<FormattedMessage id="assistant.credits.note" />}
          aside={
            <Button kind="ghost" onClick={() => navigate('premium')}>
              <FormattedMessage id="assistant.credits.open" />
            </Button>
          }
        >
          <dl className="kv">
            {(
              [
                ['free', c.free],
                ['premium', c.premium],
                ['text', c.textCredits],
                ['image', c.imageCredits],
                ['summary', c.aiSummaryCredits],
              ] as const
            ).map(([k, n]) => (
              <Fragment key={k}>
                <dt>
                  <FormattedMessage id={`assistant.credits.${k}`} />
                </dt>
                <dd>
                  <FormattedMessage id="assistant.credits.value" values={{ n }} />
                </dd>
              </Fragment>
            ))}
          </dl>
          {!c.stored && (
            <p className="muted">
              <FormattedMessage id="assistant.credits.default" />
            </p>
          )}
        </Panel>
      </div>
      <Panel
        title={<FormattedMessage id="assistant.pool" />}
        note={<FormattedMessage id="assistant.pool.note" />}
        className="panel--flush"
      >
        <TableScroll min={720}>
          <table className="table">
            <thead>
              <tr>
                <Th id="assistant.pool.col.plan" />
                <Th id="assistant.pool.col.committed" />
                <Th id="assistant.pool.col.released" />
                <Th id="assistant.pool.col.held" />
                <Th id="assistant.pool.col.households" />
                <Th id="assistant.pool.col.exhausted" />
              </tr>
            </thead>
            <tbody>
              {data.pool.map((p) => (
                <tr key={p.plan}>
                  <td>
                    <Pill tone={planTone[p.plan]}>
                      <FormattedMessage id={`assistant.plan.${p.plan}`} />
                    </Pill>
                  </td>
                  <td>
                    {num(intl, p.committed)}
                    <br />
                    <span className="muted">
                      <FormattedMessage
                        id="assistant.pool.split"
                        values={{ chat: p.chat, summaries: p.summaries }}
                      />
                    </span>
                  </td>
                  <td>{num(intl, p.released)}</td>
                  <td>{num(intl, p.held)}</td>
                  <td>{num(intl, p.households)}</td>
                  <td>{p.exhausted ? <Pill tone="warn">{num(intl, p.exhausted)}</Pill> : 0}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      </Panel>
      <div className="cols cols--1-1">
        <Panel title={<FormattedMessage id="assistant.states" />}>
          <CountBars counts={t.byState} prefix="assistant.state" />
        </Panel>
        <Panel title={<FormattedMessage id="assistant.outcomes" />}>
          <CountBars counts={t.byOutcome} prefix="assistant.outcome" />
          <dl className="kv mt-4">
            {(['text', 'image'] as const).map((k) => (
              <Fragment key={k}>
                <dt>
                  <FormattedMessage id={`assistant.modality.${k}`} />
                </dt>
                <dd>{num(intl, t.byModality[k] ?? 0)}</dd>
              </Fragment>
            ))}
            <dt>
              <FormattedMessage id="assistant.health" />
            </dt>
            <dd>{num(intl, t.health)}</dd>
          </dl>
        </Panel>
      </div>
      <div className="cols cols--1-1">
        <Panel
          title={<FormattedMessage id="assistant.errors" />}
          note={<FormattedMessage id="assistant.errors.note" />}
        >
          {t.errors.length === 0 ? (
            <p className="muted">
              <FormattedMessage id="assistant.noErrors" />
            </p>
          ) : (
            <HBars
              rows={t.errors.map((e) => ({
                label: <span className="mono">{e.code}</span>,
                value: num(intl, e.count),
                ratio: e.count / errorMax,
              }))}
            />
          )}
        </Panel>
        <Panel
          title={<FormattedMessage id="assistant.model" />}
          note={<FormattedMessage id="assistant.model.note" />}
        >
          <dl className="kv">
            <dt>
              <FormattedMessage id="assistant.model.calls" />
            </dt>
            <dd>
              <FormattedMessage
                id="assistant.model.callsValue"
                values={{ calls: m.calls, tasks: m.tasksWithCalls }}
              />
            </dd>
            <dt>
              <FormattedMessage id="assistant.model.cost" />
            </dt>
            <dd>{vnd(intl, m.estimatedCostVnd)}</dd>
            <dt>
              <FormattedMessage id="assistant.model.timeToReady" />
            </dt>
            <dd>
              {m.timeToReady.samples === 0 ? (
                <span className="muted">
                  <FormattedMessage id="assistant.model.noSamples" />
                </span>
              ) : (
                <FormattedMessage
                  id="assistant.model.timeValue"
                  values={{
                    p50: seconds(intl, m.timeToReady.p50Ms),
                    p95: seconds(intl, m.timeToReady.p95Ms),
                    n: m.timeToReady.samples,
                  }}
                />
              )}
            </dd>
            <dt>
              <FormattedMessage
                id="assistant.model.budget"
                values={{
                  month: intl.formatDate(`${data.budget.month}-15`, {
                    month: 'long',
                    timeZone: ZONE,
                  }),
                }}
              />
            </dt>
            <dd>
              {vnd(intl, data.budget.spentVnd)} / {vnd(intl, data.budget.monthlyBudgetVnd)}
            </dd>
          </dl>
          {m.byModel.length > 0 && (
            <TableScroll min={420}>
              <table className="table mt-4">
                <thead>
                  <tr>
                    <Th id="assistant.model.col.model" />
                    <Th id="assistant.model.col.prompt" />
                    <Th id="assistant.model.col.tasks" />
                    <Th id="assistant.model.col.calls" />
                  </tr>
                </thead>
                <tbody>
                  {m.byModel.map((r) => (
                    <tr key={`${r.model}|${r.promptVersion ?? ''}`}>
                      <td className="mono">{r.model}</td>
                      <td className="mono">{r.promptVersion ?? '—'}</td>
                      <td>{num(intl, r.tasks)}</td>
                      <td>{num(intl, r.calls)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </TableScroll>
          )}
        </Panel>
      </div>
    </div>
  );
}

// ---------- Tasks ----------

const taskIdPattern = /^tk_[a-f0-9]{32}$/;

/** Looks one task up; a malformed id never reaches the server. */
export async function lookupTask(
  api: Api,
  raw: string,
): Promise<{ ok: true; task: StaffAssistantTask } | { ok: false; problem: string }> {
  const taskId = raw.trim().toLowerCase();
  if (!taskIdPattern.test(taskId)) return { ok: false, problem: 'assistant.lookup.hint' };
  try {
    return { ok: true, task: await api.call<StaffAssistantTask>('staffAssistantTask', { taskId }) };
  } catch (e) {
    return {
      ok: false,
      problem: errorMessageId(e instanceof ApiError ? e : new ApiError('unknown', null)),
    };
  }
}

export function TaskLookup({ initial = null }: { initial?: StaffAssistantTask | null }) {
  const intl = useIntl();
  const api = useApi();
  const [id, setId] = useState(initial?.taskId ?? '');
  const [task, setTask] = useState<StaffAssistantTask | null>(initial);
  const [busy, setBusy] = useState(false);
  const [problem, setProblem] = useState<string | null>(null);
  const look = async () => {
    setBusy(true);
    setProblem(null);
    const answer = await lookupTask(api, id);
    if (answer.ok) setTask(answer.task);
    else {
      setTask(null);
      setProblem(answer.problem);
    }
    setBusy(false);
  };
  return (
    <div className="grid">
      <Panel
        title={<FormattedMessage id="assistant.lookup.title" />}
        note={<FormattedMessage id="assistant.lookup.note" />}
      >
        <div className="family-picker__row">
          <Input
            value={id}
            onChange={(e) => setId(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault();
                void look();
              }
            }}
            placeholder="tk_…"
            aria-label={intl.formatMessage({ id: 'assistant.lookup.id' })}
          />
          <Button kind="primary" disabled={busy || !id.trim()} onClick={() => void look()}>
            <FormattedMessage id="assistant.lookup.go" />
          </Button>
        </div>
        {problem && (
          <p className="error" role="alert">
            <FormattedMessage id={problem} />
          </p>
        )}
        <LockNote>
          <FormattedMessage id="assistant.task.lock" />
        </LockNote>
      </Panel>
      {task && <TaskView task={task} now={new Date()} />}
    </div>
  );
}

const stateTone: Record<string, PillTone> = {
  ready: 'ok',
  failed: 'error',
  canceled: 'muted',
  blocked: 'warn',
  awaiting_clarification: 'wait',
  queued: 'info',
  processing: 'info',
  received: 'info',
  uploading: 'info',
};

function Row({ label, children }: { label: string; children: ReactNode }) {
  return (
    <>
      <dt>
        <FormattedMessage id={label} />
      </dt>
      <dd>{children}</dd>
    </>
  );
}

export function TaskView({ task, now }: { task: StaffAssistantTask; now: Date }) {
  const intl = useIntl();
  const at = (iso: string | null) => (iso ? when(intl, iso, now) : '—');
  const r = task.reservation;
  return (
    <>
      <div className="cols cols--1-1">
        <Panel title={<span className="mono">{task.taskId}</span>}>
          <dl className="kv">
            <Row label="assistant.task.family">
              <span className="mono">{task.family}</span> ·{' '}
              <span className="mono">{task.baby}</span>
            </Row>
            <Row label="assistant.task.scope">
              <FormattedMessage id={`assistant.task.scope.${task.scope}`} /> ·{' '}
              <FormattedMessage id={`assistant.task.visibility.${task.visibility}`} />
            </Row>
            <Row label="assistant.task.state">
              <Pill tone={stateTone[task.state] ?? 'muted'}>
                <FormattedMessage id={`assistant.state.${task.state}`} />
              </Pill>
              {task.errorCode && (
                <>
                  {' '}
                  <span className="mono">{task.errorCode}</span>
                </>
              )}
            </Row>
            <Row label="assistant.task.modality">
              <FormattedMessage id={`assistant.modality.${task.modality}`} />
            </Row>
            <Row label="assistant.task.plan">
              <FormattedMessage id={`assistant.plan.${task.pool ?? task.plan}`} />
            </Row>
            <Row label="assistant.task.credits">
              <FormattedMessage
                id="assistant.task.creditsValue"
                values={{
                  n: task.credits,
                  usage: intl.formatMessage({ id: `assistant.usage.${task.usage}` }),
                }}
              />
            </Row>
            <Row label="assistant.task.outcome">
              {task.outcome ? (
                <FormattedMessage
                  id="assistant.task.outcomeValue"
                  values={{
                    kind: intl.formatMessage({ id: `assistant.outcome.${task.outcome.kind}` }),
                    drafts: task.outcome.drafts,
                  }}
                />
              ) : (
                <FormattedMessage id="assistant.outcome.none" />
              )}
            </Row>
            <Row label="assistant.health">
              <FormattedMessage id={task.health ? 'premium.yes' : 'premium.no'} />
            </Row>
            <Row label="assistant.task.rounds">
              {task.clarifications.length === 0 ? (
                '—'
              ) : (
                <ul className="m-0 grid list-none gap-1 p-0">
                  {task.clarifications.map((c, i) => (
                    <li key={i}>
                      <FormattedMessage
                        id="assistant.task.clarification"
                        values={{
                          field: c.field,
                          round: c.round,
                          answered: String(c.answered),
                        }}
                      />
                    </li>
                  ))}
                </ul>
              )}
            </Row>
            <Row label="assistant.task.model">
              <span className="mono">{task.model ?? '—'}</span>
              <br />
              <span className="muted">
                <FormattedMessage
                  id="assistant.task.modelValue"
                  values={{ calls: task.modelCalls, attempts: task.attempt }}
                />
              </span>
            </Row>
            <Row label="assistant.task.versions">
              <span className="mono">
                {task.promptVersion ?? '—'} · {task.policyVersion ?? '—'}
              </span>
            </Row>
            {task.careTopic && (
              <Row label="assistant.task.care">
                <span className="mono">{task.careTopic}</span>
              </Row>
            )}
          </dl>
        </Panel>
        <div className="stack">
          <Panel title={<FormattedMessage id="assistant.task.times" />}>
            <dl className="kv">
              <Row label="assistant.task.created">{at(task.createdAt)}</Row>
              <Row label="assistant.task.ready">{at(task.readyAt)}</Row>
              <Row label="assistant.task.updated">{at(task.updatedAt)}</Row>
              <Row label="assistant.task.clarExpires">{at(task.clarificationExpiresAt)}</Row>
              <Row label="assistant.task.lease">{at(task.leaseUntil)}</Row>
            </dl>
          </Panel>
          <Panel title={<FormattedMessage id="assistant.task.reservation" />}>
            {r ? (
              <>
                <p>
                  <Pill tone={r.state ? reservationTone[r.state] : 'muted'}>
                    <FormattedMessage id={`render.state.${r.state ?? 'none'}`} />
                  </Pill>{' '}
                  <FormattedMessage id="assistant.credits.value" values={{ n: r.units }} />
                </p>
                <p className="muted mono">
                  {r.window} · {r.id}
                </p>
                <dl className="kv">
                  <Row label="assistant.task.reservedAt">{at(r.reservedAt)}</Row>
                  <Row label="assistant.task.committedAt">{at(r.committedAt)}</Row>
                  <Row label="assistant.task.releasedAt">
                    {at(r.releasedAt)}
                    {r.releaseReason && <span className="muted mono"> · {r.releaseReason}</span>}
                  </Row>
                </dl>
              </>
            ) : (
              <p className="muted">
                <FormattedMessage id="assistant.task.noReservation" />
              </p>
            )}
          </Panel>
        </div>
      </div>
      <Panel title={<FormattedMessage id="assistant.task.drafts" />} className="panel--flush">
        {task.drafts.length === 0 ? (
          <Empty>
            <FormattedMessage id="assistant.task.noDrafts" />
          </Empty>
        ) : (
          <TableScroll min={760}>
            <table className="table">
              <thead>
                <tr>
                  <Th id="assistant.task.col.draft" />
                  <Th id="assistant.task.col.kind" />
                  <Th id="col.status" />
                  <Th id="assistant.task.col.review" />
                  <Th id="assistant.task.col.times" />
                </tr>
              </thead>
              <tbody>
                {task.drafts.map((d) => (
                  <tr key={d.id}>
                    <td className="mono">
                      {d.id}
                      <br />
                      <span className="muted">r{d.revision}</span>
                    </td>
                    <td>
                      {d.kind ? <FormattedMessage id={`assistant.draft.kind.${d.kind}`} /> : '—'}
                    </td>
                    <td>
                      <FormattedMessage id={`assistant.draft.state.${d.state}`} />
                      {d.errorCode && <span className="muted mono"> · {d.errorCode}</span>}
                    </td>
                    <td className="mono">
                      {[...d.missingFields, ...d.uncertainFields, ...d.warnings].join(', ') || '—'}
                    </td>
                    <td className="nowrap">
                      {d.savedAt ? (
                        <FormattedMessage
                          id="assistant.task.savedAt"
                          values={{ at: at(d.savedAt) }}
                        />
                      ) : (
                        <FormattedMessage
                          id="assistant.task.expiresAt"
                          values={{ at: at(d.expiresAt) }}
                        />
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </TableScroll>
        )}
      </Panel>
      <div className="cols cols--1-1">
        <Panel title={<FormattedMessage id="assistant.task.attachments" />}>
          {task.attachments.length === 0 ? (
            <p className="muted">
              <FormattedMessage id="assistant.task.noAttachments" />
            </p>
          ) : (
            <ul className="m-0 grid list-none gap-1 p-0">
              {task.attachments.map((a, i) => (
                <li key={i}>
                  <FormattedMessage id={`assistant.attachment.state.${a.state}`} />
                  {a.retention && (
                    <span className="muted">
                      {' · '}
                      <FormattedMessage id={`assistant.attachment.retention.${a.retention}`} />
                    </span>
                  )}
                  {a.rejected && (
                    <>
                      {' '}
                      <Pill tone="warn">
                        <FormattedMessage id="assistant.attachment.rejected" />
                      </Pill>
                    </>
                  )}
                </li>
              ))}
            </ul>
          )}
        </Panel>
        <Panel
          title={<FormattedMessage id="assistant.task.events" />}
          note={<FormattedMessage id="assistant.task.eventsNote" />}
        >
          {task.events.length === 0 ? (
            <p className="muted">
              <FormattedMessage id="assistant.task.noEvents" />
            </p>
          ) : (
            <ol className="m-0 grid list-none gap-1 p-0">
              {task.events.map((e) => (
                <li key={e.sequence}>
                  <span className="muted">#{e.sequence}</span>{' '}
                  <span className="mono">{e.type}</span> <span className="muted">· {at(e.at)}</span>
                </li>
              ))}
            </ol>
          )}
        </Panel>
      </div>
    </>
  );
}

// ---------- Switches ----------

function SwitchesLoader() {
  const [load, reload] = useLoad<StaffAssistantSwitches>(
    'staffAssistantSwitches',
    {},
    'assistantSwitches',
  );
  return (
    <Loaded load={load} reload={reload}>
      {(data) => <SwitchesView data={data} onChanged={reload} />}
    </Loaded>
  );
}

export function SwitchesView({
  data,
  onChanged,
}: {
  data: StaffAssistantSwitches;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const staff = useStaff();
  const navigate = useNavigate();
  const canToggle = staffCan(staff.levels, 'flags.toggle');
  const [change, setChange] = useState<FlagChange | null>(null);
  return (
    <div className="cols cols--2-1">
      <Panel
        title={<FormattedMessage id="assistant.switches" />}
        aside={
          <Button kind="ghost" onClick={() => navigate('features')}>
            <FormattedMessage id="assistant.switches.open" />
          </Button>
        }
        className="panel--flush"
      >
        <div className="panel__pad">
          <LockNote>
            <FormattedMessage id="assistant.switches.lock" />
          </LockNote>
        </div>
        <TableScroll min={640}>
          <table className="table">
            <thead>
              <tr>
                <Th id="col.feature" />
                <Th id="col.scope" />
                <Th id="col.lastEdit" />
                <Th id="col.on" />
              </tr>
            </thead>
            <tbody>
              {assistantSwitchKeys.map((key) => {
                const f = data.flags[key];
                const last = data.lastEdit[key];
                return (
                  <tr key={key}>
                    <td>
                      <strong>
                        <FormattedMessage id={`flag.${key}`} />
                      </strong>
                      <br />
                      <span className="muted">
                        <FormattedMessage id={`flag.${key}.desc`} />
                      </span>
                      <br />
                      <span className="muted">
                        <FormattedMessage id="assistant.switches.whenOff" />{' '}
                        <FormattedMessage id={`flag.${key}.offEffect`} />
                      </span>
                    </td>
                    <td>{f.enabled ? <ScopePill flag={f} /> : <span className="muted">—</span>}</td>
                    <td className="muted">
                      {last ? `${last.by.split(' ')[0]} · ${shortDate(intl, last.at)}` : '—'}
                    </td>
                    <td>
                      <Switch
                        checked={f.enabled}
                        aria-label={intl.formatMessage({ id: `flag.${key}` })}
                        disabled={!canToggle}
                        title={
                          canToggle ? undefined : intl.formatMessage({ id: 'features.toggleRole' })
                        }
                        onCheckedChange={() =>
                          setChange({
                            key,
                            kind: f.enabled ? 'off' : 'on',
                            next: { ...f, enabled: !f.enabled, notice: null },
                          })
                        }
                      />
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </TableScroll>
      </Panel>
      <Panel title={<FormattedMessage id="assistant.switches.recent" />}>
        {data.recent.length === 0 ? (
          <p className="muted">
            <FormattedMessage id="assistant.switches.noRecent" />
          </p>
        ) : (
          <ul className="recent">
            {data.recent.map((r, i) => (
              <li key={i}>
                <p>
                  <AuditActionText action={r.action} target={r.target} detail={r.detail} />
                </p>
                <p className="muted">
                  {r.by.split(' ')[0]} · {shortDate(intl, r.at)} · {r.reason}
                </p>
              </li>
            ))}
          </ul>
        )}
      </Panel>
      {change && (
        <FlagDialog
          change={change}
          onClose={() => setChange(null)}
          onDone={() => {
            setChange(null);
            onChanged();
          }}
        />
      )}
    </div>
  );
}
