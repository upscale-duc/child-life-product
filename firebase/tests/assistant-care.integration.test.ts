import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  assistantConsentVersion,
  defaultEntitlementsConfig,
  defaultFlags,
  type Activity,
  type AssistantPart,
  type Recipe,
  type RhythmContent,
} from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  confirmDrafts,
  discardDraft,
  getAssistantTask,
  quoteTask,
  setAssistantConsent,
  startTask,
  submitAssistantFeedback,
  submitClarification,
  type AssistantDeps,
} from '../functions/src/assistant.js';
import {
  findRecipes,
  planAssistantActivity,
  startedFeedbackIdFor,
} from '../functions/src/assistant-care.js';
import {
  fakeModelGateway,
  type ExtractInput,
  type FakeStep,
  type ModelGateway,
} from '../functions/src/assistant-model.js';
import { localInstant } from '../functions/src/assistant-tools.js';
import { runAssistantTask } from '../functions/src/assistant-worker.js';
import { readRhythmContent } from '../functions/src/rhythm.js';

// Child Life Assistant, slice A5 care (CH15–CH18, CH28) against the Firestore emulator with a FAKE
// model gateway (scripted outputs only). Journeys J06 (sleep: clarify in the same task → approved
// guidance → optional observation → plan → feedback after the chance, 0 credits) and J07 (Bé Na 7
// months, recorded reaction to egg → excluded, unknown-tolerance caveat), plus health at 0 credits,
// region, kill switch, fallback and "guidance never comes from the model". Content is synthetic
// and marked TEST_ONLY; ids use the `test_` prefix. Fixed clock 2026-10-15T07:20Z = 14:20 Vietnam.
const projectId = 'demo-child-life-assistant-care';
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
  birthDate: string;
  secondChild: { id: string; ageMonths: number; recordedReactionIngredientIds: string[] };
}>('context.json');
const packRecipes = pack<
  {
    id: string;
    ingredientIds: string[];
    minAgeMonths: number;
    approved: boolean;
    region: string;
  }[]
>('recipes.json');

const now = new Date(context.now);
const ZONE = context.timezone;
const F = context.household;
const B = context.child;
const NA = context.secondChild.id;
const MOM = context.actor;
const DAD = 'test_dad';
const GRANDMA = 'test_grandma';
const SCOPE = { type: 'child' as const, babyId: B };
const NA_SCOPE = { type: 'child' as const, babyId: NA };
const WIN = 'assistant_cal_2026-10';
/** 07:30 the next morning in Vietnam (CH17 "Sáng hôm sau · 07:30"). */
const NEXT_MORNING = new Date('2026-10-16T00:30:00Z');

const on = (key: keyof typeof defaultFlags) => ({
  ...defaultFlags[key],
  enabled: true,
  scope: 'all' as const,
});

// ---------- Synthetic content (TEST_ONLY; never shipped) ----------

const L = (vi: string, en = vi) => ({ vi, en });
const REVIEW = {
  reviewer: 'TEST_ONLY reviewer',
  credential: 'TEST_ONLY',
  reviewedOn: '2026-10-01',
};
const activity = (id: string, over: Partial<Activity> = {}): Activity => ({
  id,
  version: 1,
  status: 'published',
  title: L(`TEST_ONLY ${id} vi`, `TEST_ONLY ${id} en`),
  summary: L('TEST_ONLY tóm tắt', 'TEST_ONLY summary'),
  steps: { vi: [`TEST_ONLY ${id} bước 1`, 'TEST_ONLY bước 2'], en: ['TEST_ONLY step 1'] },
  safety: L('TEST_ONLY không khi bé sốt', 'TEST_ONLY not when feverish'),
  durationMin: 30,
  ageDays: { from: 0, to: 365 },
  needs: ['sleep'],
  interests: [],
  timeOfDay: 'evening',
  locales: ['vi', 'en'],
  regions: [],
  sources: [],
  review: null,
  ...over,
});
/** R02 (recipes.json) as content: approved = published + reviewed; one region each. */
const recipes = (): Recipe[] =>
  packRecipes.map((r) => ({
    id: `rcp_${r.id}`,
    version: 1,
    status: 'published',
    title: L(`TEST_ONLY ${r.id}`),
    summary: L('TEST_ONLY'),
    ingredientIds: r.ingredientIds,
    minAgeMonths: r.minAgeMonths,
    regions: [r.region],
    steps: { vi: ['TEST_ONLY'], en: ['TEST_ONLY'] },
    durationMin: 15,
    sources: [],
    review: r.approved ? REVIEW : null,
  }));
const content = (over: Partial<RhythmContent> = {}): RhythmContent => ({
  version: 'rc_20261015_01',
  publishedAt: now.toISOString(),
  activities: [
    activity('act_test_calm', { review: REVIEW }),
    activity('act_test_noise'),
    activity('act_test_nap', { timeOfDay: 'day' }),
    activity('act_test_draft', { status: 'draft' }),
    activity('act_test_us_only', { regions: ['US'] }),
    activity('act_test_older', { ageDays: { from: 400, to: 700 } }),
    activity('act_test_feed', { needs: ['feeding'] }),
  ],
  ageCards: [],
  health: {
    signs: [{ id: 'fever_young', label: L('Sốt'), maxAgeDays: 90 }],
    whileWaiting: { vi: [], en: [] },
    disclaimer: L('TEST_ONLY'),
    regions: [
      { country: 'VN', emergencyNumber: '115' },
      { country: 'US', emergencyNumber: '911' },
    ],
    sources: [],
    review: null,
  },
  recipes: recipes(),
  ...over,
});

