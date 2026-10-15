import { randomUUID } from 'node:crypto';
import { FieldValue, Timestamp, type Firestore } from 'firebase-admin/firestore';
import {
  assistantConsentVersion,
  assistantFeedbackRequestSchema,
  assistantTaskLimits,
  assistantUsageRequestSchema,
  cancelTaskRequestSchema,
  confirmDraftsRequestSchema,
  creditsFor,
  deleteAssistantConversationRequestSchema,
  discardDraftRequestSchema,
  draftProblems,
  familyCan,
  getAssistantTaskRequestSchema,
  listAssistantHistoryRequestSchema,
  localDateIn,
  patchDraftRequestSchema,
  quoteTaskRequestSchema,
  setAssistantConsentRequestSchema,
  smallTalkIn,
  sameMessage,
  assistantRepeatWindowMin,
  startTaskRequestSchema,
  submitClarificationRequestSchema,
  taskInputKey,
  taskVisibilityFor,
  type AssistantAuthor,
  type AssistantConversationView,
  type AssistantDraftView,
  type AssistantError,
  type AssistantHistoryPage,
  type AssistantMessage,
  type AssistantPart,
  type AssistantQuote,
  type AssistantResponse,
  type AssistantTaskSnapshot,
  type AssistantTaskView,
  type AssistantUsage,
  type ConfirmDraftsResult,
  type ConfirmItemResult,
  type GrantEnvironment,
} from '@child-life/contracts';
import {
  assistantConsentGranted,
  assistantFlagOn,
  authorOf,
  canReadConversation,
  canonical,
  consentRef,
  conversationIdFor,
  conversationRef,
  draftRef,
  fail,
  feedbackIdFor,
  loadTrustedScope,
  memberOf,
  parseRequest,
  quoteRef,
  requireAssistant,
  reservationIdFor,
  respond,
  sameScope,
  sha,
  sharedConversationId,
  sharesThread,
  taskIdFor,
  taskIdOfDraft,
  taskRef,
  toDate,
  toIso,
  withRequest,
  type TrustedScope,
} from './assistant-common.js';
import type { ModelGateway } from './assistant-model.js';
import {
  appendEvents,
  appendMessages,
  messageView,
  storedTask,
  taskSnapshot,
  taskView,
} from './assistant-store.js';
import { healthSignalsIn, moduleAllows, reviewFields } from './assistant-tools.js';
// Lumi rework 2026-10-15: small talk answered at once; money kept out of the shared thread.
import { privateConversationId, sameAsPendingPart, smallTalkPart } from './assistant-talk.js';
// Slice A5 (care): health support with the approved number; CH17 feedback rules.
import {
  careFeedbackFields,
  careFeedbackGate,
  healthSupportPart,
  startedFeedbackIdFor,
} from './assistant-care.js';
import { assistantPool, assistantUsage, creditPolicy, recentUsage } from './assistant-usage.js';
import { buildRecFeedback, confirmDraftItem, draftView } from './assistant-writers.js';
import { releaseQuota, reserveQuota } from './quota.js';
// Slice A3 (photos): attachments verified and bound at start; retention when a task stops.
import {
  bindAttachmentsTx,
  readAttachmentsTx,
  settleTaskAttachments,
  verifyAttachmentsForStart,
  type AttachmentStore,
  type VerifiedAttachment,
} from './assistant-attachments.js';
import { purgeTaskAttachments, revokeAssistantPhotos } from './assistant-lifecycle.js';
import { readRhythmContent } from './rhythm.js';
import { aiBudgetLeft } from './staff.js';

/**
 * Child Life Assistant callables, server core (slice A2; docs/assistant/api.md). Every request
 * carries the contracts envelope (`contractVersion`, `clientRequestId`, `locale`); every answer is
 * an `AssistantResponse`. The uid comes from the token, the plan from stored grants, the scope is
 * re-verified on every call (Admin SDK bypasses Rules). Reason codes are `assistantErrors` only.
 */

export interface AssistantDeps {
  db: Firestore;
  now: Date;
  environment: GrantEnvironment;
  /** Null when no provider key is configured: new work is blocked with AI_UNAVAILABLE. */
  gateway: ModelGateway | null;
  /** Slice A3: the photos' Storage (absent → photo tasks are MODULE_UNAVAILABLE). */
  files?: AttachmentStore;
}

const terminal = new Set(['ready', 'failed', 'canceled']);

/** A task the caller owns (missing and foreign read the same: NOT_MEMBER). */
async function ownTask(db: Firestore, uid: string, taskId: string) {
  const snap = await taskRef(db, taskId).get();
  if (!snap.exists || snap.get('ownerUid') !== uid) throw fail('NOT_MEMBER');
  return snap;
}

/**
 * D-075 #2: a task the caller may read and act on — their own, or a task of the baby's shared
 * thread while they are an active Cùng nuôi / Người chăm sóc of that baby. Private tasks
 * (household, spending, photos, relatives, before D-075) stay with their author only.
 */
async function readableTask(db: Firestore, uid: string, taskId: string, now: Date) {
  const snap = await taskRef(db, taskId).get();
  if (!snap.exists) throw fail('NOT_MEMBER');
  if (snap.get('ownerUid') === uid) return snap;
  if (snap.get('visibility') !== 'shared') throw fail('NOT_MEMBER');
  const babyId = snap.get('scope.babyId') as string;
  const m = memberOf(await db.doc(`babies/${babyId}/members/${uid}`).get(), now);
  if (!sharesThread(m)) throw fail('NOT_MEMBER');
  return snap;
}

async function liveAvailable(deps: AssistantDeps, s: TrustedScope): Promise<boolean> {
  return (
    assistantFlagOn(s, 'assistant_live') &&
    deps.gateway !== null &&
    (await aiBudgetLeft(deps.db, deps.now))
  );
}

// ---------- Consent (P-160) ----------

/**
 * `setAssistantConsent`: the assistant consent on `users/{uid}/settings/ai`, separate from the
 * summaries consent on the same document (never touched here). Withdrawing stops new generation:
 * queued, blocked and waiting tasks fail with CONSENT_REQUIRED and release their credits; a
 * running task drops its output at settle time (M09).
 */
export async function setAssistantConsent(deps: AssistantDeps, uid: string, data: unknown) {
  const { db, now } = deps;
  const req = parseRequest(setAssistantConsentRequestSchema, data);
  if (req.consent && req.consent.version !== assistantConsentVersion) {
    throw fail('VALIDATION_FAILED', { field: 'consent.version' });
  }
  const ref = consentRef(db, uid);
  await db.runTransaction(async (tx) => {
    const prev = (await tx.get(ref)).get('assistant') as
      { version?: string; grantedAt?: unknown } | null | undefined;
    const at = Timestamp.fromDate(now);
    tx.set(
      ref,
      {
        assistant: req.consent
          ? {
              version: req.consent.version,
              grantedAt:
                prev?.version === req.consent.version && prev.grantedAt ? prev.grantedAt : at,
            }
          : null,
        updatedAt: at,
      },
      { mergeFields: ['assistant', 'updatedAt'] },
    );
  });
  let stopped = 0;
  if (!req.consent) {
    const open = await db
      .collection('assistantTasks')
      .where('ownerUid', '==', uid)
      .where('state', 'in', ['queued', 'awaiting_clarification', 'blocked', 'received'])
      .get();
    for (const t of open.docs) {
      if (await stopTask(db, t.id, now, 'failed', 'CONSENT_REQUIRED')) stopped += 1;
    }
    // Slice A3: withdrawing also lets every photo go (Storage-confirmed, else retried).
    await revokeAssistantPhotos(db, deps.files, uid, now).catch(() => undefined);
  }
  const after = (await ref.get()).get('assistant') as {
    version: string;
    grantedAt: unknown;
  } | null;
  return respond(req.clientRequestId, now, {
    assistant: after ? { version: after.version, grantedAt: toIso(after.grantedAt) } : null,
    stoppedTasks: stopped,
  });
}

