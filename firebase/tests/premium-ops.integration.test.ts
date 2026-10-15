import { randomUUID } from 'node:crypto';
import {
  aiConsentVersion,
  aiSummaryPromptVersion,
  defaultEntitlementsConfig,
  defaultFlags,
} from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  aiPolicy,
  babyCode,
  familyQuota,
  ledgerIssue,
  renderJobCode,
  renderOps,
  shortHashes,
} from '../functions/src/premium-ops.js';
import { familyCode, type Staff } from '../functions/src/staff.js';

// Premium operations on the portal (plan §5.6, brief "Portal cần thêm"): AI policy, render jobs,
// one family's quota and billing. Own project; synthetic `test_` data; read-only callables.
const projectId = 'demo-child-life-premium-ops';
const now = new Date('2026-10-15T05:00:00Z');
const owner: Staff = { uid: 's_owner', name: 'Owner', roles: ['owner'] };
const ops: Staff = { uid: 's_ops', name: 'Vận hành', roles: ['ops'] };
const support: Staff = { uid: 's_support', name: 'Hỗ trợ', roles: ['support'] };
const analyst: Staff = { uid: 's_analyst', name: 'Phân tích', roles: ['analyst'] };
const familyId = 'test_f1';
const babyId = 'test_b1';
const code = familyCode(familyId);
const hash = (c: string) => c.repeat(40);
const accountId = `apple_${hash('a')}`;
const otherAccount = `google_${hash('b')}`;
const jobA = `ksj_${'1'.repeat(32)}`;
const jobB = `ksj_${'2'.repeat(32)}`;
const jobC = `ksj_${'3'.repeat(32)}`;
/** Things that must never reach a staff answer. */
const secrets = [
  familyId,
  babyId,
  'Bé Na',
  'Lời nhắn bí mật',
  'media_secret',
  'babies/',
  'test_mom',
  'store-transaction-123',
  'com.childlife.app',
  hash('a'),
  'sk-test-key',
];
let app: App;
let db: Firestore;

const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason,
  );
const at = (iso: string) => new Date(iso);
const expectMasked = (answer: unknown) => {
  const json = JSON.stringify(answer);
  for (const s of secrets) expect(json).not.toContain(s);
};

