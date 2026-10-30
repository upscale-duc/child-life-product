import { randomUUID } from 'node:crypto';
import {
  assistantConsentVersion,
  defaultEntitlementsConfig,
  defaultFlags,
  draftKinds,
} from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  deleteAssistantConversation,
  setAssistantConsent,
  startTask,
  type AssistantDeps,
} from '../functions/src/assistant.js';
import { fakeModelGateway, type ModelGateway } from '../functions/src/assistant-model.js';

// Lumi L10 (lumi-plan §13.2 A1, A2, A5, A6, P2 order) against the Firestore emulator: an answer
// routed from `startTask` replays as that answer, runs under one request's budget and timer, a
// long text or a raced question reads as a new message, the dialogue doc keeps chip ids only and
// goes with the conversation, and "huỷ" cancels my question only once its start is recorded.
// Synthetic `test_` data only.
const projectId = 'demo-child-life-assistant-l10';
let app: App;
let db: Firestore;

const ZONE = 'Asia/Ho_Chi_Minh';
/** 14:20 in Vietnam on Thursday 2026-10-15. */
const NOW = new Date('2026-10-15T07:20:00Z');
const F = 'test_sf';
const B = 'test_sb';
const MOM = 'test_smom';
const SCOPE = { type: 'child' as const, babyId: B };
const SHARED = `cv_${B}`;

const E = (over: Record<string, unknown> = {}) => ({
  contractVersion: 1,
  clientRequestId: randomUUID(),
  locale: 'vi',
  clientDraftKinds: [...draftKinds],
  ...over,
});
const deps = (
  gateway: ModelGateway | null = fakeModelGateway({}),
  over: Partial<AssistantDeps> = {},
) => ({ db, now: NOW, environment: 'test', gateway, ...over }) as AssistantDeps;
const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason ?? String(e),
  );
const start = (
  text: string,
  gw: ModelGateway | null,
  over: Partial<AssistantDeps> = {},
  extra = {},
) =>
  startTask(
    deps(gw, over),
    MOM,
    E({ conversationId: SHARED, scope: SCOPE, text, attachmentIds: [], ...extra }),
  );

const on = (key: keyof typeof defaultFlags) => ({
  ...defaultFlags[key],
  enabled: true,
  scope: 'all' as const,
});
const member = (role: string, relation: string, displayName: string, extra = {}) => ({
  role,
  status: 'active',
  relation,
  relationCustom: null,
  displayName,
  ...extra,
});

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

beforeAll(() => {
  app = initializeApp({ projectId }, `assistant-l10-${randomUUID()}`);
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
  await setFreeLimit(30);
  await db.doc(`babies/${B}`).set({
    familyId: F,
    timeZone: { mode: 'auto', zone: ZONE },
    state: 'active',
  });
  await db.doc(`families/${F}`).set({ ownerUid: MOM, country: 'VN', timeZone: ZONE, babyIds: [B] });
  await db
    .doc(`babies/${B}/members/${MOM}`)
    .set(member('coParent', 'mother', 'Mai', { isOwner: true }));
  await setAssistantConsent(deps(), MOM, E({ consent: { version: assistantConsentVersion } }));
});

const dialogueOf = async () =>
  (await db.doc(`assistantConversations/${SHARED}/dialogue/${MOM}`).get()).data();
const taskCount = async () => (await db.collection('assistantTasks').get()).size;

describe('L10: an answer routed from startTask', () => {
  it('A1: the retry of the same request is that answer again — never a new task', async () => {
    const gw = fakeModelGateway({});
    const q = await start('sáng nay bé bú 120ml', gw);
    expect(q.data.task.clarification?.field).toBe('time.missing');
    const id = randomUUID();
    const a = await start('8h sáng', gw, {}, { clientRequestId: id });
    expect(a.taskId).toBe(q.taskId);
    expect(a.data.drafts[0]!.payload).toMatchObject({ kind: 'bottle', amountMl: 120 });
    const tasks = await taskCount();
    // The phone timed out and sends the same request again.
    const again = await start('8h sáng', gw, {}, { clientRequestId: id });
    expect(again.taskId).toBe(q.taskId);
    expect(again.data.task.state).toBe(a.data.task.state);
    expect(again.data.usage).toBeDefined();
    expect(await taskCount()).toBe(tasks);
    const users = again.data.messages.filter((m) => m.role === 'user');
    expect(users).toHaveLength(2);
  });

  it('A2: the routed answer runs under the request’s own start and timer (one timing line)', async () => {
    const lines: Record<string, unknown>[] = [];
    const gw = fakeModelGateway({});
    const q = await start('sáng nay bé bú 120ml', gw);
    await start('8h sáng', gw, { onTiming: (p) => lines.push(p) });
    expect(lines).toHaveLength(1);
    expect(lines[0]).toMatchObject({ op: 'startTask', taskId: q.taskId, path: 'answer' });
    expect(Object.keys(lines[0]!.hops as object)).toEqual(
      expect.arrayContaining(['scope', 'work']),
    );
  });

  it('A5: words longer than an answer may be read as a message of their own (no VALIDATION_FAILED)', async () => {
    const gw = fakeModelGateway({});
    const q = await start('sáng nay bé bú 120ml', gw);
    const long = `8h sáng nhé, ${'bé ngoan lắm, '.repeat(16)}`.trim();
    expect(long.length).toBeGreaterThan(200);
    const r = await start(long, gw);
    expect(r.taskId).not.toBe(q.taskId);
    const left = await db.doc(`assistantTasks/${q.taskId}`).get();
    expect(left.get('state')).toBe('awaiting_clarification');
  });
});

describe('L10 A6: the dialogue doc', () => {
  it('keeps the chips by id only, and goes with "Xoá cuộc trò chuyện"', async () => {
    const q = await start('sáng nay bé bú 120ml', fakeModelGateway({}));
    const d = await dialogueOf();
    expect(d?.state.question).toMatchObject({ taskId: q.taskId, field: 'time.missing' });
    expect(d?.state.question.choiceIds).toEqual(
      q.data.task.clarification!.choices.map((c) => c.id),
    );
    expect(d?.state.question.chips).toBeUndefined();
    expect(JSON.stringify(d)).not.toMatch(/Vừa xong|phút trước|tiếng trước/u);
    expect(d?.ttlAt).toBeDefined();
    await deleteAssistantConversation(deps(), MOM, E({ conversationId: SHARED, confirm: true }));
    expect(await dialogueOf()).toBeUndefined();
  });
});

describe('L10: "huỷ" while my question waits', () => {
  it('cancels the question only once the new task is recorded (a failed start leaves it open)', async () => {
    const gw = fakeModelGateway({});
    const id = randomUUID();
    const q = await start('sáng nay bé bú 120ml', gw, {}, { clientRequestId: id });
    // The same request id with other words: the start transaction refuses it.
    expect(await reason(start('huỷ', gw, {}, { clientRequestId: id }))).toBe(
      'IDEMPOTENCY_CONFLICT',
    );
    expect((await db.doc(`assistantTasks/${q.taskId}`).get()).get('state')).toBe(
      'awaiting_clarification',
    );
    const r = await start('huỷ', gw);
    expect(r.taskId).not.toBe(q.taskId);
    expect((await db.doc(`assistantTasks/${q.taskId}`).get()).get('state')).toBe('canceled');
  });
});
