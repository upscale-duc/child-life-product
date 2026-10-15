import { describe, expect, it } from 'vitest';
import {
  conflictIdOf,
  spansOverlap,
  bottleDataSchema,
  datesTouched,
  dayBoundsIn,
  growthDataSchema,
  pumpDataSchema,
  recordIdSchema,
  summarizeDay,
  type SummaryRecord,
} from '../src/index.js';

const zone = 'Asia/Ho_Chi_Minh'; // GMT+7, as in the Figma mocks
const at = (iso: string) => new Date(iso);

describe('care record shapes (S4)', () => {
  it('bottle amount is optional (2-tap save) but bounded', () => {
    expect(bottleDataSchema.safeParse({ amountMl: null, milk: 'formula' }).success).toBe(true);
    expect(bottleDataSchema.safeParse({ amountMl: 120, milk: 'breastMilk' }).success).toBe(true);
    expect(bottleDataSchema.safeParse({ amountMl: 0, milk: 'formula' }).success).toBe(false);
    expect(bottleDataSchema.safeParse({ amountMl: 12.5, milk: 'formula' }).success).toBe(false);
  });

  it('pump amount is required; growth weight is required, length optional', () => {
    expect(
      pumpDataSchema.safeParse({ side: 'both', amountMl: null, durationMin: 15 }).success,
    ).toBe(false);
    expect(
      growthDataSchema.safeParse({ weightKg: 4.3, lengthCm: null, measuredOn: '2026-10-08' })
        .success,
    ).toBe(true);
  });

  it('head circumference is optional, 20…60 cm (owner 2026-10-16; old records have no key)', () => {
    const base = { weightKg: 5.2, lengthCm: 58, measuredOn: '2026-10-08' };
    expect(growthDataSchema.strict().safeParse(base).success).toBe(true);
    expect(growthDataSchema.strict().safeParse({ ...base, headCm: 39 }).success).toBe(true);
    expect(growthDataSchema.strict().safeParse({ ...base, headCm: 38.5 }).success).toBe(true);
    expect(growthDataSchema.strict().safeParse({ ...base, headCm: null }).success).toBe(true);
    expect(growthDataSchema.safeParse({ ...base, headCm: 19.9 }).success).toBe(false);
    expect(growthDataSchema.safeParse({ ...base, headCm: 61 }).success).toBe(false);
    expect(growthDataSchema.safeParse({ ...base, headCm: '39' }).success).toBe(false);
  });

  it('record ids are client uuids', () => {
    expect(recordIdSchema.safeParse(`r_${'a'.repeat(32)}`).success).toBe(true);
    expect(recordIdSchema.safeParse('r_123').success).toBe(false);
  });
});

describe('day summaries in the baby time zone', () => {
  it('days start at local midnight', () => {
    const { start, end } = dayBoundsIn(zone, '2026-10-08');
    expect(start.toISOString()).toBe('2026-10-07T17:00:00.000Z');
    expect(end.toISOString()).toBe('2026-10-08T17:00:00.000Z');
  });

  it('matches the 19 Hôm nay mock: 2 bottles 240 ml, 1 breast 15 min, 7 h 50 sleep, 2 diapers', () => {
    const records: SummaryRecord[] = [
      // overnight 21:42 → 06:30 (only 00:00–06:30 counts today) and a nap 11:45 → 13:05
      {
        type: 'sleep',
        occurredAt: at('2026-10-07T14:42:00Z'),
        endedAt: at('2026-10-07T23:30:00Z'),
        data: {},
      },
      {
        type: 'sleep',
        occurredAt: at('2026-10-08T04:45:00Z'),
        endedAt: at('2026-10-08T06:05:00Z'),
        data: {},
      },
      // running sleep: not counted
      { type: 'sleep', occurredAt: at('2026-10-08T07:30:00Z'), endedAt: null, data: {} },
      {
        type: 'bottle',
        occurredAt: at('2026-10-08T01:00:00Z'),
        endedAt: null,
        data: { amountMl: 120, milk: 'breastMilk' },
      },
      {
        type: 'bottle',
        occurredAt: at('2026-10-08T07:20:00Z'),
        endedAt: null,
        data: { amountMl: 120, milk: 'formula' },
      },
      {
        type: 'breast',
        occurredAt: at('2026-10-08T04:30:00Z'),
        endedAt: at('2026-10-08T04:45:00Z'),
        data: { side: 'both', durationMin: 15 },
      },
      {
        type: 'diaper',
        occurredAt: at('2026-10-08T02:10:00Z'),
        endedAt: null,
        data: { kind: 'both' },
      },
      {
        type: 'diaper',
        occurredAt: at('2026-10-08T06:40:00Z'),
        endedAt: null,
        data: { kind: 'wet' },
      },
      {
        type: 'pump',
        occurredAt: at('2026-10-08T03:15:00Z'),
        endedAt: null,
        data: { side: 'both', amountMl: 90, durationMin: 15 },
      },
      // yesterday's bottle stays out
      {
        type: 'bottle',
        occurredAt: at('2026-10-07T16:30:00Z'),
        endedAt: null,
        data: { amountMl: 100, milk: 'formula' },
      },
    ];
    const s = summarizeDay(zone, '2026-10-08', records);
    expect(s.bottle).toEqual({ count: 2, ml: 240 });
    expect(s.breast).toEqual({ count: 1, minutes: 15 });
    expect(s.sleepMinutes).toBe(7 * 60 + 50);
    expect(s.diaper).toEqual({ count: 2, wet: 2, dirty: 1 });
    expect(s.pump).toEqual({ count: 1, ml: 90 });
  });

  it('a span crossing midnight touches both days', () => {
    expect(
      datesTouched(zone, {
        occurredAt: at('2026-10-07T14:42:00Z'),
        endedAt: at('2026-10-07T23:30:00Z'),
      }),
    ).toEqual(['2026-10-07', '2026-10-08']);
  });
});

describe('overlapping sleeps (R-075)', () => {
  it('detects overlap; touching ends are fine', () => {
    const span = (a: string, b: string) => ({ start: at(a), end: at(b) });
    expect(
      spansOverlap(
        span('2026-10-07T14:40:00Z', '2026-10-07T16:06:00Z'),
        span('2026-10-07T14:42:00Z', '2026-10-07T16:10:00Z'),
      ),
    ).toBe(true);
    expect(
      spansOverlap(
        span('2026-10-07T14:00:00Z', '2026-10-07T15:00:00Z'),
        span('2026-10-07T15:00:00Z', '2026-10-07T16:00:00Z'),
      ),
    ).toBe(false);
  });

  it('a pair has one id whatever the order', () => {
    expect(conflictIdOf('r_b', 'r_a')).toBe(conflictIdOf('r_a', 'r_b'));
  });
});

import vectors from './vectors/care-day.json' with { type: 'json' };

describe('shared day vectors (TS ↔ Dart)', () => {
  for (const v of vectors.vectors) {
    it(v.name, () => {
      const records = v.records.map((r) => ({
        type: r.type as SummaryRecord['type'],
        occurredAt: new Date(r.occurredAt),
        endedAt: r.endedAt ? new Date(r.endedAt) : null,
        data: r.data as Record<string, unknown>,
      }));
      const s = summarizeDay(v.zone, v.date, records);
      expect(s.bottle).toEqual(v.expect.bottle);
      expect(s.breast).toEqual(v.expect.breast);
      expect(s.sleepMinutes).toBe(v.expect.sleepMinutes);
      expect(s.diaper).toEqual(v.expect.diaper);
      expect(s.pump).toEqual(v.expect.pump);
    });
  }
});
