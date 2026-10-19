import {
  agoIn,
  bareMAmountIn,
  bottleMlIn,
  breastSideIn,
  careStatesIn,
  clockTokensIn,
  diaperIn,
  durationsIn,
  foldVi,
  growthIn,
  hasVietnameseMarks,
  looksLikeSpending,
  mentionsMedicine,
  observationCueIn,
  pumpCueIn,
  sleepConcernIn,
  type ClockToken,
} from '@child-life/contracts';
import type { IntentFieldName, ModelExtraction, ModelIntent } from './assistant-model.js';

/**
 * Lumi L2 (D-088 §4.4, P-167 #4): the rule reader for routine logs. A message that is ONE plain
 * log — a bottle with its ml, a breastfeed with its minutes / side, a wet or dirty diaper, a
 * sleep start / stop / span / length, a pump with its ml, a weight / length / head — is read here
 * into the same extraction the model returns, so `planTextIntents` and everything after it run
 * unchanged, with no model call and 0 credits (owner, 2026-10-19).
 *
 * The reader is deliberately narrow: every word of the message must be one it knows for that
 * kind, every number must belong to an amount, a time or a length it read, and anything else (a
 * question, a correction, money, medicine, a concern, two events, English, "lúc nãy", "được 5p
 * rồi" with "đang") returns null and the model reads the message as before. It writes what a
 * correct model writes under the extraction prompt (hours 1–11 without a period word as said, the
 * server decides morning or evening). Pure: no reads, no logs.
 */

export interface RuleReadInput {
  text: string;
  /** The baby's zone and the task's send instant ("today" and "vừa"). */
  zone: string;
  anchor: Date;
}

type Kind = 'bottle' | 'breast' | 'pump' | 'diaper' | 'growth' | 'sleep';

/** Longest message the reader looks at (a routine log is short; voice run-ons go to the model). */
const maxChars = 80;

/** Folded words any routine log may carry ([] = any spelling; else the accepted marked forms). */
const filler: Record<string, string[]> = {
  be: [],
  con: [],
  em: [],
  nha: [],
  nhe: [],
  a: ['à', 'ạ', 'a'],
  roi: ['rồi'],
  rui: [],
  da: ['đã'],
  duoc: ['được'],
  luc: ['lúc'],
  vao: ['vào'],
  khoang: ['khoảng'],
  tam: ['tầm'],
  cho: [],
  thi: ['thì'],
  // Time words (the clock tokens themselves are masked before the words are checked).
  hom: ['hôm'],
  nay: ['nay'],
  qua: ['qua'],
  kia: ['kia'],
  sang: ['sáng'],
  trua: ['trưa'],
  chieu: ['chiều'],
  toi: ['tối', 'tới'],
  dem: ['đêm'],
  khuya: [],
  nua: ['nửa'],
  vua: ['vừa'],
  moi: ['mới'],
  truoc: ['trước'],
  gio: ['giờ'],
  xong: [],
};

const vocab: Record<Kind, Record<string, string[]>> = {
  bottle: {
    bu: ['bú'],
    binh: ['bình'],
    uong: ['uống'],
    sua: ['sữa'],
    cong: ['công'],
    thuc: ['thức'],
    bot: ['bột'],
    me: ['mẹ'],
    vat: ['vắt'],
    de: ['dê'],
    tuoi: ['tươi'],
    cu: ['cữ'],
  },
  breast: {
    bu: ['bú'],
    ti: [],
    me: ['mẹ'],
    ben: ['bên'],
    trai: ['trái'],
    phai: ['phải'],
    hai: [],
    ca: ['cả'],
    dang: ['đang'],
    van: ['vẫn'],
    bat: ['bắt'],
    dau: ['đầu'],
  },
  pump: {
    hut: ['hút'],
    vat: ['vắt'],
    sua: ['sữa'],
    may: ['máy'],
    ra: [],
    ben: ['bên'],
    trai: ['trái'],
    phai: ['phải'],
    hai: [],
    ca: ['cả'],
  },
  diaper: {
    thay: [],
    ta: ['tã'],
    bim: ['bỉm'],
    uot: ['ướt'],
    ban: ['bẩn'],
    i: ['ị'],
    te: ['tè'],
    di: ['đi'],
    tieu: ['tiểu'],
    phan: ['phân'],
    ca: ['cả'],
    hai: [],
    va: ['và'],
    lan: ['lẫn'],
  },
  growth: {
    can: ['cân'],
    nang: ['nặng'],
    dai: ['dài'],
    cao: [],
    vong: ['vòng'],
    dau: ['đầu'],
    chu: ['chu'],
    vi: ['vi'],
    va: ['và'],
  },
  sleep: {
    ngu: ['ngủ'],
    giac: ['giấc'],
    ngay: ['ngày'],
    day: ['dậy'],
    tu: ['từ'],
    den: ['đến'],
    dang: ['đang'],
    van: ['vẫn'],
    bat: ['bắt'],
    dau: ['đầu'],
    thiep: ['thiếp'],
    say: [],
  },
};

