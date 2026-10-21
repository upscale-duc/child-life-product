import { createHash } from 'node:crypto';
import {
  analyticsObservationSchema,
  flagsSchema,
  localDateIn,
  ageInUnit,
  isFlagOnForFamily,
  type AnalyticsAgeBand,
  type AnalyticsContext,
  type AnalyticsModule,
  type EngagementKind,
  type EngagementStage,
  type EngagementReasonCode,
} from '@child-life/contracts';
import { FieldValue, Timestamp, type Firestore, type DocumentData } from 'firebase-admin/firestore';
import { AccountError, type AccountCaller } from './account.js';

export const ANALYTICS_ZONE = 'Asia/Ho_Chi_Minh' as const;
export const ANALYTICS_DAY_MS = 86_400_000;
export const analyticsHash = (s: string) => createHash('sha256').update(s).digest('hex');
export const analyticsDate = (at: Date) => localDateIn(ANALYTICS_ZONE, at);
export const analyticsTime = (v: unknown): number =>
  v instanceof Timestamp ? v.toMillis() : v instanceof Date ? v.getTime() : 0;

export interface AnalyticsFact {
  event: string;
  at: Date;
  uid?: string | null;
  babyId?: string | null;
  familyId?: string | null;
  module?: AnalyticsModule;
  platform?: 'ios' | 'android' | 'unknown';
  locale?: 'vi' | 'en' | 'other' | 'unknown';
  context?: AnalyticsContext;
  ageBand?: AnalyticsAgeBand;
  kind?: EngagementKind;
  stage?: EngagementStage;
  opportunity?: string;
  template?: string;
  meaningful?: boolean;
  windowClosesAt?: Date | null;
  reason?: EngagementReasonCode;
}

/** P-122: no config mutation here. Missing flags ship dark, including older config documents. */
export async function analyticsCollectionEnabled(db: Firestore, familyId?: string | null) {
  const config = flagsSchema.safeParse((await db.doc('config/flags').get()).data() ?? {});
  if (!config.success) return false;
  const f = config.data.product_analytics;
  if (!f.enabled) return false;
  if (!familyId) return f.scope === 'all';
  const family = await db.doc(`families/${familyId}`).get();
  return isFlagOnForFamily(
    f,
    familyId,
    parseInt(analyticsHash(familyId).slice(0, 8), 16) % 100,
    family.get('internal') === true,
  );
}

export function analyticsAgeBand(dob: unknown, at: Date, zone: string): AnalyticsAgeBand {
  if (typeof dob !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(dob)) return 'unknown';
  try {
    const today = localDateIn(zone, at);
    if (dob > today) return 'unknown';
    const months = ageInUnit(dob, today, 'month');
    return months < 1
      ? 'under_1m'
      : months < 3
        ? '1_to_3m'
        : months < 6
          ? '3_to_6m'
          : months < 9
            ? '6_to_9m'
            : months < 12
              ? '9_to_12m'
              : '12m_plus';
  } catch {
    return 'unknown';
  }
}

/** Source is Admin Auth metadata, not a client-declared date or an invite-created user doc. */
export async function recordAnalyticsRegistration(
  db: Firestore,
  uid: string,
  registeredAt: Date,
  now: Date,
  source: 'auth_create' | 'auth_metadata' = 'auth_create',
) {
  if (!(await analyticsCollectionEnabled(db))) return;
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`productAnalyticsAccounts/${uid}`);
    const stateRef = db.doc('productAnalyticsState/current');
    const [old, state, fence] = await Promise.all([
      tx.get(ref),
      tx.get(stateRef),
      tx.get(db.doc(`productAnalyticsDeletions/${analyticsHash(`uid:${uid}`)}`)),
    ]);
    if (fence.exists) return;
    if (old.exists) {
      if (source === 'auth_create' && old.get('registrationVerified') !== true)
        tx.update(ref, { registeredAt, registrationVerified: true });
      return;
    }
    tx.create(ref, {
      uid,
      registeredAt,
      registrationVerified: source === 'auth_create',
      recordedAt: now,
      ageBand: 'unknown',
      locale: 'unknown',
      expiresAt: new Date(now.getTime() + 400 * ANALYTICS_DAY_MS),
    });
    if (!state.exists) tx.create(stateRef, { sourceStartAt: now, privacyEpoch: 0 });
  });
}

