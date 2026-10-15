/**
 * Child Life Assistant ("Lumi") — LIVE text evaluation (docs/assistant/evaluation.md §5,
 * docs/assistant/eval-2026-10-15.md). Runs the REAL OpenAI gateway (`openAiModelGateway`, the
 * production request builder and strict schema) through the REAL callables and worker
 * (`quoteTask` → `startTask` → `runAssistantTask` → `submitClarification` → `getAssistantTask`)
 * against the Firestore EMULATOR with synthetic `test_ev_*` data, and scores each case of
 * `assistant-eval-cases.json` (outcome, intent kinds, fields, clarifications, privacy routing,
 * credits). Never a Cloud Function, never in CI, never against a real project.
 *
 * Run (engineer, with owner approval for the spend):
 *   OPENAI_API_KEY=<from Secret Manager, never printed> \
 *   firebase emulators:exec --only firestore --config <isolated config> --project demo-child-life-eval \
 *     "node_modules/.bin/tsx test/eval/assistant-live-eval.ts --out <dir> [--only id,id] [--max-calls 90]"
 *
 * Output: `<dir>/results.json` (per case: ids, booleans, synthetic expected / actual values, calls,
 * latency, tokens) and a summary table on stdout. Message text is never printed or written.
 * The wording step (`word`) is skipped unless EVAL_WORDING=1 (the engine's template is used; the
 * numbers come from the engine either way), to keep the call budget small.
 */
import { randomUUID } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  assistantConsentVersion,
  defaultEntitlementsConfig,
  defaultFlags,
  type AssistantPart,
  type AssistantTaskSnapshot,
} from '@child-life/contracts';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import {
  getAssistantTask,
  quoteTask,
  setAssistantConsent,
  startTask,
  submitClarification,
  type AssistantDeps,
} from '../../src/assistant.js';
import {
  ModelUnavailable,
  openAiModelGateway,
  type ModelGateway,
} from '../../src/assistant-model.js';
import { localClock, localInstant } from '../../src/assistant-tools.js';
import { runAssistantTask } from '../../src/assistant-worker.js';

// ---------- Dataset ----------

interface ExpectDraft {
  kind: string;
  at?: string;
  start?: string;
  end?: string;
  ml?: number;
  min?: number;
  side?: string;
  total?: number;
  currency?: string;
  category?: string[];
  date?: string;
  merchant?: string;
  title?: string[];
  time?: string | null;
  assignee?: string;
  observation?: string;
  warning?: string;
  review?: string[];
  tolMin?: number;
  tolMl?: number;
  // ---- Lumi 2026-10-16: timers and review fields ----
  timer?: 'sleep' | 'breast';
  action?: 'start' | 'stop';
  /** The timer draft's `at` ("D0 01:05"). */
  tAt?: string;
  /** Exactly these fields missing (review-field correctness). */
  missing?: string[];
  /** Nothing missing or unsure: one tap saves it. */
  noReview?: boolean;
}
interface EvalCase {
  id: string;
  group: string;
  locale: 'vi' | 'en';
  anchor: string;
  as?: 'MOM' | 'DAD' | 'NANNY';
  text: string;
  before?: string[];
  seed?: 'day' | 'bottle0800' | 'sleepTimer' | 'breastTimer';
  answers?: Record<string, { choice?: number | string; member?: string; text?: string }>;
  expect: {
    outcome: string;
    visibility?: 'shared' | 'private';
    credits?: number;
    asks?: string[];
    drafts?: ExpectDraft[];
    replaced?: number;
    calls?: number;
    readDay?: number;
    /** Notice codes the answer must carry (TIMER_RUNNING, SAME_AS_PENDING). */
    codes?: string[];
  };
}

const args = process.argv.slice(2);
const arg = (name: string) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : undefined;
};
const outDir = resolve(arg('out') ?? 'eval-out');
const only = arg('only')?.split(',').filter(Boolean) ?? null;
const maxCalls = Number(arg('max-calls') ?? 90);
const dataset = JSON.parse(
  readFileSync(resolve(import.meta.dirname, 'assistant-eval-cases.json'), 'utf8'),
) as { version: string; cases: EvalCase[] };
const cases = dataset.cases.filter((c) => !only || only.includes(c.id));

