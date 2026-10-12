import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import type { ExpenseExtractor } from '../functions/src/ai.js';
import type { PushSender } from '../functions/src/social.js';
import {
  analyzeSpendingImport,
  cleanupSpendingImports,
  confirmSpendingImport,
  importedCategoryId,
  importedExpenseId,
  importPage,
  runSpendingImport,
  undoSpendingImport,
  type ImportDeps,
  type ImportStore,
} from '../functions/src/spending-import.js';
import { SpendingError } from '../functions/src/spending.js';

// Nhập chi tiêu (D-060, P-144) against the Firestore emulator: analyze → confirm → import (the
// trigger's handler) → re-run → undo, refusals and the AI sources. Storage is an in-memory port.
// Times are Hồ Chí Minh (UTC+7).
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const familyId = 'f_import';
const babyId = 'b_1e000000000000000001';
const im = (n: number) => `im_${String(n).padStart(32, '0')}`;
const now = new Date(Date.UTC(2026, 9, 12, 3, 0)); // 12/10/2026 10:00 in Vietnam

class MemoryStore implements ImportStore {
  files = new Map<string, { bytes: Buffer; created: Date }>();
  put(path: string, data: unknown, created = now) {
    const bytes = Buffer.isBuffer(data) ? data : Buffer.from(JSON.stringify(data), 'utf8');
    this.files.set(path, { bytes, created });
  }
  async size(path: string) {
    return this.files.get(path)?.bytes.length ?? null;
  }
  async read(path: string) {
    const f = this.files.get(path);
    if (!f) throw new Error('missing');
    return f.bytes;
  }
  async write(path: string, bytes: Buffer) {
    this.put(path, bytes);
  }
  async listOlderThan(prefix: string, before: Date, max: number) {
    return [...this.files]
      .filter(([p, f]) => p.startsWith(prefix) && f.created < before)
      .map(([p]) => p)
      .slice(0, max);
  }
  async delete(path: string) {
    this.files.delete(path);
  }
}

let store: MemoryStore;
const pushes: { tokens: string[]; title: string; body: string; data: Record<string, string> }[] =
  [];
const sender: PushSender = {
  async send(tokens, message) {
    pushes.push({ tokens, title: message.title, body: message.body, data: message.data });
    return [];
  },
};
const aiCalls: { text?: string | undefined; images?: number | undefined; today: string }[] = [];
const extractor: ExpenseExtractor = {
  name: 'openai',
  async extractExpenses(input) {
    aiCalls.push({ text: input.text, images: input.images?.length, today: input.today });
    return [
      { date: '2026-10-10', amount: 120_000, note: 'Sữa bột', category: 'Sữa', payer: 'Mẹ' },
      { date: null, amount: 50_000, note: 'Khăn ướt', category: '', payer: '' },
    ];
  },
};
const deps = (over: Partial<ImportDeps> = {}): ImportDeps => ({ db, store, extractor, ...over });
const runDeps = () => ({
  ...deps(),
  sender,
  emailOf: async (uid: string) => `${uid}@example.com`,
});

async function reasonOf(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (error) {
    if (error instanceof SpendingError) return error.reason;
    throw error;
  }
  throw new Error('expected a SpendingError');
}

const member = (uid: string, role: string, extra: object = {}) =>
  db.doc(`babies/${babyId}/members/${uid}`).set({
    uid,
    babyId,
    role,
    isOwner: uid === 'mom',
    relation: { mom: 'mother', dad: 'father' }[uid] ?? 'grandmother',
    relationCustom: null,
    displayName: { mom: 'Mai', dad: 'Nam' }[uid] ?? uid,
    status: 'active',
    extraRights: null,
    ...extra,
  });

/** A Money Lover-like export: spending negative, one income row, one USD row. */
const moneyLover = [
  ['Id', 'Date', 'Category', 'Amount', 'Currency', 'Note', 'Wallet', 'Paid by'],
  ['1', '01/10/2026', 'Sữa', '-1,020,000', 'VND', 'Sữa công thức', 'Cash', 'Mẹ'],
  ['2', '02/10/2026', 'Bỉm', '-350,000', 'VND', 'Tã dán', 'Cash', 'Ba'],
  ['3', '03/10/2026', 'Bơi lội', '-200,000', 'VND', 'Học bơi', 'Cash', 'Mẹ'],
  ['4', '04/10/2026', 'Salary', '20,000,000', 'VND', 'Lương', 'Bank', ''],
  ['5', '05/10/2026', 'Sữa', '-12', 'USD', 'Online', 'Card', ''],
  ['6', '06/10/2026', 'Khám', '-300,000', 'VND', 'Khám tai', 'Cash', 'Bà'],
  ['7', '20/10/2026', 'Sữa', '-100,000', 'VND', 'Ngày mai', 'Cash', ''],
  [],
];

