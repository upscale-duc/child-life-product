import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { FamilyError, updateMember, type Caller } from '../functions/src/family.js';
import type { PushSender } from '../functions/src/social.js';
import {
  SpendingError,
  addRecurringExpenses,
  budgetAlertDue,
  deleteSpendingCategory,
  householdCurrency,
  occurrenceId,
  spendingBudgetAlert,
} from '../functions/src/spending.js';

// Chi tiêu server side (Figma v1.1 8a–8o; D-055 … D-057, P-140) against the Firestore emulator.
// Times are Hồ Chí Minh (UTC+7).
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const familyId = 'f_spend';
const b1 = 'b_5e000000000000000001';
const b2 = 'b_5e000000000000000002';
const vn = (d: string, h: number, m = 0) => {
  const [y, mo, day] = d.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(y, mo - 1, day, h - 7, m));
};
const now = vn('2026-10-16', 0, 30);
const mom: Caller = { uid: 'mom', anonymous: false, emailTrusted: true };

const sent: { tokens: string[]; title: string; body: string; data: Record<string, string> }[] = [];
const sender: PushSender = {
  async send(tokens, message) {
    sent.push({ tokens, title: message.title, body: message.body, data: message.data });
    return [];
  },
};

const author = { name: 'Mai', relation: 'mother', relationCustom: null };

async function reasonOf(promise: Promise<unknown>): Promise<string> {
  try {
    await promise;
  } catch (error) {
    if (error instanceof FamilyError || error instanceof SpendingError) return error.reason;
    throw error;
  }
  throw new Error('expected a FamilyError or SpendingError');
}

const member = (babyId: string, uid: string, role: string, extra: object = {}) =>
  db.doc(`babies/${babyId}/members/${uid}`).set({
    uid,
    babyId,
    role,
    isOwner: uid === 'mom',
    relation: role === 'caregiver' ? 'nanny' : 'grandmother',
    relationCustom: null,
    displayName: uid,
    status: 'active',
    extraRights: null,
    ...extra,
  });

const expense = (babyId: string, id: string, data: object) =>
  db.doc(`babies/${babyId}/expenses/${id}`).set({
    amount: 100_000,
    categoryId: 'c_milk',
    note: '',
    spentOn: '2026-10-05',
    payer: null,
    receiptPath: null,
    source: 'manual',
    sourceRef: null,
    createdBy: 'mom',
    author,
    createdAt: now,
    updatedAt: now,
    updatedBy: 'mom',
    deleted: false,
    deletedAt: null,
    deletedBy: null,
    ...data,
  });

const recurring = (babyId: string, id: string, data: object) =>
  db.doc(`babies/${babyId}/recurringExpenses/${id}`).set({
    title: 'Cô giữ trẻ',
    categoryId: 'c_childcare',
    amount: 2_000_000,
    payer: { uid: 'mom', ...author },
    schedule: { kind: 'monthly', days: [1, 15] },
    enabled: true,
    createdBy: 'mom',
    author,
    createdAt: vn('2026-09-20', 9),
    updatedAt: vn('2026-09-20', 9),
    updatedBy: 'mom',
    ...data,
  });

const rx = (n: number) => `rx_${String(n).padStart(32, '0')}`;
const xid = (n: number) => `x_${String(n).padStart(32, '0')}`;

beforeAll(() => {
  app = initializeApp({ projectId }, `spending-${randomUUID()}`);
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
  sent.length = 0;
  await db.doc(`families/${familyId}`).set({ ownerUid: 'mom', babyIds: [b1, b2] });
  for (const b of [b1, b2]) {
    await db.doc(`babies/${b}`).set({
      familyId,
      ownerUid: 'mom',
      state: 'active',
      timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' },
    });
    await member(b, 'mom', 'coParent');
  }
  await member(b1, 'dad', 'coParent');
  await member(b1, 'nanny', 'caregiver');
  await member(b1, 'aunt', 'relative', {
    extraRights: { viewBabyInfo: true, viewDailyCare: true },
  });
  for (const uid of ['mom', 'dad', 'nanny', 'aunt']) {
    await db
      .doc(`users/${uid}/devices/d_${uid}`)
      .set({ token: `t-${uid}`, language: uid === 'dad' ? 'en' : 'vi' });
  }
});

