import {
  featureLifecycles,
  productPillars,
  type FeatureLifecycle,
  type ProductPillar,
} from '@child-life/contracts';
import { Search } from 'lucide-react';
import { useEffect, useMemo, useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { useLoad } from '../../api';
import { EmptyState, FilterBar, SearchInput, Section } from '../../content-kit';
import { routePaths, useNavigate } from '../../context';
import { Loaded, Pill, SelectMenu, TableScroll } from '../../ui';
import { CoverageMeter, VerificationText, linkClass, useLocalName } from './kit';
import type { FeatureRow, FeaturesView } from './types';

export interface CatalogFilters {
  pillar: ProductPillar | 'all';
  lifecycle: FeatureLifecycle | 'all';
  /** `open` = not yet verified beyond reading the code. */
  verification: 'all' | 'open';
  tier: 'all' | 'free' | 'premium' | 'beta' | 'none';
  band: 'all' | 'low' | 'mid' | 'high';
  stale: boolean;
  conflicts: boolean;
}
export const noFilters: CatalogFilters = {
  pillar: 'all',
  lifecycle: 'all',
  verification: 'all',
  tier: 'all',
  band: 'all',
  stale: false,
  conflicts: false,
};

const pick = <T extends string>(v: string | null, allowed: readonly T[], fallback: T): T =>
  allowed.includes(v as T) ? (v as T) : fallback;

/** Filters live in the address ("?pillar=care&lifecycle=built") so tiles and links can open them. */
export function filtersOf(search: string): CatalogFilters {
  const p = new URLSearchParams(search);
  return {
    pillar: pick(p.get('pillar'), ['all', ...productPillars], 'all'),
    lifecycle: pick(p.get('lifecycle'), ['all', ...featureLifecycles], 'all'),
    verification: pick(p.get('verification'), ['all', 'open'], 'all'),
    tier: pick(p.get('tier'), ['all', 'free', 'premium', 'beta', 'none'], 'all'),
    band: pick(p.get('band'), ['all', 'low', 'mid', 'high'], 'all'),
    stale: p.get('stale') === '1',
    conflicts: p.get('conflicts') === '1',
  };
}
export function searchOf(f: CatalogFilters): string {
  const p = new URLSearchParams();
  for (const [k, v] of Object.entries(f)) {
    if (v === true) p.set(k, '1');
    else if (typeof v === 'string' && v !== 'all') p.set(k, v);
  }
  const s = p.toString();
  return s ? `?${s}` : '';
}

const fold = (s: string) =>
  s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/đ/g, 'd')
    .toLowerCase();

export function filterFeatures(rows: FeatureRow[], f: CatalogFilters, q: string): FeatureRow[] {
  const needle = fold(q.trim());
  return rows.filter(
    (r) =>
      (f.pillar === 'all' || r.pillar === f.pillar) &&
      (f.lifecycle === 'all' || r.lifecycle === f.lifecycle) &&
      (f.verification === 'all' || r.verification === 'unverified' || r.verification === 'code_read') &&
      (f.tier === 'all' || (f.tier === 'none' ? r.tier === null : r.tier === f.tier)) &&
      (f.band === 'all' || r.band === f.band) &&
      (!f.stale || r.stale > 0) &&
      (!f.conflicts || r.conflicts > 0) &&
      (!needle || fold(`${r.id} ${r.name.vi} ${r.name.en}`).includes(needle)),
  );
}

export function CatalogLoader() {
  const [load, reload] = useLoad<FeaturesView>('productHubFeatures', {}, 'features');
  return (
    <Loaded load={load} reload={reload}>
      {(d) => <CatalogView data={d} initial={filtersOf(typeof window === 'undefined' ? '' : window.location.search)} />}
    </Loaded>
  );
}

