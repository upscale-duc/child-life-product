import {
  engagementKinds,
  engagementStages,
  notificationKinds,
  notificationTemplates,
  notificationTypes,
  staffCan,
  type EngagementKind,
  type ProductAnalyticsRequest,
  type ProductAnalyticsResult,
} from '@child-life/contracts';
import { FormattedMessage, useIntl } from 'react-intl';
import { useLoad } from '../../api';
import { EmptyState, Notice, Section } from '../../content-kit';
import { useStaff } from '../../context';
import { pct } from '../../format';
import { Loaded, LockNote, Pill, TableScroll } from '../../ui';
import { analyticsClosedRange } from '../ProductAnalytics';
import { FallbackChain, destinationName, pick } from './shared';

/** The notification kinds a Smart Engagement scenario sends (ENG-04 rides the Care reminder). */
export function kindsOfScenario(eng: EngagementKind) {
  return notificationKinds
    .map((k) => notificationTypes[k])
    .filter((d) => d.engagement.includes(eng));
}

export function JourneysTab() {
  const staff = useStaff();
  return (
    <div className="stack">
      <JourneyCards />
      {staffCan(staff.levels, 'analytics.view') ? (
        <JourneyFunnelLoader />
      ) : (
        <LockNote>
          <FormattedMessage id="ntf.journeys.noAnalytics" />
        </LockNote>
      )}
    </div>
  );
}

/** ENG-01 … ENG-06: what each scenario sends, with which template, to which screen. */
export function JourneyCards() {
  const intl = useIntl();
  return (
    <div className="grid gap-3 lg:grid-cols-2">
      {engagementKinds.map((eng) => {
        const kinds = kindsOfScenario(eng);
        return (
          <article key={eng} className="rounded-xl border bg-card p-4" data-scenario={eng}>
            <header className="mb-2 flex flex-wrap items-center gap-2">
              <Pill tone="purple">{eng}</Pill>
              <h3 className="text-[15px] font-semibold">
                <FormattedMessage id={`ntf.eng.${eng}`} />
              </h3>
            </header>
            <p className="mb-3 text-sm text-muted-foreground">
              <FormattedMessage id={`ntf.eng.${eng}.about`} />
            </p>
            <dl className="grid gap-x-3 gap-y-1.5 text-sm sm:grid-cols-[minmax(0,8rem)_minmax(0,1fr)]">
              {kinds.map((def) => (
                <div key={def.kind} className="contents">
                  <dt className="text-muted-foreground">
                    <FormattedMessage id="ntf.col.kind" />
                  </dt>
                  <dd>
                    <FormattedMessage id={`ntf.kind.${def.kind}`} />
                  </dd>
                  <dt className="text-muted-foreground">
                    <FormattedMessage id="ntf.col.templates" />
                  </dt>
                  <dd>
                    {def.templates
                      .map((t) => pick(intl, notificationTemplates[t].name))
                      .join(', ') || '—'}
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
                  <dt className="text-muted-foreground">
                    <FormattedMessage id="ntf.col.trigger" />
                  </dt>
                  <dd>{pick(intl, def.trigger)}</dd>
                </div>
              ))}
            </dl>
          </article>
        );
      })}
    </div>
  );
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

function JourneyFunnelLoader() {
  const request = journeyRequest();
  const [load, reload] = useLoad<ProductAnalyticsResult>(
    'staffProductAnalytics',
    request,
    `ntf-journeys:${request.from}:${request.to}`,
  );
  return (
    <Loaded load={load} reload={reload}>
      {(data) => <JourneyFunnel data={data} />}
    </Loaded>
  );
}

/**
 * The engagement funnel from Phân tích sản phẩm (same aggregates, not recomputed). A disabled or
 * empty section says so; numbers are never filled in.
 */
export function JourneyFunnel({ data }: { data: ProductAnalyticsResult }) {
  const intl = useIntl();
  const ready = data.status === 'ready' && data.engagement.length > 0;
  return (
    <Section
      title={<FormattedMessage id="ntf.journeys.funnel" />}
      description={
        <FormattedMessage
          id="ntf.journeys.funnelNote"
          values={{ from: data.range.from, to: data.range.to }}
        />
      }
      flush
    >
      {!ready ? (
        <EmptyState
          title={
            <FormattedMessage
              id={`ntf.journeys.status.${data.status === 'ready' ? 'no_data' : data.status}`}
            />
          }
        />
      ) : (
        <>
          {!data.collectionEnabled && (
            <div className="px-5 pt-3">
              <Notice tone="warn">
                <FormattedMessage id="ntf.journeys.collectionOff" />
              </Notice>
            </div>
          )}
          <TableScroll min={1100}>
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
                  <th className="text-right">
                    <FormattedMessage id="ntf.journeys.conversion" />
                  </th>
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
                    <td
                      className="text-right tabular-nums"
                      title={
                        e.conversion.numerator !== null && e.conversion.denominator !== null
                          ? `${e.conversion.numerator} / ${e.conversion.denominator}`
                          : undefined
                      }
                    >
                      {e.conversion.value === null || !e.conversion.denominator
                        ? '—'
                        : pct(intl, e.conversion.value, 1)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </TableScroll>
        </>
      )}
    </Section>
  );
}
