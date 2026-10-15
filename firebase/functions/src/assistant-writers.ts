import {
  FieldValue,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
} from 'firebase-admin/firestore';
import {
  careLimits,
  confirmBlocker,
  growthLengthOk,
  growthWeightOk,
  draftProblems,
  localDateIn,
  maxSleepHours,
  type ActionDraft,
  type AssistantDraftView,
  type AssistantError,
  type ConfirmItemResult,
  type DraftPayload,
  type DraftProblem,
} from '@child-life/contracts';
import {
  canonical,
  checkInIdFor,
  draftRef,
  memberOf,
  recordIdForDraft,
  seqId,
  sha,
  taskRef,
  toDate,
  type ScopeMember,
} from './assistant-common.js';
import {
  careDuplicateIn,
  localInstant,
  moduleAllows,
  moduleRegistry,
  overlappingSleeps,
} from './assistant-tools.js';
// Slice A3 (photos): expense / reminder writers, the kept receipt, module problems.
import type { AttachmentStore } from './assistant-attachments.js';
import { allDraftProblems } from './assistant-image-rules.js';
// Lumi timers 2026-10-16: start / end the app's running timers.
import { planTimerWrite } from './assistant-timers.js';
import {
  afterImageConfirm,
  imageRecordLink,
  planImageWrite,
  prepareReceiptCopy,
  zoneDraftProblems,
} from './assistant-writers-images.js';

/**
 * Domain writers (P-156, brief p.7, p.12): a confirmed draft becomes exactly the document the app
 * would write through its form — the same keys, limits and author block the Rules accept
 * (`validNewRecord`, `validCareBody`, `validCareData`, `validNewCheckIn`, `validNewFeedback`) —
 * with `source: 'assistant'` instead of `'app'` and a deterministic id from the draft, so a
 * replayed confirm never writes twice. Admin SDK writes bypass the Rules: the role, membership,
 * scope and flags are re-checked here at confirm time. One item = one transaction: the record,
 * the draft's `saved` state, the execution row and the event commit together or not at all.
 * Care payloads never reach a log.
 */

/** The author block the Rules require: the writer's own membership (D-024). */
export interface AuthorMember {
  displayName: string;
  relation: string;
  relationCustom: string | null;
}

export type CareRecordType = 'bottle' | 'breast' | 'sleep' | 'pump' | 'diaper' | 'growth';

export interface CareRecordInput {
  recordId: string;
  babyId: string;
  uid: string;
  member: AuthorMember;
  type: CareRecordType;
  occurredAt: Date;
  endedAt: Date | null;
  data: Record<string, unknown>;
  clientCreatedAt: Date;
}

/** `babies/{b}/records/{r}` with exactly the Rules' key set (`validNewRecord`). */
export function buildCareRecord<S>(x: CareRecordInput, serverTime: S, source = 'assistant') {
  return {
    id: x.recordId,
    babyId: x.babyId,
    type: x.type,
    occurredAt: x.occurredAt,
    endedAt: x.endedAt,
    data: x.data,
    createdBy: x.uid,
    author: {
      name: x.member.displayName,
      relation: x.member.relation,
      relationCustom: x.member.relationCustom,
    },
    createdAt: serverTime,
    clientCreatedAt: x.clientCreatedAt,
    updatedAt: serverTime,
    updatedBy: x.uid,
    deleted: false,
    deletedAt: null,
    deletedBy: null,
    source,
  };
}

/**
 * The start of a feed / pumping session with a length, as the app's form saves it
 * (`CareRecord.spanStart`, care_models.dart): logged right after it ended, its end would be in the
 * future (the Rules refuse that), so it is taken to have just ended — it started [minutes] before
 * [now]. Otherwise the start stays as given.
 */
export function spanStartLikeApp(start: Date, minutes: number | null, now: Date): Date {
  if (minutes === null) return start;
  const end = start.getTime() + minutes * 60_000;
  return end > now.getTime() ? new Date(now.getTime() - minutes * 60_000) : start;
}

/**
 * Same ranges as the form and the Rules (`careLimits`, `validCareBody`); never fixed silently.
 * Lumi fixes 2026-10-16 (LUMI-01): every record is the document the app's own form writes
 * (`CareRecord.create` + `dataJson`, care_models.dart): a breastfeed or a pumping session with a
 * length ends `durationMin` after it starts; a diaper change is a point; a growth record happens
 * "now" when measured today, else at noon of the measuring day in the baby's zone ([zone]).
 */
