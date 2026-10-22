import {
  inboxGroups,
  notificationCatalogGaps,
  notificationDestinationIds,
  notificationDestinations,
  notificationKinds,
  notificationTemplates,
  notificationTypes,
  type NotificationTypeDef,
} from '@child-life/contracts';
import { useMemo, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { EmptyState, SearchInput, Section } from '../../content-kit';
import { Pill, TableScroll } from '../../ui';
import { DestinationDetails, FallbackChain, ParamList, pick } from './shared';

/** The words a kind is found by: its code, label, trigger, recipients, templates, destination. */
export function kindSearchText(intl: IntlShape, def: NotificationTypeDef): string {
  return [
    def.kind,
    intl.formatMessage({ id: `ntf.kind.${def.kind}` }),
    pick(intl, def.trigger),
    pick(intl, def.recipients),
    def.destination,
    pick(intl, notificationDestinations[def.destination].screen),
    ...def.engagement,
    ...def.templates.flatMap((t) => [t, pick(intl, notificationTemplates[t].name)]),
  ]
    .join(' ')
    .toLowerCase();
}

/**
 * Danh mục: every notification kind (live and reserved), grouped like the app's chips, with what
 * triggers it, who receives it, its switch, quiet hours, dedup, templates and destination; then
 * the events V1 does not push (G-109) and the destination registry.
 */
export function CatalogView() {
  const intl = useIntl();
  const [q, setQ] = useState('');
  const query = q.trim().toLowerCase();
  const kinds = useMemo(
    () =>
      notificationKinds
        .map((k) => notificationTypes[k])
        .filter((def) => !query || kindSearchText(intl, def).includes(query)),
    [intl, query],
  );
  const gaps = notificationCatalogGaps.filter(
    (g) =>
      !query ||
      [g.id, intl.formatMessage({ id: `ntf.gap.${g.id}` }), pick(intl, g.note)]
        .join(' ')
        .toLowerCase()
        .includes(query),
  );
  return (
    <div className="stack">
      <div className="flex flex-wrap items-center gap-2">
        <SearchInput
          value={q}
          onChange={setQ}
          placeholder={intl.formatMessage({ id: 'ntf.catalog.search' })}
        />
        <span className="text-[13px] text-muted-foreground" role="status">
          <FormattedMessage
            id="ntf.catalog.count"
            values={{ n: kinds.length, total: notificationKinds.length }}
          />
        </span>
      </div>
      {kinds.length === 0 && gaps.length === 0 && (
        <EmptyState title={<FormattedMessage id="ntf.catalog.noMatch" />} />
      )}
      {inboxGroups.map((group) => {
        const list = kinds.filter((k) => k.group === group);
        if (!list.length) return null;
        return (
          <Section
            key={group}
            title={<FormattedMessage id={`ntf.group.${group}`} />}
            description={<FormattedMessage id="ntf.catalog.kinds" values={{ n: list.length }} />}
          >
            <div className="grid gap-3">
              {list.map((def) => (
                <KindCard key={def.kind} def={def} />
              ))}
            </div>
          </Section>
        );
      })}
      {gaps.length > 0 && (
        <Section
          title={<FormattedMessage id="ntf.catalog.gaps" />}
          description={<FormattedMessage id="ntf.catalog.gapsNote" />}
          flush
        >
          <TableScroll min={560}>
            <table className="table">
              <thead>
                <tr>
                  <th>
                    <FormattedMessage id="ntf.col.event" />
                  </th>
                  <th>
                    <FormattedMessage id="ntf.col.group" />
                  </th>
                  <th>
                    <FormattedMessage id="ntf.col.channel" />
                  </th>
                  <th>
                    <FormattedMessage id="ntf.col.note" />
                  </th>
                </tr>
              </thead>
              <tbody>
                {gaps.map((g) => (
                  <tr key={g.id} data-gap={g.id}>
                    <td>
                      <span className="font-medium">
                        <FormattedMessage id={`ntf.gap.${g.id}`} />
                      </span>
                      <span className="block font-mono text-[12px] text-muted-foreground">
                        {g.id}
                      </span>
                    </td>
                    <td>
                      <FormattedMessage id={`ntf.group.${g.group}`} />
                    </td>
                    <td>
                      <Pill tone={g.channel === 'email' ? 'info' : 'muted'}>
                        <FormattedMessage id={`ntf.gapChannel.${g.channel}`} />
                      </Pill>
                    </td>
                    <td>{pick(intl, g.note)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </TableScroll>
        </Section>
      )}
      <DestinationsTable />
    </div>
  );
}

function KindCard({ def }: { def: NotificationTypeDef }) {
  const intl = useIntl();
  const row = (label: string, value: ReactNode) => (
    <>
      <dt className="text-muted-foreground">
        <FormattedMessage id={label} />
      </dt>
      <dd className="min-w-0">{value}</dd>
    </>
  );
  return (
    <article className="rounded-lg border p-4" data-kind={def.kind}>
      <header className="mb-3 flex flex-wrap items-center gap-2">
        <h3 className="text-[15px] font-semibold">
          <FormattedMessage id={`ntf.kind.${def.kind}`} />
        </h3>
        <code className="rounded bg-muted px-1.5 py-0.5 text-[12px]">{def.kind}</code>
        <Pill tone={def.status === 'live' ? 'ok' : 'muted'}>
          <FormattedMessage id={`ntf.catalogStatus.${def.status}`} />
        </Pill>
        <Pill tone={def.priority === 'time_sensitive' ? 'warn' : 'info'}>
          <FormattedMessage id={`ntf.priority.${def.priority}`} />
        </Pill>
        {def.engagement.map((e) => (
          <Pill key={e} tone="purple">
            {e} · <FormattedMessage id={`ntf.eng.${e}`} />
          </Pill>
        ))}
      </header>
      <dl className="grid gap-x-4 gap-y-1.5 text-sm sm:grid-cols-[minmax(0,10rem)_minmax(0,1fr)]">
        {row('ntf.col.trigger', pick(intl, def.trigger))}
        {row('ntf.col.recipients', pick(intl, def.recipients))}
        {row('ntf.col.producer', <FormattedMessage id={`ntf.producer.${def.producer}`} />)}
        {row(
          'ntf.col.setting',
          def.setting ? (
            <FormattedMessage id={`ntf.setting.${def.setting}`} />
          ) : (
            <FormattedMessage id="ntf.setting.always" />
          ),
        )}
        {row('ntf.col.quiet', <FormattedMessage id={`ntf.quiet.${def.quietHours}`} />)}
        {row('ntf.col.dedup', pick(intl, def.dedup))}
        {row('ntf.col.actionKind', <FormattedMessage id={`ntf.actionKind.${def.action}`} />)}
        {row(
          'ntf.col.templates',
          def.templates.length ? (
            <span className="flex flex-wrap gap-1">
              {def.templates.map((t) => (
                <span key={t} className="rounded-md border px-1.5 py-0.5 text-[13px]">
                  {pick(intl, notificationTemplates[t].name)}{' '}
                  <span className="font-mono text-[11px] text-muted-foreground">{t}</span>
                </span>
              ))}
            </span>
          ) : (
            <span className="text-muted-foreground">
              <FormattedMessage id="ntf.catalog.noTemplate" />
            </span>
          ),
        )}
      </dl>
      <div className="mt-3 rounded-md bg-muted/40 p-3">
        <p className="mb-2 text-[13px] font-medium">
          <FormattedMessage id="ntf.col.destination" />
        </p>
        <DestinationDetails id={def.destination} />
      </div>
    </article>
  );
}

/** "Người dùng đi đâu sau khi chạm": the destination registry. */
export function DestinationsTable() {
  const intl = useIntl();
  return (
    <Section
      title={<FormattedMessage id="ntf.dest.title" />}
      description={<FormattedMessage id="ntf.dest.note" />}
      flush
    >
      <TableScroll min={900}>
        <table className="table">
          <thead>
            <tr>
              <th>
                <FormattedMessage id="ntf.dest.screen" />
              </th>
              <th>
                <FormattedMessage id="ntf.dest.path" />
              </th>
              <th>
                <FormattedMessage id="ntf.dest.params" />
              </th>
              <th>
                <FormattedMessage id="ntf.dest.permission" />
              </th>
              <th>
                <FormattedMessage id="ntf.dest.fallback" />
              </th>
              <th>
                <FormattedMessage id="ntf.dest.completion" />
              </th>
            </tr>
          </thead>
          <tbody>
            {notificationDestinationIds.map((id) => {
              const d = notificationDestinations[id];
              return (
                <tr key={id} data-destination={id}>
                  <td>
                    <span className="font-medium">{pick(intl, d.screen)}</span>
                    <span className="block font-mono text-[11px] text-muted-foreground">{id}</span>
                  </td>
                  <td className="font-mono text-[12px]">{d.path}</td>
                  <td>
                    <ParamList id={id} />
                  </td>
                  <td>
                    <FormattedMessage id={`ntf.permission.${d.permission}`} />
                  </td>
                  <td>
                    <FallbackChain id={id} />
                  </td>
                  <td>
                    {d.completion ? (
                      pick(intl, d.completion)
                    ) : (
                      <span className="text-muted-foreground">
                        <FormattedMessage id="ntf.dest.openIsPoint" />
                      </span>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </TableScroll>
    </Section>
  );
}
