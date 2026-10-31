import { randomUUID } from 'node:crypto';
import { productRegistrySchema } from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { actSection, appliedState, productFeature, reviewChangeSet, saveSection, submitChangeSet } from '../functions/src/product-hub.js';
import { buildChangeSet, type RepoFile } from '../functions/src/product-hub-ingest.js';
import { knowledgeHealth, listMetrics } from '../functions/src/product-manage.js';
import type { Staff } from '../functions/src/staff.js';

// Sản phẩm · Phase 4 before launch (D-155) on the Firestore emulator: metrics arrive through the
// review queue with their code status, coverage counts metrics only when one is computed, and the
// freshness report lists stale text, dead paths, old linked documents and waiting work.
const projectId = 'demo-child-life-product-health';
const now = new Date('2026-10-31T09:00:00Z');
const owner: Staff = { uid: 's_owner', name: 'Owner', roles: ['owner'] };
const admin: Staff = { uid: 's_admin', name: 'Admin', roles: ['admin'] };
const eng: Staff = { uid: 's_eng', name: 'Kỹ sư', roles: ['eng'] };
const analyst: Staff = { uid: 's_analyst', name: 'Phân tích', roles: ['analyst'] };
let app: App;
let db: Firestore;

const registry = productRegistrySchema.parse({
  version: 1,
  features: [
    { id: 'remember.auto_save', name: { vi: 'Tự lưu', en: 'Auto-save' }, pillar: 'remember', platforms: ['ios'], lifecycle: 'built', implementation: 'implemented', verification: 'code_read', release: 'not_released', confidence: 'high', modules: ['apps/x/**', 'apps/gone/**'], docs: ['docs/product/auto-save-plan-2026-08-01.md'] },
    { id: 'care.feeding', name: { vi: 'Cho ăn', en: 'Feeding' }, pillar: 'care', platforms: ['ios'], lifecycle: 'built', implementation: 'implemented', verification: 'code_read', release: 'not_released', confidence: 'high', modules: ['apps/x/**'] },
  ],
});
const dictionary = [
  '## Memories',
  '| ID / metric | Numerator | Denominator | Unit | Window | Source / status | Time |',
  '| --- | --- | --- | --- | --- | --- | --- |',
  '| M03 Discovery→review | P with review | — | P | W | episode join; new | O |',
  '| M04 Review→approval | P approved | — | P | W | episode join; new | O |',
  '| M09 Cards/videos filed | J filed | — | J | W | job filing; extend | O |',
  '| F06 Lumi usefulness | U helpful | — | U | W | assistant feedback; new | O |',
].join('\n');
const files = (): RepoFile[] => [
  { path: 'apps/x/a.dart', blobSha: 'a' },
  { path: 'docs/product/auto-save-plan-2026-08-01.md', blobSha: 'p', text: '# Plan\n\n## Rules\n\nApprove before upload.\n' },
  { path: 'docs/product-analytics/02-metric-dictionary.md', blobSha: 'd', text: dictionary },
  {
    path: 'docs/product-hub/registry/metrics.json',
    blobSha: 'm',
    text: JSON.stringify({
      version: 1,
      metrics: [
        { id: 'M03', reducerIds: ['M_discovered', 'M_review'], features: ['remember.auto_save'] },
        { id: 'M04', reducerIds: ['M_approved'], features: ['remember.auto_save'] },
        { id: 'M09', reducerIds: ['M_card'], features: ['care.feeding'] },
      ],
    }),
  },
];
const probe = { M_discovered: 'unavailable/not_instrumented', M_review: 'provisional/none', M_approved: 'unavailable/not_instrumented', M_card: 'provisional/none' };

