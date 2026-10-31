import { createHash } from 'node:crypto';
import {
  amountMaxFor,
  builtInCategories,
  currencyForCountry,
  currencyOfDoc,
  deleteSpendingCategoryRequestSchema,
  dueDatesBetween,
  isExpenseCurrency,
  localDateIn,
  otherCategoryId,
  recurringExpenseSchema,
  spendingLimits,
  type ExpenseCurrency,
  type NotificationTemplateId,
  type PlaceholderValue,
} from '@child-life/contracts';
import {
  FieldPath,
  FieldValue,
  type DocumentReference,
  type DocumentSnapshot,
  type Firestore,
  type Timestamp,
  type WriteBatch,
} from 'firebase-admin/firestore';
import { isActiveMember } from './family.js';
import { notifyUsers } from './notifications.js';
import type { PushSender } from './social.js';

/**
 * Chi tiêu (Figma v1.1 8a–8o; D-055 … D-057, P-140; plan `docs/product/spending-plan.md`).
 * Expenses are written by the app; this file holds what Rules cannot do: moving a deleted
 * category's expenses across the family's babies (8o), adding recurring occurrences on their due
 * day (D-057) and the 80 % budget push (8h). Amounts, descriptions, titles and the baby's name are
 * never logged nor put in a push (R-120, P-140).
 */

export class SpendingError extends Error {
  constructor(
    readonly code:
      | 'invalid-argument'
      | 'failed-precondition'
      | 'permission-denied'
      | 'not-found'
      | 'unavailable',
    readonly reason: string,
  ) {
    super(reason);
  }
}

const DEFAULT_ZONE = 'Asia/Ho_Chi_Minh';
/** Firestore allows 500 writes per batch; keep a margin. */
const BATCH_MAX = 450;
/** The daily job never adds more than this far back (a long-paused job, an old lastOn). */
const CATCH_UP_DAYS = 62;
/** Where a spending push opens (the app registers the route). */
export const spendingRoute = '/care/spending';

const builtInIds = new Set<string>(builtInCategories.map((c) => c.id));
const zoneOf = (baby: DocumentSnapshot) =>
  (baby.get('timeZone.zone') as string | undefined) ?? DEFAULT_ZONE;
const babyActive = (baby: DocumentSnapshot) =>
  baby.exists && ((baby.get('state') as string | undefined) ?? 'active') === 'active';

function addDays(date: string, n: number): string {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(y, m - 1, d + n)).toISOString().slice(0, 10);
}

/** Commits writes in batches of at most [BATCH_MAX]. */
class Batcher {
  private batch: WriteBatch;
  private size = 0;
  constructor(private readonly db: Firestore) {
    this.batch = db.batch();
  }
  async add(write: (b: WriteBatch) => void) {
    write(this.batch);
    this.size += 1;
    if (this.size >= BATCH_MAX) await this.flush();
  }
  async flush() {
    if (this.size === 0) return;
    await this.batch.commit();
    this.batch = this.db.batch();
    this.size = 0;
  }
}

// ---------- 8o: delete a category, moving what used it ----------

/**
 * Moves every expense (soft-deleted ones too), recurring item and budget cap of [categoryId] to
 * [moveTo] in all the family's babies, then deletes the category (custom) or hides it (built-in).
 * Only a Cùng nuôi of the baby (P-140); "Khác" cannot be deleted (8m). Re-running after a partial
 * failure finishes the move (each step is idempotent).
 */
