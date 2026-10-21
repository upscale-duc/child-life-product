import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  defaultEntitlementsConfig,
  defaultFlags,
  defaultUserPreferences,
  feedbackMemory,
  recFeedbackSchema,
} from '@child-life/contracts';
import {
  personalizedDay,
  updatePersonalization,
  reservePersonalizedDigest,
} from '../functions/src/personalization-v2.js';
import { readFeedback } from '../functions/src/rhythm.js';
import { aggregatePersonalizationContent } from '../functions/src/personalization-stats.js';
import contentSeed from '../../content/rhythm/content.seed.json' with { type: 'json' };

const app = initializeApp(
  { projectId: 'demo-child-life-personalization-v2' },
  `pv2-${randomUUID()}`,
);
const db = getFirestore(app);
const now = new Date('2026-10-20T12:00:00Z');
const reminderId = `rm_${'1'.repeat(32)}`;
const call = (uid: string, action: Record<string, unknown>, date = now) =>
  updatePersonalization(db, uid, { babyId: 'baby', action }, date, 'test');
const read = (uid: string, date = now) =>
  personalizedDay(db, uid, { babyId: 'baby', locale: 'vi' }, date, 'test');
const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason,
  );
/** Group A (cross-module ranking, feedback memory) for family `f` through a beta campaign. */
const grantGroupA = () =>
  db.doc('config/entitlements').set({
    ...defaultEntitlementsConfig,
    regions: { advanced: ['VN'] },
    betaCampaigns: [
      {
        id: 'beta-pv2',
        capabilities: ['personalization.cross_module', 'rhythm.advanced', 'ai.assistance'],
        validFrom: '2026-10-01T00:00:00Z',
        validUntil: '2026-11-01T00:00:00Z',
        countries: [],
        scope: 'internal',
        percent: 0,
        families: ['f'],
      },
    ],
  });