const ZONE = 'Asia/Ho_Chi_Minh';
const DAY = '2026-10-15';
const F = 'test_evf';
const MEMBERS = { MOM: 'test_ev_mom', DAD: 'test_ev_dad', NANNY: 'test_ev_nanny' } as const;
const addDays = (date: string, n: number) =>
  new Date(Date.parse(`${date}T00:00:00Z`) + n * 86_400_000).toISOString().slice(0, 10);
const localAt = (spec: string) => {
  // "D-1 22:00" | "14:20" (D0)
  const m = /^(?:D(-?\d+) )?(\d\d:\d\d)$/.exec(spec);
  if (!m) throw new Error(`bad time spec ${spec}`);
  return localInstant(ZONE, addDays(DAY, Number(m[1] ?? 0)), m[2]!);
};
const describeLocal = (iso: string | null | undefined) => {
  if (!iso) return null;
  const at = new Date(iso);
  const date = new Intl.DateTimeFormat('en-CA', { timeZone: ZONE }).format(at);
  const diff = Math.round(
    (Date.parse(`${date}T00:00:00Z`) - Date.parse(`${DAY}T00:00:00Z`)) / 86_400_000,
  );
  return `D${diff} ${localClock(ZONE, at)}`;
};
const dateSpec = (spec: string) =>
  /^D-?\d+$/.test(spec) ? addDays(DAY, Number(spec.slice(1))) : spec;
const fold = (s: string) =>
  s
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .toLowerCase();

// ---------- Gateway with a call budget, latency and tokens ----------

const stats = {
  calls: 0,
  refused: 0,
  latencies: [] as number[],
  promptTokens: 0,
  completionTokens: 0,
};
const apiKey = process.env.OPENAI_API_KEY ?? '';
if (!apiKey || apiKey === 'unset') throw new Error('OPENAI_API_KEY is not set');
const model = process.env.OPENAI_MODEL ?? 'gpt-4.1-mini';

const meteredFetch: typeof fetch = async (input, init) => {
  if (stats.calls >= maxCalls) {
    stats.refused += 1;
    throw new Error('eval call budget reached');
  }
  stats.calls += 1;
  const t0 = Date.now();
  const res = await fetch(input, init);
  stats.latencies.push(Date.now() - t0);
  try {
    const usage = ((await res.clone().json()) as { usage?: Record<string, number> }).usage;
    stats.promptTokens += usage?.prompt_tokens ?? 0;
    stats.completionTokens += usage?.completion_tokens ?? 0;
  } catch {
    // Usage is best effort.
  }
  return res;
};
const real = openAiModelGateway(apiKey, model, meteredFetch);
const gateway: ModelGateway = {
  ...real,
  name: 'openai',
  model: real.model,
  promptVersion: real.promptVersion,
  extract: (i, s) => real.extract(i, s),
  word:
    process.env.EVAL_WORDING === '1'
      ? (i, s) => real.word(i, s)
      : async () => {
          throw new ModelUnavailable('script');
        },
};

// ---------- Emulator seed (synthetic) ----------

const app = initializeApp(
  { projectId: process.env.GCLOUD_PROJECT ?? 'demo-child-life-eval' },
  'eval',
);
const db: Firestore = getFirestore(app);
const deps = (now: Date): AssistantDeps => ({ db, now, environment: 'test', gateway });
const E = (locale: string, over: Record<string, unknown>) => ({
  contractVersion: 1,
  clientRequestId: randomUUID(),
  locale,
  ...over,
});
const on = (key: keyof typeof defaultFlags) => ({
  ...defaultFlags[key],
  enabled: true,
  scope: 'all',
});
const babyOf = (c: EvalCase) => `test_ev_${c.id.replace(/[^a-z0-9]/gi, '_')}`;
const member = (role: string, relation: string, displayName: string, extra = {}) => ({
  role,
  status: 'active',
  relation,
  relationCustom: null,
  displayName,
  ...extra,
});

