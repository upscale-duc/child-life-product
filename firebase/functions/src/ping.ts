import { functionsRegion, pingRequestSchema, type PingResponse } from '@child-life/contracts';
import { environmentForProject } from './env.js';

export class PingError extends Error {
  constructor(
    readonly code: 'invalid-argument' | 'failed-precondition',
    message: string,
  ) {
    super(message);
  }
}

/** Pure handler so it can be unit-tested without the Functions runtime. */
export function handlePing(data: unknown, projectId: string | undefined, now: Date): PingResponse {
  const parsed = pingRequestSchema.safeParse(data);
  if (!parsed.success) throw new PingError('invalid-argument', 'Malformed ping request');

  const serverEnvironment = environmentForProject(projectId);
  if (parsed.data.clientEnvironment !== serverEnvironment) {
    // A dev build talking to prod (or the reverse) is a configuration error, never tolerated.
    throw new PingError(
      'failed-precondition',
      `Client environment ${parsed.data.clientEnvironment} does not match server ${serverEnvironment}`,
    );
  }

  return {
    ok: true,
    projectId: projectId as string,
    region: functionsRegion,
    serverTime: now.toISOString(),
    opId: parsed.data.opId,
  };
}