export function careRecordFromDraft(
  p: DraftPayload,
  now: Date,
  zone = 'Asia/Ho_Chi_Minh',
):
  | {
      ok: true;
      type: CareRecordType;
      occurredAt: Date;
      endedAt: Date | null;
      data: Record<string, unknown>;
    }
  | { ok: false; problems: DraftProblem[] } {
  const skew = now.getTime() + careLimits.futureSkewMinutes * 60_000;
  const future = (d: Date) => d.getTime() > skew;
  switch (p.kind) {
    case 'bottle': {
      const problems: DraftProblem[] = [];
      const ml = p.amountMl;
      if (ml === null) problems.push('MISSING_AMOUNT');
      else if (
        !Number.isInteger(ml) ||
        ml < careLimits.bottleMl.min ||
        ml > careLimits.bottleMl.max
      )
        problems.push('INVALID_AMOUNT');
      if (p.occurredAt === null) problems.push('MISSING_TIME');
      else if (future(new Date(p.occurredAt))) problems.push('FUTURE_TIME');
      // The module knows breast milk and formula only.
      if (p.milk !== 'breast_milk' && p.milk !== 'formula') problems.push('INVALID_AMOUNT');
      if (problems.length) return { ok: false, problems };
      return {
        ok: true,
        type: 'bottle',
        occurredAt: new Date(p.occurredAt!),
        endedAt: null,
        data: { amountMl: ml, milk: p.milk === 'formula' ? 'formula' : 'breastMilk' },
      };
    }
    case 'breast': {
      const problems: DraftProblem[] = [];
      if (p.occurredAt === null) problems.push('MISSING_TIME');
      else if (future(new Date(p.occurredAt))) problems.push('FUTURE_TIME');
      const d = p.durationMin;
      if (
        d !== null &&
        (!Number.isInteger(d) || d < careLimits.durationMin.min || d > careLimits.durationMin.max)
      )
        problems.push('INVALID_AMOUNT');
      if (problems.length) return { ok: false, problems };
      const start = spanStartLikeApp(new Date(p.occurredAt!), d, now);
      return {
        ok: true,
        type: 'breast',
        occurredAt: start,
        // LUMI-01 (the app's record): a feed with a length ends that many minutes later.
        endedAt: d === null ? null : new Date(start.getTime() + d * 60_000),
        // Lumi 2026-10-16: a side not given is "both", as the app's record (`side ?? both`).
        data: { side: p.side ?? 'both', durationMin: d },
      };
    }
    // ---- Lumi fixes 2026-10-16 (LUMI-01): PumpSheet, DiaperSheet, GrowthScreen ----
    case 'pump': {
      const problems: DraftProblem[] = [];
      const ml = p.amountMl;
      if (ml === null) problems.push('MISSING_AMOUNT');
      else if (!Number.isInteger(ml) || ml < careLimits.pumpMl.min || ml > careLimits.pumpMl.max)
        problems.push('INVALID_AMOUNT');
      const d = p.durationMin;
      if (
        d !== null &&
        (!Number.isInteger(d) || d < careLimits.durationMin.min || d > careLimits.durationMin.max)
      )
        problems.push('INVALID_AMOUNT');
      if (p.occurredAt === null) problems.push('MISSING_TIME');
      else if (future(new Date(p.occurredAt))) problems.push('FUTURE_TIME');
      if (problems.length) return { ok: false, problems };
      const start = spanStartLikeApp(new Date(p.occurredAt!), d, now);
      return {
        ok: true,
        type: 'pump',
        occurredAt: start,
        endedAt: d === null ? null : new Date(start.getTime() + d * 60_000),
        // The form's keys exactly (Rules: side, amountMl, durationMin all present).
        data: { side: p.side ?? 'both', amountMl: ml, durationMin: d },
      };
    }
    case 'diaper': {
      const problems: DraftProblem[] = [];
      if (p.occurredAt === null) problems.push('MISSING_TIME');
      else if (future(new Date(p.occurredAt))) problems.push('FUTURE_TIME');
      // The sheet always has a kind; a draft without one is never saved as a guess.
      if (p.diaper === null) problems.push('INVALID_AMOUNT');
      if (problems.length) return { ok: false, problems };
      return {
        ok: true,
        type: 'diaper',
        occurredAt: new Date(p.occurredAt!),
        endedAt: null,
        data: { kind: p.diaper },
      };
    }
    case 'growth': {
      const problems: DraftProblem[] = [];
      if (p.weightKg === null) problems.push('MISSING_AMOUNT');
      else if (!growthWeightOk(p.weightKg)) problems.push('INVALID_AMOUNT');
      if (p.lengthCm !== null && !growthLengthOk(p.lengthCm)) problems.push('INVALID_AMOUNT');
      if (p.measuredOn === null) problems.push('MISSING_DATE');
      else if (p.measuredOn > localDateIn(zone, now)) problems.push('FUTURE_TIME');
      if (problems.length) return { ok: false, problems: [...new Set(problems)] };
      // One decimal, as the form keeps it ("4,3 kg").
      const one = (n: number) => Math.round(n * 10) / 10;
      const today = localDateIn(zone, now);
      return {
        ok: true,
        type: 'growth',
        occurredAt: p.measuredOn === today ? now : localInstant(zone, p.measuredOn!, '12:00'),
        endedAt: null,
        data: {
          weightKg: one(p.weightKg!),
          lengthCm: p.lengthCm === null ? null : one(p.lengthCm),
          measuredOn: p.measuredOn,
        },
      };
    }
    case 'sleep': {
      if (p.startedAt === null || p.endedAt === null)
        return { ok: false, problems: ['MISSING_TIME'] };
      const start = new Date(p.startedAt);
      const end = new Date(p.endedAt);
      const problems: DraftProblem[] = [];
      if (end <= start || end.getTime() - start.getTime() > maxSleepHours * 3_600_000)
        problems.push('INVALID_TIME');
      if (future(end) || future(start)) problems.push('FUTURE_TIME');
      if (problems.length) return { ok: false, problems };
      return { ok: true, type: 'sleep', occurredAt: start, endedAt: end, data: {} };
    }
    default:
      return { ok: false, problems: [] };
  }
}

