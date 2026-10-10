import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  collectionGroup,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// Business map §5: who may read the baby profile, its restricted part and memberships.
const projectId = 'demo-child-life';
let env: RulesTestEnvironment;

const member = (uid: string, role: string, extra: Record<string, unknown> = {}) => ({
  uid,
  babyId: 'b1',
  role,
  status: 'active',
  relation: 'mother',
  displayName: uid,
  ...extra,
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
    await setDoc(doc(db, 'users/mom'), {
      displayName: 'Mai',
      ownedBabyCount: 1,
      ownedFamilyId: 'f1',
    });
    await setDoc(doc(db, 'families/f1'), { ownerUid: 'mom', quotaBytes: 1 });
    await setDoc(doc(db, 'babies/b1'), { nickname: 'Teddy', ownerUid: 'mom', familyId: 'f1' });
    await setDoc(doc(db, 'babies/b1/restricted/profile'), {
      dateOfBirth: '2026-09-17',
      gender: 'girl',
    });
    await setDoc(doc(db, 'babies/b1/members/mom'), member('mom', 'coParent', { isOwner: true }));
    await setDoc(doc(db, 'babies/b1/members/dad'), member('dad', 'coParent'));
    await setDoc(doc(db, 'babies/b1/members/nanny'), member('nanny', 'caregiver'));
    await setDoc(doc(db, 'babies/b1/members/grandma'), member('grandma', 'relative'));
    await setDoc(
      doc(db, 'babies/b1/members/aunt'),
      member('aunt', 'relative', { extraRights: { viewBabyInfo: true, viewDailyCare: false } }),
    );
    await setDoc(
      doc(db, 'babies/b1/members/gone'),
      member('gone', 'coParent', { status: 'removed' }),
    );
    await setDoc(doc(db, 'babies/b2'), { nickname: 'Na', ownerUid: 'other' });
  });
});

const as = (uid: string) => env.authenticatedContext(uid).firestore();

describe('baby profile', () => {
  it('every active member reads the member-visible profile', async () => {
    for (const uid of ['mom', 'dad', 'nanny', 'grandma', 'aunt']) {
      await assertSucceeds(getDoc(doc(as(uid), 'babies/b1')));
    }
  });

  it('strangers, signed-out users and removed members cannot read it', async () => {
    await assertFails(getDoc(doc(as('stranger'), 'babies/b1')));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'babies/b1')));
    await assertFails(getDoc(doc(as('gone'), 'babies/b1')));
    await assertFails(getDoc(doc(as('mom'), 'babies/b2')));
  });

  it('nobody writes babies, restricted profiles or memberships from the client', async () => {
    await assertFails(updateDoc(doc(as('mom'), 'babies/b1'), { nickname: 'X' }));
    await assertFails(setDoc(doc(as('mom'), 'babies/b3'), { nickname: 'New', ownerUid: 'mom' }));
    await assertFails(updateDoc(doc(as('mom'), 'babies/b1/restricted/profile'), { gender: 'boy' }));
    await assertFails(
      setDoc(doc(as('stranger'), 'babies/b1/members/stranger'), member('stranger', 'coParent')),
    );
    await assertFails(updateDoc(doc(as('nanny'), 'babies/b1/members/nanny'), { role: 'coParent' }));
  });

  it('cannot list babies', async () => {
    await assertFails(getDocs(collection(as('mom'), 'babies')));
  });
});

describe('restricted profile (DOB, gender)', () => {
  it('Cùng nuôi read it', async () => {
    await assertSucceeds(getDoc(doc(as('mom'), 'babies/b1/restricted/profile')));
    await assertSucceeds(getDoc(doc(as('dad'), 'babies/b1/restricted/profile')));
  });

  it('caregivers never read it', async () => {
    await assertFails(getDoc(doc(as('nanny'), 'babies/b1/restricted/profile')));
  });

  it('relatives read it only with "Thông tin bé" (viewBabyInfo)', async () => {
    await assertFails(getDoc(doc(as('grandma'), 'babies/b1/restricted/profile')));
    await assertSucceeds(getDoc(doc(as('aunt'), 'babies/b1/restricted/profile')));
  });

  it('removed members and strangers cannot read it', async () => {
    await assertFails(getDoc(doc(as('gone'), 'babies/b1/restricted/profile')));
    await assertFails(getDoc(doc(as('stranger'), 'babies/b1/restricted/profile')));
  });
});

