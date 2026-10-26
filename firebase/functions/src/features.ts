import type { Firestore, Timestamp } from 'firebase-admin/firestore';
import {
  featureAccessRequestSchema,
  featureTierOf,
  type FeatureAccess,
} from '@child-life/contracts';
import { familyFeatureOn, loadFamilyEntitlements, serverGrantEnvironment } from './entitlements.js';

export { familyBucket } from './bucket.js';

export class FeatureError extends Error {
  constructor(
    readonly code: 'invalid-argument' | 'permission-denied' | 'not-found',
    readonly reason: string,
  ) {
    super(reason);
  }
}

/**
 * P-148: per-family features for one of the caller's babies. Tự lưu (D-066) and Kỷ niệm 2.0
 * (D-068) are for Cùng nuôi and follow the hub's rule (D-089, `familyFeatureDecision`): their
 * kill switch and rollout (`auto_save`, `milestone_cards`, `memory_story`), the admin override,
 * the tier (Beta: picked families and the rollout; Premium: every family with Premium) and the
 * 30-day grace of a move to Premium.
 */
export async function featureAccess(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<FeatureAccess> {
  const parsed = featureAccessRequestSchema.safeParse(data);
  if (!parsed.success) throw new FeatureError('invalid-argument', 'bad-request');
  const { babyId } = parsed.data;
  const member = await db.doc(`babies/${babyId}/members/${uid}`).get();
  const until = member.get('accessUntilAt') as Timestamp | null | undefined;
  if (
    !member.exists ||
    member.get('status') !== 'active' ||
    (until && until.toMillis() <= now.getTime())
  ) {
    throw new FeatureError('permission-denied', 'not-a-member');
  }
  const familyId = (await db.doc(`babies/${babyId}`).get()).get('familyId') as string | undefined;
  if (!familyId) throw new FeatureError('not-found', 'no-family');
  if (member.get('role') !== 'coParent') {
    return { autoSave: false, milestoneCards: false, memoryStory: false, autoSaveBeta: false };
  }
  // A missing or older document reads as every flag off (or its default), never as an error.
  const state = await loadFamilyEntitlements(db, familyId, now, serverGrantEnvironment());
  return {
    autoSave: familyFeatureOn(state, 'auto_save'),
    milestoneCards: familyFeatureOn(state, 'milestone_cards'),
    memoryStory: familyFeatureOn(state, 'memory_story'),
    // D-122: the badge follows the tier staff set on the portal, not a constant in the app.
    autoSaveBeta: featureTierOf(state.hub, 'auto_save') === 'beta',
  };
}
