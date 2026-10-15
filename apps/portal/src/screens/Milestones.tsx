import {
  milestoneGroups,
  milestoneLimits,
  milestoneSeedSchema,
  referenceMilestoneContentSchema,
  referenceMilestoneDraftSchema,
  staffCan,
  type EditorialAction,
  type MilestoneGroup,
  type ReferenceMilestoneDraft,
} from '@child-life/contracts';
import { useEffect, useId, useMemo, useState } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { ApiError, useApi, useLoad } from '../api';
import { routePaths, subPath, useStaff } from '../context';
import {
  Button,
  Empty,
  Kpi,
  Loaded,
  LockNote,
  Page,
  Panel,
  SelectMenu,
  TableScroll,
  errorMessageId,
} from '../ui';
import {
  ActDialog,
  ContentImagesProvider,
  ImagePickerButton,
  ImageThumb,
  IssuesList,
  LangTabs,
  NumberField,
  PhoneFrame,
  ReviewLine,
  SourcesField,
  StatusCell,
  TextField,
  WorkflowButtons,
  actionsFor,
  asApiError,
  dateTime,
  reviewOf,
  textOf,
  useContentList,
  type ContentItemView,
  type ContentListView,
  type ContentRow,
  type Lang,
} from './content-common';
import { CheckRow, FieldSelect, FilePicker } from './form-controls';

/**
 * Mốc phát triển (Figma B07 `319:44574`, B08 `319:44815`; D-076 #6): the reference milestones the
 * app suggests around the baby's age (3a–3g). The schema is the milestones slice's
 * (`packages/contracts/src/milestones.ts`); the workflow is the editorial one. The app never
 * judges early or late, so the list says so. "Ba mẹ đã ghi" counts are not shown: they need a
 * privacy-reviewed aggregate that does not exist yet.
 */

type Path = { id: string | null } | null;

