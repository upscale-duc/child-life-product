import {
  capabilities,
  catalogueFeature,
  coverageBand,
  creditCapabilities,
  featureCatalogue,
  featureSectionKeys,
  freeCapabilities,
  premiumCapabilities,
  productChangeSetRefSchema,
  productCoverage,
  productFeatureRefSchema,
  productReviewChangeSetSchema,
  productSaveSectionSchema,
  productSectionActSchema,
  productSourceRefSchema,
  productSourcesQuerySchema,
  staffCan,
  type ChangeItem,
  type ChangeSetSummary,
  type CoverageInput,
  type FeatureSection,
  type FeatureSectionKey,
  type FeatureTier,
  type ProductChunk,
  type ProductConflictRecord,
  type ProductDecisionRecord,
  type ProductFeatureRecord,
  type ProductSourceRecord,
} from '@child-life/contracts';
import type { DocumentSnapshot, Firestore } from 'firebase-admin/firestore';
import { recordHash, type AppliedState, type ChangeSetDraft } from './product-hub-ingest.js';
import { parse, requireStaff, staffAudit, staffLevelsOf, StaffError, type Staff } from './staff.js';

/**
 * Product Hub · "Sản phẩm" (D-155, `docs/product-hub/`). Staff-only product knowledge: the sync
 * submits a change set (draft), someone with Duyệt approves it (not their own, except the Owner,
 * D-155 #3), and only then sources, chunks, decisions and feature facts change. Narrative
 * sections are drafts until approved; a sync never rewrites them, it marks them stale. Nothing
 * here reads family data or writes `config/*` — tiers are shown from the catalogue and
 * `config/features`, changed only in "Tính năng & Premium".
 */

const C = {
  features: 'productFeatures',
  sections: 'productSections',
  sources: 'productSources',
  chunks: 'productChunks',
  decisions: 'productDecisions',
  conflicts: 'productConflicts',
  changeSets: 'productChangeSets',
  journeys: 'productJourneys',
} as const;

const iso = (v: unknown): string | null => {
  if (!v) return null;
  if (typeof v === 'string') return v;
  if (v instanceof Date) return v.toISOString();
  const t = v as { toDate?: () => Date };
  return t.toDate ? t.toDate().toISOString() : null;
};

const isOwner = (s: Staff) => s.roles.includes('owner');

/** D-155 #3: two people — the author never approves their own work, except the Owner. */
function requireReviewer(staff: Staff, authorUid: string | null | undefined) {
  if (authorUid && authorUid === staff.uid && !isOwner(staff)) {
    throw new StaffError('failed-precondition', 'own-work');
  }
}

async function inBatches<T>(db: Firestore, list: T[], write: (b: FirebaseFirestore.WriteBatch, x: T) => void, size = 400) {
  for (let i = 0; i < list.length; i += size) {
    const batch = db.batch();
    list.slice(i, i + size).forEach((x) => write(batch, x));
    await batch.commit();
  }
}

// ---------- Applied state (read by the sync script) ----------

export async function appliedState(db: Firestore): Promise<AppliedState> {
  const [sources, decisions, features, conflicts, journeys] = await Promise.all([
    db.collection(C.sources).where('kind', '==', 'repo_md').get(),
    db.collection(C.decisions).get(),
    db.collection(C.features).get(),
    db.collection(C.conflicts).select().get(),
    db.collection(C.journeys).get(),
  ]);
  return {
    sources: sources.docs.map((d) => ({
      id: d.id,
      path: d.get('path') as string,
      contentHash: d.get('contentHash') as string,
      blobSha: d.get('blobSha') as string,
      status: d.get('status') as ProductSourceRecord['status'],
      authority: d.get('authority') as ProductSourceRecord['authority'],
      features: (d.get('features') as string[] | undefined) ?? [],
    })),
    // Recomputed from what is stored, so a change to the hash rule never floods a review.
    decisions: Object.fromEntries(decisions.docs.map((d) => [d.id, recordHash(d.data())])),
    features: Object.fromEntries(
      features.docs.filter((d) => d.get('removed') !== true).map((d) => [d.id, recordHash(d.data())]),
    ),
    conflicts: conflicts.docs.map((d) => d.id),
    journeys: Object.fromEntries(journeys.docs.map((d) => [d.id, recordHash(d.data())])),
  };
}

