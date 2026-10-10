import { flagsSchema, limitsSchema } from '@child-life/contracts';

const schemas = { flags: flagsSchema, limits: limitsSchema } as const;
export type MirroredConfigId = keyof typeof schemas;

export function isMirroredConfigId(id: string): id is MirroredConfigId {
  return id in schemas;
}

/**
 * Validates a server-side config document before it is exposed to clients.
 * Returns null when the document is invalid so a bad write never reaches devices.
 */
export function publicProjection(
  id: MirroredConfigId,
  data: unknown,
): Record<string, unknown> | null {
  const parsed = schemas[id].safeParse(data);
  return parsed.success ? (parsed.data as Record<string, unknown>) : null;
}
