import {
  contentLimits,
  foodAllergens,
  foodContentSchema,
  foodDraftSchema,
  foodGroups,
  ingredientUnits,
  recipeAgeProblems,
  recipeAllergens,
  recipeContentSchema,
  recipeDraftSchema,
  recipeMethods,
  solidsCopyProblems,
  solidsLimits,
  staffCan,
  textureStages,
  type EditorialAction,
  type FoodAllergen,
  type FoodDraft,
  type FoodGroup,
  type IngredientUnit,
  type RecipeDraft,
  type RecipeMethod,
  type TextureStage,
} from '@child-life/contracts';
import { Check, Plus, Search, X } from 'lucide-react';
import { useId, useMemo, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { toast } from 'sonner';
import { Button as UiButton } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { cn } from '@/lib/utils';
import { ApiError, useApi, useLoad } from '../api';
import { EditorBar, EditorLayout, Field, Notice, Section, useGuardedLeave } from '../content-kit';
import { useOwnWorkBlocked } from '../content-policy';
import { useStaff } from '../context';
import { Button, Empty, Loaded, Modal } from '../ui';
import {
  ActDialog,
  ContentImagesProvider,
  EmergencyHint,
  EmergencyNotice,
  LangTabs,
  LinkPicker,
  PictureField,
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
import {
  AddButton,
  MonthRangeFields,
  NumField,
  RowControls,
  SelectField,
  SwitchRow,
  blankLoc,
  listAction,
} from './nutrition-common';
import { FieldSelect } from './form-controls';
import { FoodPreview, RecipePreview } from './SolidsPreviews';
import {
  SolidsNotices,
  catalogueOf,
  foodName,
  fromMonthsText,
  solidsAgeOf,
  solidsMonthsText,
  solidsPlace,
  type AgeProblem,
  type CatalogueFood,
  type SolidsKind,
} from './solids-common';

/**
 * Editors of the Ăn dặm kinds (D-085, P-164 #8–#10; plan §6; not drawn in the portal Figma, they
 * follow the Dinh dưỡng editors): the editor bar (Lưu nháp · Gửi duyệt · Duyệt · Xuất bản),
 * sections, vi/en tabs, field help, a phone preview (5e row and food detail, 5g) and the live
 * checks. A forbidden word, a dose or an added seasoning (`solidsCopyProblems`) hides "Gửi duyệt"
 * and names the field (the server refuses with `unsafe-copy`); an ingredient whose minimum age is
 * above the recipe's first month (`recipeAgeProblems`, "Mật ong chỉ từ 12 tháng") hides Gửi duyệt,
 * Duyệt and Xuất bản (the server refuses with `food-too-young`). Allergens are derived from the
 * catalogue (`recipeAllergens`).
 */

const S = solidsLimits;

type Schema = {
  safeParse(data: unknown): { success: true } | { success: false; error: { issues: ParseIssue[] } };
};

const forward: readonly EditorialAction[] = ['submit', 'approve', 'publish'];

/** Draft state, save, the live checks and the workflow steps shared by the two editors. */
function useSolidsDraft<T extends object>({
  kind,
  item,
  blank,
  draftSchema,
  strictSchema,
  prepare,
  held,
  extraIssues,
  canEdit,
  canApprove,
  onSaved,
  initialLang = 'vi',
}: {
  kind: SolidsKind;
  item: ContentItemView<T> | null;
  blank: () => T;
  draftSchema: Schema;
  strictSchema: Schema;
  /** What is validated and saved (empty list items dropped); stable, module-level. */
  prepare: (d: T) => T;
  /** Holds Gửi duyệt, Duyệt and Xuất bản (`food-too-young`). */
  held?: (d: T) => boolean;
  /** Issues the schema reports without a path (vi and en steps differ). */
  extraIssues?: (d: T) => ParseIssue[];
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
  const prepared = useMemo(() => prepare(data), [data, prepare]);
  const strict = useMemo(() => strictSchema.safeParse(prepared), [prepared, strictSchema]);
  const draft = useMemo(() => draftSchema.safeParse(prepared), [prepared, draftSchema]);
  const problems = useMemo(() => solidsCopyProblems(prepared), [prepared]);
  const extra = extraIssues ? extraIssues(prepared) : [];
  const isHeld = held ? held(prepared) : false;
  const row = item?.row ?? null;
  const actions = row && !dirty ? actionsFor(row, { edit: canEdit, approve: canApprove }) : [];
  // P-164 #10: complete in vi and en, no forbidden word, dose or seasoning, no too-young food.
  const canSubmit = strict.success && problems.length === 0 && !isHeld;
  const { main, rest } = splitActions(
    actions.filter((a) => (a !== 'submit' || canSubmit) && !(isHeld && forward.includes(a))),
  );
  const strictIssues = strict.success ? [] : strict.error.issues.filter((i) => i.path.length > 0);
  const issues: ParseIssue[] =
    tried && !draft.success
      ? draft.error.issues
      : row && row.status === 'draft' && (!strict.success || extra.length)
        ? [...strictIssues, ...extra]
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
        data: prepared,
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
    prepared,
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

type Draft = ReturnType<typeof useSolidsDraft>;

/** The bar, the notices, the form and preview, the leave guard and the workflow dialog. */
function EditorFrame({
  kind,
  d,
  title,
  actTitle,
  aside,
  children,
  item,
  ageProblems,
  foods,
  from,
  requireReview,
  today,
  staffUid,
  canEdit,
  onBack,
  onChanged,
}: {
  kind: SolidsKind;
  d: Draft;
  title: ReactNode;
  actTitle: string;
  aside: ReactNode;
  children: ReactNode;
  item: ContentItemView<unknown> | null;
  ageProblems?: readonly AgeProblem[];
  foods?: ReadonlyMap<string, CatalogueFood>;
  from?: number;
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
        backLabel={<FormattedMessage id="nav.solids" />}
        onBack={leave}
        title={title}
        badges={d.row && <StatusCell row={d.row} />}
        dirty={d.dirty}
        saving={d.busy}
        onSave={canEdit ? d.save : undefined}
        actions={<WorkflowMain actions={d.main} onPick={d.setAct} />}
        menu={workflowMenu(d.rest, d.setAct)}
      />
      <SolidsNotices
        error={d.error}
        rejection={d.row?.rejection}
        issues={d.issues}
        problems={d.problems}
        ageProblems={ageProblems}
        foods={foods}
        from={from}
      />
      <EmergencyNotice data={d.prepared} place={solidsPlace} />
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

/** Sources, the expected reviewer and notes; folded. */
function ReviewSection({
  d,
  sources,
  onSources,
}: {
  d: Draft;
  sources: Source[];
  onSources: (v: Source[]) => void;
}) {
  return (
    <Section
      title={<FormattedMessage id="content.sourcesAndReview" />}
      collapsible
      defaultOpen={false}
      summary={<FormattedMessage id="content.sourcesCount" values={{ n: sources.length }} />}
    >
      <div className="grid gap-5">
        <SourcesField value={sources} max={S.sources} onChange={onSources} />
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
const filled = (xs: readonly string[]) => xs.filter((x) => x.trim() !== '');
/** Drops the empty boxes at the end of a list (an empty box inside it stays an issue). */
function trimTail(xs: readonly string[]): string[] {
  let n = xs.length;
  while (n > 0 && xs[n - 1]!.trim() === '') n--;
  return xs.slice(0, n);
}

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
function useEditorContext(kind: SolidsKind) {
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

function useItem<T>(kind: SolidsKind, id: string) {
  return useLoad<ContentItemView<T>>('staffContentItem', { kind, id }, `${kind}:${id}`);
}

/** A list of short words, one chip each, in the language being edited. */
function ChipsField({
  label,
  hint,
  value,
  onChange,
  max,
  itemMax,
  addLabel,
}: {
  label: ReactNode;
  hint?: ReactNode;
  value: string[];
  onChange: (v: string[]) => void;
  max: number;
  itemMax: number;
  addLabel: ReactNode;
}) {
  const intl = useIntl();
  return (
    <Field label={label} hint={hint} counter={{ n: filled(value).length, max }}>
      <ul className="flex flex-wrap items-center gap-2">
        {value.map((w, i) => (
          <li
            key={i}
            className={cn(
              'flex items-center gap-0.5 rounded-full border bg-background py-0.5 pr-0.5 pl-3',
              charCount(w) > itemMax && 'border-destructive',
            )}
          >
            <input
              className="w-28 min-w-0 bg-transparent text-sm outline-none"
              value={w}
              aria-label={intl.formatMessage({ id: 'solids.food.synonym' }, { n: i + 1 })}
              onChange={(e) => onChange(value.map((x, j) => (j === i ? e.target.value : x)))}
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
        {value.length < max && (
          <li>
            <UiButton
              variant="outline"
              size="sm"
              className="rounded-full"
              onClick={() => onChange([...value, ''])}
            >
              <Plus />
              {addLabel}
            </UiButton>
          </li>
        )}
      </ul>
    </Field>
  );
}

// ---------- Food ----------

export function blankFood(): FoodDraft {
  return {
    name: blankLoc(),
    synonyms: { vi: [], en: [] },
    group: 'vegetable',
    allergen: null,
    ironRich: false,
    minAgeMonths: S.startMonths,
    prep: [],
    chokingNote: blankLoc(),
    suggest: true,
    priority: 50,
    sources: [],
  };
}

/** Empty synonym boxes are left out of what is saved. */
export function prepareFood(d: FoodDraft): FoodDraft {
  return { ...d, synonyms: { vi: filled(d.synonyms.vi), en: filled(d.synonyms.en) } };
}

export function ExistingFood({
  id,
  onBack,
  onOpen,
}: {
  id: string;
  onBack: () => void;
  onOpen: (id: string) => void;
}) {
  const [item, reload] = useItem<FoodDraft>('food', id);
  return (
    <Loaded load={item} reload={reload}>
      {(view) => <FoodEditorShell item={view} onBack={onBack} onOpen={onOpen} reload={reload} />}
    </Loaded>
  );
}

export function FoodEditorShell({ item, onBack, onOpen, reload }: ShellProps<FoodDraft>) {
  const ctx = useEditorContext('food');
  return (
    <FoodEditor
      key={item ? `${item.row.id}:${item.row.updatedAt}` : 'new'}
      item={item}
      foods={ctx.rows}
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

export function FoodEditor({
  item,
  foods,
  requireReview,
  today,
  staffUid,
  canEdit,
  canApprove,
  onBack,
  onSaved,
  onChanged,
  initialLang,
}: EditorProps<FoodDraft> & {
  /** The other foods (same-name warning). */
  foods: ContentRow[];
}) {
  const intl = useIntl();
  const d = useSolidsDraft<FoodDraft>({
    kind: 'food',
    item,
    blank: blankFood,
    draftSchema: foodDraftSchema,
    strictSchema: foodContentSchema,
    prepare: prepareFood,
    canEdit,
    canApprove,
    onSaved,
    initialLang,
  });
  const { data, edit, lang } = d;
  const name = textOf(intl, data.name);
  const langTabs = <LangTabs value={lang} onChange={d.setLang} />;
  const label = (prefix: string) => (k: string) => intl.formatMessage({ id: `${prefix}.${k}` });
  const groupLabel = label('solids.group');
  const allergenLabel = label('solids.allergen');
  const same = (a: string, b: string) =>
    !!a.trim() && a.trim().toLowerCase() === b.trim().toLowerCase();
  const twins = foods.filter(
    (f) =>
      f.id !== d.row?.id &&
      f.status !== 'archived' &&
      (same(f.title.vi, data.name.vi) || same(f.title.en, data.name.en)),
  );
  const ageOk =
    Number.isInteger(data.minAgeMonths) &&
    data.minAgeMonths >= S.startMonths &&
    data.minAgeMonths <= S.maxAgeMonths;
  return (
    <EditorFrame
      kind="food"
      d={d}
      item={item}
      title={name || <FormattedMessage id="solids.newFood" />}
      actTitle={name}
      requireReview={requireReview}
      today={today}
      staffUid={staffUid}
      canEdit={canEdit}
      onBack={onBack}
      onChanged={onChanged}
      aside={
        <>
          <Notice tone="info">
            <FormattedMessage id="solids.food.notice" />
          </Notice>
          <PreviewCard lang={lang}>
            <FoodPreview data={d.prepared} lang={lang} review={reviewOf(item)} />
          </PreviewCard>
        </>
      }
    >
      <Section title={<FormattedMessage id="solids.food.basics" />} actions={langTabs}>
        <div className="grid gap-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <TextField
              label={<FormattedMessage id="solids.food.name" />}
              value={data.name[lang]}
              max={S.foodName}
              counter
              placeholder={intl.formatMessage({ id: 'solids.food.namePlaceholder' })}
              onChange={(v) => edit((x) => void (x.name = setLoc(x.name, lang, v)))}
            />
            <SelectField<FoodGroup>
              label={<FormattedMessage id="solids.food.group" />}
              hint={<FormattedMessage id="solids.food.groupHint" />}
              value={data.group}
              options={foodGroups.map((g) => ({ value: g, label: groupLabel(g) }))}
              onChange={(g) => edit((x) => void (x.group = g))}
            />
          </div>
          {twins.length > 0 && (
            <Notice tone="warn">
              <FormattedMessage
                id="solids.food.twins"
                values={{ list: twins.map((f) => textOf(intl, f.title)).join(', ') }}
              />
            </Notice>
          )}
          <ChipsField
            label={
              <FormattedMessage id="solids.food.synonyms" values={{ lang: lang.toUpperCase() }} />
            }
            hint={<FormattedMessage id="solids.food.synonymsHint" />}
            value={data.synonyms[lang]}
            max={S.synonyms}
            itemMax={S.synonym}
            addLabel={<FormattedMessage id="solids.food.addSynonym" />}
            onChange={(v) => edit((x) => void (x.synonyms[lang] = v))}
          />
        </div>
      </Section>
      <Section
        title={<FormattedMessage id="solids.food.safety" />}
        description={<FormattedMessage id="solids.food.safetyHelp" />}
      >
        <div className="grid gap-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <SelectField<FoodAllergen | 'none'>
              label={<FormattedMessage id="solids.food.allergen" />}
              help={<FormattedMessage id="solids.food.allergenHelp" />}
              value={data.allergen ?? 'none'}
              options={[
                { value: 'none', label: intl.formatMessage({ id: 'solids.allergen.none' }) },
                ...foodAllergens.map((a) => ({ value: a, label: allergenLabel(a) })),
              ]}
              onChange={(a) => edit((x) => void (x.allergen = a === 'none' ? null : a))}
            />
            <NumField
              label={<FormattedMessage id="solids.food.minAge" />}
              value={data.minAgeMonths}
              min={S.startMonths}
              max={S.maxAgeMonths}
              suffix={<FormattedMessage id="solids.unit.months" />}
              help={<FormattedMessage id="solids.food.minAgeHelp" />}
              error={
                ageOk ? undefined : (
                  <FormattedMessage
                    id="solids.food.minAgeError"
                    values={{ min: S.startMonths, max: S.maxAgeMonths }}
                  />
                )
              }
              onChange={(v) => edit((x) => void (x.minAgeMonths = v))}
            />
          </div>
          <div className="rounded-lg border p-3">
            <SwitchRow
              label={<FormattedMessage id="solids.food.ironRich" />}
              hint={<FormattedMessage id="solids.food.ironRichHint" />}
              checked={data.ironRich}
              onChange={(on) => edit((x) => void (x.ironRich = on))}
            />
          </div>
        </div>
      </Section>
      <Section title={<FormattedMessage id="solids.food.prepSection" />} actions={langTabs}>
        <div className="grid gap-5">
          <PrepEditor
            value={data.prep}
            lang={lang}
            onChange={(v) => edit((x) => void (x.prep = v))}
          />
          <TextField
            label={<FormattedMessage id="solids.food.choking" />}
            hint={<FormattedMessage id="solids.food.chokingHint" />}
            value={data.chokingNote[lang]}
            max={S.chokingNote}
            counter
            multiline
            rows={2}
            placeholder={intl.formatMessage({ id: 'solids.food.chokingPlaceholder' })}
            onChange={(v) => edit((x) => void (x.chokingNote = setLoc(x.chokingNote, lang, v)))}
          />
        </div>
      </Section>
      <Section
        title={<FormattedMessage id="solids.food.suggestSection" />}
        description={<FormattedMessage id="solids.food.suggestHelp" />}
      >
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="rounded-lg border p-3">
            <SwitchRow
              label={<FormattedMessage id="solids.food.suggest" />}
              checked={data.suggest}
              onChange={(on) => edit((x) => void (x.suggest = on))}
            />
          </div>
          <NumField
            label={<FormattedMessage id="solids.food.priority" />}
            hint={<FormattedMessage id="solids.food.priorityHint" />}
            value={data.priority}
            min={0}
            max={100}
            onChange={(v) => edit((x) => void (x.priority = v))}
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

type PrepRow = FoodDraft['prep'][number];

/** "Cách chuẩn bị theo độ đặc": up to 5 rows of a texture stage and how to prepare it. */
function PrepEditor({
  value,
  onChange,
  lang,
}: {
  value: PrepRow[];
  onChange: (v: PrepRow[]) => void;
  lang: Lang;
}) {
  const intl = useIntl();
  const t = (id: string, values?: Record<string, number>) => intl.formatMessage({ id }, values);
  const options = textureStages.map((s) => ({ value: s, label: t(`solids.texture.${s}`) }));
  const other: Lang = lang === 'vi' ? 'en' : 'vi';
  const set = (i: number, patch: Partial<PrepRow>) =>
    onChange(value.map((x, j) => (j === i ? { ...x, ...patch } : x)));
  const next: TextureStage =
    textureStages.find((s) => !value.some((p) => p.texture === s)) ?? 'smooth';
  return (
    <fieldset className="grid gap-2">
      <legend className="mb-1.5 flex w-full items-center text-[13px] font-medium">
        <FormattedMessage id="solids.food.prep" />
        <span className="ml-auto text-xs text-muted-foreground tabular-nums">
          {value.length}/{S.prep}
        </span>
      </legend>
      {value.length === 0 && (
        <p className="text-sm text-muted-foreground">
          <FormattedMessage id="solids.food.prepEmpty" />
        </p>
      )}
      {value.map((p, i) => {
        const row = t('solids.food.prepRow', { n: i + 1 });
        return (
          <div key={i} className="grid items-start gap-2 sm:grid-cols-[11rem_minmax(0,1fr)_auto]">
            <FieldSelect<TextureStage>
              value={p.texture}
              options={options}
              ariaLabel={`${row} · ${t('solids.field.texture')}`}
              onChange={(texture) => set(i, { texture })}
            />
            <Textarea
              rows={2}
              value={p.text[lang]}
              placeholder={p.text[other] || t('solids.food.prepPlaceholder')}
              aria-label={`${row} · ${t('solids.field.text')}`}
              aria-invalid={charCount(p.text[lang]) > S.prepText || undefined}
              className="min-h-9 leading-relaxed"
              onChange={(e) => set(i, { text: setLoc(p.text, lang, e.target.value) })}
            />
            <RowControls
              index={i}
              count={value.length}
              onChange={(a) => onChange(listAction(value, i, a))}
            />
          </div>
        );
      })}
      {value.length < S.prep && (
        <AddButton onClick={() => onChange([...value, { texture: next, text: blankLoc() }])}>
          <FormattedMessage id="solids.food.addPrep" />
        </AddButton>
      )}
    </fieldset>
  );
}

// ---------- Recipe ----------

export function blankRecipe(): RecipeDraft {
  return {
    title: blankLoc(),
    summary: blankLoc(),
    cover: null,
    ageMonths: { from: S.startMonths, to: 9 },
    texture: 'smooth',
    methods: ['spoon'],
    servings: 1,
    prepMinutes: 0,
    cookMinutes: 0,
    ingredients: [],
    steps: { vi: [], en: [] },
    storage: blankLoc(),
    tip: blankLoc(),
    relatedArticleIds: [],
    sources: [],
  };
}

/** Empty step boxes at the end are left out; an empty quantity is "no quantity". */
export function prepareRecipe(d: RecipeDraft): RecipeDraft {
  return {
    ...d,
    ingredients: d.ingredients.map((i) => ({
      ...i,
      qty: i.qty === null || !Number.isFinite(i.qty) ? null : i.qty,
    })),
    steps: { vi: trimTail(d.steps.vi), en: trimTail(d.steps.en) },
  };
}

/** "Cách làm": vi and en need the same number of steps (the app shows them side by side). */
function recipeStepIssues(d: RecipeDraft): ParseIssue[] {
  const { vi, en } = d.steps;
  return vi.length && en.length && vi.length !== en.length
    ? [{ path: ['steps'], message: 'vi and en steps differ' }]
    : [];
}

export function ExistingRecipe({
  id,
  onBack,
  onOpen,
}: {
  id: string;
  onBack: () => void;
  onOpen: (id: string) => void;
}) {
  const [item, reload] = useItem<RecipeDraft>('recipe', id);
  return (
    <Loaded load={item} reload={reload}>
      {(view) => <RecipeEditorShell item={view} onBack={onBack} onOpen={onOpen} reload={reload} />}
    </Loaded>
  );
}

export function RecipeEditorShell({ item, onBack, onOpen, reload }: ShellProps<RecipeDraft>) {
  const ctx = useEditorContext('recipe');
  const [foods] = useContentList('food');
  const [articles] = useContentList('article');
  return (
    <ContentImagesProvider canUpload={ctx.canEdit}>
      <RecipeEditor
        key={item ? `${item.row.id}:${item.row.updatedAt}` : 'new'}
        item={item}
        foods={foods.status === 'ok' ? foods.data.rows : []}
        articles={articles.status === 'ok' ? articles.data.rows : []}
        requireReview={ctx.requireReview}
        today={ctx.today}
        staffUid={ctx.staffUid}
        canEdit={ctx.canEdit}
        canApprove={ctx.canApprove}
        onBack={onBack}
        onSaved={(newId) => (newId !== item?.row.id ? onOpen(newId) : reload())}
        onChanged={reload}
      />
    </ContentImagesProvider>
  );
}

export function RecipeEditor({
  item,
  foods: foodRows,
  articles,
  requireReview,
  today,
  staffUid,
  canEdit,
  canApprove,
  onBack,
  onSaved,
  onChanged,
  initialLang,
}: EditorProps<RecipeDraft> & {
  /** The catalogue (picker, allergens, minimum ages). */
  foods: ContentRow[];
  /** The articles (related guides). */
  articles: ContentRow[];
}) {
  const intl = useIntl();
  const foods = useMemo(() => catalogueOf(foodRows), [foodRows]);
  const held = (r: RecipeDraft) =>
    !!solidsAgeOf(r.ageMonths) && recipeAgeProblems(r, foods).length > 0;
  const d = useSolidsDraft<RecipeDraft>({
    kind: 'recipe',
    item,
    blank: blankRecipe,
    draftSchema: recipeDraftSchema,
    strictSchema: recipeContentSchema,
    prepare: prepareRecipe,
    held,
    extraIssues: recipeStepIssues,
    canEdit,
    canApprove,
    onSaved,
    initialLang,
  });
  const { data, edit, lang } = d;
  const age = solidsAgeOf(data.ageMonths);
  const ageLabel = age ? solidsMonthsText(intl, age) : '—';
  const title = textOf(intl, data.title);
  const ageProblems = age ? recipeAgeProblems(data, foods) : [];
  const allergens = recipeAllergens(data, foods);
  const langTabs = <LangTabs value={lang} onChange={d.setLang} />;
  const articleOptions = articles
    .filter((a) => a.status !== 'archived')
    .sort((a, b) => Number(b.library === 'solids') - Number(a.library === 'solids'))
    .map((a) => ({
      id: a.id,
      title: textOf(intl, a.title) || a.id,
      meta:
        a.library === 'solids' ? intl.formatMessage({ id: 'content.library.solids' }) : undefined,
    }));
  // `link-missing`: Xuất bản needs every linked food and article on the app.
  const notLive = [
    ...data.ingredients
      .map((i) => i.foodId)
      .filter((id): id is string => !!id && foods.has(id) && !foods.get(id)!.live)
      .map((id) => foodName(intl, foods.get(id), id)),
    ...data.relatedArticleIds
      .filter((id) => {
        const a = articles.find((x) => x.id === id);
        return !!a && !a.live;
      })
      .map((id) => textOf(intl, articles.find((x) => x.id === id)!.title) || id),
  ];
  const methodLabel = (m: RecipeMethod) => intl.formatMessage({ id: `solids.method.${m}` });
  return (
    <EditorFrame
      kind="recipe"
      d={d}
      item={item}
      title={
        <>
          {title || <FormattedMessage id="solids.newRecipe" />}
          <span className="font-normal text-muted-foreground"> · {ageLabel}</span>
        </>
      }
      actTitle={`${title} · ${ageLabel}`}
      ageProblems={ageProblems}
      foods={foods}
      from={age?.from}
      requireReview={requireReview}
      today={today}
      staffUid={staffUid}
      canEdit={canEdit}
      onBack={onBack}
      onChanged={onChanged}
      aside={
        <>
          <Notice tone="warn">
            <FormattedMessage id="solids.recipe.notice" />
          </Notice>
          <PreviewCard lang={lang}>
            <RecipePreview data={d.prepared} lang={lang} review={reviewOf(item)} foods={foods} />
          </PreviewCard>
        </>
      }
    >
      <Section title={<FormattedMessage id="solids.recipe.general" />} actions={langTabs}>
        <div className="grid gap-4">
          <TextField
            label={<FormattedMessage id="solids.recipe.title" />}
            value={data.title[lang]}
            max={S.recipeTitle}
            counter
            placeholder={intl.formatMessage({ id: 'solids.recipe.titlePlaceholder' })}
            onChange={(v) => edit((x) => void (x.title = setLoc(x.title, lang, v)))}
          />
          <TextField
            label={<FormattedMessage id="solids.recipe.summary" />}
            value={data.summary[lang]}
            max={S.recipeSummary}
            counter
            multiline
            rows={2}
            onChange={(v) => edit((x) => void (x.summary = setLoc(x.summary, lang, v)))}
          />
          <PictureField
            label={<FormattedMessage id="solids.recipe.cover" />}
            value={data.cover}
            lang={lang}
            altMax={S.alt}
            onChange={(v) => edit((x) => void (x.cover = v))}
          />
        </div>
      </Section>
      <Section
        title={<FormattedMessage id="solids.recipe.forWho" />}
        description={<FormattedMessage id="solids.recipe.forWhoHelp" />}
      >
        <div className="grid gap-4">
          <MonthRangeFields
            value={data.ageMonths}
            onChange={(a) => edit((x) => void (x.ageMonths = a))}
          />
          {Number.isFinite(data.ageMonths.from) && data.ageMonths.from < S.startMonths && (
            <Notice tone="warn">
              <FormattedMessage id="solids.recipe.from6" values={{ n: S.startMonths }} />
            </Notice>
          )}
          <div className="grid gap-4 sm:grid-cols-2">
            <SelectField<TextureStage>
              label={<FormattedMessage id="solids.recipe.texture" />}
              hint={<FormattedMessage id="solids.recipe.textureHint" />}
              value={data.texture}
              options={textureStages.map((s) => ({
                value: s,
                label: intl.formatMessage({ id: `solids.texture.${s}` }),
              }))}
              onChange={(v) => edit((x) => void (x.texture = v))}
            />
            <fieldset className="grid content-start gap-1.5">
              <legend className="mb-1.5 text-[13px] font-medium">
                <FormattedMessage id="solids.recipe.methods" />
              </legend>
              <div className="flex flex-wrap gap-2">
                {recipeMethods.map((m) => {
                  const on = data.methods.includes(m);
                  return (
                    <UiButton
                      key={m}
                      type="button"
                      size="sm"
                      variant={on ? 'default' : 'outline'}
                      aria-pressed={on}
                      className={cn('rounded-full', !on && 'text-muted-foreground')}
                      onClick={() =>
                        edit(
                          (x) =>
                            void (x.methods = on
                              ? x.methods.filter((y) => y !== m)
                              : recipeMethods.filter((y) => y === m || x.methods.includes(y))),
                        )
                      }
                    >
                      {on && <Check />}
                      {methodLabel(m)}
                    </UiButton>
                  );
                })}
              </div>
              <p className="text-xs text-muted-foreground">
                <FormattedMessage id="solids.recipe.methodsHelp" />
              </p>
            </fieldset>
          </div>
          <div className="grid gap-4 sm:grid-cols-3">
            <NumField
              label={<FormattedMessage id="solids.recipe.servings" />}
              value={data.servings}
              min={1}
              max={S.servings}
              onChange={(v) => edit((x) => void (x.servings = v))}
            />
            <NumField
              label={<FormattedMessage id="solids.recipe.prepMinutes" />}
              value={data.prepMinutes}
              min={0}
              max={S.minutes}
              suffix={<FormattedMessage id="solids.unit.minutes" />}
              onChange={(v) => edit((x) => void (x.prepMinutes = v))}
            />
            <NumField
              label={<FormattedMessage id="solids.recipe.cookMinutes" />}
              value={data.cookMinutes}
              min={0}
              max={S.minutes}
              suffix={<FormattedMessage id="solids.unit.minutes" />}
              onChange={(v) => edit((x) => void (x.cookMinutes = v))}
            />
          </div>
        </div>
      </Section>
      <Section
        title={<FormattedMessage id="solids.recipe.ingredients" />}
        hint={<FormattedMessage id="solids.recipe.ingredientsHint" />}
        actions={langTabs}
      >
        <IngredientsEditor
          value={data.ingredients}
          lang={lang}
          foods={foods}
          from={age?.from ?? null}
          onChange={(v) => edit((x) => void (x.ingredients = v))}
        />
        <div className="mt-4 grid gap-2 rounded-lg bg-muted/50 p-3 text-sm">
          <p className="m-0">
            <span className="font-medium">
              <FormattedMessage id="solids.recipe.allergens" />
            </span>{' '}
            {allergens.length ? (
              allergens.map((a) => intl.formatMessage({ id: `solids.allergen.${a}` })).join(', ')
            ) : (
              <span className="text-muted-foreground">
                <FormattedMessage id="solids.recipe.noAllergens" />
              </span>
            )}
          </p>
          <p className="m-0 text-xs text-muted-foreground">
            <FormattedMessage
              id="solids.recipe.firstTry"
              values={{
                n: data.ingredients.filter((i) => i.foodId).length,
                total: data.ingredients.filter((i) => !i.foodId).length,
              }}
            />
          </p>
        </div>
        {notLive.length > 0 && (
          <Notice tone="info" className="mt-3">
            <FormattedMessage id="solids.recipe.notLive" values={{ list: notLive.join(', ') }} />
          </Notice>
        )}
      </Section>
      <Section
        title={<FormattedMessage id="solids.recipe.stepsSection" />}
        description={<EmergencyHint />}
        actions={langTabs}
      >
        <div className="grid gap-5">
          <StepsEditor
            value={data.steps}
            lang={lang}
            onChange={(v) => edit((x) => void (x.steps = v))}
          />
          <div className="grid gap-4 sm:grid-cols-2">
            <TextField
              label={<FormattedMessage id="solids.recipe.storage" />}
              value={data.storage[lang]}
              max={S.storage}
              counter
              multiline
              rows={3}
              placeholder={intl.formatMessage({ id: 'solids.recipe.storagePlaceholder' })}
              onChange={(v) => edit((x) => void (x.storage = setLoc(x.storage, lang, v)))}
            />
            <TextField
              label={<FormattedMessage id="solids.recipe.tip" />}
              value={data.tip[lang]}
              max={S.tip}
              counter
              multiline
              rows={3}
              onChange={(v) => edit((x) => void (x.tip = setLoc(x.tip, lang, v)))}
            />
          </div>
        </div>
      </Section>
      <Section title={<FormattedMessage id="solids.recipe.links" />}>
        <LinkPicker
          label={<FormattedMessage id="solids.recipe.related" />}
          value={data.relatedArticleIds}
          options={articleOptions}
          max={S.relatedArticles}
          tone="mint"
          onChange={(v) => edit((x) => void (x.relatedArticleIds = v))}
        />
      </Section>
      <ReviewSection
        d={d}
        sources={data.sources}
        onSources={(v) => edit((x) => void (x.sources = v))}
      />
    </EditorFrame>
  );
}

type Ingredient = RecipeDraft['ingredients'][number];

const blankIngredient = (food: CatalogueFood | null = null): Ingredient => ({
  foodId: food?.id ?? null,
  name: food ? { ...food.name } : blankLoc(),
  qty: null,
  unit: null,
  note: blankLoc(),
});

/**
 * Up to 15 rows: a catalogue food (picked with search; its name fills in) or a free name (water,
 * "nước dùng rau"), a quantity and unit, and a short note.
 */
function IngredientsEditor({
  value,
  onChange,
  lang,
  foods,
  from,
}: {
  value: Ingredient[];
  onChange: (v: Ingredient[]) => void;
  lang: Lang;
  foods: ReadonlyMap<string, CatalogueFood>;
  /** The recipe's first month (the too-young tag). */
  from: number | null;
}) {
  const intl = useIntl();
  const t = (id: string, values?: Record<string, string | number>) =>
    intl.formatMessage({ id }, values);
  const [picking, setPicking] = useState<number | 'new' | null>(null);
  const other: Lang = lang === 'vi' ? 'en' : 'vi';
  const set = (i: number, patch: Partial<Ingredient>) =>
    onChange(value.map((x, j) => (j === i ? { ...x, ...patch } : x)));
  const unitOptions: Array<{ value: IngredientUnit | 'none'; label: string }> = [
    { value: 'none', label: '—' },
    ...ingredientUnits.map((u) => ({ value: u, label: t(`solids.unit.${u}`) })),
  ];
  const pick = (food: CatalogueFood) => {
    if (picking === 'new') onChange([...value, blankIngredient(food)]);
    else if (picking !== null) {
      const cur = value[picking]!;
      const prev = cur.foodId ? foods.get(cur.foodId) : undefined;
      // The name follows the food unless the editor wrote their own.
      const keep = (l: Lang) => !!cur.name[l].trim() && cur.name[l] !== prev?.name[l];
      set(picking, {
        foodId: food.id,
        name: {
          vi: keep('vi') ? cur.name.vi : food.name.vi,
          en: keep('en') ? cur.name.en : food.name.en,
        },
      });
    }
    setPicking(null);
  };
  return (
    <div className="grid gap-3">
      <span className="text-right text-xs text-muted-foreground tabular-nums">
        {value.length}/{S.ingredients}
      </span>
      {value.length === 0 && (
        <p className="text-sm text-muted-foreground">
          <FormattedMessage id="solids.recipe.noIngredients" />
        </p>
      )}
      {value.map((ing, i) => {
        const food = ing.foodId ? foods.get(ing.foodId) : undefined;
        const tooYoung = !!food && from !== null && food.minAgeMonths > from;
        const n = i + 1;
        return (
          <div key={i} className="grid gap-3 rounded-lg border p-3">
            <div className="flex flex-wrap items-center gap-2">
              <span className="text-[13px] font-medium text-muted-foreground">
                <FormattedMessage id="solids.recipe.ingredient" values={{ n }} />
              </span>
              {ing.foodId ? (
                <span className="cl-tag cl-tag--mint px-2 py-0.5 text-xs">
                  {foodName(intl, food, ing.foodId)}
                  {food?.group && ` · ${t(`solids.group.${food.group}`)}`}
                </span>
              ) : (
                <span className="cl-tag px-2 py-0.5 text-xs">
                  <FormattedMessage id="solids.recipe.freeName" />
                </span>
              )}
              {ing.foodId && !food && (
                <span className="cl-tag px-2 py-0.5 text-xs text-destructive">
                  <FormattedMessage id="solids.recipe.unknownFood" />
                </span>
              )}
              {food?.allergen && (
                <span className="cl-tag cl-tag--sunshine px-2 py-0.5 text-xs">
                  {t(`solids.allergen.${food.allergen}`)}
                </span>
              )}
              {tooYoung && (
                <span className="cl-tag border-destructive px-2 py-0.5 text-xs text-destructive">
                  {fromMonthsText(intl, food.minAgeMonths)}
                </span>
              )}
              <span className="ml-auto flex items-center gap-1">
                <UiButton variant="ghost" size="sm" onClick={() => setPicking(i)}>
                  <Search />
                  <FormattedMessage
                    id={ing.foodId ? 'solids.recipe.changeFood' : 'solids.recipe.pickFood'}
                  />
                </UiButton>
                {ing.foodId && (
                  <UiButton
                    variant="ghost"
                    size="sm"
                    className="text-muted-foreground"
                    onClick={() => set(i, { foodId: null })}
                  >
                    <FormattedMessage id="solids.recipe.unlink" />
                  </UiButton>
                )}
                <RowControls
                  index={i}
                  count={value.length}
                  onChange={(a) => onChange(listAction(value, i, a))}
                />
              </span>
            </div>
            <div className="grid gap-3 sm:grid-cols-[minmax(0,1fr)_7rem_9rem]">
              <TextField
                label={
                  <FormattedMessage
                    id="solids.recipe.ingredientName"
                    values={{ lang: lang.toUpperCase() }}
                  />
                }
                value={ing.name[lang]}
                max={S.ingredientName}
                placeholder={ing.name[other]}
                onChange={(v) => set(i, { name: setLoc(ing.name, lang, v) })}
              />
              <QtyField
                label={<FormattedMessage id="solids.recipe.qty" />}
                value={ing.qty}
                onChange={(qty) => set(i, { qty })}
              />
              <SelectField<IngredientUnit | 'none'>
                label={<FormattedMessage id="solids.recipe.unit" />}
                value={ing.unit ?? 'none'}
                options={unitOptions}
                onChange={(u) => set(i, { unit: u === 'none' ? null : u })}
              />
            </div>
            <TextField
              label={<FormattedMessage id="solids.recipe.note" />}
              value={ing.note[lang]}
              max={S.ingredientNote}
              placeholder={ing.note[other] || t('solids.recipe.notePlaceholder')}
              onChange={(v) => set(i, { note: setLoc(ing.note, lang, v) })}
            />
          </div>
        );
      })}
      {value.length < S.ingredients && (
        <div className="flex flex-wrap gap-2">
          <UiButton variant="outline" size="sm" onClick={() => setPicking('new')}>
            <Search />
            <FormattedMessage id="solids.recipe.addFood" />
          </UiButton>
          <UiButton
            variant="outline"
            size="sm"
            onClick={() => onChange([...value, blankIngredient()])}
          >
            <Plus />
            <FormattedMessage id="solids.recipe.addFree" />
          </UiButton>
        </div>
      )}
      {picking !== null && (
        <FoodPickerDialog
          foods={foods}
          from={from}
          taken={value.map((v) => v.foodId).filter((x): x is string => !!x)}
          onPick={pick}
          onClose={() => setPicking(null)}
        />
      )}
    </div>
  );
}

/** A quantity: decimals allowed (½ = 0.5), empty = none. */
function QtyField({
  label,
  value,
  onChange,
}: {
  label: ReactNode;
  value: number | null;
  onChange: (v: number | null) => void;
}) {
  const id = useId();
  const bad = value !== null && Number.isFinite(value) && (value <= 0 || value > S.maxQty);
  return (
    <Field label={label} htmlFor={id}>
      <Input
        id={id}
        type="number"
        min={0}
        max={S.maxQty}
        step="any"
        inputMode="decimal"
        className="tabular-nums"
        aria-invalid={bad || undefined}
        value={value !== null && Number.isFinite(value) ? value : ''}
        onChange={(e) => onChange(e.target.value === '' ? null : Number(e.target.value))}
      />
    </Field>
  );
}

/** Search the catalogue (names, synonyms, id); the group, minimum age and allergen next to each. */
export function FoodPickerDialog({
  foods,
  from,
  taken,
  onPick,
  onClose,
}: {
  foods: ReadonlyMap<string, CatalogueFood>;
  from: number | null;
  taken: string[];
  onPick: (f: CatalogueFood) => void;
  onClose: () => void;
}) {
  const intl = useIntl();
  const [q, setQ] = useState('');
  const needle = q.trim().toLowerCase();
  const shown = [...foods.values()]
    .filter((f) => !f.archived)
    .filter(
      (f) =>
        !needle ||
        [f.name.vi, f.name.en, f.id, ...f.synonyms].join(' ').toLowerCase().includes(needle),
    )
    .sort((a, b) => textOf(intl, a.name).localeCompare(textOf(intl, b.name), intl.locale));
  return (
    <Modal title={<FormattedMessage id="solids.picker.title" />} onClose={onClose}>
      <div className="relative">
        <Search
          className="pointer-events-none absolute top-1/2 left-2.5 size-4 -translate-y-1/2 text-muted-foreground"
          aria-hidden="true"
        />
        <Input
          type="search"
          className="pl-8"
          value={q}
          aria-label={intl.formatMessage({ id: 'solids.picker.search' })}
          placeholder={intl.formatMessage({ id: 'solids.picker.search' })}
          onChange={(e) => setQ(e.target.value)}
        />
      </div>
      {shown.length ? (
        <ul className="grid max-h-[50vh] gap-0.5 overflow-y-auto">
          {shown.map((f) => {
            const meta = [
              f.group ? intl.formatMessage({ id: `solids.group.${f.group}` }) : null,
              fromMonthsText(intl, f.minAgeMonths),
              f.allergen ? intl.formatMessage({ id: `solids.allergen.${f.allergen}` }) : null,
              f.live ? null : intl.formatMessage({ id: 'solids.picker.notLive' }),
            ].filter(Boolean);
            const tooYoung = from !== null && f.minAgeMonths > from;
            return (
              <li key={f.id}>
                <button
                  type="button"
                  className="grid w-full gap-0.5 rounded-md px-2 py-1.5 text-left hover:bg-muted"
                  onClick={() => onPick(f)}
                >
                  <span className="flex items-center gap-2 text-sm font-medium">
                    {textOf(intl, f.name) || f.id}
                    {taken.includes(f.id) && (
                      <Check className="size-3.5 text-primary" aria-hidden="true" />
                    )}
                  </span>
                  <span
                    className={cn(
                      'text-xs',
                      tooYoung ? 'text-destructive' : 'text-muted-foreground',
                    )}
                  >
                    {meta.join(' · ')}
                  </span>
                </button>
              </li>
            );
          })}
        </ul>
      ) : (
        <Empty>
          <FormattedMessage id={foods.size ? 'content.empty' : 'solids.picker.none'} />
        </Empty>
      )}
      <div className="modal__actions">
        <Button onClick={onClose}>
          <FormattedMessage id="content.done" />
        </Button>
      </div>
    </Modal>
  );
}

/** "Cách làm": up to 8 steps; each row holds both languages (shown in the one being edited). */
function StepsEditor({
  value,
  onChange,
  lang,
}: {
  value: RecipeDraft['steps'];
  onChange: (v: RecipeDraft['steps']) => void;
  lang: Lang;
}) {
  const intl = useIntl();
  const other: Lang = lang === 'vi' ? 'en' : 'vi';
  const count = Math.max(value.vi.length, value.en.length);
  const rows = Array.from({ length: count }, (_, i) => ({
    vi: value.vi[i] ?? '',
    en: value.en[i] ?? '',
  }));
  const write = (next: Array<{ vi: string; en: string }>) =>
    onChange({ vi: next.map((r) => r.vi), en: next.map((r) => r.en) });
  const vi = trimTail(value.vi).length;
  const en = trimTail(value.en).length;
  return (
    <fieldset className="grid gap-2">
      <legend className="mb-1.5 flex w-full items-center text-[13px] font-medium">
        <FormattedMessage id="solids.recipe.steps" />
        <span className="ml-auto text-xs text-muted-foreground tabular-nums">
          {count}/{S.steps}
        </span>
      </legend>
      {count === 0 && (
        <p className="text-sm text-muted-foreground">
          <FormattedMessage id="solids.recipe.noSteps" />
        </p>
      )}
      <ol className="grid gap-2">
        {rows.map((r, i) => (
          <li key={i} className="grid grid-cols-[1.75rem_minmax(0,1fr)_auto] items-start gap-2">
            <span className="mt-1.5 grid size-6 place-items-center rounded-full bg-muted text-xs font-semibold text-muted-foreground tabular-nums">
              {i + 1}
            </span>
            <Textarea
              rows={2}
              value={r[lang]}
              placeholder={r[other]}
              aria-label={intl.formatMessage({ id: 'solids.recipe.step' }, { n: i + 1 })}
              aria-invalid={charCount(r[lang]) > S.step || undefined}
              className="min-h-9 leading-relaxed"
              onChange={(e) =>
                write(rows.map((x, j) => (j === i ? { ...x, [lang]: e.target.value } : x)))
              }
            />
            <RowControls index={i} count={count} onChange={(a) => write(listAction(rows, i, a))} />
          </li>
        ))}
      </ol>
      {count < S.steps && (
        <AddButton onClick={() => write([...rows, { vi: '', en: '' }])}>
          <FormattedMessage id="solids.recipe.addStep" />
        </AddButton>
      )}
      {vi > 0 && en > 0 && vi !== en && (
        <Notice tone="warn">
          <FormattedMessage id="solids.recipe.stepsDiffer" values={{ vi, en }} />
        </Notice>
      )}
    </fieldset>
  );
}
