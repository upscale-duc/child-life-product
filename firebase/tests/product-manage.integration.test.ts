import { randomUUID } from 'node:crypto';
import { productRegistrySchema } from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { createDraft, findConflicts, rebuildSearchArtifact, type ArtifactStore, type CopilotModel } from '../functions/src/product-copilot.js';
import { actSection, appliedState, reviewChangeSet, saveSection, submitChangeSet } from '../functions/src/product-hub.js';
import { buildChangeSet, type RepoFile } from '../functions/src/product-hub-ingest.js';
import {
  actConflict,
  actDraft,
  getDecision,
  getJourney,
  listConflicts,
  listDecisions,
  listJourneys,
  listOpportunities,
  saveOpportunity,
  sectionVersions,
  setOpportunityStatus,
} from '../functions/src/product-manage.js';
import type { Staff } from '../functions/src/staff.js';

// Sản phẩm · Phase 3 (D-155) on the Firestore emulator: journeys through the review queue,
// decisions with their chain, opportunities and their two-person acceptance, Copilot drafts
// promoted, conflicts confirmed or closed with a note, Claude's suggestions kept as suggestions,
// and section history. Synthetic data; a scripted model.
const projectId = 'demo-child-life-product-manage';
const now = new Date('2026-10-31T09:00:00Z');
const owner: Staff = { uid: 's_owner', name: 'Owner', roles: ['owner'] };
const admin: Staff = { uid: 's_admin', name: 'Admin', roles: ['admin'] };
const eng: Staff = { uid: 's_eng', name: 'Kỹ sư', roles: ['eng'] };
const analyst: Staff = { uid: 's_analyst', name: 'Phân tích', roles: ['analyst'] };
let app: App;
let db: Firestore;
let bytes: Buffer | null = null;
const store: ArtifactStore = {
  save: async (b) => {
    bytes = b;
  },
  read: async () => bytes,
};
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
      platforms: ['ios', 'android'],
      lifecycle: 'built',
      implementation: 'implemented',
      verification: 'code_read',
      release: 'not_released',
      confidence: 'high',
      docs: ['docs/product/feeding.md'],
      decisions: ['D-001', 'D-002'],
    },
  ],
});
const journeys = {
  version: 1,
  journeys: [
    {
      id: 'first_feeding_log',
      name: { vi: 'Ghi cữ ăn đầu tiên', en: 'First feeding log' },
      goal: { vi: 'Ghi một cữ ăn.', en: 'Log a feed.' },
      trigger: { vi: 'Chạm thẻ Bú bình.', en: 'Tap the Bottle tile.' },
      steps: [{ text: { vi: 'Mở sheet.', en: 'Open the sheet.' }, feature: 'care.feeding' }],
      completion: { vi: 'Bản ghi hiện cho cả nhà.', en: 'The record shows for the family.' },
      verification: 'code_read',
      sources: ['docs/product/feeding.md#rules', 'D-001', 'docs/nope.md'],
    },
  ],
};
const files = (): RepoFile[] => [
  { path: 'docs/product/feeding.md', blobSha: 'f1', text: '# Cho ăn\n\n## Rules\n\nPumped milk is not intake.\n' },
  {
    path: 'docs/product/business-map.md',
    blobSha: 'bm',
    text: '## Owner decisions (2026-10-10)\n| ID | Decision | Resolves | x |\n| --- | --- | --- | --- |\n| **D-001** | **Pumping is not intake**. | Q-001 | — |\n| **D-002** | **Night 18–06**: supersedes D-001. | — | — |\n| Q-001 | Does pumping count? |\n| Q-002 | Night window for stats? |\n',
  },
  { path: 'docs/product-hub/registry/journeys.json', blobSha: 'j1', text: JSON.stringify(journeys) },
];

