import { randomUUID } from 'node:crypto';
import {
  defaultEntitlementsConfig,
  defaultFlags,
  defaultRhythmRules,
  type Activity,
  type AgeCard,
  type RhythmContent,
} from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  composeHome,
  nextAction,
  onCheckInWritten,
  bumpDataVersion,
  setDueDate,
} from '../functions/src/rhythm.js';
import {
  rhythmAct,
  rhythmDraft,
  rhythmRulesView,
  rhythmView,
  setRhythmRules,
} from '../functions/src/rhythm-content.js';
import type { Staff } from '../functions/src/staff.js';

// Nhịp lớn lên Slice 2 (plan §7.1) against the Firestore emulator: nextAction / composeHome
// gates (M01), health first, feedback changing the next Home (M18), sleep data quality (M13), two
// authors on one day and the facts version (M14), roles (D-072 #2), and the staff publishing
// workflow. Its own project (it rewrites config/* and publicConfig/*). Synthetic `test_` data.
const projectId = 'demo-child-life-rhythm';
let app: App;
let db: Firestore;
// 19:00 in Hồ Chí Minh: the baby-local day is 2026-10-14.
const now = new Date('2026-10-14T12:00:00Z');
const later = (minutes: number) => new Date(now.getTime() + minutes * 60_000);
const B = 'test_b1';
const B2 = 'test_b2';

const ops: Staff = { uid: 's_ops', name: 'Vận hành', roles: ['ops'] };
const expert: Staff = { uid: 's_expert', name: 'BS. Lan', roles: ['expert'] };
const eng: Staff = { uid: 's_eng', name: 'Kỹ sư', roles: ['eng'] };

const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason,
  );
const on = { ...defaultFlags.rhythm, enabled: true, scope: 'all' as const };
const L = (vi: string) => ({ vi, en: vi });
const LL = (vi: string) => ({ vi: [vi], en: [vi] });

const activity = (
  id: string,
  needs: Activity['needs'],
  over: Partial<Activity> = {},
): Activity => ({
  id,
  version: 1,
  status: 'published',
  title: L(id),
  summary: L('Tóm tắt'),
  steps: LL('Bước 1'),
  safety: null,
  durationMin: 10,
  ageDays: { from: 0, to: 365 },
  needs,
  interests: [],
  timeOfDay: 'evening',
  locales: ['vi', 'en'],
  regions: [],
  sources: [],
  review: null,
  ...over,
});
const ageCard = (id: string, from: number, to: number): AgeCard => ({
  id,
  version: 1,
  status: 'published',
  ageDays: { from, to },
  title: L(id),
  body: L('Mỗi bé mỗi khác'),
  tips: LL('Mẹo'),
  watchFor: LL('Hỏi bác sĩ khi…'),
  interests: [],
  sources: [],
  review: null,
});
const contentData = (): Omit<RhythmContent, 'version' | 'publishedAt'> => ({
  activities: [
    activity('act_sleep_dim', ['sleep']),
    activity('act_sleep_song', ['sleep']),
    activity('act_sleep_walk', ['sleep']),
    activity('act_feed_calm', ['feeding']),
  ],
  ageCards: [ageCard('age_m0_3', 0, 90), ageCard('age_w9', 56, 62)],
  health: {
    signs: [{ id: 'fever_young', label: L('Sốt dưới 3 tháng'), maxAgeDays: 90 }],
    whileWaiting: LL('Giữ bé ấm'),
    disclaimer: L('Không thay thế bác sĩ'),
    regions: [{ country: 'VN', emergencyNumber: '115' }],
    sources: [],
    review: null,
  },
});
const content = (): RhythmContent => ({
  ...contentData(),
  version: 'rc_20261014_01',
  publishedAt: now.toISOString(),
});

let seq = 0;
const ciId = () => `ci_${(++seq).toString(16).padStart(32, '0')}`;
const fbId = () => `fb_${(++seq).toString(16).padStart(32, '0')}`;

