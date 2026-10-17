import {
  firstAidLimits,
  firstAidPackSchema,
  type FirstAidPack,
  type FirstAidSituation,
  type FirstAidText,
} from '@child-life/contracts';
import {
  ChevronDown,
  ChevronsDownUp,
  ChevronsUpDown,
  ImageIcon,
  Plus,
  Trash2,
  Upload,
} from 'lucide-react';
import {
  createContext,
  useContext,
  useEffect,
  useId,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '@/components/ui/collapsible';
import { Input } from '@/components/ui/input';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Textarea } from '@/components/ui/textarea';
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group';
import { TooltipProvider } from '@/components/ui/tooltip';
import { cn } from '@/lib/utils';
import { ApiError, useApi, type Api, type FirstAidImage } from '../api';
import {
  EmptyState,
  Field,
  Hint,
  OverflowMenu,
  SearchInput,
  Section,
  useConfirm,
} from '../content-kit';
import { Modal, errorMessageId } from '../ui';
import { CheckRow, FieldSelect, FilePicker, IconButton } from './form-controls';

/**
 * The Sơ cứu pack editor (D-058, P-141): one situation at a time, vi and en side by side (D-012),
 * plus the guide-wide settings (emergency number, groups, quick search). The whole pack is checked
 * with `firstAidPackSchema` in the browser before "Lưu nháp"; the server checks it again and also
 * refuses a pack that points at a picture that was never uploaded (`image-missing`).
 * Laid out with the content kit (D-063): sections in the order an editor works, steps as compact
 * cards that fold to one line, technical ids under "Nâng cao".
 */

export type Variant = FirstAidSituation['variants'][number];
export type Step = Variant['steps'][number];
export type Callout = Variant['callouts'][number];
export type Category = FirstAidPack['categories'][number];
type AgeRange = FirstAidSituation['ageMonths'];
type Path = Array<string | number>;
/** Applies a change to a copy of the working pack. */
export type Edit = (fn: (pack: FirstAidPack) => void) => void;

// ---------- Validation ----------

export interface Issue {
  path: Path;
  code: string;
  message: string;
  origin?: string;
  minimum?: number;
  maximum?: number;
  expected?: string;
}

export const pathKey = (path: ReadonlyArray<PropertyKey>) => path.map(String).join('.');

/** Runs the shared schema; issues keyed by their dotted path ("situations.2.lead.en"). */
export function validatePack(pack: FirstAidPack): {
  ok: boolean;
  issues: Map<string, Issue>;
  list: Issue[];
} {
  const res = firstAidPackSchema.safeParse(pack);
  if (res.success) return { ok: true, issues: new Map(), list: [] };
  const list: Issue[] = res.error.issues.map((i) => {
    const raw = i as unknown as Record<string, unknown>;
    return {
      path: i.path.map((p) => (typeof p === 'number' ? p : String(p))),
      code: i.code,
      message: i.message,
      origin: typeof raw.origin === 'string' ? raw.origin : undefined,
      minimum: typeof raw.minimum === 'number' ? raw.minimum : undefined,
      maximum: typeof raw.maximum === 'number' ? raw.maximum : undefined,
      expected: typeof raw.expected === 'string' ? raw.expected : undefined,
    };
  });
  const issues = new Map<string, Issue>();
  for (const i of list) if (!issues.has(pathKey(i.path))) issues.set(pathKey(i.path), i);
  return { ok: false, issues, list };
}

const imageKeys = new Set(['icon', 'hero', 'image']);

/** A readable message for one schema issue (the schema's own text is for engineers). */
export function issueText(intl: IntlShape, issue: Issue): string {
  const last = issue.path[issue.path.length - 1];
  const f = (id: string, values?: Record<string, number>) =>
    intl.formatMessage({ id: `firstAid.err.${id}` }, values);
  if (typeof last === 'string' && imageKeys.has(last)) return f('image');
  if (issue.code === 'custom') {
    if (issue.message === 'unknown category') return f('category');
    if (issue.message === 'duplicate id') return f('duplicate');
    if (issue.message === 'variant labels') return f('variantLabels');
    return f('invalid');
  }
  const min = issue.minimum ?? 0;
  const max = issue.maximum ?? 0;
  if (issue.code === 'too_small') {
    if (issue.origin === 'string') return min <= 1 ? f('required') : f('tooShort', { min });
    if (issue.origin === 'array') return f('tooFew', { min });
    return f('min', { min });
  }
  if (issue.code === 'too_big') {
    if (issue.origin === 'string') return f('tooLong', { max });
    if (issue.origin === 'array') return f('tooMany', { max });
    return f('max', { max });
  }
  if (issue.code === 'invalid_format') return f('format');
  if (issue.code === 'invalid_type')
    return issue.expected === 'number' ? f('number') : f('required');
  return f('invalid');
}

/** Validates, then saves the whole pack as the open draft (or starts one). */
export async function saveFirstAidDraft(
  api: Api,
  pack: FirstAidPack,
  notes: string,
): Promise<{ ok: true; versionId: string } | { ok: false; issues: Issue[] }> {
  const check = validatePack(pack);
  if (!check.ok) return { ok: false, issues: check.list };
  const res = await api.call<{ versionId: string }>('staffFirstAidDraft', {
    pack,
    notes: notes.trim(),
  });
  return { ok: true, versionId: res.versionId };
}

// ---------- Blank content and list helpers ----------

const loc = (): FirstAidText => ({ vi: '', en: '' });

export function blankStep(): Step {
  return { title: loc(), body: loc(), image: null, chips: [], count: null, cprRole: null };
}

export function blankCallout(): Callout {
  return { tone: 'warning', heading: loc(), items: [loc()] };
}

export function blankVariant(id: string): Variant {
  return {
    id,
    label: null,
    ageMonths: null,
    hero: null,
    banner: null,
    steps: [blankStep()],
    callouts: [],
    cpr: null,
  };
}

/** A free id like "tinh-huong-3" (ids are the app's link to a page; they never change once live). */
export function freeId(taken: Iterable<string>, base: string): string {
  const used = new Set(taken);
  for (let n = 1; ; n++) {
    const id = `${base}-${n}`;
    if (!used.has(id)) return id;
  }
}

export function blankSituation(pack: FirstAidPack): FirstAidSituation {
  return {
    id: freeId(
      pack.situations.map((s) => s.id),
      'tinh-huong',
    ),
    code: null,
    category: pack.categories[0]?.id ?? '',
    emergency: false,
    monitoring: false,
    title: loc(),
    lead: loc(),
    keywords: [],
    icon: '',
    hero: '',
    ageMonths: null,
    variantKind: null,
    variants: [blankVariant('mac-dinh')],
    tool: null,
  };
}

/** Where to start when nothing was ever published (first run). */
export function starterPack(): FirstAidPack {
  const pack: FirstAidPack = {
    emergencyNumber: '115',
    categories: [
      { id: 'urgent', title: { vi: 'Khẩn cấp', en: 'Urgent' }, layout: 'grid', tone: 'danger' },
    ],
    situations: [],
    cpr: [],
    quickSearch: [],
    review: null,
  };
  pack.situations.push(blankSituation(pack));
  return pack;
}

/** Moves item `i` by `by` places (−1 up, +1 down); out of range does nothing. */
export function moveItem<T>(list: T[], i: number, by: number): void {
  const j = i + by;
  if (j < 0 || j >= list.length) return;
  const [item] = list.splice(i, 1);
  list.splice(j, 0, item!);
}

