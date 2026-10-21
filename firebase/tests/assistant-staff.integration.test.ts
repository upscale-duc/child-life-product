import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  assistantSwitches,
  assistantTaskLookup,
  assistantUsageOverview,
  percentile,
} from '../functions/src/assistant-staff.js';
import { babyCode } from '../functions/src/premium-ops.js';
import { familyCode, setFlag, StaffError, type Staff } from '../functions/src/staff.js';

// Portal "Trợ lý AI" (slice A6): usage aggregates, one task for support and the assistant kill
// switches through the existing flag path. Own project; synthetic `test_` data.
const projectId = 'demo-child-life-assistant-staff';
const now = new Date('2026-10-15T05:00:00Z');
const owner: Staff = { uid: 's_owner', name: 'Owner', roles: ['owner'] };
const ops: Staff = { uid: 's_ops', name: 'Vận hành', roles: ['ops'] };
const eng: Staff = { uid: 's_eng', name: 'Kỹ sư Minh', roles: ['eng'] };
const support: Staff = { uid: 's_support', name: 'Hỗ trợ', roles: ['support'] };
const analyst: Staff = { uid: 's_analyst', name: 'Phân tích', roles: ['analyst'] };

const fa = 'test_fa';
const fb = 'test_fb';
const fc = 'test_fc';
const babyA = 'test_baby_a';
const hex = (c: string) => c.repeat(32);
const tkA = `tk_${hex('a')}`;
const tkB = `tk_${hex('b')}`;
const tkC = `tk_${hex('c')}`;
const tkD = `tk_${hex('d')}`;
const tkOld = `tk_${hex('e')}`;
const tkBeta = `tk_${hex('f')}`;
const freeWindow = 'assistant_cal_2026-10';
const premiumWindow = 'assistant_paid_promo_x1_2026-10-01';
const betaWindow = 'assistant_paid_campaign-beta1_2026-10-01';

/** Things that must never reach a staff answer. */
const secrets = [
  fa,
  fb,
  fc,
  babyA,
  'test_mom_uid',
  'Mẹ Mai',
  'Bé Na bú 120 ml lúc 8 giờ',
  'SECRET_NOTE',
  'ANSWER_SECRET',
  'sốt cao',
  'assistant/test_mom_uid',
  'babies/',
  'PAYLOAD_SECRET',
];
const expectMasked = (answer: unknown) => {
  const json = JSON.stringify(answer);
  for (const s of secrets) expect(json, s).not.toContain(s);
};

let app: App;
let db: Firestore;

const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: unknown) => (e instanceof StaffError ? e.reason : String(e)),
  );
const ago = (ms: number) => Timestamp.fromMillis(now.getTime() - ms);
const H = 3_600_000;
const D = 24 * H;