async function saveCheckIn(
  uid: string,
  over: Record<string, unknown> = {},
  baby = B,
): Promise<string> {
  const id = (over.id as string | undefined) ?? ciId();
  await db.doc(`babies/${baby}/checkins/${id}`).set({
    id,
    babyId: baby,
    date: '2026-10-14',
    authorUid: uid,
    observation: 'sleep',
    when: 'night',
    since: 'days_2_3',
    tried: [],
    healthSigns: [],
    note: 'ghi chú riêng',
    revision: 1,
    createdAt: Timestamp.fromDate(now),
    updatedAt: Timestamp.fromDate(now),
    ...over,
  });
  return id;
}

async function giveFeedback(contentId: string, kind: string, at: Date, uid = 'test_mom') {
  const id = fbId();
  await db.doc(`babies/${B}/recFeedback/${id}`).set({
    id,
    babyId: B,
    authorUid: uid,
    contentId,
    contentVersion: 1,
    kind,
    date: '2026-10-14',
    note: null,
    createdAt: Timestamp.fromDate(at),
  });
  return id;
}

const ask = (uid: string, checkInId: string, at = now, baby = B) =>
  nextAction(db, uid, { babyId: baby, checkInId, locale: 'vi' }, at, 'test');
const home = (uid: string, at = now, baby = B) =>
  composeHome(db, uid, { babyId: baby, locale: 'vi' }, at, 'test');

/** "HH:MM" on a Hồ Chí Minh date. */
const at = (date: string, hhmm: string) => Timestamp.fromDate(new Date(`${date}T${hhmm}:00+07:00`));
const dateAdd = (date: string, days: number) =>
  new Date(Date.parse(`${date}T00:00:00Z`) + days * 86_400_000).toISOString().slice(0, 10);

/** A well-logged day: night sleep 00:00 → [sleepUntil], a bottle every two hours after. */
async function logDay(date: string, sleepUntil = '08:00') {
  const batch = db.batch();
  const col = db.collection(`babies/${B}/records`);
  const sleepId = `r_${date.replace(/-/g, '')}${'0'.repeat(24)}`;
  batch.set(col.doc(sleepId), {
    type: 'sleep',
    occurredAt: at(date, '00:00'),
    endedAt: at(date, sleepUntil),
    deleted: false,
  });
  for (const h of ['07', '09', '11', '13', '15', '17', '19', '21', '23']) {
    batch.set(col.doc(), {
      type: 'bottle',
      occurredAt: at(date, `${h}:00`),
      endedAt: null,
      deleted: false,
    });
  }
  await batch.commit();
  return sleepId;
}

beforeAll(() => {
  app = initializeApp({ projectId }, `rhythm-${randomUUID()}`);
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
    'content',
    'users',
    'staffAudit',
  ]) {
    await db.recursiveDelete(db.collection(c));
  }
  await db.doc('config/flags').set({ rhythm: on, personalization: on, ai_assist: on });
  // Beta A for test_f1 only; test_f2 is a free family in the same country.
  await db.doc('config/entitlements').set({
    ...defaultEntitlementsConfig,
    regions: { advanced: ['VN'] },
    betaCampaigns: [
      {
        id: 'beta-a',
        capabilities: ['personalization.cross_module', 'rhythm.advanced', 'ai.assistance'],
        validFrom: '2026-10-01T00:00:00Z',
        validUntil: '2026-10-20T00:00:00Z',
        countries: [],
        scope: 'internal',
        percent: 0,
        families: ['test_f1'],
      },
    ],
  });
  await db.doc('publicConfig/content_rhythm').set(content());
  for (const [baby, family, owner] of [
    [B, 'test_f1', 'test_mom'],
    [B2, 'test_f2', 'test_mom2'],
  ] as const) {
    await db.doc(`babies/${baby}`).set({
      familyId: family,
      timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' },
      state: 'active',
    });
    // 60 days old on 2026-10-14.
    await db.doc(`babies/${baby}/restricted/profile`).set({ dateOfBirth: '2026-08-15' });
    await db.doc(`families/${family}`).set({ ownerUid: owner, country: 'VN' });
    await db
      .doc(`babies/${baby}/members/${owner}`)
      .set({ role: 'coParent', isOwner: true, status: 'active' });
  }
  await db.doc(`babies/${B}/members/test_dad`).set({ role: 'coParent', status: 'active' });
  await db.doc(`babies/${B}/members/test_nanny`).set({ role: 'caregiver', status: 'active' });
  await db.doc(`babies/${B}/members/test_grandma`).set({
    role: 'relative',
    status: 'active',
    extraRights: { viewBabyInfo: false, viewDailyCare: true },
  });
  await db.doc(`babies/${B}/members/test_aunt`).set({ role: 'relative', status: 'active' });
});

