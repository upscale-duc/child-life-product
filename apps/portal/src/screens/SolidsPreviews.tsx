import {
  nutritionAgeLabel,
  recipeAllergens,
  type EditorialReview,
  type FoodDraft,
  type RecipeDraft,
} from '@child-life/contracts';
import {
  Bookmark,
  Check,
  ChevronRight,
  CircleAlert,
  Clock,
  Heart,
  Soup,
  Sparkles,
  type LucideIcon,
} from 'lucide-react';
import type { ReactNode } from 'react';
import { useIntl } from 'react-intl';
import { cn } from '@/lib/utils';
import { ImageThumb, PhoneFrame, ReviewLine, useContentList, type Lang } from './content-common';
import { catalogueOf, solidsAgeOf, type CatalogueFood } from './solids-common';

/**
 * Phone previews of the Ăn dặm content (Figma app 5e, 5g; plan §5, P-164 #14) for the sample baby
 * "Teddy", in the language being edited: a food as its 5e "Món đã thử" row and its food detail, a
 * recipe as 5g (ingredients with quantities, steps, the allergen line and the D-082 footnote). The
 * personal parts (first tried, times, reaction) use sample values.
 */

type Review = EditorialReview | null;

const muted = 'text-[var(--ink-muted)]';

function usePreviewText(lang: Lang) {
  const intl = useIntl();
  return (id: string, values?: Record<string, string | number>) =>
    intl.formatMessage({ id: `solids.preview.${id}.${lang}` }, values);
}

function Heading({ children }: { children: ReactNode }) {
  return <h4 className="m-0 text-[17px] font-bold">{children}</h4>;
}

function Chip({
  children,
  tone = 'plain',
  icon: Icon,
}: {
  children: ReactNode;
  tone?: 'plain' | 'bottle' | 'mint' | 'sunshine';
  icon?: LucideIcon;
}) {
  const look = {
    plain: 'bg-[var(--surface-2)] text-[var(--ink)]',
    bottle: 'bg-[var(--care-bottle-soft)] text-[var(--care-bottle-ink)]',
    mint: 'bg-[var(--mint-soft)] text-[var(--mint-text)]',
    // Soft warm fills take ink (Night care).
    sunshine: 'bg-[var(--sunshine-soft)] text-[var(--ink)]',
  }[tone];
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[12px] font-semibold',
        look,
      )}
    >
      {Icon && <Icon className="size-3" aria-hidden="true" />}
      {children}
    </span>
  );
}

const sourcesLine = (sources: Array<{ label: string }> | undefined) =>
  (sources ?? []).map((s) => s.label).filter(Boolean);

// ---------- 5e row and food detail ----------

