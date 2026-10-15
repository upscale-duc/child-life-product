import { createHash, randomBytes } from 'node:crypto';
import {
  amountMaxFor,
  analyzeImportRequestSchema,
  builtInCategories,
  currencyOfDoc,
  detectCurrency,
  toMinorUnits,
  categoryTints,
  confirmImportRequestSchema,
  foldText,
  guessDateOrder,
  importLimits,
  isAmbiguousDay,
  localDateIn,
  otherCategoryId,
  parseAmount,
  parseDay,
  spendingLimits,
  importPageRequestSchema,
  undoImportRequestSchema,
  type CategoryChoice,
  type ImportCounts,
  type ImportIssue,
  type ImportKind,
  type ImportMapping,
  type ImportOptions,
  type ImportPreviewRow,
  type ImportStatus,
  type ExpenseCurrency,
} from '@child-life/contracts';
import type {
  DocumentReference,
  DocumentSnapshot,
  Firestore,
  Timestamp,
} from 'firebase-admin/firestore';
import { AiUnavailable, type ExpenseExtractor } from './ai.js';
import { isActiveMember } from './family.js';
import { importSummary, type Locale } from './mail-templates.js';
import type { PushSender } from './social.js';
import { SpendingError, householdCurrency, pushUsers } from './spending.js';
import { aiBudgetLeft, chargeAi } from './staff.js';

/**
 * Nhập chi tiêu (D-060, P-144; plan `docs/product/spending-import-plan.md`). The app turns a CSV
 * or Excel file into a grid of strings (`imports/{uid}/{importId}.json`); pasted text and photos
 * become the same grid here through the AI adapter (D-003). The server finds the columns, reads
 * the rows, writes a preview to `babies/{babyId}/spendingImports/{importId}`, and once a Cùng
 * nuôi confirms, a trigger imports in batches, then mails and pushes the importer. An import can
 * be undone for [importLimits.undoDays] days.
 *
 * Logs carry ids, counts and reason codes only: never amounts, descriptions, category names,
 * file names or what the AI read (R-120, P-144).
 */

export type Grid = string[][];

const DEFAULT_ZONE = 'Asia/Ho_Chi_Minh';
/** Firestore allows 500 writes per batch; keep a margin. */
const BATCH_MAX = 450;
const DAY_MS = 86_400_000;
/** Imports left in a waiting state this long are marked failed ("expired"). */
const STUCK_DAYS = 2;
/** What one AI reading is counted as against the monthly AI budget (A09). */
const AI_COST_VND = { text: 300, image: 500 } as const;
/** Analysis failures: the same import may be analysed again. */
const ANALYSIS_FAILURES = new Set([
  'no-upload',
  'too-big',
  'empty',
  'ai-unavailable',
  'ai-failed',
  'analyze-failed',
]);

/** Where the push opens (the app registers the route). */
export const importRoute = (importId: string) => `/utilities/spending/import/${importId}`;
export const gridPath = (uid: string, importId: string) => `imports/${uid}/${importId}.json`;
export const photoPath = (uid: string, importId: string, n: number) =>
  `imports/${uid}/${importId}/${n}.jpg`;

/** `x_` + 32 hex per (import, row): a retry never doubles an expense. */
export function importedExpenseId(importId: string, row: number): string {
  return `x_${createHash('sha256').update(`${importId}:${row}`).digest('hex').slice(0, 32)}`;
}

/** `c_` + 20 hex per (import, folded name): a retry never doubles a new category. */
export function importedCategoryId(importId: string, key: string): string {
  return `c_${createHash('sha256').update(`${importId}:cat:${key}`).digest('hex').slice(0, 20)}`;
}

// ---------- Grid ----------

/** A grid as uploaded (JSON array of rows), within [importLimits]; strings only. */
export function parseGrid(raw: unknown): Grid {
  if (!Array.isArray(raw)) throw new SpendingError('invalid-argument', 'bad-upload');
  if (raw.length > importLimits.rowsMax + 50)
    throw new SpendingError('invalid-argument', 'too-big');
  const grid: Grid = [];
  for (const row of raw) {
    if (!Array.isArray(row)) throw new SpendingError('invalid-argument', 'bad-upload');
    if (row.length > importLimits.colsMax) throw new SpendingError('invalid-argument', 'too-big');
    grid.push(
      row.map((cell: unknown) => {
        const s = cell == null ? '' : typeof cell === 'string' ? cell : String(cell);
        if (s.length > importLimits.cellMax) throw new SpendingError('invalid-argument', 'too-big');
        return s;
      }),
    );
  }
  // Trailing empty rows (spreadsheets keep them) do not count.
  while (grid.length && grid[grid.length - 1]!.every((c) => !c.trim())) grid.pop();
  if (grid.length > importLimits.rowsMax) throw new SpendingError('invalid-argument', 'too-big');
  if (grid.length === 0) throw new SpendingError('invalid-argument', 'empty');
  return grid;
}

// ---------- Columns ----------

type Field = 'date' | 'amount' | 'note' | 'category' | 'payer' | 'currency';

/** Folded header keywords (vi / en). The longest match wins; an exact match beats a partial one. */
const keywords: Record<Field, string[]> = {
  date: ['ngay', 'ngay giao dich', 'ngay chi', 'thoi gian', 'date', 'time', 'day'],
  amount: [
    'so tien',
    'thanh tien',
    'tong tien',
    'tien',
    'gia',
    'chi',
    'chi tieu',
    'amount',
    'money',
    'value',
    'total',
    'vnd',
  ],
  note: [
    'noi dung',
    'ghi chu',
    'dien giai',
    'mo ta',
    'ten',
    'ten khoan',
    'chi tiet',
    'nguoi nhan',
    'note',
    'description',
    'memo',
    'item',
    'details',
    'title',
    'payee',
  ],
  category: ['danh muc', 'hang muc', 'nhom', 'loai', 'category', 'type', 'group'],
  payer: ['nguoi tra', 'ai tra', 'nguoi chi', 'payer', 'paid by', 'who paid', 'by', 'nguoi'],
  currency: ['currency', 'tien te', 'loai tien', 'don vi tien', 'ma tien te'],
};

/** Headers that look like a field but are not one ("Ghi bởi" is who typed it, not who paid). */
const ignoredHeaders = new Set([
  'ghi boi',
  'nguoi ghi',
  'nguoi tao',
  'recorded by',
  'created by',
  'id',
  'wallet',
  'vi',
  'tai khoan',
  'account',
]);

