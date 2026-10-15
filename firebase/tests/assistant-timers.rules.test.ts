import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { Timestamp, deleteDoc, doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { buildTimerDoc } from '../functions/src/assistant-timers.js';

// Lumi 2026-10-16 (docs/assistant/api.md "Timers and review fields"): a timer started from chat
// is the app's own timer document. The server writes it with the Admin SDK; this checks that the
// exact document it builds (`buildTimerDoc`) is one the Rules accept from the app
// (`validNewTimer`), and that the family then pauses, switches and ends it on their phones as any
// timer (`validTimerUpdate`, delete). Synthetic data only.
const projectId = 'demo-child-life';
let env: RulesTestEnvironment;

const member = (uid: string, role: string, relation: string) => ({
  uid,
  babyId: 'b1',
  role,
  status: 'active',
  relation,
  relationCustom: null,
  displayName: uid,
});
const as = (uid: string) => env.authenticatedContext(uid).firestore();
const timerDoc = (uid: string, type: 'sleep' | 'breast', side: 'left' | 'right' | null = null) =>
  buildTimerDoc(
    {
      type,
      babyId: 'b1',
      sessionId: 'c'.repeat(32),
      at: new Date(Date.now() - 10 * 60_000),
      side,
      uid,
      author: { name: uid, relation: uid === 'mom' ? 'mother' : 'nanny', relationCustom: null },
    },
    (d) => Timestamp.fromDate(d),
    serverTimestamp(),
  );

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
    await setDoc(doc(db, 'babies/b1/members/mom'), member('mom', 'coParent', 'mother'));
    await setDoc(doc(db, 'babies/b1/members/dad'), member('dad', 'coParent', 'father'));
    await setDoc(doc(db, 'babies/b1/members/nanny'), member('nanny', 'caregiver', 'nanny'));
  });
});

describe('a timer started from chat is the app timer', () => {
  it('the server-built sleep and breast documents pass validNewTimer for their starter', async () => {
    await assertSucceeds(
      setDoc(doc(as('mom'), 'babies/b1/timers/sleep'), timerDoc('mom', 'sleep')),
    );
    await assertSucceeds(
      setDoc(doc(as('nanny'), 'babies/b1/timers/breast'), timerDoc('nanny', 'breast', 'right')),
    );
    // Never as someone else (the server always uses the confirmer's own uid and membership).
    await assertFails(setDoc(doc(as('dad'), 'babies/b1/timers/sleep'), timerDoc('mom', 'sleep')));
  });

  it('another member pauses, switches side and ends it on their phone', async () => {
    await assertSucceeds(
      setDoc(doc(as('mom'), 'babies/b1/timers/breast'), timerDoc('mom', 'breast', 'left')),
    );
    const now = Timestamp.now();
    await assertSucceeds(
      updateDoc(doc(as('dad'), 'babies/b1/timers/breast'), {
        sides: {
          left: { accumulatedMs: 600_000, runningSince: null },
          right: { accumulatedMs: 0, runningSince: now },
        },
        paused: false,
        pausedSides: [],
        updatedAt: serverTimestamp(),
        updatedBy: 'dad',
      }),
    );
    await assertSucceeds(deleteDoc(doc(as('nanny'), 'babies/b1/timers/breast')));
  });
});
