import { z } from 'zod';

/**
 * Sơ cứu trẻ em (Figma v1.1 7a–7i, TH01–TH24; D-058, P-141). Editorial content written in the
 * portal, reviewed, and published as one pack to `publicConfig/content_firstAid`; the app keeps it
 * (and every image) on the device so it works without a network. Every string is vi + en with the
 * same ids (D-012). Medical content: on prod a pack is published only after an expert approves it.
 */

export const firstAidLimits = {
  situations: 40,
  variants: 3,
  steps: 8,
  chips: 3,
  callouts: 4,
  calloutItems: 8,
  keywords: 20,
  title: 60,
  lead: 120,
  text: 600,
  heading: 60,
  item: 200,
  /** Uploaded images (WebP, the server re-encodes). */
  imageBytes: 1.5 * 1024 * 1024,
} as const;

const loc = (max: number) =>
  z
    .object({ vi: z.string().trim().min(1).max(max), en: z.string().trim().min(1).max(max) })
    .strict();
export const firstAidTextSchema = loc(firstAidLimits.text);
export type FirstAidText = z.infer<typeof firstAidTextSchema>;

/** Images live at `content/first-aid/{id}.webp` (public, immutable: a new image is a new id). */
export const firstAidImageIdSchema = z.string().regex(/^[a-z0-9-]{2,48}_[a-f0-9]{8}$/);
export const firstAidImagePath = (id: string) => `content/first-aid/${id}.webp`;

export const firstAidCategorySchema = z
  .object({
    id: z.string().regex(/^[a-z][a-z0-9-]{1,30}$/),
    title: loc(firstAidLimits.heading),
    /** Card grid (Khẩn cấp) or list rows (the other groups), as on 7b. */
    layout: z.enum(['grid', 'list']),
    /** Tag tint on the detail page. */
    tone: z.enum(['danger', 'sunshine', 'mint']),
  })
  .strict();

export const firstAidChipSchema = z
  .object({ label: loc(firstAidLimits.heading), tone: z.enum(['mint', 'neutral']) })
  .strict();

export const firstAidStepSchema = z
  .object({
    title: loc(firstAidLimits.heading),
    body: loc(firstAidLimits.text),
    image: firstAidImageIdSchema.nullable(),
    chips: z.array(firstAidChipSchema).max(firstAidLimits.chips),
    /** "Vỗ lưng 5 lần": tap-to-count dots in reading and step mode (7d, 7f). */
    count: z.number().int().min(2).max(10).nullable(),
    /** CPR mode (7i): the compressions step runs the metronome; the breaths step closes a cycle. */
    cprRole: z.enum(['compressions', 'breaths']).nullable(),
  })
  .strict();

/** Tone callouts: negative = "Không được làm" (red), warning = "Đưa bé đi viện ngay khi", positive. */
export const firstAidCalloutSchema = z
  .object({
    tone: z.enum(['negative', 'warning', 'positive']),
    heading: loc(firstAidLimits.heading),
    items: z.array(loc(firstAidLimits.item)).min(1).max(firstAidLimits.calloutItems),
  })
  .strict();

export const firstAidVariantSchema = z
  .object({
    id: z.string().regex(/^[a-z][a-z0-9-]{1,30}$/),
    /** Segment label ("Dưới 1 tuổi", "Có dị vật"); null when the page has one variant. */
    label: loc(firstAidLimits.heading).nullable(),
    /** Age variants: the default for the selected baby (months, inclusive–exclusive). */
    ageMonths: z
      .object({ from: z.number().int().min(0), to: z.number().int().min(1).nullable() })
      .strict()
      .nullable(),
    /** Overrides the situation hero for this variant. */
    hero: firstAidImageIdSchema.nullable(),
    banner: loc(firstAidLimits.text).nullable(),
    steps: z.array(firstAidStepSchema).max(firstAidLimits.steps),
    callouts: z.array(firstAidCalloutSchema).max(firstAidLimits.callouts),
    /** Opens CPR mode (7i) for this protocol instead of the plain step mode. */
    cpr: z.enum(['infant', 'child']).nullable(),
  })
  .strict();

