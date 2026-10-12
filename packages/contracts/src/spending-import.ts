import { z } from 'zod';
import { categoryIdSchema } from './spending.js';

/**
 * Nhập chi tiêu (D-060, P-144, plan `docs/product/spending-import-plan.md`): spending kept
 * elsewhere (another app's CSV / Excel, a spreadsheet, pasted text, photos of a notebook) is
 * brought into one baby's Chi tiêu by a Cùng nuôi. The app turns a file into a grid of strings;
 * text and photos become a grid on the server (AI). The server reads the grid, guesses the
 * columns, previews, and once confirmed imports in the background, then mails and pushes the
 * result. One import can be undone for [importLimits.undoDays] days.
 */

export const importLimits = {
  /** A grid uploaded by the app (JSON), and a source file before it is read on the phone. */
  gridBytesMax: 12 * 1024 * 1024,
  fileBytesMax: 10 * 1024 * 1024,
  rowsMax: 5000,
  colsMax: 40,
  cellMax: 300,
  textMax: 20_000,
  imagesMax: 5,
  imageBytesMax: 4 * 1024 * 1024,
  previewRows: 20,
  /** Rows per page of "Xem tất cả". */
  pageRows: 50,
  /** Rows left out shown on the review (with why); all are counted. */
  skippedRows: 30,
  /** Row problems kept on the import (the rest are only counted). */
  issuesKept: 200,
  undoDays: 7,
  /** Uploaded grids and photos are deleted after this. */
  keepFileDays: 7,
  fileNameMax: 120,
} as const;

/** `im_<32 hex>`: made by the app before it uploads, so a retry reuses it. */
export const importIdSchema = z.string().regex(/^im_[a-f0-9]{32}$/);

export const importKinds = ['file', 'text', 'images'] as const;
export type ImportKind = (typeof importKinds)[number];

/**
 * `analyzing` → `ready` (preview) → `queued` (confirmed) → `importing` → `done` | `failed`;
 * `done` → `undone`. A failed analysis is `failed` too.
 */
export const importStatuses = [
  'analyzing',
  'ready',
  'queued',
  'importing',
  'done',
  'failed',
  'undone',
] as const;
export type ImportStatus = (typeof importStatuses)[number];

/** Which grid column holds what (0-based); null = not in the file. */
export const importMappingSchema = z.object({
  /** Rows before this one are skipped (a title, the header). */
  firstRow: z.number().int().min(0).max(importLimits.rowsMax),
  date: z.number().int().min(0).max(importLimits.colsMax).nullable(),
  amount: z.number().int().min(0).max(importLimits.colsMax).nullable(),
  /** Joined with " · " (e.g. "Ghi chú" and "Người nhận"). */
  note: z.array(z.number().int().min(0).max(importLimits.colsMax)).max(3),
  category: z.number().int().min(0).max(importLimits.colsMax).nullable(),
  payer: z.number().int().min(0).max(importLimits.colsMax).nullable(),
});
export type ImportMapping = z.infer<typeof importMappingSchema>;

export const importOptionsSchema = z.object({
  /** How to read 03/04/2026: day first (Vietnam) or month first. */
  dateOrder: z.enum(['dmy', 'mdy']),
  /**
   * Which rows are spending when a file mixes signs (Money Lover writes spending as −):
   * every row (signs dropped), only negative rows, or only positive rows.
   */
  rows: z.enum(['all', 'negative', 'positive']),
  skipDuplicates: z.boolean(),
});
export type ImportOptions = z.infer<typeof importOptionsSchema>;

/** Where a category named in the file goes. */
export const categoryChoiceSchema = z.discriminatedUnion('kind', [
  z.object({ kind: z.literal('existing'), id: categoryIdSchema }),
  /** A new custom category with this name (≤ 24). */
  z.object({ kind: z.literal('new'), name: z.string().trim().min(1).max(24) }),
]);
export type CategoryChoice = z.infer<typeof categoryChoiceSchema>;

/** A member uid, or null for "Khác". */
const payerChoice = z.string().min(1).max(128).nullable();

const sourceName = z.string().max(importLimits.cellMax);

/** `analyzeSpendingImport`: the first call names the source; later calls change the reading. */
export const analyzeImportRequestSchema = z.object({
  babyId: z.string().min(1).max(128),
  importId: importIdSchema,
  kind: z.enum(importKinds),
  /** file: shown in the list and the email ("money-lover-2026.csv"). */
  fileName: z.string().max(importLimits.fileNameMax).optional(),
  /** text: what was pasted. */
  text: z.string().max(importLimits.textMax).optional(),
  /** images: how many photos were uploaded as `imports/{uid}/{importId}/{0..n-1}.jpg`. */
  images: z.number().int().min(1).max(importLimits.imagesMax).optional(),
  mapping: importMappingSchema.optional(),
  options: importOptionsSchema.optional(),
});
export type AnalyzeImportRequest = z.infer<typeof analyzeImportRequestSchema>;