// ---------- Fake model outputs ----------

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
type CareOut = {
  topic: 'sleep_concern' | 'meal_ideas';
  sleep: { kind: string | null; when: string | null; since: string | null } | null;
  evidence: { field: string; text: string }[];
};
const extraction = (
  o: {
    intents?: unknown[];
    reads?: { tool: string; dayOffset: number }[];
    clarification?: { field: string } | null;
    care?: CareOut | null;
    healthSigns?: string[];
  } = {},
) => ({
  intents: o.intents ?? [],
  reads: o.reads ?? [],
  clarification: o.clarification ?? null,
  care: o.care ?? null,
  healthSigns: o.healthSigns ?? [],
});
const sleepConcern = (
  sleep: CareOut['sleep'] = null,
  evidence: CareOut['evidence'] = [],
  clarification: { field: string } | null = null,
) => extraction({ care: { topic: 'sleep_concern', sleep, evidence }, clarification });
const mealIdeas = () => extraction({ care: { topic: 'meal_ideas', sleep: null, evidence: [] } });
const bottle = (ml: number, time: string, text: string) => ({
  kind: 'bottle',
  fields: { ...F0, amountMl: ml, time, dayOffset: 0, milk: 'formula' },
  evidence: [
    { field: 'amountMl', text: `${ml} ml` },
    { field: 'time', text },
  ],
  uncertainFields: [],
  missingFields: [],
});

// ---------- Helpers ----------

