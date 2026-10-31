import {
  productConflictActSchema,
  productConflictsQuerySchema,
  productDecisionRefSchema,
  productDecisionsQuerySchema,
  productDraftActSchema,
  productJourneyRefSchema,
  productOpportunityStatusSchema,
  productSaveOpportunitySchema,
  productSectionRefSchema,
  staffCan,
  type FeatureSection,
  type OpportunityStatus,
  type ProductConflictRecord,
  type ProductDecisionRecord,
  type ProductJourneyRecord,
  type ProductOpportunity,
} from '@child-life/contracts';
import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { fold } from './product-hub-ingest.js';
import { parse, requireStaff, staffAudit, staffLevelsOf, StaffError, type Staff } from './staff.js';

/**
 * Sản phẩm · Phase 3 (D-155, doc 09): decisions browsed by id with their supersession chain,
 * user journeys, opportunities (proposed → triaged → accepted / declined → done), conflict
 * actions and section history. Approving an opportunity or closing a conflict needs Duyệt and a
 * second person (the Owner may approve their own, D-155 #3). Nothing here writes `config/*` or
 * the business map: an accepted opportunity is a product intention, not an owner decision.
 */

const iso = (v: unknown): string | null =>
  v instanceof Date ? v.toISOString() : ((v as { toDate?: () => Date })?.toDate?.().toISOString() ?? (typeof v === 'string' ? v : null));

const isOwner = (s: Staff) => s.roles.includes('owner');

// ---------- Decisions ----------

export async function listDecisions(db: Firestore, staff: Staff | null, data: unknown) {
  requireStaff(staff, 'product.view');
  const q = parse(productDecisionsQuerySchema, data ?? {});
  const snap = await db.collection('productDecisions').get();
  const all = snap.docs.map((d) => d.data() as ProductDecisionRecord);
  const supersededBy = new Map<string, string[]>();
  const resolvedBy = new Map<string, string[]>();
  for (const r of all) {
    for (const x of r.supersedes) supersededBy.set(x, [...(supersededBy.get(x) ?? []), r.id]);
    for (const x of r.resolves) resolvedBy.set(x, [...(resolvedBy.get(x) ?? []), r.id]);
  }
  const needle = q.q ? fold(q.q) : '';
  const rows = all
    .filter((r) => !q.kind || r.kind === q.kind)
    .filter((r) => !q.status || r.status === q.status)
    .filter((r) => !q.feature || r.features.includes(q.feature))
    .filter((r) => !needle || r.id.toLowerCase() === needle || fold(`${r.title} ${r.text}`).includes(needle))
    .map((r) => ({
      id: r.id,
      kind: r.kind,
      title: r.title,
      excerpt: r.text.length > 280 ? `${r.text.slice(0, 279)}…` : r.text,
      date: r.date,
      status: r.status,
      features: r.features,
      resolves: r.resolves,
      supersedes: r.supersedes,
      supersededBy: supersededBy.get(r.id) ?? [],
      resolvedBy: resolvedBy.get(r.id) ?? [],
      line: r.source.line,
    }))
    .sort((a, b) => b.id.localeCompare(a.id));
  // Open questions and gaps grouped by feature, "—" for those linked to none.
  const open: Record<string, string[]> = {};
  for (const r of all) {
    if ((r.kind !== 'Q' && r.kind !== 'G') || r.status !== 'open') continue;
    for (const f of r.features.length ? r.features : ['—']) open[f] = [...(open[f] ?? []), r.id];
  }
  return { decisions: rows, openByFeature: open, total: all.length };
}

