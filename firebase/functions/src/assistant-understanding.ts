import {
  addDaysIso,
  clockTimeIn,
  clockTokensIn,
  correctionWordIn,
  dayHalfAnswerIn,
  foldVi,
  hasDayPeriod,
  hourInDayHalf,
  isTimedEventKind,
  localDateIn,
  shortReplyIn,
  type DayHalf,
  type DraftKind,
  type TimeSpec,
  type Understanding,
  type UnderstandingAct,
  type UnderstandingEvent,
} from '@child-life/contracts';
import { careExtractionSchema, healthSignsExtractionSchema } from './assistant-care-model.js';
import { intentFieldNames, type ModelExtraction, type ModelIntent } from './assistant-model.js';
import { notNowWords, type PreviousTurn } from './assistant-text.js';
import { localClock, localInstant } from './assistant-tools.js';

/**
 * Lumi L9 (P-169, docs/product/lumi-plan.md §12.3 #2–#3): the ONE resolver of time and of
 * precedence. The model said what the parent meant (`Understanding`: an act, events with
 * `status` / `started` / `ended` / `durationMin`); this file turns it into instants and timers
 * against the anchor and the baby's zone, orders the acts, and hands the planner intents whose
 * times are already resolved (`ModelIntent.resolved`) — the planner then validates and drafts,
 * it never re-reads the words. The words are consulted only as GUARDS: which hours a written
 * clock allows (`clockTokensIn`), a period word (`hasDayPeriod`), a past-day word, a correcting
 * word (`correctionWordIn`), a short reply (`shortReplyIn`).
 *
 * Rules written once:
 * - `ongoing` → a timer start at `now − minutes` or at the clock (a span only when `finished`);
 * - `finished` with no time → now; with a length and no start → ended now, started that long ago;
 * - a sleep that ended with no start and no length → a timer stop (the planner stops the running
 *   timer, or asks when it began);
 * - `correct` / `undo` need a `target` that exists; `correct` also needs a correcting word in the
 *   message (or a short bare value): an ongoing state or a new fact is a log, never a correction;
 * - `answer` only to the open question; a short reply never starts a task (the planner restates).
 */

export interface ResolvedTime {
  /** A point log's instant, or a sleep's start (UTC ISO). */
  at: string | null;
  /** A sleep's end. */
  endAt: string | null;
  /** `start`: the ongoing state's timer from `at`; `stop`: it ended at `at` (if a timer runs). */
  timer: { action: 'start' | 'stop'; at: string } | null;
  /** A written clock open for morning / evening (its label, "8:00"): the server asks once. */
  ambiguous: string[];
  /** `start`: the start was computed from the end and the length (or now and the length). */
  derived: 'start' | 'end' | null;
  /** LUMI-04 guard: the model's clock is not what its own words say (the words win, flagged). */
  misread: ('startedAt' | 'endedAt' | 'occurredAt')[];
  /** L10: times out of bounds (a sleep over 18 h, two sleeps overlapping): flagged for review. */
  check?: ('startedAt' | 'endedAt')[];
  /** L10: an ongoing state whose start is not within the last 18 h: its start is asked. */
  askStart?: boolean;
}

export interface ResolveInput {
  u: Understanding;
  /** The message (guards only). */
  text: string;
  anchor: Date;
  zone: string;
  /** Answers by field: the choice id or the typed text (`time.ampm`, `time.missing`). */
  answers: Map<string, { choiceId: string | null; text: string | null }>;
  /** What waits / was just saved, in the order the model saw it (ids "i1", "i2"…). */
  previous: PreviousTurn | null;
  /** `continue` from `startTask` (L7): the instant the next log follows. */
  after?: Date;
  /** Running timers: a finished state with no start stops the running one. */
  timers?: Partial<Record<'sleep' | 'breast', { startedAt: Date } | null>>;
}

export interface ResolvedUnderstanding {
  /** The act after precedence. */
  act: UnderstandingAct;
  /** The planner's reading: intents with resolved times, reads, care, small talk. */
  ext: ModelExtraction;
  /** `undo`: the item to drop or delete. */
  undo: PreviousTurn['drafts'][number] | null;
  /** `continue`: the instant the new log follows. */
  after: Date | null;
}

