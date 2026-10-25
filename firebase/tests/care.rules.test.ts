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
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// S4 care records: who logs, reads, edits and deletes (business map §5, 12a, Q-012 → D-022,
// D-018) and the record shape (packages/contracts/src/care.ts).
const projectId = 'demo-child-life';
let env: RulesTestEnvironment;

const member = (
  uid: string,
  role: string,
  relation: string,
  extra: Record<string, unknown> = {},
) => ({
  uid,
  babyId: 'b1',
  role,
  status: 'active',
  relation,
  relationCustom: null,
  displayName: uid,
  ...extra,
});

const relations: Record<string, string> = {
  mom: 'mother',
  dad: 'father',
  nanny: 'nanny',
  grandma: 'grandmother',
  aunt: 'relative',
};

let seq = 0;
const newId = () => `r_${(++seq).toString(16).padStart(32, '0')}`;

/** A valid new bottle record by [uid] (overrides merged last). */
function record(uid: string, id: string, overrides: Record<string, unknown> = {}) {
  return {
    id,
    babyId: 'b1',
    type: 'bottle',
    occurredAt: Timestamp.fromDate(new Date(Date.now() - 45 * 60_000)),
    endedAt: null,
    data: { amountMl: 120, milk: 'breastMilk' },
    createdBy: uid,
    author: { name: uid, relation: relations[uid] ?? 'other', relationCustom: null },
    createdAt: serverTimestamp(),
    clientCreatedAt: Timestamp.now(),
    updatedAt: serverTimestamp(),
    updatedBy: uid,
    deleted: false,
    deletedAt: null,
    deletedBy: null,
    source: 'app',
    ...overrides,
  };
}

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
    await setDoc(
      doc(db, 'babies/b1/members/mom'),
      member('mom', 'coParent', 'mother', { isOwner: true }),
    );
    await setDoc(doc(db, 'babies/b1/members/dad'), member('dad', 'coParent', 'father'));
    await setDoc(doc(db, 'babies/b1/members/nanny'), member('nanny', 'caregiver', 'nanny'));
    await setDoc(
      doc(db, 'babies/b1/members/grandma'),
      member('grandma', 'relative', 'grandmother'),
    );
    await setDoc(
      doc(db, 'babies/b1/members/aunt'),
      member('aunt', 'relative', 'relative', {
        extraRights: { viewBabyInfo: false, viewDailyCare: true },
      }),
    );
    await setDoc(
      doc(db, 'babies/b1/members/gone'),
      member('gone', 'caregiver', 'nanny', { status: 'removed' }),
    );
    await setDoc(doc(db, 'babies/b1/records/r_mom'), {
      ...record('mom', 'r_mom'),
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
    await setDoc(doc(db, 'babies/b1/records/r_nanny'), {
      ...record('nanny', 'r_nanny'),
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
    await setDoc(doc(db, 'babies/b1/days/2026-10-08'), { bottle: { count: 2, ml: 240 } });
  });
});

const as = (uid: string) => env.authenticatedContext(uid).firestore();
const rec = (uid: string, id: string) => doc(as(uid), `babies/b1/records/${id}`);

describe('logging (12a: parents and caregivers; relatives never)', () => {
  it('Cùng nuôi and Người chăm sóc create records with their own attribution', async () => {
    for (const uid of ['mom', 'dad', 'nanny']) {
      const id = newId();
      await assertSucceeds(setDoc(rec(uid, id), record(uid, id)));
    }
  });

  it('relatives, removed members and strangers cannot log', async () => {
    for (const uid of ['grandma', 'aunt', 'gone', 'stranger']) {
      const id = newId();
      await assertFails(setDoc(rec(uid, id), record(uid, id)));
    }
  });

  it('attribution and authorship cannot be forged', async () => {
    const id = newId();
    await assertFails(setDoc(rec('nanny', id), record('nanny', id, { createdBy: 'mom' })));
    await assertFails(
      setDoc(
        rec('nanny', id),
        record('nanny', id, {
          author: { name: 'nanny', relation: 'mother', relationCustom: null },
        }),
      ),
    );
    await assertFails(
      setDoc(rec('nanny', id), record('nanny', id, { createdAt: Timestamp.now() })),
    );
  });

  it('shapes and ranges follow the contract (G-021: no future times)', async () => {
    const bad: Record<string, unknown>[] = [
      { data: { amountMl: 0, milk: 'formula' } },
      { data: { amountMl: 120.5, milk: 'formula' } },
      { data: { amountMl: 120, milk: 'juice' } },
      { data: { amountMl: 120, milk: 'formula', note: 'x' } },
      { occurredAt: Timestamp.fromDate(new Date(Date.now() + 60 * 60_000)) },
      { type: 'pump', data: { side: 'both', amountMl: null, durationMin: 15 } },
      { type: 'sleep', data: {} },
      { deleted: true },
      { source: 'widget' },
    ];
    for (const overrides of bad) {
      const id = newId();
      await assertFails(setDoc(rec('mom', id), record('mom', id, overrides)));
    }
    await assertFails(setDoc(rec('mom', 'r_bad'), record('mom', 'r_bad')));

    const good: Record<string, unknown>[] = [
      { data: { amountMl: null, milk: 'formula' } },
      { type: 'breast', data: { side: 'left', durationMin: 15 } },
      { type: 'breast', data: { side: 'both', durationMin: null } },
      { type: 'pump', data: { side: 'both', amountMl: 90, durationMin: 15 } },
      { type: 'diaper', data: { kind: 'both' } },
      { type: 'growth', data: { weightKg: 4.3, lengthCm: 54.5, measuredOn: '2026-10-08' } },
      { type: 'growth', data: { weightKg: 4, lengthCm: null, measuredOn: '2026-10-08' } },
    ];
    for (const overrides of good) {
      const id = newId();
      await assertSucceeds(setDoc(rec('dad', id), record('dad', id, overrides)));
    }
  });
});

