import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// Sổ tiêm chủng (P-133): Cùng nuôi write any dose, Người chăm sóc what they recorded, relatives
// with daily care only read; the plan is Cùng nuôi's; reminder bookkeeping is server-only.
const projectId = 'demo-child-life-vaccines';
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

function dose(uid: string, over: Record<string, unknown> = {}) {
  return {
    babyId: 'b1',
    vaccineId: 'rota',
    dose: 1,
    status: 'given',
    givenOn: '2026-11-17',
    givenTime: null,
    place: 'service',
    facility: null,
    reaction: null,
    declineReason: null,
    plannedOn: null,
    photoPath: null,
    createdBy: uid,
    author: author(uid),
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    updatedBy: uid,
    ...over,
  };
}

const plan = (uid: string, over: Record<string, unknown> = {}) => ({
  dtp: '6in1',
  setupDone: true,
  scheduleFrom: '2026-09-17',
  remind: true,
  recipients: ['mom', 'dad'],
  bookPhotos: [],
  updatedAt: serverTimestamp(),
  updatedBy: uid,
  ...over,
});

const as = (uid: string) => env.authenticatedContext(uid).firestore();

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
    await setDoc(doc(db, 'babies/b1/members/cousin'), member('cousin', 'relative'));
    await setDoc(doc(db, 'babies/b1/vaccines/bcg_1'), {
      ...dose('dad', { vaccineId: 'bcg', givenOn: '2026-09-18' }),
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  });
});

describe('doses', () => {
  it('Cùng nuôi and Người chăm sóc record a dose', async () => {
    await assertSucceeds(setDoc(doc(as('mom'), 'babies/b1/vaccines/rota_1'), dose('mom')));
    await assertSucceeds(
      setDoc(doc(as('nanny'), 'babies/b1/vaccines/pcv_1'), dose('nanny', { vaccineId: 'pcv' })),
    );
  });

  it('relatives read with daily care, never write', async () => {
    await assertSucceeds(getDoc(doc(as('aunt'), 'babies/b1/vaccines/bcg_1')));
    await assertFails(getDoc(doc(as('cousin'), 'babies/b1/vaccines/bcg_1')));
    await assertFails(setDoc(doc(as('aunt'), 'babies/b1/vaccines/rota_1'), dose('aunt')));
  });

  it('the key matches the dose, and the shape is checked', async () => {
    await assertFails(setDoc(doc(as('mom'), 'babies/b1/vaccines/rota_2'), dose('mom')));
    await assertFails(
      setDoc(doc(as('mom'), 'babies/b1/vaccines/rota_1'), dose('mom', { place: 'home' })),
    );
    await assertFails(
      setDoc(
        doc(as('mom'), 'babies/b1/vaccines/rota_1'),
        dose('mom', { reaction: 'x'.repeat(301) }),
      ),
    );
    // A declined dose has no date; a rescheduled one needs its new date.
    await assertFails(
      setDoc(doc(as('mom'), 'babies/b1/vaccines/rota_1'), dose('mom', { status: 'declined' })),
    );
    await assertSucceeds(
      setDoc(
        doc(as('mom'), 'babies/b1/vaccines/rota_1'),
        dose('mom', { status: 'planned', givenOn: null, plannedOn: '2026-11-25' }),
      ),
    );
  });

  it('a caregiver changes only what they recorded; Cùng nuôi anything', async () => {
    const stamp = (uid: string) => ({ updatedAt: serverTimestamp(), updatedBy: uid });
    await assertFails(
      updateDoc(doc(as('nanny'), 'babies/b1/vaccines/bcg_1'), {
        reaction: 'ok',
        ...stamp('nanny'),
      }),
    );
    await assertFails(deleteDoc(doc(as('nanny'), 'babies/b1/vaccines/bcg_1')));
    await assertSucceeds(
      updateDoc(doc(as('mom'), 'babies/b1/vaccines/bcg_1'), {
        reaction: 'Sốt nhẹ',
        ...stamp('mom'),
      }),
    );
    await assertFails(
      updateDoc(doc(as('mom'), 'babies/b1/vaccines/bcg_1'), { createdBy: 'mom', ...stamp('mom') }),
    );
    await assertSucceeds(deleteDoc(doc(as('mom'), 'babies/b1/vaccines/bcg_1')));
  });
});

describe('plan and reminders', () => {
  it('Cùng nuôi only write the plan; caregivers read it', async () => {
    await assertSucceeds(setDoc(doc(as('dad'), 'babies/b1/vaccinePlan/main'), plan('dad')));
    await assertSucceeds(getDoc(doc(as('nanny'), 'babies/b1/vaccinePlan/main')));
    await assertFails(setDoc(doc(as('nanny'), 'babies/b1/vaccinePlan/main'), plan('nanny')));
    await assertFails(setDoc(doc(as('mom'), 'babies/b1/vaccinePlan/other'), plan('mom')));
    await assertFails(
      setDoc(doc(as('mom'), 'babies/b1/vaccinePlan/main'), plan('mom', { dtp: '7in1' })),
    );
  });

  it('reminder bookkeeping is the server’s', async () => {
    await assertFails(getDoc(doc(as('mom'), 'babies/b1/vaccineReminders/x')));
    await assertFails(setDoc(doc(as('mom'), 'babies/b1/vaccineReminders/x'), { at: 1 }));
  });
});
