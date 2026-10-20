import { fakeModelGateway } from '../functions/src/assistant-model.js';
import { randomUUID } from 'node:crypto';
import { initializeApp, deleteApp, type App } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { beforeAll, beforeEach, afterAll, describe, expect, it } from 'vitest';
import {
  assistantConsentVersion,
  defaultEntitlementsConfig,
  defaultFlags,
  draftKinds,
  contentArticleSchema,
  contentStageSchema,
  contentFoodSchema,
  contentRecipeSchema,
  referenceMilestoneSchema,
  firstAidPublicSchema,
  type AssistantPart,
  type AssistantReadCard,
} from '@child-life/contracts';
import { startTask, setAssistantConsent, type AssistantDeps } from '../functions/src/assistant.js';
import { loadTrustedScope } from '../functions/src/assistant-common.js';
import { assistantRead } from '../functions/src/assistant-reads.js';
import { solidsContext, legacyReactionIngredientIds } from '../functions/src/assistant-solids.js';
import { careAnswer, type StoredCare } from '../functions/src/assistant-care.js';
import { foodFixture, recipeFixture, eggFixture } from '../functions/test/solids-fixtures.js';

// Emulator only; no provider and a zero credit allowance prove that known reads are free.
const projectId = 'demo-child-life-lumi-phase2';
const now = new Date('2026-10-20T00:30:00Z'); // 07:30 Vietnam
const B = 'test_p2baby',
  OTHER = 'test_p2other',
  F = 'test_p2family',
  MOM = 'test_p2mom',
  NANNY = 'test_p2nanny',
  AUNT = 'test_p2aunt';
const scope = { type: 'child' as const, babyId: B };
let app: App, db: Firestore;
const env = () => ({
  contractVersion: 1,
  clientRequestId: randomUUID(),
  locale: 'vi',
  clientDraftKinds: [...draftKinds],
});
const deps = (): AssistantDeps => ({ db, now, environment: 'test', gateway: null });
const ts = (s: string) => Timestamp.fromDate(new Date(s));
const l = (vi: string, en = vi) => ({ vi, en });
const meta = {
  status: 'published',
  revision: 1,
  review: null,
  illustrative: true,
  reviewDueOn: '2027-10-20',
  publishedAt: '2026-10-19T00:00:00.000Z',
  firstPublishedAt: '2026-10-19T00:00:00.000Z',
};
const reviewed = {
  ...meta,
  review: { reviewer: 'TEST_ONLY', credential: 'TEST_ONLY', reviewedOn: '2026-10-19' },
  illustrative: false,
};
const answerCards = (parts: AssistantPart[]) =>
  parts.filter((p): p is AssistantReadCard => p.type === 'read_card');
