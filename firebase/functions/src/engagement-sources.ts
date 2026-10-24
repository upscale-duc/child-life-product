import { FieldValue, type Firestore, type DocumentData } from 'firebase-admin/firestore';
import {
  campaignKinds,
  campaignWindow,
  campaignDate,
  occasions,
  localDateIn,
  addDaysIso,
  reminderInstantIn,
  keepsakePublicCatalogSchema,
  keepsakeTemplateAccess,
  keepsakeNeedsPremiumCheck,
  type KeepsakeTemplate,
  engagementPreferencesSchema,
  notificationSettingsOf,
} from '@child-life/contracts';
import { hasPremiumTemplates } from './entitlements.js';
import { personalizedDay } from './personalization-v2.js';
import { serverGrantEnvironment } from './entitlements.js';
import { analyticsTime } from './product-analytics-store.js';
import { AccountError } from './account.js';
import {
  ENG_DAY,
  engHash,
  upsertEngagement,
  engagementScope,
  type EngagementIntent,
  engagementConfig,
  engagementTransactionObserved,
} from './engagement.js';

type Config = Awaited<ReturnType<typeof engagementConfig>>;
type Scope = { familyId: string; zone: string; role: string };
type Refresh = {
  babyId: string;
  deviceId: string;
  pendingOnly?: boolean;
  pending?:
    | {
        episode: string;
        state: 'pending' | 'resolved' | 'unavailable';
        approvedBatches: string[];
      }
    | undefined;
};
const base = (uid: string, babyId: string, s: Scope, now: Date) => ({
  uid,
  babyId,
  familyId: s.familyId,
  zone: s.zone,
  eligibleAt: now.getTime(),
});

