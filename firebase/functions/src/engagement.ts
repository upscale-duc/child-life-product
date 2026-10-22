import { createHash } from 'node:crypto';
import {
  FieldValue,
  type Firestore,
  type DocumentData,
  type QueryDocumentSnapshot,
} from 'firebase-admin/firestore';
import {
  flagsSchema,
  isFlagOnForFamily,
  engagementPolicySchema,
  engagementPreferencesSchema,
  engagementRefreshSchema,
  engagementBackgroundAccessSchema,
  engagementActionSchema,
  engagementSettingsSchema,
  decideEngagement,
  engagementPriority,
  notificationSettingsOf,
  type EngagementKind,
  type EngagementPreferences,
  type AnalyticsContext,
  type EngagementStage,
  type EngagementReasonCode,
} from '@child-life/contracts';
import { AccountError } from './account.js';
import { familyBucket } from './features.js';
import { recordEngagementAnalytics, analyticsTime } from './product-analytics-store.js';
import { notifyUsers } from './notifications.js';
import { noteEngagementAction } from './notification-ledger.js';
import type { PushSender } from './social.js';
import {
  discoverEngagementSources,
  validateEngagementSource,
  weeklySource,
} from './engagement-sources.js';

export const ENG_DAY = 86400_000;
export const engHash = (s: string) => createHash('sha256').update(s).digest('hex');
export interface EngagementIntent {
  id: string;
  uid: string;
  babyId: string;
  familyId: string;
  kind: EngagementKind;
  source: string;
  context: AnalyticsContext;
  zone: string;
  eligibleAt: number;
  dueAt: number;
  expiresAt: number;
  windowClosesAt: number;
  priority: number;
  status: string;
  reason: EngagementReasonCode;
  sourceData: Record<string, unknown>;
  sentAt: number | null;
  snoozedUntil: number;
  dismissed: boolean;
  completedAt: number | null;
  deviceId?: string;
}
export const kindFlag = {
  'ENG-01': 'engagementPendingEnabled',
  'ENG-02': 'engagementMilestoneEnabled',
  'ENG-03': 'engagementWeeklyEnabled',
  'ENG-04': 'engagementEnabled',
  'ENG-05': 'engagementFamilyEnabled',
  'ENG-06': 'engagementLumiEnabled',
} as const;
export async function engagementConfig(db: Firestore, familyId: string) {
  const [doc, policyDoc, family] = await Promise.all([
    db.doc('config/flags').get(),
    db.doc('config/engagement').get(),
    db.doc(`families/${familyId}`).get(),
  ]);
  const flags = flagsSchema.parse(doc.data() ?? {}),
    parsed = engagementPolicySchema.safeParse(policyDoc.data() ?? {});
  const policy = parsed.success ? parsed.data : engagementPolicySchema.parse({});
  const on = (key: keyof typeof flags) =>
    policy.approved &&
    isFlagOnForFamily(
      flags[key],
      familyId,
      familyBucket(familyId),
      family.get('internal') === true,
    );
  const effectivePolicy = on('engagementFatigueEnabled')
    ? policy
    : { ...policy, reducedDismissals: 2, pausedDismissals: 3, ignoredThreshold: 3 };
  return {
    policy: effectivePolicy,
    on,
    enabled: on('engagementEnabled') && on('product_analytics'),
  };
}