export async function deleteSpendingCategory(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ moved: number }> {
  const parsed = deleteSpendingCategoryRequestSchema.safeParse(data);
  if (!parsed.success) throw new SpendingError('invalid-argument', 'malformed');
  const { babyId, categoryId, moveTo } = parsed.data;
  if (categoryId === otherCategoryId)
    throw new SpendingError('failed-precondition', 'category-locked');
  if (categoryId === moveTo) throw new SpendingError('invalid-argument', 'same-category');

  const member = await db.doc(`babies/${babyId}/members/${uid}`).get();
  if (!isActiveMember(member, now)) throw new SpendingError('permission-denied', 'not-a-member');
  if (member.get('role') !== 'coParent')
    throw new SpendingError('permission-denied', 'not-co-parent');
  const baby = await db.doc(`babies/${babyId}`).get();
  if (!babyActive(baby)) throw new SpendingError('failed-precondition', 'baby-closed');
  const familyId = baby.get('familyId') as string | undefined;
  if (!familyId) throw new SpendingError('not-found', 'not-found');
  const family = await db.doc(`families/${familyId}`).get();
  const babyIds = (family.get('babyIds') as string[] | undefined) ?? [];

  const categories = db.collection(`families/${familyId}/spendingCategories`);
  const [from, to] = await db.getAll(categories.doc(categoryId), categories.doc(moveTo));
  // Built-ins exist before a Cùng nuôi first edits them (shown until written, P-140).
  if (!from!.exists && !builtInIds.has(categoryId))
    throw new SpendingError('not-found', 'category-not-found');
  if (!to!.exists && !builtInIds.has(moveTo))
    throw new SpendingError('not-found', 'category-not-found');

  const batcher = new Batcher(db);
  let moved = 0;
  for (const id of babyIds) {
    const babyRef = db.doc(`babies/${id}`);
    const expenses = await babyRef
      .collection('expenses')
      .where('categoryId', '==', categoryId)
      .get();
    for (const doc of expenses.docs) {
      await batcher.add((b) => b.update(doc.ref, { categoryId: moveTo }));
      moved += 1;
    }
    const recurring = await babyRef
      .collection('recurringExpenses')
      .where('categoryId', '==', categoryId)
      .get();
    for (const doc of recurring.docs) {
      await batcher.add((b) => b.update(doc.ref, { categoryId: moveTo }));
    }
    const budget = await babyRef.collection('spending').doc('budget').get();
    const caps = (budget.get('caps') as Record<string, number> | undefined) ?? {};
    const cap = caps[categoryId];
    if (budget.exists && typeof cap === 'number') {
      const merged = Math.min(
        (caps[moveTo] ?? 0) + cap,
        amountMaxFor(currencyOfDoc(budget.get('currency'))),
      );
      // One update per baby: the cap moves atomically, so a retry never adds it twice.
      await batcher.add((b) =>
        b.update(
          budget.ref,
          new FieldPath('caps', moveTo),
          merged,
          new FieldPath('caps', categoryId),
          FieldValue.delete(),
        ),
      );
    }
  }
  await batcher.flush();

  if (builtInIds.has(categoryId)) {
    // A built-in "deleted" after the move is hidden (it can be shown again, 8m).
    const index = builtInCategories.findIndex((c) => c.id === categoryId);
    const def = builtInCategories[index]!;
    await from!.ref.set(
      from!.exists
        ? { hidden: true, updatedAt: now, updatedBy: uid }
        : {
            name: null,
            icon: def.icon,
            tint: def.tint,
            order: index,
            hidden: true,
            builtIn: true,
            updatedAt: now,
            updatedBy: uid,
          },
      { merge: true },
    );
  } else {
    await from!.ref.delete();
  }
  await db.collection('audit').doc().create({
    action: 'spending.category.delete',
    actor: uid,
    babyId,
    familyId,
    categoryId,
    moveTo,
    moved,
    category: 'spending',
    at: now,
  });
  return { moved };
}

// ---------- Currencies (D-075 #4) ----------

/**
 * The household's currency: `families/{f}/spendingSettings/main`, else the family's country's
 * currency, else VND. Rows of an import that name no currency are read in it.
 */
export async function householdCurrency(db: Firestore, familyId: string): Promise<ExpenseCurrency> {
  const [settings, family] = await db.getAll(
    db.doc(`families/${familyId}/spendingSettings/main`),
    db.doc(`families/${familyId}`),
  );
  const chosen = settings?.get('currency') as unknown;
  if (isExpenseCurrency(chosen)) return chosen;
  return currencyForCountry(family?.get('country') as string | null | undefined);
}

// ---------- 8i: recurring occurrences (D-057) ----------

/** `x_` + 32 hex: one occurrence per (item, day), so a retry never doubles it. */
export function occurrenceId(recurringId: string, date: string): string {
  return `x_${createHash('sha256').update(`${recurringId}:${date}`).digest('hex').slice(0, 32)}`;
}