// ---------- Quote ----------

/**
 * `quoteTask` (brief p.17–18): exact credits for this modality, the household pool now, allowed
 * or the first failing gate (consent, live model, usage). Never calls a model, never reserves.
 */
export async function quoteTask(
  deps: AssistantDeps,
  uid: string,
  data: unknown,
): Promise<AssistantResponse<AssistantQuote>> {
  const { db, now } = deps;
  const req = parseRequest(quoteTaskRequestSchema, data);
  const s = await loadTrustedScope(db, uid, req.scope, now, deps.environment);
  requireAssistant(s);
  if (req.modality === 'text' && req.attachmentCount > 0) throw fail('VALIDATION_FAILED');
  if (req.modality === 'image' && !assistantFlagOn(s, 'assistant_images')) {
    throw fail('FEATURE_DISABLED');
  }
  if (req.conversationId) {
    const conv = await conversationRef(db, req.conversationId).get();
    if (conv.exists) {
      // D-075 #2: the caller's own conversation or the baby's shared thread.
      if (!(await canReadConversation(db, uid, conv, now))) throw fail('NOT_MEMBER');
      if (!sameScope(conv.get('scope'), req.scope)) throw fail('SCOPE_CHANGED');
    } else if (req.conversationId !== sharedConversationId(req.scope.babyId)) {
      throw fail('NOT_MEMBER');
    }
  }
  return withRequest(db, uid, 'quote', req.clientRequestId, req, now, async () => {
    const pool = await assistantPool(db, s, now);
    const usage = await assistantUsage(db, s, now, pool);
    const policy = creditPolicy(s.ctx.config);
    const credits = creditsFor(req.modality, policy);
    const consent = assistantConsentGranted(await consentRef(db, uid).get());
    const reason: AssistantError | null = !consent
      ? 'CONSENT_REQUIRED'
      : !(await liveAvailable(deps, s))
        ? 'AI_UNAVAILABLE'
        : usage.remaining < credits
          ? 'USAGE_EXHAUSTED'
          : null;
    const quoteId = `qt_${randomUUID().replaceAll('-', '')}`;
    const expiresAt = new Date(now.getTime() + assistantTaskLimits.quoteTtlMinutes * 60_000);
    await quoteRef(db, quoteId).set({
      id: quoteId,
      ownerUid: uid,
      familyId: s.familyId,
      scope: req.scope,
      modality: req.modality,
      attachmentCount: req.attachmentCount,
      intentHint: req.intentHint,
      credits,
      plan: pool.plan,
      grantId: pool.grantId,
      windowId: usage.windowId,
      policyVersion: policy.policyVersion,
      allowed: reason === null,
      reason,
      expiresAt: Timestamp.fromDate(expiresAt),
      usedBy: null,
      createdAt: Timestamp.fromDate(now),
    });
    const { windowId: _w, ...view } = usage;
    void _w;
    return respond(
      req.clientRequestId,
      now,
      {
        quoteId,
        modality: req.modality,
        credits,
        allowed: reason === null,
        reason,
        expiresAt: expiresAt.toISOString(),
        usage: view,
      },
      {
        status: reason === null ? 'ok' : 'blocked',
        reasonCode: reason,
        retryable: reason === 'AI_UNAVAILABLE',
      },
    );
  });
}

// ---------- Start ----------

const userParts = (text: string | null): AssistantPart[] =>
  text ? [{ type: 'text', schemaVersion: 1, text }] : [];

/**
 * `startTask` (brief p.10, p.18): one transaction verifies the quote, reserves the credits in the
 * household pool and creates the task `queued` with its conversation and message; the trigger
 * runs it. Same clientRequestId + same input → the same task (a blocked one resumes with a fresh
 * quote, e.g. after a verified upgrade, CH23); different input → IDEMPOTENCY_CONFLICT. Health
 * signs → health support at once, 0 credits, no model, even at quota 0 (CH28). Out of credits or
 * model off → `blocked`, nothing reserved, input kept for resume.
 */
