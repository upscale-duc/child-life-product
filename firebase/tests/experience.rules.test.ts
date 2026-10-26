import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { defaultExperience } from '@child-life/contracts';
import { deleteDoc, doc, getDoc, serverTimestamp, setDoc } from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// P-175 Adaptive Experience: `users/{uid}/experience/{babyId}` is one person's arrangement of one
// child's Hôm nay. Only its owner, only while an active member, only the contract's shape.
const projectId = 'demo-child-life-experience-rules';
let env: RulesTestEnvironment;

const member = (uid: string, role: string, extra: Record<string, unknown> = {}) => ({
  uid,
  role,
  status: 'active',
  relation: 'other',
  relationCustom: null,
  displayName: uid,
  ...extra,
});

const exp = (over: Record<string, unknown> = {}) => ({
  ...defaultExperience('b3_6', 'b1'),
  updatedAt: serverTimestamp(),
  ...over,
});

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
    await setDoc(doc(db, 'babies/b1'), { familyId: 'f1', ownerUid: 'mom' });
    await setDoc(doc(db, 'babies/b1/members/mom'), member('mom', 'coParent', { isOwner: true }));
    await setDoc(doc(db, 'babies/b1/members/nanny'), member('nanny', 'caregiver'));
    await setDoc(doc(db, 'babies/b1/members/grandma'), member('grandma', 'relative'));
    await setDoc(
      doc(db, 'babies/b1/members/gone'),
      member('gone', 'caregiver', { status: 'removed' }),
    );
  });
});

const as = (uid: string) => env.authenticatedContext(uid).firestore();
const ref = (who: string, owner = who, baby = 'b1') =>
  doc(as(who), `users/${owner}/experience/${baby}`);

describe('experience: who', () => {
  it('every active role writes and reads its own arrangement', async () => {
    for (const uid of ['mom', 'nanny', 'grandma']) {
      await assertSucceeds(setDoc(ref(uid), exp()));
      await assertSucceeds(getDoc(ref(uid)));
      await assertSucceeds(deleteDoc(ref(uid)));
    }
  });

  it('nobody reads or writes someone else’s', async () => {
    await assertSucceeds(setDoc(ref('mom'), exp()));
    await assertFails(getDoc(ref('nanny', 'mom')));
    await assertFails(setDoc(ref('nanny', 'mom'), exp()));
    await assertFails(
      getDoc(doc(env.unauthenticatedContext().firestore(), 'users/mom/experience/b1')),
    );
  });

  it('a removed member or a stranger cannot write one for the baby', async () => {
    await assertFails(setDoc(ref('gone'), exp()));
    await assertFails(setDoc(ref('stranger'), exp()));
  });
});

describe('experience: shape (experienceSchema)', () => {
  it('accepts a full arrangement', async () => {
    await assertSucceeds(
      setDoc(
        ref('mom'),
        exp({
          goals: ['memories', 'spending', 'growth_vaccines'],
          goalsSource: 'chosen',
          order: ['reminders', 'moment_today'],
          pinned: ['moment_today'],
          shown: ['growth'],
          hidden: ['tiles'],
          stagePrompts: { m12: 'applied', m36: 'kept' },
        }),
      ),
    );
  });

  it('accepts "Ai đang trông bé" (care_duty, P-181) in every list', async () => {
    await assertSucceeds(
      setDoc(
        ref('mom'),
        exp({
          order: ['care_duty', 'tiles'],
          pinned: ['care_duty'],
          shown: ['care_duty'],
          hidden: ['care_duty'],
        }),
      ),
    );
  });

  it('rejects unknown ids, duplicates, extra fields and a client clock', async () => {
    await assertFails(setDoc(ref('mom'), exp({ hidden: ['learning'] })));
    await assertFails(setDoc(ref('mom'), exp({ pinned: ['tiles', 'tiles'] })));
    await assertFails(setDoc(ref('mom'), exp({ goals: ['projects'] })));
    await assertFails(setDoc(ref('mom'), exp({ bandApplied: 'b12_18' })));
    await assertFails(setDoc(ref('mom'), exp({ stagePrompts: { m144: 'kept' } })));
    await assertFails(setDoc(ref('mom'), exp({ stagePrompts: { m12: 'later' } })));
    await assertFails(setDoc(ref('mom'), exp({ childName: 'Na' })));
    await assertFails(setDoc(ref('mom'), exp({ updatedAt: new Date() })));
    await assertFails(setDoc(ref('mom'), exp({ v: 2 })));
    await assertFails(setDoc(ref('mom'), exp({ babyId: 'b2' })));
  });
});
