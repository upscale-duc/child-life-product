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
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// Premium Slice 3 (plan §5.5, §6.1): AI consent is read by its owner and written only by the
// callable; stored summaries are server-only (M04) and read by history.read roles (moment
// summaries by Cùng nuôi only); NL07b episodes are confirmed and closed by Cùng nuôi / Người
// chăm sóc as themselves, never deleted, no cross-family writes (M03).
const projectId = 'demo-child-life-ai-rules';
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

let seq = 0;
const epId = () => `ep_${(++seq).toString(16).padStart(32, '0')}`;
const ciRef = `ci_${'a'.repeat(32)}`;

const episode = (uid: string, id: string, over: Record<string, unknown> = {}) => ({
  id,
  babyId: 'b1',
  startDate: '2026-10-12',
  endDate: null,
  confirmedBy: uid,
  checkInIds: [ciRef],
  status: 'open',
  closedBy: null,
  createdAt: serverTimestamp(),
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
    await setDoc(doc(db, 'babies/b2'), { familyId: 'f2', ownerUid: 'other' });
    await setDoc(doc(db, 'babies/b1/members/mom'), member('mom', 'coParent', { isOwner: true }));
    await setDoc(doc(db, 'babies/b1/members/nanny'), member('nanny', 'caregiver'));
    await setDoc(doc(db, 'babies/b1/members/grandma'), member('grandma', 'relative'));
    await setDoc(
      doc(db, 'babies/b1/members/aunt'),
      member('aunt', 'relative', { extraRights: { viewBabyInfo: false, viewDailyCare: true } }),
    );
    await setDoc(doc(db, 'babies/b2/members/other'), member('other', 'coParent'));
    await setDoc(doc(db, 'users/mom/settings/ai'), {
      consent: { version: 'ai-consent-v1', grantedAt: new Date(), shareMyNotes: true },
      updatedAt: new Date(),
    });
    await setDoc(doc(db, 'babies/b1/summaries/su_handover'), {
      id: 'su_handover',
      kind: 'handover',
      status: 'ready',
    });
    await setDoc(doc(db, 'babies/b1/summaries/su_moment'), {
      id: 'su_moment',
      kind: 'moment',
      status: 'ready',
    });
    await setDoc(doc(db, 'babies/b1/episodes/ep_open'), {
      ...episode('nanny', 'ep_open'),
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  });
});

const as = (uid: string) => env.authenticatedContext(uid).firestore();

describe('users/{uid}/settings/ai (consent)', () => {
  it('the owner reads it; nobody else does', async () => {
    await assertSucceeds(getDoc(doc(as('mom'), 'users/mom/settings/ai')));
    await assertFails(getDoc(doc(as('nanny'), 'users/mom/settings/ai')));
  });

  it('even the owner cannot write it: only setAiConsent does', async () => {
    const body = {
      consent: { version: 'ai-consent-v1', grantedAt: serverTimestamp(), shareMyNotes: true },
      updatedAt: serverTimestamp(),
    };
    await assertFails(setDoc(doc(as('nanny'), 'users/nanny/settings/ai'), body));
    await assertFails(updateDoc(doc(as('mom'), 'users/mom/settings/ai'), { consent: null }));
    await assertFails(deleteDoc(doc(as('mom'), 'users/mom/settings/ai')));
  });
});