export async function startTask(
  deps: AssistantDeps,
  uid: string,
  data: unknown,
): Promise<AssistantResponse<{ task: AssistantTaskView; usage: AssistantUsage }>> {
  const { db, now } = deps;
  const req = parseRequest(startTaskRequestSchema, data);
  const text = req.text?.trim() ? req.text.trim() : null;
  if (!text && req.attachmentIds.length === 0) throw fail('VALIDATION_FAILED', { field: 'text' });
  const s = await loadTrustedScope(db, uid, req.scope, now, deps.environment);
  requireAssistant(s);
  const quoteSnap = await quoteRef(db, req.quoteId).get();
  const modality = quoteSnap.exists ? (quoteSnap.get('modality') as 'text' | 'image') : 'text';
  const taskId = taskIdFor(uid, req.clientRequestId);
  // ---- Slice A3 (photos): verified before any credit moves (M06) ----
  let verified: VerifiedAttachment[] = [];
  if (modality === 'image' || req.attachmentIds.length > 0) {
    if (!assistantFlagOn(s, 'assistant_images')) throw fail('FEATURE_DISABLED');
    if (modality !== 'image' || req.attachmentIds.length === 0) {
      throw fail('VALIDATION_FAILED', { field: 'attachmentIds' });
    }
    if (!deps.files) throw fail('MODULE_UNAVAILABLE');
    verified = await verifyAttachmentsForStart(
      db,
      deps.files,
      s,
      uid,
      req.scope,
      taskId,
      req.attachmentIds,
      now,
    );
  }
  // ---- end slice A3 ----
  const inputKey = sha(
    taskInputKey({
      conversationId: req.conversationId ?? '',
      scope: req.scope,
      modality,
      text,
      attachmentIds: req.attachmentIds,
    }),
  );
  const signs = text ? healthSignalsIn(text) : [];
  // Slice A5: the household's approved emergency number (none when the pack has no entry).
  const healthPart = signs.length > 0 ? await healthSupportPart(db, s, signs) : null;
  // Rework 2026-10-15: a message that is only small talk ("cảm ơn Lumi", "ok") gets the
  // server's short reply at once — no model, no quote, 0 credits.
  const talk = text && signs.length === 0 && modality === 'text' ? smallTalkIn(text) : null;
  const consent = assistantConsentGranted(await consentRef(db, uid).get());
  const live = await liveAvailable(deps, s);
  const pool = await assistantPool(db, s, now);
  const policy = creditPolicy(s.ctx.config);
  const credits = signs.length > 0 || talk ? 0 : creditsFor(modality, policy);
  const ref = taskRef(db, taskId);
  const at = Timestamp.fromDate(now);
  // ---- D-075 #2: the baby's shared thread, spending excluded ----
  const visibilityInput = {
    scope: req.scope,
    modality,
    intentHint: quoteSnap.exists ? ((quoteSnap.get('intentHint') as string | null) ?? null) : null,
    role: s.member.role,
  };
  // Rework 2026-10-15: money in the words ("mua sữa hết 500k", mixed messages too) keeps the
  // task private from the start: it never reaches the shared thread.
  const visibility = taskVisibilityFor({ ...visibilityInput, text });
  const routedForMoney =
    visibility === 'private' && taskVisibilityFor(visibilityInput) === 'shared';
  const author: AssistantAuthor = authorOf(s.member);
  const sharedId = sharedConversationId(req.scope.babyId);
  // The conversation the app is showing: the caller's own or the shared thread (validated).
  const requested = req.conversationId ? await conversationRef(db, req.conversationId).get() : null;
  if (requested && req.conversationId) {
    if (requested.exists) {
      if (!(await canReadConversation(db, uid, requested, now))) throw fail('NOT_MEMBER');
      if (!sameScope(requested.get('scope'), req.scope)) throw fail('SCOPE_CHANGED');
    } else if (req.conversationId !== sharedId) {
      throw fail('NOT_MEMBER');
    }
  }
  // A shared task always lands in the shared thread (also when the app shows an older private
  // thread of this baby: it stays readable, new messages go to the shared one). A private task
  // continues the caller's own thread, else starts a new private one (never the shared thread).
  const ownPrivate =
    requested?.exists === true &&
    requested.get('shared') !== true &&
    requested.get('ownerUid') === uid;
  const targetConvId =
    visibility === 'shared'
      ? sharedId
      : ownPrivate
        ? req.conversationId!
        : routedForMoney
          ? // Rework 2026-10-15: the author's own private thread about this baby.
            privateConversationId(uid, req.scope.babyId)
          : conversationIdFor(taskId);
  // ---- end D-075 #2 ----

  const out = await db.runTransaction(async (tx) => {
    const existing = await tx.get(ref);
    if (existing.exists) {
      if (existing.get('inputKey') !== inputKey) throw fail('IDEMPOTENCY_CONFLICT');
      if (existing.get('state') !== 'blocked') return { replay: true };
    }
    const resume = existing.exists;
    const convId = resume ? (existing.get('conversationId') as string) : targetConvId;
    const [quote, conv] = await Promise.all([
      tx.get(quoteRef(db, req.quoteId)),
      tx.get(conversationRef(db, convId)),
    ]);
    // Slice A3: the photos, re-read inside the transaction (reads before writes).
    const attachmentSnaps =
      verified.length > 0 ? await readAttachmentsTx(tx, db, req.attachmentIds) : [];
    if (conv.exists) {
      // D-075 #2: the shared thread takes shared tasks only; a private one, its owner's.
      const sharedConv = conv.get('shared') === true;
      if (sharedConv ? !sharesThread(s.member) : conv.get('ownerUid') !== uid) {
        throw fail('NOT_MEMBER');
      }
      if (!sameScope(conv.get('scope'), req.scope)) throw fail('SCOPE_CHANGED');
    }

    const base = {
      id: taskId,
      ownerUid: uid,
      familyId: s.familyId,
      scope: req.scope,
      conversationId: convId,
      // D-075 #2: a resumed task keeps where it started.
      visibility: resume
        ? ((existing.get('visibility') as string | undefined) ?? 'private')
        : visibility,
      author: resume ? (existing.get('author') ?? author) : author,
      // Rework 2026-10-15: why it is private although sent from the shared thread; the
      // sender's previous turn in this thread (corrections, "à không, 150ml").
      routing: resume
        ? (existing.get('routing') ?? null)
        : routedForMoney
          ? { reason: 'spending', from: 'shared_thread', at: 'start' }
          : null,
      previousTaskId: resume
        ? (existing.get('previousTaskId') ?? null)
        : ((conv.get('lastTaskId') as string | undefined) ?? null),
      requestId: req.clientRequestId,
      inputKey,
      input: { text, attachmentIds: req.attachmentIds },
      // "Today" is the original send instant (brief p.12); a resume keeps it.
      anchorInstant: resume ? existing.get('anchorInstant') : at,
      timezone: s.zone,
      locale: req.locale,
      modality,
      round: 0,
      clarifications: [],
      pendingClarification: null,
      clarificationExpiresAt: null,
      lease: null,
      attempt: 0,
      createdAt: resume ? existing.get('createdAt') : at,
      updatedAt: at,
    };
    let lastMsg = (conv.get('messageSeq') as number | undefined) ?? 0;
    let lastEvent = resume ? ((existing.get('eventSeq') as number | undefined) ?? 0) : 0;
    const version = resume ? (existing.get('version') as number) + 1 : 1;
    const convWrite = (lastTaskId: string) => {
      if (conv.exists) {
        tx.update(conv.ref, { messageSeq: lastMsg, updatedAt: at, lastTaskId });
      } else {
        const shared = convId === sharedId && visibility === 'shared';
        tx.set(conv.ref, {
          id: convId,
          // D-075 #2: the shared thread has no owner; its creator is kept for audit only.
          ownerUid: shared ? null : uid,
          shared,
          createdBy: uid,
          familyId: s.familyId,
          scope: req.scope,
          title: null,
          locale: req.locale,
          createdAt: at,
          updatedAt: at,
          archivedAt: null,
          messageSeq: lastMsg,
          lastTaskId,
        });
      }
    };

    // Lumi 2026-10-16: the same words again while their draft still waits just above (the
    // thread's last task, ≤ 10 min) — answered at once, nothing new drafted, nothing replaced,
    // free (the dev report: a second "Con đang ngủ" set the first draft aside).
    const repeatOf =
      !resume && text && !talk && signs.length === 0 && modality === 'text'
        ? await pendingRepeatOf(tx, db, conv.get('lastTaskId') as string | undefined, {
            uid,
            text,
            now,
            visibility,
          })
        : null;
    if (repeatOf) {
      lastMsg = appendMessages(
        tx,
        db,
        convId,
        lastMsg,
        [
          { role: 'user', parts: userParts(text!), taskId, author },
          { role: 'assistant', parts: [sameAsPendingPart(req.locale)], taskId },
        ],
        now,
      );
      lastEvent = appendEvents(
        tx,
        db,
        taskId,
        lastEvent,
        [
          { type: 'accepted', payload: { state: 'queued', credits: 0 } },
          { type: 'answer_ready', payload: { state: 'ready' } },
        ],
        now,
      );
      // The thread's last task stays the one with the draft (corrections still find it).
      convWrite(repeatOf);
      tx.set(ref, {
        ...base,
        quoteId: null,
        credits: 0,
        plan: pool.plan,
        windowId: null,
        reservationId: null,
        usage: 'none',
        state: 'ready',
        version,
        errorCode: null,
        health: null,
        repeatOf,
        eventSeq: lastEvent,
        readyAt: at,
      });
      return { replay: false };
    }

    // Rework 2026-10-15: small talk is answered at once (free, no quote, no model).
    if (talk && !resume) {
      lastMsg = appendMessages(
        tx,
        db,
        convId,
        lastMsg,
        [
          { role: 'user', parts: userParts(text), taskId, author },
          { role: 'assistant', parts: [smallTalkPart(talk, req.locale)], taskId },
        ],
        now,
      );
      lastEvent = appendEvents(
        tx,
        db,
        taskId,
        lastEvent,
        [
          { type: 'accepted', payload: { state: 'queued', credits: 0 } },
          { type: 'answer_ready', payload: { state: 'ready' } },
        ],
        now,
      );
      convWrite(taskId);
      tx.set(ref, {
        ...base,
        quoteId: null,
        credits: 0,
        plan: pool.plan,
        windowId: null,
        reservationId: null,
        usage: 'none',
        state: 'ready',
        version,
        errorCode: null,
        health: null,
        smallTalk: talk,
        eventSeq: lastEvent,
        readyAt: at,
      });
      return { replay: false };
    }
    // Health support first: free, no quote needed, no model (U10, J10).
    if (signs.length > 0 && !resume) {
      lastMsg = appendMessages(
        tx,
        db,
        convId,
        lastMsg,
        [
          { role: 'user', parts: userParts(text), taskId, author },
          {
            role: 'assistant',
            parts: [healthPart!],
            taskId,
          },
        ],
        now,
      );
      lastEvent = appendEvents(
        tx,
        db,
        taskId,
        lastEvent,
        [
          { type: 'accepted', payload: { state: 'queued', credits: 0 } },
          { type: 'answer_ready', payload: { state: 'ready', health: true } },
        ],
        now,
      );
      convWrite(taskId);
      tx.set(ref, {
        ...base,
        quoteId: null,
        credits: 0,
        plan: pool.plan,
        windowId: null,
        reservationId: null,
        usage: 'none',
        state: 'ready',
        version,
        errorCode: null,
        health: signs,
        eventSeq: lastEvent,
        readyAt: at,
      });
      return { replay: false };
    }

    if (!consent) throw fail('CONSENT_REQUIRED');
    if (!quote.exists || quote.get('ownerUid') !== uid) throw fail('QUOTE_MISMATCH');
    if (!sameScope(quote.get('scope'), req.scope)) throw fail('QUOTE_MISMATCH');
    if (
      quote.get('modality') !== modality ||
      quote.get('attachmentCount') !== req.attachmentIds.length
    ) {
      throw fail('QUOTE_MISMATCH');
    }
    if ((toDate(quote.get('expiresAt'))?.getTime() ?? 0) <= now.getTime()) {
      throw fail('QUOTE_EXPIRED');
    }
    const usedBy = quote.get('usedBy') as string | null;
    if (usedBy !== null && usedBy !== taskId) throw fail('QUOTE_MISMATCH');
    if (
      quote.get('plan') !== pool.plan ||
      (quote.get('grantId') ?? null) !== pool.grantId ||
      quote.get('credits') !== credits
    ) {
      throw fail('QUOTE_MISMATCH');
    }

    let blocked: AssistantError | null = live ? null : 'AI_UNAVAILABLE';
    let windowId: string | null = null;
    if (!blocked) {
      const r = await reserveQuota(tx, db, {
        familyId: s.familyId,
        reservationId: reservationIdFor(taskId),
        windows: [pool.request],
        requestId: req.clientRequestId,
        holder: taskId,
        units: credits,
        now,
      });
      if (r.outcome === 'denied') blocked = 'USAGE_EXHAUSTED';
      else {
        windowId = r.windows[0]!.windowId;
        // The window moved since the quote (month boundary, new grant): ask for a new quote.
        if (windowId !== quote.get('windowId')) throw fail('QUOTE_MISMATCH');
      }
    }
    const newMessages: {
      role: 'user' | 'assistant';
      parts: AssistantPart[];
      taskId: string;
      attachmentIds?: string[];
      author?: AssistantAuthor | null;
    }[] = resume
      ? []
      : [
          {
            role: 'user',
            parts: userParts(text),
            taskId,
            attachmentIds: req.attachmentIds,
            author,
          },
        ];
    if (blocked === 'USAGE_EXHAUSTED') {
      newMessages.push({
        role: 'assistant',
        parts: [
          { type: 'usage_notice', schemaVersion: 1, reason: 'USAGE_EXHAUSTED', remaining: 0 },
        ],
        taskId,
      });
    }
    lastMsg = appendMessages(tx, db, convId, lastMsg, newMessages, now);
    lastEvent = appendEvents(
      tx,
      db,
      taskId,
      lastEvent,
      [
        {
          type: 'accepted',
          payload: blocked
            ? { state: 'blocked', reason: blocked }
            : { state: 'queued', credits, plan: pool.plan },
        },
      ],
      now,
    );
    convWrite(taskId);
    tx.set(ref, {
      ...base,
      quoteId: req.quoteId,
      credits,
      plan: pool.plan,
      windowId,
      reservationId: blocked ? null : reservationIdFor(taskId),
      usage: blocked ? 'none' : 'reserved',
      state: blocked ? 'blocked' : 'queued',
      version,
      errorCode: blocked,
      health: null,
      eventSeq: lastEvent,
      policyVersion: policy.policyVersion,
    });
    if (!blocked) tx.update(quote.ref, { usedBy: taskId });
    // Slice A3: the photos belong to this task from now on (also while blocked, for resume).
    if (verified.length > 0) bindAttachmentsTx(tx, attachmentSnaps, verified, taskId, now);
    return { replay: false };
  });
  void out;
  const snap = await ref.get();
  const usage = await assistantUsage(db, s, now);
  const { windowId: _w, ...usageView } = usage;
  void _w;
  const t = storedTask(snap);
  return respond(
    req.clientRequestId,
    now,
    { task: taskView(snap), usage: usageView },
    {
      taskId,
      dataVersion: t.version,
      status: t.state === 'blocked' ? 'blocked' : 'ok',
      reasonCode: t.state === 'blocked' ? t.errorCode : null,
      retryable: t.state === 'blocked' && t.errorCode === 'AI_UNAVAILABLE',
    },
  );
}

