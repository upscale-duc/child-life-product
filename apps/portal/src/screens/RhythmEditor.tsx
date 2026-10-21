import {
  contentReviewSchema,
  healthSigns,
  interests,
  needs,
  rhythmActSchema,
  rhythmDraftSchema,
  setRhythmRulesSchema,
  stageWindow,
  type Activity,
  type AgeCard,
  type HealthPack,
  type ReferenceModel,
  type ReferenceStage,
  type RhythmContent,
  type RhythmDoc,
  type RhythmRules,
} from '@child-life/contracts';
import { Plus, X } from 'lucide-react';
import { createContext, useContext, useId, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Textarea } from '@/components/ui/textarea';
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group';
import { cn } from '@/lib/utils';
import type { Api, ContentDraftData, ReferenceDraftData, RhythmReview } from '../api';
import { Field, Hint, SearchInput, Section } from '../content-kit';
import { CheckRow, FieldSelect, IconButton } from './form-controls';

/**
 * Nhịp lớn lên editors (PN02, PN03): the reference model's stages and the content pack's
 * activities, age cards and health routing. Drafts are checked with the shared contract
 * (`rhythmDraftSchema`) in the browser before "Lưu nháp"; the server checks them again, and the
 * approval re-validates the published document. Pure helpers here are what the tests drive.
 * The forms are built from the content kit (D-063): sections, fields with hints, and what is used
 * less (ids, versions, sources) folded away.
 */

// ---------- Issues (the schema's problems, keyed by their dotted path) ----------

export interface Issue {
  path: Array<string | number>;
  code: string;
  message: string;
  origin?: string;
  minimum?: number;
  maximum?: number;
  expected?: string;
}

export const pathKey = (path: ReadonlyArray<PropertyKey>) => path.map(String).join('.');

/** The problems of the document being edited, and whether to show them yet (after "Lưu nháp"). */
export const IssuesContext = createContext<{ issues: Map<string, Issue>; show: boolean }>({
  issues: new Map(),
  show: false,
});

/** Moves item `i` by `by` places (−1 up, +1 down); out of range does nothing. */
export function moveItem<T>(list: T[], i: number, by: number): void {
  const j = i + by;
  if (j < 0 || j >= list.length) return;
  const [item] = list.splice(i, 1);
  list.splice(j, 0, item!);
}

/** A readable message for one schema issue (the schema's own text is for engineers). */
function issueText(intl: IntlShape, issue: Issue): string {
  const f = (id: string, values?: Record<string, number>) =>
    intl.formatMessage({ id: `rhythm.err.${id}` }, values);
  if (issue.code === 'custom') return f(issue.message === 'duplicate id' ? 'duplicate' : 'invalid');
  const min = issue.minimum ?? 0;
  const max = issue.maximum ?? 0;
  if (issue.code === 'too_small') {
    if (issue.origin === 'string') return min <= 1 ? f('required') : f('tooShort', { min });
    if (issue.origin === 'array') return f('tooFew', { min });
    return f('min', { min });
  }
  if (issue.code === 'too_big') {
    if (issue.origin === 'string') return f('tooLong', { max });
    if (issue.origin === 'array') return f('tooMany', { max });
    return f('max', { max });
  }
  if (issue.code === 'invalid_format') return f('format');
  if (issue.code === 'invalid_type')
    return issue.expected === 'number' ? f('number') : f('required');
  return f('invalid');
}

type Path = Array<string | number>;
export type Edit<T> = (fn: (data: T) => void) => void;
type Localized = { vi: string; en: string };
type LocalizedList = { vi: string[]; en: string[] };
export type Lang = 'vi' | 'en';
export const langs = ['vi', 'en'] as const;

/** PN02: the pre-stage reminder fits a phone notification. */
export const noticeLimits = { title: 40, body: 90 } as const;

/** Characters as people count them (NFC code points: "ồ" is one). */
export const charCount = (s: string) => [...s.normalize('NFC')].length;

// ---------- Validation ----------

export interface Check {
  ok: boolean;
  issues: Map<string, Issue>;
  list: Issue[];
}

function toIssue(i: { path: ReadonlyArray<PropertyKey>; code: string; message: string }): Issue {
  const raw = i as unknown as Record<string, unknown>;
  return {
    path: i.path.map((p) => (typeof p === 'number' ? p : String(p))),
    code: i.code,
    message: i.message,
    origin: typeof raw.origin === 'string' ? raw.origin : undefined,
    minimum: typeof raw.minimum === 'number' ? raw.minimum : undefined,
    maximum: typeof raw.maximum === 'number' ? raw.maximum : undefined,
    expected: typeof raw.expected === 'string' ? raw.expected : undefined,
  };
}

function duplicates(ids: string[], at: (i: number) => Path): Issue[] {
  const seen = new Set<string>();
  const out: Issue[] = [];
  ids.forEach((id, i) => {
    if (id && seen.has(id)) {
      out.push({ path: at(i), code: 'custom', message: 'duplicate id' });
    }
    seen.add(id);
  });
  return out;
}

/**
 * The draft as the server will check it (`rhythmDraftSchema`), plus what the design asks and the
 * schema leaves open: notice ≤40 / ≤90 characters (PN02) and ids used once per list.
 */
export function validateRhythmDraft(doc: 'reference', data: ReferenceDraftData): Check;
export function validateRhythmDraft(doc: 'content', data: ContentDraftData): Check;
export function validateRhythmDraft(
  doc: RhythmDoc,
  data: ReferenceDraftData | ContentDraftData,
): Check;
export function validateRhythmDraft(
  doc: RhythmDoc,
  data: ReferenceDraftData | ContentDraftData,
): Check {
  const list: Issue[] = [];
  const res = rhythmDraftSchema.safeParse({ doc, data, notes: '' });
  if (!res.success) {
    for (const i of res.error.issues) {
      const issue = toIssue(i);
      // Paths inside the draft ("stages.2.name.vi"), not the request ("data.stages…").
      if (issue.path[0] === 'data') issue.path = issue.path.slice(1);
      list.push(issue);
    }
  }
  if (doc === 'reference') {
    const ref = data as ReferenceDraftData;
    const stages = Array.isArray(ref.stages) ? ref.stages : [];
    stages.forEach((s, i) => {
      if (!s.notice) return;
      for (const part of ['title', 'body'] as const) {
        for (const lang of langs) {
          const max = noticeLimits[part];
          if (charCount(s.notice[part]?.[lang] ?? '') > max) {
            list.push({
              path: ['stages', i, 'notice', part, lang],
              code: 'too_big',
              message: 'notice length',
              origin: 'string',
              maximum: max,
            });
          }
        }
      }
    });
    list.push(
      ...duplicates(
        stages.map((s) => s.id),
        (i) => ['stages', i, 'id'],
      ),
    );
  } else {
    const c = data as ContentDraftData;
    list.push(
      ...duplicates(
        (c.activities ?? []).map((a) => a.id),
        (i) => ['activities', i, 'id'],
      ),
      ...duplicates(
        (c.ageCards ?? []).map((a) => a.id),
        (i) => ['ageCards', i, 'id'],
      ),
      ...duplicates(
        (c.health?.signs ?? []).map((s) => s.id),
        (i) => ['health', 'signs', i, 'id'],
      ),
    );
  }
  const issues = new Map<string, Issue>();
  for (const i of list) if (!issues.has(pathKey(i.path))) issues.set(pathKey(i.path), i);
  return { ok: list.length === 0, issues, list };
}

/** A readable message; the window and age refinements get their own words. */
export function rhythmIssueText(intl: IntlShape, issue: Issue): string {
  if (issue.code === 'custom') {
    if (issue.message === 'Window ends before it starts')
      return intl.formatMessage({ id: 'rhythm.err.window' });
    if (issue.message === 'Age range ends before it starts')
      return intl.formatMessage({ id: 'rhythm.err.ageRange' });
  }
  if (issue.code === 'invalid_format' && issue.path[issue.path.length - 1] === 'url')
    return intl.formatMessage({ id: 'rhythm.err.url' });
  return issueText(intl, issue);
}

// ---------- Saving and acting ----------

