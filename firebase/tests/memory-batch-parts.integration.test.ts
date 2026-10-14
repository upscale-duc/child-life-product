import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import sharp from 'sharp';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { sharpImages } from '../functions/src/images.js';
import {
  closeWaitingBatches,
  createMemory,
  maybeNotifyBatch,
  onMediaWritten,
  processUpload,
  type MediaStore,
} from '../functions/src/memories.js';

// D-070: a Tự lưu "Tải lên" goes out as several memories of up to 30 items that share one batch,
// and the family hears once, with the whole count. Firestore emulator; Storage is a fake.
const projectId = 'demo-child-life-batch-parts';
const now = new Date('2026-10-14T08:00:00Z');
const hour = 3_600_000;
let app: App;
let db: Firestore;
const babyId = 'b_ba7c0000000000000001';
const familyId = 'f_ba7c0000000000000001';

class FakeStore implements MediaStore {
  files = new Map<string, { bytes: Uint8Array; contentType: string }>();
  async head(path: string, n: number) {
    return this.files.get(path)?.bytes.slice(0, n) ?? null;
  }
  async read(path: string) {
    return this.files.get(path)?.bytes ?? null;
  }
  async save(path: string, bytes: Uint8Array, contentType: string) {
    this.files.set(path, { bytes, contentType });
  }
  async move(from: string, to: string, contentType: string) {
    const f = this.files.get(from);
    if (!f) throw new Error('missing');
    this.files.delete(from);
    this.files.set(to, { bytes: f.bytes, contentType });
  }
  async size(path: string) {
    return this.files.get(path)?.bytes.length ?? null;
  }
  async delete(path: string) {
    this.files.delete(path);
  }
}

let seq = 0;
const id = (prefix: string) => `${prefix}_${(++seq).toString(16).padStart(32, '0')}`;

let jpeg: Uint8Array;

function photo(mediaId: string) {
  return {
    mediaId,
    type: 'photo',
    contentType: 'image/jpeg',
    sizeBytes: jpeg.length,
    captureAt: '2026-10-13T02:20:00.000Z',
    durationMs: null,
    width: null,
    height: null,
    hasPoster: false,
  };
}

/** One part of a batch: its own memory, the shared batch id. */
function part(batchId: string, mediaIds: string[], batchParts: number | null, extra = {}) {
  return {
    babyId,
    memoryId: id('mem'),
    batchId,
    caption: null,
    audience: 'family',
    notifyFamily: true,
    batchParts,
    dateMode: 'capture',
    date: null,
    milestone: null,
    items: mediaIds.map(photo),
    ...extra,
  };
}

/** Bytes land, the item is processed, and the media trigger runs. */
async function land(store: FakeStore, mediaId: string, at = now) {
  await store.save(`babies/${babyId}/uploads/${mediaId}`, jpeg, 'image/jpeg');
  await processUpload(db, store, sharpImages, `babies/${babyId}/uploads/${mediaId}`, at);
  const snap = await db.doc(`babies/${babyId}/media/${mediaId}`).get();
  await onMediaWritten(db, babyId, snap, null, at);
}

const notice = (batchId: string) => db.doc(`babies/${babyId}/notifications/${batchId}`).get();
const waiting = (batchId: string) => db.doc(`uploadBatchesWaiting/${batchId}`).get();

beforeAll(async () => {
  app = initializeApp({ projectId }, `batch-parts-${randomUUID()}`);
  db = getFirestore(app);
  jpeg = new Uint8Array(
    await sharp({ create: { width: 64, height: 48, channels: 3, background: '#e8c8a0' } })
      .jpeg()
      .toBuffer(),
  );
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  for (const c of ['babies', 'families', 'uploadBatchesWaiting']) {
    await db.recursiveDelete(db.collection(c));
  }
  const member = (uid: string, role: string) =>
    db.doc(`babies/${babyId}/members/${uid}`).set({
      uid,
      babyId,
      role,
      relation: 'other',
      relationCustom: null,
      displayName: uid,
      status: 'active',
    });
  await db.doc(`babies/${babyId}`).set({
    nickname: 'Teddy',
    familyId,
    timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' },
  });
  await db
    .doc(`families/${familyId}`)
    .set({ ownerUid: 'mom', quotaBytes: 10 * 1024 ** 3, usedBytes: 0, reservedBytes: 0 });
  await member('mom', 'coParent');
  await member('dad', 'coParent');
  await member('grandma', 'relative');
});

