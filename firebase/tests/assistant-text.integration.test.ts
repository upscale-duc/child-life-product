import { randomUUID } from 'node:crypto';
import {
  assistantConsentVersion,
  defaultEntitlementsConfig,
  defaultFlags,
  contentFoodSchema,
  expenseSchema,
  mealSchema,
  reminderSchema,
  draftKinds,
  type AssistantPart,
  type AssistantTaskSnapshot,
  type DraftPayload,
} from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  confirmDrafts,
  getAssistantTask,
  listAssistantHistory,
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
import { privateConversationId } from '../functions/src/assistant-talk.js';
import { runAssistantTask } from '../functions/src/assistant-worker.js';
import { foodFixture } from '../functions/test/solids-fixtures.js';

// Lumi rework 2026-10-15 (docs/assistant/api.md "Rework 2026-10-15") against the Firestore
// emulator with a FAKE model (scripted outputs, no heuristics): typed expenses and reminders,
// spending kept out of the baby's shared thread (at start and, when only the model sees it, by
// moving the task in the settle transaction), duration-aware sleep with the server's start
// question, server questions that reuse the first reading (one model call), corrections,
// duplicates, small talk / help for 0 credits. Synthetic `test_` data only.
const projectId = 'demo-child-life-assistant-text';
let app: App;
let db: Firestore;

const ZONE = 'Asia/Ho_Chi_Minh';
/** 14:20 in Vietnam on Thursday 2026-10-15. */
const NOW = new Date('2026-10-15T07:20:00Z');
/** 07:10 in Vietnam the same day. */
const MORNING = new Date('2026-10-15T00:10:00Z');
const F = 'test_tf';
const B = 'test_tb';
const MOM = 'test_tmom';
const DAD = 'test_tdad';
const NANNY = 'test_tnanny';
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
};
const intent = (
  kind: string,
  fields: Partial<Record<keyof typeof F0, unknown>>,
  evidence: { field: string; text: string }[] = [],
  correctsPrevious = false,
) => ({
  kind,
  fields: { ...F0, ...fields },
  evidence,
  uncertainFields: [],
  missingFields: [],
  correctsPrevious,
});
const extraction = (intents: unknown[] = [], over: Record<string, unknown> = {}) => ({
  intents,
  reads: [],
  clarification: null,
  care: null,
  healthSigns: [],
  smallTalk: false,
  outOfScope: false,
  ...over,
});

