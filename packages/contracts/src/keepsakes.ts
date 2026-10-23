import { z } from 'zod';
import { staffReasonSchema } from './staff-reason.js';
import { keepsakePersonalizationSchema } from './keepsake-personalization.js';

/**
 * Kỷ niệm 2.0 (D-068; Figma MM01–MM17, `docs/discovery/figma-extract/29-remember-2.md`; plan
 * `docs/product/remember-2-plan.md`): "Thiệp cột mốc" (one image drawn on the phone) and "Video kỷ
 * niệm" (a 9:16 video rendered on the server), both from a versioned template catalog that staff
 * manage in the portal.
 *
 * Owner (D-068 #7): template artwork is controlled and distributed from the portal, never built
 * into the app. A card template is therefore data: per format, a list of layers drawn from a
 * fixed set of primitives (background, photo, text, shape, image) in coordinates relative to the
 * card, with its pictures uploaded in the portal. The app has one generic renderer. A video
 * template names a Remotion composition (motion stays in code in V1) and supplies its assets and
 * parameters. The catalog follows the Sơ cứu content workflow (D-058): one draft, a second person
 * approves, approval publishes `publicConfig/keepsakes`, rollback re-publishes an older one. On
 * publish the server bumps the version of every template that changed, so a published version
 * never changes; a creation records the version it used. Assets are public, immutable and named by
 * their content hash (`content/keepsakes/{name}_{hash}.{ext}`) — artwork, never child media.
 */

export const keepsakeKinds = ['card', 'video'] as const;
export type KeepsakeKind = (typeof keepsakeKinds)[number];

/** MM10 "Dọc 4:5 · Vuông · Story 9:16"; videos are always `story`. */
export const keepsakeFormats = ['portrait', 'square', 'story'] as const;
export type KeepsakeFormat = (typeof keepsakeFormats)[number];

/** Export size of each format in pixels (cards; videos are 1080 × 1920). */
export const keepsakeFormatSize: Record<KeepsakeFormat, { width: number; height: number }> = {
  portrait: { width: 2160, height: 2700 },
  square: { width: 2160, height: 2160 },
  story: { width: 2160, height: 3840 },
};

export const keepsakeTiers = ['free', 'premium'] as const;
export const keepsakeStatuses = ['draft', 'published', 'archived'] as const;

/**
 * MM10 "Chọn dịp". Age occasions are counted from the date of birth; first-time occasions take
 * the date of the newest memory tagged with their milestone. `milestoneId` is the preset the
 * saved memory is tagged with (`p_seven_days` and `p_hundred_days` are only used here).
 */
export const occasions = {
  d7: { kind: 'age', days: 7, milestoneId: 'p_seven_days' },
  m1: { kind: 'age', months: 1, milestoneId: 'p_one_month' },
  d100: { kind: 'age', days: 100, milestoneId: 'p_hundred_days' },
  first_smile: { kind: 'first', milestoneId: 'p_first_smile' },
  rolls_over: { kind: 'first', milestoneId: 'p_rolls_over' },
  crawls: { kind: 'first', milestoneId: 'p_crawls' },
  first_steps: { kind: 'first', milestoneId: 'p_first_steps' },
  y1: { kind: 'age', months: 12, milestoneId: 'p_first_birthday' },
  // Chapter 01 set (docs/product/remember-2-templates.md, E-7). No nudges for these (D-068 #9 keeps
  // to 7 ngày, 1 tháng, 100 ngày, 1 tuổi); MM10 offers them when they fit the baby.
  birth: { kind: 'age', days: 0, milestoneId: 'p_birth' },
  m2: { kind: 'age', months: 2, milestoneId: 'p_month_2' },
  m3: { kind: 'age', months: 3, milestoneId: 'p_month_3' },
  m4: { kind: 'age', months: 4, milestoneId: 'p_month_4' },
  m5: { kind: 'age', months: 5, milestoneId: 'p_month_5' },
  m6: { kind: 'age', months: 6, milestoneId: 'p_month_6' },
  m7: { kind: 'age', months: 7, milestoneId: 'p_month_7' },
  m8: { kind: 'age', months: 8, milestoneId: 'p_month_8' },
  m9: { kind: 'age', months: 9, milestoneId: 'p_month_9' },
  m10: { kind: 'age', months: 10, milestoneId: 'p_month_10' },
  m11: { kind: 'age', months: 11, milestoneId: 'p_month_11' },
  laughs: { kind: 'first', milestoneId: 'p_laughs' },
  sits_up: { kind: 'first', milestoneId: 'p_sits_up' },
  stands: { kind: 'first', milestoneId: 'p_stands' },
  first_tooth: { kind: 'first', milestoneId: 'p_first_tooth' },
  first_solids: { kind: 'first', milestoneId: 'p_first_solids' },
  first_word: { kind: 'first', milestoneId: 'p_first_word' },
} as const satisfies Record<
  string,
  { kind: 'age' | 'first'; days?: number; months?: number; milestoneId: string }
