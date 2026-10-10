import { z } from 'zod';

/**
 * Feature flags (Figma Admin portal A10, R-189; business map P-122).
 * Stored server-side in `config/flags`; a public projection is mirrored to `publicConfig/flags`
 * so signed-out clients can read kill switches. Rollout is bucketed by family.
 */
export const flagKeys = [
  'media_upload',
  'video_upload',
  'ai_story_drafts',
  'story_share_link',
  'invites',
  'lock_widgets',
  'night_auto',
] as const;
export type FlagKey = (typeof flagKeys)[number];

export const rolloutScopes = ['internal', 'percent', 'all'] as const;

export const flagSchema = z.object({
  enabled: z.boolean(),
  scope: z.enum(rolloutScopes),
  /** Only meaningful when scope = 'percent': share of families (0–100) in the rollout. */
  percent: z.number().int().min(0).max(100),
  /** Optional in-app notice shown when the flag is switched off (A11). */
  notice: z.string().max(280).nullable(),
});
export type Flag = z.infer<typeof flagSchema>;

export const flagsSchema = z.object(
  Object.fromEntries(flagKeys.map((k) => [k, flagSchema])) as Record<FlagKey, typeof flagSchema>,
);
export type Flags = z.infer<typeof flagsSchema>;

/**
 * Global limits (D-011, Admin portal A10 "Giới hạn chung"). Changed without an app release.
 * `null` duration = no limit (A10 shows "Độ dài video · Không giới hạn").
 */
export const limitsSchema = z.object({
  familyQuotaBytes: z.number().int().positive(),
  videoMaxDurationSec: z.number().int().positive().nullable(),
  videoMaxBytes: z.number().int().positive(),
  videoWifiOnlyDefault: z.boolean(),
  mediaItemsPerAdd: z.number().int().positive(),
  exportLinkTtlHours: z.number().int().positive(),
  storageRequestAmountsGb: z.array(z.number().int().positive()).nonempty(),
});
export type Limits = z.infer<typeof limitsSchema>;

const GB = 1024 ** 3;

export const defaultLimits: Limits = {
  familyQuotaBytes: 10 * GB, // R-040
  videoMaxDurationSec: null, // D-011 / A10
  videoMaxBytes: 4 * GB, // D-011 provisional until SP-3
  videoWifiOnlyDefault: true, // R-115
  mediaItemsPerAdd: 30, // R-102
  exportLinkTtlHours: 24, // R-187
  storageRequestAmountsGb: [10, 20], // D-010
};

const off = (scope: Flag['scope'] = 'all'): Flag => ({
  enabled: false,
  scope,
  percent: 0,
  notice: null,
});

/** Safe defaults used when the config document is missing: features ship dark until enabled. */
export const defaultFlags: Flags = {
  media_upload: off(),
  video_upload: off(),
  ai_story_drafts: off('internal'),
  story_share_link: off(),
  invites: off(),
  lock_widgets: off(),
  night_auto: off('internal'),
};

/** Whether a flag is on for a given family (stable hash bucket 0–99). */
export function isFlagOnForBucket(flag: Flag, bucket: number, isInternalFamily: boolean): boolean {
  if (!flag.enabled) return false;
  switch (flag.scope) {
    case 'all':
      return true;
    case 'internal':
      return isInternalFamily;
    case 'percent':
      return bucket < flag.percent;
  }
}