/** Folded, punctuation as spaces: "Số tiền (VNĐ)" → "so tien vnd". */
const headerKey = (s: string) =>
  foldText(s)
    .replace(/[^a-z0-9 ]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

const containsWords = (text: string, words: string) => ` ${text} `.includes(` ${words} `);

function headerScore(cell: string, field: Field): number {
  const key = headerKey(cell);
  if (!key || key.length > 40 || ignoredHeaders.has(key)) return 0;
  let best = 0;
  for (const k of keywords[field]) {
    if (key === k) best = Math.max(best, 100 + k.length);
    else if (containsWords(key, k)) best = Math.max(best, k.length);
  }
  return best;
}

const looksLikeData = (cell: string) =>
  parseDay(cell) != null || parseDay(cell, 'mdy') != null || parseAmount(cell) != null;

/** A known layout, from the folded header cells. */
function presetOf(headers: string[]): string | null {
  const h = new Set(headers.map(headerKey));
  const all = (...k: string[]) => k.every((x) => h.has(x));
  if (
    all('ngay', 'danh muc', 'noi dung', 'so tien', 'ai tra') ||
    all('date', 'category', 'description', 'amount', 'who paid')
  )
    return 'Child Life';
  if (all('date', 'category', 'amount', 'note') && (h.has('wallet') || h.has('currency')))
    return 'Money Lover';
  if (all('so tien', 'hang muc', 'dien giai') && (h.has('ngay') || h.has('thoi gian')))
    return 'MISA Money Keeper';
  return null;
}

export const columnLetter = (i: number): string =>
  i < 26
    ? String.fromCharCode(65 + i)
    : `${columnLetter(Math.floor(i / 26) - 1)}${columnLetter(i % 26)}`;

export interface Layout {
  preset: string | null;
  /** 0-based header row, or null when the file has none. */
  headerRow: number | null;
  columns: string[];
  mapping: ImportMapping;
  /** A column naming the currency of each row (not part of the mapping). */
  currency: number | null;
}

const widthOf = (grid: Grid) =>
  Math.min(importLimits.colsMax, Math.max(0, ...grid.map((r) => r.length)));

/** Finds the header row (first of the first 10 with ≥ 2 header-like cells) and the columns. */
export function detectLayout(grid: Grid): Layout {
  const width = widthOf(grid);
  let headerRow: number | null = null;
  const allFields: Field[] = ['date', 'amount', 'note', 'category', 'payer', 'currency'];
  for (let r = 0; r < Math.min(10, grid.length); r++) {
    const row = grid[r]!;
    // A header names two different things and holds no day or amount (data rows do).
    if (row.some(looksLikeData)) continue;
    const named = row.filter((c) => allFields.some((f) => headerScore(c, f) > 0)).length;
    if (named >= 2) {
      headerRow = r;
      break;
    }
  }

  const mapping: ImportMapping = {
    firstRow: headerRow == null ? 0 : headerRow + 1,
    date: null,
    amount: null,
    note: [],
    category: null,
    payer: null,
  };
  let currency: number | null = null;
  const used = new Set<number>();
  if (headerRow != null) {
    const header = grid[headerRow]!;
    const candidates: { field: Field; col: number; score: number }[] = [];
    header.forEach((cell, col) => {
      for (const field of allFields) {
        const score = headerScore(cell, field);
        if (score > 0) candidates.push({ field, col, score });
      }
    });
    candidates.sort((a, b) => b.score - a.score || a.col - b.col);
    for (const { field, col } of candidates) {
      if (used.has(col)) continue;
      if (field === 'note') {
        if (mapping.note.length >= 3) continue;
        mapping.note.push(col);
      } else if (field === 'currency') {
        if (currency != null) continue;
        currency = col;
      } else {
        if (mapping[field] != null) continue;
        mapping[field] = col;
      }
      used.add(col);
    }
    mapping.note.sort((a, b) => a - b);
  }

  // Without a header (or a header missing the essentials): read the content.
  const guess = guessByContent(grid, mapping.firstRow, width, used);
  if (mapping.date == null && guess.date != null) {
    mapping.date = guess.date;
    used.add(guess.date);
  }
  if (mapping.amount == null && guess.amount != null && !used.has(guess.amount)) {
    mapping.amount = guess.amount;
    used.add(guess.amount);
  }
  if (mapping.note.length === 0) {
    const note = guessNote(grid, mapping.firstRow, width, used);
    if (note != null) mapping.note = [note];
  }
  if (currency == null) currency = guessCurrency(grid, mapping.firstRow, width, used);
  if (headerRow == null && mapping.date != null) {
    // Skip a title above the data: start at the first row with a day.
    const first = grid.findIndex((r) => readDay(r[mapping.date!] ?? '') != null);
    if (first > 0) mapping.firstRow = first;
  }

  const header = headerRow == null ? null : grid[headerRow]!;
  const columns = Array.from({ length: width }, (_, i) => {
    const name = header?.[i]?.trim();
    return name ? name.slice(0, 60) : `Cột ${columnLetter(i)}`;
  });
  return { preset: header ? presetOf(header) : null, headerRow, columns, mapping, currency };
}

const readDay = (cell: string) => parseDay(cell) ?? parseDay(cell, 'mdy');
/** A day written with separators or words (not a bare Excel serial, which also reads as money). */
const strongDay = (cell: string) => !/^\d+(\.\d+)?$/.test(cell.trim()) && readDay(cell) != null;

function sample(grid: Grid, from: number, col: number): string[] {
  const out: string[] = [];
  for (let r = from; r < grid.length && out.length < 300; r++) {
    const c = grid[r]![col]?.trim() ?? '';
    if (c) out.push(c);
  }
  return out;
}

function guessByContent(
  grid: Grid,
  from: number,
  width: number,
  used: Set<number>,
): { date: number | null; amount: number | null } {
  let date: number | null = null;
  let dateShare = 0;
  let serialDate: number | null = null;
  let serialShare = 0;
  const share = new Map<number, { strong: number; serial: number; money: number; size: number }>();
  for (let col = 0; col < width; col++) {
    if (used.has(col)) continue;
    const cells = sample(grid, from, col);
    if (cells.length === 0) continue;
    const strong = cells.filter(strongDay).length / cells.length;
    const serial =
      cells.filter((c) => /^\d{5}(\.\d+)?$/.test(c) && readDay(c) != null).length / cells.length;
    const amounts = cells
      .filter((c) => !strongDay(c))
      .map((c) => parseAmount(c))
      .filter((a) => a != null);
    const money = amounts.length / cells.length;
    // Row numbers ("STT") read as money too; amounts are larger.
    const size = amounts.reduce((t, a) => t + Math.abs(a.value), 0) / Math.max(1, amounts.length);
    share.set(col, { strong, serial, money, size });
    if (strong > dateShare) {
      dateShare = strong;
      date = col;
    }
    if (serial > serialShare) {
      serialShare = serial;
      serialDate = col;
    }
  }
  if (dateShare < 0.5) {
    // Excel serials only when every cell is one (amounts are rarely all five-digit numbers).
    date = serialShare >= 0.95 ? serialDate : null;
  }
  let amount: number | null = null;
  let best = { money: 0.5, size: -1 };
  for (const [col, s] of share) {
    if (col === date || s.money < 0.5) continue;
    if (s.money > best.money + 0.05 || (s.money >= best.money - 0.05 && s.size > best.size)) {
      best = { money: Math.max(best.money, s.money), size: s.size };
      amount = col;
    }
  }
  return { date, amount };
}

function guessNote(grid: Grid, from: number, width: number, used: Set<number>): number | null {
  let best: number | null = null;
  let bestLength = 0;
  for (let col = 0; col < width; col++) {
    if (used.has(col)) continue;
    const cells = sample(grid, from, col).filter((c) => !looksLikeData(c));
    if (cells.length === 0) continue;
    const avg = cells.reduce((s, c) => s + c.length, 0) / cells.length;
    if (avg > bestLength) {
      bestLength = avg;
      best = col;
    }
  }
  return best;
}

const currencyCode = /^(vnd|vnđ|₫|đ|usd|eur|gbp|jpy|sgd|aud|thb|cny|krw|\$|€|£|¥)$/i;

function guessCurrency(grid: Grid, from: number, width: number, used: Set<number>): number | null {
  for (let col = 0; col < width; col++) {
    if (used.has(col)) continue;
    const cells = sample(grid, from, col);
    if (cells.length > 0 && cells.filter((c) => currencyCode.test(c)).length / cells.length >= 0.8)
      return col;
  }
  return null;
}

// ---------- Rows ----------

export type ReadRow = ImportPreviewRow;

export interface ReadContext {
  /** The baby's local day; later days are refused. */
  today: string;
  /** `${spentOn}|${amount}|${folded note}` of live expenses (this import's own excluded). */
  existing: Set<string>;
  /** The column naming each row's currency, if the file has one. */
  currency?: number | null;
  /** D-075 #4: the household's currency, for rows that name none (default VND). */
  household?: ExpenseCurrency;
}

/** VND keys stay as before D-075 #4; another currency is part of the key. */
export const duplicateKey = (
  spentOn: string,
  amount: number,
  note: string,
  currency: ExpenseCurrency = 'VND',
) => `${spentOn}|${amount}|${foldText(note)}${currency === 'VND' ? '' : `|${currency}`}`;

/** A spreadsheet's formula guard ("'-500"): the quote is not part of the text. */
const cleanText = (s: string) =>
  s
    .replace(/^'(?=[=+\-@])/, '')
    .replace(/\s+/g, ' ')
    .trim();

/** Trimmed to [max] UTF-16 units without cutting a surrogate pair. */
function clip(s: string, max: number): string {
  if (s.length <= max) return s;
  const cut = s.slice(0, max);
  return /[\uD800-\uDBFF]$/.test(cut) ? cut.slice(0, -1) : cut;
}

/** Reads every non-empty row from `mapping.firstRow` (empty rows are dropped silently). */
export function readRows(
  grid: Grid,
  mapping: ImportMapping,
  options: ImportOptions,
  ctx: ReadContext,
): ReadRow[] {
  const out: ReadRow[] = [];
  const cell = (row: string[], col: number | null) => (col == null ? '' : (row[col] ?? '').trim());
  for (let i = mapping.firstRow; i < grid.length; i++) {
    const row = grid[i]!;
    if (row.every((c) => !c.trim())) continue;
    const note = clip(
      mapping.note
        .map((c) => cleanText(cell(row, c)))
        .filter(Boolean)
        .join(' · '),
      spendingLimits.noteMax,
    ).trim();
    const dateRaw = cell(row, mapping.date);
    const amountRaw = cleanText(cell(row, mapping.amount));
    const spentOn = dateRaw ? parseDay(dateRaw, options.dateOrder) : null;
    const household = ctx.household ?? 'VND';
    const parsed = amountRaw ? parseAmount(amountRaw, household) : null;
    // D-075 #4: the currency named in the amount, else in the currency column, else the
    // household's; a currency Chi tiêu does not keep is still skipped.
    const named =
      parsed?.currency ??
      (ctx.currency != null ? detectCurrency(cell(row, ctx.currency), household) : null);
    const currency: ExpenseCurrency = named == null || named === 'other' ? household : named;
    const minor = parsed ? Math.abs(toMinorUnits(parsed.major, currency)) : 0;

    let amount: number | null = null;
    let issue: ImportIssue | null = null;
    if (!amountRaw) issue = 'no-amount';
    else if (!parsed || minor === 0) issue = 'bad-amount';
    else if (named === 'other') issue = 'other-currency';
    else if (options.rows === 'negative' && parsed.value > 0) issue = 'income';
    else if (options.rows === 'positive' && parsed.value < 0) issue = 'income';
    else if (minor > amountMaxFor(currency)) issue = 'too-large';
    else if (!dateRaw) issue = 'no-date';
    else if (!spentOn) issue = 'bad-date';
    else if (spentOn > ctx.today) issue = 'future-date';
    if (parsed && minor !== 0) amount = minor;
    if (
      issue == null &&
      options.skipDuplicates &&
      ctx.existing.has(duplicateKey(spentOn!, amount!, note, currency))
    )
      issue = 'duplicate';
    out.push({
      row: i + 1,
      spentOn,
      amount,
      note,
      category: cleanText(cell(row, mapping.category)),
      payer: cleanText(cell(row, mapping.payer)),
      issue,
      currency,
    });
  }
  return out;
}

/** The reading options a file suggests: its day order, and negative rows when signs mix. */
export function defaultOptions(grid: Grid, mapping: ImportMapping): ImportOptions {
  const { mixedSigns } = signsAndDates(grid, mapping);
  const dates = mapping.date == null ? [] : sample(grid, mapping.firstRow, mapping.date);
  return {
    dateOrder: guessDateOrder(dates),
    rows: mixedSigns ? 'negative' : 'all',
    skipDuplicates: true,
  };
}

/** Whether amounts have both signs, and whether a day such as 03/04 reads both ways. */
export function signsAndDates(
  grid: Grid,
  mapping: ImportMapping,
): { mixedSigns: boolean; ambiguousDates: boolean } {
  let negative = false;
  let positive = false;
  if (mapping.amount != null) {
    for (let i = mapping.firstRow; i < grid.length; i++) {
      const v = parseAmount(cleanText(grid[i]![mapping.amount] ?? ''))?.value ?? 0;
      if (v < 0) negative = true;
      if (v > 0) positive = true;
      if (negative && positive) break;
    }
  }
  let ambiguous = false;
  let decided = false;
  if (mapping.date != null) {
    for (let i = mapping.firstRow; i < grid.length; i++) {
      const c = (grid[i]![mapping.date] ?? '').trim();
      if (isAmbiguousDay(c)) ambiguous = true;
      const m = c.match(/^(\d{1,2})[-/.](\d{1,2})[-/.]\d{2,4}/);
      if (m && (+m[1]! > 12 || +m[2]! > 12)) decided = true;
    }
  }
  return { mixedSigns: negative && positive, ambiguousDates: ambiguous && !decided };
}

export function countRows(rows: ReadRow[]): ImportCounts {
  const counts: ImportCounts = { rows: rows.length, ready: 0, duplicates: 0, income: 0, errors: 0 };
  for (const r of rows) {
    if (r.issue == null) counts.ready += 1;
    else if (r.issue === 'duplicate') counts.duplicates += 1;
    else if (r.issue === 'income') counts.income += 1;
    else counts.errors += 1;
  }
  return counts;
}

// ---------- Categories and payers ----------

export interface FamilyCategory {
  id: string;
  /** Null for a built-in keeping its translated name. */
  name: string | null;
  builtIn: boolean;
  hidden: boolean;
}

/** Built-in names as the app shows them (vi / en). */
export const builtInNames: Record<string, [string, string]> = {
  c_childcare: ['Giữ trẻ & học', 'Childcare & learning'],
  c_milk: ['Sữa & ăn dặm', 'Milk & solids'],
  c_diaper: ['Tã & vệ sinh', 'Diapers & hygiene'],
  c_health: ['Y tế & tiêm chủng', 'Health & vaccines'],
  c_clothes: ['Quần áo', 'Clothes'],
  c_other: ['Khác', 'Other'],
};

/** Folded words → built-in (longest first when matching). */
const categorySynonyms: [string, string][] = (
  [
    ['c_milk', ['sua', 'bim sua', 'an dam', 'thuc pham', 'milk', 'formula', 'food']],
    ['c_diaper', ['ta', 'bim', 've sinh', 'khan uot', 'diaper', 'diapers']],
    [
      'c_health',
      ['y te', 'thuoc', 'kham', 'tiem', 'vaccine', 'vac xin', 'benh vien', 'health', 'doctor'],
    ],
    ['c_clothes', ['quan ao', 'do mac', 'giay dep', 'clothes']],
    [
      'c_childcare',
      ['giu tre', 'hoc', 'truong', 'nha tre', 'mam non', 'hoc phi', 'childcare', 'school', 'nanny'],
    ],
  ] as [string, string[]][]
)
  .flatMap(([id, words]) => words.map((w) => [w, id] as [string, string]))
  .sort((a, b) => b[0].length - a[0].length);

/** The family's categories: stored ones, plus built-ins not written yet (shown by default). */
export function withBuiltIns(stored: FamilyCategory[]): FamilyCategory[] {
  const ids = new Set(stored.map((c) => c.id));
  return [
    ...stored,
    ...builtInCategories
      .filter((c) => !ids.has(c.id))
      .map((c) => ({ id: c.id, name: null, builtIn: true, hidden: false })),
  ];
}

/** Every folded name a category answers to. */
function namesOf(c: FamilyCategory): string[] {
  const names = c.name ? [c.name] : [];
  if (c.builtIn) names.push(...(builtInNames[c.id] ?? []));
  return names.map(headerKey);
}

/** A category named in the file → an existing one, by name then by synonym; else null. */
export function suggestCategory(name: string, categories: FamilyCategory[]): CategoryChoice | null {
  const key = headerKey(name);
  if (!key) return null;
  const visible = categories.filter((c) => !c.hidden);
  const exact = visible.find((c) => namesOf(c).includes(key));
  if (exact) return { kind: 'existing', id: exact.id };
  for (const [word, id] of categorySynonyms) {
    if (containsWords(key, word)) {
      return visible.some((c) => c.id === id) ? { kind: 'existing', id } : null;
    }
  }
  return null;
}

export interface MemberLabel {
  uid: string;
  displayName: string;
  relation: string;
  relationCustom: string | null;
}

/** Lower case with marks: "Bà" (grandmother) and "Ba" (father) differ only by the mark. */
const relationWords: Record<string, { marked: string[]; folded: string[] }> = {
  mother: { marked: ['mẹ', 'má', 'mẹ bé', 'vợ'], folded: ['me', 'mom', 'mum', 'mommy', 'mother'] },
  father: {
    marked: ['bố', 'ba', 'cha', 'ba bé', 'chồng'],
    folded: ['bo', 'dad', 'daddy', 'father'],
  },
  grandmother: {
    marked: ['bà', 'bà nội', 'bà ngoại'],
    folded: ['ba noi', 'ba ngoai', 'grandma', 'grandmother', 'granny', 'nana'],
  },
  grandfather: {
    marked: ['ông', 'ông nội', 'ông ngoại'],
    folded: ['ong', 'ong noi', 'ong ngoai', 'grandpa', 'grandfather'],
  },
  nanny: { marked: ['bảo mẫu', 'cô giữ trẻ'], folded: ['bao mau', 'nanny', 'co giu tre'] },
};

/** A payer named in the file → a member uid (name, own label, or relation word); else null. */
export function suggestPayer(name: string, members: MemberLabel[]): string | null {
  const key = foldText(name);
  if (!key) return null;
  const byName = members.find(
    (m) =>
      foldText(m.displayName) === key || (m.relationCustom && foldText(m.relationCustom) === key),
  );
  if (byName) return byName.uid;
  const marked = name.normalize('NFC').toLowerCase().replace(/\s+/g, ' ').trim();
  for (const pass of ['marked', 'folded'] as const) {
    for (const [relation, words] of Object.entries(relationWords)) {
      const hit = pass === 'marked' ? words.marked.includes(marked) : words.folded.includes(key);
      if (!hit) continue;
      const m = members.find((x) => x.relation === relation);
      if (m) return m.uid;
    }
  }
  return null;
}

/** Folded source name, the key of `categories` (marks ignored, D-060; ≤ 300 characters). */
export const sourceKey = (name: string) => foldText(name).slice(0, importLimits.cellMax);

/**
 * The key of `payers`: lower case with the marks kept, since "Ba" (father) and "Bà"
 * (grandmother) are different people.
 */
export const payerKey = (name: string) =>
  name.normalize('NFC').toLowerCase().replace(/\s+/g, ' ').trim().slice(0, importLimits.cellMax);

export function summarize(
  rows: ReadRow[],
  categories: FamilyCategory[],
  members: MemberLabel[],
): {
  categories: { key: string; name: string; rows: number; suggested: CategoryChoice | null }[];
  payers: { key: string; name: string; rows: number; suggested: string | null }[];
} {
  const cats = new Map<string, { name: string; rows: number }>();
  const pays = new Map<string, { name: string; rows: number }>();
  for (const r of rows) {
    if (r.issue != null) continue;
    for (const [map, name, keyOf] of [
      [cats, r.category, sourceKey],
      [pays, r.payer, payerKey],
    ] as const) {
      const key = keyOf(name);
      if (!key) continue;
      const entry = map.get(key) ?? { name, rows: 0 };
      entry.rows += 1;
      map.set(key, entry);
    }
  }
  // Owner, 2026-10-12: a name without a match becomes a category of its own, as far as the
  // family's room for custom categories goes (the largest first); the rest go to "Khác".
  let room = Math.max(
    0,
    spendingLimits.customCategoriesMax - categories.filter((c) => !c.builtIn).length,
  );
  const byRows = [...cats].sort((a, b) => b[1].rows - a[1].rows);
  const suggested = new Map<string, CategoryChoice | null>();
  for (const [key, v] of byRows) {
    const match = suggestCategory(v.name, categories);
    if (match) {
      suggested.set(key, match);
    } else if (room > 0) {
      room -= 1;
      suggested.set(key, {
        kind: 'new',
        name: v.name.trim().slice(0, spendingLimits.categoryNameMax),
      });
    } else {
      suggested.set(key, null);
    }
  }
  return {
    categories: [...cats].map(([key, v]) => ({
      key,
      ...v,
      suggested: suggested.get(key) ?? null,
    })),
    payers: [...pays].map(([key, v]) => ({ key, ...v, suggested: suggestPayer(v.name, members) })),
  };
}

/**
 * What the review shows: the first rows that will be imported, the rows left out with why, and
 * the total and days of what will be imported.
 */
export function previewOf(
  rows: ReadRow[],
  household: ExpenseCurrency = 'VND',
): {
  preview: ReadRow[];
  skipped: ReadRow[];
  total: {
    amount: number;
    from: string | null;
    to: string | null;
    currency: ExpenseCurrency;
    others: { currency: ExpenseCurrency; amount: number }[];
  };
} {
  const ready = rows.filter((r) => r.issue == null);
  const sums = new Map<ExpenseCurrency, number>();
  for (const r of ready) {
    const c = r.currency ?? 'VND';
    sums.set(c, (sums.get(c) ?? 0) + (r.amount ?? 0));
  }
  const days = ready
    .map((r) => r.spentOn)
    .filter((d): d is string => d != null)
    .sort();
  return {
    preview: ready.slice(0, importLimits.previewRows),
    skipped: rows.filter((r) => r.issue != null).slice(0, importLimits.skippedRows),
    total: {
      // D-075 #4: never summed across currencies; the household's first, the others apart.
      amount: sums.get(household) ?? 0,
      from: days[0] ?? null,
      to: days[days.length - 1] ?? null,
      currency: household,
      others: [...sums]
        .filter(([c]) => c !== household)
        .map(([currency, amount]) => ({ currency, amount })),
    },
  };
}

// ---------- Firebase ----------

/** Storage behind one port (tests use memory). */
export interface ImportStore {
  /** Size in bytes, or null when the object does not exist. */
  size(path: string): Promise<number | null>;
  read(path: string): Promise<Buffer>;
  write(path: string, bytes: Buffer, contentType: string): Promise<void>;
  /** Up to [max] objects under [prefix] created before [before]. */
  listOlderThan(prefix: string, before: Date, max: number): Promise<string[]>;
  delete(path: string): Promise<void>;
}

export interface ImportDeps {
  db: Firestore;
  store: ImportStore;
  /** Null without an API key: the AI sources answer "ai-unavailable". */
  extractor: ExpenseExtractor | null;
}

export interface NotifyDeps {
  sender: PushSender | null;
  emailOf: (uid: string) => Promise<string | null>;
}

const babyActive = (baby: DocumentSnapshot) =>
  baby.exists && ((baby.get('state') as string | undefined) ?? 'active') === 'active';
const zoneOf = (baby: DocumentSnapshot) =>
  (baby.get('timeZone.zone') as string | undefined) ?? DEFAULT_ZONE;

async function requireParent(db: Firestore, babyId: string, uid: string, now: Date) {
  const member = await db.doc(`babies/${babyId}/members/${uid}`).get();
  if (!isActiveMember(member, now)) throw new SpendingError('permission-denied', 'not-a-member');
  if (member.get('role') !== 'coParent')
    throw new SpendingError('permission-denied', 'not-co-parent');
  const baby = await db.doc(`babies/${babyId}`).get();
  if (!babyActive(baby)) throw new SpendingError('failed-precondition', 'baby-closed');
  return { member, baby };
}

async function familyCategories(db: Firestore, familyId: string): Promise<FamilyCategory[]> {
  const docs = await db.collection(`families/${familyId}/spendingCategories`).get();
  return withBuiltIns(
    docs.docs.map((d) => ({
      id: d.id,
      name: (d.get('name') as string | null | undefined) ?? null,
      builtIn: d.get('builtIn') === true,
      hidden: d.get('hidden') === true,
    })),
  );
}

async function activeMembers(db: Firestore, babyId: string, now: Date) {
  const docs = await db.collection(`babies/${babyId}/members`).get();
  return docs.docs.filter((m) => isActiveMember(m, now));
}

const labelOf = (m: DocumentSnapshot): MemberLabel => ({
  uid: m.id,
  displayName: (m.get('displayName') as string | undefined) ?? '',
  relation: (m.get('relation') as string | undefined) ?? 'other',
  relationCustom: (m.get('relationCustom') as string | null | undefined) ?? null,
});

/** The snapshot the app writes as `author` / `payer` (rules: ownAuthor, validPayer). */
const authorOf = (m: DocumentSnapshot) => {
  const l = labelOf(m);
  return { name: l.displayName, relation: l.relation, relationCustom: l.relationCustom };
};

/** Live expenses of the baby on the days the rows cover, this import's own excluded. */
async function existingKeys(
  db: Firestore,
  babyId: string,
  importId: string,
  rows: ReadRow[],
): Promise<Set<string>> {
  const days = rows
    .map((r) => r.spentOn)
    .filter((d): d is string => d != null)
    .sort();
  if (days.length === 0) return new Set();
  const docs = await db
    .collection(`babies/${babyId}/expenses`)
    .where('spentOn', '>=', days[0]!)
    .where('spentOn', '<=', days[days.length - 1]!)
    .get();
  const keys = new Set<string>();
  for (const d of docs.docs) {
    if (d.get('deleted') === true || d.get('sourceRef') === importId) continue;
    const spentOn = d.get('spentOn') as string;
    const amount = d.get('amount') as number;
    keys.add(
      duplicateKey(
        spentOn,
        amount,
        (d.get('note') as string | undefined) ?? '',
        currencyOfDoc(d.get('currency')),
      ),
    );
  }
  return keys;
}

/** Reads the rows twice: once to learn the days, then against the expenses of those days. */
async function readWithDuplicates(
  db: Firestore,
  babyId: string,
  importId: string,
  grid: Grid,
  mapping: ImportMapping,
  options: ImportOptions,
  today: string,
  currency: number | null,
  household: ExpenseCurrency,
): Promise<ReadRow[]> {
  const first = readRows(grid, mapping, options, {
    today,
    existing: new Set(),
    currency,
    household,
  });
  if (!options.skipDuplicates) return first;
  const existing = await existingKeys(db, babyId, importId, first);
  return existing.size === 0
    ? first
    : readRows(grid, mapping, options, { today, existing, currency, household });
}

const AI_HEADER = ['Ngày', 'Danh mục', 'Nội dung', 'Số tiền', 'Ai trả', 'Tiền tệ'];

/** An AI amount as a cell: whole numbers as is, others with two decimals ("12.50"). */
const aiAmount = (a: number) => (Number.isInteger(a) ? String(a) : a.toFixed(2));

/** The grid of an import: the uploaded / stored JSON, else (text, photos) read by AI and stored. */
async function loadGrid(
  deps: ImportDeps,
  owner: string,
  importId: string,
  req: { kind: ImportKind; text?: string | undefined; images?: number | undefined },
  today: string,
  locale: Locale,
  now: Date,
  household: ExpenseCurrency = 'VND',
): Promise<Grid> {
  const path = gridPath(owner, importId);
  const size = await deps.store.size(path);
  if (size != null) {
    if (size > importLimits.gridBytesMax) throw new SpendingError('invalid-argument', 'too-big');
    let raw: unknown;
    try {
      raw = JSON.parse((await deps.store.read(path)).toString('utf8'));
    } catch {
      throw new SpendingError('invalid-argument', 'bad-upload');
    }
    return parseGrid(raw);
  }
  if (req.kind === 'file') throw new SpendingError('failed-precondition', 'no-upload');

  let images: Buffer[] | undefined;
  if (req.kind === 'text') {
    if (!req.text?.trim()) throw new SpendingError('invalid-argument', 'empty');
  } else {
    if (!req.images) throw new SpendingError('failed-precondition', 'no-upload');
    images = [];
    for (let n = 0; n < req.images; n++) {
      const p = photoPath(owner, importId, n);
      const bytes = await deps.store.size(p);
      if (bytes == null) throw new SpendingError('failed-precondition', 'no-upload');
      if (bytes > importLimits.imageBytesMax)
        throw new SpendingError('invalid-argument', 'too-big');
      images.push(await deps.store.read(p));
    }
  }
  if (!deps.extractor || !(await aiBudgetLeft(deps.db, now)))
    throw new SpendingError('failed-precondition', 'ai-unavailable');
  let rows;
  try {
    rows = await deps.extractor.extractExpenses({
      ...(req.kind === 'text' ? { text: req.text! } : { images: images! }),
      today,
      locale,
      currency: household,
    });
  } catch (error) {
    if (error instanceof AiUnavailable) throw new SpendingError('unavailable', 'ai-failed');
    throw error;
  }
  await chargeAi(
    deps.db,
    now,
    req.kind === 'text' ? AI_COST_VND.text : AI_COST_VND.image * (images?.length ?? 1),
  );
  const grid: Grid = [
    AI_HEADER,
    ...rows
      .slice(0, importLimits.rowsMax)
      .map((r) => [
        r.date ?? '',
        r.category.slice(0, importLimits.cellMax),
        r.note.slice(0, importLimits.cellMax),
        r.amount == null ? '' : aiAmount(r.amount),
        r.payer.slice(0, importLimits.cellMax),
        r.currency ?? '',
      ]),
  ];
  if (grid.length === 1) throw new SpendingError('invalid-argument', 'empty');
  await deps.store.write(path, Buffer.from(JSON.stringify(grid), 'utf8'), 'application/json');
  return grid;
}

/** The importer's language: their most recently used device, else Vietnamese. */
async function localeOf(db: Firestore, uid: string): Promise<Locale> {
  const devices = await db.collection(`users/${uid}/devices`).get();
  const at = (d: DocumentSnapshot) =>
    (d.get('updatedAt') as Timestamp | undefined)?.toMillis?.() ?? 0;
  const latest = devices.docs.filter((d) => !d.get('signedOutAt')).sort((a, b) => at(b) - at(a))[0];
  return latest?.get('language') === 'en' ? 'en' : 'vi';
}

/** `create()` that treats "already exists" (a concurrent call, a retry) as done. */
async function createOnce(ref: DocumentReference, data: Record<string, unknown>): Promise<boolean> {
  try {
    await ref.create(data);
    return true;
  } catch (error) {
    if ((error as { code?: number }).code === 6) return false;
    throw error;
  }
}

const emptyCounts: ImportCounts = { rows: 0, ready: 0, duplicates: 0, income: 0, errors: 0 };

/**
 * `analyzeSpendingImport`: reads the source (and, the first time for text / photos, asks the AI),
 * finds the columns or uses the ones given, reads the rows and writes the preview (`ready`).
 */
export async function analyzeSpendingImport(
  deps: ImportDeps,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ status: 'ready' }> {
  const parsed = analyzeImportRequestSchema.safeParse(data);
  if (!parsed.success) throw new SpendingError('invalid-argument', 'malformed');
  const req = parsed.data;
  const { db } = deps;
  const { baby } = await requireParent(db, req.babyId, uid, now);
  const ref = db.doc(`babies/${req.babyId}/spendingImports/${req.importId}`);

  const current = await ref.get();
  const status = current.get('status') as ImportStatus | undefined;
  const reanalysable =
    !current.exists ||
    status === 'analyzing' ||
    status === 'ready' ||
    (status === 'failed' && ANALYSIS_FAILURES.has(current.get('failure') as string));
  if (!reanalysable) throw new SpendingError('failed-precondition', 'wrong-state');
  // The grid lives under whoever started the import.
  const owner = (current.get('createdBy') as string | undefined) ?? uid;
  const createdAt = current.exists ? (current.get('createdAt') as Timestamp).toDate() : now;
  const fileName = req.fileName ?? (current.get('fileName') as string | null | undefined) ?? null;
  const base = {
    kind: req.kind,
    fileName,
    createdBy: owner,
    createdAt,
    updatedAt: now,
    progress: 0,
    imported: 0,
    issues: [],
    failure: null,
    finishedAt: null,
    undoUntil: null,
  };
  if (!current.exists) {
    await createOnce(ref, {
      ...base,
      status: 'analyzing',
      preset: null,
      columns: [],
      mapping: { firstRow: 0, date: null, amount: null, note: [], category: null, payer: null },
      options: { dateOrder: 'dmy', rows: 'all', skipDuplicates: true },
      mixedSigns: false,
      ambiguousDates: false,
      counts: emptyCounts,
      preview: [],
      skipped: [],
      total: { amount: 0, from: null, to: null },
      categories: [],
      payers: [],
    });
  }

  const today = localDateIn(zoneOf(baby), now);
  const familyId = baby.get('familyId') as string;
  const household = await householdCurrency(db, familyId);
  let grid: Grid;
  try {
    grid = await loadGrid(
      deps,
      owner,
      req.importId,
      req,
      today,
      await localeOf(db, uid),
      now,
      household,
    );
  } catch (error) {
    const reason =
      error instanceof SpendingError && ANALYSIS_FAILURES.has(error.reason)
        ? error.reason
        : error instanceof SpendingError && error.reason === 'bad-upload'
          ? 'no-upload'
          : 'analyze-failed';
    // A failed reading stays visible (and can be read again); never over a confirmed import.
    await db.runTransaction(async (tx) => {
      const fresh = await tx.get(ref);
      const s = fresh.get('status') as ImportStatus | undefined;
      if (s === 'analyzing' || s === 'ready' || s === 'failed')
        tx.update(ref, { status: 'failed', failure: reason, updatedAt: now });
    });
    throw error;
  }

  const layout = detectLayout(grid);
  const mapping = req.mapping ?? layout.mapping;
  const options = req.options ?? defaultOptions(grid, mapping);
  const [categories, members] = await Promise.all([
    familyCategories(db, familyId),
    activeMembers(db, req.babyId, now),
  ]);
  const rows = await readWithDuplicates(
    db,
    req.babyId,
    req.importId,
    grid,
    mapping,
    options,
    today,
    layout.currency,
    household,
  );
  const { mixedSigns, ambiguousDates } = signsAndDates(grid, mapping);
  const summary = summarize(rows, categories, members.map(labelOf));
  const doc = {
    ...base,
    status: 'ready',
    preset: req.kind === 'file' ? layout.preset : null,
    columns: layout.columns,
    mapping,
    options,
    mixedSigns,
    ambiguousDates,
    counts: countRows(rows),
    ...previewOf(rows, household),
    // D-075 #4: the currency of rows that name none, kept for the import itself.
    currency: household,
    categories: summary.categories,
    payers: summary.payers,
  };
  await db.runTransaction(async (tx) => {
    const fresh = await tx.get(ref);
    const s = fresh.get('status') as ImportStatus | undefined;
    // Confirmed (or undone) in the meantime: the reading is no longer needed.
    if (s !== 'analyzing' && s !== 'ready' && s !== 'failed')
      throw new SpendingError('failed-precondition', 'wrong-state');
    tx.set(ref, doc);
  });
  return { status: 'ready' };
}

/** `confirmSpendingImport`: the reading and the choices are kept; the trigger imports. */
export async function confirmSpendingImport(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ status: 'queued' }> {
  const parsed = confirmImportRequestSchema.safeParse(data);
  if (!parsed.success) throw new SpendingError('invalid-argument', 'malformed');
  const req = parsed.data;
  const { baby } = await requireParent(db, req.babyId, uid, now);
  const familyId = baby.get('familyId') as string;
  const categories = await familyCategories(db, familyId);
  const known = new Set(categories.map((c) => c.id));
  const takenNames = new Set(categories.flatMap(namesOf));
  const newNames = new Set<string>();
  for (const choice of Object.values(req.categories)) {
    if (choice.kind === 'existing') {
      if (!known.has(choice.id)) throw new SpendingError('not-found', 'category-not-found');
    } else {
      const key = headerKey(choice.name);
      if (!key) throw new SpendingError('invalid-argument', 'malformed');
      if (!takenNames.has(key)) newNames.add(key);
    }
  }
  const custom = categories.filter((c) => !c.builtIn).length;
  if (custom + newNames.size > spendingLimits.customCategoriesMax)
    throw new SpendingError('failed-precondition', 'too-many-categories');
  const members = new Set((await activeMembers(db, req.babyId, now)).map((m) => m.id));
  for (const payer of Object.values(req.payers)) {
    if (payer != null && !members.has(payer))
      throw new SpendingError('not-found', 'payer-not-found');
  }

  const ref = db.doc(`babies/${req.babyId}/spendingImports/${req.importId}`);
  await db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    if (!doc.exists) throw new SpendingError('not-found', 'not-found');
    if (doc.get('status') !== 'ready')
      throw new SpendingError('failed-precondition', 'wrong-state');
    tx.update(ref, {
      status: 'queued',
      mapping: req.mapping,
      options: req.options,
      choices: { categories: req.categories, payers: req.payers },
      confirmedBy: uid,
      progress: 0,
      updatedAt: now,
    });
  });
  return { status: 'queued' };
}

