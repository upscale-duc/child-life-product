import {
  Timestamp,
  type DocumentReference,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import {
  addDaysIso,
  applyQuotaOp,
  calendarMonthWindow,
  dayBoundsIn,
  localDateIn,
  quotaInvariantHolds,
  quotaWindowId,
  type QuotaFeature,
  type QuotaOp,
  type QuotaOutcome,
  type QuotaSnapshot,
  type QuotaWindow,
  type ReservationState,
} from '@child-life/contracts';

/**
 * Quota ledger on Firestore (brief p.10, plan §5.3), shared by AI summaries and video exports.
 *
 * - `families/{f}/quota/{windowId}`: one window — `feature`, `scope`, `limit`, `used`, `reserved`,
 *   `zone`, `startDate` / `endDate` (local dates, end exclusive), `startsAt` / `resetsAt`
 *   (instants, end exclusive). The limit is read from config by the caller and frozen when the
 *   window is created; the window keeps its own zone and end, so a household time-zone change only
 *   shapes the next window (M16).
 * - `families/{f}/quotaOps/{reservationId}`: one reservation — `state` reserved | committed |
 *   released, the windows it holds, `requestId`, `holder` (fencing token, e.g. a job's lease),
 *   timestamps. It moves at most once from `reserved`; repeats are no-ops (`applyQuotaOp`).
 *
 * Every operation runs `applyQuotaOp` for every window of the reservation inside ONE transaction:
 * a reservation over several windows (AI: per baby per day + per family per month) is taken in
 * all of them or in none. Clients can neither read nor write these documents (Rules, M04).
 *
 * Transactions: `reserveQuota` / `commitQuota` / `releaseQuota` read first and then write, so
 * call them after your own `tx.get`s and before your own writes (Firestore requires every read
 * of a transaction to come before its first write). The `…Now` variants run their own
 * transaction. Nothing here logs family data.
 */

export class QuotaError extends Error {
  constructor(
    readonly code: 'invalid-argument' | 'failed-precondition',
    readonly reason: string,
  ) {
    super(reason);
  }
}

/** Which window a reservation counts against. */
export type QuotaWindowRef =
  /** Calendar month in the household zone (`video` free budget, `ai_month`). */
  | { kind: 'calendar_month'; feature: QuotaFeature; zone: string }
  /** One local day for one baby (`ai_day`). */
  | { kind: 'day'; feature: QuotaFeature; babyId: string; zone: string }
  /** A paid grant's billing period (`video` premium budget): fixed instants from the provider. */
  | {
      kind: 'paid';
      feature: QuotaFeature;
      grantId: string;
      periodStart: Date;
      periodEnd: Date;
    };

/** A window plus the limit to freeze into it if it does not exist yet (from config). */
export interface QuotaWindowRequest {
  window: QuotaWindowRef;
  limit: number;
}

/** What is stored in `families/{f}/quota/{windowId}` (timestamps as Dates here). */
export interface StoredQuotaWindow extends QuotaWindow {
  windowId: string;
  feature: QuotaFeature;
  scope: QuotaWindowRef['kind'];
  babyId: string | null;
  grantId: string | null;
  /** IANA zone the window was cut in; null for paid periods. */
  zone: string | null;
  /** Local start date (inclusive) / end date (exclusive); ISO dates of the instants when paid. */
  startDate: string;
  endDate: string;
  startsAt: Date;
  resetsAt: Date;
}

export interface QuotaOpDoc {
  reservationId: string;
  familyId: string;
  /** Primary feature / window (the first one), for listings. */
  feature: QuotaFeature;
  windowId: string;
  windowIds: string[];
  features: QuotaFeature[];
  state: ReservationState;
  requestId: string | null;
  holder: string | null;
  /** Units held (assistant credits); absent on older reservations = 1. */
  units?: number;
}

export interface QuotaResult {
  outcome: QuotaOutcome | 'fenced';
  state: ReservationState | undefined;
  /** Windows after the operation, in request order (snapshot for the app, MO04). */
  windows: StoredQuotaWindow[];
}

const reservationIdPattern = /^[A-Za-z0-9_.:-]{1,200}$/;

function checkReservationId(id: string) {
  if (!reservationIdPattern.test(id)) throw new QuotaError('invalid-argument', 'bad-reservation');
}

const toDate = (v: unknown): Date =>
  v instanceof Timestamp ? v.toDate() : v instanceof Date ? v : new Date(0);

function windowOf(snap: DocumentSnapshot): StoredQuotaWindow {
  const d = snap.data() ?? {};
  return {
    windowId: snap.id,
    feature: d.feature as QuotaFeature,
    scope: d.scope as QuotaWindowRef['kind'],
    babyId: (d.babyId as string | null | undefined) ?? null,
    grantId: (d.grantId as string | null | undefined) ?? null,
    zone: (d.zone as string | null | undefined) ?? null,
    startDate: d.startDate as string,
    endDate: d.endDate as string,
    startsAt: toDate(d.startsAt),
    resetsAt: toDate(d.resetsAt),
    limit: (d.limit as number | undefined) ?? 0,
    used: (d.used as number | undefined) ?? 0,
    reserved: (d.reserved as number | undefined) ?? 0,
  };
}

/** A window as it would be created now (not stored yet). */
type WindowShape = Omit<StoredQuotaWindow, 'used' | 'reserved' | 'limit'>;

function shapeFor(ref: QuotaWindowRef, at: Date): WindowShape {
  switch (ref.kind) {
    case 'calendar_month': {
      const w = calendarMonthWindow(ref.zone, at);
      return {
        windowId: quotaWindowId(ref.feature, { kind: 'calendar', key: w.key }),
        feature: ref.feature,
        scope: 'calendar_month',
        babyId: null,
        grantId: null,
        zone: ref.zone,
        startDate: w.startDate,
        endDate: w.endDate,
        startsAt: dayBoundsIn(ref.zone, w.startDate).start,
        resetsAt: dayBoundsIn(ref.zone, w.endDate).start,
      };
    }
    case 'day': {
      const date = localDateIn(ref.zone, at);
      const end = addDaysIso(date, 1);
      return {
        windowId: quotaWindowId(ref.feature, { kind: 'day', babyId: ref.babyId, date }),
        feature: ref.feature,
        scope: 'day',
        babyId: ref.babyId,
        grantId: null,
        zone: ref.zone,
        startDate: date,
        endDate: end,
        startsAt: dayBoundsIn(ref.zone, date).start,
        resetsAt: dayBoundsIn(ref.zone, end).start,
      };
    }
    case 'paid':
      return {
        windowId: quotaWindowId(ref.feature, {
          kind: 'paid',
          grantId: ref.grantId,
          periodStart: ref.periodStart.toISOString(),
        }),
        feature: ref.feature,
        scope: 'paid',
        babyId: null,
        grantId: ref.grantId,
        zone: null,
        startDate: ref.periodStart.toISOString().slice(0, 10),
        endDate: ref.periodEnd.toISOString().slice(0, 10),
        startsAt: ref.periodStart,
        resetsAt: ref.periodEnd,
      };
  }
}

/** The calendar unit before [shape] in the same zone (to find a window still running). */
function previousShape(ref: QuotaWindowRef, shape: WindowShape): WindowShape | null {
  if (ref.kind === 'paid') return null;
  // One millisecond before this window's local start is inside the previous unit.
  return shapeFor(ref, new Date(shape.startsAt.getTime() - 1));
}

const quotaCol = (db: Firestore, familyId: string) => db.collection(`families/${familyId}/quota`);
const opRef = (db: Firestore, familyId: string, reservationId: string) =>
  db.doc(`families/${familyId}/quotaOps/${reservationId}`);

interface ResolvedWindow {
  ref: DocumentReference;
  window: StoredQuotaWindow;
  /** False: create it with the frozen limit on write. */
  exists: boolean;
}

/**
 * The window that holds [now] for [req] (reads only). Calendar windows keep their own zone and
 * end (M16): with the zone moved east the previous unit may still be running and wins; moved
 * west, the unit computed now may already have ended in its old zone, and then the next window
 * starts exactly where it ended and runs to the end of the following unit in the new zone.
 */
async function resolveWindow(
  tx: Transaction,
  db: Firestore,
  familyId: string,
  req: QuotaWindowRequest,
  now: Date,
): Promise<ResolvedWindow> {
  if (!Number.isInteger(req.limit) || req.limit < 0) {
    throw new QuotaError('invalid-argument', 'bad-limit');
  }
  const col = quotaCol(db, familyId);
  const fresh = (shape: WindowShape): ResolvedWindow => ({
    ref: col.doc(shape.windowId),
    window: { ...shape, limit: req.limit, used: 0, reserved: 0 },
    exists: false,
  });
  const live = (snap: DocumentSnapshot): ResolvedWindow | null => {
    if (!snap.exists) return null;
    const w = windowOf(snap);
    return w.startsAt.getTime() <= now.getTime() && now.getTime() < w.resetsAt.getTime()
      ? { ref: snap.ref, window: w, exists: true }
      : null;
  };

  const shape = shapeFor(req.window, now);
  if (req.window.kind === 'paid') {
    if (now < shape.startsAt || now >= shape.resetsAt) {
      throw new QuotaError('failed-precondition', 'outside-period');
    }
    const snap = await tx.get(col.doc(shape.windowId));
    return live(snap) ?? fresh(shape);
  }
  const prev = previousShape(req.window, shape)!;
  const [curSnap, prevSnap] = await Promise.all([
    tx.get(col.doc(shape.windowId)),
    tx.get(col.doc(prev.windowId)),
  ]);
  const running = live(prevSnap) ?? live(curSnap);
  if (running) return running;
  if (!curSnap.exists) {
    // A previous window that ended after this one would start: start where it ended.
    if (prevSnap.exists) {
      const p = windowOf(prevSnap);
      if (p.resetsAt > shape.startsAt) return fresh({ ...shape, startsAt: p.resetsAt });
    }
    return fresh(shape);
  }
  // This unit's id is taken by a window that already ended in its old zone (zone moved west):
  // the next window starts at its end and covers the following unit in the new zone.
  const ended = windowOf(curSnap);
  const after = shapeFor(req.window, ended.resetsAt);
  const next =
    after.windowId === ended.windowId
      ? shapeFor(req.window, new Date(after.resetsAt.getTime()))
      : after;
  const nextSnap = await tx.get(col.doc(next.windowId));
  return live(nextSnap) ?? fresh({ ...next, startsAt: ended.resetsAt });
}

function windowData(w: StoredQuotaWindow, now: Date, created: boolean) {
  return {
    windowId: w.windowId,
    feature: w.feature,
    scope: w.scope,
    babyId: w.babyId,
    grantId: w.grantId,
    zone: w.zone,
    startDate: w.startDate,
    endDate: w.endDate,
    startsAt: Timestamp.fromDate(w.startsAt),
    resetsAt: Timestamp.fromDate(w.resetsAt),
    limit: w.limit,
    used: w.used,
    reserved: w.reserved,
    updatedAt: Timestamp.fromDate(now),
    ...(created ? { createdAt: Timestamp.fromDate(now) } : {}),
  };
}

export interface ReserveInput {
  familyId: string;
  /** Idempotency key of the reservation (a job id, a summary id); one use only. */
  reservationId: string;
  /** All or none: one entry per window the use counts against. */
  windows: QuotaWindowRequest[];
  requestId?: string | null;
  /** Fencing token: commit only succeeds with the same holder (e.g. a job attempt / lease). */
  holder?: string | null;
  /** How many units this use takes in every window (default 1; assistant: text 1, image 3). */
  units?: number;
  now: Date;
}

/**
 * Reserves one use in every window of [input] in transaction [tx], or in none (`denied` when
 * any window is full). A reservation id seen before is a no-op that reports its current state
 * (a retried request never takes a second unit). Reads, then writes.
 */
export async function reserveQuota(
  tx: Transaction,
  db: Firestore,
  input: ReserveInput,
): Promise<QuotaResult> {
  checkReservationId(input.reservationId);
  if (input.windows.length === 0) throw new QuotaError('invalid-argument', 'no-window');
  const opDoc = opRef(db, input.familyId, input.reservationId);
  const opSnap = await tx.get(opDoc);
  if (opSnap.exists) {
    const op = opSnap.data() as QuotaOpDoc;
    const snaps = await Promise.all(
      op.windowIds.map((id) => tx.get(quotaCol(db, input.familyId).doc(id))),
    );
    return { outcome: 'noop', state: op.state, windows: snaps.map(windowOf) };
  }
  const resolved: ResolvedWindow[] = [];
  for (const req of input.windows) {
    resolved.push(await resolveWindow(tx, db, input.familyId, req, input.now));
  }
  if (new Set(resolved.map((r) => r.ref.path)).size !== resolved.length) {
    throw new QuotaError('invalid-argument', 'duplicate-window');
  }
  const units = input.units ?? 1;
  const applied = resolved.map((r) => applyQuotaOp(r.window, undefined, 'reserve', units));
  if (applied.some((a) => a.outcome === 'denied')) {
    return { outcome: 'denied', state: undefined, windows: resolved.map((r) => r.window) };
  }
  const after = resolved.map((r, i) => ({ ...r.window, ...applied[i]!.window }));
  if (!after.every(quotaInvariantHolds)) throw new QuotaError('failed-precondition', 'invariant');
  resolved.forEach((r, i) => tx.set(r.ref, windowData(after[i]!, input.now, !r.exists)));
  const now = Timestamp.fromDate(input.now);
  tx.create(opDoc, {
    reservationId: input.reservationId,
    familyId: input.familyId,
    feature: after[0]!.feature,
    windowId: after[0]!.windowId,
    windowIds: after.map((w) => w.windowId),
    features: after.map((w) => w.feature),
    state: 'reserved' satisfies ReservationState,
    requestId: input.requestId ?? null,
    holder: input.holder ?? null,
    units,
    createdAt: now,
    updatedAt: now,
    reservedAt: now,
    committedAt: null,
    releasedAt: null,
    releaseReason: null,
  });
  return { outcome: 'reserved', state: 'reserved', windows: after };
}

export interface SettleInput {
  familyId: string;
  reservationId: string;
  /** Must equal the reservation's holder when it has one (commit); see `releaseQuota`. */
  holder?: string | null;
  /** Release only: a closed slug for audits (`timeout`, `cancelled`, `failed`…). */
  reason?: string | null;
  now: Date;
}

async function settle(
  tx: Transaction,
  db: Firestore,
  input: SettleInput,
  op: Exclude<QuotaOp, 'reserve'>,
): Promise<QuotaResult> {
  checkReservationId(input.reservationId);
  const opDoc = opRef(db, input.familyId, input.reservationId);
  const opSnap = await tx.get(opDoc);
  if (!opSnap.exists) return { outcome: 'noop', state: undefined, windows: [] };
  const stored = opSnap.data() as QuotaOpDoc;
  const refs = stored.windowIds.map((id) => quotaCol(db, input.familyId).doc(id));
  const snaps = await Promise.all(refs.map((r) => tx.get(r)));
  const windows = snaps.map(windowOf);
  // Fencing: a stale holder (an older job attempt) never commits; release checks it when given.
  const fenced =
    stored.holder !== null &&
    (op === 'commit'
      ? input.holder !== stored.holder
      : input.holder != null && input.holder !== stored.holder);
  if (fenced) return { outcome: 'fenced', state: stored.state, windows };
  const applied = windows.map((w) => applyQuotaOp(w, stored.state, op, stored.units ?? 1));
  if (applied[0]!.outcome === 'noop') return { outcome: 'noop', state: stored.state, windows };
  const after = windows.map((w, i) => ({ ...w, ...applied[i]!.window }));
  after.forEach((w, i) => {
    if (snaps[i]!.exists) tx.set(refs[i]!, windowData(w, input.now, false));
  });
  const at = Timestamp.fromDate(input.now);
  tx.update(opDoc, {
    state: applied[0]!.state,
    updatedAt: at,
    ...(op === 'commit'
      ? { committedAt: at }
      : { releasedAt: at, releaseReason: input.reason ?? null }),
  });
  return { outcome: applied[0]!.outcome, state: applied[0]!.state, windows: after };
}

/** reserved → committed (the use happened). Requires the reservation's holder when it has one. */
export function commitQuota(tx: Transaction, db: Firestore, input: SettleInput) {
  return settle(tx, db, input, 'commit');
}

/** reserved → released (failure / cancel). A given holder must match; none = forced release. */
export function releaseQuota(tx: Transaction, db: Firestore, input: SettleInput) {
  return settle(tx, db, input, 'release');
}

export const reserveQuotaNow = (db: Firestore, input: ReserveInput) =>
  db.runTransaction((tx) => reserveQuota(tx, db, input));
export const commitQuotaNow = (db: Firestore, input: SettleInput) =>
  db.runTransaction((tx) => commitQuota(tx, db, input));
export const releaseQuotaNow = (db: Firestore, input: SettleInput) =>
  db.runTransaction((tx) => releaseQuota(tx, db, input));

/** What the app shows (MO04): limit, used, reserved and when it resets. */
export function quotaSnapshot(
  w: Pick<StoredQuotaWindow, keyof QuotaWindow | 'resetsAt'>,
): QuotaSnapshot {
  return { limit: w.limit, used: w.used, reserved: w.reserved, resetsAt: w.resetsAt.toISOString() };
}

/** The current window's snapshot without writing (an unused window reads as empty). */
export async function readQuotaSnapshot(
  db: Firestore,
  familyId: string,
  req: QuotaWindowRequest,
  now: Date,
): Promise<QuotaSnapshot> {
  const r = await db.runTransaction((tx) => resolveWindow(tx, db, familyId, req, now), {
    readOnly: true,
  });
  return quotaSnapshot(r.window);
}

/** Reservations still `reserved` (for a sweeper releasing work that died). Admin use only. */
export async function staleReservations(
  db: Firestore,
  familyId: string,
  olderThan: Date,
): Promise<string[]> {
  const snap = await db
    .collection(`families/${familyId}/quotaOps`)
    .where('state', '==', 'reserved')
    .get();
  return snap.docs
    .filter((d) => toDate(d.get('reservedAt')).getTime() < olderThan.getTime())
    .map((d) => d.id);
}

/** The window a request would use at [now], with its counters (no write; quotes, usage). */
export const peekQuotaWindow = (
  db: Firestore,
  familyId: string,
  req: QuotaWindowRequest,
  now: Date,
) =>
  db
    .runTransaction((tx) => resolveWindow(tx, db, familyId, req, now), { readOnly: true })
    .then((r) => ({ windowId: r.window.windowId, exists: r.exists, window: r.window }));

/** Exposed for tests: the window a request would use at [now] (no write). */
export const _resolveWindowForTest = peekQuotaWindow;
