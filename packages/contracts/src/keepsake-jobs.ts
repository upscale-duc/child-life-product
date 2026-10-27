import {
  keepsakePresentationRequestSchema,
  type KeepsakePresentation,
} from './keepsake-personalization.js';
import { z } from 'zod';
import { keepsakeTemplateIdSchema, occasionIds, type KeepsakeTemplate } from './keepsakes.js';
import { audiences, mediaIdSchema } from './memories.js';
import type { QuotaSnapshot } from './quota.js';

/**
 * Video kỷ niệm render jobs (D-068 #1, #4; plan `docs/product/remember-2-plan.md` §4.3, §5).
 * The app asks `requestMemoryStory`; Functions check everything, write
 * `babies/{b}/keepsakeJobs/{jobId}` with a snapshot of the template version (so a later publish
 * never changes a job) and hand it to Cloud Tasks; the private Cloud Run renderer (Remotion)
 * claims it, writes the MP4 and its poster under `babies/{b}/media/{mediaId}/`, and marks it
 * completed; a trigger then files it in Kỷ niệm and tells the person who asked (push).
 * Ids are derived (job from the caller and request id, memory and media from the job), so a
 * retried call never makes a second job and a retried completion never a second memory.
 */

export const keepsakeJobIdSchema = z.string().regex(/^ksj_[a-f0-9]{32}$/);

export const keepsakeJobStatuses = ['queued', 'rendering', 'completed', 'failed'] as const;
export type KeepsakeJobStatus = (typeof keepsakeJobStatuses)[number];

/** MM08's three lines: "Sắp xếp ảnh theo mẫu", "Thêm chữ, lời nhắn và nhạc", "Xuất video 9:16". */
export const keepsakeJobSteps = ['arrange', 'compose', 'export'] as const;
export type KeepsakeJobStep = (typeof keepsakeJobSteps)[number];

/** Why a job failed (MM14 shows its own line for each; never a raw error). */
export const keepsakeJobErrors = [
  'timeout',
  'photo-missing',
  'render-failed',
  'upload-failed',
  'unavailable',
] as const;
export type KeepsakeJobErrorCode = (typeof keepsakeJobErrors)[number];

export const keepsakeJobLimits = {
  /** One video at a time per baby (MM08 says so; the queue stays fair). */
  activePerBaby: 1,
  /** A family's videos per day (cost guard). */
  perFamilyPerDay: 10,
  /** D-124: temporary burst protection, never a daily or plan allowance. */
  perFamilyPerMinute: 3,
  /** Renderer attempts before a job fails (Cloud Tasks retries in between). */
  attempts: 3,
  /** A job still rendering after this is failed with `timeout` by the sweeper. */
  renderMinutes: 15,
  /** A job still queued after this was never picked up: failed with `unavailable`. */
  queuedMinutes: 30,
  /** Room the output needs in the family quota when asking (P-001; D-068 #5). */
  estimateBytes: 40 * 1024 * 1024,
  /** Output: 9:16, H.264. */
  width: 1080,
  height: 1920,
  fps: 30,
} as const;

/** D-124: quality is frozen by the server; layout remains at the design size. */
export const videoQualities = ['hd720', 'fullHd1080'] as const;
export type VideoQuality = (typeof videoQualities)[number];
export function videoRenderScale(quality: VideoQuality): number {
  return quality === 'hd720' ? 2 / 3 : 1;
}
export function videoQualityAllowed(quality: VideoQuality, premium: boolean): boolean {
  return quality === 'hd720' || premium;
}

/** MM07 "Tạo video". */
export const memoryStoryRequestSchema = z
  .object({
    /** Made once per press of "Tạo video" on the phone (idempotency). */
    requestId: z.uuid(),
    babyId: z.string().min(1).max(128),
    templateId: keepsakeTemplateIdSchema,
    templateVersion: z.number().int().min(1),
    /** Photos in scene order (MM06 pick order, MM07 reorder). */
    mediaIds: z.array(mediaIdSchema).min(1).max(30),
    texts: z
      .object({
        title: z.string().trim().max(60),
        message: z.string().trim().max(140),
        // Chapter 01 videos (E-9): only the keys the template offers are used.
        headline: z.string().trim().max(40).optional(),
        closing: z.string().trim().max(140).optional(),
        lines: z.string().trim().max(600).optional(),
        letter: z.string().trim().max(600).optional(),
      })
      .strict(),
    /** The app's language: the template's default texts and the photo labels follow it. */
    locale: z.enum(['vi', 'en']).optional(),
    presentation: keepsakePresentationRequestSchema.optional(),
    quality: z.enum(videoQualities).optional(),
    /** MM07 "Ai xem được" (default Chỉ ba mẹ). */
    audience: z.enum(audiences),
    occasion: z.enum(occasionIds).nullable(),
    /** MM07 "Nhạc nền": a published track, null for none; left out: the template's default. */
    musicId: z
      .string()
      .regex(/^music_[a-z0-9_]{2,40}$/)
      .nullable()
      .optional(),
  })
  .strict()
  .refine((r) => new Set(r.mediaIds).size === r.mediaIds.length, { message: 'duplicate photos' });
export type MemoryStoryRequest = z.infer<typeof memoryStoryRequestSchema>;

/** MM14 "Thử lại". */
export const memoryStoryRetrySchema = z
  .object({ babyId: z.string().min(1).max(128), jobId: keepsakeJobIdSchema })
  .strict();

/**
 * MO04 (Q2, brief p.10): the video quota of the caller's household for the window a new video
 * would count in (paid billing period, else the calendar month in the household zone).
 */
