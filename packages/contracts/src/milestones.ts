import { z } from 'zod';
import { authorSchema } from './care.js';
import { memoryIdSchema, memoryLimits } from './memories.js';
import { contentReviewSchema, contentSourceSchema } from './rhythm.js';

/**
 * Mốc phát triển (developmental milestones; Figma v1.1 3a–3g `311:1184` … `311:41795`, portal
 * B07 / B08 `319:44574` / `319:44815`; D-076 #6). Two layers that never mix:
 *
 * 1. **Reference milestones** (editorial, from the portal): `contentMilestones/{referenceId}`.
 *    The portal writes them (draft → review → publish); the app reads only `status: 'published'`
 *    (Rules: any signed-in user, so the guide also works for caregivers and relatives). Every item
 *    stays `illustrative: true` until a qualified reviewer signs it (D-073 #2: engineering drafts
 *    like a specialist, the reviewer comes later; prod publishing still needs the review).
 * 2. **The baby's own records**: `babies/{babyId}/milestones/{recordId}`. This is the **same
 *    collection** as Kỷ niệm's family milestones ("Mốc nhà mình đã tạo", 10h3 / 10h4, R-105) and
 *    MS01's "Lưu vào Mốc": one concept, not a parallel one. Mapping:
 *    - a Kỷ niệm / MS01 custom milestone (`ms_<32 hex>`, legacy shape: id, babyId, name, date,
 *      createdBy, author, createdAt) reads as `kind: 'custom'`, `status: 'observed'`, no note, no
 *      memory ids, `source: 'memories'` (`parseBabyMilestone` fills the defaults);
 *    - an observed reference milestone is the record `p_<referenceId>` (one per baby and
 *      reference, so it cannot be recorded twice). The `p_` form is what `milestoneIdSchema`
 *      (memories.ts) already accepts, so a memory tagged with the record needs no server change,
 *      and the seed reuses the Kỷ niệm preset slugs where they mean the same thing (`p_lifts_head`,
 *      `p_rolls_over`, …): a memory tagged with such a preset belongs to that reference milestone;
 *    - `name` + `date` stay the fields Kỷ niệm reads (`date` is the day the baby did it,
 *      "achievedOn"), so the 10h3 picker keeps working; `following` records have no date and are
 *      left out of the picker.
 *
 * Who: records are written by a Cùng nuôi only (`moments.create` in family-actions.ts: "Mốc do
 * người có quyền xác nhận", MS01 annotation). Caregivers and relatives read the reference guide,
 * never the records: a relative sees a milestone only through the Kỷ niệm memory and its audience
 * (D-001 / D-002). Photos are never stored on a record: "Tạo kỷ niệm" makes an ordinary memory
 * tagged with the record (`milestoneRef.id = recordId`) and the record keeps its id
 * (`memoryIds`), so nothing is copied (3e / 3f).
 *
 * The app never judges early or late (B07 note, "Mỗi bé có nhịp riêng"): a reference milestone
 * outside its window is only "chưa ghi", never "chậm".
 */

// ---------- Reference milestones (portal B07 / B08) ----------

/** "Vận động", "Giao tiếp", "Nhận thức", "Cảm xúc – xã hội" (3a chips, B07). */
export const milestoneGroups = ['motor', 'communication', 'cognitive', 'socialEmotional'] as const;
export type MilestoneGroup = (typeof milestoneGroups)[number];

export const milestoneLimits = {
  /** The record and Kỷ niệm's tag share one name (`memoryLimits.milestoneNameMax`, 60). 3g
   * draws "14/80 ký tự": kept at 60 so a custom milestone always fits a memory's tag. */
  nameMax: memoryLimits.milestoneNameMax,
  titleMax: memoryLimits.milestoneNameMax,
  howToRecogniseMax: 600,
  talkToDoctorMax: 400,
  altMax: 200,
  noteMax: 500,
  memoryIdsMax: 20,
  sourcesMax: 6,
  /** "Gợi ý quanh tuổi của bé": windows that start within this many days are "sắp tới". */
  lookAheadDays: 42,
  /** Ages a reference range may cover (the seed covers 0–24 months, D-076 #6). */
  maxAgeWeeks: 156,
  maxAgeMonths: 36,
  /** B08: a published item is due for re-review 12 months after its review (or publish). */
  reReviewMonths: 12,
} as const;

