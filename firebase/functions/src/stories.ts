import { createHash } from 'node:crypto';
import {
  dayBoundsIn,
  deleteStorySchema,
  guardAiText,
  localDateIn,
  saveStorySchema,
  storyAssistSchema,
  storyBlockSchema,
  storyLimits,
  storyMediaIds,
  suggestStorySchema,
  type AiDraft,
  type Audience,
  type StoryBlock,
  type StorySources,
} from '@child-life/contracts';
import { FieldValue, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';
import { AiUnavailable, templateProvider, type AiProvider } from './ai.js';
import { familyNotice, recomputeEffective } from './albums.js';
import { familyFeatureEnabled } from './entitlements.js';
import { aiBudgetLeft, chargeAi } from './staff.js';

/**
 * Stories (S12, Figma 14a–14g, 11i). Drafts are the app's own documents (Rules check their shape);
 * the server saves them (audience, one generic notice, photos shared per D-002), deletes them, helps
 * with paragraphs and writes the weekly suggestion (P-090) through the AI adapter (D-003). Story
 * text, captions and notes are never logged.
 */

export type StoryErrorCode =
  | 'invalid-argument'
  | 'failed-precondition'
  | 'permission-denied'
  | 'not-found'
  | 'resource-exhausted';

export class StoryError extends Error {
  constructor(
    readonly code: StoryErrorCode,
    readonly reason: string,
  ) {
    super(reason);
  }
}

const DAY_MS = 86_400_000;

function parse<T>(
  schema: { safeParse(d: unknown): { success: boolean; data?: T } },
  data: unknown,
): T {
  const r = schema.safeParse(data);
  if (!r.success) throw new StoryError('invalid-argument', 'malformed');
  return r.data as T;
}

async function requireParent(db: Firestore, babyId: string, uid: string, now: Date) {
  const m = await db.doc(`babies/${babyId}/members/${uid}`).get();
  const until = m.get('accessUntilAt') as Timestamp | null | undefined;
  const active =
    m.exists && m.get('status') === 'active' && (!until || until.toMillis() > now.getTime());
  if (!active || m.get('role') !== 'coParent')
    throw new StoryError('permission-denied', 'parents-only');
  return m;
}

const storedShape = z.object({
  title: z.string().max(storyLimits.titleMax),
  coverMediaId: z.string().nullable(),
  blocks: z.array(storyBlockSchema).max(storyLimits.blocksMax),
});

// ---------- Save / delete ----------

/**
 * 14f "Lưu câu chuyện" and re-saves (14g "Sửa"). The first save to Gia đình with "Báo cho gia đình"
 * sends one generic notice; later saves never re-notify (P-091). Photos shown in a Gia đình story
 * are seen by the family (D-002); the count of such private photos is returned for the save sheet.
 */
export async function saveStory(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ madeVisible: number; notificationId: string | null }> {
  const req = parse(saveStorySchema, data);
  const me = await requireParent(db, req.babyId, uid, now);
  const baby = await db.doc(`babies/${req.babyId}`).get();
  if (baby.get('state') === 'deleting') throw new StoryError('failed-precondition', 'deleting');
  const ref = db.doc(`babies/${req.babyId}/stories/${req.storyId}`);
  const story = await ref.get();
  if (!story.exists) throw new StoryError('not-found', 'not-found');
  const shape = storedShape.safeParse(story.data());
  if (!shape.success) throw new StoryError('invalid-argument', 'malformed');
  if (!shape.data.title.trim()) throw new StoryError('invalid-argument', 'title-required');
  const mediaIds = storyMediaIds(shape.data);
  const media = mediaIds.length
    ? await db.getAll(...mediaIds.map((m) => db.doc(`babies/${req.babyId}/media/${m}`)))
    : [];
  if (media.some((m) => !m.exists || m.get('deleted') === true)) {
    throw new StoryError('failed-precondition', 'media-missing');
  }

  const wasSaved = story.get('status') === 'saved';
  const wasFamily = wasSaved && story.get('audience') === 'family';
  const before = new Set<string>((story.get('familyMediaIds') as string[] | undefined) ?? []);
  const after = new Set<string>(req.audience === 'family' ? mediaIds : []);
  const madeVisible =
    req.audience === 'family'
      ? media.filter((m) => m.get('effectiveAudience') !== 'family').length
      : 0;

  const writer = db.batch();
  for (const m of before) {
    if (!after.has(m)) {
      writer.update(db.doc(`babies/${req.babyId}/media/${m}`), {
        familyStoryIds: FieldValue.arrayRemove(req.storyId),
      });
    }
  }
  for (const m of after) {
    if (!before.has(m)) {
      writer.update(db.doc(`babies/${req.babyId}/media/${m}`), {
        familyStoryIds: FieldValue.arrayUnion(req.storyId),
      });
    }
  }
  writer.update(ref, {
    status: 'saved',
    audience: req.audience,
    familyMediaIds: [...after],
    suggestion: false,
    savedAt: wasSaved ? story.get('savedAt') : now,
    savedBy: uid,
    updatedAt: now,
    updatedBy: uid,
  });
  await writer.commit();
  await recomputeEffective(db, req.babyId, [...new Set([...before, ...after])], now);

  let notificationId: string | null = null;
  if (req.audience === 'family' && !wasFamily && req.notifyFamily) {
    notificationId = await familyNotice(
      db,
      req.babyId,
      'story',
      1,
      uid,
      {
        name: me.get('displayName'),
        relation: me.get('relation'),
        relationCustom: me.get('relationCustom') ?? null,
      },
      now,
      { collection: 'stories', id: req.storyId },
    );
  }
  return { madeVisible, notificationId };
}

/** Not drawn (G-050): a story goes; its photos stay in Kỷ niệm and follow their own audience. */
export async function deleteStory(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<void> {
  const req = parse(deleteStorySchema, data);
  await requireParent(db, req.babyId, uid, now);
  const ref = db.doc(`babies/${req.babyId}/stories/${req.storyId}`);
  const story = await ref.get();
  if (!story.exists) return;
  const family = (story.get('familyMediaIds') as string[] | undefined) ?? [];
  const writer = db.batch();
  for (const m of family) {
    writer.update(db.doc(`babies/${req.babyId}/media/${m}`), {
      familyStoryIds: FieldValue.arrayRemove(req.storyId),
    });
  }
  const loves = await db
    .collection(`babies/${req.babyId}/reactions`)
    .where('target', '==', 'story')
    .where('targetId', '==', req.storyId)
    .get();
  loves.docs.forEach((d) => writer.delete(d.ref));
  writer.delete(ref);
  await writer.commit();
  await recomputeEffective(db, req.babyId, family, now);
}

// ---------- Sources and AI ----------

const relationLabels: Record<string, { vi: string; en: string }> = {
  mother: { vi: 'Mẹ', en: 'Mum' },
  father: { vi: 'Ba', en: 'Dad' },
  grandmother: { vi: 'Bà', en: 'Grandma' },
  grandfather: { vi: 'Ông', en: 'Grandpa' },
};

function byLabel(
  author: { name?: string; relation?: string; relationCustom?: string | null } | undefined,
  locale: 'vi' | 'en',
) {
  if (!author) return '';
  return (
    relationLabels[author.relation ?? '']?.[locale] ?? author.relationCustom ?? author.name ?? ''
  );
}

/** The week a suggestion covers: the 7 days ending [end] in the baby's zone. */
export function weekOf(zone: string, now: Date): { start: string; end: string } {
  const end = localDateIn(zone, now);
  const [y, m, d] = end.split('-').map(Number) as [number, number, number];
  const start = new Date(Date.UTC(y, m - 1, d - 6)).toISOString().slice(0, 10);
  return { start, end };
}

/** Text-only sources for a week (R-196, Q-036) and the photos the server attaches. */
export async function weekSources(
  db: Firestore,
  babyId: string,
  locale: 'vi' | 'en',
  now: Date,
): Promise<{ sources: StorySources; photoIds: string[]; items: number }> {
  const baby = await db.doc(`babies/${babyId}`).get();
  const zone = (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh';
  const { start, end } = weekOf(zone, now);
  const from = dayBoundsIn(zone, start).start;
  const to = dayBoundsIn(zone, end).end;
  const memories = await db
    .collection(`babies/${babyId}/memories`)
    .where('occurredAt', '>=', from)
    .where('occurredAt', '<', to)
    .get();
  const media = await db
    .collection(`babies/${babyId}/media`)
    .where('captureAt', '>=', from)
    .where('captureAt', '<', to)
    .get();
  const ready = media.docs.filter((m) => m.get('status') === 'ready' && m.get('deleted') !== true);
  const photos = ready.filter((m) => m.get('type') === 'photo');
  const videos = ready.filter((m) => m.get('type') === 'video');
  const milestoneDoc = [...memories.docs, ...ready].find((d) => d.get('milestone'));
  const milestone = milestoneDoc
    ? {
        name: milestoneDoc.get('milestone.name') as string,
        date: milestoneDoc.get('milestone.date') as string,
      }
    : null;
  const notes = memories.docs
    .filter((m) => m.get('deleted') !== true && (m.get('caption') as string | null))
    .sort(
      (a, b) =>
        (a.get('occurredAt') as Timestamp).toMillis() -
        (b.get('occurredAt') as Timestamp).toMillis(),
    )
    .map((m) => ({
      date: localDateIn(zone, (m.get('occurredAt') as Timestamp).toDate()),
      text: (m.get('caption') as string).slice(0, 500),
      by: byLabel(m.get('author'), locale),
    }));
  // Q-036: the milestone's photos first, then the most recent (at most 9).
  const ordered = [...photos].sort((a, b) => {
    const am = a.get('milestone') ? 1 : 0;
    const bm = b.get('milestone') ? 1 : 0;
    if (am !== bm) return bm - am;
    return (
      (b.get('captureAt') as Timestamp).toMillis() - (a.get('captureAt') as Timestamp).toMillis()
    );
  });
  const people = [...new Set(notes.map((n) => n.by).filter(Boolean))];
  return {
    sources: {
      nickname: baby.get('nickname') as string,
      locale,
      rangeStart: start,
      rangeEnd: end,
      photos: photos.length,
      videos: videos.length,
      milestone,
      notes,
      people,
    },
    photoIds: ordered.slice(0, storyLimits.suggestionPhotos).map((m) => m.id),
    items:
      ready.length +
      memories.docs.filter((m) => !(m.get('mediaIds') as string[] | undefined)?.length).length,
  };
}

/** Builds the draft's blocks: paragraphs with photo groups (≤ 4) between them. */
export function draftBlocks(
  draft: AiDraft,
  photoIds: string[],
  milestone: StorySources['milestone'],
): StoryBlock[] {
  const blocks: StoryBlock[] = [];
  const groups: string[][] = [];
  const rest = photoIds.slice(1); // the first one is the cover
  for (let i = 0; i < rest.length; i += 4) groups.push(rest.slice(i, i + 4));
  let n = 0;
  const id = () => `b${(n++).toString(36)}`;
  draft.paragraphs.forEach((p, i) => {
    blocks.push({ id: id(), type: 'paragraph', text: p, ai: true });
    if (i === 0 && draft.quote) blocks.push({ id: id(), type: 'quote', text: draft.quote });
    const g = groups[i];
    if (g?.length)
      blocks.push({
        id: id(),
        type: 'photos',
        items: g.map((m) => ({ mediaId: m, caption: null })),
      });
  });
  for (const g of groups.slice(draft.paragraphs.length)) {
    blocks.push({ id: id(), type: 'photos', items: g.map((m) => ({ mediaId: m, caption: null })) });
  }
  if (milestone)
    blocks.push({ id: id(), type: 'milestone', name: milestone.name, date: milestone.date });
  return blocks;
}

/** Nháp câu chuyện AI for this family: its flag, the admin override and the tier (D-089). */
async function aiEnabled(db: Firestore, familyId: string, now: Date): Promise<boolean> {
  return familyFeatureEnabled(db, familyId, 'ai_story_drafts', now);
}

/**
 * "Gợi ý tuần này" (P-090): with at least 5 new items this week, at most 3 drafts per baby per
 * week (R-196), a draft from the provider — validated and guarded (P-092), falling back to the
 * template provider when the model fails or invents (G-051: never partial text).
 */
export async function suggestStory(
  db: Firestore,
  provider: AiProvider,
  babyId: string,
  locale: 'vi' | 'en',
  now: Date,
  options: { ignoreFlag?: boolean } = {},
): Promise<{ storyId: string | null; reason: string; provider?: string }> {
  const baby = await db.doc(`babies/${babyId}`).get();
  if (!baby.exists || baby.get('state') === 'deleting') return { storyId: null, reason: 'no-baby' };
  if (!options.ignoreFlag && !(await aiEnabled(db, baby.get('familyId') as string, now))) {
    return { storyId: null, reason: 'flag-off' };
  }
  // A09: at 100 % of the month's budget, new suggestions pause; saved stories are unaffected.
  if (provider.name === 'openai' && !(await aiBudgetLeft(db, now))) {
    return { storyId: null, reason: 'budget-paused' };
  }
  const { sources, photoIds, items } = await weekSources(db, babyId, locale, now);
  if (items < storyLimits.minItemsForSuggestion) return { storyId: null, reason: 'too-few-items' };
  const weekKey = `${babyId}_${sources.rangeEnd}`;
  const recent = await db
    .collection(`babies/${babyId}/stories`)
    .where('origin', '==', 'ai')
    .where('createdAt', '>', new Date(now.getTime() - 7 * DAY_MS))
    .get();
  if (recent.size >= storyLimits.aiDraftsPerWeek) return { storyId: null, reason: 'weekly-limit' };

  let draft: AiDraft | null = null;
  let used: AiProvider['name'] = provider.name;
  for (let attempt = 0; attempt < 2 && !draft; attempt++) {
    try {
      const out = await provider.draft(sources);
      const problems = [out.title, ...out.paragraphs, out.quote ?? ''].flatMap((t) =>
        guardAiText(t, sources),
      );
      if (problems.length === 0) draft = out;
    } catch (error) {
      if (!(error instanceof AiUnavailable) && !(error instanceof z.ZodError)) throw error;
    }
  }
  if (!draft) {
    draft = await templateProvider.draft(sources);
    used = 'template';
  } else if (used === 'openai') {
    await chargeAi(db, now, storyLimits.costPerDraftVnd);
  }
  const storyId = `sto_${createHash('sha256').update(`${weekKey}:${recent.size}`).digest('hex').slice(0, 32)}`;
  const filed = await db.runTransaction(async (tx) => {
    const current = await tx.get(baby.ref);
    if (!current.exists || current.get('state') === 'deleting') return false;
    tx.set(db.doc(`babies/${babyId}/stories/${storyId}`), {
      id: storyId,
      babyId,
      kind: 'story',
      origin: 'ai',
      suggestion: true,
      status: 'draft',
      title: draft.title,
      coverMediaId: photoIds[0] ?? null,
      blocks: draftBlocks(draft, photoIds, sources.milestone),
      audience: 'family' satisfies Audience,
      rangeStart: sources.rangeStart,
      rangeEnd: sources.rangeEnd,
      sourcePhotos: sources.photos,
      milestone: sources.milestone,
      provider: used,
      locale,
      createdBy: 'ai',
      author: null,
      loveCount: 0,
      createdAt: now,
      updatedAt: now,
    });
    return true;
  });
  return filed
    ? { storyId, reason: 'created', provider: used }
    : { storyId: null, reason: 'no-baby' };
}

/** Weekly run over every active baby (Sunday evening, P-090). */
export async function suggestForAll(
  db: Firestore,
  provider: AiProvider,
  now: Date,
): Promise<number> {
  const babies = await db.collection('babies').where('state', '==', 'active').select().get();
  let made = 0;
  for (const b of babies.docs) {
    try {
      const r = await suggestStory(db, provider, b.id, await storyLocale(db, b.id), now);
      if (r.storyId) made++;
    } catch {
      // One baby's failure never stops the others; retried next week.
    }
  }
  return made;
}

/** An explicit story request wins; otherwise follow the owner's registered app language.
 * Never translate saved stories or pick a locale from another family member's private data. */
export async function storyLocale(db: Firestore, babyId: string): Promise<'vi' | 'en'> {
  const preferred = await db.doc(`babies/${babyId}/storyPreferences/locale`).get();
  if (preferred.get('locale') === 'en' || preferred.get('locale') === 'vi')
    return preferred.get('locale');
  const baby = await db.doc(`babies/${babyId}`).get();
  const owner = baby.get('ownerUid') as string | undefined;
  if (!owner) return 'vi';
  const devices = await db.collection(`users/${owner}/devices`).orderBy('updatedAt', 'desc').get();
  const device = devices.docs.find(
    (d) => !d.get('signedOutAt') && ['vi', 'en'].includes(d.get('language')),
  );
  return device?.get('language') === 'en' ? 'en' : 'vi';
}

/**
 * 14b "Viết lại" / "Ấm hơn", 14c "Ngắn hơn" / "Gợi ý khác" (R-132): alternatives for one paragraph,
 * guarded against the story's own facts (P-092), rate-limited per person per day.
 */
export async function storyAssist(
  db: Firestore,
  provider: AiProvider,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ options: string[] }> {
  const req = parse(storyAssistSchema, data);
  await requireParent(db, req.babyId, uid, now);
  const story = await db.doc(`babies/${req.babyId}/stories/${req.storyId}`).get();
  if (!story.exists) throw new StoryError('not-found', 'not-found');
  const day = now.toISOString().slice(0, 10);
  const counter = db.doc(`rateLimits/storyAssist_${uid}_${day}`);
  const allowed = await db.runTransaction(async (tx) => {
    const c = await tx.get(counter);
    const n = (c.get('count') as number | undefined) ?? 0;
    if (n >= storyLimits.assistPerDay) return false;
    tx.set(
      counter,
      { count: n + 1, expiresAt: new Date(now.getTime() + 2 * DAY_MS) },
      { merge: true },
    );
    return true;
  });
  if (!allowed) throw new StoryError('resource-exhausted', 'assist-limit');
  const baby = await db.doc(`babies/${req.babyId}`).get();
  const nickname = baby.get('nickname') as string;
  const blocks = (story.get('blocks') as StoryBlock[] | undefined) ?? [];
  const storyText = blocks
    .map((b) =>
      b.type === 'paragraph' || b.type === 'quote' ? b.text : b.type === 'milestone' ? b.name : '',
    )
    .join(' ');
  const sources: StorySources = {
    nickname,
    locale: req.locale,
    rangeStart: (story.get('rangeStart') as string | undefined) ?? '',
    rangeEnd: (story.get('rangeEnd') as string | undefined) ?? '',
    photos: (story.get('sourcePhotos') as number | undefined) ?? 0,
    videos: 0,
    milestone: (story.get('milestone') as StorySources['milestone']) ?? null,
    notes: [{ date: '', text: `${req.text} ${storyText} ${story.get('title') ?? ''}`, by: '' }],
    people: Object.values(relationLabels).map((l) => l[req.locale]),
  };
  let options: string[];
  try {
    options = await provider.assist(req.op, req.text, { nickname, locale: req.locale });
  } catch (error) {
    if (error instanceof AiUnavailable)
      throw new StoryError('failed-precondition', 'ai-unavailable');
    throw error;
  }
  const safe = options
    .map((o) => o.trim())
    .filter(
      (o) =>
        o.length > 0 &&
        o.length <= storyLimits.paragraphMax &&
        guardAiText(o, sources).length === 0,
    );
  if (safe.length === 0) throw new StoryError('failed-precondition', 'ai-unavailable');
  return { options: safe };
}

/** Parents ask for this week's suggestion now (same rules as the weekly job). */
export async function requestSuggestion(
  db: Firestore,
  provider: AiProvider,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ storyId: string | null; reason: string }> {
  const req = parse(suggestStorySchema, data);
  await requireParent(db, req.babyId, uid, now);
  await db.runTransaction(async (tx) => {
    const [baby, member] = await Promise.all([
      tx.get(db.doc(`babies/${req.babyId}`)),
      tx.get(db.doc(`babies/${req.babyId}/members/${uid}`)),
    ]);
    const until = member.get('accessUntilAt') as Timestamp | undefined;
    if (!baby.exists || baby.get('state') === 'deleting')
      throw new StoryError('failed-precondition', 'deleting');
    if (
      member.get('status') !== 'active' ||
      member.get('role') !== 'coParent' ||
      (until && until.toMillis() <= now.getTime())
    )
      throw new StoryError('permission-denied', 'parents-only');
    tx.set(db.doc(`babies/${req.babyId}/storyPreferences/locale`), {
      locale: req.locale,
      updatedAt: now,
    });
  });
  const r = await suggestStory(db, provider, req.babyId, req.locale, now);
  return { storyId: r.storyId, reason: r.reason };
}

export const _test = { byLabel };