async function seedWorld() {
  for (const c of [
    'babies',
    'families',
    'config',
    'publicConfig',
    'users',
    'assistantConversations',
    'assistantTasks',
    'assistantQuotes',
    'assistantExecutions',
    'assistantRequests',
  ]) {
    await db.recursiveDelete(db.collection(c));
  }
  await db.doc('config/flags').set({
    assistant: on('assistant'),
    assistant_live: on('assistant_live'),
    assistant_writes: on('assistant_writes'),
    assistant_care: on('assistant_care'),
    rhythm: on('rhythm'),
  });
  await db.doc('config/entitlements').set({
    ...defaultEntitlementsConfig,
    regions: { advanced: ['VN'] },
    quotas: {
      ...defaultEntitlementsConfig.quotas,
      assistant: { ...defaultEntitlementsConfig.quotas.assistant, free: 100_000 },
    },
  });
  const L = (vi: string, en = vi) => ({ vi, en });
  await db.doc('publicConfig/content_rhythm').set({
    version: 'rc_eval_01',
    publishedAt: new Date().toISOString(),
    activities: [
      {
        id: 'act_eval_sleep',
        version: 1,
        status: 'published',
        title: L('Hoạt động thử'),
        summary: L('Tóm tắt'),
        steps: { vi: ['Bước 1'], en: ['Step 1'] },
        safety: null,
        durationMin: 10,
        ageDays: { from: 0, to: 730 },
        needs: ['sleep'],
        interests: [],
        timeOfDay: 'evening',
        locales: ['vi', 'en'],
        regions: [],
        sources: [],
        review: null,
      },
    ],
    ageCards: [],
    health: {
      signs: [{ id: 'fever_young', label: L('Sốt'), maxAgeDays: 90 }],
      whileWaiting: { vi: [], en: [] },
      disclaimer: L('TEST_ONLY'),
      regions: [],
      sources: [],
      review: null,
    },
  });
  const babies = cases.map(babyOf);
  await db
    .doc(`families/${F}`)
    .set({ ownerUid: MEMBERS.MOM, country: 'VN', timeZone: ZONE, babyIds: babies });
  await db.doc(`families/${F}/spendingCategories/c_hocboi`).set({
    name: 'Học bơi',
    icon: 'star',
    tint: 'mint',
    order: 10,
    hidden: false,
    builtIn: false,
    updatedAt: Timestamp.now(),
    updatedBy: MEMBERS.MOM,
  });
  for (const b of babies) {
    await db
      .doc(`babies/${b}`)
      .set({ familyId: F, timeZone: { mode: 'auto', zone: ZONE }, state: 'active' });
    await db.doc(`babies/${b}/restricted/profile`).set({ dateOfBirth: '2026-03-10' });
    await db
      .doc(`babies/${b}/members/${MEMBERS.MOM}`)
      .set(member('coParent', 'mother', 'Mai', { isOwner: true }));
    await db.doc(`babies/${b}/members/${MEMBERS.DAD}`).set(member('coParent', 'father', 'Huy'));
    await db
      .doc(`babies/${b}/members/${MEMBERS.NANNY}`)
      .set(member('caregiver', 'nanny', 'Cô Hoa'));
  }
  for (const uid of Object.values(MEMBERS)) {
    await setAssistantConsent(
      deps(new Date()),
      uid,
      E('vi', { consent: { version: assistantConsentVersion } }),
    );
  }
}

async function seedRecord(
  babyId: string,
  id: string,
  type: string,
  at: string,
  data: Record<string, unknown>,
  end: string | null = null,
) {
  await db.doc(`babies/${babyId}/records/${id}`).set({
    id,
    babyId,
    type,
    occurredAt: Timestamp.fromDate(localAt(at)),
    endedAt: end ? Timestamp.fromDate(localAt(end)) : null,
    data,
    createdBy: MEMBERS.DAD,
    author: { name: 'Huy', relation: 'father', relationCustom: null },
    createdAt: Timestamp.now(),
    clientCreatedAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
    updatedBy: MEMBERS.DAD,
    deleted: false,
    deletedAt: null,
    deletedBy: null,
    source: 'app',
  });
}

