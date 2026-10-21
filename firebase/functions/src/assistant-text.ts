import type { Firestore, Timestamp } from 'firebase-admin/firestore';
import {
  addDaysIso,
  agoIn,
  bareMAmountIn,
  bottleMlIn,
  breastSideIn,
  builtInCategories,
  careStatesIn,
  categoryHintIn,
  clockTimeIn,
  clockTokensIn,
  completeSpan,
  dayHalfAnswerIn,
  diaperIn,
  growthIn,
  hourInDayHalf,
  looksLikeSpending,
  pumpCueIn,
  purchasesIn,
  type ClockToken,
  draftPayloadSchema,
  draftProblems,
  durationsIn,
  foldVi,
  hasDayPeriod,
  isExpenseCurrency,
  localDateIn,
  mentionsMedicine,
  moneyAmountsIn,
  observationCueIn,
  otherCategoryId,
  parseMoney,
  relativeDateIn,
  sameMessage,
  toMinorUnits,
  type Clarification,
  type DayHalf,
  type DraftKind,
  type DraftPayload,
  type ExpenseCurrency,
  type SpanLink,
} from '@child-life/contracts';
import type { ScopeMember, TrustedScope } from './assistant-common.js';
import { assignableMembers, reminderAssigneeQuestion } from './assistant-images.js';
import type { NoteLineReading } from './assistant-image-model.js';
import type { ModelIntent } from './assistant-model.js';
import {
  careDuplicateIn,
  localClock,
  localInstant,
  moduleAllows,
  moduleRegistry,
  reviewFields,
  type PreparedDraft,
} from './assistant-tools.js';
import {
  expenseDuplicateSuspected,
  householdBabyIds,
  zoneDraftProblems,
} from './assistant-writers-images.js';

/**
 * Lumi rework 2026-10-15 (docs/assistant/tools.md "Text planning", api.md "Rework 2026-10-15"):
 * the model's intents for a TEXT message → typed drafts or ONE server question, deterministically.
 *
 * - Times: local clock times in the baby's zone. An hour without morning / evening ("8 giờ") is
 *   resolved when only one reading is not in the future, asked (`time.ampm`) when both are
 *   possible; "10 giờ tối" said in the morning is last night; "nửa đêm" said in the morning is
 *   today 00:00; a completed log is never in the future (kept for review, never moved silently).
 * - Durations keep start / end / duration linked: two of them give the third ("dậy lúc 6h, ngủ
 *   9 tiếng" → 21:00 last night); a duration with no end point asks ONE point (`time.start`, with
 *   chips the server computes, never in the future); a log with no time at all asks `time.missing`
 *   ("Vừa xong", "30 phút trước", "1 tiếng trước", or a typed time).
 * - Amounts are re-read from the words (`parseMoney`, `bottleMlIn`); the model only says which
 *   words. Categories must be the household's; unknown → `c_other`, to review.
 * - Reminders: dates from the words ("mai", "thứ 6", "20/10"), all day without an hour, an
 *   assignee only chosen by the person among eligible members (`reminder.assignee.<i>`), never
 *   from a name in the text; medicine is never scheduled.
 * - Corrections ("à không, 150ml") replace the sender's previous unsaved draft of that kind; a
 *   saved one is never changed (the person edits it in its module).
 * Roles: a kind the member may not save is a notice, never a draft (`moduleAllows`).
 */

export interface PreviousTurn {
  taskId: string;
  text: string;
  drafts: {
    id: string;
    state: string;
    payload: DraftPayload;
    recordLink: string | null;
    /** L7: the draft's own task (the dialogue state spans tasks; else [PreviousTurn.taskId]). */
    taskId?: string;
    /** L7: the record a saved draft wrote (an edit draft changes it). */
    recordId?: string | null;
  }[];
}

export interface TextContext {
  db: Firestore;
  s: TrustedScope;
  now: Date;
  anchor: Date;
  locale: 'vi' | 'en';
  /** The person's message. */
  text: string;
  /** Typed clarification answers (grounding). */
  answerTexts: string[];
  /** Answers by field: the choice id or the typed text. */
  answers: Map<string, { choiceId: string | null; text: string | null }>;
  /** Fields already asked in this task (each is asked once). */
  asked: Set<string>;
  round: number;
  lastMilk: 'breast_milk' | 'formula';
  /** The household's Chi tiêu currency (amounts without a written one). */
  currency: ExpenseCurrency;
  /** The household's spending categories (ids the model may pick). */
  categories: { id: string; name: string }[];
  previous: PreviousTurn | null;
  /**
   * Lumi 2026-10-16: the baby's running timers (`babies/{b}/timers/{sleep|breast}`), read at
   * plan time; absent = none running.
   */
  timers?: RunningTimers;
  /** The side the next breastfeed starts on by default (the form: other side of the last one). */
  nextBreastSide?: 'left' | 'right' | 'both';
  /** LUMI-01: the side the pump form remembers (the last pump's), else both. */
  lastPumpSide?: 'left' | 'right' | 'both';
  /**
   * LUMI-05: the draft kinds the sending app can show (contracts `clientDraftKindsOf`); a kind
   * outside it is never drafted (`APP_UPDATE_NEEDED` instead). Absent = every kind (tests).
   */
  clientKinds?: readonly DraftKind[];
  /**
   * L7 (P-168 #2): "rồi ngủ lúc 10h" continues the last item: an open clock is the reading after
   * this instant (its day, a later time), never a morning / evening question.
   */
  after?: Date;
  /**
   * L9 (P-169): the intents come from the understanding resolver with their times resolved
   * (`ModelIntent.resolved`): no state or phase is read from the words here, only the guards
   * (`careBackstops`) run.
   */
  understood?: boolean;
}

/** A running app timer as the planner needs it. */
export interface RunningTimer {
  sessionId: string;
  startedAt: Date;
}
export type RunningTimers = Partial<Record<'sleep' | 'breast', RunningTimer | null>>;

export type TextNoticeCode =
  | 'MODULE_UNAVAILABLE'
  | 'WRITE_DENIED'
  | 'VALIDATION_FAILED'
  | 'MEDICINE_NOT_SCHEDULED'
  | 'DUPLICATE_SUSPECTED'
  | 'PREVIOUS_SAVED'
  | 'CORRECTION_APPLIED'
  | 'TIMER_RUNNING'
  // ---- Lumi fixes 2026-10-16 ----
  | 'APP_UPDATE_NEEDED';

export interface TextNotice {
  kind: DraftKind;
  code: TextNoticeCode;
  link?: string;
  /** TIMER_RUNNING: which timer and since when; APP_UPDATE_NEEDED for a timer: which one. */
  timer?: { type: 'sleep' | 'breast'; since: Date };
}

export type TextPlan =
  | { kind: 'ask'; clarification: Clarification }
  | { kind: 'drafts'; drafts: PreparedDraft[]; notices: TextNotice[] };

const L = (vi: string, en: string) => ({ vi, en });
const pad = (n: number) => String(n).padStart(2, '0');
const hhmmOf = (h: number, m: number) => `${pad(((h % 24) + 24) % 24)}:${pad(m)}`;
const SKEW_MS = 2 * 60_000;
/** A completed log said for later today by at most this much stays on today (for review). */
const NEAR_FUTURE_MS = 3 * 3_600_000;
const MAX_SLEEP_MS = 18 * 3_600_000;
/** L1 (P-167 #2): a start this close before its end takes that reading, never a question. */
const RECENT_MS = 6 * 3_600_000;

/** Draft field each model field fills, per kind (for uncertain / missing lists). */
const draftField: Record<string, Partial<Record<DraftKind, string>>> = {
  amountMl: { bottle: 'amountMl', pump: 'amountMl' },
  milk: { bottle: 'milk' },
  // Lumi 2026-10-16: an observation has no time; its `date` comes from dayOffset.
  time: {
    bottle: 'occurredAt',
    breast: 'occurredAt',
    sleep: 'startedAt',
    reminder: 'time',
    pump: 'occurredAt',
    diaper: 'occurredAt',
  },
  dayOffset: {
    bottle: 'occurredAt',
    breast: 'occurredAt',
    sleep: 'startedAt',
    observation: 'date',
    pump: 'occurredAt',
    diaper: 'occurredAt',
    growth: 'measuredOn',
  },
  endTime: { sleep: 'endedAt', breast: 'occurredAt', pump: 'occurredAt' },
  endDayOffset: { sleep: 'endedAt' },
  durationMin: { breast: 'durationMin', sleep: 'durationMin', pump: 'durationMin' },
  side: { breast: 'side', pump: 'side' },
  // ---- LUMI-01 ----
  diaper: { diaper: 'diaper' },
  weightKg: { growth: 'weightKg' },
  lengthCm: { growth: 'lengthCm' },
  headCm: { growth: 'headCm' },
  observation: { observation: 'observation' },
  when: { observation: 'when' },
  note: { observation: 'note' },
  title: { reminder: 'title', expense: 'note' },
  amount: { expense: 'totalMinor' },
  currency: { expense: 'currency' },
  categoryId: { expense: 'categoryId' },
  merchant: { expense: 'merchant' },
  date: { expense: 'date', reminder: 'date' },
  assigneeText: { reminder: 'assigneeUid' },
};

const pastDayWords =
  /(?<![\p{L}])(?:hom qua|bua qua|toi qua|dem qua|sang qua|trua qua|chieu qua|hom kia|yesterday|last night)(?![\p{L}])/u;

/**
 * One stated clock time (LUMI-03 / LUMI-04): the hours its OWN words allow (contracts
 * `clockTokensIn`: "6h" → 6 or 18, "9h tối" → 21, "12h" → noon), checked against the model's
 * reading. A model hour the words do not allow is a misreading: the words win and the field is
 * flagged for review.
 */
interface Clock {
  m: number;
  /** The model's day offset (0, −1, −2). */
  offset: number;
  /** The possible 24 h hours (two when the words leave morning / evening open). */
  hours: number[];
  /** The model read another time than the words say: flag the field. */
  mismatch: boolean;
  /** How the question names it ("8:00"). */
  label: string;
  /** L1: the time is written in the message (else the model computed it, or an answer). */
  written: boolean;
}

interface Resolved {
  at: Date | null;
  /** Both halves of the day fit: ask `time.ampm`. */
  ambiguous: boolean;
}

