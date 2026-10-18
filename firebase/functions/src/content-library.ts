import { createHash, randomBytes } from 'node:crypto';
import {
  articleContentStrictSchema,
  articleDraftSchema,
  articleIdSchema,
  contentActRequestSchema,
  contentArticleSchema,
  contentCollections,
  contentDraftsCollection,
  contentImageUploadSchema,
  contentImages,
  contentItemRequestSchema,
  contentKinds,
  contentLinks,
  contentListRequestSchema,
  contentSaveRequestSchema,
  contentSeedRequestSchema,
  contentStageSchema,
  editorialDisplayStatus,
  localDateIn,
  reviewDueFrom,
  stageBuckets,
  stageContentStrictSchema,
  stageCoverage,
  stageCoversBucket,
  stageDraftSchema,
  stageIdSchema,
  type ContentKind,
  type EditorialReview,
  type EditorialStatus,
  type StageAge,
} from '@child-life/contracts';
import {
  Timestamp,
  type DocumentReference,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import type { FirstAidImageStore } from './content.js';
import { milestoneAdapter } from './content-milestones.js';
import { seedArticles, seedStages } from './content-seed.js';
import { StaffError, parse, requireStaff, staffAudit, type Staff } from './staff.js';
import { mayApproveOwn, readContentPolicy, reviewRequired } from './content-policy.js';

/**
 * Editorial content on the portal (D-076 #5–#7; Figma B01–B08): Thư viện chăm bé articles,
 * "Nội dung theo giai đoạn" (app "Giai đoạn của bé") and reference Mốc phát triển. One draft per
 * item in `contentDrafts/{id}` (staff-only, through these callables):
 *
 *   Nháp → Gửi duyệt → Duyệt (a different person than the last editor, D-058; the qualified
 *   review on prod) → Xuất bản (writes `contentArticles` / `contentStages` / `contentMilestones`)
 *
 * Editing a published item opens a new draft while the published revision stays on the app.
 * "Gỡ khỏi app" deletes the published document; "Xác nhận lại" renews the 12-month re-review.
 * Engineering drafts (D-073 #2) publish with `review: null`, `illustrative: true`. Every step is
 * in the audit log (never content text: ids, kinds and statuses only).
 */

export interface ContentLibraryDeps {
  /** Prod: approving and publishing need the qualified review recorded. */
  requireReview: boolean;
  /** Public WebP pictures under `content/library/`. */
  images: FirstAidImageStore;
}

/**
 * How one kind is validated and published. Articles and stages are defined here; reference
 * milestones come from the milestones slice (`content-milestones.ts`) so both slices share the
 * workflow without sharing a schema.
 */
export interface ContentKindAdapter {
  /** A fresh id for "+ mới". */
  newId(): string;
  /** Ids this kind accepts (seed ids included). */
  isId(id: string): boolean;
  draft: { safeParse(d: unknown): { success: boolean; data?: unknown } };
  strict: { safeParse(d: unknown): { success: boolean; data?: unknown } };
  /** Builds the published document (throws when invalid). */
  published(
    id: string,
    data: Record<string, unknown>,
    meta: PublishedMeta,
  ): Record<string, unknown>;
  /** Short, non-content row fields for lists (counts, ages, taxonomy). */
  row(data: Record<string, unknown>): Record<string, unknown>;
  /** The engineering drafts; null when [payload] (milestones: the seed file) is invalid. */
  seed(
    payload?: unknown,
  ): Array<{ id: string; reviewerLabel: string | null; data: Record<string, unknown> }> | null;
}

export interface PublishedMeta {
  status: 'published';
  revision: number;
  review: EditorialReview;
  illustrative: boolean;
  reviewDueOn: string;
  publishedAt: string;
  firstPublishedAt: string;
}

type Data = Record<string, unknown>;
type Live = {
  revision: number;
  publishedAt: string;
  firstPublishedAt: string;
  reviewDueOn: string;
  review: EditorialReview;
  illustrative: boolean;
  publishedByName: string;
};

const ZONE = 'Asia/Ho_Chi_Minh';
const drafts = (db: Firestore) => db.collection(contentDraftsCollection);
const publicRef = (db: Firestore, kind: ContentKind, id: string) =>
  db.doc(`${contentCollections[kind]}/${id}`);
const iso = (v: unknown) =>
  v instanceof Timestamp ? v.toDate().toISOString() : v instanceof Date ? v.toISOString() : null;
const count = <T>(xs: readonly T[] | undefined) => xs?.length ?? 0;

const articleAdapter: ContentKindAdapter = {
  newId: () => `art_${randomBytes(5).toString('hex')}`,
  isId: (id) => articleIdSchema.safeParse(id).success,
  draft: articleDraftSchema,
  strict: articleContentStrictSchema,
  published: (id, data, meta) => contentArticleSchema.parse({ id, ...data, ...meta }),
  row: (d) => ({
    library: d.library,
    topic: d.topic,
    format: d.format,
    ageWeeks: d.ageWeeks,
    readingMinutes: d.readingMinutes,
    blocks: {
      vi: count((d.body as { vi?: unknown[] } | undefined)?.vi),
      en: count((d.body as { en?: unknown[] } | undefined)?.en),
    },
    hasCover: !!d.cover,
    sources: count(d.sources as unknown[]),
  }),
  seed: () => seedArticles.map((s) => ({ ...s, data: s.data as unknown as Data })),
};

const stageAdapter: ContentKindAdapter = {
  newId: () => `stg_${randomBytes(4).toString('hex')}`,
  isId: (id) => stageIdSchema.safeParse(id).success,
  draft: stageDraftSchema,
  strict: stageContentStrictSchema,
  published: (id, data, meta) => contentStageSchema.parse({ id, ...data, ...meta }),
  row: (d) => {
    const doing = d.doing as { vi?: unknown[] } | undefined;
    const tryThis = d.tryThis as { vi?: unknown[] } | undefined;
    return {
      age: d.age,
      points: { doing: count(doing?.vi), tryThis: count(tryThis?.vi) },
      audience: d.audience,
      sources: count(d.sources as unknown[]),
    };
  },
  seed: () => seedStages.map((s) => ({ ...s, data: s.data as unknown as Data })),
};

function adapterOf(kind: ContentKind): ContentKindAdapter {
  if (kind === 'article') return articleAdapter;
  if (kind === 'stage') return stageAdapter;
  return milestoneAdapter;
}

const titleOf = (d: Data) =>
  ((d.title ?? d.name) as { vi?: string; en?: string } | undefined) ?? { vi: '', en: '' };

function rowOf(snap: DocumentSnapshot, today: string) {
  const kind = snap.get('kind') as ContentKind;
  const data = (snap.get('data') as Data | undefined) ?? {};
  const live = (snap.get('live') as Live | null | undefined) ?? null;
  const status = snap.get('status') as EditorialStatus;
  let extra: Data;
  try {
    extra = adapterOf(kind).row(data);
  } catch {
    extra = {};
  }
  return {
    id: snap.id,
    kind,
    status,
    displayStatus: editorialDisplayStatus(
      { status, reviewDueOn: live?.reviewDueOn ?? null },
      today,
    ),
    /** On the app now (possibly with a newer draft being edited). */
    live: live
      ? {
          revision: live.revision,
          publishedAt: live.publishedAt,
          reviewDueOn: live.reviewDueOn,
          illustrative: live.illustrative,
          reviewer: live.review?.reviewer ?? null,
          dueForReview: live.reviewDueOn < today,
        }
      : null,
    title: { vi: titleOf(data).vi ?? '', en: titleOf(data).en ?? '' },
    reviewerLabel: (snap.get('reviewerLabel') as string | null | undefined) ?? null,
    lastEditorName: (snap.get('lastEditorName') as string | undefined) ?? '',
    updatedAt: iso(snap.get('updatedAt')),
    submittedByName: (snap.get('submittedByName') as string | null | undefined) ?? null,
    approverName: (snap.get('approverName') as string | null | undefined) ?? null,
    rejection: (snap.get('rejection') as { by: string; reason: string } | null | undefined) ?? null,
    links: contentLinks(kind, data),
    ...extra,
  };
}
type Row = ReturnType<typeof rowOf>;

function countsOf(rows: Row[]) {
  return {
    inApp: rows.filter((r) => r.live).length,
    pending: rows.filter((r) => r.status === 'in_review' || r.status === 'approved').length,
    inReview: rows.filter((r) => r.status === 'in_review').length,
    approved: rows.filter((r) => r.status === 'approved').length,
    drafts: rows.filter((r) => r.status === 'draft').length,
    dueForReview: rows.filter((r) => r.live?.dueForReview).length,
    archived: rows.filter((r) => r.status === 'archived').length,
    total: rows.length,
  };
}

/** B05: the 16 ranges, with the item behind each state (to jump to it) and the gaps. */
function coverageOf(rows: Row[]) {
  const items = rows
    .map((r) => ({ ...r, age: (r as Row & { age?: StageAge }).age }))
    .filter((r) => r.kind === 'stage' && r.age)
    .map((r) => ({ age: r.age!, status: r.status, live: !!r.live, id: r.id }));
  const c = stageCoverage(items);
  return {
    ...c,
    buckets: c.buckets.map((b) => {
      const bucket = stageBuckets.find((x) => x.id === b.id)!;
      return {
        ...b,
        itemIds: items.filter((i) => stageCoversBucket(i.age, bucket)).map((i) => i.id),
      };
    }),
  };
}

const todayOf = (now: Date) => localDateIn(ZONE, now);

/**
 * B01 / B05 / B07 lists (one kind, with counts; stages also get the 0–24 month coverage) and the
 * B03 / B04 queue (every kind: waiting for review, approved, due for re-review).
 */
export async function contentList(
  db: Firestore,
  deps: Pick<ContentLibraryDeps, 'requireReview'>,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  requireStaff(staff, 'content.view');
  const requireReview = reviewRequired(deps.requireReview, await readContentPolicy(db));
  const { view } = parse(contentListRequestSchema, data);
  const today = todayOf(now);
  const snap =
    view === 'queue' ? await drafts(db).get() : await drafts(db).where('kind', '==', view).get();
  const rows = snap.docs
    .map((d) => rowOf(d, today))
    .sort((a, b) => (b.updatedAt ?? '').localeCompare(a.updatedAt ?? ''));
  if (view === 'queue') {
    const queue = rows.filter(
      (r) => r.status === 'in_review' || r.status === 'approved' || r.live?.dueForReview,
    );
    return {
      view,
      today,
      rows: queue,
      counts: Object.fromEntries(
        contentKinds.map((k) => [k, countsOf(rows.filter((r) => r.kind === k))]),
      ),
      totals: countsOf(rows),
      available: contentKinds,
      requireReview,
    };
  }
  return {
    view,
    today,
    rows,
    counts: countsOf(rows),
    ...(view === 'stage' ? { coverage: coverageOf(rows) } : {}),
    available: contentKinds,
    requireReview,
  };
}

/** One item for the editors: the draft, what is on the app, and the workflow fields. */
export async function contentItem(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  requireStaff(staff, 'content.view');
  const req = parse(contentItemRequestSchema, data);
  const snap = await drafts(db).doc(req.id).get();
  if (!snap.exists || snap.get('kind') !== req.kind) throw new StaffError('not-found', 'not-found');
  const pub = await publicRef(db, req.kind, req.id).get();
  return {
    row: rowOf(snap, todayOf(now)),
    data: snap.get('data') as Data,
    notes: (snap.get('notes') as string | undefined) ?? '',
    lastEditorUid: (snap.get('lastEditorUid') as string | undefined) ?? null,
    pendingReview: (snap.get('pendingReview') as EditorialReview | undefined) ?? null,
    published: pub.exists ? (pub.data() as Data) : null,
  };
}

/** Every image the item uses must already be uploaded. */
async function checkImages(deps: ContentLibraryDeps, kind: ContentKind, data: Data) {
  for (const id of contentImages(kind, data)) {
    if (!(await deps.images.exists(id)))
      throw new StaffError('failed-precondition', 'image-missing');
  }
}

function audit(
  tx: Transaction | FirebaseFirestore.WriteBatch,
  db: Firestore,
  s: Staff,
  kind: ContentKind | 'library',
  id: string,
  action: string,
  now: Date,
  reason: string | null = null,
  detail?: Data,
) {
  staffAudit(
    tx,
    db,
    s,
    {
      action: `content.${kind}.${action}`,
      category: 'content',
      target: kind === 'library' ? id : `${kind}:${id}`,
      reason,
      ...(detail ? { detail } : {}),
    },
    now,
  );
}

/** "Lưu nháp": creates the item or saves its draft (a version under review goes back to Nháp). */
export async function contentSave(
  db: Firestore,
  deps: ContentLibraryDeps,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const s = requireStaff(staff, 'content.edit');
  const req = parse(contentSaveRequestSchema, data);
  const adapter = adapterOf(req.kind);
  const checked = adapter.draft.safeParse(req.data);
  if (!checked.success) throw new StaffError('invalid-argument', 'malformed');
  const body = checked.data as Data;
  await checkImages(deps, req.kind, body);
  const id = req.id ?? adapter.newId();
  if (!adapter.isId(id)) throw new StaffError('invalid-argument', 'malformed');
  const ref = drafts(db).doc(id);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (req.id && !snap.exists) throw new StaffError('not-found', 'not-found');
    if (snap.exists && snap.get('kind') !== req.kind)
      throw new StaffError('not-found', 'not-found');
    const from = (snap.get('status') as EditorialStatus | undefined) ?? null;
    const editor = {
      data: body,
      reviewerLabel: req.reviewerLabel,
      notes: req.notes,
      // The reviewer must see what they approve: any edit goes back to Nháp.
      status: 'draft',
      approverUid: null,
      approverName: null,
      approvedAt: null,
      pendingReview: null,
      checks: [],
      lastEditorUid: s.uid,
      lastEditorName: s.name,
      updatedAt: now,
    };
    if (snap.exists) {
      tx.update(ref, editor);
    } else {
      tx.create(ref, {
        ...editor,
        kind: req.kind,
        createdAt: now,
        createdByUid: s.uid,
        createdByName: s.name,
        submittedAt: null,
        submittedByName: null,
        rejection: null,
        live: null,
      });
    }
    audit(tx, db, s, req.kind, id, 'save', now, null, { from });
    return { id, status: 'draft' as const };
  });
}

