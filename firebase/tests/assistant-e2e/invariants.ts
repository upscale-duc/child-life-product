/**
 * Invariants checked on EVERY snapshot after every turn (docs/assistant/test-plan.md §4): no dead
 * end, fields that exist and can be fixed in the app, credits per policy, spending never in the
 * shared thread, no future completed log, saves that pass the Rules shape and show in the app's
 * lists, no duplicates on retry. Each returns violations; nothing here throws.
 */
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  careDataSchemas,
  draftProblems,
  expenseSchema,
  looksLikeSpending,
  reminderSchema,
  type AssistantTaskSnapshot,
} from '@child-life/contracts';
import { doc, serverTimestamp, setDoc, Timestamp as ClientTimestamp } from 'firebase/firestore';
import { Timestamp } from 'firebase-admin/firestore';
import {
  B,
  controls,
  db,
  F,
  outcomeOf,
  noticeCodes,
  ROOT,
  SHARED,
  snapshotOf,
  UID,
  reasonOf,
  type CaseRun,
  type ConfirmLog,
} from './harness.js';
import type { Case, Severity, Violation } from './types.js';

const SKEW_MS = 2 * 60_000;
const v = (code: string, severity: Severity, at: string, detail: string): Violation => ({
  code,
  severity,
  at,
  detail,
});

/** Care types the app logs (care_models.dart `CareType`) and words that name them. */
const appCareWords: { type: string; re: RegExp }[] = [
  {
    type: 'diaper',
    re: /(thay|thay tã|tã|bỉm|bim|ta uot|tã ướt|diaper|ị|đi ị|đi tè|tè|poop|pee)/iu,
  },
  { type: 'pump', re: /(hút|hut sua|hut \d|vắt sữa|vat sua|pump)/iu },
  {
    type: 'growth',
    re: /(cân nặng|can nang|nặng \d|nang \d|\d+[,.]?\d*\s?kg|chiều dài|chieu dai|\d+\s?cm|weigh|length)/iu,
  },
];