beforeAll(() => {
  app = initializeApp({ projectId }, `spending-import-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host) throw new Error('Run with the Firestore emulator (pnpm test:rules)');
  await fetch(`http://${host}/emulator/v1/projects/${projectId}/databases/(default)/documents`, {
    method: 'DELETE',
  });
  store = new MemoryStore();
  pushes.length = 0;
  aiCalls.length = 0;
  await db.doc(`families/${familyId}`).set({ ownerUid: 'mom', babyIds: [babyId] });
  await db.doc(`babies/${babyId}`).set({
    familyId,
    ownerUid: 'mom',
    state: 'active',
    timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' },
  });
  await member('mom', 'coParent');
  await member('dad', 'coParent');
  await member('gma', 'relative', {
    extraRights: {
      viewBabyInfo: true,
      viewDailyCare: true,
      recordSpending: true,
      viewSpending: true,
    },
  });
  await member('nanny', 'caregiver');
  for (const uid of ['mom', 'dad']) {
    await db
      .doc(`users/${uid}/devices/d_${uid}`)
      .set({ token: `t-${uid}`, language: uid === 'dad' ? 'en' : 'vi', updatedAt: now });
  }
  // Already in Chi tiêu: the 2/10 diapers (same day, amount and description).
  await db.doc(`babies/${babyId}/expenses/x_${'d'.repeat(32)}`).set({
    amount: 350_000,
    categoryId: 'c_diaper',
    note: 'tã dán',
    spentOn: '2026-10-02',
    payer: null,
    receiptPath: null,
    source: 'manual',
    sourceRef: null,
    createdBy: 'mom',
    author: { name: 'Mai', relation: 'mother', relationCustom: null },
    createdAt: now,
    updatedAt: now,
    updatedBy: 'mom',
    deleted: false,
    deletedAt: null,
    deletedBy: null,
  });
  // A renamed built-in.
  await db.doc(`families/${familyId}/spendingCategories/c_health`).set({
    name: 'Khám bệnh',
    icon: 'heart',
    tint: 'pump',
    order: 3,
    hidden: false,
    builtIn: true,
    updatedAt: now,
    updatedBy: 'mom',
  });
});

const importDoc = async (id: string) =>
  (await db.doc(`babies/${babyId}/spendingImports/${id}`).get()).data()!;
const liveImported = async (id: string) =>
  (await db.collection(`babies/${babyId}/expenses`).where('sourceRef', '==', id).get()).docs;

