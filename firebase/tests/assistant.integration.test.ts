import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  assistantConsentVersion,
  defaultEntitlementsConfig,
  defaultFlags,
  premiumCapabilities,
  quotaInvariantHolds,
  type Activity,
  type AssistantPart,
  type AssistantResponse,
  type AssistantTaskSnapshot,
  type DraftPayload,
  type RhythmContent,
} from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { FieldValue, getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  cancelTask,
  confirmDrafts,
  deleteAssistantConversation,
  discardDraft,
  getAssistantTask,
  getAssistantUsage,
  listAssistantHistory,
  patchDraft,
  quoteTask,
  setAssistantConsent,
  startTask,
  submitAssistantFeedback,
  submitClarification,
  type AssistantDeps,
} from '../functions/src/assistant.js';
import { setAiConsent } from '../functions/src/ai-summary.js';
import { recordIdForDraft } from '../functions/src/assistant-common.js';
import {
  fakeModelGateway,
  ModelUnavailable,
  type FakeStep,
  type ExtractInput,
  type ModelGateway,
} from '../functions/src/assistant-model.js';
import { localClock } from '../functions/src/assistant-tools.js';
import { runAssistantTask, sweepAssistantTasks } from '../functions/src/assistant-worker.js';
import { purgeAssistantForUser } from '../functions/src/assistant-lifecycle.js';
import { buildCareRecord } from '../functions/src/assistant-writers.js';

// Child Life Assistant, slice A2 server core, against the Firestore emulator with a FAKE model
// gateway (scripted outputs or errors, no heuristics). Ports the simulation pack
// (packages/contracts/test/vectors/assistant-v3: D01–D08, U01–U10, S01–S06, E01–E03, R01, R03)
// to real code, plus the integration matrix M01–M05, M09–M12 and journeys J01, J02, J10.
// Fixed clock 2026-10-15T07:20Z = 14:20 Asia/Ho_Chi_Minh. Synthetic `test_` data only. A pass
// proves the contracts, ledger and writes; it does not prove a real model understands Vietnamese.
const projectId = 'demo-child-life-assistant';
let app: App;
let db: Firestore;

const vectors = resolve(import.meta.dirname, '../../packages/contracts/test/vectors/assistant-v3');
const pack = <T>(name: string): T => JSON.parse(readFileSync(resolve(vectors, name), 'utf8')) as T;
const context = pack<{
  now: string;
  timezone: string;
  household: string;
  actor: string;
  child: string;
}>('context.json');
const outputs = pack<Record<string, Record<string, unknown>>>('provider_outputs.json');
const logs = pack<{ id: string; kind: string; ml?: number; minutes?: number }[]>('logs.json');

const now = new Date(context.now);
const ZONE = context.timezone;
const F = context.household;
const B = context.child;
const NA = 'test_na';
const F2 = 'test_h2';
const B2 = 'test_other';
const MOM = context.actor;
const DAD = 'test_dad';
const NANNY = 'test_nanny';
const AUNT = 'test_aunt';
const GRANDMA = 'test_grandma';
const STRANGER = 'test_mom2';
const SCOPE = { type: 'child' as const, babyId: B };
const WIN = 'assistant_cal_2026-10';
const on = (key: keyof typeof defaultFlags) => ({
  ...defaultFlags[key],
  enabled: true,
  scope: 'all' as const,
});
const offFlag = (key: keyof typeof defaultFlags) => ({ ...defaultFlags[key], enabled: false });

// ---------- Fake model outputs (ported from provider_outputs.json) ----------

const F0 = {
  amountMl: null,
  milk: null,
  time: null,
  dayOffset: null,
  endTime: null,
  endDayOffset: null,
  durationMin: null,
  side: null,
  observation: null,
  when: null,
  note: null,
  title: null,
};
const intent = (
  kind: string,
  fields: Partial<Record<keyof typeof F0, unknown>>,
  evidence: { field: string; text: string }[] = [],
) => ({ kind, fields: { ...F0, ...fields }, evidence, uncertainFields: [], missingFields: [] });
const extraction = (
  intents: unknown[] = [],
  reads: { tool: string; dayOffset: number }[] = [],
  clarification: { field: string } | null = null,
) => ({ intents, reads, clarification });
const hhmm = (iso: string) => localClock(ZONE, new Date(iso));

const TEXT = '8 giờ sáng con bú bình 120 ml, 9 giờ ngủ tới 10 giờ.';
/**
 * Lumi 2026-10-16: the same words again while their draft still waits are answered at once
 * (SAME_AS_PENDING, 0 credits); tests that need a second, separate task send other words.
 */
const AGAIN = 'Ghi thêm: 8 giờ sáng con bú bình 120 ml, 9 giờ ngủ tới 10 giờ.';
const batch = outputs.text_batch!.items as {
  kind: string;
  ml?: number;
  at?: string;
  start?: string;
  end?: string;
}[];
/** text_batch: bottle 120 ml at 08:00, sleep 09:00–10:00 (local). */
const textBatch = () =>
  extraction([
    intent('bottle', { amountMl: batch[0]!.ml, time: hhmm(batch[0]!.at!), dayOffset: 0 }, [
      { field: 'amountMl', text: '120 ml' },
      { field: 'time', text: '8 giờ sáng' },
    ]),
    intent('sleep', { time: hhmm(batch[1]!.start!), endTime: hhmm(batch[1]!.end!), dayOffset: 0 }, [
      { field: 'time', text: '9 giờ' },
      { field: 'endTime', text: '10 giờ' },
    ]),
  ]);
const summaryAsk = () => extraction([], [{ tool: 'care_summary', dayOffset: 0 }]);
const clarifyAsk = () => extraction([], [], { field: (outputs.clarify!.missing as string[])[0]! });
const FEED_AT = batch[0]!.at!;
const SLEEP_START = batch[1]!.start!;
const SLEEP_END = batch[1]!.end!;

// ---------- Helpers ----------

const E = (over: Record<string, unknown> = {}) => ({
  contractVersion: 1,
  clientRequestId: randomUUID(),
  locale: 'vi',
  ...over,
});
const placeholder = () => fakeModelGateway({});
const deps = (gateway: ModelGateway | null = placeholder(), at = now): AssistantDeps => ({
  db,
  now: at,
  environment: 'test',
  gateway,
});
const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason ?? String(e),
  );

async function quote(
  uid = MOM,
  over: Record<string, unknown> = {},
  gw: ModelGateway | null = placeholder(),
  at = now,
) {
  const r = await quoteTask(
    deps(gw, at),
    uid,
    E({
      conversationId: null,
      scope: SCOPE,
      modality: 'text',
      attachmentCount: 0,
      intentHint: null,
      ...over,
    }),
  );
  return r.data;
}

interface StartOpts {
  uid?: string;
  gw?: ModelGateway | null;
  at?: Date;
  requestId?: string;
  conversationId?: string | null;
  scope?: { type: 'child' | 'household'; babyId: string };
  quoteId?: string;
}
async function start(text: string, o: StartOpts = {}) {
  const uid = o.uid ?? MOM;
  const gw = o.gw === undefined ? placeholder() : o.gw;
  const scope = o.scope ?? SCOPE;
  const quoteId =
    o.quoteId ??
    (await quote(uid, { scope, conversationId: o.conversationId ?? null }, gw, o.at)).quoteId;
  return startTask(
    deps(gw, o.at),
    uid,
    E({
      clientRequestId: o.requestId ?? randomUUID(),
      conversationId: o.conversationId ?? null,
      scope,
      quoteId,
      text,
      attachmentIds: [],
    }),
  );
}

const work = (taskId: string, gateway: ModelGateway | null, at = now) =>
  runAssistantTask({ db, now: at, environment: 'test', gateway, timeoutMs: 500 }, taskId);

async function snapshot(taskId: string, uid = MOM, after: number | null = null) {
  return (await getAssistantTask(deps(), uid, E({ taskId, afterSequence: after }))).data;
}

/** Start + run one task with [script]; returns the task id, gateway and snapshot. */
async function prepared(
  script: FakeStep<ExtractInput>[] = [textBatch()],
  text = TEXT,
  o: StartOpts = {},
) {
  const gw = fakeModelGateway({ extract: script, word: [] });
  const r = await start(text, { ...o, gw });
  const taskId = r.taskId!;
  await work(taskId, gw, o.at);
  return { taskId, gw, snap: await snapshot(taskId, o.uid ?? MOM) };
}

const confirm = (
  taskId: string,
  selected: {
    draftId: string;
    revision: number;
    acknowledge?: ('overlap' | 'duplicate_suspected')[];
  }[],
  o: {
    uid?: string;
    at?: Date;
    requestId?: string;
    scope?: { type: 'child'; babyId: string };
  } = {},
) =>
  confirmDrafts(
    deps(null, o.at),
    o.uid ?? MOM,
    E({
      clientRequestId: o.requestId ?? randomUUID(),
      taskId,
      selected: selected.map((s) => ({ acknowledge: [], ...s })),
      ...(o.scope ? { scope: o.scope } : {}),
    }),
  );

const patch = (
  draftId: string,
  expectedRevision: number,
  payload: DraftPayload,
  confirmedFields: string[] = [],
  at = now,
) => patchDraft(deps(null, at), MOM, E({ draftId, expectedRevision, payload, confirmedFields }));

const win = async (id = WIN) =>
  (await db.doc(`families/${F}/quota/${id}`).get()).data() ?? { used: 0, reserved: 0, limit: 0 };
const opsDocs = async () => (await db.collection(`families/${F}/quotaOps`).get()).docs;
const recordDocs = async (baby = B) => (await db.collection(`babies/${baby}/records`).get()).docs;
const assistantRecords = async (baby = B) =>
  (await recordDocs(baby)).filter((d) => d.get('source') === 'assistant');

async function setFreeLimit(limit: number) {
  await db.doc('config/entitlements').set({
    ...defaultEntitlementsConfig,
    regions: { advanced: ['VN'] },
    quotas: {
      ...defaultEntitlementsConfig.quotas,
      assistant: { ...defaultEntitlementsConfig.quotas.assistant, free: limit },
    },
  });
}

async function consent(uid: string) {
  await setAssistantConsent(deps(), uid, E({ consent: { version: assistantConsentVersion } }));
}