/** Creates the confirmed new categories (once; one with the same name is reused). */
async function createCategories(
  db: Firestore,
  familyId: string,
  importId: string,
  importer: string,
  choices: Record<string, CategoryChoice>,
  used: Set<string>,
  now: Date,
): Promise<Map<string, string>> {
  const out = new Map<string, string>();
  const categories = await familyCategories(db, familyId);
  const byName = new Map<string, string>();
  for (const c of categories) for (const n of namesOf(c)) if (!byName.has(n)) byName.set(n, c.id);
  let custom = categories.filter((c) => !c.builtIn).length;
  let order = Math.max(
    builtInCategories.length - 1,
    ...(await db.collection(`families/${familyId}/spendingCategories`).get()).docs.map(
      (d) => (d.get('order') as number | undefined) ?? 0,
    ),
  );
  for (const [key, choice] of Object.entries(choices)) {
    if (choice.kind !== 'new' || !used.has(key)) continue;
    const name = choice.name.trim().slice(0, spendingLimits.categoryNameMax);
    const folded = headerKey(name);
    const existing = byName.get(folded);
    if (existing) {
      out.set(key, existing);
      continue;
    }
    const id = importedCategoryId(importId, folded);
    const ref = db.doc(`families/${familyId}/spendingCategories/${id}`);
    const snap = await ref.get();
    if (!snap.exists) {
      if (custom >= spendingLimits.customCategoriesMax) {
        out.set(key, otherCategoryId);
        continue;
      }
      order = Math.min(1000, order + 1);
      await createOnce(ref, {
        name,
        icon: 'grid',
        tint: categoryTints[custom % categoryTints.length],
        order,
        hidden: false,
        builtIn: false,
        updatedAt: now,
        updatedBy: importer,
      });
      custom += 1;
    }
    byName.set(folded, id);
    out.set(key, id);
  }
  return out;
}

