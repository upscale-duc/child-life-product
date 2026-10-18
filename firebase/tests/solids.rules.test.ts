import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// Ăn dặm (D-085, P-164 #3–#6, #13; plan §4, §10 #5): the published catalogue and recipes, the
// per-baby settings (Cùng nuôi write, care readers read), meals like care records (Cùng nuôi and
// Người chăm sóc log, caregivers edit only their own, soft delete only, the meal shape) and meal
// photos in Storage. Storage Rules read Firestore, so this suite uses the emulator's project.
const projectId = 'demo-child-life';
let env: RulesTestEnvironment;

const relations: Record<string, string> = {
  mom: 'mother',
  dad: 'father',
  nanny: 'nanny',
  grandma: 'grandmother',
  aunt: 'relative',
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
const author = (uid: string) => ({
  name: uid,
  relation: relations[uid] ?? 'other',
  relationCustom: null,
});

let seq = 0;
const newId = () => `m_${(++seq).toString(16).padStart(32, '0')}`;
const MEAL_MOM = `m_${'a'.repeat(32)}`;
const MEAL_NANNY = `m_${'b'.repeat(32)}`;

/** A valid new meal by [uid] (overrides merged last). */
function meal(uid: string, id: string, over: Record<string, unknown> = {}) {
  return {
    id,
    babyId: 'b1',
    occurredAt: Timestamp.fromDate(new Date(Date.now() - 30 * 60_000)),
    slot: 'noon',
    dish: 'Cháo bí đỏ',
    foodIds: ['fd_pumpkin', 'fd_rice'],
    freeFoods: [],
    amount: { preset: 'halfBowl' },
    reaction: 'liked',
    symptoms: [],
    note: '',
    recipeId: null,
    photoPath: null,
    createdBy: uid,
    author: author(uid),
    createdAt: serverTimestamp(),
    clientCreatedAt: Timestamp.now(),
    updatedAt: serverTimestamp(),
    updatedBy: uid,
    deleted: false,
    deletedAt: null,
    deletedBy: null,
    ...over,
  };
}
const stored = (uid: string, id: string) => ({
  ...meal(uid, id),
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now(),
});

const settings = (uid: string, over: Record<string, unknown> = {}) => ({
  enabled: true,
  startedOn: '2026-09-28',
  showOnToday: true,
  method: 'mixed',
  hidden: [],
  cleared: [],
  updatedAt: serverTimestamp(),
  updatedBy: uid,
  ...over,
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
    await setDoc(doc(db, 'babies/b1'), { nickname: 'Na', ownerUid: 'mom', familyId: 'f1' });
    await setDoc(doc(db, 'babies/b1/members/mom'), member('mom', 'coParent', { isOwner: true }));
    await setDoc(doc(db, 'babies/b1/members/dad'), member('dad', 'coParent'));
    await setDoc(doc(db, 'babies/b1/members/nanny'), member('nanny', 'caregiver'));
    await setDoc(doc(db, 'babies/b1/members/grandma'), member('grandma', 'relative'));
    await setDoc(
      doc(db, 'babies/b1/members/aunt'),
      member('aunt', 'relative', { extraRights: { viewBabyInfo: false, viewDailyCare: true } }),
    );
    await setDoc(
      doc(db, 'babies/b1/members/gone'),
      member('gone', 'caregiver', { status: 'removed' }),
    );
    await setDoc(
      doc(db, 'babies/b1/members/late'),
      member('late', 'coParent', { accessUntilAt: new Date('2020-01-01T00:00:00Z') }),
    );
    await setDoc(doc(db, `babies/b1/meals/${MEAL_MOM}`), stored('mom', MEAL_MOM));
    await setDoc(doc(db, `babies/b1/meals/${MEAL_NANNY}`), stored('nanny', MEAL_NANNY));
    await setDoc(doc(db, 'babies/b1/solids/settings'), {
      ...settings('mom'),
      updatedAt: Timestamp.now(),
    });
    for (const c of ['contentFoods', 'contentRecipes']) {
      await setDoc(doc(db, `${c}/live_one`), { status: 'published', revision: 1 });
      await setDoc(doc(db, `${c}/odd_one`), { status: 'draft', revision: 1 });
    }
    const storage = ctx.storage();
    await uploadBytes(ref(storage, 'babies/b1/meals/photo_mom1.jpg'), new Uint8Array([1, 2]), {
      contentType: 'image/jpeg',
    });
  });
});

