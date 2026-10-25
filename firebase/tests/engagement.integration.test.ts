import contentSeed from '../../content/rhythm/content.seed.json' with { type: 'json' };
import { reservePersonalizedDigest } from '../functions/src/personalization-v2.js';
import {
  familyEngagementFromInbox,
  scheduleDailySuggestions,
  validateEngagementSource,
} from '../functions/src/engagement-sources.js';
import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import {
  initializeTestEnvironment,
  assertFails,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { beforeAll, beforeEach, afterAll, it, expect } from 'vitest';
import { defaultFlags, defaultEntitlementsConfig, keepsakeSeedV1 } from '@child-life/contracts';
import {
  authorizeEngagementBackground,
  engagementTransactionObserved,
  engHash,
  refreshEngagement,
  dispatchEngagement,
  engagementAction,
  purgeEngagement,
  saveEngagementSettings,
  runEngagement,
  ENG_DAY,
  type EngagementIntent,
} from '../functions/src/engagement.js';
import {
  reconcileBabyEngagement,
  careInboxEngagement,
  careOccurrenceEngagement,
  observeEngagementContent,
} from '../functions/src/engagement-observers.js';
import type { PushSender } from '../functions/src/social.js';

const projectId = 'demo-child-life-engagement',
  app = initializeApp({ projectId }, randomUUID()),
  db = getFirestore(app);
const start = new Date('2026-10-20T03:00:00Z'),
  now = new Date('2026-10-21T03:01:00Z');
let rules: RulesTestEnvironment;
const flags = Object.fromEntries(
  Object.keys(defaultFlags).map((key) => [
    key,
    { enabled: true, scope: 'all', percent: 100, notice: null },
  ]),
);
beforeAll(async () => {
  const [host, port] = process.env.FIRESTORE_EMULATOR_HOST!.split(':');
  rules = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: host!,
      port: Number(port),
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});
afterAll(async () => {
  await rules.cleanup();
  await deleteApp(app);
});
beforeEach(async () => {
  await rules.clearFirestore();
  await db.doc('config/flags').set(flags);
  await db.doc('config/engagement').set({ approved: true });
});
async function family(babyId = 'baby', uid = 'parent') {
  await db.doc('families/family').set({ ownerUid: uid, babyIds: [babyId] });
  await db
    .doc(`babies/${babyId}`)
    .set({ familyId: 'family', state: 'active', timeZone: { zone: 'Asia/Ho_Chi_Minh' } });
  await db.doc(`babies/${babyId}/members/${uid}`).set({ status: 'active', role: 'coParent' });
  await db
    .doc(`users/${uid}/devices/d_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa`)
    .set({ token: 'token', platform: 'ios', language: 'vi' });
  await db.doc(`users/${uid}/settings/engagement`).set({
    preferences: {
      consent: true,
      kinds: { 'ENG-01': true, 'ENG-02': true, 'ENG-03': true, 'ENG-05': true, 'ENG-06': true },
    },
  });
  return {
    babyId,
    ownerUid: uid,
    deviceId: 'd_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    pushAllowed: true,
    recipientZone: 'Asia/Ho_Chi_Minh',
    handoffKinds: ['ENG-01', 'ENG-02', 'ENG-06'],
  };
}
async function pending(babyId = 'baby') {
  const r = await family(babyId),
    episode = randomUUID(),
    data = { ...r, pending: { episode, state: 'pending', approvedBatches: [] } };
  await refreshEngagement(db, 'parent', data, start);
  await refreshEngagement(db, 'parent', data, now);
  const rows = await db.collection('engagementIntents').where('babyId', '==', babyId).get();
  return {
    data,
    ref: rows.docs.find(
      (d) => d.get('kind') === 'ENG-01' && d.get('sourceData.episode') === episode,
    )!.ref,
  };
}
it('renews headless access only for the current owner and every live parent scope', async () => {
  const a = await family('one');
  await family('two');
  const access = { ownerUid: 'parent', deviceId: a.deviceId, babyIds: ['one', 'two'] };
  expect(await authorizeEngagementBackground(db, 'parent', access, now)).toEqual({
    authorized: true,
    leaseUntil: now.getTime() + ENG_DAY,
  });
  const fence = db.doc(`engagementFences/${engHash('babyId:two')}`);
  await fence.set({ at: now });
  await expect(authorizeEngagementBackground(db, 'parent', access, now)).rejects.toMatchObject({
    code: 'permission-denied',
  });
  await fence.delete();
  await expect(authorizeEngagementBackground(db, 'another', access, now)).rejects.toMatchObject({
    code: 'permission-denied',
  });
  await db
    .doc('babies/two/members/parent')
    .update({ accessUntilAt: new Date(now.getTime() + 60_000) });
  expect((await authorizeEngagementBackground(db, 'parent', access, now)).leaseUntil).toBe(
    now.getTime() + 60_000,
  );
  await db.doc('babies/two/members/parent').update({ role: 'family' });
  await expect(authorizeEngagementBackground(db, 'parent', access, now)).rejects.toMatchObject({
    code: 'permission-denied',
  });
});
it('ships dark without approved policy, rejects raw local data and denies direct access', async () => {
  const r = await family();
  await db.doc('config/engagement').delete();
  expect((await refreshEngagement(db, 'parent', r, now)).enabled).toBe(false);
  await expect(
    refreshEngagement(db, 'parent', { ...r, photoKitId: 'private' }, now),
  ).rejects.toMatchObject({ reason: 'malformed' });
  const client = rules.authenticatedContext('parent').firestore();
  await assertFails(getDoc(doc(client, 'engagementIntents/a')));
  await assertFails(getDoc(doc(client, 'users/parent/settings/engagementState')));
  await assertFails(
    setDoc(doc(client, 'users/parent/settings/engagementState'), { paused: false }),
  );
  await assertFails(setDoc(doc(client, 'engagementIntents/a'), { uid: 'parent' }));
});
it('retains one discovery episode across retries and proves completion from an approved ready batch', async () => {
  const p = await pending();
  expect((await db.collection('engagementIntents').where('kind', '==', 'ENG-01').get()).size).toBe(
    1,
  );
  expect((await p.ref.get()).get('dueAt')).toBe(start.getTime() + ENG_DAY);
  await refreshEngagement(
    db,
    'parent',
    {
      ...p.data,
      pending: { ...p.data.pending, state: 'resolved', approvedBatches: ['approved_batch'] },
    },
    now,
  );
  expect((await p.ref.get()).get('completedAt')).toBeNull();
  await db.doc('babies/baby/media/photo').set({
    status: 'ready',
    deleted: false,
    createdBy: 'parent',
    batchId: 'approved_batch',
    readyAt: now,
  });
  await reconcileBabyEngagement(db, 'baby', now);
  expect((await p.ref.get()).get('status')).toBe('completed');
});
it('uses one account budget across babies and one lease-selected device under concurrent dispatch', async () => {
  const a = await pending('baby_a'),
    b = await pending('baby_b');
  await db.doc('users/parent/devices/other').set({ token: 'other-token', language: 'en' });
  const calls: string[][] = [];
  const sender: PushSender = {
    send: async (tokens) => {
      calls.push(tokens);
      return [];
    },
  };
  await Promise.all([
    dispatchEngagement(db, sender, (await a.ref.get()) as never, now),
    dispatchEngagement(db, sender, (await b.ref.get()) as never, now),
  ]);
  expect(calls).toEqual([['token']]);
  const state = await db.doc('users/parent/settings/engagementState').get();
  expect(state.get('recent')).toHaveLength(1);
  expect((await db.collection('users/parent/notifications').get()).size).toBe(1);
});
it('does not retry ambiguous provider acceptance, and a notification open does not imply completion', async () => {
  const p = await pending();
  let calls = 0;
  const sender: PushSender = {
    send: async () => {
      calls++;
      throw Error('provider timeout');
    },
  };
  await dispatchEngagement(db, sender, (await p.ref.get()) as never, now);
  await dispatchEngagement(db, sender, (await p.ref.get()) as never, now);
  expect(calls).toBe(1);
  expect((await p.ref.get()).get('status')).toBe('unknown');
  const answer = await engagementAction(
    db,
    'parent',
    {
      id: p.ref.id,
      action: 'open',
      surface: 'notification',
      deviceId: 'd_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    },
    now,
  );
  expect(answer).toMatchObject({ babyId: 'baby', route: '/memories/auto-save/review' });
  expect((await p.ref.get()).get('completedAt')).toBeNull();
});
it('keeps snooze/dismiss/opt-out persistent and never interprets OS swipe as a dismissal', async () => {
  const p = await pending();
  await engagementAction(db, 'parent', { id: p.ref.id, action: 'snooze' }, now);
  expect((await p.ref.get()).get('snoozedUntil')).toBe(now.getTime() + 2 * ENG_DAY);
  await engagementAction(db, 'parent', { id: p.ref.id, action: 'dismiss' }, now);
  await engagementAction(db, 'parent', { id: p.ref.id, action: 'dismiss' }, now);
  expect(
    (await db.doc('users/parent/settings/engagementState').get()).get('dismissals'),
  ).toHaveLength(1);
  await refreshEngagement(db, 'parent', p.data, now);
  expect((await p.ref.get()).get('dismissed')).toBe(true);
  await expect(
    engagementAction(db, 'attacker', { id: p.ref.id, action: 'open' }, now),
  ).rejects.toMatchObject({ reason: 'not-allowed' });
});
it('supports retrospective campaigns for a late joiner and suppresses completed cards without claiming video conversion', async () => {
  const r = await family();
  await db.doc('babies/baby/restricted/profile').set({ dateOfBirth: '2026-04-01' });
  const t = structuredClone(
    keepsakeSeedV1.templates.find((t) => t.kind === 'video' && t.occasions.includes('m1'))!,
  );
  t.status = 'published';
  t.tier = 'free';
  t.ageDays = { min: 0, max: 45 };
  t.scenes = t.scenes.map((s) => ({ ...s, optional: true }));
  await db
    .doc('publicConfig/keepsakes')
    .set({ templates: [t], music: [], premium: { access: 'everyone', badges: true } });
  for (let n = 0; n < t.photos.min; n++)
    await db.doc(`babies/baby/media/photo_${n}`).set({
      type: 'photo',
      status: 'ready',
      deleted: false,
      captureAt: new Date('2026-04-15'),
      readyAt: now,
    });
  const result = await refreshEngagement(db, 'parent', r, now);
  const rows = await db.collection('engagementIntents').get(),
    // Doc 18 #21: the retrospective suggestion has its own key, apart from a current campaign.
    campaign = rows.docs.find((d) => d.get('source') === 'campaign:m1:retro');
  expect(result.suggestions.some((s) => s.context === 'retrospective')).toBe(true);
  expect(campaign).toBeDefined();
  let calls = 0;
  await dispatchEngagement(
    db,
    {
      send: async () => {
        calls++;
        return [];
      },
    },
    campaign!,
    now,
  );
  expect(calls).toBe(0);
  await db.doc('babies/baby/media/card').set({
    status: 'ready',
    deleted: false,
    generated: { kind: 'card' },
    milestone: { id: 'p_one_month' },
  });
  await reconcileBabyEngagement(db, 'baby', now);
  expect((await campaign!.ref.get()).get('status')).toBe('cancelled');
  expect((await campaign!.ref.get()).get('completedAt')).toBeNull();
});
it('records user-configured Care even when proactive consent is off and fatigue is paused', async () => {
  await family();
  await db.doc('users/parent/settings/engagement').set({ preferences: { consent: false } });
  await db.doc('users/parent/settings/engagementState').set({ paused: true });
  await db.doc('babies/baby/reminderRules/rule').set({ recipients: ['parent'], enabled: true });
  await careInboxEngagement(
    db,
    'parent',
    {
      kind: 'reminderRule',
      babyId: 'baby',
      data: { ruleId: 'rule', dueAt: String(now.getTime()) },
    },
    now,
  );
  const rows = await db.collection('engagementIntents').get();
  expect(rows.docs[0]?.get('kind')).toBe('ENG-04');
  await careOccurrenceEngagement(db, 'baby', 'rule', { dueAt: now, outcome: 'logged' }, now);
  expect((await rows.docs[0]!.ref.get()).get('status')).toBe('completed');
});
it('fences account deletion and never resurrects a late source receipt', async () => {
  const p = await pending();
  await purgeEngagement(db, 'uid', 'parent', now);
  expect((await db.collection('engagementIntents').get()).empty).toBe(true);
  const result = await refreshEngagement(db, 'parent', p.data, now);
  expect(result.suggestions).toEqual([]);
  await engagementTransactionObserved(db, 'parent', 'baby', now);
  expect((await db.doc('users/parent/settings/engagementState').get()).exists).toBe(false);
});

it('waits for OS handoff acknowledgement and keeps one intent after acknowledgement', async () => {
  const p = await pending();
  await db.doc('users/parent/settings/engagementDevice').update({ handoffKinds: [], handoffs: {} });
  let calls = 0;
  const sender: PushSender = {
    send: async () => {
      calls++;
      return [];
    },
  };
  await dispatchEngagement(db, sender, (await p.ref.get()) as never, now);
  expect(calls).toBe(0);
  await refreshEngagement(db, 'parent', p.data, now);
  await dispatchEngagement(db, sender, (await p.ref.get()) as never, now);
  expect(calls).toBe(1);
  expect((await db.collection('engagementIntents').where('kind', '==', 'ENG-01').get()).size).toBe(
    1,
  );
});
it('the device lease lasts the policy days (30 by default), not 2 hours (D-092)', async () => {
  await pending();
  const lease = await db.doc('users/parent/settings/engagementDevice').get();
  expect(lease.get('validUntil')).toBe(now.getTime() + 30 * ENG_DAY);
});
it('keeps fatigue paused until explicit resume after the minimum break', async () => {
  for (let n = 0; n < 3; n++) {
    const p = await pending();
    await engagementAction(db, 'parent', { id: p.ref.id, action: 'dismiss' }, now);
  }
  const state = await db.doc('users/parent/settings/engagementState').get();
  expect(state.get('paused')).toBe(true);
  expect(state.get('reducedUntil')).toBeGreaterThan(now.getTime());
  await expect(saveEngagementSettings(db, 'parent', { resume: true }, now)).rejects.toMatchObject({
    reason: 'cooldown',
  });
  await saveEngagementSettings(
    db,
    'parent',
    { resume: true },
    new Date(now.getTime() + 14 * ENG_DAY + 1),
  );
  expect((await state.ref.get()).get('paused')).toBe(false);
});
it('resume re-arms what the pause suppressed while its window is open (doc 18 #22)', async () => {
  const p = await pending();
  const later = new Date(now.getTime() + 14 * ENG_DAY + 1);
  await p.ref.update({
    status: 'suppressed',
    reason: 'fatigue_paused',
    expiresAt: later.getTime() + ENG_DAY,
  });
  const other = db.doc(`engagementIntents/${'f'.repeat(64)}`);
  await other.set({
    ...(await p.ref.get()).data(),
    id: 'f'.repeat(64),
    reason: 'fatigue_paused',
    status: 'suppressed',
    expiresAt: now.getTime(),
  });
  await db
    .doc('users/parent/settings/engagementState')
    .set({ paused: true, pausedUntil: now.getTime() }, { merge: true });
  await saveEngagementSettings(db, 'parent', { resume: true }, later);
  expect((await p.ref.get()).data()).toMatchObject({ status: 'eligible', reason: 'none' });
  expect((await p.ref.get()).get('nextAt')).toBeGreaterThanOrEqual(later.getTime());
  // A window that already closed stays closed: no catch-up.
  expect((await other.get()).get('status')).toBe('suppressed');
});
it('does not resurrect an episode after its payload is expired and cleaned', async () => {
  const p = await pending();
  await engagementAction(db, 'parent', { id: p.ref.id, action: 'dismiss' }, now);
  await p.ref.delete();
  await refreshEngagement(db, 'parent', p.data, now);
  expect((await db.collection('engagementIntents').where('kind', '==', 'ENG-01').get()).empty).toBe(
    true,
  );
});
it('builds the closed week from save time, excludes drafts, and completes only on a real authorized source view', async () => {
  const r = await family(),
    monday = new Date('2026-10-19T03:00:00Z');
  await db.doc('babies/baby/media/historical').set({
    type: 'photo',
    status: 'ready',
    deleted: false,
    createdBy: 'parent',
    captureAt: new Date('2026-04-01'),
    readyAt: new Date('2026-10-14'),
  });
  await db
    .doc('babies/baby/stories/draft')
    .set({ status: 'draft', savedAt: new Date('2026-10-14') });
  const result = await refreshEngagement(db, 'parent', r, monday),
    digest = result.suggestions.find((s) => s.kind === 'ENG-03');
  expect(digest).toBeDefined();
  const opened = await engagementAction(db, 'parent', { id: digest!.id, action: 'open' }, monday);
  expect(opened).toMatchObject({ content: { mediaIds: ['historical'], storyIds: [] } });
  expect((await db.doc(`engagementIntents/${digest!.id}`).get()).get('completedAt')).toBeNull();
  await observeEngagementContent(
    db,
    'parent',
    { babyId: 'baby', sourceType: 'media', sourceId: 'historical' },
    monday,
  );
  expect((await db.doc(`engagementIntents/${digest!.id}`).get()).get('status')).toBe('completed');
});
it('groups real family updates, suppresses own/revoked sources and completes only from viewed content', async () => {
  await family();
  await db.doc('users/parent/settings/notifications').set({ familyActivity: true });
  for (const id of ['message_1', 'message_2']) {
    await db.doc(`babies/baby/messages/${id}`).set({ from: 'relative', createdAt: start });
    const data = {
      kind: 'message',
      babyId: 'baby',
      readAt: null,
      data: { sourceCollection: 'messages', sourceId: id },
    };
    await db.doc(`users/parent/notifications/${id}`).set(data);
    await familyEngagementFromInbox(db, 'parent', id, data, start);
  }
  const groups = await db.collection('engagementIntents').get();
  expect(groups.size).toBe(1);
  expect(groups.docs[0]!.get('sourceData.inboxIds')).toHaveLength(2);
  await observeEngagementContent(
    db,
    'parent',
    { babyId: 'baby', sourceType: 'message', sourceId: 'message_1' },
    start,
  );
  expect((await groups.docs[0]!.ref.get()).get('status')).toBe('completed');
});

it('D-099: the daily suggestion is a server slot at the chosen time, decided at send time', async () => {
  await db.doc('config/entitlements').set({
    ...defaultEntitlementsConfig,
    regions: { advanced: ['VN'] },
    betaCampaigns: [
      {
        id: 'test_beta',
        capabilities: ['personalization.cross_module'],
        validFrom: '2026-10-01T00:00:00Z',
        validUntil: '2026-11-01T00:00:00Z',
        countries: [],
        scope: 'all',
        percent: 100,
      },
    ],
  });
  const r = await family();
  await db.doc('families/family').update({ country: 'VN' });
  await db.doc('publicConfig/content_rhythm').set(contentSeed);
  await db.doc('babies/baby/restricted/profile').set({ dateOfBirth: '2026-08-15' });
  // No "Hôm nay của bé" device switch: the Gợi ý thông minh default (D-098) is enough.
  await db
    .doc('users/parent/settings/personalization')
    .set({ digestTime: '20:30', quietHours: { from: '22:00', to: '06:00' } });
  await refreshEngagement(db, 'parent', r, now);
  const slots = await db.collection('engagementIntents').where('kind', '==', 'ENG-06').get();
  expect(slots.size).toBe(1);
  const slot = slots.docs[0]!;
  // 10:01 in Hồ Chí Minh: today's 20:30.
  expect(slot.get('dueAt')).toBe(Date.parse('2026-10-21T13:30:00Z'));
  // Too few records yet: nothing to suggest, no push.
  expect((await validateEngagementSource(db, slot.data() as EngagementIntent, now)).state).toBe(
    'resolved',
  );
  for (const type of ['bottle', 'breast', 'diaper'])
    await db.doc(`babies/baby/records/${type}`).set({
      type,
      createdBy: 'parent',
      occurredAt: now,
      createdAt: now,
      deleted: false,
      data: {},
    });
  const ready = await validateEngagementSource(db, slot.data() as EngagementIntent, now);
  expect(ready).toMatchObject({ state: 'ready', route: '/rhythm/day' });
  expect((await slot.ref.get()).get('sourceData.activity')).toEqual(expect.any(String));
  // The device's own reservation stays off: the server owns the lane.
  expect(
    (
      await reservePersonalizedDigest(
        db,
        'parent',
        { babyId: 'baby', deviceId: 'd_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' },
        now,
        'test',
      )
    ).fireAt,
  ).toBeNull();
  expect((await db.collection('aiUsageDaily').get()).empty).toBe(true);
});

it('D-099: the hourly pass queues tomorrow once today has passed, and a new clock moves the slot', async () => {
  const r = await family();
  await refreshEngagement(db, 'parent', r, now);
  await db.doc('users/parent/settings/personalization').set({ digestTime: '08:00' });
  // 10:01 local: 08:00 has passed, so the slot is tomorrow's, without the app being opened.
  const late = await scheduleDailySuggestions(db, now);
  expect(late.queued).toBe(1);
  const tomorrow = await db
    .collection('engagementIntents')
    .where('kind', '==', 'ENG-06')
    .where('sourceData.date', '==', '2026-10-22')
    .get();
  expect(tomorrow.size).toBe(1);
  expect(tomorrow.docs[0]!.get('dueAt')).toBe(Date.parse('2026-10-22T01:00:00Z'));
  await db.doc('users/parent/settings/personalization').set({ digestTime: '07:30' });
  await scheduleDailySuggestions(db, now);
  const moved = await tomorrow.docs[0]!.ref.get();
  expect(moved.get('dueAt')).toBe(Date.parse('2026-10-22T00:30:00Z'));
  expect(moved.get('nextAt')).toBe(Date.parse('2026-10-22T00:30:00Z'));
  // Looking at today's ideas leaves tomorrow's slot alone (with enough to suggest).
  await db.doc('config/entitlements').set({
    ...defaultEntitlementsConfig,
    regions: { advanced: ['VN'] },
    betaCampaigns: [
      {
        id: 'test_beta',
        capabilities: ['personalization.cross_module'],
        validFrom: '2026-10-01T00:00:00Z',
        validUntil: '2026-11-01T00:00:00Z',
        countries: [],
        scope: 'all',
        percent: 100,
      },
    ],
  });
  await db.doc('families/family').update({ country: 'VN' });
  await db.doc('publicConfig/content_rhythm').set(contentSeed);
  await db.doc('babies/baby/restricted/profile').set({ dateOfBirth: '2026-08-15' });
  for (const type of ['bottle', 'breast', 'diaper'])
    await db.doc(`babies/baby/records/${type}`).set({
      type,
      createdBy: 'parent',
      occurredAt: now,
      createdAt: now,
      deleted: false,
      data: {},
    });
  expect(
    (
      await validateEngagementSource(
        db,
        (await tomorrow.docs[0]!.ref.get()).data() as EngagementIntent,
        now,
      )
    ).state,
  ).toBe('ready');
  await observeEngagementContent(
    db,
    'parent',
    { babyId: 'baby', sourceType: 'personal_day', sourceId: 'baby' },
    now,
  );
  expect((await tomorrow.docs[0]!.ref.get()).get('status')).toBe('eligible');
  // Opting out of the ENG-06 row stops the queueing.
  await db.doc('users/parent/settings/engagement').set(
    {
      preferences: {
        consent: true,
        kinds: {
          'ENG-01': true,
          'ENG-02': true,
          'ENG-03': true,
          'ENG-05': true,
          'ENG-06': false,
        },
      },
    },
    { merge: true },
  );
  expect((await scheduleDailySuggestions(db, now)).queued).toBe(0);
});

it('records an explicit rejected handoff as failed while an ambiguous send stays unknown', async () => {
  const p = await pending();
  await dispatchEngagement(
    db,
    { send: async (tokens) => tokens },
    (await p.ref.get()) as never,
    now,
  );
  expect((await p.ref.get()).get('status')).toBe('failed');
  const facts = await db.collection('productAnalyticsFacts').where('stage', '==', 'failed').get();
  expect(facts.docs[0]?.get('event')).toBe('engagement_dispatch_failed');
});

// Audit 18 regressions (docs/product-audit/18-smart-reminder-code-audit.md).
const counting = () => {
  const sent = { calls: 0 };
  const sender: PushSender = {
    send: async () => {
      sent.calls++;
      return [];
    },
  };
  return { sent, sender };
};
async function careIntent(dueAt = now.getTime()) {
  await db.doc('babies/baby/reminderRules/rule').set({ recipients: ['parent'], enabled: true });
  await careInboxEngagement(
    db,
    'parent',
    { kind: 'reminderRule', babyId: 'baby', data: { ruleId: 'rule', dueAt: String(dueAt) } },
    now,
  );
  // A delivered Care notice intentionally holds proactive spacing; these cases test the queue.
  await db.doc('users/parent/settings/engagementState').update({ transactionAt: 0 });
  return (await db.collection('engagementIntents').where('kind', '==', 'ENG-04').get()).docs[0]!
    .ref;
}
async function m1Setup() {
  await db.doc('babies/baby/restricted/profile').set({ dateOfBirth: '2026-04-01' });
  const t = structuredClone(
    keepsakeSeedV1.templates.find((t) => t.kind === 'video' && t.occasions.includes('m1'))!,
  );
  t.status = 'published';
  t.tier = 'free';
  t.ageDays = { min: 0, max: 45 };
  t.scenes = t.scenes.map((s) => ({ ...s, optional: true }));
  await db
    .doc('publicConfig/keepsakes')
    .set({ templates: [t], music: [], premium: { access: 'everyone', badges: true } });
  for (let n = 0; n < t.photos.min; n++)
    await db.doc(`babies/baby/media/photo_${n}`).set({
      type: 'photo',
      status: 'ready',
      deleted: false,
      captureAt: new Date('2026-04-15'),
      readyAt: now,
    });
}
it('keeps Care measurement out of the scheduler queue so proactive intents still send', async () => {
  const p = await pending();
  const care = await careIntent();
  expect((await care.get()).get('nextAt')).toBeUndefined();
  // A pre-fix Care row that is already queued is dropped from the queue, never dispatched.
  await care.update({ nextAt: 0 });
  const { sent, sender } = counting();
  await runEngagement(db, sender, now);
  expect((await care.get()).get('nextAt')).toBeUndefined();
  expect(sent.calls).toBe(1);
  expect((await p.ref.get()).get('status')).toBe('accepted');
});
it('saving preferences never rewrites Care or finished intents and re-arms only after opt-in', async () => {
  const p = await pending();
  const care = await careIntent();
  await careOccurrenceEngagement(db, 'baby', 'rule', { dueAt: now, outcome: 'logged' }, now);
  const kinds = { 'ENG-01': true, 'ENG-02': true, 'ENG-03': true, 'ENG-05': true, 'ENG-06': true };
  await saveEngagementSettings(
    db,
    'parent',
    { preferences: { consent: true, kinds: { ...kinds, 'ENG-01': false } } },
    now,
  );
  expect((await care.get()).get('status')).toBe('completed');
  expect((await p.ref.get()).get('status')).toBe('in_app_only');
  await saveEngagementSettings(db, 'parent', { preferences: { consent: true, kinds } }, now);
  expect((await p.ref.get()).get('status')).toBe('eligible');
  expect(typeof (await p.ref.get()).get('nextAt')).toBe('number');
  const { sender } = counting();
  await dispatchEngagement(db, sender, (await p.ref.get()) as never, now);
  await saveEngagementSettings(db, 'parent', { preferences: { consent: false, kinds } }, now);
  expect((await p.ref.get()).get('status')).toBe('accepted');
});
it('snoozing a sent suggestion hides it without putting it back in the queue', async () => {
  const p = await pending();
  const { sender } = counting();
  await dispatchEngagement(db, sender, (await p.ref.get()) as never, now);
  await engagementAction(db, 'parent', { id: p.ref.id, action: 'snooze' }, now);
  expect((await p.ref.get()).get('nextAt')).toBeUndefined();
  expect((await p.ref.get()).get('snoozedUntil')).toBe(now.getTime() + 2 * ENG_DAY);
});
it('a failed render does not block the milestone campaign; one in flight does', async () => {
  const r = await family();
  await m1Setup();
  await db.doc('babies/baby/keepsakeJobs/rendering').set({ occasion: 'm1', status: 'rendering' });
  await refreshEngagement(db, 'parent', r, now);
  const campaign = () =>
    db
      .collection('engagementIntents')
      .where('source', 'in', ['campaign:m1', 'campaign:m1:retro'])
      .get();
  expect((await campaign()).empty).toBe(true);
  await db.doc('babies/baby/keepsakeJobs/rendering').update({ status: 'failed' });
  await refreshEngagement(db, 'parent', r, now);
  expect((await campaign()).size).toBe(1);
});
it('deleting one parent keeps the family campaign marker without that parent reference', async () => {
  await family();
  await db.doc(`engagementCampaigns/${engHash('baby:campaign:m1')}`).set({
    babyId: 'baby',
    uid: 'parent',
    at: now,
    deleteAfter: new Date(now.getTime() + ENG_DAY),
  });
  await purgeEngagement(db, 'uid', 'parent', now);
  const marker = await db.doc(`engagementCampaigns/${engHash('baby:campaign:m1')}`).get();
  expect(marker.exists).toBe(true);
  expect(marker.get('uid')).toBeUndefined();
});
it('a switched-off ENG-01 family does not refuse the background lease of a live member', async () => {
  const a = await family('one');
  await db.doc('config/flags').set({
    ...flags,
    engagementPendingEnabled: { enabled: false, scope: 'all', percent: 100, notice: null },
  });
  const access = { ownerUid: 'parent', deviceId: a.deviceId, babyIds: ['one'] };
  expect((await authorizeEngagementBackground(db, 'parent', access, now)).authorized).toBe(true);
});
it('a Care push with the category off is cohort-only and does not move proactive spacing', async () => {
  await family();
  await db.doc('babies/baby/reminderRules/rule').set({ recipients: ['parent'], enabled: true });
  await careInboxEngagement(
    db,
    'parent',
    {
      kind: 'reminderRule',
      babyId: 'baby',
      data: { ruleId: 'rule', dueAt: String(now.getTime()) },
      eligibilityOnly: true,
    },
    now,
  );
  expect((await db.collection('engagementIntents').get()).size).toBe(1);
  expect(
    (await db.doc('users/parent/settings/engagementState').get()).get('transactionAt'),
  ).toBeUndefined();
});
