import { z } from 'zod';
import { authorSchema } from './care.js';

/**
 * Memories (Slice S9; Figma 10a–10o; business map §6.5, R-100…R-118, D-001, D-002, P-030…P-035).
 * A memory is one compose action (caption, milestone, audience) with 0..30 media items. The app
 * asks `createMemory` for an upload session (quota reserved, P-031), uploads each item to
 * `babies/{b}/uploads/{mediaId}` (Storage Rules check the reservation), and `onMediaUploaded`
 * validates, strips metadata (P-033), writes renditions and publishes (P-030). Reads go through
 * Rules on Firestore and Storage; the Dart app mirrors this in
 * `apps/mobile/lib/features/memories/memory_models.dart`.
 */

/** "Chỉ ba mẹ" / "Gia đình" (D-001: Gia đình preselected). */
export const audiences = ['parents', 'family'] as const;
export type Audience = (typeof audiences)[number];

export const mediaTypes = ['photo', 'video'] as const;
export type MediaType = (typeof mediaTypes)[number];

/**
 * Server-side states. `waitingQuota` items have no reservation and stay on the device (R-121).
 * Device-only states (queued, waiting for Wi-Fi, paused, failed) live in the app's upload queue;
 * `clientState` mirrors "waiting for Wi-Fi" so the batch notification need not wait for it (P-030).
 */
export const mediaStatuses = [
  'waitingQuota',
  'uploading',
  'ready',
  'unreadable',
  'cancelled',
] as const;
export type MediaStatus = (typeof mediaStatuses)[number];

export const memoryLimits = {
  /** R-102 default; the live value is `config/limits.mediaItemsPerAdd`. */
  itemsPerAdd: 30,
  captionMax: 2000,
  milestoneNameMax: 60,
  /** Photos arrive as JPEG re-encoded on the device (SP-3 fallback). */
  photoMaxBytes: 50 * 1024 * 1024,
  posterMaxBytes: 4 * 1024 * 1024,
  /** Deleted items stay in "Đã xoá gần đây" this long (R-111). */
  binDays: 30,
  /** Unfinished reservations are released after this (P-031). */
  reservationHours: 24,
} as const;

export const memoryIdSchema = z.string().regex(/^mem_[a-f0-9]{32}$/);
export const mediaIdSchema = z.string().regex(/^med_[a-f0-9]{32}$/);
export const batchIdSchema = z.string().regex(/^bat_[a-f0-9]{32}$/);
/** Family-created milestones; age-based presets use `p_<slug>` (10h3). */
export const milestoneIdSchema = z.string().regex(/^(ms_[a-f0-9]{32}|p_[a-z0-9_]{2,40})$/);

export const isoDate = z.iso.date();

/** "★ Lần đầu cười · 5 thg 10": denormalised onto the memory and its items. */
export const milestoneRefSchema = z.object({
  id: milestoneIdSchema,
  name: z.string().trim().min(1).max(memoryLimits.milestoneNameMax),
  date: isoDate,
});
export type MilestoneRef = z.infer<typeof milestoneRefSchema>;

export const photoContentTypes = ['image/jpeg'] as const;
export const videoContentTypes = ['video/mp4', 'video/quicktime'] as const;

export const uploadItemSchema = z
  .object({
    mediaId: mediaIdSchema,
    type: z.enum(mediaTypes),
    contentType: z.enum([...photoContentTypes, ...videoContentTypes]),
    sizeBytes: z.number().int().positive(),
    captureAt: z.iso.datetime({ offset: true }),
    durationMs: z.number().int().nonnegative().nullable(),
    width: z.number().int().positive().nullable(),
    height: z.number().int().positive().nullable(),
    /** A poster frame is uploaded first for videos (client-generated, SP-3 fallback). */
    hasPoster: z.boolean(),
  })
  .refine(
    (i) =>
      i.type === 'photo'
        ? (photoContentTypes as readonly string[]).includes(i.contentType) &&
          i.sizeBytes <= memoryLimits.photoMaxBytes &&
          !i.hasPoster
        : (videoContentTypes as readonly string[]).includes(i.contentType),
    { message: 'type and content do not match' },
  );
export type UploadItem = z.infer<typeof uploadItemSchema>;

/** 10h "Tải lên N mục" / 10a2 "Viết ghi chú" (no items). */
export const createMemoryRequestSchema = z
  .object({
    babyId: z.string().min(1),
    memoryId: memoryIdSchema,
    batchId: batchIdSchema,
    caption: z.string().trim().max(memoryLimits.captionMax).nullable(),
    audience: z.enum(audiences),
    notifyFamily: z.boolean(),
    /** "Theo ngày chụp" (default) or "Một ngày cho tất cả" (10h2). */
    dateMode: z.enum(['capture', 'single']),
    date: isoDate.nullable(),
    milestone: milestoneRefSchema.nullable(),
    items: z.array(uploadItemSchema).max(memoryLimits.itemsPerAdd),
  })
  .refine((r) => r.dateMode === 'capture' || r.date !== null, {
    message: 'single date mode needs a date',
  })
  .refine((r) => r.items.length > 0 || (r.caption !== null && r.caption.length > 0), {
    message: 'a note needs text',
  })
  .refine((r) => new Set(r.items.map((i) => i.mediaId)).size === r.items.length, {
    message: 'duplicate media ids',
  });
