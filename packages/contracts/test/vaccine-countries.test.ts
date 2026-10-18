import { describe, expect, it } from 'vitest';
import { countryScheduleOf, countryVaccineSchedules, referenceRowsSchemas } from '../src/index.js';

// D-084: the routine schedules of the countries where most Child Life families abroad live.
describe('country vaccine schedules', () => {
  it('cover the six first countries', () => {
    expect(Object.keys(countryVaccineSchedules).sort()).toEqual([
      'AU',
      'GB',
      'JP',
      'KR',
      'SG',
      'US',
    ]);
  });

  it.each(Object.values(countryVaccineSchedules).map((s) => [s.country, s] as const))(
    '%s is a valid schedule with its sources',
    (code, s) => {
      expect(s.country).toBe(code);
      expect(s.checkedOn).toMatch(/^\d{4}-\d{2}-\d{2}$/);
      expect(s.programmeName.vi.length).toBeGreaterThan(5);
      expect(s.sources.length).toBeGreaterThanOrEqual(1);
      for (const src of s.sources) expect(src.url).toMatch(/^https:\/\/[^/]+\//);
      const rows = referenceRowsSchemas['vaccines.schedule'].safeParse(s.defs);
      expect(rows.success, JSON.stringify(rows.error?.issues.slice(0, 3))).toBe(true);
      expect(new Set(s.defs.map((d) => d.id)).size).toBe(s.defs.length);
      // The 6in1 / 5in1 choice and "Tiêm chủng mở rộng" are Việt Nam's.
      for (const d of s.defs) {
        expect(d.programme, d.id).not.toBe('choice');
        expect(d.only5in1 ?? false, d.id).toBe(false);
        expect(d.dtpSeries ?? false, d.id).toBe(false);
      }
    },
  );

  it('Việt Nam and countries without a schedule fall back to the Việt Nam book', () => {
    expect(countryScheduleOf('VN')).toBeNull();
    expect(countryScheduleOf(null)).toBeNull();
    expect(countryScheduleOf('FR')).toBeNull();
    expect(countryScheduleOf('US')?.programmeName.en).toContain('CDC');
  });
});
