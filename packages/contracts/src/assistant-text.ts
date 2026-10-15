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
    spendWordsEn.some((w) => wordRe(w).test(f)) ||
    // LUMI-16: goods counted by the box / pack ("Con Cưng hôm nay hai hộp sữa").
    /(?<![\p{L}\d])(?:\d+|mot|hai|ba|bon|nam|sau|muoi)\s+(?:hop|lon|goi|bich|thung|loc|chai|tui|bao)\s+(?:sua|bim|ta|khan|banh|bot|nuoc)(?![\p{L}])/u.test(
      f,
    ) ||
    // LUMI-16 (owner 2026-10-16): "đặt tã online", "order diapers".
    purchasesIn(text).length > 0;
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
  // LUMI-03: "12h" is noon in Vietnamese unless the night is said ("12h đêm", "12h khuya").
  if (h === 12 && p !== 'night' && !/(?<![\p{L}])(?:am|a\.m)(?![\p{L}])/u.test(f)) {
    return { hhmm: `12:${pad(min)}`, explicit: true, dayOffset: day };
  }
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

// ---------- Ongoing states → the app's timers (Lumi 2026-10-16) ----------

export interface CareState {
  timer: 'sleep' | 'breast';
  /** start: happening now / just began ("con đang ngủ"); stop: just ended ("dậy rồi"). */
  action: 'start' | 'stop';
  /** "đang cho bú bên trái": the side to run first (both → null: one side at a time). */
  side: 'left' | 'right' | null;
  /** The matched words (folded), for evidence. */
  text: string;
}

const W = (alts: string) => new RegExp(String.raw`(?<![\p{L}])(?:${alts})(?![\p{L}])`, 'u');
/** A sleep problem or a concern, not a state: "khó ngủ", "chưa ngủ", "hay thức giấc"… */
const sleepConcern = W(
  'kho ngu|kho vao giac|khong ngu|chua ngu|chang ngu|khong chiu ngu|it ngu|ngu it|mat ngu|ngu kem|ngu khong ngon|buon ngu|hay thuc|thuc giac|thuc dem|giat minh|quay|khoc',
);
const sleepStop = W(
  'ngu day|day roi|day rui|vua day|moi day|da day|thuc day|tinh day|tinh giac|day luc|day vao luc|day hoi|day nhe',
);
const sleepStopEn =
  /\b(?:woke up|woken up|is awake|awake now|just woke|has woken|wakes up|is up now|up from (?:her|his|the) nap)\b/u;
const sleepStart = W(
  'dang ngu|vua ngu|moi ngu|ngu roi|ngu rui|da ngu|di ngu roi|bat dau ngu|vao giac|ngu thiep|ru ngu xong|ru xong roi|ngu say roi|dang ngu trua|dang ngu ngay',
);
const sleepStartEn =
  /\b(?:is asleep|fell asleep|fallen asleep|went to sleep|gone to sleep|started sleeping|is sleeping|sleeping now|is napping|napping now|down for (?:a |her |his )?nap)\b/u;
const bottleWords = W('binh|bu binh|sua cong thuc|cong thuc|bottle|formula|ml|oz');
const breastStart = W(
  'dang (?:cho (?:be |con )?)?(?:bu|ti)(?: me)?|bat dau (?:cho (?:be |con )?)?(?:bu|ti)(?: me)?|dang cho (?:be |con )?an sua me',
);
const breastStartEn =
  /\b(?:nursing now|is nursing|started nursing|breastfeeding now|is breastfeeding|started breastfeeding|feeding on the (?:left|right))\b/u;
const breastStop = W('(?:cho (?:be |con )?)?(?:bu|ti)(?: me)? xong|xong cu bu|bu no roi|ti no roi');
const breastStopEn =
  /\b(?:done nursing|finished nursing|done breastfeeding|finished breastfeeding|stopped nursing)\b/u;

/**
 * Ongoing care states in [text] that map to the app's running timers (sleep, breastfeeding):
 * "con đang ngủ", "bé vừa ngủ", "bé ngủ rồi", "bắt đầu ngủ lúc 21h" → sleep start; "con dậy rồi",
 * "bé vừa dậy", "dậy lúc 6h" → sleep stop; "đang cho bú (trái)" → breast start; "bú xong rồi" →
 * breast stop. A concern ("khó ngủ", "chưa ngủ", "hay thức giấc"), a bottle, or a finished log
 * with its length ("ngủ 2 tiếng", "bú 15 phút xong") is not a state. At most one per timer.
 * "dậy" is matched with its diacritics when the text has any ("dạy", "đầy" are other words).
 */