export async function planTextIntents(
  ctx: TextContext,
  modelIntents: ModelIntent[],
): Promise<TextPlan> {
  const { s, anchor } = ctx;
  const zone = s.zone;
  // Lumi 2026-10-16: ongoing states ("con đang ngủ", "bé dậy rồi", "đang cho bú trái") from
  // the words, and the model's items checked against them (`checkIntents`).
  // L9: understood intents carry resolved times (the resolver read `status` / `started`); the
  // state words are only a GUARD for a timer kind the model returned nothing for ("Con đang
  // ngủ" read as an observation), never a second reading of an event it did return.
  const states = ctx.understood
    ? careStatesIn(ctx.text).filter((st) => !modelIntents.some((i) => i.kind === st.timer))
    : careStatesIn(ctx.text);
  const intents = checkIntents(ctx, modelIntents, states);
  const today = localDateIn(zone, anchor);
  const all = [ctx.text, ...ctx.answerTexts].join(' \n ');
  const haystack = foldVi([all, ctx.previous?.text ?? ''].join(' \n '));
  // A correction ("nhầm, 10h30 mới dậy") reads its morning / evening from the turn it corrects.
  const correcting = intents.some((i) => i.correctsPrevious === true) && ctx.previous !== null;
  // L1: a typed morning / evening answer ("tối") is read as the answer below, never as a period
  // word of the message (it would keep the model's reading of every open time).
  const typedAmpm = ctx.answers.get('time.ampm')?.text ?? null;
  const periodWords = [ctx.text, ...ctx.answerTexts.filter((t) => t !== typedAmpm)].join(' \n ');
  const periodSaid = hasDayPeriod(
    correcting ? `${periodWords} \n ${ctx.previous!.text}` : periodWords,
  );
  // In a batch where another log has a time, a log without one is left for the person to fill
  // (no question: none of the quick choices would fit "rồi bú thêm 60ml").
  const timedLogs = intents.filter(
    (i) =>
      (i.kind === 'bottle' ||
        i.kind === 'breast' ||
        i.kind === 'sleep' ||
        i.kind === 'pump' ||
        i.kind === 'diaper') &&
      (i.fields.time !== null ||
        i.fields.endTime !== null ||
        // L9: a resolved time counts as one the words gave.
        Boolean(i.resolved && (i.resolved.at || i.resolved.endAt || i.resolved.timer))),
  ).length;
  const saysPastDay = pastDayWords.test(foldVi(ctx.text));
  // L1 (P-167 #3): the morning / evening answer, a chip or typed ("Sáng", "tối", "23:21").
  const ampmAnswer = ctx.answers.get('time.ampm');
  const ampm: DayHalf | null =
    ampmAnswer?.choiceId === 'am' || ampmAnswer?.choiceId === 'pm'
      ? ampmAnswer.choiceId
      : ampmAnswer?.text
        ? dayHalfAnswerIn(ampmAnswer.text)
        : null;
  /** The hours of [hours] the answer keeps (all of them when it keeps none). */
  const keptByAnswer = (hours: number[]) => {
    if (!ampm) return hours;
    const kept = hours.filter((h) => hourInDayHalf(h, ampm));
    return kept.length > 0 ? kept : hours;
  };
  const said = durationsIn(ctx.text).map((d) => d.minutes);
  const ago = agoIn(ctx.text);
  // L1 (P-167 #2): "cách đây 5p", "5p rồi", "2 tiếng trước": the model's clock for it is computed.
  const relativeSaid = ago !== null && !ago.justNow;
  const inst = (date: string, h: number, m: number) => localInstant(zone, date, hhmmOf(h, m));
  const grounded = (t: string) => {
    const f = foldVi(t).trim();
    return f.length > 0 && haystack.includes(f);
  };
  const evidenceOf = (i: ModelIntent, field: string) =>
    i.evidence.find((e) => e.field === field)?.text ?? null;

  // LUMI-03 / LUMI-04: every clock time of the message, each with its own period words.
  const tokens = clockTokensIn(ctx.text);
  const textFolded = foldVi(ctx.text);
  const timeFields = intents.reduce(
    (n, i) => n + (i.fields.time ? 1 : 0) + (i.fields.endTime ? 1 : 0),
    0,
  );
  /** The words a time of [i] was read from: its evidence in the message, else the only match. */
  const tokenFor = (i: ModelIntent, field: 'time' | 'endTime', h: number, m: number) => {
    const ev = evidenceOf(i, field);
    if (ev) {
      const fe = foldVi(ev).trim();
      const at = fe ? textFolded.indexOf(fe) : -1;
      if (at >= 0) {
        // The words of this time: the one token of its evidence, or the one there that reads as
        // the model's clock ("9 to 10am" holds two times).
        const inSpan = tokens.filter(
          (x) =>
            (x.index >= at && x.index < at + fe.length) ||
            (at >= x.index && at < x.index + x.text.length),
        );
        if (inSpan.length === 1) {
          const t = inSpan[0]!;
          // "9 to 10am" for the start: its own hour is written there too (not a clock form):
          // that bare number, not the other time, is what the model read.
          const bare = new RegExp(String.raw`(?<![\d:])${h % 12 || 12}(?![\d:hg])`, 'u');
          const outside =
            fe.slice(0, Math.max(0, t.index - at)) + ' ' + fe.slice(t.index - at + t.text.length);
          if (!allows(t, h, m) && bare.test(outside)) return null;
          return t;
        }
        if (inSpan.length > 1) {
          const same = inSpan.filter((x) => x.m === m && x.h % 12 === h % 12);
          return same.length === 1 ? same[0]! : null;
        }
      }
      const own = clockTokensIn(ev)[0];
      if (own) return own;
    }
    if (tokens.length === 1 && timeFields === 1) return tokens[0]!;
    const same = tokens.filter((x) => x.m === m && x.h % 12 === h % 12);
    return same.length === 1 ? same[0]! : null;
  };
  /** Whether a model hour is one the words allow. */
  const allows = (t: ClockToken, h: number, m: number) => t.m === m && t.hours.includes(h);
  // A correction reads its morning / evening from the turn it corrects when its own words are open.
  const previousPeriod = correcting && hasDayPeriod(ctx.previous!.text);

  const clockOf = (i: ModelIntent, field: 'time' | 'endTime'): Clock | null => {
    const v = i.fields[field];
    if (!v) return null;
    const [h, m] = v.split(':').map(Number) as [number, number];
    const offset =
      (field === 'time' ? i.fields.dayOffset : (i.fields.endDayOffset ?? i.fields.dayOffset)) ?? 0;
    const label = (hh: number, mm: number) => `${hh}:${pad(mm)}`;
    const tok = tokenFor(i, field, h, m);
    if (tok) {
      if (!allows(tok, h, m)) {
        // The model read another time than the words say (LUMI-04): the words win, flagged.
        return {
          m: tok.m,
          offset,
          hours: tok.hours,
          mismatch: true,
          label: label(tok.h, tok.m),
          written: true,
        };
      }
      // The words leave the half of the day open but the message (or the turn it corrects) has a
      // period word somewhere: the model's reading of it stands.
      if (tok.hours.length > 1 && (periodSaid || previousPeriod)) {
        return { m, offset, hours: [h], mismatch: false, label: label(tok.h, m), written: true };
      }
      return {
        m,
        offset,
        hours: tok.hours,
        mismatch: false,
        label: label(tok.h, m),
        written: true,
      };
    }
    // No words for this time (an answer, a previous turn): the model's hour; open when it is
    // 1–11 and nothing anywhere says morning or evening. L1 (P-167 #2): a clock the model
    // computed from "cách đây 5p" / "5p rồi" is never open.
    const open = !periodSaid && !previousPeriod && !ampm && !relativeSaid && h >= 1 && h <= 11;
    return {
      m,
      offset,
      hours: open ? [h % 12, (h % 12) + 12] : [h],
      mismatch: false,
      label: label(h % 12 === 0 ? 12 : h % 12, m),
      written: false,
    };
  };
  /** The readings of [c] that the person's morning / evening answer keeps (all when none). */
  const byAnswer = (c: Clock, hours: number[]) => (hours.length < 2 ? hours : keptByAnswer(hours));
  /** A correction that repeats the previous draft's clock keeps that draft's instant. */
  const fromBase = (c: Clock | null, iso: unknown): Date | null =>
    c &&
    c.hours.length === 1 &&
    typeof iso === 'string' &&
    localClock(zone, new Date(iso)) === hhmmOf(c.hours[0]!, c.m)
      ? new Date(iso)
      : null;
  /** The ambiguous clocks of this message (named in the morning / evening question). */
  const openClocks: string[] = [];
  /** Fields whose time the model misread (flagged on their draft). */
  let misread: string[] = [];

  /** A completed log's instant: never silently in the future, last night when said that way. */
  const resolveLog = (c: Clock): Resolved => {
    const days = saysPastDay ? [c.offset] : [0, -1];
    for (const d of days) {
      const date = addDaysIso(today, d);
      const all = c.hours.map((h) => inst(date, h, c.m));
      const valid = all.filter(
        (t) =>
          t.getTime() <= anchor.getTime() + SKEW_MS &&
          anchor.getTime() - t.getTime() <= 36 * 3_600_000,
      );
      if (valid.length === 1) return { at: valid[0]!, ambiguous: false };
      // L7: a continuation takes the first reading after the item it follows.
      if (valid.length >= 2 && ctx.after && !ampm) {
        const next = valid
          .filter((t) => t.getTime() >= ctx.after!.getTime() - SKEW_MS)
          .sort((a, b) => a.getTime() - b.getTime());
        if (next.length > 0) return { at: next[0]!, ambiguous: false };
      }
      if (valid.length >= 2) {
        // Only a time that is really open takes the morning / evening answer (LUMI-03).
        const kept = byAnswer(
          c,
          valid.map((t) => Number(localClock(zone, t).slice(0, 2))),
        );
        const picked = valid.filter((t) => kept.includes(Number(localClock(zone, t).slice(0, 2))));
        const latest = (picked.length ? picked : valid).sort((a, b) => b.getTime() - a.getTime());
        if (ampm) return { at: latest[0]!, ambiguous: false };
        openClocks.push(c.label);
        return { at: latest[0]!, ambiguous: true };
      }
      if (d === 0 && !saysPastDay) {
        const near = all.filter((t) => t.getTime() - anchor.getTime() <= NEAR_FUTURE_MS);
        if (near.length > 0) return { at: near[0]!, ambiguous: false };
      }
    }
    return { at: inst(addDaysIso(today, c.offset), c.hours[0]!, c.m), ambiguous: false };
  };

  /**
   * A sleep start given its end: before it, within 18 h. L1 (P-167 #2): with a known length the
   * reading that gives it (end − length, ± 10 min) is the start; a reading less than 6 h before
   * the end is taken (the other one would be a sleep of over 12 h): no question either way.
   */
  const resolveStartBefore = (c: Clock, end: Date, lengthMin: number | null = null): Resolved => {
    const endDate = localDateIn(zone, end);
    const cands: Date[] = [];
    for (const d of [0, -1]) {
      for (const h of c.hours) cands.push(inst(addDaysIso(endDate, d), h, c.m));
    }
    let valid = cands.filter(
      (t) => t.getTime() < end.getTime() && end.getTime() - t.getTime() <= MAX_SLEEP_MS,
    );
    if (valid.length === 0) {
      // Kept as said (INVALID_TIME for review), never flipped.
      return { at: inst(addDaysIso(today, c.offset), c.hours[0]!, c.m), ambiguous: false };
    }
    const halves = new Set(valid.map((t) => Number(localClock(zone, t).slice(0, 2)) >= 12));
    if (lengthMin !== null && halves.size > 1) {
      const fits = valid.filter(
        (t) => Math.abs(end.getTime() - lengthMin * 60_000 - t.getTime()) <= 10 * 60_000,
      );
      if (fits.length === 1) return { at: fits[0]!, ambiguous: false };
    }
    if (!ampm && halves.size > 1) {
      const recent = valid.filter((t) => end.getTime() - t.getTime() < RECENT_MS);
      if (recent.length === 1) return { at: recent[0]!, ambiguous: false };
    }
    if (ampm && halves.size > 1) {
      const hourOf = (t: Date) => Number(localClock(zone, t).slice(0, 2));
      const kept = valid.filter((t) => hourInDayHalf(hourOf(t), ampm));
      if (kept.length > 0) valid = kept;
    }
    valid.sort((a, b) => b.getTime() - a.getTime());
    const open = !ampm && halves.size > 1;
    if (open) openClocks.push(c.label);
    return { at: valid[0]!, ambiguous: open };
  };

  /** A reminder's time on [date] (future): resolved when only one half is still ahead. */
  const resolveReminder = (c: Clock, date: string | null): { hhmm: string; ambiguous: boolean } => {
    const hours = byAnswer(c, c.hours);
    if (hours.length === 1 || date === null) {
      if (hours.length > 1) openClocks.push(c.label);
      return { hhmm: hhmmOf(hours[0]!, c.m), ambiguous: hours.length > 1 };
    }
    const ahead = hours.filter(
      (h) => inst(date, h, c.m).getTime() > ctx.now.getTime() - 5 * 60_000,
    );
    if (ahead.length === 1) return { hhmm: hhmmOf(ahead[0]!, c.m), ambiguous: false };
    if (ahead.length > 1) openClocks.push(c.label);
    return { hhmm: hhmmOf(hours[0]!, c.m), ambiguous: ahead.length > 1 };
  };

  /** A duration the person said (the model's when it is one of them, else the only one said). */
  const durationFor = (i: ModelIntent): { min: number | null; uncertain: boolean } => {
    const d = i.fields.durationMin;
    if (d !== null && Number.isInteger(d) && d > 0) {
      // LUMI-15: a feed or pumping length with no time unit in the words is not trusted past
      // an hour ("bé bu 120m" is never a two-hour breastfeed).
      if (said.length === 0) return { min: d, uncertain: i.kind !== 'sleep' && d > 60 };
      if (said.includes(d)) return { min: d, uncertain: false };
      if (said.length === 1) return { min: said[0]!, uncertain: false };
      return { min: d, uncertain: true };
    }
    if (d !== null) return { min: null, uncertain: true };
    const sameKind = intents.filter((x) => x.kind === i.kind).length;
    if (
      sameKind === 1 &&
      said.length === 1 &&
      intents.filter((x) => x.kind === 'sleep' || x.kind === 'breast' || x.kind === 'pump')
        .length === 1
    ) {
      return { min: said[0]!, uncertain: false };
    }
    return { min: null, uncertain: false };
  };

  // ---------- Questions: one at a time, each field once ----------
  let ask: Clarification | null = null;
  const askOnce = (q: Clarification) => {
    if (!ask && !ctx.asked.has(q.field) && ctx.round < 4) ask = q;
  };

  const drafts: PreparedDraft[] = [];
  const notices: TextNotice[] = [];
  const needsAmpm: boolean[] = [];

  // The answers that resolve a missing time ("Vừa xong", a chip, a typed time).
  const missingAnswer = ctx.answers.get('time.missing') ?? null;
  const startAnswer = ctx.answers.get('time.start') ?? null;

  /** `time.missing` answered: minutes before the send time, or a typed clock time. */
  const missingAt = (): Date | null => {
    if (!missingAnswer) return null;
    const id = missingAnswer.choiceId;
    if (id && /^ago_\d+$/.test(id))
      return new Date(anchor.getTime() - Number(id.slice(4)) * 60_000);
    if (missingAnswer.text) {
      const c = clockTimeIn(missingAnswer.text);
      if (!c) return null;
      const [h, m] = c.hhmm.split(':').map(Number) as [number, number];
      const r = resolveLogFromAnswer(h, m, !c.explicit, c.dayOffset);
      return r;
    }
    return null;
  };
  /** A typed time as an answer: the most recent reading that is not in the future. */
  const resolveLogFromAnswer = (
    h: number,
    m: number,
    ambiguous: boolean,
    dayOffset: number | null,
    latest: Date = new Date(anchor.getTime() + SKEW_MS),
  ): Date | null => {
    const hours = ambiguous ? [h % 12, (h % 12) + 12] : [h];
    const days = dayOffset !== null ? [dayOffset] : [0, -1];
    const cands = days
      .flatMap((d) => hours.map((hh) => inst(addDaysIso(today, d), hh, m)))
      .filter((t) => t.getTime() <= latest.getTime())
      .sort((a, b) => b.getTime() - a.getTime());
    return cands[0] ?? null;
  };
  /** `time.start` answered: a chip (`at_<date>_<HH:mm>`), a typed time or (with [end]) a length. */
  const startAt = (latest: Date, end: Date | null = null): Date | null => {
    if (!startAnswer) return null;
    const id = startAnswer.choiceId;
    const chip = id ? /^at_(\d{4}-\d{2}-\d{2})_(\d{2}):(\d{2})$/.exec(id) : null;
    if (chip) return inst(chip[1]!, Number(chip[2]), Number(chip[3]));
    // "2 tiếng" typed for "Bé bắt đầu ngủ lúc mấy giờ?" after "dậy rồi": it slept that long.
    const typedLength = startAnswer.text ? durationsIn(startAnswer.text) : [];
    if (end && typedLength.length === 1 && !clockTimeIn(startAnswer.text!)) {
      return new Date(end.getTime() - typedLength[0]!.minutes * 60_000);
    }
    if (startAnswer.text) {
      const c = clockTimeIn(startAnswer.text);
      if (!c) return null;
      const [h, m] = c.hhmm.split(':').map(Number) as [number, number];
      return resolveLogFromAnswer(h, m, !c.explicit, c.dayOffset, latest);
    }
    return null;
  };

  /** A point log's time: its words' clock, "2 tiếng trước", a correction's, an answer, else asked. */
  const pointTime = (c: Clock | null, base: DraftPayload | null): Date | null => {
    const kept = fromBase(c, x(base, 'occurredAt'));
    if (c?.mismatch) misread.push('occurredAt');
    if (kept) return kept;
    if (c) {
      const r = resolveLog(c);
      needsAmpm.push(r.ambiguous);
      return r.at;
    }
    if (ago) return new Date(anchor.getTime() - ago.minutes * 60_000);
    if (base && 'occurredAt' in base && base.occurredAt) return new Date(base.occurredAt);
    const at = missingAt();
    if (!at && timedLogs === 0) askOnce(timeMissingQuestion(ctx, null));
    return at;
  };

  /**
   * A feed / pumping time whose words say it ENDED then ("bú 15 phút, xong lúc 8h sáng") with a
   * length is the end, whatever field the model put it in (br-06 live: `time` 08:00, phase stop).
   */
  const endFirst = (i: ModelIntent, durMin: number | null): [Clock | null, Clock | null] => {
    const c = clockOf(i, 'time');
    const endC = clockOf(i, 'endTime');
    if (c && !endC && durMin) {
      const ev = foldVi(evidenceOf(i, 'time') ?? '');
      if (
        /(?<![\p{L}])(?:xong|het|ket thuc|den|toi|finished|ended|done|until)(?![\p{L}])/u.test(ev)
      ) {
        return [null, c];
      }
    }
    return [c, endC];
  };

  // L7 (v8): the item the model says it corrects (`corrects`, maybe another kind), else the
  // latest one of the same kind; the dialogue state lists the latest first.
  const previousOf = (kind: DraftKind, corrects?: DraftKind | null, correctsId?: string) =>
    // L9: the item the understanding named by id, first.
    (correctsId
      ? ctx.previous?.drafts.find((d) => d.id === correctsId && d.state !== 'discarded')
      : null) ??
    ctx.previous?.drafts.find(
      (d) => d.payload.kind === (corrects ?? kind) && d.state !== 'discarded',
    ) ??
    ctx.previous?.drafts.find((d) => d.payload.kind === kind) ??
    null;

  let reminderIndex = 0;
  let assignable: ScopeMember[] | null = null;
  const clientCan = (k: DraftKind) => !ctx.clientKinds || ctx.clientKinds.includes(k);
  /** A side the words say for [i] (its grounded evidence, or the message when it is the only one). */
  const sideOf = (i: ModelIntent): 'left' | 'right' | 'both' | null => {
    const ev = evidenceOf(i, 'side');
    if (ev && grounded(ev)) {
      const fromEv = breastSideIn(ev);
      if (fromEv) return fromEv;
    }
    const sameKind = intents.filter((x) => x.kind === i.kind).length;
    return sameKind === 1 ? breastSideIn(ctx.text) : null;
  };

  /**
   * Lumi 2026-10-16: an ongoing sleep / feed drives the app's timer. `start` ("con đang ngủ",
   * "bắt đầu ngủ lúc 21h", "đang cho bú trái") → a `timer` start at the said time, else now — or,
   * when that timer already runs, a TIMER_RUNNING notice and a stop draft (end it / keep it).
   * `stop` ("dậy rồi", "dậy lúc 6h", "bú xong rồi") → a stop draft for the running timer; with no
   * timer, `finishedEnd` (a finished sleep that ended then; its start is asked). A length, both
   * times, or a correction make it a finished log instead — except (L1, P-167 #1) a state the
   * words say still goes on ("đang ngủ, được 5p rồi", "đang bú bên trái được 10 phút"): its timer
   * starts that long ago (contracts `CareState.sinceMin`), or at the time written.
   */
  const timerPlan = (
    i: ModelIntent,
    kind: 'sleep' | 'breast',
    durMin: number | null,
    base: DraftPayload | null,
  ): { payload: DraftPayload } | { finishedEnd: Date } | { legacy: true } | null => {
    const st = states.find((x) => x.timer === kind) ?? null;
    // L9: an understood intent says itself whether a timer starts or stops (the resolver's
    // reading of `status` / `started` / `ended`); no phase cue is read from the words.
    const rt = i.resolved?.timer ?? null;
    if (i.resolved && !rt) return null;
    // The model's phase only with words of something happening now / just over ("bú sữa"
    // alone is not a running feed, rd-09).
    const phase =
      rt?.action ??
      st?.action ??
      (i.fields.phase && phaseCue.test(foldVi(ctx.text)) ? i.fields.phase : null);
    if (!phase || base) return null;
    const goingOn = phase === 'start' && (st?.action === 'start' || rt !== null);
    if (durMin !== null && !goingOn) return null;
    // LUMI-05: an app build that cannot show a timer draft gets a notice with the timer's link.
    const legacy = () => {
      notices.push({
        kind: 'timer',
        code: 'APP_UPDATE_NEEDED',
        timer: { type: kind, since: anchor },
      });
      return { legacy: true as const };
    };
    let startC = clockOf(i, 'time');
    let endC = clockOf(i, 'endTime');
    if (phase === 'stop' && startC && !endC) {
      // "dậy lúc 6h" read into `time`: it is when the sleep ended.
      const ev = foldVi(evidenceOf(i, 'time') ?? ctx.text);
      if (/(?<![\p{L}])(?:day|thuc|tinh|woke|awake|xong)(?![\p{L}])/u.test(ev)) {
        endC = startC;
        startC = null;
      }
    }
    // L1: still going on ("Bé đang ngủ. Vừa ngủ được 5p rồi"): an end the model made up (now)
    // is not an end the words gave.
    if (goingOn && endC && !endC.written) endC = null;
    if (startC && endC) return null;
    const running = ctx.timers?.[kind] ?? null;
    // L1: how long the state has run, from the words ("được 5p rồi", "cách đây 5p").
    const since = goingOn ? (st?.sinceMin ?? durMin) : null;
    const when = (c: Clock | null): Date => {
      if (i.resolved?.askStart && phase === 'start') {
        // L10: a start the resolver could not place within the last 18 h is asked.
        const answered = startAt(anchor);
        if (answered) return answered;
        askOnce(timeStartQuestion(ctx, anchor, kind));
      }
      // L9: the resolver's instant, as it is.
      if (rt) return new Date(rt.at);
      // A time the model computed ("cách đây 5p" → 11:21) gives way to the words' own length.
      if (c && (c.written || since === null)) {
        const r = resolveLog(c);
        needsAmpm.push(r.ambiguous);
        if (c.mismatch) misread.push('at');
        return r.at ?? anchor;
      }
      if (since !== null) return new Date(anchor.getTime() - since * 60_000);
      if (ago && !ago.justNow) return new Date(anchor.getTime() - ago.minutes * 60_000);
      return anchor;
    };
    const stopOf = (r: RunningTimer, at: Date): DraftPayload => ({
      kind: 'timer',
      timer: kind,
      action: 'stop',
      at: at.toISOString(),
      side: null,
      sessionId: r.sessionId,
      startedAt: r.startedAt.toISOString(),
    });
    if (phase === 'start') {
      if (endC) return null;
      if (!clientCan('timer')) return legacy();
      if (running) {
        notices.push({
          kind: 'timer',
          code: 'TIMER_RUNNING',
          timer: { type: kind, since: running.startedAt },
        });
        return { payload: stopOf(running, anchor) };
      }
      // LUMI-07: the side from the words only; else the form's default, never flagged.
      const evSide = sideOf(i);
      const saidSide = st?.side ?? (evSide === 'left' || evSide === 'right' ? evSide : null);
      return {
        payload: {
          kind: 'timer',
          timer: kind,
          action: 'start',
          at: when(startC).toISOString(),
          side:
            kind === 'breast'
              ? (saidSide ?? (ctx.nextBreastSide === 'right' ? 'right' : 'left'))
              : null,
          sessionId: null,
          startedAt: null,
        },
      };
    }
    if (startC) return null; // "ngủ từ 9h, vừa dậy": a finished sleep with both ends.
    if (running && !clientCan('timer')) return legacy();
    if (running) return { payload: stopOf(running, when(endC)) };
    return kind === 'sleep' ? { finishedEnd: when(endC) } : null;
  };

  for (const intent of intents) {
    const kind = intent.kind;
    const mod = moduleRegistry[kind];
    if (!mod.available || (!mod.action && !mod.can)) {
      notices.push({ kind, code: 'MODULE_UNAVAILABLE' });
      continue;
    }
    if (!moduleAllows(kind, s.member)) {
      notices.push({ kind, code: 'WRITE_DENIED' });
      continue;
    }
    // LUMI-05: never a draft the sending app cannot show (an older build): said instead.
    if (!clientCan(kind)) {
      notices.push({ kind, code: 'APP_UPDATE_NEEDED' });
      continue;
    }
    misread = [];
    const f = intent.fields;
    // L9: the resolver's times (a written clock it left open is the server's one question).
    const r = intent.resolved ?? null;
    for (const label of r?.ambiguous ?? []) {
      openClocks.push(label);
      needsAmpm.push(true);
    }
    // LUMI-04: a clock the model misread (the words won) is always flagged; L10: so is a time
    // out of bounds (a sleep over 18 h or in the future, two sleeps overlapping).
    misread.push(...(r?.misread ?? []), ...(r?.check ?? []));
    const name = (field: string) => draftField[field]?.[kind] ?? null;
    const uncertain = new Set<string>();
    const missing = new Set<string>();
    for (const u of intent.uncertainFields) if (name(u)) uncertain.add(name(u)!);
    for (const m of intent.missingFields) if (name(m)) missing.add(name(m)!);
    for (const e of intent.evidence) {
      if (name(e.field) && !grounded(e.text)) uncertain.add(name(e.field)!);
    }
    // The model's "time is unsure" for an hour without morning / evening is the server's call.
    if (!periodSaid) uncertain.delete(name('time') ?? '');

    // ---- Correction of the previous turn ----
    let replaces: PreparedDraft['replaces'] = undefined;
    let base: DraftPayload | null = null;
    /** L7 (P-168 #2): a care record saved in the last 30 min is changed by an edit draft. */
    let edit: string | null = null;
    if (intent.correctsPrevious && ctx.previous) {
      const prev = previousOf(kind, intent.corrects, intent.correctsId);
      if (prev && prev.state === 'saved') {
        if (prev.recordId && prev.payload.kind === kind && editableKinds.has(kind)) {
          edit = prev.recordId;
          base = prev.payload;
        } else {
          notices.push({
            kind,
            code: 'PREVIOUS_SAVED',
            ...(prev.recordLink ? { link: prev.recordLink } : {}),
          });
          continue;
        }
      }
      if (
        prev &&
        (prev.state === 'draft' || prev.state === 'needs_review' || prev.state === 'failed')
      ) {
        replaces = { taskId: prev.taskId ?? ctx.previous.taskId, draftId: prev.id };
        base = prev.payload;
      }
    }

    let payload: DraftPayload;
    let link: SpanLink | undefined;
    switch (kind) {
      case 'bottle': {
        const ev = evidenceOf(intent, 'amountMl');
        const parsed = ev ? bottleMlIn(ev) : null;
        const only =
          intents.filter((x) => x.kind === 'bottle').length === 1 ? bottleMlIn(ctx.text) : null;
        let amount = parsed?.ml ?? f.amountMl ?? only?.ml ?? null;
        if (parsed && f.amountMl !== null && Math.abs(parsed.ml - f.amountMl) > 2)
          amount = parsed.ml;
        if (amount !== null && !Number.isInteger(amount)) amount = Math.round(amount);
        const milk = f.milk === 'other' ? null : (f.milk ?? x(base, 'milk') ?? ctx.lastMilk);
        if (f.milk === 'other') uncertain.add('milk');
        // Lumi 2026-10-16: milk not said takes the form's default (the last bottle's): the
        // model's doubt about a value it was never given must not block the save.
        else if (f.milk === null) uncertain.delete('milk');
        const c = clockOf(intent, 'time');
        if (!c) uncertain.delete('occurredAt');
        const at = r?.at ? new Date(r.at) : pointTime(c, base);
        payload = {
          kind: 'bottle',
          amountMl:
            amount !== null && amount > 0
              ? amount
              : ((x(base, 'amountMl') as number | null) ?? null),
          occurredAt: at?.toISOString() ?? null,
          milk: milk as 'breast_milk' | 'formula' | null,
        };
        if (amount !== null && amount <= 0) uncertain.add('amountMl');
        break;
      }
      case 'breast': {
        const dur = durationFor(intent);
        if (dur.uncertain) uncertain.add('durationMin');
        const tp = timerPlan(intent, 'breast', dur.min, base);
        if (tp && 'payload' in tp) {
          payload = tp.payload;
          break;
        }
        if (tp && 'legacy' in tp) continue;
        const durMin = dur.min ?? (x(base, 'durationMin') as number | null) ?? null;
        // LUMI-07: a side only from the words (the model's guess is never a value to review).
        const sideSaid = sideOf(intent);
        // Lumi 2026-10-16: a side not said takes the form's default (the other side of the last
        // feed, else both) — never a blocking gap.
        const side =
          sideSaid ??
          (x(base, 'side') as 'left' | 'right' | 'both' | null) ??
          ctx.nextBreastSide ??
          'both';
        if (sideSaid === null) uncertain.delete('side');
        let at: Date | null;
        const [c, endC] = endFirst(intent, durMin);
        const kept = fromBase(c, x(base, 'occurredAt'));
        if (c?.mismatch || endC?.mismatch) misread.push('occurredAt');
        // The model's doubt about a start it did not read (computed from the end) is not kept.
        if (!c && !(endC?.mismatch ?? false)) uncertain.delete('occurredAt');
        if (kept) {
          at = kept;
        } else if (r?.at) {
          // L9: the resolver's instant ("vừa bú mẹ 20 phút" → started 20 minutes ago).
          at = new Date(r.at);
          if (r.derived === 'start') link = { derived: 'occurredAt' };
        } else if (c) {
          const r = resolveLog(c);
          at = r.at;
          needsAmpm.push(r.ambiguous);
          // "vừa bú mẹ 20 phút": the feed just ended, so it started 20 minutes ago.
          if (
            at &&
            ago?.justNow &&
            durMin &&
            Math.abs(at.getTime() - anchor.getTime()) <= SKEW_MS
          ) {
            at = new Date(anchor.getTime() - durMin * 60_000);
            link = { derived: 'occurredAt' };
          }
          // "bú 15 phút, xong lúc 8h": a start the model computed from the end and the length
          // agrees with the words — nothing for the person to check (LUMI-09).
          if (at && endC && durMin && !endC.mismatch) {
            const e = resolveLog(endC).at;
            if (e && Math.abs(e.getTime() - durMin * 60_000 - at.getTime()) <= SKEW_MS) {
              uncertain.delete('occurredAt');
              link = { derived: 'occurredAt' };
            }
          }
        } else if (endC && durMin) {
          const r = resolveLog(endC);
          needsAmpm.push(r.ambiguous);
          at = r.at ? new Date(r.at.getTime() - durMin * 60_000) : null;
          link = { derived: 'occurredAt' };
        } else if (ago && ago.justNow && !r) {
          at = new Date(anchor.getTime() - (durMin ?? 0) * 60_000);
          if (durMin) link = { derived: 'occurredAt' };
        } else if (ago && !r) {
          at = new Date(anchor.getTime() - ago.minutes * 60_000);
        } else if (base && 'occurredAt' in base && base.occurredAt) {
          at = new Date(base.occurredAt);
        } else {
          const id = missingAnswer?.choiceId;
          if (id && /^ago_\d+$/.test(id) && durMin) {
            // "Vừa xong" for a feed with a length: it ended then.
            at = new Date(anchor.getTime() - (Number(id.slice(4)) + durMin) * 60_000);
            link = { derived: 'occurredAt' };
          } else at = missingAt();
          if (!at && timedLogs === 0) askOnce(timeMissingQuestion(ctx, durMin));
        }
        payload = {
          kind: 'breast',
          occurredAt: at?.toISOString() ?? null,
          durationMin: durMin !== null && durMin > 0 ? durMin : null,
          side,
          ...(link ? { linked: link } : {}),
        };
        break;
      }
      case 'sleep': {
        const dur = durationFor(intent);
        if (dur.uncertain) uncertain.add('durationMin');
        const tp = timerPlan(intent, 'sleep', dur.min, base);
        if (tp && 'payload' in tp) {
          payload = tp.payload;
          break;
        }
        if (tp && 'legacy' in tp) continue;
        const finishedEnd = tp && 'finishedEnd' in tp ? tp.finishedEnd : null;
        let durMin = dur.min;
        const startC = clockOf(intent, 'time');
        const endC = clockOf(intent, 'endTime');
        if (startC?.mismatch) misread.push('startedAt');
        if (endC?.mismatch) misread.push('endedAt');
        // LUMI-09: the model's doubt about an end it did not read (a chip, an answer, a length)
        // is not a doubt about the person's words.
        if (!startC) uncertain.delete('startedAt');
        if (!endC) uncertain.delete('endedAt');
        if (dur.min !== null && said.includes(dur.min)) uncertain.delete('durationMin');
        let start: Date | null = null;
        let end: Date | null = null;
        const keptEnd = fromBase(endC, x(base, 'endedAt'));
        const keptStart = fromBase(startC, x(base, 'startedAt'));
        if (keptEnd) {
          end = keptEnd;
        } else if (finishedEnd) {
          // "dậy rồi" with no timer running: it ended then; the start is asked below.
          end = finishedEnd;
        } else if (r?.endAt) {
          // L9: the resolver's end.
          end = new Date(r.endAt);
        } else if (endC) {
          const r = resolveLog(endC);
          end = r.at;
          needsAmpm.push(r.ambiguous);
        } else if (ago?.justNow && (durMin || startC) && !r) {
          // "vừa ngủ dậy": it ended now.
          end = anchor;
        }
        if (keptStart) {
          start = keptStart;
        } else if (r?.at) {
          start = new Date(r.at);
          if (r.derived === 'start') uncertain.delete('startedAt');
        } else if (startC) {
          const r = end ? resolveStartBefore(startC, end, durMin) : resolveLog(startC);
          start = r.at;
          needsAmpm.push(r.ambiguous);
        }
        if (base && base.kind === 'sleep') {
          if (!start && base.startedAt) start = new Date(base.startedAt);
          if (!end && base.endedAt && !durMin) end = new Date(base.endedAt);
          if (end && start && end <= start && base.endedAt) end = new Date(base.endedAt);
        }
        if (!start && !end && durMin) {
          // A length with no end point: ask when it started (chips never in the future).
          const latest = new Date(anchor.getTime() - durMin * 60_000);
          start = startAt(latest);
          if (!start && !ctx.asked.has('time.start')) askOnce(timeStartQuestion(ctx, latest));
        }
        if (!start && end && !durMin) {
          // Lumi 2026-10-16: an end with no start ("dậy rồi", "dậy lúc 6h") asks when it began
          // (chips by length, a typed time or a length) instead of leaving a dead end.
          start = startAt(end, end);
          if (!start && !ctx.asked.has('time.start')) askOnce(sleepStartQuestion(ctx, end));
        }
        // A length said for another item of the message ("rồi bú mẹ 10 phút") is not this sleep's.
        if (
          start &&
          end &&
          durMin !== null &&
          intents.some((o) => o !== intent && o.kind !== 'sleep' && o.fields.durationMin === durMin)
        ) {
          durMin = null;
          uncertain.delete('durationMin');
        }
        const span = completeSpan({
          start: start?.getTime() ?? null,
          end: end?.getTime() ?? null,
          durationMin: durMin,
        });
        if (span.inconsistent) {
          uncertain.add('durationMin');
          uncertain.add('endedAt');
        } else if (span.start !== null && span.end !== null) {
          // The length follows the two ends (the server recomputes it): never the model's doubt.
          uncertain.delete('durationMin');
        }
        durMin = span.durationMin;
        link =
          span.derived === 'start'
            ? { derived: 'startedAt' }
            : span.derived === 'end'
              ? { derived: 'endedAt' }
              : // L9: the resolver computed the start from the end and the length.
                r?.derived === 'start'
                ? { derived: 'startedAt' }
                : null;
        payload = {
          kind: 'sleep',
          startedAt: span.start !== null ? new Date(span.start).toISOString() : null,
          endedAt: span.end !== null ? new Date(span.end).toISOString() : null,
          durationMin: durMin !== null && durMin > 0 ? durMin : null,
          linked: link,
        };
        break;
      }
      case 'observation': {
        if (f.observation === null) {
          notices.push({ kind, code: 'VALIDATION_FAILED' });
          continue;
        }
        // A day the words do not name is today: the model's doubt about it is not kept.
        const day = relativeDateIn(ctx.text, today, 'past');
        if (!day || (day.certain && day.date === addDaysIso(today, f.dayOffset ?? 0))) {
          uncertain.delete('date');
        }
        payload = {
          kind: 'observation',
          observation: f.observation,
          date: addDaysIso(today, f.dayOffset ?? 0),
          when: f.when,
          note: f.note,
        };
        break;
      }
      case 'expense': {
        const amountEv = evidenceOf(intent, 'amount');
        const written = moneyAmountsIn(ctx.text);
        const expenses = intents.filter((i) => i.kind === 'expense').length;
        let money = amountEv ? parseMoney(amountEv, ctx.currency) : null;
        if (!money && expenses === 1 && written.length === 1) money = written[0]!;
        let totalMinor: number | null = null;
        let currency: string;
        if (money) {
          totalMinor = money.minor;
          currency = money.currency;
          if (money.uncertain) uncertain.add('totalMinor');
        } else if (f.amount !== null && f.amount !== undefined && f.amount > 0) {
          // The model's number without readable words: shown for review, never trusted as is.
          const cur: ExpenseCurrency = isExpenseCurrency(f.currency) ? f.currency : ctx.currency;
          totalMinor = toMinorUnits(f.amount, cur);
          currency = cur;
          uncertain.add('totalMinor');
        } else {
          currency = ctx.currency;
        }
        // A later day in the words ("…, mai nhớ mua sữa") belongs to a plan, never to money
        // already spent (LUMI-16, 2026-10-16): the expense keeps today.
        const said = relativeDateIn(ctx.text, today, 'past');
        const d = said && said.date <= today ? said : null;
        let date: string | null = d?.date ?? null;
        if (d && !d.certain) uncertain.add('date');
        if (!date && f.date && /^\d{4}-\d{2}-\d{2}$/.test(f.date) && f.date !== today) {
          date = f.date;
          uncertain.add('date');
        }
        // No day in the words: today, as the form; the model's doubt about it is not kept.
        if (!d && date === null) uncertain.delete('date');
        date ??= today;
        const allowed = new Set(ctx.categories.map((c) => c.id));
        let categoryId = f.categoryId && allowed.has(f.categoryId) ? f.categoryId : null;
        categoryId ??= categoryHintIn([f.title ?? '', ctx.text].join(' '));
        if (categoryId === null || !allowed.has(categoryId)) {
          categoryId = otherCategoryId;
          if (!(f.categoryId === otherCategoryId)) uncertain.add('categoryId');
        } else if (categoryHintIn([f.title ?? '', ctx.text].join(' ')) === categoryId) {
          // The words point to the same category ("wipes" → Tã & vệ sinh): nothing to check.
          uncertain.delete('categoryId');
        }
        const merchant =
          f.merchant?.trim() && grounded(f.merchant) ? f.merchant.trim().slice(0, 120) : null;
        const note = f.title?.trim() ? f.title.trim().slice(0, 80) : null;
        payload = {
          kind: 'expense',
          merchant,
          totalMinor: totalMinor !== null && totalMinor > 0 ? totalMinor : null,
          currency,
          date,
          subtotalMinor: null,
          taxMinor: null,
          categoryId,
          babyId: s.babyId,
          keepReceipt: false,
          note,
        };
        break;
      }
      case 'reminder': {
        const title = (f.title ?? '').trim();
        if (mentionsMedicine([title, ctx.text].join(' '))) {
          notices.push({ kind, code: 'MEDICINE_NOT_SCHEDULED' });
          continue;
        }
        if (!title) {
          notices.push({ kind, code: 'VALIDATION_FAILED' });
          continue;
        }
        if (!grounded(title)) uncertain.add('title');
        const d = relativeDateIn(ctx.text, today, 'future');
        let date: string | null = d?.date ?? null;
        if (d && !d.certain) uncertain.add('date');
        if (!date && f.date && /^\d{4}-\d{2}-\d{2}$/.test(f.date)) {
          date = f.date;
          if (!evidenceOf(intent, 'date')) uncertain.add('date');
        }
        let time: string | null = null;
        const c = clockOf(intent, 'time');
        if (c) {
          const r = resolveReminder(c, date);
          time = r.hhmm;
          needsAmpm.push(r.ambiguous);
          if (c.mismatch) misread.push('time');
        }
        // ---- D-075 #5: who does it — the person picks among eligible members ----
        let assigneeUid: string | null = null;
        const index = reminderIndex++;
        const who = f.assigneeText?.trim();
        if (who && grounded(who)) {
          const field = `reminder.assignee.${index}`;
          const answer = ctx.answers.get(field);
          assignable ??= await assignableMembers(ctx.db, s, ctx.now);
          if (answer) {
            assigneeUid = assignable.find((m) => m.uid === answer.choiceId)?.uid ?? null;
          } else if (assignable.length > 0 && !ctx.asked.has(field)) {
            const q = reminderAssigneeQuestion(
              index,
              { title, assigneeText: who } as NoteLineReading,
              assignable,
              s.uid,
            );
            // The photo wording ("Ảnh ghi …") does not fit a typed message.
            const t = title.length > 50 ? `${title.slice(0, 49)}…` : title;
            const w = who.length > 20 ? `${who.slice(0, 19)}…` : who;
            askOnce({
              ...q,
              id: 'pending',
              question: L(
                `Tin nhắn ghi “${w}” cho việc “${t}”. Giao việc này cho ai?`,
                `The message says “${w}” for “${t}”. Who should do it?`,
              ),
            });
          }
        }
        payload = { kind: 'reminder', title: title.slice(0, 120), date, time, assigneeUid };
        break;
      }
      // ---- Lumi fixes 2026-10-16 (LUMI-01): the care module's other logs ----
      case 'pump': {
        // Millilitres from the words ("hút được 80ml", "4oz"); the model only says which words.
        const ev = evidenceOf(intent, 'amountMl');
        const only =
          intents.filter((y) => y.kind === 'pump').length === 1 ? bottleMlIn(ctx.text) : null;
        const parsed = (ev ? bottleMlIn(ev) : null) ?? only;
        let amount = parsed?.ml ?? f.amountMl ?? (x(base, 'amountMl') as number | null) ?? null;
        if (parsed && f.amountMl !== null && Math.abs(parsed.ml - f.amountMl) > 2) {
          amount = parsed.ml;
        }
        if (amount !== null && !Number.isInteger(amount)) amount = Math.round(amount);
        if (amount !== null && !parsed && f.amountMl !== null) uncertain.add('amountMl');
        const dur = durationFor(intent);
        if (dur.uncertain) uncertain.add('durationMin');
        const durMin = dur.min ?? (x(base, 'durationMin') as number | null) ?? null;
        // The form's side: as said, else the side it remembers (the last pump's), else both.
        const sideSaid = sideOf(intent);
        const side =
          sideSaid ??
          (x(base, 'side') as 'left' | 'right' | 'both' | null) ??
          ctx.lastPumpSide ??
          'both';
        if (sideSaid === null) uncertain.delete('side');
        const [c, endC] = endFirst(intent, durMin);
        if (!c && !(endC?.mismatch ?? false)) uncertain.delete('occurredAt');
        if (endC?.mismatch) misread.push('occurredAt');
        let at: Date | null;
        if (!c && endC && durMin) {
          // "hút xong lúc 10h, 20 phút": it started 20 minutes before.
          const r = resolveLog(endC);
          needsAmpm.push(r.ambiguous);
          at = r.at ? new Date(r.at.getTime() - durMin * 60_000) : null;
          link = { derived: 'occurredAt' };
        } else if (r?.at) {
          // L9: the resolver's instant.
          at = new Date(r.at);
          if (r.derived === 'start') link = { derived: 'occurredAt' };
        } else {
          at = pointTime(c, base);
          // "vừa hút 15 phút": it just ended, so it started 15 minutes ago (as a breastfeed).
          if (
            durMin &&
            ago?.justNow &&
            (!at || Math.abs(at.getTime() - anchor.getTime()) <= SKEW_MS)
          ) {
            at = new Date(anchor.getTime() - durMin * 60_000);
            link = { derived: 'occurredAt' };
          }
        }
        payload = {
          kind: 'pump',
          amountMl: amount !== null && amount > 0 ? amount : null,
          occurredAt: at?.toISOString() ?? null,
          side,
          durationMin: durMin !== null && durMin > 0 ? durMin : null,
          ...(link ? { linked: link } : {}),
        };
        break;
      }
      case 'diaper': {
        // Wet / dirty / both from the words; the model's value only with its own words.
        const words =
          intents.filter((y) => y.kind === 'diaper').length === 1
            ? (diaperIn(ctx.text)?.kind ?? null)
            : null;
        const ev = evidenceOf(intent, 'diaper');
        const modelKind = f.diaper && ev && grounded(ev) ? f.diaper : null;
        const said = words ?? modelKind ?? (x(base, 'diaper') as 'wet' | 'dirty' | 'both' | null);
        if (f.diaper && said !== f.diaper) uncertain.delete('diaper');
        const c = clockOf(intent, 'time');
        if (!c) uncertain.delete('occurredAt');
        const at = r?.at ? new Date(r.at) : pointTime(c, base);
        payload = { kind: 'diaper', diaper: said ?? null, occurredAt: at?.toISOString() ?? null };
        break;
      }
      case 'growth': {
        const g =
          intents.filter((y) => y.kind === 'growth').length === 1 ? growthIn(ctx.text) : null;
        const pick = (
          fromWords: number | null | undefined,
          model: number | null | undefined,
          key: string,
        ) => {
          if (fromWords !== null && fromWords !== undefined) {
            if (model !== null && model !== undefined && Math.abs(model - fromWords) > 0.05) {
              // The model read another number than the words: the words win (checked).
              uncertain.add(key);
            }
            return fromWords;
          }
          if (model !== null && model !== undefined && model > 0) {
            // A number only the model saw: shown for review, never trusted as is.
            uncertain.add(key);
            return Math.round(model * 10) / 10;
          }
          return (x(base, key) as number | null) ?? null;
        };
        const weightKg = pick(g?.weightKg, f.weightKg, 'weightKg');
        // The head's number read as the length by the model ("vòng đầu 39cm") is not a length.
        const lengthCm =
          g && g.lengthCm === null && g.headCm !== null && f.lengthCm === g.headCm
            ? null
            : pick(g?.lengthCm, f.lengthCm, 'lengthCm');
        // Owner 2026-10-16: head circumference is saved with the record (no PART_NOT_SAVED).
        const headCm = pick(g?.headCm, f.headCm, 'headCm');
        // The measuring day: as said ("hôm qua đi khám"), else the model's day, else today.
        const d = relativeDateIn(ctx.text, today, 'past');
        const measuredOn =
          d?.date ??
          (f.dayOffset !== null && f.dayOffset !== undefined
            ? addDaysIso(today, f.dayOffset)
            : ((x(base, 'measuredOn') as string | null) ?? today));
        if (d && !d.certain) uncertain.add('measuredOn');
        payload = { kind: 'growth', weightKg, lengthCm, measuredOn, headCm };
        break;
      }
      default:
        notices.push({ kind, code: 'MODULE_UNAVAILABLE' });
        continue;
    }

    // LUMI-07: a timer draft is checked by its time only (its side is the form's default when
    // not said); LUMI-04: a time the model misread is always flagged.
    if (payload.kind === 'timer') uncertain.clear();
    for (const m of misread) uncertain.add(m);
    const checked = draftPayloadSchema.safeParse(payload);
    if (!checked.success) {
      notices.push({ kind, code: 'VALIDATION_FAILED' });
      continue;
    }
    // LUMI-11: plus what only the baby's zone tells (a reminder whose time is already gone).
    const problems = [
      ...new Set([
        ...draftProblems(checked.data, anchor),
        ...zoneDraftProblems(checked.data, ctx.now, zone),
      ]),
    ];
    if (checked.data.kind === 'observation' && checked.data.date > today) uncertain.add('date');
    // Lumi 2026-10-16: what is missing comes from the payload (the kind's required fields that
    // are empty), never from the model's list; only the draft's own, filled fields are unsure.
    void missing;
    const review = reviewFields(checked.data, problems, uncertain);
    drafts.push({
      payload: checked.data,
      missingFields: review.missing,
      uncertainFields: review.uncertain,
      problems,
      warnings: [],
      ...(replaces ? { replaces } : {}),
      ...(edit ? { op: 'update' as const, targetRecordId: edit } : {}),
    });
    if (replaces) notices.push({ kind, code: 'CORRECTION_APPLIED' });
  }

  // Morning or evening first; the answer applies only to the times it names (LUMI-03).
  if (!ampm && needsAmpm.some(Boolean) && !ctx.asked.has('time.ampm') && ctx.round < 4) {
    return { kind: 'ask', clarification: ampmQuestion([...new Set(openClocks)]) };
  }
  if (ask) return { kind: 'ask', clarification: ask };

  // Possible duplicates (a warning to acknowledge, never a merge).
  for (const d of drafts) {
    // L7: an edit of a saved record is never a duplicate of itself.
    if (d.op === 'update' || d.op === 'delete') continue;
    if (await duplicateSuspected(ctx, d.payload)) {
      d.warnings.push('duplicate_suspected');
      notices.push({ kind: d.payload.kind, code: 'DUPLICATE_SUSPECTED' });
    }
  }
  return { kind: 'drafts', drafts, notices };
}

