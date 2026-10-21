import { FieldValue, type Firestore, type Timestamp } from 'firebase-admin/firestore';
import {
  albumItemsRequestSchema,
  createAlbumRequestSchema,
  deleteAlbumRequestSchema,
  itemsStayingShared,
  updateAlbumRequestSchema,
  type Audience,
} from '@child-life/contracts';
import { MemoryError } from './memories.js';

/**
 * Albums (S10, 10d–10e10). Functions own albums, their membership (`albums/{a}/items/{m}` and
 * `media.albumIds`) and every item's effective audience (D-002, P-035): Gia đình if the item
 * itself is, or it sits in any Gia đình album. Album names and contents are never logged.
 */

async function requireParent(db: Firestore, babyId: string, uid: string, now: Date) {
  const m = await db.doc(`babies/${babyId}/members/${uid}`).get();
  const until = m.get('accessUntilAt') as Timestamp | null | undefined;
  const ok =
    m.exists &&
    m.get('status') === 'active' &&
    m.get('role') === 'coParent' &&
    (!until || until.toMillis() > now.getTime());
  if (!ok) throw new MemoryError('permission-denied', 'not-allowed');
  return {
    name: (m.get('displayName') as string | undefined) ?? '',
    relation: (m.get('relation') as string | undefined) ?? 'other',
    relationCustom: (m.get('relationCustom') as string | null | undefined) ?? null,
  };
}

function chunks<T>(list: readonly T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size));
  return out;
}

/**
 * Writes the effective audience of [mediaIds] from their own audience and their albums';
 * returns the items that became visible to the family (for "Báo cho gia đình").
 */
export async function recomputeEffective(
  db: Firestore,
  babyId: string,
  mediaIds: readonly string[],
  now: Date,
): Promise<string[]> {
  if (mediaIds.length === 0) return [];
  const widened: string[] = [];
  for (const part of chunks(mediaIds, 300)) {
    const snaps = await db.getAll(...part.map((m) => db.doc(`babies/${babyId}/media/${m}`)));
    const albumIds = new Set<string>();
    for (const s of snaps) {
      for (const a of (s.get('albumIds') as string[] | undefined) ?? []) albumIds.add(a);
    }
    const albums = albumIds.size
      ? await db.getAll(...[...albumIds].map((a) => db.doc(`babies/${babyId}/albums/${a}`)))
      : [];
    const family = new Set(
      albums.filter((a) => a.exists && a.get('audience') === 'family').map((a) => a.id),
    );
    const writer = db.batch();
    let n = 0;
    for (const s of snaps) {
      if (!s.exists) continue;
      const own = s.get('audience') as Audience;
      // In a Gia đình album, or shown in a saved Gia đình story (D-002, S12).
      const inFamily =
        ((s.get('albumIds') as string[] | undefined) ?? []).some((a) => family.has(a)) ||
        ((s.get('familyStoryIds') as string[] | undefined) ?? []).length > 0;
      const next: Audience = own === 'family' || inFamily ? 'family' : 'parents';
      const before = s.get('effectiveAudience') as Audience;
      if (next === before) continue;
      writer.update(s.ref, { effectiveAudience: next, updatedAt: now });
      n++;
      if (next === 'family' && s.get('status') === 'ready' && s.get('deleted') !== true) {
        widened.push(s.id);
      }
    }
    if (n > 0) await writer.commit();
  }
  return widened;
}

/** Counts, cover and "cập nhật" of an album from its ready, not-deleted items. */
export async function recomputeAlbum(
  db: Firestore,
  babyId: string,
  albumId: string,
  now: Date,
): Promise<void> {
  const ref = db.doc(`babies/${babyId}/albums/${albumId}`);
  const album = await ref.get();
  if (!album.exists) return;
  const items = await ref.collection('items').get();
  const ids = items.docs.map((d) => d.id);
  const media = ids.length
    ? (
        await Promise.all(
          chunks(ids, 300).map((part) =>
            db.getAll(...part.map((m) => db.doc(`babies/${babyId}/media/${m}`))),
          ),
        )
      ).flat()
    : [];
  const live = media.filter(
    (m) => m.exists && m.get('status') === 'ready' && m.get('deleted') !== true,
  );
  const photos = live.filter((m) => m.get('type') === 'photo').length;
  const newest = [...live].sort(
    (a, b) =>
      (b.get('captureAt') as Timestamp).toMillis() - (a.get('captureAt') as Timestamp).toMillis(),
  );
  const chosen = album.get('coverMediaId') as string | null;
  const cover = live.some((m) => m.id === chosen) ? chosen : (newest[0]?.id ?? null);
  const lastAdded = items.docs
    .map((d) => (d.get('addedAt') as Timestamp | undefined)?.toMillis() ?? 0)
    .reduce((a, b) => Math.max(a, b), 0);
  await ref.update({
    counts: { photos, videos: live.length - photos },
    coverMediaId: cover,
    contentUpdatedAt: lastAdded ? new Date(lastAdded) : album.get('createdAt'),
    updatedAt: now,
  });
}