export async function getDecision(db: Firestore, staff: Staff | null, data: unknown) {
  requireStaff(staff, 'product.view');
  const { id } = parse(productDecisionRefSchema, data);
  const doc = await db.collection('productDecisions').doc(id).get();
  if (!doc.exists) throw new StaffError('not-found', 'not-found');
  const r = doc.data() as ProductDecisionRecord;
  const [laterSupersede, laterResolve, opportunities] = await Promise.all([
    db.collection('productDecisions').where('supersedes', 'array-contains', id).get(),
    db.collection('productDecisions').where('resolves', 'array-contains', id).get(),
    db.collection('productOpportunities').where('decisions', 'array-contains', id).get(),
  ]);
  return {
    decision: { ...r, syncedAt: undefined },
    supersededBy: laterSupersede.docs.map((d) => d.id).sort(),
    resolvedBy: laterResolve.docs.map((d) => d.id).sort(),
    opportunities: opportunities.docs.map((d) => ({ id: d.id, title: d.get('title') as string, status: d.get('status') as string })),
  };
}

// ---------- Journeys ----------

export async function listJourneys(db: Firestore, staff: Staff | null) {
  requireStaff(staff, 'product.view');
  const snap = await db.collection('productJourneys').get();
  return {
    journeys: snap.docs
      .map((d) => d.data() as ProductJourneyRecord)
      .map((j) => ({
        id: j.id,
        name: j.name,
        goal: j.goal,
        steps: j.steps.length,
        features: j.features,
        verification: j.verification,
        metrics: j.metrics,
        revision: j.revision,
      }))
      .sort((a, b) => a.id.localeCompare(b.id)),
  };
}

export async function getJourney(db: Firestore, staff: Staff | null, data: unknown) {
  requireStaff(staff, 'product.view');
  const { id } = parse(productJourneyRefSchema, data);
  const doc = await db.collection('productJourneys').doc(id).get();
  if (!doc.exists) throw new StaffError('not-found', 'not-found');
  const j = doc.data() as ProductJourneyRecord;
  const features = j.features.length
    ? await db.getAll(...j.features.map((f) => db.collection('productFeatures').doc(f)))
    : [];
  return {
    journey: j,
    features: features
      .filter((d) => d.exists)
      .map((d) => ({
        id: d.id,
        name: d.get('name') as { vi: string; en: string },
        lifecycle: d.get('lifecycle') as string,
        verification: d.get('verification') as string,
      })),
  };
}

// ---------- Opportunities ----------

const OPP = 'productOpportunities';

const opportunityOf = (id: string, d: FirebaseFirestore.DocumentData): ProductOpportunity => ({
  id,
  title: d.title,
  feature: d.feature ?? null,
  problem: d.problem,
  evidence: d.evidence ?? [],
  hypothesis: d.hypothesis ?? '',
  proposal: d.proposal ?? '',
  impact: d.impact,
  effort: d.effort,
  priority: d.priority,
  successCriteria: d.successCriteria ?? '',
  decisions: d.decisions ?? [],
  status: d.status,
  fromDraft: d.fromDraft ?? null,
  createdBy: d.createdByName,
  createdByUid: d.createdByUid,
  createdAt: iso(d.createdAt),
  updatedAt: iso(d.updatedAt),
  history: (d.history ?? []) as ProductOpportunity['history'],
});

export async function listOpportunities(db: Firestore, staff: Staff | null) {
  const s = requireStaff(staff, 'product.view');
  const snap = await db.collection(OPP).orderBy('updatedAt', 'desc').limit(200).get();
  return {
    opportunities: snap.docs.map((d) => opportunityOf(d.id, d.data())),
    canEdit: staffCan(staffLevelsOf(s), 'product.edit'),
    canApprove: staffCan(staffLevelsOf(s), 'product.approve'),
  };
}

/** Create or edit (Sửa). Editing never changes the status; accepted or declined ones are frozen. */
export async function saveOpportunity(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const s = requireStaff(staff, 'product.edit');
  const req = parse(productSaveOpportunitySchema, data);
  const { id, ...fields } = req;
  if (id) {
    const ref = db.collection(OPP).doc(id);
    await db.runTransaction(async (tx) => {
      const cur = await tx.get(ref);
      if (!cur.exists) throw new StaffError('not-found', 'not-found');
      if (['accepted', 'declined', 'done'].includes(cur.get('status') as string)) {
        throw new StaffError('failed-precondition', 'opportunity-closed');
      }
      tx.update(ref, { ...fields, updatedAt: now });
      staffAudit(tx, db, s, { action: 'product.opportunity.edit', category: 'product', target: id, reason: null }, now);
    });
    return { id };
  }
  const ref = db.collection(OPP).doc();
  const batch = db.batch();
  batch.set(ref, {
    ...fields,
    status: 'proposed',
    fromDraft: null,
    createdByUid: s.uid,
    createdByName: s.name,
    createdAt: now,
    updatedAt: now,
    history: [{ from: null, to: 'proposed', by: s.name, at: now.toISOString(), note: '' }],
  });
  staffAudit(batch, db, s, { action: 'product.opportunity.create', category: 'product', target: ref.id, reason: null }, now);
  await batch.commit();
  return { id: ref.id };
}

