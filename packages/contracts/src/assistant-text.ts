import { currencyInfo, toMinorUnits, type ExpenseCurrency } from './spending.js';

/**
 * Child Life Assistant ("Lumi") — deterministic text rules (rework 2026-10-15,
 * docs/assistant/api.md "Rework 2026-10-15"). The model reads a message and PROPOSES; these pure
 * functions decide what the server trusts: money amounts (Vietnamese shorthand "500k", "1tr2",
 * "350.000đ" and other Chi tiêu currencies in minor units), the spending detector that keeps
 * money out of the baby's shared thread (D-075 #2), durations ("9 tiếng", "1 tiếng rưỡi"),
 * "2 tiếng trước", relative dates ("mai", "thứ 6 tuần sau", "20/10"), clock times typed as an
 * answer ("9h tối", "21:30"), small talk ("cảm ơn Lumi"), category hints and medicine reminders.
 * Shared by the server (worker, startTask) and testable without a model. Nothing here logs.
 */

// ---------- Folding ----------

/** Lower case, Vietnamese diacritics removed, đ → d. Same length as the NFC lower-case text. */
export function foldVi(s: string): string {
  return s
    .normalize('NFC')
    .toLocaleLowerCase('vi')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/đ/g, 'd');
}

const lowerVi = (s: string) => s.normalize('NFC').toLocaleLowerCase('vi');

/** Whether [s] carries any Vietnamese diacritic (then unaccented words are taken as written). */
export function hasVietnameseMarks(s: string): boolean {
  return lowerVi(s) !== foldVi(s);
}

// ---------- Numbers ----------

/**
 * "350.000" → 350000, "500,000" → 500000, "1.2" → 1.2, "20.50" → 20.5, "1,5" → 1.5. A separator
 * followed by groups of exactly three digits is a thousands separator; otherwise a decimal one.
 */
export function parseLooseNumber(raw: string): number | null {
  const s = raw.replace(/\s+/g, '');
  if (!/^\d+(?:[.,]\d+)*$/.test(s)) return null;
  const groups = s.split(/[.,]/);
  if (groups.length === 1) return Number(s);
  const seps = s.replace(/\d/g, '');
  const tail = groups.slice(1);
  const thousands =
    tail.every((g) => g.length === 3) && (new Set(seps).size === 1 || tail.length > 1);
  if (thousands && groups.length > 2) return Number(groups.join(''));
  if (thousands && groups[0]!.length <= 3) return Number(groups.join(''));
  if (groups.length === 2) return Number(`${groups[0]}.${groups[1]}`);
  // "1.200,50" / "1,200.50": the last separator is the decimal one.
  const last = Math.max(s.lastIndexOf('.'), s.lastIndexOf(','));
  return Number(`${s.slice(0, last).replace(/[.,]/g, '')}.${s.slice(last + 1)}`);
}

// ---------- Money ----------

export interface MoneyAmount {
  /** The matched words, e.g. "1tr2", "$20", "350.000đ". */
  text: string;
  /** Integer minor units of [currency] (VND đồng, USD cents…). */
  minor: number;
  currency: ExpenseCurrency;
  /** The currency was written (unit, symbol or code) rather than taken from the household. */
  explicitCurrency: boolean;
  /** The amount may not be what was meant (e.g. "hết 500" in VND): review before saving. */
  uncertain: boolean;
  index: number;
}

const NUM = String.raw`\d+(?:[.,]\d+)*`;
const END = String.raw`(?![\p{L}\d])`;

/** Words / symbols / codes that name a Chi tiêu currency (folded text). */
const currencyWords: [RegExp, ExpenseCurrency][] = [
  [/^(?:\$|us\$|usd|dollars?|bucks?)$/, 'USD'],
  [/^(?:€|eur|euros?)$/, 'EUR'],
  [/^(?:£|gbp|pounds?)$/, 'GBP'],
  [/^(?:s\$|sgd)$/, 'SGD'],
  [/^(?:฿|thb|baht)$/, 'THB'],
  [/^(?:¥|jpy|yen)$/, 'JPY'],
  [/^(?:₩|krw|won)$/, 'KRW'],
  [/^(?:a\$|aud)$/, 'AUD'],
  [/^cad$/, 'CAD'],
  [/^nzd$/, 'NZD'],
  [/^(?:nt\$|twd)$/, 'TWD'],
  [/^(?:hk\$|hkd)$/, 'HKD'],
  [/^(?:cny|rmb|nhan dan te)$/, 'CNY'],
  [/^chf$/, 'CHF'],
  [/^(?:myr|ringgit)$/, 'MYR'],
  [/^(?:₫|d|dong|vnd|vnđ)$/, 'VND'],
];
const currencyOf = (w: string): ExpenseCurrency | null =>
  currencyWords.find(([re]) => re.test(w.trim()))?.[1] ?? null;

const SYMBOLS = String.raw`us\$|s\$|a\$|nt\$|hk\$|\$|€|£|฿|¥|₩|₫`;
const CODES = String.raw`usd|eur|gbp|sgd|thb|jpy|krw|aud|cad|nzd|twd|hkd|cny|rmb|chf|myr|vnd`;
const AFTER_WORDS = String.raw`dollars?|bucks?|euros?|pounds?|baht|yen|won|ringgit|nhan dan te|dong|d`;

