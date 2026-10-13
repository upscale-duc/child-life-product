import { ArrowDown, ArrowUp, ArrowUpDown, Loader2, Lock, MoreHorizontal } from 'lucide-react';
import {
  useEffect,
  useId,
  useMemo,
  useRef,
  useState,
  type CSSProperties,
  type ReactNode,
} from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  ReferenceLine,
  XAxis,
  YAxis,
} from 'recharts';
import { Button as UiButton } from '@/components/ui/button';
import {
  ChartContainer,
  ChartLegend,
  ChartLegendContent,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from '@/components/ui/chart';
import { Dialog, DialogContent, DialogTitle } from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { cn } from '@/lib/utils';
import type { ApiError, Load } from './api';

/**
 * Building blocks of the staff portal (Figma Admin portal `253:18`), drawn with shadcn/ui and the
 * Child Life palette (D-063). Screens keep these props; the look lives here and in index.css.
 */

export function Page({
  title,
  subtitle,
  actions,
  children,
}: {
  title: ReactNode;
  subtitle: ReactNode;
  actions?: ReactNode;
  children: ReactNode;
}) {
  return (
    <section className="page">
      <header className="page__head">
        <div>
          <h1 className="page__title">{title}</h1>
          <p className="page__sub">{subtitle}</p>
        </div>
        {actions && <div className="page__actions">{actions}</div>}
      </header>
      {children}
    </section>
  );
}

export function Panel({
  title,
  note,
  aside,
  children,
  className,
}: {
  title?: ReactNode;
  note?: ReactNode;
  aside?: ReactNode;
  children: ReactNode;
  className?: string;
}) {
  return (
    <div className={`panel ${className ?? ''}`}>
      {(title || aside) && (
        <div className="panel__head">
          <div>
            {title && <h2 className="panel__title">{title}</h2>}
            {note && <p className="panel__note">{note}</p>}
          </div>
          {aside}
        </div>
      )}
      {children}
    </div>
  );
}

export function Kpi({
  label,
  value,
  foot,
  tone,
}: {
  label: ReactNode;
  value: ReactNode;
  foot?: ReactNode;
  tone?: 'up' | 'down' | 'warn' | 'error' | 'muted';
}) {
  return (
    <div className="kpi">
      <p className="kpi__label">{label}</p>
      <p className="kpi__value">{value}</p>
      {foot && <p className={`kpi__foot kpi__foot--${tone ?? 'muted'}`}>{foot}</p>}
    </div>
  );
}

export function Segmented<T extends string | number>({
  value,
  options,
  onChange,
  label,
}: {
  value: T;
  options: Array<{ value: T; label: ReactNode }>;
  onChange: (v: T) => void;
  label: string;
}) {
  return (
    <div className="seg" role="tablist" aria-label={label}>
      {options.map((o) => (
        <button
          key={String(o.value)}
          type="button"
          role="tab"
          aria-selected={o.value === value}
          className={`seg__item ${o.value === value ? 'seg__item--on' : ''}`}
          onClick={() => onChange(o.value)}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}

export type PillTone = 'error' | 'high' | 'warn' | 'wait' | 'ok' | 'info' | 'muted' | 'purple';
export function Pill({ tone, children }: { tone: PillTone; children: ReactNode }) {
  return <span className={`pill pill--${tone}`}>{children}</span>;
}

const buttonVariant = {
  primary: 'default',
  secondary: 'outline',
  danger: 'destructive',
  ghost: 'ghost',
} as const;

export function Button({
  kind = 'secondary',
  children,
  disabled,
  onClick,
  type = 'button',
  title,
}: {
  kind?: 'primary' | 'secondary' | 'danger' | 'ghost';
  children: ReactNode;
  disabled?: boolean;
  onClick?: () => void;
  type?: 'button' | 'submit';
  title?: string;
}) {
  return (
    <UiButton
      type={type}
      variant={buttonVariant[kind]}
      className={kind === 'ghost' ? 'text-primary hover:text-primary' : undefined}
      disabled={disabled}
      onClick={onClick}
      title={title}
    >
      {children}
    </UiButton>
  );
}

/** A filter or choice from a short list (shadcn Select); the label names it for screen readers. */
export function SelectMenu<T extends string | number>({
  value,
  onChange,
  options,
  label,
  className,
}: {
  value: T;
  onChange: (value: T) => void;
  options: Array<{ value: T; label: string }>;
  label: string;
  className?: string;
}) {
  const selected = options.find((o) => o.value === value);
  return (
    <Select
      value={String(value)}
      onValueChange={(v) => {
        const hit = options.find((o) => String(o.value) === v);
        if (hit) onChange(hit.value);
      }}
    >
      <SelectTrigger aria-label={label} className={cn('min-w-36', className)}>
        <SelectValue>{selected?.label}</SelectValue>
      </SelectTrigger>
      <SelectContent position="popper" align="start">
        {options.map((o) => (
          <SelectItem key={String(o.value)} value={String(o.value)}>
            {o.label}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  );
}

export type RowAction = {
  key: string;
  label: ReactNode;
  onSelect: () => void;
  /** Shown in red, after a separator (remove, revoke). */
  destructive?: boolean;
};

/** A row's actions behind "⋯" (shadcn-admin data tables), so long rows keep one line. */
export function RowActions({ label, actions }: { label: string; actions: RowAction[] }) {
  if (!actions.length) return null;
  const plain = actions.filter((a) => !a.destructive);
  const danger = actions.filter((a) => a.destructive);
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <UiButton
          variant="ghost"
          size="icon"
          className="size-8 data-[state=open]:bg-muted"
          aria-label={label}
          title={label}
        >
          <MoreHorizontal />
        </UiButton>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="min-w-40">
        {plain.map((a) => (
          <DropdownMenuItem key={a.key} onSelect={a.onSelect}>
            {a.label}
          </DropdownMenuItem>
        ))}
        {plain.length > 0 && danger.length > 0 && <DropdownMenuSeparator />}
        {danger.map((a) => (
          <DropdownMenuItem key={a.key} variant="destructive" onSelect={a.onSelect}>
            {a.label}
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

export type SortDir = 'asc' | 'desc';
type SortValue = string | number | null | undefined;
const collator = new Intl.Collator('vi', { numeric: true, sensitivity: 'base' });

/**
 * Click-to-sort columns for lists the portal loads whole (shadcn-admin data tables): asc, desc,
 * then back to the server's order. Empty values always go last.
 */
export function useSort<T, K extends string>(
  rows: readonly T[],
  by: Record<K, (row: T) => SortValue>,
) {
  const [sort, setSort] = useState<{ key: K; dir: SortDir } | null>(null);
  const sorted = useMemo(() => {
    if (!sort) return rows;
    const get = by[sort.key];
    const sign = sort.dir === 'asc' ? 1 : -1;
    return [...rows].sort((a, b) => {
      const x = get(a);
      const y = get(b);
      if (x == null || x === '') return y == null || y === '' ? 0 : 1;
      if (y == null || y === '') return -1;
      const c =
        typeof x === 'number' && typeof y === 'number'
          ? x - y
          : collator.compare(String(x), String(y));
      return c * sign;
    });
    // `by` is a table of accessors defined with the table; the sort key decides.
  }, [rows, sort]);
  const toggle = (key: K) =>
    setSort((s) =>
      s?.key !== key ? { key, dir: 'asc' } : s.dir === 'asc' ? { key, dir: 'desc' } : null,
    );
  const th = (key: K, label: ReactNode) => (
    <SortTh label={label} dir={sort?.key === key ? sort.dir : null} onClick={() => toggle(key)} />
  );
  return { rows: sorted, th };
}

/** A header cell that sorts its column; `aria-sort` tells screen readers the order. */
export function SortTh({
  label,
  dir,
  onClick,
}: {
  label: ReactNode;
  dir: SortDir | null;
  onClick: () => void;
}) {
  const Icon = dir === 'asc' ? ArrowUp : dir === 'desc' ? ArrowDown : ArrowUpDown;
  return (
    <th aria-sort={dir === 'asc' ? 'ascending' : dir === 'desc' ? 'descending' : undefined}>
      <button type="button" className="th-sort" onClick={onClick}>
        {label}
        <Icon
          className={cn('size-3.5', dir ? 'text-foreground' : 'opacity-50')}
          aria-hidden="true"
        />
      </button>
    </th>
  );
}

/**
 * A wide table scrolls sideways inside its panel instead of being cut off or squeezed into
 * one-word columns. `min` is the width below which the table stops shrinking.
 */
export function TableScroll({ min = 640, children }: { min?: number; children: ReactNode }) {
  return (
    <div className="table-scroll" style={{ '--table-min': `${min}px` } as CSSProperties}>
      {children}
    </div>
  );
}

/** Lock-icon helper notes (A03, A04, A06, A10, A12). */
export function LockNote({ children }: { children: ReactNode }) {
  return (
    <p className="lock">
      <Lock className="size-3.5" aria-hidden="true" />
      <span>{children}</span>
    </p>
  );
}

export function UsageBar({ ratio, tone }: { ratio: number; tone: 'ok' | 'warn' | 'error' }) {
  const w = Math.max(0, Math.min(1, ratio)) * 100;
  return (
    <span className="bar" aria-hidden="true">
      <span className={`bar__fill bar__fill--${tone}`} style={{ width: `${w}%` }} />
    </span>
  );
}

/**
 * Keeps the page behind an open dialog, drawer or menu from scrolling. Counted, so a dialog opened
 * from the QA case sheet does not unlock the page when it closes.
 */
export function useScrollLock(active = true) {
  useEffect(() => {
    if (!active || typeof document === 'undefined') return;
    const body = document.body;
    const count = Number(body.dataset.scrollLocks ?? '0') + 1;
    body.dataset.scrollLocks = String(count);
    body.classList.add('no-scroll');
    return () => {
      const left = Number(body.dataset.scrollLocks ?? '1') - 1;
      body.dataset.scrollLocks = String(left);
      if (left <= 0) body.classList.remove('no-scroll');
    };
  }, [active]);
}

/** Open layers (menu drawer, case sheet, dialog), newest last: Escape closes only the top one. */
const escapeStack: { current: () => void }[] = [];
function onEscapeKey(e: KeyboardEvent) {
  const top = escapeStack[escapeStack.length - 1];
  // A Radix dialog or menu above our layers handles its own Escape (and marks it handled).
  if (e.key !== 'Escape' || !top || e.defaultPrevented) return;
  e.stopPropagation();
  top.current();
}

export function useEscape(onEscape: () => void, active = true) {
  const handler = useRef(onEscape);
  handler.current = onEscape;
  useEffect(() => {
    if (!active || typeof window === 'undefined') return;
    if (escapeStack.length === 0) window.addEventListener('keydown', onEscapeKey);
    escapeStack.push(handler);
    return () => {
      const at = escapeStack.lastIndexOf(handler);
      if (at >= 0) escapeStack.splice(at, 1);
      if (escapeStack.length === 0) window.removeEventListener('keydown', onEscapeKey);
    };
  }, [active]);
}

export function Modal({
  title,
  onClose,
  children,
  icon,
  wide,
}: {
  title: ReactNode;
  onClose: () => void;
  children: ReactNode;
  icon?: ReactNode;
  /** Forms with several long fields (the QA case editor). */
  wide?: boolean;
}) {
  const id = useId();
  const intl = useIntl();
  // Server rendering (tests) has no portal: the same content, inline.
  if (typeof document === 'undefined') {
    return (
      <div className="modal" role="dialog" aria-modal="true" aria-labelledby={id}>
        {icon}
        <h2 className="modal__title" id={id}>
          {title}
        </h2>
        {children}
      </div>
    );
  }
  // Radix: focus trap, scroll lock and Escape; the first field gets the focus.
  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent
        aria-describedby={undefined}
        closeLabel={intl.formatMessage({ id: 'action.close' })}
        className={cn(
          'max-h-[calc(100dvh-2rem)] gap-4 overflow-y-auto overscroll-contain',
          wide ? 'sm:max-w-3xl' : 'sm:max-w-lg',
        )}
      >
        {icon}
        <DialogTitle className="modal__title pr-6">{title}</DialogTitle>
        {children}
      </DialogContent>
    </Dialog>
  );
}

/** "Lý do (ghi vào nhật ký thao tác)": 3–500 characters, as the server requires. */
export function ReasonField({
  value,
  onChange,
  required,
}: {
  value: string;
  onChange: (v: string) => void;
  required?: boolean;
}) {
  const id = useId();
  return (
    <div className="field">
      <label htmlFor={id} className="field__label">
        <FormattedMessage id={required ? 'reason.labelRequired' : 'reason.label'} />
      </label>
      <textarea
        id={id}
        className="field__input"
        rows={3}
        maxLength={500}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
    </div>
  );
}

export const reasonOk = (s: string) => s.trim().length >= 3;

export function Loading() {
  return (
    <div className="state" role="status">
      <Loader2 className="size-4 animate-spin text-primary" aria-hidden="true" />
      <FormattedMessage id="state.loading" />
    </div>
  );
}

export function Empty({ children }: { children: ReactNode }) {
  return <div className="state state--empty">{children}</div>;
}

/** Server reasons with their own message (`error.<reason>`), v1.0 staff and data actions. */
export const reasonMessages = [
  'last-owner',
  'family-not-found',
  'self',
  'already-member',
  'already-active',
  'locked',
  'name-taken',
  'unknown-role',
  'already-requested',
  'same-person',
  'not-requested',
  'past',
  'not-eligible',
  'transfer-pending',
  'no-change',
  'rows-invalid',
  'rows-duplicate',
  'rows-out-of-range',
  'bands-gap',
  'bands-open',
  'not-draft',
  'not-pending',
  'not-retired',
  'image-missing',
  'image-unreadable',
  'review-required',
  'no-contact',
  'no-screenshot',
  'too-large',
];

export function errorMessageId(error: ApiError): string {
  if (error.reason === 'role') return 'error.role';
  if (error.reason === 'not-staff' || error.code === 'unauthenticated') return 'error.notStaff';
  if (error.reason === 'already-claimed') return 'error.alreadyClaimed';
  if (error.reason === 'already-decided') return 'error.alreadyDecided';
  if (error.reason === 'not-failed') return 'error.notFailed';
  if (error.reason === 'archived') return 'error.qaArchived';
  if (error.reason && reasonMessages.includes(error.reason)) return `error.${error.reason}`;
  if (error.code === 'not-found') return 'error.notFound';
  if (error.code === 'invalid-argument') return 'error.invalid';
  return 'error.generic';
}

export function ErrorState({ error, onRetry }: { error: ApiError; onRetry: () => void }) {
  return (
    <div className="state state--error" role="alert">
      <FormattedMessage id={errorMessageId(error)} />
      <Button onClick={onRetry}>
        <FormattedMessage id="state.retry" />
      </Button>
    </div>
  );
}

/** Renders the loaded data, or the loading / error state. */
export function Loaded<T>({
  load,
  reload,
  children,
}: {
  load: Load<T>;
  reload: () => void;
  children: (data: T) => ReactNode;
}) {
  if (load.status === 'loading') return <Loading />;
  if (load.status === 'error') return <ErrorState error={load.error} onRetry={reload} />;
  return <>{children(load.data)}</>;
}

// ---------- Charts (shadcn chart on recharts; aggregates only) ----------

/** The legacy class names screens pass for series colours, as chart colours. */
const seriesColor: Record<string, string> = {
  'fill-feed': 'var(--care-bottle-accent)',
  'fill-sleep': 'var(--care-sleep-accent)',
  'fill-diaper': 'var(--care-diaper-accent)',
};
const fallbackColors = ['var(--chart-1)', 'var(--chart-2)', 'var(--chart-3)', 'var(--chart-4)'];

export function LineChart({
  points,
  labels,
  threshold,
  thresholdLabel,
  area = true,
  title,
}: {
  points: number[];
  labels: string[];
  threshold?: number;
  thresholdLabel?: string;
  area?: boolean;
  title: string;
}) {
  const intl = useIntl();
  const gradient = useId().replace(/:/g, '');
  const data = points.map((value, i) => ({ label: labels[i] ?? '', value }));
  const config = { value: { label: title, color: 'var(--chart-2)' } } satisfies ChartConfig;
  return (
    <ChartContainer
      config={config}
      className="aspect-auto h-[220px] w-full"
      role="img"
      aria-label={title}
    >
      <AreaChart data={data} margin={{ top: 12, right: 12, left: 0, bottom: 0 }}>
        <defs>
          <linearGradient id={gradient} x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="var(--color-value)" stopOpacity={area ? 0.3 : 0} />
            <stop offset="95%" stopColor="var(--color-value)" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid vertical={false} />
        <XAxis dataKey="label" tickLine={false} axisLine={false} tickMargin={8} minTickGap={24} />
        <YAxis
          width={40}
          tickLine={false}
          axisLine={false}
          allowDecimals={false}
          tickFormatter={(v: number) => intl.formatNumber(v, { notation: 'compact' })}
        />
        <ChartTooltip
          cursor={false}
          content={<ChartTooltipContent indicator="line" className="min-w-44 gap-2" />}
        />
        {threshold !== undefined && (
          <ReferenceLine
            y={threshold}
            stroke="var(--warning)"
            strokeDasharray="6 5"
            label={
              thresholdLabel
                ? {
                    value: thresholdLabel,
                    position: 'insideTopRight',
                    fill: 'var(--muted-foreground)',
                    fontSize: 11,
                  }
                : undefined
            }
          />
        )}
        <Area
          dataKey="value"
          type="monotone"
          stroke="var(--color-value)"
          strokeWidth={2}
          fill={`url(#${gradient})`}
          dot={false}
          activeDot={{ r: 4 }}
        />
      </AreaChart>
    </ChartContainer>
  );
}

export function StackedBars({
  series,
  labels,
  keys,
  title,
}: {
  series: Array<Record<string, number | string>>;
  labels: string[];
  keys: Array<{ key: string; label: string; className: string }>;
  title: string;
}) {
  const intl = useIntl();
  const data = series.map((s, i) => ({
    label: labels[i] ?? '',
    ...Object.fromEntries(keys.map((k) => [k.key, Number(s[k.key] ?? 0) || 0])),
  }));
  const config = Object.fromEntries(
    keys.map((k, i) => [
      k.key,
      { label: k.label, color: seriesColor[k.className] ?? fallbackColors[i % 4] },
    ]),
  ) satisfies ChartConfig;
  return (
    <ChartContainer
      config={config}
      className="aspect-auto h-[240px] w-full"
      role="img"
      aria-label={title}
    >
      <BarChart data={data} margin={{ top: 12, right: 12, left: 0, bottom: 0 }}>
        <CartesianGrid vertical={false} />
        <XAxis dataKey="label" tickLine={false} axisLine={false} tickMargin={8} minTickGap={16} />
        <YAxis
          width={40}
          tickLine={false}
          axisLine={false}
          allowDecimals={false}
          tickFormatter={(v: number) => intl.formatNumber(v, { notation: 'compact' })}
        />
        <ChartTooltip
          cursor={{ fill: 'var(--muted)' }}
          content={<ChartTooltipContent className="min-w-44 gap-2" />}
        />
        <ChartLegend content={<ChartLegendContent />} />
        {keys.map((k, i) => (
          <Bar
            key={k.key}
            dataKey={k.key}
            stackId="a"
            fill={`var(--color-${k.key})`}
            radius={i === keys.length - 1 ? [4, 4, 0, 0] : 0}
            maxBarSize={36}
          />
        ))}
      </BarChart>
    </ChartContainer>
  );
}

/** Horizontal bars with a count and a share (funnel, histogram, outcomes). */
export function HBars({
  rows,
}: {
  rows: Array<{ label: ReactNode; value: ReactNode; ratio: number; tone?: string }>;
}) {
  return (
    <ul className="hbars">
      {rows.map((r, i) => (
        <li key={i} className="hbars__row">
          <span className="hbars__label">{r.label}</span>
          <span className="hbars__track">
            <span
              className={`hbars__fill ${r.tone ? `hbars__fill--${r.tone}` : ''}`}
              style={{ width: `${Math.max(0, Math.min(1, r.ratio)) * 100}%` }}
            />
          </span>
          <span className="hbars__value">{r.value}</span>
        </li>
      ))}
    </ul>
  );
}
