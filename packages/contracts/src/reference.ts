import { z } from 'zod';
import { staffReasonSchema } from './staff-reason.js';
import { vaccineProgrammes, vaccineRoutes, vaccineSchedule, type VaccineDef } from './vaccines.js';
import { whoReferenceRows } from './who-reference.g.js';

/**
 * Dữ liệu tham chiếu (Figma C01–C04, P-138): the tables the app compares against or offers as
 * shortcuts, versioned on the portal. A draft is made by "Dữ liệu tham chiếu: Sửa", approved by a
 * different person with "Duyệt"; approval publishes it to `publicConfig/{referenceDocIds[...]}`,
 * which the app reads offline-first and validates, falling back to the copy it ships with.
 * Version 1 of every dataset is what the app shipped before the portal (results unchanged).
 */
export const referenceDatasets = [
  'growth.weight',
  'growth.length',
  'bottle.quickPicks',
  'vaccines.schedule',
] as const;
export type ReferenceDataset = (typeof referenceDatasets)[number];

export const referenceDocIds: Record<ReferenceDataset, string> = {
  'growth.weight': 'reference_growth_weight',
  'growth.length': 'reference_growth_length',
  'bottle.quickPicks': 'reference_bottle',
  'vaccines.schedule': 'reference_vaccines',
};

/** Nháp → Chờ duyệt → Đang dùng → Đã thay (one status per version, never per row). */
export const referenceStatuses = ['draft', 'pending', 'published', 'retired'] as const;
export type ReferenceStatus = (typeof referenceStatuses)[number];

/**
 * One WHO row: P3 (lower), median, P97 (upper) at an age in weeks (0–13) or months (0–60). The
 * app reads between rows by day (D-049: below P3 / above P97 = outside the normal band).
 */
export const growthRowSchema = z
  .object({
    sex: z.enum(['boy', 'girl']),
    unit: z.enum(['week', 'month']),
    age: z.number().int().min(0).max(60),
    low: z.number().positive(),
    median: z.number().positive(),
    high: z.number().positive(),
  })
  .refine((r) => r.low < r.median && r.median < r.high, 'low < median < high');
export type GrowthRow = z.infer<typeof growthRowSchema>;

/** C02: four quick picks for an age band [fromDay, toDay), and the ± step when adjusting. */
export const bottleRowSchema = z
  .object({
    fromDay: z.number().int().min(0).max(3650),
    toDay: z.number().int().min(1).max(3650).nullable(),
    picks: z.array(z.number().int().min(5).max(400)).length(4),
    stepMl: z.number().int().min(1).max(50),
  })
  .refine((r) => r.toDay === null || r.toDay > r.fromDay, 'toDay > fromDay')
  .refine((r) => r.picks.every((p, i) => i === 0 || p > r.picks[i - 1]!), 'picks increase');
export type BottleRow = z.infer<typeof bottleRowSchema>;

const text = z.object({
  vi: z.string().trim().min(1).max(300),
  en: z.string().trim().min(1).max(300),
});

/** C04: the vaccine definitions of P-133 (`VaccineDef`), editable on the portal. */
export const vaccineRowSchema = z.object({
  id: z.string().regex(/^[a-z0-9]{2,12}$/),
  name: text,
  short: text,
  months: z
    .array(z.number().int().min(0).max(72))
    .min(1)
    .max(9)
    .refine((m) => m.every((x, i) => i === 0 || x > m[i - 1]!), 'months increase'),
  programme: z.enum(vaccineProgrammes),
  route: z.enum(vaccineRoutes),
  about: text,
  minIntervalWeeks: z.number().int().min(1).max(104).optional(),
  yearly: z.boolean().optional(),
  only5in1: z.boolean().optional(),
  dtpSeries: z.boolean().optional(),
});

export const referenceRowsSchemas = {
  'growth.weight': z.array(growthRowSchema).min(1).max(400),
  'growth.length': z.array(growthRowSchema).min(1).max(400),
  'bottle.quickPicks': z.array(bottleRowSchema).min(1).max(20),
  'vaccines.schedule': z.array(vaccineRowSchema).min(1).max(40),
} as const;

export type ReferenceRows = {
  'growth.weight': GrowthRow[];
  'growth.length': GrowthRow[];
  'bottle.quickPicks': BottleRow[];
  'vaccines.schedule': VaccineDef[];
};

/** Bottle v1 = the table the app shipped (P-126, `bottle_suggestions.dart`). */
export const bottleQuickPicksV1: BottleRow[] = [
  { fromDay: 0, toDay: 7, picks: [30, 45, 60, 75], stepMl: 5 },
  { fromDay: 7, toDay: 28, picks: [60, 90, 120, 150], stepMl: 10 },
  { fromDay: 28, toDay: 61, picks: [90, 120, 150, 180], stepMl: 10 },
  { fromDay: 61, toDay: 122, picks: [120, 150, 180, 210], stepMl: 10 },
  { fromDay: 122, toDay: null, picks: [150, 180, 210, 240], stepMl: 10 },
];

/** Version 1 of each dataset: exactly what the app shipped before the portal. */
export function referenceV1<D extends ReferenceDataset>(dataset: D): ReferenceRows[D] {
  const rows: ReferenceRows = {
    'growth.weight': whoReferenceRows.weight,
    'growth.length': whoReferenceRows.length,
    'bottle.quickPicks': bottleQuickPicksV1,
    'vaccines.schedule': [...vaccineSchedule],
  };
  return rows[dataset];
}

