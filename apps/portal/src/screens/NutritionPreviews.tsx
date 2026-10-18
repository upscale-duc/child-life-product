import {
  nutritionAgeContains,
  nutritionAgeLabel,
  type EditorialReview,
  type NumberRange,
  type NutrientDraft,
  type NutrientKey,
  type NutritionRuleDraft,
  type NutritionStageDraft,
  type SampleKind,
} from '@child-life/contracts';
import {
  Apple,
  Bone,
  ChevronRight,
  CircleAlert,
  Droplet,
  Fish,
  Heart,
  Leaf,
  Milk,
  Moon,
  Sparkles,
  Star,
  Sunrise,
  Waves,
  Wheat,
  type LucideIcon,
} from 'lucide-react';
import type { ReactNode } from 'react';
import { useIntl } from 'react-intl';
import { cn } from '@/lib/utils';
import {
  PhoneFrame,
  ReviewLine,
  useContentList,
  type ContentRow,
  type Lang,
  type Loc,
} from './content-common';
import {
  ageRangeOk,
  nextRound,
  rangeText,
  roundText,
  roundsOf,
  sampleMonths,
  withName,
} from './nutrition-common';

/**
 * Phone previews of the Dinh dưỡng content (Figma app 9b, 9d, 9e) for the sample baby "Teddy", in
 * the language being edited. They show what the expert writes; the personal cards (the 7-day milk
 * average, growth) use sample numbers.
 */

type Review = EditorialReview | null;

const muted = 'text-[var(--ink-muted)]';

function usePreviewText(lang: Lang) {
  const intl = useIntl();
  return (id: string, values?: Record<string, string | number>) =>
    intl.formatMessage({ id: `nutrition.preview.${id}.${lang}` }, values);
}

function monthsIn(intl: ReturnType<typeof useIntl>, lang: Lang, age: { from: number; to: number }) {
  const l = nutritionAgeLabel(age);
  return intl.formatMessage({ id: `content.preview.months.${lang}` }, { from: l.from, to: l.to });
}

const keyLook: Record<NutrientKey, { bg: string; fg: string; Icon: LucideIcon }> = {
  iron: { bg: 'var(--care-pump-soft)', fg: 'var(--care-pump-ink)', Icon: Droplet },
  zinc: { bg: 'var(--care-sleep-soft)', fg: 'var(--care-sleep-ink)', Icon: Star },
  vitaminD: { bg: 'var(--care-bottle-soft)', fg: 'var(--care-bottle-ink)', Icon: Sunrise },
  // Soft warm fills take ink (Night care).
  vitaminA: { bg: 'var(--peach-soft)', fg: 'var(--ink)', Icon: Heart },
  calcium: { bg: 'var(--mint-soft)', fg: 'var(--mint-text)', Icon: Bone },
  dha: { bg: 'var(--care-bottle-soft)', fg: 'var(--care-bottle-ink)', Icon: Fish },
  iodine: { bg: 'var(--sunshine-soft)', fg: 'var(--ink)', Icon: Waves },
  fibre: { bg: 'var(--mint-soft)', fg: 'var(--mint-text)', Icon: Wheat },
  other: { bg: 'var(--surface-2)', fg: 'var(--ink-muted)', Icon: Leaf },
};

export function NutrientChip({ nutrientKey, large }: { nutrientKey: unknown; large?: boolean }) {
  const look = keyLook[nutrientKey as NutrientKey] ?? keyLook.other;
  return (
    <span
      className={cn(
        'grid shrink-0 place-items-center',
        large ? 'size-14 rounded-[18px]' : 'size-[34px] rounded-xl',
      )}
      style={{ background: look.bg, color: look.fg }}
      aria-hidden="true"
    >
      <look.Icon className={large ? 'size-7' : 'size-4'} />
    </span>
  );
}

const kindIcon: Record<SampleKind, LucideIcon> = {
  milk: Milk,
  solids: Sparkles,
  snack: Apple,
  sleep: Moon,
};

function Heading({ children }: { children: ReactNode }) {
  return <h4 className="m-0 text-[15px] font-bold">{children}</h4>;
}