export function careStatesIn(text: string): CareState[] {
  const f = foldVi(text);
  const lower = lowerVi(text);
  const marks = hasVietnameseMarks(text);
  const said = durationsIn(text).length > 0;
  const out: CareState[] = [];
  const hit = (re: RegExp) => re.exec(f)?.[0] ?? null;
  // Sleep: a stop ("ngủ dậy") is read before a start ("ngủ").
  if (!sleepConcern.test(f)) {
    const wakeWord = !marks || /dậy|thức|tỉnh/u.test(lower);
    const stop = (wakeWord ? hit(sleepStop) : null) ?? hit(sleepStopEn);
    const start = hit(sleepStart) ?? hit(sleepStartEn);
    if (stop && !said) out.push({ timer: 'sleep', action: 'stop', side: null, text: stop });
    else if (start && !stop && !(said && /ngu duoc|slept for/u.test(f))) {
      out.push({ timer: 'sleep', action: 'start', side: null, text: start });
    }
  }
  if (!bottleWords.test(f)) {
    const stop = hit(breastStop) ?? hit(breastStopEn);
    const start = hit(breastStart) ?? hit(breastStartEn);
    const side = breastSideIn(text);
    if (stop && !said) out.push({ timer: 'breast', action: 'stop', side: null, text: stop });
    else if (start && !stop && !said) {
      out.push({
        timer: 'breast',
        action: 'start',
        side: side === 'left' || side === 'right' ? side : null,
        text: start,
      });
    }
  }
  return out;
}

/**
 * Words that make a sleep / feeding note an OBSERVATION ("something different noticed"): khó
 * ngủ, hay thức giấc, quấy hơn, ăn ít, biếng bú, bỏ bú, ngủ ít hơn… A plain state or log ("con
 * đang ngủ", "bé ngủ 2 tiếng", "bé vừa bú") has none of them and is never an observation.
 */
export function observationCueIn(text: string): boolean {
  const f = foldVi(text);
  return (
    W(
      'kho|hay thuc|thuc giac|thuc dem|giat minh|quay|khoc|it hon|nhieu hon|hon moi khi|hon hom qua|it qua|ngu it|an it|bu it|bieng|bo bu|bo an|khong chiu|chang chiu|khong muon|bat thuong|la thuong|khac thuong|khac moi ngay|tre hon|som hon|muon hon|lau hon|ngan hon|khong ngon|tinh giac|tran troc|van minh',
    ).test(f) ||
    /\b(?:fussy|fussier|trouble|hard to|less than|more than|refus\w*|won'?t|waking|unusual|restless|worse|better than|harder|cranky)\b/u.test(
      f,
    )
  );
}

/** The same message again (case, diacritics kept, spaces and punctuation ignored). */
export function sameMessage(a: string | null | undefined, b: string | null | undefined): boolean {
  const n = (s: string) =>
    s
      .normalize('NFC')
      .toLocaleLowerCase('vi')
      .replace(/[^\p{L}\p{N}]+/gu, ' ')
      .trim();
  return typeof a === 'string' && typeof b === 'string' && n(a) !== '' && n(a) === n(b);
}

/** A repeated message within this many minutes reuses the draft still waiting above it. */
export const assistantRepeatWindowMin = 10;

// ---------- Lumi fixes 2026-10-16 ----------

// ---- Clock tokens, each with ITS OWN half of the day (LUMI-03 / LUMI-04) ----

/** One clock time written in a message, read on its own (never with another token's period). */
export interface ClockToken {
  /** The hour and minute as written (h 0…23). */
  h: number;
  m: number;
  /**
   * The possible 24 h hours: one when this token's half of the day is known (24 h written,
   * "12h" = noon, a period word next to it, or the message's single period phrase), else both
   * readings (h, h + 12).
   */
  hours: number[];
  /** Index in the folded text and the matched words (folded). */
  index: number;
  text: string;
}

const hourWordsVi: Record<string, number> = {
  mot: 1,
  hai: 2,
  ba: 3,
  bon: 4,
  tu: 4,
  nam: 5,
  sau: 6,
  bay: 7,
  tam: 8,
  chin: 9,
  muoi: 10,
  'muoi mot': 11,
  'muoi hai': 12,
};

type Period = 'am' | 'pm' | 'noon' | 'night' | 'en_am' | null;

/**
 * The period a few words AFTER a token says ("9h tối", "8h sang nay", "10 pm", "9 in the morning").
 * [rest] is folded; [restMarked] the same span with its diacritics, used when the message has any
 * ("tới 10 giờ" is "until", never "tối").
 */