/** Pushes and mails the importer (counts only, no names or amounts, R-120). */
async function notifyImporter(
  db: Firestore,
  notify: NotifyDeps,
  babyId: string,
  importId: string,
  importer: string,
  result: { ok: true; counts: ImportCounts; imported: number } | { ok: false },
  now: Date,
): Promise<void> {
  const locale = await localeOf(db, importer);
  const email = await notify.emailOf(importer);
  if (email) {
    const mailData = result.ok
      ? {
          added: result.imported,
          duplicates: result.counts.duplicates,
          errors: result.counts.errors,
        }
      : {};
    // One mail per import and outcome (a re-run never mails twice).
    await createOnce(db.doc(`mail/spimport_${importId}_${result.ok ? 'done' : 'failed'}`), {
      to: email,
      template: result.ok ? 'spendingImportDone' : 'spendingImportFailed',
      locale,
      data: mailData,
      unsubscribeToken: randomBytes(24).toString('base64url'),
      status: 'queued',
      attempts: 0,
      createdAt: now,
    });
  }
  await pushUsers(db, notify.sender, [importer], (language) => {
    const lang: Locale = language.startsWith('en') ? 'en' : 'vi';
    const copy = result.ok
      ? {
          title: lang === 'vi' ? 'Đã nhập xong chi tiêu' : 'Your spending import is done',
          body: importSummary(
            lang,
            result.imported,
            result.counts.duplicates,
            result.counts.errors,
          ),
        }
      : {
          title: lang === 'vi' ? 'Chưa nhập được chi tiêu' : 'Your spending import didn’t finish',
          body: lang === 'vi' ? 'Mở app để thử lại.' : 'Open the app to try again.',
        };
    return {
      ...copy,
      data: { kind: 'spending', reason: 'import', babyId, importId, route: importRoute(importId) },
      apns: { collapseId: `sp-im-${importId}`, threadId: `sp-${babyId}` },
    };
  });
}

