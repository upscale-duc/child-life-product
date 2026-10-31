import { randomUUID } from 'node:crypto';
import { productRegistrySchema } from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  actSection,
  appliedState,
  changeSetDetail,
  productFeature,
  productFeatures,
  productOverview,
  productPlans,
  productSource,
  reviewChangeSet,
  saveSection,
  submitChangeSet,
} from '../functions/src/product-hub.js';
import { buildChangeSet, type RepoFile } from '../functions/src/product-hub-ingest.js';
import type { Staff } from '../functions/src/staff.js';

// Sản phẩm · Product Hub (D-155) against the Firestore emulator: submit → review → apply, the
// two-person rule, stale marking instead of overwriting approved text (Scenario D), coverage gaps
// (Scenario F), conflicts kept open (Scenario C). Its own project; synthetic documents only.
const projectId = 'demo-child-life-product-hub';
const now = new Date('2026-10-31T09:00:00Z');
const owner: Staff = { uid: 's_owner', name: 'Owner', roles: ['owner'] };
const admin: Staff = { uid: 's_admin', name: 'Admin', roles: ['admin'] };
const eng: Staff = { uid: 's_eng', name: 'Kỹ sư', roles: ['eng'] };
const analyst: Staff = { uid: 's_analyst', name: 'Phân tích', roles: ['analyst'] };
const support: Staff = { uid: 's_support', name: 'Hỗ trợ', roles: ['support'] };
let app: App;
let db: Firestore;

const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason ?? String(e),
  );

const registry = productRegistrySchema.parse({
  version: 1,
  features: [
    {
      id: 'care.feeding',
      name: { vi: 'Cho ăn', en: 'Feeding' },
      pillar: 'care',
      capabilities: ['module.basic'],
      platforms: ['ios', 'android'],
      lifecycle: 'built',
      implementation: 'implemented',
      verification: 'code_read',
      release: 'not_released',
      confidence: 'high',
      modules: ['apps/mobile/lib/features/care/**'],
      tests: ['apps/mobile/test/features/care_test.dart'],
      docs: ['docs/product/feeding.md'],
      decisions: ['D-001'],
    },
    {
      id: 'platform.lumi',
      name: { vi: 'Lumi', en: 'Lumi assistant' },
      pillar: 'platform',
      hubKey: 'assistant',
      platforms: ['ios', 'android'],
      lifecycle: 'built',
      implementation: 'implemented',
      verification: 'code_read',
      release: 'not_released',
      confidence: 'high',
      docs: ['docs/product/lumi.md'],
      dependsOn: ['care.feeding'],
    },
  ],
});

const md = (path: string, text: string, blobSha = `b_${path}`): RepoFile => ({ path, blobSha, text });
const files = (feeding = '# Cho ăn\n\n## Rules\n\nBottle = volume.\n') => [
  md('apps/mobile/lib/features/care/care_sheets.dart', '// D-001\n'),
  md('apps/mobile/test/features/care_test.dart', ''),
  md('docs/product/feeding.md', feeding, `b_${feeding.length}`),
  md('docs/product/lumi.md', '# Lumi\n\nLumi: Free for everyone.\n'),
  md(
    'docs/product/business-map.md',
    '## Owner decisions (2026-10-10)\n| ID | Decision | Resolves | x |\n| --- | --- | --- | --- |\n| **D-001** | **Pumping is not intake**. | — | — |\n',
  ),
];

async function submit(by: Staff, feeding?: string, revision = 'r1') {
  const draft = buildChangeSet({ revision, files: files(feeding), registry, now }, await appliedState(db));
  return submitChangeSet(db, by, { ...draft, dirty: false }, now);
}

