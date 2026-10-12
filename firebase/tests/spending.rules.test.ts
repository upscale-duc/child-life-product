import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
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
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// Chi tiêu (Figma v1.1 8a–8o, D-055 … D-057, P-140): Cùng nuôi see and change everything;
// "Ghi khoản đã chi" records and sees one's own; "Xem toàn bộ chi tiêu" reads all; recurring
// occurrences are server-only; categories are the family's.
const projectId = 'demo-child-life-spending';
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
  extraRights: null,
  ...extra,
});
const author = (uid: string) => ({
  name: uid,
  relation: relations[uid] ?? 'other',
  relationCustom: null,
});
const id = (n: number, prefix = 'x_') => `${prefix}${String(n).padStart(32, '0')}`;

function expense(uid: string, over: Record<string, unknown> = {}) {
  return {
    amount: 1_020_000,
    categoryId: 'c_milk',
    note: 'Sữa công thức ×2',
    spentOn: '2026-10-12',
    payer: { uid: 'mom', name: 'mom', relation: 'mother', relationCustom: null },
    receiptPath: null,
    source: 'manual',
    sourceRef: null,
    createdBy: uid,
    author: author(uid),
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    updatedBy: uid,
    deleted: false,
    deletedAt: null,
    deletedBy: null,
    ...over,
  };
}

const budget = (uid: string, over: Record<string, unknown> = {}) => ({
  monthlyTotal: 8_000_000,
  caps: { c_childcare: 4_000_000 },
  alert80: true,
  updatedAt: serverTimestamp(),
  updatedBy: uid,
  ...over,
});

const recurring = (uid: string, over: Record<string, unknown> = {}) => ({
  title: 'Cô giữ trẻ',
  categoryId: 'c_childcare',
  amount: 2_000_000,
  payer: null,
  schedule: { kind: 'monthly', days: [1, 16] },
  enabled: true,
  createdBy: uid,
  author: author(uid),
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  updatedBy: uid,
  ...over,
});

const category = (uid: string, over: Record<string, unknown> = {}) => ({
  name: 'Bơi & vận động',
  icon: 'journal',
  tint: 'sunshine',
  order: 6,
  hidden: false,
  builtIn: false,
  updatedAt: serverTimestamp(),
  updatedBy: uid,
  ...over,
});

const as = (uid: string) => env.authenticatedContext(uid).firestore();
const custom = 'c_0123456789abcdef0123';

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: { rules: readFileSync(resolve(import.meta.dirname, '../firestore.rules'), 'utf8') },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'families/f1'), { ownerUid: 'mom', babyIds: ['b1'] });
    await setDoc(doc(db, 'babies/b1'), { nickname: 'Teddy', ownerUid: 'mom', familyId: 'f1' });
    await setDoc(doc(db, 'babies/b1/members/mom'), member('mom', 'coParent', { isOwner: true }));
    await setDoc(doc(db, 'babies/b1/members/dad'), member('dad', 'coParent'));
    // A caregiver who may record (8l "Ghi khoản đã chi"), one with no right.
    await setDoc(
      doc(db, 'babies/b1/members/grandma'),
      member('grandma', 'caregiver', {
        extraRights: {
          viewBabyInfo: false,
          viewDailyCare: false,
          recordSpending: true,
          viewSpending: false,
        },
      }),
    );
    await setDoc(doc(db, 'babies/b1/members/nanny'), member('nanny', 'caregiver'));
    // A relative who may see everything (8l "Xem toàn bộ chi tiêu").
    await setDoc(
      doc(db, 'babies/b1/members/aunt'),
      member('aunt', 'relative', {
        extraRights: { viewBabyInfo: false, viewDailyCare: false, viewSpending: true },
      }),
    );
    const at = { createdAt: new Date(), updatedAt: new Date() };
    await setDoc(doc(db, `babies/b1/expenses/${id(1)}`), { ...expense('dad'), ...at });
    await setDoc(doc(db, `babies/b1/expenses/${id(2)}`), { ...expense('grandma'), ...at });
    await setDoc(doc(db, 'babies/b1/spending/budget'), {
      ...budget('mom'),
      updatedAt: new Date(),
      alertedMonth: '2026-10',
    });
    await setDoc(doc(db, `babies/b1/recurringExpenses/${id(1, 'rx_')}`), {
      ...recurring('mom'),
      ...at,
    });
    await setDoc(doc(db, 'families/f1/spendingCategories/c_milk'), {
      ...category('mom', { name: null, icon: 'feed', tint: 'bottle', order: 1, builtIn: true }),
      updatedAt: new Date(),
    });
  });
});

