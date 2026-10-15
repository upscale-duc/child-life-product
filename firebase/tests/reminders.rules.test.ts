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
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// S7 reminders: Cùng nuôi create / edit / delete, caregivers view and mark done, relatives
// never (D-018, D-029…D-031); shape from packages/contracts/src/reminders.ts.
const projectId = 'demo-child-life-reminders';
let env: RulesTestEnvironment;

const relations: Record<string, string> = {
  mom: 'mother',
  dad: 'father',
  nanny: 'nanny',
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
const device = (uid: string, hex = 'a') => ({
  id: `d_${hex.repeat(32)}`,
  uid,
  label: 'iPhone',
  owner: uid,
});
const inHours = (h: number) => Timestamp.fromDate(new Date(Date.now() + h * 3_600_000));

let seq = 0;
const newId = () => `rm_${(++seq).toString(16).padStart(32, '0')}`;

function reminder(uid: string, id: string, overrides: Record<string, unknown> = {}) {
  return {
    id,
    babyId: 'b1',
    title: 'Tiêm 6 trong 1',
    dueAt: inHours(40),
    leadMinutes: 60,
    notifyDevice: device(uid),
    createdBy: uid,
    author: author(uid),
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    updatedBy: uid,
    done: false,
    doneAt: null,
    doneBy: null,
    doneAuthor: null,
    ...overrides,
  };
}

const SEEDED = 'rm_seeded000000000000000000000000';
const DONE = 'rm_done00000000000000000000000000';

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
    await setDoc(doc(db, 'babies/b1'), { nickname: 'Teddy', ownerUid: 'mom', familyId: 'f1' });
    await setDoc(doc(db, 'babies/b1/members/mom'), member('mom', 'coParent', { isOwner: true }));
    await setDoc(doc(db, 'babies/b1/members/dad'), member('dad', 'coParent'));
    await setDoc(doc(db, 'babies/b1/members/nanny'), member('nanny', 'caregiver'));
    await setDoc(
      doc(db, 'babies/b1/members/aunt'),
      member('aunt', 'relative', { extraRights: { viewBabyInfo: true, viewDailyCare: true } }),
    );
    await setDoc(
      doc(db, 'babies/b1/members/gone'),
      member('gone', 'caregiver', { status: 'removed' }),
    );
    const now = Timestamp.now();
    await setDoc(doc(db, `babies/b1/reminders/${SEEDED}`), {
      ...reminder('mom', SEEDED),
      createdAt: now,
      updatedAt: now,
    });
    await setDoc(doc(db, `babies/b1/reminders/${DONE}`), {
      ...reminder('dad', DONE),
      createdAt: now,
      updatedAt: now,
      done: true,
      doneAt: now,
      doneBy: 'nanny',
      doneAuthor: author('nanny'),
    });
  });
});

const as = (uid: string) => env.authenticatedContext(uid).firestore();
const rem = (uid: string, id: string) => doc(as(uid), `babies/b1/reminders/${id}`);
const stamp = (uid: string) => ({ updatedAt: serverTimestamp(), updatedBy: uid });

describe('who sees reminders (8a, 12f, D-018)', () => {
  it('Cùng nuôi and caregivers list them; relatives and removed members cannot', async () => {
    for (const uid of ['mom', 'dad', 'nanny']) {
      await assertSucceeds(getDocs(collection(as(uid), 'babies/b1/reminders')));
    }
    for (const uid of ['aunt', 'gone', 'stranger']) {
      await assertFails(getDoc(rem(uid, SEEDED)));
    }
  });
});