/** Existing Care/family delivery wins spacing without reviving a deleted account's state. */
export async function engagementTransactionObserved(
  db: Firestore,
  uid: string,
  babyId: string,
  now: Date,
) {
  await db.runTransaction(async (tx) => {
    const [fence, babyFence, member, baby] = await Promise.all([
      tx.get(db.doc(`engagementFences/${engHash(`uid:${uid}`)}`)),
      tx.get(db.doc(`engagementFences/${engHash(`babyId:${babyId}`)}`)),
      tx.get(db.doc(`babies/${babyId}/members/${uid}`)),
      tx.get(db.doc(`babies/${babyId}`)),
    ]);
    const until = analyticsTime(member.get('accessUntilAt'));
    if (
      fence.exists ||
      babyFence.exists ||
      member.get('status') !== 'active' ||
      !baby.exists ||
      baby.get('state') === 'deleting' ||
      (until > 0 && until <= now.getTime())
    )
      return;
    tx.set(
      db.doc(`users/${uid}/settings/engagementState`),
      { transactionAt: now.getTime() },
      { merge: true },
    );
  });
}
export async function engagementScope(db: Firestore, uid: string, babyId: string, now: Date) {
  const [baby, member] = await Promise.all([
    db.doc(`babies/${babyId}`).get(),
    db.doc(`babies/${babyId}/members/${uid}`).get(),
  ]);
  const until = analyticsTime(member.get('accessUntilAt'));
  if (
    !baby.exists ||
    baby.get('state') === 'deleting' ||
    member.get('status') !== 'active' ||
    (until > 0 && until <= now.getTime())
  )
    throw new AccountError('permission-denied', 'not-a-member');
  return {
    familyId: String(baby.get('familyId')),
    zone: String(baby.get('timeZone.zone') ?? 'Asia/Ho_Chi_Minh'),
    role: String(member.get('role')),
    accessUntil: until || null,
  };
}
export async function engStage(
  db: Firestore,
  i: EngagementIntent,
  stage: EngagementStage,
  now: Date,
  reason: EngagementReasonCode = 'none',
) {
  // P-174: the notification ledger's action dimension follows the intent's outcome.
  if (['opened', 'completed', 'expired', 'cancelled', 'dismissed'].includes(stage))
    await noteEngagementAction(db, i.id, stage, now).catch(() => undefined);
  await recordEngagementAnalytics(
    db,
    {
      recipient: i.uid,
      babyId: i.babyId,
      opportunity: i.id,
      kind: i.kind,
      context: i.context,
      stage,
      at:
        stage === 'eligible'
          ? new Date(i.eligibleAt)
          : stage === 'completed' && i.completedAt
            ? new Date(i.completedAt)
            : now,
      windowClosesAt: new Date(i.windowClosesAt),
      reason,
    },
    now,
  );
}
export async function upsertEngagement(
  db: Firestore,
  input: Omit<
    EngagementIntent,
    | 'id'
    | 'status'
    | 'reason'
    | 'sentAt'
    | 'snoozedUntil'
    | 'dismissed'
    | 'completedAt'
    | 'priority'
  >,
  now: Date,
) {
  const id = engHash(`${input.uid}:${input.babyId}:${input.kind}:${input.source}`),
    ref = db.doc(`engagementIntents/${id}`);
  const value = await db.runTransaction(async (tx) => {
    const [old, fence, member, baby, receipt, babyFence] = await Promise.all([
      tx.get(ref),
      tx.get(db.doc(`engagementFences/${engHash(`uid:${input.uid}`)}`)),
      tx.get(db.doc(`babies/${input.babyId}/members/${input.uid}`)),
      tx.get(db.doc(`babies/${input.babyId}`)),
      tx.get(db.doc(`engagementReceipts/${id}`)),
      tx.get(db.doc(`engagementFences/${engHash(`babyId:${input.babyId}`)}`)),
    ]);
    if (
      fence.exists ||
      babyFence.exists ||
      member.get('status') !== 'active' ||
      !['coParent', 'relative', 'caregiver'].includes(String(member.get('role'))) ||
      (analyticsTime(member.get('accessUntilAt')) > 0 &&
        analyticsTime(member.get('accessUntilAt')) <= now.getTime()) ||
      !baby.exists ||
      baby.get('state') === 'deleting'
    )
      return null;
    if (old.exists) {
      const i = old.data() as EngagementIntent;
      if (
        i.kind !== 'ENG-04' &&
        !i.sentAt &&
        !i.dismissed &&
        !i.completedAt &&
        i.status === 'in_app_only'
      )
        tx.update(ref, { nextAt: Math.max(now.getTime(), i.dueAt, i.snoozedUntil) });
      return i;
    }
    if (receipt.exists) return null;
    const i: EngagementIntent = {
      ...input,
      id,
      status: 'eligible',
      reason: 'none',
      sentAt: null,
      snoozedUntil: 0,
      dismissed: false,
      completedAt: null,
      priority: engagementPriority[input.kind],
    };
    // ENG-04 is measurement only: Care keeps its own sender, so it never enters the tick queue,
    // and `proactive` keeps its volume out of the per-account proactive reads.
    tx.create(ref, {
      ...i,
      proactive: input.kind !== 'ENG-04',
      ...(input.kind === 'ENG-04' ? {} : { nextAt: input.dueAt }),
      deleteAfter: new Date(input.windowClosesAt + 30 * ENG_DAY),
    });
    return i;
  });
  // Out-of-transaction analytics uses its own idempotent receipt and can be repaired on refresh.
  if (value) await engStage(db, value, 'eligible', now);
  return value;
}
export async function refreshEngagement(db: Firestore, uid: string, data: unknown, now: Date) {
  const parsed = engagementRefreshSchema.safeParse(data);
  if (!parsed.success) throw new AccountError('invalid-argument', 'malformed');
  const r = parsed.data;
  if (r.ownerUid !== uid) throw new AccountError('permission-denied', 'stale-owner');
  const fences = await Promise.all([
    db.doc(`engagementFences/${engHash(`uid:${uid}`)}`).get(),
    db.doc(`engagementFences/${engHash(`babyId:${r.babyId}`)}`).get(),
  ]);
  if (fences.some((f) => f.exists))
    return { enabled: false, suggestions: [], preferences: engagementPreferencesSchema.parse({}) };
  const scope = await engagementScope(db, uid, r.babyId, now),
    config = await engagementConfig(db, scope.familyId);
  const prefs = engagementPreferencesSchema.parse(
    (await db.doc(`users/${uid}/settings/engagement`).get()).get('preferences') ?? {},
  );
  if (!config.enabled) return { enabled: false, suggestions: [], preferences: prefs };
  await db.runTransaction(async (tx) => {
    const stateRef = db.doc(`users/${uid}/settings/engagementState`);
    const [state, device, uidFence, babyFence, member, baby, oldLease] = await Promise.all([
      tx.get(stateRef),
      tx.get(db.doc(`users/${uid}/devices/${r.deviceId}`)),
      tx.get(db.doc(`engagementFences/${engHash(`uid:${uid}`)}`)),
      tx.get(db.doc(`engagementFences/${engHash(`babyId:${r.babyId}`)}`)),
      tx.get(db.doc(`babies/${r.babyId}/members/${uid}`)),
      tx.get(db.doc(`babies/${r.babyId}`)),
      tx.get(db.doc(`users/${uid}/settings/engagementDevice`)),
    ]);
    if (
      uidFence.exists ||
      babyFence.exists ||
      member.get('status') !== 'active' ||
      !['coParent', 'relative', 'caregiver'].includes(String(member.get('role'))) ||
      (analyticsTime(member.get('accessUntilAt')) > 0 &&
        analyticsTime(member.get('accessUntilAt')) <= now.getTime()) ||
      !baby.exists ||
      baby.get('state') === 'deleting'
    )
      throw new AccountError('permission-denied', 'not-a-member');
    const bucket = Math.floor(now.getTime() / 3600_000),
      count = state.get('refreshBucket') === bucket ? Number(state.get('refreshCount') ?? 0) : 0;
    if (count >= 100) throw new AccountError('failed-precondition', 'refresh-limit');
    tx.set(
      stateRef,
      {
        refreshBucket: bucket,
        refreshCount: count + 1,
        ...(r.handoffKinds.includes('ENG-06') ? { lumiHandedOff: true } : {}),
        ...(member.get('role') === 'coParent' && r.legacyDismissedCampaigns.length
          ? {
              dismissedCampaigns: FieldValue.arrayUnion(
                ...r.legacyDismissedCampaigns.map((o) => engHash(`${r.babyId}:${o}`)),
              ),
            }
          : {}),
      },
      { merge: true },
    );
    if (device.exists && !device.get('signedOutAt'))
      tx.set(db.doc(`users/${uid}/settings/engagementDevice`), {
        deviceId: r.deviceId,
        pushAllowed: r.pushAllowed,
        recipientZone: r.recipientZone ?? null,
        handoffKinds: r.handoffKinds,
        handoffs: {
          ...(oldLease.get('deviceId') === r.deviceId ? (oldLease.get('handoffs') ?? {}) : {}),
          [engHash(r.babyId)]:
            r.pendingOnly && oldLease.get('deviceId') === r.deviceId
              ? [
                  ...new Set([
                    ...(oldLease.get(`handoffs.${engHash(r.babyId)}`) ?? []),
                    ...r.handoffKinds,
                  ]),
                ]
              : r.handoffKinds,
        },
        babyId: r.babyId,
        validUntil: now.getTime() + 2 * 3600_000,
      });
  });
  await discoverEngagementSources(db, uid, r, scope, config, now);
  if (r.pendingOnly)
    return {
      enabled: true,
      preferences: prefs,
      suggestions: [],
      ownsPending: config.on('engagementPendingEnabled'),
    };
  const rows = await db
    .collection('engagementIntents')
    .where('uid', '==', uid)
    .where('babyId', '==', r.babyId)
    .where('proactive', '==', true)
    .limit(200)
    .get();
  const suggestions = [];
  const evidence = new Map();
  for (const doc of rows.docs) {
    const i = doc.data() as EngagementIntent;
    if (i.kind === 'ENG-01' && i.sourceData.deviceId !== r.deviceId) continue;
    if (
      i.babyId !== r.babyId ||
      i.dismissed ||
      i.completedAt ||
      i.status === 'cancelled' ||
      (i.status === 'expired' && i.kind !== 'ENG-02')
    )
      continue;
    if (!config.on(kindFlag[i.kind])) continue;
    const valid = await validateEngagementSource(db, i, now, evidence);
    if (valid.state === 'resolved') {
      await finishEngagement(db, i, valid.completed === true, now, valid.completedAt);
      continue;
    }
    if (valid.state !== 'ready') continue;
    if (i.context !== 'retrospective' && now.getTime() >= i.windowClosesAt) continue;
    suggestions.push({
      id: i.id,
      kind: i.kind,
      context: i.context,
      occasion: i.sourceData.occasion ?? null,
      occasionDate: String(i.sourceData.occasionDate ?? ''),
      route: valid.route,
      expiresAt: new Date(i.windowClosesAt).toISOString(),
      sent: i.sentAt !== null,
      snoozed: i.snoozedUntil > now.getTime(),
    });
  }
  const fatigue = (await db.doc(`users/${uid}/settings/engagementState`).get()).data() ?? {};
  return {
    enabled: true,
    preferences: prefs,
    fatigue: {
      paused: fatigue.paused === true,
      pausedUntil: Number(fatigue.pausedUntil ?? 0),
      reducedUntil: Number(fatigue.reducedUntil ?? 0),
    },
    ownsMilestone: config.on('engagementMilestoneEnabled'),
    ownsPending: config.on('engagementPendingEnabled'),
    ownsLumi: config.on('engagementLumiEnabled'),
    suggestions: suggestions
      .filter((s) => !s.snoozed)
      .sort(
        (a, b) =>
          engagementPriority[a.kind] - engagementPriority[b.kind] ||
          (a.context === 'retrospective' && b.context === 'retrospective'
            ? b.occasionDate.localeCompare(a.occasionDate)
            : 0) ||
          a.id.localeCompare(b.id),
      )
      .slice(0, 6),
  };
}
export async function finishEngagement(
  db: Firestore,
  i: EngagementIntent,
  completed: boolean,
  now: Date,
  completedAt = now.getTime(),
) {
  const changed = await db.runTransaction(async (tx) => {
    const ref = db.doc(`engagementIntents/${i.id}`),
      live = await tx.get(ref);
    if (!live.exists || live.get('completedAt') || live.get('status') === 'cancelled') return false;
    tx.update(ref, {
      status: completed ? 'completed' : 'cancelled',
      reason: 'source_resolved',
      completedAt: completed ? completedAt : null,
      nextAt: FieldValue.delete(),
    });
    tx.set(db.doc(`engagementReceipts/${i.id}`), {
      uid: i.uid,
      babyId: i.babyId,
      deleteAfter: new Date(i.windowClosesAt + 400 * ENG_DAY),
    });
    if (completed && ['ENG-01', 'ENG-02'].includes(i.kind))
      tx.set(db.doc(`users/${i.uid}/settings/engagementState`), { completedAt }, { merge: true });
    return true;
  });
  if (changed)
    await engStage(
      db,
      { ...i, completedAt: completed ? completedAt : null },
      completed ? 'completed' : 'cancelled',
      now,
      'source_resolved',
    );
}
export async function engagementAction(db: Firestore, uid: string, data: unknown, now: Date) {
  const parsed = engagementActionSchema.safeParse(data);
  if (!parsed.success) throw new AccountError('invalid-argument', 'malformed');
  const r = parsed.data,
    ref = db.doc(`engagementIntents/${r.id}`),
    doc = await ref.get(),
    i = doc.data() as EngagementIntent | undefined;
  if (!i || i.uid !== uid) throw new AccountError('permission-denied', 'not-allowed');
  await engagementScope(db, uid, i.babyId, now);
  const choicePolicy = (await engagementConfig(db, i.familyId)).policy;
  if (r.action === 'open' && i.kind === 'ENG-01' && r.deviceId !== i.sourceData.deviceId)
    return { route: null, state: 'source_device_required' };
  if (r.action === 'open' || r.action === 'view') {
    const valid = await validateEngagementSource(db, i, now);
    if (
      valid.state !== 'ready' ||
      (i.context !== 'retrospective' && now.getTime() >= i.windowClosesAt)
    )
      return { route: null, state: 'expired' };
    // update(), not set(merge): a purge between the read and this write must not leave an orphan.
    if (r.action === 'view') await ref.update({ viewedAt: now.getTime() }).catch(() => undefined);
    if (r.action === 'open') {
      await engStage(db, i, 'opened', now);
      await ref.update({ openedAt: now.getTime() }).catch(() => undefined);
    }
    // Content view completion is observed at the actual destination, never inferred from a tap.
    let content: { mediaIds: string[]; storyIds: string[] } | undefined;
    if (i.kind === 'ENG-03') {
      const scope = await engagementScope(db, uid, i.babyId, now),
        c = await weeklySource(
          db,
          i.babyId,
          scope,
          String(i.sourceData.start),
          String(i.sourceData.end),
        );
      content = { mediaIds: c.media.map((d) => d.id), storyIds: c.stories.map((d) => d.id) };
    }
    return {
      route: valid.route,
      babyId: i.babyId,
      state: 'ready',
      ...(content ? { content } : {}),
    };
  }
  const changed = await db.runTransaction(async (tx) => {
    const stateRef = db.doc(`users/${uid}/settings/engagementState`),
      [live, state] = await Promise.all([tx.get(ref), tx.get(stateRef)]);
    if (!live.exists || live.get('dismissed') || live.get('completedAt')) return false;
    if (r.action === 'dismiss') {
      tx.set(db.doc(`engagementReceipts/${i.id}`), {
        uid: i.uid,
        babyId: i.babyId,
        deleteAfter: new Date(i.windowClosesAt + 400 * ENG_DAY),
      });
      const dismissals = ((state.get('dismissals') ?? []) as number[]).filter(
        (t) => t > now.getTime() - 14 * ENG_DAY,
      );
      dismissals.push(now.getTime());
      tx.set(
        stateRef,
        {
          dismissals: dismissals.slice(-30),
          ...(dismissals.filter((t) => t > now.getTime() - 7 * ENG_DAY).length >=
          choicePolicy.reducedDismissals
            ? {
                reducedUntil: Math.max(
                  Number(state.get('reducedUntil') ?? 0),
                  now.getTime() + 7 * ENG_DAY,
                ),
              }
            : {}),
          ...(dismissals.length >= choicePolicy.pausedDismissals
            ? {
                paused: true,
                pausedUntil: Math.max(
                  Number(state.get('pausedUntil') ?? 0),
                  now.getTime() + 14 * ENG_DAY,
                ),
              }
            : {}),
          ...(i.kind === 'ENG-02'
            ? {
                dismissedCampaigns: FieldValue.arrayUnion(
                  engHash(`${i.babyId}:${i.sourceData.occasion}`),
                ),
              }
            : {}),
        },
        { merge: true },
      );
      tx.update(ref, {
        dismissed: true,
        status: 'cancelled',
        reason: 'user_choice',
        nextAt: FieldValue.delete(),
      });
    } else {
      const until = now.getTime() + 2 * ENG_DAY;
      // Hide it from the shelf; only an unsent intent with push time left goes back in the queue.
      const requeue =
        live.get('kind') !== 'ENG-04' &&
        !live.get('sentAt') &&
        ['eligible', 'deferred'].includes(String(live.get('status'))) &&
        until < Number(live.get('expiresAt'));
      tx.update(ref, {
        snoozedUntil: until,
        nextAt: requeue ? until : FieldValue.delete(),
      });
    }
    return true;
  });
  if (changed)
    await engStage(db, i, r.action === 'dismiss' ? 'dismissed' : 'snoozed', now, 'user_choice');
  return { state: 'saved', route: null };
}
export async function saveEngagementSettings(db: Firestore, uid: string, data: unknown, now: Date) {
  const p = engagementSettingsSchema.safeParse(data);
  if (!p.success) throw new AccountError('invalid-argument', 'malformed');
  await db.runTransaction(async (tx) => {
    const stateRef = db.doc(`users/${uid}/settings/engagementState`),
      [state, fence] = await Promise.all([
        tx.get(stateRef),
        tx.get(db.doc(`engagementFences/${engHash(`uid:${uid}`)}`)),
      ]);
    if (fence.exists) throw new AccountError('permission-denied', 'not-allowed');
    if (p.data.resume && Number(state.get('pausedUntil') ?? 0) > now.getTime())
      throw new AccountError('failed-precondition', 'cooldown');
    if (p.data.preferences)
      tx.set(db.doc(`users/${uid}/settings/engagement`), {
        preferences: p.data.preferences,
        updatedAt: now,
      });
    if (p.data.resume)
      tx.set(
        stateRef,
        { paused: false, resumedAt: now.getTime(), dismissals: [], ignored: [] },
        { merge: true },
      );
  });
  if (p.data.resume) {
    // Doc 18 #22: intents the pause suppressed come back while their window is still open.
    const rows = await db
      .collection('engagementIntents')
      .where('uid', '==', uid)
      .where('proactive', '==', true)
      .limit(500)
      .get();
    for (const doc of rows.docs) {
      const i = doc.data() as EngagementIntent;
      if (
        i.reason !== 'fatigue_paused' ||
        i.sentAt ||
        i.dismissed ||
        i.completedAt ||
        i.expiresAt <= now.getTime() ||
        !['suppressed', 'cancelled', 'in_app_only'].includes(i.status)
      )
        continue;
      await doc.ref.update({
        nextAt: Math.max(now.getTime(), i.dueAt, i.snoozedUntil),
        status: 'eligible',
        reason: 'none',
      });
    }
  }
  if (p.data.preferences) {
    const rows = await db
      .collection('engagementIntents')
      .where('uid', '==', uid)
      .where('proactive', '==', true)
      .limit(500)
      .get();
    for (const doc of rows.docs) {
      const i = doc.data() as EngagementIntent;
      // Sent, finished or family-suppressed intents keep their recorded outcome (funnel integrity).
      if (
        i.kind === 'ENG-04' ||
        i.sentAt ||
        i.dismissed ||
        i.completedAt ||
        !['eligible', 'deferred', 'in_app_only'].includes(i.status)
      )
        continue;
      if (
        !p.data.preferences.consent ||
        !p.data.preferences.kinds[i.kind as keyof EngagementPreferences['kinds']]
      ) {
        if (i.status === 'in_app_only' && i.reason === 'user_choice') continue;
        await doc.ref.update({
          status: 'in_app_only',
          reason: 'user_choice',
          nextAt: FieldValue.delete(),
        });
        await engStage(db, i, 'suppressed', now, 'user_choice');
      } else
        await doc.ref.update({
          nextAt: Math.max(now.getTime(), i.dueAt, i.snoozedUntil),
          status: 'eligible',
          reason: 'none',
        });
    }
  }
  return { saved: true };
}
export const engagementCopy = {
  'ENG-01': {
    vi: { title: 'Kỷ niệm của bạn', body: 'Bạn có ảnh đang chờ chọn lưu.' },
    en: { title: 'Your memories', body: 'Some photos are ready for your review.' },
  },
  'ENG-02': {
    vi: { title: 'Kỷ niệm của bạn', body: 'Có một gợi ý làm video kỷ niệm dành cho bạn.' },
    en: { title: 'Your memories', body: 'A memory video idea is ready for you.' },
  },
  'ENG-03': {
    vi: { title: 'Nhìn lại tuần qua', body: 'Bạn có những kỷ niệm đã lưu để xem lại.' },
    en: { title: 'Look back on your week', body: 'Your saved memories are ready to revisit.' },
  },
  'ENG-04': {
    vi: { title: 'Nhắc việc', body: 'Có một việc bạn đã đặt lịch.' },
    en: { title: 'Your reminder', body: 'A routine you scheduled is due.' },
  },
  'ENG-05': {
    vi: { title: 'Gia đình của bạn', body: 'Có cập nhật được chia sẻ trong gia đình.' },
    en: { title: 'Your family', body: 'There are shared family updates.' },
  },
  'ENG-06': {
    vi: { title: 'Gợi ý dành cho bạn', body: 'Có một gợi ý mới để bạn xem khi thuận tiện.' },
    en: { title: 'An idea for you', body: 'A fresh suggestion is ready when you are.' },
  },
} as const;
/** P-174 Portal templates; [engagementCopy] is their version 0. */
const engagementTemplate = {
  'ENG-01': 'eng.pending_photos',
  'ENG-02': 'eng.keepsake_suggestion',
  'ENG-03': 'eng.weekly_recap',
  'ENG-04': 'care.rule_due',
  'ENG-05': 'eng.family_recap',
  'ENG-06': 'eng.lumi_insight',
} as const;
const noticeKind = {
  'ENG-01': 'photoSuggestion',
  'ENG-02': 'keepsakePrompt',
  'ENG-03': 'weeklySummary',
  'ENG-04': 'reminderRule',
  'ENG-05': 'familyActivity',
  'ENG-06': 'rhythm',
} as const;

