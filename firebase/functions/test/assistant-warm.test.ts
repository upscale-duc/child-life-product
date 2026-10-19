import { describe, expect, it } from 'vitest';
import { isAssistantWarmup, warmAssistant } from '../src/assistant-warm.js';

// Lumi L2 (D-088 §4.4): the warm-up ping and the request the callables answer before any auth.
describe('assistant warm-up', () => {
  it('only exactly { warmup: true } is a warm-up', () => {
    expect(isAssistantWarmup({ warmup: true })).toBe(true);
    for (const d of [
      null,
      undefined,
      {},
      { warmup: 'true' },
      { warmup: true, taskId: 'tk_x' },
      [{ warmup: true }],
      'warmup',
    ]) {
      expect(isAssistantWarmup(d)).toBe(false);
    }
  });

  it('pings startTask and getAssistantTask with the callable body; failures are reported', async () => {
    const sent: { url: string; body: string }[] = [];
    const fake = (async (url: string, init: RequestInit) => {
      sent.push({ url, body: String(init.body) });
      if (url.endsWith('/getAssistantTask')) throw new Error('down');
      return new Response('{"result":{"warm":true}}', { status: 200 });
    }) as unknown as typeof fetch;
    const r = await warmAssistant('child-life-dev', 'asia-southeast1', fake);
    expect(sent.map((x) => x.url).sort()).toEqual([
      'https://asia-southeast1-child-life-dev.cloudfunctions.net/getAssistantTask',
      'https://asia-southeast1-child-life-dev.cloudfunctions.net/startTask',
    ]);
    expect(JSON.parse(sent[0]!.body)).toEqual({ data: { warmup: true } });
    expect(r.find((x) => x.fn === 'startTask')!.status).toBe(200);
    expect(r.find((x) => x.fn === 'getAssistantTask')!.status).toBeNull();
  });
});