/** L7: the care records a follow-up may change or delete (`confirmDraftItem` writes them). */
export const editableKinds: ReadonlySet<DraftKind> = new Set([
  'bottle',
  'breast',
  'sleep',
  'pump',
  'diaper',
]);

const blankFields = {
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
} satisfies ModelIntent['fields'];

/**
 * Lumi 2026-10-16: the model's items checked against the words before planning.
 * - The same words as the previous turn are never a correction (they replaced a waiting draft).
 * - A sleep / feeding "observation" without a difference cue (`observationCueIn`: khó ngủ, quấy
 *   hơn, ăn ít…) next to a state, a log or a sleep length is a plain log, not an observation.
 * - A state the model missed (or read as an observation) gets its sleep / breast item, with the
 *   clock time of the words ("bắt đầu ngủ lúc 21h") as its start or end.
 */
export function checkIntents(
  ctx: Pick<TextContext, 'text' | 'previous'>,
  raw: ModelIntent[],
  states: ReturnType<typeof careStatesIn>,
): ModelIntent[] {
  const repeat = ctx.previous !== null && sameMessage(ctx.text, ctx.previous.text);
  let out = raw.map((i) => (repeat && i.correctsPrevious ? { ...i, correctsPrevious: false } : i));
  const cue = observationCueIn(ctx.text);
  const logs = out.some((i) => i.kind === 'sleep' || i.kind === 'breast' || i.kind === 'bottle');
  const length = durationsIn(ctx.text).length > 0;
  const plain = (i: ModelIntent) =>
    i.kind === 'observation' &&
    !cue &&
    ((i.fields.observation === 'sleep' &&
      (states.some((st) => st.timer === 'sleep') || logs || length)) ||
      (i.fields.observation === 'feeding' &&
        (states.some((st) => st.timer === 'breast') ||
          out.some((o) => o.kind === 'breast' || o.kind === 'bottle'))));
  const dropped = out.filter(plain);
  out = out.filter((i) => !plain(i));
  const clock = clockTimeIn(ctx.text);
  for (const st of states) {
    if (out.some((i) => i.kind === st.timer)) continue;
    const at = clock?.hhmm ?? null;
    out.push({
      kind: st.timer,
      fields: {
        ...blankFields,
        time: st.action === 'start' ? at : null,
        endTime: st.action === 'stop' ? at : null,
        side: st.side,
        phase: st.action,
      },
      evidence: [{ field: 'phase', text: st.text }],
      uncertainFields: [],
      missingFields: [],
      correctsPrevious: false,
    });
  }
  // "bé ngủ 2 tiếng" read as an observation: it is the sleep log (its start is asked).
  if (
    dropped.some((d) => d.fields.observation === 'sleep') &&
    !out.some((i) => i.kind === 'sleep')
  ) {
    out.push({
      kind: 'sleep',
      fields: { ...blankFields },
      evidence: [],
      uncertainFields: [],
      missingFields: [],
      correctsPrevious: false,
    });
  }
  return careBackstops(ctx.text, out);
}