>;
export type OccasionId = keyof typeof occasions;
/** In MM10's order. */
export const occasionIds = Object.keys(occasions) as [OccasionId, ...OccasionId[]];

const localized = (max: number) =>
  z.object({ vi: z.string().trim().min(1).max(max), en: z.string().trim().min(1).max(max) });

/** `#RRGGBB` or `#RRGGBBAA`. */
const hex = z.string().regex(/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/);
/** A palette slot (so "Màu" can swap it) or a fixed colour. */
export const keepsakeColorSchema = z.union([z.enum(['background', 'ink', 'accent']), hex]);

/**
 * The Remotion compositions the renderer has (`apps/renderer/src/compositions/Root.tsx` registers
 * exactly these; a test keeps them in step). A new one is added here and in the renderer, then
 * deployed with the renderer and the portal: never an app release (D-068 #7).
 */
export const keepsakeCompositions = [
  'FirstMonth',
  'FirstWeek',
  'HundredDays',
  'LittleMoments',
  // Chapter 01 set V01–V12 (docs/product/remember-2-templates.md §5).
  'WelcomeWorld',
  'OurFirstDays',
  'LittleLoveStory',
  'TinyMoments',
  'GrowingSoFast',
  'HelloSmile',
  'FirstMilestone',
  'HundredDaysLove',
  'HalfYear',
  'LetterToBaby',
  'ThenAndNow',
  'FirstBirthday',
  'PremiumArrival',
  'PremiumEmbrace',
  'PremiumHomecoming',
  'PremiumFirstMonth',
  'PremiumLittleThings',
  'PremiumMonthLetter',
  'PremiumMonthlyChapter',
  'PremiumThenNow',
  'PremiumOutgrownKeepsake',
  'PremiumSmileToKeep',
  'PremiumYouDidIt',
  'PremiumWorldToDiscover',
  'PremiumHeldWithLove',
  'PremiumAcrossGenerations',
  'PremiumCircleOfLove',
  'PremiumDayWithYou',
  'PremiumTiniestDetails',
  'PremiumSleepSoftly',
  'PremiumHundredDays',
  'PremiumFirstCelebration',
  'PremiumLittleAdventure',
  'PremiumTwelveMonths',
  'PremiumBirthdayLetter',
  'PremiumFamilyYear',
] as const;
export type KeepsakeComposition = (typeof keepsakeCompositions)[number];

export const keepsakeTemplateIdSchema = z.string().regex(/^(card|video)_[a-z0-9_]{2,40}$/);

/** An uploaded asset: `{name}_{hash}.webp` (pictures), `.mp3` / `.m4a` (music) or `.mp4` (a video
 * template's preview), stored at `content/keepsakes/{asset}`. */
export const keepsakeAssetSchema = z
  .string()
  .regex(/^[a-z0-9-]{2,40}_[a-f0-9]{8}\.(webp|mp3|m4a|mp4)$/);