describe('member rights (8l, D-055)', () => {
  it('a caregiver may record and view spending', async () => {
    await updateMember(
      db,
      mom,
      {
        babyId: b1,
        uid: 'nanny',
        extraRights: {
          viewBabyInfo: false,
          viewDailyCare: false,
          recordSpending: true,
          viewSpending: true,
        },
      },
      now,
    );
    expect((await db.doc(`babies/${b1}/members/nanny`).get()).get('extraRights')).toEqual({
      viewBabyInfo: false,
      viewDailyCare: false,
      recordSpending: true,
      viewSpending: true,
    });
  });

  it('a caregiver never gets baby info or daily care; co-parents never carry rights', async () => {
    expect(
      await reasonOf(
        updateMember(
          db,
          mom,
          {
            babyId: b1,
            uid: 'nanny',
            extraRights: { viewBabyInfo: false, viewDailyCare: true, recordSpending: true },
          },
          now,
        ),
      ),
    ).toBe('extra-rights-relatives-only');
    expect(
      await reasonOf(
        updateMember(
          db,
          mom,
          {
            babyId: b1,
            uid: 'dad',
            extraRights: { viewBabyInfo: false, viewDailyCare: false, viewSpending: true },
          },
          now,
        ),
      ),
    ).toBe('extra-rights-relatives-only');
    expect((await db.doc(`babies/${b1}/members/nanny`).get()).get('extraRights')).toBeNull();
  });

  it('relatives keep all four (missing spending = false); a move to caregiver keeps spending only', async () => {
    await updateMember(db, mom, { babyId: b1, uid: 'aunt', relation: 'relative' }, now);
    expect((await db.doc(`babies/${b1}/members/aunt`).get()).get('extraRights')).toEqual({
      viewBabyInfo: true,
      viewDailyCare: true,
      recordSpending: false,
      viewSpending: false,
    });
    await updateMember(
      db,
      mom,
      {
        babyId: b1,
        uid: 'aunt',
        extraRights: { viewBabyInfo: true, viewDailyCare: true, viewSpending: true },
      },
      now,
    );
    await updateMember(db, mom, { babyId: b1, uid: 'aunt', role: 'caregiver' }, now);
    expect((await db.doc(`babies/${b1}/members/aunt`).get()).get('extraRights')).toEqual({
      viewBabyInfo: false,
      viewDailyCare: false,
      recordSpending: false,
      viewSpending: true,
    });
  });
});

