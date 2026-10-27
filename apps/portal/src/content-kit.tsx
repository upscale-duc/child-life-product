import {
  ArrowLeft,
  ChevronDown,
  CircleAlert,
  CircleCheck,
  CircleHelp,
  Info,
  MoreHorizontal,
  Search,
  SlidersHorizontal,
  TriangleAlert,
  X,
  type LucideIcon,
} from 'lucide-react';
import {
  cloneElement,
  isValidElement,
  useEffect,
  useId,
  useState,
  type ReactElement,
  type ReactNode,
} from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '@/components/ui/collapsible';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { cn } from '@/lib/utils';

/**
 * Building blocks of the content screens (Sơ cứu, Nhịp lớn lên, Bài viết, Giai đoạn, Mốc phát
 * triển) on shadcn/ui (D-063): an editor bar that stays on screen, stat tiles that filter, a
 * filter bar, sections that fold away what is used less, hints instead of long paragraphs,
 * notices, a confirmation dialog and an empty state.
 */

// ---------- Menus ----------

export type MenuItem = {
  key: string;
  label: ReactNode;
  icon?: LucideIcon;
  onSelect: () => void;
  /** Red, after a separator (remove, discard, unpublish). */
  destructive?: boolean;
  disabled?: boolean;
};

/** Less frequent actions behind "⋯" (or a labelled button), so the bar keeps one main action. */
export function OverflowMenu({
  items,
  label,
  text,
  heading,
}: {
  items: MenuItem[];
  label?: string;
  /** Shown on the button next to the icon. */
  text?: ReactNode;
  heading?: ReactNode;
}) {
  const intl = useIntl();
  if (!items.length) return null;
  const name = label ?? intl.formatMessage({ id: 'kit.more' });
  const plain = items.filter((a) => !a.destructive);
  const danger = items.filter((a) => a.destructive);
  const row = (a: MenuItem) => (
    <DropdownMenuItem
      key={a.key}
      disabled={a.disabled}
      variant={a.destructive ? 'destructive' : 'default'}
      onSelect={a.onSelect}
    >
      {a.icon && <a.icon />}
      {a.label}
    </DropdownMenuItem>
  );
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="outline"
          size={text ? 'default' : 'icon'}
          aria-label={name}
          title={text ? undefined : name}
          className="data-[state=open]:bg-muted"
        >
          <MoreHorizontal />
          {text}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="min-w-48">
        {heading && <DropdownMenuLabel>{heading}</DropdownMenuLabel>}
        {plain.map(row)}
        {plain.length > 0 && danger.length > 0 && <DropdownMenuSeparator />}
        {danger.map(row)}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

// ---------- Stat tiles ----------

export type StatTone = 'default' | 'ok' | 'warn' | 'error' | 'muted';
export type StatItem = {
  key: string;
  label: ReactNode;
  value: ReactNode;
  tone?: StatTone;
  foot?: ReactNode;
  /** The list is filtered by this tile. */
  active?: boolean;
  onClick?: () => void;
};

const statValueTone: Record<StatTone, string> = {
  default: 'text-foreground',
  ok: 'text-success',
  warn: 'text-warning',
  error: 'text-destructive',
  muted: 'text-muted-foreground',
};

/** A row of small counts; a tile with `onClick` filters the list below (and clears it again). */
export function StatTiles({ items }: { items: StatItem[] }) {
  return (
    <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
      {items.map((s) => {
        const body = (
          <>
            <span className="text-[13px] font-medium text-muted-foreground">{s.label}</span>
            <span
              className={cn(
                'text-2xl leading-8 font-bold tracking-tight',
                statValueTone[s.tone ?? 'default'],
              )}
            >
              {s.value}
            </span>
            {s.foot && <span className="text-xs text-muted-foreground">{s.foot}</span>}
          </>
        );
        const base = 'flex min-w-0 flex-col gap-0.5 rounded-xl border bg-card px-4 py-3 text-left';
        return s.onClick ? (
          <button
            key={s.key}
            type="button"
            aria-pressed={!!s.active}
            onClick={s.onClick}
            className={cn(
              base,
              'transition-colors outline-none hover:border-primary/50 focus-visible:ring-[3px] focus-visible:ring-ring/50',
              s.active && 'border-primary bg-accent/60 ring-1 ring-primary/40',
            )}
          >
            {body}
          </button>
        ) : (
          <div key={s.key} className={base}>
            {body}
          </div>
        );
      })}
    </div>
  );
}

// ---------- Filters ----------

export function SearchInput({
  value,
  onChange,
  placeholder,
  className,
}: {
  value: string;
  onChange: (v: string) => void;
  placeholder: string;
  className?: string;
}) {
  const intl = useIntl();
  return (
    <div className={cn('relative w-full sm:w-64', className)}>
      <Search
        className="pointer-events-none absolute top-1/2 left-2.5 size-4 -translate-y-1/2 text-muted-foreground"
        aria-hidden="true"
      />
      <Input
        type="search"
        value={value}
        aria-label={placeholder}
        placeholder={placeholder}
        className="pr-8 pl-8 [&::-webkit-search-cancel-button]:hidden"
        onChange={(e) => onChange(e.target.value)}
      />
      {value && (
        <button
          type="button"
          className="absolute top-1/2 right-1.5 grid size-6 -translate-y-1/2 place-items-center rounded-md text-muted-foreground hover:bg-muted hover:text-foreground"
          aria-label={intl.formatMessage({ id: 'kit.clearSearch' })}
          onClick={() => onChange('')}
        >
          <X className="size-3.5" />
        </button>
      )}
    </div>
  );
}

/** Search and filters over a list; "Xoá bộ lọc" and the number of results when something is set. */
export function FilterBar({
  children,
  active,
  onClear,
  shown,
  total,
}: {
  children: ReactNode;
  active: boolean;
  onClear: () => void;
  shown: number;
  total: number;
}) {
  return (
    <div className="flex flex-wrap items-center gap-2 border-b px-4 py-3">
      {children}
      {active && (
        <>
          <Button variant="ghost" size="sm" onClick={onClear} className="text-muted-foreground">
            <X />
            <FormattedMessage id="kit.clearFilters" />
          </Button>
        </>
      )}
      <span className="ml-auto text-sm text-muted-foreground" role="status" aria-live="polite">
        <FormattedMessage id="kit.results" values={{ n: shown, total }} />
      </span>
    </div>
  );
}

/** Filters used less often, in a popover; the button counts the ones that are set. */
export function MoreFilters({ count, children }: { count: number; children: ReactNode }) {
  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button variant="outline" className={cn(count > 0 && 'border-primary text-primary')}>
          <SlidersHorizontal />
          <FormattedMessage id="kit.moreFilters" />
          {count > 0 && (
            <span className="grid size-5 place-items-center rounded-full bg-primary text-[11px] text-primary-foreground tabular-nums">
              {count}
            </span>
          )}
        </Button>
      </PopoverTrigger>
      <PopoverContent align="start" className="grid w-72 gap-3">
        {children}
      </PopoverContent>
    </Popover>
  );
}