/** 9b "Sữa mỗi ngày": the reference band, with a marker at the sample average. */
export function MilkBand({ range, value }: { range: NumberRange; value: number | null }) {
  const top = Math.max(1100, Math.ceil((range.max * 1.25) / 100) * 100);
  const at = (n: number) => `${Math.min(100, Math.max(0, (n / top) * 100))}%`;
  return (
    <div className="relative mx-2 mt-6 mb-6 h-2.5 rounded-full bg-[var(--surface-2)]">
      <div
        className="absolute inset-y-0 rounded-full border border-[var(--care-bottle-accent)] bg-[var(--care-bottle-soft)]"
        style={{
          left: at(range.min),
          width: `${(Math.max(0, range.max - range.min) / top) * 100}%`,
        }}
      />
      {value !== null && (
        <>
          <span
            className="absolute top-1/2 size-4 -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-[var(--surface)] bg-[var(--care-bottle-accent)]"
            style={{ left: at(value) }}
          />
          <span
            className="absolute -top-5 -translate-x-1/2 text-[11px] font-bold whitespace-nowrap text-[var(--care-bottle-ink)]"
            style={{ left: at(value) }}
          >
            {value} ml
          </span>
        </>
      )}
      <span
        className={cn('absolute top-4 -translate-x-1/2 text-[11px] whitespace-nowrap', muted)}
        style={{ left: at(range.min) }}
      >
        {range.min}
      </span>
      <span
        className={cn('absolute top-4 -translate-x-1/2 text-[11px] whitespace-nowrap', muted)}
        style={{ left: at(range.max) }}
      >
        {range.max} ml
      </span>
    </div>
  );
}

/** A sample 7-day average inside the band (720 for 600–900, as 9b draws it). */
const sampleAverage = (r: NumberRange) => Math.round((r.min + (r.max - r.min) * 0.4) / 10) * 10;

// ---------- 9b stage ----------