function vndAmount(text: string, minor: number, index: number): MoneyAmount {
  return {
    text,
    minor: Math.round(minor),
    currency: 'VND',
    explicitCurrency: true,
    uncertain: false,
    index,
  };
}

/**
 * Money amounts written with a unit, a symbol or a currency code, in reading order: "500k",
 * "50 nghìn", "1tr2", "1.2tr", "1 triệu rưỡi", "500.000đ", "500,000 vnd", "$20", "20 USD",
 * "35 dollars", "20 đô", "€15", "15 euros". Bare numbers are not amounts here (see
 * [parseMoney]). The k / nghìn / triệu shorthand is Vietnamese, so always VND.
 */
export function moneyAmountsIn(text: string): MoneyAmount[] {
  const f = foldVi(text);
  const lower = lowerVi(text);
  const out: MoneyAmount[] = [];
  const taken: [number, number][] = [];
  const free = (a: number, b: number) => !taken.some(([x, y]) => a < y && b > x);
  const add = (m: RegExpExecArray, amount: MoneyAmount | null) => {
    if (!amount || amount.minor <= 0 || !free(m.index, m.index + m[0].length)) return;
    taken.push([m.index, m.index + m[0].length]);
    out.push(amount);
  };
  // 1tr2, 1 triệu 2 (end), 1.2tr, 1 triệu rưỡi.
  for (const m of f.matchAll(
    new RegExp(
      String.raw`(?<![\d.,])(${NUM})\s*(tr|trieu)(?:(\d{1,3})|\s+(\d{1,3})(?=\s*(?:$|[,.;!?)])))?(\s*ruoi)?${END}`,
      'gu',
    ),
  )) {
    const base = parseLooseNumber(m[1]!);
    if (base === null) continue;
    const digits = m[3] ?? m[4];
    let v = base * 1_000_000;
    if (digits) v += Number(digits) * 10 ** (6 - digits.length);
    if (m[5]) v += 500_000;
    add(m as RegExpExecArray, vndAmount(m[0].trim(), v, m.index));
  }
  // 500k, 50 nghìn / ngàn, 1 trăm nghìn is left to the model.
  for (const m of f.matchAll(
    new RegExp(String.raw`(?<![\d.,])(${NUM})\s*(k|nghin|ngan)(\s*ruoi)?${END}`, 'gu'),
  )) {
    const base = parseLooseNumber(m[1]!);
    if (base === null) continue;
    add(m as RegExpExecArray, vndAmount(m[0].trim(), base * 1000 + (m[3] ? 500 : 0), m.index));
  }
  // Symbol or code before the number: $20, € 15, USD 20.
  for (const m of f.matchAll(
    new RegExp(String.raw`(?<![\p{L}])(${SYMBOLS}|${CODES})\s*(${NUM})${END}`, 'gu'),
  )) {
    const cur = currencyOf(m[1]!);
    const major = parseLooseNumber(m[2]!);
    if (!cur || major === null) continue;
    add(m as RegExpExecArray, money(m[0].trim(), major, cur, m.index));
  }
  // Number then symbol / code / word: 20$, 20 usd, 35 dollars, 500.000đ, 500,000 vnd, 20 đô (la).
  for (const m of f.matchAll(
    new RegExp(
      String.raw`(?<![\d.,])(${NUM})\s*(${SYMBOLS}|${CODES}|${AFTER_WORDS}|do la|do)${END}`,
      'gu',
    ),
  )) {
    const word = m[2]!;
    let cur: ExpenseCurrency | null;
    if (word === 'do' || word === 'do la') {
      // "đô" (dollar) only as written with its mark: "39 độ" (degrees) is never money.
      const original = lower.slice(m.index, m.index + m[0].length);
      cur = /đô/.test(original) ? 'USD' : null;
    } else if (word === 'd') {
      // "500đ" / "500 đ": the đồng sign as written (a folded "d" from đ only).
      const original = lower.slice(m.index, m.index + m[0].length);
      cur = /đ/.test(original) || /\d\s*d$/.test(m[0]) ? 'VND' : null;
    } else cur = currencyOf(word);
    const major = parseLooseNumber(m[1]!);
    if (!cur || major === null) continue;
    add(m as RegExpExecArray, money(m[0].trim(), major, cur, m.index));
  }
  return out.sort((a, b) => a.index - b.index);
}

function money(text: string, major: number, currency: ExpenseCurrency, index: number): MoneyAmount {
  const exp = currencyInfo[currency].exponent;
  const minor = toMinorUnits(major, currency);
  // A fraction of a minor unit (VND "1.5đ") cannot be what was meant.
  const uncertain = exp === 0 && !Number.isInteger(major);
  return { text, minor, currency, explicitCurrency: true, uncertain, index };
}

/**
 * The amount in [evidence] (the words the model says the amount comes from): a written amount
 * ([moneyAmountsIn]) or a bare number in the household's [fallback] currency ("450,000",
 * "hết 500"). A bare VND number under 1 000 đ ("hết 500") is kept but marked uncertain — it is
 * most likely "500k".
 */