/** Links to items that do not exist (or were archived) cannot be submitted. */
async function checkLinks(db: Firestore, kind: ContentKind, id: string, data: Data) {
  const links = contentLinks(kind, data);
  if (links.articles.includes(id)) throw new StaffError('failed-precondition', 'link-missing');
  const ids = [...links.articles, ...links.milestones];
  if (!ids.length) return;
  const snaps = await db.getAll(...ids.map((x) => drafts(db).doc(x)));
  for (const [i, snap] of snaps.entries()) {
    const want: ContentKind = i < links.articles.length ? 'article' : 'milestone';
    // A milestone published by the milestones slice outside this workflow also counts.
    if (snap.exists && snap.get('kind') === want && snap.get('status') !== 'archived') continue;
    if (want === 'milestone' && (await publicRef(db, 'milestone', snap.id).get()).exists) continue;
    throw new StaffError('failed-precondition', 'link-missing');
  }
}

/**
 * Gửi duyệt · Duyệt · Trả lại · Xuất bản · Gỡ khỏi app · Lưu trữ / Huỷ bản nháp · Xác nhận lại.
 */
export async function contentAct(
  db: Firestore,
  deps: ContentLibraryDeps,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  if (!staff) throw new StaffError('permission-denied', 'not-staff');
  const req = parse(contentActRequestSchema, data);
  const policy = await readContentPolicy(db);
  const requireReview = reviewRequired(deps.requireReview, policy);
  const adapter = adapterOf(req.kind);
  const ref = drafts(db).doc(req.id);
  const first = await ref.get();
  if (!first.exists || first.get('kind') !== req.kind)
    throw new StaffError('not-found', 'not-found');
  const reason = req.reason.trim() || null;
  const today = todayOf(now);

  // Re-read in the transaction: the state may have moved since the portal loaded it.
  const within = async <T>(fn: (snap: DocumentSnapshot, tx: Transaction) => T | Promise<T>) =>
    db.runTransaction(async (tx) => fn(await tx.get(ref), tx));
  const statusOf = (snap: DocumentSnapshot) => snap.get('status') as EditorialStatus;
  const liveOf = (snap: DocumentSnapshot) => (snap.get('live') as Live | null | undefined) ?? null;

  switch (req.action) {
    case 'submit': {
      const s = requireStaff(staff, 'content.edit');
      const body = first.get('data') as Data;
      if (!adapter.strict.safeParse(body).success) {
        throw new StaffError('failed-precondition', 'invalid-content');
      }
      await checkImages(deps, req.kind, body);
      await checkLinks(db, req.kind, req.id, body);
      return within((snap, tx) => {
        if (statusOf(snap) !== 'draft') throw new StaffError('failed-precondition', 'not-draft');
        tx.update(ref, {
          status: 'in_review',
          submittedAt: now,
          submittedByName: s.name,
          rejection: null,
          updatedAt: now,
        });
        audit(tx, db, s, req.kind, req.id, 'submit', now);
        return { status: 'in_review' as const };
      });
    }
    case 'approve': {
      const s = requireStaff(staff, 'content.approve');
      const review = req.review ?? null;
      if (requireReview && !review) {
        throw new StaffError('failed-precondition', 'review-required');
      }
      return within((snap, tx) => {
        if (statusOf(snap) !== 'in_review') {
          throw new StaffError('failed-precondition', 'not-pending');
        }
        // Two people: whoever edited last cannot approve it (D-058, D-073 #2), unless the Owner
        // may approve their own (D-079).
        if (snap.get('lastEditorUid') === s.uid && !mayApproveOwn(s, policy)) {
          throw new StaffError('failed-precondition', 'same-person');
        }
        tx.update(ref, {
          status: 'approved',
          approverUid: s.uid,
          approverName: s.name,
          approvedAt: now,
          pendingReview: review,
          checks: req.checks ?? [],
          updatedAt: now,
        });
        audit(tx, db, s, req.kind, req.id, 'approve', now, reason, { reviewed: !!review });
        return { status: 'approved' as const };
      });
    }
    case 'reject': {
      const s = requireStaff(staff, 'content.approve');
      return within((snap, tx) => {
        const st = statusOf(snap);
        if (st !== 'in_review' && st !== 'approved') {
          throw new StaffError('failed-precondition', 'not-pending');
        }
        tx.update(ref, {
          status: 'draft',
          rejection: { by: s.name, reason: req.reason.trim() },
          approverUid: null,
          approverName: null,
          approvedAt: null,
          pendingReview: null,
          checks: [],
          updatedAt: now,
        });
        audit(tx, db, s, req.kind, req.id, 'reject', now, reason);
        return { status: 'draft' as const };
      });
    }
    case 'publish': {
      const s = requireStaff(staff, 'content.approve');
      return within(async (snap, tx) => {
        if (statusOf(snap) !== 'approved') {
          throw new StaffError('failed-precondition', 'not-approved');
        }
        const pubRef = publicRef(db, req.kind, req.id);
        await tx.get(pubRef);
        const review = (snap.get('pendingReview') as EditorialReview | undefined) ?? null;
        if (requireReview && !review) {
          throw new StaffError('failed-precondition', 'review-required');
        }
        const live = liveOf(snap);
        const nowIso = now.toISOString();
        const meta: PublishedMeta = {
          status: 'published',
          revision: (live?.revision ?? 0) + 1,
          review,
          illustrative: review === null,
          reviewDueOn: reviewDueFrom(review?.reviewedOn ?? today),
          publishedAt: nowIso,
          firstPublishedAt: live?.firstPublishedAt ?? nowIso,
        };
        let doc: Data;
        try {
          doc = adapter.published(req.id, snap.get('data') as Data, meta);
        } catch {
          throw new StaffError('failed-precondition', 'invalid-content');
        }
        tx.set(pubRef, doc);
        const nextLive: Live = {
          revision: meta.revision,
          publishedAt: meta.publishedAt,
          firstPublishedAt: meta.firstPublishedAt,
          reviewDueOn: meta.reviewDueOn,
          review: meta.review,
          illustrative: meta.illustrative,
          publishedByName: s.name,
        };
        tx.update(ref, { status: 'published', live: nextLive, updatedAt: now });
        audit(tx, db, s, req.kind, req.id, 'publish', now, reason, {
          revision: meta.revision,
          illustrative: meta.illustrative,
        });
        return { status: 'published' as const, revision: meta.revision };
      });
    }
    case 'unpublish': {
      const s = requireStaff(staff, 'content.approve');
      return within((snap, tx) => {
        if (!liveOf(snap)) throw new StaffError('failed-precondition', 'not-live');
        tx.delete(publicRef(db, req.kind, req.id));
        const next: EditorialStatus = statusOf(snap) === 'published' ? 'archived' : statusOf(snap);
        tx.update(ref, { status: next, live: null, updatedAt: now });
        audit(tx, db, s, req.kind, req.id, 'unpublish', now, reason);
        return { status: next };
      });
    }
    case 'archive': {
      const s = requireStaff(staff, 'content.edit');
      const pub = await publicRef(db, req.kind, req.id).get();
      return within((snap, tx) => {
        const st = statusOf(snap);
        if (st === 'published' || st === 'archived') {
          throw new StaffError('failed-precondition', 'not-draft');
        }
        const live = liveOf(snap);
        if (live) {
          // "Huỷ bản nháp": the edit is dropped, the published revision stays as it is.
          if (!pub.exists) throw new StaffError('failed-precondition', 'not-live');
          const published = pub.data() as Data;
          const keep = adapter.draft.safeParse(stripMeta(published));
          if (!keep.success) throw new StaffError('failed-precondition', 'invalid-content');
          tx.update(ref, {
            status: 'published',
            data: keep.data as Data,
            approverUid: null,
            approverName: null,
            approvedAt: null,
            pendingReview: null,
            checks: [],
            rejection: null,
            updatedAt: now,
          });
          audit(tx, db, s, req.kind, req.id, 'revert', now, reason);
          return { status: 'published' as const };
        }
        tx.update(ref, { status: 'archived', updatedAt: now });
        audit(tx, db, s, req.kind, req.id, 'archive', now, reason);
        return { status: 'archived' as const };
      });
    }
    case 'reconfirm': {
      const s = requireStaff(staff, 'content.approve');
      const review = req.review ?? null;
      if (requireReview && !review) {
        throw new StaffError('failed-precondition', 'review-required');
      }
      return within(async (snap, tx) => {
        const live = liveOf(snap);
        if (!live) throw new StaffError('failed-precondition', 'not-live');
        if (snap.get('lastEditorUid') === s.uid && !mayApproveOwn(s, policy)) {
          throw new StaffError('failed-precondition', 'same-person');
        }
        const pubRef = publicRef(db, req.kind, req.id);
        const pub = await tx.get(pubRef);
        if (!pub.exists) throw new StaffError('failed-precondition', 'not-live');
        const kept = review ?? live.review;
        const meta: PublishedMeta = {
          status: 'published',
          revision: live.revision + 1,
          review: kept,
          illustrative: kept === null,
          reviewDueOn: reviewDueFrom(review?.reviewedOn ?? today),
          publishedAt: now.toISOString(),
          firstPublishedAt: live.firstPublishedAt,
        };
        let doc: Data;
        try {
          doc = adapter.published(req.id, stripMeta(pub.data() as Data), meta);
        } catch {
          throw new StaffError('failed-precondition', 'invalid-content');
        }
        tx.set(pubRef, doc);
        tx.update(ref, {
          live: { ...live, ...pickLive(meta), publishedByName: s.name },
          updatedAt: now,
        });
        audit(tx, db, s, req.kind, req.id, 'reconfirm', now, reason, { reviewed: !!review });
        return { status: statusOf(snap), revision: meta.revision };
      });
    }
  }
}