// ---------- Submit (sync script, `--submit`) ----------

/**
 * Stores a change set as `pending`. A set already pending must be reviewed first, so two sets
 * never apply over each other; `replacePending` closes the old one as `superseded`.
 */
export async function submitChangeSet(
  db: Firestore,
  staff: Staff | null,
  draft: ChangeSetDraft & { dirty: boolean },
  now: Date,
  options: { replacePending?: boolean } = {},
) {
  const s = requireStaff(staff, 'product.edit');
  if (draft.dirty) throw new StaffError('failed-precondition', 'dirty-tree');
  if (draft.items.length === 0) throw new StaffError('failed-precondition', 'no-changes');
  if (draft.items.length > 5000) throw new StaffError('invalid-argument', 'too-many-items');
  const pending = await db.collection(C.changeSets).where('status', '==', 'pending').get();
  if (!pending.empty && !options.replacePending) {
    throw new StaffError('failed-precondition', 'pending-exists');
  }
  const ref = db.collection(C.changeSets).doc();
  const docs: Array<Record<string, unknown>> = [];
  for (const item of draft.items) {
    if (item.type === 'source') {
      const { chunks, ...rest } = item;
      docs.push({ ...rest, chunkCount: chunks.length });
      for (let i = 0; i < chunks.length; i += 40) {
        docs.push({ type: 'chunks', sourceId: item.source.id, chunks: chunks.slice(i, i + 40) });
      }
    } else docs.push(item as unknown as Record<string, unknown>);
  }
  await inBatches(db, docs.map((d, i) => ({ d, i })), (b, { d, i }) =>
    b.set(ref.collection('items').doc(String(i).padStart(5, '0')), d),
  );
  const batch = db.batch();
  for (const p of pending.docs) batch.update(p.ref, { status: 'superseded', supersededBy: ref.id });
  batch.set(ref, {
    status: 'pending',
    revision: draft.revision,
    summary: draft.summary,
    itemCount: draft.items.length,
    createdByUid: s.uid,
    createdByName: s.name,
    createdAt: now,
  });
  staffAudit(
    batch,
    db,
    s,
    {
      action: 'product.sync.submit',
      category: 'product',
      target: ref.id,
      reason: null,
      detail: { revision: draft.revision, ...countsOf(draft.summary) },
    },
    now,
  );
  await batch.commit();
  return { id: ref.id };
}

const countsOf = (s: ChangeSetSummary) => ({
  added: s.added,
  changed: s.changed,
  moved: s.moved,
  deleted: s.deleted,
});

// ---------- Review ----------

export async function listChangeSets(db: Firestore, staff: Staff | null) {
  requireStaff(staff, 'product.view');
  const snap = await db.collection(C.changeSets).orderBy('createdAt', 'desc').limit(30).get();
  return {
    changeSets: snap.docs.map((d) => ({
      id: d.id,
      status: d.get('status') as string,
      revision: d.get('revision') as string,
      summary: d.get('summary') as ChangeSetSummary,
      itemCount: d.get('itemCount') as number,
      createdBy: d.get('createdByName') as string,
      createdByUid: d.get('createdByUid') as string,
      createdAt: iso(d.get('createdAt')),
      reviewedBy: (d.get('reviewedByName') as string | undefined) ?? null,
      reviewedAt: iso(d.get('reviewedAt')),
      reason: (d.get('reason') as string | undefined) ?? '',
    })),
  };
}

type StoredItem =
  | Exclude<ChangeItem, { type: 'source' }>
  | (Omit<Extract<ChangeItem, { type: 'source' }>, 'chunks'> & { chunkCount: number })
  | { type: 'chunks'; sourceId: string; chunks: ProductChunk[] };

async function itemsOf(db: Firestore, id: string): Promise<StoredItem[]> {
  const snap = await db.collection(C.changeSets).doc(id).collection('items').orderBy('__name__').get();
  return snap.docs.map((d) => d.data() as StoredItem);
}

