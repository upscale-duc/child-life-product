import { z } from 'zod';
import { widgetIds } from './adaptive.js';

/** MET-01 / P-137: product observations are private operational receipts; staff get aggregates. */
export const productAnalyticsSections = [
  'overview',
  'acquisition',
  'memories',
  'engagement',
  'features',
  'cost',
] as const;
export type ProductAnalyticsSection = (typeof productAnalyticsSections)[number];
export const analyticsModules = [
  'care',
  'grow',
  'remember',
  'family',
  'lumi',
  'personalization',
  'engagement',
] as const;
export type AnalyticsModule = (typeof analyticsModules)[number];
export const analyticsAgeBands = [
  'under_1m',
  '1_to_3m',
  '3_to_6m',
  '6_to_9m',
  '9_to_12m',
  '12m_plus',
  'unknown',
] as const;
export type AnalyticsAgeBand = (typeof analyticsAgeBands)[number];
export const engagementKinds = [
  'ENG-01',
  'ENG-02',
  'ENG-03',
  'ENG-04',
  'ENG-05',
  'ENG-06',
] as const;
export type EngagementKind = (typeof engagementKinds)[number];
export const engagementStages = [
  'eligible',
  'scheduled',
  'attempted',
  'accepted',
  'opened',
  'completed',
  'dismissed',
  'snoozed',
  'suppressed',
  'cancelled',
  'expired',
  'unknown',
  'failed',
] as const;
export type EngagementStage = (typeof engagementStages)[number];
export const engagementReasonCodes = [
  'none',
  'duplicate',
  'source_resolved',
  'not_authorized',
  'user_choice',
  'disabled',
  'window_closed',
  'awaiting_verification',
  'fatigue_paused',
  'post_completion_quiet',
  'channel_unavailable',
  'holdout',
  'not_due',
  'snoozed',
  'quiet_hours',
  'budget',
  'higher_priority',
  'digest_member',
  'reserved',
] as const;
export type EngagementReasonCode = (typeof engagementReasonCodes)[number];
export const analyticsContexts = ['current', 'retrospective', 'unknown'] as const;

/**
 * Adaptive Experience events (P-175, plan §1.3 / §4.8): what a person did with Hôm nay, AX33 and
 * Khám phá. One closed `detail` each; never a name, a date of birth or free text (a search term
 * is reduced to `search`).
 */
export const adaptiveEvents = [
  'adaptive_goals_set',
  'adaptive_widget_opened',
  'adaptive_customized',
  'adaptive_stage_answered',
  'adaptive_interest',
] as const;
export type AdaptiveEvent = (typeof adaptiveEvents)[number];
export const adaptiveDetails = [
  // adaptive_goals_set
  'chosen',
  'skipped',
  // adaptive_widget_opened: the widget id
  ...widgetIds,
  // adaptive_customized
  'pin',
  'unpin',
  'hide',
  'show',
  'reorder',
  'goals',
  'restore',
  // adaptive_stage_answered
  'applied',
  'kept',
  // adaptive_interest
  'card',
  'search',
] as const;
export type AdaptiveDetail = (typeof adaptiveDetails)[number];
export type AnalyticsContext = (typeof analyticsContexts)[number];

/** Closed client events. Source references are validated against owned domain data, never logged. */
export const analyticsObservationSchema = z
  .object({
    schemaVersion: z.literal(1),
    receiptId: z.string().uuid(),
    ownerUid: z.string().min(1).max(128),
    occurredAt: z.string().datetime(),
    event: z.enum([
      'app_foreground_observed',
      'family_context_viewed',
      'family_content_viewed',
      'photo_review_opened',
      'memory_story_started',
      'memory_story_share_sheet_opened',
      'memory_story_share_result',
      'lumi_answer_viewed',
      ...adaptiveEvents,
    ]),
    babyId: z
      .string()
      .regex(/^[A-Za-z0-9_-]{1,128}$/)
      .optional(),
    sourceId: z
      .string()
      .regex(/^[A-Za-z0-9_-]{1,128}$/)
      .optional(),
    platform: z.enum(['ios', 'android', 'unknown']),
    locale: z.enum(['vi', 'en', 'other', 'unknown']),
    result: z.enum(['platform_confirmed', 'cancelled', 'unknown']).optional(),
    /** Adaptive events only (required there, refused elsewhere). */
    detail: z.enum(adaptiveDetails).optional(),
  })
  .strict()
  .refine(
    (r) => (r.event.startsWith('adaptive_') ? r.detail !== undefined : r.detail === undefined),
    { message: 'detail is for adaptive events only', path: ['detail'] },
  );