/** Words that something is going on now or has just ended (a timer start / stop). */
const phaseCue =
  /(?<![\p{L}])(?:dang|vua|moi|bat dau|roi|rui|xong|day|thuc|tinh|now|currently|just|is|started|woke|awake|done|finished|asleep|sleeping|napping|nursing|feeding)(?![\p{L}])/u;

const feedWords =
  /(?<![\p{L}])(?:cho (?:be |con )?(?:bu|uong|an|ti)|bu binh|be bu|con bu|be uong|bottle|fed|feed)(?![\p{L}])/u;
const breastWords = /(?<![\p{L}])(?:bu me|ti me|cho bu me|breastf\w*|nurs\w*)(?![\p{L}])/u;
const measureWords =
  /(?<![\p{L}])(?:nang|can nang|can|cao|dai|chieu dai|vong dau|tang truong|weigh\w*|length|tall|head)(?![\p{L}])/u;

/** The words carry a care log the model may have missed or misnamed (pump, diaper, growth). */
export function careCueIn(text: string): boolean {
  return pumpCueIn(text) || diaperIn(text) !== null || growthCue(text) !== null;
}

/** A measurement said about the baby (never "2kg sữa 500k": money without measuring words). */
function growthCue(text: string) {
  const g = growthIn(text);
  if (!g) return null;
  if (looksLikeSpending(text) && !measureWords.test(foldVi(text))) return null;
  return g;
}