beforeAll(() => {
  app = initializeApp({ projectId }, `assistant-staff-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});

async function task(id: string, familyId: string, fields: Record<string, unknown>) {
  await db.doc(`assistantTasks/${id}`).set({
    id,
    ownerUid: 'test_mom_uid',
    familyId,
    scope: { type: 'child', babyId: babyA },
    conversationId: `cv_${babyA}`,
    visibility: 'shared',
    author: { uid: 'test_mom_uid', name: 'Mẹ Mai', relation: 'mother', relationCustom: null },
    requestId: randomUUID(),
    input: { text: 'Bé Na bú 120 ml lúc 8 giờ', attachmentIds: [] },
    anchorInstant: ago(H),
    timezone: 'Asia/Ho_Chi_Minh',
    locale: 'vi',
    modality: 'text',
    round: 0,
    clarifications: [],
    pendingClarification: null,
    lease: null,
    attempt: 0,
    health: null,
    credits: 1,
    plan: 'free',
    windowId: null,
    reservationId: null,
    usage: 'none',
    errorCode: null,
    version: 1,
    createdAt: ago(H),
    updatedAt: ago(H),
    ...fields,
  });
}

async function op(
  familyId: string,
  id: string,
  windowId: string,
  state: 'reserved' | 'committed' | 'released',
  units: number,
  reservedAt: Timestamp,
  feature = 'assistant',
) {
  await db.doc(`families/${familyId}/quotaOps/${id}`).set({
    reservationId: id,
    familyId,
    feature,
    windowId,
    windowIds: [windowId],
    features: [feature],
    state,
    requestId: randomUUID(),
    holder: id,
    units,
    createdAt: reservedAt,
    updatedAt: reservedAt,
    reservedAt,
    committedAt: state === 'committed' ? reservedAt : null,
    releasedAt: state === 'released' ? reservedAt : null,
    ...(state === 'released' ? { releaseReason: 'unreadable' } : {}),
  });
}

beforeEach(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080';
  await fetch(`http://${host}/emulator/v1/projects/${projectId}/databases/(default)/documents`, {
    method: 'DELETE',
  });
  await db.doc('config/ai').set({ monthlyBudgetVnd: 1_000_000, month: '2026-10', spentVnd: 1200 });

  // A: text drafts, committed on the Free window, model called (4 s to ready).
  await task(tkA, fa, {
    state: 'ready',
    windowId: freeWindow,
    reservationId: `assistant_${tkA}`,
    usage: 'committed',
    outcome: { kind: 'drafts', drafts: 1, parts: ['draft_reference'] },
    modelCalls: 1,
    model: 'openai:gpt-4.1-mini',
    promptVersion: 'assistant-v3',
    policyVersion: 'assistant-qa-v3/policy-v2',
    readyAt: Timestamp.fromMillis(now.getTime() - H + 4000),
    round: 1,
    clarifications: [
      {
        id: 'cl_1',
        field: 'time.ampm',
        round: 1,
        answer: { choiceId: null, text: 'ANSWER_SECRET' },
      },
    ],
  });
  await db.doc(`assistantTasks/${tkA}/drafts/dr_${hex('a')}_0`).set({
    id: `dr_${hex('a')}_0`,
    taskId: tkA,
    ownerUid: 'test_mom_uid',
    itemIndex: 0,
    scope: { type: 'child', babyId: babyA },
    payload: { kind: 'bottle', ml: 120, note: 'SECRET_NOTE' },
    missingFields: [],
    uncertainFields: ['time'],
    revision: 2,
    state: 'saved',
    expiresAt: Timestamp.fromMillis(now.getTime() + D),
    warnings: ['overlap'],
    errorCode: null,
    savedAt: ago(H / 2),
    confirmedBy: { uid: 'test_mom_uid', name: 'Mẹ Mai' },
  });
  for (const [i, type] of ['accepted', 'progress', 'drafts_ready', 'usage_updated'].entries()) {
    await db.doc(`assistantTasks/${tkA}/events/${String(i + 1).padStart(8, '0')}`).set({
      taskId: tkA,
      eventId: `${tkA}:${i + 1}`,
      sequence: i + 1,
      type,
      emittedAt: ago(H - i * 1000),
      payload: { note: 'PAYLOAD_SECRET' },
    });
  }
  await op(fa, `assistant_${tkA}`, freeWindow, 'committed', 1, ago(H));
  // An AI summary charged to the same Free pool (D-075 #1).
  await op(fa, 'su_test_summary1', freeWindow, 'committed', 1, ago(2 * D));
  await db.doc(`families/${fa}/quota/${freeWindow}`).set({
    feature: 'assistant',
    scope: 'calendar_month',
    limit: 20,
    used: 20,
    reserved: 0,
    resetsAt: new Date('2026-10-31T17:00:00Z'),
  });

  // B: a photo the model could not read, released on a Premium window.
  await task(tkB, fb, {
    modality: 'image',
    visibility: 'private',
    scope: { type: 'household', babyId: babyA },
    state: 'failed',
    errorCode: 'OCR_UNREADABLE',
    credits: 3,
    plan: 'premium',
    windowId: premiumWindow,
    reservationId: `assistant_${tkB}`,
    usage: 'released',
    outcome: { kind: 'unreadable', drafts: 0, parts: ['text'] },
    modelCalls: 1,
    model: 'openai:gpt-4.1-mini',
    promptVersion: 'image-v1',
    input: { text: '', attachmentIds: ['at_x'] },
  });
  await db.doc('assistantAttachments/at_x').set({
    id: 'at_x',
    ownerUid: 'test_mom_uid',
    taskId: tkB,
    storagePath: 'assistant/test_mom_uid/at_x',
    state: 'deleted',
    retention: 'delete_after_read',
    rejected: false,
    deletedAt: ago(H / 2),
  });
  await op(fb, `assistant_${tkB}`, premiumWindow, 'released', 3, ago(3 * D));

  // C: health support at start (0 credits, no outcome, no model).
  await task(tkC, fa, { state: 'ready', credits: 0, health: ['sốt cao'], readyAt: ago(H) });
  // D: blocked at 0 credits.
  await task(tkD, fa, { state: 'blocked', errorCode: 'USAGE_EXHAUSTED', usage: 'none' });
  // A beta household with a credit still held.
  await task(tkBeta, fc, {
    state: 'processing',
    plan: 'premium',
    windowId: betaWindow,
    reservationId: `assistant_${tkBeta}`,
    usage: 'reserved',
  });
  await op(fc, `assistant_${tkBeta}`, betaWindow, 'reserved', 1, ago(H));
  await db.doc(`families/${fc}/quota/${betaWindow}`).set({
    feature: 'assistant',
    scope: 'paid',
    limit: 200,
    used: 0,
    reserved: 1,
    resetsAt: new Date('2026-10-31T17:00:00Z'),
  });

  // Outside the period or another feature: not counted.
  await task(tkOld, fa, { state: 'ready', createdAt: ago(40 * D), modelCalls: 5 });
  await op(fa, 'assistant_old', freeWindow, 'committed', 1, ago(40 * D));
  await op(fa, 'video_ksj_1_0', 'video_cal_2026-10', 'committed', 1, ago(H), 'video');
});

