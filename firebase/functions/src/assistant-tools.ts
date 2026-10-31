import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import {
  addDaysIso,
  careSummary,
  dayBoundsIn,
  draftPayloadSchema,
  draftProblems,
  draftReviewFields,
  familyCan,
  hasDayPeriod,
  localDateIn,
  spansOverlap,
  type AssistantPart,
  type CareSummary,
  type Clarification,
  type DraftKind,
  type DraftPayload,
  type DraftProblem,
  type FamilyAction,
  type MemberGrant,
} from '@child-life/contracts';
import type { TrustedScope } from './assistant-common.js';
// Slice A3 (photos): Chi tiêu / reminder role checks and review fields (leaf module).
import { canCreateReminders, canRecordSpending } from './assistant-image-rules.js';
import type { ClarificationField, ModelIntent, ReadToolName } from './assistant-model.js';
import { assistantUsage } from './assistant-usage.js';
import { readRhythmRules, sleepFacts } from './rhythm.js';

/**
 * The tools the server runs for the assistant (brief p.7). The model only asks; these functions
 * run with the scope bound at task start (`TrustedScope`) and read nothing outside it.
 *
 * - Read tools (`care_summary`, `sleep_facts`, `usage_snapshot`): deterministic figures from the
 *   scope's records in its local day; never write.
 * - Prepare tools: turn validated intents into typed drafts (contracts `draftPayloadSchema`),
 *   with the form's checks (`draftProblems`) against the task's anchor; never write a record.
 * - Module registry: which draft kinds have a module and writer in this slice, and the family
 *   action (role) needed to save them.
 */

// ---------- Modules ----------

export interface ModuleEntry {
  /** A writer exists in `assistant-writers.ts` (A3 adds expense and reminder). */
  available: boolean;
  /** Who may save it (Rules `canLog` for care and check-ins: Cùng nuôi and Người chăm sóc). */
  action: FamilyAction | null;
  /** Slice A3: a role check that is not a family action (Chi tiêu rights, reminders). */
  can?: (m: MemberGrant) => boolean;
  /**
   * Slice A3: drafted from photos only. Rework 2026-10-15: no kind is photo-only any more (text
   * drafts expenses and reminders, `assistant-text.ts`); kept for older callers.
   */
  photoOnly?: boolean;
}

export const moduleRegistry: Record<DraftKind, ModuleEntry> = {
  bottle: { available: true, action: 'rhythm.checkin' },
  breast: { available: true, action: 'rhythm.checkin' },
  sleep: { available: true, action: 'rhythm.checkin' },
  observation: { available: true, action: 'rhythm.checkin' },
  // ---- Slice A3 (P-157): Chi tiêu (Rules `canRecordSpending`) and one-off reminders (Cùng
  // nuôi only). Rework 2026-10-15: from photos AND typed messages ("mua sữa hết 500k",
  // "nhắc mai 9h mua bỉm"). ----
  expense: { available: true, action: null, can: canRecordSpending },
  reminder: { available: true, action: null, can: canCreateReminders },
  // ---- end slice A3 ----
  // Lumi L5: a meal in the Ăn dặm diary (Rules `canLog`, like care records; the diary must be
  // on, checked where the draft is made and again on save).
  meal: { available: true, action: 'rhythm.checkin' },
  // Lumi timers 2026-10-16: the app's running timers (Rules `canLog`, like care records).
  timer: { available: true, action: 'rhythm.checkin' },
  // Lumi fixes 2026-10-16 (LUMI-01): the care module's other logs (Rules `canLog`).
  pump: { available: true, action: 'rhythm.checkin' },
  diaper: { available: true, action: 'rhythm.checkin' },
  growth: { available: true, action: 'rhythm.checkin' },
};

/** Slice A3: whether [member] may save a draft of [kind] (family action or module check). */
export function moduleAllows(kind: DraftKind, member: MemberGrant): boolean {
  const mod = moduleRegistry[kind];
  if (!mod.available) return false;
  if (mod.can) return mod.can(member);
  return mod.action !== null && familyCan(member, mod.action);
}