export const keepsakeAssetPath = (asset: string) => `content/keepsakes/${asset}`;
export const keepsakeLimits = {
  /** Upload size of one asset before re-encoding. */
  assetBytes: 8 * 1024 * 1024,
  /** Pictures are re-encoded to WebP at most this wide (the card export width). */
  imageWidth: 2160,
  templates: 100,
  /** Large files (preview videos, music) go through `content/keepsakes-incoming/` (staff only). */
  incomingBytes: 50 * 1024 * 1024,
  tracks: 100,
} as const;

/**
 * Thư viện nhạc (owner, 2026-10-14: "mỗi template nên có nhạc default và được chọn nhạc qua thư
 * viện nhạc"; Q-062): tracks staff upload with their licence; a video template names its default,
 * parents may pick another or none (MM07 "Đổi"). A track is published only with a licence.
 */
export const keepsakeMusicIdSchema = z.string().regex(/^music_[a-z0-9_]{2,40}$/);
/** gentle · happy · warm · playful, and (owner, 2026-10-14) emotional piano, dreamy, celebration. */
export const keepsakeMoods = [
  'gentle',
  'happy',
  'warm',
  'playful',
  'emotional',
  'dreamy',
  'festive',
] as const;
export const keepsakeLicenceKinds = ['royaltyFree', 'licensed', 'original'] as const;
/** A track as the app sees it (`publicConfig/keepsakes.music`): no licence details. */
export const keepsakePublicMusicSchema = z.object({
  id: keepsakeMusicIdSchema,
  title: z.object({
    vi: z.string().trim().min(1).max(60),
    en: z.string().trim().min(1).max(60),
  }),
  artist: z.string().trim().max(60),
  mood: z.enum(keepsakeMoods),
  durationSec: z.number().int().min(5).max(600),
  asset: z.string().regex(/^[a-z0-9-]{2,40}_[a-f0-9]{8}\.(mp3|m4a)$/),
  status: z.enum(['draft', 'published', 'archived']),
  order: z.number().int().min(0).max(999),
});
export type KeepsakePublicMusic = z.infer<typeof keepsakePublicMusicSchema>;

export const keepsakeMusicSchema = keepsakePublicMusicSchema
  .extend({
    licence: z.object({
      kind: z.enum(keepsakeLicenceKinds),
      /** Where it comes from (store, composer) — never shown in the app. */
      source: z.string().trim().max(120),
      /** Licence or invoice number. */
      reference: z.string().trim().max(120),
      /** Last day it may be used; null: no end. */
      expiresOn: z.iso.date().nullable(),
    }),
  })
  .refine((m) => m.status !== 'published' || (m.licence.source && m.licence.reference), {
    message: 'a published track needs its licence (source and reference)',
  });
export type KeepsakeMusic = z.infer<typeof keepsakeMusicSchema>;

/** Position and size as fractions of the card (0–1; may overflow a little to bleed). */
const unit = z.number().min(-0.5).max(1.5);
export const keepsakeRectSchema = z.object({
  x: unit,
  y: unit,
  w: z.number().gt(0).max(2),
  h: z.number().gt(0).max(2),
});

/** What a text layer shows; the app fills it from the baby's profile and the parent's edits. */
export const keepsakeTextFields = [
  'occasion',
  'name',
  'date',
  'nameDate',
  'quote',
  'title',
  // E-2 (Chapter 01 set): from the profile and the photos, or the template's own texts.
  'age',
  'ageNumber',
  'ageUnit',
  'birthStats',
  'headline',
  'message',
  'photoLabel0',
  'photoLabel1',
  'photoLabel2',
  'photoLabel3',
  'photoLabel4',
  'photoLabel5',
  'photoLabel6',
  'photoLabel7',
  'photoLabel8',
  'photoLabel9',
  'photoLabel10',
  'photoLabel11',
  'detail0',
  'detail1',
  'detail2',
  'label0',
  'label1',
  'label2',
  'signature',
] as const;
export const keepsakeFonts = [
  'beVietnamPro',
  'lora',
  'dancingScript',
  // E-1: bundled in the app, the renderer and the portal (SIL OFL 1.1).
  'playfair',
  'baloo',
  'patrickHand',
] as const;
/** E-3: a gentle tilt, in degrees; missing = level. */
const rotate = z.number().min(-45).max(45).optional();

