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
  getAssistantTask,
  getAssistantUsage,
  quoteTask,
  setAssistantConsent,
  startTask,
  submitClarification,
  type AssistantDeps,
} from '../functions/src/assistant.js';
import {
  fakeModelGateway,
  type ExtractInput,
  type FakeStep,
  type ModelGateway,
} from '../functions/src/assistant-model.js';
import { ruleReadText } from '../functions/src/assistant-rules.js';
import { runAssistantTask } from '../functions/src/assistant-worker.js';

// Lumi L2 (D-088 §4.4, P-167 #4 / #9) against the Firestore emulator: text without a quote, the
// rule reader before the model (0 credits, no model, listed as "0 lượt · không tính"), the worker
// inside `startTask` / `submitClarification` with the whole snapshot in the answer, and the hand-off
// to the trigger when the model would outlast the phone's wait. Synthetic `test_` data only.
const projectId = 'demo-child-life-assistant-speed';
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
const WIN = 'assistant_cal_2026-10';

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
const win = async () =>
  (await db.doc(`families/${F}/quota/${WIN}`).get()).data() ?? { used: 0, reserved: 0 };
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

/** What a correct model returns for "8h bú 120ml, 11h bú 150ml" (two bottles: the model's). */
const twoBottles = () => {
  const one = ruleReadText({ text: 'bé bú 120ml lúc 8h', zone: ZONE, anchor: NOW })!.intents[0]!;
  const two = ruleReadText({ text: 'bé bú 150ml lúc 11h', zone: ZONE, anchor: NOW })!.intents[0]!;
  return {
    intents: [
      {
        ...one,
        evidence: [
          { field: 'amountMl', text: '120ml' },
          { field: 'time', text: '8h' },
        ],
      },
      {
        ...two,
        evidence: [
          { field: 'amountMl', text: '150ml' },
          { field: 'time', text: '11h' },
        ],
      },
    ],
    reads: [],
    clarification: null,
    care: null,
    smallTalk: false,
    outOfScope: false,
  };
};

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
  app = initializeApp({ projectId }, `assistant-speed-${randomUUID()}`);
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

describe('rule-read routine logs (0 credits, no model)', () => {
  it('"bé bú 120ml lúc 8h sáng" without a quote: the card comes back in the answer, no model call, 0 credits, listed as free', async () => {
    const gw = fakeModelGateway({});
    const r = await start('bé bú 120ml lúc 8h sáng', gw);
    expect(r.data.task).toMatchObject({ state: 'ready', credits: 0, usage: 'committed' });
    expect(r.data.drafts).toHaveLength(1);
    expect(r.data.drafts[0]!.payload).toMatchObject({
      kind: 'bottle',
      amountMl: 120,
      occurredAt: '2026-10-15T01:00:00.000Z',
    });
    // The answer is the whole snapshot (the phone draws it, no getAssistantTask).
    expect(r.data.messages.map((m) => m.role)).toEqual(['user', 'assistant']);
    expect(r.data.events.map((e) => e.type)).toEqual([
      'accepted',
      'progress',
      'drafts_ready',
      'usage_updated',
    ]);
    expect(gw.calls.extract).toHaveLength(0);
    expect(await win()).toMatchObject({ used: 0, reserved: 0 });
    const u = (await getAssistantUsage(deps(), MOM, E({ babyId: B }))).data;
    expect(u.recent!.map((x) => [x.kind, x.state, x.credits])).toEqual([['text', 'committed', 0]]);
    expect(u.remaining).toBe(30);
  });

  it('the routine phrases of the plan are read the same way (diaper, sleep start, pump, weight)', async () => {
    for (const [text, kind] of [
      ['thay tã ướt lúc 13h', 'diaper'],
      ['hút 100ml lúc 10h', 'pump'],
      ['bé nặng 5,2kg', 'growth'],
      ['bé ngủ từ 13h đến 14h', 'sleep'],
    ] as const) {
      const gw = fakeModelGateway({});
      const r = await start(text, gw);
      expect(r.data.task, text).toMatchObject({ state: 'ready', credits: 0 });
      expect(
        r.data.drafts.map((d) => d.payload.kind),
        text,
      ).toEqual([kind]);
      expect(gw.calls.extract, text).toHaveLength(0);
    }
  });

  it('works with the model off and with no credits left (the free path)', async () => {
    await setFreeLimit(0);
    const r = await start('bé bú 90ml lúc 13h', null);
    expect(r.data.task).toMatchObject({ state: 'ready', credits: 0 });
    expect(r.status).toBe('ok');
    // A message only the model reads is still blocked (kept to resume, nothing reserved).
    const m = await start('8h bú 120ml, 11h bú 150ml', null);
    expect(m.data.task).toMatchObject({ state: 'blocked', errorCode: 'AI_UNAVAILABLE' });
  });

  it('a missing time is asked; the answer runs in the same request and returns the card', async () => {
    const gw = fakeModelGateway({});
    const r = await start('sáng nay bé bú 120ml', gw);
    expect(r.data.task.state).toBe('awaiting_clarification');
    const cl = r.data.task.clarification!;
    expect(cl.field).toBe('time.missing');
    const a = await submitClarification(
      deps(gw),
      MOM,
      E({
        taskId: r.taskId,
        expectedVersion: r.data.task.version,
        clarificationId: cl.id,
        choiceId: cl.choices[0]!.id,
        text: null,
      }),
    );
    expect(a.data.task).toMatchObject({ state: 'ready', credits: 0 });
    expect(a.data.drafts[0]!.payload).toMatchObject({ kind: 'bottle', amountMl: 120 });
    expect(gw.calls.extract).toHaveLength(0);
  });

  it('an older app with a quote still works, and a rule read is never a quote mismatch', async () => {
    const q = await quoteTask(
      deps(),
      MOM,
      E({
        conversationId: SHARED,
        scope: SCOPE,
        modality: 'text',
        attachmentCount: 0,
        intentHint: null,
      }),
    );
    expect(q.data.credits).toBe(1);
    const r = await start(
      'thay tã ướt lúc 13h',
      fakeModelGateway({}),
      {},
      { quoteId: q.data.quoteId },
    );
    expect(r.data.task).toMatchObject({ state: 'ready', credits: 0 });
  });
});

