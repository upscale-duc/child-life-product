import {
  defaultRhythmRules,
  activitySchema,
  needs,
  rankingWeights,
  staffCan,
  type Activity,
  type AgeCard,
  type Flags,
  type Need,
  type ReferenceStage,
  type RhythmContent,
  type RhythmDoc,
  type RhythmRules,
} from '@child-life/contracts';
import { ArrowLeft, ChevronLeft, ChevronRight, ExternalLink, Pencil, Plus } from 'lucide-react';
import {
  useCallback,
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
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Textarea } from '@/components/ui/textarea';
import { cn } from '@/lib/utils';
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
import {
  EditorBar,
  EditorLayout,
  EmptyState,
  Field,
  FilterBar,
  HelpPopover,
  Hint,
  Notice,
  OverflowMenu,
  SearchInput,
  Section,
  useConfirm,
  useLeaveGuard,
  VersionBadge,
  type MenuItem,
} from '../content-kit';
import { routePaths, subPath, useNavigate, useStaff } from '../context';
import { ZONE } from '../format';
import {
  Loaded,
  LockNote,
  Modal,
  Page,
  Pill,
  RejectedBy,
  RowActions,
  SelectMenu,
  TableScroll,
  errorMessageId,
  type PillTone,
} from '../ui';
import toddlerDraftData from '../../../../content/rhythm/toddler-v2.draft.json';
import {
  ActivityEditor,
  AgeCardEditor,
  HealthEditor,
  IssuesContext,
  LangSwitch,
  ModelEditor,
  NumberInput,
  StageEditor,
  TextInput,
  blankActivity,
  blankAgeCard,
  blankStage,
  contentDraftFrom,
  dmy,
  forbiddenPhrases,
  matches,
  monthsOf,
  moveItem,
  referenceDraftFrom,
  rhythmActRequest,
  rhythmIssueText,
  rhythmReviewFrom,
  ruleIssueText,
  rulesIssues,
  saveRhythmDraft,
  saveRhythmRules,
  sendRhythmAct,
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
  type Issue,
  type Lang,
  type ReviewInput,
} from './RhythmEditor';

/**
 * Nhịp lớn lên (PN01–PN04, plan §5.6 / §7.1, D-073 #2). Two published documents on the Sơ cứu
 * workflow: the reference model (`publicConfig/rhythm_reference`) and the content pack
 * (`publicConfig/content_rhythm`: activities, age cards, health routing). "Tạo phiên bản mới"
 * opens a working copy, "Lưu nháp" keeps one open version per document, "Gửi duyệt" hands it to
 * another person with "Nội dung · Duyệt", whose approval publishes it (on prod with the qualified
 * review). Rules (`config/rhythm`, PN04) are versioned thresholds (Tính năng · Sửa). Every step
 * is in the audit log; no reason is asked (D-090).
 *
 * Layout (D-063 content kit): each tab opens on its list with the live status in one line and one
 * main action; the model details, history, kill switches and explanations are folded away.
 */

// Hiệu quả cá nhân hoá moved to Phân tích › Cá nhân hoá (owner 2026-10-21).
export type Tab = 'reference' | 'content' | 'rules';
const tabs: Tab[] = ['reference', 'content', 'rules'];
type ContentTab = 'activities' | 'ageCards' | 'health';
const contentTabs: ContentTab[] = ['activities', 'ageCards', 'health'];

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
    <Page title={<FormattedMessage id="rhythm.title" />}>
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
  const { ask, dialog: confirmDialog } = useConfirm();

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
  const dirty = !!((ref.editing && ref.dirty) || (content.editing && content.dirty));
  useLeaveGuard(dirty);
  const leave = (isDirty: boolean, then: () => void) =>
    isDirty
      ? ask({
          title: <FormattedMessage id="rhythm.leave.title" />,
          body: <FormattedMessage id="rhythm.leave.body" />,
          confirmLabel: <FormattedMessage id="kit.leaveConfirm" />,
          destructive: true,
          onConfirm: then,
        })
      : then();

  // Activities a stage can link: the content being edited, else its draft, else what is live.
  const activityOptions: ActivityOption[] = (
    content.editing?.activities ??
    cd?.data.activities ??
    view.content.current?.activities ??
    []
  ).map((a) => ({ id: a.id, title: textOf(intl, a.title), durationMin: a.durationMin }));

  const [dueDate, setDueDate] = useState(() => today ?? todayIso());

  return (
    <Tabs value={tab} onValueChange={(v) => setTab(v as Tab)} className="gap-5">
      <TabsList aria-label={intl.formatMessage({ id: 'rhythm.title' })}>
        {tabs.map((t) => (
          <TabsTrigger key={t} value={t} className="px-3">
            <FormattedMessage id={`rhythm.tab.${t}`} />
          </TabsTrigger>
        ))}
      </TabsList>

      <TabsContent value="reference" className="grid grid-cols-1 gap-4">
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
            onStop={(then) =>
              leave(ref.dirty, () => {
                ref.stop();
                then?.();
              })
            }
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
      </TabsContent>

      <TabsContent value="content" className="grid grid-cols-1 gap-4">
        {canEdit && content.editing && (
          <div className="grid gap-2">
            <Button
              variant="outline"
              onClick={() =>
                content.edit((draft) => {
                  const ids = new Set(draft.activities.map((a) => a.id));
                  for (const value of toddlerDraftData) {
                    const activity = activitySchema.parse(value);
                    if (!ids.has(activity.id)) {
                      draft.activities.push(activity);
                      ids.add(activity.id);
                    }
                  }
                })
              }
            >
              <FormattedMessage id="rhythm.importToddler" />
            </Button>
            <p className="text-sm text-muted-foreground">
              <FormattedMessage id="rhythm.importToddlerHint" />
            </p>
          </div>
        )}
        <IssuesContext.Provider
          value={{ issues: contentCheck?.issues ?? new Map(), show: content.showIssues }}
        >
          <ContentTabView
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
            onStop={(then) =>
              leave(content.dirty, () => {
                content.stop();
                then?.();
              })
            }
            onSave={() => {
              content.setShowIssues(true);
              if (contentCheck?.ok) setDialog({ kind: 'save', doc: 'content' });
            }}
            onAct={(act, versionId) => setDialog({ kind: 'act', doc: 'content', act, versionId })}
          />
        </IssuesContext.Provider>
      </TabsContent>

      <TabsContent value="rules" className="grid grid-cols-1 gap-4">
        <RulesTab
          canView={canViewRules}
          canEdit={canEditRules}
          rules={rules}
          content={view.content.current}
        />
      </TabsContent>

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
      {confirmDialog}
    </Tabs>
  );
}

type Working<T> = ReturnType<typeof useWorking<T>>;

// ---------- Status line, editor bar, issues, history (shared by both documents) ----------

/** The review in words, for the version badge's popover. */
function reviewLine(intl: IntlShape, review: RhythmReview): string {
  return review
    ? intl.formatMessage(
        { id: 'rhythm.reviewedBy' },
        { name: review.reviewer, credential: review.credential, date: dmy(review.reviewedOn) },
      )
    : intl.formatMessage({ id: 'rhythm.notReviewed' });
}

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

/**
 * The workflow steps one person can take on the open version: the main one (a button) and the
 * rest (the "⋯" menu). Draft: the author's team sends it or drops it; pending: an approver.
 */
export function draftActions(
  status: 'draft' | 'pending',
  canEdit: boolean,
  canApprove: boolean,
): { main: Act | null; more: Act[] } {
  if (status === 'draft')
    return canEdit ? { main: 'submit', more: ['discard'] } : { main: null, more: [] };
  return canApprove ? { main: 'approve', more: ['reject'] } : { main: null, more: [] };
}

/** The live version in one line, the open version under it, and the one main action. */
function DocStatus({
  doc,
  docView,
  size,
  stat,
  canEdit,
  canApprove,
  showDraft,
  onToggleDraft,
  onEdit,
  onAct,
}: {
  doc: RhythmDoc;
  docView: RhythmDocView<{ version: string; publishedAt: string | null }, unknown>;
  size: (v: RhythmVersion) => ReactNode;
  /** The live version's review, in a few words (in the version badge's popover). */
  stat: string;
  canEdit: boolean;
  canApprove: boolean;
  showDraft: boolean;
  onToggleDraft: () => void;
  onEdit: () => void;
  onAct: (act: Act, versionId: string) => void;
}) {
  const intl = useIntl();
  const c = docView.current;
  const d = docView.draft;
  const steps = d ? draftActions(d.status, canEdit, canApprove) : { main: null, more: [] };
  // The approver's job on a pending version is the decision; everyone else's is the editing.
  const decisionFirst = d?.status === 'pending' && steps.main === 'approve';
  // "Trả lại" sits next to "Duyệt & xuất bản", as on the other content screens.
  const reject = steps.more.includes('reject');
  const menu: MenuItem[] = d
    ? steps.more
        .filter((act) => act !== 'reject')
        .map((act) => ({
          key: act,
          label: <FormattedMessage id={`rhythm.act.${act}`} />,
          destructive: act === 'discard',
          onSelect: () => onAct(act, d.versionId),
        }))
    : [];
  return (
    <div className="grid gap-3 rounded-xl border bg-card px-4 py-3 text-card-foreground">
      <div className="flex flex-wrap items-center gap-x-3 gap-y-2">
        {/* The live version as a badge; when and who reviewed it are in its popover. */}
        <VersionBadge
          version={c?.version ?? null}
          label={<FormattedMessage id="rhythm.live" />}
          details={
            c
              ? [
                  intl.formatMessage(
                    { id: 'rhythm.publishedAt' },
                    { when: dateTime(intl, c.publishedAt) },
                  ),
                  stat,
                ]
              : []
          }
        />
        {canEdit && (
          <Button
            className="ml-auto"
            variant={decisionFirst ? 'outline' : 'default'}
            onClick={onEdit}
          >
            {d ? <Pencil /> : <Plus />}
            <FormattedMessage id={d ? 'rhythm.editDraft' : 'rhythm.newVersion'} />
          </Button>
        )}
      </div>

      {d && (
        <div className="flex flex-wrap items-center gap-x-3 gap-y-2 border-t pt-3">
          <Pill tone={statusTone[d.status] ?? 'muted'}>
            <FormattedMessage id={`rhythm.status.${d.status}`} />
          </Pill>
          <span className="text-sm font-medium">
            <FormattedMessage id={`rhythm.openVersion.${doc}`} />
          </span>
          {d.status === 'pending' && (
            <Hint>
              <FormattedMessage id="rhythm.waitOther" />
            </Hint>
          )}
          <span className="min-w-0 text-sm text-muted-foreground tabular-nums">
            <FormattedMessage
              id="rhythm.draftBy"
              values={{
                name: d.authorName || '—',
                when: dateTime(intl, d.updatedAt),
                size: size(d),
              }}
            />
          </span>
          {d.notes && (
            <span className="max-w-full min-w-0 truncate text-sm italic" title={d.notes}>
              “{d.notes}”
            </span>
          )}
          <div className="ml-auto flex flex-wrap items-center gap-2">
            {c && (
              <Button variant="ghost" size="sm" onClick={onToggleDraft}>
                <FormattedMessage id={showDraft ? 'rhythm.showCurrent' : 'rhythm.showDraft'} />
              </Button>
            )}
            {reject && (
              <Button
                variant="outline"
                className="text-destructive hover:text-destructive"
                onClick={() => onAct('reject', d.versionId)}
              >
                <FormattedMessage id="rhythm.act.reject" />
              </Button>
            )}
            {steps.main && (
              <Button
                variant={decisionFirst || !canEdit ? 'default' : 'outline'}
                onClick={() => onAct(steps.main!, d.versionId)}
              >
                <FormattedMessage id={`rhythm.act.${steps.main}`} />
              </Button>
            )}
            <OverflowMenu items={menu} />
          </div>
          {d.rejection && (
            <Notice tone="warn" className="basis-full">
              <RejectedBy id="rhythm.rejected" by={d.rejection.by} reason={d.rejection.reason} />
            </Notice>
          )}
        </div>
      )}
    </div>
  );
}

