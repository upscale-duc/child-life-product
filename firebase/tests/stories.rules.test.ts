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

// S12 stories: parents write their drafts, take a suggestion as theirs, edit saved stories' content
// but never their status or audience; relatives read saved Gia đình stories only; caregivers never.
const projectId = 'demo-child-life';
let env: RulesTestEnvironment;
const S = (n: number) => `sto_${String(n).repeat(32)}`;

const member = (uid: string, role: string) => ({
  uid,
  babyId: 'b1',
  role,
  status: 'active',
  relation: 'other',
  relationCustom: null,
  displayName: uid,
});

const storyDoc = (id: string, extra: Record<string, unknown> = {}) => ({
  id,
  babyId: 'b1',
  kind: 'story',
  origin: 'manual',
  suggestion: false,
  status: 'draft',
  title: 'Tuần Teddy biết cười',
  coverMediaId: null,
  blocks: [],
  audience: 'family',
  createdBy: 'mom',
  author: { name: 'Mai', relation: 'mother', relationCustom: null },
  loveCount: 0,
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
    await setDoc(doc(db, 'babies/b1'), { nickname: 'Teddy', familyId: 'f1', state: 'active' });
    for (const [uid, role] of [
      ['mom', 'coParent'],
      ['dad', 'coParent'],
      ['nanny', 'caregiver'],
      ['grandma', 'relative'],
    ]) {
      await setDoc(doc(db, `babies/b1/members/${uid}`), member(uid!, role!));
    }
    await setDoc(doc(db, `babies/b1/stories/${S(1)}`), storyDoc(S(1)));
    await setDoc(doc(db, `babies/b1/stories/${S(2)}`), storyDoc(S(2), { status: 'saved' }));
    await setDoc(
      doc(db, `babies/b1/stories/${S(3)}`),
      storyDoc(S(3), { status: 'saved', audience: 'parents' }),
    );
    await setDoc(
      doc(db, `babies/b1/stories/${S(4)}`),
      storyDoc(S(4), { origin: 'ai', suggestion: true, createdBy: 'ai', author: null }),
    );
  });
});

const db = (uid: string) => env.authenticatedContext(uid).firestore();
const now = { updatedAt: serverTimestamp() };

describe('reading stories', () => {
  it('drafts are their author’s (and suggestions every parent’s); saved ones per audience', async () => {
    await assertSucceeds(getDoc(doc(db('mom'), `babies/b1/stories/${S(1)}`)));
    await assertFails(getDoc(doc(db('dad'), `babies/b1/stories/${S(1)}`)));
    await assertSucceeds(getDoc(doc(db('dad'), `babies/b1/stories/${S(4)}`)));
    await assertSucceeds(getDoc(doc(db('grandma'), `babies/b1/stories/${S(2)}`)));
    await assertFails(getDoc(doc(db('grandma'), `babies/b1/stories/${S(3)}`)));
    await assertFails(getDoc(doc(db('grandma'), `babies/b1/stories/${S(4)}`)));
    await assertFails(getDoc(doc(db('nanny'), `babies/b1/stories/${S(2)}`)));
  });
});

describe('writing stories', () => {
  it('a parent starts a draft ("Viết")', async () => {
    const id = S(5);
    const fresh = {
      ...storyDoc(id, { createdBy: 'dad' }),
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
      updatedBy: 'dad',
    };
    await assertSucceeds(setDoc(doc(db('dad'), `babies/b1/stories/${id}`), fresh));
    await assertFails(
      setDoc(doc(db('grandma'), `babies/b1/stories/${S(6)}`), {
        ...fresh,
        id: S(6),
        createdBy: 'grandma',
        updatedBy: 'grandma',
      }),
    );
    await assertFails(
      setDoc(doc(db('dad'), `babies/b1/stories/${S(7)}`), { ...fresh, id: S(7), status: 'saved' }),
    );
  });

  it('edits keep status; a suggestion becomes the editor’s draft', async () => {
    await assertSucceeds(
      updateDoc(doc(db('mom'), `babies/b1/stories/${S(1)}`), {
        title: 'Mới',
        ...now,
        updatedBy: 'mom',
      }),
    );
    await assertFails(
      updateDoc(doc(db('mom'), `babies/b1/stories/${S(1)}`), {
        status: 'saved',
        ...now,
        updatedBy: 'mom',
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db('dad'), `babies/b1/stories/${S(4)}`), {
        createdBy: 'dad',
        suggestion: false,
        ...now,
        updatedBy: 'dad',
      }),
    );
    // Saved: content yes, audience no (that goes through saveFamilyStory).
    await assertSucceeds(
      updateDoc(doc(db('dad'), `babies/b1/stories/${S(2)}`), {
        title: 'Sửa',
        ...now,
        updatedBy: 'dad',
      }),
    );
    await assertFails(
      updateDoc(doc(db('dad'), `babies/b1/stories/${S(2)}`), {
        audience: 'parents',
        ...now,
        updatedBy: 'dad',
      }),
    );
    await assertFails(
      updateDoc(doc(db('grandma'), `babies/b1/stories/${S(2)}`), {
        title: 'x',
        ...now,
        updatedBy: 'grandma',
      }),
    );
  });

  it('drafts can be discarded, saved stories only through Functions', async () => {
    await assertSucceeds(deleteDoc(doc(db('dad'), `babies/b1/stories/${S(4)}`)));
    await assertFails(deleteDoc(doc(db('dad'), `babies/b1/stories/${S(1)}`)));
    await assertFails(deleteDoc(doc(db('mom'), `babies/b1/stories/${S(2)}`)));
  });

  it('nothing is written while the profile is being deleted', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), 'babies/b1'), { state: 'deleting' });
    });
    await assertFails(
      updateDoc(doc(db('mom'), `babies/b1/stories/${S(1)}`), {
        title: 'x',
        ...now,
        updatedBy: 'mom',
      }),
    );
  });
});
