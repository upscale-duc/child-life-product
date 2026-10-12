import { describe, expect, it } from 'vitest';
import {
  bottleQuickPicksV1,
  capLevels,
  diffRows,
  levelAtLeast,
  levelsForRoles,
  parseReferenceCsv,
  referenceRowsSchemas,
  referenceV1,
  staffCan,
  staffRoleTemplates,
  staffRoles,
} from '../src/index.js';

// P-134 role levels and P-138 reference data: the pure rules shared by the portal and Functions.
describe('staff levels (P-134)', () => {
  it('levels are ordered and roles combine to the highest level', () => {
    expect(levelAtLeast('approve', 'edit')).toBe(true);
    expect(levelAtLeast('viewMasked', 'view')).toBe(false);
    expect(levelAtLeast(undefined, 'view')).toBe(false);
    const both = levelsForRoles(['support', 'analyst']);
    expect(both).toMatchObject({
      support: 'edit',
      analyticsExport: 'edit',
      families: 'viewMasked',
    });
    // S15 trưởng nhóm reads as Admin; unknown roles give nothing.
    expect(levelsForRoles(['lead'])).toEqual(staffRoleTemplates.admin);
    expect(staffCan(levelsForRoles(['nope']), 'overview.view')).toBe(false);
  });

  it('the v1.0 matrix: P-120, P-139, the QA handbook and the locked roles', () => {
    const can = (role: string, action: Parameters<typeof staffCan>[1]) =>
      staffCan(levelsForRoles([role]), action);
    expect(can('ops', 'storage.decide') && !can('ops', 'storage.large')).toBe(true);
    expect(can('admin', 'storage.large')).toBe(true);
    expect(can('eng', 'jobs.rerun') && !can('eng', 'jobs.approve')).toBe(true);
    expect(can('eng', 'support.view')).toBe(false);
    expect(can('expert', 'reference.approve') && !can('expert', 'overview.view')).toBe(true);
    expect(can('admin', 'staff.manage') && !can('admin', 'staff.owners')).toBe(true);
    expect(can('owner', 'staff.owners')).toBe(true);
    for (const r of staffRoles) expect(can(r, 'qa.view'), r).toBe(true);
    expect(staffRoles.filter((r) => can(r, 'qa.manage')).sort()).toEqual([
      'admin',
      'eng',
      'owner',
      'qa',
    ]);
    expect(can('qa', 'overview.view')).toBe(false);
    // Locked roles ignore stored edits.
    const edited = levelsForRoles(['qa'], { qa: { ...staffRoleTemplates.qa, overview: 'full' } });
    expect(edited.overview).toBe('none');
  });

  it('Hỗ trợ can never be given transfer, export or deletion re-runs', () => {
    const wanted = {
      ...staffRoleTemplates.support,
      familyTransfer: 'full',
      analyticsExport: 'edit',
      dataJobs: 'approve',
    } as const;
    expect(capLevels('support', { ...wanted })).toMatchObject({
      familyTransfer: 'none',
      analyticsExport: 'none',
      dataJobs: 'view',
    });
    expect(capLevels('ops', { ...wanted }).familyTransfer).toBe('full');
  });
});

describe('reference data (P-138)', () => {
  it('v1 of every dataset is valid and is what the app shipped', () => {
    expect(
      referenceRowsSchemas['bottle.quickPicks'].safeParse(referenceV1('bottle.quickPicks')).success,
    ).toBe(true);
    expect(
      referenceRowsSchemas['vaccines.schedule'].safeParse(referenceV1('vaccines.schedule')).success,
    ).toBe(true);
    const length = referenceV1('growth.length');
    expect(referenceRowsSchemas['growth.length'].safeParse(length).success).toBe(true);
    // WHO length-for-age, boys, birth: P3 46.3 · median 49.9 · P97 53.4 (as Figma C01).
    const birth = length.find((r) => r.sex === 'boy' && r.unit === 'week' && r.age === 0)!;
    expect([birth.low, birth.median, birth.high].map((v) => v.toFixed(1))).toEqual([
      '46.3',
      '49.9',
      '53.4',
    ]);
    expect(length.filter((r) => r.unit === 'month')).toHaveLength(122);
  });

  it('CSV: header, decimal comma with semicolons, row errors, order and bands', () => {
    const ok = parseReferenceCsv(
      'growth.length',
      '﻿age;low;median;high\n0;46,3;49,9;53,4\n1;47,5;51,1;54,7\n',
      { sex: 'boy', unit: 'week' },
    );
    expect(ok.errors).toEqual([]);
    expect(ok.rows).toEqual([
      { sex: 'boy', unit: 'week', age: 0, low: 46.3, median: 49.9, high: 53.4 },
      { sex: 'boy', unit: 'week', age: 1, low: 47.5, median: 51.1, high: 54.7 },
    ]);
    expect(parseReferenceCsv('growth.length', 'tuoi,a,b,c\n0,1,2,3').errors[0]!.message).toBe(
      'header:age,low,median,high',
    );
    const bad = parseReferenceCsv(
      'growth.length',
      'age,low,median,high\n0,50,49,53\n2,47,51,54\n1,48,52,55',
      { sex: 'girl', unit: 'week' },
    );
    expect(bad.errors.map((e) => e.line)).toEqual([2, 4]);
    const bottle = parseReferenceCsv(
      'bottle.quickPicks',
      'from_day,to_day,pick1,pick2,pick3,pick4,step_ml\n0,7,30,45,60,75,5\n10,,60,90,120,150,10',
    );
    expect(bottle.errors).toEqual([{ line: 3, message: 'bands-gap' }]);
  });

  it('diff names the rows that changed', () => {
    const next = bottleQuickPicksV1.map((r, i) => (i === 2 ? { ...r, stepMl: 5 } : r));
    expect(diffRows('bottle.quickPicks', bottleQuickPicksV1, next)).toEqual({
      added: [],
      removed: [],
      changed: ['28'],
    });
  });
});