/**
 * Lumi fixes 2026-10-16 (LUMI-01, LUMI-15): the care logs in the words, whatever the model named
 * them — deterministic, so a reply of the wrong kind never becomes a wrong record one tap away:
 * - "hút sữa 120ml" is a pumping session, never a bottle feed (nor a breastfeed);
 * - "thay tã ướt", "bé vừa ị" is a diaper change, never an observation or a meal;
 * - "bé nặng 5,2kg", "hôm qua đi khám bé nặng 5kg8" is a growth record, never an expense (a
 *   clinic visit with no amount said is not money);
 * - a log the model missed entirely gets its item from the words (time from the message's only
 *   clock when nothing else has one);
 * - "bé bu 120m" (a bare m after bú, ≥ 50, no "mẹ") is a 120 ml bottle, never a 2-hour breastfeed.
 */
export function careBackstops(text: string, raw: ModelIntent[]): ModelIntent[] {
  let out = [...raw];
  const f = foldVi(text);
  const tokens = clockTokensIn(text);
  const timed = (except: ModelIntent | null) =>
    out.some((i) => i !== except && (i.fields.time !== null || i.fields.endTime !== null));
  const soleTime = (except: ModelIntent | null) =>
    tokens.length === 1 && !timed(except)
      ? `${String(tokens[0]!.h).padStart(2, '0')}:${String(tokens[0]!.m).padStart(2, '0')}`
      : null;
  const item = (kind: DraftKind, fields: Partial<ModelIntent['fields']>): ModelIntent => ({
    kind,
    fields: { ...blankFields, ...fields },
    evidence: [],
    uncertainFields: [],
    missingFields: [],
    correctsPrevious: false,
  });
  // ---- LUMI-15: "bé bu 120m" ----
  const bare = bareMAmountIn(text);
  if (bare !== null && durationsIn(text).length === 0) {
    out = out.map((i) =>
      i.kind === 'breast' && (i.fields.durationMin === bare || i.fields.durationMin === null)
        ? {
            ...i,
            kind: 'bottle' as const,
            fields: { ...i.fields, amountMl: bare, durationMin: null, side: null },
            evidence: [...i.evidence.filter((e) => e.field !== 'durationMin')],
            uncertainFields: i.uncertainFields.filter((u) => u !== 'durationMin' && u !== 'side'),
          }
        : i,
    );
  }
  // ---- Pump ----
  if (pumpCueIn(text) && !out.some((i) => i.kind === 'pump')) {
    // A feed (or the model's "meal") named for pumping words is the pumping session.
    const feeds = out.filter(
      (i) =>
        i.kind === 'bottle' || i.kind === 'meal' || (i.kind === 'breast' && !breastWords.test(f)),
    );
    if (feeds.length === 1 && !feedWords.test(f.replace(/hut sua|vat sua/g, ''))) {
      const i = feeds[0]!;
      out = out.map((y) =>
        y === i
          ? {
              ...y,
              kind: 'pump' as const,
              fields: {
                ...y.fields,
                milk: null,
                title: null,
                amountMl: y.fields.amountMl ?? bottleMlIn(text)?.ml ?? null,
                side: y.fields.side ?? breastSideIn(text),
              },
            }
          : y,
      );
    } else if (feeds.length === 0) {
      out.push(
        item('pump', {
          amountMl: bottleMlIn(text)?.ml ?? null,
          side: breastSideIn(text),
          time: soleTime(null),
          durationMin: durationsIn(text).length === 1 ? durationsIn(text)[0]!.minutes : null,
        }),
      );
    } else {
      out.push(item('pump', { side: breastSideIn(text) }));
    }
  }
  // ---- Diaper ----
  const dia = diaperIn(text);
  if (dia && !out.some((i) => i.kind === 'diaper')) {
    const wrong = out.find(
      (i) =>
        i.kind === 'meal' ||
        (i.kind === 'observation' && (i.fields.observation === 'usual' || !observationCueIn(text))),
    );
    if (wrong) {
      out = out
        .filter((i) => i === wrong || !(i.kind === 'meal' || i.kind === 'observation'))
        .map((i) =>
          i === wrong
            ? item('diaper', {
                diaper: dia.kind,
                time: i.fields.time ?? soleTime(i),
                dayOffset: i.fields.dayOffset,
              })
            : i,
        );
    } else {
      out.push(item('diaper', { diaper: dia.kind, time: soleTime(null) }));
    }
  }
  // ---- Growth ----
  const g = growthCue(text);
  if (
    g &&
    (g.weightKg !== null || g.lengthCm !== null || g.headCm !== null) &&
    !out.some((i) => i.kind === 'growth')
  ) {
    // A clinic visit read as an expense with no money said is the measurement, not a cost.
    const noMoney = moneyAmountsIn(text).length === 0;
    out = out.filter(
      (i) =>
        !(i.kind === 'expense' && noMoney && !(i.fields.amount && i.fields.amount > 0)) &&
        i.kind !== 'meal' &&
        !(i.kind === 'observation' && !observationCueIn(text)),
    );
    out.push(
      item('growth', {
        weightKg: g.weightKg,
        lengthCm: g.lengthCm,
        headCm: g.headCm,
        dayOffset: /(?<![\p{L}])(?:hom qua|yesterday)(?![\p{L}])/u.test(f)
          ? -1
          : /(?<![\p{L}])hom kia(?![\p{L}])/u.test(f)
            ? -2
            : 0,
      }),
    );
  }
  return out;
}

