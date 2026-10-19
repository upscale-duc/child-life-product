/**
 * Lumi end-to-end scenarios (docs/assistant/test-plan.md): the shape of a case file. Synthetic
 * data only. Times are local in Asia/Ho_Chi_Minh on the anchor day 2026-10-15 (Thursday):
 * "D0 08:00" = that day, "D-1 21:00" = the day before; dates "D0", "D1"…
 */

/** Members of the synthetic household (uids match the app's test fixtures). */
export type Who = 'MOM' | 'DAD' | 'NANNY' | 'AUNT' | 'GRANDMA' | 'NANNY_SPEND';

/** One scripted intent (fake mode): what a correct model returns under the v3 prompt. */
export interface FakeIntent {
  /** Draft kind; "diaper|meal" = the first one the contracts know (future kinds fall back). */
  k: string;
  f?: Record<string, unknown>;
  /** Evidence by field: the exact words. */
  ev?: Record<string, string>;
  miss?: string[];
  unc?: string[];
  /** correctsPrevious */
  cp?: boolean;
}

/** One scripted model reply (fake mode). */
export interface FakeModel {
  i?: FakeIntent[];
  reads?: { tool: string; dayOffset: number }[];
  clar?: string | null;
  care?: {
    topic: 'sleep_concern' | 'meal_ideas';
    sleep?: { kind: string | null; when: string | null; since: string | null } | null;
    evidence?: { field: string; text: string }[];
  } | null;
  health?: string[];
  talk?: boolean;
  oos?: boolean;
  /** A raw reply (e.g. an unknown tool) sent as is. */
  raw?: unknown;
  /** A provider failure. */
  error?: 'timeout' | 'http';
}

/** An answer to the server's question: a chip by index or id, a member, or typed text. */
export interface Answer {
  /** Field (prefix) this answer is for; the first open question matching it is answered. */
  field: string;
  choice?: number | string;
  member?: Who;
  text?: string;
  /** Minutes after the question was asked (expiry tests). */
  afterMin?: number;
}

export type Turn =
  | {
      say: string;
      as?: Who;
      /** Local "HH:mm" on D0 or "+N" minutes after the previous turn. */
      at?: string;
      /** Fake mode: the model replies for this message (start + any re-reading). */
      model?: FakeModel | FakeModel[] | null;
      answers?: Answer[];
      /** Send the same request twice (idempotent replay). */
      replay?: boolean;
      /** Conversation the app sends: the baby's shared thread (default for shared roles) or none. */
      conversation?: 'shared' | 'none';
      intentHint?: 'expense' | null;
      /** LUMI-05: sent by an app build from before 2026-10-16 (no `clientDraftKinds`). */
      client?: 'legacy';
    }
  | {
      photo: 'receipt' | 'blurry' | 'note';
      as?: Who;
      at?: string;
      /** Fake mode: the image reading(s). */
      reading?: unknown[];
      hint?: 'expense' | null;
      retention?: 'delete_after_read' | 'keep_with_record';
      answers?: Answer[];
    }
  /** Edit a draft like the app's editor: set values, confirm the flagged fields. */
  | { patch: { draft?: number; set?: Record<string, unknown>; confirm?: 'flagged' | string[] } }
  /** Save drafts of the last task: all pending (default) or by index. */
  | {
      confirm: 'all' | number[];
      as?: Who;
      acknowledge?: ('duplicate_suspected' | 'overlap')[];
      /** Send the same confirm twice with the same request id. */
      retry?: boolean;
    }
  | { cancel: true }
  | { withdrawConsent: Who };

export interface Expect {
  /** Allowed outcomes of the last message (one of). */
  outcome?: string | string[];
  /** Draft kinds (exact, in order); a list of lists = any of them (e.g. a sleep draft or a timer). */
  kinds?: string[] | string[][];
  /** Every draft can be saved as it is (no review, no problem). */
  ready?: boolean;
  /** Fields that must be flagged for review on some draft. */
  review?: string[];
  /** Payload values: "0.amountMl": 120, "0.occurredAt": "D0 08:00", "0.date": "D1". */
  values?: Record<string, unknown>;
  /** Server questions asked, in order (prefix match). */
  asks?: string[];
  visibility?: 'shared' | 'private';
  /** Credits committed by the whole case. */
  credits?: number;
  /** Domain records saved by the whole case. */
  saved?: number;
  /** A refusal (callable reason) or the task's errorCode. */
  error?: string;
  /** Notice codes that must appear. */
  codes?: string[];
  /** Notice codes that must NOT appear (2026-10-16: "vòng đầu" is saved, never PART_NOT_SAVED). */
  notCodes?: string[];
  /**
   * Values in the saved care records' `data` (2026-10-16): "growth.headCm": 39 = some growth
   * record this case saved has `data.headCm` 39; null = the key is absent or null.
   */
  recordData?: Record<string, unknown>;
  /** Fake mode: model calls for the whole case. */
  calls?: number;
  /** Invariants this case is allowed to break by design (rare; documented). */
  allow?: string[];
}

export interface World {
  /** Record presets: "bottle0800", "day", "sleepNight", "expense500k". */
  seed?: string[];
  /** Flags to switch off. */
  off?: string[];
  /** Members without the assistant consent. */
  noConsent?: Who[];
  /** Free credits (default 1000). */
  quota?: number;
  /** Baby date of birth (default 2026-03-10, ~7 months); null = unknown. */
  dob?: string | null;
}

export interface Case {
  id: string;
  group: string;
  title?: string;
  locale?: 'vi' | 'en';
  /** Local time on D0 of the first turn (default 14:20). */
  anchor?: string;
  as?: Who;
  world?: World;
  turns: Turn[];
  expect: Expect;
  /** A device bug this case reproduces (docs/assistant/test-report-*.md). */
  device?: string;
  /** Skip the end-of-case "fix and save" probe. */
  noProbe?: boolean;
  /** Run in live mode too (default true for text cases). */
  live?: boolean;
  /**
   * Lumi L2: false = the model reads every message (the rule reader is off): cases about the
   * model itself — a wrong reading the server's backstops catch, a provider failure, credits.
   */
  rules?: boolean;
}

export interface CaseFile {
  group: string;
  note?: string;
  cases: Case[];
}

export type Severity = 'P0' | 'P1' | 'P2';

export interface Violation {
  /** Invariant or expectation id (docs/assistant/test-plan.md §4). */
  code: string;
  severity: Severity;
  /** Where: "turn 1 · after start", "probe · after fix", "expect". */
  at: string;
  detail: string;
}
