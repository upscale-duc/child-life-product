import { createHash } from 'node:crypto';

/** Stable 0–99 bucket of a family for percent rollouts (the same as AI story drafts). */
export function familyBucket(familyId: string): number {
  return parseInt(createHash('sha256').update(familyId).digest('hex').slice(0, 8), 16) % 100;
}
