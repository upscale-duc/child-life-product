import { z } from 'zod';

/**
 * The note a staff action used to require (D-090, owner 2026-10-21: one operator, no reasons on
 * the portal). Optional everywhere: missing, null or empty reads as "" and is never refused; the
 * audit line (actor, action, before / after) is written either way. A leaf module so every
 * contract file can use it without an import cycle.
 */
export const staffReasonSchema = z
  .string()
  .trim()
  .max(500)
  .nullish()
  .transform((v) => v ?? '');