/** Validates, then saves the document's open draft (or starts one); sends the parsed data. */
export async function saveRhythmDraft(
  api: Api,
  doc: RhythmDoc,
  data: ReferenceDraftData | ContentDraftData,
  notes: string,
): Promise<{ ok: true; versionId: string } | { ok: false; issues: Issue[] }> {
  const check = validateRhythmDraft(doc, data);
  const req = rhythmDraftSchema.safeParse({ doc, data, notes: notes.trim() });
  if (!check.ok || !req.success) return { ok: false, issues: check.list };
  const res = await api.call<{ versionId: string }>('staffRhythmDraft', req.data);
  return { ok: true, versionId: res.versionId };
}

export type Act = 'submit' | 'approve' | 'reject' | 'discard' | 'rollback';

export interface ReviewInput {
  reviewer: string;
  credential: string;
  reviewedOn: string;
}

/** The approver's review: required on prod; on dev all empty = none, a half-filled one is refused. */
export function rhythmReviewFrom(
  input: ReviewInput,
  required: boolean,
): { ok: true; review: RhythmReview } | { ok: false } {
  const reviewer = input.reviewer.trim();
  const credential = input.credential.trim();
  if (!required && !reviewer && !credential) return { ok: true, review: null };
  const res = contentReviewSchema.safeParse({ reviewer, credential, reviewedOn: input.reviewedOn });
  if (!res.success || !res.data) return { ok: false };
  return { ok: true, review: res.data };
}

/**
 * The `staffRhythmAct` request, or null when the review is not acceptable yet. No reason is sent
 * (D-090): the server writes the audit line itself.
 */
export function rhythmActRequest(
  doc: RhythmDoc,
  versionId: string,
  action: Act,
  review: ReviewInput | null,
  requireReview: boolean,
) {
  let rv: RhythmReview = null;
  if (action === 'approve' && review) {
    const checked = rhythmReviewFrom(review, requireReview);
    if (!checked.ok) return null;
    rv = checked.review;
  } else if (action === 'approve' && requireReview) {
    return null;
  }
  const res = rhythmActSchema.safeParse({ doc, versionId, action, review: rv });
  return res.success
    ? { doc: res.data.doc, versionId: res.data.versionId, action: res.data.action, review: rv }
    : null;
}

/** Sends one step of the workflow; nothing is sent when the request is not acceptable. */
export async function sendRhythmAct(
  api: Api,
  doc: RhythmDoc,
  versionId: string,
  action: Act,
  review: ReviewInput | null,
  requireReview: boolean,
): Promise<{ ok: true; status: string } | { ok: false }> {
  const req = rhythmActRequest(doc, versionId, action, review, requireReview);
  if (!req) return { ok: false };
  const res = await api.call<{ status: string }>('staffRhythmAct', req);
  return { ok: true, status: res?.status ?? '' };
}

/** PN04 "Lưu quy tắc": the server's schema (with the window checks) before it is sent. */
export function rulesIssues(rules: RhythmRules): Map<string, Issue> {
  const res = setRhythmRulesSchema.safeParse({ rules });
  const out = new Map<string, Issue>();
  if (res.success) return out;
  for (const i of res.error.issues) {
    const issue = toIssue(i);
    const key = issue.path[1] !== undefined ? String(issue.path[1]) : (issue.message ?? '');
    if (!out.has(key)) out.set(key, issue);
  }
  return out;
}

/** PN04 "Lưu quy tắc": checked like the server, then sent without a reason (D-090). */
export async function saveRhythmRules(
  api: Api,
  rules: RhythmRules,
): Promise<{ ok: true; rules: RhythmRules } | { ok: false }> {
  const req = setRhythmRulesSchema.safeParse({ rules });
  if (!req.success) return { ok: false };
  const res = await api.call<{ rules: RhythmRules }>('staffSetRhythmRules', {
    rules: req.data.rules,
  });
  return { ok: true, rules: res.rules };
}

/** The refinements in `setRhythmRulesSchema`, as messages. */
export function ruleIssueText(intl: IntlShape, issue: Issue): string {
  if (issue.message === 'baselineMinDays > baselineMaxDays')
    return intl.formatMessage({ id: 'rhythm.rules.err.baselineMin' });
  if (issue.message === 'recentMinDays > recentDays')
    return intl.formatMessage({ id: 'rhythm.rules.err.recentMin' });
  if (issue.message === 'baseline window too long')
    return intl.formatMessage({ id: 'rhythm.rules.err.lookback' });
  return issueText(intl, issue);
}

// ---------- "Không được viết" (PN02, brief p.13) ----------

export const forbiddenPatterns: ReadonlyArray<{ id: string; re: RegExp }> = [
  { id: 'certain', re: /chắc chắn/iu },
  { id: 'countdown', re: /còn\s+\d+\s+(ngày|tuần)/iu },
  { id: 'behind', re: /chậm hơn chuẩn/iu },
  { id: 'definitely', re: /\b(definitely|certainly|surely)\b/i },
  { id: 'daysLeft', re: /\b\d+\s+(days?|weeks?)\s+(left|until|to go)\b/i },
];

export interface ForbiddenHit {
  stage: number;
  field: 'name' | 'signs' | 'skills' | 'notice';
  lang: Lang;
  text: string;
  phrase: string;
}

/** Stage texts that promise or count down ("chắc chắn", "còn 3 ngày", "definitely"). */
export function forbiddenPhrases(stages: readonly ReferenceStage[]): ForbiddenHit[] {
  const hits: ForbiddenHit[] = [];
  stages.forEach((s, stage) => {
    for (const lang of langs) {
      const texts: Array<[ForbiddenHit['field'], string]> = [
        ['name', s.name?.[lang] ?? ''],
        ...(s.signs?.[lang] ?? []).map((t): [ForbiddenHit['field'], string] => ['signs', t]),
        ...(s.skills?.[lang] ?? []).map((t): [ForbiddenHit['field'], string] => ['skills', t]),
        ...(s.notice
          ? ([
              ['notice', s.notice.title[lang]],
              ['notice', s.notice.body[lang]],
            ] as Array<[ForbiddenHit['field'], string]>)
          : []),
      ];
      for (const [field, raw] of texts) {
        const text = raw.normalize('NFC');
        for (const p of forbiddenPatterns) {
          const m = p.re.exec(text);
          if (m) hits.push({ stage, field, lang, text, phrase: m[0] });
        }
      }
    }
  });
  return hits;
}

// ---------- Dates ----------

/** "2026-10-12" → "12/10/2026". */
export const dmy = (iso: string) => iso.split('-').reverse().join('/');

/** PN02 preview: the window for a sample due date (inclusive, date-only). */
export function windowPreview(
  dueDate: string,
  stage: Pick<ReferenceStage, 'startOffsetDays' | 'endOffsetDays'>,
): { start: string; end: string } | null {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dueDate)) return null;
  if (!Number.isInteger(stage.startOffsetDays) || !Number.isInteger(stage.endOffsetDays)) {
    return null;
  }
  return stageWindow(dueDate, stage);
}

export const monthsOf = (days: number) => Math.round(days / 30.44);

// ---------- Drafts from what is published ----------

/** A working copy of the published model: without its version, and not reviewed yet. */
export function referenceDraftFrom(m: ReferenceModel | ReferenceDraftData): ReferenceDraftData {
  const copy = structuredClone(m) as Partial<ReferenceModel>;
  delete copy.version;
  delete copy.publishedAt;
  return { ...(copy as ReferenceDraftData), review: null };
}

export function contentDraftFrom(c: RhythmContent | ContentDraftData): ContentDraftData {
  const copy = structuredClone(c) as Partial<RhythmContent>;
  delete copy.version;
  delete copy.publishedAt;
  return copy as ContentDraftData;
}

const sameText = <T extends { version?: number; status?: string; review?: unknown }>(
  a: T,
  b: T,
) => {
  const strip = (x: T) => {
    const copy: Record<string, unknown> = { ...x };
    delete copy.version;
    delete copy.status;
    delete copy.review;
    return copy;
  };
  return JSON.stringify(strip(a)) === JSON.stringify(strip(b));
};

/**
 * An item whose text changed since the published pack gets the next version (feedback is kept
 * per version) and loses the old sign-off: the approver's review is recorded on it instead.
 */