/** The sticky bar while a document is being edited, with what to know before saving. */
function EditingBar({
  doc,
  docView,
  working,
  canEdit,
  onSave,
  onStop,
  onAct,
}: {
  doc: RhythmDoc;
  docView: RhythmDocView<unknown, unknown>;
  working: { dirty: boolean };
  canEdit: boolean;
  onSave: () => void;
  onStop: () => void;
  onAct: (act: Act, versionId: string) => void;
}) {
  const d = docView.draft;
  return (
    <>
      <EditorBar
        titleAs="h2"
        backLabel={<FormattedMessage id="rhythm.stopEditing" />}
        onBack={onStop}
        title={<FormattedMessage id={`rhythm.editingTitle.${doc}`} />}
        badges={
          d ? (
            <Pill tone={statusTone[d.status] ?? 'muted'}>
              <FormattedMessage id={`rhythm.status.${d.status}`} />
            </Pill>
          ) : (
            <Pill tone="info">
              <FormattedMessage id="rhythm.newDraft" />
            </Pill>
          )
        }
        dirty={working.dirty}
        onSave={onSave}
        saveLabel={<FormattedMessage id="rhythm.saveDraft" />}
        menu={
          d && d.status === 'draft' && canEdit
            ? [
                {
                  key: 'discard',
                  destructive: true,
                  label: <FormattedMessage id="rhythm.act.discard" />,
                  onSelect: () => onAct('discard', d.versionId),
                },
              ]
            : undefined
        }
      />
      {d?.status === 'pending' && (
        <Notice tone="info">
          <FormattedMessage id="rhythm.saveNotePending" />
        </Notice>
      )}
      {d?.rejection && (
        <Notice tone="warn">
          <RejectedBy id="rhythm.rejected" by={d.rejection.by} reason={d.rejection.reason} />
        </Notice>
      )}
    </>
  );
}

const fieldNames: Record<string, string> = {
  name: 'rhythm.field.name',
  signs: 'rhythm.field.signs',
  skills: 'rhythm.field.skills',
  notice: 'rhythm.stage.notice',
  title: 'rhythm.field.title',
  body: 'rhythm.field.body',
  summary: 'rhythm.field.summary',
  steps: 'rhythm.field.steps',
  safety: 'rhythm.field.safety',
  tips: 'rhythm.field.tips',
  watchFor: 'rhythm.field.watchFor',
  sources: 'rhythm.field.sources',
  url: 'rhythm.field.sourceUrl',
  id: 'rhythm.field.itemId',
  number: 'rhythm.field.number',
  startOffsetDays: 'rhythm.field.start',
  endOffsetDays: 'rhythm.field.end',
  activityIds: 'rhythm.stageCol.activities',
  needs: 'rhythm.field.needs',
  interests: 'rhythm.field.interests',
  locales: 'rhythm.field.locales',
  regions: 'rhythm.field.regions',
  ageDays: 'rhythm.itemCol.age',
  from: 'rhythm.field.ageFrom',
  to: 'rhythm.field.ageTo',
  durationMin: 'rhythm.field.duration',
  timeOfDay: 'rhythm.field.timeOfDay',
  status: 'rhythm.field.itemStatus',
  whileWaiting: 'rhythm.field.whileWaiting',
  disclaimer: 'rhythm.field.disclaimer',
  health: 'rhythm.sub.health',
  maxAgeDays: 'rhythm.field.maxAgeDays',
  country: 'rhythm.field.country',
  emergencyNumber: 'rhythm.field.emergencyNumber',
};

/** "Dấu hiệu có thể gặp · VI · #2" for the rest of an issue's path, in the form's words. */
function fieldPath(intl: IntlShape, path: Issue['path'], from = 0): string {
  const out: string[] = [];
  for (let k = from; k < path.length; k++) {
    const seg = path[k]!;
    if (typeof seg === 'number') out.push(`#${seg + 1}`);
    else if (seg === 'vi' || seg === 'en') out.push(seg.toUpperCase());
    else if (seg === 'label') {
      const parent = path[k - 2];
      const id =
        parent === 'sources'
          ? 'rhythm.field.sourceLabel'
          : parent === 'signs'
            ? 'rhythm.field.signLabel'
            : 'rhythm.field.label';
      out.push(intl.formatMessage({ id }));
    } else if (seg === 'signs' && path[0] === 'health')
      out.push(intl.formatMessage({ id: 'rhythm.health.signsShort' }));
    else out.push(fieldNames[seg] ? intl.formatMessage({ id: fieldNames[seg] }) : seg);
  }
  return out.join(' · ');
}

/** "Còn n chỗ chưa hợp lệ": each one a link to the item that has it. */
function IssuesNotice({
  check,
  show,
  place,
  onOpen,
}: {
  check: Check | null;
  show: boolean;
  place: (issue: Issue) => string;
  onOpen: (issue: Issue) => void;
}) {
  const intl = useIntl();
  const issues = show ? (check?.list ?? []) : [];
  if (!issues.length) return null;
  return (
    <Notice
      tone="error"
      title={<FormattedMessage id="rhythm.issues" values={{ n: issues.length }} />}
    >
      <ul className="grid gap-1">
        {issues.slice(0, 12).map((i, k) => (
          <li key={k}>
            <button
              type="button"
              className="text-left font-medium underline underline-offset-2 hover:no-underline"
              onClick={() => onOpen(i)}
            >
              {place(i)}
            </button>
            {': '}
            {rhythmIssueText(intl, i)}
          </li>
        ))}
        {issues.length > 12 && (
          <li>
            <FormattedMessage id="rhythm.issuesMore" values={{ n: issues.length - 12 }} />
          </li>
        )}
      </ul>
    </Notice>
  );
}

/** Back to the list, the item's name, and previous / next through the list as filtered. */
function ItemNav({
  backLabel,
  title,
  meta,
  badges,
  index,
  order,
  onBack,
  onGo,
}: {
  backLabel: ReactNode;
  title: ReactNode;
  meta?: ReactNode;
  badges?: ReactNode;
  index: number;
  /** The indices in the order the list showed them. */
  order: number[];
  onBack: () => void;
  onGo: (index: number) => void;
}) {
  const intl = useIntl();
  const at = order.indexOf(index);
  const prev = at > 0 ? order[at - 1] : undefined;
  const next = at >= 0 && at < order.length - 1 ? order[at + 1] : undefined;
  return (
    <div className="flex flex-wrap items-center gap-x-3 gap-y-2">
      <Button variant="ghost" size="sm" className="-ml-2 text-muted-foreground" onClick={onBack}>
        <ArrowLeft />
        {backLabel}
      </Button>
      <div className="flex min-w-0 flex-1 flex-wrap items-center gap-x-2 gap-y-1">
        <h2 className="min-w-0 truncate text-base font-semibold">{title}</h2>
        {badges}
        {meta && <span className="font-mono text-xs text-muted-foreground">{meta}</span>}
      </div>
      {at >= 0 && order.length > 1 && (
        <div className="flex items-center gap-1">
          <span className="mr-1 text-sm text-muted-foreground tabular-nums">
            {at + 1}/{order.length}
          </span>
          <Button
            variant="outline"
            size="icon-sm"
            aria-label={intl.formatMessage({ id: 'rhythm.prevItem' })}
            title={intl.formatMessage({ id: 'rhythm.prevItem' })}
            disabled={prev === undefined}
            onClick={() => prev !== undefined && onGo(prev)}
          >
            <ChevronLeft />
          </Button>
          <Button
            variant="outline"
            size="icon-sm"
            aria-label={intl.formatMessage({ id: 'rhythm.nextItem' })}
            title={intl.formatMessage({ id: 'rhythm.nextItem' })}
            disabled={next === undefined}
            onClick={() => next !== undefined && onGo(next)}
          >
            <ChevronRight />
          </Button>
        </div>
      )}
    </div>
  );
}

