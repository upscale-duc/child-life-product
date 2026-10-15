import {
  applyQuotaOp,
  calendarMonthWindow,
  dayBoundsIn,
  quotaInvariantHolds,
  quotaWindowId,
  type EntitlementsConfig,
  type GrantEnvironment,
  type QuotaOp,
  type QuotaOutcome,
  type QuotaSnapshot,
  type QuotaWindow,
  type ReservationState,
} from '@child-life/contracts';
import type { Firestore, Timestamp, Transaction } from 'firebase-admin/firestore';

/**
 * Video kỷ niệm quota ledger (Q2, brief p.10, plan §5.3): one unit per video, reserved in the
 * transaction that creates the render job, committed once when the video is filed, released once
 * when the job fails for good. `families/{f}/quota/{windowId}` holds the window counters;
 * `families/{f}/quotaOps/{reservationId}` holds each reservation's state, so a repeated callback
 * never charges or refunds twice (contracts `applyQuotaOp`).
 *
 * TODO(quota.ts): the shared ledger helper `firebase/functions/src/quota.ts` (AI summaries) was
 * not there when this was written; switch these calls to it once it lands. The documents and
 * the state machine are the same (contracts `quota.ts`), so the switch is mechanical.
 */

/** Fallback when neither the family nor the baby has a zone (the app's home market). */
const defaultZone = 'Asia/Ho_Chi_Minh';

export interface VideoWindow {
  id: string;
  kind: 'free' | 'paid';
  /** Configured limit for this window (`config/entitlements` quotas.video). */
  limit: number;
  start: Date;
  /** Exclusive end. */
  end: Date;
  zone: string | null;
  grantId: string | null;
}

const toDate = (v: unknown): Date | null =>
  v instanceof Date
    ? v
    : v && typeof (v as Timestamp).toDate === 'function'
      ? (v as Timestamp).toDate()
      : null;

/**
 * The window a new video counts in: the paid grant's billing period while one is valid (premium
 * limit), else the calendar month in the household zone (free limit; Beta A uses this too).
 */
export async function videoWindowFor(
  db: Firestore,
  familyId: string,
  babyId: string,
  config: EntitlementsConfig,
  environment: GrantEnvironment,
  now: Date,
): Promise<VideoWindow> {
  const t = now.getTime();
  const paid = (
    await db.collection(`families/${familyId}/grants`).where('source', '==', 'paid').get()
  ).docs
    .map((d) => ({
      id: d.id,
      status: d.get('status') as string,
      environment: d.get('environment') as string,
      validFrom: toDate(d.get('validFrom')),
      validUntil: toDate(d.get('validUntil')),
      periodStart: toDate(d.get('periodStart')),
    }))
    .filter(
      (g) =>
        g.environment === environment &&
        (g.status === 'active' || g.status === 'grace') &&
        g.validFrom !== null &&
        g.validUntil !== null &&
        g.validFrom.getTime() <= t &&
        t < g.validUntil.getTime(),
    )
    .sort((a, b) => b.validUntil!.getTime() - a.validUntil!.getTime())[0];
  if (paid) {
    const start = paid.periodStart ?? paid.validFrom!;
    return {
      id: quotaWindowId('video', {
        kind: 'paid',
        grantId: paid.id,
        periodStart: start.toISOString(),
      }),
      kind: 'paid',
      limit: config.quotas.video.premium.limit,
      start,
      end: paid.validUntil!,
      zone: null,
      grantId: paid.id,
    };
  }
  const [family, baby] = await Promise.all([
    db.doc(`families/${familyId}`).get(),
    db.doc(`babies/${babyId}`).get(),
  ]);
  const zone =
    (family.get('timeZone') as string | undefined) ??
    (baby.get('timeZone.zone') as string | undefined) ??
    defaultZone;
  const month = calendarMonthWindow(zone, now);
  return {
    id: quotaWindowId('video', { kind: 'calendar', key: month.key }),
    kind: 'free',
    limit: config.quotas.video.free.limit,
    start: dayBoundsIn(zone, month.startDate).start,
    end: dayBoundsIn(zone, month.endDate).start,
    zone,
    grantId: null,
  };
}

export const windowRef = (db: Firestore, familyId: string, windowId: string) =>
  db.doc(`families/${familyId}/quota/${windowId}`);
export const opRef = (db: Firestore, familyId: string, reservationId: string) =>
  db.doc(`families/${familyId}/quotaOps/${reservationId}`);

/** The counters stored for [windowId]; the limit follows the config but never drops below what
 * is already used or held, so the invariant survives a lowered limit. */
function countersOf(
  snap: FirebaseFirestore.DocumentSnapshot,
  configLimit: number | null,
): QuotaWindow {
  const used = (snap.get('used') as number | undefined) ?? 0;
  const reserved = (snap.get('reserved') as number | undefined) ?? 0;
  const stored = (snap.get('limit') as number | undefined) ?? 0;
  const limit = configLimit === null ? stored : Math.max(configLimit, used + reserved);
  return { limit, used, reserved };
}

