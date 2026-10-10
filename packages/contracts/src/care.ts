import { z } from 'zod';
import { localDateIn } from './baby.js';

/**
 * Care records (Slice S4; Figma 19, 19a, 21, 22, 23, 23a, 24, 28; business map §6, R-050…R-066).
 * Records are written by the app directly to `babies/{babyId}/records/{recordId}` so the Firestore
 * cache is the offline outbox (plan §3.3); Rules in `firebase/firestore.rules` enforce the same
 * shape and ranges as these schemas. The Dart app mirrors them in
 * `apps/mobile/lib/features/care/care_models.dart`.
 */

export const careTypes = ['bottle', 'breast', 'pump', 'sleep', 'diaper', 'growth'] as const;
export type CareType = (typeof careTypes)[number];

export const milkTypes = ['breastMilk', 'formula'] as const;
export const sides = ['left', 'right', 'both'] as const;
export const diaperKinds = ['wet', 'dirty', 'both'] as const;

/** Ranges (not in Figma; keep typos out and are mirrored in Rules). */
export const careLimits = {
  bottleMl: { min: 1, max: 500 },
  pumpMl: { min: 1, max: 1000 },
  durationMin: { min: 1, max: 240 },
  weightKg: { min: 0.3, max: 40 },
  lengthCm: { min: 20, max: 150 },
  /** Clock skew allowed for "now" (G-021: no future times). */
  futureSkewMinutes: 5,
} as const;

/** Client ids: `r_` + 32 hex (a UUID without dashes) — stable across retries (idempotent). */
export const recordIdSchema = z.string().regex(/^r_[a-f0-9]{32}$/);

const amount = (limits: { min: number; max: number }) =>
  z.number().int().min(limits.min).max(limits.max);
const duration = amount(careLimits.durationMin);

export const bottleDataSchema = z.object({
  amountMl: amount(careLimits.bottleMl).nullable(),
  milk: z.enum(milkTypes),
});
export const breastDataSchema = z.object({
  side: z.enum(sides),
  durationMin: duration.nullable(),
});
export const pumpDataSchema = z.object({
  side: z.enum(sides),
  amountMl: amount(careLimits.pumpMl),
  durationMin: duration.nullable(),
});
export const diaperDataSchema = z.object({ kind: z.enum(diaperKinds) });
export const growthDataSchema = z.object({
  weightKg: z.number().min(careLimits.weightKg.min).max(careLimits.weightKg.max),
  lengthCm: z.number().min(careLimits.lengthCm.min).max(careLimits.lengthCm.max).nullable(),
  measuredOn: z.iso.date(),
});
/** S5 writes sleep through timers / manual entry; the shape is fixed now for summaries. */
export const sleepDataSchema = z.object({});

export const careDataSchemas = {
  bottle: bottleDataSchema,
  breast: breastDataSchema,
  pump: pumpDataSchema,
  sleep: sleepDataSchema,
  diaper: diaperDataSchema,
  growth: growthDataSchema,
} as const;

/** Author snapshot for "Mẹ ghi" / "Cô Lan ghi" (D-024), kept even if the member leaves. */
export const authorSchema = z.object({
  name: z.string().min(1).max(40),
  relation: z.string().min(1).max(24),
  relationCustom: z.string().max(24).nullable(),
});

/**
 * Attribution (Q-030 → D-024): family relations read as their label ("Mẹ ghi", "Bà ghi");
 * nanny / relative / friend / other read as the member's name ("Cô Lan ghi").
 */
export const labelRelations = ['mother', 'father', 'grandmother', 'grandfather'] as const;

/** Day summary kept by the server per baby-local date (`babies/{b}/days/{YYYY-MM-DD}`). */
export interface DaySummary {
  date: string;
  bottle: { count: number; ml: number };
  breast: { count: number; minutes: number };
  /** Finished sleep, clipped to the day in the baby's zone (R-061). */
  sleepMinutes: number;
  diaper: { count: number; wet: number; dirty: number };
  /** Not intake (R-054): never part of the feed totals. */
  pump: { count: number; ml: number };
  growth: { count: number };
}