const W = (alts: string) => new RegExp(String.raw`(?<![\p{L}])(?:${alts})(?![\p{L}])`, 'u');
/** "lúc nãy" is vague (no time), "cách đây" / "được X rồi" are the ongoing-state reader's (L1). */
const handOff = W('luc nay|cach day|hoi nay|nay gio');
const dayBack = W('hom qua|toi qua|dem qua|sang qua|chieu qua|trua qua');
const twoDaysBack = W('hom kia');
const today = W('hom nay|sang nay|chieu nay|toi nay|trua nay');
const sleepStartAt =
  /(?:ngu|ngu luc|ngu tu|ngu vao|ngu vao luc|ngu khoang|bat dau ngu luc|bat dau ngu|tu|ngu trua tu|ngu trua luc|ngu ngay tu|ngu ngay luc)\s*$/u;
const wakeAt = /(?:day|day luc|day vao|day vao luc|day khoang|thuc day luc)\s*$/u;
const doneAt = /(?:xong|xong luc|xong vao luc|xong vao|xong khoang)\s*$/u;
const spanBetween = /^\s*(?:(?:sang|trua|chieu|toi|dem|khuya)\s+)?(?:den|toi|-|–)(?:\s+luc)?\s*$/u;

interface Span {
  index: number;
  len: number;
}

const blankIntent = (kind: Kind): ModelIntent => ({
  kind,
  fields: {
    amountMl: null,
    milk: null,
    time: null,
    dayOffset: null,
    endTime: null,
    endDayOffset: null,
    durationMin: null,
    side: null,
    observation: null,
    when: null,
    note: null,
    title: null,
    amount: null,
    currency: null,
    categoryId: null,
    merchant: null,
    date: null,
    assigneeText: null,
    phase: null,
    diaper: null,
    weightKg: null,
    lengthCm: null,
    headCm: null,
  },
  correctsPrevious: false,
  evidence: [],
  uncertainFields: [],
  missingFields: [],
});

const pad = (n: number) => String(n).padStart(2, '0');
const lenSpan = (d: { index: number; text: string }): Span => ({
  index: d.index,
  len: d.text.length,
});

function localClockOf(zone: string, at: Date): { h: number; m: number } {
  const [h, m] = new Intl.DateTimeFormat('en-GB', {
    timeZone: zone,
    hourCycle: 'h23',
    hour: '2-digit',
    minute: '2-digit',
  })
    .format(at)
    .split(':')
    .map(Number) as [number, number];
  return { h, m };
}