/**
 * The trigger: when an import becomes `queued`, claims it (`importing`), creates the new
 * categories, reads the grid again and writes the expenses in batches (existing ids skipped, so a
 * re-run never doubles), then `done` (or `failed`) and tells the importer.
 */
export async function runSpendingImport(
  deps: ImportDeps & NotifyDeps,
  babyId: string,
  importId: string,
  now: Date,
): Promise<{ ran: boolean; imported: number; failure: string | null }> {
  const { db } = deps;
  const ref = db.doc(`babies/${babyId}/spendingImports/${importId}`);
  const claimed = await db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    if (doc.get('status') !== 'queued') return null;
    tx.update(ref, { status: 'importing', progress: 0, updatedAt: now });
    return doc;
  });
  if (!claimed) return { ran: false, imported: 0, failure: null };
  const importer =
    (claimed.get('confirmedBy') as string | undefined) ?? (claimed.get('createdBy') as string);
  const owner = claimed.get('createdBy') as string;
  let imported = 0;
  try {
    const member = await db.doc(`babies/${babyId}/members/${importer}`).get();
    if (!isActiveMember(member, now) || member.get('role') !== 'coParent')
      throw new SpendingError('permission-denied', 'not-co-parent');
    const baby = await db.doc(`babies/${babyId}`).get();
    if (!babyActive(baby)) throw new SpendingError('failed-precondition', 'baby-closed');
    const familyId = baby.get('familyId') as string;
    const mapping = claimed.get('mapping') as ImportMapping;
    const options = claimed.get('options') as ImportOptions;
    const choices = (claimed.get('choices') ?? { categories: {}, payers: {} }) as {
      categories: Record<string, CategoryChoice>;
      payers: Record<string, string | null>;
    };

    const size = await deps.store.size(gridPath(owner, importId));
    if (size == null) throw new SpendingError('failed-precondition', 'no-upload');
    if (size > importLimits.gridBytesMax) throw new SpendingError('invalid-argument', 'too-big');
    const grid = parseGrid(
      JSON.parse((await deps.store.read(gridPath(owner, importId))).toString()),
    );
    const layout = detectLayout(grid);
    const today = localDateIn(zoneOf(baby), now);
    const rows = await readWithDuplicates(
      db,
      babyId,
      importId,
      grid,
      mapping,
      options,
      today,
      layout.currency,
      currencyOfDoc(claimed.get('currency')),
    );
    const counts = countRows(rows);
    await ref.update({ counts, updatedAt: now });

    const categoryIds = await createCategories(
      db,
      familyId,
      importId,
      importer,
      choices.categories,
      new Set(rows.filter((r) => r.issue == null).map((r) => sourceKey(r.category))),
      now,
    );
    const known = new Set((await familyCategories(db, familyId)).map((c) => c.id));
    const categoryOf = (name: string) => {
      const key = sourceKey(name);
      const choice = choices.categories[key];
      const id =
        choice?.kind === 'existing'
          ? choice.id
          : choice?.kind === 'new'
            ? categoryIds.get(key)
            : null;
      return id && known.has(id) ? id : otherCategoryId;
    };
    const members = new Map((await activeMembers(db, babyId, now)).map((m) => [m.id, m]));
    const payerOf = (name: string) => {
      const uid = choices.payers[payerKey(name)];
      const m = uid ? members.get(uid) : undefined;
      return m ? { uid: m.id, ...authorOf(m) } : null;
    };
    const author = authorOf(member);

    const ready = rows.filter((r) => r.issue == null);
    for (let i = 0; i < ready.length; i += BATCH_MAX) {
      const chunk = ready.slice(i, i + BATCH_MAX);
      const refs = chunk.map((r) =>
        db.doc(`babies/${babyId}/expenses/${importedExpenseId(importId, r.row)}`),
      );
      const snaps = await db.getAll(...refs);
      const batch = db.batch();
      let writes = 0;
      chunk.forEach((r, j) => {
        if (snaps[j]!.exists) return;
        batch.create(refs[j]!, {
          amount: r.amount,
          currency: r.currency ?? 'VND',
          categoryId: categoryOf(r.category),
          note: r.note,
          spentOn: r.spentOn,
          payer: payerOf(r.payer),
          receiptPath: null,
          source: 'import',
          sourceRef: importId,
          createdBy: importer,
          author,
          createdAt: now,
          updatedAt: now,
          updatedBy: importer,
          deleted: false,
          deletedAt: null,
          deletedBy: null,
        });
        writes += 1;
      });
      if (writes > 0) await batch.commit();
      imported += chunk.length;
      await ref.update({
        progress: Math.floor((imported / ready.length) * 100),
        imported,
        updatedAt: now,
      });
    }

    const issues = rows
      .filter((r) => r.issue != null)
      .slice(0, importLimits.issuesKept)
      .map((r) => ({ row: r.row, issue: r.issue! }));
    await ref.update({
      status: 'done',
      progress: 100,
      imported,
      counts,
      issues,
      failure: null,
      finishedAt: now,
      undoUntil: new Date(now.getTime() + importLimits.undoDays * DAY_MS),
      updatedAt: now,
    });
    await notifyImporter(db, deps, babyId, importId, importer, { ok: true, counts, imported }, now);
    return { ran: true, imported, failure: null };
  } catch (error) {
    const failure = error instanceof SpendingError ? error.reason : 'import-failed';
    await ref.update({
      status: 'failed',
      failure,
      imported,
      finishedAt: now,
      // What was written can still be undone.
      undoUntil: imported > 0 ? new Date(now.getTime() + importLimits.undoDays * DAY_MS) : null,
      updatedAt: now,
    });
    await notifyImporter(db, deps, babyId, importId, importer, { ok: false }, now);
    return { ran: true, imported, failure };
  }
}