export function withNewVersions(
  data: ContentDraftData,
  current: RhythmContent | null,
): ContentDraftData {
  if (!current) return data;
  const bump = <T extends Activity | AgeCard>(items: T[], published: T[]): T[] =>
    items.map((item) => {
      const was = published.find((p) => p.id === item.id);
      if (!was || sameText(item, was)) return item;
      return { ...item, version: Math.max(item.version, was.version + 1), review: null };
    });
  const health = sameText(data.health, current.health)
    ? data.health
    : { ...data.health, review: null };
  return {
    ...data,
    activities: bump(data.activities, current.activities),
    ageCards: bump(data.ageCards, current.ageCards),
    health,
  };
}

// ---------- Blank items ----------

const loc = (): Localized => ({ vi: '', en: '' });
const locList = (): LocalizedList => ({ vi: [], en: [] });

export function freeId(taken: Iterable<string>, base: string): string {
  const used = new Set(taken);
  for (let n = 1; ; n++) {
    const id = `${base}${String(n).padStart(2, '0')}`;
    if (!used.has(id)) return id;
  }
}

export function blankStage(stages: readonly ReferenceStage[]): ReferenceStage {
  const last = [...stages].sort((a, b) => b.endOffsetDays - a.endOffsetDays)[0];
  const start = last ? last.endOffsetDays + 7 : 28;
  return {
    id: freeId(
      stages.map((s) => s.id),
      'stage_',
    ),
    number: Math.min(30, Math.max(0, ...stages.map((s) => s.number)) + 1),
    startOffsetDays: start,
    endOffsetDays: start + 10,
    name: loc(),
    signs: locList(),
    skills: locList(),
    activityIds: [],
    notice: null,
  };
}

export function starterReference(): ReferenceDraftData {
  return { label: 'Wonder Weeks', stages: [blankStage([])], sources: [], review: null };
}

export function blankActivity(items: readonly Activity[]): Activity {
  return {
    id: freeId(
      items.map((a) => a.id),
      'act_new_',
    ),
    version: 1,
    status: 'published',
    title: loc(),
    summary: loc(),
    steps: locList(),
    safety: null,
    durationMin: 10,
    ageDays: { from: 0, to: 91 },
    needs: [],
    interests: [],
    timeOfDay: 'any',
    locales: ['vi', 'en'],
    regions: [],
    sources: [],
    review: null,
  };
}

export function blankAgeCard(items: readonly AgeCard[]): AgeCard {
  const last = [...items].sort((a, b) => b.ageDays.to - a.ageDays.to)[0];
  const from = last ? last.ageDays.to + 1 : 0;
  return {
    id: freeId(
      items.map((a) => a.id),
      'age_new_',
    ),
    version: 1,
    status: 'published',
    ageDays: { from, to: from + 6 },
    title: loc(),
    body: loc(),
    tips: locList(),
    watchFor: locList(),
    interests: [],
    sources: [],
    review: null,
  };
}

export function starterContent(): ContentDraftData {
  return {
    activities: [],
    ageCards: [],
    health: {
      signs: [{ id: 'fever_young', label: loc(), maxAgeDays: 90 }],
      whileWaiting: locList(),
      disclaimer: loc(),
      regions: [{ country: 'VN', emergencyNumber: '115' }],
      sources: [],
      review: null,
    },
  };
}

// ---------- Fields ----------

function useRhythmIssue(path: Path | null): string | undefined {
  const intl = useIntl();
  const { issues, show } = useContext(IssuesContext);
  if (!show || !path) return undefined;
  const hit = issues.get(pathKey(path));
  return hit ? rhythmIssueText(intl, hit) : undefined;
}

/** Whether anything under [prefix] (optionally in one language) has a problem. */
function useHasIssue(prefix: Path, lang?: Lang): boolean {
  const { issues, show } = useContext(IssuesContext);
  if (!show) return false;
  const head = `${pathKey(prefix)}.`;
  for (const key of issues.keys()) {
    if (!key.startsWith(head)) continue;
    if (!lang || key.split('.').includes(lang)) return true;
  }
  return false;
}

/** Whether one of these fields, or anything under them, has a problem (opens a folded section). */
function useIssueUnder(paths: Path[]): boolean {
  const { issues, show } = useContext(IssuesContext);
  if (!show) return false;
  const keys = paths.map(pathKey);
  for (const key of issues.keys()) {
    if (keys.some((k) => key === k || key.startsWith(`${k}.`))) return true;
  }
  return false;
}

function FieldError({ text, className }: { text?: string; className?: string }) {
  return text ? <p className={cn('text-xs text-destructive', className)}>{text}</p> : null;
}

const monoInput = 'font-mono text-[13px]';

export function TextInput({
  label,
  value,
  onChange,
  path,
  help,
  hint,
  mono,
  disabled,
  max,
  counter,
  multiline,
  className,
}: {
  label: ReactNode;
  value: string;
  onChange: (v: string) => void;
  path: Path;
  help?: ReactNode;
  hint?: ReactNode;
  mono?: boolean;
  disabled?: boolean;
  max?: number;
  /** Shows "n/limit" and turns red past it (PN02 notice). */
  counter?: number;
  /** Two lines (a notification body). */
  multiline?: boolean;
  className?: string;
}) {
  const id = useId();
  const err = useRhythmIssue(path);
  const props = {
    id,
    value,
    maxLength: max,
    disabled,
    'aria-invalid': err ? true : undefined,
    onChange: (e: { target: { value: string } }) => onChange(e.target.value),
  };
  return (
    <Field
      label={label}
      htmlFor={id}
      hint={hint}
      help={help}
      error={err}
      counter={counter !== undefined ? { n: charCount(value), max: counter } : undefined}
      className={className}
    >
      {multiline ? (
        <Textarea rows={2} className="min-h-0" {...props} />
      ) : (
        <Input className={cn(mono && monoInput)} {...props} />
      )}
    </Field>
  );
}

const toNumber = (s: string) => (s.trim() === '' ? Number.NaN : Number(s));

export function NumberInput({
  label,
  value,
  onChange,
  path,
  help,
  hint,
  unit,
  nullable,
  placeholder,
  step,
}: {
  label: ReactNode;
  value: number | null;
  onChange: (v: number | null) => void;
  path: Path;
  help?: ReactNode;
  hint?: ReactNode;
  /** Words after the box ("ngày sau dự sinh"). */
  unit?: ReactNode;
  nullable?: boolean;
  placeholder?: string;
  step?: string;
}) {
  const id = useId();
  const err = useRhythmIssue(path);
  return (
    <Field label={label} htmlFor={id} hint={hint} help={help} error={err}>
      <div className="flex items-center gap-2">
        <Input
          id={id}
          type="number"
          step={step ?? '1'}
          placeholder={placeholder}
          className="w-28 tabular-nums"
          value={value === null || Number.isNaN(value) ? '' : value}
          aria-invalid={err ? true : undefined}
          onChange={(e) =>
            onChange(nullable && e.target.value === '' ? null : toNumber(e.target.value))
          }
        />
        {unit && <span className="text-sm text-muted-foreground">{unit}</span>}
      </div>
    </Field>
  );
}

/** One item per line (PN02 "mỗi dòng một ý"); blank lines are dropped. */
export function LinesInput({
  label,
  value,
  onChange,
  path,
  help,
  max = 12,
}: {
  label: ReactNode;
  value: string[];
  onChange: (v: string[]) => void;
  path: Path;
  help?: ReactNode;
  max?: number;
}) {
  const id = useId();
  const intl = useIntl();
  // Typing keeps blank lines until the text is saved; the data only holds the filled ones.
  const [text, setText] = useState(value.join('\n'));
  const errList = useRhythmIssue(path);
  const { issues, show } = useContext(IssuesContext);
  const itemErr = show
    ? value
        .map((_, i) => issues.get(pathKey([...path, i])))
        .find((x): x is Issue => x !== undefined)
    : undefined;
  const err = errList ?? (itemErr ? rhythmIssueText(intl, itemErr) : undefined);
  return (
    <Field label={label} htmlFor={id} counter={{ n: value.length, max }} help={help} error={err}>
      <Textarea
        id={id}
        rows={Math.min(8, Math.max(3, value.length + 1))}
        value={text}
        aria-invalid={err ? true : undefined}
        onChange={(e) => {
          setText(e.target.value);
          onChange(
            e.target.value
              .split('\n')
              .map((l) => l.trim())
              .filter(Boolean),
          );
        }}
      />
    </Field>
  );
}

