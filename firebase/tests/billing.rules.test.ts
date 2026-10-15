import {
  assertFails,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// Premium billing (plan §5.2, §6.1): purchase intents, store bindings and the notification ledger
// are Functions-only; the owner who bought cannot read or forge them. Synthetic `test_` ids.
const projectId = 'demo-child-life-billing-rules';
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
    await setDoc(doc(db, 'purchaseIntents/i1'), { familyId: 'test_f1', uid: 'test_mom' });
    await setDoc(doc(db, 'billingAccounts/apple_x'), { familyId: 'test_f1' });
    await setDoc(doc(db, 'billingEvents/apple_e'), { provider: 'apple' });
  });
});

describe('billing documents are closed to clients', () => {
  it('the buyer can neither read nor write intents, bindings or events', async () => {
    const mom = env.authenticatedContext('test_mom').firestore();
    for (const path of ['purchaseIntents/i1', 'billingAccounts/apple_x', 'billingEvents/apple_e']) {
      await assertFails(getDoc(doc(mom, path)));
      await assertFails(setDoc(doc(mom, path), { familyId: 'test_f2' }));
    }
    await assertFails(setDoc(doc(mom, 'purchaseIntents/new'), { familyId: 'test_f1' }));
    await assertFails(setDoc(doc(mom, 'billingAccounts/google_y'), { familyId: 'test_f1' }));
  });
});
