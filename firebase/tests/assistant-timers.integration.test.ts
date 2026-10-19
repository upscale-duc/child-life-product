import { randomUUID } from 'node:crypto';
import {
  assistantConsentVersion,
  defaultEntitlementsConfig,
  defaultFlags,
  draftKinds,
  type AssistantPart,
  type AssistantTaskSnapshot,
} from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  confirmDrafts,
  discardDraft,
  getAssistantTask,
  patchDraft,
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
import { runAssistantTask } from '../functions/src/assistant-worker.js';

// Lumi 2026-10-16 (docs/assistant/api.md "Timers and review fields") against the Firestore
// emulator with a FAKE model (scripted outputs): ongoing states drive the app's own running
// timers (`babies/{b}/timers/{type}`) — start, "already running", stop into the same record the
// app's "Kết thúc" writes — for every member of the shared thread; review flags name real fields
// and optional ones never block; the same message again reuses the waiting draft for 0 credits.
// Synthetic `test_` data only.
const projectId = 'demo-child-life-assistant-timers';
let app: App;
let db: Firestore;

const ZONE = 'Asia/Ho_Chi_Minh';
/** 01:05 in Vietnam on Friday 2026-10-16 (the dev report). */
const NIGHT = new Date('2026-10-15T18:05:00Z');
const plus = (min: number, from = NIGHT) => new Date(from.getTime() + min * 60_000);
const F = 'test_mf';
const B = 'test_mb';
const MOM = 'test_mmom';
const DAD = 'test_mdad';
const NANNY = 'test_mnanny';
const SCOPE = { type: 'child' as const, babyId: B };
const SHARED = `cv_${B}`;
const WIN = 'assistant_cal_2026-10';

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
  amount: null,
  currency: null,
  categoryId: null,
  merchant: null,
  date: null,
  assigneeText: null,
  phase: null,
};
const intent = (
  kind: string,
  fields: Partial<Record<keyof typeof F0, unknown>>,
  evidence: { field: string; text: string }[] = [],
  more: { missingFields?: string[]; uncertainFields?: string[]; correctsPrevious?: boolean } = {},
) => ({
  kind,
  fields: { ...F0, ...fields },
  evidence,
  uncertainFields: more.uncertainFields ?? [],
  missingFields: more.missingFields ?? [],
  correctsPrevious: more.correctsPrevious ?? false,
});
const extraction = (intents: unknown[] = []) => ({
  intents,
  reads: [],
  clarification: null,
  care: null,
  healthSigns: [],
  smallTalk: false,
  outOfScope: false,
});

// LUMI-05: the current app declares the draft kinds it can show.
const E = (over: Record<string, unknown> = {}) => ({
  contractVersion: 1,
  clientRequestId: randomUUID(),
  locale: 'vi',
  clientDraftKinds: [...draftKinds],
  ...over,
});
const deps = (gateway: ModelGateway | null = fakeModelGateway({}), at = NIGHT): AssistantDeps => ({
  db,
  now: at,
  environment: 'test',
  gateway,
  // Lumi L2: these cases test the trigger path and the model's readings (inline / rules: assistant-speed).
  inline: false,
  ruleReads: false,
});
const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason ?? String(e),
  );

async function start(text: string, uid: string, gw: ModelGateway, at: Date) {
  const q = await quoteTask(
    deps(gw, at),
    uid,
    E({
      conversationId: SHARED,
      scope: SCOPE,
      modality: 'text',
      attachmentCount: 0,
      intentHint: null,
    }),
  );
  return startTask(
    deps(gw, at),
    uid,
    E({ conversationId: SHARED, scope: SCOPE, quoteId: q.data.quoteId, text, attachmentIds: [] }),
  );
}
const work = (taskId: string, gw: ModelGateway, at: Date) =>
  runAssistantTask({ db, now: at, environment: 'test', gateway: gw, timeoutMs: 1_000 }, taskId);
const snapshot = async (taskId: string, uid = MOM, at = NIGHT) =>
  (await getAssistantTask(deps(null, at), uid, E({ taskId, afterSequence: null }))).data;