/** "Vỗ lưng ở bé.PNG" → "vo-lung-o-be"; icons get the "icon-" prefix the server looks for. */
export function kebabName(fileName: string, icon: boolean): string {
  const base = fileName
    .replace(/\.[a-z0-9]+$/i, '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[đĐ]/g, 'd')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
  const stem = icon ? base.replace(/^icon-?/, '') : base;
  const name = (icon ? `icon-${stem}` : stem).slice(0, 40).replace(/-+$/, '');
  return name.length >= 2 ? name : icon ? 'icon-anh' : 'anh';
}

export const imageNameOk = (name: string) => /^[a-z0-9-]{2,40}$/.test(name);

/** Base64 of a file, without the data-URL prefix. */
export async function fileToBase64(file: Blob): Promise<string> {
  const bytes = new Uint8Array(await file.arrayBuffer());
  let s = '';
  for (let i = 0; i < bytes.length; i += 0x8000) {
    s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  }
  return btoa(s);
}

// ---------- Contexts: issues to show, the picture library ----------

export const IssuesContext = createContext<{ issues: Map<string, Issue>; show: boolean }>({
  issues: new Map(),
  show: false,
});

function useIssue(path: Path | null): string | undefined {
  const intl = useIntl();
  const { issues, show } = useContext(IssuesContext);
  if (!show || !path) return undefined;
  const hit = issues.get(pathKey(path));
  return hit ? issueText(intl, hit) : undefined;
}

/** Whether a shown issue sits at or under a path (a folded card or section opens for it). */
function useIssueUnder(): (path: Path) => boolean {
  const { issues, show } = useContext(IssuesContext);
  return (path) => {
    if (!show) return false;
    const key = pathKey(path);
    for (const k of issues.keys()) if (k === key || k.startsWith(`${key}.`)) return true;
    return false;
  };
}

/**
 * Scrolls to the field of an issue (and focuses it when it is a control). Fields carry their
 * path in `data-path`; the deepest one that is on the page wins.
 */
export function revealPath(path: Path) {
  if (typeof document === 'undefined') return;
  for (let n = path.length; n > 0; n--) {
    const key = pathKey(path.slice(0, n));
    const el = document.querySelector<HTMLElement>(`[data-path="${CSS.escape(key)}"]`);
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'center' });
      if (el.matches('input, textarea, button')) el.focus({ preventScroll: true });
      return;
    }
  }
}

export const LibraryContext = createContext<{
  images: FirstAidImage[];
  canUpload: boolean;
  onUploaded: (img: FirstAidImage) => void;
}>({ images: [], canUpload: false, onUploaded: () => undefined });

function FieldError({ text }: { text?: string }) {
  return text ? <p className="text-xs text-destructive">{text}</p> : null;
}

const labelClass = 'flex min-h-5 items-center gap-1.5 text-[13px] font-medium';

// ---------- Fields ----------

export function LocField({
  label,
  value,
  onChange,
  path,
  multiline,
  max,
  help,
  hint,
  counter,
}: {
  label: ReactNode;
  value: FirstAidText;
  onChange: (v: FirstAidText) => void;
  path: Path;
  multiline?: boolean;
  max: number;
  /** A line under the two boxes. */
  help?: ReactNode;
  /** A "?" next to the label (needs a TooltipProvider above). */
  hint?: ReactNode;
  /** Shows "n/max" for each language (short texts shown on cards). */
  counter?: boolean;
}) {
  const intl = useIntl();
  const id = useId();
  const errVi = useIssue([...path, 'vi']);
  const errEn = useIssue([...path, 'en']);
  const errAll = useIssue(path);
  return (
    <fieldset className="grid min-w-0 gap-1.5" data-path={pathKey(path)}>
      <legend className={cn(labelClass, 'mb-1.5')}>
        {label}
        {hint && <Hint>{hint}</Hint>}
      </legend>
      <div className="grid gap-x-3 gap-y-2 sm:grid-cols-2">
        {(['vi', 'en'] as const).map((lang) => {
          const err = lang === 'vi' ? errVi : errEn;
          const props = {
            id: `${id}-${lang}`,
            value: value[lang],
            maxLength: max,
            'data-path': pathKey([...path, lang]),
            'aria-invalid': err ? true : undefined,
            onChange: (e: { target: { value: string } }) =>
              onChange({ ...value, [lang]: e.target.value }),
          };
          return (
            <div key={lang} className="grid min-w-0 content-start gap-1">
              <div className="flex items-center gap-2">
                <label htmlFor={`${id}-${lang}`} className="text-xs text-muted-foreground">
                  {intl.formatMessage({ id: `firstAid.lang.${lang}` })}
                </label>
                {counter && (
                  <span
                    className={cn(
                      'ml-auto text-xs tabular-nums',
                      value[lang].length > max ? 'text-destructive' : 'text-muted-foreground',
                    )}
                  >
                    {value[lang].length}/{max}
                  </span>
                )}
              </div>
              {multiline ? <Textarea rows={3} {...props} /> : <Input {...props} />}
              <FieldError text={err} />
            </div>
          );
        })}
      </div>
      <FieldError text={errAll} />
      {help && <p className="text-xs text-muted-foreground">{help}</p>}
    </fieldset>
  );
}

/** A text that may be absent (variant label, banner): both languages empty = none. */
export function OptionalLocField(
  props: Omit<Parameters<typeof LocField>[0], 'value' | 'onChange'> & {
    value: FirstAidText | null;
    onChange: (v: FirstAidText | null) => void;
  },
) {
  return (
    <LocField
      {...props}
      value={props.value ?? { vi: '', en: '' }}
      onChange={(v) => props.onChange(!v.vi && !v.en ? null : v)}
      help={props.help ?? <FormattedMessage id="firstAid.optionalText" />}
    />
  );
}

/** Keywords, callout items, quick searches: rows of vi + en. */
export function LocList({
  label,
  items,
  onChange,
  path,
  max,
  itemMax,
  addLabel,
}: {
  label: ReactNode;
  items: FirstAidText[];
  onChange: (items: FirstAidText[]) => void;
  path: Path;
  max: number;
  itemMax: number;
  addLabel: ReactNode;
}) {
  const intl = useIntl();
  const errList = useIssue(path);
  return (
    <fieldset className="grid min-w-0 gap-2" data-path={pathKey(path)}>
      <legend className={cn(labelClass, 'mb-1.5')}>
        {label}
        <span className="text-xs font-normal text-muted-foreground tabular-nums">
          {items.length}/{max}
        </span>
      </legend>
      {items.map((it, i) => (
        <LocRow
          key={i}
          value={it}
          path={[...path, i]}
          max={itemMax}
          onChange={(v) => onChange(items.map((x, j) => (j === i ? v : x)))}
          onRemove={() => onChange(items.filter((_, j) => j !== i))}
          removeLabel={intl.formatMessage({ id: 'firstAid.remove' })}
        />
      ))}
      <FieldError text={errList} />
      <div>
        <AddButton disabled={items.length >= max} onClick={() => onChange([...items, loc()])}>
          {addLabel}
        </AddButton>
      </div>
    </fieldset>
  );
}

function AddButton({
  children,
  disabled,
  onClick,
}: {
  children: ReactNode;
  disabled?: boolean;
  onClick: () => void;
}) {
  return (
    <Button
      type="button"
      variant="ghost"
      size="sm"
      className="-ml-2 text-primary hover:text-primary"
      disabled={disabled}
      onClick={onClick}
    >
      <Plus />
      {children}
    </Button>
  );
}

function LocRow({
  value,
  path,
  max,
  onChange,
  onRemove,
  removeLabel,
}: {
  value: FirstAidText;
  path: Path;
  max: number;
  onChange: (v: FirstAidText) => void;
  onRemove: () => void;
  removeLabel: string;
}) {
  const intl = useIntl();
  const errVi = useIssue([...path, 'vi']);
  const errEn = useIssue([...path, 'en']);
  return (
    <div className="grid min-w-0 items-start gap-2 sm:grid-cols-[minmax(0,1fr)_minmax(0,1fr)_auto]">
      {(['vi', 'en'] as const).map((lang) => {
        const err = lang === 'vi' ? errVi : errEn;
        return (
          <div key={lang} className="grid min-w-0 gap-1">
            <Input
              value={value[lang]}
              maxLength={max}
              data-path={pathKey([...path, lang])}
              aria-invalid={err ? true : undefined}
              placeholder={intl.formatMessage({ id: `firstAid.lang.${lang}` })}
              aria-label={intl.formatMessage({ id: `firstAid.lang.${lang}` })}
              onChange={(e) => onChange({ ...value, [lang]: e.target.value })}
            />
            <FieldError text={err} />
          </div>
        );
      })}
      <IconButton icon="remove" label={removeLabel} onClick={onRemove} />
    </div>
  );
}

