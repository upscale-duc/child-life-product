import { productPillars } from '@child-life/contracts';
import { Boxes } from 'lucide-react';
import type { ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { EmptyState, Section, StatTiles } from '../../content-kit';
import { useNavigate } from '../../context';
import { shortDate } from '../../format';
import { useLoad } from '../../api';
import { Button, Loaded, TableScroll } from '../../ui';
import { Meta, linkClass, shortRev } from './kit';
import type { OverviewView } from './types';

const lifecycleCols = ['built', 'in_development', 'designed', 'planned'] as const;

export function OverviewLoader() {
  const [load, reload] = useLoad<OverviewView>('productHubOverview', {}, 'overview');
  return <Loaded load={load} reload={reload}>{(d) => <OverviewView data={d} />}</Loaded>;
}

/**
 * Where the product stands, from approved registry records only (doc 04 §2.1). Every count opens
 * the catalog filtered; usage numbers are not shown before the app has real users.
 */
export function OverviewView({ data }: { data: OverviewView }) {
  const intl = useIntl();
  const navigate = useNavigate();
  const go = (query: string) => navigate('product', `features${query ? `?${query}` : ''}`);
  if (data.total === 0) {
    return (
      <Section title={<FormattedMessage id="ph.overview.emptyTitle" />}>
        <EmptyState
          icon={Boxes}
          title={<FormattedMessage id="ph.overview.emptyTitle" />}
          action={
            <Button onClick={() => navigate('product', 'sources')}>
              <FormattedMessage id="ph.overview.openSources" />
            </Button>
          }
        >
          <FormattedMessage id="ph.overview.emptyBody" values={{ n: data.pending }} />
        </EmptyState>
      </Section>
    );
  }
  const n = (r: Record<string, number>, k: string) => r[k] ?? 0;
  return (
    <div className="grid gap-4 [&>*]:min-w-0">
      {data.lastSync && (
        <Meta>
          <FormattedMessage
            id="ph.overview.revision"
            values={{
              rev: shortRev(data.lastSync.revision),
              date: data.lastSync.at ? shortDate(intl, data.lastSync.at) : '—',
              by: data.lastSync.by,
            }}
          />
        </Meta>
      )}
      <StatTiles
        items={[
          { key: 'total', label: <FormattedMessage id="ph.stat.total" />, value: data.total, onClick: () => go('') },
          {
            key: 'built',
            label: <FormattedMessage id="ph.stat.built" />,
            value: n(data.byLifecycle, 'built'),
            onClick: () => go('lifecycle=built'),
          },
          {
            key: 'dev',
            label: <FormattedMessage id="ph.stat.inDevelopment" />,
            value: n(data.byLifecycle, 'in_development'),
            onClick: () => go('lifecycle=in_development'),
          },
          {
            key: 'verify',
            label: <FormattedMessage id="ph.stat.needVerification" />,
            value: data.needVerification,
            tone: 'warn',
            foot: <FormattedMessage id="ph.stat.released" values={{ n: data.released }} />,
            onClick: () => go('verification=open'),
          },
        ]}
      />

      <Section title={<FormattedMessage id="ph.overview.byPillar" />} flush>
        <TableScroll min={520}>
          <table className="table">
            <thead>
              <tr>
                <th>
                  <FormattedMessage id="ph.col.pillar" />
                </th>
                {lifecycleCols.map((l) => (
                  <th key={l} className="text-right">
                    <FormattedMessage id={`ph.lifecycle.${l}`} />
                  </th>
                ))}
                <th className="text-right">
                  <FormattedMessage id="ph.col.total" />
                </th>
              </tr>
            </thead>
            <tbody>
              {productPillars.map((p) => (
                <tr key={p}>
                  <td className="font-medium">
                    <FormattedMessage id={`ph.pillar.${p}`} />
                  </td>
                  {lifecycleCols.map((l) => {
                    const v = n(data.byPillarLifecycle, `${p}:${l}`);
                    return (
                      <td key={l} className="text-right tabular-nums">
                        {v ? (
                          <button type="button" className={linkClass} onClick={() => go(`pillar=${p}&lifecycle=${l}`)}>
                            {v}
                          </button>
                        ) : (
                          <span className="text-muted-foreground">0</span>
                        )}
                      </td>
                    );
                  })}
                  <td className="text-right tabular-nums">
                    <button type="button" className={linkClass} onClick={() => go(`pillar=${p}`)}>
                      {n(data.byPillar, p)}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      </Section>

      <div className="grid gap-4 lg:grid-cols-2">
        <Section title={<FormattedMessage id="ph.overview.health" />}>
          <dl className="grid grid-cols-[1fr_auto] gap-x-4 gap-y-2 text-sm">
            {(['low', 'mid', 'high'] as const).map((b) => (
              <Row key={b} label={<FormattedMessage id={`ph.band.${b}`} />} value={n(data.byBand, b)} onClick={() => go(`band=${b}`)} />
            ))}
            <Row label={<FormattedMessage id="ph.overview.stale" />} value={data.staleFeatures} onClick={() => go('stale=1')} />
            <Row label={<FormattedMessage id="ph.overview.conflicts" />} value={data.openConflicts} onClick={() => go('conflicts=1')} />
            <Row
              label={<FormattedMessage id="ph.overview.pending" />}
              value={data.pending}
              onClick={() => navigate('product', 'sources')}
            />
          </dl>
        </Section>
        <Section title={<FormattedMessage id="ph.overview.plans" />}>
          <dl className="grid grid-cols-[1fr_auto] gap-x-4 gap-y-2 text-sm">
            {(['free', 'premium', 'beta'] as const).map((t) => (
              <Row key={t} label={<FormattedMessage id={`ph.tier.${t}`} />} value={n(data.byTier, t)} onClick={() => go(`tier=${t}`)} />
            ))}
            <Row label={<FormattedMessage id="ph.tier.none" />} value={n(data.byTier, 'none')} onClick={() => go('tier=none')} />
          </dl>
          <Meta>
            <FormattedMessage id="ph.overview.analyticsUnavailable" />
          </Meta>
        </Section>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Section title={<FormattedMessage id="ph.overview.recentDecisions" />}>
          {data.recentDecisions.length === 0 ? (
            <Meta>
              <FormattedMessage id="ph.none" />
            </Meta>
          ) : (
            <ul className="grid gap-2 text-sm">
              {data.recentDecisions.map((d) => (
                <li key={d.id} className="flex gap-2">
                  <span className="font-mono text-[12.5px] font-semibold">{d.id}</span>
                  <span className="min-w-0 flex-1">{d.title}</span>
                  {d.date && <span className="text-muted-foreground tabular-nums">{shortDate(intl, d.date)}</span>}
                </li>
              ))}
            </ul>
          )}
        </Section>
        <Section title={<FormattedMessage id="ph.overview.recentChanges" />}>
          <ul className="grid gap-2 text-sm">
            {data.recentChanges.map((c) => (
              <li key={c.id} className="flex flex-wrap gap-x-2">
                <button type="button" className={`${linkClass} font-mono text-[12.5px]`} onClick={() => navigate('product', `sources/review/${c.id}`)}>
                  {shortRev(c.revision)}
                </button>
                <FormattedMessage id={`ph.changeSet.status.${c.status}`} />
                <span className="text-muted-foreground">
                  <FormattedMessage id="ph.changeSet.counts" values={{ ...c.summary }} />
                </span>
              </li>
            ))}
          </ul>
        </Section>
      </div>
    </div>
  );
}

function Row({ label, value, onClick }: { label: ReactNode; value: number; onClick: () => void }) {
  return (
    <>
      <dt>{label}</dt>
      <dd className="text-right tabular-nums">
        <button type="button" className={linkClass} onClick={onClick} disabled={value === 0}>
          {value}
        </button>
      </dd>
    </>
  );
}
