import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  where,
} from 'firebase/firestore';
import { getBytes, ref } from 'firebase/storage';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// Kỷ niệm 2.0 (D-068): the published catalog and template assets are readable (artwork, never
// child media); video jobs are read only by the Cùng nuôi who asked and written by the server.
const projectId = 'demo-child-life';
let env: RulesTestEnvironment;
const job = `ksj_${'a'.repeat(32)}`;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: { rules: readFileSync(resolve(import.meta.dirname, '../firestore.rules'), 'utf8') },
    storage: { rules: readFileSync(resolve(import.meta.dirname, '../storage.rules'), 'utf8') },
  });
});
afterAll(async () => env.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [uid, role] of [
      ['mom', 'coParent'],
      ['dad', 'coParent'],
      ['grandma', 'relative'],
    ]) {
      await setDoc(doc(db, `babies/b1/members/${uid}`), {
        uid,
        babyId: 'b1',
        role,
        status: 'active',
        relation: 'other',
        relationCustom: null,
        displayName: uid,
      });
    }
    await setDoc(doc(db, `babies/b1/keepsakeJobs/${job}`), { uid: 'mom', status: 'queued' });
    await setDoc(doc(db, 'publicConfig/keepsakes'), { templates: [] });
  });
});

describe('Kỷ niệm 2.0 rules', () => {
  it('saved Thiệp / Video templates: their owner only, a list of at most 100', async () => {
    const mom = env.authenticatedContext('mom').firestore();
    const dad = env.authenticatedContext('dad').firestore();
    const saved = (n: number) => Array.from({ length: n }, (_, i) => `t${i}`);
    await assertSucceeds(
      setDoc(doc(mom, 'users/mom/settings/keepsakes'), {
        saved: saved(100),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(getDoc(doc(mom, 'users/mom/settings/keepsakes')));
    await assertFails(getDoc(doc(dad, 'users/mom/settings/keepsakes')));
    await assertFails(
      setDoc(doc(dad, 'users/mom/settings/keepsakes'), { saved: [], updatedAt: serverTimestamp() }),
    );
    await assertFails(
      setDoc(doc(mom, 'users/mom/settings/keepsakes'), {
        saved: saved(101),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      setDoc(doc(mom, 'users/mom/settings/keepsakes'), {
        saved: [],
        babyId: 'b1',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('the catalog is readable, never writable from a client', async () => {
    const mom = env.authenticatedContext('mom').firestore();
    await assertSucceeds(getDoc(doc(mom, 'publicConfig/keepsakes')));
    await assertFails(setDoc(doc(mom, 'publicConfig/keepsakes'), { templates: [] }));
  });

  it('a job is read by the parent who asked only, and written by no client', async () => {
    const mom = env.authenticatedContext('mom').firestore();
    const dad = env.authenticatedContext('dad').firestore();
    const grandma = env.authenticatedContext('grandma').firestore();
    await assertSucceeds(getDoc(doc(mom, `babies/b1/keepsakeJobs/${job}`)));
    await assertSucceeds(
      getDocs(query(collection(mom, 'babies/b1/keepsakeJobs'), where('uid', '==', 'mom'))),
    );
    await assertFails(getDoc(doc(dad, `babies/b1/keepsakeJobs/${job}`)));
    await assertFails(getDoc(doc(grandma, `babies/b1/keepsakeJobs/${job}`)));
    await assertFails(setDoc(doc(mom, `babies/b1/keepsakeJobs/${job}`), { status: 'completed' }));
  });

  it('template assets are public; other content paths stay closed to writes', async () => {
    const anyone = env.unauthenticatedContext().storage();
    // Reading a missing public object is allowed by Rules (the emulator answers not-found).
    await getBytes(ref(anyone, 'content/keepsakes/frame_1a2b3c4d.webp')).catch(
      (e: { code?: string }) => {
        if (e.code === 'storage/unauthorized') throw e;
      },
    );
  });
});