describe('staffAssistantUsage', () => {
  it('needs premium.view; non-staff and other roles are refused', async () => {
    expect(await reason(assistantUsageOverview(db, null, now))).toBe('not-staff');
    expect(await reason(assistantUsageOverview(db, support, now))).toBe('role');
    expect(await reason(assistantUsageOverview(db, analyst, now))).toBe('role');
    expect(await reason(assistantUsageOverview(db, ops, now))).toBe('ok');
  });

  it('aggregates the pool by budget, credits per day, tasks and model counters', async () => {
    const u = await assistantUsageOverview(db, ops, now);
    expect(u.truncated).toEqual({ tasks: false, ops: false });
    expect(u.since).toBe('2026-09-15T17:00:00.000Z');
    const free = u.pool.find((p) => p.plan === 'free')!;
    expect(free).toEqual({
      plan: 'free',
      committed: 2,
      released: 0,
      held: 0,
      chat: 1,
      summaries: 1,
      households: 1,
      exhausted: 1,
    });
    expect(u.pool.find((p) => p.plan === 'premium')).toMatchObject({
      committed: 0,
      released: 3,
      households: 1,
      exhausted: 0,
    });
    expect(u.pool.find((p) => p.plan === 'beta')).toMatchObject({
      held: 1,
      households: 1,
      exhausted: 0,
    });
    expect(u.daily).toHaveLength(30);
    expect(u.daily.at(-1)).toEqual({ day: '2026-10-15', committed: 1, released: 0 });
    expect(u.daily.reduce((n, d) => n + d.committed, 0)).toBe(2);
    expect(u.daily.reduce((n, d) => n + d.released, 0)).toBe(3);

    expect(u.tasks.total).toBe(5);
    expect(u.tasks.byState).toEqual({ ready: 2, failed: 1, blocked: 1, processing: 1 });
    expect(u.tasks.byModality).toEqual({ text: 4, image: 1 });
    expect(u.tasks.byOutcome).toEqual({ drafts: 1, unreadable: 1, none: 3 });
    expect(u.tasks.health).toBe(1);
    expect(u.tasks.errors).toEqual([
      { code: 'OCR_UNREADABLE', count: 1 },
      { code: 'USAGE_EXHAUSTED', count: 1 },
    ]);
    expect(u.model.calls).toBe(2);
    expect(u.model.tasksWithCalls).toBe(2);
    expect(u.model.estimatedCostVnd).toBe(300 + 900);
    expect(u.model.byModel).toEqual([
      { model: 'openai:gpt-4.1-mini', promptVersion: 'assistant-v3', tasks: 1, calls: 1 },
      { model: 'openai:gpt-4.1-mini', promptVersion: 'image-v1', tasks: 1, calls: 1 },
    ]);
    expect(u.model.timeToReady).toEqual({ samples: 1, p50Ms: 4000, p95Ms: 4000 });
    expect(u.budget.spentVnd).toBe(1200);
    expect(u.credits).toMatchObject({ free: 20, premium: 200, aiSummaryCredits: 1, stored: false });
    expectMasked(u);
  });

  it('percentile is nearest-rank', () => {
    expect(percentile([], 0.5)).toBeNull();
    expect(percentile([1, 2, 3, 4], 0.5)).toBe(2);
    expect(percentile([1, 2, 3, 4], 0.95)).toBe(4);
  });
});

