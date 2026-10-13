import {
  firstAidImages,
  firstAidReviewSchema,
  staffCan,
  type FirstAidPack,
  type FirstAidSituation,
} from '@child-life/contracts';
import { Fragment, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { FormattedMessage, createIntl, useIntl, type IntlShape } from 'react-intl';
import {
  ApiError,
  useApi,
  useLoad,
  type FirstAidImage,
  type FirstAidVersion,
  type FirstAidView,
} from '../api';
import { routePaths, subPath, useStaff } from '../context';
import { ZONE } from '../format';
import { messages } from '../messages';
import {
  Button,
  Empty,
  Loaded,
  Modal,
  Page,
  Panel,
  Pill,
  ReasonField,
  Segmented,
  TableScroll,
  errorMessageId,
  reasonOk,
  type PillTone,
  RowActions,
} from '../ui';
import {
  GeneralEditor,
  ImageGrid,
  ImageThumb,
  IssuesContext,
  LibraryContext,
  SituationEditor,
  UploadBox,
  blankSituation,
  filterImages,
  issueText,
  moveItem,
  saveFirstAidDraft,
  starterPack,
  validatePack,
  type Edit,
  type Issue,
} from './FirstAidEditor';

/**
 * Sơ cứu (D-058, P-141; app v1.1 7a–7i, TH01–TH24). The guide the app shows, edited here as one
 * pack: "Sửa" opens a working copy, "Lưu nháp" saves it as the one open version, "Gửi duyệt" hands
 * it to a different person with "Nội dung · Duyệt" (on prod an expert, who records the review),
 * and approval publishes it to `publicConfig/content_firstAid`. Every step asks for a reason and
 * is in the audit log. "/first-aid/<situationId>" opens one situation with a phone preview.
 */

const statusTone: Record<string, PillTone> = {
  draft: 'muted',
  pending: 'wait',
  published: 'ok',
  retired: 'muted',
  discarded: 'muted',
};

export type Act = 'submit' | 'approve' | 'reject' | 'discard' | 'rollback';
type Tab = 'situations' | 'general' | 'library';

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

export function FirstAidScreen() {
  const staff = useStaff();
  const [load, reload] = useLoad<FirstAidView>('staffFirstAid', {}, 'firstAid');
  return (
    <Page
      title={<FormattedMessage id="firstAid.title" />}
      subtitle={<FormattedMessage id="firstAid.sub" />}
    >
      <Loaded load={load} reload={reload}>
        {(view) => (
          <FirstAidBody
            view={view}
            canEdit={staffCan(staff.levels, 'content.edit')}
            canApprove={staffCan(staff.levels, 'content.approve')}
            onChanged={reload}
          />
        )}
      </Loaded>
    </Page>
  );
}

/** The situation in the address ("/first-aid/choking"), or null for the list. */
function situationFromUrl(): string | null {
  return subPath('firstAid', window.location.pathname)[0] ?? null;
}

export function FirstAidBody({
  view,
  canEdit,
  canApprove,
  onChanged,
  initialSituation,
}: {
  view: FirstAidView;
  canEdit: boolean;
  canApprove: boolean;
  onChanged: () => void;
  /** Tests (no window): the situation to open. */
  initialSituation?: string | null;
}) {
  const intl = useIntl();
  const d = view.draft;
  const [showDraft, setShowDraft] = useState(!!d);
  const draftId = d?.versionId ?? null;
  useEffect(() => setShowDraft(draftId !== null), [draftId]);
  const [editing, setEditing] = useState<FirstAidPack | null>(null);
  const [dirty, setDirty] = useState(false);
  const [showIssues, setShowIssues] = useState(false);
  const [tab, setTab] = useState<Tab>('situations');
  const [dialog, setDialog] = useState<{ act: Act; versionId: string } | 'save' | null>(null);
  const [images, setImages] = useState<FirstAidImage[]>(view.images);
  useEffect(() => setImages(view.images), [view.images]);
  const onUploaded = useCallback(
    (img: FirstAidImage) =>
      setImages((list) => (list.some((i) => i.id === img.id) ? list : [img, ...list])),
    [],
  );

  const shown: FirstAidPack | null =
    editing ?? (showDraft && d ? d.pack : (view.current?.pack ?? null));
  const check = useMemo(() => (editing ? validatePack(editing) : null), [editing]);

  // Selected situation by position (ids can be edited); the address carries its id.
  const [selected, setSelected] = useState<number | null>(() => {
    const id =
      initialSituation !== undefined
        ? initialSituation
        : typeof window === 'undefined'
          ? null
          : situationFromUrl();
    const at = shown?.situations.findIndex((s) => s.id === id) ?? -1;
    return at >= 0 ? at : null;
  });
  const [variant, setVariant] = useState(0);
  const selectedSituation = selected !== null ? (shown?.situations[selected] ?? null) : null;
  const url = selectedSituation
    ? `${routePaths.firstAid}/${encodeURIComponent(selectedSituation.id)}`
    : routePaths.firstAid;
  useEffect(() => {
    if (typeof window !== 'undefined' && window.location.pathname !== url) {
      window.history.replaceState({}, '', url);
    }
  }, [url]);
  useEffect(() => {
    const onPop = () => {
      const id = situationFromUrl();
      const at = shown?.situations.findIndex((s) => s.id === id) ?? -1;
      setSelected(at >= 0 ? at : null);
    };
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, [shown]);
  const open = (i: number | null) => {
    const s = i === null ? null : shown?.situations[i];
    const next = s ? `${routePaths.firstAid}/${encodeURIComponent(s.id)}` : routePaths.firstAid;
    if (window.location.pathname !== next) window.history.pushState({}, '', next);
    setSelected(s ? i : null);
    setVariant(0);
    window.scrollTo?.(0, 0);
  };

  // Leaving with unsaved changes asks first.
  useEffect(() => {
    if (!editing || !dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [editing, dirty]);

  const edit: Edit = useCallback((fn) => {
    setEditing((p) => {
      if (!p) return p;
      const next = structuredClone(p);
      fn(next);
      return next;
    });
    setDirty(true);
  }, []);

  const startEditing = () => {
    setEditing(structuredClone(d?.pack ?? view.current?.pack ?? starterPack()));
    setShowDraft(!!d);
    setDirty(false);
    setShowIssues(false);
  };
  const stopEditing = () => {
    if (dirty && !window.confirm(intl.formatMessage({ id: 'firstAid.leaveConfirm' }))) return;
    setEditing(null);
    setDirty(false);
    setShowIssues(false);
    const saved = d?.pack ?? view.current?.pack;
    if (selected !== null && (!saved || selected >= saved.situations.length)) open(null);
  };

  const liveIds = useMemo(
    () => new Set(view.current?.pack.situations.map((s) => s.id) ?? []),
    [view.current],
  );

  return (
    <LibraryContext.Provider value={{ images, canUpload: canEdit, onUploaded }}>
      <IssuesContext.Provider value={{ issues: check?.issues ?? new Map(), show: showIssues }}>
        <div className="stack">
          <StatusPanels
            view={view}
            canEdit={canEdit}
            canApprove={canApprove}
            editing={!!editing}
            showDraft={showDraft}
            onToggleDraft={() => {
              // Keep the same situation open (by id) when switching between the two versions.
              const next = !showDraft && d ? d.pack : (view.current?.pack ?? null);
              const at = next?.situations.findIndex((s) => s.id === selectedSituation?.id) ?? -1;
              setSelected(at >= 0 ? at : null);
              setShowDraft(!showDraft);
            }}
            onEdit={startEditing}
            onAct={(act, versionId) => setDialog({ act, versionId })}
          />

          {editing && (
            <EditBar
              dirty={dirty}
              pending={d?.status === 'pending'}
              issues={showIssues ? (check?.list ?? []) : []}
              pack={editing}
              onOpen={(i) => {
                setTab('situations');
                open(i);
              }}
              onSave={() => {
                setShowIssues(true);
                if (check?.ok) setDialog('save');
              }}
              onCancel={stopEditing}
            />
          )}

          {!shown ? (
            <Panel>
              <Empty>
                <FormattedMessage id={canEdit ? 'firstAid.emptyEdit' : 'firstAid.empty'} />
              </Empty>
            </Panel>
          ) : selectedSituation && selected !== null ? (
            <SituationPage
              pack={shown}
              index={selected}
              editing={!!editing}
              edit={edit}
              idLocked={liveIds.has(selectedSituation.id) || !editing}
              variant={variant}
              onVariant={setVariant}
              onBack={() => open(null)}
            />
          ) : (
            <>
              <Segmented
                label={intl.formatMessage({ id: 'firstAid.title' })}
                value={tab}
                onChange={setTab}
                options={(['situations', 'general', 'library'] as const).map((t) => ({
                  value: t,
                  label: <FormattedMessage id={`firstAid.tab.${t}`} />,
                }))}
              />
              {tab === 'situations' && (
                <SituationList
                  pack={shown}
                  editing={!!editing}
                  edit={edit}
                  issues={showIssues ? (check?.list ?? []) : []}
                  onOpen={open}
                  onAdd={() => {
                    if (!editing) return;
                    const added = blankSituation(editing);
                    edit((p) => {
                      p.situations.push(structuredClone(added));
                    });
                    window.history.pushState({}, '', `${routePaths.firstAid}/${added.id}`);
                    setSelected(editing.situations.length);
                    setVariant(0);
                  }}
                />
              )}
              {tab === 'general' &&
                (editing ? (
                  <Panel>
                    <GeneralEditor pack={editing} edit={edit} />
                  </Panel>
                ) : (
                  <GeneralSummary pack={shown} />
                ))}
              {tab === 'library' && <Library pack={shown} canUpload={canEdit} />}
            </>
          )}

          <HistoryPanel
            view={view}
            canApprove={canApprove}
            onRollback={(versionId) => setDialog({ act: 'rollback', versionId })}
          />
        </div>

        {dialog === 'save' && editing && (
          <SaveDialog
            pack={editing}
            notes={d?.notes ?? ''}
            pending={d?.status === 'pending'}
            onClose={() => setDialog(null)}
            onDone={() => {
              setEditing(null);
              setDirty(false);
              setShowIssues(false);
              onChanged();
            }}
          />
        )}
        {dialog && typeof dialog === 'object' && (
          <ActDialog
            act={dialog.act}
            versionId={dialog.versionId}
            requireReview={view.requireReview}
            initialReview={d?.pack.review ?? null}
            onClose={() => setDialog(null)}
            onDone={onChanged}
          />
        )}
      </IssuesContext.Provider>
    </LibraryContext.Provider>
  );
}

// ---------- Status, actions, history ----------

function StatusPanels({
  view,
  canEdit,
  canApprove,
  editing,
  showDraft,
  onToggleDraft,
  onEdit,
  onAct,
}: {
  view: FirstAidView;
  canEdit: boolean;
  canApprove: boolean;
  editing: boolean;
  showDraft: boolean;
  onToggleDraft: () => void;
  onEdit: () => void;
  onAct: (act: Act, versionId: string) => void;
}) {
  const intl = useIntl();
  const c = view.current;
  const d = view.draft;
  const review = c?.pack.review;
  return (
    <>
      <div className="toolbar">
        <span className="chips">
          {c ? (
            <>
              <Pill tone="ok">
                <FormattedMessage id="firstAid.inUse" values={{ v: c.version }} />
              </Pill>
              <span className="muted">
                <FormattedMessage
                  id="firstAid.publishedAt"
                  values={{ when: dateTime(intl, c.publishedAt), n: c.pack.situations.length }}
                />
              </span>
              {review && (
                <span className="muted">
                  <FormattedMessage
                    id="firstAid.reviewedBy"
                    values={{ name: review.reviewer, date: review.reviewedOn }}
                  />
                </span>
              )}
            </>
          ) : (
            <Pill tone="muted">
              <FormattedMessage id="firstAid.notPublished" />
            </Pill>
          )}
        </span>
        {canEdit && !editing && (
          <div className="actions">
            <Button kind={d ? 'secondary' : 'primary'} onClick={onEdit}>
              <FormattedMessage id={d ? 'firstAid.editDraft' : 'firstAid.edit'} />
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
                <FormattedMessage id={`firstAid.status.${d.status}`} />
              </Pill>
              <FormattedMessage id="firstAid.openVersion" />
            </span>
          }
          note={
            <FormattedMessage
              id="firstAid.draftBy"
              values={{
                name: d.authorName || '—',
                when: dateTime(intl, d.updatedAt),
                n: d.pack.situations.length,
              }}
            />
          }
          aside={
            <div className="actions">
              {c && !editing && (
                <Button kind="ghost" onClick={onToggleDraft}>
                  <FormattedMessage
                    id={showDraft ? 'firstAid.showCurrent' : 'firstAid.showDraft'}
                  />
                </Button>
              )}
              {canEdit && d.status === 'draft' && (
                <>
                  <Button onClick={() => onAct('discard', d.versionId)}>
                    <FormattedMessage id="firstAid.act.discard" />
                  </Button>
                  <Button
                    kind="primary"
                    disabled={editing}
                    onClick={() => onAct('submit', d.versionId)}
                  >
                    <FormattedMessage id="firstAid.act.submit" />
                  </Button>
                </>
              )}
              {canApprove && d.status === 'pending' && (
                <>
                  <Button disabled={editing} onClick={() => onAct('reject', d.versionId)}>
                    <FormattedMessage id="firstAid.act.reject" />
                  </Button>
                  <Button
                    kind="primary"
                    disabled={editing}
                    onClick={() => onAct('approve', d.versionId)}
                  >
                    <FormattedMessage id="firstAid.act.approve" />
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
                id="firstAid.rejected"
                values={{ name: d.rejection.by, reason: d.rejection.reason }}
              />
            </p>
          )}
          {d.status === 'pending' && (
            <p className="muted">
              <FormattedMessage id="firstAid.waitOther" />
            </p>
          )}
        </Panel>
      )}
    </>
  );
}

function HistoryPanel({
  view,
  canApprove,
  onRollback,
}: {
  view: FirstAidView;
  canApprove: boolean;
  onRollback: (versionId: string) => void;
}) {
  const intl = useIntl();
  const items = view.history.filter((h) => h.status !== 'draft' && h.status !== 'pending');
  if (!items.length) return null;
  // The version in use is already live; any other published or replaced one can come back.
  const canReuse = (h: FirstAidVersion) =>
    h.status === 'retired' || (h.status === 'published' && h.label !== view.current?.version);
  return (
    <Panel className="panel--flush" title={<FormattedMessage id="firstAid.history" />}>
      <TableScroll min={760}>
        <table className="table">
          <thead>
            <tr>
              <th>
                <FormattedMessage id="firstAid.col.version" />
              </th>
              <th>
                <FormattedMessage id="firstAid.col.status" />
              </th>
              <th>
                <FormattedMessage id="firstAid.col.situations" />
              </th>
              <th>
                <FormattedMessage id="firstAid.col.people" />
              </th>
              <th>
                <FormattedMessage id="firstAid.col.when" />
              </th>
              <th>
                <FormattedMessage id="firstAid.col.notes" />
              </th>
              <th />
            </tr>
          </thead>
          <tbody>
            {items.map((h) => (
              <tr key={h.versionId}>
                <td className="mono">{h.label ?? '—'}</td>
                <td>
                  <Pill tone={statusTone[h.status] ?? 'muted'}>
                    <FormattedMessage id={`firstAid.status.${h.status}`} />
                  </Pill>
                </td>
                <td>{h.situations}</td>
                <td>
                  <FormattedMessage
                    id="firstAid.historyBy"
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
                      <FormattedMessage id="firstAid.act.rollback" />
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

// ---------- Review (approve on prod) ----------

export interface ReviewInput {
  reviewer: string;
  reviewedOn: string;
  sources: string;
}

/** The review the approver records; required on prod, optional (all empty = none) elsewhere. */
export function reviewFrom(
  input: ReviewInput,
  required: boolean,
):
  | { ok: true; review: { reviewer: string; reviewedOn: string; sources: string[] } | null }
  | { ok: false } {
  const sources = input.sources
    .split('\n')
    .map((s) => s.trim())
    .filter(Boolean);
  const empty = !input.reviewer.trim() && !sources.length;
  if (!required && empty) return { ok: true, review: null };
  const res = firstAidReviewSchema.safeParse({
    reviewer: input.reviewer.trim(),
    reviewedOn: input.reviewedOn,
    sources,
  });
  if (!res.success || (required && !sources.length)) return { ok: false };
  return { ok: true, review: res.data };
}

const today = () => new Date().toLocaleDateString('en-CA', { timeZone: ZONE });

export function ActDialog({
  act,
  versionId,
  requireReview,
  initialReview,
  onClose,
  onDone,
}: {
  act: Act;
  versionId: string;
  requireReview: boolean;
  initialReview: { reviewer: string; reviewedOn: string; sources: string[] } | null;
  onClose: () => void;
  onDone: () => void;
}) {
  const api = useApi();
  const [reason, setReason] = useState('');
  const [review, setReview] = useState<ReviewInput>({
    reviewer: initialReview?.reviewer ?? '',
    reviewedOn: initialReview?.reviewedOn ?? today(),
    sources: initialReview?.sources.join('\n') ?? '',
  });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const withReview = act === 'approve';
  const touched = !!(review.reviewer || review.sources || reasonOk(reason));
  const checked = withReview
    ? reviewFrom(review, requireReview)
    : { ok: true as const, review: null };
  return (
    <Modal
      wide={withReview}
      title={<FormattedMessage id={`firstAid.confirm.${act}`} />}
      onClose={onClose}
    >
      <p className="modal__sub">
        <FormattedMessage id={`firstAid.confirm.${act}.note`} />
      </p>
      {withReview && (
        <fieldset className="fa-review">
          <legend className="field__label">
            <FormattedMessage
              id={requireReview ? 'firstAid.review.required' : 'firstAid.review.optional'}
            />
          </legend>
          <label className="field">
            <span className="field__label">
              <FormattedMessage id="firstAid.review.reviewer" />
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
              <FormattedMessage id="firstAid.review.reviewedOn" />
            </span>
            <input
              className="field__input"
              type="date"
              value={review.reviewedOn}
              required={requireReview}
              onChange={(e) => setReview({ ...review, reviewedOn: e.target.value })}
            />
          </label>
          <label className="field">
            <span className="field__label">
              <FormattedMessage id="firstAid.review.sources" />
            </span>
            <textarea
              className="field__input"
              rows={3}
              value={review.sources}
              required={requireReview}
              onChange={(e) => setReview({ ...review, sources: e.target.value })}
            />
            <span className="field__help">
              <FormattedMessage id="firstAid.review.sourcesHelp" />
            </span>
          </label>
          {!checked.ok && (
            <p className={touched ? 'error' : 'field__help'}>
              <FormattedMessage id="firstAid.review.incomplete" />
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
          disabled={busy || !reasonOk(reason) || !checked.ok}
          onClick={() => {
            if (!checked.ok) return;
            setBusy(true);
            setError(null);
            api
              .call('staffFirstAidAct', {
                versionId,
                action: act,
                reason: reason.trim(),
                review: checked.review,
              })
              .then(() => {
                onClose();
                onDone();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id={`firstAid.act.${act}`} />
        </Button>
      </div>
    </Modal>
  );
}

// ---------- Editing ----------

/** Where an issue sits, for the summary ("TH03 Đuối nước · variants.0.steps.1.title.vi"). */
export function issuePlace(intl: IntlShape, pack: FirstAidPack, issue: Issue): string {
  const [head, at, ...rest] = issue.path;
  if (head === 'situations' && typeof at === 'number') {
    const s = pack.situations[at];
    const name = s
      ? [s.code, textOf(intl, s.title) || s.id].filter(Boolean).join(' ')
      : `#${at + 1}`;
    return rest.length ? `${name} · ${rest.join('.')}` : name;
  }
  return issue.path.join('.') || '—';
}

function EditBar({
  dirty,
  pending,
  issues,
  pack,
  onOpen,
  onSave,
  onCancel,
}: {
  dirty: boolean;
  pending: boolean;
  issues: Issue[];
  pack: FirstAidPack;
  onOpen: (situation: number) => void;
  onSave: () => void;
  onCancel: () => void;
}) {
  const intl = useIntl();
  return (
    <Panel
      className="fa-editbar"
      title={<FormattedMessage id="firstAid.editing" />}
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
            <FormattedMessage id="firstAid.stopEditing" />
          </Button>
          <Button kind="primary" disabled={!dirty} onClick={onSave}>
            <FormattedMessage id="firstAid.saveDraft" />
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
                {i.path[0] === 'situations' && typeof i.path[1] === 'number' ? (
                  <button
                    type="button"
                    className="linkbtn"
                    onClick={() => onOpen(i.path[1] as number)}
                  >
                    {issuePlace(intl, pack, i)}
                  </button>
                ) : (
                  <span className="mono">{issuePlace(intl, pack, i)}</span>
                )}
                {': '}
                {issueText(intl, i)}
              </li>
            ))}
          </ul>
        </div>
      )}
    </Panel>
  );
}

function SaveDialog({
  pack,
  notes: initialNotes,
  pending,
  onClose,
  onDone,
}: {
  pack: FirstAidPack;
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
    <Modal title={<FormattedMessage id="firstAid.saveTitle" />} onClose={onClose}>
      <p className="modal__sub">
        <FormattedMessage id={pending ? 'firstAid.saveNotePending' : 'firstAid.saveNote'} />
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
            saveFirstAidDraft(api, pack, notes)
              .then((res) => {
                if (!res.ok) throw new ApiError('invalid-argument', 'malformed');
                onClose();
                onDone();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id="firstAid.saveDraft" />
        </Button>
      </div>
    </Modal>
  );
}

// ---------- Situations ----------

const stepCount = (s: FirstAidSituation) => s.variants.reduce((n, v) => n + v.steps.length, 0);

export function SituationList({
  pack,
  editing,
  edit,
  issues,
  onOpen,
  onAdd,
}: {
  pack: FirstAidPack;
  editing: boolean;
  edit: Edit;
  issues: Issue[];
  onOpen: (i: number) => void;
  onAdd: () => void;
}) {
  const intl = useIntl();
  const categories = new Map(pack.categories.map((c) => [c.id, c]));
  const problems = new Map<number, number>();
  for (const i of issues) {
    if (i.path[0] === 'situations' && typeof i.path[1] === 'number') {
      problems.set(i.path[1], (problems.get(i.path[1]) ?? 0) + 1);
    }
  }
  return (
    <Panel
      className="panel--flush"
      title={
        <FormattedMessage
          id="firstAid.situations"
          values={{ n: pack.situations.length, max: 40 }}
        />
      }
      aside={
        editing ? (
          <Button disabled={pack.situations.length >= 40} onClick={onAdd}>
            <FormattedMessage id="firstAid.addSituation" />
          </Button>
        ) : undefined
      }
    >
      <TableScroll min={760}>
        <table className="table">
          <thead>
            <tr>
              <th>#</th>
              <th>
                <FormattedMessage id="firstAid.col.code" />
              </th>
              <th>
                <FormattedMessage id="firstAid.col.title" />
              </th>
              <th>
                <FormattedMessage id="firstAid.col.category" />
              </th>
              <th>
                <FormattedMessage id="firstAid.col.flags" />
              </th>
              <th>
                <FormattedMessage id="firstAid.col.content" />
              </th>
              <th />
            </tr>
          </thead>
          <tbody>
            {pack.situations.map((s, i) => (
              <tr key={`${i}-${s.id}`}>
                <td className="muted">{i + 1}</td>
                <td className="mono">{s.code ?? '—'}</td>
                <td>
                  <span className="fa-title-cell">
                    <ImageThumb id={s.icon || null} size={32} />
                    <button type="button" className="linkbtn" onClick={() => onOpen(i)}>
                      {s.title.vi || <FormattedMessage id="firstAid.untitled" />}
                    </button>
                  </span>
                  <span className="muted fa-sub-line">{s.lead.vi}</span>
                </td>
                <td>{textOf(intl, categories.get(s.category)?.title) || s.category}</td>
                <td>
                  <span className="chips">
                    {s.emergency && (
                      <Pill tone="error">
                        <FormattedMessage id="firstAid.badge.emergency" />
                      </Pill>
                    )}
                    {s.monitoring && (
                      <Pill tone="info">
                        <FormattedMessage id="firstAid.badge.monitoring" />
                      </Pill>
                    )}
                    {problems.has(i) && (
                      <Pill tone="warn">
                        <FormattedMessage
                          id="firstAid.badge.issues"
                          values={{ n: problems.get(i) }}
                        />
                      </Pill>
                    )}
                  </span>
                </td>
                <td className="nowrap">
                  <FormattedMessage
                    id="firstAid.counts"
                    values={{ v: s.variants.length, n: stepCount(s) }}
                  />
                </td>
                <td className="cell-actions">
                  {editing && (
                    <RowActions
                      label={intl.formatMessage(
                        { id: 'table.actionsFor' },
                        { name: s.title.vi || s.id },
                      )}
                      actions={[
                        ...(i > 0
                          ? [
                              {
                                key: 'up',
                                label: <FormattedMessage id="firstAid.moveUp" />,
                                onSelect: () => edit((p) => moveItem(p.situations, i, -1)),
                              },
                            ]
                          : []),
                        ...(i < pack.situations.length - 1
                          ? [
                              {
                                key: 'down',
                                label: <FormattedMessage id="firstAid.moveDown" />,
                                onSelect: () => edit((p) => moveItem(p.situations, i, 1)),
                              },
                            ]
                          : []),
                        ...(pack.situations.length > 1
                          ? [
                              {
                                key: 'remove',
                                destructive: true,
                                label: <FormattedMessage id="firstAid.remove" />,
                                onSelect: () => {
                                  if (
                                    window.confirm(
                                      intl.formatMessage(
                                        { id: 'firstAid.removeConfirm' },
                                        { name: s.title.vi || s.id },
                                      ),
                                    )
                                  ) {
                                    edit((p) => {
                                      p.situations.splice(i, 1);
                                    });
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
            ))}
          </tbody>
        </table>
      </TableScroll>
    </Panel>
  );
}

function SituationPage({
  pack,
  index,
  editing,
  edit,
  idLocked,
  variant,
  onVariant,
  onBack,
}: {
  pack: FirstAidPack;
  index: number;
  editing: boolean;
  edit: Edit;
  idLocked: boolean;
  variant: number;
  onVariant: (v: number) => void;
  onBack: () => void;
}) {
  const intl = useIntl();
  const s = pack.situations[index]!;
  return (
    <div className="stack">
      <div className="toolbar">
        <button type="button" className="linkbtn" onClick={onBack}>
          ← <FormattedMessage id="firstAid.back" />
        </button>
        <span className="muted">
          {[s.code, textOf(intl, s.title) || s.id].filter(Boolean).join(' · ')}
        </span>
      </div>
      <div className="fa-split">
        <Panel>
          {editing ? (
            <SituationEditor
              pack={pack}
              index={index}
              edit={edit}
              idLocked={idLocked}
              variant={variant}
              onVariant={onVariant}
            />
          ) : (
            <SituationSummary pack={pack} situation={s} />
          )}
        </Panel>
        <div className="fa-preview-col">
          <PhonePreview pack={pack} situation={s} variant={variant} onVariant={onVariant} />
        </div>
      </div>
    </div>
  );
}

/** Read-only facts next to the preview (vi and en side by side). */
function SituationSummary({
  pack,
  situation: s,
}: {
  pack: FirstAidPack;
  situation: FirstAidSituation;
}) {
  const intl = useIntl();
  const category = pack.categories.find((c) => c.id === s.category);
  const age = (a: FirstAidSituation['ageMonths']) =>
    a ? intl.formatMessage({ id: 'firstAid.ageRange' }, { from: a.from, to: a.to ?? '∞' }) : '—';
  return (
    <dl className="kv">
      <dt>
        <FormattedMessage id="firstAid.field.id" />
      </dt>
      <dd className="mono">{s.id}</dd>
      <dt>
        <FormattedMessage id="firstAid.field.category" />
      </dt>
      <dd>{textOf(intl, category?.title) || s.category}</dd>
      <dt>
        <FormattedMessage id="firstAid.field.title" />
      </dt>
      <dd>
        {s.title.vi}
        <br />
        <span className="muted">{s.title.en}</span>
      </dd>
      <dt>
        <FormattedMessage id="firstAid.field.lead" />
      </dt>
      <dd>
        {s.lead.vi}
        <br />
        <span className="muted">{s.lead.en}</span>
      </dd>
      <dt>
        <FormattedMessage id="firstAid.field.keywords" />
      </dt>
      <dd>{s.keywords.map((k) => k.vi).join(' · ') || '—'}</dd>
      <dt>
        <FormattedMessage id="firstAid.field.ageMonths" />
      </dt>
      <dd>{age(s.ageMonths)}</dd>
      <dt>
        <FormattedMessage id="firstAid.section.variants" />
      </dt>
      <dd>
        {s.variants
          .map((v) => `${textOf(intl, v.label) || v.id} (${v.steps.length}, ${age(v.ageMonths)})`)
          .join(' · ')}
      </dd>
      <dt>
        <FormattedMessage id="firstAid.field.tool" />
      </dt>
      <dd>{s.tool ? <FormattedMessage id={`firstAid.tool.${s.tool}`} /> : '—'}</dd>
    </dl>
  );
}

function GeneralSummary({ pack }: { pack: FirstAidPack }) {
  const intl = useIntl();
  return (
    <div className="cols cols--1-1">
      <Panel title={<FormattedMessage id="firstAid.section.categories" />}>
        <dl className="kv">
          <dt>
            <FormattedMessage id="firstAid.field.emergencyNumber" />
          </dt>
          <dd className="mono">{pack.emergencyNumber}</dd>
          {pack.categories.map((c) => (
            <Fragment key={c.id}>
              <dt className="mono">{c.id}</dt>
              <dd>
                {textOf(intl, c.title)} · <FormattedMessage id={`firstAid.layout.${c.layout}`} /> ·{' '}
                <FormattedMessage id={`firstAid.categoryTone.${c.tone}`} />
              </dd>
            </Fragment>
          ))}
        </dl>
      </Panel>
      <Panel title={<FormattedMessage id="firstAid.section.quickSearch" />}>
        <span className="chips">
          {pack.quickSearch.length
            ? pack.quickSearch.map((q, i) => (
                <span key={i} className="qa-tag">
                  {textOf(intl, q)}
                </span>
              ))
            : '—'}
        </span>
        {pack.cpr.length > 0 && (
          <dl className="kv">
            {pack.cpr.map((c) => (
              <Fragment key={c.id}>
                <dt>
                  <FormattedMessage id={`firstAid.cpr.${c.id}`} />
                </dt>
                <dd>
                  <FormattedMessage
                    id="firstAid.cprFacts"
                    values={{
                      rate: c.ratePerMinute,
                      compressions: c.compressions,
                      breaths: c.breaths,
                    }}
                  />
                </dd>
              </Fragment>
            ))}
          </dl>
        )}
      </Panel>
    </div>
  );
}

// ---------- Picture library ----------

function Library({ pack, canUpload }: { pack: FirstAidPack; canUpload: boolean }) {
  const intl = useIntl();
  const [filter, setFilter] = useState<'picture' | 'icon' | 'all'>('all');
  const [query, setQuery] = useState('');
  const usage = useMemo(() => {
    const m = new Map<string, number>();
    for (const s of pack.situations) {
      for (const id of firstAidImages({ ...pack, situations: [s], cpr: [] })) {
        m.set(id, (m.get(id) ?? 0) + 1);
      }
    }
    return m;
  }, [pack]);
  const { images } = useContext(LibraryContext);
  return (
    <Panel
      title={<FormattedMessage id="firstAid.library" />}
      note={<FormattedMessage id="firstAid.libraryNote" values={{ n: images.length }} />}
    >
      <div className="stack">
        {canUpload && <UploadBox />}
        <div className="toolbar">
          <Segmented
            label={intl.formatMessage({ id: 'firstAid.library' })}
            value={filter}
            onChange={setFilter}
            options={(['all', 'picture', 'icon'] as const).map((f) => ({
              value: f,
              label: <FormattedMessage id={`firstAid.filter.${f}`} />,
            }))}
          />
          <input
            className="field__input fa-search"
            type="search"
            value={query}
            placeholder={intl.formatMessage({ id: 'firstAid.searchImages' })}
            aria-label={intl.formatMessage({ id: 'firstAid.searchImages' })}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>
        <ImageGrid images={filterImages(images, filter, query)} usage={usage} />
      </div>
    </Panel>
  );
}

// ---------- Phone preview ----------

const previewIntl = {
  vi: createIntl({ locale: 'vi', messages: messages.vi }),
  en: createIntl({ locale: 'en', messages: messages.en }),
};

/** Roughly what the app shows on the situation page (7d), at phone width; read-only. */
export function PhonePreview({
  pack,
  situation: s,
  variant,
  onVariant,
}: {
  pack: FirstAidPack;
  situation: FirstAidSituation;
  variant: number;
  onVariant: (v: number) => void;
}) {
  const intl = useIntl();
  const [lang, setLang] = useState<'vi' | 'en'>('vi');
  const t = previewIntl[lang];
  const v = s.variants[Math.min(variant, s.variants.length - 1)]!;
  const category = pack.categories.find((c) => c.id === s.category);
  const hero = v.hero ?? s.hero;
  const say = (x: { vi: string; en: string } | null | undefined) => (x ? x[lang] : '');
  return (
    <Panel
      title={<FormattedMessage id="firstAid.preview" />}
      aside={
        <Segmented
          label={intl.formatMessage({ id: 'firstAid.preview' })}
          value={lang}
          onChange={setLang}
          options={(['vi', 'en'] as const).map((l) => ({
            value: l,
            label: <FormattedMessage id={`firstAid.lang.${l}`} />,
          }))}
        />
      }
    >
      <div className="fa-phone" lang={lang}>
        <div className="fa-phone__hero">
          <ImageThumb id={hero || null} size={343} />
        </div>
        <div className="fa-phone__body">
          <span className="chips">
            {category && (
              <span className={`fa-tag fa-tag--${category.tone}`}>{say(category.title)}</span>
            )}
            {s.monitoring && (
              <span className="fa-tag fa-tag--mint">
                {t.formatMessage({ id: 'firstAid.preview.monitoring' })}
              </span>
            )}
          </span>
          <h3 className="fa-phone__title">{say(s.title)}</h3>
          <p className="fa-phone__lead">{say(s.lead)}</p>
          {s.variants.length > 1 && (
            <div className="fa-phone__seg" role="tablist">
              {s.variants.map((x, i) => (
                <button
                  key={x.id}
                  type="button"
                  role="tab"
                  aria-selected={x === v}
                  className={x === v ? 'on' : ''}
                  onClick={() => onVariant(i)}
                >
                  {say(x.label) || x.id}
                </button>
              ))}
            </div>
          )}
          {v.banner && <p className="fa-phone__banner">{say(v.banner)}</p>}
          <ol className="fa-phone__steps">
            {v.steps.map((st, i) => (
              <li key={i}>
                <span className="fa-phone__num">{i + 1}</span>
                <div>
                  <strong>{say(st.title)}</strong>
                  <p>{say(st.body)}</p>
                  {st.image && <ImageThumb id={st.image} size={240} />}
                  {(st.chips.length > 0 || st.count) && (
                    <span className="chips">
                      {st.chips.map((c, k) => (
                        <span key={k} className={`fa-chip fa-chip--${c.tone}`}>
                          {say(c.label)}
                        </span>
                      ))}
                      {st.count && (
                        <span className="fa-dots" aria-label={`× ${st.count}`}>
                          {'○'.repeat(st.count)}
                        </span>
                      )}
                    </span>
                  )}
                </div>
              </li>
            ))}
          </ol>
          {v.callouts.map((c, i) => (
            <div key={i} className={`fa-callout fa-callout--${c.tone}`}>
              <strong>{say(c.heading)}</strong>
              <ul>
                {c.items.map((it, k) => (
                  <li key={k}>{say(it)}</li>
                ))}
              </ul>
            </div>
          ))}
          {s.tool === 'seizureTimer' && (
            <p className="fa-phone__tool">
              ⏱ {t.formatMessage({ id: 'firstAid.preview.seizureTimer' })}
            </p>
          )}
          {v.cpr && (
            <p className="fa-phone__tool">{t.formatMessage({ id: 'firstAid.preview.cpr' })}</p>
          )}
          <p className="fa-phone__foot">
            {pack.review
              ? t.formatMessage(
                  { id: 'firstAid.preview.reviewed' },
                  {
                    name: pack.review.reviewer,
                    month: pack.review.reviewedOn.slice(0, 7).split('-').reverse().join('/'),
                  },
                )
              : t.formatMessage({ id: 'firstAid.preview.notReviewed' })}
          </p>
        </div>
        {s.emergency && (
          <div className="fa-phone__call">
            {t.formatMessage({ id: 'firstAid.preview.call' }, { n: pack.emergencyNumber })}
          </div>
        )}
      </div>
    </Panel>
  );
}
