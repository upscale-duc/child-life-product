import { staffCan } from '@child-life/contracts';
import { Check, HardDrive } from 'lucide-react';
import type { ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { cn } from '@/lib/utils';
import { useLoad, type AiStats, type SystemHealth } from '../api';
import { EmptyState, Notice, Section, StatTiles } from '../content-kit';
import { useNavigate, useStaff } from '../context';
import { ZONE, bytes, gb, num, pct, shortDate, usageTone, vnd } from '../format';
import { HBars, LineChart, Loaded, Page, Pill, TableScroll, UsageBar } from '../ui';

/** A08 / A09 Hệ thống & AI: aggregate figures only; the tabs keep their routes. */
export function SystemScreen({ tab }: { tab: 'storage' | 'ai' }) {
  const intl = useIntl();
  const navigate = useNavigate();
  return (
    <Page
      title={<FormattedMessage id="system.title" />}
      subtitle={<FormattedMessage id="system.sub" />}
    >
      <Tabs
        value={tab}
        onValueChange={(t) => navigate(t === 'ai' ? 'systemAi' : 'system')}
        className="min-w-0 gap-4"
      >
        <TabsList aria-label={intl.formatMessage({ id: 'system.tabs' })}>
          <TabsTrigger value="storage" className="px-3">
            <FormattedMessage id="system.tabStorage" />
          </TabsTrigger>
          <TabsTrigger value="ai" className="px-3">
            <FormattedMessage id="system.tabAi" />
          </TabsTrigger>
        </TabsList>
        <TabsContent value="storage" className="min-w-0">
          <StorageHealth />
        </TabsContent>
        <TabsContent value="ai" className="min-w-0">
          <AiHealth />
        </TabsContent>
      </Tabs>
    </Page>
  );
}

function StorageHealth() {
  const [load, reload] = useLoad<SystemHealth>('staffSystem', {}, 'system');
  return (
    <Loaded load={load} reload={reload}>
      {(data) => <SystemView data={data} now={new Date()} />}
    </Loaded>
  );
}

const bucketIds = ['lt1', 'b1to3', 'b3to6', 'b6to8', 'b8to10', 'expanded'] as const;

/** Lưu trữ: what needs attention first (a long video queue, families near quota), then figures. */
export function SystemView({ data, now }: { data: SystemHealth; now: Date }) {
  const intl = useIntl();
  const staff = useStaff();
  const navigate = useNavigate();
  const k = data.kpis;
  const total = Math.max(1, data.families);
  const hours = data.videoQueue.map((_, i) =>
    intl.formatTime(new Date(now.getTime() - (23 - i) * 3_600_000), {
      hour: 'numeric',
      timeZone: ZONE,
    }),
  );
  const over = k.videosWaiting >= data.videoThreshold;
  return (
    <div className="grid min-w-0 grid-cols-1 gap-4">
      {over && (
        <Notice
          tone="warn"
          title={
            <FormattedMessage
              id="system.warn.queue"
              values={{ n: k.videosWaiting, max: data.videoThreshold }}
            />
          }
        >
          <FormattedMessage id="system.warn.queueBody" />
        </Notice>
      )}
      {k.over80 > 0 && (
        <Notice
          tone="warn"
          title={<FormattedMessage id="system.warn.near" values={{ n: k.over80 }} />}
          action={
            staffCan(staff.levels, 'storage.view') && (
              <Button variant="outline" size="sm" onClick={() => navigate('storage')}>
                <FormattedMessage id="system.openStorage" />
              </Button>
            )
          }
        >
          <FormattedMessage id="system.reminded" />
        </Notice>
      )}
      <StatTiles
        items={[
          {
            key: 'stored',
            label: <FormattedMessage id="system.stored" />,
            value: <span className="tabular-nums">{bytes(intl, k.storedBytes)}</span>,
          },
          {
            key: 'over80',
            label: <FormattedMessage id="storage.kpiOver80" />,
            value: <span className="tabular-nums">{num(intl, k.over80)}</span>,
            tone: k.over80 > 0 ? 'warn' : 'default',
            foot: <FormattedMessage id="system.reminded" />,
          },
          {
            key: 'videos',
            label: <FormattedMessage id="system.videosWaiting" />,
            value: <span className="tabular-nums">{num(intl, k.videosWaiting)}</span>,
            tone: over ? 'warn' : 'default',
            foot: <FormattedMessage id="system.threshold" values={{ n: data.videoThreshold }} />,
          },
          {
            key: 'uploads',
            label: <FormattedMessage id="system.uploadFailures" />,
            value: <span className="tabular-nums">{pct(intl, k.uploadFailureRate, 1)}</span>,
            foot: <FormattedMessage id="system.last24h" />,
          },
        ]}
      />
      <div className="grid min-w-0 grid-cols-1 gap-4 lg:grid-cols-2">
        <Section
          title={<FormattedMessage id="system.perFamily" />}
          description={<FormattedMessage id="system.perFamilyNote" values={{ n: data.families }} />}
          className="min-w-0"
        >
          <HBars
            rows={data.histogram.map((n, i) => ({
              label: <FormattedMessage id={`bucket.${bucketIds[i]}`} />,
              value: `${num(intl, n)} · ${pct(intl, n / total)}`,
              ratio: n / total,
              tone: i === 4 ? 'warn' : i === 5 ? 'purple' : undefined,
            }))}
          />
        </Section>
        <Section
          title={<FormattedMessage id="system.queue" />}
          description={<FormattedMessage id="system.queueNote" />}
          actions={
            <Pill tone={over ? 'warn' : 'ok'}>
              <FormattedMessage id={over ? 'system.overThreshold' : 'system.underThreshold'} />
            </Pill>
          }
          className="min-w-0"
        >
          <LineChart
            title={intl.formatMessage({ id: 'system.queue' })}
            points={data.videoQueue}
            labels={hours}
            threshold={data.videoThreshold}
            thresholdLabel={intl.formatMessage(
              { id: 'system.threshold' },
              { n: data.videoThreshold },
            )}
            area={false}
          />
        </Section>
      </div>
      <Section
        title={<FormattedMessage id="system.near" />}
        description={<FormattedMessage id="system.nearNote" />}
        hint={<FormattedMessage id="system.nearHint" />}
        flush
        className="min-w-0 overflow-hidden"
      >
        {data.nearQuota.length === 0 ? (
          <EmptyState icon={HardDrive} title={<FormattedMessage id="system.nearEmpty" />} />
        ) : (
          <TableScroll min={560}>
            <table className="table [&_td]:py-2.5">
              <thead>
                <tr>
                  <th>
                    <FormattedMessage id="col.family" />
                  </th>
                  <th>
                    <FormattedMessage id="col.babies" />
                  </th>
                  <th>
                    <FormattedMessage id="col.used" />
                  </th>
                  <th>
                    <FormattedMessage id="col.request" />
                  </th>
                </tr>
              </thead>
              <tbody>
                {data.nearQuota.map((f) => {
                  const ratio = f.usedBytes / Math.max(1, f.quotaBytes);
                  return (
                    <tr key={f.family}>
                      <td className="mono font-semibold">{f.family}</td>
                      <td className="tabular-nums">
                        <FormattedMessage id="family.babies" values={{ n: f.babies }} />
                      </td>
                      <td className="w-[40%] min-w-44">
                        <span className="tabular-nums">
                          {gb(intl, f.usedBytes)} · {pct(intl, ratio)}
                        </span>
                        <UsageBar ratio={ratio} tone={usageTone(f.usedBytes, f.quotaBytes)} />
                      </td>
                      <td>
                        {f.requested ? (
                          <Pill tone="wait">
                            <FormattedMessage id="system.requested" />
                          </Pill>
                        ) : (
                          <span className="text-muted-foreground">
                            <FormattedMessage id="system.notRequested" />
                          </span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </TableScroll>
        )}
      </Section>
    </div>
  );
}

function AiHealth() {
  const [load, reload] = useLoad<AiStats>('staffAi', {}, 'ai');
  return (
    <Loaded load={load} reload={reload}>
      {(data) => <AiView data={data} now={new Date()} />}
    </Loaded>
  );
}

type Budget = AiStats['budget'];

/** Share of the monthly AI budget spent (0 when no budget is set). */
export const budgetUsed = (b: Budget) => (b.monthlyBudgetVnd ? b.spentVnd / b.monthlyBudgetVnd : 0);

/** "tháng 10" / "October" for a `YYYY-MM` budget month. */
export const budgetMonth = (intl: IntlShape, b: Budget) =>
  intl.formatDate(`${b.month}-15`, { month: 'long', timeZone: ZONE });

const meterTone = (used: number) => (used >= 1 ? 'error' : used >= 0.8 ? 'warn' : 'ok');
const meterText = { ok: 'text-foreground', warn: 'text-warning', error: 'text-destructive' };
const meterFill = { ok: 'bg-primary', warn: 'bg-warning', error: 'bg-destructive' };

/**
 * Spent / budget this month as a bar with the 80% alert mark (A09), the day of the month, and
 * what the marks mean (`foot`). Shared with Trợ lý AI › Mức dùng.
 */
export function BudgetMeter({ budget, now, foot }: { budget: Budget; now: Date; foot: ReactNode }) {
  const intl = useIntl();
  const used = budgetUsed(budget);
  const tone = meterTone(used);
  const day = Number(
    new Intl.DateTimeFormat('en-GB', { day: 'numeric', timeZone: ZONE }).format(now),
  );
  const [y, m] = budget.month.split('-').map(Number) as [number, number];
  const days = new Date(Date.UTC(y, m, 0)).getUTCDate();
  const width = Math.max(0, Math.min(1, used)) * 100;
  return (
    <div className="grid gap-2">
      <p className="flex flex-wrap items-baseline gap-x-2 tabular-nums">
        <span className="text-2xl leading-8 font-bold tracking-tight">
          {vnd(intl, budget.spentVnd)}
        </span>
        <span className="text-muted-foreground">/ {vnd(intl, budget.monthlyBudgetVnd)}</span>
        <span className={cn('ml-auto text-lg font-semibold', meterText[tone])}>
          {pct(intl, used)}
        </span>
      </p>
      <div
        role="progressbar"
        aria-label={intl.formatMessage({ id: 'ai.budgetBar' })}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuenow={Math.round(width)}
        className="relative h-2.5 rounded-full bg-muted"
      >
        <div
          className={cn('h-full rounded-full', meterFill[tone])}
          style={{ width: `${width}%` }}
        />
        <span
          aria-hidden="true"
          className="absolute -inset-y-1 left-[80%] w-0.5 rounded-full bg-foreground/50"
        />
      </div>
      <div className="flex flex-wrap justify-between gap-x-4 gap-y-1 text-xs text-muted-foreground">
        <span className="tabular-nums">
          <FormattedMessage id="ai.budgetDay" values={{ day, days }} />
        </span>
        <span>{foot}</span>
      </div>
    </div>
  );
}

const safetyKeys = ['photos', 'name', 'retention', 'cap'] as const;

/** AI gợi ý câu chuyện: the budget first, then volume and what parents do; the safety list folds. */
export function AiView({ data, now }: { data: AiStats; now: Date }) {
  const intl = useIntl();
  const k = data.kpis;
  const b = data.budget;
  const used = budgetUsed(b);
  const month = budgetMonth(intl, b);
  const total = Math.max(
    1,
    data.outcomes.editedSaved + data.outcomes.savedAsIs + data.outcomes.left,
  );
  const r = data.rollout;
  const rolloutNote = !r.enabled
    ? 'ai.rolloutOff'
    : r.scope === 'internal'
      ? 'ai.rolloutInternal'
      : r.scope === 'percent'
        ? 'ai.rolloutPercent'
        : 'ai.rolloutAll';
  return (
    <div className="grid min-w-0 grid-cols-1 gap-4">
      {used >= 1 ? (
        <Notice tone="error" title={<FormattedMessage id="ai.warn.over" />}>
          <FormattedMessage id="ai.warn.overBody" />
        </Notice>
      ) : (
        used >= 0.8 && (
          <Notice
            tone="warn"
            title={<FormattedMessage id="ai.warn.near" values={{ p: pct(intl, used) }} />}
          >
            <FormattedMessage id="ai.pauseNote" />
          </Notice>
        )
      )}
      <Section
        title={<FormattedMessage id="ai.budget" values={{ month }} />}
        hint={<FormattedMessage id="ai.pauseNote" />}
        actions={
          <Pill tone={!r.enabled ? 'muted' : r.scope === 'all' ? 'ok' : 'purple'}>
            <FormattedMessage id={rolloutNote} values={{ p: r.percent }} />
          </Pill>
        }
      >
        <BudgetMeter budget={b} now={now} foot={<FormattedMessage id="ai.budgetMarks" />} />
      </Section>
      <StatTiles
        items={[
          {
            key: 'cost',
            label: <FormattedMessage id="ai.cost" />,
            value: (
              <span className="tabular-nums">
                {k.costPerDraftVnd === null ? '—' : vnd(intl, k.costPerDraftVnd)}
              </span>
            ),
          },
          {
            key: 'drafts',
            label: <FormattedMessage id="ai.drafts" />,
            value: <span className="tabular-nums">{num(intl, k.drafts7d)}</span>,
          },
          {
            key: 'saved',
            label: <FormattedMessage id="ai.saved" />,
            value: <span className="tabular-nums">{pct(intl, k.savedRate)}</span>,
            foot: <FormattedMessage id="ai.savedFoot" />,
          },
          {
            key: 'reports',
            label: <FormattedMessage id="ai.reports" />,
            value: <span className="tabular-nums">{num(intl, k.reports)}</span>,
            tone: k.reports > 0 ? 'warn' : 'muted',
            foot: <FormattedMessage id="ai.reportsFoot" />,
          },
        ]}
      />
      <div className="grid min-w-0 grid-cols-1 gap-4 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]">
        <Section
          title={<FormattedMessage id="ai.daily" />}
          description={<FormattedMessage id="ai.dailyNote" />}
          className="min-w-0"
        >
          <LineChart
            title={intl.formatMessage({ id: 'ai.daily' })}
            points={data.daily.map((d) => d.drafts)}
            labels={data.daily.map((d) => shortDate(intl, `${d.date}T12:00:00+07:00`))}
          />
        </Section>
        <Section
          title={<FormattedMessage id="ai.outcomes" />}
          description={<FormattedMessage id="ai.last7" />}
          hint={<FormattedMessage id="ai.outcomeCaption" />}
          className="min-w-0"
        >
          <HBars
            rows={(['editedSaved', 'savedAsIs', 'left'] as const).map((key) => ({
              label: <FormattedMessage id={`ai.outcome.${key}`} />,
              value: pct(intl, data.outcomes[key] / total),
              ratio: data.outcomes[key] / total,
            }))}
          />
        </Section>
      </div>
      <Section
        title={<FormattedMessage id="ai.safety" />}
        summary={<FormattedMessage id="ai.safetySummary" values={{ n: safetyKeys.length }} />}
        collapsible
        defaultOpen={false}
      >
        <ul className="grid gap-x-6 gap-y-3 sm:grid-cols-2">
          {safetyKeys.map((key) => (
            <li key={key} className="flex items-start gap-2">
              <Check className="mt-0.5 size-4 shrink-0 text-primary" aria-hidden="true" />
              <span className="grid gap-0.5">
                <span className="font-medium">
                  <FormattedMessage id={`ai.safe.${key}`} />
                </span>
                <span className="text-[13px] text-muted-foreground">
                  <FormattedMessage id={`ai.safe.${key}Value`} />
                </span>
              </span>
            </li>
          ))}
        </ul>
      </Section>
    </div>
  );
}