/** One account transaction reserves capacity BEFORE adapter I/O. Ambiguous sends never retry. */
export async function dispatchEngagement(
  db: Firestore,
  sender: PushSender | null,
  doc: QueryDocumentSnapshot,
  now: Date,
  checkPriority = true,
) {
  const initial = doc.data() as EngagementIntent;
  if (initial.kind === 'ENG-04') {
    // Existing user-configured Care owns its own adapter; never hold a scheduler slot.
    await doc.ref.update({ nextAt: FieldValue.delete() });
    return;
  }
  if (checkPriority) {
    // A bounded scheduler page must not allow an older low-priority item to consume this
    // recipient's slot before a due milestone outside that global page.
    const peers = await db
      .collection('engagementIntents')
      .where('uid', '==', initial.uid)
      .where('proactive', '==', true)
      .limit(200)
      .get();
    const before = (a: EngagementIntent, b: EngagementIntent) =>
      a.priority - b.priority ||
      a.expiresAt - b.expiresAt ||
      a.eligibleAt - b.eligibleAt ||
      a.id.localeCompare(b.id);
    const higher = peers.docs
      .filter((d) => {
        const p = d.data() as EngagementIntent;
        return (
          p.kind !== 'ENG-04' &&
          typeof d.get('nextAt') === 'number' &&
          d.get('nextAt') <= now.getTime() &&
          before(p, initial) < 0 &&
          !p.sentAt &&
          !p.completedAt &&
          !p.dismissed
        );
      })
      .sort((a, b) => before(a.data() as EngagementIntent, b.data() as EngagementIntent));
    for (const peer of higher.slice(0, 10)) await dispatchEngagement(db, sender, peer, now, false);
    if (higher.length > 10) {
      await doc.ref.update({
        status: 'deferred',
        reason: 'higher_priority',
        nextAt: now.getTime() + 5 * 60_000,
      });
      return;
    }
  }
  let scope;
  try {
    scope = await engagementScope(db, initial.uid, initial.babyId, now);
  } catch {
    await doc.ref.update({
      status: 'cancelled',
      reason: 'not_authorized',
      nextAt: FieldValue.delete(),
    });
    await engStage(db, initial, 'cancelled', now, 'not_authorized');
    return;
  }
  const config = await engagementConfig(db, scope.familyId),
    source = await validateEngagementSource(db, initial, now);
  if (source.state === 'resolved') {
    await finishEngagement(db, initial, source.completed === true, now, source.completedAt);
    return;
  }
  const reservation = await db.runTransaction(async (tx) => {
    const stateRef = db.doc(`users/${initial.uid}/settings/engagementState`);
    const campaignRef = db.doc(
      `engagementCampaigns/${engHash(`${initial.babyId}:${initial.source}`)}`,
    );
    const [
      live,
      state,
      settings,
      pref,
      personal,
      deviceLease,
      campaign,
      member,
      baby,
      accountFence,
      babyFence,
    ] = await Promise.all([
      tx.get(doc.ref),
      tx.get(stateRef),
      tx.get(db.doc(`users/${initial.uid}/settings/notifications`)),
      tx.get(db.doc(`users/${initial.uid}/settings/engagement`)),
      tx.get(db.doc(`users/${initial.uid}/settings/personalization`)),
      tx.get(db.doc(`users/${initial.uid}/settings/engagementDevice`)),
      tx.get(campaignRef),
      tx.get(db.doc(`babies/${initial.babyId}/members/${initial.uid}`)),
      tx.get(db.doc(`babies/${initial.babyId}`)),
      tx.get(db.doc(`engagementFences/${engHash(`uid:${initial.uid}`)}`)),
      tx.get(db.doc(`engagementFences/${engHash(`babyId:${initial.babyId}`)}`)),
    ]);
    if (!live.exists) return null;
    const i = live.data() as EngagementIntent;
    if (
      i.completedAt ||
      i.dismissed ||
      ['completed', 'cancelled', 'expired', 'attempted', 'accepted', 'unknown', 'failed'].includes(
        i.status,
      )
    ) {
      // Snoozed-after-send or stale rows must not hold a scheduler slot every tick.
      if (live.get('nextAt') !== undefined) tx.update(doc.ref, { nextAt: FieldValue.delete() });
      return null;
    }
    const consent = engagementPreferencesSchema.parse(pref.get('preferences') ?? {}),
      n = now.getTime();
    const dismissals = ((state.get('dismissals') ?? []) as number[]).filter(
      (t) => t > n - 14 * ENG_DAY,
    );
    const ignored = ((state.get('ignored') ?? []) as number[]).filter((t) => t > n - 14 * ENG_DAY);
    const shouldPause =
      dismissals.length >= config.policy.pausedDismissals ||
      ignored.length >= config.policy.ignoredThreshold;
    const paused = state.get('paused') === true || shouldPause;
    const reduced =
      dismissals.filter((t) => t > n - 7 * ENG_DAY).length >= config.policy.reducedDismissals ||
      Number(state.get('reducedUntil') ?? 0) > n;
    const recent = ((state.get('recent') ?? []) as number[]).filter((t) => t > n - 7 * ENG_DAY);
    const allowedDevice = String(deviceLease.get('deviceId') ?? '');
    const device = allowedDevice
      ? await tx.get(db.doc(`users/${i.uid}/devices/${allowedDevice}`))
      : null;
    // A live settings/device lease is required; cached permission is not a delivery receipt.
    const settingsKey = {
      'ENG-01': 'photoSuggestions',
      'ENG-02': 'keepsakePrompts',
      'ENG-03': 'weeklySummary',
      'ENG-05': 'familyActivity',
      'ENG-06': 'rhythm',
    }[i.kind as Exclude<EngagementKind, 'ENG-04'>]!;
    const validMember =
      member.get('status') === 'active' &&
      (member.get('role') === 'coParent' ||
        (['ENG-03', 'ENG-05'].includes(i.kind) && member.get('role') === 'relative') ||
        (['ENG-04', 'ENG-06'].includes(i.kind) && member.get('role') === 'caregiver')) &&
      (!analyticsTime(member.get('accessUntilAt')) ||
        analyticsTime(member.get('accessUntilAt')) > n) &&
      baby.get('state') !== 'deleting';
    const familySent = i.kind === 'ENG-02' && campaign.exists;
    const decision = decideEngagement(
      {
        now: n,
        dueAt:
          i.kind === 'ENG-06'
            ? Math.max(i.dueAt, Number(state.get('lastLumiAt') ?? 0) + 7 * ENG_DAY)
            : i.dueAt,
        expiresAt: i.expiresAt,
        scheduled: i.status === 'scheduled',
        enabled: config.enabled && config.on(kindFlag[i.kind]),
        authorized: validMember && !accountFence.exists && !babyFence.exists,
        source: source.state,
        context: i.context,
        consent: consent.consent,
        category:
          consent.kinds[i.kind as keyof typeof consent.kinds] &&
          notificationSettingsOf(settings.data())[settingsKey as 'rhythm'],
        pushAvailable:
          (!['ENG-01', 'ENG-02', 'ENG-06'].includes(i.kind) ||
            (deviceLease.get(`handoffs.${engHash(i.babyId)}`) ?? []).includes(i.kind)) &&
          (!['ENG-01', 'ENG-06'].includes(i.kind) || allowedDevice === i.sourceData.deviceId) &&
          typeof deviceLease.get('recipientZone') === 'string' &&
          source.pushRecipient !== false &&
          config.on('engagementPushEnabled') &&
          sender !== null &&
          deviceLease.get('pushAllowed') === true &&
          Number(deviceLease.get('validUntil')) > n &&
          !!device?.get('token') &&
          !device.get('signedOutAt'),
        paused,
        reduced,
        dismissed: i.dismissed,
        sentAt: familySent ? n : i.sentAt,
        snoozedUntil: i.snoozedUntil,
        completedAt: Number(state.get('completedAt') ?? 0),
        recent,
        zone: String(deviceLease.get('recipientZone') ?? i.zone),
        quiet:
          personal.get('quietHours') === undefined
            ? config.policy.quietDefault
            : personal.get('quietHours'),
        spacingUntil:
          Number(state.get('transactionAt') ?? 0) + config.policy.spacingMinutes * 60_000,
      },
      config.policy,
    );
    const patch: DocumentData = {
      decision: decision.decision,
      reason: decision.reason,
      status: (
        {
          in_app_only: 'in_app_only',
          delay: 'deferred',
          suppress: 'suppressed',
          cancel: 'cancelled',
          expire: 'expired',
          group_into_digest: 'digest_member',
          push_eligible: 'attempted',
        } as const
      )[decision.decision],
      nextAt: decision.nextAt ?? FieldValue.delete(),
    };
    if (decision.decision === 'expire')
      tx.set(db.doc(`engagementReceipts/${i.id}`), {
        uid: i.uid,
        babyId: i.babyId,
        deleteAfter: new Date(i.windowClosesAt + 400 * ENG_DAY),
      });
    if (decision.decision === 'push_eligible') {
      tx.set(db.doc(`engagementReceipts/${i.id}`), {
        uid: i.uid,
        babyId: i.babyId,
        deleteAfter: new Date(i.windowClosesAt + 400 * ENG_DAY),
      });
      patch.status = 'attempted';
      patch.sentAt = n;
      patch.attemptedAt = n;
      patch.deviceId = allowedDevice;
      tx.set(
        stateRef,
        {
          recent: [...recent, n].slice(-10),
          ...(i.kind === 'ENG-06' ? { lastLumiAt: n } : {}),
          paused,
          ...(shouldPause && state.get('paused') !== true ? { pausedUntil: n + 14 * ENG_DAY } : {}),
          ...(reduced
            ? { reducedUntil: Math.max(Number(state.get('reducedUntil') ?? 0), n + 7 * ENG_DAY) }
            : {}),
        },
        { merge: true },
      );
      if (i.kind === 'ENG-02')
        tx.create(campaignRef, {
          babyId: i.babyId,
          uid: i.uid,
          at: now,
          deleteAfter: new Date(i.windowClosesAt + 400 * ENG_DAY),
        });
    } else if (shouldPause && state.get('paused') !== true)
      tx.set(stateRef, { paused: true, pausedUntil: n + 14 * ENG_DAY }, { merge: true });
    tx.update(doc.ref, patch);
    return {
      i,
      decision,
      deviceId: allowedDevice,
      recipientZone: String(deviceLease.get('recipientZone') ?? i.zone),
    };
  });
  if (!reservation) return;
  const { i, decision, deviceId, recipientZone } = reservation;
  if (decision.decision !== 'push_eligible') {
    if (['suppress', 'cancel', 'expire', 'in_app_only'].includes(decision.decision))
      await engStage(
        db,
        i,
        decision.decision === 'cancel'
          ? 'cancelled'
          : decision.decision === 'expire'
            ? 'expired'
            : 'suppressed',
        now,
        decision.reason,
      );
    return;
  }
  await engStage(db, i, 'scheduled', now);
  await engStage(db, i, 'attempted', now);
  // Recheck immediately before handoff. Reservation stays consumed if a send is ambiguous.
  const [live, latestConfig, latestSource, latestPref] = await Promise.all([
    doc.ref.get(),
    engagementConfig(db, i.familyId),
    validateEngagementSource(db, i, now),
    db.doc(`users/${i.uid}/settings/engagement`).get(),
  ]);
  if (
    live.get('status') !== 'attempted' ||
    latestPref.get('preferences.consent') !== true ||
    latestPref.get(`preferences.kinds.${i.kind}`) !== true ||
    live.get('dismissed') ||
    live.get('completedAt') ||
    !latestConfig.enabled ||
    !latestConfig.on('engagementPushEnabled') ||
    latestSource.state !== 'ready' ||
    latestSource.pushRecipient === false
  ) {
    await releaseReservation(db, doc, i, now);
    return;
  }
  let adapter: { attempted: boolean; accepted: number; inbox: boolean; held: boolean } | undefined;
  try {
    const result = await notifyUsers(
      db,
      sender,
      [i.uid],
      {
        kind: noticeKind[i.kind],
        id: `eng-${i.id.slice(0, 48)}`,
        babyId: i.babyId,
        data: { engagementId: i.id, babyId: i.babyId },
        deviceId,
        // P-174: the unified platform's ledger follows the intent; ambiguous sends never retry.
        retry: false,
        engagement: { id: i.id, kind: i.kind },
        template: { id: engagementTemplate[i.kind], values: {} },
        onResult: async (_uid, result) => {
          adapter = result;
        },
        zone: recipientZone,
        message: (language) => ({
          ...engagementCopy[i.kind][language],
          expiresAt: i.expiresAt,
          apns: { collapseId: i.id.slice(0, 64) },
        }),
      },
      now,
    );
    const stage =
      result.sent > 0
        ? 'accepted'
        : adapter?.attempted
          ? 'failed'
          : adapter
            ? 'cancelled'
            : 'unknown';
    await doc.ref.update({ status: stage });
    await engStage(
      db,
      i,
      stage,
      now,
      stage === 'failed' ? 'channel_unavailable' : adapter?.held ? 'quiet_hours' : 'none',
    );
  } catch {
    await doc.ref.update({ status: 'unknown' });
    await engStage(db, i, 'unknown', now);
  }
}
/** The final recheck aborted before any adapter I/O: give the slot back, record a cancel. */
async function releaseReservation(
  db: Firestore,
  doc: QueryDocumentSnapshot,
  i: EngagementIntent,
  now: Date,
) {
  const sentAt = await db.runTransaction(async (tx) => {
    const live = await tx.get(doc.ref);
    if (!live.exists || live.get('status') !== 'attempted') return null;
    const at = Number(live.get('sentAt'));
    tx.update(doc.ref, {
      status: 'cancelled',
      reason: 'source_resolved',
      sentAt: null,
      nextAt: FieldValue.delete(),
    });
    tx.set(
      db.doc(`users/${i.uid}/settings/engagementState`),
      { recent: FieldValue.arrayRemove(at) },
      { merge: true },
    );
    if (i.kind === 'ENG-02')
      tx.delete(db.doc(`engagementCampaigns/${engHash(`${i.babyId}:${i.source}`)}`));
    return at;
  });
  if (sentAt !== null) await engStage(db, i, 'cancelled', now, 'source_resolved');
}
export async function runEngagement(db: Firestore, sender: PushSender | null, now: Date) {
  const rows = await db
    .collection('engagementIntents')
    .where('nextAt', '<=', now.getTime())
    .orderBy('nextAt')
    .limit(100)
    .get();
  const sorted = rows.docs.sort(
    (a, b) =>
      Number(a.get('priority')) - Number(b.get('priority')) ||
      Number(a.get('expiresAt')) - Number(b.get('expiresAt')) ||
      Number(a.get('eligibleAt')) - Number(b.get('eligibleAt')) ||
      a.id.localeCompare(b.id),
  );
  for (const doc of sorted) {
    try {
      await dispatchEngagement(db, sender, doc, now);
    } catch {
      const live = await doc.ref.get();
      if (!live.exists) continue;
      if (
        live.get('completedAt') ||
        live.get('dismissed') ||
        ['completed', 'cancelled', 'expired'].includes(String(live.get('status')))
      ) {
        await doc.ref.update({ nextAt: FieldValue.delete() });
        continue;
      }
      if (live.get('sentAt')) {
        await doc.ref.update({ status: 'unknown', nextAt: FieldValue.delete() });
        await engStage(db, live.data() as EngagementIntent, 'unknown', now);
      } else
        await doc.ref.update({
          status: 'deferred',
          reason: 'awaiting_verification',
          nextAt: now.getTime() + 15 * 60_000,
        });
    }
  }
  // Attempts left by a crash remain consumed and unknown, never retried automatically.
  const stale = await db
    .collection('engagementIntents')
    .where('status', '==', 'attempted')
    .limit(100)
    .get();
  for (const doc of stale.docs)
    if (Number(doc.get('attemptedAt')) < now.getTime() - 10 * 60_000) {
      await doc.ref.update({ status: 'unknown' });
      await engStage(db, doc.data() as EngagementIntent, 'unknown', now);
    }
}
export async function purgeEngagement(
  db: Firestore,
  field: 'uid' | 'babyId',
  value: string,
  now: Date,
) {
  await db
    .doc(`engagementFences/${engHash(`${field}:${value}`)}`)
    .set({ deleteAfter: new Date(now.getTime() + 401 * ENG_DAY) });
  for (const name of ['engagementIntents', 'engagementCampaigns', 'engagementReceipts'])
    for (;;) {
      const rows = await db.collection(name).where(field, '==', value).limit(300).get();
      if (rows.empty) break;
      const batch = db.batch();
      // A family campaign marker outlives one parent's account: erase the reference, keep the
      // dedup so the other coParent is not sent the same campaign again.
      rows.docs.forEach((d) =>
        name === 'engagementCampaigns' && field === 'uid'
          ? batch.update(d.ref, { uid: FieldValue.delete() })
          : batch.delete(d.ref),
      );
      await batch.commit();
    }
  if (field === 'uid')
    for (const key of ['engagement', 'engagementState', 'engagementDevice'])
      await db.doc(`users/${value}/settings/${key}`).delete();
}