async function ask(text: string, uid = MOM) {
  const r = await startTask(deps(), uid, {
    ...env(),
    scope,
    conversationId: uid === AUNT ? null : `cv_${B}`,
    text,
    attachmentIds: [],
  });
  expect(r.data.task.state).toBe('ready');
  expect(r.data.task.credits).toBe(0);
  const task = await db.doc(`assistantTasks/${r.data.task.id}`).get();
  expect(task.get('modelCalls') ?? 0).toBe(0);
  return {
    ...r.data,
    cards: answerCards(r.data.messages.flatMap((m) => (m.role === 'assistant' ? m.parts : []))),
  };
}
async function record(
  id: string,
  type: string,
  occurredAt: string,
  data: object,
  extra = {},
  baby = B,
) {
  await db
    .doc(`babies/${baby}/records/${id}`)
    .set({ type, occurredAt: ts(occurredAt), data, deleted: false, ...extra });
}
async function read(tool: Parameters<typeof assistantRead>[1]['tool'], text = '', uid = MOM) {
  const s = await loadTrustedScope(db, uid, scope, now, 'test');
  return assistantRead({ db, s, anchor: now, locale: 'vi', text }, { tool, dayOffset: 0 });
}
beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw Error('FIRESTORE_EMULATOR_HOST is required');
  app = initializeApp({ projectId }, `phase2-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => deleteApp(app));
beforeEach(async () => {
  for (const c of [
    'babies',
    'families',
    'config',
    'users',
    'publicConfig',
    'assistantTasks',
    'assistantRequests',
    'assistantConversations',
    'contentFoods',
    'contentRecipes',
    'contentArticles',
    'contentStages',
    'contentMilestones',
  ])
    await db.recursiveDelete(db.collection(c));
  const on = { enabled: true, scope: 'all' };
  await db.doc('config/flags').set({
    ...defaultFlags,
    assistant: { ...defaultFlags.assistant, ...on },
    assistant_live: { ...defaultFlags.assistant_live, enabled: false },
  });
  await db.doc('config/entitlements').set({
    ...defaultEntitlementsConfig,
    quotas: {
      ...defaultEntitlementsConfig.quotas,
      assistant: { ...defaultEntitlementsConfig.quotas.assistant, free: 0 },
    },
  });
  await db
    .doc(`families/${F}`)
    .set({ ownerUid: MOM, country: 'VN', timeZone: 'Asia/Ho_Chi_Minh', babyIds: [B, OTHER] });
  for (const b of [B, OTHER]) {
    await db
      .doc(`babies/${b}`)
      .set({ familyId: F, state: 'active', timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' } });
    await db
      .doc(`babies/${b}/restricted/profile`)
      .set({ dateOfBirth: '2026-03-20', gender: 'boy' });
  }
  for (const [uid, role, rights] of [
    [MOM, 'coParent', null],
    [NANNY, 'caregiver', null],
    [AUNT, 'relative', { viewDailyCare: true }],
  ] as const) {
    await db.doc(`babies/${B}/members/${uid}`).set({
      uid,
      role,
      extraRights: rights,
      status: 'active',
      isOwner: uid === MOM,
      displayName: uid,
      relation: uid === MOM ? 'mother' : 'other',
      relationCustom: null,
    });
    await setAssistantConsent(deps(), uid, {
      ...env(),
      consent: { version: assistantConsentVersion },
    });
  }
});

describe('Phase 2 end-to-end read shortcuts', () => {
  it('authorises model-selected reads too and moves a discovered money answer before publication', async () => {
    await db
      .doc('config/flags')
      .update({ assistant_live: { ...defaultFlags.assistant_live, enabled: true, scope: 'all' } });
    await db.doc('config/entitlements').set({
      ...defaultEntitlementsConfig,
      quotas: {
        ...defaultEntitlementsConfig.quotas,
        assistant: { ...defaultEntitlementsConfig.quotas.assistant, free: 5 },
      },
    });
    await db.doc(`babies/${B}/expenses/test_private`).set({
      amount: 123456,
      currency: 'VND',
      categoryId: 'c_milk',
      spentOn: '2026-10-19',
      deleted: false,
    });
    const model = (tool: string) =>
      fakeModelGateway({
        extract: [{ intents: [], reads: [{ tool, dayOffset: 0 }], clarification: null }],
      });
    const gw = model('spending_month');
    const r = await startTask({ ...deps(), gateway: gw }, MOM, {
      ...env(),
      scope,
      conversationId: `cv_${B}`,
      text: 'Cho mình biết phần tổng hợp mục thứ tám',
      attachmentIds: [],
    });
    expect(r.data.task).toMatchObject({ state: 'ready', visibility: 'private' });
    expect(answerCards(r.data.messages.flatMap((m) => m.parts))[0]!.tool).toBe('spending_month');
    expect((await db.collection(`assistantConversations/cv_${B}/messages`).get()).empty).toBe(true);
    expect(gw.calls.word).toHaveLength(0);
    const denied = await startTask({ ...deps(), gateway: model('milestones') }, NANNY, {
      ...env(),
      scope,
      conversationId: `cv_${B}`,
      text: 'Tôi muốn xem những thành tựu của con',
      attachmentIds: [],
    });
    expect(denied.data.task).toMatchObject({
      state: 'failed',
      errorCode: 'READ_DENIED',
      usage: 'released',
    });
    expect(answerCards(denied.data.messages.flatMap((m) => m.parts))).toEqual([]);
  });
  it('reads the whole day, separates logged sleep from running time, and excludes deleted/other-baby logs', async () => {
    await record('feed1', 'bottle', '2026-10-20T00:00:00Z', { amountMl: 120 });
    await record(
      'sleep1',
      'sleep',
      '2026-10-19T16:00:00Z',
      {},
      { endedAt: ts('2026-10-19T18:00:00Z') },
    ); // 23:00–01:00 crosses local midnight
    await record('pump1', 'pump', '2026-10-19T23:00:00Z', { amountMl: 90 });
    await record('diaper1', 'diaper', '2026-10-19T23:10:00Z', { kind: 'wet' });
    await record('deleted', 'bottle', '2026-10-20T00:00:00Z', { amountMl: 999 }, { deleted: true });
    await record('otherbaby', 'bottle', '2026-10-20T00:00:00Z', { amountMl: 999 }, {}, OTHER);
    await db
      .doc(`babies/${B}/timers/sleep`)
      .set({ sessionId: 'a'.repeat(32), startedAt: ts('2026-10-20T00:25:00Z') });
    const r = await ask('Hôm nay bé thế nào?');
    const c = r.cards[0]!;
    expect(c.tool).toBe('day_overview');
    expect(c.rows.find((r) => r.label === 'Bú bình')!.value).toContain('120 ml');
    expect(c.rows.find((r) => r.label === 'Giấc ngủ đã kết thúc')!.value).toContain('60 phút');
    expect(c.rows.find((r) => r.label === 'Đang ngủ')!.value).toContain('5 phút');
    expect(c.rows.find((r) => r.label === 'Hút sữa')!.value).toContain('90 ml');
    expect(JSON.stringify(c)).not.toContain('999');
    expect(c.action.link).toBe('/today');
  });
  it('adds pumping and diaper logs for the last seven local days', async () => {
    await record('old', 'pump', '2026-10-14T00:00:00Z', { amountMl: 50 });
    await record('today', 'pump', '2026-10-20T00:00:00Z', { amountMl: 80 });
    await record('outside', 'pump', '2026-10-13T00:00:00Z', { amountMl: 999 });
    const r = await ask('Hút được bao nhiêu trong 7 ngày?');
    expect(r.cards[0]!.rows[1]!.value).toBe('130 ml');
    expect(r.cards[0]!.action.link).toBe('/care/history?filter=pump');
  });
  it('reads all three timers without making a second timer or saving a record', async () => {
    await db.doc(`babies/${B}/timers/pump`).set({ startedAt: ts('2026-10-20T00:20:00Z') });
    const sleeping = await ask('Bé ngủ được bao lâu rồi?');
    expect(sleeping.cards[0]!.sourceIds).toEqual([]);
    const r = await ask('Có timer nào đang chạy?');
    expect(r.cards[0]!.rows[0]!.value).toContain('10 phút');
    expect(r.cards[0]!.rows[0]!.link).toBe('/care/timer/pump');
    expect((await db.collection(`babies/${B}/records`).get()).empty).toBe(true);
  });
  it('reads separate latest measurements and calculates at measurement age, not current age', async () => {
    await record('born', 'growth', '2026-03-20T00:00:00Z', { weightKg: 3.3464 });
    await record('head', 'growth', '2026-10-19T00:00:00Z', { headCm: 43 });
    const r = await ask('Bé nặng bao nhiêu, có chuẩn không?');
    expect(r.cards[0]!.rows.find((r) => r.label === 'Cân nặng')!.value).toContain('P50.0');
    expect(r.cards[0]!.rows.some((r) => r.label === 'Vòng đầu')).toBe(true);
    expect(r.cards[0]!.caveat).toContain('không phải chẩn đoán');
  });
  it('reads family vaccination choices, given/declined doses and rescheduled dates', async () => {
    await db
      .doc(`babies/${B}/vaccinePlan/main`)
      .set({ scheduleFrom: '2026-03-20', dtp: '6in1', setupDone: true });
    await db.doc('publicConfig/reference_vaccines').set({
      dataset: 'vaccines.schedule',
      version: 'v2026.10',
      publishedAt: now.toISOString(),
      rows: [
        {
          id: 'testvx',
          name: l('TEST_ONLY'),
          short: l('TEST_ONLY'),
          months: [1, 2, 3],
          programme: 'epi',
          route: 'injection',
          about: l('TEST_ONLY'),
        },
      ],
    });
    await db.doc(`babies/${B}/vaccines/testvx_1`).set({ status: 'given' });
    await db.doc(`babies/${B}/vaccines/testvx_2`).set({ status: 'declined' });
    await db
      .doc(`babies/${B}/vaccines/testvx_3`)
      .set({ status: 'planned', plannedOn: '2026-10-25' });
    const r = await ask('Sắp tới bé tiêm gì?');
    expect(r.cards[0]!.rows).toHaveLength(1);
    expect(r.cards[0]!.rows[0]!.value).toBe('25/10/2026');
    expect(r.cards[0]!.rows[0]!.link).toBe('/care/vaccines/dose/testvx_3');
    await db.doc(`families/${F}`).update({ country: 'US' });
    expect(JSON.stringify(await read('vaccine_next'))).toContain('CDC');
  });
  it('reads all-day, assignees and enabled rule reminders but denies a daily-care relative', async () => {
    await db.doc(`babies/${B}/reminders/rm_test`).set({
      title: 'TEST_ONLY',
      dueAt: ts('2026-10-20T16:59:00Z'),
      allDay: true,
      dueDate: '2026-10-20',
      assigneeUid: NANNY,
      done: false,
    });
    await db.doc(`babies/${B}/reminderRules/rr_test`).set({
      type: 'feed',
      enabled: true,
      nextDueAt: ts('2026-10-20T01:00:00Z'),
      recipients: [NANNY],
    });
    const r = await ask('Hôm nay có nhắc gì?', NANNY);
    expect(r.cards[0]!.rows).toHaveLength(2);
    expect(r.cards[0]!.rows[0]!.value).toContain(`Cả ngày · Chưa xong · ${NANNY}`);
    const denied = await ask('Hôm nay có nhắc gì?', AUNT);
    expect(denied.cards).toEqual([]);
    expect(JSON.stringify(denied.messages)).not.toContain('TEST_ONLY');
  });
  it('keeps month totals and categories private and never mixes currencies or reads another baby', async () => {
    for (const [id, amount, currency, categoryId, baby] of [
      ['vnd', 500000, 'VND', 'c_milk', B],
      ['usd', 2500, 'USD', 'c_diaper', B],
      ['other', 999999, 'VND', 'c_milk', OTHER],
    ] as const)
      await db.doc(`babies/${baby}/expenses/${id}`).set({
        amount,
        currency,
        categoryId,
        spentOn: '2026-10-19',
        createdBy: MOM,
        deleted: false,
      });
    const r = await ask('Tháng này tiêu bao nhiêu?');
    expect(r.task.visibility).toBe('private');
    expect(r.task.conversationId).not.toBe(`cv_${B}`);
    expect(r.cards[0]!.rows.slice(0, 2).map((r) => r.value)).toEqual(['25.00 USD', '500000 VND']);
    await db.doc(`babies/${B}/spending/budget`).set({ monthlyTotal: 1000000, currency: 'VND' });
    const withBudget = answerCards(await read('spending_month'))[0]!;
    expect(withBudget.rows.find((r) => r.label === 'Ngân sách còn lại')!.value).toBe('500000 VND');
    const shared = await db.collection(`assistantConversations/cv_${B}/messages`).get();
    expect(shared.empty).toBe(true);
    await db.doc(`babies/${B}/members/${NANNY}`).update({ extraRights: { recordSpending: true } });
    expect(answerCards(await read('spending_month', '', NANNY))).toEqual([]);
  });
  it('reports tried ingredients and symptoms and excludes same-allergen recipes using the real diary', async () => {
    for (const [id, f] of [
      ['fd_pumpkin', foodFixture()],
      ['fd_egg', eggFixture()],
      ['fd_quail', eggFixture()],
    ] as const)
      await db.doc(`contentFoods/${id}`).set(contentFoodSchema.parse({ id, ...f, ...reviewed }));
    for (const [id, foods] of [
      ['rcp_pumpkin', ['fd_pumpkin']],
      ['rcp_quail', ['fd_quail']],
    ] as const)
      await db
        .doc(`contentRecipes/${id}`)
        .set(contentRecipeSchema.parse({ id, ...recipeFixture([...foods]), ...reviewed }));
    await db.doc('contentRecipes/rcp_us').set(
      contentRecipeSchema.parse({
        id: 'rcp_us',
        ...recipeFixture(['fd_pumpkin']),
        ...reviewed,
        countries: ['US'],
      }),
    );
    await db.doc(`babies/${B}/meals/m_egg`).set({
      occurredAt: ts('2026-10-19T05:00:00Z'),
      foodIds: ['fd_egg'],
      freeFoods: [],
      symptoms: ['rash'],
      reaction: 'notYet',
      deleted: false,
    });
    await db.doc(`babies/${B}/meals/m_pumpkin`).set({
      occurredAt: ts('2026-10-19T06:00:00Z'),
      foodIds: ['fd_pumpkin'],
      freeFoods: ['Bí ngô'],
      symptoms: [],
      reaction: 'liked',
      deleted: false,
    });
    await db.doc(`babies/${B}/meals/m_deleted`).set({
      occurredAt: ts('2026-10-19T06:00:00Z'),
      foodIds: ['fd_quail'],
      symptoms: [],
      deleted: true,
    });
    const r = await ask('Bé đã ăn thử những gì?');
    expect(r.cards[0]!.rows).toHaveLength(2);
    expect(r.cards[0]!.rows.find((r) => r.label === 'Trứng gà')!.value).toContain('Nổi mẩn');
    const c = await solidsContext(db, B, now);
    expect(c.excluded.has('fd_quail')).toBe(true);
    expect(legacyReactionIngredientIds(c)).toEqual(
      expect.arrayContaining(['egg', 'fd_egg', 'fd_quail', 'trung_ga']),
    );
    const s = await loadTrustedScope(db, MOM, scope, now, 'test');
    const care = { topic: 'meal_ideas', recipeIds: [] } as unknown as StoredCare;
    const ideas = await careAnswer({ db, s, care, anchor: now, now, locale: 'vi', canRead: true });
    expect(answerCards(ideas.parts)[0]!.rows.map((r) => r.link)).toEqual([
      '/care/solids/recipe/rcp_pumpkin',
    ]);
  });
  it('reads observed milestones privately and stage content matching audience and age', async () => {
    await db
      .doc(`babies/${B}/milestones/p_sits`)
      .set({ name: 'TEST_ONLY ngồi', status: 'observed', date: '2026-10-18' });
    const ref = referenceMilestoneSchema.parse({
      id: 'crawls',
      group: 'motor',
      order: 1,
      ageRange: { unit: 'months', from: 7, to: 10 },
      title: l('TEST_ONLY bò'),
      howToRecognise: l('TEST_ONLY'),
      talkToDoctor: null,
      illustration: null,
      sources: [{ label: 'TEST_ONLY', url: 'https://example.org/' }],
      ...meta,
    });
    await db.doc('contentMilestones/crawls').set(ref);
    await db.doc('contentStages/stg_m7').set(
      contentStageSchema.parse({
        id: 'stg_m7',
        age: { unit: 'month', from: 7, to: 8 },
        title: l('TEST_ONLY 7 tháng'),
        doing: { vi: ['TEST_ONLY'], en: ['TEST_ONLY'] },
        tryThis: { vi: ['TEST_ONLY trò chuyện'], en: ['TEST_ONLY talk'] },
        articleIds: [],
        milestoneIds: [],
        audience: ['coParent'],
        cover: null,
        sources: [],
        ...meta,
      }),
    );
    const r = await ask('Bé biết làm gì rồi?');
    expect(r.task.visibility).toBe('private');
    expect(r.cards[0]!.rows.some((r) => r.value.includes('TEST_ONLY bò'))).toBe(true);
    expect(answerCards(await read('milestones', '', NANNY))).toEqual([]);
    expect(answerCards(await read('stage'))[0]!.action.link).toBe('/stages/stg_m7');
    expect(JSON.stringify(await read('stage', '', NANNY))).not.toContain('TEST_ONLY 7 tháng');
  });
  it('finds up to three published age-matching articles and links first aid even without consent', async () => {
    const article = {
      library: 'care',
      topic: 'sleep',
      format: 'article',
      ageWeeks: { from: 20, to: 40 },
      readingMinutes: 2,
      cover: null,
      title: l('Giấc ngủ', 'Sleep'),
      summary: l('TEST_ONLY ngủ'),
      body: {
        vi: [{ type: 'paragraph', text: 'TEST_ONLY' }],
        en: [{ type: 'paragraph', text: 'TEST_ONLY' }],
      },
      keywords: { vi: ['ngủ'], en: ['sleep'] },
      relatedArticleIds: [],
      milestoneIds: [],
      sources: [],
      ...meta,
    };
    for (const id of ['art_sleep1', 'art_sleep2', 'art_sleep3', 'art_sleep4'])
      await db.doc(`contentArticles/${id}`).set(contentArticleSchema.parse({ id, ...article }));
    await db.doc('contentArticles/art_wrong_age').set(
      contentArticleSchema.parse({
        id: 'art_wrong_age',
        ...article,
        ageWeeks: { from: 0, to: 4 },
      }),
    );
    await db
      .doc('contentArticles/art_country')
      .set(contentArticleSchema.parse({ id: 'art_country', ...article, countries: ['US'] }));
    const r = await ask('Bài về giấc ngủ');
    expect(r.cards[0]!.rows).toHaveLength(3);
    expect(r.cards[0]!.sourceIds).not.toContain('art_country');
    await db.doc(`families/${F}`).update({ country: 'US' });
    expect(answerCards(await read('library_search', 'Bài về giấc ngủ'))[0]!.sourceIds).toContain(
      'art_country',
    );
    expect(r.cards[0]!.rows.every((r) => r.link?.startsWith('/library/a/'))).toBe(true);
    const pack = firstAidPublicSchema.parse({
      version: 'fa_20261020_01',
      publishedAt: now.toISOString(),
      pack: {
        emergencyNumber: '115',
        categories: [{ id: 'urgent', title: l('TEST_ONLY'), layout: 'list', tone: 'danger' }],
        situations: [
          {
            id: 'fever',
            code: 'TH01',
            category: 'urgent',
            emergency: false,
            monitoring: true,
            title: l('TEST_ONLY sốt'),
            lead: l('TEST_ONLY'),
            keywords: [l('sốt')],
            icon: 'test-icon_12345678',
            hero: 'test-hero_12345678',
            ageMonths: null,
            variantKind: null,
            variants: [
              {
                id: 'default',
                label: null,
                ageMonths: null,
                hero: null,
                banner: null,
                steps: [],
                callouts: [],
                cpr: null,
              },
            ],
            tool: null,
          },
        ],
        cpr: [],
        quickSearch: [],
        review: null,
      },
    });
    await db.doc('publicConfig/content_firstAid').set(pack);
    await db.doc(`users/${MOM}/settings/ai`).delete();
    const health = await ask('Bé sốt thì làm gì?');
    expect(health.cards[0]!.action.link).toBe('/utilities/first-aid');
  });
});
