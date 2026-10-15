import { describe, expect, it } from 'vitest';
import { observationEpisodeSchema } from '../src/index.js';

// NL07b observation episodes: confirmed and closed by people, never by the server.
const open = {
  id: `ep_${'a'.repeat(32)}`,
  babyId: 'b1',
  startDate: '2026-10-12',
  endDate: null,
  confirmedBy: 'mom',
  checkInIds: [`ci_${'b'.repeat(32)}`],
  status: 'open' as const,
  closedBy: null,
};

describe('observationEpisodeSchema', () => {
  it('accepts an open episode and a closed one', () => {
    expect(observationEpisodeSchema.safeParse(open).success).toBe(true);
    expect(
      observationEpisodeSchema.safeParse({
        ...open,
        status: 'closed',
        endDate: '2026-10-14',
        closedBy: 'nanny',
      }).success,
    ).toBe(true);
  });

  it('refuses half-closed, reversed or empty episodes and bad ids', () => {
    for (const bad of [
      { ...open, status: 'closed' },
      { ...open, endDate: '2026-10-14' },
      { ...open, closedBy: 'mom' },
      { ...open, status: 'closed', endDate: '2026-10-10', closedBy: 'mom' },
      { ...open, checkInIds: [] },
      { ...open, checkInIds: ['ci_x'] },
      { ...open, id: 'ep_1' },
    ]) {
      expect(observationEpisodeSchema.safeParse(bad).success).toBe(false);
    }
  });
});