beforeAll(() => {
  app = initializeApp({ projectId }, `premium-ops-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});

async function job(
  id: string,
  fields: Record<string, unknown>,
  op: { state: string } | null,
  seq = 0,
) {
  const reservationId = `video_${id}_${seq}`;
  await db.doc(`babies/${babyId}/keepsakeJobs/${id}`).set({
    id,
    uid: 'test_mom',
    babyId,
    familyId,
    requestId: randomUUID(),
    templateId: 'ch1-birthday',
    templateVersion: 3,
    mediaIds: ['media_secret'],
    audience: 'family',
    occasion: 'birthday',
    musicId: null,
    input: { caption: 'Lời nhắn bí mật', name: 'Bé Na', photos: [`babies/${babyId}/media/x`] },
    step: null,
    progress: 0,
    attempts: 0,
    error: null,
    output: null,
    memoryId: null,
    quota: { reservationId, windowId: 'video_cal_2026-10', seq },
    lease: 0,
    startedAt: null,
    finishedAt: null,
    ...fields,
  });
  if (op) {
    await db.doc(`families/${familyId}/quotaOps/${reservationId}`).set({
      feature: 'video',
      windowId: 'video_cal_2026-10',
      babyId,
      jobId: id,
      state: op.state,
      reservedAt: now,
    });
  }
}

beforeEach(async () => {
  for (const c of [
    'babies',
    'families',
    'config',
    'familyDirectory',
    'appEventsDaily',
    'aiReports',
    'billingAccounts',
    'billingEvents',
  ]) {
    await db.recursiveDelete(db.collection(c));
  }
  await db.doc(`familyDirectory/${familyId}`).set({ code });
  await db
    .doc(`families/${familyId}`)
    .set({ ownerUid: 'test_mom', country: 'VN', babyIds: [babyId] });
  await db.doc(`babies/${babyId}`).set({ familyId, name: 'Bé Na' });
});

describe('staffAiPolicy', () => {
  beforeEach(async () => {
    await db.doc('config/flags').set({
      ...defaultFlags,
      ai_assist: {
        enabled: true,
        scope: 'internal',
        percent: 0,
        notice: null,
        families: [familyId],
      },
    });
    await db.doc('config/entitlements').set({
      ...defaultEntitlementsConfig,
      quotas: {
        ...defaultEntitlementsConfig.quotas,
        ai: { perBabyPerDay: 2, perFamilyPerMonth: 20 },
      },
    });
    await db
      .doc('config/ai')
      .set({ monthlyBudgetVnd: 1_000_000, month: '2026-10', spentVnd: 4500 });
    await db.doc('appEventsDaily/2026-10-15').set({
      day: '2026-10-15',
      summaryGenerated: 10,
      summaryGenerated__ai: 6,
      summaryGenerated__cache: 1,
      summaryGenerated__fallback: 3,
      summaryFallback: 3,
      summaryFallback__timeout: 1,
      summaryFallback__QUOTA_EXCEEDED: 2,
    });
    await db.doc('appEventsDaily/2026-10-01').set({
      day: '2026-10-01',
      summaryGenerated: 2,
      summaryGenerated__ai: 2,
    });
    // Outside the 30 days.
    await db.doc('appEventsDaily/2026-09-01').set({
      day: '2026-09-01',
      summaryGenerated: 50,
      summaryGenerated__fallback: 50,
      summaryFallback__invalid: 50,
    });
    const report = (id: string, problem: string, status = 'open') =>
      db.doc(`aiReports/${id}`).set({
        id,
        babyId,
        familyId,
        summaryId: 's1',
        reporterUid: 'test_mom',
        problem,
        kind: 'handover',
        method: 'ai',
        status,
        createdAt: now,
      });
    await report('air_1', 'wrong_fact');
    await report('air_2', 'wrong_fact');
    await report('air_3', 'unsafe_advice');
    await report('air_4', 'language', 'closed');
  });

  it('shows the provider, versions, switch, quotas, budget, counters and open reports', async () => {
    const p = await aiPolicy(db, ops, { name: 'openai', model: 'gpt-4.1-mini' }, now);
    expect(p.provider).toEqual({ name: 'openai', model: 'gpt-4.1-mini' });
    expect(p.consentVersion).toBe(aiConsentVersion);
    expect(p.promptVersion).toBe(aiSummaryPromptVersion);
    expect(p.flag).toEqual({ enabled: true, scope: 'internal', percent: 0, families: 1 });
    expect(p.quotas).toEqual({ perBabyPerDay: 2, perFamilyPerMonth: 20, stored: true });
    expect(p.budget).toMatchObject({ monthlyBudgetVnd: 1_000_000, spentVnd: 4500 });
    expect(p.days).toHaveLength(30);
    expect(p.days.at(-1)).toEqual({
      day: '2026-10-15',
      generated: 10,
      ai: 6,
      cache: 1,
      fallback: 3,
    });
    expect(p.totals).toEqual({
      generated: 12,
      ai: 8,
      cache: 1,
      fallback: 3,
      fallbackRate: 3 / 12,
      technicalRate: 1 / 12,
    });
    expect(p.fallbackReasons).toEqual([
      { reason: 'QUOTA_EXCEEDED', count: 2 },
      { reason: 'timeout', count: 1 },
    ]);
    expect(p.reports.open).toBe(3);
    expect(p.reports.byProblem).toEqual({
      wrong_fact: 2,
      wrong_person: 0,
      unsafe_advice: 1,
      language: 0,
      other: 0,
    });
    expectMasked(p);
  });

  it('a template provider has no model; nothing stored = shipped defaults, empty counters', async () => {
    for (const c of ['config', 'appEventsDaily', 'aiReports']) {
      await db.recursiveDelete(db.collection(c));
    }
    const p = await aiPolicy(db, owner, { name: 'template', model: 'gpt-4.1-mini' }, now);
    expect(p.provider).toEqual({ name: 'template', model: null });
    expect(p.flag.enabled).toBe(false);
    expect(p.quotas).toEqual({ ...defaultEntitlementsConfig.quotas.ai, stored: false });
    expect(p.totals.fallbackRate).toBeNull();
    expect(p.fallbackReasons).toEqual([]);
    expect(p.reports.open).toBe(0);
  });

  it('refuses staff without premium.view', async () => {
    const provider = { name: 'template' as const, model: null };
    expect(await reason(aiPolicy(db, support, provider, now))).toBe('role');
    expect(await reason(aiPolicy(db, analyst, provider, now))).toBe('role');
    expect(await reason(aiPolicy(db, null, provider, now))).toBe('not-staff');
  });
});

describe('staffRenderOps', () => {
  beforeEach(async () => {
    await job(
      jobA,
      {
        status: 'failed',
        error: 'render-failed',
        attempts: 2,
        lease: 2,
        createdAt: at('2026-10-15T01:00:00Z'),
        updatedAt: at('2026-10-15T01:20:00Z'),
        startedAt: at('2026-10-15T01:01:00Z'),
        finishedAt: at('2026-10-15T01:20:00Z'),
      },
      // The unit was never given back: a ledger issue the portal points out.
      { state: 'reserved' },
    );
    await job(
      jobB,
      {
        status: 'completed',
        step: 'export',
        progress: 1,
        attempts: 1,
        lease: 1,
        memoryId: 'mem_1',
        output: { path: `babies/${babyId}/media/out/original.mp4` },
        createdAt: at('2026-10-15T02:00:00Z'),
        updatedAt: at('2026-10-15T02:05:00Z'),
        finishedAt: at('2026-10-15T02:05:00Z'),
      },
      { state: 'committed' },
    );
    await job(
      jobC,
      {
        status: 'rendering',
        step: 'compose',
        progress: 0.4,
        attempts: 1,
        lease: 1,
        createdAt: at('2026-10-15T04:00:00Z'),
        updatedAt: at('2026-10-15T04:01:00Z'),
        startedAt: at('2026-10-15T04:01:00Z'),
      },
      { state: 'reserved' },
      1,
    );
  });

  it('lists jobs newest first with reservation state, ledger issues and failure codes', async () => {
    const r = await renderOps(db, support, now);
    expect(r.jobs.map((j) => j.code)).toEqual([jobC, jobB, jobA].map(renderJobCode));
    const [c, b, a] = r.jobs;
    expect(c).toMatchObject({
      family: code,
      templateId: 'ch1-birthday',
      templateVersion: 3,
      status: 'rendering',
      step: 'compose',
      attempts: 1,
      lease: 1,
      error: null,
      reservation: {
        id: 'video_ksj_33333333…_1',
        window: 'video_cal_2026-10',
        seq: 1,
        state: 'reserved',
        issue: null,
      },
      createdAt: '2026-10-15T04:00:00.000Z',
      startedAt: '2026-10-15T04:01:00.000Z',
      finishedAt: null,
    });
    expect(b!.reservation).toMatchObject({ state: 'committed', issue: null });
    expect(a).toMatchObject({ status: 'failed', error: 'render-failed', attempts: 2, lease: 2 });
    expect(a!.reservation).toMatchObject({ state: 'reserved', issue: 'not-released' });
    expect(r.kpis).toEqual({ active: 1, failed24h: 1, completed24h: 1, ledgerIssues: 1 });
    expect(r.failures).toEqual({ 'render-failed': 1 });
    expectMasked(r);
  });

  it('a job without its reservation document is flagged as missing', async () => {
    await db.recursiveDelete(db.collection(`families/${familyId}/quotaOps`));
    const r = await renderOps(db, ops, now);
    expect(r.jobs.every((j) => j.reservation?.state === null)).toBe(true);
    expect(r.jobs.every((j) => j.reservation?.issue === 'missing')).toBe(true);
    expect(r.kpis.ledgerIssues).toBe(3);
  });

  it('refuses staff without jobs.view and never writes', async () => {
    expect(await reason(renderOps(db, analyst, now))).toBe('role');
    expect(await reason(renderOps(db, null, now))).toBe('not-staff');
    const before = (await db.collectionGroup('keepsakeJobs').get()).docs.map((d) => d.data());
    await renderOps(db, owner, now);
    const after = (await db.collectionGroup('keepsakeJobs').get()).docs.map((d) => d.data());
    expect(after).toEqual(before);
  });

  it('ledger expectations per job state', () => {
    expect(ledgerIssue({ status: 'queued', memoryId: null }, 'reserved')).toBeNull();
    expect(ledgerIssue({ status: 'queued', memoryId: null }, 'released')).toBe('not-held');
    expect(ledgerIssue({ status: 'failed', memoryId: null }, 'released')).toBeNull();
    expect(ledgerIssue({ status: 'failed', memoryId: null }, 'reserved')).toBe('not-released');
    expect(ledgerIssue({ status: 'completed', memoryId: 'm' }, 'committed')).toBeNull();
    expect(ledgerIssue({ status: 'completed', memoryId: 'm' }, 'reserved')).toBe('not-committed');
    expect(ledgerIssue({ status: 'completed', memoryId: null }, 'reserved')).toBeNull();
    expect(ledgerIssue({ status: 'rendering', memoryId: null }, null)).toBe('missing');
  });
});

describe('staffFamilyQuota', () => {
  beforeEach(async () => {
    const q = (id: string, data: Record<string, unknown>) =>
      db.doc(`families/${familyId}/quota/${id}`).set(data);
    // Video window (video-quota.ts shape).
    await q('video_cal_2026-10', {
      feature: 'video',
      kind: 'free',
      limit: 1,
      used: 0,
      reserved: 1,
      windowStart: at('2026-09-30T17:00:00Z'),
      windowEnd: at('2026-10-31T17:00:00Z'),
      zone: 'Asia/Ho_Chi_Minh',
      grantId: null,
    });
    // AI windows (quota.ts shape).
    await q(`ai_day_${babyId}_2026-10-15`, {
      feature: 'ai_day',
      scope: 'day',
      babyId,
      grantId: null,
      zone: 'Asia/Ho_Chi_Minh',
      limit: 1,
      used: 1,
      reserved: 0,
      startDate: '2026-10-15',
      endDate: '2026-10-16',
      startsAt: at('2026-10-14T17:00:00Z'),
      resetsAt: at('2026-10-15T17:00:00Z'),
    });
    await q('ai_month_cal_2026-10', {
      feature: 'ai_month',
      scope: 'calendar_month',
      babyId: null,
      limit: 10,
      used: 1,
      reserved: 0,
      startsAt: at('2026-09-30T17:00:00Z'),
      resetsAt: at('2026-10-31T17:00:00Z'),
    });
    await q(`video_paid_paid_${accountId}_2026-09-01`, {
      feature: 'video',
      kind: 'paid',
      limit: 5,
      used: 2,
      reserved: 0,
      windowStart: at('2026-09-01T00:00:00Z'),
      windowEnd: at('2026-10-01T00:00:00Z'),
      zone: null,
      grantId: `paid_${accountId}`,
    });
    // Long ended: left out.
    await q('ai_month_cal_2026-01', {
      feature: 'ai_month',
      scope: 'calendar_month',
      limit: 10,
      used: 9,
      reserved: 0,
      resetsAt: at('2026-01-31T17:00:00Z'),
    });
    await db.doc(`families/${familyId}/quotaOps/video_x_0`).set({ state: 'reserved' });
    await db.doc(`families/${familyId}/quotaOps/video_y_0`).set({ state: 'committed' });
    await db.doc(`billingAccounts/${accountId}`).set({
      provider: 'apple',
      familyId,
      billingOwnerUid: 'test_mom',
      environment: 'test',
      productId: 'premium.monthly',
      status: 'active',
      expiresAt: at('2026-11-01T00:00:00Z'),
      autoRenew: true,
      storeRef: 'store-transaction-123',
      packageName: 'com.childlife.app',
      fetchedAt: at('2026-10-01T00:00:00Z'),
      updatedAt: at('2026-10-01T00:00:00Z'),
      boundAt: at('2026-09-01T00:00:00Z'),
    });
    await db.doc(`billingAccounts/${otherAccount}`).set({
      provider: 'google',
      familyId: 'test_other',
      status: 'active',
      environment: 'test',
      storeRef: 'other-token',
    });
    const event = (id: string, account: string, kind: string, receivedAt: string) =>
      db.doc(`billingEvents/${id}`).set({
        provider: account.split('_')[0],
        kind,
        refHash: hash('a'),
        receivedAt: at(receivedAt),
        processedAt: at(receivedAt),
        outcome: 'active',
        account,
      });
    await event('apple_e1', accountId, 'SUBSCRIBED.INITIAL_BUY', '2026-09-01T00:00:00Z');
    await event('apple_e2', accountId, 'DID_RENEW', '2026-10-01T00:00:00Z');
    await event('google_e3', otherAccount, 'SUBSCRIPTION_RENEWED', '2026-10-02T00:00:00Z');
  });

  it('shows open and recent windows, held units, billing accounts and their events', async () => {
    const r = await familyQuota(db, ops, { code }, now);
    expect(r.code).toBe(code);
    expect(r.held).toBe(1);
    expect(r.windows.map((w) => w.window)).toEqual([
      'ai_month_cal_2026-10',
      'video_cal_2026-10',
      `ai_day_${babyCode(babyId)}_2026-10-15`,
      `video_paid_paid_apple_aaaaaaaa…_2026-09-01`,
    ]);
    expect(r.windows[1]).toEqual({
      window: 'video_cal_2026-10',
      feature: 'video',
      scope: 'calendar_month',
      limit: 1,
      used: 0,
      reserved: 1,
      startsAt: '2026-09-30T17:00:00.000Z',
      resetsAt: '2026-10-31T17:00:00.000Z',
      open: true,
    });
    expect(r.windows[2]).toMatchObject({ feature: 'ai_day', scope: 'day', used: 1, open: true });
    expect(r.windows[3]).toMatchObject({ scope: 'paid', limit: 5, used: 2, open: false });
    expect(r.accounts).toEqual([
      {
        id: 'apple_aaaaaaaa…',
        provider: 'apple',
        productId: 'premium.monthly',
        status: 'active',
        validUntil: '2026-11-01T00:00:00.000Z',
        environment: 'test',
        autoRenew: true,
        boundAt: '2026-09-01T00:00:00.000Z',
        fetchedAt: '2026-10-01T00:00:00.000Z',
      },
    ]);
    expect(r.events).toEqual([
      {
        provider: 'apple',
        type: 'DID_RENEW',
        outcome: 'active',
        at: '2026-10-01T00:00:00.000Z',
        processedAt: '2026-10-01T00:00:00.000Z',
      },
      {
        provider: 'apple',
        type: 'SUBSCRIBED.INITIAL_BUY',
        outcome: 'active',
        at: '2026-09-01T00:00:00.000Z',
        processedAt: '2026-09-01T00:00:00.000Z',
      },
    ]);
    expectMasked(r);
    expect(JSON.stringify(r)).not.toContain('other-token');
  });

  it('a family without billing has windows only; unknown codes and roles are refused', async () => {
    await db.recursiveDelete(db.collection('billingAccounts'));
    const r = await familyQuota(db, owner, { code }, now);
    expect(r.accounts).toEqual([]);
    expect(r.events).toEqual([]);
    expect(await reason(familyQuota(db, ops, { code: 'F-ZZZZ' }, now))).toBe('family-not-found');
    expect(await reason(familyQuota(db, ops, { code: familyId }, now))).toBe('malformed');
    expect(await reason(familyQuota(db, support, { code }, now))).toBe('role');
    expect(await reason(familyQuota(db, null, { code }, now))).toBe('not-staff');
  });

  it('masks ids: hashes shortened, baby ids as codes', () => {
    expect(shortHashes(`video_${jobA}_0`)).toBe('video_ksj_11111111…_0');
    expect(shortHashes('video_cal_2026-10')).toBe('video_cal_2026-10');
    expect(babyCode(babyId)).toMatch(/^B-[A-Z2-9]{4}$/);
  });
});