const E = (over: Record<string, unknown> = {}) => ({
  contractVersion: 1,
  clientRequestId: randomUUID(),
  locale: 'vi',
  ...over,
});
const deps = (gateway: ModelGateway | null = fakeModelGateway({}), at = now): AssistantDeps => ({
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

async function start(
  text: string,
  o: { uid?: string; gw?: ModelGateway; scope?: typeof SCOPE; at?: Date } = {},
) {
  const uid = o.uid ?? MOM;
  const gw = o.gw ?? fakeModelGateway({});
  const scope = o.scope ?? SCOPE;
  const q = await quoteTask(
    deps(gw, o.at),
    uid,
    E({
      conversationId: null,
      scope,
      modality: 'text',
      attachmentCount: 0,
      intentHint: null,
    }),
  );
  return startTask(
    deps(gw, o.at),
    uid,
    E({
      conversationId: null,
      scope,
      quoteId: q.data.quoteId,
      text,
      attachmentIds: [],
    }),
  );
}

const work = (
  taskId: string,
  gateway: ModelGateway | null,
  o: { at?: Date; reactions?: string[] } = {},
) =>
  runAssistantTask(
    {
      db,
      now: o.at ?? now,
      environment: 'test',
      gateway,
      timeoutMs: 500,
      ...(o.reactions ? { careFixtures: { reactionIngredientIds: o.reactions } } : {}),
    },
    taskId,
  );

async function snapshot(taskId: string, uid = MOM, at = now) {
  return (await getAssistantTask(deps(null, at), uid, E({ taskId, afterSequence: null }))).data;
}

/** Start + run one round with [script]. */
async function run(
  text: string,
  script: FakeStep<ExtractInput>[],
  o: { uid?: string; scope?: typeof SCOPE; reactions?: string[]; word?: unknown[] } = {},
) {
  const gw = fakeModelGateway({ extract: script, word: o.word ?? [] });
  const r = await start(text, {
    gw,
    ...(o.uid ? { uid: o.uid } : {}),
    ...(o.scope ? { scope: o.scope } : {}),
  });
  await work(r.taskId!, gw, o.reactions ? { reactions: o.reactions } : {});
  return { taskId: r.taskId!, gw, snap: await snapshot(r.taskId!, o.uid ?? MOM) };
}

async function answer(taskId: string, choiceId: string, gw: ModelGateway, uid = MOM) {
  const s = await snapshot(taskId, uid);
  await submitClarification(
    deps(gw),
    uid,
    E({
      taskId,
      expectedVersion: s.task.version,
      clarificationId: s.task.clarification!.id,
      choiceId,
      text: null,
    }),
  );
  await work(taskId, gw);
  return snapshot(taskId, uid);
}

const lastParts = (s: { messages: { parts: AssistantPart[] }[] }) => s.messages.at(-1)!.parts;
const partOf = <T extends AssistantPart['type']>(parts: AssistantPart[], type: T) =>
  parts.find((p) => p.type === type) as Extract<AssistantPart, { type: T }> | undefined;
const win = async () =>
  (await db.doc(`families/${F}/quota/${WIN}`).get()).data() ?? { used: 0, reserved: 0 };
const opsDocs = async () => (await db.collection(`families/${F}/quotaOps`).get()).docs;
const feedbackDocs = async (baby = B) =>
  (await db.collection(`babies/${baby}/recFeedback`).get()).docs;

async function setConfig(o: { free?: number; regions?: string[] } = {}) {
  await db.doc('config/entitlements').set({
    ...defaultEntitlementsConfig,
    regions: { advanced: o.regions ?? ['VN'] },
    quotas: {
      ...defaultEntitlementsConfig.quotas,
      assistant: { ...defaultEntitlementsConfig.quotas.assistant, free: o.free ?? 20 },
    },
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

/** Sleep records for one local day: [from, to] "HH:mm" pairs (24:00 = next midnight). */
async function seedSleepDay(date: string, spans: [string, string][]) {
  for (const [i, [from, to]] of spans.entries()) {
    const id = `test_s_${date.replace(/-/g, '')}_${i}`;
    const end =
      to === '24:00'
        ? localInstant(
            ZONE,
            new Date(Date.parse(`${date}T12:00:00Z`) + 86_400_000).toISOString().slice(0, 10),
            '00:00',
          )
        : localInstant(ZONE, date, to);
    await db.doc(`babies/${B}/records/${id}`).set({
      id,
      babyId: B,
      type: 'sleep',
      occurredAt: Timestamp.fromDate(localInstant(ZONE, date, from)),
      endedAt: Timestamp.fromDate(end),
      data: {},
      deleted: false,
      source: 'app',
    });
  }
}

beforeAll(() => {
  app = initializeApp({ projectId }, `assistant-care-${randomUUID()}`);
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
    assistant_care: on('assistant_care'),
    rhythm: on('rhythm'),
  });
  await setConfig();
  await db.doc('publicConfig/content_rhythm').set(content());
  await db.doc(`families/${F}`).set({ ownerUid: MOM, country: 'VN', timeZone: ZONE });
  // Teddy: 28 days old on 15/10 (pack birthDate). Bé Na: 7 months (born 10/03/2026).
  for (const [baby, dob] of [
    [B, context.birthDate],
    [NA, '2026-03-10'],
  ] as const) {
    await db.doc(`babies/${baby}`).set({
      familyId: F,
      timeZone: { mode: 'auto', zone: ZONE },
      state: 'active',
    });
    await db.doc(`babies/${baby}/restricted/profile`).set({ dateOfBirth: dob });
    await db
      .doc(`babies/${baby}/members/${MOM}`)
      .set(member('coParent', 'mother', 'Mai', { isOwner: true }));
  }
  await db.doc(`babies/${B}/members/${DAD}`).set(member('coParent', 'father', 'Huy'));
  await db.doc(`babies/${B}/members/${GRANDMA}`).set(member('relative', 'grandmother', 'Bà'));
  for (const uid of [MOM, DAD, GRANDMA]) {
    await setAssistantConsent(deps(), uid, E({ consent: { version: assistantConsentVersion } }));
  }
});

// =====================================================================================
describe('J06 sleep: clarify in the same task → approved guidance → optional observation → feedback', () => {
  it('J06: two short questions in one task and one credit; guidance from content only; plan ≠ tried; feedback 0 credits', async () => {
    const gw = fakeModelGateway({ extract: [sleepConcern(), sleepConcern(), sleepConcern()] });
    const r = await start('Con hôm nay khó ngủ', { gw });
    const taskId = r.taskId!;
    await work(taskId, gw);

    // CH15 round 1: khó vào giấc / hay thức giấc (server catalog), reservation held.
    let s = await snapshot(taskId);
    expect(s.task).toMatchObject({ state: 'awaiting_clarification', usage: 'reserved', round: 1 });
    expect(s.task.clarification!.field).toBe('sleep.period');
    expect(s.task.clarification!.choices.map((c) => c.id)).toEqual([
      'falling_asleep',
      'night_waking',
      'both',
    ]);
    expect(s.task.care).toMatchObject({ topic: 'sleep_concern', guidance: null });
    expect(await win()).toMatchObject({ used: 0, reserved: 1 });

    // Round 2: ngày / đêm. Same task, same reservation.
    s = await answer(taskId, 'falling_asleep', gw);
    expect(s.task).toMatchObject({ state: 'awaiting_clarification', round: 2 });
    expect(s.task.clarification!.field).toBe('sleep.when');
    expect(await win()).toMatchObject({ used: 0, reserved: 1 });

    // CH16: approved guidance for a night concern + optional observation draft.
    s = await answer(taskId, 'night', gw);
    expect(s.task).toMatchObject({ state: 'ready', usage: 'committed', round: 2 });
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
    expect(await opsDocs()).toHaveLength(1);
    const parts = lastParts(s);
    const g = partOf(parts, 'approved_content')!;
    const calm = content().activities[0]!;
    expect(g).toMatchObject({
      contentId: 'act_test_calm',
      contentVersion: 1,
      reviewed: true,
      reasonCode: 'SELF_REPORTED_NEED',
      alternatives: [{ contentId: 'act_test_noise', contentVersion: 1 }],
    });
    // The card's words are the published item's, never the model's.
    expect(g.content).toEqual({
      title: calm.title.vi,
      summary: calm.summary.vi,
      steps: calm.steps.vi,
      safety: calm.safety!.vi,
      durationMin: 30,
      timeOfDay: 'evening',
    });
    expect(g.reason).toBe('Vì sao: bạn chọn “khó vào giấc, giấc đêm”.');
    expect(g.reason).not.toMatch(/Wonder|tuần khủng hoảng|\d/);
    expect(gw.calls.word).toHaveLength(0);
    expect(gw.calls.extract).toHaveLength(3);
    expect(gw.calls.extract[2]!.clarifications).toEqual([
      { field: 'sleep.period', answer: 'falling_asleep' },
      { field: 'sleep.when', answer: 'night' },
    ]);
    // G01: an observation (check-in) draft, not a reminder; optional.
    expect(s.drafts).toHaveLength(1);
    expect(s.drafts[0]).toMatchObject({
      state: 'draft',
      payload: {
        kind: 'observation',
        observation: 'sleep',
        date: '2026-10-15',
        when: 'night',
        note: null,
      },
    });
    expect(parts.map((p) => p.type)).toEqual(['approved_content', 'draft_reference']);
    expect(s.task.care).toMatchObject({
      sleep: { kind: 'falling_asleep', when: 'night', since: null },
      guidance: { contentId: 'act_test_calm', reasonCode: 'SELF_REPORTED_NEED', reviewed: true },
      plan: null,
      followUp: null,
    });

    // "Lưu ghi nhận": the person chooses to save it (0 extra credits).
    const saved = await confirmDrafts(
      deps(null),
      MOM,
      E({ taskId, selected: [{ draftId: s.drafts[0]!.id, revision: 1, acknowledge: [] }] }),
    );
    expect(saved.data.items[0]!.status).toBe('saved');
    expect((await db.collection(`babies/${B}/checkins`).get()).size).toBe(1);

    // "Thử tối nay": an intention — recFeedback `started` + a plan, 0 credits, no model.
    const plan = await planAssistantActivity(
      deps(null),
      MOM,
      E({ taskId, contentId: 'act_test_calm', contentVersion: 1 }),
    );
    expect(plan.data.plan).toMatchObject({
      contentId: 'act_test_calm',
      plannedFor: '2026-10-15',
      // 05:00 on 16/10 in Vietnam.
      feedbackOpensAt: '2026-10-15T22:00:00.000Z',
    });
    const started = (await feedbackDocs()).map((d) => d.data());
    expect(started).toHaveLength(1);
    expect(started[0]).toMatchObject({
      id: startedFeedbackIdFor(MOM, taskId, 'act_test_calm', 1),
      kind: 'started',
      authorUid: MOM,
      date: '2026-10-15',
    });

    // Not asked as tried just because "Thử tối nay" was tapped: no follow-up yet, tried refused.
    expect((await snapshot(taskId)).task.care!.followUp).toBeNull();
    expect(
      await reason(
        submitAssistantFeedback(
          deps(null),
          MOM,
          E({ taskId, contentId: 'act_test_calm', contentVersion: 1, outcome: 'helpful' }),
        ),
      ),
    ).toBe('INVALID_STATE');

    // CH17 the next morning: the question never says "đã thử" and always offers "Chưa thử".
    const morning = (await snapshot(taskId, MOM, NEXT_MORNING)).task.care!.followUp!;
    expect(morning.question.vi).toContain('có dịp thử');
    expect(morning.question.vi).not.toContain('đã thử “');
    expect(morning.question.en).not.toMatch(/you tried/i);
    expect(morning.choices.map((c) => c.id)).toEqual([
      'helpful',
      'unsure',
      'not_suitable',
      'not_tried',
    ]);
    const fb = await submitAssistantFeedback(
      deps(null, NEXT_MORNING),
      MOM,
      E({ taskId, contentId: 'act_test_calm', contentVersion: 1, outcome: 'helpful' }),
    );
    expect(fb.data.outcome).toBe('helpful');
    expect((await feedbackDocs()).map((d) => d.get('kind')).sort()).toEqual(['helpful', 'started']);
    const after = await snapshot(taskId, MOM, NEXT_MORNING);
    expect(after.task.care).toMatchObject({ feedback: { outcome: 'helpful' }, followUp: null });
    // Feedback and plan: 0 credits, no model call.
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
    expect(gw.calls.extract).toHaveLength(3);

    // Feedback only on this task's guidance.
    expect(
      await reason(
        submitAssistantFeedback(
          deps(null, NEXT_MORNING),
          MOM,
          E({ taskId, contentId: 'act_test_noise', contentVersion: 1, outcome: 'unsure' }),
        ),
      ),
    ).toBe('VALIDATION_FAILED');

    // The same day again: the check-in exists, so no second observation draft is offered.
    const again = await run('Con vẫn khó ngủ', [
      sleepConcern({ kind: 'falling_asleep', when: 'night', since: null }, [
        { field: 'kind', text: 'khó ngủ' },
        { field: 'when', text: 'khó ngủ' },
      ]),
    ]);
    expect(again.snap.task.state).toBe('ready');
    expect(again.snap.drafts).toHaveLength(0);
  });

  it('"Chưa thử" is recorded only on the task: nothing tried is written to the module', async () => {
    const { taskId } = await run('Con hay thức đêm', [
      sleepConcern({ kind: 'night_waking', when: 'night', since: null }, [
        { field: 'kind', text: 'hay thức' },
        { field: 'when', text: 'đêm' },
      ]),
    ]);
    await planAssistantActivity(
      deps(null),
      MOM,
      E({ taskId, contentId: 'act_test_calm', contentVersion: 1 }),
    );
    // "Chưa thử" is accepted before and after the chance.
    const nt = await submitAssistantFeedback(
      deps(null, NEXT_MORNING),
      MOM,
      E({ taskId, contentId: 'act_test_calm', contentVersion: 1, outcome: 'not_tried' }),
    );
    expect(nt.data.feedbackId).toBeNull();
    expect((await feedbackDocs()).map((d) => d.get('kind'))).toEqual(['started']);
    const t = (await db.doc(`assistantTasks/${taskId}`).get()).data()!;
    expect(t.feedback).toEqual([
      expect.objectContaining({ contentId: 'act_test_calm', outcome: 'not_tried' }),
    ]);
    expect((await snapshot(taskId, MOM, NEXT_MORNING)).task.care).toMatchObject({
      feedback: { outcome: 'not_tried' },
      followUp: null,
    });
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
  });

  it('a concern fully stated in the words asks nothing; a fact without evidence is asked', async () => {
    const full = await run('Con hay thức đêm', [
      sleepConcern({ kind: 'night_waking', when: 'night', since: null }, [
        { field: 'kind', text: 'hay thức' },
        { field: 'when', text: 'đêm' },
      ]),
    ]);
    expect(full.snap.task).toMatchObject({ state: 'ready', round: 0 });
    expect(partOf(lastParts(full.snap), 'approved_content')!.reason).toBe(
      'Vì sao: bạn chọn “hay thức giấc, giấc đêm”.',
    );
    // The model claims "khó vào giấc" with evidence the person never wrote: asked instead.
    const ungrounded = await run('Con khó ngủ', [
      sleepConcern({ kind: 'falling_asleep', when: 'night', since: null }, [
        { field: 'kind', text: 'khó vào giấc' },
        { field: 'when', text: 'buổi tối' },
      ]),
    ]);
    expect(ungrounded.snap.task.state).toBe('awaiting_clarification');
    expect(ungrounded.snap.task.clarification!.field).toBe('sleep.period');
  });

  it('naps pick a daytime item; an unreviewed item says reviewed:false; onset only when asked, skippable', async () => {
    const gw = fakeModelGateway({
      extract: [
        sleepConcern(null, [], { field: 'sleep.onset' }),
        sleepConcern(null, [], { field: 'sleep.onset' }),
        sleepConcern(null, [], { field: 'sleep.onset' }),
        sleepConcern(null, [], { field: 'sleep.onset' }),
      ],
    });
    const r = await start('Con ngủ ngày khó', { gw });
    await work(r.taskId!, gw);
    let s = await answer(r.taskId!, 'both', gw);
    expect(s.task.clarification!.field).toBe('sleep.when');
    s = await answer(r.taskId!, 'day', gw);
    expect(s.task.clarification!.field).toBe('sleep.onset');
    expect(s.task.clarification!.choices.map((c) => c.id)).toContain('unsure');
    s = await answer(r.taskId!, 'unsure', gw);
    // Four runs in one task: the attempt cap is per run (fix), so the 4th round still settles.
    expect(s.task).toMatchObject({ state: 'ready', round: 3 });
    expect(gw.calls.extract).toHaveLength(4);
    expect(partOf(lastParts(s), 'approved_content')).toMatchObject({
      contentId: 'act_test_nap',
      reviewed: false,
    });
    expect(s.task.care!.sleep).toEqual({ kind: 'both', when: 'day', since: null });
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
  });

  it('logged sleep supports the reason only on valid days showing less sleep (DATA_INSIGHT); never a cause', async () => {
    const base: [string, string][] = [
      ['00:00', '06:00'],
      ['08:00', '10:00'],
      ['12:00', '14:00'],
      ['16:00', '17:00'],
      ['19:00', '24:00'],
    ];
    const recent: [string, string][] = [
      ['00:00', '04:00'],
      ['08:00', '10:00'],
      ['12:00', '14:00'],
      ['16:00', '17:00'],
      ['20:00', '24:00'],
    ];
    for (let d = 17; d >= 1; d -= 1) {
      const date = new Date(Date.UTC(2026, 9, 15 - d)).toISOString().slice(0, 10);
      await seedSleepDay(date, d <= 3 ? recent : base);
    }
    const words = [
      { field: 'kind', text: 'khó vào giấc' },
      { field: 'when', text: 'đêm' },
    ];
    const facts = { kind: 'falling_asleep', when: 'night', since: null };
    const mom = await run('Con khó vào giấc ban đêm', [sleepConcern(facts, words)]);
    const g = partOf(lastParts(mom.snap), 'approved_content')!;
    expect(g.reasonCode).toBe('DATA_INSIGHT');
    expect(g.reason).toBe(
      'Vì sao: bạn chọn “khó vào giấc, giấc đêm”. Nhật ký các ngày ghi đầy đủ: gần đây khoảng 780 phút ngủ mỗi ngày, trước đó khoảng 960 phút.',
    );
    expect(g.reason).not.toMatch(/Wonder|nguyên nhân|vì bé đang/);
    // A relative without "Chăm sóc hằng ngày" gets the guidance but not the log, nor a draft.
    const grandma = await run('Con khó vào giấc ban đêm', [sleepConcern(facts, words)], {
      uid: GRANDMA,
    });
    expect(grandma.snap.task.state).toBe('ready');
    expect(partOf(lastParts(grandma.snap), 'approved_content')!.reasonCode).toBe(
      'SELF_REPORTED_NEED',
    );
    expect(grandma.snap.drafts).toHaveLength(0);
  });

  it('"Không cần": the optional observation is discarded; nothing written, no refund, no extra charge', async () => {
    const { taskId, snap } = await run('Con hay thức đêm', [
      sleepConcern({ kind: 'night_waking', when: 'night', since: null }, [
        { field: 'kind', text: 'hay thức' },
        { field: 'when', text: 'đêm' },
      ]),
    ]);
    const d = snap.drafts[0]!;
    const out = await discardDraft(deps(null), MOM, E({ draftId: d.id, expectedRevision: 1 }));
    expect(out.data.draft.state).toBe('discarded');
    expect((await db.collection(`babies/${B}/checkins`).get()).size).toBe(0);
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
    expect((await snapshot(taskId)).task.care!.guidance).not.toBeNull();
  });
});

// =====================================================================================
describe('guidance never comes from the model', () => {
  it('a model output carrying advice is rejected: 0 credits, no approved content', async () => {
    const withAdvice = {
      ...sleepConcern(),
      care: {
        topic: 'sleep_concern',
        sleep: null,
        evidence: [],
        advice: 'Cho bé uống 5 ml siro ngủ ngon',
      },
    };
    const { snap } = await run('Con khó ngủ', [withAdvice]);
    expect(snap.task).toMatchObject({
      state: 'failed',
      errorCode: 'VALIDATION_FAILED',
      usage: 'released',
    });
    expect(lastParts(snap).some((p) => p.type === 'approved_content')).toBe(false);
    expect(JSON.stringify(lastParts(snap))).not.toContain('siro');
    expect(await win()).toMatchObject({ used: 0, reserved: 0 });
  });

  it('the wording step is never used for care: scripted instructions never reach the person', async () => {
    const { snap, gw } = await run(
      'Con hay thức đêm',
      [
        sleepConcern({ kind: 'night_waking', when: 'night', since: null }, [
          { field: 'kind', text: 'hay thức' },
          { field: 'when', text: 'đêm' },
        ]),
      ],
      { word: [{ text: 'Hãy cho bé uống siro và bế ru 2 tiếng.' }] },
    );
    expect(gw.calls.word).toHaveLength(0);
    expect(JSON.stringify(snap.messages)).not.toContain('siro');
    const g = partOf(lastParts(snap), 'approved_content')!;
    expect(g.content!.steps).toEqual(content().activities[0]!.steps.vi);
  });

  it('no eligible content: an honest fallback, never generated advice; released (0 credits)', async () => {
    // Only feeding and out-of-age items: nothing fits a sleep concern at 28 days.
    await db.doc('publicConfig/content_rhythm').set(
      content({
        activities: [
          activity('act_test_feed', { needs: ['feeding'] }),
          activity('act_test_older', { ageDays: { from: 400, to: 700 } }),
          activity('act_test_us_only', { regions: ['US'] }),
          activity('act_test_draft', { status: 'draft' }),
        ],
      }),
    );
    const { snap } = await run('Con hay thức đêm', [
      sleepConcern({ kind: 'night_waking', when: 'night', since: null }, [
        { field: 'kind', text: 'hay thức' },
        { field: 'when', text: 'đêm' },
      ]),
    ]);
    expect(snap.task).toMatchObject({ state: 'ready', usage: 'released', errorCode: null });
    expect(lastParts(snap)).toEqual([
      {
        type: 'text',
        schemaVersion: 1,
        text: 'Chưa có gợi ý đã duyệt phù hợp với con lúc này. Bạn có thể xem Thư viện chăm bé.',
        code: 'CARE_NO_APPROVED_CONTENT',
      },
    ]);
    expect(snap.drafts).toHaveLength(0);
    expect(await win()).toMatchObject({ used: 0, reserved: 0 });
    // Without a date of birth no age-based content is chosen.
    await db.doc(`babies/${B}/restricted/profile`).delete();
    const noAge = await run('Con hay thức đêm', [
      sleepConcern({ kind: 'night_waking', when: 'night', since: null }, [
        { field: 'kind', text: 'hay thức' },
        { field: 'when', text: 'đêm' },
      ]),
    ]);
    expect(noAge.snap.task).toMatchObject({ state: 'ready', usage: 'released' });
    expect(partOf(lastParts(noAge.snap), 'text')).toMatchObject({ code: 'CARE_AGE_UNKNOWN' });
  });
});

// =====================================================================================
describe('J07 meals: approved recipes, recorded-reaction exclusion, unknown tolerance', () => {
  it('J07: Bé Na 7 months, recorded reaction to egg → egg recipe excluded; caveat; 1 credit, no write', async () => {
    const { snap, gw } = await run('Hôm nay con ăn gì?', [mealIdeas()], {
      scope: NA_SCOPE,
      reactions: context.secondChild.recordedReactionIngredientIds,
    });
    expect(snap.task).toMatchObject({ state: 'ready', usage: 'committed', round: 0 });
    const list = partOf(lastParts(snap), 'recipe_list')!;
    expect(list.recipeIds).toEqual(['rcp_test_recipe_1']);
    expect(list.excludedCount).toBe(1);
    expect(list.mealLogAvailable).toBe(false);
    expect(list.items![0]).toMatchObject({
      recipeId: 'rcp_test_recipe_1',
      recipeVersion: 1,
      minAgeMonths: 6,
      why: 'Từ 6 tháng · đã được chuyên môn duyệt',
    });
    expect(list.caveat).toContain('không phải chẩn đoán dị ứng');
    expect(list.caveat).toContain('không có nghĩa là con đã dung nạp tốt');
    expect(snap.drafts).toHaveLength(0);
    expect(gw.calls.word).toHaveLength(0);
    expect(snap.task.care).toMatchObject({ topic: 'meal_ideas', recipeIds: ['rcp_test_recipe_1'] });
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
    expect((await db.collection(`babies/${NA}/records`).get()).size).toBe(0);
  });

  it('today no module records reactions: the egg recipe stays and the caveat says tolerance is unknown', async () => {
    const { snap } = await run('Hôm nay con ăn gì?', [mealIdeas()], { scope: NA_SCOPE });
    const list = partOf(lastParts(snap), 'recipe_list')!;
    expect(list.recipeIds).toEqual(['rcp_test_recipe_1', 'rcp_test_recipe_2']);
    expect(list.excludedCount).toBe(0);
    expect(list.caveat).toContain('chưa có nhật ký ăn dặm');
    expect(list.caveat).toContain('không có nghĩa là con đã dung nạp tốt');
  });

  it('R02 against the real tool and a seeded content document', async () => {
    const pub = (await readRhythmContent(db))!;
    const out = findRecipes({
      recipes: pub.recipes!,
      ageMonths: context.secondChild.ageMonths,
      country: 'VN',
      reactionIngredientIds: context.secondChild.recordedReactionIngredientIds,
      locale: 'vi',
    });
    expect(out.items.map((i) => i.recipeId)).toEqual(['rcp_test_recipe_1']);
    // Without reactions: the egg recipe; unapproved (#4), 9 months (#3) and US (#5) never.
    expect(
      findRecipes({
        recipes: pub.recipes!,
        ageMonths: 7,
        country: 'VN',
        reactionIngredientIds: [],
        locale: 'en',
      }).items.map((i) => i.recipeId),
    ).toEqual(['rcp_test_recipe_1', 'rcp_test_recipe_2']);
    expect(
      findRecipes({
        recipes: pub.recipes!,
        ageMonths: 9,
        country: 'VN',
        reactionIngredientIds: [],
        locale: 'en',
      }).items.map((i) => i.recipeId),
    ).toEqual(['rcp_test_recipe_3', 'rcp_test_recipe_1', 'rcp_test_recipe_2']);
  });

  it('no approved recipe: an empty list and "chưa có công thức được duyệt", released; never for a 4-week-old', async () => {
    const { recipes: _r, ...withoutRecipes } = content();
    void _r;
    await db.doc('publicConfig/content_rhythm').set(withoutRecipes);
    const none = await run('Hôm nay con ăn gì?', [mealIdeas()], { scope: NA_SCOPE });
    expect(none.snap.task).toMatchObject({ state: 'ready', usage: 'released' });
    expect(lastParts(none.snap)).toEqual([
      {
        type: 'recipe_list',
        schemaVersion: 1,
        recipeIds: [],
        caveat: null,
        items: [],
        excludedCount: 0,
        mealLogAvailable: false,
      },
      {
        type: 'text',
        schemaVersion: 1,
        text: 'Chưa có công thức được duyệt phù hợp với con.',
        code: 'RECIPES_NONE_APPROVED',
      },
    ]);
    await db.doc('publicConfig/content_rhythm').set(content());
    const teddy = await run('Hôm nay con ăn gì?', [mealIdeas()]);
    expect(partOf(lastParts(teddy.snap), 'recipe_list')!.recipeIds).toEqual([]);
    expect(await win()).toMatchObject({ used: 0, reserved: 0 });
  });
});

// =====================================================================================
describe('health: free, regional number only, independent of care and credits', () => {
  it('at 0 credits and with care off: health support with the approved number (VN 115)', async () => {
    await setConfig({ free: 0 });
    await db.doc('config/flags').set({
      assistant: on('assistant'),
      assistant_live: on('assistant_live'),
      rhythm: on('rhythm'),
    });
    const gw = fakeModelGateway({});
    const r = await start('Con sốt 38.5 độ, thở rít', { gw });
    expect(r.data.task).toMatchObject({ state: 'ready', credits: 0, usage: 'none' });
    expect(lastParts(await snapshot(r.taskId!))).toEqual([
      {
        type: 'health_support',
        schemaVersion: 1,
        signs: ['breathing', 'fever_young'],
        emergency: { country: 'VN', number: '115' },
      },
    ]);
    expect(gw.calls.extract).toHaveLength(0);
    expect(await opsDocs()).toHaveLength(0);
  });

  it('a country without an approved entry gets no number — never a default hotline', async () => {
    await db.doc(`families/${F}`).set({ ownerUid: MOM, country: 'TH', timeZone: ZONE });
    const r = await start('Bé co giật');
    const h = partOf(lastParts(await snapshot(r.taskId!)), 'health_support')!;
    expect(h.signs).toEqual(['seizure']);
    expect(h).not.toHaveProperty('emergency');
  });

  it('structured health signs from the model route to health support; the credit is released', async () => {
    const { snap, gw } = await run('Con cứ mê man từ sáng', [
      extraction({
        healthSigns: ['lethargic'],
        care: { topic: 'sleep_concern', sleep: null, evidence: [] },
      }),
    ]);
    expect(snap.task).toMatchObject({ state: 'ready', usage: 'released' });
    expect(lastParts(snap)).toEqual([
      {
        type: 'health_support',
        schemaVersion: 1,
        signs: ['lethargic'],
        emergency: { country: 'VN', number: '115' },
      },
    ]);
    expect(gw.calls.word).toHaveLength(0);
    expect(await win()).toMatchObject({ used: 0, reserved: 0 });
  });
});

// =====================================================================================
describe('kill switch and region', () => {
  it('assistant_care off: no guidance or recipes (released); logging still drafts', async () => {
    await db.doc('config/flags').set({
      assistant: on('assistant'),
      assistant_live: on('assistant_live'),
      assistant_writes: on('assistant_writes'),
      rhythm: on('rhythm'),
    });
    const care = await run('Con khó ngủ', [sleepConcern()]);
    expect(care.snap.task).toMatchObject({
      state: 'failed',
      errorCode: 'FEATURE_DISABLED',
      usage: 'released',
    });
    expect(partOf(lastParts(care.snap), 'text')).toMatchObject({ code: 'CARE_FEATURE_DISABLED' });
    expect(lastParts(care.snap).some((p) => p.type === 'clarification')).toBe(false);
    const meal = await run('Hôm nay con ăn gì?', [mealIdeas()], { scope: NA_SCOPE });
    expect(meal.snap.task.errorCode).toBe('FEATURE_DISABLED');
    expect(lastParts(meal.snap).some((p) => p.type === 'recipe_list')).toBe(false);
    const log = await run('8 giờ sáng con bú 120 ml', [
      extraction({ intents: [bottle(120, '08:00', '8 giờ sáng')] }),
    ]);
    expect(log.snap.task.state).toBe('ready');
    expect(log.snap.drafts.map((d) => d.payload.kind)).toEqual(['bottle']);
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
  });

  it('region unsupported: REGION_UNSUPPORTED blocks care guidance, never logging in the same message', async () => {
    await db.doc(`families/${F}`).set({ ownerUid: MOM, country: 'US', timeZone: ZONE });
    const care = await run('Con khó ngủ', [sleepConcern()]);
    expect(care.snap.task).toMatchObject({
      state: 'failed',
      errorCode: 'REGION_UNSUPPORTED',
      usage: 'released',
    });
    expect(partOf(lastParts(care.snap), 'text')).toMatchObject({
      code: 'REGION_UNSUPPORTED',
      text: 'Gợi ý chăm sóc qua chat chưa mở ở khu vực của hộ. Ghi nhanh và hỏi dữ liệu vẫn dùng được.',
    });
    const both = await run('Con khó ngủ, 8 giờ sáng bú 120 ml', [
      extraction({
        intents: [bottle(120, '08:00', '8 giờ sáng')],
        care: { topic: 'sleep_concern', sleep: null, evidence: [] },
      }),
    ]);
    expect(both.snap.task).toMatchObject({ state: 'ready', usage: 'committed' });
    expect(both.snap.drafts.map((d) => d.payload.kind)).toEqual(['bottle']);
    expect(lastParts(both.snap).map((p) => p.type)).toEqual(['text', 'draft_reference']);
    expect(await win()).toMatchObject({ used: 1, reserved: 0 });
  });

  it('planning and feedback stay 0 credits and need the feedback role', async () => {
    const { taskId } = await run(
      'Con hay thức đêm',
      [
        sleepConcern({ kind: 'night_waking', when: 'night', since: null }, [
          { field: 'kind', text: 'hay thức' },
          { field: 'when', text: 'đêm' },
        ]),
      ],
      { uid: GRANDMA },
    );
    expect(
      await reason(
        planAssistantActivity(
          deps(null),
          GRANDMA,
          E({ taskId, contentId: 'act_test_calm', contentVersion: 1 }),
        ),
      ),
    ).toBe('WRITE_DENIED');
    const mom = await run('Con hay thức đêm', [
      sleepConcern({ kind: 'night_waking', when: 'night', since: null }, [
        { field: 'kind', text: 'hay thức' },
        { field: 'when', text: 'đêm' },
      ]),
    ]);
    expect(
      await reason(
        planAssistantActivity(
          deps(null),
          MOM,
          E({ taskId: mom.taskId, contentId: 'act_test_noise', contentVersion: 1 }),
        ),
      ),
    ).toBe('VALIDATION_FAILED');
    const req = E({ taskId: mom.taskId, contentId: 'act_test_calm', contentVersion: 1 });
    const a = await planAssistantActivity(deps(null), MOM, req);
    const b = await planAssistantActivity(deps(null), MOM, req);
    expect(b.data).toEqual(a.data);
    expect((await feedbackDocs()).filter((d) => d.get('kind') === 'started')).toHaveLength(1);
    expect(
      await reason(
        planAssistantActivity(
          deps(null),
          DAD,
          E({ taskId: mom.taskId, contentId: 'act_test_calm', contentVersion: 1 }),
        ),
      ),
    ).toBe('NOT_MEMBER');
    expect(await win()).toMatchObject({ used: 2, reserved: 0 });
  });
});
