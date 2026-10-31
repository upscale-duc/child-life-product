import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, serverTimestamp, setDoc } from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// Hiểu con (D-150, D-151 #6): `babies/{b}/insights/*` is written by Functions only and read by
// parents and caregivers; relatives (even with Chăm sóc hằng ngày) do not see it in V1.
// `insightQueue` is server-only.
const projectId = 'demo-child-life';
let env: RulesTestEnvironment;

const member = (uid: string, role: string, extra: Record<string, unknown> = {}) => ({
  uid,
  babyId: 'b1',
  role,
  status: 'active',
  relation: 'other',
  relationCustom: null,
  displayName: uid,
  ...extra,
});

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: { rules: readFileSync(resolve(import.meta.dirname, '../firestore.rules'), 'utf8') },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'babies/b1'), { nickname: 'Teddy', ownerUid: 'mom', familyId: 'f1' });
    await setDoc(doc(db, 'babies/b1/members/mom'), member('mom', 'coParent', { isOwner: true }));
    await setDoc(doc(db, 'babies/b1/members/nanny'), member('nanny', 'caregiver'));
    await setDoc(
      doc(db, 'babies/b1/members/aunt'),
      member('aunt', 'relative', { extraRights: { viewBabyInfo: true, viewDailyCare: true } }),
    );
    await setDoc(
      doc(db, 'babies/b1/members/gone'),
      member('gone', 'caregiver', { status: 'removed' }),
    );
    await setDoc(doc(db, 'babies/b1/insights/current'), {
      ruleVersion: 1,
      premium: true,
      items: [],
    });
    await setDoc(doc(db, 'insightQueue/b1'), { babyId: 'b1' });
  });
});

const as = (uid: string) => env.authenticatedContext(uid).firestore();

describe('insights', () => {
  it('parents and caregivers read', async () => {
    await assertSucceeds(getDoc(doc(as('mom'), 'babies/b1/insights/current')));
    await assertSucceeds(getDoc(doc(as('nanny'), 'babies/b1/insights/current')));
  });

  it('relatives, removed members and strangers do not', async () => {
    await assertFails(getDoc(doc(as('aunt'), 'babies/b1/insights/current')));
    await assertFails(getDoc(doc(as('gone'), 'babies/b1/insights/current')));
    await assertFails(getDoc(doc(as('stranger'), 'babies/b1/insights/current')));
    await assertFails(
      getDoc(doc(env.unauthenticatedContext().firestore(), 'babies/b1/insights/current')),
    );
  });

  it('nobody writes from the app', async () => {
    await assertFails(setDoc(doc(as('mom'), 'babies/b1/insights/current'), { premium: true }));
    await assertFails(deleteDoc(doc(as('mom'), 'babies/b1/insights/current')));
  });

  it('the queue is server-only', async () => {
    await assertFails(getDoc(doc(as('mom'), 'insightQueue/b1')));
    await assertFails(setDoc(doc(as('mom'), 'insightQueue/b1'), { dueAt: new Date() }));
  });
});

// D-151: "Có ích / Chưa có ích" and the hidden kinds belong to the person, per baby.
describe('insightPrefs', () => {
  const prefs = (extra: Record<string, unknown> = {}) => ({
    babyId: 'b1',
    muted: ['night_longest'],
    votes: { 'night_longest_2026-10-25': true },
    updatedAt: serverTimestamp(),
    ...extra,
  });

  it('a parent or caregiver writes and reads their own', async () => {
    await assertSucceeds(setDoc(doc(as('mom'), 'users/mom/insightPrefs/b1'), prefs()));
    await assertSucceeds(getDoc(doc(as('mom'), 'users/mom/insightPrefs/b1')));
    await assertSucceeds(setDoc(doc(as('nanny'), 'users/nanny/insightPrefs/b1'), prefs()));
  });

  it("never someone else's, never a relative, never for another baby", async () => {
    await assertFails(setDoc(doc(as('mom'), 'users/nanny/insightPrefs/b1'), prefs()));
    await assertFails(getDoc(doc(as('mom'), 'users/nanny/insightPrefs/b1')));
    await assertFails(setDoc(doc(as('aunt'), 'users/aunt/insightPrefs/b1'), prefs()));
    await assertFails(setDoc(doc(as('mom'), 'users/mom/insightPrefs/b2'), prefs({ babyId: 'b2' })));
  });

  it('only the known shape', async () => {
    await assertFails(
      setDoc(doc(as('mom'), 'users/mom/insightPrefs/b1'), prefs({ muted: ['anything'] })),
    );
    await assertFails(
      setDoc(doc(as('mom'), 'users/mom/insightPrefs/b1'), prefs({ babyId: 'other' })),
    );
    await assertFails(setDoc(doc(as('mom'), 'users/mom/insightPrefs/b1'), prefs({ extra: 1 })));
  });
});
