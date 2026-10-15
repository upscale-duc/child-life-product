import { z } from 'zod';
import { localDateIn } from './baby.js';
import { authorSchema } from './care.js';

/**
 * Reminders (Slice S7; Figma 8a–8e, 12f; business map §6.4, R-090…R-094, D-029…D-032).
 * Written by the app to `babies/{babyId}/reminders/{reminderId}`; Rules in
 * `firebase/firestore.rules` enforce the same shape. Notifications are local, scheduled only on
 * the device named in `notifyDevice` (R-091) — never pushed by the server — and, since D-075 #5,
 * on the assignee's own devices. The Dart app mirrors this in
 * `apps/mobile/lib/features/reminders/reminder_models.dart`.
 * Date-only and assignee: `docs/product/reminders-allday-assignee-plan.md`.
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

// ---- D-075 #5 (all day, assignee) ----

/** "Báo trước" for an all-day reminder: "Đúng ngày" or "1 ngày" (the day before). */
export const reminderAllDayLeadMinutes = [0, 1440] as const;
export const defaultReminderAllDayLeadMinutes = 0;
/** The person's "Giờ nhắc việc cả ngày" until they pick one (baby's zone, never silent). */
export const defaultReminderAllDayTime = '08:00';
/** Who may be assigned a reminder: the roles that see reminders (D-018). */
export const reminderAssigneeRoles = ['coParent', 'caregiver'] as const;
/** The wall time `dueAt` carries for an all-day reminder (old apps read it as "23:59"). */
export const reminderAllDayDueTime = '23:59';

export const reminderSchema = z
  .object({
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
    // ---- D-075 #5: date-only (all day) and an assignee; absent = timed, unassigned (old docs) ----
    /** All day: `dueDate` is the day in the baby's zone; `dueAt` is 23:59 that day. */
    allDay: z.boolean().optional(),
    dueDate: z.iso.date().nullable().optional(),
    /** An active Cùng nuôi or Người chăm sóc of the baby (Rules check the member doc). */
    assigneeUid: z.string().min(1).max(128).nullable().optional(),
  })
  .superRefine((r, ctx) => {
    if (r.allDay === true) {
      if (!r.dueDate) {
        ctx.addIssue({ code: 'custom', path: ['dueDate'], message: 'all day needs a date' });
      }
      if (!(reminderAllDayLeadMinutes as readonly number[]).includes(r.leadMinutes)) {
        ctx.addIssue({ code: 'custom', path: ['leadMinutes'], message: 'all day: 0 or 1440' });
      }
    } else if (r.dueDate) {
      ctx.addIssue({ code: 'custom', path: ['dueDate'], message: 'a date is only for all day' });
    }
  });
export type Reminder = z.infer<typeof reminderSchema>;

/** The instant of local [date] [hhmm] in [zone] (DST-safe, two passes). */
export function reminderInstantIn(zone: string, date: string, hhmm: string): Date {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  const [h, mi] = hhmm.split(':').map(Number) as [number, number];
  const naive = Date.UTC(y, m - 1, d, h, mi);
  const offset = (at: number) => {
    const parts = new Intl.DateTimeFormat('en-US', {
      timeZone: zone,
      hourCycle: 'h23',
      year: 'numeric',
      month: 'numeric',
      day: 'numeric',
      hour: 'numeric',
      minute: 'numeric',
      second: 'numeric',
    }).formatToParts(new Date(at));
    const get = (type: string) => Number(parts.find((p) => p.type === type)?.value ?? 0);
    const asUtc = Date.UTC(
      get('year'),
      get('month') - 1,
      get('day'),
      get('hour'),
      get('minute'),
      get('second'),
    );
    return asUtc - Math.floor(at / 1000) * 1000;
  };
  let t = naive - offset(naive);
  t = naive - offset(t);
  return new Date(t);
}

/** `dueAt` of an all-day reminder: 23:59 on [date] in the baby's [zone]. */
export function reminderAllDayDueAt(zone: string, date: string): Date {
  return reminderInstantIn(zone, date, reminderAllDayDueTime);
}

type StatusFields = Pick<Reminder, 'dueAt' | 'done'> &
  Partial<Pick<Reminder, 'allDay' | 'dueDate'>>;

export type ReminderStatus = 'upcoming' | 'overdue' | 'done';

/**
 * R-093: overdue is derived — past due and not done. An all-day reminder is due for the whole
 * of its date in the baby's [zone] and overdue from the next day (D-075 #5).
 */
export function reminderStatus(r: StatusFields, now: Date, zone?: string): ReminderStatus {
  if (r.done) return 'done';
  if (r.allDay === true && r.dueDate && zone) {
    return localDateIn(zone, now) > r.dueDate ? 'overdue' : 'upcoming';
  }
  return r.dueAt.getTime() < now.getTime() ? 'overdue' : 'upcoming';
}

/**
 * When the local notification fires (D-032): due time minus "Báo trước", once. An all-day
 * reminder fires at the person's chosen time ([allDayTime], default 08:00) in the baby's [zone]
 * on its date, or the day before for "1 ngày".
 */
export function reminderFireAt(
  r: Pick<Reminder, 'dueAt' | 'leadMinutes'> & Partial<Pick<Reminder, 'allDay' | 'dueDate'>>,
  zone?: string,
  allDayTime: string = defaultReminderAllDayTime,
): Date {
  if (r.allDay === true && r.dueDate && zone) {
    let day = r.dueDate;
    if (r.leadMinutes >= 1440) {
      const [y, m, d] = day.split('-').map(Number) as [number, number, number];
      day = new Date(Date.UTC(y, m - 1, d - 1)).toISOString().slice(0, 10);
    }
    return reminderInstantIn(zone, day, allDayTime);
  }
  return new Date(r.dueAt.getTime() - r.leadMinutes * 60_000);
}
