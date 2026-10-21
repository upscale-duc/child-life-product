import {
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import {
  dialogueLimits,
  emptyDialogue,
  followUpCueIn,
  liveDialogue,
  localDateIn,
  shortReplyIn,
  yesNoIn,
  type AssistantPart,
  type Clarification,
  type DialogueAnswerKind,
  type DialogueChange,
  type DialogueKeys,
  type DialogueQuestion,
  type DialogueSaved,
  type DialogueState,
  type DialogueWaiting,
  type DraftKind,
  type DraftPayload,
  type SmallTalkKind,
} from '@child-life/contracts';
import { conversationRef, draftRef, taskRef } from './assistant-common.js';
import { kindNames } from './assistant-talk.js';
import { localClock, localInstant } from './assistant-tools.js';
import type { PreviousTurn } from './assistant-text.js';

/**
 * Lumi L7 (P-168 #1–#2, #6; docs/product/lumi-plan.md §11.3): the dialogue state of one author in
 * one conversation (`assistantConversations/{cv}/dialogue/{uid}`, server-only: the Rules deny
 * every client read and write) and the resolver that reads a new message against it before any
 * reader. Written by the worker's settle and by confirm / discard / patch / cancel / expiry.
 * Holds ids, kinds, numbers, enums and instants only: no names, notes, captions or words.
 */

export const dialogueRef = (db: Firestore, conversationId: string, uid: string) =>
  conversationRef(db, conversationId).collection('dialogue').doc(uid);

/** The state as stored, lapsed parts dropped (null when none or lapsed). */
export function dialogueOf(snap: DocumentSnapshot | null | undefined, now: Date) {
  if (!snap?.exists) return null;
  return liveDialogue((snap.get('state') as DialogueState | undefined) ?? null, now);
}

/** Writes [d] (the TTL runs from now, or later while a question is open). */
export function writeDialogue(tx: Transaction, db: Firestore, d: DialogueState, now: Date): void {
  const ttl = now.getTime() + dialogueLimits.ttlMin * 60_000;
  const until = Math.max(ttl, d.question ? Date.parse(d.question.expiresAt) : 0);
  const state: DialogueState = {
    ...d,
    waiting: d.waiting.slice(0, dialogueLimits.items),
    saved: d.saved.slice(0, dialogueLimits.items),
    turns: d.turns.slice(-dialogueLimits.turns),
    updatedAt: now.toISOString(),
    expiresAt: new Date(until).toISOString(),
  };
  tx.set(dialogueRef(db, d.conversationId, d.ownerUid), {
    state,
    // A TTL policy may sweep lapsed docs; reads never trust a lapsed one (`liveDialogue`).
    ttlAt: Timestamp.fromMillis(until),
  });
}

/** The key values of [p] (numbers, enums, instants; never a note, a title or a merchant). */
export function keysOf(p: DraftPayload): DialogueKeys {
  switch (p.kind) {
    case 'bottle':
      return { amountMl: p.amountMl, milk: p.milk, at: p.occurredAt };
    case 'breast':
      return { durationMin: p.durationMin, side: p.side, at: p.occurredAt };
    case 'pump':
      return { amountMl: p.amountMl, durationMin: p.durationMin, side: p.side, at: p.occurredAt };
    case 'diaper':
      return { diaper: p.diaper, at: p.occurredAt };
    case 'sleep':
      return { at: p.startedAt, endAt: p.endedAt, durationMin: p.durationMin ?? null };
    case 'timer':
      return { timer: p.timer, action: p.action, at: p.at, side: p.side };
    case 'meal':
      return { at: p.occurredAt };
    default:
      return {};
  }
}

const turnOf = (kind: DialogueAnswerKind, items: DraftKind[], now: Date) => ({
  at: now.toISOString(),
  kind,
  items,
});

const without = <T extends { draftId: string }>(xs: T[], ids: Set<string>) =>
  xs.filter((x) => !ids.has(x.draftId));

/** The settle of a task of this author ([taskId]): what it drafted, asked or answered. */
export function afterTurn(
  prev: DialogueState | null,
  x: {
    ownerUid: string;
    conversationId: string;
    taskId: string;
    now: Date;
    kind: DialogueAnswerKind;
    drafts: { draftId: string; payload: DraftPayload }[];
    /** Drafts this turn set aside (corrections) or discarded ("xoá cái vừa ghi"). */
    dropped: string[];
    question: { pc: Clarification; expiresAt: Date; about: DialogueQuestion['about'] } | null;
    /** A new topic closed the open question (P-168 #6). */
    setAside: boolean;
    timers?: DialogueState['timers'];
  },
): DialogueState {
  const d = prev ?? emptyDialogue(x.ownerUid, x.conversationId, x.now);
  const at = x.now.toISOString();
  const waiting: DialogueWaiting[] = [
    ...x.drafts.map((dr) => ({
      taskId: x.taskId,
      draftId: dr.draftId,
      kind: dr.payload.kind,
      keys: keysOf(dr.payload),
      revision: 1,
      createdAt: at,
    })),
    ...without(d.waiting, new Set([...x.dropped, ...x.drafts.map((dr) => dr.draftId)])),
  ];
  let question = d.question;
  let setAside = d.setAside;
  if (x.question) {
    question = {
      taskId: x.taskId,
      clarificationId: x.question.pc.id,
      field: x.question.pc.field,
      choiceIds: x.question.pc.choices.map((c) => c.id),
      allowText: x.question.pc.allowText,
      askedAt: at,
      expiresAt: x.question.expiresAt.toISOString(),
      about: x.question.about,
    };
    if (d.question && d.question.taskId !== x.taskId) setAside = { ...d.question, at };
  } else if (d.question?.taskId === x.taskId) {
    question = null;
  } else if (d.question && x.setAside) {
    setAside = { ...d.question, at };
    question = null;
  }
  if (setAside && question && setAside.taskId === question.taskId) setAside = null;
  return {
    ...d,
    question,
    setAside,
    waiting,
    saved: without(d.saved, new Set(x.dropped)),
    timers: x.timers ?? d.timers,
    lastAnswer: x.kind,
    turns: [
      ...d.turns,
      turnOf(
        x.kind,
        x.drafts.map((dr) => dr.payload.kind),
        x.now,
      ),
    ].slice(-dialogueLimits.turns),
  };
}

/** Saved through `confirmDrafts`: off the waiting list; a create / update is kept 30 min. */
export function afterSave(
  d: DialogueState,
  items: {
    taskId: string;
    draftId: string;
    payload: DraftPayload;
    recordId: string;
    op: 'create' | 'update' | 'delete';
  }[],
  now: Date,
): DialogueState {
  const ids = new Set(items.map((i) => i.draftId));
  const touched = new Set(items.map((i) => i.recordId));
  const kept: DialogueSaved[] = items
    .filter((i) => i.op !== 'delete' && i.payload.kind !== 'timer')
    .map((i) => ({
      taskId: i.taskId,
      draftId: i.draftId,
      kind: i.payload.kind,
      keys: keysOf(i.payload),
      recordId: i.recordId,
      savedAt: now.toISOString(),
    }));
  return {
    ...d,
    waiting: without(d.waiting, ids),
    saved: [...kept, ...d.saved.filter((s) => !touched.has(s.recordId) && !ids.has(s.draftId))],
    lastAnswer: 'saved',
    turns: [
      ...d.turns,
      turnOf(
        'saved',
        kept.map((k) => k.kind),
        now,
      ),
    ].slice(-dialogueLimits.turns),
  };
}

/** "Bỏ" on a draft, or an edit in the card (its keys follow). */
export function afterDraftChange(
  d: DialogueState,
  draftId: string,
  change: { discarded: true } | { payload: DraftPayload; revision: number },
  now: Date,
): DialogueState {
  if ('discarded' in change) {
    return {
      ...d,
      waiting: without(d.waiting, new Set([draftId])),
      lastAnswer: 'discarded',
      turns: [...d.turns, turnOf('discarded', [], now)].slice(-dialogueLimits.turns),
    };
  }
  return {
    ...d,
    waiting: d.waiting.map((w) =>
      w.draftId === draftId ? { ...w, keys: keysOf(change.payload), revision: change.revision } : w,
    ),
  };
}

/** A task stopped (cancelled, failed, its question expired): its question and drafts go. */
export function afterStop(
  d: DialogueState,
  taskId: string,
  kind: 'canceled' | 'failed' | 'expired',
  now: Date,
): DialogueState {
  return {
    ...d,
    question: d.question?.taskId === taskId ? null : d.question,
    setAside: d.setAside?.taskId === taskId ? null : d.setAside,
    waiting: d.waiting.filter((w) => w.taskId !== taskId),
    lastAnswer: kind,
    turns: [...d.turns, turnOf(kind, [], now)].slice(-dialogueLimits.turns),
  };
}

/** My question asked again in its task (an unreadable answer, "là sao", "Giữ lại"). */
export function afterAsk(
  prev: DialogueState | null,
  x: {
    ownerUid: string;
    conversationId: string;
    taskId: string;
    pc: Clarification;
    expiresAt: Date;
    now: Date;
  },
): DialogueState {
  const d = prev ?? emptyDialogue(x.ownerUid, x.conversationId, x.now);
  const was =
    d.question?.taskId === x.taskId
      ? d.question
      : d.setAside?.taskId === x.taskId
        ? d.setAside
        : null;
  return {
    ...d,
    question: {
      taskId: x.taskId,
      clarificationId: x.pc.id,
      field: x.pc.field,
      choiceIds: x.pc.choices.map((c) => c.id),
      allowText: x.pc.allowText,
      askedAt: x.now.toISOString(),
      expiresAt: x.expiresAt.toISOString(),
      about: was?.about ?? null,
    },
    setAside:
      d.setAside?.taskId === x.taskId
        ? null
        : d.question && d.question.taskId !== x.taskId
          ? { ...d.question, at: x.now.toISOString() }
          : d.setAside,
    lastAnswer: 'question',
    turns: [...d.turns, turnOf('question', [], x.now)].slice(-dialogueLimits.turns),
  };
}

/** My question answered (the next round settles the rest). */
export function afterAnswer(d: DialogueState, taskId: string): DialogueState {
  return d.question?.taskId === taskId ? { ...d, question: null } : d;
}

// ---------- Words for an item ----------

const L = (vi: string, en: string) => ({ vi, en });
type Locale = 'vi' | 'en';

/** "cữ bú bình 180ml lúc 13:00" / "bottle feed 180 ml at 13:00". */
export function itemLabel(
  kind: DraftKind,
  keys: DialogueKeys,
  zone: string,
  locale: Locale,
  now: Date,
): string {
  const name =
    kind === 'timer'
      ? keys.timer === 'breast'
        ? L('đồng hồ bú', 'feed timer')
        : L('đồng hồ ngủ', 'sleep timer')
      : kindNames[kind];
  const bits: string[] = [name[locale]];
  if (keys.amountMl) bits.push(locale === 'vi' ? `${keys.amountMl}ml` : `${keys.amountMl} ml`);
  if (keys.durationMin && kind !== 'sleep') {
    bits.push(locale === 'vi' ? `${keys.durationMin} phút` : `${keys.durationMin} min`);
  }
  if (keys.diaper) {
    bits.push(
      { wet: L('ướt', 'wet'), dirty: L('bẩn', 'dirty'), both: L('ướt và bẩn', 'wet and dirty') }[
        keys.diaper
      ][locale],
    );
  }
  if (keys.at) {
    const t = new Date(keys.at);
    const clock = localClock(zone, t);
    const yesterday = localDateIn(zone, t) < localDateIn(zone, now);
    const when =
      kind === 'sleep' ? L(`từ ${clock}`, `from ${clock}`) : L(`lúc ${clock}`, `at ${clock}`);
    bits.push(when[locale] + (yesterday ? (locale === 'vi' ? ' hôm qua' : ' yesterday') : ''));
  }
  return bits.join(' ');
}

const examples: Partial<Record<DraftKind, { vi: string; en: string }>> = {
  bottle: L('“150 chứ” hoặc “lúc 13h mới đúng”', '“150 actually” or “it was at 1 pm”'),
  pump: L('“120ml chứ”', '“120 ml actually”'),
  breast: L('“thêm 5 phút” hoặc “bên trái chứ”', '“5 more minutes” or “left side actually”'),
  sleep: L(
    '“dậy lúc 6h mới đúng” hoặc “thêm 10 phút”',
    '“woke at 6 actually” or “10 more minutes”',
  ),
  diaper: L('“tã bẩn chứ”', '“dirty actually”'),
};

const fieldWait: Record<string, (item: string) => { vi: string; en: string }> = {
  'time.missing': (i) =>
    L(
      `Mình đang chờ giờ của ${i} để ghi. Chọn bên dưới hoặc gõ giờ, ví dụ 13:00 hoặc “30 phút trước”.`,
      `I’m waiting for the time of the ${i} to log it. Pick one below or type a time, e.g. 13:00 or “30 min ago”.`,
    ),
  'time.ampm': (i) =>
    L(
      `Mình đang chờ biết ${i} là buổi sáng hay chiều tối. Chọn bên dưới hoặc gõ “sáng” / “tối”.`,
      `I’m waiting to know if the ${i} was in the morning or the evening. Pick one below or type “morning” / “evening”.`,
    ),
  'time.start': (i) =>
    L(
      `Mình đang chờ giờ bắt đầu của ${i}. Chọn bên dưới hoặc gõ giờ, ví dụ 21:00.`,
      `I’m waiting for when the ${i} started. Pick one below or type a time, e.g. 21:00.`,
    ),
};

const fallbackItem = L('việc bạn vừa nhắn', 'what you just sent');

/** The question's item in words, else "việc bạn vừa nhắn". */
export function aboutLabel(
  q: Pick<DialogueQuestion, 'about'>,
  zone: string,
  locale: Locale,
  now: Date,
): string {
  return q.about ? itemLabel(q.about.kind, q.about.keys, zone, locale, now) : fallbackItem[locale];
}

/** "là sao" while my question waits: what I wait for and how to answer (the chips follow). */
export function questionWaitPart(
  q: DialogueQuestion,
  zone: string,
  locale: Locale,
  now: Date,
  why: 'meta' | 'short' | 'keep',
): AssistantPart {
  const item = aboutLabel(q, zone, locale, now);
  const words =
    why === 'keep'
      ? L(`Ok, mình giữ câu hỏi về ${item}:`, `OK, keeping the question about the ${item}:`)
      : (fieldWait[q.field]?.(item) ??
        L(
          `Mình đang chờ câu trả lời cho câu hỏi về ${item} để làm tiếp. Chọn bên dưới hoặc gõ câu trả lời.`,
          `I’m waiting for your answer about the ${item} to go on. Pick one below or type it.`,
        ));
  return { type: 'text', schemaVersion: 1, text: words[locale], code: 'FOLLOW_UP' };
}

/** P-168 #6: a new topic closed my open question; the app adds "Giữ lại". */
export function setAsidePart(
  q: DialogueQuestion,
  zone: string,
  locale: Locale,
  now: Date,
): AssistantPart {
  const item = q.about ? itemLabel(q.about.kind, q.about.keys, zone, locale, now) : null;
  const words = item
    ? L(`Mình bỏ câu hỏi về ${item} nhé.`, `I’ve dropped the question about the ${item}.`)
    : L('Mình bỏ câu hỏi trước nhé.', 'I’ve dropped the earlier question.');
  return { type: 'text', schemaVersion: 1, text: words[locale], code: 'QUESTION_SET_ASIDE' };
}

/** What waits or was just done, said plainly (a short reply or "là sao" with nothing to answer). */
export function restatePart(
  d: DialogueState,
  zone: string,
  locale: Locale,
  now: Date,
): AssistantPart | null {
  const label = (i: { kind: DraftKind; keys: DialogueKeys }) =>
    itemLabel(i.kind, i.keys, zone, locale, now);
  const ex = (k: DraftKind) => examples[k]?.[locale] ?? null;
  let words: { vi: string; en: string } | null = null;
  if (d.waiting.length > 1) {
    const list = d.waiting.slice(0, 3).map(label).join(', ');
    words = L(
      `${d.waiting.length} mục đang chờ bạn lưu ở trên: ${list}. Bấm Lưu để ghi, hoặc nhắn để sửa.`,
      `${d.waiting.length} items are waiting above: ${list}. Tap Save to log them, or message me to fix one.`,
    );
  } else if (d.waiting.length === 1) {
    const w = d.waiting[0]!;
    const e = ex(w.kind);
    words = L(
      `Mình đang chờ bạn lưu ${label(w)} ở trên. Bấm Lưu để ghi${e ? `, hoặc nhắn để sửa, ví dụ ${e}` : ''}.`,
      `The ${label(w)} is waiting above. Tap Save to log it${e ? `, or message me to fix it, e.g. ${e}` : ''}.`,
    );
  } else if (d.saved.length > 0) {
    const s = d.saved[0]!;
    const e = ex(s.kind);
    words = L(
      `Mình đã lưu ${label(s)}. Muốn sửa thì nhắn${e ? `, ví dụ ${e}` : ''}, hoặc “xoá cái vừa ghi”.`,
      `I saved the ${label(s)}. To change it, message me${e ? `, e.g. ${e}` : ''}, or “delete that”.`,
    );
  }
  return words ? { type: 'text', schemaVersion: 1, text: words[locale], code: 'FOLLOW_UP' } : null;
}

/** The replies of a follow-up the server applied itself. */
export function followUpPart(
  what:
    | 'cancel_question'
    | 'discarded'
    | 'delete_ready'
    | 'edit_ready'
    | 'corrected'
    | 'keep_expired'
    | 'record_gone'
    | 'already_gone',
  item: string,
  locale: Locale,
): AssistantPart {
  const words = {
    cancel_question: L(
      `Mình đã huỷ ${item}, chưa có gì được lưu.`,
      `Cancelled the ${item}; nothing was saved.`,
    ),
    discarded: L(
      `Mình đã bỏ bản nháp ${item}, chưa có gì được lưu.`,
      `Dropped the draft ${item}; nothing was saved.`,
    ),
    delete_ready: L(
      `Xoá ${item} đã lưu? Bấm Xoá ở thẻ dưới để xoá khỏi nhật ký.`,
      `Delete the saved ${item}? Tap Delete on the card below to remove it from the log.`,
    ),
    edit_ready: L(
      `${item.charAt(0).toUpperCase()}${item.slice(1)} đã được lưu. Mình chuẩn bị bản sửa ở dưới — bấm Lưu để cập nhật nhật ký.`,
      `The ${item} is already saved. Here’s the change below — tap Save to update the log.`,
    ),
    corrected: L(
      `Mình đã sửa ${item} và bỏ bản nháp trước. Kiểm tra rồi bấm Lưu nhé.`,
      `Updated the ${item} and set the earlier draft aside. Check it and tap Save.`,
    ),
    keep_expired: L(
      `Câu hỏi về ${item} đã hết hạn. Bạn nhắn lại việc cần ghi giúp mình nhé.`,
      `The question about the ${item} has expired. Could you send it again?`,
    ),
    record_gone: L(
      `Mình không tìm thấy ${item} trong nhật ký nữa (có thể đã được xoá).`,
      `I can’t find the ${item} in the log any more (it may have been deleted).`,
    ),
    already_gone: L(
      `${item.charAt(0).toUpperCase()}${item.slice(1)} đã được bỏ rồi, chưa có gì được lưu.`,
      `The ${item} was already dropped; nothing was saved.`,
    ),
  }[what];
  return {
    type: 'text',
    schemaVersion: 1,
    text: words[locale],
    code: what === 'corrected' ? 'CORRECTION_APPLIED' : 'FOLLOW_UP',
  };
}

// ---------- The resolver (P-168 #2) ----------

export type FollowUpTarget =
  { saved: false; item: DialogueWaiting } | { saved: true; item: DialogueSaved };

/** What a message is, read against the author's state, before rules or the model. */
export type Resolution =
  /** My open question: the words answer it (`submitClarification`). */
  | { kind: 'answer'; question: DialogueQuestion }
  /** "là sao" / "ok" while my question waits: the question again, said plainly, with its chips. */
  | { kind: 'reask'; question: DialogueQuestion; why: 'meta' | 'short' }
  /** "huỷ" / "xoá cái vừa ghi" while my question waits: that task is cancelled. */
  | { kind: 'cancel_question'; question: DialogueQuestion }
  /** "Giữ lại": the question a new topic closed. */
  | { kind: 'keep'; question: DialogueQuestion }
  /** "xoá cái vừa ghi": the waiting draft dropped, or a delete draft of the saved record. */
  | { kind: 'delete'; target: FollowUpTarget }
  /** "180 chứ", "thêm 10 phút": a replacement draft, or an edit draft of the saved record. */
  | { kind: 'correct'; target: FollowUpTarget; change: DialogueChange }
  /** "là sao" / a short reply while a draft waits: what waits, said plainly. */
  | { kind: 'restate' }
  /** "rồi ngủ lúc 10h": a new log after the last one (its day, a later time). */
  | { kind: 'continue'; after: string }
  | { kind: 'none' };

/** Which kinds a change can apply to. */
const changeKinds: Record<DialogueChange['field'], readonly DraftKind[]> = {
  amountMl: ['bottle', 'pump'],
  addMin: ['breast', 'sleep', 'pump'],
  durationMin: ['breast', 'sleep', 'pump'],
  clock: ['bottle', 'breast', 'sleep', 'pump', 'diaper'],
  side: ['breast', 'pump'],
  milk: ['bottle'],
  diaper: ['diaper'],
  kind: [],
};

/** Waiting drafts and records saved in the last 30 min, the latest first. */
export function recentTargets(d: DialogueState): FollowUpTarget[] {
  const all: { t: number; target: FollowUpTarget }[] = [
    ...d.waiting.map((item) => ({
      t: Date.parse(item.createdAt),
      target: { saved: false as const, item },
    })),
    ...d.saved.map((item) => ({
      t: Date.parse(item.savedAt),
      target: { saved: true as const, item },
    })),
  ];
  // At the same instant a save is what was just done ("cái vừa ghi").
  return all
    .sort((a, b) => b.t - a.t || Number(b.target.saved) - Number(a.target.saved))
    .map((x) => x.target);
}

export function resolveFollowUp(x: {
  text: string;
  dialogue: DialogueState | null;
  /** The rule reader reads a log of its own in the words. */
  ruled: boolean;
  /** The words read as an answer to the open question (`answersOpenQuestion`). */
  answersQuestion: boolean;
  /** Small talk in the words (thanks / hello / bye keep their reply; "ok" does not). */
  talk: SmallTalkKind | null;
}): Resolution {
  const d = x.dialogue;
  if (!d) return { kind: 'none' };
  const cue = followUpCueIn(x.text);
  const q = d.question;
  if (q) {
    if (cue?.kind === 'delete') return { kind: 'cancel_question', question: q };
    if (cue?.kind === 'meta') return { kind: 'reask', question: q, why: 'meta' };
    // "ok" / "không" to "Việc này lúc mấy giờ?" is no time: the question again, with examples.
    if (yesNoIn(x.text) !== null && q.field.startsWith('time.')) {
      return { kind: 'reask', question: q, why: 'short' };
    }
    // L10 A4: "cảm ơn Lumi" keeps its reply (plus the wait line); only "ok" may answer.
    if (x.answersQuestion && !x.ruled && (x.talk === null || x.talk === 'ack')) {
      return { kind: 'answer', question: q };
    }
  }
  if (cue?.kind === 'keep' && d.setAside && !q) return { kind: 'keep', question: d.setAside };
  const items = recentTargets(d).filter((t) => t.item.kind !== 'timer');
  if (cue?.kind === 'delete' && items.length > 0) return { kind: 'delete', target: items[0]! };
  if (cue?.kind === 'correction' && cue.change.field !== 'kind' && (cue.cue || !x.ruled)) {
    const kinds = changeKinds[cue.change.field];
    const target = items.find(
      (t) => kinds.includes(t.item.kind) && (!cue.kindWord || cue.kindWord === t.item.kind),
    );
    if (target) return { kind: 'correct', target, change: cue.change };
  }
  if (cue?.kind === 'continuation' && items.length > 0) {
    const last = items[0]!.item.keys;
    const after = last.endAt ?? last.at ?? null;
    if (after) return { kind: 'continue', after };
  }
  if (q) return { kind: 'none' };
  if (cue?.kind === 'meta' && (d.waiting.length > 0 || d.saved.length > 0)) {
    return { kind: 'restate' };
  }
  // P-168 #2: a short reply never starts a new task while a draft waits ("ok", "180", "ừ").
  if (
    d.waiting.length > 0 &&
    !x.ruled &&
    (x.talk === null || x.talk === 'ack') &&
    shortReplyIn(x.text)
  ) {
    return { kind: 'restate' };
  }
  return { kind: 'none' };
}

// ---------- Applying a change ----------

const SKEW_MS = 5 * 60_000;
const addDays = (date: string, n: number) => {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(y, m - 1, d + n)).toISOString().slice(0, 10);
};