export type CreateMemoryRequest = z.infer<typeof createMemoryRequestSchema>;

export interface CreateMemoryResponse {
  memoryId: string;
  /** Items with a reservation: upload now. */
  reserved: string[];
  /** Items over the family quota: keep on the device (R-121, 13d). */
  waitingQuota: string[];
}

/** Retry the reservation of items kept on the device (quota freed or raised). */
export const reserveUploadsRequestSchema = z.object({
  babyId: z.string().min(1),
  mediaIds: z.array(mediaIdSchema).min(1).max(memoryLimits.itemsPerAdd),
});

export const cancelUploadsRequestSchema = reserveUploadsRequestSchema;

/** Batch actions on items (10b3, 10b4, 10o). */
export const updateMediaRequestSchema = z.object({
  babyId: z.string().min(1),
  mediaIds: z.array(mediaIdSchema).min(1).max(500),
  change: z.discriminatedUnion('kind', [
    /** "Ai thấy" / "Chia sẻ với gia đình?" with "Báo cho gia đình" (R-118). */
    z.object({
      kind: z.literal('audience'),
      audience: z.enum(audiences),
      notifyFamily: z.boolean(),
    }),
    /** "Đổi ngày": keep each item's time of day, move it to [date] (baby's zone). */
    z.object({ kind: z.literal('date'), date: isoDate }),
    /** "Gắn mốc" (one milestone per item; null clears). */
    z.object({ kind: z.literal('milestone'), milestone: milestoneRefSchema.nullable() }),
    /** "Xoá N mục" → "Đã xoá gần đây" for 30 days (R-111). */
    z.object({ kind: z.literal('delete') }),
    z.object({ kind: z.literal('restore') }),
  ]),
});
export type UpdateMediaRequest = z.infer<typeof updateMediaRequestSchema>;

/** Family-created milestone ("Mốc nhà mình đã tạo", R-105), written by the app. */
export const milestoneSchema = z.object({
  id: z.string().regex(/^ms_[a-f0-9]{32}$/),
  babyId: z.string(),
  name: z.string().trim().min(1).max(memoryLimits.milestoneNameMax),
  date: isoDate,
  createdBy: z.string(),
  author: authorSchema,
});

/**
 * D-002 / P-035: an item is seen by the family if it is Gia đình itself or sits in any Gia đình
 * album (albums arrive in S10; until then this is the item's own audience).
 */
export function effectiveAudience(
  item: Audience,
  albumAudiences: readonly Audience[] = [],
): Audience {
  return item === 'family' || albumAudiences.includes('family') ? 'family' : 'parents';
}

/** Terminal for the batch notification (P-030). */
export function isTerminal(status: MediaStatus): boolean {
  return status === 'ready' || status === 'unreadable' || status === 'cancelled';
}

/**
 * P-030 / Q-019: notify once when every item is terminal, or once at least one is ready and the
 * rest only wait for Wi-Fi on the uploader's device.
 */
export function batchReadyToNotify(
  items: readonly { status: MediaStatus; waitingWifi: boolean }[],
): boolean {
  if (items.length === 0) return true;
  if (items.every((i) => isTerminal(i.status))) return items.some((i) => i.status === 'ready');
  return (
    items.some((i) => i.status === 'ready') &&
    items.every((i) => isTerminal(i.status) || i.waitingWifi)
  );
}

/** First 64 bytes → what the file really is (never trust the declared type). */
export function sniffMedia(head: Uint8Array): 'jpeg' | 'png' | 'mp4' | 'quicktime' | null {
  if (head.length >= 3 && head[0] === 0xff && head[1] === 0xd8 && head[2] === 0xff) return 'jpeg';
  if (
    head.length >= 8 &&
    head[0] === 0x89 &&
    head[1] === 0x50 &&
    head[2] === 0x4e &&
    head[3] === 0x47
  ) {
    return 'png';
  }
  if (head.length >= 12) {
    const box = String.fromCharCode(head[4]!, head[5]!, head[6]!, head[7]!);
    if (box === 'ftyp') {
      const brand = String.fromCharCode(head[8]!, head[9]!, head[10]!, head[11]!);
      if (brand === 'qt  ') return 'quicktime';
      if (
        ['isom', 'iso2', 'mp41', 'mp42', 'avc1', 'M4V ', 'MSNV', '3gp4', '3gp5'].includes(brand)
      ) {
        return 'mp4';
      }
      return null;
    }
    if (['moov', 'mdat', 'wide', 'free'].includes(box)) return 'quicktime';
  }
  return null;
}