/** A group of fields under one label (a `<fieldset>`), with an optional "?" hint. */
function Group({
  label,
  hint,
  children,
  className,
}: {
  label: ReactNode;
  hint?: ReactNode;
  children: ReactNode;
  className?: string;
}) {
  return (
    <fieldset className={cn('min-w-0', className)}>
      <legend className="mb-2 flex items-center gap-1.5 text-[13px] font-medium">
        {label}
        {hint && <Hint>{hint}</Hint>}
      </legend>
      {children}
    </fieldset>
  );
}

/** vi and en lists side by side. */
export function LocLines({
  label,
  value,
  onChange,
  path,
}: {
  label: ReactNode;
  value: LocalizedList;
  onChange: (v: LocalizedList) => void;
  path: Path;
}) {
  const intl = useIntl();
  return (
    <Group label={label} hint={<FormattedMessage id="rhythm.field.onePerLine" />}>
      <div className="grid gap-3 md:grid-cols-2">
        {langs.map((lang) => (
          <LinesInput
            key={lang}
            label={intl.formatMessage({ id: `rhythm.lang.${lang}` })}
            value={value[lang]}
            path={[...path, lang]}
            onChange={(v) => onChange({ ...value, [lang]: v })}
          />
        ))}
      </div>
    </Group>
  );
}

/** A text in both languages, side by side. */
export function LocField({
  label,
  value,
  onChange,
  path,
  multiline,
  max,
  help,
  hint,
}: {
  label: ReactNode;
  value: Localized;
  onChange: (v: Localized) => void;
  path: Path;
  multiline?: boolean;
  max: number;
  help?: ReactNode;
  hint?: ReactNode;
}) {
  const intl = useIntl();
  const id = useId();
  const errs = { vi: useRhythmIssue([...path, 'vi']), en: useRhythmIssue([...path, 'en']) };
  const errAll = useRhythmIssue(path);
  return (
    <Group label={label} hint={hint}>
      <div className="grid gap-3 md:grid-cols-2">
        {langs.map((lang) => {
          const props = {
            id: `${id}-${lang}`,
            value: value[lang],
            maxLength: max,
            'aria-invalid': errs[lang] ? true : undefined,
            onChange: (e: { target: { value: string } }) =>
              onChange({ ...value, [lang]: e.target.value }),
          };
          return (
            <div key={lang} className="grid min-w-0 gap-1">
              <Label htmlFor={props.id} className="text-xs font-normal text-muted-foreground">
                {intl.formatMessage({ id: `rhythm.lang.${lang}` })}
              </Label>
              {multiline ? <Textarea rows={3} {...props} /> : <Input {...props} />}
              <FieldError text={errs[lang]} />
            </div>
          );
        })}
      </div>
      <FieldError text={errAll} className="mt-1.5" />
      {help && <p className="mt-1.5 text-xs text-muted-foreground">{help}</p>}
    </Group>
  );
}

/** A text that may be absent (safety note): both languages empty = none. */
export function OptionalLocField(
  props: Omit<Parameters<typeof LocField>[0], 'value' | 'onChange'> & {
    value: Localized | null;
    onChange: (v: Localized | null) => void;
  },
) {
  return (
    <LocField
      {...props}
      value={props.value ?? { vi: '', en: '' }}
      onChange={(v) => props.onChange(!v.vi && !v.en ? null : v)}
      help={props.help ?? <FormattedMessage id="rhythm.optionalText" />}
    />
  );
}

/** Codes typed as "VN, SG" (kept as text while typing). */
function CodesInput({
  label,
  value,
  onChange,
  path,
  hint,
}: {
  label: ReactNode;
  value: string[];
  onChange: (v: string[]) => void;
  path: Path;
  hint?: ReactNode;
}) {
  const id = useId();
  const intl = useIntl();
  const [text, setText] = useState(value.join(', '));
  const { issues, show } = useContext(IssuesContext);
  const err = show
    ? [issues.get(pathKey(path)), ...value.map((_, i) => issues.get(pathKey([...path, i])))].find(
        (x): x is Issue => x !== undefined,
      )
    : undefined;
  return (
    <Field
      label={label}
      htmlFor={id}
      hint={hint}
      error={err ? rhythmIssueText(intl, err) : undefined}
    >
      <Input
        id={id}
        className={cn(monoInput, 'sm:w-64')}
        value={text}
        placeholder="VN, SG"
        onChange={(e) => {
          setText(e.target.value);
          onChange(
            e.target.value
              .split(/[\s,]+/)
              .map((c) => c.trim().toUpperCase())
              .filter(Boolean),
          );
        }}
      />
    </Field>
  );
}

function Checks<T extends string>({
  label,
  options,
  value,
  onChange,
  path,
  labelOf,
}: {
  label: ReactNode;
  options: readonly T[];
  value: readonly T[];
  onChange: (v: T[]) => void;
  path: Path;
  labelOf: (v: T) => string;
}) {
  const err = useRhythmIssue(path);
  return (
    <Group label={label}>
      <div className="flex flex-wrap gap-x-5 gap-y-2">
        {options.map((o) => (
          <CheckRow
            key={o}
            label={labelOf(o)}
            checked={value.includes(o)}
            onChange={(on) =>
              onChange(
                on
                  ? options.filter((x) => x === o || value.includes(x))
                  : value.filter((x) => x !== o),
              )
            }
          />
        ))}
      </div>
      <FieldError text={err} className="mt-1.5" />
    </Group>
  );
}

function SelectInput<T extends string>({
  label,
  value,
  options,
  onChange,
  hint,
  className,
}: {
  label: ReactNode;
  value: T;
  options: Array<{ value: T; label: string }>;
  onChange: (v: T) => void;
  hint?: ReactNode;
  className?: string;
}) {
  const id = useId();
  return (
    <Field label={label} htmlFor={id} hint={hint} className={className}>
      <FieldSelect id={id} value={value} options={options} onChange={onChange} />
    </Field>
  );
}

/** "Thêm …" under a list: a quiet button with a plus. */
function AddButton({
  children,
  disabled,
  onClick,
}: {
  children: ReactNode;
  disabled?: boolean;
  onClick: () => void;
}) {
  return (
    <Button variant="outline" size="sm" disabled={disabled} onClick={onClick}>
      <Plus />
      {children}
    </Button>
  );
}

type Source = { label: string; url: string };

/** "Nguồn": label + link rows. */
export function SourcesInput({
  value,
  onChange,
  path,
  max,
}: {
  value: Source[];
  onChange: (v: Source[]) => void;
  path: Path;
  max: number;
}) {
  const intl = useIntl();
  const errList = useRhythmIssue(path);
  return (
    <div className="grid gap-2">
      {value.length === 0 && (
        <p className="text-sm text-muted-foreground">
          <FormattedMessage id="rhythm.noSources" />
        </p>
      )}
      {value.map((s, i) => (
        <SourceRow
          key={i}
          value={s}
          path={[...path, i]}
          onChange={(v) => onChange(value.map((x, j) => (j === i ? v : x)))}
          onRemove={() => onChange(value.filter((_, j) => j !== i))}
          removeLabel={intl.formatMessage({ id: 'rhythm.remove' })}
        />
      ))}
      <FieldError text={errList} />
      <div className="flex items-center gap-3">
        <AddButton
          disabled={value.length >= max}
          onClick={() => onChange([...value, { label: '', url: 'https://' }])}
        >
          <FormattedMessage id="rhythm.field.addSource" />
        </AddButton>
        <span className="text-xs text-muted-foreground tabular-nums">
          {value.length}/{max}
        </span>
      </div>
    </div>
  );
}