async function addItems(
  db: Firestore,
  babyId: string,
  albumId: string,
  mediaIds: readonly string[],
  uid: string,
  now: Date,
): Promise<string[]> {
  const added: string[] = [];
  for (const part of chunks(mediaIds, 200)) {
    const snaps = await db.getAll(...part.map((m) => db.doc(`babies/${babyId}/media/${m}`)));
    const writer = db.batch();
    for (const s of snaps) {
      if (!s.exists || s.get('deleted') === true) continue;
      writer.set(db.doc(`babies/${babyId}/albums/${albumId}/items/${s.id}`), {
        mediaId: s.id,
        addedAt: now,
        addedBy: uid,
      });
      writer.update(s.ref, { albumIds: FieldValue.arrayUnion(albumId), updatedAt: now });
      added.push(s.id);
    }
    await writer.commit();
  }
  return added;
}

/** Records a generic family notice (R-120); delivered by `deliverFamilyNotice`. */
async function familyNotice(
  db: Firestore,
  babyId: string,
  kind: 'album' | 'shared' | 'story',
  count: number,
  uid: string,
  actor: unknown,
  now: Date,
  source?: { collection: string; id: string },
): Promise<string> {
  const members = await db
    .collection(`babies/${babyId}/members`)
    .where('status', '==', 'active')
    .get();
  const recipients = members.docs
    .filter((m) => m.id !== uid && ['coParent', 'relative'].includes(m.get('role') as string))
    .map((m) => m.id);
  const id = `${kind}_${now.getTime().toString(36)}_${uid.slice(0, 8)}`;
  await db.doc(`babies/${babyId}/notifications/${id}`).set({
    kind,
    babyId,
    count,
    actor,
    actorUid: uid,
    ...(source ? { sourceCollection: source.collection, sourceId: source.id } : {}),
    recipients,
    createdAt: now,
    delivered: false,
  });
  return id;
}

export async function createAlbum(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ albumId: string; added: number }> {
  const parsed = createAlbumRequestSchema.safeParse(data);
  if (!parsed.success) throw new MemoryError('invalid-argument', 'malformed');
  const { babyId, albumId, name, audience, mediaIds } = parsed.data;
  const author = await requireParent(db, babyId, uid, now);
  const ref = db.doc(`babies/${babyId}/albums/${albumId}`);
  const created = await db.runTransaction(async (tx) => {
    const existing = await tx.get(ref);
    if (existing.exists) {
      if (existing.get('createdBy') !== uid) throw new MemoryError('invalid-argument', 'taken');
      return false;
    }
    tx.set(ref, {
      id: albumId,
      babyId,
      name,
      audience,
      sort: 'newest',
      coverMediaId: null,
      counts: { photos: 0, videos: 0 },
      loveCount: 0,
      createdBy: uid,
      author,
      createdAt: now,
      contentUpdatedAt: now,
      updatedAt: now,
    });
    return true;
  });
  const added = created ? await addItems(db, babyId, albumId, mediaIds, uid, now) : [];
  await recomputeEffective(db, babyId, added, now);
  await recomputeAlbum(db, babyId, albumId, now);
  return { albumId, added: added.length };
}

export async function addToAlbum(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ added: number }> {
  const parsed = albumItemsRequestSchema.safeParse(data);
  if (!parsed.success) throw new MemoryError('invalid-argument', 'malformed');
  const { babyId, albumId, mediaIds } = parsed.data;
  await requireParent(db, babyId, uid, now);
  if (!(await db.doc(`babies/${babyId}/albums/${albumId}`).get()).exists) {
    throw new MemoryError('not-found', 'not-found');
  }
  const added = await addItems(db, babyId, albumId, mediaIds, uid, now);
  // Later items follow the album (R-104).
  await recomputeEffective(db, babyId, added, now);
  await recomputeAlbum(db, babyId, albumId, now);
  return { added: added.length };
}