// ---------- Clarification ----------

/**
 * `submitClarification` (brief p.9): continues the same task and the same reservation (no new
 * credits): the answer is stored, the task goes back to `queued` and the worker runs the next
 * round. A clarification past its TTL releases the credits and asks for a new quote.
 */
export async function submitClarification(
  deps: AssistantDeps,
  uid: string,
  data: unknown,
): Promise<AssistantResponse<{ task: AssistantTaskView }>> {
  const { db, now } = deps;
  const req = parseRequest(submitClarificationRequestSchema, data);
  const { contractVersion: _c, clientRequestId, locale: _l, ...input } = req;
  void _c;
  void _l;
  return withRequest(db, uid, 'clarify', clientRequestId, input, now, async () => {
    const pre = await ownTask(db, uid, req.taskId);
    const s = await loadTrustedScope(db, uid, storedTask(pre).scope, now, deps.environment);
    requireAssistant(s);
    const ref = pre.ref;
    const out = await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const t = storedTask(snap);
      if (t.state !== 'awaiting_clarification' || t.version !== req.expectedVersion) {
        throw fail('INVALID_STATE');
      }
      const pc = t.pendingClarification;
      if (!pc || pc.id !== req.clarificationId) throw fail('INVALID_STATE');
      const choice = req.choiceId ? pc.choices.find((c) => c.id === req.choiceId) : undefined;
      const answerText = req.text?.trim() || null;
      if (req.choiceId ? !choice : !(pc.allowText && answerText)) {
        throw fail('VALIDATION_FAILED', { field: 'answer' });
      }
      const conv = await tx.get(conversationRef(db, t.conversationId));
      const at = Timestamp.fromDate(now);
      if ((toDate(t.clarificationExpiresAt)?.getTime() ?? 0) <= now.getTime()) {
        if (t.reservationId && t.usage === 'reserved') {
          await releaseQuota(tx, db, {
            familyId: t.familyId,
            reservationId: t.reservationId,
            holder: t.id,
            reason: 'clarification_expired',
            now,
          });
        }
        const seq = appendEvents(
          tx,
          db,
          t.id,
          t.eventSeq ?? 0,
          [
            { type: 'task_failed', payload: { state: 'failed', errorCode: 'QUOTE_EXPIRED' } },
            { type: 'usage_updated', payload: { usage: 'released', credits: 0 } },
          ],
          now,
        );
        tx.update(ref, {
          state: 'failed',
          errorCode: 'QUOTE_EXPIRED',
          usage: t.usage === 'reserved' ? 'released' : t.usage,
          pendingClarification: null,
          version: t.version + 1,
          eventSeq: seq,
          updatedAt: at,
        });
        tx.delete(ref.collection('textReading').doc('current'));
        return { expired: true };
      }
      const answer = { choiceId: req.choiceId, text: answerText };
      const shown = choice ? choice.label[t.locale] : answerText!;
      const msg = appendMessages(
        tx,
        db,
        t.conversationId,
        (conv.get('messageSeq') as number | undefined) ?? 0,
        [
          {
            role: 'user',
            parts: [{ type: 'text', schemaVersion: 1, text: shown }],
            taskId: t.id,
            author: authorOf(s.member),
          },
        ],
        now,
      );
      tx.update(conv.ref, { messageSeq: msg, updatedAt: at });
      const seq = appendEvents(
        tx,
        db,
        t.id,
        t.eventSeq ?? 0,
        [{ type: 'accepted', payload: { state: 'queued', round: t.round } }],
        now,
      );
      tx.update(ref, {
        state: 'queued',
        clarifications: t.clarifications.map((c) =>
          c.id === pc.id ? { ...c, answer, answeredAt: at } : c,
        ),
        pendingClarification: null,
        clarificationExpiresAt: null,
        // Slice A5 fix: the attempt cap (3) is per run, not per task — without this reset the
        // 4th round of a 4-round clarification always failed AI_UNAVAILABLE.
        attempt: 0,
        version: t.version + 1,
        eventSeq: seq,
        updatedAt: at,
      });
      return { expired: false };
    });
    if (out.expired) throw fail('QUOTE_EXPIRED');
    const snap = await ref.get();
    return respond(
      clientRequestId,
      now,
      { task: taskView(snap) },
      {
        taskId: req.taskId,
        dataVersion: storedTask(snap).version,
      },
    );
  });
}