async function seedCase(c: EvalCase) {
  const b = babyOf(c);
  if (c.seed === 'day') {
    await seedRecord(b, `r_${'1'.repeat(32)}`, 'bottle', 'D0 07:00', {
      amountMl: 120,
      milk: 'formula',
    });
    await seedRecord(b, `r_${'2'.repeat(32)}`, 'bottle', 'D0 11:00', {
      amountMl: 150,
      milk: 'formula',
    });
    await seedRecord(b, `r_${'3'.repeat(32)}`, 'breast', 'D0 09:00', {
      side: 'left',
      durationMin: 15,
    });
    await seedRecord(b, `r_${'4'.repeat(32)}`, 'sleep', 'D0 12:00', {}, 'D0 13:30');
    await seedRecord(b, `r_${'5'.repeat(32)}`, 'sleep', 'D-1 13:00', {}, 'D-1 14:30');
    await seedRecord(b, `r_${'6'.repeat(32)}`, 'sleep', 'D-1 21:00', {}, 'D0 05:30');
  } else if (c.seed === 'sleepTimer' || c.seed === 'breastTimer') {
    // Lumi 2026-10-16: a timer the app started 40 / 15 minutes before the anchor (Ba).
    const type = c.seed === 'sleepTimer' ? 'sleep' : 'breast';
    const at = new Date(localAt(c.anchor).getTime() - (type === 'sleep' ? 40 : 15) * 60_000);
    await db.doc(`babies/${b}/timers/${type}`).set({
      type,
      babyId: b,
      sessionId: (type === 'sleep' ? 'e' : 'f').repeat(32),
      startedAt: Timestamp.fromDate(at),
      startedBy: MEMBERS.DAD,
      author: { name: 'Huy', relation: 'father', relationCustom: null },
      sides:
        type === 'sleep'
          ? null
          : {
              left: { accumulatedMs: 0, runningSince: Timestamp.fromDate(at) },
              right: { accumulatedMs: 0, runningSince: null },
            },
      paused: false,
      pausedSides: [],
      updatedAt: Timestamp.fromDate(at),
      updatedBy: MEMBERS.DAD,
    });
  } else if (c.seed === 'bottle0800') {
    await seedRecord(b, `r_${'7'.repeat(32)}`, 'bottle', 'D0 08:00', {
      amountMl: 120,
      milk: 'formula',
    });
  }
}

// ---------- Run one message ----------

interface StepOut {
  taskId: string;
  snap: AssistantTaskSnapshot;
  asked: string[];
  error: string | null;
}

async function runMessage(c: EvalCase, uid: string, text: string, at: Date): Promise<StepOut> {
  const babyId = babyOf(c);
  const scope = { type: 'child' as const, babyId };
  const conversationId = `cv_${babyId}`;
  const asked: string[] = [];
  let clock = at;
  const tick = () => (clock = new Date(clock.getTime() + 5_000));
  try {
    const q = await quoteTask(
      deps(clock),
      uid,
      E(c.locale, {
        conversationId,
        scope,
        modality: 'text',
        attachmentCount: 0,
        intentHint: null,
      }),
    );
    const r = await startTask(
      deps(clock),
      uid,
      E(c.locale, { conversationId, scope, quoteId: q.data.quoteId, text, attachmentIds: [] }),
    );
    const taskId = r.taskId!;
    const work = () =>
      runAssistantTask(
        { db, now: tick(), environment: 'test', gateway, timeoutMs: 60_000 },
        taskId,
      );
    if (r.data.task.state === 'queued') await work();
    let snap = (
      await getAssistantTask(deps(clock), uid, E(c.locale, { taskId, afterSequence: null }))
    ).data;
    for (let round = 0; round < 4 && snap.task.state === 'awaiting_clarification'; round++) {
      const cl = snap.task.clarification!;
      asked.push(cl.field);
      const key = Object.keys(c.answers ?? {}).find(
        (k) => cl.field === k || cl.field.startsWith(`${k}.`),
      );
      if (!key) break;
      const spec = c.answers![key]!;
      let choiceId: string | null = null;
      let answerText: string | null = null;
      if (spec.member) choiceId = MEMBERS[spec.member as keyof typeof MEMBERS];
      else if (typeof spec.choice === 'number') choiceId = cl.choices[spec.choice]?.id ?? null;
      else if (typeof spec.choice === 'string') choiceId = spec.choice;
      else answerText = spec.text ?? null;
      if (choiceId !== null && !cl.choices.some((x) => x.id === choiceId)) break;
      await submitClarification(
        deps(tick()),
        uid,
        E(c.locale, {
          taskId,
          expectedVersion: snap.task.version,
          clarificationId: cl.id,
          choiceId,
          text: answerText,
        }),
      );
      await work();
      snap = (
        await getAssistantTask(deps(clock), uid, E(c.locale, { taskId, afterSequence: null }))
      ).data;
    }
    return { taskId, snap, asked, error: null };
  } catch (e) {
    const reason =
      (e as { reason?: string }).reason ?? (e instanceof Error ? e.message.slice(0, 60) : 'error');
    return { taskId: '', snap: null as unknown as AssistantTaskSnapshot, asked, error: reason };
  }
}