function periodAfter(rest: string, restMarked: string | null): Period {
  const m =
    /^\s*(?:,\s*)?(?:buoi\s+)?(sang|trua|chieu|toi|dem|khuya|am|a\.m|pm|p\.m|in the morning|in the afternoon|in the evening|at night|tonight|morning|afternoon|evening|noon)(?![\p{L}])/u.exec(
      rest,
    );
  if (!m) return null;
  if (restMarked !== null && /^(?:sang|trua|chieu|toi|dem)$/.test(m[1]!)) {
    const marked = restMarked.slice(m.index, m.index + m[0].length);
    if (!/(?:sáng|trưa|chiều|tối|đêm)/u.test(marked)) return null;
  }
  return periodWord(m[1]!);
}

/** The period right BEFORE a token ("tối qua lúc 9h", "sáng 7h", "chiều nay 3 giờ"). */
function periodBefore(head: string, headMarked: string | null): Period {
  const m =
    /(?<![\p{L}])(?:buoi\s+)?(sang|trua|chieu|toi|dem|khuya)(?:\s+(?:nay|qua|mai|hom qua))?(?:\s+(?:luc|vao|vao luc|khoang|tam|tu))?\s*$/u.exec(
      head,
    );
  if (!m) return null;
  if (headMarked !== null && m[1] !== 'khuya') {
    const marked = headMarked.slice(m.index, m.index + m[0].length);
    if (!/(?:sáng|trưa|chiều|tối|đêm)/u.test(marked)) return null;
  }
  return periodWord(m[1]!);
}

function periodWord(w: string): Period {
  if (w === 'am' || w === 'a.m' || w === 'in the morning' || w === 'morning')
    return w.startsWith('a') ? 'en_am' : 'am';
  if (w === 'sang') return 'am';
  if (w === 'trua' || w === 'noon') return 'noon';
  if (w === 'dem' || w === 'khuya' || w === 'at night') return 'night';
  return 'pm';
}

function hoursFor(h: number, p: Period, nightWords: boolean): number[] {
  if (h >= 13 || h === 0) return [h];
  if (h === 12) {
    if (p === 'night' || p === 'en_am' || (p === null && nightWords)) return [0];
    return [12];
  }
  switch (p) {
    case 'am':
    case 'en_am':
      return [h];
    case 'noon':
      return [h <= 4 ? h + 12 : h];
    case 'pm':
      return [h + 12];
    case 'night':
      return [h >= 6 ? h + 12 : h];
    default:
      return [h, h + 12];
  }
}

/**
 * Every clock time in [text] in reading order, each with the half of the day ITS words give:
 * "6h 90ml, 9h 120ml, 12h 100ml" → [6, 18], [9, 21], [12]; "từ 1h trưa đến 2h chiều" → [13], [14];
 * "sáng nay bú 6h, 9h" → [6], [9] (one period phrase for the message). Forms: 21h, 21:30, 9h15,
 * 9 giờ rưỡi, 9 giờ kém 15, 8g, 10pm, "lúc 8", "tám giờ rưỡi", "mười hai giờ".
 */
export function clockTokensIn(text: string): ClockToken[] {
  const f = foldVi(text);
  // Folding keeps the length of the NFC lower-case text: the marked words sit at the same index.
  const lower = lowerVi(text);
  const marked = hasVietnameseMarks(text) && lower.length === f.length ? lower : null;
  const out: ClockToken[] = [];
  const taken: [number, number][] = [];
  const nightWords = /(?<![\p{L}])(?:dem|khuya|midnight)(?![\p{L}])/u.test(f);
  const add = (index: number, len: number, h: number, m: number, matched: string) => {
    if (h > 23 || m > 59 || h < 0) return;
    if (taken.some(([a, b]) => index < b && index + len > a)) return;
    taken.push([index, index + len]);
    const from = Math.max(0, index - 30);
    // Only the period words next to THIS time count (never another time's, LUMI-03).
    const own =
      periodAfter(f.slice(index + len), marked?.slice(index + len) ?? null) ??
      periodBefore(f.slice(from, index), marked?.slice(from, index) ?? null);
    out.push({ h, m, hours: hoursFor(h, own, nightWords && own === null), index, text: matched });
  };
  for (const x of f.matchAll(
    /(?<![\d:.,])(\d{1,2})\s*(?::|gio(?![\p{L}])|h(?![\p{L}])|g(?![\p{L}]))(?:\s?([0-5]\d)(?!\d|\s*(?:ml|oz|cc|kg|g|k|p|phut|tieng|%)(?![\p{L}])))?(?:\s*(ruoi)|\s*kem\s*(\d{1,2}))?(?![\d])/gu,
  )) {
    let h = Number(x[1]);
    let m = x[2] ? Number(x[2]) : x[3] ? 30 : 0;
    if (x[4]) {
      h -= 1;
      m = 60 - Number(x[4]);
    }
    add(x.index, x[0].length, h, m, x[0]);
  }
  for (const x of f.matchAll(/(?<![\d:.,])(\d{1,2})(?::(\d{2}))?\s*(?=am|pm|a\.m|p\.m)/gu)) {
    add(x.index, x[0].length, Number(x[1]), x[2] ? Number(x[2]) : 0, x[0]);
  }
  for (const x of f.matchAll(
    /(?<![\p{L}])(muoi mot|muoi hai|mot|hai|ba|bon|tu|nam|sau|bay|tam|chin|muoi)\s+gio(?:\s+(ruoi)|\s+kem\s+(\d{1,2}|muoi lam|muoi))?(?![\p{L}])/gu,
  )) {
    let h = hourWordsVi[x[1]!]!;
    let m = x[2] ? 30 : 0;
    if (x[3]) {
      h -= 1;
      m = 60 - (x[3] === 'muoi lam' ? 15 : x[3] === 'muoi' ? 10 : Number(x[3]));
    }
    add(x.index, x[0].length, h, m, x[0]);
  }
  // "lúc 8", "at 8" (a bare hour after lúc / at, not an amount or a length).
  for (const x of f.matchAll(
    /(?<![\p{L}])(?:luc|at)\s+(\d{1,2})(?![\d:.,]|\s*(?:ml|oz|phut|p\b|tieng|gio|h\b|g\b|kg|cm|k\b|%|lan|cu|ngay|thang))/gu,
  )) {
    const at = x.index + x[0].lastIndexOf(x[1]!);
    add(at, x[1]!.length, Number(x[1]), 0, x[1]!);
  }
  if (/(?<![\p{L}])(?:nua dem|midnight)(?![\p{L}])/u.test(f) && out.length === 0) {
    const i = f.search(/nua dem|midnight/);
    out.push({ h: 0, m: 0, hours: [0], index: i, text: 'nua dem' });
  }
  return out.sort((a, b) => a.index - b.index);
}