// Reuse published templates. Each required scene needs a DISTINCT matching ready photo.
export function matchesEngagementTemplate(
  template: KeepsakeTemplate,
  photos: DocumentData[],
  dob: string,
  occasion: string,
  zone = 'Asia/Ho_Chi_Minh',
) {
  // Doc 18 #22: age counts from midnight of the birth date in the baby's zone, not UTC.
  const born = reminderInstantIn(zone, dob, '00:00').getTime();
  const eligible = photos.filter((p) => {
    const age = (analyticsTime(p.captureAt) - born) / ENG_DAY;
    return (
      p.type === 'photo' &&
      !p.generated &&
      !p.deleted &&
      p.status === 'ready' &&
      (!template.ageDays || (age >= template.ageDays.min && age < template.ageDays.max + 1))
    );
  });
  if (eligible.length < template.photos.min) return false;
  const required = template.scenes.filter((s) => !s.optional),
    assigned = new Map<number, number>();
  function fill(scene: number, seen: Set<number>): boolean {
    const s = required[scene]!;
    for (let n = 0; n < eligible.length; n++) {
      if (seen.has(n)) continue;
      const p = eligible[n]!,
        capture = analyticsTime(p.captureAt),
        age = (capture - born) / ENG_DAY;
      if (
        !capture ||
        (s.ageDays && (age < s.ageDays.min || age > s.ageDays.max + 1)) ||
        (s.occasion && p.milestone?.id !== occasions[s.occasion].milestoneId)
      )
        continue;
      seen.add(n);
      const old = assigned.get(n);
      if (old === undefined || fill(old, seen)) {
        assigned.set(n, scene);
        return true;
      }
    }
    return false;
  }
  return (
    (!template.occasions.length ||
      template.occasions.includes(occasion as keyof typeof occasions)) &&
    required.every((_, n) => fill(n, new Set()))
  );
}
async function campaignEvidence(db: Firestore, babyId: string) {
  const rows = await Promise.all([
    db.doc(`babies/${babyId}/restricted/profile`).get(),
    db
      .collection(`babies/${babyId}/media`)
      .select('type', 'status', 'deleted', 'captureAt', 'readyAt', 'generated.kind', 'milestone.id')
      .limit(2001)
      .get(),
    db
      .collection(`babies/${babyId}/keepsakeJobs`)
      .select('occasion', 'status', 'memoryId')
      .limit(1001)
      .get(),
    db.doc('publicConfig/keepsakes').get(),
    db.collection(`babies/${babyId}/members`).select('role', 'status', 'accessUntilAt').get(),
    db.doc('config/flags').get(),
  ]);
  const recipients = await Promise.all(
    rows[4].docs
      .filter((m) => m.get('role') === 'coParent' && m.get('status') === 'active')
      .map(async (m) => {
        const [choice, settings, activity] = await Promise.all([
          db.doc(`users/${m.id}/settings/engagement`).get(),
          db.doc(`users/${m.id}/settings/notifications`).get(),
          db
            .collection('productAnalyticsFacts')
            .where('uid', '==', m.id)
            .orderBy('at', 'desc')
            .limit(100)
            .get(),
        ]);
        const consent = engagementPreferencesSchema.parse(choice.get('preferences') ?? {});
        const last = activity.docs
          .filter(
            (d) =>
              d.get('babyId') === babyId &&
              [
                'memory_ready',
                'photo_review_opened',
                'memory_story_started',
                'memory_story_share_sheet_opened',
              ].includes(d.get('event')),
          )
          .reduce((v, d) => Math.max(v, analyticsTime(d.get('at'))), 0);
        return {
          uid: m.id,
          opted:
            consent.consent &&
            consent.kinds['ENG-02'] &&
            notificationSettingsOf(settings.data()).keepsakePrompts,
          last,
        };
      }),
  );
  return [...rows, recipients] as const;
}
async function campaignSource(
  db: Firestore,
  uid: string,
  babyId: string,
  occasion: (typeof campaignKinds)[number],
  now: Date,
  scope: Scope,
  evidence?: ReturnType<typeof campaignEvidence>,
) {
  if (scope.role !== 'coParent') return null;
  const [profile, media, jobs, catalogDoc, members, flags, recipientEvidence] = await (evidence ??
    campaignEvidence(db, babyId));
  const dob = profile.get('dateOfBirth');
  if (typeof dob !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(dob)) return null;
  const parsedDob = new Date(`${dob}T12:00:00Z`);
  if (
    !Number.isFinite(parsedDob.getTime()) ||
    parsedDob.toISOString().slice(0, 10) !== dob ||
    dob > localDateIn(scope.zone, now)
  )
    return null;
  const milestone = occasions[occasion].milestoneId;
  const videoCompleted = media.docs.some(
    (m) =>
      m.get('status') === 'ready' &&
      m.get('deleted') !== true &&
      m.get('generated.kind') === 'video' &&
      m.get('milestone.id') === milestone,
  );
  const resolved =
    media.docs.some(
      (m) =>
        m.get('status') === 'ready' &&
        m.get('deleted') !== true &&
        m.get('generated') &&
        m.get('milestone.id') === milestone,
    ) || jobs.docs.some((j) => j.get('occasion') === occasion && j.get('memoryId'));
  // Only a render still in flight blocks a new invitation; a failed one must not end the campaign.
  const blocked = jobs.docs.some(
    (j) =>
      j.get('occasion') === occasion &&
      ['queued', 'rendering'].includes(String(j.get('status'))) &&
      !j.get('memoryId'),
  );
  const completeHistory = media.size < 2001 && jobs.size < 1001;
  const window = campaignWindow(dob, occasion, scope.zone, now),
    catalog = keepsakePublicCatalogSchema.safeParse(catalogDoc.data());
  if (!catalog.success) return null;
  // Check the existing memory_story capability; no new entitlement or billing bypass.
  const { flagsSchema, isFlagOnForFamily } = await import('@child-life/contracts');
  const { familyBucket } = await import('./features.js');
  const ff = flagsSchema.parse(flags.data() ?? {}),
    family = await db.doc(`families/${scope.familyId}`).get();
  if (
    !isFlagOnForFamily(
      ff.memory_story,
      scope.familyId,
      familyBucket(scope.familyId),
      family.get('internal') === true,
    ) ||
    !ff.media_upload.enabled
  )
    return null;
  let premium: boolean | undefined;
  const photos = media.docs
    .map((d) => d.data())
    .filter((p) => analyticsTime(p.captureAt) <= now.getTime());
  const age = Math.floor(
    (Date.parse(
      `${window.context === 'retrospective' ? campaignDate(dob, occasion) : localDateIn(scope.zone, now)}T12:00:00Z`,
    ) -
      Date.parse(`${dob}T12:00:00Z`)) /
      ENG_DAY,
  );
  let template: KeepsakeTemplate | undefined;
  for (const t of catalog.data.templates
    .filter((t) => t.kind === 'video' && t.status === 'published')
    .sort((a, b) => a.order - b.order || a.id.localeCompare(b.id))) {
    if (t.ageDays && (age < t.ageDays.min || age > t.ageDays.max)) continue;
    if (keepsakeNeedsPremiumCheck(t, catalog.data.premium) && premium === undefined)
      premium = await hasPremiumTemplates(db, uid, babyId, now);
    if (keepsakeTemplateAccess(t, catalog.data.premium, premium ?? false) !== 'ok') continue;
    if (matchesEngagementTemplate(t, photos, dob, occasion, scope.zone)) {
      template = t;
      break;
    }
  }
  const parents = members.docs
    .filter(
      (m) =>
        m.get('role') === 'coParent' &&
        m.get('status') === 'active' &&
        (!analyticsTime(m.get('accessUntilAt')) ||
          analyticsTime(m.get('accessUntilAt')) > now.getTime()),
    )
    .map((m) => m.id)
    .sort();
  return {
    window,
    resolved,
    videoCompleted,
    completedAt: Math.min(
      ...media.docs
        .filter(
          (m) =>
            m.get('generated.kind') === 'video' &&
            m.get('milestone.id') === milestone &&
            m.get('status') === 'ready' &&
            m.get('deleted') !== true,
        )
        .map((m) => analyticsTime(m.get('readyAt')) || now.getTime()),
      now.getTime(),
    ),
    blocked,
    completeHistory,
    template,
    recipient: recipientEvidence
      .filter((p) => p.opted && parents.includes(p.uid))
      .sort((a, b) => b.last - a.last || a.uid.localeCompare(b.uid))[0]?.uid,
    dob,
  };
}
function visibleMedia(role: string, d: DocumentData) {
  return (
    d.status === 'ready' &&
    d.deleted !== true &&
    (role === 'coParent' ||
      (role === 'relative' && d.effectiveAudience === 'family' && d.deleted === false))
  );
}
export async function weeklySource(
  db: Firestore,
  babyId: string,
  scope: Scope,
  start: string,
  end: string,
) {
  const [media, stories] = await Promise.all([
    db
      .collection(`babies/${babyId}/media`)
      .where('readyAt', '>=', reminderInstantIn(scope.zone, start, '00:00'))
      .where('readyAt', '<', reminderInstantIn(scope.zone, end, '00:00'))
      .limit(201)
      .get(),
    db
      .collection(`babies/${babyId}/stories`)
      .where('savedAt', '>=', reminderInstantIn(scope.zone, start, '00:00'))
      .where('savedAt', '<', reminderInstantIn(scope.zone, end, '00:00'))
      .limit(201)
      .get(),
  ]);
  return {
    media: media.docs.filter((d) => visibleMedia(scope.role, d.data())),
    stories: stories.docs.filter(
      (d) =>
        d.get('status') === 'saved' &&
        (scope.role === 'coParent' ||
          (scope.role === 'relative' && d.get('audience') === 'family')),
    ),
  };
}
export async function discoverEngagementSources(
  db: Firestore,
  uid: string,
  r: Refresh,
  scope: Scope,
  config: Config,
  now: Date,
) {
  if (r.pending && scope.role === 'coParent' && config.on('engagementPendingEnabled')) {
    const key = engHash(`${uid}:${r.babyId}:ENG-01:pending:${r.deviceId}:${r.pending.episode}`),
      ref = db.doc(`engagementIntents/${key}`),
      old = await ref.get();
    if (r.pending.state === 'pending')
      await upsertEngagement(
        db,
        {
          ...base(uid, r.babyId, scope, now),
          kind: 'ENG-01',
          source: `pending:${r.deviceId}:${r.pending.episode}`,
          context: 'current',
          dueAt: now.getTime() + ENG_DAY,
          expiresAt: now.getTime() + 7 * ENG_DAY,
          windowClosesAt: now.getTime() + 7 * ENG_DAY,
          sourceData: {
            deviceId: r.deviceId,
            episode: r.pending.episode,
            proofAt: now.getTime(),
            state: 'pending',
            approvedBatches: r.pending.approvedBatches,
          },
        },
        now,
      );
    if (old.exists)
      await ref.update({
        'sourceData.proofAt': now.getTime(),
        'sourceData.state': r.pending.state,
        'sourceData.approvedBatches': r.pending.approvedBatches,
      });
  }
  if (r.pendingOnly) return;
  const evidence =
    config.on('engagementMilestoneEnabled') && scope.role === 'coParent'
      ? campaignEvidence(db, r.babyId)
      : undefined;
  if (config.on('engagementMilestoneEnabled') && scope.role === 'coParent')
    for (const occasion of campaignKinds) {
      const choices = await db.doc(`users/${uid}/settings/engagementState`).get();
      if (
        ((choices.get('dismissedCampaigns') ?? []) as string[]).includes(
          engHash(`${r.babyId}:${occasion}`),
        )
      )
        continue;
      if (occasion === 'm6' && !config.on('engagementSixMonthEnabled')) continue;
      const c = await campaignSource(db, uid, r.babyId, occasion, now, scope, evidence);
      if (!c || !c.window.visible || c.resolved || c.blocked || !c.completeHistory || !c.template)
        continue;
      await upsertEngagement(
        db,
        {
          ...base(uid, r.babyId, scope, now),
          kind: 'ENG-02',
          // Doc 18 #21: a retrospective suggestion is its own opportunity, so it can follow a
          // current campaign that closed without a keepsake (doc 13 §44). Completion, dismissal
          // and an existing keepsake still suppress it (checked above).
          source:
            c.window.context === 'retrospective'
              ? `campaign:${occasion}:retro`
              : `campaign:${occasion}`,
          context: c.window.context,
          dueAt: c.window.dueAt,
          expiresAt: c.window.pushExpiresAt,
          windowClosesAt:
            c.window.context === 'retrospective'
              ? now.getTime() + 14 * ENG_DAY
              : c.window.windowClosesAt,
          sourceData: {
            occasion,
            templateId: c.template.id,
            templateVersion: c.template.version,
            recipient: c.recipient,
            occasionDate: c.window.date,
          },
        },
        now,
      );
    }
  if (config.on('engagementWeeklyEnabled') && ['coParent', 'relative'].includes(scope.role)) {
    const today = localDateIn(scope.zone, now),
      dow = new Date(`${today}T12:00:00Z`).getUTCDay(),
      end = addDaysIso(today, -((dow + 6) % 7)),
      start = addDaysIso(end, -7);
    const content = await weeklySource(db, r.babyId, scope, start, end),
      dueAt = reminderInstantIn(scope.zone, end, '09:00').getTime();
    if ((content.media.length || content.stories.length) && now.getTime() < dueAt + 2 * ENG_DAY)
      await upsertEngagement(
        db,
        {
          ...base(uid, r.babyId, scope, now),
          kind: 'ENG-03',
          source: `week:${start}`,
          context: 'current',
          dueAt,
          expiresAt: dueAt + 2 * ENG_DAY,
          windowClosesAt: dueAt + 2 * ENG_DAY,
          sourceData: { start, end },
        },
        now,
      );
  }
  await scheduleDailySuggestion(db, uid, r.babyId, r.deviceId, scope, config, now);
}