export function parseMoney(evidence: string, fallback: ExpenseCurrency): MoneyAmount | null {
  const written = moneyAmountsIn(evidence);
  if (written.length > 0) return written[0]!;
  const f = foldVi(evidence);
  const m = new RegExp(
    String.raw`(?<![\d.,:])(${NUM})(?![\d.,:]|\s*(?:ml|oz|h|g|gio|phut|p|tieng|thang|tuoi|kg|cm|mg|do|lan|cu|ngay|tuan|%|:))`,
    'u',
  ).exec(f);
  if (!m) return null;
  const major = parseLooseNumber(m[1]!);
  if (major === null || major <= 0) return null;
  const amount = money(m[0], major, fallback, m.index);
  return {
    ...amount,
    explicitCurrency: false,
    uncertain: amount.uncertain || (fallback === 'VND' && major < 1000),
  };
}

// ---------- Spending detector (D-075 #2: money never enters the shared thread) ----------

const spendWordsMarked = [
  'mua',
  'trả tiền',
  'đã trả',
  'trả hết',
  'tiền',
  'chi tiêu',
  'chi phí',
  'đóng tiền',
  'đóng học',
  'học phí',
  'hoá đơn',
  'hóa đơn',
  'thanh toán',
  'chuyển khoản',
  'mua sắm',
];
const spendWordsFolded = [
  'chi tieu',
  'chi phi',
  'hoc phi',
  'hoa don',
  'thanh toan',
  'tra tien',
  'dong tien',
  'chuyen khoan',
];
const spendWordsEn = [
  'spent',
  'spend',
  'spending',
  'paid',
  'pay',
  'paying',
  'bought',
  'buy',
  'buying',
  'purchase',
  'purchased',
  'cost',
  'costs',
  'price',
  'expense',
  'expenses',
  'receipt',
  'bill',
  'fee',
  'fees',
  'tuition',
];

const wordRe = (w: string) =>
  new RegExp(String.raw`(?<![\p{L}\d])${w.replace(/\s+/g, String.raw`\s+`)}(?![\p{L}])`, 'u');

/**
 * Why [text] looks like money (empty when it does not): a written amount (`amount`), a spending
 * word (`keyword`: mua, trả tiền, tiền, chi tiêu, học phí, hoá đơn, spent, paid, bought…). Used
 * at `startTask` so such a message starts as a PRIVATE task and never reaches the baby's shared
 * thread (D-075 #2). Conservative on purpose: a false positive only keeps a message private.
 */
export function spendingSignalsIn(text: string): ('amount' | 'keyword')[] {
  const out: ('amount' | 'keyword')[] = [];
  if (moneyAmountsIn(text).length > 0) out.push('amount');
  const lower = lowerVi(text);
  const f = foldVi(text);
  const marked = hasVietnameseMarks(text);
  const keyword =
    spendWordsMarked.some((w) => wordRe(w).test(lower)) ||
    spendWordsFolded.some((w) => wordRe(w).test(f)) ||
    // Without any diacritic, "mua" is read as "mua" (buy), "het 500" as spending.
    (!marked && (wordRe('mua').test(f) || /(?<![\p{L}])het\s+\d/u.test(f))) ||
    /(?<![\p{L}])hết\s+\d/u.test(lower) ||
    spendWordsEn.some((w) => wordRe(w).test(f));
  if (keyword) out.push('keyword');
  return out;
}

export function looksLikeSpending(text: string): boolean {
  return spendingSignalsIn(text).length > 0;
}

// ---------- Durations ----------

const numberWords: Record<string, number> = {
  mot: 1,
  hai: 2,
  ba: 3,
  bon: 4,
  nam: 5,
  sau: 6,
  bay: 7,
  tam: 8,
  chin: 9,
  muoi: 10,
  an: 1,
  a: 1,
  one: 1,
  two: 2,
  three: 3,
  four: 4,
  five: 5,
  six: 6,
  seven: 7,
  eight: 8,
  nine: 9,
  ten: 10,
};
const numOrWord = String.raw`(\d+(?:[.,]\d+)?|mot|hai|ba|bon|nam|sau|bay|tam|chin|muoi|an|a|one|two|three|four|five|six|seven|eight|nine|ten)`;
const toNum = (s: string) => numberWords[s] ?? Number(s.replace(',', '.'));

export interface DurationMatch {
  minutes: number;
  text: string;
  index: number;
}

/**
 * Durations written in [text], in reading order: "9 tiếng", "1 tiếng rưỡi", "1 tiếng 15 phút",
 * "nửa tiếng", "15 phút", "15p", "2 hours", "45 mins", "an hour", "ngủ được 2 giờ". A clock-like
 * "9h" or "2 giờ" alone is NOT a duration (it may be a time).
 */
