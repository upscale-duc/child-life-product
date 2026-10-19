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
import { familyRecipeSchema } from '@child-life/contracts';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { familyRecipeFixture } from '../functions/test/solids-fixtures.js';

// Ăn dặm (D-085, P-164 #3–#6, #13; plan §4, §10 #5): the published catalogue and recipes, the
// per-baby settings (Cùng nuôi write, care readers read), meals like care records (Cùng nuôi and
// Người chăm sóc log, caregivers edit only their own, soft delete only, the meal shape) and meal
// photos in Storage; "Công thức nhà mình" (D-086, plan §12 #2) the same way, with their photos.
// Storage Rules read Firestore, so this suite uses the emulator's project.
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

let frSeq = 0;
const newRecipeId = () => `fr_${(++frSeq).toString(16).padStart(32, '0')}`;
const REC_MOM = `fr_${'a'.repeat(32)}`;
const REC_NANNY = `fr_${'b'.repeat(32)}`;

/** A valid new family recipe by [uid] (D-086), from the shared fixture (overrides merged last). */
function recipe(uid: string, id: string, over: Record<string, unknown> = {}) {
  return {
    ...familyRecipeFixture(id, 'b1'),
    createdBy: uid,
    author: author(uid),
    createdAt: serverTimestamp(),
    clientCreatedAt: Timestamp.now(),
    updatedAt: serverTimestamp(),
    updatedBy: uid,
    ...over,
  };
}
const storedRecipe = (uid: string, id: string) => ({
  ...recipe(uid, id),
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
    await setDoc(doc(db, `babies/b1/recipes/${REC_MOM}`), storedRecipe('mom', REC_MOM));
    await setDoc(doc(db, `babies/b1/recipes/${REC_NANNY}`), storedRecipe('nanny', REC_NANNY));
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
    await uploadBytes(ref(storage, 'babies/b1/recipes/photo_rec1.jpg'), new Uint8Array([1, 2]), {
      contentType: 'image/jpeg',
    });
  });
});

const as = (uid: string) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();
const mealRef = (uid: string, id: string) => doc(as(uid), `babies/b1/meals/${id}`);
const recipeRef = (uid: string, id: string) => doc(as(uid), `babies/b1/recipes/${id}`);
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
      // Cooked from one of the family's own recipes (D-086).
      { recipeId: REC_MOM },
      { recipeId: `fr_${'0123456789abcdef'.repeat(2)}` },
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
      { recipeId: `fr_${'A'.repeat(32)}` },
      { recipeId: `fr_${'a'.repeat(31)}` },
      { recipeId: `fr_${'a'.repeat(33)}` },
      { recipeId: `fr_chao_bi_do` },
      { recipeId: `m_${'a'.repeat(32)}` },
      { recipeId: `rcp_x fr_${'a'.repeat(32)}` },
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
        recipeId: REC_NANNY,
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

