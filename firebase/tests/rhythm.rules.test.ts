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

// Nhịp lớn lên (plan §6.1, §7.1, D-072 #2): check-ins and feedback written by the phone, by
// Cùng nuôi and Người chăm sóc as themselves; recommendations and facts server-only (M04); no
// cross-family writes (M03); reads by history.read roles; per-person preferences.
const projectId = 'demo-child-life-rhythm-rules';
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
const hex = () => (++seq).toString(16).padStart(32, '0');
const ciId = () => `ci_${hex()}`;
const fbId = () => `fb_${hex()}`;

function checkIn(uid: string, id: string, over: Record<string, unknown> = {}) {
  return {
    id,
    babyId: 'b1',
    date: '2026-10-14',
    authorUid: uid,
    observation: 'sleep',
    when: 'night',
    since: 'days_2_3',
    tried: ['rocking'],
    healthSigns: [],
    note: null,
    revision: 1,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...over,
  };
}

function feedback(uid: string, id: string, over: Record<string, unknown> = {}) {
  return {
    id,
    babyId: 'b1',
    authorUid: uid,
    contentId: 'act_sleep_dim',
    contentVersion: 1,
    kind: 'helpful',
    date: '2026-10-14',
    note: null,
    createdAt: serverTimestamp(),
    ...over,
  };
}

const prefs = (over: Record<string, unknown> = {}) => ({
  interests: ['sleep'],
  digestTime: '20:30',
  quietHours: { from: '22:00', to: '06:00' },
  fewer: [],
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
    await setDoc(doc(db, 'babies/b1/members/dad'), member('dad', 'coParent'));
    await setDoc(doc(db, 'babies/b1/members/nanny'), member('nanny', 'caregiver'));
    await setDoc(doc(db, 'babies/b1/members/grandma'), member('grandma', 'relative'));
    await setDoc(
      doc(db, 'babies/b1/members/aunt'),
      member('aunt', 'relative', { extraRights: { viewBabyInfo: false, viewDailyCare: true } }),
    );
    await setDoc(
      doc(db, 'babies/b1/members/gone'),
      member('gone', 'caregiver', { status: 'removed' }),
    );
    await setDoc(doc(db, 'babies/b2/members/other'), member('other', 'coParent'));
    await setDoc(doc(db, 'babies/b1/checkins/ci_mom'), {
      ...checkIn('mom', 'ci_mom'),
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    });
    await setDoc(doc(db, 'babies/b1/recFeedback/fb_mom'), {
      ...feedback('mom', 'fb_mom'),
      createdAt: Timestamp.now(),
    });
    await setDoc(doc(db, 'babies/b1/recommendations/rec_1'), { contentId: 'act_sleep_dim' });
    await setDoc(doc(db, 'babies/b1/facts/state'), { dataVersion: 3 });
    await setDoc(doc(db, 'publicConfig/content_rhythm'), { version: 'rc_20261015_01' });
    await setDoc(doc(db, 'publicConfig/rhythm_reference'), { version: 'ref_20261015_01' });
  });
});

const as = (uid: string) => env.authenticatedContext(uid).firestore();
const ci = (uid: string, id: string, baby = 'b1') => doc(as(uid), `babies/${baby}/checkins/${id}`);
const fb = (uid: string, id: string, baby = 'b1') =>
  doc(as(uid), `babies/${baby}/recFeedback/${id}`);