/**
 * The day after which occurrences are due: the last run (`lastOn`), else the day before the item
 * was created (so the creation day itself counts), and never more than [CATCH_UP_DAYS] back.
 */
export function catchUpAfter(lastOn: string | null, createdOn: string, today: string): string {
  const after = lastOn ?? addDays(createdOn, -1);
  const floor = addDays(today, -CATCH_UP_DAYS);
  return after < floor ? floor : after;
}

const recurringFields = recurringExpenseSchema.pick({
  title: true,
  categoryId: true,
  amount: true,
  currency: true,
  payer: true,
  schedule: true,
  createdBy: true,
  author: true,
});

/**
 * Daily (00:30 Hồ Chí Minh): adds the due occurrences of every enabled recurring item in its baby's
 * zone and moves `lastOn` to today; a paused item only moves `lastOn`, so resuming never adds the
 * paused days. One push per baby that got something, to its Cùng nuôi.
 */
export async function addRecurringExpenses(
  db: Firestore,
  sender: PushSender | null,
  now: Date,
): Promise<{ added: number; babies: number; sent: number }> {
  const all = await db.collectionGroup('recurringExpenses').get();
  const byBaby = new Map<string, DocumentSnapshot[]>();
  for (const doc of all.docs) {
    const babyRef = doc.ref.parent.parent;
    if (!babyRef || babyRef.parent.id !== 'babies') continue;
    byBaby.set(babyRef.id, [...(byBaby.get(babyRef.id) ?? []), doc]);
  }
  let added = 0;
  let babies = 0;
  let sent = 0;
  for (const [babyId, items] of byBaby) {
    const baby = await db.doc(`babies/${babyId}`).get();
    if (!babyActive(baby)) continue;
    const zone = zoneOf(baby);
    const today = localDateIn(zone, now);
    let addedHere = 0;
    for (const item of items) {
      const lastOn = (item.get('lastOn') as string | null | undefined) ?? null;
      if (lastOn && lastOn >= today) continue;
      if (item.get('enabled') === true) {
        addedHere += await addOccurrences(db, babyId, item, zone, today, lastOn, now);
      }
      await item.ref.update({ lastOn: today });
    }
    if (addedHere > 0) {
      added += addedHere;
      babies += 1;
      sent += await pushParents(
        db,
        sender,
        babyId,
        now,
        (language) => ({
          ...recurringCopy(addedHere, language),
          data: { kind: 'spending', reason: 'recurring', babyId, route: spendingRoute },
          apns: { collapseId: `sp-rx-${babyId}-${today}`, threadId: `sp-${babyId}` },
        }),
        { template: { id: 'spending.recurring', values: { count: addedHere } } },
      );
    }
  }
  return { added, babies, sent };
}

async function addOccurrences(
  db: Firestore,
  babyId: string,
  item: DocumentSnapshot,
  zone: string,
  today: string,
  lastOn: string | null,
  now: Date,
): Promise<number> {
  const parsed = recurringFields.safeParse(item.data());
  if (!parsed.success) return 0;
  const r = parsed.data;
  // An amount over its currency's ceiling never becomes an expense (Rules would refuse it).
  if (r.amount > amountMaxFor(currencyOfDoc(r.currency))) return 0;
  const created = item.get('createdAt') as Timestamp | undefined;
  const createdOn = created ? localDateIn(zone, created.toDate()) : today;
  const dates = dueDatesBetween(r.schedule, catchUpAfter(lastOn, createdOn, today), today);
  let count = 0;
  for (const date of dates) {
    const ref = db.doc(`babies/${babyId}/expenses/${occurrenceId(item.id, date)}`);
    if (await createOnce(ref, occurrence(item.id, r, date, now))) count += 1;
  }
  return count;
}

function occurrence(
  recurringId: string,
  r: ReturnType<typeof recurringFields.parse>,
  date: string,
  now: Date,
) {
  return {
    amount: r.amount,
    // The item's currency (D-075 #4); an item from before it is VND.
    currency: currencyOfDoc(r.currency),
    categoryId: r.categoryId,
    note: r.title.slice(0, spendingLimits.noteMax),
    spentOn: date,
    payer: r.payer,
    receiptPath: null,
    source: 'recurring',
    sourceRef: recurringId,
    createdBy: r.createdBy,
    author: r.author,
    createdAt: now,
    updatedAt: now,
    updatedBy: r.createdBy,
    deleted: false,
    deletedAt: null,
    deletedBy: null,
  };
}