describe('staffAssistantTask', () => {
  it('needs premium.view and a well-formed, existing task id', async () => {
    expect(await reason(assistantTaskLookup(db, null, { taskId: tkA }))).toBe('not-staff');
    expect(await reason(assistantTaskLookup(db, support, { taskId: tkA }))).toBe('role');
    expect(await reason(assistantTaskLookup(db, ops, { taskId: 'tk_../x' }))).toBe('malformed');
    expect(await reason(assistantTaskLookup(db, ops, { taskId: `tk_${hex('9')}` }))).toBe(
      'no-task',
    );
  });

  it('shows states, codes, counts and times; never text, payloads, answers or ids', async () => {
    const t = await assistantTaskLookup(db, ops, { taskId: ` ${tkA} ` });
    expect(t).toMatchObject({
      taskId: tkA,
      family: familyCode(fa),
      baby: babyCode(babyA),
      scope: 'child',
      visibility: 'shared',
      state: 'ready',
      modality: 'text',
      plan: 'free',
      pool: 'free',
      credits: 1,
      usage: 'committed',
      errorCode: null,
      outcome: { kind: 'drafts', drafts: 1, parts: ['draft_reference'] },
      health: false,
      round: 1,
      clarifications: [{ field: 'time.ampm', round: 1, answered: true }],
      modelCalls: 1,
      model: 'openai:gpt-4.1-mini',
      promptVersion: 'assistant-v3',
      readyAt: new Date(now.getTime() - H + 4000).toISOString(),
    });
    expect(t.reservation).toMatchObject({
      id: 'assistant_tk_aaaaaaaa…',
      window: freeWindow,
      units: 1,
      state: 'committed',
    });
    expect(t.drafts).toEqual([
      expect.objectContaining({
        kind: 'bottle',
        state: 'saved',
        revision: 2,
        uncertainFields: ['time'],
        warnings: ['overlap'],
      }),
    ]);
    expect(t.events.map((e) => e.type)).toEqual([
      'accepted',
      'progress',
      'drafts_ready',
      'usage_updated',
    ]);
    expect(t.attachments).toEqual([]);
    expectMasked(t);

    const b = await assistantTaskLookup(db, owner, { taskId: tkB });
    expect(b).toMatchObject({
      scope: 'household',
      visibility: 'private',
      modality: 'image',
      pool: 'premium',
      errorCode: 'OCR_UNREADABLE',
      reservation: { state: 'released', units: 3, releaseReason: 'unreadable' },
      attachments: [
        { state: 'deleted', retention: 'delete_after_read', rejected: false, deleted: true },
      ],
    });
    expectMasked(b);

    const c = await assistantTaskLookup(db, ops, { taskId: tkC });
    expect(c).toMatchObject({ health: true, outcome: null, reservation: null, credits: 0 });
    expectMasked(c);
  });
});

describe('staffAssistantSwitches', () => {
  it('reads the six flags for features.view; others are refused', async () => {
    expect(await reason(assistantSwitches(db, null))).toBe('not-staff');
    expect(await reason(assistantSwitches(db, analyst))).toBe('role');
    const s = await assistantSwitches(db, ops);
    expect(Object.keys(s.flags)).toEqual([
      'assistant',
      'assistant_live',
      'assistant_images',
      'assistant_care',
      'assistant_writes',
      'assistant_upsell',
    ]);
    expect(s.flags.assistant.enabled).toBe(false);
    expect(s.recent).toEqual([]);
  });

  it('a toggle goes through staffSetFlag: flags.toggle, a reason, and the audit log', async () => {
    const on = {
      key: 'assistant_live',
      enabled: true,
      scope: 'all',
      percent: 100,
      notice: null,
      reason: 'mở cho QA',
    };
    // Vận hành sees the switches but may not flip them (no reason is needed since D-090).
    expect(await reason(setFlag(db, ops, on, now))).toBe('role');
    await setFlag(db, eng, on, now);
    await setFlag(
      db,
      eng,
      { ...on, enabled: false, notice: 'Trợ lý tạm dừng', reason: 'nhà cung cấp lỗi' },
      new Date(now.getTime() + 60_000),
    );
    const flags = (await db.doc('config/flags').get()).data()!;
    expect(flags.assistant_live).toMatchObject({ enabled: false, notice: 'Trợ lý tạm dừng' });
    const audit = await db.collection('staffAudit').where('target', '==', 'assistant_live').get();
    expect(audit.docs.map((a) => a.get('action')).sort()).toEqual(['flags.off', 'flags.on']);
    for (const a of audit.docs) {
      expect(a.get('category')).toBe('features');
      expect(a.get('actorUid')).toBe('s_eng');
    }
    const s = await assistantSwitches(db, ops);
    expect(s.flags.assistant_live.enabled).toBe(false);
    expect(s.lastEdit.assistant_live?.by).toBe('Kỹ sư Minh');
    expect(s.recent.map((r) => [r.action, r.reason])).toEqual([
      ['flags.off', 'nhà cung cấp lỗi'],
      ['flags.on', 'mở cho QA'],
    ]);
  });
});
