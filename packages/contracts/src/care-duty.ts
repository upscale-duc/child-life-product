import { z } from 'zod';

/**
 * P-181 "Ai đang trông bé" (owner, 2026-10-25): one person per baby is on duty, shown to the
 * whole family (`babies/{b}/careDuty/current`, written by the server only). A carer takes it
 * ("Tôi trông bé"), ends their own, or gets it by receiving a handover. Reminders do not follow
 * it yet (a later step).
 */
export const careDutyRequestSchema = z
  .object({
    babyId: z.string().min(1).max(128),
    action: z.enum(['take', 'end']),
  })
  .strict();
export type CareDutyRequest = z.infer<typeof careDutyRequestSchema>;

/** Who may be on duty: those who log care (Cùng nuôi, Người chăm sóc). */
export const careDutyFamilyAction = 'rhythm.feedback' as const;
