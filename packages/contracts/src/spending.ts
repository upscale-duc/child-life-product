import { z } from 'zod';
import { authorSchema } from './care.js';

/**
 * Chi tiêu (spending), Figma v1.1 8a–8o; decisions D-055 … D-057, defaults P-140, plan
 * `docs/product/spending-plan.md`. Expenses are written by the app (offline outbox, as care records);
 * category moves and recurring occurrences go through Functions.
 */

export const spendingLimits = {
  /** Whole VND (the VND ceiling; other currencies: `currencyInfo`). */
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

// ---- Currencies (D-075 #4, plan `docs/product/spending-currency-plan.md`) ----

/**
 * The currencies an expense can be kept in. `amount` is an integer in the currency's MINOR units
 * (ISO 4217 exponent: VND 0 → đồng, USD 2 → cents, JPY 0 → yen). A document without `currency`
 * is VND (everything written before D-075 #4, and old apps that keep writing it). Each currency
 * has its own ceiling in minor units (Rules `currencyMax`; keep the two in step).
 */
export const currencyInfo = {
  VND: { exponent: 0, max: 1_000_000_000 },
  USD: { exponent: 2, max: 100_000_000 },
  EUR: { exponent: 2, max: 100_000_000 },
  GBP: { exponent: 2, max: 100_000_000 },
  AUD: { exponent: 2, max: 200_000_000 },
  CAD: { exponent: 2, max: 200_000_000 },
  NZD: { exponent: 2, max: 200_000_000 },
  SGD: { exponent: 2, max: 200_000_000 },
  JPY: { exponent: 0, max: 200_000_000 },
  KRW: { exponent: 0, max: 2_000_000_000 },
  TWD: { exponent: 2, max: 5_000_000_000 },
  THB: { exponent: 2, max: 5_000_000_000 },
  HKD: { exponent: 2, max: 1_000_000_000 },
  CNY: { exponent: 2, max: 1_000_000_000 },
  CHF: { exponent: 2, max: 100_000_000 },
  MYR: { exponent: 2, max: 500_000_000 },
} as const;
export type ExpenseCurrency = keyof typeof currencyInfo;
export const expenseCurrencies = Object.keys(currencyInfo) as ExpenseCurrency[];
/** What a document without `currency` is in (back-compat). */
export const legacyCurrency: ExpenseCurrency = 'VND';
export const currencySchema = z.enum(expenseCurrencies as [ExpenseCurrency, ...ExpenseCurrency[]]);
/** Above every currency's ceiling: the plain schema bound (the per-currency one is a refine). */
const anyCurrencyMax = Math.max(...Object.values(currencyInfo).map((c) => c.max));

export function isExpenseCurrency(c: unknown): c is ExpenseCurrency {
  return typeof c === 'string' && Object.prototype.hasOwnProperty.call(currencyInfo, c);
}

/** A stored document's currency: absent (old data) → VND. */
export function currencyOfDoc(c: unknown): ExpenseCurrency {
  return isExpenseCurrency(c) ? c : legacyCurrency;
}

/** The largest amount (minor units) an expense, cap or recurring item may hold in [c]. */
export function amountMaxFor(c: ExpenseCurrency): number {
  return currencyInfo[c].max;
}

/** 1 … the currency's ceiling, an integer. */
export function amountFits(amount: unknown, c: ExpenseCurrency): boolean {
  return (
    Number.isInteger(amount) && (amount as number) >= 1 && (amount as number) <= amountMaxFor(c)
  );
}

/** 12.5 USD → 1250; 486000 VND → 486000 (rounded to the minor unit). */
export function toMinorUnits(major: number, c: ExpenseCurrency): number {
  return Math.round(major * 10 ** currencyInfo[c].exponent);
}

/** 1250 USD → "12.50"; 486000 VND → "486000" (plain, for CSV and model grids). */
export function minorToPlain(amount: number, c: ExpenseCurrency): string {
  const e = currencyInfo[c].exponent;
  if (e === 0) return String(amount);
  const sign = amount < 0 ? '-' : '';
  const abs = Math.abs(amount);
  const unit = 10 ** e;
  return `${sign}${Math.floor(abs / unit)}.${String(abs % unit).padStart(e, '0')}`;
}

const euro = ['AT', 'BE', 'CY', 'DE', 'EE', 'ES', 'FI', 'FR', 'GR', 'HR', 'IE', 'IT', 'LT', 'LU'];
const euro2 = ['LV', 'MT', 'NL', 'PT', 'SI', 'SK'];
const countryCurrency: Record<string, ExpenseCurrency> = {
  VN: 'VND',
  US: 'USD',
  GB: 'GBP',
  AU: 'AUD',
  CA: 'CAD',
  NZ: 'NZD',
  SG: 'SGD',
  JP: 'JPY',
  KR: 'KRW',
  TW: 'TWD',
  TH: 'THB',
  HK: 'HKD',
  CN: 'CNY',
  CH: 'CHF',
  MY: 'MYR',
  ...Object.fromEntries([...euro, ...euro2].map((c) => [c, 'EUR' as const])),
};

/** The household's default before anyone picks one: its country's currency, else VND. */
export function currencyForCountry(country: string | null | undefined): ExpenseCurrency {
  return (country && countryCurrency[country.toUpperCase()]) || legacyCurrency;
}

/**
 * `families/{familyId}/spendingSettings/main`: the household's currency (the add form's default,
 * the currency of new budgets). Written by a Cùng nuôi of one of the family's babies.
 */
export const spendingSettingsSchema = z.object({
  currency: currencySchema,
  updatedAt: z.date(),
  updatedBy: z.string(),
});
export type SpendingSettings = z.infer<typeof spendingSettingsSchema>;

// ---- end currencies ----

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
  /** Minor units of `currency` (≤ its `currencyInfo` max; whole VND without one). */
  amount: z.number().int().min(1).max(anyCurrencyMax),
  /** Absent on older documents: VND (D-075 #4). */
  currency: currencySchema.optional(),
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
  monthlyTotal: z.number().int().min(0).max(anyCurrencyMax).nullable(),
  caps: z.record(categoryIdSchema, z.number().int().min(1).max(anyCurrencyMax)),
  /** What the budget counts (only expenses in it); absent on older documents: VND. */
  currency: currencySchema.optional(),
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
  amount: z.number().int().min(1).max(anyCurrencyMax),
  /** Each occurrence is written in it; absent on older documents: VND. */
  currency: currencySchema.optional(),
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
