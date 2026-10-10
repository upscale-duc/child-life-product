import { z } from 'zod';

/**
 * Baby profile and first membership (Slice S2; Figma 10a, 11, 11a–11c, 12; business map §3, R-008…R-010).
 * The Dart app mirrors these shapes in `apps/mobile/lib/features/baby/baby_models.dart`.
 */

/** Trackers "Theo dõi gì?" (R-010); the Today tile set follows them. */
export const trackerKinds = ['bottle', 'breast', 'sleep', 'diaper', 'pump', 'growth'] as const;
export type TrackerKind = (typeof trackerKinds)[number];

/** "Giới tính · không bắt buộc": Bé gái / Bé trai / Không nêu (R-009). */
export const genders = ['girl', 'boy', 'unspecified'] as const;
export type Gender = (typeof genders)[number];

/** "Bạn là" on 10a: Mẹ, Ba, Bà, Ông, Bảo mẫu, Họ hàng, Khác… (R-020). */
export const selfRelations = [
  'mother',
  'father',
  'grandmother',
  'grandfather',
  'nanny',
  'relative',
  'other',
] as const;
export type SelfRelation = (typeof selfRelations)[number];

/** Roles per baby (business map §2.1). S2 only creates the owner's `coParent` membership. */
export const memberRoles = ['coParent', 'caregiver', 'relative'] as const;
export type MemberRole = (typeof memberRoles)[number];

/** Each account creates at most 3 baby profiles; memberships elsewhere do not count (R-043). */
export const maxOwnedBabies = 3;

/** Illustrated avatars on 11c (mint, peach, sun, night). */
export const avatarPresets = [1, 2, 3, 4] as const;

/** Profile photos are re-encoded on device to a 512 px JPEG; the server accepts up to 1 MB. */
export const maxAvatarBytes = 1024 * 1024;

export const nicknameMaxLength = 30;
export const displayNameMaxLength = 40;
export const relationCustomMaxLength = 24;
/** Oldest accepted date of birth, in years (not in Figma; keeps typos like 1026 out). */
export const maxBabyAgeYears = 18;

/** IANA zone ids only (P-014); fixed offsets would break across DST. */
export function isIanaTimeZone(zone: string): boolean {
  if (!/^[A-Za-z]+(?:\/[A-Za-z0-9_+-]+)+$/.test(zone) && zone !== 'UTC') return false;
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: zone });
    return true;
  } catch {
    return false;
  }
}

/** Calendar date (YYYY-MM-DD) of [now] in [zone]. */
export function localDateIn(zone: string, now: Date): string {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: zone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(now);
  const get = (type: string) => parts.find((p) => p.type === type)?.value ?? '';
  return `${get('year')}-${get('month')}-${get('day')}`;
}

export const timeZoneSettingSchema = z.object({
  /** "Tự động theo máy" or picked from the list (11b). */
  mode: z.enum(['auto', 'manual']),
  zone: z.string().min(1).max(64).refine(isIanaTimeZone, 'Not an IANA time zone'),
});
export type TimeZoneSetting = z.infer<typeof timeZoneSettingSchema>;

export const selfSchema = z
  .object({
    displayName: z.string().trim().min(1).max(displayNameMaxLength),
    relation: z.enum(selfRelations),
    /** Free text for "Khác…" only. */
    relationCustom: z.string().trim().min(1).max(relationCustomMaxLength).optional(),
  })
  .refine((s) => (s.relation === 'other') === (s.relationCustom !== undefined), {
    message: 'relationCustom is required for "other" and only allowed there',
    path: ['relationCustom'],
  });

export const createBabyRequestSchema = z.object({
  /** Client-generated; retries with the same id return the same baby (idempotent). */
  requestId: z.uuid(),
  nickname: z.string().trim().min(1).max(nicknameMaxLength),
  dateOfBirth: z.iso.date(),
  gender: z.enum(genders),
  timeZone: timeZoneSettingSchema,
  avatarPreset: z.literal(avatarPresets),
  trackers: z
    .array(z.enum(trackerKinds))
    .min(1)
    .max(trackerKinds.length)
    .refine((t) => new Set(t).size === t.length, 'Duplicate tracker'),
  self: selfSchema,
});
export type CreateBabyRequest = z.infer<typeof createBabyRequestSchema>;

export const createBabyResponseSchema = z.object({
  babyId: z.string(),
  familyId: z.string(),
  /** false when the request id had already created this baby. */
  created: z.boolean(),
});
export type CreateBabyResponse = z.infer<typeof createBabyResponseSchema>;

export const babyIdSchema = z.string().regex(/^b_[a-f0-9]{20}$/);

export const setBabyAvatarRequestSchema = z.object({
  babyId: babyIdSchema,
  avatar: z.discriminatedUnion('kind', [
    z.object({ kind: z.literal('preset'), preset: z.literal(avatarPresets) }),
    z.object({
      kind: z.literal('photo'),
      /** Base64 JPEG (≤ maxAvatarBytes once decoded). */
      jpegBase64: z.base64().max(Math.ceil((maxAvatarBytes * 4) / 3) + 4),
    }),
  ]),
});
export type SetBabyAvatarRequest = z.infer<typeof setBabyAvatarRequestSchema>;

export const getBabyAvatarRequestSchema = z.object({ babyId: babyIdSchema });

/** Stored on `babies/{babyId}.avatar`; photo bytes live in private Storage. */
export const babyAvatarSchema = z.discriminatedUnion('kind', [
  z.object({ kind: z.literal('preset'), preset: z.number().int().min(1).max(4) }),
  z.object({ kind: z.literal('photo'), version: z.number().int().positive() }),
]);
export type BabyAvatar = z.infer<typeof babyAvatarSchema>;

/** Storage object for a baby's profile photo (never readable by clients directly). */
export const babyAvatarPath = (babyId: string, version: number) =>
  `babies/${babyId}/avatar/v${version}.jpg`;
