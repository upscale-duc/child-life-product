import { z } from 'zod';
import { staffReasonSchema } from './staff-reason.js';

/**
 * Feature flags (Figma Admin portal A10, R-189; business map P-122).
 * Stored server-side in `config/flags`; a public projection is mirrored to `publicConfig/flags`
 * so signed-out clients can read kill switches. Rollout is bucketed by family.
 */
export const flagKeys = [
  'engagementEnabled',
  'engagementPushEnabled',
  'engagementPendingEnabled',
  'engagementMilestoneEnabled',
  'engagementSixMonthEnabled',
  'engagementWeeklyEnabled',
  'engagementFamilyEnabled',
  'engagementLumiEnabled',
  'engagementFatigueEnabled',
  'engagementDigestGroupingEnabled',
  'engagementExperimentEnabled',

  /** MET-01: private product observations; off never blocks a domain action or existing stats. */
  'product_analytics',
  'media_upload',
  'video_upload',
  'ai_story_drafts',
  'story_share_link',
  'invites',
  'lock_widgets',
  'night_auto',
  /** Tự lưu kỷ niệm beta on iOS (D-066, P-148); evaluated per family by `featureAccess`. */
  'auto_save',
  /** Kỷ niệm 2.0 free beta (D-068 #3): Thiệp cột mốc, per family through `featureAccess`. */
  'milestone_cards',
  /** Kỷ niệm 2.0 free beta (D-068 #3): Video kỷ niệm, per family through `featureAccess`. */
  'memory_story',
  /** Nhịp lớn lên (free layer): reference calendar and check-in (PN01 kill switch; plan §5). */
  'rhythm',
  /** Group A: need-based suggestions and advanced rhythm (`personalization.cross_module`,
   * `rhythm.advanced`). A kill switch only; access also needs a grant. */
  'personalization',
  /** Grounded AI handover / explanations (`ai.assistance`), independent of entitlement (brief p.14). */
  'ai_assist',
  /** In-app purchase of Child Life Premium (D-072 #6); off = no paywall purchase button. */
  'premium_billing',
  /** Assistant chat overall (docs/assistant/architecture.md P-161). Off: history stays readable. */
  'assistant',
  /** Assistant photo tasks (receipts, notes). */
  'assistant_images',
  /** Assistant care guidance and recipes; off never blocks summaries or logging. */
  'assistant_care',
  /** Live model calls; off = no new model calls, drafts already ready can still be saved. */
  'assistant_live',
  /** Saving drafts into modules (confirm). */
  'assistant_writes',
  /** Upgrade prompts when credits run out. */
  'assistant_upsell',
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
  /**
   * Scope `internal`: the families staff picked in A10 ("Một vài gia đình"), as family ids, on top
   * of families marked `internal`. The portal shows them as codes; never mirrored to clients.
   */
  families: z.array(z.string().min(1).max(128)).max(100).optional(),
});
export type Flag = z.infer<typeof flagSchema>;

export type Flags = Record<FlagKey, Flag>;

const off = (scope: Flag['scope'] = 'all'): Flag => ({
  enabled: false,
  scope,
  percent: 0,
  notice: null,
});

/** Safe defaults used when the config document is missing: features ship dark until enabled. */
export const defaultFlags: Flags = {
  engagementEnabled: off(),
  engagementPushEnabled: off(),
  engagementPendingEnabled: off(),
  engagementMilestoneEnabled: off(),
  engagementSixMonthEnabled: off(),
  engagementWeeklyEnabled: off(),
  engagementFamilyEnabled: off(),
  engagementLumiEnabled: off(),
  engagementFatigueEnabled: off(),
  engagementDigestGroupingEnabled: off(),
  engagementExperimentEnabled: off(),

  product_analytics: off(),
  media_upload: off(),
  video_upload: off(),
  ai_story_drafts: off('internal'),
  story_share_link: off(),
  invites: off(),
  lock_widgets: off(),
  night_auto: off('internal'),
  auto_save: off('internal'),
  milestone_cards: off('internal'),
  memory_story: off('internal'),
  rhythm: off('internal'),
  personalization: off('internal'),
  ai_assist: off('internal'),
  premium_billing: off('internal'),
  assistant: off('internal'),
  assistant_images: off('internal'),
  assistant_care: off('internal'),
  assistant_live: off('internal'),
  assistant_writes: off('internal'),
  assistant_upsell: off('internal'),
};