describe('nextAction · plan gates (M01)', () => {
  it('a free family gets the age card and PREMIUM_REQUIRED, never an error', async () => {
    const id = await saveCheckIn('test_mom2', {}, B2);
    const a = await ask('test_mom2', id, now, B2);
    expect(a).toEqual({
      state: 'free_content',
      recommendation: null,
      secondary: [],
      ageCardId: 'age_w9',
      gate: 'PREMIUM_REQUIRED',
      sleep: null,
    });
    expect((await db.collection(`babies/${B2}/recommendations`).get()).size).toBe(0);
  });

  it('a beta family gets a suggestion for the reported need (SELF_REPORTED_NEED)', async () => {
    const id = await saveCheckIn('test_mom');
    const a = await ask('test_mom', id);
    expect(a.state).toBe('suggestion');
    expect(a.gate).toBeNull();
    expect(a.ageCardId).toBe('age_w9');
    expect(a.recommendation).toMatchObject({
      id: `rec_${id.slice(3)}`,
      contentId: 'act_sleep_dim',
      contentVersion: 1,
      reasonCode: 'SELF_REPORTED_NEED',
      supportingIds: [id],
      requiredCapability: 'personalization.cross_module',
      state: 'suggested',
      changes: [],
      generatedAt: now.toISOString(),
    });
    expect(a.secondary).toEqual([
      { contentId: 'act_sleep_song', contentVersion: 1 },
      { contentId: 'act_sleep_walk', contentVersion: 1 },
    ]);
    expect(a.sleep).toMatchObject({ status: 'insufficient_data', validDays: 0 });
    const stored = await db.doc(`babies/${B}/recommendations/rec_${id.slice(3)}`).get();
    expect(stored.get('contentId')).toBe('act_sleep_dim');
    // Notes never leave the check-in.
    expect(JSON.stringify(stored.data())).not.toContain('ghi chú');
  });

  it('"Bình thường" (usual) → normal, with the free card', async () => {
    const id = await saveCheckIn('test_mom', { observation: 'usual' });
    const a = await ask('test_mom', id);
    expect(a).toMatchObject({ state: 'normal', recommendation: null, ageCardId: 'age_w9' });
  });

  it('health signs → health, no suggestion and no gate, even after the beta ended', async () => {
    const afterBeta = new Date('2026-11-01T05:00:00Z');
    for (const [uid, baby] of [
      ['test_mom', B],
      ['test_mom2', B2],
    ] as const) {
      const id = await saveCheckIn(
        uid,
        { observation: 'health', healthSigns: ['breathing'] },
        baby,
      );
      expect(await ask(uid, id, afterBeta, baby)).toEqual({
        state: 'health',
        recommendation: null,
        secondary: [],
        ageCardId: null,
        gate: null,
        sleep: null,
      });
    }
    // A sleep check-in that also answered "Có" to a sign is still health first.
    const id = await saveCheckIn('test_mom', { healthSigns: ['fever_young'] });
    expect((await ask('test_mom', id)).state).toBe('health');
    expect((await db.collection(`babies/${B}/recommendations`).get()).size).toBe(0);
  });

  it('the same check-in returns the same stored recommendation (idempotent)', async () => {
    const id = await saveCheckIn('test_mom');
    const first = await ask('test_mom', id);
    // Feedback in between does not change a retry of the same check-in.
    await giveFeedback('act_sleep_dim', 'not_suitable', later(5));
    const again = await ask('test_mom', id, later(10));
    expect(again).toEqual(first);
    expect((await db.collection(`babies/${B}/recommendations`).get()).size).toBe(1);
  });

  it('an edited check-in (new revision) is ranked again', async () => {
    const id = await saveCheckIn('test_mom');
    await ask('test_mom', id);
    await saveCheckIn('test_mom', { id, observation: 'feeding', revision: 2 });
    const a = await ask('test_mom', id, later(10));
    expect(a.recommendation).toMatchObject({ contentId: 'act_feed_calm' });
  });

  it('no published content → no_suggestion (beta) / no age card (free), never an error', async () => {
    await db.doc('publicConfig/content_rhythm').delete();
    const beta = await ask('test_mom', await saveCheckIn('test_mom'));
    expect(beta).toMatchObject({ state: 'no_suggestion', ageCardId: null, gate: null });
    const free = await ask('test_mom2', await saveCheckIn('test_mom2', {}, B2), now, B2);
    expect(free).toMatchObject({
      state: 'free_content',
      ageCardId: null,
      gate: 'PREMIUM_REQUIRED',
    });
    expect((await home('test_mom2', now, B2)).state).toBe('free_content');
  });

  it('a check-in that does not exist or belongs elsewhere is refused', async () => {
    expect(await reason(ask('test_mom', ciId()))).toBe('checkin-not-found');
    expect(await reason(ask('test_mom', 'ci_bad'))).toBe('bad-request');
  });
});

