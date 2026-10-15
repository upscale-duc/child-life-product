import { z } from 'zod';
import { authorSchema } from './care.js';

/**
 * Chi tiêu (spending), Figma v1.1 8a–8o; decisions D-055 … D-057, defaults P-140, plan
 * `docs/product/spending-plan.md`. Expenses are written by the app (offline outbox, as care records);
 * category moves and recurring occurrences go through Functions.
 */

export const spendingLimits = {
  /** Whole VND. */
  amountMax: 1_000_000_000,
  noteMax: 80,
  categoryNameMax: 24,
  /** Custom categories per family (built-ins excluded). */
  customCategoriesMax: 30,
  recurringMax: 30,
  recurringTitleMax: 60,
  /** "Gần chạm mức" from this share of a category cap (P-140). */
  nearCapShare: 0.9,
  /** The budget push (8h "Nhắc khi dùng 80% ngân sách"). */
  alertShare: 0.8,
} as const;

/** `x_<32 hex>`: a client id, so an offline retry never doubles an expense. */
export const expenseIdSchema = z.string().regex(/^x_[a-f0-9]{32}$/);
export const recurringIdSchema = z.string().regex(/^rx_[a-f0-9]{32}$/);
/** Built-ins have fixed ids (`c_milk`); custom ones `c_<20 hex>`. */
export const categoryIdSchema = z.string().regex(/^c_[a-z0-9]{3,20}$/);

/** The six categories every family starts with (8c / 8m). "Khác" cannot be deleted. */
export const builtInCategories = [
  { id: 'c_childcare', icon: 'family', tint: 'growth' },
  { id: 'c_milk', icon: 'feed', tint: 'bottle' },
  { id: 'c_diaper', icon: 'diaper', tint: 'diaper' },
  { id: 'c_health', icon: 'heart', tint: 'pump' },
  { id: 'c_clothes', icon: 'star', tint: 'breast' },
  { id: 'c_other', icon: 'grid', tint: 'sleep' },
] as const;
export const otherCategoryId = 'c_other';
/** Y tế & tiêm chủng: where a vaccine cost goes (8k). */
export const healthCategoryId = 'c_health';

/** 8n: the 16 icons and 8 tints a category can take. */
export const categoryIcons = [
  'family',
  'feed',
  'diaper',
  'heart',
  'star',
  'journal',
  'grid',
  'spark',
  'sleep',
  'ruler',
  'camera',
  'cake',
  'bell',
  'globe',
  'today',
  'drop',
] as const;
export const categoryTints = [
  'growth',
  'bottle',
  'diaper',
  'pump',
  'breast',
  'sleep',
  'sunshine',
  'mint',
] as const;

const isoDate = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);

/** "Ai trả" (D-056): a member's label snapshot, or null for "Khác". */
export const payerSchema = authorSchema.extend({ uid: z.string().min(1).max(128) }).nullable();

/** `import`: brought in by "Nhập chi tiêu" (D-060); sourceRef = the import id. */
/** `assistant`: saved from a confirmed assistant draft (server-written, like `import`). */
export const expenseSources = ['manual', 'recurring', 'vaccine', 'import', 'assistant'] as const;

/** `babies/{babyId}/expenses/{expenseId}`. Soft delete only. */
export const expenseSchema = z.object({
  amount: z.number().int().min(1).max(spendingLimits.amountMax),
  categoryId: categoryIdSchema,
  note: z.string().max(spendingLimits.noteMax),
  /** The day it was spent, in the baby's time zone. */
  spentOn: isoDate,
  payer: payerSchema,
  receiptPath: z.string().nullable(),
  source: z.enum(expenseSources),
  /** A recurring item id, or a vaccine dose key (`hexa6_2`). */
  sourceRef: z.string().max(40).nullable(),
  createdBy: z.string(),
  author: authorSchema,
  createdAt: z.date(),
  updatedAt: z.date(),
  updatedBy: z.string(),
  deleted: z.boolean(),
});
export type Expense = z.infer<typeof expenseSchema>;