// ---------- Hints ----------

/** A "?" next to a label: the explanation on hover or focus, not on the page. */
export function Hint({ children, label }: { children: ReactNode; label?: string }) {
  const intl = useIntl();
  // Its own provider, so a hint also works outside the Shell (tests, dialogs).
  return (
    <TooltipProvider delayDuration={150}>
      <Tooltip>
        <TooltipTrigger asChild>
          <button
            type="button"
            className="inline-grid size-5 shrink-0 place-items-center rounded-full align-middle text-muted-foreground hover:text-foreground focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-none"
            aria-label={label ?? intl.formatMessage({ id: 'kit.help' })}
          >
            <CircleHelp className="size-4" />
          </button>
        </TooltipTrigger>
        <TooltipContent className="max-w-xs text-pretty">{children}</TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}

/** Longer guidance ("Cách app dùng mô hình") behind a button. */
export function HelpPopover({
  title,
  children,
  text,
  wide,
}: {
  title: ReactNode;
  children: ReactNode;
  /** The button's words; the title by default. */
  text?: ReactNode;
  wide?: boolean;
}) {
  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button variant="ghost" size="sm" className="text-muted-foreground">
          <Info />
          {text ?? title}
        </Button>
      </PopoverTrigger>
      <PopoverContent align="end" className={cn('grid gap-3 text-sm', wide ? 'w-[28rem]' : 'w-80')}>
        <p className="font-semibold">{title}</p>
        {children}
      </PopoverContent>
    </Popover>
  );
}