/** Every check on one snapshot of the case. */
export function checkSnapshot(
  c: Case,
  snap: AssistantTaskSnapshot,
  at: string,
  now: Date,
  userText: string | null,
): Violation[] {
  const out: Violation[] = [];
  const t = snap.task;
  const outcome = outcomeOf(snap);
  // ---- Drafts: flagged fields exist, are named right and can be fixed in the app ----
  const pending = snap.drafts.filter((d) => d.state === 'draft' || d.state === 'needs_review');
  let forward = false;
  for (const [i, d] of snap.drafts.entries()) {
    if (!(d.state === 'draft' || d.state === 'needs_review')) continue;
    const kind = d.payload.kind;
    const map = controls.kinds[kind] ?? { editor: false, fields: {} };
    const keys = new Set(Object.keys(d.payload));
    const p = d.payload as Record<string, unknown>;
    const flagged = [...new Set([...d.missingFields, ...d.uncertainFields])];
    const problems = [...new Set([...d.problems, ...draftProblems(d.payload, now)])];
    const where = `${at} · draft ${i} (${kind})`;
    for (const f of flagged) {
      if (!keys.has(f)) {
        out.push(v('NR_FIELD_UNKNOWN', 'P0', where, `flagged "${f}" is not a field of ${kind}`));
      }
      if (!map.fields[f]) {
        out.push(
          v(
            'NR_NO_CONTROL',
            map.editor ? 'P1' : 'P0',
            where,
            map.editor
              ? `"${f}" flagged but the ${kind} editor has no control for it (cleared only by saving the editor unchanged)`
              : `"${f}" flagged on ${kind}, which has no editor in the app: the draft can never be saved (dead end)`,
          ),
        );
      }
    }
    for (const f of d.missingFields) {
      if (keys.has(f) && p[f] !== null && p[f] !== undefined) {
        out.push(
          v(
            'NR_MISSING_BUT_SET',
            map.editor ? 'P1' : 'P0',
            where,
            `missingFields names "${f}" but the draft has a value for it (${JSON.stringify(p[f]).slice(0, 40)})`,
          ),
        );
      }
    }
    if (d.state === 'needs_review' && flagged.length === 0 && problems.length === 0) {
      out.push(
        v(
          'NR_NOTHING_NAMED',
          'P1',
          where,
          'needs_review with no flagged field and no problem: nothing tells the person what to fix',
        ),
      );
    }
    const saveable = d.state === 'draft' && flagged.length === 0 && problems.length === 0;
    // Fixable in the app: every flagged field has its own control (inline fix or editor field),
    // or the card opens an editor (whose save confirms what it shows).
    const fixable =
      flagged.every((f) => map.fields[f]) || (map.editor && flagged.every((f) => keys.has(f)));
    if (saveable || fixable) forward = true;
    // ---- No completed log in the future (unflagged) ----
    if (saveable) {
      for (const key of ['occurredAt', 'startedAt', 'endedAt']) {
        const val = p[key];
        if (typeof val === 'string' && Date.parse(val) > now.getTime() + SKEW_MS) {
          out.push(
            v(
              'FUTURE_LOG',
              'P0',
              where,
              `${key} is ${Math.round((Date.parse(val) - now.getTime()) / 60_000)} min in the future and nothing flags it`,
            ),
          );
        }
      }
    }
  }
  // ---- A forward action or a final answer ----
  if (t.state === 'queued' || t.state === 'processing' || t.state === 'received') {
    out.push(v('DEAD_END', 'P0', at, `task stuck in ${t.state} after the worker ran`));
  } else if (t.state === 'awaiting_clarification') {
    const cl = t.clarification;
    if (!cl || (cl.choices.length === 0 && !cl.allowText)) {
      out.push(v('DEAD_END', 'P0', at, 'a question with no choice and no free answer'));
    } else {
      for (const ch of cl.choices) {
        const ago = /^ago_(\d+)$/.exec(ch.id);
        const atChip = /^at_(\d{4}-\d{2}-\d{2})_(\d{2}):(\d{2})$/.exec(ch.id);
        if (ago && Number(ago[1]) < 0) out.push(v('CHIP_FUTURE', 'P1', at, `chip ${ch.id}`));
        if (atChip) {
          const inst = Date.parse(`${atChip[1]}T${atChip[2]}:${atChip[3]}:00+07:00`);
          if (inst > Date.parse(t.anchorInstant) + SKEW_MS) {
            out.push(v('CHIP_FUTURE', 'P1', at, `chip ${ch.id} is after the send time`));
          }
        }
        if (!ch.label.vi.trim() || !ch.label.en.trim()) {
          out.push(v('CHIP_EMPTY', 'P2', at, `chip ${ch.id} has an empty label`));
        }
      }
    }
  } else if (t.state === 'ready') {
    const parts = snap.messages.filter((m) => m.role === 'assistant').flatMap((m) => m.parts);
    if (pending.length > 0 && !forward) {
      out.push(
        v('DEAD_END', 'P0', at, 'every pending draft is blocked and none can be fixed in the app'),
      );
    }
    if (snap.drafts.length === 0 && parts.length === 0) {
      out.push(v('DEAD_END', 'P0', at, 'ready with nothing to show'));
    }
  } else if (t.state === 'failed') {
    const parts = snap.messages.filter((m) => m.role === 'assistant').flatMap((m) => m.parts);
    if (!t.errorCode) out.push(v('DEAD_END', 'P0', at, 'failed without an error code'));
    if (
      parts.length === 0 &&
      !['AI_UNAVAILABLE', 'QUOTE_EXPIRED', 'CONSENT_REQUIRED'].includes(t.errorCode ?? '')
    ) {
      out.push(
        v(
          'FAILED_SILENT',
          'P2',
          at,
          `failed (${t.errorCode}) with no explanation part in the thread`,
        ),
      );
    }
  }
  // ---- "No place to save" for a care type the app has ----
  const hit =
    userText && !looksLikeSpending(userText)
      ? appCareWords.find((w) => w.re.test(userText))
      : undefined;
  if (hit && t.state === 'failed' && t.errorCode === 'MODULE_UNAVAILABLE') {
    out.push(
      v(
        'FALSE_UNAVAILABLE',
        'P0',
        at,
        `MODULE_UNAVAILABLE for a ${hit.type} message: the app shows "Chưa có nơi lưu việc này / App chưa có module" although it logs ${hit.type}; nothing to save or open in chat`,
      ),
    );
  } else if (
    hit &&
    !snap.drafts.some((d) => d.payload.kind === hit.type || d.payload.kind === 'timer')
  ) {
    const dropped = snap.messages.some((m) =>
      m.parts.some(
        (p) =>
          p.type === 'text' &&
          /chưa ghi được qua trò chuyện|chưa có nơi lưu|not .*via chat|no place to save/i.test(
            p.text,
          ),
      ),
    );
    if (dropped && snap.drafts.length > 0) {
      out.push(
        v(
          'DROPPED_ITEM',
          'P1',
          at,
          `the ${hit.type} part of the message got no draft; the notice does not say which item or open ${hit.type}`,
        ),
      );
    }
  }
  // ---- Credits per outcome ----
  const usage = t.usage;
  const expectUsage =
    t.state === 'awaiting_clarification'
      ? ['reserved']
      : t.state === 'blocked'
        ? ['none', 'released']
        : outcome === 'drafts' || outcome === 'answer' || outcome === 'care'
          ? ['committed']
          : t.state === 'ready' || t.state === 'failed' || t.state === 'canceled'
            ? ['none', 'released']
            : null;
  if (expectUsage && !expectUsage.includes(usage)) {
    out.push(
      v(
        'CREDITS_POLICY',
        'P1',
        at,
        `outcome ${outcome} (${t.state}) with usage ${usage}; policy says ${expectUsage.join('/')}`,
      ),
    );
  }
  if (
    (outcome === 'health' || outcome === 'small_talk' || outcome === 'help') &&
    usage === 'committed'
  ) {
    out.push(v('CREDITS_POLICY', 'P1', at, `${outcome} charged a credit`));
  }
  // ---- Privacy: money stays private ----
  const money =
    snap.drafts.some((d) => d.payload.kind === 'expense') ||
    (userText !== null && looksLikeSpending(userText)) ||
    noticeCodes(snap).includes('SPENDING_PRIVATE');
  if (money && t.visibility === 'shared') {
    out.push(v('PRIVACY_VISIBILITY', 'P0', at, 'a spending task is visible to the shared thread'));
  }
  if (money && t.conversationId === SHARED) {
    out.push(v('PRIVACY_VISIBILITY', 'P0', at, 'a spending task lives in the shared conversation'));
  }
  return out;
}

