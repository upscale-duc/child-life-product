import {
  engagementKinds,
  engagementStages,
  notificationKinds,
  notificationTemplates,
  notificationTypes,
  staffCan,
  type EngagementKind,
  type EngagementStage,
  type ProductAnalyticsRequest,
  type ProductAnalyticsResult,
} from '@child-life/contracts';
import { useEffect, useRef } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { useLoad } from '../../api';
import { Notice, Section } from '../../content-kit';
import { useStaff } from '../../context';
import { pct } from '../../format';
import { HBars, LockNote, Pill } from '../../ui';
import { analyticsClosedRange } from '../ProductAnalytics';
import { DataTable, LoadedSkeleton, TabHeader, TilesSkeleton } from './kit';
import { FallbackChain, destinationName, pick } from './shared';

/** The notification kinds a Smart Engagement scenario sends (ENG-04 rides the Care reminder). */
export function kindsOfScenario(eng: EngagementKind) {
  return notificationKinds
    .map((k) => notificationTypes[k])
    .filter((d) => d.engagement.includes(eng));
}

export const journeyRequest = (now = new Date()): ProductAnalyticsRequest => ({
  schemaVersion: 2,
  section: 'engagement',
  ...analyticsClosedRange(30, now),
  platform: 'all',
  locale: 'all',
  ageBand: 'all',
  context: 'all',
  chapter: 'all',
  comparison: false,
});

/** The funnel steps shown per scenario. */
export const funnelSteps: EngagementStage[] = [
  'eligible',
  'scheduled',
  'accepted',
  'opened',
  'completed',
];

/**
 * One scenario's funnel; each step's share is of the first step. A missing stage stays null
 * ("—"), and with no eligible opportunities there is no funnel at all (not a row of zeros).
 */
export function funnelOf(
  stages: Partial<Record<EngagementStage, number | null>> | undefined,
): Array<{ stage: EngagementStage; n: number | null; ratio: number }> | null {
  if (!stages) return null;
  const top = stages.eligible ?? null;
  if (top === null || top <= 0) return null;
  return funnelSteps.map((stage) => {
    const n = stages[stage] ?? null;
    return { stage, n, ratio: n === null ? 0 : n / top };
  });
}

export function JourneysTab() {
  const staff = useStaff();
  const canAnalytics = staffCan(staff.levels, 'analytics.view');
  return (
    <div className="stack">
      <TabHeader
        title={<FormattedMessage id="ntf.tab.journeys" />}
        purpose={<FormattedMessage id="ntf.purpose.journeys" />}
      />
      {canAnalytics ? (
        <JourneysLoader />
      ) : (
        <>
          <LockNote>
            <FormattedMessage id="ntf.journeys.noAnalytics" />
          </LockNote>
          <JourneysView data={null} />
        </>
      )}
    </div>
  );
}

function JourneysLoader() {
  const request = journeyRequest();
  const [load, reload] = useLoad<ProductAnalyticsResult>(
    'staffProductAnalytics',
    request,
    `ntf-journeys:${request.from}:${request.to}`,
  );
  // Like Product analytics: a snapshot being computed is fetched again (1.5 s, at most 20 times).
  const attempts = useRef(0);
  useEffect(() => {
    if (load.status !== 'ok' || load.data.status !== 'preparing' || attempts.current >= 20) return;
    attempts.current++;
    const timer = window.setTimeout(reload, 1500);
    return () => window.clearTimeout(timer);
  }, [load, reload]);
  return (
    <LoadedSkeleton load={load} reload={reload} skeleton={<TilesSkeleton n={6} />}>
      {(data) => <JourneysView data={data} />}
    </LoadedSkeleton>
  );
}

/**
 * ENG-01 … ENG-06: what each scenario sends (kind, template, destination) and its 30-day funnel
 * from Phân tích sản phẩm — the same aggregates, never recomputed or filled in.
 */