// ---------- Scoring ----------

type FieldStatus = 'correct' | 'caught' | 'wrong';

function outcomeOf(s: AssistantTaskSnapshot): string {
  const parts: AssistantPart[] = s.messages
    .filter((m) => m.role === 'assistant')
    .flatMap((m) => m.parts);
  const codes = parts.flatMap((p) => (p.type === 'text' && p.code ? [p.code as string] : []));
  if (parts.some((p) => p.type === 'health_support')) return 'health';
  if (codes.includes('SMALL_TALK')) return 'small_talk';
  if (codes.includes('SAME_AS_PENDING')) return 'same';
  if (codes.includes('HELP')) return 'help';
  if (s.task.state === 'awaiting_clarification') return 'awaiting';
  if (s.drafts.length > 0) return 'drafts';
  if (s.task.state === 'failed' && s.task.errorCode === 'WRITE_DENIED') return 'denied';
  if (codes.includes('CARE_NO_APPROVED_CONTENT') || codes.includes('RECIPES_NONE_APPROVED'))
    return 'fallback';
  if (
    s.task.state === 'ready' &&
    parts.some((p) => p.type === 'source_summary' || p.type === 'text')
  ) {
    return s.task.usage === 'committed' ? 'answer' : 'fallback';
  }
  return `${s.task.state}:${s.task.errorCode ?? '-'}`;
}