/** The shared thread must hold no message of a private task and no money words. */
export async function checkSharedThread(run: CaseRun, at: string): Promise<Violation[]> {
  const out: Violation[] = [];
  const msgs = await db.collection(`assistantConversations/${SHARED}/messages`).get();
  const privateTasks = new Set<string>();
  for (const s of run.steps)
    if (s.snapshot.task.visibility === 'private') privateTasks.add(s.taskId);
  for (const m of msgs.docs) {
    const taskId = m.get('taskId') as string | null;
    if (taskId && privateTasks.has(taskId)) {
      out.push(
        v(
          'PRIVACY_SHARED_LEAK',
          'P0',
          at,
          `a message of private task ${taskId.slice(0, 10)}… is in the shared thread`,
        ),
      );
    }
    const parts =
      (m.get('parts') as { type: string; text?: string; draftId?: string }[] | undefined) ?? [];
    for (const p of parts) {
      if (p.type === 'text' && m.get('role') === 'user' && p.text && looksLikeSpending(p.text)) {
        out.push(v('PRIVACY_SHARED_LEAK', 'P0', at, 'money words in a shared-thread user message'));
      }
    }
  }
  // Another co-parent must not read a private task (a spending one in particular).
  for (const taskId of privateTasks) {
    const owner = run.steps.find((s) => s.taskId === taskId)!.uid;
    for (const other of [UID.DAD, UID.NANNY, UID.MOM].filter((u) => u !== owner)) {
      try {
        await snapshotOf(taskId, other, run.clock);
        out.push(
          v(
            'PRIVACY_SHARED_LEAK',
            'P0',
            at,
            `another member (${other}) can read private task ${taskId.slice(0, 10)}…`,
          ),
        );
      } catch (e) {
        if (reasonOf(e) !== 'NOT_MEMBER') {
          out.push(
            v(
              'PRIVACY_SHARED_LEAK',
              'P1',
              at,
              `reading another member's private task answered ${reasonOf(e)} (expected NOT_MEMBER)`,
            ),
          );
        }
      }
    }
  }
  return out;
}

