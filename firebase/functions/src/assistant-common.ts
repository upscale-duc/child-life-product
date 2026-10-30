import { createHash } from 'node:crypto';
import { Timestamp, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import {
  assistantConsentVersion,
  assistantContractVersion,
  inSharedThread,
  sharedConversationIdFor,
  type AssistantAuthor,
  type AssistantError,
  type AssistantResponse,
  type AssistantScope,
  type FlagKey,
  type GrantEnvironment,
  type MemberRole,
} from '@child-life/contracts';
import { flagOn, loadEntitlementContext, type EntitlementContext } from './entitlements.js';

/**
 * Child Life Assistant, server core (slice A2, docs/assistant/architecture.md P-155–P-161):
 * shared errors, ids, the trusted scope and the request ledger. Nothing here logs family data;
 * user text, drafts and records never reach a log line or an error message.
 */

export const DEFAULT_ZONE = 'Asia/Ho_Chi_Minh';

/** A closed assistant reason code (contracts `assistantErrors`); never a stack or provider text. */
export class AssistantFailure extends Error {
  constructor(
    readonly reason: AssistantError,
    readonly retryable = reason === 'AI_UNAVAILABLE',
    /** Field-level details (problem codes, field names), never values. */
    readonly details: Record<string, unknown> = {},
  ) {
    super(reason);
  }
}

export const fail = (reason: AssistantError, details: Record<string, unknown> = {}) =>
  new AssistantFailure(reason, reason === 'AI_UNAVAILABLE', details);

/** The HttpsError code the callable wrapper uses for each reason. */
export function httpsCodeOf(
  reason: AssistantError,
):
  | 'unauthenticated'
  | 'permission-denied'
  | 'resource-exhausted'
  | 'failed-precondition'
  | 'already-exists'
  | 'invalid-argument'
  | 'unavailable'
  | 'not-found' {
  switch (reason) {
    case 'AUTH_REQUIRED':
      return 'unauthenticated';
    case 'NOT_MEMBER':
    case 'READ_DENIED':
    case 'WRITE_DENIED':
    case 'CONSENT_REQUIRED':
    case 'FEATURE_DISABLED':
    case 'REGION_UNSUPPORTED':
      return 'permission-denied';
    case 'USAGE_EXHAUSTED':
      return 'resource-exhausted';
    case 'IDEMPOTENCY_CONFLICT':
      return 'already-exists';
    case 'VALIDATION_FAILED':
      return 'invalid-argument';
    case 'AI_UNAVAILABLE':
      return 'unavailable';
    default:
      return 'failed-precondition';
  }
}

// ---------- Ids (deterministic where a retry must land on the same document) ----------

export const sha = (s: string) => createHash('sha256').update(s).digest('hex');
const hex32 = (s: string) => sha(s).slice(0, 32);

/** Same uid + clientRequestId → same task (startTask replay, M01). */
export const taskIdFor = (uid: string, clientRequestId: string) =>
  `tk_${hex32(`task|${uid}|${clientRequestId}`)}`;
/** A new conversation started by a task is named after it (a replay reuses it). */
export const conversationIdFor = (taskId: string) => `cv_${hex32(`conversation|${taskId}`)}`;
/** `dr_<task hex>_<index>`: the task is derivable from the draft id. */
export const draftIdFor = (taskId: string, index: number) => `dr_${taskId.slice(3)}_${index}`;
export function taskIdOfDraft(draftId: string): string | null {
  const m = /^dr_([a-f0-9]{32})_(\d{1,2})$/.exec(draftId);
  return m ? `tk_${m[1]}` : null;
}
/** Care record id of a draft (`r_` + 32 hex, Rules `^r_[a-f0-9]{32}$`): one record per draft. */
export const recordIdForDraft = (draftId: string) => `r_${hex32(`record|${draftId}`)}`;
/** Lumi L5: the diary's meal id for a draft (contracts `mealIdSchema`). */
export const mealIdForDraft = (draftId: string) => `m_${hex32(`meal|${draftId}`)}`;
/** The app's check-in id (`rhythm_repository.dart`): one per author, observation and day. */
export const checkInIdFor = (babyId: string, uid: string, date: string, observation: string) =>
  `ci_${hex32(`${babyId}|${uid}|${date}|${observation}`)}`;
export const feedbackIdFor = (uid: string, taskId: string, contentId: string, version: number) =>
  `fb_${hex32(`feedback|${uid}|${taskId}|${contentId}|${version}`)}`;
export const reservationIdFor = (taskId: string) => `assistant_${taskId}`;

export const taskRef = (db: Firestore, taskId: string) => db.doc(`assistantTasks/${taskId}`);
export const conversationRef = (db: Firestore, id: string) =>
  db.doc(`assistantConversations/${id}`);
export const draftRef = (db: Firestore, taskId: string, draftId: string) =>
  db.doc(`assistantTasks/${taskId}/drafts/${draftId}`);
export const quoteRef = (db: Firestore, quoteId: string) => db.doc(`assistantQuotes/${quoteId}`);
export const consentRef = (db: Firestore, uid: string) => db.doc(`users/${uid}/settings/ai`);

/** Zero-padded sequence ids keep lexical order = numeric order. */
export const seqId = (n: number) => String(n).padStart(8, '0');

// ---------- Time ----------

export const toDate = (v: unknown): Date | null =>
  v instanceof Timestamp ? v.toDate() : v instanceof Date ? v : null;
export const toIso = (v: unknown): string | null => toDate(v)?.toISOString() ?? null;

// ---------- Trusted scope (bound at task start; the model never chooses it) ----------

export interface ScopeMember {
  uid: string;
  role: MemberRole;
  isOwner: boolean;
  extraRights: Record<string, unknown> | null;
  displayName: string;
  relation: string;
  relationCustom: string | null;
}

export interface TrustedScope {
  uid: string;
  scope: AssistantScope;
  babyId: string;
  familyId: string;
  /** The baby's zone (care days), else the household's, else Vietnam. */
  zone: string;
  /** The household's zone for credit windows (family, else baby, else Vietnam). */
  householdZone: string;
  member: ScopeMember;
  ctx: EntitlementContext;
}

export function memberOf(snap: DocumentSnapshot, now: Date): ScopeMember | null {
  if (!snap.exists || snap.get('status') !== 'active') return null;
  const until = toDate(snap.get('accessUntilAt'));
  if (until && until.getTime() <= now.getTime()) return null;
  return {
    uid: snap.id,
    role: snap.get('role') as MemberRole,
    isOwner: snap.get('isOwner') === true,
    extraRights: (snap.get('extraRights') as Record<string, unknown> | undefined) ?? null,
    displayName: (snap.get('displayName') as string | undefined) ?? '',
    relation: (snap.get('relation') as string | undefined) ?? 'other',
    relationCustom: (snap.get('relationCustom') as string | null | undefined) ?? null,
  };
}

/**
 * Verifies the caller is an active member of the scope's baby (Admin SDK bypasses Rules, so this
 * is the authorization) and loads flags, config and grants. NOT_MEMBER when not, without saying
 * whether the baby exists.
 */
export async function loadTrustedScope(
  db: Firestore,
  uid: string,
  scope: AssistantScope,
  now: Date,
  environment: GrantEnvironment,
): Promise<TrustedScope> {
  let ctx: EntitlementContext;
  try {
    ctx = await loadEntitlementContext(db, uid, scope.babyId, now, environment);
  } catch {
    throw fail('NOT_MEMBER');
  }
  if (!ctx.member) throw fail('NOT_MEMBER');
  const [memberSnap, baby] = await Promise.all([
    db.doc(`babies/${scope.babyId}/members/${uid}`).get(),
    db.doc(`babies/${scope.babyId}`).get(),
  ]);
  const member = memberOf(memberSnap, now);
  if (!member) throw fail('NOT_MEMBER');
  const babyZone = baby.get('timeZone.zone') as string | undefined;
  return {
    uid,
    scope,
    babyId: scope.babyId,
    familyId: ctx.familyId,
    zone: babyZone ?? ctx.family.timeZone ?? DEFAULT_ZONE,
    householdZone: ctx.family.timeZone ?? babyZone ?? DEFAULT_ZONE,
    member,
    ctx,
  };
}

export const sameScope = (a: AssistantScope, b: AssistantScope) =>
  a.type === b.type && a.babyId === b.babyId;

export type AssistantFlag = Extract<
  FlagKey,
  | 'assistant'
  | 'assistant_images'
  | 'assistant_care'
  | 'assistant_live'
  | 'assistant_writes'
  | 'assistant_upsell'
>;
export const assistantFlagOn = (s: TrustedScope, key: AssistantFlag) => flagOn(s.ctx, key);

/** The chat overall (P-161): off → FEATURE_DISABLED for new work; history stays readable. */
export function requireAssistant(s: TrustedScope): void {
  if (!assistantFlagOn(s, 'assistant')) throw fail('FEATURE_DISABLED');
}

/** Only the current assistant consent version counts (P-160); summaries consent is separate. */
export function assistantConsentGranted(snap: DocumentSnapshot | undefined): boolean {
  const c = snap?.get('assistant') as { version?: string } | null | undefined;
  return !!c && c.version === assistantConsentVersion;
}

// ---------- Response envelope ----------

export function respond<T>(
  requestId: string,
  now: Date,
  data: T,
  extra: Partial<
    Pick<AssistantResponse<T>, 'taskId' | 'dataVersion' | 'status' | 'reasonCode' | 'retryable'>
  > = {},
): AssistantResponse<T> {
  return {
    contractVersion: assistantContractVersion,
    requestId,
    taskId: extra.taskId ?? null,
    serverTime: now.toISOString(),
    dataVersion: extra.dataVersion ?? 0,
    status: extra.status ?? 'ok',
    reasonCode: extra.reasonCode ?? null,
    retryable: extra.retryable ?? false,
    data,
  };
}

export function parseRequest<T>(
  schema: { safeParse(d: unknown): { success: boolean; data?: T; error?: unknown } },
  data: unknown,
): T {
  const r = schema.safeParse(data);
  if (!r.success) throw fail('VALIDATION_FAILED');
  return r.data as T;
}

// ---------- Request ledger (idempotent commands) ----------

/** Canonical JSON (sorted keys) so the same input always hashes the same. */
export function canonical(v: unknown): string {
  if (v === null || typeof v !== 'object') return JSON.stringify(v ?? null);
  if (Array.isArray(v)) return `[${v.map(canonical).join(',')}]`;
  const o = v as Record<string, unknown>;
  return `{${Object.keys(o)
    .filter((k) => o[k] !== undefined)
    .sort()
    .map((k) => `${JSON.stringify(k)}:${canonical(o[k])}`)
    .join(',')}}`;
}

const requestRef = (db: Firestore, uid: string, op: string, clientRequestId: string) =>
  db.doc(`assistantRequests/${sha(`${uid}|${op}|${clientRequestId}`).slice(0, 40)}`);

/** The stored answer of a request [withRequest] ran (null when it never succeeded). */
export async function storedRequestAnswer<T>(
  db: Firestore,
  uid: string,
  op: string,
  clientRequestId: string,
): Promise<T | null> {
  const prev = await requestRef(db, uid, op, clientRequestId).get();
  return prev.exists ? (JSON.parse(prev.get('response') as string) as T) : null;
}

/**
 * Runs [run] once per (caller, operation, clientRequestId): a replay with the same input returns
 * the stored answer; the same request id with a different input is IDEMPOTENCY_CONFLICT (brief
 * p.12). Answers are stored only when [run] succeeds, so a failed attempt can be retried.
 */
export async function withRequest<T>(
  db: Firestore,
  uid: string,
  op: string,
  clientRequestId: string,
  input: unknown,
  now: Date,
  run: () => Promise<T>,
): Promise<T> {
  const ref = requestRef(db, uid, op, clientRequestId);
  const inputHash = sha(canonical(input));
  const prev = await ref.get();
  if (prev.exists) {
    if (prev.get('inputHash') !== inputHash) throw fail('IDEMPOTENCY_CONFLICT');
    return JSON.parse(prev.get('response') as string) as T;
  }
  const out = await run();
  await ref.set({
    uid,
    op,
    inputHash,
    response: JSON.stringify(out),
    createdAt: Timestamp.fromDate(now),
  });
  return out;
}

// ---------- D-075 #2: the baby's shared thread (docs/assistant/data.md) ----------

/** The shared thread of [babyId]: `cv_<babyId>` (contracts), hashed if the id would not fit. */
export function sharedConversationId(babyId: string): string {
  return /^[A-Za-z0-9_-]{1,70}$/.test(babyId)
    ? sharedConversationIdFor(babyId)
    : `cv_s_${hex32(`shared|${babyId}`)}`;
}

/** The member block shown next to a message, a task or a saved draft. */
export function authorOf(m: ScopeMember): AssistantAuthor {
  return {
    uid: m.uid,
    name: m.displayName,
    relation: m.relation,
    relationCustom: m.relationCustom,
  };
}

/** Cùng nuôi and Người chăm sóc read and write the shared thread; relatives never (D-075 #2). */
export const sharesThread = (m: Pick<ScopeMember, 'role'> | null): boolean =>
  m !== null && inSharedThread(m.role);

/** A conversation document the caller may read: their own, or the shared thread of a baby they
 * share (still an active Cùng nuôi / Người chăm sóc of it). */
export async function canReadConversation(
  db: Firestore,
  uid: string,
  conv: DocumentSnapshot,
  now: Date,
): Promise<boolean> {
  if (!conv.exists) return false;
  if (conv.get('shared') !== true) return conv.get('ownerUid') === uid;
  const babyId = conv.get('scope.babyId') as string;
  return sharesThread(memberOf(await db.doc(`babies/${babyId}/members/${uid}`).get(), now));
}
