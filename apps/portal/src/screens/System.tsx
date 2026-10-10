import { FormattedMessage, useIntl } from 'react-intl';
import { useLoad, type AiStats, type SystemHealth } from '../api';
import { useNavigate } from '../context';
import { ZONE, bytes, gb, num, pct, shortDate, usageTone, vnd } from '../format';
import {
  Empty,
  HBars,
  Kpi,
  LineChart,
  Loaded,
  LockNote,
  Page,
  Panel,
  Pill,
  Segmented,
  UsageBar,
} from '../ui';

/** A08 / A09 Hệ thống & AI: aggregate figures only. */
export function SystemScreen({ tab }: { tab: 'storage' | 'ai' }) {
  const intl = useIntl();
  const navigate = useNavigate();
  return (
    <Page
      title={<FormattedMessage id="system.title" />}
      subtitle={<FormattedMessage id="system.sub" />}
      actions={
        <Segmented
          label={intl.formatMessage({ id: 'system.tabs' })}
          value={tab}
          onChange={(t) => navigate(t === 'ai' ? 'systemAi' : 'system')}
          options={[
            { value: 'storage', label: <FormattedMessage id="system.tabStorage" /> },
            { value: 'ai', label: <FormattedMessage id="system.tabAi" /> },
          ]}
        />
      }
    >
      {tab === 'storage' ? <StorageHealth /> : <AiHealth />}
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

export function SystemView({ data, now }: { data: SystemHealth; now: Date }) {
  const intl = useIntl();
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
    <div className="grid">
      <div className="kpis">
        <Kpi label={<FormattedMessage id="system.stored" />} value={bytes(intl, k.storedBytes)} />
        <Kpi
          label={<FormattedMessage id="storage.kpiOver80" />}
          value={num(intl, k.over80)}
          foot={<FormattedMessage id="system.reminded" />}
        />
        <Kpi
          label={<FormattedMessage id="system.videosWaiting" />}
          value={num(intl, k.videosWaiting)}
          foot={<FormattedMessage id="system.threshold" values={{ n: data.videoThreshold }} />}
          tone={over ? 'warn' : 'muted'}
        />
        <Kpi
          label={<FormattedMessage id="system.uploadFailures" />}
          value={pct(intl, k.uploadFailureRate, 1)}
          foot={<FormattedMessage id="system.last24h" />}
        />
      </div>
      <div className="cols cols--1-1">
        <Panel
          title={<FormattedMessage id="system.perFamily" />}
          aside={
            <span className="muted">
              <FormattedMessage id="system.quota" />
            </span>
          }
        >
          <HBars
            rows={data.histogram.map((n, i) => ({
              label: <FormattedMessage id={`bucket.${bucketIds[i]}`} />,
              value: `${num(intl, n)} · ${pct(intl, n / total)}`,
              ratio: n / total,
              tone: i === 4 ? 'warn' : i === 5 ? 'purple' : undefined,
            }))}
          />
          <p className="muted">
            <FormattedMessage id="system.families" values={{ n: data.families }} />
          </p>
        </Panel>
        <Panel
          title={<FormattedMessage id="system.queue" />}
          aside={
            over ? (
              <Pill tone="warn">
                <FormattedMessage id="system.overThreshold" />
              </Pill>
            ) : (
              <Pill tone="ok">
                <FormattedMessage id="system.underThreshold" />
              </Pill>
            )
          }
        >
          <LineChart
            title={intl.formatMessage({ id: 'system.queue' })}
            points={data.videoQueue}
            labels={hours}
            threshold={data.videoThreshold}
            thresholdLabel={intl.formatMessage(
              { id: 'system.thresholdLine' },
              { n: data.videoThreshold },
            )}
            area={false}
          />
        </Panel>
      </div>
      <Panel
        title={<FormattedMessage id="system.near" />}
        aside={
          <span className="muted">
            <FormattedMessage id="storage.anon" />
          </span>
        }
        className="panel--flush"
      >
        {data.nearQuota.length === 0 ? (
          <Empty>
            <FormattedMessage id="system.nearEmpty" />
          </Empty>
        ) : (
          <table className="table">
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
                <th />
              </tr>
            </thead>
            <tbody>
              {data.nearQuota.map((f) => (
                <tr key={f.family}>
                  <td className="mono">
                    <strong>{f.family}</strong>
                  </td>
                  <td>
                    <FormattedMessage id="family.babies" values={{ n: f.babies }} />
                  </td>
                  <td>
                    {gb(intl, f.usedBytes)} · {pct(intl, f.usedBytes / Math.max(1, f.quotaBytes))}
                    <UsageBar
                      ratio={f.usedBytes / Math.max(1, f.quotaBytes)}
                      tone={usageTone(f.usedBytes, f.quotaBytes)}
                    />
                  </td>
                  <td>
                    <FormattedMessage
                      id={f.requested ? 'system.requested' : 'system.notRequested'}
                    />
                  </td>
                  <td>
                    <LockNote>
                      <FormattedMessage id="system.noPhotos" />
                    </LockNote>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Panel>
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

export function AiView({ data, now }: { data: AiStats; now: Date }) {
  const intl = useIntl();
  const k = data.kpis;
  const b = data.budget;
  const used = b.monthlyBudgetVnd ? b.spentVnd / b.monthlyBudgetVnd : 0;
  const total = Math.max(
    1,
    data.outcomes.editedSaved + data.outcomes.savedAsIs + data.outcomes.left,
  );
  const dayOfMonth = Number(
    new Intl.DateTimeFormat('en-GB', { day: 'numeric', timeZone: ZONE }).format(now),
  );
  const [y, m] = b.month.split('-').map(Number) as [number, number];
  const daysInMonth = new Date(Date.UTC(y, m, 0)).getUTCDate();
  const r = data.rollout;
  const rolloutNote = !r.enabled
    ? 'ai.rolloutOff'
    : r.scope === 'internal'
      ? 'ai.rolloutInternal'
      : r.scope === 'percent'
        ? 'ai.rolloutPercent'
        : 'ai.rolloutAll';
  return (
    <div className="grid">
      <div className="kpis">
        <Kpi label={<FormattedMessage id="ai.drafts" />} value={num(intl, k.drafts7d)} />
        <Kpi
          label={<FormattedMessage id="ai.saved" />}
          value={pct(intl, k.savedRate)}
          foot={<FormattedMessage id="ai.savedFoot" />}
        />
        <Kpi
          label={<FormattedMessage id="ai.cost" />}
          value={k.costPerDraftVnd === null ? '—' : vnd(intl, k.costPerDraftVnd)}
          foot={<FormattedMessage id="ai.budgetUsed" values={{ p: pct(intl, used) }} />}
          tone={used >= 0.8 ? 'warn' : 'muted'}
        />
        <Kpi
          label={<FormattedMessage id="ai.reports" />}
          value={num(intl, k.reports)}
          foot={<FormattedMessage id="ai.reportsFoot" />}
        />
      </div>
      <div className="cols cols--2-1">
        <Panel
          title={<FormattedMessage id="ai.daily" />}
          note={<FormattedMessage id={rolloutNote} values={{ p: r.percent }} />}
        >
          <LineChart
            title={intl.formatMessage({ id: 'ai.daily' })}
            points={data.daily.map((d) => d.drafts)}
            labels={data.daily.map((d) => shortDate(intl, `${d.date}T12:00:00+07:00`))}
          />
        </Panel>
        <Panel
          title={<FormattedMessage id="ai.outcomes" />}
          note={<FormattedMessage id="ai.last7" />}
        >
          <HBars
            rows={(['editedSaved', 'savedAsIs', 'left'] as const).map((key) => ({
              label: <FormattedMessage id={`ai.outcome.${key}`} />,
              value: pct(intl, data.outcomes[key] / total),
              ratio: data.outcomes[key] / total,
            }))}
          />
          <p className="muted">
            <FormattedMessage id="ai.outcomeCaption" />
          </p>
        </Panel>
      </div>
      <div className="cols cols--1-1">
        <Panel
          title={
            <FormattedMessage
              id="ai.budget"
              values={{
                month: intl.formatDate(`${b.month}-15`, { month: 'long', timeZone: ZONE }),
              }}
            />
          }
        >
          <p className="budget">
            <strong>{vnd(intl, b.spentVnd)}</strong> / {vnd(intl, b.monthlyBudgetVnd)}
          </p>
          <div className="budget__bar" aria-hidden="true">
            <span
              className={`budget__fill ${used >= 0.8 ? 'budget__fill--warn' : ''}`}
              style={{ width: `${Math.min(1, used) * 100}%` }}
            />
            <span className="budget__tick" style={{ left: '80%' }} />
          </div>
          <p className="muted">
            <FormattedMessage
              id="ai.budgetDay"
              values={{ p: pct(intl, used), day: dayOfMonth, days: daysInMonth }}
            />
          </p>
          <p className="note">
            <FormattedMessage id="ai.pauseNote" />
          </p>
        </Panel>
        <Panel title={<FormattedMessage id="ai.safety" />}>
          <dl className="kv kv--checks">
            {(['photos', 'name', 'retention', 'cap'] as const).map((key) => (
              <SafetyRow key={key} k={key} />
            ))}
          </dl>
          <p className="muted">
            <FormattedMessage id="ai.safetyFoot" />
          </p>
        </Panel>
      </div>
    </div>
  );
}

function SafetyRow({ k }: { k: string }) {
  return (
    <>
      <dt>
        <span className="check" aria-hidden="true">
          ✓
        </span>
        <FormattedMessage id={`ai.safe.${k}`} />
      </dt>
      <dd>
        <FormattedMessage id={`ai.safe.${k}Value`} />
      </dd>
    </>
  );
}