// ---------- Drafts ----------

async function draftContext(deps: AssistantDeps, uid: string, draftId: string) {
  const taskId = taskIdOfDraft(draftId);
  if (!taskId) throw fail('VALIDATION_FAILED', { field: 'draftId' });
  // D-075 #2: a shared task's drafts may be edited by the members who may save that module.
  const task = await readableTask(deps.db, uid, taskId, deps.now);
  const s = await loadTrustedScope(
    deps.db,
    uid,
    storedTask(task).scope,
    deps.now,
    deps.environment,
  );
  if (s.familyId !== task.get('familyId')) throw fail('SCOPE_CHANGED');
  const ref = draftRef(deps.db, taskId, draftId);
  if (task.get('ownerUid') !== uid) {
    const kind = (await ref.get()).get('payload.kind') as Parameters<typeof moduleAllows>[0];
    if (!kind || !moduleAllows(kind, s.member)) throw fail('WRITE_DENIED');
  }
  return { taskId, task, s, ref };
}

/**
 * `patchDraft` (CH06): the person's edit, validated like the form, revision + 1, no model, no
 * credits, no domain write. A saved draft is never patched (edit the record in its module).
 */
export async function patchDraft(
  deps: AssistantDeps,
  uid: string,
  data: unknown,
): Promise<AssistantResponse<{ draft: AssistantDraftView }>> {
  const { db, now } = deps;
  const req = parseRequest(patchDraftRequestSchema, data);
  const { contractVersion: _c, clientRequestId, locale: _l, ...input } = req;
  void _c;
  void _l;
  return withRequest(db, uid, 'patch', clientRequestId, input, now, async () => {
    const { ref, taskId } = await draftContext(deps, uid, req.draftId);
    await db.runTransaction(async (tx) => {
      const d = await tx.get(ref);
      if (!d.exists) throw fail('VALIDATION_FAILED', { field: 'draftId' });
      const cur = draftView(d, now);
      if (cur.state === 'saved') throw fail('DRAFT_SAVED');
      if (cur.state === 'discarded') throw fail('INVALID_STATE');
      if (now.getTime() >= Date.parse(cur.expiresAt)) throw fail('DRAFT_EXPIRED');
      if (cur.revision !== req.expectedRevision) throw fail('DRAFT_STALE');
      if (req.payload.kind !== cur.payload.kind) throw fail('VALIDATION_FAILED', { field: 'kind' });
      // Rework 2026-10-15: a sleep's length follows its two ends (the server's figure wins).
      let payload = req.payload;
      if (
        payload.kind === 'sleep' &&
        payload.startedAt &&
        payload.endedAt &&
        payload.durationMin !== undefined
      ) {
        const span = Math.round(
          (Date.parse(payload.endedAt) - Date.parse(payload.startedAt)) / 60_000,
        );
        payload = { ...payload, durationMin: span > 0 ? span : null };
      }
      const before = cur.payload as Record<string, unknown>;
      const after = payload as Record<string, unknown>;
      const changed = new Set(
        Object.keys(after).filter((k) => canonical(after[k]) !== canonical(before[k])),
      );
      // Lumi timers 2026-10-16: only the time (and a start's side) of a timer draft change;
      // which timer, start / stop and the running session it ends are the server's.
      if (payload.kind === 'timer' && cur.payload.kind === 'timer') {
        const c = cur.payload;
        if (
          payload.timer !== c.timer ||
          payload.action !== c.action ||
          payload.sessionId !== c.sessionId ||
          payload.startedAt !== c.startedAt ||
          (payload.action === 'stop' && payload.side !== c.side)
        ) {
          throw fail('VALIDATION_FAILED', { field: 'timer' });
        }
      }
      const problems = draftProblems(payload, now);
      // Lumi 2026-10-16: still-unsure fields the person neither changed nor confirmed, plus the
      // problems' fields; missing = the kind's required fields that are empty (contracts).
      const review = reviewFields(
        payload,
        problems,
        cur.uncertainFields.filter((f) => !changed.has(f) && !req.confirmedFields.includes(f)),
      );
      const uncertain = new Set(review.uncertain);
      const needsReview = uncertain.size > 0 || review.missing.length > 0;
      tx.update(ref, {
        payload,
        missingFields: review.missing,
        uncertainFields: [...uncertain].sort(),
        revision: cur.revision + 1,
        state: needsReview ? 'needs_review' : 'draft',
        errorCode: null,
        updatedAt: Timestamp.fromDate(now),
      });
    });
    const view = draftView(await ref.get(), now);
    return respond(clientRequestId, now, { draft: view }, { taskId, dataVersion: view.revision });
  });
}