/**
 * LUMI-16 (owner 2026-10-16): purchases checked against the words (contracts `purchasesIn`),
 * before anything is planned:
 * - only plans / to-dos and questions ("mai đi mua sữa", "nhớ mua bỉm", "mua sữa nào tốt?") →
 *   no expense; a plan the model read as an expense becomes a reminder in the person's words
 *   (unless the model already returned one);
 * - a purchase made ("mua hai hộp sữa", "vừa mua bỉm ở Con Cưng", "đặt tã online") the model
 *   missed → an expense with no amount (the person adds it on the card);
 * `shopping`: only a question about buying is left, so the reply says what Lumi can do with it.
 */
export function checkPurchases(
  text: string,
  raw: ModelIntent[],
): { intents: ModelIntent[]; shopping: boolean } {
  const buys = purchasesIn(text);
  if (buys.length === 0) return { intents: raw, shopping: false };
  let out = [...raw];
  const item = (
    kind: DraftKind,
    fields: Partial<ModelIntent['fields']>,
    evidence: ModelIntent['evidence'],
  ): ModelIntent => ({
    kind,
    fields: { ...blankFields, ...fields },
    evidence,
    uncertainFields: [],
    missingFields: [],
    correctsPrevious: false,
  });
  // Every purchase in the words was made ("đặt tã online"): a reminder the model made of it, with
  // no day or time said, is that purchase misread (live 2026-10-16), never a to-do.
  if (buys.every((b) => b.mood === 'done')) {
    const f = (t: string) => foldVi(t).replace(/\s+/g, ' ').trim();
    out = out.map((i) => {
      if (i.kind !== 'reminder' || i.fields.date || i.fields.time) return i;
      const title = f(i.fields.title ?? '');
      const b = buys.find(
        (x) =>
          x.what !== null &&
          title !== '' &&
          (f(x.phrase).includes(title) || title.includes(f(x.what!))),
      );
      return b
        ? item('expense', { title: b.what, merchant: b.merchant }, [
            { field: 'title', text: b.what! },
            ...(b.merchant ? [{ field: 'merchant' as const, text: b.merchant }] : []),
          ])
        : i;
    });
  }
  const hadExpense = out.some((i) => i.kind === 'expense');
  const hasReminder = out.some((i) => i.kind === 'reminder');
  if (buys.every((b) => b.mood !== 'done')) {
    out = out.filter((i) => i.kind !== 'expense');
    if (hadExpense && !hasReminder) {
      for (const b of buys) {
        if (b.mood !== 'plan' || b.what === null) continue;
        out.push(item('reminder', { title: b.title }, [{ field: 'title', text: b.title }]));
      }
    }
  } else if (!hadExpense && !hasReminder) {
    const b = buys.find((x) => x.mood === 'done' && x.what !== null);
    if (b) {
      out.push(
        item('expense', { title: b.what, merchant: b.merchant }, [
          { field: 'title', text: b.what! },
          ...(b.merchant ? [{ field: 'merchant' as const, text: b.merchant }] : []),
        ]),
      );
    }
  }
  const shopping =
    buys.some((b) => b.mood === 'question') &&
    !out.some((i) => i.kind === 'expense' || i.kind === 'reminder');
  return { intents: out, shopping };
}