describe('deleting a category (8o)', () => {
  beforeEach(async () => {
    await db.doc(`families/${familyId}/spendingCategories/c_school`).set({
      name: 'Học phí',
      icon: 'journal',
      tint: 'mint',
      order: 6,
      hidden: false,
      builtIn: false,
      updatedAt: now,
      updatedBy: 'mom',
    });
    await expense(b1, xid(1), { categoryId: 'c_school' });
    await expense(b1, xid(2), { categoryId: 'c_school', deleted: true, deletedAt: now });
    await expense(b1, xid(3), { categoryId: 'c_milk' });
    await expense(b2, xid(4), { categoryId: 'c_school' });
    await recurring(b2, rx(1), { categoryId: 'c_school' });
    await recurring(b1, rx(2), { categoryId: 'c_milk' });
    const budget = (caps: object) => ({
      monthlyTotal: 5_000_000,
      caps,
      alert80: true,
      updatedAt: now,
      updatedBy: 'mom',
    });
    await db
      .doc(`babies/${b1}/spending/budget`)
      .set(budget({ c_school: 500_000, c_other: 1_000_000 }));
    await db.doc(`babies/${b2}/spending/budget`).set(budget({ c_school: 200_000 }));
  });

  it('moves expenses (deleted too), recurring items and caps in every family baby', async () => {
    const { moved } = await deleteSpendingCategory(
      db,
      'mom',
      { babyId: b1, categoryId: 'c_school', moveTo: 'c_other' },
      now,
    );
    expect(moved).toBe(3);
    const cat = async (b: string, id: string) =>
      (await db.doc(`babies/${b}/expenses/${id}`).get()).get('categoryId');
    expect(await cat(b1, xid(1))).toBe('c_other');
    expect(await cat(b1, xid(2))).toBe('c_other');
    expect(await cat(b1, xid(3))).toBe('c_milk');
    expect(await cat(b2, xid(4))).toBe('c_other');
    expect((await db.doc(`babies/${b2}/recurringExpenses/${rx(1)}`).get()).get('categoryId')).toBe(
      'c_other',
    );
    expect((await db.doc(`babies/${b1}/recurringExpenses/${rx(2)}`).get()).get('categoryId')).toBe(
      'c_milk',
    );
    expect((await db.doc(`babies/${b1}/spending/budget`).get()).get('caps')).toEqual({
      c_other: 1_500_000,
    });
    expect((await db.doc(`babies/${b2}/spending/budget`).get()).get('caps')).toEqual({
      c_other: 200_000,
    });
    expect((await db.doc(`families/${familyId}/spendingCategories/c_school`).get()).exists).toBe(
      false,
    );
    const audit = await db
      .collection('audit')
      .where('action', '==', 'spending.category.delete')
      .get();
    expect(audit.docs[0]!.data()).toMatchObject({ category: 'spending', moved: 3, actor: 'mom' });
  });

  it('a built-in (not yet written) is hidden after the move', async () => {
    const { moved } = await deleteSpendingCategory(
      db,
      'mom',
      { babyId: b2, categoryId: 'c_milk', moveTo: 'c_school' },
      now,
    );
    expect(moved).toBe(1);
    expect((await db.doc(`babies/${b1}/expenses/${xid(3)}`).get()).get('categoryId')).toBe(
      'c_school',
    );
    expect(
      (await db.doc(`families/${familyId}/spendingCategories/c_milk`).get()).data(),
    ).toMatchObject({ hidden: true, builtIn: true, name: null, icon: 'feed', order: 1 });
  });

  it('refuses "Khác", the same category, unknown ones and anyone but Cùng nuôi', async () => {
    const del = (uid: string, categoryId: string, moveTo: string) =>
      reasonOf(deleteSpendingCategory(db, uid, { babyId: b1, categoryId, moveTo }, now));
    expect(await del('mom', 'c_other', 'c_milk')).toBe('category-locked');
    expect(await del('mom', 'c_school', 'c_school')).toBe('same-category');
    expect(await del('mom', 'c_nothere', 'c_other')).toBe('category-not-found');
    expect(await del('mom', 'c_school', 'c_nothere')).toBe('category-not-found');
    expect(await del('nanny', 'c_school', 'c_other')).toBe('not-co-parent');
    expect(await del('aunt', 'c_school', 'c_other')).toBe('not-co-parent');
    expect(await del('stranger', 'c_school', 'c_other')).toBe('not-a-member');
    expect((await db.doc(`babies/${b1}/expenses/${xid(1)}`).get()).get('categoryId')).toBe(
      'c_school',
    );
  });
});