export function snapshotOf(w: QuotaWindow, end: Date | null): QuotaSnapshot {
  return {
    limit: w.limit,
    used: w.used,
    reserved: w.reserved,
    resetsAt: end ? end.toISOString() : null,
  };
}

/** MO04: what the current window looks like (no document yet = nothing used). */
export async function readVideoQuota(
  db: Firestore,
  familyId: string,
  window: VideoWindow,
): Promise<QuotaSnapshot> {
  const snap = await windowRef(db, familyId, window.id).get();
  return snapshotOf(countersOf(snap, window.limit), window.end);
}

/** Reads for a reserve inside a transaction (all reads come before any write). */
export async function readForReserve(
  tx: Transaction,
  db: Firestore,
  familyId: string,
  window: VideoWindow,
) {
  return tx.get(windowRef(db, familyId, window.id));
}

/**
 * Reserves one unit for [reservationId] in [window] (writes only; the window snapshot was read in
 * the same transaction). Returns `denied` without writing when the window is full.
 */
export function reserveInTx(
  tx: Transaction,
  db: Firestore,
  familyId: string,
  window: VideoWindow,
  windowSnap: FirebaseFirestore.DocumentSnapshot,
  reservationId: string,
  meta: { babyId: string; jobId: string },
  now: Date,
  /** Earlier changes to the same window in this transaction (a retry's release). */
  base?: QuotaWindow,
): { outcome: QuotaOutcome; window: QuotaWindow } {
  const before = base ?? countersOf(windowSnap, window.limit);
  const r = applyQuotaOp(
    { ...before, limit: Math.max(window.limit, before.used + before.reserved) },
    undefined,
    'reserve',
  );
  if (r.outcome !== 'reserved') return { outcome: r.outcome, window: r.window };
  if (!quotaInvariantHolds(r.window)) throw new Error('quota invariant');
  tx.set(
    windowRef(db, familyId, window.id),
    {
      feature: 'video',
      kind: window.kind,
      limit: r.window.limit,
      used: r.window.used,
      reserved: r.window.reserved,
      windowStart: window.start,
      windowEnd: window.end,
      zone: window.zone,
      grantId: window.grantId,
      updatedAt: now,
      ...(windowSnap.exists ? {} : { createdAt: now }),
    },
    { merge: true },
  );
  tx.create(opRef(db, familyId, reservationId), {
    feature: 'video',
    windowId: window.id,
    babyId: meta.babyId,
    jobId: meta.jobId,
    state: 'reserved' satisfies ReservationState,
    reservedAt: now,
    committedAt: null,
    releasedAt: null,
  });
  return { outcome: 'reserved', window: r.window };
}

export interface SettleReads {
  op: FirebaseFirestore.DocumentSnapshot;
  window: FirebaseFirestore.DocumentSnapshot | null;
}

/** Reads for commit / release of [reservationId] (op, then its window). */
export async function readForSettle(
  tx: Transaction,
  db: Firestore,
  familyId: string,
  reservationId: string,
): Promise<SettleReads> {
  const op = await tx.get(opRef(db, familyId, reservationId));
  const windowId = op.get('windowId') as string | undefined;
  return { op, window: windowId ? await tx.get(windowRef(db, familyId, windowId)) : null };
}

/**
 * Commit or release, at most once per reservation: anything but `reserved` is a no-op. Returns
 * the outcome and the window counters after.
 */
export function settleInTx(
  tx: Transaction,
  db: Firestore,
  familyId: string,
  reads: SettleReads,
  op: Extract<QuotaOp, 'commit' | 'release'>,
  now: Date,
): { outcome: QuotaOutcome; window: QuotaWindow | null } {
  if (!reads.op.exists || !reads.window?.exists) return { outcome: 'noop', window: null };
  const state = reads.op.get('state') as ReservationState;
  const before = countersOf(reads.window, null);
  const r = applyQuotaOp(before, state, op);
  if (r.outcome === 'noop') return { outcome: 'noop', window: before };
  if (!quotaInvariantHolds(r.window)) throw new Error('quota invariant');
  tx.update(reads.window.ref, { used: r.window.used, reserved: r.window.reserved, updatedAt: now });
  tx.update(reads.op.ref, {
    state: r.state,
    ...(op === 'commit' ? { committedAt: now } : { releasedAt: now }),
  });
  return { outcome: r.outcome, window: r.window };
}

/** Counters of the window a release in this transaction touched, for a reserve that follows. */
export function countersAfter(
  reads: SettleReads,
  settled: { window: QuotaWindow | null },
): QuotaWindow | null {
  return reads.window?.exists ? (settled.window ?? countersOf(reads.window, null)) : null;
}