describe('expenses', () => {
  it('Cùng nuôi record, read and edit any item', async () => {
    await assertSucceeds(setDoc(doc(as('mom'), `babies/b1/expenses/${id(9)}`), expense('mom')));
    await assertSucceeds(getDoc(doc(as('mom'), `babies/b1/expenses/${id(2)}`)));
    await assertSucceeds(
      updateDoc(doc(as('mom'), `babies/b1/expenses/${id(2)}`), {
        amount: 990_000,
        updatedAt: serverTimestamp(),
        updatedBy: 'mom',
      }),
    );
  });

  it('"Ghi khoản đã chi" records and sees only their own', async () => {
    await assertSucceeds(
      setDoc(doc(as('grandma'), `babies/b1/expenses/${id(9)}`), expense('grandma')),
    );
    await assertSucceeds(getDoc(doc(as('grandma'), `babies/b1/expenses/${id(2)}`)));
    await assertFails(getDoc(doc(as('grandma'), `babies/b1/expenses/${id(1)}`)));
    await assertSucceeds(
      getDocs(
        query(collection(as('grandma'), 'babies/b1/expenses'), where('createdBy', '==', 'grandma')),
      ),
    );
    await assertFails(getDocs(collection(as('grandma'), 'babies/b1/expenses')));
    await assertFails(
      updateDoc(doc(as('grandma'), `babies/b1/expenses/${id(1)}`), {
        amount: 1,
        updatedAt: serverTimestamp(),
        updatedBy: 'grandma',
      }),
    );
    // No totals: the budget and the recurring list are not theirs to read.
    await assertFails(getDoc(doc(as('grandma'), 'babies/b1/spending/budget')));
  });

  it('"Xem toàn bộ chi tiêu" reads everything and writes nothing; no right, nothing', async () => {
    await assertSucceeds(getDocs(collection(as('aunt'), 'babies/b1/expenses')));
    await assertSucceeds(getDoc(doc(as('aunt'), 'babies/b1/spending/budget')));
    await assertFails(setDoc(doc(as('aunt'), `babies/b1/expenses/${id(9)}`), expense('aunt')));
    await assertFails(getDoc(doc(as('nanny'), `babies/b1/expenses/${id(1)}`)));
    await assertFails(setDoc(doc(as('nanny'), `babies/b1/expenses/${id(9)}`), expense('nanny')));
  });

  it('shape: whole VND, own author, client id, no recurring source, no hard delete', async () => {
    const at = (n: number) => doc(as('mom'), `babies/b1/expenses/${id(n)}`);
    await assertFails(setDoc(at(10), expense('mom', { amount: 10.5 })));
    await assertFails(setDoc(at(11), expense('mom', { amount: 0 })));
    await assertFails(setDoc(at(12), expense('mom', { author: author('dad') })));
    await assertFails(setDoc(at(13), expense('mom', { source: 'recurring', sourceRef: 'rx' })));
    await assertFails(setDoc(at(14), expense('mom', { note: 'x'.repeat(81) })));
    await assertFails(setDoc(doc(as('mom'), 'babies/b1/expenses/not-an-id'), expense('mom')));
    await assertSucceeds(
      setDoc(at(15), expense('mom', { source: 'vaccine', sourceRef: 'hexa6_2' })),
    );
    await assertFails(deleteDoc(doc(as('mom'), `babies/b1/expenses/${id(1)}`)));
  });

  it('soft delete records who and when; the origin never changes', async () => {
    await assertSucceeds(
      updateDoc(doc(as('mom'), `babies/b1/expenses/${id(1)}`), {
        deleted: true,
        deletedAt: serverTimestamp(),
        deletedBy: 'mom',
        updatedAt: serverTimestamp(),
        updatedBy: 'mom',
      }),
    );
    await assertFails(
      updateDoc(doc(as('mom'), `babies/b1/expenses/${id(2)}`), {
        source: 'vaccine',
        updatedAt: serverTimestamp(),
        updatedBy: 'mom',
      }),
    );
  });
});

