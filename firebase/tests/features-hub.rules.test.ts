import {
  assertFails,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, getDocs, collection, setDoc, updateDoc } from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// "Tính năng & Premium" hub (D-089): admin overrides and `config/features` are server-written
// and server-read only. A client can never switch a feature on for its own family, or read
// another family's overrides. Synthetic `test_` ids.
const projectId = 'demo-child-life';
let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: { rules: readFileSync(resolve(import.meta.dirname, '../firestore.rules'), 'utf8') },
  });
});
afterAll(async () => env.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'families/test_f1'), { ownerUid: 'test_mom', country: 'VN' });
    await setDoc(doc(db, 'families/test_f1/featureOverrides/auto_save'), {
      feature: 'auto_save',
      state: 'off',
      until: null,
      byUid: 's_owner',
      byName: 'Owner',
      at: new Date('2026-10-21T00:00:00Z'),
    });
    await setDoc(doc(db, 'config/features'), { features: { auto_save: { tier: 'beta' } } });
    await setDoc(doc(db, 'babies/test_b1/members/test_mom'), {
      uid: 'test_mom',
      babyId: 'test_b1',
      role: 'coParent',
      isOwner: true,
      status: 'active',
    });
  });
});

describe('featureOverrides · clients denied', () => {
  it('the family owner cannot read, list, create, change or delete an override', async () => {
    const mom = env.authenticatedContext('test_mom').firestore();
    const ref = doc(mom, 'families/test_f1/featureOverrides/auto_save');
    await assertFails(getDoc(ref));
    await assertFails(getDocs(collection(mom, 'families/test_f1/featureOverrides')));
    await assertFails(updateDoc(ref, { state: 'on' }));
    await assertFails(deleteDoc(ref));
    await assertFails(
      setDoc(doc(mom, 'families/test_f1/featureOverrides/milestone_cards'), {
        feature: 'milestone_cards',
        state: 'on',
        until: null,
      }),
    );
  });

  it('strangers and signed-out callers are denied too', async () => {
    const other = env.authenticatedContext('test_other').firestore();
    const anon = env.unauthenticatedContext().firestore();
    for (const db of [other, anon]) {
      await assertFails(getDoc(doc(db, 'families/test_f1/featureOverrides/auto_save')));
      await assertFails(
        setDoc(doc(db, 'families/test_f1/featureOverrides/rhythm'), { state: 'on' }),
      );
    }
  });

  it('config/features (tiers, beta lists, grace) is closed to clients', async () => {
    const mom = env.authenticatedContext('test_mom').firestore();
    await assertFails(getDoc(doc(mom, 'config/features')));
    await assertFails(setDoc(doc(mom, 'config/features'), { features: {} }));
    await assertFails(getDoc(doc(mom, 'publicConfig/features')));
  });
});
