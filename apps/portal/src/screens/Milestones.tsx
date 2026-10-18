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
import { Plus, Star, Upload } from 'lucide-react';
import { useEffect, useId, useMemo, useState } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { toast } from 'sonner';
import { Switch } from '@/components/ui/switch';
import { ApiError, useApi, useLoad } from '../api';
import {
  EditorBar,
  EditorLayout,
  EmptyState,
  Field,
  FilterBar,
  Hint,
  Notice,
  OverflowMenu,
  SearchInput,
  Section,
  StatTiles,
  useGuardedLeave,
} from '../content-kit';
import { useOwnWorkBlocked } from '../content-policy';
import { routePaths, subPath, useStaff } from '../context';
import { Button, Loaded, Modal, Page, SelectMenu, TableScroll, errorMessageId } from '../ui';
import {
  ActDialog,
  ContentImagesProvider,
  EditorNotices,
  ImageThumb,
  LangTabs,
  NumberField,
  PhoneFrame,
  PictureField,
  PreviewCard,
  ReviewLine,
  SourcesField,
  StatusCell,
  TextField,
  WorkflowMain,
  actionsFor,
  asApiError,
  contentTiles,
  dateTime,
  reviewOf,
  splitActions,
  statusOptions,
  textOf,
  tileMatch,
  useContentList,
  workflowMenu,
  type ContentItemView,
  type ContentListView,
  type ContentRow,
  type Lang,
  type Tile,
} from './content-common';
import { FieldSelect, FilePicker } from './form-controls';

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
  const [seeding, setSeeding] = useState(false);
  return (
    <Page
      title={<FormattedMessage id="milestones.title" />}
      subtitle={<FormattedMessage id="milestones.sub" />}
      actions={
        canEdit && (
          <>
            <OverflowMenu
              items={[
                {
                  key: 'seed',
                  icon: Upload,
                  label: <FormattedMessage id="content.seed" />,
                  onSelect: () => setSeeding(true),
                },
              ]}
            />
            <Button kind="primary" onClick={() => go({ id: null })}>
              <Plus />
              <FormattedMessage id="milestones.new" />
            </Button>
          </>
        )
      }
    >
      <Loaded load={load} reload={reload}>
        {(view) => <MilestonesBody view={view} onOpen={(id) => go({ id })} />}
      </Loaded>
      {seeding && <MilestoneSeedDialog onClose={() => setSeeding(false)} onDone={reload} />}
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
  const [tile, setTile] = useState<Tile>('all');
  const rows = view.rows.filter(
    (r) =>
      tileMatch(r, tile) &&
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
  const opt = (id: string, value: string) => ({ value, label: intl.formatMessage({ id }) });
  return (
    <div className="grid gap-4">
      <StatTiles items={contentTiles(view.counts, tile, setTile)} />
      <div className="overflow-hidden rounded-xl border bg-card">
        <FilterBar
          active={!!q || group !== 'all' || status !== 'all' || tile !== 'all'}
          onClear={() => {
            setQ('');
            setGroup('all');
            setStatus('all');
            setTile('all');
          }}
          shown={rows.length}
          total={view.rows.length}
        >
          <SearchInput
            value={q}
            placeholder={intl.formatMessage({ id: 'milestones.search' })}
            onChange={setQ}
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
            options={statusOptions(intl)}
          />
        </FilterBar>
        {byGroup.length ? (
          <TableScroll min={720}>
            <table className="table">
              <thead>
                <tr>
                  <th className="w-20">
                    <FormattedMessage id="milestones.col.order" />
                  </th>
                  <th>
                    <FormattedMessage id="content.col.title" />
                  </th>
                  <th>
                    <span className="inline-flex items-center gap-1">
                      <FormattedMessage id="milestones.col.age" />
                      <Hint>
                        <FormattedMessage id="milestones.noJudgement" />
                      </Hint>
                    </span>
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
                      <span className="font-normal text-muted-foreground">· {g.rows.length}</span>
                    </th>
                  </tr>
                  {g.rows.map((r) => {
                    const age = ageRangeOf(r);
                    return (
                      <tr key={r.id} className="cl-row" onClick={() => onOpen(r.id)}>
                        <td className="text-muted-foreground tabular-nums">
                          {String(r.order ?? '—')}
                        </td>
                        <td>
                          <button
                            type="button"
                            className="link-button text-left font-medium"
                            onClick={() => onOpen(r.id)}
                          >
                            {textOf(intl, r.title) || r.id}
                          </button>
                        </td>
                        <td className="nowrap">{age ? milestoneAgeText(intl, age) : '—'}</td>
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
                    );
                  })}
                </tbody>
              ))}
            </table>
          </TableScroll>
        ) : (
          <EmptyState
            icon={Star}
            title={
              <FormattedMessage id={view.rows.length ? 'content.noMatch' : 'milestones.empty'} />
            }
          />
        )}
      </div>
    </div>
  );
}