async function run(
  text: string,
  script: FakeStep<ExtractInput>[],
  o: {
    uid?: string;
    at?: Date;
    answers?: Record<string, { choiceId?: string; text?: string }>;
  } = {},
) {
  const uid = o.uid ?? MOM;
  const at = o.at ?? NIGHT;
  const gw = fakeModelGateway({ extract: script, word: [] });
  const r = await start(text, uid, gw, at);
  const taskId = r.taskId!;
  if (r.data.task.state === 'queued') await work(taskId, gw, at);
  let snap = await snapshot(taskId, uid, at);
  const asked: AssistantTaskSnapshot['task']['clarification'][] = [];
  for (let i = 0; i < 4 && snap.task.state === 'awaiting_clarification'; i++) {
    const cl = snap.task.clarification!;
    asked.push(cl);
    const key = Object.keys(o.answers ?? {}).find((k) => cl.field.startsWith(k));
    if (!key) break;
    const a = o.answers![key]!;
    await submitClarification(
      deps(gw, at),
      uid,
      E({
        taskId,
        expectedVersion: snap.task.version,
        clarificationId: cl.id,
        choiceId: a.choiceId ?? null,
        text: a.text ?? null,
      }),
    );
    await work(taskId, gw, at);
    snap = await snapshot(taskId, uid, at);
  }
  return { taskId, gw, snap, asked, start: r };
}

const confirm = (taskId: string, draftId: string, revision = 1, uid = MOM, at = NIGHT) =>
  confirmDrafts(
    deps(null, at),
    uid,
    E({ taskId, selected: [{ draftId, revision, acknowledge: [] }] }),
  );

const win = async () =>
  (await db.doc(`families/${F}/quota/${WIN}`).get()).data() ?? { used: 0, reserved: 0 };
const codes = (s: AssistantTaskSnapshot) =>
  s.messages
    .flatMap((m) => m.parts)
    .flatMap((p: AssistantPart) => (p.type === 'text' && p.code ? [p.code] : []));
const texts = (s: AssistantTaskSnapshot) =>
  s.messages
    .filter((m) => m.role === 'assistant')
    .flatMap((m) => m.parts)
    .flatMap((p: AssistantPart) => (p.type === 'text' ? [p.text] : []));
const timer = (type: 'sleep' | 'breast') => db.doc(`babies/${B}/timers/${type}`).get();

/** A timer exactly as the app writes it (`CareTimer.toJson`), started by [uid]. */
async function appStartsTimer(type: 'sleep' | 'breast', uid: string, at: Date, sessionId: string) {
  const name = uid === DAD ? 'Huy' : 'Mai';
  await db.doc(`babies/${B}/timers/${type}`).set({
    type,
    babyId: B,
    sessionId,
    startedAt: Timestamp.fromDate(at),
    startedBy: uid,
    author: { name, relation: uid === DAD ? 'father' : 'mother', relationCustom: null },
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
    updatedBy: uid,
  });
}

const member = (role: string, relation: string, displayName: string, extra = {}) => ({
  role,
  status: 'active',
  relation,
  relationCustom: null,
  displayName,
  ...extra,
});
const on = (key: keyof typeof defaultFlags) => ({
  ...defaultFlags[key],
  enabled: true,
  scope: 'all' as const,
});

beforeAll(() => {
  app = initializeApp({ projectId }, `assistant-timers-${randomUUID()}`);
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
  await db.doc('config/entitlements').set({
    ...defaultEntitlementsConfig,
    regions: { advanced: ['VN'] },
  });
  await db.doc(`babies/${B}`).set({
    familyId: F,
    timeZone: { mode: 'auto', zone: ZONE },
    state: 'active',
  });
  await db.doc(`families/${F}`).set({ ownerUid: MOM, country: 'VN', timeZone: ZONE, babyIds: [B] });
  await db
    .doc(`babies/${B}/members/${MOM}`)
    .set(member('coParent', 'mother', 'Mai', { isOwner: true }));
  await db.doc(`babies/${B}/members/${DAD}`).set(member('coParent', 'father', 'Huy'));
  await db.doc(`babies/${B}/members/${NANNY}`).set(member('caregiver', 'nanny', 'Cô Hoa'));
  for (const uid of [MOM, DAD, NANNY]) {
    await setAssistantConsent(deps(), uid, E({ consent: { version: assistantConsentVersion } }));
  }
});

/** The dev incident: the model read "Con đang ngủ" as an observation with "time" missing. */
const incident = () =>
  extraction([
    intent('observation', { observation: 'sleep', note: 'Con đang ngủ' }, [], {
      missingFields: ['time', 'when'],
    }),
  ]);
const sleepStop = () =>
  extraction([intent('sleep', { phase: 'stop' }, [{ field: 'phase', text: 'dậy rồi' }])]);

