import {
  articleTopics,
  calloutTones,
  contentEmergencyToken,
  contentImageUploadSchema,
  contentLimits,
  editorialChecks,
  literalEmergencyProblems,
  memberRoles,
  solidsSubtopics,
  type ArticleTopic,
  type ContentBlock,
  type ContentKind,
  type EditorialAction,
  type EditorialCheck,
  type EditorialDisplayStatus,
  type EditorialReview,
  type EditorialStatus,
  type MemberRole,
  type SolidsSubtopic,
  type StageAge,
  type StageUnit,
} from '@child-life/contracts';
import {
  Check,
  ImageIcon,
  Phone,
  Plus,
  Search,
  Trash2,
  TriangleAlert,
  Upload,
  X,
} from 'lucide-react';
import {
  createContext,
  useContext,
  useEffect,
  useId,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { toast } from 'sonner';
import { Badge } from '@/components/ui/badge';
import { Button as UiButton } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Textarea } from '@/components/ui/textarea';
import { cn } from '@/lib/utils';
import { ApiError, useApi, useLoad, type Api } from '../api';
import { Field, Notice, type MenuItem, type StatItem } from '../content-kit';
import { ZONE } from '../format';
import { Button, Empty, Modal, Pill, RejectedBy, errorMessageId, type PillTone } from '../ui';
import { CheckRow, FilePicker, IconButton } from './form-controls';
import { fileToBase64, kebabName, imageNameOk } from './FirstAidEditor';

/**
 * Shared pieces of the editorial screens (D-076 #5–#7, Figma B01–B08): the shapes the
 * `staffContent*` callables answer (mirrors firebase/functions/src/content-library.ts), status
 * pills, the workflow dialog (Gửi duyệt · Duyệt · Trả lại · Xuất bản · Gỡ · Xác nhận lại),
 * vi/en fields, sources, pictures and the phone previews.
 */

// ---------- Response shapes ----------

export type Lang = 'vi' | 'en';
export const langs: Lang[] = ['vi', 'en'];
export type Loc = { vi: string; en: string };
export type LocList = { vi: string[]; en: string[] };

export interface ContentLive {
  revision: number;
  publishedAt: string;
  reviewDueOn: string;
  illustrative: boolean;
  reviewer: string | null;
  dueForReview: boolean;
}

export interface ContentRow {
  id: string;
  kind: ContentKind;
  status: EditorialStatus;
  displayStatus: EditorialDisplayStatus;
  live: ContentLive | null;
  title: Loc;
  reviewerLabel: string | null;
  lastEditorName: string;
  updatedAt: string | null;
  submittedByName: string | null;
  approverName: string | null;
  rejection: { by: string; reason: string } | null;
  links: { articles: string[]; milestones: string[] };
  // Articles
  library?: string;
  topic?: ArticleTopic;
  format?: string;
  ageWeeks?: { from: number; to: number };
  readingMinutes?: number;
  blocks?: { vi: number; en: number };
  hasCover?: boolean;
  sources?: number;
  // Stages
  age?: StageAge;
  points?: { doing: number; tryThis: number };
  audience?: MemberRole[];
  // Milestones (whatever the milestones adapter lists)
  [extra: string]: unknown;
}

export interface ContentCounts {
  inApp: number;
  pending: number;
  inReview: number;
  approved: number;
  drafts: number;
  dueForReview: number;
  archived: number;
  total: number;
}

export interface CoverageBucket {
  id: string;
  unit: StageUnit;
  from: number;
  to: number;
  state: 'published' | 'pending' | 'draft' | 'missing';
  itemIds: string[];
}

export interface ContentListView {
  view: ContentKind;
  today: string;
  rows: ContentRow[];
  counts: ContentCounts;
  coverage?: {
    buckets: CoverageBucket[];
    covered: number;
    published: number;
    total: number;
    gaps: string[];
  };
  available: ContentKind[];
  requireReview: boolean;
}

export interface ContentQueueView {
  view: 'queue';
  today: string;
  rows: ContentRow[];
  /** Per kind (a server that does not know a kind yet leaves it out). */
  counts: Partial<Record<ContentKind, ContentCounts>>;
  totals: ContentCounts;
  available: ContentKind[];
  requireReview: boolean;
}

export interface ContentItemView<T = Record<string, unknown>> {
  row: ContentRow;
  data: T;
  notes: string;
  lastEditorUid: string | null;
  pendingReview: EditorialReview;
  published: Record<string, unknown> | null;
}

export interface ContentImage {
  id: string;
  url: string;
}

export const asApiError = (e: unknown) =>
  e instanceof ApiError ? e : new ApiError('unknown', null);

export const textOf = (intl: IntlShape, t: Loc | null | undefined) =>
  t ? (intl.locale.startsWith('vi') ? t.vi : t.en) || t.vi || t.en : '';

export const charCount = (s: string) => [...s.normalize('NFC')].length;

export function dateTime(intl: IntlShape, iso: string | null | undefined): string {
  return iso
    ? intl.formatDate(iso, {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        timeZone: ZONE,
      })
    : '—';
}
export const dmy = (iso: string) => iso.split('-').reverse().join('/');

// ---------- Ages ----------

const WEEKS_PER_MONTH = 4.345;

/** Article ages are stored in weeks; whole months read as "0–3 tháng", else "3–4 tuần". */
export function weeksLabel(intl: IntlShape, a: { from: number; to: number }): string {
  const m = (w: number) => Math.round(w / WEEKS_PER_MONTH);
  const whole = (w: number) => Math.abs(m(w) * WEEKS_PER_MONTH - w) <= 0.6;
  if (a.from === 0 && a.to >= 104 && whole(a.to)) {
    return intl.formatMessage({ id: 'content.age.months' }, { from: 0, to: m(a.to) });
  }
  if (whole(a.from) && whole(a.to) && a.to >= 8) {
    return intl.formatMessage({ id: 'content.age.months' }, { from: m(a.from), to: m(a.to) });
  }
  return intl.formatMessage({ id: 'content.age.weeks' }, { from: a.from, to: a.to - 1 });
}