describe('check-ins: who writes (D-072 #2)', () => {
  it('Cùng nuôi and Người chăm sóc save their own check-in', async () => {
    for (const uid of ['mom', 'dad', 'nanny']) {
      const id = ciId();
      await assertSucceeds(setDoc(ci(uid, id), checkIn(uid, id)));
    }
  });

  it('relatives (even with daily care), removed members and strangers cannot', async () => {
    for (const uid of ['grandma', 'aunt', 'gone', 'other']) {
      const id = ciId();
      await assertFails(setDoc(ci(uid, id), checkIn(uid, id)));
    }
    const id = ciId();
    await assertFails(
      setDoc(
        doc(env.unauthenticatedContext().firestore(), `babies/b1/checkins/${id}`),
        checkIn('mom', id),
      ),
    );
  });

  it('M03: no writing into another family, nor pointing at another baby', async () => {
    const id = ciId();
    await assertFails(setDoc(ci('mom', id, 'b2'), { ...checkIn('mom', id), babyId: 'b2' }));
    const id2 = ciId();
    await assertFails(setDoc(ci('mom', id2), { ...checkIn('mom', id2), babyId: 'b2' }));
  });

  it('M04: the author is the caller, the id matches, timestamps are the server time', async () => {
    const id = ciId();
    await assertFails(setDoc(ci('dad', id), checkIn('mom', id)));
    await assertFails(setDoc(ci('mom', id), { ...checkIn('mom', id), id: ciId() }));
    await assertFails(setDoc(ci('mom', 'ci_short'), checkIn('mom', 'ci_short')));
    await assertFails(setDoc(ci('mom', id), { ...checkIn('mom', id), createdAt: Timestamp.now() }));
    await assertFails(setDoc(ci('mom', id), { ...checkIn('mom', id), revision: 2 }));
    await assertFails(setDoc(ci('mom', id), { ...checkIn('mom', id), premium: true }));
  });

  it('malformed check-ins are refused', async () => {
    const bad: Record<string, unknown>[] = [
      { observation: 'teething' },
      { date: '14/10/2026' },
      { when: 'evening' },
      { since: 'week' },
      { tried: ['magic'] },
      { healthSigns: ['sneezing'] },
      { note: 'x'.repeat(501) },
      { revision: '1' },
    ];
    for (const over of bad) {
      const id = ciId();
      await assertFails(setDoc(ci('mom', id), checkIn('mom', id, over)));
    }
    const id = ciId();
    const missing: Record<string, unknown> = checkIn('mom', id);
    delete missing.note;
    await assertFails(setDoc(ci('mom', id), missing));
  });

  it('the author edits with a bumped revision; who, baby and day never change', async () => {
    const edit = (uid: string, over: Record<string, unknown>) =>
      updateDoc(ci(uid, 'ci_mom'), { updatedAt: serverTimestamp(), ...over });
    await assertSucceeds(edit('mom', { observation: 'usual', revision: 2 }));
    await assertFails(edit('mom', { observation: 'feeding', revision: 2 }));
    await assertFails(edit('mom', { observation: 'feeding' }));
    await assertFails(edit('mom', { date: '2026-10-13', revision: 3 }));
    await assertFails(edit('mom', { authorUid: 'dad', revision: 3 }));
    await assertFails(edit('mom', { revision: 3, createdAt: Timestamp.now() }));
    await assertFails(edit('dad', { observation: 'feeding', revision: 3 }));
    await assertFails(edit('nanny', { observation: 'feeding', revision: 3 }));
  });

  it('only the author deletes', async () => {
    await assertFails(deleteDoc(ci('dad', 'ci_mom')));
    await assertFails(deleteDoc(ci('grandma', 'ci_mom')));
    await assertSucceeds(deleteDoc(ci('mom', 'ci_mom')));
  });
});

