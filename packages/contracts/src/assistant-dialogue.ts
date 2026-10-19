import type { Clarification, DraftKind } from './assistant.js';
import {
  bottleMlIn,
  careStatesIn,
  clockTimeIn,
  durationsIn,
  foldVi,
  smallTalkIn,
  type ClockMatch,
} from './assistant-text.js';

/**
 * Lumi L7 (P-168, docs/product/lumi-plan.md §11.3 #1–#2): the conversation, not the message, is
 * the unit of understanding. The server keeps, per author and conversation, what Lumi waits for
 * and what was just done (`assistantConversations/{cv}/dialogue/{uid}`); every new message is
 * resolved against it before any reader. Only ids, kinds, numbers, enums and instants are kept —
 * never a child's name, a note, a caption or the words of a message.
 */

export const dialogueLimits = {
  /** A saved record can be corrected or deleted by a follow-up for this long. */
  savedWindowMin: 30,
  /** The whole state lapses this long after its last write (the question keeps its own TTL). */
  ttlMin: 120,
  /** Turns kept, compacted to kinds and times. */
  turns: 3,
  /** Waiting drafts / saved records kept. */
  items: 6,
} as const;

/** The key values of one item: numbers, enums and instants (ISO) only. */
export interface DialogueKeys {
  amountMl?: number | null;
  milk?: 'breast_milk' | 'formula' | 'other' | null;
  side?: 'left' | 'right' | 'both' | null;
  durationMin?: number | null;
  /** occurredAt / startedAt / a timer's at. */
  at?: string | null;
  endAt?: string | null;
  diaper?: 'wet' | 'dirty' | 'both' | null;
  /** timer: which one and what it does. */
  timer?: 'sleep' | 'breast' | null;
  action?: 'start' | 'stop' | null;
}

export interface DialogueItem {
  taskId: string;
  draftId: string;
  kind: DraftKind;
  keys: DialogueKeys;
}

/** A draft still waiting for "Lưu" / "Bỏ". */
export interface DialogueWaiting extends DialogueItem {
  revision: number;
  createdAt: string;
}

/** A record saved (or changed) through Lumi in the last 30 minutes. */
export interface DialogueSaved extends DialogueItem {
  recordId: string;
  savedAt: string;
}

/** The author's open question in this conversation (one at a time). */
export interface DialogueQuestion {
  taskId: string;
  clarificationId: string;
  field: string;
  chips: Clarification['choices'];
  /** A typed answer is allowed (a time, a length). */
  allowText: boolean;
  askedAt: string;
  expiresAt: string;
  /** What the question is about (the first item read from the words), when known. */
  about: { kind: DraftKind; keys: DialogueKeys } | null;
}

export type DialogueAnswerKind =
  | 'drafts'
  | 'answer'
  | 'question'
  | 'fallback'
  | 'health'
  | 'failed'
  | 'saved'
  | 'discarded'
  | 'canceled'
  | 'expired'
  | 'restated';

export interface DialogueTurn {
  at: string;
  kind: DialogueAnswerKind;
  items: DraftKind[];
}

export interface DialogueState {
  schemaVersion: 1;
  ownerUid: string;
  conversationId: string;
  question: DialogueQuestion | null;
  /** A question a new topic closed ("Mình bỏ câu hỏi về …"); "Giữ lại" brings it back. */
  setAside: (DialogueQuestion & { at: string }) | null;
  waiting: DialogueWaiting[];
  saved: DialogueSaved[];
  timers: { type: 'sleep' | 'breast'; since: string }[];
  lastAnswer: DialogueAnswerKind | null;
  turns: DialogueTurn[];
  updatedAt: string;
  expiresAt: string;
}

export function emptyDialogue(ownerUid: string, conversationId: string, now: Date): DialogueState {
  return {
    schemaVersion: 1,
    ownerUid,
    conversationId,
    question: null,
    setAside: null,
    waiting: [],
    saved: [],
    timers: [],
    lastAnswer: null,
    turns: [],
    updatedAt: now.toISOString(),
    expiresAt: new Date(now.getTime() + dialogueLimits.ttlMin * 60_000).toISOString(),
  };
}

/**
 * The state as it stands at [now]: lapsed → null; an expired question and records saved more
 * than 30 minutes ago are dropped.
 */