/** B05 labels: weeks name the last week ("3–4 tuần" = [3, 5)), months the end ("8–9 tháng"). */
export function stageAgeText(intl: IntlShape, age: { unit: StageUnit; from: number; to: number }) {
  return age.unit === 'week'
    ? intl.formatMessage({ id: 'content.age.weeks' }, { from: age.from, to: age.to - 1 })
    : intl.formatMessage({ id: 'content.age.months' }, { from: age.from, to: age.to });
}

/** The 4c age bands, in weeks: 0–3, 3–6, 6–12 months, 1–2 years. */
export const ageBands = [
  { id: '0-3', from: 0, to: 13 },
  { id: '3-6', from: 13, to: 26 },
  { id: '6-12', from: 26, to: 52 },
  { id: '12-24', from: 52, to: 104 },
] as const;

// ---------- Status ----------

export const statusTone: Record<EditorialDisplayStatus, PillTone> = {
  draft: 'muted',
  in_review: 'wait',
  approved: 'info',
  published: 'ok',
  archived: 'muted',
  needs_rereview: 'high',
};

/** The statuses a list can filter on, in workflow order. */
export const displayStatuses = [
  'draft',
  'in_review',
  'approved',
  'published',
  'needs_rereview',
  'archived',
] as const;

/** Workflow status, plus "Trên app · bản n" and "Minh hoạ" when something is live. */
export function StatusCell({ row }: { row: ContentRow }) {
  return (
    <span className="inline-flex items-center gap-1 whitespace-nowrap">
      <Pill tone={statusTone[row.displayStatus]}>
        <FormattedMessage id={`content.status.${row.displayStatus}`} />
      </Pill>
      {row.live && row.status !== 'published' && (
        <Pill tone="ok">
          <FormattedMessage id="content.liveRevision" values={{ n: row.live.revision }} />
        </Pill>
      )}
      {row.live?.illustrative && (
        <Pill tone="purple">
          <FormattedMessage id="content.illustrative" />
        </Pill>
      )}
    </span>
  );
}

/** The count tiles over a list; each one filters the list to what it counts. */
export type Tile = 'all' | 'live' | 'pending' | 'draft' | 'due';

/** Mirrors the server's counts (content-library.ts). */
export function tileMatch(r: ContentRow, tile: Tile | undefined): boolean {
  switch (tile ?? 'all') {
    case 'live':
      return !!r.live;
    case 'pending':
      return r.status === 'in_review' || r.status === 'approved';
    case 'draft':
      return r.status === 'draft';
    case 'due':
      return !!r.live?.dueForReview;
    default:
      return true;
  }
}

export function contentTiles(c: ContentCounts, tile: Tile, onTile: (t: Tile) => void): StatItem[] {
  const pick = (t: Tile) => () => onTile(tile === t ? 'all' : t);
  return [
    {
      key: 'live',
      label: <FormattedMessage id="content.kpi.inApp" />,
      value: c.inApp,
      active: tile === 'live',
      onClick: pick('live'),
    },
    {
      key: 'pending',
      label: <FormattedMessage id="content.kpi.pending" />,
      value: c.pending,
      tone: c.pending ? 'warn' : 'muted',
      foot: c.approved ? (
        <FormattedMessage id="content.kpi.pendingFoot" values={{ n: c.approved }} />
      ) : undefined,
      active: tile === 'pending',
      onClick: pick('pending'),
    },
    {
      key: 'draft',
      label: <FormattedMessage id="content.kpi.drafts" />,
      value: c.drafts,
      tone: c.drafts ? 'default' : 'muted',
      active: tile === 'draft',
      onClick: pick('draft'),
    },
    {
      key: 'due',
      label: <FormattedMessage id="content.kpi.due" />,
      value: c.dueForReview,
      tone: c.dueForReview ? 'error' : 'muted',
      foot: <FormattedMessage id="content.kpi.dueFoot" />,
      active: tile === 'due',
      onClick: pick('due'),
    },
  ];
}

export const statusOptions = (intl: IntlShape) => [
  { value: 'all', label: intl.formatMessage({ id: 'content.filter.allStatuses' }) },
  ...displayStatuses.map((s) => ({
    value: s,
    label: intl.formatMessage({ id: `content.status.${s}` }),
  })),
];

export function useContentList<T = ContentListView>(view: ContentKind | 'queue') {
  return useLoad<T>('staffContentList', { view }, `content:${view}`);
}

/** "Nhập bản nháp mẫu" in a screen's "⋯": imports the drafts that are not there yet. */
export function useSeedItem(kind: ContentKind, onDone: () => void): MenuItem {
  const api = useApi();
  const intl = useIntl();
  const [busy, setBusy] = useState(false);
  return {
    key: 'seed',
    icon: Upload,
    disabled: busy,
    label: <FormattedMessage id="content.seed" />,
    onSelect: () => {
      setBusy(true);
      api
        .call<{ added: Record<string, number>; skipped: number }>('staffContentSeed', {
          kinds: [kind],
        })
        .then((r) => {
          toast.success(
            intl.formatMessage(
              { id: 'content.seedDone' },
              { added: r.added[kind] ?? 0, skipped: r.skipped },
            ),
          );
          onDone();
        })
        .catch((e: unknown) =>
          toast.error(intl.formatMessage({ id: errorMessageId(asApiError(e)) })),
        )
        .finally(() => setBusy(false));
    },
  };
}

// ---------- Workflow ----------

/** Which actions a member sees for an item (the server checks again). */
export function actionsFor(
  row: Pick<ContentRow, 'status' | 'live'>,
  can: { edit: boolean; approve: boolean },
): EditorialAction[] {
  const out: EditorialAction[] = [];
  if (row.status === 'draft' && can.edit) out.push('submit');
  if (row.status === 'in_review' && can.approve) out.push('approve', 'reject');
  if (row.status === 'approved' && can.approve) out.push('publish', 'reject');
  if (row.live && can.approve) out.push('reconfirm', 'unpublish');
  if (['draft', 'in_review', 'approved'].includes(row.status) && can.edit) out.push('archive');
  return out;
}