export const firstAidSituationSchema = z
  .object({
    id: z.string().regex(/^[a-z][a-z0-9-]{1,40}$/),
    /** TH01… (editorial reference only). */
    code: z
      .string()
      .regex(/^[A-Z]{2}\d{2}$/)
      .nullable(),
    category: z.string(),
    /** Red "Gọi 115" pill and bottom button (7d, TH01–TH07, TH19, TH20). */
    emergency: z.boolean(),
    /** Tag "Theo dõi" (TH21, TH24). */
    monitoring: z.boolean(),
    title: loc(firstAidLimits.title),
    /** The card / row subline on 7b and the subtitle on the page. */
    lead: loc(firstAidLimits.lead),
    /** Search synonyms and alternative titles ("Co giật do sốt"). */
    keywords: z.array(loc(firstAidLimits.heading)).max(firstAidLimits.keywords),
    icon: firstAidImageIdSchema,
    hero: firstAidImageIdSchema,
    /** Moves down the index for babies outside it (newborn-only pages). */
    ageMonths: z
      .object({ from: z.number().int().min(0), to: z.number().int().min(1).nullable() })
      .strict()
      .nullable(),
    variantKind: z.enum(['age', 'condition']).nullable(),
    variants: z.array(firstAidVariantSchema).min(1).max(firstAidLimits.variants),
    /** Extra on-page tool (TH04 "Bấm giờ cơn giật"). */
    tool: z.enum(['seizureTimer']).nullable(),
  })
  .strict();

export const firstAidCprSchema = z
  .object({
    id: z.enum(['infant', 'child']),
    ratePerMinute: z.number().int().min(100).max(120),
    compressions: z.number().int().min(15).max(30),
    breaths: z.number().int().min(0).max(2),
    /** Shown on the compressions step ("ấn sâu khoảng 4 cm"). */
    compressionText: loc(firstAidLimits.text),
    image: firstAidImageIdSchema.nullable(),
  })
  .strict();

export const firstAidReviewSchema = z
  .object({
    /** Shown as "Được … rà soát tháng MM/YYYY" only once a reviewer is recorded. */
    reviewer: z.string().trim().min(2).max(120),
    reviewedOn: z.iso.date(),
    sources: z.array(z.string().trim().min(2).max(200)).max(10),
  })
  .strict();

/** The whole guide as the app reads it. */
export const firstAidPackSchema = z
  .object({
    emergencyNumber: z.string().regex(/^\d{3,4}$/),
    categories: z.array(firstAidCategorySchema).min(1).max(8),
    situations: z.array(firstAidSituationSchema).min(1).max(firstAidLimits.situations),
    cpr: z.array(firstAidCprSchema).max(2),
    quickSearch: z.array(loc(firstAidLimits.heading)).max(12),
    review: firstAidReviewSchema.nullable(),
  })
  .strict()
  .superRefine((pack, ctx) => {
    const categories = new Set(pack.categories.map((c) => c.id));
    const ids = new Set<string>();
    pack.situations.forEach((s, i) => {
      if (!categories.has(s.category)) {
        ctx.addIssue({
          code: 'custom',
          path: ['situations', i, 'category'],
          message: 'unknown category',
        });
      }
      if (ids.has(s.id)) {
        ctx.addIssue({ code: 'custom', path: ['situations', i, 'id'], message: 'duplicate id' });
      }
      ids.add(s.id);
      if (s.variants.length > 1 && (!s.variantKind || s.variants.some((v) => !v.label))) {
        ctx.addIssue({
          code: 'custom',
          path: ['situations', i, 'variants'],
          message: 'variant labels',
        });
      }
    });
  });
export type FirstAidPack = z.infer<typeof firstAidPackSchema>;
export type FirstAidSituation = z.infer<typeof firstAidSituationSchema>;

/** Every image the pack points at (the app downloads them all for offline use). */
export function firstAidImages(pack: FirstAidPack): string[] {
  const out = new Set<string>();
  for (const s of pack.situations) {
    out.add(s.icon);
    out.add(s.hero);
    for (const v of s.variants) {
      if (v.hero) out.add(v.hero);
      for (const st of v.steps) if (st.image) out.add(st.image);
    }
  }
  for (const c of pack.cpr) if (c.image) out.add(c.image);
  return [...out];
}

/** `publicConfig/content_firstAid`: the published pack and its version. */
export const firstAidPublicSchema = z.object({
  version: z.string().regex(/^fa_\d{8}_\d{2}$/),
  publishedAt: z.string(),
  pack: firstAidPackSchema,
});
export type FirstAidPublic = z.infer<typeof firstAidPublicSchema>;
export const firstAidPublicDocId = 'content_firstAid';

// ---------- Portal (staff) ----------

export const firstAidSaveDraftSchema = z.object({ pack: firstAidPackSchema }).strict();
export const firstAidSubmitSchema = z.object({ note: z.string().trim().min(3).max(500) }).strict();
export const firstAidDecideSchema = z
  .object({
    versionId: z.string().regex(/^fv_[a-f0-9]{16}$/),
    approve: z.boolean(),
    note: z.string().trim().min(3).max(500),
    /** Recorded on the pack when approving (prod needs it). */
    review: firstAidReviewSchema.nullable(),
  })
  .strict();
export const firstAidUploadImageSchema = z
  .object({
    name: z.string().regex(/^[a-z0-9-]{2,48}$/),
    /** PNG, JPEG or WebP, base64. */
    data: z.base64().max(Math.ceil((firstAidLimits.imageBytes * 4) / 3) + 4),
  })
  .strict();