export function liveDialogue(d: DialogueState | null, now: Date): DialogueState | null {
  if (!d || d.schemaVersion !== 1) return null;
  if (Date.parse(d.expiresAt) <= now.getTime()) return null;
  const t = now.getTime();
  const open = (q: DialogueQuestion | null) => (q && Date.parse(q.expiresAt) > t ? q : null);
  return {
    ...d,
    question: open(d.question),
    setAside: d.setAside && Date.parse(d.setAside.expiresAt) > t ? d.setAside : null,
    saved: d.saved.filter(
      (s) => t - Date.parse(s.savedAt) <= dialogueLimits.savedWindowMin * 60_000,
    ),
  };
}

/** Whether anything waits on the person: an open question or a draft not yet saved. */
export const dialogueWaits = (d: DialogueState | null) =>
  Boolean(d && (d.question || d.waiting.length > 0));

// ---------- Follow-up words ----------

/** What a follow-up changes on a waiting draft or a record just saved. */
export type DialogueChange =
  | { field: 'amountMl'; value: number }
  /** "thêm 10 phút" / "bớt 5 phút": minutes added to (or taken from) a length. */
  | { field: 'addMin'; value: number }
  | { field: 'durationMin'; value: number }
  /** "lúc 13h mới đúng": the start (or, with "dậy", a sleep's end). */
  | { field: 'clock'; clock: ClockMatch; end: boolean }
  | { field: 'side'; value: 'left' | 'right' | 'both' }
  | { field: 'milk'; value: 'breast_milk' | 'formula' }
  | { field: 'diaper'; value: 'wet' | 'dirty' | 'both' }
  /** "bình chứ không phải mẹ": another kind (the model re-reads it with the state). */
  | { field: 'kind'; value: DraftKind };

export type FollowUpCue =
  | { kind: 'delete' }
  | { kind: 'keep' }
  | { kind: 'meta' }
  | { kind: 'continuation' }
  | { kind: 'correction'; change: DialogueChange; cue: boolean; kindWord: DraftKind | null }
  | null;