// ---- Pump, diaper, growth in the words (LUMI-01 backstops) ----

/** "hút sữa", "hút được 80ml", "vắt sữa", "pumped", "expressed": pumping, never a feed. */
export function pumpCueIn(text: string): boolean {
  const f = foldVi(text);
  return (
    /(?<![\p{L}])(?:hut sua|hut duoc|hut ra|hut \d|hut (?:ca )?(?:hai|2) ben|hut ben|vat sua|vat duoc|vat ra|may hut)(?![\p{L}])/u.test(
      f,
    ) || /\b(?:pump(?:ed|ing)?|expressed|breast pump)\b/u.test(f)
  );
}

/**
 * A diaper change in the words and what was in it: "thay tã ướt" → wet, "bé vừa ị" / "tã bẩn" /
 * "poop" → dirty, "cả hai" / "ướt và bẩn" → both, "thay tã" alone → null (the person picks).
 * Buying diapers ("mua bỉm 200k") is money, not a change: null.
 */
export function diaperIn(text: string): { kind: 'wet' | 'dirty' | 'both' | null } | null {
  const f = foldVi(text);
  const lower = lowerVi(text);
  if (looksLikeSpending(text)) return null;
  const change =
    /(?<![\p{L}])(?:thay (?:ta|bim|bim cho be|ta cho be)|ta uot|ta ban|bim uot|bim ban|di ve sinh|di tieu|di nang|di phan)(?![\p{L}])/u.test(
      f,
    ) ||
    /(?<![\p{L}])(?:ị|tè|đi ị|đi tè|tã|bỉm)(?![\p{L}])/u.test(lower) ||
    /\b(?:diaper|nappy|nappies|diapers|pooped|poop|poo|peed|pee|wee)\b/u.test(f);
  if (!change) return null;
  const wet =
    /(?<![\p{L}])(?:uot|tieu)(?![\p{L}])/u.test(f) ||
    /(?<![\p{L}])tè(?![\p{L}])/u.test(lower) ||
    /\b(?:wet|pee|peed|wee)\b/u.test(f);
  const dirty =
    /(?<![\p{L}])(?:ban|phan|di nang|di cau)(?![\p{L}])/u.test(f) ||
    /(?<![\p{L}])ị(?![\p{L}])/u.test(lower) ||
    /\b(?:dirty|poop|pooped|poo|soiled|bm)\b/u.test(f);
  const both =
    /(?<![\p{L}])(?:ca hai|ca 2|ca uot (?:va|lan) ban)(?![\p{L}])/u.test(f) || (wet && dirty);
  return { kind: both ? 'both' : wet ? 'wet' : dirty ? 'dirty' : null };
}

export interface GrowthMeasure {
  weightKg: number | null;
  lengthCm: number | null;
  /** "vòng đầu 40cm" / "head 40 cm" (saved with the growth record since 2026-10-16). */
  headCm: number | null;
}

