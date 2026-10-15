import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import {
  assistantPartTypes,
  assistantTaskLimits,
  draftKinds,
  familyCan,
  taskStateForOutcome,
  usageForOutcome,
  type AssistantError,
  type AssistantPart,
  type GrantEnvironment,
  type TaskEventType,
  type TaskOutcome,
} from '@child-life/contracts';
import {
  assistantConsentGranted,
  assistantFlagOn,
  consentRef,
  conversationRef,
  draftIdFor,
  loadTrustedScope,
  taskRef,
  toDate,
  type TrustedScope,
} from './assistant-common.js';
import {
  callWithTimeout,
  ModelUnavailable,
  parseExtraction,
  parseWording,
  readToolNames,
  type ClarificationField,
  type ModelGateway,
  type ReadToolName,
} from './assistant-model.js';
import { appendEvents, appendMessages, storedTask, type StoredTask } from './assistant-store.js';
import {
  anchorOf,
  careSummaryTool,
  clarificationFor,
  healthSignalsIn,
  lastMilkOf,
  needsPeriod,
  overlappingSleeps,
  prepareDrafts,
  sleepFactsTool,
  usageSnapshotTool,
  wordingGrounded,
  type PreparedDraft,
  type PrepareNotice,
  type ReadResult,
} from './assistant-tools.js';
import { commitQuota, releaseQuota } from './quota.js';
import { aiBudgetLeft, chargeAi } from './staff.js';

/**
 * The assistant worker (brief p.9, p.18; architecture §3 step 4). A Firestore trigger hands it a
 * task that reached `queued`; it claims the task with a lease and a fencing token in a
 * transaction (as `runSpendingImport`), builds the trusted context (scope bound at start), runs
 * the health rule (no model, 0 credits), calls the model gateway once with a deadline, validates
 * the output (schema, allowlists, times vs the anchor, AM/PM ambiguity), runs the read / prepare
 * tools itself, and settles everything in ONE fenced transaction: drafts, the assistant message,
 * coalesced events, the task state and the credit decision (`usageForOutcome`: commit once, hold
 * while asking, release otherwise). A second delivery finds the task claimed and stops; a late
 * worker whose lease was lost or whose task was cancelled writes nothing and charges nothing.
 * No user text, draft or record reaches a log.
 */

export interface WorkerDeps {
  db: Firestore;
  now: Date;
  environment: GrantEnvironment;
  /** Null when no provider is configured (secret unset): tasks fail with AI_UNAVAILABLE. */
  gateway: ModelGateway | null;
  /** One model call's deadline (default 60 s). */
  timeoutMs?: number;
  /** Lease length (default 300 s, the function's timeout). */
  leaseMs?: number;
}

export const assistantLeaseMs = 300_000;
const maxAttempts = 3;
/** Internal cost estimate per model call (VND) for the AI budget (A09); never shown in the app. */
export const assistantCallCostVnd = 300;

interface WorkResult {
  outcome: TaskOutcome;
  errorCode: AssistantError | null;
  drafts: PreparedDraft[];
  /** Parts before the draft references (summaries, wording, notices). */
  parts: AssistantPart[];
  clarification: ClarificationField | null;
  modelCalls: number;
}

const failWith = (code: AssistantError, kind: 'error' | 'rejected' = 'error'): WorkResult => ({
  outcome:
    kind === 'rejected'
      ? { kind: 'rejected', detail: code }
      : { kind: 'error', code: code === 'AI_UNAVAILABLE' ? 'AI_UNAVAILABLE' : 'VALIDATION_FAILED' },
  errorCode: code,
  drafts: [],
  parts: [],
  clarification: null,
  modelCalls: 0,
});