function scoreDraft(e: ExpectDraft, d: AssistantTaskSnapshot['drafts'][number]) {
  const p = d.payload as Record<string, unknown>;
  const flagged = new Set([...d.uncertainFields, ...d.missingFields]);
  const out: Record<string, { status: FieldStatus; expected: unknown; actual: unknown }> = {};
  const check = (
    name: string,
    ok: boolean,
    expected: unknown,
    actual: unknown,
    flagField: string,
  ) => {
    out[name] = {
      status: ok ? 'correct' : flagged.has(flagField) ? 'caught' : 'wrong',
      expected,
      actual,
    };
  };
  const near = (spec: string, iso: unknown, tol = 0) =>
    typeof iso === 'string' && Math.abs(Date.parse(iso) - localAt(spec).getTime()) <= tol * 60_000;
  const tol = e.tolMin ?? 0;
  if (e.at !== undefined)
    check(
      'at',
      near(e.at, p.occurredAt, tol),
      e.at,
      describeLocal(p.occurredAt as string),
      'occurredAt',
    );
  if (e.start !== undefined)
    check(
      'start',
      near(e.start, p.startedAt, tol),
      e.start,
      describeLocal(p.startedAt as string),
      'startedAt',
    );
  if (e.end !== undefined)
    check('end', near(e.end, p.endedAt, tol), e.end, describeLocal(p.endedAt as string), 'endedAt');
  if (e.ml !== undefined)
    check(
      'ml',
      typeof p.amountMl === 'number' && Math.abs(p.amountMl - e.ml) <= (e.tolMl ?? 0),
      e.ml,
      p.amountMl,
      'amountMl',
    );
  if (e.min !== undefined) {
    const actual =
      typeof p.durationMin === 'number'
        ? p.durationMin
        : typeof p.startedAt === 'string' && typeof p.endedAt === 'string'
          ? Math.round((Date.parse(p.endedAt) - Date.parse(p.startedAt)) / 60_000)
          : null;
    check('min', actual === e.min, e.min, actual, 'durationMin');
  }
  if (e.side !== undefined) check('side', p.side === e.side, e.side, p.side, 'side');
  if (e.total !== undefined)
    check('total', p.totalMinor === e.total, e.total, p.totalMinor, 'totalMinor');
  if (e.currency !== undefined)
    check('currency', p.currency === e.currency, e.currency, p.currency, 'currency');
  if (e.category !== undefined)
    check(
      'category',
      e.category.includes(p.categoryId as string),
      e.category,
      p.categoryId,
      'categoryId',
    );
  if (e.date !== undefined)
    check('date', p.date === dateSpec(e.date), dateSpec(e.date), p.date, 'date');
  if (e.merchant !== undefined) {
    const m = typeof p.merchant === 'string' ? fold(p.merchant) : '';
    check('merchant', m.includes(fold(e.merchant)), e.merchant, p.merchant, 'merchant');
  }
  if (e.title !== undefined) {
    const t = typeof p.title === 'string' ? fold(p.title) : '';
    check(
      'title',
      e.title.some((w) => t.includes(fold(w))),
      e.title,
      p.title,
      'title',
    );
  }
  if (e.time !== undefined) check('time', (p.time ?? null) === e.time, e.time, p.time, 'time');
  if (e.assignee !== undefined) {
    const want = MEMBERS[e.assignee as keyof typeof MEMBERS];
    check('assignee', p.assigneeUid === want, e.assignee, p.assigneeUid, 'assigneeUid');
  }
  if (e.observation !== undefined)
    check(
      'observation',
      p.observation === e.observation,
      e.observation,
      p.observation,
      'observation',
    );
  if (e.warning !== undefined)
    check('warning', d.warnings.includes(e.warning as 'overlap'), e.warning, d.warnings, '-');
  // Lumi 2026-10-16: timer drafts and review lists.
  if (e.timer !== undefined) check('timer', p.timer === e.timer, e.timer, p.timer, '-');
  if (e.action !== undefined) check('action', p.action === e.action, e.action, p.action, '-');
  if (e.tAt !== undefined)
    check('tAt', near(e.tAt, p.at, tol), e.tAt, describeLocal(p.at as string), 'at');
  if (e.missing !== undefined) {
    const got = [...d.missingFields].sort().join(',');
    out.missing = {
      status: got === [...e.missing].sort().join(',') ? 'correct' : 'wrong',
      expected: e.missing,
      actual: d.missingFields,
    };
  }
  if (e.noReview) {
    out.noReview = {
      status: flagged.size === 0 && d.state === 'draft' ? 'correct' : 'wrong',
      expected: 'complete',
      actual: [...flagged],
    };
  }
  if (e.review !== undefined) {
    for (const f of e.review) {
      out[`review:${f}`] = {
        status: flagged.has(f) ? 'correct' : 'wrong',
        expected: 'flagged',
        actual: [...flagged],
      };
    }
  }
  return out;
}

interface CaseResult {
  id: string;
  group: string;
  locale: string;
  error: string | null;
  outcome: string;
  outcomeOk: boolean;
  intentsOk: boolean;
  kinds: string[];
  fields: Record<string, { status: FieldStatus; expected: unknown; actual: unknown }>[];
  asked: string[];
  asksOk: boolean;
  overAsked: boolean;
  visibility: string | null;
  privacyOk: boolean;
  leakChecked: boolean;
  credits: number | null;
  creditsOk: boolean;
  replacedOk: boolean | null;
  calls: number;
  ms: number;
}

async function leaksToShared(babyId: string, taskId: string, author: string): Promise<boolean> {
  const shared = await db
    .collection(`assistantConversations/cv_${babyId}/messages`)
    .where('taskId', '==', taskId)
    .get();
  if (!shared.empty) return true;
  // Another member of the shared thread (never the author) must not read the task.
  const other = author === MEMBERS.NANNY ? MEMBERS.DAD : MEMBERS.NANNY;
  try {
    await getAssistantTask(deps(new Date()), other, E('vi', { taskId, afterSequence: null }));
    return true;
  } catch {
    return false;
  }
}

