import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, serverTimestamp, setDoc, Timestamp } from 'firebase/firestore';
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import type { DraftPayload } from '@child-life/contracts';
import type { ScopeMember } from '../functions/src/assistant-common.js';
import {
  expenseIdForDraft,
  receiptPathFor,
  reminderIdForDraft,
} from '../functions/src/assistant-image-rules.js';
import {
  buildExpense,
  buildReminder,
  expenseFromDraft,
  payerOf,
  reminderFromDraft,
} from '../functions/src/assistant-writers-images.js';

// Child Life Assistant, slice A3 (docs/assistant/security.md): photo attachments are read-only for
// their uploader (still a member), never written by a client; the cached photo reading is never
// readable; the Storage path `assistant/{uid}/{at_*}` takes one upload by its owner matching the
// attachment document and is never read back. Shape test (P-156): the expense and reminder
// documents the server writers produce pass the app's own create rules when written by the member
// with the app's source (`manual`, no sourceRef); a client can never write `source: 'assistant'`.
// Storage Rules read Firestore (`firestore.get`) only in the emulator's own project, so this file
// uses that project (as memories.rules.test.ts does); every test clears it first.
const projectId = process.env.GCLOUD_PROJECT ?? 'demo-child-life';
let env: RulesTestEnvironment;

const AT = `at_${'0'.repeat(31)}1`;
const AT2 = `at_${'0'.repeat(31)}2`;
const TK = `tk_${'0'.repeat(31)}1`;
const DR = `dr_${'0'.repeat(32)}_0`;
const scope = { type: 'household', babyId: 'b1' };
const ZONE = 'Asia/Ho_Chi_Minh';

const member = (
  role: string,
  relation: string,
  displayName: string,
  extra: Record<string, unknown> = {},
) => ({
  babyId: 'b1',
  role,
  status: 'active',
  relation,
  relationCustom: null,
  displayName,
  ...extra,
});
const mom: ScopeMember = {
  uid: 'mom',
  role: 'coParent',
  isOwner: true,
  extraRights: null,
  displayName: 'Mai',
  relation: 'mother',
  relationCustom: null,
};
const aunt: ScopeMember = {
  ...mom,
  uid: 'aunt',
  role: 'relative',
  isOwner: false,
  displayName: 'Dì Thu',
  relation: 'relative',
  extraRights: { recordSpending: true },
};

const attachmentDoc = (over: Record<string, unknown> = {}) => ({
  id: AT,
  ownerUid: 'mom',
  uploaderUid: 'mom',
  familyId: 'f1',
  scope,
  storagePath: `assistant/mom/${AT}`,
  mime: 'image/jpeg',
  bytes: 1024,
  state: 'uploading',
  uploadExpiresAt: Timestamp.fromMillis(Date.now() + 10 * 60_000),
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
    await setDoc(doc(db, 'babies/b1'), { familyId: 'f1', state: 'active' });
    await setDoc(
      doc(db, 'babies/b1/members/mom'),
      member('coParent', 'mother', 'Mai', { isOwner: true }),
    );
    await setDoc(doc(db, 'babies/b1/members/dad'), member('coParent', 'father', 'Huy'));
    await setDoc(doc(db, 'babies/b1/members/nanny'), member('caregiver', 'nanny', 'Cô Hoa'));
    await setDoc(
      doc(db, 'babies/b1/members/aunt'),
      member('relative', 'relative', 'Dì Thu', {
        extraRights: { viewBabyInfo: false, viewDailyCare: false, recordSpending: true },
      }),
    );
    await setDoc(doc(db, `assistantAttachments/${AT}`), attachmentDoc());
    await setDoc(
      doc(db, `assistantAttachments/${AT2}`),
      attachmentDoc({
        id: AT2,
        storagePath: `assistant/mom/${AT2}`,
        uploadExpiresAt: Timestamp.fromMillis(Date.now() - 60_000),
      }),
    );
    await setDoc(doc(db, `assistantTasks/${TK}`), {
      ownerUid: 'mom',
      scope,
      state: 'awaiting_clarification',
    });
    await setDoc(doc(db, `assistantTasks/${TK}/imageReading/current`), { reading: {} });
    await setDoc(doc(db, `assistantTasks/${TK}/textReading/current`), { ext: {} });
  });
});

const as = (uid: string) => env.authenticatedContext(uid).firestore();
const storageAs = (uid: string) => env.authenticatedContext(uid).storage();
const jpeg = (n = 512) => new Uint8Array(n).fill(7);