describe('roles (D-072 #2)', () => {
  it('a caregiver gets the next action; relatives are ROLE_DENIED; strangers NOT_MEMBER', async () => {
    const id = await saveCheckIn('test_nanny');
    expect((await ask('test_nanny', id)).state).toBe('suggestion');
    expect(await reason(ask('test_grandma', id))).toBe('ROLE_DENIED');
    expect(await reason(ask('test_aunt', id))).toBe('ROLE_DENIED');
    expect(await reason(ask('test_mom2', id))).toBe('NOT_MEMBER');
  });

  it('composeHome: history.read roles read the household card; others are refused', async () => {
    await ask('test_mom', await saveCheckIn('test_mom'));
    expect((await home('test_nanny')).recommendation?.contentId).toBe('act_sleep_dim');
    expect((await home('test_grandma')).recommendation?.contentId).toBe('act_sleep_dim');
    expect(await reason(home('test_aunt'))).toBe('ROLE_DENIED');
    expect(await reason(home('test_mom2'))).toBe('NOT_MEMBER');
  });

  it('the rhythm kill switch closes nextAction; the free Home answers with the reason', async () => {
    await db.doc('config/flags').set({ rhythm: { ...on, enabled: false }, personalization: on });
    const id = await saveCheckIn('test_mom');
    expect(await reason(ask('test_mom', id))).toBe('FEATURE_DISABLED');
    expect(await home('test_mom')).toMatchObject({
      state: 'free_content',
      gate: 'FEATURE_DISABLED',
      ageCardId: 'age_w9',
    });
  });
});

