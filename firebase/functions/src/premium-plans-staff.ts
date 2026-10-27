import { randomBytes } from 'node:crypto';
import {
  adjustUsageSchema,
  adjustmentApprovalThreshold,
  decideProposalSchema,
  entitlementsConfigSchema,
  proposePlansSchema,
  refundVideoJobSchema,
  type EntitlementsConfig,
  type GrantEnvironment,
  type PremiumPlans,
  type StaffProposal,
} from '@child-life/contracts';
import { Timestamp, type Firestore, type Transaction } from 'firebase-admin/firestore';
import { assistantPool } from './assistant-usage.js';
import { mayApproveOwn, readContentPolicy } from './content-policy.js';
import {
  flagOn,
  loadFamilyEntitlements,
  readEntitlementsConfig,
  serverGrantEnvironment,
  type EntitlementContext,
} from './entitlements.js';
import { renderJobCode } from './premium-ops.js';
import { adjustQuotaLimit } from './quota.js';
import {
  familyCode,
  familyIdsOf,
  parse,
  requireStaff,
  StaffError,
  staffAudit,
  type Staff,
} from './staff.js';
import {
  adjustVideoBonus,
  readForSettle,
  refundVideoInTx,
  videoWindowFor,
  windowRef,
} from './video-quota.js';

/**
 * Portal Premium v2 (PT01–PT04, D-101): a plans version and a large adjustment take effect only
 * once a second person approves them (D-058, the Owner self-approve switch of D-079 applies);
 * small adjustments and video refunds apply at once. Everything is audited under "premium"
 * with its reason. Proposals live in `premiumProposals/{id}` (server only, Rules deny).
 */

const proposals = (db: Firestore) => db.collection('premiumProposals');
const newId = (prefix: 'pp' | 'pa') => `${prefix}_${randomBytes(9).toString('base64url')}`;
const iso = (v: unknown) =>
  v instanceof Timestamp ? v.toDate().toISOString() : v instanceof Date ? v.toISOString() : null;

/** `staffPremiumProposals`: the pending and recent proposals (newest first). */
export async function listProposals(db: Firestore, staff: Staff | null): Promise<StaffProposal[]> {
  const s = requireStaff(staff, 'premium.view');
  const snap = await proposals(db).orderBy('at', 'desc').limit(30).get();
  return snap.docs.map((d) => {
    const adjustment = d.get('adjustment') as {
      familyId: string;
      feature: 'lumi' | 'video';
      amount: number;
    } | null;
    return {
      id: d.id,
      kind: d.get('kind') as StaffProposal['kind'],
      status: d.get('status') as StaffProposal['status'],
      version: (d.get('version') as string | null | undefined) ?? null,
      plans: (d.get('plans') as PremiumPlans | null | undefined) ?? null,
      adjustment: adjustment
        ? {
            code: familyCode(adjustment.familyId),
            feature: adjustment.feature,
            amount: adjustment.amount,
          }
        : null,
      reason: d.get('reason') as string,
      by: d.get('byName') as string,
      at: iso(d.get('at')) ?? '',
      decidedBy: (d.get('decidedByName') as string | null | undefined) ?? null,
      decidedAt: iso(d.get('decidedAt')),
      mine: d.get('by') === s.uid,
    };
  });
}

/** PT03 `staffProposePlans`: a new plans version, waiting for a second approver. */
export async function proposePlans(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
): Promise<{ id: string }> {
  const s = requireStaff(staff, 'premium.config');
  const req = parse(proposePlansSchema, data);
  const config = await readEntitlementsConfig(db);
  if (req.version === config.plansVersion) throw new StaffError('invalid-argument', 'same-version');
  const id = newId('pp');
  await db.runTransaction(async (tx) => {
    tx.create(proposals(db).doc(id), {
      kind: 'plans',
      status: 'pending',
      version: req.version,
      plans: req.plans,
      adjustment: null,
      reason: req.reason,
      by: s.uid,
      byName: s.name,
      at: now,
    });
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'premium.plans.propose',
        category: 'premium',
        target: req.version,
        reason: req.reason,
        detail: { before: config.plans, after: req.plans },
      },
      now,
    );
  });
  return { id };
}

