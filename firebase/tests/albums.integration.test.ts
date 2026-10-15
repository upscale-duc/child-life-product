import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  addToAlbum,
  createAlbum,
  deleteAlbum,
  removeFromAlbum,
  updateAlbum,
} from '../functions/src/albums.js';
import { createMemory, onMediaWritten, updateMedia } from '../functions/src/memories.js';
import {
  deliverNotice,
  noticeCopy,
  onMessageCreated,
  onReactionWritten,
  type PushSender,
} from '../functions/src/social.js';

// S10 server side against the Firestore emulator: album membership and effective audience
// (D-002, P-035), counts and covers, compose into albums (10h5), loves, messages (D-034) and
// generic notice delivery (R-120).
const projectId = 'demo-child-life';
const now = new Date('2026-10-08T08:05:00Z');
let app: App;
let db: Firestore;
const babyId = 'b_ca5e0000000000000010';
const familyId = 'f_ca5e0000000000000010';

let seq = 0;
const id = (p: string) => `${p}_${(++seq).toString(16).padStart(32, '0')}`;

async function readyItem(audience: 'family' | 'parents', type: 'photo' | 'video' = 'photo') {
  const mediaId = id('med');
  await db.doc(`babies/${babyId}/media/${mediaId}`).set({
    id: mediaId,
    babyId,
    memoryId: 'mem_x',
    familyId,
    type,
    audience,
    effectiveAudience: audience,
    albumIds: [],
    status: 'ready',
    deleted: false,
    captureAt: new Date(now.getTime() - ++seq * 60_000),
    createdBy: 'mom',
  });
  return mediaId;
}

const media = async (m: string) => (await db.doc(`babies/${babyId}/media/${m}`).get()).data()!;
const album = async (a: string) => (await db.doc(`babies/${babyId}/albums/${a}`).get()).data()!;

beforeAll(() => {
  app = initializeApp({ projectId }, `albums-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  await fetch(
    `http://127.0.0.1:8080/emulator/v1/projects/${projectId}/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  await db.doc(`babies/${babyId}`).set({
    nickname: 'Teddy',
    familyId,
    timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' },
  });
  await db
    .doc(`families/${familyId}`)
    .set({ quotaBytes: 10 * 1024 ** 3, usedBytes: 0, reservedBytes: 0 });
  for (const [uid, role, relation, name] of [
    ['mom', 'coParent', 'mother', 'Mai'],
    ['dad', 'coParent', 'father', 'Minh'],
    ['nanny', 'caregiver', 'nanny', 'Cô Lan'],
    ['grandma', 'relative', 'grandmother', 'Bà nội Hoa'],
  ] as const) {
    await db.doc(`babies/${babyId}/members/${uid}`).set({
      uid,
      babyId,
      role,
      relation,
      relationCustom: null,
      displayName: name,
      status: 'active',
    });
  }
});

