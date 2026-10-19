/**
 * Lumi L2 (D-088 §4.4, owner 2026-10-19: no `minInstances`, keep the functions warm instead). A
 * scheduled ping sends an empty warm-up request to the callables a typed log goes through; they
 * answer it before any auth check or Firestore read (`isAssistantWarmup`), so a ping costs one
 * invocation and keeps one instance with its module graph loaded. Nothing here reads or logs
 * family data.
 */

/** The callables a typed log uses (text runs its worker inside `startTask`). */
export const warmAssistantTargets = ['startTask', 'getAssistantTask'] as const;

/** A warm-up request: exactly `{ warmup: true }` (anything else is an ordinary request). */
export function isAssistantWarmup(data: unknown): boolean {
  return (
    typeof data === 'object' &&
    data !== null &&
    !Array.isArray(data) &&
    Object.keys(data).length === 1 &&
    (data as { warmup?: unknown }).warmup === true
  );
}

export interface WarmResult {
  fn: string;
  status: number | null;
  ms: number;
}

/**
 * Pings each callable once over HTTPS (the callable protocol: POST `{ data }`), in parallel, with
 * a short deadline. A failed ping is reported, never thrown: the next one comes in five minutes.
 */
export async function warmAssistant(
  project: string,
  region: string,
  fetchImpl: typeof fetch = fetch,
  timeoutMs = 20_000,
): Promise<WarmResult[]> {
  return Promise.all(
    warmAssistantTargets.map(async (fn) => {
      const started = Date.now();
      try {
        const res = await fetchImpl(`https://${region}-${project}.cloudfunctions.net/${fn}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ data: { warmup: true } }),
          signal: AbortSignal.timeout(timeoutMs),
        });
        return { fn, status: res.status, ms: Date.now() - started };
      } catch {
        return { fn, status: null, ms: Date.now() - started };
      }
    }),
  );
}
