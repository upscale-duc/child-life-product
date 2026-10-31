import { randomUUID } from 'node:crypto';
import { productRegistrySchema } from '@child-life/contracts';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  askCopilot,
  createDraft,
  deleteConversation,
  getConversation,
  listConversations,
  listDrafts,
  rebuildSearchArtifact,
  searchKnowledge,
  type ArtifactStore,
  type CopilotModel,
  type CopilotModelCall,
} from '../functions/src/product-copilot.js';
import { appliedState, reviewChangeSet, submitChangeSet } from '../functions/src/product-hub.js';
import { buildChangeSet, type RepoFile } from '../functions/src/product-hub-ingest.js';
import type { Staff } from '../functions/src/staff.js';

// Sản phẩm · Copilot (D-155, Phase 2) against the Firestore emulator with a scripted model: the
// index built at approval, grounding, sources-only without a model, limits, private conversations
// and drafts that never become decisions. Synthetic documents only; no model calls.
const projectId = 'demo-child-life-product-copilot';
const now = new Date('2026-10-31T09:00:00Z');
const owner: Staff = { uid: 's_owner', name: 'Owner', roles: ['owner'] };
const eng: Staff = { uid: 's_eng', name: 'Kỹ sư', roles: ['eng'] };
const analyst: Staff = { uid: 's_analyst', name: 'Phân tích', roles: ['analyst'] };
const support: Staff = { uid: 's_support', name: 'Hỗ trợ', roles: ['support'] };
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
      id: 'remember.auto_save',
      name: { vi: 'Tự lưu kỷ niệm', en: 'Auto-save memories' },
      pillar: 'remember',
      hubKey: 'auto_save',
      platforms: ['ios'],
      lifecycle: 'built',
      implementation: 'implemented',
      verification: 'code_read',
      release: 'not_released',
      confidence: 'high',
      docs: ['docs/product/auto-save-plan.md'],
    },
  ],
});
const files: RepoFile[] = [
  {
    path: 'docs/product/auto-save-plan.md',
    blobSha: 'b1',
    text: '# Tự lưu kỷ niệm\n\n## Permission\n\nWhen Photos access is denied, Auto-save pauses and offers Open Settings.\n',
  },
  {
    path: 'docs/product/business-map.md',
    blobSha: 'b2',
    text: '## Owner decisions (2026-10-13)\n| ID | Decision | Resolves | x |\n| --- | --- | --- | --- |\n| **D-066** | **Tự lưu kỷ niệm, free beta on iOS**. | — | — |\n',
  },
];

/** A model that cites what the test tells it to and records what it was sent. */
function fakeModel(answer: (call: CopilotModelCall) => unknown, refused = false): CopilotModel & { calls: CopilotModelCall[] } {
  const calls: CopilotModelCall[] = [];
  return {
    model: 'fake-claude',
    calls,
    async answer(call) {
      calls.push(call);
      return { refused, output: refused ? null : answer(call) };
    },
  };
}
/** The id of the block whose text contains `needle`. */
const blockOf = (call: CopilotModelCall, needle: string) =>
  call.user
    .split('</block>')
    .find((b) => b.includes(needle))
    ?.match(/<block id="(S\d+)"/)?.[1];

beforeAll(() => {
  app = initializeApp({ projectId }, `product-copilot-${randomUUID()}`);
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
    'productConversations',
    'productCopilotUsage',
    'productDrafts',
    'productHubMeta',
    'staffAudit',
    'config',
  ]) {
    await db.recursiveDelete(db.collection(c));
  }
  bytes = null;
  const draft = buildChangeSet({ revision: 'r1', files, registry, now }, await appliedState(db));
  const { id } = await submitChangeSet(db, eng, { ...draft, dirty: false }, now);
  await reviewChangeSet(db, owner, { id, decision: 'approve' }, now, () => rebuildSearchArtifact(db, store, now));
});

const ask = (staff: Staff | null, data: object, model: CopilotModel | null = null) =>
  askCopilot(db, staff, { scope: 'global', locale: 'en', question: 'What happens when Photos access is denied?', ...data }, now, { store, model });

