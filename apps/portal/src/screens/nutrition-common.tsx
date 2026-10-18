import {
  addMonthsIso,
  nutritionAgeLabel,
  nutritionAgeSchema,
  nutritionAgesOverlap,
  nutritionGaps,
  nutritionLimits,
  sortNutritionStages,
  type ContentKind,
  type CopyProblem,
  type NumberRange,
  type NutrientRound,
  type NutritionAge,
} from '@child-life/contracts';
import { Plus } from 'lucide-react';
import { useId, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { Badge } from '@/components/ui/badge';
import { Button as UiButton } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { cn } from '@/lib/utils';
import type { ApiError } from '../api';
import { Field, Hint, Notice } from '../content-kit';
import { routePaths } from '../context';
import { errorMessageId } from '../ui';
import { TextField, type ContentRow, type Lang, type Loc, type ParseIssue } from './content-common';
import { FieldSelect, IconButton } from './form-controls';

/**
 * Shared pieces of the Dinh dưỡng screens (D-083, P-163; Figma portal D01–D04; plan
 * `docs/product/nutrition-plan.md` §3, §5): addresses, reading the list rows defensively (the
 * server adds the kind's fields to each row), labels, the 0–36 month coverage, the month-range and
 * amount fields, list editors, and the copy check that blocks "Gửi duyệt" (P-163 #16).
 */

const N = nutritionLimits;

// ---------- Kinds and addresses ----------

export type NutritionKind = Extract<ContentKind, 'nutritionStage' | 'nutrient' | 'nutritionRule'>;
export type NutritionTab = 'stages' | 'nutrients' | 'rules';
export const nutritionTabs: readonly NutritionTab[] = ['stages', 'nutrients', 'rules'];
export const tabKind: Record<NutritionTab, NutritionKind> = {
  stages: 'nutritionStage',
  nutrients: 'nutrient',
  rules: 'nutritionRule',
};
export const kindTab: Record<NutritionKind, NutritionTab> = {
  nutritionStage: 'stages',
  nutrient: 'nutrients',
  nutritionRule: 'rules',
};
export const isNutritionKind = (k: ContentKind): k is NutritionKind => k in kindTab;

/**
 * "/nutrition" (stages), "/nutrition/nutrients", "/nutrition/rules/nru_x",
 * "/nutrition/stages/new/9-12" (a new stage over a gap). `id` undefined = the list, null = new.
 */
export type NutritionPath = { tab: NutritionTab; id?: string | null; range?: NutritionAge | null };

export function nutritionPathOf(segments: string[]): NutritionPath {
  const first = segments[0] ?? '';
  const tab = (nutritionTabs as readonly string[]).includes(first)
    ? (first as NutritionTab)
    : 'stages';
  const id = segments[1];
  if (!id) return { tab };
  if (id !== 'new') return { tab, id };
  const m = /^(\d+)-(\d+)$/.exec(segments[2] ?? '');
  const range = tab === 'stages' && m ? ageOf({ from: Number(m[1]), to: Number(m[2]) }) : null;
  return { tab, id: null, range };
}

export function nutritionUrl(p: NutritionPath): string {
  const base = routePaths.nutrition;
  if (p.id === undefined) return p.tab === 'stages' ? base : `${base}/${p.tab}`;
  if (p.id === null) {
    return `${base}/${p.tab}/new${p.range ? `/${p.range.from}-${p.range.to}` : ''}`;
  }
  return `${base}/${p.tab}/${encodeURIComponent(p.id)}`;
}

export const nutritionEditorUrl = (kind: NutritionKind, id: string) =>
  nutritionUrl({ tab: kindTab[kind], id });

// ---------- Reading rows and drafts defensively ----------

export function ageOf(v: unknown): NutritionAge | null {
  const r = nutritionAgeSchema.safeParse(v);
  return r.success ? r.data : null;
}

export function rangeOf(v: unknown): NumberRange | null {
  const r = v as { min?: unknown; max?: unknown } | null | undefined;
  return r && typeof r.min === 'number' && typeof r.max === 'number'
    ? { min: r.min, max: r.max }
    : null;
}

export function locOf(v: unknown): Loc | null {
  const o = v as { vi?: unknown; en?: unknown } | null | undefined;
  if (!o || typeof o !== 'object') return null;
  return {
    vi: typeof o.vi === 'string' ? o.vi : '',
    en: typeof o.en === 'string' ? o.en : '',
  };
}

export type MilkRow = {
  perFeedMl: NumberRange | null;
  feedsPerDay: NumberRange | null;
  perDayMl: NumberRange | null;
};

export function milkOf(v: unknown): MilkRow | null {
  const m = v as Record<string, unknown> | null | undefined;
  if (!m || typeof m !== 'object') return null;
  return {
    perFeedMl: rangeOf(m.perFeedMl),
    feedsPerDay: rangeOf(m.feedsPerDay),
    perDayMl: rangeOf(m.perDayMl),
  };
}

export function roundsOf(v: unknown): NutrientRound[] {
  if (!Array.isArray(v)) return [];
  return v.flatMap((r: unknown) => {
    const x = r as Partial<NutrientRound> | null;
    return x &&
      typeof x.month === 'number' &&
      typeof x.fromDay === 'number' &&
      typeof x.toDay === 'number'
      ? [{ month: x.month, fromDay: x.fromDay, toDay: x.toDay }]
      : [];
  });
}

/** A count the server sends, or the length of a list. */
export function countOf(v: unknown): number | null {
  if (typeof v === 'number') return v;
  return Array.isArray(v) ? v.length : null;
}

/** The sample baby of the previews: `{name}` in rule copy becomes "Teddy". */
export const withName = (s: string) => s.split('{name}').join('Teddy');

// ---------- Labels ----------

/** "6–8 tháng" ([6, 9)), "0–1 tháng" ([0, 1)), "24–36 tháng" ([24, 37)). */
export function monthsText(intl: IntlShape, age: NutritionAge): string {
  const l = nutritionAgeLabel(age);
  return intl.formatMessage({ id: 'content.age.months' }, { from: l.from, to: l.to });
}

/** "180–240", or "180" when both ends match. */
export function rangeText(intl: IntlShape, r: NumberRange): string {
  const f = (n: number) => intl.formatNumber(n);
  return r.min === r.max ? f(r.min) : `${f(r.min)}–${f(r.max)}`;
}

/** D01 "Sữa tham khảo": per feed first (with the daily amount, or the feeds, under it). */
export function milkCell(intl: IntlShape, milk: MilkRow | null) {
  const perFeed = milk?.perFeedMl
    ? intl.formatMessage({ id: 'nutrition.ml.perFeed' }, { range: rangeText(intl, milk.perFeedMl) })
    : null;
  const perDay = milk?.perDayMl
    ? intl.formatMessage({ id: 'nutrition.ml.perDay' }, { range: rangeText(intl, milk.perDayMl) })
    : null;
  const feeds = milk?.feedsPerDay
    ? intl.formatMessage({ id: 'nutrition.feeds' }, { range: rangeText(intl, milk.feedsPerDay) })
    : null;
  if (perFeed) return { main: perFeed, sub: perDay ?? feeds };
  return { main: perDay ?? feeds, sub: perDay ? feeds : null };
}

/** "1–2/12" (or "1/6" for a single day). */
export const roundText = (r: NutrientRound) =>
  r.fromDay === r.toDay ? `${r.fromDay}/${r.month}` : `${r.fromDay}–${r.toDay}/${r.month}`;

/** The round on or after [today] (YYYY-MM-DD) in the year, else the first of next year. */
export function nextRound(rounds: readonly NutrientRound[], today: string): NutrientRound | null {
  const m = Number(today.slice(5, 7));
  const d = Number(today.slice(8, 10));
  const sorted = [...rounds].sort((a, b) => a.month - b.month || a.fromDay - b.fromDay);
  return sorted.find((r) => r.month > m || (r.month === m && r.toDay >= d)) ?? sorted[0] ?? null;
}

/** The month a published item was reviewed: its re-review date is 12 months later. */
export function reviewMonth(reviewDueOn: string): string {
  const on = addMonthsIso(reviewDueOn, -12);
  return `${on.slice(5, 7)}/${on.slice(0, 4)}`;
}

/** The first month a sample baby of the stage is in: 7 for [6, 9) (9b "7 tháng · 6–8"). */
export const sampleMonths = (age: NutritionAge) =>
  age.to - age.from > 1 ? age.from + 1 : age.from;

// ---------- Coverage 0–36 months (P-163 #17, D01) ----------

export type CoverageItemState = 'published' | 'pending' | 'draft';
const itemStates: readonly CoverageItemState[] = ['published', 'pending', 'draft'];

export interface NutritionCoverage {
  total: number;
  covered: number;
  published: number;
  /** Months no stage covers (drafts count). */
  gaps: NutritionAge[];
  /** Months no stage on the app covers: the app tile is a teaser there (P-163 #11). */
  liveGaps: NutritionAge[];
  items: Array<{ id: string; ageMonths: NutritionAge; state: CoverageItemState }>;
  overlaps: Array<{ ids: [string, string]; ageMonths: NutritionAge }>;
}

function stateOfRow(r: ContentRow): CoverageItemState | null {
  if (r.live) return 'published';
  if (r.status === 'in_review' || r.status === 'approved') return 'pending';
  return r.status === 'draft' ? 'draft' : null;
}

/**
 * The D01 strip: the server's `coverage` items when the list has them (the same rule as
 * `content-nutrition.ts`), else the rows; gaps and overlaps follow from the items.
 */
export function nutritionCoverageOf(view: {
  rows: ContentRow[];
  coverage?: unknown;
}): NutritionCoverage {
  const server = view.coverage as
    { items?: unknown; total?: unknown; covered?: unknown; published?: unknown } | undefined;
  const fromServer = Array.isArray(server?.items)
    ? (server.items as unknown[]).flatMap((x) => {
        const i = x as { id?: unknown; ageMonths?: unknown; state?: unknown } | null;
        const age = ageOf(i?.ageMonths);
        const state = i?.state as CoverageItemState;
        return i && typeof i.id === 'string' && age && itemStates.includes(state)
          ? [{ id: i.id, ageMonths: age, state }]
          : [];
      })
    : null;
  const items = sortNutritionStages(
    fromServer ??
      view.rows.flatMap((r) => {
        const age = ageOf(r.ageMonths);
        const state = stateOfRow(r);
        return age && state ? [{ id: r.id, ageMonths: age, state }] : [];
      }),
  );
  const months = Array.from({ length: N.maxAgeMonths + 1 }, (_, m) =>
    items.filter((i) => m >= i.ageMonths.from && m < i.ageMonths.to),
  );
  const overlaps: NutritionCoverage['overlaps'] = [];
  items.forEach((a, i) => {
    for (const b of items.slice(i + 1)) {
      if (!nutritionAgesOverlap(a.ageMonths, b.ageMonths)) continue;
      overlaps.push({
        ids: [a.id, b.id],
        ageMonths: {
          from: Math.max(a.ageMonths.from, b.ageMonths.from),
          to: Math.min(a.ageMonths.to, b.ageMonths.to),
        },
      });
    }
  });
  const num = (v: unknown, fallback: number) => (typeof v === 'number' ? v : fallback);
  return {
    total: num(server?.total, months.length),
    covered: num(server?.covered, months.filter((h) => h.length).length),
    published: num(
      server?.published,
      months.filter((h) => h.some((i) => i.state === 'published')).length,
    ),
    gaps: nutritionGaps(items),
    liveGaps: nutritionGaps(items.filter((i) => i.state === 'published')),
    items,
    overlaps,
  };
}

// ---------- Copy check and notices (P-163 #16) ----------

/**
 * A readable place for a schema issue or a copy problem: "Gợi ý · mục 2 · Nội dung · VI". Field
 * names come from `nutrition.field.*` (a parent-specific one first, e.g. tips → title), then the
 * shared `content.field.*`.
 */
export function nutritionPlace(intl: IntlShape, path: ReadonlyArray<PropertyKey>): string {
  const parts: string[] = [];
  let parent: string | null = null;
  for (const p of path) {
    const key = String(p);
    if (key === 'vi' || key === 'en') parts.push(key.toUpperCase());
    else if (typeof p === 'number' || /^\d+$/.test(key)) {
      parts.push(intl.formatMessage({ id: 'content.issue.item' }, { n: Number(key) + 1 }));
    } else {
      const ids = [
        parent ? `nutrition.field.${parent}.${key}` : '',
        `nutrition.field.${key}`,
        `content.field.${key}`,
      ];
      const id = ids.find((i) => i && intl.messages[i]);
      parts.push(id ? intl.formatMessage({ id }) : key);
      parent = key;
    }
  }
  return parts.join(' · ') || '—';
}

/** What blocks "Gửi duyệt" and what the server said, above the form. */
export function NutritionNotices({
  error,
  rejection,
  issues,
  problems,
  className = 'mb-4 grid gap-3',
}: {
  error: ApiError | null;
  rejection: { by: string; reason: string } | null | undefined;
  issues: ReadonlyArray<ParseIssue>;
  problems: readonly CopyProblem[];
  className?: string;
}) {
  const intl = useIntl();
  if (!error && !rejection && !issues.length && !problems.length) return null;
  const places = [...new Set(issues.map((i) => nutritionPlace(intl, i.path)))];
  return (
    <div className={className}>
      {error && (
        <Notice tone="error">
          <FormattedMessage id={errorMessageId(error)} />
        </Notice>
      )}
      {rejection && (
        <Notice tone="warn" title={<FormattedMessage id="content.rejectedTitle" />}>
          <FormattedMessage id="content.rejected" values={rejection} />
        </Notice>
      )}
      {problems.length > 0 && (
        <Notice
          tone="error"
          title={<FormattedMessage id="nutrition.copy.title" values={{ n: problems.length }} />}
        >
          <ul className="mt-1 grid list-disc gap-0.5 pl-4">
            {problems.slice(0, 12).map((p, i) => (
              <li key={i}>
                <FormattedMessage
                  id={`nutrition.copy.${p.problem}`}
                  values={{ place: nutritionPlace(intl, p.path.split('.')), match: p.match }}
                />
              </li>
            ))}
            {problems.length > 12 && <li>+{problems.length - 12}</li>}
          </ul>
          <p className="mt-2 text-xs">
            <FormattedMessage id="nutrition.copy.help" />
          </p>
        </Notice>
      )}
      {places.length > 0 && (
        <Notice
          tone="warn"
          title={<FormattedMessage id="content.issues" values={{ n: issues.length }} />}
        >
          <ul className="mt-1 flex flex-wrap gap-1.5">
            {places.slice(0, 12).map((p) => (
              <li key={p}>
                <Badge variant="outline" className="font-normal">
                  {p}
                </Badge>
              </li>
            ))}
            {places.length > 12 && (
              <li className="text-xs text-muted-foreground">+{places.length - 12}</li>
            )}
          </ul>
        </Notice>
      )}
    </div>
  );
}

// ---------- Fields ----------

/** A whole number with an optional unit, a "?" hint and an error under it. */
export function NumField({
  label,
  value,
  onChange,
  min,
  max,
  suffix,
  hint,
  help,
  error,
  className,
}: {
  label: ReactNode;
  value: number;
  onChange: (v: number) => void;
  min: number;
  max: number;
  suffix?: ReactNode;
  hint?: ReactNode;
  help?: ReactNode;
  error?: ReactNode;
  className?: string;
}) {
  const id = useId();
  return (
    <Field label={label} htmlFor={id} hint={hint} help={help} error={error} className={className}>
      <div className="relative">
        <Input
          id={id}
          type="number"
          min={min}
          max={max}
          inputMode="numeric"
          className={cn('tabular-nums', suffix && 'pr-14')}
          aria-invalid={error ? true : undefined}
          value={Number.isFinite(value) ? value : ''}
          onChange={(e) => onChange(e.target.value === '' ? Number.NaN : Number(e.target.value))}
        />
        {suffix && (
          <span className="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2 text-xs text-muted-foreground">
            {suffix}
          </span>
        )}
      </div>
    </Field>
  );
}

export const ageRangeOk = (a: NutritionAge) =>
  Number.isInteger(a.from) &&
  Number.isInteger(a.to) &&
  a.from >= 0 &&
  a.to > a.from &&
  a.to <= N.maxAgeMonths + 1;

/**
 * "Từ tháng tuổi" and "Đến tháng tuổi (gồm cả)": the last month shown is `to − 1`, stored
 * exclusive (P-163 #1). The line under it says who sees it and the app's label.
 */
export function MonthRangeFields({
  value,
  onChange,
  showHelp = true,
}: {
  value: NutritionAge;
  onChange: (a: NutritionAge) => void;
  showHelp?: boolean;
}) {
  const intl = useIntl();
  const last = value.to - 1;
  const ok = ageRangeOk(value);
  return (
    <div className="grid gap-x-4 gap-y-2 sm:grid-cols-2">
      <NumField
        label={<FormattedMessage id="nutrition.age.from" />}
        value={value.from}
        min={0}
        max={N.maxAgeMonths}
        hint={<FormattedMessage id="nutrition.age.hint" />}
        onChange={(from) => onChange({ ...value, from })}
      />
      <NumField
        label={<FormattedMessage id="nutrition.age.to" />}
        value={last}
        min={0}
        max={N.maxAgeMonths}
        error={
          Number.isFinite(last) && Number.isFinite(value.from) && last < value.from ? (
            <FormattedMessage id="nutrition.age.toError" values={{ from: value.from }} />
          ) : undefined
        }
        onChange={(v) => onChange({ ...value, to: Number.isFinite(v) ? v + 1 : Number.NaN })}
      />
      {showHelp && ok && (
        <p className="text-xs text-muted-foreground sm:col-span-2">
          <FormattedMessage
            id="nutrition.age.help"
            values={{
              single: value.from === last ? 'yes' : 'no',
              from: value.from,
              last,
              label: monthsText(intl, value),
            }}
          />
        </p>
      )}
    </div>
  );
}

/** A label with a switch on the right (an optional part of the item). */
export function SwitchRow({
  label,
  checked,
  onChange,
  hint,
  className,
}: {
  label: ReactNode;
  checked: boolean;
  onChange: (on: boolean) => void;
  hint?: ReactNode;
  className?: string;
}) {
  const id = useId();
  return (
    <div className={cn('flex items-center justify-between gap-3', className)}>
      <span className="flex items-center gap-1.5">
        <Label htmlFor={id} className="text-[13px] font-medium">
          {label}
        </Label>
        {hint && <Hint>{hint}</Hint>}
      </span>
      <Switch id={id} checked={checked} onCheckedChange={onChange} />
    </div>
  );
}

/** An optional min–max amount (ml per feed, feeds, ml per day); off = not applicable. */
export function AmountRangeField({
  label,
  value,
  onChange,
  max,
  unit,
  hint,
}: {
  label: ReactNode;
  value: NumberRange | null;
  onChange: (v: NumberRange | null) => void;
  max: number;
  unit: ReactNode;
  hint?: ReactNode;
}) {
  const intl = useIntl();
  const bad =
    !!value &&
    (!Number.isInteger(value.min) || !Number.isInteger(value.max) || value.max < value.min);
  const num = (v: string) => (v === '' ? Number.NaN : Number(v));
  return (
    <div className="grid content-start gap-2 rounded-lg border p-3">
      <SwitchRow
        label={label}
        hint={hint}
        checked={!!value}
        onChange={(on) => onChange(on ? { min: 0, max: 0 } : null)}
      />
      {value ? (
        <div className="flex items-center gap-2">
          <Input
            type="number"
            min={0}
            max={max}
            inputMode="numeric"
            className="tabular-nums"
            aria-label={intl.formatMessage({ id: 'nutrition.range.min' })}
            aria-invalid={bad || undefined}
            value={Number.isFinite(value.min) ? value.min : ''}
            onChange={(e) => onChange({ ...value, min: num(e.target.value) })}
          />
          <span className="text-muted-foreground" aria-hidden="true">
            –
          </span>
          <Input
            type="number"
            min={0}
            max={max}
            inputMode="numeric"
            className="tabular-nums"
            aria-label={intl.formatMessage({ id: 'nutrition.range.max' })}
            aria-invalid={bad || undefined}
            value={Number.isFinite(value.max) ? value.max : ''}
            onChange={(e) => onChange({ ...value, max: num(e.target.value) })}
          />
          <span className="shrink-0 text-xs text-muted-foreground">{unit}</span>
        </div>
      ) : (
        <p className="text-xs text-muted-foreground">
          <FormattedMessage id="nutrition.notApplicable" />
        </p>
      )}
      {bad && (
        <p className="text-xs text-destructive">
          <FormattedMessage id="nutrition.range.error" />
        </p>
      )}
    </div>
  );
}

/** A select with its label (and an optional "?" hint). */
export function SelectField<T extends string>({
  label,
  value,
  options,
  onChange,
  hint,
  help,
  className,
}: {
  label: ReactNode;
  value: T;
  options: Array<{ value: T; label: string }>;
  onChange: (v: T) => void;
  hint?: ReactNode;
  help?: ReactNode;
  className?: string;
}) {
  const id = useId();
  return (
    <Field label={label} htmlFor={id} hint={hint} help={help} className={className}>
      <FieldSelect<T> id={id} value={value} options={options} onChange={onChange} />
    </Field>
  );
}

export function move<T>(xs: readonly T[], i: number, by: -1 | 1): T[] {
  const j = i + by;
  if (j < 0 || j >= xs.length) return [...xs];
  const out = [...xs];
  [out[i], out[j]] = [out[j]!, out[i]!];
  return out;
}

/** ↑ ↓ ✕ for a row of a list. */
export function RowControls({
  index,
  count,
  onChange,
}: {
  index: number;
  count: number;
  onChange: (action: 'up' | 'down' | 'remove') => void;
}) {
  const intl = useIntl();
  return (
    <span className="flex shrink-0 items-center">
      <IconButton
        icon="up"
        label={intl.formatMessage({ id: 'content.moveUp' })}
        disabled={index === 0}
        onClick={() => onChange('up')}
      />
      <IconButton
        icon="down"
        label={intl.formatMessage({ id: 'content.moveDown' })}
        disabled={index === count - 1}
        onClick={() => onChange('down')}
      />
      <IconButton
        icon="remove"
        label={intl.formatMessage({ id: 'content.remove' })}
        onClick={() => onChange('remove')}
      />
    </span>
  );
}

/** Applies a RowControls action to a list. */
export function listAction<T>(xs: readonly T[], i: number, action: 'up' | 'down' | 'remove'): T[] {
  if (action === 'remove') return xs.filter((_, j) => j !== i);
  return move(xs, i, action === 'up' ? -1 : 1);
}

export function AddButton({ children, onClick }: { children: ReactNode; onClick: () => void }) {
  return (
    <div>
      <UiButton variant="outline" size="sm" onClick={onClick}>
        <Plus />
        {children}
      </UiButton>
    </div>
  );
}

export type Tip = { title: Loc; body: Loc };
export const blankLoc = (): Loc => ({ vi: '', en: '' });

/** Up to 4 cards of a title (60) and a text (220), in the language being edited. */
export function TipsEditor({
  label,
  hint,
  value,
  onChange,
  lang,
}: {
  label: ReactNode;
  hint?: ReactNode;
  value: Tip[];
  onChange: (v: Tip[]) => void;
  lang: Lang;
}) {
  return (
    <fieldset className="grid gap-2">
      <legend className="mb-1.5 flex w-full items-center gap-1.5 text-[13px] font-medium">
        {label}
        {hint && <Hint>{hint}</Hint>}
        <span className="ml-auto text-xs text-muted-foreground tabular-nums">
          {value.length}/{N.tips}
        </span>
      </legend>
      {value.map((t, i) => (
        <div key={i} className="grid gap-3 rounded-lg border p-3">
          <div className="flex items-center gap-2">
            <span className="text-[13px] font-medium text-muted-foreground">
              <FormattedMessage id="nutrition.tip.n" values={{ n: i + 1 }} />
            </span>
            <span className="ml-auto">
              <RowControls
                index={i}
                count={value.length}
                onChange={(a) => onChange(listAction(value, i, a))}
              />
            </span>
          </div>
          <TextField
            label={<FormattedMessage id="nutrition.tip.title" />}
            value={t.title[lang]}
            max={N.tipTitle}
            counter
            onChange={(v) =>
              onChange(
                value.map((x, j) => (j === i ? { ...x, title: { ...x.title, [lang]: v } } : x)),
              )
            }
          />
          <TextField
            label={<FormattedMessage id="nutrition.tip.body" />}
            value={t.body[lang]}
            max={N.tipBody}
            counter
            multiline
            rows={2}
            onChange={(v) =>
              onChange(
                value.map((x, j) => (j === i ? { ...x, body: { ...x.body, [lang]: v } } : x)),
              )
            }
          />
        </div>
      ))}
      {value.length < N.tips && (
        <AddButton onClick={() => onChange([...value, { title: blankLoc(), body: blankLoc() }])}>
          <FormattedMessage id="nutrition.tip.add" />
        </AddButton>
      )}
    </fieldset>
  );
}