describe('recurring items (8i, D-057)', () => {
  it('adds the due occurrences once, advances lastOn and pushes once to Cùng nuôi', async () => {
    // Twice a month, created 20/9: 1/10 and 15/10.
    await recurring(b1, rx(1), {});
    // Every 2 weeks from 1/10: 1/10 and 15/10.
    await recurring(b1, rx(2), {
      schedule: { kind: 'weeks', every: 2, startOn: '2026-10-01' },
      createdAt: vn('2026-10-01', 8),
    });
    // Yearly on 10/10, created in January: only 62 days back are caught up.
    await recurring(b1, rx(3), {
      schedule: { kind: 'yearly', month: 10, day: 10 },
      createdAt: vn('2026-01-05', 8),
    });
    // Paused: nothing added, lastOn still moves (resuming never adds the paused days).
    await recurring(b1, rx(4), { enabled: false });
    // A baby being deleted is left alone.
    await db.doc(`babies/${b2}`).update({ state: 'deleting' });
    await recurring(b2, rx(5), {});

    // The run is at 00:30: inside EN02 / EN07's default quiet hours (22:00–06:00) the push is
    // held and only the inbox row is written (D-076 #2), so these parents turned them off.
    for (const uid of ['mom', 'dad']) {
      await db.doc(`users/${uid}/settings/personalization`).set({ quietHours: null });
    }
    const first = await addRecurringExpenses(db, sender, now);
    expect(first).toMatchObject({ added: 5, babies: 1 });
    const spent = await db.collection(`babies/${b1}/expenses`).get();
    const by = (id: string) => spent.docs.filter((d) => d.get('sourceRef') === id);
    expect(
      by(rx(1))
        .map((d) => d.get('spentOn'))
        .sort(),
    ).toEqual(['2026-10-01', '2026-10-15']);
    expect(
      by(rx(2))
        .map((d) => d.get('spentOn'))
        .sort(),
    ).toEqual(['2026-10-01', '2026-10-15']);
    expect(by(rx(3)).map((d) => d.get('spentOn'))).toEqual(['2026-10-10']);
    expect(by(rx(4))).toHaveLength(0);
    const one = (
      await db.doc(`babies/${b1}/expenses/${occurrenceId(rx(1), '2026-10-15')}`).get()
    ).data()!;
    expect(one).toMatchObject({
      amount: 2_000_000,
      categoryId: 'c_childcare',
      note: 'Cô giữ trẻ',
      spentOn: '2026-10-15',
      payer: { uid: 'mom', ...author },
      receiptPath: null,
      source: 'recurring',
      sourceRef: rx(1),
      createdBy: 'mom',
      author,
      updatedBy: 'mom',
      deleted: false,
      deletedAt: null,
      deletedBy: null,
    });
    expect(occurrenceId(rx(1), '2026-10-15')).toMatch(/^x_[a-f0-9]{32}$/);
    for (const n of [1, 2, 3, 4]) {
      expect((await db.doc(`babies/${b1}/recurringExpenses/${rx(n)}`).get()).get('lastOn')).toBe(
        '2026-10-16',
      );
    }
    expect((await db.collection(`babies/${b2}/expenses`).get()).size).toBe(0);
    expect((await db.doc(`babies/${b2}/recurringExpenses/${rx(5)}`).get()).get('lastOn')).toBe(
      undefined,
    );

    // One push per baby, to Cùng nuôi only, with no baby name, title or amount (R-120).
    expect(sent.map((s) => s.tokens[0]).sort()).toEqual(['t-dad', 't-mom']);
    const vi = sent.find((s) => s.tokens[0] === 't-mom')!;
    expect(vi.title).toBe('Đã thêm 5 khoản định kỳ');
    expect(vi.body).toBe('Mở Chi tiêu để xem hoặc sửa.');
    expect(vi.data).toEqual({
      kind: 'spending',
      reason: 'recurring',
      babyId: b1,
      route: '/care/spending',
      // D-076 #2: the inbox row the push opens.
      inboxId: expect.stringMatching(/^n_sp-rx-/),
      // P-174: the semantic destination the app's resolver opens.
      destination: 'SPENDING',
    });
    expect(sent.find((s) => s.tokens[0] === 't-dad')!.title).toBe('5 recurring expenses added');

    // A second run the same day adds nothing.
    sent.length = 0;
    expect(await addRecurringExpenses(db, sender, vn('2026-10-16', 6))).toMatchObject({ added: 0 });
    expect(sent).toHaveLength(0);
    expect((await db.collection(`babies/${b1}/expenses`).get()).size).toBe(5);

    // Resumed: from the day after lastOn only (15/10, while paused, is not added).
    await db.doc(`babies/${b1}/recurringExpenses/${rx(4)}`).update({ enabled: true });
    const later = await addRecurringExpenses(db, sender, vn('2026-11-01', 0, 30));
    expect(later.added).toBe(3);
    const after = await db.collection(`babies/${b1}/expenses`).get();
    const days = (id: string) =>
      after.docs
        .filter((d) => d.get('sourceRef') === id)
        .map((d) => d.get('spentOn'))
        .sort();
    expect(days(rx(1))).toEqual(['2026-10-01', '2026-10-15', '2026-11-01']);
    expect(days(rx(2))).toEqual(['2026-10-01', '2026-10-15', '2026-10-29']);
    expect(days(rx(4))).toEqual(['2026-11-01']);
  });

  it('a retry after a crash (lastOn not moved) never doubles an occurrence', async () => {
    await recurring(b1, rx(1), {});
    await addRecurringExpenses(db, sender, now);
    await db.doc(`babies/${b1}/recurringExpenses/${rx(1)}`).update({ lastOn: null });
    expect((await addRecurringExpenses(db, sender, now)).added).toBe(0);
    expect((await db.collection(`babies/${b1}/expenses`).get()).size).toBe(2);
  });
});