const noticeText: Record<PrepareNotice['code'] | 'READ_DENIED', { vi: string; en: string }> = {
  MODULE_UNAVAILABLE: {
    vi: 'Mục này chưa ghi được qua trò chuyện. Bạn có thể mở mục tương ứng để ghi trực tiếp.',
    en: 'This can’t be saved from chat yet. You can open the matching section to add it directly.',
  },
  WRITE_DENIED: {
    vi: 'Vai trò của bạn chỉ xem được, không ghi được mục này.',
    en: 'Your role can view but not add this.',
  },
  VALIDATION_FAILED: {
    vi: 'Có một phần mình chưa hiểu rõ để tạo bản nháp.',
    en: 'Part of this was not clear enough to prepare a draft.',
  },
  READ_DENIED: {
    vi: 'Vai trò của bạn không xem được nhật ký chăm sóc.',
    en: 'Your role cannot see the care log.',
  },
};

const failureText = {
  vi: 'Chưa xử lý được yêu cầu này. Không tính lượt.',
  en: 'This request could not be completed. No credit was used.',
};

/** Claims [taskId] if it is queued (or its lease expired) and runs it. */
export async function runAssistantTask(
  deps: WorkerDeps,
  taskId: string,
): Promise<{ ran: boolean; fenced: boolean; state: string | null }> {
  const { db, now } = deps;
  const ref = taskRef(db, taskId);
  const leaseMs = deps.leaseMs ?? assistantLeaseMs;
  const claim = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return null;
    const t = storedTask(snap);
    const leaseUntil = toDate(t.lease?.until);
    const takeover = t.state === 'processing' && (!leaseUntil || leaseUntil <= now);
    if (t.state !== 'queued' && !takeover) return null;
    const attempt = (t.attempt ?? 0) + 1;
    const at = Timestamp.fromDate(now);
    if (attempt > maxAttempts) {
      // Gave up: release once, fail; no further dispatch.
      if (t.reservationId && t.usage === 'reserved') {
        await releaseQuota(tx, db, {
          familyId: t.familyId,
          reservationId: t.reservationId,
          holder: taskId,
          reason: 'attempts',
          now,
        });
      }
      const seq = appendEvents(
        tx,
        db,
        taskId,
        t.eventSeq ?? 0,
        [
          { type: 'task_failed', payload: { state: 'failed', errorCode: 'AI_UNAVAILABLE' } },
          { type: 'usage_updated', payload: { usage: 'released', credits: 0 } },
        ],
        now,
      );
      tx.update(ref, {
        state: 'failed',
        errorCode: 'AI_UNAVAILABLE',
        usage: t.usage === 'reserved' ? 'released' : t.usage,
        lease: null,
        version: t.version + 1,
        eventSeq: seq,
        updatedAt: at,
      });
      return null;
    }
    const holder = `${taskId}#${attempt}`;
    const seq = appendEvents(
      tx,
      db,
      taskId,
      t.eventSeq ?? 0,
      [{ type: 'progress', payload: { state: 'processing', round: t.round } }],
      now,
    );
    tx.update(ref, {
      state: 'processing',
      lease: { holder, until: Timestamp.fromMillis(now.getTime() + leaseMs) },
      attempt,
      version: t.version + 1,
      eventSeq: seq,
      updatedAt: at,
    });
    return { t, holder };
  });
  if (!claim) return { ran: false, fenced: false, state: null };

  const work = await process(deps, claim.t);
  return finalize(deps, claim.t, claim.holder, work);
}

