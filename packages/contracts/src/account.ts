import { z } from 'zod';
import {
  babyIdSchema,
  displayNameMaxLength,
  genders,
  nicknameMaxLength,
  relationCustomMaxLength,
  timeZoneSettingSchema,
} from './baby.js';
import { relations } from './family.js';
import { deviceIdSchema } from './reminders.js';

/**
 * Me, storage, baby profiles, account and data (Slice S11; Figma 13a–13n; business map §4, §8,
 * R-040…R-046, R-122…R-124, R-187, D-010, P-001, P-003, P-034, P-110, P-123, Q-016, Q-037).
 * The Dart app mirrors these shapes in `apps/mobile/lib/features/me/`.
 */

const GB = 1024 ** 3;

/** Storage states on 13b–13d: "Sắp đầy" from 80 %, uploads paused at 100 % (R-040, 13c, 13d). */
export const storageNearFullRatio = 0.8;
export type StorageState = 'ok' | 'nearFull' | 'full';
export function storageState(usedBytes: number, quotaBytes: number): StorageState {
  if (quotaBytes <= 0 || usedBytes >= quotaBytes) return 'full';
  return usedBytes >= quotaBytes * storageNearFullRatio ? 'nearFull' : 'ok';
}

// ---------- Storage (13b–13e) ----------

export const familyStorageRequestSchema = z.object({ babyId: babyIdSchema });

const babyUsageSchema = z.object({
  babyId: z.string(),
  nickname: z.string(),
  photos: z.number().int().nonnegative(),
  videos: z.number().int().nonnegative(),
  photoBytes: z.number().int().nonnegative(),
  videoBytes: z.number().int().nonnegative(),
});

export const largestVideoSchema = z.object({
  babyId: z.string(),
  mediaId: z.string(),
  bytes: z.number().int().nonnegative(),
  durationMs: z.number().int().nonnegative().nullable(),
  captureAt: z.string(),
});

/** 13b for any Cùng nuôi of a baby in the family (P-003, G-040). */
export const familyStorageSchema = z.object({
  familyId: z.string(),
  isOwner: z.boolean(),
  quotaBytes: z.number().int().nonnegative(),
  usedBytes: z.number().int().nonnegative(),
  /** In "Đã xoá gần đây": still counted until the 30-day purge (P-034, G-041). */
  binBytes: z.number().int().nonnegative(),
  /** "Câu chuyện & ghi chú": text is tiny; an estimate from note and story counts. */
  notesBytes: z.number().int().nonnegative(),
  babies: z.array(babyUsageSchema),
  /** "Xem video lớn nhất" (G-058): the 20 largest videos the caller can see. */
  largestVideos: z.array(largestVideoSchema),
  /** An open "Xin thêm dung lượng" request, so 13b shows it as sent. */
  openRequest: z
    .object({ id: z.string(), amountGb: z.number().int(), createdAt: z.string() })
    .nullable(),
});
export type FamilyStorage = z.infer<typeof familyStorageSchema>;

/** Bytes counted for one note or story text (displayed as "Câu chuyện & ghi chú"). */
export const noteBytesEstimate = 2 * 1024;

export const storageRequestAmountsGb = [10, 20] as const;

/** 13e "Xin thêm dung lượng": +10 GB / +20 GB only (D-010), optional message (R-122). */
export const requestStorageSchema = z.object({
  requestId: z.uuid(),
  babyId: babyIdSchema,
  amountGb: z.literal(storageRequestAmountsGb),
  message: z.string().trim().max(1000).optional(),
});
export type RequestStorage = z.infer<typeof requestStorageSchema>;
export const storageRequestBytes = (amountGb: number) => amountGb * GB;

// ---------- Baby profile (13j–13l) ----------

/** 13k "Sửa hồ sơ bé" — the create form's fields (R-124). Cùng nuôi only (§5). */
export const updateBabyProfileSchema = z
  .object({
    babyId: babyIdSchema,
    nickname: z.string().trim().min(1).max(nicknameMaxLength).optional(),
    dateOfBirth: z.iso.date().optional(),
    gender: z.enum(genders).optional(),
    timeZone: timeZoneSettingSchema.optional(),
  })
  .refine(
    (v) =>
      v.nickname !== undefined ||
      v.dateOfBirth !== undefined ||
      v.gender !== undefined ||
      v.timeZone !== undefined,
    'Nothing to change',
  );
export type UpdateBabyProfile = z.infer<typeof updateBabyProfileSchema>;

/** 13l: the owner types the nickname to confirm (R-045). */
export const deleteBabySchema = z.object({
  babyId: babyIdSchema,
  confirmNickname: z.string().trim().min(1).max(nicknameMaxLength),
});