/** `babies/{b}/checkins/{ci}` (`validNewCheckIn`): revision 1, the caller as author. */
export function buildCheckIn<S>(
  x: {
    id: string;
    babyId: string;
    uid: string;
    date: string;
    observation: 'sleep' | 'feeding' | 'soothing' | 'new_skill' | 'usual';
    when: 'night' | 'day' | 'both' | null;
    note: string | null;
  },
  serverTime: S,
) {
  return {
    id: x.id,
    babyId: x.babyId,
    date: x.date,
    authorUid: x.uid,
    observation: x.observation,
    when: x.when,
    since: null,
    tried: [],
    healthSigns: [],
    note: x.note,
    revision: 1,
    createdAt: serverTime,
    updatedAt: serverTime,
  };
}

/** `babies/{b}/recFeedback/{fb}` (`validNewFeedback`). */
export function buildRecFeedback<S>(
  x: {
    id: string;
    babyId: string;
    uid: string;
    contentId: string;
    contentVersion: number;
    kind: 'helpful' | 'unsure' | 'not_suitable';
    date: string;
  },
  serverTime: S,
) {
  return {
    id: x.id,
    babyId: x.babyId,
    authorUid: x.uid,
    contentId: x.contentId,
    contentVersion: x.contentVersion,
    kind: x.kind,
    date: x.date,
    note: null,
    createdAt: serverTime,
  };
}

const timerRefOf = (db: Firestore, babyId: string, type: 'sleep' | 'breast') =>
  db.doc(`babies/${babyId}/timers/${type}`);

/** The app routes that open a saved item (built here, never by the model; A4 registers them). */
export const recordLinkFor = (babyId: string, kind: DraftPayload['kind'], id: string) =>
  kind === 'expense' || kind === 'reminder' // Slice A3: the app's own routes.
    ? imageRecordLink(kind, babyId, id)
    : kind === 'observation'
      ? `/rhythm/checkins/${babyId}/${id}`
      : `/care/records/${babyId}/${id}`;

// ---------- Draft documents ----------

