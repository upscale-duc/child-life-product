import {
  articleContentStrictSchema,
  articleDraftSchema,
  articleFormats,
  articleTopics,
  contentBlockTypes,
  contentLibraries,
  contentLimits,
  readingMinutesOf,
  solidsSubtopics,
  staffCan,
  type ArticleDraft,
  type ContentBlock,
  type ContentBlockType,
  type EditorialAction,
  type SolidsSubtopic,
} from '@child-life/contracts';
import {
  ChevronDown,
  Copy,
  Heading,
  List,
  MessageSquareWarning,
  Newspaper,
  Pilcrow,
  Plus,
  Trash2,
} from 'lucide-react';
import { useEffect, useId, useMemo, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { toast } from 'sonner';
import { Button as UiButton } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Input } from '@/components/ui/input';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { cn } from '@/lib/utils';
import { ApiError, useApi, useLoad } from '../api';
import {
  EditorBar,
  EditorLayout,
  EmptyState,
  Field,
  FilterBar,
  MoreFilters,
  Notice,
  OverflowMenu,
  SearchInput,
  Section,
  StatTiles,
  useGuardedLeave,
} from '../content-kit';
import { useOwnWorkBlocked } from '../content-policy';
import { routePaths, subPath, useStaff } from '../context';
import { Button, Loaded, Page, SelectMenu, TableScroll, useSort } from '../ui';
import {
  ActDialog,
  BlocksPreview,
  ContentImagesProvider,
  CoverField,
  EditorNotices,
  EmergencyHint,
  EmergencyNotice,
  ImagePickerButton,
  ImageThumb,
  LangTabs,
  LinkPicker,
  NumberField,
  PhoneFrame,
  PreviewCard,
  ReviewLine,
  SourcesField,
  StatusCell,
  TextField,
  WorkflowMain,
  actionsFor,
  ageBands,
  asApiError,
  calloutToneOptions,
  contentTiles,
  dateTime,
  fillEmergency,
  reviewOf,
  splitActions,
  statusOptions,
  subtopicOf,
  subtopicOptions,
  textOf,
  tileMatch,
  topicOptions,
  useContentList,
  useSeedItem,
  weeksLabel,
  workflowMenu,
  type ContentItemView,
  type ContentListView,
  type ContentRow,
  type Lang,
  type ParseIssue,
  type Tile,
} from './content-common';
import { FieldSelect, IconButton } from './form-controls';

/**
 * Bài viết (Figma B01 `316:1460`, B02 `317:1558`; D-076 #7): the Thư viện chăm bé articles.
 * B01 lists them with the counts (on the app, waiting, drafts, due for re-review; each filters the
 * list) and filters; B02 edits one in the safe block model (paragraph, heading, list, callout,
 * picture; plain text only) in three tabs (content, settings, sources and review) next to a
 * preview of the app reader (4d). Saving keeps a draft; the workflow (Gửi duyệt → Duyệt → Xuất
 * bản) is shared with Duyệt nội dung (B03/B04).
 */

