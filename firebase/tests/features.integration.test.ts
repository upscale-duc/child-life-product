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
    expect(await featureAccess(db, 'mom', { babyId: 'b1' }, now)).toEqual({
      autoSave: false,
      milestoneCards: false,
      memoryStory: false,
      autoSaveBeta: true,
    });
    await db.doc('config/flags').set({
      media_upload: { ...defaultFlags.media_upload, enabled: true },
    });
    expect(await featureAccess(db, 'mom', { babyId: 'b1' }, now)).toEqual({
      autoSave: false,
      milestoneCards: false,
      memoryStory: false,
      autoSaveBeta: true,
    });
  });

  it('internal: staff families only, and only for Cùng nuôi', async () => {
    await autoSave({ scope: 'internal' });
    expect((await featureAccess(db, 'mom', { babyId: 'b1' }, now)).autoSave).toBe(true);
    expect((await featureAccess(db, 'nanny', { babyId: 'b1' }, now)).autoSave).toBe(false);
    await db.doc('families/f1').set({ internal: false });
    expect((await featureAccess(db, 'mom', { babyId: 'b1' }, now)).autoSave).toBe(false);
  });

  it('the families picked in A10 count as internal for this flag only', async () => {
    await db.doc('families/f1').set({ internal: false });
    await autoSave({ scope: 'internal', families: ['f1'] });
    expect((await featureAccess(db, 'mom', { babyId: 'b1' }, now)).autoSave).toBe(true);
    await autoSave({ scope: 'internal', families: ['f9'] });
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

describe('getFeatureAccess · Kỷ niệm 2.0 (D-068)', () => {
  it('each flag stands alone, for Cùng nuôi only', async () => {
    await db.doc('config/flags').set({
      milestone_cards: { ...defaultFlags.milestone_cards, enabled: true, scope: 'all' },
    });
    expect(await featureAccess(db, 'mom', { babyId: 'b1' }, now)).toEqual({
      autoSave: false,
      milestoneCards: true,
      memoryStory: false,
      autoSaveBeta: true,
    });
    expect((await featureAccess(db, 'nanny', { babyId: 'b1' }, now)).milestoneCards).toBe(false);
    await db.doc('config/flags').set({
      memory_story: { ...defaultFlags.memory_story, enabled: true, scope: 'internal' },
    });
    expect(await featureAccess(db, 'mom', { babyId: 'b1' }, now)).toEqual({
      autoSave: false,
      milestoneCards: false,
      memoryStory: true,
      autoSaveBeta: true,
    });
  });
});

describe('getFeatureAccess · the Beta badge follows the portal tier (D-122)', () => {
  it('is Beta by default and not once staff set Tự lưu to Miễn phí', async () => {
    await autoSave({ scope: 'all' });
    expect((await featureAccess(db, 'mom', { babyId: 'b1' }, now)).autoSaveBeta).toBe(true);
    await db.doc('config/features').set({
      features: { auto_save: { tier: 'free', betaFamilies: [], grace: null } },
    });
    const access = await featureAccess(db, 'mom', { babyId: 'b1' }, now);
    expect(access.autoSave).toBe(true);
    expect(access.autoSaveBeta).toBe(false);
  });
});