/** One routine log read from [input.text], or null when the model must read it. */
export function ruleReadText(input: RuleReadInput): ModelExtraction | null {
  const text = input.text.normalize('NFC').trim();
  if (text.length === 0 || text.length > maxChars) return null;
  const lower = text.toLocaleLowerCase('vi');
  const f = foldVi(text);
  // Evidence and marked-word checks slice the original at folded indexes.
  if (lower.length !== f.length) return null;
  const marks = hasVietnameseMarks(text);
  if (/[?]/.test(text) || /\n/.test(text)) return null;
  if (looksLikeSpending(text) || mentionsMedicine(text)) return null;
  if (observationCueIn(text) || sleepConcernIn(text) || handOff.test(f)) return null;

  const kind = kindOf(text, f);
  if (!kind) return null;

  // ---- What the message says, each with the words it was read from ----
  const masked: Span[] = [];
  const tokens = clockTokensIn(text);
  for (const t of tokens) masked.push({ index: t.index, len: t.text.length });
  if (/(?<![\p{L}])nua dem(?![\p{L}])/u.test(f)) {
    const i = f.search(/nua dem/);
    masked.push({ index: i, len: 'nua dem'.length });
  }
  const ago = agoIn(text);
  const agoAt = ago && !ago.justNow ? f.indexOf(ago.text) : -1;
  if (agoAt >= 0) masked.push({ index: agoAt, len: ago!.text.length });
  // A length inside "2 tiếng trước" is the time, not the log's length.
  const durations = durationsIn(text).filter(
    (d) => agoAt < 0 || d.index < agoAt || d.index >= agoAt + ago!.text.length,
  );
  for (const d of durations) masked.push({ index: d.index, len: d.text.length });
  const ml = mlSpan(f);
  if (ml) masked.push(ml);
  const bareM = ml ? null : bareMSpan(f);
  if (bareM) masked.push(bareM);
  for (const s of growthSpans(f)) masked.push(s);
  const side2 = /(?<![\p{L}])(?:ca\s+)?2\s+ben(?![\p{L}])/u.exec(f);
  if (side2) masked.push({ index: side2.index, len: side2[0].length });

  // Every word is one this kind knows; every number was read.
  const chars = [...f];
  for (const s of masked) for (let i = s.index; i < s.index + s.len; i++) chars[i] = ' ';
  const rest = chars.join('');
  if (/\d/.test(rest)) return null;
  const allowed = { ...filler, ...vocab[kind] };
  for (const w of rest.matchAll(/[\p{L}]+/gu)) {
    const forms = allowed[w[0]];
    if (!forms) return null;
    if (marks && forms.length > 0) {
      const said = lower.slice(w.index, w.index + w[0].length);
      if (!forms.includes(said)) return null;
    }
  }

  const ev = (s: Span) => text.slice(s.index, s.index + s.len).trim();
  const anchor = localClockOf(input.zone, input.anchor);
  const anchorMin = anchor.h * 60 + anchor.m;
  const dayWord = dayBack.test(f) ? -1 : twoDaysBack.test(f) ? -2 : today.test(f) ? 0 : null;
  // Only "vừa" / "vừa xong" and "2 tiếng trước" are read here; any other "ago" is the model's.
  const agoOk =
    ago === null ||
    (ago.justNow && /^(?:vua|vua xong|vua moi)$/u.test(ago.text)) ||
    (!ago.justNow && /(?<![\p{L}])truoc(?![\p{L}])/u.test(f));
  if (!agoOk) return null;
  if (ago && tokens.length > 0) return null;
  if (ago && !ago.justNow && dayWord !== null) return null;

  /** "HH:mm" as a correct model writes it, its day offset, and whether the half is known. */
  const clock = (t: ClockToken) => {
    const one = t.hours.length === 1;
    const h = one ? t.hours[0]! : t.h;
    const min = h * 60 + t.m;
    return { hhmm: `${pad(h)}:${pad(t.m)}`, min, explicit: one };
  };
  const offsetFor = (c: { min: number; explicit: boolean }): number | null => {
    if (dayWord !== null) {
      // "đêm qua lúc 2h" may be after midnight (today): the model decides.
      if (dayWord === -1 && c.explicit && c.min < 6 * 60) return null;
      return dayWord;
    }
    // A clock later than now: last night, or a time typed by mistake — the model decides.
    return c.explicit && c.min > anchorMin ? null : 0;
  };
  const agoClock = () => {
    const at = anchorMin - (ago?.minutes ?? 0);
    const day = at < 0 ? -1 : 0;
    const m = ((at % 1440) + 1440) % 1440;
    return { hhmm: `${pad(Math.floor(m / 60))}:${pad(m % 60)}`, day };
  };
  const agoEvidence = () => {
    if (!ago) return '';
    const i = f.indexOf(ago.text);
    return i >= 0 ? text.slice(i, i + ago.text.length) : ago.text;
  };

  const intent = blankIntent(kind);
  const set = (field: IntentFieldName, value: unknown, evidence: string | null) => {
    (intent.fields as Record<string, unknown>)[field] = value;
    if (evidence) intent.evidence.push({ field, text: evidence });
  };
  /** One time for a log (or none: asked by the server). */
  const oneTime = (field: 'time' | 'endTime' = 'time'): boolean => {
    const offField = field === 'time' ? 'dayOffset' : 'endDayOffset';
    if (tokens.length > 1) return false;
    if (tokens.length === 1) {
      const t = tokens[0]!;
      const c = clock(t);
      const off = offsetFor(c);
      if (off === null) return false;
      set(field, c.hhmm, ev({ index: t.index, len: t.text.length }));
      set(offField, off, null);
      return true;
    }
    if (ago) {
      const a = agoClock();
      set(field, a.hhmm, agoEvidence());
      set(offField, a.day, null);
      return true;
    }
    if (dayWord !== null) set(offField, dayWord, null);
    return true;
  };
  const needsTime = () => {
    if (intent.fields.time === null && intent.fields.endTime === null) {
      intent.missingFields.push('time');
    }
  };

  switch (kind) {
    case 'bottle': {
      if (durations.length > 0) return null;
      if (ml) set('amountMl', bottleMlIn(text)!.ml, ev(ml));
      else if (bareM) set('amountMl', bareMAmountIn(text), ev(bareM));
      else intent.missingFields.push('amountMl');
      const milk = /(?<![\p{L}])(?:sua cong thuc|cong thuc|sua bot)(?![\p{L}])/u.test(f)
        ? 'formula'
        : /(?<![\p{L}])(?:sua me|sua vat)(?![\p{L}])/u.test(f)
          ? 'breast_milk'
          : /(?<![\p{L}])(?:sua de|sua tuoi)(?![\p{L}])/u.test(f)
            ? 'other'
            : null;
      if (milk) set('milk', milk, null);
      if (!oneTime()) return null;
      needsTime();
      break;
    }
    case 'breast': {
      const states = careStatesIn(text).filter((s) => s.timer === 'breast');
      const side = breastSideIn(text);
      if (states.length === 1) {
        // "đang cho bú bên trái", "bú xong rồi": the app's timer (no length said).
        if (durations.length > 0 || tokens.length > 0 || ago) return null;
        set('phase', states[0]!.action, sideEvidence(text, f, states[0]!.text));
        if (side) set('side', side, sideEvidence(text, f, null));
        break;
      }
      if (/(?<![\p{L}])dang(?![\p{L}])/u.test(f)) return null;
      if (durations.length > 1) return null;
      if (durations[0]) set('durationMin', durations[0].minutes, ev(lenSpan(durations[0])));
      if (side) set('side', side, sideEvidence(text, f, null));
      // "bú 15 phút bên trái, xong lúc 8h sáng": the end of the feed.
      const endAt = tokens.length === 1 && doneAt.test(f.slice(0, tokens[0]!.index).trimEnd());
      if (!oneTime(endAt ? 'endTime' : 'time')) return null;
      needsTime();
      break;
    }
    case 'pump': {
      if (durations.length > 1) return null;
      if (ml) set('amountMl', bottleMlIn(text)!.ml, ev(ml));
      if (durations[0]) set('durationMin', durations[0].minutes, ev(lenSpan(durations[0])));
      const side = breastSideIn(text);
      if (side) set('side', side, sideEvidence(text, f, null));
      if (!ml && !durations[0]) intent.missingFields.push('amountMl');
      if (!oneTime()) return null;
      needsTime();
      break;
    }
    case 'diaper': {
      if (durations.length > 0) return null;
      const d = diaperIn(text);
      if (!d) return null;
      if (d.kind) set('diaper', d.kind, diaperEvidence(text, f, d.kind));
      if (!oneTime()) return null;
      needsTime();
      break;
    }
    case 'growth': {
      if (tokens.length > 0 || durations.length > 0 || ago) return null;
      const g = growthIn(text);
      if (!g) return null;
      const spans = growthSpans(f);
      const byKind = (k: GrowthSpan['kind']) => spans.find((s) => s.kind === k);
      if (g.weightKg !== null) set('weightKg', g.weightKg, ev(byKind('weight') ?? spans[0]!));
      if (g.lengthCm !== null) set('lengthCm', g.lengthCm, ev(byKind('length') ?? spans[0]!));
      if (g.headCm !== null) set('headCm', g.headCm, ev(byKind('head') ?? spans[0]!));
      if (dayWord !== null) set('dayOffset', dayWord, null);
      break;
    }
    case 'sleep': {
      if (!readSleep()) return null;
      break;
    }
  }
  return {
    intents: [intent],
    reads: [],
    clarification: null,
    care: null,
    smallTalk: false,
    outOfScope: false,
  };

  /** Sleep: a span, a start, a wake-up, a length; never an ongoing state with a length (L1). */
  function readSleep(): boolean {
    const states = careStatesIn(text).filter((s) => s.timer === 'sleep');
    const state = states[0] ?? null;
    const woke = /(?<![\p{L}])(?:ngu day|day)(?![\p{L}])/u.test(f);
    const ongoing = /(?<![\p{L}])(?:dang|van)(?![\p{L}])/u.test(f);
    if (durations.length > 1) return false;
    const dur = durations[0] ?? null;
    if (ago && !ago.justNow) return false;
    if (tokens.length === 2) {
      // "từ 13h đến 14h", "đêm qua từ 9h tối đến 6h sáng".
      if (dur || ago || woke || ongoing || state) return false;
      const [a, b] = [tokens[0]!, tokens[1]!];
      const between = f.slice(a.index + a.text.length, b.index);
      if (!spanBetween.test(between)) return false;
      if (!sleepStartAt.test(f.slice(0, a.index).trimEnd())) return false;
      const ca = clock(a);
      const cb = clock(b);
      let startOff: number;
      let endOff: number;
      const overnight = ca.explicit && cb.explicit && ca.min > cb.min;
      if (!ca.explicit || !cb.explicit) {
        startOff = endOff = dayWord ?? 0;
      } else if (overnight) {
        if (dayWord === -1 && !/(?<![\p{L}])(?:dem qua|toi qua)(?![\p{L}])/u.test(f)) return false;
        if (dayWord === null && cb.min > anchorMin) return false;
        endOff = dayWord === -1 ? 0 : (dayWord ?? 0);
        startOff = endOff - 1;
        if (startOff < -2) return false;
      } else {
        if (dayWord === null && cb.min > anchorMin) return false;
        endOff = dayWord ?? 0;
        startOff = endOff;
      }
      set('time', ca.hhmm, ev({ index: a.index, len: a.text.length }));
      set('dayOffset', startOff, null);
      set('endTime', cb.hhmm, ev({ index: b.index, len: b.text.length }));
      set('endDayOffset', endOff, null);
      return true;
    }
    if (tokens.length === 1) {
      if (ago || ongoing) {
        // "bé ngủ từ 13h, giờ vẫn đang ngủ": a start at 13h (no length).
        if (!ongoing || dur || woke || state?.action !== 'start') return false;
      }
      const t = tokens[0]!;
      const head = f.slice(0, t.index).trimEnd();
      const c = clock(t);
      const off = offsetFor(c);
      if (off === null) return false;
      const span = { index: t.index, len: t.text.length };
      if (wakeAt.test(head)) {
        // "dậy lúc 6h" (stop), "dậy lúc 6h, ngủ 9 tiếng" (a finished sleep).
        set('endTime', c.hhmm, ev(span));
        set('endDayOffset', off, null);
        if (dur) set('durationMin', dur.minutes, ev(lenSpan(dur)));
        else set('phase', 'stop', ev(span));
        return true;
      }
      if (sleepStartAt.test(head) && !woke && !dur) {
        // "bé ngủ lúc 9h", "ngủ từ 11h20": began then, still asleep (the timer starts there).
        set('time', c.hhmm, ev(span));
        set('dayOffset', off, null);
        set('phase', 'start', null);
        return true;
      }
      return false;
    }
    if (dur) {
      // "ngủ 9 tiếng", "vừa ngủ dậy, ngủ được 2 tiếng"; never "đang ngủ … được 5p" (L1).
      if (ongoing || state?.action === 'start') return false;
      set('durationMin', dur.minutes, ev(lenSpan(dur)));
      if (woke) {
        if (!ago?.justNow) return false;
        const a = agoClock();
        set('endTime', a.hhmm, agoEvidence());
        set('endDayOffset', a.day, null);
      } else if (ago) return false;
      return true;
    }
    if (state && states.length === 1) {
      // "con đang ngủ", "bé ngủ rồi", "bé dậy rồi": the app's timer.
      set('phase', state.action, sideEvidence(text, f, state.text));
      return true;
    }
    return false;
  }
}

