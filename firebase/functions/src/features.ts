import { createHash } from 'node:crypto';
import type { Firestore, Timestamp } from 'firebase-admin/firestore';
import {
  featureAccessRequestSchema,
  flagsSchema,
  isFlagOnForFamily,
  type FeatureAccess,
} from '@child-life/contracts';

export class FeatureError extends Error {
  constructor(
    readonly code: 'invalid-argument' | 'permission-denied' | 'not-found',
    readonly reason: string,
  ) {
    super(reason);
  }
}

/** Stable 0–99 bucket of a family for percent rollouts (the same as AI story drafts). */
export function familyBucket(familyId: string): number {
  return parseInt(createHash('sha256').update(familyId).digest('hex').slice(0, 8), 16) % 100;
}

/**
 * P-148: per-family features for one of the caller's babies. Tự lưu (D-066) and Kỷ niệm 2.0
 * (D-068) are for Cùng nuôi and follow their flags (`auto_save`, `milestone_cards`, `memory_story`):
 * off, the families picked in A10 (and families marked `internal`), a share of families, or all.
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
  // A missing or older document reads as every flag off (or its default), never as an error.
  const flags = flagsSchema.safeParse((await db.doc('config/flags').get()).data() ?? {});
  if (!flags.success || member.get('role') !== 'coParent') {
    return { autoSave: false, milestoneCards: false, memoryStory: false };
  }
  let internal: boolean | undefined;
  const on = async (key: 'auto_save' | 'milestone_cards' | 'memory_story') => {
    const flag = flags.data[key];
    if (flag.enabled && flag.scope === 'internal' && internal === undefined) {
      internal = (await db.doc(`families/${familyId}`).get()).get('internal') === true;
    }
    return isFlagOnForFamily(flag, familyId, familyBucket(familyId), internal ?? false);
  };
  return {
    autoSave: await on('auto_save'),
    milestoneCards: await on('milestone_cards'),
    memoryStory: await on('memory_story'),
  };
}