describe('analyze (file)', () => {
  it('finds the columns, reads the rows and writes the preview', async () => {
    store.put(`imports/mom/${im(1)}.json`, moneyLover);
    expect(
      await analyzeSpendingImport(
        deps(),
        'mom',
        { babyId, importId: im(1), kind: 'file', fileName: 'money-lover.csv' },
        now,
      ),
    ).toEqual({ status: 'ready' });
    const d = await importDoc(im(1));
    expect(d).toMatchObject({
      kind: 'file',
      fileName: 'money-lover.csv',
      status: 'ready',
      preset: 'Money Lover',
      mapping: { firstRow: 1, date: 1, amount: 3, note: [5], category: 2, payer: 7 },
      options: { dateOrder: 'dmy', rows: 'negative', skipDuplicates: true },
      mixedSigns: true,
      ambiguousDates: false,
      counts: { rows: 7, ready: 3, duplicates: 1, income: 1, errors: 2 },
      createdBy: 'mom',
      progress: 0,
      imported: 0,
      issues: [],
      failure: null,
      finishedAt: null,
      undoUntil: null,
    });
    expect(d.columns).toEqual([
      'Id',
      'Date',
      'Category',
      'Amount',
      'Currency',
      'Note',
      'Wallet',
      'Paid by',
    ]);
    // The review: rows that will be imported, rows left out with why, the total and days.
    expect(d.preview.map((r: { issue: string | null }) => r.issue)).toEqual([null, null, null]);
    expect(d.skipped.map((r: { issue: string | null }) => r.issue)).toEqual([
      'duplicate',
      'income',
      'other-currency',
      'future-date',
    ]);
    expect(d.total.from).toBe('2026-10-01');
    expect(d.preview[0]).toEqual({
      row: 2,
      spentOn: '2026-10-01',
      amount: 1_020_000,
      note: 'Sữa công thức',
      category: 'Sữa',
      payer: 'Mẹ',
      issue: null,
    });
    expect(d.categories).toEqual([
      { key: 'sua', name: 'Sữa', rows: 1, suggested: { kind: 'existing', id: 'c_milk' } },
      // No match: a category of its own by default (owner, 2026-10-12).
      { key: 'boi loi', name: 'Bơi lội', rows: 1, suggested: { kind: 'new', name: 'Bơi lội' } },
      { key: 'kham', name: 'Khám', rows: 1, suggested: { kind: 'existing', id: 'c_health' } },
    ]);
    expect(d.payers).toEqual([
      { key: 'mẹ', name: 'Mẹ', rows: 2, suggested: 'mom' },
      { key: 'bà', name: 'Bà', rows: 1, suggested: 'gma' },
    ]);
  });

  it('pages through every row that will be imported', async () => {
    store.put(`imports/mom/${im(1)}.json`, moneyLover);
    await analyzeSpendingImport(deps(), 'mom', { babyId, importId: im(1), kind: 'file' }, now);
    const first = await importPage(deps(), 'dad', { babyId, importId: im(1), page: 0 }, now);
    expect(first).toMatchObject({ total: 3, page: 0, pages: 1 });
    expect(first.rows.every((r) => r.issue == null)).toBe(true);
    expect((await importPage(deps(), 'mom', { babyId, importId: im(1), page: 9 }, now)).page).toBe(
      0,
    );
    expect(
      await reasonOf(importPage(deps(), 'nanny', { babyId, importId: im(1), page: 0 }, now)),
    ).toBe('not-co-parent');
  });

  it('reads again with other options or columns', async () => {
    store.put(`imports/mom/${im(1)}.json`, moneyLover);
    await analyzeSpendingImport(deps(), 'mom', { babyId, importId: im(1), kind: 'file' }, now);
    await analyzeSpendingImport(
      deps(),
      'dad',
      {
        babyId,
        importId: im(1),
        kind: 'file',
        options: { dateOrder: 'dmy', rows: 'all', skipDuplicates: false },
      },
      now,
    );
    const d = await importDoc(im(1));
    expect(d.counts).toEqual({ rows: 7, ready: 5, duplicates: 0, income: 0, errors: 2 });
    expect(d.createdBy).toBe('mom');
    expect(d.fileName).toBeNull();
  });

  it('refuses anyone but an active Cùng nuôi, a closed profile and a missing or large grid', async () => {
    store.put(`imports/mom/${im(1)}.json`, moneyLover);
    const req = { babyId, importId: im(1), kind: 'file' };
    expect(await reasonOf(analyzeSpendingImport(deps(), 'gma', req, now))).toBe('not-co-parent');
    expect(await reasonOf(analyzeSpendingImport(deps(), 'nanny', req, now))).toBe('not-co-parent');
    expect(await reasonOf(analyzeSpendingImport(deps(), 'stranger', req, now))).toBe(
      'not-a-member',
    );
    expect(
      await reasonOf(analyzeSpendingImport(deps(), 'mom', { ...req, importId: 'x' }, now)),
    ).toBe('malformed');

    expect(
      await reasonOf(analyzeSpendingImport(deps(), 'mom', { ...req, importId: im(2) }, now)),
    ).toBe('no-upload');
    expect(await importDoc(im(2))).toMatchObject({ status: 'failed', failure: 'no-upload' });

    store.put(
      `imports/mom/${im(3)}.json`,
      Array.from({ length: 5001 }, () => ['1']),
    );
    expect(
      await reasonOf(analyzeSpendingImport(deps(), 'mom', { ...req, importId: im(3) }, now)),
    ).toBe('too-big');
    store.put(`imports/mom/${im(4)}.json`, [[''], []]);
    expect(
      await reasonOf(analyzeSpendingImport(deps(), 'mom', { ...req, importId: im(4) }, now)),
    ).toBe('empty');

    await db.doc(`babies/${babyId}`).update({ state: 'deleting' });
    expect(await reasonOf(analyzeSpendingImport(deps(), 'mom', req, now))).toBe('baby-closed');
  });
});