export function durationsIn(text: string): DurationMatch[] {
  const f = foldVi(text);
  const out: DurationMatch[] = [];
  const taken: [number, number][] = [];
  const push = (index: number, len: number, minutes: number, t: string) => {
    if (taken.some(([a, b]) => index < b && index + len > a) || !(minutes > 0)) return;
    taken.push([index, index + len]);
    out.push({ minutes: Math.round(minutes), text: t.trim(), index });
  };
  // Hours (+ rưỡi / + minutes): "1 tiếng rưỡi", "1 tiếng 15 phút", "2 hours 30 min".
  const hourWords = String.raw`tieng(?:\s+dong\s+ho)?|hours?|hrs?|gio\s+dong\s+ho`;
  for (const m of f.matchAll(
    new RegExp(
      String.raw`(?<![\p{L}\d])${numOrWord}\s*(?:${hourWords})(?:\s*(ruoi)|\s*(?:and\s+)?(\d{1,2})\s*(?:phut|p|minutes?|mins?)?(?![\p{L}\d]))?${END}`,
      'gu',
    ),
  )) {
    const h = toNum(m[1]!);
    if (!Number.isFinite(h)) continue;
    push(m.index, m[0].length, h * 60 + (m[2] ? 30 : 0) + (m[3] ? Number(m[3]) : 0), m[0]);
  }
  // "ngủ được 2 giờ", "trong 2 giờ", "mất 2 giờ" (a duration only after these words).
  for (const m of f.matchAll(
    new RegExp(String.raw`(?:duoc|trong|mat|het)\s+${numOrWord}\s*gio(\s*ruoi)?${END}`, 'gu'),
  )) {
    const h = toNum(m[1]!);
    if (Number.isFinite(h)) push(m.index, m[0].length, h * 60 + (m[2] ? 30 : 0), m[0]);
  }
  for (const m of f.matchAll(/(?<![\p{L}])(?:nua tieng|half an hour|nua gio)(?![\p{L}])/gu)) {
    push(m.index, m[0].length, 30, m[0]);
  }
  for (const m of f.matchAll(
    new RegExp(String.raw`(?<![\p{L}\d])${numOrWord}\s*(?:phut|p|minutes?|mins?)${END}`, 'gu'),
  )) {
    const n = toNum(m[1]!);
    if (Number.isFinite(n)) push(m.index, m[0].length, n, m[0]);
  }
  return out.sort((a, b) => a.index - b.index);
}

// ---------- "2 tiếng trước", "vừa xong" ----------

export interface AgoMatch {
  /** Minutes before the send time; 0 for "vừa xong" / "just now". */
  minutes: number;
  /** "vừa", "just" without a number: about now. */
  justNow: boolean;
  text: string;
}

/** "2 tiếng trước", "30 phút trước", "nửa tiếng trước", "2 hours ago", "vừa xong", "just now". */
export function agoIn(text: string): AgoMatch | null {
  const f = foldVi(text);
  const m = new RegExp(String.raw`(.{0,30}?)\s*(truoc|ago)(?![\p{L}])(?!\s*khi)`, 'u').exec(f);
  if (m) {
    const d = durationsIn(m[1]!);
    if (d.length > 0)
      return {
        minutes: d[d.length - 1]!.minutes,
        justNow: false,
        text: `${d[d.length - 1]!.text} ${m[2]}`,
      };
  }
  const j =
    /(?<![\p{L}])(vua xong|vua moi|vua roi|just now|just)(?![\p{L}])/u.exec(f) ??
    /(?<![\p{L}])vua(?![\p{L}])/u.exec(f);
  if (j) return { minutes: 0, justNow: true, text: j[0] };
  return null;
}

// ---------- Clock times (a typed answer, or a check on the model) ----------

export interface ClockMatch {
  /** 24 h local "HH:mm". */
  hhmm: string;
  /** The half of the day is known (24 h written, a period word, am / pm). */
  explicit: boolean;
  /** From "hôm qua", "tối qua", "đêm qua", "yesterday" (−1), "mai" (+1), else null. */
  dayOffset: number | null;
}

const pad = (n: number) => String(n).padStart(2, '0');

/** Which half of the day the words near a time say (folded text). */
function periodNear(f: string): 'am' | 'pm' | 'noon' | 'night' | 'late' | null {
  if (/(?<![\p{L}])(?:pm|p\.m)(?![\p{L}])/u.test(f)) return 'pm';
  if (/(?<![\p{L}])(?:am|a\.m)(?![\p{L}])/u.test(f)) return 'am';
  if (/rang sang|sang som|morning/.test(f) || /(?<![\p{L}])sang(?![\p{L}])/u.test(f)) return 'am';
  if (/(?<![\p{L}])(?:trua|noon)(?![\p{L}])/u.test(f)) return 'noon';
  if (/(?<![\p{L}])(?:chieu|afternoon|toi|evening|tonight)(?![\p{L}])/u.test(f)) return 'pm';
  if (/(?<![\p{L}])(?:dem|night|khuya)(?![\p{L}])/u.test(f)) return 'night';
  return null;
}

/**
 * The first clock time in [text]: "21h", "21:30", "9h tối", "9 giờ rưỡi tối", "10pm", "8h sáng",
 * "nửa đêm", "12h trưa". Returns null when there is none.
 */