export interface SummaryRecord {
  type: CareType;
  occurredAt: Date;
  endedAt: Date | null;
  data: Record<string, unknown>;
}

/** Start (inclusive) and end (exclusive) instants of [date] in [zone]. */
export function dayBoundsIn(zone: string, date: string): { start: Date; end: Date } {
  const start = startOfDayIn(zone, date);
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  const next = new Date(Date.UTC(y, m - 1, d + 1)).toISOString().slice(0, 10);
  return { start, end: startOfDayIn(zone, next) };
}

function startOfDayIn(zone: string, date: string): Date {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  // Start from UTC midnight and walk to the first instant whose local date is [date].
  let guess = Date.UTC(y, m - 1, d) - 14 * 3_600_000;
  for (let i = 0; i < 48 && localDateIn(zone, new Date(guess)) < date; i += 1) guess += 3_600_000;
  for (let i = 0; i < 120 && localDateIn(zone, new Date(guess - 60_000)) === date; i += 1)
    guess -= 60_000;
  return new Date(guess);
}

/** Local dates in [zone] touched by a record (both days for a span crossing midnight). */
export function datesTouched(zone: string, record: Pick<SummaryRecord, 'occurredAt' | 'endedAt'>) {
  const first = localDateIn(zone, record.occurredAt);
  const last = localDateIn(zone, record.endedAt ?? record.occurredAt);
  const dates = [first];
  let cursor = first;
  for (let i = 0; i < 3 && cursor < last; i += 1) {
    const [y, m, d] = cursor.split('-').map(Number) as [number, number, number];
    cursor = new Date(Date.UTC(y, m - 1, d + 1)).toISOString().slice(0, 10);
    dates.push(cursor);
  }
  return dates;
}

/**
 * "Đã ghi hôm nay" (DayRhythm 48:409): bottle count + ml, breast count + minutes, finished
 * sleep clipped to the day, diaper count (both counts as wet and dirty), pump and growth apart.
 * Point records count on the day they occurred; spans count by overlap.
 */
export function summarizeDay(
  zone: string,
  date: string,
  records: readonly SummaryRecord[],
): DaySummary {
  const { start, end } = dayBoundsIn(zone, date);
  const summary: DaySummary = {
    date,
    bottle: { count: 0, ml: 0 },
    breast: { count: 0, minutes: 0 },
    sleepMinutes: 0,
    diaper: { count: 0, wet: 0, dirty: 0 },
    pump: { count: 0, ml: 0 },
    growth: { count: 0 },
  };
  for (const r of records) {
    const onDay = r.occurredAt >= start && r.occurredAt < end;
    switch (r.type) {
      case 'bottle':
        if (!onDay) break;
        summary.bottle.count += 1;
        summary.bottle.ml += typeof r.data.amountMl === 'number' ? r.data.amountMl : 0;
        break;
      case 'breast':
        if (!onDay) break;
        summary.breast.count += 1;
        summary.breast.minutes += typeof r.data.durationMin === 'number' ? r.data.durationMin : 0;
        break;
      case 'sleep': {
        if (!r.endedAt) break; // running sleep is not counted until it ends
        const from = Math.max(r.occurredAt.getTime(), start.getTime());
        const to = Math.min(r.endedAt.getTime(), end.getTime());
        if (to > from) summary.sleepMinutes += Math.round((to - from) / 60_000);
        break;
      }
      case 'diaper':
        if (!onDay) break;
        summary.diaper.count += 1;
        if (r.data.kind !== 'dirty') summary.diaper.wet += 1;
        if (r.data.kind !== 'wet') summary.diaper.dirty += 1;
        break;
      case 'pump':
        if (!onDay) break;
        summary.pump.count += 1;
        summary.pump.ml += typeof r.data.amountMl === 'number' ? r.data.amountMl : 0;
        break;
      case 'growth':
        if (onDay) summary.growth.count += 1;
        break;
    }
  }
  return summary;
}