const metaKeys = [
  'id',
  'status',
  'revision',
  'review',
  'illustrative',
  'reviewDueOn',
  'publishedAt',
  'firstPublishedAt',
];
function stripMeta(doc: Data): Data {
  return Object.fromEntries(Object.entries(doc).filter(([k]) => !metaKeys.includes(k)));
}
function pickLive(meta: PublishedMeta) {
  return {
    revision: meta.revision,
    publishedAt: meta.publishedAt,
    reviewDueOn: meta.reviewDueOn,
    review: meta.review,
    illustrative: meta.illustrative,
  };
}

/**
 * Imports the engineering drafts (D-073 #2) as Nháp; an id that exists is left alone. The
 * importer is recorded as the last editor, so someone else approves them.
 */
export async function contentSeed(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const s = requireStaff(staff, 'content.edit');
  const { kinds, milestoneSeed } = parse(contentSeedRequestSchema, data);
  const items: Array<{ kind: ContentKind; id: string; reviewerLabel: string | null; data: Data }> =
    [];
  for (const kind of kinds) {
    const seed = adapterOf(kind).seed(kind === 'milestone' ? milestoneSeed : undefined);
    if (!seed) throw new StaffError('invalid-argument', 'invalid-content');
    for (const item of seed) items.push({ kind, ...item });
  }
  const refs: DocumentReference[] = items.map((i) => drafts(db).doc(i.id));
  const existing = items.length ? await db.getAll(...refs) : [];
  const added: Record<string, number> = {};
  // Firestore batches hold 500 writes; one audit entry per batch.
  const fresh = items.filter((_, i) => !existing[i]?.exists);
  const skipped = items.length - fresh.length;
  for (let i = 0; i < fresh.length; i += 400) {
    const batch = db.batch();
    for (const item of fresh.slice(i, i + 400)) {
      const adapter = adapterOf(item.kind);
      if (!adapter.draft.safeParse(item.data).success) {
        throw new StaffError('failed-precondition', 'invalid-content');
      }
      batch.create(drafts(db).doc(item.id), {
        kind: item.kind,
        data: item.data,
        status: 'draft',
        reviewerLabel: item.reviewerLabel,
        notes: 'Bản nháp mẫu · chờ chuyên môn duyệt',
        createdAt: now,
        createdByUid: s.uid,
        createdByName: s.name,
        lastEditorUid: s.uid,
        lastEditorName: s.name,
        updatedAt: now,
        submittedAt: null,
        submittedByName: null,
        approverUid: null,
        approverName: null,
        approvedAt: null,
        pendingReview: null,
        checks: [],
        rejection: null,
        live: null,
      });
      added[item.kind] = (added[item.kind] ?? 0) + 1;
    }
    audit(batch, db, s, 'library', 'seed', 'seed', now, null, { added, skipped });
    await batch.commit();
  }
  if (!fresh.length) {
    const batch = db.batch();
    audit(batch, db, s, 'library', 'seed', 'seed', now, null, { added, skipped });
    await batch.commit();
  }
  return { added, skipped };
}