export const videoQuotaRequestSchema = z.object({ babyId: z.string().min(1).max(128) }).strict();

/**
 * `getVideoQuota` (MO04): the window a new video would count in, plus the premium budget when the
 * household is on the free one ("Khi hết lượt" may then offer Premium; never otherwise).
 */
export interface VideoQuotaAnswer extends QuotaSnapshot {
  /** The paid plan's per-period limit when this household is not on it; null when it is. */
  premiumLimit: number | null;
}

/** `requestMemoryStory` / `retryMemoryStory` answer: the job and the quota after it (MO04). */
export interface MemoryStoryAnswer {
  jobId: string;
  status: string;
  /** Null for a job asked for before the ledger existed. */
  quota: QuotaSnapshot | null;
}

/**
 * MM08 on iPhone: the job's Live Activity (lock screen, Dynamic Island). The app sends its
 * ActivityKit push token and the device's FCM token; Functions push each step to it and end it
 * when the job finishes. Ids and progress only — never a photo, a text or the baby's name.
 */
export const keepsakeJobLiveSchema = z
  .object({
    babyId: z.string().min(1).max(128),
    jobId: keepsakeJobIdSchema,
    /** The Live Activity's push token (iPhone); Android has none and follows by FCM (A6). */
    token: z
      .string()
      .regex(/^[0-9a-f]{32,512}$/)
      .nullable()
      .default(null),
    fcm: z.string().min(20).max(4096),
  })
  .strict();

/** What the Live Activity draws (`KeepsakeJobAttributes.ContentState` in ios/Shared). */
export interface KeepsakeLiveState {
  status: KeepsakeJobStatus;
  step: KeepsakeJobStep | null;
  progress: number;
}

/** What Cloud Tasks posts to the renderer. */
export const renderTaskSchema = z
  .object({ babyId: z.string().min(1).max(128), jobId: keepsakeJobIdSchema })
  .strict();

/** What the renderer needs, frozen in the job (never re-read from the catalog). */
export interface KeepsakeJobInput {
  /** Absent only on legacy jobs. Never read from untrusted renderer input. */
  quality?: VideoQuality;
  presentation?: KeepsakePresentation;
  template: KeepsakeTemplate;
  /** Display renditions in scene order (`babies/{b}/media/{m}/display.jpg`). */
  photos: string[];
  texts: {
    title: string;
    message: string;
    headline?: string;
    closing?: string;
    /** One per line, cycled over the photos. */
    lines?: string;
    letter?: string;
  };
  /** Per photo, in scene order: when it was taken and its age label ("Tháng 3"), when known. */
  photoInfo?: { takenAt: string | null; label: string | null }[];
  locale?: 'vi' | 'en';
  /** "3,2 kg · 50 cm" from the first growth record (V01); never logged. */
  birthStats?: string | null;
  /** The baby's nickname, for "{name}" in the template texts. */
  name: string;
  /** "14.10 – 14.11.2026": from birth or the first photo to the occasion. */
  dateLine: string;
  /** The big mark of MM08 / MM09 ("1", "7", "100"), or null. */
  mark: string | null;
  /** `content/keepsakes/{asset}` of the music, or null (Q-062). */
  music: string | null;
}

/** "{name}" in a template's default texts. */
export function fillName(text: string, name: string): string {
  return text.replaceAll('{name}', name);
}

/**
 * A photo's age label for videos (the app's card labels, `keepsake_card_content.dart`): "Ngày đầu",
 * "Ngày 5", "Tuần 3", "Tháng 6", "1 tuổi" / "Day 1", "Day 5", "Week 3", "Month 6", "Year 1".
 * Dates are ISO days (`YYYY-MM-DD`) in the baby's zone; null when either is unknown or before birth.
 */
export function keepsakeAgeLabel(
  dob: string | null,
  takenOn: string | null,
  locale: 'vi' | 'en',
): string | null {
  if (!dob || !takenOn) return null;
  const [by, bm, bd] = dob.split('-').map(Number) as [number, number, number];
  const [ty, tm, td] = takenOn.split('-').map(Number) as [number, number, number];
  const days = Math.round((Date.UTC(ty, tm - 1, td) - Date.UTC(by, bm - 1, bd)) / 86_400_000);
  if (days < 0) return null;
  const vi = locale === 'vi';
  if (days === 0) return vi ? 'Ngày đầu' : 'Day 1';
  if (days < 14) return vi ? `Ngày ${days + 1}` : `Day ${days + 1}`;
  if (days < 60)
    return vi ? `Tuần ${Math.floor(days / 7) + 1}` : `Week ${Math.floor(days / 7) + 1}`;
  const months = (ty - by) * 12 + tm - bm - (td < bd ? 1 : 0);
  if (months < 12) return vi ? `Tháng ${months}` : `Month ${months}`;
  const years = Math.floor(months / 12);
  return vi ? `${years} tuổi` : `Year ${years}`;
}

/** "3,2 kg · 50 cm" / "3.2 kg · 50 cm"; one value alone when only one is known. */
export function keepsakeBirthStats(
  weightKg: number | null,
  lengthCm: number | null,
  locale: 'vi' | 'en',
): string | null {
  const n = (v: number) =>
    new Intl.NumberFormat(locale === 'vi' ? 'vi-VN' : 'en-US', { maximumFractionDigits: 1 }).format(
      v,
    );
  const parts = [
    weightKg != null ? `${n(weightKg)} kg` : null,
    lengthCm != null ? `${n(lengthCm)} cm` : null,
  ];
  const out = parts.filter(Boolean).join(' · ');
  return out || null;
}