// =====================================================================================
describe('sleep timer from chat — the same timer as the app', () => {
  it('"Con đang ngủ" (read as an observation) → one tap "Bắt đầu tính giờ ngủ · 01:05" → the app timer; "con dậy rồi" → the same record as "Kết thúc"', async () => {
    const a = await run('Con đang ngủ', [incident()]);
    expect(a.snap.drafts).toHaveLength(1);
    const d = a.snap.drafts[0]!;
    expect(d.payload).toEqual({
      kind: 'timer',
      timer: 'sleep',
      action: 'start',
      at: NIGHT.toISOString(),
      side: null,
      sessionId: null,
      startedAt: null,
    });
    // Nothing to check: ready to save in one tap (the incident's "Cần kiểm tra" is gone).
    expect(d).toMatchObject({
      state: 'draft',
      missingFields: [],
      uncertainFields: [],
      problems: [],
    });
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });

    const saved = await confirm(a.taskId, d.id);
    expect(saved.data.items[0]).toMatchObject({
      status: 'saved',
      recordLink: `/care/timer/sleep?babyId=${B}`,
    });
    const t = await timer('sleep');
    // `validNewTimer`: exactly the app's keys, the confirmer as starter and author.
    expect(Object.keys(t.data()!).sort()).toEqual(
      [
        'author',
        'babyId',
        'pausedSides',
        'paused',
        'sessionId',
        'sides',
        'startedAt',
        'startedBy',
        'type',
        'updatedAt',
        'updatedBy',
      ].sort(),
    );
    expect(t.data()).toMatchObject({
      type: 'sleep',
      babyId: B,
      startedBy: MOM,
      updatedBy: MOM,
      author: { name: 'Mai', relation: 'mother', relationCustom: null },
      sides: null,
      paused: false,
      pausedSides: [],
    });
    expect((t.get('startedAt') as Timestamp).toDate()).toEqual(NIGHT);
    const sessionId = t.get('sessionId') as string;
    expect(sessionId).toMatch(/^[a-f0-9]{32}$/);
    expect(saved.data.items[0]!.recordId).toBe(`r_${sessionId}`);

    // 55 minutes later the father says the baby woke up: the stop of THAT session.
    const woke = plus(55);
    const b = await run('con dậy rồi', [sleepStop()], { uid: DAD, at: woke });
    const stop = b.snap.drafts[0]!;
    expect(stop.payload).toEqual({
      kind: 'timer',
      timer: 'sleep',
      action: 'stop',
      at: woke.toISOString(),
      side: null,
      sessionId,
      startedAt: NIGHT.toISOString(),
    });
    expect(stop.state).toBe('draft');
    const ended = await confirm(b.taskId, stop.id, 1, DAD, woke);
    expect(ended.data.items[0]).toMatchObject({
      status: 'saved',
      recordId: `r_${sessionId}`,
      recordLink: `/care/records/${B}/r_${sessionId}`,
    });
    expect((await timer('sleep')).exists).toBe(false);
    const rec = await db.doc(`babies/${B}/records/r_${sessionId}`).get();
    expect(rec.data()).toMatchObject({
      id: `r_${sessionId}`,
      type: 'sleep',
      data: {},
      createdBy: DAD,
      author: { name: 'Huy', relation: 'father', relationCustom: null },
      deleted: false,
      source: 'assistant',
    });
    expect((rec.get('occurredAt') as Timestamp).toDate()).toEqual(NIGHT);
    expect((rec.get('endedAt') as Timestamp).toDate()).toEqual(woke);
  });

  it('"bắt đầu ngủ lúc 21h" said at 21:30 starts the timer at 21:00; a caregiver can start it too', async () => {
    const at = new Date('2026-10-15T14:30:00Z'); // 21:30 local
    const r = await run('bắt đầu ngủ lúc 21h', [extraction([])], { uid: NANNY, at });
    expect(r.snap.drafts[0]!.payload).toMatchObject({
      kind: 'timer',
      timer: 'sleep',
      action: 'start',
      at: new Date('2026-10-15T14:00:00Z').toISOString(),
    });
    const s = await confirm(r.taskId, r.snap.drafts[0]!.id, 1, NANNY, at);
    expect(s.data.items[0]!.status).toBe('saved');
    expect((await timer('sleep')).get('startedBy')).toBe(NANNY);
  });

  it('"Con đang ngủ" while the timer runs: says so and offers "Kết thúc" / "Để tiếp tục" (keeping it changes nothing)', async () => {
    const since = plus(-40);
    await appStartsTimer('sleep', DAD, since, 'a'.repeat(32));
    const r = await run('Con đang ngủ', [incident()]);
    expect(codes(r.snap)).toContain('TIMER_RUNNING');
    expect(texts(r.snap).join(' ')).toContain('00:25');
    const d = r.snap.drafts[0]!;
    expect(d.payload).toMatchObject({
      kind: 'timer',
      timer: 'sleep',
      action: 'stop',
      sessionId: 'a'.repeat(32),
      startedAt: since.toISOString(),
      at: NIGHT.toISOString(),
    });
    // "Để tiếp tục": the draft goes, the timer stays.
    await discardDraft(deps(null), MOM, E({ draftId: d.id, expectedRevision: 1 }));
    expect((await timer('sleep')).get('sessionId')).toBe('a'.repeat(32));
  });

  it('"dậy rồi" with no timer asks when the sleep started (chips by length, or a typed length) and drafts the finished sleep', async () => {
    const r = await run('bé vừa dậy', [sleepStop()], {
      answers: { 'time.start': { choiceId: 'at_2026-10-15_23:05' } },
    });
    expect(r.asked.map((q) => q!.field)).toEqual(['time.start']);
    expect(r.asked[0]!.choices.map((c) => c.label.vi)).toEqual([
      'Khoảng 1 tiếng (từ 00:05)',
      'Khoảng 2 tiếng (từ 23:05 hôm qua)',
      'Khoảng 3 tiếng (từ 22:05 hôm qua)',
    ]);
    expect(r.gw.calls.extract).toHaveLength(1); // the answer reuses the first reading
    expect(r.snap.drafts[0]).toMatchObject({
      state: 'draft',
      missingFields: [],
      payload: {
        kind: 'sleep',
        startedAt: new Date('2026-10-15T16:05:00Z').toISOString(),
        endedAt: NIGHT.toISOString(),
        durationMin: 120,
      },
    });
    const typed = await run('con dậy rồi', [sleepStop()], {
      at: plus(30),
      answers: { 'time.start': { text: '90 phút' } },
    });
    expect(typed.snap.drafts[0]!.payload).toMatchObject({
      kind: 'sleep',
      startedAt: plus(-60).toISOString(),
      endedAt: plus(30).toISOString(),
      durationMin: 90,
    });
  });
});

