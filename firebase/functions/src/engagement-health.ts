import {
  engagementOutcomes,
  localDateIn,
  staffEngagementHealthSchema,
  type EngagementHealthResponse,
  type EngagementHealthSignalId,
  type EngagementOutcome,
} from '@child-life/contracts';
import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { LEDGER } from './notification-ledger.js';
import { familyCode, parse, requireStaff, type Staff } from './staff.js';

/**
 * "Thông báo bị mất trước khi gửi" (owner, 2026-10-26): the overview's delivery numbers only see
 * notices that were created, so a suggestion that never became a push left it "all good". On
 * 26/10 every Smart Engagement suggestion of one account went in-app only (the app sent the
 * device lease while the permission was still loading) and the next day's "Gợi ý hôm nay" was
 * closed the day before. These four checks look at the engine's own records before the send:
 *
 * - `channel_unavailable`: decided suggestions kept in the app because no push channel was
 *   usable (≥ 20 % of the decided ones, at least 2);
 * - `permission_mismatch`: a live device lease says "not allowed" while that phone still has a
 *   push token and received a push in the last 7 days (the lease is wrong);
 * - `closed_early`: a daily suggestion closed (`source_resolved`) before its own day began;
 * - `daily_missed`: a past day's daily slot that expired or still waits after its window (the
 *   scheduler did not decide it).
 *
 * Metadata only: kinds, statuses, reasons, counts and masked family codes, never uids or copy.
 */

const DAY_MS = 86_400_000;
const SCAN = 2000;
const FAMILIES = 10;
const ZONE = 'Asia/Ho_Chi_Minh';

const ms = (v: unknown) =>
  v instanceof Timestamp
    ? v.toMillis()
    : v instanceof Date
      ? v.getTime()
      : typeof v === 'number'
        ? v
        : 0;
const vnStart = (day: string) => new Date(`${day}T00:00:00+07:00`).getTime();
/** Midnight of [day] in [zone], to the hour (the zones in use are whole hours). */
const dayStartIn = (zone: string, day: string) => {
  let t = Date.parse(`${day}T00:00:00Z`) - 14 * 3_600_000;
  while (localDateIn(zone, new Date(t)) < day) t += 3_600_000;
  return t;
};

const outcomeOf = (status: string): EngagementOutcome =>
  ['accepted', 'attempted', 'unknown'].includes(status)
    ? 'pushed'
    : status === 'in_app_only'
      ? 'in_app_only'
      : ['suppressed', 'deferred', 'digest_member', 'failed'].includes(status)
        ? 'held'
        : ['completed', 'cancelled'].includes(status)
          ? 'closed'
          : status === 'expired'
            ? 'expired'
            : 'pending';