/** `create()` that treats "already exists" (a retry, or the user deleted it) as done. */
async function createOnce(ref: DocumentReference, data: Record<string, unknown>) {
  try {
    await ref.create(data);
    return true;
  } catch (error) {
    if ((error as { code?: number }).code === 6) return false;
    throw error;
  }
}

/** Generic copy (R-120): no baby name, and no title or amount (user text and money, P-140). */
export function recurringCopy(count: number, language: string) {
  const en = language.startsWith('en');
  if (en) {
    return {
      title: count === 1 ? 'Recurring expense added' : `${count} recurring expenses added`,
      body: 'You can view or edit it in Spending any time.',
    };
  }
  return {
    title: count === 1 ? 'Đã thêm khoản chi định kỳ' : `Đã thêm ${count} khoản chi định kỳ`,
    body: 'Đã ghi vào Chi tiêu, bạn xem hoặc sửa lúc nào cũng được.',
  };
}

// ---------- 8h: the 80 % budget push ----------

export interface BudgetAlertInput {
  /** Non-deleted expenses of [month] in the budget's currency (D-075 #4: never mixed). */
  total: number;
  month: string;
  /** The current month in the baby's zone; older months never alert. */
  currentMonth: string;
  budget: { monthlyTotal?: number | null; alert80?: boolean; alertedMonth?: string | null } | null;
}

/** True when this month's spending first reaches 80 % of the standing monthly total (8h). */
export function budgetAlertDue({ total, month, currentMonth, budget }: BudgetAlertInput): boolean {
  if (!budget || budget.alert80 !== true) return false;
  if (month !== currentMonth || budget.alertedMonth === month) return false;
  const limit = budget.monthlyTotal ?? 0;
  return limit > 0 && total >= limit * spendingLimits.alertShare;
}

export function budgetCopy(language: string) {
  return language.startsWith('en')
    ? {
        title: 'This month’s spending reached 80% of the budget',
        body: 'Take a look at what’s been spent to plan the rest of the month.',
      }
    : {
        title: 'Chi tiêu tháng này đã tới 80% ngân sách',
        body: 'Xem lại các khoản đã chi để cân đối phần còn lại của tháng nhé.',
      };
}

/**
 * After an expense write: if its month is the current one and the month total first reaches 80 %
 * of the budget, marks `alertedMonth` (once, in a transaction) and pushes to the Cùng nuôi.
 */
export async function spendingBudgetAlert(
  db: Firestore,
  sender: PushSender | null,
  babyId: string,
  before: DocumentSnapshot | null,
  after: DocumentSnapshot | null,
  now: Date,
): Promise<{ alerted: boolean; sent: number }> {
  const none = { alerted: false, sent: 0 };
  // Only a write that can raise the total matters (soft deletes and lowered amounts cannot).
  if (!after?.exists || after.get('deleted') === true) return none;
  const amount = (after.get('amount') as number | undefined) ?? 0;
  const spentOn = after.get('spentOn') as string | undefined;
  if (!spentOn) return none;
  const currency = currencyOfDoc(after.get('currency'));
  if (
    before?.exists &&
    before.get('deleted') !== true &&
    before.get('spentOn') === spentOn &&
    currencyOfDoc(before.get('currency')) === currency &&
    ((before.get('amount') as number | undefined) ?? 0) >= amount
  ) {
    return none;
  }
  const babyRef = db.doc(`babies/${babyId}`);
  const baby = await babyRef.get();
  if (!babyActive(baby)) return none;
  const month = spentOn.slice(0, 7);
  const currentMonth = localDateIn(zoneOf(baby), now).slice(0, 7);
  const budgetRef = babyRef.collection('spending').doc('budget');
  const budget = await budgetRef.get();
  // The budget counts its own currency only (D-075 #4): another currency never raises it.
  const budgetCurrency = currencyOfDoc(budget.get('currency'));
  if (budget.exists && currency !== budgetCurrency) return none;
  const read = (b: DocumentSnapshot) =>
    b.exists
      ? {
          monthlyTotal: b.get('monthlyTotal') as number | null,
          alert80: b.get('alert80') as boolean,
          alertedMonth: (b.get('alertedMonth') as string | null | undefined) ?? null,
        }
      : null;
  // Cheap checks first: everything but the total.
  if (
    !budgetAlertDue({ total: Number.MAX_SAFE_INTEGER, month, currentMonth, budget: read(budget) })
  )
    return none;
  const total = await monthTotal(babyRef, month, budgetCurrency);
  if (!budgetAlertDue({ total, month, currentMonth, budget: read(budget) })) return none;
  const claimed = await db.runTransaction(async (tx) => {
    const fresh = await tx.get(budgetRef);
    if (currencyOfDoc(fresh.get('currency')) !== budgetCurrency) return false;
    if (!budgetAlertDue({ total, month, currentMonth, budget: read(fresh) })) return false;
    tx.update(budgetRef, { alertedMonth: month });
    return true;
  });
  if (!claimed) return none;
  const sent = await pushParents(
    db,
    sender,
    babyId,
    now,
    (language) => ({
      ...budgetCopy(language),
      data: { kind: 'spending', reason: 'budget', babyId, month, route: spendingRoute },
      apns: { collapseId: `sp-budget-${babyId}-${month}`, threadId: `sp-${babyId}` },
    }),
    { template: { id: 'spending.budget80', values: {} } },
  );
  return { alerted: true, sent };
}