/** The next step of the workflow, shown as a button; the rest goes behind "⋯". */
const forwardActions: EditorialAction[] = ['submit', 'approve', 'publish'];
const destructiveActions: EditorialAction[] = ['unpublish', 'archive'];

export function splitActions(actions: EditorialAction[]) {
  const main = actions.filter((a) => forwardActions.includes(a) || a === 'reject');
  const rest = actions.filter((a) => !main.includes(a));
  return { main, rest };
}

export interface ActInput {
  checks: EditorialCheck[];
  review: { reviewer: string; credential: string; reviewedOn: string };
  withReview: boolean;
}

export function blankActInput(today: string): ActInput {
  return {
    checks: [],
    review: { reviewer: '', credential: '', reviewedOn: today },
    withReview: false,
  };
}

/** The `staffContentAct` request, or null while the dialog is not complete (no reason: D-090). */
export function contentActRequest(
  kind: ContentKind,
  id: string,
  action: EditorialAction,
  input: ActInput,
  requireReview: boolean,
): Record<string, unknown> | null {
  if (action === 'approve' && !editorialChecks.every((c) => input.checks.includes(c))) return null;
  const takesReview = action === 'approve' || action === 'reconfirm';
  const wantsReview = takesReview && (input.withReview || requireReview);
  const r = input.review;
  if (wantsReview && (!r.reviewer.trim() || !r.credential.trim() || !r.reviewedOn)) return null;
  return {
    kind,
    id,
    action,
    ...(action === 'approve' ? { checks: input.checks } : {}),
    ...(wantsReview
      ? {
          review: {
            reviewer: r.reviewer.trim(),
            credential: r.credential.trim(),
            reviewedOn: r.reviewedOn,
          },
        }
      : {}),
  };
}

export function sendContentAct(api: Api, request: Record<string, unknown>) {
  return api.call<{ status: EditorialStatus; revision?: number }>('staffContentAct', request);
}