describe('growth head circumference (owner 2026-10-16)', () => {
  const growth = (data: Record<string, unknown>) => ({
    type: 'growth',
    data: { weightKg: 5.2, lengthCm: 58, measuredOn: '2026-10-08', ...data },
  });
  const seedOld = async (id: string) =>
    env.withSecurityRulesDisabled(async (ctx) => {
      // A record written before the field (no headCm key), as older apps still write it.
      await setDoc(doc(ctx.firestore(), `babies/b1/records/${id}`), {
        ...record('mom', id, growth({})),
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      });
    });

  it('old records and old apps (no key) keep working; new apps may add 20…60 cm', async () => {
    for (const data of [{}, { headCm: 39 }, { headCm: 38.5 }, { headCm: null }, { headCm: 20 }]) {
      const id = newId();
      await assertSucceeds(setDoc(rec('mom', id), record('mom', id, growth(data))));
    }
    for (const data of [{ headCm: 19.9 }, { headCm: 61 }, { headCm: '39' }, { head: 39 }]) {
      const id = newId();
      await assertFails(setDoc(rec('mom', id), record('mom', id, growth(data))));
    }
  });

  it('editing an old record may add the head circumference, or keep it absent', async () => {
    await seedOld('r_growth_old');
    const edit = (data: Record<string, unknown>) =>
      updateDoc(rec('dad', 'r_growth_old'), {
        data: growth(data).data,
        updatedAt: serverTimestamp(),
        updatedBy: 'dad',
      });
    await assertSucceeds(edit({ headCm: 40.2 }));
    // An older app's edit sends the three keys only.
    await assertSucceeds(edit({}));
    await assertFails(edit({ headCm: 75 }));
  });
});

describe('reading (D-018: relatives only with daily care)', () => {
  it('parents, caregivers and relatives with "Chăm sóc hằng ngày" read records and days', async () => {
    for (const uid of ['mom', 'nanny', 'aunt']) {
      await assertSucceeds(
        getDocs(query(collection(as(uid), 'babies/b1/records'), where('deleted', '==', false))),
      );
      await assertSucceeds(getDoc(doc(as(uid), 'babies/b1/days/2026-10-08')));
    }
  });

  it('other relatives, removed members and strangers do not', async () => {
    for (const uid of ['grandma', 'gone', 'stranger']) {
      await assertFails(getDoc(rec(uid, 'r_mom')));
      await assertFails(getDoc(doc(as(uid), 'babies/b1/days/2026-10-08')));
    }
  });

  it('nobody writes day summaries', async () => {
    await assertFails(
      setDoc(doc(as('mom'), 'babies/b1/days/2026-10-09'), { bottle: { count: 1 } }),
    );
  });
});