describe('access and limits', () => {
  it('needs Sản phẩm view; support is refused', async () => {
    expect(await reason(ask(null, {}))).toBe('not-staff');
    expect(await reason(ask(support, {}))).toBe('role');
    expect(await reason(ask(analyst, {}))).toBe('ok');
  });
  it('20 questions per hour per staff member (D-155 #5)', async () => {
    await db.doc(`productCopilotUsage/${analyst.uid}`).set({ hour: now.toISOString().slice(0, 13), hourCount: 20, day: now.toISOString().slice(0, 10), dayCount: 20 });
    expect(await reason(ask(analyst, {}))).toBe('copilot-limit-hour');
    expect(await reason(ask(eng, {}))).toBe('ok');
  });
});

describe('answers', () => {
  it('the index built at approval is searchable', async () => {
    const r = await searchKnowledge(db, analyst, { q: 'photos denied' }, store);
    expect(r.built).toBe(true);
    expect(r.hits[0]).toMatchObject({ path: 'docs/product/auto-save-plan.md', authority: 'draft_spec' });
  });

  it('without a model: the sources, marked as no answer', async () => {
    const r = await ask(analyst, {});
    expect(r.message.answer).toMatchObject({ mode: 'sources', reason: 'unconfigured', confidence: 'insufficient' });
    expect(r.message.answer!.citations.some((c) => c.path === 'docs/product/auto-save-plan.md')).toBe(true);
  });

  it('a grounded answer keeps valid citations and downgrades a draft-only fact (Scenario B)', async () => {
    const model = fakeModel((call) => {
      const doc = blockOf(call, 'Photos access is denied')!;
      const facts = blockOf(call, 'facts from code')!;
      return {
        answer: 'Auto-save pauses and offers Open Settings.',
        features: ['remember.auto_save'],
        claims: [
          { text: 'It pauses and offers Open Settings', type: 'fact', cites: [doc] },
          { text: 'It is iOS only', type: 'fact', cites: [facts, 'S99'] },
        ],
        missingEvidence: ['Not checked on a real iPhone'],
        implications: '',
        suggestions: [],
      };
    });
    const r = await ask(analyst, { scope: 'remember.auto_save' }, model);
    const a = r.message.answer!;
    expect(a.mode).toBe('model');
    expect(a.claims[0]).toMatchObject({ type: 'assumption', downgraded: true }); // a draft spec only
    expect(a.claims[1]).toMatchObject({ type: 'fact', downgraded: false });
    expect(a.claims[1]!.cites).not.toContain('S99');
    expect(a.confidence).toBe('mixed');
    expect(model.calls[0]!.registry).toContain('remember.auto_save | Tự lưu kỷ niệm');
    expect(model.calls[0]!.user).not.toMatch(/babies\/|familyId/);
  });

  it('a refusal or a broken answer falls back to the sources', async () => {
    expect((await ask(analyst, {}, fakeModel(() => null, true))).message.answer!.reason).toBe('refused');
    expect((await ask(analyst, {}, fakeModel(() => ({ nope: true })))).message.answer!.reason).toBe('error');
  });
});

describe('conversations and drafts', () => {
  it('a follow-up carries earlier turns; conversations are private to their owner', async () => {
    const model = fakeModel(() => ({ answer: 'First answer', features: [], claims: [], missingEvidence: [], implications: '', suggestions: [] }));
    const first = await ask(analyst, {}, model);
    await ask(analyst, { conversationId: first.conversationId, question: 'And on Android?' }, model);
    expect(model.calls[1]!.user).toContain('Earlier in this conversation');
    expect(model.calls[1]!.user).toContain('First answer');
    const mine = await listConversations(db, analyst, now);
    expect(mine.conversations).toHaveLength(1);
    expect((await getConversation(db, analyst, { id: first.conversationId })).messages).toHaveLength(4);
    expect(await reason(getConversation(db, eng, { id: first.conversationId }))).toBe('not-found');
    expect(await reason(ask(eng, { conversationId: first.conversationId }))).toBe('not-found');
    await deleteConversation(db, analyst, { id: first.conversationId });
    expect((await listConversations(db, analyst, now)).conversations).toEqual([]);
  });

  it('saving an answer makes a draft, never a decision (Scenario E)', async () => {
    const { id } = await createDraft(db, analyst, { type: 'opportunity', feature: 'remember.auto_save', title: 'Review by week', body: 'Hypothesis…', evidence: ['D-066'] }, now);
    const drafts = await listDrafts(db, analyst);
    expect(drafts.drafts).toEqual([expect.objectContaining({ id, status: 'draft', type: 'opportunity', createdBy: 'Phân tích' })]);
    expect((await db.collection('productDecisions').where('id', '==', id).get()).empty).toBe(true);
  });
});
