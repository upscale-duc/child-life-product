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
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { localDateIn, type DraftPayload } from '@child-life/contracts';
import {
  checkInIdFor,
  feedbackIdFor,
  recordIdForDraft,
} from '../functions/src/assistant-common.js';
import {
  buildCareRecord,
  buildCheckIn,
  buildRecFeedback,
  careRecordFromDraft,
} from '../functions/src/assistant-writers.js';

// Child Life Assistant, slice A2 (docs/assistant/data.md, P-158): every assistant collection is
// read-only for its owner while still a member of the scope, never written by a client; the
// execution and request ledgers are never readable. Shape test (P-156): the documents the domain
// writers produce pass the app's own create rules when written by the member with
// `source: 'app'`, and a client can never write `source: 'assistant'`.
const projectId = 'demo-child-life-assistant-rules';
let env: RulesTestEnvironment;

const member = (
  role: string,
  relation: string,
  displayName: string,
  extra: Record<string, unknown> = {},
) => ({
  babyId: 'b1',
  role,
  status: 'active',
  relation,
  relationCustom: null,
  displayName,
  ...extra,
});

const CV = 'cv_00000000000000000000000000000001';
const TK = 'tk_00000000000000000000000000000001';
const DR = 'dr_00000000000000000000000000000001_0';
const scope = { type: 'child', babyId: 'b1' };

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
    await setDoc(doc(db, 'babies/b1'), { familyId: 'f1', state: 'active' });
    await setDoc(
      doc(db, 'babies/b1/members/mom'),
      member('coParent', 'mother', 'Mai', { isOwner: true }),
    );
    await setDoc(doc(db, 'babies/b1/members/dad'), member('coParent', 'father', 'Huy'));
    await setDoc(doc(db, 'babies/b1/members/nanny'), member('caregiver', 'nanny', 'Cô Hoa'));
    await setDoc(doc(db, 'babies/b1/members/grandma'), member('relative', 'grandmother', 'Bà'));
    const owned = { ownerUid: 'mom', familyId: 'f1', scope };
    await setDoc(doc(db, `assistantConversations/${CV}`), {
      ...owned,
      id: CV,
      title: null,
      messageSeq: 1,
    });
    await setDoc(doc(db, `assistantConversations/${CV}/messages/00000001`), {
      conversationId: CV,
      role: 'user',
      parts: [{ type: 'text', schemaVersion: 1, text: 'test' }],
      taskId: TK,
      sequence: 1,
    });
    await setDoc(doc(db, `assistantTasks/${TK}`), {
      ...owned,
      id: TK,
      conversationId: CV,
      state: 'ready',
      version: 3,
    });
    await setDoc(doc(db, `assistantTasks/${TK}/drafts/${DR}`), {
      ...owned,
      id: DR,
      taskId: TK,
      revision: 1,
      state: 'draft',
    });
    await setDoc(doc(db, `assistantTasks/${TK}/events/00000001`), {
      taskId: TK,
      sequence: 1,
      type: 'accepted',
    });
    await setDoc(doc(db, 'assistantQuotes/qt_1'), { ...owned, id: 'qt_1', credits: 1 });
    await setDoc(doc(db, `assistantExecutions/${DR}_1`), {
      ownerUid: 'mom',
      draftId: DR,
      status: 'saved',
    });
    await setDoc(doc(db, 'assistantRequests/req_1'), { uid: 'mom', op: 'confirm' });
  });
});

const as = (uid: string) => env.authenticatedContext(uid).firestore();
const paths = [
  `assistantConversations/${CV}`,
  `assistantConversations/${CV}/messages/00000001`,
  `assistantTasks/${TK}`,
  `assistantTasks/${TK}/drafts/${DR}`,
  `assistantTasks/${TK}/events/00000001`,
  'assistantQuotes/qt_1',
];

describe('assistant collections: owner read-only', () => {
  it('the owner reads every own assistant document', async () => {
    for (const p of paths) await assertSucceeds(getDoc(doc(as('mom'), p)));
  });

  it('another member of the same baby, a stranger and a signed-out client read nothing', async () => {
    for (const p of paths) {
      await assertFails(getDoc(doc(as('dad'), p)));
      await assertFails(getDoc(doc(as('stranger'), p)));
      await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), p)));
    }
  });

  it('the owner no longer reads once their membership of the scope ended (P-158)', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), 'babies/b1/members/mom'), { status: 'removed' });
    });
    for (const p of paths) await assertFails(getDoc(doc(as('mom'), p)));
  });

  it('no client writes: create, update or delete, even by the owner', async () => {
    const db = as('mom');
    for (const p of paths) {
      await assertFails(setDoc(doc(db, p), { ownerUid: 'mom', scope }));
      await assertFails(updateDoc(doc(db, p), { state: 'saved' }));
      await assertFails(deleteDoc(doc(db, p)));
    }
    await assertFails(
      setDoc(doc(db, 'assistantTasks/tk_new'), {
        ownerUid: 'mom',
        familyId: 'f1',
        scope,
        state: 'queued',
      }),
    );
  });

  it('executions and the request ledger are never readable, not even by the owner', async () => {
    await assertFails(getDoc(doc(as('mom'), `assistantExecutions/${DR}_1`)));
    await assertFails(getDoc(doc(as('mom'), 'assistantRequests/req_1')));
    await assertFails(getDocs(collection(as('mom'), 'assistantExecutions')));
  });

  it('lists: own conversations by owner + baby, a task’s drafts and events, own quotes', async () => {
    const db = as('mom');
    await assertSucceeds(
      getDocs(
        query(
          collection(db, 'assistantConversations'),
          where('ownerUid', '==', 'mom'),
          where('scope.babyId', '==', 'b1'),
        ),
      ),
    );
    await assertFails(getDocs(collection(db, 'assistantConversations')));
    await assertFails(
      getDocs(
        query(collection(as('dad'), 'assistantConversations'), where('ownerUid', '==', 'mom')),
      ),
    );
    await assertSucceeds(getDocs(collection(db, `assistantTasks/${TK}/drafts`)));
    await assertSucceeds(getDocs(collection(db, `assistantTasks/${TK}/events`)));
    await assertSucceeds(getDocs(collection(db, `assistantConversations/${CV}/messages`)));
    await assertFails(getDocs(collection(as('dad'), `assistantTasks/${TK}/drafts`)));
  });

  it('the assistant consent is written by the callable only', async () => {
    await assertFails(
      setDoc(doc(as('mom'), 'users/mom/settings/ai'), {
        assistant: { version: 'assistant-consent-v1', grantedAt: 'x' },
      }),
    );
  });
});

