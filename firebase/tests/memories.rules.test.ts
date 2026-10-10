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

// S9 memories: who reads memories and media (Cùng nuôi all; relatives only published Gia đình
// items; caregivers never — 12a, 10o, R-119), the upload slot in Storage (P-031) and family
// milestones (R-105). Storage Rules read Firestore, so this suite uses the emulator's project.
const projectId = 'demo-child-life';
let env: RulesTestEnvironment;

const relations: Record<string, string> = {
  mom: 'mother',
  dad: 'father',
  nanny: 'nanny',
  grandma: 'grandmother',
};
const member = (uid: string, role: string, extra: Record<string, unknown> = {}) => ({
  uid,
  babyId: 'b1',
  role,
  status: 'active',
  relation: relations[uid] ?? 'other',
  relationCustom: null,
  displayName: uid,
  ...extra,
});

const MEM_FAMILY = `mem_${'a'.repeat(32)}`;
const MEM_PARENTS = `mem_${'b'.repeat(32)}`;
const MEM_UPLOADING = `mem_${'c'.repeat(32)}`;
const MED_FAMILY = `med_${'1'.repeat(32)}`;
const MED_PRIVATE = `med_${'2'.repeat(32)}`;
const MED_UPLOADING = `med_${'3'.repeat(32)}`;
const MED_VIDEO = `med_${'4'.repeat(32)}`;
const MED_DELETED = `med_${'5'.repeat(32)}`;

function memoryDoc(id: string, audience: string, state = 'published') {
  return {
    id,
    babyId: 'b1',
    audience,
    state,
    deleted: false,
    caption: 'Ngủ trưa ngon lành sau giờ tắm.',
    occurredAt: Timestamp.now(),
    createdBy: 'mom',
  };
}

function mediaDoc(id: string, overrides: Record<string, unknown> = {}) {
  return {
    id,
    babyId: 'b1',
    memoryId: MEM_FAMILY,
    type: 'photo',
    contentType: 'image/jpeg',
    sizeBytes: 1000,
    hasPoster: false,
    audience: 'family',
    effectiveAudience: 'family',
    status: 'ready',
    clientState: null,
    createdBy: 'mom',
    captureAt: Timestamp.now(),
    deleted: false,
    ...overrides,
  };
}

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
    await setDoc(doc(db, 'babies/b1'), { nickname: 'Teddy', familyId: 'f1' });
    await setDoc(doc(db, 'babies/b1/members/mom'), member('mom', 'coParent'));
    await setDoc(doc(db, 'babies/b1/members/dad'), member('dad', 'coParent'));
    await setDoc(doc(db, 'babies/b1/members/nanny'), member('nanny', 'caregiver'));
    await setDoc(doc(db, 'babies/b1/members/grandma'), member('grandma', 'relative'));
    await setDoc(
      doc(db, 'babies/b1/members/gone'),
      member('gone', 'relative', { status: 'removed' }),
    );
    await setDoc(doc(db, `babies/b1/memories/${MEM_FAMILY}`), memoryDoc(MEM_FAMILY, 'family'));
    await setDoc(doc(db, `babies/b1/memories/${MEM_PARENTS}`), memoryDoc(MEM_PARENTS, 'parents'));
    await setDoc(
      doc(db, `babies/b1/memories/${MEM_UPLOADING}`),
      memoryDoc(MEM_UPLOADING, 'family', 'uploading'),
    );
    await setDoc(doc(db, `babies/b1/media/${MED_FAMILY}`), mediaDoc(MED_FAMILY));
    await setDoc(
      doc(db, `babies/b1/media/${MED_PRIVATE}`),
      mediaDoc(MED_PRIVATE, { audience: 'parents', effectiveAudience: 'parents' }),
    );
    await setDoc(
      doc(db, `babies/b1/media/${MED_UPLOADING}`),
      mediaDoc(MED_UPLOADING, { status: 'uploading', sizeBytes: 2048 }),
    );
    await setDoc(
      doc(db, `babies/b1/media/${MED_VIDEO}`),
      mediaDoc(MED_VIDEO, {
        status: 'uploading',
        type: 'video',
        contentType: 'video/quicktime',
        sizeBytes: 4096,
        hasPoster: true,
      }),
    );
    await setDoc(
      doc(db, `babies/b1/media/${MED_DELETED}`),
      mediaDoc(MED_DELETED, { deleted: true }),
    );
    const storage = ctx.storage();
    for (const id of [MED_FAMILY, MED_PRIVATE, MED_DELETED]) {
      await uploadBytes(ref(storage, `babies/b1/media/${id}/thumb.jpg`), new Uint8Array([1, 2]), {
        contentType: 'image/jpeg',
      });
    }
  });
});