export function FoodPreview({
  data,
  lang,
  review,
}: {
  data: FoodDraft;
  lang: Lang;
  review: Review;
}) {
  const p = usePreviewText(lang);
  const name = data.name?.[lang] || '—';
  const group = data.group ? p(`group.${data.group}`) : null;
  const prep = (data.prep ?? []).filter((x) => x.text?.[lang]);
  const choking = data.chokingNote?.[lang];
  const sources = sourcesLine(data.sources);
  return (
    <PhoneFrame>
      <div className="cl-phone__body">
        <h3 className="cl-phone__title">{p('tried')}</h3>
        <div className="flex flex-wrap gap-1.5">
          <span className="rounded-full bg-[var(--ink)] px-3 py-1 text-[12px] font-semibold text-[var(--surface)]">
            {p('all', { n: 1 })}
          </span>
          {group && (
            <span className="rounded-full border border-[var(--separator)] bg-[var(--surface)] px-3 py-1 text-[12px] font-semibold">
              {group} · 1
            </span>
          )}
        </div>
        <div className="cl-phone__card flex items-center gap-3">
          <span className="grid min-w-0 flex-1">
            <strong className="truncate text-[15px]">{name}</strong>
            <span className={cn('text-xs', muted)}>{p('firstTried')}</span>
          </span>
          <Chip tone="mint">{p('liked')}</Chip>
          <ChevronRight className={cn('size-4', muted)} aria-hidden="true" />
        </div>
        <p className={cn('m-0 text-xs', muted)}>{p('familyRecord')}</p>
        <section className="grid gap-2 border-t border-[var(--separator)] pt-3">
          <span className={cn('text-[11px] font-semibold uppercase', muted)}>{p('detail')}</span>
          <h3 className="cl-phone__title">{name}</h3>
          <div className="flex flex-wrap gap-1.5">
            {group && <Chip>{group}</Chip>}
            {typeof data.minAgeMonths === 'number' && (
              <Chip>{p('fromMonths', { n: data.minAgeMonths })}</Chip>
            )}
            {data.ironRich && <Chip tone="bottle">{p('ironRich')}</Chip>}
            {data.allergen && (
              <Chip tone="sunshine" icon={CircleAlert}>
                {p('allergen', { name: p(`allergen.${data.allergen}`) })}
              </Chip>
            )}
          </div>
          <div className="cl-phone__card text-[13px]">{p('sampleHistory')}</div>
          {prep.length > 0 && (
            <>
              <Heading>{p('prep')}</Heading>
              <div className="cl-phone__card grid divide-y divide-[var(--separator)] p-0">
                {prep.map((x, i) => (
                  <div key={i} className="grid gap-0.5 px-3.5 py-2.5">
                    <strong className="text-sm">{p(`texture.${x.texture}`)}</strong>
                    <span className="text-[13px]">{x.text[lang]}</span>
                  </div>
                ))}
              </div>
            </>
          )}
          {choking && (
            <div className="cl-callout cl-callout--doctor flex gap-2">
              <CircleAlert className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
              <span className="text-sm">{choking}</span>
            </div>
          )}
          <span className="block rounded-2xl border border-[var(--separator)] bg-[var(--surface)] py-3 text-center text-sm font-semibold">
            {p('hide')}
          </span>
          <ReviewLine review={review} lang={lang} />
          {sources.length > 0 && (
            <p className="cl-foot">{p('sources', { list: sources.join(', ') })}</p>
          )}
        </section>
      </div>
    </PhoneFrame>
  );
}

// ---------- 5g recipe ----------

function qtyText(
  p: ReturnType<typeof usePreviewText>,
  qty: number | null,
  unit: RecipeDraft['ingredients'][number]['unit'],
) {
  if (qty === null || !Number.isFinite(qty)) return unit ? p(`unit.${unit}`) : '';
  return unit ? `${qty} ${p(`unit.${unit}`)}` : String(qty);
}