export const keepsakeLayerSchema = z.discriminatedUnion('type', [
  /** The whole card: a colour, optionally a picture over it. */
  z.object({
    type: z.literal('background'),
    color: keepsakeColorSchema,
    asset: keepsakeAssetSchema.nullable(),
  }),
  /** The parent's photo ("Chạm ảnh để đổi · kéo để căn"). */
  z.object({
    type: z.literal('photo'),
    slot: z.number().int().min(0).max(29),
    rect: keepsakeRectSchema,
    shape: z.enum(['rect', 'circle']),
    /** Corner radius as a fraction of the card width (rect only). */
    radius: z.number().min(0).max(0.5),
    rotate,
  }),
  z.object({
    type: z.literal('text'),
    field: z.enum(keepsakeTextFields),
    rect: keepsakeRectSchema,
    font: z.enum(keepsakeFonts),
    weight: z.union([z.literal(400), z.literal(500), z.literal(600), z.literal(700)]),
    /** Font size as a fraction of the card width. */
    size: z.number().gt(0).max(0.4),
    color: keepsakeColorSchema,
    opacity: z.number().min(0).max(1),
    align: z.enum(['left', 'center', 'right']),
    italic: z.boolean(),
    maxLines: z.number().int().min(1).max(5),
    rotate,
    /** E-4: tracking in em, and all caps (never for script fonts). */
    letterSpacing: z.number().min(-0.05).max(0.5).optional(),
    caps: z.boolean().optional(),
  }),
  /** A plain shape: a block, a gradient scrim, a ring, a star. */
  z.object({
    type: z.literal('shape'),
    shape: z.enum(['rect', 'circle', 'star']),
    rect: keepsakeRectSchema,
    color: keepsakeColorSchema,
    /** A vertical gradient from `color` to this one (rect only). */
    gradientTo: keepsakeColorSchema.nullable(),
    radius: z.number().min(0).max(0.5),
    /** 0 = filled; otherwise an outline this thick (fraction of the card width). */
    stroke: z.number().min(0).max(0.05),
    rotate,
  }),
  /** An uploaded picture: frame, sticker, texture. */
  z.object({
    type: z.literal('image'),
    /** Optional authored-copy switch, e.g. an explicitly selected celebration theme. */
    when: z
      .object({ field: z.string().regex(/^[a-z][a-zA-Z0-9]{0,31}$/), equals: z.string().max(32) })
      .optional(),
    asset: keepsakeAssetSchema,
    rect: keepsakeRectSchema,
    fit: z.enum(['cover', 'contain', 'fill']),
    opacity: z.number().min(0).max(1),
    rotate,
  }),
  /**
   * The Child Life lockup (D-068 #10; `keepsake-brand.ts`), drawn by the app in one colour —
   * usually the palette's ink, white on a photo. Fitted inside `rect`, keeping its aspect. At
   * most one per format; never removed from cards already made (they are pictures).
   */
  z.object({
    type: z.literal('brand'),
    kind: z.enum(['lockup']),
    rect: keepsakeRectSchema,
    color: keepsakeColorSchema,
    /** Subtle, never invisible. */
    opacity: z.number().min(0.3).max(1),
  }),
]);
export type KeepsakeLayer = z.infer<typeof keepsakeLayerSchema>;

const paletteSchema = z.object({ background: hex, ink: hex, accent: hex });