/** `families/{familyId}/spendingCategories/{categoryId}` (shared by the family's babies). */
export const spendingCategorySchema = z.object({
  /** Null for a built-in that keeps its translated name. */
  name: z.string().min(1).max(spendingLimits.categoryNameMax).nullable(),
  icon: z.enum(categoryIcons),
  tint: z.enum(categoryTints),
  order: z.number().int().min(0).max(1000),
  hidden: z.boolean(),
  builtIn: z.boolean(),
  updatedAt: z.date(),
  updatedBy: z.string(),
});
export type SpendingCategory = z.infer<typeof spendingCategorySchema>;

/** `babies/{babyId}/spending/budget` (8h): a standing monthly total and optional caps. */
export const budgetSchema = z.object({
  monthlyTotal: z.number().int().min(0).max(spendingLimits.amountMax).nullable(),
  caps: z.record(categoryIdSchema, z.number().int().min(1).max(spendingLimits.amountMax)),
  alert80: z.boolean(),
  updatedAt: z.date(),
  updatedBy: z.string(),
});
export type Budget = z.infer<typeof budgetSchema>;

/** 8i: twice a month on fixed days, every N weeks from a date, or once a year. */
export const recurringScheduleSchema = z.discriminatedUnion('kind', [
  z.object({
    kind: z.literal('monthly'),
    days: z.array(z.number().int().min(1).max(31)).min(1).max(2),
  }),
  z.object({
    kind: z.literal('weeks'),
    every: z.number().int().min(1).max(8),
    startOn: isoDate,
  }),
  z.object({
    kind: z.literal('yearly'),
    month: z.number().int().min(1).max(12),
    day: z.number().int().min(1).max(31),
  }),
]);
export type RecurringSchedule = z.infer<typeof recurringScheduleSchema>;

/** `babies/{babyId}/recurringExpenses/{recurringId}`. */
export const recurringExpenseSchema = z.object({
  title: z.string().min(1).max(spendingLimits.recurringTitleMax),
  categoryId: categoryIdSchema,
  amount: z.number().int().min(1).max(spendingLimits.amountMax),
  payer: payerSchema,
  schedule: recurringScheduleSchema,
  enabled: z.boolean(),
  createdBy: z.string(),
  author: authorSchema,
  createdAt: z.date(),
  updatedAt: z.date(),
  updatedBy: z.string(),
});
export type RecurringExpense = z.infer<typeof recurringExpenseSchema>;

/** 8o: delete a custom category and move what used it. */
export const deleteSpendingCategoryRequestSchema = z.object({
  babyId: z.string().min(1).max(128),
  categoryId: categoryIdSchema,
  moveTo: categoryIdSchema,
});
export type DeleteSpendingCategoryRequest = z.infer<typeof deleteSpendingCategoryRequestSchema>;

/** The next due dates of a schedule after [after] (exclusive), up to [until] (inclusive). */
export function dueDatesBetween(
  schedule: RecurringSchedule,
  after: string,
  until: string,
): string[] {
  const out: string[] = [];
  const start = parseDay(after);
  const end = parseDay(until);
  for (let d = addDays(start, 1); d <= end; d = addDays(d, 1)) {
    if (isDue(schedule, d)) out.push(formatDay(d));
  }
  return out;
}

function isDue(s: RecurringSchedule, day: Date): boolean {
  const y = day.getUTCFullYear();
  const m = day.getUTCMonth() + 1;
  const d = day.getUTCDate();
  const last = new Date(Date.UTC(y, m, 0)).getUTCDate();
  // A day past the month's end (31 in a 30-day month) falls on its last day.
  const clamp = (n: number) => Math.min(n, last);
  switch (s.kind) {
    case 'monthly':
      return s.days.some((n) => clamp(n) === d);
    case 'yearly':
      return s.month === m && Math.min(s.day, last) === d;
    case 'weeks': {
      const from = parseDay(s.startOn);
      const diff = Math.round((day.getTime() - from.getTime()) / 86_400_000);
      return diff >= 0 && diff % (7 * s.every) === 0;
    }
  }
}

const parseDay = (iso: string) => new Date(`${iso}T00:00:00Z`);
const addDays = (d: Date, n: number) => new Date(d.getTime() + n * 86_400_000);
const formatDay = (d: Date) => d.toISOString().slice(0, 10);
