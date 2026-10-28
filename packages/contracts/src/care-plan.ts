import { z } from 'zod';
import type { MemberRole } from './baby.js';

/**
 * Cùng Chăm Con (D-135, `docs/design/explorations/cung-cham-con/ANALYSIS-2026-10-28.md`): one
 * shared plan of care tasks per baby per day, written by the server only.
 *
 * - `babies/{b}/carePlanDays/{yyyy-mm-dd}`: the day (the baby's time zone), its `revision`.
 * - `…/carePlanDays/{date}/items/{pi_…}`: a task: time, what, who (any number), status.
 * - `babies/{b}/carePlanTemplate/{pt_…}`: the tasks kept "Mọi ngày"; a new day starts from them.
 * - `babies/{b}/carePlanHistory/{auto}`: who changed what, when (20 Lịch sử thay đổi).
 *
 * Sáng / Chiều / Tối are groups of the day's tasks by time, never a parent's shift. Marking a task
 * done is not a care record: logging stays in Care (a later step links the two).
 */

/** What a task is; the app draws its art and name. `custom` carries its own title. */
export const carePlanTasks = [
  'bottle',
  'breast',
  'pump',
  'solids',
  'water',
  'sleep',
  'diaper',
  'bath',
  'tummy',
  'read',
  'walk',
  'vitamin',
  'medicine',
  'temperature',
  'teeth',
  'potty',
  'custom',
] as const;
export type CarePlanTask = (typeof carePlanTasks)[number];

export const carePlanItemStatuses = ['open', 'done', 'skipped'] as const;
export type CarePlanItemStatus = (typeof carePlanItemStatuses)[number];

/** At most this many tasks in a day, and assignees on one task. */
export const carePlanLimits = { itemsPerDay: 40, assigneesPerItem: 6, titleLength: 60 } as const;

const babyId = z.string().min(1).max(128);
const uid = z.string().min(1).max(128);
export const carePlanDateSchema = z.string().regex(/^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/);
export const carePlanTimeSchema = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/);
export const carePlanItemIdSchema = z.string().regex(/^pi_[a-f0-9]{32}$/);
const assignees = z
  .array(uid)
  .max(carePlanLimits.assigneesPerItem)
  .refine((a) => new Set(a).size === a.length);

/** 04-0 "Hôm nay chưa có lịch": start the day from the everyday tasks, yesterday, or empty. */
export const startCarePlanDaySchema = z
  .object({
    babyId,
    date: carePlanDateSchema,
    from: z.enum(['everyday', 'yesterday', 'empty']),
  })
  .strict();
export type StartCarePlanDayRequest = z.infer<typeof startCarePlanDaySchema>;

/** 06 Thêm việc / 06b Sửa: create or edit one task, for today only or every day. */
export const saveCarePlanItemSchema = z
  .object({
    babyId,
    date: carePlanDateSchema,
    itemId: carePlanItemIdSchema,
    task: z.enum(carePlanTasks),
    title: z.string().trim().min(1).max(carePlanLimits.titleLength).nullable(),
    time: carePlanTimeSchema,
    assignees,
    scope: z.enum(['today', 'everyDay']),
  })
  .strict()
  .refine((r) => (r.task === 'custom' ? r.title !== null : true));
export type SaveCarePlanItemRequest = z.infer<typeof saveCarePlanItemSchema>;

/** 06b: delete a task (today only, or also from every day). */
export const deleteCarePlanItemSchema = z
  .object({
    babyId,
    date: carePlanDateSchema,
    itemId: carePlanItemIdSchema,
    scope: z.enum(['today', 'everyDay']),
  })
  .strict();
export type DeleteCarePlanItemRequest = z.infer<typeof deleteCarePlanItemSchema>;

/** 05 Giao việc: the chosen people for one task or a whole group ("Giao cả ca"). Empty = nobody. */
export const assignCarePlanItemsSchema = z
  .object({
    babyId,
    date: carePlanDateSchema,
    itemIds: z.array(carePlanItemIdSchema).min(1).max(carePlanLimits.itemsPerDay),
    assignees,
  })
  .strict();
export type AssignCarePlanItemsRequest = z.infer<typeof assignCarePlanItemsSchema>;