/** `discardDraft` ("Bỏ"): never a domain delete, never a refund (the AI work was done). */
export async function discardDraft(
  deps: AssistantDeps,
  uid: string,
  data: unknown,
): Promise<AssistantResponse<{ draft: AssistantDraftView }>> {
  const { db, now } = deps;
  const req = parseRequest(discardDraftRequestSchema, data);
  const { ref, taskId } = await draftContext(deps, uid, req.draftId);
  await db.runTransaction(async (tx) => {
    const d = await tx.get(ref);
    if (!d.exists) throw fail('VALIDATION_FAILED', { field: 'draftId' });
    const cur = draftView(d, now);
    if (cur.state === 'discarded') return;
    if (cur.state === 'saved') throw fail('DRAFT_SAVED');
    if (cur.revision !== req.expectedRevision) throw fail('DRAFT_STALE');
    tx.update(ref, { state: 'discarded', updatedAt: Timestamp.fromDate(now) });
  });
  const view = draftView(await ref.get(), now);
  return respond(req.clientRequestId, now, { draft: view }, { taskId, dataVersion: view.revision });
}

/**
 * `confirmDrafts` (CH07): no model, no credits — works at 0 credits while the drafts' TTL holds.
 * Each selected item is saved on its own (`confirmDraftItem`); saved items stay saved when
 * another fails; a retry sends only the failed ones (a saved one answers with its record).
 */
export async function confirmDrafts(
  deps: AssistantDeps,
  uid: string,
  data: unknown,
): Promise<AssistantResponse<ConfirmDraftsResult>> {
  const { db, now } = deps;
  const req = parseRequest(confirmDraftsRequestSchema, data);
  const { contractVersion: _c, clientRequestId, locale: _l, ...input } = req;
  void _c;
  void _l;
  return withRequest(db, uid, 'confirm', clientRequestId, input, now, async () => {
    // D-075 #2: any member of the shared thread may save a shared task's drafts; each item is
    // re-checked against the CONFIRMER's role for that module (`confirmDraftItem`).
    const task = await readableTask(db, uid, req.taskId, now);
    const t = storedTask(task);
    if (req.scope && !sameScope(req.scope, t.scope)) throw fail('SCOPE_CHANGED');
    const s = await loadTrustedScope(db, uid, t.scope, now, deps.environment);
    if (s.familyId !== t.familyId) throw fail('SCOPE_CHANGED');
    requireAssistant(s);
    if (!assistantFlagOn(s, 'assistant_writes')) throw fail('FEATURE_DISABLED');
    const ids = req.selected.map((x) => x.draftId);
    if (new Set(ids).size !== ids.length || ids.some((id) => taskIdOfDraft(id) !== req.taskId)) {
      throw fail('VALIDATION_FAILED', { field: 'selected' });
    }
    const items: ConfirmItemResult[] = [];
    for (const sel of req.selected) {
      items.push(
        await confirmDraftItem(db, {
          uid,
          taskId: req.taskId,
          familyId: t.familyId,
          babyId: t.scope.babyId,
          zone: s.zone,
          draftId: sel.draftId,
          revision: sel.revision,
          acknowledge: sel.acknowledge,
          requestId: clientRequestId,
          now,
          ...(deps.files ? { files: deps.files } : {}), // Slice A3: kept receipts.
        }),
      );
    }
    // One result card in the conversation (typed; links built by the module adapter), signed by
    // the confirmer; newly saved drafts remember who saved them (D-075 #2).
    const confirmer = authorOf(s.member);
    await db.runTransaction(async (tx) => {
      const conv = await tx.get(conversationRef(db, t.conversationId));
      const saved = await Promise.all(
        items
          .filter((i) => i.status === 'saved')
          .map((i) => tx.get(draftRef(db, req.taskId, i.draftId))),
      );
      for (const d of saved) {
        if (d.exists && !d.get('confirmedBy')) tx.update(d.ref, { confirmedBy: confirmer });
      }
      if (!conv.exists) return;
      const seq = appendMessages(
        tx,
        db,
        t.conversationId,
        (conv.get('messageSeq') as number | undefined) ?? 0,
        [
          {
            role: 'assistant',
            parts: [
              {
                type: 'action_result',
                schemaVersion: 1,
                items: items.map((i) => ({
                  draftId: i.draftId,
                  status: i.status,
                  recordLink: i.recordLink,
                  errorCode: i.errorCode,
                })),
              },
            ],
            taskId: req.taskId,
            author: confirmer,
          },
        ],
        now,
      );
      tx.update(conv.ref, { messageSeq: seq, updatedAt: Timestamp.fromDate(now) });
    });
    const partial = items.some((i) => i.status !== 'saved');
    return respond(
      clientRequestId,
      now,
      { items, partial },
      {
        taskId: req.taskId,
        status: partial ? 'partial' : 'ok',
        reasonCode: items.find((i) => i.errorCode)?.errorCode ?? null,
      },
    );
  });
}

// ---------- Cancel ----------

/**
 * Stops an unfinished task once: releases its reservation (if any) and marks it [state]. The
 * worker's settle transaction is fenced on the task state, so a late worker cannot make it ready
 * or commit credits (brief p.9, U06, M03).
 */
async function stopTask(
  db: Firestore,
  taskId: string,
  now: Date,
  state: 'canceled' | 'failed',
  errorCode: AssistantError | null,
): Promise<boolean> {
  const ref = taskRef(db, taskId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return false;
    const t = storedTask(snap);
    if (terminal.has(t.state)) return false;
    const release = t.reservationId !== null && t.usage === 'reserved';
    if (release) {
      await releaseQuota(tx, db, {
        familyId: t.familyId,
        reservationId: t.reservationId!,
        holder: taskId,
        reason: state === 'canceled' ? 'cancelled' : (errorCode ?? 'failed'),
        now,
      });
    }
    const events: Parameters<typeof appendEvents>[4] = [
      { type: 'task_failed', payload: { state, errorCode } },
    ];
    if (release) events.push({ type: 'usage_updated', payload: { usage: 'released', credits: 0 } });
    const seq = appendEvents(tx, db, taskId, t.eventSeq ?? 0, events, now);
    // Rework 2026-10-15: a text reading kept for an open question goes with the task's stop.
    tx.delete(ref.collection('textReading').doc('current'));
    tx.update(ref, {
      state,
      errorCode,
      usage: release ? 'released' : t.usage,
      lease: null,
      pendingClarification: null,
      clarificationExpiresAt: null,
      version: t.version + 1,
      eventSeq: seq,
      updatedAt: Timestamp.fromDate(now),
    });
    return true;
  });
}