/** The catalog (doc 04 §2.2): one dense table; a row opens the feature's specification. */
export function CatalogView({ data, initial = noFilters }: { data: FeaturesView; initial?: CatalogFilters }) {
  const intl = useIntl();
  const navigate = useNavigate();
  const name = useLocalName();
  const [f, setF] = useState<CatalogFilters>(initial);
  const [q, setQ] = useState('');
  useEffect(() => {
    if (typeof window === 'undefined') return;
    const path = `${routePaths.product}/features${searchOf(f)}`;
    if (`${window.location.pathname}${window.location.search}` !== path) window.history.replaceState({}, '', path);
  }, [f]);
  const shown = useMemo(() => filterFeatures(data.features, f, q), [data.features, f, q]);
  const active = q !== '' || searchOf(f) !== '';
  const set = <K extends keyof CatalogFilters>(k: K) => (v: CatalogFilters[K]) => setF((x) => ({ ...x, [k]: v }));
  const all = intl.formatMessage({ id: 'ph.filter.all' });

  return (
    <Section title={<FormattedMessage id="ph.catalog.title" />} flush>
      <FilterBar
        active={active}
        onClear={() => {
          setF(noFilters);
          setQ('');
        }}
        shown={shown.length}
        total={data.features.length}
      >
        <SearchInput value={q} onChange={setQ} placeholder={intl.formatMessage({ id: 'ph.catalog.search' })} />
        <SelectMenu
          label={intl.formatMessage({ id: 'ph.col.pillar' })}
          value={f.pillar}
          onChange={set('pillar')}
          options={[
            { value: 'all', label: `${intl.formatMessage({ id: 'ph.col.pillar' })}: ${all}` },
            ...productPillars.map((p) => ({ value: p, label: intl.formatMessage({ id: `ph.pillar.${p}` }) })),
          ]}
        />
        <SelectMenu
          label={intl.formatMessage({ id: 'ph.col.lifecycle' })}
          value={f.lifecycle}
          onChange={set('lifecycle')}
          options={[
            { value: 'all', label: `${intl.formatMessage({ id: 'ph.col.lifecycle' })}: ${all}` },
            ...featureLifecycles.map((l) => ({ value: l, label: intl.formatMessage({ id: `ph.lifecycle.${l}` }) })),
          ]}
        />
        <SelectMenu
          label={intl.formatMessage({ id: 'ph.col.tier' })}
          value={f.tier}
          onChange={set('tier')}
          options={(['all', 'free', 'premium', 'beta', 'none'] as const).map((t) => ({
            value: t,
            label: t === 'all' ? `${intl.formatMessage({ id: 'ph.col.tier' })}: ${all}` : intl.formatMessage({ id: `ph.tier.${t}` }),
          }))}
        />
        <SelectMenu
          label={intl.formatMessage({ id: 'ph.col.coverage' })}
          value={f.band}
          onChange={set('band')}
          options={(['all', 'low', 'mid', 'high'] as const).map((b) => ({
            value: b,
            label: b === 'all' ? `${intl.formatMessage({ id: 'ph.col.coverage' })}: ${all}` : intl.formatMessage({ id: `ph.band.${b}` }),
          }))}
        />
        <SelectMenu
          label={intl.formatMessage({ id: 'ph.col.verification' })}
          value={f.verification}
          onChange={set('verification')}
          options={[
            { value: 'all', label: `${intl.formatMessage({ id: 'ph.col.verification' })}: ${all}` },
            { value: 'open', label: intl.formatMessage({ id: 'ph.filter.needVerification' }) },
          ]}
        />
        {f.stale && (
          <Pill tone="wait">
            <FormattedMessage id="ph.filter.stale" />
          </Pill>
        )}
        {f.conflicts && (
          <Pill tone="warn">
            <FormattedMessage id="ph.filter.conflicts" />
          </Pill>
        )}
      </FilterBar>
      {shown.length === 0 ? (
        <EmptyState icon={Search} title={<FormattedMessage id="ph.catalog.noMatch" />} />
      ) : (
        <TableScroll min={860}>
          <table className="table">
            <thead>
              <tr>
                <th>
                  <FormattedMessage id="ph.col.feature" />
                </th>
                <th>
                  <FormattedMessage id="ph.col.pillar" />
                </th>
                <th>
                  <FormattedMessage id="ph.col.lifecycle" />
                </th>
                <th>
                  <FormattedMessage id="ph.col.tier" />
                </th>
                <th>
                  <FormattedMessage id="ph.col.coverage" />
                </th>
                <th>
                  <FormattedMessage id="ph.col.verification" />
                </th>
              </tr>
            </thead>
            <tbody>
              {shown.map((r) => (
                <tr key={r.id}>
                  <td>
                    <button
                      type="button"
                      className={`${linkClass} text-left font-medium text-foreground`}
                      onClick={() => navigate('product', `features/${r.id}`)}
                    >
                      {name(r.name, r.id)}
                    </button>
                    <div className="flex flex-wrap items-center gap-1.5 text-xs text-muted-foreground">
                      <span className="font-mono">{r.id}</span>
                      {r.implementation !== 'implemented' && (
                        <Pill tone="warn">
                          <FormattedMessage id={`ph.implementation.${r.implementation}`} />
                        </Pill>
                      )}
                      {r.conflicts > 0 && (
                        <Pill tone="warn">
                          <FormattedMessage id="ph.catalog.conflicts" values={{ n: r.conflicts }} />
                        </Pill>
                      )}
                      {r.stale > 0 && (
                        <Pill tone="wait">
                          <FormattedMessage id="ph.catalog.stale" values={{ n: r.stale }} />
                        </Pill>
                      )}
                    </div>
                  </td>
                  <td>
                    <FormattedMessage id={`ph.pillar.${r.pillar}`} />
                  </td>
                  <td>
                    <FormattedMessage id={`ph.lifecycle.${r.lifecycle}`} />
                  </td>
                  <td>
                    <FormattedMessage id={`ph.tier.${r.tier ?? 'none'}`} />
                  </td>
                  <td>
                    <CoverageMeter score={r.coverage} />
                  </td>
                  <td>
                    <VerificationText value={r.verification} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      )}
    </Section>
  );
}
