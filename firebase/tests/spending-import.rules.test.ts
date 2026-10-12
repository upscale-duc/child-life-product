import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, setDoc, updateDoc } from 'firebase/firestore';
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// Nhập chi tiêu (D-060, P-144): the import documents are Functions-written and read by Cùng nuôi
// only; the uploader writes their grid / photos under their own uid, nobody reads them back.
const projectId = 'demo-child-life-spending-import';
let env: RulesTestEnvironment;

const importId = `im_${'0'.repeat(31)}1`;
const member = (uid: string, role: string, extra: Record<string, unknown> = {}) => ({
  uid,
  babyId: 'b1',
  role,
  status: 'active',
  relation: 'other',
  relationCustom: null,
  displayName: uid,
  extraRights: null,
  ...extra,
});

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
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'babies/b1'), { nickname: 'Teddy', ownerUid: 'mom', familyId: 'f1' });
    await setDoc(doc(db, 'babies/b1/members/mom'), member('mom', 'coParent'));
    await setDoc(doc(db, 'babies/b1/members/dad'), member('dad', 'coParent'));
    await setDoc(
      doc(db, 'babies/b1/members/aunt'),
      member('aunt', 'relative', {
        extraRights: {
          viewBabyInfo: true,
          viewDailyCare: true,
          recordSpending: true,
          viewSpending: true,
        },
      }),
    );
    await setDoc(doc(db, 'babies/b1/members/nanny'), member('nanny', 'caregiver'));
    await setDoc(
      doc(db, 'babies/b1/members/gone'),
      member('gone', 'coParent', { status: 'removed' }),
    );
    await setDoc(doc(db, `babies/b1/spendingImports/${importId}`), {
      kind: 'file',
      status: 'ready',
      createdBy: 'mom',
    });
    await uploadBytes(
      ref(ctx.storage(), `imports/mom/${importId}.json`),
      new Uint8Array([91, 93]),
      {
        contentType: 'application/json',
      },
    );
  });
});

const db = (uid: string) => env.authenticatedContext(uid).firestore();
const storage = (uid: string) => env.authenticatedContext(uid).storage();
const bytes = (n: number) => new Uint8Array(n);
const path = `babies/b1/spendingImports/${importId}`;

describe('spendingImports documents', () => {
  it('Cùng nuôi read them; nobody else, even with every spending right', async () => {
    await assertSucceeds(getDoc(doc(db('mom'), path)));
    await assertSucceeds(getDoc(doc(db('dad'), path)));
    await assertSucceeds(getDocs(collection(db('dad'), 'babies/b1/spendingImports')));
    for (const uid of ['aunt', 'nanny', 'gone', 'stranger']) {
      await assertFails(getDoc(doc(db(uid), path)));
    }
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), path)));
  });

  it('only Functions write them', async () => {
    await assertFails(
      setDoc(doc(db('mom'), `babies/b1/spendingImports/im_${'2'.repeat(32)}`), {
        kind: 'file',
        status: 'ready',
        createdBy: 'mom',
      }),
    );
    await assertFails(updateDoc(doc(db('mom'), path), { status: 'queued' }));
    await assertFails(deleteDoc(doc(db('mom'), path)));
  });
});

describe('imports/ in Storage', () => {
  const grid = (uid: string, id = importId) => `imports/${uid}/${id}.json`;
  const photo = (uid: string, n: number | string, id = importId) => `imports/${uid}/${id}/${n}.jpg`;

  it('the uploader adds a JSON grid (≤ 12 MB) and up to five JPEG photos (≤ 4 MB)', async () => {
    const id = `im_${'a'.repeat(32)}`;
    await assertSucceeds(
      uploadBytes(ref(storage('mom'), grid('mom', id)), bytes(10), {
        contentType: 'application/json',
      }),
    );
    await assertSucceeds(
      uploadBytes(ref(storage('mom'), grid('mom', `im_${'b'.repeat(32)}`)), bytes(10), {
        contentType: 'application/json; charset=utf-8',
      }),
    );
    for (const n of [0, 4]) {
      await assertSucceeds(
        uploadBytes(ref(storage('mom'), photo('mom', n, id)), bytes(10), {
          contentType: 'image/jpeg',
        }),
      );
    }
  });

  it('refuses other people, other names, types and sizes', async () => {
    const id = `im_${'c'.repeat(32)}`;
    const json = { contentType: 'application/json' };
    const jpeg = { contentType: 'image/jpeg' };
    await assertFails(uploadBytes(ref(storage('dad'), grid('mom', id)), bytes(10), json));
    await assertFails(
      uploadBytes(ref(env.unauthenticatedContext().storage(), grid('mom', id)), bytes(10), json),
    );
    await assertFails(uploadBytes(ref(storage('mom'), grid('mom', 'im_short')), bytes(10), json));
    await assertFails(uploadBytes(ref(storage('mom'), `imports/mom/${id}.csv`), bytes(10), json));
    await assertFails(
      uploadBytes(ref(storage('mom'), grid('mom', id)), bytes(10), { contentType: 'text/html' }),
    );
    await assertFails(
      uploadBytes(ref(storage('mom'), grid('mom', id)), bytes(12 * 1024 * 1024 + 1), json),
    );
    await assertFails(uploadBytes(ref(storage('mom'), photo('mom', 5, id)), bytes(10), jpeg));
    await assertFails(uploadBytes(ref(storage('mom'), photo('mom', 'x', id)), bytes(10), jpeg));
    await assertFails(
      uploadBytes(ref(storage('mom'), photo('mom', 0, id)), bytes(10), {
        contentType: 'image/png',
      }),
    );
    await assertFails(
      uploadBytes(ref(storage('mom'), photo('mom', 0, id)), bytes(4 * 1024 * 1024 + 1), jpeg),
    );
    await assertFails(
      uploadBytes(ref(storage('mom'), `imports/mom/${id}/sub/0.jpg`), bytes(10), jpeg),
    );
  });

  it('nobody reads or replaces a grid; the uploader may delete it', async () => {
    await assertFails(getBytes(ref(storage('mom'), grid('mom'))));
    await assertFails(getBytes(ref(storage('dad'), grid('mom'))));
    await assertFails(
      uploadBytes(ref(storage('mom'), grid('mom')), bytes(10), { contentType: 'application/json' }),
    );
    await assertFails(deleteObject(ref(storage('dad'), grid('mom'))));
    await assertSucceeds(deleteObject(ref(storage('mom'), grid('mom'))));
  });
});