const SKEW_MS = 2 * 60_000;
const NEAR_FUTURE_MS = 3 * 3_600_000;
const pad = (n: number) => String(n).padStart(2, '0');
const pastDayWords =
  /(?<![\p{L}])(?:hom qua|bua qua|toi qua|dem qua|sang qua|trua qua|chieu qua|hom kia|yesterday|last night)(?![\p{L}])/u;

const nullFields = Object.fromEntries(
  intentFieldNames.map((k) => [k, null]),
) as ModelIntent['fields'];

/** The id the model saw for the n-th item of the previous turn. */
export const itemIdOf = (index: number) => `i${index + 1}`;

/** The previous item a `target` names: "i2", or a legacy "kind:sleep" (the latest of that kind). */
export function targetOf(
  target: string | null,
  previous: PreviousTurn | null,
): PreviousTurn['drafts'][number] | null {
  if (!target || !previous) return null;
  const live = previous.drafts.filter((d) => d.state !== 'discarded');
  const m = /^i(\d{1,2})$/.exec(target);
  if (m) return live.find((d) => d === previous.drafts[Number(m[1]) - 1]) ?? null;
  const k = /^kind:(\w+)$/.exec(target);
  if (k) return live.find((d) => d.payload.kind === k[1]) ?? null;
  return null;
}