// ---------- Version in use ----------

/**
 * The published version as a small badge (owner, 2026-10-21: no "● Bản đang dùng · … · Xuất bản …"
 * banner on the page). The version id, when it was published and the rest are in its popover, and
 * in its tooltip for a quick look.
 */
export function VersionBadge({
  version,
  details = [],
  label,
}: {
  /** The version id; null: nothing published yet. */
  version: string | null;
  /** Lines under the id: "Xuất bản 19:31 18/10/2026", "35 tình huống", the reviewer. */
  details?: string[];
  /** The badge's words; "Đang dùng" by default. */
  label?: ReactNode;
}) {
  const intl = useIntl();
  if (!version) {
    return (
      <span className="inline-flex h-7 items-center rounded-full border px-2.5 text-xs font-medium text-muted-foreground">
        <FormattedMessage id="kit.version.none" />
      </span>
    );
  }
  const title = [
    intl.formatMessage({ id: 'kit.version.title' }, { v: version }),
    ...details.filter(Boolean),
  ].join(' · ');
  return (
    <Popover>
      <PopoverTrigger asChild>
        <button
          type="button"
          title={title}
          aria-label={title}
          className="inline-flex h-7 shrink-0 items-center gap-1.5 rounded-full border border-success/30 bg-success/10 px-2.5 text-xs font-medium text-success outline-none hover:bg-success/15 focus-visible:ring-[3px] focus-visible:ring-ring/50"
        >
          <span className="size-1.5 rounded-full bg-success" aria-hidden="true" />
          {label ?? <FormattedMessage id="kit.version.inUse" />}
          <Info className="size-3.5 opacity-70" aria-hidden="true" />
        </button>
      </PopoverTrigger>
      <PopoverContent align="start" className="grid w-72 gap-1.5 text-sm">
        <p className="font-semibold">
          <FormattedMessage id="kit.version.heading" />
        </p>
        <p className="font-mono text-[13px] break-all">{version}</p>
        {details.filter(Boolean).map((d) => (
          <p key={d} className="text-muted-foreground">
            {d}
          </p>
        ))}
      </PopoverContent>
    </Popover>
  );
}

// ---------- Notices ----------

export type NoticeTone = 'info' | 'ok' | 'warn' | 'error';
const noticeIcon: Record<NoticeTone, LucideIcon> = {
  info: Info,
  ok: CircleCheck,
  warn: TriangleAlert,
  error: CircleAlert,
};
const noticeClass: Record<NoticeTone, string> = {
  info: 'border-primary/30 bg-accent/50 text-foreground [&>svg]:text-primary',
  ok: 'border-success/30 bg-success/5 [&>svg]:text-success',
  warn: 'border-warning/40 bg-warning/5 [&>svg]:text-warning',
  error: 'border-destructive/40 bg-destructive/5 text-destructive [&>svg]:text-destructive',
};

export function Notice({
  tone = 'info',
  title,
  children,
  action,
  className,
}: {
  tone?: NoticeTone;
  title?: ReactNode;
  children?: ReactNode;
  action?: ReactNode;
  className?: string;
}) {
  const Icon = noticeIcon[tone];
  return (
    <Alert
      role={tone === 'error' || tone === 'warn' ? 'alert' : 'status'}
      className={cn(noticeClass[tone], className)}
    >
      <Icon />
      {title && <AlertTitle className="line-clamp-none">{title}</AlertTitle>}
      {(children || action) && (
        <AlertDescription
          className={cn('text-current/85', action && 'flex flex-wrap items-center gap-x-4 gap-y-2')}
        >
          {children && <div className="min-w-0 flex-1">{children}</div>}
          {action}
        </AlertDescription>
      )}
    </Alert>
  );
}

// ---------- Sections ----------