/** `cancelTask`: before a useful result → released; a ready task stays ready (no refund). */
export async function cancelTask(
  deps: AssistantDeps,
  uid: string,
  data: unknown,
): Promise<AssistantResponse<{ task: AssistantTaskView }>> {
  const { db, now } = deps;
  const req = parseRequest(cancelTaskRequestSchema, data);
  await ownTask(db, uid, req.taskId);
  // Slice A3: a stopped photo task lets its photos go at once (CH10 cancel: 0 credits).
  if (await stopTask(db, req.taskId, now, 'canceled', null)) {
    await settleTaskAttachments(db, deps.files, req.taskId, now, true).catch(() => undefined);
  }
  const snap = await taskRef(db, req.taskId).get();
  return respond(
    req.clientRequestId,
    now,
    { task: taskView(snap) },
    {
      taskId: req.taskId,
      dataVersion: storedTask(snap).version,
    },
  );
}

// ---------- Feedback ----------

/**
 * `submitAssistantFeedback` (CH17): 0 credits, no model. Helpful / unsure / not suitable become
 * the module's `recFeedback` (same document as the app's, `source` aside); "Chưa thử" is a valid
 * answer that records nothing tried in the module (nothing was tried) and takes back this task's
 * plan there (its `started` row, D-076 #10), as the app's "Chưa thử" on one's own plan does, so
 * Nhịp lớn lên stops asking about it. One per task and content.
 */
export async function submitAssistantFeedback(
  deps: AssistantDeps,
  uid: string,
  data: unknown,
): Promise<AssistantResponse<{ feedbackId: string | null; outcome: string }>> {
  const { db, now } = deps;
  const req = parseRequest(assistantFeedbackRequestSchema, data);
  const { contractVersion: _c, clientRequestId, locale: _l, ...input } = req;
  void _c;
  void _l;
  return withRequest(db, uid, 'feedback', clientRequestId, input, now, async () => {
    const task = await ownTask(db, uid, req.taskId);
    const t = storedTask(task);
    const s = await loadTrustedScope(db, uid, t.scope, now, deps.environment);
    requireAssistant(s);
    if (!familyCan(s.member, 'rhythm.feedback')) throw fail('WRITE_DENIED');
    const content = await readRhythmContent(db);
    const activity = content?.activities.find(
      (a) => a.id === req.contentId && a.version === req.contentVersion && a.status === 'published',
    );
    if (!activity) throw fail('VALIDATION_FAILED', { field: 'contentId' });
    // Slice A5 (CH17): only this task's guidance; a tried outcome only after the chance to try.
    careFeedbackGate(t, req, now);
    const careFields = careFeedbackFields(t, req, now);
    const at = Timestamp.fromDate(now);
    const note = {
      contentId: req.contentId,
      contentVersion: req.contentVersion,
      outcome: req.outcome,
      at,
    };
    if (req.outcome === 'not_tried') {
      const plan = db.doc(
        `babies/${t.scope.babyId}/recFeedback/${startedFeedbackIdFor(
          uid,
          req.taskId,
          req.contentId,
          req.contentVersion,
        )}`,
      );
      const batch = db.batch();
      batch.update(task.ref, {
        feedback: FieldValue.arrayUnion(note),
        updatedAt: at,
        ...careFields,
      });
      // Only this person's plan from this task (the id says so); absent is fine.
      batch.delete(plan);
      await batch.commit();
      return respond(
        clientRequestId,
        now,
        { feedbackId: null, outcome: req.outcome },
        { taskId: req.taskId },
      );
    }
    const id = feedbackIdFor(uid, req.taskId, req.contentId, req.contentVersion);
    const ref = db.doc(`babies/${t.scope.babyId}/recFeedback/${id}`);
    await db.runTransaction(async (tx) => {
      const existing = await tx.get(ref);
      if (existing.exists) {
        if (existing.get('kind') !== req.outcome) throw fail('DOMAIN_CONFLICT');
        return;
      }
      tx.create(
        ref,
        buildRecFeedback(
          {
            id,
            babyId: t.scope.babyId,
            uid,
            contentId: req.contentId,
            contentVersion: req.contentVersion,
            kind: req.outcome as 'helpful' | 'unsure' | 'not_suitable',
            date: localDateIn(s.zone, now),
          },
          FieldValue.serverTimestamp(),
        ),
      );
      tx.update(task.ref, {
        feedback: FieldValue.arrayUnion(note),
        updatedAt: at,
        ...careFields,
      });
    });
    return respond(
      clientRequestId,
      now,
      { feedbackId: id, outcome: req.outcome },
      { taskId: req.taskId },
    );
  });
}

// ---------- Reads ----------

/** `getAssistantUsage` (CH19): the household pool, reset date, plan; never mutates. */
export async function getAssistantUsage(
  deps: AssistantDeps,
  uid: string,
  data: unknown,
): Promise<AssistantResponse<AssistantUsage>> {
  const { db, now } = deps;
  const req = parseRequest(assistantUsageRequestSchema, data);
  const s = await loadTrustedScope(
    db,
    uid,
    { type: 'child', babyId: req.babyId },
    now,
    deps.environment,
  );
  const { windowId, ...usage } = await assistantUsage(db, s, now);
  const recent = await recentUsage(db, s.familyId, windowId);
  return respond(req.clientRequestId, now, { ...usage, recent });
}

/**
 * `getAssistantTask`: the authoritative snapshot (reconnect, M11). The owner, or any Cùng nuôi /
 * Người chăm sóc for a task of the shared thread (D-075 #2); still a member.
 */
export async function getAssistantTask(
  deps: AssistantDeps,
  uid: string,
  data: unknown,
): Promise<AssistantResponse<AssistantTaskSnapshot>> {
  const { db, now } = deps;
  const req = parseRequest(getAssistantTaskRequestSchema, data);
  const task = await readableTask(db, uid, req.taskId, now);
  await loadTrustedScope(db, uid, storedTask(task).scope, now, deps.environment);
  const snap = await taskSnapshot(db, req.taskId, now, req.afterSequence ?? 0);
  return respond(req.clientRequestId, now, snap, {
    taskId: req.taskId,
    dataVersion: snap.task.version,
  });
}

function conversationView(d: FirebaseFirestore.DocumentSnapshot): AssistantConversationView {
  return {
    id: d.id,
    ownerUid: d.get('ownerUid') ?? null,
    shared: d.get('shared') === true,
    familyId: d.get('familyId'),
    scope: d.get('scope'),
    title: d.get('title') ?? null,
    locale: d.get('locale'),
    createdAt: toIso(d.get('createdAt')) ?? '',
    updatedAt: toIso(d.get('updatedAt')) ?? '',
    archivedAt: toIso(d.get('archivedAt')),
    lastTaskId: d.get('lastTaskId') ?? null,
  };
}