beforeAll(() => {
  app = initializeApp({ projectId }, `product-hub-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  for (const c of [
    'productFeatures',
    'productSources',
    'productChunks',
    'productDecisions',
    'productConflicts',
    'productChangeSets',
    'staffAudit',
    'config',
  ]) {
    await db.recursiveDelete(db.collection(c));
  }
});

describe('access', () => {
  it('only staff with Sản phẩm reach it; submit needs Sửa, approve needs Duyệt', async () => {
    expect(await reason(productFeatures(db, null))).toBe('not-staff');
    expect(await reason(productFeatures(db, support))).toBe('role');
    expect(await reason(productFeatures(db, analyst))).toBe('ok');
    expect(await reason(submit(analyst))).toBe('role');
    const { id } = await submit(eng);
    expect(await reason(reviewChangeSet(db, eng, { id, decision: 'approve' }, now))).toBe('role');
  });

  it('nothing is visible until a change set is approved', async () => {
    await submit(eng);
    expect((await productFeatures(db, analyst)).features).toEqual([]);
    expect((await productOverview(db, analyst)).total).toBe(0);
  });
});

describe('review', () => {
  it('the submitter cannot approve their own set, except the Owner (D-155 #3)', async () => {
    const a = await submit(admin);
    expect(await reason(reviewChangeSet(db, admin, { id: a.id, decision: 'approve' }, now))).toBe('own-work');
    await reviewChangeSet(db, admin, { id: a.id, decision: 'reject', reason: '' }, now).catch((e) => e);
    await db.recursiveDelete(db.collection('productChangeSets'));
    const o = await submit(owner);
    expect(await reason(reviewChangeSet(db, owner, { id: o.id, decision: 'approve' }, now))).toBe('ok');
  });

  it('one pending set at a time; a reject leaves knowledge unchanged', async () => {
    const { id } = await submit(eng);
    expect(await reason(submit(eng))).toBe('pending-exists');
    await reviewChangeSet(db, admin, { id, decision: 'reject', reason: 'later' }, now);
    expect((await db.collection('productSources').get()).size).toBe(0);
    const audit = await db.collection('staffAudit').where('category', '==', 'product').get();
    expect(audit.docs.map((d) => d.get('action')).sort()).toEqual(['product.changeset.reject', 'product.sync.submit']);
  });

  it('approve applies sources, chunks, decisions, features and conflicts', async () => {
    const { id } = await submit(eng);
    const detail = await changeSetDetail(db, admin, { id });
    expect(detail.sources.map((s) => s.path)).toEqual([
      'docs/product/business-map.md',
      'docs/product/feeding.md',
      'docs/product/lumi.md',
    ]);
    expect(detail.conflicts.map((c) => c.topic)).toEqual(['tier']);
    expect(await reason(reviewChangeSet(db, admin, { id, decision: 'approve' }, now))).toBe('ok');
    expect(await reason(reviewChangeSet(db, owner, { id, decision: 'approve' }, now))).toBe('not-pending');

    const list = await productFeatures(db, analyst);
    expect(list.features.map((f) => f.id)).toEqual(['care.feeding', 'platform.lumi']);
    const lumi = list.features.find((f) => f.id === 'platform.lumi')!;
    expect(lumi.tier).toBe('premium');
    expect(lumi.conflicts).toBe(1);

    const feeding = await productFeature(db, analyst, { id: 'care.feeding' });
    expect(feeding.decisions).toEqual([{ id: 'D-001', kind: 'D', title: 'Pumping is not intake', date: '2026-10-10', status: 'approved' }]);
    expect(feeding.dependents).toEqual(['platform.lumi']);
    expect(feeding.sources.map((s) => s.path)).toEqual(['docs/product/feeding.md']);
    expect(feeding.canEdit).toBe(false);

    const src = await productSource(db, analyst, { id: feeding.sources[0]!.id });
    expect(src.chunks.map((c) => c.headingPath.join('>'))).toEqual(['Cho ăn>Rules']);
    expect(src.versions).toHaveLength(1);
  });
});

describe('sections, coverage and freshness', () => {
  async function seeded() {
    const { id } = await submit(eng);
    await reviewChangeSet(db, admin, { id, decision: 'approve' }, now);
  }

  it('shows the coverage gap until sections are approved (Scenario F)', async () => {
    await seeded();
    const before = await productFeature(db, analyst, { id: 'care.feeding' });
    expect(before.coverage.missing).toContain('rules');
    expect(before.coverage.score).toBe(30); // tier 10 + technical 10 + decisions 10

    await saveSection(db, eng, { feature: 'care.feeding', key: 'rules', body: { vi: 'Bình = thể tích.' }, sources: ['docs/product/feeding.md#rules'] }, now);
    const draft = await productFeature(db, analyst, { id: 'care.feeding' });
    expect(draft.coverage.unverified).toContain('rules');
    expect(await reason(actSection(db, eng, { feature: 'care.feeding', key: 'rules', action: 'approve' }, now))).toBe('role');
    await actSection(db, admin, { feature: 'care.feeding', key: 'rules', action: 'approve' }, now);
    const after = await productFeature(db, analyst, { id: 'care.feeding' });
    const rules = after.sections.find((s) => s.key === 'rules')!;
    expect(rules.approved).toMatchObject({ version: 1, approvedBy: 'Admin', by: 'Kỹ sư' });
    expect(after.coverage.score).toBe(46);
  });

  it('a changed source marks the approved section stale and never rewrites it (Scenario D)', async () => {
    await seeded();
    await saveSection(db, eng, { feature: 'care.feeding', key: 'rules', body: { vi: 'Bình = thể tích.' }, sources: ['docs/product/feeding.md#rules'] }, now);
    await actSection(db, admin, { feature: 'care.feeding', key: 'rules', action: 'approve' }, now);

    const { id } = await submit(eng, '# Cho ăn\n\n## Rules\n\nBottle = volume; breast = time.\n', 'r2');
    const detail = await changeSetDetail(db, admin, { id });
    expect(detail.sources).toHaveLength(1);
    expect(detail.sources[0]!.diff).toEqual([
      expect.objectContaining({ heading: 'Cho ăn › Rules', change: 'changed' }),
    ]);
    const result = await reviewChangeSet(db, admin, { id, decision: 'approve' }, now);
    expect(result).toEqual({ status: 'approved', staleSections: 1, indexed: true });

    const f = await productFeature(db, analyst, { id: 'care.feeding' });
    const rules = f.sections.find((s) => s.key === 'rules')!;
    expect(rules.approved!.body.vi).toBe('Bình = thể tích.');
    expect(rules.stale!.paths).toEqual(['docs/product/feeding.md']);
    expect(f.coverage.stale).toEqual(['rules']);
  });

  it('an AI draft says so and is approved like any other (D-155 #3)', async () => {
    await seeded();
    await saveSection(db, owner, { feature: 'care.feeding', key: 'summary', body: { vi: 'Ghi cữ ăn.' }, sources: ['D-001'] }, now, 'ai');
    const f = await productFeature(db, analyst, { id: 'care.feeding' });
    expect(f.sections.find((s) => s.key === 'summary')!.draft).toMatchObject({ origin: 'ai', by: 'Owner' });
    await actSection(db, owner, { feature: 'care.feeding', key: 'summary', action: 'approve' }, now);
    const after = await productFeature(db, analyst, { id: 'care.feeding' });
    expect(after.sections.find((s) => s.key === 'summary')!.approved).toMatchObject({ version: 1, approvedBy: 'Owner' });
  });

  it('the same revision again has nothing to submit', async () => {
    await seeded();
    expect(await reason(submit(eng))).toBe('no-changes');
  });
});

describe('plans are read only', () => {
  it('show default and live tiers with the open plan conflicts', async () => {
    const { id } = await submit(eng);
    await reviewChangeSet(db, admin, { id, decision: 'approve' }, now);
    await db.doc('config/features').set({ features: { assistant: { tier: 'free' } } });
    const plans = await productPlans(db, analyst);
    const assistant = plans.catalogue.find((c) => c.key === 'assistant')!;
    expect(assistant).toMatchObject({ defaultTier: 'premium', liveTier: 'free', features: ['platform.lumi'] });
    expect(plans.conflicts).toHaveLength(1);
    expect(plans.capabilities.find((c) => c.key === 'ai.assistance')).toMatchObject({ credits: true, premium: true });
  });
});