/** The dialog for one workflow step. */
export function ActDialog({
  kind,
  id,
  action,
  title,
  requireReview,
  today,
  sameEditor,
  onClose,
  onDone,
}: {
  kind: ContentKind;
  id: string;
  action: EditorialAction;
  title: string;
  requireReview: boolean;
  today: string;
  /** The member edited the item last: approving needs someone else (D-058). */
  sameEditor: boolean;
  onClose: () => void;
  onDone: () => void;
}) {
  const api = useApi();
  const intl = useIntl();
  const reviewId = useId();
  const [input, setInput] = useState<ActInput>(() => blankActInput(today));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const request = contentActRequest(kind, id, action, input, requireReview);
  const blocked = (action === 'approve' || action === 'reconfirm') && sameEditor;
  const takesReview = action === 'approve' || action === 'reconfirm';
  const set = (patch: Partial<ActInput>) => setInput((i) => ({ ...i, ...patch }));
  return (
    <Modal
      wide={action === 'approve'}
      title={<FormattedMessage id={`content.act.${action}.title`} />}
      onClose={onClose}
    >
      <div className="grid gap-1">
        <p className="font-medium">{title}</p>
        <p className="text-sm text-muted-foreground">
          <FormattedMessage id={`content.act.${action}.body`} />
        </p>
      </div>
      {blocked && (
        <Notice tone="warn">
          <FormattedMessage id="content.act.samePerson" />
        </Notice>
      )}
      {action === 'approve' && (
        <fieldset className="grid gap-2 rounded-lg border p-3">
          <legend className="px-1 text-[13px] font-medium">
            <FormattedMessage id="content.checks.title" />{' '}
            <span className="text-muted-foreground tabular-nums">
              {input.checks.length}/{editorialChecks.length}
            </span>
          </legend>
          {editorialChecks.map((c) => (
            <CheckRow
              key={c}
              label={
                <span className="text-sm">
                  <FormattedMessage id={`content.check.${c}`} />
                </span>
              }
              checked={input.checks.includes(c)}
              onChange={(on) =>
                set({
                  checks: on ? [...input.checks, c] : input.checks.filter((x) => x !== c),
                })
              }
            />
          ))}
        </fieldset>
      )}
      {takesReview && (
        <fieldset className="grid gap-3 rounded-lg border p-3">
          <legend className="px-1 text-[13px] font-medium">
            <FormattedMessage id="content.review.title" />
          </legend>
          {requireReview ? (
            <p className="text-sm text-muted-foreground">
              <FormattedMessage id="content.review.required" />
            </p>
          ) : (
            <CheckRow
              label={
                <span className="text-sm">
                  <FormattedMessage id="content.review.optional" />
                </span>
              }
              checked={input.withReview}
              onChange={(on) => set({ withReview: on })}
            />
          )}
          {(input.withReview || requireReview) && (
            <div className="grid gap-3 sm:grid-cols-3">
              {(['reviewer', 'credential'] as const).map((f) => (
                <Field
                  key={f}
                  htmlFor={`${reviewId}-${f}`}
                  label={<FormattedMessage id={`content.review.${f}`} />}
                >
                  <Input
                    id={`${reviewId}-${f}`}
                    maxLength={120}
                    value={input.review[f]}
                    onChange={(e) => set({ review: { ...input.review, [f]: e.target.value } })}
                  />
                </Field>
              ))}
              <Field
                htmlFor={`${reviewId}-on`}
                label={<FormattedMessage id="content.review.reviewedOn" />}
              >
                <Input
                  id={`${reviewId}-on`}
                  type="date"
                  max={today}
                  value={input.review.reviewedOn}
                  onChange={(e) => set({ review: { ...input.review, reviewedOn: e.target.value } })}
                />
              </Field>
            </div>
          )}
          {!requireReview && !input.withReview && (
            <p className="text-xs text-muted-foreground">
              <FormattedMessage id="content.review.illustrativeNote" />
            </p>
          )}
        </fieldset>
      )}
      {error && (
        <Notice tone="error">
          <FormattedMessage id={errorMessageId(error)} />
        </Notice>
      )}
      <div className="modal__actions">
        <Button onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button
          kind={action === 'unpublish' || action === 'reject' ? 'danger' : 'primary'}
          disabled={busy || blocked || !request}
          onClick={() => {
            if (!request) return;
            setBusy(true);
            setError(null);
            sendContentAct(api, request)
              .then(() => {
                toast.success(intl.formatMessage({ id: `content.done.${action}` }));
                onDone();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id={`content.action.${action}`} />
        </Button>
      </div>
    </Modal>
  );
}

/** The next workflow step(s) as buttons (the editor bar, the review queue). */
export function WorkflowButtons({
  actions,
  onPick,
}: {
  actions: EditorialAction[];
  onPick: (a: EditorialAction) => void;
}) {
  if (!actions.length) return null;
  return (
    <div className="flex flex-wrap items-center gap-2">
      {actions.map((a) => (
        <Button
          key={a}
          kind={
            a === 'unpublish' || a === 'reject'
              ? 'danger'
              : a === 'archive'
                ? 'ghost'
                : forwardActions.includes(a)
                  ? 'primary'
                  : 'secondary'
          }
          onClick={() => onPick(a)}
        >
          <FormattedMessage id={`content.action.${a}`} />
        </Button>
      ))}
    </div>
  );
}

/** The workflow steps that are not the next one, for the editor bar's "⋯". */
export function workflowMenu(
  actions: EditorialAction[],
  onPick: (a: EditorialAction) => void,
): MenuItem[] {
  return actions.map((a) => ({
    key: a,
    label: <FormattedMessage id={`content.action.${a}`} />,
    destructive: destructiveActions.includes(a),
    onSelect: () => onPick(a),
  }));
}

/** The editor bar's buttons: "Trả lại" outlined, the step forward filled. */
export function WorkflowMain({
  actions,
  onPick,
}: {
  actions: EditorialAction[];
  onPick: (a: EditorialAction) => void;
}) {
  return (
    <>
      {actions.map((a) => (
        <UiButton
          key={a}
          variant={a === 'reject' ? 'outline' : 'default'}
          className={cn(a === 'reject' && 'text-destructive hover:text-destructive')}
          onClick={() => onPick(a)}
        >
          <FormattedMessage id={`content.action.${a}`} />
        </UiButton>
      ))}
    </>
  );
}

/** What stops "Gửi duyệt", a rejection and a save error, above the form. */
export function EditorNotices({
  error,
  rejection,
  issues,
}: {
  error: ApiError | null;
  rejection: { by: string; reason: string } | null | undefined;
  issues: ParseIssue[];
}) {
  if (!error && !rejection && !issues.length) return null;
  return (
    <div className="mb-4 grid gap-3">
      {error && (
        <Notice tone="error">
          <FormattedMessage id={errorMessageId(error)} />
        </Notice>
      )}
      {rejection && (
        <Notice tone="warn" title={<FormattedMessage id="content.rejectedTitle" />}>
          <RejectedBy id="content.rejected" by={rejection.by} reason={rejection.reason} />
        </Notice>
      )}
      <IssuesList issues={issues} />
    </div>
  );
}

// ---------- Fields ----------

/** "Tiếng Việt · Tiếng Anh": which language the form and the preview show. */
export function LangTabs({ value, onChange }: { value: Lang; onChange: (l: Lang) => void }) {
  const intl = useIntl();
  return (
    <Tabs value={value} onValueChange={(v) => onChange(v as Lang)}>
      <TabsList aria-label={intl.formatMessage({ id: 'content.lang' })}>
        {langs.map((l) => (
          <TabsTrigger key={l} value={l} className="px-3">
            <FormattedMessage id={`content.lang.${l}`} />
          </TabsTrigger>
        ))}
      </TabsList>
    </Tabs>
  );
}

export function TextField({
  label,
  value,
  onChange,
  max,
  counter,
  multiline,
  help,
  hint,
  placeholder,
  rows,
  className,
}: {
  label: ReactNode;
  value: string;
  onChange: (v: string) => void;
  max: number;
  counter?: boolean;
  multiline?: boolean;
  help?: ReactNode;
  hint?: ReactNode;
  placeholder?: string;
  rows?: number;
  className?: string;
}) {
  const id = useId();
  const n = charCount(value);
  const over = n > max;
  return (
    <Field
      label={label}
      htmlFor={id}
      hint={hint}
      counter={counter ? { n, max } : undefined}
      help={help}
      className={className}
    >
      {multiline ? (
        <Textarea
          id={id}
          rows={rows ?? Math.min(12, Math.max(3, Math.ceil(n / 80)))}
          value={value}
          placeholder={placeholder}
          aria-invalid={over ? true : undefined}
          className="leading-relaxed"
          onChange={(e) => onChange(e.target.value)}
        />
      ) : (
        <Input
          id={id}
          value={value}
          placeholder={placeholder}
          aria-invalid={over ? true : undefined}
          onChange={(e) => onChange(e.target.value)}
        />
      )}
    </Field>
  );
}

export function NumberField({
  label,
  value,
  onChange,
  min,
  max,
  help,
  hint,
  suffix,
}: {
  label: ReactNode;
  value: number;
  onChange: (v: number) => void;
  min: number;
  max: number;
  help?: ReactNode;
  hint?: ReactNode;
  suffix?: ReactNode;
}) {
  const id = useId();
  return (
    <Field label={label} htmlFor={id} help={help} hint={hint}>
      <div className="relative">
        <Input
          id={id}
          type="number"
          min={min}
          max={max}
          className={cn('tabular-nums', suffix && 'pr-14')}
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

/**
 * Up to [max] short points, one box each (Enter starts the next one); empty boxes are left out
 * of the saved list. The counter turns red past [max].
 */
export function PointsField({
  label,
  value,
  onChange,
  max,
  itemMax,
}: {
  label: ReactNode;
  value: string[];
  onChange: (v: string[]) => void;
  max: number;
  itemMax: number;
}) {
  const intl = useIntl();
  const [rows, setRows] = useState<string[]>(() => (value.length ? value : ['']));
  const [focus, setFocus] = useState<number | null>(null);
  const boxes = useRef<Array<HTMLTextAreaElement | null>>([]);
  useEffect(() => {
    if (focus === null) return;
    boxes.current[focus]?.focus();
    setFocus(null);
  }, [focus]);
  const update = (next: string[]) => {
    setRows(next.length ? next : ['']);
    onChange(next.map((l) => l.trim()).filter(Boolean));
  };
  const filled = value.length;
  const tooLong = value.some((v) => charCount(v) > itemMax);
  return (
    <Field
      label={label}
      counter={{ n: filled, max }}
      error={
        tooLong ? <FormattedMessage id="content.pointTooLong" values={{ max: itemMax }} /> : null
      }
    >
      <ol className="grid gap-2">
        {rows.map((r, i) => (
          <li key={i} className="grid grid-cols-[1.5rem_minmax(0,1fr)_auto] items-start gap-2">
            <span className="mt-2 grid size-5 place-items-center rounded-full bg-muted text-[11px] font-semibold text-muted-foreground tabular-nums">
              {i + 1}
            </span>
            <Textarea
              ref={(el) => {
                boxes.current[i] = el;
              }}
              rows={1}
              value={r}
              aria-label={intl.formatMessage({ id: 'content.block.item' }, { n: i + 1 })}
              aria-invalid={charCount(r.trim()) > itemMax || i >= max ? true : undefined}
              className="min-h-9 py-1.5 leading-relaxed"
              onChange={(e) => update(rows.map((x, j) => (j === i ? e.target.value : x)))}
              onKeyDown={(e) => {
                if (e.key !== 'Enter' || e.shiftKey || e.nativeEvent.isComposing) return;
                e.preventDefault();
                if (rows.length >= max) return;
                update([...rows.slice(0, i + 1), '', ...rows.slice(i + 1)]);
                setFocus(i + 1);
              }}
            />
            <IconButton
              icon="remove"
              label={intl.formatMessage({ id: 'content.remove' })}
              disabled={rows.length === 1 && !r}
              onClick={() => update(rows.filter((_, j) => j !== i))}
            />
          </li>
        ))}
      </ol>
      {rows.length < max && (
        <div className="pl-8">
          <UiButton
            variant="ghost"
            size="sm"
            className="text-primary"
            onClick={() => {
              update([...rows, '']);
              setFocus(rows.length);
            }}
          >
            <Plus />
            <FormattedMessage id="content.block.addItem" />
          </UiButton>
        </div>
      )}
    </Field>
  );
}

export type Source = { label: string; url: string };

export function SourcesField({
  value,
  onChange,
  max,
}: {
  value: Source[];
  onChange: (v: Source[]) => void;
  max: number;
}) {
  const intl = useIntl();
  return (
    <fieldset className="grid gap-2">
      <legend className="mb-1.5 flex w-full items-center text-[13px] font-medium">
        <FormattedMessage id="content.sources" />
        <span className="ml-auto text-xs text-muted-foreground tabular-nums">
          {value.length}/{max}
        </span>
      </legend>
      {value.map((s, i) => (
        <div
          className="grid grid-cols-[minmax(0,2fr)_minmax(0,3fr)_auto] items-center gap-2"
          key={i}
        >
          <Input
            aria-label={intl.formatMessage({ id: 'content.source.label' })}
            placeholder={intl.formatMessage({ id: 'content.source.label' })}
            value={s.label}
            maxLength={200}
            onChange={(e) =>
              onChange(value.map((x, j) => (j === i ? { ...x, label: e.target.value } : x)))
            }
          />
          <Input
            className="font-mono text-xs"
            aria-label={intl.formatMessage({ id: 'content.source.url' })}
            placeholder="https://"
            value={s.url}
            maxLength={500}
            onChange={(e) =>
              onChange(value.map((x, j) => (j === i ? { ...x, url: e.target.value } : x)))
            }
          />
          <IconButton
            icon="remove"
            label={intl.formatMessage({ id: 'content.remove' })}
            onClick={() => onChange(value.filter((_, j) => j !== i))}
          />
        </div>
      ))}
      {value.length < max && (
        <div>
          <UiButton
            variant="outline"
            size="sm"
            onClick={() => onChange([...value, { label: '', url: '' }])}
          >
            <Plus />
            <FormattedMessage id="content.source.add" />
          </UiButton>
        </div>
      )}
    </fieldset>
  );
}

/** B06 "Hiện với": Bố mẹ · Người chăm · Gia đình. */
export function AudienceField({
  value,
  onChange,
}: {
  value: MemberRole[];
  onChange: (v: MemberRole[]) => void;
}) {
  return (
    <fieldset className="grid gap-1.5">
      <legend className="mb-1.5 text-[13px] font-medium">
        <FormattedMessage id="content.audience" />
      </legend>
      <div className="flex flex-wrap gap-2">
        {memberRoles.map((r) => {
          const on = value.includes(r);
          return (
            <UiButton
              key={r}
              type="button"
              size="sm"
              variant={on ? 'default' : 'outline'}
              aria-pressed={on}
              className={cn('rounded-full', !on && 'text-muted-foreground')}
              onClick={() => onChange(on ? value.filter((x) => x !== r) : [...value, r])}
            >
              {on && <Check />}
              <FormattedMessage id={`content.audience.${r}`} />
            </UiButton>
          );
        })}
      </div>
    </fieldset>
  );
}

/** Picks up to [max] items (articles or milestones) from a loaded list. */
export function LinkPicker({
  label,
  value,
  onChange,
  options,
  max,
  tone,
}: {
  label: ReactNode;
  value: string[];
  onChange: (v: string[]) => void;
  options: Array<{ id: string; title: string; meta?: string }>;
  max: number;
  tone: 'mint' | 'peach';
}) {
  const intl = useIntl();
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState('');
  const titleOf = (id: string) => options.find((o) => o.id === id)?.title ?? id;
  const shown = options.filter(
    (o) => !q.trim() || `${o.title} ${o.id}`.toLowerCase().includes(q.trim().toLowerCase()),
  );
  return (
    <div className="grid gap-1.5">
      <div className="flex items-center text-[13px] font-medium">
        {label}
        <span
          className={cn(
            'ml-auto text-xs tabular-nums',
            value.length > max ? 'font-medium text-destructive' : 'text-muted-foreground',
          )}
        >
          {value.length}/{max}
        </span>
      </div>
      <div className="flex flex-wrap items-center gap-2">
        {value.map((id) => (
          <span key={id} className={`cl-tag cl-tag--${tone} max-w-full`}>
            <span className="truncate">{titleOf(id)}</span>
            <button
              type="button"
              className="cl-tag__x"
              aria-label={intl.formatMessage({ id: 'content.remove' })}
              onClick={() => onChange(value.filter((x) => x !== id))}
            >
              <X className="size-3.5" />
            </button>
          </span>
        ))}
        {value.length < max && (
          <UiButton variant="outline" size="sm" onClick={() => setOpen(true)}>
            <Plus />
            <FormattedMessage id="content.link.add" />
          </UiButton>
        )}
      </div>
      {open && (
        <Modal title={label} onClose={() => setOpen(false)}>
          <div className="relative">
            <Search
              className="pointer-events-none absolute top-1/2 left-2.5 size-4 -translate-y-1/2 text-muted-foreground"
              aria-hidden="true"
            />
            <Input
              type="search"
              className="pl-8"
              value={q}
              aria-label={intl.formatMessage({ id: 'content.search' })}
              placeholder={intl.formatMessage({ id: 'content.search' })}
              onChange={(e) => setQ(e.target.value)}
            />
          </div>
          {shown.length ? (
            <ul className="grid max-h-[50vh] gap-0.5 overflow-y-auto">
              {shown.map((o) => {
                const on = value.includes(o.id);
                return (
                  <li key={o.id} className="rounded-md px-2 py-1.5 hover:bg-muted">
                    <CheckRow
                      label={
                        <span className="text-sm">
                          {o.title}{' '}
                          {o.meta && <span className="text-muted-foreground">· {o.meta}</span>}
                        </span>
                      }
                      checked={on}
                      disabled={!on && value.length >= max}
                      onChange={(c) =>
                        onChange(c ? [...value, o.id] : value.filter((x) => x !== o.id))
                      }
                    />
                  </li>
                );
              })}
            </ul>
          ) : (
            <Empty>
              <FormattedMessage id="content.empty" />
            </Empty>
          )}
          <div className="modal__actions">
            <Button kind="primary" onClick={() => setOpen(false)}>
              <FormattedMessage id="content.done" />
            </Button>
          </div>
        </Modal>
      )}
    </div>
  );
}

// ---------- Pictures (content/library/{id}.webp) ----------

export const ContentImagesContext = createContext<{
  images: ContentImage[];
  canUpload: boolean;
  onUploaded: (img: ContentImage) => void;
}>({ images: [], canUpload: false, onUploaded: () => undefined });

/** Loads the uploaded pictures once for an editor. */
export function ContentImagesProvider({
  canUpload,
  children,
}: {
  canUpload: boolean;
  children: ReactNode;
}) {
  const [load] = useLoad<{ images: ContentImage[] }>('staffContentImages', {}, 'content-images');
  const [added, setAdded] = useState<ContentImage[]>([]);
  const images = [...added, ...(load.status === 'ok' ? load.data.images : [])];
  return (
    <ContentImagesContext.Provider
      value={{ images, canUpload, onUploaded: (img) => setAdded((a) => [img, ...a]) }}
    >
      {children}
    </ContentImagesContext.Provider>
  );
}

export function ImageThumb({ id, size = 64 }: { id: string | null; size?: number }) {
  const { images } = useContext(ContentImagesContext);
  const url = id ? images.find((i) => i.id === id)?.url : undefined;
  return url ? (
    <img className="cl-thumb" src={url} alt="" width={size} height={size} loading="lazy" />
  ) : (
    <span className="cl-thumb cl-thumb--empty" style={{ width: size, height: size }} aria-hidden>
      {id ? '!' : <ImageIcon className="size-5" />}
    </span>
  );
}

const imageTypes = ['image/png', 'image/jpeg', 'image/webp'];

/** Picks an uploaded picture or uploads a new one (re-encoded to WebP by the server). */
export function ImagePickerButton({
  onPick,
  label,
}: {
  onPick: (id: string) => void;
  /** The button's words; "Chọn ảnh" by default. */
  label?: ReactNode;
}) {
  const intl = useIntl();
  const api = useApi();
  const fileId = useId();
  const { images, canUpload, onUploaded } = useContext(ContentImagesContext);
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [name, setName] = useState('');
  const [busy, setBusy] = useState(false);
  const [problem, setProblem] = useState<string | null>(null);
  const [error, setError] = useState<ApiError | null>(null);
  const shown = images.filter((i) => !q.trim() || i.id.includes(q.trim().toLowerCase()));
  return (
    <>
      <UiButton variant="outline" size="sm" onClick={() => setOpen(true)}>
        <ImageIcon />
        {label ?? <FormattedMessage id="content.image.pick" />}
      </UiButton>
      {open && (
        <Modal
          wide
          title={<FormattedMessage id="content.image.title" />}
          onClose={() => setOpen(false)}
        >
          {canUpload && (
            <div className="grid gap-3 rounded-lg border border-dashed p-3">
              <FilePicker
                id={fileId}
                accept={imageTypes.join(',')}
                label={<FormattedMessage id="content.image.uploadNew" />}
                onFile={(f) => {
                  setFile(f);
                  setError(null);
                  setProblem(null);
                  if (!f) return;
                  if (!imageTypes.includes(f.type)) setProblem('content.image.type');
                  else if (f.size > contentLimits.imageBytes) setProblem('content.image.size');
                  setName(kebabName(f.name, false));
                }}
              />
              {file && (
                <div className="flex flex-wrap items-end gap-2">
                  <Field
                    className="min-w-56 flex-1"
                    htmlFor={`${fileId}-name`}
                    label={<FormattedMessage id="content.image.name" />}
                  >
                    <Input
                      id={`${fileId}-name`}
                      className="font-mono text-xs"
                      value={name}
                      maxLength={40}
                      onChange={(e) => setName(e.target.value)}
                    />
                  </Field>
                  <Button
                    kind="primary"
                    disabled={busy || !!problem || !imageNameOk(name)}
                    onClick={() => {
                      setBusy(true);
                      setError(null);
                      fileToBase64(file)
                        .then((data) => {
                          const req = { name, data };
                          if (!contentImageUploadSchema.safeParse(req).success) {
                            throw new ApiError('invalid-argument', null);
                          }
                          return api.call<ContentImage>('staffContentImage', req);
                        })
                        .then((img) => {
                          onUploaded(img);
                          setFile(null);
                          onPick(img.id);
                          setOpen(false);
                        })
                        .catch((e: unknown) => setError(asApiError(e)))
                        .finally(() => setBusy(false));
                    }}
                  >
                    <FormattedMessage id={busy ? 'content.image.busy' : 'content.image.upload'} />
                  </Button>
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
          )}
          <div className="relative">
            <Search
              className="pointer-events-none absolute top-1/2 left-2.5 size-4 -translate-y-1/2 text-muted-foreground"
              aria-hidden="true"
            />
            <Input
              type="search"
              className="pl-8"
              value={q}
              aria-label={intl.formatMessage({ id: 'content.search' })}
              placeholder={intl.formatMessage({ id: 'content.search' })}
              onChange={(e) => setQ(e.target.value)}
            />
          </div>
          {shown.length ? (
            <ul className="cl-images max-h-[50vh] overflow-y-auto">
              {shown.map((img) => (
                <li key={img.id}>
                  <button
                    type="button"
                    onClick={() => {
                      onPick(img.id);
                      setOpen(false);
                    }}
                  >
                    <img src={img.url} alt="" loading="lazy" />
                    <span className="truncate font-mono">{img.id}</span>
                  </button>
                </li>
              ))}
            </ul>
          ) : (
            <Empty>
              <FormattedMessage id="content.image.none" />
            </Empty>
          )}
        </Modal>
      )}
    </>
  );
}

/** A picture with alt text per language (or none): the cover, a milestone's illustration. */
export function PictureField({
  label,
  value,
  onChange,
  lang,
  altMax = contentLimits.alt,
}: {
  /** Absent when the section around it already says what it is. */
  label?: ReactNode;
  value: { image: string; alt: Loc } | null;
  onChange: (v: { image: string; alt: Loc } | null) => void;
  lang: Lang;
  altMax?: number;
}) {
  return (
    <div className="grid gap-1.5">
      {label && <span className="text-[13px] font-medium">{label}</span>}
      <div className="flex items-start gap-3">
        <ImageThumb id={value?.image ?? null} size={72} />
        <div className="grid min-w-0 flex-1 gap-2">
          <div className="flex flex-wrap gap-2">
            <ImagePickerButton
              label={value ? <FormattedMessage id="content.image.change" /> : undefined}
              onPick={(image) => onChange({ image, alt: value?.alt ?? { vi: '', en: '' } })}
            />
            {value && (
              <UiButton
                variant="ghost"
                size="sm"
                className="text-muted-foreground"
                onClick={() => onChange(null)}
              >
                <Trash2 />
                <FormattedMessage id="content.image.clear" />
              </UiButton>
            )}
          </div>
          {value && (
            <TextField
              label={
                <FormattedMessage id="content.image.alt" values={{ lang: lang.toUpperCase() }} />
              }
              value={value.alt[lang]}
              max={altMax}
              onChange={(v) => onChange({ ...value, alt: { ...value.alt, [lang]: v } })}
            />
          )}
        </div>
      </div>
    </div>
  );
}

/** Cover picture with alt text per language (or none). */
export function CoverField({
  value,
  onChange,
  lang,
}: {
  value: { image: string; alt: Loc } | null;
  onChange: (v: { image: string; alt: Loc } | null) => void;
  lang: Lang;
}) {
  return <PictureField value={value} onChange={onChange} lang={lang} />;
}

// ---------- Issues (what blocks "Gửi duyệt") ----------

export type ParseIssue = { path: ReadonlyArray<PropertyKey>; message: string };

/** A short, readable place for a schema issue: "Nội dung (EN) · khối 3". */
export function issuePlace(intl: IntlShape, path: ReadonlyArray<PropertyKey>): string {
  const parts: string[] = [];
  for (let i = 0; i < path.length; i++) {
    const p = path[i];
    if (p === 'vi' || p === 'en') parts.push(String(p).toUpperCase());
    else if (typeof p === 'number')
      parts.push(intl.formatMessage({ id: 'content.issue.item' }, { n: p + 1 }));
    else {
      const id = `content.field.${String(p)}`;
      parts.push(intl.messages[id] ? intl.formatMessage({ id }) : String(p));
    }
  }
  return parts.join(' · ');
}

export function IssuesList({ issues }: { issues: ParseIssue[] }) {
  const intl = useIntl();
  if (!issues.length) return null;
  const places = [...new Set(issues.map((i) => issuePlace(intl, i.path)))];
  return (
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
  );
}

// ---------- The family's emergency number (D-078, D-087, P-166 #1) ----------

/**
 * What the previews show for `{emergency}`: the app writes the number of the family's country
 * (115 in Việt Nam, 911 in the US…), and 115 when it knows none.
 */
export const previewEmergencyNumber = '115';

export const withEmergency = (s: string) =>
  s.split(contentEmergencyToken).join(previewEmergencyNumber);

/** A draft with `{emergency}` written as the preview number in every text (previews only). */
export function fillEmergency<T>(v: T): T {
  if (typeof v === 'string') return withEmergency(v) as T;
  if (Array.isArray(v)) return v.map((x: unknown) => fillEmergency(x)) as T;
  if (v && typeof v === 'object') {
    return Object.fromEntries(
      Object.entries(v as Record<string, unknown>).map(([k, x]) => [k, fillEmergency(x)]),
    ) as T;
  }
  return v;
}

/** "Dùng {emergency} thay cho số 115: …", under the fields that may name the number. */
export function EmergencyHint() {
  return (
    <FormattedMessage
      id="content.emergency.hint"
      values={{ token: <code className="font-mono text-[0.95em]">{contentEmergencyToken}</code> }}
    />
  );
}

/** Splits a `literalEmergencyProblems` path ("body.vi.3.text") for the place labels. */
const pathParts = (path: string): PropertyKey[] =>
  path.split('.').map((p) => (/^\d+$/.test(p) ? Number(p) : p));

/**
 * The texts that write "115" instead of `{emergency}` (`literalEmergencyProblems`), naming each
 * field. A warning only: saving and the workflow go on (the seed tests refuse it).
 */
export function EmergencyNotice({
  data,
  place = issuePlace,
  className = 'mb-4',
}: {
  data: unknown;
  /** The field names of the kind (solids, nutrition); the article ones by default. */
  place?: (intl: IntlShape, path: ReadonlyArray<PropertyKey>) => string;
  className?: string;
}) {
  const intl = useIntl();
  const found = useMemo(() => literalEmergencyProblems(data), [data]);
  if (!found.length) return null;
  const places = [...new Set(found.map((p) => place(intl, pathParts(p.path))))];
  return (
    <Notice
      tone="warn"
      className={className}
      title={<FormattedMessage id="content.emergency.title" values={{ n: found.length }} />}
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
      <p className="mt-2 text-xs">
        <EmergencyHint />
      </p>
    </Notice>
  );
}

// ---------- Phone previews (4d, 2b) ----------

/**
 * The 4d body. An `urgent` callout is red with the app's call button (D-087, P-166 #2); the
 * button names the preview number.
 */
export function BlocksPreview({ blocks, lang = 'vi' }: { blocks: ContentBlock[]; lang?: Lang }) {
  const intl = useIntl();
  return (
    <div className="cl-blocks">
      {blocks.map((b, i) => {
        switch (b.type) {
          case 'paragraph':
            return <p key={i}>{b.text}</p>;
          case 'heading':
            return <h4 key={i}>{b.text}</h4>;
          case 'bullets':
            return (
              <ul key={i}>
                {b.items.map((x, j) => (
                  <li key={j}>{x}</li>
                ))}
              </ul>
            );
          case 'callout':
            return b.tone === 'urgent' ? (
              <div key={i} className="cl-callout cl-callout--urgent">
                <span className="cl-callout__head">
                  <TriangleAlert className="size-4 shrink-0" aria-hidden="true" />
                  <strong>{b.title}</strong>
                </span>
                <p>{b.text}</p>
                <span className="cl-callout__call">
                  <Phone className="size-4" aria-hidden="true" />
                  {intl.formatMessage(
                    { id: `content.preview.call.${lang}` },
                    { number: previewEmergencyNumber },
                  )}
                </span>
              </div>
            ) : (
              <div key={i} className={`cl-callout cl-callout--${b.tone}`}>
                <strong>{b.title}</strong>
                <p>{b.text}</p>
              </div>
            );
          case 'image':
            return (
              <figure key={i}>
                <ImageThumb id={b.image} size={300} />
                {b.caption && <figcaption>{b.caption}</figcaption>}
              </figure>
            );
        }
      })}
    </div>
  );
}

export function PhoneFrame({ children }: { children: ReactNode }) {
  return (
    <div className="cl-phone no-scrollbar" aria-label="preview">
      {children}
    </div>
  );
}

/** The preview card in an editor's side column; it follows the form's language. */
export function PreviewCard({
  lang,
  onLang,
  children,
}: {
  lang: Lang;
  /** A language switch on the card itself (when the form has none). */
  onLang?: (l: Lang) => void;
  children: ReactNode;
}) {
  return (
    <section className="grid gap-3 rounded-xl border bg-card p-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h2 className="text-[15px] font-semibold">
          <FormattedMessage id="content.preview" />
        </h2>
        {onLang ? (
          <LangTabs value={lang} onChange={onLang} />
        ) : (
          <Badge variant="outline" className="font-normal text-muted-foreground">
            <FormattedMessage id={`content.lang.${lang}`} />
          </Badge>
        )}
      </div>
      {children}
    </section>
  );
}

/** "Nội dung minh hoạ · chờ chuyên môn duyệt" or the reviewer line. */
export function ReviewLine({ review, lang }: { review: EditorialReview | null; lang: Lang }) {
  const intl = useIntl();
  const msg = (id: string, values?: Record<string, string>) =>
    intl.formatMessage({ id: `content.preview.${id}.${lang}` }, values);
  return (
    <p className="cl-byline">
      {review
        ? msg('reviewed', { who: review.reviewer, on: dmy(review.reviewedOn).slice(3) })
        : msg('illustrative')}
    </p>
  );
}

/** For filters: all topics in their 4a order. */
export const topicOptions = (intl: IntlShape) =>
  articleTopics.map((t) => ({ value: t, label: intl.formatMessage({ id: `content.topic.${t}` }) }));

/** A solids guide's group (D-087), read defensively from a row or a draft; null when unset. */
export const subtopicOf = (v: unknown): SolidsSubtopic | null =>
  (solidsSubtopics as readonly unknown[]).includes(v) ? (v as SolidsSubtopic) : null;

/** The Thư viện ăn dặm groups in their app order: Bắt đầu … Ăn cùng gia đình. */
export const subtopicOptions = (intl: IntlShape) =>
  solidsSubtopics.map((s) => ({
    value: s,
    label: intl.formatMessage({ id: `content.subtopic.${s}` }),
  }));

export const calloutToneOptions = (intl: IntlShape) =>
  calloutTones.map((t) => ({
    value: t,
    label: intl.formatMessage({ id: `content.callout.${t}` }),
  }));

/** The review shown in previews: the one waiting to publish, else the published one. */
export function reviewOf(item: ContentItemView<unknown> | null): EditorialReview {
  return item?.pendingReview ?? (item?.published?.review as EditorialReview | undefined) ?? null;
}
