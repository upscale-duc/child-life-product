import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// Premium & Cá nhân hoá (plan §6.1): integration matrix M03 (no cross-family reads) and M04
// (clients cannot write premium=true, grants or quota counters). Synthetic `test_` ids.
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
    await setDoc(doc(db, 'families/test_f2'), { ownerUid: 'test_other' });
    await setDoc(doc(db, 'families/test_f1/grants/paid_1'), { source: 'paid', status: 'active' });
    await setDoc(doc(db, 'families/test_f2/grants/paid_1'), { source: 'paid', status: 'active' });
    await setDoc(doc(db, 'families/test_f1/quota/video_2026-10'), {
      limit: 1,
      used: 0,
      reserved: 0,
    });
    await setDoc(doc(db, 'babies/test_b1/members/test_mom'), {
      uid: 'test_mom',
      babyId: 'test_b1',
      role: 'coParent',
      isOwner: true,
      status: 'active',
    });
  });
});

describe('M04 · clients never write entitlements or quota', () => {
  it('the owner cannot create, edit or read grants', async () => {
    const mom = env.authenticatedContext('test_mom').firestore();
    await assertFails(getDoc(doc(mom, 'families/test_f1/grants/paid_1')));
    await assertFails(
      setDoc(doc(mom, 'families/test_f1/grants/fake'), {
        source: 'paid',
        status: 'active',
        capabilities: ['templates.premium'],
      }),
    );
    await assertFails(updateDoc(doc(mom, 'families/test_f1/grants/paid_1'), { status: 'active' }));
  });

  it('the owner cannot touch quota counters or ledger operations', async () => {
    const mom = env.authenticatedContext('test_mom').firestore();
    await assertFails(getDoc(doc(mom, 'families/test_f1/quota/video_2026-10')));
    await assertFails(
      updateDoc(doc(mom, 'families/test_f1/quota/video_2026-10'), { used: 0, limit: 99 }),
    );
    await assertFails(setDoc(doc(mom, 'families/test_f1/quotaOps/reserve_x'), { op: 'release' }));
  });

  it('the family document is read-only: premium=true, country or entitlementVersion are refused', async () => {
    const mom = env.authenticatedContext('test_mom').firestore();
    await assertSucceeds(getDoc(doc(mom, 'families/test_f1')));
    await assertFails(updateDoc(doc(mom, 'families/test_f1'), { premium: true }));
    await assertFails(updateDoc(doc(mom, 'families/test_f1'), { country: 'US' }));
    await assertFails(updateDoc(doc(mom, 'families/test_f1'), { entitlementVersion: 99 }));
  });

  it('server config and its entitlements are closed to clients', async () => {
    const mom = env.authenticatedContext('test_mom').firestore();
    await assertFails(getDoc(doc(mom, 'config/entitlements')));
    await assertFails(setDoc(doc(mom, 'config/entitlements'), { regions: { advanced: ['VN'] } }));
  });
});

describe('M03 · no cross-family reads', () => {
  it('a member of family 1 cannot read family 2 or its grants', async () => {
    const mom = env.authenticatedContext('test_mom').firestore();
    await assertFails(getDoc(doc(mom, 'families/test_f2')));
    await assertFails(getDoc(doc(mom, 'families/test_f2/grants/paid_1')));
  });

  it('signed-out callers read nothing', async () => {
    const anon = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(anon, 'families/test_f1')));
    await assertFails(getDoc(doc(anon, 'families/test_f1/grants/paid_1')));
  });
});