describe('the 80 % budget push (8h)', () => {
  it('decides on the current month, once, from 80 %', () => {
    const budget = { monthlyTotal: 1_000_000, alert80: true, alertedMonth: null };
    const at = (total: number, b: object = budget, month = '2026-10') =>
      budgetAlertDue({ total, month, currentMonth: '2026-10', budget: { ...budget, ...b } });
    expect(at(799_999)).toBe(false);
    expect(at(800_000)).toBe(true);
    expect(at(900_000, { alertedMonth: '2026-10' })).toBe(false);
    expect(at(900_000, { alertedMonth: '2026-09' })).toBe(true);
    expect(at(900_000, { alert80: false })).toBe(false);
    expect(at(900_000, { monthlyTotal: null })).toBe(false);
    expect(at(900_000, {}, '2026-09')).toBe(false);
    expect(
      budgetAlertDue({ total: 1, month: '2026-10', currentMonth: '2026-10', budget: null }),
    ).toBe(false);
  });

  it('sets alertedMonth once and pushes Cùng nuôi when the month reaches 80 %', async () => {
    const at = vn('2026-10-20', 10);
    await db.doc(`babies/${b1}/spending/budget`).set({
      monthlyTotal: 1_000_000,
      caps: {},
      alert80: true,
      updatedAt: at,
      updatedBy: 'mom',
    });
    const write = async (id: string, data: object) => {
      const ref = db.doc(`babies/${b1}/expenses/${id}`);
      const before = await ref.get();
      await expense(b1, id, data);
      return spendingBudgetAlert(db, sender, b1, before, await ref.get(), at);
    };
    // An old month never alerts, however large.
    expect((await write(xid(1), { amount: 5_000_000, spentOn: '2026-09-30' })).alerted).toBe(false);
    // A deleted item does not count.
    await expense(b1, xid(2), { amount: 600_000, deleted: true, deletedAt: at });
    expect((await write(xid(3), { amount: 700_000 })).alerted).toBe(false);
    const { alerted, sent: pushed } = await write(xid(4), { amount: 100_000 });
    expect(alerted).toBe(true);
    expect(pushed).toBe(2);
    expect((await db.doc(`babies/${b1}/spending/budget`).get()).get('alertedMonth')).toBe(
      '2026-10',
    );
    const vi = sent.find((s) => s.tokens[0] === 't-mom')!;
    expect(vi).toMatchObject({
      title: 'Chi tiêu đã dùng 80% ngân sách tháng',
      body: 'Mở Chi tiêu để xem chi tiết.',
      data: { kind: 'spending', reason: 'budget', babyId: b1, month: '2026-10' },
    });
    expect(sent.map((s) => s.tokens[0]).sort()).toEqual(['t-dad', 't-mom']);
    // Once a month.
    expect((await write(xid(5), { amount: 300_000 })).alerted).toBe(false);
  });

  it('honours "Nhắc việc" off and alert80 off', async () => {
    await db.doc('users/dad/settings/notifications').set({ reminders: false });
    const at = vn('2026-10-20', 10);
    await db.doc(`babies/${b1}/spending/budget`).set({
      monthlyTotal: 100_000,
      caps: {},
      alert80: false,
      updatedAt: at,
      updatedBy: 'mom',
    });
    const ref = db.doc(`babies/${b1}/expenses/${xid(1)}`);
    await expense(b1, xid(1), { amount: 100_000 });
    expect((await spendingBudgetAlert(db, sender, b1, null, await ref.get(), at)).alerted).toBe(
      false,
    );
    await db.doc(`babies/${b1}/spending/budget`).update({ alert80: true });
    expect(await spendingBudgetAlert(db, sender, b1, null, await ref.get(), at)).toEqual({
      alerted: true,
      sent: 1,
    });
    expect(sent.map((s) => s.tokens[0])).toEqual(['t-mom']);
  });
});