describe('assistantAttachments: uploader read-only; the cached reading never readable', () => {
  it('the uploader reads the attachment state; others and signed-out clients do not', async () => {
    await assertSucceeds(getDoc(doc(as('mom'), `assistantAttachments/${AT}`)));
    await assertFails(getDoc(doc(as('dad'), `assistantAttachments/${AT}`)));
    await assertFails(
      getDoc(doc(env.unauthenticatedContext().firestore(), `assistantAttachments/${AT}`)),
    );
  });

  it('no client writes; the photo reading of a task is not readable even by its owner', async () => {
    await assertFails(
      setDoc(doc(as('mom'), `assistantAttachments/${AT}`), attachmentDoc({ state: 'deleted' })),
    );
    await assertFails(setDoc(doc(as('mom'), 'assistantAttachments/at_new'), attachmentDoc()));
    await assertFails(getDoc(doc(as('mom'), `assistantTasks/${TK}/imageReading/current`)));
    // Lumi rework 2026-10-15: nor the text reading kept while a server question is open.
    await assertFails(getDoc(doc(as('mom'), `assistantTasks/${TK}/textReading/current`)));
  });

  it('the uploader stops reading once their membership ended', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), 'babies/b1/members/mom'),
        member('coParent', 'mother', 'Mai', { status: 'removed' }),
      );
    });
    await assertFails(getDoc(doc(as('mom'), `assistantAttachments/${AT}`)));
  });
});

// ---------- Writer shapes (P-156) ----------

const now = () => new Date();
const today = () => new Intl.DateTimeFormat('en-CA', { timeZone: ZONE }).format(now());
const expensePayload = (): DraftPayload => ({
  kind: 'expense',
  merchant: 'ConCung',
  totalMinor: 486000,
  currency: 'VND',
  date: today(),
  subtotalMinor: 450000,
  taxMinor: 36000,
  categoryId: 'c_diaper',
  babyId: 'b1',
  keepReceipt: true,
});

function expenseDoc(
  who: typeof mom,
  source: 'manual' | 'assistant',
  receipt = false,
  over: Partial<DraftPayload> = {},
) {
  const e = expenseFromDraft({ ...expensePayload(), ...over } as DraftPayload, now(), ZONE);
  if (!e.ok) throw new Error('expense');
  const id = expenseIdForDraft(DR);
  return {
    id,
    data: buildExpense(
      {
        uid: who.uid,
        author: {
          name: who.displayName,
          relation: who.relation,
          relationCustom: who.relationCustom,
        },
        amount: e.amount,
        currency: e.currency,
        categoryId: e.categoryId,
        note: e.note,
        spentOn: e.spentOn,
        payer: payerOf(who),
        receiptPath: receipt ? receiptPathFor('b1', id) : null,
        source,
        sourceRef: source === 'assistant' ? DR : null,
      },
      serverTimestamp(),
    ),
  };
}

function reminderDoc(
  who: typeof mom,
  // D-075 #5: `time: null` = all day; an assignee the person picked.
  o: { time?: string | null; assigneeUid?: string | null } = {},
) {
  const tomorrow = new Date(now().getTime() + 86_400_000);
  const date = new Intl.DateTimeFormat('en-CA', { timeZone: ZONE }).format(tomorrow);
  const r = reminderFromDraft(
    {
      kind: 'reminder',
      title: 'Mua bỉm',
      date,
      time: o.time === undefined ? '17:00' : o.time,
      assigneeUid: o.assigneeUid ?? null,
    },
    now(),
    ZONE,
  );
  if (!r.ok) throw new Error('reminder');
  const id = reminderIdForDraft(DR);
  return {
    id,
    data: buildReminder(
      {
        id,
        babyId: 'b1',
        uid: who.uid,
        author: {
          name: who.displayName,
          relation: who.relation,
          relationCustom: who.relationCustom,
        },
        title: r.title,
        dueAt: r.dueAt,
        leadMinutes: r.allDay ? 0 : 60,
        allDay: r.allDay,
        dueDate: r.dueDate,
        assigneeUid: o.assigneeUid ?? null,
      },
      serverTimestamp(),
    ),
  };
}

