import { z } from 'zod';

/**
 * P-181 / owner 2026-10-27: one carer, or Ba and Mẹ together, shown to the
 * whole family (`babies/{b}/careDuty/current`, written by the server only). A carer takes it
 * ("Tôi trông bé"), ends their own, or gets it by receiving a handover. Reminders do not follow
 * it yet (a later step).
 */
export const careDutyRequestSchema = z
  .object({
    babyId: z.string().min(1).max(128),
    action: z.enum(['take', 'end', 'together']),
    coCarerUid: z.string().min(1).max(128).optional(),
  })
  .strict()
  .refine((r) => (r.action === 'together' ? !!r.coCarerUid : r.coCarerUid === undefined));
export type CareDutyRequest = z.infer<typeof careDutyRequestSchema>;

/** Who may be on duty: those who log care (Cùng nuôi, Người chăm sóc). */
export const careDutyFamilyAction = 'rhythm.feedback' as const;