/** A video template's logo (D-068 #10; the renderer's `BrandMark` and closing lockup). */
export const keepsakeVideoBrandSchema = z.object({
  corner: z.boolean(),
  endCard: z.boolean(),
  opacity: z.number().min(0.3).max(1),
});
export type KeepsakeVideoBrand = z.infer<typeof keepsakeVideoBrandSchema>;
export const defaultKeepsakeVideoBrand: KeepsakeVideoBrand = {
  corner: true,
  endCard: true,
  opacity: 0.75,
};

/** Texts a template offers for editing: cards `title` / `quote` / `message` / `headline`;
 * videos also `closing`, `lines` (one per line, cycled over the photos) and `letter` (E-9). */
export const keepsakeTextKeys = [
  'title',
  'message',
  'quote',
  'headline',
  'closing',
  'lines',
  'letter',
] as const;
export type KeepsakeTextKey = (typeof keepsakeTextKeys)[number];
export const keepsakeTextFieldSchema = z.object({
  key: z.enum(keepsakeTextKeys),
  default: localized(600),
  max: z.number().int().min(1).max(600),
});

export const keepsakeTemplateSchema = z
  .object({
    id: keepsakeTemplateIdSchema,
    version: z.number().int().min(1),
    personalization: keepsakePersonalizationSchema.optional(),
    kind: z.enum(keepsakeKinds),
    name: localized(40),
    description: localized(120).nullable(),
    tier: z.enum(keepsakeTiers),
    status: z.enum(keepsakeStatuses),
    order: z.number().int().min(0).max(999),
    /** Empty: every occasion. */
    occasions: z.array(z.enum(occasionIds)).max(20),
    /** Suggested for babies in this age window (days since birth); null: any age. */
    ageDays: z
      .object({ min: z.number().int().min(0), max: z.number().int().min(0) })
      .refine((a) => a.min <= a.max)
      .nullable(),
    /** Card layers per format; the formats offered are the keys present. Null for videos. */
    layouts: z
      .partialRecord(z.enum(keepsakeFormats), z.array(keepsakeLayerSchema).min(1).max(40))
      .nullable(),
    /** Video: the Remotion composition (motion lives in the renderer in V1). Null for cards. */
    composition: z.enum(keepsakeCompositions).nullable(),
    /** Video: pictures and music the composition uses, by role. */
    assets: z.record(z.string().regex(/^[a-z][a-zA-Z0-9]{1,30}$/), keepsakeAssetSchema),
    photos: z.object({
      min: z.number().int().min(1).max(30),
      max: z.number().int().min(1).max(30),
    }),
    /**
     * Video scenes in order (MM06 "Cảnh 7: Bé cười"); empty for cards. A scene may say when its
     * photo was taken (days since birth) and which milestone it shows: MM06 suggests photos for
     * it from those. Absent: any photo (newest first).
     */
    scenes: z
      .array(
        z.object({
          hint: localized(40),
          optional: z.boolean(),
          ageDays: z
            .object({ min: z.number().int().min(0), max: z.number().int().min(0) })
            .refine((a) => a.min <= a.max)
            .optional(),
          occasion: z.enum(occasionIds).optional(),
        }),
      )
      .max(30),
    texts: z.array(keepsakeTextFieldSchema).max(4),
    palette: paletteSchema,
    /** MM11 "Màu": the palettes the parent may switch to (the first is `palette`). */
    palettes: z.array(paletteSchema).max(8),
    durationSec: z.number().int().min(5).max(180).nullable(),
    /** Catalog picture (portal list, MM01 / MM15 previews; cards also draw live previews). */
    thumb: keepsakeAssetSchema.nullable(),
    /** Videos: the track from the library played unless the parent picks another (MM07). */
    defaultMusic: keepsakeMusicIdSchema.nullable().default(null),
    /** Videos: a real video of the template (`.mp4`, made from licensed sample photos) for "Xem
     * mẫu"; without it the app plays the composition with sample pictures. */
    preview: keepsakeAssetSchema.nullable().default(null),
    previews: z.partialRecord(z.enum(['vi', 'en']), keepsakeAssetSchema).optional(),
    thumbs: z.partialRecord(z.enum(['vi', 'en']), keepsakeAssetSchema).optional(),
    /** Videos: the Child Life logo (D-068 #10) — a small corner mark through the video and the
     * lockup on the closing scene. Null: no branding (templates published before it). Cards
     * carry theirs as a `brand` layer. */
    brand: keepsakeVideoBrandSchema.nullable().default(null),
  })
  .refine(
    (t) =>
      !t.personalization ||
      t.personalization.beats.every((b) => b.slots.every((i) => i < t.photos.max)),
    { message: 'beat references unknown slot' },
  )
  .refine((t) => t.photos.min <= t.photos.max, { message: 'photos min > max' })
  .refine(
    (t) =>
      t.kind === 'card'
        ? t.layouts !== null && Object.keys(t.layouts).length > 0 && t.composition === null
        : t.layouts === null && t.composition !== null,
    { message: 'a card has layouts, a video a composition' },
  )
  .refine((t) => t.kind === 'card' || t.scenes.length === t.photos.max, {
    message: 'one scene per photo slot',
  })
  .refine((t) => t.kind === 'video' || t.durationSec === null, {
    message: 'cards have no duration',
  })
  .refine(
    (t) => keepsakeTemplateAssets(t).every((a) => a.endsWith('.webp') || t.kind === 'video'),
    {
      message: 'cards use pictures only',
    },
  )
  .refine((t) => t.preview === null || (t.kind === 'video' && t.preview.endsWith('.mp4')), {
    message: 'a preview is an .mp4 of a video template',
  })
  .refine(
    (t) =>
      Object.values(t.previews ?? {}).every((a) => t.kind === 'video' && a?.endsWith('.mp4')) &&
      Object.values(t.thumbs ?? {}).every((a) => a?.endsWith('.webp')),
    { message: 'localized previews are MP4 videos and thumbs are WebP pictures' },
  )
  .refine((t) => t.kind === 'video' || t.brand === null, {
    message: 'cards carry their logo as a brand layer',
  })
  .refine(
    (t) =>
      Object.values(t.layouts ?? {}).every(
        (layers) => (layers ?? []).filter((l) => l.type === 'brand').length <= 1,
      ),
    { message: 'at most one brand layer per format' },
  )
  .refine((t) => t.kind === 'video' || t.defaultMusic === null, {
    message: 'cards have no music',
  });
