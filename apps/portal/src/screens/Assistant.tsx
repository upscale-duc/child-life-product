import {
  assistantSwitchKeys,
  staffCan,
  type AssistantPoolPlan,
  type StaffAssistantSwitches,
  type StaffAssistantTask,
  type StaffAssistantUsage,
} from '@child-life/contracts';
import { Copy, Search } from 'lucide-react';
import { useId, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { toast } from 'sonner';
import { Button as UiButton } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { cn } from '@/lib/utils';
import { ApiError, useApi, useLoad, type Api } from '../api';
import { Hint, Notice, Section, StatTiles } from '../content-kit';
import { useNavigate, useStaff } from '../context';
import { duration, num, pct, shortDate, vnd, when } from '../format';
import {
  Button,
  HBars,
  Loaded,
  LockNote,
  Page,
  Pill,
  StackedBars,
  TableScroll,
  errorMessageId,
  type PillTone,
} from '../ui';
import { AuditActionText, FlagDialog, ScopePill, type FlagChange } from './Features';
import { reservationTone } from './PremiumOps';
import { BudgetMeter, budgetMonth, budgetUsed } from './System';

/**
 * Trợ lý AI (docs/assistant/architecture.md §5, slice A6): Usage (the household credit pool by
 * budget, tasks, errors, model counters), Tasks (one task by id, for support) and Switches (the
 * assistant kill switches, P-161). Aggregates, codes and states only — never a message, a draft's
 * content, a clarification answer, a health sign or a photo; families and babies as codes.
 * Credit settings stay in Premium › Cấu hình (D-075 #1); switching uses the Features dialog
 * (`staffSetFlag`: role `flags.toggle`, reason, audit).
 */
export function AssistantScreen({ initialTab = 'usage' }: { initialTab?: AssistantTab }) {
  const intl = useIntl();
  const [tab, setTab] = useState<AssistantTab>(initialTab);
  return (
    <Page
      title={<FormattedMessage id="assistant.title" />}
      subtitle={<FormattedMessage id="assistant.sub" />}
    >
      <Tabs value={tab} onValueChange={(t) => setTab(t as AssistantTab)} className="min-w-0 gap-4">
        <TabsList aria-label={intl.formatMessage({ id: 'assistant.tabs' })}>
          {assistantTabs.map((t) => (
            <TabsTrigger key={t} value={t} className="px-3">
              <FormattedMessage id={`assistant.tab.${t}`} />
            </TabsTrigger>
          ))}
        </TabsList>
        <TabsContent value="usage" className="min-w-0">
          <UsageLoader />
        </TabsContent>
        <TabsContent value="tasks" className="min-w-0">
          <TaskLookup />
        </TabsContent>
        <TabsContent value="switches" className="min-w-0">
          <SwitchesLoader />
        </TabsContent>
      </Tabs>
    </Page>
  );
}

export const assistantTabs = ['usage', 'tasks', 'switches'] as const;
export type AssistantTab = (typeof assistantTabs)[number];

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

/** Seconds under a minute, then minutes or hours. */
const took = (intl: IntlShape, ms: number | null) =>
  ms === null || ms < 0 ? '—' : ms < 60_000 ? seconds(intl, ms) : duration(intl, ms / 60_000);

/** A code (task, family, baby) in monospace with a small copy button. */
function CopyCode({ value, className }: { value: string; className?: string }) {
  const intl = useIntl();
  const label = intl.formatMessage({ id: 'assistant.copy' }, { id: value });
  return (
    <span className={cn('inline-flex min-w-0 items-center gap-0.5', className)}>
      <span className="mono truncate">{value}</span>
      <button
        type="button"
        aria-label={label}
        title={label}
        className="inline-grid size-6 shrink-0 place-items-center rounded-md text-muted-foreground hover:bg-muted hover:text-foreground focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-none"
        onClick={() =>
          void navigator.clipboard?.writeText(value).then(
            () => toast.success(intl.formatMessage({ id: 'assistant.copied' })),
            () => undefined,
          )
        }
      >
        <Copy className="size-3.5" aria-hidden="true" />
      </button>
    </span>
  );
}

/** A small heading inside a section. */
function SubHead({ id }: { id: string }) {
  return (
    <p className="mb-3 text-[13px] font-medium text-muted-foreground">
      <FormattedMessage id={id} />
    </p>
  );
}

// ---------- Usage ----------

function UsageLoader() {
  const [load, reload] = useLoad<StaffAssistantUsage>('staffAssistantUsage', {}, 'assistantUsage');
  return (
    <Loaded load={load} reload={reload}>
      {(data) => <UsageView data={data} now={new Date()} />}
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
      <p className="text-sm text-muted-foreground">
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

/**
 * Mức dùng: spend against the AI budget and the figures an operator acts on (failures, blocked
 * tasks, households out of credits) first; the credit pool next; breakdowns and model counters
 * fold away.
 */
export function UsageView({ data, now = new Date() }: { data: StaffAssistantUsage; now?: Date }) {
  const intl = useIntl();
  const navigate = useNavigate();
  const committed = data.pool.reduce((n, p) => n + p.committed, 0);
  const released = data.pool.reduce((n, p) => n + p.released, 0);
  const held = data.pool.reduce((n, p) => n + p.held, 0);
  const exhausted = data.pool.reduce((n, p) => n + p.exhausted, 0);
  const t = data.tasks;
  const m = data.model;
  const failed = t.byState.failed ?? 0;
  const top = t.errors[0];
  const errorMax = Math.max(1, ...t.errors.map((e) => e.count));
  const c = data.credits;
  const used = budgetUsed(data.budget);
  const month = budgetMonth(intl, data.budget);
  return (
    <div className="grid min-w-0 grid-cols-1 gap-4">
      {(data.truncated.tasks || data.truncated.ops) && (
        <Notice tone="info">
          <FormattedMessage id="assistant.usage.truncated" />
        </Notice>
      )}
      {used >= 0.8 && (
        <Notice
          tone={used >= 1 ? 'error' : 'warn'}
          title={
            used >= 1 ? (
              <FormattedMessage id="ai.warn.over" />
            ) : (
              <FormattedMessage id="ai.warn.near" values={{ p: pct(intl, used) }} />
            )
          }
        >
          <FormattedMessage id="assistant.budget.hint" />
        </Notice>
      )}
      <Section
        title={<FormattedMessage id="ai.budget" values={{ month }} />}
        hint={<FormattedMessage id="assistant.budget.hint" />}
      >
        <BudgetMeter
          budget={data.budget}
          now={now}
          foot={
            <FormattedMessage
              id="assistant.budget.foot"
              values={{ calls: m.calls, cost: vnd(intl, m.estimatedCostVnd) }}
            />
          }
        />
      </Section>
      <StatTiles
        items={[
          {
            key: 'tasks',
            label: <FormattedMessage id="assistant.kpi.tasks" />,
            value: <span className="tabular-nums">{num(intl, t.total)}</span>,
            foot: (
              <FormattedMessage
                id="assistant.kpi.tasksFoot"
                values={{ health: t.health, blocked: t.byState.blocked ?? 0 }}
              />
            ),
          },
          {
            key: 'failed',
            label: <FormattedMessage id="assistant.kpi.failed" />,
            value: <span className="tabular-nums">{num(intl, failed)}</span>,
            tone: failed ? 'warn' : 'default',
            foot: top ? (
              <FormattedMessage id="assistant.kpi.failedFoot" values={{ code: top.code }} />
            ) : (
              <FormattedMessage id="assistant.noErrors" />
            ),
          },
          {
            key: 'exhausted',
            label: <FormattedMessage id="assistant.kpi.exhausted" />,
            value: <span className="tabular-nums">{num(intl, exhausted)}</span>,
            tone: exhausted ? 'warn' : 'default',
            foot: <FormattedMessage id="assistant.kpi.exhaustedFoot" />,
          },
          {
            key: 'credits',
            label: <FormattedMessage id="assistant.kpi.credits" />,
            value: <span className="tabular-nums">{num(intl, committed)}</span>,
            foot: <FormattedMessage id="assistant.kpi.creditsFoot" values={{ released, held }} />,
          },
        ]}
      />
      <div className="grid min-w-0 grid-cols-1 gap-4 lg:grid-cols-2">
        <Section
          title={<FormattedMessage id="assistant.errors" />}
          description={<FormattedMessage id="assistant.errors.note" />}
          className="min-w-0"
        >
          {t.errors.length === 0 ? (
            <p className="text-sm text-muted-foreground">
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
        </Section>
        <Section
          title={<FormattedMessage id="assistant.daily" />}
          hint={<FormattedMessage id="assistant.daily.note" />}
          className="min-w-0"
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
        </Section>
      </div>
      <Section
        title={<FormattedMessage id="assistant.pool" />}
        hint={<FormattedMessage id="assistant.pool.note" />}
        actions={
          <Button kind="ghost" onClick={() => navigate('premium')}>
            <FormattedMessage id="assistant.credits.open" />
          </Button>
        }
        flush
        className="min-w-0 overflow-hidden"
      >
        <TableScroll min={600}>
          <table className="table [&_td]:py-2.5">
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
                    <span className="font-medium">{num(intl, p.committed)}</span>
                    <span className="block text-xs text-muted-foreground">
                      <FormattedMessage
                        id="assistant.pool.split"
                        values={{ chat: p.chat, summaries: p.summaries }}
                      />
                    </span>
                  </td>
                  <td>{num(intl, p.released)}</td>
                  <td>{num(intl, p.held)}</td>
                  <td>{num(intl, p.households)}</td>
                  <td>
                    {p.exhausted ? (
                      <Pill tone="warn">{num(intl, p.exhausted)}</Pill>
                    ) : (
                      <span className="text-muted-foreground">0</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
        <div className="flex flex-wrap items-baseline gap-x-5 gap-y-1.5 border-t px-5 py-3 text-[13px]">
          <span className="font-medium">
            <FormattedMessage id="assistant.credits" />
          </span>
          <dl className="m-0 flex flex-wrap items-baseline gap-x-5 gap-y-1.5">
            {(
              [
                ['free', c.free],
                ['premium', c.premium],
                ['text', c.textCredits],
                ['image', c.imageCredits],
                ['summary', c.aiSummaryCredits],
              ] as const
            ).map(([k, n]) => (
              <div key={k} className="flex items-baseline gap-1.5">
                <dt className="text-muted-foreground">
                  <FormattedMessage id={`assistant.credits.${k}`} />
                </dt>
                <dd className="m-0 font-medium tabular-nums">
                  <FormattedMessage id="assistant.credits.value" values={{ n }} />
                </dd>
              </div>
            ))}
          </dl>
          {!c.stored && (
            <span className="text-muted-foreground">
              <FormattedMessage id="assistant.credits.default" />
            </span>
          )}
        </div>
      </Section>
      <Section
        title={<FormattedMessage id="assistant.breakdown" />}
        summary={
          <FormattedMessage
            id="assistant.breakdown.summary"
            values={{
              text: t.byModality.text ?? 0,
              media: t.byModality.image ?? 0,
              health: t.health,
            }}
          />
        }
        collapsible
        defaultOpen={false}
      >
        <TaskBreakdown tasks={t} />
      </Section>
      <Section
        title={<FormattedMessage id="assistant.model" />}
        hint={<FormattedMessage id="assistant.model.note" />}
        summary={
          <FormattedMessage
            id="assistant.model.summary"
            values={{ calls: m.calls, p95: seconds(intl, m.timeToReady.p95Ms) }}
          />
        }
        collapsible
        defaultOpen={false}
      >
        <ModelDetails model={m} />
      </Section>
      <LockNote>
        <FormattedMessage id="assistant.usage.lock" />
      </LockNote>
    </div>
  );
}

/** Tasks by state and by outcome, and the text / photo / health counts (folded in Mức dùng). */
export function TaskBreakdown({ tasks: t }: { tasks: StaffAssistantUsage['tasks'] }) {
  const intl = useIntl();
  return (
    <div className="grid gap-5">
      <div className="grid gap-6 md:grid-cols-2">
        <div className="min-w-0">
          <SubHead id="assistant.states" />
          <CountBars counts={t.byState} prefix="assistant.state" />
        </div>
        <div className="min-w-0">
          <SubHead id="assistant.outcomes" />
          <CountBars counts={t.byOutcome} prefix="assistant.outcome" />
        </div>
      </div>
      <dl className="flex flex-wrap gap-x-6 gap-y-1 border-t pt-4 text-sm">
        {(['text', 'image'] as const).map((k) => (
          <div key={k} className="flex gap-2">
            <dt className="text-muted-foreground">
              <FormattedMessage id={`assistant.modality.${k}`} />
            </dt>
            <dd className="m-0 font-medium tabular-nums">{num(intl, t.byModality[k] ?? 0)}</dd>
          </div>
        ))}
        <div className="flex gap-2">
          <dt className="text-muted-foreground">
            <FormattedMessage id="assistant.health" />
          </dt>
          <dd className="m-0 font-medium tabular-nums">{num(intl, t.health)}</dd>
        </div>
      </dl>
    </div>
  );
}

/** Calls, estimated cost, time to ready and the calls per model / prompt (folded in Mức dùng). */
export function ModelDetails({ model: m }: { model: StaffAssistantUsage['model'] }) {
  const intl = useIntl();
  return (
    <div className="grid gap-4">
      <dl className="kv m-0">
        <Row label="assistant.model.calls">
          <FormattedMessage
            id="assistant.model.callsValue"
            values={{ calls: m.calls, tasks: m.tasksWithCalls }}
          />
        </Row>
        <Row label="assistant.model.cost">{vnd(intl, m.estimatedCostVnd)}</Row>
        <Row label="assistant.model.timeToReady">
          {m.timeToReady.samples === 0 ? (
            <span className="text-muted-foreground">
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
        </Row>
      </dl>
      {m.byModel.length > 0 && (
        <div className="overflow-hidden rounded-lg border">
          <TableScroll min={460}>
            <table className="table [&_td]:py-2">
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
                    <td className="mono text-muted-foreground">{r.promptVersion ?? '—'}</td>
                    <td>{num(intl, r.tasks)}</td>
                    <td>{num(intl, r.calls)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </TableScroll>
        </div>
      )}
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
  const api = useApi();
  const inputId = useId();
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
    <div className="grid min-w-0 grid-cols-1 gap-4">
      <Section
        title={<FormattedMessage id="assistant.lookup.title" />}
        description={<FormattedMessage id="assistant.lookup.note" />}
      >
        <form
          className="flex flex-wrap items-center gap-2"
          onSubmit={(e) => {
            e.preventDefault();
            if (!busy && id.trim()) void look();
          }}
        >
          <Label htmlFor={inputId} className="sr-only">
            <FormattedMessage id="assistant.lookup.id" />
          </Label>
          <div className="relative min-w-0 flex-1 sm:max-w-xl">
            <Search
              className="pointer-events-none absolute top-1/2 left-2.5 size-4 -translate-y-1/2 text-muted-foreground"
              aria-hidden="true"
            />
            <Input
              id={inputId}
              value={id}
              onChange={(e) => setId(e.target.value)}
              placeholder="tk_…"
              spellCheck={false}
              autoComplete="off"
              aria-invalid={problem ? true : undefined}
              className="pl-8 font-mono"
            />
          </div>
          <UiButton type="submit" disabled={busy || !id.trim()}>
            <FormattedMessage id="assistant.lookup.go" />
          </UiButton>
        </form>
        {problem && (
          <p className="mt-2 text-sm text-destructive" role="alert">
            <FormattedMessage id={problem} />
          </p>
        )}
        <LockNote>
          <FormattedMessage id="assistant.task.lock" />
        </LockNote>
      </Section>
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

/** A label over a value, in the task header. */
function Fact({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="grid min-w-0 gap-0.5">
      <dt className="text-xs text-muted-foreground">
        <FormattedMessage id={label} />
      </dt>
      <dd className="m-0 text-sm font-medium">{children}</dd>
    </div>
  );
}

/**
 * One task for support: state, codes and the main figures on top; the timeline, times and credit
 * reservation next; drafts, clarifications and photos; model and versions fold away.
 */
export function TaskView({ task, now }: { task: StaffAssistantTask; now: Date }) {
  const intl = useIntl();
  const at = (iso: string | null) => (iso ? when(intl, iso, now) : '—');
  const r = task.reservation;
  const tookMs = task.readyAt ? Date.parse(task.readyAt) - Date.parse(task.createdAt) : null;
  return (
    <div className="grid min-w-0 grid-cols-1 gap-4">
      <section className="rounded-xl border bg-card text-card-foreground">
        <div className="grid gap-1.5 px-5 py-4">
          <div className="flex flex-wrap items-center gap-x-3 gap-y-1.5">
            <h2 className="min-w-0 text-[15px] font-semibold">
              <CopyCode value={task.taskId} />
            </h2>
            <Pill tone={stateTone[task.state] ?? 'muted'}>
              <FormattedMessage id={`assistant.state.${task.state}`} />
            </Pill>
            {task.errorCode && <span className="mono text-destructive">{task.errorCode}</span>}
            <span className="ml-auto text-[13px] text-muted-foreground tabular-nums">
              <FormattedMessage
                id="assistant.task.receivedAt"
                values={{ at: at(task.createdAt) }}
              />
            </span>
          </div>
          <p className="flex flex-wrap items-center gap-x-1.5 gap-y-1 text-[13px] text-muted-foreground">
            <span>
              <FormattedMessage id="assistant.task.family" />
            </span>
            <CopyCode value={task.family} className="text-foreground" /> ·{' '}
            <CopyCode value={task.baby} className="text-foreground" />
            <span aria-hidden="true">·</span>
            <span>
              <FormattedMessage id={`assistant.task.scope.${task.scope}`} /> ·{' '}
              <FormattedMessage id={`assistant.task.visibility.${task.visibility}`} />
            </span>
            <span aria-hidden="true">·</span>
            <FormattedMessage id={`assistant.modality.${task.modality}`} />
          </p>
        </div>
        <dl className="m-0 grid grid-cols-2 gap-x-6 gap-y-3 border-t px-5 py-3 lg:grid-cols-4">
          <Fact label="assistant.model.timeToReady">
            <span className="tabular-nums">{took(intl, tookMs)}</span>
          </Fact>
          <Fact label="assistant.task.credits">
            <FormattedMessage
              id="assistant.task.creditsValue"
              values={{
                n: task.credits,
                usage: intl.formatMessage({ id: `assistant.usage.${task.usage}` }),
              }}
            />
            <span className="block text-xs font-normal text-muted-foreground">
              <FormattedMessage id={`assistant.plan.${task.pool ?? task.plan}`} />
            </span>
          </Fact>
          <Fact label="assistant.task.outcome">
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
          </Fact>
          <Fact label="assistant.health">
            <FormattedMessage id={task.health ? 'premium.yes' : 'premium.no'} />
          </Fact>
        </dl>
      </section>

      <div className="grid min-w-0 grid-cols-1 items-start gap-4 lg:grid-cols-2">
        <Section
          title={<FormattedMessage id="assistant.task.events" />}
          hint={<FormattedMessage id="assistant.task.eventsNote" />}
          className="min-w-0"
        >
          {task.events.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              <FormattedMessage id="assistant.task.noEvents" />
            </p>
          ) : (
            <ol className="m-0 ml-1 grid list-none gap-2.5 border-l p-0 pl-4">
              {task.events.map((e) => (
                <li key={e.sequence} className="relative flex flex-wrap items-baseline gap-x-2">
                  <span
                    aria-hidden="true"
                    className="absolute top-1.5 -left-[21px] size-2 rounded-full bg-primary"
                  />
                  <span className="mono">{e.type}</span>
                  <span className="text-xs text-muted-foreground tabular-nums">
                    #{e.sequence} · {at(e.at)}
                  </span>
                </li>
              ))}
            </ol>
          )}
        </Section>
        <div className="grid min-w-0 content-start gap-4">
          <Section title={<FormattedMessage id="assistant.task.times" />}>
            <dl className="kv m-0 tabular-nums">
              <Row label="assistant.task.created">{at(task.createdAt)}</Row>
              <Row label="assistant.task.ready">{at(task.readyAt)}</Row>
              <Row label="assistant.task.updated">{at(task.updatedAt)}</Row>
              <Row label="assistant.task.clarExpires">{at(task.clarificationExpiresAt)}</Row>
            </dl>
          </Section>
          <Section
            title={<FormattedMessage id="assistant.task.reservation" />}
            actions={
              r && (
                <Pill tone={r.state ? reservationTone[r.state] : 'muted'}>
                  <FormattedMessage id={`render.state.${r.state ?? 'none'}`} />
                </Pill>
              )
            }
          >
            {r ? (
              <div className="grid gap-2">
                <p className="font-medium">
                  <FormattedMessage id="assistant.credits.value" values={{ n: r.units }} />
                </p>
                <dl className="kv m-0 tabular-nums">
                  <Row label="assistant.task.reservedAt">{at(r.reservedAt)}</Row>
                  <Row label="assistant.task.committedAt">{at(r.committedAt)}</Row>
                  <Row label="assistant.task.releasedAt">
                    {at(r.releasedAt)}
                    {r.releaseReason && (
                      <span className="mono text-muted-foreground"> · {r.releaseReason}</span>
                    )}
                  </Row>
                </dl>
                <p className="mono truncate text-xs text-muted-foreground" title={r.id}>
                  {r.window} · {r.id}
                </p>
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">
                <FormattedMessage id="assistant.task.noReservation" />
              </p>
            )}
          </Section>
        </div>
      </div>

      <Section
        title={<FormattedMessage id="assistant.task.drafts" />}
        flush
        className="min-w-0 overflow-hidden"
      >
        {task.drafts.length === 0 ? (
          <p className="px-5 py-4 text-sm text-muted-foreground">
            <FormattedMessage id="assistant.task.noDrafts" />
          </p>
        ) : (
          <TableScroll min={680}>
            <table className="table [&_td]:py-2.5">
              <thead>
                <tr>
                  <Th id="assistant.task.col.draft" />
                  <Th id="col.status" />
                  <Th id="assistant.task.col.review" />
                  <Th id="assistant.task.col.times" />
                </tr>
              </thead>
              <tbody>
                {task.drafts.map((d) => (
                  <tr key={d.id}>
                    <td>
                      <span className="font-medium">
                        {d.kind ? <FormattedMessage id={`assistant.draft.kind.${d.kind}`} /> : '—'}
                      </span>
                      <span className="mono block text-xs text-muted-foreground">
                        {d.id} · r{d.revision}
                      </span>
                    </td>
                    <td>
                      <FormattedMessage id={`assistant.draft.state.${d.state}`} />
                      {d.errorCode && (
                        <span className="mono block text-xs text-destructive">{d.errorCode}</span>
                      )}
                    </td>
                    <td className="mono text-muted-foreground">
                      {[...d.missingFields, ...d.uncertainFields, ...d.warnings].join(', ') || '—'}
                    </td>
                    <td className="nowrap text-muted-foreground tabular-nums">
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
      </Section>

      <div className="grid min-w-0 grid-cols-1 gap-4 lg:grid-cols-2">
        <Section title={<FormattedMessage id="assistant.task.rounds" />} className="min-w-0">
          {task.clarifications.length === 0 ? (
            <p className="text-sm text-muted-foreground">—</p>
          ) : (
            <ul className="m-0 grid list-none gap-1.5 p-0 text-sm">
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
        </Section>
        <Section title={<FormattedMessage id="assistant.task.attachments" />} className="min-w-0">
          {task.attachments.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              <FormattedMessage id="assistant.task.noAttachments" />
            </p>
          ) : (
            <ul className="m-0 grid list-none gap-1.5 p-0 text-sm">
              {task.attachments.map((a, i) => (
                <li key={i} className="flex flex-wrap items-center gap-x-1.5">
                  <FormattedMessage id={`assistant.attachment.state.${a.state}`} />
                  {a.retention && (
                    <span className="text-muted-foreground">
                      {'· '}
                      <FormattedMessage id={`assistant.attachment.retention.${a.retention}`} />
                    </span>
                  )}
                  {a.rejected && (
                    <Pill tone="warn">
                      <FormattedMessage id="assistant.attachment.rejected" />
                    </Pill>
                  )}
                </li>
              ))}
            </ul>
          )}
        </Section>
      </div>

      <Section
        title={<FormattedMessage id="assistant.task.tech" />}
        summary={<span className="mono">{task.model ?? '—'}</span>}
        collapsible
        defaultOpen={false}
      >
        <TaskTechnical task={task} now={now} />
      </Section>
    </div>
  );
}

/** Model, calls, prompt and policy versions, care topic and worker lease (folded). */
export function TaskTechnical({ task, now }: { task: StaffAssistantTask; now: Date }) {
  const intl = useIntl();
  return (
    <dl className="kv m-0">
      <Row label="assistant.task.model">
        <span className="mono">{task.model ?? '—'}</span>
        <span className="block text-[13px] text-muted-foreground">
          <FormattedMessage
            id="assistant.task.modelValue"
            values={{ calls: task.modelCalls, attempts: task.attempt }}
          />
        </span>
      </Row>
      <Row label="assistant.task.versions">
        <span className="mono text-muted-foreground">
          {task.promptVersion ?? '—'} · {task.policyVersion ?? '—'}
        </span>
      </Row>
      {task.careTopic && (
        <Row label="assistant.task.care">
          <span className="mono text-muted-foreground">{task.careTopic}</span>
        </Row>
      )}
      <Row label="assistant.task.lease">
        <span className="tabular-nums">
          {task.leaseUntil ? when(intl, task.leaseUntil, now) : '—'}
        </span>
      </Row>
    </dl>
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

/** Công tắc: one row per switch (what it does, what turning it off does, scope, last edit). */
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
    <div className="grid min-w-0 grid-cols-1 gap-4">
      <Section
        title={<FormattedMessage id="assistant.switches" />}
        description={<FormattedMessage id="assistant.switches.lock" />}
        actions={
          <Button kind="ghost" onClick={() => navigate('features')}>
            <FormattedMessage id="assistant.switches.open" />
          </Button>
        }
        flush
      >
        <ul className="m-0 list-none divide-y p-0">
          {assistantSwitchKeys.map((key) => {
            const f = data.flags[key];
            const last = data.lastEdit[key];
            const name = intl.formatMessage({ id: `flag.${key}` });
            const offEffect = intl.formatMessage({ id: `flag.${key}.offEffect` });
            const whenOff = intl.formatMessage({ id: 'assistant.switches.whenOff' });
            return (
              <li key={key} className="flex flex-wrap items-center gap-x-4 gap-y-2 px-5 py-3">
                <div className="min-w-0 flex-1 basis-64">
                  <p className="flex items-center gap-1 font-medium">
                    {name}
                    <Hint label={`${whenOff} ${offEffect}`}>
                      <span className="font-medium">{whenOff}</span> {offEffect}
                    </Hint>
                  </p>
                  <p className="text-[13px] text-muted-foreground">
                    <FormattedMessage id={`flag.${key}.desc`} />
                  </p>
                </div>
                <div className="flex min-w-36 shrink-0 flex-col items-end gap-1 text-right">
                  {f.enabled ? (
                    <ScopePill flag={f} />
                  ) : (
                    <span className="text-[13px] text-muted-foreground">
                      <FormattedMessage id="assistant.switches.off" />
                    </span>
                  )}
                  {last && (
                    <span
                      className="text-xs text-muted-foreground tabular-nums"
                      title={intl.formatMessage({ id: 'col.lastEdit' })}
                    >
                      {last.by.split(' ')[0]} · {shortDate(intl, last.at)}
                    </span>
                  )}
                </div>
                <Switch
                  checked={f.enabled}
                  aria-label={name}
                  disabled={!canToggle}
                  title={canToggle ? undefined : intl.formatMessage({ id: 'features.toggleRole' })}
                  onCheckedChange={() =>
                    setChange({
                      key,
                      kind: f.enabled ? 'off' : 'on',
                      next: { ...f, enabled: !f.enabled, notice: null },
                    })
                  }
                />
              </li>
            );
          })}
        </ul>
      </Section>
      <Section
        title={<FormattedMessage id="assistant.switches.recent" />}
        summary={
          data.recent.length ? (
            <FormattedMessage
              id="assistant.switches.recentSummary"
              values={{ n: data.recent.length }}
            />
          ) : (
            <FormattedMessage id="assistant.switches.noRecent" />
          )
        }
        collapsible
        defaultOpen={false}
      >
        <SwitchRecent recent={data.recent} />
      </Section>
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

/** The recent switch changes: what, who, when and why (folded in Công tắc). */
export function SwitchRecent({ recent }: { recent: StaffAssistantSwitches['recent'] }) {
  const intl = useIntl();
  if (recent.length === 0) {
    return (
      <p className="text-sm text-muted-foreground">
        <FormattedMessage id="assistant.switches.noRecent" />
      </p>
    );
  }
  return (
    <ul className="m-0 grid list-none gap-3 p-0">
      {recent.map((r, i) => (
        <li key={i} className="grid gap-0.5">
          <p className="text-sm">
            <AuditActionText action={r.action} target={r.target} detail={r.detail} />
          </p>
          <p className="text-xs text-muted-foreground">
            {r.by.split(' ')[0]} · {shortDate(intl, r.at)} · {r.reason}
          </p>
        </li>
      ))}
    </ul>
  );
}