const as = (uid: string) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();
const mealRef = (uid: string, id: string) => doc(as(uid), `babies/b1/meals/${id}`);
const SETTINGS = 'babies/b1/solids/settings';
const lockBaby = () =>
  env.withSecurityRulesDisabled(async (ctx) => {
    await updateDoc(doc(ctx.firestore(), 'babies/b1'), { state: 'deleting' });
  });

describe.each(['contentFoods', 'contentRecipes'])('%s (published catalogue)', (c) => {
  it('signed-in users read published documents and list them filtered', async () => {
    await assertSucceeds(getDoc(doc(as('mom'), `${c}/live_one`)));
    await assertSucceeds(
      getDocs(query(collection(as('nanny'), c), where('status', '==', 'published'))),
    );
  });

  it('nothing else: unfiltered lists, unpublished documents, signed-out reads, writes', async () => {
    await assertFails(getDocs(collection(as('mom'), c)));
    await assertFails(getDoc(doc(as('mom'), `${c}/odd_one`)));
    await assertFails(getDoc(doc(anon(), `${c}/live_one`)));
    await assertFails(setDoc(doc(as('mom'), `${c}/new_one`), { status: 'published' }));
    await assertFails(updateDoc(doc(as('mom'), `${c}/live_one`), { revision: 2 }));
    await assertFails(deleteDoc(doc(as('mom'), `${c}/live_one`)));
  });
});

describe('solids settings (5a, P-164 #3)', () => {
  it('members who read care read it; nobody else', async () => {
    for (const uid of ['mom', 'dad', 'nanny', 'aunt']) {
      await assertSucceeds(getDoc(doc(as(uid), SETTINGS)));
    }
    for (const uid of ['grandma', 'gone', 'late', 'stranger']) {
      await assertFails(getDoc(doc(as(uid), SETTINGS)));
    }
    await assertFails(getDoc(doc(anon(), SETTINGS)));
    await assertFails(getDocs(collection(as('mom'), 'babies/b1/solids')));
  });

  it('Cùng nuôi write it as themselves; caregivers and relatives never (§10 #5)', async () => {
    await assertSucceeds(setDoc(doc(as('dad'), SETTINGS), settings('dad', { method: 'blw' })));
    await assertSucceeds(
      updateDoc(doc(as('mom'), SETTINGS), {
        hidden: ['fd_egg'],
        cleared: ['fd_chicken'],
        updatedAt: serverTimestamp(),
        updatedBy: 'mom',
      }),
    );
    for (const uid of ['nanny', 'aunt', 'grandma', 'gone', 'late', 'stranger']) {
      await assertFails(setDoc(doc(as(uid), SETTINGS), settings(uid)));
    }
    // "Bác sĩ đã cho ăn lại" is the parents' call.
    await assertFails(
      updateDoc(doc(as('nanny'), SETTINGS), {
        cleared: ['fd_egg'],
        updatedAt: serverTimestamp(),
        updatedBy: 'nanny',
      }),
    );
    for (const uid of ['mom', 'nanny']) await assertFails(deleteDoc(doc(as(uid), SETTINGS)));
  });

  it('checks the shape: fields, method, date, list sizes, author, server time', async () => {
    const fifty = Array.from({ length: 50 }, (_, i) => `fd_food_${i}`);
    await assertSucceeds(
      setDoc(doc(as('mom'), SETTINGS), settings('mom', { hidden: fifty, startedOn: null })),
    );
    const bad: Record<string, unknown>[] = [
      { method: 'puree' },
      { enabled: 'yes' },
      { showOnToday: null },
      { startedOn: '2026-13-01' },
      { startedOn: '28/09/2026' },
      { hidden: [...fifty, 'fd_one_more'] },
      { cleared: 'fd_egg' },
      { updatedBy: 'dad' },
      { updatedAt: new Date() },
      { note: 'x' },
    ];
    for (const over of bad) {
      await assertFails(setDoc(doc(as('mom'), SETTINGS), settings('mom', over)));
    }
    const missing: Record<string, unknown> = settings('mom');
    delete missing.method;
    await assertFails(setDoc(doc(as('mom'), SETTINGS), missing));
  });

  it('only the settings document; locked while the profile is deleted', async () => {
    await assertFails(setDoc(doc(as('mom'), 'babies/b1/solids/other'), settings('mom')));
    await lockBaby();
    await assertSucceeds(getDoc(doc(as('mom'), SETTINGS)));
    await assertFails(setDoc(doc(as('mom'), SETTINGS), settings('mom')));
  });
});