function SourceRow({
  value,
  path,
  onChange,
  onRemove,
  removeLabel,
}: {
  value: Source;
  path: Path;
  onChange: (v: Source) => void;
  onRemove: () => void;
  removeLabel: string;
}) {
  const intl = useIntl();
  const errLabel = useRhythmIssue([...path, 'label']);
  const errUrl = useRhythmIssue([...path, 'url']);
  return (
    <div className="grid items-start gap-2 sm:grid-cols-[minmax(0,1fr)_minmax(0,1.3fr)_auto]">
      <div className="grid gap-1">
        <Input
          value={value.label}
          maxLength={200}
          placeholder={intl.formatMessage({ id: 'rhythm.field.sourceLabel' })}
          aria-label={intl.formatMessage({ id: 'rhythm.field.sourceLabel' })}
          aria-invalid={errLabel ? true : undefined}
          onChange={(e) => onChange({ ...value, label: e.target.value })}
        />
        <FieldError text={errLabel} />
      </div>
      <div className="grid gap-1">
        <Input
          className={monoInput}
          value={value.url}
          maxLength={500}
          placeholder="https://"
          aria-label={intl.formatMessage({ id: 'rhythm.field.sourceUrl' })}
          aria-invalid={errUrl ? true : undefined}
          onChange={(e) => onChange({ ...value, url: e.target.value })}
        />
        <FieldError text={errUrl} />
      </div>
      <IconButton icon="remove" label={removeLabel} onClick={onRemove} />
    </div>
  );
}

function AgeDaysInput({
  value,
  onChange,
  path,
  hint,
}: {
  value: { from: number; to: number };
  onChange: (v: { from: number; to: number }) => void;
  path: Path;
  hint?: ReactNode;
}) {
  const err = useRhythmIssue(path);
  return (
    <div className="grid gap-1.5">
      <div className="flex flex-wrap items-end gap-x-4 gap-y-2">
        <NumberInput
          label={<FormattedMessage id="rhythm.field.ageFrom" />}
          value={value.from}
          hint={hint}
          path={[...path, 'ageDays', 'from']}
          onChange={(v) => onChange({ ...value, from: v ?? Number.NaN })}
        />
        <NumberInput
          label={<FormattedMessage id="rhythm.field.ageTo" />}
          value={value.to}
          path={[...path, 'ageDays', 'to']}
          onChange={(v) => onChange({ ...value, to: v ?? Number.NaN })}
        />
        <span className="pb-2 text-sm text-muted-foreground tabular-nums">
          <FormattedMessage
            id="rhythm.field.ageHelp"
            values={{
              from: Number.isFinite(value.from) ? monthsOf(value.from) : '—',
              to: Number.isFinite(value.to) ? monthsOf(value.to) : '—',
            }}
          />
        </span>
      </div>
      <FieldError text={err} />
    </div>
  );
}

/** "Tiếng Việt | English" for forms that show one language at a time; a dot marks problems. */
export function LangSwitch({
  value,
  onChange,
  bad,
}: {
  value: Lang;
  onChange: (l: Lang) => void;
  bad?: Partial<Record<Lang, boolean>>;
}) {
  const intl = useIntl();
  return (
    <ToggleGroup
      type="single"
      variant="outline"
      size="sm"
      value={value}
      aria-label={intl.formatMessage({ id: 'rhythm.lang.switch' })}
      onValueChange={(v) => v && onChange(v as Lang)}
    >
      {langs.map((l) => (
        <ToggleGroupItem key={l} value={l} className="gap-1.5 px-3">
          <FormattedMessage id={`rhythm.lang.${l}`} />
          {bad?.[l] && (
            <>
              <span className="size-1.5 rounded-full bg-destructive" aria-hidden="true" />
              <span className="sr-only">
                <FormattedMessage id="rhythm.lang.hasIssues" />
              </span>
            </>
          )}
        </ToggleGroupItem>
      ))}
    </ToggleGroup>
  );
}

/**
 * "Nâng cao": ids and version numbers, folded away. It opens by itself when one of its fields
 * has a problem (the key remounts it with the new default).
 */
function AdvancedSection({
  bad,
  summary,
  children,
}: {
  bad: boolean;
  summary: ReactNode;
  children: ReactNode;
}) {
  return (
    <Section
      key={bad ? 'open' : 'closed'}
      title={<FormattedMessage id="rhythm.advanced" />}
      collapsible
      defaultOpen={bad}
      summary={summary}
    >
      <div className="grid gap-4 sm:grid-cols-2">{children}</div>
    </Section>
  );
}

/** "Nguồn" of one item, folded with the count; opens when a link is wrong. */
function SourcesSection({
  value,
  onChange,
  path,
  max,
}: {
  value: Source[];
  onChange: (v: Source[]) => void;
  path: Path;
  max: number;
}) {
  const bad = useIssueUnder([path]);
  return (
    <Section
      key={bad ? 'open' : 'closed'}
      title={<FormattedMessage id="rhythm.section.sources" />}
      collapsible
      defaultOpen={bad}
      summary={<FormattedMessage id="rhythm.sourcesCount" values={{ n: value.length }} />}
    >
      <SourcesInput value={value} max={max} path={path} onChange={onChange} />
    </Section>
  );
}

// ---------- Reference model (PN01 label and sources; PN02 one stage) ----------

export function ModelEditor({
  model,
  edit,
}: {
  model: ReferenceDraftData;
  edit: Edit<ReferenceDraftData>;
}) {
  return (
    <div className="grid gap-5">
      <TextInput
        label={<FormattedMessage id="rhythm.field.label" />}
        value={model.label}
        max={60}
        path={['label']}
        hint={<FormattedMessage id="rhythm.field.labelHelp" />}
        className="sm:max-w-sm"
        onChange={(v) =>
          edit((m) => {
            m.label = v;
          })
        }
      />
      <Group label={<FormattedMessage id="rhythm.field.sources" />}>
        <SourcesInput
          value={model.sources}
          max={10}
          path={['sources']}
          onChange={(v) =>
            edit((m) => {
              m.sources = v;
            })
          }
        />
      </Group>
    </div>
  );
}

export interface ActivityOption {
  id: string;
  title: string;
  durationMin: number;
}

const fold = (s: string) =>
  s.normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/gi, 'd').toLowerCase();

/** Whether `query` is in one of the texts, ignoring case and Vietnamese marks. */
export const matches = (query: string, ...texts: Array<string | null | undefined>) => {
  const q = fold(query.trim());
  return !q || texts.some((t) => !!t && fold(t).includes(q));
};

