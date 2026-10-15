import {
  articleTopics,
  calloutTones,
  contentImageUploadSchema,
  contentLimits,
  editorialChecks,
  memberRoles,
  type ArticleTopic,
  type ContentBlock,
  type ContentKind,
  type EditorialAction,
  type EditorialCheck,
  type EditorialDisplayStatus,
  type EditorialReview,
  type EditorialStatus,
  type MemberRole,
  type StageAge,
  type StageUnit,
} from '@child-life/contracts';
import { createContext, useContext, useId, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { ApiError, useApi, useLoad, type Api } from '../api';
import { ZONE } from '../format';
import {
  Button,
  Empty,
  Modal,
  Pill,
  ReasonField,
  Segmented,
  errorMessageId,
  reasonOk,
  type PillTone,
} from '../ui';
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
  counts: Record<ContentKind, ContentCounts>;
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

/** Workflow status, plus "Trên app · rev n" and "Minh hoạ" when something is live. */
export function StatusCell({ row }: { row: ContentRow }) {
  return (
    <span className="cl-status">
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

export function useContentList<T = ContentListView>(view: ContentKind | 'queue') {
  return useLoad<T>('staffContentList', { view }, `content:${view}`);
}

/** "Nhập bản nháp mẫu": imports the engineering drafts that are not there yet. */
export function SeedButton({ kind, onDone }: { kind: ContentKind; onDone: () => void }) {
  const api = useApi();
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState<{ added: number; skipped: number } | null>(null);
  const [error, setError] = useState<ApiError | null>(null);
  return (
    <span className="cl-seed">
      <Button
        disabled={busy}
        onClick={() => {
          setBusy(true);
          setError(null);
          api
            .call<{ added: Record<string, number>; skipped: number }>('staffContentSeed', {
              kinds: [kind],
            })
            .then((r) => {
              setDone({ added: r.added[kind] ?? 0, skipped: r.skipped });
              onDone();
            })
            .catch((e: unknown) => setError(asApiError(e)))
            .finally(() => setBusy(false));
        }}
      >
        <FormattedMessage id="content.seed" />
      </Button>
      {done && (
        <span className="muted" role="status">
          <FormattedMessage id="content.seedDone" values={done} />
        </span>
      )}
      {error && (
        <span className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </span>
      )}
    </span>
  );
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

export interface ActInput {
  reason: string;
  checks: EditorialCheck[];
  review: { reviewer: string; credential: string; reviewedOn: string };
  withReview: boolean;
}

export function blankActInput(today: string): ActInput {
  return {
    reason: '',
    checks: [],
    review: { reviewer: '', credential: '', reviewedOn: today },
    withReview: false,
  };
}

/** The `staffContentAct` request, or null while the dialog is not complete. */
export function contentActRequest(
  kind: ContentKind,
  id: string,
  action: EditorialAction,
  input: ActInput,
  requireReview: boolean,
): Record<string, unknown> | null {
  const needsReason = action === 'reject' || action === 'unpublish';
  if (needsReason && !reasonOk(input.reason)) return null;
  if (action === 'approve' && !editorialChecks.every((c) => input.checks.includes(c))) return null;
  const takesReview = action === 'approve' || action === 'reconfirm';
  const wantsReview = takesReview && (input.withReview || requireReview);
  const r = input.review;
  if (wantsReview && (!r.reviewer.trim() || !r.credential.trim() || !r.reviewedOn)) return null;
  return {
    kind,
    id,
    action,
    reason: input.reason.trim(),
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
  const reviewId = useId();
  const [input, setInput] = useState<ActInput>(() => blankActInput(today));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const request = contentActRequest(kind, id, action, input, requireReview);
  const blocked = (action === 'approve' || action === 'reconfirm') && sameEditor;
  const takesReview = action === 'approve' || action === 'reconfirm';
  const set = (patch: Partial<ActInput>) => setInput((i) => ({ ...i, ...patch }));
  return (
    <Modal title={<FormattedMessage id={`content.act.${action}.title`} />} onClose={onClose}>
      <p className="modal__sub">
        <strong>{title}</strong>
      </p>
      <p className="muted">
        <FormattedMessage id={`content.act.${action}.body`} />
      </p>
      {blocked && (
        <p className="error" role="alert">
          <FormattedMessage id="content.act.samePerson" />
        </p>
      )}
      {action === 'approve' && (
        <fieldset className="cl-checks">
          <legend className="field__label">
            <FormattedMessage id="content.checks.title" />
          </legend>
          {editorialChecks.map((c) => (
            <CheckRow
              key={c}
              label={<FormattedMessage id={`content.check.${c}`} />}
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
        <fieldset className="cl-review">
          <legend className="field__label">
            <FormattedMessage id="content.review.title" />
          </legend>
          {requireReview ? (
            <p className="muted">
              <FormattedMessage id="content.review.required" />
            </p>
          ) : (
            <CheckRow
              label={<FormattedMessage id="content.review.optional" />}
              checked={input.withReview}
              onChange={(on) => set({ withReview: on })}
            />
          )}
          {(input.withReview || requireReview) && (
            <div className="cl-grid3">
              {(['reviewer', 'credential'] as const).map((f) => (
                <div className="field" key={f}>
                  <label className="field__label" htmlFor={`${reviewId}-${f}`}>
                    <FormattedMessage id={`content.review.${f}`} />
                  </label>
                  <input
                    id={`${reviewId}-${f}`}
                    className="field__input"
                    maxLength={120}
                    value={input.review[f]}
                    onChange={(e) => set({ review: { ...input.review, [f]: e.target.value } })}
                  />
                </div>
              ))}
              <div className="field">
                <label className="field__label" htmlFor={`${reviewId}-on`}>
                  <FormattedMessage id="content.review.reviewedOn" />
                </label>
                <input
                  id={`${reviewId}-on`}
                  className="field__input"
                  type="date"
                  max={today}
                  value={input.review.reviewedOn}
                  onChange={(e) => set({ review: { ...input.review, reviewedOn: e.target.value } })}
                />
              </div>
            </div>
          )}
          {!requireReview && !input.withReview && (
            <p className="field__help">
              <FormattedMessage id="content.review.illustrativeNote" />
            </p>
          )}
        </fieldset>
      )}
      <ReasonField
        value={input.reason}
        onChange={(reason) => set({ reason })}
        required={action === 'reject' || action === 'unpublish'}
      />
      {error && (
        <p className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
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
              .then(onDone)
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

/** The workflow buttons under an item, each opening the dialog. */
export function WorkflowButtons({
  actions,
  onPick,
}: {
  actions: EditorialAction[];
  onPick: (a: EditorialAction) => void;
}) {
  return (
    <div className="actions">
      {actions.map((a) => (
        <Button
          key={a}
          kind={
            a === 'unpublish' || a === 'reject'
              ? 'danger'
              : a === 'archive'
                ? 'ghost'
                : a === 'publish' || a === 'approve' || a === 'submit'
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

// ---------- Fields ----------

export function LangTabs({ value, onChange }: { value: Lang; onChange: (l: Lang) => void }) {
  const intl = useIntl();
  return (
    <Segmented
      label={intl.formatMessage({ id: 'content.lang' })}
      value={value}
      onChange={onChange}
      options={langs.map((l) => ({
        value: l,
        label: <FormattedMessage id={`content.lang.${l}`} />,
      }))}
    />
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
  placeholder,
}: {
  label: ReactNode;
  value: string;
  onChange: (v: string) => void;
  max: number;
  counter?: boolean;
  multiline?: boolean;
  help?: ReactNode;
  placeholder?: string;
}) {
  const id = useId();
  const n = charCount(value);
  return (
    <div className="field">
      <label className="field__label" htmlFor={id}>
        {label}
        {counter && (
          <span className={`cl-counter ${n > max ? 'error' : 'muted'}`}>
            {' '}
            <FormattedMessage id="content.chars" values={{ n, max }} />
          </span>
        )}
      </label>
      {multiline ? (
        <textarea
          id={id}
          className="field__input"
          rows={Math.min(10, Math.max(3, Math.ceil(n / 90)))}
          value={value}
          placeholder={placeholder}
          aria-invalid={n > max ? true : undefined}
          onChange={(e) => onChange(e.target.value)}
        />
      ) : (
        <input
          id={id}
          className="field__input"
          value={value}
          placeholder={placeholder}
          aria-invalid={n > max ? true : undefined}
          onChange={(e) => onChange(e.target.value)}
        />
      )}
      {help && <p className="field__help">{help}</p>}
    </div>
  );
}

export function NumberField({
  label,
  value,
  onChange,
  min,
  max,
  help,
}: {
  label: ReactNode;
  value: number;
  onChange: (v: number) => void;
  min: number;
  max: number;
  help?: ReactNode;
}) {
  const id = useId();
  return (
    <div className="field">
      <label className="field__label" htmlFor={id}>
        {label}
      </label>
      <input
        id={id}
        className="field__input cl-num"
        type="number"
        min={min}
        max={max}
        value={Number.isFinite(value) ? value : ''}
        onChange={(e) => onChange(e.target.value === '' ? Number.NaN : Number(e.target.value))}
      />
      {help && <p className="field__help">{help}</p>}
    </div>
  );
}

/** "Mỗi dòng một ý": up to [max] points; the counter turns red past it. */
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
  const id = useId();
  const [text, setText] = useState(value.join('\n'));
  const tooLong = value.some((v) => charCount(v) > itemMax);
  return (
    <div className="field">
      <label className="field__label" htmlFor={id}>
        {label}{' '}
        <span className={value.length > max ? 'error' : 'muted'}>
          {value.length}/{max}
        </span>
      </label>
      <textarea
        id={id}
        className="field__input"
        rows={Math.max(3, Math.min(8, value.length + 1))}
        value={text}
        aria-invalid={value.length > max || tooLong ? true : undefined}
        onChange={(e) => {
          setText(e.target.value);
          onChange(
            e.target.value
              .split('\n')
              .map((l) => l.trim())
              .filter(Boolean),
          );
        }}
      />
      <p className={`field__help ${tooLong ? 'error' : ''}`}>
        <FormattedMessage id="content.onePerLine" values={{ max: itemMax }} />
      </p>
    </div>
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
    <fieldset className="cl-sources">
      <legend className="field__label">
        <FormattedMessage id="content.sources" />{' '}
        <span className="muted">
          {value.length}/{max}
        </span>
      </legend>
      {value.map((s, i) => (
        <div className="cl-source" key={i}>
          <input
            className="field__input"
            aria-label={intl.formatMessage({ id: 'content.source.label' })}
            placeholder={intl.formatMessage({ id: 'content.source.label' })}
            value={s.label}
            maxLength={200}
            onChange={(e) =>
              onChange(value.map((x, j) => (j === i ? { ...x, label: e.target.value } : x)))
            }
          />
          <input
            className="field__input mono"
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
        <Button kind="ghost" onClick={() => onChange([...value, { label: '', url: '' }])}>
          <FormattedMessage id="content.source.add" />
        </Button>
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
    <fieldset className="field">
      <legend className="field__label">
        <FormattedMessage id="content.audience" />
      </legend>
      <div className="chips">
        {memberRoles.map((r) => {
          const on = value.includes(r);
          return (
            <button
              key={r}
              type="button"
              className={`chip ${on ? 'chip--on' : ''}`}
              aria-pressed={on}
              onClick={() => onChange(on ? value.filter((x) => x !== r) : [...value, r])}
            >
              {on ? '✓ ' : ''}
              <FormattedMessage id={`content.audience.${r}`} />
            </button>
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
    <div className="field">
      <span className="field__label">
        {label}{' '}
        <span className={value.length > max ? 'error' : 'muted'}>
          {value.length}/{max}
        </span>
      </span>
      <div className="chips">
        {value.map((id) => (
          <span key={id} className={`cl-tag cl-tag--${tone}`}>
            {titleOf(id)}
            <button
              type="button"
              className="cl-tag__x"
              aria-label={intl.formatMessage({ id: 'content.remove' })}
              onClick={() => onChange(value.filter((x) => x !== id))}
            >
              ×
            </button>
          </span>
        ))}
        {value.length < max && (
          <button type="button" className="chip" onClick={() => setOpen(true)}>
            <FormattedMessage id="content.link.add" />
          </button>
        )}
      </div>
      {open && (
        <Modal title={label} onClose={() => setOpen(false)}>
          <input
            className="field__input"
            type="search"
            value={q}
            aria-label={intl.formatMessage({ id: 'content.search' })}
            placeholder={intl.formatMessage({ id: 'content.search' })}
            onChange={(e) => setQ(e.target.value)}
          />
          {shown.length ? (
            <ul className="cl-pick">
              {shown.map((o) => {
                const on = value.includes(o.id);
                return (
                  <li key={o.id}>
                    <CheckRow
                      label={
                        <span>
                          {o.title} {o.meta && <span className="muted">· {o.meta}</span>}
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
      {id ? '!' : '—'}
    </span>
  );
}

const imageTypes = ['image/png', 'image/jpeg', 'image/webp'];

/** Picks an uploaded picture or uploads a new one (re-encoded to WebP by the server). */
export function ImagePickerButton({ onPick }: { onPick: (id: string) => void }) {
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
      <Button onClick={() => setOpen(true)}>
        <FormattedMessage id="content.image.pick" />
      </Button>
      {open && (
        <Modal
          wide
          title={<FormattedMessage id="content.image.title" />}
          onClose={() => setOpen(false)}
        >
          {canUpload && (
            <div className="cl-upload">
              <FilePicker
                id={fileId}
                accept={imageTypes.join(',')}
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
                <div className="actions">
                  <input
                    className="field__input mono"
                    aria-label={intl.formatMessage({ id: 'content.image.name' })}
                    value={name}
                    maxLength={40}
                    onChange={(e) => setName(e.target.value)}
                  />
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
                <p className="error" role="alert">
                  <FormattedMessage id={problem} />
                </p>
              )}
              {error && (
                <p className="error" role="alert">
                  <FormattedMessage id={errorMessageId(error)} />
                </p>
              )}
            </div>
          )}
          <input
            className="field__input"
            type="search"
            value={q}
            aria-label={intl.formatMessage({ id: 'content.search' })}
            placeholder={intl.formatMessage({ id: 'content.search' })}
            onChange={(e) => setQ(e.target.value)}
          />
          {shown.length ? (
            <ul className="cl-images">
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
                    <span className="mono">{img.id}</span>
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
  return (
    <div className="field">
      <span className="field__label">
        <FormattedMessage id="content.cover" />
      </span>
      <div className="cl-cover">
        <ImageThumb id={value?.image ?? null} />
        <div className="stack cl-tight">
          <div className="actions">
            <ImagePickerButton
              onPick={(image) => onChange({ image, alt: value?.alt ?? { vi: '', en: '' } })}
            />
            {value && (
              <Button kind="ghost" onClick={() => onChange(null)}>
                <FormattedMessage id="content.image.clear" />
              </Button>
            )}
          </div>
          {value && (
            <TextField
              label={
                <FormattedMessage id="content.image.alt" values={{ lang: lang.toUpperCase() }} />
              }
              value={value.alt[lang]}
              max={contentLimits.alt}
              onChange={(v) => onChange({ ...value, alt: { ...value.alt, [lang]: v } })}
            />
          )}
        </div>
      </div>
    </div>
  );
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
  return (
    <div className="cl-issues" role="alert">
      <strong>
        <FormattedMessage id="content.issues" values={{ n: issues.length }} />
      </strong>
      <ul>
        {issues.slice(0, 12).map((i, n) => (
          <li key={n}>{issuePlace(intl, i.path)}</li>
        ))}
      </ul>
    </div>
  );
}

// ---------- Phone previews (4d, 2b) ----------

export function BlocksPreview({ blocks }: { blocks: ContentBlock[] }) {
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
            return (
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
    <div className="cl-phone" aria-label="preview">
      {children}
    </div>
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

export const calloutToneOptions = (intl: IntlShape) =>
  calloutTones.map((t) => ({
    value: t,
    label: intl.formatMessage({ id: `content.callout.${t}` }),
  }));

/** The review shown in previews: the one waiting to publish, else the published one. */
export function reviewOf(item: ContentItemView<unknown> | null): EditorialReview {
  return item?.pendingReview ?? (item?.published?.review as EditorialReview | undefined) ?? null;
}