export function clockTimeIn(text: string): ClockMatch | null {
  const f = foldVi(text);
  const day =
    /(?<![\p{L}])(?:hom qua|toi qua|dem qua|sang qua|chieu qua|trua qua|yesterday|last night)(?![\p{L}])/u.test(
      f,
    )
      ? -1
      : /(?<![\p{L}])(?:ngay mai|sang mai|chieu mai|toi mai|tomorrow)(?![\p{L}])/u.test(f)
        ? 1
        : null;
  if (/(?<![\p{L}])(?:nua dem|midnight)(?![\p{L}])/u.test(f) && !/\d/.test(f)) {
    return { hhmm: '00:00', explicit: true, dayOffset: day };
  }
  const m =
    /(?<![\d:])(\d{1,2})\s*(?::|gio|h|g)\s*(\d{2})?(?:\s*(ruoi)|\s*kem\s*(\d{1,2}))?(?![\d])/u.exec(
      f,
    ) ?? /(?<![\d:])(\d{1,2})()()()\s*(?=am|pm|a\.m|p\.m)/u.exec(f);
  if (!m) return null;
  let h = Number(m[1]);
  let min = m[2] ? Number(m[2]) : m[3] ? 30 : 0;
  if (m[4]) {
    h -= 1;
    min = 60 - Number(m[4]);
  }
  if (h > 23 || min > 59 || h < 0) return null;
  if (h >= 13 || h === 0) return { hhmm: `${pad(h)}:${pad(min)}`, explicit: true, dayOffset: day };
  const p = periodNear(f);
  if (p === null) return { hhmm: `${pad(h)}:${pad(min)}`, explicit: false, dayOffset: day };
  if (p === 'am') h = h === 12 ? 0 : h;
  else if (p === 'pm') h = h === 12 ? 12 : h + 12;
  else if (p === 'noon') h = h <= 4 ? h + 12 : h;
  else if (p === 'night') h = h === 12 ? 0 : h >= 6 ? h + 12 : h;
  return { hhmm: `${pad(h % 24)}:${pad(min)}`, explicit: true, dayOffset: day };
}

/**
 * Whether [text] says which half of the day its hours are in: a period word (sáng, trưa, chiều,
 * tối, đêm, khuya, rạng sáng, nửa đêm; morning, afternoon, evening, night, noon, midnight), with or
 * without diacritics next to a time ("9h sang"), or am / pm after a number.
 */
export function hasDayPeriod(text: string): boolean {
  const lower = ` ${lowerVi(text)} `;
  if (
    /(?<![\p{L}])(?:sáng|trưa|chiều|tối|đêm|khuya|rạng|morning|afternoon|evening|night|tonight|noon|midnight)(?![\p{L}])/u.test(
      lower,
    )
  ) {
    return true;
  }
  const f = foldVi(text);
  if (/\d\s*(?:am|pm|a\.m|p\.m)(?![\p{L}])/u.test(f)) return true;
  // Unaccented, only next to a time or "nay / qua / mai": "9h sang", "toi qua", "chieu nay".
  return (
    /\d\s*(?:h|g|gio|:\d\d)?\s*\d{0,2}\s*(?:sang|trua|chieu|toi|dem|khuya)(?![\p{L}])/u.test(f) ||
    /(?<![\p{L}])(?:sang|trua|chieu|toi|dem)\s+(?:nay|qua|mai)(?![\p{L}])/u.test(f) ||
    /(?<![\p{L}])(?:nua dem|rang sang)(?![\p{L}])/u.test(f)
  );
}

// ---------- Relative dates ----------

export interface DateMatch {
  date: string;
  /** False when the words leave room (a weekday equal to today, "tuần sau" alone). */
  certain: boolean;
  text: string;
}

const addDays = (date: string, n: number) => {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(y, m - 1, d + n)).toISOString().slice(0, 10);
};
const weekdayOfIso = (date: string) => {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay();
};

const weekdayWords: [RegExp, number][] = [
  [/(?<![\p{L}])(?:thu\s*2|thu\s*hai|t2|monday)(?![\p{L}\d])/u, 1],
  [/(?<![\p{L}])(?:thu\s*3|thu\s*ba|t3|tuesday)(?![\p{L}\d])/u, 2],
  [/(?<![\p{L}])(?:thu\s*4|thu\s*tu|t4|wednesday)(?![\p{L}\d])/u, 3],
  [/(?<![\p{L}])(?:thu\s*5|thu\s*nam|t5|thursday)(?![\p{L}\d])/u, 4],
  [/(?<![\p{L}])(?:thu\s*6|thu\s*sau|t6|friday)(?![\p{L}\d])/u, 5],
  [/(?<![\p{L}])(?:thu\s*7|thu\s*bay|t7|saturday)(?![\p{L}\d])/u, 6],
  [/(?<![\p{L}])(?:chu\s*nhat|cn|sunday)(?![\p{L}\d])/u, 0],
];

