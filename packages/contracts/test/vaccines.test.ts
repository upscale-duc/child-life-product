import { describe, expect, it } from 'vitest';
import {
  doseKeyOf,
  plannedDate,
  scheduleFor,
  vaccineDoseKeySchema,
  vaccineSchedule,
} from '../src/index.js';

// Sổ tiêm chủng reference schedule (Figma VX 1 / VX 1b, P-133).
describe('the schedule as drawn', () => {
  it('30 doses in 14 rows on the 6in1 path; the 5in1 path adds 3 polio doses', () => {
    const count = (dtp: '6in1' | '5in1' | null) =>
      scheduleFor(dtp).reduce((n, v) => n + v.months.length, 0);
    expect(scheduleFor('6in1')).toHaveLength(14);
    expect(count('6in1')).toBe(30);
    expect(count(null)).toBe(30);
    expect(count('5in1')).toBe(33);
  });

  it('every dose has a valid key and ages stay within 0–24 months', () => {
    for (const v of vaccineSchedule) {
      v.months.forEach((m, i) => {
        expect(vaccineDoseKeySchema.safeParse(doseKeyOf(v.id, i + 1)).success).toBe(true);
        expect(m).toBeGreaterThanOrEqual(0);
        expect(m).toBeLessThanOrEqual(24);
      });
    }
  });
});

describe('planned dates (DOB + calendar months)', () => {
  it('Teddy, born 17/9/2026: 2 tháng = 17/11, 24 tháng = 17/9/2028', () => {
    expect(plannedDate('2026-09-17', 0)).toBe('2026-09-17');
    expect(plannedDate('2026-09-17', 2)).toBe('2026-11-17');
    expect(plannedDate('2026-09-17', 4)).toBe('2027-01-17');
    expect(plannedDate('2026-09-17', 24)).toBe('2028-09-17');
  });

  it('a day the month lacks falls back to its last day', () => {
    expect(plannedDate('2026-01-31', 1)).toBe('2026-02-28');
    expect(plannedDate('2027-12-31', 2)).toBe('2028-02-29');
  });
});
