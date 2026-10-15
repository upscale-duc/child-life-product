import {
  FieldValue,
  Timestamp,
  type DocumentReference,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import {
  addDaysIso,
  amountFits,
  assistantModuleProblems,
  builtInCategories,
  categoryIdSchema,
  currencyOfDoc,
  defaultReminderAllDayLeadMinutes,
  defaultReminderLeadMinutes,
  draftProblems,
  foldText,
  isExpenseCurrency,
  localDateIn,
  otherCategoryId,
  reminderAllDayDueAt,
  reminderAssigneeRoles,
  reminderLimits,
  reminderModuleTitleMax,
  reminderNeedsTime,
  spendingLimits,
  type DraftPayload,
  type DraftProblem,
  type ExpenseCurrency,
} from '@child-life/contracts';
import { draftRef, memberOf, taskRef, type ScopeMember } from './assistant-common.js';
import {
  attachmentRef,
  settleTaskAttachments,
  storedAttachment,
  validateImage,
  type AttachmentStore,
} from './assistant-attachments.js';
import {
  canRecordSpending,
  expenseIdForDraft,
  receiptPathFor,
  reminderIdForDraft,
} from './assistant-image-rules.js';
import { localInstant } from './assistant-tools.js';

/**
 * Child Life Assistant, slice A3 domain writers (P-156, P-157): a confirmed expense draft becomes
 * exactly the Chi tiêu document the app's form writes (`validNewExpense`: same keys, the
 * receipt's currency and its minor units (D-075 #4), the confirmer as author) with `source: 'assistant'` and `sourceRef` = the draft id; a confirmed
 * reminder draft becomes exactly the one-off reminder the app writes (`validNewReminder`: same
 * keys, Cùng nuôi only, a due time in the baby's zone, the module's default lead, no device;
 * D-075 #5: a date without a time is all day, lead "Đúng ngày", and the assignee the person
 * picked, re-checked here).
 * Reminders have no `source` field in their Rules key set, so none is added: provenance is the
 * execution row (`assistantExecutions`). Deterministic ids (`x_` / `rm_` + hash of the draft id)
 * make a replayed confirm adopt the record instead of writing it twice. Never logs a payload.
 */

type Author = { name: string; relation: string; relationCustom: string | null };

const authorOf = (m: Pick<ScopeMember, 'displayName' | 'relation' | 'relationCustom'>): Author => ({
  name: m.displayName,
  relation: m.relation,
  relationCustom: m.relationCustom,
});

/** `babies/{b}/expenses/{x}` with exactly the Rules' key set (`validNewExpense`). */
export function buildExpense<S>(
  x: {
    uid: string;
    author: Author;
    amount: number;
    /** D-075 #4: the expense's currency (`amount` in its minor units). */
    currency: ExpenseCurrency;
    categoryId: string;
    note: string;
    spentOn: string;
    payer: (Author & { uid: string }) | null;
    receiptPath: string | null;
    source?: string;
    sourceRef?: string | null;
  },
  serverTime: S,
) {
  return {
    amount: x.amount,
    currency: x.currency,
    categoryId: x.categoryId,
    note: x.note,
    spentOn: x.spentOn,
    payer: x.payer,
    receiptPath: x.receiptPath,
    source: x.source ?? 'assistant',
    sourceRef: x.sourceRef ?? null,
    createdBy: x.uid,
    author: x.author,
    createdAt: serverTime,
    updatedAt: serverTime,
    updatedBy: x.uid,
    deleted: false,
    deletedAt: null,
    deletedBy: null,
  };
}

/** `babies/{b}/reminders/{rm}` with exactly the Rules' key set (`validNewReminder`). */
export function buildReminder<S>(
  x: {
    id: string;
    babyId: string;
    uid: string;
    author: Author;
    title: string;
    dueAt: Date;
    leadMinutes: number;
    // ---- D-075 #5 (reminders): all day and assignee ----
    allDay?: boolean;
    dueDate?: string | null;
    assigneeUid?: string | null;
  },
  serverTime: S,
) {
  return {
    id: x.id,
    babyId: x.babyId,
    title: x.title,
    dueAt: x.dueAt,
    leadMinutes: x.leadMinutes,
    notifyDevice: null,
    createdBy: x.uid,
    author: x.author,
    createdAt: serverTime,
    updatedAt: serverTime,
    updatedBy: x.uid,
    done: false,
    doneAt: null,
    doneBy: null,
    doneAuthor: null,
    allDay: x.allDay === true,
    dueDate: x.allDay === true ? (x.dueDate ?? null) : null,
    assigneeUid: x.assigneeUid ?? null,
  };
}

/** The member's label as "Ai trả" (Rules `validPayer`), or null ("Khác") when it would not fit. */
export function payerOf(m: ScopeMember): (Author & { uid: string }) | null {
  const name = m.displayName.trim();
  if (!name || name.length > 40 || m.relation.length > 24) return null;
  return { uid: m.uid, ...authorOf(m) };
}

/**
 * Same checks as the Chi tiêu form and Rules: a currency Chi tiêu keeps (D-075 #4; an unknown or
 * uncertain one stays in review), 1 … that currency's ceiling in minor units (1 000 000 000 đ for
 * VND), a date not after today (baby zone), a valid category id. The total is the receipt's
 * total — subtotal, tax and discount are never added (brief p.14).
 */
export function expenseFromDraft(
  p: DraftPayload,
  now: Date,
  zone: string,
):
  | {
      ok: true;
      amount: number;
      currency: ExpenseCurrency;
      spentOn: string;
      note: string;
      categoryId: string;
    }
  | { ok: false; problems: DraftProblem[] } {
  if (p.kind !== 'expense') return { ok: false, problems: [] };
  const problems = new Set<DraftProblem>([...draftProblems(p, now), ...assistantModuleProblems(p)]);
  const amount = p.totalMinor;
  if (!isExpenseCurrency(p.currency)) problems.add('CURRENCY_UNSUPPORTED');
  const currency = currencyOfDoc(p.currency);
  if (amount !== null && !amountFits(amount, currency)) problems.add('INVALID_AMOUNT');
  if (p.date !== null && p.date > localDateIn(zone, now)) problems.add('FUTURE_TIME');
  const categoryId = p.categoryId ?? otherCategoryId;
  // A malformed category id has no problem code of its own: VALIDATION_FAILED, field-level only.
  if (problems.size > 0 || !categoryIdSchema.safeParse(categoryId).success) {
    return { ok: false, problems: [...problems] };
  }
  return {
    ok: true,
    amount: amount!,
    currency,
    spentOn: p.date!,
    note: (p.merchant ?? '').trim().slice(0, spendingLimits.noteMax),
    categoryId,
  };
}

/**
 * Same checks as the reminder form and Rules: a title of 1–80 characters, a date, due not before
 * now (5 min skew) and at most 366 days ahead, computed in the baby's zone. D-075 #5: a date
 * without a time is an all-day reminder (due all that day, `dueAt` 23:59 there; never a default
 * 09:00 — the person's own notification time applies on their devices).
 */
export function reminderFromDraft(
  p: DraftPayload,
  now: Date,
  zone: string,
):
  | { ok: true; title: string; dueAt: Date; allDay: boolean; dueDate: string | null }
  | { ok: false; problems: DraftProblem[] } {
  if (p.kind !== 'reminder') return { ok: false, problems: [] };
  const problems = new Set<DraftProblem>([...draftProblems(p, now), ...assistantModuleProblems(p)]);
  const title = p.title.trim();
  if (!title) problems.add('MISSING_TITLE');
  else if (title.length > reminderModuleTitleMax) problems.add('INVALID_TITLE');
  let dueAt: Date | null = null;
  const allDay = p.date !== null && p.time === null && !reminderNeedsTime();
  if (p.date !== null && p.time !== null) {
    dueAt = localInstant(zone, p.date, p.time);
    if (dueAt.getTime() < now.getTime() - reminderLimits.pastSkewMinutes * 60_000) {
      problems.add('PAST_TIME');
    } else if (dueAt.getTime() > now.getTime() + reminderLimits.maxDaysAhead * 86_400_000) {
      problems.add('INVALID_TIME');
    }
  } else if (allDay) {
    // ---- D-075 #5: all day, by date in the baby's zone ----
    dueAt = reminderAllDayDueAt(zone, p.date!);
    if (p.date! < localDateIn(zone, now)) problems.add('PAST_TIME');
    else if (dueAt.getTime() > now.getTime() + reminderLimits.maxDaysAhead * 86_400_000) {
      problems.add('INVALID_TIME');
    }
  }
  if (problems.size > 0 || !dueAt) return { ok: false, problems: [...problems] };
  return { ok: true, title, dueAt, allDay, dueDate: allDay ? p.date : null };
}

/** App routes that open a saved expense / reminder (built here, never by the model). */
export function imageRecordLink(kind: 'expense' | 'reminder', babyId: string, id: string): string {
  return kind === 'expense'
    ? `/utilities/spending/expense/${id}?babyId=${babyId}`
    : `/care/reminders/${id}?babyId=${babyId}`;
}

// ---------- Duplicates (CH11 "Nghi trùng", I03): a warning, never a merge ----------

export interface DuplicateQuery {
  familyId: string;
  /** The household's babies to look through (the expense collection is per baby). */
  babyIds: readonly string[];
  date: string | null;
  total: number | null;
  /** D-075 #4: when given, only expenses in it are compared (absent: any currency). */
  currency?: string | null;
  merchant: string | null;
  /** Server-computed content hashes of this task's photos. */
  sha256s: readonly string[];
  /** This draft's own expense id and this task's own photos (never a duplicate of itself). */
  excludeExpenseId: string | null;
  excludeAttachmentIds: readonly string[];
}

const close = (a: number, b: number) => Math.abs(a - b) <= Math.max(1, Math.round(b * 0.01));

/**
 * Same household only (no global dedup): a live expense within a day of the receipt date with a
 * total within 1 % and the same merchant (or no merchant on either side), or the same photo
 * (content hash) already saved as an expense by this household.
 */
export async function expenseDuplicateSuspected(
  db: Firestore,
  q: DuplicateQuery,
  tx?: Transaction,
): Promise<boolean> {
  const get = <T>(r: FirebaseFirestore.Query<T>) => (tx ? tx.get(r) : r.get());
  if (q.date !== null && q.total !== null) {
    const m = q.merchant ? foldText(q.merchant) : '';
    for (const babyId of q.babyIds) {
      const snap = await get(
        db
          .collection(`babies/${babyId}/expenses`)
          .where('spentOn', '>=', addDaysIso(q.date, -1))
          .where('spentOn', '<=', addDaysIso(q.date, 1)),
      );
      for (const d of snap.docs) {
        if (d.id === q.excludeExpenseId || d.get('deleted') === true) continue;
        if (q.currency && currencyOfDoc(d.get('currency')) !== q.currency) continue;
        if (!close(d.get('amount') as number, q.total)) continue;
        const note = foldText((d.get('note') as string | undefined) ?? '');
        if (!m || !note || note.includes(m) || m.includes(note)) return true;
      }
    }
  }
  for (const h of new Set(q.sha256s)) {
    const snap = await get(db.collection('assistantAttachments').where('sha256Server', '==', h));
    if (
      snap.docs.some(
        (d) =>
          d.get('familyId') === q.familyId &&
          !q.excludeAttachmentIds.includes(d.id) &&
          ((d.get('savedExpenseIds') as string[] | undefined) ?? []).length > 0,
      )
    ) {
      return true;
    }
  }
  return false;
}

/** The household's babies (the family's list, else the scope's baby). */
export async function householdBabyIds(
  db: Firestore,
  familyId: string,
  fallback: string,
  tx?: Transaction,
): Promise<string[]> {
  const ref = db.doc(`families/${familyId}`);
  const fam = tx ? await tx.get(ref) : await ref.get();
  const ids = (fam.get('babyIds') as string[] | undefined) ?? [];
  return ids.length > 0 ? [...new Set([...ids, fallback])] : [fallback];
}

// ---------- Confirm: the domain part for expense / reminder ----------

export type ImageWritePlan =
  | {
      kind: 'fail';
      errorCode: 'VALIDATION_FAILED' | 'WRITE_DENIED' | 'SCOPE_CHANGED';
      problems: DraftProblem[];
    }
  | { kind: 'adopt'; target: DocumentReference }
  | {
      kind: 'write';
      target: DocumentReference;
      doc: Record<string, unknown>;
      conflict: 'DUPLICATE_SUSPECTED' | null;
      warnings: ('duplicate_suspected' | 'overlap')[];
    };

/**
 * Reads (inside the confirm transaction, before any write) and builds the domain document for an
 * expense or reminder draft. The role was checked for the scope's baby; an expense attributed to
 * another baby of the household needs the same right there. A duplicate suspected now (re-checked
 * at confirm) is a `conflict` unless the person acknowledged it ("Vẫn lưu").
 */
export async function planImageWrite<S>(
  tx: Transaction,
  db: Firestore,
  x: {
    draftId: string;
    taskId: string;
    familyId: string;
    babyId: string;
    uid: string;
    zone: string;
    now: Date;
    member: ScopeMember;
    acknowledge: readonly ('duplicate_suspected' | 'overlap')[];
    warnings: readonly ('duplicate_suspected' | 'overlap')[];
    receiptPath: string | null;
    attachmentIds: readonly string[];
  },
  p: DraftPayload,
  serverTime: S,
): Promise<ImageWritePlan> {
  if (p.kind === 'reminder') {
    const r = reminderFromDraft(p, x.now, x.zone);
    if (!r.ok) return { kind: 'fail', errorCode: 'VALIDATION_FAILED', problems: r.problems };
    const id = reminderIdForDraft(x.draftId);
    const target = db.doc(`babies/${x.babyId}/reminders/${id}`);
    // ---- D-075 #5: the assignee is re-read now (Rules `validReminderAssignee`) ----
    const assignee = p.assigneeUid
      ? tx.get(db.doc(`babies/${x.babyId}/members/${p.assigneeUid}`))
      : Promise.resolve(null);
    const [existing, assigneeSnap] = await Promise.all([tx.get(target), assignee]);
    if (existing.exists) return { kind: 'adopt', target };
    if (assigneeSnap) {
      const m = memberOf(assigneeSnap, x.now);
      if (!m || !(reminderAssigneeRoles as readonly string[]).includes(m.role)) {
        return { kind: 'fail', errorCode: 'VALIDATION_FAILED', problems: ['INVALID_ASSIGNEE'] };
      }
    }
    return {
      kind: 'write',
      target,
      doc: buildReminder(
        {
          id,
          babyId: x.babyId,
          uid: x.uid,
          author: authorOf(x.member),
          title: r.title,
          dueAt: r.dueAt,
          leadMinutes: r.allDay ? defaultReminderAllDayLeadMinutes : defaultReminderLeadMinutes,
          allDay: r.allDay,
          dueDate: r.dueDate,
          assigneeUid: p.assigneeUid,
        },
        serverTime,
      ),
      conflict: null,
      warnings: [...x.warnings],
    };
  }
  if (p.kind !== 'expense') return { kind: 'fail', errorCode: 'VALIDATION_FAILED', problems: [] };
  const e = expenseFromDraft(p, x.now, x.zone);
  if (!e.ok) return { kind: 'fail', errorCode: 'VALIDATION_FAILED', problems: e.problems };
  const babyId = p.babyId ?? x.babyId;
  const id = expenseIdForDraft(x.draftId);
  const target = db.doc(`babies/${babyId}/expenses/${id}`);
  const reads: Promise<FirebaseFirestore.DocumentSnapshot>[] = [tx.get(target)];
  const builtIn = builtInCategories.some((c) => c.id === e.categoryId);
  if (!builtIn)
    reads.push(tx.get(db.doc(`families/${x.familyId}/spendingCategories/${e.categoryId}`)));
  let other: FirebaseFirestore.DocumentSnapshot[] = [];
  if (babyId !== x.babyId) {
    other = await Promise.all([
      tx.get(db.doc(`babies/${babyId}`)),
      tx.get(db.doc(`babies/${babyId}/members/${x.uid}`)),
    ]);
  }
  const [existing, category] = await Promise.all(reads);
  if (existing!.exists) return { kind: 'adopt', target };
  if (!builtIn && !category?.exists) {
    return { kind: 'fail', errorCode: 'VALIDATION_FAILED', problems: [] };
  }
  if (babyId !== x.babyId) {
    const [baby, memberSnap] = other;
    if (!baby!.exists || baby!.get('familyId') !== x.familyId) {
      return { kind: 'fail', errorCode: 'SCOPE_CHANGED', problems: [] };
    }
    if ((baby!.get('state') ?? 'active') !== 'active') {
      return { kind: 'fail', errorCode: 'WRITE_DENIED', problems: [] };
    }
    const m = memberOf(memberSnap!, x.now);
    if (!m || !canRecordSpending(m))
      return { kind: 'fail', errorCode: 'WRITE_DENIED', problems: [] };
  }
  const warnings = new Set(x.warnings);
  // The task's photos' server-computed hashes (same photo already saved → duplicate warning).
  const sha256s = (await Promise.all(x.attachmentIds.map((id) => tx.get(attachmentRef(db, id)))))
    .map((a) => a.get('sha256Server') as string | null | undefined)
    .filter((h): h is string => typeof h === 'string');
  const duplicate = await expenseDuplicateSuspected(
    db,
    {
      familyId: x.familyId,
      babyIds: await householdBabyIds(db, x.familyId, babyId, tx),
      date: e.spentOn,
      total: e.amount,
      currency: e.currency,
      merchant: p.merchant,
      sha256s,
      excludeExpenseId: id,
      excludeAttachmentIds: x.attachmentIds,
    },
    tx,
  );
  if (duplicate) warnings.add('duplicate_suspected');
  const conflict =
    duplicate && !x.acknowledge.includes('duplicate_suspected') ? 'DUPLICATE_SUSPECTED' : null;
  return {
    kind: 'write',
    target,
    doc: buildExpense(
      {
        uid: x.uid,
        author: authorOf(x.member),
        amount: e.amount,
        currency: e.currency,
        categoryId: e.categoryId,
        note: e.note,
        spentOn: e.spentOn,
        payer: payerOf(x.member),
        receiptPath: x.receiptPath,
        source: 'assistant',
        sourceRef: x.draftId,
      },
      serverTime,
    ),
    conflict,
    warnings: [...warnings],
  };
}

// ---------- "Giữ ảnh hoá đơn": the receipt copy around the confirm transaction ----------

const receiptMaxBytes = 4 * 1024 * 1024;

export interface ReceiptCopy {
  path: string;
  attachmentId: string;
  /** Written by this attempt (removed again if the expense is not saved). */
  fresh: boolean;
}

/**
 * Before the confirm transaction (Storage is not transactional): when the expense draft keeps
 * its receipt and a "keep with the record" photo is still there, a re-encoded JPEG (≤ 2048 px,
 * metadata stripped, ≤ 4 MB — the Chi tiêu receipt limit) is written to the expense's receipt
 * path. Idempotent: the path is the expense's own. Null when there is nothing to keep (the
 * photo was "xoá sau khi đọc", already deleted, or keepReceipt is off): the expense is then saved
 * without a receipt, and the photo's real state is what the app shows.
 */
export async function prepareReceiptCopy(
  db: Firestore,
  files: AttachmentStore | undefined,
  x: { taskId: string; draftId: string; babyId: string; revision: number },
): Promise<ReceiptCopy | null> {
  if (!files) return null;
  const d = await draftRef(db, x.taskId, x.draftId).get();
  // Only for a confirm that can go through (the transaction re-checks everything).
  if (!d.exists || !['draft', 'failed'].includes(d.get('state') as string)) return null;
  if (d.get('revision') !== x.revision) return null;
  const review = [
    ...((d.get('uncertainFields') as string[] | undefined) ?? []),
    ...((d.get('missingFields') as string[] | undefined) ?? []),
  ];
  if (review.length > 0) return null;
  const p = d.get('payload') as DraftPayload | undefined;
  if (p?.kind !== 'expense' || p.keepReceipt !== true) return null;
  const task = await taskRef(db, x.taskId).get();
  const ids = (task.get('input.attachmentIds') as string[] | undefined) ?? [];
  for (const id of ids) {
    const snap = await attachmentRef(db, id).get();
    if (!snap.exists) continue;
    const a = storedAttachment(snap);
    if (a.retention !== 'keep_with_record' || a.state !== 'ready' || !a.generation || a.rejected) {
      continue;
    }
    let bytes: Buffer;
    try {
      bytes = await files.read(a.storagePath, a.generation);
    } catch {
      continue;
    }
    const jpeg = await validateImage(bytes, a.mime);
    if (!jpeg || jpeg.jpeg.length > receiptMaxBytes) continue;
    const path = receiptPathFor(p.babyId ?? x.babyId, expenseIdForDraft(x.draftId));
    const existed = await files.exists(path);
    await files.write(path, jpeg.jpeg, 'image/jpeg');
    return { path, attachmentId: id, fresh: !existed };
  }
  return null;
}

/**
 * After the confirm transaction: a saved expense marks the task's photos (`savedExpenseIds`, for
 * the household "same photo" duplicate check; `keptPath` on the kept one) and lets the temporary
 * originals go (Storage-confirmed); a copy written for an expense that was not saved is removed.
 */
export async function afterImageConfirm(
  db: Firestore,
  files: AttachmentStore | undefined,
  x: { taskId: string; draftId: string; now: Date },
  out: { status: string; recordId: string | null },
  receipt: ReceiptCopy | null,
): Promise<void> {
  const d = await draftRef(db, x.taskId, x.draftId).get();
  const p = d.get('payload') as DraftPayload | undefined;
  if (p?.kind !== 'expense') return;
  if (out.status === 'saved' && out.recordId) {
    const task = await taskRef(db, x.taskId).get();
    const ids = (task.get('input.attachmentIds') as string[] | undefined) ?? [];
    for (const id of ids) {
      await attachmentRef(db, id).update({
        savedExpenseIds: FieldValue.arrayUnion(out.recordId),
        ...(receipt?.attachmentId === id ? { keptPath: receipt.path } : {}),
        updatedAt: Timestamp.fromDate(x.now),
      });
    }
    try {
      await settleTaskAttachments(db, files, x.taskId, x.now);
    } catch {
      // The sweeper retries; the photo stays `ready` / `deletion_pending`, never "deleted".
    }
    return;
  }
  if (receipt?.fresh && files) {
    const expense = receipt.path.replace(/\.jpg$/, '');
    const [, babyId, , id] = expense.split('/');
    if (!(await db.doc(`babies/${babyId}/expenses/${id}`).get()).exists) {
      try {
        await files.delete(receipt.path);
      } catch {
        // An orphan copy without an expense is not readable through any record.
      }
    }
  }
}