const db = (uid: string) => env.authenticatedContext(uid).firestore();
const storage = (uid: string) => env.authenticatedContext(uid).storage();

describe('memories and media in Firestore', () => {
  it('Cùng nuôi read every memory and item, uploads and the bin included', async () => {
    for (const id of [MEM_FAMILY, MEM_PARENTS, MEM_UPLOADING]) {
      await assertSucceeds(getDoc(doc(db('dad'), `babies/b1/memories/${id}`)));
    }
    for (const id of [MED_FAMILY, MED_PRIVATE, MED_UPLOADING, MED_DELETED]) {
      await assertSucceeds(getDoc(doc(db('dad'), `babies/b1/media/${id}`)));
    }
  });

  it('relatives read only published Gia đình memories and ready Gia đình items', async () => {
    const g = db('grandma');
    await assertSucceeds(getDoc(doc(g, `babies/b1/memories/${MEM_FAMILY}`)));
    await assertFails(getDoc(doc(g, `babies/b1/memories/${MEM_PARENTS}`)));
    await assertFails(getDoc(doc(g, `babies/b1/memories/${MEM_UPLOADING}`)));
    await assertSucceeds(getDoc(doc(g, `babies/b1/media/${MED_FAMILY}`)));
    for (const id of [MED_PRIVATE, MED_UPLOADING, MED_DELETED]) {
      await assertFails(getDoc(doc(g, `babies/b1/media/${id}`)));
    }
    await assertSucceeds(
      getDocs(
        query(
          collection(g, 'babies/b1/media'),
          where('effectiveAudience', '==', 'family'),
          where('status', '==', 'ready'),
          where('deleted', '==', false),
        ),
      ),
    );
    await assertFails(getDocs(collection(g, 'babies/b1/media')));
  });

  it('caregivers, removed members and strangers never see Kỷ niệm', async () => {
    for (const uid of ['nanny', 'gone', 'stranger']) {
      await assertFails(getDoc(doc(db(uid), `babies/b1/memories/${MEM_FAMILY}`)));
      await assertFails(getDoc(doc(db(uid), `babies/b1/media/${MED_FAMILY}`)));
    }
  });

  it('only Functions write memories and items; the uploader may flag Wi-Fi waits', async () => {
    await assertFails(
      setDoc(doc(db('mom'), `babies/b1/memories/mem_${'d'.repeat(32)}`), memoryDoc('x', 'family')),
    );
    await assertFails(
      updateDoc(doc(db('mom'), `babies/b1/media/${MED_FAMILY}`), { audience: 'parents' }),
    );
    await assertSucceeds(
      updateDoc(doc(db('mom'), `babies/b1/media/${MED_UPLOADING}`), {
        clientState: 'waitingWifi',
      }),
    );
    await assertFails(
      updateDoc(doc(db('dad'), `babies/b1/media/${MED_UPLOADING}`), {
        clientState: 'waitingWifi',
      }),
    );
    await assertFails(
      updateDoc(doc(db('mom'), `babies/b1/media/${MED_UPLOADING}`), { clientState: 'done' }),
    );
  });

  it('Cùng nuôi create family milestones as themselves (R-105)', async () => {
    const id = `ms_${'e'.repeat(32)}`;
    const milestone = (uid: string) => ({
      id,
      babyId: 'b1',
      name: 'Lần đầu lật người',
      date: '2026-10-08',
      createdBy: uid,
      author: { name: uid, relation: relations[uid] ?? 'other', relationCustom: null },
      createdAt: serverTimestamp(),
    });
    await assertFails(
      setDoc(doc(db('grandma'), `babies/b1/milestones/${id}`), milestone('grandma')),
    );
    await assertFails(setDoc(doc(db('nanny'), `babies/b1/milestones/${id}`), milestone('nanny')));
    await assertFails(
      setDoc(doc(db('dad'), `babies/b1/milestones/${id}`), { ...milestone('dad'), name: '' }),
    );
    await assertSucceeds(setDoc(doc(db('dad'), `babies/b1/milestones/${id}`), milestone('dad')));
    await assertFails(getDoc(doc(db('grandma'), `babies/b1/milestones/${id}`)));
  });
});