/**
 * The first date said in [text] relative to [today] (the send day in the baby's zone):
 * hôm nay / sáng nay / tối nay / today (0), hôm qua / tối qua / đêm qua / yesterday (−1),
 * hôm kia (−2), mai / ngày mai / tomorrow (+1), mốt / ngày kia (+2), a weekday ("thứ 6", "thứ 2
 * tuần sau", "chủ nhật tuần trước", "friday") and a written date ("20/10", "ngày 20 tháng 10",
 * "20/10/2026"). [direction] chooses the side of a bare weekday: `future` for reminders, `past`
 * for logs and expenses. Null when nothing is said.
 */
export function relativeDateIn(
  text: string,
  today: string,
  direction: 'future' | 'past',
): DateMatch | null {
  const f = foldVi(text);
  const lower = lowerVi(text);
  const found: (DateMatch & { index: number })[] = [];
  const add = (index: number, date: string, certain: boolean, t: string) =>
    found.push({ index, date, certain, text: t });
  const year = Number(today.slice(0, 4));
  const fixDate = (d: number, mo: number, y: number | null, idx: number, t: string) => {
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return;
    const yy = y === null ? year : y < 100 ? 2000 + y : y;
    let iso = `${yy}-${pad(mo)}-${pad(d)}`;
    if (Number.isNaN(Date.parse(iso)) || addDays(iso, 0) !== iso) return;
    if (y === null) {
      // No year: the nearest such date in the direction asked (a reminder in January → next year).
      if (direction === 'future' && iso < addDays(today, -1))
        iso = `${yy + 1}-${pad(mo)}-${pad(d)}`;
      if (direction === 'past' && iso > addDays(today, 1)) iso = `${yy - 1}-${pad(mo)}-${pad(d)}`;
    }
    add(idx, iso, true, t);
  };
  for (const m of f.matchAll(
    /(?<![\d/.:-])(\d{1,2})([/.-])(\d{1,2})(?:[/.-](\d{2,4}))?(?![\d/:.-])/g,
  )) {
    // "1.2tr" / "20.50" are amounts, "2-3" a range, "9.30" may be a time: a dot or a dash needs
    // a year after it or "ngày" before it; a slash is a date.
    if (m[2] !== '/' && !m[4] && !/ngay\s*$/.test(f.slice(0, m.index))) continue;
    fixDate(Number(m[1]), Number(m[3]), m[4] ? Number(m[4]) : null, m.index, m[0]);
  }
  for (const m of f.matchAll(/ngay\s+(\d{1,2})\s+thang\s+(\d{1,2})(?:\s+nam\s+(\d{4}))?/g)) {
    fixDate(Number(m[1]), Number(m[2]), m[3] ? Number(m[3]) : null, m.index, m[0]);
  }
  const rel: [RegExp, number][] = [
    [
      /(?<![\p{L}])(?:hom nay|bua nay|sang nay|trua nay|chieu nay|toi nay|dem nay|today|tonight|this morning|this afternoon|this evening)(?![\p{L}])/u,
      0,
    ],
    [
      /(?<![\p{L}])(?:hom qua|bua qua|toi qua|dem qua|sang qua|trua qua|chieu qua|yesterday|last night)(?![\p{L}])/u,
      -1,
    ],
    [/(?<![\p{L}])(?:hom kia|day before yesterday)(?![\p{L}])/u, -2],
    [/(?<![\p{L}])(?:ngay mai|sang mai|trua mai|chieu mai|toi mai|tomorrow)(?![\p{L}])/u, 1],
    [/(?<![\p{L}])(?:ngay kia|ngay mot|day after tomorrow)(?![\p{L}])/u, 2],
  ];
  for (const [re, n] of rel) {
    const m = re.exec(f);
    if (m) add(m.index, addDays(today, n), true, m[0]);
  }
  // "mai" / "mốt" alone, as written (not "Mai" the name mid-sentence, not "một").
  for (const m of lower.matchAll(/(?<![\p{L}])(mai|mốt)(?![\p{L}])/gu)) {
    if (m[1] === 'mai' && /[\p{Lu}]/u.test(text.normalize('NFC').charAt(m.index))) {
      if (m.index > 0) continue;
    }
    if (found.some((x) => m.index >= x.index && m.index < x.index + x.text.length)) continue;
    add(m.index, addDays(today, m[1] === 'mai' ? 1 : 2), true, m[1]!);
  }
  const todayDow = weekdayOfIso(today);
  for (const [re, dow] of weekdayWords) {
    const m = re.exec(f);
    if (!m) continue;
    const around = f.slice(m.index, m.index + m[0].length + 16);
    const before = f.slice(Math.max(0, m.index - 12), m.index);
    const next =
      /tuan\s*(?:sau|toi)|next/.test(around) || /(?:next|tuan\s*(?:sau|toi))\s*$/.test(before);
    const last = /tuan\s*truoc|last/.test(around) || /(?:last|tuan\s*truoc)\s*$/.test(before);
    // Weeks start on Monday (Vietnam): "thứ 2 tuần sau" is the Monday of next week.
    const mondayOffset = (todayDow + 6) % 7;
    const thisWeek = addDays(today, -mondayOffset + ((dow + 6) % 7));
    if (next) add(m.index, addDays(thisWeek, 7), true, m[0]);
    else if (last) add(m.index, addDays(thisWeek, -7), true, m[0]);
    else if (dow === todayDow) {
      add(m.index, direction === 'future' ? addDays(today, 7) : today, false, m[0]);
    } else if (direction === 'future') {
      add(m.index, addDays(today, (dow - todayDow + 7) % 7), true, m[0]);
    } else add(m.index, addDays(today, -((todayDow - dow + 7) % 7)), true, m[0]);
  }
  if (found.length === 0) {
    const w = /(?<![\p{L}])(?:tuan sau|tuan toi|next week)(?![\p{L}])/u.exec(f);
    if (w) return { date: addDays(today, 7), certain: false, text: w[0] };
    return null;
  }
  found.sort((a, b) => a.index - b.index);
  const { index: _i, ...first } = found[0]!;
  void _i;
  return first;
}