/** One change set for the review screen: what changes, with old and new text of changed sections. */
export async function changeSetDetail(db: Firestore, staff: Staff | null, data: unknown) {
  requireStaff(staff, 'product.view');
  const { id } = parse(productChangeSetRefSchema, data);
  const ref = await db.collection(C.changeSets).doc(id).get();
  if (!ref.exists) throw new StaffError('not-found', 'not-found');
  const items = await itemsOf(db, id);
  const newChunks = new Map<string, ProductChunk[]>();
  for (const i of items) {
    if (i.type === 'chunks') newChunks.set(i.sourceId, [...(newChunks.get(i.sourceId) ?? []), ...i.chunks]);
  }
  const sources = [];
  for (const i of items) {
    if (i.type !== 'source') continue;
    const fresh = newChunks.get(i.source.id) ?? [];
    let diff: Array<{ heading: string; change: 'added' | 'removed' | 'changed'; before: string; after: string }> = [];
    if (i.change === 'changed' || i.change === 'moved' || i.change === 'deleted') {
      const old = await db.collection(C.chunks).where('sourceId', '==', i.source.id).get();
      const join = (cs: Array<{ headingPath: string[]; text: string }>) => {
        const m = new Map<string, string>();
        for (const c of cs) {
          const k = c.headingPath.join(' › ') || '—';
          m.set(k, m.has(k) ? `${m.get(k)}\n\n${c.text}` : c.text);
        }
        return m;
      };
      const before = join(old.docs.map((d) => d.data() as ProductChunk));
      const after = join(fresh);
      for (const [k, v] of after) {
        const b = before.get(k);
        if (b === undefined) diff.push({ heading: k, change: 'added', before: '', after: v });
        else if (b !== v) diff.push({ heading: k, change: 'changed', before: b, after: v });
      }
      for (const [k, v] of before) {
        if (!after.has(k)) diff.push({ heading: k, change: 'removed', before: v, after: '' });
      }
      diff = diff.slice(0, 40).map((x) => ({
        ...x,
        before: x.before.slice(0, 3000),
        after: x.after.slice(0, 3000),
      }));
    }
    sources.push({
      change: i.change,
      id: i.source.id,
      path: i.source.path,
      beforePath: i.before?.path ?? null,
      title: i.source.title,
      authority: i.source.authority,
      features: i.source.features,
      chunkCount: i.chunkCount,
      diff,
    });
  }
  return {
    id,
    status: ref.get('status') as string,
    revision: ref.get('revision') as string,
    summary: ref.get('summary') as ChangeSetSummary,
    createdBy: ref.get('createdByName') as string,
    createdByUid: ref.get('createdByUid') as string,
    createdAt: iso(ref.get('createdAt')),
    sources,
    decisions: items
      .filter((i): i is Extract<StoredItem, { type: 'decision' }> => i.type === 'decision')
      .map((i) => ({ change: i.change, id: i.decision.id, title: i.decision.title, status: i.decision.status })),
    features: items
      .filter((i): i is Extract<StoredItem, { type: 'feature' }> => i.type === 'feature')
      .map((i) => ({
        change: i.change,
        id: i.feature.id,
        name: i.feature.name ?? null,
        deadGlobs: i.feature.facts?.deadGlobs ?? [],
      })),
    conflicts: items
      .filter((i): i is Extract<StoredItem, { type: 'conflict' }> => i.type === 'conflict')
      .map((i) => i.conflict),
    journeys: items
      .filter((i): i is Extract<StoredItem, { type: 'journey' }> => i.type === 'journey')
      .map((i) => ({ change: i.change, id: i.journey.id, name: i.journey.name ?? null })),
  };
}

/**
 * Approve applies the change set; reject leaves the knowledge as it was. Approved sections whose
 * sources changed are marked stale with the paths — their text is never touched (Scenario D).
 */