/** "lúc 13h mới đúng" for an item at [current]: the reading nearest it, never in the future. */
export function clockFor(
  c: Extract<DialogueChange, { field: 'clock' }>['clock'],
  current: Date | null,
  zone: string,
  anchor: Date,
): Date | null {
  const [h, m] = c.hhmm.split(':').map(Number) as [number, number];
  const hours = c.explicit ? [h] : [h % 12, (h % 12) + 12];
  const base = localDateIn(zone, current ?? anchor);
  const today = localDateIn(zone, anchor);
  const days = c.dayOffset !== null ? [addDays(today, c.dayOffset)] : [base, addDays(base, -1)];
  const cands = days
    .flatMap((day) =>
      hours.map((hh) =>
        localInstant(zone, day, `${String(hh).padStart(2, '0')}:${String(m).padStart(2, '0')}`),
      ),
    )
    .filter((t) => t.getTime() <= anchor.getTime() + SKEW_MS);
  if (cands.length === 0) return null;
  const ref = (current ?? anchor).getTime();
  return cands.sort((a, b) => Math.abs(a.getTime() - ref) - Math.abs(b.getTime() - ref))[0]!;
}

const iso = (d: Date) => d.toISOString();
const spanMin = (a: string | null | undefined, b: string | null | undefined) => {
  if (!a || !b) return null;
  const n = Math.round((Date.parse(b) - Date.parse(a)) / 60_000);
  return n > 0 ? n : null;
};

