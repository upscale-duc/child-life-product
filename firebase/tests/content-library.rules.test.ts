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
  query,
  setDoc,
  where,
} from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// Editorial content (D-076 #5–#7, D-083): signed-in users read published articles, stage content,
// reference milestones and the nutrition stages, micronutrients and rules (lists must ask for
// status == 'published'); nobody writes them from a client; drafts (contentDrafts) are reached
// only through staff callables.
const projectId = 'demo-child-life-content-rules';
let env: RulesTestEnvironment;
const collections = [
  'contentArticles',
  'contentStages',
  'contentMilestones',
  // Dinh dưỡng theo giai đoạn (D-083).
  'contentNutritionStages',
  'contentNutrients',
  'contentNutritionRules',
];

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync(resolve(import.meta.dirname, '../firestore.rules'), 'utf8'),
    },
  });
});
afterAll(async () => {
  await env.cleanup();
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const c of collections) {
      await setDoc(doc(db, `${c}/live_one`), { status: 'published', revision: 1 });
      // Never written by the server, but the rules must not trust the collection alone.
      await setDoc(doc(db, `${c}/odd_one`), { status: 'draft', revision: 1 });
    }
    await setDoc(doc(db, 'contentDrafts/art_x'), { kind: 'article', status: 'draft' });
    await setDoc(doc(db, 'staffMembers/s1'), { status: 'active', roles: ['admin'] });
  });
});

const signedIn = () => env.authenticatedContext('mom').firestore();
const staffUser = () =>
  env.authenticatedContext('s1', { staff: true, roles: ['admin'] }).firestore();
const anon = () => env.unauthenticatedContext().firestore();

describe.each(collections)('%s', (c) => {
  it('signed-in users read published documents and list them filtered', async () => {
    await assertSucceeds(getDoc(doc(signedIn(), `${c}/live_one`)));
    await assertSucceeds(
      getDocs(query(collection(signedIn(), c), where('status', '==', 'published'))),
    );
  });

  it('nothing else: unfiltered lists, unpublished documents, signed-out reads', async () => {
    await assertFails(getDocs(collection(signedIn(), c)));
    await assertFails(getDoc(doc(signedIn(), `${c}/odd_one`)));
    await assertFails(getDoc(doc(anon(), `${c}/live_one`)));
  });

  it('no client writes, staff included', async () => {
    await assertFails(setDoc(doc(signedIn(), `${c}/new_one`), { status: 'published' }));
    await assertFails(setDoc(doc(staffUser(), `${c}/new_one`), { status: 'published' }));
    await assertFails(deleteDoc(doc(staffUser(), `${c}/live_one`)));
  });
});

describe('contentDrafts', () => {
  it('is closed to every client, staff included (callables only)', async () => {
    await assertFails(getDoc(doc(signedIn(), 'contentDrafts/art_x')));
    await assertFails(getDoc(doc(staffUser(), 'contentDrafts/art_x')));
    await assertFails(getDocs(collection(staffUser(), 'contentDrafts')));
    await assertFails(setDoc(doc(staffUser(), 'contentDrafts/art_y'), { status: 'draft' }));
  });
});