async function seedRecord(
  id: string,
  type: string,
  occurredAt: string,
  data: Record<string, unknown>,
  endedAt: string | null = null,
  over: Record<string, unknown> = {},
) {
  await db.doc(`babies/${B}/records/${id}`).set({
    id,
    babyId: B,
    type,
    occurredAt: Timestamp.fromDate(new Date(occurredAt)),
    endedAt: endedAt ? Timestamp.fromDate(new Date(endedAt)) : null,
    data,
    createdBy: DAD,
    author: { name: 'Huy', relation: 'father', relationCustom: null },
    createdAt: Timestamp.fromDate(now),
    clientCreatedAt: Timestamp.fromDate(now),
    updatedAt: Timestamp.fromDate(now),
    updatedBy: DAD,
    deleted: false,
    deletedAt: null,
    deletedBy: null,
    source: 'app',
    ...over,
  });
}

/** R01 / J02: the pack's logs.json (3 bottles 150 + 120 + 120, nursing 20 + 15) today. */
async function seedPackLogs() {
  const times = ['2026-10-14T23:00:00Z', '2026-10-15T03:00:00Z', '2026-10-15T06:00:00Z'];
  let b = 0;
  let n = 0;
  for (const l of logs) {
    if (l.kind === 'bottle') {
      await seedRecord(l.id, 'bottle', times[b++]!, { amountMl: l.ml, milk: 'formula' });
    } else {
      const at = ['2026-10-15T00:30:00Z', '2026-10-15T04:30:00Z'][n++]!;
      await seedRecord(l.id, 'breast', at, { side: 'left', durationMin: l.minutes });
    }
  }
  // Not today, or deleted: never counted.
  await seedRecord('test_y1', 'bottle', '2026-10-14T10:00:00Z', { amountMl: 90, milk: 'formula' });
  await seedRecord(
    'test_d1',
    'bottle',
    '2026-10-15T05:00:00Z',
    { amountMl: 60, milk: 'formula' },
    null,
    {
      deleted: true,
    },
  );
}

