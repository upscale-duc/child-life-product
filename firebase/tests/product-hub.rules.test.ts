import {
  assertFails,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, setDoc } from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// Sản phẩm · Product Hub (D-155): product knowledge is staff-only through callables. No client —
// a family member or a signed-in staff account — reads or writes it directly. Synthetic ids.
const projectId = 'demo-child-life';
let env: RulesTestEnvironment;
const collections = [
  'productFeatures',
  'productSources',
  'productChunks',
  'productDecisions',
  'productConflicts',
  'productChangeSets',
];

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
    for (const c of collections) await setDoc(doc(db, `${c}/test_1`), { id: 'test_1' });
    await setDoc(doc(db, 'productFeatures/test_1/productSections/rules'), { draft: null });
  });
});

describe('product knowledge rules', () => {
  it('denies reads and writes to family members and staff accounts alike', async () => {
    for (const ctx of [
      env.authenticatedContext('test_mom'),
      env.authenticatedContext('test_staff', { staff: true, roles: ['owner'] }),
      env.unauthenticatedContext(),
    ]) {
      const db = ctx.firestore();
      for (const c of collections) {
        await assertFails(getDoc(doc(db, `${c}/test_1`)));
        await assertFails(getDocs(collection(db, c)));
        await assertFails(setDoc(doc(db, `${c}/test_2`), { id: 'test_2' }));
      }
      await assertFails(getDoc(doc(db, 'productFeatures/test_1/productSections/rules')));
    }
  });
});
