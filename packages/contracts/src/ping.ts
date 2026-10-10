import { z } from 'zod';
import { environments } from './environment.js';

/** S0 round-trip callable used to prove client ↔ backend wiring per environment. */
export const pingRequestSchema = z.object({
  clientEnvironment: z.enum(environments),
  opId: z.uuid(),
});
export type PingRequest = z.infer<typeof pingRequestSchema>;

export const pingResponseSchema = z.object({
  ok: z.literal(true),
  projectId: z.string(),
  region: z.string(),
  serverTime: z.iso.datetime(),
  opId: z.uuid(),
});
export type PingResponse = z.infer<typeof pingResponseSchema>;