/** [p] with [c] applied; null when the change does not fit the item. */
export function applyChange(
  p: DraftPayload,
  c: DialogueChange,
  x: { zone: string; anchor: Date },
): DraftPayload | null {
  switch (c.field) {
    case 'amountMl':
      return p.kind === 'bottle' || p.kind === 'pump' ? { ...p, amountMl: c.value } : null;
    case 'milk':
      return p.kind === 'bottle' ? { ...p, milk: c.value } : null;
    case 'diaper':
      return p.kind === 'diaper' ? { ...p, diaper: c.value } : null;
    case 'side':
      return p.kind === 'breast' || p.kind === 'pump' ? { ...p, side: c.value } : null;
    case 'addMin':
    case 'durationMin': {
      if (p.kind === 'breast' || p.kind === 'pump') {
        const n = c.field === 'addMin' ? (p.durationMin ?? 0) + c.value : c.value;
        return n > 0 ? { ...p, durationMin: n } : null;
      }
      if (p.kind === 'sleep') {
        const cur = p.durationMin ?? spanMin(p.startedAt, p.endedAt);
        const n = c.field === 'addMin' ? (cur ?? 0) + c.value : c.value;
        if (n <= 0) return null;
        if (p.startedAt) {
          const end = new Date(Date.parse(p.startedAt) + n * 60_000);
          if (end.getTime() > x.anchor.getTime() + SKEW_MS) return null;
          return { ...p, endedAt: iso(end), durationMin: n };
        }
        if (p.endedAt) {
          return {
            ...p,
            startedAt: iso(new Date(Date.parse(p.endedAt) - n * 60_000)),
            durationMin: n,
          };
        }
        return { ...p, durationMin: n };
      }
      return null;
    }
    case 'clock': {
      if (p.kind === 'sleep') {
        const cur = c.end ? p.endedAt : p.startedAt;
        const at = clockFor(c.clock, cur ? new Date(cur) : null, x.zone, x.anchor);
        if (!at) return null;
        const next = c.end ? { ...p, endedAt: iso(at) } : { ...p, startedAt: iso(at) };
        return {
          ...next,
          durationMin: spanMin(next.startedAt, next.endedAt) ?? next.durationMin ?? null,
        };
      }
      if (p.kind === 'bottle' || p.kind === 'breast' || p.kind === 'pump' || p.kind === 'diaper') {
        const at = clockFor(
          c.clock,
          p.occurredAt ? new Date(p.occurredAt) : null,
          x.zone,
          x.anchor,
        );
        return at ? { ...p, occurredAt: iso(at) } : null;
      }
      return null;
    }
    default:
      return null;
  }
}

