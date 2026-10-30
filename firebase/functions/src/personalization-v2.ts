import { createHash } from 'node:crypto';
import { FieldValue, Timestamp, type Firestore } from 'firebase-admin/firestore';
import {
  activeAt,
  addDaysIso,
  ageCardFor,
  cardAgeDays,
  dailyContexts,
  dayBoundsIn,
  daysBetweenIso,
  familyCan,
  feedbackMemory,
  localDateIn,
  nextLocalDay,
  nextLocalWeek,
  nextWorkState,
  personalizationDayRequestSchema,
  personalizationDigestRequestSchema,
  personalizationMutationSchema,
  recommend,
  responseSuppresses,
  routinePatterns,
  reminderInstantIn,
  recFeedbackSchema,
  defaultUserPreferences,
  weeklyFocuses,
  type FeedbackKind,
  type GrantEnvironment,
  type NotebookNote,
  type PersonalizationState,
  type PersonalResponse,
} from '@child-life/contracts';
import { checkCapability, gateError, loadEntitlementContext } from './entitlements.js';
import {
  readFeedback,
  readPreferences,
  readRhythmContent,
  readRhythmRules,
  sleepFacts,
  RhythmError,
  type FeedbackRow,
} from './rhythm.js';

/** P-172 G/H/I: callable-only writes, current membership on every read and transactional write. */
async function scope(db: Firestore, uid: string, babyId: string, now: Date, env: GrantEnvironment) {
  const ctx = await loadEntitlementContext(db, uid, babyId, now, env);
  const access = checkCapability(ctx, 'wonder.reference', now, 'history.read');
  if (!access.allowed) throw gateError(access.reason);
  const baby = await db.doc(`babies/${babyId}`).get();
  if (!baby.exists || baby.get('state') === 'deleting')
    throw new RhythmError('failed-precondition', 'deleting');
  return { ctx, zone: (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh' };
}
const iso = (v: unknown) =>
  v instanceof Timestamp
    ? v.toDate().toISOString()
    : typeof v === 'string' && Number.isFinite(Date.parse(v))
      ? v
      : null;
const stateRef = (db: Firestore, uid: string, baby: string) =>
  db.doc(`users/${uid}/personalization/${baby}`);

/**
 * P-172 (audit 2026-10-21 P2 #6): the module feedback ("Mình sẽ thử", AC02 "Có ích" / "Chưa thấy
 * rõ") an answer on this screen also writes, so `feedbackMemory` ranks from both screens.
 */
const householdFeedback: Partial<Record<PersonalResponse['value'], FeedbackKind>> = {
  intend: 'started',
  helpful: 'helpful',
  unsure: 'unsure',
};

interface WorkClaim {
  state: string;
  actorUid: string | null;
  revision: number;
}
/**
 * P-172 (audit 2026-10-21 P2 #5): the reminder is the truth. A claim left `completed` after
 * "Hoàn tác" in Nhắc việc reopened the reminder reads as unclaimed (same revision), so the work
 * comes back and can be accepted again.
 */
function liveClaim(claim: Partial<WorkClaim> | undefined, reminderDone: boolean): WorkClaim {
  const revision = claim?.revision ?? 0;
  return !claim?.state || (claim.state === 'completed' && !reminderDone)
    ? { state: 'unclaimed', actorUid: null, revision }
    : { state: claim.state, actorUid: claim.actorUid ?? null, revision };
}

export async function updatePersonalization(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
  env: GrantEnvironment,
) {
  const parsed = personalizationMutationSchema.safeParse(data);
  if (!parsed.success) throw new RhythmError('invalid-argument', 'bad-request');
  const { babyId, action } = parsed.data;
  const { ctx, zone } = await scope(db, uid, babyId, now, env);
  if (!ctx.member || !familyCan(ctx.member, 'rhythm.feedback')) throw gateError('ROLE_DENIED');
  const parent = ctx.member.role === 'coParent';
  const at = now.toISOString();
  const activity =
    action.kind === 'respond'
      ? (await readRhythmContent(db))?.activities.find((a) => a.id === action.contentId)
      : undefined;
  // Read all transactional documents before any write; retries recheck access and revision.
  await db.runTransaction(async (tx) => {
    const [member, baby, personal] = await Promise.all([
      tx.get(db.doc(`babies/${babyId}/members/${uid}`)),
      tx.get(db.doc(`babies/${babyId}`)),
      tx.get(stateRef(db, uid, babyId)),
    ]);
    if (
      member.get('status') !== 'active' ||
      !['coParent', 'caregiver'].includes(member.get('role') as string) ||
      baby.get('state') === 'deleting'
    )
      throw gateError('ROLE_DENIED');
    const isParent = parent && member.get('role') === 'coParent';
    const state = (personal.data() ?? {}) as PersonalizationState;
    // P-172 (audit 2026-10-21 P1 #3): only writes that change what the family shares move
    // the facts version (shared notes, work transitions, family exclusions). Per-person state
    // and the routine switch never mark the AI handover stale or refetch every device.
    let shared = false;
    switch (action.kind) {
      case 'context':
        tx.set(
          personal.ref,
          { context: { value: action.value, expiresAt: nextLocalDay(zone, now) } },
          { merge: true },
        );
        break;
      case 'focus':
        tx.set(
          personal.ref,
          {
            focus: action.value
              ? { value: action.value, expiresAt: nextLocalWeek(zone, now) }
              : null,
          },
          { merge: true },
        );
        break;
      case 'routine':
        if (!isParent) throw gateError('ROLE_DENIED');
        tx.set(db.doc(`babies/${babyId}/personalization/routine`), {
          unusual: action.unusual,
          expiresAt: nextLocalDay(zone, now),
          authorUid: uid,
          updatedAt: at,
        });
        break;
      case 'respond': {
        const previous = state.responses?.[action.contentId];
        // P-172 (audit 2026-10-21 P2 #4): a work card on Home can only be put off until tonight
        // (or restored), and only for this person.
        const work = action.contentId.startsWith('work:');
        if (work && (action.scope === 'baby' || !['snooze', 'restore'].includes(action.value)))
          throw new RhythmError('invalid-argument', 'bad-request');
        if (['helpful', 'unsure'].includes(action.value) && !previous?.triedAt)
          throw new RhythmError('failed-precondition', 'try-first');
        if (action.scope === 'baby' && (action.value !== 'restore' || !isParent))
          throw gateError('ROLE_DENIED');
        if (action.value === 'exclude' && !isParent) throw gateError('ROLE_DENIED');
        if (action.value === 'exclude' && !activity)
          throw new RhythmError('invalid-argument', 'unknown-activity');
        const exclusion = db.doc(`babies/${babyId}/personalizationExclusions/${action.contentId}`);
        if (action.value === 'restore' && action.scope === 'baby') {
          tx.delete(exclusion);
          shared = true;
          break;
        }
        const responses = { ...state.responses };
        if (action.value === 'restore') {
          // Restoring visibility does not erase an attempt or a saved favourite.
          responses[action.contentId] = { ...previous, value: 'restore', at, until: null };
        } else {
          // Whole-map write (not recursive merge) makes restore reliable and bounds storage.
          // Saving and unsaving only flip `saved`; the person's last answer stays.
          const saving = action.value === 'save' || action.value === 'unsave';
          const response: PersonalResponse = {
            value: saving ? (previous?.value ?? 'save') : action.value,
            at,
            until: ['snooze', 'tried', 'helpful'].includes(action.value)
              ? dayBoundsIn(
                  zone,
                  addDaysIso(localDateIn(zone, now), action.value === 'snooze' && !work ? 2 : 0),
                ).end.toISOString()
              : null,
            saved:
              action.value === 'save'
                ? true
                : action.value === 'unsave'
                  ? false
                  : (previous?.saved ?? false),
            ...(previous?.intendedAt ? { intendedAt: previous.intendedAt } : {}),
            ...(previous?.triedAt ? { triedAt: previous.triedAt } : {}),
            ...(previous?.outcome
              ? { outcome: previous.outcome, outcomeAt: previous.outcomeAt }
              : {}),
            ...(action.value === 'intend' ? { intendedAt: at } : {}),
            ...(action.value === 'tried' ? { triedAt: at } : {}),
          };
          if (action.value === 'intend') {
            delete response.triedAt;
            delete response.outcome;
            delete response.outcomeAt;
          }
          if (action.value === 'helpful' || action.value === 'unsure') {
            response.outcome = action.value;
            response.outcomeAt = at;
          }
          responses[action.contentId] = response;
          if (action.value === 'exclude') {
            tx.set(exclusion, { authorUid: uid, at, active: true });
            shared = true;
          }
        }
        // A work card's snooze ends tonight; spent ones are dropped so they never fill the limit.
        for (const [id, r] of Object.entries(responses))
          if (id.startsWith('work:') && !responseSuppresses(r, now)) delete responses[id];
        if (Object.keys(responses).length > 200)
          throw new RhythmError('failed-precondition', 'response-limit');
        tx.set(personal.ref, { ...state, responses });
        // P-172 (audit 2026-10-21 P2 #6): the household row the ranking and the AI summary read,
        // the same document the activity screen writes (Rules `validNewFeedback`). `responses`
        // above only decides what this person sees. The id is fixed per answer, so a retried
        // transaction writes it once; `onRecFeedbackWrite` moves the facts version, as for the app.
        const kind = householdFeedback[action.value];
        if (activity && kind && previous?.value !== action.value) {
          const id = `fb_${createHash('sha256')
            .update(`personal|${uid}|${activity.id}|${action.value}|${at}`)
            .digest('hex')
            .slice(0, 32)}`;
          tx.set(db.doc(`babies/${babyId}/recFeedback/${id}`), {
            ...recFeedbackSchema.parse({
              id,
              babyId,
              authorUid: uid,
              contentId: activity.id,
              contentVersion: activity.version,
              kind,
              date: localDateIn(zone, now),
              note: null,
            }),
            createdAt: FieldValue.serverTimestamp(),
          });
        }
        if (
          activity &&
          (action.value === 'save'
            ? previous?.saved !== true
            : action.value === 'unsave'
              ? previous?.saved === true
              : previous?.value !== action.value)
        ) {
          tx.set(
            db.doc(`contentStatsDaily/${localDateIn('Asia/Ho_Chi_Minh', now)}`),
            {
              day: localDateIn('Asia/Ho_Chi_Minh', now),
              answers: {
                [`${activity.id}__v${activity.version}`]: {
                  contentId: activity.id,
                  version: activity.version,
                  [action.value]: FieldValue.increment(1),
                },
              },
            },
            { merge: true },
          );
        }
        break;
      }
      case 'note':
      case 'delete_note': {
        const noteRef = db.doc(`babies/${babyId}/notebook/${action.id}`);
        const old = await tx.get(noteRef);
        const revision = (old.get('revision') as number | undefined) ?? 0;
        if (revision !== action.revision)
          throw new RhythmError('failed-precondition', 'note-conflict');
        if (
          old.exists &&
          old.get('authorUid') !== uid &&
          (!isParent || old.get('scope') === 'person')
        )
          throw gateError('ROLE_DENIED');
        shared = old.get('scope') === 'baby' || (action.kind === 'note' && action.scope === 'baby');
        if (action.kind === 'delete_note') {
          tx.delete(noteRef);
          break;
        }
        if (
          !old.exists &&
          (await tx.get(db.collection(`babies/${babyId}/notebook`).limit(200))).size >= 200
        )
          throw new RhythmError('failed-precondition', 'note-limit');
        if (action.scope === 'baby' && action.category === 'avoid' && !isParent)
          throw gateError('ROLE_DENIED');
        if (action.avoidActivityId && (action.category !== 'avoid' || action.scope !== 'baby'))
          throw new RhythmError('invalid-argument', 'invalid-constraint');
        const note: NotebookNote = {
          id: action.id,
          authorUid: (old.get('authorUid') as string | undefined) ?? uid,
          confirmedBy: uid,
          source: action.source ?? 'app',
          text: action.text,
          category: action.category,
          scope: action.scope,
          revision: revision + 1,
          confirmedAt: at,
          expiresAt:
            action.days === null
              ? null
              : dayBoundsIn(
                  zone,
                  addDaysIso(localDateIn(zone, now), action.days - 1),
                ).end.toISOString(),
          avoidActivityId: action.avoidActivityId,
        };
        tx.set(noteRef, note);
        break;
      }
      case 'work': {
        const reminderRef = db.doc(`babies/${babyId}/reminders/${action.reminderId}`);
        const claimRef = db.doc(`babies/${babyId}/careWork/${action.reminderId}`);
        const [reminder, claim] = await Promise.all([tx.get(reminderRef), tx.get(claimRef)]);
        if (!reminder.exists) throw new RhythmError('not-found', 'reminder-not-found');
        if (!isParent && reminder.get('assigneeUid') !== uid) throw gateError('ROLE_DENIED');
        const current = liveClaim(
          claim.exists ? (claim.data() as WorkClaim) : undefined,
          reminder.get('done') === true,
        );
        let next;
        try {
          next = nextWorkState(current, action.transition, uid, isParent);
        } catch {
          throw new RhythmError('failed-precondition', 'work-conflict');
        }
        // Same transition replay is harmless even if the client still has its original version.
        if (next === current) break;
        if (current.revision !== action.revision || reminder.get('done') === true)
          throw new RhythmError('failed-precondition', 'work-conflict');
        tx.set(claimRef, { ...next, reminderId: action.reminderId, updatedAt: at });
        shared = true;
        if (action.transition === 'complete')
          tx.update(reminderRef, {
            done: true,
            doneAt: now,
            doneBy: uid,
            doneAuthor: {
              name: member.get('name') ?? member.get('displayName') ?? '—',
              relation: member.get('relation') ?? 'other',
              relationCustom: member.get('relationCustom') ?? null,
            },
            updatedAt: now,
            updatedBy: uid,
          });
        break;
      }
      case 'acknowledge':
        tx.set(
          personal.ref,
          { acknowledgedAt: at, acknowledgedVersion: action.version ?? null },
          { merge: true },
        );
        break;
      case 'digest':
        if (action.enabled && !action.deviceId)
          throw new RhythmError('invalid-argument', 'device-required');
        {
          const preferences = await tx.get(db.doc(`users/${uid}/settings/personalization`));
          if (action.enabled && !preferences.get('digestTime'))
            tx.set(preferences.ref, {
              ...defaultUserPreferences,
              ...preferences.data(),
              digestTime: '20:30',
              updatedAt: at,
            });
        }
        tx.set(db.doc(`users/${uid}/settings/personalizationDelivery`), {
          enabled: action.enabled,
          deviceId: action.deviceId,
          babyId,
          zone,
          updatedAt: at,
        });
        break;
    }
    tx.set(personal.ref, { babyId }, { merge: true });
    if (shared)
      tx.set(
        db.doc(`babies/${babyId}/facts/state`),
        { dataVersion: FieldValue.increment(1), updatedAt: now },
        { merge: true },
      );
  });
  return { ok: true };
}

/** P-172 B1: one server reservation across installs, for fresh content later TODAY only.
 * A device transfer cannot schedule a second notice on a day reserved by the previous device.
 * The lease is operational child data, never analytics. No claim of OS delivery is made.
 */
export async function reservePersonalizedDigest(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
  env: GrantEnvironment,
) {
  const parsed = personalizationDigestRequestSchema.safeParse(data);
  if (!parsed.success) throw new RhythmError('invalid-argument', 'bad-request');
  const input = parsed.data;
  const snapshot = await personalizedDay(db, uid, { babyId: input.babyId, locale: 'vi' }, now, env);
  const { engagementScope, engagementConfig } = await import('./engagement.js');
  const engagementFamily = await engagementScope(db, uid, input.babyId, now);
  const engagement = await engagementConfig(db, engagementFamily.familyId);
  const previousHandoff =
    (await db.doc(`users/${uid}/settings/engagementState`).get()).get('lumiHandedOff') === true;
  if (previousHandoff || (engagement.enabled && engagement.on('engagementLumiEnabled')))
    return { fireAt: null as string | null };
  const none = { fireAt: null as string | null };
  if (!snapshot.writable || snapshot.health || snapshot.context === 'busy') return none;
  const meaningful = {
    activity: snapshot.activityIds[0] ?? null,
    age: snapshot.ageCardId,
    work: snapshot.work[0]?.id ?? null,
  };
  if (!meaningful.activity && !meaningful.age && !meaningful.work) return none;
  const fingerprint = createHash('sha256').update(JSON.stringify(meaningful)).digest('hex');
  return db.runTransaction(async (tx) => {
    const [delivery, preferences, settings, lease, member, baby] = await Promise.all([
      tx.get(db.doc(`users/${uid}/settings/personalizationDelivery`)),
      tx.get(db.doc(`users/${uid}/settings/personalization`)),
      tx.get(db.doc(`users/${uid}/settings/notifications`)),
      tx.get(db.doc(`users/${uid}/settings/personalizationDigestLease`)),
      tx.get(db.doc(`babies/${input.babyId}/members/${uid}`)),
      tx.get(db.doc(`babies/${input.babyId}`)),
    ]);
    if (
      member.get('status') !== 'active' ||
      baby.get('state') === 'deleting' ||
      delivery.get('enabled') !== true ||
      delivery.get('deviceId') !== input.deviceId ||
      delivery.get('babyId') !== input.babyId ||
      settings.get('rhythm') === false
    )
      return none;
    const zone = delivery.get('zone') as string;
    if (!zone) return none;
    const date = localDateIn(zone, now);
    const time = preferences.get('digestTime') as string | null;
    if (!time || !/^([01]\d|2[0-3]):[0-5]\d$/.test(time)) return none;
    const quiet = preferences.get('quietHours') as { from: string; to: string } | null;
    if (
      quiet &&
      quiet.from !== quiet.to &&
      (quiet.from < quiet.to
        ? time >= quiet.from && time < quiet.to
        : time >= quiet.from || time < quiet.to)
    )
      return none;
    // The existing Sunday summary owns that day's optional suggestion notice.
    if (new Date(`${date}T12:00:00Z`).getUTCDay() === 0 && settings.get('weeklySummary') !== false)
      return none;
    const fireAt = reminderInstantIn(zone, date, time);
    if (fireAt <= now) return none;
    if (lease.get('date') === date) {
      if (lease.get('deviceId') !== input.deviceId) return none;
      const previousFire = Date.parse(String(lease.get('fireAt')));
      if (!Number.isFinite(previousFire) || previousFire <= now.getTime()) return none;
      // P-172 B1 (audit 2026-10-21 P1 #2): new content later the same day keeps the pending
      // slot, because the app cancels any notice this call does not return and the copy is
      // generic. The stored fingerprint follows the content, so tomorrow compares against what
      // tonight's notice announced. The slot moves only when the person changes their clock;
      // the app replaces the same OS notification id rather than creating another one.
      const changed: Record<string, string> = {};
      if (lease.get('fingerprint') !== fingerprint) changed.fingerprint = fingerprint;
      if (previousFire !== fireAt.getTime()) changed.fireAt = fireAt.toISOString();
      if (Object.keys(changed).length > 0) tx.update(lease.ref, changed);
      return { fireAt: fireAt.toISOString() };
    }
    if (lease.get('fingerprint') === fingerprint) return none;
    tx.set(lease.ref, {
      date,
      deviceId: input.deviceId,
      fireAt: fireAt.toISOString(),
      fingerprint,
      babyId: input.babyId,
      reservedAt: now.toISOString(),
    });
    return { fireAt: fireAt.toISOString() };
  });
}

export async function personalizedDay(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
  env: GrantEnvironment,
) {
  const parsed = personalizationDayRequestSchema.safeParse(data);
  if (!parsed.success) throw new RhythmError('invalid-argument', 'bad-request');
  const { babyId, locale } = parsed.data;
  const { ctx, zone } = await scope(db, uid, babyId, now, env);
  const today = localDateIn(zone, now);
  const parent = ctx.member?.role === 'coParent';
  const writable = ctx.member !== null && familyCan(ctx.member, 'rhythm.feedback');
  const [
    personal,
    prefs,
    content,
    profile,
    notesSnap,
    routine,
    exclusionSnap,
    checkins,
    records,
    conflicts,
    timer,
    reminderSnap,
    delivery,
  ] = await Promise.all([
    stateRef(db, uid, babyId).get(),
    readPreferences(db, uid),
    readRhythmContent(db),
    db.doc(`babies/${babyId}/restricted/profile`).get(),
    db.collection(`babies/${babyId}/notebook`).limit(200).get(),
    db.doc(`babies/${babyId}/personalization/routine`).get(),
    db.collection(`babies/${babyId}/personalizationExclusions`).get(),
    db.collection(`babies/${babyId}/checkins`).where('date', '==', today).get(),
    db
      .collection(`babies/${babyId}/records`)
      .where('occurredAt', '>=', new Date(now.getTime() - 14 * 86_400_000))
      .orderBy('occurredAt', 'desc')
      .limit(1500)
      .get(),
    db.collection(`babies/${babyId}/conflicts`).where('status', '==', 'open').limit(1).get(),
    db.doc(`babies/${babyId}/timers/sleep`).get(),
    // P-172 (audit 2026-10-21 P2 #4): work due today or overdue by less than 24 h, never a
    // reminder forgotten weeks ago (same `done` + `dueAt` index as before).
    writable
      ? db
          .collection(`babies/${babyId}/reminders`)
          .where('done', '==', false)
          .where('dueAt', '>', new Date(now.getTime() - 86_400_000))
          .where('dueAt', '<', dayBoundsIn(zone, today).end)
          .orderBy('dueAt')
          .limit(100)
          .get()
      : null,
    db.doc(`users/${uid}/settings/personalizationDelivery`).get(),
  ]);
  const state = (personal.data() ?? {}) as PersonalizationState & {
    acknowledgedAt?: string;
    acknowledgedVersion?: string;
  };
  // P-172 (audit 2026-10-21 P2 #7): a choice dropped after it was stored reads as none.
  const context =
    state.context &&
    activeAt(state.context.expiresAt, now) &&
    dailyContexts.includes(state.context.value)
      ? state.context.value
      : 'usual';
  const focus =
    state.focus && activeAt(state.focus.expiresAt, now) && weeklyFocuses.includes(state.focus.value)
      ? state.focus.value
      : null;
  const unusual =
    routine.get('unusual') === true && activeAt(routine.get('expiresAt') as string, now);
  const health = checkins.docs.some(
    (d) =>
      (d.get('healthSigns') as unknown[] | undefined)?.length || d.get('observation') === 'health',
  );
  const visibleNotes = notesSnap.docs
    .map((d) => d.data() as NotebookNote)
    .filter((n) => n.scope === 'baby' || n.authorUid === uid);
  const notes = visibleNotes.filter((n) => activeAt(n.expiresAt, now));
  const expiredNotes = visibleNotes.filter((n) => !activeAt(n.expiresAt, now));
  const excluded = new Set(
    exclusionSnap.docs.filter((d) => d.get('active') === true).map((d) => d.id),
  );
  for (const n of notes)
    if (n.scope === 'baby' && n.avoidActivityId) excluded.add(n.avoidActivityId);
  for (const [id, response] of Object.entries(state.responses ?? {}))
    if (responseSuppresses(response, now)) excluded.add(id);
  const dob = (profile.get('dateOfBirth') as string | undefined)?.slice(0, 10);
  const ageDays = dob && dob <= today ? daysBetweenIso(dob, today) : null;
  const rules = await readRhythmRules(db);
  const advanced = checkCapability(ctx, 'rhythm.advanced', now).allowed;
  const feedback = advanced ? await readFeedback(db, babyId) : [];
  const needDoc = checkins.docs
    .filter((d) =>
      ['sleep', 'feeding', 'soothing', 'new_skill'].includes(d.get('observation') as string),
    )
    .sort((a, b) =>
      (iso(b.get('updatedAt')) ?? '').localeCompare(iso(a.get('updatedAt')) ?? ''),
    )[0];
  const need = needDoc?.get('observation') as
    'sleep' | 'feeding' | 'soothing' | 'new_skill' | undefined;
  const crossModule = checkCapability(ctx, 'personalization.cross_module', now).allowed;
  const ranked =
    content && ageDays !== null && crossModule
      ? recommend({
          locale,
          today,
          ageDays,
          need: need === 'new_skill' ? 'milestone' : (need ?? (focus === 'play' ? 'play' : null)),
          interests: prefs.interests,
          fewer: prefs.fewer,
          country: ctx.family.country,
          healthFlag: health,
          memory: feedbackMemory(feedback, rules.cooldownDays),
          activities: content.activities.filter(
            (a) =>
              !excluded.has(a.id) &&
              ((context !== 'few_minutes' && context !== 'busy') || a.durationMin <= 5),
          ),
        })
      : null;
  const liveRecords = records.docs
    .filter(
      (d) =>
        d.get('deleted') !== true &&
        ['bottle', 'breast', 'sleep', 'pump', 'diaper'].includes(d.get('type') as string),
    )
    .flatMap((d) => {
      const at = iso(d.get('occurredAt'));
      return at
        ? [
            {
              id: d.id,
              type: String(d.get('type')),
              at,
              end: iso(d.get('endedAt')),
              ...(typeof d.get('data.amountMl') === 'number'
                ? { amountMl: d.get('data.amountMl') as number }
                : {}),
            },
          ]
        : [];
    });
  const patterns =
    !health && !unusual && conflicts.empty && !timer.exists && records.size < 1500
      ? routinePatterns(liveRecords, now, zone)
      : [];
  // P-172 (audit 2026-10-21 P2 #4): the viewer's own work and unassigned work only.
  const reminders = (reminderSnap?.docs ?? []).filter((r) =>
    [null, uid].includes((r.get('assigneeUid') as string | null | undefined) ?? null),
  );
  const claimRows =
    reminders.length > 0
      ? await db.getAll(...reminders.map((r) => db.doc(`babies/${babyId}/careWork/${r.id}`)))
      : [];
  const work = reminders
    .map((r) => {
      // Every listed reminder is open, so a `completed` claim is one "Hoàn tác" reopened (P2 #5).
      const claim = liveClaim(claimRows.find((c) => c.id === r.id)?.data(), false);
      return {
        id: r.id,
        title: String(r.get('title') ?? ''),
        dueAt: iso(r.get('dueAt')),
        assigneeUid: r.get('assigneeUid') ?? null,
        ...claim,
        canAct: parent || r.get('assigneeUid') === uid,
      };
    })
    .sort((a, b) => (a.dueAt ?? '').localeCompare(b.dueAt ?? ''));
  const weekStart = addDaysIso(today, -6);
  const lastRecords = [
    ...new Map([...liveRecords].reverse().map((r) => [r.type, r])).values(),
  ].sort((a, b) => b.at.localeCompare(a.at));
  const handoverVersion = createHash('sha256')
    .update(
      JSON.stringify({
        records: lastRecords,
        notes: notes.filter((n) => n.scope === 'baby'),
        work,
      }),
    )
    .digest('hex');
  const responses = state.responses ?? {};
  // P-172 (audit 2026-10-21 P2 #6): "đã thử / có ích" counts this person's answers from both
  // screens once per activity: `responses` here and their own household feedback (AC02 on the
  // activity screen; this screen writes both). The latest outcome per activity wins.
  const weekFeedback: Pick<FeedbackRow, 'authorUid' | 'contentId' | 'kind' | 'createdAtMs'>[] = (
    advanced
      ? feedback.filter((f) => f.date >= weekStart)
      : (
          await db
            .collection(`babies/${babyId}/recFeedback`)
            .where('date', '>=', weekStart)
            .limit(300)
            .get()
        ).docs.flatMap((d) => {
          const row = recFeedbackSchema.safeParse(d.data());
          const created = d.get('createdAt') as unknown;
          return row.success
            ? [{ ...row.data, createdAtMs: created instanceof Timestamp ? created.toMillis() : 0 }]
            : [];
        })
  ).filter((f) => f.authorUid === uid);
  const inWeek = (at: string | undefined) =>
    !!at && Number.isFinite(Date.parse(at)) && localDateIn(zone, new Date(at)) >= weekStart;
  const outcomes = new Map<string, { kind: string; at: number }>();
  const outcome = (id: string, kind: string, at: number) => {
    if (at >= (outcomes.get(id)?.at ?? -Infinity)) outcomes.set(id, { kind, at });
  };
  for (const [id, r] of Object.entries(responses)) {
    const kind = r.outcome ?? (r.value === 'helpful' ? 'helpful' : null);
    const at = r.outcomeAt ?? r.at;
    if (kind && inWeek(at)) outcome(id, kind, Date.parse(at));
  }
  for (const f of weekFeedback)
    if (f.kind === 'helpful' || f.kind === 'unsure') outcome(f.contentId, f.kind, f.createdAtMs);
  const tried = new Set([
    ...Object.entries(responses)
      .filter(([, r]) => inWeek(r.triedAt))
      .map(([id]) => id),
    ...outcomes.keys(),
  ]);
  const sleep = !health && advanced ? await sleepFacts(db, babyId, zone, today, now, rules) : null;
  return {
    asOf: now.toISOString(),
    contentVersion: content?.version ?? null,
    expiresAt: nextLocalDay(zone, now),
    today,
    zone,
    writable,
    parent,
    health,
    context,
    focus,
    unusual,
    notes,
    expiredNotes,
    responses,
    sharedExclusions: parent
      ? exclusionSnap.docs
          .filter((d) => d.get('active') === true)
          .map((d) => ({ id: d.id, authorUid: d.get('authorUid'), at: d.get('at') }))
      : [],
    patterns,
    sleep,
    activityIds:
      ranked?.kind === 'suggestion'
        ? [ranked.primary, ...ranked.secondary]
            .slice(0, context === 'busy' ? 1 : 3)
            .map((a) => a.id)
        : [],
    // P-172 (audit 2026-10-21 P2 #7): the reason recommend() gave for this pick. WEEKLY_FOCUS only
    // when the "play" focus stood in for a need nobody reported; none without a suggestion.
    reason:
      ranked?.kind === 'suggestion'
        ? ranked.reasonCode === 'SELF_REPORTED_NEED' && !need
          ? 'WEEKLY_FOCUS'
          : ranked.reasonCode
        : null,
    ageCardId:
      content && dob && ageDays !== null
        ? (ageCardFor(
            content.ageCards,
            cardAgeDays(dob, (profile.get('dueDate.date') as string | undefined) ?? null, today),
          )?.id ?? null)
        : null,
    work,
    lastRecords,
    acknowledgedAt: state.acknowledgedAt ?? null,
    handoverVersion,
    handoverChanged:
      state.acknowledgedVersion != null && state.acknowledgedVersion !== handoverVersion,
    weekly: {
      tried: tried.size,
      helpful: [...outcomes.values()].filter((o) => o.kind === 'helpful').length,
    },
    delivery: delivery.exists ? delivery.data() : null,
  };
}