describe('create (8b): Cùng nuôi only, own attribution, own device', () => {
  it('a parent creates with or without a notification device', async () => {
    const a = newId();
    await assertSucceeds(setDoc(rem('dad', a), reminder('dad', a)));
    const b = newId();
    await assertSucceeds(setDoc(rem('mom', b), reminder('mom', b, { notifyDevice: null })));
  });

  it('caregivers and relatives cannot create ("Ba mẹ tạo nhắc việc")', async () => {
    for (const uid of ['nanny', 'aunt']) {
      const id = newId();
      await assertFails(setDoc(rem(uid, id), reminder(uid, id)));
    }
  });

  it('refuses another device owner, a past time, other lead times and bad titles', async () => {
    const bad: Record<string, unknown>[] = [
      { notifyDevice: device('mom') },
      { notifyDevice: { ...device('dad'), id: 'iphone' } },
      { dueAt: inHours(-1) },
      { dueAt: inHours(24 * 400) },
      { leadMinutes: 45 },
      { title: '' },
      { title: '   ' },
      { title: 'x'.repeat(81) },
      { author: author('mom') },
      { done: true },
      { extra: 1 },
    ];
    for (const overrides of bad) {
      const id = newId();
      await assertFails(setDoc(rem('dad', id), reminder('dad', id, overrides)));
    }
    await assertFails(setDoc(rem('dad', 'rm_short'), reminder('dad', 'rm_short')));
  });
});

describe('edit and delete (D-030, D-031)', () => {
  it('any Cùng nuôi edits title, time and lead time', async () => {
    await assertSucceeds(
      updateDoc(rem('dad', SEEDED), {
        title: 'Tiêm 6 trong 1 (mũi 1)',
        dueAt: inHours(30),
        leadMinutes: 1440,
        ...stamp('dad'),
      }),
    );
  });

  it('an edit cannot move the time into the past or touch authorship', async () => {
    await assertFails(updateDoc(rem('dad', SEEDED), { dueAt: inHours(-2), ...stamp('dad') }));
    await assertFails(updateDoc(rem('dad', SEEDED), { createdBy: 'dad', ...stamp('dad') }));
  });

  it('a past-due reminder can still be renamed without changing its time', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), `babies/b1/reminders/${SEEDED}`), {
        dueAt: inHours(-3),
      });
    });
    await assertSucceeds(updateDoc(rem('mom', SEEDED), { title: 'Mua sữa', ...stamp('mom') }));
  });

  it('caregivers cannot edit; only Cùng nuôi delete', async () => {
    await assertFails(updateDoc(rem('nanny', SEEDED), { title: 'x', ...stamp('nanny') }));
    await assertFails(deleteDoc(rem('nanny', SEEDED)));
    await assertFails(deleteDoc(rem('aunt', SEEDED)));
    await assertSucceeds(deleteDoc(rem('dad', SEEDED)));
  });
});

describe('done and undo (8e, 12f, D-030)', () => {
  const markDone = (uid: string) => ({
    done: true,
    doneAt: serverTimestamp(),
    doneBy: uid,
    doneAuthor: author(uid),
    ...stamp(uid),
  });
  const undo = (uid: string) => ({
    done: false,
    doneAt: null,
    doneBy: null,
    doneAuthor: null,
    ...stamp(uid),
  });

  it('caregivers and parents mark done as themselves', async () => {
    await assertSucceeds(updateDoc(rem('nanny', SEEDED), markDone('nanny')));
  });

  it('nobody marks done in someone else’s name; relatives never', async () => {
    await assertFails(updateDoc(rem('nanny', SEEDED), { ...markDone('nanny'), doneBy: 'mom' }));
    await assertFails(
      updateDoc(rem('nanny', SEEDED), { ...markDone('nanny'), doneAuthor: author('mom') }),
    );
    await assertFails(updateDoc(rem('aunt', SEEDED), markDone('aunt')));
  });

  it('undo: any Cùng nuôi or whoever marked it', async () => {
    await assertSucceeds(updateDoc(rem('mom', DONE), undo('mom')));
  });

  it('a caregiver cannot undo someone else’s done', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), `babies/b1/reminders/${DONE}`), {
        doneBy: 'mom',
        doneAuthor: author('mom'),
      });
    });
    await assertFails(updateDoc(rem('nanny', DONE), undo('nanny')));
  });

  it('the caregiver who marked it can undo it', async () => {
    await assertSucceeds(updateDoc(rem('nanny', DONE), undo('nanny')));
  });
});