// ---------- Saves: Rules shape, contracts shape, the app's lists, no duplicates ----------

let rulesEnv: RulesTestEnvironment | null = null;
export async function rulesEnvironment(host: string, port: number) {
  rulesEnv ??= await initializeTestEnvironment({
    projectId: 'demo-child-life-e2e-rules',
    firestore: {
      host,
      port,
      rules: readFileSync(resolve(ROOT, 'firebase/firestore.rules'), 'utf8'),
    },
  });
  return rulesEnv;
}
export async function closeRules() {
  await rulesEnv?.cleanup();
  rulesEnv = null;
}

const toClient = (x: unknown): unknown => {
  if (x instanceof Timestamp) return ClientTimestamp.fromMillis(x.toMillis());
  if (Array.isArray(x)) return x.map(toClient);
  if (x && typeof x === 'object') {
    return Object.fromEntries(
      Object.entries(x as Record<string, unknown>).map(([k, y]) => [k, toClient(y)]),
    );
  }
  return x;
};

/** Copies what the Rules read (baby, members, family, categories) into the rules project. */
async function mirrorWorld(env: RulesTestEnvironment) {
  await env.clearFirestore();
  const paths: string[] = [`babies/${B}`, `families/${F}`];
  for (const col of [
    `babies/${B}/members`,
    `families/${F}/spendingCategories`,
    `families/${F}/spendingSettings`,
  ]) {
    for (const d of (await db.collection(col).get()).docs) paths.push(d.ref.path);
  }
  const docs = await Promise.all(paths.map((p) => db.doc(p).get()));
  await env.withSecurityRulesDisabled(async (ctx) => {
    const cdb = ctx.firestore();
    for (const d of docs)
      if (d.exists)
        await setDoc(doc(cdb, d.ref.path), toClient(d.data()) as Record<string, unknown>);
  });
}

/** Where a saved item lives and how the app lists it. */
function targetOf(kind: string, recordId: string, payload?: Record<string, unknown>) {
  if (kind === 'timer') {
    return payload?.action === 'start'
      ? { path: `babies/${B}/timers/${String(payload.timer)}`, col: 'timers' }
      : { path: `babies/${B}/records/${recordId}`, col: 'records' };
  }
  if (kind === 'expense') return { path: `babies/${B}/expenses/${recordId}`, col: 'expenses' };
  if (kind === 'reminder') return { path: `babies/${B}/reminders/${recordId}`, col: 'reminders' };
  if (kind === 'observation') return { path: `babies/${B}/checkins/${recordId}`, col: 'checkins' };
  return { path: `babies/${B}/records/${recordId}`, col: 'records' };
}

