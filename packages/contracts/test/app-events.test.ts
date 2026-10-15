import { describe, expect, it } from 'vitest';
import { appEventDims, appEvents, recordAppEventSchema } from '../src/index.js';

describe('app events (brief p.20)', () => {
  it('a dimension must be one of the event’s closed values', () => {
    expect(recordAppEventSchema.safeParse({ event: 'paywallSeen', dim: 'templates' }).success).toBe(
      true,
    );
    expect(recordAppEventSchema.safeParse({ event: 'paywallSeen', dim: 'Teddy' }).success).toBe(
      false,
    );
    expect(recordAppEventSchema.safeParse({ event: 'checkinSaved', dim: 'x' }).success).toBe(false);
    expect(recordAppEventSchema.parse({ event: 'checkinSaved' })).toEqual({
      event: 'checkinSaved',
      n: 1,
    });
  });
  it('server-authoritative events cannot be recorded by the app', () => {
    expect(recordAppEventSchema.safeParse({ event: 'summaryGenerated', dim: 'ai' }).success).toBe(
      false,
    );
  });
  it('every dimension belongs to a known event', () => {
    for (const e of Object.keys(appEventDims)) expect(appEvents).toContain(e);
  });
});
