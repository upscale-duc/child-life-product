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

// Mốc phát triển (D-076 #6, packages/contracts/src/milestones.ts): the baby's records share
// `babies/{b}/milestones` with Kỷ niệm's family milestones (R-105). Only a Cùng nuôi records,
// edits or removes them (`moments.create`); caregivers and relatives never read them. Published
// reference milestones are readable by any signed-in user, drafts by nobody.
const projectId = 'demo-child-life';
let env: RulesTestEnvironment;

const relations: Record<string, string> = {
  mom: 'mother',
  dad: 'father',
  nanny: 'nanny',
  grandma: 'grandmother',
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

const CUSTOM = `ms_${'e'.repeat(32)}`;
const MEMORY = `mem_${'a'.repeat(32)}`;

function record(uid: string, overrides: Record<string, unknown> = {}) {
  return {
    id: 'p_first_smile',
    babyId: 'b1',
    kind: 'reference',
    referenceId: 'first_smile',
    name: 'Mỉm cười đáp lại',
    status: 'observed',
    date: '2026-10-08',
    note: 'Bé cười khi mẹ hát sau cữ bú sáng.',
    memoryIds: [],
    source: 'milestones',
    createdBy: uid,
    author: author(uid),
    createdAt: serverTimestamp(),
    updatedBy: uid,
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

const db = (uid: string) => env.authenticatedContext(uid).firestore();
const path = (id = 'p_first_smile') => `babies/b1/milestones/${id}`;

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
    const d = ctx.firestore();
    await setDoc(doc(d, 'babies/b1'), { nickname: 'Teddy', familyId: 'f1' });
    await setDoc(doc(d, 'babies/b2'), { nickname: 'Na', familyId: 'f2', state: 'deleting' });
    await setDoc(doc(d, 'babies/b1/members/mom'), member('mom', 'coParent'));
    await setDoc(doc(d, 'babies/b1/members/dad'), member('dad', 'coParent'));
    await setDoc(doc(d, 'babies/b1/members/nanny'), member('nanny', 'caregiver'));
    await setDoc(
      doc(d, 'babies/b1/members/grandma'),
      member('grandma', 'relative', { extraRights: { viewBabyInfo: true, viewDailyCare: true } }),
    );
    await setDoc(
      doc(d, 'babies/b1/members/gone'),
      member('gone', 'coParent', { status: 'removed' }),
    );
    await setDoc(doc(d, 'babies/b2/members/mom'), { ...member('mom', 'coParent'), babyId: 'b2' });
    // A Kỷ niệm milestone from before (R-105 shape).
    await setDoc(doc(d, path(CUSTOM)), {
      id: CUSTOM,
      babyId: 'b1',
      name: 'Lần đầu về quê',
      date: '2026-10-04',
      createdBy: 'dad',
      author: author('dad'),
      createdAt: new Date(),
    });
    await setDoc(doc(d, 'contentMilestones/first_smile'), {
      id: 'first_smile',
      status: 'published',
    });
    await setDoc(doc(d, 'contentMilestones/coos'), { id: 'coos', status: 'draft' });
  });
});