export const availableKinds = (Object.keys(moduleRegistry) as DraftKind[]).filter(
  (k) => moduleRegistry[k].available,
);

// ---------- Health rule (brief p.16, CH28): before anything else, no model, 0 credits ----------

/**
 * A conservative keyword list for urgent signs in Vietnamese (with and without diacritics) and
 * English. It never promises to catch everything (the app always shows a direct health entry);
 * a match routes to health support instead of the model. Sign ids follow contracts `healthSigns`
 * where one exists.
 */
const healthKeywords: Record<string, string[]> = {
  breathing: [
    'khó thở',
    'kho tho',
    'thở rít',
    'tho rit',
    'ngừng thở',
    'ngung tho',
    'thở gấp',
    'tím tái',
    'tim tai',
    'tím môi',
    'trouble breathing',
    'difficulty breathing',
    'not breathing',
    "can't breathe",
    'cannot breathe',
    'stopped breathing',
    'turning blue',
    'blue lips',
  ],
  seizure: ['co giật', 'co giat', 'seizure', 'convulsion', 'fitting'],
  lethargic: [
    'li bì',
    'li bi',
    'lừ đừ',
    'bất tỉnh',
    'bat tinh',
    'không tỉnh',
    'khong tinh',
    'khó đánh thức',
    'unresponsive',
    'hard to wake',
    "won't wake",
    'lethargic',
    'floppy',
  ],
  fever_young: ['sốt', 'fever', 'nóng sốt'],
  dehydration: ['mất nước', 'mat nuoc', 'không đi tiểu', 'dehydrat', 'no wet diaper'],
  poor_feeding: ['bỏ bú', 'bo bu', 'không chịu bú', 'refuses to feed', "won't feed", 'not feeding'],
  inconsolable: ['khóc thét', 'khóc không dứt', 'inconsolable', "won't stop crying"],
  bleeding: ['nôn ra máu', 'đi ngoài ra máu', 'chảy máu', 'vomiting blood', 'blood in'],
  injury: ['ngã đập đầu', 'chấn thương đầu', 'head injury', 'fell on head'],
  poisoning: ['ngộ độc', 'nuốt phải', 'poison', 'swallowed'],
};

const fold = (s: string) => s.normalize('NFC').toLocaleLowerCase('vi').replace(/\s+/g, ' ');

/** Sign ids found in [text] (empty when none). Substring matches on purpose: conservative. */
export function healthSignalsIn(text: string): string[] {
  const t = fold(text);
  return Object.entries(healthKeywords)
    .filter(([, words]) => words.some((w) => t.includes(fold(w))))
    .map(([sign]) => sign);
}

// ---------- Time (anchor = the task's original send instant, brief p.12) ----------

function zoneOffsetMs(zone: string, at: Date): number {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: zone,
    hourCycle: 'h23',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  }).formatToParts(at);
  const get = (t: string) => Number(parts.find((p) => p.type === t)?.value ?? 0);
  const asUtc = Date.UTC(
    get('year'),
    get('month') - 1,
    get('day'),
    get('hour'),
    get('minute'),
    get('second'),
  );
  return asUtc - Math.floor(at.getTime() / 1000) * 1000;
}

/** The instant of local [date] [hhmm] in [zone]. */
export function localInstant(zone: string, date: string, hhmm: string): Date {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  const [h, mi] = hhmm.split(':').map(Number) as [number, number];
  const naive = Date.UTC(y, m - 1, d, h, mi);
  let t = naive - zoneOffsetMs(zone, new Date(naive));
  t = naive - zoneOffsetMs(zone, new Date(t));
  return new Date(t);
}

export function localClock(zone: string, at: Date): string {
  return new Intl.DateTimeFormat('en-GB', {
    timeZone: zone,
    hourCycle: 'h23',
    hour: '2-digit',
    minute: '2-digit',
  }).format(at);
}