/** A reference id; the baby's record of it is `p_<id>` (≤ 40 after the prefix, memories.ts). */
export const referenceMilestoneIdSchema = z.string().regex(/^[a-z][a-z0-9_]{1,39}$/);

/** Staff text is plain text, never markup (same test as the editorial content contract). */
function plain(s: string): boolean {
  return !/<\s*\/?\s*[a-zA-Z!?]/.test(s) && !/javascript\s*:/i.test(s);
}
const text = (max: number, min: number) =>
  z.string().trim().min(min).max(max).refine(plain, 'Plain text only, no markup');
const loc = (max: number, min: number) =>
  z.object({ vi: text(max, min), en: text(max, min) }).strict();

/**
 * "tham khảo 1–3 tháng": typical ages, both ends inclusive, counted from the date of birth (not
 * the due date). Weeks for the first months, months after; the app shows the same unit.
 */
export const milestoneAgeRangeSchema = z
  .object({
    unit: z.enum(['weeks', 'months']),
    from: z.number().int().min(0).max(milestoneLimits.maxAgeWeeks),
    to: z.number().int().min(0).max(milestoneLimits.maxAgeWeeks),
  })
  .strict()
  .refine((r) => r.to >= r.from, { message: 'Age range ends before it starts' })
  .refine((r) => r.unit === 'weeks' || r.to <= milestoneLimits.maxAgeMonths, {
    message: 'Age range beyond the covered ages',
  });
export type MilestoneAgeRange = z.infer<typeof milestoneAgeRangeSchema>;

export const milestoneSourceSchema = contentSourceSchema;

/**
 * B08 "illustration" (3b hero, ≈ 2:1): an image uploaded in the portal, public and immutable at
 * `content/library/{image}.webp` (the editorial content's image store and id shape).
 */
export const milestoneIllustrationSchema = z
  .object({
    image: z.string().regex(/^[a-z0-9-]{2,48}_[a-f0-9]{8}$/),
    alt: loc(milestoneLimits.altMax, 1),
  })
  .strict();
export const milestoneIllustrationPath = (image: string) => `content/library/${image}.webp`;

function referenceContentSchema(strict: boolean) {
  const min = strict ? 1 : 0;
  return z
    .object({
      group: z.enum(milestoneGroups),
      /** Order in the list (B08 "order"); ties fall back to the age range, then the id. */
      order: z.number().int().min(0).max(9999),
      ageRange: milestoneAgeRangeSchema,
      title: loc(milestoneLimits.titleMax, min),
      /** "Cách nhận biết" (3b): what to look for, in plain words. */
      howToRecognise: loc(milestoneLimits.howToRecogniseMax, min),
      /**
       * Optional "Khi nào nên hỏi bác sĩ": when it is worth asking the baby's doctor, worded as a
       * suggestion to ask, never a diagnosis; the app links it to the health guidance.
       */
      talkToDoctor: loc(milestoneLimits.talkToDoctorMax, min).nullable(),
      illustration: milestoneIllustrationSchema.nullable(),
      sources: z.array(milestoneSourceSchema).min(min).max(milestoneLimits.sourcesMax),
    })
    .strict();
}

/** B08 "Lưu nháp": the editable fields, texts may still be empty. */
export const referenceMilestoneDraftSchema = referenceContentSchema(false);
export type ReferenceMilestoneDraft = z.infer<typeof referenceMilestoneDraftSchema>;
/** Submit / approve / publish: complete in vi and en, at least one source. */
export const referenceMilestoneContentSchema = referenceContentSchema(true);
export type ReferenceMilestoneContent = z.infer<typeof referenceMilestoneContentSchema>;

/**
 * `contentMilestones/{id}`: one published reference milestone, the same publish metadata as the
 * editorial articles and stages (`content.ts`): `review` is the shared `contentReviewSchema`
 * (`null` = engineering draft; else reviewer, credential, reviewedOn: the "reviewer label" is
 * "{reviewer} · {credential}" and the review status is approved), and `illustrative` is true
 * exactly while `review` is null ("Nội dung minh hoạ · chờ chuyên môn duyệt").
 */
