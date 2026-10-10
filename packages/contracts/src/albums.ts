import { z } from 'zod';
import { albumIdSchema, audiences, mediaIdSchema } from './memories.js';

/**
 * Albums, favourites, loves and messages (Slice S10; Figma 10d–10e10, 10h5, 11a–11h; business
 * map D-002, D-034…D-036, R-104…R-108, R-118…R-120, P-035). Albums and their membership are
 * written by Functions (effective audience is recomputed server-side, P-035); favourites,
 * loves and messages are written by the app and checked by Rules.
 */

/** 10e7 "Sắp xếp": Mới nhất (default) · Cũ nhất · Mới thêm vào album. */
export const albumSorts = ['newest', 'oldest', 'added'] as const;
export type AlbumSort = (typeof albumSorts)[number];

export const albumLimits = {
  nameMax: 60,
  itemsPerCall: 500,
  messageMax: 1000,
} as const;

const albumName = z.string().trim().min(1).max(albumLimits.nameMax);
const mediaIds = z.array(mediaIdSchema).max(albumLimits.itemsPerCall);

/** "Album mới" (10d, 10h5 "Tạo album mới"). */
export const createAlbumRequestSchema = z.object({
  babyId: z.string().min(1),
  albumId: albumIdSchema,
  name: albumName,
  audience: z.enum(audiences),
  mediaIds,
});

/** 10e3 options: rename (10e4), cover (10e5), audience (10e6), sort (10e7). */
export const updateAlbumRequestSchema = z.object({
  babyId: z.string().min(1),
  albumId: albumIdSchema,
  change: z.discriminatedUnion('kind', [
    z.object({ kind: z.literal('rename'), name: albumName }),
    z.object({ kind: z.literal('cover'), mediaId: mediaIdSchema }),
    z.object({ kind: z.literal('sort'), sort: z.enum(albumSorts) }),
    z.object({
      kind: z.literal('audience'),
      audience: z.enum(audiences),
      notifyFamily: z.boolean(),
    }),
  ]),
});
export type UpdateAlbumRequest = z.infer<typeof updateAlbumRequestSchema>;

/** 10b3 "Album", 10e "Thêm ảnh", 10e8 "Bỏ khỏi album". */
export const albumItemsRequestSchema = z.object({
  babyId: z.string().min(1),
  albumId: albumIdSchema,
  mediaIds: mediaIds.min(1),
});

/** 10e10: the album goes, its items stay (R-106). */
export const deleteAlbumRequestSchema = z.object({
  babyId: z.string().min(1),
  albumId: albumIdSchema,
});

/** What can be loved ("Thương"): items, entries, albums (11f "Thương album"), stories (S12). */
export const loveTargets = ['media', 'memory', 'album', 'story'] as const;
export type LoveTarget = (typeof loveTargets)[number];

/** `babies/{b}/reactions/{target}__{id}__{uid}`: one love per person and target. */
export function reactionIdOf(target: LoveTarget, targetId: string, uid: string): string {
  return `${target}__${targetId}__${uid}`;
}

/** `babies/{b}/favorites/{uid}__{mediaId}`: private to its owner (R-107). */
export function favoriteIdOf(uid: string, mediaId: string): string {
  return `${uid}__${mediaId}`;
}

/** "Nhắn ba mẹ" (D-034): where a message points. Caregivers write "Nhắn Mẹ" on a record. */
export const messageContexts = ['media', 'memory', 'album', 'story', 'record'] as const;
export const messageIdSchema = z.string().regex(/^msg_[a-f0-9]{32}$/);

/**
 * D-002: when an album changes to Chỉ ba mẹ its items become Chỉ ba mẹ, except those still in
 * another Gia đình album; returns how many stay visible to the family (the sheet says so).
 */
export function itemsStayingShared(
  items: readonly { albumIds: readonly string[] }[],
  albumId: string,
  familyAlbums: ReadonlySet<string>,
): number {
  return items.filter((i) => i.albumIds.some((a) => a !== albumId && familyAlbums.has(a))).length;
}

/** Counts shown on album cards and heroes ("12 ảnh · 3 video"). */
export function albumCounts(items: readonly { type: 'photo' | 'video' }[]): {
  photos: number;
  videos: number;
} {
  const photos = items.filter((i) => i.type === 'photo').length;
  return { photos, videos: items.length - photos };
}