describe('a batch sent in parts (D-070)', () => {
  it('tells the family once, after the last part, with every item counted', async () => {
    const batchId = id('bat');
    const first = [id('med'), id('med')];
    const last = [id('med')];
    const store = new FakeStore();
    await createMemory(db, 'mom', part(batchId, first, null), now);
    expect((await waiting(batchId)).exists).toBe(true);
    // Everything in the first part is up before the last part has even arrived: no notice yet.
    for (const m of first) await land(store, m);
    expect((await notice(batchId)).exists).toBe(false);

    await createMemory(db, 'mom', part(batchId, last, 2), now);
    expect((await waiting(batchId)).exists).toBe(false);
    const batch = (await db.doc(`babies/${babyId}/uploadBatches/${batchId}`).get()).data()!;
    expect(batch.parts).toBe(2);
    expect(batch.memoryIds).toHaveLength(2);
    expect(batch.mediaIds).toEqual([...first, ...last]);
    expect((await notice(batchId)).exists).toBe(false);

    await land(store, last[0]!);
    const n = (await notice(batchId)).data()!;
    expect(n.count).toBe(3);
    expect(n.recipients.sort()).toEqual(['dad', 'grandma']);
    expect(await maybeNotifyBatch(db, babyId, batchId, now)).toBe('done');
  });

  it('a part counted ahead of a slower one still waits for it', async () => {
    const batchId = id('bat');
    const a = id('med');
    const b = id('med');
    const store = new FakeStore();
    // The last part (it knows there are two) arrives first.
    await createMemory(db, 'mom', part(batchId, [b], 2), now);
    await land(store, b);
    expect((await notice(batchId)).exists).toBe(false);
    await createMemory(db, 'mom', part(batchId, [a], null), now);
    await land(store, a);
    expect((await notice(batchId)).data()!.count).toBe(2);
  });

  it('only the same person, sharing the same way, joins a batch', async () => {
    const batchId = id('bat');
    await createMemory(db, 'mom', part(batchId, [id('med')], null), now);
    await expect(createMemory(db, 'dad', part(batchId, [id('med')], 2), now)).rejects.toThrow();
    await expect(
      createMemory(db, 'mom', part(batchId, [id('med')], 2, { audience: 'parents' }), now),
    ).rejects.toThrow();
    await expect(
      createMemory(db, 'mom', part(batchId, [id('med')], 2, { notifyFamily: false }), now),
    ).rejects.toThrow();
  });

  it('a batch whose last part never comes is closed with what arrived and told about', async () => {
    const batchId = id('bat');
    const a = id('med');
    const store = new FakeStore();
    await createMemory(db, 'mom', part(batchId, [a], null), now);
    await land(store, a);
    expect(await closeWaitingBatches(db, new Date(now.getTime() + hour))).toBe(0);
    expect((await notice(batchId)).exists).toBe(false);

    expect(await closeWaitingBatches(db, new Date(now.getTime() + 2 * hour))).toBe(1);
    expect((await notice(batchId)).data()!.count).toBe(1);
    expect((await waiting(batchId)).exists).toBe(false);
    expect(await closeWaitingBatches(db, new Date(now.getTime() + 3 * hour))).toBe(0);
  });

  it('a plain upload is one part and is told about as before', async () => {
    const batchId = id('bat');
    const a = id('med');
    const req = part(batchId, [a], 1);
    delete (req as Record<string, unknown>).batchParts;
    await createMemory(db, 'mom', req, now);
    expect((await waiting(batchId)).exists).toBe(false);
    await land(new FakeStore(), a);
    expect((await notice(batchId)).data()!.count).toBe(1);
  });
});