async function runCase(c: EvalCase): Promise<CaseResult> {
  const callsBefore = stats.calls;
  const refusedBefore = stats.refused;
  const t0 = Date.now();
  await seedCase(c);
  const uid = MEMBERS[c.as ?? 'MOM'];
  const anchor = localAt(c.anchor);
  const before: StepOut[] = [];
  for (const [i, text] of (c.before ?? []).entries()) {
    before.push(await runMessage(c, uid, text, new Date(anchor.getTime() - (3 - i) * 60_000)));
  }
  const step = await runMessage(c, uid, c.text, anchor);
  if (stats.refused > refusedBefore) step.error = 'eval call budget reached';
  const ex = c.expect;
  const base: CaseResult = {
    id: c.id,
    group: c.group,
    locale: c.locale,
    error: step.error,
    outcome: 'error',
    outcomeOk: false,
    intentsOk: false,
    kinds: [],
    fields: [],
    asked: step.asked,
    asksOk: false,
    overAsked: false,
    visibility: null,
    privacyOk: false,
    leakChecked: false,
    credits: null,
    creditsOk: false,
    replacedOk: null,
    calls: stats.calls - callsBefore,
    ms: Date.now() - t0,
  };
  if (step.error) return base;
  const s = step.snap;
  const outcome = outcomeOf(s);
  const live = s.drafts.filter((d) => d.state !== 'discarded');
  const kinds = live.map((d) => d.payload.kind);
  const want = (ex.drafts ?? []).map((d) => d.kind);
  const sorted = (a: string[]) => [...a].sort().join(',');
  const fields: CaseResult['fields'] = [];
  const pool = [...live];
  for (const e of ex.drafts ?? []) {
    const i = pool.findIndex((d) => d.payload.kind === e.kind);
    if (i < 0) continue;
    fields.push(scoreDraft(e, pool[i]!));
    pool.splice(i, 1);
  }
  const expectedAsks = ex.asks ?? [];
  const askedNorm = step.asked.map((f) => f.replace(/\.\d+$/, ''));
  const credits = s.task.usage === 'committed' ? s.task.credits : 0;
  let privacyOk = true;
  let leakChecked = false;
  if (ex.visibility) privacyOk = s.task.visibility === ex.visibility;
  if (ex.visibility === 'private' || kinds.includes('expense')) {
    leakChecked = true;
    if (await leaksToShared(babyOf(c), step.taskId, uid)) privacyOk = false;
  }
  let replacedOk: boolean | null = null;
  if (ex.replaced !== undefined && before[0]?.taskId) {
    const prev = (
      await getAssistantTask(
        deps(new Date()),
        uid,
        E('vi', { taskId: before[0].taskId, afterSequence: null }),
      )
    ).data;
    replacedOk = prev.drafts.filter((d) => d.state === 'discarded').length === ex.replaced;
  }
  const answerCodes = s.messages
    .filter((m) => m.role === 'assistant')
    .flatMap((m) => m.parts)
    .flatMap((p) => (p.type === 'text' && p.code ? [p.code as string] : []));
  const mainCalls = stats.calls - callsBefore - before.length; // ≈ the main message's calls
  const outcomeOk =
    outcome === ex.outcome &&
    (ex.calls === undefined || Math.max(0, mainCalls) === ex.calls) &&
    (ex.codes ?? []).every((code) => answerCodes.includes(code));
  return {
    ...base,
    outcome,
    outcomeOk,
    intentsOk: sorted(kinds) === sorted(want),
    kinds,
    fields,
    asksOk: expectedAsks.every((f) => askedNorm.includes(f)),
    overAsked: askedNorm.some((f) => !expectedAsks.includes(f)),
    visibility: s.task.visibility ?? null,
    privacyOk,
    leakChecked,
    credits,
    creditsOk: ex.credits === undefined || credits === ex.credits,
    replacedOk,
  };
}

// ---------- Main ----------

const pct = (n: number, d: number) =>
  d === 0 ? 'n/a' : `${((100 * n) / d).toFixed(1)}% (${n}/${d})`;

