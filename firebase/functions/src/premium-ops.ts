import { createHash } from 'node:crypto';
import { Timestamp, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import {
  aiConsentVersion,
  aiReportProblems,
  aiSummaryLimits,
  aiSummaryPromptVersion,
  appEventDims,
  defaultEntitlementsConfig,
  entitlementsConfigSchema,
  familyQuotaSchema,
  flagsSchema,
  technicalFallbackReasons,
  type AiReportProblem,
  type BillingProvider,
  type GrantEnvironment,
  type GrantStatus,
  type KeepsakeJobErrorCode,
  type KeepsakeJobStatus,
  type KeepsakeJobStep,
  type QuotaFeature,
  type RenderLedgerIssue,
  type ReservationState,
  type StaffAiPolicy,
  type StaffFamilyQuota,
  type StaffRenderJob,
  type StaffRenderOps,
  type SummaryFallbackReason,
} from '@child-life/contracts';
import { dayOf } from './analytics.js';
import {
  familyCode,
  familyIdsOf,
  launchedFlags,
  parse,
  readAiBudget,
  requireStaff,
  type Staff,
} from './staff.js';

/**
 * Premium operations on the portal (plan §5.6, brief "Portal cần thêm"): the AI policy in force,
 * video render jobs with their quota reservations, and one family's quota windows and billing
 * records. Read-only: nothing here retries a job, takes or releases a unit, or touches a grant
 * (a retry is the family's own "Thử lại", which takes a new reservation — brief "không cho retry
 * tạo charge/job mới"). Answers carry family codes, short hashes and closed codes only: never a
 * baby name, caption, media path, uid, store transaction id or purchase token.
 */

const DAY_MS = 86_400_000;

const toMs = (v: unknown): number | null =>
  v instanceof Timestamp ? v.toMillis() : v instanceof Date ? v.getTime() : null;
const isoOrNull = (v: unknown): string | null => {
  const m = toMs(v);
  return m === null ? null : new Date(m).toISOString();
};
const iso = (v: unknown): string => isoOrNull(v) ?? new Date(0).toISOString();
const num = (v: unknown): number => (typeof v === 'number' && Number.isFinite(v) ? v : 0);

/** Hex runs of 12+ characters (hashes, job ids) shortened to 8: `ksj_1a2b3c4d…`. */
export const shortHashes = (s: string): string =>
  s.replace(/[0-9a-f]{12,}/g, (h) => `${h.slice(0, 8)}…`);

/** "B-7Q2K"-like code of a baby id, so day windows never show the id itself. */
const B32 = 'ABCDEFGHJKMNPQRSTVWXYZ23456789';
export function babyCode(babyId: string): string {
  const digest = createHash('sha256').update(`baby:${babyId}`).digest();
  return `B-${Array.from(digest.subarray(0, 4), (b) => B32[b % B32.length]).join('')}`;
}

/** "KJ-1A2B": a stable short code of a keepsake job id. */
export const renderJobCode = (jobId: string) =>
  `KJ-${createHash('sha256').update(jobId).digest('hex').slice(0, 4).toUpperCase()}`;

// ---------- AI policy ----------

export interface AiProviderInfo {
  name: 'openai' | 'template';
  model: string | null;
}

const zeroProblems = (): Record<AiReportProblem, number> =>
  Object.fromEntries(aiReportProblems.map((p) => [p, 0])) as Record<AiReportProblem, number>;

/**
 * `staffAiPolicy`: provider and model (no key), consent and prompt versions, the `ai_assist`
 * switch, AI quotas, the monthly budget, 30 days of summary counters and open reports by problem.
 */
export async function aiPolicy(
  db: Firestore,
  staff: Staff | null,
  provider: AiProviderInfo,
  now: Date,
): Promise<StaffAiPolicy> {
  requireStaff(staff, 'premium.view');
  const dayIds = Array.from({ length: 30 }, (_, i) =>
    dayOf(new Date(now.getTime() - (29 - i) * DAY_MS)),
  );
  const [flagsDoc, entDoc, budget, daySnaps, reports] = await Promise.all([
    db.doc('config/flags').get(),
    db.doc('config/entitlements').get(),
    readAiBudget(db, now),
    db.getAll(...dayIds.map((d) => db.doc(`appEventsDaily/${d}`))),
    db.collection('aiReports').where('status', '==', 'open').select('problem').get(),
  ]);
  const flags = flagsSchema.safeParse(flagsDoc.data());
  const flag = flags.success ? flags.data.ai_assist : launchedFlags.ai_assist;
  const ent = entitlementsConfigSchema.safeParse(entDoc.data());
  const ai = (ent.success ? ent.data : defaultEntitlementsConfig).quotas.ai;

  const days = daySnaps.map((d, i) => ({
    day: dayIds[i]!,
    generated: num(d.get('summaryGenerated')),
    ai: num(d.get('summaryGenerated__ai')),
    cache: num(d.get('summaryGenerated__cache')),
    fallback: num(d.get('summaryGenerated__fallback')),
  }));
  const sum = (k: 'generated' | 'ai' | 'cache' | 'fallback') => days.reduce((n, d) => n + d[k], 0);
  const reasons = (appEventDims.summaryFallback ?? []) as readonly SummaryFallbackReason[];
  const fallbackReasons = reasons
    .map((reason) => ({
      reason,
      count: daySnaps.reduce((n, d) => n + num(d.get(`summaryFallback__${reason}`)), 0),
    }))
    .filter((r) => r.count > 0)
    .sort((a, b) => b.count - a.count);
  const generated = sum('generated');
  const technical = fallbackReasons
    .filter((r) => (technicalFallbackReasons as readonly string[]).includes(r.reason))
    .reduce((n, r) => n + r.count, 0);

  const byProblem = zeroProblems();
  for (const r of reports.docs) {
    const p = r.get('problem') as AiReportProblem;
    if (p in byProblem) byProblem[p]++;
  }
  return {
    provider: { name: provider.name, model: provider.name === 'template' ? null : provider.model },
    consentVersion: aiConsentVersion,
    promptVersion: aiSummaryPromptVersion,
    limits: { ...aiSummaryLimits },
    flag: {
      enabled: flag.enabled,
      scope: flag.scope,
      percent: flag.percent,
      families: flag.families?.length ?? 0,
    },
    quotas: { ...ai, stored: ent.success },
    budget,
    days,
    totals: {
      generated,
      ai: sum('ai'),
      cache: sum('cache'),
      fallback: sum('fallback'),
      fallbackRate: generated ? sum('fallback') / generated : null,
      technicalRate: generated ? technical / generated : null,
    },
    fallbackReasons,
    reports: { open: reports.size, byProblem },
  };
}

// ---------- Render operations ----------

/** What the reservation's state should be, given the job's (`null`: nothing to check). */
export function ledgerIssue(
  job: { status: string; memoryId: string | null },
  state: ReservationState | null,
): RenderLedgerIssue | null {
  if (state === null) return 'missing';
  switch (job.status) {
    case 'queued':
    case 'rendering':
      return state === 'reserved' ? null : 'not-held';
    case 'failed':
      return state === 'reserved' ? 'not-released' : null;
    case 'completed':
      // Committed once the video is filed; until then the unit is still held.
      if (job.memoryId) return state === 'committed' ? null : 'not-committed';
      return state === 'released' ? 'not-held' : null;
    default:
      return null;
  }
}

/**
 * `staffRenderOps`: the 100 newest keepsake video jobs across families with the state of their
 * quota reservation and why a failed job failed. Status and codes only: no names, captions,
 * media ids or storage paths.
 */
export async function renderOps(
  db: Firestore,
  staff: Staff | null,
  now: Date,
): Promise<StaffRenderOps> {
  requireStaff(staff, 'jobs.view');
  const snap = await db
    .collectionGroup('keepsakeJobs')
    .orderBy('createdAt', 'desc')
    .limit(100)
    .select(
      'familyId',
      'templateId',
      'templateVersion',
      'status',
      'step',
      'progress',
      'attempts',
      'lease',
      'error',
      'quota',
      'memoryId',
      'createdAt',
      'updatedAt',
      'startedAt',
      'finishedAt',
    )
    .get();
  const quotaOf = (d: DocumentSnapshot) =>
    d.get('quota') as { reservationId?: string; windowId?: string; seq?: number } | undefined;
  const opRefs = snap.docs.map((d) => {
    const q = quotaOf(d);
    const familyId = d.get('familyId') as string | undefined;
    return q?.reservationId && familyId
      ? db.doc(`families/${familyId}/quotaOps/${q.reservationId}`)
      : null;
  });
  const wanted = opRefs.filter((r): r is NonNullable<typeof r> => r !== null);
  const ops = new Map(
    (wanted.length ? await db.getAll(...wanted) : []).map((o) => [o.ref.path, o]),
  );
  const jobs: StaffRenderJob[] = snap.docs.map((d, i) => {
    const q = quotaOf(d);
    const ref = opRefs[i];
    const op = ref ? ops.get(ref.path) : undefined;
    const state = op?.exists ? ((op.get('state') as ReservationState) ?? null) : null;
    const status = d.get('status') as KeepsakeJobStatus;
    const familyId = (d.get('familyId') as string | undefined) ?? null;
    return {
      code: renderJobCode(d.id),
      family: familyId ? familyCode(familyId) : '—',
      templateId: String(d.get('templateId') ?? ''),
      templateVersion: (d.get('templateVersion') as number | undefined) ?? null,
      status,
      step: (d.get('step') as KeepsakeJobStep | null | undefined) ?? null,
      progress: num(d.get('progress')),
      attempts: num(d.get('attempts')),
      lease: num(d.get('lease')),
      error: (d.get('error') as KeepsakeJobErrorCode | null | undefined) ?? null,
      reservation: q?.reservationId
        ? {
            id: shortHashes(q.reservationId),
            window: shortHashes(q.windowId ?? ''),
            seq: num(q.seq),
            state,
            issue: ledgerIssue(
              { status, memoryId: (d.get('memoryId') as string | null | undefined) ?? null },
              state,
            ),
          }
        : null,
      createdAt: iso(d.get('createdAt')),
      updatedAt: iso(d.get('updatedAt')),
      startedAt: isoOrNull(d.get('startedAt')),
      finishedAt: isoOrNull(d.get('finishedAt')),
    };
  });
  const dayAgo = now.getTime() - DAY_MS;
  const recent = (j: StaffRenderJob) => Date.parse(j.finishedAt ?? j.updatedAt) >= dayAgo;
  const failures: StaffRenderOps['failures'] = {};
  for (const j of jobs) {
    if (j.status === 'failed' && j.error) failures[j.error] = (failures[j.error] ?? 0) + 1;
  }
  return {
    kpis: {
      active: jobs.filter((j) => j.status === 'queued' || j.status === 'rendering').length,
      failed24h: jobs.filter((j) => j.status === 'failed' && recent(j)).length,
      completed24h: jobs.filter((j) => j.status === 'completed' && recent(j)).length,
      ledgerIssues: jobs.filter((j) => j.reservation?.issue).length,
    },
    failures,
    jobs,
  };
}

// ---------- One family's quota and billing ----------

/** A window id as staff see it: baby ids as codes, hashes shortened. */
export function windowLabel(windowId: string, babyId: string | null): string {
  const named = babyId ? windowId.split(babyId).join(babyCode(babyId)) : windowId;
  return shortHashes(named);
}

function windowScope(d: DocumentSnapshot): StaffFamilyQuota['windows'][number]['scope'] {
  const scope = d.get('scope') as string | undefined;
  if (scope === 'day' || scope === 'paid' || scope === 'calendar_month') return scope;
  // Video windows (video-quota.ts) store `kind` free | paid instead.
  return d.get('kind') === 'paid' ? 'paid' : 'calendar_month';
}

/**
 * `staffFamilyQuota`: the family's quota windows (open and recent), held reservations, billing
 * accounts and the store events applied to them. Store references, purchase tokens, owner uids
 * and package names stay on the server.
 */
export async function familyQuota(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
): Promise<StaffFamilyQuota> {
  requireStaff(staff, 'premium.view');
  const { code } = parse(familyQuotaSchema, data);
  const familyId = (await familyIdsOf(db, [code]))[0]!;
  const [windowSnap, held, accountSnap] = await Promise.all([
    db.collection(`families/${familyId}/quota`).get(),
    db.collection(`families/${familyId}/quotaOps`).where('state', '==', 'reserved').count().get(),
    db.collection('billingAccounts').where('familyId', '==', familyId).get(),
  ]);
  const since = now.getTime() - 62 * DAY_MS;
  const windows = windowSnap.docs
    .map((d) => {
      const resetsAt = isoOrNull(d.get('resetsAt') ?? d.get('windowEnd'));
      return {
        window: windowLabel(d.id, (d.get('babyId') as string | null | undefined) ?? null),
        feature: d.get('feature') as QuotaFeature,
        scope: windowScope(d),
        limit: num(d.get('limit')),
        used: num(d.get('used')),
        reserved: num(d.get('reserved')),
        startsAt: isoOrNull(d.get('startsAt') ?? d.get('windowStart')),
        resetsAt,
        open: resetsAt === null || Date.parse(resetsAt) > now.getTime(),
      };
    })
    .filter((w) => w.resetsAt === null || Date.parse(w.resetsAt) >= since)
    .sort(
      (a, b) =>
        (b.resetsAt ?? '9').localeCompare(a.resetsAt ?? '9') || a.window.localeCompare(b.window),
    )
    .slice(0, 40);

  const accounts = accountSnap.docs
    .map((d) => ({
      id: shortHashes(d.id),
      provider: d.get('provider') as BillingProvider,
      productId: (d.get('productId') as string | null | undefined) ?? null,
      status: d.get('status') as GrantStatus,
      validUntil: isoOrNull(d.get('expiresAt')),
      environment: d.get('environment') as GrantEnvironment,
      autoRenew: (d.get('autoRenew') as boolean | null | undefined) ?? null,
      boundAt: isoOrNull(d.get('boundAt')),
      fetchedAt: isoOrNull(d.get('fetchedAt')),
    }))
    .sort((a, b) => (b.validUntil ?? '').localeCompare(a.validUntil ?? ''));

  const ids = accountSnap.docs.map((d) => d.id);
  const events: StaffFamilyQuota['events'] = [];
  for (let i = 0; i < ids.length; i += 30) {
    const page = await db
      .collection('billingEvents')
      .where('account', 'in', ids.slice(i, i + 30))
      .select('provider', 'kind', 'outcome', 'receivedAt', 'processedAt')
      .get();
    for (const e of page.docs) {
      events.push({
        provider: e.get('provider') as BillingProvider,
        type: String(e.get('kind') ?? ''),
        outcome: (e.get('outcome') as string | null | undefined) ?? null,
        at: iso(e.get('receivedAt')),
        processedAt: isoOrNull(e.get('processedAt')),
      });
    }
  }
  events.sort((a, b) => b.at.localeCompare(a.at));
  return { code, windows, held: held.data().count, accounts, events: events.slice(0, 20) };
}