export function NutritionStagePreview({
  data,
  lang,
  nutrients,
  review,
  today,
}: {
  data: NutritionStageDraft;
  lang: Lang;
  /** The micronutrient list rows (names, keys, campaign rounds). */
  nutrients: ContentRow[];
  review: Review;
  today: string;
}) {
  const intl = useIntl();
  const p = usePreviewText(lang);
  const age = ageRangeOk(data.ageMonths) ? data.ageMonths : null;
  const milk = data.milk;
  const perDay = milk?.perDayMl ?? null;
  const avg = perDay ? sampleAverage(perDay) : null;
  const feedsPart = [
    milk?.feedsPerDay ? p('feeds', { range: rangeText(intl, milk.feedsPerDay) }) : null,
    milk?.perFeedMl ? p('perFeed', { range: rangeText(intl, milk.perFeedMl) }) : null,
  ]
    .filter(Boolean)
    .join(', ');
  const note = milk?.breastfeedingNote?.[lang]?.trim();
  const milkLine = [avg !== null ? p('milkAvg', { n: avg }) : null, feedsPart || null]
    .filter(Boolean)
    .join(' · ');
  const milkText = note
    ? `${milkLine ? `${milkLine}. ` : ''}${p('breastfeeding', { note })}`
    : milkLine;
  const nutrientIds = data.nutrientIds ?? [];
  const sampleDay = data.sampleDay ?? [];
  const tips = data.tips ?? [];
  return (
    <PhoneFrame>
      <div className="cl-phone__body">
        <h3 className="cl-phone__title">{p('title')}</h3>
        <div className="grid gap-2 rounded-3xl bg-[var(--care-growth-soft)] p-4">
          <span className="text-[13px] font-semibold text-[var(--care-growth-ink)]">
            {age ? p('stageLine', { n: sampleMonths(age), label: monthsIn(intl, lang, age) }) : '—'}
          </span>
          <strong className="text-2xl leading-tight font-bold">{data.title?.[lang] || '—'}</strong>
          {data.summary?.[lang] && (
            <p className="m-0 text-sm leading-normal">{data.summary[lang]}</p>
          )}
          <span className="text-[13px] font-semibold text-[var(--mint-text)]">
            {p('seeStages')}
          </span>
        </div>
        {milk && (
          <div className="cl-phone__card grid gap-2">
            <div className="flex items-center gap-2.5">
              <span className="grid size-[34px] shrink-0 place-items-center rounded-xl bg-[var(--care-bottle-soft)] text-[var(--care-bottle-ink)]">
                <Milk className="size-4" aria-hidden="true" />
              </span>
              <span className="grid min-w-0 flex-1">
                <strong className="text-base">{p('milkTitle')}</strong>
                <span className={cn('text-xs', muted)}>{p('milkSub')}</span>
              </span>
              <ChevronRight className={cn('size-4', muted)} aria-hidden="true" />
            </div>
            {perDay && <MilkBand range={perDay} value={avg} />}
            {milkText && <p className={cn('m-0 text-[13px]', muted)}>{milkText}</p>}
          </div>
        )}
        {nutrientIds.length > 0 && (
          <section className="grid gap-2">
            <Heading>{p('nutrients')}</Heading>
            <div className="cl-phone__card grid divide-y divide-[var(--separator)] p-0">
              {nutrientIds.map((id) => {
                const r = nutrients.find((x) => x.id === id);
                const rounds = roundsOf(r?.rounds);
                const next = rounds.length ? nextRound(rounds, today) : null;
                const name = r ? (r.title as Loc)[lang] || r.title.vi : id;
                return (
                  <div key={id} className="flex items-center gap-3 px-3.5 py-2.5">
                    <NutrientChip nutrientKey={r?.key} />
                    <span className="min-w-0 flex-1 truncate text-[15px] font-semibold">
                      {name}
                    </span>
                    {next && (
                      <span className="cl-tag cl-tag--sunshine px-2 py-0.5 text-[11px] font-bold">
                        {roundText(next)}
                      </span>
                    )}
                    <ChevronRight className={cn('size-4', muted)} aria-hidden="true" />
                  </div>
                );
              })}
            </div>
          </section>
        )}
        {sampleDay.length > 0 && (
          <section className="grid gap-2">
            <Heading>{p('sampleDay')}</Heading>
            <div className="cl-phone__card grid divide-y divide-[var(--separator)] p-0">
              {sampleDay.map((s, i) => {
                const Icon = kindIcon[s.kind] ?? Sparkles;
                return (
                  <div key={i} className="flex items-center gap-3 px-3.5 py-2.5">
                    <span className="grid size-[34px] shrink-0 place-items-center rounded-xl bg-[var(--surface-2)]">
                      <Icon className="size-4" aria-hidden="true" />
                    </span>
                    <span className="grid min-w-0">
                      <strong className="text-sm">{p(`slot.${s.slot}`)}</strong>
                      <span className={cn('text-xs', muted)}>{s.text?.[lang] || '—'}</span>
                    </span>
                  </div>
                );
              })}
            </div>
          </section>
        )}
        {tips.length > 0 && (
          <section className="grid gap-2">
            <Heading>{p('tips')}</Heading>
            {tips.map((t, i) => (
              <div key={i} className="rounded-[20px] bg-[var(--mint-soft)] px-4 py-3">
                <strong className="block text-[15px] text-[var(--mint-text)]">
                  {t.title?.[lang] || '—'}
                </strong>
                {t.body?.[lang] && <p className="m-0 mt-1 text-[13px]">{t.body[lang]}</p>}
              </div>
            ))}
          </section>
        )}
        <ReviewLine review={review} lang={lang} />
        <p className="cl-foot">{p('footer')}</p>
      </div>
    </PhoneFrame>
  );
}

/** The 9b preview in the review queue: it loads the micronutrient names itself. */
export function NutritionStagePreviewLoaded(
  props: Omit<Parameters<typeof NutritionStagePreview>[0], 'nutrients'>,
) {
  const [load] = useContentList('nutrient');
  return (
    <NutritionStagePreview {...props} nutrients={load.status === 'ok' ? load.data.rows : []} />
  );
}

// ---------- 9d micronutrient ----------

