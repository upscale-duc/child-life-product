import { describe, expect, it } from 'vitest';
import type { ImportMapping, ImportOptions } from '@child-life/contracts';
import { AiUnavailable, openAiExpenseExtractor } from '../src/ai.js';
import { importSummary, renderAccountEmail } from '../src/mail-templates.js';
import {
  columnLetter,
  countRows,
  defaultOptions,
  detectLayout,
  duplicateKey,
  importedExpenseId,
  parseGrid,
  readRows,
  signsAndDates,
  suggestCategory,
  suggestPayer,
  summarize,
  withBuiltIns,
  type FamilyCategory,
  type Grid,
  type MemberLabel,
} from '../src/spending-import.js';
import { SpendingError } from '../src/spending.js';

// Nhập chi tiêu (D-060, P-144): reading grids the app uploads. Sample data only.
const today = '2026-10-12';
const read = (
  grid: Grid,
  mapping: ImportMapping,
  options: ImportOptions,
  existing = new Set<string>(),
) => readRows(grid, mapping, options, { today, existing, currency: detectLayout(grid).currency });

const reason = (f: () => unknown) => {
  try {
    f();
  } catch (e) {
    if (e instanceof SpendingError) return e.reason;
    throw e;
  }
  return null;
};

describe('the uploaded grid', () => {
  it('keeps strings, drops trailing empty rows and enforces the limits', () => {
    expect(parseGrid([['a', 1, null], ['', ' '], []])).toEqual([['a', '1', '']]);
    expect(reason(() => parseGrid('x'))).toBe('bad-upload');
    expect(reason(() => parseGrid([[''], []]))).toBe('empty');
    expect(reason(() => parseGrid([Array(41).fill('x')]))).toBe('too-big');
    expect(reason(() => parseGrid([['x'.repeat(301)]]))).toBe('too-big');
    expect(reason(() => parseGrid(Array.from({ length: 5001 }, () => ['1'])))).toBe('too-big');
  });

  it('names columns without a header by letter', () => {
    expect([0, 25, 26, 39].map(columnLetter)).toEqual(['A', 'Z', 'AA', 'AN']);
  });
});