describe('analyze (AI)', () => {
  it('without an API key the text and photo sources are unavailable', async () => {
    const req = { babyId, importId: im(5), kind: 'text', text: '10/10 sữa 120k' };
    expect(await reasonOf(analyzeSpendingImport(deps({ extractor: null }), 'mom', req, now))).toBe(
      'ai-unavailable',
    );
    expect(await importDoc(im(5))).toMatchObject({ status: 'failed', failure: 'ai-unavailable' });
    expect(store.files.has(`imports/mom/${im(5)}.json`)).toBe(false);
  });

  it('text becomes a stored grid read like a file; the AI is asked once', async () => {
    const req = { babyId, importId: im(6), kind: 'text', text: '10/10 sữa 120k, khăn ướt 50k' };
    await analyzeSpendingImport(deps(), 'mom', req, now);
    expect(aiCalls).toEqual([{ text: req.text, images: undefined, today: '2026-10-12' }]);
    const grid = JSON.parse(store.files.get(`imports/mom/${im(6)}.json`)!.bytes.toString());
    expect(grid[0]).toEqual(['Ngày', 'Danh mục', 'Nội dung', 'Số tiền', 'Ai trả']);
    const d = await importDoc(im(6));
    expect(d).toMatchObject({
      kind: 'text',
      status: 'ready',
      preset: null,
      counts: { rows: 2, ready: 1, duplicates: 0, income: 0, errors: 1 },
    });
    expect(d.skipped[0].issue).toBe('no-date');
    await analyzeSpendingImport(
      deps(),
      'mom',
      { ...req, options: { dateOrder: 'dmy', rows: 'all', skipDuplicates: true } },
      now,
    );
    expect(aiCalls).toHaveLength(1);
  });

  it('photos must all be uploaded', async () => {
    const req = { babyId, importId: im(7), kind: 'images', images: 2 };
    store.put(`imports/mom/${im(7)}/0.jpg`, Buffer.from([1, 2, 3]));
    expect(await reasonOf(analyzeSpendingImport(deps(), 'mom', req, now))).toBe('no-upload');
    store.put(`imports/mom/${im(7)}/1.jpg`, Buffer.from([4, 5]));
    await analyzeSpendingImport(deps(), 'mom', req, now);
    expect(aiCalls.at(-1)).toMatchObject({ images: 2 });
    expect((await importDoc(im(7))).status).toBe('ready');
  });
});

const confirmReq = (over: object = {}) => ({
  babyId,
  importId: im(1),
  mapping: { firstRow: 1, date: 1, amount: 3, note: [5], category: 2, payer: 7 },
  options: { dateOrder: 'dmy', rows: 'negative', skipDuplicates: true },
  categories: {
    sua: { kind: 'existing', id: 'c_milk' },
    'boi loi': { kind: 'new', name: 'Bơi lội' },
    // Not in any importable row: never created.
    'du lich': { kind: 'new', name: 'Du lịch' },
  },
  payers: { mẹ: 'mom', bà: 'gma', ba: 'dad' },
  ...over,
});