// ---------- Small talk ----------

export type SmallTalkKind = 'thanks' | 'greeting' | 'ack' | 'bye';

const smallTalkPhrases: Record<SmallTalkKind, string[]> = {
  thanks: [
    'cam on',
    'cam on nhieu',
    'cam on nhe',
    'cam on nha',
    'cam on ban',
    'cam on lumi',
    'tks',
    'thks',
    'thx',
    'thanks',
    'thank you',
    'thank u',
    'ty',
    'many thanks',
  ],
  greeting: [
    'chao',
    'xin chao',
    'chao ban',
    'hello',
    'hi',
    'hey',
    'alo',
    'good morning',
    'chao buoi sang',
  ],
  ack: [
    'ok',
    'oke',
    'okay',
    'okie',
    'oki',
    'okela',
    'u',
    'uh',
    'um',
    'vang',
    'da',
    'duoc roi',
    'dc roi',
    'tot qua',
    'tuyet',
    'tuyet voi',
    'hay qua',
    'great',
    'cool',
    'nice',
    'got it',
    'vua ghi roi',
    'ghi roi',
    'da ghi roi',
    'minh ghi roi',
    'xong roi',
    'da luu roi',
    'luu roi',
  ],
  bye: ['bye', 'tam biet', 'good night', 'chuc ngu ngon', 'ngu ngon', 'see you'],
};
const fillers = new Set([
  'lumi',
  'nhe',
  'nha',
  'a',
  'oi',
  'nhieu',
  'ban',
  'em',
  'minh',
  'nhe',
  'luon',
  'so',
  'much',
  'very',
  'so',
  'you',
  'nhieu',
  'lam',
]);

/**
 * When the WHOLE message is small talk ("cảm ơn Lumi", "chào", "ok", "Thanks!", "vừa ghi rồi"),
 * its kind; null when anything else is in it (a number, a log, a question). Answered by the
 * server's own short reply, without the model, for 0 credits.
 */