describe('breastfeeding timer from chat', () => {
  it('"đang cho bú (trái)" → the left side runs; "bú xong rồi" → the record the timer would write', async () => {
    const a = await run('đang cho bú (trái)', [extraction([])]);
    expect(a.snap.drafts[0]!.payload).toEqual({
      kind: 'timer',
      timer: 'breast',
      action: 'start',
      at: NIGHT.toISOString(),
      side: 'left',
      sessionId: null,
      startedAt: null,
    });
    await confirm(a.taskId, a.snap.drafts[0]!.id);
    const t = await timer('breast');
    expect(t.get('sides.left.accumulatedMs')).toBe(0);
    expect((t.get('sides.left.runningSince') as Timestamp).toDate()).toEqual(NIGHT);
    expect(t.get('sides.right')).toEqual({ accumulatedMs: 0, runningSince: null });
    const sessionId = t.get('sessionId') as string;

    const done = plus(12);
    const b = await run('bú xong rồi', [extraction([])], { at: done });
    expect(b.snap.drafts[0]!.payload).toMatchObject({
      kind: 'timer',
      timer: 'breast',
      action: 'stop',
      sessionId,
    });
    await confirm(b.taskId, b.snap.drafts[0]!.id, 1, MOM, done);
    const rec = await db.doc(`babies/${B}/records/r_${sessionId}`).get();
    expect(rec.get('type')).toBe('breast');
    expect(rec.get('data')).toEqual({
      side: 'left',
      durationMin: 12,
      leftMin: 12,
      rightMin: 0,
      endSide: 'left',
    });
    expect((await timer('breast')).exists).toBe(false);
  });

  it('a feed timer started on the app is ended from chat by another member (shared thread)', async () => {
    await appStartsTimer('breast', DAD, plus(-15), 'b'.repeat(32));
    const r = await run('bú xong rồi', [extraction([])], { uid: NANNY });
    const s = await confirm(r.taskId, r.snap.drafts[0]!.id, 1, NANNY);
    expect(s.data.items[0]!.status).toBe('saved');
    const rec = await db.doc(`babies/${B}/records/r_${'b'.repeat(32)}`).get();
    expect(rec.get('createdBy')).toBe(NANNY);
    expect(rec.get('data')).toMatchObject({ side: 'left', durationMin: 15 });
  });
});