/** PN02: VI/EN content, timing with a preview for a sample due date, activities, notice. */
export function StageEditor({
  model,
  index,
  edit,
  idLocked,
  dueDate,
  activities,
}: {
  model: ReferenceDraftData;
  index: number;
  edit: Edit<ReferenceDraftData>;
  idLocked: boolean;
  /** The sample due date picked on the page (YYYY-MM-DD). */
  dueDate: string;
  activities: ActivityOption[];
}) {
  const intl = useIntl();
  const s = model.stages[index]!;
  const base: Path = ['stages', index];
  const [lang, setLang] = useState<Lang>('vi');
  const [query, setQuery] = useState('');
  const set = (fn: (st: ReferenceStage) => void) =>
    edit((m) => {
      fn(m.stages[index]!);
    });
  const windowErr = useRhythmIssue(base);
  const preview = windowPreview(dueDate, s);
  const viBad = useHasIssue(base, 'vi');
  const enBad = useHasIssue(base, 'en');
  const advBad = useIssueUnder([
    [...base, 'id'],
    [...base, 'number'],
  ]);
  const titles = new Map(activities.map((a) => [a.id, a]));
  const shown = activities.filter((a) => matches(query, a.title, a.id));
  const unlink = (id: string) =>
    set((st) => void (st.activityIds = st.activityIds.filter((x) => x !== id)));
  return (
    <div className="grid gap-4">
      <Section
        title={<FormattedMessage id="rhythm.stage.content" />}
        actions={<LangSwitch value={lang} onChange={setLang} bad={{ vi: viBad, en: enBad }} />}
      >
        <div className="grid gap-4" key={lang}>
          <TextInput
            label={<FormattedMessage id="rhythm.field.name" />}
            value={s.name[lang]}
            max={2000}
            path={[...base, 'name', lang]}
            hint={<FormattedMessage id="rhythm.field.nameHelp" />}
            onChange={(v) => set((st) => void (st.name[lang] = v))}
          />
          <LinesInput
            label={<FormattedMessage id="rhythm.field.signs" />}
            value={s.signs[lang]}
            path={[...base, 'signs', lang]}
            help={<FormattedMessage id="rhythm.field.onePerLine" />}
            onChange={(v) => set((st) => void (st.signs[lang] = v))}
          />
          <LinesInput
            label={<FormattedMessage id="rhythm.field.skills" />}
            value={s.skills[lang]}
            path={[...base, 'skills', lang]}
            onChange={(v) => set((st) => void (st.skills[lang] = v))}
          />
        </div>
      </Section>

      <Section title={<FormattedMessage id="rhythm.stage.timing" />}>
        <div className="flex flex-wrap items-start gap-x-6 gap-y-3">
          <NumberInput
            label={<FormattedMessage id="rhythm.field.start" />}
            value={s.startOffsetDays}
            unit={<FormattedMessage id="rhythm.field.offsetUnit" />}
            path={[...base, 'startOffsetDays']}
            onChange={(v) => set((st) => void (st.startOffsetDays = v ?? Number.NaN))}
          />
          <NumberInput
            label={<FormattedMessage id="rhythm.field.end" />}
            value={s.endOffsetDays}
            unit={<FormattedMessage id="rhythm.field.offsetUnit" />}
            hint={<FormattedMessage id="rhythm.field.endHelp" />}
            path={[...base, 'endOffsetDays']}
            onChange={(v) => set((st) => void (st.endOffsetDays = v ?? Number.NaN))}
          />
        </div>
        <FieldError text={windowErr} className="mt-2" />
        <p className="mt-3 rounded-lg bg-muted/60 px-3 py-2 text-sm tabular-nums">
          {preview ? (
            <FormattedMessage
              id="rhythm.stage.preview"
              values={{ due: dmy(dueDate), start: dmy(preview.start), end: dmy(preview.end) }}
            />
          ) : (
            <FormattedMessage id="rhythm.stage.previewNone" />
          )}
        </p>
      </Section>

      <Section
        title={
          <FormattedMessage
            id="rhythm.field.activities"
            values={{ n: s.activityIds.length, max: 8 }}
          />
        }
      >
        <div className="grid gap-3">
          {s.activityIds.length > 0 && (
            <ul
              className="flex flex-wrap gap-1.5"
              aria-label={intl.formatMessage({ id: 'rhythm.stage.linked' })}
            >
              {s.activityIds.map((id) => {
                const a = titles.get(id);
                return (
                  <li
                    key={id}
                    className={cn(
                      'inline-flex max-w-full items-center gap-1 rounded-full border py-0.5 pr-1 pl-2.5 text-xs',
                      a ? 'bg-secondary' : 'border-warning/50 bg-warning/10',
                    )}
                  >
                    <span className="truncate">
                      {a ? (
                        a.title || a.id
                      ) : (
                        <FormattedMessage id="rhythm.stage.unknownActivity" values={{ id }} />
                      )}
                    </span>
                    <button
                      type="button"
                      className="grid size-5 place-items-center rounded-full text-muted-foreground hover:bg-muted hover:text-foreground"
                      aria-label={intl.formatMessage(
                        { id: 'rhythm.stage.unlink' },
                        { name: a?.title || id },
                      )}
                      onClick={() => unlink(id)}
                    >
                      <X className="size-3" />
                    </button>
                  </li>
                );
              })}
            </ul>
          )}
          {activities.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              <FormattedMessage id="rhythm.stage.noActivities" />
            </p>
          ) : (
            <>
              {activities.length > 8 && (
                <SearchInput
                  value={query}
                  onChange={setQuery}
                  placeholder={intl.formatMessage({ id: 'rhythm.stage.searchActivities' })}
                  className="sm:w-72"
                />
              )}
              <div className="grid max-h-80 gap-x-5 gap-y-2 overflow-y-auto p-0.5 sm:grid-cols-2">
                {shown.map((a) => (
                  <CheckRow
                    key={a.id}
                    label={
                      <span className="min-w-0">
                        {a.title || a.id}{' '}
                        <span className="font-normal text-muted-foreground">
                          · <FormattedMessage id="rhythm.minutes" values={{ n: a.durationMin }} />
                        </span>
                      </span>
                    }
                    checked={s.activityIds.includes(a.id)}
                    disabled={!s.activityIds.includes(a.id) && s.activityIds.length >= 8}
                    onChange={(on) =>
                      set((st) => {
                        st.activityIds = on
                          ? [...st.activityIds, a.id]
                          : st.activityIds.filter((x) => x !== a.id);
                      })
                    }
                  />
                ))}
                {shown.length === 0 && (
                  <p className="text-sm text-muted-foreground">
                    <FormattedMessage id="rhythm.noMatch" />
                  </p>
                )}
              </div>
            </>
          )}
        </div>
      </Section>

      <NoticeSection stage={s} base={base} set={set} />

      <AdvancedSection bad={advBad} summary={<span className="font-mono text-xs">{s.id}</span>}>
        <TextInput
          label={<FormattedMessage id="rhythm.field.stageId" />}
          value={s.id}
          mono
          disabled={idLocked}
          path={[...base, 'id']}
          help={
            <FormattedMessage id={idLocked ? 'rhythm.field.idLocked' : 'rhythm.field.idHelp'} />
          }
          onChange={(v) => set((st) => void (st.id = v))}
        />
        <NumberInput
          label={<FormattedMessage id="rhythm.field.number" />}
          value={s.number}
          hint={<FormattedMessage id="rhythm.field.numberHelp" />}
          path={[...base, 'number']}
          onChange={(v) => set((st) => void (st.number = v ?? Number.NaN))}
        />
      </AdvancedSection>
    </div>
  );
}

/** PN02 reminder: short enough for a phone notification, both languages side by side. */
function NoticeSection({
  stage: s,
  base,
  set,
}: {
  stage: ReferenceStage;
  base: Path;
  set: (fn: (st: ReferenceStage) => void) => void;
}) {
  const id = useId();
  return (
    <Section
      title={<FormattedMessage id="rhythm.stage.notice" />}
      hint={<FormattedMessage id="rhythm.field.noticeHelp" />}
      actions={
        <div className="flex items-center gap-2">
          <Switch
            id={id}
            checked={s.notice !== null}
            onCheckedChange={(on) =>
              set((st) => {
                st.notice = on ? { title: loc(), body: loc() } : null;
              })
            }
          />
          <Label htmlFor={id} className="text-[13px]">
            <FormattedMessage id="rhythm.field.noticeOn" />
          </Label>
        </div>
      }
    >
      {s.notice ? (
        <div className="grid gap-x-6 gap-y-5 md:grid-cols-2">
          {langs.map((lang) => (
            <Group key={lang} label={<FormattedMessage id={`rhythm.lang.${lang}`} />}>
              <div className="grid gap-4">
                <TextInput
                  label={<FormattedMessage id="rhythm.field.noticeTitle" />}
                  value={s.notice!.title[lang]}
                  counter={noticeLimits.title}
                  path={[...base, 'notice', 'title', lang]}
                  onChange={(v) => set((st) => void (st.notice!.title[lang] = v))}
                />
                <TextInput
                  label={<FormattedMessage id="rhythm.field.noticeBody" />}
                  value={s.notice!.body[lang]}
                  counter={noticeLimits.body}
                  multiline
                  path={[...base, 'notice', 'body', lang]}
                  // A notification body is one line.
                  onChange={(v) =>
                    set((st) => void (st.notice!.body[lang] = v.replace(/\s*\n\s*/g, ' ')))
                  }
                />
              </div>
            </Group>
          ))}
        </div>
      ) : (
        <p className="text-sm text-muted-foreground">
          <FormattedMessage id="rhythm.stage.noNotice" />
        </p>
      )}
    </Section>
  );
}

// ---------- Content (PN03) ----------

const itemStatuses = ['draft', 'published', 'retired'] as const;
const timesOfDay = ['any', 'evening', 'day'] as const;

function StatusSelect({
  status,
  onStatus,
}: {
  status: (typeof itemStatuses)[number];
  onStatus: (v: (typeof itemStatuses)[number]) => void;
}) {
  const intl = useIntl();
  return (
    <SelectInput
      label={<FormattedMessage id="rhythm.field.itemStatus" />}
      hint={<FormattedMessage id="rhythm.field.statusHelp" />}
      value={status}
      className="sm:max-w-xs"
      options={itemStatuses.map((s) => ({
        value: s,
        label: intl.formatMessage({ id: `rhythm.itemStatus.${s}` }),
      }))}
      onChange={onStatus}
    />
  );
}

