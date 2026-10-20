import { FormattedMessage } from 'react-intl';
import type { RhythmView } from '../api';
import { TableScroll } from '../ui';

/** P-172 D2: anonymous counts, no unsupported conversion rates or delivery claims. */
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
  return (
    <div className="grid gap-4">
      <p className="text-sm text-muted-foreground">
        <FormattedMessage id="rhythm.metrics.hint" />
      </p>
      <TableScroll>
        <table className="w-full text-sm">
          <thead>
            <tr>
              <th className="p-2 text-left">
                <FormattedMessage id="rhythm.metrics.day" />
              </th>
              {funnel.map((key) => (
                <th className="p-2 text-right" key={key}>
                  <FormattedMessage id={`rhythm.metrics.${key}`} />
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {metrics?.funnel.map((row) => (
              <tr key={row.day} className="border-t">
                <th className="p-2 text-left">{row.day}</th>
                {funnel.map((key) => (
                  <td className="p-2 text-right tabular-nums" key={key}>
                    {row.counts[key] ?? 0}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </TableScroll>
      <TableScroll>
        <table className="w-full text-sm">
          <thead>
            <tr>
              <th className="p-2 text-left">
                <FormattedMessage id="rhythm.metrics.day" />
              </th>
              <th className="p-2 text-left">
                <FormattedMessage id="rhythm.metrics.content" />
              </th>
              <th className="p-2 text-right">
                <FormattedMessage id="rhythm.metrics.generated" />
              </th>
              {actions.map((key) => (
                <th className="p-2 text-right" key={key}>
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
                    <tr key={`${day.day}:${key}`} className="border-t">
                      <td className="p-2">{day.day}</td>
                      <th className="p-2 text-left">
                        {answers?.contentId ?? generated?.contentId} · v
                        {answers?.version ?? generated?.version}
                      </th>
                      <td className="p-2 text-right tabular-nums">{generated?.count ?? 0}</td>
                      {actions.map((action) => (
                        <td className="p-2 text-right tabular-nums" key={action}>
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
      {!metrics?.content.length && !metrics?.funnel.length && (
        <p className="text-sm text-muted-foreground">
          <FormattedMessage id="rhythm.metrics.empty" />
        </p>
      )}
    </div>
  );
}
