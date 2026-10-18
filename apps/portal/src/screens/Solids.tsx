import {
  foodAllergens,
  foodGroups,
  recipeMethods,
  staffCan,
  textureStages,
  type ArticleDraft,
  type FoodAllergen,
  type FoodGroup,
} from '@child-life/contracts';
import { Carrot, Plus, Soup } from 'lucide-react';
import { Fragment, useEffect, useMemo, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
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
import { ArticleEditorScreen, ArticlesBody, blankArticle } from './Articles';
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
import { ExistingFood, ExistingRecipe, FoodEditorShell, RecipeEditorShell } from './SolidsEditors';
import {
  allergensOfFoods,
  bandOf,
  bandOverlaps,
  catalogueOf,
  countsOfRows,
  foodCoverageOf,
  foodFactsOf,
  fromMonthsText,
  launchBands,
  recipeBands,
  recipeCoverageOf,
  recipeFactsOf,
  recipeTarget,
  solidsMonthsText,
  solidsPathOf,
  solidsTabs,
  solidsUrl,
  type FoodCoverage,
  type RecipeBandCoverage,
  type SolidsPath,
  type SolidsTab,
} from './solids-common';

/**
 * Ăn dặm (D-085, P-164 #8–#11; plan `docs/product/solids-plan.md` §6; the portal is not drawn and
 * follows Dinh dưỡng D01–D04): one page under NỘI DUNG with three tabs on the editorial workflow.
 * Thực phẩm lists the catalogue by food group (allergen, minimum age, iron, "Gợi ý") with its
 * coverage; Công thức lists the recipes by age band with 6 per band as the target; Hướng dẫn is
 * the article list filtered to `library: 'solids'` and opens the same article editor. Each opens
 * its editor at `/solids/{tab}/{id}` (`/new` for a new one).
 */

/** A new guide from Ăn dặm › Hướng dẫn: library "solids", topic "feeding", 6–12 months. */
export function blankSolidsGuide(): ArticleDraft {
  return { ...blankArticle(), library: 'solids', topic: 'feeding', ageWeeks: { from: 26, to: 52 } };
}

export function SolidsScreen() {
  const [path, setPath] = useState<SolidsPath>(() =>
    solidsPathOf(subPath('solids', window.location.pathname)),
  );
  useEffect(() => {
    const onPop = () => setPath(solidsPathOf(subPath('solids', window.location.pathname)));
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, []);
  const go = (next: SolidsPath) => {
    const url = solidsUrl(next);
    if (window.location.pathname !== url) window.history.pushState({}, '', url);
    const tabOnly = next.id === undefined && path.id === undefined;
    setPath(next);
    if (!tabOnly) window.scrollTo(0, 0);
  };
  if (path.id === undefined) return <SolidsLists tab={path.tab} go={go} />;
  const onBack = () => go({ tab: path.tab });
  const onOpen = (id: string) => go({ tab: path.tab, id });
  const none = () => undefined;
  switch (path.tab) {
    case 'foods':
      return path.id ? (
        <ExistingFood key={path.id} id={path.id} onBack={onBack} onOpen={onOpen} />
      ) : (
        <FoodEditorShell key="new" item={null} onBack={onBack} onOpen={onOpen} reload={none} />
      );
    case 'recipes':
      return path.id ? (
        <ExistingRecipe key={path.id} id={path.id} onBack={onBack} onOpen={onOpen} />
      ) : (
        <RecipeEditorShell key="new" item={null} onBack={onBack} onOpen={onOpen} reload={none} />
      );
    case 'guides':
      return (
        <ArticleEditorScreen
          key={path.id ?? 'new'}
          id={path.id}
          onOpen={(id) => (id ? onOpen(id) : onBack())}
          blank={blankSolidsGuide}
          backLabel={<FormattedMessage id="nav.solids" />}
        />
      );
  }
}

const seedKind = { foods: 'food', recipes: 'recipe', guides: 'article' } as const;

function SolidsLists({ tab, go }: { tab: SolidsTab; go: (p: SolidsPath) => void }) {
  const staff = useStaff();
  const intl = useIntl();
  const canEdit = staffCan(staff.levels, 'content.edit');
  const [foods, reloadFoods] = useContentList('food');
  const [recipes, reloadRecipes] = useContentList('recipe');
  const [articles, reloadArticles] = useContentList('article');
  const seeds = {
    foods: useSeedItem(seedKind.foods, reloadFoods),
    recipes: useSeedItem(seedKind.recipes, reloadRecipes),
    guides: useSeedItem(seedKind.guides, reloadArticles),
  };
  const countOfTab = (t: SolidsTab) => {
    const l = { foods, recipes, guides: articles }[t];
    if (l.status !== 'ok') return null;
    return l.data.rows.filter(
      (r) => r.status !== 'archived' && (t !== 'guides' || r.library === 'solids'),
    ).length;
  };
  const foodRows = foods.status === 'ok' ? foods.data.rows : [];
  return (
    <Page
      title={<FormattedMessage id="solids.title" />}
      subtitle={<FormattedMessage id={`solids.sub.${tab}`} />}
      actions={
        canEdit && (
          <>
            <OverflowMenu items={[seeds[tab]]} />
            <Button kind="primary" onClick={() => go({ tab, id: null })}>
              <Plus />
              <FormattedMessage id={`solids.new.${tab}`} />
            </Button>
          </>
        )
      }
    >
      <Tabs value={tab} onValueChange={(v) => go({ tab: v as SolidsTab })} className="gap-4">
        <TabsList aria-label={intl.formatMessage({ id: 'solids.tabs' })}>
          {solidsTabs.map((t) => {
            const n = countOfTab(t);
            const label = intl.formatMessage({ id: `solids.tab.${t}` });
            return (
              <TabsTrigger key={t} value={t} className="px-3">
                {n === null ? (
                  label
                ) : (
                  <FormattedMessage id="solids.tabCount" values={{ label, n }} />
                )}
              </TabsTrigger>
            );
          })}
        </TabsList>
        <TabsContent value="foods">
          <Loaded load={foods} reload={reloadFoods}>
            {(view) => <FoodsBody view={view} onOpen={(id) => go({ tab: 'foods', id })} />}
          </Loaded>
        </TabsContent>
        <TabsContent value="recipes">
          <Loaded load={recipes} reload={reloadRecipes}>
            {(view) => (
              <RecipesBody
                view={view}
                foods={foodRows}
                onOpen={(id) => go({ tab: 'recipes', id })}
              />
            )}
          </Loaded>
        </TabsContent>
        <TabsContent value="guides">
          <Loaded load={articles} reload={reloadArticles}>
            {(view) => <GuidesBody view={view} onOpen={(id) => go({ tab: 'guides', id })} />}
          </Loaded>
        </TabsContent>
      </Tabs>
    </Page>
  );
}

// ---------- Shared list pieces ----------

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

function UpdatedCell({ row }: { row: ContentRow }) {
  const intl = useIntl();
  return (
    <td className="nowrap text-muted-foreground tabular-nums" title={row.lastEditorName}>
      {dateTime(intl, row.updatedAt)}
    </td>
  );
}

function Tags({ items, tone }: { items: string[]; tone?: 'sunshine' | 'mint' }) {
  if (!items.length) return <>—</>;
  return (
    <span className="flex max-w-[14rem] flex-wrap gap-1">
      {items.map((x) => (
        <span key={x} className={cn('cl-tag px-2 py-0.5 text-xs', tone && `cl-tag--${tone}`)}>
          {x}
        </span>
      ))}
    </span>
  );
}

/** A group heading row inside a table (shown while the list keeps its default order). */
function GroupRow({ cols, children }: { cols: number; children: ReactNode }) {
  return (
    <tr className="bg-muted/50">
      <th colSpan={cols} scope="colgroup" className="py-1.5 text-left text-xs font-semibold">
        {children}
      </th>
    </tr>
  );
}

const yesNo = ['all', 'yes', 'no'] as const;
type YesNo = (typeof yesNo)[number];
const yesNoMatch = (f: YesNo, v: boolean | null) => f === 'all' || (f === 'yes') === (v === true);

// ---------- Thực phẩm ----------

type FoodFilters = {
  q: string;
  group: 'all' | FoodGroup;
  allergen: 'all' | 'any' | 'none' | FoodAllergen;
  iron: YesNo;
  suggest: YesNo;
  status: string;
  tile: Tile;
};
const allFoodFilters: FoodFilters = {
  q: '',
  group: 'all',
  allergen: 'all',
  iron: 'all',
  suggest: 'all',
  status: 'all',
  tile: 'all',
};

/** Thực phẩm filters: group, allergen (any, none or one), iron, "Gợi ý", status, a count tile. */
export function filterFoods(rows: ContentRow[], f: FoodFilters): ContentRow[] {
  const q = f.q.trim().toLowerCase();
  return rows.filter((r) => {
    const x = foodFactsOf(r);
    return (
      tileMatch(r, f.tile) &&
      (!q || [r.title.vi, r.title.en, r.id, ...x.synonyms].join(' ').toLowerCase().includes(q)) &&
      (f.group === 'all' || x.group === f.group) &&
      (f.allergen === 'all' ||
        (f.allergen === 'any'
          ? !!x.allergen
          : f.allergen === 'none'
            ? !x.allergen
            : x.allergen === f.allergen)) &&
      yesNoMatch(f.iron, x.ironRich) &&
      yesNoMatch(f.suggest, x.suggest) &&
      (f.status === 'all' || r.displayStatus === f.status)
    );
  });
}

export function FoodsBody({
  view,
  onOpen,
}: {
  view: ContentListView;
  onOpen: (id: string) => void;
}) {
  const intl = useIntl();
  const t = (id: string) => intl.formatMessage({ id });
  const [f, setF] = useState<FoodFilters>(allFoodFilters);
  const rows = filterFoods(view.rows, f);
  const sorted = useSort(rows, {
    name: (r) => textOf(intl, r.title),
    group: (r) => {
      const g = foodFactsOf(r).group;
      return g ? foodGroups.indexOf(g) : null;
    },
    age: (r) => foodFactsOf(r).minAgeMonths,
    status: (r) => r.displayStatus,
    updated: (r) => r.updatedAt,
  });
  // By group (in the 5e order), then by name, until a column is sorted.
  const grouped = sorted.rows === rows;
  const shown = useMemo(() => {
    if (!grouped) return rows;
    const rank = (r: ContentRow) => {
      const g = foodFactsOf(r).group;
      return g ? foodGroups.indexOf(g) : foodGroups.length;
    };
    return [...rows].sort(
      (a, b) =>
        rank(a) - rank(b) ||
        textOf(intl, a.title).localeCompare(textOf(intl, b.title), intl.locale),
    );
  }, [grouped, rows, intl]);
  const perGroup = new Map<FoodGroup | null, number>();
  for (const r of shown) {
    const g = foodFactsOf(r).group;
    perGroup.set(g, (perGroup.get(g) ?? 0) + 1);
  }
  const opt = <V extends string>(id: string, value: V) => ({ value, label: t(id) });
  const cols = 8;
  return (
    <div className="grid gap-4">
      <StatTiles items={contentTiles(view.counts, f.tile, (tile) => setF({ ...f, tile }))} />
      <FoodCoverageCard coverage={foodCoverageOf(view)} />
      <div className="overflow-hidden rounded-xl border bg-card">
        <FilterBar
          active={JSON.stringify(f) !== JSON.stringify(allFoodFilters)}
          onClear={() => setF(allFoodFilters)}
          shown={rows.length}
          total={view.rows.length}
        >
          <SearchInput
            value={f.q}
            placeholder={t('solids.search.foods')}
            onChange={(q) => setF({ ...f, q })}
          />
          <SelectMenu
            label={t('solids.filter.group')}
            value={f.group}
            onChange={(group) => setF({ ...f, group })}
            options={[
              opt('solids.filter.allGroups', 'all'),
              ...foodGroups.map((g) => opt(`solids.group.${g}`, g)),
            ]}
          />
          <SelectMenu
            label={t('solids.filter.allergen')}
            value={f.allergen}
            onChange={(allergen) => setF({ ...f, allergen })}
            options={[
              opt('solids.filter.allAllergens', 'all'),
              opt('solids.filter.anyAllergen', 'any'),
              opt('solids.allergen.none', 'none'),
              ...foodAllergens.map((a) => opt(`solids.allergen.${a}`, a)),
            ]}
          />
          <SelectMenu
            label={t('solids.filter.iron')}
            value={f.iron}
            onChange={(iron) => setF({ ...f, iron })}
            options={yesNo.map((v) => opt(`solids.filter.iron.${v}`, v))}
          />
          <SelectMenu
            label={t('solids.filter.suggest')}
            value={f.suggest}
            onChange={(suggest) => setF({ ...f, suggest })}
            options={yesNo.map((v) => opt(`solids.filter.suggest.${v}`, v))}
          />
          <SelectMenu
            label={t('content.filter.status')}
            value={f.status}
            onChange={(status) => setF({ ...f, status })}
            options={statusOptions(intl)}
          />
        </FilterBar>
        {rows.length ? (
          <TableScroll min={980}>
            <table className="table">
              <thead>
                <tr>
                  {sorted.th('name', <FormattedMessage id="solids.col.food" />)}
                  {sorted.th('group', <FormattedMessage id="solids.col.group" />)}
                  <th>
                    <FormattedMessage id="solids.col.allergen" />
                  </th>
                  {sorted.th('age', <FormattedMessage id="solids.col.minAge" />)}
                  <th>
                    <FormattedMessage id="solids.col.iron" />
                  </th>
                  <th>
                    <FormattedMessage id="solids.col.suggest" />
                  </th>
                  {sorted.th('status', <FormattedMessage id="content.col.status" />)}
                  {sorted.th('updated', <FormattedMessage id="content.col.updated" />)}
                </tr>
              </thead>
              <tbody>
                {shown.map((r, i) => {
                  const x = foodFactsOf(r);
                  const prev = i > 0 ? foodFactsOf(shown[i - 1]!).group : undefined;
                  const heading = grouped && (i === 0 || prev !== x.group);
                  return (
                    <Fragment key={r.id}>
                      {heading && (
                        <GroupRow cols={cols}>
                          <FormattedMessage
                            id="solids.groupCount"
                            values={{
                              label: x.group
                                ? t(`solids.group.${x.group}`)
                                : t('solids.group.unknown'),
                              n: perGroup.get(x.group) ?? 0,
                            }}
                          />
                        </GroupRow>
                      )}
                      <tr className="cl-row" onClick={() => onOpen(r.id)}>
                        <td className="max-w-[16rem]">
                          <TitleButton row={r} onOpen={onOpen} />
                          {x.synonyms.length > 0 && (
                            <div className="mt-0.5 truncate text-xs text-muted-foreground">
                              {x.synonyms.join(', ')}
                            </div>
                          )}
                        </td>
                        <td className="nowrap">{x.group ? t(`solids.group.${x.group}`) : '—'}</td>
                        <td>
                          {x.allergen ? (
                            <Tags items={[t(`solids.allergen.${x.allergen}`)]} tone="sunshine" />
                          ) : (
                            '—'
                          )}
                        </td>
                        <td className="nowrap tabular-nums">
                          {x.minAgeMonths !== null ? fromMonthsText(intl, x.minAgeMonths) : '—'}
                        </td>
                        <td className="nowrap">
                          {x.ironRich ? (
                            <span className="cl-tag cl-tag--mint px-2 py-0.5 text-xs">
                              <FormattedMessage id="solids.ironRich" />
                            </span>
                          ) : (
                            '—'
                          )}
                        </td>
                        <td className="nowrap">
                          {x.suggest === null ? (
                            '—'
                          ) : (
                            <FormattedMessage
                              id={x.suggest ? 'solids.suggest.yes' : 'solids.suggest.no'}
                            />
                          )}
                        </td>
                        <td>
                          <StatusCell row={r} />
                        </td>
                        <UpdatedCell row={r} />
                      </tr>
                    </Fragment>
                  );
                })}
              </tbody>
            </table>
          </TableScroll>
        ) : (
          <EmptyState
            icon={Carrot}
            title={
              <FormattedMessage id={view.rows.length ? 'content.noMatch' : 'solids.empty.foods'} />
            }
          />
        )}
      </div>
      <Notice tone="info">
        <FormattedMessage id="solids.note.foods" />
      </Notice>
    </div>
  );
}

/** "N món theo nhóm, N món giàu sắt, 9/9 nhóm dị ứng có món" (plan §6). */
export function FoodCoverageCard({ coverage: c }: { coverage: FoodCoverage }) {
  const intl = useIntl();
  const missing = foodAllergens.filter((a) => !c.allergens.includes(a));
  const emptyGroups = foodGroups.filter((g) => !c.byGroup[g]);
  const summary = (
    <FormattedMessage
      id="solids.coverage.foodsSummary"
      values={{ n: c.total, a: c.allergens.length, total: foodAllergens.length, c: c.ironRich }}
    />
  );
  return (
    <Section
      title={<FormattedMessage id="solids.coverage.foods" />}
      collapsible
      defaultOpen={missing.length > 0 || emptyGroups.length > 0}
      summary={summary}
      actions={<span className="text-sm font-medium tabular-nums">{summary}</span>}
    >
      <div className="grid gap-4">
        <ul className="grid grid-cols-2 gap-2 sm:grid-cols-4 lg:grid-cols-7">
          {foodGroups.map((g) => (
            <li
              key={g}
              className={cn(
                'grid gap-0.5 rounded-lg border px-3 py-2',
                !c.byGroup[g] && 'border-dashed border-destructive/70 text-destructive',
              )}
            >
              <span className="text-xs text-muted-foreground">
                <FormattedMessage id={`solids.group.${g}`} />
              </span>
              <span className="text-lg font-semibold tabular-nums">{c.byGroup[g]}</span>
            </li>
          ))}
        </ul>
        <div className="grid gap-3 sm:grid-cols-2">
          <div className="grid gap-1.5 rounded-lg border px-3 py-2">
            <span className="text-[13px] font-medium">
              <FormattedMessage
                id="solids.coverage.allergens"
                values={{ n: c.allergens.length, total: foodAllergens.length }}
              />
            </span>
            <span className="flex flex-wrap gap-1">
              {foodAllergens.map((a) => (
                <span
                  key={a}
                  className={cn(
                    'cl-tag px-2 py-0.5 text-xs',
                    c.allergens.includes(a) ? 'cl-tag--sunshine' : 'border-dashed text-destructive',
                  )}
                >
                  {intl.formatMessage({ id: `solids.allergen.${a}` })}
                </span>
              ))}
            </span>
            {missing.length > 0 && (
              <span className="text-xs text-destructive">
                <FormattedMessage
                  id="solids.coverage.allergensMissing"
                  values={{
                    list: missing
                      .map((a) => intl.formatMessage({ id: `solids.allergen.${a}` }))
                      .join(', '),
                  }}
                />
              </span>
            )}
          </div>
          <div className="grid content-start gap-1 rounded-lg border px-3 py-2">
            <span className="text-[13px] font-medium">
              <FormattedMessage id="solids.coverage.iron" values={{ n: c.ironRich }} />
            </span>
            <span className="text-xs text-muted-foreground">
              <FormattedMessage id="solids.coverage.live" values={{ n: c.live, total: c.total }} />
            </span>
          </div>
        </div>
      </div>
    </Section>
  );
}

// ---------- Công thức ----------

type RecipeFilters = {
  q: string;
  band: string;
  texture: string;
  method: string;
  status: string;
  tile: Tile;
};
const allRecipeFilters: RecipeFilters = {
  q: '',
  band: 'all',
  texture: 'all',
  method: 'all',
  status: 'all',
  tile: 'all',
};

/** Công thức filters: age band (overlap, as 5f), texture, method, status, a count tile. */
export function filterRecipes(rows: ContentRow[], f: RecipeFilters): ContentRow[] {
  const q = f.q.trim().toLowerCase();
  const band = recipeBands.find((b) => b.id === f.band);
  return rows.filter((r) => {
    const x = recipeFactsOf(r);
    return (
      tileMatch(r, f.tile) &&
      (!q ||
        [r.title.vi, r.title.en, r.id, ...x.ingredientNames].join(' ').toLowerCase().includes(q)) &&
      (!band || (!!x.ageMonths && bandOverlaps(band, x.ageMonths))) &&
      (f.texture === 'all' || x.texture === f.texture) &&
      (f.method === 'all' || x.methods.includes(f.method as (typeof recipeMethods)[number])) &&
      (f.status === 'all' || r.displayStatus === f.status)
    );
  });
}

export function RecipesBody({
  view,
  foods: foodRows,
  onOpen,
}: {
  view: ContentListView;
  /** The catalogue (allergens when the row does not send them). */
  foods: ContentRow[];
  onOpen: (id: string) => void;
}) {
  const intl = useIntl();
  const t = (id: string) => intl.formatMessage({ id });
  const [f, setF] = useState<RecipeFilters>(allRecipeFilters);
  const foods = useMemo(() => catalogueOf(foodRows), [foodRows]);
  const rows = filterRecipes(view.rows, f);
  const sorted = useSort(rows, {
    title: (r) => textOf(intl, r.title),
    age: (r) => recipeFactsOf(r).ageMonths?.from ?? null,
    minutes: (r) => recipeFactsOf(r).minutes,
    status: (r) => r.displayStatus,
    updated: (r) => r.updatedAt,
  });
  const grouped = sorted.rows === rows;
  const shown = useMemo(() => {
    if (!grouped) return rows;
    const key = (r: ContentRow) => {
      const a = recipeFactsOf(r).ageMonths;
      return a ? a.from * 100 + a.to : 99999;
    };
    return [...rows].sort((a, b) => key(a) - key(b));
  }, [grouped, rows]);
  const opt = <V extends string>(id: string, value: V) => ({ value, label: t(id) });
  const cols = 8;
  return (
    <div className="grid gap-4">
      <StatTiles items={contentTiles(view.counts, f.tile, (tile) => setF({ ...f, tile }))} />
      <RecipeCoverageCard
        bands={recipeCoverageOf(view)}
        onBand={(band) => setF({ ...allRecipeFilters, band })}
      />
      <div className="overflow-hidden rounded-xl border bg-card">
        <FilterBar
          active={JSON.stringify(f) !== JSON.stringify(allRecipeFilters)}
          onClear={() => setF(allRecipeFilters)}
          shown={rows.length}
          total={view.rows.length}
        >
          <SearchInput
            value={f.q}
            placeholder={t('solids.search.recipes')}
            onChange={(q) => setF({ ...f, q })}
          />
          <SelectMenu
            label={t('solids.filter.band')}
            value={f.band}
            onChange={(band) => setF({ ...f, band })}
            options={[
              opt('solids.filter.allBands', 'all'),
              ...recipeBands.map((b) => ({
                value: b.id,
                label: solidsMonthsText(intl, b),
              })),
            ]}
          />
          <SelectMenu
            label={t('solids.filter.texture')}
            value={f.texture}
            onChange={(texture) => setF({ ...f, texture })}
            options={[
              opt('solids.filter.allTextures', 'all'),
              ...textureStages.map((s) => opt(`solids.texture.${s}`, s)),
            ]}
          />
          <SelectMenu
            label={t('solids.filter.method')}
            value={f.method}
            onChange={(method) => setF({ ...f, method })}
            options={[
              opt('solids.filter.allMethods', 'all'),
              ...recipeMethods.map((m) => opt(`solids.method.${m}`, m)),
            ]}
          />
          <SelectMenu
            label={t('content.filter.status')}
            value={f.status}
            onChange={(status) => setF({ ...f, status })}
            options={statusOptions(intl)}
          />
        </FilterBar>
        {rows.length ? (
          <TableScroll min={1040}>
            <table className="table">
              <thead>
                <tr>
                  {sorted.th('title', <FormattedMessage id="solids.col.recipe" />)}
                  {sorted.th('age', <FormattedMessage id="solids.col.age" />)}
                  <th>
                    <FormattedMessage id="solids.col.texture" />
                  </th>
                  <th>
                    <FormattedMessage id="solids.col.methods" />
                  </th>
                  {sorted.th('minutes', <FormattedMessage id="solids.col.minutes" />)}
                  <th>
                    <FormattedMessage id="solids.col.allergens" />
                  </th>
                  {sorted.th('status', <FormattedMessage id="content.col.status" />)}
                  {sorted.th('updated', <FormattedMessage id="content.col.updated" />)}
                </tr>
              </thead>
              <tbody>
                {shown.map((r, i) => {
                  const x = recipeFactsOf(r);
                  const band = bandOf(x.ageMonths);
                  const prev = i > 0 ? bandOf(recipeFactsOf(shown[i - 1]!).ageMonths) : undefined;
                  const heading = grouped && (i === 0 || prev?.id !== band?.id);
                  const allergens = x.allergens ?? allergensOfFoods(x.foodIds, foods);
                  return (
                    <Fragment key={r.id}>
                      {heading && (
                        <GroupRow cols={cols}>
                          {band ? (
                            solidsMonthsText(intl, band)
                          ) : (
                            <FormattedMessage id="solids.band.unknown" />
                          )}
                        </GroupRow>
                      )}
                      <tr className="cl-row" onClick={() => onOpen(r.id)}>
                        <td className="max-w-[18rem]">
                          <TitleButton row={r} onOpen={onOpen} />
                          {x.servings !== null && (
                            <div className="mt-0.5 text-xs text-muted-foreground">
                              <FormattedMessage
                                id="solids.servingsCount"
                                values={{ n: x.servings }}
                              />
                            </div>
                          )}
                          {x.ageProblems > 0 && (
                            <span className="cl-tag mt-1 border-destructive px-2 py-0.5 text-xs text-destructive">
                              <FormattedMessage
                                id="solids.ageProblemsTag"
                                values={{ n: x.ageProblems }}
                              />
                            </span>
                          )}
                        </td>
                        <td className="nowrap">
                          {x.ageMonths ? solidsMonthsText(intl, x.ageMonths) : '—'}
                        </td>
                        <td className="nowrap">
                          {x.texture ? t(`solids.texture.${x.texture}`) : '—'}
                        </td>
                        <td>
                          <Tags items={x.methods.map((m) => t(`solids.method.${m}`))} />
                        </td>
                        <td className="nowrap tabular-nums">
                          {x.minutes !== null ? (
                            <FormattedMessage id="solids.minutes" values={{ n: x.minutes }} />
                          ) : (
                            '—'
                          )}
                        </td>
                        <td>
                          <Tags
                            items={allergens.map((a) => t(`solids.allergen.${a}`))}
                            tone="sunshine"
                          />
                        </td>
                        <td>
                          <StatusCell row={r} />
                        </td>
                        <UpdatedCell row={r} />
                      </tr>
                    </Fragment>
                  );
                })}
              </tbody>
            </table>
          </TableScroll>
        ) : (
          <EmptyState
            icon={Soup}
            title={
              <FormattedMessage
                id={view.rows.length ? 'content.noMatch' : 'solids.empty.recipes'}
              />
            }
          />
        )}
      </div>
      <Notice tone="warn">
        <FormattedMessage id="solids.note.recipes" />
      </Notice>
    </div>
  );
}

/** "Công thức theo độ tuổi": per band, how many (and on the app) against 6. */
export function RecipeCoverageCard({
  bands,
  onBand,
}: {
  bands: RecipeBandCoverage[];
  onBand?: (band: string) => void;
}) {
  const intl = useIntl();
  // The tile goes live once the first three bands each have the target on the app.
  const launch = bands.filter((b) => launchBands.includes(b.band.id));
  const short = launch.filter((b) => b.live < recipeTarget);
  const summary = (
    <FormattedMessage
      id="solids.coverage.recipesSummary"
      values={{ n: launch.length - short.length, total: launch.length, max: recipeTarget }}
    />
  );
  return (
    <Section
      title={<FormattedMessage id="solids.coverage.recipes" />}
      collapsible
      defaultOpen={short.length > 0}
      summary={summary}
      actions={<span className="text-sm font-medium tabular-nums">{summary}</span>}
    >
      <ul className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {bands.map(({ band, count, live }) => {
          const label = solidsMonthsText(intl, band);
          const ok = live >= recipeTarget;
          const body = (
            <>
              <span className="flex items-baseline justify-between gap-2">
                <span className="text-[13px] font-medium">{label}</span>
                <span
                  className={cn(
                    'text-lg font-semibold tabular-nums',
                    count < recipeTarget && 'text-destructive',
                  )}
                >
                  {count}/{recipeTarget}
                </span>
              </span>
              <span className="h-1.5 overflow-hidden rounded-full bg-muted" aria-hidden="true">
                <span
                  className={cn(
                    'block h-full rounded-full',
                    ok ? 'bg-primary' : 'bg-[var(--sunshine)]',
                  )}
                  style={{ width: `${Math.min(100, (live / recipeTarget) * 100)}%` }}
                />
              </span>
              <span className="text-xs text-muted-foreground">
                <FormattedMessage id="solids.coverage.bandLive" values={{ n: live }} />
                {!launchBands.includes(band.id) && (
                  <>
                    {' · '}
                    <FormattedMessage id="solids.coverage.optional" />
                  </>
                )}
              </span>
            </>
          );
          const base = 'grid w-full gap-1.5 rounded-lg border px-3 py-2 text-left';
          return (
            <li key={band.id}>
              {onBand ? (
                <button
                  type="button"
                  className={cn(base, 'transition-colors hover:border-primary/50')}
                  aria-label={intl.formatMessage({ id: 'solids.coverage.showBand' }, { label })}
                  onClick={() => onBand(band.id)}
                >
                  {body}
                </button>
              ) : (
                <div className={base}>{body}</div>
              )}
            </li>
          );
        })}
      </ul>
      <p className="mt-3 text-xs text-muted-foreground">
        <FormattedMessage id="solids.coverage.recipesHelp" values={{ n: recipeTarget }} />
      </p>
    </Section>
  );
}

// ---------- Hướng dẫn ----------

/** The Thư viện chăm bé articles with `library: 'solids'` (same list, same editor). */
export function GuidesBody({
  view,
  onOpen,
}: {
  view: ContentListView;
  onOpen: (id: string) => void;
}) {
  const rows = view.rows.filter((r) => r.library === 'solids');
  return (
    <div className="grid gap-4">
      <ArticlesBody view={{ ...view, rows, counts: countsOfRows(rows) }} onOpen={onOpen} />
      <Notice tone="info">
        <FormattedMessage id="solids.note.guides" />
      </Notice>
    </div>
  );
}