const clean = (text: string) =>
  foldVi(text)
    .replace(/[\p{Extended_Pictographic}\u{FE0F}\u{200D}]/gu, ' ')
    .replace(/[^\p{L}\d:\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();

const particles = /(?:\s+(?:nhe|nha|di|giup|giup minh|giup em|voi|lumi|a|ha|nhi|vay|luon))+$/u;

/** Words of the message (folded, punctuation dropped). */
export const followUpWords = (text: string) => clean(text).split(' ').filter(Boolean);

/** "xoá cái vừa ghi", "huỷ cái đó", "bỏ cữ vừa rồi", "delete that", "undo". */
export function deleteCueIn(text: string): boolean {
  const f = clean(text).replace(particles, '');
  if (
    /^(?:please )?(?:undo|delete (?:that|it|this|the last one|the last|what you just (?:logged|saved))|remove (?:that|it|the last one))$/u.test(
      f,
    )
  ) {
    return true;
  }
  const verb = String.raw`(?:xoa|huy|bo|go)`;
  const what = String.raw`(?:\s+(?:giup(?:\s+(?:minh|em))?|cai|muc|cu|ban ghi|ban nhap|giac|lan|bu|ngu|binh|ta|hut sua|thay ta|cu bu|giac ngu|lan thay ta))*`;
  const which = String.raw`(?:vua ghi|vua luu|vua roi|vua nay|vua xong|vua|do|nay|kia|luc nay|truoc|cuoi)`;
  return (
    new RegExp(String.raw`^(?:lumi\s+)?${verb}${what}\s+${which}$`, 'u').test(f) ||
    new RegExp(String.raw`^(?:lumi\s+)?${verb}(?:\s+di)?$`, 'u').test(f)
  );
}

/** "Giữ lại" (the chip under "Mình bỏ câu hỏi về …"), "keep it". */
export function keepCueIn(text: string): boolean {
  return /^(?:giu lai|giu cau hoi|giu|van giu|keep|keep it|keep the question)$/u.test(
    clean(text).replace(particles, ''),
  );
}

/** "là sao", "sao không ghi", "mình gõ rồi mà", "what?": the person asks what Lumi is doing. */
export function metaCueIn(text: string): boolean {
  const f = clean(text);
  return (
    /(?<![\p{L}])(?:the la sao|la sao|y la sao|sao vay|sao the|gi vay|gi the|hoi gi vay|sao lai hoi|sao (?:khong|ko|k|chua|hong) (?:ghi|luu|hieu|lam)|(?:khong|ko|chua) hieu|minh (?:go|nhan|tra loi|noi|ghi) roi ma|da (?:go|nhan|tra loi|noi) roi ma|(?:go|nhan|tra loi) roi ma|what do you mean|why didn ?t you|why not|i (?:already )?(?:typed|said|answered|told you)|huh)(?![\p{L}])/u.test(
      f,
    ) || /^(?:what|sao|ha|gi|cai gi)$/u.test(f)
  );
}

/** "rồi ngủ lúc 10h", "xong rồi bé ngủ", "then slept at 10": a next log after the last one. */
export function continuationCueIn(text: string): boolean {
  const f = clean(text);
  const m =
    /^(?:roi|xong roi|xong|sau do|tiep theo|tiep do|ke do|then|after that|and then)\s+(.+)$/u.exec(
      f,
    );
  return m !== null && m[1]!.split(' ').filter(Boolean).length >= 1 && smallTalkIn(text) === null;
}

const kindWords: [RegExp, DraftKind][] = [
  [/(?<![\p{L}])(?:hut sua|vat sua|pump(?:ed|ing)?)(?![\p{L}])/u, 'pump'],
  [/(?<![\p{L}])(?:binh|bottle|sua cong thuc|sua bot|formula)(?![\p{L}])/u, 'bottle'],
  [/(?<![\p{L}])(?:bu me|ti me|me|breast(?:feed|fed)?|nurs(?:e|ed|ing))(?![\p{L}])/u, 'breast'],
  [/(?<![\p{L}])(?:ngu|giac|nap|sleep|slept)(?![\p{L}])/u, 'sleep'],
  [/(?<![\p{L}])(?:ta|bim|diaper|nappy)(?![\p{L}])/u, 'diaper'],
];

/** The care kind a few words name ("bình" → bottle, "mẹ" → breast, "ngủ" → sleep). */
export function kindWordIn(text: string): DraftKind | null {
  const f = clean(text);
  return kindWords.find(([re]) => re.test(f))?.[1] ?? null;
}

const correctionCue =
  /(?<![\p{L}])(?:chu|moi dung|moi phai|moi chinh xac|moi chuan|khong phai|ko phai|k phai|nham|a khong|a ko|sua lai|sua thanh|doi lai|doi thanh|thoi|i mean|actually|not|should be|make it|change it to|change to|instead)(?![\p{L}])/u;

/**
 * A correction or an addition of the last item ("180 chứ", "lúc 13h mới đúng", "thêm 10 phút",
 * "bên trái chứ", "bình chứ không phải mẹ"); [cue] when a correcting word was said (else only a
 * bare value, which counts while something waits and the message is short).
 */
export function correctionIn(
  text: string,
): { change: DialogueChange; cue: boolean; kindWord: DraftKind | null } | null {
  const f = clean(text);
  if (f === '') return null;
  // What comes before "không phải" is the right value, what follows the wrong one.
  const not = /(?<![\p{L}])(?:chu )?(?:khong phai|ko phai|k phai|not)(?![\p{L}])/u.exec(f);
  const right = not ? f.slice(0, not.index).trim() : f;
  const wrong = not ? f.slice(not.index + not[0].length).trim() : '';
  const cue = correctionCue.test(f);
  // Kind swap: "bình chứ không phải mẹ".
  if (not && right && wrong) {
    const a = kindWordIn(right);
    const b = kindWordIn(wrong);
    if (a && b && a !== b) return { change: { field: 'kind', value: a }, cue: true, kindWord: a };
  }
  const kindWord = kindWordIn(right);
  // "thêm 10 phút", "bớt 5 phút", "10 more minutes".
  const more = /(?<![\p{L}])(them|bot|giam|tru|cong|more|less|add|plus|minus)(?![\p{L}])/u.exec(
    right,
  );
  const lengths = durationsIn(right);
  if (more && lengths.length === 1 && !bottleMlIn(right)) {
    const sign = /^(?:bot|giam|tru|less|minus)$/u.test(more[1]!) ? -1 : 1;
    return { change: { field: 'addMin', value: sign * lengths[0]!.minutes }, cue: true, kindWord };
  }
  const ml = bottleMlIn(right);
  if (ml) return { change: { field: 'amountMl', value: ml.ml }, cue, kindWord };
  const clock = clockTimeIn(right);
  if (clock) {
    const end = /(?<![\p{L}])(?:day|thuc|tinh|woke|wake|ket thuc|xong)(?![\p{L}])/u.test(right);
    return { change: { field: 'clock', clock, end }, cue, kindWord };
  }
  if (lengths.length === 1) {
    return { change: { field: 'durationMin', value: lengths[0]!.minutes }, cue, kindWord };
  }
  // A bare number ("180 chứ", "150 thôi"): an amount.
  const bare =
    /^(?:la |thanh |is )?(\d{2,4})(?: ml)?(?: (?:chu|thoi|moi dung|moi phai|nhe|nha))*$/u.exec(
      right,
    );
  if (bare) {
    const n = Number(bare[1]);
    if (n >= 5 && n <= 1000) return { change: { field: 'amountMl', value: n }, cue, kindWord };
  }
  // Sides need a correcting word ("phải" is also "must"; "không phải" is "not").
  if (cue) {
    const side =
      /(?<![\p{L}])(?:ben )?(trai|phai|left|right|hai ben|ca hai ben|both)(?![\p{L}])/u.exec(right);
    if (side && !/^(?:phai)$/u.test(right)) {
      const s = side[1]!;
      return {
        change: {
          field: 'side',
          value: /trai|left/u.test(s) ? 'left' : /phai|right/u.test(s) ? 'right' : 'both',
        },
        cue,
        kindWord,
      };
    }
    if (/(?<![\p{L}])(?:sua me|breast milk)(?![\p{L}])/u.test(right)) {
      return { change: { field: 'milk', value: 'breast_milk' }, cue, kindWord: 'bottle' };
    }
    if (/(?<![\p{L}])(?:sua cong thuc|sua bot|cong thuc|formula)(?![\p{L}])/u.test(right)) {
      return { change: { field: 'milk', value: 'formula' }, cue, kindWord: 'bottle' };
    }
    const wet = /(?<![\p{L}])(?:uot|wet|te)(?![\p{L}])/u.test(right);
    const dirty = /(?<![\p{L}])(?:ban|dirty|poo|phan|ia)(?![\p{L}])/u.test(right);
    if (wet || dirty) {
      return {
        change: { field: 'diaper', value: wet && dirty ? 'both' : wet ? 'wet' : 'dirty' },
        cue,
        kindWord: 'diaper',
      };
    }
  }
  return null;
}

/** Words of a log of its own ("bé bú 150ml", "dậy lúc 6h"). */
const logWords =
  /(?<![\p{L}])(?:be|con|bu|an|uong|ngu|thay|hut|tam|day|thuc|feed|fed|ate|drank|slept|nap|woke)(?![\p{L}])/u;

/** "ừ", "ok", "đúng", "không", "chưa": yes / no as a whole reply. */
export function yesNoIn(text: string): 'yes' | 'no' | null {
  const f = clean(text).replace(particles, '');
  if (
    /^(?:u|uh|um|uhm|ok|oke|okay|oki|vang|da|dung|dung roi|duoc|dc|co|yes|yeah|yep|sure|right)$/u.test(
      f,
    )
  )
    return 'yes';
  if (/^(?:khong|ko|k|hong|chua|no|nope|not yet|khong phai)$/u.test(f)) return 'no';
  return null;
}

/**
 * A short reply (≤ 3 words, a number, a time, ừ / ok / đúng / không): never a new task while
 * something waits (P-168 #2), unless it names a log of its own ("bé ngủ rồi").
 */
export function shortReplyIn(text: string): boolean {
  const words = followUpWords(text);
  if (words.length === 0) return false;
  if (careStatesIn(text).length > 0) return false;
  if (words.length <= 3) return true;
  if (yesNoIn(text) !== null) return true;
  const f = clean(text);
  return (
    /^\d+(?:[.,]\d+)?(?: ?ml)?$/u.test(f) || /^\d{1,2}(?::|h|g)\d{0,2}$/u.test(f.replace(/ /g, ''))
  );
}

/** The follow-up the words read as, before anything else (P-168 #2 order: meta words first). */
export function followUpCueIn(text: string): FollowUpCue {
  if (keepCueIn(text)) return { kind: 'keep' };
  if (deleteCueIn(text)) return { kind: 'delete' };
  if (metaCueIn(text)) return { kind: 'meta' };
  const c = correctionIn(text);
  // Without a correcting word only a bare value counts ("180", "13:00"): "bé bú 150ml" is a log.
  if (c && (c.cue || (shortReplyIn(text) && c.kindWord === null && !logWords.test(clean(text))))) {
    return { kind: 'correction', ...c };
  }
  if (continuationCueIn(text)) return { kind: 'continuation' };
  return null;
}