const transitions: Record<OpportunityStatus, OpportunityStatus[]> = {
  proposed: ['triaged', 'declined'],
  triaged: ['accepted', 'declined', 'proposed'],
  accepted: ['done', 'triaged'],
  declined: ['proposed'],
  done: [],
};

/**
 * Status changes. Triage, reopening and "done" need Sửa; accepting or declining needs Duyệt and
 * is never the creator's own call, except the Owner's (D-155 #3).
 */
export async function setOpportunityStatus(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const req = parse(productOpportunityStatusSchema, data);
  const decisive = req.status === 'accepted' || req.status === 'declined';
  const s = requireStaff(staff, decisive ? 'product.approve' : 'product.edit');
  const ref = db.collection(OPP).doc(req.id);
  await db.runTransaction(async (tx) => {
    const cur = await tx.get(ref);
    if (!cur.exists) throw new StaffError('not-found', 'not-found');
    const from = cur.get('status') as OpportunityStatus;
    if (!transitions[from].includes(req.status)) throw new StaffError('failed-precondition', 'bad-transition');
    if (decisive && cur.get('createdByUid') === s.uid && !isOwner(s)) {
      throw new StaffError('failed-precondition', 'own-work');
    }
    const history = [...((cur.get('history') as ProductOpportunity['history']) ?? []), { from, to: req.status, by: s.name, at: now.toISOString(), note: req.note }].slice(-50);
    tx.update(ref, { status: req.status, updatedAt: now, history });
    staffAudit(tx, db, s, { action: `product.opportunity.${req.status}`, category: 'product', target: req.id, reason: req.note || null, detail: { from } }, now);
  });
  return { ok: true };
}

/** A Copilot draft becomes a proposed opportunity (promote) or is set aside (dismiss). */
export async function actDraft(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const s = requireStaff(staff, 'product.edit');
  const req = parse(productDraftActSchema, data);
  const ref = db.collection('productDrafts').doc(req.id);
  return db.runTransaction(async (tx) => {
    const cur = await tx.get(ref);
    if (!cur.exists) throw new StaffError('not-found', 'not-found');
    if (cur.get('status') !== 'draft') throw new StaffError('failed-precondition', 'not-pending');
    if (req.action === 'dismiss') {
      tx.update(ref, { status: 'dismissed', closedBy: s.name, closedAt: now });
      staffAudit(tx, db, s, { action: 'product.draft.dismiss', category: 'product', target: req.id, reason: null }, now);
      return { opportunityId: null };
    }
    const opp = db.collection(OPP).doc();
    const body = cur.get('body') as string;
    tx.set(opp, {
      title: cur.get('title'),
      feature: cur.get('feature') ?? null,
      problem: body.slice(0, 4000),
      evidence: cur.get('evidence') ?? [],
      hypothesis: cur.get('type') === 'hypothesis' ? body.slice(0, 2000) : '',
      proposal: '',
      impact: 'medium',
      effort: 'm',
      priority: 'p2',
      successCriteria: '',
      decisions: ((cur.get('evidence') as string[]) ?? []).filter((x) => /^D-\d{3}$/.test(x)).slice(0, 20),
      status: 'proposed',
      fromDraft: req.id,
      createdByUid: s.uid,
      createdByName: s.name,
      createdAt: now,
      updatedAt: now,
      history: [{ from: null, to: 'proposed', by: s.name, at: now.toISOString(), note: `draft ${req.id}` }],
    });
    tx.update(ref, { status: 'promoted', opportunityId: opp.id, closedBy: s.name, closedAt: now });
    staffAudit(tx, db, s, { action: 'product.draft.promote', category: 'product', target: req.id, reason: null, detail: { opportunity: opp.id } }, now);
    return { opportunityId: opp.id };
  });
}

