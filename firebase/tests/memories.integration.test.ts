import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { Timestamp, getFirestore, type Firestore } from 'firebase-admin/firestore';
import sharp from 'sharp';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { defaultEntitlementsConfig, keepsakeSeedV1 } from '@child-life/contracts';
import { sharpImages } from '../functions/src/images.js';
import {
  cancelUploads,
  createMemory,
  maybeNotifyBatch,
  onMediaWritten,
  processUpload,
  purgeMediaBin,
  releaseStaleUploads,
  reserveUploads,
  updateMedia,
  type MediaStore,
} from '../functions/src/memories.js';

// S9 server side against the Firestore emulator (`pnpm test:rules`): upload sessions and quota
// (P-031), processing with metadata stripped (P-033), publish and the single batch notice
// (P-030, Q-019), batch actions (10b3, 10b4, 10o) and the jobs. Storage is an in-memory fake.
const projectId = 'demo-child-life';
const now = new Date('2026-10-08T08:05:00Z');
let app: App;
let db: Firestore;
const babyId = 'b_ca5e0000000000000009';
const familyId = 'f_ca5e0000000000000009';
const GB = 1024 ** 3;

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

/** A real JPEG carrying GPS in its EXIF, as a phone would write it. */
async function jpegWithGps(width = 1200, height = 900): Promise<Uint8Array> {
  const buf = await sharp({
    create: { width, height, channels: 3, background: { r: 240, g: 200, b: 160 } },
  })
    .jpeg()
    .withExif({ IFD3: { GPSLatitudeRef: 'N', GPSLatitude: '10/1 46/1 0/1' } })
    .toBuffer();
  return new Uint8Array(buf);
}

const mp4Head = () => {
  const b = new Uint8Array(4096);
  b.set(new TextEncoder().encode('\0\0\0\x18ftypisom'), 0);
  return b;
};

function photo(mediaId: string, sizeBytes: number) {
  return {
    mediaId,
    type: 'photo',
    contentType: 'image/jpeg',
    sizeBytes,
    captureAt: '2026-10-05T02:20:00.000Z',
    durationMs: null,
    width: null,
    height: null,
    hasPoster: false,
  };
}

function request(items: unknown[], overrides: Record<string, unknown> = {}) {
  return {
    babyId,
    memoryId: id('mem'),
    batchId: id('bat'),
    caption: 'Teddy cười khi nghe ba hát bài ru quen.',
    audience: 'family',
    notifyFamily: true,
    dateMode: 'capture',
    date: null,
    milestone: { id: 'p_first_smile', name: 'Lần đầu cười', date: '2026-10-05' },
    items,
    ...overrides,
  };
}

async function family() {
  return (await db.doc(`families/${familyId}`).get()).data()!;
}

/** What the media trigger does after each write. */
async function settle(mediaId: string) {
  const snap = await db.doc(`babies/${babyId}/media/${mediaId}`).get();
  await onMediaWritten(db, babyId, snap, null, now);
}

beforeAll(() => {
  app = initializeApp({ projectId }, `memories-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080'}/emulator/v1/projects/${projectId}/databases/(default)/documents`,
    {
      method: 'DELETE',
    },
  );
  const member = (uid: string, role: string, relation: string, name: string) =>
    db.doc(`babies/${babyId}/members/${uid}`).set({
      uid,
      babyId,
      role,
      relation,
      relationCustom: null,
      displayName: name,
      status: 'active',
    });
  await db.doc(`babies/${babyId}`).set({
    nickname: 'Teddy',
    familyId,
    timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' },
  });
  await db
    .doc(`families/${familyId}`)
    .set({ ownerUid: 'mom', quotaBytes: 10 * GB, usedBytes: 0, reservedBytes: 0 });
  await member('mom', 'coParent', 'mother', 'Mai');
  await member('dad', 'coParent', 'father', 'Minh');
  await member('nanny', 'caregiver', 'nanny', 'Cô Lan');
  await member('grandma', 'relative', 'grandmother', 'Bà nội Hoa');
});