/** PN01 "Danh sách phiên bản": every version but the discarded ones, newest first (folded). */
function HistorySection({
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
  const items = docView.history.filter((h) => h.status !== 'discarded');
  if (!items.length) return null;
  return (
    <Section
      title={<FormattedMessage id={`rhythm.history.${doc}`} />}
      collapsible
      defaultOpen={false}
      flush
      summary={<FormattedMessage id="rhythm.history.count" values={{ n: items.length }} />}
    >
      <HistoryTable
        docView={docView}
        size={size}
        locales={locales}
        canApprove={canApprove}
        onRollback={onRollback}
      />
    </Section>
  );
}

export function HistoryTable({
  docView,
  size,
  locales,
  canApprove,
  onRollback,
}: {
  docView: RhythmDocView<{ version: string }, unknown>;
  size: (v: RhythmVersion) => ReactNode;
  locales: (v: RhythmVersion) => string;
  canApprove: boolean;
  onRollback: (versionId: string) => void;
}) {
  const intl = useIntl();
  const items = docView.history.filter((h) => h.status !== 'discarded');
  // The version in use is already live; any other published or replaced one can come back.
  const canReuse = (h: RhythmVersion) =>
    h.status === 'retired' || (h.status === 'published' && h.label !== docView.current?.version);
  return (
    <TableScroll min={860}>
      <table className="table">
        <thead>
          <tr>
            {(['version', 'status', 'size', 'review', 'locales', 'people', 'when'] as const).map(
              (c) => (
                <th key={c}>
                  <FormattedMessage id={`rhythm.col.${c}`} />
                </th>
              ),
            )}
            <th />
          </tr>
        </thead>
        <tbody>
          {items.map((h) => (
            <tr key={h.versionId}>
              <td>
                <span className="block font-mono text-[13px]">{h.label ?? '—'}</span>
                {h.notes && (
                  <span
                    className="block max-w-56 truncate text-xs text-muted-foreground"
                    title={h.notes}
                  >
                    {h.notes}
                  </span>
                )}
              </td>
              <td>
                <Pill tone={statusTone[h.status] ?? 'muted'}>
                  <FormattedMessage id={`rhythm.status.${h.status}`} />
                </Pill>
              </td>
              <td className="nowrap">{size(h)}</td>
              <td className="text-muted-foreground">
                <ReviewText review={h.review} />
              </td>
              <td className="nowrap">{locales(h)}</td>
              <td className="text-muted-foreground">
                <FormattedMessage
                  id="rhythm.historyBy"
                  values={{ author: h.authorName || '—', approver: h.approverName ?? '—' }}
                />
              </td>
              <td className="nowrap tabular-nums">
                {dateTime(intl, h.approvedAt ?? h.updatedAt ?? h.createdAt)}
              </td>
              <td className="cell-actions">
                {canApprove && canReuse(h) && (
                  <Button variant="ghost" size="sm" onClick={() => onRollback(h.versionId)}>
                    <FormattedMessage id="rhythm.act.rollback" />
                  </Button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </TableScroll>
  );
}

// ---------- Dialogs ----------

/** A note: 500 characters at most, with the count. */
function NoteField({
  label,
  value,
  onChange,
}: {
  label: ReactNode;
  value: string;
  onChange: (v: string) => void;
}) {
  const id = useId();
  return (
    <Field label={label} htmlFor={id} counter={{ n: value.length, max: 500 }}>
      <Textarea
        id={id}
        rows={3}
        maxLength={500}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
    </Field>
  );
}

function DialogActions({ children }: { children: ReactNode }) {
  return <div className="flex flex-wrap justify-end gap-2 pt-1">{children}</div>;
}

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
  const intl = useIntl();
  const ids = { reviewer: useId(), credential: useId(), reviewedOn: useId() };
  const [review, setReview] = useState<ReviewInput>({
    reviewer: '',
    credential: '',
    reviewedOn: todayIso(),
  });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const withReview = act === 'approve';
  const req = rhythmActRequest(doc, versionId, act, withReview ? review : null, requireReview);
  const reviewOk = !withReview || rhythmReviewFrom(review, requireReview).ok;
  const touched = !!(review.reviewer || review.credential);
  return (
    <Modal
      wide={withReview}
      title={<FormattedMessage id={`rhythm.confirm.${act}`} />}
      onClose={onClose}
    >
      <p className="text-sm text-muted-foreground">
        <FormattedMessage id={`rhythm.confirm.${act}.note`} />
      </p>
      {withReview && (
        <fieldset className="grid gap-4 rounded-lg border p-4">
          <legend className="px-1 text-[13px] font-semibold">
            <FormattedMessage
              id={requireReview ? 'rhythm.review.required' : 'rhythm.review.optional'}
            />
          </legend>
          <div className="grid gap-4 sm:grid-cols-[minmax(0,1fr)_minmax(0,1fr)_10rem]">
            <Field label={<FormattedMessage id="rhythm.review.reviewer" />} htmlFor={ids.reviewer}>
              <Input
                id={ids.reviewer}
                value={review.reviewer}
                maxLength={120}
                required={requireReview}
                onChange={(e) => setReview({ ...review, reviewer: e.target.value })}
              />
            </Field>
            <Field
              label={<FormattedMessage id="rhythm.review.credential" />}
              htmlFor={ids.credential}
            >
              <Input
                id={ids.credential}
                value={review.credential}
                maxLength={120}
                required={requireReview}
                onChange={(e) => setReview({ ...review, credential: e.target.value })}
              />
            </Field>
            <Field
              label={<FormattedMessage id="rhythm.review.reviewedOn" />}
              htmlFor={ids.reviewedOn}
            >
              <Input
                id={ids.reviewedOn}
                type="date"
                value={review.reviewedOn}
                required={requireReview}
                onChange={(e) => setReview({ ...review, reviewedOn: e.target.value })}
              />
            </Field>
          </div>
          {!reviewOk && (
            <p className={cn('text-xs', touched ? 'text-destructive' : 'text-muted-foreground')}>
              <FormattedMessage id="rhythm.review.incomplete" />
            </p>
          )}
          {!requireReview && (
            <p className="text-xs text-muted-foreground">
              <FormattedMessage id="rhythm.review.optionalHelp" />
            </p>
          )}
        </fieldset>
      )}
      {error && (
        <Notice tone="error">
          <FormattedMessage id={errorMessageId(error)} />
        </Notice>
      )}
      <DialogActions>
        <Button variant="outline" onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button
          variant={act === 'discard' || act === 'reject' ? 'destructive' : 'default'}
          disabled={busy || !req}
          onClick={() => {
            if (!req) return;
            setBusy(true);
            setError(null);
            sendRhythmAct(api, doc, versionId, act, withReview ? review : null, requireReview)
              .then((res) => {
                if (!res.ok) throw new ApiError('invalid-argument', 'malformed');
                toast.success(intl.formatMessage({ id: `rhythm.toast.${act}` }));
                onClose();
                onDone();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id={`rhythm.act.${act}`} />
        </Button>
      </DialogActions>
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
  const intl = useIntl();
  const [notes, setNotes] = useState(initialNotes);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  return (
    <Modal title={<FormattedMessage id={`rhythm.saveTitle.${doc}`} />} onClose={onClose}>
      <p className="text-sm text-muted-foreground">
        <FormattedMessage id={pending ? 'rhythm.saveNotePending' : 'rhythm.saveNote'} />
      </p>
      <NoteField
        label={<FormattedMessage id="rhythm.saveNotes" />}
        value={notes}
        onChange={setNotes}
      />
      {error && (
        <Notice tone="error">
          <FormattedMessage id={errorMessageId(error)} />
        </Notice>
      )}
      <DialogActions>
        <Button variant="outline" onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button
          disabled={busy}
          onClick={() => {
            setBusy(true);
            setError(null);
            saveRhythmDraft(api, doc, data, notes)
              .then((res) => {
                if (!res.ok) throw new ApiError('invalid-argument', 'malformed');
                toast.success(intl.formatMessage({ id: 'rhythm.toast.saved' }));
                onClose();
                onDone();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id="rhythm.saveDraft" />
        </Button>
      </DialogActions>
    </Modal>
  );
}

// ---------- Small read-only pieces ----------

/** Label / value rows. */
function Rows({ children }: { children: ReactNode }) {
  return (
    <dl className="grid gap-x-6 gap-y-3 text-sm sm:grid-cols-[minmax(0,11rem)_minmax(0,1fr)]">
      {children}
    </dl>
  );
}

function Row({ label, children }: { label: ReactNode; children: ReactNode }) {
  return (
    <>
      <dt className="text-muted-foreground">{label}</dt>
      <dd className="min-w-0">{children}</dd>
    </>
  );
}

function Bullets({ items, ordered }: { items: string[]; ordered?: boolean }) {
  if (!items.length) return <span className="text-muted-foreground">—</span>;
  const List = ordered ? 'ol' : 'ul';
  return (
    <List className={cn('grid gap-1 pl-5', ordered ? 'list-decimal' : 'list-disc')}>
      {items.map((t, i) => (
        <li key={i}>{t}</li>
      ))}
    </List>
  );
}

function Sources({ list }: { list: Array<{ label: string; url: string }> }) {
  if (!list.length) return <span className="text-muted-foreground">—</span>;
  return (
    <ol className="grid list-decimal gap-1 pl-5">
      {list.map((s, i) => (
        <li key={i}>
          <a
            href={s.url}
            target="_blank"
            rel="noreferrer noopener"
            className="text-primary underline-offset-2 [overflow-wrap:anywhere] hover:underline"
          >
            {s.label}
          </a>
        </li>
      ))}
    </ol>
  );
}

/** vi on the left, en on the right (read-only). */
function BothLangs({ render }: { render: (lang: Lang) => ReactNode }) {
  return (
    <div className="grid gap-x-8 gap-y-5 md:grid-cols-2">
      {(['vi', 'en'] as const).map((lang) => (
        <div key={lang} className="grid min-w-0 content-start gap-3">
          <p className="text-xs font-medium tracking-wide text-muted-foreground uppercase">
            <FormattedMessage id={`rhythm.lang.${lang}`} />
          </p>
          {render(lang)}
        </div>
      ))}
    </div>
  );
}

function Labeled({ label, children }: { label: ReactNode; children: ReactNode }) {
  return (
    <div className="grid gap-1 text-sm">
      <p className="text-[13px] font-medium text-muted-foreground">{label}</p>
      <div>{children}</div>
    </div>
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
  onStop: (then?: () => void) => void;
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
  const viewingDraft = !editing && showDraft && !!doc.draft;
  return (
    <>
      {editing ? (
        <EditingBar
          doc="reference"
          docView={doc}
          working={working}
          canEdit={canEdit}
          onSave={onSave}
          onStop={() =>
            onStop(() => {
              // A stage added in this session is gone with it: back to the list.
              const after = (doc.draft?.data ?? doc.current)?.stages.length ?? 0;
              if (selected !== null && selected >= after) setSelected(null);
            })
          }
          onAct={onAct}
        />
      ) : (
        <DocStatus
          doc="reference"
          docView={doc}
          size={size}
          stat={doc.current ? reviewLine(intl, doc.current.review) : ''}
          canEdit={canEdit}
          canApprove={canApprove}
          showDraft={showDraft}
          onToggleDraft={onToggleDraft}
          onEdit={onStart}
          onAct={onAct}
        />
      )}
      {editing && (
        <IssuesNotice
          check={check}
          show={working.showIssues}
          place={(i) => {
            if (i.path[0] === 'stages' && typeof i.path[1] === 'number') {
              const s = editing.stages[i.path[1]];
              const name = s ? stageName(intl, s, i.path[1]) : `#${i.path[1] + 1}`;
              return i.path.length > 2 ? `${name} · ${fieldPath(intl, i.path, 2)}` : name;
            }
            return fieldPath(intl, i.path) || '—';
          }}
          onOpen={(i) =>
            open(i.path[0] === 'stages' && typeof i.path[1] === 'number' ? i.path[1] : null)
          }
        />
      )}

      {!shown ? (
        <Section title={<FormattedMessage id="rhythm.tab.reference" />}>
          <EmptyState title={<FormattedMessage id="rhythm.empty" />}>
            {canEdit && <FormattedMessage id="rhythm.emptyEdit" />}
          </EmptyState>
        </Section>
      ) : stage && selected !== null ? (
        <>
          <ItemNav
            backLabel={<FormattedMessage id="rhythm.backStages" />}
            title={stageName(intl, stage, selected)}
            index={selected}
            order={shown.stages.map((_, i) => i)}
            onBack={() => open(null)}
            onGo={open}
          />
          <EditorLayout
            aside={
              <StageAside
                stage={stage}
                dueDate={dueDate}
                onDueDate={onDueDate}
                hits={hits.filter((h) => h.stage === selected)}
                model={shown}
                editing={!!editing}
              />
            }
          >
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
          </EditorLayout>
        </>
      ) : (
        <>
          {hits.length > 0 && <ForbiddenNotice hits={hits} model={shown} onOpen={open} />}
          <Section
            flush
            title={
              <>
                <FormattedMessage id="rhythm.stages" values={{ n: shown.stages.length, max: 30 }} />
                {viewingDraft && (
                  <Pill tone="wait">
                    <FormattedMessage id="rhythm.viewingDraft" />
                  </Pill>
                )}
              </>
            }
            hint={<FormattedMessage id="rhythm.stagesNote" />}
            actions={
              <>
                <DueDateControl dueDate={dueDate} onDueDate={onDueDate} />
                <NeverWriteHelp />
                <HelpPopover title={<FormattedMessage id="rhythm.how" />} wide>
                  <HowItWorks />
                </HelpPopover>
                {editing && (
                  <Button
                    variant="outline"
                    size="sm"
                    disabled={shown.stages.length >= 30}
                    onClick={() => {
                      working.edit((m) => {
                        m.stages.push(blankStage(m.stages));
                      });
                      open(editing.stages.length);
                    }}
                  >
                    <Plus />
                    <FormattedMessage id="rhythm.addStage" />
                  </Button>
                )}
              </>
            }
          >
            <StagesTable
              model={shown}
              editing={editing ? working.edit : null}
              dueDate={dueDate}
              hits={hits}
              check={working.showIssues ? check : null}
              onOpen={open}
            />
          </Section>
          <ModelSection model={shown} edit={editing ? working.edit : null} />
        </>
      )}

      <HistorySection
        doc="reference"
        docView={doc}
        size={size}
        locales={() => 'VI · EN'}
        canApprove={canApprove}
        onRollback={(versionId) => onAct('rollback', versionId)}
      />
      <KillSwitchPanel flags={flags} />
    </>
  );
}

/** The sample due date, only to preview each stage's window (not saved). */
function DueDateControl({
  dueDate,
  onDueDate,
}: {
  dueDate: string;
  onDueDate: (d: string) => void;
}) {
  const id = useId();
  return (
    <div className="flex items-center gap-1.5">
      <Label htmlFor={id} className="text-[13px] whitespace-nowrap text-muted-foreground">
        <FormattedMessage id="rhythm.dueDate.label" />
      </Label>
      <Input
        id={id}
        type="date"
        className="h-8 w-[9.5rem] tabular-nums"
        value={dueDate}
        onChange={(e) => onDueDate(e.target.value)}
      />
      <Hint>
        <FormattedMessage id="rhythm.dueDate.help" />
      </Hint>
    </div>
  );
}

/** "Mô hình · Wonder Weeks": its name, review and sources, folded away. */
function ModelSection({
  model,
  edit,
}: {
  model: ReferenceDraftData;
  edit: Edit<ReferenceDraftData> | null;
}) {
  const { issues, show } = useContext(IssuesContext);
  const bad =
    !!edit &&
    show &&
    [...issues.keys()].some((k) => k === 'label' || k === 'sources' || k.startsWith('sources.'));
  return (
    <Section
      key={bad ? 'open' : 'closed'}
      title={<FormattedMessage id="rhythm.model" values={{ label: model.label || '—' }} />}
      collapsible
      defaultOpen={bad}
      summary={
        <>
          <FormattedMessage id="rhythm.sourcesCount" values={{ n: model.sources.length }} />
          {' · '}
          <ReviewText review={model.review} />
        </>
      }
    >
      {edit ? (
        <ModelEditor model={model} edit={edit} />
      ) : (
        <Rows>
          <Row label={<FormattedMessage id="rhythm.field.label" />}>{model.label}</Row>
          <Row label={<FormattedMessage id="rhythm.col.size" />}>
            <FormattedMessage id="rhythm.size.reference" values={{ n: model.stages.length }} />
          </Row>
          <Row label={<FormattedMessage id="rhythm.col.review" />}>
            <ReviewText review={model.review} />
          </Row>
          <Row label={<FormattedMessage id="rhythm.field.sources" />}>
            <Sources list={model.sources} />
          </Row>
        </Rows>
      )}
    </Section>
  );
}

/** PN02 "Không được viết" behind a button. */
function NeverWriteHelp() {
  return (
    <HelpPopover title={<FormattedMessage id="rhythm.forbidden" />}>
      <p className="text-muted-foreground">
        <FormattedMessage id="rhythm.forbidden.examples" />
      </p>
    </HelpPopover>
  );
}

/** The stage texts that slipped into "Không được viết", each a link to its stage. */
export function ForbiddenNotice({
  hits,
  model,
  onOpen,
}: {
  hits: ForbiddenHit[];
  model: ReferenceDraftData;
  onOpen?: (stage: number) => void;
}) {
  const intl = useIntl();
  return (
    <Notice
      tone="warn"
      title={<FormattedMessage id="rhythm.forbidden.found" values={{ n: hits.length }} />}
    >
      <ul className="grid gap-1">
        {hits.map((h, k) => {
          const s = model.stages[h.stage];
          const line = (
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
          );
          return (
            <li key={k}>
              {onOpen ? (
                <button
                  type="button"
                  className="text-left underline-offset-2 hover:underline"
                  onClick={() => onOpen(h.stage)}
                >
                  {line}
                </button>
              ) : (
                line
              )}
            </li>
          );
        })}
      </ul>
    </Notice>
  );
}

/** PN01 "Phiên bản đang phát hành": how the app counts, stated once. */
export function HowItWorks() {
  return (
    <dl className="grid gap-2">
      {(['calc', 'noDue', 'estimated', 'change', 'overlap'] as const).map((k) => (
        <div key={k} className="grid gap-0.5">
          <dt className="font-medium">
            <FormattedMessage id={`rhythm.how.${k}`} />
          </dt>
          <dd className="text-muted-foreground">
            <FormattedMessage id={`rhythm.how.${k}.value`} />
          </dd>
        </div>
      ))}
    </dl>
  );
}

function StagesTable({
  model,
  editing,
  dueDate,
  hits,
  check,
  onOpen,
}: {
  model: ReferenceDraftData;
  editing: Edit<ReferenceDraftData> | null;
  dueDate: string;
  hits: ForbiddenHit[];
  check: Check | null;
  onOpen: (i: number) => void;
}) {
  const intl = useIntl();
  const { ask, dialog } = useConfirm();
  const problems = rowProblems(check, 'stages');
  // "Cần xem" only when a stage has something to look at.
  const flagged = hits.length > 0 || problems.size > 0;
  const cols = ['stage', 'offsets', 'window', ...(flagged ? (['flags'] as const) : [])] as const;
  return (
    <>
      <TableScroll min={760}>
        <table className="table">
          <thead>
            <tr>
              <th className="w-12">#</th>
              {cols.map((c) => (
                <th key={c}>
                  <FormattedMessage id={`rhythm.stageCol.${c}`} />
                </th>
              ))}
              {editing && <th className="w-12" />}
            </tr>
          </thead>
          <tbody>
            {model.stages.map((s, i) => {
              const w = windowPreview(dueDate, s);
              const n = hits.filter((h) => h.stage === i).length;
              const name = stageName(intl, s, i);
              return (
                <tr key={`${i}-${s.id}`} className="cursor-pointer" onClick={() => onOpen(i)}>
                  <td className="text-muted-foreground tabular-nums">{s.number}</td>
                  <td className="w-full max-w-0">
                    <RowTitle onOpen={() => onOpen(i)}>{name}</RowTitle>
                    <span className="block truncate text-xs text-muted-foreground">
                      <FormattedMessage
                        id="rhythm.stageLine"
                        values={{ n: s.signs.vi.length, a: s.activityIds.length }}
                      />
                      {s.notice && (
                        <>
                          {' · '}
                          <FormattedMessage id="rhythm.stageLine.notice" />
                        </>
                      )}
                    </span>
                  </td>
                  <td className="nowrap tabular-nums">
                    <FormattedMessage
                      id="rhythm.offsets"
                      values={{ start: s.startOffsetDays, end: s.endOffsetDays }}
                    />
                  </td>
                  <td className="nowrap tabular-nums">
                    {w ? `${dmy(w.start)} – ${dmy(w.end)}` : '—'}
                  </td>
                  {flagged && (
                    <td>
                      <span className="flex flex-wrap gap-1">
                        {n > 0 && (
                          <Pill tone="warn">
                            <FormattedMessage id="rhythm.badge.forbidden" values={{ n }} />
                          </Pill>
                        )}
                        {problems.has(i) && (
                          <Pill tone="error">
                            <FormattedMessage
                              id="rhythm.badge.issues"
                              values={{ n: problems.get(i) }}
                            />
                          </Pill>
                        )}
                      </span>
                    </td>
                  )}
                  {editing && (
                    <td className="cell-actions" onClick={(e) => e.stopPropagation()}>
                      <RowActions
                        label={intl.formatMessage({ id: 'table.actionsFor' }, { name })}
                        actions={[
                          ...(i > 0
                            ? [
                                {
                                  key: 'up',
                                  label: <FormattedMessage id="rhythm.moveUp" />,
                                  onSelect: () => editing((m) => moveItem(m.stages, i, -1)),
                                },
                              ]
                            : []),
                          ...(i < model.stages.length - 1
                            ? [
                                {
                                  key: 'down',
                                  label: <FormattedMessage id="rhythm.moveDown" />,
                                  onSelect: () => editing((m) => moveItem(m.stages, i, 1)),
                                },
                              ]
                            : []),
                          ...(model.stages.length > 1
                            ? [
                                {
                                  key: 'remove',
                                  destructive: true,
                                  label: <FormattedMessage id="rhythm.remove" />,
                                  onSelect: () =>
                                    ask({
                                      title: (
                                        <FormattedMessage
                                          id="rhythm.removeConfirm"
                                          values={{ name }}
                                        />
                                      ),
                                      confirmLabel: <FormattedMessage id="rhythm.remove" />,
                                      destructive: true,
                                      onConfirm: () => editing((m) => void m.stages.splice(i, 1)),
                                    }),
                                },
                              ]
                            : []),
                        ]}
                      />
                    </td>
                  )}
                </tr>
              );
            })}
          </tbody>
        </table>
      </TableScroll>
      {dialog}
    </>
  );
}

/** The row's name: a button for the keyboard; the whole row opens the item for the mouse. */
function RowTitle({ children, onOpen }: { children: ReactNode; onOpen: () => void }) {
  return (
    <button
      type="button"
      className="block max-w-full truncate text-left font-medium underline-offset-2 hover:underline focus-visible:underline focus-visible:outline-none"
      onClick={(e) => {
        e.stopPropagation();
        onOpen();
      }}
    >
      {children}
    </button>
  );
}

function StageAside({
  stage,
  dueDate,
  onDueDate,
  hits,
  model,
  editing,
}: {
  stage: ReferenceStage;
  dueDate: string;
  onDueDate: (d: string) => void;
  hits: ForbiddenHit[];
  model: ReferenceDraftData;
  /** The editor shows the window itself, next to the days. */
  editing: boolean;
}) {
  const w = windowPreview(dueDate, stage);
  return (
    <>
      <Section title={<FormattedMessage id="rhythm.dueDate" />}>
        <div className="grid gap-3">
          <DueDateControl dueDate={dueDate} onDueDate={onDueDate} />
          {!editing && (
            <p className="rounded-lg bg-muted/60 px-3 py-2 text-sm tabular-nums">
              {w ? (
                <FormattedMessage
                  id="rhythm.stage.preview"
                  values={{ due: dmy(dueDate), start: dmy(w.start), end: dmy(w.end) }}
                />
              ) : (
                <FormattedMessage id="rhythm.stage.previewNone" />
              )}
            </p>
          )}
        </div>
      </Section>
      {hits.length > 0 && <ForbiddenNotice hits={hits} model={model} />}
      <Section title={<FormattedMessage id="rhythm.forbidden" />}>
        <p className="text-sm text-muted-foreground">
          <FormattedMessage id="rhythm.forbidden.examples" />
        </p>
      </Section>
    </>
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
  return (
    <>
      <Section title={<FormattedMessage id="rhythm.stage.content" />}>
        <BothLangs
          render={(lang) => (
            <>
              <p className="font-semibold">{s.name[lang] || '—'}</p>
              <Labeled label={<FormattedMessage id="rhythm.field.signs" />}>
                <Bullets items={s.signs[lang]} />
              </Labeled>
              <Labeled label={<FormattedMessage id="rhythm.field.skills" />}>
                <Bullets items={s.skills[lang]} />
              </Labeled>
            </>
          )}
        />
      </Section>
      <Section title={<FormattedMessage id="rhythm.stage.timing" />}>
        <Rows>
          <Row label={<FormattedMessage id="rhythm.stageCol.offsets" />}>
            <span className="tabular-nums">
              <FormattedMessage
                id="rhythm.offsets"
                values={{ start: s.startOffsetDays, end: s.endOffsetDays }}
              />
            </span>
          </Row>
          <Row label={<FormattedMessage id="rhythm.stageCol.window" />}>
            <span className="tabular-nums">{w ? `${dmy(w.start)} – ${dmy(w.end)}` : '—'}</span>
          </Row>
        </Rows>
      </Section>
      <Section
        title={
          <FormattedMessage
            id="rhythm.field.activities"
            values={{ n: s.activityIds.length, max: 8 }}
          />
        }
      >
        <Bullets items={s.activityIds.map((id) => names.get(id) || id)} />
      </Section>
      <Section title={<FormattedMessage id="rhythm.stage.notice" />}>
        {s.notice ? (
          <BothLangs
            render={(lang) => (
              <div className="grid gap-1 rounded-lg border bg-background/40 p-3 text-sm">
                <p className="font-medium">{s.notice!.title[lang]}</p>
                <p className="text-muted-foreground">{s.notice!.body[lang]}</p>
              </div>
            )}
          />
        ) : (
          <p className="text-sm text-muted-foreground">
            <FormattedMessage id="rhythm.stage.noNotice" />
          </p>
        )}
      </Section>
    </>
  );
}

// ---------- Kill switches (PN01) ----------

const killSwitches = ['rhythm', 'personalization', 'ai_assist'] as const;

/** PN01 "Công tắc khẩn cấp": the flags' state (folded); they are switched in the hub. */
export function KillSwitchPanel({ flags }: { flags: Flags | null | undefined }) {
  const staff = useStaff();
  if (!staffCan(staff.levels, 'features.view')) {
    return (
      <Section
        title={<FormattedMessage id="rhythm.switches" />}
        collapsible
        defaultOpen={false}
        summary={<FormattedMessage id="rhythm.switches.lockedShort" />}
      >
        <LockNote>
          <FormattedMessage id="rhythm.switches.locked" />
        </LockNote>
      </Section>
    );
  }
  return flags === undefined ? <KillSwitchLoader /> : <KillSwitchSection flags={flags} />;
}

function KillSwitchLoader() {
  const [load] = useLoad<FlagsView>('staffFlags', {}, 'flags');
  return <KillSwitchSection flags={load.status === 'ok' ? load.data.flags : null} />;
}

function KillSwitchSection({ flags }: { flags: Flags | null }) {
  const navigate = useNavigate();
  const on = killSwitches.filter((k) => flags?.[k]?.enabled).length;
  return (
    <Section
      title={<FormattedMessage id="rhythm.switches" />}
      collapsible
      defaultOpen={false}
      summary={
        flags ? (
          <FormattedMessage
            id="rhythm.switches.summary"
            values={{ on, total: killSwitches.length }}
          />
        ) : undefined
      }
      actions={
        <Button variant="ghost" size="sm" onClick={() => navigate('features')}>
          <ExternalLink />
          <FormattedMessage id="rhythm.switches.open" />
        </Button>
      }
    >
      <KillSwitchList flags={flags} />
    </Section>
  );
}

export function KillSwitchList({ flags }: { flags: Flags | null }) {
  return (
    <div className="grid gap-4">
      <ul className="grid gap-3">
        {killSwitches.map((k) => {
          const f = flags?.[k];
          return (
            <li
              key={k}
              className="grid gap-1 sm:grid-cols-[minmax(0,16rem)_minmax(0,1fr)] sm:gap-4"
            >
              <span className="text-sm font-medium">
                <FormattedMessage id={`flag.${k}`} />
              </span>
              <span className="grid gap-0.5">
                {!f ? (
                  <span className="text-sm text-muted-foreground">—</span>
                ) : (
                  <span className="flex flex-wrap items-center gap-2">
                    <Pill tone={f.enabled ? 'ok' : 'muted'}>
                      <FormattedMessage id={f.enabled ? 'rhythm.switch.on' : 'rhythm.switch.off'} />
                    </Pill>
                    {f.enabled && (
                      <span className="text-sm text-muted-foreground">
                        <FormattedMessage
                          id={`scope.${f.scope}`}
                          values={{ p: f.scope === 'all' ? 100 : f.percent }}
                        />
                      </span>
                    )}
                  </span>
                )}
                <span className="text-xs text-muted-foreground">
                  <FormattedMessage id={`flag.${k}.offEffect`} />
                </span>
              </span>
            </li>
          );
        })}
      </ul>
      <LockNote>
        <FormattedMessage id="rhythm.switches.note" />
      </LockNote>
    </div>
  );
}

// ---------- Tab 2: Hoạt động & thẻ theo tuổi (PN03) ----------

type Selected = { kind: 'activity' | 'ageCard'; index: number } | null;

/** "~0–3 tháng" for long ranges, "7–13 ngày" for short ones; the full range on hover. */
function AgeText({ age }: { age: { from: number; to: number } }) {
  const intl = useIntl();
  const full = intl.formatMessage(
    { id: 'rhythm.ageDays' },
    { from: age.from, to: age.to, mFrom: monthsOf(age.from), mTo: monthsOf(age.to) },
  );
  const short =
    age.to - age.from < 31
      ? intl.formatMessage({ id: 'rhythm.ageShort.days' }, { from: age.from, to: age.to })
      : intl.formatMessage(
          { id: 'rhythm.ageShort.months' },
          { from: monthsOf(age.from), to: monthsOf(age.to) },
        );
  return (
    <span title={full} className="tabular-nums">
      {short}
    </span>
  );
}

function ItemReview({ review }: { review: RhythmReview }) {
  return review ? (
    <span className="text-muted-foreground">
      <ReviewText review={review} />
    </span>
  ) : (
    <Pill tone="warn">
      <FormattedMessage id="rhythm.awaitingExpert" />
    </Pill>
  );
}

type ReviewFilter = 'all' | 'reviewed' | 'awaiting';
type StatusFilter = 'all' | Activity['status'];
export interface ItemFilter {
  query: string;
  need: 'all' | Need;
  status: StatusFilter;
  review: ReviewFilter;
}
const noFilter: ItemFilter = { query: '', need: 'all', status: 'all', review: 'all' };
const filterOn = (f: ItemFilter) =>
  !!f.query.trim() || f.need !== 'all' || f.status !== 'all' || f.review !== 'all';

const reviewPass = (f: ItemFilter, review: RhythmReview) =>
  f.review === 'all' || (f.review === 'reviewed') === !!review;

/** The activities the filter keeps, as indices into the pack (the order the table shows). */
export function filterActivities(items: Activity[], f: ItemFilter): number[] {
  return items.flatMap((a, i) =>
    matches(f.query, a.title.vi, a.title.en, a.id) &&
    (f.need === 'all' || a.needs.includes(f.need)) &&
    (f.status === 'all' || a.status === f.status) &&
    reviewPass(f, a.review)
      ? [i]
      : [],
  );
}

export function filterAgeCards(items: AgeCard[], f: ItemFilter): number[] {
  return items.flatMap((c, i) =>
    matches(f.query, c.title.vi, c.title.en, c.id) &&
    (f.status === 'all' || c.status === f.status) &&
    reviewPass(f, c.review)
      ? [i]
      : [],
  );
}

function ContentTabView({
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
  onStop: (then?: () => void) => void;
  onSave: () => void;
  onAct: (act: Act, versionId: string) => void;
}) {
  const intl = useIntl();
  const doc = view.content;
  const editing = working.editing;
  const [sub, setSub] = useState<ContentTab>('activities');
  const [selected, setSelected] = useState<Selected>(null);
  const [actFilter, setActFilter] = useState<ItemFilter>(noFilter);
  const [cardFilter, setCardFilter] = useState<ItemFilter>(noFilter);
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
  const actOrder = shown ? filterActivities(shown.activities, actFilter) : [];
  const cardOrder = shown ? filterAgeCards(shown.ageCards, cardFilter) : [];
  const viewingDraft = !editing && showDraft && !!doc.draft;
  return (
    <>
      {editing ? (
        <EditingBar
          doc="content"
          docView={doc}
          working={working}
          canEdit={canEdit}
          onSave={onSave}
          onStop={() => onStop(() => open(null))}
          onAct={onAct}
        />
      ) : (
        <DocStatus
          doc="content"
          docView={doc}
          size={size}
          stat={r ? intl.formatMessage({ id: 'rhythm.reviewedCount' }, r) : ''}
          canEdit={canEdit}
          canApprove={canApprove}
          showDraft={showDraft}
          onToggleDraft={onToggleDraft}
          onEdit={onStart}
          onAct={onAct}
        />
      )}
      {editing && (
        <IssuesNotice
          check={check}
          show={working.showIssues}
          place={(i) => {
            const [head, at] = i.path;
            if ((head === 'activities' || head === 'ageCards') && typeof at === 'number') {
              const x = head === 'activities' ? editing.activities[at] : editing.ageCards[at];
              const name = x ? textOf(intl, x.title) || x.id : `#${at + 1}`;
              return i.path.length > 2 ? `${name} · ${fieldPath(intl, i.path, 2)}` : name;
            }
            return fieldPath(intl, i.path) || '—';
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
        />
      )}

      {!shown ? (
        <Section title={<FormattedMessage id="rhythm.tab.content" />}>
          <EmptyState title={<FormattedMessage id="rhythm.empty" />}>
            {canEdit && <FormattedMessage id="rhythm.emptyEdit" />}
          </EmptyState>
        </Section>
      ) : item && selected ? (
        <>
          <ItemNav
            backLabel={<FormattedMessage id={`rhythm.back.${selected.kind}`} />}
            title={textOf(intl, item.title) || item.id}
            meta={`${item.id} · v${item.version}`}
            badges={
              <Pill tone={itemTone[item.status] ?? 'muted'}>
                <FormattedMessage id={`rhythm.itemStatus.${item.status}`} />
              </Pill>
            }
            index={selected.index}
            order={
              selected.kind === 'activity'
                ? actOrder.includes(selected.index)
                  ? actOrder
                  : shown.activities.map((_, i) => i)
                : cardOrder.includes(selected.index)
                  ? cardOrder
                  : shown.ageCards.map((_, i) => i)
            }
            onBack={() => open(null)}
            onGo={(index) => open({ kind: selected.kind, index })}
          />
          <EditorLayout
            aside={
              editing ? (
                selected.kind === 'activity' ? (
                  <ActivityPreview a={item as Activity} />
                ) : (
                  <AgeCardPreview c={item as AgeCard} />
                )
              ) : undefined
            }
          >
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
          </EditorLayout>
        </>
      ) : (
        <Tabs value={sub} onValueChange={(v) => setSub(v as ContentTab)} className="gap-3">
          <TabsList variant="line" aria-label={intl.formatMessage({ id: 'rhythm.tab.content' })}>
            {contentTabs.map((t) => (
              <TabsTrigger key={t} value={t} className="px-3">
                <FormattedMessage id={`rhythm.sub.${t}`} />
              </TabsTrigger>
            ))}
          </TabsList>
          <TabsContent value="activities">
            <ActivitiesTable
              data={shown}
              viewingDraft={viewingDraft}
              filter={actFilter}
              onFilter={setActFilter}
              order={actOrder}
              editing={editing ? working.edit : null}
              check={working.showIssues ? check : null}
              onOpen={(index) => open({ kind: 'activity', index })}
              onAdd={() => {
                if (!editing) return;
                working.edit((d) => void d.activities.push(blankActivity(d.activities)));
                setActFilter(noFilter);
                open({ kind: 'activity', index: editing.activities.length });
              }}
            />
          </TabsContent>
          <TabsContent value="ageCards">
            <AgeCardsTable
              data={shown}
              viewingDraft={viewingDraft}
              filter={cardFilter}
              onFilter={setCardFilter}
              order={cardOrder}
              editing={editing ? working.edit : null}
              check={working.showIssues ? check : null}
              onOpen={(index) => open({ kind: 'ageCard', index })}
              onAdd={() => {
                if (!editing) return;
                working.edit((d) => void d.ageCards.push(blankAgeCard(d.ageCards)));
                setCardFilter(noFilter);
                open({ kind: 'ageCard', index: editing.ageCards.length });
              }}
            />
          </TabsContent>
          <TabsContent value="health" className="grid grid-cols-1 gap-4">
            {editing ? (
              <HealthEditor data={editing} edit={working.edit} />
            ) : (
              <Section
                title={
                  <>
                    <FormattedMessage id="rhythm.health" />
                    <Pill tone="info">
                      <FormattedMessage id="rhythm.health.free" />
                    </Pill>
                  </>
                }
                hint={<FormattedMessage id="rhythm.health.note" />}
              >
                <HealthSummary health={shown.health} />
              </Section>
            )}
          </TabsContent>
        </Tabs>
      )}

      <HistorySection
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
  const { ask, dialog } = useConfirm();
  return (
    <>
      <RowActions
        label={intl.formatMessage({ id: 'table.actionsFor' }, { name })}
        actions={[
          {
            key: 'remove',
            destructive: true,
            label: <FormattedMessage id="rhythm.remove" />,
            onSelect: () =>
              ask({
                title: <FormattedMessage id="rhythm.removeConfirm" values={{ name }} />,
                confirmLabel: <FormattedMessage id="rhythm.remove" />,
                destructive: true,
                onConfirm: () => editing((d) => void list(d).splice(index, 1)),
              }),
          },
        ]}
      />
      {dialog}
    </>
  );
}

/** Search, need, status and review filters over a list. */
function ItemFilters({
  filter,
  onFilter,
  withNeed,
  shown,
  total,
  placeholder,
}: {
  filter: ItemFilter;
  onFilter: (f: ItemFilter) => void;
  withNeed?: boolean;
  shown: number;
  total: number;
  placeholder: string;
}) {
  const intl = useIntl();
  const t = (id: string) => intl.formatMessage({ id });
  return (
    <FilterBar
      active={filterOn(filter)}
      onClear={() => onFilter(noFilter)}
      shown={shown}
      total={total}
    >
      <SearchInput
        value={filter.query}
        onChange={(query) => onFilter({ ...filter, query })}
        placeholder={placeholder}
      />
      {withNeed && (
        <SelectMenu
          label={t('rhythm.filter.need')}
          value={filter.need}
          onChange={(need) => onFilter({ ...filter, need })}
          options={[
            { value: 'all' as const, label: t('rhythm.filter.allNeeds') },
            ...needs.map((n) => ({ value: n, label: t(`rhythm.need.${n}`) })),
          ]}
        />
      )}
      <SelectMenu
        label={t('rhythm.filter.status')}
        value={filter.status}
        onChange={(status) => onFilter({ ...filter, status })}
        options={[
          { value: 'all' as const, label: t('rhythm.filter.allStatuses') },
          ...(['published', 'draft', 'retired'] as const).map((s) => ({
            value: s,
            label: t(`rhythm.itemStatus.${s}`),
          })),
        ]}
      />
      <SelectMenu
        label={t('rhythm.filter.review')}
        value={filter.review}
        onChange={(review) => onFilter({ ...filter, review })}
        options={(['all', 'awaiting', 'reviewed'] as const).map((v) => ({
          value: v,
          label: t(`rhythm.filter.review.${v}`),
        }))}
      />
    </FilterBar>
  );
}

function NoMatch({ onClear }: { onClear: () => void }) {
  return (
    <EmptyState
      title={<FormattedMessage id="rhythm.noMatch" />}
      action={
        <Button variant="outline" size="sm" onClick={onClear}>
          <FormattedMessage id="kit.clearFilters" />
        </Button>
      }
    />
  );
}

export function ActivitiesTable({
  data,
  viewingDraft,
  filter,
  onFilter,
  order,
  editing,
  check,
  onOpen,
  onAdd,
}: {
  data: ContentDraftData;
  viewingDraft?: boolean;
  filter: ItemFilter;
  onFilter: (f: ItemFilter) => void;
  /** Indices of the activities the filter keeps. */
  order: number[];
  editing: Edit<ContentDraftData> | null;
  check: Check | null;
  onOpen: (i: number) => void;
  onAdd: () => void;
}) {
  const intl = useIntl();
  const problems = rowProblems(check, 'activities');
  return (
    <Section
      flush
      title={
        <>
          <FormattedMessage id="rhythm.activities" values={{ n: data.activities.length }} />
          {viewingDraft && (
            <Pill tone="wait">
              <FormattedMessage id="rhythm.viewingDraft" />
            </Pill>
          )}
        </>
      }
      hint={<FormattedMessage id="rhythm.activitiesNote" />}
      actions={
        editing ? (
          <Button
            variant="outline"
            size="sm"
            disabled={data.activities.length >= 300}
            onClick={onAdd}
          >
            <Plus />
            <FormattedMessage id="rhythm.addActivity" />
          </Button>
        ) : undefined
      }
    >
      {data.activities.length > 0 && (
        <ItemFilters
          filter={filter}
          onFilter={onFilter}
          withNeed
          shown={order.length}
          total={data.activities.length}
          placeholder={intl.formatMessage({ id: 'rhythm.search.activities' })}
        />
      )}
      {data.activities.length === 0 ? (
        <EmptyState title={<FormattedMessage id="rhythm.noActivities" />} />
      ) : order.length === 0 ? (
        <NoMatch onClear={() => onFilter(noFilter)} />
      ) : (
        <TableScroll min={900}>
          <table className="table">
            <thead>
              <tr>
                {(['activity', 'age', 'needs', 'status', 'review', 'locales'] as const).map((c) => (
                  <th key={c}>
                    <FormattedMessage id={`rhythm.itemCol.${c}`} />
                  </th>
                ))}
                {editing && <th className="w-12" />}
              </tr>
            </thead>
            <tbody>
              {order.map((i) => {
                const a = data.activities[i]!;
                const name = textOf(intl, a.title) || a.id;
                return (
                  <tr key={`${i}-${a.id}`} className="cursor-pointer" onClick={() => onOpen(i)}>
                    <td className="w-full max-w-0">
                      <RowTitle onOpen={() => onOpen(i)}>{name}</RowTitle>
                      <span className="block truncate text-xs text-muted-foreground">
                        <FormattedMessage id="rhythm.minutes" values={{ n: a.durationMin }} />
                        {' · '}
                        <FormattedMessage id={`rhythm.timeOfDay.${a.timeOfDay}`} />
                      </span>
                    </td>
                    <td className="nowrap">
                      <AgeText age={a.ageDays} />
                    </td>
                    <td>
                      <span className="block max-w-44 truncate">
                        {a.needs
                          .map((n) => intl.formatMessage({ id: `rhythm.need.${n}` }))
                          .join(' · ')}
                      </span>
                    </td>
                    <td>
                      <span className="flex flex-wrap gap-1">
                        <Pill tone={itemTone[a.status] ?? 'muted'}>
                          <FormattedMessage id={`rhythm.itemStatus.${a.status}`} />
                        </Pill>
                        {problems.has(i) && (
                          <Pill tone="error">
                            <FormattedMessage
                              id="rhythm.badge.issues"
                              values={{ n: problems.get(i) }}
                            />
                          </Pill>
                        )}
                      </span>
                    </td>
                    <td>
                      <span className="block max-w-52 truncate">
                        <ItemReview review={a.review} />
                      </span>
                    </td>
                    <td className="nowrap text-muted-foreground">
                      {a.locales.map((l) => l.toUpperCase()).join(' · ')}
                    </td>
                    {editing && (
                      <td className="cell-actions" onClick={(e) => e.stopPropagation()}>
                        <RemoveAction
                          name={name}
                          index={i}
                          editing={editing}
                          list={(d) => d.activities}
                        />
                      </td>
                    )}
                  </tr>
                );
              })}
            </tbody>
          </table>
        </TableScroll>
      )}
    </Section>
  );
}

export function AgeCardsTable({
  data,
  viewingDraft,
  filter,
  onFilter,
  order,
  editing,
  check,
  onOpen,
  onAdd,
}: {
  data: ContentDraftData;
  viewingDraft?: boolean;
  filter: ItemFilter;
  onFilter: (f: ItemFilter) => void;
  order: number[];
  editing: Edit<ContentDraftData> | null;
  check: Check | null;
  onOpen: (i: number) => void;
  onAdd: () => void;
}) {
  const intl = useIntl();
  const problems = rowProblems(check, 'ageCards');
  return (
    <Section
      flush
      title={
        <>
          <FormattedMessage id="rhythm.ageCards" values={{ n: data.ageCards.length }} />
          {viewingDraft && (
            <Pill tone="wait">
              <FormattedMessage id="rhythm.viewingDraft" />
            </Pill>
          )}
        </>
      }
      hint={<FormattedMessage id="rhythm.ageCardsNote" />}
      actions={
        editing ? (
          <Button
            variant="outline"
            size="sm"
            disabled={data.ageCards.length >= 200}
            onClick={onAdd}
          >
            <Plus />
            <FormattedMessage id="rhythm.addAgeCard" />
          </Button>
        ) : undefined
      }
    >
      {data.ageCards.length > 0 && (
        <ItemFilters
          filter={filter}
          onFilter={onFilter}
          shown={order.length}
          total={data.ageCards.length}
          placeholder={intl.formatMessage({ id: 'rhythm.search.ageCards' })}
        />
      )}
      {data.ageCards.length === 0 ? (
        <EmptyState title={<FormattedMessage id="rhythm.noAgeCards" />} />
      ) : order.length === 0 ? (
        <NoMatch onClear={() => onFilter(noFilter)} />
      ) : (
        <TableScroll min={760}>
          <table className="table">
            <thead>
              <tr>
                {(['age', 'title', 'status', 'review'] as const).map((c) => (
                  <th key={c}>
                    <FormattedMessage id={`rhythm.itemCol.${c}`} />
                  </th>
                ))}
                {editing && <th className="w-12" />}
              </tr>
            </thead>
            <tbody>
              {order.map((i) => {
                const c = data.ageCards[i]!;
                const name = textOf(intl, c.title) || c.id;
                return (
                  <tr key={`${i}-${c.id}`} className="cursor-pointer" onClick={() => onOpen(i)}>
                    <td className="nowrap">
                      <AgeText age={c.ageDays} />
                    </td>
                    <td className="w-full max-w-0">
                      <RowTitle onOpen={() => onOpen(i)}>{name}</RowTitle>
                      <span className="block truncate text-xs text-muted-foreground">
                        {textOf(intl, c.body)}
                      </span>
                    </td>
                    <td>
                      <span className="flex flex-wrap gap-1">
                        <Pill tone={itemTone[c.status] ?? 'muted'}>
                          <FormattedMessage id={`rhythm.itemStatus.${c.status}`} />
                        </Pill>
                        {problems.has(i) && (
                          <Pill tone="error">
                            <FormattedMessage
                              id="rhythm.badge.issues"
                              values={{ n: problems.get(i) }}
                            />
                          </Pill>
                        )}
                      </span>
                    </td>
                    <td>
                      <span className="block max-w-52 truncate">
                        <ItemReview review={c.review} />
                      </span>
                    </td>
                    {editing && (
                      <td className="cell-actions" onClick={(e) => e.stopPropagation()}>
                        <RemoveAction
                          name={name}
                          index={i}
                          editing={editing}
                          list={(d) => d.ageCards}
                        />
                      </td>
                    )}
                  </tr>
                );
              })}
            </tbody>
          </table>
        </TableScroll>
      )}
    </Section>
  );
}

function ReviewAndSources({
  review,
  sources,
}: {
  review: RhythmReview;
  sources: Array<{ label: string; url: string }>;
}) {
  return (
    <Section title={<FormattedMessage id="rhythm.section.reviewSources" />}>
      <Rows>
        <Row label={<FormattedMessage id="rhythm.itemCol.review" />}>
          <ItemReview review={review} />
        </Row>
        <Row label={<FormattedMessage id="rhythm.field.sources" />}>
          <Sources list={sources} />
        </Row>
      </Rows>
    </Section>
  );
}

function ActivitySummary({ a }: { a: Activity }) {
  const intl = useIntl();
  return (
    <>
      <Section title={<FormattedMessage id="rhythm.section.basics" />}>
        <BothLangs
          render={(lang) => (
            <>
              <p className="font-semibold">{a.title[lang] || '—'}</p>
              <p className="text-sm">{a.summary[lang] || '—'}</p>
              <Labeled label={<FormattedMessage id="rhythm.field.steps" />}>
                <Bullets items={a.steps[lang]} ordered />
              </Labeled>
              <Labeled label={<FormattedMessage id="rhythm.field.safety" />}>
                {a.safety?.[lang] || <span className="text-muted-foreground">—</span>}
              </Labeled>
            </>
          )}
        />
      </Section>
      <Section title={<FormattedMessage id="rhythm.section.when" />}>
        <Rows>
          <Row label={<FormattedMessage id="rhythm.itemCol.age" />}>
            <FormattedMessage
              id="rhythm.ageDays"
              values={{
                from: a.ageDays.from,
                to: a.ageDays.to,
                mFrom: monthsOf(a.ageDays.from),
                mTo: monthsOf(a.ageDays.to),
              }}
            />
          </Row>
          <Row label={<FormattedMessage id="rhythm.field.duration" />}>
            <FormattedMessage id="rhythm.minutes" values={{ n: a.durationMin }} />
            {' · '}
            <FormattedMessage id={`rhythm.timeOfDay.${a.timeOfDay}`} />
          </Row>
          <Row label={<FormattedMessage id="rhythm.field.needs" />}>
            {a.needs.map((n) => intl.formatMessage({ id: `rhythm.need.${n}` })).join(' · ')}
          </Row>
          <Row label={<FormattedMessage id="rhythm.field.interests" />}>
            {a.interests
              .map((n) => intl.formatMessage({ id: `rhythm.interest.${n}` }))
              .join(' · ') || '—'}
          </Row>
          <Row label={<FormattedMessage id="rhythm.field.locales" />}>
            {a.locales.map((l) => l.toUpperCase()).join(' · ')}
          </Row>
          <Row label={<FormattedMessage id="rhythm.field.regions" />}>
            {a.regions.join(', ') || <FormattedMessage id="rhythm.allRegions" />}
          </Row>
        </Rows>
      </Section>
      <ReviewAndSources review={a.review} sources={a.sources} />
    </>
  );
}

function AgeCardSummary({ c }: { c: AgeCard }) {
  const intl = useIntl();
  return (
    <>
      <Section
        title={<FormattedMessage id="rhythm.section.basics" />}
        actions={
          <span className="text-sm text-muted-foreground tabular-nums">
            <FormattedMessage
              id="rhythm.ageDays"
              values={{
                from: c.ageDays.from,
                to: c.ageDays.to,
                mFrom: monthsOf(c.ageDays.from),
                mTo: monthsOf(c.ageDays.to),
              }}
            />
          </span>
        }
      >
        <BothLangs
          render={(lang) => (
            <>
              <p className="font-semibold">{c.title[lang] || '—'}</p>
              <p className="text-sm">{c.body[lang] || '—'}</p>
              <Labeled label={<FormattedMessage id="rhythm.field.tips" />}>
                <Bullets items={c.tips[lang]} />
              </Labeled>
              <Labeled label={<FormattedMessage id="rhythm.field.watchFor" />}>
                <Bullets items={c.watchFor[lang]} />
              </Labeled>
            </>
          )}
        />
        <p className="mt-4 text-sm text-muted-foreground">
          <FormattedMessage id="rhythm.field.interests" />
          {': '}
          {c.interests.map((n) => intl.formatMessage({ id: `rhythm.interest.${n}` })).join(' · ') ||
            '—'}
        </p>
      </Section>
      <ReviewAndSources review={c.review} sources={c.sources} />
    </>
  );
}

/** How the item reads in the app, in one language at a time. */
function PreviewCard({
  children,
  onLang,
  lang,
}: {
  children: ReactNode;
  lang: Lang;
  onLang: (l: Lang) => void;
}) {
  return (
    <Section
      title={<FormattedMessage id="rhythm.preview" />}
      actions={<LangSwitch value={lang} onChange={onLang} />}
    >
      <div className="grid gap-3 rounded-xl border bg-background p-4 text-sm shadow-xs">
        {children}
      </div>
    </Section>
  );
}

function ActivityPreview({ a }: { a: Activity }) {
  const [lang, setLang] = useState<Lang>('vi');
  return (
    <PreviewCard lang={lang} onLang={setLang}>
      <div className="flex flex-wrap items-center gap-2">
        <Pill tone="info">
          <FormattedMessage id="rhythm.minutes" values={{ n: a.durationMin }} />
        </Pill>
        <span className="text-xs text-muted-foreground">
          <FormattedMessage id={`rhythm.timeOfDay.${a.timeOfDay}`} />
        </span>
      </div>
      <p className="text-base font-semibold">{a.title[lang] || '—'}</p>
      {a.summary[lang] && <p className="text-muted-foreground">{a.summary[lang]}</p>}
      {a.steps[lang].length > 0 && <Bullets items={a.steps[lang]} ordered />}
      {a.safety?.[lang] && (
        <p className="rounded-lg bg-warning/10 px-3 py-2 text-[13px]">{a.safety[lang]}</p>
      )}
    </PreviewCard>
  );
}

function AgeCardPreview({ c }: { c: AgeCard }) {
  const [lang, setLang] = useState<Lang>('vi');
  return (
    <PreviewCard lang={lang} onLang={setLang}>
      <span className="text-xs text-muted-foreground">
        <AgeText age={c.ageDays} />
      </span>
      <p className="text-base font-semibold">{c.title[lang] || '—'}</p>
      {c.body[lang] && <p className="text-muted-foreground">{c.body[lang]}</p>}
      {c.tips[lang].length > 0 && <Bullets items={c.tips[lang]} />}
      {c.watchFor[lang].length > 0 && (
        <div className="rounded-lg bg-muted/60 px-3 py-2">
          <p className="mb-1 text-[13px] font-medium">
            <FormattedMessage id="rhythm.field.watchFor" />
          </p>
          <Bullets items={c.watchFor[lang]} />
        </div>
      )}
    </PreviewCard>
  );
}

function HealthSummary({ health: h }: { health: ContentDraftData['health'] }) {
  const intl = useIntl();
  return (
    <Rows>
      <Row
        label={
          <FormattedMessage id="rhythm.health.signs" values={{ n: h.signs.length, max: 20 }} />
        }
      >
        <ul className="grid list-disc gap-1 pl-5">
          {h.signs.map((s) => (
            <li key={s.id}>
              {textOf(intl, s.label)}{' '}
              {s.maxAgeDays !== null && (
                <span className="text-muted-foreground">
                  <FormattedMessage id="rhythm.health.under" values={{ n: s.maxAgeDays }} />
                </span>
              )}
            </li>
          ))}
        </ul>
      </Row>
      <Row label={<FormattedMessage id="rhythm.field.whileWaiting" />}>
        <Bullets items={intl.locale.startsWith('vi') ? h.whileWaiting.vi : h.whileWaiting.en} />
      </Row>
      <Row label={<FormattedMessage id="rhythm.field.disclaimer" />}>
        {textOf(intl, h.disclaimer) || '—'}
      </Row>
      <Row label={<FormattedMessage id="rhythm.health.regions" values={{ n: h.regions.length }} />}>
        <span className="tabular-nums">
          {h.regions.map((r) => `${r.country} (${r.emergencyNumber})`).join(' · ') || '—'}
        </span>
        <span className="block text-xs text-muted-foreground">
          <FormattedMessage id="rhythm.health.otherRegions" />
        </span>
      </Row>
      <Row label={<FormattedMessage id="rhythm.itemCol.review" />}>
        <ItemReview review={h.review} />
      </Row>
      <Row label={<FormattedMessage id="rhythm.field.sources" />}>
        <Sources list={h.sources} />
      </Row>
    </Rows>
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
        <Section title={<FormattedMessage id="rhythm.rules" />}>
          <LockNote>
            <FormattedMessage id="rhythm.rules.noAccess" />
          </LockNote>
        </Section>
      ) : rules === undefined ? (
        <RulesLoader canEdit={canEdit} />
      ) : rules ? (
        <RulesPanel view={rules} canEdit={canEdit} onSaved={() => undefined} />
      ) : null}
      <Section
        title={<FormattedMessage id="rhythm.ranking" />}
        collapsible
        defaultOpen={false}
        summary={<span className="font-mono text-xs">{rankingWeights.version}</span>}
      >
        <RankingDetails />
      </Section>
      <Section
        title={<FormattedMessage id="rhythm.health.routing" />}
        collapsible
        defaultOpen={false}
        summary={<FormattedMessage id="rhythm.health.first" />}
      >
        <HealthRoutingDetails content={content} />
      </Section>
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
    <dl className="grid gap-x-6 gap-y-2 rounded-lg bg-muted/50 p-4 text-sm sm:grid-cols-[minmax(0,9rem)_minmax(0,1fr)]">
      {(['baseline', 'validDay', 'change', 'repeat'] as const).map((k) => (
        <div key={k} className="contents">
          <dt className="font-medium">
            <FormattedMessage id={`rhythm.rules.summary.${k}`} />
          </dt>
          <dd className="text-muted-foreground">
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
        </div>
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
  useLeaveGuard(canEdit && dirty);
  const err = (key: string) => {
    const hit = issues.get(key);
    return hit ? ruleIssueText(intl, hit) : undefined;
  };
  const crossIssues = [...issues.values()].filter((i) => i.path.length <= 1);
  const defaults = JSON.stringify(rules) === JSON.stringify(defaultRhythmRules);
  return (
    <Section
      title={
        <>
          <FormattedMessage id="rhythm.rules" />
          <Pill tone="muted">{view.rules.version}</Pill>
        </>
      }
      description={
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
      hint={<FormattedMessage id="rhythm.rules.lead" />}
      actions={
        canEdit && !defaults ? (
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setRules({ ...defaultRhythmRules, version: rules.version })}
          >
            <FormattedMessage id="rhythm.rules.useDefaults" />
          </Button>
        ) : undefined
      }
    >
      <div className="grid gap-6">
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
            hint={<FormattedMessage id="rhythm.rules.versionHelp" />}
            className="sm:max-w-xs"
            onChange={(v) => setRules({ ...rules, version: v })}
          />
        )}
        {canEdit && err('version') && <p className="text-xs text-destructive">{err('version')}</p>}
        {ruleGroups.map((g) => (
          <div key={g.id} className="grid gap-3">
            <h3 className="text-sm font-semibold">
              <FormattedMessage id={`rhythm.rules.group.${g.id}`} />
            </h3>
            <div className="grid gap-x-6 gap-y-4 sm:grid-cols-2 xl:grid-cols-3">
              {g.keys.map((k) =>
                canEdit ? (
                  <div key={k} className="grid content-start gap-1">
                    <NumberInput
                      label={<FormattedMessage id={`rhythm.rule.${k}`} />}
                      value={rules[k]}
                      step={k === 'minDeltaShare' ? '0.01' : '1'}
                      path={[k]}
                      hint={<FormattedMessage id={`rhythm.rule.${k}.help`} />}
                      onChange={(v) => setRules({ ...rules, [k]: v ?? Number.NaN })}
                    />
                    {err(k) && <p className="text-xs text-destructive">{err(k)}</p>}
                  </div>
                ) : (
                  <div key={k} className="grid content-start gap-1">
                    <span className="flex min-h-5 items-center gap-1.5 text-[13px] font-medium text-muted-foreground">
                      <FormattedMessage id={`rhythm.rule.${k}`} />
                      <Hint>
                        <FormattedMessage id={`rhythm.rule.${k}.help`} />
                      </Hint>
                    </span>
                    <strong className="text-base tabular-nums">
                      {ruleValue(intl, k, rules[k])}
                    </strong>
                  </div>
                ),
              )}
            </div>
          </div>
        ))}
        {crossIssues.length > 0 && (
          <Notice tone="error">
            {crossIssues.map((i, k) => (
              <p key={k}>{ruleIssueText(intl, i)}</p>
            ))}
          </Notice>
        )}
      </div>
      {canEdit && (
        <div className="sticky bottom-0 z-10 -mx-5 mt-6 -mb-5 flex flex-wrap items-center gap-3 rounded-b-xl border-t bg-card/95 px-5 py-3 backdrop-blur supports-[backdrop-filter]:bg-card/80">
          <span
            className={cn(
              'flex items-center gap-1.5 text-[13px]',
              dirty ? 'text-warning' : 'text-muted-foreground',
            )}
            role="status"
          >
            {dirty && <span className="size-2 rounded-full bg-warning" aria-hidden="true" />}
            <FormattedMessage id={dirty ? 'kit.unsaved' : 'rhythm.rules.noChanges'} />
          </span>
          <div className="ml-auto flex items-center gap-2">
            {dirty && (
              <Button variant="ghost" onClick={() => setRules(view.rules)}>
                <FormattedMessage id="rhythm.rules.undo" />
              </Button>
            )}
            <Button disabled={!dirty || issues.size > 0} onClick={() => setSaving(true)}>
              <FormattedMessage id="rhythm.rules.save" />
            </Button>
          </div>
        </div>
      )}
      {saving && (
        <RulesDialog
          before={view.rules}
          rules={rules}
          onClose={() => setSaving(false)}
          onDone={onSaved}
        />
      )}
    </Section>
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
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const changed = (Object.keys(rules) as Array<keyof RhythmRules>).filter(
    (k) => rules[k] !== before[k],
  );
  return (
    <Modal title={<FormattedMessage id="rhythm.rules.saveTitle" />} onClose={onClose}>
      <p className="text-sm text-muted-foreground">
        <FormattedMessage id="rhythm.rules.saveNote" />
      </p>
      <dl className="grid gap-x-4 gap-y-1.5 rounded-lg bg-muted/50 p-3 text-sm sm:grid-cols-[minmax(0,1fr)_auto]">
        {changed.map((k) => (
          <div key={k} className="contents">
            <dt className="text-muted-foreground">
              <FormattedMessage
                id={k === 'version' ? 'rhythm.rules.version' : `rhythm.rule.${k}`}
              />
            </dt>
            <dd className="font-medium tabular-nums">
              {k === 'version'
                ? `${before.version} → ${rules.version}`
                : `${ruleValue(intl, k, before[k])} → ${ruleValue(intl, k, rules[k])}`}
            </dd>
          </div>
        ))}
      </dl>
      {error && (
        <Notice tone="error">
          <FormattedMessage id={errorMessageId(error)} />
        </Notice>
      )}
      <DialogActions>
        <Button variant="outline" onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button
          disabled={busy}
          onClick={() => {
            setBusy(true);
            setError(null);
            saveRhythmRules(api, rules)
              .then((res) => {
                if (!res.ok) throw new ApiError('invalid-argument', 'malformed');
                toast.success(intl.formatMessage({ id: 'rhythm.toast.rules' }));
                onClose();
                onDone();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id="rhythm.rules.save" />
        </Button>
      </DialogActions>
    </Modal>
  );
}

/** PN04 "Xếp hạng gợi ý": the weights ship with the app (`rankingWeights`), read-only here. */
export function RankingDetails() {
  const w = rankingWeights;
  return (
    <div className="grid gap-4">
      <Rows>
        <Row label={<FormattedMessage id="rhythm.ranking.filter" />}>
          <FormattedMessage id="rhythm.ranking.filter.value" />
        </Row>
        <Row label={<FormattedMessage id="rhythm.ranking.score" />}>
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
        </Row>
        <Row label={<FormattedMessage id="rhythm.ranking.tie" />}>
          <FormattedMessage id="rhythm.ranking.tie.value" />
        </Row>
      </Rows>
      <LockNote>
        <FormattedMessage id="rhythm.ranking.code" />
      </LockNote>
    </div>
  );
}

/** PN04 "Định tuyến sức khoẻ": always first, always free; edited in the content pack. */
export function HealthRoutingDetails({ content }: { content: RhythmContent | null }) {
  const intl = useIntl();
  const h = content?.health;
  return (
    <Rows>
      <Row label={<FormattedMessage id="rhythm.health.signsShort" />}>
        {h ? h.signs.map((s) => textOf(intl, s.label)).join(' · ') : '—'}
      </Row>
      <Row label={<FormattedMessage id="rhythm.health.action" />}>
        <FormattedMessage id="rhythm.health.action.value" />
      </Row>
      <Row label={<FormattedMessage id="rhythm.health.countries" />}>
        <span className="tabular-nums">
          {h?.regions.map((r) => `${r.country} (${r.emergencyNumber})`).join(' · ') || '—'}
        </span>
        <span className="block text-xs text-muted-foreground">
          <FormattedMessage id="rhythm.health.otherRegions" />
        </span>
      </Row>
      <Row label={<FormattedMessage id="rhythm.health.noAi" />}>
        <FormattedMessage id="rhythm.health.noAi.value" />
      </Row>
    </Rows>
  );
}