interface AdjustmentTarget {
  familyId: string;
  feature: 'lumi' | 'video';
  amount: number;
}

/** Applies an adjustment to the family's current Lumi or video window (inside [tx]). */
async function applyAdjustment(
  tx: Transaction,
  db: Firestore,
  target: AdjustmentTarget,
  adjustmentId: string,
  now: Date,
  environment: GrantEnvironment,
): Promise<{ before: number; after: number }> {
  const family = await loadFamilyEntitlements(db, target.familyId, now, environment);
  if (target.feature === 'lumi') {
    const ctx = { ...family, uid: '', babyId: '', member: null } as EntitlementContext;
    const pool = await assistantPool(
      db,
      {
        ctx,
        familyId: target.familyId,
        householdZone: family.family.timeZone ?? 'Asia/Ho_Chi_Minh',
      },
      now,
    );
    return adjustQuotaLimit(tx, db, {
      familyId: target.familyId,
      adjustmentId,
      request: pool.request,
      delta: target.amount,
      now,
    });
  }
  const baby = await db
    .collection('babies')
    .where('familyId', '==', target.familyId)
    .limit(1)
    .get();
  if (baby.empty) throw new StaffError('not-found', 'no-baby');
  const window = await videoWindowFor(
    db,
    target.familyId,
    baby.docs[0]!.id,
    family.config,
    environment,
    now,
  );
  if (window.unlimited) throw new StaffError('failed-precondition', 'video-unlimited');
  const snap = await tx.get(windowRef(db, target.familyId, window.id));
  return adjustVideoBonus(tx, db, target.familyId, window, snap, adjustmentId, target.amount, now);
}

/**
 * PT02 `staffAdjustUsage`: up to 50 credit / lượt applies now; more waits for a second approver.
 */
export async function adjustUsage(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<{ status: 'applied' | 'pending'; id: string; before?: number; after?: number }> {
  const s = requireStaff(staff, 'premium.grant');
  const req = parse(adjustUsageSchema, data);
  const familyId = (await familyIdsOf(db, [req.code]))[0]!;
  if (
    req.feature === 'video' &&
    flagOn(await loadFamilyEntitlements(db, familyId, now, environment), 'premium_v2')
  ) {
    throw new StaffError('failed-precondition', 'video-unlimited');
  }
  const target: AdjustmentTarget = { familyId, feature: req.feature, amount: req.amount };
  const id = newId('pa');
  if (Math.abs(req.amount) > adjustmentApprovalThreshold) {
    await db.runTransaction(async (tx) => {
      tx.create(proposals(db).doc(id), {
        kind: 'adjustment',
        status: 'pending',
        version: null,
        plans: null,
        adjustment: target,
        reason: req.reason,
        by: s.uid,
        byName: s.name,
        at: now,
      });
      staffAudit(
        tx,
        db,
        s,
        {
          action: 'premium.adjust.propose',
          category: 'premium',
          target: req.code,
          reason: req.reason,
          detail: { feature: req.feature, amount: req.amount },
        },
        now,
      );
    });
    return { status: 'pending', id };
  }
  const r = await db.runTransaction(async (tx) => {
    const applied = await applyAdjustment(tx, db, target, id, now, environment);
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'premium.adjust',
        category: 'premium',
        target: req.code,
        reason: req.reason,
        detail: { feature: req.feature, amount: req.amount, ...applied },
      },
      now,
    );
    return applied;
  });
  return { status: 'applied', id, ...r };
}