export type KeepsakeTemplate = z.infer<typeof keepsakeTemplateSchema>;

/** Every asset a template uses. */
export function keepsakeTemplateAssets(t: {
  thumb: string | null;
  preview?: string | null;
  previews?: Partial<Record<'vi' | 'en', string>> | undefined;
  thumbs?: Partial<Record<'vi' | 'en', string>> | undefined;
  assets: Record<string, string>;
  layouts: Partial<Record<KeepsakeFormat, readonly KeepsakeLayer[]>> | null;
}): string[] {
  const out = new Set<string>(Object.values(t.assets));
  if (t.thumb) out.add(t.thumb);
  if (t.preview) out.add(t.preview);
  for (const a of [...Object.values(t.previews ?? {}), ...Object.values(t.thumbs ?? {})])
    if (a) out.add(a);
  for (const layers of Object.values(t.layouts ?? {})) {
    for (const l of layers ?? []) if ('asset' in l && l.asset) out.add(l.asset);
  }
  return [...out];
}

/** `publicConfig/keepsakes`: the published catalog every signed-in member reads. */
/**
 * Owner (D-068 #8): Miễn phí / Cao cấp is controlled in the portal — each template's `tier`, and
 * for the whole catalog what a Cao cấp template means:
 * - `everyone`: anyone in the beta may use it (D-068 #3, the default while there is no paid plan);
 * - `hidden`: Cao cấp templates are not offered at all;
 * - `subscribers`: shown with their badge, used only by families whose plan gives
 *   `templates.premium` (paid, promo, or a beta that includes it, D-075 #1). The switch from `everyone` waits for the
 *   owner (Q-072) and a notice to beta families.
 * `badges`: show "Miễn phí" / "★ Cao cấp" on the templates (MM10).
 * `createMemorySession` and the video request enforce it on the server.
 */
