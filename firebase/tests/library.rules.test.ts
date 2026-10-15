import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  collection,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// Thư viện chăm bé "Đã lưu" (4e / 4f, D-076 #7): `users/{uid}/savedArticles/{articleId}` holds
// only when the person saved an article and the revision they last read. Per person: nobody else
// reads or writes it.
const projectId = 'demo-child-life-library';
let env: RulesTestEnvironment;

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
});

const db = (uid: string) => env.authenticatedContext(uid).firestore();
const saved = (uid: string, id = 'art_newborn_sleep', as = uid) =>
  doc(db(as), `users/${uid}/savedArticles/${id}`);

async function seed(uid: string, id: string, revision: number) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `users/${uid}/savedArticles/${id}`), {
      savedAt: Timestamp.fromDate(new Date('2026-10-02T03:00:00Z')),
      revision,
    });
  });
}

describe('users/{uid}/savedArticles', () => {
  it('the person saves an article: server time and the revision read', async () => {
    await assertSucceeds(setDoc(saved('mom'), { savedAt: serverTimestamp(), revision: 1 }));
    await assertSucceeds(getDoc(saved('mom')));
    await assertSucceeds(getDocs(collection(db('mom'), 'users/mom/savedArticles')));
    // Saving again replaces the time.
    await assertSucceeds(setDoc(saved('mom'), { savedAt: serverTimestamp(), revision: 2 }));
  });

  it('opening a newer revision updates only the revision', async () => {
    await seed('mom', 'art_newborn_sleep', 1);
    await assertSucceeds(updateDoc(saved('mom'), { revision: 3 }));
    // The saved time is not rewritten by hand.
    await assertFails(
      updateDoc(saved('mom'), { savedAt: Timestamp.fromDate(new Date('2020-01-01')) }),
    );
  });

  it('unsaving deletes it', async () => {
    await seed('mom', 'art_newborn_sleep', 1);
    await assertSucceeds(deleteDoc(saved('mom')));
  });

  it('nobody else reads, lists, writes or deletes it', async () => {
    await seed('mom', 'art_newborn_sleep', 1);
    await assertFails(getDoc(saved('mom', 'art_newborn_sleep', 'dad')));
    await assertFails(getDocs(collection(db('dad'), 'users/mom/savedArticles')));
    await assertFails(
      setDoc(saved('mom', 'art_bath', 'dad'), { savedAt: serverTimestamp(), revision: 1 }),
    );
    await assertFails(deleteDoc(saved('mom', 'art_newborn_sleep', 'dad')));
    const anon = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(anon, 'users/mom/savedArticles/art_newborn_sleep')));
    await assertFails(
      setDoc(doc(anon, 'users/mom/savedArticles/art_x1'), {
        savedAt: serverTimestamp(),
        revision: 1,
      }),
    );
  });

  it('refuses other ids, other fields and made-up times or revisions', async () => {
    const ok = { savedAt: serverTimestamp(), revision: 1 };
    // Only article ids (`art_…`, contracts `articleIdSchema`).
    await assertFails(setDoc(saved('mom', 'stg_w3'), ok));
    await assertFails(setDoc(saved('mom', 'Art_Upper'), ok));
    // Nothing else is stored (no title, note or baby).
    await assertFails(setDoc(saved('mom'), { ...ok, title: 'Giấc ngủ của bé sơ sinh' }));
    await assertFails(setDoc(saved('mom'), { ...ok, babyId: 'b1' }));
    await assertFails(setDoc(saved('mom'), { savedAt: serverTimestamp() }));
    await assertFails(
      setDoc(saved('mom'), {
        savedAt: Timestamp.fromDate(new Date('2026-10-01')),
        revision: 1,
      }),
    );
    await assertFails(setDoc(saved('mom'), { savedAt: serverTimestamp(), revision: 0 }));
    await assertFails(setDoc(saved('mom'), { savedAt: serverTimestamp(), revision: '2' }));
    await assertFails(setDoc(saved('mom'), { savedAt: serverTimestamp(), revision: 1.5 }));
  });
});