export function MilestonesScreen() {
  const [path, setPath] = useState<Path>(() =>
    pathOf(subPath('milestones', window.location.pathname)),
  );
  useEffect(() => {
    const onPop = () => setPath(pathOf(subPath('milestones', window.location.pathname)));
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, []);
  const go = (next: Path) => {
    const url = !next
      ? routePaths.milestones
      : `${routePaths.milestones}/${next.id ? encodeURIComponent(next.id) : 'new'}`;
    if (window.location.pathname !== url) window.history.pushState({}, '', url);
    setPath(next);
    window.scrollTo(0, 0);
  };
  if (!path) return <MilestonesListScreen go={go} />;
  return path.id ? (
    <ExistingMilestone key={path.id} id={path.id} go={go} />
  ) : (
    <MilestoneEditorShell item={null} go={go} reload={() => undefined} />
  );
}

function pathOf(segments: string[]): Path {
  if (!segments[0]) return null;
  return { id: segments[0] === 'new' ? null : segments[0] };
}

function MilestonesListScreen({ go }: { go: (p: Path) => void }) {
  const staff = useStaff();
  const [load, reload] = useContentList('milestone');
  const canEdit = staffCan(staff.levels, 'content.edit');
  return (
    <Page
      title={<FormattedMessage id="milestones.title" />}
      subtitle={<FormattedMessage id="milestones.sub" />}
      actions={
        canEdit && (
          <>
            <MilestoneSeedButton onDone={reload} />
            <Button kind="primary" onClick={() => go({ id: null })}>
              <FormattedMessage id="milestones.new" />
            </Button>
          </>
        )
      }
    >
      <Loaded load={load} reload={reload}>
        {(view) => <MilestonesBody view={view} onOpen={(id) => go({ id })} />}
      </Loaded>
    </Page>
  );
}

/** "tham khảo 1–3 tháng": both ends inclusive (milestones.ts). */
export function milestoneAgeText(
  intl: IntlShape,
  r: { unit: 'weeks' | 'months'; from: number; to: number },
) {
  return intl.formatMessage(
    { id: r.unit === 'weeks' ? 'content.age.weeks' : 'content.age.months' },
    { from: r.from, to: r.to },
  );
}

type AgeRange = { unit: 'weeks' | 'months'; from: number; to: number };
const ageRangeOf = (r: ContentRow) => r.ageRange as AgeRange | undefined;
const daysOf = (r: AgeRange | undefined) =>
  r ? (r.unit === 'weeks' ? r.from * 7 : r.from * 30.44) : 0;

export function MilestonesBody({
  view,
  onOpen,
}: {
  view: ContentListView;
  onOpen: (id: string) => void;
}) {
  const intl = useIntl();
  const [q, setQ] = useState('');
  const [group, setGroup] = useState('all');
  const [status, setStatus] = useState('all');
  const rows = view.rows.filter(
    (r) =>
      (!q.trim() ||
        `${r.title.vi} ${r.title.en} ${r.id}`.toLowerCase().includes(q.trim().toLowerCase())) &&
      (group === 'all' || r.group === group) &&
      (status === 'all' || r.displayStatus === status),
  );
  const byGroup = milestoneGroups
    .map((g) => ({
      group: g,
      rows: rows
        .filter((r) => r.group === g)
        .sort(
          (a, b) =>
            Number(a.order ?? 0) - Number(b.order ?? 0) ||
            daysOf(ageRangeOf(a)) - daysOf(ageRangeOf(b)) ||
            a.id.localeCompare(b.id),
        ),
    }))
    .filter((g) => g.rows.length);
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
        />
        <Kpi label={<FormattedMessage id="content.kpi.drafts" />} value={c.drafts} />
        <Kpi
          label={<FormattedMessage id="content.kpi.due" />}
          value={c.dueForReview}
          tone={c.dueForReview ? 'error' : 'muted'}
        />
      </div>
      <LockNote>
        <FormattedMessage id="milestones.noJudgement" />
      </LockNote>
      <Panel className="panel--flush">
        <div className="toolbar cl-toolbar">
          <input
            className="field__input cl-search"
            type="search"
            value={q}
            aria-label={intl.formatMessage({ id: 'milestones.search' })}
            placeholder={intl.formatMessage({ id: 'milestones.search' })}
            onChange={(e) => setQ(e.target.value)}
          />
          <SelectMenu
            label={intl.formatMessage({ id: 'milestones.group' })}
            value={group}
            onChange={setGroup}
            options={[
              opt('milestones.allGroups', 'all'),
              ...milestoneGroups.map((g) => opt(`milestones.group.${g}`, g)),
            ]}
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
        </div>
        {byGroup.length ? (
          <TableScroll min={760}>
            <table className="table">
              <thead>
                <tr>
                  <th>
                    <FormattedMessage id="milestones.col.order" />
                  </th>
                  <th>
                    <FormattedMessage id="content.col.title" />
                  </th>
                  <th>
                    <FormattedMessage id="milestones.col.age" />
                  </th>
                  <th>
                    <FormattedMessage id="content.col.status" />
                  </th>
                  <th>
                    <FormattedMessage id="content.col.updated" />
                  </th>
                </tr>
              </thead>
              {byGroup.map((g) => (
                <tbody key={g.group}>
                  <tr className="cl-group-row">
                    <th colSpan={5} scope="rowgroup">
                      <FormattedMessage id={`milestones.group.${g.group}`} />{' '}
                      <span className="muted">· {g.rows.length}</span>
                    </th>
                  </tr>
                  {g.rows.map((r) => {
                    const age = ageRangeOf(r);
                    return (
                      <tr key={r.id} className="cl-row" onClick={() => onOpen(r.id)}>
                        <td>{String(r.order ?? '—')}</td>
                        <td>
                          <button
                            type="button"
                            className="link-button"
                            onClick={() => onOpen(r.id)}
                          >
                            {textOf(intl, r.title) || r.id}
                          </button>
                        </td>
                        <td className="nowrap">{age ? milestoneAgeText(intl, age) : '—'}</td>
                        <td>
                          <StatusCell row={r} />
                        </td>
                        <td className="nowrap">{dateTime(intl, r.updatedAt)}</td>
                      </tr>
                    );
                  })}
                </tbody>
              ))}
            </table>
          </TableScroll>
        ) : (
          <Empty>
            <FormattedMessage id={view.rows.length ? 'content.noMatch' : 'milestones.empty'} />
          </Empty>
        )}
      </Panel>
    </>
  );
}

/**
 * "Nhập bản nháp mẫu": the milestones slice's seed file (`content/milestones/milestones.seed.json`),
 * checked here and on the server; ids already there are left alone.
 */