export const referenceMilestoneSchema = referenceContentSchema(true)
  .extend({
    id: referenceMilestoneIdSchema,
    status: z.literal('published'),
    /** 1 on first publish, +1 on every later publish. */
    revision: z.number().int().min(1),
    review: contentReviewSchema,
    illustrative: z.boolean(),
    /** 12 months after the review (or the publish while not reviewed yet). */
    reviewDueOn: z.iso.date(),
    publishedAt: z.iso.datetime(),
    firstPublishedAt: z.iso.datetime(),
  })
  .strict()
  .refine((m) => m.illustrative === (m.review === null), {
    message: 'illustrative must match review',
    path: ['illustrative'],
  });
export type ReferenceMilestone = z.infer<typeof referenceMilestoneSchema>;

/** The Firestore collection the portal publishes to and the app reads (`status == 'published'`). */
export const contentMilestonesCollection = 'contentMilestones';

/**
 * Problems that stop a publish: none on dev (illustrative drafts are fine, D-073 #2); on prod a
 * qualified review is required (D-058 pattern). The portal and the publish function share it.
 */
export function milestonePublishProblems(
  m: { review: z.infer<typeof contentReviewSchema> },
  opts: { requireReview: boolean },
): string[] {
  return opts.requireReview && m.review === null ? ['REVIEW_REQUIRED'] : [];
}

/**
 * The seed / import file (`content/milestones/milestones.seed.json`): engineering drafts, each
 * with its id and content; the portal imports them as drafts or the dev seed publishes them.
 */
export const milestoneSeedSchema = z
  .object({
    version: z.string().regex(/^mst_\d{8}_\d{2}$/),
    note: z.string().max(600),
    milestones: z
      .array(referenceMilestoneContentSchema.extend({ id: referenceMilestoneIdSchema }).strict())
      .min(1)
      .max(400),
  })
  .strict()
  .refine(
    (s) => new Set(s.milestones.map((m) => m.id)).size === s.milestones.length,
    'duplicate ids',
  );
export type MilestoneSeed = z.infer<typeof milestoneSeedSchema>;

/** A seed item as the published document the dev seed writes (engineering draft: no review). */
export function publishedFromSeed(
  item: MilestoneSeed['milestones'][number],
  at: string,
  revision = 1,
): ReferenceMilestone {
  return referenceMilestoneSchema.parse({
    ...item,
    status: 'published',
    revision,
    review: null,
    illustrative: true,
    reviewDueOn: addMonthsIso(at.slice(0, 10), milestoneLimits.reReviewMonths),
    publishedAt: at,
    firstPublishedAt: at,
  });
}

// ---------- The baby's records (babies/{babyId}/milestones/{recordId}) ----------

export const babyMilestoneKinds = ['reference', 'custom'] as const;
/** "Đã quan sát" (observed, dated) or "Lưu để theo dõi" (following, reference only, no date). */
export const babyMilestoneStatuses = ['observed', 'following'] as const;
/** Where it was recorded: Kỷ niệm's picker (R-105), this module, MS01 "Lưu vào Mốc", a card. */
export const babyMilestoneSources = ['memories', 'milestones', 'rhythm', 'keepsakes'] as const;

export const customMilestoneIdSchema = z.string().regex(/^ms_[a-f0-9]{32}$/);
export const referenceRecordIdSchema = z.string().regex(/^p_[a-z][a-z0-9_]{1,39}$/);

/** The record id of reference milestone [referenceId] for a baby. */
export function referenceRecordId(referenceId: string): string {
  return `p_${referenceId}`;
}

/** The reference id a record id stands for (`p_<id>`), or null for a custom one. */
export function referenceIdOfRecord(recordId: string): string | null {
  return recordId.startsWith('p_') ? recordId.slice(2) : null;
}

const isoDate = z.iso.date();