describe('composeHome · feedback changes the next Home (M18, PS02)', () => {
  beforeEach(async () => {
    await ask('test_mom', await saveCheckIn('test_mom'));
  });

  it('without feedback: the stored primary, nothing changed', async () => {
    const h = await home('test_mom', later(30));
    expect(h).toMatchObject({
      state: 'suggestion',
      gate: null,
      ageCardId: 'age_w9',
      lastFeedback: null,
    });
    expect(h.recommendation).toMatchObject({ contentId: 'act_sleep_dim', changes: [] });
  });

  it('"Có ích" on another item makes it the primary (PREVIOUS_HELPFUL)', async () => {
    const fb = await giveFeedback('act_sleep_song', 'helpful', later(60), 'test_dad');
    const h = await home('test_mom', later(120));
    expect(h.recommendation).toMatchObject({
      contentId: 'act_sleep_song',
      reasonCode: 'PREVIOUS_HELPFUL',
      changes: ['prefers_helpful'],
      state: 'suggested',
    });
    expect(h.recommendation?.supportingIds).toContain(fb);
    expect(h.lastFeedback).toEqual({
      id: fb,
      contentId: 'act_sleep_song',
      kind: 'helpful',
      date: '2026-10-14',
      authorUid: 'test_dad',
    });
    // Stable on the next open; one shown recommendation.
    const again = await home('test_mom', later(180));
    expect(again.recommendation?.id).toBe(h.recommendation?.id);
    const shown = await db
      .collection(`babies/${B}/recommendations`)
      .where('state', '==', 'suggested')
      .get();
    expect(shown.size).toBe(1);
  });

  it('"Không phù hợp" excludes the item for this baby', async () => {
    const fb = await giveFeedback('act_sleep_dim', 'not_suitable', later(60));
    const h = await home('test_mom', later(120));
    expect(h.recommendation).toMatchObject({
      contentId: 'act_sleep_song',
      changes: ['excluded_not_suitable'],
    });
    expect(h.lastFeedback?.id).toBe(fb);
    expect(h.secondary.map((s) => s.contentId)).not.toContain('act_sleep_dim');
  });

  it('"Không phải hôm nay" cools the item down', async () => {
    await giveFeedback('act_sleep_dim', 'not_today', later(60));
    const h = await home('test_mom', later(120));
    expect(h.recommendation).toMatchObject({
      contentId: 'act_sleep_song',
      changes: ['cooling_down'],
    });
    expect(h.lastFeedback?.kind).toBe('not_today');
  });

  it('"Mình sẽ thử" marks the suggestion started and keeps it', async () => {
    await giveFeedback('act_sleep_dim', 'started', later(60));
    const h = await home('test_mom', later(120));
    expect(h.recommendation).toMatchObject({ contentId: 'act_sleep_dim', state: 'started' });
  });

  it('a free family: the age card and the gate', async () => {
    expect(await home('test_mom2', now, B2)).toMatchObject({
      state: 'free_content',
      recommendation: null,
      ageCardId: 'age_w9',
      gate: 'PREMIUM_REQUIRED',
      lastFeedback: null,
    });
  });

  it('after the beta ends the free Home still answers', async () => {
    const h = await home('test_mom', new Date('2026-11-01T05:00:00Z'));
    expect(h).toMatchObject({ state: 'free_content', gate: 'PREMIUM_REQUIRED' });
  });
});

