import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// Cùng Chăm Con (D-135): whoever reads care reads the plan; only the Functions write it.
const projectId = 'demo-child-life-care-plan';
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

const ITEM = `pi_${'a'.repeat(32)}`;
const paths = [
  'babies/b1/carePlanDays/2026-10-28',
  `babies/b1/carePlanDays/2026-10-28/items/${ITEM}`,
  `babies/b1/carePlanTemplate/pt_${'b'.repeat(32)}`,
  'babies/b1/carePlanHistory/h1',
];

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
      member('aunt', 'relative', { extraRights: { viewBabyInfo: true, viewDailyCare: false } }),
    );
    await setDoc(
      doc(db, 'babies/b1/members/uncle'),
      member('uncle', 'relative', { extraRights: { viewBabyInfo: true, viewDailyCare: true } }),
    );
    await setDoc(
      doc(db, 'babies/b1/members/gone'),
      member('gone', 'caregiver', { status: 'removed' }),
    );
    for (const p of paths) await setDoc(doc(db, p), { x: 1 });
  });
});

const as = (uid: string) => env.authenticatedContext(uid).firestore();

describe('Cùng Chăm Con plan', () => {
  it('parents, caregivers and relatives with daily care read it; others cannot', async () => {
    for (const uid of ['mom', 'nanny', 'uncle']) {
      for (const p of paths) await assertSucceeds(getDoc(doc(as(uid), p)));
      await assertSucceeds(getDocs(collection(as(uid), 'babies/b1/carePlanDays/2026-10-28/items')));
    }
    for (const uid of ['aunt', 'gone', 'stranger']) {
      for (const p of paths) await assertFails(getDoc(doc(as(uid), p)));
    }
  });

  it('nobody writes it from the app', async () => {
    for (const p of paths) {
      await assertFails(setDoc(doc(as('mom'), p), { x: 2 }));
      await assertFails(updateDoc(doc(as('mom'), p), { x: 2 }));
      await assertFails(deleteDoc(doc(as('mom'), p)));
    }
  });
});

describe('Cùng Chăm Con reminder settings (users/{uid}/settings/carePlan)', () => {
  const ref = (as_: string, uid = as_) => doc(as(as_), `users/${uid}/settings/carePlan`);
  it('its owner writes a lead of 0 / 5 / 10 / 15 and the quiet-hours switch', async () => {
    for (const leadMinutes of [0, 5, 10, 15]) {
      await assertSucceeds(
        setDoc(ref('mom'), { leadMinutes, quietHours: false, updatedAt: serverTimestamp() }),
      );
    }
    await assertSucceeds(getDoc(ref('mom')));
  });

  it('nothing else, and nobody else', async () => {
    await assertFails(setDoc(ref('mom'), { leadMinutes: 7, updatedAt: serverTimestamp() }));
    await assertFails(setDoc(ref('mom'), { quietHours: 'yes', updatedAt: serverTimestamp() }));
    await assertFails(
      setDoc(ref('mom'), { leadMinutes: 5, extra: 1, updatedAt: serverTimestamp() }),
    );
    await assertFails(setDoc(ref('mom'), { leadMinutes: 5 }));
    await assertFails(
      setDoc(ref('nanny', 'mom'), { leadMinutes: 5, updatedAt: serverTimestamp() }),
    );
    await assertFails(getDoc(ref('nanny', 'mom')));
  });
});