/** The one kind a message is about, or null (none, several, or a feed that could be either). */
function kindOf(text: string, f: string): Kind | null {
  const kinds = new Set<Kind>();
  const pump = pumpCueIn(text) || /(?<![\p{L}])(?:hut|vat)(?![\p{L}])/u.test(f);
  if (pump) kinds.add('pump');
  if (diaperIn(text)) kinds.add('diaper');
  if (
    growthIn(text) &&
    /(?<![\p{L}])(?:can|nang|dai|cao|vong dau|chu vi dau)(?![\p{L}])/u.test(f)
  ) {
    kinds.add('growth');
  }
  if (/(?<![\p{L}])(?:ngu|giac|day)(?![\p{L}])/u.test(f)) kinds.add('sleep');
  const feed = /(?<![\p{L}])(?:bu|ti|uong|binh)(?![\p{L}])/u.test(f);
  if (feed && !pump) {
    const amount = bottleMlIn(text) !== null || bareMAmountIn(text) !== null;
    const mother = /(?<![\p{L}])(?:bu me|ti me|ti)(?![\p{L}])/u.test(f);
    const bottle = /(?<![\p{L}])(?:binh|uong)(?![\p{L}])/u.test(f);
    if (amount) {
      // "bé bú mẹ 100ml": breastfeeding is never ml (the model / the person decide).
      if (mother) return null;
      kinds.add('bottle');
    } else if (bottle) {
      if (mother) return null;
      kinds.add('bottle');
    } else if (
      mother ||
      durationsIn(text).length > 0 ||
      breastSideIn(text) !== null ||
      careStatesIn(text).some((s) => s.timer === 'breast')
    ) {
      kinds.add('breast');
    } else {
      // "bé bú" alone: a bottle or the breast — the model asks.
      return null;
    }
  }
  return kinds.size === 1 ? [...kinds][0]! : null;
}