describe('sleep from the log (M13, B01–B06)', () => {
  const today = '2026-10-14';
  const baselineDays = Array.from({ length: 7 }, (_, i) => dateAdd(today, -10 + i)); // 10-04 … 10-10
  const recentDays = [dateAdd(today, -3), dateAdd(today, -2), dateAdd(today, -1)];

  it('enough valid days and shorter recent nights → change_detected → DATA_INSIGHT', async () => {
    for (const d of baselineDays) await logDay(d, '08:00');
    for (const d of recentDays) await logDay(d, '05:00');
    const a = await ask('test_mom', await saveCheckIn('test_mom'));
    expect(a.sleep).toEqual({
      status: 'change_detected',
      baseline: 480,
      recent: 300,
      validDays: 10,
    });
    expect(a.recommendation?.reasonCode).toBe('DATA_INSIGHT');
  });

  it('missing days are not zero: too few valid days → insufficient_data', async () => {
    for (const d of baselineDays.slice(0, 3)) await logDay(d, '08:00');
    for (const d of recentDays) await logDay(d, '05:00');
    const a = await ask('test_mom', await saveCheckIn('test_mom'));
    expect(a.sleep).toEqual({
      status: 'insufficient_data',
      baseline: null,
      recent: null,
      validDays: 6,
    });
    expect(a.recommendation?.reasonCode).toBe('SELF_REPORTED_NEED');
  });

  it('a sleep timer still running invalidates the days it covers', async () => {
    for (const d of baselineDays) await logDay(d, '08:00');
    for (const d of recentDays) await logDay(d, '05:00');
    await db.doc(`babies/${B}/timers/sleep`).set({
      type: 'sleep',
      startedAt: at(recentDays[1]!, '20:00'),
    });
    const a = await ask('test_mom', await saveCheckIn('test_mom'));
    expect(a.sleep).toMatchObject({ status: 'insufficient_data', validDays: 8 });
  });

  it('an unresolved overlap invalidates its days', async () => {
    for (const d of baselineDays) await logDay(d, '08:00');
    const ids = [];
    for (const d of recentDays) ids.push(await logDay(d, '05:00'));
    await db.doc(`babies/${B}/conflicts/c1`).set({
      status: 'open',
      recordIds: [ids[1], ids[2]],
    });
    const a = await ask('test_mom', await saveCheckIn('test_mom'));
    expect(a.sleep).toMatchObject({ status: 'insufficient_data', validDays: 8 });
  });

  it('a free family gets no sleep comparison (rhythm.advanced)', async () => {
    const a = await ask('test_mom2', await saveCheckIn('test_mom2', {}, B2), now, B2);
    expect(a.sleep).toBeNull();
  });
});

describe('two authors, one day, and the facts version (M14)', () => {
  const version = async () =>
    ((await db.doc(`babies/${B}/facts/state`).get()).get('dataVersion') as number | undefined) ?? 0;
  const day = () => db.doc(`babies/${B}/facts/day_2026-10-14`).get();

  it('mother "normal" and father "changed" are both kept → mixed', async () => {
    const mom = await saveCheckIn('test_mom', { observation: 'usual' });
    const momSnap = await db.doc(`babies/${B}/checkins/${mom}`).get();
    await onCheckInWritten(db, B, null, momSnap, now);
    expect((await day()).get('state')).toBe('normal');
    const dad = await saveCheckIn('test_dad', { observation: 'sleep' });
    const dadSnap = await db.doc(`babies/${B}/checkins/${dad}`).get();
    await onCheckInWritten(db, B, null, dadSnap, now);
    expect((await day()).data()).toMatchObject({
      state: 'mixed',
      checkIns: 2,
      normal: 1,
      changed: 1,
    });
    expect((await db.collection(`babies/${B}/checkins`).get()).size).toBe(2);
    expect(await version()).toBe(2);

    // Father edits (revision 2): the version moves; deleting it leaves the mother's "normal".
    const before = dadSnap;
    await saveCheckIn('test_dad', { id: dad, observation: 'usual', revision: 2 });
    const after = await db.doc(`babies/${B}/checkins/${dad}`).get();
    await onCheckInWritten(db, B, before, after, now);
    expect(await version()).toBe(3);
    expect((await day()).get('state')).toBe('normal');
    await db.doc(`babies/${B}/checkins/${dad}`).delete();
    await onCheckInWritten(db, B, after, null, now);
    expect(await version()).toBe(4);
    expect((await day()).get('checkIns')).toBe(1);
    await db.doc(`babies/${B}/checkins/${mom}`).delete();
    await onCheckInWritten(db, B, momSnap, null, now);
    expect((await day()).exists).toBe(false);
    expect(await version()).toBe(5);
  });

  it('feedback and care writes bump the same version', async () => {
    await bumpDataVersion(db, B, now);
    await bumpDataVersion(db, B, now);
    expect(await version()).toBe(2);
  });

  it('a profile being deleted gets nothing written back by late triggers', async () => {
    await db.doc(`babies/${B}`).update({ state: 'deleting' });
    expect(await bumpDataVersion(db, B, now)).toBe(false);
    expect((await db.doc(`babies/${B}/facts/state`).get()).exists).toBe(false);
  });
});