describe('editing and deleting (Q-012 → D-022)', () => {
  const edit = { data: { amountMl: 150, milk: 'formula' }, updatedAt: serverTimestamp() };

  it('any Cùng nuôi edits any record; a caregiver only their own', async () => {
    await assertSucceeds(updateDoc(rec('dad', 'r_mom'), { ...edit, updatedBy: 'dad' }));
    await assertSucceeds(updateDoc(rec('mom', 'r_nanny'), { ...edit, updatedBy: 'mom' }));
    await assertSucceeds(updateDoc(rec('nanny', 'r_nanny'), { ...edit, updatedBy: 'nanny' }));
    await assertFails(updateDoc(rec('nanny', 'r_mom'), { ...edit, updatedBy: 'nanny' }));
    await assertFails(updateDoc(rec('aunt', 'r_mom'), { ...edit, updatedBy: 'aunt' }));
  });

  it('type, author and creation time never change; edits stay valid', async () => {
    await assertFails(
      updateDoc(rec('mom', 'r_mom'), {
        type: 'diaper',
        updatedBy: 'mom',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(rec('mom', 'r_mom'), {
        createdBy: 'dad',
        updatedBy: 'mom',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(rec('mom', 'r_mom'), {
        data: { amountMl: 9000, milk: 'formula' },
        updatedBy: 'mom',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('delete is a soft delete with undo; hard deletes are refused', async () => {
    const soft = {
      deleted: true,
      deletedAt: serverTimestamp(),
      deletedBy: 'nanny',
      updatedBy: 'nanny',
      updatedAt: serverTimestamp(),
    };
    await assertFails(updateDoc(rec('nanny', 'r_mom'), soft));
    await assertSucceeds(updateDoc(rec('nanny', 'r_nanny'), soft));
    await assertFails(updateDoc(rec('nanny', 'r_nanny'), { ...edit, updatedBy: 'nanny' }));
    await assertSucceeds(
      updateDoc(rec('nanny', 'r_nanny'), {
        deleted: false,
        deletedAt: null,
        deletedBy: null,
        updatedBy: 'nanny',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(deleteDoc(rec('mom', 'r_mom')));
  });
});

describe('sleep and timers (S5)', () => {
  const sleep = (start: number, end: number | null) => ({
    type: 'sleep',
    data: {},
    occurredAt: Timestamp.fromDate(new Date(Date.now() - start * 60_000)),
    endedAt: end === null ? null : Timestamp.fromDate(new Date(Date.now() - end * 60_000)),
  });

  it('a sleep needs an end, after its start, within 24 h', async () => {
    for (const [ok, s] of [
      [true, sleep(90, 10)],
      [false, sleep(90, null)],
      [false, sleep(10, 90)],
      [false, sleep(26 * 60, 10)],
    ] as const) {
      const id = newId();
      const write = setDoc(rec('nanny', id), record('nanny', id, s));
      await (ok ? assertSucceeds(write) : assertFails(write));
    }
  });

  it('breastfeeds from the timer carry per-side minutes', async () => {
    const id = newId();
    await assertSucceeds(
      setDoc(
        rec('mom', id),
        record('mom', id, {
          type: 'breast',
          data: { side: 'both', durationMin: 12, leftMin: 8, rightMin: 4, endSide: 'right' },
        }),
      ),
    );
  });

  const timer = (uid: string, type: string, extra: Record<string, unknown> = {}) => ({
    type,
    babyId: 'b1',
    sessionId: 'a'.repeat(32),
    startedAt: Timestamp.fromDate(new Date(Date.now() - 5 * 60_000)),
    startedBy: uid,
    author: { name: uid, relation: relations[uid] ?? 'other', relationCustom: null },
    sides:
      type === 'sleep'
        ? null
        : {
            left: { accumulatedMs: 0, runningSince: Timestamp.now() },
            right: { accumulatedMs: 0, runningSince: null },
          },
    paused: false,
    pausedSides: [],
    updatedAt: serverTimestamp(),
    updatedBy: uid,
    ...extra,
  });
  const slot = (uid: string, type: string) => doc(as(uid), `babies/b1/timers/${type}`);

  it('parents and caregivers start one shared timer per type; relatives cannot', async () => {
    await assertSucceeds(setDoc(slot('dad', 'sleep'), timer('dad', 'sleep')));
    await assertSucceeds(setDoc(slot('nanny', 'breast'), timer('nanny', 'breast')));
    await assertFails(setDoc(slot('aunt', 'pump'), timer('aunt', 'pump')));
    await assertFails(setDoc(slot('mom', 'bottle'), timer('mom', 'bottle')));
    // everyone who sees care sees it running ("Cả nhà đang thấy")
    await assertSucceeds(getDoc(doc(as('aunt'), 'babies/b1/timers/sleep')));
    await assertFails(getDoc(doc(as('grandma'), 'babies/b1/timers/sleep')));
  });

  it('a second start does not take over the slot (P-011); updates keep the session', async () => {
    await assertSucceeds(setDoc(slot('dad', 'sleep'), timer('dad', 'sleep')));
    await assertFails(
      setDoc(slot('mom', 'sleep'), timer('mom', 'sleep', { sessionId: 'b'.repeat(32) })),
    );
    await assertSucceeds(
      updateDoc(slot('mom', 'sleep'), {
        startedAt: Timestamp.fromDate(new Date(Date.now() - 20 * 60_000)),
        updatedAt: serverTimestamp(),
        updatedBy: 'mom',
      }),
    );
    await assertFails(
      updateDoc(slot('mom', 'sleep'), {
        startedBy: 'mom',
        updatedAt: serverTimestamp(),
        updatedBy: 'mom',
      }),
    );
    await assertSucceeds(deleteDoc(slot('mom', 'sleep')));
  });

  it('conflicts are read-only for clients', async () => {
    await assertFails(setDoc(doc(as('mom'), 'babies/b1/conflicts/x'), { status: 'open' }));
  });
});

describe('write seats (PV44, D-101 Q-101)', () => {
  it('a writer left out after a downgrade reads but no longer logs or edits', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), 'babies/b1/members/nanny'), { writeSuspended: true });
    });
    const id = newId();
    await assertFails(setDoc(rec('nanny', id), record('nanny', id)));
    await assertFails(updateDoc(rec('nanny', 'r_nanny'), { 'data.amountMl': 90 }));
    await assertSucceeds(getDoc(rec('nanny', 'r_mom')));
    // Others keep writing; the flag is never the member's to clear.
    const dadId = newId();
    await assertSucceeds(setDoc(rec('dad', dadId), record('dad', dadId)));
    await assertFails(
      updateDoc(doc(as('nanny'), 'babies/b1/members/nanny'), { writeSuspended: false }),
    );
  });
});