/** One logical source/stage receipt. No raw source ids, child facts or content in aggregates. */
export async function recordAnalyticsFact(
  db: Firestore,
  key: string,
  fact: AnalyticsFact,
  now: Date,
) {
  if (
    !Number.isFinite(fact.at.getTime()) ||
    fact.at.getTime() > now.getTime() + 300_000 ||
    fact.at.getTime() < now.getTime() - 400 * ANALYTICS_DAY_MS
  )
    return false;
  let familyId = fact.familyId ?? null;
  if (fact.babyId) {
    const baby = await db.doc(`babies/${fact.babyId}`).get();
    if (!baby.exists || baby.get('state') === 'deleting') return false;
    familyId = (baby.get('familyId') as string | undefined) ?? null;
  }
  if (!(await analyticsCollectionEnabled(db, familyId))) return false;
  const data = {
    version: 1,
    event: fact.event,
    day: analyticsDate(fact.at),
    at: fact.at,
    receivedAt: now,
    uid: fact.uid ?? null,
    babyId: fact.babyId ?? null,
    familyId,
    module: fact.module ?? null,
    platform: fact.platform ?? 'unknown',
    locale: fact.locale ?? 'unknown',
    context: fact.context ?? 'unknown',
    ageBand: fact.ageBand ?? 'unknown',
    kind: fact.kind ?? null,
    stage: fact.stage ?? null,
    opportunity: fact.opportunity ? analyticsHash(fact.opportunity) : null,
    template: fact.template && /^[A-Za-z0-9_-]{1,100}$/.test(fact.template) ? fact.template : null,
    meaningful: fact.meaningful === true,
    windowClosesAt: fact.windowClosesAt ?? null,
    reason: fact.reason ?? 'none',
    expiresAt: fact.kind
      ? new Date((fact.windowClosesAt ?? fact.at).getTime() + 30 * ANALYTICS_DAY_MS)
      : new Date(now.getTime() + 400 * ANALYTICS_DAY_MS),
  };
  return db.runTransaction(async (tx) => {
    const ref = db.doc(`productAnalyticsFacts/${analyticsHash(key)}`);
    const stateRef = db.doc('productAnalyticsState/current');
    const [old, state] = await Promise.all([tx.get(ref), tx.get(stateRef)]);
    // Deletion fences stop an in-flight writer from resurrecting a removed identity.
    const fences = await Promise.all([
      ...(fact.uid
        ? [tx.get(db.doc(`productAnalyticsDeletions/${analyticsHash(`uid:${fact.uid}`)}`))]
        : []),
      ...(fact.babyId
        ? [tx.get(db.doc(`productAnalyticsDeletions/${analyticsHash(`babyId:${fact.babyId}`)}`))]
        : []),
    ]);
    if (old.exists || fences.some((f) => f.exists)) return false;
    tx.create(ref, data);
    if (!state.exists) tx.create(stateRef, { sourceStartAt: now, privacyEpoch: 0 });
    return true;
  });
}

/** Trigger bridge for the existing foreground heartbeat: no second client heartbeat or SDK. */
export async function recordAnalyticsHeartbeat(
  db: Firestore,
  uid: string,
  before: DocumentData | undefined,
  after: DocumentData | undefined,
  now: Date,
) {
  const at = analyticsTime(after?.lastActiveAt);
  if (!at || at === analyticsTime(before?.lastActiveAt) || after?.signedOutAt) return;
  const platform =
    after?.platform === 'ios' || after?.platform === 'android' ? after.platform : 'unknown';
  const locale = after?.language === 'vi' || after?.language === 'en' ? after.language : 'unknown';
  await recordAnalyticsFact(
    db,
    `foreground:${uid}:${analyticsDate(new Date(at))}:${platform}:${locale}`,
    {
      event: 'app_foreground_observed',
      uid,
      at: new Date(at),
      platform,
      locale,
    },
    now,
  );
}