/**
 * A card of related fields. `collapsible` sections fold away what is used less (sources, notes,
 * history); `summary` says what is inside while folded.
 */
export function Section({
  title,
  description,
  hint,
  actions,
  summary,
  collapsible,
  defaultOpen = true,
  open: openProp,
  onOpenChange,
  flush,
  children,
  className,
}: {
  title: ReactNode;
  description?: ReactNode;
  hint?: ReactNode;
  actions?: ReactNode;
  summary?: ReactNode;
  collapsible?: boolean;
  defaultOpen?: boolean;
  /** Controlled folding (e.g. open a section when it holds an error). */
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  /** No inner padding (tables). */
  flush?: boolean;
  children: ReactNode;
  className?: string;
}) {
  const [ownOpen, setOwnOpen] = useState(defaultOpen);
  const open = openProp ?? ownOpen;
  const setOpen = (o: boolean) => {
    setOwnOpen(o);
    onOpenChange?.(o);
  };
  // The hint is a button, so a folding header keeps it outside its trigger button.
  const heading = (withHint: boolean) => (
    <div className="flex min-w-0 flex-1 flex-col gap-0.5 text-left">
      <span className="flex items-center gap-1.5 text-[15px] leading-6 font-semibold">
        {title}
        {withHint && hint && <Hint>{hint}</Hint>}
      </span>
      {description && <span className="text-[13px] text-muted-foreground">{description}</span>}
    </div>
  );
  const body = <div className={cn(!flush && 'px-5 pb-5', flush && 'border-t')}>{children}</div>;
  if (!collapsible) {
    return (
      <section className={cn('rounded-xl border bg-card text-card-foreground', className)}>
        <div className="flex flex-wrap items-start gap-3 px-5 py-4">
          {heading(true)}
          {actions && <div className="flex flex-wrap items-center gap-2">{actions}</div>}
        </div>
        {body}
      </section>
    );
  }
  return (
    <Collapsible
      open={open}
      onOpenChange={setOpen}
      className={cn('rounded-xl border bg-card text-card-foreground', className)}
      asChild
    >
      <section>
        <div className="flex flex-wrap items-start gap-3 px-5 py-4">
          <CollapsibleTrigger className="flex min-w-0 flex-1 items-start gap-2 rounded-md text-left outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50">
            <ChevronDown
              className={cn(
                'mt-1 size-4 shrink-0 text-muted-foreground transition-transform',
                !open && '-rotate-90',
              )}
              aria-hidden="true"
            />
            {heading(false)}
            {!open && summary && (
              <span className="mt-0.5 shrink-0 text-[13px] text-muted-foreground">{summary}</span>
            )}
          </CollapsibleTrigger>
          {hint && (
            <span className="mt-0.5">
              <Hint>{hint}</Hint>
            </span>
          )}
          {open && actions && <div className="flex flex-wrap items-center gap-2">{actions}</div>}
        </div>
        <CollapsibleContent>{body}</CollapsibleContent>
      </section>
    </Collapsible>
  );
}

// ---------- Fields ----------

/** Label, optional "?" hint and counter, the control, then help or an error under it. */
export function Field({
  label,
  htmlFor,
  hint,
  counter,
  help,
  error,
  children,
  className,
}: {
  label: ReactNode;
  htmlFor?: string;
  hint?: ReactNode;
  counter?: { n: number; max: number };
  help?: ReactNode;
  error?: ReactNode;
  children: ReactNode;
  className?: string;
}) {
  const generatedId = useId();
  type ControlProps = {
    id?: string;
    'aria-describedby'?: string;
    'aria-invalid'?: boolean | 'true' | 'false';
  };
  const control =
    isValidElement<ControlProps>(children) &&
    (children.type === Input ||
      children.type === Textarea ||
      (typeof children.type === 'string' &&
        ['input', 'textarea', 'select'].includes(children.type)))
      ? (children as ReactElement<ControlProps>)
      : null;
  const id = htmlFor ?? control?.props.id ?? generatedId;
  const descriptionId = `${id}-description`;
  const describedBy =
    [control?.props['aria-describedby'], (error || help) && descriptionId]
      .filter(Boolean)
      .join(' ') || undefined;
  const input = control
    ? cloneElement(control, {
        id,
        'aria-invalid': error ? true : control.props['aria-invalid'],
        'aria-describedby': describedBy,
      })
    : children;
  const over = counter ? counter.n > counter.max : false;
  return (
    <div className={cn('grid min-w-0 gap-1.5', className)}>
      <div className="flex min-h-5 items-start gap-1.5">
        <Label htmlFor={id} className="min-w-0 text-sm leading-5 font-medium">
          {label}
        </Label>
        {hint && <Hint>{hint}</Hint>}
        {counter && (
          <span
            className={cn(
              'ml-auto text-xs tabular-nums',
              over ? 'font-medium text-destructive' : 'text-muted-foreground',
            )}
          >
            {counter.n}/{counter.max}
          </span>
        )}
      </div>
      {input}
      {error ? (
        <p id={descriptionId} className="text-sm text-destructive" role="alert">
          {error}
        </p>
      ) : (
        help && (
          <p id={descriptionId} className="text-sm leading-5 text-muted-foreground">
            {help}
          </p>
        )
      )}
    </div>
  );
}

