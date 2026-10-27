import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, query, setDoc, where } from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, it } from 'vitest';
let env: RulesTestEnvironment;
beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-child-life',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});
afterAll(async () => env.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (c) => {
    for (const [uid, role] of [
      ['mom', 'coParent'],
      ['dad', 'coParent'],
      ['grandma', 'relative'],
    ])
      await setDoc(doc(c.firestore(), `babies/b1/members/${uid}`), { uid, role, status: 'active' });
    await setDoc(doc(c.firestore(), 'babies/b1/printOrders/order1'), { uid: 'mom', total: 379000 });
    await setDoc(doc(c.firestore(), 'babies/b1/printExportJobs/px1'), {
      uid: 'mom',
      status: 'queued',
    });
    await setDoc(doc(c.firestore(), 'babies/b1/printDrafts/mom'), {
      design: { name: 'Private name' },
    });
    await setDoc(doc(c.firestore(), 'printOrderOps/order1'), {
      babyId: 'b1',
      internalNote: 'Private staff notes',
    });
    await setDoc(doc(c.firestore(), 'publicConfig/printStudio'), { physicalEnabled: false });
    await setDoc(doc(c.firestore(), 'printReviews/review1'), {
      uid: 'mom',
      message: 'Private pending review',
    });
    await setDoc(doc(c.firestore(), 'printReviewsPublic/review1'), {
      rating: 5,
      message: 'Published review',
    });
  });
});
it('only the ordering co-parent reads their order and draft; clients never write either', async () => {
  const mom = env.authenticatedContext('mom').firestore();
  await assertSucceeds(getDoc(doc(mom, 'babies/b1/printOrders/order1')));
  await assertSucceeds(
    getDocs(query(collection(mom, 'babies/b1/printOrders'), where('uid', '==', 'mom'))),
  );
  await assertFails(getDocs(collection(mom, 'babies/b1/printOrders')));
  await assertSucceeds(getDoc(doc(mom, 'babies/b1/printDrafts/mom')));
  await assertFails(getDoc(doc(mom, 'printOrderOps/order1')));
  await assertFails(setDoc(doc(mom, 'printOrderOps/order1'), { internalNote: 'edited' }));
  await assertFails(setDoc(doc(mom, 'babies/b1/printOrders/order2'), { uid: 'mom' }));
  await assertFails(setDoc(doc(mom, 'babies/b1/printDrafts/mom'), {}));
  for (const uid of ['dad', 'grandma', 'stranger']) {
    const db = env.authenticatedContext(uid).firestore();
    await assertFails(getDoc(doc(db, 'babies/b1/printOrders/order1')));
    await assertFails(getDoc(doc(db, 'babies/b1/printDrafts/mom')));
  }
});
it('only the co-parent who asked follows a print file job; clients never write it (PR-1)', async () => {
  const mom = env.authenticatedContext('mom').firestore();
  await assertSucceeds(getDoc(doc(mom, 'babies/b1/printExportJobs/px1')));
  await assertFails(setDoc(doc(mom, 'babies/b1/printExportJobs/px1'), { status: 'ready' }));
  for (const uid of ['dad', 'grandma', 'stranger']) {
    const db = env.authenticatedContext(uid).firestore();
    await assertFails(getDoc(doc(db, 'babies/b1/printExportJobs/px1')));
  }
});
it('only moderated public reviews can be read; catalog is read-only', async () => {
  const db = env.authenticatedContext('mom').firestore();
  await assertFails(getDoc(doc(db, 'printReviews/review1')));
  await assertSucceeds(getDoc(doc(db, 'printReviewsPublic/review1')));
  await assertFails(setDoc(doc(db, 'printReviewsPublic/review1'), { rating: 5 }));
  await assertSucceeds(getDoc(doc(db, 'publicConfig/printStudio')));
  await assertFails(setDoc(doc(db, 'publicConfig/printStudio'), { physicalEnabled: true }));
});