function TextField({
  label,
  value,
  onChange,
  path,
  help,
  hint,
  mono,
  className,
}: {
  label: ReactNode;
  value: string;
  onChange: (v: string) => void;
  path: Path;
  help?: ReactNode;
  hint?: ReactNode;
  mono?: boolean;
  className?: string;
}) {
  const id = useId();
  const err = useIssue(path);
  return (
    <Field label={label} htmlFor={id} hint={hint} help={help} error={err} className={className}>
      <Input
        id={id}
        className={mono ? 'font-mono' : undefined}
        value={value}
        data-path={pathKey(path)}
        aria-invalid={err ? true : undefined}
        onChange={(e) => onChange(e.target.value)}
      />
    </Field>
  );
}

const num = (s: string) => (s.trim() === '' ? Number.NaN : Number(s));

function NumField({
  label,
  value,
  onChange,
  path,
  nullable,
  placeholder,
  hint,
}: {
  label: ReactNode;
  value: number | null;
  onChange: (v: number | null) => void;
  path: Path;
  nullable?: boolean;
  placeholder?: string;
  hint?: ReactNode;
}) {
  const id = useId();
  const err = useIssue(path);
  return (
    <Field label={label} htmlFor={id} hint={hint} error={err}>
      <Input
        id={id}
        className="w-28 tabular-nums"
        inputMode="numeric"
        placeholder={placeholder}
        data-path={pathKey(path)}
        aria-invalid={err ? true : undefined}
        value={value === null || Number.isNaN(value) ? '' : value}
        onChange={(e) => onChange(nullable && e.target.value === '' ? null : num(e.target.value))}
      />
    </Field>
  );
}

function SelectField<T extends string>({
  label,
  value,
  options,
  onChange,
  path,
  hint,
  className,
}: {
  label: ReactNode;
  value: T;
  options: Array<{ value: T; label: string }>;
  onChange: (v: T) => void;
  path: Path;
  hint?: ReactNode;
  className?: string;
}) {
  const id = useId();
  const err = useIssue(path);
  return (
    <Field label={label} htmlFor={id} hint={hint} error={err} className={className}>
      <div data-path={pathKey(path)} className="min-w-0">
        <FieldSelect id={id} value={value} options={options} onChange={onChange} />
      </div>
    </Field>
  );
}

/** "Chỉ cho bé từ … đến … tháng" (to empty = no upper bound). */
function AgeField({
  label,
  value,
  onChange,
  path,
}: {
  label: ReactNode;
  value: AgeRange;
  onChange: (v: AgeRange) => void;
  path: Path;
}) {
  const err = useIssue(path);
  return (
    <div className="grid min-w-0 gap-2" data-path={pathKey(path)}>
      <CheckRow
        label={label}
        checked={value !== null}
        onChange={(on) => onChange(on ? { from: 0, to: 12 } : null)}
      />
      {value && (
        <div className="flex flex-wrap items-start gap-3 pl-6">
          <NumField
            label={<FormattedMessage id="firstAid.age.from" />}
            value={value.from}
            path={[...path, 'from']}
            onChange={(v) => onChange({ ...value, from: v ?? Number.NaN })}
          />
          <NumField
            label={<FormattedMessage id="firstAid.age.to" />}
            value={value.to}
            nullable
            placeholder="∞"
            hint={<FormattedMessage id="firstAid.age.help" />}
            path={[...path, 'to']}
            onChange={(v) => onChange({ ...value, to: v })}
          />
        </div>
      )}
      <FieldError text={err} />
    </div>
  );
}

// ---------- Pictures ----------

export const isIcon = (id: string) => id.startsWith('icon-');

export function ImageThumb({ id, size = 64 }: { id: string | null; size?: number }) {
  const { images } = useContext(LibraryContext);
  const url = id ? images.find((i) => i.id === id)?.url : undefined;
  return url ? (
    <img className="fa-thumb" src={url} alt="" width={size} height={size} loading="lazy" />
  ) : (
    <span className="fa-thumb fa-thumb--empty" style={{ width: size, height: size }} aria-hidden>
      {id ? '!' : '—'}
    </span>
  );
}

export function ImageField({
  label,
  value,
  onChange,
  path,
  kind,
  nullable,
}: {
  label: ReactNode;
  value: string | null;
  onChange: (v: string | null) => void;
  path: Path;
  kind: 'icon' | 'picture';
  nullable?: boolean;
}) {
  const intl = useIntl();
  const { images } = useContext(LibraryContext);
  const err = useIssue(path);
  const [open, setOpen] = useState(false);
  const missing = !!value && !images.some((i) => i.id === value);
  return (
    <div className="grid min-w-0 content-start gap-1.5" data-path={pathKey(path)}>
      <span className={labelClass}>{label}</span>
      <div
        className={cn(
          'flex min-w-0 items-center gap-3 rounded-lg border bg-background p-2',
          (err || missing) && 'border-destructive/60',
        )}
      >
        <ImageThumb id={value || null} size={44} />
        <div className="grid min-w-0 flex-1 gap-0.5">
          <span
            className="truncate font-mono text-xs text-muted-foreground"
            title={value || undefined}
          >
            {value || <FormattedMessage id="firstAid.noImage" />}
          </span>
          {missing && (
            <span className="text-xs text-destructive">
              <FormattedMessage id="firstAid.imageNotInLibrary" />
            </span>
          )}
        </div>
        <Button type="button" variant="outline" size="sm" onClick={() => setOpen(true)}>
          <FormattedMessage id={value ? 'firstAid.changeImage' : 'firstAid.pickImage'} />
        </Button>
        {nullable && value && (
          <IconButton
            icon="remove"
            label={intl.formatMessage({ id: 'firstAid.clearImage' })}
            onClick={() => onChange(null)}
          />
        )}
      </div>
      <FieldError text={err} />
      {open && (
        <ImagePicker
          kind={kind}
          value={value}
          onClose={() => setOpen(false)}
          onPick={(id) => {
            onChange(id);
            setOpen(false);
          }}
        />
      )}
    </div>
  );
}

export type ImageFilter = 'picture' | 'icon' | 'all';

export function filterImages(images: FirstAidImage[], filter: ImageFilter, query: string) {
  const q = query.trim().toLowerCase();
  return images.filter(
    (i) => (filter === 'all' || (filter === 'icon') === isIcon(i.id)) && (!q || i.id.includes(q)),
  );
}

/** Tất cả / Ảnh minh hoạ / Biểu tượng. */
export function ImageKindFilter({
  value,
  onChange,
  order = ['all', 'picture', 'icon'],
}: {
  value: ImageFilter;
  onChange: (v: ImageFilter) => void;
  order?: ImageFilter[];
}) {
  const intl = useIntl();
  return (
    <ToggleGroup
      type="single"
      variant="outline"
      size="sm"
      value={value}
      aria-label={intl.formatMessage({ id: 'firstAid.imageKind' })}
      onValueChange={(v) => v && onChange(v as ImageFilter)}
    >
      {order.map((f) => (
        <ToggleGroupItem key={f} value={f} className="px-3">
          <FormattedMessage id={`firstAid.filter.${f}`} />
        </ToggleGroupItem>
      ))}
    </ToggleGroup>
  );
}