export async function reviewChangeSet(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  /** Runs after an approval is applied (the Copilot's search index); a failure never undoes it. */
  afterApply?: () => Promise<unknown>,
) {
  const s = requireStaff(staff, 'product.approve');
  const req = parse(productReviewChangeSetSchema, data);
  const ref = db.collection(C.changeSets).doc(req.id);
  const snap = await ref.get();
  if (!snap.exists) throw new StaffError('not-found', 'not-found');
  if (snap.get('status') !== 'pending') throw new StaffError('failed-precondition', 'not-pending');
  requireReviewer(s, snap.get('createdByUid') as string);

  if (req.decision === 'reject') {
    const batch = db.batch();
    batch.update(ref, {
      status: 'rejected',
      reviewedByUid: s.uid,
      reviewedByName: s.name,
      reviewedAt: now,
      reason: req.reason,
    });
    staffAudit(batch, db, s, { action: 'product.changeset.reject', category: 'product', target: req.id, reason: req.reason || null }, now);
    await batch.commit();
    return { status: 'rejected' as const };
  }

  // Claim it first so a second reviewer cannot apply the same set twice.
  await db.runTransaction(async (tx) => {
    const cur = await tx.get(ref);
    if (cur.get('status') !== 'pending') throw new StaffError('failed-precondition', 'not-pending');
    tx.update(ref, { status: 'applying', reviewedByUid: s.uid, reviewedByName: s.name, reviewedAt: now });
  });
  const items = await itemsOf(db, req.id);
  const touched: string[] = [];
  const chunksBySource = new Map<string, ProductChunk[]>();
  for (const i of items) {
    if (i.type === 'chunks') chunksBySource.set(i.sourceId, [...(chunksBySource.get(i.sourceId) ?? []), ...i.chunks]);
  }

  for (const i of items) {
    if (i.type !== 'source') continue;
    const sref = db.collection(C.sources).doc(i.source.id);
    const old = await db.collection(C.chunks).where('sourceId', '==', i.source.id).select().get();
    await inBatches(db, old.docs, (b, d) => b.delete(d.ref));
    if (i.change === 'deleted') {
      await sref.set({ status: 'deleted', deletedAt: now, chunkCount: 0 }, { merge: true });
    } else {
      const chunks = chunksBySource.get(i.source.id) ?? [];
      await inBatches(db, chunks, (b, c) => b.set(db.collection(C.chunks).doc(c.id), c));
      await sref.set({ ...i.source, syncedAt: now, changeSet: req.id });
      await sref.collection('versions').doc(i.source.contentHash.slice(0, 16)).set({
        contentHash: i.source.contentHash,
        commit: i.source.commit,
        path: i.source.path,
        chunkCount: chunks.length,
        changeSet: req.id,
        syncedAt: now,
      });
    }
    touched.push(i.source.path);
    if (i.before && i.before.path !== i.source.path) touched.push(i.before.path);
  }
  const rest = items.filter(
    (i) => i.type === 'decision' || i.type === 'feature' || i.type === 'conflict' || i.type === 'journey',
  );
  await inBatches(db, rest, (b, i) => {
    if (i.type === 'decision') {
      const r = db.collection(C.decisions).doc(i.decision.id);
      if (i.change === 'deleted') b.delete(r);
      else b.set(r, { ...i.decision, hash: recordHash(i.decision), syncedAt: now });
    } else if (i.type === 'feature') {
      const r = db.collection(C.features).doc(i.feature.id);
      if (i.change === 'deleted') b.set(r, { removed: true, removedAt: now }, { merge: true });
      else b.set(r, { ...i.feature, removed: false, hash: recordHash(i.feature) });
    } else if (i.type === 'journey') {
      const r = db.collection(C.journeys).doc(i.journey.id);
      if (i.change === 'deleted') b.delete(r);
      else b.set(r, { ...i.journey });
    } else if (i.type === 'conflict') {
      b.set(db.collection(C.conflicts).doc(i.conflict.id), { ...i.conflict, createdAt: now, changeSet: req.id });
    }
  });

  // Stale marking (doc 06 §2.8): approved sections citing a touched path.
  let staleCount = 0;
  if (touched.length) {
    const sections = await db.collectionGroup(C.sections).get();
    await inBatches(db, sections.docs, (b, d) => {
      const approved = d.get('approved') as FeatureSection['approved'];
      if (!approved) return;
      const hit = touched.filter((p) => approved.sources.some((src) => src === p || src.startsWith(`${p}#`) || src.startsWith(`${p}:`)));
      if (!hit.length) return;
      staleCount++;
      const prior = (d.get('stale') as FeatureSection['stale']) ?? null;
      b.update(d.ref, {
        stale: { since: prior?.since ?? now.toISOString(), paths: [...new Set([...(prior?.paths ?? []), ...hit])] },
      });
    });
  }

  const batch = db.batch();
  batch.update(ref, { status: 'approved', reason: req.reason, staleSections: staleCount });
  staffAudit(
    batch,
    db,
    s,
    {
      action: 'product.changeset.approve',
      category: 'product',
      target: req.id,
      reason: req.reason || null,
      detail: { revision: snap.get('revision') as string, items: items.length, staleSections: staleCount },
    },
    now,
  );
  await batch.commit();
  let indexed = true;
  if (afterApply) {
    try {
      await afterApply();
    } catch {
      indexed = false;
    }
  }
  return { status: 'approved' as const, staleSections: staleCount, indexed };
}

