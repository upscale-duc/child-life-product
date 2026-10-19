import { describe, expect, it } from 'vitest';
import { HopTimer } from '../src/assistant-timing.js';

// Lumi L2: per-hop timings (names and milliseconds only).
describe('HopTimer', () => {
  it('adds up hops, times async work and reports the total with labels only', async () => {
    let t = 0;
    const h = new HopTimer(() => t);
    t = 40;
    h.mark('scope');
    t = 50;
    h.mark('scope');
    await h.time('model', async () => {
      t = 2450;
    });
    t = 2600;
    h.mark('settle');
    expect(h.payload({ path: 'rules', taskId: 'tk_1' })).toEqual({
      path: 'rules',
      taskId: 'tk_1',
      hops: { scope: 50, model: 2400, settle: 150 },
      totalMs: 2600,
    });
  });
});
