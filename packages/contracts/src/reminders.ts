import { z } from 'zod';
import { authorSchema } from './care.js';

/**
 * Reminders (Slice S7; Figma 8a–8e, 12f; business map §6.4, R-090…R-094, D-029…D-032).
 * Written by the app to `babies/{babyId}/reminders/{reminderId}`; Rules in
 * `firebase/firestore.rules` enforce the same shape. Notifications are local, scheduled only on
 * the device named in `notifyDevice` (R-091) — never pushed by the server. The Dart app mirrors
 * this in `apps/mobile/lib/features/reminders/reminder_models.dart`.
 */

/** "Báo trước" (D-031): Đúng giờ · 10 phút · 30 phút · 1 giờ · 2 giờ · 1 ngày. */
export const reminderLeadMinutes = [0, 10, 30, 60, 120, 1440] as const;
export const defaultReminderLeadMinutes = 60;

export const reminderLimits = {
  titleMax: 80,
  /** How far ahead a reminder can be set (the date wheel's range). */
  maxDaysAhead: 366,
  /** Clock skew allowed when checking "not in the past" (D-031). */
  pastSkewMinutes: 5,
} as const;

/** `rm_` + 32 hex, created on the device (idempotent retries). */
export const reminderIdSchema = z.string().regex(/^rm_[a-f0-9]{32}$/);

/** A per-install id, never a hardware identifier. */
export const deviceIdSchema = z.string().regex(/^d_[a-f0-9]{32}$/);

/** "iPhone của Mai" (8e): the device holding the local notification and whose it is. */
export const notifyDeviceSchema = z.object({
  id: deviceIdSchema,
  uid: z.string().min(1),
  label: z.string().min(1).max(40),
  owner: z.string().min(1).max(60),
});
export type NotifyDevice = z.infer<typeof notifyDeviceSchema>;

export const reminderSchema = z.object({
  id: reminderIdSchema,
  babyId: z.string(),
  title: z.string().trim().min(1).max(reminderLimits.titleMax),
  dueAt: z.date(),
  leadMinutes: z.union(reminderLeadMinutes.map((m) => z.literal(m))),
  notifyDevice: notifyDeviceSchema.nullable(),
  createdBy: z.string(),
  author: authorSchema,
  createdAt: z.date(),
  updatedAt: z.date(),
  updatedBy: z.string(),
  done: z.boolean(),
  doneAt: z.date().nullable(),
  doneBy: z.string().nullable(),
  doneAuthor: authorSchema.nullable(),
});
export type Reminder = z.infer<typeof reminderSchema>;

export type ReminderStatus = 'upcoming' | 'overdue' | 'done';

/** R-093: overdue is derived — past due and not done. */
export function reminderStatus(r: Pick<Reminder, 'dueAt' | 'done'>, now: Date): ReminderStatus {
  if (r.done) return 'done';
  return r.dueAt.getTime() < now.getTime() ? 'overdue' : 'upcoming';
}

/** When the local notification fires (D-032): due time minus "Báo trước", once. */
export function reminderFireAt(r: Pick<Reminder, 'dueAt' | 'leadMinutes'>): Date {
  return new Date(r.dueAt.getTime() - r.leadMinutes * 60_000);
}