function ImagePicker({
  kind,
  value,
  onClose,
  onPick,
}: {
  kind: 'icon' | 'picture';
  value: string | null;
  onClose: () => void;
  onPick: (id: string) => void;
}) {
  const intl = useIntl();
  const { images, canUpload } = useContext(LibraryContext);
  const [filter, setFilter] = useState<ImageFilter>(kind);
  const [query, setQuery] = useState('');
  const [uploading, setUploading] = useState(false);
  const shown = filterImages(images, filter, query);
  return (
    <Modal wide title={<FormattedMessage id="firstAid.pickerTitle" />} onClose={onClose}>
      <div className="flex flex-wrap items-center gap-2">
        <ImageKindFilter value={filter} onChange={setFilter} order={['picture', 'icon', 'all']} />
        <SearchInput
          value={query}
          onChange={setQuery}
          placeholder={intl.formatMessage({ id: 'firstAid.searchImages' })}
        />
        {canUpload && (
          <Button
            type="button"
            variant={uploading ? 'secondary' : 'outline'}
            size="sm"
            className="ml-auto"
            aria-expanded={uploading}
            onClick={() => setUploading((u) => !u)}
          >
            <Upload />
            <FormattedMessage id="firstAid.upload.open" />
          </Button>
        )}
      </div>
      {uploading && <UploadBox icon={kind === 'icon'} onDone={(img) => onPick(img.id)} />}
      <div className="max-h-[50vh] min-h-40 overflow-y-auto overscroll-contain">
        <ImageGrid images={shown} selected={value} onPick={onPick} />
      </div>
      <div className="flex justify-end gap-2">
        <Button type="button" variant="outline" onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
      </div>
    </Modal>
  );
}

export function ImageGrid({
  images,
  selected,
  onPick,
  usage,
}: {
  images: FirstAidImage[];
  selected?: string | null;
  onPick?: (id: string) => void;
  usage?: Map<string, number>;
}) {
  if (!images.length) {
    return <EmptyState icon={ImageIcon} title={<FormattedMessage id="firstAid.noImages" />} />;
  }
  return (
    <ul className="grid grid-cols-[repeat(auto-fill,minmax(128px,1fr))] gap-3">
      {images.map((img) => {
        const on = img.id === selected;
        const used = usage?.get(img.id) ?? 0;
        const body = (
          <>
            <span className="block aspect-square overflow-hidden rounded-md bg-muted">
              <img src={img.url} alt="" loading="lazy" className="size-full object-contain" />
            </span>
            <span className="truncate font-mono text-[11px] leading-4" title={img.id}>
              {img.id}
            </span>
            {usage && (
              <span
                className={cn(
                  'text-xs tabular-nums',
                  used ? 'text-muted-foreground' : 'text-muted-foreground/70 italic',
                )}
              >
                <FormattedMessage id="firstAid.usedTimes" values={{ n: used }} />
              </span>
            )}
          </>
        );
        const box = 'grid w-full min-w-0 content-start gap-1.5 rounded-lg border bg-card p-2';
        return (
          <li key={img.id} className="min-w-0">
            {onPick ? (
              <button
                type="button"
                aria-pressed={on}
                className={cn(
                  box,
                  'text-left transition-colors outline-none hover:border-primary/50 focus-visible:ring-[3px] focus-visible:ring-ring/50',
                  on && 'border-primary bg-accent/50 ring-1 ring-primary/40',
                )}
                onClick={() => onPick(img.id)}
              >
                {body}
              </button>
            ) : (
              <div className={box}>{body}</div>
            )}
          </li>
        );
      })}
    </ul>
  );
}

const imageTypes = ['image/png', 'image/jpeg', 'image/webp'];

