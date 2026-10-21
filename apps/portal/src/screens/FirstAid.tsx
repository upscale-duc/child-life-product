import {
  firstAidImages,
  firstAidReviewSchema,
  staffCan,
  type FirstAidPack,
  type FirstAidSituation,
} from '@child-life/contracts';
import {
  ArrowDown,
  ArrowUp,
  Eye,
  LifeBuoy,
  LogOut,
  Pencil,
  Plus,
  SearchX,
  Trash2,
  Upload,
} from 'lucide-react';
import {
  useCallback,
  useContext,
  useEffect,
  useId,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { FormattedMessage, createIntl, useIntl, type IntlShape } from 'react-intl';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Textarea } from '@/components/ui/textarea';
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group';
import { TooltipProvider } from '@/components/ui/tooltip';
import { cn } from '@/lib/utils';
import {
  ApiError,
  useApi,
  useLoad,
  type FirstAidImage,
  type FirstAidVersion,
  type FirstAidView,
} from '../api';
import {
  EditorBar,
  EditorLayout,
  EmptyState,
  Field,
  FilterBar,
  HelpPopover,
  Notice,
  OverflowMenu,
  SearchInput,
  Section,
  useConfirm,
  useLeaveGuard,
  VersionBadge,
  type MenuItem,
} from '../content-kit';
import { routePaths, subPath, useStaff } from '../context';
import { ZONE } from '../format';
import { messages } from '../messages';
import {
  Loaded,
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
import {
  GeneralEditor,
  ImageGrid,
  ImageKindFilter,
  ImageThumb,
  IssuesContext,
  LibraryContext,
  SituationEditor,
  UploadBox,
  blankSituation,
  filterImages,
  issueText,
  moveItem,
  revealPath,
  saveFirstAidDraft,
  starterPack,
  validatePack,
  type Edit,
  type ImageFilter,
  type Issue,
} from './FirstAidEditor';

/**
 * Sơ cứu (D-058, P-141; app v1.1 7a–7i, TH01–TH24). The guide the app shows, edited here as one
 * pack: "Sửa" opens a working copy, "Lưu nháp" saves it as the one open version, "Gửi duyệt" hands
 * it to a different person with "Nội dung · Duyệt" (on prod an expert, who records the review),
 * and approval publishes it to `publicConfig/content_firstAid`. Every step is in the audit log
 * (no reason asked: D-090). "/first-aid/<situationId>" opens one situation with a phone preview.
 * Laid out with the content kit (D-063): the list first, the open draft as a notice with its next
 * step, history folded away; while editing, a sticky editor bar replaces the page header.
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
  if (load.status !== 'ok') {
    return (
      <Page title={<FormattedMessage id="firstAid.title" />}>
        <Loaded load={load} reload={reload}>
          {() => null}
        </Loaded>
      </Page>
    );
  }
  return (
    <FirstAidBody
      view={load.data}
      canEdit={staffCan(staff.levels, 'content.edit')}
      canApprove={staffCan(staff.levels, 'content.approve')}
      onChanged={reload}
    />
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
  const confirm = useConfirm();
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
  const issues = showIssues ? (check?.list ?? []) : [];

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
  useLeaveGuard(!!editing && dirty);

  const edit: Edit = useCallback((fn) => {
    setEditing((p) => {
      if (!p) return p;
      const next = structuredClone(p);
      fn(next);
      return next;
    });
    setDirty(true);
  }, []);

  /** Keeps the open situation (by id) when the pack on screen changes. */
  const follow = (pack: FirstAidPack | null) => {
    if (selected === null) return;
    const at = pack?.situations.findIndex((s) => s.id === selectedSituation?.id) ?? -1;
    if (at >= 0) setSelected(at);
    else open(null);
  };

  const startEditing = () => {
    const pack = structuredClone(d?.pack ?? view.current?.pack ?? starterPack());
    follow(pack);
    setEditing(pack);
    setShowDraft(!!d);
    setDirty(false);
    setShowIssues(false);
  };
  const leave = () => {
    follow(d?.pack ?? view.current?.pack ?? null);
    setEditing(null);
    setDirty(false);
    setShowIssues(false);
  };
  const stopEditing = () => {
    if (!dirty) return leave();
    confirm.ask({
      title: intl.formatMessage({ id: 'firstAid.leaveConfirm' }),
      body: <FormattedMessage id="firstAid.leaveConfirmNote" />,
      confirmLabel: <FormattedMessage id="kit.leaveConfirm" />,
      destructive: true,
      onConfirm: leave,
    });
  };
  const trySave = () => {
    setShowIssues(true);
    if (check?.ok) setDialog('save');
    else if (check) {
      toast.error(intl.formatMessage({ id: 'firstAid.issues' }, { n: check.list.length }));
    }
  };
  const askRemove = (i: number, after?: () => void) => {
    const s = shown?.situations[i];
    if (!s) return;
    confirm.ask({
      title: intl.formatMessage({ id: 'firstAid.removeConfirm' }, { name: s.title.vi || s.id }),
      body: <FormattedMessage id="firstAid.removeConfirmNote" />,
      confirmLabel: <FormattedMessage id="firstAid.remove" />,
      destructive: true,
      onConfirm: () => {
        edit((p) => {
          p.situations.splice(i, 1);
        });
        after?.();
      },
    });
  };
  /** From the issues summary to the field: the situation (and variant) or the settings tab. */
  const jump = (issue: Issue) => {
    const [head, at, key, v] = issue.path;
    if (head === 'situations' && typeof at === 'number') {
      setTab('situations');
      open(at);
      if (key === 'variants' && typeof v === 'number') setVariant(v);
    } else {
      open(null);
      setTab('general');
    }
    window.setTimeout(() => revealPath(issue.path), 80);
  };
  const addSituation = () => {
    if (!editing) return;
    const added = blankSituation(editing);
    edit((p) => {
      p.situations.push(structuredClone(added));
    });
    window.history.pushState({}, '', `${routePaths.firstAid}/${added.id}`);
    setSelected(editing.situations.length);
    setVariant(0);
    window.scrollTo?.(0, 0);
  };

  const liveIds = useMemo(
    () => new Set(view.current?.pack.situations.map((s) => s.id) ?? []),
    [view.current],
  );
  const saveLabel = <FormattedMessage id="firstAid.saveDraft" />;
  const editLabel = (
    <>
      <Pencil />
      <FormattedMessage id={d ? 'firstAid.editDraft' : 'firstAid.edit'} />
    </>
  );
  const issuesNotice = editing && issues.length > 0 && (
    <IssuesNotice issues={issues} pack={editing} onJump={jump} />
  );

  let screen: ReactNode;
  if (selectedSituation && selected !== null && shown) {
    // One situation: the editor (or a read-only summary) beside the phone preview.
    const n = shown.situations.length;
    const own = issues.filter((i) => i.path[0] === 'situations' && i.path[1] === selected);
    const menu: MenuItem[] = editing
      ? [
          {
            key: 'up',
            icon: ArrowUp,
            label: <FormattedMessage id="firstAid.moveUp" />,
            disabled: selected === 0,
            onSelect: () => {
              edit((p) => moveItem(p.situations, selected, -1));
              setSelected(selected - 1);
            },
          },
          {
            key: 'down',
            icon: ArrowDown,
            label: <FormattedMessage id="firstAid.moveDown" />,
            disabled: selected >= n - 1,
            onSelect: () => {
              edit((p) => moveItem(p.situations, selected, 1));
              setSelected(selected + 1);
            },
          },
          {
            key: 'exit',
            icon: LogOut,
            label: <FormattedMessage id="firstAid.stopEditing" />,
            onSelect: stopEditing,
          },
          {
            key: 'remove',
            icon: Trash2,
            destructive: true,
            disabled: n <= 1,
            label: <FormattedMessage id="firstAid.removeSituation" />,
            onSelect: () => askRemove(selected, () => open(null)),
          },
        ]
      : [];
    screen = (
      <>
        <EditorBar
          backLabel={<FormattedMessage id="firstAid.back" />}
          onBack={() => open(null)}
          title={
            [selectedSituation.code, textOf(intl, selectedSituation.title) || selectedSituation.id]
              .filter(Boolean)
              .join(' · ') || intl.formatMessage({ id: 'firstAid.untitled' })
          }
          badges={
            editing ? (
              own.length > 0 && (
                <Pill tone="warn">
                  <FormattedMessage id="firstAid.badge.issues" values={{ n: own.length }} />
                </Pill>
              )
            ) : (
              <VersionPill view={view} showDraft={showDraft} />
            )
          }
          dirty={editing ? dirty : undefined}
          onSave={editing ? trySave : undefined}
          saveLabel={saveLabel}
          actions={
            !editing && canEdit ? <Button onClick={startEditing}>{editLabel}</Button> : undefined
          }
          menu={editing ? menu : undefined}
        />
        <div className="grid gap-4">
          {issuesNotice}
          <EditorLayout
            aside={
              <PhonePreview
                pack={shown}
                situation={selectedSituation}
                variant={variant}
                onVariant={setVariant}
              />
            }
          >
            {editing ? (
              <SituationEditor
                pack={shown}
                index={selected}
                edit={edit}
                idLocked={liveIds.has(selectedSituation.id)}
                variant={variant}
                onVariant={setVariant}
              />
            ) : (
              <SituationSummary pack={shown} situation={selectedSituation} />
            )}
          </EditorLayout>
        </div>
      </>
    );
  } else {
    const content = !shown ? (
      <div className="rounded-xl border bg-card">
        <EmptyState icon={LifeBuoy} title={<FormattedMessage id="firstAid.notPublished" />}>
          <FormattedMessage id={canEdit ? 'firstAid.emptyEdit' : 'firstAid.empty'} />
        </EmptyState>
      </div>
    ) : (
      <Tabs value={tab} onValueChange={(t) => setTab(t as Tab)} className="gap-4">
        <TabsList aria-label={intl.formatMessage({ id: 'firstAid.title' })}>
          {(['situations', 'general', 'library'] as const).map((t) => (
            <TabsTrigger key={t} value={t} className="px-3">
              <FormattedMessage id={`firstAid.tab.${t}`} />
              {t !== 'general' && (
                <span className="text-xs text-muted-foreground tabular-nums">
                  {t === 'situations' ? shown.situations.length : images.length}
                </span>
              )}
            </TabsTrigger>
          ))}
        </TabsList>
        <TabsContent value="situations">
          <SituationList
            pack={shown}
            editing={!!editing}
            edit={edit}
            issues={issues}
            onOpen={open}
            onAdd={addSituation}
            onRemove={(i) => askRemove(i)}
          />
        </TabsContent>
        <TabsContent value="general">
          {editing ? <GeneralEditor pack={editing} edit={edit} /> : <GeneralSummary pack={shown} />}
        </TabsContent>
        <TabsContent value="library">
          <Library pack={shown} canUpload={canEdit} />
        </TabsContent>
      </Tabs>
    );
    const history = (
      <HistorySection
        view={view}
        canApprove={canApprove}
        onRollback={(versionId) => setDialog({ act: 'rollback', versionId })}
      />
    );
    screen = editing ? (
      <>
        <EditorBar
          backLabel={<FormattedMessage id="firstAid.stopEditing" />}
          onBack={stopEditing}
          title={<FormattedMessage id="firstAid.title" />}
          badges={
            d ? (
              <Pill tone={statusTone[d.status] ?? 'muted'}>
                <FormattedMessage id={`firstAid.status.${d.status}`} />
              </Pill>
            ) : (
              <Pill tone="muted">
                <FormattedMessage id="firstAid.newDraft" />
              </Pill>
            )
          }
          dirty={dirty}
          onSave={trySave}
          saveLabel={saveLabel}
          menu={
            d?.status === 'draft' && canEdit
              ? [
                  {
                    key: 'discard',
                    icon: Trash2,
                    destructive: true,
                    label: <FormattedMessage id="firstAid.act.discard" />,
                    onSelect: () => setDialog({ act: 'discard', versionId: d.versionId }),
                  },
                ]
              : undefined
          }
        />
        <div className="grid gap-4">
          {issuesNotice}
          {d?.status === 'pending' && (
            <Notice tone="warn">
              <FormattedMessage id="firstAid.editingPending" />
            </Notice>
          )}
          {d?.rejection && (
            <Notice tone="warn">
              <RejectedBy id="firstAid.rejected" by={d.rejection.by} reason={d.rejection.reason} />
            </Notice>
          )}
          {content}
          {history}
        </div>
      </>
    ) : (
      <Page
        title={<FormattedMessage id="firstAid.title" />}
        actions={
          <>
            <StatusLine view={view} />
            <HelpPopover title={<FormattedMessage id="firstAid.howTitle" />} wide>
              <ol className="grid list-decimal gap-1.5 pl-5 text-muted-foreground">
                {(['edit', 'save', 'submit', 'approve'] as const).map((k) => (
                  <li key={k}>
                    <FormattedMessage id={`firstAid.how.${k}`} />
                  </li>
                ))}
              </ol>
            </HelpPopover>
            {canEdit && <Button onClick={startEditing}>{editLabel}</Button>}
          </>
        }
      >
        <div className="grid gap-4">
          {d && (
            <DraftNotice
              draft={d}
              canEdit={canEdit}
              canApprove={canApprove}
              showDraft={showDraft}
              canToggle={!!view.current}
              onToggle={() => {
                // Keep the same situation open (by id) when switching between the two versions.
                follow(!showDraft ? d.pack : (view.current?.pack ?? null));
                setShowDraft(!showDraft);
              }}
              onAct={(act) => setDialog({ act, versionId: d.versionId })}
            />
          )}
          {content}
          {history}
        </div>
      </Page>
    );
  }

  return (
    <LibraryContext.Provider value={{ images, canUpload: canEdit, onUploaded }}>
      <IssuesContext.Provider value={{ issues: check?.issues ?? new Map(), show: showIssues }}>
        <TooltipProvider>{screen}</TooltipProvider>

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
        {confirm.dialog}
      </IssuesContext.Provider>
    </LibraryContext.Provider>
  );
}