describe('recording a milestone', () => {
  it('a Cùng nuôi records a reference milestone as itself, keyed p_<referenceId>', async () => {
    await assertSucceeds(setDoc(doc(db('mom'), path()), record('mom')));
    await assertFails(setDoc(doc(db('mom'), path('p_rolls_over')), record('mom')));
    await assertFails(setDoc(doc(db('mom'), path()), record('mom', { createdBy: 'dad' })));
    await assertFails(setDoc(doc(db('mom'), path()), record('mom', { author: author('dad') })));
    await assertFails(
      setDoc(doc(db('mom'), path()), record('mom', { kind: 'custom', referenceId: null })),
    );
    await assertFails(setDoc(doc(db('mom'), path()), record('mom', { extra: true })));
  });

  it('caregivers, relatives and former members cannot record or read', async () => {
    for (const uid of ['nanny', 'grandma', 'gone']) {
      await assertFails(setDoc(doc(db(uid), path()), record(uid)));
      await assertFails(getDoc(doc(db(uid), path(CUSTOM))));
      await assertFails(getDocs(collection(db(uid), 'babies/b1/milestones')));
    }
    await assertSucceeds(getDocs(collection(db('dad'), 'babies/b1/milestones')));
  });

  it('a custom milestone with a note, and one followed reference milestone without a date', async () => {
    const id = `ms_${'f'.repeat(32)}`;
    await assertSucceeds(
      setDoc(
        doc(db('dad'), path(id)),
        record('dad', {
          id,
          kind: 'custom',
          referenceId: null,
          name: 'Lần đầu đi biển',
          source: 'rhythm',
        }),
      ),
    );
    await assertSucceeds(
      setDoc(
        doc(db('dad'), path('p_coos')),
        record('dad', {
          id: 'p_coos',
          referenceId: 'coos',
          name: 'Ê a',
          status: 'following',
          date: null,
          note: null,
        }),
      ),
    );
    // A custom one is never "following"; observed ones have a date.
    const other = `ms_${'d'.repeat(32)}`;
    await assertFails(
      setDoc(
        doc(db('dad'), path(other)),
        record('dad', {
          id: other,
          kind: 'custom',
          referenceId: null,
          status: 'following',
          date: null,
        }),
      ),
    );
    await assertFails(setDoc(doc(db('dad'), path()), record('dad', { date: null })));
  });

  it('checks the name, note, memory links and source', async () => {
    await assertFails(setDoc(doc(db('mom'), path()), record('mom', { name: ' ' })));
    await assertFails(setDoc(doc(db('mom'), path()), record('mom', { name: 'x'.repeat(61) })));
    await assertFails(setDoc(doc(db('mom'), path()), record('mom', { note: 'x'.repeat(501) })));
    await assertFails(
      setDoc(doc(db('mom'), path()), record('mom', { memoryIds: Array(21).fill(MEMORY) })),
    );
    await assertFails(setDoc(doc(db('mom'), path()), record('mom', { source: 'portal' })));
    await assertSucceeds(
      setDoc(doc(db('mom'), path()), record('mom', { note: null, memoryIds: [MEMORY] })),
    );
  });

  it('still accepts the Kỷ niệm "Tạo mốc mới" shape (R-105)', async () => {
    const id = `ms_${'c'.repeat(32)}`;
    await assertSucceeds(
      setDoc(doc(db('mom'), path(id)), {
        id,
        babyId: 'b1',
        name: 'Lần đầu lật người',
        date: '2026-10-08',
        createdBy: 'mom',
        author: author('mom'),
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('locks writes while the profile is being deleted', async () => {
    await assertFails(
      setDoc(doc(db('mom'), 'babies/b2/milestones/p_first_smile'), {
        ...record('mom'),
        babyId: 'b2',
      }),
    );
  });
});

describe('editing and removing', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), path()), { ...record('mom'), createdAt: new Date() });
    });
  });

  const edit = (uid: string, change: Record<string, unknown>) =>
    updateDoc(doc(db(uid), path()), {
      ...change,
      updatedBy: uid,
      updatedAt: serverTimestamp(),
    });

  it('any Cùng nuôi edits the date, note and memory links', async () => {
    await assertSucceeds(edit('dad', { date: '2026-10-07', note: 'Sau giờ tắm' }));
    await assertSucceeds(edit('mom', { memoryIds: [MEMORY] }));
    await assertFails(edit('nanny', { note: 'x' }));
    await assertFails(edit('grandma', { note: 'x' }));
  });

  it('never rewrites who recorded it, when, or what it is', async () => {
    await assertFails(edit('dad', { createdBy: 'dad' }));
    await assertFails(edit('dad', { author: author('dad') }));
    await assertFails(edit('dad', { kind: 'custom', referenceId: null }));
    await assertFails(edit('dad', { source: 'rhythm' }));
    await assertFails(edit('dad', { createdAt: serverTimestamp() }));
    await assertFails(
      updateDoc(doc(db('dad'), path()), {
        note: 'x',
        updatedBy: 'mom',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('a legacy Kỷ niệm milestone gains the new fields as a custom one', async () => {
    const full = {
      kind: 'custom',
      referenceId: null,
      status: 'observed',
      note: 'Cả nhà về Nam Định.',
      memoryIds: [MEMORY],
      source: 'memories',
      updatedBy: 'mom',
      updatedAt: serverTimestamp(),
    };
    await assertSucceeds(updateDoc(doc(db('mom'), path(CUSTOM)), full));
  });

  it('a legacy one cannot turn into another kind', async () => {
    await assertFails(
      updateDoc(doc(db('mom'), path(CUSTOM)), {
        kind: 'reference',
        referenceId: 'first_smile',
        status: 'observed',
        note: null,
        memoryIds: [],
        source: 'memories',
        updatedBy: 'mom',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('a Cùng nuôi removes a record; others cannot', async () => {
    await assertFails(deleteDoc(doc(db('nanny'), path())));
    await assertFails(deleteDoc(doc(db('grandma'), path())));
    await assertSucceeds(deleteDoc(doc(db('dad'), path())));
  });
});

describe('reference milestones (contentMilestones)', () => {
  it('signed-in users read published ones only; nobody writes', async () => {
    await assertSucceeds(getDoc(doc(db('grandma'), 'contentMilestones/first_smile')));
    await assertFails(getDoc(doc(db('grandma'), 'contentMilestones/coos')));
    await assertSucceeds(
      getDocs(
        query(collection(db('nanny'), 'contentMilestones'), where('status', '==', 'published')),
      ),
    );
    await assertFails(getDocs(collection(db('nanny'), 'contentMilestones')));
    await assertFails(
      getDoc(doc(env.unauthenticatedContext().firestore(), 'contentMilestones/first_smile')),
    );
    await assertFails(
      setDoc(doc(db('mom'), 'contentMilestones/laughs'), { id: 'laughs', status: 'published' }),
    );
  });
});
