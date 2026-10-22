import { z } from 'zod';
import { addDaysIso } from './rhythm.js';
import { reminderInstantIn } from './reminders.js';
import { localDateIn } from './baby.js';
import { inQuietHours } from './notifications.js';
import type { EngagementKind, EngagementReasonCode } from './product-analytics.js';

// ENG-00: conservative defaults; changing a policy never resets a logical receipt.
export const engagementPolicySchema = z
  .object({
    version: z.literal(1).default(1),
    approved: z.boolean().default(false),
    dailyCap: z.number().int().min(1).max(1).default(1),
    weeklyCap: z.number().int().min(1).max(3).default(3),
    reducedDismissals: z.number().int().min(2).max(10).default(2),
    pausedDismissals: z.number().int().min(3).max(20).default(3),
    ignoredThreshold: z.number().int().min(3).max(20).default(3),
    completionQuietHours: z.number().int().min(48).max(168).default(48),
    spacingMinutes: z.number().int().min(60).max(240).default(60),
    /**
     * Owner, 2026-10-22 (D-092, doc 18 #10): how long the device a person last opened the app on
     * may receive proactive pushes. The send still needs a live token, no sign-out and current
     * membership; sign-out or revocation ends it at once.
     */
    deviceLeaseDays: z.number().int().min(1).max(60).default(30),
    quietDefault: z
      .object({
        from: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/),
        to: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/),
      })
      .strict()
      .default({ from: '22:00', to: '07:00' }),
  })
  .strict();
export type EngagementPolicy = z.infer<typeof engagementPolicySchema>;
export const defaultEngagementPolicy = engagementPolicySchema.parse({});
export const proactiveKinds = ['ENG-01', 'ENG-02', 'ENG-03', 'ENG-05', 'ENG-06'] as const;
export const engagementPreferencesSchema = z
  .object({
    consent: z.boolean().default(false),
    kinds: z
      .object({
        'ENG-01': z.boolean().default(false),
        'ENG-02': z.boolean().default(false),
        'ENG-03': z.boolean().default(false),
        'ENG-05': z.boolean().default(false),
        'ENG-06': z.boolean().default(false),
      })
      .strict()
      .default(() => ({
        'ENG-01': false,
        'ENG-02': false,
        'ENG-03': false,
        'ENG-05': false,
        'ENG-06': false,
      })),
  })
  .strict();
export type EngagementPreferences = z.infer<typeof engagementPreferencesSchema>;
const id = z.string().regex(/^[A-Za-z0-9_-]{1,128}$/);
export const engagementRefreshSchema = z
  .object({
    babyId: id,
    ownerUid: id,
    pendingOnly: z.boolean().default(false),
    deviceId: id,
    pushAllowed: z.boolean(),
    recipientZone: z
      .string()
      .min(1)
      .max(80)
      .refine((zone) => {
        try {
          new Intl.DateTimeFormat('en', { timeZone: zone }).format();
          return true;
        } catch {
          return false;
        }
      })
      .optional(),
    handoffKinds: z
      .array(z.enum(['ENG-01', 'ENG-02', 'ENG-06']))
      .max(3)
      .default([]),
    legacyDismissedCampaigns: z
      .array(z.enum(['m1', 'd100', 'm6', 'y1']))
      .max(4)
      .default([]),
    pending: z
      .object({
        episode: z.string().uuid(),
        state: z.enum(['pending', 'resolved', 'unavailable']),
        approvedBatches: z.array(id).max(20).default([]),
      })
      .strict()
      .optional(),
  })
  .strict();
export const engagementActionSchema = z
  .object({
    id: z.string().regex(/^[a-f0-9]{64}$/),
    action: z.enum(['dismiss', 'snooze', 'open', 'view']),
    surface: z.enum(['in_app', 'notification']).default('in_app'),
    deviceId: id.optional(),
  })
  .strict();
export const engagementSettingsSchema = z
  .object({ preferences: engagementPreferencesSchema.optional(), resume: z.boolean().optional() })
  .strict();
export const engagementContentSchema = z
  .object({
    babyId: id,
    sourceType: z.enum(['media', 'story', 'personal_day', 'message']),
    sourceId: id,
  })
  .strict();