const L = (vi: string, en = vi) => ({ vi, en });
const activity = (id: string): Activity => ({
  id,
  version: 1,
  status: 'published',
  title: L(`Tiêu đề ${id}`),
  summary: L('Tóm tắt'),
  steps: { vi: ['Bước 1'], en: ['Step 1'] },
  safety: null,
  durationMin: 10,
  ageDays: { from: 0, to: 365 },
  needs: ['sleep'],
  interests: [],
  timeOfDay: 'evening',
  locales: ['vi', 'en'],
  regions: [],
  sources: [],
  review: null,
});
const content = (): RhythmContent => ({
  version: 'rc_20261015_01',
  publishedAt: now.toISOString(),
  activities: [activity('act_test_sleep')],
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

const member = (
  role: string,
  relation: string,
  displayName: string,
  extra: Record<string, unknown> = {},
) => ({
  role,
  status: 'active',
  relation,
  relationCustom: null,
  displayName,
  ...extra,
});

beforeAll(() => {
  app = initializeApp({ projectId }, `assistant-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
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
    rhythm: on('rhythm'),
  });
  await setFreeLimit(20);
  await db.doc('publicConfig/content_rhythm').set(content());
  for (const [baby, family, owner] of [
    [B, F, MOM],
    [NA, F, MOM],
    [B2, F2, STRANGER],
  ] as const) {
    await db.doc(`babies/${baby}`).set({
      familyId: family,
      timeZone: { mode: 'auto', zone: ZONE },
      state: 'active',
    });
    await db.doc(`families/${family}`).set({ ownerUid: owner, country: 'VN', timeZone: ZONE });
    await db
      .doc(`babies/${baby}/members/${owner}`)
      .set(member('coParent', 'mother', owner === MOM ? 'Mai' : 'Lan', { isOwner: true }));
  }
  await db.doc(`babies/${B}/members/${DAD}`).set(member('coParent', 'father', 'Huy'));
  await db.doc(`babies/${B}/members/${NANNY}`).set(member('caregiver', 'nanny', 'Cô Hoa'));
  await db.doc(`babies/${B}/members/${AUNT}`).set(
    member('relative', 'relative', 'Dì Thu', {
      extraRights: { viewBabyInfo: false, viewDailyCare: true },
    }),
  );
  await db.doc(`babies/${B}/members/${GRANDMA}`).set(member('relative', 'grandmother', 'Bà'));
  for (const uid of [MOM, DAD, NANNY, AUNT, GRANDMA, STRANGER]) await consent(uid);
});

const drafts = (s: AssistantTaskSnapshot) => s.drafts;

// =====================================================================================
describe('D: drafts, validation, revision, partial save, retry', () => {
  it('D01: a text batch prepares two drafts and writes no domain record (1 credit)', async () => {
    const { snap } = await prepared();
    expect(snap.task.state).toBe('ready');
    expect(drafts(snap).map((d) => d.payload.kind)).toEqual(['bottle', 'sleep']);
    expect(drafts(snap)[0]!.payload).toEqual({
      kind: 'bottle',
      amountMl: 120,
      occurredAt: FEED_AT.replace('Z', '.000Z'),
      milk: 'breast_milk',
    });
    expect(drafts(snap)[1]!.payload).toMatchObject({
      startedAt: SLEEP_START.replace('Z', '.000Z'),
      endedAt: SLEEP_END.replace('Z', '.000Z'),
    });
    expect(drafts(snap).every((d) => d.state === 'draft' && d.revision === 1)).toBe(true);
    expect(await recordDocs()).toHaveLength(0);
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
    const parts = snap.messages.at(-1)!.parts;
    expect(parts.filter((p) => p.type === 'draft_reference')).toHaveLength(2);
  });

  it('D02: edit 120 → 150 then save: one record with 150 ml, still 1 credit', async () => {
    const { taskId, snap } = await prepared();
    const d = drafts(snap)[0]!;
    const p = await patch(d.id, 1, {
      ...(d.payload as DraftPayload & { kind: 'bottle' }),
      amountMl: 150,
    });
    expect(p.data.draft.revision).toBe(2);
    const r = await confirm(taskId, [{ draftId: d.id, revision: 2 }]);
    expect(r.data.items[0]).toMatchObject({ status: 'saved', errorCode: null });
    const rec = (await assistantRecords())[0]!;
    expect(rec.get('data')).toEqual({ amountMl: 150, milk: 'breastMilk' });
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
  });

  it('D03: partial save — feed saved, sleep conflict kept unsaved, retry only the sleep', async () => {
    await seedRecord(
      'r_' + 'a'.repeat(32),
      'sleep',
      '2026-10-15T02:30:00Z',
      {},
      '2026-10-15T03:30:00Z',
    );
    const { taskId, snap } = await prepared();
    const [feed, sleep] = drafts(snap);
    expect(sleep!.warnings).toEqual(['overlap']);
    const first = await confirm(taskId, [
      { draftId: feed!.id, revision: 1 },
      { draftId: sleep!.id, revision: 1 },
    ]);
    expect(first.status).toBe('partial');
    expect(first.data.items.map((i) => i.status)).toEqual(['saved', 'conflict']);
    expect(first.data.items[1]!.errorCode).toBe('DOMAIN_CONFLICT');
    expect(await assistantRecords()).toHaveLength(1);
    const retry = await confirm(taskId, [
      { draftId: sleep!.id, revision: 1, acknowledge: ['overlap'] },
    ]);
    expect(retry.data.items[0]!.status).toBe('saved');
    const again = await confirm(taskId, [{ draftId: feed!.id, revision: 1 }]);
    expect(again.data.items[0]!.recordId).toBe(first.data.items[0]!.recordId);
    expect(await assistantRecords()).toHaveLength(2);
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
  });

  it('D04: a confirm on an older revision is DRAFT_STALE and writes nothing', async () => {
    const { taskId, snap } = await prepared();
    const d = drafts(snap)[0]!;
    await patch(d.id, 1, { ...(d.payload as DraftPayload & { kind: 'bottle' }), amountMl: 150 });
    const r = await confirm(taskId, [{ draftId: d.id, revision: 1 }]);
    expect(r.data.items[0]).toMatchObject({ status: 'failed', errorCode: 'DRAFT_STALE' });
    expect(await recordDocs()).toHaveLength(0);
    expect(await reason(patch(d.id, 1, d.payload))).toBe('DRAFT_STALE');
  });

  it('D05: after the 24 h TTL the draft is DRAFT_EXPIRED (confirm and patch)', async () => {
    const { taskId, snap } = await prepared();
    const d = drafts(snap)[0]!;
    const later = new Date(now.getTime() + 24 * 3_600_000);
    const r = await confirm(taskId, [{ draftId: d.id, revision: 1 }], { at: later });
    expect(r.data.items[0]).toMatchObject({ status: 'failed', errorCode: 'DRAFT_EXPIRED' });
    expect(await reason(patch(d.id, 1, d.payload, [], later))).toBe('DRAFT_EXPIRED');
    expect(await recordDocs()).toHaveLength(0);
  });

  it('D06: invalid amounts never save (negative refused; over the limit needs review)', async () => {
    const { taskId, snap } = await prepared();
    const d = drafts(snap)[0]!;
    const bottle = d.payload as DraftPayload & { kind: 'bottle' };
    expect(await reason(patch(d.id, 1, { ...bottle, amountMl: -1 }))).toBe('VALIDATION_FAILED');
    const p = await patch(d.id, 1, { ...bottle, amountMl: 600 });
    expect(p.data.draft).toMatchObject({ state: 'needs_review', uncertainFields: ['amountMl'] });
    expect(p.data.draft.problems).toContain('INVALID_AMOUNT');
    const r = await confirm(taskId, [{ draftId: d.id, revision: 2 }]);
    expect(r.data.items[0]).toMatchObject({ status: 'failed', errorCode: 'REVIEW_REQUIRED' });
    expect(await recordDocs()).toHaveLength(0);
  });

  it('D07: a sleep ending before it starts is kept for review, never flipped or moved overnight', async () => {
    const reversed = extraction([
      intent('sleep', { time: '10:00', endTime: '09:00', dayOffset: 0 }, [
        { field: 'time', text: '10 giờ sáng' },
        { field: 'endTime', text: '9 giờ' },
      ]),
    ]);
    const { taskId, snap } = await prepared([reversed], 'Con ngủ từ 10 giờ sáng tới 9 giờ.');
    const d = drafts(snap)[0]!;
    // Rework 2026-10-15: the draft also carries its length (none: the end is before the start).
    expect(d.payload).toEqual({
      kind: 'sleep',
      startedAt: '2026-10-15T03:00:00.000Z',
      endedAt: '2026-10-15T02:00:00.000Z',
      durationMin: null,
      linked: null,
    });
    expect(d.state).toBe('needs_review');
    expect(d.uncertainFields).toContain('endedAt');
    expect(d.problems).toContain('INVALID_TIME');
    const r = await confirm(taskId, [{ draftId: d.id, revision: 1 }]);
    expect(r.data.items[0]!.errorCode).toBe('REVIEW_REQUIRED');
    // The pack's D07: patching the end before the start is still refused at confirm.
    const { taskId: t2, snap: s2 } = await prepared();
    const sl = drafts(s2)[1]!;
    const p = await patch(sl.id, 1, {
      ...(sl.payload as DraftPayload & { kind: 'sleep' }),
      endedAt: '2026-10-15T01:00:00.000Z',
    });
    expect(p.data.draft.problems).toContain('INVALID_TIME');
    expect((await confirm(t2, [{ draftId: sl.id, revision: 2 }])).data.items[0]!.status).toBe(
      'failed',
    );
    expect(await recordDocs()).toHaveLength(0);
  });

  it('D08: ready drafts still save when the household has 0 credits left', async () => {
    await setFreeLimit(1);
    const { taskId, snap } = await prepared();
    expect((await getAssistantUsage(deps(), MOM, E({ babyId: B }))).data.remaining).toBe(0);
    const r = await confirm(taskId, [{ draftId: drafts(snap)[0]!.id, revision: 1 }]);
    expect(r.data.items[0]!.status).toBe('saved');
    expect(await assistantRecords()).toHaveLength(1);
  });
});

// =====================================================================================
describe('U: credits — quote, reserve, commit, release, upgrade', () => {
  it('U01: the same request replayed is the same task, charged once', async () => {
    const gw = fakeModelGateway({ extract: [textBatch()] });
    const requestId = randomUUID();
    const a = await start(TEXT, { gw, requestId });
    await work(a.taskId!, gw);
    const b = await start(TEXT, { gw, requestId });
    expect(b.taskId).toBe(a.taskId);
    expect((await work(b.taskId!, gw)).ran).toBe(false);
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
    expect(await opsDocs()).toHaveLength(1);
  });

  it('U02: the same request id with a different input is IDEMPOTENCY_CONFLICT', async () => {
    const requestId = randomUUID();
    await start(TEXT, { requestId });
    expect(await reason(start('9 giờ sáng con bú 90 ml', { requestId }))).toBe(
      'IDEMPOTENCY_CONFLICT',
    );
    expect(await opsDocs()).toHaveLength(1);
  });

  it('U03: a photo quote of 3 with 2 left is blocked before any upload or reservation', async () => {
    await setFreeLimit(2);
    await db.doc('config/flags').set({ assistant_images: on('assistant_images') }, { merge: true });
    const q = await quote(MOM, { modality: 'image', attachmentCount: 1 });
    expect(q).toMatchObject({ credits: 3, allowed: false, reason: 'USAGE_EXHAUSTED' });
    expect(q.usage).toMatchObject({ remaining: 2, limit: 2 });
    expect(await opsDocs()).toHaveLength(0);
    expect((await win()).reserved).toBe(0);
  });

  it('U04: a provider failure releases the credit (0 used, 0 held)', async () => {
    const { snap } = await prepared([new ModelUnavailable('http')]);
    expect(snap.task).toMatchObject({
      state: 'failed',
      errorCode: 'AI_UNAVAILABLE',
      usage: 'released',
    });
    expect(await win()).toMatchObject({ used: 0, reserved: 0 });
  });

  it('U05: a clarification holds the same reservation; the answer continues the same task', async () => {
    const gw = fakeModelGateway({ extract: [clarifyAsk(), textBatch()] });
    const r = await start(TEXT, { gw });
    await work(r.taskId!, gw);
    const s1 = await snapshot(r.taskId!);
    expect(s1.task).toMatchObject({ state: 'awaiting_clarification', usage: 'reserved' });
    expect(s1.task.clarification).toMatchObject({ field: 'sleep.period' });
    expect(await win()).toMatchObject({ used: 0, reserved: 1 });
    const c = await submitClarification(
      deps(gw),
      MOM,
      E({
        taskId: r.taskId,
        expectedVersion: s1.task.version,
        clarificationId: s1.task.clarification!.id,
        choiceId: 'falling_asleep',
        text: null,
      }),
    );
    expect(c.data.task.state).toBe('queued');
    await work(r.taskId!, gw);
    expect((await snapshot(r.taskId!)).task.state).toBe('ready');
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
    expect(await opsDocs()).toHaveLength(1);
    expect(gw.calls.extract[1]!.clarifications).toEqual([
      { field: 'sleep.period', answer: 'falling_asleep' },
    ]);
  });

  it('U06: cancel then a late worker callback: canceled, nothing charged or written', async () => {
    const gw = fakeModelGateway({ extract: [textBatch()] });
    const r = await start(TEXT, { gw });
    await cancelTask(deps(), MOM, E({ taskId: r.taskId }));
    expect((await work(r.taskId!, gw)).ran).toBe(false);
    const s = await snapshot(r.taskId!);
    expect(s.task).toMatchObject({ state: 'canceled', usage: 'released' });
    expect(s.drafts).toHaveLength(0);
    expect(await win()).toMatchObject({ used: 0, reserved: 0 });
  });

  it('U08: blocked at 0, verified paid grant → re-quoted at the paid pool, charged once, no second pool', async () => {
    await setFreeLimit(1);
    await prepared();
    const requestId = randomUUID();
    const blocked = await start(AGAIN, { requestId });
    expect(blocked).toMatchObject({ status: 'blocked', reasonCode: 'USAGE_EXHAUSTED' });
    expect(blocked.data.task).toMatchObject({ state: 'blocked', usage: 'none' });
    expect(await opsDocs()).toHaveLength(1);
    const grant = {
      familyId: F,
      source: 'paid',
      status: 'active',
      environment: 'test',
      capabilities: [...premiumCapabilities],
      validFrom: Timestamp.fromDate(new Date('2026-10-15T07:00:00Z')),
      validUntil: Timestamp.fromDate(new Date('2026-11-15T07:00:00Z')),
      billingOwnerUid: MOM,
      provider: 'apple',
      sourceRef: 'test_account',
      campaignId: null,
      autoRenew: true,
      periodStart: Timestamp.fromDate(new Date('2026-10-15T07:00:00Z')),
      updatedAt: Timestamp.fromDate(now),
    };
    await db.doc(`families/${F}/grants/paid_test_account`).set(grant);
    const q = await quote();
    expect(q.usage).toMatchObject({ plan: 'premium', limit: 200, used: 0 });
    const gw = fakeModelGateway({ extract: [textBatch()] });
    const resumed = await start(AGAIN, { requestId, quoteId: q.quoteId, gw });
    expect(resumed.taskId).toBe(blocked.taskId);
    expect(resumed.data.task).toMatchObject({
      state: 'queued',
      plan: 'premium',
      usage: 'reserved',
    });
    await work(resumed.taskId!, gw);
    const PAID = 'assistant_paid_paid_test_account_2026-10-15';
    expect(await win(PAID)).toMatchObject({ used: 1, reserved: 0, limit: 200 });
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
    // A repeated verified event rewrites the same grant and period: the same pool.
    await db
      .doc(`families/${F}/grants/paid_test_account`)
      .set({ ...grant, updatedAt: Timestamp.now() });
    const again = await quote();
    expect(again.usage).toMatchObject({ plan: 'premium', used: 1, limit: 200 });
    expect((await db.collection(`families/${F}/quota`).get()).size).toBe(2);
  });

  it('U09: an unverified (pending) purchase gives no paid pool; the task stays blocked', async () => {
    await setFreeLimit(0);
    const requestId = randomUUID();
    await start(TEXT, { requestId });
    await db.doc(`families/${F}/grants/paid_pending`).set({
      familyId: F,
      source: 'paid',
      status: 'pending',
      environment: 'test',
      capabilities: [...premiumCapabilities],
      validFrom: Timestamp.fromDate(new Date('2026-10-15T07:00:00Z')),
      validUntil: Timestamp.fromDate(new Date('2026-11-15T07:00:00Z')),
      billingOwnerUid: MOM,
      provider: 'apple',
      sourceRef: 'test_pending',
      campaignId: null,
      autoRenew: true,
      updatedAt: Timestamp.fromDate(now),
    });
    const q = await quote();
    expect(q.usage.plan).toBe('free');
    const r = await start(TEXT, { requestId, quoteId: q.quoteId });
    expect(r).toMatchObject({ status: 'blocked', reasonCode: 'USAGE_EXHAUSTED' });
    expect(await opsDocs()).toHaveLength(0);
  });

  it('U10: health signs → health support at quota 0, 0 credits, no model, no record', async () => {
    await setFreeLimit(0);
    const gw = fakeModelGateway({});
    const q = await quote();
    expect(q).toMatchObject({ allowed: false, reason: 'USAGE_EXHAUSTED' });
    const r = await start('Bé khó thở, môi tím tái', { gw, quoteId: q.quoteId });
    expect(r.status).toBe('ok');
    expect(r.data.task).toMatchObject({ state: 'ready', credits: 0, usage: 'none' });
    const s = await snapshot(r.taskId!);
    expect(s.messages.at(-1)!.parts).toEqual([
      { type: 'health_support', schemaVersion: 1, signs: ['breathing'] },
    ]);
    expect(gw.calls.extract).toHaveLength(0);
    expect(await opsDocs()).toHaveLength(0);
    expect(await recordDocs()).toHaveLength(0);
  });

  it('flags: model off → blocked AI_UNAVAILABLE before reserving; chat off → FEATURE_DISABLED', async () => {
    await db
      .doc('config/flags')
      .set({ assistant_live: offFlag('assistant_live') }, { merge: true });
    expect((await quote()).reason).toBe('AI_UNAVAILABLE');
    const r = await start(TEXT);
    expect(r).toMatchObject({ status: 'blocked', reasonCode: 'AI_UNAVAILABLE', retryable: true });
    expect(await opsDocs()).toHaveLength(0);
    expect(await reason(start(TEXT, { gw: null }))).toBe('ok');
    await db.doc('config/flags').set({ assistant: offFlag('assistant') }, { merge: true });
    expect(await reason(quote())).toBe('FEATURE_DISABLED');
  });

  it('quotes expire after 5 minutes and are single-use', async () => {
    const q = await quote();
    const late = new Date(now.getTime() + 6 * 60_000);
    expect(await reason(start(TEXT, { quoteId: q.quoteId, at: late }))).toBe('QUOTE_EXPIRED');
    await start(TEXT, { quoteId: q.quoteId });
    expect(await reason(start(TEXT, { quoteId: q.quoteId }))).toBe('QUOTE_MISMATCH');
  });
});

// =====================================================================================
describe('S: scope, role, consent', () => {
  it('S01: a viewer (relative with daily care) reads summaries but gets no drafts and pays nothing for writes', async () => {
    const read = await prepared([summaryAsk()], 'Hôm nay con bú thế nào?', { uid: AUNT });
    expect(read.snap.task.state).toBe('ready');
    expect(read.snap.messages.at(-1)!.parts.some((p) => p.type === 'source_summary')).toBe(true);
    const write = await prepared([textBatch()], TEXT, { uid: AUNT });
    expect(write.snap.task).toMatchObject({
      state: 'failed',
      errorCode: 'WRITE_DENIED',
      usage: 'released',
    });
    expect(write.snap.drafts).toHaveLength(0);
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
    // A relative without daily care cannot read the log.
    const g = await prepared([summaryAsk()], 'Hôm nay con bú thế nào?', { uid: GRANDMA });
    expect(g.snap.task).toMatchObject({ state: 'failed', errorCode: 'READ_DENIED' });
  });

  it('S02: another household’s baby is NOT_MEMBER (quote and start)', async () => {
    const other = { type: 'child' as const, babyId: B2 };
    expect(await reason(quote(MOM, { scope: other }))).toBe('NOT_MEMBER');
    const q = await quote();
    expect(await reason(start(TEXT, { scope: other, quoteId: q.quoteId }))).toBe('NOT_MEMBER');
    expect(await opsDocs()).toHaveLength(0);
  });

  it('S03: another child — not a member → NOT_MEMBER; a conversation of another child → SCOPE_CHANGED', async () => {
    const na = { type: 'child' as const, babyId: NA };
    expect(await reason(quote(DAD, { scope: na }))).toBe('NOT_MEMBER');
    const { snap } = await prepared();
    const conversationId = snap.task.conversationId;
    expect(await reason(quote(MOM, { scope: na, conversationId }))).toBe('SCOPE_CHANGED');
    const q = await quote(MOM, { scope: na });
    expect(await reason(start(TEXT, { scope: na, conversationId, quoteId: q.quoteId }))).toBe(
      'SCOPE_CHANGED',
    );
  });

  it('S04: without the assistant consent nothing starts; the summaries consent is separate', async () => {
    await setAssistantConsent(deps(), MOM, E({ consent: null }));
    expect((await quote()).reason).toBe('CONSENT_REQUIRED');
    expect(await reason(start(TEXT))).toBe('CONSENT_REQUIRED');
    expect(await opsDocs()).toHaveLength(0);
    const doc = (await db.doc(`users/${MOM}/settings/ai`).get()).data()!;
    expect(doc.assistant).toBeNull();
    expect(await reason(setAssistantConsent(deps(), MOM, E({ consent: { version: 'old' } })))).toBe(
      'VALIDATION_FAILED',
    );
  });

  it('S05: consent withdrawn while queued → no dispatch, credits released', async () => {
    const gw = fakeModelGateway({ extract: [textBatch()] });
    const r = await start(TEXT, { gw });
    const w = await setAssistantConsent(deps(), MOM, E({ consent: null }));
    expect(w.data.stoppedTasks).toBe(1);
    expect((await work(r.taskId!, gw)).ran).toBe(false);
    expect(gw.calls.extract).toHaveLength(0);
    expect((await snapshot(r.taskId!)).task).toMatchObject({
      state: 'failed',
      errorCode: 'CONSENT_REQUIRED',
    });
    expect(await win()).toMatchObject({ used: 0, reserved: 0 });
  });

  it('S06: membership removed after the draft → confirm denied, nothing written', async () => {
    const { taskId, snap } = await prepared();
    await db.doc(`babies/${B}/members/${MOM}`).update({ status: 'removed' });
    expect(await reason(confirm(taskId, [{ draftId: drafts(snap)[0]!.id, revision: 1 }]))).toBe(
      'NOT_MEMBER',
    );
    expect(await recordDocs()).toHaveLength(0);
    expect(await reason(getAssistantTask(deps(), MOM, E({ taskId, afterSequence: null })))).toBe(
      'NOT_MEMBER',
    );
  });

  it('D-075 #2: a private task (household scope) stays with its owner: no read, no confirm', async () => {
    const { taskId, snap } = await prepared([textBatch()], TEXT, {
      scope: { type: 'household', babyId: B },
    });
    expect(snap.task.visibility).toBe('private');
    expect(await reason(getAssistantTask(deps(), DAD, E({ taskId, afterSequence: null })))).toBe(
      'NOT_MEMBER',
    );
    expect(
      await reason(confirm(taskId, [{ draftId: drafts(snap)[0]!.id, revision: 1 }], { uid: DAD })),
    ).toBe('NOT_MEMBER');
  });
});

// =====================================================================================
describe('E: schema, grounding, model failure', () => {
  it('E01: an unknown tool request is rejected: 0 credits, no write', async () => {
    const { snap } = await prepared([outputs.injection]);
    expect(snap.task).toMatchObject({
      state: 'failed',
      errorCode: 'VALIDATION_FAILED',
      usage: 'released',
    });
    expect(await win()).toMatchObject({ used: 0, reserved: 0 });
    expect(await recordDocs()).toHaveLength(0);
  });

  it('E02: a duplicate finish keeps two drafts and one charge', async () => {
    const { taskId, gw } = await prepared();
    expect((await work(taskId, gw)).ran).toBe(false);
    expect((await snapshot(taskId)).drafts).toHaveLength(2);
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
  });

  it('E03: edits never charge', async () => {
    const { snap } = await prepared();
    const d = drafts(snap)[0]!;
    const bottle = d.payload as DraftPayload & { kind: 'bottle' };
    await patch(d.id, 1, { ...bottle, amountMl: 150 });
    await patch(d.id, 2, { ...bottle, amountMl: 160 });
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
  });

  it('"8 giờ" with no morning/evening asks when both are possible; the answer is applied, never guessed', async () => {
    const at8 = extraction([
      intent('bottle', { amountMl: 120, time: '08:00', dayOffset: 0 }, [
        { field: 'time', text: '8 giờ' },
      ]),
    ]);
    // Rework 2026-10-15: at 14:20, 20:00 would be in the future, so 08:00 needs no question.
    const day = await prepared([at8], '8 giờ con bú bình 120 ml');
    expect(day.snap.task.clarification).toBeNull();
    expect(drafts(day.snap)[0]!.payload).toMatchObject({ occurredAt: '2026-10-15T01:00:00.000Z' });
    // At 21:30 both 08:00 and 20:00 are past: asked once; the reading is reused (one call).
    const evening = new Date('2026-10-15T14:30:00Z');
    const gw = fakeModelGateway({ extract: [at8] });
    const r = await start('8 giờ con bú bình 120 ml', { gw, at: evening });
    await work(r.taskId!, gw, evening);
    const s1 = await snapshot(r.taskId!);
    expect(s1.task.clarification).toMatchObject({ field: 'time.ampm' });
    await submitClarification(
      deps(gw, evening),
      MOM,
      E({
        taskId: r.taskId,
        expectedVersion: s1.task.version,
        clarificationId: s1.task.clarification!.id,
        choiceId: 'pm',
        text: null,
      }),
    );
    await work(r.taskId!, gw, evening);
    const d = (await snapshot(r.taskId!)).drafts[0]!;
    expect(d.payload).toMatchObject({ occurredAt: '2026-10-15T13:00:00.000Z' });
    expect(d.state).toBe('draft');
    expect(gw.calls.extract).toHaveLength(1);
    expect(await win()).toMatchObject({ used: 2, reserved: 0 });
  });

  it('evidence not in the person’s words makes the field uncertain (review before save)', async () => {
    const invented = extraction([
      intent('bottle', { amountMl: 180, time: '08:00', dayOffset: 0 }, [
        { field: 'amountMl', text: '180 ml' },
        { field: 'time', text: '8 giờ sáng' },
      ]),
    ]);
    const { taskId, snap } = await prepared([invented]);
    expect(drafts(snap)[0]!.uncertainFields).toEqual(['amountMl']);
    const r = await confirm(taskId, [{ draftId: drafts(snap)[0]!.id, revision: 1 }]);
    expect(r.data.items[0]!.errorCode).toBe('REVIEW_REQUIRED');
  });

  it('kinds without a module are not drafted: MODULE_UNAVAILABLE, released', async () => {
    // Rework 2026-10-15: typed expenses and reminders have modules now; meals still do not.
    const exp = extraction([
      intent('meal', { title: 'Cháo bí đỏ' }, [{ field: 'title', text: 'cháo bí đỏ' }]),
    ]);
    const { snap } = await prepared([exp], 'Bé ăn cháo bí đỏ');
    expect(snap.task).toMatchObject({
      state: 'failed',
      errorCode: 'MODULE_UNAVAILABLE',
      usage: 'released',
    });
    expect(await win()).toMatchObject({ used: 0, reserved: 0 });
  });

  it('a model timeout releases the credit', async () => {
    const slow = () => new Promise((r) => setTimeout(() => r(textBatch()), 2_000));
    const { snap } = await prepared([slow]);
    expect(snap.task).toMatchObject({ state: 'failed', errorCode: 'AI_UNAVAILABLE' });
    expect(await win()).toMatchObject({ used: 0, reserved: 0 });
  });
});

// =====================================================================================
describe('R: read summaries', () => {
  it('R01: 3 bottles = 390 ml and nursing 35 min stay apart; 5 sources; wording grounded', async () => {
    await seedPackLogs();
    const gw = fakeModelGateway({
      extract: [summaryAsk(), summaryAsk()],
      word: [
        { text: 'Đã ghi 3 cữ bú bình, 390 ml; bú mẹ 2 lần, 35 phút.' },
        { text: 'Bé chỉ bú 425 ml.' },
      ],
    });
    const r = await start('Hôm nay con bú thế nào?', { gw });
    await work(r.taskId!, gw);
    const parts = (await snapshot(r.taskId!)).messages.at(-1)!.parts;
    const summary = parts.find((p) => p.type === 'source_summary') as Extract<
      AssistantPart,
      { type: 'source_summary' }
    >;
    expect(summary.summary.bottle).toEqual({ count: 3, ml: outputs.summary!.bottleMl });
    expect(summary.summary.breast).toEqual({ count: 2, minutes: outputs.summary!.nursingMinutes });
    expect(summary.summary.coverage).toBe('unknown');
    expect([...summary.sourceIds].sort()).toEqual(
      [...(outputs.summary!.sources as string[])].sort(),
    );
    expect(parts.find((p) => p.type === 'text')).toMatchObject({
      text: 'Đã ghi 3 cữ bú bình, 390 ml; bú mẹ 2 lần, 35 phút.',
    });
    // A wording with a number that is not in the facts falls back to the engine's template.
    const r2 = await start('Hôm nay con bú thế nào?', { gw });
    await work(r2.taskId!, gw);
    const text = (await snapshot(r2.taskId!)).messages
      .at(-1)!
      .parts.find((p) => p.type === 'text') as { text: string };
    expect(text.text).not.toContain('425');
    expect(text.text).toContain('390 ml');
  });

  it('R03: a read task writes no domain record and costs 1 credit', async () => {
    await seedPackLogs();
    const before = (await recordDocs()).length;
    await prepared([summaryAsk()], 'Hôm nay con bú thế nào?');
    expect(await recordDocs()).toHaveLength(before);
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
  });
});

// =====================================================================================
describe('M: integration matrix', () => {
  it('M01: replay and key conflict on start and confirm', async () => {
    const { taskId, snap } = await prepared();
    const d = drafts(snap)[0]!;
    const requestId = randomUUID();
    const a = await confirm(taskId, [{ draftId: d.id, revision: 1 }], { requestId });
    const b = await confirm(taskId, [{ draftId: d.id, revision: 1 }], { requestId });
    expect(b).toEqual(a);
    expect(
      await reason(confirm(taskId, [{ draftId: drafts(snap)[1]!.id, revision: 1 }], { requestId })),
    ).toBe('IDEMPOTENCY_CONFLICT');
    expect(await assistantRecords()).toHaveLength(1);
  });

  it('M02: 20 concurrent starts on a 1-credit window → at most one reservation', async () => {
    await setFreeLimit(1);
    const quotes = [];
    for (let i = 0; i < 20; i += 1) quotes.push((await quote()).quoteId);
    const out = await Promise.allSettled(quotes.map((quoteId) => start(TEXT, { quoteId })));
    const answered = out
      .filter((o) => o.status === 'fulfilled')
      .map(
        (o) => (o as PromiseFulfilledResult<AssistantResponse<{ task: { state: string } }>>).value,
      );
    const reserved = answered.filter((r) => r.data.task.state === 'queued');
    expect(reserved.length).toBeLessThanOrEqual(1);
    expect(
      answered
        .filter((r) => r.data.task.state !== 'queued')
        .every((r) => r.reasonCode === 'USAGE_EXHAUSTED'),
    ).toBe(true);
    const w = await win();
    expect(quotaInvariantHolds({ limit: w.limit, used: w.used, reserved: w.reserved })).toBe(true);
    expect(w.reserved).toBe(reserved.length);
    expect((await opsDocs()).length).toBe(reserved.length);
  }, 120_000);

  it('M03: duplicate worker delivery runs once; a late callback after cancel cannot commit', async () => {
    const gw = fakeModelGateway({ extract: [textBatch(), textBatch()] });
    const r = await start(TEXT, { gw });
    const runs = await Promise.all([work(r.taskId!, gw), work(r.taskId!, gw)]);
    expect(runs.filter((x) => x.ran)).toHaveLength(1);
    expect((await snapshot(r.taskId!)).drafts).toHaveLength(2);
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });

    let taskId = '';
    const cancelling = fakeModelGateway({
      extract: [
        async () => {
          await cancelTask(deps(), MOM, E({ taskId }));
          return textBatch();
        },
      ],
    });
    const r2 = await start(AGAIN, { gw: cancelling });
    taskId = r2.taskId!;
    const late = await work(taskId, cancelling);
    expect(late).toMatchObject({ ran: true, fenced: true });
    const s = await snapshot(taskId);
    expect(s.task).toMatchObject({ state: 'canceled', usage: 'released' });
    expect(s.drafts).toHaveLength(0);
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
  });

  it('M04: client timeout after the write, then retry → one record with the same id', async () => {
    const { taskId, snap } = await prepared();
    const [feed, sleep] = drafts(snap);
    const first = await confirm(taskId, [{ draftId: feed!.id, revision: 1 }]);
    const retry = await confirm(taskId, [{ draftId: feed!.id, revision: 1 }]);
    expect(retry.data.items[0]!.recordId).toBe(first.data.items[0]!.recordId);
    // A crash after the record write but before the draft was marked: the record id is the
    // draft's, so the retry finds it and never writes a second one.
    const recordId = recordIdForDraft(sleep!.id);
    await db.doc(`babies/${B}/records/${recordId}`).set(
      buildCareRecord(
        {
          recordId,
          babyId: B,
          uid: MOM,
          member: { displayName: 'Mai', relation: 'mother', relationCustom: null },
          type: 'sleep',
          occurredAt: new Date(SLEEP_START),
          endedAt: new Date(SLEEP_END),
          data: {},
          clientCreatedAt: now,
        },
        FieldValue.serverTimestamp(),
      ),
    );
    const s = await confirm(taskId, [{ draftId: sleep!.id, revision: 1 }]);
    expect(s.data.items[0]).toMatchObject({ status: 'saved', recordId });
    expect(await assistantRecords()).toHaveLength(2);
  });

  it('M05: role revoked or child switched after preview → denied, nothing on either child', async () => {
    const { taskId, snap } = await prepared();
    const d = drafts(snap)[0]!;
    expect(
      await reason(
        confirm(taskId, [{ draftId: d.id, revision: 1 }], { scope: { type: 'child', babyId: NA } }),
      ),
    ).toBe('SCOPE_CHANGED');
    await db.doc(`babies/${B}/members/${MOM}`).update({
      role: 'relative',
      extraRights: { viewBabyInfo: false, viewDailyCare: true },
    });
    const r = await confirm(taskId, [{ draftId: d.id, revision: 1 }]);
    expect(r.data.items[0]).toMatchObject({ status: 'failed', errorCode: 'WRITE_DENIED' });
    expect(await recordDocs(B)).toHaveLength(0);
    expect(await recordDocs(NA)).toHaveLength(0);
    // The baby moved to another household after the preview: the scope changed.
    await db.doc(`babies/${B}/members/${MOM}`).update({ role: 'coParent' });
    await db.doc(`babies/${B}`).update({ familyId: F2 });
    expect(await reason(confirm(taskId, [{ draftId: d.id, revision: 1 }]))).toBe('SCOPE_CHANGED');
  });

  it('M09: consent withdrawn while the model runs → output dropped, released', async () => {
    const withdrawing = fakeModelGateway({
      extract: [
        async () => {
          await setAssistantConsent(deps(), MOM, E({ consent: null }));
          return textBatch();
        },
      ],
    });
    const r = await start(TEXT, { gw: withdrawing });
    await work(r.taskId!, withdrawing);
    const s = await snapshot(r.taskId!);
    expect(s.task).toMatchObject({
      state: 'failed',
      errorCode: 'CONSENT_REQUIRED',
      usage: 'released',
    });
    expect(s.drafts).toHaveLength(0);
    expect(await win()).toMatchObject({ used: 0, reserved: 0 });
  });

  it('M10: stale / expired / saved-then-edited-in-the-form: never overwritten', async () => {
    const { taskId, snap } = await prepared();
    const d = drafts(snap)[0]!;
    const saved = await confirm(taskId, [{ draftId: d.id, revision: 1 }]);
    const recordId = saved.data.items[0]!.recordId!;
    await db
      .doc(`babies/${B}/records/${recordId}`)
      .update({ 'data.amountMl': 130, updatedBy: DAD });
    const again = await confirm(taskId, [{ draftId: d.id, revision: 1 }]);
    expect(again.data.items[0]).toMatchObject({ status: 'saved', recordId });
    expect((await db.doc(`babies/${B}/records/${recordId}`).get()).get('data.amountMl')).toBe(130);
    expect(await reason(patch(d.id, 1, d.payload))).toBe('DRAFT_SAVED');
    expect(await reason(discardDraft(deps(), MOM, E({ draftId: d.id, expectedRevision: 1 })))).toBe(
      'DRAFT_SAVED',
    );
  });

  it('M11: events are ordered and unique; the snapshot after reconnect is authoritative', async () => {
    const { taskId, gw, snap } = await prepared();
    await confirm(taskId, [{ draftId: drafts(snap)[0]!.id, revision: 1 }]);
    await work(taskId, gw);
    const full = await snapshot(taskId);
    const seqs = full.events.map((e) => e.sequence);
    expect(seqs).toEqual(seqs.map((_, i) => i + 1));
    expect(new Set(full.events.map((e) => e.eventId)).size).toBe(seqs.length);
    expect(full.events.map((e) => e.type)).toEqual([
      'accepted',
      'progress',
      'drafts_ready',
      'usage_updated',
      'item_saved',
    ]);
    const tail = await snapshot(taskId, MOM, 3);
    expect(tail.events.map((e) => e.sequence)).toEqual([4, 5]);
    expect(tail.task.state).toBe('ready');
    expect(tail.drafts.map((d) => d.state)).toEqual(['saved', 'draft']);
  });

  it('M12: a task started before midnight stays in its month window when it settles after', async () => {
    const before = new Date('2026-10-31T16:59:00Z');
    const after = new Date('2026-10-31T17:01:00Z');
    const gw = fakeModelGateway({ extract: [textBatch(), textBatch()] });
    const r = await start(TEXT, { gw, at: before });
    await work(r.taskId!, gw, after);
    expect(await win('assistant_cal_2026-10')).toMatchObject({ used: 1, reserved: 0 });
    expect((await db.doc(`families/${F}/quota/assistant_cal_2026-11`).get()).exists).toBe(false);
    const r2 = await start(AGAIN, { gw, at: after });
    await work(r2.taskId!, gw, after);
    expect(await win('assistant_cal_2026-11')).toMatchObject({ used: 1, reserved: 0 });
    expect(await win('assistant_cal_2026-10')).toMatchObject({ used: 1, reserved: 0 });
  });
});

// =====================================================================================
describe('J: golden journeys', () => {
  it('J01: feed 120 → 150 saved once, sleep overlap conflict, retry only the sleep, 1 credit', async () => {
    await seedRecord(
      'r_' + 'b'.repeat(32),
      'sleep',
      '2026-10-15T02:30:00Z',
      {},
      '2026-10-15T03:30:00Z',
    );
    const { taskId, snap } = await prepared();
    const [feed, sleep] = drafts(snap);
    const p = await patch(feed!.id, 1, {
      ...(feed!.payload as DraftPayload & { kind: 'bottle' }),
      amountMl: 150,
    });
    const r1 = await confirm(taskId, [
      { draftId: feed!.id, revision: p.data.draft.revision },
      { draftId: sleep!.id, revision: 1 },
    ]);
    expect(r1.data).toMatchObject({ partial: true });
    expect(r1.data.items.map((i) => [i.status, i.errorCode])).toEqual([
      ['saved', null],
      ['conflict', 'DOMAIN_CONFLICT'],
    ]);
    const r2 = await confirm(taskId, [
      { draftId: sleep!.id, revision: 1, acknowledge: ['overlap'] },
    ]);
    expect(r2.data.items[0]!.status).toBe('saved');
    const feeds = (await assistantRecords()).filter((d) => d.get('type') === 'bottle');
    expect(feeds).toHaveLength(1);
    expect(feeds[0]!.get('data')).toEqual({ amountMl: 150, milk: 'breastMilk' });
    const rec = feeds[0]!.data();
    expect(Object.keys(rec).sort()).toEqual(
      [
        'id',
        'babyId',
        'type',
        'occurredAt',
        'endedAt',
        'data',
        'createdBy',
        'author',
        'createdAt',
        'clientCreatedAt',
        'updatedAt',
        'updatedBy',
        'deleted',
        'deletedAt',
        'deletedBy',
        'source',
      ].sort(),
    );
    expect(rec).toMatchObject({
      createdBy: MOM,
      updatedBy: MOM,
      author: { name: 'Mai', relation: 'mother', relationCustom: null },
      source: 'assistant',
      deleted: false,
    });
    expect((rec.occurredAt as Timestamp).toDate().toISOString()).toBe(
      FEED_AT.replace('Z', '.000Z'),
    );
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
    // The conversation shows one result card per confirm.
    const s = await snapshot(taskId);
    expect(s.messages.filter((m) => m.parts[0]?.type === 'action_result')).toHaveLength(2);
  });

  it('J02: summary — 390 ml bottle and 35 min nursing apart, 0 writes, 1 credit', async () => {
    await seedPackLogs();
    const before = (await recordDocs()).length;
    const { snap } = await prepared([summaryAsk()], 'Hôm nay con bú thế nào?');
    const summary = snap.messages.at(-1)!.parts.find((p) => p.type === 'source_summary') as Extract<
      AssistantPart,
      { type: 'source_summary' }
    >;
    expect(summary.summary).toMatchObject({
      bottle: { count: 3, ml: 390 },
      breast: { count: 2, minutes: 35 },
    });
    expect(summary.sourceIds).toHaveLength(5);
    expect(snap.drafts).toHaveLength(0);
    expect(await recordDocs()).toHaveLength(before);
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
  });

  it('J10: the viewer reads but never writes; health support is free at quota 0', async () => {
    await setFreeLimit(2);
    await seedPackLogs();
    const read = await prepared([summaryAsk()], 'Hôm nay con bú thế nào?', { uid: AUNT });
    expect(read.snap.task.state).toBe('ready');
    const mom = await prepared();
    expect(
      await reason(
        confirm(mom.taskId, [{ draftId: drafts(mom.snap)[0]!.id, revision: 1 }], { uid: AUNT }),
      ),
    ).toBe('NOT_MEMBER');
    expect((await getAssistantUsage(deps(), AUNT, E({ babyId: B }))).data.remaining).toBe(0);
    const h = await start('My baby is having a seizure', { uid: AUNT });
    expect(h.data.task).toMatchObject({ state: 'ready', credits: 0 });
    expect((await snapshot(h.taskId!, AUNT)).messages.at(-1)!.parts[0]).toMatchObject({
      type: 'health_support',
      signs: ['seizure'],
    });
    expect(await win()).toMatchObject({ used: 2, reserved: 0 });
    expect((await recordDocs()).filter((d) => d.get('source') === 'assistant')).toHaveLength(0);
  });
});

// =====================================================================================
describe('writers: check-ins, nursing, budgets, consent', () => {
  it('observation → the app’s check-in (revision 1, confirmer as author); same day again → conflict', async () => {
    const obs = () =>
      extraction([
        intent('observation', { observation: 'sleep', when: 'night', dayOffset: -1 }, [
          { field: 'observation', text: 'khó ngủ' },
          { field: 'dayOffset', text: 'Tối qua' },
        ]),
      ]);
    const a = await prepared([obs()], 'Tối qua bé khó ngủ');
    const d = drafts(a.snap)[0]!;
    expect(d.payload).toEqual({
      kind: 'observation',
      observation: 'sleep',
      date: '2026-10-14',
      when: 'night',
      note: null,
    });
    const r = await confirm(a.taskId, [{ draftId: d.id, revision: 1 }]);
    expect(r.data.items[0]).toMatchObject({ status: 'saved' });
    const ci = (await db.doc(`babies/${B}/checkins/${r.data.items[0]!.recordId}`).get()).data()!;
    expect(Object.keys(ci).sort()).toEqual(
      [
        'id',
        'babyId',
        'date',
        'authorUid',
        'observation',
        'when',
        'since',
        'tried',
        'healthSigns',
        'note',
        'revision',
        'createdAt',
        'updatedAt',
      ].sort(),
    );
    expect(ci).toMatchObject({
      authorUid: MOM,
      revision: 1,
      since: null,
      tried: [],
      healthSigns: [],
    });
    const b = await prepared([obs()], 'Tối qua bé khó ngủ');
    const again = await confirm(b.taskId, [{ draftId: drafts(b.snap)[0]!.id, revision: 1 }]);
    expect(again.data.items[0]).toMatchObject({ status: 'conflict', errorCode: 'DOMAIN_CONFLICT' });
    expect((await db.collection(`babies/${B}/checkins`).get()).size).toBe(1);
  });

  it('nursing is minutes and a side, never ml; a side not said takes the form default (never blocks)', async () => {
    const br = (side: string | null) =>
      extraction([
        intent('breast', { time: '07:30', dayOffset: 0, durationMin: 20, side }, [
          { field: 'durationMin', text: '20 phút' },
          { field: 'time', text: '7 giờ 30 sáng' },
        ]),
      ]);
    const a = await prepared([br('left')], 'Bú mẹ bên trái 20 phút lúc 7 giờ 30 sáng');
    const r = await confirm(a.taskId, [{ draftId: drafts(a.snap)[0]!.id, revision: 1 }]);
    expect(r.data.items[0]!.status).toBe('saved');
    const rec = (await assistantRecords())[0]!;
    expect(rec.get('type')).toBe('breast');
    expect(rec.get('data')).toEqual({ side: 'left', durationMin: 20 });
    // Lumi 2026-10-16: like the form ("bên còn lại"): the last feed was on the left → right.
    const b = await prepared([br(null)], 'Bú mẹ 20 phút lúc 7 giờ 30 sáng');
    expect(drafts(b.snap)[0]).toMatchObject({ state: 'draft', missingFields: [] });
    expect(drafts(b.snap)[0]!.payload).toMatchObject({ side: 'right' });
  });

  it('a caregiver saves care drafts; a relative never does', async () => {
    const n = await prepared([textBatch()], TEXT, { uid: NANNY });
    const r = await confirm(n.taskId, [{ draftId: drafts(n.snap)[0]!.id, revision: 1 }], {
      uid: NANNY,
    });
    expect(r.data.items[0]!.status).toBe('saved');
    expect((await assistantRecords())[0]!.get('author')).toEqual({
      name: 'Cô Hoa',
      relation: 'nanny',
      relationCustom: null,
    });
  });

  it('the monthly AI budget spent → blocked AI_UNAVAILABLE before reserving', async () => {
    await db.doc('config/ai').set({ monthlyBudgetVnd: 1000, month: '2026-10', spentVnd: 1000 });
    expect((await quote()).reason).toBe('AI_UNAVAILABLE');
    expect(await start(TEXT)).toMatchObject({ status: 'blocked', reasonCode: 'AI_UNAVAILABLE' });
    expect(await opsDocs()).toHaveLength(0);
    await db.doc('config/ai').delete();
  });

  it('a promo grant giving Premium uses the premium pool for its period', async () => {
    await db.doc(`families/${F}/grants/promo_test`).set({
      familyId: F,
      source: 'promo',
      status: 'active',
      environment: 'test',
      capabilities: [...premiumCapabilities],
      validFrom: Timestamp.fromDate(new Date('2026-10-01T00:00:00Z')),
      validUntil: Timestamp.fromDate(new Date('2026-12-01T00:00:00Z')),
      billingOwnerUid: null,
      provider: 'staff',
      sourceRef: null,
      campaignId: 'audit_test',
      autoRenew: null,
      updatedAt: Timestamp.fromDate(now),
    });
    const u = (await getAssistantUsage(deps(), MOM, E({ babyId: B }))).data;
    expect(u).toMatchObject({ plan: 'premium', limit: 200, remaining: 200 });
    await prepared();
    expect(await win('assistant_paid_promo_test_2026-10-01')).toMatchObject({ used: 1 });
  });

  it('summaries consent and assistant consent live side by side on users/{uid}/settings/ai', async () => {
    await setAiConsent(
      db,
      MOM,
      { consent: { version: 'ai-consent-v1', shareMyNotes: false } },
      now,
    );
    const doc = (await db.doc(`users/${MOM}/settings/ai`).get()).data()!;
    expect(doc.assistant).toMatchObject({ version: assistantConsentVersion });
    expect(doc.consent).toMatchObject({ version: 'ai-consent-v1', shareMyNotes: false });
    await setAssistantConsent(deps(), MOM, E({ consent: null }));
    const after = (await db.doc(`users/${MOM}/settings/ai`).get()).data()!;
    expect(after.consent).toMatchObject({ version: 'ai-consent-v1' });
    expect(after.assistant).toBeNull();
  });
});

// =====================================================================================
describe('feedback, history, deletion, sweeper', () => {
  it('feedback: 0 credits, the module’s recFeedback document; "Chưa thử" records nothing', async () => {
    const { taskId } = await prepared();
    const fb = await submitAssistantFeedback(
      deps(),
      MOM,
      E({ taskId, contentId: 'act_test_sleep', contentVersion: 1, outcome: 'helpful' }),
    );
    const doc = (await db.doc(`babies/${B}/recFeedback/${fb.data.feedbackId}`).get()).data()!;
    expect(Object.keys(doc).sort()).toEqual(
      [
        'id',
        'babyId',
        'authorUid',
        'contentId',
        'contentVersion',
        'kind',
        'date',
        'note',
        'createdAt',
      ].sort(),
    );
    expect(doc).toMatchObject({ authorUid: MOM, kind: 'helpful', date: '2026-10-15', note: null });
    expect(
      await reason(
        submitAssistantFeedback(
          deps(),
          MOM,
          E({ taskId, contentId: 'act_test_sleep', contentVersion: 1, outcome: 'unsure' }),
        ),
      ),
    ).toBe('DOMAIN_CONFLICT');
    const nt = await submitAssistantFeedback(
      deps(),
      MOM,
      E({ taskId, contentId: 'act_test_sleep', contentVersion: 1, outcome: 'not_tried' }),
    );
    expect(nt.data.feedbackId).toBeNull();
    expect(
      await reason(
        submitAssistantFeedback(
          deps(),
          MOM,
          E({ taskId, contentId: 'act_test_unknown', contentVersion: 1, outcome: 'helpful' }),
        ),
      ),
    ).toBe('VALIDATION_FAILED');
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
    const aunt = await prepared([summaryAsk()], 'Hôm nay con bú thế nào?', { uid: AUNT });
    expect(
      await reason(
        submitAssistantFeedback(
          deps(),
          AUNT,
          E({
            taskId: aunt.taskId,
            contentId: 'act_test_sleep',
            contentVersion: 1,
            outcome: 'helpful',
          }),
        ),
      ),
    ).toBe('WRITE_DENIED');
  });

  it('history: the shared thread first, then own private ones; messages paged by sequence', async () => {
    const a = await prepared();
    const SHARED = `cv_${B}`;
    expect(a.snap.task.conversationId).toBe(SHARED);
    const h = await prepared([summaryAsk()], 'Hôm nay con bú thế nào?', {
      at: new Date(now.getTime() + 60_000),
      scope: { type: 'household', babyId: B },
    });
    await prepared([summaryAsk()], 'Hôm nay con bú thế nào?', { uid: DAD });
    // DAD's private household thread is never listed for MOM.
    await prepared([summaryAsk()], 'Hôm nay con bú thế nào?', {
      uid: DAD,
      scope: { type: 'household', babyId: B },
    });
    const page = await listAssistantHistory(
      deps(),
      MOM,
      E({ babyId: B, conversationId: null, cursor: null, limit: 1 }),
    );
    expect(page.data.items.map((c) => (c as { id: string }).id)).toEqual([SHARED]);
    expect(page.data.items[0]).toMatchObject({ shared: true, ownerUid: null });
    expect(page.data.nextCursor).toBe('private');
    const page2 = await listAssistantHistory(
      deps(),
      MOM,
      E({ babyId: B, conversationId: null, cursor: page.data.nextCursor, limit: 5 }),
    );
    expect(page2.data.items.map((c) => (c as { id: string }).id)).toEqual([
      h.snap.task.conversationId,
    ]);
    expect(page2.data.nextCursor).toBeNull();
    // Messages of the shared thread: MOM's question + answer, then DAD's (4), newest first.
    const msgs = await listAssistantHistory(
      deps(),
      MOM,
      E({ babyId: B, conversationId: SHARED, cursor: null, limit: 1 }),
    );
    expect(msgs.data.items.map((m) => (m as { sequence: number }).sequence)).toEqual([4]);
    const older = await listAssistantHistory(
      deps(),
      MOM,
      E({ babyId: B, conversationId: SHARED, cursor: msgs.data.nextCursor, limit: 5 }),
    );
    expect(older.data.items.map((m) => (m as { sequence: number }).sequence)).toEqual([3, 2, 1]);
    expect(
      await reason(
        listAssistantHistory(
          deps(),
          DAD,
          E({ babyId: B, conversationId: h.snap.task.conversationId, cursor: null, limit: 5 }),
        ),
      ),
    ).toBe('NOT_MEMBER');
  });

  it('delete conversation: chat, tasks and drafts go; saved records stay; open work released', async () => {
    const { taskId, snap } = await prepared();
    await confirm(taskId, [{ draftId: drafts(snap)[0]!.id, revision: 1 }]);
    const open = await start(AGAIN, { conversationId: snap.task.conversationId, uid: DAD });
    expect(await win()).toMatchObject({ used: 1, reserved: 1 });
    // D-075 #2: the shared thread is deleted by a Cùng nuôi only, for everyone.
    expect(
      await reason(
        deleteAssistantConversation(
          deps(),
          NANNY,
          E({ conversationId: snap.task.conversationId, confirm: true }),
        ),
      ),
    ).toBe('WRITE_DENIED');
    const del = await deleteAssistantConversation(
      deps(),
      MOM,
      E({ conversationId: snap.task.conversationId, confirm: true }),
    );
    expect(del.data).toEqual({ deletedTasks: 2, domainRecordsKept: true });
    expect((await db.doc(`assistantTasks/${taskId}`).get()).exists).toBe(false);
    expect((await db.doc(`assistantTasks/${open.taskId}`).get()).exists).toBe(false);
    expect(
      (await db.collection(`assistantConversations/${snap.task.conversationId}/messages`).get())
        .size,
    ).toBe(0);
    expect(await assistantRecords()).toHaveLength(1);
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
    expect(
      await reason(
        deleteAssistantConversation(deps(), MOM, E({ conversationId: 'x', confirm: false })),
      ),
    ).toBe('VALIDATION_FAILED');
  });

  it('sweeper: a dead worker’s task is requeued then run once; an unanswered clarification expires released', async () => {
    const gw = fakeModelGateway({ extract: [textBatch()] });
    const r = await start(TEXT, { gw });
    await db.doc(`assistantTasks/${r.taskId}`).update({
      state: 'processing',
      lease: { holder: 'dead', until: Timestamp.fromDate(now) },
      attempt: 1,
    });
    const later = new Date(now.getTime() + 60_000);
    expect((await sweepAssistantTasks(db, later)).requeued).toBe(1);
    await work(r.taskId!, gw, later);
    expect((await snapshot(r.taskId!)).task.state).toBe('ready');

    const c = await prepared([clarifyAsk()], AGAIN);
    expect(c.snap.task.state).toBe('awaiting_clarification');
    const late = new Date(now.getTime() + 31 * 60_000);
    expect((await sweepAssistantTasks(db, late)).expired).toBe(1);
    expect((await snapshot(c.taskId)).task).toMatchObject({
      state: 'failed',
      errorCode: 'QUOTE_EXPIRED',
    });
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
  });

  it('usage "Gần đây": newest credit lines with kind, state and author, never content', async () => {
    await prepared();
    await start('9 giờ con bú 100 ml', { gw: fakeModelGateway({ extract: [textBatch()] }) });
    const u = (await getAssistantUsage(deps(), MOM, E({ babyId: B }))).data;
    expect(u.recent).toHaveLength(2);
    expect(u.recent!.map((r) => [r.kind, r.state, r.credits])).toEqual(
      expect.arrayContaining([
        ['text', 'committed', 1],
        ['text', 'reserved', 1],
      ]),
    );
    expect(u.recent!.every((r) => typeof r.who === 'string' && r.who.length > 0)).toBe(true);
    expect(JSON.stringify(u.recent)).not.toMatch(/bú|ml/);
  });

  it('sweeper: a task left queued is nudged three times, then failed with its credits released', async () => {
    const r = await start(TEXT, { gw: fakeModelGateway({ extract: [textBatch()] }) });
    expect(await win()).toMatchObject({ reserved: 1 });
    let at = now;
    for (let i = 0; i < 3; i++) {
      at = new Date(at.getTime() + 11 * 60_000);
      expect((await sweepAssistantTasks(db, at)).requeued).toBe(1);
      expect((await snapshot(r.taskId!)).task.state).toBe('queued');
    }
    // Nudged a minute ago: not stuck yet.
    expect((await sweepAssistantTasks(db, new Date(at.getTime() + 60_000))).requeued).toBe(0);
    at = new Date(at.getTime() + 11 * 60_000);
    expect((await sweepAssistantTasks(db, at)).requeued).toBe(1);
    expect((await snapshot(r.taskId!)).task).toMatchObject({
      state: 'failed',
      errorCode: 'AI_UNAVAILABLE',
    });
    expect(await win()).toMatchObject({ used: 0, reserved: 0 });
  });
});

// =====================================================================================
// D-075: one credit pool with a Premium budget from any grant (#1); one shared conversation per
// baby for Cùng nuôi and Người chăm sóc, spending excluded (#2).
describe('D-075 #1: credit budgets', () => {
  it('Free is 20; a beta campaign giving the Premium budget makes it 200 (monthly, its own window)', async () => {
    const free = (await getAssistantUsage(deps(), MOM, E({ babyId: B }))).data;
    expect(free).toMatchObject({ plan: 'free', limit: 20, remaining: 20 });
    await db.doc('config/entitlements').set(
      {
        betaCampaigns: [
          {
            id: 'beta-all',
            capabilities: [...premiumCapabilities],
            validFrom: '2026-09-01T00:00:00Z',
            validUntil: '2026-12-01T00:00:00Z',
            countries: [],
            scope: 'all',
            percent: 100,
          },
        ],
      },
      { merge: true },
    );
    const beta = (await getAssistantUsage(deps(), MOM, E({ babyId: B }))).data;
    expect(beta).toMatchObject({ plan: 'premium', limit: 200, remaining: 200 });
    // The beta window resets with the household month, not at the end of the campaign.
    expect(beta.resetsAt).toBe('2026-10-31T17:00:00.000Z');
    await prepared();
    expect(await win('assistant_paid_campaign-beta-all_2026-09-30')).toMatchObject({
      used: 1,
      limit: 200,
    });
    expect(await win()).toMatchObject({ used: 0 });
    // A beta with group A only keeps the Free budget.
    await db.doc('config/entitlements').set(
      {
        betaCampaigns: [
          {
            id: 'beta-a',
            capabilities: ['personalization.cross_module', 'rhythm.advanced', 'ai.assistance'],
            validFrom: '2026-09-01T00:00:00Z',
            validUntil: '2026-12-01T00:00:00Z',
            countries: [],
            scope: 'all',
            percent: 100,
          },
        ],
      },
      { merge: true },
    );
    expect((await getAssistantUsage(deps(), MOM, E({ babyId: B }))).data).toMatchObject({
      plan: 'free',
      limit: 20,
    });
  });
});

describe('D-075 #2: one shared conversation per baby, spending excluded', () => {
  const SHARED = `cv_${B}`;
  const mom = { uid: MOM, name: 'Mai', relation: 'mother', relationCustom: null };
  const nanny = { uid: NANNY, name: 'Cô Hoa', relation: 'nanny', relationCustom: null };

  /** A synthetic expense draft (as a receipt reading leaves it) on [taskId]. */
  async function seedExpenseDraft(taskId: string, scope: { type: string; babyId: string }) {
    const id = `dr_${taskId.slice(3)}_0`;
    await db.doc(`assistantTasks/${taskId}/drafts/${id}`).set({
      id,
      taskId,
      ownerUid: MOM,
      itemIndex: 0,
      scope,
      payload: {
        kind: 'expense',
        merchant: 'Test Mart',
        totalMinor: 120_000,
        currency: 'VND',
        date: '2026-10-15',
        subtotalMinor: null,
        taxMinor: null,
        categoryId: null,
        babyId: B,
        keepReceipt: false,
      },
      missingFields: [],
      uncertainFields: [],
      revision: 1,
      state: 'draft',
      expiresAt: Timestamp.fromMillis(now.getTime() + 3_600_000),
      sourceRefs: [],
      recordId: null,
      recordLink: null,
      errorCode: null,
      warnings: [],
      createdAt: Timestamp.fromDate(now),
      updatedAt: Timestamp.fromDate(now),
    });
    return id;
  }

  it('a child text task joins the shared thread with its author; Cùng nuôi and caregiver read it, relatives never', async () => {
    const a = await prepared();
    expect(a.snap.task).toMatchObject({
      conversationId: SHARED,
      visibility: 'shared',
      author: mom,
    });
    expect(a.snap.messages[0]).toMatchObject({ role: 'user', author: mom });
    expect(a.snap.messages.at(-1)).toMatchObject({ role: 'assistant', author: null });
    const conv = (await db.doc(`assistantConversations/${SHARED}`).get()).data()!;
    expect(conv).toMatchObject({ shared: true, ownerUid: null, createdBy: MOM });
    for (const uid of [DAD, NANNY]) {
      const s = await snapshot(a.taskId, uid);
      expect(s.task.author).toEqual(mom);
      expect(s.drafts).toHaveLength(2);
    }
    for (const uid of [AUNT, GRANDMA, STRANGER]) {
      expect(
        await reason(getAssistantTask(deps(), uid, E({ taskId: a.taskId, afterSequence: null }))),
      ).toBe('NOT_MEMBER');
    }
    // The caregiver writes into the same thread.
    const n = await prepared([summaryAsk()], 'Hôm nay con bú thế nào?', { uid: NANNY });
    expect(n.snap.task).toMatchObject({ conversationId: SHARED, author: nanny });
    const msgs = await listAssistantHistory(
      deps(),
      DAD,
      E({ babyId: B, conversationId: SHARED, cursor: null, limit: 10 }),
    );
    expect(
      (msgs.data.items as { role: string; author: { uid: string } | null }[])
        .filter((m) => m.role === 'user')
        .map((m) => m.author?.uid),
    ).toEqual([NANNY, MOM]);
    // A relative's own task stays private (their thread), and the shared thread is not listed.
    const r = await prepared([summaryAsk()], 'Hôm nay con bú thế nào?', { uid: AUNT });
    expect(r.snap.task.visibility).toBe('private');
    expect(r.snap.task.conversationId).not.toBe(SHARED);
    const auntList = await listAssistantHistory(
      deps(),
      AUNT,
      E({ babyId: B, conversationId: null, cursor: null, limit: 10 }),
    );
    expect(auntList.data.items.map((c) => (c as { id: string }).id)).toEqual([
      r.snap.task.conversationId,
    ]);
    expect(
      await reason(
        listAssistantHistory(
          deps(),
          AUNT,
          E({ babyId: B, conversationId: SHARED, cursor: null, limit: 10 }),
        ),
      ),
    ).toBe('NOT_MEMBER');
    expect(await reason(quote(AUNT, { conversationId: SHARED }))).toBe('NOT_MEMBER');
  });

  it('a caregiver confirms a shared care draft (as the confirmer); never an expense, never a private task', async () => {
    const a = await prepared();
    const d = drafts(a.snap)[0]!;
    const r = await confirm(a.taskId, [{ draftId: d.id, revision: 1 }], { uid: NANNY });
    expect(r.data.items[0]!.status).toBe('saved');
    const rec = (await assistantRecords())[0]!;
    expect(rec.get('createdBy')).toBe(NANNY);
    expect(rec.get('author')).toEqual({ name: 'Cô Hoa', relation: 'nanny', relationCustom: null });
    const after = await snapshot(a.taskId, MOM);
    expect(after.drafts[0]).toMatchObject({ state: 'saved', confirmedBy: nanny });
    expect(after.messages.at(-1)).toMatchObject({ author: nanny });
    expect(after.messages.at(-1)!.parts[0]!.type).toBe('action_result');
    // A relative can never confirm or edit a shared draft.
    const sleepDraft = drafts(a.snap)[1]!;
    expect(
      await reason(confirm(a.taskId, [{ draftId: sleepDraft.id, revision: 1 }], { uid: GRANDMA })),
    ).toBe('NOT_MEMBER');

    // Spending stays private: a household task and an expense-hinted child task.
    const h = await start('Chi tiêu tuần này', { scope: { type: 'household', babyId: B } });
    const q = await quote(MOM, { intentHint: 'expense' });
    const x = await start('Chi tiêu tuần này', { quoteId: q.quoteId });
    for (const t of [h, x]) {
      const snap = await snapshot(t.taskId!, MOM);
      expect(snap.task.visibility).toBe('private');
      expect(snap.task.conversationId).not.toBe(SHARED);
      const draftId = await seedExpenseDraft(t.taskId!, snap.task.scope);
      for (const uid of [NANNY, DAD]) {
        expect(
          await reason(getAssistantTask(deps(), uid, E({ taskId: t.taskId, afterSequence: null }))),
        ).toBe('NOT_MEMBER');
        expect(await reason(confirm(t.taskId!, [{ draftId, revision: 1 }], { uid }))).toBe(
          'NOT_MEMBER',
        );
      }
    }
    // Nothing of them reached the shared thread.
    const shared = await db.collection(`assistantConversations/${SHARED}/messages`).get();
    expect(shared.docs.map((m) => m.get('taskId'))).not.toContain(h.taskId);
    expect(shared.docs.map((m) => m.get('taskId'))).not.toContain(x.taskId);
    // Defence in depth: an expense draft on a shared task is refused to a caregiver.
    const s2 = await prepared([textBatch()], TEXT, { uid: DAD });
    const ex = await seedExpenseDraft(s2.taskId, SCOPE);
    const res = await confirm(s2.taskId, [{ draftId: ex, revision: 1 }], { uid: NANNY });
    expect(res.data.items[0]).toMatchObject({ status: 'failed', errorCode: 'WRITE_DENIED' });
  });

  it('a thread from before D-075 stays readable by its owner; new messages go to the shared thread', async () => {
    const LEGACY = 'cv_00000000000000000000000000000abc';
    await db.doc(`assistantConversations/${LEGACY}`).set({
      id: LEGACY,
      ownerUid: MOM,
      familyId: F,
      scope: SCOPE,
      title: null,
      locale: 'vi',
      createdAt: Timestamp.fromDate(new Date(now.getTime() - 86_400_000)),
      updatedAt: Timestamp.fromDate(new Date(now.getTime() - 86_400_000)),
      archivedAt: null,
      messageSeq: 1,
      lastTaskId: null,
    });
    await db.doc(`assistantConversations/${LEGACY}/messages/00000001`).set({
      conversationId: LEGACY,
      role: 'user',
      parts: [{ type: 'text', schemaVersion: 1, text: 'test' }],
      taskId: null,
      sequence: 1,
      createdAt: Timestamp.fromDate(now),
      attachmentIds: [],
    });
    const r = await start(TEXT, { conversationId: LEGACY });
    expect(r.data.task).toMatchObject({ conversationId: SHARED, visibility: 'shared' });
    const old = await listAssistantHistory(
      deps(),
      MOM,
      E({ babyId: B, conversationId: LEGACY, cursor: null, limit: 5 }),
    );
    expect(old.data.items).toHaveLength(1);
    expect(old.data.items[0]).toMatchObject({ author: null });
    const list = await listAssistantHistory(
      deps(),
      MOM,
      E({ babyId: B, conversationId: null, cursor: null, limit: 5 }),
    );
    expect(list.data.items.map((c) => (c as { id: string }).id)).toEqual([SHARED, LEGACY]);
    expect(
      await reason(
        listAssistantHistory(
          deps(),
          DAD,
          E({ babyId: B, conversationId: LEGACY, cursor: null, limit: 5 }),
        ),
      ),
    ).toBe('NOT_MEMBER');
  });

  it('a shared draft is edited only by members who may save it; clarifications stay with the author', async () => {
    const a = await prepared();
    const d = drafts(a.snap)[0]!;
    const edited = await patchDraft(
      deps(),
      NANNY,
      E({
        draftId: d.id,
        expectedRevision: 1,
        payload: { ...(d.payload as Extract<DraftPayload, { kind: 'bottle' }>), amountMl: 150 },
        confirmedFields: [],
      }),
    );
    expect(edited.data.draft.revision).toBe(2);
    expect(
      await reason(
        patchDraft(
          deps(),
          AUNT,
          E({ draftId: d.id, expectedRevision: 2, payload: d.payload, confirmedFields: [] }),
        ),
      ),
    ).toBe('NOT_MEMBER');
    expect(await reason(cancelTask(deps(null), NANNY, E({ taskId: a.taskId })))).toBe('NOT_MEMBER');
  });

  it('account deletion removes that person’s messages from the shared thread; the thread stays', async () => {
    await prepared();
    await prepared([summaryAsk()], 'Hôm nay con bú thế nào?', { uid: DAD });
    await purgeAssistantForUser(db, { deletePrefix: async () => undefined }, DAD, now);
    const left = await db.collection(`assistantConversations/${SHARED}/messages`).get();
    expect(left.size).toBe(2);
    expect(left.docs.every((m) => m.get('author') === null || m.get('author').uid === MOM)).toBe(
      true,
    );
    expect((await db.doc(`assistantConversations/${SHARED}`).get()).exists).toBe(true);
  });
});
