import { type Firestore, type DocumentData } from 'firebase-admin/firestore';
import { analyticsTime } from './product-analytics-store.js';
import {
  ENG_DAY,
  engHash,
  engStage,
  engagementScope,
  engagementConfig,
  engagementTransactionObserved,
  upsertEngagement,
  finishEngagement,
  type EngagementIntent,
} from './engagement.js';
import { validateEngagementSource } from './engagement-sources.js';
import { engagementContentSchema, reminderInstantIn } from '@child-life/contracts';
import { AccountError } from './account.js';

export async function observeEngagementContent(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
) {
  const p = engagementContentSchema.safeParse(data);
  if (!p.success) throw new AccountError('invalid-argument', 'malformed');
  const r = p.data,
    scope = await engagementScope(db, uid, r.babyId, now);
  if (!(await engagementConfig(db, scope.familyId)).enabled) return { completed: 0 };
  let source: DocumentData | undefined;
  if (r.sourceType !== 'personal_day') {
    const collection = { media: 'media', story: 'stories', message: 'messages' }[r.sourceType];
    const doc = await db.doc(`babies/${r.babyId}/${collection}/${r.sourceId}`).get();
    source = doc.data();
    if (!source || source.deleted === true) return { completed: 0 };
    const parent = scope.role === 'coParent';
    if (r.sourceType === 'message' && !parent) return { completed: 0 };
    if (
      r.sourceType === 'media' &&
      (source.status !== 'ready' ||
        (!parent &&
          !(
            scope.role === 'relative' &&
            source.effectiveAudience === 'family' &&
            source.deleted === false
          )))
    )
      return { completed: 0 };
    if (
      r.sourceType === 'story' &&
      (source.status !== 'saved' ||
        (!parent && !(scope.role === 'relative' && source.audience === 'family')))
    )
      return { completed: 0 };
  }
  const rows = await db
    .collection('engagementIntents')
    .where('uid', '==', uid)
    .where('babyId', '==', r.babyId)
    .where('proactive', '==', true)
    .limit(200)
    .get();
  let completed = 0;
  for (const d of rows.docs) {
    const i = d.data() as EngagementIntent;
    if (i.babyId !== r.babyId || i.completedAt || i.dismissed || now.getTime() > i.windowClosesAt)
      continue;
    let matches = false;
    if (i.kind === 'ENG-03' && (r.sourceType === 'media' || r.sourceType === 'story')) {
      const at = analyticsTime(r.sourceType === 'media' ? source?.readyAt : source?.savedAt);
      matches =
        at >= reminderInstantIn(i.zone, String(i.sourceData.start), '00:00').getTime() &&
        at < reminderInstantIn(i.zone, String(i.sourceData.end), '00:00').getTime();
    }
    if (i.kind === 'ENG-05') {
      const ids = (i.sourceData.inboxIds ?? []) as string[];
      for (const id of ids) {
        const notice = await db.doc(`users/${uid}/notifications/${id}`).get(),
          v = notice.get('data') ?? {};
        if (
          v.sourceId === r.sourceId &&
          v.sourceCollection ===
            { media: 'media', story: 'stories', message: 'messages', personal_day: '' }[
              r.sourceType
            ]
        )
          matches = true;
        if (
          v.sourceCollection === 'albums' &&
          r.sourceType === 'media' &&
          (source?.albumIds ?? []).includes(v.sourceId)
        )
          matches = true;
        if (
          v.sourceCollection === 'uploadBatches' &&
          r.sourceType === 'media' &&
          source?.batchId === v.sourceId
        )
          matches = true;
      }
    }
    if (i.kind === 'ENG-06' && r.sourceType === 'personal_day' && r.sourceId === i.babyId)
      matches = true;
    if (matches) {
      const valid = await validateEngagementSource(db, i, now);
      // An inbox may have become read between the actual content view and this receipt.
      if (i.kind === 'ENG-05' || valid.state === 'ready') {
        await finishEngagement(db, i, true, now);
        completed++;
      }
    }
  }
  return { completed };
}