export async function checkSaves(
  run: CaseRun,
  env: RulesTestEnvironment | null,
): Promise<Violation[]> {
  const out: Violation[] = [];
  if (run.confirms.length === 0) return out;
  let mirrored = false;
  const seen = new Map<string, string>();
  for (const cf of run.confirms) {
    const at = `${cf.turn < 0 ? 'probe' : `turn ${cf.turn + 1}`} · save${cf.retried ? ' (retry)' : ''}`;
    if (cf.error) continue;
    const snap = run.steps.filter((s) => s.taskId === cf.taskId).at(-1)?.snapshot;
    for (const item of cf.items) {
      const d = snap?.drafts.find((x) => x.id === item.draftId);
      const kind = d?.payload.kind ?? 'bottle';
      if (item.status !== 'saved') {
        const expected = [
          'DUPLICATE_SUSPECTED',
          'WRITE_DENIED',
          'DOMAIN_CONFLICT',
          'REVIEW_REQUIRED',
          'DRAFT_SAVED',
          'NOT_MEMBER',
        ];
        if (item.errorCode === 'VALIDATION_FAILED') {
          // The draft looked ready (nothing flagged) but the save refused it: an extra round trip.
          out.push(
            v(
              'SAVE_REFUSED_READY',
              'P1',
              at,
              `${kind} looked ready but the save refused it: ${item.problems.join(',') || 'VALIDATION_FAILED'} (not flagged on the draft)`,
            ),
          );
        } else if (!expected.includes(item.errorCode ?? '')) {
          out.push(
            v(
              'SAVE_FAILED',
              'P0',
              at,
              `${kind} not saved: ${item.status} ${item.errorCode ?? ''} ${item.problems.join(',')}`,
            ),
          );
        }
        continue;
      }
      if (!item.recordId) {
        out.push(v('SAVE_FAILED', 'P0', at, `${kind} saved without a record id`));
        continue;
      }
      if (seen.has(item.draftId) && seen.get(item.draftId) !== item.recordId) {
        out.push(v('SAVE_DUPLICATE', 'P0', at, `${kind} saved twice under different records`));
      }
      const again = seen.has(item.draftId);
      seen.set(item.draftId, item.recordId);
      if (again) continue; // the same record: checked once (a retry must not write another)
      const { path, col } = targetOf(
        kind,
        item.recordId,
        d?.payload as Record<string, unknown> | undefined,
      );
      const snapDoc = await db.doc(path).get();
      if (!snapDoc.exists) {
        out.push(v('SAVE_NOT_LISTED', 'P0', at, `${kind} record ${path} does not exist`));
        continue;
      }
      const data = snapDoc.data()!;
      // The app's list query (care_repository / spending_repository / reminder_repository).
      const listed = await appListed(col, item.recordId, data);
      if (!listed)
        out.push(
          v(
            'SAVE_NOT_LISTED',
            'P0',
            at,
            `${kind} record is not returned by the app's ${col} query`,
          ),
        );
      // Contracts shape.
      const shape = contractShape(kind, data);
      if (shape) out.push(v('SAVE_SHAPE', 'P0', at, `${kind}: ${shape}`));
      // No completed log after the save time.
      for (const key of ['occurredAt', 'endedAt']) {
        const t = data[key];
        if (
          t instanceof Timestamp &&
          t.toMillis() > Date.parse(run.steps.at(-1)?.at ?? new Date().toISOString()) + SKEW_MS &&
          col === 'records'
        ) {
          out.push(v('FUTURE_LOG', 'P0', at, `saved ${kind} has ${key} in the future`));
        }
      }
      // Rules shape: the same document must be one the app itself may create.
      if (env) {
        if (!mirrored) {
          await mirrorWorld(env);
          mirrored = true;
        }
        const r = await rulesShape(env, col, path, data, cf.uid);
        if (r) out.push(v('SAVE_RULES', 'P0', at, `${kind}: ${r}`));
      }
    }
    // No duplicates on retry.
    if (cf.retried) {
      const before = run.confirms[run.confirms.indexOf(cf) - 1];
      if (before && before.recordsAfter !== cf.recordsAfter) {
        out.push(
          v(
            'SAVE_DUPLICATE',
            'P0',
            at,
            `a retried save wrote ${cf.recordsAfter - before.recordsAfter} more record(s)`,
          ),
        );
      }
    }
  }
  return out;
}

