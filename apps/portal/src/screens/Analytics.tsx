import { staffCan } from '@child-life/contracts';
import { useEffect, useState } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import {
  ApiError,
  useApi,
  useLoad,
  type AnalyticsFeatures,
  type AnalyticsGrowth,
  type AnalyticsResult,
  type Delta,
} from '../api';
import { routePaths, subPath, useStaff } from '../context';
import { bytes, downloadCsv, pct, shortDate, toCsv } from '../format';
import {
  Button,
  Empty,
  HBars,
  Kpi,
  LineChart,
  Loaded,
  LockNote,
  Page,
  Panel,
  Segmented,
  errorMessageId,
  TableScroll,
} from '../ui';

/**
 * Phân tích (Figma A13 / A14; P-137): aggregates from the nightly rollup only, one definition of
 * "Hoạt động" shared with Tổng quan and Gia đình. The design's "Kỹ thuật" tab is not drawn, so it
 * is hidden (G-086). "Xuất CSV" needs "Phân tích · xuất CSV" and is logged.
 */

type Tab = 'growth' | 'features';
type Days = 7 | 30 | 90;
type Platform = 'all' | 'ios' | 'android';

function deltaFoot(intl: IntlShape, d: Delta) {
  if (d.change !== undefined && d.change !== null) {
    return {
      text: intl.formatMessage(
        { id: d.change >= 0 ? 'analytics.up' : 'analytics.down' },
        { v: pct(intl, Math.abs(d.change)) },
      ),
      tone: d.change >= 0 ? ('up' as const) : ('down' as const),
    };
  }
  if (d.points !== undefined && d.points !== null) {
    return {
      text: intl.formatMessage(
        { id: d.points >= 0 ? 'analytics.upPoints' : 'analytics.downPoints' },
        { v: intl.formatNumber(Math.abs(d.points * 100), { maximumFractionDigits: 1 }) },
      ),
      tone: d.points >= 0 ? ('up' as const) : ('warn' as const),
    };
  }
  return { text: intl.formatMessage({ id: 'analytics.noPrev' }), tone: 'muted' as const };
}

function DeltaKpi({ label, value, d }: { label: string; value: string; d: Delta }) {
  const intl = useIntl();
  const foot = deltaFoot(intl, d);
  return (
    <Kpi label={<FormattedMessage id={label} />} value={value} foot={foot.text} tone={foot.tone} />
  );
}

export function AnalyticsScreen() {
  const intl = useIntl();
  const api = useApi();
  const staff = useStaff();
  const [tab, setTab] = useState<Tab>(() =>
    subPath('analytics', window.location.pathname)[0] === 'features' ? 'features' : 'growth',
  );
  const [days, setDays] = useState<Days>(30);
  const [platform, setPlatform] = useState<Platform>('all');
  const [error, setError] = useState<ApiError | null>(null);
  useEffect(() => {
    const url = tab === 'growth' ? routePaths.analytics : `${routePaths.analytics}/features`;
    if (window.location.pathname !== url) window.history.replaceState({}, '', url);
  }, [tab]);
  const req = { tab, days, platform };
  const [load, reload] = useLoad<AnalyticsResult>(
    'staffAnalytics',
    req,
    `${tab}|${days}|${platform}`,
  );
  const exportCsv = async () => {
    setError(null);
    try {
      const r = await api.call<AnalyticsResult>('staffExportAnalytics', req);
      downloadCsv(`child-life-analytics-${tab}-${days}d-${platform}.csv`, analyticsCsv(r));
    } catch (e) {
      setError(e instanceof ApiError ? e : new ApiError('unknown', null));
    }
  };
  return (
    <Page
      title={<FormattedMessage id="analytics.title" />}
      subtitle={<FormattedMessage id="analytics.sub" />}
      actions={
        staffCan(staff.levels, 'analytics.export') && (
          <Button onClick={() => void exportCsv()}>
            <FormattedMessage id="action.exportCsv" />
          </Button>
        )
      }
    >
      <div className="stack">
        <div className="toolbar">
          <Segmented
            label={intl.formatMessage({ id: 'analytics.title' })}
            value={tab}
            onChange={setTab}
            options={[
              { value: 'growth' as Tab, label: <FormattedMessage id="analytics.tab.growth" /> },
              { value: 'features' as Tab, label: <FormattedMessage id="analytics.tab.features" /> },
            ]}
          />
          <div className="qa-filters">
            <select
              className="select"
              value={platform}
              onChange={(e) => setPlatform(e.target.value as Platform)}
              aria-label={intl.formatMessage({ id: 'analytics.platform' })}
            >
              {(['all', 'ios', 'android'] as const).map((p) => (
                <option key={p} value={p}>
                  {intl.formatMessage({ id: `analytics.platform.${p}` })}
                </option>
              ))}
            </select>
            <select
              className="select"
              value={days}
              onChange={(e) => setDays(Number(e.target.value) as Days)}
              aria-label={intl.formatMessage({ id: 'analytics.range' })}
            >
              {([7, 30, 90] as Days[]).map((d) => (
                <option key={d} value={d}>
                  {intl.formatMessage({ id: 'analytics.rangeDays' }, { n: d })}
                </option>
              ))}
            </select>
          </div>
        </div>
        {error && (
          <p className="error" role="alert">
            <FormattedMessage id={errorMessageId(error)} />
          </p>
        )}
        <Loaded load={load} reload={reload}>
          {(r) =>
            r.empty ? (
              <Panel>
                <Empty>
                  <FormattedMessage id="analytics.empty" />
                </Empty>
              </Panel>
            ) : 'channels' in r ? (
              <GrowthView data={r} />
            ) : (
              <FeaturesView data={r} />
            )
          }
        </Loaded>
        <LockNote>
          <FormattedMessage id="analytics.definition" />
        </LockNote>
      </div>
    </Page>
  );
}

