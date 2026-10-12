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
  it('anyone can get the approved reference tables (P-138), nobody can write them', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'publicConfig/reference_bottle'), { version: 'v2026.10' });
    });
    const anon = env.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(anon, 'publicConfig/reference_bottle')));
    await assertSucceeds(getDoc(doc(anon, 'publicConfig/reference_growth_length')));
    await assertFails(getDoc(doc(anon, 'publicConfig/reference_secret')));
    const user = env.authenticatedContext('u1', { staff: true, roles: ['owner'] }).firestore();
    await assertFails(setDoc(doc(user, 'publicConfig/reference_bottle'), { version: 'x' }));
    await assertFails(getDoc(doc(user, 'referenceData/bottle.quickPicks')));
    await assertFails(getDoc(doc(user, 'familyDirectory/f1')));
    await assertFails(getDoc(doc(user, 'staffMembers/u1')));
    await assertFails(getDoc(doc(user, 'statsDaily/2026-10-10')));
  });

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

  it('the QA handbook is reached only through the staff callables (P-132), even by staff', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'qaRuns/r_0123456789abcdef0123'), { name: '1.0.3' });
    });
    const staff = env
      .authenticatedContext('s1', { staff: true, roles: ['qa', 'lead'] })
      .firestore();
    await assertFails(getDoc(doc(staff, 'qaRuns/r_0123456789abcdef0123')));
    await assertFails(getDocs(collection(staff, 'qaRuns')));
    await assertFails(setDoc(doc(staff, 'qaCases/CARE-Q01'), { builtin: false }));
    await assertFails(
      setDoc(doc(staff, 'qaRuns/r_0123456789abcdef0123/results/CARE-001'), { status: 'passed' }),
    );
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