describe('family recipes: who writes and reads (D-086, plan §12 #2)', () => {
  it('Cùng nuôi and Người chăm sóc create them as themselves', async () => {
    for (const uid of ['mom', 'dad', 'nanny']) {
      const id = newRecipeId();
      await assertSucceeds(setDoc(recipeRef(uid, id), recipe(uid, id)));
    }
  });

  it('relatives (even with daily care), former, expired members and strangers never write', async () => {
    for (const uid of ['aunt', 'grandma', 'gone', 'late', 'stranger']) {
      const id = newRecipeId();
      await assertFails(setDoc(recipeRef(uid, id), recipe(uid, id)));
    }
  });

  it('care readers read and list them; others do not', async () => {
    for (const uid of ['mom', 'dad', 'nanny', 'aunt']) {
      await assertSucceeds(getDoc(recipeRef(uid, REC_MOM)));
      await assertSucceeds(getDocs(collection(as(uid), 'babies/b1/recipes')));
    }
    for (const uid of ['grandma', 'gone', 'late', 'stranger']) {
      await assertFails(getDoc(recipeRef(uid, REC_MOM)));
    }
    await assertFails(getDocs(collection(as('grandma'), 'babies/b1/recipes')));
    await assertFails(getDoc(doc(anon(), `babies/b1/recipes/${REC_MOM}`)));
  });

  it('attribution, ids and server times belong to the writer', async () => {
    const id = newRecipeId();
    const wrong: Record<string, unknown>[] = [
      { createdBy: 'mom' },
      { updatedBy: 'mom' },
      { author: author('mom') },
      { author: { ...author('nanny'), name: 'Bà Lan' } },
      { author: { ...author('nanny'), extra: 1 } },
      { createdAt: Timestamp.now() },
      { updatedAt: Timestamp.now() },
      { clientCreatedAt: '2026-10-19' },
      { id: newRecipeId() },
      { babyId: 'b2' },
      { deleted: true },
      { deletedAt: Timestamp.now() },
      { deletedBy: 'nanny' },
    ];
    for (const over of wrong) {
      await assertFails(setDoc(recipeRef('nanny', id), recipe('nanny', id, over)));
    }
    for (const bad of ['fr_XYZ', `fr_${'A'.repeat(32)}`, `m_${'c'.repeat(32)}`, 'rcp_chao']) {
      await assertFails(setDoc(recipeRef('nanny', bad), recipe('nanny', bad)));
    }
    await assertSucceeds(setDoc(recipeRef('nanny', id), recipe('nanny', id)));
  });
});