export function GrowthView({ data }: { data: AnalyticsGrowth }) {
  const intl = useIntl();
  const [series, setSeries] = useState<'dau' | 'wau' | 'mau'>('dau');
  const k = data.kpis;
  const n = (v: number | null) => (v === null ? '—' : intl.formatNumber(v));
  const channelTotal = data.channels.invite + data.channels.website + data.channels.store;
  const platformTotal = data.platforms.ios + data.platforms.android;
  const share = (v: number, total: number) => (total ? v / total : 0);
  return (
    <div className="stack">
      <div className="kpis kpis--5">
        <DeltaKpi label="analytics.dau" value={n(k.dau.value)} d={k.dau} />
        <DeltaKpi label="analytics.wau" value={n(k.wau.value)} d={k.wau} />
        <DeltaKpi label="analytics.mau" value={n(k.mau.value)} d={k.mau} />
        <DeltaKpi
          label="analytics.stickiness"
          value={pct(intl, k.stickiness.value)}
          d={k.stickiness}
        />
        <DeltaKpi label="analytics.d30" value={pct(intl, k.d30.value)} d={k.d30} />
      </div>
      <div className="cols cols--2-1">
        <Panel
          title={<FormattedMessage id="analytics.activeFamilies" />}
          aside={
            <Segmented
              label={intl.formatMessage({ id: 'analytics.activeFamilies' })}
              value={series}
              onChange={setSeries}
              options={(['dau', 'wau', 'mau'] as const).map((s) => ({
                value: s,
                label: <FormattedMessage id={`analytics.series.${s}`} />,
              }))}
            />
          }
        >
          <LineChart
            title={intl.formatMessage({ id: 'analytics.activeFamilies' })}
            points={data.series.map((p) => p[series])}
            labels={data.series.map((p) => shortDate(intl, `${p.date}T05:00:00Z`))}
          />
        </Panel>
        <Panel
          title={<FormattedMessage id="analytics.sources" />}
          note={<FormattedMessage id="analytics.newFamilies" values={{ n: data.newFamilies }} />}
        >
          <div className="sources">
            <section>
              <h3 className="sources__head">
                <FormattedMessage id="analytics.channel" />
              </h3>
              <HBars
                rows={(['invite', 'website', 'store'] as const).map((c) => ({
                  label: <FormattedMessage id={`analytics.channel.${c}`} />,
                  value: `${intl.formatNumber(data.channels[c])} · ${pct(intl, share(data.channels[c], channelTotal))}`,
                  ratio: share(data.channels[c], channelTotal),
                }))}
              />
            </section>
            <section>
              <h3 className="sources__head">
                <FormattedMessage id="analytics.platform" />
              </h3>
              <HBars
                rows={(['ios', 'android'] as const).map((p) => ({
                  label: <FormattedMessage id={`platform.${p}`} />,
                  value: `${intl.formatNumber(data.platforms[p])} · ${pct(intl, share(data.platforms[p], platformTotal))}`,
                  ratio: share(data.platforms[p], platformTotal),
                  ...(p === 'android' ? { tone: 'purple' } : {}),
                }))}
              />
            </section>
            <p className="field__help">
              <FormattedMessage id="analytics.channelNote" />
            </p>
          </div>
        </Panel>
      </div>
      <Panel
        className="panel--flush"
        title={<FormattedMessage id="analytics.cohorts" />}
        note={<FormattedMessage id="analytics.cohortsNote" />}
      >
        <div className="matrix-wrap">
          <table className="table heat">
            <thead>
              <tr>
                <th>
                  <FormattedMessage id="analytics.cohort" />
                </th>
                <th>
                  <FormattedMessage id="analytics.families" />
                </th>
                {Array.from({ length: 8 }, (_, i) => (
                  <th key={i}>T{i}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {data.cohorts.map((c) => (
                <tr key={c.week}>
                  <td className="nowrap">
                    <FormattedMessage id="analytics.week" values={{ w: c.week.slice(-2) }} />
                  </td>
                  <td>{intl.formatNumber(c.families)}</td>
                  {Array.from({ length: 8 }, (_, i) => {
                    const v = c.retention[i];
                    return (
                      <td
                        key={i}
                        className="heat__cell"
                        style={
                          v === undefined || v === null
                            ? undefined
                            : {
                                background: `rgb(53 170 155 / ${0.12 + v * 0.75})`,
                                color: v > 0.55 ? '#fff' : undefined,
                              }
                        }
                      >
                        {v === undefined || v === null ? '' : pct(intl, v)}
                      </td>
                    );
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Panel>
    </div>
  );
}

export function FeaturesView({ data }: { data: AnalyticsFeatures }) {
  const intl = useIntl();
  const k = data.kpis;
  const s = data.storage;
  const totalVersions = data.versions.reduce((n, v) => n + v.devices, 0);
  const round = (v: number | null) => (v === null ? '—' : intl.formatNumber(Math.round(v)));
  return (
    <div className="stack">
      <div className="kpis">
        <DeltaKpi label="analytics.carePerDay" value={round(k.carePerDay.value)} d={k.carePerDay} />
        <DeltaKpi
          label="analytics.memoriesPerWeek"
          value={round(k.memoriesPerWeek.value)}
          d={k.memoriesPerWeek}
        />
        <DeltaKpi
          label="analytics.storiesPerWeek"
          value={round(k.storiesPerWeek.value)}
          d={k.storiesPerWeek}
        />
        <DeltaKpi
          label="analytics.relativesShare"
          value={pct(intl, k.relativesShare.value)}
          d={k.relativesShare}
        />
      </div>
      <Panel
        className="panel--flush"
        title={<FormattedMessage id="analytics.usage" />}
        note={<FormattedMessage id="analytics.usageNote" />}
      >
        <TableScroll min={640}>
          <table className="table">
            <thead>
              <tr>
                <th>
                  <FormattedMessage id="analytics.feature" />
                </th>
                <th>
                  <FormattedMessage id="analytics.familiesUsing" />
                </th>
                <th>
                  <FormattedMessage id="analytics.perDay" />
                </th>
                <th>
                  <FormattedMessage id="analytics.vsPrev" />
                </th>
              </tr>
            </thead>
            <tbody>
              {data.features.map((f) => (
                <tr key={f.feature}>
                  <td>
                    <strong>
                      <FormattedMessage id={`analytics.feature.${f.feature}`} />
                    </strong>
                    <br />
                    <span className="muted">
                      <FormattedMessage id={`analytics.feature.${f.feature}.note`} />
                    </span>
                  </td>
                  <td className="cell-progress">
                    <span className="bar" aria-hidden="true">
                      <span
                        className="bar__fill bar__fill--ok"
                        style={{ width: `${(f.share ?? 0) * 100}%` }}
                      />
                    </span>
                    <span className="muted">{pct(intl, f.share)}</span>
                  </td>
                  <td>{intl.formatNumber(Math.round(f.perDay))}</td>
                  <td className={f.change === null ? 'muted' : f.change >= 0 ? 'up' : 'down'}>
                    {f.change === null
                      ? '—'
                      : intl.formatMessage(
                          { id: f.change >= 0 ? 'analytics.up' : 'analytics.down' },
                          { v: pct(intl, Math.abs(f.change)) },
                        )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      </Panel>
      <div className="cols cols--1-1">
        <Panel title={<FormattedMessage id="analytics.storage" />}>
          <HBars
            rows={(['photo', 'video', 'other'] as const).map((t) => {
              const v = t === 'photo' ? s.photoBytes : t === 'video' ? s.videoBytes : s.otherBytes;
              return {
                label: <FormattedMessage id={`analytics.storage.${t}`} />,
                value: `${bytes(intl, v)} · ${pct(intl, s.usedBytes ? v / s.usedBytes : null)}`,
                ratio: s.usedBytes ? v / s.usedBytes : 0,
                ...(t === 'video' ? { tone: 'purple' } : {}),
              };
            })}
          />
          <dl className="kv">
            <dt>
              <FormattedMessage id="analytics.storage.base" />
            </dt>
            <dd>
              <FormattedMessage id="analytics.familiesN" values={{ n: s.baseFamilies }} />
            </dd>
            <dt>
              <FormattedMessage id="analytics.storage.expanded" />
            </dt>
            <dd>
              <FormattedMessage id="analytics.familiesN" values={{ n: s.expandedFamilies }} />
            </dd>
            <dt>
              <FormattedMessage id="analytics.storage.over80" />
            </dt>
            <dd>
              <FormattedMessage id="analytics.familiesN" values={{ n: s.over80Families }} />
            </dd>
          </dl>
        </Panel>
        <Panel
          title={<FormattedMessage id="analytics.versions" />}
          note={<FormattedMessage id="analytics.versionsNote" />}
        >
          {data.versions.length === 0 ? (
            <p className="muted">
              <FormattedMessage id="analytics.noDevices" />
            </p>
          ) : (
            <HBars
              rows={data.versions.slice(0, 8).map((v) => ({
                label: `${intl.formatMessage({ id: `platform.${v.platform}` })} ${v.version}`,
                value: `${intl.formatNumber(v.devices)} · ${pct(intl, totalVersions ? v.devices / totalVersions : null)}`,
                ratio: totalVersions ? v.devices / totalVersions : 0,
                ...(v.platform === 'android' ? { tone: 'purple' } : {}),
              }))}
            />
          )}
        </Panel>
      </div>
    </div>
  );
}

/** The exported CSV: one "section,key,value" row per figure on screen. */
export function analyticsCsv(r: AnalyticsResult): string {
  const rows: unknown[][] = [['section', 'key', 'value']];
  if (r.empty) return toCsv(rows[0] as string[], []);
  if ('channels' in r) {
    for (const [k, d] of Object.entries(r.kpis)) rows.push(['kpi', k, d.value]);
    for (const p of r.series) rows.push(['active', p.date, `${p.dau}/${p.wau}/${p.mau}`]);
    for (const [k, v] of Object.entries(r.channels)) rows.push(['channel', k, v]);
    for (const [k, v] of Object.entries(r.platforms)) rows.push(['platform', k, v]);
    for (const c of r.cohorts)
      rows.push([
        'cohort',
        c.week,
        c.retention.map((x) => (x === null ? '' : x.toFixed(3))).join(' '),
      ]);
  } else {
    for (const [k, d] of Object.entries(r.kpis)) rows.push(['kpi', k, d.value]);
    for (const f of r.features) rows.push(['feature', f.feature, `${f.share ?? ''}/${f.perDay}`]);
    for (const [k, v] of Object.entries(r.storage)) rows.push(['storage', k, v]);
    for (const v of r.versions) rows.push(['version', `${v.platform} ${v.version}`, v.devices]);
  }
  return toCsv(rows[0] as string[], rows.slice(1));
}