export const keepsakePremiumAccess = ['everyone', 'hidden', 'subscribers'] as const;
export const keepsakePremiumSchema = z.object({
  access: z.enum(keepsakePremiumAccess),
  badges: z.boolean(),
});
export type KeepsakePremium = z.infer<typeof keepsakePremiumSchema>;
export const defaultKeepsakePremium: KeepsakePremium = { access: 'everyone', badges: true };

/**
 * Whether a template may be used under the catalog's premium setting: `ok`, `premium-required`
 * (subscribers mode without `templates.premium`: MO02, the paywall may show) or `unavailable`.
 * [hasPremiumTemplates] comes from the server capability resolver, never from the app.
 */
export function keepsakeTemplateAccess(
  t: { tier: (typeof keepsakeTiers)[number] },
  premium: KeepsakePremium,
  hasPremiumTemplates: boolean,
): 'ok' | 'premium-required' | 'unavailable' {
  if (t.tier === 'free' || premium.access === 'everyone') return 'ok';
  if (premium.access === 'hidden') return 'unavailable';
  return hasPremiumTemplates ? 'ok' : 'premium-required';
}

/** Whether a premium check is needed at all (only Cao cấp templates in `subscribers` mode). */
export function keepsakeNeedsPremiumCheck(
  t: { tier: (typeof keepsakeTiers)[number] },
  premium: KeepsakePremium,
): boolean {
  return t.tier === 'premium' && premium.access === 'subscribers';
}

const catalogOf = <M extends z.ZodType<{ id: string; status: string }>>(music: M) =>
  z
    .object({
      templates: z.array(keepsakeTemplateSchema).max(keepsakeLimits.templates),
      premium: keepsakePremiumSchema.default(() => ({ ...defaultKeepsakePremium })),
      /** Thư viện nhạc. */
      music: z.array(music).max(keepsakeLimits.tracks).default([]),
    })
    .refine((c) => new Set(c.templates.map((t) => t.id)).size === c.templates.length, {
      message: 'duplicate template ids',
    })
    .refine((c) => new Set(c.music.map((m) => m.id)).size === c.music.length, {
      message: 'duplicate track ids',
    })
    .refine(
      (c) =>
        c.templates.every(
          (t) =>
            t.status !== 'published' ||
            t.defaultMusic === null ||
            c.music.some((m) => m.id === t.defaultMusic && m.status === 'published'),
        ),
      { message: 'a published template’s default music must be a published track' },
    );

/** What staff edit (drafts, versions): tracks with their licence. */
export const keepsakeCatalogSchema = catalogOf(keepsakeMusicSchema);
/** `publicConfig/keepsakes` as the app and Functions read it: tracks without licence. */
export const keepsakePublicCatalogSchema = catalogOf(keepsakePublicMusicSchema);
export type KeepsakePublicCatalog = z.infer<typeof keepsakePublicCatalogSchema>;
export type KeepsakeCatalog = z.infer<typeof keepsakeCatalogSchema>;

/** What a creation remembers on its memory and media item (never re-rendered later). */
export const generatedSchema = z.object({
  kind: z.enum(keepsakeKinds),
  templateId: keepsakeTemplateIdSchema,
  templateVersion: z.number().int().min(1),
  occasion: z.enum(occasionIds).nullable(),
  format: z.enum(keepsakeFormats),
});
export type Generated = z.infer<typeof generatedSchema>;

/** The published templates of one kind, in display order. */
export function listTemplates(catalog: KeepsakeCatalog, kind: KeepsakeKind): KeepsakeTemplate[] {
  return catalog.templates
    .filter((t) => t.kind === kind && t.status === 'published')
    .sort((a, b) => a.order - b.order || a.id.localeCompare(b.id));
}