/** The ring on a task (done / undo), and 06b "Bỏ qua" (skipped, can be undone). */
export const setCarePlanItemStatusSchema = z
  .object({
    babyId,
    date: carePlanDateSchema,
    itemId: carePlanItemIdSchema,
    status: z.enum(carePlanItemStatuses),
  })
  .strict();
export type SetCarePlanItemStatusRequest = z.infer<typeof setCarePlanItemStatusSchema>;

/**
 * Who may do what with the plan (13 Quyền với lịch). Defaults by role: Cùng nuôi manage (add,
 * edit, delete, assign, skip); Người chăm sóc only mark done; relatives neither. "Bà" is a
 * relation and grants nothing by itself.
 */
export type CarePlanRight = 'manage' | 'complete';

export function carePlanCan(role: MemberRole, right: CarePlanRight): boolean {
  if (right === 'manage') return role === 'coParent';
  return role === 'coParent' || role === 'caregiver';
}

/** Who can be given a task: those who take care of the baby. */
export const carePlanAssignable = (role: MemberRole) => role === 'coParent' || role === 'caregiver';

// ---------- Task reminders (N1, D-135 Q5) ----------

/**
 * "Nhắc trước" choices in minutes; 0 = Tắt. Per person, in `users/{uid}/settings/carePlan`
 * (written by its owner, Rules mirror [carePlanPrefsDocSchema]).
 */
export const carePlanReminderLeads = [0, 5, 10, 15] as const;
export type CarePlanReminderLead = (typeof carePlanReminderLeads)[number];

/** Tasks of one person less than this many minutes apart ring as one push. */
export const carePlanGroupMinutes = 15;

export const carePlanPrefsDocSchema = z
  .object({
    leadMinutes: z.union(carePlanReminderLeads.map((m) => z.literal(m))).optional(),
    /** "Nhắc cả trong giờ yên lặng" (D-135 Q5): on by default. */
    quietHours: z.boolean().optional(),
    updatedAt: z.unknown().optional(),
  })
  .strict();

export interface CarePlanPrefs {
  leadMinutes: CarePlanReminderLead;
  quietHours: boolean;
}

export const defaultCarePlanPrefs: CarePlanPrefs = { leadMinutes: 5, quietHours: true };

/** The stored prefs with defaults; anything malformed takes its default. */
export function carePlanPrefsOf(doc: Record<string, unknown> | null | undefined): CarePlanPrefs {
  const lead = doc?.leadMinutes;
  return {
    leadMinutes: (carePlanReminderLeads as readonly unknown[]).includes(lead)
      ? (lead as CarePlanReminderLead)
      : defaultCarePlanPrefs.leadMinutes,
    quietHours:
      typeof doc?.quietHours === 'boolean' ? doc.quietHours : defaultCarePlanPrefs.quietHours,
  };
}

/**
 * A task's name in a push (mirrors the app's `cpTask*` strings). A custom task's own title is
 * free text the family typed and may name a medicine, so it never reaches a lock screen.
 */
export const carePlanTaskNames: Record<CarePlanTask, { vi: string; en: string }> = {
  bottle: { vi: 'Bú bình', en: 'Bottle' },
  breast: { vi: 'Bú mẹ', en: 'Breastfeed' },
  pump: { vi: 'Hút sữa', en: 'Pump' },
  solids: { vi: 'Ăn dặm', en: 'Solids' },
  water: { vi: 'Uống nước', en: 'Water' },
  sleep: { vi: 'Ngủ', en: 'Sleep' },
  diaper: { vi: 'Thay tã', en: 'Diaper' },
  bath: { vi: 'Tắm', en: 'Bath' },
  tummy: { vi: 'Nằm sấp', en: 'Tummy time' },
  read: { vi: 'Đọc sách', en: 'Reading' },
  walk: { vi: 'Đi dạo', en: 'Walk' },
  vitamin: { vi: 'Vitamin', en: 'Vitamin' },
  medicine: { vi: 'Uống thuốc', en: 'Medicine' },
  temperature: { vi: 'Đo nhiệt độ', en: 'Check temp' },
  teeth: { vi: 'Đánh răng', en: 'Brush teeth' },
  potty: { vi: 'Ngồi bô', en: 'Potty' },
  custom: { vi: 'Việc riêng', en: 'Your own task' },
};