beforeAll(() => {
  expect(process.env.FIRESTORE_EMULATOR_HOST).toBeTruthy();
});
afterAll(() => deleteApp(app));
beforeEach(async () => {
  for (const collection of await db.listCollections()) await db.recursiveDelete(collection);
  const flag = { ...defaultFlags.rhythm, enabled: true, scope: 'all' };
  await db.doc('config/flags').set({ rhythm: flag, personalization: flag });
  await db.doc('publicConfig/content_rhythm').set(contentSeed);
  await db.doc('families/f').set({ ownerUid: 'parent', country: 'VN' });
  await db
    .doc('babies/baby')
    .set({ familyId: 'f', state: 'active', timeZone: { zone: 'Asia/Ho_Chi_Minh' } });
  await db.doc('babies/baby/restricted/profile').set({ dateOfBirth: '2026-08-15' });
  for (const [uid, role] of [
    ['parent', 'coParent'],
    ['carer', 'caregiver'],
    ['carer2', 'caregiver'],
    ['relative', 'relative'],
  ]) {
    await db.doc(`babies/baby/members/${uid}`).set({
      uid,
      role,
      status: 'active',
      displayName: uid,
      relation: 'other',
      relationCustom: null,
      permissions: { dailyCare: true },
    });
  }
  await db.doc(`babies/baby/reminders/${reminderId}`).set({
    title: 'Việc gia đình đã đặt',
    dueAt: Timestamp.fromDate(now),
    done: false,
    assigneeUid: 'carer',
  });
});
describe('P-172 scoped, expiring personalization', () => {
  it('does not let a client choose another author or write across family boundaries', async () => {
    expect(
      await reason(
        updatePersonalization(
          db,
          'outsider',
          { babyId: 'baby', action: { kind: 'context', value: 'busy' } },
          now,
          'test',
        ),
      ),
    ).toBe('NOT_MEMBER');
    expect(
      await reason(call('parent', { kind: 'context', value: 'busy', authorUid: 'carer' })),
    ).toBe('bad-request');
    expect(await reason(call('relative', { kind: 'context', value: 'busy' }))).toBe('ROLE_DENIED');
  });
  it('expires capacity and goals and isolates two caregivers', async () => {
    await call('carer', { kind: 'context', value: 'busy' });
    await call('carer', { kind: 'focus', value: 'play' });
    expect((await read('carer')).context).toBe('busy');
    expect((await read('parent')).context).toBe('usual');
    expect((await read('carer', new Date('2026-10-20T17:00:00Z'))).context).toBe('usual');
    expect((await read('carer', new Date('2026-10-25T17:00:00Z'))).focus).toBeNull();
  });
  it('separates save, try and helpful; restores visibility without losing the outcome', async () => {
    await call('carer', { kind: 'respond', contentId: 'act_a', value: 'save' });
    expect(
      await reason(call('carer', { kind: 'respond', contentId: 'act_a', value: 'helpful' })),
    ).toBe('try-first');
    expect(
      await reason(call('carer', { kind: 'respond', contentId: 'act_a', value: 'unsure' })),
    ).toBe('try-first');
    await call('carer', { kind: 'respond', contentId: 'act_a', value: 'tried' });
    await call('carer', { kind: 'respond', contentId: 'act_a', value: 'helpful' });
    await call('carer', { kind: 'respond', contentId: 'act_a', value: 'save' });
    const snapshot = await read('carer');
    expect(snapshot.weekly).toEqual({ tried: 1, helpful: 1 });
    expect((await read('parent')).responses).toEqual({});
    await call('carer', { kind: 'respond', contentId: 'act_a', value: 'restore' });
    expect((await read('carer')).responses.act_a?.value).toBe('restore');
    expect((await read('carer')).weekly).toEqual({ tried: 1, helpful: 1 });
    expect(
      await reason(call('carer', { kind: 'respond', contentId: 'act_a', value: 'exclude' })),
    ).toBe('ROLE_DENIED');
  });
  it('a personal restore cannot undo a family exclusion; another co-parent can restore it', async () => {
    const id = contentSeed.activities[0]!.id;
    await call('parent', { kind: 'respond', contentId: id, value: 'exclude' });
    await call('carer', { kind: 'respond', contentId: id, value: 'dislike' });
    await call('carer', { kind: 'respond', contentId: id, value: 'restore' });
    expect((await db.doc(`babies/baby/personalizationExclusions/${id}`).get()).exists).toBe(true);
    await db
      .doc('babies/baby/members/parent2')
      .set({ uid: 'parent2', role: 'coParent', status: 'active' });
    expect((await read('parent2')).sharedExclusions.map((r) => r.id)).toContain(id);
    await call('parent2', { kind: 'respond', contentId: id, value: 'restore' });
    expect((await db.doc(`babies/baby/personalizationExclusions/${id}`).get()).exists).toBe(true);
    expect(
      await reason(
        call('carer', { kind: 'respond', contentId: id, value: 'restore', scope: 'baby' }),
      ),
    ).toBe('ROLE_DENIED');
    await call('parent2', { kind: 'respond', contentId: id, value: 'restore', scope: 'baby' });
    expect((await db.doc(`babies/baby/personalizationExclusions/${id}`).get()).exists).toBe(false);
  });
  it('makes private notes private, preserves author authority and detects revision conflicts', async () => {
    const note = {
      kind: 'note',
      id: 'nb_private',
      revision: 0,
      text: 'Riêng tôi',
      category: 'other',
      scope: 'person',
      days: 1,
      avoidActivityId: null,
    };
    await call('carer', note);
    expect((await read('carer')).notes).toHaveLength(1);
    expect((await read('parent')).notes).toHaveLength(0);
    expect(await reason(call('parent', { ...note, revision: 1, text: 'Sửa của người khác' }))).toBe(
      'ROLE_DENIED',
    );
    expect(await reason(call('carer', note))).toBe('note-conflict');
    expect((await read('carer', new Date('2026-10-20T17:00:00Z'))).notes).toHaveLength(0);
    expect((await read('carer', new Date('2026-10-20T17:00:00Z'))).expiredNotes).toHaveLength(1);
    expect((await read('parent', new Date('2026-10-20T17:00:00Z'))).expiredNotes).toHaveLength(0);
    await call('carer', { kind: 'delete_note', id: 'nb_private', revision: 1 });
    expect((await read('carer', new Date('2026-10-20T17:00:00Z'))).expiredNotes).toHaveLength(0);
  });
  it('suppresses pattern ranges for a health day or explicitly changed routine', async () => {
    await call('parent', { kind: 'routine', unusual: true });
    expect((await read('carer')).unusual).toBe(true);
    expect((await read('carer')).patterns).toEqual([]);
    await db.doc('babies/baby/checkins/health').set({ date: '2026-10-20', observation: 'health' });
    expect((await read('carer')).health).toBe(true);
  });
  it('does not expose restricted growth facts through handover', async () => {
    await db
      .doc('babies/baby/records/growth')
      .set({ type: 'growth', occurredAt: Timestamp.fromDate(now), data: { weightKg: 4 } });
    expect((await read('carer')).lastRecords).toEqual([]);
  });
  it('rejects revoked members and deleting babies on mutation and read', async () => {
    await db.doc('babies/baby/members/carer').update({ status: 'left' });
    expect(await reason(call('carer', { kind: 'context', value: 'busy' }))).toBe('NOT_MEMBER');
    expect(await reason(read('carer'))).toBe('NOT_MEMBER');
    await db.doc('babies/baby').update({ state: 'deleting' });
    expect(await reason(call('parent', { kind: 'context', value: 'busy' }))).not.toBe('ok');
  });
});
describe('P-172 transactional care handover', () => {
  it('permits only the assigned caregiver; concurrent claims have exactly one winner', async () => {
    expect(
      await reason(call('carer2', { kind: 'work', reminderId, transition: 'accept', revision: 0 })),
    ).toBe('ROLE_DENIED');
    const results = await Promise.all([
      reason(call('carer', { kind: 'work', reminderId, transition: 'accept', revision: 0 })),
      reason(call('parent', { kind: 'work', reminderId, transition: 'accept', revision: 0 })),
    ]);
    expect(results.filter((r) => r === 'ok')).toHaveLength(1);
    expect(results.filter((r) => r === 'work-conflict')).toHaveLength(1);
  });
  it('completes an existing reminder once without inventing a care record', async () => {
    await call('carer', { kind: 'work', reminderId, transition: 'accept', revision: 0 });
    await call('carer', { kind: 'work', reminderId, transition: 'accept', revision: 0 });
    await call('carer', { kind: 'work', reminderId, transition: 'complete', revision: 1 });
    await call('carer', { kind: 'work', reminderId, transition: 'complete', revision: 1 });
    expect((await db.doc(`babies/baby/reminders/${reminderId}`).get()).get('doneBy')).toBe('carer');
    expect((await db.collection('babies/baby/records').get()).empty).toBe(true);
    expect((await read('carer')).work).toEqual([]);
  });
  it('lists only my or unassigned work due today or overdue < 24 h; its card snoozes until tonight (audit P2 #4)', async () => {
    const rm = (n: string) => `rm_${n.repeat(32)}`;
    const add = (n: string, dueAt: string, assigneeUid: string | null) =>
      db.doc(`babies/baby/reminders/${rm(n)}`).set({
        title: `Việc ${n}`,
        dueAt: Timestamp.fromDate(new Date(dueAt)),
        done: false,
        assigneeUid,
      });
    await add('3', '2026-09-01T02:00:00Z', 'carer'); // overdue for weeks
    await add('4', '2026-10-19T13:00:00Z', null); // overdue by 23 h
    await add('5', '2026-10-19T11:00:00Z', null); // overdue by 25 h
    await add('6', '2026-10-20T14:00:00Z', 'carer2'); // someone else's
    await add('7', '2026-10-21T03:00:00Z', null); // tomorrow morning
    expect((await read('carer')).work.map((w) => w.id)).toEqual([rm('4'), reminderId]);
    // A co-parent may act on anyone's work in Nhắc việc, but the card is about their own.
    expect((await read('parent')).work.map((w) => w.id)).toEqual([rm('4')]);
    const card = `work:${reminderId}`;
    await call('carer', { kind: 'respond', contentId: card, value: 'snooze' });
    expect((await read('carer')).responses[card]).toMatchObject({
      value: 'snooze',
      until: '2026-10-20T17:00:00.000Z',
    });
    expect(await reason(call('carer', { kind: 'respond', contentId: card, value: 'hide' }))).toBe(
      'bad-request',
    );
    expect(
      await reason(
        call('parent', { kind: 'respond', contentId: card, value: 'restore', scope: 'baby' }),
      ),
    ).toBe('bad-request');
    // A spent snooze is dropped on the next answer, so it never fills the 200-answer limit.
    const tomorrow = new Date('2026-10-21T02:00:00Z');
    await call('carer', { kind: 'respond', contentId: 'act_a', value: 'save' }, tomorrow);
    expect(Object.keys((await read('carer', tomorrow)).responses)).toEqual(['act_a']);
  });
  it('a reminder reopened in Nhắc việc after the work card completed it comes back (audit P2 #5)', async () => {
    await call('carer', { kind: 'work', reminderId, transition: 'accept', revision: 0 });
    await call('carer', { kind: 'work', reminderId, transition: 'complete', revision: 1 });
    expect((await read('carer')).work).toEqual([]);
    // "Hoàn tác" in Nhắc việc writes the reminder directly (D-030); the claim stays `completed`.
    await db
      .doc(`babies/baby/reminders/${reminderId}`)
      .update({ done: false, doneAt: null, doneBy: null });
    expect((await read('carer')).work).toMatchObject([
      { id: reminderId, state: 'unclaimed', actorUid: null, revision: 2 },
    ]);
    await call('carer', { kind: 'work', reminderId, transition: 'accept', revision: 2 });
    expect((await read('carer')).work).toMatchObject([
      { id: reminderId, state: 'accepted', actorUid: 'carer', revision: 3 },
    ]);
    await call('carer', { kind: 'work', reminderId, transition: 'complete', revision: 3 });
    expect((await db.doc(`babies/baby/reminders/${reminderId}`).get()).get('done')).toBe(true);
  });
  it('marks a changed handover without invalidating acknowledgement on a personal context change', async () => {
    const first = await read('carer');
    await call('carer', { kind: 'acknowledge', version: first.handoverVersion });
    await call('carer', { kind: 'context', value: 'few_minutes' });
    expect((await read('carer')).handoverChanged).toBe(false);
    await db.doc(`babies/baby/reminders/${reminderId}`).update({ title: 'Việc đã thay đổi' });
    expect((await read('carer')).handoverChanged).toBe(true);
  });
  it('moves the facts version only for shared facts, never for per-person state (audit P1 #3)', async () => {
    const version = async () =>
      ((await db.doc('babies/baby/facts/state').get()).get('dataVersion') as number | undefined) ??
      0;
    const note = {
      kind: 'note',
      id: 'nb_shared',
      revision: 0,
      text: 'Ghi chú chung',
      category: 'other',
      scope: 'person',
      days: 1,
      avoidActivityId: null,
    };
    const first = await read('carer');
    await call('carer', { kind: 'acknowledge', version: first.handoverVersion });
    await call('carer', { kind: 'context', value: 'few_minutes' });
    await call('carer', { kind: 'focus', value: 'play' });
    await call('parent', { kind: 'digest', enabled: true, deviceId: `d_${'a'.repeat(32)}` });
    await call('parent', { kind: 'routine', unusual: true });
    await call('carer', { kind: 'respond', contentId: 'act_a', value: 'save' });
    await call('carer', note);
    expect(await version()).toBe(0);
    await call('carer', { ...note, revision: 1, scope: 'baby' });
    expect(await version()).toBe(1);
    // Turning a shared note back into a private one removes a shared fact too.
    await call('carer', { ...note, revision: 2 });
    expect(await version()).toBe(2);
    await call('carer', { ...note, revision: 3, scope: 'baby' });
    await call('carer', { kind: 'delete_note', id: 'nb_shared', revision: 4 });
    expect(await version()).toBe(4);
    await call('carer', { kind: 'work', reminderId, transition: 'accept', revision: 0 });
    expect(await version()).toBe(5);
    // A replayed transition changes nothing and does not bump either.
    await call('carer', { kind: 'work', reminderId, transition: 'accept', revision: 0 });
    expect(await version()).toBe(5);
    const id = contentSeed.activities[0]!.id;
    await call('parent', { kind: 'respond', contentId: id, value: 'exclude' });
    expect(await version()).toBe(6);
    await call('parent', { kind: 'respond', contentId: id, value: 'restore' });
    expect(await version()).toBe(6);
    await call('parent', { kind: 'respond', contentId: id, value: 'restore', scope: 'baby' });
    expect(await version()).toBe(7);
  });
});

