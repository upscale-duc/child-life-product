import { describe, it, expect } from 'vitest';
import { openAiModelGateway } from '../src/assistant-model.js';
import { observedAiFetch, providerUsage, type AiCallUsage } from '../src/ai-telemetry.js';
describe('provider metadata boundary', () => {
  it('rejects invalid/missing usage instead of inventing zero tokens', () => {
    expect(providerUsage({ prompt_tokens: -1, completion_tokens: 1.5 })).toEqual({
      inputTokens: null,
      outputTokens: null,
      cachedInputTokens: null,
    });
    expect(
      providerUsage({
        prompt_tokens: 200,
        completion_tokens: 10,
        prompt_tokens_details: { cached_tokens: 50 },
      }),
    ).toEqual({ inputTokens: 200, outputTokens: 10, cachedInputTokens: 50 });
  });
  it('observes actual returned model/usage and never sends facts to the observer', async () => {
    const calls: AiCallUsage[] = [];
    const gateway = openAiModelGateway(
      'test',
      'test-alias',
      (async () =>
        new Response(
          JSON.stringify({
            model: 'test-snapshot',
            usage: { prompt_tokens: 12, completion_tokens: 3 },
            choices: [{ message: { content: '{"text":"safe"}' } }],
          }),
        )) as typeof fetch,
      'test-understanding',
      async (call) => {
        calls.push(call);
      },
    );
    expect(
      await gateway.word(
        { locale: 'en', facts: [{ id: 'private-id', text: 'PRIVATE FAMILY TEXT' }] },
        new AbortController().signal,
      ),
    ).toEqual({ text: 'safe' });
    expect(calls).toHaveLength(1);
    expect(calls[0]).toMatchObject({
      model: 'test-snapshot',
      operation: 'word',
      inputTokens: 12,
      outputTokens: 3,
      status: 'ok',
    });
    expect(JSON.stringify(calls)).not.toMatch(/PRIVATE|private-id|choices|content/);
  });
  it('records unsuccessful/unknown calls and observer failures never break valid responses', async () => {
    const calls: AiCallUsage[] = [];
    const gateway = openAiModelGateway(
      'test',
      'test-model',
      (async () => new Response('{}', { status: 429 })) as typeof fetch,
      'test-model',
      async (c) => {
        calls.push(c);
      },
    );
    await expect(
      gateway.word({ locale: 'en', facts: [] }, new AbortController().signal),
    ).rejects.toThrow();
    expect(calls[0]).toMatchObject({ status: 'http', inputTokens: null, outputTokens: null });
    const good = openAiModelGateway(
      'test',
      'test-model',
      (async () =>
        new Response(
          JSON.stringify({ choices: [{ message: { content: '{}' } }] }),
        )) as typeof fetch,
      'test-model',
      async () => {
        throw Error('observer offline');
      },
    );
    await expect(
      good.word({ locale: 'en', facts: [] }, new AbortController().signal),
    ).resolves.toEqual({});
  });
  it('observes summary/story HTTP usage without exposing the request or response', async () => {
    const calls: AiCallUsage[] = [];
    const res = await observedAiFetch(
      (async () =>
        new Response(
          JSON.stringify({
            model: 'returned-model',
            usage: { prompt_tokens: 50, completion_tokens: 3 },
            error: { message: 'PRIVATE' },
          }),
          { status: 429 },
        )) as typeof fetch,
      'https://example.test',
      { body: 'PRIVATE INPUT' },
      { model: 'alias', operation: 'summary', promptVersion: 'test-v1' },
      async (call) => {
        calls.push(call);
      },
    );
    expect(res.status).toBe(429);
    expect(calls[0]).toMatchObject({
      operation: 'summary',
      status: 'http',
      model: 'returned-model',
      inputTokens: 50,
      outputTokens: 3,
    });
    expect(JSON.stringify(calls)).not.toContain('PRIVATE');
  });
});