function MilestoneSeedButton({ onDone }: { onDone: () => void }) {
  const api = useApi();
  const id = useId();
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<{ added: number; skipped: number } | null>(null);
  const [problem, setProblem] = useState<string | null>(null);
  const [error, setError] = useState<ApiError | null>(null);
  return (
    <>
      <Button onClick={() => setOpen(true)}>
        <FormattedMessage id="content.seed" />
      </Button>
      {open && (
        <div className="cl-seed-file">
          <FilePicker
            id={id}
            accept="application/json,.json"
            label={<FormattedMessage id="milestones.seedFile" />}
            onFile={(file) => {
              setProblem(null);
              setError(null);
              setResult(null);
              if (!file) return;
              setBusy(true);
              file
                .text()
                .then((t) => {
                  const seed: unknown = JSON.parse(t);
                  if (!milestoneSeedSchema.safeParse(seed).success) {
                    setProblem('milestones.seedInvalid');
                    return;
                  }
                  return api
                    .call<{ added: Record<string, number>; skipped: number }>('staffContentSeed', {
                      kinds: ['milestone'],
                      milestoneSeed: seed,
                    })
                    .then((r) => {
                      setResult({ added: r.added.milestone ?? 0, skipped: r.skipped });
                      onDone();
                    });
                })
                .catch((e: unknown) =>
                  e instanceof SyntaxError
                    ? setProblem('milestones.seedInvalid')
                    : setError(asApiError(e)),
                )
                .finally(() => setBusy(false));
            }}
          />
          {busy && (
            <span className="muted" role="status">
              <FormattedMessage id="state.loading" />
            </span>
          )}
          {result && (
            <span className="muted" role="status">
              <FormattedMessage id="content.seedDone" values={result} />
            </span>
          )}
          {problem && (
            <span className="error" role="alert">
              <FormattedMessage id={problem} />
            </span>
          )}
          {error && (
            <span className="error" role="alert">
              <FormattedMessage id={errorMessageId(error)} />
            </span>
          )}
        </div>
      )}
    </>
  );
}

// ---------- B08 editor ----------

export function blankMilestone(): ReferenceMilestoneDraft {
  return {
    group: 'motor',
    order: 10,
    ageRange: { unit: 'months', from: 1, to: 3 },
    title: { vi: '', en: '' },
    howToRecognise: { vi: '', en: '' },
    talkToDoctor: null,
    illustration: null,
    sources: [],
  };
}

function ExistingMilestone({ id, go }: { id: string; go: (p: Path) => void }) {
  const [item, reload] = useLoad<ContentItemView<ReferenceMilestoneDraft>>(
    'staffContentItem',
    { kind: 'milestone', id },
    `milestone:${id}`,
  );
  return (
    <Loaded load={item} reload={reload}>
      {(view) => <MilestoneEditorShell item={view} go={go} reload={reload} />}
    </Loaded>
  );
}

function MilestoneEditorShell({
  item,
  go,
  reload,
}: {
  item: ContentItemView<ReferenceMilestoneDraft> | null;
  go: (p: Path) => void;
  reload: () => void;
}) {
  const staff = useStaff();
  const [list] = useContentList('milestone');
  const canEdit = staffCan(staff.levels, 'content.edit');
  const ok = list.status === 'ok' ? list.data : null;
  return (
    <ContentImagesProvider canUpload={canEdit}>
      <MilestoneEditor
        key={item ? `${item.row.id}:${item.row.updatedAt}` : 'new'}
        item={item}
        requireReview={ok?.requireReview ?? false}
        today={ok?.today ?? new Date().toISOString().slice(0, 10)}
        staffUid={staff.uid}
        canEdit={canEdit}
        canApprove={staffCan(staff.levels, 'content.approve')}
        onBack={() => go(null)}
        onSaved={(newId) => (newId !== item?.row.id ? go({ id: newId }) : reload())}
        onChanged={reload}
      />
    </ContentImagesProvider>
  );
}