/** `assistantTasks/{t}/drafts/{d}` as the app reads it (timestamps as ISO). */
export function draftView(snap: DocumentSnapshot, now: Date, zone?: string): AssistantDraftView {
  const d = snap.data() ?? {};
  const payload = d.payload as DraftPayload;
  const draft: ActionDraft = {
    id: snap.id,
    taskId: d.taskId as string,
    itemIndex: d.itemIndex as number,
    scope: d.scope as ActionDraft['scope'],
    payload,
    missingFields: (d.missingFields as string[] | undefined) ?? [],
    uncertainFields: (d.uncertainFields as string[] | undefined) ?? [],
    revision: d.revision as number,
    state: d.state as ActionDraft['state'],
    expiresAt: toDate(d.expiresAt)?.toISOString() ?? new Date(0).toISOString(),
    sourceRefs: (d.sourceRefs as string[] | undefined) ?? [],
    recordId: (d.recordId as string | null | undefined) ?? null,
    recordLink: (d.recordLink as string | null | undefined) ?? null,
    errorCode: (d.errorCode as string | null | undefined) ?? null,
    warnings: (d.warnings as ActionDraft['warnings'] | undefined) ?? [],
  };
  // Slice A3: plus the module's own problems (VND only, a reminder needs a time).
  return {
    ...draft,
    problems:
      draft.state === 'saved'
        ? []
        : allDraftProblems(
            [
              ...draftProblems(payload, now),
              // LUMI-11: what only the baby's zone can tell (a reminder already past…).
              ...(zone ? zoneDraftProblems(payload, now, zone) : []),
            ],
            payload,
          ),
    // D-075 #2: who saved it (set by `confirmDrafts`).
    confirmedBy: (d.confirmedBy as AssistantDraftView['confirmedBy'] | undefined) ?? null,
  };
}

// ---------- Confirm one item ----------

export interface ConfirmItemInput {
  uid: string;
  taskId: string;
  familyId: string;
  babyId: string;
  zone: string;
  draftId: string;
  revision: number;
  acknowledge: readonly ('duplicate_suspected' | 'overlap')[];
  requestId: string;
  now: Date;
  /** Slice A3: the photos' Storage (the kept receipt copy, the temporary original's deletion). */
  files?: AttachmentStore;
}

const result = (
  x: Pick<ConfirmItemInput, 'draftId' | 'revision'>,
  status: ConfirmItemResult['status'],
  more: Partial<ConfirmItemResult> = {},
): ConfirmItemResult => ({
  draftId: x.draftId,
  status,
  revision: x.revision,
  recordId: null,
  recordLink: null,
  errorCode: null,
  problems: [],
  ...more,
});

/**
 * Saves one selected draft (brief p.12, CH07): per-item, partial success kept. Order of checks:
 * draft state / TTL / revision / review (contracts `confirmBlocker`), module, membership and role
 * for that module, scope (baby still in the task's household and open), the form's validation,
 * then the domain conflict (an overlapping live sleep → `conflict` unless acknowledged; a
 * check-in already written for that day → `conflict`). A saved draft answers with its record
 * (replay, M04/M10) and never rewrites it, even if the record was edited in the form since.
 */