export interface ContentImportItem {
  kind: ContentKind;
  id: string;
  reviewerLabel: string | null;
  data: Data;
}
export type ContentImportOutcome = 'added' | 'updated' | 'same' | 'busy';

const stable = (v: unknown): string =>
  Array.isArray(v)
    ? `[${v.map(stable).join(',')}]`
    : v && typeof v === 'object'
      ? `{${Object.keys(v)
          .sort()
          .map((k) => `${JSON.stringify(k)}:${stable((v as Data)[k])}`)
          .join(',')}}`
      : JSON.stringify(v);

/**
 * Content bundle import (`scripts/content-release.ts`): items from another project keep their ids
 * (links between articles, stages and milestones stay valid) and land as Nháp, never published.
 * A new id is created; changed text becomes the item's draft (the published revision stays on the
 * app); an item waiting for review or approved is left alone ("busy"). The importer is the last
 * editor, so someone else approves (D-058) and prod still needs the qualified review.
 */
export async function contentImport(
  db: Firestore,
  deps: ContentLibraryDeps,
  staff: Staff | null,
  items: ContentImportItem[],
  now: Date,
  opts: { notes: string; dryRun: boolean },
) {
  const s = requireStaff(staff, 'content.edit');
  for (const item of items) {
    const adapter = adapterOf(item.kind);
    if (!adapter.isId(item.id) || !adapter.draft.safeParse(item.data).success) {
      throw new StaffError('invalid-argument', `invalid-content:${item.kind}:${item.id}`);
    }
    if (!opts.dryRun) await checkImages(deps, item.kind, item.data);
  }
  const out: Array<{ kind: ContentKind; id: string; outcome: ContentImportOutcome }> = [];
  for (const item of items) {
    const ref = drafts(db).doc(item.id);
    const outcome = await db.runTransaction(async (tx): Promise<ContentImportOutcome> => {
      const snap = await tx.get(ref);
      if (snap.exists && snap.get('kind') !== item.kind) {
        throw new StaffError('failed-precondition', `kind-mismatch:${item.id}`);
      }
      if (snap.exists && stable(snap.get('data')) === stable(item.data)) return 'same';
      const status = (snap.get('status') as EditorialStatus | undefined) ?? null;
      if (status === 'in_review' || status === 'approved') return 'busy';
      if (opts.dryRun) return snap.exists ? 'updated' : 'added';
      const editor = {
        data: item.data,
        reviewerLabel: item.reviewerLabel,
        notes: opts.notes,
        status: 'draft',
        approverUid: null,
        approverName: null,
        approvedAt: null,
        pendingReview: null,
        checks: [],
        lastEditorUid: s.uid,
        lastEditorName: s.name,
        updatedAt: now,
      };
      if (snap.exists) {
        tx.update(ref, editor);
      } else {
        tx.create(ref, {
          ...editor,
          kind: item.kind,
          createdAt: now,
          createdByUid: s.uid,
          createdByName: s.name,
          submittedAt: null,
          submittedByName: null,
          rejection: null,
          live: null,
        });
      }
      audit(tx, db, s, item.kind, item.id, 'import', now, null, { from: status });
      return snap.exists ? 'updated' : 'added';
    });
    out.push({ kind: item.kind, id: item.id, outcome });
  }
  return out;
}

/** A picture for articles and stages (stored once; the same bytes give the same id). */
export async function contentUploadImage(
  db: Firestore,
  deps: ContentLibraryDeps,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const s = requireStaff(staff, 'content.edit');
  const req = parse(contentImageUploadSchema, data);
  let webp: Buffer;
  try {
    webp = await deps.images.encode(Buffer.from(req.data, 'base64'), false);
  } catch {
    throw new StaffError('invalid-argument', 'image-unreadable');
  }
  const id = `${req.name}_${createHash('sha256').update(webp).digest('hex').slice(0, 8)}`;
  if (!(await deps.images.exists(id))) await deps.images.save(id, webp);
  const batch = db.batch();
  audit(batch, db, s, 'library', id, 'image', now);
  await batch.commit();
  return { id, url: deps.images.publicUrl(id) };
}

/** The uploaded pictures (for the editors' picker). */
export async function contentImagesList(deps: ContentLibraryDeps, staff: Staff | null) {
  requireStaff(staff, 'content.view');
  const ids = await deps.images.list();
  return { images: ids.map((id) => ({ id, url: deps.images.publicUrl(id) })) };
}
