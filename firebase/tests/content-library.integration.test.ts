import { readFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import {
  contentArticleSchema,
  contentStageSchema,
  editorialChecks,
  referenceMilestoneSchema,
  type ArticleContent,
} from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  contentAct,
  contentItem,
  contentList,
  contentSave,
  contentSeed,
  contentUploadImage,
  type ContentLibraryDeps,
} from '../functions/src/content-library.js';
import { seedArticles, seedStages } from '../functions/src/content-seed.js';
import type { Staff } from '../functions/src/staff.js';

// Editorial content (D-076 #5–#7, B01–B08) against the Firestore emulator: roles, the engineering
// seed, two-person approval, publish / edit-after-publish / unpublish, the 12-month re-review,
// coverage and the audit log. Its own project; an in-memory picture store.
const projectId = 'demo-child-life-content-library';
let app: App;
let db: Firestore;
const now = new Date('2026-10-15T03:00:00Z');
const later = new Date('2027-11-01T03:00:00Z');

const ops: Staff = { uid: 's_ops', name: 'Hà Vũ', roles: ['ops'] };
const ops2: Staff = { uid: 's_ops2', name: 'Minh', roles: ['ops'] };
const expert: Staff = { uid: 's_expert', name: 'BS. Lan', roles: ['expert'] };
const support: Staff = { uid: 's_support', name: 'Mai', roles: ['support'] };
const eng: Staff = { uid: 's_eng', name: 'Kỹ sư', roles: ['eng'] };
const admin: Staff = { uid: 's_admin', name: 'Linh', roles: ['admin'] };

const stored = new Set<string>();
const deps = (requireReview = false): ContentLibraryDeps => ({
  requireReview,
  images: {
    exists: async (i) => stored.has(i),
    save: async (i) => void stored.add(i),
    list: async () => [...stored],
    publicUrl: (i) => `https://img.test/${i}`,
    encode: async (bytes) => Buffer.from(bytes),
  },
});
const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason,
  );
const checks = [...editorialChecks];
const review = { reviewer: 'BS. Thu Hà', credential: 'Nhi khoa', reviewedOn: '2026-10-10' };

// A seed article on its own (its related articles are not imported in these tests).
const article = (): ArticleContent => ({
  ...structuredClone(seedArticles[0]!.data),
  relatedArticleIds: [],
});

async function newArticle(by: Staff = ops, data: unknown = article()) {
  const r = await contentSave(
    db,
    deps(),
    by,
    { kind: 'article', id: null, data, reviewerLabel: 'Nhi khoa', notes: '' },
    now,
  );
  return r.id;
}
const act = (
  by: Staff,
  id: string,
  action: string,
  extra: Record<string, unknown> = {},
  kind = 'article',
  d = deps(),
  at = now,
) => contentAct(db, d, by, { kind, id, action, reason: '', ...extra }, at);

async function publishArticle(id: string, withReview = false) {
  await act(ops, id, 'submit');
  await act(expert, id, 'approve', { checks, ...(withReview ? { review } : {}) });
  return act(expert, id, 'publish');
}