async function appListed(col: string, id: string, data: Record<string, unknown>) {
  if (col === 'records') {
    const t = data.occurredAt as Timestamp;
    const from = new Date(t.toMillis() - 36 * 3_600_000);
    const to = new Date(t.toMillis() + 36 * 3_600_000);
    const q = await db
      .collection(`babies/${B}/records`)
      .where('deleted', '==', false)
      .where('occurredAt', '>=', Timestamp.fromDate(from))
      .where('occurredAt', '<', Timestamp.fromDate(to))
      .orderBy('occurredAt', 'desc')
      .get();
    return q.docs.some((d) => d.id === id);
  }
  if (col === 'expenses') {
    const q = await db.collection(`babies/${B}/expenses`).get();
    return q.docs.some((d) => d.id === id && d.get('deleted') !== true);
  }
  if (col === 'reminders') {
    const q = await db.collection(`babies/${B}/reminders`).orderBy('dueAt').get();
    return q.docs.some((d) => d.id === id);
  }
  return true;
}

function contractShape(kind: string, data: Record<string, unknown>): string | null {
  const dates = (o: Record<string, unknown>) =>
    Object.fromEntries(
      Object.entries(o).map(([k, x]) => [k, x instanceof Timestamp ? x.toDate() : x]),
    );
  if (kind === 'expense') {
    const r = expenseSchema.safeParse(dates(data));
    return r.success
      ? null
      : `expenseSchema: ${r.error.issues.map((i) => i.path.join('.')).join(',')}`;
  }
  if (kind === 'reminder') {
    const r = reminderSchema.safeParse(dates(data));
    return r.success
      ? null
      : `reminderSchema: ${r.error.issues.map((i) => i.path.join('.')).join(',')}`;
  }
  // LUMI-01: a care record's data is exactly the care module's (`careDataSchemas`).
  const type = data.type as string | undefined;
  if (type && type in careDataSchemas && 'occurredAt' in data && 'data' in data) {
    const r = careDataSchemas[type as keyof typeof careDataSchemas].strict().safeParse(data.data);
    return r.success
      ? null
      : `careDataSchemas.${type}: ${r.error.issues.map((i) => i.path.join('.') || i.code).join(',')}`;
  }
  return null;
}

async function rulesShape(
  env: RulesTestEnvironment,
  col: string,
  path: string,
  data: Record<string, unknown>,
  uid: string,
): Promise<string | null> {
  const body = toClient(data) as Record<string, unknown>;
  for (const k of ['createdAt', 'updatedAt']) if (k in body) body[k] = serverTimestamp();
  // Only the server writer may say where it came from; the app writes `app` / `manual`.
  if (col === 'records') body.source = 'app';
  if (col === 'expenses') {
    body.source = 'manual';
    body.sourceRef = null;
  }
  if (col === 'checkins') return null;
  if (col === 'reminders') {
    // The Rules compare dueAt with the REAL request.time; the harness runs on a fixed synthetic
    // day, so a reminder is moved by whole days to the same clock time after today (shape only).
    const day = 86_400_000;
    const due = (body.dueAt as ClientTimestamp).toMillis();
    const k = Math.max(0, Math.ceil((Date.now() - due) / day) + 1);
    body.dueAt = ClientTimestamp.fromMillis(due + k * day);
    if (typeof body.dueDate === 'string') {
      body.dueDate = new Date(Date.parse(`${body.dueDate}T00:00:00Z`) + k * day)
        .toISOString()
        .slice(0, 10);
    }
  }
  try {
    await assertSucceeds(setDoc(doc(env.authenticatedContext(uid).firestore(), path), body));
    return null;
  } catch (e) {
    return `the app's create Rules refuse the saved document (${String((e as Error).message).slice(0, 120)})`;
  }
}

// ---------- Expectations ----------