// ---------- Conflicts ----------

export async function listConflicts(db: Firestore, staff: Staff | null, data: unknown) {
  const s = requireStaff(staff, 'product.view');
  const q = parse(productConflictsQuerySchema, data ?? {});
  const snap = await db.collection('productConflicts').get();
  const rows = snap.docs
    .map((d) => ({ ...(d.data() as ProductConflictRecord), createdAt: iso(d.get('createdAt')), history: (d.get('history') as unknown[]) ?? [], resolution: (d.get('resolution') as unknown) ?? null }))
    .filter((c) => q.status === 'all' || c.status === q.status)
    .sort((a, b) => (b.createdAt ?? '').localeCompare(a.createdAt ?? ''));
  return { conflicts: rows, canApprove: staffCan(staffLevelsOf(s), 'product.approve'), canEdit: staffCan(staffLevelsOf(s), 'product.edit') };
}

const conflictMoves: Record<string, { from: ProductConflictRecord['status'][]; to: ProductConflictRecord['status']; level: 'product.edit' | 'product.approve' }> = {
  accept: { from: ['suggested'], to: 'open', level: 'product.edit' },
  dismiss: { from: ['suggested'], to: 'dismissed', level: 'product.edit' },
  resolve: { from: ['open'], to: 'resolved', level: 'product.approve' },
  accept_difference: { from: ['open'], to: 'accepted_difference', level: 'product.approve' },
  reopen: { from: ['resolved', 'accepted_difference', 'dismissed'], to: 'open', level: 'product.approve' },
};

/**
 * A suggested conflict is confirmed (→ open) or dismissed with Sửa; an open one is closed —
 * resolved, or the difference accepted on purpose — with Duyệt, a note and, when there is one,
 * the decision that settles it. History is kept; nothing is deleted.
 */
export async function actConflict(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  const req = parse(productConflictActSchema, data);
  const move = conflictMoves[req.action]!;
  const s = requireStaff(staff, move.level);
  if ((req.action === 'resolve' || req.action === 'accept_difference') && !req.note && !req.decision) {
    throw new StaffError('invalid-argument', 'note-required');
  }
  const ref = db.collection('productConflicts').doc(req.id);
  await db.runTransaction(async (tx) => {
    const cur = await tx.get(ref);
    if (!cur.exists) throw new StaffError('not-found', 'not-found');
    const from = cur.get('status') as ProductConflictRecord['status'];
    if (!move.from.includes(from)) throw new StaffError('failed-precondition', 'bad-transition');
    tx.update(ref, {
      status: move.to,
      resolution: move.to === 'resolved' || move.to === 'accepted_difference' ? { note: req.note, decision: req.decision, by: s.name, at: now.toISOString() } : null,
      history: FieldValue.arrayUnion({ from, to: move.to, by: s.name, at: now.toISOString(), note: req.note, decision: req.decision }),
    });
    staffAudit(tx, db, s, { action: `product.conflict.${req.action}`, category: 'product', target: req.id, reason: req.note || null, detail: { from, to: move.to, decision: req.decision } }, now);
  });
  return { ok: true };
}

// ---------- Section history ----------

export async function sectionVersions(db: Firestore, staff: Staff | null, data: unknown) {
  requireStaff(staff, 'product.view');
  const req = parse(productSectionRefSchema, data);
  const ref = db.collection('productFeatures').doc(req.feature).collection('productSections').doc(req.key);
  const [cur, versions] = await Promise.all([ref.get(), ref.collection('versions').orderBy('version', 'desc').limit(30).get()]);
  const approved = (cur.get('approved') as FeatureSection['approved']) ?? null;
  return {
    current: approved,
    versions: versions.docs.map((d) => d.data() as NonNullable<FeatureSection['approved']>),
  };
}