export function ArticlesScreen() {
  const [path, setPath] = useState(() => subPath('articles', window.location.pathname));
  useEffect(() => {
    const onPop = () => setPath(subPath('articles', window.location.pathname));
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, []);
  const go = (id: string | null) => {
    const url = id ? `${routePaths.articles}/${encodeURIComponent(id)}` : routePaths.articles;
    if (window.location.pathname !== url) window.history.pushState({}, '', url);
    setPath(id ? [id] : []);
    window.scrollTo(0, 0);
  };
  const id = path[0] ?? null;
  return id ? (
    <ArticleEditorScreen key={id} id={id === 'new' ? null : id} onOpen={go} />
  ) : (
    <ArticlesListScreen onOpen={go} />
  );
}

function ArticlesListScreen({ onOpen }: { onOpen: (id: string | null) => void }) {
  const staff = useStaff();
  const [load, reload] = useContentList('article');
  const canEdit = staffCan(staff.levels, 'content.edit');
  const seed = useSeedItem('article', reload);
  return (
    <Page
      title={<FormattedMessage id="articles.title" />}
      actions={
        canEdit && (
          <>
            <OverflowMenu items={[seed]} />
            <Button kind="primary" onClick={() => onOpen('new')}>
              <Plus />
              <FormattedMessage id="articles.new" />
            </Button>
          </>
        )
      }
    >
      <Loaded load={load} reload={reload}>
        {(view) => <ArticlesBody view={view} onOpen={onOpen} />}
      </Loaded>
    </Page>
  );
}

type Filters = {
  q: string;
  library: string;
  topic: string;
  age: string;
  status: string;
  reviewer: string;
  lang: string;
  /** Ăn dặm › Hướng dẫn: a group, "none" (not chosen yet) or "all" (D-087). */
  subtopic?: string;
  /** The count tile the list is narrowed to. */
  tile?: Tile;
};
const allFilters: Filters = {
  q: '',
  library: 'all',
  topic: 'all',
  age: 'all',
  status: 'all',
  reviewer: 'all',
  lang: 'all',
  subtopic: 'all',
  tile: 'all',
};

/**
 * B01 filters: library, topic, age band (overlap), status, reviewer, missing language, and the
 * solids group in Ăn dặm › Hướng dẫn.
 */
export function filterArticles(rows: ContentRow[], f: Filters): ContentRow[] {
  const q = f.q.trim().toLowerCase();
  const band = ageBands.find((b) => b.id === f.age);
  return rows.filter(
    (r) =>
      tileMatch(r, f.tile) &&
      (!q || `${r.title.vi} ${r.title.en} ${r.id}`.toLowerCase().includes(q)) &&
      (f.library === 'all' || r.library === f.library) &&
      (f.topic === 'all' || r.topic === f.topic) &&
      (!band || (!!r.ageWeeks && r.ageWeeks.from < band.to && band.from < r.ageWeeks.to)) &&
      (f.status === 'all' || r.displayStatus === f.status) &&
      (f.reviewer === 'all' || (r.reviewerLabel ?? '') === f.reviewer) &&
      (!f.subtopic ||
        f.subtopic === 'all' ||
        (f.subtopic === 'none'
          ? !subtopicOf(r.subtopic)
          : subtopicOf(r.subtopic) === f.subtopic)) &&
      (f.lang === 'all' ||
        (f.lang === 'missingEn' ? !r.title.en || !r.blocks?.en : !r.title.vi || !r.blocks?.vi)),
  );
}

export function ArticlesBody({
  view,
  onOpen,
  initialFilters,
  solids = false,
}: {
  view: ContentListView;
  onOpen: (id: string) => void;
  initialFilters?: Partial<Filters>;
  /** Ăn dặm › Hướng dẫn: the solids group (D-087) instead of the topic, always "Bú & sữa". */
  solids?: boolean;
}) {
  const intl = useIntl();
  const [f, setF] = useState<Filters>({ ...allFilters, ...initialFilters });
  const rows = filterArticles(view.rows, f);
  const reviewers = [...new Set(view.rows.map((r) => r.reviewerLabel ?? '').filter(Boolean))];
  const sorted = useSort(rows, {
    title: (r) => textOf(intl, r.title),
    topic: (r) => r.topic ?? '',
    subtopic: (r) => {
      const s = subtopicOf(r.subtopic);
      return s ? solidsSubtopics.indexOf(s) : null;
    },
    age: (r) => r.ageWeeks?.from ?? null,
    minutes: (r) => r.readingMinutes ?? null,
    status: (r) => r.displayStatus,
    updated: (r) => r.updatedAt,
  });
  const opt = (id: string, value: string) => ({ value, label: intl.formatMessage({ id }) });
  const more = [f.library, f.reviewer, f.lang].filter((v) => v !== 'all').length;
  const active = JSON.stringify(f) !== JSON.stringify(allFilters);
  return (
    <div className="grid gap-4">
      <StatTiles
        items={contentTiles(view.counts, f.tile ?? 'all', (tile) => setF({ ...f, tile }))}
      />
      <div className="overflow-hidden rounded-xl border bg-card">
        <FilterBar
          active={active}
          onClear={() => setF(allFilters)}
          shown={rows.length}
          total={view.rows.length}
        >
          <SearchInput
            value={f.q}
            placeholder={intl.formatMessage({ id: 'articles.search' })}
            onChange={(q) => setF({ ...f, q })}
          />
          {solids ? (
            <SelectMenu
              label={intl.formatMessage({ id: 'content.filter.subtopic' })}
              value={f.subtopic ?? 'all'}
              onChange={(subtopic) => setF({ ...f, subtopic })}
              options={[
                opt('content.filter.allSubtopics', 'all'),
                ...subtopicOptions(intl),
                opt('content.filter.noSubtopic', 'none'),
              ]}
            />
          ) : (
            <SelectMenu
              label={intl.formatMessage({ id: 'content.filter.topic' })}
              value={f.topic}
              onChange={(topic) => setF({ ...f, topic })}
              options={[opt('content.filter.allTopics', 'all'), ...topicOptions(intl)]}
            />
          )}
          <SelectMenu
            label={intl.formatMessage({ id: 'content.filter.age' })}
            value={f.age}
            onChange={(age) => setF({ ...f, age })}
            options={[
              opt('content.filter.allAges', 'all'),
              ...ageBands.map((b) => opt(`content.band.${b.id}`, b.id)),
            ]}
          />
          <SelectMenu
            label={intl.formatMessage({ id: 'content.filter.status' })}
            value={f.status}
            onChange={(status) => setF({ ...f, status })}
            options={statusOptions(intl)}
          />
          <MoreFilters count={more}>
            <FilterField label={<FormattedMessage id="content.filter.library" />}>
              <SelectMenu
                className="w-full"
                label={intl.formatMessage({ id: 'content.filter.library' })}
                value={f.library}
                onChange={(library) => setF({ ...f, library })}
                options={[
                  opt('content.filter.allLibraries', 'all'),
                  ...contentLibraries.map((l) => opt(`content.library.${l}`, l)),
                ]}
              />
            </FilterField>
            <FilterField label={<FormattedMessage id="content.filter.reviewer" />}>
              <SelectMenu
                className="w-full"
                label={intl.formatMessage({ id: 'content.filter.reviewer' })}
                value={f.reviewer}
                onChange={(reviewer) => setF({ ...f, reviewer })}
                options={[
                  opt('content.filter.allReviewers', 'all'),
                  ...reviewers.map((r) => ({ value: r, label: r })),
                ]}
              />
            </FilterField>
            <FilterField label={<FormattedMessage id="content.filter.lang" />}>
              <SelectMenu
                className="w-full"
                label={intl.formatMessage({ id: 'content.filter.lang' })}
                value={f.lang}
                onChange={(lang) => setF({ ...f, lang })}
                options={[
                  opt('content.filter.allLangs', 'all'),
                  opt('content.filter.missingEn', 'missingEn'),
                  opt('content.filter.missingVi', 'missingVi'),
                ]}
              />
            </FilterField>
          </MoreFilters>
        </FilterBar>
        {rows.length ? (
          <TableScroll min={860}>
            <table className="table">
              <thead>
                <tr>
                  {sorted.th('title', <FormattedMessage id="content.col.title" />)}
                  {solids
                    ? sorted.th('subtopic', <FormattedMessage id="content.col.subtopic" />)
                    : sorted.th('topic', <FormattedMessage id="content.col.topic" />)}
                  {sorted.th('age', <FormattedMessage id="content.col.age" />)}
                  {sorted.th('minutes', <FormattedMessage id="content.col.minutes" />)}
                  {sorted.th('status', <FormattedMessage id="content.col.status" />)}
                  {sorted.th('updated', <FormattedMessage id="content.col.updated" />)}
                </tr>
              </thead>
              <tbody>
                {sorted.rows.map((r) => (
                  <tr key={r.id} className="cl-row" onClick={() => onOpen(r.id)}>
                    <td className="max-w-[28rem]">
                      <button
                        type="button"
                        className="link-button line-clamp-2 text-left font-medium"
                        onClick={() => onOpen(r.id)}
                      >
                        {textOf(intl, r.title) || (
                          <span className="text-muted-foreground">
                            <FormattedMessage id="content.untitled" />
                          </span>
                        )}
                      </button>
                      <div className="mt-0.5 truncate text-xs text-muted-foreground">
                        {[
                          r.library === 'solids'
                            ? intl.formatMessage({ id: 'content.library.solids' })
                            : null,
                          r.format
                            ? intl.formatMessage({ id: `content.format.${r.format}` })
                            : null,
                          r.reviewerLabel,
                        ]
                          .filter(Boolean)
                          .join(' · ')}
                      </div>
                    </td>
                    <td className="nowrap">
                      {solids ? (
                        <SubtopicCell value={r.subtopic} />
                      ) : (
                        r.topic && <FormattedMessage id={`content.topic.${r.topic}`} />
                      )}
                    </td>
                    <td className="nowrap">{r.ageWeeks ? weeksLabel(intl, r.ageWeeks) : '—'}</td>
                    <td className="text-center tabular-nums">{r.readingMinutes ?? '—'}</td>
                    <td>
                      <StatusCell row={r} />
                    </td>
                    <td
                      className="nowrap text-muted-foreground tabular-nums"
                      title={r.lastEditorName}
                    >
                      {dateTime(intl, r.updatedAt)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </TableScroll>
        ) : (
          <EmptyState
            icon={Newspaper}
            title={
              <FormattedMessage id={view.rows.length ? 'content.noMatch' : 'articles.empty'} />
            }
          />
        )}
      </div>
    </div>
  );
}

/** A solids guide's group, or a muted "Chưa chọn" so the gaps show. */
function SubtopicCell({ value }: { value: unknown }) {
  const s = subtopicOf(value);
  return s ? (
    <FormattedMessage id={`content.subtopic.${s}`} />
  ) : (
    <span className="text-muted-foreground">
      <FormattedMessage id="content.subtopic.none" />
    </span>
  );
}

function FilterField({ label, children }: { label: ReactNode; children: ReactNode }) {
  return (
    <div className="grid gap-1.5">
      <span className="text-xs font-medium text-muted-foreground">{label}</span>
      {children}
    </div>
  );
}

// ---------- B02 editor ----------

export function blankArticle(): ArticleDraft {
  return {
    library: 'care',
    topic: 'sleep',
    format: 'article',
    ageWeeks: { from: 0, to: 13 },
    readingMinutes: 1,
    cover: null,
    title: { vi: '', en: '' },
    summary: { vi: '', en: '' },
    body: { vi: [{ type: 'paragraph', text: '' }], en: [] },
    keywords: { vi: [], en: [] },
    relatedArticleIds: [],
    milestoneIds: [],
    sources: [],
  };
}

export function blankBlock(type: ContentBlockType): ContentBlock {
  switch (type) {
    case 'paragraph':
      return { type, text: '' };
    case 'heading':
      return { type, text: '' };
    case 'bullets':
      return { type, items: [''] };
    case 'callout':
      return { type, tone: 'doctor', title: '', text: '' };
    case 'image':
      // Filled by the picker before it is added.
      return { type, image: 'x', caption: '', alt: '' };
  }
}

/** "Sao chép cấu trúc từ tiếng Việt": the same blocks, to translate in place. */
export function copyStructure(from: ContentBlock[]): ContentBlock[] {
  return structuredClone(from);
}

/** Where an article is edited from: Bài viết, or Ăn dặm › Hướng dẫn (D-085, same editor). */
type EditorPlace = {
  /** A new article starts from this (Ăn dặm presets library "solids", topic "feeding"). */
  blank?: () => ArticleDraft;
  backLabel?: ReactNode;
};

export function ArticleEditorScreen({
  id,
  onOpen,
  ...place
}: {
  id: string | null;
  onOpen: (id: string | null) => void;
} & EditorPlace) {
  return id ? (
    <ExistingArticle id={id} onOpen={onOpen} {...place} />
  ) : (
    <ArticleEditorShell item={null} onOpen={onOpen} reload={() => undefined} {...place} />
  );
}

function ExistingArticle({
  id,
  onOpen,
  ...place
}: { id: string; onOpen: (id: string | null) => void } & EditorPlace) {
  const [item, reload] = useLoad<ContentItemView<ArticleDraft>>(
    'staffContentItem',
    { kind: 'article', id },
    `article:${id}`,
  );
  return (
    <Loaded load={item} reload={reload}>
      {(view) => <ArticleEditorShell item={view} onOpen={onOpen} reload={reload} {...place} />}
    </Loaded>
  );
}

function ArticleEditorShell({
  item,
  onOpen,
  reload,
  blank,
  backLabel,
}: {
  item: ContentItemView<ArticleDraft> | null;
  onOpen: (id: string | null) => void;
  reload: () => void;
} & EditorPlace) {
  const staff = useStaff();
  const [list] = useContentList('article');
  const canEdit = staffCan(staff.levels, 'content.edit');
  const ok = list.status === 'ok' ? list.data : null;
  return (
    <ContentImagesProvider canUpload={canEdit}>
      <ArticleEditor
        key={item ? `${item.row.id}:${item.row.updatedAt}` : 'new'}
        item={item}
        articles={ok?.rows ?? []}
        requireReview={ok?.requireReview ?? false}
        today={ok?.today ?? new Date().toISOString().slice(0, 10)}
        staffUid={staff.uid}
        canEdit={canEdit}
        canApprove={staffCan(staff.levels, 'content.approve')}
        onBack={() => onOpen(null)}
        onSaved={(newId) => (newId !== item?.row.id ? onOpen(newId) : reload())}
        onChanged={reload}
        blank={blank}
        backLabel={backLabel}
      />
    </ContentImagesProvider>
  );
}

type EditorTab = 'content' | 'settings' | 'review';
const tabOfIssue = (i: ParseIssue): EditorTab => {
  const head = String(i.path[0] ?? '');
  if (['title', 'summary', 'body'].includes(head)) return 'content';
  if (head === 'sources') return 'review';
  return 'settings';
};

export function ArticleEditor({
  item,
  articles,
  requireReview,
  today,
  staffUid,
  canEdit,
  canApprove,
  onBack,
  onSaved,
  onChanged,
  initialLang = 'vi',
  initialTab = 'content',
  blank = blankArticle,
  backLabel,
}: {
  item: ContentItemView<ArticleDraft> | null;
  articles: ContentRow[];
  requireReview: boolean;
  today: string;
  staffUid: string;
  canEdit: boolean;
  canApprove: boolean;
  onBack: () => void;
  onSaved: (id: string) => void;
  onChanged: () => void;
  initialLang?: Lang;
  /** The tab the form opens on. */
  initialTab?: EditorTab;
  /** A new article starts from this (Ăn dặm › Hướng dẫn: library "solids", topic "feeding"). */
  blank?: () => ArticleDraft;
  backLabel?: ReactNode;
}) {
  const intl = useIntl();
  const ownWorkBlocked = useOwnWorkBlocked(staffUid);
  const api = useApi();
  const [data, setData] = useState<ArticleDraft>(() =>
    item ? structuredClone(item.data) : blank(),
  );
  const [reviewerLabel, setReviewerLabel] = useState(item?.row.reviewerLabel ?? '');
  const [notes, setNotes] = useState(item?.notes ?? '');
  const [dirty, setDirty] = useState(!item);
  const [lang, setLang] = useState<Lang>(initialLang);
  const [tab, setTab] = useState<EditorTab>(initialTab);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const [act, setAct] = useState<EditorialAction | null>(null);
  const [start] = useState(() =>
    JSON.stringify({
      data: item ? item.data : blank(),
      reviewerLabel: item?.row.reviewerLabel ?? '',
      notes: item?.notes ?? '',
    }),
  );
  const changed = dirty && JSON.stringify({ data, reviewerLabel, notes }) !== start;
  const { leave, dialog } = useGuardedLeave(changed, onBack);
  const edit = (fn: (d: ArticleDraft) => void) => {
    setData((d) => {
      const next = structuredClone(d);
      fn(next);
      return next;
    });
    setDirty(true);
  };
  const strict = useMemo(() => articleContentStrictSchema.safeParse(data), [data]);
  const issues = strict.success ? [] : strict.error.issues;
  const shownIssues = item?.row.status === 'draft' ? issues : [];
  const row = item?.row ?? null;
  const actions = row && !dirty ? actionsFor(row, { edit: canEdit, approve: canApprove }) : [];
  const { main, rest } = splitActions(actions.filter((a) => a !== 'submit' || strict.success));
  const save = () => {
    const req = {
      kind: 'article',
      id: row?.id ?? null,
      data,
      reviewerLabel: reviewerLabel.trim() || null,
      notes: notes.trim(),
    };
    if (!articleDraftSchema.safeParse(data).success) {
      setError(new ApiError('invalid-argument', null));
      return;
    }
    setBusy(true);
    setError(null);
    api
      .call<{ id: string }>('staffContentSave', req)
      .then((r) => {
        setDirty(false);
        toast.success(intl.formatMessage({ id: 'content.savedToast' }));
        onSaved(r.id);
      })
      .catch((e: unknown) => setError(asApiError(e)))
      .finally(() => setBusy(false));
  };
  const others = articles
    .filter((a) => a.id !== row?.id && a.status !== 'archived')
    .map((a) => ({
      id: a.id,
      title: textOf(intl, a.title) || a.id,
      meta: weeksLabel(intl, a.ageWeeks ?? { from: 0, to: 1 }),
    }));
  const body = data.body[lang];
  const perTab = (t: EditorTab) => shownIssues.filter((i) => tabOfIssue(i) === t).length;
  const tabLabel = (t: EditorTab, id: string) => (
    <>
      <FormattedMessage id={id} />
      {perTab(t) > 0 && (
        <span className="grid size-4.5 place-items-center rounded-full bg-warning text-[10px] font-semibold text-white tabular-nums">
          {perTab(t)}
        </span>
      )}
    </>
  );
  return (
    <section>
      <EditorBar
        backLabel={backLabel ?? <FormattedMessage id="articles.title" />}
        onBack={leave}
        title={textOf(intl, data.title) || <FormattedMessage id="articles.new" />}
        badges={row && <StatusCell row={row} />}
        dirty={dirty}
        saving={busy}
        onSave={canEdit ? save : undefined}
        actions={<WorkflowMain actions={main} onPick={setAct} />}
        menu={workflowMenu(rest, setAct)}
      />
      <EditorNotices error={error} rejection={row?.rejection} issues={shownIssues} />
      <EmergencyNotice data={data} />
      <EditorLayout
        aside={
          <PreviewCard lang={lang}>
            <ArticlePreview data={data} lang={lang} review={reviewOf(item)} />
          </PreviewCard>
        }
      >
        <Tabs value={tab} onValueChange={(v) => setTab(v as EditorTab)} className="gap-4">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <TabsList>
              <TabsTrigger value="content" className="px-3">
                {tabLabel('content', 'articles.content')}
              </TabsTrigger>
              <TabsTrigger value="settings" className="px-3">
                {tabLabel('settings', 'articles.settings')}
              </TabsTrigger>
              <TabsTrigger value="review" className="px-3">
                {tabLabel('review', 'articles.reviewTab')}
              </TabsTrigger>
            </TabsList>
            <LangTabs value={lang} onChange={setLang} />
          </div>
          <TabsContent value="content" className="grid gap-4">
            <Section title={<FormattedMessage id="articles.heading" />}>
              <div className="grid gap-4">
                <TextField
                  label={<FormattedMessage id="content.field.title" />}
                  value={data.title[lang]}
                  max={contentLimits.articleTitle}
                  counter
                  onChange={(v) => edit((d) => void (d.title[lang] = v))}
                />
                <TextField
                  label={<FormattedMessage id="content.field.summary" />}
                  value={data.summary[lang]}
                  max={contentLimits.summary}
                  counter
                  multiline
                  onChange={(v) => edit((d) => void (d.summary[lang] = v))}
                />
              </div>
            </Section>
            {lang === 'en' && body.length === 0 && data.body.vi.length > 0 && (
              <Notice
                tone="info"
                action={
                  <UiButton
                    size="sm"
                    onClick={() => edit((d) => void (d.body.en = copyStructure(d.body.vi)))}
                  >
                    <Copy />
                    <FormattedMessage id="articles.copyStructure" />
                  </UiButton>
                }
              >
                <FormattedMessage id="articles.copyHint" />
              </Notice>
            )}
            <BlocksEditor
              blocks={body}
              onChange={(blocks) => edit((d) => void (d.body[lang] = blocks))}
            />
          </TabsContent>
          <TabsContent value="settings" className="grid gap-4">
            <Section title={<FormattedMessage id="articles.placement" />}>
              <div
                className={cn(
                  'grid gap-4',
                  data.library === 'solids' ? 'sm:grid-cols-2' : 'sm:grid-cols-3',
                )}
              >
                <SettingSelect
                  label="content.field.library"
                  value={data.library}
                  options={contentLibraries.map((l) => ({
                    value: l,
                    label: intl.formatMessage({ id: `content.library.${l}` }),
                  }))}
                  onChange={(v) =>
                    edit((d) => {
                      d.library = v;
                      // The groups belong to Thư viện ăn dặm; care articles carry none (D-087).
                      if (v !== 'solids') delete d.subtopic;
                    })
                  }
                />
                {data.library === 'solids' && (
                  <SettingSelect<SolidsSubtopic | 'none'>
                    label="content.field.subtopic"
                    value={subtopicOf(data.subtopic) ?? 'none'}
                    options={[
                      {
                        value: 'none',
                        label: intl.formatMessage({ id: 'content.subtopic.none' }),
                      },
                      ...subtopicOptions(intl),
                    ]}
                    help={<FormattedMessage id="articles.subtopicHelp" />}
                    onChange={(v) => edit((d) => void (d.subtopic = v === 'none' ? null : v))}
                  />
                )}
                <SettingSelect
                  label="content.field.topic"
                  value={data.topic}
                  options={articleTopics.map((t) => ({
                    value: t,
                    label: intl.formatMessage({ id: `content.topic.${t}` }),
                  }))}
                  onChange={(v) => edit((d) => void (d.topic = v))}
                />
                <SettingSelect
                  label="content.field.format"
                  value={data.format}
                  options={articleFormats.map((t) => ({
                    value: t,
                    label: intl.formatMessage({ id: `content.format.${t}` }),
                  }))}
                  onChange={(v) => edit((d) => void (d.format = v))}
                />
              </div>
            </Section>
            <Section
              title={<FormattedMessage id="articles.ageAndTime" />}
              description={
                <FormattedMessage
                  id="articles.ageHelp"
                  values={{
                    label:
                      data.ageWeeks.to > data.ageWeeks.from ? weeksLabel(intl, data.ageWeeks) : '—',
                  }}
                />
              }
            >
              <div className="grid items-start gap-4 sm:grid-cols-3">
                <NumberField
                  label={<FormattedMessage id="articles.ageFrom" />}
                  value={data.ageWeeks.from}
                  min={0}
                  max={contentLimits.maxAgeWeeks}
                  suffix={<FormattedMessage id="articles.weeks" />}
                  onChange={(v) => edit((d) => void (d.ageWeeks.from = v))}
                />
                <NumberField
                  label={<FormattedMessage id="articles.ageTo" />}
                  value={data.ageWeeks.to}
                  min={1}
                  max={contentLimits.maxAgeWeeks}
                  suffix={<FormattedMessage id="articles.weeks" />}
                  hint={<FormattedMessage id="articles.ageToHint" />}
                  onChange={(v) => edit((d) => void (d.ageWeeks.to = v))}
                />
                <NumberField
                  label={<FormattedMessage id="content.field.readingMinutes" />}
                  value={data.readingMinutes}
                  min={1}
                  max={contentLimits.readingMinutes}
                  suffix={<FormattedMessage id="articles.minutes" />}
                  help={
                    <button
                      type="button"
                      className="font-medium text-primary hover:underline"
                      onClick={() =>
                        edit((d) => void (d.readingMinutes = readingMinutesOf(d.body.vi)))
                      }
                    >
                      <FormattedMessage id="articles.computeMinutes" />
                    </button>
                  }
                  onChange={(v) => edit((d) => void (d.readingMinutes = v))}
                />
              </div>
            </Section>
            <Section title={<FormattedMessage id="content.cover" />}>
              <CoverField
                value={data.cover}
                lang={lang}
                onChange={(v) => edit((d) => void (d.cover = v))}
              />
            </Section>
            <Section title={<FormattedMessage id="articles.links" />}>
              <div className="grid gap-5">
                <LinkPicker
                  label={<FormattedMessage id="articles.related" />}
                  value={data.relatedArticleIds}
                  options={others}
                  max={contentLimits.relatedArticles}
                  tone="mint"
                  onChange={(v) => edit((d) => void (d.relatedArticleIds = v))}
                />
                <TextField
                  label={
                    <FormattedMessage
                      id="articles.keywords"
                      values={{ lang: lang.toUpperCase() }}
                    />
                  }
                  value={data.keywords[lang].join(', ')}
                  max={600}
                  help={<FormattedMessage id="articles.keywordsHelp" />}
                  onChange={(v) =>
                    edit(
                      (d) =>
                        void (d.keywords[lang] = v
                          .split(',')
                          .map((k) => k.trim())
                          .filter(Boolean)
                          .slice(0, contentLimits.keywords)),
                    )
                  }
                />
              </div>
            </Section>
          </TabsContent>
          <TabsContent value="review" className="grid gap-4">
            <Section title={<FormattedMessage id="content.sources" />}>
              <SourcesField
                value={data.sources}
                max={contentLimits.articleSources}
                onChange={(v) => edit((d) => void (d.sources = v))}
              />
            </Section>
            <Section title={<FormattedMessage id="content.forReviewer" />}>
              <div className="grid gap-4">
                <TextField
                  label={<FormattedMessage id="content.reviewerLabel" />}
                  value={reviewerLabel}
                  max={contentLimits.reviewerLabel}
                  hint={<FormattedMessage id="content.reviewerLabelHelp" />}
                  onChange={(v) => {
                    setReviewerLabel(v);
                    setDirty(true);
                  }}
                />
                <TextField
                  label={<FormattedMessage id="content.notes" />}
                  value={notes}
                  max={contentLimits.notes}
                  multiline
                  onChange={(v) => {
                    setNotes(v);
                    setDirty(true);
                  }}
                />
              </div>
            </Section>
          </TabsContent>
        </Tabs>
      </EditorLayout>
      {dialog}
      {act && row && (
        <ActDialog
          kind="article"
          id={row.id}
          action={act}
          title={textOf(intl, data.title)}
          requireReview={requireReview}
          today={today}
          sameEditor={ownWorkBlocked(item?.lastEditorUid)}
          onClose={() => setAct(null)}
          onDone={() => {
            setAct(null);
            onChanged();
          }}
        />
      )}
    </section>
  );
}

function SettingSelect<T extends string>({
  label,
  value,
  options,
  onChange,
  help,
}: {
  label: string;
  value: T;
  options: Array<{ value: T; label: string }>;
  onChange: (v: T) => void;
  help?: ReactNode;
}) {
  const id = useId();
  return (
    <Field label={<FormattedMessage id={label} />} htmlFor={id} help={help}>
      <FieldSelect id={id} value={value} options={options} onChange={onChange} />
    </Field>
  );
}

const blockIcon = {
  paragraph: Pilcrow,
  heading: Heading,
  bullets: List,
  callout: MessageSquareWarning,
  image: Newspaper,
} as const;

const blockStripe: Record<string, string> = {
  heading: 'border-l-primary',
  callout: 'border-l-warning',
  bullets: 'border-l-chart-5',
  image: 'border-l-chart-3',
  paragraph: 'border-l-border',
};

/** One line that says what a folded block holds. */
function blockSummary(b: ContentBlock): string {
  switch (b.type) {
    case 'paragraph':
    case 'heading':
      return b.text;
    case 'bullets':
      return b.items.filter(Boolean).join(' · ');
    case 'callout':
      return [b.title, b.text].filter(Boolean).join(' — ');
    case 'image':
      return b.caption || b.image;
  }
}

/** The block list for one language: add (at the end or under a block), edit, fold, move, remove. */
export function BlocksEditor({
  blocks,
  onChange,
}: {
  blocks: ContentBlock[];
  onChange: (b: ContentBlock[]) => void;
}) {
  const intl = useIntl();
  // Folded blocks by position; moving a block moves its fold with it.
  const [folded, setFolded] = useState<boolean[]>([]);
  const isFolded = (i: number) => folded[i] ?? false;
  const set = (i: number, b: ContentBlock) => onChange(blocks.map((x, j) => (j === i ? b : x)));
  const move = (i: number, by: number) => {
    const next = [...blocks];
    const [b] = next.splice(i, 1);
    next.splice(i + by, 0, b!);
    const f = blocks.map((_, j) => isFolded(j));
    const [x] = f.splice(i, 1);
    f.splice(i + by, 0, x!);
    setFolded(f);
    onChange(next);
  };
  const insert = (at: number, b: ContentBlock) => {
    const next = [...blocks];
    next.splice(at, 0, b);
    const f = blocks.map((_, j) => isFolded(j));
    f.splice(at, 0, false);
    setFolded(f);
    onChange(next);
  };
  const remove = (i: number) => {
    setFolded(blocks.map((_, j) => isFolded(j)).filter((_, j) => j !== i));
    onChange(blocks.filter((_, j) => j !== i));
  };
  const allFolded = blocks.length > 0 && blocks.every((_, i) => isFolded(i));
  const textTypes = contentBlockTypes.filter((t) => t !== 'image');
  const full = blocks.length >= contentLimits.blocks;
  return (
    <Section
      title={
        <FormattedMessage
          id="articles.blocks"
          values={{ n: blocks.length, max: contentLimits.blocks }}
        />
      }
      description={<EmergencyHint />}
      actions={
        blocks.length > 1 && (
          <UiButton
            variant="ghost"
            size="sm"
            className="text-muted-foreground"
            onClick={() => setFolded(blocks.map(() => !allFolded))}
          >
            <ChevronDown className={cn('transition-transform', !allFolded && 'rotate-180')} />
            <FormattedMessage id={allFolded ? 'articles.unfoldAll' : 'articles.foldAll'} />
          </UiButton>
        )
      }
    >
      <ol className="grid gap-2">
        {blocks.map((b, i) => {
          const Icon = blockIcon[b.type];
          const isOpen = !isFolded(i);
          return (
            <li
              key={i}
              className={cn(
                'rounded-lg border border-l-[3px] bg-background',
                blockStripe[b.type] ?? 'border-l-border',
              )}
            >
              <div className="flex items-center gap-2 px-3 py-1.5">
                <button
                  type="button"
                  className="flex min-w-0 flex-1 items-center gap-2 rounded-md py-1 text-left outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50"
                  aria-expanded={isOpen}
                  onClick={() => setFolded(blocks.map((_, j) => (j === i ? isOpen : isFolded(j))))}
                >
                  <ChevronDown
                    className={cn(
                      'size-4 shrink-0 text-muted-foreground transition-transform',
                      !isOpen && '-rotate-90',
                    )}
                    aria-hidden="true"
                  />
                  <Icon className="size-4 shrink-0 text-muted-foreground" aria-hidden="true" />
                  <span className="shrink-0 text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                    <FormattedMessage id={`content.block.${b.type}`} />
                  </span>
                  {!isOpen && (
                    <span className="min-w-0 truncate text-sm text-muted-foreground">
                      {blockSummary(b) || '—'}
                    </span>
                  )}
                </button>
                <span className="flex shrink-0 items-center">
                  <IconButton
                    icon="up"
                    label={intl.formatMessage({ id: 'content.moveUp' })}
                    disabled={i === 0}
                    onClick={() => move(i, -1)}
                  />
                  <IconButton
                    icon="down"
                    label={intl.formatMessage({ id: 'content.moveDown' })}
                    disabled={i === blocks.length - 1}
                    onClick={() => move(i, 1)}
                  />
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <UiButton
                        variant="ghost"
                        size="icon"
                        className="size-8"
                        disabled={full}
                        aria-label={intl.formatMessage({ id: 'articles.insertBelow' })}
                        title={intl.formatMessage({ id: 'articles.insertBelow' })}
                      >
                        <Plus />
                      </UiButton>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      {textTypes.map((t) => {
                        const TIcon = blockIcon[t];
                        return (
                          <DropdownMenuItem key={t} onSelect={() => insert(i + 1, blankBlock(t))}>
                            <TIcon />
                            <FormattedMessage id={`content.block.${t}`} />
                          </DropdownMenuItem>
                        );
                      })}
                    </DropdownMenuContent>
                  </DropdownMenu>
                  <UiButton
                    variant="ghost"
                    size="icon"
                    className="size-8 text-muted-foreground hover:text-destructive"
                    aria-label={intl.formatMessage({ id: 'content.remove' })}
                    title={intl.formatMessage({ id: 'content.remove' })}
                    onClick={() => remove(i)}
                  >
                    <Trash2 />
                  </UiButton>
                </span>
              </div>
              {isOpen && (
                <div className="px-3 pb-3">
                  <BlockFields block={b} onChange={(nb) => set(i, nb)} />
                </div>
              )}
            </li>
          );
        })}
      </ol>
      {!full && (
        <div className="mt-3 flex flex-wrap items-center gap-2 border-t border-dashed pt-3">
          <span className="text-[13px] text-muted-foreground">
            <FormattedMessage id="articles.addBlock" />
          </span>
          {textTypes.map((t) => {
            const TIcon = blockIcon[t];
            return (
              <UiButton
                key={t}
                variant="outline"
                size="sm"
                onClick={() => insert(blocks.length, blankBlock(t))}
              >
                <TIcon />
                <FormattedMessage id={`content.block.${t}`} />
              </UiButton>
            );
          })}
          <ImagePickerButton
            label={<FormattedMessage id="content.block.image" />}
            onPick={(image) =>
              insert(blocks.length, { type: 'image', image, caption: '', alt: '' })
            }
          />
        </div>
      )}
    </Section>
  );
}

function BlockFields({
  block,
  onChange,
}: {
  block: ContentBlock;
  onChange: (b: ContentBlock) => void;
}) {
  const intl = useIntl();
  const L = contentLimits;
  switch (block.type) {
    case 'paragraph':
      return (
        <TextField
          label={<FormattedMessage id="content.block.text" />}
          value={block.text}
          max={L.paragraph}
          multiline
          counter
          onChange={(text) => onChange({ ...block, text })}
        />
      );
    case 'heading':
      return (
        <TextField
          label={<FormattedMessage id="content.block.text" />}
          value={block.text}
          max={L.heading}
          counter
          onChange={(text) => onChange({ ...block, text })}
        />
      );
    case 'bullets':
      return (
        <div className="grid gap-2">
          {block.items.map((it, j) => (
            <div key={j} className="grid grid-cols-[12px_minmax(0,1fr)_auto] items-center gap-2">
              <span aria-hidden="true" className="text-muted-foreground">
                •
              </span>
              <Input
                aria-label={intl.formatMessage({ id: 'content.block.item' }, { n: j + 1 })}
                value={it}
                onChange={(e) =>
                  onChange({
                    ...block,
                    items: block.items.map((x, k) => (k === j ? e.target.value : x)),
                  })
                }
              />
              <span className="flex">
                <IconButton
                  icon="up"
                  label={intl.formatMessage({ id: 'content.moveUp' })}
                  disabled={j === 0}
                  onClick={() => {
                    const items = [...block.items];
                    [items[j - 1], items[j]] = [items[j]!, items[j - 1]!];
                    onChange({ ...block, items });
                  }}
                />
                <IconButton
                  icon="remove"
                  label={intl.formatMessage({ id: 'content.remove' })}
                  disabled={block.items.length <= 1}
                  onClick={() =>
                    onChange({ ...block, items: block.items.filter((_, k) => k !== j) })
                  }
                />
              </span>
            </div>
          ))}
          {block.items.length < L.bullets && (
            <div className="pl-5">
              <UiButton
                variant="ghost"
                size="sm"
                className="text-primary"
                onClick={() => onChange({ ...block, items: [...block.items, ''] })}
              >
                <Plus />
                <FormattedMessage id="content.block.addItem" />
              </UiButton>
            </div>
          )}
        </div>
      );
    case 'callout':
      return (
        <div className="grid gap-3">
          <div className="grid gap-3 sm:grid-cols-[minmax(0,12rem)_minmax(0,1fr)]">
            <CalloutTone value={block.tone} onChange={(tone) => onChange({ ...block, tone })} />
            <TextField
              label={<FormattedMessage id="content.block.calloutTitle" />}
              value={block.title}
              max={L.calloutTitle}
              counter
              onChange={(title) => onChange({ ...block, title })}
            />
          </div>
          <TextField
            label={<FormattedMessage id="content.block.text" />}
            value={block.text}
            max={L.calloutText}
            multiline
            counter
            help={
              block.tone === 'urgent' ? (
                <>
                  <FormattedMessage id="content.callout.urgentHelp" /> <EmergencyHint />
                </>
              ) : undefined
            }
            onChange={(text) => onChange({ ...block, text })}
          />
        </div>
      );
    case 'image':
      return (
        <div className="flex items-start gap-3">
          <ImageThumb id={block.image} size={96} />
          <div className="grid min-w-0 flex-1 gap-3">
            <div>
              <ImagePickerButton
                label={<FormattedMessage id="content.image.change" />}
                onPick={(image) => onChange({ ...block, image })}
              />
            </div>
            <TextField
              label={<FormattedMessage id="content.block.caption" />}
              value={block.caption}
              max={L.caption}
              onChange={(caption) => onChange({ ...block, caption })}
            />
            <TextField
              label={<FormattedMessage id="content.block.alt" />}
              value={block.alt}
              max={L.alt}
              onChange={(alt) => onChange({ ...block, alt })}
            />
          </div>
        </div>
      );
  }
}

function CalloutTone({
  value,
  onChange,
}: {
  value: Extract<ContentBlock, { type: 'callout' }>['tone'];
  onChange: (v: Extract<ContentBlock, { type: 'callout' }>['tone']) => void;
}) {
  const intl = useIntl();
  const id = useId();
  return (
    <Field label={<FormattedMessage id="content.block.tone" />} htmlFor={id}>
      <FieldSelect id={id} value={value} options={calloutToneOptions(intl)} onChange={onChange} />
    </Field>
  );
}

/** 4d reader, in the language being edited. */
export function ArticlePreview({
  data,
  lang,
  review,
}: {
  data: ArticleDraft;
  lang: Lang;
  review: Parameters<typeof ReviewLine>[0]['review'];
}) {
  const intl = useIntl();
  const p = (id: string, values?: Record<string, string | number>) =>
    intl.formatMessage({ id: `content.preview.${id}.${lang}` }, values);
  // `{emergency}` reads as the family's number in the app; the preview shows 115 (D-087).
  const shown = useMemo(() => fillEmergency(data), [data]);
  return (
    <PhoneFrame>
      {shown.cover && (
        <div className="cl-phone__hero">
          <ImageThumb id={shown.cover.image} size={340} />
        </div>
      )}
      <div className="cl-phone__body">
        <div className="chips">
          <span className="cl-tag cl-tag--sleep">{p(`topic.${shown.topic}`)}</span>
          <span className="cl-tag">{p('minutes', { n: shown.readingMinutes })}</span>
        </div>
        <h3 className="cl-phone__title">{shown.title[lang] || '—'}</h3>
        <ReviewLine review={review} lang={lang} />
        <BlocksPreview blocks={shown.body[lang]} lang={lang} />
      </div>
    </PhoneFrame>
  );
}
