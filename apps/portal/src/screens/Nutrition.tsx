import {
  nutritionAgeLabel,
  nutritionLimits,
  nutritionMetrics,
  nutritionConditions,
  staffCan,
  type NutritionAge,
  type NutritionCondition,
  type NutritionMetric,
} from '@child-life/contracts';
import { Milk, Plus, Sparkles, Waypoints } from 'lucide-react';
import { useEffect, useMemo, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { cn } from '@/lib/utils';
import {
  EmptyState,
  FilterBar,
  Notice,
  OverflowMenu,
  SearchInput,
  Section,
  StatTiles,
} from '../content-kit';
import { subPath, useStaff } from '../context';
import { Button, Loaded, Page, SelectMenu, TableScroll, useSort } from '../ui';
import {
  StatusCell,
  contentTiles,
  dateTime,
  statusOptions,
  textOf,
  tileMatch,
  useContentList,
  useSeedItem,
  type ContentListView,
  type ContentRow,
  type Tile,
} from './content-common';
import {
  ExistingNutrient,
  ExistingNutritionRule,
  ExistingNutritionStage,
  NutrientEditorShell,
  NutritionRuleEditorShell,
  NutritionStageEditorShell,
} from './NutritionEditors';
import {
  ageOf,
  countOf,
  locOf,
  milkCell,
  milkOf,
  monthsText,
  nutritionCoverageOf,
  nutritionPathOf,
  nutritionTabs,
  nutritionUrl,
  reviewMonth,
  roundText,
  roundsOf,
  type CoverageItemState,
  type NutritionCoverage,
  type NutritionPath,
  type NutritionTab,
} from './nutrition-common';

/**
 * Dinh dưỡng theo giai đoạn (D-083, P-163; Figma D01 `442:4354`, D02 `442:4716`, D03 `442:53582`,
 * D04 `442:53870`; plan `docs/product/nutrition-plan.md` §5): one page with three tabs on the
 * editorial workflow. Giai đoạn lists the stages with the 0–36 month coverage and its gaps
 * (P-163 #17); Vi chất the shared micronutrient library; Quy tắc gợi ý the rules the app checks on
 * the device. Each opens its editor at `/nutrition/{tab}/{id}` (`/new` for a new one).
 */

export function NutritionScreen() {
  const [path, setPath] = useState<NutritionPath>(() =>
    nutritionPathOf(subPath('nutrition', window.location.pathname)),
  );
  useEffect(() => {
    const onPop = () => setPath(nutritionPathOf(subPath('nutrition', window.location.pathname)));
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, []);
  const go = (next: NutritionPath) => {
    const url = nutritionUrl(next);
    if (window.location.pathname !== url) window.history.pushState({}, '', url);
    const tabOnly = next.id === undefined && path.id === undefined;
    setPath(next);
    if (!tabOnly) window.scrollTo(0, 0);
  };
  if (path.id === undefined) return <NutritionLists tab={path.tab} go={go} />;
  const onBack = () => go({ tab: path.tab });
  const onOpen = (id: string) => go({ tab: path.tab, id });
  const none = () => undefined;
  switch (path.tab) {
    case 'stages':
      return path.id ? (
        <ExistingNutritionStage key={path.id} id={path.id} onBack={onBack} onOpen={onOpen} />
      ) : (
        <NutritionStageEditorShell
          key={`new:${path.range?.from}-${path.range?.to}`}
          item={null}
          range={path.range ?? null}
          onBack={onBack}
          onOpen={onOpen}
          reload={none}
        />
      );
    case 'nutrients':
      return path.id ? (
        <ExistingNutrient key={path.id} id={path.id} onBack={onBack} onOpen={onOpen} />
      ) : (
        <NutrientEditorShell key="new" item={null} onBack={onBack} onOpen={onOpen} reload={none} />
      );
    case 'rules':
      return path.id ? (
        <ExistingNutritionRule key={path.id} id={path.id} onBack={onBack} onOpen={onOpen} />
      ) : (
        <NutritionRuleEditorShell
          key="new"
          item={null}
          onBack={onBack}
          onOpen={onOpen}
          reload={none}
        />
      );
  }
}

function NutritionLists({ tab, go }: { tab: NutritionTab; go: (p: NutritionPath) => void }) {
  const staff = useStaff();
  const intl = useIntl();
  const canEdit = staffCan(staff.levels, 'content.edit');
  const [stages, reloadStages] = useContentList('nutritionStage');
  const [nutrients, reloadNutrients] = useContentList('nutrient');
  const [rules, reloadRules] = useContentList('nutritionRule');
  const seeds = {
    stages: useSeedItem('nutritionStage', reloadStages),
    nutrients: useSeedItem('nutrient', reloadNutrients),
    rules: useSeedItem('nutritionRule', reloadRules),
  };
  const loads = { stages, nutrients, rules };
  const countOfTab = (t: NutritionTab) => {
    const l = loads[t];
    return l.status === 'ok' ? l.data.rows.filter((r) => r.status !== 'archived').length : null;
  };
  const nutrientRows = nutrients.status === 'ok' ? nutrients.data.rows : [];
  return (
    <Page
      title={<FormattedMessage id="nutrition.title" />}
      info={<FormattedMessage id={`nutrition.sub.${tab}`} />}
      actions={
        canEdit && (
          <>
            <OverflowMenu items={[seeds[tab]]} />
            <Button kind="primary" onClick={() => go({ tab, id: null })}>
              <Plus />
              <FormattedMessage id={`nutrition.new.${tab}`} />
            </Button>
          </>
        )
      }
    >
      <Tabs value={tab} onValueChange={(v) => go({ tab: v as NutritionTab })} className="gap-4">
        <TabsList aria-label={intl.formatMessage({ id: 'nutrition.tabs' })}>
          {nutritionTabs.map((t) => {
            const n = countOfTab(t);
            const label = intl.formatMessage({ id: `nutrition.tab.${t}` });
            return (
              <TabsTrigger key={t} value={t} className="px-3">
                {n === null ? (
                  label
                ) : (
                  <FormattedMessage id="nutrition.tabCount" values={{ label, n }} />
                )}
              </TabsTrigger>
            );
          })}
        </TabsList>
        <TabsContent value="stages">
          <Loaded load={stages} reload={reloadStages}>
            {(view) => (
              <NutritionStagesBody
                view={view}
                nutrients={nutrientRows}
                canEdit={canEdit}
                onOpen={(id) => go({ tab: 'stages', id })}
                onCreate={(range) => go({ tab: 'stages', id: null, range })}
              />
            )}
          </Loaded>
        </TabsContent>
        <TabsContent value="nutrients">
          <Loaded load={nutrients} reload={reloadNutrients}>
            {(view) => <NutrientsBody view={view} onOpen={(id) => go({ tab: 'nutrients', id })} />}
          </Loaded>
        </TabsContent>
        <TabsContent value="rules">
          <Loaded load={rules} reload={reloadRules}>
            {(view) => <NutritionRulesBody view={view} onOpen={(id) => go({ tab: 'rules', id })} />}
          </Loaded>
        </TabsContent>
      </Tabs>
    </Page>
  );
}

// ---------- Shared list frame ----------

function useListFilter(view: ContentListView, extra: (r: ContentRow) => string) {
  const [q, setQ] = useState('');
  const [status, setStatus] = useState('all');
  const [tile, setTile] = useState<Tile>('all');
  const needle = q.trim().toLowerCase();
  const rows = view.rows.filter(
    (r) =>
      tileMatch(r, tile) &&
      (status === 'all' || r.displayStatus === status) &&
      (!needle || `${r.title.vi} ${r.title.en} ${r.id} ${extra(r)}`.toLowerCase().includes(needle)),
  );
  return {
    q,
    setQ,
    status,
    setStatus,
    tile,
    setTile,
    rows,
    active: !!q || status !== 'all' || tile !== 'all',
    clear: () => {
      setQ('');
      setStatus('all');
      setTile('all');
    },
  };
}

function ListFrame({
  tab,
  view,
  filter: f,
  icon,
  top,
  children,
}: {
  tab: NutritionTab;
  view: ContentListView;
  filter: ReturnType<typeof useListFilter>;
  icon: typeof Milk;
  top?: ReactNode;
  children: ReactNode;
}) {
  const intl = useIntl();
  return (
    <div className="grid gap-4">
      <StatTiles items={contentTiles(view.counts, f.tile, f.setTile)} />
      {top}
      <div className="overflow-hidden rounded-xl border bg-card">
        <FilterBar
          active={f.active}
          onClear={f.clear}
          shown={f.rows.length}
          total={view.rows.length}
        >
          <SearchInput
            value={f.q}
            placeholder={intl.formatMessage({ id: `nutrition.search.${tab}` })}
            onChange={f.setQ}
          />
          <SelectMenu
            label={intl.formatMessage({ id: 'content.filter.status' })}
            value={f.status}
            onChange={f.setStatus}
            options={statusOptions(intl)}
          />
        </FilterBar>
        {f.rows.length ? (
          children
        ) : (
          <EmptyState
            icon={icon}
            title={
              <FormattedMessage
                id={view.rows.length ? 'content.noMatch' : `nutrition.empty.${tab}`}
              />
            }
          />
        )}
      </div>
      <Notice tone={tab === 'rules' ? 'warn' : 'info'}>
        <FormattedMessage id={`nutrition.note.${tab}`} />
      </Notice>
    </div>
  );
}

function TitleButton({ row, onOpen }: { row: ContentRow; onOpen: (id: string) => void }) {
  const intl = useIntl();
  return (
    <button
      type="button"
      className="link-button line-clamp-2 text-left font-medium"
      onClick={(e) => {
        e.stopPropagation();
        onOpen(row.id);
      }}
    >
      {textOf(intl, row.title) || (
        <span className="text-muted-foreground">
          <FormattedMessage id="content.untitled" />
        </span>
      )}
    </button>
  );
}

function TwoLines({ main, sub }: { main: ReactNode; sub?: ReactNode }) {
  return (
    <>
      <span className="block">{main ?? '—'}</span>
      {sub && <span className="block text-xs text-muted-foreground">{sub}</span>}
    </>
  );
}

function UpdatedCell({ row }: { row: ContentRow }) {
  const intl = useIntl();
  return (
    <td className="nowrap text-muted-foreground tabular-nums" title={row.lastEditorName}>
      {dateTime(intl, row.updatedAt)}
    </td>
  );
}

/** "BS. Mai Hồ · 08/2026" once a qualified review is on the app, else the expected reviewer. */
function ReviewerCell({ row }: { row: ContentRow }) {
  if (row.live?.reviewer) {
    return <TwoLines main={row.live.reviewer} sub={reviewMonth(row.live.reviewDueOn)} />;
  }
  return (
    <TwoLines
      main="—"
      sub={
        row.reviewerLabel ? (
          <FormattedMessage id="nutrition.expectedReviewer" values={{ name: row.reviewerLabel }} />
        ) : undefined
      }
    />
  );
}

const ageFrom = (r: ContentRow) => ageOf(r.ageMonths)?.from ?? null;
const ageTo = (r: ContentRow) => ageOf(r.ageMonths)?.to ?? null;
const byAge = (a: ContentRow, b: ContentRow) =>
  (ageFrom(a) ?? 99) - (ageFrom(b) ?? 99) || (ageTo(a) ?? 99) - (ageTo(b) ?? 99);

// ---------- D01 Giai đoạn ----------

export function NutritionStagesBody({
  view,
  nutrients,
  canEdit,
  onOpen,
  onCreate,
}: {
  view: ContentListView;
  /** The micronutrient rows, for the tag names. */
  nutrients: ContentRow[];
  canEdit: boolean;
  onOpen: (id: string) => void;
  onCreate: (range: NutritionAge) => void;
}) {
  const intl = useIntl();
  const f = useListFilter(view, (r) => {
    const s = locOf(r.solidsMeals);
    return s ? `${s.vi} ${s.en}` : '';
  });
  const sorted = useSort(f.rows, {
    age: ageFrom,
    title: (r) => textOf(intl, r.title),
    status: (r) => r.displayStatus,
    updated: (r) => r.updatedAt,
  });
  // D01 lists by age by default.
  const shown = useMemo(
    () => (sorted.rows === f.rows ? [...f.rows].sort(byAge) : sorted.rows),
    [sorted.rows, f.rows],
  );
  const coverage = nutritionCoverageOf(view);
  const nameOf = (id: string) => {
    const n = nutrients.find((x) => x.id === id);
    return n ? textOf(intl, n.title) || id : id;
  };
  return (
    <ListFrame
      tab="stages"
      view={view}
      filter={f}
      icon={Milk}
      top={
        <NutritionCoverageStrip
          coverage={coverage}
          rows={view.rows}
          canEdit={canEdit}
          onOpen={onOpen}
          onCreate={onCreate}
        />
      }
    >
      <TableScroll min={1040}>
        <table className="table">
          <thead>
            <tr>
              {sorted.th('age', <FormattedMessage id="nutrition.col.age" />)}
              {sorted.th('title', <FormattedMessage id="nutrition.col.stage" />)}
              <th>
                <FormattedMessage id="nutrition.col.milk" />
              </th>
              <th>
                <FormattedMessage id="nutrition.col.solids" />
              </th>
              <th>
                <FormattedMessage id="nutrition.col.nutrients" />
              </th>
              <th>
                <FormattedMessage id="nutrition.col.reviewer" />
              </th>
              {sorted.th('status', <FormattedMessage id="content.col.status" />)}
              {sorted.th('updated', <FormattedMessage id="content.col.updated" />)}
            </tr>
          </thead>
          <tbody>
            {shown.map((r) => {
              const age = ageOf(r.ageMonths);
              const milk = milkCell(intl, milkOf(r.milk));
              const solids = locOf(r.solidsMeals);
              const ids = Array.isArray(r.nutrientIds)
                ? (r.nutrientIds as unknown[]).filter((x): x is string => typeof x === 'string')
                : [];
              return (
                <tr key={r.id} className="cl-row" onClick={() => onOpen(r.id)}>
                  <td className="nowrap font-medium">{age ? monthsText(intl, age) : '—'}</td>
                  <td className="max-w-[18rem]">
                    <TitleButton row={r} onOpen={onOpen} />
                  </td>
                  <td className="nowrap tabular-nums">
                    <TwoLines main={milk.main} sub={milk.sub} />
                  </td>
                  <td className="max-w-[12rem]">{(solids && textOf(intl, solids)) || '—'}</td>
                  <td>
                    {ids.length ? (
                      <span className="flex max-w-[14rem] flex-wrap gap-1">
                        {ids.map((id) => (
                          <span key={id} className="cl-tag px-2 py-0.5 text-xs">
                            {nameOf(id)}
                          </span>
                        ))}
                      </span>
                    ) : (
                      '—'
                    )}
                  </td>
                  <td className="nowrap">
                    <ReviewerCell row={r} />
                  </td>
                  <td>
                    <StatusCell row={r} />
                  </td>
                  <UpdatedCell row={r} />
                </tr>
              );
            })}
          </tbody>
        </table>
      </TableScroll>
    </ListFrame>
  );
}

const segTone: Record<CoverageItemState | 'gap', string> = {
  published: 'border-primary bg-primary text-primary-foreground',
  pending: 'border-[var(--sunshine)] bg-[var(--sunshine)] text-[#3a3115]',
  draft: 'border-chart-5 bg-chart-5/15 text-foreground',
  gap: 'border-dashed border-destructive/70 bg-transparent text-destructive',
};
const dotTone: Record<CoverageItemState | 'gap', string> = {
  published: 'bg-primary',
  pending: 'bg-[var(--sunshine)]',
  draft: 'bg-chart-5/60',
  gap: 'border border-dashed border-destructive bg-destructive/10',
};
/** The month ruler's cells: the best state of the stages covering the month, gaps hatched. */
const monthTone: Record<CoverageItemState | 'gap', string> = {
  published: 'bg-primary',
  pending: 'bg-[var(--sunshine)]',
  draft: 'bg-chart-5/60',
  gap: 'border border-destructive/50 bg-[image:repeating-linear-gradient(135deg,color-mix(in_oklab,var(--destructive)_30%,transparent)_0_3px,transparent_3px_6px)]',
};
const stateRank: Record<CoverageItemState, number> = { published: 0, pending: 1, draft: 2 };

type Segment = {
  key: string;
  age: NutritionAge;
  lane: number;
  item: { id: string; state: CoverageItemState } | null;
};

/** Stages as segments over months 0–36 (overlapping ones on a lane below), gaps on the first. */
function segmentsOf(c: NutritionCoverage): Segment[] {
  const ends: number[] = [];
  const items = c.items.map((i) => {
    let lane = ends.findIndex((end) => end <= i.ageMonths.from);
    if (lane < 0) lane = ends.push(0) - 1;
    ends[lane] = i.ageMonths.to;
    return { key: i.id, age: i.ageMonths, lane, item: { id: i.id, state: i.state } };
  });
  const gaps = c.gaps.map((g) => ({ key: `gap-${g.from}`, age: g, lane: 0, item: null }));
  return [...items, ...gaps];
}

/**
 * Month by month (0…36): the stage the app shows for that month (the best state among the stages
 * covering it: on the app, then waiting, then draft), or none (a gap).
 */
export function coverageMonths(c: NutritionCoverage, months = nutritionLimits.maxAgeMonths + 1) {
  return Array.from({ length: months }, (_, m) => {
    const hits = c.items
      .filter((i) => m >= i.ageMonths.from && m < i.ageMonths.to)
      .sort((a, b) => stateRank[a.state] - stateRank[b.state]);
    const gap = c.gaps.find((g) => m >= g.from && m < g.to) ?? null;
    return { month: m, item: hits[0] ?? null, gap };
  });
}

/**
 * D01 "Độ phủ 0–36 tháng" (P-163 #17; owner 2026-10-21: a clearer view): a month ruler 0…36
 * coloured by state with a tooltip per month, the stages over the months they cover (opens one),
 * the gaps hatched (start a stage there), a legend with month counts, the months not on the app
 * yet (the tile is a teaser there) and any overlap (Duyệt / Xuất bản refuse it). Folded while
 * nothing is missing.
 */
export function NutritionCoverageStrip({
  coverage,
  rows,
  canEdit,
  onOpen,
  onCreate,
}: {
  coverage: NutritionCoverage;
  rows: ContentRow[];
  canEdit: boolean;
  onOpen: (id: string) => void;
  onCreate: (range: NutritionAge) => void;
}) {
  const intl = useIntl();
  const months = nutritionLimits.maxAgeMonths + 1;
  // A label column, then one column per month.
  const cols = { gridTemplateColumns: `5.5rem repeat(${months}, minmax(0, 1fr))` };
  const short = (a: NutritionAge) => {
    const l = nutritionAgeLabel(a);
    return `${l.from}–${l.to}`;
  };
  const titleOf = (id: string) => {
    const r = rows.find((x) => x.id === id);
    return r ? textOf(intl, r.title) : '';
  };
  const named = (id: string, age: NutritionAge) =>
    [monthsText(intl, age), titleOf(id)].filter(Boolean).join(' · ');
  const list = (xs: NutritionAge[]) => xs.map((a) => monthsText(intl, a)).join(', ');
  const ageById = new Map(coverage.items.map((i) => [i.id, i.ageMonths]));
  const sameGaps = JSON.stringify(coverage.gaps) === JSON.stringify(coverage.liveGaps);
  const byMonth = coverageMonths(coverage, months);
  const monthsIn = (state: CoverageItemState | 'gap') =>
    byMonth.filter((m) => (m.item ? m.item.state : 'gap') === state).length;
  const stateText = (state: CoverageItemState) =>
    intl.formatMessage({ id: `stages.state.${state}` });
  const lanes = Math.max(1, ...segmentsOf(coverage).map((s) => s.lane + 1));
  const rowLabel = 'self-center pr-2 text-xs font-medium text-muted-foreground';
  const count = (
    <FormattedMessage
      id="nutrition.coverage.covered"
      values={{ n: coverage.covered, total: coverage.total }}
    />
  );
  return (
    <Section
      title={<FormattedMessage id="nutrition.coverage" />}
      collapsible
      defaultOpen={coverage.gaps.length > 0 || coverage.overlaps.length > 0}
      summary={count}
      actions={<span className="text-sm font-medium tabular-nums">{count}</span>}
    >
      <TooltipProvider delayDuration={100}>
        <div className="overflow-x-auto pb-1">
          <div className="grid min-w-[640px] gap-y-1.5" style={cols}>
            {/* Month by month: the state the app is in for a baby that age. */}
            <span className={rowLabel} style={{ gridColumn: 1, gridRow: 1 }}>
              <FormattedMessage id="nutrition.coverage.byMonth" />
            </span>
            {byMonth.map(({ month, item, gap }) => {
              const label = item
                ? intl.formatMessage(
                    { id: 'nutrition.coverage.monthStage' },
                    {
                      month,
                      title: titleOf(item.id) || monthsText(intl, item.ageMonths),
                      status: stateText(item.state),
                    },
                  )
                : intl.formatMessage({ id: 'nutrition.coverage.monthGap' }, { month });
              const tone = monthTone[item ? item.state : 'gap'];
              const place = { gridColumn: month + 2, gridRow: 1 };
              const act = item
                ? () => onOpen(item.id)
                : canEdit && gap
                  ? () => onCreate(gap)
                  : undefined;
              return (
                <Tooltip key={month}>
                  <TooltipTrigger asChild>
                    {act ? (
                      <button
                        type="button"
                        style={place}
                        aria-label={label}
                        className={cn(
                          'mx-px h-6 rounded-[3px] outline-none hover:opacity-80 focus-visible:ring-[3px] focus-visible:ring-ring/50',
                          tone,
                        )}
                        onClick={act}
                      />
                    ) : (
                      <span
                        style={place}
                        role="img"
                        aria-label={label}
                        className={cn('mx-px h-6 rounded-[3px]', tone)}
                      />
                    )}
                  </TooltipTrigger>
                  <TooltipContent>{label}</TooltipContent>
                </Tooltip>
              );
            })}

            {/* The stages over the months they cover; overlapping ones on a lane below. */}
            <span
              className={cn(rowLabel, 'self-start pt-2')}
              style={{ gridColumn: 1, gridRow: `2 / span ${lanes}` }}
            >
              <FormattedMessage id="nutrition.coverage.byStage" />
            </span>
            {segmentsOf(coverage).map((s) => {
              const place = {
                gridColumn: `${s.age.from + 2} / ${Math.min(s.age.to, months) + 2}`,
                gridRow: s.lane + 2,
              };
              const base =
                'h-8 min-w-0 truncate rounded-md border px-1.5 text-left text-[11px] font-medium tabular-nums';
              if (s.item) {
                const state = stateText(s.item.state);
                const name = `${named(s.item.id, s.age)} · ${state}`;
                const id = s.item.id;
                const title = titleOf(id);
                return (
                  <button
                    key={s.key}
                    type="button"
                    style={place}
                    title={name}
                    aria-label={name}
                    className={cn(
                      base,
                      segTone[s.item.state],
                      'transition-opacity hover:opacity-85',
                    )}
                    onClick={() => onOpen(id)}
                  >
                    {short(s.age)}
                    {title && <span className="font-normal opacity-80"> · {title}</span>}
                  </button>
                );
              }
              const name = canEdit
                ? intl.formatMessage(
                    { id: 'nutrition.coverage.add' },
                    { label: monthsText(intl, s.age) },
                  )
                : `${monthsText(intl, s.age)} · ${intl.formatMessage({ id: 'stages.state.missing' })}`;
              return canEdit ? (
                <button
                  key={s.key}
                  type="button"
                  style={place}
                  title={name}
                  aria-label={name}
                  className={cn(base, segTone.gap, 'text-center hover:bg-destructive/5')}
                  onClick={() => onCreate(s.age)}
                >
                  + {short(s.age)}
                </button>
              ) : (
                <span
                  key={s.key}
                  style={place}
                  title={name}
                  className={cn(base, segTone.gap, 'text-center leading-8')}
                >
                  {short(s.age)}
                </span>
              );
            })}

            {/* The ruler: a tick per month, a number every 3 months, the years in bold. */}
            <span
              className={cn(rowLabel, 'self-start')}
              style={{ gridColumn: 1, gridRow: lanes + 2 }}
            >
              <FormattedMessage id="nutrition.coverage.months" />
            </span>
            {byMonth.map(({ month }) => (
              <span
                key={month}
                aria-hidden="true"
                className="relative grid justify-items-center"
                style={{ gridColumn: month + 2, gridRow: lanes + 2 }}
              >
                <span
                  className={cn(
                    'w-px bg-border',
                    month % 12 === 0 ? 'h-3 bg-foreground/50' : month % 3 === 0 ? 'h-2' : 'h-1',
                  )}
                />
                {month % 3 === 0 && (
                  <span
                    className={cn(
                      'text-[11px] leading-4 tabular-nums',
                      month % 12 === 0 ? 'font-semibold text-foreground' : 'text-muted-foreground',
                    )}
                  >
                    {month}
                  </span>
                )}
              </span>
            ))}
          </div>
        </div>
      </TooltipProvider>
      <ul className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
        {(['published', 'pending', 'draft'] as const).map((s) => (
          <li key={s} className="flex items-center gap-1.5">
            <span className={cn('size-2.5 rounded-sm', dotTone[s])} aria-hidden="true" />
            <FormattedMessage
              id="nutrition.coverage.legend"
              values={{ label: stateText(s), n: monthsIn(s) }}
            />
          </li>
        ))}
        <li className={cn('flex items-center gap-1.5', coverage.gaps.length && 'text-destructive')}>
          <span className={cn('size-2.5 rounded-sm', dotTone.gap)} aria-hidden="true" />
          {coverage.gaps.length ? (
            <FormattedMessage id="nutrition.coverage.gaps" values={{ list: list(coverage.gaps) }} />
          ) : (
            <FormattedMessage id="stages.noGaps" />
          )}
        </li>
      </ul>
      {coverage.liveGaps.length > 0 && !sameGaps && (
        <p className="mt-2 text-xs text-muted-foreground">
          <FormattedMessage
            id="nutrition.coverage.liveGaps"
            values={{ list: list(coverage.liveGaps) }}
          />
        </p>
      )}
      {coverage.overlaps.length > 0 && (
        <Notice tone="warn" className="mt-3">
          <ul className="grid gap-1">
            {coverage.overlaps.map((o) => (
              <li key={o.ids.join(':')}>
                <FormattedMessage
                  id="nutrition.coverage.overlap"
                  values={{
                    first: named(o.ids[0], ageById.get(o.ids[0]) ?? o.ageMonths),
                    second: named(o.ids[1], ageById.get(o.ids[1]) ?? o.ageMonths),
                  }}
                />
              </li>
            ))}
          </ul>
        </Notice>
      )}
    </Section>
  );
}

// ---------- D03 Vi chất ----------

export function NutrientsBody({
  view,
  onOpen,
}: {
  view: ContentListView;
  onOpen: (id: string) => void;
}) {
  const intl = useIntl();
  const focusOf = (r: ContentRow) =>
    r.focus as { ageMonths?: unknown; label?: unknown; note?: unknown } | null | undefined;
  const f = useListFilter(view, (r) =>
    typeof r.key === 'string' && intl.messages[`nutrition.key.${r.key}`]
      ? intl.formatMessage({ id: `nutrition.key.${r.key}` })
      : '',
  );
  const sorted = useSort(f.rows, {
    name: (r) => textOf(intl, r.title),
    focus: (r) => ageOf(focusOf(r)?.ageMonths)?.from,
    status: (r) => r.displayStatus,
    updated: (r) => r.updatedAt,
  });
  return (
    <ListFrame tab="nutrients" view={view} filter={f} icon={Sparkles}>
      <TableScroll min={900}>
        <table className="table">
          <thead>
            <tr>
              {sorted.th('name', <FormattedMessage id="nutrition.col.nutrient" />)}
              {sorted.th('focus', <FormattedMessage id="nutrition.col.focus" />)}
              <th>
                <FormattedMessage id="nutrition.col.foods" />
              </th>
              <th>
                <FormattedMessage id="nutrition.col.warning" />
              </th>
              {sorted.th('status', <FormattedMessage id="content.col.status" />)}
              {sorted.th('updated', <FormattedMessage id="content.col.updated" />)}
            </tr>
          </thead>
          <tbody>
            {sorted.rows.map((r) => {
              const focus = focusOf(r);
              const age = ageOf(focus?.ageMonths);
              const label = locOf(focus?.label);
              const note = locOf(focus?.note);
              const labelText = label ? textOf(intl, label) : '';
              const ageText = age ? monthsText(intl, age) : null;
              const rounds = roundsOf(r.rounds);
              // The medical note when the row carries it (D03 "Ghi chú y khoa"), and the rounds.
              const warningLoc = locOf(r.warning);
              const warning = warningLoc ? textOf(intl, warningLoc) : '';
              return (
                <tr key={r.id} className="cl-row" onClick={() => onOpen(r.id)}>
                  <td className="max-w-[14rem]">
                    <TitleButton row={r} onOpen={onOpen} />
                  </td>
                  <td className="max-w-[16rem]">
                    <TwoLines
                      main={labelText || ageText}
                      sub={(note && textOf(intl, note)) || (labelText ? ageText : null)}
                    />
                  </td>
                  <td className="max-w-[18rem]">
                    <FoodsCell value={r.foods} />
                  </td>
                  <td className="max-w-[18rem]">
                    {warning || rounds.length ? (
                      <span className="grid justify-items-start gap-1">
                        {warning && (
                          <span className="line-clamp-2 whitespace-normal">{warning}</span>
                        )}
                        {rounds.length > 0 && (
                          <span className="cl-tag cl-tag--sunshine px-2 py-0.5 text-xs">
                            {rounds.map(roundText).join(', ')}
                          </span>
                        )}
                      </span>
                    ) : (
                      '—'
                    )}
                  </td>
                  <td>
                    <StatusCell row={r} />
                  </td>
                  <UpdatedCell row={r} />
                </tr>
              );
            })}
          </tbody>
        </table>
      </TableScroll>
    </ListFrame>
  );
}

/** The food chips when the row lists them, else how many there are. */
function FoodsCell({ value }: { value: unknown }) {
  const intl = useIntl();
  if (Array.isArray(value)) {
    const names = value.map((v) => (locOf(v) ? textOf(intl, locOf(v)) : String(v))).filter(Boolean);
    if (!names.length) return <>—</>;
    return (
      <span className="flex flex-wrap gap-1">
        {names.slice(0, 3).map((n, i) => (
          <span key={i} className="cl-tag px-2 py-0.5 text-xs">
            {n}
          </span>
        ))}
        {names.length > 3 && (
          <span className="text-xs text-muted-foreground">+{names.length - 3}</span>
        )}
      </span>
    );
  }
  const n = countOf(value);
  return n ? <FormattedMessage id="nutrition.foodsCount" values={{ n }} /> : <>—</>;
}

// ---------- D04 Quy tắc gợi ý ----------

/** "Dưới khoảng chuẩn WHO" and its detail line; null when the row has no known condition. */
export function conditionWords(
  intl: IntlShape,
  condition: unknown,
  days: unknown,
): { main: string; sub: string } | null {
  if (!(nutritionConditions as readonly unknown[]).includes(condition)) return null;
  const c = condition as NutritionCondition;
  return {
    main: intl.formatMessage(
      { id: `nutrition.condition.${c}` },
      { days: typeof days === 'number' ? days : 30 },
    ),
    sub: intl.formatMessage({ id: `nutrition.conditionDetail.${c}` }),
  };
}

export const metricOk = (m: unknown): m is NutritionMetric =>
  (nutritionMetrics as readonly unknown[]).includes(m);

export function NutritionRulesBody({
  view,
  onOpen,
}: {
  view: ContentListView;
  onOpen: (id: string) => void;
}) {
  const intl = useIntl();
  const metricText = (r: ContentRow) =>
    metricOk(r.metric) ? intl.formatMessage({ id: `nutrition.metric.${r.metric}` }) : '';
  const f = useListFilter(view, (r) => metricText(r));
  const sorted = useSort(f.rows, {
    metric: (r) => (metricOk(r.metric) ? nutritionMetrics.indexOf(r.metric) : null),
    age: ageFrom,
    status: (r) => r.displayStatus,
    updated: (r) => r.updatedAt,
  });
  const shown = useMemo(
    () =>
      sorted.rows === f.rows
        ? [...f.rows].sort(
            (a, b) =>
              (metricOk(a.metric) ? nutritionMetrics.indexOf(a.metric) : 9) -
                (metricOk(b.metric) ? nutritionMetrics.indexOf(b.metric) : 9) || byAge(a, b),
          )
        : sorted.rows,
    [sorted.rows, f.rows],
  );
  return (
    <ListFrame tab="rules" view={view} filter={f} icon={Waypoints}>
      <TableScroll min={960}>
        <table className="table">
          <thead>
            <tr>
              {sorted.th('metric', <FormattedMessage id="nutrition.col.metric" />)}
              <th>
                <FormattedMessage id="nutrition.col.condition" />
              </th>
              {sorted.th('age', <FormattedMessage id="nutrition.col.age" />)}
              <th>
                <FormattedMessage id="nutrition.col.shows" />
              </th>
              {sorted.th('status', <FormattedMessage id="content.col.status" />)}
              {sorted.th('updated', <FormattedMessage id="content.col.updated" />)}
            </tr>
          </thead>
          <tbody>
            {shown.map((r) => {
              const age = ageOf(r.ageMonths);
              const cond = conditionWords(intl, r.condition, r.days);
              const tips = countOf(r.tips) ?? 0;
              const parts = [
                intl.formatMessage({ id: 'nutrition.shows.tips' }, { n: tips }),
                typeof r.remindAfterDays === 'number'
                  ? intl.formatMessage({ id: 'nutrition.shows.remind' }, { n: r.remindAfterDays })
                  : null,
                r.export === true ? intl.formatMessage({ id: 'nutrition.shows.export' }) : null,
              ].filter(Boolean);
              const title = textOf(intl, r.title);
              return (
                <tr key={r.id} className="cl-row" onClick={() => onOpen(r.id)}>
                  <td className="nowrap font-medium">
                    <button
                      type="button"
                      className="link-button text-left"
                      onClick={(e) => {
                        e.stopPropagation();
                        onOpen(r.id);
                      }}
                    >
                      {metricText(r) || '—'}
                    </button>
                  </td>
                  <td className="max-w-[16rem]">
                    <TwoLines main={cond?.main ?? '—'} sub={cond?.sub} />
                  </td>
                  <td className="nowrap">{age ? monthsText(intl, age) : '—'}</td>
                  <td className="max-w-[24rem]">
                    <TwoLines
                      main={
                        title || (
                          <span className="text-muted-foreground">
                            <FormattedMessage id="nutrition.noBanner" />
                          </span>
                        )
                      }
                      sub={parts.join(' · ')}
                    />
                  </td>
                  <td>
                    <StatusCell row={r} />
                  </td>
                  <UpdatedCell row={r} />
                </tr>
              );
            })}
          </tbody>
        </table>
      </TableScroll>
    </ListFrame>
  );
}