describe('races with the app and the family', () => {
  it('ended on a phone before "Kết thúc" in chat: adopted as saved (one record); started elsewhere first: TIMER_RUNNING', async () => {
    await appStartsTimer('sleep', DAD, plus(-30), 'c'.repeat(32));
    const r = await run('con dậy rồi', [sleepStop()]);
    // The father taps "Kết thúc" on the timer screen meanwhile (the app's batch).
    await db.doc(`babies/${B}/records/r_${'c'.repeat(32)}`).set({ type: 'sleep', deleted: false });
    await db.doc(`babies/${B}/timers/sleep`).delete();
    const s = await confirm(r.taskId, r.snap.drafts[0]!.id);
    expect(s.data.items[0]).toMatchObject({ status: 'saved', recordId: `r_${'c'.repeat(32)}` });

    const st = await run('Con đang ngủ', [incident()], { at: plus(5) });
    await appStartsTimer('sleep', DAD, plus(4), 'd'.repeat(32));
    const c = await confirm(st.taskId, st.snap.drafts[0]!.id, 1, MOM, plus(5));
    expect(c.data.items[0]).toMatchObject({ status: 'conflict', errorCode: 'TIMER_RUNNING' });
    expect((await timer('sleep')).get('sessionId')).toBe('d'.repeat(32));
  });

  it('a timer draft can move its time, never its session', async () => {
    const r = await run('Con đang ngủ', [incident()]);
    const d = r.snap.drafts[0]!;
    const ok = await patchDraft(
      deps(null),
      MOM,
      E({
        draftId: d.id,
        expectedRevision: 1,
        payload: { ...d.payload, at: plus(-10).toISOString() },
        confirmedFields: [],
      }),
    );
    expect(ok.data.draft).toMatchObject({ state: 'draft', revision: 2 });
    expect(
      await reason(
        patchDraft(
          deps(null),
          MOM,
          E({
            draftId: d.id,
            expectedRevision: 2,
            payload: { ...d.payload, action: 'stop', sessionId: 'e'.repeat(32) },
            confirmedFields: [],
          }),
        ),
      ),
    ).toBe('VALIDATION_FAILED');
  });
});

