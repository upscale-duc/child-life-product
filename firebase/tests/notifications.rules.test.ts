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

// Notification centre (D-076 #2): the inbox is the owner's to read and mark read / archived only;
// EN07 settings take any subset of bool switches.
const projectId = 'demo-child-life';
let env: RulesTestEnvironment;
const ROW = 'n_bn-b1-memories_1-abc123';

const row = () => ({
  kind: 'memories',
  category: 'family',
  title: { vi: 'Có 1 khoảnh khắc mới', en: '1 new moment' },
  body: { vi: 'Mai vừa chia sẻ với gia đình. Mở để xem.', en: 'Mai just shared. Open to see.' },
  route: 'memories',
  babyId: 'b1',
  data: { kind: 'memories', babyId: 'b1', inboxId: ROW },
  pushed: true,
  createdAt: Timestamp.now(),
  readAt: null,
  archivedAt: null,
  expireAt: Timestamp.fromMillis(Date.now() + 90 * 86_400_000),
});

const db = (uid: string) => env.authenticatedContext(uid).firestore();

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
    await setDoc(doc(ctx.firestore(), `users/mom/notifications/${ROW}`), row());
  });
});

describe('inbox (EN06)', () => {
  it('only its owner reads it', async () => {
    await assertSucceeds(getDoc(doc(db('mom'), `users/mom/notifications/${ROW}`)));
    await assertSucceeds(getDocs(collection(db('mom'), 'users/mom/notifications')));
    await assertFails(getDoc(doc(db('dad'), `users/mom/notifications/${ROW}`)));
    await assertFails(getDocs(collection(db('dad'), 'users/mom/notifications')));
    await assertFails(
      getDoc(doc(env.unauthenticatedContext().firestore(), `users/mom/notifications/${ROW}`)),
    );
  });

  it('nobody creates or deletes rows from the app', async () => {
    await assertFails(setDoc(doc(db('mom'), 'users/mom/notifications/n_fake-000001'), row()));
    await assertFails(deleteDoc(doc(db('mom'), `users/mom/notifications/${ROW}`)));
  });

  it('the owner marks read and archived, at the request time, once', async () => {
    const ref = doc(db('mom'), `users/mom/notifications/${ROW}`);
    await assertFails(
      updateDoc(doc(db('dad'), `users/mom/notifications/${ROW}`), { readAt: serverTimestamp() }),
    );
    await assertFails(updateDoc(ref, { readAt: Timestamp.fromMillis(0) }));
    await assertSucceeds(updateDoc(ref, { readAt: serverTimestamp() }));
    // Read stays read.
    await assertFails(updateDoc(ref, { readAt: null }));
    await assertFails(updateDoc(ref, { readAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(ref, { archivedAt: serverTimestamp() }));
  });

  it('nothing else changes', async () => {
    const ref = doc(db('mom'), `users/mom/notifications/${ROW}`);
    await assertFails(updateDoc(ref, { title: { vi: 'x', en: 'x' } }));
    await assertFails(updateDoc(ref, { readAt: serverTimestamp(), pushed: false }));
    await assertFails(updateDoc(ref, { babyName: 'Teddy' }));
  });
});

describe('settings (EN07)', () => {
  const settingsRef = (uid: string) => doc(db(uid), `users/${uid}/settings/notifications`);

  it('any subset of the EN07 switches, bools only', async () => {
    await assertSucceeds(
      setDoc(settingsRef('mom'), {
        reminders: true,
        vaccines: false,
        spending: true,
        rhythm: true,
        stages: false,
        milestones: true,
        articles: false,
        weeklySummary: true,
        memories: true,
        messages: true,
        storage: true,
        photoSuggestions: true,
        keepsakePrompts: false,
        familyActivity: true,
        familyMembers: false,
        babyName: false,
        updatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      setDoc(settingsRef('mom'), { rhythm: false, updatedAt: serverTimestamp() }),
    );
    // The G-056 shape still saves (older app versions).
    await assertSucceeds(
      setDoc(settingsRef('mom'), {
        memories: true,
        messages: false,
        reminders: true,
        storage: true,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('rejects other people, other keys and non-bools', async () => {
    await assertFails(
      setDoc(doc(db('dad'), 'users/mom/settings/notifications'), {
        rhythm: true,
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      setDoc(settingsRef('mom'), { quietHours: '22:00', updatedAt: serverTimestamp() }),
    );
    await assertFails(setDoc(settingsRef('mom'), { articles: 'on', updatedAt: serverTimestamp() }));
    await assertFails(
      setDoc(settingsRef('mom'), { articles: true, updatedAt: Timestamp.fromMillis(0) }),
    );
  });
});

describe('unified platform collections (P-174) are server-only', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const f = ctx.firestore();
      await setDoc(doc(f, 'notificationDeliveries/d_1'), { uid: 'mom', kind: 'memories' });
      await setDoc(doc(f, 'notificationStats/2026-10-20_0'), { day: '2026-10-20' });
      await setDoc(doc(f, 'notificationTemplates/memories.new_moments'), { status: 'published' });
      await setDoc(doc(f, 'config/notifications'), { templatesEnabled: true });
    });
  });

  it('even the recipient cannot read or write the ledger, stats, templates or ops switches', async () => {
    for (const path of [
      'notificationDeliveries/d_1',
      'notificationStats/2026-10-20_0',
      'notificationTemplates/memories.new_moments',
      'config/notifications',
    ]) {
      await assertFails(getDoc(doc(db('mom'), path)));
      await assertFails(setDoc(doc(db('mom'), path), { x: 1 }));
    }
    await assertFails(getDocs(collection(db('mom'), 'notificationDeliveries')));
  });

  it('the owner cannot rewrite the platform fields of an inbox row', async () => {
    const ref = doc(db('mom'), `users/mom/notifications/${ROW}`);
    await assertFails(updateDoc(ref, { destination: 'INBOX' }));
    await assertFails(updateDoc(ref, { ledgerId: `d_${'0'.repeat(40)}` }));
    await assertFails(updateDoc(ref, { readAt: serverTimestamp(), templateVersion: 9 }));
  });
});