describe('writer documents pass the app’s create rules (P-156)', () => {
  it('expense: accepted as a Cùng nuôi with the app source, receipt path included', async () => {
    const e = expenseDoc(mom, 'manual', true);
    expect(Object.keys(e.data).sort()).toEqual([
      'amount',
      'author',
      'categoryId',
      'createdAt',
      'createdBy',
      'currency',
      'deleted',
      'deletedAt',
      'deletedBy',
      'note',
      'payer',
      'receiptPath',
      'source',
      'sourceRef',
      'spentOn',
      'updatedAt',
      'updatedBy',
    ]);
    await assertSucceeds(setDoc(doc(as('mom'), `babies/b1/expenses/${e.id}`), e.data));
  });

  it('expense: a relative with "Ghi khoản đã chi" passes; a caregiver without it does not', async () => {
    const a = expenseDoc(aunt, 'manual');
    await assertSucceeds(setDoc(doc(as('aunt'), `babies/b1/expenses/${a.id}`), a.data));
    const n = expenseDoc(
      { ...mom, uid: 'nanny', role: 'coParent', displayName: 'Cô Hoa', relation: 'nanny' },
      'manual',
    );
    await assertFails(setDoc(doc(as('nanny'), `babies/b1/expenses/x_${'1'.repeat(32)}`), n.data));
  });

  it('a client can never write source "assistant" (only the server writer does)', async () => {
    const e = expenseDoc(mom, 'assistant');
    expect(e.data).toMatchObject({ source: 'assistant', sourceRef: DR });
    await assertFails(setDoc(doc(as('mom'), `babies/b1/expenses/${e.id}`), e.data));
  });

  it('reminder: the exact key set passes as a Cùng nuôi; a caregiver cannot create one', async () => {
    const r = reminderDoc(mom);
    expect(r.data).toMatchObject({ notifyDevice: null, leadMinutes: 60, done: false });
    await assertSucceeds(setDoc(doc(as('mom'), `babies/b1/reminders/${r.id}`), r.data));
    const n = reminderDoc({ ...mom, uid: 'nanny', displayName: 'Cô Hoa', relation: 'nanny' });
    await assertFails(setDoc(doc(as('nanny'), `babies/b1/reminders/rm_${'2'.repeat(32)}`), n.data));
  });

  // D-075 #5: a date-only draft is an all-day reminder; the assignee must be able to receive it.
  it('reminder all day with an assignee: accepted for a caregiver, refused for a relative', async () => {
    const r = reminderDoc(mom, { time: null, assigneeUid: 'nanny' });
    expect(r.data).toMatchObject({ allDay: true, leadMinutes: 0, assigneeUid: 'nanny' });
    expect(r.data.dueDate).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    await assertSucceeds(setDoc(doc(as('mom'), `babies/b1/reminders/${r.id}`), r.data));
    const bad = reminderDoc(mom, { time: null, assigneeUid: 'aunt' });
    await assertFails(
      setDoc(doc(as('mom'), `babies/b1/reminders/rm_${'3'.repeat(32)}`), {
        ...bad.data,
        id: `rm_${'3'.repeat(32)}`,
      }),
    );
  });

  // D-075 #4: a USD receipt is saved in cents with its currency, and passes the app's rules.
  it('expense in USD: cents and the currency, accepted by the create rules', async () => {
    const e = expenseDoc(mom, 'manual', false, { currency: 'USD', totalMinor: 1250 });
    expect(e.data).toMatchObject({ amount: 1250, currency: 'USD' });
    await assertSucceeds(setDoc(doc(as('mom'), `babies/b1/expenses/${e.id}`), e.data));
  });

  // Lumi rework 2026-10-15: a typed expense ("mua sữa hết 500k ở Con Cưng") — what was bought
  // and the shop make the one note; no receipt; same key set, accepted by the create rules.
  it('typed expense: note = what · shop (≤ 80), no receipt, accepted by the create rules', async () => {
    const e = expenseDoc(mom, 'manual', false, {
      note: 'sữa',
      merchant: 'Con Cưng',
      totalMinor: 500_000,
      subtotalMinor: null,
      taxMinor: null,
      categoryId: 'c_milk',
      keepReceipt: false,
    } as Partial<DraftPayload>);
    expect(e.data).toMatchObject({ amount: 500_000, note: 'sữa · Con Cưng', receiptPath: null });
    await assertSucceeds(setDoc(doc(as('mom'), `babies/b1/expenses/${e.id}`), e.data));
    const long = expenseDoc(mom, 'manual', false, {
      note: 'x'.repeat(80),
      merchant: 'Shop',
    } as Partial<DraftPayload>);
    expect((long.data.note as string).length).toBe(80);
  });

  it('the writers refuse what the forms refuse (unknown currency, no time, past due, title too long)', () => {
    expect(
      expenseFromDraft({ ...expensePayload(), currency: 'XAF' } as DraftPayload, now(), ZONE).ok,
    ).toBe(false);
    expect(
      expenseFromDraft({ ...expensePayload(), currency: null } as DraftPayload, now(), ZONE).ok,
    ).toBe(false);
    expect(
      expenseFromDraft(
        { ...expensePayload(), currency: 'USD', totalMinor: 100_000_001 } as DraftPayload,
        now(),
        ZONE,
      ).ok,
    ).toBe(false);
    const base = { kind: 'reminder' as const, title: 'Mua bỉm', date: today(), assigneeUid: null };
    // D-075 #5: no time is no longer refused — it is all day (today is still allowed).
    expect(reminderFromDraft({ ...base, time: null }, now(), ZONE)).toMatchObject({
      ok: true,
      allDay: true,
      dueDate: today(),
    });
    expect(reminderFromDraft({ ...base, date: '2020-01-01', time: null }, now(), ZONE)).toEqual({
      ok: false,
      problems: ['PAST_TIME'],
    });
    expect(reminderFromDraft({ ...base, date: '2020-01-01', time: '09:00' }, now(), ZONE)).toEqual({
      ok: false,
      problems: ['PAST_TIME'],
    });
    expect(
      reminderFromDraft({ ...base, title: 'x'.repeat(100), time: '23:59' }, now(), ZONE).ok,
    ).toBe(false);
  });
});

