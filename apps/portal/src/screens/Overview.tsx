import { useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { useLoad, type OpsAlert, type Overview } from '../api';
import { useNavigate, type Route } from '../context';
import { delta, downloadCsv, num, pct, shortDate, toCsv } from '../format';
import {
  Button,
  HBars,
  Kpi,
  LineChart,
  Loaded,
  Page,
  Panel,
  Pill,
  Segmented,
  StackedBars,
} from '../ui';

/** A02 Tổng quan: system-wide aggregates only, never a family's photos, captions or records. */
export function OverviewScreen() {
  const [days, setDays] = useState<7 | 30 | 90>(30);
  const [load, reload] = useLoad<Overview>('staffOverview', { days }, String(days));
  const intl = useIntl();
  const exportCsv = () => {
    if (load.status !== 'ok') return;
    const d = load.data;
    downloadCsv(
      `child-life-overview-${days}d.csv`,
      toCsv(
        ['metric', 'value'],
        [
          ['activeFamilies', d.kpis.activeFamilies],
          ['newAccounts', d.kpis.newAccounts],
          ['setupRate', d.kpis.setupRate],
          ['multiCarerRate', d.kpis.multiCarerRate],
          ...d.daily.map((p) => [`activeFamilies.${p.date}`, p.families]),
          ...d.funnel.map((f) => [`funnel.${f.step}`, f.count]),
          ...d.weekly.map((w) => [
            `careLogs.${w.weekStart.slice(0, 10)}`,
            w.feed + w.sleep + w.diaper,
          ]),
        ],
      ),
    );
  };
  return (
    <Page
      title={<FormattedMessage id="overview.title" />}
      info={<FormattedMessage id="overview.sub" />}
      actions={
        <>
          <Segmented
            label={intl.formatMessage({ id: 'overview.window' })}
            value={days}
            onChange={setDays}
            options={[7, 30, 90].map((d) => ({
              value: d as 7 | 30 | 90,
              label: <FormattedMessage id="fmt.days" values={{ n: d }} />,
            }))}
          />
          <Button onClick={exportCsv} disabled={load.status !== 'ok'}>
            <FormattedMessage id="action.exportCsv" />
          </Button>
        </>
      }
    >
      <Loaded load={load} reload={reload}>
        {(data) => <OverviewView data={data} days={days} />}
      </Loaded>
    </Page>
  );
}

const alertRoute: Record<OpsAlert['module'], Route> = {
  jobs: 'jobs',
  storage: 'storage',
  system: 'system',
  support: 'support',
};

export function OverviewView({ data, days }: { data: Overview; days: number }) {
  const intl = useIntl();
  const navigate = useNavigate();
  const { kpis } = data;
  const ratioFoot = (cur: number, prev: number) => {
    const d = delta(cur, prev);
    if (d === null)
      return { foot: <FormattedMessage id="overview.noPrev" />, tone: 'muted' as const };
    return {
      foot: (
        <FormattedMessage
          id={d >= 0 ? 'overview.up' : 'overview.down'}
          values={{ p: pct(intl, Math.abs(d)), n: days }}
        />
      ),
      tone: d >= 0 ? ('up' as const) : ('down' as const),
    };
  };
  const active = ratioFoot(kpis.activeFamilies, kpis.activeFamiliesPrev);
  const accounts = ratioFoot(kpis.newAccounts, kpis.newAccountsPrev);
  const first = data.funnel.find((f) => f.count !== null)?.count ?? 0;
  return (
    <div className="grid gap-4">
      <div className="kpis">
        <Kpi
          label={<FormattedMessage id="overview.active" />}
          value={num(intl, kpis.activeFamilies)}
          foot={active.foot}
          tone={active.tone}
        />
        <Kpi
          label={<FormattedMessage id="overview.newAccounts" />}
          value={num(intl, kpis.newAccounts)}
          foot={accounts.foot}
          tone={accounts.tone}
        />
        <Kpi
          label={<FormattedMessage id="overview.setup" />}
          value={pct(intl, kpis.setupRate)}
          foot={<FormattedMessage id="overview.setupFoot" />}
        />
        <Kpi
          label={<FormattedMessage id="overview.multi" />}
          value={pct(intl, kpis.multiCarerRate)}
          foot={<FormattedMessage id="overview.multiFoot" />}
        />
      </div>
      <div className="cols cols--2-1">
        <Panel
          title={<FormattedMessage id="overview.daily" />}
          note={<FormattedMessage id="overview.dailyNote" />}
        >
          <LineChart
            title={intl.formatMessage({ id: 'overview.daily' })}
            points={data.daily.map((d) => d.families)}
            labels={data.daily.map((d) => shortDate(intl, `${d.date}T12:00:00+07:00`))}
          />
        </Panel>
        <Panel
          title={<FormattedMessage id="overview.attention" />}
          aside={<span className="count">{data.alerts.length}</span>}
        >
          {data.alerts.length === 0 ? (
            <p className="muted">
              <FormattedMessage id="overview.allClear" />
            </p>
          ) : (
            <ul className="alerts">
              {data.alerts.map((a) => (
                <li key={a.kind}>
                  <button
                    type="button"
                    className="alerts__item"
                    onClick={() => navigate(alertRoute[a.module])}
                  >
                    <Pill tone={a.severity === 'wait' ? 'info' : a.severity}>
                      <FormattedMessage id={`severity.${a.severity}`} />
                    </Pill>
                    <span className="alerts__text">
                      <FormattedMessage id={`alert.${a.kind}`} values={{ n: a.count }} />
                    </span>
                    <span className="alerts__module">
                      <FormattedMessage id={`nav.${alertRoute[a.module]}`} />
                    </span>
                    <span aria-hidden="true">›</span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </Panel>
      </div>
      <div className="cols cols--1-1">
        <Panel
          title={<FormattedMessage id="overview.funnel" />}
          note={<FormattedMessage id="overview.funnelNote" values={{ n: days }} />}
        >
          <HBars
            rows={data.funnel.map((f) => ({
              label: <FormattedMessage id={`funnel.${f.step}`} />,
              value:
                f.count === null ? (
                  <FormattedMessage id="funnel.notTracked" />
                ) : (
                  `${num(intl, f.count)} · ${pct(intl, first ? f.count / first : null)}`
                ),
              ratio: f.count === null || !first ? 0 : f.count / first,
            }))}
          />
        </Panel>
        <Panel
          title={<FormattedMessage id="overview.weekly" />}
          note={<FormattedMessage id="overview.weeklyNote" />}
        >
          <StackedBars
            title={intl.formatMessage({ id: 'overview.weekly' })}
            series={data.weekly}
            labels={data.weekly.map((w) => shortDate(intl, w.weekStart))}
            keys={[
              {
                key: 'feed',
                label: intl.formatMessage({ id: 'care.feed' }),
                className: 'fill-feed',
              },
              {
                key: 'sleep',
                label: intl.formatMessage({ id: 'care.sleep' }),
                className: 'fill-sleep',
              },
              {
                key: 'diaper',
                label: intl.formatMessage({ id: 'care.diaper' }),
                className: 'fill-diaper',
              },
            ]}
          />
        </Panel>
      </div>
    </div>
  );
}
