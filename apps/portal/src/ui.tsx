import { Loader2, Lock, MoreHorizontal } from 'lucide-react';
import { useEffect, useId, useRef, type CSSProperties, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Button as UiButton } from '@/components/ui/button';
import { Dialog, DialogContent, DialogTitle } from '@/components/ui/dialog';
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

// ---------- Charts (plain SVG; aggregates only) ----------

function niceMax(v: number): number {
  if (v <= 5) return 5;
  const p = 10 ** Math.floor(Math.log10(v));
  const m = v / p;
  return (m <= 1 ? 1 : m <= 2 ? 2 : m <= 5 ? 5 : 10) * p;
}

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
  const W = 640;
  const H = 220;
  const pad = { l: 44, r: 16, t: 12, b: 26 };
  const max = niceMax(Math.max(1, threshold ?? 0, ...points));
  const x = (i: number) => pad.l + (i * (W - pad.l - pad.r)) / Math.max(1, points.length - 1);
  const y = (v: number) => pad.t + (1 - v / max) * (H - pad.t - pad.b);
  const line = points.map((v, i) => `${i ? 'L' : 'M'}${x(i)},${y(v)}`).join('');
  const ticks = [0, max / 3, (2 * max) / 3, max].map((t) => Math.round(t));
  const last = points.length - 1;
  const every = Math.ceil(labels.length / 6);
  return (
    <svg className="chart" viewBox={`0 0 ${W} ${H}`} role="img" aria-label={title}>
      {ticks.map((t) => (
        <g key={t}>
          <line className="chart__grid" x1={pad.l} x2={W - pad.r} y1={y(t)} y2={y(t)} />
          <text className="chart__axis" x={pad.l - 8} y={y(t) + 4} textAnchor="end">
            {intl.formatNumber(t)}
          </text>
        </g>
      ))}
      {area && points.length > 1 && (
        <path className="chart__area" d={`${line}L${x(last)},${y(0)}L${x(0)},${y(0)}Z`} />
      )}
      <path className="chart__line" d={line} />
      {threshold !== undefined && (
        <g>
          <line
            className="chart__threshold"
            x1={pad.l}
            x2={W - pad.r}
            y1={y(threshold)}
            y2={y(threshold)}
          />
          {thresholdLabel && (
            <text className="chart__axis" x={W - pad.r} y={y(threshold) - 6} textAnchor="end">
              {thresholdLabel}
            </text>
          )}
        </g>
      )}
      {last >= 0 && (
        <g>
          <circle className="chart__dot" cx={x(last)} cy={y(points[last]!)} r={4} />
          <text className="chart__value" x={x(last) - 8} y={y(points[last]!) - 10} textAnchor="end">
            {intl.formatNumber(points[last]!)}
          </text>
        </g>
      )}
      {labels.map((l, i) =>
        i % every === 0 || i === last ? (
          <text key={i} className="chart__axis" x={x(i)} y={H - 6} textAnchor="middle">
            {l}
          </text>
        ) : null,
      )}
    </svg>
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
  const W = 640;
  const H = 220;
  const pad = { l: 44, r: 16, t: 12, b: 26 };
  const value = (s: Record<string, number | string>, key: string) => Number(s[key] ?? 0) || 0;
  const totals = series.map((s) => keys.reduce((n, k) => n + value(s, k.key), 0));
  const max = niceMax(Math.max(1, ...totals));
  const band = (W - pad.l - pad.r) / Math.max(1, series.length);
  const y = (v: number) => (v / max) * (H - pad.t - pad.b);
  return (
    <div>
      <svg className="chart" viewBox={`0 0 ${W} ${H}`} role="img" aria-label={title}>
        {[0, max / 2, max].map((t) => (
          <g key={t}>
            <line
              className="chart__grid"
              x1={pad.l}
              x2={W - pad.r}
              y1={H - pad.b - y(t)}
              y2={H - pad.b - y(t)}
            />
            <text className="chart__axis" x={pad.l - 8} y={H - pad.b - y(t) + 4} textAnchor="end">
              {intl.formatNumber(t, { notation: 'compact' })}
            </text>
          </g>
        ))}
        {series.map((s, i) => {
          let base = H - pad.b;
          return (
            <g key={i}>
              {keys.map((k) => {
                const h = y(value(s, k.key));
                base -= h;
                return (
                  <rect
                    key={k.key}
                    className={k.className}
                    x={pad.l + i * band + band * 0.2}
                    width={band * 0.6}
                    y={base}
                    height={h}
                  />
                );
              })}
              <text
                className="chart__axis"
                x={pad.l + i * band + band / 2}
                y={H - 6}
                textAnchor="middle"
              >
                {labels[i]}
              </text>
            </g>
          );
        })}
      </svg>
      <ul className="legend">
        {keys.map((k) => (
          <li key={k.key}>
            <span className={`legend__dot ${k.className}`} />
            {k.label}
          </li>
        ))}
      </ul>
    </div>
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
