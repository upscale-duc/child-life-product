import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import {
  assistantPartTypes,
  assistantTaskLimits,
  currencyForCountry,
  draftKinds,
  familyCan,
  asksWhatToEat,
  careStatesIn,
  localDateIn,
  // Lumi fixes 2026-10-16.
  asksAboutCare,
  asksAboutCredits,
  asksWhatLumiDoes,
  clientDraftKindsOf,
  feedingConcernIn,
  foldVi,
  mentionsSleep,
  sleepConcernIn,
  smallTalkIn,
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
  draftRef,
  loadTrustedScope,
  seqId,
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
  type ModelExtraction,
  type ModelGateway,
  type ReadToolName,
} from './assistant-model.js';
// Lumi rework 2026-10-15: text planning (expenses, reminders, durations, corrections, questions).
import {
  calendarAround,
  careCueIn,
  checkPurchases,
  householdCurrencyOf,
  planTextIntents,
  previousForModel,
  previousTurnOf,
  spendingCategoriesOf,
  type TextNotice,
} from './assistant-text.js';
import {
  appUpdatePart,
  helpPart,
  noticePart,
  privateConversationId,
  smallTalkPart,
  spendingPrivatePart,
  timerRunningPart,
} from './assistant-talk.js';
// Lumi 2026-10-16: the baby's running timers and the next breastfeed side.
import {
  lastPumpSideOf,
  nextBreastSideOf,
  runningTimersOf,
  timerLinkFor,
} from './assistant-timers.js';
import { appendEvents, appendMessages, storedTask, type StoredTask } from './assistant-store.js';
import {
  anchorOf,
  careSummaryTool,
  clarificationFor,
  healthSignalsIn,
  lastMilkOf,
  localClock,
  overlappingSleeps,
  sleepFactsTool,
  usageSnapshotTool,
  wordingGrounded,
  type PreparedDraft,
  type ReadResult,
} from './assistant-tools.js';
import { commitQuota, releaseQuota } from './quota.js';
// Slice A5 (care, CH15–CH18, CH28).
import {
  blockedPart,
  careAnswer,
  careOf,
  healthSupportPart,
  planCare,
  type CareAnswer,
  type StoredCare,
} from './assistant-care.js';
// Slice A3 (photos): image tasks, the cached reading, retention after settle.
import type { Clarification } from '@child-life/contracts';
import { settleTaskAttachments, type AttachmentStore } from './assistant-attachments.js';
import { processImageTask, writeReadingTx, type StoredReading } from './assistant-images.js';
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
  /**
   * Slice A5, TEST-ONLY fixture input: ingredient ids with a recorded reaction (no meal / reaction
   * module exists yet, P-157). Never set in production (`index.ts` does not pass it).
   */
  careFixtures?: { reactionIngredientIds?: string[] };
  /** Slice A3: the photos' Storage (absent → photo tasks fail MODULE_UNAVAILABLE, released). */
  files?: AttachmentStore;
}