/** The item's id (fixed once published) and its content version, in "Nâng cao". */
function ItemIdFields({
  id,
  version,
  idLocked,
  path,
  onId,
}: {
  id: string;
  version: number;
  idLocked: boolean;
  path: Path;
  onId: (v: string) => void;
}) {
  return (
    <>
      <TextInput
        label={<FormattedMessage id="rhythm.field.itemId" />}
        value={id}
        mono
        disabled={idLocked}
        path={[...path, 'id']}
        help={
          <FormattedMessage id={idLocked ? 'rhythm.field.idLocked' : 'rhythm.field.itemIdHelp'} />
        }
        onChange={onId}
      />
      <div className="grid content-start gap-1.5">
        <span className="flex min-h-5 items-center gap-1.5 text-[13px] font-medium">
          <FormattedMessage id="rhythm.field.version" />
          <Hint>
            <FormattedMessage id="rhythm.field.versionHelp" />
          </Hint>
        </span>
        <span className="flex h-9 items-center font-mono text-sm tabular-nums">v{version}</span>
      </div>
    </>
  );
}

export function ActivityEditor({
  data,
  index,
  edit,
  idLocked,
}: {
  data: ContentDraftData;
  index: number;
  edit: Edit<ContentDraftData>;
  idLocked: boolean;
}) {
  const intl = useIntl();
  const a = data.activities[index]!;
  const base: Path = ['activities', index];
  const set = (fn: (x: Activity) => void) =>
    edit((d) => {
      fn(d.activities[index]!);
    });
  const advBad = useIssueUnder([[...base, 'id']]);
  return (
    <div className="grid gap-4">
      <Section title={<FormattedMessage id="rhythm.section.basics" />}>
        <div className="grid gap-5">
          <LocField
            label={<FormattedMessage id="rhythm.field.title" />}
            value={a.title}
            max={2000}
            path={[...base, 'title']}
            onChange={(v) => set((x) => void (x.title = v))}
          />
          <LocField
            label={<FormattedMessage id="rhythm.field.summary" />}
            value={a.summary}
            multiline
            max={2000}
            path={[...base, 'summary']}
            onChange={(v) => set((x) => void (x.summary = v))}
          />
          <StatusSelect status={a.status} onStatus={(v) => set((x) => void (x.status = v))} />
        </div>
      </Section>
      <Section title={<FormattedMessage id="rhythm.section.howTo" />}>
        <div className="grid gap-5">
          <LocLines
            label={<FormattedMessage id="rhythm.field.steps" />}
            value={a.steps}
            path={[...base, 'steps']}
            onChange={(v) => set((x) => void (x.steps = v))}
          />
          <OptionalLocField
            label={<FormattedMessage id="rhythm.field.safety" />}
            value={a.safety}
            multiline
            max={2000}
            path={[...base, 'safety']}
            onChange={(v) => set((x) => void (x.safety = v))}
          />
        </div>
      </Section>
      <Section title={<FormattedMessage id="rhythm.section.when" />}>
        <div className="grid gap-5">
          <div className="flex flex-wrap items-start gap-x-6 gap-y-4">
            <NumberInput
              label={<FormattedMessage id="rhythm.field.duration" />}
              value={a.durationMin}
              path={[...base, 'durationMin']}
              onChange={(v) => set((x) => void (x.durationMin = v ?? Number.NaN))}
            />
            <SelectInput
              label={<FormattedMessage id="rhythm.field.timeOfDay" />}
              value={a.timeOfDay}
              className="w-64"
              options={timesOfDay.map((t) => ({
                value: t,
                label: intl.formatMessage({ id: `rhythm.timeOfDay.${t}` }),
              }))}
              onChange={(v) => set((x) => void (x.timeOfDay = v))}
            />
          </div>
          <AgeDaysInput
            value={a.ageDays}
            path={base}
            onChange={(v) => set((x) => void (x.ageDays = v))}
          />
          <Checks
            label={<FormattedMessage id="rhythm.field.needs" />}
            options={needs}
            value={a.needs}
            path={[...base, 'needs']}
            labelOf={(n) => intl.formatMessage({ id: `rhythm.need.${n}` })}
            onChange={(v) => set((x) => void (x.needs = v))}
          />
          <Checks
            label={<FormattedMessage id="rhythm.field.interests" />}
            options={interests}
            value={a.interests}
            path={[...base, 'interests']}
            labelOf={(n) => intl.formatMessage({ id: `rhythm.interest.${n}` })}
            onChange={(v) => set((x) => void (x.interests = v))}
          />
          <div className="grid gap-5 sm:grid-cols-2">
            <Checks
              label={<FormattedMessage id="rhythm.field.locales" />}
              options={langs}
              value={a.locales}
              path={[...base, 'locales']}
              labelOf={(l) => intl.formatMessage({ id: `rhythm.lang.${l}` })}
              onChange={(v) => set((x) => void (x.locales = v))}
            />
            <CodesInput
              label={<FormattedMessage id="rhythm.field.regions" />}
              value={a.regions}
              path={[...base, 'regions']}
              hint={<FormattedMessage id="rhythm.field.regionsHelp" />}
              onChange={(v) => set((x) => void (x.regions = v))}
            />
          </div>
        </div>
      </Section>
      <SourcesSection
        value={a.sources}
        max={6}
        path={[...base, 'sources']}
        onChange={(v) => set((x) => void (x.sources = v))}
      />
      <AdvancedSection
        bad={advBad}
        summary={
          <span className="font-mono text-xs">
            {a.id} · v{a.version}
          </span>
        }
      >
        <ItemIdFields
          id={a.id}
          version={a.version}
          idLocked={idLocked}
          path={base}
          onId={(v) => set((x) => void (x.id = v))}
        />
      </AdvancedSection>
    </div>
  );
}

export function AgeCardEditor({
  data,
  index,
  edit,
  idLocked,
}: {
  data: ContentDraftData;
  index: number;
  edit: Edit<ContentDraftData>;
  idLocked: boolean;
}) {
  const intl = useIntl();
  const c = data.ageCards[index]!;
  const base: Path = ['ageCards', index];
  const set = (fn: (x: AgeCard) => void) =>
    edit((d) => {
      fn(d.ageCards[index]!);
    });
  const advBad = useIssueUnder([[...base, 'id']]);
  return (
    <div className="grid gap-4">
      <Section title={<FormattedMessage id="rhythm.section.basics" />}>
        <div className="grid gap-5">
          <AgeDaysInput
            value={c.ageDays}
            path={base}
            hint={<FormattedMessage id="rhythm.field.ageCardHelp" />}
            onChange={(v) => set((x) => void (x.ageDays = v))}
          />
          <LocField
            label={<FormattedMessage id="rhythm.field.title" />}
            value={c.title}
            max={2000}
            path={[...base, 'title']}
            onChange={(v) => set((x) => void (x.title = v))}
          />
          <LocField
            label={<FormattedMessage id="rhythm.field.body" />}
            value={c.body}
            multiline
            max={2000}
            path={[...base, 'body']}
            onChange={(v) => set((x) => void (x.body = v))}
          />
          <StatusSelect status={c.status} onStatus={(v) => set((x) => void (x.status = v))} />
        </div>
      </Section>
      <Section title={<FormattedMessage id="rhythm.section.tips" />}>
        <div className="grid gap-5">
          <LocLines
            label={<FormattedMessage id="rhythm.field.tips" />}
            value={c.tips}
            path={[...base, 'tips']}
            onChange={(v) => set((x) => void (x.tips = v))}
          />
          <LocLines
            label={<FormattedMessage id="rhythm.field.watchFor" />}
            value={c.watchFor}
            path={[...base, 'watchFor']}
            onChange={(v) => set((x) => void (x.watchFor = v))}
          />
          <Checks
            label={<FormattedMessage id="rhythm.field.interests" />}
            options={interests}
            value={c.interests}
            path={[...base, 'interests']}
            labelOf={(n) => intl.formatMessage({ id: `rhythm.interest.${n}` })}
            onChange={(v) => set((x) => void (x.interests = v))}
          />
        </div>
      </Section>
      <SourcesSection
        value={c.sources}
        max={6}
        path={[...base, 'sources']}
        onChange={(v) => set((x) => void (x.sources = v))}
      />
      <AdvancedSection
        bad={advBad}
        summary={
          <span className="font-mono text-xs">
            {c.id} · v{c.version}
          </span>
        }
      >
        <ItemIdFields
          id={c.id}
          version={c.version}
          idLocked={idLocked}
          path={base}
          onId={(v) => set((x) => void (x.id = v))}
        />
      </AdvancedSection>
    </div>
  );
}