/** Safe operational intake; local photos themselves and PhotoKit ids are never accepted. */
export async function recordAnalyticsObservation(
  db: Firestore,
  caller: AccountCaller,
  data: unknown,
  now: Date,
) {
  const parsed = analyticsObservationSchema.safeParse(data);
  if (!parsed.success) throw new AccountError('invalid-argument', 'malformed');
  const r = parsed.data;
  if (r.ownerUid !== caller.uid) throw new AccountError('permission-denied', 'stale-owner');
  const at = new Date(r.occurredAt);
  if (at.getTime() > now.getTime() + 300_000 || at.getTime() < now.getTime() - 3 * ANALYTICS_DAY_MS)
    throw new AccountError('invalid-argument', 'stale-observation');
  if (caller.anonymous) return { recorded: false };
  let familyId: string | null = null;
  let band: AnalyticsAgeBand = 'unknown';
  let creator = false;
  if (r.event !== 'app_foreground_observed' && !r.babyId)
    throw new AccountError('invalid-argument', 'malformed');
  if (r.babyId) {
    const [baby, member, profile] = await Promise.all([
      db.doc(`babies/${r.babyId}`).get(),
      db.doc(`babies/${r.babyId}/members/${caller.uid}`).get(),
      db.doc(`babies/${r.babyId}/restricted/profile`).get(),
    ]);
    if (
      !baby.exists ||
      baby.get('state') === 'deleting' ||
      member.get('status') !== 'active' ||
      (analyticsTime(member.get('accessUntilAt')) > 0 &&
        analyticsTime(member.get('accessUntilAt')) <= now.getTime())
    )
      throw new AccountError('permission-denied', 'not-a-member');
    if (
      [
        'photo_review_opened',
        'memory_story_started',
        'memory_story_share_sheet_opened',
        'memory_story_share_result',
      ].includes(r.event) &&
      member.get('role') !== 'coParent'
    )
      throw new AccountError('permission-denied', 'role');
    familyId = (baby.get('familyId') as string | undefined) ?? null;
    creator = member.get('role') === 'coParent';
    band = analyticsAgeBand(
      profile.get('dateOfBirth'),
      at,
      (baby.get('timeZone.zone') as string) ?? ANALYTICS_ZONE,
    );
    // Native shares must point to the caller's actual, filed job, not a guessed global id.
    if (r.event.startsWith('memory_story_share')) {
      if (!r.sourceId) throw new AccountError('invalid-argument', 'malformed');
      const job = await db.doc(`babies/${r.babyId}/keepsakeJobs/${r.sourceId}`).get();
      if (job.get('uid') !== caller.uid || !job.get('memoryId'))
        throw new AccountError('permission-denied', 'role');
    }
    if (r.event === 'family_content_viewed') {
      if (!r.sourceId) throw new AccountError('invalid-argument', 'malformed');
      const media = await db.doc(`babies/${r.babyId}/media/${r.sourceId}`).get();
      if (
        !media.exists ||
        media.get('status') !== 'ready' ||
        media.get('deleted') === true ||
        (member.get('role') !== 'coParent' &&
          !(
            member.get('role') === 'relative' &&
            media.get('effectiveAudience') === 'family' &&
            media.get('deleted') === false
          ))
      )
        throw new AccountError('permission-denied', 'not-a-member');
      if (media.get('createdBy') === caller.uid) return { recorded: false };
    }
    if (r.event === 'lumi_answer_viewed') {
      if (!r.sourceId) throw new AccountError('invalid-argument', 'malformed');
      const task = await db.doc(`assistantTasks/${r.sourceId}`).get();
      if (
        task.get('ownerUid') !== caller.uid ||
        (task.get('scope.babyId') ?? task.get('babyId')) !== r.babyId ||
        task.get('state') !== 'ready'
      )
        throw new AccountError('permission-denied', 'role');
    }
  }
  if (!(await analyticsCollectionEnabled(db, familyId))) return { recorded: false };
  const accountRef = db.doc(`productAnalyticsAccounts/${caller.uid}`);
  const account = await accountRef.get();
  if (account.exists && r.event === 'family_context_viewed' && !account.get('primaryContextAt')) {
    await db.runTransaction(async (tx) => {
      const p = await tx.get(accountRef);
      if (!p.exists || p.get('primaryContextAt')) return;
      tx.update(accountRef, {
        primaryContextAt: now,
        primaryBabyId: r.babyId,
        ageBand: band,
        creator,
        locale: r.locale,
      });
    });
  }
  const dayKey = `${caller.uid}:${analyticsDate(at)}:${r.platform}:${r.locale}`;
  const key =
    r.event === 'app_foreground_observed'
      ? `foreground:${dayKey}`
      : r.event === 'family_context_viewed'
        ? `context:${dayKey}:${r.babyId}`
        : `client:${caller.uid}:${r.receiptId}`;
  const module: AnalyticsModule = r.event.startsWith('lumi_')
    ? 'lumi'
    : r.event === 'family_content_viewed'
      ? 'family'
      : 'remember';
  const recorded = await recordAnalyticsFact(
    db,
    key,
    {
      event:
        r.event === 'memory_story_share_result'
          ? `memory_story_share_${r.result ?? 'unknown'}`
          : r.event,
      uid: caller.uid,
      babyId: r.babyId ?? null,
      familyId,
      at,
      platform: r.platform,
      locale: r.locale,
      ageBand: band,
      ...(['app_foreground_observed', 'family_context_viewed'].includes(r.event) ? {} : { module }),
    },
    now,
  );
  return { recorded };
}