describe('memberships', () => {
  it('everyone reads their own membership, even after removal (R-025)', async () => {
    await assertSucceeds(getDoc(doc(as('nanny'), 'babies/b1/members/nanny')));
    await assertSucceeds(getDoc(doc(as('gone'), 'babies/b1/members/gone')));
  });

  it('every active member sees the family list (14a, view only for non-parents); others cannot', async () => {
    await assertSucceeds(getDocs(collection(as('dad'), 'babies/b1/members')));
    await assertSucceeds(getDocs(collection(as('nanny'), 'babies/b1/members')));
    await assertSucceeds(getDoc(doc(as('grandma'), 'babies/b1/members/mom')));
    await assertFails(getDocs(collection(as('stranger'), 'babies/b1/members')));
    await assertFails(getDocs(collection(as('gone'), 'babies/b1/members')));
    await assertFails(getDoc(doc(as('gone'), 'babies/b1/members/mom')));
  });

  it('pending invites are visible to Cùng nuôi only', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'babies/b1/pendingInvites/i1'), { code: '482913' });
    });
    await assertSucceeds(getDocs(collection(as('dad'), 'babies/b1/pendingInvites')));
    await assertFails(getDocs(collection(as('nanny'), 'babies/b1/pendingInvites')));
    await assertFails(getDoc(doc(as('grandma'), 'babies/b1/pendingInvites/i1')));
    await assertFails(setDoc(doc(as('mom'), 'babies/b1/pendingInvites/i2'), { code: '111111' }));
  });

  it('access ends at "Thời hạn" even before the expiry job runs (R-024)', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), 'babies/b1/members/temp'),
        member('temp', 'caregiver', { accessUntilAt: new Date(Date.now() - 60_000) }),
      );
      await setDoc(
        doc(ctx.firestore(), 'babies/b1/members/later'),
        member('later', 'caregiver', { accessUntilAt: new Date(Date.now() + 86_400_000) }),
      );
    });
    await assertFails(getDoc(doc(as('temp'), 'babies/b1')));
    await assertSucceeds(getDoc(doc(as('later'), 'babies/b1')));
  });

  it('server-only invite collections are closed to clients', async () => {
    for (const path of [
      'invites/i1',
      'inviteCodes/482913',
      'inviteTokens/x',
      'mail/m1',
      'audit/a1',
      'rateLimits/r1',
    ]) {
      await assertFails(getDoc(doc(as('mom'), path)));
    }
  });

  it('"my babies" collection-group query works only for my own uid', async () => {
    await assertSucceeds(
      getDocs(query(collectionGroup(as('nanny'), 'members'), where('uid', '==', 'nanny'))),
    );
    await assertFails(
      getDocs(query(collectionGroup(as('nanny'), 'members'), where('uid', '==', 'mom'))),
    );
    await assertFails(getDocs(collectionGroup(as('nanny'), 'members')));
  });
});

describe('account and family documents', () => {
  it('users read only their own account document', async () => {
    await assertSucceeds(getDoc(doc(as('mom'), 'users/mom')));
    await assertFails(getDoc(doc(as('dad'), 'users/mom')));
    await assertFails(setDoc(doc(as('mom'), 'users/mom'), { ownedBabyCount: 0 }));
  });

  it('only the owner reads the family; nobody writes it', async () => {
    await assertSucceeds(getDoc(doc(as('mom'), 'families/f1')));
    await assertFails(getDoc(doc(as('dad'), 'families/f1')));
    await assertFails(updateDoc(doc(as('mom'), 'families/f1'), { quotaBytes: 99 }));
  });
});