export function NutrientPreview({
  data,
  lang,
  review,
}: {
  data: NutrientDraft;
  lang: Lang;
  review: Review;
}) {
  const intl = useIntl();
  const p = usePreviewText(lang);
  const focusAge = ageRangeOk(data.focus?.ageMonths ?? { from: 0, to: 0 })
    ? data.focus.ageMonths
    : null;
  const teddy = focusAge ? sampleMonths(focusAge) : null;
  const foods = (data.foods ?? []).map((f) => f[lang]).filter(Boolean);
  const sources = (data.sources ?? []).map((s) => s.label).filter(Boolean);
  const campaign = data.campaign;
  return (
    <PhoneFrame>
      <div className="cl-phone__body">
        <div className="flex items-center gap-3.5">
          <NutrientChip nutrientKey={data.key} large />
          <div className="grid min-w-0">
            <h3 className="cl-phone__title">{data.name?.[lang] || '—'}</h3>
            {data.focus?.label?.[lang] && (
              <span className={cn('text-sm', muted)}>{data.focus.label[lang]}</span>
            )}
          </div>
        </div>
        {data.why?.[lang] && (
          <div className="cl-phone__card">
            <strong>{p('why')}</strong>
            <p>{data.why[lang]}</p>
          </div>
        )}
        {foods.length > 0 && (
          <section className="grid gap-2">
            <Heading>{p('foods')}</Heading>
            <div className="flex flex-wrap gap-1.5">
              {foods.map((f, i) => (
                <span key={i} className="cl-tag bg-[var(--surface)]">
                  {f}
                </span>
              ))}
            </div>
          </section>
        )}
        {data.tip?.[lang] && (
          <div className="cl-callout cl-callout--tip">
            <strong>{p('tip')}</strong>
            <p>{data.tip[lang]}</p>
          </div>
        )}
        {(data.byAge ?? []).length > 0 && (
          <section className="grid gap-2">
            <Heading>{p('byAge')}</Heading>
            <div className="cl-phone__card grid divide-y divide-[var(--separator)] p-0">
              {data.byAge.map((b, i) => {
                const here =
                  teddy !== null &&
                  !!b.ageMonths &&
                  ageRangeOk(b.ageMonths) &&
                  nutritionAgeContains(b.ageMonths, teddy);
                return (
                  <div
                    key={i}
                    className={cn(
                      'grid grid-cols-[6rem_minmax(0,1fr)] gap-3 px-3.5 py-2.5 text-[13px]',
                      here && 'bg-[var(--care-growth-soft)]',
                    )}
                  >
                    <strong>{b.label?.[lang] || '—'}</strong>
                    <span>{b.text?.[lang]}</span>
                  </div>
                );
              })}
            </div>
          </section>
        )}
        {campaign && (
          <div className="cl-phone__card text-[13px]">
            {p('campaign', {
              place: campaign.place?.[lang] || '—',
              rounds: (campaign.rounds ?? []).map(roundText).join(', ') || '—',
              age: ageRangeOk(campaign.ageMonths) ? monthsIn(intl, lang, campaign.ageMonths) : '—',
            })}
          </div>
        )}
        {data.warning?.[lang] && (
          <div className="cl-callout cl-callout--doctor flex gap-2">
            <CircleAlert className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
            <span className="text-sm">{data.warning[lang]}</span>
          </div>
        )}
        <ReviewLine review={review} lang={lang} />
        {sources.length > 0 && (
          <p className="cl-foot">{p('sources', { list: sources.join(', ') })}</p>
        )}
      </div>
    </PhoneFrame>
  );
}

// ---------- 9e rule ----------

/** A WHO-style sketch: the normal band, the median, and Teddy's line leaving the band. */
function GrowthSketch({ above }: { above: boolean }) {
  const line = above
    ? '10,74 60,66 110,57 160,45 210,32 260,14'
    : '10,84 60,82 110,83 160,85 210,89 260,94';
  return (
    <svg viewBox="0 0 300 120" className="h-auto w-full" aria-hidden="true">
      <polygon points="0,60 300,15 300,65 0,100" fill="var(--mint-soft)" />
      <polyline
        points="0,80 300,40"
        fill="none"
        stroke="var(--mint-deep)"
        strokeDasharray="5 4"
        strokeWidth="1.5"
      />
      <polyline
        points={line}
        fill="none"
        stroke="var(--care-bottle-accent)"
        strokeWidth="2.5"
        strokeLinejoin="round"
      />
      {line.split(' ').map((pt) => {
        const [x, y] = pt.split(',');
        return <circle key={pt} cx={x} cy={y} r="3.5" fill="var(--care-bottle-accent)" />;
      })}
    </svg>
  );
}

