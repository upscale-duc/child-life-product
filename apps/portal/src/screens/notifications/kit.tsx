import { useCallback, useEffect, useState, type CSSProperties, type ReactNode } from 'react';
import { FormattedMessage } from 'react-intl';
import { Skeleton } from '@/components/ui/skeleton';
import { cn } from '@/lib/utils';
import { ApiError, useApi, type Callable, type Load } from '../../api';
import { Button } from '../../ui';
import { ntfErrorId } from './shared';

/**
 * Layout pieces of the Notifications module (portal design system only): a tab header with one
 * line of purpose, tables whose header stays visible, truncated codes, status dots, a sparkline
 * and skeletons for layouts that are known while loading.
 */

/** "Gửi & lỗi — Lần gửi lỗi, …": the tab's name and purpose, with its controls on the right. */
export function TabHeader({
  title,
  purpose,
  actions,
}: {
  title: ReactNode;
  purpose: ReactNode;
  actions?: ReactNode;
}) {
  return (
    <div className="flex flex-wrap items-end justify-between gap-x-4 gap-y-2">
      <div className="grid min-w-0 gap-0.5">
        <h2 className="text-lg leading-7 font-semibold tracking-tight">{title}</h2>
        <p className="text-[13px] text-muted-foreground">{purpose}</p>
      </div>
      {actions && <div className="flex flex-wrap items-end gap-2">{actions}</div>}
    </div>
  );
}

/**
 * A table that scrolls inside itself (sideways on narrow screens, down when long) so its header
 * stays visible; numbers in it are right-aligned by the cells.
 */
export function DataTable({
  min = 640,
  tall,
  children,
  label,
}: {
  min?: number;
  /** No height limit (short tables). */
  tall?: boolean;
  children: ReactNode;
  label?: string;
}) {
  return (
    <div
      className={cn(
        'table-scroll [&_thead_th]:sticky [&_thead_th]:top-0 [&_thead_th]:z-[1] [&_thead_th]:bg-muted',
        !tall && 'max-h-[70vh] overflow-y-auto',
      )}
      style={{ '--table-min': `${min}px` } as CSSProperties}
      role={label ? 'region' : undefined}
      aria-label={label}
      tabIndex={label ? 0 : undefined}
    >
      {children}
    </div>
  );
}

/** A long code cut to fit, the full value on hover and for screen readers. */
export function CodeText({ value, max = 'max-w-[14rem]' }: { value: string; max?: string }) {
  return (
    <code
      className={cn(
        'inline-block truncate align-bottom font-mono text-[12px] text-muted-foreground',
        max,
      )}
      title={value}
    >
      {value}
    </code>
  );
}

export type DotTone = 'ok' | 'warn' | 'error' | 'wait' | 'muted';
const dotClass: Record<DotTone, string> = {
  ok: 'bg-success',
  warn: 'bg-warning',
  error: 'bg-destructive',
  wait: 'bg-primary',
  muted: 'bg-muted-foreground/50',
};

/** A small coloured dot and its words (colour is never the only signal). */
export function StatusDot({ tone, children }: { tone: DotTone; children: ReactNode }) {
  return (
    <span className="inline-flex items-center gap-1.5 whitespace-nowrap">
      <span className={cn('size-2 shrink-0 rounded-full', dotClass[tone])} aria-hidden="true" />
      {children}
    </span>
  );
}