/**
 * `undoSpendingImport`: soft-deletes every expense of the import (edited ones too) within
 * [importLimits.undoDays] days. Re-running finishes a partial undo.
 */
/** "Xem tất cả" (owner, 2026-10-12): one page of [importLimits.pageRows] rows to import. */
export async function importPage(
  deps: Pick<ImportDeps, 'db' | 'store'>,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ rows: ReadRow[]; total: number; page: number; pages: number }> {
  const parsed = importPageRequestSchema.safeParse(data);
  if (!parsed.success) throw new SpendingError('invalid-argument', 'malformed');
  const { babyId, importId, page } = parsed.data;
  const { baby } = await requireParent(deps.db, babyId, uid, now);
  const doc = await deps.db.doc(`babies/${babyId}/spendingImports/${importId}`).get();
  if (!doc.exists) throw new SpendingError('not-found', 'not-found');
  if (doc.get('status') !== 'ready') throw new SpendingError('failed-precondition', 'wrong-state');
  const owner = doc.get('createdBy') as string;
  const size = await deps.store.size(gridPath(owner, importId));
  if (size == null) throw new SpendingError('failed-precondition', 'no-upload');
  if (size > importLimits.gridBytesMax) throw new SpendingError('invalid-argument', 'too-big');
  const grid = parseGrid(JSON.parse((await deps.store.read(gridPath(owner, importId))).toString()));
  const rows = (
    await readWithDuplicates(
      deps.db,
      babyId,
      importId,
      grid,
      doc.get('mapping') as ImportMapping,
      doc.get('options') as ImportOptions,
      localDateIn(zoneOf(baby), now),
      detectLayout(grid).currency,
      currencyOfDoc(doc.get('currency')),
    )
  ).filter((r) => r.issue == null);
  const pages = Math.max(1, Math.ceil(rows.length / importLimits.pageRows));
  const at = Math.min(page, pages - 1);
  return {
    rows: rows.slice(at * importLimits.pageRows, (at + 1) * importLimits.pageRows),
    total: rows.length,
    page: at,
    pages,
  };
}