export type AnalyticsObservation = z.infer<typeof analyticsObservationSchema>;

const dateOnly = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/)
  .refine((s) => {
    const d = new Date(`${s}T00:00:00Z`);
    return Number.isFinite(d.getTime()) && d.toISOString().slice(0, 10) === s;
  });
export const productAnalyticsRequestSchema = z
  .object({
    schemaVersion: z.literal(2),
    section: z.enum(productAnalyticsSections),
    from: dateOnly,
    to: dateOnly,
    platform: z.enum(['all', 'ios', 'android']).default('all'),
    locale: z.enum(['all', 'vi', 'en']).default('all'),
    ageBand: z.enum(['all', ...analyticsAgeBands]).default('all'),
    context: z.enum(['all', ...analyticsContexts]).default('all'),
    chapter: z.enum(['all', 'chapter01', 'unknown']).default('all'),
    comparison: z.boolean().default(true),
  })
  .strict()
  .refine((r) => r.from <= r.to && (Date.parse(r.to) - Date.parse(r.from)) / 86_400_000 < 366, {
    message: 'Invalid range',
  });
export type ProductAnalyticsRequest = z.infer<typeof productAnalyticsRequestSchema>;

export type AnalyticsMetricStatus =
  'ready' | 'provisional' | 'no_data' | 'unavailable' | 'insufficient' | 'immature';
export interface ProductMetric {
  id: string;
  unit: 'users' | 'families' | 'actions' | 'opportunities' | 'calls' | 'tokens' | 'credits' | 'usd';
  value: number | null;
  numerator: number | null;
  denominator: number | null;
  status: AnalyticsMetricStatus;
  reason:
    | 'none'
    | 'not_instrumented'
    | 'small_cohort'
    | 'window_open'
    | 'no_source'
    | 'unsupported_filter'
    | 'history_unavailable';
  windowDays: number | null;
  previous: number | null;
}
export interface ProductAnalyticsResult {
  schemaVersion: 2;
  definitionVersion: 1;
  section: ProductAnalyticsSection;
  range: { from: string; to: string };
  reportingZone: 'Asia/Ho_Chi_Minh';
  status: 'preparing' | 'ready' | 'no_data' | 'disabled' | 'unavailable';
  computedAt: string | null;
  observedThrough: string | null;
  sourceStartAt: string | null;
  collectionEnabled: boolean;
  stale: boolean;
  privacyThreshold: number;
  unsupportedFilters: string[];
  metrics: ProductMetric[];
  series: Array<{
    day: string;
    users: number | null;
    families: number | null;
    actions: number | null;
  }>;
  retention: Array<{
    day: string;
    users: number | null;
    d1: ProductMetric;
    d7: ProductMetric;
    d30: ProductMetric;
  }>;
  breakdowns: Array<{
    /** `stageBand` / `adaptive`: Adaptive Experience (P-175), people per band and per
     * `event:detail` (e.g. `widget_opened:moment_today`), each slice at the privacy threshold. */
    dimension: 'platform' | 'locale' | 'ageBand' | 'module' | 'template' | 'stageBand' | 'adaptive';
    key: string;
    count: number | null;
  }>;
  engagement: Array<{
    kind: EngagementKind;
    stages: Record<EngagementStage, number | null>;
    conversion: ProductMetric;
    reasons: Array<{ reason: EngagementReasonCode; count: number | null }>;
  }>;
  quality: {
    unknownActor: number | null;
    lateObservations: number | null;
    sourceCoverage: 'complete' | 'partial' | 'none';
  };
}
