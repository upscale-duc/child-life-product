import {
  articleContentStrictSchema,
  articleDraftSchema,
  articleFormats,
  articleTopics,
  contentBlockTypes,
  contentLibraries,
  contentLimits,
  readingMinutesOf,
  staffCan,
  type ArticleDraft,
  type ContentBlock,
  type ContentBlockType,
  type EditorialAction,
} from '@child-life/contracts';
import { useEffect, useMemo, useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { ApiError, useApi, useLoad } from '../api';
import { routePaths, subPath, useStaff } from '../context';
import {
  Button,
  Empty,
  Kpi,
  Loaded,
  Page,
  Panel,
  SelectMenu,
  TableScroll,
  errorMessageId,
  useSort,
} from '../ui';
import {
  ActDialog,
  BlocksPreview,
  ContentImagesProvider,
  CoverField,
  ImagePickerButton,
  ImageThumb,
  IssuesList,
  LangTabs,
  LinkPicker,
  NumberField,
  PhoneFrame,
  ReviewLine,
  SeedButton,
  SourcesField,
  StatusCell,
  TextField,
  WorkflowButtons,
  actionsFor,
  ageBands,
  asApiError,
  calloutToneOptions,
  dateTime,
  reviewOf,
  textOf,
  topicOptions,
  useContentList,
  weeksLabel,
  type ContentItemView,
  type ContentListView,
  type ContentRow,
  type Lang,
} from './content-common';
import { FieldSelect, IconButton } from './form-controls';

/**
 * Bài viết (Figma B01 `316:1460`, B02 `317:1558`; D-076 #7): the Thư viện chăm bé articles.
 * B01 lists them with the counts (on the app, waiting, drafts, due for re-review) and filters;
 * B02 edits one in the safe block model (paragraph, heading, list, callout, picture; plain text
 * only), with its settings and a preview of the app reader (4d). Saving keeps a draft; the
 * workflow (Gửi duyệt → Duyệt → Xuất bản) is shared with Duyệt nội dung (B03/B04).
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
  return (
    <Page
      title={<FormattedMessage id="articles.title" />}
      subtitle={<FormattedMessage id="articles.sub" />}
      actions={
        canEdit && (
          <>
            <SeedButton kind="article" onDone={reload} />
            <Button kind="primary" onClick={() => onOpen('new')}>
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
};
const allFilters: Filters = {
  q: '',
  library: 'all',
  topic: 'all',
  age: 'all',
  status: 'all',
  reviewer: 'all',
  lang: 'all',
};

/** B01 filters: library, topic, age band (overlap), status, reviewer, missing language. */
export function filterArticles(rows: ContentRow[], f: Filters): ContentRow[] {
  const q = f.q.trim().toLowerCase();
  const band = ageBands.find((b) => b.id === f.age);
  return rows.filter(
    (r) =>
      (!q || `${r.title.vi} ${r.title.en} ${r.id}`.toLowerCase().includes(q)) &&
      (f.library === 'all' || r.library === f.library) &&
      (f.topic === 'all' || r.topic === f.topic) &&
      (!band || (!!r.ageWeeks && r.ageWeeks.from < band.to && band.from < r.ageWeeks.to)) &&
      (f.status === 'all' || r.displayStatus === f.status) &&
      (f.reviewer === 'all' || (r.reviewerLabel ?? '') === f.reviewer) &&
      (f.lang === 'all' ||
        (f.lang === 'missingEn' ? !r.title.en || !r.blocks?.en : !r.title.vi || !r.blocks?.vi)),
  );
}

export function ArticlesBody({
  view,
  onOpen,
  initialFilters,
}: {
  view: ContentListView;
  onOpen: (id: string) => void;
  initialFilters?: Partial<Filters>;
}) {
  const intl = useIntl();
  const [f, setF] = useState<Filters>({ ...allFilters, ...initialFilters });
  const rows = filterArticles(view.rows, f);
  const reviewers = [...new Set(view.rows.map((r) => r.reviewerLabel ?? '').filter(Boolean))];
  const sorted = useSort(rows, {
    title: (r) => textOf(intl, r.title),
    topic: (r) => r.topic ?? '',
    age: (r) => r.ageWeeks?.from ?? null,
    minutes: (r) => r.readingMinutes ?? null,
    status: (r) => r.displayStatus,
    updated: (r) => r.updatedAt,
  });
  const c = view.counts;
  const opt = (id: string, value: string) => ({ value, label: intl.formatMessage({ id }) });
  return (
    <>
      <div className="kpis">
        <Kpi label={<FormattedMessage id="content.kpi.inApp" />} value={c.inApp} />
        <Kpi
          label={<FormattedMessage id="content.kpi.pending" />}
          value={c.pending}
          tone={c.pending ? 'warn' : 'muted'}
          foot={<FormattedMessage id="content.kpi.pendingFoot" values={{ n: c.approved }} />}
        />
        <Kpi label={<FormattedMessage id="content.kpi.drafts" />} value={c.drafts} />
        <Kpi
          label={<FormattedMessage id="content.kpi.due" />}
          value={c.dueForReview}
          tone={c.dueForReview ? 'error' : 'muted'}
          foot={<FormattedMessage id="content.kpi.dueFoot" />}
        />
      </div>
      <Panel className="panel--flush">
        <div className="toolbar cl-toolbar">
          <input
            className="field__input cl-search"
            type="search"
            value={f.q}
            aria-label={intl.formatMessage({ id: 'articles.search' })}
            placeholder={intl.formatMessage({ id: 'articles.search' })}
            onChange={(e) => setF({ ...f, q: e.target.value })}
          />
          <SelectMenu
            label={intl.formatMessage({ id: 'content.filter.library' })}
            value={f.library}
            onChange={(library) => setF({ ...f, library })}
            options={[
              opt('content.filter.allLibraries', 'all'),
              ...contentLibraries.map((l) => opt(`content.library.${l}`, l)),
            ]}
          />
          <SelectMenu
            label={intl.formatMessage({ id: 'content.filter.topic' })}
            value={f.topic}
            onChange={(topic) => setF({ ...f, topic })}
            options={[opt('content.filter.allTopics', 'all'), ...topicOptions(intl)]}
          />
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
            options={[
              opt('content.filter.allStatuses', 'all'),
              ...(
                [
                  'draft',
                  'in_review',
                  'approved',
                  'published',
                  'needs_rereview',
                  'archived',
                ] as const
              ).map((s) => opt(`content.status.${s}`, s)),
            ]}
          />
          <SelectMenu
            label={intl.formatMessage({ id: 'content.filter.reviewer' })}
            value={f.reviewer}
            onChange={(reviewer) => setF({ ...f, reviewer })}
            options={[
              opt('content.filter.allReviewers', 'all'),
              ...reviewers.map((r) => ({ value: r, label: r })),
            ]}
          />
          <SelectMenu
            label={intl.formatMessage({ id: 'content.filter.lang' })}
            value={f.lang}
            onChange={(lang) => setF({ ...f, lang })}
            options={[
              opt('content.filter.allLangs', 'all'),
              opt('content.filter.missingEn', 'missingEn'),
              opt('content.filter.missingVi', 'missingVi'),
            ]}
          />
        </div>
        {rows.length ? (
          <TableScroll min={900}>
            <table className="table">
              <thead>
                <tr>
                  {sorted.th('title', <FormattedMessage id="content.col.title" />)}
                  {sorted.th('topic', <FormattedMessage id="content.col.topic" />)}
                  {sorted.th('age', <FormattedMessage id="content.col.age" />)}
                  {sorted.th('minutes', <FormattedMessage id="content.col.minutes" />)}
                  {sorted.th('status', <FormattedMessage id="content.col.status" />)}
                  <th>
                    <FormattedMessage id="content.col.reviewer" />
                  </th>
                  {sorted.th('updated', <FormattedMessage id="content.col.updated" />)}
                </tr>
              </thead>
              <tbody>
                {sorted.rows.map((r) => (
                  <tr key={r.id} className="cl-row" onClick={() => onOpen(r.id)}>
                    <td>
                      <button type="button" className="link-button" onClick={() => onOpen(r.id)}>
                        {textOf(intl, r.title) || (
                          <span className="muted">
                            <FormattedMessage id="content.untitled" />
                          </span>
                        )}
                      </button>
                      {r.library === 'solids' && (
                        <span className="muted">
                          {' '}
                          · <FormattedMessage id="content.library.solids" />
                        </span>
                      )}
                    </td>
                    <td>{r.topic && <FormattedMessage id={`content.topic.${r.topic}`} />}</td>
                    <td className="nowrap">{r.ageWeeks ? weeksLabel(intl, r.ageWeeks) : '—'}</td>
                    <td>{r.readingMinutes ?? '—'}</td>
                    <td>
                      <StatusCell row={r} />
                    </td>
                    <td>{r.reviewerLabel ?? <span className="muted">—</span>}</td>
                    <td className="nowrap">
                      {dateTime(intl, r.updatedAt)}
                      <div className="muted">{r.lastEditorName}</div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </TableScroll>
        ) : (
          <Empty>
            <FormattedMessage id={view.rows.length ? 'content.noMatch' : 'articles.empty'} />
          </Empty>
        )}
      </Panel>
    </>
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

function ArticleEditorScreen({
  id,
  onOpen,
}: {
  id: string | null;
  onOpen: (id: string | null) => void;
}) {
  return id ? (
    <ExistingArticle id={id} onOpen={onOpen} />
  ) : (
    <ArticleEditorShell item={null} onOpen={onOpen} reload={() => undefined} />
  );
}

function ExistingArticle({ id, onOpen }: { id: string; onOpen: (id: string | null) => void }) {
  const [item, reload] = useLoad<ContentItemView<ArticleDraft>>(
    'staffContentItem',
    { kind: 'article', id },
    `article:${id}`,
  );
  return (
    <Loaded load={item} reload={reload}>
      {(view) => <ArticleEditorShell item={view} onOpen={onOpen} reload={reload} />}
    </Loaded>
  );
}

function ArticleEditorShell({
  item,
  onOpen,
  reload,
}: {
  item: ContentItemView<ArticleDraft> | null;
  onOpen: (id: string | null) => void;
  reload: () => void;
}) {
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
      />
    </ContentImagesProvider>
  );
}

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
}) {
  const intl = useIntl();
  const api = useApi();
  const [data, setData] = useState<ArticleDraft>(() =>
    item ? structuredClone(item.data) : blankArticle(),
  );
  const [reviewerLabel, setReviewerLabel] = useState(item?.row.reviewerLabel ?? '');
  const [notes, setNotes] = useState(item?.notes ?? '');
  const [dirty, setDirty] = useState(!item);
  const [lang, setLang] = useState<Lang>(initialLang);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const [act, setAct] = useState<EditorialAction | null>(null);
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
  const row = item?.row ?? null;
  const actions = row && !dirty ? actionsFor(row, { edit: canEdit, approve: canApprove }) : [];
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
  return (
    <section className="page cl-editor">
      <header className="cl-editbar">
        <nav className="cl-crumbs" aria-label={intl.formatMessage({ id: 'nav.breadcrumb' })}>
          <button type="button" className="link-button" onClick={onBack}>
            <FormattedMessage id="articles.title" />
          </button>
          <span aria-hidden="true"> › </span>
          <strong>{textOf(intl, data.title) || <FormattedMessage id="articles.new" />}</strong>
        </nav>
        {row && <StatusCell row={row} />}
        <div className="cl-editbar__actions">
          {dirty && (
            <span className="muted" role="status">
              <FormattedMessage id="content.unsaved" />
            </span>
          )}
          {canEdit && (
            <Button kind={dirty ? 'primary' : 'secondary'} disabled={busy || !dirty} onClick={save}>
              <FormattedMessage id={busy ? 'content.saving' : 'content.save'} />
            </Button>
          )}
          <WorkflowButtons
            actions={actions.filter((a) => a !== 'submit' || strict.success)}
            onPick={setAct}
          />
        </div>
      </header>
      {error && (
        <p className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
      {row?.rejection && (
        <p className="note note--warn">
          <FormattedMessage id="content.rejected" values={row.rejection} />
        </p>
      )}
      {row && row.status === 'draft' && <IssuesList issues={issues} />}
      <div className="cols cols--2-1">
        <div className="stack">
          <Panel
            title={<FormattedMessage id="articles.content" />}
            aside={<LangTabs value={lang} onChange={setLang} />}
          >
            <div className="stack">
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
              {lang === 'en' && body.length === 0 && data.body.vi.length > 0 && (
                <Button onClick={() => edit((d) => void (d.body.en = copyStructure(d.body.vi)))}>
                  <FormattedMessage id="articles.copyStructure" />
                </Button>
              )}
              <BlocksEditor
                blocks={body}
                onChange={(blocks) => edit((d) => void (d.body[lang] = blocks))}
              />
            </div>
          </Panel>
        </div>
        <div className="stack">
          <Panel title={<FormattedMessage id="articles.settings" />}>
            <div className="stack">
              <SettingSelect
                label="content.field.library"
                value={data.library}
                options={contentLibraries.map((l) => ({
                  value: l,
                  label: intl.formatMessage({ id: `content.library.${l}` }),
                }))}
                onChange={(v) => edit((d) => void (d.library = v))}
              />
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
              <div className="cl-grid2">
                <NumberField
                  label={<FormattedMessage id="articles.ageFrom" />}
                  value={data.ageWeeks.from}
                  min={0}
                  max={contentLimits.maxAgeWeeks}
                  onChange={(v) => edit((d) => void (d.ageWeeks.from = v))}
                />
                <NumberField
                  label={<FormattedMessage id="articles.ageTo" />}
                  value={data.ageWeeks.to}
                  min={1}
                  max={contentLimits.maxAgeWeeks}
                  onChange={(v) => edit((d) => void (d.ageWeeks.to = v))}
                />
              </div>
              <p className="field__help">
                <FormattedMessage
                  id="articles.ageHelp"
                  values={{
                    label:
                      data.ageWeeks.to > data.ageWeeks.from ? weeksLabel(intl, data.ageWeeks) : '—',
                  }}
                />
              </p>
              <div className="cl-inline">
                <NumberField
                  label={<FormattedMessage id="content.field.readingMinutes" />}
                  value={data.readingMinutes}
                  min={1}
                  max={contentLimits.readingMinutes}
                  onChange={(v) => edit((d) => void (d.readingMinutes = v))}
                />
                <Button
                  kind="ghost"
                  onClick={() => edit((d) => void (d.readingMinutes = readingMinutesOf(d.body.vi)))}
                >
                  <FormattedMessage id="articles.computeMinutes" />
                </Button>
              </div>
              <CoverField
                value={data.cover}
                lang={lang}
                onChange={(v) => edit((d) => void (d.cover = v))}
              />
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
                  <FormattedMessage id="articles.keywords" values={{ lang: lang.toUpperCase() }} />
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
              <SourcesField
                value={data.sources}
                max={contentLimits.articleSources}
                onChange={(v) => edit((d) => void (d.sources = v))}
              />
              <TextField
                label={<FormattedMessage id="content.reviewerLabel" />}
                value={reviewerLabel}
                max={contentLimits.reviewerLabel}
                help={<FormattedMessage id="content.reviewerLabelHelp" />}
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
          </Panel>
          <Panel title={<FormattedMessage id="content.preview" />}>
            <ArticlePreview data={data} lang={lang} review={reviewOf(item)} />
          </Panel>
        </div>
      </div>
      {act && row && (
        <ActDialog
          kind="article"
          id={row.id}
          action={act}
          title={textOf(intl, data.title)}
          requireReview={requireReview}
          today={today}
          sameEditor={item?.lastEditorUid === staffUid}
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
}: {
  label: string;
  value: T;
  options: Array<{ value: T; label: string }>;
  onChange: (v: T) => void;
}) {
  const intl = useIntl();
  return (
    <div className="field">
      <span className="field__label">
        <FormattedMessage id={label} />
      </span>
      <FieldSelect
        value={value}
        options={options}
        ariaLabel={intl.formatMessage({ id: label })}
        onChange={onChange}
      />
    </div>
  );
}

/** The block list for one language: add, edit, move, remove. */
export function BlocksEditor({
  blocks,
  onChange,
}: {
  blocks: ContentBlock[];
  onChange: (b: ContentBlock[]) => void;
}) {
  const intl = useIntl();
  const set = (i: number, b: ContentBlock) => onChange(blocks.map((x, j) => (j === i ? b : x)));
  const move = (i: number, by: number) => {
    const next = [...blocks];
    const [b] = next.splice(i, 1);
    next.splice(i + by, 0, b!);
    onChange(next);
  };
  return (
    <div className="cl-blocks-editor">
      <span className="field__label">
        <FormattedMessage
          id="articles.blocks"
          values={{ n: blocks.length, max: contentLimits.blocks }}
        />
      </span>
      {blocks.map((b, i) => (
        <div key={i} className={`cl-block cl-block--${b.type}`}>
          <div className="cl-block__head">
            <span className="cl-block__kind">
              <FormattedMessage id={`content.block.${b.type}`} />
            </span>
            <span className="cl-block__tools">
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
              <IconButton
                icon="remove"
                label={intl.formatMessage({ id: 'content.remove' })}
                onClick={() => onChange(blocks.filter((_, j) => j !== i))}
              />
            </span>
          </div>
          <BlockFields block={b} onChange={(nb) => set(i, nb)} />
        </div>
      ))}
      {blocks.length < contentLimits.blocks && (
        <div className="actions cl-add">
          {contentBlockTypes
            .filter((t) => t !== 'image')
            .map((t) => (
              <Button key={t} kind="ghost" onClick={() => onChange([...blocks, blankBlock(t)])}>
                <FormattedMessage
                  id="content.addBlock"
                  values={{ kind: intl.formatMessage({ id: `content.block.${t}` }) }}
                />
              </Button>
            ))}
          <ImagePickerButton
            onPick={(image) =>
              onChange([...blocks, { type: 'image', image, caption: '', alt: '' }])
            }
          />
        </div>
      )}
    </div>
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
        <div className="stack cl-tight">
          {block.items.map((it, j) => (
            <div key={j} className="cl-bullet">
              <span aria-hidden="true">•</span>
              <input
                className="field__input"
                aria-label={intl.formatMessage({ id: 'content.block.item' }, { n: j + 1 })}
                value={it}
                onChange={(e) =>
                  onChange({
                    ...block,
                    items: block.items.map((x, k) => (k === j ? e.target.value : x)),
                  })
                }
              />
              <IconButton
                icon="remove"
                label={intl.formatMessage({ id: 'content.remove' })}
                disabled={block.items.length <= 1}
                onClick={() => onChange({ ...block, items: block.items.filter((_, k) => k !== j) })}
              />
            </div>
          ))}
          {block.items.length < L.bullets && (
            <Button
              kind="ghost"
              onClick={() => onChange({ ...block, items: [...block.items, ''] })}
            >
              <FormattedMessage id="content.block.addItem" />
            </Button>
          )}
        </div>
      );
    case 'callout':
      return (
        <div className="stack cl-tight">
          <div className="field">
            <span className="field__label">
              <FormattedMessage id="content.block.tone" />
            </span>
            <FieldSelect
              value={block.tone}
              options={calloutToneOptions(intl)}
              ariaLabel={intl.formatMessage({ id: 'content.block.tone' })}
              onChange={(tone) => onChange({ ...block, tone })}
            />
          </div>
          <TextField
            label={<FormattedMessage id="content.block.calloutTitle" />}
            value={block.title}
            max={L.calloutTitle}
            counter
            onChange={(title) => onChange({ ...block, title })}
          />
          <TextField
            label={<FormattedMessage id="content.block.text" />}
            value={block.text}
            max={L.calloutText}
            multiline
            counter
            onChange={(text) => onChange({ ...block, text })}
          />
        </div>
      );
    case 'image':
      return (
        <div className="cl-cover">
          <ImageThumb id={block.image} />
          <div className="stack cl-tight">
            <ImagePickerButton onPick={(image) => onChange({ ...block, image })} />
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
  return (
    <PhoneFrame>
      {data.cover && (
        <div className="cl-phone__hero">
          <ImageThumb id={data.cover.image} size={340} />
        </div>
      )}
      <div className="cl-phone__body">
        <div className="chips">
          <span className="cl-tag cl-tag--sleep">{p(`topic.${data.topic}`)}</span>
          <span className="cl-tag">{p('minutes', { n: data.readingMinutes })}</span>
        </div>
        <h3 className="cl-phone__title">{data.title[lang] || '—'}</h3>
        <ReviewLine review={review} lang={lang} />
        <BlocksPreview blocks={data.body[lang]} />
      </div>
    </PhoneFrame>
  );
}