describe('upload session (P-031)', () => {
  it('reserves quota per item and records memory, items and batch', async () => {
    const a = id('med');
    const b = id('med');
    const req = request([photo(a, 3_400_000), photo(b, 2_100_000)]);
    const res = await createMemory(db, 'mom', req, now);
    expect(res.reserved).toEqual([a, b]);
    expect(res.waitingQuota).toEqual([]);
    expect((await family()).reservedBytes).toBe(3_400_000 + 2_100_000 + 2 * 1_000_000);
    const memory = (await db.doc(`babies/${babyId}/memories/${req.memoryId}`).get()).data()!;
    expect(memory.state).toBe('uploading');
    expect(memory.author).toEqual({ name: 'Mai', relation: 'mother', relationCustom: null });
    const item = (await db.doc(`babies/${babyId}/media/${a}`).get()).data()!;
    expect(item.effectiveAudience).toBe('family');
    expect(item.milestone.name).toBe('Lần đầu cười');
    // Retried with the same ids: same answer, nothing reserved twice.
    expect(await createMemory(db, 'mom', req, now)).toEqual(res);
    expect((await family()).reservedBytes).toBe(7_500_000);
  });

  it('items over the quota wait on the device, then reserve when space frees (R-121)', async () => {
    await db.doc(`families/${familyId}`).update({ usedBytes: 10 * GB - 5_000_000 });
    const a = id('med');
    const b = id('med');
    const res = await createMemory(
      db,
      'mom',
      request([photo(a, 3_000_000), photo(b, 3_000_000)]),
      now,
    );
    expect(res.reserved).toEqual([a]);
    expect(res.waitingQuota).toEqual([b]);
    expect((await db.doc(`babies/${babyId}/media/${b}`).get()).get('status')).toBe('waitingQuota');
    expect(await reserveUploads(db, 'mom', { babyId, mediaIds: [b] }, now)).toEqual({
      reserved: [],
      waitingQuota: [b],
    });
    await db.doc(`families/${familyId}`).update({ usedBytes: 0 });
    expect((await reserveUploads(db, 'mom', { babyId, mediaIds: [b] }, now)).reserved).toEqual([b]);
  });

  it('only Cùng nuôi add memories; batches are capped by config', async () => {
    for (const uid of ['nanny', 'grandma', 'stranger']) {
      await expect(
        createMemory(db, uid, request([photo(id('med'), 1000)]), now),
      ).rejects.toMatchObject({
        code: 'permission-denied',
      });
    }
    await db.doc('config/limits').set({
      familyQuotaBytes: 10 * GB,
      videoMaxDurationSec: null,
      videoMaxBytes: 4 * GB,
      videoWifiOnlyDefault: true,
      mediaItemsPerAdd: 2,
      exportLinkTtlHours: 24,
      storageRequestAmountsGb: [10, 20],
    });
    await expect(
      createMemory(db, 'mom', request([1, 2, 3].map(() => photo(id('med'), 1000))), now),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('a text-only note is published at once (10a2 "Viết ghi chú")', async () => {
    const req = request([], { caption: 'Đêm qua con ngủ một mạch 4 tiếng.', audience: 'parents' });
    await createMemory(db, 'mom', req, now);
    const memory = (await db.doc(`babies/${babyId}/memories/${req.memoryId}`).get()).data()!;
    expect(memory.state).toBe('published');
    expect(memory.mediaIds).toEqual([]);
  });

  it('cancelling releases the reservation (10i ×)', async () => {
    const a = id('med');
    await createMemory(db, 'mom', request([photo(a, 2_000_000)]), now);
    const store = new FakeStore();
    store.files.set(`babies/${babyId}/uploads/${a}`, {
      bytes: new Uint8Array(10),
      contentType: 'image/jpeg',
    });
    expect(await cancelUploads(db, store, 'mom', { babyId, mediaIds: [a] }, now)).toEqual({
      cancelled: [a],
    });
    expect((await family()).reservedBytes).toBe(0);
    expect(store.files.size).toBe(0);
  });
});

describe('processing (P-033) and publish (P-030)', () => {
  it('re-encodes a photo without EXIF/GPS, commits quota and publishes the memory', async () => {
    const a = id('med');
    const raw = await jpegWithGps();
    expect((await sharp(raw).metadata()).exif).toBeDefined();
    const req = request([photo(a, raw.length)]);
    await createMemory(db, 'mom', req, now);
    const store = new FakeStore();
    await store.save(`babies/${babyId}/uploads/${a}`, raw, 'image/jpeg');
    expect(await processUpload(db, store, sharpImages, `babies/${babyId}/uploads/${a}`, now)).toBe(
      'ready',
    );
    for (const v of ['original', 'display', 'thumb']) {
      const out = store.files.get(`babies/${babyId}/media/${a}/${v}.jpg`)!;
      expect(out.contentType).toBe('image/jpeg');
      expect((await sharp(out.bytes).metadata()).exif).toBeUndefined();
    }
    expect(store.files.has(`babies/${babyId}/uploads/${a}`)).toBe(false);
    const item = (await db.doc(`babies/${babyId}/media/${a}`).get()).data()!;
    expect(item.status).toBe('ready');
    expect([item.width, item.height]).toEqual([1200, 900]);
    const fam = await family();
    expect(fam.reservedBytes).toBe(0);
    expect(fam.usedBytes).toBe(item.storedBytes);

    await settle(a);
    const memory = (await db.doc(`babies/${babyId}/memories/${req.memoryId}`).get()).data()!;
    expect(memory.state).toBe('published');
    expect(memory.counts).toEqual({ photos: 1, videos: 0 });
    expect(memory.coverMediaId).toBe(a);
    // "Đã báo cho Bà nội…": one notice to the other parent and the relative, never the nanny.
    const notice = (await db.doc(`babies/${babyId}/notifications/${req.batchId}`).get()).data()!;
    expect(notice.count).toBe(1);
    expect(notice.recipients.sort()).toEqual(['dad', 'grandma']);
    expect(await maybeNotifyBatch(db, babyId, req.batchId, now)).toBe('done');
  });

  it('bytes that land while the baby is being deleted are dropped (not checked by Storage Rules)', async () => {
    const a = id('med');
    const raw = await jpegWithGps();
    await createMemory(db, 'mom', request([photo(a, raw.length)]), now);
    await db.doc(`babies/${babyId}`).update({ state: 'deleting' });
    const store = new FakeStore();
    await store.save(`babies/${babyId}/uploads/${a}`, raw, 'image/jpeg');
    expect(await processUpload(db, store, sharpImages, `babies/${babyId}/uploads/${a}`, now)).toBe(
      'ignored',
    );
    expect(store.files.size).toBe(0);
    await db.doc(`babies/${babyId}`).update({ state: 'active' });
  });

  it('refuses what is not really a photo and gives the bytes back (unreadable)', async () => {
    const a = id('med');
    const html = new TextEncoder().encode('<!doctype html><script>');
    await createMemory(db, 'mom', request([photo(a, 1000)]), now);
    const store = new FakeStore();
    await store.save(`babies/${babyId}/uploads/${a}`, html, 'image/jpeg');
    expect(await processUpload(db, store, sharpImages, `babies/${babyId}/uploads/${a}`, now)).toBe(
      'unreadable',
    );
    expect((await db.doc(`babies/${babyId}/media/${a}`).get()).get('status')).toBe('unreadable');
    expect((await family()).reservedBytes).toBe(0);
    expect(store.files.size).toBe(0);
  });

  it('a video keeps its bytes, gets its poster and plays from original.mp4', async () => {
    const v = id('med');
    const head = mp4Head();
    await createMemory(
      db,
      'mom',
      request([
        {
          ...photo(v, head.length),
          type: 'video',
          contentType: 'video/mp4',
          durationMs: 24_000,
          hasPoster: true,
        },
      ]),
      now,
    );
    const store = new FakeStore();
    await store.save(
      `babies/${babyId}/uploads/${v}.poster`,
      await jpegWithGps(640, 360),
      'image/jpeg',
    );
    expect(
      await processUpload(db, store, sharpImages, `babies/${babyId}/uploads/${v}.poster`, now),
    ).toBe('poster');
    await store.save(`babies/${babyId}/uploads/${v}`, head, 'video/mp4');
    expect(await processUpload(db, store, sharpImages, `babies/${babyId}/uploads/${v}`, now)).toBe(
      'ready',
    );
    const item = (await db.doc(`babies/${babyId}/media/${v}`).get()).data()!;
    expect(item.paths).toEqual({
      original: `babies/${babyId}/media/${v}/original.mp4`,
      display: null,
      thumb: `babies/${babyId}/media/${v}/thumb.jpg`,
      poster: `babies/${babyId}/media/${v}/poster.jpg`,
    });
    expect(store.files.get(item.paths.original)?.contentType).toBe('video/mp4');
  });

  it('a poster that lands after its video is still linked and counted', async () => {
    const v = id('med');
    const head = mp4Head();
    await createMemory(
      db,
      'mom',
      request([
        {
          ...photo(v, head.length),
          type: 'video',
          contentType: 'video/mp4',
          durationMs: 24_000,
          hasPoster: true,
        },
      ]),
      now,
    );
    const store = new FakeStore();
    await store.save(`babies/${babyId}/uploads/${v}`, head, 'video/mp4');
    expect(await processUpload(db, store, sharpImages, `babies/${babyId}/uploads/${v}`, now)).toBe(
      'ready',
    );
    const before = (await db.doc(`babies/${babyId}/media/${v}`).get()).data()!;
    expect(before.paths.poster).toBeNull();
    const used = (await family()).usedBytes as number;
    await store.save(
      `babies/${babyId}/uploads/${v}.poster`,
      await jpegWithGps(640, 360),
      'image/jpeg',
    );
    expect(
      await processUpload(db, store, sharpImages, `babies/${babyId}/uploads/${v}.poster`, now),
    ).toBe('poster');
    const item = (await db.doc(`babies/${babyId}/media/${v}`).get()).data()!;
    expect(item.paths.poster).toBe(`babies/${babyId}/media/${v}/poster.jpg`);
    expect(item.paths.thumb).toBe(`babies/${babyId}/media/${v}/thumb.jpg`);
    expect(item.storedBytes).toBe(before.storedBytes + item.posterBytes);
    expect((await family()).usedBytes).toBe(used + item.posterBytes);
  });

  it('the batch notice waits for uploads but not for Wi-Fi waits (Q-019)', async () => {
    const a = id('med');
    const v = id('med');
    const req = request([
      photo(a, 0),
      {
        ...photo(v, 48_000_000),
        type: 'video',
        contentType: 'video/quicktime',
        durationMs: 24_000,
        hasPoster: false,
      },
    ]);
    req.items[0] = photo(a, (await jpegWithGps()).length);
    await createMemory(db, 'mom', req, now);
    const store = new FakeStore();
    await store.save(`babies/${babyId}/uploads/${a}`, await jpegWithGps(), 'image/jpeg');
    await processUpload(db, store, sharpImages, `babies/${babyId}/uploads/${a}`, now);
    await settle(a);
    expect((await db.doc(`babies/${babyId}/notifications/${req.batchId}`).get()).exists).toBe(
      false,
    );
    await db.doc(`babies/${babyId}/media/${v}`).update({ clientState: 'waitingWifi' });
    await settle(v);
    expect((await db.doc(`babies/${babyId}/notifications/${req.batchId}`).get()).get('count')).toBe(
      1,
    );
  });

  it('Chỉ ba mẹ batches notify nobody', async () => {
    const a = id('med');
    const raw = await jpegWithGps();
    const req = request([photo(a, raw.length)], { audience: 'parents' });
    await createMemory(db, 'mom', req, now);
    const store = new FakeStore();
    await store.save(`babies/${babyId}/uploads/${a}`, raw, 'image/jpeg');
    await processUpload(db, store, sharpImages, `babies/${babyId}/uploads/${a}`, now);
    await settle(a);
    expect((await db.doc(`babies/${babyId}/notifications/${req.batchId}`).get()).exists).toBe(
      false,
    );
    expect(
      (await db.doc(`babies/${babyId}/uploadBatches/${req.batchId}`).get()).get('closed'),
    ).toBe(true);
  });
});

describe('batch actions (10b3, 10b4, 10o)', () => {
  async function readyPhoto(audience = 'family') {
    const a = id('med');
    const raw = await jpegWithGps();
    const req = request([photo(a, raw.length)], { audience });
    await createMemory(db, 'mom', req, now);
    const store = new FakeStore();
    await store.save(`babies/${babyId}/uploads/${a}`, raw, 'image/jpeg');
    await processUpload(db, store, sharpImages, `babies/${babyId}/uploads/${a}`, now);
    await settle(a);
    return { a, req, store };
  }

  it('sharing private items with the family sends one generic notice (R-118)', async () => {
    const { a } = await readyPhoto('parents');
    const res = await updateMedia(
      db,
      'dad',
      {
        babyId,
        mediaIds: [a],
        change: { kind: 'audience', audience: 'family', notifyFamily: true },
      },
      now,
    );
    expect(res.updated).toEqual([a]);
    const item = (await db.doc(`babies/${babyId}/media/${a}`).get()).data()!;
    expect(item.effectiveAudience).toBe('family');
    const notice = (
      await db.doc(`babies/${babyId}/notifications/${res.notificationId}`).get()
    ).data()!;
    expect(notice.kind).toBe('shared');
    expect(notice.recipients.sort()).toEqual(['grandma', 'mom']);
    // MEMORIES_SHARED: the notice names its share, and the shared items carry it (ids only).
    expect(notice.sourceCollection).toBe('shares');
    expect(notice.sourceId).toMatch(/^sh_[a-f0-9]{32}$/);
    expect(item.sharedIn).toEqual([notice.sourceId]);
  });

  it('"Đổi ngày" keeps the time of day in the baby’s zone; "Gắn mốc" tags items', async () => {
    const { a } = await readyPhoto();
    await updateMedia(
      db,
      'mom',
      { babyId, mediaIds: [a], change: { kind: 'date', date: '2026-10-01' } },
      now,
    );
    expect(
      ((await db.doc(`babies/${babyId}/media/${a}`).get()).get('captureAt') as Timestamp)
        .toDate()
        .toISOString(),
    ).toBe('2026-10-01T02:20:00.000Z');
    const milestone = { id: 'p_first_bath', name: 'Lần đầu tắm', date: '2026-10-01' };
    await updateMedia(
      db,
      'mom',
      { babyId, mediaIds: [a], change: { kind: 'milestone', milestone } },
      now,
    );
    expect((await db.doc(`babies/${babyId}/media/${a}`).get()).get('milestone')).toEqual(milestone);
  });

  it('delete → "Đã xoá gần đây"; restore within 30 days; purge frees the quota', async () => {
    const { a, req, store } = await readyPhoto();
    const used = (await family()).usedBytes as number;
    expect(used).toBeGreaterThan(0);
    await updateMedia(db, 'mom', { babyId, mediaIds: [a], change: { kind: 'delete' } }, now);
    await settle(a);
    expect((await db.doc(`babies/${babyId}/memories/${req.memoryId}`).get()).get('deleted')).toBe(
      true,
    );
    await updateMedia(db, 'mom', { babyId, mediaIds: [a], change: { kind: 'restore' } }, now);
    await settle(a);
    expect((await db.doc(`babies/${babyId}/memories/${req.memoryId}`).get()).get('deleted')).toBe(
      false,
    );

    await updateMedia(db, 'mom', { babyId, mediaIds: [a], change: { kind: 'delete' } }, now);
    const later = new Date(now.getTime() + 31 * 86_400_000);
    expect(await purgeMediaBin(db, store, later)).toBe(1);
    expect((await db.doc(`babies/${babyId}/media/${a}`).get()).exists).toBe(false);
    expect((await family()).usedBytes).toBe(0);
    expect([...store.files.keys()].some((k) => k.includes(a))).toBe(false);
  });

  it('only Cùng nuôi change items', async () => {
    const { a } = await readyPhoto();
    for (const uid of ['grandma', 'nanny']) {
      await expect(
        updateMedia(db, uid, { babyId, mediaIds: [a], change: { kind: 'delete' } }, now),
      ).rejects.toMatchObject({ code: 'permission-denied' });
    }
  });

  it('unused reservations are released after 24 h (P-031)', async () => {
    const a = id('med');
    await createMemory(db, 'mom', request([photo(a, 2_000_000)]), now);
    const later = new Date(now.getTime() + 25 * 3_600_000);
    expect(await releaseStaleUploads(db, new FakeStore(), later)).toBe(1);
    expect((await db.doc(`babies/${babyId}/media/${a}`).get()).get('status')).toBe('cancelled');
    expect((await family()).reservedBytes).toBe(0);
  });
});

describe('Thiệp cột mốc saved to Kỷ niệm (D-068)', () => {
  const generated = {
    kind: 'card',
    templateId: 'card_round',
    templateVersion: 2,
    occasion: 'm1',
    format: 'portrait',
  };
  const on = (enabled: boolean) => ({
    enabled,
    scope: 'all',
    percent: 0,
    notice: null,
  });
  /** The catalog as published from the portal: card_round at version 2. */
  const publish = (access: 'everyone' | 'hidden' | 'subscribers' = 'everyone') =>
    db.doc('publicConfig/keepsakes').set({
      version: 'ks_20261013_01',
      templates: keepsakeSeedV1.templates.map((t) =>
        t.id === 'card_round' ? { ...t, version: 2 } : t,
      ),
      premium: { access, badges: true },
    });
  beforeEach(() => publish());

  it('needs the milestone_cards beta flag for the family', async () => {
    const a = id('med');
    await expect(
      createMemory(db, 'mom', request([photo(a, 900_000)], { generated }), now),
    ).rejects.toMatchObject({ reason: 'not-enabled' });
    await db.doc('config/flags').set({ media_upload: on(true), milestone_cards: on(false) });
    await expect(
      createMemory(db, 'mom', request([photo(a, 900_000)], { generated }), now),
    ).rejects.toMatchObject({ reason: 'not-enabled' });
  });

  it('keeps the template and version on the memory and its item; quota is reserved as usual', async () => {
    await db.doc('config/flags').set({ media_upload: on(true), milestone_cards: on(true) });
    const a = id('med');
    const req = request([photo(a, 900_000)], {
      generated,
      audience: 'parents',
      notifyFamily: false,
      dateMode: 'single',
      date: '2026-10-08',
      caption: null,
    });
    const r = await createMemory(db, 'mom', req, now);
    expect(r.reserved).toEqual([a]);
    expect(
      (await db.doc(`babies/${babyId}/memories/${req.memoryId}`).get()).get('generated'),
    ).toEqual(generated);
    expect((await db.doc(`babies/${babyId}/media/${a}`).get()).get('generated')).toEqual(generated);
    expect((await family()).reservedBytes).toBeGreaterThan(0);
  });

  it('a card is one photo', async () => {
    await db.doc('config/flags').set({ media_upload: on(true), milestone_cards: on(true) });
    await expect(
      createMemory(
        db,
        'mom',
        request([photo(id('med'), 1000), photo(id('med'), 1000)], { generated }),
        now,
      ),
    ).rejects.toMatchObject({ reason: 'malformed' });
  });

  it('only a published card at a published version, under the portal’s Cao cấp setting (D-068 #8)', async () => {
    await db.doc('config/flags').set({ media_upload: on(true), milestone_cards: on(true) });
    const save = (g: Record<string, unknown>) =>
      createMemory(db, 'mom', request([photo(id('med'), 1000)], { generated: g }), now);
    await expect(save({ ...generated, templateVersion: 3 })).rejects.toMatchObject({
      reason: 'template-unavailable',
    });
    await expect(save({ ...generated, templateId: 'card_nope' })).rejects.toMatchObject({
      reason: 'template-unavailable',
    });
    await expect(save({ ...generated, templateId: 'video_first_month' })).rejects.toMatchObject({
      reason: 'template-unavailable',
    });
    // An older version the phone still holds is fine.
    await save({ ...generated, templateVersion: 1 });
    // Cao cấp: open to everyone in the beta; refused once the portal hides it.
    const blush = { ...generated, templateId: 'card_blush', templateVersion: 1 };
    await save(blush);
    await publish('hidden');
    await expect(save(blush)).rejects.toMatchObject({ reason: 'template-unavailable' });
    await save(generated);
  });

  it('subscribers mode: Cao cấp needs templates.premium; Beta A never opens it (Q1, E03, MO02)', async () => {
    await db.doc('config/flags').set({ media_upload: on(true), milestone_cards: on(true) });
    await db.doc(`families/${familyId}`).set({ country: 'VN' }, { merge: true });
    await db.doc('config/entitlements').set({
      ...defaultEntitlementsConfig,
      regions: { advanced: ['VN'] },
      betaCampaigns: [
        {
          id: 'beta-a',
          capabilities: ['personalization.cross_module', 'rhythm.advanced', 'ai.assistance'],
          validFrom: '2026-10-01T00:00:00Z',
          validUntil: '2026-12-01T00:00:00Z',
          countries: [],
          scope: 'all',
          percent: 0,
        },
      ],
    });
    await publish('subscribers');
    const save = (g: Record<string, unknown>) =>
      createMemory(db, 'mom', request([photo(id('med'), 1000)], { generated: g }), now);
    const blush = { ...generated, templateId: 'card_blush', templateVersion: 1 };
    await expect(save(blush)).rejects.toMatchObject({ reason: 'PREMIUM_REQUIRED' });
    // A free template never needs a plan.
    await save(generated);
    await db.doc(`families/${familyId}/grants/paid_test`).set({
      familyId,
      source: 'paid',
      status: 'active',
      environment: 'test',
      capabilities: [
        'personalization.cross_module',
        'rhythm.advanced',
        'ai.assistance',
        'templates.premium',
      ],
      validFrom: Timestamp.fromDate(new Date('2026-10-01T00:00:00Z')),
      validUntil: Timestamp.fromDate(new Date('2026-11-01T00:00:00Z')),
      billingOwnerUid: 'mom',
      provider: 'apple',
      sourceRef: 'apple_test',
      campaignId: null,
      autoRenew: true,
      updatedAt: Timestamp.fromDate(new Date('2026-10-01T00:00:00Z')),
    });
    await save(blush);
  });
});