// ---------- Portal (staff), the Sơ cứu workflow (D-058) ----------

/** Save the open draft of the whole catalog. Versions are assigned when it is published. */
export const keepsakeDraftSchema = z
  .object({
    catalog: keepsakeCatalogSchema,
    notes: z.string().trim().max(500),
    /**
     * The published version this working copy was made from (`publicConfig/keepsakes.version`).
     * Approval refuses a draft made from an older one, so it never undoes a later release.
     */
    basedOn: z.string().max(40).nullable().optional(),
  })
  .strict();

/** Gửi duyệt · Duyệt & xuất bản · Trả lại · Huỷ nháp · Dùng lại bản này. */
export const keepsakeActSchema = z
  .object({
    versionId: z.string().regex(/^kv_[a-f0-9]{16}$/),
    action: z.enum(['submit', 'approve', 'reject', 'discard', 'rollback']),
    /** Optional (D-090), "" when missing; a rejection no longer needs one. */
    reason: staffReasonSchema,
  })
  .strict();

/** One asset, base64: PNG / JPEG / WebP pictures (re-encoded to WebP) or MP3 / M4A music. */
export const keepsakeUploadAssetSchema = z
  .object({
    name: z.string().regex(/^[a-z0-9-]{2,40}$/),
    /** A small file inline (pictures). */
    data: z
      .base64()
      .max(Math.ceil((keepsakeLimits.assetBytes * 4) / 3) + 4)
      .optional(),
    /** A large file the portal first put at `content/keepsakes-incoming/{uid}/{file}`. */
    incoming: z
      .string()
      .regex(
        /^content\/keepsakes-incoming\/[A-Za-z0-9_-]{2,128}\/[a-z0-9-]{2,60}\.(mp4|mp3|m4a|png|jpg|webp)$/,
      )
      .optional(),
  })
  .strict()
  .refine((r) => (r.data === undefined) !== (r.incoming === undefined), {
    message: 'either data or incoming',
  });

/**
 * The versions to publish: a template keeps its version when it is exactly the published one,
 * otherwise it gets the next number after the highest it ever had (immutable versions). Status
 * `archived` templates are dropped from what the app reads.
 */
function stableJson(v: unknown): string {
  if (Array.isArray(v)) return `[${v.map(stableJson).join(',')}]`;
  if (v && typeof v === 'object') {
    const entries = Object.entries(v)
      .filter(([, x]) => x !== undefined)
      .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));
    return `{${entries.map(([k, x]) => `${JSON.stringify(k)}:${stableJson(x)}`).join(',')}}`;
  }
  return JSON.stringify(v);
}

export function assignKeepsakeVersions(
  draft: KeepsakeCatalog,
  published: { templates: KeepsakeTemplate[] } | null,
  highest: Record<string, number>,
): KeepsakeCatalog {
  const before = new Map((published?.templates ?? []).map((t) => [t.id, t]));
  // Key order does not count: Firestore hands maps back in its own order.
  const same = (a: KeepsakeTemplate, b: KeepsakeTemplate) =>
    stableJson({ ...a, version: 0 }) === stableJson({ ...b, version: 0 });
  return {
    premium: draft.premium,
    // What the app offers: published tracks only (drafts and archived stay in the portal).
    music: (draft.music ?? []).filter((m) => m.status === 'published'),
    templates: draft.templates
      .filter((t) => t.status === 'published')
      .map((t) => {
        const prev = before.get(t.id);
        if (prev && same(prev, t)) return { ...t, version: prev.version };
        return { ...t, version: Math.max(highest[t.id] ?? 0, prev?.version ?? 0) + 1 };
      }),
  };
}

/** A published track without its licence, for `publicConfig/keepsakes`. */
export function publicKeepsakeMusic(m: KeepsakeMusic): KeepsakePublicMusic {
  // Unknown keys (the licence) are dropped by the parse.
  return keepsakePublicMusicSchema.parse(m);
}