/** Upload one picture: the name comes from the file (kebab-case), "icon-…" for pictograms. */
export function UploadBox({
  icon: iconDefault = false,
  onDone,
}: {
  icon?: boolean;
  onDone?: (img: FirstAidImage) => void;
}) {
  const api = useApi();
  const intl = useIntl();
  const id = useId();
  const { onUploaded } = useContext(LibraryContext);
  const [file, setFile] = useState<File | null>(null);
  const [icon, setIcon] = useState(iconDefault);
  const [name, setName] = useState('');
  const [busy, setBusy] = useState(false);
  const [problem, setProblem] = useState<string | null>(null);
  const [error, setError] = useState<ApiError | null>(null);
  const nameOk = imageNameOk(name) && (!icon || isIcon(name));
  return (
    <div className="grid gap-3 rounded-lg border bg-muted/40 p-4">
      <Field
        label={<FormattedMessage id="firstAid.upload.file" />}
        htmlFor={id}
        help={<FormattedMessage id="firstAid.upload.help" />}
      >
        <FilePicker
          id={id}
          accept={imageTypes.join(',')}
          onFile={(f) => {
            setError(null);
            setProblem(null);
            setFile(f);
            if (!f) return;
            if (!imageTypes.includes(f.type)) setProblem('firstAid.upload.type');
            else if (f.size > firstAidLimits.imageBytes) setProblem('firstAid.upload.size');
            setName(kebabName(f.name, icon));
          }}
        />
      </Field>
      {file && (
        <div className="flex flex-wrap items-start gap-3">
          <Field
            label={<FormattedMessage id="firstAid.upload.name" />}
            htmlFor={`${id}-name`}
            error={nameOk ? undefined : <FormattedMessage id="firstAid.upload.badName" />}
            className="min-w-48 flex-1"
          >
            <Input
              id={`${id}-name`}
              className="font-mono"
              value={name}
              maxLength={40}
              aria-invalid={nameOk ? undefined : true}
              onChange={(e) => setName(e.target.value)}
            />
          </Field>
          <div className="flex items-center gap-3 pt-7">
            <CheckRow
              label={<FormattedMessage id="firstAid.upload.icon" />}
              checked={icon}
              onChange={(on) => {
                setIcon(on);
                setName(kebabName(file.name, on));
              }}
            />
            <Button
              type="button"
              disabled={busy || !nameOk || !!problem}
              onClick={() => {
                setBusy(true);
                setError(null);
                fileToBase64(file)
                  .then((data) => api.call<FirstAidImage>('staffFirstAidImage', { name, data }))
                  .then((img) => {
                    onUploaded(img);
                    setFile(null);
                    toast.success(intl.formatMessage({ id: 'firstAid.toast.uploaded' }));
                    onDone?.(img);
                  })
                  .catch((e: unknown) =>
                    setError(e instanceof ApiError ? e : new ApiError('unknown', null)),
                  )
                  .finally(() => setBusy(false));
              }}
            >
              <Upload />
              <FormattedMessage id={busy ? 'firstAid.upload.busy' : 'firstAid.upload.go'} />
            </Button>
          </div>
        </div>
      )}
      {problem && (
        <p className="text-sm text-destructive" role="alert">
          <FormattedMessage id={problem} />
        </p>
      )}
      {error && (
        <p className="text-sm text-destructive" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
    </div>
  );
}

// ---------- List items ----------

/** ↑ ↓ ✕ on a card. */
function ItemTools({
  index,
  count,
  onMove,
  onRemove,
  canRemove = true,
}: {
  index: number;
  count: number;
  onMove: (by: number) => void;
  onRemove: () => void;
  canRemove?: boolean;
}) {
  const intl = useIntl();
  return (
    <span className="flex shrink-0 items-center">
      <IconButton
        icon="up"
        label={intl.formatMessage({ id: 'firstAid.moveUp' })}
        disabled={index === 0}
        onClick={() => onMove(-1)}
      />
      <IconButton
        icon="down"
        label={intl.formatMessage({ id: 'firstAid.moveDown' })}
        disabled={index === count - 1}
        onClick={() => onMove(1)}
      />
      <IconButton
        icon="remove"
        label={intl.formatMessage({ id: 'firstAid.remove' })}
        disabled={!canRemove}
        onClick={onRemove}
      />
    </span>
  );
}

const calloutEdge: Record<Callout['tone'], string> = {
  negative: 'border-l-destructive',
  warning: 'border-l-warning',
  positive: 'border-l-success',
};

/** A repeated item (step, group): one line with its tools; opens to edit. */
function ItemCard({
  title,
  summary,
  open,
  onOpenChange,
  tools,
  path,
  children,
}: {
  title: ReactNode;
  summary?: ReactNode;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  tools: ReactNode;
  path: Path;
  children: ReactNode;
}) {
  return (
    <Collapsible
      open={open}
      onOpenChange={onOpenChange}
      className="rounded-lg border bg-card"
      data-path={pathKey(path)}
    >
      <div className="flex items-center gap-2 py-1 pr-1 pl-2">
        <CollapsibleTrigger className="flex min-w-0 flex-1 items-center gap-2 rounded-md px-1 py-1.5 text-left outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50">
          <ChevronDown
            className={cn(
              'size-4 shrink-0 text-muted-foreground transition-transform',
              !open && '-rotate-90',
            )}
            aria-hidden="true"
          />
          <span className="shrink-0 text-sm font-semibold">{title}</span>
          {summary && (
            <span className="min-w-0 truncate text-sm text-muted-foreground">{summary}</span>
          )}
        </CollapsibleTrigger>
        {tools}
      </div>
      <CollapsibleContent className="grid gap-4 border-t px-4 pt-3 pb-4">
        {children}
      </CollapsibleContent>
    </Collapsible>
  );
}

/**
 * Open cards by position, kept in step with moves and removals. Cards with a shown issue open
 * and stay open once the issue is fixed (no card folds away while it is being typed in).
 */
function useOpenSet(initial: () => number[], forced: number[]) {
  const [open, setOpen] = useState<Set<number>>(() => new Set(initial()));
  const forcedKey = forced.join(',');
  useEffect(() => {
    if (!forced.length) return;
    setOpen((s) => (forced.every((i) => s.has(i)) ? s : new Set([...s, ...forced])));
    // `forcedKey` stands for `forced`.
  }, [forcedKey]);
  return {
    has: (i: number) => open.has(i) || forced.includes(i),
    set: (i: number, on: boolean) =>
      setOpen((s) => {
        const next = new Set(s);
        if (on) next.add(i);
        else next.delete(i);
        return next;
      }),
    all: (n: number, on: boolean) =>
      setOpen(new Set(on ? Array.from({ length: n }, (_, i) => i) : [])),
    moved: (i: number, j: number) =>
      setOpen((s) => {
        const next = new Set(s);
        const a = s.has(i);
        const b = s.has(j);
        next.delete(i);
        next.delete(j);
        if (a) next.add(j);
        if (b) next.add(i);
        return next;
      }),
    removed: (i: number) =>
      setOpen((s) => new Set([...s].filter((x) => x !== i).map((x) => (x > i ? x - 1 : x)))),
  };
}

// ---------- One situation ----------

export function SituationEditor({
  pack,
  index,
  edit,
  idLocked,
  variant,
  onVariant,
}: {
  pack: FirstAidPack;
  index: number;
  edit: Edit;
  /** Live situations keep their id (the app links to it). */
  idLocked: boolean;
  variant: number;
  onVariant: (v: number) => void;
}) {
  const intl = useIntl();
  const confirm = useConfirm();
  const s = pack.situations[index]!;
  const base: Path = ['situations', index];
  const set = (fn: (s: FirstAidSituation) => void) => edit((p) => fn(p.situations[index]!));
  const vi = intl.locale.startsWith('vi');
  const variantsErr = useIssue([...base, 'variants']);
  const under = useIssueUnder();
  const v = Math.min(variant, s.variants.length - 1);
  const current = s.variants[v]!;
  const vpath: Path = [...base, 'variants', v];
  const variantName = (x: Variant) => (x.label ? (vi ? x.label.vi : x.label.en) || x.id : x.id);
  // "Nâng cao" opens for an issue inside and stays open once it is fixed.
  const advancedIssue = ['id', 'code', 'tool', 'ageMonths', 'keywords'].some((k) =>
    under([...base, k]),
  );
  const [advancedSeen, setAdvancedSeen] = useState(false);
  useEffect(() => {
    if (advancedIssue) setAdvancedSeen(true);
  }, [advancedIssue]);
  const advancedOpen = advancedIssue || advancedSeen;
  const many = s.variants.length > 1;
  return (
    <TooltipProvider>
      <div className="grid min-w-0 gap-4">
        <Section title={<FormattedMessage id="firstAid.section.basics" />}>
          <div className="grid gap-5">
            <LocField
              counter
              label={<FormattedMessage id="firstAid.field.title" />}
              value={s.title}
              max={firstAidLimits.title}
              path={[...base, 'title']}
              onChange={(t) =>
                set((x) => {
                  x.title = t;
                })
              }
            />
            <LocField
              counter
              label={<FormattedMessage id="firstAid.field.lead" />}
              hint={<FormattedMessage id="firstAid.field.leadHelp" />}
              value={s.lead}
              max={firstAidLimits.lead}
              path={[...base, 'lead']}
              onChange={(t) =>
                set((x) => {
                  x.lead = t;
                })
              }
            />
            <div className="grid items-end gap-4 sm:grid-cols-[minmax(0,16rem)_1fr]">
              <SelectField
                label={<FormattedMessage id="firstAid.field.category" />}
                value={s.category}
                path={[...base, 'category']}
                options={pack.categories.map((c) => ({
                  value: c.id,
                  label: (vi ? c.title.vi : c.title.en) || c.id,
                }))}
                onChange={(c) =>
                  set((x) => {
                    x.category = c;
                  })
                }
              />
              <div className="flex min-h-9 flex-wrap items-center gap-x-6 gap-y-2">
                <CheckRow
                  label={<FormattedMessage id="firstAid.field.emergency" />}
                  checked={s.emergency}
                  onChange={(on) =>
                    set((x) => {
                      x.emergency = on;
                    })
                  }
                />
                <CheckRow
                  label={<FormattedMessage id="firstAid.field.monitoring" />}
                  checked={s.monitoring}
                  onChange={(on) =>
                    set((x) => {
                      x.monitoring = on;
                    })
                  }
                />
              </div>
            </div>
            <div className="grid gap-4 md:grid-cols-2">
              <ImageField
                kind="icon"
                label={<FormattedMessage id="firstAid.field.icon" />}
                value={s.icon}
                path={[...base, 'icon']}
                onChange={(id) =>
                  set((x) => {
                    x.icon = id ?? '';
                  })
                }
              />
              <ImageField
                kind="picture"
                label={<FormattedMessage id="firstAid.field.hero" />}
                value={s.hero}
                path={[...base, 'hero']}
                onChange={(id) =>
                  set((x) => {
                    x.hero = id ?? '';
                  })
                }
              />
            </div>
          </div>
        </Section>

        <Section
          title={<FormattedMessage id="firstAid.section.variants" />}
          hint={
            <FormattedMessage
              id="firstAid.variantsHelp"
              values={{ max: firstAidLimits.variants }}
            />
          }
          description={
            many ? (
              <FormattedMessage id="firstAid.variantsCount" values={{ n: s.variants.length }} />
            ) : (
              <FormattedMessage id="firstAid.variantsOne" />
            )
          }
          actions={
            <>
              <Button
                type="button"
                variant="outline"
                size="sm"
                disabled={s.variants.length >= firstAidLimits.variants}
                onClick={() => {
                  set((x) => {
                    x.variants.push(
                      blankVariant(
                        freeId(
                          x.variants.map((y) => y.id),
                          'bien-the',
                        ),
                      ),
                    );
                  });
                  onVariant(s.variants.length);
                }}
              >
                <Plus />
                <FormattedMessage id="firstAid.addVariant" />
              </Button>
              {many && (
                <OverflowMenu
                  items={[
                    {
                      key: 'remove',
                      destructive: true,
                      icon: Trash2,
                      label: <FormattedMessage id="firstAid.removeVariant" />,
                      onSelect: () =>
                        confirm.ask({
                          title: intl.formatMessage(
                            { id: 'firstAid.removeVariantConfirm' },
                            { name: variantName(current) },
                          ),
                          body: <FormattedMessage id="firstAid.removeVariantNote" />,
                          confirmLabel: <FormattedMessage id="firstAid.remove" />,
                          destructive: true,
                          onConfirm: () => {
                            set((x) => {
                              x.variants.splice(v, 1);
                            });
                            onVariant(Math.max(0, v - 1));
                          },
                        }),
                    },
                  ]}
                />
              )}
            </>
          }
        >
          <div className="grid gap-5">
            <div className="flex flex-wrap items-end gap-4">
              {many && (
                <Tabs value={String(v)} onValueChange={(x) => onVariant(Number(x))}>
                  <TabsList aria-label={intl.formatMessage({ id: 'firstAid.section.variants' })}>
                    {s.variants.map((x, i) => (
                      <TabsTrigger key={i} value={String(i)} className="px-3">
                        {variantName(x)}
                        {under([...base, 'variants', i]) && (
                          <span
                            className="size-1.5 rounded-full bg-destructive"
                            aria-hidden="true"
                          />
                        )}
                      </TabsTrigger>
                    ))}
                  </TabsList>
                </Tabs>
              )}
              <SelectField
                className="w-56"
                label={<FormattedMessage id="firstAid.field.variantKind" />}
                value={s.variantKind ?? ''}
                path={[...base, 'variantKind']}
                options={[
                  { value: '', label: intl.formatMessage({ id: 'firstAid.none' }) },
                  { value: 'age', label: intl.formatMessage({ id: 'firstAid.variantKind.age' }) },
                  {
                    value: 'condition',
                    label: intl.formatMessage({ id: 'firstAid.variantKind.condition' }),
                  },
                ]}
                onChange={(k) =>
                  set((x) => {
                    x.variantKind = k === '' ? null : k;
                  })
                }
              />
            </div>
            <FieldError text={variantsErr} />
            <VariantFields
              key={`${index}-${v}`}
              variant={current}
              path={vpath}
              set={(fn) => set((x) => fn(x.variants[v]!))}
            />
          </div>
        </Section>

        <StepsSection
          key={`steps-${index}-${v}`}
          variant={current}
          variantName={many ? variantName(current) : null}
          path={vpath}
          set={(fn) => set((x) => fn(x.variants[v]!))}
        />

        <CalloutsSection
          variant={current}
          variantName={many ? variantName(current) : null}
          path={vpath}
          set={(fn) => set((x) => fn(x.variants[v]!))}
        />

        <Section
          key={advancedOpen ? 'advanced-issue' : 'advanced'}
          collapsible
          defaultOpen={advancedOpen}
          title={<FormattedMessage id="firstAid.section.advanced" />}
          description={<FormattedMessage id="firstAid.section.advancedNote" />}
          summary={[s.id, s.code].filter(Boolean).join(' · ')}
        >
          <div className="grid gap-5">
            <div className="grid gap-4 sm:grid-cols-2">
              {idLocked ? (
                <Field
                  label={<FormattedMessage id="firstAid.field.id" />}
                  help={<FormattedMessage id="firstAid.field.idLocked" />}
                >
                  <span className="flex h-9 items-center rounded-md border bg-muted/50 px-3 font-mono text-sm">
                    {s.id}
                  </span>
                </Field>
              ) : (
                <TextField
                  mono
                  label={<FormattedMessage id="firstAid.field.id" />}
                  value={s.id}
                  path={[...base, 'id']}
                  hint={<FormattedMessage id="firstAid.field.idHelp" />}
                  onChange={(id) => {
                    set((x) => {
                      x.id = id;
                    });
                  }}
                />
              )}
              <TextField
                mono
                label={<FormattedMessage id="firstAid.field.code" />}
                value={s.code ?? ''}
                path={[...base, 'code']}
                hint={<FormattedMessage id="firstAid.field.codeHelp" />}
                onChange={(c) =>
                  set((x) => {
                    x.code = c.trim() === '' ? null : c.toUpperCase();
                  })
                }
              />
              <SelectField
                label={<FormattedMessage id="firstAid.field.tool" />}
                value={s.tool ?? ''}
                path={[...base, 'tool']}
                options={[
                  { value: '', label: intl.formatMessage({ id: 'firstAid.none' }) },
                  {
                    value: 'seizureTimer',
                    label: intl.formatMessage({ id: 'firstAid.tool.seizureTimer' }),
                  },
                ]}
                onChange={(t) =>
                  set((x) => {
                    x.tool = t === '' ? null : t;
                  })
                }
              />
            </div>
            <AgeField
              label={<FormattedMessage id="firstAid.field.ageMonths" />}
              value={s.ageMonths}
              path={[...base, 'ageMonths']}
              onChange={(a) =>
                set((x) => {
                  x.ageMonths = a;
                })
              }
            />
            <LocList
              label={<FormattedMessage id="firstAid.field.keywords" />}
              items={s.keywords}
              max={firstAidLimits.keywords}
              itemMax={firstAidLimits.heading}
              path={[...base, 'keywords']}
              addLabel={<FormattedMessage id="firstAid.addKeyword" />}
              onChange={(k) =>
                set((x) => {
                  x.keywords = k;
                })
              }
            />
          </div>
        </Section>
      </div>
      {confirm.dialog}
    </TooltipProvider>
  );
}

/** The selected variant's own settings: label, age, banner, header picture, CPR, id. */
function VariantFields({
  variant,
  path,
  set,
}: {
  variant: Variant;
  path: Path;
  set: (fn: (v: Variant) => void) => void;
}) {
  const intl = useIntl();
  return (
    <div className="grid gap-5">
      <OptionalLocField
        label={<FormattedMessage id="firstAid.field.variantLabel" />}
        value={variant.label}
        max={firstAidLimits.heading}
        path={[...path, 'label']}
        onChange={(l) =>
          set((v) => {
            v.label = l;
          })
        }
      />
      <AgeField
        label={<FormattedMessage id="firstAid.field.variantAge" />}
        value={variant.ageMonths}
        path={[...path, 'ageMonths']}
        onChange={(a) =>
          set((v) => {
            v.ageMonths = a;
          })
        }
      />
      <OptionalLocField
        multiline
        label={<FormattedMessage id="firstAid.field.banner" />}
        value={variant.banner}
        max={firstAidLimits.text}
        path={[...path, 'banner']}
        onChange={(b) =>
          set((v) => {
            v.banner = b;
          })
        }
      />
      <div className="grid gap-4 md:grid-cols-2">
        <ImageField
          nullable
          kind="picture"
          label={<FormattedMessage id="firstAid.field.variantHero" />}
          value={variant.hero}
          path={[...path, 'hero']}
          onChange={(h) =>
            set((v) => {
              v.hero = h;
            })
          }
        />
        <div className="grid content-start gap-4 sm:grid-cols-2">
          <SelectField
            label={<FormattedMessage id="firstAid.field.cpr" />}
            value={variant.cpr ?? ''}
            path={[...path, 'cpr']}
            options={[
              { value: '', label: intl.formatMessage({ id: 'firstAid.none' }) },
              { value: 'infant', label: intl.formatMessage({ id: 'firstAid.cpr.infant' }) },
              { value: 'child', label: intl.formatMessage({ id: 'firstAid.cpr.child' }) },
            ]}
            onChange={(c) =>
              set((v) => {
                v.cpr = c === '' ? null : c;
              })
            }
          />
          <TextField
            mono
            label={<FormattedMessage id="firstAid.field.variantId" />}
            value={variant.id}
            path={[...path, 'id']}
            onChange={(id) =>
              set((v) => {
                v.id = id;
              })
            }
          />
        </div>
      </div>
    </div>
  );
}

function StepsSection({
  variant,
  variantName,
  path,
  set,
}: {
  variant: Variant;
  variantName: string | null;
  path: Path;
  set: (fn: (v: Variant) => void) => void;
}) {
  const intl = useIntl();
  const stepsErr = useIssue([...path, 'steps']);
  const under = useIssueUnder();
  const n = variant.steps.length;
  const bad = variant.steps.map((_, i) => i).filter((i) => under([...path, 'steps', i]));
  // Short lists open whole; longer ones start with the first step open.
  const open = useOpenSet(() => (n <= 2 ? variant.steps.map((_, i) => i) : [0]), bad);
  const allOpen = variant.steps.every((_, i) => open.has(i));
  return (
    <Section
      title={<FormattedMessage id="firstAid.steps" values={{ n, max: firstAidLimits.steps }} />}
      description={
        variantName ? (
          <FormattedMessage id="firstAid.forVariant" values={{ name: variantName }} />
        ) : undefined
      }
      actions={
        n > 1 && (
          <Button
            type="button"
            variant="ghost"
            size="sm"
            className="text-muted-foreground"
            onClick={() => open.all(n, !allOpen)}
          >
            {allOpen ? <ChevronsDownUp /> : <ChevronsUpDown />}
            <FormattedMessage id={allOpen ? 'firstAid.collapseAll' : 'firstAid.expandAll'} />
          </Button>
        )
      }
    >
      <div className="grid gap-2">
        <FieldError text={stepsErr} />
        {variant.steps.map((st, i) => {
          const at: Path = [...path, 'steps', i];
          return (
            <ItemCard
              key={i}
              path={at}
              open={open.has(i)}
              onOpenChange={(on) => open.set(i, on)}
              title={
                <span className="flex items-center gap-2">
                  <span className="grid size-6 place-items-center rounded-full bg-accent text-xs font-semibold text-accent-foreground tabular-nums">
                    {i + 1}
                  </span>
                  <span className="sr-only">
                    <FormattedMessage id="firstAid.stepN" values={{ n: i + 1 }} />
                  </span>
                  {bad.includes(i) && (
                    <span className="size-1.5 rounded-full bg-destructive" aria-hidden="true" />
                  )}
                </span>
              }
              summary={
                <>
                  <span className={st.title.vi ? 'text-foreground' : 'italic'}>
                    {st.title.vi || intl.formatMessage({ id: 'firstAid.untitledStep' })}
                  </span>
                  {(st.image || st.chips.length > 0 || st.count) && (
                    <span className="ml-2 text-xs">
                      {[
                        st.image && intl.formatMessage({ id: 'firstAid.stepHasImage' }),
                        st.chips.length > 0 &&
                          intl.formatMessage({ id: 'firstAid.stepChips' }, { n: st.chips.length }),
                        st.count &&
                          intl.formatMessage({ id: 'firstAid.stepCount' }, { n: st.count }),
                      ]
                        .filter(Boolean)
                        .join(' · ')}
                    </span>
                  )}
                </>
              }
              tools={
                <ItemTools
                  index={i}
                  count={n}
                  onMove={(by) => {
                    set((v) => moveItem(v.steps, i, by));
                    if (i + by >= 0 && i + by < n) open.moved(i, i + by);
                  }}
                  onRemove={() => {
                    set((v) => {
                      v.steps.splice(i, 1);
                    });
                    open.removed(i);
                  }}
                />
              }
            >
              <StepEditor step={st} path={at} set={(fn) => set((v) => fn(v.steps[i]!))} />
            </ItemCard>
          );
        })}
        <div>
          <AddButton
            disabled={n >= firstAidLimits.steps}
            onClick={() => {
              set((v) => {
                v.steps.push(blankStep());
              });
              open.set(n, true);
            }}
          >
            <FormattedMessage id="firstAid.addStep" />
          </AddButton>
        </div>
      </div>
    </Section>
  );
}

function CalloutsSection({
  variant,
  variantName,
  path,
  set,
}: {
  variant: Variant;
  variantName: string | null;
  path: Path;
  set: (fn: (v: Variant) => void) => void;
}) {
  const intl = useIntl();
  const calloutsErr = useIssue([...path, 'callouts']);
  return (
    <Section
      title={
        <FormattedMessage
          id="firstAid.callouts"
          values={{ n: variant.callouts.length, max: firstAidLimits.callouts }}
        />
      }
      hint={<FormattedMessage id="firstAid.calloutsHelp" />}
      description={
        variantName ? (
          <FormattedMessage id="firstAid.forVariant" values={{ name: variantName }} />
        ) : undefined
      }
    >
      <div className="grid gap-3">
        <FieldError text={calloutsErr} />
        {variant.callouts.map((c, i) => (
          <div
            key={i}
            className={cn(
              'grid gap-4 rounded-lg border border-l-4 bg-card p-4',
              calloutEdge[c.tone],
            )}
            data-path={pathKey([...path, 'callouts', i])}
          >
            <div className="flex items-start gap-3">
              <SelectField
                className="w-64 max-w-full"
                label={<FormattedMessage id="firstAid.field.tone" />}
                value={c.tone}
                path={[...path, 'callouts', i, 'tone']}
                options={(['negative', 'warning', 'positive'] as const).map((t) => ({
                  value: t,
                  label: intl.formatMessage({ id: `firstAid.tone.${t}` }),
                }))}
                onChange={(t) =>
                  set((v) => {
                    v.callouts[i]!.tone = t;
                  })
                }
              />
              <span className="ml-auto">
                <ItemTools
                  index={i}
                  count={variant.callouts.length}
                  onMove={(by) => set((v) => moveItem(v.callouts, i, by))}
                  onRemove={() =>
                    set((v) => {
                      v.callouts.splice(i, 1);
                    })
                  }
                />
              </span>
            </div>
            <LocField
              label={<FormattedMessage id="firstAid.field.heading" />}
              value={c.heading}
              max={firstAidLimits.heading}
              path={[...path, 'callouts', i, 'heading']}
              onChange={(h) =>
                set((v) => {
                  v.callouts[i]!.heading = h;
                })
              }
            />
            <LocList
              label={<FormattedMessage id="firstAid.field.items" />}
              items={c.items}
              max={firstAidLimits.calloutItems}
              itemMax={firstAidLimits.item}
              path={[...path, 'callouts', i, 'items']}
              addLabel={<FormattedMessage id="firstAid.addItem" />}
              onChange={(items) =>
                set((v) => {
                  v.callouts[i]!.items = items;
                })
              }
            />
          </div>
        ))}
        <div>
          <AddButton
            disabled={variant.callouts.length >= firstAidLimits.callouts}
            onClick={() =>
              set((v) => {
                v.callouts.push(blankCallout());
              })
            }
          >
            <FormattedMessage id="firstAid.addCallout" />
          </AddButton>
        </div>
      </div>
    </Section>
  );
}

function StepEditor({
  step,
  path,
  set,
}: {
  step: Step;
  path: Path;
  set: (fn: (s: Step) => void) => void;
}) {
  const intl = useIntl();
  const chipsErr = useIssue([...path, 'chips']);
  return (
    <>
      <LocField
        counter
        label={<FormattedMessage id="firstAid.field.stepTitle" />}
        value={step.title}
        max={firstAidLimits.heading}
        path={[...path, 'title']}
        onChange={(t) =>
          set((s) => {
            s.title = t;
          })
        }
      />
      <LocField
        multiline
        label={<FormattedMessage id="firstAid.field.stepBody" />}
        value={step.body}
        max={firstAidLimits.text}
        path={[...path, 'body']}
        onChange={(b) =>
          set((s) => {
            s.body = b;
          })
        }
      />
      <div className="grid gap-4 md:grid-cols-2">
        <ImageField
          nullable
          kind="picture"
          label={<FormattedMessage id="firstAid.field.stepImage" />}
          value={step.image}
          path={[...path, 'image']}
          onChange={(img) =>
            set((s) => {
              s.image = img;
            })
          }
        />
        <div className="grid content-start gap-4 sm:grid-cols-2">
          <NumField
            nullable
            label={<FormattedMessage id="firstAid.field.count" />}
            hint={<FormattedMessage id="firstAid.field.countHelp" />}
            value={step.count}
            path={[...path, 'count']}
            onChange={(c) =>
              set((s) => {
                s.count = c;
              })
            }
          />
          <SelectField
            label={<FormattedMessage id="firstAid.field.cprRole" />}
            value={step.cprRole ?? ''}
            path={[...path, 'cprRole']}
            options={[
              { value: '', label: intl.formatMessage({ id: 'firstAid.none' }) },
              {
                value: 'compressions',
                label: intl.formatMessage({ id: 'firstAid.cprRole.compressions' }),
              },
              { value: 'breaths', label: intl.formatMessage({ id: 'firstAid.cprRole.breaths' }) },
            ]}
            onChange={(r) =>
              set((s) => {
                s.cprRole = r === '' ? null : r;
              })
            }
          />
        </div>
      </div>
      <fieldset className="grid min-w-0 gap-2" data-path={pathKey([...path, 'chips'])}>
        <legend className={cn(labelClass, 'mb-1.5')}>
          <FormattedMessage id="firstAid.field.chips" />
          <span className="text-xs font-normal text-muted-foreground tabular-nums">
            {step.chips.length}/{firstAidLimits.chips}
          </span>
        </legend>
        {step.chips.map((c, i) => (
          <div key={i} className="grid min-w-0 items-start gap-2 sm:grid-cols-[minmax(0,1fr)_8rem]">
            <LocRow
              value={c.label}
              path={[...path, 'chips', i, 'label']}
              max={firstAidLimits.heading}
              removeLabel={intl.formatMessage({ id: 'firstAid.remove' })}
              onChange={(l) =>
                set((s) => {
                  s.chips[i]!.label = l;
                })
              }
              onRemove={() =>
                set((s) => {
                  s.chips.splice(i, 1);
                })
              }
            />
            <FieldSelect
              className="max-sm:row-start-1"
              value={c.tone}
              ariaLabel={intl.formatMessage({ id: 'firstAid.field.tone' })}
              options={(['mint', 'neutral'] as const).map((t) => ({
                value: t,
                label: intl.formatMessage({ id: `firstAid.chipTone.${t}` }),
              }))}
              onChange={(tone) =>
                set((s) => {
                  s.chips[i]!.tone = tone;
                })
              }
            />
          </div>
        ))}
        <FieldError text={chipsErr} />
        <div>
          <AddButton
            disabled={step.chips.length >= firstAidLimits.chips}
            onClick={() =>
              set((s) => {
                s.chips.push({ label: loc(), tone: 'mint' });
              })
            }
          >
            <FormattedMessage id="firstAid.addChip" />
          </AddButton>
        </div>
      </fieldset>
    </>
  );
}

// ---------- Guide-wide settings ----------

export function GeneralEditor({ pack, edit }: { pack: FirstAidPack; edit: Edit }) {
  const intl = useIntl();
  const used = useMemo(() => new Set(pack.situations.map((s) => s.category)), [pack.situations]);
  const categoriesErr = useIssue(['categories']);
  const under = useIssueUnder();
  const open = useOpenSet(
    () => [],
    pack.categories.map((_, i) => i).filter((i) => under(['categories', i])),
  );
  const vi = intl.locale.startsWith('vi');
  return (
    <TooltipProvider>
      <div className="grid min-w-0 gap-4">
        <Section title={<FormattedMessage id="firstAid.section.emergency" />}>
          <TextField
            className="max-w-xs"
            label={<FormattedMessage id="firstAid.field.emergencyNumber" />}
            value={pack.emergencyNumber}
            path={['emergencyNumber']}
            help={<FormattedMessage id="firstAid.field.emergencyNumberHelp" />}
            onChange={(n) =>
              edit((p) => {
                p.emergencyNumber = n.trim();
              })
            }
          />
        </Section>
        <Section
          title={<FormattedMessage id="firstAid.section.categories" />}
          description={
            <FormattedMessage
              id="firstAid.categoriesCount"
              values={{ n: pack.categories.length }}
            />
          }
          hint={<FormattedMessage id="firstAid.categoriesHelp" />}
        >
          <div className="grid gap-2">
            <FieldError text={categoriesErr} />
            {pack.categories.map((c, i) => {
              const at: Path = ['categories', i];
              const name = (vi ? c.title.vi : c.title.en) || c.title.vi || c.id;
              return (
                <ItemCard
                  key={i}
                  path={at}
                  open={open.has(i)}
                  onOpenChange={(on) => open.set(i, on)}
                  title={name || <FormattedMessage id="firstAid.untitled" />}
                  summary={
                    <>
                      <FormattedMessage id={`firstAid.layout.${c.layout}`} />
                      {' · '}
                      <FormattedMessage id={`firstAid.categoryTone.${c.tone}`} />
                      {' · '}
                      <FormattedMessage
                        id="firstAid.categoryUsed"
                        values={{ n: pack.situations.filter((s) => s.category === c.id).length }}
                      />
                    </>
                  }
                  tools={
                    <ItemTools
                      index={i}
                      count={pack.categories.length}
                      canRemove={!used.has(c.id) && pack.categories.length > 1}
                      onMove={(by) => {
                        edit((p) => moveItem(p.categories, i, by));
                        if (i + by >= 0 && i + by < pack.categories.length) open.moved(i, i + by);
                      }}
                      onRemove={() => {
                        edit((p) => {
                          p.categories.splice(i, 1);
                        });
                        open.removed(i);
                      }}
                    />
                  }
                >
                  <LocField
                    label={<FormattedMessage id="firstAid.field.categoryTitle" />}
                    value={c.title}
                    max={firstAidLimits.heading}
                    path={['categories', i, 'title']}
                    onChange={(t) =>
                      edit((p) => {
                        p.categories[i]!.title = t;
                      })
                    }
                  />
                  <div className="grid gap-4 sm:grid-cols-3">
                    <SelectField
                      label={<FormattedMessage id="firstAid.field.layout" />}
                      value={c.layout}
                      path={['categories', i, 'layout']}
                      options={(['grid', 'list'] as const).map((l) => ({
                        value: l,
                        label: intl.formatMessage({ id: `firstAid.layout.${l}` }),
                      }))}
                      onChange={(l) =>
                        edit((p) => {
                          p.categories[i]!.layout = l;
                        })
                      }
                    />
                    <SelectField
                      label={<FormattedMessage id="firstAid.field.categoryTone" />}
                      value={c.tone}
                      path={['categories', i, 'tone']}
                      options={(['danger', 'sunshine', 'mint'] as const).map((t) => ({
                        value: t,
                        label: intl.formatMessage({ id: `firstAid.categoryTone.${t}` }),
                      }))}
                      onChange={(t) =>
                        edit((p) => {
                          p.categories[i]!.tone = t;
                        })
                      }
                    />
                    <TextField
                      mono
                      label={<FormattedMessage id="firstAid.field.categoryId" />}
                      hint={<FormattedMessage id="firstAid.field.categoryIdHelp" />}
                      value={c.id}
                      path={['categories', i, 'id']}
                      onChange={(id) =>
                        edit((p) => {
                          // Situations follow their group when its id changes.
                          for (const s of p.situations) if (s.category === c.id) s.category = id;
                          p.categories[i]!.id = id;
                        })
                      }
                    />
                  </div>
                </ItemCard>
              );
            })}
            <div>
              <AddButton
                disabled={pack.categories.length >= 8}
                onClick={() => {
                  edit((p) => {
                    p.categories.push({
                      id: freeId(
                        p.categories.map((x) => x.id),
                        'nhom',
                      ),
                      title: loc(),
                      layout: 'list',
                      tone: 'mint',
                    });
                  });
                  open.set(pack.categories.length, true);
                }}
              >
                <FormattedMessage id="firstAid.addCategory" />
              </AddButton>
            </div>
          </div>
        </Section>
        <Section
          title={<FormattedMessage id="firstAid.section.quickSearch" />}
          hint={<FormattedMessage id="firstAid.quickSearchHelp" />}
        >
          <LocList
            label={<FormattedMessage id="firstAid.field.quickSearch" />}
            items={pack.quickSearch}
            max={12}
            itemMax={firstAidLimits.heading}
            path={['quickSearch']}
            addLabel={<FormattedMessage id="firstAid.addQuickSearch" />}
            onChange={(q) =>
              edit((p) => {
                p.quickSearch = q;
              })
            }
          />
        </Section>
      </div>
    </TooltipProvider>
  );
}