/** Renew only after live authorization for EVERY cached biometric scope, before opening its file. */
export async function authorizeEngagementBackground(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
) {
  const p = engagementBackgroundAccessSchema.safeParse(data);
  if (!p.success) throw new AccountError('invalid-argument', 'malformed');
  if (p.data.ownerUid !== uid) throw new AccountError('permission-denied', 'stale-owner');
  const [device, fence] = await Promise.all([
    db.doc(`users/${uid}/devices/${p.data.deviceId}`).get(),
    db.doc(`engagementFences/${engHash(`uid:${uid}`)}`).get(),
  ]);
  if (fence.exists || !device.exists || device.get('signedOutAt'))
    throw new AccountError('permission-denied', 'not-allowed');
  let until = now.getTime() + ENG_DAY;
  for (const babyId of p.data.babyIds) {
    const [scope, babyFence] = await Promise.all([
      engagementScope(db, uid, babyId, now),
      db.doc(`engagementFences/${engHash(`babyId:${babyId}`)}`).get(),
    ]);
    const config = await engagementConfig(db, scope.familyId);
    if (babyFence.exists || scope.role !== 'coParent' || !config.on('auto_save'))
      throw new AccountError('permission-denied', 'not-allowed');
    // ENG-01 switched off (rollout, kill switch) is not a privacy refusal: background Auto Save
    // keeps scanning, and the next foreground refresh hands the lane back to the legacy alert.
    if (!config.enabled || !config.on('engagementPendingEnabled')) continue;
    if (scope.accessUntil) until = Math.min(until, scope.accessUntil);
  }
  return { authorized: true, leaseUntil: until };
}