export const campaignKinds = ['m1', 'd100', 'm6', 'y1'] as const;
export type CampaignKind = (typeof campaignKinds)[number];
export const engagementPriority: Record<EngagementKind, number> = {
  'ENG-01': 20,
  'ENG-02': 10,
  'ENG-03': 30,
  'ENG-04': 0,
  'ENG-05': 40,
  'ENG-06': 50,
};
export function campaignDate(dob: string, campaign: CampaignKind): string {
  if (campaign === 'd100') return addDaysIso(dob, 100);
  const d = new Date(`${dob}T12:00:00Z`),
    months = campaign === 'm1' ? 1 : campaign === 'm6' ? 6 : 12;
  const target = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + months, 1, 12));
  target.setUTCDate(
    Math.min(
      d.getUTCDate(),
      new Date(Date.UTC(target.getUTCFullYear(), target.getUTCMonth() + 1, 0)).getUTCDate(),
    ),
  );
  return target.toISOString().slice(0, 10);
}
export function campaignWindow(dob: string, campaign: CampaignKind, zone: string, now: Date) {
  const date = campaignDate(dob, campaign),
    today = localDateIn(zone, now);
  return {
    date,
    context: today > addDaysIso(date, 14) ? ('retrospective' as const) : ('current' as const),
    visible: today >= addDaysIso(date, -7),
    dueAt: reminderInstantIn(zone, addDaysIso(date, -3), '09:00').getTime(),
    pushExpiresAt: reminderInstantIn(zone, addDaysIso(date, 2), '00:00').getTime(),
    windowClosesAt: reminderInstantIn(zone, addDaysIso(date, 15), '00:00').getTime(),
  };
}
export interface EngagementDecisionInput {
  now: number;
  dueAt: number;
  expiresAt: number;
  scheduled: boolean;
  enabled: boolean;
  authorized: boolean;
  source: 'ready' | 'resolved' | 'unknown';
  context: 'current' | 'retrospective' | 'unknown';
  consent: boolean;
  category: boolean;
  pushAvailable: boolean;
  paused: boolean;
  reduced: boolean;
  dismissed: boolean;
  sentAt: number | null;
  snoozedUntil: number;
  completedAt: number;
  recent: number[];
  zone: string;
  quiet: { from: string; to: string } | null;
  spacingUntil: number;
  higherPriorityUntil?: number;
  digestAt?: number;
  holdout?: boolean;
}
export function decideEngagement(
  i: EngagementDecisionInput,
  p = defaultEngagementPolicy,
): {
  decision:
    | 'in_app_only'
    | 'push_eligible'
    | 'delay'
    | 'group_into_digest'
    | 'suppress'
    | 'cancel'
    | 'expire';
  reason: EngagementReasonCode;
  nextAt?: number;
} {
  const stop = (reason: EngagementReasonCode) => ({
    decision: i.scheduled ? ('cancel' as const) : ('suppress' as const),
    reason,
  });
  if (!i.enabled) return stop('disabled');
  if (!i.authorized) return stop('not_authorized');
  if (i.source === 'resolved') return stop('source_resolved');
  if (i.dismissed) return stop('user_choice');
  if (i.sentAt !== null) return { decision: 'suppress', reason: 'duplicate' };
  if (i.context === 'retrospective') return { decision: 'in_app_only', reason: 'window_closed' };
  if (i.now >= i.expiresAt) return { decision: 'expire', reason: 'window_closed' };
  const delay = (nextAt: number, reason: EngagementReasonCode) =>
    nextAt >= i.expiresAt
      ? { decision: 'expire' as const, reason: 'window_closed' as const }
      : { decision: 'delay' as const, reason, nextAt };
  if (i.source === 'unknown') return delay(i.now + 15 * 60_000, 'awaiting_verification');
  if (i.paused) return stop('fatigue_paused');
  if (!i.consent || !i.category) return { decision: 'in_app_only', reason: 'channel_unavailable' };
  if (i.completedAt && i.completedAt + p.completionQuietHours * 3600_000 > i.now)
    return delay(i.completedAt + p.completionQuietHours * 3600_000, 'post_completion_quiet');
  if (!i.pushAvailable) return { decision: 'in_app_only', reason: 'channel_unavailable' };
  if (i.holdout) return { decision: 'in_app_only', reason: 'holdout' };
  if (i.digestAt && i.digestAt < i.expiresAt)
    return { decision: 'group_into_digest', reason: 'digest_member', nextAt: i.digestAt };
  const next = Math.max(i.dueAt, i.snoozedUntil, i.spacingUntil, i.higherPriorityUntil ?? 0);
  if (next > i.now)
    return delay(
      next,
      i.snoozedUntil === next ? 'snoozed' : i.dueAt === next ? 'not_due' : 'higher_priority',
    );
  if (inQuietHours(i.quiet, i.zone, new Date(i.now))) {
    for (let n = 1; n <= 1440; n++)
      if (!inQuietHours(i.quiet, i.zone, new Date(i.now + n * 60_000)))
        return delay(i.now + n * 60_000, 'quiet_hours');
    return { decision: 'in_app_only', reason: 'quiet_hours' };
  }
  const day = 86400_000,
    week = i.recent.filter((t) => t > i.now - 7 * day).sort((a, b) => a - b),
    daily = week.filter((t) => t > i.now - day);
  if (i.reduced && week.length) return delay(week.at(-1)! + 7 * day, 'budget');
  if (daily.length >= p.dailyCap) return delay(daily[daily.length - p.dailyCap]! + day, 'budget');
  if (week.length >= p.weeklyCap)
    return delay(week[week.length - p.weeklyCap]! + 7 * day, 'budget');
  return { decision: 'push_eligible', reason: 'reserved' };
}

export function engagementSegments(i: {
  accountDays: number;
  historyKnown: boolean;
  firstMemory: boolean;
  pending: boolean;
  saveDays: number;
  videos: number;
  views: number;
  fatigue: boolean;
}) {
  return [
    ...(!i.historyKnown
      ? ['unknown']
      : i.accountDays <= 14 && !i.firstMemory
        ? ['new_without_memory']
        : []),
    ...(i.pending ? ['pending_photos'] : []),
    ...(i.saveDays >= 2 ? ['active_memory_saver'] : []),
    ...(i.videos > 0 ? ['active_video_creator'] : []),
    ...(i.views > 0 ? ['family_viewer'] : []),
    ...(i.fatigue ? ['fatigue'] : []),
  ];
}

export const engagementBackgroundAccessSchema = z
  .object({ ownerUid: id, deviceId: id, babyIds: z.array(id).min(1).max(20) })
  .strict();
