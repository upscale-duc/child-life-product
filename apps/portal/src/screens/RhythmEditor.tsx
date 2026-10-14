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
import { useContext, useId, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import type { Api, ContentDraftData, ReferenceDraftData, RhythmReview } from '../api';
import { Button, Segmented, reasonOk } from '../ui';
import {
  IssuesContext,
  LocField,
  OptionalLocField,
  issueText,
  moveItem,
  pathKey,
  type Issue,
} from './FirstAidEditor';
import { CheckRow, FieldSelect, IconButton } from './form-controls';

/**
 * Nhịp lớn lên editors (PN02, PN03): the reference model's stages and the content pack's
 * activities, age cards and health routing. Drafts are checked with the shared contract
 * (`rhythmDraftSchema`) in the browser before "Lưu nháp"; the server checks them again, and the
 * approval re-validates the published document. Pure helpers here are what the tests drive.
 */

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

/** The `staffRhythmAct` request, or null when the reason or review is not acceptable yet. */
export function rhythmActRequest(
  doc: RhythmDoc,
  versionId: string,
  action: Act,
  reason: string,
  review: ReviewInput | null,
  requireReview: boolean,
) {
  if (!reasonOk(reason)) return null;
  let rv: RhythmReview = null;
  if (action === 'approve' && review) {
    const checked = rhythmReviewFrom(review, requireReview);
    if (!checked.ok) return null;
    rv = checked.review;
  } else if (action === 'approve' && requireReview) {
    return null;
  }
  const res = rhythmActSchema.safeParse({
    doc,
    versionId,
    action,
    reason: reason.trim(),
    review: rv,
  });
  return res.success ? res.data : null;
}

/** Sends one step of the workflow; nothing is sent when the request is not acceptable. */
export async function sendRhythmAct(
  api: Api,
  doc: RhythmDoc,
  versionId: string,
  action: Act,
  reason: string,
  review: ReviewInput | null,
  requireReview: boolean,
): Promise<{ ok: true; status: string } | { ok: false }> {
  const req = rhythmActRequest(doc, versionId, action, reason, review, requireReview);
  if (!req) return { ok: false };
  const res = await api.call<{ status: string }>('staffRhythmAct', req);
  return { ok: true, status: res?.status ?? '' };
}

/** PN04 "Lưu quy tắc": the server's schema (with the window checks) before it is sent. */
export function rulesIssues(rules: RhythmRules): Map<string, Issue> {
  const res = setRhythmRulesSchema.safeParse({ rules, reason: 'check' });
  const out = new Map<string, Issue>();
  if (res.success) return out;
  for (const i of res.error.issues) {
    const issue = toIssue(i);
    const key = issue.path[1] !== undefined ? String(issue.path[1]) : (issue.message ?? '');
    if (!out.has(key)) out.set(key, issue);
  }
  return out;
}

export async function saveRhythmRules(
  api: Api,
  rules: RhythmRules,
  reason: string,
): Promise<{ ok: true; rules: RhythmRules } | { ok: false }> {
  const req = setRhythmRulesSchema.safeParse({ rules, reason: reason.trim() });
  if (!req.success) return { ok: false };
  const res = await api.call<{ rules: RhythmRules }>('staffSetRhythmRules', req.data);
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

function FieldError({ text }: { text?: string }) {
  return text ? <p className="error fa-err">{text}</p> : null;
}

export function TextInput({
  label,
  value,
  onChange,
  path,
  help,
  mono,
  disabled,
  max,
  counter,
}: {
  label: ReactNode;
  value: string;
  onChange: (v: string) => void;
  path: Path;
  help?: ReactNode;
  mono?: boolean;
  disabled?: boolean;
  max?: number;
  /** Shows "n/limit" and turns red past it (PN02 notice). */
  counter?: number;
}) {
  const id = useId();
  const err = useRhythmIssue(path);
  const n = charCount(value);
  return (
    <div className="field">
      <label className="field__label" htmlFor={id}>
        {label}
        {counter !== undefined && (
          <span className={`rh-counter ${n > counter ? 'error' : 'muted'}`}>
            {' '}
            {n}/{counter}
          </span>
        )}
      </label>
      <input
        id={id}
        className={`field__input ${mono ? 'mono' : ''}`}
        value={value}
        maxLength={max}
        disabled={disabled}
        aria-invalid={err ? true : undefined}
        onChange={(e) => onChange(e.target.value)}
      />
      <FieldError text={err} />
      {help && <p className="field__help">{help}</p>}
    </div>
  );
}

const toNumber = (s: string) => (s.trim() === '' ? Number.NaN : Number(s));

export function NumberInput({
  label,
  value,
  onChange,
  path,
  help,
  nullable,
  placeholder,
  step,
}: {
  label: ReactNode;
  value: number | null;
  onChange: (v: number | null) => void;
  path: Path;
  help?: ReactNode;
  nullable?: boolean;
  placeholder?: string;
  step?: string;
}) {
  const id = useId();
  const err = useRhythmIssue(path);
  return (
    <div className="field">
      <label className="field__label" htmlFor={id}>
        {label}
      </label>
      <input
        id={id}
        className="field__input rh-num"
        type="number"
        step={step ?? '1'}
        placeholder={placeholder}
        value={value === null || Number.isNaN(value) ? '' : value}
        aria-invalid={err ? true : undefined}
        onChange={(e) =>
          onChange(nullable && e.target.value === '' ? null : toNumber(e.target.value))
        }
      />
      <FieldError text={err} />
      {help && <p className="field__help">{help}</p>}
    </div>
  );
}

/** One item per line (PN02 "mỗi dòng một ý"); blank lines are dropped. */
export function LinesInput({
  label,
  value,
  onChange,
  path,
  max = 12,
}: {
  label: ReactNode;
  value: string[];
  onChange: (v: string[]) => void;
  path: Path;
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
  return (
    <div className="field">
      <label className="field__label" htmlFor={id}>
        {label}{' '}
        <span className={value.length > max ? 'error' : 'muted'}>
          {value.length}/{max}
        </span>
      </label>
      <textarea
        id={id}
        className="field__input"
        rows={Math.min(8, Math.max(3, value.length + 1))}
        value={text}
        aria-invalid={errList || itemErr ? true : undefined}
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
      <p className="field__help">
        <FormattedMessage id="rhythm.field.onePerLine" />
      </p>
      <FieldError text={errList ?? (itemErr ? rhythmIssueText(intl, itemErr) : undefined)} />
    </div>
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
    <fieldset className="fa-loc">
      <legend className="field__label">{label}</legend>
      {langs.map((lang) => (
        <LinesInput
          key={lang}
          label={intl.formatMessage({ id: `firstAid.lang.${lang}` })}
          value={value[lang]}
          path={[...path, lang]}
          onChange={(v) => onChange({ ...value, [lang]: v })}
        />
      ))}
    </fieldset>
  );
}

/** Codes typed as "VN, SG" (kept as text while typing). */
function CodesInput({
  label,
  value,
  onChange,
  path,
  help,
}: {
  label: ReactNode;
  value: string[];
  onChange: (v: string[]) => void;
  path: Path;
  help?: ReactNode;
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
    <div className="field">
      <label className="field__label" htmlFor={id}>
        {label}
      </label>
      <input
        id={id}
        className="field__input mono"
        value={text}
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
      <FieldError text={err ? rhythmIssueText(intl, err) : undefined} />
      {help && <p className="field__help">{help}</p>}
    </div>
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
    <fieldset className="fa-list">
      <legend className="field__label">{label}</legend>
      <div className="rh-checks">
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
      <FieldError text={err} />
    </fieldset>
  );
}

function SelectInput<T extends string>({
  label,
  value,
  options,
  onChange,
}: {
  label: ReactNode;
  value: T;
  options: Array<{ value: T; label: string }>;
  onChange: (v: T) => void;
}) {
  const id = useId();
  return (
    <div className="field">
      <label className="field__label" htmlFor={id}>
        {label}
      </label>
      <FieldSelect id={id} value={value} options={options} onChange={onChange} />
    </div>
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
    <fieldset className="fa-list">
      <legend className="field__label">
        <FormattedMessage id="rhythm.field.sources" />{' '}
        <span className="muted">
          {value.length}/{max}
        </span>
      </legend>
      {value.map((s, i) => (
        <SourceRow
          key={i}
          value={s}
          path={[...path, i]}
          onChange={(v) => onChange(value.map((x, j) => (j === i ? v : x)))}
          onRemove={() => onChange(value.filter((_, j) => j !== i))}
          removeLabel={intl.formatMessage({ id: 'firstAid.remove' })}
        />
      ))}
      <FieldError text={errList} />
      <div>
        <Button
          kind="ghost"
          disabled={value.length >= max}
          onClick={() => onChange([...value, { label: '', url: 'https://' }])}
        >
          <FormattedMessage id="rhythm.field.addSource" />
        </Button>
      </div>
    </fieldset>
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
    <div className="fa-row">
      <div className="field">
        <input
          className="field__input"
          value={value.label}
          maxLength={200}
          placeholder={intl.formatMessage({ id: 'rhythm.field.sourceLabel' })}
          aria-label={intl.formatMessage({ id: 'rhythm.field.sourceLabel' })}
          onChange={(e) => onChange({ ...value, label: e.target.value })}
        />
        <FieldError text={errLabel} />
      </div>
      <div className="field">
        <input
          className="field__input mono"
          value={value.url}
          maxLength={500}
          placeholder="https://"
          aria-label={intl.formatMessage({ id: 'rhythm.field.sourceUrl' })}
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
}: {
  value: { from: number; to: number };
  onChange: (v: { from: number; to: number }) => void;
  path: Path;
}) {
  const err = useRhythmIssue(path);
  return (
    <div className="field">
      <div className="fa-inline">
        <NumberInput
          label={<FormattedMessage id="rhythm.field.ageFrom" />}
          value={value.from}
          path={[...path, 'ageDays', 'from']}
          onChange={(v) => onChange({ ...value, from: v ?? Number.NaN })}
        />
        <NumberInput
          label={<FormattedMessage id="rhythm.field.ageTo" />}
          value={value.to}
          path={[...path, 'ageDays', 'to']}
          onChange={(v) => onChange({ ...value, to: v ?? Number.NaN })}
        />
        <p className="field__help">
          <FormattedMessage
            id="rhythm.field.ageHelp"
            values={{
              from: Number.isFinite(value.from) ? monthsOf(value.from) : '—',
              to: Number.isFinite(value.to) ? monthsOf(value.to) : '—',
            }}
          />
        </p>
      </div>
      <FieldError text={err} />
    </div>
  );
}

function Section({ title, children }: { title: ReactNode; children: ReactNode }) {
  return (
    <section className="fa-section">
      <h3 className="fa-section__title">{title}</h3>
      {children}
    </section>
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
    <div className="fa-editor">
      <TextInput
        label={<FormattedMessage id="rhythm.field.label" />}
        value={model.label}
        max={60}
        path={['label']}
        help={<FormattedMessage id="rhythm.field.labelHelp" />}
        onChange={(v) =>
          edit((m) => {
            m.label = v;
          })
        }
      />
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
    </div>
  );
}

export interface ActivityOption {
  id: string;
  title: string;
  durationMin: number;
}

/** PN02: timing with a preview for a sample due date, VI/EN content, activities, notice. */
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
  const set = (fn: (st: ReferenceStage) => void) =>
    edit((m) => {
      fn(m.stages[index]!);
    });
  const windowErr = useRhythmIssue(base);
  const preview = windowPreview(dueDate, s);
  const viBad = useHasIssue(base, 'vi');
  const enBad = useHasIssue(base, 'en');
  const known = new Set(activities.map((a) => a.id));
  return (
    <div className="fa-editor">
      <Section title={<FormattedMessage id="rhythm.stage.timing" />}>
        <div className="fa-cols">
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
            path={[...base, 'number']}
            onChange={(v) => set((st) => void (st.number = v ?? Number.NaN))}
          />
          <NumberInput
            label={<FormattedMessage id="rhythm.field.start" />}
            value={s.startOffsetDays}
            path={[...base, 'startOffsetDays']}
            help={<FormattedMessage id="rhythm.field.startHelp" />}
            onChange={(v) => set((st) => void (st.startOffsetDays = v ?? Number.NaN))}
          />
          <NumberInput
            label={<FormattedMessage id="rhythm.field.end" />}
            value={s.endOffsetDays}
            path={[...base, 'endOffsetDays']}
            help={<FormattedMessage id="rhythm.field.endHelp" />}
            onChange={(v) => set((st) => void (st.endOffsetDays = v ?? Number.NaN))}
          />
        </div>
        <FieldError text={windowErr} />
        <p className="note">
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

      <Section title={<FormattedMessage id="rhythm.stage.content" />}>
        <Segmented
          label={intl.formatMessage({ id: 'rhythm.stage.content' })}
          value={lang}
          onChange={setLang}
          options={langs.map((l) => ({
            value: l,
            label: (
              <>
                <FormattedMessage id={`firstAid.lang.${l}`} />
                {(l === 'vi' ? viBad : enBad) && <span className="error"> •</span>}
              </>
            ),
          }))}
        />
        <div className="stack" key={lang}>
          <TextInput
            label={<FormattedMessage id="rhythm.field.name" />}
            value={s.name[lang]}
            max={2000}
            path={[...base, 'name', lang]}
            help={<FormattedMessage id="rhythm.field.nameHelp" />}
            onChange={(v) => set((st) => void (st.name[lang] = v))}
          />
          <LinesInput
            label={<FormattedMessage id="rhythm.field.signs" />}
            value={s.signs[lang]}
            path={[...base, 'signs', lang]}
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

      <Section
        title={
          <FormattedMessage
            id="rhythm.field.activities"
            values={{ n: s.activityIds.length, max: 8 }}
          />
        }
      >
        {activities.length === 0 ? (
          <p className="muted">
            <FormattedMessage id="rhythm.stage.noActivities" />
          </p>
        ) : (
          <div className="rh-picker">
            {activities.map((a) => (
              <CheckRow
                key={a.id}
                label={
                  <span>
                    {a.title || a.id}{' '}
                    <span className="muted">
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
          </div>
        )}
        {s.activityIds.some((id) => !known.has(id)) && (
          <div className="chips">
            {s.activityIds
              .filter((id) => !known.has(id))
              .map((id) => (
                <span key={id} className="pill pill--warn">
                  <FormattedMessage id="rhythm.stage.unknownActivity" values={{ id }} />
                  <IconButton
                    icon="remove"
                    label={intl.formatMessage({ id: 'firstAid.remove' })}
                    onClick={() =>
                      set((st) => void (st.activityIds = st.activityIds.filter((x) => x !== id)))
                    }
                  />
                </span>
              ))}
          </div>
        )}
      </Section>

      <Section title={<FormattedMessage id="rhythm.stage.notice" />}>
        <CheckRow
          label={<FormattedMessage id="rhythm.field.noticeOn" />}
          checked={s.notice !== null}
          onChange={(on) =>
            set((st) => {
              st.notice = on ? { title: loc(), body: loc() } : null;
            })
          }
        />
        {s.notice && (
          <div className="stack" key={`notice-${lang}`}>
            <TextInput
              label={
                <FormattedMessage
                  id="rhythm.field.noticeTitle"
                  values={{ max: noticeLimits.title }}
                />
              }
              value={s.notice.title[lang]}
              counter={noticeLimits.title}
              path={[...base, 'notice', 'title', lang]}
              onChange={(v) => set((st) => void (st.notice!.title[lang] = v))}
            />
            <TextInput
              label={
                <FormattedMessage
                  id="rhythm.field.noticeBody"
                  values={{ max: noticeLimits.body }}
                />
              }
              value={s.notice.body[lang]}
              counter={noticeLimits.body}
              path={[...base, 'notice', 'body', lang]}
              onChange={(v) => set((st) => void (st.notice!.body[lang] = v))}
            />
            <p className="field__help">
              <FormattedMessage id="rhythm.field.noticeHelp" />
            </p>
          </div>
        )}
      </Section>
    </div>
  );
}

// ---------- Content (PN03) ----------

const itemStatuses = ['draft', 'published', 'retired'] as const;
const timesOfDay = ['any', 'evening', 'day'] as const;

function StatusAndId({
  id,
  status,
  idLocked,
  path,
  onId,
  onStatus,
}: {
  id: string;
  status: (typeof itemStatuses)[number];
  idLocked: boolean;
  path: Path;
  onId: (v: string) => void;
  onStatus: (v: (typeof itemStatuses)[number]) => void;
}) {
  const intl = useIntl();
  return (
    <div className="fa-cols">
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
      <SelectInput
        label={<FormattedMessage id="rhythm.field.itemStatus" />}
        value={status}
        options={itemStatuses.map((s) => ({
          value: s,
          label: intl.formatMessage({ id: `rhythm.itemStatus.${s}` }),
        }))}
        onChange={onStatus}
      />
    </div>
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
  return (
    <div className="fa-editor">
      <Section title={<FormattedMessage id="rhythm.section.basics" />}>
        <StatusAndId
          id={a.id}
          status={a.status}
          idLocked={idLocked}
          path={base}
          onId={(v) => set((x) => void (x.id = v))}
          onStatus={(v) => set((x) => void (x.status = v))}
        />
        <p className="field__help">
          <FormattedMessage id="rhythm.field.statusHelp" />
        </p>
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
      </Section>
      <Section title={<FormattedMessage id="rhythm.section.howTo" />}>
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
      </Section>
      <Section title={<FormattedMessage id="rhythm.section.when" />}>
        <div className="fa-cols">
          <NumberInput
            label={<FormattedMessage id="rhythm.field.duration" />}
            value={a.durationMin}
            path={[...base, 'durationMin']}
            onChange={(v) => set((x) => void (x.durationMin = v ?? Number.NaN))}
          />
          <SelectInput
            label={<FormattedMessage id="rhythm.field.timeOfDay" />}
            value={a.timeOfDay}
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
        <Checks
          label={<FormattedMessage id="rhythm.field.locales" />}
          options={langs}
          value={a.locales}
          path={[...base, 'locales']}
          labelOf={(l) => intl.formatMessage({ id: `firstAid.lang.${l}` })}
          onChange={(v) => set((x) => void (x.locales = v))}
        />
        <CodesInput
          label={<FormattedMessage id="rhythm.field.regions" />}
          value={a.regions}
          path={[...base, 'regions']}
          help={<FormattedMessage id="rhythm.field.regionsHelp" />}
          onChange={(v) => set((x) => void (x.regions = v))}
        />
      </Section>
      <Section title={<FormattedMessage id="rhythm.section.sources" />}>
        <SourcesInput
          value={a.sources}
          max={6}
          path={[...base, 'sources']}
          onChange={(v) => set((x) => void (x.sources = v))}
        />
      </Section>
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
  return (
    <div className="fa-editor">
      <Section title={<FormattedMessage id="rhythm.section.basics" />}>
        <StatusAndId
          id={c.id}
          status={c.status}
          idLocked={idLocked}
          path={base}
          onId={(v) => set((x) => void (x.id = v))}
          onStatus={(v) => set((x) => void (x.status = v))}
        />
        <AgeDaysInput
          value={c.ageDays}
          path={base}
          onChange={(v) => set((x) => void (x.ageDays = v))}
        />
        <p className="field__help">
          <FormattedMessage id="rhythm.field.ageCardHelp" />
        </p>
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
      </Section>
      <Section title={<FormattedMessage id="rhythm.section.tips" />}>
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
      </Section>
      <Section title={<FormattedMessage id="rhythm.section.sources" />}>
        <SourcesInput
          value={c.sources}
          max={6}
          path={[...base, 'sources']}
          onChange={(v) => set((x) => void (x.sources = v))}
        />
      </Section>
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
  const remove = intl.formatMessage({ id: 'firstAid.remove' });
  return (
    <div className="fa-editor">
      <Section
        title={
          <FormattedMessage id="rhythm.health.signs" values={{ n: h.signs.length, max: 20 }} />
        }
      >
        <p className="field__help">
          <FormattedMessage id="rhythm.health.signsHelp" />
        </p>
        {h.signs.map((s, i) => (
          <div key={i} className="rh-card">
            <div className="rh-card__head">
              <strong className="mono">{s.id || `#${i + 1}`}</strong>
              <span className="fa-tools">
                <IconButton
                  icon="up"
                  label={intl.formatMessage({ id: 'firstAid.moveUp' })}
                  disabled={i === 0}
                  onClick={() => set((x) => moveItem(x.signs, i, -1))}
                />
                <IconButton
                  icon="down"
                  label={intl.formatMessage({ id: 'firstAid.moveDown' })}
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
            <div className="fa-cols">
              <div>
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
                help={<FormattedMessage id="rhythm.field.maxAgeDaysHelp" />}
                onChange={(v) => set((x) => void (x.signs[i]!.maxAgeDays = v))}
              />
            </div>
            <LocField
              label={<FormattedMessage id="rhythm.field.signLabel" />}
              value={s.label}
              max={2000}
              path={[...base, 'signs', i, 'label']}
              onChange={(v) => set((x) => void (x.signs[i]!.label = v))}
            />
          </div>
        ))}
        <FieldError text={signsErr} />
        <div>
          <Button
            kind="ghost"
            disabled={!unusedSign}
            onClick={() =>
              unusedSign &&
              set((x) => void x.signs.push({ id: unusedSign, label: loc(), maxAgeDays: null }))
            }
          >
            <FormattedMessage id="rhythm.health.addSign" />
          </Button>
        </div>
      </Section>
      <Section title={<FormattedMessage id="rhythm.health.waiting" />}>
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
      </Section>
      <Section
        title={<FormattedMessage id="rhythm.health.regions" values={{ n: h.regions.length }} />}
      >
        <p className="field__help">
          <FormattedMessage id="rhythm.health.regionsHelp" />
        </p>
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
        <div>
          <Button
            kind="ghost"
            disabled={h.regions.length >= 60}
            onClick={() => set((x) => void x.regions.push({ country: '', emergencyNumber: '' }))}
          >
            <FormattedMessage id="rhythm.health.addRegion" />
          </Button>
        </div>
      </Section>
      <Section title={<FormattedMessage id="rhythm.section.sources" />}>
        <SourcesInput
          value={h.sources}
          max={10}
          path={[...base, 'sources']}
          onChange={(v) => set((x) => void (x.sources = v))}
        />
      </Section>
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
    <div className="fa-row">
      <div className="field">
        <input
          className="field__input mono"
          value={value.country}
          maxLength={2}
          placeholder="VN"
          aria-label={intl.formatMessage({ id: 'rhythm.field.country' })}
          onChange={(e) => onChange({ ...value, country: e.target.value.toUpperCase() })}
        />
        <FieldError text={errCountry} />
      </div>
      <div className="field">
        <input
          className="field__input mono"
          value={value.emergencyNumber}
          maxLength={4}
          inputMode="numeric"
          placeholder="115"
          aria-label={intl.formatMessage({ id: 'rhythm.field.emergencyNumber' })}
          onChange={(e) => onChange({ ...value, emergencyNumber: e.target.value.trim() })}
        />
        <FieldError text={errNumber} />
      </div>
      <IconButton icon="remove" label={removeLabel} onClick={onRemove} />
    </div>
  );
}