/** Baby lifecycle (business map §7.4): purge finishes before anyone sees "đã xoá" (flow F). */
export const babyStates = ['active', 'deleting'] as const;

// ---------- Deletion jobs (P-110) ----------

export const babyDeletionSteps = [
  'lock',
  'storage',
  'documents',
  'family',
  'verify',
  'finish',
] as const;
export const accountDeletionSteps = [
  'memberships',
  'authored',
  'personal',
  'auth',
  'finish',
] as const;
export const deletionJobStates = ['queued', 'running', 'failed', 'done'] as const;

// ---------- Your profile (13m) ----------

export const updateMyProfileSchema = z
  .object({
    displayName: z.string().trim().min(1).max(displayNameMaxLength).optional(),
    /** "Bạn là ai với bé": relation per baby. */
    relations: z
      .array(
        z.object({
          babyId: babyIdSchema,
          relation: z.enum(relations),
          relationCustom: z.string().trim().min(1).max(relationCustomMaxLength).nullable(),
        }),
      )
      .max(20)
      .optional(),
  })
  .refine((v) => v.displayName !== undefined || (v.relations?.length ?? 0) > 0, 'Nothing to change')
  .refine(
    (v) =>
      (v.relations ?? []).every((r) => (r.relation === 'other') === (r.relationCustom != null)),
    'relationCustom is required for "other" and only allowed there',
  );
export type UpdateMyProfile = z.infer<typeof updateMyProfileSchema>;

// ---------- Ownership transfer and account deletion (13n, Q-016) ----------

/** The owner offers the family (all its babies) to an active Cùng nuôi of every baby. */
export const offerOwnershipSchema = z.object({ toUid: z.string().min(1).max(128) });
/** The receiver accepts or declines; the owner may cancel. */
export const answerOwnershipSchema = z.object({
  familyId: z.string().min(1).max(64),
  answer: z.enum(['accept', 'decline', 'cancel']),
});
export const deleteAccountSchema = z.object({ confirm: z.literal(true) });

// ---------- Devices (13n) ----------

export const signOutDeviceSchema = z.object({ deviceId: deviceIdSchema });

// ---------- Notifications (G-056) ----------

/** Which pushes this account receives; reminders are local and read by the app. */
export const notificationPrefKeys = ['memories', 'messages', 'reminders', 'storage'] as const;
export type NotificationPrefKey = (typeof notificationPrefKeys)[number];
/** Notice kind → preference that silences it. */
export const noticePref: Record<string, NotificationPrefKey> = {
  memories: 'memories',
  shared: 'memories',
  album: 'memories',
  story: 'memories',
  message: 'messages',
  storage: 'storage',
  // Rule reminders (1f) follow "Nhắc việc" in Thông báo.
  reminderRule: 'reminders',
  // Sổ tiêm chủng reminders (P-133) follow "Nhắc việc" too.
  vaccine: 'reminders',
};

// ---------- Data export (R-187, P-123, G-072) ----------

export const exportKinds = ['care', 'media'] as const;
export const requestExportSchema = z.object({
  requestId: z.uuid(),
  babyId: babyIdSchema,
  kind: z.enum(exportKinds),
});
export const exportJobStates = ['queued', 'running', 'ready', 'failed', 'expired'] as const;

// ---------- Help & contact (G-057, G-073) ----------

export const supportCategories = [
  'memories',
  'family',
  'invites',
  'sync',
  'account',
  'storage',
  'stories',
] as const;

/** Sent only with consent; no child content (business map `DiagnosticsSnapshot`). */
export const diagnosticsSchema = z.object({
  platform: z.enum(['ios', 'android']),
  appVersion: z.string().max(32),
  osVersion: z.string().max(64),
  deviceModel: z.string().max(64),
  role: z.string().max(16).nullable(),
  pendingUploads: z.number().int().nonnegative(),
  lastSyncAt: z.string().max(40).nullable(),
});

export const createSupportTicketSchema = z.object({
  requestId: z.uuid(),
  category: z.enum(supportCategories),
  message: z.string().trim().min(1).max(2000),
  diagnostics: diagnosticsSchema.nullable(),
  locale: z.enum(['vi', 'en']),
});

// ---------- Góp ý & đánh giá (FB1–FB5, D-065) ----------

/** FB2 "Ý tưởng · Báo lỗi · Khác". */
export const feedbackTypes = ['idea', 'bug', 'other'] as const;
export type FeedbackType = (typeof feedbackTypes)[number];

/**
 * FB2 "Gửi góp ý". The screenshot, when attached, is uploaded first to
 * `feedback/{uid}/{requestId}.{jpg|png}` (picked: JPEG; captured by FB4: PNG); device info is the same consented snapshot as Trợ giúp
 * (no baby data); "Cho phép liên hệ lại" off = no email to or from the team about it.
 */