/**
 * D-099: "Gợi ý mỗi ngày" (ENG-06) is a server push at the person's chosen time
 * (`settings/personalization.digestTime`, 20:30 until chosen), every day, whether or not the app
 * was opened: the next slot (today, or tomorrow once today's has passed) is queued here, from the
 * app's refresh and from the hourly [dailySuggestionScheduler]. What it suggests is decided at
 * send time ([validateEngagementSource]); a day with nothing to suggest sends nothing. The
 * "Hôm nay của bé" device switch (`personalizationDelivery`) no longer gates it (D-098 defaults).
 */
export async function scheduleDailySuggestion(
  db: Firestore,
  uid: string,
  babyId: string,
  deviceId: string,
  scope: Scope,
  config: Config,
  now: Date,
) {
  if (!config.on('engagementLumiEnabled') || !['coParent', 'caregiver'].includes(scope.role))
    return;
  const chosen = (await db.doc(`users/${uid}/settings/personalization`).get()).get('digestTime');
  const time =
    typeof chosen === 'string' && /^([01]\d|2[0-3]):[0-5]\d$/.test(chosen) ? chosen : '20:30';
  let date = localDateIn(scope.zone, now);
  let dueAt = reminderInstantIn(scope.zone, date, time).getTime();
  if (dueAt <= now.getTime()) {
    date = addDaysIso(date, 1);
    dueAt = reminderInstantIn(scope.zone, date, time).getTime();
  }
  // Held through quiet hours or a slow tick, it still goes the same morning or evening.
  const expiresAt = dueAt + 3 * 3_600_000;
  const queued = await upsertEngagement(
    db,
    {
      ...base(uid, babyId, scope, now),
      kind: 'ENG-06',
      source: `daily:${date}`,
      context: 'current',
      dueAt,
      expiresAt,
      windowClosesAt: expiresAt,
      sourceData: { deviceId, date, time },
    },
    now,
  );
  // A changed clock or a new install moves the not-yet-sent slot instead of adding a second one.
  if (
    queued &&
    !queued.sentAt &&
    ['eligible', 'scheduled', 'in_app_only'].includes(queued.status) &&
    (queued.dueAt !== dueAt || queued.sourceData.deviceId !== deviceId)
  )
    await db.doc(`engagementIntents/${queued.id}`).update({
      dueAt,
      expiresAt,
      windowClosesAt: expiresAt,
      nextAt: dueAt,
      'sourceData.deviceId': deviceId,
      'sourceData.time': time,
    });
}
/**
 * D-099: the hourly pass that queues tomorrow's (or today's) daily suggestion for every install
 * holding a live ENG-06 push lease, so the push no longer depends on the app being opened
 * before the chosen time. Opted-out people (Gợi ý thông minh or its ENG-06 row) are skipped;
 * the send-time checks run again in the tick.
 */