async function process(deps: WorkerDeps, t: StoredTask): Promise<WorkResult> {
  const { db, now } = deps;
  const answers = (t.clarifications ?? []).filter((c) => c.answer !== null);
  const text = t.input?.text ?? '';
  const texts = [text, ...answers.map((a) => a.answer?.text ?? '').filter(Boolean)];

  let s: TrustedScope;
  try {
    s = await loadTrustedScope(db, t.ownerUid, t.scope, now, deps.environment);
  } catch {
    return failWith('NOT_MEMBER', 'rejected');
  }
  if (s.familyId !== t.familyId) return failWith('SCOPE_CHANGED', 'rejected');
  if (!assistantFlagOn(s, 'assistant')) return failWith('FEATURE_DISABLED', 'rejected');

  // Health first (brief p.16): no model, free, even when everything else would stop.
  const signs = healthSignalsIn(texts.join('\n'));
  if (signs.length > 0) {
    return {
      outcome: { kind: 'health_route', signs },
      errorCode: null,
      drafts: [],
      parts: [{ type: 'health_support', schemaVersion: 1, signs }],
      clarification: null,
      modelCalls: 0,
    };
  }
  if (!assistantConsentGranted(await consentRef(db, t.ownerUid).get())) {
    return failWith('CONSENT_REQUIRED', 'rejected');
  }
  if (!assistantFlagOn(s, 'assistant_live') || !deps.gateway || !(await aiBudgetLeft(db, now))) {
    return failWith('AI_UNAVAILABLE');
  }
  const gateway = deps.gateway;
  const anchor = t.anchorInstant.toDate();
  const canRead = familyCan(s.member, 'history.read');
  const allowedReads: ReadToolName[] = canRead ? [...readToolNames] : ['usage_snapshot'];

  let raw: unknown;
  try {
    raw = await callWithTimeout(
      (signal) =>
        gateway.extract(
          {
            text,
            locale: t.locale,
            anchor: anchorOf(s.zone, anchor),
            clarifications: answers.map((a) => ({
              field: a.field,
              answer: a.answer?.choiceId ?? a.answer?.text ?? '',
            })),
            allowedIntents: draftKinds,
            allowedReads,
          },
          signal,
        ),
      deps.timeoutMs ?? 60_000,
    );
  } catch (error) {
    if (gateway.name === 'openai') await charge(db, now);
    return {
      ...failWith('AI_UNAVAILABLE'),
      outcome: {
        kind: 'error',
        code:
          error instanceof ModelUnavailable && error.kind === 'timeout'
            ? 'timeout'
            : 'AI_UNAVAILABLE',
      },
      modelCalls: 1,
    };
  }
  if (gateway.name === 'openai') await charge(db, now);
  let modelCalls = 1;
  const parsed = parseExtraction(raw);
  // Unknown tools, intents, fields or part shapes: rejected, never executed, 0 credits (E01).
  if (!parsed.ok) return { ...failWith('VALIDATION_FAILED', 'rejected'), modelCalls };
  const ext = parsed.value;

  // One question at a time, each field asked once, within the round cap (brief p.9).
  const asked = new Set((t.clarifications ?? []).map((c) => c.field));
  const periodAnswer = answers.find((a) => a.field === 'time.ampm')?.answer?.choiceId;
  const period = periodAnswer === 'am' || periodAnswer === 'pm' ? periodAnswer : null;
  let ask: ClarificationField | null = null;
  if (ext.clarification && !asked.has(ext.clarification.field)) ask = ext.clarification.field;
  const timed = ext.intents.some((i) => i.fields.time !== null || i.fields.endTime !== null);
  if (!ask && timed && !period && !asked.has('time.ampm') && needsPeriod(texts)) ask = 'time.ampm';
  if (!ask && ext.intents.length === 0 && ext.reads.length === 0 && !asked.has('intent')) {
    ask = 'intent';
  }
  if (ask) {
    if ((t.round ?? 0) >= assistantTaskLimits.maxClarificationRounds) {
      // Cap reached: manual fallback, never an extra charge.
      return { ...failWith('VALIDATION_FAILED', 'rejected'), modelCalls };
    }
    return {
      outcome: { kind: 'clarification', clarification: clarificationFor(ask, 'pending') },
      errorCode: null,
      drafts: [],
      parts: [],
      clarification: ask,
      modelCalls,
    };
  }

  // Read tools (trusted scope; role checked per module).
  const parts: AssistantPart[] = [];
  const reads: ReadResult[] = [];
  const notices: (PrepareNotice['code'] | 'READ_DENIED')[] = [];
  const seen = new Set<string>();
  for (const r of ext.reads) {
    const key = `${r.tool}:${r.dayOffset}`;
    if (seen.has(key)) continue;
    seen.add(key);
    if (r.tool !== 'usage_snapshot' && !canRead) {
      notices.push('READ_DENIED');
      continue;
    }
    switch (r.tool) {
      case 'care_summary':
        reads.push(await careSummaryTool(db, s, anchor, r.dayOffset, t.locale));
        break;
      case 'sleep_facts':
        reads.push(await sleepFactsTool(db, s, anchor, t.locale));
        break;
      case 'usage_snapshot':
        reads.push(await usageSnapshotTool(db, s, now, t.locale));
        break;
    }
  }
  for (const r of reads) parts.push(...r.parts);
  const facts = reads.flatMap((r) => r.facts);
  if (facts.length > 0) {
    // The model only words engine facts; any number not in the facts → the template.
    let wording = facts.map((f) => f.text).join(' ');
    try {
      const out = parseWording(
        await callWithTimeout(
          (signal) => gateway.word({ locale: t.locale, facts }, signal),
          deps.timeoutMs ?? 60_000,
        ),
      );
      modelCalls += 1;
      if (out.ok && wordingGrounded(out.value, facts)) wording = out.value;
    } catch {
      modelCalls += 1;
    }
    if (gateway.name === 'openai') await charge(db, now);
    parts.push({ type: 'text', schemaVersion: 1, text: wording });
  }

  // Prepare tools: typed drafts, never a write.
  const prepared = prepareDrafts(s, {
    intents: ext.intents,
    texts,
    anchor,
    period,
    lastMilk: ext.intents.some((i) => i.kind === 'bottle')
      ? await lastMilkOf(db, s.babyId, anchor)
      : 'breast_milk',
  });
  for (const d of prepared.drafts) {
    if (d.payload.kind === 'sleep' && d.payload.startedAt && d.payload.endedAt) {
      const span = { start: new Date(d.payload.startedAt), end: new Date(d.payload.endedAt) };
      if (span.end > span.start && (await overlappingSleeps(db, s.babyId, span, null)).length) {
        d.warnings.push('overlap');
      }
    }
  }
  notices.push(...prepared.notices.map((n) => n.code));
  for (const code of [...new Set(notices)]) {
    parts.push({ type: 'text', schemaVersion: 1, text: noticeText[code][t.locale] });
  }

  if (prepared.drafts.length > 0) {
    return {
      outcome: {
        kind: 'drafts',
        items: prepared.drafts.map((d) => d.payload),
        answer: facts.length ? 'read' : null,
      },
      errorCode: null,
      drafts: prepared.drafts,
      parts,
      clarification: null,
      modelCalls,
    };
  }
  if (reads.length > 0) {
    return {
      outcome: { kind: 'answer', parts },
      errorCode: null,
      drafts: [],
      parts,
      clarification: null,
      modelCalls,
    };
  }
  // Nothing useful (only unsupported modules / denied roles): released, explained.
  const code = (notices[0] ?? 'VALIDATION_FAILED') as AssistantError;
  return { ...failWith(code, 'rejected'), parts, modelCalls };
}