export const confirmImportRequestSchema = z.object({
  babyId: z.string().min(1).max(128),
  importId: importIdSchema,
  mapping: importMappingSchema,
  options: importOptionsSchema,
  /** Folded source name → where it goes; names left out go to "Khác". */
  categories: z.record(sourceName, categoryChoiceSchema),
  /** Folded source name → member uid or null. */
  payers: z.record(sourceName, payerChoice),
});
export type ConfirmImportRequest = z.infer<typeof confirmImportRequestSchema>;

/** "Xem tất cả": one page of the rows that will be imported, with the current reading. */
export const importPageRequestSchema = z.object({
  babyId: z.string().min(1).max(128),
  importId: importIdSchema,
  page: z.number().int().min(0).max(1000),
});

export const undoImportRequestSchema = z.object({
  babyId: z.string().min(1).max(128),
  importId: importIdSchema,
});

/** Why a row is not imported. */
export const importIssues = [
  'no-date',
  'bad-date',
  'future-date',
  'no-amount',
  'bad-amount',
  'too-large',
  'other-currency',
  'income',
  'duplicate',
] as const;
export type ImportIssue = (typeof importIssues)[number];

/** One previewed row, already read with the current mapping. */
export interface ImportPreviewRow {
  /** 1-based row number in the file. */
  row: number;
  spentOn: string | null;
  amount: number | null;
  note: string;
  category: string;
  payer: string;
  issue: ImportIssue | null;
}

export interface ImportCounts {
  rows: number;
  ready: number;
  duplicates: number;
  income: number;
  errors: number;
}

/**
 * `babies/{babyId}/spendingImports/{importId}`: written by Functions only, read by Cùng nuôi.
 * The grid itself stays in Storage (`imports/{uid}/{importId}.json`) for [keepFileDays].
 */
export interface SpendingImportDoc {
  kind: ImportKind;
  fileName: string | null;
  status: ImportStatus;
  /** A known layout ("Money Lover", "MISA Money Keeper", "Child Life"), or null. */
  preset: string | null;
  /** Header cells, or "Cột A", "Cột B"… when the file has none. */
  columns: string[];
  mapping: ImportMapping;
  options: ImportOptions;
  /** Whether the file has both negative and positive amounts (the app then asks). */
  mixedSigns: boolean;
  /** Whether a date such as 03/04 could be read both ways (the app then asks). */
  ambiguousDates: boolean;
  counts: ImportCounts;
  /** The first rows that will be imported. */
  preview: ImportPreviewRow[];
  /** The first rows left out, with why. */
  skipped: ImportPreviewRow[];
  /** What will be imported: the sum and the first and last day. */
  total: { amount: number; from: string | null; to: string | null };
  /** Categories named in the file with a suggestion (folded name as key). */
  categories: { key: string; name: string; rows: number; suggested: CategoryChoice | null }[];
  payers: { key: string; name: string; rows: number; suggested: string | null }[];
  /** After confirming. */
  progress: number;
  imported: number;
  issues: { row: number; issue: ImportIssue }[];
  failure: string | null;
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
  finishedAt: Date | null;
  undoUntil: Date | null;
}

// ---------- Reading cells (shared by the server and its tests) ----------

/** Lower case, no Vietnamese marks, single spaces: "Sữa  Công thức" → "sua cong thuc". */
export function foldText(s: string): string {
  return s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

const pad = (n: number) => String(n).padStart(2, '0');

function validDay(y: number, m: number, d: number): string | null {
  if (y < 100) y += 2000;
  if (y < 1990 || y > 2100 || m < 1 || m > 12 || d < 1) return null;
  const last = new Date(Date.UTC(y, m, 0)).getUTCDate();
  if (d > last) return null;
  return `${y}-${pad(m)}-${pad(d)}`;
}

const monthNames: Record<string, number> = {
  jan: 1, feb: 2, mar: 3, apr: 4, may: 5, jun: 6, jul: 7, aug: 8, sep: 9, sept: 9, oct: 10,
  nov: 11, dec: 12,
};

/**
 * A day from what spreadsheets and apps write: 2026-10-12, 12/10/2026, 12-10-26, 12.10.2026,
 * "12 thg 10, 2026", "12 tháng 10 năm 2026", "Oct 12, 2026", "12 Oct 2026", a time after it, or
 * an Excel serial (45942). [order] decides 03/04/2026. Null when unreadable.
 */
export function parseDay(raw: string, order: 'dmy' | 'mdy' = 'dmy'): string | null {
  const s = raw.trim();
  if (!s) return null;
  let m = s.match(/^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})(?:[T\s].*)?$/);
  if (m) return validDay(+m[1]!, +m[2]!, +m[3]!);
  m = s.match(/^(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})(?:[,\s].*)?$/);
  if (m) {
    const [a, b, y] = [+m[1]!, +m[2]!, +m[3]!];
    return order === 'dmy' ? validDay(y, b, a) : validDay(y, a, b);
  }
  const f = foldText(s);
  m = f.match(/^(\d{1,2})\s*(?:thg|thang)\s*(\d{1,2})(?:\s*,?\s*(?:nam\s*)?(\d{4}))?/);
  if (m && m[3]) return validDay(+m[3]!, +m[2]!, +m[1]!);
  const month = (w: string) => monthNames[w.slice(0, 3)] ?? 0;
  m = f.match(/^([a-z]{3,9})\.?\s+(\d{1,2}),?\s+(\d{4})/);
  if (m && month(m[1]!)) return validDay(+m[3]!, month(m[1]!), +m[2]!);
  m = f.match(/^(\d{1,2})\s+([a-z]{3,9})\.?,?\s+(\d{4})/);
  if (m && month(m[2]!)) return validDay(+m[3]!, month(m[2]!), +m[1]!);
  // Excel serial days (1900 system), 2000-01-01 … 2100.
  if (/^\d{5}(\.\d+)?$/.test(s)) {
    const n = Math.floor(+s);
    if (n >= 36526 && n <= 73051) {
      const d = new Date(Date.UTC(1899, 11, 30) + n * 86_400_000);
      return d.toISOString().slice(0, 10);
    }
  }
  return null;
}