beforeAll(() => {
  app = initializeApp({ projectId }, `content-library-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  stored.clear();
  for (const c of ['contentDrafts', 'contentArticles', 'contentStages', 'contentMilestones']) {
    await db.recursiveDelete(db.collection(c));
  }
  await db.recursiveDelete(db.collection('staffAudit'));
});

describe('roles', () => {
  it('needs Nội dung · Xem to list, · Sửa to save, · Duyệt to approve and publish', async () => {
    expect(await reason(contentList(db, deps(), eng, { view: 'article' }, now))).toBe('role');
    expect(await reason(contentList(db, deps(), null, { view: 'article' }, now))).toBe('not-staff');
    expect(await reason(contentList(db, deps(), support, { view: 'article' }, now))).toBe('ok');
    expect(await reason(newArticle(support))).toBe('role');
    const id = await newArticle();
    await act(ops, id, 'submit');
    expect(await reason(act(ops2, id, 'approve', { checks }))).toBe('role');
    expect(await reason(act(support, id, 'reject', { reason: 'Sai nguồn' }))).toBe('role');
  });

  it('refuses malformed and marked-up input', async () => {
    const bad = article();
    bad.body.vi[0] = { type: 'paragraph', text: '<script>alert(1)</script>' };
    expect(await reason(newArticle(ops, bad))).toBe('malformed');
    expect(
      await reason(
        contentSave(
          db,
          deps(),
          ops,
          { kind: 'article', id: 'stg_x1', data: article(), reviewerLabel: null, notes: '' },
          now,
        ),
      ),
    ).toBe('malformed');
  });
});

describe('two-person workflow', () => {
  it('draft → in review → approved by someone else → published for the app', async () => {
    const id = await newArticle();
    expect(await reason(act(ops, id, 'publish'))).toBe('role');
    expect(await reason(act(expert, id, 'publish'))).toBe('not-approved');
    expect(await reason(act(expert, id, 'approve', { checks }))).toBe('not-pending');
    await act(ops, id, 'submit');
    expect(await reason(act(ops, id, 'submit'))).toBe('not-draft');
    // Admin edited nothing but approves; ops (the editor) cannot even with the role.
    const adminOps: Staff = { ...admin, uid: ops.uid };
    expect(await reason(act(adminOps, id, 'approve', { checks }))).toBe('same-person');
    // Every checklist line is required.
    expect(await reason(act(expert, id, 'approve', { checks: checks.slice(1) }))).toBe('malformed');
    await act(expert, id, 'approve', { checks });
    // Not on the app before publishing.
    expect((await db.doc(`contentArticles/${id}`).get()).exists).toBe(false);
    const r = await act(expert, id, 'publish');
    expect(r).toEqual({ status: 'published', revision: 1 });
    const pub = contentArticleSchema.parse((await db.doc(`contentArticles/${id}`).get()).data());
    expect(pub).toMatchObject({
      id,
      status: 'published',
      revision: 1,
      review: null,
      illustrative: true,
      reviewDueOn: '2027-10-15',
      publishedAt: now.toISOString(),
      firstPublishedAt: now.toISOString(),
    });
    const draft = await db.doc(`contentDrafts/${id}`).get();
    expect(draft.get('status')).toBe('published');
    expect(draft.get('live').revision).toBe(1);
  });

  it('a recorded review publishes without the illustrative label, due 12 months after it', async () => {
    const id = await newArticle();
    await publishArticle(id, true);
    const pub = (await db.doc(`contentArticles/${id}`).get()).data()!;
    expect(pub.illustrative).toBe(false);
    expect(pub.review).toEqual(review);
    expect(pub.reviewDueOn).toBe('2027-10-10');
  });

  it('on prod the qualified review is required', async () => {
    const id = await newArticle();
    await act(ops, id, 'submit');
    expect(await reason(act(expert, id, 'approve', { checks }, 'article', deps(true)))).toBe(
      'review-required',
    );
    await act(expert, id, 'approve', { checks, review }, 'article', deps(true));
    expect(await reason(act(expert, id, 'publish', {}, 'article', deps(true)))).toBe('ok');
  });

  it('returns with a reason, and incomplete or broken content cannot be submitted', async () => {
    const id = await newArticle();
    await act(ops, id, 'submit');
    expect(await reason(act(expert, id, 'reject'))).toBe('malformed');
    await act(expert, id, 'reject', { reason: 'Thiếu nguồn cho phần sốt' });
    const draft = await db.doc(`contentDrafts/${id}`).get();
    expect(draft.get('status')).toBe('draft');
    expect(draft.get('rejection')).toEqual({ by: 'BS. Lan', reason: 'Thiếu nguồn cho phần sốt' });

    const half = article();
    half.title.en = '';
    const halfId = await newArticle(ops, half);
    expect(await reason(act(ops, halfId, 'submit'))).toBe('invalid-content');

    const linked = article();
    linked.relatedArticleIds = ['art_missing_one'];
    const linkedId = await newArticle(ops, linked);
    expect(await reason(act(ops, linkedId, 'submit'))).toBe('link-missing');

    const pictured = article();
    pictured.cover = { image: 'cover-sleep_0a1b2c3d', alt: { vi: 'Bé ngủ', en: 'Asleep' } };
    expect(await reason(newArticle(ops, pictured))).toBe('image-missing');
    stored.add('cover-sleep_0a1b2c3d');
    expect(await reason(newArticle(ops, pictured))).toBe('ok');
  });

  it('editing a published item keeps the app copy until the new revision is published', async () => {
    const id = await newArticle();
    await publishArticle(id);
    const edited = article();
    edited.title.vi = 'Giấc ngủ của bé sơ sinh (cập nhật)';
    await contentSave(
      db,
      deps(),
      ops2,
      { kind: 'article', id, data: edited, reviewerLabel: null, notes: '' },
      now,
    );
    const item = await contentItem(db, expert, { kind: 'article', id }, now);
    expect(item.row.status).toBe('draft');
    expect(item.row.live?.revision).toBe(1);
    expect((await db.doc(`contentArticles/${id}`).get()).get('title.vi')).toBe(
      seedArticles[0]!.data.title.vi,
    );
    // "Huỷ bản nháp" goes back to the published text.
    await act(ops2, id, 'archive');
    const back = await db.doc(`contentDrafts/${id}`).get();
    expect(back.get('status')).toBe('published');
    expect(back.get('data.title.vi')).toBe(seedArticles[0]!.data.title.vi);
    // The edit again, through the workflow: revision 2, first publish kept.
    await contentSave(
      db,
      deps(),
      ops2,
      { kind: 'article', id, data: edited, reviewerLabel: null, notes: '' },
      now,
    );
    await act(ops2, id, 'submit');
    expect(await reason(act({ ...expert, uid: ops2.uid }, id, 'approve', { checks }))).toBe(
      'same-person',
    );
    await act(expert, id, 'approve', { checks });
    await act(expert, id, 'publish', {}, 'article', deps(), later);
    const pub = (await db.doc(`contentArticles/${id}`).get()).data()!;
    expect(pub.revision).toBe(2);
    expect(pub.title.vi).toBe('Giấc ngủ của bé sơ sinh (cập nhật)');
    expect(pub.firstPublishedAt).toBe(now.toISOString());
    expect(pub.publishedAt).toBe(later.toISOString());
  });

  it('unpublishing removes it from the app with a reason; never-published drafts are archived', async () => {
    const id = await newArticle();
    await publishArticle(id);
    expect(await reason(act(expert, id, 'unpublish'))).toBe('malformed');
    expect(await reason(act(ops, id, 'unpublish', { reason: 'Đang sửa lớn' }))).toBe('role');
    await act(expert, id, 'unpublish', { reason: 'Đang sửa lớn' });
    expect((await db.doc(`contentArticles/${id}`).get()).exists).toBe(false);
    expect((await db.doc(`contentDrafts/${id}`).get()).get('status')).toBe('archived');
    expect(await reason(act(expert, id, 'unpublish', { reason: 'Lần nữa' }))).toBe('not-live');

    const other = await newArticle();
    await act(ops, other, 'archive');
    expect((await db.doc(`contentDrafts/${other}`).get()).get('status')).toBe('archived');
  });

  it('after 12 months it is due for re-review; a reviewer confirms it again', async () => {
    const id = await newArticle();
    await publishArticle(id);
    const queue = (await contentList(db, deps(), expert, { view: 'queue' }, later)) as {
      rows: Array<{ id: string; displayStatus: string; live: { dueForReview: boolean } }>;
      totals: { dueForReview: number };
    };
    expect(queue.rows.find((r) => r.id === id)).toMatchObject({
      displayStatus: 'needs_rereview',
      live: { dueForReview: true },
    });
    expect(queue.totals.dueForReview).toBe(1);
    expect(
      await reason(act({ ...expert, uid: ops.uid }, id, 'reconfirm', {}, 'article', deps(), later)),
    ).toBe('same-person');
    await act(
      expert,
      id,
      'reconfirm',
      { review: { ...review, reviewedOn: '2027-10-30' } },
      'article',
      deps(),
      later,
    );
    const pub = (await db.doc(`contentArticles/${id}`).get()).data()!;
    expect(pub).toMatchObject({ revision: 2, illustrative: false, reviewDueOn: '2028-10-30' });
    const after = (await contentList(db, deps(), expert, { view: 'queue' }, later)) as {
      rows: unknown[];
    };
    expect(after.rows).toHaveLength(0);
  });
});

// The stage drafts link reference milestones, which must exist as drafts before a stage is
// submitted (`link-missing`), so these tests import the real milestone seed first.
const realMilestoneSeed: unknown = JSON.parse(
  readFileSync(new URL('../../content/milestones/milestones.seed.json', import.meta.url), 'utf8'),
);
const importMilestones = () =>
  contentSeed(db, ops, { kinds: ['milestone'], milestoneSeed: realMilestoneSeed }, now);

describe('seed, lists and coverage', () => {
  it('imports the engineering drafts once, as drafts the importer cannot approve', async () => {
    await importMilestones();
    const r = await contentSeed(db, ops, { kinds: ['article', 'stage'] }, now);
    expect(r).toEqual({
      added: { article: seedArticles.length, stage: seedStages.length },
      skipped: 0,
    });
    const again = await contentSeed(db, ops, { kinds: ['article', 'stage'] }, now);
    expect(again).toEqual({ added: {}, skipped: seedArticles.length + seedStages.length });

    const stages = (await contentList(db, deps(), support, { view: 'stage' }, now)) as {
      counts: { drafts: number; inApp: number };
      coverage: { covered: number; published: number; total: number; gaps: string[] };
    };
    expect(stages.counts).toMatchObject({ drafts: 16, inApp: 0 });
    expect(stages.coverage).toMatchObject({ covered: 16, published: 0, total: 16, gaps: [] });

    // Seed links resolve, so the drafts can go through review.
    const first = seedStages[1]!.id;
    await act(ops, first, 'submit', {}, 'stage');
    expect(await reason(act(ops, first, 'approve', { checks }, 'stage'))).toBe('role');
    const opsExpert: Staff = { ...expert, uid: ops.uid };
    expect(await reason(act(opsExpert, first, 'approve', { checks }, 'stage'))).toBe('same-person');
    await act(expert, first, 'approve', { checks }, 'stage');
    await act(expert, first, 'publish', {}, 'stage');
    contentStageSchema.parse((await db.doc(`contentStages/${first}`).get()).data());
    const after = (await contentList(db, deps(), support, { view: 'stage' }, now)) as {
      coverage: {
        published: number;
        buckets: Array<{ id: string; state: string; itemIds: string[] }>;
      };
    };
    expect(after.coverage.published).toBe(1);
    expect(after.coverage.buckets.find((b) => b.id === 'w3')).toMatchObject({
      state: 'published',
      itemIds: [first],
    });

    const articles = (await contentList(
      db,
      deps(),
      support,
      { view: 'article' },
      now,
    )) as unknown as {
      rows: Array<{ id: string; topic: string; ageWeeks: unknown; readingMinutes: number }>;
    };
    expect(articles.rows).toHaveLength(seedArticles.length);
    expect(articles.rows[0]).toHaveProperty('topic');
  });

  it('a stage gap shows until a range has content', async () => {
    const data = structuredClone(seedStages[0]!.data);
    await contentSave(
      db,
      deps(),
      ops,
      { kind: 'stage', id: null, data, reviewerLabel: null, notes: '' },
      now,
    );
    const list = (await contentList(db, deps(), ops, { view: 'stage' }, now)) as {
      coverage: { covered: number; gaps: string[] };
    };
    expect(list.coverage.covered).toBe(1);
    expect(list.coverage.gaps).toHaveLength(15);
    expect(list.coverage.gaps).not.toContain('w0');
  });

  it('the queue spans every kind and the counts split by kind', async () => {
    await importMilestones();
    await contentSeed(db, ops, { kinds: ['article', 'stage'] }, now);
    await act(ops, seedArticles[0]!.id, 'submit');
    await act(ops, seedStages[0]!.id, 'submit', {}, 'stage');
    const q = (await contentList(db, deps(), expert, { view: 'queue' }, now)) as {
      rows: Array<{ kind: string }>;
      counts: Record<string, { inReview: number }>;
    };
    expect(q.rows.map((r) => r.kind).sort()).toEqual(['article', 'stage']);
    expect(q.counts.article!.inReview).toBe(1);
    expect(q.counts.stage!.inReview).toBe(1);
  });
});

describe('reference milestones (milestones.ts schema)', () => {
  const milestoneSeed = {
    version: 'mst_20261015_01',
    note: 'Bản nháp kỹ thuật',
    milestones: [
      {
        id: 'smiles_back',
        group: 'socialEmotional',
        order: 10,
        ageRange: { unit: 'months', from: 1, to: 3 },
        title: { vi: 'Mỉm cười đáp lại', en: 'Smiles back' },
        howToRecognise: {
          vi: 'Bé cười khi nhìn thấy mặt bạn hoặc nghe bạn nói chuyện.',
          en: 'Baby smiles when they see your face or hear you talk.',
        },
        talkToDoctor: null,
        illustration: null,
        sources: [{ label: 'CDC', url: 'https://www.cdc.gov/act-early/milestones/index.html' }],
      },
    ],
  };

  it('imports from the seed file, goes through review and publishes contentMilestones', async () => {
    expect(
      await reason(contentSeed(db, ops, { kinds: ['milestone'], milestoneSeed: { bad: 1 } }, now)),
    ).toBe('invalid-content');
    const r = await contentSeed(db, ops, { kinds: ['milestone'], milestoneSeed }, now);
    expect(r.added).toEqual({ milestone: 1 });
    await act(ops, 'smiles_back', 'submit', {}, 'milestone');
    await act(expert, 'smiles_back', 'approve', { checks }, 'milestone');
    await act(expert, 'smiles_back', 'publish', {}, 'milestone');
    const pub = referenceMilestoneSchema.parse(
      (await db.doc('contentMilestones/smiles_back').get()).data(),
    );
    expect(pub).toMatchObject({ id: 'smiles_back', illustrative: true, revision: 1 });
    // A stage may now link it.
    const stage = structuredClone(seedStages[0]!.data);
    stage.articleIds = [];
    stage.milestoneIds = ['smiles_back'];
    const { id } = await contentSave(
      db,
      deps(),
      ops,
      { kind: 'stage', id: null, data: stage, reviewerLabel: null, notes: '' },
      now,
    );
    expect(await reason(act(ops, id, 'submit', {}, 'stage'))).toBe('ok');
  });
});

describe('pictures and audit', () => {
  it('uploads once per content and logs every step without content text', async () => {
    const a = await contentUploadImage(
      db,
      deps(),
      ops,
      { name: 'cover-sleep', data: Buffer.from('png').toString('base64') },
      now,
    );
    expect(a.id).toMatch(/^cover-sleep_[a-f0-9]{8}$/);
    expect(stored.has(a.id)).toBe(true);
    expect(
      await reason(contentUploadImage(db, deps(), support, { name: 'x-y', data: 'AA==' }, now)),
    ).toBe('role');

    const id = await newArticle();
    await publishArticle(id);
    const audit = await db.collection('staffAudit').get();
    const actions = audit.docs.map((d) => d.get('action') as string).sort();
    expect(actions).toEqual(
      [
        'content.article.approve',
        'content.article.publish',
        'content.article.save',
        'content.article.submit',
        'content.library.image',
      ].sort(),
    );
    const text = JSON.stringify(audit.docs.map((d) => d.data()));
    expect(text).not.toContain(seedArticles[0]!.data.title.vi);
    expect(audit.docs.every((d) => d.get('category') === 'content')).toBe(true);
  });
});