describe('P-172 daily suggestions and truthful aggregates', () => {
  const device = `d_${'a'.repeat(32)}`;
  const secondDevice = `d_${'b'.repeat(32)}`;
  const reserve = (deviceId = device, date = now) =>
    reservePersonalizedDigest(db, 'parent', { babyId: 'baby', deviceId }, date, 'test');
  it('does not schedule from an old clock choice without explicit enabling', async () => {
    await db.doc('users/parent/settings/personalization').set({ digestTime: '20:30' });
    expect((await reserve()).fireAt).toBeNull();
  });
  it('reserves at most one install/day and retains the original lease after a transfer', async () => {
    await call('parent', { kind: 'digest', enabled: true, deviceId: device });
    expect((await reserve()).fireAt).toBe('2026-10-20T13:30:00.000Z');
    expect((await reserve()).fireAt).toBe('2026-10-20T13:30:00.000Z');
    await call('parent', { kind: 'digest', enabled: true, deviceId: secondDevice });
    expect((await reserve(secondDevice)).fireAt).toBeNull();
    expect((await reserve()).fireAt).toBeNull();
  });
  it('respects quiet hours, busy context, notification switches and revoked access', async () => {
    await call('parent', { kind: 'digest', enabled: true, deviceId: device });
    await db
      .doc('users/parent/settings/personalization')
      .update({ quietHours: { from: '20:00', to: '06:00' } });
    expect((await reserve()).fireAt).toBeNull();
    await db.doc('users/parent/settings/personalization').update({ quietHours: null });
    await call('parent', { kind: 'context', value: 'busy' });
    expect((await reserve()).fireAt).toBeNull();
    await call('parent', { kind: 'context', value: 'usual' });
    await db.doc('users/parent/settings/notifications').set({ rhythm: false });
    expect((await reserve()).fireAt).toBeNull();
    await db.doc('babies/baby/members/parent').update({ status: 'removed' });
    expect(await reason(reserve())).toBe('NOT_MEMBER');
  });
  it('keeps the 20:30 slot when the day changes after it was reserved (audit P1 #2)', async () => {
    const lease = db.doc('users/parent/settings/personalizationDigestLease');
    await call('parent', { kind: 'digest', enabled: true, deviceId: device });
    expect((await reserve()).fireAt).toBe('2026-10-20T13:30:00.000Z');
    const before = (await lease.get()).get('fingerprint') as string;
    // A reminder due earlier becomes the first work item, so the fingerprint changes.
    await db.doc(`babies/baby/reminders/rm_${'2'.repeat(32)}`).set({
      title: 'Việc mới trong ngày',
      dueAt: Timestamp.fromDate(new Date('2026-10-20T11:00:00Z')),
      done: false,
      assigneeUid: 'parent',
    });
    const later = new Date('2026-10-20T13:00:00Z');
    expect((await reserve(device, later)).fireAt).toBe('2026-10-20T13:30:00.000Z');
    const after = (await lease.get()).data()!;
    expect(after.fingerprint).not.toBe(before);
    expect(after.fireAt).toBe('2026-10-20T13:30:00.000Z');
    expect(after.reservedAt).toBe(now.toISOString());
    // The day still belongs to one install, and a delivered slot is not offered again.
    await call('parent', { kind: 'digest', enabled: true, deviceId: secondDevice });
    expect((await reserve(secondDevice, later)).fireAt).toBeNull();
    await call('parent', { kind: 'digest', enabled: true, deviceId: device });
    await db.doc('users/parent/settings/personalization').update({ digestTime: '20:45' });
    expect((await reserve(device, new Date('2026-10-20T13:35:00Z'))).fireAt).toBeNull();
  });
  it('moves a still-pending slot when its designated install changes the digest time', async () => {
    await call('parent', { kind: 'digest', enabled: true, deviceId: device });
    await reserve();
    await db.doc('users/parent/settings/personalization').update({ digestTime: '21:00' });
    expect((await reserve()).fireAt).toBe('2026-10-20T14:00:00.000Z');
    expect(
      (await db.doc('users/parent/settings/personalizationDigestLease').get()).get('fireAt'),
    ).toBe('2026-10-20T14:00:00.000Z');
  });
  it('answers here write the household feedback; the weekly count reads both screens (audit P2 #6)', async () => {
    const [a, b, c] = contentSeed.activities as { id: string; version: number }[];
    await call('carer', { kind: 'respond', contentId: a!.id, value: 'intend' });
    await call('carer', { kind: 'respond', contentId: a!.id, value: 'intend' });
    await call('carer', { kind: 'respond', contentId: a!.id, value: 'tried' });
    await call('carer', { kind: 'respond', contentId: a!.id, value: 'helpful' });
    await call('carer', { kind: 'respond', contentId: a!.id, value: 'save' });
    const rows = (await db.collection('babies/baby/recFeedback').get()).docs.map((d) => d.data());
    expect(rows.map((r) => r.kind).sort()).toEqual(['helpful', 'started']);
    for (const { createdAt, ...row } of rows) {
      // The same keys the Rules let the app write (`validNewFeedback`).
      expect(recFeedbackSchema.strict().safeParse(row).success).toBe(true);
      expect(createdAt).toBeInstanceOf(Timestamp);
      expect(row).toMatchObject({
        babyId: 'baby',
        authorUid: 'carer',
        contentId: a!.id,
        contentVersion: a!.version,
        date: '2026-10-20',
        note: null,
      });
    }
    // What the ranking reads ("feedback visibly changes the next visit").
    expect(feedbackMemory(await readFeedback(db, 'baby'), 3).helpful.has(a!.id)).toBe(true);
    // AC02 on the activity screen writes only the household row; another person's is theirs.
    const ac02 = (id: string, authorUid: string, contentId: string) =>
      db.doc(`babies/baby/recFeedback/${id}`).set({
        id,
        babyId: 'baby',
        authorUid,
        contentId,
        contentVersion: 1,
        kind: 'helpful',
        date: '2026-10-19',
        note: null,
        createdAt: Timestamp.fromDate(new Date('2026-10-19T13:00:00Z')),
      });
    await ac02(`fb_${'d'.repeat(32)}`, 'carer', b!.id);
    await ac02(`fb_${'e'.repeat(32)}`, 'parent', c!.id);
    expect((await read('carer')).weekly).toEqual({ tried: 2, helpful: 2 });
    await grantGroupA();
    expect((await read('carer')).weekly).toEqual({ tried: 2, helpful: 2 });
    // The latest outcome per activity counts, from either source.
    await call('carer', { kind: 'respond', contentId: a!.id, value: 'unsure' });
    expect((await read('carer')).weekly).toEqual({ tried: 2, helpful: 1 });
    expect((await read('parent')).weekly).toEqual({ tried: 1, helpful: 1 });
  });
  it('gives the pick its own reason and refuses choices that changed nothing (audit P2 #7)', async () => {
    await grantGroupA();
    // No need, no focus, no interest: the pick is there for the baby's age.
    const plain = await read('carer');
    expect(plain.activityIds[0]).toBe('act_bed_sharing_safer');
    expect(plain.reason).toBe('AGE_CONTENT');
    expect(await reason(call('carer', { kind: 'focus', value: 'handover' }))).toBe('bad-request');
    expect(await reason(call('carer', { kind: 'focus', value: 'routine' }))).toBe('bad-request');
    expect(await reason(call('carer', { kind: 'context', value: 'other_carer' }))).toBe(
      'bad-request',
    );
    // Stored before they were dropped: read as none, and nothing claims a focus.
    await db.doc('users/carer/personalization/baby').set({
      context: { value: 'other_carer', expiresAt: '2026-10-20T17:00:00.000Z' },
      focus: { value: 'handover', expiresAt: '2026-10-25T17:00:00.000Z' },
    });
    expect(await read('carer')).toMatchObject({
      context: 'usual',
      focus: null,
      reason: 'AGE_CONTENT',
      activityIds: plain.activityIds,
    });
    // The play focus picks play activities, and says so.
    await call('carer', { kind: 'focus', value: 'play' });
    const play = await read('carer');
    expect(play.activityIds[0]).toBe('act_face_to_face');
    expect(play.reason).toBe('WEEKLY_FOCUS');
    // A chosen interest the pick matches is a true INTEREST.
    await call('carer', { kind: 'focus', value: null });
    await db
      .doc('users/carer/settings/personalization')
      .set({ ...defaultUserPreferences, interests: ['milestones'] });
    const interest = await read('carer');
    expect(interest.activityIds[0]).toBe('act_face_to_face');
    expect(interest.reason).toBe('INTEREST');
    // What the family reported today wins over the focus.
    await call('carer', { kind: 'focus', value: 'play' });
    await db
      .doc('babies/baby/checkins/ci_sleep')
      .set({ date: '2026-10-20', observation: 'sleep', updatedAt: now.toISOString() });
    expect((await read('carer')).reason).toBe('SELF_REPORTED_NEED');
  });
  it('aggregates generation separately and is idempotent without overwriting answer counters', async () => {
    const act = contentSeed.activities[0]!;
    await call('parent', { kind: 'respond', contentId: act.id, value: 'save' });
    await call('parent', { kind: 'respond', contentId: act.id, value: 'save' });
    const stat = await db.doc('contentStatsDaily/2026-10-20').get();
    expect(stat.get(`answers.${act.id}__v1.save`)).toBe(1);
    expect(JSON.stringify(stat.data())).not.toContain('parent');
    await db
      .doc('babies/baby/recommendations/r1')
      .set({ contentId: act.id, contentVersion: 1, generatedAt: '2026-10-20T12:00:00.000Z' });
    const next = new Date('2026-10-20T20:00:00Z');
    await aggregatePersonalizationContent(db, next);
    await aggregatePersonalizationContent(db, next);
    const result = (await db.doc('contentStatsDaily/2026-10-20').get()).data()!;
    expect(result.generated[`${act.id}__v1`].count).toBe(1);
    expect(result.answers[`${act.id}__v1`].save).toBe(1);
    expect(JSON.stringify(result)).not.toContain('baby');
  });
});