async function main() {
  mkdirSync(outDir, { recursive: true });
  await seedWorld();
  const results: CaseResult[] = [];
  for (const c of cases) {
    // Past the budget the metered fetch refuses (that case is an error); free cases still run.
    const r = await runCase(c);
    results.push(r);
    const f = r.fields.flatMap((x) => Object.values(x));
    console.log(
      [
        r.id.padEnd(8),
        r.outcome.padEnd(22),
        r.outcomeOk ? 'OUT✓' : 'OUT✗',
        r.intentsOk ? 'INT✓' : 'INT✗',
        `F ${f.filter((x) => x.status === 'correct').length}/${f.length}`,
        r.asksOk ? 'ASK✓' : 'ASK✗',
        r.overAsked ? 'OVER' : '    ',
        r.privacyOk ? 'PRIV✓' : 'PRIV✗',
        r.creditsOk ? 'CR✓' : 'CR✗',
        r.replacedOk === null ? '' : r.replacedOk ? 'REPL✓' : 'REPL✗',
        `calls ${r.calls}`,
        r.error ? `ERR ${r.error}` : '',
      ].join(' '),
    );
  }
  const scored = results.filter((r) => r.error !== 'eval call budget reached');
  const allFields = scored.flatMap((r) => r.fields.flatMap((x) => Object.values(x)));
  const withAsks = scored.filter(
    (r) => (cases.find((c) => c.id === r.id)!.expect.asks ?? []).length > 0,
  );
  const clear = scored.filter(
    (r) => (cases.find((c) => c.id === r.id)!.expect.asks ?? []).length === 0,
  );
  const groups = [...new Set(scored.map((r) => r.group))];
  const lat = [...stats.latencies].sort((a, b) => a - b);
  const q = (p: number) =>
    lat.length ? lat[Math.min(lat.length - 1, Math.floor(p * lat.length))] : 0;
  const summary = {
    dataset: dataset.version,
    model,
    cases: scored.length,
    outcome: pct(scored.filter((r) => r.outcomeOk).length, scored.length),
    intents: pct(scored.filter((r) => r.intentsOk).length, scored.length),
    fieldsCorrect: pct(allFields.filter((f) => f.status === 'correct').length, allFields.length),
    fieldsCaught: pct(allFields.filter((f) => f.status === 'caught').length, allFields.length),
    fieldsSilentWrong: pct(allFields.filter((f) => f.status === 'wrong').length, allFields.length),
    clarifyRecall: pct(withAsks.filter((r) => r.asksOk).length, withAsks.length),
    overAsk: pct(clear.filter((r) => r.overAsked).length, clear.length),
    privacy: pct(scored.filter((r) => r.privacyOk).length, scored.length),
    leakChecks: scored.filter((r) => r.leakChecked).length,
    credits: pct(scored.filter((r) => r.creditsOk).length, scored.length),
    health: pct(
      scored.filter((r) => r.group === 'health' && r.outcomeOk).length,
      scored.filter((r) => r.group === 'health').length,
    ),
    allPass: pct(
      scored.filter(
        (r) =>
          r.outcomeOk &&
          r.intentsOk &&
          r.asksOk &&
          r.privacyOk &&
          r.creditsOk &&
          r.replacedOk !== false &&
          r.fields.every((x) => Object.values(x).every((f) => f.status === 'correct')),
      ).length,
      scored.length,
    ),
    byGroup: Object.fromEntries(
      groups.map((g) => {
        const rs = scored.filter((r) => r.group === g);
        return [
          g,
          `${rs.filter((r) => r.outcomeOk && r.intentsOk && r.fields.every((x) => Object.values(x).every((f) => f.status === 'correct'))).length}/${rs.length}`,
        ];
      }),
    ),
    apiCalls: stats.calls,
    latencyMs: { p50: q(0.5), p95: q(0.95) },
    tokens: { prompt: stats.promptTokens, completion: stats.completionTokens },
    // gpt-4.1-mini list price (USD per 1M tokens): input 0.40, output 1.60.
    costUsd: Number(((stats.promptTokens * 0.4 + stats.completionTokens * 1.6) / 1e6).toFixed(4)),
  };
  writeFileSync(resolve(outDir, 'results.json'), JSON.stringify({ summary, results }, null, 2));
  console.log(JSON.stringify(summary, null, 2));
}

await main();
process.exit(0);