describe('meals: who logs and reads (P-164 #13)', () => {
  it('Cùng nuôi and Người chăm sóc log meals as themselves', async () => {
    for (const uid of ['mom', 'dad', 'nanny']) {
      const id = newId();
      await assertSucceeds(setDoc(mealRef(uid, id), meal(uid, id)));
    }
  });

  it('relatives (even with daily care), former, expired members and strangers never log', async () => {
    for (const uid of ['aunt', 'grandma', 'gone', 'late', 'stranger']) {
      const id = newId();
      await assertFails(setDoc(mealRef(uid, id), meal(uid, id)));
    }
  });

  it('care readers read and list meals; others do not', async () => {
    for (const uid of ['mom', 'dad', 'nanny', 'aunt']) {
      await assertSucceeds(getDoc(mealRef(uid, MEAL_MOM)));
      await assertSucceeds(getDocs(collection(as(uid), 'babies/b1/meals')));
    }
    for (const uid of ['grandma', 'gone', 'late', 'stranger']) {
      await assertFails(getDoc(mealRef(uid, MEAL_MOM)));
    }
    await assertFails(getDocs(collection(as('grandma'), 'babies/b1/meals')));
  });

  it('attribution, ids and server times belong to the writer', async () => {
    const id = newId();
    const wrong: Record<string, unknown>[] = [
      { createdBy: 'mom' },
      { updatedBy: 'mom' },
      { author: author('mom') },
      { author: { ...author('nanny'), name: 'Bà Lan' } },
      { createdAt: Timestamp.now() },
      { updatedAt: Timestamp.now() },
      { clientCreatedAt: '2026-10-19' },
      { id: newId() },
      { babyId: 'b2' },
      { deleted: true },
      { deletedAt: Timestamp.now() },
    ];
    for (const over of wrong)
      await assertFails(setDoc(mealRef('nanny', id), meal('nanny', id, over)));
    const bad = 'm_XYZ';
    await assertFails(setDoc(mealRef('nanny', bad), meal('nanny', bad)));
    await assertSucceeds(setDoc(mealRef('nanny', id), meal('nanny', id)));
  });
});