export async function undoSpendingImport(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ removed: number }> {
  const parsed = undoImportRequestSchema.safeParse(data);
  if (!parsed.success) throw new SpendingError('invalid-argument', 'malformed');
  const { babyId, importId } = parsed.data;
  await requireParent(db, babyId, uid, now);
  const ref = db.doc(`babies/${babyId}/spendingImports/${importId}`);
  const doc = await ref.get();
  if (!doc.exists) throw new SpendingError('not-found', 'not-found');
  const status = doc.get('status') as ImportStatus;
  const until = (doc.get('undoUntil') as Timestamp | null | undefined)?.toDate();
  if ((status !== 'done' && status !== 'failed') || !until)
    throw new SpendingError('failed-precondition', 'wrong-state');
  if (now >= until) throw new SpendingError('failed-precondition', 'undo-expired');

  const expenses = await db
    .collection(`babies/${babyId}/expenses`)
    .where('sourceRef', '==', importId)
    .where('source', '==', 'import')
    .get();
  const live = expenses.docs.filter((d) => d.get('deleted') !== true);
  for (let i = 0; i < live.length; i += BATCH_MAX) {
    const batch = db.batch();
    for (const d of live.slice(i, i + BATCH_MAX)) {
      batch.update(d.ref, {
        deleted: true,
        deletedAt: now,
        deletedBy: uid,
        updatedAt: now,
        updatedBy: uid,
      });
    }
    await batch.commit();
  }
  await ref.update({ status: 'undone', undoneBy: uid, updatedAt: now });
  return { removed: live.length };
}