describe('due date (NL02b)', () => {
  const due = { date: '2026-09-05', estimated: true, gestation: { weeks: 37, days: 0 } };

  it('Cùng nuôi set and clear it next to the date of birth', async () => {
    expect(await setDueDate(db, 'test_mom', { babyId: B, dueDate: due }, now, 'test')).toEqual({
      dueDate: due,
    });
    const p = await db.doc(`babies/${B}/restricted/profile`).get();
    expect(p.get('dueDate')).toEqual(due);
    expect(p.get('dateOfBirth')).toBe('2026-08-15');
    await setDueDate(db, 'test_dad', { babyId: B, dueDate: null }, now, 'test');
    expect((await db.doc(`babies/${B}/restricted/profile`).get()).get('dueDate')).toBeNull();
  });

  it('caregivers and relatives cannot; nonsense dates are refused', async () => {
    const set = (uid: string, dueDate: unknown) =>
      reason(setDueDate(db, uid, { babyId: B, dueDate }, now, 'test'));
    expect(await set('test_nanny', due)).toBe('ROLE_DENIED');
    expect(await set('test_grandma', due)).toBe('ROLE_DENIED');
    expect(await set('test_mom2', due)).toBe('NOT_MEMBER');
    expect(await set('test_mom', { ...due, date: '2027-03-01' })).toBe('due-date-out-of-range');
    expect(await set('test_mom', { ...due, date: '15/09/2026' })).toBe('bad-request');
  });
});

