import {
  inboxGroups,
  notificationCatalogGaps,
  notificationDestinationIds,
  notificationDestinations,
  notificationKinds,
  notificationTemplates,
  notificationTypes,
  type NotificationDestinationId,
  type NotificationTypeDef,
} from '@child-life/contracts';
import { ChevronRight } from 'lucide-react';
import { useMemo, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { EmptyState, SearchInput, Section } from '../../content-kit';
import { Pill } from '../../ui';
import { StatusDot, TabHeader } from './kit';
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

export function destinationSearchText(intl: IntlShape, id: NotificationDestinationId): string {
  const d = notificationDestinations[id];
  return [
    id,
    pick(intl, d.screen),
    d.path,
    intl.formatMessage({ id: `ntf.permission.${d.permission}` }),
  ]
    .join(' ')
    .toLowerCase();
}

/** A compact row that opens to its details (keyboard: Enter / Space on the summary). */
function Row({
  summary,
  children,
  data,
}: {
  summary: ReactNode;
  children: ReactNode;
  data?: Record<string, string>;
}) {
  return (
    <details className="group border-b last:border-b-0" {...data}>
      <summary className="flex cursor-pointer list-none items-center gap-3 px-5 py-3 outline-none hover:bg-muted/50 focus-visible:ring-[3px] focus-visible:ring-ring/50 [&::-webkit-details-marker]:hidden">
        <ChevronRight
          className="size-4 shrink-0 text-muted-foreground transition-transform group-open:rotate-90"
          aria-hidden="true"
        />
        {summary}
      </summary>
      <div className="bg-muted/30 px-5 py-4 sm:pl-12">{children}</div>
    </details>
  );
}

/**
 * Danh mục: every notification kind (live and reserved) as a compact row grouped like the app's
 * chips — open a row for its trigger, recipients, switch, quiet hours, dedup, templates and
 * destination; then events not pushed, and the destination registry. One search filters all.
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
  const destinations = notificationDestinationIds.filter(
    (id) => !query || destinationSearchText(intl, id).includes(query),
  );
  const gaps = notificationCatalogGaps.filter(
    (g) =>
      !query ||
      [g.id, intl.formatMessage({ id: `ntf.gap.${g.id}` }), pick(intl, g.note)]
        .join(' ')
        .toLowerCase()
        .includes(query),
  );
  const live = notificationKinds.filter((k) => notificationTypes[k].status === 'live').length;
  return (
    <div className="stack">
      <TabHeader
        title={<FormattedMessage id="ntf.tab.catalog" />}
        purpose={
          <FormattedMessage
            id="ntf.purpose.catalog"
            values={{
              n: live,
              total: notificationKinds.length,
              a: notificationDestinationIds.length,
            }}
          />
        }
        actions={
          <SearchInput
            value={q}
            onChange={setQ}
            placeholder={intl.formatMessage({ id: 'ntf.catalog.search' })}
          />
        }
      />
      {query && (
        <p className="text-[13px] text-muted-foreground" role="status">
          <FormattedMessage
            id="ntf.catalog.found"
            values={{ n: kinds.length, a: destinations.length, c: gaps.length }}
          />
        </p>
      )}
      {kinds.length === 0 && gaps.length === 0 && destinations.length === 0 && (
        <EmptyState title={<FormattedMessage id="ntf.catalog.noMatch" />} />
      )}
      {inboxGroups.map((group) => {
        const list = kinds.filter((k) => k.group === group);
        if (!list.length) return null;
        return (
          <Section
            key={group}
            flush
            title={
              <span className="inline-flex items-center gap-2">
                <FormattedMessage id={`ntf.group.${group}`} />
                <span className="rounded-full bg-muted px-2 text-[12px] font-medium text-muted-foreground tabular-nums">
                  {list.length}
                </span>
              </span>
            }
          >
            {list.map((def) => (
              <KindRow key={def.kind} def={def} />
            ))}
          </Section>
        );
      })}
      {gaps.length > 0 && (
        <Section
          flush
          title={<FormattedMessage id="ntf.catalog.gaps" />}
          description={<FormattedMessage id="ntf.catalog.gapsNote" />}
        >
          <ul>
            {gaps.map((g) => (
              <li
                key={g.id}
                data-gap={g.id}
                className="flex flex-wrap items-baseline gap-x-3 gap-y-1 border-b px-5 py-3 last:border-b-0"
              >
                <span className="font-medium">
                  <FormattedMessage id={`ntf.gap.${g.id}`} />
                </span>
                <StatusDot tone={g.channel === 'email' ? 'wait' : 'muted'}>
                  <span className="text-[13px]">
                    <FormattedMessage id={`ntf.gapChannel.${g.channel}`} />
                  </span>
                </StatusDot>
                <span className="w-full text-[13px] text-muted-foreground">
                  {pick(intl, g.note)}
                </span>
              </li>
            ))}
          </ul>
        </Section>
      )}
      {destinations.length > 0 && <DestinationsList ids={destinations} />}
    </div>
  );
}

function KindRow({ def }: { def: NotificationTypeDef }) {
  const intl = useIntl();
  const line = (label: string, value: ReactNode) => (
    <>
      <dt className="text-muted-foreground">
        <FormattedMessage id={label} />
      </dt>
      <dd className="min-w-0">{value}</dd>
    </>
  );
  return (
    <Row
      data={{ 'data-kind': def.kind }}
      summary={
        <span className="grid min-w-0 flex-1 gap-0.5 sm:grid-cols-[minmax(0,1.3fr)_minmax(0,1fr)_auto] sm:items-center sm:gap-4">
          <span className="min-w-0">
            <span className="font-medium">
              <FormattedMessage id={`ntf.kind.${def.kind}`} />
            </span>
            {def.engagement.map((e) => (
              <span key={e} className="ml-2 text-[12px] font-medium text-muted-foreground">
                {e}
              </span>
            ))}
            <span className="block truncate text-[13px] text-muted-foreground">
              {pick(intl, def.trigger)}
            </span>
          </span>
          <span className="truncate text-[13px] text-muted-foreground">
            → {pick(intl, notificationDestinations[def.destination].screen)}
          </span>
          <span className="flex items-center gap-2 text-[13px]">
            {def.priority === 'time_sensitive' && (
              <Pill tone="warn">
                <FormattedMessage id="ntf.priority.time_sensitive" />
              </Pill>
            )}
            <StatusDot tone={def.status === 'live' ? 'ok' : 'muted'}>
              <FormattedMessage id={`ntf.catalogStatus.${def.status}`} />
            </StatusDot>
          </span>
        </span>
      }
    >
      <div className="grid gap-4 lg:grid-cols-2">
        <dl className="grid gap-x-4 gap-y-1.5 text-sm sm:grid-cols-[minmax(0,9rem)_minmax(0,1fr)]">
          {line('ntf.col.kind', <code className="text-[12px]">{def.kind}</code>)}
          {line('ntf.col.recipients', pick(intl, def.recipients))}
          {line('ntf.col.producer', <FormattedMessage id={`ntf.producer.${def.producer}`} />)}
          {line('ntf.col.priority', <FormattedMessage id={`ntf.priority.${def.priority}`} />)}
          {line(
            'ntf.col.setting',
            def.setting ? (
              <FormattedMessage id={`ntf.setting.${def.setting}`} />
            ) : (
              <FormattedMessage id="ntf.setting.always" />
            ),
          )}
          {line('ntf.col.quiet', <FormattedMessage id={`ntf.quiet.${def.quietHours}`} />)}
          {line('ntf.col.dedup', pick(intl, def.dedup))}
          {line('ntf.col.actionKind', <FormattedMessage id={`ntf.actionKind.${def.action}`} />)}
          {line(
            'ntf.col.templates',
            def.templates.length ? (
              <span className="grid gap-0.5">
                {def.templates.map((t) => (
                  <span key={t}>
                    {pick(intl, notificationTemplates[t].name)}{' '}
                    <code className="text-[11px] text-muted-foreground">{t}</code>
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
        <div>
          <p className="mb-2 text-[13px] font-semibold">
            <FormattedMessage id="ntf.col.destination" />
          </p>
          <DestinationDetails id={def.destination} />
        </div>
      </div>
    </Row>
  );
}

/** "Người dùng đi đâu sau khi chạm": the destination registry, one compact row each. */
export function DestinationsList({
  ids = notificationDestinationIds,
}: {
  ids?: readonly NotificationDestinationId[];
}) {
  const intl = useIntl();
  return (
    <Section
      flush
      title={
        <span className="inline-flex items-center gap-2">
          <FormattedMessage id="ntf.dest.title" />
          <span className="rounded-full bg-muted px-2 text-[12px] font-medium text-muted-foreground tabular-nums">
            {ids.length}
          </span>
        </span>
      }
      description={<FormattedMessage id="ntf.dest.note" />}
    >
      {ids.map((id) => {
        const d = notificationDestinations[id];
        return (
          <Row
            key={id}
            data={{ 'data-destination': id }}
            summary={
              <span className="grid min-w-0 flex-1 gap-0.5 sm:grid-cols-[minmax(0,1fr)_minmax(0,1.4fr)] sm:items-center sm:gap-4">
                <span className="min-w-0">
                  <span className="font-medium">{pick(intl, d.screen)}</span>
                  <span className="block truncate font-mono text-[11px] text-muted-foreground">
                    {d.path}
                  </span>
                </span>
                <span className="text-[13px] text-muted-foreground">
                  <FallbackChain id={id} />
                </span>
              </span>
            }
          >
            <dl className="grid gap-x-4 gap-y-1.5 text-sm sm:grid-cols-[minmax(0,9rem)_minmax(0,1fr)]">
              <dt className="text-muted-foreground">
                <FormattedMessage id="ntf.dest.id" />
              </dt>
              <dd>
                <code className="text-[12px]">{id}</code>
              </dd>
              <dt className="text-muted-foreground">
                <FormattedMessage id="ntf.dest.params" />
              </dt>
              <dd>
                <ParamList id={id} />
              </dd>
              <dt className="text-muted-foreground">
                <FormattedMessage id="ntf.dest.permission" />
              </dt>
              <dd>
                <FormattedMessage id={`ntf.permission.${d.permission}`} />
              </dd>
              <dt className="text-muted-foreground">
                <FormattedMessage id="ntf.dest.completion" />
              </dt>
              <dd>
                {d.completion ? (
                  pick(intl, d.completion)
                ) : (
                  <span className="text-muted-foreground">
                    <FormattedMessage id="ntf.dest.openIsPoint" />
                  </span>
                )}
              </dd>
            </dl>
          </Row>
        );
      })}
    </Section>
  );
}