// ---- Chi tiêu currencies (D-075 #4) ----
describe('currencies (D-075 #4)', () => {
  it("recurring occurrences carry their item's currency; an old item writes VND", async () => {
    await recurring(b1, rx(1), { amount: 150_000, currency: 'USD' });
    await recurring(b1, rx(2), {});
    await addRecurringExpenses(db, sender, now);
    const spent = await db.collection(`babies/${b1}/expenses`).get();
    const of = (id: string) => spent.docs.filter((d) => d.get('sourceRef') === id);
    expect(of(rx(1)).map((d) => [d.get('amount'), d.get('currency')])).toEqual([
      [150_000, 'USD'],
      [150_000, 'USD'],
    ]);
    expect(of(rx(2)).every((d) => d.get('currency') === 'VND')).toBe(true);
  });

  it('the 80 % push counts the budget currency only', async () => {
    const at = vn('2026-10-20', 10);
    await db.doc(`babies/${b1}/spending/budget`).set({
      monthlyTotal: 100_000,
      caps: {},
      alert80: true,
      currency: 'USD',
      updatedAt: at,
      updatedBy: 'mom',
    });
    const write = async (id: string, data: object) => {
      const ref = db.doc(`babies/${b1}/expenses/${id}`);
      const before = await ref.get();
      await expense(b1, id, { spentOn: '2026-10-19', ...data });
      return spendingBudgetAlert(db, sender, b1, before, await ref.get(), at);
    };
    // 5 000 000 đ never counts against a USD budget (nor an old document without a currency).
    expect((await write(xid(1), { amount: 5_000_000, currency: 'VND' })).alerted).toBe(false);
    expect((await write(xid(2), { amount: 5_000_000 })).alerted).toBe(false);
    expect((await write(xid(3), { amount: 50_000, currency: 'USD' })).alerted).toBe(false);
    expect((await write(xid(4), { amount: 30_000, currency: 'USD' })).alerted).toBe(true);
    expect((await db.doc(`babies/${b1}/spending/budget`).get()).get('alertedMonth')).toBe(
      '2026-10',
    );
  });

  it('a budget without a currency (old) counts VND only', async () => {
    const at = vn('2026-10-20', 10);
    await db.doc(`babies/${b1}/spending/budget`).set({
      monthlyTotal: 1_000_000,
      caps: {},
      alert80: true,
      updatedAt: at,
      updatedBy: 'mom',
    });
    const ref = db.doc(`babies/${b1}/expenses/${xid(1)}`);
    await expense(b1, xid(1), { amount: 90_000_000, currency: 'KRW', spentOn: '2026-10-19' });
    expect((await spendingBudgetAlert(db, sender, b1, null, await ref.get(), at)).alerted).toBe(
      false,
    );
    const ref2 = db.doc(`babies/${b1}/expenses/${xid(2)}`);
    await expense(b1, xid(2), { amount: 800_000, spentOn: '2026-10-19' });
    expect((await spendingBudgetAlert(db, sender, b1, null, await ref2.get(), at)).alerted).toBe(
      true,
    );
  });

  it("the household's currency: the setting, else the country's, else VND", async () => {
    expect(await householdCurrency(db, familyId)).toBe('VND');
    await db.doc(`families/${familyId}`).update({ country: 'AU' });
    expect(await householdCurrency(db, familyId)).toBe('AUD');
    await db
      .doc(`families/${familyId}/spendingSettings/main`)
      .set({ currency: 'EUR', updatedAt: now, updatedBy: 'mom' });
    expect(await householdCurrency(db, familyId)).toBe('EUR');
  });

  it("deleting a category caps the merged cap at the budget currency's ceiling", async () => {
    await db.doc(`babies/${b1}/spending/budget`).set({
      monthlyTotal: null,
      caps: { [`c_${'a'.repeat(20)}`]: 90_000_000, c_milk: 50_000_000 },
      alert80: false,
      currency: 'USD',
      updatedAt: now,
      updatedBy: 'mom',
    });
    await db
      .doc(`families/${familyId}/spendingCategories/c_${'a'.repeat(20)}`)
      .set({ name: 'Bơi', icon: 'drop', tint: 'mint', order: 7, hidden: false, builtIn: false });
    await deleteSpendingCategory(
      db,
      'mom',
      { babyId: b1, categoryId: `c_${'a'.repeat(20)}`, moveTo: 'c_milk' },
      now,
    );
    expect((await db.doc(`babies/${b1}/spending/budget`).get()).get('caps')).toEqual({
      c_milk: 100_000_000,
    });
  });
});
// ---- end Chi tiêu currencies ----
