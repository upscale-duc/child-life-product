import { Timestamp, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import {
  addDaysIso,
  cardAgeDays,
  chooseShown,
  computeInsights,
  insightRuleVersion,
  insightRulesFrom,
  insightWindows,
  localDateIn,
  nightBoundsIn,
  type CareType,
  type InsightKind,
  type InsightRecord,
  type InsightState,
} from '@child-life/contracts';
import {
  capabilityStateAsOwner,
  loadFamilyEntitlements,
  serverGrantEnvironment,
} from './entitlements.js';

/**
 * Hiểu con · "Điều đáng chú ý" (D-150, D-151; analysis `docs/product/hieu-con-insights-analysis.md`
 * §5): the server computes the insights once, stores them with their evidence in
 * `babies/{b}/insights/current`, and every surface (Hôm nay, Hiểu con, Thống kê, Lumi) reads that
 * one document. The rules are the pure functions of contracts `insights.ts`.
 *
 * When: `insightQueue/{babyId}.dueAt`. A care write schedules the next morning (30 min after the
 * night ends); an edit of a night already counted schedules a recompute in 10 minutes. The app
 * hides a card as soon as a record of its window changes (the stale check), so no old number is
 * shown in between.
 */

const DEFAULT_ZONE = 'Asia/Ho_Chi_Minh';
const MIN = 60_000;
const DAY = 86_400_000;
/** Debounce after an edit of a counted night: one recompute for a burst of corrections. */
export const insightEditDelayMs = 10 * MIN;
/** After the night ends (06:00), so the morning's first wake-up is usually logged. */
export const insightMorningDelayMs = 30 * MIN;
/** A baby with no care record for this long is not recomputed every morning. */
const idleAfterMs = 3 * DAY;

const insightDoc = (babyId: string) => `babies/${babyId}/insights/current`;

function recordOf(d: DocumentSnapshot): InsightRecord | null {
  if (d.get('deleted') === true) return null;
  const occurredAt = d.get('occurredAt');
  if (!(occurredAt instanceof Timestamp)) return null;
  const author = d.get('author') as { name?: unknown; relation?: unknown } | undefined;
  return {
    id: d.id,
    type: d.get('type') as CareType,
    occurredAt: occurredAt.toDate(),
    endedAt: (d.get('endedAt') as Timestamp | null | undefined)?.toDate() ?? null,
    data: (d.get('data') as Record<string, unknown> | undefined) ?? {},
    author:
      author && typeof author.name === 'string'
        ? {
            name: author.name,
            relation: typeof author.relation === 'string' ? author.relation : null,
          }
        : null,
  };
}

/** Whether the household may see the figures (D-150: `rhythm.advanced`). */
async function premiumFor(db: Firestore, familyId: string | undefined, now: Date) {
  if (!familyId) return false;
  const state = await loadFamilyEntitlements(db, familyId, now, serverGrantEnvironment());
  return capabilityStateAsOwner(state, 'rhythm.advanced', now).allowed;
}

/** Computes and stores the baby's insights; 'skipped' for a profile that is not active. */
export async function computeBabyInsights(
  db: Firestore,
  babyId: string,
  now: Date,
): Promise<'written' | 'skipped'> {
  const [baby, profile, rulesDoc, previousDoc] = await Promise.all([
    db.doc(`babies/${babyId}`).get(),
    db.doc(`babies/${babyId}/restricted/profile`).get(),
    db.doc('config/insights').get(),
    db.doc(insightDoc(babyId)).get(),
  ]);
  if (!baby.exists || (baby.get('state') ?? 'active') !== 'active') return 'skipped';
  const zone = (baby.get('timeZone.zone') as string | undefined) ?? DEFAULT_ZONE;
  const rules = insightRulesFrom(rulesDoc.data());
  const today = localDateIn(zone, now);
  const dob = (profile.get('dateOfBirth') as string | undefined)?.slice(0, 10) ?? null;
  const ageDays =
    dob && dob <= today
      ? cardAgeDays(dob, (profile.get('dueDate.date') as string | undefined) ?? null, today)
      : null;

  const w = insightWindows(zone, now, rules);
  const readFrom = new Date(nightBoundsIn(zone, w.baseline[0]!).start.getTime() - DAY);
  const readTo = nightBoundsIn(zone, w.recent[w.recent.length - 1]!).end;
  const [records, timer, conflicts, premium] = await Promise.all([
    db
      .collection(`babies/${babyId}/records`)
      .where('occurredAt', '>=', readFrom)
      .where('occurredAt', '<', readTo)
      .get(),
    db.doc(`babies/${babyId}/timers/sleep`).get(),
    db.collection(`babies/${babyId}/conflicts`).where('status', '==', 'open').get(),
    premiumFor(db, baby.get('familyId') as string | undefined, now),
  ]);
  const computation = computeInsights({
    zone,
    now,
    records: records.docs.flatMap((d) => recordOf(d) ?? []),
    openSleepTimerSince: timer.exists
      ? ((timer.get('startedAt') as Timestamp | undefined)?.toDate() ?? new Date(0))
      : null,
    conflictRecordIds: new Set(
      conflicts.docs.flatMap((c) => (c.get('recordIds') as string[] | undefined) ?? []),
    ),
    ageDays,
    rules,
  });
  const previous = previousDoc.exists
    ? {
        today: (previousDoc.get('today') as InsightKind | null | undefined) ?? null,
        todayOn: (previousDoc.get('todayOn') as string | null | undefined) ?? null,
        teaser: (previousDoc.get('teaser') as InsightState['teaser'] | undefined) ?? null,
        teaserOn: (previousDoc.get('teaserOn') as string | null | undefined) ?? null,
        lastTodayOn: (previousDoc.get('lastTodayOn') as InsightState['lastTodayOn']) ?? {},
      }
    : null;
  const shown = chooseShown({ computation, previous, premium, today, rules });
  const state: InsightState = {
    ruleVersion: insightRuleVersion,
    computedAt: now,
    windowStart: nightBoundsIn(zone, computation.from).start,
    windowEnd: nightBoundsIn(zone, computation.to).end,
    from: computation.from,
    to: computation.to,
    ...shown,
  };
  await db.doc(insightDoc(babyId)).set(state);
  return 'written';
}

/** When the next morning's computation is due: 30 min after the next night end still ahead. */
export function nextMorningDue(zone: string, now: Date): Date {
  const today = localDateIn(zone, now);
  const thisMorning = nightBoundsIn(zone, addDaysIso(today, -1)).end.getTime();
  const end =
    thisMorning + insightMorningDelayMs > now.getTime()
      ? thisMorning
      : nightBoundsIn(zone, today).end.getTime();
  return new Date(end + insightMorningDelayMs);
}

/**
 * A care record was written: schedule the recompute. An edit of a night that has ended inside
 * the window is due in 10 minutes; anything else waits for the next morning. Never moves a due
 * time later.
 */
export async function queueInsights(
  db: Firestore,
  babyId: string,
  before: DocumentSnapshot | null,
  after: DocumentSnapshot | null,
  now: Date,
): Promise<Date | null> {
  const baby = await db.doc(`babies/${babyId}`).get();
  if (!baby.exists || (baby.get('state') ?? 'active') !== 'active') return null;
  const zone = (baby.get('timeZone.zone') as string | undefined) ?? DEFAULT_ZONE;
  const rulesDoc = await db.doc('config/insights').get();
  const w = insightWindows(zone, now, insightRulesFrom(rulesDoc.data()));
  const windowStart = nightBoundsIn(zone, w.baseline[0]!).start.getTime();
  const countedUntil = nightBoundsIn(zone, w.recent[w.recent.length - 1]!).end.getTime();
  const touchesCounted = [before, after].some((s) => {
    const at = (s?.get('occurredAt') as Timestamp | undefined)?.toMillis();
    const end = (s?.get('endedAt') as Timestamp | null | undefined)?.toMillis() ?? at;
    return at !== undefined && end! >= windowStart - DAY && at < countedUntil;
  });
  const wanted = touchesCounted
    ? new Date(now.getTime() + insightEditDelayMs)
    : nextMorningDue(zone, now);
  const ref = db.doc(`insightQueue/${babyId}`);
  return db.runTransaction(async (tx) => {
    const current = (await tx.get(ref)).get('dueAt') as Timestamp | undefined;
    const due = current && current.toMillis() <= wanted.getTime() ? current.toDate() : wanted;
    tx.set(ref, { babyId, dueAt: due, lastCareAt: now }, { merge: true });
    return due;
  });
}

/** Computes every baby whose turn has come, then books its next morning while it is in use. */
export async function runInsightQueue(
  db: Firestore,
  now: Date,
  limit = 200,
): Promise<{ computed: number; skipped: number; idle: number }> {
  const due = await db
    .collection('insightQueue')
    .where('dueAt', '<=', now)
    .orderBy('dueAt')
    .limit(limit)
    .get();
  const result = { computed: 0, skipped: 0, idle: 0 };
  for (const q of due.docs) {
    const babyId = q.id;
    const outcome = await computeBabyInsights(db, babyId, now);
    const lastCareAt = (q.get('lastCareAt') as Timestamp | undefined)?.toMillis() ?? 0;
    const dueAt = q.get('dueAt') as Timestamp;
    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(q.ref);
      // A care write moved the due time while we computed: leave the new one.
      if (!fresh.exists || !(fresh.get('dueAt') as Timestamp).isEqual(dueAt)) return;
      if (outcome === 'skipped' || now.getTime() - lastCareAt > idleAfterMs) tx.delete(q.ref);
      else {
        const baby = await tx.get(db.doc(`babies/${babyId}`));
        const zone = (baby.get('timeZone.zone') as string | undefined) ?? DEFAULT_ZONE;
        tx.set(q.ref, { dueAt: nextMorningDue(zone, now) }, { merge: true });
      }
    });
    if (outcome === 'skipped') result.skipped += 1;
    else if (now.getTime() - lastCareAt > idleAfterMs) result.idle += 1;
    else result.computed += 1;
  }
  return result;
}