export function anchorOf(zone: string, at: Date) {
  return {
    date: localDateIn(zone, at),
    time: localClock(zone, at),
    weekday: new Intl.DateTimeFormat('en-US', { timeZone: zone, weekday: 'long' }).format(at),
    zone,
  };
}

/** Words that say which half of the day an hour is in (Vietnamese with diacritics, English). */
const periodWords = [
  'sáng',
  'trưa',
  'chiều',
  'tối',
  'đêm',
  'khuya',
  'rạng',
  'morning',
  'afternoon',
  'evening',
  'night',
  'tonight',
  'noon',
  'midnight',
];

/**
 * "8 giờ" with no morning / evening anywhere in the message is ambiguous (CH05): the server asks,
 * whatever the model returned. Hours 13–23 or 0 are explicit; so is any period word or am / pm
 * right after a number.
 */
export function needsPeriod(texts: readonly string[]): boolean {
  // Rework 2026-10-15: also unaccented periods next to a time ("9h sang", "toi qua").
  if (hasDayPeriod(texts.join(' '))) return false;
  const t = ` ${fold(texts.join(' '))} `;
  if (periodWords.some((w) => new RegExp(`(^|[^\\p{L}])${w}([^\\p{L}]|$)`, 'u').test(t))) {
    return false;
  }
  if (/\d\s*(am|pm|a\.m|p\.m)(?![\p{L}])/u.test(t)) return false;
  const hours = [
    ...t.matchAll(
      /(?:^|[^\d:])(\d{1,2})\s*(?:giờ|gio|h(?![\p{L}])|g(?![\p{L}])|:[0-5]\d|o'clock)/gu,
    ),
    ...t.matchAll(/(?:lúc|luc|at)\s+(\d{1,2})(?![\d:])/gu),
  ].map((m) => Number(m[1]));
  return hours.some((h) => h >= 1 && h <= 12);
}

/** Applies a "sáng / chiều-tối" answer to a model time (never otherwise moved). */
export function applyPeriod(hhmm: string, period: 'am' | 'pm' | null): string {
  if (!period) return hhmm;
  const [h, m] = hhmm.split(':').map(Number) as [number, number];
  if (period === 'pm' && h >= 1 && h <= 11)
    return `${String(h + 12).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
  if (period === 'am' && h === 12) return `00:${String(m).padStart(2, '0')}`;
  return hhmm;
}

// ---------- Clarification catalog (the model picks a field; the words are ours) ----------

const L = (vi: string, en: string) => ({ vi, en });

export function clarificationFor(field: ClarificationField, id: string): Clarification {
  switch (field) {
    case 'time.ampm':
      return {
        id,
        field,
        question: L(
          'Giờ đó là buổi sáng hay chiều tối?',
          'Was that in the morning or the evening?',
        ),
        choices: [
          { id: 'am', label: L('Buổi sáng', 'Morning') },
          { id: 'pm', label: L('Chiều / tối', 'Afternoon / evening') },
        ],
        // L1 (P-167 #3): typed "Sáng" / "tối" answers it (`readTypedAnswer`).
        allowText: true,
      };
    case 'time.missing':
      return {
        id,
        field,
        question: L('Việc này diễn ra lúc mấy giờ?', 'What time was it?'),
        choices: [],
        allowText: true,
      };
    case 'intent':
      return {
        id,
        field,
        question: L(
          'Bạn muốn xem nhật ký hay ghi thêm?',
          'Do you want to see the log or add to it?',
        ),
        choices: [
          { id: 'read', label: L('Xem nhật ký', 'See the log') },
          { id: 'write', label: L('Ghi thêm', 'Add to the log') },
        ],
        allowText: false,
      };
    case 'sleep.period':
      return {
        id,
        field,
        question: L(
          'Bé khó vào giấc hay thức giấc?',
          'Is it hard to fall asleep, or waking often?',
        ),
        choices: [
          { id: 'falling_asleep', label: L('Khó vào giấc', 'Hard to fall asleep') },
          { id: 'night_waking', label: L('Hay thức giấc', 'Waking often') },
          // Slice A5 (CH15 "Cả hai").
          { id: 'both', label: L('Cả hai', 'Both') },
        ],
        allowText: false,
      };
    // ---- Slice A5 (care, CH15): day / night, optional onset; always skippable ----
    case 'sleep.when':
      return {
        id,
        field,
        question: L('Giấc ngày hay giấc đêm?', 'Naps or night sleep?'),
        choices: [
          { id: 'night', label: L('Giấc đêm', 'Night') },
          { id: 'day', label: L('Giấc ngày', 'Naps') },
          { id: 'unsure', label: L('Chưa rõ', 'Not sure') },
        ],
        allowText: false,
      };
    case 'sleep.onset':
      return {
        id,
        field,
        question: L('Việc này bắt đầu từ khi nào?', 'When did this start?'),
        choices: [
          { id: 'today', label: L('Hôm nay', 'Today') },
          { id: 'days_2_3', label: L('2–3 ngày nay', 'The last 2–3 days') },
          { id: 'longer', label: L('Lâu hơn', 'Longer') },
          { id: 'unsure', label: L('Chưa rõ', 'Not sure') },
        ],
        allowText: false,
      };
    // ---- end slice A5 ----
  }
}

// ---------- Read tools ----------

export interface ReadResult {
  tool: ReadToolName;
  /** Engine-written lines the wording may use (ids are stable within the task). */
  facts: { id: string; text: string }[];
  parts: AssistantPart[];
}

const fmtMin = (n: number) => String(Math.round(n));

/**
 * Live records touching the [days] ending on [date] in the scope's zone, up to [until] (a running
 * day stops at now).
 */
async function recordsOfDay(db: Firestore, s: TrustedScope, date: string, until: Date, days = 1) {
  const { start } = dayBoundsIn(s.zone, addDaysIso(date, 1 - days));
  const { end } = dayBoundsIn(s.zone, date);
  const stop = new Date(Math.min(end.getTime(), until.getTime()));
  const snap = await db
    .collection(`babies/${s.babyId}/records`)
    .where('occurredAt', '>=', new Date(start.getTime() - 86_400_000))
    .where('occurredAt', '<', stop)
    .get();
  const out: { id: string; kind: string; ml?: number; minutes?: number }[] = [];
  for (const d of snap.docs) {
    if (d.get('deleted') === true) continue;
    const at = (d.get('occurredAt') as Timestamp | undefined)?.toDate();
    if (!at) continue;
    const type = d.get('type') as string;
    const data = (d.get('data') as Record<string, unknown> | undefined) ?? {};
    if (type === 'bottle' || type === 'breast') {
      if (at < start) continue;
      out.push(
        type === 'bottle'
          ? { id: d.id, kind: 'bottle', ml: typeof data.amountMl === 'number' ? data.amountMl : 0 }
          : {
              id: d.id,
              kind: 'breast',
              minutes: typeof data.durationMin === 'number' ? data.durationMin : 0,
            },
      );
    } else if (type === 'sleep') {
      const endedAt = (d.get('endedAt') as Timestamp | null | undefined)?.toDate();
      if (!endedAt) continue;
      const from = Math.max(at.getTime(), start.getTime());
      const to = Math.min(endedAt.getTime(), stop.getTime());
      if (to <= from) continue;
      out.push({ id: d.id, kind: 'sleep', minutes: Math.round((to - from) / 60_000) });
    }
  }
  return { records: out, until: stop };
}

/** CH08 / R01: bottle ml and nursing minutes kept apart; "các cữ đã ghi", coverage unknown. */
export async function careSummaryTool(
  db: Firestore,
  s: TrustedScope,
  anchor: Date,
  dayOffset: number,
  locale: 'vi' | 'en',
  days = 1,
): Promise<ReadResult & { summary: CareSummary; first: string }> {
  const date = addDaysIso(localDateIn(s.zone, anchor), dayOffset);
  const first = addDaysIso(date, 1 - days);
  const { records, until } = await recordsOfDay(db, s, date, anchor, days);
  const { summary, sourceIds } = careSummary(records, date, until.toISOString(), 'unknown');
  const vi = locale === 'vi';
  const day =
    days > 1
      ? vi
        ? `${days} ngày ${first} – ${date}`
        : `${days} days ${first} – ${date}`
      : dayOffset === 0
        ? vi
          ? 'hôm nay'
          : 'today'
        : date;
  const clock = localClock(s.zone, until);
  const facts = [
    {
      id: `${date}:bottle`,
      text: vi
        ? `Bú bình đã ghi ${day} (đến ${clock}): ${summary.bottle.count} cữ, ${summary.bottle.ml} ml.`
        : `Bottle feeds logged ${day} (until ${clock}): ${summary.bottle.count}, ${summary.bottle.ml} ml.`,
    },
    {
      id: `${date}:breast`,
      text: vi
        ? `Bú mẹ đã ghi ${day}: ${summary.breast.count} lần, ${fmtMin(summary.breast.minutes)} phút.`
        : `Breastfeeds logged ${day}: ${summary.breast.count}, ${fmtMin(summary.breast.minutes)} min.`,
    },
    {
      id: `${date}:sleep`,
      text: vi
        ? `Giấc ngủ đã ghi ${day}: ${summary.sleep.count} giấc, ${fmtMin(summary.sleep.minutes)} phút.`
        : `Sleep logged ${day}: ${summary.sleep.count}, ${fmtMin(summary.sleep.minutes)} min.`,
    },
  ];
  return {
    tool: 'care_summary',
    facts,
    summary,
    first,
    parts: [{ type: 'source_summary', schemaVersion: 1, summary, sourceIds }],
  };
}

/** Sleep trend from the rhythm engine (valid days only; never a cause). */
export async function sleepFactsTool(
  db: Firestore,
  s: TrustedScope,
  anchor: Date,
  locale: 'vi' | 'en',
): Promise<ReadResult & { trend: { recent: number; baseline: number } | null }> {
  const today = localDateIn(s.zone, anchor);
  const f = await sleepFacts(db, s.babyId, s.zone, today, anchor, await readRhythmRules(db));
  const vi = locale === 'vi';
  const text =
    f.status === 'insufficient_data' || f.baseline === null || f.recent === null
      ? vi
        ? `Chưa đủ ngày ghi đầy đủ để so sánh giấc ngủ (${f.validDays} ngày hợp lệ).`
        : `Not enough fully logged days to compare sleep (${f.validDays} valid days).`
      : vi
        ? `Giấc ngủ đã ghi gần đây: khoảng ${fmtMin(f.recent)} phút mỗi ngày; trước đó khoảng ${fmtMin(f.baseline)} phút mỗi ngày.`
        : `Recently logged sleep: about ${fmtMin(f.recent)} min a day; before that about ${fmtMin(f.baseline)} min a day.`;
  return {
    tool: 'sleep_facts',
    facts: [{ id: `${today}:sleep_facts`, text }],
    parts: [],
    // The read card's label/value rows (the model keeps the sentence above).
    trend:
      f.status === 'insufficient_data' || f.baseline === null || f.recent === null
        ? null
        : { recent: f.recent, baseline: f.baseline },
  };
}

/** "Còn bao nhiêu lượt?": the household pool (never mutates the budget). */
export async function usageSnapshotTool(
  db: Firestore,
  s: TrustedScope,
  now: Date,
  locale: 'vi' | 'en',
): Promise<ReadResult> {
  const u = await assistantUsage(db, s, now);
  // P2 copy (2026-10-16): a date people read ("1/11/2026", "1 Nov 2026"), never an ISO date.
  const [ry, rm, rd] = localDateIn(s.householdZone, new Date(u.resetsAt))
    .split('-')
    .map(Number) as [number, number, number];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  const reset = locale === 'vi' ? `${rd}/${rm}/${ry}` : `${rd} ${months[rm - 1]} ${ry}`;
  const text =
    locale === 'vi'
      ? `Hộ còn ${u.remaining} / ${u.limit} lượt trợ lý, làm mới ngày ${reset}.`
      : `The household has ${u.remaining} of ${u.limit} assistant credits left, renewing on ${reset}.`;
  return { tool: 'usage_snapshot', facts: [{ id: 'usage', text }], parts: [] };
}

/** Numbers a wording may contain: exactly those in the facts (brief p.13, "model chỉ diễn đạt"). */
export function wordingGrounded(text: string, facts: readonly { text: string }[]): boolean {
  const nums = (s: string) => (s.match(/\d+(?:[.,]\d+)?/g) ?? []).map((n) => n.replace(',', '.'));
  const allowed = new Set(facts.flatMap((f) => nums(f.text)));
  return nums(text).every((n) => allowed.has(n));
}

// ---------- Prepare tools ----------

export interface PreparedDraft {
  payload: DraftPayload;
  missingFields: string[];
  uncertainFields: string[];
  problems: DraftProblem[];
  warnings: ('duplicate_suspected' | 'overlap')[];
  /** Rework 2026-10-15: the previous turn's unsaved draft this one corrects (discarded at settle). */
  replaces?: { taskId: string; draftId: string };
  /**
   * Lumi L7 (P-168 #2): a change to a care record saved in the last 30 min (`update`, "180 chứ")
   * or its soft delete (`delete`, "xoá cái vừa ghi"); absent = a new record.
   */
  op?: 'update' | 'delete';
  targetRecordId?: string;
}

export type PrepareNotice = {
  kind: DraftKind;
  code: 'MODULE_UNAVAILABLE' | 'WRITE_DENIED' | 'VALIDATION_FAILED';
};

export interface PrepareInput {
  intents: ModelIntent[];
  /** The person's text and clarification answers (grounding). */
  texts: string[];
  anchor: Date;
  period: 'am' | 'pm' | null;
  /** The baby's last bottle milk (the form remembers it; else breast milk, as the form). */
  lastMilk: 'breast_milk' | 'formula';
}

const draftField: Record<string, Partial<Record<DraftKind, string>>> = {
  amountMl: { bottle: 'amountMl' },
  milk: { bottle: 'milk' },
  // Lumi 2026-10-16: an observation has no time (its `date` comes from dayOffset only).
  time: { bottle: 'occurredAt', breast: 'occurredAt', sleep: 'startedAt' },
  dayOffset: {
    bottle: 'occurredAt',
    breast: 'occurredAt',
    sleep: 'startedAt',
    observation: 'date',
  },
  endTime: { sleep: 'endedAt' },
  endDayOffset: { sleep: 'endedAt' },
  durationMin: { breast: 'durationMin' },
  side: { breast: 'side' },
  observation: { observation: 'observation' },
  when: { observation: 'when' },
  note: { observation: 'note' },
};

/**
 * Intents → typed drafts, deterministically (brief p.12). Times are local clock times on the
 * anchor day (or the day before when said); nothing is swapped, flipped or moved overnight; a
 * value whose evidence is not in the person's words is uncertain; a completed log after the
 * anchor, an invalid amount or a sleep ending before it starts is kept for review, never fixed.
 * Kinds without a module, or that the caller's role cannot save, become notices, not drafts.
 */
export function prepareDrafts(
  s: TrustedScope,
  x: PrepareInput,
): { drafts: PreparedDraft[]; notices: PrepareNotice[] } {
  const drafts: PreparedDraft[] = [];
  const notices: PrepareNotice[] = [];
  const haystack = fold(x.texts.join(' \n '));
  const today = localDateIn(s.zone, x.anchor);
  for (const intent of x.intents) {
    const mod = moduleRegistry[intent.kind];
    // Slice A3: photo-only kinds are not drafted here. Rework 2026-10-15: text expenses and
    // reminders are planned by `planTextIntents` (assistant-text.ts), not by this A2 helper.
    if (!mod.available || !mod.action || mod.photoOnly) {
      notices.push({ kind: intent.kind, code: 'MODULE_UNAVAILABLE' });
      continue;
    }
    if (!familyCan(s.member, mod.action)) {
      notices.push({ kind: intent.kind, code: 'WRITE_DENIED' });
      continue;
    }
    const f = intent.fields;
    const name = (field: string) => draftField[field]?.[intent.kind] ?? null;
    const uncertain = new Set<string>();
    const missing = new Set<string>();
    for (const u of intent.uncertainFields) if (name(u)) uncertain.add(name(u)!);
    for (const m of intent.missingFields) if (name(m)) missing.add(name(m)!);
    // Grounding: a filled field whose evidence is not in the person's words is uncertain.
    for (const e of intent.evidence) {
      if (name(e.field) && !haystack.includes(fold(e.text).trim())) uncertain.add(name(e.field)!);
    }
    const at = (time: string | null, offset: number | null) =>
      time === null
        ? null
        : localInstant(
            s.zone,
            addDaysIso(today, offset ?? 0),
            applyPeriod(time, x.period),
          ).toISOString();
    let payload: DraftPayload;
    switch (intent.kind) {
      case 'bottle': {
        const amount = f.amountMl;
        if (amount !== null && !Number.isInteger(amount)) uncertain.add('amountMl');
        const milk = f.milk === 'other' ? null : (f.milk ?? x.lastMilk);
        if (f.milk === 'other') uncertain.add('milk');
        payload = {
          kind: 'bottle',
          amountMl: amount !== null && amount > 0 ? amount : null,
          occurredAt: at(f.time, f.dayOffset),
          milk,
        };
        if (amount !== null && amount <= 0) uncertain.add('amountMl');
        break;
      }
      case 'breast': {
        const d = f.durationMin;
        payload = {
          kind: 'breast',
          occurredAt: at(f.time, f.dayOffset),
          durationMin: d !== null && Number.isInteger(d) && d > 0 ? d : null,
          side: f.side,
        };
        if (d !== null && (!Number.isInteger(d) || d <= 0)) uncertain.add('durationMin');
        break;
      }
      case 'sleep':
        payload = {
          kind: 'sleep',
          startedAt: at(f.time, f.dayOffset),
          endedAt: at(f.endTime, f.endDayOffset ?? f.dayOffset),
        };
        break;
      case 'observation':
        if (f.observation === null) {
          notices.push({ kind: intent.kind, code: 'VALIDATION_FAILED' });
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
      default:
        notices.push({ kind: intent.kind, code: 'MODULE_UNAVAILABLE' });
        continue;
    }
    const checked = draftPayloadSchema.safeParse(payload);
    if (!checked.success) {
      notices.push({ kind: intent.kind, code: 'VALIDATION_FAILED' });
      continue;
    }
    const problems = draftProblems(checked.data, x.anchor);
    if (payload.kind === 'observation' && payload.date > today) uncertain.add('date');
    // Lumi 2026-10-16: the model's "missing" list is advice only; what is missing is decided
    // from the payload (`draftReviewFields`), so a filled field is never flagged.
    void missing;
    const review = reviewFields(checked.data, problems, uncertain);
    drafts.push({
      payload: checked.data,
      missingFields: review.missing,
      uncertainFields: review.uncertain,
      problems,
      warnings: [],
    });
  }
  return { drafts, notices };
}

/**
 * Fields the person must fill (`missing`) or look at (`uncertain`) given the form's problems for
 * [p]; both block confirm until a patch clears them. Lumi 2026-10-16: contracts
 * `draftReviewFields` (one mapping for every kind, tested against each kind's fields): only the
 * kind's REQUIRED fields that are empty are missing; [uncertain] candidates are kept only when
 * they are real, filled fields of the kind.
 */
export function reviewFields(
  p: DraftPayload,
  problems: readonly DraftProblem[],
  uncertain: Iterable<string> = [],
): { missing: string[]; uncertain: string[] } {
  return draftReviewFields(p, problems, uncertain);
}

/** Live sleeps of the baby overlapping [span] (contracts `spansOverlap`; touching ends do not). */
export async function overlappingSleeps(
  db: Firestore,
  babyId: string,
  span: { start: Date; end: Date },
  exceptId: string | null,
  tx?: FirebaseFirestore.Transaction,
): Promise<string[]> {
  const q = db
    .collection(`babies/${babyId}/records`)
    .where('type', '==', 'sleep')
    .where('deleted', '==', false)
    .where('occurredAt', '>=', new Date(span.start.getTime() - 86_400_000))
    .where('occurredAt', '<', span.end);
  const snap = tx ? await tx.get(q) : await q.get();
  return snap.docs
    .filter((d) => d.id !== exceptId)
    .filter((d) => {
      const start = (d.get('occurredAt') as Timestamp | undefined)?.toDate();
      const end = (d.get('endedAt') as Timestamp | null | undefined)?.toDate();
      return !!start && !!end && spansOverlap(span, { start, end });
    })
    .map((d) => d.id);
}

/** The milk of the baby's latest bottle record (the form's memory), else breast milk. */
export async function lastMilkOf(
  db: Firestore,
  babyId: string,
  before: Date,
): Promise<'breast_milk' | 'formula'> {
  const snap = await db
    .collection(`babies/${babyId}/records`)
    .where('occurredAt', '>=', new Date(before.getTime() - 7 * 86_400_000))
    .where('occurredAt', '<=', before)
    .get();
  const last = snap.docs
    .filter((d) => d.get('type') === 'bottle' && d.get('deleted') !== true)
    .sort(
      (a, b) =>
        (b.get('occurredAt') as Timestamp).toMillis() -
        (a.get('occurredAt') as Timestamp).toMillis(),
    )[0];
  return last?.get('data.milk') === 'formula' ? 'formula' : 'breast_milk';
}

// ---- Lumi rework 2026-10-15: care duplicates ("vừa ghi rồi"), a warning, never a merge ----

/** Records of the same kind within 10 minutes (and, for a bottle, within 10 % of the amount). */
export async function careDuplicateIn(
  db: Firestore,
  babyId: string,
  p: DraftPayload,
  exceptId: string | null,
  tx?: FirebaseFirestore.Transaction,
): Promise<boolean> {
  if (
    (p.kind !== 'bottle' && p.kind !== 'breast' && p.kind !== 'pump' && p.kind !== 'diaper') ||
    !p.occurredAt
  ) {
    return false;
  }
  const at = Date.parse(p.occurredAt);
  const q = db
    .collection(`babies/${babyId}/records`)
    .where('occurredAt', '>=', Timestamp.fromMillis(at - 10 * 60_000))
    .where('occurredAt', '<=', Timestamp.fromMillis(at + 10 * 60_000));
  const snap = tx ? await tx.get(q) : await q.get();
  return snap.docs.some((d) => {
    if (d.id === exceptId || d.get('deleted') === true || d.get('type') !== p.kind) return false;
    // LUMI-01: a pump like one just logged (within 10 % of the amount); a diaper of the same kind.
    if (p.kind === 'diaper') return p.diaper === null || d.get('data.kind') === p.diaper;
    if (p.kind === 'bottle' || p.kind === 'pump') {
      const ml = d.get('data.amountMl') as number | undefined;
      return (
        typeof ml === 'number' &&
        p.amountMl !== null &&
        Math.abs(ml - p.amountMl) <= p.amountMl * 0.1
      );
    }
    return true;
  });
}
