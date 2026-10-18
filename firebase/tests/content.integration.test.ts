import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  firstAidAct,
  firstAidDraft,
  firstAidUploadImage,
  firstAidView,
  type ContentDeps,
} from '../functions/src/content.js';
import type { Staff } from '../functions/src/staff.js';

// Sơ cứu on the portal (D-058, P-141) against the Firestore emulator, with an in-memory picture
// store: draft → submit → a different person approves → publicConfig/content_firstAid.
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const now = new Date('2026-10-12T03:00:00Z');
const ops: Staff = { uid: 'u_ops', name: 'Hà Vũ', roles: ['ops'] };
const expert: Staff = { uid: 'u_expert', name: 'BS. Lan', roles: ['expert'] };
const support: Staff = { uid: 'u_support', name: 'Mai', roles: ['support'] };

// The real seed, every slug standing in for a stored picture id.
const seed = JSON.parse(readFileSync('../../content/first-aid/pack.seed.json', 'utf8'));
const id = (slug: string | null) => (slug == null ? null : `${slug}_00000000`);
const pack = {
  ...seed,
  situations: seed.situations.map((s: Record<string, unknown>) => ({
    ...s,
    icon: id(s.icon as string),
    hero: id(s.hero as string),
    variants: (s.variants as Array<Record<string, unknown>>).map((v) => ({
      ...v,
      hero: id(v.hero as string | null),
      steps: (v.steps as Array<Record<string, unknown>>).map((st) => ({
        ...st,
        image: id(st.image as string | null),
      })),
    })),
  })),
  cpr: seed.cpr.map((c: Record<string, unknown>) => ({
    ...c,
    image: id(c.image as string | null),
  })),
};