/** Server-only domain completion. Source transitions already have stable logical ids (MET-01). */
export async function recordAnalyticsDomain(
  db: Firestore,
  babyId: string,
  sourceId: string,
  event: string,
  data: DocumentData,
  now: Date,
  options: { meaningful?: boolean; module?: AnalyticsModule } = {},
) {
  const candidateUid =
    event === 'story_saved'
      ? typeof data.savedBy === 'string'
        ? data.savedBy
        : null
      : typeof data.createdBy === 'string' && data.createdBy !== 'ai'
        ? data.createdBy
        : typeof data.uid === 'string'
          ? data.uid
          : typeof data.savedBy === 'string'
            ? data.savedBy
            : null;
  const uid =
    typeof candidateUid === 'string' &&
    candidateUid.length > 0 &&
    !candidateUid.includes('/') &&
    data.authorDeleted !== true
      ? candidateUid
      : null;
  const profile = uid ? await db.doc(`productAnalyticsAccounts/${uid}`).get() : null;
  const at = new Date(
    analyticsTime(data.readyAt ?? data.savedAt ?? data.finishedAt ?? data.createdAt) ||
      now.getTime(),
  );
  return recordAnalyticsFact(
    db,
    `domain:${babyId}:${sourceId}:${event}`,
    {
      event,
      uid: data.authorDeleted === true ? null : uid,
      babyId,
      at,
      module: options.module ?? 'remember',
      meaningful: options.meaningful ?? false,
      ageBand: (profile?.get('ageBand') as AnalyticsAgeBand) ?? 'unknown',
      locale: data.locale === 'en' || data.locale === 'vi' ? data.locale : 'unknown',
      context:
        data.occasionDate &&
        Date.parse(`${String(data.occasionDate)}T00:00:00Z`) + 15 * ANALYTICS_DAY_MS < now.getTime()
          ? 'retrospective'
          : data.occasionDate
            ? 'current'
            : 'unknown',
      template: data.input?.template?.id ?? data.generated?.templateId,
    },
    now,
  );
}