export function RecipePreview({
  data,
  lang,
  review,
  foods,
}: {
  data: RecipeDraft;
  lang: Lang;
  review: Review;
  /** The catalogue (allergens). */
  foods: ReadonlyMap<string, CatalogueFood>;
}) {
  const intl = useIntl();
  const p = usePreviewText(lang);
  const age = solidsAgeOf(data.ageMonths);
  const ageLabel = age
    ? intl.formatMessage(
        { id: `content.preview.months.${lang}` },
        { from: nutritionAgeLabel(age).from, to: nutritionAgeLabel(age).to },
      )
    : null;
  const prep = Number.isFinite(data.prepMinutes) ? data.prepMinutes : 0;
  const cook = Number.isFinite(data.cookMinutes) ? data.cookMinutes : 0;
  const minutes = prep + cook;
  const ingredients = (data.ingredients ?? []).filter((i) => i.name?.[lang] || i.foodId);
  const steps = (data.steps?.[lang] ?? []).filter((s) => s.trim());
  const allergens = recipeAllergens({ ingredients: data.ingredients ?? [] }, foods);
  const sources = sourcesLine(data.sources);
  const nameOf = (i: RecipeDraft['ingredients'][number]) =>
    i.name?.[lang] || (i.foodId ? (foods.get(i.foodId)?.name[lang] ?? i.foodId) : '—');
  return (
    <PhoneFrame>
      <div className="cl-phone__body">
        {data.cover ? (
          <ImageThumb id={data.cover.image} size={300} />
        ) : (
          <div
            className="grid h-[150px] place-items-center rounded-[22px] bg-[var(--sunshine-soft)] text-[var(--ink)]"
            aria-hidden="true"
          >
            <Soup className="size-10" />
          </div>
        )}
        <div className="flex flex-wrap gap-1.5">
          <Chip tone="bottle">{p('recipe')}</Chip>
          {ageLabel && <Chip>{ageLabel}</Chip>}
          {minutes > 0 && <Chip icon={Clock}>{p('minutes', { n: minutes })}</Chip>}
          {data.texture && <Chip>{p(`texture.${data.texture}`)}</Chip>}
          {(data.methods ?? []).map((m) => (
            <Chip key={m}>{p(`method.${m}`)}</Chip>
          ))}
        </div>
        <h3 className="m-0 text-[26px] leading-tight font-bold">{data.title?.[lang] || '—'}</h3>
        {data.summary?.[lang] && <p className="m-0 text-sm">{data.summary[lang]}</p>}
        <div className="cl-phone__card grid gap-2">
          <div className="flex items-baseline justify-between gap-2">
            <Heading>{p('ingredients')}</Heading>
            {data.servings > 0 && (
              <span className={cn('text-xs', muted)}>{p('servings', { n: data.servings })}</span>
            )}
          </div>
          {ingredients.length ? (
            ingredients.map((i, n) => (
              <div key={n} className="flex items-start gap-2 text-[15px] font-medium">
                <Check
                  className="mt-1 size-3.5 shrink-0 text-[var(--mint-text)]"
                  aria-hidden="true"
                />
                <span className="grid min-w-0 flex-1">
                  <span>{nameOf(i)}</span>
                  {i.note?.[lang] && (
                    <span className={cn('text-xs font-normal', muted)}>{i.note[lang]}</span>
                  )}
                </span>
                <span className={cn('shrink-0 text-[13px] tabular-nums', muted)}>
                  {qtyText(p, i.qty, i.unit)}
                </span>
              </div>
            ))
          ) : (
            <span className={cn('text-sm', muted)}>—</span>
          )}
        </div>
        {allergens.length > 0 && (
          <div className="flex gap-2 rounded-2xl bg-[var(--sunshine-soft)] px-3.5 py-2.5 text-[13px] font-semibold text-[var(--ink)]">
            <CircleAlert className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
            {p('contains', {
              list: allergens.map((a) => p(`allergen.${a}`)).join(', '),
            })}
          </div>
        )}
        {steps.length > 0 && (
          <section className="grid gap-2">
            <h4 className="m-0 text-[19px] font-bold">{p('steps')}</h4>
            <ol className="m-0 grid list-none gap-2.5 p-0">
              {steps.map((s, i) => (
                <li key={i} className="flex gap-2.5 text-[15px] leading-normal">
                  <span className="h-fit shrink-0 rounded-full bg-[var(--mint-soft)] px-2 py-0.5 text-[13px] font-bold text-[var(--mint-text)]">
                    {i + 1}
                  </span>
                  <span>{s}</span>
                </li>
              ))}
            </ol>
          </section>
        )}
        {data.storage?.[lang] && (
          <div className="cl-phone__card">
            <strong>{p('storage')}</strong>
            <p>{data.storage[lang]}</p>
          </div>
        )}
        {data.tip?.[lang] && (
          <div className="cl-callout cl-callout--tip">
            <strong>{p('tip')}</strong>
            <p>{data.tip[lang]}</p>
          </div>
        )}
        <div className="flex gap-2 rounded-2xl bg-[var(--surface-2)] px-3.5 py-2.5">
          <Heart className={cn('mt-0.5 size-4 shrink-0', muted)} aria-hidden="true" />
          <span className={cn('text-[13px] font-medium', muted)}>{p('everyBaby')}</span>
        </div>
        <ReviewLine review={review} lang={lang} />
        {sources.length > 0 && (
          <p className="cl-foot">{p('sources', { list: sources.join(', ') })}</p>
        )}
        <div className="flex gap-2">
          <span className="inline-flex items-center gap-1.5 rounded-2xl border border-[var(--separator)] bg-[var(--surface)] px-4 py-3 text-sm font-semibold">
            <Bookmark className="size-4" aria-hidden="true" />
            {p('save')}
          </span>
          <span className="flex flex-1 items-center justify-center gap-1.5 rounded-2xl bg-[var(--mint-deep)] py-3 text-sm font-semibold text-[var(--on-mint-deep)]">
            <Sparkles className="size-4" aria-hidden="true" />
            {p('log')}
          </span>
        </div>
      </div>
    </PhoneFrame>
  );
}

/** The 5g preview in the review queue: it loads the catalogue itself. */
export function RecipePreviewLoaded(props: Omit<Parameters<typeof RecipePreview>[0], 'foods'>) {
  const [load] = useContentList('food');
  return (
    <RecipePreview {...props} foods={catalogueOf(load.status === 'ok' ? load.data.rows : [])} />
  );
}