async function charge(db: Firestore, now: Date) {
  try {
    await chargeAi(db, now, assistantCallCostVnd);
  } catch {
    // The budget counter never fails a task.
  }
}

async function finalize(
  deps: WorkerDeps,
  claimed: StoredTask,
  holder: string,
  work: WorkResult,
): Promise<{ ran: boolean; fenced: boolean; state: string | null }> {
  const { db, now } = deps;
  const taskId = claimed.id;
  const ref = taskRef(db, taskId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const t = storedTask(snap);
    // Fencing: cancelled, re-claimed or finished meanwhile → this run writes and charges nothing.
    if (t.state !== 'processing' || t.lease?.holder !== holder) {
      return { ran: true, fenced: true, state: t.state };
    }
    const [consent, conversation] = await Promise.all([
      tx.get(consentRef(db, t.ownerUid)),
      tx.get(conversationRef(db, t.conversationId)),
    ]);
    let result = work;
    // M09: consent withdrawn while running → the output is dropped, credits released.
    if (result.outcome.kind !== 'health_route' && !assistantConsentGranted(consent)) {
      result = failWith('CONSENT_REQUIRED', 'rejected');
    }
    // Only allowlisted part types ever reach the app (brief p.11); anything else is rejected.
    if (!result.parts.every((p) => (assistantPartTypes as readonly string[]).includes(p.type))) {
      result = failWith('VALIDATION_FAILED', 'rejected');
    }
    const decision =
      t.reservationId && t.usage === 'reserved' ? usageForOutcome(result.outcome) : 'none';
    if (decision === 'commit') {
      await commitQuota(tx, db, {
        familyId: t.familyId,
        reservationId: t.reservationId!,
        holder: taskId,
        now,
      });
    } else if (decision === 'release') {
      await releaseQuota(tx, db, {
        familyId: t.familyId,
        reservationId: t.reservationId!,
        holder: taskId,
        reason: result.outcome.kind,
        now,
      });
    }
    const at = Timestamp.fromDate(now);
    const state = taskStateForOutcome(result.outcome);
    const usage =
      decision === 'commit'
        ? 'committed'
        : decision === 'release'
          ? 'released'
          : decision === 'hold'
            ? 'reserved'
            : t.usage;

    // Drafts.
    const expiresAt = Timestamp.fromMillis(
      now.getTime() + assistantTaskLimits.draftTtlHours * 3_600_000,
    );
    const draftParts: AssistantPart[] = [];
    result.drafts.forEach((d, i) => {
      const id = draftIdFor(taskId, i);
      const needsReview = d.uncertainFields.length > 0 || d.missingFields.length > 0;
      tx.set(ref.collection('drafts').doc(id), {
        id,
        taskId,
        ownerUid: t.ownerUid,
        itemIndex: i,
        scope: t.scope,
        payload: d.payload,
        missingFields: d.missingFields,
        uncertainFields: d.uncertainFields,
        revision: 1,
        state: needsReview ? 'needs_review' : 'draft',
        expiresAt,
        sourceRefs: [`task:${taskId}`],
        recordId: null,
        recordLink: null,
        errorCode: null,
        warnings: d.warnings,
        createdAt: at,
        updatedAt: at,
      });
      draftParts.push({ type: 'draft_reference', schemaVersion: 1, draftId: id, revision: 1 });
    });

    // The assistant message (typed parts only).
    const round = (t.round ?? 0) + (result.clarification ? 1 : 0);
    let pending = null;
    let parts: AssistantPart[];
    if (result.clarification) {
      pending = clarificationFor(result.clarification, `cl_${round}`);
      parts = [{ type: 'clarification', schemaVersion: 1, clarification: pending }];
    } else if (state === 'failed') {
      parts = [...result.parts, { type: 'text', schemaVersion: 1, text: failureText[t.locale] }];
    } else {
      parts = [...result.parts, ...draftParts];
    }
    const messageSeq = appendMessages(
      tx,
      db,
      t.conversationId,
      (conversation.get('messageSeq') as number | undefined) ?? 0,
      [{ role: 'assistant', parts, taskId }],
      now,
    );
    tx.update(conversation.ref, { messageSeq, updatedAt: at, lastTaskId: taskId });

    // Coalesced events: the result, then usage when it moved.
    const resultEvent: TaskEventType =
      state === 'awaiting_clarification'
        ? 'clarification_required'
        : state === 'failed'
          ? 'task_failed'
          : result.outcome.kind === 'drafts'
            ? 'drafts_ready'
            : 'answer_ready';
    const events: { type: TaskEventType; payload: Record<string, unknown> }[] = [
      {
        type: resultEvent,
        payload: {
          state,
          errorCode: result.errorCode,
          draftIds: result.drafts.map((_, i) => draftIdFor(taskId, i)),
        },
      },
    ];
    if (decision === 'commit' || decision === 'release') {
      events.push({
        type: 'usage_updated',
        payload: { usage, credits: decision === 'commit' ? t.credits : 0 },
      });
    }
    const eventSeq = appendEvents(tx, db, taskId, t.eventSeq ?? 0, events, now);
    tx.update(ref, {
      state,
      errorCode: result.errorCode,
      usage,
      lease: null,
      round,
      version: t.version + 1,
      eventSeq,
      pendingClarification: pending,
      clarificationExpiresAt: pending
        ? Timestamp.fromMillis(now.getTime() + assistantTaskLimits.clarificationTtlMinutes * 60_000)
        : null,
      clarifications: pending
        ? [
            ...(t.clarifications ?? []),
            { id: pending.id, field: pending.field, round, answer: null },
          ]
        : (t.clarifications ?? []),
      draftIds: result.drafts.map((_, i) => draftIdFor(taskId, i)),
      outcome: {
        kind: result.outcome.kind,
        drafts: result.drafts.length,
        parts: parts.map((p) => p.type),
      },
      modelCalls: ((snap.get('modelCalls') as number | undefined) ?? 0) + work.modelCalls,
      model: deps.gateway ? `${deps.gateway.name}:${deps.gateway.model}` : null,
      promptVersion: deps.gateway?.promptVersion ?? null,
      updatedAt: at,
      ...(state === 'ready' ? { readyAt: at } : {}),
    });
    return { ran: true, fenced: false, state };
  });
}