function mlSpan(f: string): Span | null {
  const oz = /(\d+(?:[.,]\d+)?)\s*(?:oz|ounces?|ounce)(?![\p{L}])/u.exec(f);
  if (oz) return { index: oz.index, len: oz[0].length };
  const ml = /(\d+(?:[.,]\d+)?)\s*(?:ml|mls|millilit(?:er|re)s?|mililit|cc)(?![\p{L}])/u.exec(f);
  return ml ? { index: ml.index, len: ml[0].length } : null;
}

function bareMSpan(f: string): Span | null {
  const m = /(?<![\d.,])(\d{2,3})\s*m(?![\p{L}\d])/u.exec(f);
  return m ? { index: m.index, len: m[0].length } : null;
}

interface GrowthSpan extends Span {
  kind: 'weight' | 'length' | 'head';
}

/** The words of each measurement `growthIn` reads (same patterns, with where they are). */
function growthSpans(f: string): GrowthSpan[] {
  const out: GrowthSpan[] = [];
  const kg =
    /(?<![\d.,])(\d{1,2}(?:[.,]\d{1,3})?)\s*(?:kg|kgs|ky|ki|ki lo|kilo|kilogram|kilograms|can)(?:\s*(\d{1,3})(?!\d|[.,]\d|\s*(?:cm|g\b|gr)))?(?![\p{L}])/u.exec(
      f,
    );
  if (kg) out.push({ index: kg.index, len: kg[0].length, kind: 'weight' });
  const head =
    /(?<![\p{L}])(?:vong dau|chu vi dau)\D{0,12}?(\d{2}(?:[.,]\d)?)\s*(?:cm|phan)?/u.exec(f);
  let headSpan: Span | null = null;
  if (head) {
    const at = head.index + head[0].indexOf(head[1]!);
    headSpan = { index: at, len: head.index + head[0].length - at };
    out.push({ ...headSpan, kind: 'head' });
  }
  for (const m of f.matchAll(
    /(?<![\d.,])(\d{2,3}(?:[.,]\d)?)\s*(?:cm|centimet\w*|phan)(?![\p{L}])/gu,
  )) {
    if (headSpan && m.index >= headSpan.index && m.index < headSpan.index + headSpan.len) continue;
    out.push({ index: m.index, len: m[0].length, kind: 'length' });
    break;
  }
  return out;
}

/** The words a state or a side was read from, in the person's spelling. */
function sideEvidence(text: string, f: string, folded: string | null): string | null {
  const re = folded
    ? new RegExp(folded.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'u')
    : /(?<![\p{L}])(?:ca hai ben|ca 2 ben|hai ben|2 ben|ben trai|ben phai|trai|phai)(?![\p{L}])/u;
  const m = re.exec(f);
  return m ? text.slice(m.index, m.index + m[0].length) : null;
}

function diaperEvidence(text: string, f: string, kind: 'wet' | 'dirty' | 'both'): string | null {
  const re =
    kind === 'wet'
      ? /(?<![\p{L}])(?:uot|tieu|te)(?![\p{L}])/u
      : kind === 'dirty'
        ? /(?<![\p{L}])(?:ban|phan|i)(?![\p{L}])/u
        : /(?<![\p{L}])(?:ca hai|ca 2|uot (?:va|lan) ban)(?![\p{L}])/u;
  const m = re.exec(f);
  return m ? text.slice(m.index, m.index + m[0].length) : null;
}