/**
 * "Nhập bản nháp mẫu": the milestones slice's seed file (`content/milestones/milestones.seed.json`),
 * checked here and on the server; ids already there are left alone.
 */
function MilestoneSeedDialog({ onClose, onDone }: { onClose: () => void; onDone: () => void }) {
  const api = useApi();
  const intl = useIntl();
  const id = useId();
  const [busy, setBusy] = useState(false);
  const [problem, setProblem] = useState<string | null>(null);
  const [error, setError] = useState<ApiError | null>(null);
  return (
    <Modal title={<FormattedMessage id="content.seed" />} onClose={onClose}>
      <p className="text-sm text-muted-foreground">
        <FormattedMessage id="milestones.seedHelp" />
      </p>
      <FilePicker
        id={id}
        accept="application/json,.json"
        disabled={busy}
        label={<FormattedMessage id="milestones.seedFile" />}
        onFile={(file) => {
          setProblem(null);
          setError(null);
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
                  toast.success(
                    intl.formatMessage(
                      { id: 'content.seedDone' },
                      { added: r.added.milestone ?? 0, skipped: r.skipped },
                    ),
                  );
                  onDone();
                  onClose();
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
        <p className="text-sm text-muted-foreground" role="status">
          <FormattedMessage id="state.loading" />
        </p>
      )}
      {problem && (
        <Notice tone="error">
          <FormattedMessage id={problem} />
        </Notice>
      )}
      {error && (
        <Notice tone="error">
          <FormattedMessage id={errorMessageId(error)} />
        </Notice>
      )}
    </Modal>
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
  const ownWorkBlocked = useOwnWorkBlocked(staffUid);
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
  const [start] = useState(() =>
    JSON.stringify({
      data: item ? item.data : blankMilestone(),
      reviewerLabel: item?.row.reviewerLabel ?? '',
      notes: item?.notes ?? '',
    }),
  );
  const changed = dirty && JSON.stringify({ data, reviewerLabel, notes }) !== start;
  const { leave, dialog } = useGuardedLeave(changed, onBack);
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
        toast.success(intl.formatMessage({ id: 'content.savedToast' }));
        onSaved(r.id);
      })
      .catch((e: unknown) => setError(asApiError(e)))
      .finally(() => setBusy(false));
  };
  const issues = row && row.status === 'draft' && !strict.success ? strict.error.issues : [];
  const { main, rest } = splitActions(actions.filter((a) => a !== 'submit' || strict.success));
  return (
    <section>
      <EditorBar
        backLabel={<FormattedMessage id="milestones.title" />}
        onBack={leave}
        title={textOf(intl, data.title) || <FormattedMessage id="milestones.new" />}
        badges={row && <StatusCell row={row} />}
        dirty={dirty}
        saving={busy}
        onSave={canEdit ? save : undefined}
        actions={<WorkflowMain actions={main} onPick={setAct} />}
        menu={workflowMenu(rest, setAct)}
      />
      <EditorNotices error={error} rejection={row?.rejection} issues={issues} />
      <EditorLayout
        aside={
          <PreviewCard lang={lang}>
            <MilestonePreview data={data} lang={lang} review={reviewOf(item)} />
          </PreviewCard>
        }
      >
        <Section
          title={<FormattedMessage id="milestones.placement" />}
          description={
            <FormattedMessage
              id="milestones.ageHelp"
              values={{ label: milestoneAgeText(intl, data.ageRange) }}
            />
          }
          hint={<FormattedMessage id="milestones.noJudgement" />}
        >
          <div className="grid gap-4 sm:grid-cols-3 lg:grid-cols-6">
            <div className="sm:col-span-2">
              <GroupField value={data.group} onChange={(g) => edit((d) => void (d.group = g))} />
            </div>
            <NumberField
              label={<FormattedMessage id="milestones.col.order" />}
              value={data.order}
              min={0}
              max={9999}
              hint={<FormattedMessage id="milestones.orderHint" />}
              onChange={(v) => edit((d) => void (d.order = v))}
            />
            <UnitField
              value={data.ageRange.unit}
              onChange={(u) => edit((d) => void (d.ageRange.unit = u))}
            />
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
        </Section>
        <Section
          title={<FormattedMessage id="milestones.card" />}
          actions={<LangTabs value={lang} onChange={setLang} />}
        >
          <div className="grid gap-4">
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
            <div className="grid gap-3 rounded-lg border p-3">
              <label className="flex items-center justify-between gap-3 text-[13px] font-medium">
                <FormattedMessage id="milestones.doctorToggle" />
                <Switch
                  checked={data.talkToDoctor !== null}
                  onCheckedChange={(on) =>
                    edit((d) => void (d.talkToDoctor = on ? { vi: '', en: '' } : null))
                  }
                />
              </label>
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
            </div>
          </div>
        </Section>
        <Section
          title={<FormattedMessage id="milestones.illustration" />}
          collapsible
          defaultOpen={!!data.illustration}
          summary={
            <FormattedMessage id={data.illustration ? 'content.cover.set' : 'content.cover.none'} />
          }
        >
          <PictureField
            value={data.illustration}
            lang={lang}
            altMax={L.altMax}
            onChange={(v) => edit((d) => void (d.illustration = v))}
          />
        </Section>
        <Section
          title={<FormattedMessage id="content.sourcesAndReview" />}
          collapsible
          defaultOpen={false}
          summary={
            <FormattedMessage id="content.sourcesCount" values={{ n: data.sources.length }} />
          }
        >
          <div className="grid gap-5">
            <SourcesField
              value={data.sources}
              max={L.sourcesMax}
              onChange={(v) => edit((d) => void (d.sources = v))}
            />
            <TextField
              label={<FormattedMessage id="content.reviewerLabel" />}
              value={reviewerLabel}
              max={80}
              hint={<FormattedMessage id="content.reviewerLabelHelp" />}
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
        </Section>
      </EditorLayout>
      {dialog}
      {act && row && (
        <ActDialog
          kind="milestone"
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

function GroupField({
  value,
  onChange,
}: {
  value: MilestoneGroup;
  onChange: (g: MilestoneGroup) => void;
}) {
  const intl = useIntl();
  const id = useId();
  return (
    <Field label={<FormattedMessage id="milestones.group" />} htmlFor={id}>
      <FieldSelect<MilestoneGroup>
        id={id}
        value={value}
        options={milestoneGroups.map((g) => ({
          value: g,
          label: intl.formatMessage({ id: `milestones.group.${g}` }),
        }))}
        onChange={onChange}
      />
    </Field>
  );
}

function UnitField({
  value,
  onChange,
}: {
  value: 'weeks' | 'months';
  onChange: (u: 'weeks' | 'months') => void;
}) {
  const intl = useIntl();
  const id = useId();
  return (
    <Field label={<FormattedMessage id="stages.unit" />} htmlFor={id}>
      <FieldSelect<'weeks' | 'months'>
        id={id}
        value={value}
        options={(['weeks', 'months'] as const).map((u) => ({
          value: u,
          label: intl.formatMessage({ id: `stages.unit.${u === 'weeks' ? 'week' : 'month'}` }),
        }))}
        onChange={onChange}
      />
    </Field>
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