/**
 * Recovery (every few minutes): a worker that died keeps its lease until it ends; then the task
 * is queued again (the trigger re-runs it) up to the attempt cap, after which it fails and its
 * credits are released once. Clarifications left unanswered past their TTL fail the same way
 * ("expired clarification needs a new quote"). Old unused quotes are deleted.
 */
export async function sweepAssistantTasks(
  db: Firestore,
  now: Date,
): Promise<{ requeued: number; expired: number; quotes: number }> {
  let requeued = 0;
  let expired = 0;
  const processing = await db.collection('assistantTasks').where('state', '==', 'processing').get();
  for (const d of processing.docs) {
    const until = toDate(d.get('lease.until'));
    if (until && until > now) continue;
    const moved = await db.runTransaction(async (tx) => {
      const snap = await tx.get(d.ref);
      const t = storedTask(snap);
      const u = toDate(t.lease?.until);
      if (t.state !== 'processing' || (u && u > now)) return false;
      tx.update(d.ref, {
        state: 'queued',
        lease: null,
        version: t.version + 1,
        updatedAt: Timestamp.fromDate(now),
      });
      return true;
    });
    if (moved) requeued += 1;
  }
  const waiting = await db
    .collection('assistantTasks')
    .where('state', '==', 'awaiting_clarification')
    .get();
  for (const d of waiting.docs) {
    const until = toDate(d.get('clarificationExpiresAt'));
    if (!until || until > now) continue;
    if (await expireClarification(db, d.id, now)) expired += 1;
  }
  const oldQuotes = await db
    .collection('assistantQuotes')
    .where('expiresAt', '<', Timestamp.fromMillis(now.getTime() - 86_400_000))
    .limit(400)
    .get();
  if (!oldQuotes.empty) {
    const batch = db.batch();
    for (const q of oldQuotes.docs) batch.delete(q.ref);
    await batch.commit();
  }
  return { requeued, expired, quotes: oldQuotes.size };
}

/** An unanswered clarification past its TTL: release once, fail with QUOTE_EXPIRED. */
export async function expireClarification(
  db: Firestore,
  taskId: string,
  now: Date,
): Promise<boolean> {
  const ref = taskRef(db, taskId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const t = storedTask(snap);
    if (t.state !== 'awaiting_clarification') return false;
    if (t.reservationId && t.usage === 'reserved') {
      await releaseQuota(tx, db, {
        familyId: t.familyId,
        reservationId: t.reservationId,
        holder: taskId,
        reason: 'clarification_expired',
        now,
      });
    }
    const seq = appendEvents(
      tx,
      db,
      taskId,
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
      updatedAt: Timestamp.fromDate(now),
    });
    return true;
  });
}
