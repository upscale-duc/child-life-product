import {
  defaultRhythmRules,
  rankingWeights,
  staffCan,
  type Activity,
  type AgeCard,
  type Flags,
  type ReferenceStage,
  type RhythmContent,
  type RhythmDoc,
  type RhythmRules,
} from '@child-life/contracts';
import { Fragment, useCallback, useEffect, useMemo, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import {
  ApiError,
  useApi,
  useLoad,
  type ContentDraftData,
  type FlagsView,
  type ReferenceDraftData,
  type RhythmDocView,
  type RhythmReview,
  type RhythmRulesView,
  type RhythmVersion,
  type RhythmView,
} from '../api';
import { routePaths, subPath, useNavigate, useStaff } from '../context';
import { ZONE } from '../format';
import {
  Button,
  Empty,
  Loaded,
  LockNote,
  Modal,
  Page,
  Panel,
  Pill,
  ReasonField,
  RowActions,
  Segmented,
  TableScroll,
  errorMessageId,
  reasonOk,
  type PillTone,
} from '../ui';
import { IssuesContext, moveItem, type Issue } from './FirstAidEditor';
import {
  ActivityEditor,
  AgeCardEditor,
  HealthEditor,
  ModelEditor,
  StageEditor,
  NumberInput,
  TextInput,
  blankActivity,
  blankAgeCard,
  blankStage,
  contentDraftFrom,
  dmy,
  forbiddenPhrases,
  monthsOf,
  referenceDraftFrom,
  rhythmActRequest,
  rhythmIssueText,
  rhythmReviewFrom,
  sendRhythmAct,
  ruleIssueText,
  rulesIssues,
  saveRhythmDraft,
  saveRhythmRules,
  starterContent,
  starterReference,
  validateRhythmDraft,
  windowPreview,
  withNewVersions,
  type Act,
  type ActivityOption,
  type Check,
  type Edit,
  type ForbiddenHit,
  type ReviewInput,
} from './RhythmEditor';

/**
 * Nhịp lớn lên (PN01–PN04, plan §5.6 / §7.1, D-073 #2). Two published documents on the Sơ cứu
 * workflow: the reference model (`publicConfig/rhythm_reference`) and the content pack
 * (`publicConfig/content_rhythm`: activities, age cards, health routing). "Tạo phiên bản mới"
 * opens a working copy, "Lưu nháp" keeps one open version per document, "Gửi duyệt" hands it to
 * another person with "Nội dung · Duyệt", whose approval publishes it (on prod with the qualified
 * review). Rules (`config/rhythm`, PN04) are versioned thresholds saved with a reason
 * (Tính năng · Sửa). Every step is in the audit log.
 */

export type Tab = 'reference' | 'content' | 'rules';
const tabs: Tab[] = ['reference', 'content', 'rules'];
type ContentTab = 'activities' | 'ageCards' | 'health';

const statusTone: Record<string, PillTone> = {
  draft: 'muted',
  pending: 'wait',
  published: 'ok',
  retired: 'muted',
  discarded: 'muted',
};
const itemTone: Record<string, PillTone> = { draft: 'muted', published: 'ok', retired: 'muted' };

const asApiError = (e: unknown) => (e instanceof ApiError ? e : new ApiError('unknown', null));

function dateTime(intl: IntlShape, iso: string | null | undefined): string {
  return iso
    ? intl.formatDate(iso, {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        timeZone: ZONE,
      })
    : '—';
}

const textOf = (intl: IntlShape, t: { vi: string; en: string } | null | undefined) =>
  t ? (intl.locale.startsWith('vi') ? t.vi : t.en) || t.vi : '';

const todayIso = () => new Date().toLocaleDateString('en-CA', { timeZone: ZONE });

function tabFromUrl(): Tab {
  const t = subPath('rhythm', window.location.pathname)[0];
  return tabs.includes(t as Tab) && t !== 'reference' ? (t as Tab) : 'reference';
}

export function RhythmScreen() {
  const staff = useStaff();
  const [load, reload] = useLoad<RhythmView>('staffRhythm', {}, 'rhythm');
  return (
    <Page
      title={<FormattedMessage id="rhythm.title" />}
      subtitle={<FormattedMessage id="rhythm.sub" />}
    >
      <Loaded load={load} reload={reload}>
        {(view) => (
          <RhythmBody
            view={view}
            canEdit={staffCan(staff.levels, 'content.edit')}
            canApprove={staffCan(staff.levels, 'content.approve')}
            canViewRules={staffCan(staff.levels, 'features.view')}
            canEditRules={staffCan(staff.levels, 'flags.rollout')}
            onChanged={reload}
          />
        )}
      </Loaded>
    </Page>
  );
}

/** A working copy of one document: edits apply to a fresh clone (undo-safe re-renders). */
function useWorking<T>() {
  const [editing, setEditing] = useState<T | null>(null);
  const [dirty, setDirty] = useState(false);
  const [showIssues, setShowIssues] = useState(false);
  const edit: Edit<T> = useCallback((fn) => {
    setEditing((p) => {
      if (!p) return p;
      const next = structuredClone(p);
      fn(next);
      return next;
    });
    setDirty(true);
  }, []);
  const start = (v: T) => {
    setEditing(v);
    setDirty(false);
    setShowIssues(false);
  };
  const stop = () => {
    setEditing(null);
    setDirty(false);
    setShowIssues(false);
  };
  return { editing, dirty, showIssues, setShowIssues, edit, start, stop };
}

type Dialog =
  | { kind: 'act'; doc: RhythmDoc; act: Act; versionId: string }
  | { kind: 'save'; doc: RhythmDoc }
  | null;

export function RhythmBody({
  view,
  canEdit,
  canApprove,
  canViewRules,
  canEditRules,
  onChanged,
  initialTab,
  rules,
  flags,
  today,
}: {
  view: RhythmView;
  canEdit: boolean;
  canApprove: boolean;
  /** `features.view`: the server's condition for reading `config/rhythm`. */
  canViewRules: boolean;
  /** `flags.rollout` (Tính năng · Sửa): the server's condition for saving it. */
  canEditRules: boolean;
  onChanged: () => void;
  /** Tests (no window): the tab to open. */
  initialTab?: Tab;
  /** Tests: the rules and flags as loaded; the screen loads them itself otherwise. */
  rules?: RhythmRulesView | null;
  flags?: Flags | null;
  /** Tests: "today" for the sample due date. */
  today?: string;
}) {
  const intl = useIntl();
  const [tab, setTab] = useState<Tab>(
    () => initialTab ?? (typeof window === 'undefined' ? 'reference' : tabFromUrl()),
  );
  useEffect(() => {
    if (typeof window === 'undefined') return;
    const url = tab === 'reference' ? routePaths.rhythm : `${routePaths.rhythm}/${tab}`;
    if (window.location.pathname !== url) window.history.replaceState({}, '', url);
  }, [tab]);

  const ref = useWorking<ReferenceDraftData>();
  const content = useWorking<ContentDraftData>();
  const rd = view.reference.draft;
  const cd = view.content.draft;
  const [showRefDraft, setShowRefDraft] = useState(!!rd);
  const [showContentDraft, setShowContentDraft] = useState(!!cd);
  useEffect(() => setShowRefDraft(!!rd), [rd?.versionId]);
  useEffect(() => setShowContentDraft(!!cd), [cd?.versionId]);
  const [dialog, setDialog] = useState<Dialog>(null);

  const shownRef: ReferenceDraftData | null =
    ref.editing ?? (showRefDraft && rd ? rd.data : (view.reference.current ?? null));
  const shownContent: ContentDraftData | null =
    content.editing ?? (showContentDraft && cd ? cd.data : (view.content.current ?? null));
  const refCheck = useMemo(
    () => (ref.editing ? validateRhythmDraft('reference', ref.editing) : null),
    [ref.editing],
  );
  const contentCheck = useMemo(
    () => (content.editing ? validateRhythmDraft('content', content.editing) : null),
    [content.editing],
  );

  // Leaving with unsaved changes asks first.
  const dirty = (ref.editing && ref.dirty) || (content.editing && content.dirty);
  useEffect(() => {
    if (!dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);
  const confirmLeave = (isDirty: boolean) =>
    !isDirty || window.confirm(intl.formatMessage({ id: 'firstAid.leaveConfirm' }));

  // Activities a stage can link: the content being edited, else its draft, else what is live.
  const activityOptions: ActivityOption[] = (
    content.editing?.activities ??
    cd?.data.activities ??
    view.content.current?.activities ??
    []
  ).map((a) => ({ id: a.id, title: textOf(intl, a.title), durationMin: a.durationMin }));

  const [dueDate, setDueDate] = useState(() => today ?? todayIso());

  return (
    <div className="stack">
      <Segmented
        label={intl.formatMessage({ id: 'rhythm.title' })}
        value={tab}
        onChange={setTab}
        options={tabs.map((t) => ({
          value: t,
          label: <FormattedMessage id={`rhythm.tab.${t}`} />,
        }))}
      />

      {tab === 'reference' && (
        <IssuesContext.Provider
          value={{ issues: refCheck?.issues ?? new Map(), show: ref.showIssues }}
        >
          <ReferenceTab
            view={view}
            shown={shownRef}
            working={ref}
            check={refCheck}
            canEdit={canEdit}
            canApprove={canApprove}
            showDraft={showRefDraft}
            onToggleDraft={() => setShowRefDraft(!showRefDraft)}
            onStart={() => {
              ref.start(
                rd
                  ? referenceDraftFrom(rd.data)
                  : view.reference.current
                    ? referenceDraftFrom(view.reference.current)
                    : starterReference(),
              );
              setShowRefDraft(!!rd);
            }}
            onStop={() => confirmLeave(ref.dirty) && ref.stop()}
            onSave={() => {
              ref.setShowIssues(true);
              if (refCheck?.ok) setDialog({ kind: 'save', doc: 'reference' });
            }}
            onAct={(act, versionId) => setDialog({ kind: 'act', doc: 'reference', act, versionId })}
            dueDate={dueDate}
            onDueDate={setDueDate}
            activities={activityOptions}
            flags={flags}
          />
        </IssuesContext.Provider>
      )}

      {tab === 'content' && (
        <IssuesContext.Provider
          value={{ issues: contentCheck?.issues ?? new Map(), show: content.showIssues }}
        >
          <ContentTab
            view={view}
            shown={shownContent}
            working={content}
            check={contentCheck}
            canEdit={canEdit}
            canApprove={canApprove}
            showDraft={showContentDraft}
            onToggleDraft={() => setShowContentDraft(!showContentDraft)}
            onStart={() => {
              // Editing a draft keeps it as is (`review` included); from the live pack, a copy.
              content.start(
                cd
                  ? contentDraftFrom(cd.data)
                  : view.content.current
                    ? contentDraftFrom(view.content.current)
                    : starterContent(),
              );
              setShowContentDraft(!!cd);
            }}
            onStop={() => confirmLeave(content.dirty) && content.stop()}
            onSave={() => {
              content.setShowIssues(true);
              if (contentCheck?.ok) setDialog({ kind: 'save', doc: 'content' });
            }}
            onAct={(act, versionId) => setDialog({ kind: 'act', doc: 'content', act, versionId })}
          />
        </IssuesContext.Provider>
      )}

      {tab === 'rules' && (
        <RulesTab
          canView={canViewRules}
          canEdit={canEditRules}
          rules={rules}
          content={view.content.current}
        />
      )}

      {dialog?.kind === 'save' && (
        <SaveDialog
          doc={dialog.doc}
          data={
            dialog.doc === 'reference'
              ? ref.editing!
              : withNewVersions(content.editing!, view.content.current)
          }
          notes={(dialog.doc === 'reference' ? rd?.notes : cd?.notes) ?? ''}
          pending={(dialog.doc === 'reference' ? rd?.status : cd?.status) === 'pending'}
          onClose={() => setDialog(null)}
          onDone={() => {
            if (dialog.doc === 'reference') ref.stop();
            else content.stop();
            onChanged();
          }}
        />
      )}
      {dialog?.kind === 'act' && (
        <ActDialog
          doc={dialog.doc}
          act={dialog.act}
          versionId={dialog.versionId}
          requireReview={view.requireReview}
          onClose={() => setDialog(null)}
          onDone={onChanged}
        />
      )}
    </div>
  );
}

type Working<T> = ReturnType<typeof useWorking<T>>;

// ---------- Status, edit bar, history (shared by both documents) ----------

function ReviewText({ review }: { review: RhythmReview }) {
  return review ? (
    <FormattedMessage
      id="rhythm.reviewedBy"
      values={{
        name: review.reviewer,
        credential: review.credential,
        date: dmy(review.reviewedOn),
      }}
    />
  ) : (
    <FormattedMessage id="rhythm.notReviewed" />
  );
}

/** D-073 #2: content nobody qualified signed off yet is labelled, never hidden. */
export function TechnicalDraftBadge() {
  return (
    <Pill tone="warn">
      <FormattedMessage id="rhythm.technicalDraft" />
    </Pill>
  );
}

function StatusPanels({
  doc,
  docView,
  size,
  currentReview,
  canEdit,
  canApprove,
  editing,
  showDraft,
  onToggleDraft,
  onEdit,
  onAct,
}: {
  doc: RhythmDoc;
  docView: RhythmDocView<{ version: string; publishedAt: string | null }, unknown>;
  size: (v: RhythmVersion) => ReactNode;
  currentReview: ReactNode;
  canEdit: boolean;
  canApprove: boolean;
  editing: boolean;
  showDraft: boolean;
  onToggleDraft: () => void;
  onEdit: () => void;
  onAct: (act: Act, versionId: string) => void;
}) {
  const intl = useIntl();
  const c = docView.current;
  const d = docView.draft;
  return (
    <>
      <div className="toolbar">
        <span className="chips">
          {c ? (
            <>
              <Pill tone="ok">
                <FormattedMessage id="rhythm.inUse" values={{ v: c.version }} />
              </Pill>
              <span className="muted">
                <FormattedMessage
                  id="rhythm.publishedAt"
                  values={{ when: dateTime(intl, c.publishedAt) }}
                />
              </span>
              {currentReview}
            </>
          ) : (
            <Pill tone="muted">
              <FormattedMessage id="rhythm.notPublished" />
            </Pill>
          )}
        </span>
        {canEdit && !editing && (
          <div className="actions">
            <Button kind={d ? 'secondary' : 'primary'} onClick={onEdit}>
              <FormattedMessage id={d ? 'rhythm.editDraft' : 'rhythm.newVersion'} />
            </Button>
          </div>
        )}
      </div>

      {d && (
        <Panel
          className="draft-panel"
          title={
            <span className="chips">
              <Pill tone={statusTone[d.status] ?? 'muted'}>
                <FormattedMessage id={`rhythm.status.${d.status}`} />
              </Pill>
              <FormattedMessage id={`rhythm.openVersion.${doc}`} />
            </span>
          }
          note={
            <FormattedMessage
              id="rhythm.draftBy"
              values={{
                name: d.authorName || '—',
                when: dateTime(intl, d.updatedAt),
                size: size(d),
              }}
            />
          }
          aside={
            <div className="actions">
              {c && !editing && (
                <Button kind="ghost" onClick={onToggleDraft}>
                  <FormattedMessage id={showDraft ? 'rhythm.showCurrent' : 'rhythm.showDraft'} />
                </Button>
              )}
              {canEdit && d.status === 'draft' && (
                <>
                  <Button onClick={() => onAct('discard', d.versionId)}>
                    <FormattedMessage id="rhythm.act.discard" />
                  </Button>
                  <Button
                    kind="primary"
                    disabled={editing}
                    onClick={() => onAct('submit', d.versionId)}
                  >
                    <FormattedMessage id="rhythm.act.submit" />
                  </Button>
                </>
              )}
              {canApprove && d.status === 'pending' && (
                <>
                  <Button disabled={editing} onClick={() => onAct('reject', d.versionId)}>
                    <FormattedMessage id="rhythm.act.reject" />
                  </Button>
                  <Button
                    kind="primary"
                    disabled={editing}
                    onClick={() => onAct('approve', d.versionId)}
                  >
                    <FormattedMessage id="rhythm.act.approve" />
                  </Button>
                </>
              )}
            </div>
          }
        >
          {d.notes && <p className="quote">{d.notes}</p>}
          {d.rejection && (
            <p className="note note--warn">
              <FormattedMessage
                id="rhythm.rejected"
                values={{ name: d.rejection.by, reason: d.rejection.reason }}
              />
            </p>
          )}
          {d.status === 'pending' && (
            <p className="muted">
              <FormattedMessage id="rhythm.waitOther" />
            </p>
          )}
        </Panel>
      )}
    </>
  );
}

function EditBar({
  dirty,
  pending,
  check,
  show,
  place,
  onOpen,
  onSave,
  onCancel,
}: {
  dirty: boolean;
  pending: boolean;
  check: Check | null;
  show: boolean;
  /** "Giai đoạn 2 · signs.vi.0" for one issue. */
  place: (issue: Issue) => string;
  onOpen: (issue: Issue) => void;
  onSave: () => void;
  onCancel: () => void;
}) {
  const intl = useIntl();
  const issues = show ? (check?.list ?? []) : [];
  return (
    <Panel
      className="fa-editbar"
      title={<FormattedMessage id="rhythm.editing" />}
      note={
        <FormattedMessage
          id={
            pending ? 'firstAid.editingPending' : dirty ? 'firstAid.unsaved' : 'firstAid.noChanges'
          }
        />
      }
      aside={
        <div className="actions">
          <Button onClick={onCancel}>
            <FormattedMessage id="rhythm.stopEditing" />
          </Button>
          <Button kind="primary" disabled={!dirty} onClick={onSave}>
            <FormattedMessage id="rhythm.saveDraft" />
          </Button>
        </div>
      }
    >
      {issues.length > 0 && (
        <div className="fa-issues" role="alert">
          <p className="error">
            <FormattedMessage id="firstAid.issues" values={{ n: issues.length }} />
          </p>
          <ul>
            {issues.slice(0, 12).map((i, k) => (
              <li key={k}>
                <button type="button" className="linkbtn" onClick={() => onOpen(i)}>
                  {place(i)}
                </button>
                {': '}
                {rhythmIssueText(intl, i)}
              </li>
            ))}
          </ul>
        </div>
      )}
    </Panel>
  );
}

/** PN01 "Danh sách phiên bản": every version but the discarded ones, newest first. */
function HistoryPanel({
  doc,
  docView,
  size,
  locales,
  canApprove,
  onRollback,
}: {
  doc: RhythmDoc;
  docView: RhythmDocView<{ version: string }, unknown>;
  size: (v: RhythmVersion) => ReactNode;
  locales: (v: RhythmVersion) => string;
  canApprove: boolean;
  onRollback: (versionId: string) => void;
}) {
  const intl = useIntl();
  const items = docView.history.filter((h) => h.status !== 'discarded');
  if (!items.length) return null;
  // The version in use is already live; any other published or replaced one can come back.
  const canReuse = (h: RhythmVersion) =>
    h.status === 'retired' || (h.status === 'published' && h.label !== docView.current?.version);
  return (
    <Panel className="panel--flush" title={<FormattedMessage id={`rhythm.history.${doc}`} />}>
      <TableScroll min={900}>
        <table className="table">
          <thead>
            <tr>
              {(
                [
                  'version',
                  'status',
                  'size',
                  'review',
                  'locales',
                  'people',
                  'when',
                  'notes',
                ] as const
              ).map((c) => (
                <th key={c}>
                  <FormattedMessage id={`rhythm.col.${c}`} />
                </th>
              ))}
              <th />
            </tr>
          </thead>
          <tbody>
            {items.map((h) => (
              <tr key={h.versionId}>
                <td className="mono">{h.label ?? '—'}</td>
                <td>
                  <Pill tone={statusTone[h.status] ?? 'muted'}>
                    <FormattedMessage id={`rhythm.status.${h.status}`} />
                  </Pill>
                </td>
                <td className="nowrap">{size(h)}</td>
                <td>
                  <ReviewText review={h.review} />
                </td>
                <td className="nowrap">{locales(h)}</td>
                <td>
                  <FormattedMessage
                    id="rhythm.historyBy"
                    values={{ author: h.authorName || '—', approver: h.approverName ?? '—' }}
                  />
                </td>
                <td className="nowrap">
                  {dateTime(intl, h.approvedAt ?? h.updatedAt ?? h.createdAt)}
                </td>
                <td className="muted">{h.notes || '—'}</td>
                <td className="cell-actions">
                  {canApprove && canReuse(h) && (
                    <Button kind="ghost" onClick={() => onRollback(h.versionId)}>
                      <FormattedMessage id="rhythm.act.rollback" />
                    </Button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </TableScroll>
    </Panel>
  );
}

// ---------- Dialogs ----------

export function ActDialog({
  doc,
  act,
  versionId,
  requireReview,
  onClose,
  onDone,
}: {
  doc: RhythmDoc;
  act: Act;
  versionId: string;
  requireReview: boolean;
  onClose: () => void;
  onDone: () => void;
}) {
  const api = useApi();
  const [reason, setReason] = useState('');
  const [review, setReview] = useState<ReviewInput>({
    reviewer: '',
    credential: '',
    reviewedOn: todayIso(),
  });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const withReview = act === 'approve';
  const req = rhythmActRequest(
    doc,
    versionId,
    act,
    reason,
    withReview ? review : null,
    requireReview,
  );
  const reviewOk = !withReview || rhythmReviewFrom(review, requireReview).ok;
  const touched = !!(review.reviewer || review.credential || reasonOk(reason));
  return (
    <Modal
      wide={withReview}
      title={<FormattedMessage id={`rhythm.confirm.${act}`} />}
      onClose={onClose}
    >
      <p className="modal__sub">
        <FormattedMessage id={`rhythm.confirm.${act}.note`} />
      </p>
      {withReview && (
        <fieldset className="fa-review">
          <legend className="field__label">
            <FormattedMessage
              id={requireReview ? 'rhythm.review.required' : 'rhythm.review.optional'}
            />
          </legend>
          <label className="field">
            <span className="field__label">
              <FormattedMessage id="rhythm.review.reviewer" />
            </span>
            <input
              className="field__input"
              value={review.reviewer}
              maxLength={120}
              required={requireReview}
              onChange={(e) => setReview({ ...review, reviewer: e.target.value })}
            />
          </label>
          <label className="field">
            <span className="field__label">
              <FormattedMessage id="rhythm.review.credential" />
            </span>
            <input
              className="field__input"
              value={review.credential}
              maxLength={120}
              required={requireReview}
              onChange={(e) => setReview({ ...review, credential: e.target.value })}
            />
          </label>
          <label className="field">
            <span className="field__label">
              <FormattedMessage id="rhythm.review.reviewedOn" />
            </span>
            <input
              className="field__input"
              type="date"
              value={review.reviewedOn}
              required={requireReview}
              onChange={(e) => setReview({ ...review, reviewedOn: e.target.value })}
            />
          </label>
          {!reviewOk && (
            <p className={touched ? 'error' : 'field__help'}>
              <FormattedMessage id="rhythm.review.incomplete" />
            </p>
          )}
          {!requireReview && (
            <p className="field__help">
              <FormattedMessage id="rhythm.review.devHelp" />
            </p>
          )}
        </fieldset>
      )}
      <ReasonField value={reason} onChange={setReason} required />
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
          kind={act === 'discard' || act === 'reject' ? 'danger' : 'primary'}
          disabled={busy || !req}
          onClick={() => {
            if (!req) return;
            setBusy(true);
            setError(null);
            sendRhythmAct(
              api,
              doc,
              versionId,
              act,
              reason,
              withReview ? review : null,
              requireReview,
            )
              .then((res) => {
                if (!res.ok) throw new ApiError('invalid-argument', 'malformed');
                onClose();
                onDone();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id={`rhythm.act.${act}`} />
        </Button>
      </div>
    </Modal>
  );
}

function SaveDialog({
  doc,
  data,
  notes: initialNotes,
  pending,
  onClose,
  onDone,
}: {
  doc: RhythmDoc;
  data: ReferenceDraftData | ContentDraftData;
  notes: string;
  pending: boolean;
  onClose: () => void;
  onDone: () => void;
}) {
  const api = useApi();
  const [notes, setNotes] = useState(initialNotes);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  return (
    <Modal title={<FormattedMessage id={`rhythm.saveTitle.${doc}`} />} onClose={onClose}>
      <p className="modal__sub">
        <FormattedMessage id={pending ? 'rhythm.saveNotePending' : 'rhythm.saveNote'} />
      </p>
      <ReasonField value={notes} onChange={setNotes} />
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
          kind="primary"
          disabled={busy}
          onClick={() => {
            setBusy(true);
            setError(null);
            saveRhythmDraft(api, doc, data, notes)
              .then((res) => {
                if (!res.ok) throw new ApiError('invalid-argument', 'malformed');
                onClose();
                onDone();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id="rhythm.saveDraft" />
        </Button>
      </div>
    </Modal>
  );
}

// ---------- Tab 1: Mô hình tham khảo (PN01, PN02) ----------

const stageName = (intl: IntlShape, s: ReferenceStage, i: number) =>
  textOf(intl, s.name) || intl.formatMessage({ id: 'rhythm.stageN' }, { n: s.number || i + 1 });

function ReferenceTab({
  view,
  shown,
  working,
  check,
  canEdit,
  canApprove,
  showDraft,
  onToggleDraft,
  onStart,
  onStop,
  onSave,
  onAct,
  dueDate,
  onDueDate,
  activities,
  flags,
}: {
  view: RhythmView;
  shown: ReferenceDraftData | null;
  working: Working<ReferenceDraftData>;
  check: Check | null;
  canEdit: boolean;
  canApprove: boolean;
  showDraft: boolean;
  onToggleDraft: () => void;
  onStart: () => void;
  onStop: () => void;
  onSave: () => void;
  onAct: (act: Act, versionId: string) => void;
  dueDate: string;
  onDueDate: (d: string) => void;
  activities: ActivityOption[];
  flags: Flags | null | undefined;
}) {
  const intl = useIntl();
  const doc = view.reference;
  const editing = working.editing;
  const [selected, setSelected] = useState<number | null>(null);
  const hits = useMemo(() => (shown ? forbiddenPhrases(shown.stages) : []), [shown]);
  const liveIds = useMemo(() => new Set(doc.current?.stages.map((s) => s.id) ?? []), [doc.current]);
  const size = (v: RhythmVersion) => (
    <FormattedMessage id="rhythm.size.reference" values={{ n: v.stages ?? 0 }} />
  );
  const stage = selected !== null ? shown?.stages[selected] : undefined;
  const open = (i: number | null) => {
    setSelected(i);
    window.scrollTo?.(0, 0);
  };
  return (
    <>
      <StatusPanels
        doc="reference"
        docView={doc}
        size={size}
        currentReview={
          doc.current &&
          (doc.current.review ? (
            <span className="muted">
              <ReviewText review={doc.current.review} />
            </span>
          ) : (
            <TechnicalDraftBadge />
          ))
        }
        canEdit={canEdit}
        canApprove={canApprove}
        editing={!!editing}
        showDraft={showDraft}
        onToggleDraft={onToggleDraft}
        onEdit={onStart}
        onAct={onAct}
      />
      {editing && (
        <EditBar
          dirty={working.dirty}
          pending={doc.draft?.status === 'pending'}
          check={check}
          show={working.showIssues}
          place={(i) => {
            if (i.path[0] === 'stages' && typeof i.path[1] === 'number') {
              const s = editing.stages[i.path[1]];
              const name = s ? stageName(intl, s, i.path[1]) : `#${i.path[1] + 1}`;
              return i.path.length > 2 ? `${name} · ${i.path.slice(2).join('.')}` : name;
            }
            return i.path.join('.') || '—';
          }}
          onOpen={(i) =>
            open(i.path[0] === 'stages' && typeof i.path[1] === 'number' ? i.path[1] : null)
          }
          onSave={onSave}
          onCancel={() => {
            onStop();
            if (selected !== null && selected >= (shown?.stages.length ?? 0)) setSelected(null);
          }}
        />
      )}

      {!shown ? (
        <Panel>
          <Empty>
            <FormattedMessage id={canEdit ? 'rhythm.emptyEdit' : 'rhythm.empty'} />
          </Empty>
        </Panel>
      ) : stage && selected !== null ? (
        <div className="stack">
          <div className="toolbar">
            <button type="button" className="linkbtn" onClick={() => open(null)}>
              ← <FormattedMessage id="rhythm.backStages" />
            </button>
            <span className="muted">{stageName(intl, stage, selected)}</span>
          </div>
          <div className="cols cols--2-1">
            <Panel>
              {editing ? (
                <StageEditor
                  key={selected}
                  model={editing}
                  index={selected}
                  edit={working.edit}
                  idLocked={liveIds.has(stage.id)}
                  dueDate={dueDate}
                  activities={activities}
                />
              ) : (
                <StageSummary stage={stage} dueDate={dueDate} activities={activities} />
              )}
            </Panel>
            <div className="stack">
              <DueDatePanel dueDate={dueDate} onDueDate={onDueDate} />
              <SourcesReviewPanel model={shown} />
              <ForbiddenPanel hits={hits.filter((h) => h.stage === selected)} model={shown} />
            </div>
          </div>
        </div>
      ) : (
        <>
          <div className="cols cols--2-1">
            <Panel
              title={
                <span className="chips">
                  <FormattedMessage id="rhythm.model" values={{ label: shown.label || '—' }} />
                  {!shown.review && <TechnicalDraftBadge />}
                </span>
              }
            >
              {editing ? (
                <ModelEditor model={editing} edit={working.edit} />
              ) : (
                <ModelSummary model={shown} />
              )}
            </Panel>
            <div className="stack">
              <DueDatePanel dueDate={dueDate} onDueDate={onDueDate} />
              <ForbiddenPanel hits={hits} model={shown} />
            </div>
          </div>
          <StagesTable
            model={shown}
            editing={editing ? working.edit : null}
            dueDate={dueDate}
            hits={hits}
            check={working.showIssues ? check : null}
            onOpen={open}
            onAdd={() => {
              if (!editing) return;
              working.edit((m) => {
                m.stages.push(blankStage(m.stages));
              });
              open(editing.stages.length);
            }}
          />
        </>
      )}

      <HistoryPanel
        doc="reference"
        docView={doc}
        size={size}
        locales={() => 'VI · EN'}
        canApprove={canApprove}
        onRollback={(versionId) => onAct('rollback', versionId)}
      />
      <div className="cols cols--1-1">
        <HowItWorksPanel />
        <KillSwitchPanel flags={flags} />
      </div>
    </>
  );
}

function DueDatePanel({ dueDate, onDueDate }: { dueDate: string; onDueDate: (d: string) => void }) {
  return (
    <Panel title={<FormattedMessage id="rhythm.dueDate" />}>
      <label className="field">
        <span className="field__label">
          <FormattedMessage id="rhythm.dueDate.label" />
        </span>
        <input
          className="field__input"
          type="date"
          value={dueDate}
          onChange={(e) => onDueDate(e.target.value)}
        />
        <span className="field__help">
          <FormattedMessage id="rhythm.dueDate.help" />
        </span>
      </label>
    </Panel>
  );
}

function ModelSummary({ model }: { model: ReferenceDraftData }) {
  return (
    <dl className="kv">
      <dt>
        <FormattedMessage id="rhythm.field.label" />
      </dt>
      <dd>{model.label}</dd>
      <dt>
        <FormattedMessage id="rhythm.col.size" />
      </dt>
      <dd>
        <FormattedMessage id="rhythm.size.reference" values={{ n: model.stages.length }} />
      </dd>
      <dt>
        <FormattedMessage id="rhythm.col.review" />
      </dt>
      <dd>
        <ReviewText review={model.review} />
      </dd>
      <dt>
        <FormattedMessage id="rhythm.field.sources" />
      </dt>
      <dd>
        <Sources list={model.sources} />
      </dd>
    </dl>
  );
}

function Sources({ list }: { list: Array<{ label: string; url: string }> }) {
  if (!list.length) return <>—</>;
  return (
    <ol className="rh-sources">
      {list.map((s, i) => (
        <li key={i}>
          <a href={s.url} target="_blank" rel="noreferrer noopener">
            {s.label}
          </a>
        </li>
      ))}
    </ol>
  );
}

function SourcesReviewPanel({ model }: { model: ReferenceDraftData }) {
  return (
    <Panel title={<FormattedMessage id="rhythm.sourcesReview" />}>
      <dl className="kv">
        <dt>
          <FormattedMessage id="rhythm.field.sources" />
        </dt>
        <dd>
          <Sources list={model.sources} />
        </dd>
        <dt>
          <FormattedMessage id="rhythm.col.review" />
        </dt>
        <dd>{model.review ? <ReviewText review={model.review} /> : <TechnicalDraftBadge />}</dd>
      </dl>
    </Panel>
  );
}

/** PN02 "Không được viết", and the stage texts that slipped into it. */
export function ForbiddenPanel({
  hits,
  model,
}: {
  hits: ForbiddenHit[];
  model: ReferenceDraftData;
}) {
  const intl = useIntl();
  return (
    <Panel title={<FormattedMessage id="rhythm.forbidden" />}>
      <p className="muted">
        <FormattedMessage id="rhythm.forbidden.examples" />
      </p>
      {hits.length > 0 && (
        <div className="note note--warn" role="alert">
          <strong>
            <FormattedMessage id="rhythm.forbidden.found" values={{ n: hits.length }} />
          </strong>
          <ul className="rh-hits">
            {hits.map((h, k) => {
              const s = model.stages[h.stage];
              return (
                <li key={k}>
                  <FormattedMessage
                    id="rhythm.forbidden.hit"
                    values={{
                      stage: s ? stageName(intl, s, h.stage) : `#${h.stage + 1}`,
                      field: intl.formatMessage({ id: `rhythm.hitField.${h.field}` }),
                      lang: h.lang.toUpperCase(),
                      text: h.text,
                      phrase: h.phrase,
                    }}
                  />
                </li>
              );
            })}
          </ul>
        </div>
      )}
    </Panel>
  );
}

function StagesTable({
  model,
  editing,
  dueDate,
  hits,
  check,
  onOpen,
  onAdd,
}: {
  model: ReferenceDraftData;
  editing: Edit<ReferenceDraftData> | null;
  dueDate: string;
  hits: ForbiddenHit[];
  check: Check | null;
  onOpen: (i: number) => void;
  onAdd: () => void;
}) {
  const intl = useIntl();
  const problems = new Map<number, number>();
  for (const i of check?.list ?? []) {
    if (i.path[0] === 'stages' && typeof i.path[1] === 'number') {
      problems.set(i.path[1], (problems.get(i.path[1]) ?? 0) + 1);
    }
  }
  return (
    <Panel
      className="panel--flush"
      title={<FormattedMessage id="rhythm.stages" values={{ n: model.stages.length, max: 30 }} />}
      note={<FormattedMessage id="rhythm.stagesNote" values={{ due: dmy(dueDate) }} />}
      aside={
        editing ? (
          <Button disabled={model.stages.length >= 30} onClick={onAdd}>
            <FormattedMessage id="rhythm.addStage" />
          </Button>
        ) : undefined
      }
    >
      <TableScroll min={900}>
        <table className="table">
          <thead>
            <tr>
              <th>#</th>
              {(
                ['stage', 'offsets', 'window', 'signs', 'activities', 'notice', 'flags'] as const
              ).map((c) => (
                <th key={c}>
                  <FormattedMessage id={`rhythm.stageCol.${c}`} />
                </th>
              ))}
              <th />
            </tr>
          </thead>
          <tbody>
            {model.stages.map((s, i) => {
              const w = windowPreview(dueDate, s);
              const n = hits.filter((h) => h.stage === i).length;
              return (
                <tr key={`${i}-${s.id}`}>
                  <td className="muted">{s.number}</td>
                  <td>
                    <button type="button" className="linkbtn" onClick={() => onOpen(i)}>
                      {stageName(intl, s, i)}
                    </button>
                    <span className="muted fa-sub-line mono">{s.id}</span>
                  </td>
                  <td className="nowrap">
                    <FormattedMessage
                      id="rhythm.offsets"
                      values={{ start: s.startOffsetDays, end: s.endOffsetDays }}
                    />
                  </td>
                  <td className="nowrap">{w ? `${dmy(w.start)} – ${dmy(w.end)}` : '—'}</td>
                  <td className="nowrap">
                    <FormattedMessage
                      id="rhythm.counts.lang"
                      values={{ vi: s.signs.vi.length, en: s.signs.en.length }}
                    />
                  </td>
                  <td>{s.activityIds.length}</td>
                  <td>
                    {s.notice ? (
                      <FormattedMessage id="rhythm.yes" />
                    ) : (
                      <span className="muted">—</span>
                    )}
                  </td>
                  <td>
                    <span className="chips">
                      {n > 0 && (
                        <Pill tone="warn">
                          <FormattedMessage id="rhythm.badge.forbidden" values={{ n }} />
                        </Pill>
                      )}
                      {problems.has(i) && (
                        <Pill tone="error">
                          <FormattedMessage
                            id="firstAid.badge.issues"
                            values={{ n: problems.get(i) }}
                          />
                        </Pill>
                      )}
                    </span>
                  </td>
                  <td className="cell-actions">
                    {editing && (
                      <RowActions
                        label={intl.formatMessage(
                          { id: 'table.actionsFor' },
                          { name: stageName(intl, s, i) },
                        )}
                        actions={[
                          ...(i > 0
                            ? [
                                {
                                  key: 'up',
                                  label: <FormattedMessage id="firstAid.moveUp" />,
                                  onSelect: () => editing((m) => moveItem(m.stages, i, -1)),
                                },
                              ]
                            : []),
                          ...(i < model.stages.length - 1
                            ? [
                                {
                                  key: 'down',
                                  label: <FormattedMessage id="firstAid.moveDown" />,
                                  onSelect: () => editing((m) => moveItem(m.stages, i, 1)),
                                },
                              ]
                            : []),
                          ...(model.stages.length > 1
                            ? [
                                {
                                  key: 'remove',
                                  destructive: true,
                                  label: <FormattedMessage id="firstAid.remove" />,
                                  onSelect: () => {
                                    if (
                                      window.confirm(
                                        intl.formatMessage(
                                          { id: 'rhythm.removeConfirm' },
                                          { name: stageName(intl, s, i) },
                                        ),
                                      )
                                    ) {
                                      editing((m) => void m.stages.splice(i, 1));
                                    }
                                  },
                                },
                              ]
                            : []),
                        ]}
                      />
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </TableScroll>
    </Panel>
  );
}

function StageSummary({
  stage: s,
  dueDate,
  activities,
}: {
  stage: ReferenceStage;
  dueDate: string;
  activities: ActivityOption[];
}) {
  const w = windowPreview(dueDate, s);
  const names = new Map(activities.map((a) => [a.id, a.title]));
  const list = (items: string[]) =>
    items.length ? (
      <ul className="rh-list">
        {items.map((t, i) => (
          <li key={i}>{t}</li>
        ))}
      </ul>
    ) : (
      '—'
    );
  return (
    <dl className="kv">
      <dt>
        <FormattedMessage id="rhythm.field.stageId" />
      </dt>
      <dd className="mono">{s.id}</dd>
      <dt>
        <FormattedMessage id="rhythm.stageCol.offsets" />
      </dt>
      <dd>
        <FormattedMessage
          id="rhythm.offsets"
          values={{ start: s.startOffsetDays, end: s.endOffsetDays }}
        />
        {w && (
          <>
            <br />
            <span className="muted">
              <FormattedMessage
                id="rhythm.stage.preview"
                values={{ due: dmy(dueDate), start: dmy(w.start), end: dmy(w.end) }}
              />
            </span>
          </>
        )}
      </dd>
      {(['vi', 'en'] as const).map((lang) => (
        <Fragment key={lang}>
          <dt>
            <FormattedMessage id={`firstAid.lang.${lang}`} />
          </dt>
          <dd>
            <strong>{s.name[lang]}</strong>
            <p className="fa-sub">
              <FormattedMessage id="rhythm.field.signs" />
            </p>
            {list(s.signs[lang])}
            <p className="fa-sub">
              <FormattedMessage id="rhythm.field.skills" />
            </p>
            {list(s.skills[lang])}
            {s.notice && (
              <>
                <p className="fa-sub">
                  <FormattedMessage id="rhythm.stage.notice" />
                </p>
                <p className="quote">
                  <strong>{s.notice.title[lang]}</strong>
                  {'\n'}
                  {s.notice.body[lang]}
                </p>
              </>
            )}
          </dd>
        </Fragment>
      ))}
      <dt>
        <FormattedMessage id="rhythm.stageCol.activities" />
      </dt>
      <dd>{s.activityIds.map((id) => names.get(id) || id).join(' · ') || '—'}</dd>
    </dl>
  );
}

/** PN01 "Phiên bản đang phát hành": how the app counts, stated once. */
function HowItWorksPanel() {
  return (
    <Panel title={<FormattedMessage id="rhythm.how" />}>
      <dl className="kv">
        {(['calc', 'noDue', 'estimated', 'change', 'overlap'] as const).map((k) => (
          <Fragment key={k}>
            <dt>
              <FormattedMessage id={`rhythm.how.${k}`} />
            </dt>
            <dd>
              <FormattedMessage id={`rhythm.how.${k}.value`} />
            </dd>
          </Fragment>
        ))}
      </dl>
    </Panel>
  );
}

const killSwitches = ['rhythm', 'personalization', 'ai_assist'] as const;

/** PN01 "Công tắc khẩn cấp": the flags' state; they are switched (with a reason) in A10. */
export function KillSwitchPanel({ flags }: { flags: Flags | null | undefined }) {
  const staff = useStaff();
  if (!staffCan(staff.levels, 'features.view')) {
    return (
      <Panel title={<FormattedMessage id="rhythm.switches" />}>
        <LockNote>
          <FormattedMessage id="rhythm.switches.locked" />
        </LockNote>
      </Panel>
    );
  }
  return flags === undefined ? <KillSwitchLoader /> : <KillSwitchList flags={flags} />;
}

function KillSwitchLoader() {
  const [load] = useLoad<FlagsView>('staffFlags', {}, 'flags');
  return <KillSwitchList flags={load.status === 'ok' ? load.data.flags : null} />;
}

function KillSwitchList({ flags }: { flags: Flags | null }) {
  const navigate = useNavigate();
  return (
    <Panel
      title={<FormattedMessage id="rhythm.switches" />}
      aside={
        <Button kind="ghost" onClick={() => navigate('features')}>
          <FormattedMessage id="rhythm.switches.open" />
        </Button>
      }
    >
      <dl className="kv">
        {killSwitches.map((k) => {
          const f = flags?.[k];
          return (
            <Fragment key={k}>
              <dt>
                <FormattedMessage id={`flag.${k}`} />
              </dt>
              <dd>
                {!f ? (
                  <span className="muted">—</span>
                ) : (
                  <span className="chips">
                    <Pill tone={f.enabled ? 'ok' : 'muted'}>
                      <FormattedMessage id={f.enabled ? 'rhythm.switch.on' : 'rhythm.switch.off'} />
                    </Pill>
                    {f.enabled && (
                      <span className="muted">
                        <FormattedMessage
                          id={`scope.${f.scope}`}
                          values={{ p: f.scope === 'all' ? 100 : f.percent }}
                        />
                      </span>
                    )}
                  </span>
                )}
                <span className="muted fa-sub-line">
                  <FormattedMessage id={`flag.${k}.offEffect`} />
                </span>
              </dd>
            </Fragment>
          );
        })}
      </dl>
      <LockNote>
        <FormattedMessage id="rhythm.switches.note" />
      </LockNote>
    </Panel>
  );
}

// ---------- Tab 2: Hoạt động & thẻ theo tuổi (PN03) ----------

type Selected = { kind: 'activity' | 'ageCard'; index: number } | null;

function AgeText({ age }: { age: { from: number; to: number } }) {
  return (
    <FormattedMessage
      id="rhythm.ageDays"
      values={{ from: age.from, to: age.to, mFrom: monthsOf(age.from), mTo: monthsOf(age.to) }}
    />
  );
}

function ItemReview({ review }: { review: RhythmReview }) {
  return review ? (
    <span className="muted">
      <ReviewText review={review} />
    </span>
  ) : (
    <Pill tone="warn">
      <FormattedMessage id="rhythm.awaitingExpert" />
    </Pill>
  );
}

function ContentTab({
  view,
  shown,
  working,
  check,
  canEdit,
  canApprove,
  showDraft,
  onToggleDraft,
  onStart,
  onStop,
  onSave,
  onAct,
}: {
  view: RhythmView;
  shown: ContentDraftData | null;
  working: Working<ContentDraftData>;
  check: Check | null;
  canEdit: boolean;
  canApprove: boolean;
  showDraft: boolean;
  onToggleDraft: () => void;
  onStart: () => void;
  onStop: () => void;
  onSave: () => void;
  onAct: (act: Act, versionId: string) => void;
}) {
  const intl = useIntl();
  const doc = view.content;
  const editing = working.editing;
  const [sub, setSub] = useState<ContentTab>('activities');
  const [selected, setSelected] = useState<Selected>(null);
  const live = useMemo(
    () =>
      new Set([
        ...(doc.current?.activities.map((a) => a.id) ?? []),
        ...(doc.current?.ageCards.map((a) => a.id) ?? []),
      ]),
    [doc.current],
  );
  const size = (v: RhythmVersion) => (
    <FormattedMessage
      id="rhythm.size.content"
      values={{ a: v.activities ?? 0, c: v.ageCards ?? 0 }}
    />
  );
  const localesOf = (data: { activities: Activity[] } | null | undefined) => {
    const set = new Set((data?.activities ?? []).flatMap((a) => a.locales));
    return (
      (['vi', 'en'] as const)
        .filter((l) => set.has(l))
        .map((l) => l.toUpperCase())
        .join(' · ') || '—'
    );
  };
  const reviewed = (data: ContentDraftData) => {
    const items = [...data.activities, ...data.ageCards, data.health];
    return { done: items.filter((x) => x.review).length, total: items.length };
  };
  const open = (s: Selected) => {
    setSelected(s);
    window.scrollTo?.(0, 0);
  };
  const item =
    selected && shown
      ? selected.kind === 'activity'
        ? shown.activities[selected.index]
        : shown.ageCards[selected.index]
      : undefined;
  const r = doc.current ? reviewed(doc.current) : null;
  return (
    <>
      <StatusPanels
        doc="content"
        docView={doc}
        size={size}
        currentReview={
          r &&
          (r.done < r.total ? (
            <>
              <span className="muted">
                <FormattedMessage id="rhythm.reviewedCount" values={r} />
              </span>
              <TechnicalDraftBadge />
            </>
          ) : (
            <span className="muted">
              <FormattedMessage id="rhythm.reviewedCount" values={r} />
            </span>
          ))
        }
        canEdit={canEdit}
        canApprove={canApprove}
        editing={!!editing}
        showDraft={showDraft}
        onToggleDraft={onToggleDraft}
        onEdit={onStart}
        onAct={onAct}
      />
      {editing && (
        <EditBar
          dirty={working.dirty}
          pending={doc.draft?.status === 'pending'}
          check={check}
          show={working.showIssues}
          place={(i) => {
            const [head, at, ...rest] = i.path;
            if ((head === 'activities' || head === 'ageCards') && typeof at === 'number') {
              const x = head === 'activities' ? editing.activities[at] : editing.ageCards[at];
              const name = x ? textOf(intl, x.title) || x.id : `#${at + 1}`;
              return rest.length ? `${name} · ${rest.join('.')}` : name;
            }
            return i.path.join('.') || '—';
          }}
          onOpen={(i) => {
            const [head, at] = i.path;
            if (head === 'activities' && typeof at === 'number') {
              setSub('activities');
              open({ kind: 'activity', index: at });
            } else if (head === 'ageCards' && typeof at === 'number') {
              setSub('ageCards');
              open({ kind: 'ageCard', index: at });
            } else if (head === 'health') {
              setSub('health');
              open(null);
            }
          }}
          onSave={onSave}
          onCancel={() => {
            onStop();
            open(null);
          }}
        />
      )}

      {!shown ? (
        <Panel>
          <Empty>
            <FormattedMessage id={canEdit ? 'rhythm.emptyEdit' : 'rhythm.empty'} />
          </Empty>
        </Panel>
      ) : item && selected ? (
        <div className="stack">
          <div className="toolbar">
            <button type="button" className="linkbtn" onClick={() => open(null)}>
              ← <FormattedMessage id={`rhythm.back.${selected.kind}`} />
            </button>
            <span className="muted">{textOf(intl, item.title) || item.id}</span>
          </div>
          <Panel>
            {editing ? (
              selected.kind === 'activity' ? (
                <ActivityEditor
                  key={`activity-${selected.index}`}
                  data={editing}
                  index={selected.index}
                  edit={working.edit}
                  idLocked={live.has(item.id)}
                />
              ) : (
                <AgeCardEditor
                  key={`ageCard-${selected.index}`}
                  data={editing}
                  index={selected.index}
                  edit={working.edit}
                  idLocked={live.has(item.id)}
                />
              )
            ) : selected.kind === 'activity' ? (
              <ActivitySummary a={item as Activity} />
            ) : (
              <AgeCardSummary c={item as AgeCard} />
            )}
          </Panel>
        </div>
      ) : (
        <>
          <Segmented
            label={intl.formatMessage({ id: 'rhythm.tab.content' })}
            value={sub}
            onChange={setSub}
            options={(['activities', 'ageCards', 'health'] as const).map((t) => ({
              value: t,
              label: <FormattedMessage id={`rhythm.sub.${t}`} />,
            }))}
          />
          {sub === 'activities' && (
            <ActivitiesTable
              data={shown}
              editing={editing ? working.edit : null}
              check={working.showIssues ? check : null}
              onOpen={(index) => open({ kind: 'activity', index })}
              onAdd={() => {
                if (!editing) return;
                working.edit((d) => void d.activities.push(blankActivity(d.activities)));
                open({ kind: 'activity', index: editing.activities.length });
              }}
            />
          )}
          {sub === 'ageCards' && (
            <AgeCardsTable
              data={shown}
              editing={editing ? working.edit : null}
              check={working.showIssues ? check : null}
              onOpen={(index) => open({ kind: 'ageCard', index })}
              onAdd={() => {
                if (!editing) return;
                working.edit((d) => void d.ageCards.push(blankAgeCard(d.ageCards)));
                open({ kind: 'ageCard', index: editing.ageCards.length });
              }}
            />
          )}
          {sub === 'health' && (
            <Panel
              title={
                <span className="chips">
                  <FormattedMessage id="rhythm.health" />
                  <Pill tone="info">
                    <FormattedMessage id="rhythm.health.free" />
                  </Pill>
                </span>
              }
              note={<FormattedMessage id="rhythm.health.note" />}
            >
              {editing ? (
                <HealthEditor data={editing} edit={working.edit} />
              ) : (
                <HealthSummary health={shown.health} />
              )}
            </Panel>
          )}
        </>
      )}

      <HistoryPanel
        doc="content"
        docView={doc}
        size={size}
        locales={(v) =>
          v.versionId === doc.draft?.versionId
            ? localesOf(doc.draft.data)
            : v.label && v.label === doc.current?.version
              ? localesOf(doc.current)
              : '—'
        }
        canApprove={canApprove}
        onRollback={(versionId) => onAct('rollback', versionId)}
      />
    </>
  );
}

function rowProblems(check: Check | null, head: string) {
  const m = new Map<number, number>();
  for (const i of check?.list ?? []) {
    if (i.path[0] === head && typeof i.path[1] === 'number') {
      m.set(i.path[1], (m.get(i.path[1]) ?? 0) + 1);
    }
  }
  return m;
}

function RemoveAction<T>({
  name,
  index,
  editing,
  list,
}: {
  name: string;
  index: number;
  editing: Edit<ContentDraftData>;
  list: (d: ContentDraftData) => T[];
}) {
  const intl = useIntl();
  return (
    <RowActions
      label={intl.formatMessage({ id: 'table.actionsFor' }, { name })}
      actions={[
        {
          key: 'remove',
          destructive: true,
          label: <FormattedMessage id="firstAid.remove" />,
          onSelect: () => {
            if (window.confirm(intl.formatMessage({ id: 'rhythm.removeConfirm' }, { name }))) {
              editing((d) => void list(d).splice(index, 1));
            }
          },
        },
      ]}
    />
  );
}

export function ActivitiesTable({
  data,
  editing,
  check,
  onOpen,
  onAdd,
}: {
  data: ContentDraftData;
  editing: Edit<ContentDraftData> | null;
  check: Check | null;
  onOpen: (i: number) => void;
  onAdd: () => void;
}) {
  const intl = useIntl();
  const problems = rowProblems(check, 'activities');
  return (
    <Panel
      className="panel--flush"
      title={<FormattedMessage id="rhythm.activities" values={{ n: data.activities.length }} />}
      note={<FormattedMessage id="rhythm.activitiesNote" />}
      aside={
        editing ? (
          <Button disabled={data.activities.length >= 300} onClick={onAdd}>
            <FormattedMessage id="rhythm.addActivity" />
          </Button>
        ) : undefined
      }
    >
      <TableScroll min={900}>
        <table className="table">
          <thead>
            <tr>
              {(['activity', 'age', 'needs', 'status', 'review', 'locales'] as const).map((c) => (
                <th key={c}>
                  <FormattedMessage id={`rhythm.itemCol.${c}`} />
                </th>
              ))}
              <th />
            </tr>
          </thead>
          <tbody>
            {data.activities.map((a, i) => (
              <tr key={`${i}-${a.id}`}>
                <td>
                  <button type="button" className="linkbtn" onClick={() => onOpen(i)}>
                    {textOf(intl, a.title) || a.id}
                  </button>
                  <span className="muted fa-sub-line">
                    <FormattedMessage id="rhythm.minutes" values={{ n: a.durationMin }} /> ·{' '}
                    <span className="mono">{a.id}</span> · v{a.version}
                  </span>
                </td>
                <td className="nowrap">
                  <AgeText age={a.ageDays} />
                </td>
                <td>
                  {a.needs.map((n) => intl.formatMessage({ id: `rhythm.need.${n}` })).join(' · ')}
                </td>
                <td>
                  <span className="chips">
                    <Pill tone={itemTone[a.status] ?? 'muted'}>
                      <FormattedMessage id={`rhythm.itemStatus.${a.status}`} />
                    </Pill>
                    {problems.has(i) && (
                      <Pill tone="error">
                        <FormattedMessage
                          id="firstAid.badge.issues"
                          values={{ n: problems.get(i) }}
                        />
                      </Pill>
                    )}
                  </span>
                </td>
                <td>
                  <ItemReview review={a.review} />
                </td>
                <td className="nowrap">{a.locales.map((l) => l.toUpperCase()).join(' · ')}</td>
                <td className="cell-actions">
                  {editing && (
                    <RemoveAction
                      name={textOf(intl, a.title) || a.id}
                      index={i}
                      editing={editing}
                      list={(d) => d.activities}
                    />
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </TableScroll>
    </Panel>
  );
}

export function AgeCardsTable({
  data,
  editing,
  check,
  onOpen,
  onAdd,
}: {
  data: ContentDraftData;
  editing: Edit<ContentDraftData> | null;
  check: Check | null;
  onOpen: (i: number) => void;
  onAdd: () => void;
}) {
  const intl = useIntl();
  const problems = rowProblems(check, 'ageCards');
  return (
    <Panel
      className="panel--flush"
      title={<FormattedMessage id="rhythm.ageCards" values={{ n: data.ageCards.length }} />}
      note={<FormattedMessage id="rhythm.ageCardsNote" />}
      aside={
        editing ? (
          <Button disabled={data.ageCards.length >= 200} onClick={onAdd}>
            <FormattedMessage id="rhythm.addAgeCard" />
          </Button>
        ) : undefined
      }
    >
      <TableScroll min={760}>
        <table className="table">
          <thead>
            <tr>
              {(['age', 'title', 'status', 'review'] as const).map((c) => (
                <th key={c}>
                  <FormattedMessage id={`rhythm.itemCol.${c}`} />
                </th>
              ))}
              <th />
            </tr>
          </thead>
          <tbody>
            {data.ageCards.map((c, i) => (
              <tr key={`${i}-${c.id}`}>
                <td className="nowrap">
                  <AgeText age={c.ageDays} />
                </td>
                <td>
                  <button type="button" className="linkbtn" onClick={() => onOpen(i)}>
                    {textOf(intl, c.title) || c.id}
                  </button>
                  <span className="muted fa-sub-line mono">{c.id}</span>
                </td>
                <td>
                  <span className="chips">
                    <Pill tone={itemTone[c.status] ?? 'muted'}>
                      <FormattedMessage id={`rhythm.itemStatus.${c.status}`} />
                    </Pill>
                    {problems.has(i) && (
                      <Pill tone="error">
                        <FormattedMessage
                          id="firstAid.badge.issues"
                          values={{ n: problems.get(i) }}
                        />
                      </Pill>
                    )}
                  </span>
                </td>
                <td>
                  <ItemReview review={c.review} />
                </td>
                <td className="cell-actions">
                  {editing && (
                    <RemoveAction
                      name={textOf(intl, c.title) || c.id}
                      index={i}
                      editing={editing}
                      list={(d) => d.ageCards}
                    />
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </TableScroll>
    </Panel>
  );
}

function LocBlock({
  label,
  value,
}: {
  label: ReactNode;
  value: { vi: string; en: string } | null;
}) {
  return (
    <>
      <dt>{label}</dt>
      <dd>
        {value ? (
          <>
            {value.vi}
            <br />
            <span className="muted">{value.en}</span>
          </>
        ) : (
          '—'
        )}
      </dd>
    </>
  );
}

function ListBlock({ label, value }: { label: ReactNode; value: { vi: string[]; en: string[] } }) {
  return (
    <>
      <dt>{label}</dt>
      <dd>
        {value.vi.length || value.en.length ? (
          <div className="cols cols--1-1">
            {(['vi', 'en'] as const).map((l) => (
              <ol key={l} className={`rh-list ${l === 'en' ? 'muted' : ''}`}>
                {value[l].map((t, i) => (
                  <li key={i}>{t}</li>
                ))}
              </ol>
            ))}
          </div>
        ) : (
          '—'
        )}
      </dd>
    </>
  );
}

function ActivitySummary({ a }: { a: Activity }) {
  const intl = useIntl();
  return (
    <dl className="kv">
      <dt>
        <FormattedMessage id="rhythm.field.itemId" />
      </dt>
      <dd className="mono">
        {a.id} · v{a.version}
      </dd>
      <dt>
        <FormattedMessage id="rhythm.itemCol.status" />
      </dt>
      <dd>
        <FormattedMessage id={`rhythm.itemStatus.${a.status}`} />
      </dd>
      <LocBlock label={<FormattedMessage id="rhythm.field.title" />} value={a.title} />
      <LocBlock label={<FormattedMessage id="rhythm.field.summary" />} value={a.summary} />
      <ListBlock label={<FormattedMessage id="rhythm.field.steps" />} value={a.steps} />
      <LocBlock label={<FormattedMessage id="rhythm.field.safety" />} value={a.safety} />
      <dt>
        <FormattedMessage id="rhythm.itemCol.age" />
      </dt>
      <dd>
        <AgeText age={a.ageDays} /> ·{' '}
        <FormattedMessage id="rhythm.minutes" values={{ n: a.durationMin }} /> ·{' '}
        <FormattedMessage id={`rhythm.timeOfDay.${a.timeOfDay}`} />
      </dd>
      <dt>
        <FormattedMessage id="rhythm.field.needs" />
      </dt>
      <dd>{a.needs.map((n) => intl.formatMessage({ id: `rhythm.need.${n}` })).join(' · ')}</dd>
      <dt>
        <FormattedMessage id="rhythm.field.interests" />
      </dt>
      <dd>
        {a.interests.map((n) => intl.formatMessage({ id: `rhythm.interest.${n}` })).join(' · ') ||
          '—'}
      </dd>
      <dt>
        <FormattedMessage id="rhythm.field.locales" />
      </dt>
      <dd>{a.locales.map((l) => l.toUpperCase()).join(' · ')}</dd>
      <dt>
        <FormattedMessage id="rhythm.field.regions" />
      </dt>
      <dd>{a.regions.join(', ') || <FormattedMessage id="rhythm.allRegions" />}</dd>
      <dt>
        <FormattedMessage id="rhythm.itemCol.review" />
      </dt>
      <dd>
        <ItemReview review={a.review} />
      </dd>
      <dt>
        <FormattedMessage id="rhythm.field.sources" />
      </dt>
      <dd>
        <Sources list={a.sources} />
      </dd>
    </dl>
  );
}

function AgeCardSummary({ c }: { c: AgeCard }) {
  return (
    <dl className="kv">
      <dt>
        <FormattedMessage id="rhythm.field.itemId" />
      </dt>
      <dd className="mono">
        {c.id} · v{c.version}
      </dd>
      <dt>
        <FormattedMessage id="rhythm.itemCol.age" />
      </dt>
      <dd>
        <AgeText age={c.ageDays} />
      </dd>
      <LocBlock label={<FormattedMessage id="rhythm.field.title" />} value={c.title} />
      <LocBlock label={<FormattedMessage id="rhythm.field.body" />} value={c.body} />
      <ListBlock label={<FormattedMessage id="rhythm.field.tips" />} value={c.tips} />
      <ListBlock label={<FormattedMessage id="rhythm.field.watchFor" />} value={c.watchFor} />
      <dt>
        <FormattedMessage id="rhythm.itemCol.review" />
      </dt>
      <dd>
        <ItemReview review={c.review} />
      </dd>
      <dt>
        <FormattedMessage id="rhythm.field.sources" />
      </dt>
      <dd>
        <Sources list={c.sources} />
      </dd>
    </dl>
  );
}

function HealthSummary({ health: h }: { health: ContentDraftData['health'] }) {
  const intl = useIntl();
  return (
    <dl className="kv">
      <dt>
        <FormattedMessage id="rhythm.health.signs" values={{ n: h.signs.length, max: 20 }} />
      </dt>
      <dd>
        <ul className="rh-list">
          {h.signs.map((s) => (
            <li key={s.id}>
              {textOf(intl, s.label)}{' '}
              {s.maxAgeDays !== null && (
                <span className="muted">
                  <FormattedMessage id="rhythm.health.under" values={{ n: s.maxAgeDays }} />
                </span>
              )}
            </li>
          ))}
        </ul>
      </dd>
      <ListBlock
        label={<FormattedMessage id="rhythm.field.whileWaiting" />}
        value={h.whileWaiting}
      />
      <LocBlock label={<FormattedMessage id="rhythm.field.disclaimer" />} value={h.disclaimer} />
      <dt>
        <FormattedMessage id="rhythm.health.regions" values={{ n: h.regions.length }} />
      </dt>
      <dd>
        {h.regions.map((r) => `${r.country} (${r.emergencyNumber})`).join(' · ') || '—'}
        <span className="muted fa-sub-line">
          <FormattedMessage id="rhythm.health.otherRegions" />
        </span>
      </dd>
      <dt>
        <FormattedMessage id="rhythm.itemCol.review" />
      </dt>
      <dd>
        <ItemReview review={h.review} />
      </dd>
      <dt>
        <FormattedMessage id="rhythm.field.sources" />
      </dt>
      <dd>
        <Sources list={h.sources} />
      </dd>
    </dl>
  );
}

// ---------- Tab 3: Quy tắc (PN04) ----------

type RuleKey = Exclude<keyof RhythmRules, 'version'>;
/** In the order PN04 reads them: valid days, the two windows, the change test, repeats. */
export const ruleGroups: Array<{ id: string; keys: RuleKey[] }> = [
  { id: 'validDay', keys: ['maxGapMinutes', 'pointCoverMinutes'] },
  { id: 'baseline', keys: ['baselineMaxDays', 'baselineMinDays', 'baselineLookbackDays'] },
  { id: 'recent', keys: ['recentDays', 'recentMinDays'] },
  { id: 'change', keys: ['minDeltaMinutes', 'minDeltaShare', 'minSameDirectionDays'] },
  { id: 'repeat', keys: ['cooldownDays'] },
];

function RulesTab({
  canView,
  canEdit,
  rules,
  content,
}: {
  canView: boolean;
  canEdit: boolean;
  rules: RhythmRulesView | null | undefined;
  content: RhythmContent | null;
}) {
  return (
    <>
      {!canView ? (
        <Panel title={<FormattedMessage id="rhythm.rules" />}>
          <LockNote>
            <FormattedMessage id="rhythm.rules.noAccess" />
          </LockNote>
        </Panel>
      ) : rules === undefined ? (
        <RulesLoader canEdit={canEdit} />
      ) : rules ? (
        <RulesPanel view={rules} canEdit={canEdit} onSaved={() => undefined} />
      ) : null}
      <div className="cols cols--1-1">
        <RankingPanel />
        <HealthRoutingPanel content={content} />
      </div>
    </>
  );
}

function RulesLoader({ canEdit }: { canEdit: boolean }) {
  const [load, reload] = useLoad<RhythmRulesView>('staffRhythmRules', {}, 'rhythmRules');
  return (
    <Loaded load={load} reload={reload}>
      {(view) => <RulesPanel view={view} canEdit={canEdit} onSaved={reload} />}
    </Loaded>
  );
}

const ruleUnit: Record<RuleKey, 'minutes' | 'days' | 'share'> = {
  maxGapMinutes: 'minutes',
  pointCoverMinutes: 'minutes',
  baselineMinDays: 'days',
  baselineMaxDays: 'days',
  baselineLookbackDays: 'days',
  recentDays: 'days',
  recentMinDays: 'days',
  minDeltaMinutes: 'minutes',
  minDeltaShare: 'share',
  minSameDirectionDays: 'days',
  cooldownDays: 'days',
};

function ruleValue(intl: IntlShape, key: RuleKey, v: number) {
  const unit = ruleUnit[key];
  return unit === 'share'
    ? intl.formatNumber(v, { style: 'percent', maximumFractionDigits: 1 })
    : intl.formatMessage({ id: `rhythm.unit.${unit}` }, { n: v });
}

/** PN04 in words, from the values (what the app does with them). */
export function RulesSummary({ rules: r }: { rules: RhythmRules }) {
  const intl = useIntl();
  return (
    <dl className="kv">
      {(['baseline', 'validDay', 'change', 'repeat'] as const).map((k) => (
        <Fragment key={k}>
          <dt>
            <FormattedMessage id={`rhythm.rules.summary.${k}`} />
          </dt>
          <dd>
            <FormattedMessage
              id={`rhythm.rules.summary.${k}.value`}
              values={{
                ...r,
                share: intl.formatNumber(r.minDeltaShare, {
                  style: 'percent',
                  maximumFractionDigits: 1,
                }),
              }}
            />
          </dd>
        </Fragment>
      ))}
    </dl>
  );
}

export function RulesPanel({
  view,
  canEdit,
  onSaved,
}: {
  view: RhythmRulesView;
  canEdit: boolean;
  onSaved: () => void;
}) {
  const intl = useIntl();
  const [rules, setRules] = useState<RhythmRules>(view.rules);
  useEffect(() => setRules(view.rules), [view.rules]);
  const [saving, setSaving] = useState(false);
  const issues = useMemo(() => rulesIssues(rules), [rules]);
  const dirty = JSON.stringify(rules) !== JSON.stringify(view.rules);
  const err = (key: string) => {
    const hit = issues.get(key);
    return hit ? ruleIssueText(intl, hit) : undefined;
  };
  const crossIssues = [...issues.values()].filter((i) => i.path.length <= 1);
  const defaults = JSON.stringify(rules) === JSON.stringify(defaultRhythmRules);
  return (
    <Panel
      title={
        <span className="chips">
          <FormattedMessage id="rhythm.rules" />
          <Pill tone="muted">{view.rules.version}</Pill>
        </span>
      }
      note={
        view.stored ? (
          <FormattedMessage
            id="rhythm.rules.updated"
            values={{
              name: view.updatedByName ?? '—',
              when: dateTime(intl, view.updatedAt),
            }}
          />
        ) : (
          <FormattedMessage id="rhythm.rules.default" />
        )
      }
      aside={
        canEdit ? (
          <div className="actions">
            {!defaults && (
              <Button
                kind="ghost"
                onClick={() => setRules({ ...defaultRhythmRules, version: rules.version })}
              >
                <FormattedMessage id="rhythm.rules.useDefaults" />
              </Button>
            )}
            <Button
              kind="primary"
              disabled={!dirty || issues.size > 0}
              onClick={() => setSaving(true)}
            >
              <FormattedMessage id="rhythm.rules.save" />
            </Button>
          </div>
        ) : undefined
      }
    >
      <div className="stack">
        <p className="note">
          <FormattedMessage id="rhythm.rules.lead" />
        </p>
        {!canEdit && (
          <LockNote>
            <FormattedMessage id="rhythm.rules.readOnly" />
          </LockNote>
        )}
        <RulesSummary rules={rules} />
        {canEdit && (
          <TextInput
            label={<FormattedMessage id="rhythm.rules.version" />}
            value={rules.version}
            mono
            max={40}
            path={['version']}
            help={<FormattedMessage id="rhythm.rules.versionHelp" />}
            onChange={(v) => setRules({ ...rules, version: v })}
          />
        )}
        {canEdit && err('version') && <p className="error">{err('version')}</p>}
        {ruleGroups.map((g) => (
          <section key={g.id} className="fa-section">
            <h3 className="fa-section__title">
              <FormattedMessage id={`rhythm.rules.group.${g.id}`} />
            </h3>
            <div className="rh-rules">
              {g.keys.map((k) =>
                canEdit ? (
                  <div key={k}>
                    <NumberInput
                      label={<FormattedMessage id={`rhythm.rule.${k}`} />}
                      value={rules[k]}
                      step={k === 'minDeltaShare' ? '0.01' : '1'}
                      path={[k]}
                      help={<FormattedMessage id={`rhythm.rule.${k}.help`} />}
                      onChange={(v) => setRules({ ...rules, [k]: v ?? Number.NaN })}
                    />
                    {err(k) && <p className="error fa-err">{err(k)}</p>}
                  </div>
                ) : (
                  <div key={k} className="field">
                    <span className="field__label">
                      <FormattedMessage id={`rhythm.rule.${k}`} />
                    </span>
                    <strong>{ruleValue(intl, k, rules[k])}</strong>
                    <span className="field__help">
                      <FormattedMessage id={`rhythm.rule.${k}.help`} />
                    </span>
                  </div>
                ),
              )}
            </div>
          </section>
        ))}
        {crossIssues.length > 0 && (
          <div role="alert">
            {crossIssues.map((i, k) => (
              <p key={k} className="error">
                {ruleIssueText(intl, i)}
              </p>
            ))}
          </div>
        )}
      </div>
      {saving && (
        <RulesDialog
          before={view.rules}
          rules={rules}
          onClose={() => setSaving(false)}
          onDone={onSaved}
        />
      )}
    </Panel>
  );
}

function RulesDialog({
  before,
  rules,
  onClose,
  onDone,
}: {
  before: RhythmRules;
  rules: RhythmRules;
  onClose: () => void;
  onDone: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const changed = (Object.keys(rules) as Array<keyof RhythmRules>).filter(
    (k) => rules[k] !== before[k],
  );
  return (
    <Modal title={<FormattedMessage id="rhythm.rules.saveTitle" />} onClose={onClose}>
      <p className="modal__sub">
        <FormattedMessage id="rhythm.rules.saveNote" />
      </p>
      <dl className="kv">
        {changed.map((k) => (
          <Fragment key={k}>
            <dt>
              <FormattedMessage
                id={k === 'version' ? 'rhythm.rules.version' : `rhythm.rule.${k}`}
              />
            </dt>
            <dd>
              {k === 'version'
                ? `${before.version} → ${rules.version}`
                : `${ruleValue(intl, k, before[k])} → ${ruleValue(intl, k, rules[k])}`}
            </dd>
          </Fragment>
        ))}
      </dl>
      <ReasonField value={reason} onChange={setReason} required />
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
          kind="primary"
          disabled={busy || !reasonOk(reason)}
          onClick={() => {
            setBusy(true);
            setError(null);
            saveRhythmRules(api, rules, reason)
              .then((res) => {
                if (!res.ok) throw new ApiError('invalid-argument', 'malformed');
                onClose();
                onDone();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id="rhythm.rules.save" />
        </Button>
      </div>
    </Modal>
  );
}

/** PN04 "Xếp hạng gợi ý": the weights are versioned in code (`rankingWeights`). */
function RankingPanel() {
  const w = rankingWeights;
  return (
    <Panel
      title={
        <span className="chips">
          <FormattedMessage id="rhythm.ranking" />
          <Pill tone="muted">{w.version}</Pill>
        </span>
      }
    >
      <dl className="kv">
        <dt>
          <FormattedMessage id="rhythm.ranking.filter" />
        </dt>
        <dd>
          <FormattedMessage id="rhythm.ranking.filter.value" />
        </dd>
        <dt>
          <FormattedMessage id="rhythm.ranking.score" />
        </dt>
        <dd>
          <FormattedMessage
            id="rhythm.ranking.score.value"
            values={{
              need: w.need,
              interest: w.interest,
              helpful: w.helpful,
              recent: -w.recent,
              notSuitable: -w.notSuitable,
            }}
          />
        </dd>
        <dt>
          <FormattedMessage id="rhythm.ranking.tie" />
        </dt>
        <dd>
          <FormattedMessage id="rhythm.ranking.tie.value" />
        </dd>
      </dl>
      <LockNote>
        <FormattedMessage id="rhythm.ranking.code" />
      </LockNote>
    </Panel>
  );
}

/** PN04 "Định tuyến sức khoẻ": always first, always free; edited in the content pack. */
function HealthRoutingPanel({ content }: { content: RhythmContent | null }) {
  const intl = useIntl();
  const h = content?.health;
  return (
    <Panel
      title={
        <span className="chips">
          <FormattedMessage id="rhythm.health.routing" />
          <Pill tone="info">
            <FormattedMessage id="rhythm.health.first" />
          </Pill>
        </span>
      }
    >
      <dl className="kv">
        <dt>
          <FormattedMessage id="rhythm.health.signsShort" />
        </dt>
        <dd>{h ? h.signs.map((s) => textOf(intl, s.label)).join(' · ') : '—'}</dd>
        <dt>
          <FormattedMessage id="rhythm.health.action" />
        </dt>
        <dd>
          <FormattedMessage id="rhythm.health.action.value" />
        </dd>
        <dt>
          <FormattedMessage id="rhythm.health.countries" />
        </dt>
        <dd>
          {h?.regions.map((r) => `${r.country} (${r.emergencyNumber})`).join(' · ') || '—'}
          <span className="muted fa-sub-line">
            <FormattedMessage id="rhythm.health.otherRegions" />
          </span>
        </dd>
        <dt>
          <FormattedMessage id="rhythm.health.noAi" />
        </dt>
        <dd>
          <FormattedMessage id="rhythm.health.noAi.value" />
        </dd>
      </dl>
    </Panel>
  );
}