export const assistantLeaseMs = 300_000;
const maxAttempts = 3;
/** A `queued` task untouched this long is nudged by the sweeper (the trigger normally runs in seconds). */
const queuedStuckMs = 10 * 60_000;
const maxQueuedNudges = 3;
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
  /** Slice A5: the care thread to store on the task (facts so far, guidance, recipes). */
  care?: StoredCare | null | undefined;
  /** Slice A3: a server-catalog question of a photo task (id assigned at settle). */
  ask?: Clarification | null;
  /** Slice A3: ready with nothing to save (declined, nothing actionable): credits released. */
  releaseReady?: boolean;
  /** Slice A3: the photo reading cached while a question is open (deleted otherwise). */
  reading?: StoredReading | null;
  // ---- Lumi rework 2026-10-15 ----
  /** The model found money (an expense): a shared task moves to the author's private thread. */
  spending?: boolean;
  /** The text extraction kept while a server question is open (no second model call). */
  textReading?: ModelExtraction | null;
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
  // D-075 #2: spending never stays in the shared thread. A shared task whose words the detector
  // missed but where the model found an expense is moved, with its user messages, to the
  // author's private thread inside the settle transaction, before anything visible is written.
  const done = await finalize(deps, claim.t, claim.holder, work);
  // Slice A3: once settled (or fenced), photos go per their retention (G05); a failure here is
  // retried by the sweeper and never fails the task.
  if (claim.t.modality === 'image') {
    try {
      await settleTaskAttachments(db, deps.files, taskId, now);
    } catch {
      // `sweepAssistantFiles` retries.
    }
  }
  return done;
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
      // Slice A5: with the household's approved emergency number, when the pack has one.
      parts: [await healthSupportPart(db, s, signs)],
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
  // ---- Slice A3 (photos): validate, read once, prepare (assistant-images.ts) ----
  if (t.modality === 'image') {
    const w = await processImageTask(
      { db, now, gateway, files: deps.files, timeoutMs: deps.timeoutMs },
      t,
      s,
    );
    return { ...w, clarification: null };
  }
  // ---- end slice A3 ----
  const canRead = familyCan(s.member, 'history.read');
  // LUMI-14: every read is offered; one the member may not use is answered READ_DENIED (free)
  // by the server, never swapped for the credit balance.
  const allowedReads: ReadToolName[] = [...readToolNames];
  const today = localDateIn(s.zone, anchor);
  const answerMap = new Map(
    answers.map((a) => [
      a.field,
      { choiceId: a.answer?.choiceId ?? null, text: a.answer?.text ?? null },
    ]),
  );
  const routing = t.routing ?? null;
  // Rework 2026-10-15: the household's currency and categories, the calendar and the sender's
  // previous turn (corrections) travel with the request; nothing identifies the family.
  const [currency, categories, previous] = await Promise.all([
    householdCurrencyOf(db, s, currencyForCountry),
    spendingCategoriesOf(db, s.familyId, t.locale),
    previousTurnOf(db, {
      previousTaskId: t.previousTaskId,
      ownerUid: t.ownerUid,
      conversationId: t.conversationId,
      anchor,
    }),
  ]);

  // Rework 2026-10-15: while a server question is open, the first reading is reused (no second
  // model call, no second charge) when every answer is one the server applies itself.
  let ext: ModelExtraction | null = null;
  let modelCalls = 0;
  if ((t.round ?? 0) > 0 && answers.every((a) => serverResolvedField(a.field))) {
    const cached = await textReadingRef(db, t.id).get();
    if (cached.exists) {
      const p = parseExtraction(cached.get('ext'));
      if (p.ok) ext = p.value;
    }
  }
  if (!ext) {
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
              // Timers are the server's (from `phase`), never a kind the model returns.
              allowedIntents: draftKinds.filter((k) => k !== 'timer'),
              allowedReads,
              currency,
              categories,
              calendar: calendarAround(today, t.locale),
              previous: previousForModel(previous, s.zone, today),
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
    modelCalls = 1;
    const parsed = parseExtraction(raw);
    // Unknown tools, intents, fields or part shapes: rejected, never executed, 0 credits (E01).
    if (!parsed.ok) return { ...failWith('VALIDATION_FAILED', 'rejected'), modelCalls };
    ext = parsed.value;
  }
  // Safety net: "con 7 tháng ăn gì được?" with nothing extracted is the meal-ideas care topic
  // (approved recipes only), never a "read or log?" question.
  if (
    !ext.care &&
    ext.intents.length === 0 &&
    ext.reads.length === 0 &&
    !ext.smallTalk &&
    asksWhatToEat(text)
  ) {
    ext = { ...ext, care: { topic: 'meal_ideas', sleep: null, evidence: [] }, clarification: null };
  }
  // ---- Lumi fixes 2026-10-16: the words checked against the reading ----
  // LUMI-12: "Lumi làm được gì?" is what Lumi does (HELP, free), never "read or log?".
  if (asksWhatLumiDoes(text) && ext.intents.length === 0 && ext.reads.length === 0) {
    ext = { ...ext, clarification: null, care: null, outOfScope: true };
  }
  // LUMI-10: a sleep concern ("dạo này bé khó ngủ về đêm") gets care guidance, never an
  // observation draft; its facts come from the words (the server asks what they do not say).
  const concern = sleepConcernIn(text);
  if (concern && !ext.care && ext.reads.length === 0) {
    const rest = ext.intents.filter(
      (i) =>
        !(
          i.kind === 'observation' &&
          (i.fields.observation === 'sleep' || i.fields.observation === 'usual')
        ),
    );
    if (rest.length === 0) {
      ext = {
        ...ext,
        intents: [],
        clarification: null,
        care: {
          topic: 'sleep_concern',
          sleep: { kind: concern.kind, when: concern.when, since: null },
          evidence: [
            ...(concern.kind ? [{ field: 'kind' as const, text }] : []),
            ...(concern.when ? [{ field: 'when' as const, text }] : []),
          ],
        },
      };
    }
  }
  // LUMI-12: a feeding worry ("mấy hôm nay bé biếng ăn") is not a sleep concern.
  if (ext.care?.topic === 'sleep_concern' && !mentionsSleep(text)) {
    ext = { ...ext, care: null };
    if (feedingConcernIn(text) && ext.intents.length === 0) {
      ext = {
        ...ext,
        intents: [
          {
            kind: 'observation',
            fields: {
              amountMl: null,
              milk: null,
              time: null,
              dayOffset: null,
              endTime: null,
              endDayOffset: null,
              durationMin: null,
              side: null,
              observation: 'feeding',
              when: null,
              note: null,
              title: null,
            },
            evidence: [],
            uncertainFields: [],
            missingFields: [],
            correctsPrevious: false,
          },
        ],
      };
    }
  }
  // LUMI-16 (owner 2026-10-16): a purchase made is an expense even without an amount (the card
  // asks "Hết bao nhiêu tiền?"); a plan or a question about buying never is.
  const bought = checkPurchases(text, ext.intents);
  ext = { ...ext, intents: bought.intents };
  let bareLog = false;
  // rd-09: two bare words of a feed or a sleep ("bú sữa", "bé ngủ") with nothing said about it —
  // no amount, time, length or "đang / vừa / rồi" — may be a question about the log: asked once.
  const bareWords = foldVi(text)
    .replace(/[^\p{L}\d\s]/gu, ' ')
    .trim()
    .split(/\s+/);
  if (
    !(t.clarifications ?? []).some((c) => c.field === 'intent') &&
    bareWords.length <= 2 &&
    !/\d/.test(text) &&
    ext.reads.length === 0 &&
    !ext.care &&
    ext.intents.length > 0 &&
    careStatesIn(text).length === 0 &&
    !careCueIn(text) &&
    ext.intents.every(
      (i) =>
        (i.kind === 'bottle' || i.kind === 'breast' || i.kind === 'sleep') &&
        i.fields.amountMl === null &&
        i.fields.time === null &&
        i.fields.endTime === null &&
        i.fields.durationMin === null,
    )
  ) {
    bareLog = true;
  }
  const spending = ext.intents.some((i) => i.kind === 'expense');
  const lead: AssistantPart[] = routing ? [spendingPrivatePart(t.locale)] : [];

  // One question at a time, each field asked once, within the round cap (brief p.9).
  const asked = new Set((t.clarifications ?? []).map((c) => c.field));
  // ---- Slice A5 (care): health signs from the model, kill switch, region, the care question ----
  const care = planCare({
    s,
    stored: careOf(t),
    ext,
    answers: answers.map((a) => ({ field: a.field, choiceId: a.answer?.choiceId ?? null })),
    asked,
    texts,
    round: t.round ?? 0,
  });
  if (care.kind === 'health') {
    return {
      outcome: { kind: 'health_route', signs: care.signs },
      errorCode: null,
      drafts: [],
      parts: [await healthSupportPart(db, s, care.signs)],
      clarification: null,
      modelCalls,
    };
  }
  const careActive = care.kind !== 'none';
  const careState = care.kind === 'ask' || care.kind === 'ready' ? care.care : undefined;
  // ---- end slice A5 ----
  const capped = (t.round ?? 0) >= assistantTaskLimits.maxClarificationRounds;
  const intentAnswer = answerMap.get('intent')?.choiceId ?? null;
  // "Xem nhật ký" answered: today's summary, without asking the model again.
  const reads = [...ext.reads];
  if (intentAnswer === 'read' && reads.length === 0 && canRead) {
    reads.push({ tool: 'care_summary', dayOffset: 0 });
  }
  // "Xem nhật ký" answered: the bare log the model guessed is not drafted too (rd-09).
  if (intentAnswer === 'read') ext = { ...ext, intents: [] };
  // Lumi 2026-10-16: an ongoing state in the words ("con đang ngủ", "bú xong rồi") is something
  // to do even when the model returned nothing (the planner adds its timer item).
  const states = careStatesIn(text);
  // LUMI-01: so is a pump / diaper / growth log in the words the model did not return.
  const nothing =
    ext.intents.length === 0 &&
    reads.length === 0 &&
    !careActive &&
    states.length === 0 &&
    !careCueIn(text);
  // Slice A5: a care question goes first; the care facts (`sleep.*`) are asked by `planCare`.
  let ask: ClarificationField | null = care.kind === 'ask' ? care.field : bareLog ? 'intent' : null;
  if (
    !ask &&
    ext.clarification &&
    !asked.has(ext.clarification.field) &&
    !(careActive && ext.clarification.field.startsWith('sleep.')) &&
    // Rework 2026-10-15: times are the server's questions (with chips), never the model's.
    !ext.clarification.field.startsWith('time.') &&
    // Small talk and out-of-scope messages are answered, never questioned.
    !(
      ext.clarification.field === 'intent' &&
      (!nothing || ext.smallTalk || ext.outOfScope || bought.shopping)
    )
  ) {
    ask = ext.clarification.field;
  }
  if (ask) {
    if (capped) return { ...fallback(t.locale, 'help', lead), modelCalls, care: careState };
    return {
      outcome: { kind: 'clarification', clarification: clarificationFor(ask, 'pending') },
      errorCode: null,
      drafts: [],
      parts: lead,
      clarification: ask,
      modelCalls,
      care: careState,
      textReading: ext,
      spending,
    };
  }
  // Rework 2026-10-15: small talk and messages Lumi cannot help with get a short answer for
  // 0 credits — never a question, never a dead end.
  if (nothing) {
    const talk = ext.smallTalk && !ext.outOfScope && !bought.shopping;
    return {
      ...fallback(
        t.locale,
        talk ? 'talk' : bought.shopping ? 'shopping' : intentAnswer === 'write' ? 'write' : 'help',
        lead,
        smallTalkIn(text) ?? 'ack',
      ),
      modelCalls,
    };
  }

  // Prepare: typed drafts or ONE server question (morning / evening, a missing time, a start
  // for a duration, who does a reminder). Never a write.
  const plan = await planTextIntents(
    {
      db,
      s,
      now,
      anchor,
      locale: t.locale,
      text,
      answerTexts: answers.map((a) => a.answer?.text ?? '').filter(Boolean),
      answers: answerMap,
      asked,
      round: t.round ?? 0,
      lastMilk: ext.intents.some((i) => i.kind === 'bottle')
        ? await lastMilkOf(db, s.babyId, anchor)
        : 'breast_milk',
      currency,
      categories,
      previous,
      // Lumi 2026-10-16: "con đang ngủ" / "dậy rồi" / "đang cho bú" drive the app's timers.
      timers: await runningTimersOf(db, s.babyId),
      nextBreastSide: await nextBreastSideOf(db, s.babyId, anchor),
      // Lumi fixes 2026-10-16: the pump form's remembered side; what the app can show (LUMI-05).
      lastPumpSide: await lastPumpSideOf(db, s.babyId, anchor),
      clientKinds: clientDraftKindsOf(t.clientKinds),
    },
    ext.intents,
  );
  if (plan.kind === 'ask') {
    return {
      outcome: { kind: 'clarification', clarification: plan.clarification },
      errorCode: null,
      drafts: [],
      parts: lead,
      clarification: null,
      ask: plan.clarification,
      modelCalls,
      care: careState,
      textReading: ext,
      spending,
    };
  }
  const prepared = { drafts: plan.drafts };

  // Read tools (trusted scope; role checked per module).
  const parts: AssistantPart[] = [...lead];
  const results: ReadResult[] = [];
  const notices: TextNotice[] = [...plan.notices];
  const readDenied: AssistantPart[] = [];
  const seen = new Set<string>();
  for (const r of reads) {
    const key = `${r.tool}:${r.dayOffset}`;
    if (seen.has(key)) continue;
    seen.add(key);
    // LUMI-14: the credit balance is never the answer to a question about the baby.
    const careQuestion =
      r.tool === 'usage_snapshot' && !asksAboutCredits(text) && asksAboutCare(text);
    if ((r.tool !== 'usage_snapshot' || careQuestion) && !canRead) {
      if (readDenied.length === 0) readDenied.push(noticePart({ code: 'READ_DENIED' }, t.locale));
      continue;
    }
    if (careQuestion) {
      const key2 = `care_summary:${r.dayOffset}`;
      if (!seen.has(key2)) {
        seen.add(key2);
        results.push(await careSummaryTool(db, s, anchor, r.dayOffset, t.locale));
      }
      continue;
    }
    switch (r.tool) {
      case 'care_summary':
        results.push(await careSummaryTool(db, s, anchor, r.dayOffset, t.locale));
        break;
      case 'sleep_facts':
        results.push(await sleepFactsTool(db, s, anchor, t.locale));
        break;
      case 'usage_snapshot':
        results.push(await usageSnapshotTool(db, s, now, t.locale));
        break;
    }
  }
  for (const r of results) parts.push(...r.parts);
  const facts = results.flatMap((r) => r.facts);
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

  for (const d of prepared.drafts) {
    if (d.payload.kind === 'sleep' && d.payload.startedAt && d.payload.endedAt) {
      const span = { start: new Date(d.payload.startedAt), end: new Date(d.payload.endedAt) };
      if (span.end > span.start && (await overlappingSleeps(db, s.babyId, span, null)).length) {
        d.warnings.push('overlap');
      }
    }
  }
  parts.push(...readDenied);
  const said = new Set<string>();
  for (const n of notices) {
    const key = `${n.code}:${n.code === 'WRITE_DENIED' || n.code === 'APP_UPDATE_NEEDED' ? n.kind : ''}:${n.timer?.type ?? ''}`;
    if (said.has(key)) continue;
    said.add(key);
    // LUMI-05: what this app build cannot show, with where to add it directly.
    if (n.code === 'APP_UPDATE_NEEDED') {
      const link =
        n.kind === 'timer' && n.timer
          ? timerLinkFor(s.babyId, n.timer.type)
          : n.kind === 'growth'
            ? '/care/growth'
            : '/care';
      parts.push(appUpdatePart(n.kind, t.locale, link));
      continue;
    }
    if (n.code === 'TIMER_RUNNING' && n.timer) {
      const since = n.timer.since;
      parts.push(
        timerRunningPart(
          n.timer.type,
          {
            clock: localClock(s.zone, since),
            yesterday: localDateIn(s.zone, since) < localDateIn(s.zone, anchor),
          },
          t.locale,
          timerLinkFor(s.babyId, n.timer.type),
        ),
      );
      continue;
    }
    if (n.code === 'TIMER_RUNNING') continue;
    parts.push(noticePart({ ...n, code: n.code }, t.locale));
  }

  // ---- Slice A5 (care): guidance / recipes from published content, never from the model ----
  let careOut: CareAnswer | null = null;
  if (care.kind === 'blocked') {
    parts.unshift(blockedPart(care.code, t.locale));
  } else if (care.kind === 'ready') {
    careOut = await careAnswer({
      db,
      s,
      care: care.care,
      anchor,
      now,
      locale: t.locale,
      canRead,
      reactionIngredientIds: deps.careFixtures?.reactionIngredientIds,
    });
    parts.unshift(...careOut.parts);
    prepared.drafts.push(...careOut.drafts);
  }
  const careResult = careOut?.care ?? careState;
  // ---- end slice A5 ----

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
      care: careResult,
      spending,
    };
  }
  if (results.length > 0 || careOut?.useful) {
    return {
      outcome: { kind: 'answer', parts },
      errorCode: null,
      drafts: [],
      parts,
      clarification: null,
      modelCalls,
      care: careResult,
      spending,
    };
  }
  // Slice A5: a care question with no approved content fits → an honest answer, released.
  if (careOut) {
    return {
      outcome: { kind: 'fallback', parts },
      errorCode: null,
      drafts: [],
      parts,
      clarification: null,
      modelCalls,
      care: careResult,
      spending,
    };
  }
  if (care.kind === 'blocked') {
    return { ...failWith(care.code, 'rejected'), parts, modelCalls, spending };
  }
  // Nothing useful (only unsupported modules / denied roles / a saved previous item): released,
  // explained.
  const first = notices[0]?.code ?? (readDenied.length ? 'READ_DENIED' : null);
  if (!first) return { ...fallback(t.locale, 'help', lead), modelCalls, spending };
  const code: AssistantError =
    first === 'WRITE_DENIED' || first === 'MODULE_UNAVAILABLE' || first === 'READ_DENIED'
      ? first
      : first === 'PREVIOUS_SAVED' ||
          first === 'MEDICINE_NOT_SCHEDULED' ||
          first === 'APP_UPDATE_NEEDED'
        ? 'MODULE_UNAVAILABLE'
        : 'VALIDATION_FAILED';
  if (
    first === 'PREVIOUS_SAVED' ||
    first === 'MEDICINE_NOT_SCHEDULED' ||
    first === 'APP_UPDATE_NEEDED'
  ) {
    // An honest answer, not a failure: ready, released.
    return {
      outcome: { kind: 'fallback', parts },
      errorCode: null,
      drafts: [],
      parts,
      clarification: null,
      modelCalls,
      spending,
    };
  }
  return { ...failWith(code, 'rejected'), parts, modelCalls, spending };
}