/** "03/04/2026" style days where both parts are ≤ 12. */
export function isAmbiguousDay(raw: string): boolean {
  const m = raw.trim().match(/^(\d{1,2})[-/.](\d{1,2})[-/.]\d{2,4}/);
  return !!m && +m[1]! <= 12 && +m[2]! <= 12 && m[1]! !== m[2]!;
}

/** Which order the dated cells suggest: a first part > 12 means day first. */
export function guessDateOrder(cells: string[]): 'dmy' | 'mdy' {
  let dmy = 0;
  let mdy = 0;
  for (const c of cells) {
    const m = c.trim().match(/^(\d{1,2})[-/.](\d{1,2})[-/.]\d{2,4}/);
    if (!m) continue;
    if (+m[1]! > 12) dmy++;
    if (+m[2]! > 12) mdy++;
  }
  return mdy > dmy ? 'mdy' : 'dmy';
}

export interface ParsedAmount {
  /** Whole VND, sign kept. */
  value: number;
  /** A currency other than VND was named. */
  foreign: boolean;
}

/**
 * Money as people write it: 1.020.000 · 1,020,000 · 1020000.00 · 1.020.000,50 · −500.000 ·
 * (500.000) · 1.020.000 ₫ / đ / VND · 500k · 1tr2 · 1,5 tr · 2 triệu · 300 nghìn. Null when
 * unreadable.
 */
export function parseAmount(raw: string): ParsedAmount | null {
  let s = raw.trim();
  if (!s) return null;
  let negative = false;
  if (/^\(.*\)$/.test(s)) {
    negative = true;
    s = s.slice(1, -1);
  }
  s = s.replace(/−/g, '-');
  if (s.startsWith('-')) {
    negative = true;
    s = s.slice(1);
  }
  if (s.endsWith('-')) {
    negative = true;
    s = s.slice(0, -1);
  }
  const f = foldText(s).replace(/\s+/g, '');
  const foreign = /(usd|\$|eur|€|£|jpy|¥|sgd|aud|thb)/.test(f);
  // Folded, "đ" is already "d".
  const body = f
    .replace(/(usd|\$|eur|€|£|jpy|¥|sgd|aud|thb|₫)/g, '')
    .replace(/(vnd|dong|d)$/, '')
    .replace(/^(vnd|d)/, '')
    .replace(/^\+/, '');
  // "1tr2", "1,5tr", "2trieu", "500k", "300nghin", "1ty".
  const unit = body.match(/^(\d+(?:[.,]\d+)?)(tr|trieu|m|k|nghin|ngan|ty|b)(\d*)$/);
  let value: number | null = null;
  if (unit) {
    const base = +unit[1]!.replace(',', '.');
    const mult = { tr: 1e6, trieu: 1e6, m: 1e6, k: 1e3, nghin: 1e3, ngan: 1e3, ty: 1e9, b: 1e9 }[
      unit[2]! as 'tr'
    ];
    const tail = unit[3]! ? +`0.${unit[3]!}` * mult : 0;
    value = base * mult + tail;
  } else if (/^\d[\d.,\s]*$/.test(body)) {
    value = plainNumber(body.replace(/\s/g, ''));
  }
  if (value == null || !Number.isFinite(value)) return null;
  const rounded = Math.round(value);
  return { value: negative ? -rounded : rounded, foreign };
}

/** "1.020.000" / "1,020,000" / "1020000.5" / "1.020.000,50" → number. */
function plainNumber(s: string): number | null {
  const dots = (s.match(/\./g) ?? []).length;
  const commas = (s.match(/,/g) ?? []).length;
  if (dots && commas) {
    // The later one is the decimal mark.
    return s.lastIndexOf(',') > s.lastIndexOf('.')
      ? +s.replace(/\./g, '').replace(',', '.')
      : +s.replace(/,/g, '');
  }
  const mark = dots ? '.' : commas ? ',' : null;
  if (!mark) return +s;
  const parts = s.split(mark);
  // Several marks, or three digits after one: thousands ("1.020.000", "120,000").
  if (parts.length > 2 || parts[1]!.length === 3) return +parts.join('');
  return +parts.join('.');
}
