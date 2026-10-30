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

/**
 * How a day's plan is made (04-0, 01 Chọn cách lên lịch; D-136). The family's own tasks
 * (`everyday`, `yesterday`, `empty`) start the day at once; the others make a **draft** the
 * family looks over and edits before "Dùng lịch này": `rhythm` from the last 7 days of the care
 * log, and the reference templates `basic` (by age), `easy35`, `easy4` (dev only until the owner
 * reviews their content, D-136 #1).
 */
export const carePlanMethods = [
  'everyday',
  'yesterday',
  'empty',
  'rhythm',
  'basic',
  'easy35',
  'easy4',
] as const;
export type CarePlanMethod = (typeof carePlanMethods)[number];

export const carePlanDraftMethods = ['rhythm', 'basic', 'easy35', 'easy4'] as const;
export type CarePlanDraftMethod = (typeof carePlanDraftMethods)[number];
export type CarePlanTemplateMethod = Exclude<CarePlanDraftMethod, 'rhythm'>;

export const isDraftMethod = (m: CarePlanMethod): m is CarePlanDraftMethod =>
  (carePlanDraftMethods as readonly string[]).includes(m);

/** D-136 #2: "Theo nhịp của bé" needs this many of the last days, each with a feed and a sleep. */
export const carePlanRhythmDays = 7;

/** A day is `draft` until someone taps "Dùng lịch này"; a day without `status` is published. */
export const carePlanDayStatuses = ['draft', 'published'] as const;
export type CarePlanDayStatus = (typeof carePlanDayStatuses)[number];

/**
 * 04-0 "Hôm nay chưa có lịch" / 01: start the day. A day that exists is kept, except a draft
 * started again with another method ("Đổi cách khác"), which is replaced.
 */
export const startCarePlanDaySchema = z
  .object({
    babyId,
    date: carePlanDateSchema,
    from: z.enum(carePlanMethods),
  })
  .strict();
export type StartCarePlanDayRequest = z.infer<typeof startCarePlanDaySchema>;

/** 02 "Dùng lịch này": a draft day becomes the family's plan (and is reminded, N1). */
export const publishCarePlanDaySchema = z.object({ babyId, date: carePlanDateSchema }).strict();
export type PublishCarePlanDayRequest = z.infer<typeof publishCarePlanDaySchema>;

/**
 * 13 "Tự tạo lịch mỗi sáng" (D-136 #3): per family, off by default, changed by plan managers.
 * Stored with the method last used to start a day in `babies/{b}/carePlanSettings/family`
 * (server-written); the morning draft uses that method.
 */
export const setCarePlanAutoDraftSchema = z.object({ babyId, on: z.boolean() }).strict();
export type SetCarePlanAutoDraftRequest = z.infer<typeof setCarePlanAutoDraftSchema>;

/** Baby-local time from which the morning draft is made, and the last one it is still made at. */
export const carePlanMorningWindow = { from: '06:30', until: '11:00' } as const;

/** 06 Thêm việc / 06b Sửa: create or edit one task, for today only or every day. */
/** D-138: tasks that carry a planned amount (ml), and its upper bound (as a bottle log). */
export const carePlanAmountTasks: readonly string[] = ['bottle', 'pump'];
export const carePlanMaxMl = 500;

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
    /** D-138: the ml planned for a bottle or pumping ("Bú bình · 120 ml"); null for others. */
    amountMl: z.number().int().min(1).max(carePlanMaxMl).nullable().optional(),
  })
  .strict()
  .refine((r) => (r.task === 'custom' ? r.title !== null : true))
  .refine((r) => r.amountMl == null || carePlanAmountTasks.includes(r.task));
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
    /** "Khi người khác làm xong" (N2) and their hearts / thanks (N3): on by default. */
    team: z.boolean().optional(),
    updatedAt: z.unknown().optional(),
  })
  .strict();

export interface CarePlanPrefs {
  leadMinutes: CarePlanReminderLead;
  quietHours: boolean;
  team: boolean;
}