describe('meals: the shape (mealSchema, 5c)', () => {
  const tryMeal = (over: Record<string, unknown>) => {
    const id = newId();
    return setDoc(mealRef('mom', id), meal('mom', id, over));
  };
  const ids = (n: number) => Array.from({ length: n }, (_, i) => `fd_food_${i}`);

  it('accepts the 5c variants', async () => {
    const ok: Record<string, unknown>[] = [
      { dish: '', foodIds: ['fd_pumpkin'] },
      { dish: '', foodIds: [], freeFoods: ['rau ngót'] },
      { dish: 'Súp', foodIds: [] },
      { foodIds: ids(12) },
      { freeFoods: ['a', 'b', 'c'] },
      { amount: null, reaction: null },
      { amount: { value: 2.5, unit: 'spoon' } },
      { amount: { value: 120, unit: 'ml' } },
      { symptoms: ['rash', 'breathing', 'swelling'], reaction: 'notYet' },
      { note: 'x'.repeat(300) },
      { recipeId: 'rcp_chao_bi_do' },
      { photoPath: 'babies/b1/meals/photo_mom1.jpg' },
      { slot: 'snack' },
      // Five minutes of clock skew.
      { occurredAt: Timestamp.fromDate(new Date(Date.now() + 2 * 60_000)) },
    ];
    for (const over of ok) await assertSucceeds(tryMeal(over));
  });

  it('refuses what the contract refuses', async () => {
    const bad: Record<string, unknown>[] = [
      { occurredAt: Timestamp.fromDate(new Date(Date.now() + 10 * 60_000)) },
      { occurredAt: '2026-10-19T10:00:00Z' },
      { dish: '', foodIds: [], freeFoods: [] },
      { dish: '   ', foodIds: [], freeFoods: [] },
      { dish: 'x'.repeat(61) },
      { foodIds: ids(13) },
      { foodIds: [...ids(11), 'pumpkin'] },
      { foodIds: ['fd_pumpkin', 7] },
      { foodIds: 'fd_pumpkin' },
      { freeFoods: ['a', 'b', 'c', 'd'] },
      { freeFoods: ['  '] },
      { freeFoods: ['x'.repeat(41)] },
      { amount: { preset: 'plate' } },
      { amount: { value: 0, unit: 'g' } },
      { amount: { value: 1001, unit: 'g' } },
      { amount: { value: 2, unit: 'cup' } },
      { amount: { preset: 'halfBowl', unit: 'g' } },
      { amount: 'halfBowl' },
      { reaction: 'loved' },
      { symptoms: ['hives'] },
      { symptoms: 'rash' },
      { note: 'x'.repeat(301) },
      { note: null },
      { recipeId: 'rcp-chao' },
      { photoPath: 'babies/b2/meals/photo_mom1.jpg' },
      { photoPath: 'babies/b1/vaccines/photo_mom1.jpg' },
      { photoPath: 'babies/b1/meals/x.jpg' },
      { slot: 'brunch' },
      { extra: true },
    ];
    for (const over of bad) await assertFails(tryMeal(over));
    const id = newId();
    const missing: Record<string, unknown> = meal('mom', id);
    delete missing.note;
    await assertFails(setDoc(mealRef('mom', id), missing));
  });
});

describe('meals: edit and delete (D-022, soft delete only)', () => {
  const edit = (uid: string, id: string, over: Record<string, unknown> = {}) =>
    updateDoc(mealRef(uid, id), {
      dish: 'Cháo cà rốt',
      reaction: 'neutral',
      updatedAt: serverTimestamp(),
      updatedBy: uid,
      ...over,
    });
  const remove = (uid: string, id: string) =>
    updateDoc(mealRef(uid, id), {
      deleted: true,
      deletedAt: serverTimestamp(),
      deletedBy: uid,
      updatedAt: serverTimestamp(),
      updatedBy: uid,
    });
  const restore = (uid: string, id: string) =>
    updateDoc(mealRef(uid, id), {
      deleted: false,
      deletedAt: null,
      deletedBy: null,
      updatedAt: serverTimestamp(),
      updatedBy: uid,
    });

  it('a caregiver edits only their own meals; Cùng nuôi edit any (§10 #5)', async () => {
    await assertSucceeds(edit('nanny', MEAL_NANNY));
    await assertFails(edit('nanny', MEAL_MOM));
    await assertSucceeds(edit('mom', MEAL_NANNY));
    await assertSucceeds(edit('dad', MEAL_MOM));
    for (const uid of ['aunt', 'grandma', 'gone', 'late', 'stranger']) {
      await assertFails(edit(uid, MEAL_MOM));
    }
  });

  it('details change; who, which baby and when it was made never do', async () => {
    await assertSucceeds(
      edit('mom', MEAL_MOM, {
        foodIds: ['fd_egg'],
        freeFoods: ['rau ngót'],
        symptoms: ['rash'],
        amount: { value: 3, unit: 'spoon' },
        photoPath: 'babies/b1/meals/photo_mom1.jpg',
        recipeId: 'rcp_trung',
        slot: 'morning',
        note: 'Bé ăn hết',
        occurredAt: Timestamp.fromDate(new Date(Date.now() - 3 * 3_600_000)),
      }),
    );
    const fixed: Record<string, unknown>[] = [
      { createdBy: 'dad' },
      { author: author('dad') },
      { babyId: 'b2' },
      { id: newId() },
      { createdAt: serverTimestamp() },
      { clientCreatedAt: Timestamp.now() },
      { updatedBy: 'dad' },
      { updatedAt: Timestamp.now() },
      { symptoms: ['hives'] },
      { dish: '', foodIds: [], freeFoods: [] },
      { occurredAt: Timestamp.fromDate(new Date(Date.now() + 3_600_000)) },
    ];
    for (const over of fixed) await assertFails(edit('mom', MEAL_MOM, over));
  });

  it('"Xoá" is a soft delete with undo; never a hard delete', async () => {
    await assertFails(remove('nanny', MEAL_MOM));
    await assertSucceeds(remove('nanny', MEAL_NANNY));
    // Deleted meals are not edited, only restored.
    await assertFails(edit('nanny', MEAL_NANNY, { deleted: true }));
    await assertSucceeds(restore('nanny', MEAL_NANNY));
    await assertSucceeds(remove('mom', MEAL_NANNY));
    await assertSucceeds(restore('dad', MEAL_NANNY));
    await assertFails(
      updateDoc(mealRef('mom', MEAL_MOM), {
        deleted: true,
        deletedAt: Timestamp.now(),
        deletedBy: 'mom',
        updatedAt: serverTimestamp(),
        updatedBy: 'mom',
      }),
    );
    await assertFails(
      updateDoc(mealRef('mom', MEAL_MOM), {
        deleted: true,
        deletedAt: serverTimestamp(),
        deletedBy: 'dad',
        updatedAt: serverTimestamp(),
        updatedBy: 'mom',
      }),
    );
    for (const uid of ['mom', 'nanny', 'stranger']) {
      await assertFails(deleteDoc(mealRef(uid, MEAL_NANNY)));
    }
  });

  it('a meal whose author deleted their account stays editable by Cùng nuôi', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), `babies/b1/meals/${MEAL_NANNY}`), {
        author: { name: '', relation: 'deleted', relationCustom: null },
        authorDeleted: true,
      });
    });
    await assertSucceeds(edit('mom', MEAL_NANNY));
    await assertSucceeds(remove('dad', MEAL_NANNY));
  });

  it('locked while the profile is deleted; still readable', async () => {
    await lockBaby();
    await assertSucceeds(getDoc(mealRef('mom', MEAL_MOM)));
    const id = newId();
    await assertFails(setDoc(mealRef('mom', id), meal('mom', id)));
    await assertFails(edit('mom', MEAL_MOM));
    await assertFails(remove('nanny', MEAL_NANNY));
  });
});