export function checkExpect(
  c: Case,
  run: CaseRun,
  creditsUsed: number,
  savedCount: number,
  mode: 'fake' | 'live',
  describeLocal: (iso: string | null | undefined) => string | null,
  dateSpec: (s: string) => string,
): Violation[] {
  const out: Violation[] = [];
  const e = c.expect;
  const at = 'expect';
  const last = run.lastTaskId
    ? (run.steps.filter((s) => s.taskId === run.lastTaskId).at(-1)?.snapshot ?? null)
    : null;
  // The message's own outcome = the last snapshot before any save of the last task.
  const beforeSave = run.lastTaskId
    ? (run.steps
        .filter(
          (s) =>
            s.taskId === run.lastTaskId && !s.label.includes('save') && !s.label.includes('probe'),
        )
        .at(-1)?.snapshot ?? last)
    : null;
  const refusal = run.refusals.find((r) => r.op !== 'getAssistantTask');
  if (e.error) {
    const got = refusal?.reason ?? last?.task.errorCode ?? run.quoteBlocks[0] ?? null;
    const blockedCode = last?.task.state === 'blocked' ? last.task.errorCode : null;
    if (got !== e.error && blockedCode !== e.error && !run.quoteBlocks.includes(e.error)) {
      out.push(v('EXPECT_ERROR', 'P1', at, `expected ${e.error}, got ${got ?? 'none'}`));
    }
  } else if (refusal && !(e.allow ?? []).includes('refusal')) {
    out.push(v('EXPECT_ERROR', 'P1', at, `unexpected refusal ${refusal.op}: ${refusal.reason}`));
  }
  if (e.outcome && beforeSave) {
    const allowed = Array.isArray(e.outcome) ? e.outcome : [e.outcome];
    const got = outcomeOf(beforeSave);
    if (!allowed.includes(got)) {
      out.push(
        v(
          'EXPECT_OUTCOME',
          'P1',
          at,
          `outcome ${got}, expected ${allowed.join(' | ')}${got.startsWith('failed') || got.startsWith('ready') ? '' : ''}`,
        ),
      );
    }
  }
  if (e.kinds && beforeSave) {
    const got = beforeSave.drafts.filter((d) => d.state !== 'discarded').map((d) => d.payload.kind);
    const options = (Array.isArray(e.kinds[0]) ? e.kinds : [e.kinds]) as string[][];
    if (!options.some((o) => JSON.stringify(got) === JSON.stringify(o))) {
      // A draft of another kind that could be saved as it is = a wrong record (a pump saved as a
      // bottle feed, a diaper change as an observation), not just a missed one.
      const expectedKinds = new Set(options.flat());
      const wrong = beforeSave.drafts.filter(
        (d) =>
          d.state === 'draft' &&
          !expectedKinds.has(d.payload.kind) &&
          d.missingFields.length + d.uncertainFields.length === 0,
      );
      out.push(
        v(
          wrong.length ? 'WRONG_KIND' : 'EXPECT_KINDS',
          wrong.length ? 'P0' : 'P1',
          at,
          `draft kinds [${got.join(',')}], expected ${options.map((o) => `[${o.join(',')}]`).join(' or ')}${wrong.length ? ` — the ${wrong.map((d) => d.payload.kind).join(',')} draft is ready to save: a wrong record one tap away` : ''}`,
        ),
      );
    }
  }
  if (e.ready && beforeSave) {
    for (const [i, d] of beforeSave.drafts.entries()) {
      if (d.state === 'discarded') continue;
      const flagged = [...d.missingFields, ...d.uncertainFields];
      if (d.state !== 'draft' || flagged.length > 0 || d.problems.length > 0) {
        out.push(
          v(
            'EXPECT_READY',
            'P1',
            at,
            `draft ${i} (${d.payload.kind}) is ${d.state}${flagged.length ? ` flagged [${flagged.join(',')}]` : ''}${d.problems.length ? ` problems [${d.problems.join(',')}]` : ''}: an extra review step the message did not need`,
          ),
        );
      }
    }
  }
  if (e.review && beforeSave) {
    const flagged = new Set(
      beforeSave.drafts.flatMap((d) => [
        ...d.missingFields,
        ...d.uncertainFields,
        ...d.problems.map((p) => `problem:${p}`),
      ]),
    );
    for (const f of e.review)
      if (!flagged.has(f))
        out.push(
          v(
            'EXPECT_REVIEW',
            'P1',
            at,
            `"${f}" should be flagged for review (got [${[...flagged].join(',')}])`,
          ),
        );
  }
  if (e.values && beforeSave) {
    const live = beforeSave.drafts.filter((d) => d.state !== 'discarded');
    for (const [key, want] of Object.entries(e.values)) {
      const [idx, field] = key.split('.') as [string, string];
      const d = live[Number(idx)];
      const got = d ? (d.payload as Record<string, unknown>)[field] : undefined;
      let shown: unknown = got;
      let ok: boolean;
      if (typeof want === 'string' && /^D-?\d+ \d\d:\d\d$/.test(want)) {
        shown = describeLocal(got as string | null);
        ok = shown === want;
      } else if (typeof want === 'string' && /^D-?\d+$/.test(want)) {
        ok = got === dateSpec(want);
      } else if (Array.isArray(want)) {
        ok = want.includes(got);
      } else ok = JSON.stringify(got ?? null) === JSON.stringify(want);
      const flagged = d ? [...d.missingFields, ...d.uncertainFields].includes(field) : true;
      if (!ok) {
        out.push(
          v(
            flagged ? 'EXPECT_VALUE' : 'WRONG_VALUE_SILENT',
            flagged ? 'P1' : 'P0',
            at,
            `${key} = ${JSON.stringify(shown ?? null)}, expected ${JSON.stringify(want)}${flagged ? ' (flagged for review)' : ' and NOT flagged: it would be saved wrong'}`,
          ),
        );
      }
    }
  }
  if (e.asks) {
    const got = run.asked;
    const ok = e.asks.length === got.length && e.asks.every((a, i) => got[i]!.startsWith(a));
    if (!ok) {
      const extra = got.length > e.asks.length;
      out.push(
        v(
          'EXPECT_ASKS',
          'P1',
          at,
          `asked [${got.join(',')}], expected [${e.asks.join(',')}]${extra ? ' (an extra question = extra taps)' : ''}`,
        ),
      );
    }
  }
  if (e.visibility && last && last.task.visibility !== e.visibility) {
    out.push(
      v(
        'EXPECT_VISIBILITY',
        e.visibility === 'private' ? 'P0' : 'P1',
        at,
        `visibility ${last.task.visibility}, expected ${e.visibility}`,
      ),
    );
  }
  if (e.credits !== undefined && creditsUsed !== e.credits) {
    out.push(
      v('EXPECT_CREDITS', 'P1', at, `${creditsUsed} credit(s) committed, expected ${e.credits}`),
    );
  }
  if (e.saved !== undefined && savedCount !== e.saved) {
    out.push(v('EXPECT_SAVED', 'P1', at, `${savedCount} record(s) saved, expected ${e.saved}`));
  }
  if (e.codes && last) {
    const codes = new Set(
      run.steps.filter((s) => s.taskId === run.lastTaskId).flatMap((s) => noticeCodes(s.snapshot)),
    );
    for (const code of e.codes)
      if (!codes.has(code)) out.push(v('EXPECT_CODE', 'P2', at, `notice ${code} missing`));
  }
  if (e.notCodes && last) {
    const codes = new Set(
      run.steps.filter((s) => s.taskId === run.lastTaskId).flatMap((s) => noticeCodes(s.snapshot)),
    );
    for (const code of e.notCodes)
      if (codes.has(code)) out.push(v('EXPECT_CODE', 'P1', at, `notice ${code} should not show`));
  }
  if (mode === 'fake' && e.calls !== undefined && run.modelCalls !== e.calls) {
    out.push(v('EXPECT_CALLS', 'P2', at, `${run.modelCalls} model call(s), expected ${e.calls}`));
  }
  return out;
}

export type { ConfirmLog };
