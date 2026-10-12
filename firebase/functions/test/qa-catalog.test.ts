import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  qaCaseContentSchema,
  qaCaseIdPattern,
  qaModulePrefix,
  qaModules,
} from '@child-life/contracts';
import { describe, expect, it } from 'vitest';
import { qaCatalog } from '../src/qa-catalog.js';

// P-132: the built-in QA cases. Results are keyed by case id, so ids must stay stable and unique.
describe('built-in QA catalog', () => {
  it('every case is valid as the portal editor would save it', () => {
    for (const c of qaCatalog) {
      expect(qaCaseContentSchema.safeParse(c).success, c.id).toBe(true);
    }
  });

  it('ids are unique, built-in shaped and carry their module prefix', () => {
    const ids = qaCatalog.map((c) => c.id);
    expect(new Set(ids).size).toBe(ids.length);
    for (const c of qaCatalog) {
      expect(c.id, c.id).toMatch(qaCaseIdPattern);
      expect(c.id, c.id).toMatch(/^[A-Z]+-\d{3}$/);
      expect(c.id.startsWith(`${qaModulePrefix[c.module]}-`), c.id).toBe(true);
    }
  });

  it('cases are grouped by module, in handbook order', () => {
    const order = qaCatalog.map((c) => qaModules.indexOf(c.module));
    expect(order).toEqual([...order].sort((a, b) => a - b));
  });

  it('every module has a case, and the critical path is smoke', () => {
    for (const m of qaModules) {
      expect(
        qaCatalog.some((c) => c.module === m),
        m,
      ).toBe(true);
    }
    const smoke = qaCatalog.filter((c) => c.level === 'smoke').length;
    expect(smoke).toBeGreaterThanOrEqual(15);
    expect(smoke).toBeLessThan(qaCatalog.length / 2);
  });

  it('references point at ids the business map defines', () => {
    const map = readFileSync(
      join(import.meta.dirname, '../../../docs/product/business-map.md'),
      'utf8',
    );
    for (const c of qaCatalog) {
      for (const ref of c.refs ?? []) {
        if (/^[RDPGQ]-\d+$/.test(ref)) expect(map.includes(ref), `${c.id} → ${ref}`).toBe(true);
      }
    }
  });
});