export function JourneysView({ data }: { data: ProductAnalyticsResult | null }) {
  const intl = useIntl();
  const ready = !!data && data.status === 'ready' && data.engagement.length > 0;
  return (
    <div className="stack">
      {data && !ready && (
        <Notice tone={data.status === 'disabled' ? 'warn' : 'info'}>
          <FormattedMessage
            id={`ntf.journeys.status.${data.status === 'ready' ? 'no_data' : data.status}`}
          />
        </Notice>
      )}
      {data && ready && !data.collectionEnabled && (
        <Notice tone="warn">
          <FormattedMessage id="ntf.journeys.collectionOff" />
        </Notice>
      )}
      {data && (
        <p className="text-[13px] text-muted-foreground">
          <FormattedMessage
            id="ntf.journeys.funnelNote"
            values={{ from: data.range.from, to: data.range.to }}
          />
        </p>
      )}
      <div className="grid gap-3 lg:grid-cols-2">
        {engagementKinds.map((eng) => {
          const kinds = kindsOfScenario(eng);
          const row = ready ? data.engagement.find((e) => e.kind === eng) : undefined;
          const funnel = funnelOf(row?.stages);
          return (
            <article
              key={eng}
              className="grid content-start gap-3 rounded-xl border bg-card p-4"
              data-scenario={eng}
            >
              <header className="flex flex-wrap items-center gap-2">
                <Pill tone="muted">{eng}</Pill>
                <h3 className="text-[15px] font-semibold">
                  <FormattedMessage id={`ntf.eng.${eng}`} />
                </h3>
                {row && row.conversion.value !== null && row.conversion.denominator ? (
                  <span
                    className="ml-auto text-[13px] text-muted-foreground tabular-nums"
                    title={`${row.conversion.numerator ?? '—'} / ${row.conversion.denominator}`}
                  >
                    <FormattedMessage
                      id="ntf.journeys.conversionShort"
                      values={{ v: pct(intl, row.conversion.value, 1) }}
                    />
                  </span>
                ) : null}
              </header>
              <p className="text-sm text-muted-foreground">
                <FormattedMessage id={`ntf.eng.${eng}.about`} />
              </p>
              {funnel ? (
                <HBars
                  rows={funnel.map((f) => ({
                    label: <FormattedMessage id={`ntf.stage.${f.stage}`} />,
                    value: f.n === null ? '—' : intl.formatNumber(f.n),
                    ratio: f.ratio,
                  }))}
                />
              ) : (
                data && (
                  <p className="rounded-md bg-muted/50 px-3 py-2 text-[13px] text-muted-foreground">
                    <FormattedMessage id="ntf.journeys.noFunnel" />
                  </p>
                )
              )}
              <dl className="grid gap-x-3 gap-y-1 border-t pt-3 text-[13px] sm:grid-cols-[minmax(0,7rem)_minmax(0,1fr)]">
                {kinds.map((def) => (
                  <div key={def.kind} className="contents">
                    <dt className="text-muted-foreground">
                      <FormattedMessage id="ntf.col.kind" />
                    </dt>
                    <dd>
                      <FormattedMessage id={`ntf.kind.${def.kind}`} />
                      {def.templates.length > 0 && (
                        <span className="text-muted-foreground">
                          {' · '}
                          {def.templates
                            .map((t) => pick(intl, notificationTemplates[t].name))
                            .join(', ')}
                        </span>
                      )}
                    </dd>
                    <dt className="text-muted-foreground">
                      <FormattedMessage id="ntf.col.destination" />
                    </dt>
                    <dd>
                      {destinationName(intl, def.destination)}
                      <span className="block text-[12px] text-muted-foreground">
                        <FallbackChain id={def.destination} />
                      </span>
                    </dd>
                  </div>
                ))}
              </dl>
            </article>
          );
        })}
      </div>
      {ready && (
        <Section
          flush
          collapsible
          defaultOpen={false}
          title={<FormattedMessage id="ntf.journeys.allStages" />}
        >
          <DataTable min={1100} tall>
            <table className="table">
              <thead>
                <tr>
                  <th>
                    <FormattedMessage id="ntf.col.scenario" />
                  </th>
                  {engagementStages.map((s) => (
                    <th key={s} className="text-right">
                      <FormattedMessage id={`ntf.stage.${s}`} />
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {data.engagement.map((e) => (
                  <tr key={e.kind}>
                    <td className="nowrap">
                      <span className="font-medium">{e.kind}</span>{' '}
                      <FormattedMessage id={`ntf.eng.${e.kind}`} />
                    </td>
                    {engagementStages.map((s) => (
                      <td key={s} className="text-right tabular-nums">
                        {e.stages[s] == null ? '—' : intl.formatNumber(e.stages[s])}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </DataTable>
        </Section>
      )}
    </div>
  );
}