export function NutritionRulePreview({ data, lang }: { data: NutritionRuleDraft; lang: Lang }) {
  const p = usePreviewText(lang);
  const banner = withName(data.banner?.[lang] ?? '');
  const tips = data.tips ?? [];
  const growth = data.metric === 'weight' || data.metric === 'length';
  const bannerCard = banner && (
    <div className="cl-callout cl-callout--doctor flex gap-2">
      <CircleAlert className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
      <span className="text-sm">{banner}</span>
    </div>
  );
  const tipList = tips.length > 0 && (
    <section className="grid gap-2">
      <Heading>{p(growth ? 'waitTips' : 'otherTips')}</Heading>
      <div className="cl-phone__card grid divide-y divide-[var(--separator)] p-0">
        {tips.map((t, i) => (
          <div key={i} className="flex gap-3 px-3.5 py-2.5">
            <span
              className="mt-1.5 size-2 shrink-0 rounded-full bg-[var(--mint-deep)]"
              aria-hidden="true"
            />
            <span className="grid min-w-0">
              <strong className="text-sm">{withName(t.title?.[lang] ?? '') || '—'}</strong>
              <span className={cn('text-xs', muted)}>{withName(t.body?.[lang] ?? '')}</span>
            </span>
          </div>
        ))}
      </div>
    </section>
  );
  const buttons = (data.remindAfterDays !== null || data.export) && (
    <div className="grid gap-2">
      {data.remindAfterDays !== null && (
        <span className="block rounded-2xl bg-[var(--mint-deep)] py-3 text-center text-sm font-semibold text-[var(--on-mint-deep)]">
          {p('remind', { n: data.remindAfterDays })}
        </span>
      )}
      {data.export && (
        <span className="block rounded-2xl border border-[var(--separator)] bg-[var(--surface)] py-3 text-center text-sm font-semibold">
          {p('export')}
        </span>
      )}
    </div>
  );
  return (
    <PhoneFrame>
      <div className="cl-phone__body">
        {growth ? (
          <>
            <h3 className="cl-phone__title">
              {p(data.metric === 'weight' ? 'weightOf' : 'lengthOf')}
            </h3>
            <div className="cl-phone__card grid gap-2">
              <strong className="text-sm">{p('whoChart')}</strong>
              <GrowthSketch above={data.condition === 'aboveRange'} />
              <span className={cn('flex items-center gap-1.5 text-xs', muted)}>
                <span className="size-2.5 rounded-sm bg-[var(--mint-soft)]" aria-hidden="true" />
                {p('normalRange')}
                <span
                  className="ml-3 h-0.5 w-4 rounded bg-[var(--care-bottle-accent)]"
                  aria-hidden="true"
                />
                Teddy
              </span>
            </div>
            {bannerCard}
            {tipList}
            {buttons}
            <p className="cl-foot">{p('ruleFooter')}</p>
          </>
        ) : data.metric === 'milk' ? (
          <>
            <h3 className="cl-phone__title">{p('title')}</h3>
            <p className={cn('m-0 text-xs', muted)}>{p('whereMilk')}</p>
            <div className="cl-phone__card grid gap-2">
              <div className="flex items-center gap-2.5">
                <span className="grid size-[34px] shrink-0 place-items-center rounded-xl bg-[var(--care-bottle-soft)] text-[var(--care-bottle-ink)]">
                  <Milk className="size-4" aria-hidden="true" />
                </span>
                <strong className="text-base">{p('milkTitle')}</strong>
              </div>
              <MilkBand range={{ min: 600, max: 900 }} value={1000} />
              {banner && <p className={cn('m-0 text-[13px]', muted)}>{banner}</p>}
            </div>
            {tipList}
            {buttons}
          </>
        ) : (
          <>
            <h3 className="cl-phone__title">{p('title')}</h3>
            <p className={cn('m-0 text-xs', muted)}>{p('whereStage')}</p>
            {bannerCard}
            {tipList}
            {buttons}
          </>
        )}
      </div>
    </PhoneFrame>
  );
}