/**
 * Measurements in the words: "nặng 5,2kg", "5kg2" (5.2), "6.1 kg", "5200g", "5 cân 2", "weighs
 * 5.4 kg"; "dài 62cm", "cao 62 phân", "length 60 cm"; "vòng đầu 40cm". Null when none.
 */
export function growthIn(text: string): GrowthMeasure | null {
  const f = foldVi(text);
  let weightKg: number | null = null;
  let lengthCm: number | null = null;
  let headCm: number | null = null;
  const kg =
    /(?<![\d.,])(\d{1,2}(?:[.,]\d{1,3})?)\s*(?:kg|kgs|ky|ki|ki lo|kilo|kilogram|kilograms|can)(?:\s*(\d{1,3})(?!\d|[.,]\d|\s*(?:cm|g\b|gr)))?(?![\p{L}])/u.exec(
      f,
    );
  if (kg) {
    const base = Number(kg[1]!.replace(',', '.'));
    // "5kg2" = 5.2 kg, "5kg250" = 5.25 kg (the grams after the kilos).
    weightKg = kg[2] ? base + Number(`0.${kg[2]}`) : base;
  } else {
    const g = /(?<![\d.,])(\d{3,5})\s*(?:g|gr|gram|grams|gam)(?![\p{L}])/u.exec(f);
    if (g && /(?<![\p{L}])(?:nang|can|weigh\w*|cân)(?![\p{L}])/u.test(f))
      weightKg = Number(g[1]) / 1000;
  }
  const head =
    /(?<![\p{L}])(?:vong dau|chu vi dau|head(?: circumference)?)\D{0,12}(\d{2}(?:[.,]\d)?)\s*(?:cm|phan)?/u.exec(
      f,
    );
  if (head) headCm = Number(head[1]!.replace(',', '.'));
  for (const m of f.matchAll(
    /(?<![\d.,])(\d{2,3}(?:[.,]\d)?)\s*(?:cm|centimet\w*|phan)(?![\p{L}])/gu,
  )) {
    if (head && m.index >= head.index && m.index <= head.index + head[0].length) continue;
    lengthCm = Number(m[1]!.replace(',', '.'));
    break;
  }
  if (lengthCm === null) {
    const len =
      /(?<![\p{L}])(?:dai|cao|chieu dai|length|long|tall)\s*(?:duoc|la|is)?\s*(\d{2,3}(?:[.,]\d)?)(?![\d])/u.exec(
        f,
      );
    if (len && !/kg|ky|can/.test(f.slice(len.index, len.index + len[0].length + 4))) {
      lengthCm = Number(len[1]!.replace(',', '.'));
    }
  }
  if (weightKg === null && lengthCm === null && headCm === null) return null;
  const one = (n: number | null) => (n === null ? null : Math.round(n * 10) / 10);
  return { weightKg: one(weightKg), lengthCm: one(lengthCm), headCm: one(headCm) };
}

/**
 * LUMI-15: "bé bu 120m" — a number with a bare "m" after a feed word is millilitres or minutes.
 * Returns the number when it reads as a bottle amount (≥ 50, no "mẹ" / "ti" / breast word), so a
 * typo never becomes a two-hour breastfeed.
 */
export function bareMAmountIn(text: string): number | null {
  const f = foldVi(text);
  const m = /(?<![\d.,])(\d{2,3})\s*m(?![\p{L}\d])/u.exec(f);
  if (!m) return null;
  const n = Number(m[1]);
  if (n < 50) return null;
  if (/(?<![\p{L}])(?:bu me|ti me|me|ti|breast|nursing|nursed)(?![\p{L}])/u.test(f)) return null;
  return n;
}

/** "Lumi làm được gì?", "bạn giúp được gì", "what can you do": what Lumi does (HELP, free). */
export function asksWhatLumiDoes(text: string): boolean {
  const f = foldVi(text)
    .replace(/[?!.]+/g, ' ')
    .trim();
  return (
    /(?<![\p{L}])(?:lam duoc gi|giup duoc gi|biet lam gi|lam gi duoc|co the lam gi|giup gi duoc|dung the nao|dung nhu the nao|huong dan su dung)(?![\p{L}])/u.test(
      f,
    ) ||
    /\b(?:what can you do|what do you do|how do i use|how does this work|what are you)\b/u.test(f)
  );
}

/** Words of a question about logged care data (feeds, sleep, diapers…), for read checks. */
export function asksAboutCare(text: string): boolean {
  const f = foldVi(text);
  return /(?<![\p{L}])(?:bu|ngu|an|uong|ta|bim|giac|cu|sleep|slept|feed|fed|nap|diaper|bottle|ml)(?![\p{L}])/u.test(
    f,
  );
}