beforeAll(() => {
  app = initializeApp({ projectId }, `product-manage-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  for (const c of ['productFeatures', 'productSources', 'productChunks', 'productDecisions', 'productConflicts', 'productChangeSets', 'productJourneys', 'productOpportunities', 'productDrafts', 'productCopilotUsage', 'productHubMeta', 'staffAudit']) {
    await db.recursiveDelete(db.collection(c));
  }
  bytes = null;
  const draft = buildChangeSet({ revision: 'r1', files: files(), registry, now }, await appliedState(db));
  expect(draft.summary.warnings).toContain('journey first_feeding_log: docs/nope.md does not exist');
  const { id } = await submitChangeSet(db, eng, { ...draft, dirty: false }, now);
  await reviewChangeSet(db, owner, { id, decision: 'approve' }, now, () => rebuildSearchArtifact(db, store, now));
});

describe('journeys', () => {
  it('arrive through the review queue with their features, and are searchable by the Copilot', async () => {
    const list = await listJourneys(db, analyst);
    expect(list.journeys).toEqual([expect.objectContaining({ id: 'first_feeding_log', steps: 1, features: ['care.feeding'] })]);
    const j = await getJourney(db, analyst, { id: 'first_feeding_log' });
    expect(j.features).toEqual([expect.objectContaining({ id: 'care.feeding', lifecycle: 'built' })]);
    expect(bytes!.length).toBeGreaterThan(0);
    // Unchanged on the next sync.
    const again = buildChangeSet({ revision: 'r2', files: files(), registry, now }, await appliedState(db));
    expect(again.items.filter((i) => i.type === 'journey')).toEqual([]);
  });
});

describe('decisions', () => {
  it('show the supersession chain, what they resolve, and open questions by feature', async () => {
    const list = await listDecisions(db, analyst, {});
    const d1 = list.decisions.find((d) => d.id === 'D-001')!;
    expect(d1).toMatchObject({ status: 'superseded', supersededBy: ['D-002'], resolves: ['Q-001'] });
    expect(list.openByFeature['—']).toEqual(['Q-002']);
    expect((await listDecisions(db, analyst, { kind: 'Q', status: 'open' })).decisions.map((d) => d.id)).toEqual(['Q-002']);
    expect((await listDecisions(db, analyst, { q: 'night' })).decisions.map((d) => d.id)).toEqual(['Q-002', 'D-002']);
    const detail = await getDecision(db, analyst, { id: 'D-001' });
    expect(detail.supersededBy).toEqual(['D-002']);
  });
});

describe('opportunities', () => {
  it('move proposed → triaged → accepted with a second person; the creator cannot accept their own', async () => {
    expect(await reason(saveOpportunity(db, analyst, { title: 'Next-feed nudge', problem: 'Night feeds missed' }, now))).toBe('role');
    const { id } = await saveOpportunity(db, eng, { title: 'Next-feed nudge', feature: 'care.feeding', problem: 'Night feeds missed', decisions: ['D-001'] }, now);
    expect(await reason(setOpportunityStatus(db, eng, { id, status: 'accepted' }, now))).toBe('role');
    expect(await reason(setOpportunityStatus(db, eng, { id, status: 'done' }, now))).toBe('bad-transition');
    await setOpportunityStatus(db, eng, { id, status: 'triaged', note: 'worth a look' }, now);
    await setOpportunityStatus(db, admin, { id, status: 'accepted' }, now);
    expect(await reason(saveOpportunity(db, eng, { id, title: 'Changed title', problem: 'y' }, now))).toBe('opportunity-closed');
    const list = await listOpportunities(db, analyst);
    expect(list.opportunities[0]).toMatchObject({ id, status: 'accepted' });
    expect(list.opportunities[0]!.history.map((h) => h.to)).toEqual(['proposed', 'triaged', 'accepted']);
    expect((await getDecision(db, analyst, { id: 'D-001' })).opportunities).toEqual([{ id, title: 'Next-feed nudge', status: 'accepted' }]);
  });

  it('an admin who created it needs someone else; the Owner may accept their own (D-155 #3)', async () => {
    const a = await saveOpportunity(db, admin, { title: 'Admin idea', problem: 'p' }, now);
    await setOpportunityStatus(db, admin, { id: a.id, status: 'triaged' }, now);
    expect(await reason(setOpportunityStatus(db, admin, { id: a.id, status: 'accepted' }, now))).toBe('own-work');
    const o = await saveOpportunity(db, owner, { title: 'Owner idea', problem: 'p' }, now);
    await setOpportunityStatus(db, owner, { id: o.id, status: 'triaged' }, now);
    expect(await reason(setOpportunityStatus(db, owner, { id: o.id, status: 'accepted' }, now))).toBe('ok');
  });

  it('a Copilot draft is promoted to a proposed opportunity once (Scenario E)', async () => {
    const d = await createDraft(db, analyst, { type: 'hypothesis', feature: 'care.feeding', title: 'Nudge', body: 'If we nudge…', evidence: ['D-001', 'docs/product/feeding.md#rules'] }, now);
    const r = await actDraft(db, eng, { id: d.id, action: 'promote' }, now);
    expect(r.opportunityId).toBeTruthy();
    const opp = (await listOpportunities(db, analyst)).opportunities.find((o) => o.id === r.opportunityId)!;
    expect(opp).toMatchObject({ status: 'proposed', fromDraft: d.id, decisions: ['D-001'], hypothesis: 'If we nudge…' });
    expect(await reason(actDraft(db, eng, { id: d.id, action: 'dismiss' }, now))).toBe('not-pending');
  });
});

describe('conflicts', () => {
  async function seedOpen() {
    await db.doc('productConflicts/cf_1').set({ id: 'cf_1', topic: 'tier', feature: 'care.feeding', summary: 's', tiers: null, claims: [], status: 'open' });
  }
  it('an open conflict closes with Duyệt and a note or a decision, and can be reopened', async () => {
    await seedOpen();
    expect(await reason(actConflict(db, eng, { id: 'cf_1', action: 'resolve', note: 'x' }, now))).toBe('role');
    expect(await reason(actConflict(db, admin, { id: 'cf_1', action: 'resolve' }, now))).toBe('note-required');
    await actConflict(db, admin, { id: 'cf_1', action: 'resolve', decision: 'D-002' }, now);
    const after = (await listConflicts(db, analyst, { status: 'resolved' })).conflicts;
    expect(after[0]).toMatchObject({ id: 'cf_1', resolution: { decision: 'D-002', by: 'Admin' } });
    await actConflict(db, owner, { id: 'cf_1', action: 'reopen', note: 'back' }, now);
    expect((await listConflicts(db, analyst, { status: 'open' })).conflicts.map((c) => c.id)).toEqual(['cf_1']);
  });

  it('Claude suggestions need two real sources and stay "suggested" until confirmed', async () => {
    const model: CopilotModel = {
      model: 'fake-claude',
      async answer(call) {
        const ids = [...call.user.matchAll(/<block id="(S\d+)"/g)].map((m) => m[1]!);
        return {
          refused: false,
          output: {
            conflicts: [
              { summary: 'Two sources disagree', claims: [{ block: ids[0]!, text: 'a' }, { block: ids[1]!, text: 'b' }] },
              { summary: 'Only one real source', claims: [{ block: ids[0]!, text: 'a' }, { block: 'S99', text: 'b' }] },
            ],
          },
        };
      },
    };
    expect(await reason(findConflicts(db, analyst, { feature: 'care.feeding', locale: 'en' }, now, { store, model }))).toBe('role');
    const r = await findConflicts(db, eng, { feature: 'care.feeding', locale: 'en' }, now, { store, model });
    expect(r).toEqual({ added: 1, skipped: 1 });
    const suggested = (await listConflicts(db, analyst, { status: 'suggested' })).conflicts;
    expect(suggested).toEqual([expect.objectContaining({ topic: 'ai_suggested', feature: 'care.feeding' })]);
    expect((await listConflicts(db, analyst, { status: 'open' })).conflicts).toEqual([]);
    await actConflict(db, eng, { id: suggested[0]!.id, action: 'accept' }, now);
    expect((await listConflicts(db, analyst, { status: 'open' })).conflicts).toHaveLength(1);
    expect((await findConflicts(db, eng, { feature: 'care.feeding', locale: 'en' }, now, { store, model })).added).toBe(0);
  });
});

describe('section history', () => {
  it('keeps every approved version', async () => {
    for (const text of ['Bình = thể tích.', 'Bình theo ml; bú mẹ theo phút.']) {
      await saveSection(db, eng, { feature: 'care.feeding', key: 'rules', body: { vi: text }, sources: ['D-001'] }, now);
      await actSection(db, admin, { feature: 'care.feeding', key: 'rules', action: 'approve' }, now);
    }
    const h = await sectionVersions(db, analyst, { feature: 'care.feeding', key: 'rules' });
    expect(h.current).toMatchObject({ version: 2, body: { vi: 'Bình theo ml; bú mẹ theo phút.' } });
    expect(h.versions.map((v) => v.version)).toEqual([1]);
    expect(h.versions[0]!.body.vi).toBe('Bình = thể tích.');
  });
});
