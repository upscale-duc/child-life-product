import {
  conditionsFor,
  contentLimits,
  nutrientDraftSchema,
  nutrientKeys,
  nutrientStrictSchema,
  nutritionAgesOverlap,
  nutritionCopyProblems,
  nutritionLimits,
  nutritionMetrics,
  nutritionRuleDraftSchema,
  nutritionRuleStrictSchema,
  nutritionStageDraftSchema,
  nutritionStageStrictSchema,
  sampleKinds,
  sampleSlots,
  staffCan,
  type EditorialAction,
  type NutrientDraft,
  type NutrientRound,
  type NutritionAge,
  type NutritionCondition,
  type NutritionMetric,
  type NutritionRuleDraft,
  type NutritionStageDraft,
  type SampleKind,
  type SampleSlot,
} from '@child-life/contracts';
import { Plus, X } from 'lucide-react';
import { useMemo, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { toast } from 'sonner';
import { Button as UiButton } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { cn } from '@/lib/utils';
import { ApiError, useApi, useLoad } from '../api';
import { EditorBar, EditorLayout, Notice, Section, useGuardedLeave } from '../content-kit';
import { useOwnWorkBlocked } from '../content-policy';
import { useStaff } from '../context';
import { Loaded } from '../ui';
import {
  ActDialog,
  EmergencyHint,
  EmergencyNotice,
  LangTabs,
  LinkPicker,
  PreviewCard,
  SourcesField,
  StatusCell,
  TextField,
  WorkflowMain,
  actionsFor,
  asApiError,
  charCount,
  reviewOf,
  splitActions,
  textOf,
  useContentList,
  workflowMenu,
  type ContentItemView,
  type ContentRow,
  type Lang,
  type Loc,
  type ParseIssue,
  type Source,
} from './content-common';
import { FieldSelect, IconButton } from './form-controls';
import { NutrientPreview, NutritionRulePreview, NutritionStagePreview } from './NutritionPreviews';
import {
  AddButton,
  AmountRangeField,
  MonthRangeFields,
  NumField,
  NutritionNotices,
  RowControls,
  SelectField,
  SwitchRow,
  TipsEditor,
  ageOf,
  ageRangeOk,
  blankLoc,
  listAction,
  locOf,
  monthsText,
  nutritionPlace,
  roundText,
  type NutritionKind,
} from './nutrition-common';

/**
 * Editors of the Dinh dưỡng kinds (D-083, P-163; Figma D02 `442:4716`; D03 and D04 editors are
 * not drawn and follow D02): the editor bar (Lưu nháp · Gửi duyệt · Duyệt · Xuất bản), sections,
 * vi/en tabs, a phone preview (9b, 9d, 9e) and the copy check: a forbidden word or a dose
 * anywhere in the text hides "Gửi duyệt" and names the field (the server refuses with
 * `unsafe-copy` too, P-163 #16).
 */

const N = nutritionLimits;

type Schema = {
  safeParse(data: unknown): { success: true } | { success: false; error: { issues: ParseIssue[] } };
};

/** Draft state, save, the copy check and the workflow steps shared by the three editors. */
function useNutritionDraft<T extends object>({
  kind,
  item,
  blank,
  draftSchema,
  strictSchema,
  canEdit,
  canApprove,
  onSaved,
  initialLang = 'vi',
}: {
  kind: NutritionKind;
  item: ContentItemView<T> | null;
  blank: () => T;
  draftSchema: Schema;
  strictSchema: Schema;
  canEdit: boolean;
  canApprove: boolean;
  onSaved: (id: string) => void;
  initialLang?: Lang;
}) {
  const intl = useIntl();
  const api = useApi();
  // A stored draft keeps every field; the blank fills anything an older draft lacks.
  const [initial] = useState<T>(() =>
    item ? { ...blank(), ...structuredClone(item.data) } : blank(),
  );
  const [data, setData] = useState<T>(() => structuredClone(initial));
  const [reviewerLabel, setReviewerLabel] = useState(item?.row.reviewerLabel ?? '');
  const [notes, setNotes] = useState(item?.notes ?? '');
  const [dirty, setDirty] = useState(!item);
  const [lang, setLang] = useState<Lang>(initialLang);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const [tried, setTried] = useState(false);
  const [act, setAct] = useState<EditorialAction | null>(null);
  const [start] = useState(() =>
    JSON.stringify({
      data: initial,
      reviewerLabel: item?.row.reviewerLabel ?? '',
      notes: item?.notes ?? '',
    }),
  );
  const changed = dirty && JSON.stringify({ data, reviewerLabel, notes }) !== start;
  const edit = (fn: (d: T) => void) => {
    setData((d) => {
      const next = structuredClone(d);
      fn(next);
      return next;
    });
    setDirty(true);
  };
  const strict = useMemo(() => strictSchema.safeParse(data), [data, strictSchema]);
  const draft = useMemo(() => draftSchema.safeParse(data), [data, draftSchema]);
  const problems = useMemo(() => nutritionCopyProblems(data), [data]);
  const row = item?.row ?? null;
  const actions = row && !dirty ? actionsFor(row, { edit: canEdit, approve: canApprove }) : [];
  // P-163 #16: complete in vi and en, and no forbidden word or dose.
  const canSubmit = strict.success && problems.length === 0;
  const { main, rest } = splitActions(actions.filter((a) => a !== 'submit' || canSubmit));
  const issues: ParseIssue[] =
    tried && !draft.success
      ? draft.error.issues
      : row && row.status === 'draft' && !strict.success
        ? strict.error.issues
        : [];
  const save = () => {
    if (!draft.success) {
      setTried(true);
      setError(new ApiError('invalid-argument', null));
      return;
    }
    setTried(false);
    setBusy(true);
    setError(null);
    api
      .call<{ id: string }>('staffContentSave', {
        kind,
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
  return {
    data,
    edit,
    reviewerLabel,
    setReviewerLabel: (v: string) => {
      setReviewerLabel(v);
      setDirty(true);
    },
    notes,
    setNotes: (v: string) => {
      setNotes(v);
      setDirty(true);
    },
    dirty,
    changed,
    lang,
    setLang,
    busy,
    error,
    act,
    setAct,
    row,
    issues,
    problems,
    main,
    rest,
    save,
  };
}

type Draft = ReturnType<typeof useNutritionDraft>;

/** The bar, the notices, the form and preview, the leave guard and the workflow dialog. */
function EditorFrame({
  kind,
  d,
  title,
  actTitle,
  aside,
  children,
  item,
  requireReview,
  today,
  staffUid,
  canEdit,
  onBack,
  onChanged,
}: {
  kind: NutritionKind;
  d: Draft;
  title: ReactNode;
  actTitle: string;
  aside: ReactNode;
  children: ReactNode;
  item: ContentItemView<unknown> | null;
  requireReview: boolean;
  today: string;
  staffUid: string;
  canEdit: boolean;
  onBack: () => void;
  onChanged: () => void;
}) {
  const ownWorkBlocked = useOwnWorkBlocked(staffUid);
  const { leave, dialog } = useGuardedLeave(d.changed, onBack);
  return (
    <section>
      <EditorBar
        backLabel={<FormattedMessage id="nav.nutrition" />}
        onBack={leave}
        title={title}
        badges={d.row && <StatusCell row={d.row} />}
        dirty={d.dirty}
        saving={d.busy}
        onSave={canEdit ? d.save : undefined}
        actions={<WorkflowMain actions={d.main} onPick={d.setAct} />}
        menu={workflowMenu(d.rest, d.setAct)}
      />
      <NutritionNotices
        error={d.error}
        rejection={d.row?.rejection}
        issues={d.issues}
        problems={d.problems}
      />
      <EmergencyNotice data={d.data} place={nutritionPlace} />
      <EditorLayout aside={aside}>{children}</EditorLayout>
      {dialog}
      {d.act && d.row && (
        <ActDialog
          kind={kind}
          id={d.row.id}
          action={d.act}
          title={actTitle}
          requireReview={requireReview}
          today={today}
          sameEditor={ownWorkBlocked(item?.lastEditorUid)}
          onClose={() => d.setAct(null)}
          onDone={() => {
            d.setAct(null);
            onChanged();
          }}
        />
      )}
    </section>
  );
}

/** Sources (when the kind has them), the expected reviewer and notes; folded. */
function ReviewSection({
  d,
  sources,
  onSources,
}: {
  d: Draft;
  sources?: Source[];
  onSources?: (v: Source[]) => void;
}) {
  return (
    <Section
      title={
        <FormattedMessage
          id={sources ? 'content.sourcesAndReview' : 'nutrition.rule.reviewSection'}
        />
      }
      collapsible
      defaultOpen={false}
      summary={
        sources ? (
          <FormattedMessage id="content.sourcesCount" values={{ n: sources.length }} />
        ) : undefined
      }
    >
      <div className="grid gap-5">
        {sources && onSources && (
          <SourcesField value={sources} max={N.sources} onChange={onSources} />
        )}
        <TextField
          label={<FormattedMessage id="content.reviewerLabel" />}
          value={d.reviewerLabel}
          max={contentLimits.reviewerLabel}
          hint={<FormattedMessage id="content.reviewerLabelHelp" />}
          onChange={d.setReviewerLabel}
        />
        <TextField
          label={<FormattedMessage id="content.notes" />}
          value={d.notes}
          max={contentLimits.notes}
          multiline
          onChange={d.setNotes}
        />
      </div>
    </Section>
  );
}

const setLoc = (l: Loc, lang: Lang, v: string): Loc => ({ ...l, [lang]: v });

type EditorProps<T> = {
  item: ContentItemView<T> | null;
  requireReview: boolean;
  today: string;
  staffUid: string;
  canEdit: boolean;
  canApprove: boolean;
  onBack: () => void;
  onSaved: (id: string) => void;
  onChanged: () => void;
  /** The content language the form and preview open in. */
  initialLang?: Lang;
};

type ShellProps<T> = {
  item: ContentItemView<T> | null;
  onBack: () => void;
  onOpen: (id: string) => void;
  reload: () => void;
};

/** What every editor needs from the staff member and the kind's list. */
function useEditorContext(kind: NutritionKind) {
  const staff = useStaff();
  const [list] = useContentList(kind);
  const ok = list.status === 'ok' ? list.data : null;
  return {
    staffUid: staff.uid,
    canEdit: staffCan(staff.levels, 'content.edit'),
    canApprove: staffCan(staff.levels, 'content.approve'),
    requireReview: ok?.requireReview ?? false,
    today: ok?.today ?? new Date().toISOString().slice(0, 10),
    rows: ok?.rows ?? [],
  };
}

function useItem<T>(kind: NutritionKind, id: string) {
  return useLoad<ContentItemView<T>>('staffContentItem', { kind, id }, `${kind}:${id}`);
}

// ---------- D02 stage ----------

export function blankNutritionStage(range: NutritionAge | null = null): NutritionStageDraft {
  return {
    ageMonths: range ?? { from: 0, to: 1 },
    title: blankLoc(),
    summary: blankLoc(),
    milk: { perFeedMl: null, feedsPerDay: null, perDayMl: null, breastfeedingNote: blankLoc() },
    solids: null,
    sampleDay: [],
    nutrientIds: [],
    tips: [],
    sources: [],
  };
}

export function ExistingNutritionStage({
  id,
  onBack,
  onOpen,
}: {
  id: string;
  onBack: () => void;
  onOpen: (id: string) => void;
}) {
  const [item, reload] = useItem<NutritionStageDraft>('nutritionStage', id);
  return (
    <Loaded load={item} reload={reload}>
      {(view) => (
        <NutritionStageEditorShell
          item={view}
          range={null}
          onBack={onBack}
          onOpen={onOpen}
          reload={reload}
        />
      )}
    </Loaded>
  );
}

export function NutritionStageEditorShell({
  item,
  range,
  onBack,
  onOpen,
  reload,
}: ShellProps<NutritionStageDraft> & { range: NutritionAge | null }) {
  const ctx = useEditorContext('nutritionStage');
  const [nutrients] = useContentList('nutrient');
  return (
    <NutritionStageEditor
      key={item ? `${item.row.id}:${item.row.updatedAt}` : `new:${range?.from}-${range?.to}`}
      item={item}
      range={range}
      stages={ctx.rows}
      nutrients={nutrients.status === 'ok' ? nutrients.data.rows : []}
      requireReview={ctx.requireReview}
      today={ctx.today}
      staffUid={ctx.staffUid}
      canEdit={ctx.canEdit}
      canApprove={ctx.canApprove}
      onBack={onBack}
      onSaved={(newId) => (newId !== item?.row.id ? onOpen(newId) : reload())}
      onChanged={reload}
    />
  );
}

export function NutritionStageEditor({
  item,
  range = null,
  stages,
  nutrients,
  requireReview,
  today,
  staffUid,
  canEdit,
  canApprove,
  onBack,
  onSaved,
  onChanged,
  initialLang,
}: EditorProps<NutritionStageDraft> & {
  range?: NutritionAge | null;
  /** The other stages (the overlap warning). */
  stages: ContentRow[];
  /** The micronutrient library (the picker and the preview). */
  nutrients: ContentRow[];
}) {
  const intl = useIntl();
  const d = useNutritionDraft<NutritionStageDraft>({
    kind: 'nutritionStage',
    item,
    blank: () => blankNutritionStage(range),
    draftSchema: nutritionStageDraftSchema,
    strictSchema: nutritionStageStrictSchema,
    canEdit,
    canApprove,
    onSaved,
    initialLang,
  });
  const { data, edit, lang } = d;
  const ageOk = ageRangeOk(data.ageMonths);
  const ageLabel = ageOk ? monthsText(intl, data.ageMonths) : '—';
  const title = textOf(intl, data.title);
  // P-163 #17: the server refuses Duyệt / Xuất bản over a live or approved stage.
  const overlapping = ageOk
    ? stages.filter((s) => {
        if (s.id === d.row?.id || !(s.live || s.status === 'approved')) return false;
        const a = ageOf(s.ageMonths);
        return !!a && nutritionAgesOverlap(a, data.ageMonths);
      })
    : [];
  const nutrientOptions = nutrients
    .filter((n) => n.status !== 'archived')
    .map((n) => {
      const focus = n.focus as { label?: unknown } | null | undefined;
      const label = locOf(focus?.label);
      return {
        id: n.id,
        title: textOf(intl, n.title) || n.id,
        meta: (label && textOf(intl, label)) || undefined,
      };
    });
  const langTabs = <LangTabs value={lang} onChange={d.setLang} />;
  const milk = data.milk;
  return (
    <EditorFrame
      kind="nutritionStage"
      d={d}
      item={item}
      title={
        <>
          {ageLabel}
          {title && <span className="font-normal text-muted-foreground"> · {title}</span>}
        </>
      }
      actTitle={`${ageLabel} · ${title}`}
      requireReview={requireReview}
      today={today}
      staffUid={staffUid}
      canEdit={canEdit}
      onBack={onBack}
      onChanged={onChanged}
      aside={
        <>
          <Notice tone="warn">
            <FormattedMessage id="nutrition.doseNotice" />
          </Notice>
          <PreviewCard lang={lang}>
            <NutritionStagePreview
              data={data}
              lang={lang}
              nutrients={nutrients}
              review={reviewOf(item)}
              today={today}
            />
          </PreviewCard>
        </>
      }
    >
      <Section title={<FormattedMessage id="nutrition.stage.general" />} actions={langTabs}>
        <div className="grid gap-4">
          <MonthRangeFields
            value={data.ageMonths}
            onChange={(a) => edit((x) => void (x.ageMonths = a))}
          />
          {overlapping.length > 0 && (
            <Notice tone="warn">
              <FormattedMessage
                id="nutrition.stage.overlap"
                values={{
                  list: overlapping
                    .map((s) => {
                      const a = ageOf(s.ageMonths);
                      return [a ? monthsText(intl, a) : '', textOf(intl, s.title)]
                        .filter(Boolean)
                        .join(' · ');
                    })
                    .join(', '),
                }}
              />
            </Notice>
          )}
          <TextField
            label={<FormattedMessage id="nutrition.stage.title" />}
            value={data.title[lang]}
            max={N.stageTitle}
            counter
            placeholder={intl.formatMessage({ id: 'nutrition.stage.titlePlaceholder' })}
            onChange={(v) => edit((x) => void (x.title = setLoc(x.title, lang, v)))}
          />
          <TextField
            label={<FormattedMessage id="nutrition.stage.summary" />}
            value={data.summary[lang]}
            max={N.stageSummary}
            counter
            multiline
            rows={3}
            onChange={(v) => edit((x) => void (x.summary = setLoc(x.summary, lang, v)))}
          />
        </div>
      </Section>
      <Section
        title={<FormattedMessage id="nutrition.stage.milk" />}
        hint={<FormattedMessage id="nutrition.stage.milkHint" />}
        actions={milk ? langTabs : undefined}
      >
        <div className="grid gap-4">
          <SwitchRow
            label={<FormattedMessage id="nutrition.stage.milkOn" />}
            checked={!!milk}
            onChange={(on) =>
              edit(
                (x) =>
                  void (x.milk = on
                    ? {
                        perFeedMl: null,
                        feedsPerDay: null,
                        perDayMl: null,
                        breastfeedingNote: blankLoc(),
                      }
                    : null),
              )
            }
          />
          {milk && (
            <>
              <div className="grid gap-3 lg:grid-cols-3">
                <AmountRangeField
                  label={<FormattedMessage id="nutrition.stage.perFeed" />}
                  value={milk.perFeedMl}
                  max={N.maxMl}
                  unit={<FormattedMessage id="nutrition.unit.ml" />}
                  onChange={(v) => edit((x) => void (x.milk!.perFeedMl = v))}
                />
                <AmountRangeField
                  label={<FormattedMessage id="nutrition.stage.feeds" />}
                  value={milk.feedsPerDay}
                  max={N.maxFeeds}
                  unit={<FormattedMessage id="nutrition.unit.feeds" />}
                  onChange={(v) => edit((x) => void (x.milk!.feedsPerDay = v))}
                />
                <AmountRangeField
                  label={<FormattedMessage id="nutrition.stage.perDay" />}
                  hint={<FormattedMessage id="nutrition.stage.perDayHint" />}
                  value={milk.perDayMl}
                  max={N.maxMl}
                  unit={<FormattedMessage id="nutrition.unit.ml" />}
                  onChange={(v) => edit((x) => void (x.milk!.perDayMl = v))}
                />
              </div>
              <TextField
                label={<FormattedMessage id="nutrition.stage.breastfeeding" />}
                value={milk.breastfeedingNote[lang]}
                max={N.amountText}
                counter
                placeholder={intl.formatMessage({ id: 'nutrition.stage.breastfeedingPlaceholder' })}
                onChange={(v) =>
                  edit(
                    (x) =>
                      void (x.milk!.breastfeedingNote = setLoc(x.milk!.breastfeedingNote, lang, v)),
                  )
                }
              />
            </>
          )}
        </div>
      </Section>
      <Section title={<FormattedMessage id="nutrition.stage.solids" />} actions={langTabs}>
        <div className="grid gap-5">
          <div className="grid gap-4 rounded-lg border p-3">
            <SwitchRow
              label={<FormattedMessage id="nutrition.stage.solidsOn" />}
              checked={!!data.solids}
              onChange={(on) =>
                edit(
                  (x) => void (x.solids = on ? { meals: blankLoc(), texture: blankLoc() } : null),
                )
              }
            />
            {data.solids && (
              <div className="grid gap-4 sm:grid-cols-2">
                <TextField
                  label={<FormattedMessage id="nutrition.stage.meals" />}
                  value={data.solids.meals[lang]}
                  max={N.amountText}
                  placeholder={intl.formatMessage({ id: 'nutrition.stage.mealsPlaceholder' })}
                  onChange={(v) =>
                    edit((x) => void (x.solids!.meals = setLoc(x.solids!.meals, lang, v)))
                  }
                />
                <TextField
                  label={<FormattedMessage id="nutrition.stage.texture" />}
                  value={data.solids.texture[lang]}
                  max={N.amountText}
                  placeholder={intl.formatMessage({ id: 'nutrition.stage.texturePlaceholder' })}
                  onChange={(v) =>
                    edit((x) => void (x.solids!.texture = setLoc(x.solids!.texture, lang, v)))
                  }
                />
              </div>
            )}
          </div>
          <SampleDayEditor
            value={data.sampleDay}
            lang={lang}
            onChange={(v) => edit((x) => void (x.sampleDay = v))}
          />
        </div>
      </Section>
      <Section
        title={<FormattedMessage id="nutrition.stage.nutrientsAndTips" />}
        actions={langTabs}
      >
        <div className="grid gap-5">
          <LinkPicker
            label={<FormattedMessage id="nutrition.stage.nutrients" />}
            value={data.nutrientIds}
            options={nutrientOptions}
            max={N.stageNutrients}
            tone="mint"
            onChange={(v) => edit((x) => void (x.nutrientIds = v))}
          />
          <TipsEditor
            label={<FormattedMessage id="nutrition.stage.tips" />}
            hint={<FormattedMessage id="nutrition.stage.tipsHint" />}
            value={data.tips}
            lang={lang}
            onChange={(v) => edit((x) => void (x.tips = v))}
          />
        </div>
      </Section>
      <ReviewSection
        d={d}
        sources={data.sources}
        onSources={(v) => edit((x) => void (x.sources = v))}
      />
    </EditorFrame>
  );
}

type SampleRow = NutritionStageDraft['sampleDay'][number];

/** "Một ngày tham khảo": up to 8 rows of time of day, type and text. */
function SampleDayEditor({
  value,
  onChange,
  lang,
}: {
  value: SampleRow[];
  onChange: (v: SampleRow[]) => void;
  lang: Lang;
}) {
  const intl = useIntl();
  const t = (id: string, values?: Record<string, number>) => intl.formatMessage({ id }, values);
  const slotOptions = sampleSlots.map((s) => ({ value: s, label: t(`nutrition.slot.${s}`) }));
  const kindOptions = sampleKinds.map((k) => ({ value: k, label: t(`nutrition.kind.${k}`) }));
  const set = (i: number, patch: Partial<SampleRow>) =>
    onChange(value.map((x, j) => (j === i ? { ...x, ...patch } : x)));
  const lastSlot = value[value.length - 1]?.slot;
  const nextSlot: SampleSlot = lastSlot
    ? (sampleSlots[Math.min(sampleSlots.indexOf(lastSlot) + 1, sampleSlots.length - 1)] ?? 'night')
    : 'morning';
  const grid = 'grid items-center gap-2 sm:grid-cols-[8rem_8rem_minmax(0,1fr)_auto]';
  return (
    <fieldset className="grid gap-2">
      <legend className="mb-1.5 flex w-full items-center text-[13px] font-medium">
        <FormattedMessage id="nutrition.stage.sampleDay" />
        <span className="ml-auto text-xs text-muted-foreground tabular-nums">
          {value.length}/{N.sampleDay}
        </span>
      </legend>
      {value.length === 0 ? (
        <p className="text-sm text-muted-foreground">
          <FormattedMessage id="nutrition.stage.sampleEmpty" />
        </p>
      ) : (
        <div className={cn(grid, 'text-xs text-muted-foreground max-sm:hidden')} aria-hidden="true">
          <span>{t('nutrition.field.slot')}</span>
          <span>{t('nutrition.field.kind')}</span>
          <span>{t('nutrition.stage.sampleText')}</span>
        </div>
      )}
      {value.map((s, i) => {
        const row = t('nutrition.stage.sampleRow', { n: i + 1 });
        return (
          <div key={i} className={grid}>
            <FieldSelect<SampleSlot>
              value={s.slot}
              options={slotOptions}
              ariaLabel={`${row} · ${t('nutrition.field.slot')}`}
              onChange={(slot) => set(i, { slot })}
            />
            <FieldSelect<SampleKind>
              value={s.kind}
              options={kindOptions}
              ariaLabel={`${row} · ${t('nutrition.field.kind')}`}
              onChange={(kind) => set(i, { kind })}
            />
            <Input
              value={s.text[lang]}
              aria-label={`${row} · ${t('nutrition.stage.sampleText')}`}
              aria-invalid={charCount(s.text[lang]) > N.sampleText || undefined}
              onChange={(e) => set(i, { text: setLoc(s.text, lang, e.target.value) })}
            />
            <RowControls
              index={i}
              count={value.length}
              onChange={(a) => onChange(listAction(value, i, a))}
            />
          </div>
        );
      })}
      {value.length < N.sampleDay && (
        <AddButton
          onClick={() => onChange([...value, { slot: nextSlot, kind: 'milk', text: blankLoc() }])}
        >
          <FormattedMessage id="nutrition.stage.addSample" />
        </AddButton>
      )}
    </fieldset>
  );
}

// ---------- D03 micronutrient ----------

export function blankNutrient(): NutrientDraft {
  return {
    key: 'other',
    name: blankLoc(),
    subtitle: blankLoc(),
    focus: { ageMonths: { from: 6, to: 24 }, label: blankLoc(), note: blankLoc() },
    why: blankLoc(),
    foods: [],
    tip: null,
    byAge: [],
    warning: blankLoc(),
    campaign: null,
    sources: [],
  };
}

/** The national vitamin A days (1–2/6 and 1–2/12, 6–36 months) as a starting point. */
const blankCampaign = (): NonNullable<NutrientDraft['campaign']> => ({
  rounds: [
    { month: 6, fromDay: 1, toDay: 2 },
    { month: 12, fromDay: 1, toDay: 2 },
  ],
  ageMonths: { from: 6, to: N.maxAgeMonths + 1 },
  place: blankLoc(),
});

export function ExistingNutrient({
  id,
  onBack,
  onOpen,
}: {
  id: string;
  onBack: () => void;
  onOpen: (id: string) => void;
}) {
  const [item, reload] = useItem<NutrientDraft>('nutrient', id);
  return (
    <Loaded load={item} reload={reload}>
      {(view) => (
        <NutrientEditorShell item={view} onBack={onBack} onOpen={onOpen} reload={reload} />
      )}
    </Loaded>
  );
}

export function NutrientEditorShell({ item, onBack, onOpen, reload }: ShellProps<NutrientDraft>) {
  const ctx = useEditorContext('nutrient');
  return (
    <NutrientEditor
      key={item ? `${item.row.id}:${item.row.updatedAt}` : 'new'}
      item={item}
      requireReview={ctx.requireReview}
      today={ctx.today}
      staffUid={ctx.staffUid}
      canEdit={ctx.canEdit}
      canApprove={ctx.canApprove}
      onBack={onBack}
      onSaved={(newId) => (newId !== item?.row.id ? onOpen(newId) : reload())}
      onChanged={reload}
    />
  );
}

export function NutrientEditor({
  item,
  requireReview,
  today,
  staffUid,
  canEdit,
  canApprove,
  onBack,
  onSaved,
  onChanged,
  initialLang,
}: EditorProps<NutrientDraft>) {
  const intl = useIntl();
  const d = useNutritionDraft<NutrientDraft>({
    kind: 'nutrient',
    item,
    blank: blankNutrient,
    draftSchema: nutrientDraftSchema,
    strictSchema: nutrientStrictSchema,
    canEdit,
    canApprove,
    onSaved,
    initialLang,
  });
  const { data, edit, lang } = d;
  const name = textOf(intl, data.name);
  const langTabs = <LangTabs value={lang} onChange={d.setLang} />;
  const keyOptions = nutrientKeys.map((k) => ({
    value: k,
    label: intl.formatMessage({ id: `nutrition.key.${k}` }),
  }));
  const campaign = data.campaign;
  return (
    <EditorFrame
      kind="nutrient"
      d={d}
      item={item}
      title={name || <FormattedMessage id="nutrition.newNutrient" />}
      actTitle={name}
      requireReview={requireReview}
      today={today}
      staffUid={staffUid}
      canEdit={canEdit}
      onBack={onBack}
      onChanged={onChanged}
      aside={
        <>
          <Notice tone="warn">
            <FormattedMessage id="nutrition.doseNotice" />
          </Notice>
          <PreviewCard lang={lang}>
            <NutrientPreview data={data} lang={lang} review={reviewOf(item)} />
          </PreviewCard>
        </>
      }
    >
      <Section title={<FormattedMessage id="nutrition.nutrient.basics" />} actions={langTabs}>
        <div className="grid gap-4 sm:grid-cols-2">
          <SelectField
            label={<FormattedMessage id="nutrition.nutrient.key" />}
            value={data.key}
            options={keyOptions}
            onChange={(k) => edit((x) => void (x.key = k))}
          />
          <TextField
            label={<FormattedMessage id="nutrition.nutrient.name" />}
            value={data.name[lang]}
            max={N.nutrientName}
            counter
            onChange={(v) => edit((x) => void (x.name = setLoc(x.name, lang, v)))}
          />
          <TextField
            className="sm:col-span-2"
            label={<FormattedMessage id="nutrition.nutrient.subtitle" />}
            hint={<FormattedMessage id="nutrition.nutrient.subtitleHint" />}
            value={data.subtitle[lang]}
            max={N.nutrientSubtitle}
            counter
            onChange={(v) => edit((x) => void (x.subtitle = setLoc(x.subtitle, lang, v)))}
          />
        </div>
      </Section>
      <Section title={<FormattedMessage id="nutrition.nutrient.focus" />} actions={langTabs}>
        <div className="grid gap-4">
          <MonthRangeFields
            value={data.focus.ageMonths}
            onChange={(a) => edit((x) => void (x.focus.ageMonths = a))}
          />
          <div className="grid gap-4 sm:grid-cols-2">
            <TextField
              label={<FormattedMessage id="nutrition.nutrient.focusLabel" />}
              value={data.focus.label[lang]}
              max={N.focusLabel}
              counter
              placeholder={intl.formatMessage({ id: 'nutrition.nutrient.focusLabelPlaceholder' })}
              onChange={(v) => edit((x) => void (x.focus.label = setLoc(x.focus.label, lang, v)))}
            />
            <TextField
              label={<FormattedMessage id="nutrition.nutrient.focusNote" />}
              value={data.focus.note[lang]}
              max={N.focusNote}
              counter
              placeholder={intl.formatMessage({ id: 'nutrition.nutrient.focusNotePlaceholder' })}
              onChange={(v) => edit((x) => void (x.focus.note = setLoc(x.focus.note, lang, v)))}
            />
          </div>
        </div>
      </Section>
      <Section title={<FormattedMessage id="nutrition.nutrient.content" />} actions={langTabs}>
        <div className="grid gap-5">
          <TextField
            label={<FormattedMessage id="nutrition.nutrient.why" />}
            value={data.why[lang]}
            max={N.why}
            counter
            multiline
            rows={4}
            onChange={(v) => edit((x) => void (x.why = setLoc(x.why, lang, v)))}
          />
          <FoodsEditor
            value={data.foods}
            lang={lang}
            onChange={(v) => edit((x) => void (x.foods = v))}
          />
          <div className="grid gap-3 rounded-lg border p-3">
            <SwitchRow
              label={<FormattedMessage id="nutrition.nutrient.tipOn" />}
              checked={data.tip !== null}
              onChange={(on) => edit((x) => void (x.tip = on ? blankLoc() : null))}
            />
            {data.tip && (
              <TextField
                label={<FormattedMessage id="nutrition.nutrient.tip" />}
                value={data.tip[lang]}
                max={N.tip}
                counter
                multiline
                rows={2}
                onChange={(v) => edit((x) => void (x.tip = setLoc(x.tip!, lang, v)))}
              />
            )}
          </div>
          <TextField
            label={<FormattedMessage id="nutrition.nutrient.warning" />}
            value={data.warning[lang]}
            max={N.warning}
            counter
            multiline
            rows={2}
            placeholder={intl.formatMessage({ id: 'nutrition.nutrient.warningPlaceholder' })}
            help={<EmergencyHint />}
            onChange={(v) => edit((x) => void (x.warning = setLoc(x.warning, lang, v)))}
          />
        </div>
      </Section>
      <Section
        title={<FormattedMessage id="nutrition.nutrient.byAge" />}
        hint={<FormattedMessage id="nutrition.nutrient.byAgeHint" />}
        actions={langTabs}
      >
        <ByAgeEditor
          value={data.byAge}
          lang={lang}
          onChange={(v) => edit((x) => void (x.byAge = v))}
        />
      </Section>
      <Section
        title={<FormattedMessage id="nutrition.nutrient.campaign" />}
        hint={<FormattedMessage id="nutrition.nutrient.campaignHint" />}
        collapsible
        defaultOpen={!!campaign}
        summary={
          campaign ? (
            campaign.rounds.map(roundText).join(', ')
          ) : (
            <FormattedMessage id="nutrition.nutrient.campaignNone" />
          )
        }
        actions={campaign ? langTabs : undefined}
      >
        <div className="grid gap-4">
          <SwitchRow
            label={<FormattedMessage id="nutrition.nutrient.campaignOn" />}
            checked={!!campaign}
            onChange={(on) => edit((x) => void (x.campaign = on ? blankCampaign() : null))}
          />
          {campaign && (
            <>
              <RoundsEditor
                value={campaign.rounds}
                onChange={(v) => edit((x) => void (x.campaign!.rounds = v))}
              />
              <div className="grid gap-2">
                <span className="text-[13px] font-medium">
                  <FormattedMessage id="nutrition.nutrient.campaignAge" />
                </span>
                <MonthRangeFields
                  value={campaign.ageMonths}
                  onChange={(a) => edit((x) => void (x.campaign!.ageMonths = a))}
                />
              </div>
              <TextField
                label={<FormattedMessage id="nutrition.nutrient.place" />}
                value={campaign.place[lang]}
                max={N.place}
                counter
                placeholder={intl.formatMessage({ id: 'nutrition.nutrient.placePlaceholder' })}
                onChange={(v) =>
                  edit((x) => void (x.campaign!.place = setLoc(x.campaign!.place, lang, v)))
                }
              />
            </>
          )}
        </div>
      </Section>
      <ReviewSection
        d={d}
        sources={data.sources}
        onSources={(v) => edit((x) => void (x.sources = v))}
      />
    </EditorFrame>
  );
}

/** Food chips: one small box each, in the language being edited (the other one as a hint). */
function FoodsEditor({
  value,
  onChange,
  lang,
}: {
  value: Loc[];
  onChange: (v: Loc[]) => void;
  lang: Lang;
}) {
  const intl = useIntl();
  const other: Lang = lang === 'vi' ? 'en' : 'vi';
  return (
    <fieldset className="grid gap-2">
      <legend className="mb-1.5 flex w-full items-center text-[13px] font-medium">
        <FormattedMessage id="nutrition.nutrient.foods" />
        <span className="ml-auto text-xs text-muted-foreground tabular-nums">
          {value.length}/{N.foods}
        </span>
      </legend>
      <ul className="flex flex-wrap items-center gap-2">
        {value.map((f, i) => (
          <li
            key={i}
            className={cn(
              'flex items-center gap-0.5 rounded-full border bg-background py-0.5 pr-0.5 pl-3',
              charCount(f[lang]) > N.food && 'border-destructive',
            )}
          >
            <input
              className="w-32 min-w-0 bg-transparent text-sm outline-none placeholder:text-muted-foreground/70"
              value={f[lang]}
              placeholder={f[other]}
              aria-label={intl.formatMessage({ id: 'nutrition.nutrient.food' }, { n: i + 1 })}
              onChange={(e) =>
                onChange(value.map((x, j) => (j === i ? setLoc(x, lang, e.target.value) : x)))
              }
            />
            <button
              type="button"
              className="grid size-6 place-items-center rounded-full text-muted-foreground hover:bg-muted hover:text-foreground"
              aria-label={intl.formatMessage({ id: 'content.remove' })}
              onClick={() => onChange(value.filter((_, j) => j !== i))}
            >
              <X className="size-3.5" />
            </button>
          </li>
        ))}
        {value.length < N.foods && (
          <li>
            <UiButton
              variant="outline"
              size="sm"
              className="rounded-full"
              onClick={() => onChange([...value, blankLoc()])}
            >
              <Plus />
              <FormattedMessage id="nutrition.nutrient.addFood" />
            </UiButton>
          </li>
        )}
      </ul>
    </fieldset>
  );
}

type ByAgeRow = NutrientDraft['byAge'][number];

function ByAgeEditor({
  value,
  onChange,
  lang,
}: {
  value: ByAgeRow[];
  onChange: (v: ByAgeRow[]) => void;
  lang: Lang;
}) {
  const intl = useIntl();
  const set = (i: number, patch: Partial<ByAgeRow>) =>
    onChange(value.map((x, j) => (j === i ? { ...x, ...patch } : x)));
  return (
    <div className="grid gap-3">
      <span className="text-right text-xs text-muted-foreground tabular-nums">
        {value.length}/{N.byAge}
      </span>
      {value.map((b, i) => (
        <div key={i} className="grid gap-3 rounded-lg border p-3">
          <div className="flex items-center gap-2">
            <span className="text-[13px] font-medium text-muted-foreground">
              <FormattedMessage id="nutrition.nutrient.row" values={{ n: i + 1 }} />
            </span>
            <span className="ml-auto">
              <RowControls
                index={i}
                count={value.length}
                onChange={(a) => onChange(listAction(value, i, a))}
              />
            </span>
          </div>
          <div className="grid gap-4 sm:grid-cols-[minmax(0,12rem)_minmax(0,1fr)]">
            <TextField
              label={<FormattedMessage id="nutrition.nutrient.byAgeLabel" />}
              value={b.label[lang]}
              max={N.byAgeLabel}
              counter
              placeholder={intl.formatMessage({ id: 'nutrition.nutrient.byAgeLabelPlaceholder' })}
              onChange={(v) => set(i, { label: setLoc(b.label, lang, v) })}
            />
            <TextField
              label={<FormattedMessage id="nutrition.nutrient.byAgeText" />}
              value={b.text[lang]}
              max={N.byAgeText}
              counter
              onChange={(v) => set(i, { text: setLoc(b.text, lang, v) })}
            />
          </div>
          <SwitchRow
            label={<FormattedMessage id="nutrition.nutrient.byAgeRange" />}
            checked={!!b.ageMonths}
            onChange={(on) => set(i, { ageMonths: on ? { from: 0, to: 1 } : null })}
          />
          {b.ageMonths && (
            <MonthRangeFields value={b.ageMonths} onChange={(a) => set(i, { ageMonths: a })} />
          )}
        </div>
      ))}
      {value.length < N.byAge && (
        <AddButton
          onClick={() =>
            onChange([...value, { ageMonths: null, label: blankLoc(), text: blankLoc() }])
          }
        >
          <FormattedMessage id="nutrition.nutrient.addByAge" />
        </AddButton>
      )}
    </div>
  );
}

/** Campaign rounds: month, first and last day (1–4). */
function RoundsEditor({
  value,
  onChange,
}: {
  value: NutrientRound[];
  onChange: (v: NutrientRound[]) => void;
}) {
  const intl = useIntl();
  const months = Array.from({ length: 12 }, (_, i) => ({
    value: String(i + 1),
    label: intl.formatMessage({ id: 'nutrition.monthN' }, { n: i + 1 }),
  }));
  const set = (i: number, patch: Partial<NutrientRound>) =>
    onChange(value.map((x, j) => (j === i ? { ...x, ...patch } : x)));
  return (
    <div className="grid gap-3">
      {value.map((r, i) => (
        <div
          key={i}
          className="grid items-start gap-3 sm:grid-cols-[minmax(0,10rem)_minmax(0,7rem)_minmax(0,7rem)_auto]"
        >
          <SelectField
            label={<FormattedMessage id="nutrition.nutrient.round" values={{ n: i + 1 }} />}
            value={String(r.month)}
            options={months}
            onChange={(m) => set(i, { month: Number(m) })}
          />
          <NumField
            label={<FormattedMessage id="nutrition.field.fromDay" />}
            value={r.fromDay}
            min={1}
            max={31}
            onChange={(fromDay) => set(i, { fromDay })}
          />
          <NumField
            label={<FormattedMessage id="nutrition.field.toDay" />}
            value={r.toDay}
            min={1}
            max={31}
            error={
              r.toDay < r.fromDay ? (
                <FormattedMessage id="nutrition.nutrient.roundError" />
              ) : undefined
            }
            onChange={(toDay) => set(i, { toDay })}
          />
          <span className="pt-6">
            <IconButton
              icon="remove"
              label={intl.formatMessage({ id: 'content.remove' })}
              disabled={value.length === 1}
              onClick={() => onChange(value.filter((_, j) => j !== i))}
            />
          </span>
        </div>
      ))}
      {value.length < N.rounds && (
        <AddButton onClick={() => onChange([...value, { month: 1, fromDay: 1, toDay: 2 }])}>
          <FormattedMessage id="nutrition.nutrient.addRound" />
        </AddButton>
      )}
    </div>
  );
}

// ---------- D04 rule ----------

export function blankNutritionRule(): NutritionRuleDraft {
  return {
    metric: 'weight',
    condition: 'belowRange',
    days: null,
    ageMonths: { from: 0, to: N.maxAgeMonths + 1 },
    banner: blankLoc(),
    tips: [],
    remindAfterDays: 14,
    export: true,
  };
}

/** The conditions a metric offers (`conditionsFor`), in words. */
export function conditionOptions(intl: IntlShape, metric: NutritionMetric) {
  return conditionsFor[metric].map((c) => ({
    value: c,
    label: intl.formatMessage({
      id:
        c === 'noMeasurement'
          ? 'nutrition.conditionOption.noMeasurement'
          : `nutrition.condition.${c}`,
    }),
  }));
}

/** Changing the metric keeps the condition when it still applies, else takes the first one. */
export function withMetric(rule: NutritionRuleDraft, metric: NutritionMetric): NutritionRuleDraft {
  const allowed = conditionsFor[metric];
  const condition = allowed.includes(rule.condition) ? rule.condition : allowed[0]!;
  return withCondition({ ...rule, metric }, condition);
}

export function withCondition(
  rule: NutritionRuleDraft,
  condition: NutritionCondition,
): NutritionRuleDraft {
  return {
    ...rule,
    condition,
    days: condition === 'noMeasurement' ? (rule.days ?? 30) : null,
  };
}

/** Growth banners say "không phải chẩn đoán" / "not a diagnosis" (plan §3). */
export function missesNotDiagnosis(rule: Pick<NutritionRuleDraft, 'metric' | 'banner'>): boolean {
  if (rule.metric !== 'weight' && rule.metric !== 'length') return false;
  const vi = rule.banner.vi.trim().toLowerCase();
  const en = rule.banner.en.trim().toLowerCase();
  return (
    (!!vi && !vi.includes('không phải chẩn đoán')) || (!!en && !en.includes('not a diagnosis'))
  );
}

export function ExistingNutritionRule({
  id,
  onBack,
  onOpen,
}: {
  id: string;
  onBack: () => void;
  onOpen: (id: string) => void;
}) {
  const [item, reload] = useItem<NutritionRuleDraft>('nutritionRule', id);
  return (
    <Loaded load={item} reload={reload}>
      {(view) => (
        <NutritionRuleEditorShell item={view} onBack={onBack} onOpen={onOpen} reload={reload} />
      )}
    </Loaded>
  );
}

export function NutritionRuleEditorShell({
  item,
  onBack,
  onOpen,
  reload,
}: ShellProps<NutritionRuleDraft>) {
  const ctx = useEditorContext('nutritionRule');
  return (
    <NutritionRuleEditor
      key={item ? `${item.row.id}:${item.row.updatedAt}` : 'new'}
      item={item}
      requireReview={ctx.requireReview}
      today={ctx.today}
      staffUid={ctx.staffUid}
      canEdit={ctx.canEdit}
      canApprove={ctx.canApprove}
      onBack={onBack}
      onSaved={(newId) => (newId !== item?.row.id ? onOpen(newId) : reload())}
      onChanged={reload}
    />
  );
}

export function NutritionRuleEditor({
  item,
  requireReview,
  today,
  staffUid,
  canEdit,
  canApprove,
  onBack,
  onSaved,
  onChanged,
  initialLang,
}: EditorProps<NutritionRuleDraft>) {
  const intl = useIntl();
  const d = useNutritionDraft<NutritionRuleDraft>({
    kind: 'nutritionRule',
    item,
    blank: blankNutritionRule,
    draftSchema: nutritionRuleDraftSchema,
    strictSchema: nutritionRuleStrictSchema,
    canEdit,
    canApprove,
    onSaved,
    initialLang,
  });
  const { data, edit, lang } = d;
  const metricLabel = intl.formatMessage({ id: `nutrition.metric.${data.metric}` });
  const conditionLabel = intl.formatMessage(
    { id: `nutrition.condition.${data.condition}` },
    { days: Number.isFinite(data.days) && data.days !== null ? data.days : 30 },
  );
  const ageOk = ageRangeOk(data.ageMonths);
  const langTabs = <LangTabs value={lang} onChange={d.setLang} />;
  const replace = (next: NutritionRuleDraft) => edit((x) => void Object.assign(x, next));
  return (
    <EditorFrame
      kind="nutritionRule"
      d={d}
      item={item}
      title={
        <>
          {metricLabel}
          <span className="font-normal text-muted-foreground"> · {conditionLabel}</span>
        </>
      }
      actTitle={`${metricLabel} · ${conditionLabel}`}
      requireReview={requireReview}
      today={today}
      staffUid={staffUid}
      canEdit={canEdit}
      onBack={onBack}
      onChanged={onChanged}
      aside={
        <>
          <Notice tone="warn">
            <FormattedMessage id="nutrition.note.rules" />
          </Notice>
          <PreviewCard lang={lang}>
            <NutritionRulePreview data={data} lang={lang} />
          </PreviewCard>
        </>
      }
    >
      <Section
        title={<FormattedMessage id="nutrition.rule.when" />}
        description={
          ageOk ? (
            <FormattedMessage
              id="nutrition.rule.summary"
              values={{ condition: conditionLabel, age: monthsText(intl, data.ageMonths) }}
            />
          ) : undefined
        }
      >
        <div className="grid gap-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <SelectField<NutritionMetric>
              label={<FormattedMessage id="nutrition.rule.metric" />}
              value={data.metric}
              options={nutritionMetrics.map((m) => ({
                value: m,
                label: intl.formatMessage({ id: `nutrition.metric.${m}` }),
              }))}
              onChange={(m) => replace(withMetric(data, m))}
            />
            <SelectField<NutritionCondition>
              label={<FormattedMessage id="nutrition.rule.condition" />}
              value={data.condition}
              options={conditionOptions(intl, data.metric)}
              help={<FormattedMessage id={`nutrition.conditionDetail.${data.condition}`} />}
              onChange={(c) => replace(withCondition(data, c))}
            />
          </div>
          {data.condition === 'noMeasurement' && (
            <NumField
              className="max-w-56"
              label={<FormattedMessage id="nutrition.rule.days" />}
              value={data.days ?? 30}
              min={7}
              max={120}
              suffix={<FormattedMessage id="nutrition.unit.days" />}
              onChange={(v) => edit((x) => void (x.days = v))}
            />
          )}
          <MonthRangeFields
            value={data.ageMonths}
            onChange={(a) => edit((x) => void (x.ageMonths = a))}
          />
        </div>
      </Section>
      <Section title={<FormattedMessage id="nutrition.rule.card" />} actions={langTabs}>
        <div className="grid gap-5">
          <TextField
            label={<FormattedMessage id="nutrition.rule.banner" />}
            value={data.banner[lang]}
            max={N.banner}
            counter
            multiline
            rows={3}
            help={<FormattedMessage id="nutrition.rule.bannerHelp" />}
            onChange={(v) => edit((x) => void (x.banner = setLoc(x.banner, lang, v)))}
          />
          {missesNotDiagnosis(data) && (
            <Notice tone="warn">
              <FormattedMessage id="nutrition.rule.notDiagnosis" />
            </Notice>
          )}
          <TipsEditor
            label={<FormattedMessage id="nutrition.rule.tips" />}
            value={data.tips}
            lang={lang}
            onChange={(v) => edit((x) => void (x.tips = v))}
          />
        </div>
      </Section>
      <Section title={<FormattedMessage id="nutrition.rule.actions" />}>
        <div className="grid gap-3">
          <div className="grid gap-3 rounded-lg border p-3">
            <SwitchRow
              label={<FormattedMessage id="nutrition.rule.remindOn" />}
              hint={<FormattedMessage id="nutrition.rule.remindHint" />}
              checked={data.remindAfterDays !== null}
              onChange={(on) => edit((x) => void (x.remindAfterDays = on ? 14 : null))}
            />
            {data.remindAfterDays !== null && (
              <NumField
                className="max-w-56"
                label={<FormattedMessage id="nutrition.rule.remindDays" />}
                value={data.remindAfterDays}
                min={7}
                max={60}
                suffix={<FormattedMessage id="nutrition.unit.days" />}
                onChange={(v) => edit((x) => void (x.remindAfterDays = v))}
              />
            )}
          </div>
          <div className="rounded-lg border p-3">
            <SwitchRow
              label={<FormattedMessage id="nutrition.rule.export" />}
              hint={<FormattedMessage id="nutrition.rule.exportHint" />}
              checked={data.export}
              onChange={(on) => edit((x) => void (x.export = on))}
            />
          </div>
        </div>
      </Section>
      <ReviewSection d={d} />
    </EditorFrame>
  );
}