describe('albums and effective audience (D-002, P-035)', () => {
  it('a Gia đình album shares its private items; leaving it takes the share back', async () => {
    const p = await readyItem('parents');
    const a = id('alb');
    await createAlbum(
      db,
      'mom',
      { babyId, albumId: a, name: 'Giờ tắm', audience: 'family', mediaIds: [p] },
      now,
    );
    expect((await media(p)).effectiveAudience).toBe('family');
    expect((await media(p)).albumIds).toEqual([a]);
    expect((await album(a)).counts).toEqual({ photos: 1, videos: 0 });
    expect((await album(a)).coverMediaId).toBe(p);
    await removeFromAlbum(db, 'mom', { babyId, albumId: a, mediaIds: [p] }, now);
    expect((await media(p)).effectiveAudience).toBe('parents');
    expect((await album(a)).counts).toEqual({ photos: 0, videos: 0 });
  });

  it('later items follow the album (R-104)', async () => {
    const a = id('alb');
    await createAlbum(
      db,
      'mom',
      { babyId, albumId: a, name: 'Bàn tay nhỏ', audience: 'family', mediaIds: [] },
      now,
    );
    const p = await readyItem('parents');
    await addToAlbum(db, 'dad', { babyId, albumId: a, mediaIds: [p] }, now);
    expect((await media(p)).effectiveAudience).toBe('family');
  });

  it('Chỉ ba mẹ makes the items private, except those in another Gia đình album', async () => {
    const shared = await readyItem('family');
    const both = await readyItem('family');
    const a = id('alb');
    const b = id('alb');
    await createAlbum(
      db,
      'mom',
      { babyId, albumId: a, name: 'A', audience: 'family', mediaIds: [shared, both] },
      now,
    );
    await createAlbum(
      db,
      'mom',
      { babyId, albumId: b, name: 'B', audience: 'family', mediaIds: [both] },
      now,
    );
    const r = await updateAlbum(
      db,
      'mom',
      {
        babyId,
        albumId: a,
        change: { kind: 'audience', audience: 'parents', notifyFamily: false },
      },
      now,
    );
    expect(r.stayingShared).toBe(1);
    expect((await media(shared)).audience).toBe('parents');
    expect((await media(shared)).effectiveAudience).toBe('parents');
    expect((await media(both)).effectiveAudience).toBe('family');
  });

  it('sharing an album tells the family once, generically', async () => {
    const p = await readyItem('parents');
    const a = id('alb');
    await createAlbum(
      db,
      'mom',
      { babyId, albumId: a, name: 'Ngủ ngoan', audience: 'parents', mediaIds: [p] },
      now,
    );
    const r = await updateAlbum(
      db,
      'mom',
      { babyId, albumId: a, change: { kind: 'audience', audience: 'family', notifyFamily: true } },
      now,
    );
    const notice = (
      await db.doc(`babies/${babyId}/notifications/${r.notificationId}`).get()
    ).data()!;
    expect(notice.kind).toBe('album');
    expect(notice.count).toBe(1);
    expect(notice.recipients.sort()).toEqual(['dad', 'grandma']);
  });

  it('rename, cover, sort; delete keeps the items (R-106)', async () => {
    const p1 = await readyItem('family');
    const p2 = await readyItem('parents');
    const a = id('alb');
    await createAlbum(
      db,
      'mom',
      { babyId, albumId: a, name: 'Giờ tắm', audience: 'family', mediaIds: [p1, p2] },
      now,
    );
    await updateAlbum(
      db,
      'mom',
      { babyId, albumId: a, change: { kind: 'rename', name: 'Giờ tắm của Teddy' } },
      now,
    );
    await updateAlbum(
      db,
      'mom',
      { babyId, albumId: a, change: { kind: 'cover', mediaId: p2 } },
      now,
    );
    await updateAlbum(
      db,
      'mom',
      { babyId, albumId: a, change: { kind: 'sort', sort: 'oldest' } },
      now,
    );
    const al = await album(a);
    expect([al.name, al.coverMediaId, al.sort]).toEqual(['Giờ tắm của Teddy', p2, 'oldest']);
    await expect(
      updateAlbum(
        db,
        'mom',
        { babyId, albumId: a, change: { kind: 'cover', mediaId: id('med') } },
        now,
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
    await deleteAlbum(db, 'mom', { babyId, albumId: a }, now);
    expect((await db.doc(`babies/${babyId}/albums/${a}`).get()).exists).toBe(false);
    expect((await media(p1)).effectiveAudience).toBe('family');
    expect((await media(p2)).effectiveAudience).toBe('parents');
    expect((await media(p2)).albumIds).toEqual([]);
  });

  it('only Cùng nuôi change albums', async () => {
    for (const uid of ['grandma', 'nanny']) {
      await expect(
        createAlbum(
          db,
          uid,
          { babyId, albumId: id('alb'), name: 'x', audience: 'family', mediaIds: [] },
          now,
        ),
      ).rejects.toMatchObject({ code: 'permission-denied' });
    }
  });

  it('compose into a Gia đình album (10h5) makes a private item effectively shared', async () => {
    const a = id('alb');
    await createAlbum(
      db,
      'mom',
      { babyId, albumId: a, name: 'Giờ tắm', audience: 'family', mediaIds: [] },
      now,
    );
    const m = id('med');
    await createMemory(
      db,
      'mom',
      {
        babyId,
        memoryId: id('mem'),
        batchId: id('bat'),
        caption: null,
        audience: 'parents',
        notifyFamily: false,
        dateMode: 'capture',
        date: null,
        milestone: null,
        albumIds: [a],
        items: [
          {
            mediaId: m,
            type: 'photo',
            contentType: 'image/jpeg',
            sizeBytes: 1000,
            captureAt: '2026-10-08T02:00:00.000Z',
            durationMs: null,
            width: null,
            height: null,
            hasPoster: false,
          },
        ],
      },
      now,
    );
    expect((await media(m)).effectiveAudience).toBe('family');
    expect((await db.doc(`babies/${babyId}/albums/${a}/items/${m}`).get()).exists).toBe(true);
  });

  it('item audience changes go through albums too (10b3 "Ai thấy")', async () => {
    const p = await readyItem('family');
    const a = id('alb');
    await createAlbum(
      db,
      'mom',
      { babyId, albumId: a, name: 'A', audience: 'family', mediaIds: [p] },
      now,
    );
    await updateMedia(
      db,
      'mom',
      {
        babyId,
        mediaIds: [p],
        change: { kind: 'audience', audience: 'parents', notifyFamily: false },
      },
      now,
    );
    // Still in a Gia đình album: the family keeps seeing it (most permissive wins).
    expect((await media(p)).audience).toBe('parents');
    expect((await media(p)).effectiveAudience).toBe('family');
  });

  it('album counts follow item changes through the media trigger', async () => {
    const p = await readyItem('family', 'video');
    const a = id('alb');
    await createAlbum(
      db,
      'mom',
      { babyId, albumId: a, name: 'A', audience: 'family', mediaIds: [p] },
      now,
    );
    expect((await album(a)).counts).toEqual({ photos: 0, videos: 1 });
    const before = await db.doc(`babies/${babyId}/media/${p}`).get();
    await db.doc(`babies/${babyId}/media/${p}`).update({ deleted: true });
    const after = await db.doc(`babies/${babyId}/media/${p}`).get();
    await onMediaWritten(db, babyId, after, before, now);
    expect((await album(a)).counts).toEqual({ photos: 0, videos: 0 });
  });
});

describe('loves, messages and notices', () => {
  it('a love moves its target’s count, and back', async () => {
    const p = await readyItem('family');
    const ref = db.doc(`babies/${babyId}/reactions/media__${p}__grandma`);
    await ref.set({ uid: 'grandma', target: 'media', targetId: p, createdAt: now });
    await onReactionWritten(db, babyId, null, await ref.get());
    expect((await media(p)).loveCount).toBe(1);
    const gone = await ref.get();
    await ref.delete();
    await onReactionWritten(db, babyId, gone, null);
    expect((await media(p)).loveCount).toBe(0);
  });

  it('"Nhắn ba mẹ" becomes one notice for the parents (D-034)', async () => {
    const msg = db.doc(`babies/${babyId}/messages/msg_${'1'.repeat(32)}`);
    await msg.set({
      from: 'grandma',
      author: { name: 'Bà nội Hoa', relation: 'grandmother', relationCustom: null },
      context: { kind: 'media', id: 'med_x' },
      text: 'Bà thương con.',
    });
    await onMessageCreated(db, babyId, await msg.get(), now);
    const n = (await db.doc(`babies/${babyId}/notifications/message_${msg.id}`).get()).data()!;
    expect(n.kind).toBe('message');
    expect(n.recipients.sort()).toEqual(['dad', 'mom']);
  });

  it('delivers once, in each device’s language, and forgets dead tokens', async () => {
    // Other files on this emulator leave devices for the same uids (vitest orders files by
    // duration, not name): start from none.
    for (const uid of ['grandma', 'dad']) {
      await db.recursiveDelete(db.collection(`users/${uid}/devices`));
    }
    await db
      .doc(`users/grandma/devices/d_${'1'.repeat(32)}`)
      .set({ token: 't-vi', language: 'vi', platform: 'android' });
    await db
      .doc(`users/dad/devices/d_${'2'.repeat(32)}`)
      .set({ token: 't-en', language: 'en', platform: 'ios' });
    await db
      .doc(`users/dad/devices/d_${'3'.repeat(32)}`)
      .set({ token: 't-dead', language: 'en', platform: 'ios' });
    await db.doc(`babies/${babyId}/notifications/n1`).set({
      kind: 'memories',
      count: 7,
      actor: { name: 'Mai' },
      recipients: ['grandma', 'dad'],
      delivered: false,
    });
    const sent: { tokens: string[]; title: string; body: string }[] = [];
    const sender: PushSender = {
      async send(tokens, m) {
        sent.push({ tokens, title: m.title, body: m.body });
        return tokens.filter((t) => t === 't-dead');
      },
    };
    expect(await deliverNotice(db, sender, babyId, 'n1', now)).toEqual({ sent: 2 });
    expect(sent).toContainEqual({
      tokens: ['t-vi'],
      title: 'Có 7 khoảnh khắc mới',
      body: 'Mai vừa chia sẻ với gia đình. Mở để xem.',
    });
    expect(sent.find((s) => s.tokens.includes('t-en'))?.title).toBe('7 new moments');
    // D-076 #2: the dead token goes; the install stays in "Thiết bị đang đăng nhập" (13n).
    const dead = await db.doc(`users/dad/devices/d_${'3'.repeat(32)}`).get();
    expect(dead.exists).toBe(true);
    expect(dead.get('token')).toBeUndefined();
    expect(await deliverNotice(db, sender, babyId, 'n1', now)).toEqual({ sent: 0 });
  });

  it('notice copy never names the baby or quotes anything (R-120)', () => {
    const c = noticeCopy('message', 1, 'Bà nội Hoa', 'vi');
    expect(c.title).toBe('Có lời nhắn mới');
    expect(`${c.title} ${c.body}`).not.toContain('Teddy');
  });
});