/** A saved care record as the draft that would write it (its current values). */
export function payloadFromRecord(r: DocumentSnapshot): DraftPayload | null {
  if (!r.exists || r.get('deleted') === true) return null;
  const at = (k: string) => {
    const v = r.get(k) as Timestamp | null | undefined;
    return v ? v.toDate().toISOString() : null;
  };
  const data = (r.get('data') as Record<string, unknown> | undefined) ?? {};
  const num = (k: string) => (typeof data[k] === 'number' ? (data[k] as number) : null);
  const side = (data.side as 'left' | 'right' | 'both' | undefined) ?? 'both';
  switch (r.get('type')) {
    case 'bottle':
      return {
        kind: 'bottle',
        amountMl: num('amountMl'),
        occurredAt: at('occurredAt'),
        milk: data.milk === 'formula' ? 'formula' : 'breast_milk',
      };
    case 'breast':
      return {
        kind: 'breast',
        occurredAt: at('occurredAt'),
        durationMin: num('durationMin'),
        side,
      };
    case 'pump':
      return {
        kind: 'pump',
        amountMl: num('amountMl'),
        occurredAt: at('occurredAt'),
        side,
        durationMin: num('durationMin'),
      };
    case 'diaper':
      return {
        kind: 'diaper',
        diaper: (data.kind as 'wet' | 'dirty' | 'both' | undefined) ?? null,
        occurredAt: at('occurredAt'),
      };
    case 'sleep': {
      const s = at('occurredAt');
      const e = at('endedAt');
      return { kind: 'sleep', startedAt: s, endedAt: e, durationMin: spanMin(s, e) };
    }
    default:
      return null;
  }
}

