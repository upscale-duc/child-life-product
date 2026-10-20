import { dayBoundsIn, addDaysIso, localDateIn } from '@child-life/contracts';
import type { Firestore, QueryDocumentSnapshot } from 'firebase-admin/firestore';

/** P-172 D2: generation is distinct from impression; no person/baby identifier is written. */
export async function aggregatePersonalizationContent(db: Firestore, now: Date) {
  const day = addDaysIso(localDateIn('Asia/Ho_Chi_Minh', now), -1);
  const bounds = dayBoundsIn('Asia/Ho_Chi_Minh', day);
  const generated: Record<string, { contentId: string; version: number; count: number }> = {};
  let cursor: QueryDocumentSnapshot | undefined;
  for (;;) {
    let query = db
      .collectionGroup('recommendations')
      .where('generatedAt', '>=', bounds.start.toISOString())
      .where('generatedAt', '<', bounds.end.toISOString())
      .orderBy('generatedAt')
      .limit(500);
    if (cursor) query = query.startAfter(cursor);
    const page = await query.get();
    for (const row of page.docs) {
      const contentId = row.get('contentId') as string;
      const version = row.get('contentVersion') as number;
      if (
        !/^act_[a-z0-9_]{2,40}$/.test(contentId ?? '') ||
        !Number.isInteger(version) ||
        version < 1
      )
        continue;
      const entry = (generated[`${contentId}__v${version}`] ??= { contentId, version, count: 0 });
      entry.count++;
    }
    if (page.size < 500) break;
    cursor = page.docs.at(-1);
  }
  // Replace this one field atomically; do not merge stale nested counters on retries.
  const ref = db.doc(`contentStatsDaily/${day}`);
  await db.runTransaction(async (tx) => {
    const old = await tx.get(ref);
    tx.set(ref, { ...old.data(), day, generated, aggregatedAt: now.toISOString() });
  });
  return { day, items: Object.keys(generated).length };
}
