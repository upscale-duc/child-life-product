import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc } from 'firebase/firestore';
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';
import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

// Góp ý (FB2, D-065): the sender uploads one screenshot under their own uid and the request id;
// nobody reads it from a client. Tickets and the daily counters are server-only.
const projectId = 'demo-child-life-feedback';
let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: { rules: readFileSync(resolve(import.meta.dirname, '../firestore.rules'), 'utf8') },
    storage: { rules: readFileSync(resolve(import.meta.dirname, '../storage.rules'), 'utf8') },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearStorage();
});

const storage = (uid: string) => env.authenticatedContext(uid).storage();
const bytes = (n: number) => new Uint8Array(n);
const jpeg = { contentType: 'image/jpeg' };
const png = { contentType: 'image/png' };

describe('feedback/ in Storage', () => {
  it('the sender adds one JPEG or PNG (≤ 4 MB) named by the request', async () => {
    const id = randomUUID();
    await assertSucceeds(
      uploadBytes(ref(storage('mom'), `feedback/mom/${id}.png`), bytes(10), png),
    );
    await assertSucceeds(
      uploadBytes(ref(storage('mom'), `feedback/mom/${randomUUID()}.jpg`), bytes(10), jpeg),
    );
    // Once, never replaced; not read back or removed from the app.
    await assertFails(uploadBytes(ref(storage('mom'), `feedback/mom/${id}.png`), bytes(10), png));
    await assertFails(getBytes(ref(storage('mom'), `feedback/mom/${id}.png`)));
    await assertFails(deleteObject(ref(storage('mom'), `feedback/mom/${id}.png`)));
  });

  it("refuses someone else's folder, other names, types and sizes", async () => {
    const id = randomUUID();
    await assertFails(uploadBytes(ref(storage('dad'), `feedback/mom/${id}.png`), bytes(10), png));
    await assertFails(
      uploadBytes(
        ref(env.unauthenticatedContext().storage(), `feedback/mom/${id}.png`),
        bytes(10),
        png,
      ),
    );
    await assertFails(uploadBytes(ref(storage('mom'), `feedback/mom/shot.png`), bytes(10), png));
    await assertFails(
      uploadBytes(ref(storage('mom'), `feedback/mom/${id}.gif`), bytes(10), {
        contentType: 'image/gif',
      }),
    );
    await assertFails(
      uploadBytes(ref(storage('mom'), `feedback/mom/${id}.png`), bytes(10), {
        contentType: 'text/html',
      }),
    );
    await assertFails(
      uploadBytes(ref(storage('mom'), `feedback/mom/${id}.jpg`), bytes(4 * 1024 * 1024 + 1), jpeg),
    );
  });
});

describe('server-only documents', () => {
  it('tickets and the daily counters are not readable from the app', async () => {
    const db = env.authenticatedContext('mom').firestore();
    await assertFails(getDoc(doc(db, 'supportTickets/t_1')));
    await assertFails(getDoc(doc(db, 'appEventsDaily/2026-10-13')));
  });
});