describe('review fields and repeated messages', () => {
  it('the same words again reuse the waiting draft: answered at once, 0 credits, the first draft untouched', async () => {
    const first = await run('Con đang ngủ', [incident()]);
    const gw = fakeModelGateway({ extract: [incident()] });
    const again = await start('con đang ngủ.', MOM, gw, plus(1));
    expect(again.data.task).toMatchObject({ state: 'ready', credits: 0, usage: 'none' });
    const snap = await snapshot(again.taskId!, MOM, plus(1));
    expect(codes(snap)).toEqual(['SAME_AS_PENDING']);
    expect(gw.calls.extract).toHaveLength(0);
    expect((await snapshot(first.taskId)).drafts[0]!.state).toBe('draft');
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
    // Once saved, the same words are a new message again (the timer already runs → offered stop).
    await confirm(first.taskId, first.snap.drafts[0]!.id);
    const third = await run('Con đang ngủ', [incident()], { at: plus(2) });
    expect(codes(third.snap)).toContain('TIMER_RUNNING');
  });

  it('an observation the model said was missing "time" is complete; "when" is optional', async () => {
    // A note about one night (LUMI-10: "dạo này con khó ngủ" is a care question instead).
    const r = await run('đêm qua con khó ngủ hơn mọi khi', [
      extraction([
        intent('observation', { observation: 'sleep', note: 'khó ngủ' }, [], {
          missingFields: ['time', 'when', 'date'],
        }),
      ]),
    ]);
    expect(r.snap.drafts[0]).toMatchObject({
      state: 'draft',
      missingFields: [],
      uncertainFields: [],
      payload: { kind: 'observation', observation: 'sleep', date: '2026-10-16', when: null },
    });
    const s = await confirm(r.taskId, r.snap.drafts[0]!.id);
    expect(s.data.items[0]!.status).toBe('saved');
  });

  it('LUMI-10: "dạo này con khó ngủ" read as an observation is a sleep concern (care), never a draft', async () => {
    const r = await run('dạo này con khó ngủ', [
      extraction([
        intent('observation', { observation: 'sleep', note: 'khó ngủ' }, [], {
          missingFields: ['time', 'when', 'date'],
        }),
      ]),
    ]);
    expect(r.snap.drafts).toHaveLength(0);
    // Care guidance (or its honest "paused here" when care is off in this world).
    expect(
      r.snap.task.care?.topic === 'sleep_concern' ||
        ['FEATURE_DISABLED', 'REGION_UNSUPPORTED'].includes(r.snap.task.errorCode ?? ''),
    ).toBe(true);
  });

  it('the second report: "Con đã bú mẹ được 20p" + "Vừa xong" is complete (time filled, side defaulted)', async () => {
    const r = await run(
      'Con đã bú mẹ được 20p',
      [
        extraction([
          // The live model also called the side it was never given "unsure" (eval rev-01).
          intent('breast', { durationMin: 20 }, [{ field: 'durationMin', text: '20p' }], {
            missingFields: ['time', 'side'],
            uncertainFields: ['side'],
          }),
        ]),
      ],
      { at: plus(4), answers: { 'time.missing': { choiceId: 'ago_0' } } },
    );
    expect(r.snap.drafts[0]).toMatchObject({
      state: 'draft',
      missingFields: [],
      uncertainFields: [],
      payload: {
        kind: 'breast',
        occurredAt: plus(-16).toISOString(),
        durationMin: 20,
        side: 'both',
      },
    });
    const s = await confirm(r.taskId, r.snap.drafts[0]!.id, 1, MOM, plus(4));
    expect(s.data.items[0]!.status).toBe('saved');
  });

  it('"fed 120 ml": the milk not said is the last bottle\'s, never "unsure" (eval rev-05)', async () => {
    const r = await run(
      'fed 120 ml',
      [
        extraction([
          intent('bottle', { amountMl: 120 }, [{ field: 'amountMl', text: '120 ml' }], {
            missingFields: ['time'],
            uncertainFields: ['milk'],
          }),
        ]),
      ],
      { answers: { 'time.missing': { choiceId: 'ago_0' } } },
    );
    expect(r.snap.drafts[0]).toMatchObject({
      state: 'draft',
      missingFields: [],
      uncertainFields: [],
      payload: { kind: 'bottle', amountMl: 120, milk: 'breast_milk' },
    });
  });

  it('"bé ngủ 2 tiếng" read as an observation is the sleep log (its start is asked), never an observation', async () => {
    const r = await run('bé ngủ 2 tiếng', [
      extraction([
        intent('observation', { observation: 'sleep' }, [], { missingFields: ['time'] }),
      ]),
    ]);
    expect(r.snap.task.clarification?.field).toBe('time.start');
    expect(r.snap.drafts).toHaveLength(0);
  });
});

describe('LUMI-05: an app build from before timers (no clientDraftKinds)', () => {
  it('"Con đang ngủ": no timer draft it cannot show; a notice with the timer link; 0 credits', async () => {
    const gw = fakeModelGateway({ extract: [extraction([])], word: [] });
    const old = (over: Record<string, unknown>) => {
      const { clientDraftKinds: _k, ...rest } = E(over);
      void _k;
      return rest;
    };
    const q = await quoteTask(
      deps(gw),
      MOM,
      old({
        conversationId: SHARED,
        scope: SCOPE,
        modality: 'text',
        attachmentCount: 0,
        intentHint: null,
      }),
    );
    const r = await startTask(
      deps(gw),
      MOM,
      old({
        conversationId: SHARED,
        scope: SCOPE,
        quoteId: q.data.quoteId,
        text: 'Con đang ngủ',
        attachmentIds: [],
      }),
    );
    await work(r.taskId!, gw, NIGHT);
    const snap = await snapshot(r.taskId!);
    expect(snap.drafts).toHaveLength(0);
    expect(codes(snap)).toContain('APP_UPDATE_NEEDED');
    const notice = snap.messages
      .flatMap((m) => m.parts)
      .find((p) => p.type === 'text' && p.code === 'APP_UPDATE_NEEDED');
    expect(notice).toMatchObject({ link: expect.stringContaining('/care/timer/sleep') });
    expect(snap.task).toMatchObject({ state: 'ready', usage: 'released' });
    expect((await timer('sleep')).exists).toBe(false);
  });
});