export async function engagementHealth(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
): Promise<EngagementHealthResponse> {
  requireStaff(staff, 'notifications.view');
  const range = parse(staffEngagementHealthSchema, data) as { from: string; to: string };
  const from = vnStart(range.from);
  const to = vnStart(range.to) + DAY_MS;
  const n = now.getTime();
  const [intents, leases] = await Promise.all([
    db
      .collection('engagementIntents')
      .where('dueAt', '>=', from)
      .where('dueAt', '<', to)
      .limit(SCAN)
      .get(),
    // Every device lease names its baby (`settings/engagementDevice`); other settings are skipped.
    db.collectionGroup('settings').orderBy('babyId').limit(SCAN).get(),
  ]);

  const outcomes = Object.fromEntries(engagementOutcomes.map((o) => [o, 0])) as Record<
    EngagementOutcome,
    number
  >;
  const reasons: Record<string, number> = {};
  const hits: Record<EngagementHealthSignalId, { n: number; families: Set<string> }> = {
    channel_unavailable: { n: 0, families: new Set() },
    permission_mismatch: { n: 0, families: new Set() },
    closed_early: { n: 0, families: new Set() },
    daily_missed: { n: 0, families: new Set() },
  };
  const hit = (id: EngagementHealthSignalId, familyId: unknown) => {
    hits[id].n++;
    if (typeof familyId === 'string' && hits[id].families.size < FAMILIES)
      hits[id].families.add(familyCode(familyId));
  };
  const daily = new Map<string, { slots: number; pushed: number; missed: number }>();

  for (const d of intents.docs) {
    if (d.get('proactive') === false) continue;
    const status = String(d.get('status') ?? '');
    const reason = String(d.get('reason') ?? 'none');
    const outcome = outcomeOf(status);
    outcomes[outcome]++;
    if (outcome !== 'pushed' && reason !== 'none') reasons[reason] = (reasons[reason] ?? 0) + 1;
    if (reason === 'channel_unavailable' && (outcome === 'in_app_only' || outcome === 'held'))
      hit('channel_unavailable', d.get('familyId'));
    if (d.get('kind') !== 'ENG-06') continue;
    const day = String(d.get('sourceData.date') ?? '');
    if (!/^\d{4}-\d{2}-\d{2}$/.test(day)) continue;
    const row = daily.get(day) ?? { slots: 0, pushed: 0, missed: 0 };
    row.slots++;
    if (outcome === 'pushed') row.pushed++;
    // Closed before its own day began: judged on another day's state.
    const closedAt = ms(d.get('completedAt')) || ms(d.get('closedAt'));
    if (
      outcome === 'closed' &&
      reason === 'source_resolved' &&
      closedAt > 0 &&
      closedAt < dayStartIn(String(d.get('zone') ?? ZONE), day)
    )
      hit('closed_early', d.get('familyId'));
    // Its window passed and the engine never decided it.
    const windowEnd = ms(d.get('windowClosesAt'));
    if (
      windowEnd > 0 &&
      windowEnd < n &&
      (outcome === 'expired' || outcome === 'pending') &&
      !d.get('dismissed')
    ) {
      row.missed++;
      hit('daily_missed', d.get('familyId'));
    }
    daily.set(day, row);
  }

  // A live lease that says "not allowed" for a phone that still gets pushes is wrong.
  const weekAgo = new Date(n - 7 * DAY_MS);
  for (const lease of leases.docs) {
    if (lease.id !== 'engagementDevice') continue;
    if (lease.get('pushAllowed') === true || !(Number(lease.get('validUntil')) > n)) continue;
    const uid = lease.ref.parent.parent?.id;
    const deviceId = lease.get('deviceId');
    if (!uid || typeof deviceId !== 'string') continue;
    const [device, recent] = await Promise.all([
      db.doc(`users/${uid}/devices/${deviceId}`).get(),
      // Equality only (no composite index); the week is filtered here.
      db.collection(LEDGER).where('uid', '==', uid).limit(200).get(),
    ]);
    if (!device.get('token') || device.get('signedOutAt')) continue;
    if (
      !recent.docs.some(
        (r) => r.get('delivery') === 'accepted' && ms(r.get('createdAt')) >= weekAgo.getTime(),
      )
    )
      continue;
    const baby = await db.doc(`babies/${String(lease.get('babyId'))}`).get();
    hit('permission_mismatch', baby.get('familyId'));
  }

  const decided = outcomes.pushed + outcomes.in_app_only + outcomes.held;
  const raised = (id: EngagementHealthSignalId) =>
    id === 'channel_unavailable'
      ? hits[id].n >= 2 && decided > 0 && hits[id].n / decided >= 0.2
      : hits[id].n > 0;
  return {
    range,
    computedAt: now.toISOString(),
    outcomes,
    reasons,
    signals: (Object.keys(hits) as EngagementHealthSignalId[])
      .filter(raised)
      .map((id) => ({ id, n: hits[id].n, families: [...hits[id].families].sort() })),
    daily: [...daily.entries()]
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([day, r]) => ({ day, ...r })),
    truncated: intents.size >= SCAN || leases.size >= SCAN,
  };
}