// ---------- Features ----------

type LiveTiers = Partial<Record<string, FeatureTier>>;

async function liveTiers(db: Firestore): Promise<LiveTiers> {
  const doc = await db.doc('config/features').get();
  const features = (doc.get('features') as Record<string, { tier?: FeatureTier }> | undefined) ?? {};
  return Object.fromEntries(Object.entries(features).map(([k, v]) => [k, v?.tier]));
}

function sectionOf(d: DocumentSnapshot): FeatureSection {
  return {
    key: d.id as FeatureSectionKey,
    draft: (d.get('draft') as FeatureSection['draft']) ?? null,
    approved: (d.get('approved') as FeatureSection['approved']) ?? null,
    stale: (d.get('stale') as FeatureSection['stale']) ?? null,
  };
}

function coverageFor(
  f: ProductFeatureRecord,
  sections: FeatureSection[],
  conflicts: ProductConflictRecord[],
) {
  const input: CoverageInput = {
    sections: Object.fromEntries(
      sections.map((s) => [
        s.key,
        {
          state: s.approved ? 'approved' : s.draft ? 'draft' : 'missing',
          stale: !!s.stale,
          sources: (s.approved ?? s.draft)?.sources.length ?? 0,
        },
      ]),
    ),
    hasTier: !!f.hubKey || f.capabilities.length > 0,
    openTierConflict: conflicts.some((c) => c.topic === 'tier'),
    moduleCount: f.facts.modules.length,
    testCount: f.facts.tests.length,
    decisionCount: f.facts.decisions.length,
    metricsInstrumented: !!sections
      .find((s) => s.key === 'metrics')
      ?.approved?.sources.some((x) => x.startsWith('docs/product-analytics/')),
    openConflicts: conflicts.length,
  };
  return productCoverage(input);
}

const featureOf = (d: DocumentSnapshot) => ({ ...(d.data() as ProductFeatureRecord), id: d.id });

async function openConflicts(db: Firestore) {
  const snap = await db.collection(C.conflicts).where('status', '==', 'open').get();
  return snap.docs.map((d) => d.data() as ProductConflictRecord);
}

export async function productFeatures(db: Firestore, staff: Staff | null) {
  requireStaff(staff, 'product.view');
  const [features, sections, conflicts, tiers] = await Promise.all([
    db.collection(C.features).where('removed', '==', false).get(),
    db.collectionGroup(C.sections).get(),
    openConflicts(db),
    liveTiers(db),
  ]);
  const byFeature = new Map<string, FeatureSection[]>();
  for (const d of sections.docs) {
    const fid = d.ref.parent.parent!.id;
    byFeature.set(fid, [...(byFeature.get(fid) ?? []), sectionOf(d)]);
  }
  const rows = features.docs.map((d) => {
    const f = featureOf(d);
    const mine = conflicts.filter((c) => c.feature === f.id);
    const cov = coverageFor(f, byFeature.get(f.id) ?? [], mine);
    return {
      id: f.id,
      name: f.name,
      pillar: f.pillar,
      chapters: f.chapters,
      platforms: f.platforms,
      lifecycle: f.lifecycle,
      implementation: f.implementation,
      verification: f.verification,
      release: f.release,
      confidence: f.confidence,
      hubKey: f.hubKey,
      tier: f.hubKey ? (tiers[f.hubKey] ?? catalogueFeature(f.hubKey).defaultTier) : null,
      coverage: cov.score,
      band: coverageBand(cov.score),
      missing: cov.missing,
      stale: cov.stale.length,
      conflicts: mine.length,
      syncedAt: iso(f.syncedAt),
      revision: f.revision,
    };
  });
  rows.sort((a, b) => a.id.localeCompare(b.id));
  return { features: rows, conflictsWithoutFeature: conflicts.filter((c) => !c.feature).length };
}