/**
 * Daily: deletes uploaded grids and photos older than [importLimits.keepFileDays], and marks
 * imports left waiting for more than [STUCK_DAYS] as failed ("expired", no mail). Bounded per run;
 * the next run continues.
 */
export async function cleanupSpendingImports(
  db: Firestore,
  store: ImportStore,
  now: Date,
): Promise<{ files: number; expired: number }> {
  const old = await store.listOlderThan(
    'imports/',
    new Date(now.getTime() - importLimits.keepFileDays * DAY_MS),
    2000,
  );
  for (const path of old) await store.delete(path);
  const stuck = await db
    .collectionGroup('spendingImports')
    .where('status', 'in', ['analyzing', 'ready', 'queued', 'importing'])
    .where('updatedAt', '<', new Date(now.getTime() - STUCK_DAYS * DAY_MS))
    .limit(300)
    .get();
  let expired = 0;
  for (const doc of stuck.docs) {
    if (doc.ref.parent.parent?.parent.id !== 'babies') continue;
    const imported = (doc.get('imported') as number | undefined) ?? 0;
    await doc.ref.update({
      status: 'failed',
      failure: 'expired',
      finishedAt: now,
      undoUntil: imported > 0 ? new Date(now.getTime() + importLimits.undoDays * DAY_MS) : null,
      updatedAt: now,
    });
    expired += 1;
  }
  return { files: old.length, expired };
}