describe('family recipes: the shape (familyRecipeSchema)', () => {
  const tryRecipe = (over: Record<string, unknown>) => {
    const id = newRecipeId();
    return setDoc(recipeRef('mom', id), recipe('mom', id, over));
  };
  /** The same overrides through the contract (dates for timestamps): Rules and zod agree. */
  const contractOk = (over: Record<string, unknown>) =>
    familyRecipeSchema.safeParse({ ...familyRecipeFixture(REC_MOM, 'b1'), ...over }).success;
  const ing = (name = 'Cà rốt', over: Record<string, unknown> = {}) => ({
    foodId: null,
    name,
    qty: null,
    unit: null,
    ...over,
  });
  const ings = (n: number) => Array.from({ length: n }, (_, i) => ing(`Món ${i + 1}`));
  const steps = (n: number) => Array.from({ length: n }, (_, i) => `Bước ${i + 1}`);

  /** The largest recipe the contract allows, every field filled. */
  const fullest = () => ({
    title: 'x'.repeat(60),
    photoPath: 'babies/b1/recipes/photo_rec1.jpg',
    ingredients: Array.from({ length: 15 }, (_, i) =>
      ing('y'.repeat(40), { foodId: `fd_food_${i}`, qty: 1999.5, unit: 'piece' }),
    ),
    steps: Array.from({ length: 12 }, (_, i) => `${i + 1}`.padEnd(300, 'z')),
    note: 'n'.repeat(300),
  });

  const ok: Record<string, unknown>[] = [
    { ingredients: [ing()], steps: [], note: '' },
    { ingredients: ings(15) },
    { steps: steps(12) },
    { title: 'x'.repeat(60) },
    { title: '  Cháo  ' },
    { note: 'x'.repeat(300) },
    { steps: ['x'.repeat(300)] },
    { steps: ['Hấp cà rốt 10 phút.\nNghiền mịn.', '  Trộn cháo  '] },
    { ingredients: [ing('x'.repeat(40))] },
    { ingredients: [ing(` ${'x'.repeat(40)} `)] },
    { ingredients: [ing('Cà rốt', { foodId: 'fd_carrot', qty: 0.5, unit: 'bowl' })] },
    { ingredients: [ing('Gạo', { qty: 2000, unit: 'g' })] },
    { ingredients: [ing('Sữa', { qty: 120, unit: 'ml' }), ing('Dầu', { qty: 1, unit: 'tsp' })] },
    { ingredients: [ing('Trứng', { qty: 1, unit: 'piece' }), ing('Muối', { qty: null })] },
    // Key order does not matter.
    { ingredients: [{ unit: 'g', qty: 30, name: 'Cá hồi', foodId: 'fd_salmon' }] },
    // The family's own words are never blocked (the app only nudges): honey, salt.
    { title: 'Cháo mật ong', ingredients: [ing('Mật ong', { qty: 1, unit: 'tsp' })] },
  ];
  const bad: Record<string, unknown>[] = [
    { title: '' },
    { title: '   ' },
    { title: 'x'.repeat(61) },
    { title: null },
    { ingredients: [] },
    { ingredients: ings(16) },
    { ingredients: ing() },
    // The last one (the 15th) is checked too.
    { ingredients: [...ings(14), ing('')] },
    { ingredients: [...ings(14), { ...ing(), note: 'x' }] },
    { ingredients: [{ foodId: null, name: 'Cà rốt', qty: null }] },
    { ingredients: [{ ...ing(), note: 'x' }] },
    { ingredients: [ing('')] },
    { ingredients: [ing('   ')] },
    { ingredients: [ing('x'.repeat(41))] },
    { ingredients: [ing('Cà rốt'), ing('x'.repeat(41))] },
    { ingredients: [ing('Cà rốt', { name: 7 })] },
    { ingredients: ['Cà rốt'] },
    { ingredients: [null] },
    { steps: steps(13) },
    { steps: [''] },
    { steps: ['   '] },
    { steps: ['ok', '   '] },
    { steps: ['', 'ok'] },
    { steps: ['ok', ''] },
    { steps: ['x'.repeat(301)] },
    { steps: [...steps(11), 'x'.repeat(301)] },
    { steps: [...steps(11), 7] },
    { steps: [7] },
    { steps: [null] },
    { steps: [true] },
    { steps: [{ text: 'Hấp' }] },
    { steps: 'Hấp' },
    { note: 'x'.repeat(301) },
    { note: null },
    { photoPath: 7 },
    { extra: true },
  ];
  // Rules cannot afford these per ingredient (the 1000-expression budget, see firestore.rules):
  // the contract refuses them and the app reads them defensively. Pinned so a change is deliberate.
  const contractOnly: Record<string, unknown>[] = [
    { ingredients: [ing('Cà rốt', { foodId: 'carrot' })] },
    { ingredients: [ing('Cà rốt', { foodId: 'rcp_carrot' })] },
    { ingredients: [ing('Cà rốt', { qty: 0 })] },
    { ingredients: [ing('Cà rốt', { qty: 2001 })] },
    { ingredients: [ing('Cà rốt', { qty: '30' })] },
    { ingredients: [ing('Cà rốt', { unit: 'cup' })] },
  ];
  // Rules are a little stricter on steps: at most 300 characters before trimming, and never the
  // U+001F separator the check joins on.
  const rulesOnly: Record<string, unknown>[] = [
    { steps: [` ${'x'.repeat(300)}`] },
    { steps: ['Hấp\u001fnghiền'] },
  ];

  it('accepts what the contract accepts', async () => {
    for (const over of ok) {
      expect(contractOk(over), JSON.stringify(over)).toBe(true);
      await assertSucceeds(tryRecipe(over));
    }
  });

  it('refuses what the contract refuses', async () => {
    for (const over of bad) {
      expect(contractOk(over), JSON.stringify(over)).toBe(false);
      await assertFails(tryRecipe(over));
    }
    const id = newRecipeId();
    for (const key of ['note', 'photoPath', 'steps', 'ingredients', 'clientCreatedAt']) {
      const missing: Record<string, unknown> = recipe('mom', id);
      delete missing[key];
      await assertFails(setDoc(recipeRef('mom', id), missing));
    }
  });

  it('the known differences from the contract', async () => {
    for (const over of contractOnly) {
      expect(contractOk(over), JSON.stringify(over)).toBe(false);
      await assertSucceeds(tryRecipe(over));
    }
    for (const over of rulesOnly) {
      expect(contractOk(over), JSON.stringify(over)).toBe(true);
      await assertFails(tryRecipe(over));
    }
  });

  it('the fullest recipe fits the expression budget, created and edited', async () => {
    expect(contractOk(fullest())).toBe(true);
    // A caregiver creates it (the writer's membership read for the author) …
    const id = newRecipeId();
    await assertSucceeds(setDoc(recipeRef('nanny', id), recipe('nanny', id, fullest())));
    // … one ingredient and twelve steps (the most indexes past the end) …
    const few = newRecipeId();
    await assertSucceeds(
      setDoc(recipeRef('nanny', few), recipe('nanny', few, { ...fullest(), ingredients: [ing()] })),
    );
    // … and a Cùng nuôi rewrites all of it.
    const next = fullest();
    await assertSucceeds(
      updateDoc(recipeRef('dad', id), {
        ...next,
        title: 'w'.repeat(60),
        steps: next.steps.map((s) => s.replace(/z/g, 'q')),
        ingredients: next.ingredients.map((x) => ({ ...x, qty: 2 })),
        updatedAt: serverTimestamp(),
        updatedBy: 'dad',
      }),
    );
  });

  it("the photo is its own, under this baby's recipes in Storage", async () => {
    await assertSucceeds(tryRecipe({ photoPath: 'babies/b1/recipes/photo_rec1.jpg' }));
    for (const photoPath of [
      'babies/b1/meals/photo_mom1.jpg',
      'babies/b2/recipes/photo_rec1.jpg',
      'babies/b1/recipes/x.jpg',
      'babies/b1/recipes/photo_rec1.png',
      `babies/b1/recipes/${'x'.repeat(65)}.jpg`,
    ]) {
      await assertFails(tryRecipe({ photoPath }));
    }
  });
});

