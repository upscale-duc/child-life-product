import type { Firestore, Timestamp } from 'firebase-admin/firestore';
import {
  addDaysIso,
  agoIn,
  bottleMlIn,
  breastSideIn,
  builtInCategories,
  careStatesIn,
  categoryHintIn,
  clockTimeIn,
  completeSpan,
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
import { expenseDuplicateSuspected, householdBabyIds } from './assistant-writers-images.js';

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
  drafts: { id: string; state: string; payload: DraftPayload; recordLink: string | null }[];
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
  | 'TIMER_RUNNING';

export interface TextNotice {
  kind: DraftKind;
  code: TextNoticeCode;
  link?: string;
  /** TIMER_RUNNING: which timer and since when. */
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

/** Draft field each model field fills, per kind (for uncertain / missing lists). */
const draftField: Record<string, Partial<Record<DraftKind, string>>> = {
  amountMl: { bottle: 'amountMl' },
  milk: { bottle: 'milk' },
  // Lumi 2026-10-16: an observation has no time; its `date` comes from dayOffset.
  time: {
    bottle: 'occurredAt',
    breast: 'occurredAt',
    sleep: 'startedAt',
    reminder: 'time',
  },
  dayOffset: {
    bottle: 'occurredAt',
    breast: 'occurredAt',
    sleep: 'startedAt',
    observation: 'date',
  },
  endTime: { sleep: 'endedAt', breast: 'occurredAt' },
  endDayOffset: { sleep: 'endedAt' },
  durationMin: { breast: 'durationMin', sleep: 'durationMin' },
  side: { breast: 'side' },
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

/** One stated clock time and how sure its half of the day is. */
interface Clock {
  h: number;
  m: number;
  /** The model's day offset (0, −1, −2). */
  offset: number;
  /** "8 giờ" with no morning / evening anywhere: both halves are possible. */
  ambiguous: boolean;
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
  const states = careStatesIn(ctx.text);
  const intents = checkIntents(ctx, modelIntents, states);
  const today = localDateIn(zone, anchor);
  const all = [ctx.text, ...ctx.answerTexts].join(' \n ');
  const haystack = foldVi([all, ctx.previous?.text ?? ''].join(' \n '));
  // A correction ("nhầm, 10h30 mới dậy") reads its morning / evening from the turn it corrects.
  const correcting = intents.some((i) => i.correctsPrevious === true) && ctx.previous !== null;
  const periodSaid = hasDayPeriod(correcting ? `${all} \n ${ctx.previous!.text}` : all);
  // In a batch where another log has a time, a log without one is left for the person to fill
  // (no question: none of the quick choices would fit "rồi bú thêm 60ml").
  const timedLogs = intents.filter(
    (i) =>
      (i.kind === 'bottle' || i.kind === 'breast' || i.kind === 'sleep') &&
      (i.fields.time !== null || i.fields.endTime !== null),
  ).length;
  const saysPastDay = pastDayWords.test(foldVi(ctx.text));
  const ampmChoice = ctx.answers.get('time.ampm')?.choiceId;
  const ampm = ampmChoice === 'am' || ampmChoice === 'pm' ? ampmChoice : null;
  const said = durationsIn(ctx.text).map((d) => d.minutes);
  const ago = agoIn(ctx.text);
  const inst = (date: string, h: number, m: number) => localInstant(zone, date, hhmmOf(h, m));
  const grounded = (t: string) => {
    const f = foldVi(t).trim();
    return f.length > 0 && haystack.includes(f);
  };
  const evidenceOf = (i: ModelIntent, field: string) =>
    i.evidence.find((e) => e.field === field)?.text ?? null;

  const clockOf = (i: ModelIntent, field: 'time' | 'endTime'): Clock | null => {
    const v = i.fields[field];
    if (!v) return null;
    const [h, m] = v.split(':').map(Number) as [number, number];
    const offset =
      (field === 'time' ? i.fields.dayOffset : (i.fields.endDayOffset ?? i.fields.dayOffset)) ?? 0;
    let ambiguous = false;
    if (!periodSaid && !ampm) {
      const ev = evidenceOf(i, field);
      const c = ev ? clockTimeIn(ev) : null;
      ambiguous = c ? !c.explicit : h >= 1 && h <= 11;
    }
    if (ampm && !periodSaid) {
      const ev = evidenceOf(i, field);
      const c = ev ? clockTimeIn(ev) : null;
      if (!c || !c.explicit) {
        const base = h % 12;
        return { h: ampm === 'pm' ? base + 12 : base, m, offset, ambiguous: false };
      }
    }
    return { h, m, offset, ambiguous };
  };
  const hoursOf = (c: Clock) => (c.ambiguous ? [c.h % 12, (c.h % 12) + 12] : [c.h]);
  /** A correction that repeats the previous draft's clock keeps that draft's instant. */
  const fromBase = (c: Clock | null, iso: unknown): Date | null =>
    c && typeof iso === 'string' && localClock(zone, new Date(iso)) === hhmmOf(c.h, c.m)
      ? new Date(iso)
      : null;

  /** A completed log's instant: never silently in the future, last night when said that way. */
  const resolveLog = (c: Clock): Resolved => {
    const days = saysPastDay ? [c.offset] : [0, -1];
    for (const d of days) {
      const date = addDaysIso(today, d);
      const all = hoursOf(c).map((h) => inst(date, h, c.m));
      const valid = all.filter(
        (t) =>
          t.getTime() <= anchor.getTime() + SKEW_MS &&
          anchor.getTime() - t.getTime() <= 36 * 3_600_000,
      );
      if (valid.length === 1) return { at: valid[0]!, ambiguous: false };
      if (valid.length >= 2) {
        return { at: valid.sort((a, b) => b.getTime() - a.getTime())[0]!, ambiguous: true };
      }
      if (d === 0 && !saysPastDay) {
        const near = all.filter((t) => t.getTime() - anchor.getTime() <= NEAR_FUTURE_MS);
        if (near.length > 0) return { at: near[0]!, ambiguous: false };
      }
    }
    return { at: inst(addDaysIso(today, c.offset), hoursOf(c)[0]!, c.m), ambiguous: false };
  };

  /** A sleep start given its end: before it, within 18 h. */
  const resolveStartBefore = (c: Clock, end: Date): Resolved => {
    const endDate = localDateIn(zone, end);
    const cands: Date[] = [];
    for (const d of [0, -1]) {
      for (const h of hoursOf(c)) cands.push(inst(addDaysIso(endDate, d), h, c.m));
    }
    const valid = cands.filter(
      (t) => t.getTime() < end.getTime() && end.getTime() - t.getTime() <= MAX_SLEEP_MS,
    );
    if (valid.length === 0) {
      // Kept as said (INVALID_TIME for review), never flipped.
      return { at: inst(addDaysIso(today, c.offset), hoursOf(c)[0]!, c.m), ambiguous: false };
    }
    const halves = new Set(valid.map((t) => Number(localClock(zone, t).slice(0, 2)) >= 12));
    valid.sort((a, b) => b.getTime() - a.getTime());
    return { at: valid[0]!, ambiguous: c.ambiguous && halves.size > 1 };
  };

  /** A reminder's time on [date] (future): resolved when only one half is still ahead. */
  const resolveReminder = (c: Clock, date: string | null): { hhmm: string; ambiguous: boolean } => {
    const hours = hoursOf(c);
    if (hours.length === 1 || date === null) {
      return { hhmm: hhmmOf(hours[0]!, c.m), ambiguous: hours.length > 1 };
    }
    const ahead = hours.filter(
      (h) => inst(date, h, c.m).getTime() > ctx.now.getTime() - 5 * 60_000,
    );
    if (ahead.length === 1) return { hhmm: hhmmOf(ahead[0]!, c.m), ambiguous: false };
    return { hhmm: hhmmOf(hours[0]!, c.m), ambiguous: ahead.length > 1 };
  };

  /** A duration the person said (the model's when it is one of them, else the only one said). */
  const durationFor = (i: ModelIntent): { min: number | null; uncertain: boolean } => {
    const d = i.fields.durationMin;
    if (d !== null && Number.isInteger(d) && d > 0) {
      if (said.length === 0 || said.includes(d)) return { min: d, uncertain: false };
      if (said.length === 1) return { min: said[0]!, uncertain: false };
      return { min: d, uncertain: true };
    }
    if (d !== null) return { min: null, uncertain: true };
    const sameKind = intents.filter((x) => x.kind === i.kind).length;
    if (
      sameKind === 1 &&
      said.length === 1 &&
      intents.filter((x) => x.kind === 'sleep' || x.kind === 'breast').length === 1
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

  const previousOf = (kind: DraftKind) =>
    ctx.previous?.drafts.find((d) => d.payload.kind === kind) ?? null;

  let reminderIndex = 0;
  let assignable: ScopeMember[] | null = null;

  /**
   * Lumi 2026-10-16: an ongoing sleep / feed drives the app's timer. `start` ("con đang ngủ",
   * "bắt đầu ngủ lúc 21h", "đang cho bú trái") → a `timer` start at the said time, else now — or,
   * when that timer already runs, a TIMER_RUNNING notice and a stop draft (end it / keep it).
   * `stop` ("dậy rồi", "dậy lúc 6h", "bú xong rồi") → a stop draft for the running timer; with no
   * timer, `finishedEnd` (a finished sleep that ended then; its start is asked). A length, both
   * times, or a correction make it a finished log instead.
   */
  const timerPlan = (
    i: ModelIntent,
    kind: 'sleep' | 'breast',
    durMin: number | null,
    base: DraftPayload | null,
  ): { payload: DraftPayload } | { finishedEnd: Date } | null => {
    const st = states.find((x) => x.timer === kind) ?? null;
    const phase = st?.action ?? i.fields.phase ?? null;
    if (!phase || durMin !== null || base) return null;
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
    if (startC && endC) return null;
    const running = ctx.timers?.[kind] ?? null;
    const when = (c: Clock | null): Date => {
      if (c) {
        const r = resolveLog(c);
        needsAmpm.push(r.ambiguous);
        return r.at ?? anchor;
      }
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
      if (running) {
        notices.push({
          kind: 'timer',
          code: 'TIMER_RUNNING',
          timer: { type: kind, since: running.startedAt },
        });
        return { payload: stopOf(running, anchor) };
      }
      const saidSide =
        st?.side ?? (i.fields.side === 'left' || i.fields.side === 'right' ? i.fields.side : null);
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
    const f = intent.fields;
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
    if (intent.correctsPrevious && ctx.previous) {
      const prev = previousOf(kind);
      if (prev && prev.state === 'saved') {
        notices.push({
          kind,
          code: 'PREVIOUS_SAVED',
          ...(prev.recordLink ? { link: prev.recordLink } : {}),
        });
        continue;
      }
      if (
        prev &&
        (prev.state === 'draft' || prev.state === 'needs_review' || prev.state === 'failed')
      ) {
        replaces = { taskId: ctx.previous.taskId, draftId: prev.id };
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
        let at: Date | null;
        const c = clockOf(intent, 'time');
        const kept = fromBase(c, x(base, 'occurredAt'));
        if (kept) {
          at = kept;
        } else if (c) {
          const r = resolveLog(c);
          at = r.at;
          needsAmpm.push(r.ambiguous);
        } else if (ago) {
          at = new Date(anchor.getTime() - ago.minutes * 60_000);
        } else if (base && 'occurredAt' in base && base.occurredAt) {
          at = new Date(base.occurredAt);
        } else {
          at = missingAt();
          if (!at && timedLogs === 0) askOnce(timeMissingQuestion(ctx, null));
        }
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
        const durMin = dur.min ?? (x(base, 'durationMin') as number | null) ?? null;
        const sideSaid =
          f.side ??
          (intents.filter((i) => i.kind === 'breast').length === 1 ? breastSideIn(ctx.text) : null);
        // Lumi 2026-10-16: a side not said takes the form's default (the other side of the last
        // feed, else both) — never a blocking gap.
        const side =
          sideSaid ??
          (x(base, 'side') as 'left' | 'right' | 'both' | null) ??
          ctx.nextBreastSide ??
          'both';
        if (sideSaid === null) uncertain.delete('side');
        let at: Date | null;
        const c = clockOf(intent, 'time');
        const endC = clockOf(intent, 'endTime');
        const kept = fromBase(c, x(base, 'occurredAt'));
        if (kept) {
          at = kept;
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
        } else if (endC && durMin) {
          const r = resolveLog(endC);
          needsAmpm.push(r.ambiguous);
          at = r.at ? new Date(r.at.getTime() - durMin * 60_000) : null;
          link = { derived: 'occurredAt' };
        } else if (ago && ago.justNow) {
          at = new Date(anchor.getTime() - (durMin ?? 0) * 60_000);
          if (durMin) link = { derived: 'occurredAt' };
        } else if (ago) {
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
        const finishedEnd = tp && 'finishedEnd' in tp ? tp.finishedEnd : null;
        let durMin = dur.min;
        const startC = clockOf(intent, 'time');
        const endC = clockOf(intent, 'endTime');
        let start: Date | null = null;
        let end: Date | null = null;
        const keptEnd = fromBase(endC, x(base, 'endedAt'));
        const keptStart = fromBase(startC, x(base, 'startedAt'));
        if (keptEnd) {
          end = keptEnd;
        } else if (finishedEnd) {
          // "dậy rồi" with no timer running: it ended then; the start is asked below.
          end = finishedEnd;
        } else if (endC) {
          const r = resolveLog(endC);
          end = r.at;
          needsAmpm.push(r.ambiguous);
        } else if (ago?.justNow && (durMin || startC)) {
          // "vừa ngủ dậy": it ended now.
          end = anchor;
        }
        if (keptStart) {
          start = keptStart;
        } else if (startC) {
          const r = end ? resolveStartBefore(startC, end) : resolveLog(startC);
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
        const span = completeSpan({
          start: start?.getTime() ?? null,
          end: end?.getTime() ?? null,
          durationMin: durMin,
        });
        if (span.inconsistent) {
          uncertain.add('durationMin');
          uncertain.add('endedAt');
        }
        durMin = span.durationMin;
        link =
          span.derived === 'start'
            ? { derived: 'startedAt' }
            : span.derived === 'end'
              ? { derived: 'endedAt' }
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
        const d = relativeDateIn(ctx.text, today, 'past');
        let date: string | null = d?.date ?? null;
        if (d && !d.certain) uncertain.add('date');
        if (!date && f.date && /^\d{4}-\d{2}-\d{2}$/.test(f.date) && f.date !== today) {
          date = f.date;
          uncertain.add('date');
        }
        date ??= today;
        const allowed = new Set(ctx.categories.map((c) => c.id));
        let categoryId = f.categoryId && allowed.has(f.categoryId) ? f.categoryId : null;
        categoryId ??= categoryHintIn([f.title ?? '', ctx.text].join(' '));
        if (categoryId === null || !allowed.has(categoryId)) {
          categoryId = otherCategoryId;
          if (!(f.categoryId === otherCategoryId)) uncertain.add('categoryId');
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
      default:
        notices.push({ kind, code: 'MODULE_UNAVAILABLE' });
        continue;
    }

    const checked = draftPayloadSchema.safeParse(payload);
    if (!checked.success) {
      notices.push({ kind, code: 'VALIDATION_FAILED' });
      continue;
    }
    const problems = draftProblems(checked.data, anchor);
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
    });
    if (replaces) notices.push({ kind, code: 'CORRECTION_APPLIED' });
  }

  // Morning or evening first (it changes every ambiguous time at once).
  if (!ampm && needsAmpm.some(Boolean) && !ctx.asked.has('time.ampm') && ctx.round < 4) {
    return { kind: 'ask', clarification: ampmQuestion() };
  }
  if (ask) return { kind: 'ask', clarification: ask };

  // Possible duplicates (a warning to acknowledge, never a merge).
  for (const d of drafts) {
    if (await duplicateSuspected(ctx, d.payload)) {
      d.warnings.push('duplicate_suspected');
      notices.push({ kind: d.payload.kind, code: 'DUPLICATE_SUSPECTED' });
    }
  }
  return { kind: 'drafts', drafts, notices };
}

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
  return out;
}

/** A value of the previous draft's payload (corrections keep what was not corrected). */
function x(base: DraftPayload | null, key: string): unknown {
  return base ? ((base as Record<string, unknown>)[key] ?? null) : null;
}

// ---------- The server's questions (the words and chips are ours) ----------

export function ampmQuestion(): Clarification {
  return {
    id: 'pending',
    field: 'time.ampm',
    question: L('Giờ đó là buổi sáng hay chiều tối?', 'Was that in the morning or the evening?'),
    choices: [
      { id: 'am', label: L('Buổi sáng', 'Morning') },
      { id: 'pm', label: L('Chiều / tối', 'Afternoon / evening') },
    ],
    allowText: false,
  };
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
    question: L('Bé bắt đầu ngủ lúc mấy giờ?', 'When did the sleep start?'),
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
        const out: Record<string, unknown> = { kind: d.payload.kind, saved: d.state === 'saved' };
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