// ---------- Editor bar and layout ----------

/**
 * The bar on top of an editor; it stays under the portal header while the form scrolls: back,
 * what is being edited and its status, whether it is saved, "Lưu", the next step and "⋯".
 */
export function EditorBar({
  backLabel,
  onBack,
  title,
  badges,
  dirty,
  saving,
  onSave,
  saveLabel,
  canSave = true,
  actions,
  menu,
  titleAs = 'h1',
}: {
  backLabel: ReactNode;
  onBack: () => void;
  title: ReactNode;
  badges?: ReactNode;
  dirty?: boolean;
  saving?: boolean;
  /** Absent: nothing to save here (read-only, or saving happens elsewhere). */
  onSave?: () => void;
  saveLabel?: ReactNode;
  canSave?: boolean;
  /** The next workflow step(s), shown as buttons. */
  actions?: ReactNode;
  menu?: MenuItem[];
  /** "h2" when the page already has its own title. */
  titleAs?: 'h1' | 'h2';
}) {
  const Title = titleAs;
  return (
    <div className="sticky top-14 z-10 -mx-4 mb-6 border-b bg-background/95 px-4 py-3 backdrop-blur supports-[backdrop-filter]:bg-background/80 md:-mx-8 md:px-8">
      <div className="flex flex-wrap items-center gap-x-3 gap-y-2">
        <Button variant="ghost" size="sm" className="-ml-2 text-muted-foreground" onClick={onBack}>
          <ArrowLeft />
          <span className="max-sm:sr-only">{backLabel}</span>
        </Button>
        <div className="flex min-w-0 flex-1 items-center gap-2">
          <Title className="min-w-0 truncate text-lg leading-7 font-semibold tracking-tight">
            {title}
          </Title>
          {badges && <div className="flex shrink-0 flex-wrap items-center gap-1.5">{badges}</div>}
        </div>
        <div className="flex flex-wrap items-center justify-end gap-2">
          {onSave && (
            <span
              className={cn(
                'flex items-center gap-1.5 text-[13px]',
                dirty ? 'text-warning' : 'text-muted-foreground',
              )}
              role="status"
            >
              {dirty && <span className="size-2 rounded-full bg-warning" aria-hidden="true" />}
              <FormattedMessage id={saving ? 'kit.saving' : dirty ? 'kit.unsaved' : 'kit.saved'} />
            </span>
          )}
          {onSave && (
            <Button
              variant={dirty ? 'default' : 'outline'}
              disabled={!dirty || saving || !canSave}
              onClick={onSave}
            >
              {saveLabel ?? <FormattedMessage id="kit.save" />}
            </Button>
          )}
          {actions}
          {menu && <OverflowMenu items={menu} />}
        </div>
      </div>
    </div>
  );
}