export async function scheduleDailySuggestions(db: Firestore, now: Date) {
  const { engagementPreferencesSchema } = await import('@child-life/contracts');
  const leases = await db
    .collectionGroup('settings')
    .where('handoffKinds', 'array-contains', 'ENG-06')
    .get();
  let queued = 0;
  for (const lease of leases.docs) {
    const uid = lease.ref.parent.parent?.id;
    const babyId = lease.get('babyId') as string | undefined;
    const deviceId = lease.get('deviceId') as string | undefined;
    if (
      lease.id !== 'engagementDevice' ||
      !uid ||
      !babyId ||
      !deviceId ||
      lease.get('pushAllowed') !== true ||
      !(Number(lease.get('validUntil')) > now.getTime())
    )
      continue;
    try {
      const pref = await db.doc(`users/${uid}/settings/engagement`).get();
      const prefs = engagementPreferencesSchema.parse(pref.get('preferences') ?? {});
      if (!prefs.consent || !prefs.kinds['ENG-06']) continue;
      const scope = await engagementScope(db, uid, babyId, now);
      const config = await engagementConfig(db, scope.familyId);
      await scheduleDailySuggestion(db, uid, babyId, deviceId, scope, config, now);
      queued++;
    } catch {
      // Not a member any more, or a transient read: the next hour or the app's refresh retries.
    }
  }
  return { leases: leases.size, queued };
}