export function resolveUnderstanding(x: ResolveInput): ResolvedUnderstanding {
  const { u, anchor, zone } = x;
  const today = localDateIn(zone, anchor);
  const text = x.text;
  const folded = foldVi(text);
  const tokens = clockTokensIn(text);
  const periodSaid = hasDayPeriod(text);
  const saysPastDay = pastDayWords.test(folded);
  /** L8: a log with no time is now only when no word places it elsewhere ("hồi nãy", "hôm qua"). */
  const awayFromNow = saysPastDay || notNowWords.test(folded);
  const inst = (date: string, h: number, m: number) =>
    localInstant(zone, date, `${pad(((h % 24) + 24) % 24)}:${pad(m)}`);
  const ampmAnswer = x.answers.get('time.ampm');
  const ampm: DayHalf | null =
    ampmAnswer?.choiceId === 'am' || ampmAnswer?.choiceId === 'pm'
      ? ampmAnswer.choiceId
      : ampmAnswer?.text
        ? dayHalfAnswerIn(ampmAnswer.text)
        : null;
  const missingAnswer = x.answers.get('time.missing') ?? null;

  // ---------- Precedence (§12.3 #3) ----------
  let act: UnderstandingAct = u.act;
  let target = act === 'correct' || act === 'undo' ? targetOf(u.target, x.previous) : null;
  const events = u.events.filter((e) => e.status !== 'planned' || e.kind === 'reminder');
  if (act === 'correct') {
    // A new fact or an ongoing state is never a correction without a correcting word (a short
    // bare value — "180", "13:00" — counts while a draft waits, as L7's resolver reads it).
    const cue = correctionWordIn(text) || shortReplyIn(text);
    const ongoing = events.some((e) => e.status === 'ongoing');
    if (!target || !cue || ongoing) {
      act = events.length > 0 ? 'log' : 'meta';
      target = null;
    }
  } else if (act === 'undo') {
    if (!target) act = 'meta';
  } else if (act === 'answer' && events.length > 0) {
    act = 'log';
  } else if (act === 'ask' || act === 'log' || act === 'continue') {
    if (events.length === 0) act = u.reads.length > 0 ? 'read' : u.care ? 'log' : 'none';
  } else if ((act === 'talk' || act === 'none' || act === 'meta') && events.length > 0) {
    act = 'log';
  }
  let after: Date | null = x.after ?? null;
  if (act === 'continue' && !after) {
    const last = x.previous?.drafts.find((d) => d.state !== 'discarded')?.payload as
      Record<string, unknown> | undefined;
    const iso = (last?.endedAt ?? last?.occurredAt ?? last?.startedAt ?? last?.at) as
      string | undefined;
    after = iso ? new Date(iso) : null;
    if (!after) act = 'log';
  }

  // ---------- Time ----------
  interface Clock {
    hours: number[];
    m: number;
    label: string;
    offset: number;
    /** The model's hour is not one its evidence words allow (LUMI-04): flagged. */
    mismatch: boolean;
  }
  /**
   * A written clock: the hours ITS words allow (a guard — the evidence's token, else the
   * message's token with the same minutes and 12 h hour), else the model's hour as said.
   */
  const clockOf = (spec: TimeSpec, evidence: string | null): Clock | null => {
    if (spec.how !== 'clock' || !spec.hhmm) return null;
    const [h, m] = spec.hhmm.split(':').map(Number) as [number, number];
    const offset = spec.dayOffset ?? 0;
    const own = evidence ? clockTokensIn(evidence) : [];
    let tok =
      (own.length === 1 ? own[0] : null) ?? tokens.find((t) => t.m === m && t.h % 12 === h % 12);
    // "9 to 10am" as the evidence of the start: the bare 9 beside the token is what was read.
    if (tok && own.length === 1 && evidence && !tok.hours.includes(h)) {
      const fe = foldVi(evidence);
      const outside = fe.slice(0, tok.index) + ' ' + fe.slice(tok.index + tok.text.length);
      if (new RegExp(String.raw`(?<![\d:])${h % 12 || 12}(?![\d:hg])`, 'u').test(outside)) {
        tok = undefined;
      }
    }
    if (tok) {
      if (tok.m !== m || !tok.hours.includes(h)) {
        // The model read another time than the words say: the words win, flagged.
        return {
          hours: tok.hours,
          m: tok.m,
          label: `${tok.h}:${pad(tok.m)}`,
          offset,
          mismatch: true,
        };
      }
      const hours = tok.hours.length > 1 && periodSaid ? [h] : tok.hours;
      return { hours, m, label: `${tok.h}:${pad(m)}`, offset, mismatch: false };
    }
    return {
      hours: [h],
      m,
      label: `${h % 12 === 0 ? 12 : h % 12}:${pad(m)}`,
      offset,
      mismatch: false,
    };
  };
  const keptByAnswer = (hours: number[]) => {
    if (!ampm || hours.length < 2) return hours;
    const kept = hours.filter((h) => hourInDayHalf(h, ampm));
    return kept.length > 0 ? kept : hours;
  };
  /**
   * L10 A3: the day a past-day word names for an hour the model placed today or later: "tối qua
   * 9h" / "hôm qua" → yesterday, "hôm kia" → the day before; "đêm qua 2h" / "last night 2am" is
   * early TODAY (only its evening hours are yesterday).
   */
  const nightOnly =
    /(?<![\p{L}])(?:dem qua|last night)(?![\p{L}])/u.test(folded) &&
    !/(?<![\p{L}])(?:hom qua|bua qua|toi qua|sang qua|trua qua|chieu qua|hom kia|yesterday)(?![\p{L}])/u.test(
      folded,
    );
  const pastOffsetFor = (h: number) =>
    /(?<![\p{L}])hom kia(?![\p{L}])/u.test(folded) ? -2 : nightOnly && h < 12 ? 0 : -1;
  /** A log's instant: never silently in the future, last night when said so; open → asked. */
  const resolveLog = (c: Clock, open: string[], role: 'point' | 'end' = 'point'): Date => {
    if (saysPastDay && c.offset >= 0 && role === 'point') {
      const cands = c.hours
        .map((h) => inst(addDaysIso(today, pastOffsetFor(h)), h, c.m))
        .filter((t) => t.getTime() <= anchor.getTime() + SKEW_MS);
      const hourOf = (t: Date) => Number(localClock(zone, t).slice(0, 2));
      const kept = keptByAnswer(cands.map(hourOf));
      const picked = cands
        .filter((t) => kept.includes(hourOf(t)))
        .sort((a, b) => b.getTime() - a.getTime());
      if (picked.length > 1 && !ampm) open.push(c.label);
      if (picked.length > 0) return picked[0]!;
    }
    const days = saysPastDay || c.offset === -2 ? [c.offset] : c.offset === 1 ? [1] : [0, -1];
    for (const d of days) {
      const date = addDaysIso(today, d);
      const all = c.hours.map((h) => inst(date, h, c.m));
      const valid = all.filter(
        (t) =>
          t.getTime() <= anchor.getTime() + SKEW_MS &&
          anchor.getTime() - t.getTime() <= 36 * 3_600_000,
      );
      if (d === 1) return all[0]!;
      if (valid.length === 1) return valid[0]!;
      if (valid.length >= 2) {
        // L7: a continuation takes the first reading after the item it follows.
        if (after && !ampm) {
          const next = valid
            .filter((t) => t.getTime() >= after!.getTime() - SKEW_MS)
            .sort((a, b) => a.getTime() - b.getTime());
          if (next.length > 0) return next[0]!;
        }
        const hourOf = (t: Date) => Number(localClock(zone, t).slice(0, 2));
        const kept = keptByAnswer(valid.map(hourOf));
        const picked = valid.filter((t) => kept.includes(hourOf(t)));
        const latest = (picked.length ? picked : valid).sort((a, b) => b.getTime() - a.getTime());
        if (!ampm) open.push(c.label);
        return latest[0]!;
      }
      if (d === 0 && !saysPastDay) {
        const near = all.filter((t) => t.getTime() - anchor.getTime() <= NEAR_FUTURE_MS);
        if (near.length > 0) return near[0]!;
      }
    }
    return inst(addDaysIso(today, c.offset), c.hours[0]!, c.m);
  };
  /** `time.missing` answered (a chip "ago_N" or a typed clock). */
  const missingAt = (): Date | null => {
    if (!missingAnswer) return null;
    const id = missingAnswer.choiceId;
    if (id && /^ago_\d+$/.test(id))
      return new Date(anchor.getTime() - Number(id.slice(4)) * 60_000);
    if (missingAnswer.text) {
      const c = clockTimeIn(missingAnswer.text);
      if (!c) return null;
      const [h, m] = c.hhmm.split(':').map(Number) as [number, number];
      const hours = c.explicit ? [h] : [h % 12, (h % 12) + 12];
      const days = c.dayOffset !== null ? [c.dayOffset] : [0, -1];
      return (
        days
          .flatMap((d) => hours.map((hh) => inst(addDaysIso(today, d), hh, m)))
          .filter((t) => t.getTime() <= anchor.getTime() + SKEW_MS)
          .sort((a, b) => b.getTime() - a.getTime())[0] ?? null
      );
    }
    return null;
  };
  const instantOf = (
    spec: TimeSpec | null,
    open: string[],
    evidence: string | null = null,
    misread: (() => void) | null = null,
    role: 'point' | 'end' = 'point',
  ): Date | null => {
    if (!spec) return null;
    if (spec.how === 'ago') return new Date(anchor.getTime() - (spec.minutes ?? 0) * 60_000);
    const c = clockOf(spec, evidence);
    if (c?.mismatch) misread?.();
    return c ? resolveLog(c, open, role) : null;
  };
  /** Another event of the message has a time: a log without one is left to fill, not now. */
  const timedElsewhere = (e: UnderstandingEvent) =>
    events.some(
      (o) =>
        o !== e &&
        isTimedEventKind(o.kind) &&
        ((o.started && o.started.how !== 'unknown') || (o.ended && o.ended.how !== 'unknown')),
    );
  const minus = (d: Date, min: number) => new Date(d.getTime() - min * 60_000);
  const MAX_SLEEP_MS = 18 * 3_600_000;
  const RECENT_MS = 6 * 3_600_000;
  /** A sleep start given its end: the reading before the end within 18 h (a length fixes it). */
  const startBefore = (
    spec: TimeSpec | null,
    end: Date,
    dur: number | null,
    open: string[],
    evidence: string | null,
    misread: () => void,
  ): Date | null => {
    if (!spec) return null;
    if (spec.how === 'ago') return new Date(anchor.getTime() - (spec.minutes ?? 0) * 60_000);
    const c = clockOf(spec, evidence);
    if (!c) return null;
    if (c.mismatch) misread();
    const endDate = localDateIn(zone, end);
    const cands: Date[] = [];
    for (const d of [0, -1])
      for (const h of c.hours) cands.push(inst(addDaysIso(endDate, d), h, c.m));
    let valid = cands.filter(
      (t) => t.getTime() < end.getTime() && end.getTime() - t.getTime() <= MAX_SLEEP_MS,
    );
    // Nothing fits: kept as said (INVALID_TIME for review), never flipped.
    if (valid.length === 0) return inst(addDaysIso(today, c.offset), c.hours[0]!, c.m);
    const hourOf = (t: Date) => Number(localClock(zone, t).slice(0, 2));
    const halves = new Set(valid.map((t) => hourOf(t) >= 12));
    if (dur !== null && halves.size > 1) {
      const fits = valid.filter(
        (t) => Math.abs(end.getTime() - dur * 60_000 - t.getTime()) <= 10 * 60_000,
      );
      if (fits.length === 1) return fits[0]!;
    }
    if (!ampm && halves.size > 1) {
      const recent = valid.filter((t) => end.getTime() - t.getTime() < RECENT_MS);
      if (recent.length === 1) return recent[0]!;
    }
    if (ampm && halves.size > 1) {
      const kept = valid.filter((t) => hourInDayHalf(hourOf(t), ampm));
      if (kept.length > 0) valid = kept;
    }
    valid.sort((a, b) => b.getTime() - a.getTime());
    if (!ampm && halves.size > 1) open.push(c.label);
    return valid[0]!;
  };
  const iso = (d: Date | null) => d?.toISOString() ?? null;

  /** The instants of one timed event. */
  const resolveTimed = (e: UnderstandingEvent): ResolvedTime => {
    const open: string[] = [];
    const misread: ResolvedTime['misread'] = [];
    const dur = e.durationMin && e.durationMin > 0 ? e.durationMin : null;
    const startSaid = e.started && e.started.how !== 'unknown' ? e.started : null;
    const endSaid = e.ended && e.ended.how !== 'unknown' ? e.ended : null;
    const kind = e.kind;
    const evOf = (field: 'started' | 'ended') =>
      e.evidence.find((v) => v.field === field)?.text ?? null;
    const point = kind === 'sleep' ? 'startedAt' : 'occurredAt';
    const startOf = () => instantOf(startSaid, open, evOf('started'), () => misread.push(point));
    const endOf = () =>
      instantOf(
        endSaid,
        open,
        evOf('ended'),
        () => misread.push(kind === 'sleep' ? 'endedAt' : 'occurredAt'),
        // A sleep's end is read against its start below, never moved by "tối qua" itself.
        kind === 'sleep' ? 'end' : 'point',
      );
    const running = kind === 'sleep' || kind === 'breast' ? (x.timers?.[kind] ?? null) : null;
    if (e.status === 'ongoing' && (kind === 'sleep' || kind === 'breast')) {
      // §12.3 #2: still going on → a timer from when it began (a length = how long so far).
      const at = startOf() ?? (dur !== null ? minus(anchor, dur) : anchor);
      // L10: a state that began in the future or more than 18 h ago is not a reading to keep
      // ("đang ngủ từ 16h" at 15:30): its start is asked.
      const askStart =
        at.getTime() > anchor.getTime() + SKEW_MS || anchor.getTime() - at.getTime() > MAX_SLEEP_MS;
      return {
        at: null,
        endAt: null,
        timer: { action: 'start', at: iso(at)! },
        ambiguous: askStart ? [] : open,
        derived: null,
        misread,
        ...(askStart ? { askStart } : {}),
      };
    }
    const none: ResolvedTime = {
      at: null,
      endAt: null,
      timer: null,
      ambiguous: open,
      derived: null,
      misread,
    };
    if (kind === 'sleep') {
      if (saysPastDay && startSaid?.how === 'clock' && endSaid?.how === 'clock') {
        // L10 A3: "tối qua ngủ 21h đến 6h sáng", "hôm qua ngủ 13h đến 14h": the past-day word
        // places the START; the end is the first reading after it within 18 h.
        const o: string[] = [];
        const m: ResolvedTime['misread'] = [];
        const s0 = instantOf(startSaid, o, evOf('started'), () => m.push('startedAt'));
        const c = clockOf(endSaid, evOf('ended'));
        if (s0 && c) {
          if (c.mismatch) m.push('endedAt');
          const startDate = localDateIn(zone, s0);
          const ends = [0, 1]
            .flatMap((d) => c.hours.map((h) => inst(addDaysIso(startDate, d), h, c.m)))
            .filter(
              (t) =>
                t.getTime() > s0.getTime() &&
                t.getTime() - s0.getTime() <= MAX_SLEEP_MS &&
                t.getTime() <= anchor.getTime() + SKEW_MS,
            )
            .sort((a, b) => a.getTime() - b.getTime());
          const fit =
            dur !== null
              ? ends.find((t) => Math.abs(t.getTime() - s0.getTime() - dur * 60_000) <= 10 * 60_000)
              : undefined;
          const e0 = fit ?? ends[0];
          if (e0) {
            open.push(...o);
            misread.push(...m);
            return { ...none, at: iso(s0), endAt: iso(e0) };
          }
        }
      }
      const end = endOf();
      // A start given with its end is read BEFORE the end, within 18 h ("đêm qua 9h tối đến
      // 6h sáng" keeps its days; "ngủ 9h, dậy 10h" at 15:00 is the morning): never a span that
      // ends before it starts because each clock was placed on its own.
      let start = end
        ? startBefore(startSaid, end, dur, open, evOf('started'), () => misread.push('startedAt'))
        : startOf();
      if (
        !start &&
        !end &&
        dur !== null &&
        e.status === 'finished' &&
        e.ended?.how === 'unknown' &&
        e.started?.how === 'unknown'
      ) {
        // "ngủ 9 tiếng": a length with no end point — the planner asks when it began.
        return none;
      }
      if (!start && end && dur === null) {
        // "dậy rồi", "dậy lúc 6h": it ended then; the running timer stops, else the start is asked.
        return { ...none, endAt: iso(end), timer: { action: 'stop', at: iso(end)! } };
      }
      if (!start && !end) {
        const m = missingAt();
        if (m) start = m;
      }
      if (!start && end && dur !== null) {
        start = minus(end, dur);
        return { ...none, at: iso(start), endAt: iso(end), derived: 'start' };
      }
      if (start && !end && dur !== null && e.status !== 'ongoing') {
        // L10: a finished sleep from its start and length ends at start + length — at most 18 h
        // and never in the future, else the end is flagged for review (the planner computes it).
        const ends = start.getTime() + dur * 60_000;
        if (dur * 60_000 > MAX_SLEEP_MS || ends > anchor.getTime() + SKEW_MS) {
          return { ...none, at: iso(start), check: ['endedAt'] };
        }
      }
      return { ...none, at: iso(start), endAt: iso(end) };
    }
    if (kind === 'breast' || kind === 'pump') {
      const start = startOf();
      const end = endOf();
      // "vừa bú mẹ 20 phút" read with its start at now (a v8 reply): a feed with a length
      // cannot have begun now — it just ended, so it started that long ago.
      if (start && dur !== null && Math.abs(start.getTime() - anchor.getTime()) <= SKEW_MS) {
        return { ...none, at: iso(minus(start, dur)), derived: 'start' };
      }
      if (start) return { ...none, at: iso(start) };
      if (end) {
        if (dur !== null) return { ...none, at: iso(minus(end, dur)), derived: 'start' };
        // "bú xong rồi": the running feed stops; else a log that ended then (its length is asked).
        if (kind === 'breast' && running)
          return { ...none, timer: { action: 'stop', at: iso(end)! } };
        return { ...none, at: iso(end) };
      }
      const m = missingAt();
      // As the planner reads `time.missing` (assistant-text.ts): a "Vừa xong" / "N phút trước"
      // chip is when the feed ended, a typed clock is when it began (br-05).
      const endedThen = /^ago_\d+$/.test(missingAnswer?.choiceId ?? '');
      if (m)
        return {
          ...none,
          at: iso(dur !== null && endedThen ? minus(m, dur) : m),
          derived: dur && endedThen ? 'start' : null,
        };
      if (timedElsewhere(e) || awayFromNow) return none;
      if (dur !== null) return { ...none, at: iso(minus(anchor, dur)), derived: 'start' };
      return { ...none, at: iso(anchor) };
    }
    // bottle, diaper: a point log — its clock, "N phút trước", an answer, else now (§12.3 #2);
    // in a batch where another log has a time, left to fill ("7h 100ml rồi bú thêm 60ml").
    const said = startOf() ?? endOf() ?? missingAt();
    if (!said && (timedElsewhere(e) || awayFromNow)) return none;
    return { ...none, at: iso(said ?? anchor) };
  };

  // ---------- The planner's intents ----------
  const known = new Set<string>(intentFieldNames);
  const back = (f: string) => (f === 'started' ? 'time' : f === 'ended' ? 'endTime' : f);
  const sleeps: { r: ResolvedTime; dur: number | null }[] = [];
  const intents: ModelIntent[] = events.map((e) => {
    const f = e.fields;
    const fields: ModelIntent['fields'] = {
      ...nullFields,
      amountMl: f.amountMl ?? null,
      milk: f.milk ?? null,
      side: f.side ?? null,
      diaper: f.diaper ?? null,
      weightKg: f.weightKg ?? null,
      lengthCm: f.lengthCm ?? null,
      headCm: f.headCm ?? null,
      dayOffset: f.dayOffset ?? null,
      observation: f.observation ?? null,
      when: f.when ?? null,
      note: f.note ?? null,
      title: f.title ?? null,
      amount: f.amount ?? null,
      currency: f.currency ?? null,
      categoryId: f.categoryId ?? null,
      merchant: f.merchant ?? null,
      date: f.date ?? null,
      assigneeText: f.assigneeText ?? null,
      time: e.kind === 'reminder' ? (f.time ?? null) : null,
      durationMin: isTimedEventKind(e.kind) && e.durationMin ? e.durationMin : null,
      phase: null,
    };
    const resolved = isTimedEventKind(e.kind) ? resolveTimed(e) : undefined;
    if (resolved && e.kind === 'sleep') sleeps.push({ r: resolved, dur: e.durationMin ?? null });
    return {
      kind: e.kind as DraftKind,
      fields,
      evidence: e.evidence
        .map((v) => ({ field: back(v.field), text: v.text }))
        .filter((v) => known.has(v.field)) as ModelIntent['evidence'],
      uncertainFields: [
        ...new Set(e.uncertainFields.map(back).filter((v) => known.has(v))),
      ] as ModelIntent['uncertainFields'],
      missingFields: [],
      correctsPrevious: act === 'correct' && target !== null,
      corrects: act === 'correct' && target ? (target.payload.kind as DraftKind) : null,
      ...(act === 'correct' && target ? { correctsId: target.id } : {}),
      ...(resolved ? { resolved } : {}),
    };
  });
  // L10: two sleeps of one message never overlap ("ngủ 9h-11h, rồi ngủ 10h-12h"): both flagged.
  const spans = sleeps.flatMap(({ r, dur }) => {
    if (!r.at) return [];
    const start = Date.parse(r.at);
    const end = r.endAt ? Date.parse(r.endAt) : dur ? start + dur * 60_000 : null;
    return end !== null && end > start ? [{ r, start, end }] : [];
  });
  for (const a of spans) {
    if (spans.some((b) => b !== a && a.start < b.end && b.start < a.end)) {
      a.r.check = [...new Set([...(a.r.check ?? []), 'startedAt' as const, 'endedAt' as const])];
    }
  }
  const ext: ModelExtraction = {
    intents:
      act === 'undo' || act === 'meta' || act === 'talk' || act === 'none' || act === 'answer'
        ? []
        : intents,
    reads: act === 'undo' ? [] : u.reads,
    // Slice A5: a care fact the model asks for (`planCare` owns the question); never a time.
    clarification:
      u.ask && u.ask.field.startsWith('sleep.')
        ? { field: u.ask.field as 'sleep.period' | 'sleep.when' | 'sleep.onset' }
        : null,
    // The care topic and the health signs in the server's own enums (anything else is dropped).
    care: careExtractionSchema.safeParse(u.care ?? null).data ?? null,
    healthSigns: healthSignsExtractionSchema.safeParse(u.healthSigns ?? []).data ?? [],
    smallTalk: act === 'talk',
    outOfScope: act === 'none' && !u.care,
    replyTo:
      act === 'answer'
        ? 'question'
        : act === 'correct'
          ? target?.state === 'saved'
            ? 'record'
            : 'draft'
          : null,
  };
  return {
    act,
    ext,
    undo: act === 'undo' ? target : null,
    after: act === 'continue' ? after : null,
  };
}
