import {
  contentLimits,
  memberRoles,
  stageBuckets,
  stageContentStrictSchema,
  stageDraftSchema,
  stageUnits,
  staffCan,
  type EditorialAction,
  type StageDraft,
  type StageUnit,
} from '@child-life/contracts';
import { useEffect, useMemo, useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { ApiError, useApi, useLoad } from '../api';
import { routePaths, subPath, useStaff } from '../context';
import {
  Button,
  Empty,
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
  AudienceField,
  ContentImagesProvider,
  CoverField,
  ImageThumb,
  IssuesList,
  LangTabs,
  LinkPicker,
  NumberField,
  PhoneFrame,
  PointsField,
  ReviewLine,
  SeedButton,
  SourcesField,
  StatusCell,
  TextField,
  WorkflowButtons,
  actionsFor,
  asApiError,
  dateTime,
  reviewOf,
  stageAgeText,
  textOf,
  useContentList,
  weeksLabel,
  type ContentItemView,
  type ContentListView,
  type ContentRow,
  type CoverageBucket,
  type Lang,
} from './content-common';
import { FieldSelect } from './form-controls';

/**
 * Nội dung theo giai đoạn (Figma B05 `319:2030`, B06 `319:2345`; D-076 #5): the content the app
 * shows as "Giai đoạn của bé" (was "Thẻ theo tuổi") for the baby's age, counted from the date of
 * birth. B05 shows the 0–24 month coverage over 16 fixed ranges ("14 / 16 khoảng có nội dung")
 * with the gaps, and the list; B06 edits one: age range, title (60), up to 3 "Bé đang thế nào"
 * and 3 "Ba mẹ có thể thử", related articles (2) and milestones, audience, preview of 2b.
 */

type Path = { id: string | null; bucket: string | null } | null;

function pathOf(segments: string[]): Path {
  if (!segments[0]) return null;
  if (segments[0] === 'new') return { id: null, bucket: segments[1] ?? null };
  return { id: segments[0], bucket: null };
}

export function StagesScreen() {
  const [path, setPath] = useState(() => pathOf(subPath('stages', window.location.pathname)));
  useEffect(() => {
    const onPop = () => setPath(pathOf(subPath('stages', window.location.pathname)));
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, []);
  const go = (next: Path) => {
    const url = !next
      ? routePaths.stages
      : next.id
        ? `${routePaths.stages}/${encodeURIComponent(next.id)}`
        : `${routePaths.stages}/new${next.bucket ? `/${next.bucket}` : ''}`;
    if (window.location.pathname !== url) window.history.pushState({}, '', url);
    setPath(next);
    window.scrollTo(0, 0);
  };
  return path ? (
    path.id ? (
      <ExistingStage key={path.id} id={path.id} go={go} />
    ) : (
      <StageEditorShell
        key={`new:${path.bucket}`}
        item={null}
        bucket={path.bucket}
        go={go}
        reload={() => undefined}
      />
    )
  ) : (
    <StagesListScreen go={go} />
  );
}

function StagesListScreen({ go }: { go: (p: Path) => void }) {
  const staff = useStaff();
  const [load, reload] = useContentList('stage');
  const canEdit = staffCan(staff.levels, 'content.edit');
  return (
    <Page
      title={<FormattedMessage id="stages.title" />}
      subtitle={<FormattedMessage id="stages.sub" />}
      actions={
        canEdit && (
          <>
            <SeedButton kind="stage" onDone={reload} />
            <Button kind="primary" onClick={() => go({ id: null, bucket: null })}>
              <FormattedMessage id="stages.new" />
            </Button>
          </>
        )
      }
    >
      <Loaded load={load} reload={reload}>
        {(view) => (
          <StagesBody
            view={view}
            canEdit={canEdit}
            onOpen={(id) => go({ id, bucket: null })}
            onCreate={(bucket) => go({ id: null, bucket })}
          />
        )}
      </Loaded>
    </Page>
  );
}

const bucketTone: Record<CoverageBucket['state'], string> = {
  published: 'cl-cov--published',
  pending: 'cl-cov--pending',
  draft: 'cl-cov--draft',
  missing: 'cl-cov--missing',
};

/** B05 "Độ phủ 0–24 tháng": one bar per range; a bar opens its item or starts one. */
export function CoverageStrip({
  buckets,
  covered,
  total,
  canEdit,
  onOpen,
  onCreate,
}: {
  buckets: CoverageBucket[];
  covered: number;
  total: number;
  canEdit: boolean;
  onOpen: (id: string) => void;
  onCreate: (bucket: string) => void;
}) {
  const intl = useIntl();
  const gaps = buckets.filter((b) => b.state === 'missing');
  return (
    <Panel
      title={<FormattedMessage id="stages.coverage" />}
      aside={
        <strong>
          <FormattedMessage id="stages.covered" values={{ n: covered, total }} />
        </strong>
      }
    >
      <ol className="cl-coverage">
        {buckets.map((b) => {
          const label = stageAgeText(intl, b);
          const state = intl.formatMessage({ id: `stages.state.${b.state}` });
          const target = b.itemIds[0];
          const disabled = !target && !canEdit;
          return (
            <li key={b.id}>
              <button
                type="button"
                className={`cl-cov ${bucketTone[b.state]}`}
                title={`${label} · ${state}`}
                aria-label={`${label} · ${state}`}
                disabled={disabled}
                onClick={() => (target ? onOpen(target) : onCreate(b.id))}
              />
              <span className="cl-cov__label">{label}</span>
            </li>
          );
        })}
      </ol>
      <ul className="cl-legend">
        {(['published', 'pending', 'draft'] as const).map((s) => (
          <li key={s}>
            <span className={`cl-dot ${bucketTone[s]}`} aria-hidden="true" />
            <FormattedMessage id={`stages.state.${s}`} />
          </li>
        ))}
        <li className={gaps.length ? 'error' : 'muted'}>
          <span className={`cl-dot ${bucketTone.missing}`} aria-hidden="true" />
          {gaps.length ? (
            <FormattedMessage
              id="stages.gaps"
              values={{ list: gaps.map((b) => stageAgeText(intl, b)).join(', ') }}
            />
          ) : (
            <FormattedMessage id="stages.noGaps" />
          )}
        </li>
      </ul>
    </Panel>
  );
}

export function StagesBody({
  view,
  canEdit,
  onOpen,
  onCreate,
}: {
  view: ContentListView;
  canEdit: boolean;
  onOpen: (id: string) => void;
  onCreate: (bucket: string) => void;
}) {
  const intl = useIntl();
  const [q, setQ] = useState('');
  const [status, setStatus] = useState('all');
  const [audience, setAudience] = useState('all');
  const rows = view.rows.filter(
    (r) =>
      (!q.trim() || `${r.title.vi} ${r.title.en}`.toLowerCase().includes(q.trim().toLowerCase())) &&
      (status === 'all' || r.displayStatus === status) &&
      (audience === 'all' || (r.audience ?? []).includes(audience as (typeof memberRoles)[number])),
  );
  const ageDays = (r: ContentRow) =>
    r.age ? (r.age.unit === 'week' ? r.age.from * 7 : r.age.from * 30.44) : null;
  const sorted = useSort(rows, {
    age: ageDays,
    title: (r) => textOf(intl, r.title),
    status: (r) => r.displayStatus,
    updated: (r) => r.updatedAt,
  });
  // B05 lists by age by default (the drawn order is neither by age nor by update).
  const shown = useMemo(
    () =>
      sorted.rows === rows
        ? [...rows].sort((a, b) => (ageDays(a) ?? 0) - (ageDays(b) ?? 0))
        : sorted.rows,
    [sorted.rows, rows],
  );
  const opt = (id: string, value: string) => ({ value, label: intl.formatMessage({ id }) });
  return (
    <>
      {view.coverage && (
        <CoverageStrip
          buckets={view.coverage.buckets}
          covered={view.coverage.covered}
          total={view.coverage.total}
          canEdit={canEdit}
          onOpen={onOpen}
          onCreate={onCreate}
        />
      )}
      <Panel className="panel--flush">
        <div className="toolbar cl-toolbar">
          <input
            className="field__input cl-search"
            type="search"
            value={q}
            aria-label={intl.formatMessage({ id: 'stages.search' })}
            placeholder={intl.formatMessage({ id: 'stages.search' })}
            onChange={(e) => setQ(e.target.value)}
          />
          <SelectMenu
            label={intl.formatMessage({ id: 'content.filter.status' })}
            value={status}
            onChange={setStatus}
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
            label={intl.formatMessage({ id: 'content.audience' })}
            value={audience}
            onChange={setAudience}
            options={[
              opt('stages.audienceAll', 'all'),
              ...memberRoles.map((r) => opt(`content.audience.${r}`, r)),
            ]}
          />
        </div>
        {shown.length ? (
          <TableScroll min={860}>
            <table className="table">
              <thead>
                <tr>
                  {sorted.th('age', <FormattedMessage id="content.col.age" />)}
                  {sorted.th('title', <FormattedMessage id="content.col.title" />)}
                  <th>
                    <FormattedMessage id="stages.col.points" />
                  </th>
                  <th>
                    <FormattedMessage id="stages.col.articles" />
                  </th>
                  <th>
                    <FormattedMessage id="stages.col.milestones" />
                  </th>
                  {sorted.th('status', <FormattedMessage id="content.col.status" />)}
                  {sorted.th('updated', <FormattedMessage id="content.col.updated" />)}
                </tr>
              </thead>
              <tbody>
                {shown.map((r) => (
                  <tr key={r.id} className="cl-row" onClick={() => onOpen(r.id)}>
                    <td className="nowrap">{r.age ? stageAgeText(intl, r.age) : '—'}</td>
                    <td>
                      <button type="button" className="link-button" onClick={() => onOpen(r.id)}>
                        {textOf(intl, r.title) || (
                          <span className="muted">
                            <FormattedMessage id="content.untitled" />
                          </span>
                        )}
                      </button>
                    </td>
                    <td className="nowrap">
                      <FormattedMessage
                        id="stages.points"
                        values={{
                          doing: r.points?.doing ?? 0,
                          tryThis: r.points?.tryThis ?? 0,
                          max: contentLimits.stagePoints,
                        }}
                      />
                    </td>
                    <td>
                      {r.links.articles.length}/{contentLimits.stageArticles}
                    </td>
                    <td>{r.links.milestones.length}</td>
                    <td>
                      <StatusCell row={r} />
                    </td>
                    <td className="nowrap">{dateTime(intl, r.updatedAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </TableScroll>
        ) : (
          <Empty>
            <FormattedMessage id={view.rows.length ? 'content.noMatch' : 'stages.empty'} />
          </Empty>
        )}
      </Panel>
    </>
  );
}

// ---------- B06 editor ----------

export function blankStage(bucketId: string | null): StageDraft {
  const b = stageBuckets.find((x) => x.id === bucketId);
  return {
    age: b ? { unit: b.unit, from: b.from, to: b.to } : { unit: 'week', from: 0, to: 3 },
    title: { vi: '', en: '' },
    doing: { vi: [], en: [] },
    tryThis: { vi: [], en: [] },
    articleIds: [],
    milestoneIds: [],
    audience: ['coParent', 'caregiver'],
    cover: null,
    sources: [],
  };
}

function ExistingStage({ id, go }: { id: string; go: (p: Path) => void }) {
  const [item, reload] = useLoad<ContentItemView<StageDraft>>(
    'staffContentItem',
    { kind: 'stage', id },
    `stage:${id}`,
  );
  return (
    <Loaded load={item} reload={reload}>
      {(view) => <StageEditorShell item={view} bucket={null} go={go} reload={reload} />}
    </Loaded>
  );
}

function StageEditorShell({
  item,
  bucket,
  go,
  reload,
}: {
  item: ContentItemView<StageDraft> | null;
  bucket: string | null;
  go: (p: Path) => void;
  reload: () => void;
}) {
  const staff = useStaff();
  const [stages] = useContentList('stage');
  const [articles] = useContentList('article');
  const [milestones] = useContentList('milestone');
  const canEdit = staffCan(staff.levels, 'content.edit');
  const ok = stages.status === 'ok' ? stages.data : null;
  return (
    <ContentImagesProvider canUpload={canEdit}>
      <StageEditor
        key={item ? `${item.row.id}:${item.row.updatedAt}` : `new:${bucket}`}
        item={item}
        bucket={bucket}
        articles={articles.status === 'ok' ? articles.data.rows : []}
        milestones={milestones.status === 'ok' ? milestones.data.rows : []}
        requireReview={ok?.requireReview ?? false}
        today={ok?.today ?? new Date().toISOString().slice(0, 10)}
        staffUid={staff.uid}
        canEdit={canEdit}
        canApprove={staffCan(staff.levels, 'content.approve')}
        onBack={() => go(null)}
        onSaved={(newId) => (newId !== item?.row.id ? go({ id: newId, bucket: null }) : reload())}
        onChanged={reload}
      />
    </ContentImagesProvider>
  );
}

export function StageEditor({
  item,
  bucket,
  articles,
  milestones,
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
  item: ContentItemView<StageDraft> | null;
  bucket: string | null;
  articles: ContentRow[];
  milestones: ContentRow[];
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
  const [data, setData] = useState<StageDraft>(() =>
    item ? structuredClone(item.data) : blankStage(bucket),
  );
  const [reviewerLabel, setReviewerLabel] = useState(item?.row.reviewerLabel ?? '');
  const [notes, setNotes] = useState(item?.notes ?? '');
  const [dirty, setDirty] = useState(!item);
  const [lang, setLang] = useState<Lang>(initialLang);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const [act, setAct] = useState<EditorialAction | null>(null);
  const edit = (fn: (d: StageDraft) => void) => {
    setData((d) => {
      const next = structuredClone(d);
      fn(next);
      return next;
    });
    setDirty(true);
  };
  const strict = useMemo(() => stageContentStrictSchema.safeParse(data), [data]);
  const row = item?.row ?? null;
  const actions = row && !dirty ? actionsFor(row, { edit: canEdit, approve: canApprove }) : [];
  const ageOk = Number.isInteger(data.age.from) && data.age.to > data.age.from;
  const save = () => {
    if (!stageDraftSchema.safeParse(data).success) {
      setError(new ApiError('invalid-argument', null));
      return;
    }
    setBusy(true);
    setError(null);
    api
      .call<{ id: string }>('staffContentSave', {
        kind: 'stage',
        id: row?.id ?? null,
        data,
        reviewerLabel: reviewerLabel.trim() || null,
        notes: notes.trim(),
      })
      .then((r) => {
        setDirty(false);
        onSaved(r.id);
      })
      .catch((e: unknown) => setError(asApiError(e)))
      .finally(() => setBusy(false));
  };
  const articleOptions = articles
    .filter((a) => a.status !== 'archived')
    .map((a) => ({
      id: a.id,
      title: textOf(intl, a.title) || a.id,
      meta: a.ageWeeks ? weeksLabel(intl, a.ageWeeks) : '',
    }));
  const milestoneOptions = milestones
    .filter((m) => m.status !== 'archived')
    .map((m) => ({ id: m.id, title: textOf(intl, m.title) || m.id }));
  const ageLabel = ageOk ? stageAgeText(intl, data.age) : '—';
  return (
    <section className="page cl-editor">
      <header className="cl-editbar">
        <nav className="cl-crumbs" aria-label={intl.formatMessage({ id: 'nav.breadcrumb' })}>
          <button type="button" className="link-button" onClick={onBack}>
            <FormattedMessage id="stages.title" />
          </button>
          <span aria-hidden="true"> › </span>
          <strong>{ageLabel}</strong>
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
      {row && row.status === 'draft' && (
        <IssuesList issues={strict.success ? [] : strict.error.issues} />
      )}
      <div className="cols cols--2-1">
        <Panel
          aside={<LangTabs value={lang} onChange={setLang} />}
          title={<FormattedMessage id="stages.card" />}
        >
          <div className="stack">
            <fieldset className="field">
              <legend className="field__label">
                <FormattedMessage id="stages.ageRange" />
              </legend>
              <div className="cl-grid3">
                <div className="field">
                  <span className="field__label">
                    <FormattedMessage id="stages.unit" />
                  </span>
                  <FieldSelect<StageUnit>
                    value={data.age.unit}
                    ariaLabel={intl.formatMessage({ id: 'stages.unit' })}
                    options={stageUnits.map((u) => ({
                      value: u,
                      label: intl.formatMessage({ id: `stages.unit.${u}` }),
                    }))}
                    onChange={(unit) => edit((d) => void (d.age.unit = unit))}
                  />
                </div>
                <NumberField
                  label={<FormattedMessage id="stages.from" />}
                  value={data.age.from}
                  min={0}
                  max={contentLimits.maxAgeWeeks}
                  onChange={(v) => edit((d) => void (d.age.from = v))}
                />
                <NumberField
                  label={<FormattedMessage id="stages.to" />}
                  value={data.age.to}
                  min={1}
                  max={contentLimits.maxAgeWeeks}
                  onChange={(v) => edit((d) => void (d.age.to = v))}
                />
              </div>
              <p className="field__help">
                <FormattedMessage id="stages.ageHelp" values={{ label: ageLabel }} />
              </p>
            </fieldset>
            <TextField
              label={<FormattedMessage id="stages.titleField" />}
              value={data.title[lang]}
              max={contentLimits.stageTitle}
              counter
              onChange={(v) => edit((d) => void (d.title[lang] = v))}
            />
            <PointsField
              key={`doing-${lang}`}
              label={<FormattedMessage id="stages.doing" />}
              value={data.doing[lang]}
              max={contentLimits.stagePoints}
              itemMax={contentLimits.stagePoint}
              onChange={(v) => edit((d) => void (d.doing[lang] = v))}
            />
            <PointsField
              key={`try-${lang}`}
              label={<FormattedMessage id="stages.tryThis" />}
              value={data.tryThis[lang]}
              max={contentLimits.stagePoints}
              itemMax={contentLimits.stagePoint}
              onChange={(v) => edit((d) => void (d.tryThis[lang] = v))}
            />
            <LinkPicker
              label={<FormattedMessage id="stages.articles" />}
              value={data.articleIds}
              options={articleOptions}
              max={contentLimits.stageArticles}
              tone="mint"
              onChange={(v) => edit((d) => void (d.articleIds = v))}
            />
            <LinkPicker
              label={<FormattedMessage id="stages.milestones" />}
              value={data.milestoneIds}
              options={milestoneOptions}
              max={contentLimits.stageMilestones}
              tone="peach"
              onChange={(v) => edit((d) => void (d.milestoneIds = v))}
            />
            <AudienceField
              value={data.audience}
              onChange={(v) => edit((d) => void (d.audience = v))}
            />
            <CoverField
              value={data.cover}
              lang={lang}
              onChange={(v) => edit((d) => void (d.cover = v))}
            />
            <SourcesField
              value={data.sources}
              max={contentLimits.stageSources}
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
          <StagePreview
            data={data}
            lang={lang}
            articles={articles}
            milestones={milestones}
            review={reviewOf(item)}
          />
        </Panel>
      </div>
      {act && row && (
        <ActDialog
          kind="stage"
          id={row.id}
          action={act}
          title={`${ageLabel} · ${textOf(intl, data.title)}`}
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

/** 2b "Chi tiết giai đoạn", in the language being edited, with the sample baby "Teddy". */
export function StagePreview({
  data,
  lang,
  articles,
  milestones,
  review,
}: {
  data: StageDraft;
  lang: Lang;
  articles: ContentRow[];
  milestones: ContentRow[];
  review: Parameters<typeof ReviewLine>[0]['review'];
}) {
  const intl = useIntl();
  const p = (id: string, values?: Record<string, string | number>) =>
    intl.formatMessage({ id: `content.preview.${id}.${lang}` }, values);
  const range =
    data.age.unit === 'week'
      ? p('weeks', { from: data.age.from, to: data.age.to - 1 })
      : p('months', { from: data.age.from, to: data.age.to });
  return (
    <PhoneFrame>
      {data.cover && (
        <div className="cl-phone__hero">
          <ImageThumb id={data.cover.image} size={340} />
        </div>
      )}
      <div className="cl-phone__body">
        <div className="chips">
          <span className="cl-tag cl-tag--sunshine">{range}</span>
          <span className="cl-tag">{p('sampleBaby')}</span>
        </div>
        <h3 className="cl-phone__title">{data.title[lang] || '—'}</h3>
        <div className="cl-phone__card">
          <strong>{p('doing')}</strong>
          <ul>
            {data.doing[lang].map((x, i) => (
              <li key={i}>{x}</li>
            ))}
          </ul>
        </div>
        <div className="cl-phone__card">
          <strong>{p('tryThis')}</strong>
          <ul>
            {data.tryThis[lang].map((x, i) => (
              <li key={i}>{x}</li>
            ))}
          </ul>
        </div>
        {data.milestoneIds.length > 0 && (
          <div className="cl-phone__card">
            <strong>{p('milestones')}</strong>
            <ul>
              {data.milestoneIds.map((id) => {
                const m = milestones.find((x) => x.id === id);
                return <li key={id}>{m ? m.title[lang] || m.title.vi : id}</li>;
              })}
            </ul>
          </div>
        )}
        {data.articleIds.length > 0 && (
          <div className="cl-phone__card">
            <strong>{p('articles')}</strong>
            <ul>
              {data.articleIds.map((id) => {
                const a = articles.find((x) => x.id === id);
                return (
                  <li key={id}>
                    {a ? a.title[lang] || a.title.vi : id}
                    {a?.readingMinutes ? (
                      <span className="muted"> · {p('minutes', { n: a.readingMinutes })}</span>
                    ) : null}
                  </li>
                );
              })}
            </ul>
          </div>
        )}
        <ReviewLine review={review} lang={lang} />
        <p className="cl-foot">{p('ownPace')}</p>
      </div>
    </PhoneFrame>
  );
}