/**
 * `listAssistantHistory` (CH03, D-075 #2): the baby's shared thread first (Cùng nuôi and Người
 * chăm sóc), then the caller's own private conversations about one baby (household / spending
 * threads, threads from before D-075), newest first; or one readable conversation's messages,
 * newest first. Other members' private chats are never listed. Cursors: a private conversation id,
 * or `private` (the private list from its start, after a first page that held only the shared
 * thread).
 */
export async function listAssistantHistory(
  deps: AssistantDeps,
  uid: string,
  data: unknown,
): Promise<
  AssistantResponse<
    AssistantHistoryPage<AssistantConversationView> | AssistantHistoryPage<AssistantMessage>
  >
> {
  const { db, now } = deps;
  const req = parseRequest(listAssistantHistoryRequestSchema, data);
  const s = await loadTrustedScope(
    db,
    uid,
    { type: 'child', babyId: req.babyId },
    now,
    deps.environment,
  );
  if (req.conversationId === null) {
    const items: AssistantConversationView[] = [];
    if (req.cursor === null && sharesThread(s.member)) {
      const shared = await conversationRef(db, sharedConversationId(req.babyId)).get();
      if (shared.exists) items.push(conversationView(shared));
    }
    const room = req.limit - items.length;
    let q = db
      .collection('assistantConversations')
      .where('ownerUid', '==', uid)
      .where('scope.babyId', '==', req.babyId)
      .orderBy('updatedAt', 'desc')
      .limit(room + 1);
    if (req.cursor && req.cursor !== 'private') {
      const c = await conversationRef(db, req.cursor).get();
      if (!c.exists || c.get('ownerUid') !== uid)
        throw fail('VALIDATION_FAILED', { field: 'cursor' });
      q = q.startAfter(c);
    }
    const docs = (await q.get()).docs;
    const page = docs.slice(0, room);
    items.push(...page.map(conversationView));
    const more = docs.length > room;
    return respond(req.clientRequestId, now, {
      items,
      nextCursor: !more ? null : page.length > 0 ? page[page.length - 1]!.id : 'private',
    });
  }
  const conv = await conversationRef(db, req.conversationId).get();
  if (
    !conv.exists ||
    conv.get('scope.babyId') !== req.babyId ||
    !(await canReadConversation(db, uid, conv, now))
  ) {
    throw fail('NOT_MEMBER');
  }
  let q = conv.ref
    .collection('messages')
    .orderBy('sequence', 'desc')
    .limit(req.limit + 1);
  if (req.cursor) {
    const n = Number(req.cursor);
    if (!Number.isInteger(n) || n < 1) throw fail('VALIDATION_FAILED', { field: 'cursor' });
    q = conv.ref
      .collection('messages')
      .where('sequence', '<', n)
      .orderBy('sequence', 'desc')
      .limit(req.limit + 1);
  }
  const docs = (await q.get()).docs;
  const page = docs.slice(0, req.limit).map(messageView);
  return respond(req.clientRequestId, now, {
    items: page,
    nextCursor: docs.length > req.limit ? String(page[page.length - 1]!.sequence) : null,
  });
}

/**
 * `deleteAssistantConversation` (CH03, brief p.19): confirmed by the request. A private
 * conversation by its owner; the baby's shared thread (D-075 #2) by a Cùng nuôi only, for every
 * member (a caregiver is WRITE_DENIED). Unfinished tasks are cancelled (credits released once),
 * then the conversation, its messages, its tasks, drafts and events are deleted. Saved domain
 * records (care, check-ins, feedback, reminders, expenses) are never touched
 * (`domainRecordsKept`); the credit ledger and the execution rows (ids and hashes only) are kept.
 */
export async function deleteAssistantConversation(
  deps: AssistantDeps,
  uid: string,
  data: unknown,
): Promise<AssistantResponse<{ deletedTasks: number; domainRecordsKept: true }>> {
  const { db, now } = deps;
  const req = parseRequest(deleteAssistantConversationRequestSchema, data);
  const conv = await conversationRef(db, req.conversationId).get();
  if (!conv.exists) {
    return respond(req.clientRequestId, now, { deletedTasks: 0, domainRecordsKept: true });
  }
  const shared = conv.get('shared') === true;
  if (shared) {
    const babyId = conv.get('scope.babyId') as string;
    const m = memberOf(await db.doc(`babies/${babyId}/members/${uid}`).get(), now);
    if (!sharesThread(m)) throw fail('NOT_MEMBER');
    if (m!.role !== 'coParent') throw fail('WRITE_DENIED');
  } else if (conv.get('ownerUid') !== uid) {
    throw fail('NOT_MEMBER');
  }
  const tasks = shared
    ? await db.collection('assistantTasks').where('conversationId', '==', req.conversationId).get()
    : await db
        .collection('assistantTasks')
        .where('conversationId', '==', req.conversationId)
        .where('ownerUid', '==', uid)
        .get();
  for (const t of tasks.docs) await stopTask(db, t.id, now, 'canceled', null);
  // Slice A3: the photos go too (Storage-confirmed; a pending one is retried by the sweeper).
  for (const t of tasks.docs) await purgeTaskAttachments(db, deps.files, t.id, now);
  for (const t of tasks.docs) await db.recursiveDelete(t.ref);
  await db.recursiveDelete(conv.ref);
  return respond(req.clientRequestId, now, {
    deletedTasks: tasks.size,
    domainRecordsKept: true,
  });
}

/**
 * Lumi 2026-10-16: the thread's last task when it was the same words ([x.text], contracts
 * `sameMessage`) within `assistantRepeatWindowMin`, by this person (or a shared task in the
 * shared thread), and one of its drafts still waits to be saved — else null. Read inside the
 * start transaction.
 */
async function pendingRepeatOf(
  tx: FirebaseFirestore.Transaction,
  db: FirebaseFirestore.Firestore,
  lastTaskId: string | undefined,
  x: { uid: string; text: string; now: Date; visibility: string },
): Promise<string | null> {
  if (!lastTaskId) return null;
  const prev = await tx.get(taskRef(db, lastTaskId));
  if (!prev.exists || prev.get('state') !== 'ready') return null;
  const shared = prev.get('visibility') === 'shared' && x.visibility === 'shared';
  if (!shared && prev.get('ownerUid') !== x.uid) return null;
  const sentAt = toDate(prev.get('anchorInstant'));
  if (!sentAt || x.now.getTime() - sentAt.getTime() > assistantRepeatWindowMin * 60_000) {
    return null;
  }
  if (!sameMessage(prev.get('input.text') as string | null | undefined, x.text)) return null;
  const drafts = await tx.get(prev.ref.collection('drafts'));
  const waiting = drafts.docs.some(
    (d) =>
      (d.get('state') === 'draft' || d.get('state') === 'needs_review') &&
      (toDate(d.get('expiresAt'))?.getTime() ?? 0) > x.now.getTime(),
  );
  return waiting ? lastTaskId : null;
}
