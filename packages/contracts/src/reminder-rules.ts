import { z } from 'zod';
import { localDateIn } from './baby.js';
import { dayBoundsIn, type CareType } from './care.js';

/**
 * Rule reminders (v1.0 improvement "Nhắc bú/ngủ có quy tắc", 370:1247; D-051). Stored at
 * `babies/{babyId}/reminderRules/{ruleId}` and written only by callable Functions; the server
 * keeps the schedule (`nextDueAt`), pushes to the chosen recipients and resolves a due reminder
 * for everyone when anyone logs the activity (1d). Occurrences (1h "Gần đây") live in
 * `reminderRules/{ruleId}/occurrences`. The Dart app mirrors this in
 * `apps/mobile/lib/features/reminders/rule_models.dart`.
 */

/** 1b "Bạn muốn nhắc việc gì?": Bú covers bottle and breast (1c). */
export const reminderRuleTypes = ['feed', 'sleep', 'diaper', 'pump'] as const;
export type ReminderRuleType = (typeof reminderRuleTypes)[number];

/** 1b "Cách nhắc": after the latest log, or fixed times each day. */
export const reminderRuleModes = ['afterLast', 'fixed'] as const;
export type ReminderRuleMode = (typeof reminderRuleModes)[number];

export const reminderRuleLimits = {
  /** 1c stepper, in minutes (presets 2 h · 2 h 30 · 3 h · 3 h 30). */
  intervalMin: 30,
  intervalMax: 12 * 60,
  intervalStep: 15,
  timesMax: 8,
  recipientsMax: 20,
  /** 1g "Báo lại sau" 10 · 15 · 30 phút; the lock screen offers 15 (1f). */
  snoozeMinutes: [10, 15, 30] as const,
  /** 1c "Không nhắc ban đêm 22:00 – 06:00". */
  quietStartMinute: 22 * 60,
  quietEndMinute: 6 * 60,
} as const;

/** The care types each rule type follows. */
export const ruleRecordTypes: Record<ReminderRuleType, readonly CareType[]> = {
  feed: ['bottle', 'breast'],
  sleep: ['sleep'],
  diaper: ['diaper'],
  pump: ['pump'],
};

export function ruleTypeOfRecord(type: string): ReminderRuleType | null {
  for (const t of reminderRuleTypes) {
    if ((ruleRecordTypes[t] as readonly string[]).includes(type)) return t;
  }
  return null;
}

/** `rr_` + 32 hex, made on the device so a retried save is idempotent. */
export const reminderRuleIdSchema = z.string().regex(/^rr_[a-f0-9]{32}$/);
export const clockTimeSchema = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/);

const babyIdSchema = z.string().min(1).max(64);

export const saveReminderRuleSchema = z
  .object({
    babyId: babyIdSchema,
    ruleId: reminderRuleIdSchema,
    type: z.enum(reminderRuleTypes),
    mode: z.enum(reminderRuleModes),
    intervalMinutes: z
      .number()
      .int()
      .min(reminderRuleLimits.intervalMin)
      .max(reminderRuleLimits.intervalMax)
      .multipleOf(reminderRuleLimits.intervalStep)
      .nullable(),
    times: z.array(clockTimeSchema).max(reminderRuleLimits.timesMax),
    /** ISO weekdays, Monday = 1 … Sunday = 7 (1c2 "T2 … CN"). */
    days: z.array(z.number().int().min(1).max(7)).min(1).max(7),
    quietNight: z.boolean(),
    recipients: z.array(z.string().min(1).max(128)).min(1).max(reminderRuleLimits.recipientsMax),
  })
  .strict()
  .superRefine((r, ctx) => {
    const issue = (message: string) => ctx.addIssue({ code: 'custom', message });
    if (r.mode === 'afterLast' && (r.intervalMinutes == null || r.times.length > 0)) {
      issue('afterLast needs an interval and no times');
    }
    if (r.mode === 'fixed' && (r.intervalMinutes != null || r.times.length === 0)) {
      issue('fixed needs times and no interval');
    }
    if (new Set(r.times).size !== r.times.length) issue('duplicate times');
    if (new Set(r.days).size !== r.days.length) issue('duplicate days');
    if (new Set(r.recipients).size !== r.recipients.length) issue('duplicate recipients');
  });
export type SaveReminderRule = z.infer<typeof saveReminderRuleSchema>;

export const setReminderRuleEnabledSchema = z
  .object({ babyId: babyIdSchema, ruleId: reminderRuleIdSchema, enabled: z.boolean() })
  .strict();

export const deleteReminderRuleSchema = z
  .object({ babyId: babyIdSchema, ruleId: reminderRuleIdSchema })
  .strict();