describe('budget and recurring items', () => {
  it("Cùng nuôi set the budget; the alert bookkeeping stays the server's", async () => {
    await assertSucceeds(
      setDoc(
        doc(as('dad'), 'babies/b1/spending/budget'),
        budget('dad', { alertedMonth: '2026-10' }),
      ),
    );
    await assertFails(
      setDoc(
        doc(as('dad'), 'babies/b1/spending/budget'),
        budget('dad', { alertedMonth: '2026-11' }),
      ),
    );
    await assertFails(setDoc(doc(as('aunt'), 'babies/b1/spending/budget'), budget('aunt')));
  });

  it('Cùng nuôi manage recurring items; others read with the view right only', async () => {
    await assertSucceeds(
      setDoc(doc(as('mom'), `babies/b1/recurringExpenses/${id(2, 'rx_')}`), recurring('mom')),
    );
    await assertFails(
      setDoc(
        doc(as('mom'), `babies/b1/recurringExpenses/${id(3, 'rx_')}`),
        recurring('mom', { schedule: { kind: 'monthly', days: [] } }),
      ),
    );
    // 8c "Lặp lại hằng tháng": today's expense is recorded, so the job starts after it.
    await assertSucceeds(
      setDoc(
        doc(as('mom'), `babies/b1/recurringExpenses/${id(5, 'rx_')}`),
        recurring('mom', { lastOn: '2026-10-12' }),
      ),
    );
    await assertFails(
      setDoc(
        doc(as('mom'), `babies/b1/recurringExpenses/${id(6, 'rx_')}`),
        recurring('mom', { lastOn: 'soon' }),
      ),
    );
    await assertSucceeds(getDoc(doc(as('aunt'), `babies/b1/recurringExpenses/${id(1, 'rx_')}`)));
    await assertFails(getDoc(doc(as('grandma'), `babies/b1/recurringExpenses/${id(1, 'rx_')}`)));
    await assertFails(
      setDoc(
        doc(as('grandma'), `babies/b1/recurringExpenses/${id(4, 'rx_')}`),
        recurring('grandma'),
      ),
    );
    await assertSucceeds(deleteDoc(doc(as('mom'), `babies/b1/recurringExpenses/${id(1, 'rx_')}`)));
  });
});

describe("categories (the family's)", () => {
  it('Cùng nuôi add a custom one and seed a built-in; "Khác" never hides', async () => {
    await assertSucceeds(
      setDoc(doc(as('dad'), `families/f1/spendingCategories/${custom}`), category('dad')),
    );
    await assertSucceeds(
      setDoc(
        doc(as('dad'), 'families/f1/spendingCategories/c_other'),
        category('dad', { name: null, icon: 'grid', tint: 'sleep', builtIn: true }),
      ),
    );
    await assertFails(
      setDoc(
        doc(as('dad'), 'families/f1/spendingCategories/c_other'),
        category('dad', { name: null, icon: 'grid', tint: 'sleep', builtIn: true, hidden: true }),
      ),
    );
    // A custom id posing as a built-in, and a name over 24 characters.
    await assertFails(
      setDoc(
        doc(as('dad'), `families/f1/spendingCategories/${custom}`),
        category('dad', { builtIn: true }),
      ),
    );
    await assertFails(
      setDoc(
        doc(as('dad'), `families/f1/spendingCategories/${custom}`),
        category('dad', { name: 'x'.repeat(25) }),
      ),
    );
  });

  it('those with a spending right read them; only Cùng nuôi change them; no delete', async () => {
    await assertSucceeds(getDoc(doc(as('grandma'), 'families/f1/spendingCategories/c_milk')));
    await assertSucceeds(getDoc(doc(as('aunt'), 'families/f1/spendingCategories/c_milk')));
    await assertFails(getDoc(doc(as('nanny'), 'families/f1/spendingCategories/c_milk')));
    await assertFails(
      setDoc(doc(as('grandma'), `families/f1/spendingCategories/${custom}`), category('grandma')),
    );
    await assertFails(deleteDoc(doc(as('mom'), 'families/f1/spendingCategories/c_milk')));
  });
});