describe('feedback (AC01, AC02)', () => {
  it('P-172 private state is owner/member-readable and all new authority stays callable-only', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/mom/personalization/b1'), {
        babyId: 'b1',
        context: 'busy',
      });
    });
    const mine = doc(env.authenticatedContext('mom').firestore(), 'users/mom/personalization/b1');
    await assertSucceeds(getDoc(mine));
    await assertFails(
      getDoc(doc(env.authenticatedContext('dad').firestore(), 'users/mom/personalization/b1')),
    );
    await assertFails(setDoc(mine, { context: 'forged' }));
    for (const path of [
      'babies/b1/notebook/n1',
      'babies/b1/careWork/w1',
      'babies/b1/personalizationExclusions/a1',
    ]) {
      await assertFails(
        setDoc(doc(env.authenticatedContext('mom').firestore(), path), { authorUid: 'mom' }),
      );
    }
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), 'babies/b1/members/mom'), { status: 'removed' });
    });
    await assertFails(getDoc(mine));
  });
  it('Cùng nuôi and Người chăm sóc give feedback as themselves', async () => {
    for (const uid of ['mom', 'nanny']) {
      const id = fbId();
      await assertSucceeds(setDoc(fb(uid, id), feedback(uid, id)));
    }
  });

  it('relatives, strangers, other authors and other babies are refused', async () => {
    for (const uid of ['grandma', 'aunt', 'gone', 'other']) {
      const id = fbId();
      await assertFails(setDoc(fb(uid, id), feedback(uid, id)));
    }
    const id = fbId();
    await assertFails(setDoc(fb('dad', id), feedback('mom', id)));
    await assertFails(setDoc(fb('mom', id, 'b2'), { ...feedback('mom', id), babyId: 'b2' }));
  });

  it('malformed feedback is refused and it never changes once written', async () => {
    const bad: Record<string, unknown>[] = [
      { kind: 'love' },
      { contentVersion: 0 },
      { contentId: '' },
      { date: 'yesterday' },
      { note: 'x'.repeat(301) },
      { createdAt: Timestamp.now() },
    ];
    for (const over of bad) {
      const id = fbId();
      await assertFails(setDoc(fb('mom', id), feedback('mom', id, over)));
    }
    await assertFails(setDoc(fb('mom', 'fb_bad'), feedback('mom', 'fb_bad')));
    await assertFails(updateDoc(fb('mom', 'fb_mom'), { kind: 'not_suitable' }));
    await assertFails(deleteDoc(fb('dad', 'fb_mom')));
    await assertSucceeds(deleteDoc(fb('mom', 'fb_mom')));
  });
});

describe('reads follow history.read', () => {
  it('Cùng nuôi, Người chăm sóc and relatives with daily care read; others do not', async () => {
    const paths = [
      'babies/b1/checkins/ci_mom',
      'babies/b1/recFeedback/fb_mom',
      'babies/b1/recommendations/rec_1',
      'babies/b1/facts/state',
    ];
    for (const uid of ['mom', 'nanny', 'aunt']) {
      for (const p of paths) await assertSucceeds(getDoc(doc(as(uid), p)));
      await assertSucceeds(getDocs(collection(as(uid), 'babies/b1/checkins')));
    }
    for (const uid of ['grandma', 'gone', 'other']) {
      for (const p of paths) await assertFails(getDoc(doc(as(uid), p)));
    }
  });

  it('M04: recommendations and facts are never written by the phone', async () => {
    await assertFails(setDoc(doc(as('mom'), 'babies/b1/recommendations/rec_2'), { x: 1 }));
    await assertFails(
      updateDoc(doc(as('mom'), 'babies/b1/recommendations/rec_1'), { state: 'done' }),
    );
    await assertFails(setDoc(doc(as('mom'), 'babies/b1/facts/state'), { dataVersion: 9 }));
    await assertFails(deleteDoc(doc(as('mom'), 'babies/b1/facts/state')));
  });

  it('the published reference and content are readable, never writable', async () => {
    for (const id of ['rhythm_reference', 'content_rhythm']) {
      await assertSucceeds(getDoc(doc(as('grandma'), `publicConfig/${id}`)));
      await assertFails(setDoc(doc(as('mom'), `publicConfig/${id}`), { version: 'x' }));
    }
  });
});

describe('preferences (EN01, EN02): per person', () => {
  const ref = (uid: string, owner = uid) => doc(as(uid), `users/${owner}/settings/personalization`);

  it('the owner saves and reads a valid shape', async () => {
    await assertSucceeds(setDoc(ref('grandma'), prefs()));
    await assertSucceeds(getDoc(ref('grandma')));
    await assertSucceeds(setDoc(ref('mom'), prefs({ digestTime: null, quietHours: null })));
  });

  it('nobody else reads or writes it', async () => {
    await assertFails(setDoc(ref('dad', 'mom'), prefs()));
    await assertFails(getDoc(ref('dad', 'mom')));
  });

  it('malformed preferences are refused', async () => {
    const bad: Record<string, unknown>[] = [
      { interests: ['gaming'] },
      { fewer: ['x'] },
      { digestTime: '25:00' },
      { quietHours: { from: '22:00' } },
      { quietHours: { from: '22:00', to: '6h' } },
      { premium: true },
    ];
    for (const over of bad) await assertFails(setDoc(ref('mom'), prefs(over)));
  });
});
