import { describe, expect, it } from 'vitest';
import { assistantContractVersion, startTaskRequestSchema } from '../src/index.js';

// Lumi L2 (D-088 §4.4): text skips `quoteTask`; `startTask` quotes inline.
const envelope = {
  contractVersion: assistantContractVersion,
  clientRequestId: '6f1c1d52-4a3e-4c55-9d43-0a7a0d3b2f11',
  locale: 'vi' as const,
};
const base = {
  ...envelope,
  conversationId: null,
  scope: { type: 'child' as const, babyId: 'b_1' },
  text: 'bé bú 120ml lúc 8h',
  attachmentIds: [],
};

describe('startTask without a quote (Lumi L2)', () => {
  it('a text start needs no quote id; an older client still sends one', () => {
    expect(startTaskRequestSchema.safeParse(base).success).toBe(true);
    expect(startTaskRequestSchema.safeParse({ ...base, quoteId: null }).success).toBe(true);
    const old = startTaskRequestSchema.parse({ ...base, quoteId: 'qt_1' });
    expect(old.quoteId).toBe('qt_1');
  });

  it('carries the module hint the quote used to carry, from the same list', () => {
    expect(startTaskRequestSchema.parse({ ...base, intentHint: 'expense' }).intentHint).toBe(
      'expense',
    );
    expect(startTaskRequestSchema.safeParse({ ...base, intentHint: 'money' }).success).toBe(false);
    expect(startTaskRequestSchema.safeParse({ ...base, quoteId: '' }).success).toBe(false);
  });
});
