import { createHash } from 'node:crypto';
import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { localDateIn } from '@child-life/contracts';

export const productOutcomeKinds = [
  'careConfirmed',
  'memoryReady',
  'storySaved',
  'keepsakeFiled',
] as const;
export type ProductOutcomeKind = (typeof productOutcomeKinds)[number];

/** MET-01: operational identity stays inside the family's/baby's gated data. The
 * dashboard receives counts only. Retry receipts count a logical completion once. */
export async function recordProductOutcome(
  db: Firestore,
  babyId: string,
  sourceId: string,
  kind: ProductOutcomeKind,
  at: Date,
): Promise<boolean> {
  const day = localDateIn('Asia/Ho_Chi_Minh', at);
  const hash = createHash('sha256').update(`${kind}|${sourceId}`).digest('hex');
  return db.runTransaction(async (tx) => {
    const baby = await tx.get(db.doc(`babies/${babyId}`));
    if (!baby.exists || baby.get('state') === 'deleting') return false;
    const familyId = baby.get('familyId') as string | undefined;
    if (!familyId) return false;
    const marker = db.doc(`babies/${babyId}/outcomeReceipts/${hash}`);
    const familyDay = db.doc(`families/${familyId}/outcomeDays/${day}`);
    const [seen, activity] = await Promise.all([tx.get(marker), tx.get(familyDay)]);
    if (seen.exists) return false;
    tx.create(marker, { kind, at });
    tx.set(familyDay, { day, [kind]: true }, { merge: true });
    tx.set(
      db.doc(`productOutcomesDaily/${day}`),
      {
        day,
        version: 1,
        // All qualified families that completed any outcome that day: a known denominator.
        qualifiedFamilies: FieldValue.increment(activity.exists ? 0 : 1),
        actions: { [kind]: FieldValue.increment(1) },
        households: { [kind]: FieldValue.increment(activity.get(kind) === true ? 0 : 1) },
      },
      { merge: true },
    );
    return true;
  });
}