/** A stored record as written by this app version (all fields present). */
export const babyMilestoneSchema = z
  .object({
    id: z.union([customMilestoneIdSchema, referenceRecordIdSchema]),
    babyId: z.string().min(1),
    kind: z.enum(babyMilestoneKinds),
    referenceId: referenceMilestoneIdSchema.nullable(),
    /** The custom name, or the reference title in the recorder's language (denormalised). */
    name: z.string().trim().min(1).max(milestoneLimits.nameMax),
    status: z.enum(babyMilestoneStatuses),
    /** The day the baby did it (baby's zone); null only while `following`. */
    date: isoDate.nullable(),
    note: z.string().trim().min(1).max(milestoneLimits.noteMax).nullable(),
    /** Kỷ niệm memories made from or tagged with this record (newest last; ids only). */
    memoryIds: z.array(memoryIdSchema).max(milestoneLimits.memoryIdsMax),
    source: z.enum(babyMilestoneSources),
    createdBy: z.string().min(1),
    author: authorSchema,
    updatedBy: z.string().min(1),
  })
  .refine(
    (m) =>
      m.kind === 'custom'
        ? m.referenceId === null && customMilestoneIdSchema.safeParse(m.id).success
        : m.referenceId !== null && m.id === referenceRecordId(m.referenceId),
    { message: 'kind, id and referenceId do not match', path: ['id'] },
  )
  .refine((m) => (m.status === 'observed') === (m.date !== null), {
    message: 'observed records have a date; following ones do not',
    path: ['date'],
  })
  .refine((m) => m.status === 'observed' || m.kind === 'reference', {
    message: 'only reference milestones can be followed',
    path: ['status'],
  });
export type BabyMilestone = z.infer<typeof babyMilestoneSchema>;

/**
 * Any stored record, old or new: legacy Kỷ niệm / MS01 milestones (R-105 shape) get the defaults
 * of a custom, observed milestone recorded from Kỷ niệm. Returns null for a document that is not
 * a milestone (never throws on user data).
 */
export function parseBabyMilestone(doc: Record<string, unknown>): BabyMilestone | null {
  const filled = {
    kind: 'custom',
    referenceId: null,
    status: 'observed',
    note: null,
    memoryIds: [],
    source: 'memories',
    updatedBy: doc.createdBy,
    ...doc,
  };
  const parsed = babyMilestoneSchema.safeParse(filled);
  return parsed.success ? parsed.data : null;
}

// ---------- Windows and states (pure; the app mirrors them in Dart) ----------

function addMonthsIso(date: string, months: number): string {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  const first = new Date(Date.UTC(y, m - 1 + months, 1));
  const last = new Date(Date.UTC(first.getUTCFullYear(), first.getUTCMonth() + 1, 0)).getUTCDate();
  return new Date(Date.UTC(first.getUTCFullYear(), first.getUTCMonth(), Math.min(d, last)))
    .toISOString()
    .slice(0, 10);
}

function addDaysIsoLocal(date: string, days: number): string {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(y, m - 1, d + days)).toISOString().slice(0, 10);
}

/**
 * The calendar window of [range] for a baby born on [dateOfBirth], inclusive: weeks count whole
 * weeks of age ("tuần 4" = day 28 … 34), months count monthly birthdays ("tháng 3" = from the
 * 3-month birthday to the day before the 4-month one).
 */
export function milestoneWindow(
  dateOfBirth: string,
  range: MilestoneAgeRange,
): { start: string; end: string } {
  if (range.unit === 'weeks') {
    return {
      start: addDaysIsoLocal(dateOfBirth, range.from * 7),
      end: addDaysIsoLocal(dateOfBirth, range.to * 7 + 6),
    };
  }
  return {
    start: addMonthsIso(dateOfBirth, range.from),
    end: addDaysIsoLocal(addMonthsIso(dateOfBirth, range.to + 1), -1),
  };
}

/**
 * What 3a shows for a reference milestone: "đã thấy" (observed), "đang theo dõi" (following),
 * "quanh tuổi" (the window holds today), "sắp tới" (the window starts within the look-ahead) or
 * "chưa ghi" (anything else, earlier or later: never "late").
 */
export type MilestoneState = 'seen' | 'following' | 'now' | 'upcoming' | 'notRecorded';

export function milestoneState(
  record: Pick<BabyMilestone, 'status'> | null,
  window: { start: string; end: string },
  today: string,
): MilestoneState {
  if (record?.status === 'observed') return 'seen';
  if (record?.status === 'following') return 'following';
  if (today >= window.start && today <= window.end) return 'now';
  if (
    today < window.start &&
    window.start <= addDaysIsoLocal(today, milestoneLimits.lookAheadDays)
  ) {
    return 'upcoming';
  }
  return 'notRecorded';
}
