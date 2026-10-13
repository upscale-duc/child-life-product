import { randomUUID } from 'node:crypto';
import { defaultFlags } from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { familyBucket, featureAccess } from '../functions/src/features.js';

// P-148 `getFeatureAccess`: the `auto_save` rollout of Tự lưu kỷ niệm (D-066) per family, against
// the Firestore emulator. Its own project: these tests rewrite the global `config/flags` and
// must not race the other files running at the same time.
const projectId = 'demo-child-life-features';
const now = new Date('2026-10-13T03:00:00Z');
let app: App;
let db: Firestore;
const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason,
  );
const autoSave = (over: Record<string, unknown>) =>
  db.doc('config/flags').set({
    media_upload: { ...defaultFlags.media_upload, enabled: true },
    auto_save: { ...defaultFlags.auto_save, enabled: true, ...over },
  });

beforeAll(() => {
  app = initializeApp({ projectId }, `features-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  for (const c of ['babies', 'families', 'config']) {
    await db.recursiveDelete(db.collection(c));
  }
  await db.doc('babies/b1').set({ familyId: 'f1' });
  await db.doc('families/f1').set({ internal: true });
  await db.doc('babies/b1/members/mom').set({ role: 'coParent', status: 'active' });
  await db.doc('babies/b1/members/nanny').set({ role: 'caregiver', status: 'active' });
  await db.doc('babies/b1/members/gone').set({
    role: 'coParent',
    status: 'active',
    accessUntilAt: Timestamp.fromDate(new Date('2026-10-01T00:00:00Z')),
  });
});

describe('getFeatureAccess · auto_save', () => {
  it('is off with no config, and with a document written before the flag existed', async () => {
    expect(await featureAccess(db, 'mom', { babyId: 'b1' }, now)).toEqual({ autoSave: false });
    await db.doc('config/flags').set({
      media_upload: { ...defaultFlags.media_upload, enabled: true },
    });
    expect(await featureAccess(db, 'mom', { babyId: 'b1' }, now)).toEqual({ autoSave: false });
  });

  it('internal: staff families only, and only for Cùng nuôi', async () => {
    await autoSave({ scope: 'internal' });
    expect((await featureAccess(db, 'mom', { babyId: 'b1' }, now)).autoSave).toBe(true);
    expect((await featureAccess(db, 'nanny', { babyId: 'b1' }, now)).autoSave).toBe(false);
    await db.doc('families/f1').set({ internal: false });
    expect((await featureAccess(db, 'mom', { babyId: 'b1' }, now)).autoSave).toBe(false);
  });

  it('percent follows the family bucket; all is everyone; off is the kill switch', async () => {
    const bucket = familyBucket('f1');
    await autoSave({ scope: 'percent', percent: bucket + 1 });
    expect((await featureAccess(db, 'mom', { babyId: 'b1' }, now)).autoSave).toBe(true);
    await autoSave({ scope: 'percent', percent: bucket });
    expect((await featureAccess(db, 'mom', { babyId: 'b1' }, now)).autoSave).toBe(false);
    await autoSave({ scope: 'all' });
    expect((await featureAccess(db, 'mom', { babyId: 'b1' }, now)).autoSave).toBe(true);
    await autoSave({ scope: 'all', enabled: false });
    expect((await featureAccess(db, 'mom', { babyId: 'b1' }, now)).autoSave).toBe(false);
  });

  it('refuses strangers, ended access and bad requests', async () => {
    await autoSave({ scope: 'all' });
    expect(await reason(featureAccess(db, 'stranger', { babyId: 'b1' }, now))).toBe('not-a-member');
    expect(await reason(featureAccess(db, 'gone', { babyId: 'b1' }, now))).toBe('not-a-member');
    expect(await reason(featureAccess(db, 'mom', { babyId: '' }, now))).toBe('bad-request');
  });
});
