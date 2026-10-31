import { randomUUID } from 'node:crypto';
import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { localDateIn } from '@child-life/contracts';

export interface AiCallUsage {
  callId: string;
  operation:
    | 'extract'
    | 'understand'
    | 'word'
    | 'images'
    | 'summary'
    | 'story'
    | 'storyAssist'
    | 'expenses'
    // Sản phẩm · Copilot (D-155): staff questions about product knowledge, on Claude.
    | 'productCopilot';
  model: string;
  promptVersion: string;
  status: 'ok' | 'http' | 'network' | 'timeout' | 'invalid';
  durationMs: number;
  inputTokens: number | null;
  outputTokens: number | null;
  cachedInputTokens: number | null;
}
export const aiCallId = () => randomUUID();
const token = (v: unknown): number | null =>
  typeof v === 'number' && Number.isSafeInteger(v) && v >= 0 ? v : null;
export function providerUsage(value: unknown) {
  const u = (value && typeof value === 'object' ? value : {}) as Record<string, unknown>;
  const details = u.prompt_tokens_details as Record<string, unknown> | undefined;
  return {
    inputTokens: token(u.prompt_tokens),
    outputTokens: token(u.completion_tokens),
    cachedInputTokens: token(details?.cached_tokens),
  };
}

/** LUM-01: aggregate metadata only. No prompts, response text, paths or child identifiers.
 * Missing usage stays unknown; commercial assistant credits remain a separate ledger. */
export async function recordAiCall(db: Firestore, call: AiCallUsage, now = new Date()) {
  const day = localDateIn('Asia/Ho_Chi_Minh', now);
  const ref = db.doc(`aiUsageDaily/${day}`);
  const known = call.inputTokens !== null && call.outputTokens !== null;
  const key = `${call.model}__${call.operation}`.replace(/[^A-Za-z0-9_-]/g, '_');
  await db.runTransaction(async (tx) => {
    // Short-lived metadata-only delivery marker makes observer retries idempotent.
    const seen = db.doc(`aiUsageReceipts/${call.callId}`);
    const [receipt, rates] = await Promise.all([
      tx.get(seen),
      tx.get(db.doc('config/aiModelRates')),
    ]);
    if (receipt.exists) return;
    const models = rates.get('models') as Record<string, unknown> | undefined;
    const rate =
      models && Object.hasOwn(models, call.model)
        ? (models[call.model] as Record<string, unknown>)
        : undefined;
    const validRate = (v: unknown): v is number =>
      typeof v === 'number' && Number.isFinite(v) && v >= 0 && v <= 1_000_000;
    const cached = call.cachedInputTokens ?? 0;
    const rated =
      known &&
      call.cachedInputTokens !== null &&
      rates.get('currency') === 'USD' &&
      typeof rates.get('version') === 'string' &&
      /^[A-Za-z0-9_-]{1,40}$/.test(rates.get('version')) &&
      validRate(rate?.inputPerMillion) &&
      validRate(rate?.outputPerMillion) &&
      (cached === 0 || validRate(rate?.cachedInputPerMillion)) &&
      cached <= call.inputTokens!;
    const micros = rated
      ? Math.round(
          (call.inputTokens! - cached) * Number(rate!.inputPerMillion) +
            cached * Number(rate!.cachedInputPerMillion ?? 0) +
            call.outputTokens! * Number(rate!.outputPerMillion),
        )
      : 0;
    const costKnown = rated && Number.isSafeInteger(micros);
    tx.create(seen, { expiresAt: new Date(now.getTime() + 30 * 86_400_000) });
    const counters = {
      calls: FieldValue.increment(1),
      knownUsage: FieldValue.increment(known ? 1 : 0),
      unknownUsage: FieldValue.increment(known ? 0 : 1),
      inputTokens: FieldValue.increment(call.inputTokens ?? 0),
      outputTokens: FieldValue.increment(call.outputTokens ?? 0),
      cachedInputTokens: FieldValue.increment(call.cachedInputTokens ?? 0),
      knownCachedUsage: FieldValue.increment(call.cachedInputTokens !== null ? 1 : 0),
      ratedCalls: FieldValue.increment(costKnown ? 1 : 0),
      unratedCalls: FieldValue.increment(costKnown ? 0 : 1),
      estimatedCostUsdMicros: FieldValue.increment(costKnown ? micros : 0),
      durationMs: FieldValue.increment(call.durationMs),
    };
    tx.set(
      ref,
      {
        day,
        version: 1,
        ...counters,
        byModel: {
          [key]: {
            model: call.model,
            operation: call.operation,
            promptVersion: call.promptVersion,
            ...counters,
            ...(costKnown
              ? {
                  byRateVersion: {
                    [rates.get('version') as string]: {
                      calls: FieldValue.increment(1),
                      estimatedCostUsdMicros: FieldValue.increment(micros),
                    },
                  },
                }
              : {}),
            statuses: { [call.status]: FieldValue.increment(1) },
          },
        },
      },
      { merge: true },
    );
  });
}

export async function cleanupAiUsage(db: Firestore, now: Date) {
  const receipts = await db
    .collection('aiUsageReceipts')
    .where('expiresAt', '<', now)
    .limit(400)
    .get();
  const batch = db.batch();
  for (const d of receipts.docs) batch.delete(d.ref);
  await batch.commit();
  return receipts.size;
}

/** Instrument the other provider adapters without changing their response/credit contracts. */
export async function observedAiFetch(
  fetchImpl: typeof fetch,
  url: string,
  init: RequestInit,
  metadata: Pick<AiCallUsage, 'model' | 'operation' | 'promptVersion'>,
  observe?: (call: AiCallUsage) => Promise<void>,
): Promise<Response> {
  const started = Date.now();
  let usage = providerUsage(null);
  let model = metadata.model;
  let status: AiCallUsage['status'] = 'network';
  try {
    const res = await fetchImpl(url, init);
    status = res.ok ? 'ok' : 'http';
    try {
      const body = (await res.clone().json()) as { usage?: unknown; model?: unknown };
      usage = providerUsage(body.usage);
      if (typeof body.model === 'string' && /^[A-Za-z0-9_.:-]{1,100}$/.test(body.model))
        model = body.model;
    } catch {
      if (res.ok) status = 'invalid';
    }
    return res;
  } catch (error) {
    status = init.signal?.aborted ? 'timeout' : 'network';
    throw error;
  } finally {
    try {
      await observe?.({
        ...metadata,
        model,
        callId: aiCallId(),
        status,
        durationMs: Math.max(0, Date.now() - started),
        ...usage,
      });
    } catch {
      /* Usage recording must not fail a provider answer. */
    }
  }
}