describe('finding the columns', () => {
  it('Money Lover CSV', () => {
    const grid: Grid = [
      ['Id', 'Date', 'Category', 'Amount', 'Currency', 'Note', 'Wallet'],
      ['1', '12/10/2026', 'Milk', '-285,000', 'VND', 'Formula x2', 'Cash'],
      ['2', '11/10/2026', 'Salary', '20,000,000', 'VND', '', 'Bank'],
    ];
    const l = detectLayout(grid);
    expect(l.preset).toBe('Money Lover');
    expect(l.headerRow).toBe(0);
    expect(l.mapping).toEqual({
      firstRow: 1,
      date: 1,
      amount: 3,
      note: [5],
      category: 2,
      payer: null,
    });
    expect(l.currency).toBe(4);
    expect(l.columns[0]).toBe('Id');
    expect(defaultOptions(grid, l.mapping)).toEqual({
      dateOrder: 'dmy',
      rows: 'negative',
      skipDuplicates: true,
    });
  });

  it('MISA Money Keeper', () => {
    const grid: Grid = [
      ['Ngày', 'Số tiền', 'Hạng mục', 'Diễn giải', 'Tài khoản', 'Loại'],
      ['12/10/2026', '120.000', 'Ăn uống', 'Bỉm', 'Ví', 'Chi'],
    ];
    const l = detectLayout(grid);
    expect(l.preset).toBe('MISA Money Keeper');
    expect(l.mapping).toMatchObject({ date: 0, amount: 1, category: 2, note: [3], payer: null });
  });

  it('Child Life\'s own CSV in vi and en ("Ghi bởi" is not who paid)', () => {
    const vi = detectLayout([
      ['﻿Ngày', 'Danh mục', 'Nội dung', 'Số tiền', 'Ai trả', 'Ghi bởi'],
      ['2026-10-12', 'Sữa & ăn dặm', 'Sữa', '1020000', 'Mẹ', 'Mẹ'],
    ]);
    expect(vi.preset).toBe('Child Life');
    expect(vi.mapping).toEqual({
      firstRow: 1,
      date: 0,
      amount: 3,
      note: [2],
      category: 1,
      payer: 4,
    });
    const en = detectLayout([
      ['Date', 'Category', 'Description', 'Amount', 'Who paid', 'Recorded by'],
      ['2026-10-12', 'Milk & solids', 'Milk', '1020000', 'Mum', 'Mum'],
    ]);
    expect(en.preset).toBe('Child Life');
    expect(en.mapping).toEqual({
      firstRow: 1,
      date: 0,
      amount: 3,
      note: [2],
      category: 1,
      payer: 4,
    });
  });

  it('a title row before the header, partial names and two note columns', () => {
    const l = detectLayout([
      ['Chi tiêu của bé tháng 10'],
      [],
      ['STT', 'Ngày giao dịch', 'Ghi chú', 'Người nhận', 'Số tiền (VNĐ)', 'Nhóm', 'Người trả'],
      ['1', '01/10/2026', 'Sữa', 'Shop A', '500k', 'Sữa', 'Bố'],
    ]);
    expect(l.headerRow).toBe(2);
    expect(l.preset).toBeNull();
    expect(l.mapping).toEqual({
      firstRow: 3,
      date: 1,
      amount: 4,
      note: [2, 3],
      category: 5,
      payer: 6,
    });
  });

  it('without a header: days, amounts (not row numbers) and the longest text', () => {
    const grid: Grid = [
      ['Sổ chi tiêu'],
      ['1', '01/10/2026', 'Sữa', 'Sữa công thức hộp lớn', '1.020.000'],
      ['2', '03/10/2026', 'Tã', 'Bỉm dán size M', '350.000'],
      ['3', '15/10/2026', 'Khám', 'Khám tai mũi họng', '200.000'],
    ];
    const l = detectLayout(grid);
    expect(l.headerRow).toBeNull();
    expect(l.mapping).toEqual({
      firstRow: 1,
      date: 1,
      amount: 4,
      note: [3],
      category: null,
      payer: null,
    });
    expect(l.columns).toEqual(['Cột A', 'Cột B', 'Cột C', 'Cột D', 'Cột E']);
  });

  it('Excel serial days when the column holds nothing else', () => {
    const l = detectLayout([
      ['46307', 'Sữa', '120000'],
      ['46308', 'Tã', '80000'],
    ]);
    expect(l.mapping.date).toBe(0);
    expect(l.mapping.amount).toBe(2);
  });
});