/** One campaign evidence read per baby for a whole pass (reconcile, refresh), not per intent. */
export type EngagementEvidenceCache = Map<string, ReturnType<typeof campaignEvidence>>;
export async function validateEngagementSource(
  db: Firestore,
  i: EngagementIntent,
  now: Date,
  cache?: EngagementEvidenceCache,
): Promise<{
  state: 'ready' | 'resolved' | 'unknown';
  route: string | null;
  completed?: boolean;
  completedAt?: number;
  pushRecipient?: boolean;
}> {
  const unknown = { state: 'unknown' as const, route: null };
  let scope: Scope;
  try {
    scope = await engagementScope(db, i.uid, i.babyId, now);
  } catch (error) {
    // Lost membership resolves; a transient read error is unknown and must not cancel for good.
    if (error instanceof AccountError) return { state: 'resolved', route: null };
    return unknown;
  }
  const resolved = (completed = false, completedAt = now.getTime()) => ({
    state: 'resolved' as const,
    route: null,
    completed,
    completedAt,
  });
  if (i.kind === 'ENG-01') {
    if (scope.role !== 'coParent') return resolved();
    const proof = i.sourceData,
      route = '/memories/auto-save/review';
    // Cloud completion is proved from real approved batch IDs, not "queue accepted".
    for (const batchId of (proof.approvedBatches ?? []) as string[]) {
      const rows = await db
        .collection(`babies/${i.babyId}/media`)
        .where('batchId', '==', batchId)
        .limit(100)
        .get();
      const ready = rows.docs.find(
        (d) =>
          d.get('createdBy') === i.uid &&
          d.get('status') === 'ready' &&
          d.get('deleted') !== true &&
          analyticsTime(d.get('readyAt')) >= i.eligibleAt,
      );
      if (ready) return resolved(true, analyticsTime(ready.get('readyAt')) || now.getTime());
    }
    if (proof.state === 'resolved')
      return (proof.approvedBatches as unknown[] | undefined)?.length ? unknown : resolved();
    if (proof.state !== 'pending' || Number(proof.proofAt) < now.getTime() - 30 * 60_000)
      return unknown;
    return { state: 'ready', route };
  }
  if (i.kind === 'ENG-02') {
    if (scope.role !== 'coParent') return resolved();
    const occasion = i.sourceData.occasion as (typeof campaignKinds)[number];
    if (!campaignKinds.includes(occasion)) return unknown;
    let evidence = cache?.get(i.babyId);
    if (cache && !evidence) cache.set(i.babyId, (evidence = campaignEvidence(db, i.babyId)));
    const c = await campaignSource(db, i.uid, i.babyId, occasion, now, scope, evidence);
    if (!c) return unknown;
    if (c.resolved) return resolved(c.videoCompleted, c.completedAt);
    if (c.blocked || !c.completeHistory || !c.template) return unknown;
    if (c.window.date !== i.sourceData.occasionDate) return unknown; // DOB/timezone edit never creates a second campaign key.
    if (i.context === 'current' && c.window.context === 'retrospective') return resolved();
    return {
      state: 'ready',
      route: `/memories/video?occasion=${occasion}`,
      pushRecipient: c.recipient === i.uid,
    };
  }
  if (i.kind === 'ENG-03') {
    if (!['coParent', 'relative'].includes(scope.role)) return resolved();
    const c = await weeklySource(
      db,
      i.babyId,
      scope,
      String(i.sourceData.start),
      String(i.sourceData.end),
    );
    return c.media.length || c.stories.length
      ? { state: 'ready', route: `/memories?week=${i.sourceData.start}&engagement=${i.id}` }
      : resolved();
  }
  if (i.kind === 'ENG-05') {
    const ids = (i.sourceData.inboxIds ?? []) as string[];
    if (!ids.length) return resolved();
    const docs = await db.getAll(...ids.map((id) => db.doc(`users/${i.uid}/notifications/${id}`)));
    for (const d of docs)
      if (d.exists && !d.get('archivedAt') && !d.get('readAt') && d.get('babyId') === i.babyId) {
        // The transaction's original source must still exist; shared audience is checked anew.
        const data = d.get('data') ?? {};
        const collection = data.sourceCollection,
          key = data.sourceId;
        if (
          typeof key !== 'string' ||
          !/^[A-Za-z0-9_-]{1,128}$/.test(key) ||
          !['messages', 'media', 'albums', 'stories', 'uploadBatches'].includes(collection)
        )
          continue;
        if (collection === 'uploadBatches') {
          const items = await db
            .collection(`babies/${i.babyId}/media`)
            .where('batchId', '==', key)
            .limit(100)
            .get();
          if (
            items.docs.some(
              (m) => m.get('createdBy') !== i.uid && visibleMedia(scope.role, m.data()),
            )
          )
            return { state: 'ready', route: '/memories' };
          continue;
        }
        const source = await db.doc(`babies/${i.babyId}/${collection}/${key}`).get();
        if (!source.exists || source.get('deleted') === true) continue;
        if (collection === 'messages') {
          if (scope.role === 'coParent' && source.get('from') !== i.uid)
            return { state: 'ready', route: '/messages' };
          continue;
        }
        const shared =
          scope.role === 'coParent' ||
          (scope.role === 'relative' &&
            (source.get('effectiveAudience') ?? source.get('audience')) === 'family');
        if (!shared) continue;
        if (collection === 'stories' && source.get('status') !== 'saved') continue;
        return {
          state: 'ready',
          route:
            collection === 'albums'
              ? `/memories/album/${key}`
              : collection === 'stories'
                ? `/story/${key}`
                : '/memories',
        };
      }
    return resolved();
  }
  if (i.kind === 'ENG-06') {
    // D-099: what to suggest is read now; nothing to suggest (a health day, "bận", too few
    // records, no activity) ends the slot without a push.
    const s = await personalizedDay(
      db,
      i.uid,
      { babyId: i.babyId, locale: 'vi' },
      now,
      serverGrantEnvironment(),
    );
    const activity = s.activityIds[0];
    if (
      !s.writable ||
      s.health ||
      s.context === 'busy' ||
      s.lastRecords.length < 3 ||
      !activity ||
      Date.parse(s.expiresAt) <= now.getTime()
    )
      return resolved();
    // The push names today's activity ([engagementCopyValues] reads it from the intent).
    if (i.sourceData.activity !== activity) {
      i.sourceData.activity = activity;
      await db.doc(`engagementIntents/${i.id}`).update({ 'sourceData.activity': activity });
    }
    return { state: 'ready', route: '/rhythm/day' };
  }
  return unknown;
}