describe('media bytes in Storage', () => {
  const bytes = (n: number) => new Uint8Array(n);

  it('the uploader fills the reserved slot once, within size and type', async () => {
    const path = `babies/b1/uploads/${MED_UPLOADING}`;
    await assertFails(
      uploadBytes(ref(storage('dad'), path), bytes(10), { contentType: 'image/jpeg' }),
    );
    await assertFails(
      uploadBytes(ref(storage('mom'), path), bytes(4096), { contentType: 'image/jpeg' }),
    );
    await assertFails(
      uploadBytes(ref(storage('mom'), path), bytes(10), { contentType: 'text/html' }),
    );
    await assertSucceeds(
      uploadBytes(ref(storage('mom'), path), bytes(2048), { contentType: 'image/jpeg' }),
    );
    // Ready items take no more bytes.
    await assertFails(
      uploadBytes(ref(storage('mom'), `babies/b1/uploads/${MED_FAMILY}`), bytes(10), {
        contentType: 'image/jpeg',
      }),
    );
  });

  it('a video poster is a small JPEG next to its video', async () => {
    await assertSucceeds(
      uploadBytes(ref(storage('mom'), `babies/b1/uploads/${MED_VIDEO}.poster`), bytes(500), {
        contentType: 'image/jpeg',
      }),
    );
    await assertFails(
      uploadBytes(ref(storage('mom'), `babies/b1/uploads/${MED_UPLOADING}.poster`), bytes(500), {
        contentType: 'image/jpeg',
      }),
    );
    await assertSucceeds(
      uploadBytes(ref(storage('mom'), `babies/b1/uploads/${MED_VIDEO}`), bytes(4096), {
        contentType: 'video/quicktime',
      }),
    );
  });

  it('nobody writes renditions or reads raw uploads', async () => {
    await assertFails(
      uploadBytes(ref(storage('mom'), `babies/b1/media/${MED_FAMILY}/thumb.jpg`), bytes(2), {
        contentType: 'image/jpeg',
      }),
    );
    await assertFails(getBytes(ref(storage('mom'), `babies/b1/uploads/${MED_UPLOADING}`)));
  });

  it('reads follow the audience: parents all, relatives shared items, caregivers nothing', async () => {
    const thumb = (id: string) => `babies/b1/media/${id}/thumb.jpg`;
    for (const id of [MED_FAMILY, MED_PRIVATE, MED_DELETED]) {
      await assertSucceeds(getBytes(ref(storage('dad'), thumb(id))));
    }
    await assertSucceeds(getBytes(ref(storage('grandma'), thumb(MED_FAMILY))));
    await assertFails(getBytes(ref(storage('grandma'), thumb(MED_PRIVATE))));
    await assertFails(getBytes(ref(storage('grandma'), thumb(MED_DELETED))));
    for (const uid of ['nanny', 'gone', 'stranger']) {
      await assertFails(getBytes(ref(storage(uid), thumb(MED_FAMILY))));
    }
  });
});
