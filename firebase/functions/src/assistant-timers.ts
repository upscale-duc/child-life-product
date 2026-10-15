import {
  FieldValue,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import {
  recordIdForTimer,
  timerRecordAt,
  type AssistantError,
  type DraftPayload,
  type DraftProblem,
  type TimerState,
} from '@child-life/contracts';
import { sha, toDate, type ScopeMember } from './assistant-common.js';
import type { RunningTimers } from './assistant-text.js';
import { buildCareRecord } from './assistant-writers.js';

/**
 * Lumi timers 2026-10-16 (`docs/assistant/api.md` "Timers"): "con đang ngủ", "đang cho bú bên
 * trái", "bé dậy rồi", "bú xong rồi" drive the app's OWN running timers — the one source of truth
 * every family member's app listens to (`babies/{b}/timers/{sleep|breast}`, P-011, R-070…R-073).
 *
 * - Plan time: the running timers (`runningTimersOf`) and the next breastfeed side
 *   (`nextBreastSideOf`, the form's "bên còn lại") feed `planTextIntents`.
 * - Confirm ("Bắt đầu tính giờ" / "Kết thúc"): `planTimerWrite` writes exactly what the app's
 *   timer would — the timer document of `validNewTimer` (the confirmer as `startedBy` and
 *   author), or the end of the running session: its record `r_<sessionId>` (contracts
 *   `timerRecordAt` = the app's `CareTimer.toRecord`) and the timer's deletion, in the confirm
 *   transaction. The app's timer screen, Home tile and widgets then show / end it as usual.
 * Admin writes bypass the Rules; role, membership and the baby are re-checked by
 * `confirmDraftItem` before this runs. Nothing here logs care data.
 */

/** The timer session a start draft creates (32 hex, like the app's UUID without dashes). */
export const timerSessionIdForDraft = (draftId: string) => sha(`timer|${draftId}`).slice(0, 32);

/** The app route of a running timer (`/care/timer/{type}`; the baby rides along). */
export const timerLinkFor = (babyId: string, type: 'sleep' | 'breast') =>
  `/care/timer/${type}?babyId=${babyId}`;

const timerRef = (db: Firestore, babyId: string, type: 'sleep' | 'breast') =>
  db.doc(`babies/${babyId}/timers/${type}`);

const runningOf = (d: DocumentSnapshot) => {
  if (!d.exists) return null;
  const sessionId = d.get('sessionId');
  const startedAt = toDate(d.get('startedAt'));
  return typeof sessionId === 'string' && /^[a-f0-9]{32}$/.test(sessionId) && startedAt
    ? { sessionId, startedAt }
    : null;
};

/** The baby's running sleep and breastfeeding timers (null when none). */
export async function runningTimersOf(db: Firestore, babyId: string): Promise<RunningTimers> {
  const [sleep, breast] = await db.getAll(
    timerRef(db, babyId, 'sleep'),
    timerRef(db, babyId, 'breast'),
  );
  return { sleep: runningOf(sleep!), breast: runningOf(breast!) };
}

/**
 * The side a breastfeed starts on by default: the other side of the last one ("nhớ bên lần
 * trước, gợi ý bên còn lại", `care_sheets.dart` `_effectiveSide`), else both.
 */
export async function nextBreastSideOf(
  db: Firestore,
  babyId: string,
  before: Date,
): Promise<'left' | 'right' | 'both'> {
  const snap = await db
    .collection(`babies/${babyId}/records`)
    .where('occurredAt', '>=', new Date(before.getTime() - 7 * 86_400_000))
    .where('occurredAt', '<=', before)
    .get();
  const last = snap.docs
    .filter((d) => d.get('type') === 'breast' && d.get('deleted') !== true)
    .sort(
      (a, b) =>
        (b.get('occurredAt') as Timestamp).toMillis() -
        (a.get('occurredAt') as Timestamp).toMillis(),
    )[0];
  const side = last?.get('data.side');
  return side === 'left' ? 'right' : side === 'right' ? 'left' : 'both';
}

/**
 * LUMI-01: the side the pump form starts on — the one it remembers (`pumpSide`, the last pump's
 * side on this device; the server reads the baby's last pump record), else both.
 */
export async function lastPumpSideOf(
  db: Firestore,
  babyId: string,
  before: Date,
): Promise<'left' | 'right' | 'both'> {
  const snap = await db
    .collection(`babies/${babyId}/records`)
    .where('occurredAt', '>=', new Date(before.getTime() - 14 * 86_400_000))
    .where('occurredAt', '<=', before)
    .get();
  const last = snap.docs
    .filter((d) => d.get('type') === 'pump' && d.get('deleted') !== true)
    .sort(
      (a, b) =>
        (b.get('occurredAt') as Timestamp).toMillis() -
        (a.get('occurredAt') as Timestamp).toMillis(),
    )[0];
  const side = last?.get('data.side');
  return side === 'left' || side === 'right' ? side : 'both';
}

/** A stored timer as contracts `TimerState` (ms). */
export function timerStateOf(d: DocumentSnapshot): TimerState | null {
  const type = d.get('type');
  const startedAt = toDate(d.get('startedAt'));
  const sessionId = d.get('sessionId');
  if ((type !== 'sleep' && type !== 'breast' && type !== 'pump') || !startedAt) return null;
  if (typeof sessionId !== 'string') return null;
  const side = (k: 'left' | 'right') => {
    const v = d.get(`sides.${k}`) as Record<string, unknown> | null | undefined;
    if (!v) return null;
    return {
      accumulatedMs: typeof v.accumulatedMs === 'number' ? v.accumulatedMs : 0,
      runningSince: toDate(v.runningSince)?.getTime() ?? null,
    };
  };
  const paused = (d.get('pausedSides') as unknown[] | undefined) ?? [];
  return {
    type,
    sessionId,
    startedAt: startedAt.getTime(),
    left: side('left'),
    right: side('right'),
    pausedSides: paused.filter(
      (x): x is 'left' | 'right' | 'both' => x === 'left' || x === 'right' || x === 'both',
    ),
  };
}

/**
 * The running timer document exactly as the app's "Bắt đầu" writes it (`CareTimer.toJson`,
 * Rules `validNewTimer`): [x.uid] starts it as themselves; a breastfeed runs one side from [x.at].
 * [ts] makes a timestamp, [serverTime] is the write's server time (Admin or client SDK).
 */
export function buildTimerDoc<T, S>(
  x: {
    type: 'sleep' | 'breast';
    babyId: string;
    sessionId: string;
    at: Date;
    side: 'left' | 'right' | null;
    uid: string;
    author: { name: string; relation: string; relationCustom: string | null };
  },
  ts: (d: Date) => T,
  serverTime: S,
) {
  const running = (side: 'left' | 'right') => ({
    accumulatedMs: 0,
    runningSince: x.type === 'breast' && (x.side ?? 'left') === side ? ts(x.at) : null,
  });
  return {
    type: x.type,
    babyId: x.babyId,
    sessionId: x.sessionId,
    startedAt: ts(x.at),
    startedBy: x.uid,
    author: x.author,
    sides: x.type === 'sleep' ? null : { left: running('left'), right: running('right') },
    paused: false,
    pausedSides: [] as string[],
    updatedAt: serverTime,
    updatedBy: x.uid,
  };
}

export type TimerWritePlan =
  | { kind: 'fail'; errorCode: AssistantError; problems: DraftProblem[] }
  | { kind: 'conflict'; errorCode: AssistantError }
  | { kind: 'adopt'; recordId: string; link: string }
  | {
      kind: 'write';
      target: FirebaseFirestore.DocumentReference;
      doc: Record<string, unknown>;
      /** Also delete (the ended timer). */
      remove: FirebaseFirestore.DocumentReference | null;
      recordId: string;
      link: string;
    };

/**
 * What confirming a `timer` draft writes (reads only; the caller writes in its transaction):
 * - start: the timer document, unless one already runs (`TIMER_RUNNING` conflict — the app shows
 *   the running one) or this draft's session already exists / ended (adopted as saved);
 * - stop: the running session's record `r_<sessionId>` and the timer's deletion; already ended
 *   with that record (another device, a replay) → adopted as saved; another session now runs or
 *   none and no record → `TIMER_CHANGED`.
 */
export async function planTimerWrite(
  tx: Transaction,
  db: Firestore,
  x: { draftId: string; babyId: string; uid: string; now: Date; member: ScopeMember },
  p: Extract<DraftPayload, { kind: 'timer' }>,
): Promise<TimerWritePlan> {
  const ref = timerRef(db, x.babyId, p.timer);
  const recordLink = (id: string) => `/care/records/${x.babyId}/${id}`;
  const author = {
    name: x.member.displayName,
    relation: x.member.relation,
    relationCustom: x.member.relationCustom,
  };
  if (p.at === null)
    return { kind: 'fail', errorCode: 'VALIDATION_FAILED', problems: ['MISSING_TIME'] };
  const at = new Date(p.at);
  if (p.action === 'start') {
    const sessionId = timerSessionIdForDraft(x.draftId);
    const recordId = recordIdForTimer(sessionId);
    const [cur, rec] = await Promise.all([
      tx.get(ref),
      tx.get(db.doc(`babies/${x.babyId}/records/${recordId}`)),
    ]);
    if (rec.exists) return { kind: 'adopt', recordId, link: recordLink(recordId) };
    if (cur.exists) {
      return cur.get('sessionId') === sessionId
        ? { kind: 'adopt', recordId, link: timerLinkFor(x.babyId, p.timer) }
        : { kind: 'conflict', errorCode: 'TIMER_RUNNING' };
    }
    const doc = buildTimerDoc(
      {
        type: p.timer,
        babyId: x.babyId,
        sessionId,
        at,
        side: p.side,
        uid: x.uid,
        author,
      },
      (d) => Timestamp.fromDate(d),
      FieldValue.serverTimestamp(),
    );
    return {
      kind: 'write',
      target: ref,
      doc,
      remove: null,
      recordId,
      link: timerLinkFor(x.babyId, p.timer),
    };
  }
  if (p.sessionId === null) {
    return { kind: 'fail', errorCode: 'VALIDATION_FAILED', problems: ['INVALID_TIME'] };
  }
  const recordId = recordIdForTimer(p.sessionId);
  const recRef = db.doc(`babies/${x.babyId}/records/${recordId}`);
  const [cur, rec] = await Promise.all([tx.get(ref), tx.get(recRef)]);
  if (rec.exists) return { kind: 'adopt', recordId, link: recordLink(recordId) };
  const state = cur.exists ? timerStateOf(cur) : null;
  if (!state || state.sessionId !== p.sessionId) {
    return { kind: 'conflict', errorCode: 'TIMER_CHANGED' };
  }
  if (at.getTime() <= state.startedAt) {
    return { kind: 'fail', errorCode: 'VALIDATION_FAILED', problems: ['INVALID_TIME'] };
  }
  const r = timerRecordAt(state, at.getTime());
  const doc = buildCareRecord(
    {
      recordId,
      babyId: x.babyId,
      uid: x.uid,
      member: x.member,
      type: r.type === 'sleep' ? 'sleep' : 'breast',
      occurredAt: new Date(r.occurredAt),
      endedAt: new Date(r.endedAt),
      data: r.data,
      clientCreatedAt: x.now,
    },
    FieldValue.serverTimestamp(),
  );
  return { kind: 'write', target: recRef, doc, remove: ref, recordId, link: recordLink(recordId) };
}