/** "còn bao nhiêu lượt", "credits": a question about the assistant's credits. */
export function asksAboutCredits(text: string): boolean {
  const f = foldVi(text);
  return /(?<![\p{L}])(?:luot|credit|credits|han muc|quota)(?![\p{L}])/u.test(f);
}

/**
 * LUMI-10: a sleep CONCERN to get guidance for ("dạo này bé khó ngủ về đêm", "bé hay thức đêm 3
 * hôm nay", "bé khó ngủ quá") — not a note about one sleep ("đêm qua bé thức giấc 2 lần" with a
 * day said is an observation). Returns what the words say, each fact only when said.
 */
export function sleepConcernIn(text: string): {
  kind: 'falling_asleep' | 'night_waking' | 'both' | null;
  when: 'night' | 'day' | 'both' | null;
} | null {
  const f = foldVi(text);
  const falling =
    /(?<![\p{L}])(?:kho ngu|kho vao giac|kho du ngu|lau ngu|khong chiu ngu|trouble (?:falling|getting) (?:asleep|to sleep)|hard to (?:get to )?sleep|won'?t (?:fall asleep|go to sleep|sleep))(?![\p{L}])/u.test(
      f,
    );
  const waking =
    /(?<![\p{L}])(?:hay thuc|thuc giac|thuc dem|giat minh|day dem|wak(?:es|ing) (?:up )?(?:at night|often|a lot)|night waking)(?![\p{L}])/u.test(
      f,
    );
  if (!falling && !waking) return null;
  // One sleep on a said day is a note (observation), not a concern.
  if (
    /(?<![\p{L}])(?:dem qua|toi qua|hom qua|trua nay|sang nay|last night|yesterday)(?![\p{L}])/u.test(
      f,
    ) &&
    !/(?<![\p{L}])(?:dao nay|may hom|may dem|gan day|lately|recently|hay|thuong|luon|every night)(?![\p{L}])/u.test(
      f,
    )
  ) {
    return null;
  }
  const night = /(?<![\p{L}])(?:dem|ve dem|ban dem|toi|night|at night)(?![\p{L}])/u.test(f);
  const day = /(?<![\p{L}])(?:ngay|ban ngay|trua|nap|naps|giac ngay)(?![\p{L}])/u.test(f);
  return {
    kind: falling && waking ? 'both' : falling ? 'falling_asleep' : 'night_waking',
    when: night && day ? 'both' : night ? 'night' : day ? 'day' : null,
  };
}

/** Words that the message is about sleep at all ("ngủ", "giấc", "thức", "sleep", "nap"). */
export function mentionsSleep(text: string): boolean {
  return /(?<![\p{L}])(?:ngu|giac|thuc|sleep|slept|nap|naps|asleep|waking|wakes)(?![\p{L}])/u.test(
    foldVi(text),
  );
}

/** A feeding concern ("biếng ăn", "ăn ít", "bú ít hơn"): an observation about feeding. */
export function feedingConcernIn(text: string): boolean {
  return /(?<![\p{L}])(?:bieng an|bieng bu|an it|bu it|an kem|bu kem|luoi an|luoi bu|an khong ngon|eats? less|eating less|feeding less|poor appetite)(?![\p{L}])/u.test(
    foldVi(text),
  );
}

// ---------- Purchases (LUMI-16, owner 2026-10-16) ----------

/** Whether a purchase in the words was made, is planned / a to-do, or is asked about. */
export type PurchaseMood = 'done' | 'plan' | 'question';

export interface Purchase {
  mood: PurchaseMood;
  /** The words from the verb on ("mua hai hộp sữa", "đặt tã online"), lower case, ≤ 60. */
  phrase: string;
  /** The words as a to-do ("mua sữa", "buy diapers"): the phrase without a trailing day / price. */
  title: string;
  /** What was bought ("hai hộp sữa", "tã"), without the store; null when nothing follows. */
  what: string | null;
  /** "ở Con Cưng" / "tại Kids Plaza" / "at Target" → the store's words as written. */
  merchant: string | null;
}

/** A word in folded text, or (in a text with diacritics) only as written with its marks. */
type Cue = readonly [marked: string, folded: string | null];

const buyCues: readonly Cue[] = [
  ['mua', 'mua'],
  ['đặt mua', 'dat mua'],
  ['đặt hàng', 'dat hang'],
  ['đặt online', 'dat online'],
  ['đặt tã', 'dat ta'],
  ['đặt bỉm', 'dat bim'],
  ['đặt sữa', 'dat sua'],
  ['đặt đồ', 'dat do'],
  ['đặt khăn', 'dat khan'],
  ['đặt quần áo', 'dat quan ao'],
  ['order', 'order'],
  ['ordered', 'ordered'],
  ['bought', 'bought'],
  ['buy', 'buy'],
  ['buying', 'buying'],
  ['purchase', 'purchase'],
  ['purchased', 'purchased'],
];