// ---------- Storage: assistant/{uid}/{at_*} ----------

describe('Storage: assistant photos', () => {
  it('the owner uploads once, matching the attachment document; nobody reads, replaces or deletes it', async () => {
    const path = `assistant/mom/${AT}`;
    await assertSucceeds(
      uploadBytes(ref(storageAs('mom'), path), jpeg(), { contentType: 'image/jpeg' }),
    );
    await assertFails(
      uploadBytes(ref(storageAs('mom'), path), jpeg(), { contentType: 'image/jpeg' }),
    );
    await assertFails(getBytes(ref(storageAs('mom'), path)));
    await assertFails(getBytes(ref(storageAs('dad'), path)));
    await assertFails(deleteObject(ref(storageAs('mom'), path)));
  });

  it('refused: another uid, another type than declared, larger than declared, expired, no document', async () => {
    await assertFails(
      uploadBytes(ref(storageAs('dad'), `assistant/mom/${AT}`), jpeg(), {
        contentType: 'image/jpeg',
      }),
    );
    await assertFails(
      uploadBytes(ref(storageAs('dad'), `assistant/dad/${AT}`), jpeg(), {
        contentType: 'image/jpeg',
      }),
    );
    await assertFails(
      uploadBytes(ref(storageAs('mom'), `assistant/mom/${AT}`), jpeg(), {
        contentType: 'image/png',
      }),
    );
    await assertFails(
      uploadBytes(ref(storageAs('mom'), `assistant/mom/${AT}`), jpeg(2048), {
        contentType: 'image/jpeg',
      }),
    );
    await assertFails(
      uploadBytes(ref(storageAs('mom'), `assistant/mom/${AT}`), jpeg(), {
        contentType: 'application/pdf',
      }),
    );
    await assertFails(
      uploadBytes(ref(storageAs('mom'), `assistant/mom/${AT2}`), jpeg(), {
        contentType: 'image/jpeg',
      }),
    );
    await assertFails(
      uploadBytes(ref(storageAs('mom'), `assistant/mom/at_${'9'.repeat(32)}`), jpeg(), {
        contentType: 'image/jpeg',
      }),
    );
    await assertFails(
      uploadBytes(ref(storageAs('mom'), 'assistant/mom/receipt.jpg'), jpeg(), {
        contentType: 'image/jpeg',
      }),
    );
    await assertFails(
      uploadBytes(ref(env.unauthenticatedContext().storage(), `assistant/mom/${AT}`), jpeg(), {
        contentType: 'image/jpeg',
      }),
    );
  });

  it('once the photo is no longer `uploading` (bound, deleted) no upload is accepted', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), `assistantAttachments/${AT}`),
        attachmentDoc({ state: 'ready' }),
      );
    });
    await assertFails(
      uploadBytes(ref(storageAs('mom'), `assistant/mom/${AT}`), jpeg(), {
        contentType: 'image/jpeg',
      }),
    );
  });
});