export const defaultCarePlanPrefs: CarePlanPrefs = { leadMinutes: 5, quietHours: true, team: true };

/** The stored prefs with defaults; anything malformed takes its default. */
export function carePlanPrefsOf(doc: Record<string, unknown> | null | undefined): CarePlanPrefs {
  const lead = doc?.leadMinutes;
  return {
    leadMinutes: (carePlanReminderLeads as readonly unknown[]).includes(lead)
      ? (lead as CarePlanReminderLead)
      : defaultCarePlanPrefs.leadMinutes,
    quietHours:
      typeof doc?.quietHours === 'boolean' ? doc.quietHours : defaultCarePlanPrefs.quietHours,
    team: typeof doc?.team === 'boolean' ? doc.team : defaultCarePlanPrefs.team,
  };
}

// ---------- 10 Vừa xong: hearts and thanks (N2, N3) ----------

/**
 * The thanks 10 offers (Figma 1353:22683): "Cảm ơn", "Tuyệt" and the quick lines "Cảm ơn Ba!",
 * "Ba giỏi quá", "Thương Ba". Kept as keys, never typed text, so a push quotes only our copy.
 */
export const carePlanThanks = ['thanks', 'great', 'thanksName', 'proud', 'love'] as const;
export type CarePlanThanks = (typeof carePlanThanks)[number];

/** 10: a heart and / or a thanks for a task someone else did. Hearts stay once sent. */
export const reactCarePlanItemSchema = z
  .object({
    babyId,
    date: carePlanDateSchema,
    itemId: carePlanItemIdSchema,
    heart: z.boolean(),
    // Lock-screen "Thả tim" may leave it out (Android drops null keys).
    thanks: z.enum(carePlanThanks).nullable().default(null),
  })
  .strict()
  .refine((r) => r.heart || r.thanks !== null);
export type ReactCarePlanItemRequest = z.infer<typeof reactCarePlanItemSchema>;

/**
 * What someone did for the baby, for N2 / N3 and 10 ("Ba vừa tắm cho Teddy", "Cảm ơn Ba đã tắm
 * cho Teddy nha!"); `{baby}` is the baby's name or "bé". A custom task stays generic (its typed
 * title never reaches a lock screen). Mirrors the app's `cpDidTask`.
 */
export const carePlanDidPhrases: Record<CarePlanTask, { vi: string; en: string }> = {
  bottle: { vi: 'cho {baby} bú bình', en: 'gave {baby} a bottle' },
  breast: { vi: 'cho {baby} bú mẹ', en: 'breastfed {baby}' },
  pump: { vi: 'hút sữa cho {baby}', en: 'pumped milk for {baby}' },
  solids: { vi: 'cho {baby} ăn dặm', en: 'fed {baby} solids' },
  water: { vi: 'cho {baby} uống nước', en: 'gave {baby} some water' },
  sleep: { vi: 'ru {baby} ngủ', en: 'put {baby} to sleep' },
  diaper: { vi: 'thay tã cho {baby}', en: 'changed {baby}’s diaper' },
  bath: { vi: 'tắm cho {baby}', en: 'gave {baby} a bath' },
  tummy: { vi: 'cho {baby} nằm sấp', en: 'did tummy time with {baby}' },
  read: { vi: 'đọc sách cho {baby}', en: 'read to {baby}' },
  walk: { vi: 'đưa {baby} đi dạo', en: 'took {baby} for a walk' },
  vitamin: { vi: 'cho {baby} uống vitamin', en: 'gave {baby} vitamins' },
  medicine: { vi: 'cho {baby} uống thuốc', en: 'gave {baby} medicine' },
  temperature: { vi: 'đo nhiệt độ cho {baby}', en: 'checked {baby}’s temperature' },
  teeth: { vi: 'đánh răng cho {baby}', en: 'brushed {baby}’s teeth' },
  potty: { vi: 'cho {baby} ngồi bô', en: 'helped {baby} on the potty' },
  custom: { vi: 'xong một việc cho {baby}', en: 'did a task for {baby}' },
};

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