/** The public projection the apps read (`publicConfig/reference_*`). */
export const referencePublicSchema = z.object({
  dataset: z.enum(referenceDatasets),
  version: z.string().regex(/^v\d{4}\.\d{2}(?:\.\d+)?$/),
  publishedAt: z.string(),
  rows: z.array(z.unknown()),
});
export type ReferencePublic = z.infer<typeof referencePublicSchema>;

const reason = staffReasonSchema;
const versionId = z.string().regex(/^rv_[a-f0-9]{16}$/);

export const referenceViewSchema = z.object({ dataset: z.enum(referenceDatasets) });
/** Save a draft (new, or the open draft of this dataset). */
export const referenceDraftSchema = z.object({
  dataset: z.enum(referenceDatasets),
  rows: z.array(z.unknown()).min(1).max(400),
  notes: z.string().trim().max(500),
  source: z.enum(['edit', 'csv']),
});
export const referenceActSchema = z.object({
  versionId,
  action: z.enum(['submit', 'approve', 'reject', 'discard', 'rollback']),
  reason,
});

/** Row-level differences between two versions, keyed for display (C03 "Khác bản đang dùng 2 dòng"). */
export function rowKey(dataset: ReferenceDataset, row: unknown): string {
  if (dataset === 'bottle.quickPicks') return String((row as BottleRow).fromDay);
  if (dataset === 'vaccines.schedule') return (row as VaccineDef).id;
  const g = row as GrowthRow;
  return `${g.sex}:${g.unit}:${g.age}`;
}

export function diffRows(dataset: ReferenceDataset, before: unknown[], after: unknown[]) {
  const a = new Map(before.map((r) => [rowKey(dataset, r), JSON.stringify(r)]));
  const b = new Map(after.map((r) => [rowKey(dataset, r), JSON.stringify(r)]));
  const added = [...b.keys()].filter((k) => !a.has(k));
  const removed = [...a.keys()].filter((k) => !b.has(k));
  const changed = [...b.keys()].filter((k) => a.has(k) && a.get(k) !== b.get(k));
  return { added, removed, changed };
}

/**
 * C03 "Nhập CSV": parses a growth or bottle table. UTF-8 (BOM allowed), comma or semicolon
 * separated, decimal point or comma. Returns rows or row-level errors (1-based line numbers).
 */
export function parseReferenceCsv(
  dataset: ReferenceDataset,
  csv: string,
  bind: { sex?: 'boy' | 'girl'; unit?: 'week' | 'month' } = {},
): { rows: unknown[]; errors: Array<{ line: number; message: string }> } {
  const errors: Array<{ line: number; message: string }> = [];
  const lines = csv.replace(/^\uFEFF/, '').split(/\r?\n/);
  const sep = (lines[0] ?? '').includes(';') ? ';' : ',';
  const cells = (l: string) => l.split(sep).map((c) => c.trim().replace(/^"|"$/g, ''));
  const num = (c: string | undefined) => {
    if (c === undefined || c === '') return Number.NaN;
    return Number(sep === ';' ? c.replace(',', '.') : c);
  };
  const header = cells(lines[0] ?? '').map((h) => h.toLowerCase());
  const rows: unknown[] = [];
  const lineOf: number[] = [];
  const want =
    dataset === 'bottle.quickPicks'
      ? ['from_day', 'to_day', 'pick1', 'pick2', 'pick3', 'pick4', 'step_ml']
      : dataset === 'vaccines.schedule'
        ? null
        : ['age', 'low', 'median', 'high'];
  if (!want) return { rows, errors: [{ line: 1, message: 'csv-unsupported' }] };
  if (want.some((w, i) => header[i] !== w)) {
    return { rows, errors: [{ line: 1, message: `header:${want.join(',')}` }] };
  }
  for (let i = 1; i < lines.length; i++) {
    const raw = lines[i]!;
    if (!raw.trim()) continue;
    const c = cells(raw);
    const row =
      dataset === 'bottle.quickPicks'
        ? {
            fromDay: num(c[0]),
            toDay: c[1] === '' ? null : num(c[1]),
            picks: [num(c[2]), num(c[3]), num(c[4]), num(c[5])],
            stepMl: num(c[6]),
          }
        : {
            sex: bind.sex,
            unit: bind.unit,
            age: num(c[0]),
            low: num(c[1]),
            median: num(c[2]),
            high: num(c[3]),
          };
    const schema = dataset === 'bottle.quickPicks' ? bottleRowSchema : growthRowSchema;
    const ok = schema.safeParse(row);
    if (!ok.success) {
      errors.push({ line: i + 1, message: ok.error.issues[0]?.message ?? 'invalid' });
    } else {
      rows.push(ok.data);
      lineOf.push(i + 1);
    }
  }
  if (!rows.length && !errors.length) errors.push({ line: 2, message: 'empty' });
  // Ages strictly increase with no duplicates (growth) / bands do not overlap (bottle).
  for (let i = 1; i < rows.length; i++) {
    if (dataset === 'bottle.quickPicks') {
      const prev = rows[i - 1] as BottleRow;
      const cur = rows[i] as BottleRow;
      if (prev.toDay === null || cur.fromDay !== prev.toDay)
        errors.push({ line: lineOf[i]!, message: 'bands-gap' });
    } else if ((rows[i] as GrowthRow).age <= (rows[i - 1] as GrowthRow).age) {
      errors.push({ line: lineOf[i]!, message: 'ages-order' });
    }
  }
  return { rows, errors };
}