async function monthTotal(
  babyRef: DocumentReference,
  month: string,
  currency: ExpenseCurrency,
): Promise<number> {
  const docs = await babyRef
    .collection('expenses')
    .where('spentOn', '>=', `${month}-01`)
    .where('spentOn', '<=', `${month}-31`)
    .get();
  return docs.docs
    .filter((d) => d.get('deleted') !== true && currencyOfDoc(d.get('currency')) === currency)
    .reduce((sum, d) => sum + ((d.get('amount') as number | undefined) ?? 0), 0);
}

// ---------- Push ----------

export type PushMessage = Parameters<PushSender['send']>[1];

/** Sends to the baby's active Cùng nuôi (D-055: spending pushes are for parents). */
async function pushParents(
  db: Firestore,
  sender: PushSender | null,
  babyId: string,
  now: Date,
  message: (language: string) => PushMessage,
  extra: PushExtra = {},
): Promise<number> {
  const members = await db.collection(`babies/${babyId}/members`).get();
  const parents = members.docs
    .filter((m) => isActiveMember(m, now) && m.get('role') === 'coParent')
    .map((m) => m.id);
  return pushUsers(db, sender, parents, message, now, extra);
}

/** P-174: the Portal template of a spending push and, when the collapse id is not unique, its id. */
export interface PushExtra {
  template?: { id: NotificationTemplateId; values: Record<string, PlaceholderValue> };
  id?: string;
}

/**
 * Sends to [uids]' signed-in devices in each device's language through the notification centre
 * (D-076 #2): EN07 "Chi tiêu" (until set, the old "Nhắc việc" switch, G-056), quiet hours and the
 * inbox row. The notice id (the collapse id unless [extra.id]) is the dedup key: a retried run
 * finds the row and pushes nothing twice (P-174).
 */
export async function pushUsers(
  db: Firestore,
  sender: PushSender | null,
  uids: string[],
  message: (language: string) => PushMessage,
  now: Date = new Date(),
  extra: PushExtra = {},
): Promise<number> {
  const sample = message('vi');
  const babyId = sample.data.babyId ?? null;
  const zone = babyId
    ? ((await db.doc(`babies/${babyId}`).get()).get('timeZone.zone') as string | undefined)
    : undefined;
  const { sent } = await notifyUsers(
    db,
    sender,
    uids,
    {
      kind: 'spending',
      id: extra.id ?? sample.apns?.collapseId ?? `sp-${babyId ?? 'x'}-${now.getTime()}`,
      template: extra.template,
      babyId,
      data: sample.data,
      message: (language) => {
        const { title, body, apns, androidDraws } = message(language);
        return {
          title,
          body,
          ...(apns ? { apns } : {}),
          ...(androidDraws !== undefined ? { androidDraws } : {}),
        };
      },
      zone,
    },
    now,
  );
  return sent;
}