describe('reading rows', () => {
  const mapping: ImportMapping = {
    firstRow: 1,
    date: 0,
    amount: 1,
    note: [2],
    category: 3,
    payer: 4,
  };
  const all: ImportOptions = { dateOrder: 'dmy', rows: 'all', skipDuplicates: true };

  it('reads days, money and text; empty rows are dropped', () => {
    const rows = read(
      [
        ['Ngày', 'Số tiền', 'Nội dung', 'Danh mục', 'Ai trả'],
        ['12/10/2026', '1.020.000 ₫', "'-Sữa   công thức", 'Sữa', 'Mẹ'],
        ['', '', '', '', ''],
        ['13/10/2026', '100.000', 'Ngày mai', '', ''],
        ['', '50k', 'Không ngày', '', ''],
        ['31/02/2026', '50k', 'Sai ngày', '', ''],
        ['01/10/2026', '', 'Không tiền', '', ''],
        ['01/10/2026', 'abc', 'Sai tiền', '', ''],
        ['01/10/2026', '0', 'Không đồng', '', ''],
        ['01/10/2026', '2 tỷ', 'Quá lớn', '', ''],
        ['01/10/2026', '$12.50', 'Đô', '', ''],
      ],
      mapping,
      all,
    );
    expect(rows[0]).toEqual({
      row: 2,
      spentOn: '2026-10-12',
      amount: 1_020_000,
      note: '-Sữa công thức',
      category: 'Sữa',
      payer: 'Mẹ',
      issue: null,
    });
    expect(rows.map((r) => [r.row, r.issue])).toEqual([
      [2, null],
      [4, 'future-date'],
      [5, 'no-date'],
      [6, 'bad-date'],
      [7, 'no-amount'],
      [8, 'bad-amount'],
      [9, 'bad-amount'],
      [10, 'too-large'],
      [11, 'other-currency'],
    ]);
    expect(countRows(rows)).toEqual({ rows: 9, ready: 1, duplicates: 0, income: 0, errors: 8 });
  });

  it('chooses spending by sign when a file mixes them', () => {
    const grid: Grid = [
      ['Date', 'Amount', 'Note'],
      ['01/10/2026', '-285,000', 'Milk'],
      ['02/10/2026', '20,000,000', 'Salary'],
      ['03/10/2026', '(50,000)', 'Wipes'],
    ];
    const m: ImportMapping = {
      firstRow: 1,
      date: 0,
      amount: 1,
      note: [2],
      category: null,
      payer: null,
    };
    expect(signsAndDates(grid, m).mixedSigns).toBe(true);
    const neg = read(grid, m, { ...all, rows: 'negative' });
    expect(neg.map((r) => [r.amount, r.issue])).toEqual([
      [285_000, null],
      [20_000_000, 'income'],
      [50_000, null],
    ]);
    const pos = read(grid, m, { ...all, rows: 'positive' });
    expect(pos.map((r) => r.issue)).toEqual(['income', null, 'income']);
    expect(read(grid, m, all).every((r) => r.issue == null)).toBe(true);
    expect(countRows(neg)).toMatchObject({ ready: 2, income: 1, errors: 0 });
  });

  it('skips rows whose currency is not VND', () => {
    const grid: Grid = [
      ['Date', 'Category', 'Amount', 'Currency', 'Note'],
      ['01/10/2026', 'Milk', '-100000', 'VND', 'a'],
      ['01/10/2026', 'Milk', '-12', 'USD', 'b'],
      ['01/10/2026', 'Milk', '-100000', '₫', 'c'],
    ];
    const l = detectLayout(grid);
    expect(read(grid, l.mapping, defaultOptions(grid, l.mapping)).map((r) => r.issue)).toEqual([
      null,
      'other-currency',
      null,
    ]);
  });

  it('reads 03/04 by the chosen order and flags ambiguity', () => {
    const grid: Grid = [
      ['Ngày', 'Số tiền'],
      ['03/04/2026', '100000'],
      ['05/06/2026', '100000'],
    ];
    const m: ImportMapping = {
      firstRow: 1,
      date: 0,
      amount: 1,
      note: [],
      category: null,
      payer: null,
    };
    expect(signsAndDates(grid, m).ambiguousDates).toBe(true);
    expect(read(grid, m, all)[0]!.spentOn).toBe('2026-04-03');
    expect(read(grid, m, { ...all, dateOrder: 'mdy' })[0]!.spentOn).toBe('2026-03-04');
    expect(signsAndDates([...grid, ['13/04/2026', '1']], m).ambiguousDates).toBe(false);
    expect(defaultOptions([['04/25/2026', '1']], { ...m, firstRow: 0 }).dateOrder).toBe('mdy');
  });

  it('skips what is already in Chi tiêu (same day, amount and folded description)', () => {
    const grid: Grid = [
      ['Ngày', 'Số tiền', 'Nội dung'],
      ['01/10/2026', '100.000', 'Sữa Công thức'],
      ['01/10/2026', '100.000', 'Tã'],
    ];
    const m: ImportMapping = {
      firstRow: 1,
      date: 0,
      amount: 1,
      note: [2],
      category: null,
      payer: null,
    };
    const existing = new Set([duplicateKey('2026-10-01', 100_000, 'sua cong thuc')]);
    expect(read(grid, m, all, existing).map((r) => r.issue)).toEqual(['duplicate', null]);
    expect(read(grid, m, { ...all, skipDuplicates: false }, existing).map((r) => r.issue)).toEqual([
      null,
      null,
    ]);
  });

  it('joins note columns and keeps 80 characters', () => {
    const grid: Grid = [['01/10/2026', '1000', 'x'.repeat(70), 'Shop ABC xyz']];
    const m: ImportMapping = {
      firstRow: 0,
      date: 0,
      amount: 1,
      note: [2, 3],
      category: null,
      payer: null,
    };
    const [r] = read(grid, m, all);
    expect(r!.note).toHaveLength(80);
    expect(r!.note.startsWith(`${'x'.repeat(70)} · Shop`)).toBe(true);
  });

  it('gives each row a stable expense id', () => {
    const a = importedExpenseId(`im_${'a'.repeat(32)}`, 2);
    expect(a).toMatch(/^x_[a-f0-9]{32}$/);
    expect(importedExpenseId(`im_${'a'.repeat(32)}`, 2)).toBe(a);
    expect(importedExpenseId(`im_${'a'.repeat(32)}`, 3)).not.toBe(a);
  });
});

