import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { metricRegistrySchema } from '@child-life/contracts';
import { describe, expect, it } from 'vitest';
import { instrumentationOf, parseMetricDictionary } from '../src/product-hub-ingest.js';
import { metricProbe } from '../src/product-hub-metric-probe.js';

// Sản phẩm · Phase 4 before launch (D-155): what the analytics code computes, from the code.
const repo = resolve(import.meta.dirname, '../../..');
const read = (p: string) => readFileSync(resolve(repo, p), 'utf8');

describe('metric dictionary', () => {
  const rows = parseMetricDictionary(read('docs/product-analytics/02-metric-dictionary.md'));
  it('reads all 50 metrics with their section and plan word', () => {
    expect(rows).toHaveLength(50);
    expect(rows.find((r) => r.id === 'A01')).toMatchObject({ name: 'New users', planStatus: 'extend' });
    expect(new Set(rows.map((r) => r.section)).size).toBe(4);
  });
  it('the mapping only names dictionary metrics and real reducer ids', () => {
    const mapping = metricRegistrySchema.parse(JSON.parse(read('docs/product-hub/registry/metrics.json')));
    const probe = metricProbe(read('firebase/functions/src/product-analytics-reducer.ts'), new Date('2026-10-31T00:00:00Z'));
    for (const m of mapping.metrics) {
      expect(rows.some((r) => r.id === m.id), m.id).toBe(true);
      for (const id of m.reducerIds) expect(probe[id], `${m.id} → ${id}`).toBeDefined();
    }
  });
});

describe('instrumentation', () => {
  it('reads the reducer answers', () => {
    expect(instrumentationOf([], {})).toBe('defined_only');
    expect(instrumentationOf(['X'], {})).toBe('defined_only');
    expect(instrumentationOf(['A'], { A: 'provisional/none' })).toBe('computed');
    expect(instrumentationOf(['A', 'B'], { A: 'provisional/none', B: 'unavailable/not_instrumented' })).toBe('partial');
    expect(instrumentationOf(['B'], { B: 'unavailable/not_instrumented' })).toBe('not_instrumented');
    expect(instrumentationOf(['C'], { C: 'unavailable/no_source' })).toBe('no_source');
    expect(instrumentationOf(['A', 'Z'], { A: 'ready/none' })).toBe('partial');
  });

  it('the dense probe tells a missing producer from "no data yet"', () => {
    const probe = metricProbe(read('firebase/functions/src/product-analytics-reducer.ts'), new Date('2026-10-31T00:00:00Z'));
    // Data-driven metrics compute once events arrive (empty input would call them missing).
    for (const id of ['A01', 'A08', 'A10', 'F04', 'M_ready', 'E_ENG-01', 'C_input']) {
      expect(probe[id], id).toMatch(/\/(none|window_open)$/);
    }
    // No producer in code at all.
    expect(probe['M_approved']).toBe('unavailable/not_instrumented');
    expect(probe['C_actual']).toBe('unavailable/no_source');
  });
});
