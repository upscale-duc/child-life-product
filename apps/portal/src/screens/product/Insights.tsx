import { metricInstrumentations, type MetricInstrumentation } from '@child-life/contracts';
import { useMemo, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { useLoad } from '../../api';
import { FilterBar, Notice, SearchInput, Section, StatTiles } from '../../content-kit';
import { useNavigate } from '../../context';
import { shortDate } from '../../format';
import { Loaded, Pill, Segmented, SelectMenu, TableScroll, type PillTone } from '../../ui';
import { Meta, PathText, linkClass } from './kit';
import type { HealthView, MetricsView } from './types';

/**
 * Sản phẩm › Hiệu quả (D-155, Phase 4 before launch). No usage numbers exist before release, so
 * this tab says what the analytics code can measure today (from the reducer itself, at sync time)
 * and how fresh the product knowledge is. Usage data joins here after launch.
 */
type Part = 'measurement' | 'freshness';

export function InsightsScreen({ part }: { part: Part }) {
  const intl = useIntl();
  const navigate = useNavigate();
  return (
    <div className="grid gap-4 [&>*]:min-w-0">
      <Notice tone="info">
        <FormattedMessage id="ph.insights.noUsage" />
      </Notice>
      <Segmented<Part>
        label={intl.formatMessage({ id: 'ph.insights.parts' })}
        value={part}
        onChange={(p) => navigate('product', p === 'measurement' ? 'insights' : `insights/${p}`)}
        options={[
          { value: 'measurement', label: intl.formatMessage({ id: 'ph.insights.measurement' }) },
          { value: 'freshness', label: intl.formatMessage({ id: 'ph.insights.freshness' }) },
        ]}
      />
      {part === 'measurement' ? <MetricsLoader /> : <HealthLoader />}
    </div>
  );
}

export const instrumentationTone: Record<string, PillTone> = {
  computed: 'ok',
  partial: 'wait',
  not_instrumented: 'warn',
  no_source: 'warn',
  defined_only: 'muted',
};

export function InstrumentationPill({ value }: { value: string }) {
  return (
    <Pill tone={instrumentationTone[value] ?? 'muted'}>
      <FormattedMessage id={`ph.instr.${value}`} />
    </Pill>
  );
}

function MetricsLoader() {
  const [load, reload] = useLoad<MetricsView>('productHubMetrics', {}, 'metrics');
  return <Loaded load={load} reload={reload}>{(d) => <MetricsView data={d} />}</Loaded>;
}

export function MetricsView({ data }: { data: MetricsView }) {
  const intl = useIntl();
  const navigate = useNavigate();
  const [instr, setInstr] = useState<MetricInstrumentation | 'all' | 'gaps'>('all');
  const [q, setQ] = useState('');
  const [open, setOpen] = useState<string | null>(null);
  const shown = useMemo(() => {
    const needle = q.trim().toLowerCase();
    return data.metrics.filter(
      (m) =>
        (instr === 'all' || (instr === 'gaps' ? m.instrumentation !== 'computed' : m.instrumentation === instr)) &&
        (!needle || `${m.id} ${m.name} ${m.features.join(' ')}`.toLowerCase().includes(needle)),
    );
  }, [data.metrics, instr, q]);
  const n = (k: string) => data.counts[k] ?? 0;
  if (data.metrics.length === 0) {
    return (
      <Section title={<FormattedMessage id="ph.insights.measurement" />}>
        <Meta>
          <FormattedMessage id="ph.insights.noMetrics" />
        </Meta>
      </Section>
    );
  }
  return (
    <div className="grid gap-4 [&>*]:min-w-0">
      <StatTiles
        items={[
          { key: 'computed', label: <FormattedMessage id="ph.instr.computed" />, value: n('computed'), tone: 'ok', onClick: () => setInstr('computed'), active: instr === 'computed' },
          { key: 'gaps', label: <FormattedMessage id="ph.insights.gaps" />, value: n('partial') + n('not_instrumented') + n('no_source'), tone: 'warn', foot: <FormattedMessage id="ph.insights.gapsFoot" values={{ p: n('partial'), m: n('not_instrumented'), s: n('no_source') }} />, onClick: () => setInstr('gaps'), active: instr === 'gaps' },
          { key: 'defined', label: <FormattedMessage id="ph.instr.defined_only" />, value: n('defined_only'), onClick: () => setInstr('defined_only'), active: instr === 'defined_only' },
          { key: 'total', label: <FormattedMessage id="ph.insights.total" />, value: data.metrics.length, onClick: () => setInstr('all'), active: instr === 'all' },
        ]}
      />
      <Section title={<FormattedMessage id="ph.insights.measurement" />} hint={<FormattedMessage id="ph.insights.measurementHint" />} flush>
        <FilterBar active={instr !== 'all' || q !== ''} onClear={() => { setInstr('all'); setQ(''); }} shown={shown.length} total={data.metrics.length}>
          <SearchInput value={q} onChange={setQ} placeholder={intl.formatMessage({ id: 'ph.insights.search' })} />
          <SelectMenu
            label={intl.formatMessage({ id: 'ph.insights.status' })}
            value={instr}
            onChange={setInstr}
            options={[
              { value: 'all', label: `${intl.formatMessage({ id: 'ph.insights.status' })}: ${intl.formatMessage({ id: 'ph.filter.all' })}` },
              { value: 'gaps', label: intl.formatMessage({ id: 'ph.insights.gaps' }) },
              ...metricInstrumentations.map((x) => ({ value: x, label: intl.formatMessage({ id: `ph.instr.${x}` }) })),
            ]}
          />
        </FilterBar>
        <TableScroll min={760}>
          <table className="table">
            <thead>
              <tr>
                <th className="w-16">Id</th>
                <th>
                  <FormattedMessage id="ph.insights.col.metric" />
                </th>
                <th>
                  <FormattedMessage id="ph.insights.status" />
                </th>
                <th>
                  <FormattedMessage id="ph.col.features" />
                </th>
              </tr>
            </thead>
            <tbody>
              {shown.map((m) => (
                <tr key={m.id} className="align-top">
                  <td className="font-mono text-[12.5px] font-semibold">{m.id}</td>
                  <td>
                    <button type="button" className={`${linkClass} text-left font-medium text-foreground`} aria-expanded={open === m.id} onClick={() => setOpen(open === m.id ? null : m.id)}>
                      {m.name}
                    </button>
                    <div className="text-xs text-muted-foreground">{m.section}</div>
                    {open === m.id && (
                      <dl className="mt-2 grid gap-1 text-[12.5px]">
                        <Detail label="ph.insights.numerator">{m.numerator}</Detail>
                        <Detail label="ph.insights.denominator">{m.denominator}</Detail>
                        <Detail label="ph.insights.source">{m.source}</Detail>
                        <Detail label="ph.insights.plan">
                          <FormattedMessage id={`ph.plan.${m.planStatus}`} />
                        </Detail>
                        {Object.keys(m.probe).length > 0 && (
                          <Detail label="ph.insights.probe">
                            <span className="font-mono">{Object.entries(m.probe).map(([k, v]) => `${k}: ${v.split('/')[1]}`).join(' · ')}</span>
                          </Detail>
                        )}
                        {m.note && <Detail label="ph.insights.note">{m.note}</Detail>}
                      </dl>
                    )}
                  </td>
                  <td>
                    <InstrumentationPill value={m.instrumentation} />
                  </td>
                  <td className="text-[12px]">
                    {m.features.length ? (
                      m.features.map((f) => (
                        <button key={f} type="button" className={`${linkClass} mr-2 font-mono`} onClick={() => navigate('product', `features/${f}`)}>
                          {f}
                        </button>
                      ))
                    ) : (
                      <span className="text-muted-foreground">—</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      </Section>
    </div>
  );
}

function Detail({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="grid grid-cols-[110px_1fr] gap-2">
      <dt className="text-muted-foreground">
        <FormattedMessage id={label} />
      </dt>
      <dd className="[overflow-wrap:anywhere]">{children}</dd>
    </div>
  );
}

function HealthLoader() {
  const [load, reload] = useLoad<HealthView>('productHubHealth', {}, 'health');
  return <Loaded load={load} reload={reload}>{(d) => <HealthView data={d} />}</Loaded>;
}

export function HealthView({ data }: { data: HealthView }) {
  const intl = useIntl();
  const navigate = useNavigate();
  const feature = (f: string) => (
    <button key={f} type="button" className={`${linkClass} font-mono text-[12.5px]`} onClick={() => navigate('product', `features/${f}`)}>
      {f}
    </button>
  );
  const w = data.waiting;
  const waitingSections = w.sections.length;
  return (
    <div className="grid gap-4 [&>*]:min-w-0">
      <StatTiles
        items={[
          { key: 'stale', label: <FormattedMessage id="ph.health.stale" />, value: data.stale.length, tone: data.stale.length ? 'warn' : 'default' },
          { key: 'dead', label: <FormattedMessage id="ph.health.dead" />, value: data.deadGlobs.length, tone: data.deadGlobs.length ? 'warn' : 'default' },
          { key: 'waiting', label: <FormattedMessage id="ph.health.waiting" />, value: waitingSections + w.changeSets.length + w.suggestedConflicts + w.drafts, foot: <FormattedMessage id="ph.health.waitingFoot" values={{ s: waitingSections, c: w.changeSets.length, k: w.suggestedConflicts, d: w.drafts }} /> },
          { key: 'unreviewed', label: <FormattedMessage id="ph.health.unreviewed" />, value: data.unreviewed.length },
        ]}
      />
      {data.index.behind && (
        <Notice tone="warn">
          <FormattedMessage id="ph.health.indexBehind" />
        </Notice>
      )}
      <div className="grid items-start gap-4 lg:grid-cols-2 [&>*]:min-w-0">
        <Section title={<FormattedMessage id="ph.health.stale" />} hint={<FormattedMessage id="ph.health.staleHint" />}>
          {data.stale.length === 0 ? (
            <Meta>
              <FormattedMessage id="ph.health.none" />
            </Meta>
          ) : (
            <ul className="grid gap-2 text-[13px]">
              {data.stale.map((x) => (
                <li key={`${x.feature}/${x.key}`} className="grid gap-0.5">
                  <span>
                    {feature(x.feature)} · <FormattedMessage id={`ph.section.${x.key}`} />
                  </span>
                  {x.paths.map((p) => (
                    <PathText key={p} path={p} />
                  ))}
                </li>
              ))}
            </ul>
          )}
        </Section>
        <Section title={<FormattedMessage id="ph.health.dead" />} hint={<FormattedMessage id="ph.health.deadHint" />}>
          {data.deadGlobs.length === 0 ? (
            <Meta>
              <FormattedMessage id="ph.health.none" />
            </Meta>
          ) : (
            <ul className="grid gap-2 text-[13px]">
              {data.deadGlobs.map((x) => (
                <li key={x.feature} className="grid gap-0.5">
                  {feature(x.feature)}
                  {x.globs.map((g) => (
                    <PathText key={g} path={g} />
                  ))}
                </li>
              ))}
            </ul>
          )}
        </Section>
        <Section title={<FormattedMessage id="ph.health.old" />} hint={<FormattedMessage id="ph.health.oldHint" />}>
          {data.oldSources.length === 0 ? (
            <Meta>
              <FormattedMessage id="ph.health.none" />
            </Meta>
          ) : (
            <ul className="grid gap-2 text-[13px]">
              {data.oldSources.map((s) => (
                <li key={s.id} className="grid gap-0.5">
                  <button type="button" className={`${linkClass} justify-self-start text-left`} onClick={() => navigate('product', `sources/${s.id}`)}>
                    {s.title}
                  </button>
                  <span className="text-xs text-muted-foreground">
                    <FormattedMessage id="ph.health.oldMeta" values={{ date: s.docDate ? shortDate(intl, s.docDate) : '—', days: s.days ?? 0 }} />{' '}
                    {s.features.slice(0, 4).join(', ')}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </Section>
        <Section title={<FormattedMessage id="ph.health.waiting" />}>
          <ul className="grid gap-1.5 text-[13px]">
            <Row label="ph.health.w.changeSets" value={w.changeSets.length} onClick={() => navigate('product', 'sources')} />
            <Row label="ph.health.w.sections" value={waitingSections} />
            <Row label="ph.health.w.suggested" value={w.suggestedConflicts} onClick={() => navigate('product', 'decisions/conflicts')} />
            <Row label="ph.health.w.open" value={w.openConflicts} onClick={() => navigate('product', 'decisions/conflicts')} />
            <Row label="ph.health.w.drafts" value={w.drafts} onClick={() => navigate('product', 'decisions/drafts')} />
            <Row label="ph.health.w.opportunities" value={w.proposedOpportunities} onClick={() => navigate('product', 'decisions/opportunities')} />
          </ul>
          {w.sections.length > 0 && (
            <p className="mt-3 text-xs text-muted-foreground">
              <FormattedMessage id="ph.health.w.sectionsList" values={{ list: [...new Set(w.sections.map((x) => x.feature))].join(', ') }} />
            </p>
          )}
        </Section>
      </div>
      <Section title={<FormattedMessage id="ph.health.unreviewed" />} hint={<FormattedMessage id="ph.health.unreviewedHint" />}>
        <span className="flex flex-wrap gap-x-3 gap-y-1">{data.unreviewed.map(feature)}</span>
      </Section>
    </div>
  );
}

function Row({ label, value, onClick }: { label: string; value: number; onClick?: () => void }) {
  return (
    <li className="flex items-center justify-between gap-3">
      <FormattedMessage id={label} />
      {onClick && value > 0 ? (
        <button type="button" className={`${linkClass} tabular-nums`} onClick={onClick}>
          {value}
        </button>
      ) : (
        <span className="tabular-nums">{value}</span>
      )}
    </li>
  );
}
