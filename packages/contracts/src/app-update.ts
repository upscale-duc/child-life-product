import { z } from 'zod';
import { staffReasonSchema } from './staff-reason.js';

/**
 * App updates (v1.0 improvement UP1–UP6, owner 2026-10-12, D-061): written on the portal
 * (Hệ thống · Cập nhật ứng dụng) and read by the app from `publicConfig/appUpdate`.
 *
 * - Below `minimum` for its platform → UP1 "Cần cập nhật để tiếp tục" blocks the app.
 * - Below `latest` → UP2 "Child Life có bản mới" once, again after `snoozeDays` ("Để sau"), and
 *   the "Cập nhật" tag on UP6 Tôi · Phiên bản.
 * - Opening the app for the first time on `release.version` after an update → UP5 banner on Hôm
 *   nay; "Xem" opens UP3/UP4 "Có gì mới" (the release's pages).
 */

export const appUpdatePublicDocId = 'appUpdate';

/** "1.2.0": what the stores show (CFBundleShortVersionString / versionName). */
export const appVersionSchema = z.string().regex(/^\d{1,3}\.\d{1,3}\.\d{1,3}$/);

/** -1, 0, 1 like a comparator; both must be valid versions. */
export function compareAppVersions(a: string, b: string): number {
  const pa = a.split('.').map(Number);
  const pb = b.split('.').map(Number);
  for (let i = 0; i < 3; i += 1) {
    const d = (pa[i] ?? 0) - (pb[i] ?? 0);
    if (d !== 0) return d < 0 ? -1 : 1;
  }
  return 0;
}

export const appUpdateLimits = {
  summary: 60,
  title: 60,
  highlightBody: 60,
  pageBody: 240,
  where: 40,
  highlights: 4,
  pages: 5,
  imageBytes: 1.5 * 1024 * 1024,
} as const;

const loc = (max: number) =>
  z
    .object({ vi: z.string().trim().min(1).max(max), en: z.string().trim().min(1).max(max) })
    .strict();
export type AppUpdateText = { vi: string; en: string };

/** Pictures at `content/app-update/{id}.webp` (public, immutable). */
export const appUpdateImageIdSchema = z.string().regex(/^[a-z0-9-]{2,48}_[a-f0-9]{8}$/);
export const appUpdateImagePath = (id: string) => `content/app-update/${id}.webp`;

const storeUrl = z
  .url({ protocol: /^https$/ })
  .max(300)
  .refine(
    (u) =>
      /^https:\/\/(apps\.apple\.com|testflight\.apple\.com|play\.google\.com|appdistribution\.firebase\.dev)\//.test(
        u,
      ),
    'store',
  );

export const appUpdatePlatformSchema = z
  .object({
    /** Newest version in the store; null = nothing to offer. */
    latest: appVersionSchema.nullable(),
    /** Oldest version allowed to run; null = never block. */
    minimum: appVersionSchema.nullable(),
    storeUrl: storeUrl.nullable(),
  })
  .strict()
  .refine((p) => !p.minimum || (p.latest && compareAppVersions(p.minimum, p.latest) <= 0), {
    message: 'minimum-above-latest',
  })
  .refine((p) => !p.latest || p.storeUrl, { message: 'store-url-required' });
export type AppUpdatePlatform = z.infer<typeof appUpdatePlatformSchema>;

/** The icons and tints a UP2 highlight row may use (the app's icon set and care colours). */
export const appUpdateIcons = [
  'alert',
  'grid',
  'heart',
  'cake',
  'spark',
  'bell',
  'camera',
  'sleep',
  'family',
  'star',
] as const;
export const appUpdateTones = [
  'danger',
  'growth',
  'pump',
  'sleep',
  'bottle',
  'mint',
  'sunshine',
] as const;

export const appUpdateHighlightSchema = z
  .object({
    icon: z.enum(appUpdateIcons),
    tone: z.enum(appUpdateTones),
    title: loc(appUpdateLimits.title),
    body: loc(appUpdateLimits.highlightBody),
  })
  .strict();
export type AppUpdateHighlight = z.infer<typeof appUpdateHighlightSchema>;

export const appUpdatePageSchema = z
  .object({
    image: appUpdateImageIdSchema.nullable(),
    title: loc(appUpdateLimits.title),
    body: loc(appUpdateLimits.pageBody),
    /** "Tìm trong tab Tiện ích". */
    where: loc(appUpdateLimits.where).nullable(),
  })
  .strict();
export type AppUpdatePage = z.infer<typeof appUpdatePageSchema>;

export const appUpdateReleaseSchema = z
  .object({
    version: appVersionSchema,
    /** UP5 banner line: "Sơ cứu, chi tiêu chung, lịch tiêm". */
    summary: loc(appUpdateLimits.summary),
    /** UP2 sheet rows. */
    highlights: z.array(appUpdateHighlightSchema).max(appUpdateLimits.highlights),
    /** UP3/UP4 pages. */
    pages: z.array(appUpdatePageSchema).max(appUpdateLimits.pages),
  })
  .strict();
export type AppUpdateRelease = z.infer<typeof appUpdateReleaseSchema>;

export const appUpdateConfigSchema = z
  .object({
    ios: appUpdatePlatformSchema,
    android: appUpdatePlatformSchema,
    /** "Để sau" on UP2 hides it for this many days. */
    snoozeDays: z.number().int().min(1).max(30),
    release: appUpdateReleaseSchema.nullable(),
  })
  .strict();
export type AppUpdateConfig = z.infer<typeof appUpdateConfigSchema>;

export const appUpdateEmpty: AppUpdateConfig = {
  ios: { latest: null, minimum: null, storeUrl: null },
  android: { latest: null, minimum: null, storeUrl: null },
  snoozeDays: 3,
  release: null,
};

/** `publicConfig/appUpdate`. */
export interface AppUpdatePublic {
  /** "au_20261012_01". */
  version: string;
  publishedAt: string;
  config: AppUpdateConfig;
}

// ---------- Portal (staff) ----------

export const appUpdateSaveSchema = z
  .object({
    config: appUpdateConfigSchema,
    /** Optional (D-090): "" when missing; the audit log records the change either way. */
    reason: staffReasonSchema,
  })
  .strict();

export const appUpdateUploadImageSchema = z
  .object({
    name: z.string().regex(/^[a-z0-9-]{2,40}$/),
    data: z.base64().max(Math.ceil((appUpdateLimits.imageBytes * 4) / 3) + 4),
  })
  .strict();