/** A value of the previous draft's payload (corrections keep what was not corrected). */
function x(base: DraftPayload | null, key: string): unknown {
  return base ? ((base as Record<string, unknown>)[key] ?? null) : null;
}

// ---------- The server's questions (the words and chips are ours) ----------

export function ampmQuestion(clocks: readonly string[] = []): Clarification {
  // LUMI-03: the question names the time(s) it is about; other times of the message keep theirs.
  const list = clocks.slice(0, 3).join(', ');
  return {
    id: 'pending',
    field: 'time.ampm',
    question:
      clocks.length === 0
        ? L('Giờ đó là buổi sáng hay chiều tối?', 'Was that in the morning or the evening?')
        : clocks.length === 1
          ? L(`${list} là buổi sáng hay chiều tối?`, `Was ${list} in the morning or the evening?`)
          : L(`${list} là buổi sáng hay chiều tối?`, `Were ${list} in the morning or the evening?`),
    choices: [
      { id: 'am', label: L('Buổi sáng', 'Morning') },
      { id: 'pm', label: L('Chiều / tối', 'Afternoon / evening') },
    ],
    // L1 (P-167 #3): "Sáng", "tối", "23:21" typed in the composer answer it too.
    allowText: true,
  };
}

/** Folded words of a label or an answer ("Chiều / tối" → "chieu toi"). */
const answerWords = (x: string) =>
  foldVi(x)
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .trim();

/**
 * L1 (P-167 #3): how a typed answer reads for an open question.
 * - `time.ampm`: the half of the day it names (`choiceId` am / pm; trưa / đêm stay as text the
 *   planner reads per hour), else unreadable.
 * - A question with chips and no free answer: the one chip its words name ("khó vào giấc",
 *   "Giấc đêm", "cả hai"), else unreadable.
 * - Any other question takes the text as it is (`time.missing`, `time.start` read it later).
 * Unreadable → the question is asked again, never a new task or the help text.
 */
export function readTypedAnswer(
  c: Pick<Clarification, 'field' | 'choices' | 'allowText'>,
  text: string,
): { choiceId: string | null } | 'unreadable' {
  if (c.field === 'time.ampm') {
    const half = dayHalfAnswerIn(text);
    if (half === null) return 'unreadable';
    return { choiceId: half === 'am' || half === 'pm' ? half : null };
  }
  // L1b: "bây giờ", "vừa xong" to "Việc này lúc mấy giờ?" is the "Vừa xong" chip.
  if (c.field === 'time.missing' && nowAnswerIn(text)) return { choiceId: 'ago_0' };
  if (c.allowText) return { choiceId: null };
  const said = answerWords(text);
  if (said.length < 2) return 'unreadable';
  const has = (hay: string, needle: string) => ` ${hay} `.includes(` ${needle} `);
  const hits = c.choices.filter((ch) =>
    [ch.label.vi, ch.label.en].map(answerWords).some((l) => l && (has(l, said) || has(said, l))),
  );
  return hits.length === 1 ? { choiceId: hits[0]!.id } : 'unreadable';
}

/** "bây giờ" / "giờ" / "vừa xong" / "mới xong" / "now" as a whole answer. */
export function nowAnswerIn(text: string): boolean {
  const f = answerWords(text);
  return /^(ngay )?(bay gio|gio|vua|vua xong|vua moi xong|moi xong|xong roi|now|right now|just now)$/u.test(
    f,
  );
}

/**
 * L1b (P-168 #2): whether words sent as a new message answer the open question [c] rather than
 * start something of their own: a readable answer, or a short reply (≤ 4 words, or a clock,
 * an "ago" or a half of the day) — never words that carry a state of the baby ("đang ngủ").
 */
export function answersOpenQuestion(
  c: Pick<Clarification, 'field' | 'choices' | 'allowText'>,
  text: string,
): boolean {
  if (careStatesIn(text).length > 0) return false;
  const words = answerWords(text).split(' ').filter(Boolean).length;
  if (words === 0) return false;
  if (words <= 4) return true;
  if (clockTimeIn(text) !== null || agoIn(text) !== null || dayHalfAnswerIn(text) !== null) {
    return true;
  }
  return readTypedAnswer(c, text) !== 'unreadable' && !c.allowText;
}

