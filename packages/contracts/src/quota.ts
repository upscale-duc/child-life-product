import { localDateIn } from './baby.js';

/**
 * Quota ledger (brief p.10, plan §5.3): one state machine for video exports and AI summaries.
 * Invariant at every step: `used + reserved ≤ limit`. Every reservation id moves at most once
 * from reserved to committed (success) or released (failure / cancel); repeats are no-ops, so a
 * retried request or a twice-delivered callback never charges twice. The server keeps the window
 * in one document and each reservation's state in an immutable op document, in one transaction.
 */

export interface QuotaWindow {
  limit: number;
  used: number;
  reserved: number;
}

export type ReservationState = 'reserved' | 'committed' | 'released';

export type QuotaOp = 'reserve' | 'commit' | 'release';

export type QuotaOutcome = 'reserved' | 'denied' | 'committed' | 'released' | 'noop';

/**
 * Applies one operation for one reservation id. `current` is the id's state before (undefined =
 * never seen). A reservation id is used once: reserving it again after a release is a no-op (a
 * retry after a failure takes a new reservation id).
 */
export function applyQuotaOp(
  window: QuotaWindow,
  current: ReservationState | undefined,
  op: QuotaOp,
  /** Units the reservation holds (assistant credits: text 1, image 3); the same value on every
   * operation of one reservation. Video and AI summaries use 1. */
  units = 1,
): { window: QuotaWindow; state: ReservationState | undefined; outcome: QuotaOutcome } {
  if (!Number.isInteger(units) || units < 0)
    throw new Error('units must be a non-negative integer');
  const w = { ...window };
  switch (op) {
    case 'reserve':
      if (current !== undefined) return { window: w, state: current, outcome: 'noop' };
      if (w.used + w.reserved + units > w.limit || (units === 0 && w.used + w.reserved > w.limit)) {
        return { window: w, state: undefined, outcome: 'denied' };
      }
      w.reserved += units;
      return { window: w, state: 'reserved', outcome: 'reserved' };
    case 'commit':
      if (current !== 'reserved') return { window: w, state: current, outcome: 'noop' };
      w.reserved -= units;
      w.used += units;
      return { window: w, state: 'committed', outcome: 'committed' };
    case 'release':
      if (current !== 'reserved') return { window: w, state: current, outcome: 'noop' };
      w.reserved -= units;
      return { window: w, state: 'released', outcome: 'released' };
  }
}

export function quotaInvariantHolds(w: QuotaWindow): boolean {
  return w.used >= 0 && w.reserved >= 0 && w.used + w.reserved <= w.limit;
}

/** `assistant`: chat credits, one household pool per window (Free calendar month, Premium billing period). */
export const quotaFeatures = ['video', 'ai_day', 'ai_month', 'assistant'] as const;
export type QuotaFeature = (typeof quotaFeatures)[number];

/**
 * Window of a calendar quota in the household's time zone (brief p.10: reset by the server and the
 * household zone, never the client's clock). A zone change keeps the current window to its end:
 * the window document stores its own zone and end, and the next one uses the new zone.
 */
export function calendarMonthWindow(
  zone: string,
  now: Date,
): { key: string; startDate: string; endDate: string } {
  const today = localDateIn(zone, now);
  const [y, m] = today.split('-').map(Number) as [number, number];
  const next = m === 12 ? `${y + 1}-01-01` : `${y}-${String(m + 1).padStart(2, '0')}-01`;
  return { key: today.slice(0, 7), startDate: `${today.slice(0, 7)}-01`, endDate: next };
}

/** Window document id: `video_cal_2026-10`, `video_paid_<grant>_<periodStart>`, `ai_day_<baby>_<date>`… */
export function quotaWindowId(
  feature: QuotaFeature,
  scope:
    | { kind: 'calendar'; key: string }
    | { kind: 'paid'; grantId: string; periodStart: string }
    | { kind: 'day'; babyId: string; date: string }
    /** Premium v2 Free allowance used once (`assistant_trial_v2`, `video_trial_v2`, D-101). */
    | { kind: 'trial'; key: string },
): string {
  switch (scope.kind) {
    case 'trial':
      return `${feature}_trial_${scope.key}`;
    case 'calendar':
      return `${feature}_cal_${scope.key}`;
    case 'paid':
      return `${feature}_paid_${scope.grantId}_${scope.periodStart.slice(0, 10)}`;
    case 'day':
      return `${feature}_${scope.babyId}_${scope.date}`;
  }
}

/** What the app shows (MO04 "3 / 5 · 2 đã dùng · 1 đang giữ chỗ · làm mới …"). */
export interface QuotaSnapshot {
  limit: number;
  used: number;
  reserved: number;
  /** Exclusive end of the window (ISO instant). */
  resetsAt: string | null;
}