export async function removeFromAlbum(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ removed: number }> {
  const parsed = albumItemsRequestSchema.safeParse(data);
  if (!parsed.success) throw new MemoryError('invalid-argument', 'malformed');
  const { babyId, albumId, mediaIds } = parsed.data;
  await requireParent(db, babyId, uid, now);
  for (const part of chunks(mediaIds, 200)) {
    const writer = db.batch();
    for (const m of part) {
      writer.delete(db.doc(`babies/${babyId}/albums/${albumId}/items/${m}`));
      writer.update(db.doc(`babies/${babyId}/media/${m}`), {
        albumIds: FieldValue.arrayRemove(albumId),
        updatedAt: now,
      });
    }
    await writer.commit().catch(async () => {
      // Some ids were not in the album or are gone: fall back to one by one.
      for (const m of part) {
        await db.doc(`babies/${babyId}/albums/${albumId}/items/${m}`).delete();
        await db
          .doc(`babies/${babyId}/media/${m}`)
          .update({ albumIds: FieldValue.arrayRemove(albumId), updatedAt: now })
          .catch(() => undefined);
      }
    });
  }
  await recomputeEffective(db, babyId, mediaIds, now);
  await recomputeAlbum(db, babyId, albumId, now);
  return { removed: mediaIds.length };
}

export async function updateAlbum(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ stayingShared: number; notificationId: string | null }> {
  const parsed = updateAlbumRequestSchema.safeParse(data);
  if (!parsed.success) throw new MemoryError('invalid-argument', 'malformed');
  const { babyId, albumId, change } = parsed.data;
  const author = await requireParent(db, babyId, uid, now);
  const ref = db.doc(`babies/${babyId}/albums/${albumId}`);
  const album = await ref.get();
  if (!album.exists) throw new MemoryError('not-found', 'not-found');
  switch (change.kind) {
    case 'rename':
      await ref.update({ name: change.name, updatedAt: now });
      return { stayingShared: 0, notificationId: null };
    case 'sort':
      await ref.update({ sort: change.sort, updatedAt: now });
      return { stayingShared: 0, notificationId: null };
    case 'cover': {
      const item = await ref.collection('items').doc(change.mediaId).get();
      if (!item.exists) throw new MemoryError('invalid-argument', 'not-in-album');
      await ref.update({ coverMediaId: change.mediaId, updatedAt: now });
      return { stayingShared: 0, notificationId: null };
    }
    case 'audience': {
      await ref.update({ audience: change.audience, updatedAt: now });
      const ids = (await ref.collection('items').get()).docs.map((d) => d.id);
      let staying = 0;
      if (change.audience === 'parents' && ids.length) {
        // D-002: its items become Chỉ ba mẹ, except those in another Gia đình album.
        const media = (
          await Promise.all(
            chunks(ids, 300).map((part) =>
              db.getAll(...part.map((m) => db.doc(`babies/${babyId}/media/${m}`))),
            ),
          )
        ).flat();
        const others = new Set<string>();
        for (const m of media) {
          for (const a of (m.get('albumIds') as string[] | undefined) ?? []) {
            if (a !== albumId) others.add(a);
          }
        }
        const familyAlbums = new Set(
          (others.size
            ? await db.getAll(...[...others].map((a) => db.doc(`babies/${babyId}/albums/${a}`)))
            : []
          )
            .filter((a) => a.exists && a.get('audience') === 'family')
            .map((a) => a.id),
        );
        staying = itemsStayingShared(
          media.map((m) => ({ albumIds: (m.get('albumIds') as string[] | undefined) ?? [] })),
          albumId,
          familyAlbums,
        );
        for (const part of chunks(media, 400)) {
          const writer = db.batch();
          for (const m of part) {
            if (m.exists) writer.update(m.ref, { audience: 'parents', updatedAt: now });
          }
          await writer.commit();
        }
      }
      const widened = await recomputeEffective(db, babyId, ids, now);
      const notificationId =
        change.audience === 'family' && change.notifyFamily && widened.length > 0
          ? await familyNotice(db, babyId, 'album', widened.length, uid, author, now, {
              collection: 'albums',
              id: albumId,
            })
          : null;
      return { stayingShared: staying, notificationId };
    }
  }
}

export async function deleteAlbum(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ deleted: boolean }> {
  const parsed = deleteAlbumRequestSchema.safeParse(data);
  if (!parsed.success) throw new MemoryError('invalid-argument', 'malformed');
  const { babyId, albumId } = parsed.data;
  await requireParent(db, babyId, uid, now);
  const ref = db.doc(`babies/${babyId}/albums/${albumId}`);
  const items = await ref.collection('items').get();
  const ids = items.docs.map((d) => d.id);
  for (const part of chunks(ids, 200)) {
    const writer = db.batch();
    for (const m of part) {
      writer.delete(ref.collection('items').doc(m));
      writer.set(
        db.doc(`babies/${babyId}/media/${m}`),
        { albumIds: FieldValue.arrayRemove(albumId), updatedAt: now },
        { merge: true },
      );
    }
    await writer.commit();
  }
  await ref.delete();
  // Items keep their own audience; only what the album shared goes back (R-106).
  await recomputeEffective(db, babyId, ids, now);
  return { deleted: true };
}

/** "Báo cho gia đình" after a batch share (re-exported for updateMedia, R-118). */
export { familyNotice };