export const sendFeedbackSchema = z.object({
  requestId: z.uuid(),
  type: z.enum(feedbackTypes),
  message: z.string().trim().min(1).max(2000),
  screenshot: z.enum(['jpg', 'png']).nullable(),
  diagnostics: diagnosticsSchema.nullable(),
  replyByEmail: z.boolean(),
  locale: z.enum(['vi', 'en']),
});

/**
 * Counters from the app (P-137: first-party, aggregate only, nothing about who); feedback is
 * counted by the server. FB5 review prompts, and Tự lưu kỷ niệm's beta numbers (P-148): setup,
 * photo access, what parents do with suggestions, background checks, missed photos.
 */
export const appEvents = [
  'reviewPromptEligible',
  'reviewPromptRequested',
  'autoSaveSetupStarted',
  'autoSaveSetupDone',
  'autoSaveAccessFull',
  'autoSaveAccessLimited',
  'autoSaveAccessDenied',
  'autoSaveSuggested',
  'autoSaveApproved',
  'autoSaveUnticked',
  'autoSaveRejected',
  'autoSaveSkipped',
  'autoSaveMissed',
  'autoSaveBackgroundCheck',
  'autoSaveNotified',
  'autoSaveTurnedOff',
  'autoSaveWiped',
  // Premium & Cá nhân hoá (brief p.20): UX counters from the phone; purchases, usage and
  // summaries are counted by the server, which is authoritative for them.
  'capabilityGateSeen',
  'checkinSaved',
  'nextActionShown',
  'suggestionStarted',
  'feedbackSaved',
  'paywallSeen',
  'purchaseStarted',
  'premiumTemplateSelected',
  'summaryOpened',
  // Grounded AI (plan §5.5): counted by the server only (`generateSummary`).
  'summaryGenerated',
  'summaryFallback',
] as const;
export type AppEvent = (typeof appEvents)[number];

/**
 * Closed dimension values per event (counted as `event__dim` next to `event`): reasons, entry
 * points, kinds, methods. Never free text, child data, notes or transaction tokens.
 */
export const appEventDims: Partial<Record<AppEvent, readonly string[]>> = {
  capabilityGateSeen: [
    'NOT_MEMBER',
    'ROLE_DENIED',
    'FEATURE_DISABLED',
    'REGION_UNAVAILABLE',
    'PREMIUM_REQUIRED',
    'CONSENT_REQUIRED',
    'QUOTA_EXCEEDED',
  ],
  nextActionShown: [
    'SELF_REPORTED_NEED',
    'DATA_INSIGHT',
    'PREVIOUS_HELPFUL',
    'AGE_CONTENT',
    'INTEREST',
    'normal',
    'health',
    'no_suggestion',
  ],
  feedbackSaved: ['started', 'helpful', 'unsure', 'not_suitable', 'not_today'],
  paywallSeen: ['rhythm', 'templates', 'plan'],
  purchaseStarted: ['rhythm', 'templates', 'plan'],
  summaryOpened: ['ai', 'cache', 'fallback'],
  summaryGenerated: ['ai', 'cache', 'fallback'],
  summaryFallback: [
    'HEALTH_FLOW',
    'NOT_MEMBER',
    'ROLE_DENIED',
    'FEATURE_DISABLED',
    'REGION_UNAVAILABLE',
    'PREMIUM_REQUIRED',
    'CONSENT_REQUIRED',
    'QUOTA_EXCEEDED',
    'timeout',
    'invalid',
    'unavailable',
  ],
};

/** Counted by the server only (authoritative); the app may not record them. */
export const serverOnlyAppEvents: readonly AppEvent[] = ['summaryGenerated', 'summaryFallback'];

/** [n]: how many at once (e.g. 15 photos approved in one go). */
export const recordAppEventSchema = z
  .object({
    event: z.enum(appEvents),
    n: z.number().int().min(1).max(1000).default(1),
    /** One of `appEventDims[event]`; anything else is refused. */
    dim: z.string().max(40).optional(),
  })
  .refine((r) => r.dim === undefined || (appEventDims[r.event] ?? []).includes(r.dim), {
    message: 'Unknown dimension for this event',
    path: ['dim'],
  })
  .refine((r) => !serverOnlyAppEvents.includes(r.event), {
    message: 'Counted by the server only',
    path: ['event'],
  });

/** FB3 "Bạn xem lại góp ý trong Tôi › Trợ giúp & liên hệ": what this person sent. */
export interface MyTicket {
  ticket: string;
  /** A help topic, or `feedback`. */
  category: string;
  feedbackType: FeedbackType | null;
  message: string;
  status: string;
  createdAt: string;
}