export async function confirmDraftItem(
  db: Firestore,
  x: ConfirmItemInput,
): Promise<ConfirmItemResult> {
  const dRef = draftRef(db, x.taskId, x.draftId);
  const tRef = taskRef(db, x.taskId);
  // Slice A3: a kept receipt is copied before the transaction (Storage is not transactional).
  const receipt = await prepareReceiptCopy(db, x.files, x);
  const out = await db.runTransaction(async (tx): Promise<ConfirmItemResult> => {
    const [task, d] = await Promise.all([tx.get(tRef), tx.get(dRef)]);
    if (!d.exists || d.get('taskId') !== x.taskId) {
      return result(x, 'failed', { errorCode: 'VALIDATION_FAILED' });
    }
    const draft = draftView(d, x.now, x.zone);
    if (draft.state === 'saved') {
      return result(x, 'saved', {
        revision: draft.revision,
        recordId: draft.recordId,
        recordLink: draft.recordLink,
      });
    }
    const blocker = confirmBlocker(draft, x.revision, x.now);
    if (blocker) return result(x, 'failed', { errorCode: blocker, revision: draft.revision });
    const mod = moduleRegistry[draft.payload.kind];
    if (!mod.available || (!mod.action && !mod.can)) {
      return result(x, 'failed', { errorCode: 'MODULE_UNAVAILABLE' });
    }
    const [memberSnap, baby] = await Promise.all([
      tx.get(db.doc(`babies/${x.babyId}/members/${x.uid}`)),
      tx.get(db.doc(`babies/${x.babyId}`)),
    ]);
    const member = memberOf(memberSnap, x.now);
    if (!member) return result(x, 'failed', { errorCode: 'NOT_MEMBER' });
    if (!moduleAllows(draft.payload.kind, member)) {
      return result(x, 'failed', { errorCode: 'WRITE_DENIED' });
    }
    if (!baby.exists || baby.get('familyId') !== x.familyId) {
      return result(x, 'failed', { errorCode: 'SCOPE_CHANGED' });
    }
    if ((baby.get('state') ?? 'active') !== 'active') {
      return result(x, 'failed', { errorCode: 'WRITE_DENIED' });
    }
    const p = draft.payload;
    const formProblems = draftProblems(p, x.now);
    if (formProblems.length) {
      return result(x, 'failed', { errorCode: 'VALIDATION_FAILED', problems: formProblems });
    }

    // Domain target, read before any write.
    let target: FirebaseFirestore.DocumentReference;
    let doc: Record<string, unknown>;
    let conflict: AssistantError | null = null;
    /** Lumi timers: the ended timer, deleted with its record. */
    let remove: FirebaseFirestore.DocumentReference | null = null;
    let linkOverride: string | null = null;
    let recordOverride: string | null = null;
    const warnings = new Set(draft.warnings);
    // ---- Slice A3: Chi tiêu expense / one-off reminder (assistant-writers-images.ts) ----
    if (p.kind === 'expense' || p.kind === 'reminder') {
      const plan = await planImageWrite(
        tx,
        db,
        {
          draftId: x.draftId,
          taskId: x.taskId,
          familyId: x.familyId,
          babyId: x.babyId,
          uid: x.uid,
          zone: x.zone,
          now: x.now,
          member,
          acknowledge: x.acknowledge,
          warnings: draft.warnings,
          receiptPath: receipt?.path ?? null,
          attachmentIds: (task.get('input.attachmentIds') as string[] | undefined) ?? [],
        },
        p,
        FieldValue.serverTimestamp(),
      );
      if (plan.kind === 'fail') {
        return result(x, 'failed', { errorCode: plan.errorCode, problems: plan.problems });
      }
      if (plan.kind === 'adopt') {
        // Written by this draft before (the id is the draft's): saved; never overwritten.
        const recordId = plan.target.id;
        const link = recordLinkFor(plan.target.parent.parent?.id ?? x.babyId, p.kind, recordId);
        tx.update(dRef, {
          state: 'saved',
          recordId,
          recordLink: link,
          errorCode: null,
          updatedAt: Timestamp.fromDate(x.now),
        });
        return result(x, 'saved', { revision: draft.revision, recordId, recordLink: link });
      }
      target = plan.target;
      doc = plan.doc;
      conflict = plan.conflict;
      for (const w of plan.warnings) warnings.add(w);
      // ---- end slice A3 (the observation and care branches below are A2's) ----
    } else if (p.kind === 'timer') {
      // ---- Lumi timers 2026-10-16 (assistant-timers.ts) ----
      const plan = await planTimerWrite(
        tx,
        db,
        { draftId: x.draftId, babyId: x.babyId, uid: x.uid, now: x.now, member },
        p,
      );
      if (plan.kind === 'fail') {
        return result(x, 'failed', { errorCode: plan.errorCode, problems: plan.problems });
      }
      if (plan.kind === 'adopt') {
        tx.update(dRef, {
          state: 'saved',
          recordId: plan.recordId,
          recordLink: plan.link,
          errorCode: null,
          updatedAt: Timestamp.fromDate(x.now),
        });
        return result(x, 'saved', {
          revision: draft.revision,
          recordId: plan.recordId,
          recordLink: plan.link,
        });
      }
      if (plan.kind === 'conflict') {
        conflict = plan.errorCode;
        target = timerRefOf(db, x.babyId, p.timer);
        doc = {};
      } else {
        target = plan.target;
        doc = plan.doc;
        remove = plan.remove;
        linkOverride = plan.link;
        recordOverride = plan.recordId;
      }
    } else if (p.kind === 'observation') {
      const id = checkInIdFor(x.babyId, x.uid, p.date, p.observation);
      target = db.doc(`babies/${x.babyId}/checkins/${id}`);
      if (p.date > localDateIn(x.zone, x.now)) {
        return result(x, 'failed', { errorCode: 'VALIDATION_FAILED', problems: ['FUTURE_TIME'] });
      }
      if ((await tx.get(target)).exists) conflict = 'DOMAIN_CONFLICT';
      doc = buildCheckIn(
        {
          id,
          babyId: x.babyId,
          uid: x.uid,
          date: p.date,
          observation: p.observation,
          when: p.when,
          note: p.note,
        },
        FieldValue.serverTimestamp(),
      );
    } else {
      const care = careRecordFromDraft(p, x.now, x.zone);
      if (!care.ok) {
        return result(x, 'failed', { errorCode: 'VALIDATION_FAILED', problems: care.problems });
      }
      const recordId = recordIdForDraft(x.draftId);
      target = db.doc(`babies/${x.babyId}/records/${recordId}`);
      const existing = await tx.get(target);
      if (existing.exists) {
        // Written by this draft before (the id is the draft's): it is saved; never overwrite.
        const link = recordLinkFor(x.babyId, p.kind, recordId);
        tx.update(dRef, {
          state: 'saved',
          recordId,
          recordLink: link,
          errorCode: null,
          updatedAt: Timestamp.fromDate(x.now),
        });
        return result(x, 'saved', { revision: draft.revision, recordId, recordLink: link });
      }
      // Rework 2026-10-15: a feed very like one already logged ("vừa ghi rồi") is a warning to
      // acknowledge ("Vẫn lưu"), re-checked here; never merged.
      if (
        (p.kind === 'bottle' || p.kind === 'breast' || p.kind === 'pump' || p.kind === 'diaper') &&
        (await careDuplicateIn(db, x.babyId, p, recordId, tx))
      ) {
        warnings.add('duplicate_suspected');
        if (!x.acknowledge.includes('duplicate_suspected')) conflict = 'DUPLICATE_SUSPECTED';
      }
      if (care.type === 'sleep') {
        const others = await overlappingSleeps(
          db,
          x.babyId,
          { start: care.occurredAt, end: care.endedAt! },
          recordId,
          tx,
        );
        if (others.length > 0) {
          warnings.add('overlap');
          if (!x.acknowledge.includes('overlap')) conflict = 'DOMAIN_CONFLICT';
        }
      }
      doc = buildCareRecord(
        {
          recordId,
          babyId: x.babyId,
          uid: x.uid,
          member: member satisfies ScopeMember,
          type: care.type,
          occurredAt: care.occurredAt,
          endedAt: care.endedAt,
          data: care.data,
          clientCreatedAt: x.now,
        },
        FieldValue.serverTimestamp(),
      );
    }

    const at = Timestamp.fromDate(x.now);
    const seq = ((task.get('eventSeq') as number | undefined) ?? 0) + 1;
    const exec = db.doc(`assistantExecutions/${x.draftId}_${draft.revision}`);
    const payloadHash = sha(canonical(p));
    // A timer start's "record" is the one its end will write (`r_<sessionId>`).
    const recordId = recordOverride ?? target.id;
    const link =
      linkOverride ?? recordLinkFor(target.parent.parent?.id ?? x.babyId, p.kind, recordId);
    const event = (type: 'item_saved' | 'item_failed', payload: Record<string, unknown>) =>
      tx.set(tRef.collection('events').doc(seqId(seq)), {
        taskId: x.taskId,
        eventId: `${x.taskId}:${seq}`,
        sequence: seq,
        type,
        emittedAt: at,
        payload,
      });
    if (conflict) {
      tx.update(dRef, {
        state: 'failed',
        errorCode: conflict,
        warnings: [...warnings],
        updatedAt: at,
      });
      tx.set(exec, {
        draftId: x.draftId,
        taskId: x.taskId,
        ownerUid: x.uid,
        revision: draft.revision,
        requestId: x.requestId,
        payloadHash,
        status: 'conflict',
        recordId: null,
        errorCode: conflict,
        createdAt: at,
      });
      event('item_failed', { draftId: x.draftId, status: 'conflict', errorCode: conflict });
      tx.update(tRef, { eventSeq: seq, updatedAt: at });
      return result(x, 'conflict', { revision: draft.revision, errorCode: conflict });
    }
    tx.create(target, doc);
    if (remove) tx.delete(remove);
    tx.update(dRef, {
      state: 'saved',
      recordId,
      recordLink: link,
      errorCode: null,
      warnings: [...warnings],
      savedAt: at,
      savedBy: x.uid,
      updatedAt: at,
    });
    tx.set(exec, {
      draftId: x.draftId,
      taskId: x.taskId,
      ownerUid: x.uid,
      revision: draft.revision,
      requestId: x.requestId,
      payloadHash,
      status: 'saved',
      recordId,
      errorCode: null,
      createdAt: at,
    });
    event('item_saved', { draftId: x.draftId, recordId });
    tx.update(tRef, { eventSeq: seq, updatedAt: at });
    return result(x, 'saved', { revision: draft.revision, recordId, recordLink: link });
  });
  // Slice A3: mark the photos, let the temporary originals go, drop an unused receipt copy.
  if (x.files) await afterImageConfirm(db, x.files, x, out, receipt);
  return out;
}
