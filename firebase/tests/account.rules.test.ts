import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import { getBytes, ref, uploadBytes } from 'firebase/storage';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// S11: devices and remote sign-out (13n), notification settings (G-056), deletion and export
// jobs, writes locked while a profile is deleted (13l, Q-037) and export downloads that re-check
// the right at read time (R-187, P-123).
const projectId = 'demo-child-life';
let env: RulesTestEnvironment;

const DEVICE = `d_${'a'.repeat(32)}`;
const MED = `med_${'1'.repeat(32)}`;
const hour = 3_600_000;

const member = (
  uid: string,
  babyId: string,
  role: string,
  extra: Record<string, unknown> = {},
) => ({
  uid,
  babyId,
  role,
  status: 'active',
  relation: 'other',
  relationCustom: null,
  displayName: uid,
  ...extra,
});

const exportJob = (id: string, extra: Record<string, unknown>) => ({
  kind: 'export',
  exportKind: 'care',
  babyId: 'b1',
  uid: 'dad',
  state: 'ready',
  path: `exports/dad/${id}/child-life-care.zip`,
  expiresAt: Timestamp.fromMillis(Date.now() + 24 * hour),
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
    await setDoc(doc(db, 'babies/b1'), {
      nickname: 'Teddy',
      familyId: 'f1',
      ownerUid: 'mom',
      state: 'active',
    });
    await setDoc(doc(db, 'babies/b2'), {
      nickname: 'Na',
      familyId: 'f1',
      ownerUid: 'mom',
      state: 'deleting',
    });
    for (const b of ['b1', 'b2']) {
      await setDoc(
        doc(db, `babies/${b}/members/mom`),
        member('mom', b, 'coParent', { isOwner: true }),
      );
      await setDoc(doc(db, `babies/${b}/members/dad`), member('dad', b, 'coParent'));
      await setDoc(doc(db, `babies/${b}/members/grandma`), member('grandma', b, 'relative'));
      await setDoc(doc(db, `babies/${b}/media/${MED}`), {
        id: MED,
        babyId: b,
        status: 'ready',
        deleted: false,
        audience: 'family',
        effectiveAudience: 'family',
        createdBy: 'mom',
      });
    }
    await setDoc(doc(db, `users/mom/devices/${DEVICE}`), {
      token: 't',
      platform: 'ios',
      language: 'vi',
      name: 'iPhone của Mai',
      updatedAt: Timestamp.now(),
    });
    await setDoc(doc(db, 'deletionJobs/del_b2'), {
      kind: 'baby',
      babyId: 'b2',
      requestedBy: 'mom',
      state: 'running',
    });
    await setDoc(doc(db, 'dataJobs/ex_care'), exportJob('ex_care', {}));
    await setDoc(
      doc(db, 'dataJobs/ex_old'),
      exportJob('ex_old', { expiresAt: Timestamp.fromMillis(Date.now() - hour) }),
    );
    await setDoc(doc(db, 'dataJobs/ex_media'), exportJob('ex_media', { exportKind: 'media' }));
    await setDoc(
      doc(db, 'dataJobs/ex_mom'),
      exportJob('ex_mom', { exportKind: 'media', uid: 'mom' }),
    );
    const storage = ctx.storage();
    for (const [uid, id, kind] of [
      ['dad', 'ex_care', 'care'],
      ['dad', 'ex_old', 'care'],
      ['dad', 'ex_media', 'media'],
      ['mom', 'ex_mom', 'media'],
    ]) {
      await uploadBytes(
        ref(storage, `exports/${uid}/${id}/child-life-${kind}.zip`),
        new Uint8Array([80, 75]),
        {
          contentType: 'application/zip',
        },
      );
    }
  });
});

const db = (uid: string) => env.authenticatedContext(uid).firestore();
const storage = (uid: string) => env.authenticatedContext(uid).storage();

describe('devices (13n)', () => {
  const device = (extra: Record<string, unknown> = {}) => ({
    token: 'tok',
    platform: 'android',
    language: 'en',
    name: 'Pixel 9',
    appVersion: '1.0.0',
    updatedAt: serverTimestamp(),
    ...extra,
  });

  it('an install registers itself, with or without a push token', async () => {
    const other = `d_${'b'.repeat(32)}`;
    await assertSucceeds(setDoc(doc(db('mom'), `users/mom/devices/${other}`), device()));
    const { token: _token, ...noToken } = device();
    void _token;
    await assertSucceeds(setDoc(doc(db('dad'), `users/dad/devices/${other}`), noToken));
    await assertFails(setDoc(doc(db('dad'), `users/mom/devices/${other}`), device()));
    await assertFails(
      setDoc(doc(db('mom'), `users/mom/devices/${other}`), device({ city: 'HCM' })),
    );
  });

  it('only the server signs a device out', async () => {
    await assertFails(
      setDoc(
        doc(db('mom'), `users/mom/devices/d_${'c'.repeat(32)}`),
        device({ signedOutAt: serverTimestamp() }),
      ),
    );
    await assertFails(
      updateDoc(doc(db('mom'), `users/mom/devices/${DEVICE}`), { signedOutAt: serverTimestamp() }),
    );
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), `users/mom/devices/${DEVICE}`), {
        signedOutAt: Timestamp.now(),
      });
    });
    // The signed-out install may still refresh its own fields but never clear the flag.
    await assertSucceeds(
      updateDoc(doc(db('mom'), `users/mom/devices/${DEVICE}`), {
        language: 'en',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(db('mom'), `users/mom/devices/${DEVICE}`), {
        signedOutAt: null,
        updatedAt: serverTimestamp(),
      }),
    );
  });
});