beforeAll(() => {
  app = initializeApp({ projectId }, `product-health-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  for (const c of ['productFeatures', 'productSources', 'productChunks', 'productDecisions', 'productConflicts', 'productChangeSets', 'productMetrics', 'productDrafts', 'productOpportunities', 'productHubMeta', 'staffAudit']) {
    await db.recursiveDelete(db.collection(c));
  }
  const draft = buildChangeSet({ revision: 'r1', files: files(), registry, now, metricProbe: probe }, await appliedState(db));
  const { id } = await submitChangeSet(db, eng, { ...draft, dirty: false }, now);
  await reviewChangeSet(db, owner, { id, decision: 'approve' }, now);
});

describe('metrics', () => {
  it('arrive with their code status and stay unchanged on the next sync', async () => {
    const r = await listMetrics(db, analyst, {});
    expect(Object.fromEntries(r.metrics.map((m) => [m.id, m.instrumentation]))).toEqual({
      F06: 'defined_only',
      M03: 'partial',
      M04: 'not_instrumented',
      M09: 'computed',
    });
    expect(r.counts).toEqual({ defined_only: 1, partial: 1, not_instrumented: 1, computed: 1 });
    expect((await listMetrics(db, analyst, { feature: 'remember.auto_save' })).metrics.map((m) => m.id)).toEqual(['M03', 'M04']);
    const again = buildChangeSet({ revision: 'r2', files: files(), registry, now, metricProbe: probe }, await appliedState(db));
    expect(again.items.filter((i) => i.type === 'metric')).toEqual([]);
  });

  it('a feature page lists its metrics; coverage counts metrics fully only when one is computed', async () => {
    for (const feature of ['care.feeding', 'remember.auto_save']) {
      await saveSection(db, eng, { feature, key: 'metrics', body: { vi: 'Chỉ số.' }, sources: ['docs/product-analytics/02-metric-dictionary.md'] }, now);
      await actSection(db, admin, { feature, key: 'metrics', action: 'approve' }, now);
    }
    const feeding = await productFeature(db, analyst, { id: 'care.feeding' });
    expect(feeding.metrics).toEqual([{ id: 'M09', name: 'Cards/videos filed', instrumentation: 'computed', planStatus: 'extend' }]);
    expect(feeding.coverage.dimensions.find((d) => d.key === 'metrics')!.earned).toBe(10);
    // Auto-save: M03 is partly instrumented, which counts as measured too.
    const auto = await productFeature(db, analyst, { id: 'remember.auto_save' });
    expect(auto.coverage.dimensions.find((d) => d.key === 'metrics')!.earned).toBe(10);
  });
});

describe('freshness', () => {
  it('lists dead registry paths, old linked documents, waiting drafts and unreviewed features', async () => {
    await saveSection(db, eng, { feature: 'care.feeding', key: 'summary', body: { vi: 'Nháp.' } }, now, 'ai');
    const h = await knowledgeHealth(db, analyst, now);
    expect(h.deadGlobs).toEqual([{ feature: 'remember.auto_save', globs: ['apps/gone/**'] }]);
    expect(h.oldSources).toEqual([expect.objectContaining({ path: 'docs/product/auto-save-plan-2026-08-01.md', days: 91, features: ['remember.auto_save'] })]);
    expect(h.waiting.sections).toEqual([{ feature: 'care.feeding', key: 'summary', days: 0, origin: 'ai' }]);
    expect(h.unreviewed).toEqual(['care.feeding', 'remember.auto_save']);
    expect(h.index).toMatchObject({ builtAt: null, behind: true });
  });

  it('an approved section whose source changed is listed as stale', async () => {
    await saveSection(db, eng, { feature: 'remember.auto_save', key: 'rules', body: { vi: 'Duyệt trước khi tải.' }, sources: ['docs/product/auto-save-plan-2026-08-01.md#rules'] }, now);
    await actSection(db, admin, { feature: 'remember.auto_save', key: 'rules', action: 'approve' }, now);
    const changed = files().map((f) => (f.path.endsWith('2026-08-01.md') ? { ...f, blobSha: 'p2', text: `${f.text}\nMore.\n` } : f));
    const draft = buildChangeSet({ revision: 'r2', files: changed, registry, now, metricProbe: probe }, await appliedState(db));
    const { id } = await submitChangeSet(db, eng, { ...draft, dirty: false }, now);
    await reviewChangeSet(db, owner, { id, decision: 'approve' }, now);
    const h = await knowledgeHealth(db, analyst, now);
    expect(h.stale).toEqual([expect.objectContaining({ feature: 'remember.auto_save', key: 'rules', paths: ['docs/product/auto-save-plan-2026-08-01.md'] })]);
    expect(h.unreviewed).toEqual(['care.feeding']);
  });
});