describe('babies/{b}/summaries (server-only, M04)', () => {
  it('history.read roles read the handover; relatives without daily care and strangers do not', async () => {
    for (const uid of ['mom', 'nanny', 'aunt']) {
      await assertSucceeds(getDoc(doc(as(uid), 'babies/b1/summaries/su_handover')));
    }
    for (const uid of ['grandma', 'other']) {
      await assertFails(getDoc(doc(as(uid), 'babies/b1/summaries/su_handover')));
    }
  });

  it('a moment summary stays with Cùng nuôi', async () => {
    await assertSucceeds(getDoc(doc(as('mom'), 'babies/b1/summaries/su_moment')));
    await assertFails(getDoc(doc(as('nanny'), 'babies/b1/summaries/su_moment')));
    await assertFails(getDocs(collection(as('nanny'), 'babies/b1/summaries')));
    await assertSucceeds(
      getDocs(
        query(collection(as('nanny'), 'babies/b1/summaries'), where('kind', '==', 'handover')),
      ),
    );
  });

  it('no client writes, not even Cùng nuôi', async () => {
    await assertFails(
      setDoc(doc(as('mom'), 'babies/b1/summaries/su_x'), { kind: 'handover', method: 'ai' }),
    );
    await assertFails(
      updateDoc(doc(as('mom'), 'babies/b1/summaries/su_handover'), { method: 'ai' }),
    );
    await assertFails(deleteDoc(doc(as('mom'), 'babies/b1/summaries/su_handover')));
  });

  it('AI reports and the quota ledger are closed to clients', async () => {
    await assertFails(getDoc(doc(as('mom'), 'aiReports/air_x')));
    await assertFails(setDoc(doc(as('mom'), 'aiReports/air_x'), { problem: 'other' }));
    await assertFails(getDoc(doc(as('mom'), 'families/f1/quota/ai_month_cal_2026-10')));
    await assertFails(getDoc(doc(as('mom'), 'families/f1/quotaOps/su_x')));
  });
});

describe('babies/{b}/episodes (NL07b)', () => {
  it('Cùng nuôi and Người chăm sóc confirm an episode as themselves', async () => {
    for (const uid of ['mom', 'nanny']) {
      const id = epId();
      await assertSucceeds(setDoc(doc(as(uid), `babies/b1/episodes/${id}`), episode(uid, id)));
    }
  });

  it('relatives, strangers and other families cannot (M03)', async () => {
    for (const uid of ['grandma', 'aunt', 'other']) {
      const id = epId();
      await assertFails(setDoc(doc(as(uid), `babies/b1/episodes/${id}`), episode(uid, id)));
    }
    const id = epId();
    await assertFails(
      setDoc(doc(as('mom'), `babies/b2/episodes/${id}`), episode('mom', id, { babyId: 'b2' })),
    );
    await assertFails(
      setDoc(doc(as('mom'), `babies/b1/episodes/${id}`), episode('mom', id, { babyId: 'b2' })),
    );
  });

  it('shape: open, confirmed by the caller, check-ins listed, no extra fields', async () => {
    const bad: Record<string, unknown>[] = [
      { confirmedBy: 'nanny' },
      { status: 'closed' },
      { endDate: '2026-10-14' },
      { closedBy: 'mom' },
      { checkInIds: [] },
      { startDate: '14/10/2026' },
      { note: 'x' },
    ];
    for (const over of bad) {
      const id = epId();
      await assertFails(
        setDoc(doc(as('mom'), `babies/b1/episodes/${id}`), episode('mom', id, over)),
      );
    }
    await assertFails(
      setDoc(doc(as('mom'), 'babies/b1/episodes/ep_bad'), episode('mom', 'ep_bad')),
    );
  });

  it('closing: once, by a logger, as themselves, end not before start', async () => {
    const ref = (uid: string) => doc(as(uid), 'babies/b1/episodes/ep_open');
    await assertFails(
      updateDoc(ref('mom'), {
        status: 'closed',
        endDate: '2026-10-10',
        closedBy: 'mom',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(ref('mom'), {
        status: 'closed',
        endDate: '2026-10-14',
        closedBy: 'nanny',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(ref('aunt'), {
        status: 'closed',
        endDate: '2026-10-14',
        closedBy: 'aunt',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(ref('mom'), {
        checkInIds: [ciRef, `ci_${'b'.repeat(32)}`],
        updatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      updateDoc(ref('mom'), {
        status: 'closed',
        endDate: '2026-10-14',
        closedBy: 'mom',
        updatedAt: serverTimestamp(),
      }),
    );
    // Closed is final.
    await assertFails(
      updateDoc(ref('nanny'), {
        status: 'closed',
        endDate: '2026-10-15',
        closedBy: 'nanny',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('read by history.read roles; never deleted by a client', async () => {
    for (const uid of ['mom', 'nanny', 'aunt']) {
      await assertSucceeds(getDoc(doc(as(uid), 'babies/b1/episodes/ep_open')));
    }
    for (const uid of ['grandma', 'other']) {
      await assertFails(getDoc(doc(as(uid), 'babies/b1/episodes/ep_open')));
    }
    await assertFails(deleteDoc(doc(as('nanny'), 'babies/b1/episodes/ep_open')));
  });
});