describe('notification settings (G-056)', () => {
  const prefs = (extra: Record<string, unknown> = {}) => ({
    memories: true,
    messages: false,
    reminders: true,
    storage: true,
    updatedAt: serverTimestamp(),
    ...extra,
  });

  it('are the account’s own and well formed', async () => {
    await assertSucceeds(setDoc(doc(db('mom'), 'users/mom/settings/notifications'), prefs()));
    await assertSucceeds(getDoc(doc(db('mom'), 'users/mom/settings/notifications')));
    await assertFails(getDoc(doc(db('dad'), 'users/mom/settings/notifications')));
    await assertFails(setDoc(doc(db('dad'), 'users/mom/settings/notifications'), prefs()));
    await assertFails(
      setDoc(doc(db('mom'), 'users/mom/settings/notifications'), prefs({ loves: true })),
    );
    await assertFails(
      setDoc(doc(db('mom'), 'users/mom/settings/notifications'), prefs({ memories: 'yes' })),
    );
    await assertFails(setDoc(doc(db('mom'), 'users/mom/settings/other'), prefs()));
  });
});

describe('jobs', () => {
  it('the requester follows a deletion job; nobody writes it', async () => {
    await assertSucceeds(getDoc(doc(db('mom'), 'deletionJobs/del_b2')));
    await assertFails(getDoc(doc(db('dad'), 'deletionJobs/del_b2')));
    await assertFails(
      setDoc(doc(db('mom'), 'deletionJobs/del_b1'), { kind: 'baby', requestedBy: 'mom' }),
    );
  });

  it('exports are listed for their requester only', async () => {
    await assertSucceeds(
      getDocs(query(collection(db('dad'), 'dataJobs'), where('uid', '==', 'dad'))),
    );
    await assertFails(getDocs(collection(db('dad'), 'dataJobs')));
    await assertFails(getDoc(doc(db('mom'), 'dataJobs/ex_care')));
    await assertFails(setDoc(doc(db('dad'), 'dataJobs/ex_new'), { uid: 'dad', state: 'ready' }));
  });
});

describe('writes lock while a profile is deleted (13l)', () => {
  const fav = (uid: string) => ({ uid, mediaId: MED, createdAt: serverTimestamp() });

  it('reads stay, writes stop', async () => {
    await assertSucceeds(setDoc(doc(db('dad'), `babies/b1/favorites/dad__${MED}`), fav('dad')));
    await assertFails(setDoc(doc(db('dad'), `babies/b2/favorites/dad__${MED}`), fav('dad')));
    await assertSucceeds(getDoc(doc(db('dad'), `babies/b2/media/${MED}`)));
  });
});

describe('export downloads (R-187)', () => {
  const file = (uid: string, id: string, kind: string) =>
    ref(storage(uid), `exports/${uid}/${id}/child-life-${kind}.zip`);

  it('the requester downloads until the link expires', async () => {
    await assertSucceeds(getBytes(file('dad', 'ex_care', 'care')));
    await assertFails(getBytes(file('dad', 'ex_old', 'care')));
    await assertFails(getBytes(ref(storage('mom'), 'exports/dad/ex_care/child-life-care.zip')));
  });

  it('media archives re-check ownership at download', async () => {
    await assertFails(getBytes(file('dad', 'ex_media', 'media')));
    await assertSucceeds(getBytes(file('mom', 'ex_mom', 'media')));
  });

  it('access is re-checked: a removed Cùng nuôi cannot download', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), 'babies/b1/members/dad'), { status: 'removed' });
    });
    await assertFails(getBytes(file('dad', 'ex_care', 'care')));
  });

  it('nobody writes exports', async () => {
    await assertFails(
      uploadBytes(ref(storage('dad'), 'exports/dad/ex_care/x.zip'), new Uint8Array([1]), {
        contentType: 'application/zip',
      }),
    );
  });
});