export async function productFeature(db: Firestore, staff: Staff | null, data: unknown) {
  const s = requireStaff(staff, 'product.view');
  const { id } = parse(productFeatureRefSchema, data);
  const doc = await db.collection(C.features).doc(id).get();
  if (!doc.exists || doc.get('removed') === true) throw new StaffError('not-found', 'not-found');
  const f = featureOf(doc);
  const [sectionsSnap, sourcesSnap, conflictsSnap, dependents, tiers] = await Promise.all([
    doc.ref.collection(C.sections).get(),
    db.collection(C.sources).where('features', 'array-contains', id).get(),
    db.collection(C.conflicts).where('feature', '==', id).get(),
    db.collection(C.features).where('dependsOn', 'array-contains', id).get(),
    liveTiers(db),
  ]);
  const decisionRefs = f.facts.decisions.slice(0, 100).map((x) => db.collection(C.decisions).doc(x));
  const decisions = decisionRefs.length ? await db.getAll(...decisionRefs) : [];
  const sections = sectionsSnap.docs.map(sectionOf);
  const conflicts = conflictsSnap.docs.map((d) => d.data() as ProductConflictRecord);
  const open = conflicts.filter((c) => c.status === 'open');
  const decisionRows = decisions
    .filter((d) => d.exists)
    .map((d) => {
      const r = d.data() as ProductDecisionRecord;
      return { id: r.id, kind: r.kind, title: r.title, date: r.date, status: r.status };
    })
    .sort((a, b) => b.id.localeCompare(a.id));
  const superseded = new Set(decisionRows.filter((d) => d.status === 'superseded').map((d) => d.id));
  const hub = f.hubKey ? catalogueFeature(f.hubKey) : null;
  return {
    feature: { ...f, syncedAt: iso(f.syncedAt) },
    sections: featureSectionKeys.map(
      (k) => sections.find((x) => x.key === k) ?? { key: k, draft: null, approved: null, stale: null },
    ),
    /** Approved sections that cite a decision now superseded (doc 06 §2.7). */
    supersededCitations: sections.flatMap((x) =>
      (x.approved?.sources ?? []).filter((src) => superseded.has(src)).map((src) => ({ section: x.key, id: src })),
    ),
    coverage: coverageFor(f, sections, open),
    access: hub
      ? {
          hubKey: hub.key,
          defaultTier: hub.defaultTier,
          liveTier: tiers[hub.key] ?? null,
          credits: hub.credits,
          flags: [...hub.flags],
          capabilities: [...hub.capabilities],
        }
      : { hubKey: null, defaultTier: null, liveTier: null, credits: false, flags: [], capabilities: f.capabilities },
    sources: sourcesSnap.docs
      .map((d) => d.data() as ProductSourceRecord)
      .filter((x) => x.status === 'active')
      .map((x) => ({ id: x.id, path: x.path, title: x.title, authority: x.authority, docDate: x.docDate, commit: x.commit }))
      .sort((a, b) => a.path.localeCompare(b.path)),
    decisions: decisionRows,
    conflicts,
    dependents: dependents.docs.filter((d) => d.get('removed') !== true).map((d) => d.id).sort(),
    canEdit: staffCan(staffLevelsOf(s), 'product.edit'),
    canApprove: staffCan(staffLevelsOf(s), 'product.approve'),
  };
}

/**
 * Saves a section draft. `origin` is set only by trusted server-side tools (the drafts script):
 * an AI-written draft says so in the portal and is approved like any other (D-155 #3).
 */
export async function saveSection(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  origin: 'staff' | 'ai' = 'staff',
) {
  const s = requireStaff(staff, 'product.edit');
  const req = parse(productSaveSectionSchema, data);
  const feature = db.collection(C.features).doc(req.feature);
  if (!(await feature.get()).exists) throw new StaffError('not-found', 'not-found');
  const ref = feature.collection(C.sections).doc(req.key);
  const batch = db.batch();
  batch.set(
    ref,
    {
      draft: { body: req.body, sources: req.sources, by: s.name, byUid: s.uid, at: now.toISOString(), origin },
    },
    { merge: true },
  );
  staffAudit(
    batch,
    db,
    s,
    { action: 'product.section.draft', category: 'product', target: `${req.feature}/${req.key}`, reason: null, detail: { origin } },
    now,
  );
  await batch.commit();
  return { ok: true };
}