describe('confirm → import → undo', () => {
  beforeEach(async () => {
    store.put(`imports/mom/${im(1)}.json`, moneyLover);
    await analyzeSpendingImport(deps(), 'mom', { babyId, importId: im(1), kind: 'file' }, now);
  });

  it('checks the caller, the state and the choices', async () => {
    expect(await reasonOf(confirmSpendingImport(db, 'gma', confirmReq(), now))).toBe(
      'not-co-parent',
    );
    expect(
      await reasonOf(
        confirmSpendingImport(
          db,
          'mom',
          confirmReq({ categories: { sua: { kind: 'existing', id: 'c_nothere' } } }),
          now,
        ),
      ),
    ).toBe('category-not-found');
    expect(
      await reasonOf(
        confirmSpendingImport(db, 'mom', confirmReq({ payers: { mẹ: 'nobody' } }), now),
      ),
    ).toBe('payer-not-found');
    const many = Object.fromEntries(
      Array.from({ length: 31 }, (_, i) => [`k${i}`, { kind: 'new', name: `Mục ${i}` }]),
    );
    expect(
      await reasonOf(confirmSpendingImport(db, 'mom', confirmReq({ categories: many }), now)),
    ).toBe('too-many-categories');
    expect(
      await reasonOf(confirmSpendingImport(db, 'mom', confirmReq({ importId: im(9) }), now)),
    ).toBe('not-found');
    expect(await confirmSpendingImport(db, 'dad', confirmReq(), now)).toEqual({ status: 'queued' });
    expect(await reasonOf(confirmSpendingImport(db, 'mom', confirmReq(), now))).toBe('wrong-state');
    expect(
      await reasonOf(
        analyzeSpendingImport(deps(), 'mom', { babyId, importId: im(1), kind: 'file' }, now),
      ),
    ).toBe('wrong-state');
  });

  it('imports once, tells the importer, survives a re-run and can be undone', async () => {
    await confirmSpendingImport(db, 'dad', confirmReq(), now);
    expect((await importDoc(im(1))).status).toBe('queued');

    const later = new Date(now.getTime() + 60_000);
    const result = await runSpendingImport(runDeps(), babyId, im(1), later);
    expect(result).toEqual({ ran: true, imported: 3, failure: null });

    const d = await importDoc(im(1));
    expect(d).toMatchObject({
      status: 'done',
      progress: 100,
      imported: 3,
      counts: { rows: 7, ready: 3, duplicates: 1, income: 1, errors: 2 },
      failure: null,
    });
    expect(d.issues).toEqual([
      { row: 3, issue: 'duplicate' },
      { row: 5, issue: 'income' },
      { row: 6, issue: 'other-currency' },
      { row: 8, issue: 'future-date' },
    ]);
    expect(d.finishedAt.toDate()).toEqual(later);
    expect(d.undoUntil.toDate()).toEqual(new Date(later.getTime() + 7 * 86_400_000));

    // "Bơi lội" was created once, as a custom category after the built-ins.
    const swimId = importedCategoryId(im(1), 'boi loi');
    const swim = (await db.doc(`families/${familyId}/spendingCategories/${swimId}`).get()).data();
    expect(swim).toMatchObject({
      name: 'Bơi lội',
      icon: 'grid',
      builtIn: false,
      hidden: false,
      updatedBy: 'dad',
    });
    expect(swim!.order).toBeGreaterThan(5);
    const cats = await db.collection(`families/${familyId}/spendingCategories`).get();
    expect(cats.size).toBe(2);

    // Expenses exactly as the app writes them, recorded by the person who confirmed.
    const milk = (
      await db.doc(`babies/${babyId}/expenses/${importedExpenseId(im(1), 2)}`).get()
    ).data()!;
    expect(milk).toEqual({
      amount: 1_020_000,
      categoryId: 'c_milk',
      note: 'Sữa công thức',
      spentOn: '2026-10-01',
      payer: { uid: 'mom', name: 'Mai', relation: 'mother', relationCustom: null },
      receiptPath: null,
      source: 'import',
      sourceRef: im(1),
      createdBy: 'dad',
      author: { name: 'Nam', relation: 'father', relationCustom: null },
      createdAt: expect.anything(),
      updatedAt: expect.anything(),
      updatedBy: 'dad',
      deleted: false,
      deletedAt: null,
      deletedBy: null,
    });
    const health = (
      await db.doc(`babies/${babyId}/expenses/${importedExpenseId(im(1), 7)}`).get()
    ).data()!;
    // "Khám" was not chosen: it goes to "Khác"; "Bà" was matched to grandma.
    expect(health).toMatchObject({ categoryId: 'c_other', payer: { uid: 'gma' } });
    const swimExpense = (
      await db.doc(`babies/${babyId}/expenses/${importedExpenseId(im(1), 4)}`).get()
    ).data()!;
    expect(swimExpense).toMatchObject({ categoryId: swimId, payer: { uid: 'mom' } });
    expect(await liveImported(im(1))).toHaveLength(3);

    // Mail and push to the importer only: counts, no names, amounts or descriptions.
    const mail = (await db.doc(`mail/spimport_${im(1)}_done`).get()).data()!;
    expect(mail).toMatchObject({
      to: 'dad@example.com',
      template: 'spendingImportDone',
      locale: 'en',
      data: { added: 3, duplicates: 1, errors: 2 },
      status: 'queued',
    });
    expect(pushes).toEqual([
      {
        tokens: ['t-dad'],
        title: 'Your spending import is done',
        body: 'Added 3 expenses to Spending. Skipped 1 duplicate and 2 rows with problems.',
        data: {
          kind: 'spending',
          reason: 'import',
          babyId,
          importId: im(1),
          route: `/utilities/spending/import/${im(1)}`,
        },
      },
    ]);

    // Not queued any more: the trigger firing again does nothing.
    expect((await runSpendingImport(runDeps(), babyId, im(1), later)).ran).toBe(false);

    // A retry after a crash: one expense missing, the import queued again.
    await db.doc(`babies/${babyId}/expenses/${importedExpenseId(im(1), 4)}`).delete();
    await db.doc(`babies/${babyId}/spendingImports/${im(1)}`).update({ status: 'queued' });
    expect(await runSpendingImport(runDeps(), babyId, im(1), later)).toMatchObject({
      imported: 3,
    });
    expect(await liveImported(im(1))).toHaveLength(3);
    expect((await importDoc(im(1))).counts.duplicates).toBe(1);
    expect((await db.collection(`families/${familyId}/spendingCategories`).get()).size).toBe(2);
    expect((await db.collection('mail').get()).size).toBe(1);

    // Undo (edited items too), once.
    await db
      .doc(`babies/${babyId}/expenses/${importedExpenseId(im(1), 2)}`)
      .update({ amount: 999_000 });
    expect(await reasonOf(undoSpendingImport(db, 'gma', { babyId, importId: im(1) }, later))).toBe(
      'not-co-parent',
    );
    expect(await undoSpendingImport(db, 'mom', { babyId, importId: im(1) }, later)).toEqual({
      removed: 3,
    });
    const undone = await liveImported(im(1));
    expect(undone.every((x) => x.get('deleted') === true && x.get('deletedBy') === 'mom')).toBe(
      true,
    );
    expect((await importDoc(im(1))).status).toBe('undone');
    // The diapers already in Chi tiêu stay.
    expect(
      (await db.doc(`babies/${babyId}/expenses/x_${'d'.repeat(32)}`).get()).get('deleted'),
    ).toBe(false);
    expect(await reasonOf(undoSpendingImport(db, 'mom', { babyId, importId: im(1) }, later))).toBe(
      'wrong-state',
    );
  });

  it('undo closes after 7 days; "Nhắc việc" off means no push', async () => {
    await db.doc('users/mom/settings/notifications').set({ reminders: false });
    await confirmSpendingImport(db, 'mom', confirmReq(), now);
    await runSpendingImport(runDeps(), babyId, im(1), now);
    expect(pushes).toEqual([]);
    expect((await db.doc(`mail/spimport_${im(1)}_done`).get()).get('locale')).toBe('vi');
    const late = new Date(now.getTime() + 7 * 86_400_000);
    expect(await reasonOf(undoSpendingImport(db, 'mom', { babyId, importId: im(1) }, late))).toBe(
      'undo-expired',
    );
  });

  it('a failed import says so (a reason code only) and mails the failure', async () => {
    await confirmSpendingImport(db, 'mom', confirmReq(), now);
    store.files.clear();
    const result = await runSpendingImport(runDeps(), babyId, im(1), now);
    expect(result).toEqual({ ran: true, imported: 0, failure: 'no-upload' });
    expect(await importDoc(im(1))).toMatchObject({
      status: 'failed',
      failure: 'no-upload',
      undoUntil: null,
    });
    expect((await db.doc(`mail/spimport_${im(1)}_failed`).get()).get('template')).toBe(
      'spendingImportFailed',
    );
    expect(pushes.map((p) => [p.title, p.body])).toEqual([
      ['Chưa nhập được chi tiêu', 'Mở app để thử lại.'],
    ]);
  });
});