/** Existing inbox delivery remains transactional; optional ENG-05 recap is a distinct opt-in. */
export async function familyEngagementFromInbox(
  db: Firestore,
  uid: string,
  id: string,
  data: DocumentData,
  now: Date,
) {
  if (
    !['shared', 'album', 'story', 'message', 'memories'].includes(String(data.kind)) ||
    !data.babyId ||
    data.data?.engagementId
  )
    return;
  const scope = await engagementScope(db, uid, data.babyId, now),
    config = await engagementConfig(db, scope.familyId);
  if (!config.enabled) return;
  await engagementTransactionObserved(db, uid, data.babyId, now);
  if (!config.on('engagementFamilyEnabled')) return;
  const sourceAt = analyticsTime(data.createdAt) || now.getTime();
  if (sourceAt + ENG_DAY <= now.getTime()) return;
  const source = `family:${Math.floor(sourceAt / (30 * 60_000))}`;
  const i = await upsertEngagement(
    db,
    {
      ...base(uid, data.babyId, scope, now),
      kind: 'ENG-05',
      source,
      context: 'current',
      dueAt: sourceAt + 30 * 60_000,
      expiresAt: sourceAt + ENG_DAY,
      windowClosesAt: sourceAt + ENG_DAY,
      sourceData: { inboxIds: [id] },
    },
    now,
  );
  if (i)
    await db.runTransaction(async (tx) => {
      const ref = db.doc(`engagementIntents/${i.id}`),
        d = await tx.get(ref);
      if ((d.get('sourceData.inboxIds') ?? []).length < 50)
        tx.update(ref, { 'sourceData.inboxIds': FieldValue.arrayUnion(id) });
    });
}
