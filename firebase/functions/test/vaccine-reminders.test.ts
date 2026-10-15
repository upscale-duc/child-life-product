import { describe, expect, it } from 'vitest';
import { atLocalHour, dueReminders, openDoses, vaccineCopy } from '../src/vaccine-reminders.js';

// Sổ tiêm chủng reminders (VX 2 / 8 / 9a, P-133): Teddy, born 17/9/2026, in Hồ Chí Minh (UTC+7).
const zone = 'Asia/Ho_Chi_Minh';
const vn = (d: string, h: number, m = 0) =>
  new Date(`${d}T${String(h - 7).padStart(2, '0')}:${String(m).padStart(2, '0')}:00Z`);
type Rec = { status: string; plannedOn: string | null };
const birth = new Map<string, Rec>([
  ['vitk_1', { status: 'given', plannedOn: null }],
  ['bcg_1', { status: 'given', plannedOn: null }],
  ['hepb_1', { status: 'given', plannedOn: null }],
]);

describe('when they ring', () => {
  it('19:00 local is 12:00 UTC in Hồ Chí Minh', () => {
    expect(atLocalHour(zone, '2026-11-16', 19).toISOString()).toBe('2026-11-16T12:00:00.000Z');
  });

  it('the 2-month shots: 3 days before and the evening before, at 19:00', () => {
    const doses = openDoses('2026-09-17', null, birth);
    expect(dueReminders(zone, doses, [], vn('2026-11-14', 18, 59))).toEqual([]);
    const threeDays = dueReminders(zone, doses, [], vn('2026-11-14', 19, 3));
    expect(threeDays.map((r) => [r.date, r.kind])).toEqual([['2026-11-17', '3d']]);
    expect(threeDays[0]!.doses.map((d) => `${d.def.id}_${d.dose}`)).toEqual([
      'dtp_1',
      'rota_1',
      'pcv_1',
    ]);
    const eve = dueReminders(zone, doses, [], vn('2026-11-16', 19, 1));
    expect(eve.map((r) => [r.date, r.kind])).toEqual([['2026-11-17', 'eve']]);
    // Long after, nothing (a new plan does not ring old dates).
    expect(dueReminders(zone, doses, [], vn('2026-11-17', 9))).toEqual([]);
  });

  it('a rescheduled dose rings only the evening before; a snooze at 07:00', () => {
    const records = new Map<string, Rec>([
      ...birth,
      ['rota_1', { status: 'planned', plannedOn: '2026-11-25' }],
    ]);
    const doses = openDoses('2026-09-17', null, records);
    expect(dueReminders(zone, doses, [], vn('2026-11-22', 19, 1))).toEqual([]);
    expect(dueReminders(zone, doses, [], vn('2026-11-24', 19, 1)).map((r) => r.kind)).toEqual([
      'eve',
    ]);
    expect(
      dueReminders(zone, doses, ['2026-11-17'], vn('2026-11-17', 7, 2)).map((r) => [
        r.date,
        r.kind,
      ]),
    ).toEqual([['2026-11-17', 'morning']]);
  });

  it('given and declined doses never ring; 5in1 adds polio', () => {
    const records = new Map<string, Rec>([
      ...birth,
      ['dtp_1', { status: 'given', plannedOn: null }],
      ['rota_1', { status: 'declined', plannedOn: null }],
    ]);
    const keys = openDoses('2026-09-17', '5in1', records)
      .filter((d) => d.months === 2)
      .map((d) => `${d.def.id}_${d.dose}`);
    expect(keys).toEqual(['polio_1', 'pcv_1']);
  });
});

describe('VX 8 copy (no baby name, R-120)', () => {
  it('vi and en', () => {
    const doses = openDoses('2026-09-17', null, birth).filter((d) => d.months === 2);
    expect(vaccineCopy('eve', doses, 'vi')).toEqual({
      title: 'Ngày mai có lịch tiêm của bé',
      // EN08 (D-076 #2): what to bring, on the eve and the morning.
      body: '6in1 · Rota · Phế cầu (mũi 1) · Mốc 2 tháng tuổi. Nhớ mang sổ tiêm và một chiếc khăn mỏng.',
    });
    expect(vaccineCopy('3d', doses, 'vi').body).toBe(
      '6in1 · Rota · Phế cầu (mũi 1) · Mốc 2 tháng tuổi',
    );
    expect(vaccineCopy('3d', doses, 'en').title).toBe('A vaccination is due in 3 days');
    expect(vaccineCopy('morning', doses, 'en').body).toBe(
      '6-in-1 · Rotavirus · Pneumococcal (dose 1) · 2-month milestone. Remember the vaccination book and a thin towel.',
    );
  });
});