/** 1f / 1g: "Báo lại sau …" or "Bỏ qua lần này" for the occurrence due at [dueAt] (ms). */
export const answerReminderRuleSchema = z
  .object({
    babyId: babyIdSchema,
    ruleId: reminderRuleIdSchema,
    action: z.enum(['snooze', 'skip']),
    minutes: z.union(reminderRuleLimits.snoozeMinutes.map((m) => z.literal(m))).optional(),
    dueAt: z.number().int().positive(),
  })
  .strict()
  .refine((a) => (a.action === 'snooze') === (a.minutes != null), 'snooze needs minutes');

/** 1h "Gần đây": what happened to one due reminder. */
export const reminderOutcomes = ['logged', 'snoozed', 'skipped', 'missed'] as const;
export type ReminderOutcome = (typeof reminderOutcomes)[number];

/** The scheduling state the server keeps on a rule. */
export interface RuleSchedule {
  mode: ReminderRuleMode;
  enabled: boolean;
  intervalMinutes: number | null;
  times: string[];
  days: number[];
  quietNight: boolean;
  /** Latest log of the type (sleep: when the baby woke); null = none yet, or asleep now. */
  anchorAt: Date | null;
  /** "Bỏ qua lần này" on an after-last rule: the next one counts from the skipped time. */
  skipBase: Date | null;
  snoozedUntil: Date | null;
  /** Fired and nobody has answered or logged yet. */
  pendingDueAt: Date | null;
}

const minuteOf = (hhmm: string) => {
  const [h, m] = hhmm.split(':').map(Number) as [number, number];
  return h * 60 + m;
};

/** ISO weekday (Mon = 1) of a local YYYY-MM-DD. */
function isoWeekday(date: string): number {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  const day = new Date(Date.UTC(y, m - 1, d)).getUTCDay();
  return day === 0 ? 7 : day;
}

function addDays(date: string, n: number): string {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(y, m - 1, d + n)).toISOString().slice(0, 10);
}

/** The instant of [hhmm] on local [date] in [zone]. */
export function atLocal(zone: string, date: string, minute: number): Date {
  return new Date(dayBoundsIn(zone, date).start.getTime() + minute * 60_000);
}

function localMinute(zone: string, at: Date): number {
  return Math.round(
    (at.getTime() - dayBoundsIn(zone, localDateIn(zone, at)).start.getTime()) / 60_000,
  );
}

/**
 * Moves [at] out of the quiet night (to 06:00) and off days the rule does not apply (to the
 * next allowed day). P-130: a reminder that would ring at night waits for the morning rather
 * than being dropped.
 */
function allowedFrom(zone: string, at: Date, days: number[], quietNight: boolean): Date {
  const { quietStartMinute: qs, quietEndMinute: qe } = reminderRuleLimits;
  let date = localDateIn(zone, at);
  let minute = localMinute(zone, at);
  let moved = false;
  for (let i = 0; i < 8; i += 1) {
    if (days.includes(isoWeekday(date))) {
      if (quietNight && minute < qe) {
        minute = qe;
        moved = true;
      }
      if (!quietNight || minute < qs) return moved ? atLocal(zone, date, minute) : at;
    }
    // After 22:00, or a day the rule skips: the next day from its start.
    date = addDays(date, 1);
    minute = 0;
    moved = true;
  }
  return at;
}

/** The next fixed time strictly after [after], or null when no day is chosen. */
function nextFixed(zone: string, rule: RuleSchedule, after: Date): Date | null {
  const minutes = rule.times.map(minuteOf).sort((a, b) => a - b);
  let date = localDateIn(zone, after);
  for (let i = 0; i < 9; i += 1) {
    if (rule.days.includes(isoWeekday(date))) {
      for (const m of minutes) {
        const at = atLocal(zone, date, m);
        if (at > after) return at;
      }
    }
    date = addDays(date, 1);
  }
  return null;
}

/**
 * When this rule should ring next, seen at [now]. [lastDue] is the occurrence that just rang
 * (fixed rules move past it). Null = nothing scheduled: paused, waiting for a first log, the
 * baby is asleep (sleep rules), or a due reminder is waiting for an answer.
 */
export function nextDueOf(
  zone: string,
  rule: RuleSchedule,
  now: Date,
  lastDue: Date | null = null,
): Date | null {
  if (!rule.enabled) return null;
  if (rule.snoozedUntil && rule.snoozedUntil > now) return rule.snoozedUntil;
  if (rule.mode === 'fixed') {
    return nextFixed(zone, rule, lastDue && lastDue > now ? lastDue : now);
  }
  if (rule.pendingDueAt || rule.anchorAt == null) return null;
  const base = Math.max(rule.anchorAt.getTime(), rule.skipBase?.getTime() ?? 0);
  const due = new Date(base + (rule.intervalMinutes ?? 0) * 60_000);
  const allowed = allowedFrom(zone, due, rule.days, rule.quietNight);
  // Overdue already (a rule made long after the last log): ring now rather than never.
  return allowed < now ? now : allowed;
}
