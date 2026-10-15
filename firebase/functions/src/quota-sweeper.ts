import type { Firestore, Timestamp } from 'firebase-admin/firestore';
import { releaseQuotaNow } from './quota.js';

/**
 * AI summaries hold a quota reservation only for the length of one model call (≤ 60 s). If the
 * function dies between reserve and settle, the unit would stay reserved until the window ends
 * (brief p.10: release only once the work is known to be over). Reservations older than
 * [olderThanMinutes] are released here, once; a late commit then finds them released and is a
 * no-op. Video reservations are left to the keepsake sweeper, which checks the job's lease; assistant
 * task reservations to `sweepAssistant`.
 */
export async function sweepAiReservations(
  db: Firestore,
  now: Date,
  olderThanMinutes = 30,
): Promise<number> {
  const cutoff = now.getTime() - olderThanMinutes * 60_000;
  const snap = await db.collectionGroup('quotaOps').where('state', '==', 'reserved').get();
  let released = 0;
  for (const d of snap.docs) {
    const features = (d.get('features') as string[] | undefined) ?? [d.get('feature') as string];
    // D-075 #1: summaries now reserve in the assistant pool under their summary id (`su_*`);
    // assistant chat tasks (`tk_*` holders) are left to `sweepAssistant`, which checks the task.
    const summary = d.id.startsWith('su_') && features.every((f) => f === 'assistant');
    if (!summary && !features.every((f) => f.startsWith('ai_'))) continue;
    const at = d.get('reservedAt') as Timestamp | undefined;
    if (!at || at.toMillis() >= cutoff) continue;
    const r = await releaseQuotaNow(db, {
      familyId: d.get('familyId') as string,
      reservationId: d.id,
      reason: 'swept',
      now,
    });
    if (r.outcome === 'released') released += 1;
  }
  return released;
}