describe('notification device (R-091, D-029)', () => {
  it('any viewer moves the notification to their own device', async () => {
    await assertSucceeds(
      updateDoc(rem('nanny', SEEDED), { notifyDevice: device('nanny', 'c'), ...stamp('nanny') }),
    );
    await assertSucceeds(
      updateDoc(rem('dad', SEEDED), { notifyDevice: device('dad', 'd'), ...stamp('dad') }),
    );
  });

  it('never onto someone else’s device, and a caregiver cannot clear it', async () => {
    await assertFails(
      updateDoc(rem('nanny', SEEDED), { notifyDevice: device('mom', 'e'), ...stamp('nanny') }),
    );
    await assertFails(updateDoc(rem('nanny', SEEDED), { notifyDevice: null, ...stamp('nanny') }));
    await assertFails(
      updateDoc(rem('aunt', SEEDED), { notifyDevice: device('aunt', 'f'), ...stamp('aunt') }),
    );
  });
});

// D-075 #5: date-only (all day) and an assignee; optional keys so older apps are unaffected.
describe('all day and assignee (D-075 #5)', () => {
  /** The calendar date in Vietnam (the test baby's zone) [days] from now. */
  const vnDate = (days: number) =>
    new Date(Date.now() + 7 * 3_600_000 + days * 86_400_000).toISOString().slice(0, 10);
  /** 23:59 on [date] in Vietnam: the `dueAt` an all-day reminder carries. */
  const endOf = (date: string) => Timestamp.fromDate(new Date(`${date}T16:59:00Z`));
  const nextFeb = Number(vnDate(0).slice(0, 4)) + (Number(vnDate(0).slice(5, 7)) >= 2 ? 1 : 0);
  const allDay = (days: number, over: Record<string, unknown> = {}) => ({
    allDay: true,
    dueDate: vnDate(days),
    dueAt: endOf(vnDate(days)),
    leadMinutes: 0,
    ...over,
  });

  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), 'babies/b1/members/temp'),
        member('temp', 'caregiver', { accessUntilAt: Timestamp.fromMillis(Date.now() - 60_000) }),
      );
    });
  });

  it('a parent creates an all-day reminder (today or later) assigned to a caregiver or parent', async () => {
    for (const [days, assignee] of [
      [0, 'nanny'],
      [3, 'mom'],
      [10, 'dad'],
      [5, null],
    ] as const) {
      const id = newId();
      await assertSucceeds(
        setDoc(rem('dad', id), reminder('dad', id, { ...allDay(days), assigneeUid: assignee })),
      );
    }
    const id = newId();
    await assertSucceeds(
      setDoc(rem('dad', id), reminder('dad', id, { ...allDay(2), leadMinutes: 1440 })),
    );
    // A timed reminder with an assignee and an explicit `allDay: false`.
    const timed = newId();
    await assertSucceeds(
      setDoc(
        rem('mom', timed),
        reminder('mom', timed, { allDay: false, dueDate: null, assigneeUid: 'nanny' }),
      ),
    );
  });

  it('refuses inconsistent days, leads and dates in the past', async () => {
    const bad: Record<string, unknown>[] = [
      { allDay: true, leadMinutes: 0 },
      { dueDate: vnDate(2) },
      { ...allDay(2), allDay: 'yes' },
      { ...allDay(2), dueDate: '2026-1-5' },
      { ...allDay(2), dueDate: `${vnDate(2)}T00:00` },
      // 30 February of the next February: refused even though `dueAt` is "2 March".
      { ...allDay(2), dueDate: `${nextFeb}-02-30`, dueAt: endOf(`${nextFeb}-03-02`) },
      { ...allDay(5), dueAt: endOf(vnDate(2)) },
      { ...allDay(2), leadMinutes: 60 },
      allDay(-1),
      allDay(400),
    ];
    for (const overrides of bad) {
      const id = newId();
      await assertFails(setDoc(rem('dad', id), reminder('dad', id, overrides)));
    }
  });

  it('the assignee is an active Cùng nuôi or Người chăm sóc of this baby', async () => {
    for (const assigneeUid of ['aunt', 'gone', 'temp', 'stranger', '', 42]) {
      const id = newId();
      await assertFails(setDoc(rem('dad', id), reminder('dad', id, { assigneeUid })));
    }
  });

  it('old documents (no new keys) still read and edit as before', async () => {
    await assertSucceeds(getDoc(rem('nanny', SEEDED)));
    await assertSucceeds(updateDoc(rem('dad', SEEDED), { title: 'Mua sữa', ...stamp('dad') }));
  });

  it('a parent switches to all day, assigns, reassigns and unassigns', async () => {
    await assertSucceeds(updateDoc(rem('dad', SEEDED), { ...allDay(4), ...stamp('dad') }));
    await assertSucceeds(updateDoc(rem('dad', SEEDED), { assigneeUid: 'nanny', ...stamp('dad') }));
    await assertSucceeds(updateDoc(rem('mom', SEEDED), { assigneeUid: 'dad', ...stamp('mom') }));
    await assertFails(updateDoc(rem('mom', SEEDED), { assigneeUid: 'aunt', ...stamp('mom') }));
    await assertSucceeds(updateDoc(rem('mom', SEEDED), { assigneeUid: null, ...stamp('mom') }));
    // Back to a timed reminder.
    await assertSucceeds(
      updateDoc(rem('mom', SEEDED), {
        allDay: false,
        dueDate: null,
        dueAt: inHours(30),
        leadMinutes: 60,
        ...stamp('mom'),
      }),
    );
  });

  it('an older app moving an all-day reminder to an hourly lead is refused', async () => {
    await assertSucceeds(updateDoc(rem('dad', SEEDED), { ...allDay(4), ...stamp('dad') }));
    await assertFails(updateDoc(rem('dad', SEEDED), { leadMinutes: 60, ...stamp('dad') }));
  });

  it('an assignee who left does not block an edit that keeps them', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), `babies/b1/reminders/${SEEDED}`), {
        assigneeUid: 'gone',
      });
    });
    await assertSucceeds(updateDoc(rem('mom', SEEDED), { title: 'Mua tã', ...stamp('mom') }));
  });

  it('caregivers neither assign nor change the day; the assignee marks done', async () => {
    await assertFails(updateDoc(rem('nanny', SEEDED), { assigneeUid: 'nanny', ...stamp('nanny') }));
    await assertFails(updateDoc(rem('nanny', SEEDED), { ...allDay(4), ...stamp('nanny') }));
    const id = newId();
    await assertFails(
      setDoc(rem('nanny', id), reminder('nanny', id, { ...allDay(1), assigneeUid: 'nanny' })),
    );
    await assertSucceeds(updateDoc(rem('dad', SEEDED), { assigneeUid: 'nanny', ...stamp('dad') }));
    await assertSucceeds(
      updateDoc(rem('nanny', SEEDED), {
        done: true,
        doneAt: serverTimestamp(),
        doneBy: 'nanny',
        doneAuthor: author('nanny'),
        ...stamp('nanny'),
      }),
    );
  });
});