describe('matching categories and payers', () => {
  const categories: FamilyCategory[] = withBuiltIns([
    { id: 'c_0123456789abcdef0123', name: 'Đồ chơi', builtIn: false, hidden: false },
    { id: 'c_clothes', name: 'Áo quần bé', builtIn: true, hidden: false },
    { id: 'c_childcare', name: null, builtIn: true, hidden: true },
  ]);

  it('by name (custom, built-in vi / en, renamed), then by synonym', () => {
    expect(suggestCategory('đồ  CHƠI', categories)).toEqual({
      kind: 'existing',
      id: 'c_0123456789abcdef0123',
    });
    expect(suggestCategory('Sữa & ăn dặm', categories)).toEqual({ kind: 'existing', id: 'c_milk' });
    expect(suggestCategory('Diapers & hygiene', categories)).toEqual({
      kind: 'existing',
      id: 'c_diaper',
    });
    expect(suggestCategory('Áo quần bé', categories)).toEqual({
      kind: 'existing',
      id: 'c_clothes',
    });
    expect(suggestCategory('Quần áo', categories)).toEqual({ kind: 'existing', id: 'c_clothes' });
    expect(suggestCategory('Khác', categories)).toEqual({ kind: 'existing', id: 'c_other' });
    expect(suggestCategory('Bỉm sữa', categories)).toEqual({ kind: 'existing', id: 'c_milk' });
    expect(suggestCategory('Bỉm', categories)).toEqual({ kind: 'existing', id: 'c_diaper' });
    expect(suggestCategory('Thuốc hạ sốt', categories)).toEqual({
      kind: 'existing',
      id: 'c_health',
    });
    expect(suggestCategory('Formula', categories)).toEqual({ kind: 'existing', id: 'c_milk' });
    // Hidden categories are not suggested.
    expect(suggestCategory('Học phí', categories)).toBeNull();
    expect(suggestCategory('Du lịch', categories)).toBeNull();
    expect(suggestCategory('', categories)).toBeNull();
  });

  it('payers by name, own label or relation word ("Bà" is not "Ba")', () => {
    const members: MemberLabel[] = [
      { uid: 'mom', displayName: 'Mai', relation: 'mother', relationCustom: null },
      { uid: 'dad', displayName: 'Nam', relation: 'father', relationCustom: null },
      { uid: 'gma', displayName: 'Hoa', relation: 'grandmother', relationCustom: null },
      { uid: 'aunt', displayName: 'Lan', relation: 'other', relationCustom: 'Dì Lan' },
    ];
    expect(suggestPayer('mai', members)).toBe('mom');
    expect(suggestPayer('Mẹ', members)).toBe('mom');
    expect(suggestPayer('Mum', members)).toBe('mom');
    expect(suggestPayer('Ba', members)).toBe('dad');
    expect(suggestPayer('Bố', members)).toBe('dad');
    expect(suggestPayer('Bà', members)).toBe('gma');
    expect(suggestPayer('bà ngoại', members)).toBe('gma');
    expect(suggestPayer('Dì Lan', members)).toBe('aunt');
    expect(suggestPayer('Ông', members)).toBeNull();
    expect(suggestPayer('', members)).toBeNull();
  });

  it('summarises the names of importable rows with folded keys', () => {
    const rows = read(
      [
        ['Ngày', 'Số tiền', 'Danh mục', 'Ai trả'],
        ['01/10/2026', '1000', 'Sữa', 'Mẹ'],
        ['02/10/2026', '1000', 'SỮA', 'mẹ'],
        ['03/10/2026', '', 'Tã', 'Bố'],
      ],
      { firstRow: 1, date: 0, amount: 1, note: [], category: 2, payer: 3 },
      { dateOrder: 'dmy', rows: 'all', skipDuplicates: true },
    );
    const s = summarize(rows, categories, [
      { uid: 'mom', displayName: 'Mai', relation: 'mother', relationCustom: null },
    ]);
    expect(s.categories).toEqual([
      { key: 'sua', name: 'Sữa', rows: 2, suggested: { kind: 'existing', id: 'c_milk' } },
    ]);
    expect(s.payers).toEqual([{ key: 'mẹ', name: 'Mẹ', rows: 2, suggested: 'mom' }]);
  });
});

