import {
  initializeTestEnvironment,
  assertFails,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore as adminFirestore } from 'firebase-admin/firestore';
import {
  collection,
  query,
  where,
  orderBy,
  documentId,
  limit,
  startAfter,
  getDocs,
  type QueryDocumentSnapshot,
} from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { beforeAll, afterAll, it, expect } from 'vitest';
const projectId = 'demo-child-life-history';
const app = initializeApp({ projectId }, projectId);
const db = adminFirestore(app);
let env: RulesTestEnvironment;
beforeAll(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw Error('Emulator required');
  env = await initializeTestEnvironment({
    projectId,
    firestore: { rules: readFileSync(resolve(import.meta.dirname, '../firestore.rules'), 'utf8') },
  });
  await env.clearFirestore();
  await db.doc('babies/history').set({ familyId: 'test', nickname: 'Synthetic' });
  await db
    .doc('babies/history/members/parent')
    .set({ uid: 'parent', babyId: 'history', status: 'active', role: 'coParent' });
  await db
    .doc('babies/history/members/relative')
    .set({ uid: 'relative', babyId: 'history', status: 'active', role: 'relative' });
  // Equal timestamps exercise the document-id tie breaker, past both former hard limits.
  for (const [name, count, field] of [
    ['memories', 1001, 'occurredAt'],
    ['media', 5001, 'captureAt'],
  ] as const) {
    for (let start = 0; start < count; start += 400) {
      const batch = db.batch();
      for (let i = start; i < Math.min(count, start + 400); i++) {
        batch.set(db.doc(`babies/history/${name}/item_${String(i).padStart(5, '0')}`), {
          [field]: new Date('2020-01-01T12:00:00Z'),
          deleted: false,
          audience: i % 2 ? 'family' : 'parents',
          effectiveAudience: i % 2 ? 'family' : 'parents',
          status: 'ready',
          state: 'published',
        });
      }
      await batch.commit();
    }
  }
}, 30_000);
afterAll(async () => {
  await env.cleanup();
  await deleteApp(app);
});
it('a parent can page beyond 1,000 memories and 5,000 photos without duplicates', async () => {
  const client = env.authenticatedContext('parent').firestore();
  for (const [name, total, field] of [
    ['memories', 1001, 'occurredAt'],
    ['media', 5001, 'captureAt'],
  ] as const) {
    const base = query(
      collection(client, `babies/history/${name}`),
      where('deleted', '==', false),
      orderBy(field, 'desc'),
      orderBy(documentId(), 'desc'),
    );
    const seen = new Set<string>();
    let last: QueryDocumentSnapshot | undefined;
    for (;;) {
      const page = await getDocs(
        last
          ? query(base, startAfter(last.get(field), last.id), limit(200))
          : query(base, limit(200)),
      );
      for (const d of page.docs) {
        expect(seen.has(d.id)).toBe(false);
        seen.add(d.id);
      }
      if (page.size < 200) break;
      last = page.docs.at(-1)!;
    }
    expect(seen.size).toBe(total);
    expect(seen.has('item_00000')).toBe(true);
  }
}, 30_000);
it('older-page predicates enforce relative visibility and revoke access', async () => {
  const client = env.authenticatedContext('relative').firestore();
  const base = collection(client, 'babies/history/media');
  await assertFails(
    getDocs(
      query(
        base,
        where('deleted', '==', false),
        orderBy('captureAt', 'desc'),
        orderBy(documentId(), 'desc'),
        limit(200),
      ),
    ),
  );
  const visible = query(
    base,
    where('deleted', '==', false),
    where('effectiveAudience', '==', 'family'),
    where('status', '==', 'ready'),
    orderBy('captureAt', 'desc'),
    orderBy(documentId(), 'desc'),
  );
  const first = await getDocs(query(visible, limit(200)));
  expect(first.size).toBe(200);
  const cursor = first.docs.at(-1)!;
  const second = query(visible, startAfter(cursor.get('captureAt'), cursor.id), limit(200));
  expect((await getDocs(second)).size).toBe(200);
  await db.doc('babies/history/members/relative').update({ status: 'removed' });
  await assertFails(getDocs(second));
});