/**
 * A plan, a to-do or a purchase that did not happen ("nhớ mua", "cần mua", "sẽ mua", "chưa mua",
 * "quên mua", "need to buy"): never an expense, whatever day is said.
 */
const planCues: readonly Cue[] = [
  ['nhớ', 'nho mua'],
  ['nhắc', 'nhac'],
  ['cần', 'can mua'],
  ['cần đặt', 'can dat'],
  ['phải mua', 'phai mua'],
  ['muốn mua', 'muon mua'],
  ['chưa mua', 'chua mua'],
  ['quên mua', 'quen mua'],
  ['không mua', 'khong mua'],
  ['sẽ', null],
  ['định', 'dinh mua'],
  ['sắp', 'sap mua'],
  ['để mua', 'de mua'],
  ['need to', 'need to'],
  ['needs to', 'needs to'],
  ['have to', 'have to'],
  ['has to', 'has to'],
  ['will', 'will'],
  ['going to', 'going to'],
  ['gonna', 'gonna'],
  ['remember', 'remember'],
  ['remind', 'remind'],
  ['plan to', 'plan to'],
  ['want to', 'want to'],
  ['forgot', 'forgot'],
];

/**
 * A later day or time ("ngày mai", "tuần sau", "lát nữa", "tomorrow"): a plan unless a past day
 * is said too. A bare "mai" / "mốt" counts only before the buying word ("mai đi mua sữa"), so
 * "mua sữa cho bé Mai" is not a plan.
 */
const laterCues: readonly Cue[] = [
  ['ngày mai', 'ngay mai'],
  ['sáng mai', 'sang mai'],
  ['trưa mai', 'trua mai'],
  ['chiều mai', 'chieu mai'],
  ['tối mai', 'toi mai'],
  ['tuần sau', 'tuan sau'],
  ['tháng sau', 'thang sau'],
  ['lát nữa', 'lat nua'],
  ['tí nữa', 'ti nua'],
  ['chút nữa', 'chut nua'],
  ['tomorrow', 'tomorrow'],
  ['later', 'later'],
  ['next week', 'next week'],
];
const laterBeforeVerb: readonly Cue[] = [
  ['mai', 'mai'],
  ['mốt', null],
];

/** It happened: these win over every plan word ("vừa mua", "đã mua", "mua rồi", "just bought"). */
const doneCues: readonly Cue[] = [
  ['vừa', 'vua'],
  ['mới mua', 'moi mua'],
  ['đã', 'da mua'],
  ['rồi', 'roi'],
  ['xong', 'xong'],
  ['lúc nãy', null],
  ['hồi nãy', null],
  ['ban nãy', null],
  ['just', 'just'],
  ['already', 'already'],
  ['bought', 'bought'],
  ['ordered', 'ordered'],
  ['purchased', 'purchased'],
  ['got', 'got'],
];

/** A day already gone or today ("hôm qua", "sáng nay"): no "later" plan then. */
const pastDayCues: readonly Cue[] = [
  ['hôm qua', 'hom qua'],
  ['hôm kia', 'hom kia'],
  ['hôm nay', 'hom nay'],
  ['sáng nay', 'sang nay'],
  ['trưa nay', 'trua nay'],
  ['chiều nay', 'chieu nay'],
  ['today', 'today'],
  ['yesterday', 'yesterday'],
];

/** Asking which / where / whether to buy ("mua sữa nào tốt", "nên mua bỉm gì"). */
const questionCues: readonly Cue[] = [
  ['nào', 'nao'],
  ['gì', 'gi'],
  ['ở đâu', 'o dau'],
  ['có nên', 'co nen'],
  ['nên mua', 'nen mua'],
  ['nên chọn', 'nen chon'],
  ['tốt không', 'tot khong'],
  ['được không', 'duoc khong'],
  ['bao nhiêu', 'bao nhieu'],
  ['which', 'which'],
  ['what', 'what'],
  ['where', 'where'],
  ['should', 'should'],
  ['recommend', 'recommend'],
];

const cueRe = (w: string) =>
  new RegExp(String.raw`(?<![\p{L}\d])${w.replace(/\s+/g, String.raw`\s+`)}(?![\p{L}])`, 'u');