/** `staffDecideProposal`: a second person approves (applies) or rejects a proposal. */
export async function decideProposal(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<{ status: 'approved' | 'rejected' }> {
  const req = parse(decideProposalSchema, data);
  const ref = proposals(db).doc(req.id);
  const first = await ref.get();
  if (!first.exists) throw new StaffError('not-found', 'not-found');
  const kind = first.get('kind') as StaffProposal['kind'];
  const s = requireStaff(staff, kind === 'plans' ? 'premium.config' : 'premium.grant');
  const policy = await readContentPolicy(db);
  return db.runTransaction(async (tx) => {
    const p = await tx.get(ref);
    if (p.get('status') !== 'pending') throw new StaffError('failed-precondition', 'decided');
    if (req.approve && p.get('by') === s.uid && !mayApproveOwn(s, policy)) {
      throw new StaffError('permission-denied', 'second-approver');
    }
    let detail: Record<string, unknown> = {};
    if (req.approve && kind === 'plans') {
      const cfgRef = db.doc('config/entitlements');
      const parsed = entitlementsConfigSchema.safeParse((await tx.get(cfgRef)).data());
      if (!parsed.success) throw new StaffError('failed-precondition', 'config-invalid');
      const next: EntitlementsConfig = {
        ...parsed.data,
        plans: p.get('plans') as PremiumPlans,
        plansVersion: p.get('version') as string,
      };
      tx.set(cfgRef, next);
      detail = { from: parsed.data.plansVersion, to: next.plansVersion };
    }
    if (req.approve && kind === 'adjustment') {
      detail = await applyAdjustment(
        tx,
        db,
        p.get('adjustment') as AdjustmentTarget,
        p.id,
        now,
        environment,
      );
    }
    tx.update(ref, {
      status: req.approve ? 'approved' : 'rejected',
      decidedBy: s.uid,
      decidedByName: s.name,
      decidedAt: now,
      decisionReason: req.reason,
    });
    staffAudit(
      tx,
      db,
      s,
      {
        action: `premium.${kind}.${req.approve ? 'approve' : 'reject'}`,
        category: 'premium',
        target: p.id,
        reason: req.reason,
        detail,
      },
      now,
    );
    return { status: req.approve ? ('approved' as const) : ('rejected' as const) };
  });
}

/** PT04 `staffRefundVideoJob`: gives back the lượt of a video that came out wrong, once. */
export async function refundVideoJob(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
): Promise<{ outcome: 'refunded' | 'already' }> {
  const s = requireStaff(staff, 'premium.grant');
  const req = parse(refundVideoJobSchema, data);
  const familyId = (await familyIdsOf(db, [req.code]))[0]!;
  // The family's jobs, newest first (the existing familyId + createdAt index), matched by code.
  const jobs = await db
    .collectionGroup('keepsakeJobs')
    .where('familyId', '==', familyId)
    .where('createdAt', '>=', new Date(0))
    .orderBy('createdAt', 'desc')
    .limit(200)
    .get();
  const hit = jobs.docs.find((d) => renderJobCode(d.id) === req.job);
  if (!hit) throw new StaffError('not-found', 'not-found');
  return db.runTransaction(async (tx) => {
    const job = await tx.get(hit.ref);
    if (!job.exists || job.get('familyId') !== familyId)
      throw new StaffError('not-found', 'not-found');
    const quota = job.get('quota') as { reservationId?: string } | undefined;
    if (!quota?.reservationId) throw new StaffError('failed-precondition', 'no-quota');
    const reads = await readForSettle(tx, db, familyId, quota.reservationId);
    const outcome = refundVideoInTx(tx, reads, now);
    if (outcome === 'missing') throw new StaffError('failed-precondition', 'no-quota');
    if (outcome === 'refunded') {
      tx.update(job.ref, { refundedAt: now, refundedBy: s.uid });
      staffAudit(
        tx,
        db,
        s,
        {
          action: 'premium.video.refund',
          category: 'premium',
          target: req.code,
          reason: req.reason,
          detail: { job: req.job },
        },
        now,
      );
    }
    return { outcome };
  });
}