// ---------- Status, the open draft, history ----------

/**
 * The version in use as a compact badge; when it was published, how many situations and who
 * reviewed it are in its popover (owner, 2026-10-21: no banner).
 */
function StatusLine({ view }: { view: FirstAidView }) {
  const intl = useIntl();
  const c = view.current;
  const review = c?.pack.review;
  return (
    <VersionBadge
      version={c?.version ?? null}
      details={
        c
          ? [
              intl.formatMessage(
                { id: 'firstAid.publishedAt' },
                { when: dateTime(intl, c.publishedAt), n: c.pack.situations.length },
              ),
              review
                ? intl.formatMessage(
                    { id: 'firstAid.reviewedBy' },
                    { name: review.reviewer, date: review.reviewedOn },
                  )
                : '',
            ]
          : []
      }
    />
  );
}

/** Which version a read-only page shows when there is an open draft. */
function VersionPill({ view, showDraft }: { view: FirstAidView; showDraft: boolean }) {
  const d = view.draft;
  if (!d) return null;
  return showDraft ? (
    <Pill tone={statusTone[d.status] ?? 'muted'}>
      <FormattedMessage id={`firstAid.status.${d.status}`} />
    </Pill>
  ) : (
    <Pill tone="ok">
      <FormattedMessage id="firstAid.status.published" />
    </Pill>
  );
}