export function smallTalkIn(text: string): SmallTalkKind | null {
  const t = text.trim();
  if (t.length === 0 || t.length > 48 || /\d/.test(t)) return null;
  const f = foldVi(t)
    .replace(/[\p{Extended_Pictographic}\u{FE0F}\u{200D}]/gu, ' ')
    .replace(/[^\p{L}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  if (f === '') return /[\p{Extended_Pictographic}]/u.test(t) ? 'ack' : null;
  for (const [kind, phrases] of Object.entries(smallTalkPhrases) as [SmallTalkKind, string[]][]) {
    if (phrases.includes(f)) return kind;
  }
  const words = f.split(' ').filter((w) => !fillers.has(w));
  const core = words.join(' ');
  for (const [kind, phrases] of Object.entries(smallTalkPhrases) as [SmallTalkKind, string[]][]) {
    if (core !== '' && phrases.includes(core)) return kind;
  }
  return null;
}

// ---------- Category hints (Chi tiêu built-ins) ----------

const categoryHints: [RegExp, string][] = [
  [
    /(?<![\p{L}])(?:hoc phi|hoc boi|hoc|truong|mam non|nha tre|trong tre|giu tre|bao mau|daycare|babysit\w*|nanny|tuition|school|class(?:es)?|lessons?|swim\w*)(?![\p{L}])/u,
    'c_childcare',
  ],
  [
    /(?<![\p{L}])(?:kham|tiem|vac ?xin|vaccine?s?|thuoc|bac si|benh vien|phong kham|xet nghiem|sieu am|doctor|clinic|hospital|medicine|pharmacy|vaccinations?)(?![\p{L}])/u,
    'c_health',
  ],
  [
    /(?<![\p{L}])(?:bim|ta giay|giay uot|khan uot|khan giay|diapers?|nappies|nappy|wipes)(?![\p{L}])/u,
    'c_diaper',
  ],
  [
    /(?<![\p{L}])(?:sua|sua bot|binh sua|an dam|bot an dam|formula|milk|baby food)(?![\p{L}])/u,
    'c_milk',
  ],
  [/(?<![\p{L}])(?:quan ao|ao|giay dep|clothes|shoes|onesies?|socks)(?![\p{L}])/u, 'c_clothes'],
];

/** A built-in Chi tiêu category the words point to ("sữa" → c_milk, "bỉm" / "tã" → c_diaper…). */
export function categoryHintIn(text: string): string | null {
  const f = foldVi(text);
  if (/(?<![\p{L}])tã(?![\p{L}])/u.test(lowerVi(text))) return 'c_diaper';
  return categoryHints.find(([re]) => re.test(f))?.[1] ?? null;
}

// ---------- Medicine (never scheduled by the assistant) ----------

/**
 * A medicine or dose in a reminder ("cho bé uống thuốc", "siro ho", "5ml paracetamol", "kháng
 * sinh"): the assistant never schedules medicine (brief: no doses, no medicine schedules); the
 * person can add such a reminder themselves in Nhắc việc.
 */
export function mentionsMedicine(text: string): boolean {
  const f = foldVi(text);
  return (
    /(?<![\p{L}])(?:thuoc|siro|si ro|khang sinh|ha sot|paracetamol|ibuprofen|hapacol|efferalgan|vitamin d|men vi sinh|nho mui|medicine|medication|antibiotics?|syrup|dose|dosage|tylenol|motrin)(?![\p{L}])/u.test(
      f,
    ) || /\d\s*(?:mg|mcg)(?![\p{L}])/u.test(f)
  );
}

// ---------- "Con ăn gì được?" ----------

/**
 * A question about what the baby could eat or cook ("con 7 tháng ăn gì được?", "món ăn dặm",
 * "thực đơn", "what can she eat"): the care meal-ideas topic (approved recipes only). A safety
 * net when the model returns nothing for such a question.
 */
export function asksWhatToEat(text: string): boolean {
  const f = foldVi(text);
  return (
    /(?<![\p{L}])(?:an gi|mon gi|mon an|an dam|thuc don|cong thuc|nau gi|nau mon|cho an|meal ideas?|recipes?)(?![\p{L}])/u.test(
      f,
    ) || /what\s+(?:can|should|to|do)\b[^?]*\b(?:eat|cook|feed)/u.test(f)
  );
}

// ---------- Bottle amounts ----------

/** "120ml", "120 ml", "4oz", "4 oz", "4 ounces" in [text] → ml (1 oz = 29.5735 ml, rounded). */
export function bottleMlIn(text: string): { ml: number; fromOz: boolean } | null {
  const f = foldVi(text);
  const oz = /(\d+(?:[.,]\d+)?)\s*(?:oz|ounces?|ounce)(?![\p{L}])/u.exec(f);
  if (oz) return { ml: Math.round(Number(oz[1]!.replace(',', '.')) * 29.5735), fromOz: true };
  const ml = /(\d+(?:[.,]\d+)?)\s*(?:ml|mls|millilit(?:er|re)s?|mililit|cc)(?![\p{L}])/u.exec(f);
  if (ml) return { ml: Math.round(Number(ml[1]!.replace(',', '.'))), fromOz: false };
  return null;
}

// ---------- Breast side ----------

/** "bên trái" / "trái" / "left" → left; "phải" / "right" → right; "hai bên" / "cả 2 bên" / "both" → both. */
export function breastSideIn(text: string): 'left' | 'right' | 'both' | null {
  const lower = lowerVi(text);
  const f = foldVi(text);
  if (/(?<![\p{L}])(?:ca hai ben|ca 2 ben|hai ben|2 ben|both(?: sides)?)(?![\p{L}])/u.test(f))
    return 'both';
  const left =
    /(?<![\p{L}])(?:trái|left)(?![\p{L}])/u.test(lower) ||
    /(?<![\p{L}])ben trai(?![\p{L}])/u.test(f);
  const right =
    /(?<![\p{L}])(?:phải|right)(?![\p{L}])/u.test(lower) ||
    /(?<![\p{L}])ben phai(?![\p{L}])/u.test(f);
  if (left && right) return 'both';
  if (left) return 'left';
  if (right) return 'right';
  return null;
}

// ---------- Spans (start / end / duration kept together) ----------

/**
 * A span from what was said (instants in ms, duration in minutes): two of the three give the
 * third. `derived` names the field the server computed (the app keeps them linked while the
 * person edits); `inconsistent` when all three were given and disagree by more than 10 minutes
 * (the end then stays as said, for review).
 */
export function completeSpan(x: {
  start: number | null;
  end: number | null;
  durationMin: number | null;
}): {
  start: number | null;
  end: number | null;
  durationMin: number | null;
  derived: 'start' | 'end' | 'duration' | null;
  inconsistent: boolean;
} {
  const { start, end, durationMin } = x;
  if (start !== null && end !== null) {
    const span = Math.round((end - start) / 60_000);
    const inconsistent = durationMin !== null && Math.abs(span - durationMin) > 10;
    return {
      start,
      end,
      durationMin: span,
      derived: durationMin === null ? 'duration' : null,
      inconsistent,
    };
  }
  if (start !== null && durationMin !== null) {
    return {
      start,
      end: start + durationMin * 60_000,
      durationMin,
      derived: 'end',
      inconsistent: false,
    };
  }
  if (end !== null && durationMin !== null) {
    return {
      start: end - durationMin * 60_000,
      end,
      durationMin,
      derived: 'start',
      inconsistent: false,
    };
  }
  return { start, end, durationMin, derived: null, inconsistent: false };
}