describe('rule reminders (v1.0 1a–1h, D-051)', () => {
  const RULE = `babies/b1/reminderRules/rr_${'a'.repeat(32)}`;
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, RULE), { type: 'feed', enabled: true, recipients: ['mom', 'nanny'] });
      await setDoc(doc(db, `${RULE}/occurrences/o1`), { outcome: 'logged' });
    });
  });
  const as = (uid: string) => env.authenticatedContext(uid).firestore();

  it('parents and caregivers read rules and their history', async () => {
    for (const uid of ['mom', 'nanny']) {
      await assertSucceeds(getDoc(doc(as(uid), RULE)));
      await assertSucceeds(getDocs(collection(as(uid), `${RULE}/occurrences`)));
    }
  });

  it('relatives and former members never', async () => {
    for (const uid of ['aunt', 'gone', 'stranger']) {
      await assertFails(getDoc(doc(as(uid), RULE)));
    }
  });

  it('nobody writes them directly: only the Functions do', async () => {
    await assertFails(updateDoc(doc(as('mom'), RULE), { enabled: false }));
    await assertFails(
      setDoc(doc(as('mom'), `babies/b1/reminderRules/rr_${'b'.repeat(32)}`), { type: 'feed' }),
    );
    await assertFails(deleteDoc(doc(as('mom'), RULE)));
    await assertFails(setDoc(doc(as('nanny'), `${RULE}/occurrences/o2`), { outcome: 'skipped' }));
  });
});