/** Rework 2026-10-15: answers the server applies itself (the first reading is reused). */
const serverResolvedField = (field: string) =>
  field === 'time.ampm' ||
  field === 'time.missing' ||
  field === 'time.start' ||
  field === 'intent' ||
  field.startsWith('reminder.assignee.');

/** The text reading kept while a server question is open (never client-readable). */
export const textReadingRef = (db: Firestore, taskId: string) =>
  taskRef(db, taskId).collection('textReading').doc('current');

/** Small talk / help: an answer without a draft, released (0 credits). */
function fallback(
  locale: 'vi' | 'en',
  kind: 'talk' | 'help' | 'write' | 'shopping',
  lead: AssistantPart[],
  talk: Parameters<typeof smallTalkPart>[0] = 'ack',
): WorkResult {
  const part = kind === 'talk' ? smallTalkPart(talk, locale) : helpPart(locale, kind);
  const parts = [...lead, part];
  return {
    outcome: { kind: 'fallback', parts },
    errorCode: null,
    drafts: [],
    parts,
    clarification: null,
    modelCalls: 0,
  };
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
    // ---- Lumi rework 2026-10-15 (every read before the first write) ----
    // D-075 #2: the model found money in a shared task → the task and its user messages move to
    // the author's private thread before anything visible (drafts, reply) is written.
    const move = t.visibility === 'shared' && work.spending === true && t.modality === 'text';
    let target = conversation;
    let moved: FirebaseFirestore.QueryDocumentSnapshot[] = [];
    let sharedLast: string | null = null;
    if (move) {
      const [priv, mine, recent] = await Promise.all([
        tx.get(conversationRef(db, privateConversationId(t.ownerUid, t.scope.babyId))),
        tx.get(conversation.ref.collection('messages').where('taskId', '==', taskId)),
        tx.get(conversation.ref.collection('messages').orderBy('sequence', 'desc').limit(20)),
      ]);
      target = priv;
      moved = [...mine.docs].sort((a, b) => a.get('sequence') - b.get('sequence'));
      sharedLast =
        (recent.docs.find((d) => d.get('taskId') !== taskId)?.get('taskId') as string | null) ??
        null;
    }
    // A correction replaces the previous turn's draft (still unsaved: checked now).
    const replacing = work.drafts.filter((d) => d.replaces);
    const replacedSnaps = await Promise.all(
      replacing.map((d) => tx.get(draftRef(db, d.replaces!.taskId, d.replaces!.draftId))),
    );
    // ---- end rework reads ----
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
      t.reservationId && t.usage === 'reserved'
        ? result.releaseReady // Slice A3: nothing to save → released.
          ? 'release'
          : usageForOutcome(result.outcome)
        : 'none';
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
    const state = result.releaseReady ? 'ready' : taskStateForOutcome(result.outcome);
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
    const round = (t.round ?? 0) + (result.clarification || result.ask ? 1 : 0);
    let pending: Clarification | null = null;
    let parts: AssistantPart[];
    if (result.clarification || result.ask) {
      // Slice A3: a photo question comes prebuilt from its catalog, with context parts first.
      pending = result.ask
        ? { ...result.ask, id: `cl_${round}` }
        : clarificationFor(result.clarification!, `cl_${round}`);
      parts = [
        ...result.parts,
        { type: 'clarification', schemaVersion: 1, clarification: pending },
      ];
    } else if (state === 'failed') {
      // The app draws the failure itself (why, "Thử lại", "Ghi trực tiếp"); no second line
      // here, and no credit wording in the chat (D-081).
      parts = [...result.parts];
    } else {
      parts = [...result.parts, ...draftParts];
    }
    // Slice A3: a photo reading is kept only while its question is open.
    if (t.modality === 'image') {
      writeReadingTx(tx, db, taskId, result.ask ? (result.reading ?? null) : null, now);
    }
    // Rework 2026-10-15: the text reading too (a server question reuses it, no second call).
    if (t.modality === 'text') {
      const cache = textReadingRef(db, taskId);
      if (pending && result.textReading) {
        tx.set(cache, { ext: result.textReading, savedAt: at });
      } else tx.delete(cache);
    }
    // Rework 2026-10-15: corrections set the previous unsaved draft aside (never a saved one).
    replacedSnaps.forEach((d) => {
      const st = d.get('state') as string | undefined;
      if (d.exists && (st === 'draft' || st === 'needs_review' || st === 'failed')) {
        tx.update(d.ref, { state: 'discarded', errorCode: 'REPLACED', updatedAt: at });
      }
    });
    let lastSeq = (target.get('messageSeq') as number | undefined) ?? 0;
    if (move) {
      // D-075 #2: out of the shared thread (its messages deleted there), into the author's own.
      if (!target.exists) {
        tx.set(target.ref, {
          id: target.id,
          ownerUid: t.ownerUid,
          shared: false,
          createdBy: t.ownerUid,
          familyId: t.familyId,
          scope: t.scope,
          title: null,
          locale: t.locale,
          createdAt: at,
          updatedAt: at,
          archivedAt: null,
          messageSeq: 0,
          lastTaskId: null,
        });
      }
      for (const m of moved) {
        lastSeq += 1;
        tx.set(target.ref.collection('messages').doc(seqId(lastSeq)), {
          ...m.data(),
          conversationId: target.id,
          sequence: lastSeq,
        });
        tx.delete(m.ref);
      }
      tx.update(conversation.ref, { lastTaskId: sharedLast });
      if (!parts.some((p) => p.type === 'text' && p.code === 'SPENDING_PRIVATE')) {
        parts = [spendingPrivatePart(t.locale), ...parts];
      }
    }
    const messageSeq = appendMessages(
      tx,
      db,
      target.id,
      lastSeq,
      [{ role: 'assistant', parts, taskId }],
      now,
    );
    if (target.exists || !move) {
      tx.update(target.ref, { messageSeq, updatedAt: at, lastTaskId: taskId });
    } else {
      tx.set(target.ref, { messageSeq, updatedAt: at, lastTaskId: taskId }, { merge: true });
    }

    // Coalesced events: the result, then usage when it moved.
    const resultEvent: TaskEventType =
      state === 'awaiting_clarification'
        ? 'clarification_required'
        : state === 'failed'
          ? 'task_failed'
          : result.outcome.kind === 'drafts' && result.drafts.length > 0
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
      // Slice A5: the care thread (facts so far, guidance or recipes).
      ...(result.care ? { care: result.care } : {}),
      // Rework 2026-10-15 (D-075 #2): moved out of the shared thread because of money.
      ...(move
        ? {
            conversationId: target.id,
            visibility: 'private',
            routing: { reason: 'spending', from: 'shared_thread', at: 'worker' },
          }
        : {}),
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
  // A task left `queued` (its trigger never ran, or gave up retrying) holds its credits: nudge
  // the trigger by bumping the version; after [maxQueuedNudges] nudges, fail it and release once.
  const stuckBefore = now.getTime() - queuedStuckMs;
  const queued = await db.collection('assistantTasks').where('state', '==', 'queued').get();
  for (const d of queued.docs) {
    const at = toDate(d.get('updatedAt'));
    if (!at || at.getTime() > stuckBefore) continue;
    const moved = await db.runTransaction(async (tx) => {
      const snap = await tx.get(d.ref);
      const t = storedTask(snap);
      const u = toDate(snap.get('updatedAt'));
      if (t.state !== 'queued' || !u || u.getTime() > stuckBefore) return false;
      const nudges = (snap.get('queuedNudges') as number | undefined) ?? 0;
      if (nudges < maxQueuedNudges) {
        tx.update(d.ref, {
          queuedNudges: nudges + 1,
          version: t.version + 1,
          updatedAt: Timestamp.fromDate(now),
        });
        return true;
      }
      if (t.reservationId && t.usage === 'reserved') {
        await releaseQuota(tx, db, {
          familyId: t.familyId,
          reservationId: t.reservationId,
          holder: d.id,
          reason: 'never_ran',
          now,
        });
      }
      const seq = appendEvents(
        tx,
        db,
        d.id,
        t.eventSeq ?? 0,
        [
          { type: 'task_failed', payload: { state: 'failed', errorCode: 'AI_UNAVAILABLE' } },
          { type: 'usage_updated', payload: { usage: 'released', credits: 0 } },
        ],
        now,
      );
      tx.update(d.ref, {
        state: 'failed',
        errorCode: 'AI_UNAVAILABLE',
        usage: t.usage === 'reserved' ? 'released' : t.usage,
        version: t.version + 1,
        eventSeq: seq,
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
    // Rework 2026-10-15: the kept text reading goes with the question.
    tx.delete(textReadingRef(db, taskId));
    return true;
  });
}