/** "Việc này lúc mấy giờ?": Vừa xong / 30 phút trước / 1 tiếng trước, or a typed time. */
export function timeMissingQuestion(
  ctx: Pick<TextContext, 's' | 'anchor'>,
  durationMin: number | null,
): Clarification {
  const at = (min: number) => localClock(ctx.s.zone, new Date(ctx.anchor.getTime() - min * 60_000));
  void durationMin;
  return {
    id: 'pending',
    field: 'time.missing',
    question: L('Việc này lúc mấy giờ?', 'What time was it?'),
    choices: [
      { id: 'ago_0', label: L(`Vừa xong (${at(0)})`, `Just now (${at(0)})`) },
      { id: 'ago_30', label: L(`30 phút trước (${at(30)})`, `30 min ago (${at(30)})`) },
      { id: 'ago_60', label: L(`1 tiếng trước (${at(60)})`, `1 hour ago (${at(60)})`) },
    ],
    allowText: true,
  };
}

/**
 * "Bé bắt đầu ngủ lúc mấy giờ?" for a sleep length with no end point: two chips on the half hour
 * no later than [latest] (= send time − length, so the sleep never ends in the future), e.g.
 * "21:00 tối qua" / "22:00 tối qua", or a typed time.
 */
export function timeStartQuestion(
  ctx: Pick<TextContext, 's' | 'anchor'>,
  latest: Date,
  /** L10: a feed still going on asks when it began. */
  what: 'sleep' | 'breast' = 'sleep',
): Clarification {
  const zone = ctx.s.zone;
  const today = localDateIn(zone, ctx.anchor);
  const floor = new Date(Math.floor(latest.getTime() / 1_800_000) * 1_800_000);
  const chips = [new Date(floor.getTime() - 3_600_000), floor];
  const label = (t: Date) => {
    const date = localDateIn(zone, t);
    const clock = localClock(zone, t);
    const h = Number(clock.slice(0, 2));
    if (date === today) return L(`${clock} hôm nay`, `${clock} today`);
    if (date === addDaysIso(today, -1)) {
      return h >= 18
        ? L(`${clock} tối qua`, `${clock} last night`)
        : L(`${clock} hôm qua`, `${clock} yesterday`);
    }
    return L(
      `${clock} ${date.slice(8, 10)}/${date.slice(5, 7)}`,
      `${clock} ${date.slice(8, 10)}/${date.slice(5, 7)}`,
    );
  };
  return {
    id: 'pending',
    field: 'time.start',
    question:
      what === 'breast'
        ? L('Bé bắt đầu bú lúc mấy giờ?', 'When did the feed start?')
        : L('Bé bắt đầu ngủ lúc mấy giờ?', 'When did the sleep start?'),
    choices: chips.map((t) => ({
      id: `at_${localDateIn(zone, t)}_${localClock(zone, t)}`,
      label: label(t),
    })),
    allowText: true,
  };
}

/**
 * Lumi 2026-10-16: "Bé bắt đầu ngủ lúc mấy giờ?" for a sleep whose END is known but not its
 * start ("dậy rồi" with no timer running, "dậy lúc 6h"): chips by length ending at [end] —
 * "Khoảng 1 tiếng (từ 00:05)", 2, 3 tiếng — or a typed time / length. Same field and choice ids
 * as `timeStartQuestion` (`at_<date>_<HH:mm>`), so the answer is read the same way.
 */
export function sleepStartQuestion(
  ctx: Pick<TextContext, 's' | 'anchor'>,
  end: Date,
): Clarification {
  const zone = ctx.s.zone;
  const today = localDateIn(zone, ctx.anchor);
  const chips = [60, 120, 180].map((m) => ({ m, t: new Date(end.getTime() - m * 60_000) }));
  const from = (t: Date) => {
    const clock = localClock(zone, t);
    const date = localDateIn(zone, t);
    if (date === today) return L(clock, clock);
    if (date === addDaysIso(today, -1)) return L(`${clock} hôm qua`, `${clock} yesterday`);
    return L(
      `${clock} ${date.slice(8, 10)}/${date.slice(5, 7)}`,
      `${clock} ${date.slice(8, 10)}/${date.slice(5, 7)}`,
    );
  };
  return {
    id: 'pending',
    field: 'time.start',
    question: L(
      `Bé dậy lúc ${localClock(zone, end)}. Bé bắt đầu ngủ lúc mấy giờ?`,
      `Woke at ${localClock(zone, end)}. When did the sleep start?`,
    ),
    choices: chips.map(({ m, t }) => ({
      id: `at_${localDateIn(zone, t)}_${localClock(zone, t)}`,
      label: L(
        `Khoảng ${m / 60} tiếng (từ ${from(t).vi})`,
        `About ${m / 60} h (from ${from(t).en})`,
      ),
    })),
    allowText: true,
  };
}

// ---------- Duplicates ----------

/**
 * A care log very like one already in the baby's records (same kind within 10 minutes; a bottle
 * within 10 % of the amount) or an expense like one the household logged (`expenseDuplicateSuspected`).
 */
async function duplicateSuspected(ctx: TextContext, p: DraftPayload): Promise<boolean> {
  if (p.kind === 'expense') {
    return expenseDuplicateSuspected(ctx.db, {
      familyId: ctx.s.familyId,
      babyIds: await householdBabyIds(ctx.db, ctx.s.familyId, ctx.s.babyId),
      date: p.date,
      total: p.totalMinor,
      currency: p.currency,
      merchant: p.merchant,
      sha256s: [],
      excludeExpenseId: null,
      excludeAttachmentIds: [],
    });
  }
  if ((p.kind === 'bottle' || p.kind === 'breast') && p.occurredAt) {
    return careDuplicateIn(ctx.db, ctx.s.babyId, p, null);
  }
  return false;
}

// ---------- Context for the request ----------

/** Built-in category names the model sees (the app's words; custom ones keep their own). */
const builtInNames: Record<string, { vi: string; en: string }> = {
  c_childcare: L('Giữ trẻ & học', 'Childcare & learning'),
  c_milk: L('Sữa & ăn dặm', 'Milk & solids'),
  c_diaper: L('Tã & vệ sinh', 'Diapers & hygiene'),
  c_health: L('Y tế & tiêm chủng', 'Health & vaccines'),
  c_clothes: L('Quần áo', 'Clothes'),
  c_other: L('Khác', 'Other'),
};

/** The household's visible spending categories (built-ins, then custom ones not hidden). */
export async function spendingCategoriesOf(
  db: Firestore,
  familyId: string,
  locale: 'vi' | 'en',
): Promise<{ id: string; name: string }[]> {
  const snap = await db.collection(`families/${familyId}/spendingCategories`).get();
  const hidden = new Set(snap.docs.filter((d) => d.get('hidden') === true).map((d) => d.id));
  const out: { id: string; name: string }[] = builtInCategories
    .filter((c) => !hidden.has(c.id) || c.id === otherCategoryId)
    .map((c) => ({ id: c.id, name: builtInNames[c.id]?.[locale] ?? c.id }));
  for (const d of snap.docs) {
    if (builtInNames[d.id] || d.get('hidden') === true) continue;
    const name = d.get('name');
    if (typeof name === 'string' && name.trim() && /^c_[a-z0-9]{3,20}$/.test(d.id)) {
      out.push({ id: d.id, name: name.trim().slice(0, 24) });
    }
  }
  return out.slice(0, 40);
}

/** Dates around the anchor with their weekday (the model maps "thứ 6", "mai" through it). */
export function calendarAround(today: string, locale: 'vi' | 'en') {
  const vi = ['Chủ nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
  const en = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const rel: Record<number, [string, string]> = {
    [-2]: ['hôm kia', 'the day before yesterday'],
    [-1]: ['hôm qua', 'yesterday'],
    0: ['hôm nay', 'today'],
    1: ['mai', 'tomorrow'],
    2: ['mốt', 'the day after tomorrow'],
  };
  const out: { date: string; weekday: string; label: string | null }[] = [];
  for (let i = -7; i <= 14; i++) {
    const date = addDaysIso(today, i);
    const [y, m, d] = date.split('-').map(Number) as [number, number, number];
    const dow = new Date(Date.UTC(y, m - 1, d)).getUTCDay();
    out.push({
      date,
      weekday: locale === 'vi' ? `${vi[dow]} (${en[dow]})` : en[dow]!,
      label: rel[i] ? (locale === 'vi' ? rel[i]![0] : rel[i]![1]) : null,
    });
  }
  return out;
}

/** The household's Chi tiêu currency: its setting, else its country's, else VND. */
export async function householdCurrencyOf(
  db: Firestore,
  s: TrustedScope,
  currencyForCountry: (c: string | null) => ExpenseCurrency,
): Promise<ExpenseCurrency> {
  const snap = await db.doc(`families/${s.familyId}/spendingSettings/main`).get();
  const c = snap.get('currency');
  if (typeof c === 'string' && c.length === 3) return c as ExpenseCurrency;
  return currencyForCountry(s.ctx.family.country);
}

/**
 * The sender's previous turn in this chat, for corrections ("à không, 150ml"): their own last
 * task of the same conversation within 60 minutes, with its drafts.
 */
export async function previousTurnOf(
  db: Firestore,
  x: {
    previousTaskId: string | null | undefined;
    ownerUid: string;
    conversationId: string;
    anchor: Date;
  },
): Promise<PreviousTurn | null> {
  if (!x.previousTaskId) return null;
  const snap = await db.doc(`assistantTasks/${x.previousTaskId}`).get();
  if (!snap.exists || snap.get('ownerUid') !== x.ownerUid) return null;
  if (snap.get('conversationId') !== x.conversationId) return null;
  const at = (snap.get('anchorInstant') as Timestamp | undefined)?.toDate();
  if (!at || x.anchor.getTime() - at.getTime() > 60 * 60_000) return null;
  const text = (snap.get('input.text') as string | null | undefined) ?? '';
  const drafts = await snap.ref.collection('drafts').get();
  return {
    taskId: snap.id,
    text,
    drafts: drafts.docs
      .map((d) => ({
        id: d.id,
        state: d.get('state') as string,
        payload: d.get('payload') as DraftPayload,
        recordLink: (d.get('recordLink') as string | null | undefined) ?? null,
        index: (d.get('itemIndex') as number | undefined) ?? 0,
      }))
      .sort((a, b) => a.index - b.index)
      .map(({ index: _i, ...d }) => {
        void _i;
        return d;
      }),
  };
}

/** What the model sees of the previous turn: kinds and values in local time, no ids. */
export function previousForModel(p: PreviousTurn | null, zone: string, today: string) {
  if (!p) return null;
  const local = (iso: string | null | undefined) => {
    if (!iso) return null;
    const t = new Date(iso);
    const date = localDateIn(zone, t);
    return { time: localClock(zone, t), dayOffset: date === today ? 0 : date < today ? -1 : 1 };
  };
  return {
    text: p.text,
    drafts: p.drafts
      .filter((d) => d.state !== 'discarded')
      .map((d) => {
        const q = d.payload as Record<string, unknown>;
        // L9: the id the model names in `target` (the index in [p.drafts], as the resolver maps it).
        const out: Record<string, unknown> = {
          id: `i${p.drafts.indexOf(d) + 1}`,
          kind: d.payload.kind,
          saved: d.state === 'saved',
        };
        for (const [k, v] of Object.entries(q)) {
          if (k === 'kind' || v === null || k === 'babyId' || k === 'keepReceipt' || k === 'linked')
            continue;
          if (k === 'occurredAt' || k === 'startedAt' || k === 'endedAt')
            out[k] = local(v as string);
          else out[k] = v;
        }
        return out;
      }),
  };
}
