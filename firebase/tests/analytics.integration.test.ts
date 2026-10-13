import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  analytics,
  backfillDays,
  exportAnalytics,
  isoWeek,
  markDeviceActivity,
  recordAcquisition,
  rollupDay,
} from '../functions/src/analytics.js';
import { StaffError, overview, type AccountLister, type Staff } from '../functions/src/staff.js';

// Phân tích v1.0 against the Firestore emulator (A13 / A14, P-137): the device heartbeat marks
// families active, the nightly rollup adds write activity and computes DAU / WAU / MAU, D30, new
// families by channel, feature use, storage and versions; the portal reads aggregates only.
const projectId = 'demo-child-life';
const GB = 1024 ** 3;
const DAY = '2026-10-10';
const at = (day: string, hour = 10) =>
  new Date(`${day}T${String(hour).padStart(2, '0')}:00:00+07:00`);
const now = at('2026-10-11', 1);
let app: App;
let db: Firestore;

const ops: Staff = { uid: 's_ops', name: 'Hà Vũ', roles: ['ops'] };
const analyst: Staff = { uid: 's_an', name: 'Bình Trịnh', roles: ['analyst'] };
const qa: Staff = { uid: 's_qa', name: 'Thu Hà', roles: ['qa'] };

const reason = async (p: Promise<unknown>) => {
  try {
    await p;
    return 'ok';
  } catch (e) {
    return e instanceof StaffError ? e.reason : String(e);
  }
};

async function family(
  id: string,
  owner: string,
  created: Date,
  babyId: string,
  extra: Record<string, unknown> = {},
) {
  await db.doc(`families/${id}`).set({
    ownerUid: owner,
    quotaBytes: 10 * GB,
    usedBytes: 1 * GB,
    babyIds: [babyId],
    createdAt: created,
    ...extra,
  });
  await db.doc(`babies/${babyId}`).set({ familyId: id, ownerUid: owner, nickname: 'Bé' });
  await db
    .doc(`babies/${babyId}/members/${owner}`)
    .set({ uid: owner, babyId, role: 'coParent', status: 'active', isOwner: true });
}

beforeAll(() => {
  app = initializeApp({ projectId }, `analytics-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080';
  await fetch(`http://${host}/emulator/v1/projects/${projectId}/databases/(default)/documents`, {
    method: 'DELETE',
  });
  // f1: 35 days old, owner arrived from the website (Android referrer), opens the app on DAY.
  await family('f1', 'ann', at('2026-09-05'), 'b1', {
    usedBytes: 9 * GB,
    usage: { b1: { photoBytes: 5 * GB, videoBytes: 3 * GB } },
  });
  await db.doc('users/ann').set({ acquisition: { channel: 'website', at: at('2026-09-05') } });
  // f2: born on DAY; its owner first joined f1 through an invitation; logs a bottle on DAY.
  await family('f2', 'bao', at(DAY, 9), 'b2', { quotaBytes: 20 * GB });
  await db.doc('babies/b1/members/bao').set({
    uid: 'bao',
    babyId: 'b1',
    role: 'relative',
    status: 'active',
    inviteId: 'i_1',
    isOwner: false,
  });
  await db
    .doc('babies/b2/records/r1')
    .set({ babyId: 'b2', type: 'bottle', createdAt: at(DAY, 11) });
  await db
    .doc('babies/b2/records/r2')
    .set({ babyId: 'b2', type: 'growth', createdAt: at(DAY, 12) });
  await db.doc('babies/b2/media/m1').set({ babyId: 'b2', type: 'photo', createdAt: at(DAY, 12) });
  await db
    .doc('users/bao/devices/d_2')
    .set({ platform: 'android', appVersion: '1.0.1', lastActiveAt: at(DAY, 8) });
  // f3: born on DAY, no install source → "Kho ứng dụng & khác".
  await family('f3', 'cuc', at(DAY, 15), 'b3');
});

