import { Timestamp, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import {
  aiSummaryCredits,
  assistantErrors,
  assistantOutcomeKinds,
  assistantPoolPlanOf,
  assistantPoolPlans,
  assistantSwitchKeys,
  assistantUsageDays,
  attachmentRetentions,
  attachmentStates,
  defaultEntitlementsConfig,
  draftKinds,
  draftStates,
  entitlementsConfigSchema,
  staffAssistantTaskSchema,
  taskEventTypes,
  taskModalities,
  taskStates,
  type AssistantError,
  type AssistantOutcomeKind,
  type AssistantPoolPlan,
  type AssistantSwitchKey,
  type ReservationState,
  type StaffAssistantSwitches,
  type StaffAssistantTask,
  type StaffAssistantUsage,
  type TaskModality,
  type TaskState,
  type TaskUsageState,
} from '@child-life/contracts';
import { dayOf } from './analytics.js';
import { imageReadCostVnd } from './assistant-images.js';
import { assistantCallCostVnd } from './assistant-worker.js';
import { babyCode, shortHashes } from './premium-ops.js';
import {
  familyCode,
  parse,
  readAiBudget,
  readFlags,
  requireStaff,
  StaffError,
  type Staff,
} from './staff.js';

/**
 * Portal "Trợ lý AI" (docs/assistant/architecture.md §5, slice A6). Read-only views for staff:
 *
 * - `staffAssistantUsage` (`premium.view`): the household credit pool by budget (Free, Premium,
 *   beta; D-075 #1), credits counted / given back per day, tasks by state, outcome and modality,
 *   error codes, health support and model counters over the last 30 Vietnam days.
 * - `staffAssistantTask` (`premium.view`): one task by id for support — states, codes, counts and
 *   times; never the message, draft payload, clarification answer, health signs or photo.
 * - `staffAssistantSwitches` (`features.view`): the six assistant flags (P-161) and their recent
 *   changes. Switching goes through the existing `staffSetFlag` (role `flags.toggle`, reason,
 *   `staffAudit`), never through a path of its own.
 *
 * Families and babies appear as codes (F-XXXX, B-XXXX); ids with hashes are shortened. No uid,
 * name, text or Storage path leaves this module. Nothing here writes.
 *
 * Cost (no new counters, no background job): one bounded query on `assistantTasks` (createdAt in
 * the period, newest {@link taskCap}, selected fields), one bounded collection-group query on the
 * credit ledger (`quotaOps`, feature `assistant`, reservedAt in the period, newest {@link opCap};
 * composite index `quotaOps (feature, reservedAt desc)`), and a `getAll` of the distinct windows
 * those reservations touched (≤ {@link windowCap}). At most ~11 000 document reads per opening of
 * the Usage tab; `truncated` says when a cap was hit.
 */

const DAY_MS = 86_400_000;
export const taskCap = 5000;
export const opCap = 5000;
export const windowCap = 1000;

const toMs = (v: unknown): number | null =>
  v instanceof Timestamp ? v.toMillis() : v instanceof Date ? v.getTime() : null;
const isoOrNull = (v: unknown): string | null => {
  const m = toMs(v);
  return m === null ? null : new Date(m).toISOString();
};
const iso = (v: unknown): string => isoOrNull(v) ?? new Date(0).toISOString();
const num = (v: unknown): number => (typeof v === 'number' && Number.isFinite(v) ? v : 0);
const oneOf = <T extends string>(list: readonly T[], v: unknown): T | null =>
  typeof v === 'string' && (list as readonly string[]).includes(v) ? (v as T) : null;
/** Catalog field ids, draft field names, warning codes: short identifiers only. */
const ident = (v: unknown): string | null =>
  typeof v === 'string' && /^[A-Za-z0-9_.-]{1,48}$/.test(v) ? v : null;
/** "openai:gpt-4.1-mini" as the worker stores it (provider and model, no key). */
const modelName = (v: unknown): string | null =>
  typeof v === 'string' && /^[A-Za-z0-9_.:-]{1,80}$/.test(v) ? v : null;
const idents = (v: unknown): string[] =>
  Array.isArray(v) ? v.map(ident).filter((x): x is string => x !== null) : [];

/** Nearest-rank percentile of sorted values. */
export function percentile(sorted: number[], p: number): number | null {
  if (!sorted.length) return null;
  return sorted[Math.min(sorted.length - 1, Math.max(0, Math.ceil(p * sorted.length) - 1))]!;
}

const reservationStates: readonly ReservationState[] = ['reserved', 'committed', 'released'];
const usageStates: readonly TaskUsageState[] = ['none', 'reserved', 'committed', 'released'];

// ---------- Usage ----------

export async function assistantUsageOverview(
  db: Firestore,
  staff: Staff | null,
  now: Date,
): Promise<StaffAssistantUsage> {
  requireStaff(staff, 'premium.view');
  const dayIds = Array.from({ length: assistantUsageDays }, (_, i) =>
    dayOf(new Date(now.getTime() - (assistantUsageDays - 1 - i) * DAY_MS)),
  );
  const since = new Date(`${dayIds[0]}T00:00:00+07:00`);
  const [taskSnap, opSnap, budget, entDoc, usageDocs] = await Promise.all([
    db
      .collection('assistantTasks')
      .where('createdAt', '>=', since)
      .orderBy('createdAt', 'desc')
      .limit(taskCap)
      .select(
        'state',
        'modality',
        'errorCode',
        'outcome.kind',
        'health',
        'modelCalls',
        'model',
        'promptVersion',
        'createdAt',
        'readyAt',
      )
      .get(),
    db
      .collectionGroup('quotaOps')
      .where('feature', '==', 'assistant')
      .where('reservedAt', '>=', since)
      .orderBy('reservedAt', 'desc')
      .limit(opCap)
      .select('windowId', 'state', 'units', 'committedAt', 'releasedAt')
      .get(),
    readAiBudget(db, now),
    db.doc('config/entitlements').get(),
    db.getAll(...dayIds.map((d) => db.doc(`aiUsageDaily/${d}`))),
  ]);

  // Credits from the ledger (chat tasks and AI summaries share it, D-075 #1).
  const dayIndex = new Map(dayIds.map((d, i) => [d, i]));
  const daily = dayIds.map((day) => ({ day, committed: 0, released: 0 }));
  const onDay = (v: unknown): number | undefined => {
    const m = toMs(v);
    return m === null ? undefined : dayIndex.get(dayOf(new Date(m)));
  };
  const pool = new Map(
    assistantPoolPlans.map((plan) => [
      plan,
      {
        plan,
        committed: 0,
        released: 0,
        held: 0,
        chat: 0,
        summaries: 0,
        households: new Set<string>(),
        exhausted: new Set<string>(),
      },
    ]),
  );
  const windows = new Map<string, { plan: AssistantPoolPlan; familyId: string }>();
  for (const op of opSnap.docs) {
    const familyId = op.ref.parent.parent?.id;
    const windowId = String(op.get('windowId') ?? '');
    const plan = assistantPoolPlanOf(windowId);
    if (!familyId || !plan) continue;
    const row = pool.get(plan)!;
    const units = op.get('units') === undefined ? 1 : num(op.get('units'));
    const state = oneOf(reservationStates, op.get('state'));
    row.households.add(familyId);
    if (state === 'committed') {
      row.committed += units;
      // Chat reservations are `assistant_<taskId>`; summaries use the summary id (`su_*`).
      if (op.id.startsWith('assistant_')) row.chat += units;
      else row.summaries += units;
      const d = onDay(op.get('committedAt'));
      if (d !== undefined) daily[d]!.committed += units;
    } else if (state === 'released') {
      row.released += units;
      const d = onDay(op.get('releasedAt'));
      if (d !== undefined) daily[d]!.released += units;
    } else if (state === 'reserved') {
      row.held += units;
    }
    if (windows.size < windowCap) {
      windows.set(`families/${familyId}/quota/${windowId}`, { plan, familyId });
    }
  }
  const paths = [...windows.keys()];
  const windowSnaps = paths.length ? await db.getAll(...paths.map((p) => db.doc(p))) : [];
  windowSnaps.forEach((w, i) => {
    if (!w.exists) return;
    const meta = windows.get(paths[i]!)!;
    const resetsAt = toMs(w.get('resetsAt'));
    const limit = num(w.get('limit'));
    const open = resetsAt === null || resetsAt > now.getTime();
    if (open && limit > 0 && num(w.get('used')) + num(w.get('reserved')) >= limit) {
      pool.get(meta.plan)!.exhausted.add(meta.familyId);
    }
  });

  // Tasks.
  const byState: Partial<Record<TaskState, number>> = {};
  const byOutcome: Partial<Record<AssistantOutcomeKind | 'none', number>> = {};
  const byModality: Partial<Record<TaskModality, number>> = {};
  const errors = new Map<AssistantError, number>();
  const models = new Map<
    string,
    { model: string; promptVersion: string | null; tasks: number; calls: number }
  >();
  const bump = <K extends string>(o: Partial<Record<K, number>>, k: K) => {
    o[k] = (o[k] ?? 0) + 1;
  };
  let health = 0;
  let calls = 0;
  let tasksWithCalls = 0;
  let costVnd = 0;
  const latencies: number[] = [];
  for (const t of taskSnap.docs) {
    const state = oneOf(taskStates, t.get('state'));
    if (state) bump(byState, state);
    const modality = oneOf(taskModalities, t.get('modality'));
    if (modality) bump(byModality, modality);
    const outcome = oneOf(assistantOutcomeKinds, t.get('outcome.kind'));
    bump(byOutcome, outcome ?? 'none');
    const signs = t.get('health') as unknown;
    if (outcome === 'health_route' || (Array.isArray(signs) && signs.length > 0)) health++;
    const code = oneOf(assistantErrors, t.get('errorCode'));
    if (code) errors.set(code, (errors.get(code) ?? 0) + 1);
    const n = num(t.get('modelCalls'));
    if (n > 0) {
      calls += n;
      tasksWithCalls++;
      costVnd += n * (modality === 'image' ? imageReadCostVnd : assistantCallCostVnd);
      const model = modelName(t.get('model')) ?? 'unknown';
      const promptVersion = ident(t.get('promptVersion'));
      const key = `${model}|${promptVersion ?? ''}`;
      const m = models.get(key) ?? { model, promptVersion, tasks: 0, calls: 0 };
      m.tasks++;
      m.calls += n;
      models.set(key, m);
      const created = toMs(t.get('createdAt'));
      const ready = toMs(t.get('readyAt'));
      if (created !== null && ready !== null && ready >= created) latencies.push(ready - created);
    }
  }
  latencies.sort((a, b) => a - b);

  const ent = entitlementsConfigSchema.safeParse(entDoc.data());
  const credits = (ent.success ? ent.data : defaultEntitlementsConfig).quotas.assistant;
  const observedModels = new Map<
    string,
    {
      model: string;
      operation: string;
      calls: number;
      knownUsage: number;
      inputTokens: number;
      outputTokens: number;
      ratedCalls: number;
      unratedCalls: number;
      estimatedCostUsdMicros: number;
    }
  >();
  for (const doc of usageDocs) {
    const rows = doc.get('byModel') as Record<string, Record<string, unknown>> | undefined;
    for (const row of Object.values(rows ?? {})) {
      if (typeof row.model !== 'string' || typeof row.operation !== 'string') continue;
      const key = `${row.model}|${row.operation}`;
      const total = observedModels.get(key) ?? {
        model: row.model,
        operation: row.operation,
        calls: 0,
        knownUsage: 0,
        inputTokens: 0,
        outputTokens: 0,
        ratedCalls: 0,
        unratedCalls: 0,
        estimatedCostUsdMicros: 0,
      };
      for (const field of [
        'calls',
        'knownUsage',
        'inputTokens',
        'outputTokens',
        'ratedCalls',
        'unratedCalls',
        'estimatedCostUsdMicros',
      ] as const)
        total[field] += num(row[field]);
      observedModels.set(key, total);
    }
  }
  return {
    since: since.toISOString(),
    truncated: { tasks: taskSnap.size >= taskCap, ops: opSnap.size >= opCap },
    pool: [...pool.values()].map(({ households, exhausted, ...row }) => ({
      ...row,
      households: households.size,
      exhausted: exhausted.size,
    })),
    daily,
    tasks: {
      total: taskSnap.size,
      byState,
      byOutcome,
      byModality,
      health,
      errors: [...errors.entries()]
        .map(([code, count]) => ({ code, count }))
        .sort((a, b) => b.count - a.count || a.code.localeCompare(b.code)),
    },
    model: {
      tokenUsage: {
        byModel: [...observedModels.values()].sort(
          (a, b) => b.calls - a.calls || a.model.localeCompare(b.model),
        ),
        ...usageDocs.reduce(
          (sum, doc) => {
            for (const key of Object.keys(sum) as Array<keyof typeof sum>)
              sum[key] += num(doc.get(key));
            return sum;
          },
          {
            calls: 0,
            knownUsage: 0,
            unknownUsage: 0,
            inputTokens: 0,
            outputTokens: 0,
            cachedInputTokens: 0,
            ratedCalls: 0,
            unratedCalls: 0,
            estimatedCostUsdMicros: 0,
          },
        ),
      },
      calls,
      tasksWithCalls,
      estimatedCostVnd: costVnd,
      byModel: [...models.values()].sort(
        (a, b) =>
          b.calls - a.calls ||
          a.model.localeCompare(b.model) ||
          (a.promptVersion ?? '').localeCompare(b.promptVersion ?? ''),
      ),
      timeToReady: {
        samples: latencies.length,
        p50Ms: percentile(latencies, 0.5),
        p95Ms: percentile(latencies, 0.95),
      },
    },
    budget,
    credits: { ...credits, aiSummaryCredits, stored: ent.success },
  };
}

// ---------- One task ----------

export async function assistantTaskLookup(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
): Promise<StaffAssistantTask> {
  requireStaff(staff, 'premium.view');
  const { taskId } = parse(staffAssistantTaskSchema, data);
  const ref = db.doc(`assistantTasks/${taskId}`);
  const t = await ref.get();
  if (!t.exists) throw new StaffError('not-found', 'no-task');
  const familyId = String(t.get('familyId') ?? '');
  const scope = (t.get('scope') ?? {}) as { type?: string; babyId?: string };
  const reservationId = ident(t.get('reservationId'));
  const windowId = typeof t.get('windowId') === 'string' ? (t.get('windowId') as string) : null;
  const [drafts, events, attachments, op] = await Promise.all([
    ref
      .collection('drafts')
      .select(
        'itemIndex',
        'payload.kind',
        'state',
        'revision',
        'missingFields',
        'uncertainFields',
        'warnings',
        'errorCode',
        'expiresAt',
        'savedAt',
      )
      .get(),
    ref
      .collection('events')
      .orderBy('sequence', 'desc')
      .limit(50)
      .select('sequence', 'type', 'emittedAt')
      .get(),
    db
      .collection('assistantAttachments')
      .where('taskId', '==', taskId)
      .select('state', 'retention', 'rejected', 'deletedAt')
      .get(),
    reservationId && familyId
      ? db.doc(`families/${familyId}/quotaOps/${reservationId}`).get()
      : Promise.resolve(null),
  ]);
  const outcomeKind = oneOf(assistantOutcomeKinds, t.get('outcome.kind'));
  const signs = t.get('health') as unknown;
  const care = t.get('care') as { topic?: unknown } | undefined;
  const lease = t.get('lease') as { until?: unknown } | null | undefined;
  const clarifications = (
    (t.get('clarifications') as Array<Record<string, unknown>> | undefined) ?? []
  ).map((c) => ({
    field: ident(c.field) ?? '—',
    round: num(c.round),
    answered: c.answer !== null && c.answer !== undefined,
  }));
  const opView = (o: DocumentSnapshot | null): StaffAssistantTask['reservation'] => {
    if (!reservationId) return null;
    return {
      id: shortHashes(reservationId),
      window: shortHashes(windowId ?? String(o?.get('windowId') ?? '')),
      units: o?.exists
        ? o.get('units') === undefined
          ? 1
          : num(o.get('units'))
        : num(t.get('credits')),
      state: o?.exists ? oneOf(reservationStates, o.get('state')) : null,
      reservedAt: o?.exists ? isoOrNull(o.get('reservedAt')) : null,
      committedAt: o?.exists ? isoOrNull(o.get('committedAt')) : null,
      releasedAt: o?.exists ? isoOrNull(o.get('releasedAt')) : null,
      releaseReason: o?.exists ? ident(o.get('releaseReason')) : null,
    };
  };
  return {
    taskId,
    family: familyId ? familyCode(familyId) : '—',
    baby: scope.babyId ? babyCode(scope.babyId) : '—',
    scope: scope.type === 'household' ? 'household' : 'child',
    visibility: t.get('visibility') === 'shared' ? 'shared' : 'private',
    state: oneOf(taskStates, t.get('state')) ?? 'received',
    modality: oneOf(taskModalities, t.get('modality')) ?? 'text',
    plan: t.get('plan') === 'premium' ? 'premium' : 'free',
    pool: windowId ? assistantPoolPlanOf(windowId) : null,
    credits: num(t.get('credits')),
    usage: oneOf(usageStates, t.get('usage')) ?? 'none',
    errorCode: oneOf(assistantErrors, t.get('errorCode')),
    outcome: outcomeKind
      ? {
          kind: outcomeKind,
          drafts: num(t.get('outcome.drafts')),
          parts: idents(t.get('outcome.parts')),
        }
      : null,
    health: outcomeKind === 'health_route' || (Array.isArray(signs) && signs.length > 0),
    round: num(t.get('round')),
    clarifications,
    attempt: num(t.get('attempt')),
    modelCalls: num(t.get('modelCalls')),
    model: modelName(t.get('model')),
    promptVersion: ident(t.get('promptVersion')),
    policyVersion:
      typeof t.get('policyVersion') === 'string'
        ? (t.get('policyVersion') as string).slice(0, 40)
        : null,
    careTopic: oneOf(['sleep_concern', 'meal_ideas'] as const, care?.topic),
    createdAt: iso(t.get('createdAt')),
    updatedAt: iso(t.get('updatedAt')),
    readyAt: isoOrNull(t.get('readyAt')),
    clarificationExpiresAt: isoOrNull(t.get('clarificationExpiresAt')),
    leaseUntil: isoOrNull(lease?.until),
    reservation: opView(op),
    drafts: drafts.docs
      .sort((a, b) => num(a.get('itemIndex')) - num(b.get('itemIndex')))
      .map((d) => ({
        id: shortHashes(d.id),
        kind: oneOf(draftKinds, d.get('payload.kind')),
        state: oneOf(draftStates, d.get('state')) ?? 'draft',
        revision: num(d.get('revision')),
        missingFields: idents(d.get('missingFields')),
        uncertainFields: idents(d.get('uncertainFields')),
        warnings: idents(d.get('warnings')),
        errorCode: ident(d.get('errorCode')),
        expiresAt: isoOrNull(d.get('expiresAt')),
        savedAt: isoOrNull(d.get('savedAt')),
      })),
    attachments: attachments.docs.map((a) => ({
      state: oneOf(attachmentStates, a.get('state')) ?? 'uploading',
      retention: oneOf(attachmentRetentions, a.get('retention')),
      rejected: a.get('rejected') === true,
      deleted: a.get('deletedAt') != null,
    })),
    events: events.docs
      .map((e) => ({
        sequence: num(e.get('sequence')),
        type: oneOf(taskEventTypes, e.get('type')),
        at: iso(e.get('emittedAt')),
      }))
      .filter((e): e is StaffAssistantTask['events'][number] => e.type !== null)
      .reverse(),
  };
}

// ---------- Kill switches ----------

/**
 * The six assistant flags as the Features screen stores them (family codes, never ids) and the
 * last changes to them. Toggling is `staffSetFlag` — the same role (`flags.toggle`), reason and
 * audit entry as on the Features screen.
 */
export async function assistantSwitches(
  db: Firestore,
  staff: Staff | null,
): Promise<StaffAssistantSwitches> {
  const all = await readFlags(db, staff);
  const keys = assistantSwitchKeys as readonly string[];
  const log = await db
    .collection('staffAudit')
    .where('category', '==', 'features')
    .orderBy('at', 'desc')
    .limit(100)
    .get();
  const mine = log.docs.filter((a) => keys.includes(a.get('target') as string));
  const lastEdit: StaffAssistantSwitches['lastEdit'] = {};
  for (const a of mine) {
    const key = a.get('target') as AssistantSwitchKey;
    lastEdit[key] ??= { by: a.get('actorName') as string, at: iso(a.get('at')) };
  }
  return {
    flags: Object.fromEntries(
      assistantSwitchKeys.map((k) => [k, all.flags[k]]),
    ) as StaffAssistantSwitches['flags'],
    lastEdit,
    recent: mine.slice(0, 10).map((a) => ({
      action: a.get('action') as string,
      target: a.get('target') as string,
      by: a.get('actorName') as string,
      at: iso(a.get('at')),
      reason: a.get('reason') as string,
      detail: (a.get('detail') as Record<string, unknown> | null | undefined) ?? null,
    })),
  };
}
