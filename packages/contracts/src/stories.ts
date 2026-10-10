import { z } from 'zod';
import { babyIdSchema } from './baby.js';
import { audiences, mediaIdSchema } from './memories.js';

/**
 * Stories (Slice S12; Figma 14a–14g, 11i; business map R-130…R-136, P-090…P-092, Q-036, D-003,
 * D-002). A story is a title, a cover and ordered blocks; photos are references to the baby's
 * memories ("Ảnh vẫn còn trong Kỷ niệm", R-133). Drafts are written by the app (Rules check the
 * shape); saving, re-saving and deleting go through callables. The Dart app mirrors these shapes
 * in `apps/mobile/lib/features/stories/story_models.dart`.
 */

export const storyIdSchema = z.string().regex(/^sto_[a-f0-9]{32}$/);
export const blockIdSchema = z.string().regex(/^b[a-z0-9]{1,15}$/);

export const storyLimits = {
  titleMax: 120,
  subtitleMax: 160,
  paragraphMax: 2000,
  quoteMax: 280,
  captionMax: 140,
  photosPerGroup: 4, // "Tối đa 4 ảnh một nhóm" (R-133)
  blocksMax: 40,
  /** "Bản nháp mỗi bé · Tối đa 3 mỗi tuần" (R-196). */
  aiDraftsPerWeek: 3,
  /** A week needs this many new items before a suggestion is made (P-090). */
  minItemsForSuggestion: 5,
  /** Photos the server attaches to a suggestion ("Từ 9 ảnh", Q-036). */
  suggestionPhotos: 9,
  /** Per-paragraph AI help per person per day. */
  assistPerDay: 60,
} as const;

export const storyKinds = ['story', 'letter'] as const;
export type StoryKind = (typeof storyKinds)[number];
export const storyStatuses = ['draft', 'saved'] as const;

const paragraphSchema = z.object({
  id: blockIdSchema,
  type: z.literal('paragraph'),
  text: z.string().max(storyLimits.paragraphMax),
  /** Still the AI's words; any edit makes it false ("Đã sửa · không còn là văn AI", R-132). */
  ai: z.boolean(),
});
const photosSchema = z.object({
  id: blockIdSchema,
  type: z.literal('photos'),
  items: z
    .array(
      z.object({
        mediaId: mediaIdSchema,
        caption: z.string().max(storyLimits.captionMax).nullable(),
      }),
    )
    .min(1)
    .max(storyLimits.photosPerGroup),
});
const milestoneSchema = z.object({
  id: blockIdSchema,
  type: z.literal('milestone'),
  name: z.string().min(1).max(60),
  date: z.iso.date(),
});
const quoteSchema = z.object({
  id: blockIdSchema,
  type: z.literal('quote'),
  text: z.string().min(1).max(storyLimits.quoteMax),
});

export const storyBlockSchema = z.discriminatedUnion('type', [
  paragraphSchema,
  photosSchema,
  milestoneSchema,
  quoteSchema,
]);
export type StoryBlock = z.infer<typeof storyBlockSchema>;

/** Media ids a story shows (cover first). */
export function storyMediaIds(story: {
  coverMediaId: string | null;
  blocks: StoryBlock[];
}): string[] {
  const ids = new Set<string>();
  if (story.coverMediaId) ids.add(story.coverMediaId);
  for (const b of story.blocks)
    if (b.type === 'photos') for (const i of b.items) ids.add(i.mediaId);
  return [...ids];
}

/** 14f "Lưu câu chuyện": audience + "Báo cho gia đình" (R-135). Re-saves never re-notify (P-091). */
export const saveStorySchema = z.object({
  babyId: babyIdSchema,
  storyId: storyIdSchema,
  audience: z.enum(audiences),
  notifyFamily: z.boolean(),
});

/** Not drawn (G-050): delete a story; its photos stay in Kỷ niệm. */
export const deleteStorySchema = z.object({ babyId: babyIdSchema, storyId: storyIdSchema });

/** 14b toolbar / 14c AI bar and "Gợi ý cho đoạn này" (R-132). */
export const assistOps = ['rewrite', 'shorter', 'warmer', 'suggest'] as const;
export type AssistOp = (typeof assistOps)[number];
export const storyAssistSchema = z.object({
  babyId: babyIdSchema,
  storyId: storyIdSchema,
  blockId: blockIdSchema,
  op: z.enum(assistOps),
  text: z.string().min(1).max(storyLimits.paragraphMax),
  locale: z.enum(['vi', 'en']),
});

/** "Gợi ý tuần này" on demand (the weekly job uses the same path). */
export const suggestStorySchema = z.object({ babyId: babyIdSchema, locale: z.enum(['vi', 'en']) });

/** What the model may use (R-196, Q-036): text only, nickname not real name. */
export interface StorySources {
  nickname: string;
  locale: 'vi' | 'en';
  rangeStart: string;
  rangeEnd: string;
  photos: number;
  videos: number;
  milestone: { name: string; date: string } | null;
  /** Captions and notes, oldest first, with their local date and the author's relation label. */
  notes: Array<{ date: string; text: string; by: string }>;
  /** Relation labels allowed in text ("Mẹ", "Ba", "Bà nội"). */
  people: string[];
}

/** Structured model output (P-092). */
export const aiDraftSchema = z.object({
  title: z.string().min(1).max(storyLimits.titleMax),
  paragraphs: z.array(z.string().min(1).max(600)).min(1).max(5),
  quote: z.string().max(storyLimits.quoteMax).nullable(),
});
export type AiDraft = z.infer<typeof aiDraftSchema>;

const words = (s: string) =>
  s
    .normalize('NFC')
    .toLocaleLowerCase('vi')
    .split(/[^\p{L}\p{N}]+/u)
    .filter(Boolean);

/**
 * Guardrails (P-092, R-136): every number and every capitalised name in AI text must come from the
 * sources (or the nickname / relation labels); no links or emails. Returns the problems found.
 */
export function guardAiText(text: string, sources: StorySources): string[] {
  const problems: string[] = [];
  if (/https?:\/\/|www\.|@\w/.test(text)) problems.push('link');
  const known = new Set(
    words(
      [
        sources.nickname,
        ...sources.people,
        sources.milestone?.name ?? '',
        ...sources.notes.map((n) => `${n.text} ${n.by}`),
        String(sources.photos),
        String(sources.videos),
        ...[
          sources.rangeStart,
          sources.rangeEnd,
          sources.milestone?.date ?? '',
          ...sources.notes.map((n) => n.date),
        ]
          .flatMap((d) => d.split('-'))
          .filter(Boolean)
          .map((x) => String(Number(x))),
      ].join(' '),
    ),
  );
  for (const n of text.match(/\d+/g) ?? []) {
    if (!known.has(n)) problems.push(`number:${n}`);
  }
  // Capitalised words not at a sentence start must be known (no invented people or places).
  const re = /(?<![.!?…:\n"“]\s*|^\s*)\b(\p{Lu}[\p{L}]+)/gu;
  for (const m of text.matchAll(re)) {
    const w = m[1]!.toLocaleLowerCase('vi');
    if (!known.has(w)) problems.push(`name:${m[1]}`);
  }
  return [...new Set(problems)];
}