/** The open draft's next step for this person, and what goes behind "⋯". */
export function draftActions(
  status: 'draft' | 'pending',
  canEdit: boolean,
  canApprove: boolean,
): { next: Act[]; more: Act[] } {
  if (status === 'draft') return canEdit ? { next: ['submit'], more: ['discard'] } : none;
  return canApprove ? { next: ['approve', 'reject'], more: [] } : none;
}
const none = { next: [] as Act[], more: [] as Act[] };

function DraftNotice({
  draft: d,
  canEdit,
  canApprove,
  showDraft,
  canToggle,
  onToggle,
  onAct,
}: {
  draft: NonNullable<FirstAidView['draft']>;
  canEdit: boolean;
  canApprove: boolean;
  showDraft: boolean;
  canToggle: boolean;
  onToggle: () => void;
  onAct: (act: Act) => void;
}) {
  const intl = useIntl();
  const { next, more } = draftActions(d.status, canEdit, canApprove);
  return (
    <Notice
      tone={d.rejection ? 'warn' : 'info'}
      title={
        <span className="flex flex-wrap items-center gap-2">
          <Pill tone={statusTone[d.status] ?? 'muted'}>
            <FormattedMessage id={`firstAid.status.${d.status}`} />
          </Pill>
          <FormattedMessage id="firstAid.openVersion" />
        </span>
      }
      action={
        <div className="flex flex-wrap items-center gap-2">
          {canToggle && (
            <Button variant="ghost" size="sm" onClick={onToggle}>
              <Eye />
              <FormattedMessage id={showDraft ? 'firstAid.showCurrent' : 'firstAid.showDraft'} />
            </Button>
          )}
          {next.map((a, k) => (
            <Button
              key={a}
              size="sm"
              variant={k === 0 ? 'default' : 'outline'}
              onClick={() => onAct(a)}
            >
              <FormattedMessage id={`firstAid.act.${a}`} />
            </Button>
          ))}
          <OverflowMenu
            items={more.map((a) => ({
              key: a,
              icon: a === 'discard' ? Trash2 : undefined,
              destructive: a === 'discard',
              label: intl.formatMessage({ id: `firstAid.act.${a}` }),
              onSelect: () => onAct(a),
            }))}
          />
        </div>
      }
    >
      <div className="grid gap-1">
        <p className="tabular-nums">
          <FormattedMessage
            id="firstAid.draftBy"
            values={{
              name: d.authorName || '—',
              when: dateTime(intl, d.updatedAt),
              n: d.pack.situations.length,
            }}
          />
        </p>
        {d.notes && (
          <p className="line-clamp-2 text-muted-foreground italic" title={d.notes}>
            “{d.notes}”
          </p>
        )}
        {d.rejection && (
          <p className="font-medium text-foreground">
            <RejectedBy id="firstAid.rejected" by={d.rejection.by} reason={d.rejection.reason} />
          </p>
        )}
        {d.status === 'pending' && (
          <p className="text-muted-foreground">
            <FormattedMessage id="firstAid.waitOther" />
          </p>
        )}
      </div>
    </Notice>
  );
}