export async function actSection(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const req = parse(productSectionActSchema, data);
  const s = requireStaff(staff, req.action === 'approve' ? 'product.approve' : 'product.edit');
  const ref = db.collection(C.features).doc(req.feature).collection(C.sections).doc(req.key);
  return db.runTransaction(async (tx) => {
    const cur = await tx.get(ref);
    const draft = cur.get('draft') as (FeatureSection['draft'] & { byUid?: string }) | null | undefined;
    if (!draft) throw new StaffError('failed-precondition', 'no-draft');
    if (req.action === 'discard') {
      tx.update(ref, { draft: null });
      staffAudit(tx, db, s, { action: 'product.section.discard', category: 'product', target: `${req.feature}/${req.key}`, reason: null }, now);
      return { ok: true };
    }
    requireReviewer(s, draft.byUid);
    const prior = cur.get('approved') as FeatureSection['approved'] | null;
    if (prior) tx.set(ref.collection('versions').doc(String(prior.version).padStart(4, '0')), prior);
    tx.set(ref, {
      draft: null,
      stale: null,
      approved: {
        body: draft.body,
        sources: draft.sources,
        by: draft.by,
        at: draft.at,
        approvedBy: s.name,
        approvedAt: now.toISOString(),
        version: (prior?.version ?? 0) + 1,
      },
    });
    staffAudit(tx, db, s, { action: 'product.section.approve', category: 'product', target: `${req.feature}/${req.key}`, reason: null }, now);
    return { ok: true };
  });
}

// ---------- Sources & decisions ----------

export async function productSources(db: Firestore, staff: Staff | null, data: unknown) {
  requireStaff(staff, 'product.view');
  const q = parse(productSourcesQuerySchema, data ?? {});
  let query: FirebaseFirestore.Query = db.collection(C.sources).where('status', '==', 'active');
  if (q.feature) query = query.where('features', 'array-contains', q.feature);
  const snap = await query.get();
  const needle = q.q?.toLowerCase();
  const rows = snap.docs
    .map((d) => d.data() as ProductSourceRecord & { syncedAt?: unknown })
    .filter((x) => !q.authority || x.authority === q.authority)
    .filter((x) => !needle || x.path.toLowerCase().includes(needle) || x.title.toLowerCase().includes(needle))
    .map((x) => ({
      id: x.id,
      path: x.path,
      title: x.title,
      authority: x.authority,
      features: x.features,
      decisions: x.decisions.length,
      chunkCount: x.chunkCount,
      docDate: x.docDate,
      commit: x.commit,
      syncedAt: iso(x.syncedAt),
    }))
    .sort((a, b) => a.path.localeCompare(b.path));
  return { sources: rows };
}

export async function productSource(db: Firestore, staff: Staff | null, data: unknown) {
  requireStaff(staff, 'product.view');
  const { id } = parse(productSourceRefSchema, data);
  const doc = await db.collection(C.sources).doc(id).get();
  if (!doc.exists) throw new StaffError('not-found', 'not-found');
  const [chunks, versions] = await Promise.all([
    db.collection(C.chunks).where('sourceId', '==', id).get(),
    doc.ref.collection('versions').orderBy('syncedAt', 'desc').limit(20).get(),
  ]);
  const x = doc.data() as ProductSourceRecord & { syncedAt?: unknown };
  return {
    source: { ...x, syncedAt: iso(x.syncedAt) },
    // Chunk ids carry no order; the heading order of the file is kept by `headings`.
    chunks: chunks.docs
      .map((d) => d.data() as ProductChunk)
      .sort((a, b) => {
        const ia = x.headings.indexOf(a.headingPath.join(' › '));
        const ib = x.headings.indexOf(b.headingPath.join(' › '));
        return ia - ib;
      }),
    versions: versions.docs.map((v) => ({
      contentHash: v.get('contentHash') as string,
      commit: v.get('commit') as string,
      path: v.get('path') as string,
      syncedAt: iso(v.get('syncedAt')),
    })),
  };
}