export function MilestoneEditor({
  item,
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
  item: ContentItemView<ReferenceMilestoneDraft> | null;
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
  const [data, setData] = useState<ReferenceMilestoneDraft>(() =>
    item ? structuredClone(item.data) : blankMilestone(),
  );
  const [reviewerLabel, setReviewerLabel] = useState(item?.row.reviewerLabel ?? '');
  const [notes, setNotes] = useState(item?.notes ?? '');
  const [dirty, setDirty] = useState(!item);
  const [lang, setLang] = useState<Lang>(initialLang);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const [act, setAct] = useState<EditorialAction | null>(null);
  const edit = (fn: (d: ReferenceMilestoneDraft) => void) => {
    setData((d) => {
      const next = structuredClone(d);
      fn(next);
      return next;
    });
    setDirty(true);
  };
  const strict = useMemo(() => referenceMilestoneContentSchema.safeParse(data), [data]);
  const row = item?.row ?? null;
  const actions = row && !dirty ? actionsFor(row, { edit: canEdit, approve: canApprove }) : [];
  const L = milestoneLimits;
  const save = () => {
    if (!referenceMilestoneDraftSchema.safeParse(data).success) {
      setError(new ApiError('invalid-argument', null));
      return;
    }
    setBusy(true);
    setError(null);
    api
      .call<{ id: string }>('staffContentSave', {
        kind: 'milestone',
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
  return (
    <section className="page cl-editor">
      <header className="cl-editbar">
        <nav className="cl-crumbs" aria-label={intl.formatMessage({ id: 'nav.breadcrumb' })}>
          <button type="button" className="link-button" onClick={onBack}>
            <FormattedMessage id="milestones.title" />
          </button>
          <span aria-hidden="true"> › </span>
          <strong>{textOf(intl, data.title) || <FormattedMessage id="milestones.new" />}</strong>
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
          title={<FormattedMessage id="milestones.card" />}
          aside={<LangTabs value={lang} onChange={setLang} />}
        >
          <div className="stack">
            <div className="cl-grid2">
              <div className="field">
                <span className="field__label">
                  <FormattedMessage id="milestones.group" />
                </span>
                <FieldSelect<MilestoneGroup>
                  value={data.group}
                  ariaLabel={intl.formatMessage({ id: 'milestones.group' })}
                  options={milestoneGroups.map((g) => ({
                    value: g,
                    label: intl.formatMessage({ id: `milestones.group.${g}` }),
                  }))}
                  onChange={(g) => edit((d) => void (d.group = g))}
                />
              </div>
              <NumberField
                label={<FormattedMessage id="milestones.col.order" />}
                value={data.order}
                min={0}
                max={9999}
                onChange={(v) => edit((d) => void (d.order = v))}
              />
            </div>
            <fieldset className="field">
              <legend className="field__label">
                <FormattedMessage id="milestones.ageRange" />
              </legend>
              <div className="cl-grid3">
                <div className="field">
                  <span className="field__label">
                    <FormattedMessage id="stages.unit" />
                  </span>
                  <FieldSelect<'weeks' | 'months'>
                    value={data.ageRange.unit}
                    ariaLabel={intl.formatMessage({ id: 'stages.unit' })}
                    options={(['weeks', 'months'] as const).map((u) => ({
                      value: u,
                      label: intl.formatMessage({
                        id: `stages.unit.${u === 'weeks' ? 'week' : 'month'}`,
                      }),
                    }))}
                    onChange={(u) => edit((d) => void (d.ageRange.unit = u))}
                  />
                </div>
                <NumberField
                  label={<FormattedMessage id="stages.from" />}
                  value={data.ageRange.from}
                  min={0}
                  max={L.maxAgeWeeks}
                  onChange={(v) => edit((d) => void (d.ageRange.from = v))}
                />
                <NumberField
                  label={<FormattedMessage id="milestones.to" />}
                  value={data.ageRange.to}
                  min={0}
                  max={L.maxAgeWeeks}
                  onChange={(v) => edit((d) => void (d.ageRange.to = v))}
                />
              </div>
              <p className="field__help">
                <FormattedMessage
                  id="milestones.ageHelp"
                  values={{ label: milestoneAgeText(intl, data.ageRange) }}
                />
              </p>
            </fieldset>
            <TextField
              label={<FormattedMessage id="milestones.titleField" />}
              value={data.title[lang]}
              max={L.titleMax}
              counter
              onChange={(v) => edit((d) => void (d.title[lang] = v))}
            />
            <TextField
              label={<FormattedMessage id="milestones.howTo" />}
              value={data.howToRecognise[lang]}
              max={L.howToRecogniseMax}
              counter
              multiline
              onChange={(v) => edit((d) => void (d.howToRecognise[lang] = v))}
            />
            <CheckRow
              label={<FormattedMessage id="milestones.doctorToggle" />}
              checked={data.talkToDoctor !== null}
              onChange={(on) => edit((d) => void (d.talkToDoctor = on ? { vi: '', en: '' } : null))}
            />
            {data.talkToDoctor && (
              <TextField
                label={<FormattedMessage id="milestones.doctor" />}
                value={data.talkToDoctor[lang]}
                max={L.talkToDoctorMax}
                counter
                multiline
                onChange={(v) => edit((d) => void (d.talkToDoctor![lang] = v))}
              />
            )}
            <div className="field">
              <span className="field__label">
                <FormattedMessage id="milestones.illustration" />
              </span>
              <div className="cl-cover">
                <ImageThumb id={data.illustration?.image ?? null} />
                <div className="stack cl-tight">
                  <div className="actions">
                    <ImagePickerButton
                      onPick={(image) =>
                        edit(
                          (d) =>
                            void (d.illustration = {
                              image,
                              alt: d.illustration?.alt ?? { vi: '', en: '' },
                            }),
                        )
                      }
                    />
                    {data.illustration && (
                      <Button
                        kind="ghost"
                        onClick={() => edit((d) => void (d.illustration = null))}
                      >
                        <FormattedMessage id="content.image.clear" />
                      </Button>
                    )}
                  </div>
                  {data.illustration && (
                    <TextField
                      label={
                        <FormattedMessage
                          id="content.image.alt"
                          values={{ lang: lang.toUpperCase() }}
                        />
                      }
                      value={data.illustration.alt[lang]}
                      max={L.altMax}
                      onChange={(v) => edit((d) => void (d.illustration!.alt[lang] = v))}
                    />
                  )}
                </div>
              </div>
            </div>
            <SourcesField
              value={data.sources}
              max={L.sourcesMax}
              onChange={(v) => edit((d) => void (d.sources = v))}
            />
            <TextField
              label={<FormattedMessage id="content.reviewerLabel" />}
              value={reviewerLabel}
              max={80}
              help={<FormattedMessage id="content.reviewerLabelHelp" />}
              onChange={(v) => {
                setReviewerLabel(v);
                setDirty(true);
              }}
            />
            <TextField
              label={<FormattedMessage id="content.notes" />}
              value={notes}
              max={500}
              multiline
              onChange={(v) => {
                setNotes(v);
                setDirty(true);
              }}
            />
          </div>
        </Panel>
        <Panel title={<FormattedMessage id="content.preview" />}>
          <MilestonePreview data={data} lang={lang} review={reviewOf(item)} />
        </Panel>
      </div>
      {act && row && (
        <ActDialog
          kind="milestone"
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

/** 3b "Chi tiết mốc", in the language being edited. */
export function MilestonePreview({
  data,
  lang,
  review,
}: {
  data: ReferenceMilestoneDraft;
  lang: Lang;
  review: Parameters<typeof ReviewLine>[0]['review'];
}) {
  const intl = useIntl();
  const p = (id: string, values?: Record<string, string | number>) =>
    intl.formatMessage({ id: `content.preview.${id}.${lang}` }, values);
  const r = data.ageRange;
  const range =
    r.unit === 'weeks'
      ? p('weeks', { from: r.from, to: r.to })
      : p('months', { from: r.from, to: r.to });
  return (
    <PhoneFrame>
      {data.illustration && (
        <div className="cl-phone__hero">
          <ImageThumb id={data.illustration.image} size={340} />
        </div>
      )}
      <div className="cl-phone__body">
        <div className="chips">
          <span className="cl-tag cl-tag--peach">{p(`group.${data.group}`)}</span>
          <span className="cl-tag">{p('reference', { range })}</span>
        </div>
        <h3 className="cl-phone__title">{data.title[lang] || '—'}</h3>
        <div className="cl-phone__card">
          <strong>{p('howTo')}</strong>
          <p>{data.howToRecognise[lang]}</p>
        </div>
        {data.talkToDoctor && (
          <div className="cl-callout cl-callout--doctor">
            <strong>{p('doctor')}</strong>
            <p>{data.talkToDoctor[lang]}</p>
          </div>
        )}
        <ReviewLine review={review} lang={lang} />
        <p className="cl-foot">{p('ownPace')}</p>
      </div>
    </PhoneFrame>
  );
}