// ---------- The model's and the planner's view ----------

/** Free-text fields that never leave the server in the conversation state. */
const wordFields = new Set([
  'note',
  'title',
  'merchant',
  'assigneeUid',
  'recipeId',
  'babyId',
  'keepReceipt',
  'linked',
]);

/**
 * L7: the drafts waiting and the records saved in the last 30 min (the planner reads their full
 * payloads, the records' current values; corrections replace or edit them), with the words of the
 * latest one's message for its period words (`text`, read here and never stored or sent).
 */
export async function previousFromDialogue(
  db: Firestore,
  d: DialogueState | null,
  babyId: string,
): Promise<PreviousTurn | null> {
  if (!d) return null;
  const targets = recentTargets(d).slice(0, dialogueLimits.items);
  if (targets.length === 0) return null;
  const rows = await Promise.all(
    targets.map(async (t) => {
      const [draft, record] = await Promise.all([
        draftRef(db, t.item.taskId, t.item.draftId).get(),
        t.saved
          ? db.doc(`babies/${babyId}/records/${t.item.recordId}`).get()
          : Promise.resolve(null),
      ]);
      if (!draft.exists) return null;
      const state = draft.get('state') as string;
      const payload =
        t.saved && record ? payloadFromRecord(record) : (draft.get('payload') as DraftPayload);
      // A record deleted since (or a timer, whose record is the session's): nothing to correct.
      if (!payload) return null;
      return {
        id: draft.id,
        taskId: t.item.taskId,
        state: t.saved ? 'saved' : state,
        payload,
        recordLink: (draft.get('recordLink') as string | null | undefined) ?? null,
        recordId: t.saved ? t.item.recordId : null,
      };
    }),
  );
  const drafts = rows.filter((r): r is NonNullable<typeof r> => r !== null);
  if (drafts.length === 0) return null;
  const latest = await taskRef(db, drafts[0]!.taskId).get();
  return {
    taskId: drafts[0]!.taskId,
    text: (latest.get('input.text') as string | null | undefined) ?? '',
    drafts,
  };
}