/** NL05b / NL06 / HL01: free in every plan state; numbers only from this list. */
export function HealthEditor({
  data,
  edit,
}: {
  data: ContentDraftData;
  edit: Edit<ContentDraftData>;
}) {
  const intl = useIntl();
  const h = data.health;
  const base: Path = ['health'];
  const set = (fn: (x: HealthPack) => void) =>
    edit((d) => {
      fn(d.health);
    });
  const signsErr = useRhythmIssue([...base, 'signs']);
  // Check-ins answer these ids (NL05b); a sign outside the list could never be asked.
  const unusedSign = healthSigns.find((id) => !h.signs.some((s) => s.id === id));
  const remove = intl.formatMessage({ id: 'rhythm.remove' });
  return (
    <div className="grid gap-4">
      <Section
        title={
          <FormattedMessage id="rhythm.health.signs" values={{ n: h.signs.length, max: 20 }} />
        }
        hint={<FormattedMessage id="rhythm.health.signsHelp" />}
        actions={
          <AddButton
            disabled={!unusedSign}
            onClick={() =>
              unusedSign &&
              set((x) => void x.signs.push({ id: unusedSign, label: loc(), maxAgeDays: null }))
            }
          >
            <FormattedMessage id="rhythm.health.addSign" />
          </AddButton>
        }
      >
        <div className="grid gap-3">
          {h.signs.map((s, i) => (
            <div key={i} className="grid gap-4 rounded-lg border bg-background/40 p-4">
              <div className="flex items-center gap-2">
                <span className="grid size-6 shrink-0 place-items-center rounded-full bg-muted text-xs font-medium tabular-nums">
                  {i + 1}
                </span>
                <span className="min-w-0 truncate text-sm font-medium">
                  {s.label.vi || <span className="font-mono text-xs">{s.id}</span>}
                </span>
                <span className="ml-auto flex shrink-0 items-center">
                  <IconButton
                    icon="up"
                    label={intl.formatMessage({ id: 'rhythm.moveUp' })}
                    disabled={i === 0}
                    onClick={() => set((x) => moveItem(x.signs, i, -1))}
                  />
                  <IconButton
                    icon="down"
                    label={intl.formatMessage({ id: 'rhythm.moveDown' })}
                    disabled={i === h.signs.length - 1}
                    onClick={() => set((x) => moveItem(x.signs, i, 1))}
                  />
                  <IconButton
                    icon="remove"
                    label={remove}
                    disabled={h.signs.length <= 1}
                    onClick={() => set((x) => void x.signs.splice(i, 1))}
                  />
                </span>
              </div>
              <LocField
                label={<FormattedMessage id="rhythm.field.signLabel" />}
                value={s.label}
                max={2000}
                path={[...base, 'signs', i, 'label']}
                onChange={(v) => set((x) => void (x.signs[i]!.label = v))}
              />
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="grid content-start gap-1">
                  <SelectInput
                    label={<FormattedMessage id="rhythm.field.signId" />}
                    value={s.id}
                    options={[...new Set<string>([...healthSigns, s.id])].map((id) => ({
                      value: id,
                      label: id,
                    }))}
                    onChange={(v) => set((x) => void (x.signs[i]!.id = v))}
                  />
                  <SignIdError path={[...base, 'signs', i, 'id']} />
                </div>
                <NumberInput
                  label={<FormattedMessage id="rhythm.field.maxAgeDays" />}
                  value={s.maxAgeDays}
                  nullable
                  placeholder="∞"
                  path={[...base, 'signs', i, 'maxAgeDays']}
                  hint={<FormattedMessage id="rhythm.field.maxAgeDaysHelp" />}
                  onChange={(v) => set((x) => void (x.signs[i]!.maxAgeDays = v))}
                />
              </div>
            </div>
          ))}
          <FieldError text={signsErr} />
        </div>
      </Section>
      <Section title={<FormattedMessage id="rhythm.health.waiting" />}>
        <div className="grid gap-5">
          <LocLines
            label={<FormattedMessage id="rhythm.field.whileWaiting" />}
            value={h.whileWaiting}
            path={[...base, 'whileWaiting']}
            onChange={(v) => set((x) => void (x.whileWaiting = v))}
          />
          <LocField
            label={<FormattedMessage id="rhythm.field.disclaimer" />}
            value={h.disclaimer}
            multiline
            max={2000}
            path={[...base, 'disclaimer']}
            onChange={(v) => set((x) => void (x.disclaimer = v))}
          />
        </div>
      </Section>
      <Section
        title={<FormattedMessage id="rhythm.health.regions" values={{ n: h.regions.length }} />}
        hint={<FormattedMessage id="rhythm.health.regionsHelp" />}
        actions={
          <AddButton
            disabled={h.regions.length >= 60}
            onClick={() => set((x) => void x.regions.push({ country: '', emergencyNumber: '' }))}
          >
            <FormattedMessage id="rhythm.health.addRegion" />
          </AddButton>
        }
      >
        <div className="grid gap-2">
          {h.regions.length > 0 && (
            <div className="grid grid-cols-[6rem_8rem_auto] gap-2 text-xs text-muted-foreground">
              <span>
                <FormattedMessage id="rhythm.field.country" />
              </span>
              <span>
                <FormattedMessage id="rhythm.field.emergencyNumber" />
              </span>
            </div>
          )}
          {h.regions.map((r, i) => (
            <RegionRow
              key={i}
              value={r}
              path={[...base, 'regions', i]}
              removeLabel={remove}
              onChange={(v) => set((x) => void (x.regions[i] = v))}
              onRemove={() => set((x) => void x.regions.splice(i, 1))}
            />
          ))}
        </div>
      </Section>
      <SourcesSection
        value={h.sources}
        max={10}
        path={[...base, 'sources']}
        onChange={(v) => set((x) => void (x.sources = v))}
      />
    </div>
  );
}

function SignIdError({ path }: { path: Path }) {
  return <FieldError text={useRhythmIssue(path)} />;
}

function RegionRow({
  value,
  path,
  removeLabel,
  onChange,
  onRemove,
}: {
  value: { country: string; emergencyNumber: string };
  path: Path;
  removeLabel: string;
  onChange: (v: { country: string; emergencyNumber: string }) => void;
  onRemove: () => void;
}) {
  const intl = useIntl();
  const errCountry = useRhythmIssue([...path, 'country']);
  const errNumber = useRhythmIssue([...path, 'emergencyNumber']);
  return (
    <div className="grid grid-cols-[6rem_8rem_auto] items-start gap-2">
      <div className="grid gap-1">
        <Input
          className={monoInput}
          value={value.country}
          maxLength={2}
          placeholder="VN"
          aria-label={intl.formatMessage({ id: 'rhythm.field.country' })}
          aria-invalid={errCountry ? true : undefined}
          onChange={(e) => onChange({ ...value, country: e.target.value.toUpperCase() })}
        />
        <FieldError text={errCountry} />
      </div>
      <div className="grid gap-1">
        <Input
          className={cn(monoInput, 'tabular-nums')}
          value={value.emergencyNumber}
          maxLength={4}
          inputMode="numeric"
          placeholder="115"
          aria-label={intl.formatMessage({ id: 'rhythm.field.emergencyNumber' })}
          aria-invalid={errNumber ? true : undefined}
          onChange={(e) => onChange({ ...value, emergencyNumber: e.target.value.trim() })}
        />
        <FieldError text={errNumber} />
      </div>
      <IconButton icon="remove" label={removeLabel} onClick={onRemove} />
    </div>
  );
}