/** Foundation sink for the ENG coordinator; intentionally never a client-accepted event. */
export async function recordEngagementAnalytics(
  db: Firestore,
  input: {
    recipient: string;
    babyId: string;
    opportunity: string;
    kind: EngagementKind;
    stage: EngagementStage;
    context: AnalyticsContext;
    at: Date;
    windowClosesAt?: Date;
    reason?: EngagementReasonCode;
  },
  now: Date,
) {
  if (
    input.stage === 'eligible' &&
    (!input.windowClosesAt ||
      input.windowClosesAt <= input.at ||
      input.windowClosesAt.getTime() > input.at.getTime() + 30 * ANALYTICS_DAY_MS)
  )
    return false;
  if (
    input.context === 'retrospective' &&
    ['scheduled', 'attempted', 'accepted'].includes(input.stage)
  )
    return false;
  return recordAnalyticsFact(
    db,
    `eng:${input.recipient}:${input.opportunity}:${input.stage}`,
    {
      uid: input.recipient,
      babyId: input.babyId,
      opportunity: `${input.recipient}:${input.opportunity}`,
      kind: input.kind,
      stage: input.stage,
      context: input.context,
      at: input.at,
      event:
        input.stage === 'failed'
          ? 'engagement_dispatch_failed'
          : input.stage === 'accepted'
            ? 'engagement_provider_accepted'
            : input.stage === 'attempted'
              ? 'engagement_dispatch_attempted'
              : input.stage === 'unknown'
                ? 'engagement_dispatch_unknown'
                : `engagement_${input.stage}`,
      module: 'engagement',
      windowClosesAt: input.windowClosesAt ?? null,
      reason: input.reason ?? 'none',
    },
    now,
  );
}

export async function purgeProductAnalytics(
  db: Firestore,
  field: 'uid' | 'babyId',
  value: string,
  now: Date,
) {
  const existing = await db
    .collection('productAnalyticsFacts')
    .where(field, '==', value)
    .limit(1)
    .get();
  const profile = field === 'uid' ? await db.doc(`productAnalyticsAccounts/${value}`).get() : null;
  if (existing.empty && !profile?.exists && !(await analyticsCollectionEnabled(db))) return;
  // A purge is resumable. While any purge is active no query can publish or serve a snapshot.
  const fenceRef = db.doc(`productAnalyticsDeletions/${analyticsHash(`${field}:${value}`)}`);
  const proceed = await db.runTransaction(async (tx) => {
    const old = await tx.get(fenceRef);
    if (old.get('state') === 'done') return false;
    tx.set(fenceRef, { at: now, state: 'purging' });
    tx.set(
      db.doc('productAnalyticsState/current'),
      {
        privacyEpoch: FieldValue.increment(1),
        ...(old.get('state') === 'purging' ? {} : { purgesActive: FieldValue.increment(1) }),
      },
      { merge: true },
    );
    return true;
  });
  if (!proceed) return;
  for (;;) {
    const rows = await db
      .collection('productAnalyticsFacts')
      .where(field, '==', value)
      .limit(300)
      .get();
    if (rows.empty) break;
    const batch = db.batch();
    rows.docs.forEach((r) => batch.delete(r.ref));
    await batch.commit();
  }
  if (field === 'uid') await db.doc(`productAnalyticsAccounts/${value}`).delete();
  else {
    const accounts = await db
      .collection('productAnalyticsAccounts')
      .where('primaryBabyId', '==', value)
      .get();
    for (const p of accounts.docs)
      await p.ref.update({ primaryBabyId: FieldValue.delete(), ageBand: 'unknown' });
  }
  await db.runTransaction(async (tx) => {
    const fence = await tx.get(fenceRef);
    if (fence.get('state') !== 'purging') return;
    tx.set(
      fenceRef,
      { state: 'done', expiresAt: new Date(now.getTime() + 401 * ANALYTICS_DAY_MS) },
      { merge: true },
    );
    tx.set(
      db.doc('productAnalyticsState/current'),
      {
        privacyEpoch: FieldValue.increment(1),
        purgesActive: FieldValue.increment(-1),
      },
      { merge: true },
    );
  });
}

export async function cleanupProductAnalytics(db: Firestore, now: Date) {
  for (const name of [
    'productAnalyticsFacts',
    'productAnalyticsAccounts',
    'productAnalyticsQueries',
    'productAnalyticsQueryBudgets',
    'productAnalyticsDeletions',
  ]) {
    for (let page = 0; page < 10; page++) {
      const rows = await db.collection(name).where('expiresAt', '<=', now).limit(300).get();
      if (rows.empty) break;
      const batch = db.batch();
      rows.docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();
    }
  }
}