describe('the model path, inside startTask', () => {
  it('a message the rules leave is read by the model in the same request: 1 credit, committed', async () => {
    const gw = fakeModelGateway({ extract: [twoBottles()] });
    const r = await start('8h bú 120ml, 11h bú 150ml', gw);
    expect(gw.calls.extract).toHaveLength(1);
    // The calendar and the categories stay out of a plain care log (a shorter prompt).
    expect(gw.calls.extract[0]).toMatchObject({ text: '8h bú 120ml, 11h bú 150ml' });
    expect(r.data.task).toMatchObject({ credits: 1 });
    expect(['ready', 'awaiting_clarification']).toContain(r.data.task.state);
    expect(await win()).toMatchObject({ reserved: r.data.task.state === 'ready' ? 0 : 1 });
  });

  it('the trigger leaves a task the request is running alone', async () => {
    const gw = fakeModelGateway({ extract: [twoBottles()] });
    const r = await start('8h bú 120ml, 11h bú 150ml', gw);
    const again = await runAssistantTask(
      { db, now: NOW, environment: 'test', gateway: gw },
      r.taskId!,
    );
    expect(again.ran).toBe(false);
  });

  it('no time left for the model: the task goes to the trigger (queued), never a failure', async () => {
    const slow: FakeStep<ExtractInput> = async () => {
      await sleep(6_000);
      return twoBottles();
    };
    // Budget 2.5 s: too little to start a call inline.
    const gw = fakeModelGateway({ extract: [twoBottles()] });
    const r = await start('8h bú 120ml, 11h bú 150ml', gw, { inlineBudgetMs: 2_500 });
    expect(r.data.task.state).toBe('queued');
    expect(gw.calls.extract).toHaveLength(0);
    const ran = await runAssistantTask(
      { db, now: NOW, environment: 'test', gateway: gw },
      r.taskId!,
    );
    expect(ran.ran).toBe(true);
    const snap = (await getAssistantTask(deps(), MOM, E({ taskId: r.taskId, afterSequence: null })))
      .data;
    expect(snap.drafts).toHaveLength(2);
    // Started inline but cut by the request's deadline: the same hand-off, the trigger reads again.
    const gw2 = fakeModelGateway({ extract: [slow, twoBottles()] });
    const r2 = await start('9h bú 120ml, 11h bú 150ml', gw2, { inlineBudgetMs: 7_000 });
    expect(r2.data.task.state).toBe('queued');
    await runAssistantTask({ db, now: NOW, environment: 'test', gateway: gw2 }, r2.taskId!);
    expect(
      (await getAssistantTask(deps(), MOM, E({ taskId: r2.taskId, afterSequence: null }))).data.task
        .state,
    ).not.toBe('failed');
  }, 30_000);
});

describe('gates without a quote (the same as quoteTask)', () => {
  it('consent, a photo without its quote', async () => {
    await setAssistantConsent(deps(), MOM, E({ consent: null }));
    expect(await reason(start('bé bú 120ml lúc 13h', fakeModelGateway({})))).toBe(
      'CONSENT_REQUIRED',
    );
    expect(
      await reason(
        startTask(
          deps(),
          MOM,
          E({ conversationId: null, scope: SCOPE, text: null, attachmentIds: ['at_x'] }),
        ),
      ),
    ).toBe('VALIDATION_FAILED');
  });

  it('the assistant switched off', async () => {
    await db.doc('config/flags').set({ assistant: { ...defaultFlags.assistant, enabled: false } });
    expect(await reason(start('bé bú 120ml lúc 13h', fakeModelGateway({})))).toBe(
      'FEATURE_DISABLED',
    );
  });
});
