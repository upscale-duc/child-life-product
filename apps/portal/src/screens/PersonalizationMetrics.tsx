import { FormattedMessage } from 'react-intl';
import { useLoad, type RhythmView } from '../api';
import { Section } from '../content-kit';
import { Loaded, TableScroll } from '../ui';

/**
 * Phân tích › Cá nhân hoá (was Nhịp lớn lên › Hiệu quả cá nhân hoá; owner 2026-10-21). P-172 D2:
 * anonymous counts, no unsupported conversion rates or delivery claims.
 */
export function PersonalizationMetricsLoader() {
  const [load, reload] = useLoad<RhythmView>('staffRhythm', {}, 'rhythm');
  return (
    <Loaded load={load} reload={reload}>
      {(view) => <PersonalizationMetrics metrics={view.metrics} />}
    </Loaded>
  );
}

export function PersonalizationMetrics({ metrics }: { metrics: RhythmView['metrics'] }) {
  const actions = ['save', 'intend', 'tried', 'helpful', 'unsure', 'exclude'] as const;
  const funnel = [
    'checkinSaved',
    'nextActionShown',
    'suggestionStarted',
    'feedbackSaved',
    'digestScheduled',
    'digestOpened',
  ] as const;
  if (!metrics?.content.length && !metrics?.funnel.length) {
    return (
      <Section
        title={<FormattedMessage id="analytics.personalization.funnel" />}
        hint={<FormattedMessage id="rhythm.metrics.hint" />}
      >
        <p className="text-sm text-muted-foreground">
          <FormattedMessage id="rhythm.metrics.empty" />
        </p>
      </Section>
    );
  }
  return (
    <div className="grid min-w-0 gap-4">
      <Section
        flush
        title={<FormattedMessage id="analytics.personalization.funnel" />}
        hint={<FormattedMessage id="rhythm.metrics.hint" />}
      >
        <TableScroll>
          <table className="table">
            <thead>
              <tr>
                <th>
                  <FormattedMessage id="rhythm.metrics.day" />
                </th>
                {funnel.map((key) => (
                  <th className="text-right" key={key}>
                    <FormattedMessage id={`rhythm.metrics.${key}`} />
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {metrics?.funnel.map((row) => (
                <tr key={row.day}>
                  <th scope="row" className="font-normal">
                    {row.day}
                  </th>
                  {funnel.map((key) => (
                    <td className="text-right tabular-nums" key={key}>
                      {row.counts[key] ?? 0}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      </Section>
      <Section flush title={<FormattedMessage id="analytics.personalization.content" />}>
        <TableScroll>
          <table className="table">
            <thead>
              <tr>
                <th>
                  <FormattedMessage id="rhythm.metrics.day" />
                </th>
                <th>
                  <FormattedMessage id="rhythm.metrics.content" />
                </th>
                <th className="text-right">
                  <FormattedMessage id="rhythm.metrics.generated" />
                </th>
                {actions.map((key) => (
                  <th className="text-right" key={key}>
                    <FormattedMessage id={`rhythm.metrics.${key}`} />
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {metrics?.content.flatMap((day) =>
                [...new Set([...Object.keys(day.generated), ...Object.keys(day.answers)])].map(
                  (key) => {
                    const answers = day.answers[key];
                    const generated = day.generated[key];
                    return (
                      <tr key={`${day.day}:${key}`}>
                        <td>{day.day}</td>
                        <th scope="row" className="font-normal">
                          {answers?.contentId ?? generated?.contentId} · v
                          {answers?.version ?? generated?.version}
                        </th>
                        <td className="text-right tabular-nums">{generated?.count ?? 0}</td>
                        {actions.map((action) => (
                          <td className="text-right tabular-nums" key={action}>
                            {Number(answers?.[action] ?? 0)}
                          </td>
                        ))}
                      </tr>
                    );
                  },
                ),
              )}
            </tbody>
          </table>
        </TableScroll>
      </Section>
    </div>
  );
}