describe('meal photos in Storage (D-085 #2)', () => {
  const storage = (uid: string) => env.authenticatedContext(uid).storage();
  const bytes = (n: number) => new Uint8Array(n);
  const jpeg = { contentType: 'image/jpeg' };
  const put = (uid: string, file: string, n = 10, meta = jpeg) =>
    uploadBytes(ref(storage(uid), `babies/b1/meals/${file}`), bytes(n), meta);

  it('Cùng nuôi and Người chăm sóc add a JPEG up to 4 MB under a safe name', async () => {
    await assertSucceeds(put('mom', 'photo_mom2.jpg'));
    await assertSucceeds(put('nanny', 'nanny-photo_01.jpg', 4 * 1024 * 1024));
    await assertFails(put('nanny', 'too-big-photo.jpg', 4 * 1024 * 1024 + 1));
    await assertFails(put('mom', 'photo_mom3.png', 10, { contentType: 'image/png' }));
    await assertFails(put('mom', 'photo_mom3.jpg', 10, { contentType: 'image/png' }));
    await assertFails(put('mom', 'short.jpg'));
    await assertFails(put('mom', 'has.dots.jpg'));
    for (const uid of ['aunt', 'grandma', 'gone', 'late', 'stranger']) {
      await assertFails(put(uid, `photo_${uid}_1.jpg`));
    }
  });

  it('care readers see them; Cùng nuôi remove them', async () => {
    const path = 'babies/b1/meals/photo_mom1.jpg';
    for (const uid of ['mom', 'dad', 'nanny', 'aunt']) {
      await assertSucceeds(getBytes(ref(storage(uid), path)));
    }
    for (const uid of ['grandma', 'gone', 'stranger']) {
      await assertFails(getBytes(ref(storage(uid), path)));
    }
    await assertFails(deleteObject(ref(storage('nanny'), path)));
    await assertFails(deleteObject(ref(storage('aunt'), path)));
    await assertSucceeds(deleteObject(ref(storage('dad'), path)));
  });
});