/** The form, and a preview that stays in view on wide screens. */
export function EditorLayout({ children, aside }: { children: ReactNode; aside?: ReactNode }) {
  return (
    // Both tracks are minmax(0, …): a wide child (a table, a long unbroken line) scrolls or wraps
    // inside its own card instead of widening the column under the preview (notifications editor,
    // 2026-10-23).
    <div
      className={cn(
        'grid grid-cols-[minmax(0,1fr)] items-start gap-6',
        aside && 'xl:grid-cols-[minmax(0,1fr)_minmax(340px,400px)]',
      )}
    >
      <div className="grid min-w-0 grid-cols-[minmax(0,1fr)] gap-4">{children}</div>
      {aside && (
        <aside className="no-scrollbar grid min-w-0 gap-4 xl:sticky xl:top-[8.5rem] xl:max-h-[calc(100svh-9.5rem)] xl:overflow-y-auto xl:overscroll-contain">
          {aside}
        </aside>
      )}
    </div>
  );
}

/** Warns before the tab is closed or reloaded with unsaved changes. */
export function useLeaveGuard(dirty: boolean) {
  useEffect(() => {
    if (!dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);
}

// ---------- Confirm ----------

/** A yes/no question in a dialog (instead of the browser's confirm box). */
export function ConfirmDialog({
  open,
  title,
  children,
  confirmLabel,
  destructive,
  onConfirm,
  onClose,
}: {
  open: boolean;
  title: ReactNode;
  children?: ReactNode;
  confirmLabel: ReactNode;
  destructive?: boolean;
  onConfirm: () => void;
  onClose: () => void;
}) {
  const intl = useIntl();
  const id = useId();
  if (typeof document === 'undefined') return null;
  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent
        className="sm:max-w-md"
        aria-describedby={children ? id : undefined}
        closeLabel={intl.formatMessage({ id: 'action.close' })}
      >
        <DialogTitle>{title}</DialogTitle>
        {children && (
          <DialogDescription id={id} asChild>
            <div className="text-sm text-muted-foreground">{children}</div>
          </DialogDescription>
        )}
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            <FormattedMessage id="action.cancel" />
          </Button>
          <Button
            variant={destructive ? 'destructive' : 'default'}
            onClick={() => {
              onConfirm();
              onClose();
            }}
          >
            {confirmLabel}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

type Ask = {
  title: ReactNode;
  body?: ReactNode;
  confirmLabel: ReactNode;
  destructive?: boolean;
  onConfirm: () => void;
};

/** `ask({...})` opens the dialog; render `dialog` once in the screen. */
export function useConfirm() {
  const [ask, setAsk] = useState<Ask | null>(null);
  const dialog = (
    <ConfirmDialog
      open={!!ask}
      title={ask?.title}
      confirmLabel={ask?.confirmLabel}
      destructive={ask?.destructive}
      onConfirm={() => ask?.onConfirm()}
      onClose={() => setAsk(null)}
    >
      {ask?.body}
    </ConfirmDialog>
  );
  return { ask: setAsk, dialog };
}

/**
 * Leaving an editor with changes asks first (the back button) and the browser warns on reload or
 * close. Render `dialog` once in the editor.
 */
export function useGuardedLeave(changed: boolean, leave: () => void) {
  const intl = useIntl();
  const { ask, dialog } = useConfirm();
  useLeaveGuard(changed);
  const guarded = () =>
    changed
      ? ask({
          title: intl.formatMessage({ id: 'kit.leave' }),
          confirmLabel: intl.formatMessage({ id: 'kit.leaveConfirm' }),
          destructive: true,
          onConfirm: leave,
        })
      : leave();
  return { leave: guarded, dialog };
}

// ---------- Empty ----------

export function EmptyState({
  icon: Icon,
  title,
  children,
  action,
}: {
  icon?: LucideIcon;
  title: ReactNode;
  children?: ReactNode;
  action?: ReactNode;
}) {
  return (
    <div className="grid justify-items-center gap-2 px-6 py-12 text-center">
      {Icon && (
        <span className="mb-1 grid size-11 place-items-center rounded-full bg-muted text-muted-foreground">
          <Icon className="size-5" />
        </span>
      )}
      <p className="font-semibold">{title}</p>
      {children && <p className="max-w-md text-sm text-muted-foreground">{children}</p>}
      {action && <div className="mt-2">{action}</div>}
    </div>
  );
}
