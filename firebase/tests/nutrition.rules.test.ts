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
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// Vitamin A rounds taken (D-083, plan §3, 9g): `babies/{b}/nutrition/vitaminA` is read by every
// active member and written by Cùng nuôi only, as `{ taken: { "YYYY-MM": "YYYY-MM-DD" },
// updatedAt: request.time, updatedBy: me }`; nothing else lives under `nutrition`.
const projectId = 'demo-child-life-nutrition';
let env: RulesTestEnvironment;

const member = (uid: string, role: string, extra: Record<string, unknown> = {}) => ({
  uid,
  babyId: 'b1',
  role,
  status: 'active',
  relation: 'other',
  relationCustom: null,
  displayName: uid,
  ...extra,
});
const record = (uid: string, taken: unknown = { '2026-06': '2026-06-01' }, over = {}) => ({
  taken,
  updatedAt: serverTimestamp(),
  updatedBy: uid,
  ...over,
});
const as = (uid: string) => env.authenticatedContext(uid).firestore();
const PATH = 'babies/b1/nutrition/vitaminA';

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
    await setDoc(doc(db, 'babies/b1/members/cousin'), member('cousin', 'relative'));
    await setDoc(doc(db, 'babies/b1/members/ex'), member('ex', 'coParent', { status: 'removed' }));
    await setDoc(
      doc(db, 'babies/b1/members/late'),
      member('late', 'coParent', { accessUntilAt: new Date('2020-01-01T00:00:00Z') }),
    );
    await setDoc(doc(db, PATH), {
      taken: { '2025-12': '2025-12-01' },
      updatedAt: new Date(),
      updatedBy: 'dad',
    });
    await setDoc(doc(db, 'babies/b1/nutrition/other'), { x: 1 });
  });
});

describe('vitamin A record', () => {
  it('every active member reads it; nobody else', async () => {
    for (const uid of ['mom', 'dad', 'nanny', 'cousin']) {
      await assertSucceeds(getDoc(doc(as(uid), PATH)));
    }
    for (const uid of ['ex', 'late', 'stranger']) await assertFails(getDoc(doc(as(uid), PATH)));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), PATH)));
  });

  it('Cùng nuôi mark, unmark and clear rounds as themselves', async () => {
    await assertSucceeds(
      setDoc(
        doc(as('mom'), PATH),
        record('mom', { '2025-12': '2025-12-01', '2026-06': '2026-06-02' }),
      ),
    );
    await assertSucceeds(
      updateDoc(doc(as('dad'), PATH), {
        taken: { '2025-12': '2025-12-01' },
        updatedAt: serverTimestamp(),
        updatedBy: 'dad',
      }),
    );
    await assertSucceeds(setDoc(doc(as('mom'), PATH), record('mom', {})));
    await assertSucceeds(deleteDoc(doc(as('mom'), PATH)));
    await assertSucceeds(setDoc(doc(as('dad'), PATH), record('dad')));
  });

  it('caregivers, relatives, former and expired members never write', async () => {
    for (const uid of ['nanny', 'cousin', 'ex', 'late', 'stranger']) {
      await assertFails(setDoc(doc(as(uid), PATH), record(uid)));
    }
    await assertFails(deleteDoc(doc(as('nanny'), PATH)));
  });

  it('checks the shape: month keys, date values, author, server time, no other fields', async () => {
    const bad: unknown[] = [
      { '2026-13': '2026-06-01' },
      { '2026-6': '2026-06-01' },
      { '2026-00': '2026-06-01' },
      { june: '2026-06-01' },
      { '2026-06': '1/6/2026' },
      { '2026-06': '2026-06-32' },
      { '2026-06': 20260601 },
      { '2026-06': null },
      ['2026-06'],
      '2026-06',
    ];
    for (const taken of bad) await assertFails(setDoc(doc(as('mom'), PATH), record('mom', taken)));
    await assertFails(setDoc(doc(as('mom'), PATH), record('dad')));
    await assertFails(
      setDoc(doc(as('mom'), PATH), record('mom', undefined, { updatedAt: new Date() })),
    );
    await assertFails(setDoc(doc(as('mom'), PATH), record('mom', undefined, { note: 'x' })));
    await assertFails(
      setDoc(doc(as('mom'), PATH), { taken: {}, updatedBy: 'mom' } as Record<string, unknown>),
    );
  });

  it('holds up to 16 rounds, each one checked', async () => {
    const months = Array.from({ length: 16 }, (_, i) => {
      const y = 2025 + Math.floor(i / 12);
      const m = String((i % 12) + 1).padStart(2, '0');
      return [`${y}-${m}`, `${y}-${m}-01`] as const;
    });
    await assertSucceeds(setDoc(doc(as('mom'), PATH), record('mom', Object.fromEntries(months))));
    const lastBad = Object.fromEntries([...months.slice(0, 15), ['2026-04', 'soon']]);
    await assertFails(setDoc(doc(as('mom'), PATH), record('mom', lastBad)));
    const tooMany = Object.fromEntries([...months, ['2027-01', '2027-01-01']]);
    await assertFails(setDoc(doc(as('mom'), PATH), record('mom', tooMany)));
  });

  it('only the vitaminA document, never listed; locked while the profile is deleted', async () => {
    await assertFails(getDoc(doc(as('mom'), 'babies/b1/nutrition/other')));
    await assertFails(setDoc(doc(as('mom'), 'babies/b1/nutrition/vitaminD'), record('mom')));
    await assertFails(getDocs(collection(as('mom'), 'babies/b1/nutrition')));
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), 'babies/b1'), { state: 'deleting' });
    });
    await assertSucceeds(getDoc(doc(as('mom'), PATH)));
    await assertFails(setDoc(doc(as('mom'), PATH), record('mom')));
  });
});
