import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, collection, getDocs } from 'firebase/firestore';
import { ref, uploadString, getBytes } from 'firebase/storage';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

const projectId = 'demo-child-life';
let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: { rules: readFileSync(resolve(import.meta.dirname, '../firestore.rules'), 'utf8') },
    storage: { rules: readFileSync(resolve(import.meta.dirname, '../storage.rules'), 'utf8') },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'publicConfig/flags'), { media_upload: { enabled: false } });
    await setDoc(doc(db, 'publicConfig/other'), { x: 1 });
    await setDoc(doc(db, 'config/flags'), { media_upload: { enabled: false } });
    await setDoc(doc(db, 'babies/b1'), { nickname: 'Teddy' });
  });
});

describe('Firestore baseline (deny by default)', () => {
  it('anyone can get the public flags and limits projections', async () => {
    const anon = env.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(anon, 'publicConfig/flags')));
    await assertSucceeds(getDoc(doc(anon, 'publicConfig/limits')));
  });

  it('nobody can list publicConfig or read other ids in it', async () => {
    const user = env.authenticatedContext('u1').firestore();
    await assertFails(getDocs(collection(user, 'publicConfig')));
    await assertFails(getDoc(doc(user, 'publicConfig/other')));
  });

  it('clients can never write config or public config', async () => {
    const user = env.authenticatedContext('u1').firestore();
    await assertFails(setDoc(doc(user, 'publicConfig/flags'), { media_upload: { enabled: true } }));
    await assertFails(setDoc(doc(user, 'config/flags'), { media_upload: { enabled: true } }));
  });

  it('server-side config and every other path are closed', async () => {
    const user = env.authenticatedContext('u1').firestore();
    await assertFails(getDoc(doc(user, 'config/flags')));
    await assertFails(getDoc(doc(user, 'babies/b1')));
    await assertFails(setDoc(doc(user, 'babies/b2'), { nickname: 'Na' }));
  });
});

describe('Storage baseline (deny all)', () => {
  it('denies reads and writes for signed-in and anonymous users', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await uploadString(ref(ctx.storage(), 'babies/b1/media/m1/thumb'), 'x');
    });
    const user = env.authenticatedContext('u1').storage();
    const anon = env.unauthenticatedContext().storage();
    await assertFails(getBytes(ref(user, 'babies/b1/media/m1/thumb')));
    await assertFails(getBytes(ref(anon, 'babies/b1/media/m1/thumb')));
    await assertFails(uploadString(ref(user, 'uploads/s1'), 'x'));
  });
});