/** What the model sees (v8): kinds, values and local times; no words, ids or names. */
export function dialogueForModel(
  d: DialogueState | null,
  prev: PreviousTurn | null,
  zone: string,
  today: string,
  now: Date,
): {
  text: null;
  drafts: Record<string, unknown>[];
  question: { field: string; about: string | null } | null;
  turns: { kind: string; items: string[]; minutesAgo: number }[];
} | null {
  const drafts = (prev?.drafts ?? []).filter((x) => x.state !== 'discarded');
  if (!d && drafts.length === 0) return null;
  if (d && !d.question && drafts.length === 0 && d.turns.length === 0) return null;
  const local = (v: string) => {
    const t = new Date(v);
    const date = localDateIn(zone, t);
    return { time: localClock(zone, t), dayOffset: date === today ? 0 : date < today ? -1 : 1 };
  };
  return {
    text: null,
    // L9: each item carries the id the model names in `target` ("i1" = prev.drafts[0] …).
    drafts: drafts.map((x) => {
      const out: Record<string, unknown> = {
        id: `i${(prev?.drafts ?? []).indexOf(x) + 1}`,
        kind: x.payload.kind,
        saved: x.state === 'saved',
      };
      for (const [k, v] of Object.entries(x.payload as Record<string, unknown>)) {
        if (k === 'kind' || v === null || v === undefined || wordFields.has(k)) continue;
        out[k] =
          k === 'occurredAt' || k === 'startedAt' || k === 'endedAt' || k === 'at'
            ? local(v as string)
            : v;
      }
      return out;
    }),
    question: d?.question
      ? {
          field: d.question.field,
          about: d.question.about
            ? itemLabel(d.question.about.kind, d.question.about.keys, zone, 'en', now)
            : null,
        }
      : null,
    turns: (d?.turns ?? []).map((t) => ({
      kind: t.kind,
      items: [...t.items],
      minutesAgo: Math.max(0, Math.round((now.getTime() - Date.parse(t.at)) / 60_000)),
    })),
  };
}
