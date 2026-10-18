import {
  contentPolicySchema,
  defaultContentPolicy,
  setContentPolicyRequestSchema,
  type ContentPolicy,
} from '@child-life/contracts';
import type { Firestore } from 'firebase-admin/firestore';
import { StaffError, parse, requireStaff, staffAudit, type Staff } from './staff.js';

/**
 * How content and reference data are approved (`config/content`, D-079): the two-person rule and
 * the prod review gate by default; the Owner may relax both while they are the only staff.
 */
export async function readContentPolicy(db: Firestore): Promise<ContentPolicy> {
  const parsed = contentPolicySchema.safeParse((await db.doc('config/content').get()).data() ?? {});
  return parsed.success ? parsed.data : defaultContentPolicy;
}

const isOwner = (s: Staff) => s.roles.includes('owner');

/**
 * D-058 / P-138: whoever wrote a version cannot approve it, except the Owner when
 * `ownerSelfApprove` is on (D-079). The audit entry then names the same person twice.
 */
export const mayApproveOwn = (s: Staff, policy: ContentPolicy): boolean =>
  policy.ownerSelfApprove && isOwner(s);

/** The review gate in force: prod only, and only while the policy keeps it. */
export const reviewRequired = (prod: boolean, policy: ContentPolicy): boolean =>
  prod && policy.reviewRequiredOnProd;

/** `staffContentPolicy`: anyone who sees content reads the switches (the portal shows them). */
export async function contentPolicyView(db: Firestore, staff: Staff | null) {
  const s = requireStaff(staff, 'content.view');
  return { ...(await readContentPolicy(db)), canChange: isOwner(s) };
}

/** `staffSetContentPolicy`: the Owner only, with a reason (P-139); audited under "content". */
export async function setContentPolicy(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
): Promise<ContentPolicy> {
  const s = requireStaff(staff, 'content.approve');
  if (!isOwner(s)) throw new StaffError('permission-denied', 'owner-only');
  const req = parse(setContentPolicyRequestSchema, data);
  const ref = db.doc('config/content');
  return db.runTransaction(async (tx) => {
    const before = contentPolicySchema.safeParse((await tx.get(ref)).data() ?? {});
    const current = before.success ? before.data : defaultContentPolicy;
    const next: ContentPolicy = {
      ownerSelfApprove: req.ownerSelfApprove ?? current.ownerSelfApprove,
      reviewRequiredOnProd: req.reviewRequiredOnProd ?? current.reviewRequiredOnProd,
    };
    tx.set(ref, { ...next, updatedAt: now, updatedBy: s.uid });
    staffAudit(
      tx,
      db,
      s,
      {
        action: 'content.policy',
        category: 'content',
        target: 'config/content',
        reason: req.reason,
        detail: { before: current, after: next },
      },
      now,
    );
    return next;
  });
}