// ---------- Plans (read only) ----------

/**
 * Free / Premium by capability, from the catalogue and capabilities in code plus the live tiers
 * in `config/features`. Changes are made in "Tính năng & Premium" only — this never writes.
 */
export async function productPlans(db: Firestore, staff: Staff | null) {
  requireStaff(staff, 'product.view');
  const [tiers, features, conflicts, decisions] = await Promise.all([
    liveTiers(db),
    db.collection(C.features).where('removed', '==', false).get(),
    openConflicts(db),
    db.getAll(...['D-075', 'D-089', 'D-147', 'D-150', 'D-153'].map((x) => db.collection(C.decisions).doc(x))),
  ]);
  const byHub = new Map<string, string[]>();
  for (const d of features.docs) {
    const hub = d.get('hubKey') as string | null;
    if (hub) byHub.set(hub, [...(byHub.get(hub) ?? []), d.id]);
  }
  return {
    catalogue: featureCatalogue.map((f) => ({
      key: f.key,
      group: f.group,
      defaultTier: f.defaultTier,
      liveTier: tiers[f.key] ?? null,
      credits: f.credits,
      flags: [...f.flags],
      capabilities: [...f.capabilities],
      features: byHub.get(f.key) ?? [],
    })),
    capabilities: capabilities.map((c) => ({
      key: c,
      free: freeCapabilities.includes(c),
      premium: premiumCapabilities.includes(c),
      credits: creditCapabilities.includes(c),
    })),
    conflicts: conflicts.filter((c) => c.topic === 'tier' || c.topic === 'plan_model'),
    decisions: decisions
      .filter((d) => d.exists)
      .map((d) => ({ id: d.id, title: d.get('title') as string, date: d.get('date') as string | null })),
  };
}

// ---------- Overview ----------

export async function productOverview(db: Firestore, staff: Staff | null) {
  requireStaff(staff, 'product.view');
  const [{ features }, sources, changeSets, recentDecisions] = await Promise.all([
    productFeatures(db, staff),
    db.collection(C.sources).where('status', '==', 'active').select('authority').get(),
    db.collection(C.changeSets).orderBy('createdAt', 'desc').limit(5).get(),
    db.collection(C.decisions).where('kind', '==', 'D').get(),
  ]);
  const count = <K extends string>(pick: (f: (typeof features)[number]) => K) => {
    const out: Record<string, number> = {};
    for (const f of features) out[pick(f)] = (out[pick(f)] ?? 0) + 1;
    return out;
  };
  const lastApplied = changeSets.docs.find((d) => d.get('status') === 'approved');
  return {
    total: features.length,
    byLifecycle: count((f) => f.lifecycle),
    byPillar: count((f) => f.pillar),
    byPillarLifecycle: count((f) => `${f.pillar}:${f.lifecycle}`),
    byTier: count((f) => f.tier ?? 'none'),
    byBand: count((f) => f.band),
    needVerification: features.filter((f) => f.verification === 'unverified' || f.verification === 'code_read').length,
    released: features.filter((f) => f.release === 'released').length,
    staleFeatures: features.filter((f) => f.stale > 0).length,
    openConflicts: features.reduce((n, f) => n + f.conflicts, 0),
    sources: sources.size,
    pending: changeSets.docs.filter((d) => d.get('status') === 'pending').length,
    lastSync: lastApplied
      ? {
          revision: lastApplied.get('revision') as string,
          at: iso(lastApplied.get('reviewedAt')),
          by: lastApplied.get('reviewedByName') as string,
        }
      : null,
    recentDecisions: recentDecisions.docs
      .map((d) => d.data() as ProductDecisionRecord)
      .sort((a, b) => b.id.localeCompare(a.id))
      .slice(0, 5)
      .map((r) => ({ id: r.id, title: r.title, date: r.date })),
    recentChanges: changeSets.docs.map((d) => ({
      id: d.id,
      status: d.get('status') as string,
      revision: d.get('revision') as string,
      at: iso(d.get('createdAt')),
      summary: d.get('summary') as ChangeSetSummary,
    })),
  };
}