describe('family recipes: edit and delete (D-022, soft delete only)', () => {
  const edit = (uid: string, id: string, over: Record<string, unknown> = {}) =>
    updateDoc(recipeRef(uid, id), {
      title: 'Cháo cá hồi cà rốt',
      updatedAt: serverTimestamp(),
      updatedBy: uid,
      ...over,
    });
  const remove = (uid: string, id: string) =>
    updateDoc(recipeRef(uid, id), {
      deleted: true,
      deletedAt: serverTimestamp(),
      deletedBy: uid,
      updatedAt: serverTimestamp(),
      updatedBy: uid,
    });
  const restore = (uid: string, id: string) =>
    updateDoc(recipeRef(uid, id), {
      deleted: false,
      deletedAt: null,
      deletedBy: null,
      updatedAt: serverTimestamp(),
      updatedBy: uid,
    });

  it('the writer or a Cùng nuôi edits; a caregiver only their own', async () => {
    await assertSucceeds(edit('nanny', REC_NANNY));
    await assertFails(edit('nanny', REC_MOM));
    await assertSucceeds(edit('mom', REC_NANNY));
    await assertSucceeds(edit('dad', REC_MOM));
    for (const uid of ['aunt', 'grandma', 'gone', 'late', 'stranger']) {
      await assertFails(edit(uid, REC_MOM));
    }
  });

  it('the content changes; who, which baby and when it was made never do', async () => {
    await assertSucceeds(
      edit('mom', REC_MOM, {
        photoPath: 'babies/b1/recipes/photo_rec1.jpg',
        ingredients: [{ foodId: 'fd_carrot', name: 'Cà rốt', qty: 40, unit: 'g' }],
        steps: ['Hấp chín.', 'Nghiền mịn.', 'Trộn cháo.'],
        note: 'Thêm chút dầu ô liu',
      }),
    );
    await assertSucceeds(edit('mom', REC_MOM, { photoPath: null, steps: [] }));
    const fixed: Record<string, unknown>[] = [
      { createdBy: 'dad' },
      { author: author('dad') },
      { babyId: 'b2' },
      { id: newRecipeId() },
      { createdAt: serverTimestamp() },
      { clientCreatedAt: Timestamp.now() },
      { updatedBy: 'dad' },
      { updatedAt: Timestamp.now() },
      { title: '' },
      { ingredients: [] },
      { steps: ['x'.repeat(301)] },
      { photoPath: 'babies/b1/meals/photo_mom1.jpg' },
      { deleted: true },
      { extra: 1 },
    ];
    for (const over of fixed) await assertFails(edit('mom', REC_MOM, over));
  });

  it('"Xoá" is a soft delete with undo; never a hard delete', async () => {
    await assertFails(remove('nanny', REC_MOM));
    await assertSucceeds(remove('nanny', REC_NANNY));
    // Deleted recipes are not edited, only restored.
    await assertFails(edit('nanny', REC_NANNY));
    await assertFails(edit('mom', REC_NANNY, { deleted: false }));
    await assertSucceeds(restore('nanny', REC_NANNY));
    await assertSucceeds(remove('mom', REC_NANNY));
    await assertSucceeds(restore('dad', REC_NANNY));
    await assertFails(
      updateDoc(recipeRef('mom', REC_MOM), {
        deleted: true,
        deletedAt: Timestamp.now(),
        deletedBy: 'mom',
        updatedAt: serverTimestamp(),
        updatedBy: 'mom',
      }),
    );
    await assertFails(
      updateDoc(recipeRef('mom', REC_MOM), {
        deleted: true,
        deletedAt: serverTimestamp(),
        deletedBy: 'dad',
        updatedAt: serverTimestamp(),
        updatedBy: 'mom',
      }),
    );
    // A soft delete carries no content change.
    await assertFails(
      updateDoc(recipeRef('mom', REC_MOM), {
        title: 'Khác',
        deleted: true,
        deletedAt: serverTimestamp(),
        deletedBy: 'mom',
        updatedAt: serverTimestamp(),
        updatedBy: 'mom',
      }),
    );
    for (const uid of ['mom', 'nanny', 'stranger']) {
      await assertFails(deleteDoc(recipeRef(uid, REC_NANNY)));
    }
  });

  it('a recipe whose writer deleted their account stays editable by Cùng nuôi', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), `babies/b1/recipes/${REC_NANNY}`), {
        author: { name: '', relation: 'deleted', relationCustom: null },
        authorDeleted: true,
      });
    });
    await assertSucceeds(edit('mom', REC_NANNY));
    await assertSucceeds(remove('dad', REC_NANNY));
  });

  it('locked while the profile is deleted; still readable', async () => {
    await lockBaby();
    await assertSucceeds(getDoc(recipeRef('mom', REC_MOM)));
    const id = newRecipeId();
    await assertFails(setDoc(recipeRef('mom', id), recipe('mom', id)));
    await assertFails(edit('mom', REC_MOM));
    await assertFails(remove('nanny', REC_NANNY));
  });
});