describe('daily cleanup', () => {
  it('deletes old uploads and expires imports left waiting, without mail', async () => {
    const old = new Date(now.getTime() - 8 * 86_400_000);
    store.put(`imports/mom/${im(1)}.json`, moneyLover, old);
    store.put(`imports/mom/${im(1)}/0.jpg`, Buffer.from([1]), old);
    store.put(`imports/mom/${im(2)}.json`, moneyLover, now);
    await analyzeSpendingImport(deps(), 'mom', { babyId, importId: im(2), kind: 'file' }, old);
    store.put(`imports/mom/${im(3)}.json`, moneyLover, now);
    await analyzeSpendingImport(deps(), 'mom', { babyId, importId: im(3), kind: 'file' }, now);

    expect(await cleanupSpendingImports(db, store, now)).toEqual({ files: 2, expired: 1 });
    expect([...store.files.keys()]).toEqual([
      `imports/mom/${im(2)}.json`,
      `imports/mom/${im(3)}.json`,
    ]);
    expect(await importDoc(im(2))).toMatchObject({ status: 'failed', failure: 'expired' });
    expect((await importDoc(im(3))).status).toBe('ready');
    expect((await db.collection('mail').get()).size).toBe(0);
    expect(await cleanupSpendingImports(db, store, now)).toEqual({ files: 0, expired: 0 });
  });
});