const stored = new Set<string>();
const deps = (requireReview = false): ContentDeps => ({
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
const all = (p: typeof pack) => {
  for (const s of p.situations) {
    stored.add(s.icon);
    stored.add(s.hero);
    for (const v of s.variants) {
      if (v.hero) stored.add(v.hero);
      for (const st of v.steps) if (st.image) stored.add(st.image);
    }
  }
  for (const c of p.cpr) if (c.image) stored.add(c.image);
};

beforeAll(() => {
  app = initializeApp({ projectId }, `content-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  stored.clear();
  await db.recursiveDelete(db.doc('content/firstAid'));
  await db.doc('publicConfig/content_firstAid').delete();
  await db.recursiveDelete(db.collection('staffAudit'));
});

describe('Sơ cứu on the portal', () => {
  it('a draft needs its pictures; two people publish it', async () => {
    expect(await reason(firstAidDraft(db, deps(), ops, { pack, notes: '' }, now))).toBe(
      'image-missing',
    );
    all(pack);
    expect(await reason(firstAidDraft(db, deps(), support, { pack, notes: '' }, now))).toBe('role');
    const { versionId } = await firstAidDraft(db, deps(), ops, { pack, notes: 'Bản đầu' }, now);
    await firstAidAct(
      db,
      deps(),
      ops,
      { versionId, action: 'submit', reason: 'Xin duyệt', review: null },
      now,
    );
    // The author cannot approve their own version, even with the right.
    const opsAdmin: Staff = { ...ops, roles: ['admin'] };
    expect(
      await reason(
        firstAidAct(
          db,
          deps(),
          opsAdmin,
          { versionId, action: 'approve', reason: 'Đồng ý', review: null },
          now,
        ),
      ),
    ).toBe('same-person');
    const out = await firstAidAct(
      db,
      deps(),
      expert,
      { versionId, action: 'approve', reason: 'Đã rà soát', review: null },
      now,
    );
    expect(out).toEqual({ status: 'published', version: 'fa_20261012_01' });
    const pub = await db.doc('publicConfig/content_firstAid').get();
    expect(pub.get('version')).toBe('fa_20261012_01');
    // The reviewed pack (2026-10-16): 25 corrected situations and 10 new ones.
    expect(pub.get('pack.situations')).toHaveLength(35);
    const view = await firstAidView(db, deps(), support);
    expect(view.current?.version).toBe('fa_20261012_01');
    expect(view.draft).toBeNull();
    expect(view.history[0]).toMatchObject({ status: 'published', approverName: 'BS. Lan' });
    const audit = await db.collection('staffAudit').get();
    expect(audit.docs.map((d) => d.get('action')).sort()).toEqual([
      'content.firstAid.approve',
      'content.firstAid.draft',
      'content.firstAid.submit',
    ]);
  });

  it('prod: approving records the medical review, shown with the pack', async () => {
    all(pack);
    const { versionId } = await firstAidDraft(db, deps(true), ops, { pack, notes: '' }, now);
    await firstAidAct(
      db,
      deps(true),
      ops,
      { versionId, action: 'submit', reason: 'Xin duyệt', review: null },
      now,
    );
    expect(
      await reason(
        firstAidAct(
          db,
          deps(true),
          expert,
          { versionId, action: 'approve', reason: 'Đồng ý', review: null },
          now,
        ),
      ),
    ).toBe('review-required');
    await firstAidAct(
      db,
      deps(true),
      expert,
      {
        versionId,
        action: 'approve',
        reason: 'Đã rà soát',
        review: { reviewer: 'BS. Lan, Nhi khoa', reviewedOn: '2026-10-12', sources: ['AHA 2020'] },
      },
      now,
    );
    expect((await db.doc('publicConfig/content_firstAid').get()).get('pack.review.reviewer')).toBe(
      'BS. Lan, Nhi khoa',
    );
  });

  it('returned with a reason; editing under review withdraws it; rollback re-publishes', async () => {
    all(pack);
    const { versionId } = await firstAidDraft(db, deps(), ops, { pack, notes: '' }, now);
    await firstAidAct(
      db,
      deps(),
      ops,
      { versionId, action: 'submit', reason: 'Xin', review: null },
      now,
    );
    await firstAidAct(
      db,
      deps(),
      expert,
      { versionId, action: 'reject', reason: 'Sửa bước 2', review: null },
      now,
    );
    const back = (await firstAidView(db, deps(), ops)).draft!;
    expect(back.status).toBe('draft');
    expect(back.rejection).toEqual({ by: 'BS. Lan', reason: 'Sửa bước 2' });
    await firstAidAct(
      db,
      deps(),
      ops,
      { versionId, action: 'submit', reason: 'Xin', review: null },
      now,
    );
    await firstAidAct(
      db,
      deps(),
      expert,
      { versionId, action: 'approve', reason: 'Đồng ý', review: null },
      now,
    );
    // A second version, then going back to the first.
    const later = new Date(now.getTime() + 60_000);
    const v2 = await firstAidDraft(db, deps(), ops, { pack, notes: 'v2' }, later);
    await firstAidAct(
      db,
      deps(),
      ops,
      { versionId: v2.versionId, action: 'submit', reason: 'Xin', review: null },
      later,
    );
    await firstAidAct(
      db,
      deps(),
      expert,
      { versionId: v2.versionId, action: 'approve', reason: 'Đồng ý', review: null },
      later,
    );
    expect((await db.doc('publicConfig/content_firstAid').get()).get('version')).toBe(
      'fa_20261012_02',
    );
    const out = await firstAidAct(
      db,
      deps(),
      expert,
      { versionId, action: 'rollback', reason: 'Quay lại bản trước', review: null },
      later,
    );
    expect(out.version).toBe('fa_20261012_03');
  });

  it('pictures: same bytes, same id; only editors upload', async () => {
    const data = Buffer.from('fake-webp').toString('base64');
    expect(
      await reason(firstAidUploadImage(db, deps(), support, { name: 'vo-lung', data }, now)),
    ).toBe('role');
    const a = await firstAidUploadImage(db, deps(), ops, { name: 'vo-lung', data }, now);
    const b = await firstAidUploadImage(db, deps(), ops, { name: 'vo-lung', data }, now);
    expect(a.id).toMatch(/^vo-lung_[a-f0-9]{8}$/);
    expect(b.id).toBe(a.id);
    expect(stored.has(a.id)).toBe(true);
  });
});