/** A tiny trend line; null values (no data yet) are gaps, not zeros. */
export function Sparkline({
  points,
  label,
  className,
}: {
  points: Array<number | null>;
  label: string;
  className?: string;
}) {
  const w = 120;
  const h = 32;
  const values = points.filter((p): p is number => p !== null);
  // One day is a dot, not a trend: draw nothing until there are two.
  if (values.length < 2) return null;
  const max = Math.max(1, ...values);
  const step = points.length > 1 ? w / (points.length - 1) : w;
  const segments: string[][] = [];
  let current: string[] = [];
  points.forEach((p, i) => {
    if (p === null) {
      if (current.length) segments.push(current);
      current = [];
      return;
    }
    current.push(`${(i * step).toFixed(1)},${(h - 2 - (p / max) * (h - 4)).toFixed(1)}`);
  });
  if (current.length) segments.push(current);
  return (
    <svg
      viewBox={`0 0 ${w} ${h}`}
      className={cn('h-8 w-full text-primary', className)}
      role="img"
      aria-label={label}
      preserveAspectRatio="none"
    >
      {segments.map((s, i) =>
        s.length === 1 ? (
          <circle
            key={i}
            cx={s[0]!.split(',')[0]}
            cy={s[0]!.split(',')[1]}
            r="1.5"
            fill="currentColor"
          />
        ) : (
          <polyline
            key={i}
            points={s.join(' ')}
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
            vectorEffect="non-scaling-stroke"
          />
        ),
      )}
    </svg>
  );
}

export function TilesSkeleton({ n = 4 }: { n?: number }) {
  return (
    <div className="grid grid-cols-2 gap-3 lg:grid-cols-4" aria-hidden="true">
      {Array.from({ length: n }, (_, i) => (
        <Skeleton key={i} className="h-[84px] rounded-xl" />
      ))}
    </div>
  );
}

export function TableSkeleton({ rows = 6 }: { rows?: number }) {
  return (
    <div className="grid gap-2 rounded-xl border p-4" aria-hidden="true">
      <Skeleton className="h-6 w-1/3" />
      {Array.from({ length: rows }, (_, i) => (
        <Skeleton key={i} className="h-9" />
      ))}
    </div>
  );
}

export function PageSkeleton() {
  return (
    <div className="stack" role="status">
      <span className="sr-only">
        <FormattedMessage id="state.loading" />
      </span>
      <TilesSkeleton />
      <TableSkeleton />
    </div>
  );
}

export function ErrorPanel({ error, onRetry }: { error: ApiError; onRetry: () => void }) {
  return (
    <div
      className="flex flex-wrap items-center gap-3 rounded-xl border border-destructive/40 bg-destructive/5 px-4 py-3 text-sm text-destructive"
      role="alert"
    >
      <FormattedMessage id={ntfErrorId(error)} />
      <Button onClick={onRetry}>
        <FormattedMessage id="state.retry" />
      </Button>
    </div>
  );
}

/** Like `Loaded`, with a skeleton of the coming layout instead of a spinner. */
export function LoadedSkeleton<T>({
  load,
  reload,
  skeleton,
  children,
}: {
  load: Load<T>;
  reload: () => void;
  skeleton?: ReactNode;
  children: (data: T) => ReactNode;
}) {
  if (load.status === 'loading') return <>{skeleton ?? <PageSkeleton />}</>;
  if (load.status === 'error') return <ErrorPanel error={load.error} onRetry={reload} />;
  return <>{children(load.data)}</>;
}

/** `useLoad` that only calls when [enabled] (a tab the staff member may not open stays silent). */
export function useOptionalLoad<T>(
  enabled: boolean,
  name: Callable,
  data: unknown,
  key: string,
): readonly [Load<T> | null, () => void] {
  const api = useApi();
  const [state, setState] = useState<Load<T>>({ status: 'loading' });
  const [tick, setTick] = useState(0);
  useEffect(() => {
    if (!enabled) return;
    let live = true;
    api
      .call<T>(name, data)
      .then((d) => live && setState({ status: 'ok', data: d }))
      .catch(
        (e: unknown) =>
          live &&
          setState({
            status: 'error',
            error: e instanceof ApiError ? e : new ApiError('unknown', null),
          }),
      );
    return () => {
      live = false;
    };
    // `data` is described by `key`.
  }, [api, enabled, name, key, tick]);
  const reload = useCallback(() => setTick((t) => t + 1), []);
  return [enabled ? state : null, reload] as const;
}