/** Domain transitions reconcile recipients, including a different coParent completing a video. */
export async function reconcileBabyEngagement(db: Firestore, babyId: string, now: Date) {
  const evidence = new Map();
  let cursor: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  for (let page = 0; page < 10; page++) {
    let q = db
      .collection('engagementIntents')
      .where('babyId', '==', babyId)
      .where('proactive', '==', true)
      .orderBy('__name__')
      .limit(100);
    if (cursor) q = q.startAfter(cursor);
    const rows = await q.get();
    for (const d of rows.docs) {
      const i = d.data() as EngagementIntent;
      if (i.completedAt || i.dismissed || ['cancelled', 'expired'].includes(i.status)) continue;
      try {
        const s = await validateEngagementSource(db, i, now, evidence);
        if (s.state === 'resolved')
          await finishEngagement(db, i, s.completed === true, now, s.completedAt);
      } catch {
        /* Unknown source never becomes permission to send. */
      }
    }
    if (rows.size < 100) break;
    cursor = rows.docs.at(-1);
  }
}
/** Observe existing Care. It remains outside proactive budgets and retains its original sender. */
export async function careInboxEngagement(
  db: Firestore,
  uid: string,
  data: DocumentData,
  now: Date,
) {
  if (data.kind !== 'reminderRule') return;
  const babyId = data.babyId,
    ruleId = data.data?.ruleId,
    due = Number(data.data?.dueAt);
  if (typeof babyId !== 'string' || typeof ruleId !== 'string' || !Number.isFinite(due)) return;
  const s = await engagementScope(db, uid, babyId, now),
    c = await engagementConfig(db, s.familyId);
  if (!c.enabled || !['coParent', 'caregiver'].includes(s.role)) return;
  const rule = await db.doc(`babies/${babyId}/reminderRules/${ruleId}`).get();
  if (!rule.exists || !(rule.get('recipients') ?? []).includes(uid)) return;
  const next = analyticsTime(rule.get('nextDueAt')),
    windowEnd = Math.min(due + ENG_DAY, next > due ? next : due + ENG_DAY);
  if (windowEnd <= now.getTime()) return;
  const i = await upsertEngagement(
    db,
    {
      uid,
      babyId,
      familyId: s.familyId,
      zone: s.zone,
      kind: 'ENG-04',
      source: `care:${ruleId}:${due}`,
      context: 'current',
      eligibleAt: now.getTime(),
      dueAt: due,
      expiresAt: windowEnd,
      windowClosesAt: windowEnd,
      sourceData: { ruleId, dueAt: due },
    },
    now,
  );
  // Cohort-only observation (category off, no inbox row) is not a delivery: spacing is untouched.
  if (i && data.eligibilityOnly !== true) await engagementTransactionObserved(db, uid, babyId, now);
  // An inbox write alone proves no dispatch/presentation stage; the adapter reports separately.
}
export async function careAdapterResult(
  db: Firestore,
  uid: string,
  babyId: string,
  ruleId: string,
  due: number,
  result: {
    attempted: boolean;
    accepted: number;
    inbox: boolean;
    held: boolean;
    ambiguous?: boolean;
  },
  now: Date,
) {
  const id = engHash(`${uid}:${babyId}:ENG-04:care:${ruleId}:${due}`),
    doc = await db.doc(`engagementIntents/${id}`).get();
  if (!doc.exists) return;
  const i = doc.data() as EngagementIntent;
  if (result.attempted) await engStage(db, i, 'attempted', now);
  if (result.accepted > 0) await engStage(db, i, 'accepted', now);
  else if (result.ambiguous || (!result.attempted && result.inbox))
    await engStage(db, i, 'unknown', now);
  else if (result.attempted) await engStage(db, i, 'failed', now, 'channel_unavailable');
  else await engStage(db, i, 'suppressed', now, 'channel_unavailable');
}
export async function careOccurrenceEngagement(
  db: Firestore,
  babyId: string,
  ruleId: string,
  data: DocumentData,
  now: Date,
) {
  const due = analyticsTime(data.dueAt);
  if (!due) return;
  const rows = await db
    .collection('engagementIntents')
    .where('babyId', '==', babyId)
    .where('source', '==', `care:${ruleId}:${due}`)
    .limit(50)
    .get();
  for (const d of rows.docs) {
    const i = d.data() as EngagementIntent;
    if (i.kind !== 'ENG-04') continue;
    if (data.outcome === 'logged')
      await finishEngagement(db, i, true, now, analyticsTime(data.at) || now.getTime());
    else if (data.outcome === 'skipped') await finishEngagement(db, i, false, now);
    else if (data.outcome === 'snoozed') await engStage(db, i, 'snoozed', now);
    else if (data.outcome === 'missed') await engStage(db, i, 'expired', now, 'window_closed');
  }
}
export async function revokeEngagementDevice(
  db: Firestore,
  uid: string,
  deviceId: string,
  data: DocumentData | undefined,
) {
  if (data && !data.signedOutAt) return;
  const ref = db.doc(`users/${uid}/settings/engagementDevice`);
  if ((await ref.get()).get('deviceId') === deviceId)
    await ref.set({ validUntil: 0, pushAllowed: false }, { merge: true });
}
/** Only directly observed suggestions can contribute to unanswered fatigue; FCM accepted cannot. */
export async function settleEngagementFatigue(db: Firestore, uid: string, now: Date) {
  const rows = await db
    .collection('engagementIntents')
    .where('uid', '==', uid)
    .where('proactive', '==', true)
    .limit(200)
    .get();
  for (const doc of rows.docs) {
    const i = doc.data();
    if (
      !i.viewedAt ||
      i.openedAt ||
      i.completedAt ||
      i.ignoredObserved ||
      Number(i.windowClosesAt) > now.getTime()
    )
      continue;
    const liveSource = await validateEngagementSource(db, i as EngagementIntent, now);
    if (liveSource.state !== 'ready') continue;
    await db.runTransaction(async (tx) => {
      const stateRef = db.doc(`users/${uid}/settings/engagementState`),
        [fresh, state] = await Promise.all([tx.get(doc.ref), tx.get(stateRef)]);
      if (fresh.get('ignoredObserved') || fresh.get('openedAt') || fresh.get('completedAt')) return;
      const ignored = ((state.get('ignored') ?? []) as number[]).filter(
        (t) => t > now.getTime() - 14 * ENG_DAY,
      );
      tx.set(stateRef, { ignored: [...ignored, now.getTime()].slice(-30) }, { merge: true });
      tx.update(doc.ref, { ignoredObserved: true });
    });
  }
}
export async function cleanupEngagement(db: Firestore, now: Date) {
  for (const collection of [
    'engagementIntents',
    'engagementCampaigns',
    'engagementFences',
    'engagementReceipts',
  ])
    for (let page = 0; page < 10; page++) {
      const rows = await db.collection(collection).where('deleteAfter', '<=', now).limit(300).get();
      if (rows.empty) break;
      const b = db.batch();
      rows.docs.forEach((d) => b.delete(d.ref));
      await b.commit();
    }
}