describe('family recipe photos in Storage (D-086)', () => {
  const storage = (uid: string) => env.authenticatedContext(uid).storage();
  const jpeg = { contentType: 'image/jpeg' };
  const put = (uid: string, file: string, n = 10, meta = jpeg) =>
    uploadBytes(ref(storage(uid), `babies/b1/recipes/${file}`), new Uint8Array(n), meta);

  it('Cùng nuôi and Người chăm sóc add a JPEG up to 4 MB under a safe name', async () => {
    await assertSucceeds(put('mom', 'photo_rec2.jpg'));
    await assertSucceeds(put('nanny', 'nanny-recipe_01.jpg', 4 * 1024 * 1024));
    await assertFails(put('nanny', 'too-big-recipe.jpg', 4 * 1024 * 1024 + 1));
    await assertFails(put('mom', 'photo_rec3.png', 10, { contentType: 'image/png' }));
    await assertFails(put('mom', 'photo_rec3.jpg', 10, { contentType: 'image/png' }));
    await assertFails(put('mom', 'short.jpg'));
    await assertFails(put('mom', 'has.dots.jpg'));
    for (const uid of ['aunt', 'grandma', 'gone', 'late', 'stranger']) {
      await assertFails(put(uid, `photo_${uid}_1.jpg`));
    }
  });

  it('care readers see them; Cùng nuôi remove them', async () => {
    const path = 'babies/b1/recipes/photo_rec1.jpg';
    for (const uid of ['mom', 'dad', 'nanny', 'aunt']) {
      await assertSucceeds(getBytes(ref(storage(uid), path)));
    }
    for (const uid of ['grandma', 'gone', 'late', 'stranger']) {
      await assertFails(getBytes(ref(storage(uid), path)));
    }
    await assertFails(deleteObject(ref(storage('nanny'), path)));
    await assertFails(deleteObject(ref(storage('aunt'), path)));
    await assertSucceeds(deleteObject(ref(storage('dad'), path)));
  });
});
