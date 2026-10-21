import { randomUUID } from 'node:crypto';
import type { Readable } from 'node:stream';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { Timestamp, getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { _test, runDeletionJob, runExport, type PurgeStore } from '../functions/src/account.js';
import { purgeDeletedRecords } from '../functions/src/care.js';
import { familyRecipeFixture } from '../functions/test/solids-fixtures.js';

// Ăn dặm meals on the server (D-085 #3, P-164 #4; plan §10 #9) against the Firestore emulator:
// the 30-day bin purges soft-deleted meals and their photo, the care export carries `meals.csv`,
// an account deletion keeps meals as "Người dùng đã xoá", and deleting the baby takes `meals` and
// `solids` with it. "Công thức nhà mình" (D-086, plan §12 #2) the same way, with
// `family-recipes.csv`. Its own project (the bin and the authored step query collection groups).
const projectId = 'demo-child-life-solids';
const now = new Date('2026-10-19T08:00:00Z');
const BABY = 'b_501d5000000000000001';
let app: App;
let db: Firestore;

let seq = 0;
const mealId = () => `m_${(++seq).toString(16).padStart(32, '0')}`;
const at = (iso: string) => Timestamp.fromDate(new Date(iso));

async function putMeal(over: Record<string, unknown> = {}, babyId = BABY) {
  const id = mealId();
  const doc = {
    id,
    babyId,
    occurredAt: at('2026-10-18T04:30:00Z'),
    slot: 'noon',
    dish: 'Cháo bí đỏ',
    foodIds: ['fd_pumpkin', 'fd_egg'],
    freeFoods: [],
    amount: { preset: 'halfBowl' },
    reaction: 'liked',
    symptoms: [],
    note: '',
    recipeId: null,
    photoPath: null,
    createdBy: 'mom',
    author: { name: 'Mẹ Na', relation: 'mother', relationCustom: null },
    createdAt: at('2026-10-18T04:31:00Z'),
    clientCreatedAt: at('2026-10-18T04:31:00Z'),
    updatedAt: at('2026-10-18T04:31:00Z'),
    updatedBy: 'mom',
    deleted: false,
    deletedAt: null,
    deletedBy: null,
    ...over,
  };
  await db.doc(`babies/${babyId}/meals/${id}`).set(doc);
  return db.doc(`babies/${babyId}/meals/${id}`);
}

let frSeq = 0;
const recipeId = () => `fr_${(++frSeq).toString(16).padStart(32, '0')}`;

/** A family recipe (D-086) from the shared fixture, stored as the app would leave it. */
async function putRecipe(over: Record<string, unknown> = {}, babyId = BABY) {
  const id = recipeId();
  await db
    .doc(`babies/${babyId}/recipes/${id}`)
    .set({ ...familyRecipeFixture(id, babyId), ...over });
  return db.doc(`babies/${babyId}/recipes/${id}`);
}

class FakeStore implements PurgeStore {
  objects = new Map<string, number>();
  files = new Map<string, Map<string, string>>();
  async deletePrefix(prefix: string) {
    for (const k of [...this.objects.keys()]) if (k.startsWith(prefix)) this.objects.delete(k);
  }
  async countPrefix(prefix: string) {
    return [...this.objects.keys()].filter((k) => k.startsWith(prefix)).length;
  }
  async zip(path: string, entries: AsyncIterable<{ name: string; open: () => Promise<Readable> }>) {
    const out = new Map<string, string>();
    let bytes = 0;
    for await (const e of entries) {
      const chunks: Buffer[] = [];
      for await (const chunk of await e.open()) chunks.push(chunk as Buffer);
      const buf = Buffer.concat(chunks);
      bytes += buf.length;
      out.set(e.name, buf.toString('utf8'));
    }
    this.files.set(path, out);
    this.objects.set(path, bytes);
    return bytes;
  }
}

beforeAll(() => {
  app = initializeApp({ projectId }, `solids-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  for (const c of [
    'babies',
    'contentFoods',
    'dataJobs',
    'deletionJobs',
    'mail',
    'auditLog',
    'users',
  ]) {
    await db.recursiveDelete(db.collection(c));
  }
  await db.doc(`babies/${BABY}`).set({ familyId: 'f_solids', state: 'active' });
});

describe('the 30-day bin (P-164 #4)', () => {
  it('purges meals deleted 30 days ago with their photo; recent and live ones stay', async () => {
    const photo = `babies/${BABY}/meals/photo_old_1.jpg`;
    const old = await putMeal({
      deleted: true,
      deletedAt: at('2026-09-10T00:00:00Z'),
      deletedBy: 'mom',
      photoPath: photo,
    });
    const oldNoPhoto = await putMeal({ deleted: true, deletedAt: at('2026-09-01T00:00:00Z') });
    // A path outside this baby's meals is never deleted from Storage (the meal still goes).
    const odd = await putMeal({
      deleted: true,
      deletedAt: at('2026-09-01T00:00:00Z'),
      photoPath: 'babies/b_other/meals/photo_odd_1.jpg',
    });
    const recent = await putMeal({ deleted: true, deletedAt: at('2026-10-01T00:00:00Z') });
    const live = await putMeal();
    await db.doc(`babies/${BABY}/records/r_${'1'.repeat(32)}`).set({
      deleted: true,
      deletedAt: at('2026-09-01T00:00:00Z'),
    });
    const removed: string[] = [];
    const n = await purgeDeletedRecords(db, now, { delete: async (p) => void removed.push(p) });
    expect(n).toBe(4);
    expect(removed).toEqual([photo]);
    for (const ref of [old, oldNoPhoto, odd]) expect((await ref.get()).exists).toBe(false);
    for (const ref of [recent, live]) expect((await ref.get()).exists).toBe(true);
  });

  it('a photo that fails to go keeps its meal for the next run', async () => {
    const ref = await putMeal({
      deleted: true,
      deletedAt: at('2026-09-01T00:00:00Z'),
      photoPath: `babies/${BABY}/meals/photo_keep_1.jpg`,
    });
    const failing = {
      delete: async () => {
        throw new Error('storage unavailable');
      },
    };
    await expect(purgeDeletedRecords(db, now, failing)).rejects.toThrow('storage unavailable');
    expect((await ref.get()).exists).toBe(true);
    expect(await purgeDeletedRecords(db, now, { delete: async () => undefined })).toBe(1);
  });

  it('purges family recipes deleted 30 days ago with their photo (D-086)', async () => {
    const photo = `babies/${BABY}/recipes/photo_rec_old1.jpg`;
    const old = await putRecipe({
      deleted: true,
      deletedAt: at('2026-09-10T00:00:00Z'),
      deletedBy: 'mom',
      photoPath: photo,
    });
    const oldNoPhoto = await putRecipe({ deleted: true, deletedAt: at('2026-09-01T00:00:00Z') });
    // A meal's photo (or another baby's) is never deleted with a recipe; the recipe still goes.
    const odd = await putRecipe({
      deleted: true,
      deletedAt: at('2026-09-01T00:00:00Z'),
      photoPath: `babies/${BABY}/meals/photo_meal_1.jpg`,
    });
    const recent = await putRecipe({ deleted: true, deletedAt: at('2026-10-01T00:00:00Z') });
    const live = await putRecipe({ photoPath: `babies/${BABY}/recipes/photo_rec_live.jpg` });
    // Only family recipes: a `recipes` collection anywhere else is not this bin's.
    const elsewhere = db.doc('users/u1/recipes/x1');
    await elsewhere.set({ deleted: true, deletedAt: at('2026-09-01T00:00:00Z') });
    const removed: string[] = [];
    const n = await purgeDeletedRecords(db, now, { delete: async (p) => void removed.push(p) });
    expect(n).toBe(3);
    expect(removed).toEqual([photo]);
    for (const ref of [old, oldNoPhoto, odd]) expect((await ref.get()).exists).toBe(false);
    for (const ref of [recent, live, elsewhere]) expect((await ref.get()).exists).toBe(true);
  });

  it('a recipe photo that fails to go keeps its recipe for the next run', async () => {
    const ref = await putRecipe({
      deleted: true,
      deletedAt: at('2026-09-01T00:00:00Z'),
      photoPath: `babies/${BABY}/recipes/photo_rec_keep.jpg`,
    });
    const failing = {
      delete: async () => {
        throw new Error('storage unavailable');
      },
    };
    await expect(purgeDeletedRecords(db, now, failing)).rejects.toThrow('storage unavailable');
    expect((await ref.get()).exists).toBe(true);
    expect(await purgeDeletedRecords(db, now, { delete: async () => undefined })).toBe(1);
    expect((await ref.get()).exists).toBe(false);
  });
});

describe('the care export (D-085 #3)', () => {
  it('meals.csv: live meals, oldest first, catalogue names in the export language, no photos', async () => {
    await db.doc('contentFoods/fd_pumpkin').set({
      status: 'published',
      name: { vi: 'Bí đỏ', en: 'Pumpkin' },
    });
    await db.doc('contentFoods/fd_draft_only').set({ status: 'draft', name: { vi: 'X', en: 'X' } });
    await putMeal({
      occurredAt: at('2026-10-18T11:00:00Z'),
      slot: 'evening',
      dish: '',
      foodIds: ['fd_pumpkin', 'fd_draft_only'],
      freeFoods: ['rau ngót'],
      amount: { value: 3, unit: 'spoon' },
      reaction: 'notYet',
      symptoms: ['rash', 'vomit'],
      note: 'Bé quấy, "khó chịu"',
      recipeId: 'rcp_chao_bi_do',
      photoPath: `babies/${BABY}/meals/photo_secret_1.jpg`,
    });
    await putMeal({ occurredAt: at('2026-10-17T00:30:00Z'), foodIds: ['fd_pumpkin'] });
    await putMeal({ deleted: true, deletedAt: at('2026-10-18T00:00:00Z'), dish: 'Đã xoá' });

    const vi = await _test.mealsCsv(db, BABY, 'vi');
    expect(vi.charCodeAt(0)).toBe(0xfeff);
    const lines = vi.slice(1).split('\n');
    expect(lines[0]).toBe(
      'id,occurredAt,slot,dish,foods,foodIds,amount,reaction,symptoms,note,recipeId,author,createdAt',
    );
    expect(lines).toHaveLength(3);
    expect(lines[1]).toContain(
      '2026-10-17T00:30:00.000Z,noon,Cháo bí đỏ,Bí đỏ,fd_pumpkin,halfBowl,liked',
    );
    expect(lines[2]).toContain(
      ',evening,,Bí đỏ; fd_draft_only; rau ngót,fd_pumpkin fd_draft_only,3 spoon,notYet,rash vomit,"Bé quấy, ""khó chịu""",rcp_chao_bi_do,Mẹ Na,',
    );
    expect(vi).not.toContain('photo_secret');
    expect(vi).not.toContain('Đã xoá');
    expect(await _test.mealsCsv(db, BABY, 'en')).toContain('Pumpkin; fd_draft_only; rau ngót');
  });

  it("family-recipes.csv: live family recipes, oldest first, the family's words, no photos", async () => {
    await putRecipe({
      title: 'Cháo cá hồi, bí đỏ',
      photoPath: `babies/${BABY}/recipes/photo_secret_2.jpg`,
      createdAt: at('2026-10-18T04:31:00Z'),
    });
    await putRecipe({
      title: 'Trứng hấp',
      ingredients: [
        { foodId: 'fd_egg', name: 'Trứng gà', qty: 1, unit: 'piece' },
        { foodId: null, name: 'Sữa của bé', qty: 1.5, unit: 'tsp' },
      ],
      steps: ['Đánh tan trứng với sữa.'],
      note: '',
      createdBy: 'nanny',
      author: { name: 'Cô Lan', relation: 'nanny', relationCustom: null },
      createdAt: at('2026-10-10T02:00:00Z'),
      updatedAt: at('2026-10-12T02:00:00Z'),
    });
    await putRecipe({ deleted: true, deletedAt: at('2026-10-18T00:00:00Z'), title: 'Đã xoá' });

    const vi = await _test.familyRecipesCsv(db, BABY, 'vi');
    expect(vi.charCodeAt(0)).toBe(0xfeff);
    expect(vi.slice(1).split('\n')[0]).toBe(
      'id,title,ingredients,steps,note,author,createdAt,updatedAt',
    );
    expect(vi).toContain(
      ',Trứng hấp,Trứng gà 1 miếng; Sữa của bé 1.5 thìa cà phê,1. Đánh tan trứng với sữa.,,Cô Lan,2026-10-10T02:00:00.000Z,2026-10-12T02:00:00.000Z',
    );
    // Commas, quotes and the numbered steps on their own lines stay in one quoted cell.
    expect(vi).toContain(
      ',"Cháo cá hồi, bí đỏ",Cá hồi 30 g; Bí đỏ 2 thìa canh; Nước dùng rau,"1. Hấp cá và bí cho chín mềm.\n2. Nghiền mịn, trộn với cháo trắng.","Na thích ăn ấm, ""không quá đặc""",Mẹ Na,2026-10-18T04:31:00.000Z,',
    );
    expect(vi.indexOf('Trứng hấp')).toBeLessThan(vi.indexOf('Cháo cá hồi'));
    expect(vi).not.toContain('photo_secret');
    expect(vi).not.toContain('Đã xoá');
    const en = await _test.familyRecipesCsv(db, BABY, 'en');
    expect(en).toContain('Cá hồi 30 g; Bí đỏ 2 tbsp; Nước dùng rau');
    expect(en).toContain('Trứng gà 1 piece; Sữa của bé 1.5 tsp');
  });

  it('family-recipes.csv is only the header when the family has none', async () => {
    expect(await _test.familyRecipesCsv(db, BABY, 'vi')).toBe(
      `${String.fromCharCode(0xfeff)}id,title,ingredients,steps,note,author,createdAt,updatedAt`,
    );
  });

  it('the care ZIP holds care.json, care.csv, meals.csv and family-recipes.csv', async () => {
    await putMeal();
    await putRecipe();
    await db.doc('dataJobs/job_solids').set({
      state: 'queued',
      uid: 'mom',
      exportKind: 'care',
      babyId: BABY,
      email: null,
      locale: 'vi',
    });
    const store = new FakeStore();
    expect(await runExport(db, store, async () => null as never, 'job_solids', now, 24)).toBe(
      'ready',
    );
    const job = (await db.doc('dataJobs/job_solids').get()).data()!;
    const files = store.files.get(job.path as string)!;
    expect([...files.keys()]).toEqual([
      'care.json',
      'personalization.json',
      'care.csv',
      'meals.csv',
      'family-recipes.csv',
    ]);
    expect(files.get('meals.csv')).toContain('Cháo bí đỏ');
    expect(files.get('family-recipes.csv')).toContain('Cháo cá hồi bí đỏ');
  });
});

describe('deletions', () => {
  it('an account deletion keeps meals and family recipes as "Người dùng đã xoá"', async () => {
    const lan = { name: 'Cô Lan', relation: 'nanny', relationCustom: null };
    const mine = await putMeal({ createdBy: 'nanny', author: lan });
    const other = await putMeal();
    const myRecipe = await putRecipe({ createdBy: 'nanny', updatedBy: 'nanny', author: lan });
    const momRecipe = await putRecipe({ updatedBy: 'nanny' });
    await db.doc('deletionJobs/acc_solids').set({
      kind: 'account',
      uid: 'nanny',
      steps: ['authored'],
      step: 0,
      state: 'queued',
    });
    const deps = { store: new FakeStore(), deleteAuthUser: async () => undefined };
    expect(await runDeletionJob(db, deps, 'acc_solids', () => now)).toBe('done');
    expect((await mine.get()).data()).toMatchObject({
      author: { name: '', relation: 'deleted', relationCustom: null },
      authorDeleted: true,
      dish: 'Cháo bí đỏ',
    });
    expect((await other.get()).get('authorDeleted')).toBeUndefined();
    expect((await myRecipe.get()).data()).toMatchObject({
      author: { name: '', relation: 'deleted', relationCustom: null },
      authorDeleted: true,
      title: 'Cháo cá hồi bí đỏ',
      deleted: false,
    });
    // Only who wrote it is marked: a recipe they merely edited keeps its writer.
    expect((await momRecipe.get()).data()).toMatchObject({ author: { name: 'Mẹ Na' } });
    expect((await momRecipe.get()).get('authorDeleted')).toBeUndefined();
  });

  it('deleting the baby takes meals, family recipes and solids settings with it (§10 #9)', async () => {
    await putMeal();
    await putRecipe({ photoPath: `babies/${BABY}/recipes/photo_rec_gone.jpg` });
    await db.doc(`babies/${BABY}/solids/settings`).set({ enabled: true });
    await db.doc('deletionJobs/baby_solids').set({
      kind: 'baby',
      babyId: BABY,
      familyId: 'f_solids',
      steps: ['documents'],
      step: 0,
      state: 'queued',
    });
    const deps = { store: new FakeStore(), deleteAuthUser: async () => undefined };
    expect(await runDeletionJob(db, deps, 'baby_solids', () => now)).toBe('done');
    expect((await db.collection(`babies/${BABY}/meals`).get()).empty).toBe(true);
    expect((await db.collection(`babies/${BABY}/recipes`).get()).empty).toBe(true);
    expect((await db.doc(`babies/${BABY}/solids/settings`).get()).exists).toBe(false);
  });
});