describe('staff publishing (PN01–PN04, first-aid workflow)', () => {
  beforeEach(async () => {
    // Start from nothing published (the app fixture above is `rc_20261014_01`).
    await db.doc('publicConfig/content_rhythm').delete();
  });
  const draft = (staff: Staff, data = contentData(), notes = 'Bản đầu') =>
    rhythmDraft(db, staff, { doc: 'content', data, notes }, now);
  const act = (
    staff: Staff,
    versionId: string,
    action: string,
    requireReview = false,
    extra = {},
  ) =>
    rhythmAct(
      db,
      { requireReview },
      staff,
      { doc: 'content', versionId, action, reason: 'Kiểm tra xong', review: null, ...extra },
      now,
    );

  it('draft → submit → a second person approves → publicConfig/content_rhythm', async () => {
    const { versionId } = await draft(ops);
    expect(await reason(act(expert, versionId, 'approve'))).toBe('not-pending');
    await act(ops, versionId, 'submit');
    expect(await reason(act(ops, versionId, 'approve'))).toBe('role');
    // The author cannot approve their own version, even with the right.
    const both: Staff = { uid: ops.uid, name: ops.name, roles: ['ops', 'expert'] };
    expect(await reason(act(both, versionId, 'approve'))).toBe('same-person');
    expect(await act(expert, versionId, 'approve')).toEqual({
      status: 'published',
      version: 'rc_20261014_01',
    });
    const pub = (await db.doc('publicConfig/content_rhythm').get()).data();
    expect(pub).toMatchObject({ version: 'rc_20261014_01', publishedAt: now.toISOString() });
    expect(pub?.activities).toHaveLength(4);
    const audit = await db.collection('staffAudit').where('category', '==', 'content').get();
    expect(audit.docs.map((d) => d.get('action'))).toEqual(
      expect.arrayContaining([
        'content.rhythm.content.draft',
        'content.rhythm.content.submit',
        'content.rhythm.content.approve',
      ]),
    );
    const view = (await rhythmView(db, { requireReview: false }, ops)) as unknown as {
      content: { current: { version: string }; draft: unknown };
    };
    expect(view.content.current.version).toBe('rc_20261014_01');
    expect(view.content.draft).toBeNull();
  });

  it('prod: approving needs a recorded review, stamped on unreviewed items', async () => {
    const { versionId } = await draft(ops);
    await act(ops, versionId, 'submit');
    expect(await reason(act(expert, versionId, 'approve', true))).toBe('review-required');
    const review = { reviewer: 'BS. Lan', credential: 'Nhi khoa', reviewedOn: '2026-10-14' };
    await act(expert, versionId, 'approve', true, { review });
    const pub = (await db.doc('publicConfig/content_rhythm').get()).data();
    expect(pub?.activities[0].review).toEqual(review);
    expect(pub?.health.review).toEqual(review);
  });

  it('reference model: publishes ref_YYYYMMDD_NN', async () => {
    const data = {
      label: 'Wonder Weeks',
      stages: [
        {
          id: 'leap_1',
          number: 1,
          startOffsetDays: 28,
          endOffsetDays: 38,
          name: L('Giai đoạn 1'),
          signs: LL('Bám mẹ hơn'),
          skills: LL('Nhìn lâu hơn'),
          activityIds: ['act_sleep_dim'],
          notice: null,
        },
      ],
      sources: [],
      review: null,
    };
    const { versionId } = await rhythmDraft(db, ops, { doc: 'reference', data, notes: '' }, now);
    const refAct = (s: Staff, action: string) =>
      rhythmAct(
        db,
        { requireReview: false },
        s,
        { doc: 'reference', versionId, action, reason: 'Kiểm tra xong', review: null },
        now,
      );
    await refAct(ops, 'submit');
    expect(await refAct(expert, 'approve')).toMatchObject({ version: 'ref_20261014_01' });
    expect((await db.doc('publicConfig/rhythm_reference').get()).get('stages')).toHaveLength(1);
  });

  it('reject sends it back; a new release the same day is _02; rollback re-publishes', async () => {
    const first = await draft(ops);
    await act(ops, first.versionId, 'submit');
    await act(expert, first.versionId, 'approve');
    const changed = contentData();
    changed.activities = changed.activities.slice(0, 2);
    const second = await draft(ops, changed, 'Bớt bài');
    await act(ops, second.versionId, 'submit');
    expect(await act(expert, second.versionId, 'reject')).toEqual({ status: 'draft' });
    await act(ops, second.versionId, 'submit');
    expect(await act(expert, second.versionId, 'approve')).toMatchObject({
      version: 'rc_20261014_02',
    });
    expect((await db.doc('publicConfig/content_rhythm').get()).get('activities')).toHaveLength(2);
    expect(await reason(act(ops, first.versionId, 'rollback'))).toBe('role');
    expect(await act(expert, first.versionId, 'rollback')).toMatchObject({
      version: 'rc_20261014_03',
    });
    expect((await db.doc('publicConfig/content_rhythm').get()).get('activities')).toHaveLength(4);
    const published = await db
      .collection('content/rhythm/content')
      .where('status', '==', 'published')
      .get();
    expect(published.size).toBe(1);
  });

  it('a malformed draft is refused; a content viewer cannot draft', async () => {
    expect(
      await reason(
        rhythmDraft(db, ops, { doc: 'content', data: { activities: 1 }, notes: '' }, now),
      ),
    ).toBe('malformed');
    const support: Staff = { uid: 's_support', name: 'Hỗ trợ', roles: ['support'] };
    expect(await reason(draft(support))).toBe('role');
  });

  it('rules (PN04): Tính năng · Sửa saves versioned thresholds with a reason', async () => {
    expect((await rhythmRulesView(db, ops)).rules).toEqual(defaultRhythmRules);
    const rules = { ...defaultRhythmRules, version: 'rules-v2', cooldownDays: 5 };
    expect(await reason(setRhythmRules(db, ops, { rules, reason: 'Thử nghiệm' }, now))).toBe(
      'role',
    );
    expect(
      await reason(
        setRhythmRules(db, eng, { rules: { ...rules, baselineMinDays: 9 }, reason: 'x x x' }, now),
      ),
    ).toBe('malformed');
    await setRhythmRules(db, eng, { rules, reason: 'Thử nghiệm' }, now);
    expect((await rhythmRulesView(db, eng)).rules.cooldownDays).toBe(5);
    expect((await db.doc('config/rhythm').get()).get('rules.version')).toBe('rules-v2');
  });
});