/** Where the first of [cues] is in a clause ([lower] / [folded] of the same text), or -1. */
function cueAt(cues: readonly Cue[], lower: string, folded: string, marked: boolean): number {
  let at = -1;
  for (const [m, f] of cues) {
    // With diacritics the word must be written with its marks ("mua", never "mưa" / "múa");
    // without any, the folded spelling is taken as written.
    const hit =
      (marked ? cueRe(m).exec(lower) : null) ?? (f && !marked ? cueRe(f).exec(folded) : null);
    if (hit && (at < 0 || hit.index < at)) at = hit.index;
  }
  return at;
}

const storeRe = /(?<![\p{L}])(?:ở|tại|o|tai|at|from|on)\s+(.+)$/u;
const tailRe =
  /\s*(?:(?<![\p{L}])(?:hết|het|mất|mat|giá|gia|tổng|tong|cost|for)(?![\p{L}]).*|(?<![\p{L}])(?:hôm nay|hom nay|hôm qua|hom qua|ngày mai|ngay mai|tối nay|toi nay|tomorrow|today|yesterday|tonight|next week|mai)(?:\s+(?:nhé|nhe|nha|nhá))?)\s*$/u;

/**
 * LUMI-16 (owner 2026-10-16): the purchases in [text], one per clause with a buying word ("mua",
 * "đặt hàng / tã…", "order", "bought"): done ("mua hai hộp sữa", "vừa mua bỉm ở Con Cưng", "đặt
 * tã online") — an expense even without an amount —, a plan or a to-do ("mai đi mua sữa", "nhớ
 * mua bỉm", "cần mua…") — a reminder or nothing —, or a question ("mua sữa nào tốt?") — help,
 * never an expense. A "?" makes the clause a question; a plan word wins over a done word only
 * when no done word is said; a question word counts only without an amount or a done word.
 */
export function purchasesIn(text: string): Purchase[] {
  const lower = lowerVi(text);
  const folded = foldVi(text);
  const marked = lower !== folded;
  const out: Purchase[] = [];
  // Clauses: punctuation, "và", "nhưng", "and", "but"; each keeps its own "?".
  const sep = /(?<!\d)[,.](?!\d)|[;!?\n]|\s(?:và|va|nhưng|nhung|and|but|then)\s/gu;
  let start = 0;
  const clauses: { from: number; to: number; asked: boolean }[] = [];
  for (const m of folded.matchAll(sep)) {
    clauses.push({ from: start, to: m.index, asked: m[0] === '?' });
    start = m.index + m[0].length;
  }
  clauses.push({ from: start, to: folded.length, asked: false });
  for (const c of clauses) {
    const l = lower.slice(c.from, c.to);
    const f = folded.slice(c.from, c.to);
    const verb = cueAt(buyCues, l, f, marked);
    if (verb < 0) continue;
    const phrase = l.slice(verb).trim().replace(/\s+/g, ' ').slice(0, 60);
    // What follows the verb ("đặt tã online" → "tã online"; "mua hai hộp sữa" → "hai hộp sữa").
    const verbWord =
      /^(?:đặt|dat|mua|order(?:ed)?|bought|buy(?:ing)?|purchased?)\s*(?:mua\s+|hàng\s+|hang\s+)?/u;
    let rest = phrase.replace(verbWord, '').trim();
    let merchant: string | null = null;
    const store = storeRe.exec(rest);
    if (store && store.index > 0) {
      merchant = store[1]!.replace(tailRe, '').trim().slice(0, 60) || null;
      // As written in the message (its case), from the same place.
      if (merchant) {
        const at = l.indexOf(merchant);
        merchant =
          at >= 0
            ? text.normalize('NFC').slice(c.from + at, c.from + at + merchant.length)
            : merchant;
      }
      rest = rest.slice(0, store.index).trim();
    }
    // An amount said with it ("bỉm 350.000đ") is the price, not what was bought.
    const price = moneyAmountsIn(rest)[0];
    if (price) rest = rest.slice(0, price.index);
    rest = rest.replace(tailRe, '').trim();
    const what = rest.length > 0 ? rest.slice(0, 60) : null;
    const amount = moneyAmountsIn(text.slice(c.from, c.to)).length > 0;
    const done = cueAt(doneCues, l, f, marked) >= 0;
    const before = cueAt(laterBeforeVerb, l, f, marked);
    const later =
      (cueAt(laterCues, l, f, marked) >= 0 || (before >= 0 && before < verb)) &&
      cueAt(pastDayCues, l, f, marked) < 0;
    const plan = cueAt(planCues, l, f, marked) >= 0 || later;
    const question = !done && !amount && cueAt(questionCues, l, f, marked) >= 0;
    const mood: PurchaseMood = c.asked
      ? 'question'
      : done
        ? 'done'
        : plan
          ? 'plan'
          : question
            ? 'question'
            : 'done';
    out.push({ mood, phrase, title: phrase.replace(tailRe, '').trim() || phrase, what, merchant });
  }
  return out;
}
