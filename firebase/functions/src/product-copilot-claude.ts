import Anthropic from '@anthropic-ai/sdk';
import { COPILOT_PROMPT_VERSION } from '@child-life/contracts';
import { aiCallId, type AiCallUsage } from './ai-telemetry.js';
import { copilotOutputSchema, type CopilotModel, type CopilotModelCall } from './product-copilot.js';

/**
 * Sản phẩm · Copilot on Claude (owner, 2026-10-31). Server-side only; the key comes from the
 * `ANTHROPIC_API_KEY` secret. Only product documentation and code metadata are sent — never family
 * data. Structured output through `output_config.format`; the rules and the registry form the
 * cached prefix; a policy decline falls back server-side (`fallbacks: "default"`). Telemetry keeps
 * token counts only (LUM-01 shape), no prompt or answer text.
 */
export function claudeCopilotModel(
  apiKey: string,
  model: string,
  observe?: (call: AiCallUsage) => Promise<void>,
): CopilotModel {
  const client = new Anthropic({ apiKey, timeout: 90_000, maxRetries: 1 });
  return {
    model,
    async answer(call: CopilotModelCall) {
      const started = Date.now();
      let status: AiCallUsage['status'] = 'network';
      let usage: Pick<AiCallUsage, 'inputTokens' | 'outputTokens' | 'cachedInputTokens'> = {
        inputTokens: null,
        outputTokens: null,
        cachedInputTokens: null,
      };
      let served = model;
      try {
        const response = await client.beta.messages.create({
          model,
          max_tokens: 16000,
          betas: ['server-side-fallback-2026-07-01'],
          fallbacks: 'default',
          output_config: {
            effort: 'medium',
            format: { type: 'json_schema', schema: call.schema ?? (copilotOutputSchema as unknown as Record<string, unknown>) },
          },
          system: [
            { type: 'text', text: call.system },
            // Changes only when a change set is approved: the cached part of every request.
            { type: 'text', text: call.registry, cache_control: { type: 'ephemeral' } },
          ],
          messages: [{ role: 'user', content: call.user }],
        });
        status = 'ok';
        served = response.model;
        usage = {
          inputTokens: response.usage.input_tokens + (response.usage.cache_creation_input_tokens ?? 0),
          outputTokens: response.usage.output_tokens,
          cachedInputTokens: response.usage.cache_read_input_tokens ?? 0,
        };
        if (response.stop_reason === 'refusal') return { refused: true, output: null };
        const text = response.content
          .filter((b): b is Anthropic.Beta.BetaTextBlock => b.type === 'text')
          .map((b) => b.text)
          .join('');
        try {
          return { refused: false, output: JSON.parse(text) as unknown };
        } catch {
          status = 'invalid';
          throw new Error(response.stop_reason === 'max_tokens' ? 'claude max_tokens' : 'claude invalid json');
        }
      } catch (error) {
        if (error instanceof Anthropic.APIConnectionTimeoutError) status = 'timeout';
        else if (error instanceof Anthropic.APIError && error.status) status = 'http';
        throw error;
      } finally {
        await observe?.({
          callId: aiCallId(),
          operation: 'productCopilot',
          model: served,
          promptVersion: COPILOT_PROMPT_VERSION,
          status,
          durationMs: Date.now() - started,
          ...usage,
        }).catch(() => undefined);
      }
    },
  };
}