describe('the result copy (no names, amounts or descriptions)', () => {
  it('counts what was added and skipped', () => {
    expect(importSummary('vi', 210, 3, 1)).toBe(
      'Đã thêm 210 khoản vào Chi tiêu. Bỏ qua 3 khoản trùng và 1 dòng lỗi.',
    );
    expect(importSummary('vi', 5, 0, 0)).toBe('Đã thêm 5 khoản vào Chi tiêu.');
    expect(importSummary('en', 1, 2, 0)).toBe('Added 1 expense to Spending. Skipped 2 duplicates.');
    const done = renderAccountEmail(
      'spendingImportDone',
      'vi',
      { added: 210, duplicates: 3, errors: 1 },
      { adminOrigin: 'https://admin.childlife.app', webOrigin: 'https://dev.childlife.app' },
    );
    expect(done.subject).toBe('Đã nhập xong chi tiêu');
    expect(done.text).toContain(
      'Đã thêm 210 khoản vào Chi tiêu. Bỏ qua 3 khoản trùng và 1 dòng lỗi.',
    );
    expect(done.text).toContain('Xem kết quả: https://dev.childlife.app');
    const failed = renderAccountEmail('spendingImportFailed', 'en', {});
    expect(failed.subject).toBe('Your spending import didn’t finish');
  });
});

describe('the AI reading (D-003 adapter)', () => {
  it('sends only the text or photos, asks for no retention and checks the reply', async () => {
    const calls: { url: string; body: Record<string, unknown> }[] = [];
    const fetchImpl = (async (url: string, init: { body: string }) => {
      calls.push({ url, body: JSON.parse(init.body) as Record<string, unknown> });
      return new Response(
        JSON.stringify({
          choices: [
            {
              message: {
                content: JSON.stringify({
                  rows: [
                    {
                      date: '2026-10-01',
                      amount: 120000,
                      note: 'Sữa',
                      category: 'Sữa',
                      payer: 'Mẹ',
                    },
                    { date: 'hôm qua', amount: null, note: 'Tã', category: '', payer: '' },
                  ],
                }),
              },
            },
          ],
        }),
      );
    }) as unknown as typeof fetch;
    const ai = openAiExpenseExtractor('sk-test', 'gpt-4.1-mini', fetchImpl);
    const rows = await ai.extractExpenses({ text: '1/10 sữa 120k', today, locale: 'vi' });
    expect(rows).toEqual([
      { date: '2026-10-01', amount: 120000, note: 'Sữa', category: 'Sữa', payer: 'Mẹ' },
      { date: null, amount: null, note: 'Tã', category: '', payer: '' },
    ]);
    expect(calls[0]!.body.store).toBe(false);
    const messages = calls[0]!.body.messages as { role: string; content: unknown }[];
    expect(String(messages[0]!.content)).toContain(`Today is ${today}`);
    expect(messages[1]!.content).toEqual([{ type: 'text', text: '1/10 sữa 120k' }]);

    await ai.extractExpenses({ images: [Buffer.from([1, 2, 3])], today, locale: 'en' });
    const photo = (calls[1]!.body.messages as { content: { image_url?: { url: string } }[] }[])[1]!
      .content[0]!;
    expect(photo.image_url!.url).toBe('data:image/jpeg;base64,AQID');
  });

  it('a refusal or a broken reply is "unavailable"', async () => {
    const failing = openAiExpenseExtractor(
      'k',
      'm',
      (async () => new Response('nope', { status: 500 })) as unknown as typeof fetch,
    );
    await expect(
      failing.extractExpenses({ text: 'x', today, locale: 'vi' }),
    ).rejects.toBeInstanceOf(AiUnavailable);
    const broken = openAiExpenseExtractor(
      'k',
      'm',
      (async () =>
        new Response(
          JSON.stringify({ choices: [{ message: { content: '{"rows":1}' } }] }),
        )) as unknown as typeof fetch,
    );
    await expect(broken.extractExpenses({ text: 'x', today, locale: 'vi' })).rejects.toBeInstanceOf(
      AiUnavailable,
    );
  });
});