// ---------- Shape: writer output == what the app may write ----------

const nowMs = () => Date.now();
const ago = (min: number) => new Date(nowMs() - min * 60_000).toISOString();
const author = { displayName: 'Mai', relation: 'mother', relationCustom: null };

function careDoc(payload: DraftPayload, uid = 'mom', source = 'app', who = author) {
  const draftId = `dr_${'0'.repeat(31)}${payload.kind === 'bottle' ? 1 : payload.kind === 'breast' ? 2 : 3}_0`;
  const care = careRecordFromDraft(payload, new Date());
  if (!care.ok) throw new Error(`invalid fixture: ${care.problems.join(',')}`);
  const recordId = recordIdForDraft(draftId);
  return {
    id: recordId,
    data: buildCareRecord(
      {
        recordId,
        babyId: 'b1',
        uid,
        member: who,
        type: care.type,
        occurredAt: care.occurredAt,
        endedAt: care.endedAt,
        data: care.data,
        clientCreatedAt: new Date(),
      },
      serverTimestamp(),
      source,
    ),
  };
}

const bottle: DraftPayload = {
  kind: 'bottle',
  amountMl: 150,
  occurredAt: ago(45),
  milk: 'breast_milk',
};
const breast: DraftPayload = { kind: 'breast', occurredAt: ago(90), durationMin: 20, side: 'left' };
const sleep: DraftPayload = { kind: 'sleep', startedAt: ago(240), endedAt: ago(180) };

describe('writer documents pass the app’s create rules (P-156)', () => {
  it('bottle, breast and sleep records: accepted as the member with source app', async () => {
    for (const p of [bottle, breast, sleep]) {
      const r = careDoc(p);
      await assertSucceeds(setDoc(doc(as('mom'), `babies/b1/records/${r.id}`), r.data));
    }
  });

  it('a caregiver’s record passes too; a relative’s never (relatives never log)', async () => {
    const nanny = careDoc(bottle, 'nanny', 'app', {
      displayName: 'Cô Hoa',
      relation: 'nanny',
      relationCustom: null,
    });
    await assertSucceeds(setDoc(doc(as('nanny'), `babies/b1/records/${nanny.id}`), nanny.data));
    const grandma = careDoc(breast, 'grandma', 'app', {
      displayName: 'Bà',
      relation: 'grandmother',
      relationCustom: null,
    });
    await assertFails(setDoc(doc(as('grandma'), `babies/b1/records/${grandma.id}`), grandma.data));
  });

  it('a client can never write source "assistant" (only the server writer does)', async () => {
    const r = careDoc(bottle, 'mom', 'assistant');
    expect(r.data.source).toBe('assistant');
    await assertFails(setDoc(doc(as('mom'), `babies/b1/records/${r.id}`), r.data));
  });

  it('the writer refuses what the Rules refuse (future time, sleep over 24 h, unknown milk)', () => {
    expect(
      careRecordFromDraft(
        { ...bottle, occurredAt: new Date(nowMs() + 60 * 60_000).toISOString() },
        new Date(),
      ).ok,
    ).toBe(false);
    expect(
      careRecordFromDraft({ kind: 'sleep', startedAt: ago(26 * 60), endedAt: ago(30) }, new Date())
        .ok,
    ).toBe(false);
    expect(careRecordFromDraft({ ...bottle, milk: 'other' }, new Date()).ok).toBe(false);
  });

  it('check-in (observation) and suggestion feedback documents pass their rules', async () => {
    const date = localDateIn('Asia/Ho_Chi_Minh', new Date());
    const ci = checkInIdFor('b1', 'mom', date, 'sleep');
    await assertSucceeds(
      setDoc(
        doc(as('mom'), `babies/b1/checkins/${ci}`),
        buildCheckIn(
          {
            id: ci,
            babyId: 'b1',
            uid: 'mom',
            date,
            observation: 'sleep',
            when: 'night',
            note: null,
          },
          serverTimestamp(),
        ),
      ),
    );
    const fb = feedbackIdFor('mom', 'tk_1', 'act_test_sleep', 1);
    await assertSucceeds(
      setDoc(
        doc(as('mom'), `babies/b1/recFeedback/${fb}`),
        buildRecFeedback(
          {
            id: fb,
            babyId: 'b1',
            uid: 'mom',
            contentId: 'act_test_sleep',
            contentVersion: 1,
            kind: 'helpful',
            date,
          },
          serverTimestamp(),
        ),
      ),
    );
  });
});