/** The version in use is already live; any other published or replaced one can come back. */
export function canReuseVersion(view: FirstAidView, h: FirstAidVersion): boolean {
  return h.status === 'retired' || (h.status === 'published' && h.label !== view.current?.version);
}

function HistorySection({
  view,
  canApprove,
  onRollback,
}: {
  view: FirstAidView;
  canApprove: boolean;
  onRollback: (versionId: string) => void;
}) {
  const items = view.history.filter((h) => h.status !== 'draft' && h.status !== 'pending');
  if (!items.length) return null;
  return (
    <Section
      collapsible
      defaultOpen={false}
      flush
      title={<FormattedMessage id="firstAid.history" />}
      summary={<FormattedMessage id="firstAid.historyCount" values={{ n: items.length }} />}
    >
      <HistoryTable view={view} canApprove={canApprove} onRollback={onRollback} />
    </Section>
  );
}

export function HistoryTable({
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
  return (
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
            <th>
              <span className="sr-only">
                <FormattedMessage id="firstAid.col.actions" />
              </span>
            </th>
          </tr>
        </thead>
        <tbody>
          {items.map((h) => (
            <tr key={h.versionId}>
              <td className="font-mono text-[13px] whitespace-nowrap">{h.label ?? '—'}</td>
              <td>
                <Pill tone={statusTone[h.status] ?? 'muted'}>
                  <FormattedMessage id={`firstAid.status.${h.status}`} />
                </Pill>
              </td>
              <td className="tabular-nums">{h.situations}</td>
              <td className="whitespace-nowrap">
                <FormattedMessage
                  id="firstAid.historyBy"
                  values={{ author: h.authorName || '—', approver: h.approverName ?? '—' }}
                />
              </td>
              <td className="whitespace-nowrap tabular-nums">
                {dateTime(intl, h.approvedAt ?? h.updatedAt ?? h.createdAt)}
              </td>
              <td className="w-[28%] max-w-0">
                <span className="block truncate text-muted-foreground" title={h.notes || undefined}>
                  {h.notes || '—'}
                </span>
              </td>
              <td className="cell-actions w-10">
                {canApprove && canReuseVersion(view, h) && (
                  <RowActions
                    label={intl.formatMessage(
                      { id: 'table.actionsFor' },
                      { name: h.label ?? h.versionId },
                    )}
                    actions={[
                      {
                        key: 'rollback',
                        label: <FormattedMessage id="firstAid.act.rollback" />,
                        onSelect: () => onRollback(h.versionId),
                      },
                    ]}
                  />
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </TableScroll>
  );
}

// ---------- Review (approve on prod) ----------

export interface ReviewInput {
  reviewer: string;
  reviewedOn: string;
  sources: string;
}

/** The review the approver records; required when the server says so, else optional (all empty = none). */
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

/** Optional notes for a draft (what changed); not a reason. */
function NotesInput({
  value,
  onChange,
  label,
}: {
  value: string;
  onChange: (v: string) => void;
  label: ReactNode;
}) {
  const id = useId();
  return (
    <Field label={label} htmlFor={id}>
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

function DialogError({ error }: { error: ApiError | null }) {
  return error ? (
    <Notice tone="error">
      <FormattedMessage id={errorMessageId(error)} />
    </Notice>
  ) : null;
}

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
  const intl = useIntl();
  const id = useId();
  const [review, setReview] = useState<ReviewInput>({
    reviewer: initialReview?.reviewer ?? '',
    reviewedOn: initialReview?.reviewedOn ?? today(),
    sources: initialReview?.sources.join('\n') ?? '',
  });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const withReview = act === 'approve';
  const touched = !!(review.reviewer || review.sources);
  const checked = withReview
    ? reviewFrom(review, requireReview)
    : { ok: true as const, review: null };
  return (
    <Modal
      wide={withReview}
      title={<FormattedMessage id={`firstAid.confirm.${act}`} />}
      onClose={onClose}
    >
      <p className="text-sm text-muted-foreground">
        <FormattedMessage id={`firstAid.confirm.${act}.note`} />
      </p>
      {withReview && (
        <fieldset className="grid min-w-0 gap-4 rounded-lg border p-4">
          <legend className="px-1 text-[13px] font-semibold">
            <FormattedMessage
              id={requireReview ? 'firstAid.review.required' : 'firstAid.review.optional'}
            />
          </legend>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label={<FormattedMessage id="firstAid.review.reviewer" />} htmlFor={`${id}-r`}>
              <Input
                id={`${id}-r`}
                value={review.reviewer}
                maxLength={120}
                required={requireReview}
                onChange={(e) => setReview({ ...review, reviewer: e.target.value })}
              />
            </Field>
            <Field label={<FormattedMessage id="firstAid.review.reviewedOn" />} htmlFor={`${id}-d`}>
              <Input
                id={`${id}-d`}
                type="date"
                value={review.reviewedOn}
                required={requireReview}
                onChange={(e) => setReview({ ...review, reviewedOn: e.target.value })}
              />
            </Field>
          </div>
          <Field
            label={<FormattedMessage id="firstAid.review.sources" />}
            htmlFor={`${id}-s`}
            help={<FormattedMessage id="firstAid.review.sourcesHelp" />}
          >
            <Textarea
              id={`${id}-s`}
              rows={3}
              value={review.sources}
              required={requireReview}
              onChange={(e) => setReview({ ...review, sources: e.target.value })}
            />
          </Field>
          {!checked.ok && (
            <p className={touched ? 'text-sm text-destructive' : 'text-xs text-muted-foreground'}>
              <FormattedMessage id="firstAid.review.incomplete" />
            </p>
          )}
        </fieldset>
      )}
      <DialogError error={error} />
      <div className="flex flex-wrap justify-end gap-2">
        <Button variant="outline" onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button
          variant={act === 'discard' || act === 'reject' ? 'destructive' : 'default'}
          disabled={busy || !checked.ok}
          onClick={() => {
            if (!checked.ok) return;
            setBusy(true);
            setError(null);
            api
              .call('staffFirstAidAct', {
                versionId,
                action: act,
                review: checked.review,
              })
              .then(() => {
                toast.success(intl.formatMessage({ id: `firstAid.toast.${act}` }));
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

/** Field names for the issues summary; some depend on where they sit (a step's title). */
const fieldIds: Record<string, string> = {
  title: 'firstAid.field.title',
  lead: 'firstAid.field.lead',
  keywords: 'firstAid.field.keywords',
  icon: 'firstAid.field.icon',
  hero: 'firstAid.field.hero',
  category: 'firstAid.field.category',
  code: 'firstAid.field.code',
  id: 'firstAid.field.id',
  ageMonths: 'firstAid.field.ageMonths',
  variantKind: 'firstAid.field.variantKind',
  variants: 'firstAid.section.variants',
  tool: 'firstAid.field.tool',
  label: 'firstAid.field.variantLabel',
  banner: 'firstAid.field.banner',
  cpr: 'firstAid.field.cpr',
  steps: 'firstAid.place.steps',
  callouts: 'firstAid.place.callouts',
  body: 'firstAid.field.stepBody',
  image: 'firstAid.field.stepImage',
  count: 'firstAid.field.count',
  cprRole: 'firstAid.field.cprRole',
  chips: 'firstAid.field.chips',
  heading: 'firstAid.field.heading',
  items: 'firstAid.field.items',
  tone: 'firstAid.field.tone',
  emergencyNumber: 'firstAid.field.emergencyNumber',
  quickSearch: 'firstAid.field.quickSearch',
  categories: 'firstAid.section.categories',
  layout: 'firstAid.field.layout',
  from: 'firstAid.age.from',
  to: 'firstAid.age.to',
  vi: 'firstAid.lang.vi',
  en: 'firstAid.lang.en',
};
const scopedIds: Record<string, Record<string, string>> = {
  variant: {
    id: 'firstAid.field.variantId',
    hero: 'firstAid.field.variantHero',
    ageMonths: 'firstAid.field.variantAge',
  },
  step: { title: 'firstAid.field.stepTitle' },
  category: {
    id: 'firstAid.field.categoryId',
    title: 'firstAid.field.categoryTitle',
    tone: 'firstAid.field.categoryTone',
  },
};
const itemIds: Record<string, string> = {
  steps: 'firstAid.stepN',
  callouts: 'firstAid.place.callout',
  chips: 'firstAid.place.chip',
  items: 'firstAid.place.item',
  keywords: 'firstAid.place.keyword',
  quickSearch: 'firstAid.place.quickSearch',
};

/**
 * Where an issue sits, in words, for the summary
 * ("TH02 Hóc dị vật · Dưới 1 tuổi · Bước 1 · Số lần đếm (2–10)").
 */
export function issuePlace(intl: IntlShape, pack: FirstAidPack, issue: Issue): string {
  const f = (id: string, values?: Record<string, number>) => intl.formatMessage({ id }, values);
  const p = issue.path;
  const parts: string[] = [];
  let scope = 'pack';
  let situation: FirstAidSituation | undefined;
  let k = 0;
  if (p[0] === 'situations' && typeof p[1] === 'number') {
    situation = pack.situations[p[1]];
    parts.push(
      situation
        ? [situation.code, textOf(intl, situation.title) || situation.id].filter(Boolean).join(' ')
        : `#${p[1] + 1}`,
    );
    scope = 'situation';
    k = 2;
  }
  for (; k < p.length; k++) {
    const seg = p[k]!;
    const at = p[k + 1];
    if (typeof seg === 'string' && typeof at === 'number') {
      const n = at + 1;
      if (seg === 'variants') {
        parts.push(
          textOf(intl, situation?.variants[at]?.label) || f('firstAid.place.variant', { n }),
        );
        scope = 'variant';
      } else if (seg === 'categories') {
        parts.push(textOf(intl, pack.categories[at]?.title) || f('firstAid.place.category', { n }));
        scope = 'category';
      } else {
        parts.push(itemIds[seg] ? f(itemIds[seg], { n }) : `${seg} ${n}`);
        scope = seg === 'steps' ? 'step' : seg === 'chips' ? 'chip' : scope;
      }
      k++;
      continue;
    }
    if (typeof seg === 'number') {
      parts.push(`#${seg + 1}`);
      continue;
    }
    if (scope === 'chip' && seg === 'label') continue;
    const id = scopedIds[scope]?.[seg] ?? fieldIds[seg];
    parts.push(id ? f(id) : seg);
  }
  return parts.join(' · ') || '—';
}

/** "Còn n chỗ chưa hợp lệ": each one jumps to its field. */
function IssuesNotice({
  issues,
  pack,
  onJump,
}: {
  issues: Issue[];
  pack: FirstAidPack;
  onJump: (issue: Issue) => void;
}) {
  const intl = useIntl();
  const max = 12;
  return (
    <Notice
      tone="error"
      title={<FormattedMessage id="firstAid.issues" values={{ n: issues.length }} />}
    >
      <ul className="mt-1 grid max-h-48 gap-1 overflow-y-auto overscroll-contain">
        {issues.slice(0, max).map((i, k) => (
          <li key={k}>
            <button
              type="button"
              className="rounded-sm text-left underline-offset-2 outline-none hover:underline focus-visible:ring-[3px] focus-visible:ring-ring/50"
              onClick={() => onJump(i)}
            >
              <span className="font-medium">{issuePlace(intl, pack, i)}</span>
              {': '}
              {issueText(intl, i)}
            </button>
          </li>
        ))}
        {issues.length > max && (
          <li className="text-muted-foreground">
            <FormattedMessage id="firstAid.issuesMore" values={{ n: issues.length - max }} />
          </li>
        )}
      </ul>
    </Notice>
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
  const intl = useIntl();
  const [notes, setNotes] = useState(initialNotes);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  return (
    <Modal title={<FormattedMessage id="firstAid.saveTitle" />} onClose={onClose}>
      <p className="text-sm text-muted-foreground">
        <FormattedMessage id={pending ? 'firstAid.saveNotePending' : 'firstAid.saveNote'} />
      </p>
      <NotesInput
        value={notes}
        onChange={setNotes}
        label={<FormattedMessage id="firstAid.saveNotes" />}
      />
      <DialogError error={error} />
      <div className="flex flex-wrap justify-end gap-2">
        <Button variant="outline" onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button
          disabled={busy}
          onClick={() => {
            setBusy(true);
            setError(null);
            saveFirstAidDraft(api, pack, notes)
              .then((res) => {
                if (!res.ok) throw new ApiError('invalid-argument', 'malformed');
                toast.success(intl.formatMessage({ id: 'firstAid.toast.saved' }));
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

/** Lowercase without accents, so "duoi nuoc" finds "Đuối nước". */
const fold = (s: string) =>
  s.normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[đĐ]/g, 'd').toLowerCase();

type Flag = 'all' | 'emergency' | 'monitoring' | 'issues';

export function SituationList({
  pack,
  editing,
  edit,
  issues,
  onOpen,
  onAdd,
  onRemove,
}: {
  pack: FirstAidPack;
  editing: boolean;
  edit: Edit;
  issues: Issue[];
  onOpen: (i: number) => void;
  onAdd: () => void;
  onRemove: (i: number) => void;
}) {
  const intl = useIntl();
  const [query, setQuery] = useState('');
  const [group, setGroup] = useState('all');
  const [flag, setFlag] = useState<Flag>('all');
  const categories = new Map(pack.categories.map((c) => [c.id, c]));
  const problems = new Map<number, number>();
  for (const i of issues) {
    if (i.path[0] === 'situations' && typeof i.path[1] === 'number') {
      problems.set(i.path[1], (problems.get(i.path[1]) ?? 0) + 1);
    }
  }
  const q = fold(query.trim());
  const rows = pack.situations
    .map((s, i) => ({ s, i }))
    .filter(
      ({ s, i }) =>
        (!q ||
          fold([s.code ?? '', s.id, s.title.vi, s.title.en, s.lead.vi].join(' ')).includes(q)) &&
        (group === 'all' || s.category === group) &&
        (flag === 'all' ||
          (flag === 'emergency' && s.emergency) ||
          (flag === 'monitoring' && s.monitoring) ||
          (flag === 'issues' && problems.has(i))),
    );
  const filtered = !!q || group !== 'all' || flag !== 'all';
  const full = pack.situations.length >= 40;
  return (
    <div className="overflow-hidden rounded-xl border bg-card">
      <FilterBar
        active={filtered}
        onClear={() => {
          setQuery('');
          setGroup('all');
          setFlag('all');
        }}
        shown={rows.length}
        total={pack.situations.length}
      >
        <SearchInput
          value={query}
          onChange={setQuery}
          placeholder={intl.formatMessage({ id: 'firstAid.searchSituations' })}
        />
        <SelectMenu
          label={intl.formatMessage({ id: 'firstAid.col.category' })}
          value={group}
          onChange={setGroup}
          options={[
            { value: 'all', label: intl.formatMessage({ id: 'firstAid.filter.allGroups' }) },
            ...pack.categories.map((c) => ({ value: c.id, label: textOf(intl, c.title) || c.id })),
          ]}
        />
        <SelectMenu<Flag>
          label={intl.formatMessage({ id: 'firstAid.col.flags' })}
          value={flag}
          onChange={setFlag}
          options={[
            { value: 'all', label: intl.formatMessage({ id: 'firstAid.filter.allFlags' }) },
            { value: 'emergency', label: intl.formatMessage({ id: 'firstAid.badge.emergency' }) },
            { value: 'monitoring', label: intl.formatMessage({ id: 'firstAid.badge.monitoring' }) },
            ...(problems.size
              ? [
                  {
                    value: 'issues' as const,
                    label: intl.formatMessage({ id: 'firstAid.filter.issues' }),
                  },
                ]
              : []),
          ]}
        />
        {editing && (
          <Button
            variant="outline"
            size="sm"
            className={cn(!filtered && 'ml-auto')}
            disabled={full}
            title={full ? intl.formatMessage({ id: 'firstAid.situationsFull' }) : undefined}
            onClick={onAdd}
          >
            <Plus />
            <FormattedMessage id="firstAid.addSituation" />
          </Button>
        )}
      </FilterBar>
      {rows.length === 0 ? (
        <EmptyState icon={SearchX} title={<FormattedMessage id="firstAid.noMatch" />} />
      ) : (
        <TableScroll min={760}>
          <table className="table">
            <thead>
              <tr>
                <th className="w-20">
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
                {editing && (
                  <th>
                    <span className="sr-only">
                      <FormattedMessage id="firstAid.col.actions" />
                    </span>
                  </th>
                )}
              </tr>
            </thead>
            <tbody>
              {rows.map(({ s, i }) => (
                <tr
                  key={`${i}-${s.id}`}
                  className={cn('cursor-pointer', problems.has(i) && 'bg-destructive/5')}
                  onClick={() => onOpen(i)}
                >
                  <td className="font-mono text-[13px] whitespace-nowrap text-muted-foreground">
                    {s.code ?? '—'}
                  </td>
                  <td className="w-[46%] max-w-0">
                    <div className="flex min-w-0 items-center gap-3">
                      <ImageThumb id={s.icon || null} size={36} />
                      <div className="grid min-w-0">
                        <button
                          type="button"
                          className="truncate text-left font-medium outline-none hover:underline focus-visible:underline"
                          onClick={(e) => {
                            e.stopPropagation();
                            onOpen(i);
                          }}
                        >
                          {s.title.vi || <FormattedMessage id="firstAid.untitled" />}
                        </button>
                        <span className="truncate text-[13px] text-muted-foreground">
                          {s.lead.vi}
                        </span>
                      </div>
                    </div>
                  </td>
                  <td className="whitespace-nowrap">
                    {textOf(intl, categories.get(s.category)?.title) || s.category}
                  </td>
                  <td>
                    <span className="flex flex-wrap items-center gap-1">
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
                  <td className="whitespace-nowrap text-muted-foreground tabular-nums">
                    <FormattedMessage
                      id="firstAid.counts"
                      values={{ v: s.variants.length, n: stepCount(s) }}
                    />
                  </td>
                  {editing && (
                    <td className="cell-actions w-10" onClick={(e) => e.stopPropagation()}>
                      <RowActions
                        label={intl.formatMessage(
                          { id: 'table.actionsFor' },
                          { name: s.title.vi || s.id },
                        )}
                        actions={[
                          ...(i > 0 && !filtered
                            ? [
                                {
                                  key: 'up',
                                  label: <FormattedMessage id="firstAid.moveUp" />,
                                  onSelect: () => edit((p) => moveItem(p.situations, i, -1)),
                                },
                              ]
                            : []),
                          ...(i < pack.situations.length - 1 && !filtered
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
                                  onSelect: () => onRemove(i),
                                },
                              ]
                            : []),
                        ]}
                      />
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      )}
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
  const both = (t: { vi: string; en: string }) => (
    <>
      <span className="block">{t.vi || '—'}</span>
      <span className="block text-muted-foreground" lang="en">
        {t.en || '—'}
      </span>
    </>
  );
  const row = (label: ReactNode, value: ReactNode) => (
    <div className="grid gap-1 sm:grid-cols-[11rem_minmax(0,1fr)] sm:gap-4">
      <dt className="text-[13px] text-muted-foreground">{label}</dt>
      <dd className="min-w-0 text-sm">{value}</dd>
    </div>
  );
  return (
    <>
      <Section title={<FormattedMessage id="firstAid.section.basics" />}>
        <dl className="grid gap-3">
          {row(<FormattedMessage id="firstAid.field.title" />, both(s.title))}
          {row(<FormattedMessage id="firstAid.field.lead" />, both(s.lead))}
          {row(
            <FormattedMessage id="firstAid.field.category" />,
            textOf(intl, category?.title) || s.category,
          )}
          {row(
            <FormattedMessage id="firstAid.col.flags" />,
            s.emergency || s.monitoring ? (
              <span className="flex flex-wrap gap-1">
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
              </span>
            ) : (
              '—'
            ),
          )}
        </dl>
      </Section>
      <Section title={<FormattedMessage id="firstAid.section.variants" />}>
        <ul className="grid gap-2">
          {s.variants.map((v) => (
            <li
              key={v.id}
              className="flex flex-wrap items-center gap-x-3 gap-y-1 rounded-lg border px-3 py-2 text-sm"
            >
              <span className="font-medium">{textOf(intl, v.label) || v.id}</span>
              <span className="text-muted-foreground tabular-nums">
                <FormattedMessage id="firstAid.stepsCount" values={{ n: v.steps.length }} />
              </span>
              {v.ageMonths && <span className="text-muted-foreground">{age(v.ageMonths)}</span>}
              {v.cpr && (
                <Pill tone="info">
                  <FormattedMessage id={`firstAid.cpr.${v.cpr}`} />
                </Pill>
              )}
            </li>
          ))}
        </ul>
      </Section>
      <Section
        collapsible
        defaultOpen={false}
        title={<FormattedMessage id="firstAid.section.advanced" />}
        summary={[s.id, s.code].filter(Boolean).join(' · ')}
      >
        <dl className="grid gap-3">
          {row(
            <FormattedMessage id="firstAid.field.id" />,
            <span className="font-mono">{s.id}</span>,
          )}
          {row(<FormattedMessage id="firstAid.field.code" />, s.code ?? '—')}
          {row(
            <FormattedMessage id="firstAid.field.keywords" />,
            s.keywords.map((k) => k.vi).join(' · ') || '—',
          )}
          {row(<FormattedMessage id="firstAid.field.ageMonths" />, age(s.ageMonths))}
          {row(
            <FormattedMessage id="firstAid.field.tool" />,
            s.tool ? <FormattedMessage id={`firstAid.tool.${s.tool}`} /> : '—',
          )}
        </dl>
      </Section>
    </>
  );
}

export function GeneralSummary({ pack }: { pack: FirstAidPack }) {
  const intl = useIntl();
  return (
    <div className="grid items-start gap-4 lg:grid-cols-2">
      <div className="grid gap-4">
        <Section title={<FormattedMessage id="firstAid.section.emergency" />}>
          <p className="text-2xl font-bold tracking-tight tabular-nums">{pack.emergencyNumber}</p>
        </Section>
        <Section title={<FormattedMessage id="firstAid.section.quickSearch" />}>
          {pack.quickSearch.length ? (
            <span className="flex flex-wrap gap-1.5">
              {pack.quickSearch.map((q, i) => (
                <span key={i} className="rounded-full border bg-muted/50 px-2.5 py-0.5 text-sm">
                  {textOf(intl, q)}
                </span>
              ))}
            </span>
          ) : (
            <p className="text-sm text-muted-foreground">—</p>
          )}
        </Section>
        {pack.cpr.length > 0 && (
          <Section title={<FormattedMessage id="firstAid.section.cpr" />}>
            <dl className="grid gap-2 text-sm">
              {pack.cpr.map((c) => (
                <div key={c.id} className="flex flex-wrap justify-between gap-2">
                  <dt className="text-muted-foreground">
                    <FormattedMessage id={`firstAid.cpr.${c.id}`} />
                  </dt>
                  <dd className="tabular-nums">
                    <FormattedMessage
                      id="firstAid.cprFacts"
                      values={{
                        rate: c.ratePerMinute,
                        compressions: c.compressions,
                        breaths: c.breaths,
                      }}
                    />
                  </dd>
                </div>
              ))}
            </dl>
          </Section>
        )}
      </div>
      <Section
        flush
        title={<FormattedMessage id="firstAid.section.categories" />}
        description={
          <FormattedMessage id="firstAid.categoriesCount" values={{ n: pack.categories.length }} />
        }
      >
        <ul className="divide-y">
          {pack.categories.map((c) => (
            <li
              key={c.id}
              className="flex flex-wrap items-center gap-x-3 gap-y-1 px-5 py-3 text-sm"
            >
              <span className={`fa-tag fa-tag--${c.tone}`}>{textOf(intl, c.title) || c.id}</span>
              <span className="text-muted-foreground">
                <FormattedMessage id={`firstAid.layout.${c.layout}`} />
              </span>
              <span className="ml-auto text-muted-foreground tabular-nums">
                <FormattedMessage
                  id="firstAid.categoryUsed"
                  values={{ n: pack.situations.filter((s) => s.category === c.id).length }}
                />
              </span>
            </li>
          ))}
        </ul>
      </Section>
    </div>
  );
}

// ---------- Picture library ----------

export function Library({ pack, canUpload }: { pack: FirstAidPack; canUpload: boolean }) {
  const intl = useIntl();
  const [filter, setFilter] = useState<ImageFilter>('all');
  const [query, setQuery] = useState('');
  const [uploading, setUploading] = useState(false);
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
  const shown = filterImages(images, filter, query);
  const filtered = filter !== 'all' || !!query.trim();
  return (
    <Section
      title={<FormattedMessage id="firstAid.library" />}
      hint={<FormattedMessage id="firstAid.libraryNote" />}
      description={<FormattedMessage id="firstAid.libraryCount" values={{ n: images.length }} />}
      actions={
        canUpload && (
          <Button size="sm" onClick={() => setUploading(true)}>
            <Upload />
            <FormattedMessage id="firstAid.upload.open" />
          </Button>
        )
      }
    >
      <div className="grid gap-4">
        <div className="flex flex-wrap items-center gap-2">
          <ImageKindFilter value={filter} onChange={setFilter} />
          <SearchInput
            value={query}
            onChange={setQuery}
            placeholder={intl.formatMessage({ id: 'firstAid.searchImages' })}
          />
          {filtered && (
            <span className="ml-auto text-sm text-muted-foreground tabular-nums" role="status">
              <FormattedMessage
                id="kit.results"
                values={{ n: shown.length, total: images.length }}
              />
            </span>
          )}
        </div>
        <ImageGrid images={shown} usage={usage} />
      </div>
      {uploading && (
        <Modal
          title={<FormattedMessage id="firstAid.upload.open" />}
          onClose={() => setUploading(false)}
        >
          <UploadBox onDone={() => setUploading(false)} />
        </Modal>
      )}
    </Section>
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
    <section className="grid gap-3 rounded-xl border bg-card p-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h2 className="text-[15px] font-semibold">
          <FormattedMessage id="firstAid.preview" />
        </h2>
        <ToggleGroup
          type="single"
          variant="outline"
          size="sm"
          value={lang}
          aria-label={intl.formatMessage({ id: 'firstAid.previewLang' })}
          onValueChange={(l) => l && setLang(l as 'vi' | 'en')}
        >
          {(['vi', 'en'] as const).map((l) => (
            <ToggleGroupItem key={l} value={l} className="px-3">
              <FormattedMessage id={`firstAid.lang.${l}`} />
            </ToggleGroupItem>
          ))}
        </ToggleGroup>
      </div>
      <div className="fa-phone no-scrollbar" lang={lang}>
        <div className="fa-phone__hero">
          <ImageThumb id={hero || null} size={343} />
        </div>
        <div className="fa-phone__body">
          <span className="flex flex-wrap items-center gap-1.5">
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
                    <span className="flex flex-wrap items-center gap-1.5">
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
    </section>
  );
}