describe('heartbeat and the nightly rollup', () => {
  it('counts families active by opening the app or by writing, with platforms and channels', async () => {
    expect(isoWeek('2026-10-11')).toBe('2026-W41');
    expect(isoWeek('2026-10-12')).toBe('2026-W42');
    const device = { platform: 'ios', appVersion: '1.0.3', lastActiveAt: at(DAY, 7) };
    await db.doc('users/ann/devices/d_1').set(device);
    expect(await markDeviceActivity(db, 'ann', undefined, device)).toBe(1);
    // The same day again changes nothing; f1 kept its day-30 activity (created 2026-09-05).
    expect(await markDeviceActivity(db, 'ann', device, device)).toBe(0);
    await db.doc('familyActivity/f1').set({ days: { '2026-10-06': true } }, { merge: true });

    const s = await rollupDay(db, DAY, now);
    expect(s.dau).toEqual({ all: 2, ios: 1, android: 0 });
    expect(s.mau.all).toBe(2);
    expect(s.newFamilies).toEqual({ all: 2, ios: 0, android: 1, invite: 1, website: 0, store: 1 });
    expect(s.d30).toBe(1);
    expect(s.features).toMatchObject({ feeding: 1, growth: 1, memories: 1, sleep: 0 });
    expect(s.weekFamilies.feeding.all).toBe(1);
    expect(s.relativeFamilies).toBe(1);
    expect(s.storage).toMatchObject({
      usedBytes: 11 * GB,
      photoBytes: 5 * GB,
      videoBytes: 3 * GB,
      otherBytes: 3 * GB,
      baseFamilies: 2,
      expandedFamilies: 1,
      over80Families: 1,
    });
    expect(s.versions).toEqual([
      { platform: 'ios', version: '1.0.3', devices: 1 },
      { platform: 'android', version: '1.0.1', devices: 1 },
    ]);
    expect(s.cohorts.at(-1)).toMatchObject({ week: '2026-W41', families: 2 });
    expect((await db.doc('familyActivity/f2').get()).get(`weeks.2026-W41`)).toEqual(
      expect.arrayContaining(['feeding', 'growth', 'memories']),
    );
    // A02 now counts the heartbeat family too (one definition, P-137).
    const accounts: AccountLister = { list: async () => [] };
    expect((await overview(db, ops, { days: 7 }, now, accounts)).kpis.activeFamilies).toBe(2);
  });

  it('install source is kept once; backfill fills only missing days', async () => {
    const caller = { uid: 'cuc', email: null, anonymous: false, locale: 'vi' as const };
    await recordAcquisition(db, caller, { channel: 'website' }, now);
    await recordAcquisition(db, caller, { channel: 'store' }, now);
    expect((await db.doc('users/cuc').get()).get('acquisition.channel')).toBe('website');
    expect(await backfillDays(db, now, 2)).toEqual(['2026-10-09', '2026-10-10']);
    expect(await backfillDays(db, now, 2)).toEqual([]);
  });
});

describe('reading and exporting (A13 / A14)', () => {
  it('aggregates for the range; export needs "Phân tích · xuất CSV" and is logged', async () => {
    await rollupDay(db, '2026-10-09', now);
    await rollupDay(db, DAY, now);
    // The app's Góp ý / review-prompt counters (D-065); a day outside the range is left out.
    await db.doc('appEventsDaily/2026-10-09').set({
      day: '2026-10-09',
      feedbackSent_bug: 2,
      reviewPromptEligible: 5,
    });
    await db.doc(`appEventsDaily/${DAY}`).set({
      day: DAY,
      feedbackSent_idea: 1,
      reviewPromptEligible: 3,
      reviewPromptRequested: 1,
      autoSaveSetupDone: 2,
      autoSaveApproved: 15,
    });
    await db.doc('appEventsDaily/2026-09-01').set({ day: '2026-09-01', feedbackSent_idea: 9 });
    const growth = await analytics(db, ops, { tab: 'growth', days: 7, platform: 'all' }, now);
    expect(growth.empty).toBe(false);
    if (growth.empty) return;
    if (!('channels' in growth)) throw new Error('growth tab');
    expect(growth.kpis.dau.value).toBe(1);
    expect(growth.series.map((p) => p.date)).toEqual(['2026-10-09', '2026-10-10']);
    expect(growth.channels).toEqual({ invite: 1, website: 0, store: 1 });
    const feats = await analytics(
      db,
      analyst,
      { tab: 'features', days: 7, platform: 'android' },
      now,
    );
    if (feats.empty || !('features' in feats)) throw new Error('features tab');
    expect(feats.features.find((f) => f.feature === 'feeding')).toMatchObject({ perDay: 0.5 });
    expect(feats.versions).toEqual([{ platform: 'android', version: '1.0.1', devices: 1 }]);
    expect(feats.feedback).toEqual({ idea: 1, bug: 2, other: 0 });
    expect(feats.reviewPrompt).toEqual({ eligible: 8, requested: 1 });
    expect(feats.autoSave).toMatchObject({ setupDone: 2, approved: 15, rejected: 0 });
    expect(await reason(analytics(db, qa, { tab: 'growth', days: 7, platform: 'all' }, now))).toBe(
      'role',
    );
    expect(
      await reason(exportAnalytics(db, ops, { tab: 'growth', days: 30, platform: 'all' }, now)),
    ).toBe('role');
    await exportAnalytics(db, analyst, { tab: 'growth', days: 30, platform: 'all' }, now);
    const log = await db.collection('staffAudit').where('category', '==', 'analytics').get();
    expect(log.docs.map((d) => [d.get('action'), d.get('target')])).toEqual([
      ['analytics.export', 'growth:30d:all'],
    ]);
  });
});