// LUMI-05: the current app declares the draft kinds it can show.
const E = (over: Record<string, unknown> = {}) => ({
  contractVersion: 1,
  clientRequestId: randomUUID(),
  locale: 'vi',
  clientDraftKinds: [...draftKinds],
  ...over,
});
const deps = (gateway: ModelGateway | null = fakeModelGateway({}), at = NOW): AssistantDeps => ({
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

async function start(
  text: string,
  o: {
    uid?: string | undefined;
    gw?: ModelGateway;
    at?: Date;
    conversationId?: string | null;
  } = {},
) {
  const uid = o.uid ?? MOM;
  const gw = o.gw ?? fakeModelGateway({});
  const at = o.at ?? NOW;
  const conversationId = o.conversationId === undefined ? SHARED : o.conversationId;
  const q = await quoteTask(
    deps(gw, at),
    uid,
    E({ conversationId, scope: SCOPE, modality: 'text', attachmentCount: 0, intentHint: null }),
  );
  return startTask(
    deps(gw, at),
    uid,
    E({ conversationId, scope: SCOPE, quoteId: q.data.quoteId, text, attachmentIds: [] }),
  );
}
const work = (taskId: string, gw: ModelGateway, at = NOW) =>
  runAssistantTask({ db, now: at, environment: 'test', gateway: gw, timeoutMs: 1_000 }, taskId);
const snapshot = async (taskId: string, uid = MOM) =>
  (await getAssistantTask(deps(), uid, E({ taskId, afterSequence: null }))).data;

/** Start + run with [script] (as [uid]); answers each open question with [answers] by field. */
async function run(
  text: string,
  script: FakeStep<ExtractInput>[],
  o: {
    uid?: string;
    at?: Date;
    answers?: Record<string, { choiceId?: string; text?: string }>;
  } = {},
) {
  const gw = fakeModelGateway({ extract: script, word: [] });
  const at = o.at ?? NOW;
  const r = await start(text, { uid: o.uid, gw, at });
  const taskId = r.taskId!;
  if (r.data.task.state === 'queued') await work(taskId, gw, at);
  let snap = await snapshot(taskId, o.uid ?? MOM);
  const asked: string[] = [];
  for (let i = 0; i < 4 && snap.task.state === 'awaiting_clarification'; i++) {
    const cl = snap.task.clarification!;
    asked.push(cl.field);
    const key = Object.keys(o.answers ?? {}).find((k) => cl.field.startsWith(k));
    if (!key) break;
    const a = o.answers![key]!;
    await submitClarification(
      deps(gw, at),
      o.uid ?? MOM,
      E({
        taskId,
        expectedVersion: snap.task.version,
        clarificationId: cl.id,
        choiceId: a.choiceId ?? null,
        text: a.text ?? null,
      }),
    );
    await work(taskId, gw, at);
    snap = await snapshot(taskId, o.uid ?? MOM);
  }
  return { taskId, gw, snap, asked, start: r };
}

const confirm = (
  taskId: string,
  selected: {
    draftId: string;
    revision: number;
    acknowledge?: ('overlap' | 'duplicate_suspected')[];
  }[],
  uid = MOM,
) =>
  confirmDrafts(
    deps(null),
    uid,
    E({ taskId, selected: selected.map((s) => ({ acknowledge: [], ...s })) }),
  );

const win = async () =>
  (await db.doc(`families/${F}/quota/${WIN}`).get()).data() ?? { used: 0, reserved: 0 };
const sharedMessages = async () =>
  (await db.collection(`assistantConversations/${SHARED}/messages`).get()).docs;
const codes = (s: AssistantTaskSnapshot) =>
  s.messages
    .flatMap((m) => m.parts)
    .flatMap((p: AssistantPart) => (p.type === 'text' && p.code ? [p.code] : []));
const local = (iso: string | null) =>
  iso
    ? `${new Intl.DateTimeFormat('en-CA', { timeZone: ZONE }).format(new Date(iso))} ${new Intl.DateTimeFormat('en-GB', { timeZone: ZONE, hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }).format(new Date(iso))}`
    : null;

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
  app = initializeApp({ projectId }, `assistant-text-${randomUUID()}`);
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
    'contentFoods',
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

// =====================================================================================
describe('typed expenses (Chi tiêu) — private from the start (D-075 #2)', () => {
  const milk = () =>
    extraction([
      intent('expense', { amount: 500000, currency: 'VND', categoryId: 'c_milk', title: 'sữa' }, [
        { field: 'amount', text: '500k' },
        { field: 'title', text: 'sữa' },
      ]),
    ]);

  it('"Mua sữa hết 500k" → one expense draft in the author’s private thread; confirm writes a valid expense, 1 credit', async () => {
    const { taskId, snap } = await run('Mua sữa hết 500k', [milk()]);
    expect(snap.task).toMatchObject({
      state: 'ready',
      visibility: 'private',
      routing: { reason: 'spending', from: 'shared_thread', at: 'start' },
      conversationId: privateConversationId(MOM, B),
    });
    expect(codes(snap)).toContain('SPENDING_PRIVATE');
    expect(snap.drafts[0]!.payload).toEqual({
      kind: 'expense',
      merchant: null,
      totalMinor: 500_000,
      currency: 'VND',
      date: '2026-10-15',
      subtotalMinor: null,
      taxMinor: null,
      categoryId: 'c_milk',
      babyId: B,
      keepReceipt: false,
      note: 'sữa',
    });
    expect(snap.drafts[0]).toMatchObject({
      state: 'draft',
      missingFields: [],
      uncertainFields: [],
    });
    // Never in the shared thread, never readable by the other members.
    expect((await sharedMessages()).map((m) => m.get('taskId'))).not.toContain(taskId);
    for (const uid of [DAD, NANNY]) {
      expect(await reason(getAssistantTask(deps(), uid, E({ taskId, afterSequence: null })))).toBe(
        'NOT_MEMBER',
      );
    }
    const r = await confirm(taskId, [{ draftId: snap.drafts[0]!.id, revision: 1 }]);
    expect(r.data.items[0]).toMatchObject({ status: 'saved' });
    const x = (await db.collection(`babies/${B}/expenses`).get()).docs[0]!;
    const data = x.data();
    const parsed = expenseSchema.safeParse({
      ...data,
      createdAt: (data.createdAt as Timestamp).toDate(),
      updatedAt: (data.updatedAt as Timestamp).toDate(),
    });
    expect(parsed.success).toBe(true);
    expect(data).toMatchObject({
      amount: 500_000,
      currency: 'VND',
      categoryId: 'c_milk',
      note: 'sữa',
      spentOn: '2026-10-15',
      source: 'assistant',
      createdBy: MOM,
    });
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
  });

  it('amounts are re-read from the words: "1tr2", "$20" (cents), "350.000đ" yesterday at a shop; unknown category → c_other to review', async () => {
    const a = await run('đóng tiền học bơi 1tr2', [
      extraction([
        intent('expense', { amount: 12, currency: 'VND', categoryId: 'c_nope', title: 'học bơi' }, [
          { field: 'amount', text: '1tr2' },
        ]),
      ]),
    ]);
    expect(a.snap.drafts[0]!.payload).toMatchObject({
      totalMinor: 1_200_000,
      categoryId: 'c_childcare',
    });
    const b = await run('$20 diapers', [
      extraction([
        intent('expense', { amount: 20, currency: 'USD' }, [{ field: 'amount', text: '$20' }]),
      ]),
    ]);
    expect(b.snap.drafts[0]!.payload).toMatchObject({
      totalMinor: 2000,
      currency: 'USD',
      categoryId: 'c_diaper',
    });
    const c = await run('hôm qua mua bỉm 350.000đ ở Con Cưng', [
      extraction([
        intent('expense', { amount: 350000, merchant: 'Con Cưng', title: 'bỉm' }, [
          { field: 'amount', text: '350.000đ' },
          { field: 'merchant', text: 'Con Cưng' },
        ]),
      ]),
    ]);
    expect(c.snap.drafts[0]!.payload).toMatchObject({
      totalMinor: 350_000,
      date: '2026-10-14',
      merchant: 'Con Cưng',
      categoryId: 'c_diaper',
    });
    const d = await run('trả 200 tiền gửi xe', [
      extraction([intent('expense', { amount: 200 }, [{ field: 'amount', text: '200' }])]),
    ]);
    expect(d.snap.drafts[0]).toMatchObject({ state: 'needs_review' });
    expect(d.snap.drafts[0]!.uncertainFields).toEqual(['categoryId', 'totalMinor']);
  });

  it('a mixed message ("bé bú 120ml lúc 8h sáng, mua sữa 500k") is private with both drafts', async () => {
    const { taskId, snap } = await run('bé bú 120ml lúc 8h sáng, mua sữa 500k', [
      extraction([
        intent('bottle', { amountMl: 120, time: '08:00', dayOffset: 0 }, [
          { field: 'amountMl', text: '120ml' },
          { field: 'time', text: '8h sáng' },
        ]),
        intent('expense', { amount: 500000, categoryId: 'c_milk' }, [
          { field: 'amount', text: '500k' },
        ]),
      ]),
    ]);
    expect(snap.task.visibility).toBe('private');
    expect(snap.drafts.map((d) => d.payload.kind)).toEqual(['bottle', 'expense']);
    expect((await sharedMessages()).map((m) => m.get('taskId'))).not.toContain(taskId);
  });

  it('a caregiver without the spending right gets a notice, never a draft; nothing charged', async () => {
    const { snap } = await run('Mua sữa hết 500k', [milk()], { uid: NANNY });
    expect(snap.task).toMatchObject({
      state: 'failed',
      errorCode: 'WRITE_DENIED',
      usage: 'released',
      visibility: 'private',
    });
    expect(snap.drafts).toHaveLength(0);
    expect(await win()).toMatchObject({ used: 0, reserved: 0 });
  });
});

describe('privacy: an expense only the model saw moves out of the shared thread', () => {
  it('the task, its message and its drafts land in the author’s private thread; a caregiver never sees the text or the draft', async () => {
    // No money words: the detector lets it into the shared thread; the model finds an expense.
    // ("hai hộp sữa" is caught at start since LUMI-16, so the words here say less.)
    const text = 'Ghé Con Cưng lấy sữa, bé bú 90ml lúc 13h';
    const { taskId, snap } = await run(text, [
      extraction([
        intent('bottle', { amountMl: 90, time: '13:00', dayOffset: 0 }, [
          { field: 'amountMl', text: '90ml' },
          { field: 'time', text: '13h' },
        ]),
        intent('expense', { amount: 900000, merchant: 'Con Cưng', categoryId: 'c_milk' }),
      ]),
    ]);
    expect(snap.task).toMatchObject({
      visibility: 'private',
      routing: { reason: 'spending', from: 'shared_thread', at: 'worker' },
      conversationId: privateConversationId(MOM, B),
    });
    expect(snap.drafts.map((d) => d.payload.kind)).toEqual(['bottle', 'expense']);
    // The model's number without readable words is shown for review, never trusted.
    expect(snap.drafts[1]!.uncertainFields).toContain('totalMinor');
    expect(snap.messages.map((m) => m.role)).toEqual(['user', 'assistant']);
    expect(codes(snap)).toContain('SPENDING_PRIVATE');
    // Nothing of it stays in the shared thread; the thread's last task is not this one.
    expect(await sharedMessages()).toHaveLength(0);
    expect((await db.doc(`assistantConversations/${SHARED}`).get()).get('lastTaskId')).toBeNull();
    for (const uid of [NANNY, DAD]) {
      expect(await reason(getAssistantTask(deps(), uid, E({ taskId, afterSequence: null })))).toBe(
        'NOT_MEMBER',
      );
      const page = await listAssistantHistory(
        deps(),
        uid,
        E({ babyId: B, conversationId: SHARED, cursor: null, limit: 20 }),
      );
      const all = JSON.stringify(page.data.items);
      expect(all).not.toContain('hộp sữa');
      expect(all).not.toContain(taskId);
      const drafts = await confirm(
        taskId,
        [{ draftId: snap.drafts[0]!.id, revision: 1 }],
        uid,
      ).then(
        () => 'ok',
        (e: { reason?: string }) => e.reason,
      );
      expect(drafts).toBe('NOT_MEMBER');
    }
    // The author still reads it in their own thread.
    const mine = await listAssistantHistory(
      deps(),
      MOM,
      E({ babyId: B, conversationId: privateConversationId(MOM, B), cursor: null, limit: 20 }),
    );
    expect(mine.data.items).toHaveLength(2);
  });
});

describe('typed reminders', () => {
  it('"nhắc mai 9h mua bỉm": asks morning / evening once (the first reading is reused: one model call); confirm writes the reminder', async () => {
    const { taskId, gw, snap, asked } = await run(
      'nhắc mai 9h mua bỉm',
      [
        extraction([
          intent('reminder', { title: 'mua bỉm', time: '09:00', date: '2026-10-16' }, [
            { field: 'title', text: 'mua bỉm' },
            { field: 'time', text: '9h' },
            { field: 'date', text: 'mai' },
          ]),
        ]),
      ],
      { answers: { 'time.ampm': { choiceId: 'am' } } },
    );
    expect(asked).toEqual(['time.ampm']);
    expect((gw as ReturnType<typeof fakeModelGateway>).calls.extract).toHaveLength(1);
    expect(snap.drafts[0]!.payload).toEqual({
      kind: 'reminder',
      title: 'mua bỉm',
      date: '2026-10-16',
      time: '09:00',
      assigneeUid: null,
    });
    expect(snap.task.usage).toBe('committed');
    const r = await confirm(taskId, [{ draftId: snap.drafts[0]!.id, revision: 1 }]);
    expect(r.data.items[0]!.status).toBe('saved');
    const rm = (await db.collection(`babies/${B}/reminders`).get()).docs[0]!.data();
    const parsed = reminderSchema.safeParse({
      ...rm,
      dueAt: (rm.dueAt as Timestamp).toDate(),
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    expect(parsed.success).toBe(true);
    expect(local((rm.dueAt as Timestamp).toDate().toISOString())).toBe('2026-10-16 09:00');
  });

  it('"thứ 6 đưa bé đi tiêm" is an all-day reminder on Friday in the shared thread; a name in the text is never an assignee — the person picks', async () => {
    const a = await run('thứ 6 đưa bé đi tiêm', [
      extraction([
        intent('reminder', { title: 'đưa bé đi tiêm' }, [
          { field: 'title', text: 'đưa bé đi tiêm' },
        ]),
      ]),
    ]);
    expect(a.snap.task.visibility).toBe('shared');
    expect(a.snap.drafts[0]!.payload).toMatchObject({
      date: '2026-10-16',
      time: null,
      assigneeUid: null,
    });
    const b = await run(
      'nhắc bố đi lấy kết quả tối nay',
      [
        extraction([
          intent('reminder', { title: 'đi lấy kết quả', assigneeText: 'bố' }, [
            { field: 'title', text: 'đi lấy kết quả' },
            { field: 'assigneeText', text: 'bố' },
          ]),
        ]),
      ],
      { answers: { 'reminder.assignee': { choiceId: DAD } } },
    );
    expect(b.asked).toEqual(['reminder.assignee.0']);
    const q = (await snapshot(b.taskId)).messages
      .flatMap((m) => m.parts)
      .find((p) => p.type === 'clarification');
    expect(
      q && q.type === 'clarification' && q.clarification.choices.map((c) => c.id).sort(),
    ).toEqual([DAD, MOM, NANNY, 'none'].sort());
    expect(b.snap.drafts[0]!.payload).toMatchObject({ date: '2026-10-15', assigneeUid: DAD });
  });

  it('a caregiver cannot create reminders (notice, released); medicine is never scheduled', async () => {
    const n = await run(
      'nhắc 4 giờ chiều nay đón bé',
      [
        extraction([
          intent('reminder', { title: 'đón bé', time: '16:00' }, [
            { field: 'time', text: '4 giờ chiều' },
          ]),
        ]),
      ],
      { uid: NANNY },
    );
    expect(n.snap.task).toMatchObject({
      state: 'failed',
      errorCode: 'WRITE_DENIED',
      usage: 'released',
    });
    const m = await run('nhắc 8h tối cho bé uống thuốc hạ sốt', [
      extraction([intent('reminder', { title: 'cho bé uống thuốc', time: '20:00' })]),
    ]);
    // "sốt" is a health sign: health support first, free, no model.
    expect(m.snap.messages.at(-1)!.parts[0]!.type).toBe('health_support');
    const m2 = await run('nhắc 8h tối cho bé uống siro', [
      extraction([
        intent('reminder', { title: 'cho bé uống siro', time: '20:00' }, [
          { field: 'time', text: '8h tối' },
        ]),
      ]),
    ]);
    expect(m2.snap.drafts).toHaveLength(0);
    expect(codes(m2.snap)).toContain('MEDICINE_NOT_SCHEDULED');
    expect(m2.snap.task).toMatchObject({ state: 'ready', usage: 'released' });
  });
});

describe('duration-aware sleep and feeds', () => {
  it('"Báo ngủ 9 tiếng" at 07:10 asks only when it started (chips never end in the future), computes the end and keeps them linked', async () => {
    const nine = extraction([
      intent('sleep', { durationMin: 540 }, [{ field: 'durationMin', text: '9 tiếng' }]),
    ]);
    const { taskId, snap, asked, gw } = await run('Báo ngủ 9 tiếng', [nine], {
      at: MORNING,
      answers: { 'time.start': { choiceId: 'at_2026-10-14_22:00' } },
    });
    expect(asked).toEqual(['time.start']);
    expect((gw as ReturnType<typeof fakeModelGateway>).calls.extract).toHaveLength(1);
    const q = snap.messages.flatMap((m) => m.parts).find((p) => p.type === 'clarification');
    expect(q && q.type === 'clarification' && q.clarification).toMatchObject({
      field: 'time.start',
      allowText: true,
      question: { vi: 'Bé bắt đầu ngủ lúc mấy giờ?' },
      choices: [
        { id: 'at_2026-10-14_21:00', label: { vi: '21:00 tối qua', en: '21:00 last night' } },
        { id: 'at_2026-10-14_22:00', label: { vi: '22:00 tối qua', en: '22:00 last night' } },
      ],
    });
    const d = snap.drafts[0]!;
    expect(d.payload).toEqual({
      kind: 'sleep',
      startedAt: '2026-10-14T15:00:00.000Z',
      endedAt: '2026-10-15T00:00:00.000Z',
      durationMin: 540,
      linked: { derived: 'endedAt' },
    });
    expect(d.state).toBe('draft');
    // Editing the start: the server keeps the length equal to the two ends.
    const p = await patchDraft(
      deps(null, MORNING),
      MOM,
      E({
        draftId: d.id,
        expectedRevision: 1,
        payload: {
          ...(d.payload as DraftPayload & { kind: 'sleep' }),
          startedAt: '2026-10-14T15:30:00.000Z',
        },
        confirmedFields: [],
      }),
    );
    expect(p.data.draft.payload).toMatchObject({ durationMin: 510 });
    const r = await confirm(taskId, [{ draftId: d.id, revision: 2 }]);
    expect(r.data.items[0]!.status).toBe('saved');
  });

  it('a typed start ("22h") works too; "dậy lúc 6h, ngủ 9 tiếng" computes the start (overnight) without a question', async () => {
    const typed = await run('ngủ 9 tiếng', [extraction([intent('sleep', { durationMin: 540 })])], {
      at: MORNING,
      answers: { 'time.start': { text: '22h' } },
    });
    expect(local((typed.snap.drafts[0]!.payload as { startedAt: string }).startedAt)).toBe(
      '2026-10-14 22:00',
    );
    const woke = await run(
      'dậy lúc 6h, ngủ 9 tiếng',
      [
        extraction([
          intent('sleep', { endTime: '06:00', endDayOffset: 0, durationMin: 540 }, [
            { field: 'endTime', text: '6h' },
            { field: 'durationMin', text: '9 tiếng' },
          ]),
        ]),
      ],
      { at: MORNING },
    );
    expect(woke.asked).toEqual([]);
    const p = woke.snap.drafts[0]!.payload as {
      startedAt: string;
      endedAt: string;
      linked: unknown;
    };
    expect([local(p.startedAt), local(p.endedAt)]).toEqual([
      '2026-10-14 21:00',
      '2026-10-15 06:00',
    ]);
    expect(p.linked).toEqual({ derived: 'startedAt' });
  });

  it('"đêm qua 9h tối đến 6h sáng" keeps its days; "10 giờ tối" said in the morning is last night; never a completed log in the future', async () => {
    const night = await run(
      'đêm qua bé ngủ từ 9h tối đến 6h sáng',
      [
        extraction([
          intent('sleep', { time: '21:00', endTime: '06:00', dayOffset: 0, endDayOffset: 0 }, [
            { field: 'time', text: '9h tối' },
            { field: 'endTime', text: '6h sáng' },
          ]),
        ]),
      ],
      { at: MORNING },
    );
    const n = night.snap.drafts[0]!.payload as {
      startedAt: string;
      endedAt: string;
      durationMin: number;
    };
    expect([local(n.startedAt), local(n.endedAt), n.durationMin]).toEqual([
      '2026-10-14 21:00',
      '2026-10-15 06:00',
      540,
    ]);
    const feed = await run(
      '10 giờ tối bú 90ml',
      [
        extraction([
          intent('bottle', { amountMl: 90, time: '22:00', dayOffset: 0 }, [
            { field: 'time', text: '10 giờ tối' },
          ]),
        ]),
      ],
      { at: MORNING },
    );
    expect(local((feed.snap.drafts[0]!.payload as { occurredAt: string }).occurredAt)).toBe(
      '2026-10-14 22:00',
    );
    const later = await run('bé ngủ từ 13h đến 15h', [
      extraction([intent('sleep', { time: '13:00', endTime: '15:00', dayOffset: 0 })]),
    ]);
    expect(later.snap.drafts[0]!.problems).toContain('FUTURE_TIME');
    expect(later.snap.drafts[0]!.uncertainFields).toContain('endedAt');
  });

  it('"8 giờ" at 14:20 is 08:00 (20:00 would be in the future) with no question; at 21:30 it asks once', async () => {
    const eight = () =>
      extraction([
        intent('bottle', { amountMl: 120, time: '08:00', dayOffset: 0 }, [
          { field: 'time', text: '8 giờ' },
        ]),
      ]);
    const day = await run('8 giờ bú 120ml', [eight()]);
    expect(day.asked).toEqual([]);
    expect(local((day.snap.drafts[0]!.payload as { occurredAt: string }).occurredAt)).toBe(
      '2026-10-15 08:00',
    );
    const evening = await run('8 giờ bú 120ml', [eight()], {
      at: new Date('2026-10-15T14:30:00Z'),
      answers: { 'time.ampm': { choiceId: 'pm' } },
    });
    expect(evening.asked).toEqual(['time.ampm']);
    expect(local((evening.snap.drafts[0]!.payload as { occurredAt: string }).occurredAt)).toBe(
      '2026-10-15 20:00',
    );
  });

  it('no time at all is now on the model path (L9: finished, started unknown → the server takes now, no question); oz → ml; "vừa bú mẹ 20 phút" started 20 minutes ago', async () => {
    // Before L9 the model path asked "Vừa xong / 30 phút trước / 1 tiếng trước" here; the rule
    // reader's path still does (lumi-plan §12.4, L9c unifies them).
    const r = await run('bé bú 120ml', [
      extraction([intent('bottle', { amountMl: 120 }, [{ field: 'amountMl', text: '120ml' }])]),
    ]);
    expect(r.asked).toEqual([]);
    expect(local((r.snap.drafts[0]!.payload as { occurredAt: string }).occurredAt)).toBe(
      '2026-10-15 14:20',
    );
    // L9: "2 tiếng trước" is the model's `started: ago 120` (v9), no longer a regex of the server.
    const oz = await run('2 tiếng trước bé bú 4oz', [
      {
        act: 'log',
        target: null,
        confidence: 0.9,
        events: [
          {
            kind: 'bottle',
            status: 'finished',
            started: { how: 'ago', minutes: 120, hhmm: null, dayOffset: null },
            ended: null,
            durationMin: null,
            fields: { amountMl: 4, milk: null },
            evidence: [
              { field: 'amountMl', text: '4oz' },
              { field: 'started', text: '2 tiếng trước' },
            ],
            uncertainFields: [],
          },
        ],
        reads: [],
        ask: null,
        care: null,
        healthSigns: [],
      },
    ]);
    expect(oz.snap.drafts[0]!.payload).toMatchObject({ amountMl: 118 });
    expect(local((oz.snap.drafts[0]!.payload as { occurredAt: string }).occurredAt)).toBe(
      '2026-10-15 12:20',
    );
    const br = await run('vừa bú mẹ 20 phút cả hai bên', [
      extraction([
        intent('breast', { durationMin: 20, side: 'both', time: '14:20', dayOffset: 0 }),
      ]),
    ]);
    expect(br.snap.drafts[0]!.payload).toMatchObject({
      durationMin: 20,
      side: 'both',
      linked: { derived: 'occurredAt' },
    });
    expect(local((br.snap.drafts[0]!.payload as { occurredAt: string }).occurredAt)).toBe(
      '2026-10-15 14:00',
    );
  });
});

describe('follow-ups, duplicates, small talk, help — credits per outcome', () => {
  it('"à không, 150ml" replaces the previous unsaved draft; a saved one is never changed', async () => {
    const first = await run('bé bú 120ml lúc 8h sáng', [
      extraction([
        intent('bottle', { amountMl: 120, time: '08:00', dayOffset: 0 }, [
          { field: 'amountMl', text: '120ml' },
          { field: 'time', text: '8h sáng' },
        ]),
      ]),
    ]);
    const fix = await run('à không, 150ml', [
      (input: ExtractInput) => {
        // L7: the server resolves "à không, 150ml" itself; were the model asked, the dialogue
        // state would travel (kinds, values and local times; no words, no ids).
        expect(input.previous).toMatchObject({
          text: null,
          drafts: [{ kind: 'bottle', amountMl: 120, occurredAt: { time: '08:00', dayOffset: 0 } }],
        });
        return extraction([
          intent(
            'bottle',
            { amountMl: 150, time: '08:00', dayOffset: 0 },
            [
              { field: 'amountMl', text: '150ml' },
              { field: 'time', text: '8h sáng' },
            ],
            true,
          ),
        ]);
      },
    ]);
    expect(fix.snap.drafts[0]!.payload).toMatchObject({ amountMl: 150 });
    expect(local((fix.snap.drafts[0]!.payload as { occurredAt: string }).occurredAt)).toBe(
      '2026-10-15 08:00',
    );
    expect(codes(fix.snap)).toContain('CORRECTION_APPLIED');
    expect((await snapshot(first.taskId)).drafts[0]).toMatchObject({
      state: 'discarded',
      errorCode: 'REPLACED',
    });
    // Lumi L7 (P-168 #2): saved, then corrected minutes later — an edit draft of that record
    // (0 credits, no model); saving it changes the record, never a second feed.
    const again = await run('bé bú 90ml lúc 9h sáng', [
      extraction([
        intent('bottle', { amountMl: 90, time: '09:00', dayOffset: 0 }, [
          { field: 'time', text: '9h sáng' },
        ]),
      ]),
    ]);
    const saved = await confirm(again.taskId, [{ draftId: again.snap.drafts[0]!.id, revision: 1 }]);
    const recordId = saved.data.items[0]!.recordId!;
    const late = await run('à 100ml chứ', []);
    expect(late.snap.drafts).toHaveLength(1);
    expect(late.snap.drafts[0]).toMatchObject({
      op: 'update',
      targetRecordId: recordId,
      payload: { kind: 'bottle', amountMl: 100 },
    });
    expect(late.snap.task.credits).toBe(0);
    const edited = await confirm(late.taskId, [{ draftId: late.snap.drafts[0]!.id, revision: 1 }]);
    expect(edited.data.items[0]).toMatchObject({ status: 'saved', recordId });
    const rec = await db.doc(`babies/${B}/records/${recordId}`).get();
    expect(rec.get('data')).toMatchObject({ amountMl: 100 });
    expect(rec.get('deleted')).toBe(false);
  });

  it('a feed like one just logged is a warning; confirm needs "Vẫn lưu"', async () => {
    await db.doc(`babies/${B}/records/r_${'7'.repeat(32)}`).set({
      id: `r_${'7'.repeat(32)}`,
      babyId: B,
      type: 'bottle',
      occurredAt: Timestamp.fromDate(new Date('2026-10-15T01:00:00Z')),
      endedAt: null,
      data: { amountMl: 120, milk: 'formula' },
      createdBy: DAD,
      author: { name: 'Huy', relation: 'father', relationCustom: null },
      createdAt: Timestamp.fromDate(NOW),
      clientCreatedAt: Timestamp.fromDate(NOW),
      updatedAt: Timestamp.fromDate(NOW),
      updatedBy: DAD,
      deleted: false,
      deletedAt: null,
      deletedBy: null,
      source: 'app',
    });
    const { taskId, snap } = await run('bé bú 120ml lúc 8h sáng', [
      extraction([
        intent('bottle', { amountMl: 120, time: '08:00', dayOffset: 0 }, [
          { field: 'time', text: '8h sáng' },
        ]),
      ]),
    ]);
    expect(snap.drafts[0]!.warnings).toEqual(['duplicate_suspected']);
    expect(codes(snap)).toContain('DUPLICATE_SUSPECTED');
    const first = await confirm(taskId, [{ draftId: snap.drafts[0]!.id, revision: 1 }]);
    expect(first.data.items[0]).toMatchObject({
      status: 'conflict',
      errorCode: 'DUPLICATE_SUSPECTED',
    });
    const ok = await confirm(taskId, [
      { draftId: snap.drafts[0]!.id, revision: 1, acknowledge: ['duplicate_suspected'] },
    ]);
    expect(ok.data.items[0]!.status).toBe('saved');
  });

  it('credits per outcome: small talk 0 (no model), help 0, a question holds 1, drafts 1, health 0', async () => {
    const gw = fakeModelGateway({});
    const talk = await start('cảm ơn Lumi', { gw });
    expect(talk.data.task).toMatchObject({ state: 'ready', credits: 0, usage: 'none' });
    expect(gw.calls.extract).toHaveLength(0);
    const ts = await snapshot(talk.taskId!);
    expect(codes(ts)).toEqual(['SMALL_TALK']);
    const help = await run('thời tiết hôm nay thế nào?', [extraction([], { outOfScope: true })]);
    expect(help.snap.task).toMatchObject({ state: 'ready', usage: 'released' });
    expect(codes(help.snap)).toEqual(['HELP']);
    // L9: the model's "xem hay ghi?" question is gone (v9 has no `intent` ask); words with
    // nothing to log get the help text at once, released.
    const unsure = await run('giúp mình với', [
      extraction([], { clarification: { field: 'intent' } }),
    ]);
    expect(unsure.asked).toEqual([]);
    expect(unsure.snap.task).toMatchObject({ state: 'ready', usage: 'released' });
    expect(codes(unsure.snap)).toEqual(['HELP']);
    // L9: a feed without a time is drafted at now; a length with no start still asks (held).
    const held = await run('ngủ 9 tiếng', [extraction([intent('sleep', { durationMin: 540 })])]);
    expect(held.snap.task).toMatchObject({ state: 'awaiting_clarification', usage: 'reserved' });
    const meal = await run('con 7 tháng ăn gì được?', [
      extraction([], { clarification: { field: 'intent' } }),
    ]);
    // Safety net: a food question is the meal-ideas care topic, never "read or log?".
    expect(meal.asked).toEqual([]);
    expect(meal.snap.task.usage).toBe('released');
    const health = await start('bé sốt cao', { gw });
    expect(health.data.task).toMatchObject({ state: 'ready', credits: 0 });
    // 1 held (the open question); small talk, help, meal fallback and health cost nothing.
    expect(await win()).toMatchObject({ used: 0, reserved: 1 });
  });
});

// =====================================================================================
describe('meals in the Ăn dặm diary (Lumi L5)', () => {
  const published = {
    status: 'published',
    revision: 1,
    review: { reviewer: 'TEST_ONLY', credential: 'TEST_ONLY', reviewedOn: '2026-10-19' },
    illustrative: false,
    reviewDueOn: '2027-10-20',
    publishedAt: '2026-10-19T00:00:00.000Z',
    firstPublishedAt: '2026-10-19T00:00:00.000Z',
  };
  const porridge = () =>
    extraction([
      intent('meal', { title: 'cháo bí đỏ', time: '11:30' }, [
        { field: 'title', text: 'cháo bí đỏ' },
        { field: 'time', text: '11h30' },
      ]),
    ]);
  const diaryOn = () =>
    db.doc(`babies/${B}/solids/settings`).set({ enabled: true, method: 'mixed' });

  it('"trưa nay bé ăn cháo bí đỏ lúc 11h30" → a meal draft; confirm writes a valid diary meal with the food', async () => {
    await diaryOn();
    await db
      .doc('contentFoods/fd_pumpkin')
      .set(contentFoodSchema.parse({ id: 'fd_pumpkin', ...foodFixture(), ...published }));
    const { taskId, snap } = await run('trưa nay bé ăn cháo bí đỏ lúc 11h30', [porridge()]);
    expect(snap.drafts[0]!.payload).toEqual({
      kind: 'meal',
      recipeId: null,
      title: 'cháo bí đỏ',
      occurredAt: '2026-10-15T04:30:00.000Z',
    });
    expect(snap.drafts[0]).toMatchObject({ state: 'draft', uncertainFields: [] });
    const r = await confirm(taskId, [{ draftId: snap.drafts[0]!.id, revision: 1 }], NANNY);
    expect(r.data.items[0]).toMatchObject({ status: 'saved' });
    const id = r.data.items[0]!.recordId!;
    expect(r.data.items[0]!.recordLink).toBe(`/care/solids/meal/${id}`);
    const m = (await db.doc(`babies/${B}/meals/${id}`).get()).data()!;
    const dates = Object.fromEntries(
      ['occurredAt', 'createdAt', 'clientCreatedAt', 'updatedAt'].map((k) => [
        k,
        (m[k] as Timestamp).toDate(),
      ]),
    );
    expect(mealSchema.safeParse({ ...m, ...dates }).success).toBe(true);
    expect(m).toMatchObject({
      slot: 'noon',
      dish: 'cháo bí đỏ',
      foodIds: ['fd_pumpkin'],
      createdBy: NANNY,
      author: { name: 'Cô Hoa', relation: 'nanny', relationCustom: null },
      deleted: false,
    });
    // A second confirm is the same meal (never a second one).
    const again = await confirm(taskId, [{ draftId: snap.drafts[0]!.id, revision: 1 }], NANNY);
    expect(again.data.items[0]!.recordId).toBe(id);
    expect((await db.collection(`babies/${B}/meals`).get()).size).toBe(1);
  });

  it('with the diary off: no draft, a notice that links to Ăn dặm; nothing written', async () => {
    const { snap } = await run('trưa nay bé ăn cháo bí đỏ lúc 11h30', [porridge()]);
    expect(snap.drafts).toEqual([]);
    const notice = snap.messages
      .flatMap((m) => m.parts)
      .find((p) => p.type === 'text' && p.link === '/care/solids');
    expect(notice).toBeDefined();
    expect((await db.collection(`babies/${B}/meals`).get()).empty).toBe(true);
  });
});