/**
 * Every flag. A key the stored document does not have yet (a flag added after the document was
 * written, such as `auto_save`) reads as its default, off, instead of failing the whole document
 * and with it every kill switch.
 */
export const flagsSchema = z.object(
  Object.fromEntries(
    flagKeys.map((k) => [k, flagSchema.default(() => ({ ...defaultFlags[k] }))]),
  ) as Record<FlagKey, z.ZodDefault<typeof flagSchema>>,
);

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
  /** Tự lưu: at most this many items per "Tải lên" (D-070); the rest wait for the next round.
   * A missing key reads as the default, so a `config/limits` written before it still parses. */
  autoSaveItemsPerApprove: z.number().int().positive().default(200),
});
export type Limits = z.infer<typeof limitsSchema>;

/**
 * How content and reference data are approved (`config/content`, D-079). The safe defaults are the
 * two-person rule (D-058, P-138) and the qualified review on prod (D-058, D-073 #2); the Owner may
 * relax them while they are the only staff, and switch them back on without a release.
 * - `ownerSelfApprove`: the Owner may approve and publish what they wrote themselves (audited as
 *   such); every other role still needs a second person.
 * - `reviewRequiredOnProd`: prod publishing needs the reviewer, credential and date. Off, content
 *   ships with `review: null` and keeps its "chờ chuyên môn duyệt" label (D-078 #6).
 */
export const contentPolicySchema = z.object({
  ownerSelfApprove: z.boolean().default(false),
  reviewRequiredOnProd: z.boolean().default(true),
});
export type ContentPolicy = z.infer<typeof contentPolicySchema>;

export const defaultContentPolicy: ContentPolicy = {
  ownerSelfApprove: false,
  reviewRequiredOnProd: true,
};

/** `staffSetContentPolicy`: the Owner changes one or both switches (P-139); reason optional (D-090). */
export const setContentPolicyRequestSchema = z.object({
  ownerSelfApprove: z.boolean().optional(),
  reviewRequiredOnProd: z.boolean().optional(),
  reason: staffReasonSchema,
});
export type SetContentPolicyRequest = z.infer<typeof setContentPolicyRequestSchema>;

const GB = 1024 ** 3;

export const defaultLimits: Limits = {
  familyQuotaBytes: 10 * GB, // R-040
  videoMaxDurationSec: null, // D-011 / A10
  videoMaxBytes: 4 * GB, // D-011 provisional until SP-3
  videoWifiOnlyDefault: true, // R-115
  mediaItemsPerAdd: 30, // R-102
  exportLinkTtlHours: 24, // R-187
  storageRequestAmountsGb: [10, 20], // D-010
  autoSaveItemsPerApprove: 200, // D-070
};

/**
 * `featureAccess` callable (P-148): which per-family features a member's baby may use. The app
 * cannot evaluate `internal` or `percent` itself (only the owner may read the family document).
 */
export const featureAccessRequestSchema = z.object({ babyId: z.string().min(1).max(128) });
export type FeatureAccessRequest = z.infer<typeof featureAccessRequestSchema>;
export interface FeatureAccess {
  /** Tự lưu kỷ niệm (D-066): the flag is on for this family and the caller is a Cùng nuôi. */
  autoSave: boolean;
  /** Thiệp cột mốc (D-068): the `milestone_cards` flag is on for this family and the caller is a
   * Cùng nuôi. */
  milestoneCards: boolean;
  /** Video kỷ niệm (D-068): the `memory_story` flag, as above. */
  memoryStory: boolean;
}

/** Whether a flag is on for a given family (stable hash bucket 0–99); a family picked in A10
 * counts as internal for that flag. */
export function isFlagOnForFamily(
  flag: Flag,
  familyId: string,
  bucket: number,
  isInternalFamily: boolean,
): boolean {
  return isFlagOnForBucket(
    flag,
    bucket,
    isInternalFamily || (flag.families ?? []).includes(familyId),
  );
}

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
