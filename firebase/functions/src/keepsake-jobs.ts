import { freezeKeepsakePresentation } from '@child-life/contracts';
import { createHash } from 'node:crypto';
import {
  fillName,
  dayBoundsIn,
  localDateIn,
  keepsakeAgeLabel,
  keepsakeBirthStats,
  type KeepsakeTextKey,
  flagsSchema,
  keepsakePublicCatalogSchema,
  keepsakeJobLimits,
  keepsakeJobLiveSchema,
  keepsakeNeedsPremiumCheck,
  keepsakeTemplateAccess,
  limitsSchema,
  defaultLimits,
  memoryStoryRequestSchema,
  memoryStoryRetrySchema,
  occasions,
  familyCan,
  videoQuotaRequestSchema,
  type VideoQuotaAnswer,
  type GrantEnvironment,
  type MemoryStoryAnswer,
  type MemberRole,
  type KeepsakeJobErrorCode,
  type KeepsakeJobInput,
  type KeepsakeLiveState,
  type KeepsakeTemplate,
} from '@child-life/contracts';
import { FieldValue, Timestamp, type Firestore } from 'firebase-admin/firestore';
import {
  familyFeatureEnabled,
  hasPremiumTemplates,
  readEntitlementsConfig,
  serverGrantEnvironment,
} from './entitlements.js';
import { mediaPaths, type ImageOps, type MediaStore } from './memories.js';
import {
  countersAfter,
  readForSettle,
  readVideoQuota,
  reserveInTx,
  settleInTx,
  snapshotOf,
  videoWindowFor,
  windowRef,
  type VideoWindow,
} from './video-quota.js';

/**
 * Video kỷ niệm jobs (D-068; contracts `keepsake-jobs.ts`; plan §5). No baby name, text or path
 * is ever logged: only job ids, template ids, timings and error codes.
 */

export class KeepsakeJobError extends Error {
  constructor(
    readonly code:
      | 'invalid-argument'
      | 'permission-denied'
      | 'not-found'
      | 'failed-precondition'
      | 'resource-exhausted',
    readonly reason: string,
  ) {
    super(reason);
  }
}

/** Hands a job to the renderer (Cloud Tasks in production). */
export interface RenderDispatcher {
  dispatch(babyId: string, jobId: string, attempt: number): Promise<void>;
}

const hex32 = (s: string) => createHash('sha256').update(s).digest('hex').slice(0, 32);
/** The same caller and request always name the same job. */
export const jobIdOf = (uid: string, requestId: string) => `ksj_${hex32(`${uid}|${requestId}`)}`;
/** What a finished job files in Kỷ niệm: always the same ids for the same job. */
export const outputIdsOf = (jobId: string) => ({
  memoryId: `mem_${hex32(`${jobId}|memory`)}`,
  mediaId: `med_${hex32(`${jobId}|media`)}`,
  batchId: `bat_${hex32(`${jobId}|batch`)}`,
});

const jobRef = (db: Firestore, babyId: string, jobId: string) =>
  db.doc(`babies/${babyId}/keepsakeJobs/${jobId}`);

const two = (n: number) => String(n).padStart(2, '0');
const dm = (d: Date) => `${two(d.getUTCDate())}.${two(d.getUTCMonth() + 1)}`;
const dmy = (d: Date) => `${dm(d)}.${d.getUTCFullYear()}`;

/** The occasion's day (UTC calendar date) from the date of birth, or null. */
function occasionDay(dob: string | null, occasion: keyof typeof occasions | null): Date | null {
  if (!dob || !occasion) return null;
  const o = occasions[occasion];
  if (o.kind !== 'age') return null;
  const [y, m, d] = dob.split('-').map(Number) as [number, number, number];
  if ('days' in o) return new Date(Date.UTC(y, m - 1, d + o.days));
  const first = new Date(Date.UTC(y, m - 1 + o.months, 1));
  const last = new Date(Date.UTC(first.getUTCFullYear(), first.getUTCMonth() + 1, 0)).getUTCDate();
  return new Date(Date.UTC(first.getUTCFullYear(), first.getUTCMonth(), Math.min(d, last)));
}

/** MM07 "Tạo video": checks everything, then one job (the same one if asked again). */
export async function requestMemoryStory(
  db: Firestore,
  dispatcher: RenderDispatcher | null,
  uid: string,
  data: unknown,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<MemoryStoryAnswer> {
  const parsed = memoryStoryRequestSchema.safeParse(data);
  if (!parsed.success) throw new KeepsakeJobError('invalid-argument', 'malformed');
  const req = parsed.data;
  const jobId = jobIdOf(uid, req.requestId);
  const ref = jobRef(db, req.babyId, jobId);

  const existing = await ref.get();
  if (existing.exists) {
    if (existing.get('uid') !== uid) throw new KeepsakeJobError('permission-denied', 'taken');
    const familyId = existing.get('familyId') as string;
    const window = await videoWindowFor(
      db,
      familyId,
      req.babyId,
      await readEntitlementsConfig(db),
      environment,
      now,
    );
    return {
      jobId,
      status: existing.get('status') as string,
      quota: await readVideoQuota(db, familyId, window),
    };
  }

  const [member, baby, flagsDoc, catalogDoc] = await Promise.all([
    db.doc(`babies/${req.babyId}/members/${uid}`).get(),
    db.doc(`babies/${req.babyId}`).get(),
    db.doc('config/flags').get(),
    db.doc('publicConfig/keepsakes').get(),
  ]);
  const until = member.get('accessUntilAt') as Timestamp | null | undefined;
  if (
    !member.exists ||
    member.get('status') !== 'active' ||
    member.get('role') !== 'coParent' ||
    (until && until.toMillis() <= now.getTime())
  ) {
    throw new KeepsakeJobError('permission-denied', 'not-allowed');
  }
  if (!baby.exists) throw new KeepsakeJobError('not-found', 'not-found');
  if (baby.get('state') === 'deleting')
    throw new KeepsakeJobError('failed-precondition', 'deleting');
  const familyId = baby.get('familyId') as string;

  // D-068 #3: Video kỷ niệm, per family: its flag, the admin override and the tier (D-089 hub
  // rule, the same answer as `featureAccess`).
  const flags = flagsSchema.safeParse(flagsDoc.data() ?? {});
  if (!(await familyFeatureEnabled(db, familyId, 'memory_story', now, environment))) {
    throw new KeepsakeJobError('failed-precondition', 'not-enabled');
  }
  if (flags.success && !flags.data.media_upload.enabled) {
    throw new KeepsakeJobError('failed-precondition', 'uploads-paused');
  }

  // A published video template, at a version that was published, allowed by Cao cấp (D-068 #8).
  const catalog = keepsakePublicCatalogSchema.safeParse(catalogDoc.data());
  const live = catalog.success
    ? catalog.data.templates.find((t) => t.id === req.templateId)
    : undefined;
  if (!catalog.success || !live || live.kind !== 'video' || req.templateVersion > live.version) {
    throw new KeepsakeJobError('failed-precondition', 'template-unavailable');
  }
  // Cao cấp in `subscribers` mode needs the family's `templates.premium` (Q1, MO02, E03).
  const access = keepsakeTemplateAccess(
    live,
    catalog.data.premium,
    keepsakeNeedsPremiumCheck(live, catalog.data.premium) &&
      (await hasPremiumTemplates(db, uid, req.babyId, now, environment)),
  );
  if (access === 'unavailable') {
    throw new KeepsakeJobError('failed-precondition', 'template-unavailable');
  }
  if (access === 'premium-required') {
    throw new KeepsakeJobError('permission-denied', 'PREMIUM_REQUIRED');
  }
  // An older version still on the phone renders as the published one (only one is kept live).
  const template: KeepsakeTemplate = live;
  // MM07 "Nhạc nền": the parent's pick, none, or the template's default — a published track.
  const musicId = req.musicId === undefined ? template.defaultMusic : req.musicId;
  let musicAsset: string | null = null;
  if (musicId) {
    const track = catalog.data.music.find((m) => m.id === musicId && m.status === 'published');
    if (!track) throw new KeepsakeJobError('failed-precondition', 'music-unavailable');
    musicAsset = track.asset;
  }
  if (req.mediaIds.length < template.photos.min || req.mediaIds.length > template.photos.max) {
    throw new KeepsakeJobError('invalid-argument', 'photo-count');
  }
  for (const [key, value] of Object.entries(req.texts)) {
    const max = template.texts.find((x) => x.key === key)?.max ?? 140;
    if ((value ?? '').length > max) throw new KeepsakeJobError('invalid-argument', 'text-too-long');
  }
  const locale = req.locale ?? 'vi';
  let presentation: KeepsakeJobInput['presentation'];
  if (!!template.personalization !== !!req.presentation) {
    throw new KeepsakeJobError('invalid-argument', 'personalization-required');
  }
  if (template.personalization && req.presentation) {
    try {
      presentation = freezeKeepsakePresentation(template.personalization, req.presentation, locale);
    } catch {
      throw new KeepsakeJobError('invalid-argument', 'personalization-invalid');
    }
  }

  // Every photo is this baby's, ready, not deleted (the Rules gate the app, this the server).
  const items = await db.getAll(
    ...req.mediaIds.map((m) => db.doc(`babies/${req.babyId}/media/${m}`)),
  );
  const photos: string[] = [];
  const takenAt: (Date | null)[] = [];
  let firstPhoto: Date | null = null;
  for (const it of items) {
    if (
      !it.exists ||
      it.get('babyId') !== req.babyId ||
      it.get('type') !== 'photo' ||
      it.get('status') !== 'ready' ||
      it.get('deleted') === true
    ) {
      throw new KeepsakeJobError('failed-precondition', 'photo-unavailable');
    }
    const display =
      (it.get('paths.display') as string | null) ?? (it.get('paths.original') as string | null);
    if (!display) throw new KeepsakeJobError('failed-precondition', 'photo-unavailable');
    photos.push(display);
    const at = (it.get('captureAt') as Timestamp | undefined)?.toDate();
    takenAt.push(at ?? null);
    if (at && (!firstPhoto || at < firstPhoto)) firstPhoto = at;
  }

  // One at a time per baby, a daily cap per family, and room in the quota (D-068 #5).
  const [active, today, family, limitsDoc] = await Promise.all([
    db
      .collection(`babies/${req.babyId}/keepsakeJobs`)
      .where('status', 'in', ['queued', 'rendering'])
      .limit(keepsakeJobLimits.activePerBaby)
      .get(),
    db
      .collectionGroup('keepsakeJobs')
      .where('familyId', '==', familyId)
      .where('createdAt', '>=', new Date(now.getTime() - 24 * 3600_000))
      .count()
      .get(),
    db.doc(`families/${familyId}`).get(),
    db.doc('config/limits').get(),
  ]);
  if (active.size >= keepsakeJobLimits.activePerBaby) {
    throw new KeepsakeJobError('resource-exhausted', 'busy');
  }
  if (today.data().count >= keepsakeJobLimits.perFamilyPerDay) {
    throw new KeepsakeJobError('resource-exhausted', 'daily-limit');
  }
  const limits = limitsSchema.safeParse(limitsDoc.data());
  const quota =
    (family.get('quotaBytes') as number | undefined) ??
    (limits.success ? limits.data : defaultLimits).familyQuotaBytes;
  const used =
    ((family.get('usedBytes') as number | undefined) ?? 0) +
    ((family.get('reservedBytes') as number | undefined) ?? 0);
  if (quota - used < keepsakeJobLimits.estimateBytes) {
    throw new KeepsakeJobError('resource-exhausted', 'quota-full');
  }

  const profile = await db.doc(`babies/${req.babyId}/restricted/profile`).get();
  const dob = (profile.get('dateOfBirth') as string | undefined)?.slice(0, 10) ?? null;
  const name = (baby.get('nickname') as string | undefined) ?? '';
  const day = occasionDay(dob, req.occasion);
  const start = dob ? new Date(`${dob}T00:00:00Z`) : firstPhoto;
  const end = day ?? now;
  const o = req.occasion ? occasions[req.occasion] : null;
  // The big number of age occasions ("7", "1", "100"; 1 tuổi → "1"); none at birth.
  const mark =
    o && o.kind === 'age'
      ? 'days' in o
        ? o.days > 0
          ? String(o.days)
          : null
        : String(o.months === 12 ? 1 : o.months)
      : null;
  const defaultText = (key: KeepsakeTextKey) =>
    fillName(template.texts.find((x) => x.key === key)?.default[locale] ?? '', name);
  // Chapter 01 texts: what the parent wrote, else the template's default, for the keys it offers.
  const extra: Partial<Record<'headline' | 'closing' | 'lines' | 'letter', string>> = {};
  for (const key of ['headline', 'closing', 'lines', 'letter'] as const) {
    if (template.texts.some((x) => x.key === key)) extra[key] = req.texts[key] || defaultText(key);
  }
  // Ages of the photos ("Tháng 3") for timeline videos, in the baby's zone.
  const dayOf = (d: Date) =>
    localDateIn((baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh', d);
  const photoInfo = takenAt.map((at) => ({
    takenAt: at ? at.toISOString() : null,
    label: at ? keepsakeAgeLabel(dob, dayOf(at), locale) : null,
  }));
  // V01: weight and length from the first growth record within a week of birth.
  let birthStats: string | null = null;
  if (dob && template.composition === 'WelcomeWorld') {
    const growth = await db
      .collection(`babies/${req.babyId}/records`)
      .where('type', '==', 'growth')
      .where('deleted', '==', false)
      .orderBy('occurredAt', 'desc')
      .limit(30)
      .get();
    const birth = Date.parse(`${dob}T00:00:00Z`);
    const first = growth.docs
      .map((d) => ({
        on: (d.get('measuredOn') as string | undefined) ?? null,
        w: (d.get('weightKg') as number | null | undefined) ?? null,
        l: (d.get('lengthCm') as number | null | undefined) ?? null,
      }))
      .filter((g) => g.on && Date.parse(`${g.on}T00:00:00Z`) - birth <= 7 * 86_400_000)
      .sort((a, b) => a.on!.localeCompare(b.on!))[0];
    if (first) birthStats = keepsakeBirthStats(first.w, first.l, locale);
  }
  const input: KeepsakeJobInput = {
    ...(presentation ? { presentation } : {}),
    template,
    photos,
    texts: {
      title: presentation?.copy.title ?? (req.texts.title || defaultText('title')),
      message: req.texts.message || defaultText('message'),
      ...extra,
    },
    photoInfo,
    locale,
    birthStats,
    name,
    dateLine: start ? `${dm(start)} – ${dmy(end)}` : dmy(end),
    mark,
    music: musicAsset
      ? `content/keepsakes/${musicAsset}`
      : musicId === null || !template.assets.music
        ? null
        : `content/keepsakes/${template.assets.music}`,
  };

  // Q2 (brief p.10): one video unit, reserved in the transaction that creates the job, so twenty
  // presses at once never take more than the window has (M10). Operational caps above still apply.
  const window = await videoWindowFor(
    db,
    familyId,
    req.babyId,
    await readEntitlementsConfig(db),
    environment,
    now,
  );
  const reservationId = reservationIdOf(jobId, 0);
  const created = await db.runTransaction(async (tx) => {
    const again = await tx.get(ref);
    const currentBaby = await tx.get(db.doc(`babies/${req.babyId}`));
    if (!currentBaby.exists || currentBaby.get('state') === 'deleting') {
      throw new KeepsakeJobError('failed-precondition', 'deleting');
    }
    const currentMember = await tx.get(db.doc(`babies/${req.babyId}/members/${uid}`));
    const memberUntil = currentMember.get('accessUntilAt') as Timestamp | null | undefined;
    if (
      currentMember.get('status') !== 'active' ||
      currentMember.get('role') !== 'coParent' ||
      (memberUntil && memberUntil.toMillis() <= now.getTime())
    )
      throw new KeepsakeJobError('permission-denied', 'not-allowed');
    if (again.exists) return null;
    const windowSnap = await tx.get(windowRef(db, familyId, window.id));
    const held = reserveInTx(
      tx,
      db,
      familyId,
      window,
      windowSnap,
      reservationId,
      { babyId: req.babyId, jobId },
      now,
    );
    if (held.outcome !== 'reserved') {
      throw new KeepsakeJobError('resource-exhausted', 'QUOTA_EXCEEDED');
    }
    tx.create(ref, {
      id: jobId,
      uid,
      babyId: req.babyId,
      familyId,
      requestId: req.requestId,
      templateId: template.id,
      templateVersion: template.version,
      mediaIds: req.mediaIds,
      audience: req.audience,
      occasion: req.occasion,
      musicId: musicId ?? null,
      occasionDate: day ? day.toISOString().slice(0, 10) : null,
      input,
      status: 'queued',
      step: null,
      progress: 0,
      attempts: 0,
      error: null,
      output: null,
      memoryId: null,
      // The ledger reservation and the fencing token: the renderer bumps `lease` on each claim
      // and only the current holder may finish the job.
      quota: { reservationId, windowId: window.id, seq: 0 },
      lease: 0,
      createdAt: now,
      updatedAt: now,
      startedAt: null,
      finishedAt: null,
    });
    return snapshotOf(held.window, window.end);
  });
  if (created === null) {
    const status = ((await ref.get()).get('status') as string | undefined) ?? 'queued';
    return { jobId, status, quota: await readVideoQuota(db, familyId, window) };
  }
  if (dispatcher) await dispatchOrRelease(db, dispatcher, req.babyId, jobId, 0, now);
  console.info('keepsake job requested', { jobId, template: template.id });
  return { jobId, status: 'queued', quota: created };
}

/** One reservation per attempt series: the first request is 0, each "Thử lại" the next. */
export const reservationIdOf = (jobId: string, seq: number) => `video_${jobId}_${seq}`;

/**
 * Hands the job to the renderer; when that fails before any worker saw it (still queued, never
 * claimed), the job fails as `unavailable` and its reservation is released ("cancel before the
 * worker"), so the parent gets "Thử lại" and the unit back.
 */
async function dispatchOrRelease(
  db: Firestore,
  dispatcher: RenderDispatcher,
  babyId: string,
  jobId: string,
  attempt: number,
  now: Date,
): Promise<void> {
  try {
    await dispatcher.dispatch(babyId, jobId, attempt);
  } catch (error) {
    const ref = jobRef(db, babyId, jobId);
    await db.runTransaction(async (tx) => {
      const job = await tx.get(ref);
      const quota = job.get('quota') as JobQuota | undefined;
      const familyId = job.get('familyId') as string | undefined;
      if (!job.exists || job.get('status') !== 'queued' || (job.get('attempts') ?? 0) !== 0) return;
      const reads =
        quota && familyId ? await readForSettle(tx, db, familyId, quota.reservationId) : null;
      tx.update(ref, { status: 'failed', error: 'unavailable', updatedAt: now, finishedAt: now });
      if (reads && familyId) settleInTx(tx, db, familyId, reads, 'release', now);
    });
    throw error;
  }
}

interface JobQuota {
  reservationId: string;
  windowId: string;
  seq: number;
}

/**
 * Gives back the unit of [reservationId] once its job failed for good, was deleted, or moved on
 * to a newer reservation (a retry). Safe to call any number of times: only a `reserved`
 * reservation is released, and never the one a live job still holds.
 */
export async function releaseJobQuota(
  db: Firestore,
  babyId: string,
  jobId: string,
  familyId: string,
  reservationId: string,
  now: Date,
): Promise<'released' | 'noop'> {
  return db.runTransaction(async (tx) => {
    const job = await tx.get(jobRef(db, babyId, jobId));
    const current = (job.get('quota') as JobQuota | undefined)?.reservationId;
    if (job.exists && current === reservationId && job.get('status') !== 'failed') return 'noop';
    const reads = await readForSettle(tx, db, familyId, reservationId);
    const r = settleInTx(tx, db, familyId, reads, 'release', now);
    return r.outcome === 'released' ? 'released' : 'noop';
  });
}

/** MO04: the household's video quota for the window a new video would count in. */
export async function getVideoQuota(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<VideoQuotaAnswer> {
  const parsed = videoQuotaRequestSchema.safeParse(data);
  if (!parsed.success) throw new KeepsakeJobError('invalid-argument', 'malformed');
  const { babyId } = parsed.data;
  const [member, baby] = await Promise.all([
    db.doc(`babies/${babyId}/members/${uid}`).get(),
    db.doc(`babies/${babyId}`).get(),
  ]);
  const until = member.get('accessUntilAt') as Timestamp | null | undefined;
  if (
    !member.exists ||
    member.get('status') !== 'active' ||
    (until && until.toMillis() <= now.getTime()) ||
    !familyCan(
      { role: member.get('role') as MemberRole, isOwner: member.get('isOwner') === true },
      'moments.create',
    )
  ) {
    throw new KeepsakeJobError('permission-denied', 'not-allowed');
  }
  const familyId = baby.get('familyId') as string | undefined;
  if (!familyId) throw new KeepsakeJobError('not-found', 'not-found');
  const config = await readEntitlementsConfig(db);
  const window: VideoWindow = await videoWindowFor(db, familyId, babyId, config, environment, now);
  return {
    ...(await readVideoQuota(db, familyId, window)),
    premiumLimit: window.kind === 'paid' ? null : config.quotas.video.premium.limit,
  };
}

/** MM14 "Thử lại": a failed job goes back in the queue with the same inputs. */
export async function retryMemoryStory(
  db: Firestore,
  dispatcher: RenderDispatcher | null,
  uid: string,
  data: unknown,
  now: Date,
  environment: GrantEnvironment = serverGrantEnvironment(),
): Promise<MemoryStoryAnswer> {
  const parsed = memoryStoryRetrySchema.safeParse(data);
  if (!parsed.success) throw new KeepsakeJobError('invalid-argument', 'malformed');
  const { babyId, jobId } = parsed.data;
  const ref = jobRef(db, babyId, jobId);
  const first = await ref.get();
  if (!first.exists || first.get('uid') !== uid) {
    throw new KeepsakeJobError('not-found', 'not-found');
  }
  const familyId = first.get('familyId') as string;
  // A retry is a new render: it takes a new reservation in the window of today (Q03, M12), after
  // the failed attempt's unit is given back (here, if the failure trigger has not yet).
  const window = await videoWindowFor(
    db,
    familyId,
    babyId,
    await readEntitlementsConfig(db),
    environment,
    now,
  );
  const retried = await db.runTransaction(async (tx) => {
    const job = await tx.get(ref);
    if (!job.exists || job.get('uid') !== uid) throw new KeepsakeJobError('not-found', 'not-found');
    const baby = await tx.get(db.doc(`babies/${babyId}`));
    const member = await tx.get(db.doc(`babies/${babyId}/members/${uid}`));
    if (!baby.exists || baby.get('state') === 'deleting')
      throw new KeepsakeJobError('failed-precondition', 'deleting');
    const until = member.get('accessUntilAt') as Timestamp | null | undefined;
    if (
      member.get('status') !== 'active' ||
      member.get('role') !== 'coParent' ||
      (until && until.toMillis() <= now.getTime())
    )
      throw new KeepsakeJobError('permission-denied', 'not-allowed');
    if (job.get('status') !== 'failed') return null;
    const old = job.get('quota') as JobQuota | undefined;
    const oldReads = old ? await readForSettle(tx, db, familyId, old.reservationId) : null;
    const windowSnap = await tx.get(windowRef(db, familyId, window.id));
    const released = oldReads ? settleInTx(tx, db, familyId, oldReads, 'release', now) : null;
    const base =
      oldReads && released && old?.windowId === window.id
        ? (countersAfter(oldReads, released) ?? undefined)
        : undefined;
    const seq = (old?.seq ?? -1) + 1;
    const reservationId = reservationIdOf(jobId, seq);
    const held = reserveInTx(
      tx,
      db,
      familyId,
      window,
      windowSnap,
      reservationId,
      { babyId, jobId },
      now,
      base,
    );
    if (held.outcome !== 'reserved') {
      throw new KeepsakeJobError('resource-exhausted', 'QUOTA_EXCEEDED');
    }
    const retries = ((job.get('retries') as number | undefined) ?? 0) + 1;
    tx.update(ref, {
      status: 'queued',
      step: null,
      progress: 0,
      attempts: 0,
      error: null,
      retries,
      quota: { reservationId, windowId: window.id, seq },
      updatedAt: now,
    });
    return { retries, quota: snapshotOf(held.window, window.end) };
  });
  if (retried === null) {
    return { jobId, status: 'unchanged', quota: await readVideoQuota(db, familyId, window) };
  }
  if (dispatcher) await dispatchOrRelease(db, dispatcher, babyId, jobId, retried.retries * 10, now);
  return { jobId, status: 'queued', quota: retried.quota };
}

/**
 * A job the renderer marked completed: file it in Kỷ niệm (memory + video item, ready, counted
 * in the quota) and tell the person who asked (push, D-068 #4). Safe to run twice.
 */
export async function completeKeepsakeJob(
  db: Firestore,
  store: MediaStore,
  images: ImageOps,
  babyId: string,
  jobId: string,
  now: Date,
): Promise<'filed' | 'ignored'> {
  const ref = jobRef(db, babyId, jobId);
  const job = await ref.get();
  if (!job.exists || job.get('status') !== 'completed' || job.get('memoryId')) return 'ignored';
  const output = job.get('output') as {
    durationMs: number;
    width: number;
    height: number;
    bytes: number;
    lease?: number;
    videoPath?: string;
    framePath?: string;
  } | null;
  if (!output) return 'ignored';
  // Fencing: only the renderer holding the current lease completes a job (a stale worker's
  // completion is refused by the renderer's own transaction; this is the second check).
  const lease = job.get('lease') as number | undefined;
  if (typeof lease === 'number' && lease > 0 && output.lease !== lease) {
    console.warn('keepsake job stale completion', { jobId });
    return 'ignored';
  }
  const ids = outputIdsOf(jobId);
  const dir = mediaPaths(babyId, ids.mediaId).dir;
  // Only accept our deterministic lease paths, never arbitrary job-supplied objects.
  const videoPath = output.videoPath ?? `${dir}/original.mp4`;
  const framePath = output.framePath ?? `${dir}/frame.jpg`;
  if (output.videoPath && videoPath !== `${dir}/original-${lease}.mp4`) return 'ignored';
  if (output.framePath && framePath !== `${dir}/frame-${lease}.jpg`) return 'ignored';
  const babyBefore = await db.doc(`babies/${babyId}`).get();
  if (!babyBefore.exists || babyBefore.get('state') === 'deleting') return 'ignored';
  // Register every Storage writer before touching bytes. Deletion drains these bounded
  // leases before purging, including a process killed between its upload and commit.
  const canFile = await db.runTransaction(async (tx) => {
    const current = await tx.get(ref);
    const baby = await tx.get(db.doc(`babies/${babyId}`));
    if (
      !baby.exists ||
      baby.get('state') === 'deleting' ||
      !current.exists ||
      current.get('status') !== 'completed' ||
      current.get('lease') !== lease ||
      current.get('memoryId')
    )
      return false;
    if (((current.get('filingUntilAt') as Timestamp | undefined)?.toMillis() ?? 0) > now.getTime())
      return 'busy' as const;
    tx.update(ref, { filingUntilAt: new Date(now.getTime() + 6 * 60_000) });
    return true;
  });
  if (canFile === 'busy') throw new KeepsakeJobError('failed-precondition', 'busy');
  if (!canFile) return 'ignored';
  const suffix = output.framePath ? `-${lease}` : '';

  // Poster and thumbnail from the frame the renderer wrote (as for uploaded videos).
  let posterBytes = 0;
  const frame = await store.read(framePath);
  if (frame) {
    const big = await images.jpeg(frame, 1280, 80);
    const thumb = await images.jpeg(frame, 480, 72);
    await store.save(`${dir}/poster${suffix}.jpg`, big.bytes, 'image/jpeg');
    await store.save(`${dir}/thumb${suffix}.jpg`, thumb.bytes, 'image/jpeg');
    posterBytes = big.bytes.length + thumb.bytes.length;
  }
  const stored = output.bytes + posterBytes;

  const filed = await db.runTransaction(async (tx) => {
    const fresh = await tx.get(ref);
    const baby = await tx.get(db.doc(`babies/${babyId}`));
    if (
      !baby.exists ||
      baby.get('state') === 'deleting' ||
      !fresh.exists ||
      fresh.get('status') !== 'completed' ||
      fresh.get('lease') !== lease ||
      fresh.get('memoryId')
    )
      return false;
    const uid = fresh.get('uid') as string;
    const member = await tx.get(db.doc(`babies/${babyId}/members/${uid}`));
    const familyId = fresh.get('familyId') as string;
    // Q2: the video's unit moves from reserved to used, once (M11).
    const quota = fresh.get('quota') as JobQuota | undefined;
    const quotaReads = quota ? await readForSettle(tx, db, familyId, quota.reservationId) : null;
    const audience = fresh.get('audience') as 'parents' | 'family';
    const occasion = fresh.get('occasion') as keyof typeof occasions | null;
    const occasionDate = fresh.get('occasionDate') as string | null;
    const template = (fresh.get('input') as KeepsakeJobInput).template;
    const author = {
      name: (member.get('displayName') as string | undefined) ?? '',
      relation: (member.get('relation') as string | undefined) ?? 'other',
      relationCustom: (member.get('relationCustom') as string | null | undefined) ?? null,
    };
    // Filed on the occasion's day when it has passed, else now (MM09 "Tuần 4").
    const zone = (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh';
    const occurredAt =
      occasionDate && occasionDate <= localDateIn(zone, now)
        ? dayBoundsIn(zone, occasionDate).start
        : now;
    const locale = (fresh.get('input') as KeepsakeJobInput).locale ?? 'vi';
    const milestone =
      occasion && occasionDate
        ? { id: occasions[occasion].milestoneId, name: template.name[locale], date: occasionDate }
        : null;
    const generated = {
      kind: 'video',
      templateId: template.id,
      templateVersion: template.version,
      occasion,
      format: (fresh.get('input') as KeepsakeJobInput).presentation?.format ?? 'story',
    };
    tx.set(db.doc(`babies/${babyId}/media/${ids.mediaId}`), {
      id: ids.mediaId,
      babyId,
      memoryId: ids.memoryId,
      batchId: ids.batchId,
      familyId,
      position: 0,
      type: 'video',
      contentType: 'video/mp4',
      sizeBytes: output.bytes,
      reservedBytes: 0,
      storedBytes: stored,
      hasPoster: posterBytes > 0,
      captureAt: occurredAt,
      durationMs: output.durationMs,
      width: output.width,
      height: output.height,
      audience,
      effectiveAudience: audience,
      albumIds: [],
      milestone,
      generated,
      status: 'ready',
      clientState: null,
      paths: {
        original: videoPath,
        display: null,
        thumb: posterBytes > 0 ? `${dir}/thumb${suffix}.jpg` : null,
        poster: posterBytes > 0 ? `${dir}/poster${suffix}.jpg` : null,
      },
      createdBy: uid,
      author,
      createdAt: now,
      updatedAt: now,
      readyAt: now,
      deleted: false,
      deletedAt: null,
      deletedBy: null,
    });
    tx.set(db.doc(`babies/${babyId}/memories/${ids.memoryId}`), {
      id: ids.memoryId,
      babyId,
      batchId: ids.batchId,
      caption: (fresh.get('input') as KeepsakeJobInput).texts.title || null,
      audience,
      notifyFamily: false,
      dateMode: 'single',
      occurredAt,
      milestone,
      generated,
      mediaIds: [ids.mediaId],
      counts: { photos: 0, videos: 1 },
      coverMediaId: ids.mediaId,
      state: 'published',
      publishedAt: now,
      createdBy: uid,
      author,
      createdAt: now,
      updatedAt: now,
      deleted: false,
    });
    tx.update(db.doc(`families/${familyId}`), { usedBytes: FieldValue.increment(stored) });
    tx.update(ref, { memoryId: ids.memoryId, outputMediaId: ids.mediaId, updatedAt: now });
    if (quotaReads) {
      const settled = settleInTx(tx, db, familyId, quotaReads, 'commit', now);
      if (settled.outcome !== 'committed') console.warn('keepsake quota not committed', { jobId });
    }
    // MM17 + push to the person who asked only (D-068 #4); generic copy on the lock screen.
    tx.set(db.doc(`babies/${babyId}/notifications/keepsake_${jobId}`), {
      kind: 'keepsakeVideo',
      babyId,
      count: 1,
      actor: null,
      recipients: [uid],
      context: { jobId, mediaId: ids.mediaId },
      createdAt: now,
      delivered: false,
    });
    return true;
  });
  // Keep the frame until filing commits: a retried trigger can regenerate derivatives.
  if (filed) await store.delete(framePath);
  // All Storage writes above have finished; do not recreate a job purged in the meantime.
  await db.runTransaction(async (tx) => {
    const current = await tx.get(ref);
    if (current.exists && current.get('lease') === lease) tx.update(ref, { filingUntilAt: null });
  });
  console.info('keepsake job filed', { jobId, filed });
  return filed ? 'filed' : 'ignored';
}

/**
 * MM14 "Xoá bản nháp": a video that could not be made goes, with any partial file. Only the
 * person who asked, and only a failed one (a finished video is a memory, deleted from Kỷ niệm).
 */
export async function deleteMemoryStory(
  db: Firestore,
  store: MediaStore,
  uid: string,
  data: unknown,
): Promise<{ jobId: string; status: 'deleted' | 'unchanged' }> {
  const parsed = memoryStoryRetrySchema.safeParse(data);
  if (!parsed.success) throw new KeepsakeJobError('invalid-argument', 'malformed');
  const { babyId, jobId } = parsed.data;
  const ref = jobRef(db, babyId, jobId);
  const deleted = await db.runTransaction(async (tx) => {
    const job = await tx.get(ref);
    if (!job.exists) return false;
    if (job.get('uid') !== uid) throw new KeepsakeJobError('not-found', 'not-found');
    if (job.get('status') !== 'failed') {
      throw new KeepsakeJobError('failed-precondition', 'not-failed');
    }
    if (((job.get('leaseUntilAt') as Timestamp | null)?.toMillis() ?? 0) > Date.now()) {
      throw new KeepsakeJobError('failed-precondition', 'busy');
    }
    // A failed job's unit is normally back already; make sure before the job goes.
    const quota = job.get('quota') as JobQuota | undefined;
    const familyId = job.get('familyId') as string | undefined;
    const reads =
      quota && familyId ? await readForSettle(tx, db, familyId, quota.reservationId) : null;
    if (reads && familyId) settleInTx(tx, db, familyId, reads, 'release', new Date());
    tx.delete(ref);
    return { lease: Number(job.get('lease') ?? 0) };
  });
  if (deleted) {
    const dir = mediaPaths(babyId, outputIdsOf(jobId).mediaId).dir;
    for (const f of ['original.mp4', 'frame.jpg']) await store.delete(`${dir}/${f}`);
    for (let lease = 1; lease <= deleted.lease; lease++) {
      for (const f of [
        `original-${lease}.mp4`,
        `frame-${lease}.jpg`,
        `poster-${lease}.jpg`,
        `thumb-${lease}.jpg`,
      ])
        await store.delete(`${dir}/${f}`);
    }
  }
  return { jobId, status: deleted ? 'deleted' : 'unchanged' };
}

/**
 * MM08: the job's Live Activity on iPhone, or (no token) the phone's FCM token on Android, from
 * the person who asked only.
 */
export async function attachKeepsakeLive(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ ok: true }> {
  const parsed = keepsakeJobLiveSchema.safeParse(data);
  if (!parsed.success) throw new KeepsakeJobError('invalid-argument', 'malformed');
  const { babyId, jobId, token, fcm } = parsed.data;
  const ref = jobRef(db, babyId, jobId);
  await db.runTransaction(async (tx) => {
    const job = await tx.get(ref);
    if (!job.exists || job.get('uid') !== uid) throw new KeepsakeJobError('not-found', 'not-found');
    tx.update(ref, { live: { token, fcm, at: now } });
  });
  return { ok: true };
}

/** Sends to a Live Activity (FCM with its ActivityKit token); false: the activity is gone. */
export interface LiveSender {
  send(
    live: { token: string; fcm: string },
    event: 'update' | 'end',
    state: KeepsakeLiveState,
    now: Date,
  ): Promise<boolean>;
  /**
   * Android (A6): the same moments as a data message to the phone, which keeps an ongoing
   * progress notice; false: the token is gone.
   */
  android(
    fcm: string,
    job: { babyId: string; jobId: string },
    event: 'update' | 'end',
    state: KeepsakeLiveState,
  ): Promise<boolean>;
}

type JobSnap = { get(field: string): unknown; exists: boolean } | undefined;

const liveStateOf = (job: NonNullable<JobSnap>): KeepsakeLiveState => ({
  status: job.get('status') as KeepsakeLiveState['status'],
  step: (job.get('step') as KeepsakeLiveState['step'] | undefined) ?? null,
  progress: Math.round((job.get('progress') as number | undefined) ?? 0),
});

/**
 * A job changed: a failure tells the person who asked (push, like "ready"; MM14), and its Live
 * Activity follows each step (every 10 %) and ends when the job finishes.
 */
export async function keepsakeJobChanged(
  db: Firestore,
  live: LiveSender | null,
  babyId: string,
  jobId: string,
  before: JobSnap,
  after: JobSnap,
  now: Date,
): Promise<void> {
  if (!after?.exists) return;
  const was = before?.exists ? liveStateOf(before) : null;
  const is = liveStateOf(after);
  if (is.status === 'failed' && was?.status !== 'failed') {
    const retries = (after.get('retries') as number | undefined) ?? 0;
    // A retry that fails again tells again: one notice per attempt.
    await db.runTransaction(async (tx) => {
      const [baby, current] = await Promise.all([
        tx.get(db.doc(`babies/${babyId}`)),
        tx.get(jobRef(db, babyId, jobId)),
      ]);
      if (
        !baby.exists ||
        baby.get('state') === 'deleting' ||
        !current.exists ||
        current.get('status') !== 'failed' ||
        Number(current.get('retries') ?? 0) !== retries
      )
        return;
      const notice = db.doc(`babies/${babyId}/notifications/keepsake_${jobId}_failed_${retries}`);
      if ((await tx.get(notice)).exists) return;
      tx.create(notice, {
        kind: 'keepsakeVideoFailed',
        babyId,
        count: 1,
        actor: null,
        recipients: [after.get('uid') as string],
        context: { jobId },
        createdAt: now,
        delivered: false,
      });
    });
    // Q2: a job that failed for good gives its unit back, once (M11).
    const quota = after.get('quota') as JobQuota | undefined;
    const familyId = after.get('familyId') as string | undefined;
    if (quota && familyId) {
      await releaseJobQuota(db, babyId, jobId, familyId, quota.reservationId, now);
    }
  }
  const target = after.get('live') as { token?: string | null; fcm?: string } | undefined;
  if (!live || !target?.fcm) return;
  const attached = !(before?.get('live') as { fcm?: string } | undefined)?.fcm;
  const changed =
    attached ||
    !was ||
    was.status !== is.status ||
    was.step !== is.step ||
    Math.floor(was.progress / 10) !== Math.floor(is.progress / 10);
  if (!changed) return;
  const done = is.status === 'completed' || is.status === 'failed';
  const ok = target.token
    ? await live.send({ token: target.token, fcm: target.fcm }, done ? 'end' : 'update', is, now)
    : await live.android(target.fcm, { babyId, jobId }, done ? 'end' : 'update', is);
  if (!ok) await jobRef(db, babyId, jobId).update({ live: FieldValue.delete() });
}

/**
 * Every 15 minutes: a job rendering too long fails with `timeout`, one never picked up with
 * `unavailable`; their partial files are removed. Inputs stay, so "Thử lại" works.
 */
export async function sweepKeepsakeJobs(
  db: Firestore,
  store: MediaStore,
  now: Date,
): Promise<number> {
  // Transactional: a worker that finishes at the same moment either wins (the job is no longer
  // rendering) or loses its lease; the unit is released in the same write (Q2).
  const fail = async (
    doc: FirebaseFirestore.QueryDocumentSnapshot,
    error: KeepsakeJobErrorCode,
  ): Promise<boolean> => {
    const status = doc.get('status') as string;
    const failed = await db.runTransaction(async (tx) => {
      const job = await tx.get(doc.ref);
      if (!job.exists || job.get('status') !== status || job.get('lease') !== doc.get('lease')) {
        return false;
      }
      const quota = job.get('quota') as JobQuota | undefined;
      const familyId = job.get('familyId') as string | undefined;
      const reads =
        quota && familyId ? await readForSettle(tx, db, familyId, quota.reservationId) : null;
      tx.update(doc.ref, { status: 'failed', error, updatedAt: now, finishedAt: now });
      if (reads && familyId) settleInTx(tx, db, familyId, reads, 'release', now);
      return true;
    });
    if (!failed) return false;
    const { mediaId } = outputIdsOf(doc.id);
    const dir = mediaPaths(doc.get('babyId') as string, mediaId).dir;
    for (const f of ['original.mp4', 'frame.jpg']) await store.delete(`${dir}/${f}`);
    for (let lease = 1; lease <= Number(doc.get('lease') ?? 0); lease++) {
      for (const f of [
        `original-${lease}.mp4`,
        `frame-${lease}.jpg`,
        `poster-${lease}.jpg`,
        `thumb-${lease}.jpg`,
      ])
        await store.delete(`${dir}/${f}`);
    }
    return true;
  };
  let n = 0;
  const rendering = await db
    .collectionGroup('keepsakeJobs')
    .where('status', '==', 'rendering')
    .where('startedAt', '<', new Date(now.getTime() - keepsakeJobLimits.renderMinutes * 60_000))
    .get();
  for (const d of rendering.docs) {
    if (await fail(d, 'timeout')) n++;
  }
  const queued = await db
    .collectionGroup('keepsakeJobs')
    .where('status', '==', 'queued')
    .where('updatedAt', '<', new Date(now.getTime() - keepsakeJobLimits.queuedMinutes * 60_000))
    .get();
  for (const d of queued.docs) {
    if (await fail(d, 'unavailable')) n++;
  }
  if (n) console.info('keepsake jobs swept', { n });
  return n;
}

/**
 * Cloud Tasks over REST (no extra dependency in the bundle): one task per job attempt, named so a
 * repeat is refused by the queue, sent with an OIDC token of the tasks service account to the
 * private renderer.
 */
export function cloudTasksDispatcher(opts: {
  project: string;
  region: string;
  queue: string;
  rendererUrl: string;
  serviceAccount: string;
}): RenderDispatcher {
  return {
    async dispatch(babyId, jobId, attempt) {
      const token = await fetch(
        'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token',
        { headers: { 'Metadata-Flavor': 'Google' } },
      ).then((r) => r.json() as Promise<{ access_token: string }>);
      const parent = `projects/${opts.project}/locations/${opts.region}/queues/${opts.queue}`;
      const response = await fetch(`https://cloudtasks.googleapis.com/v2/${parent}/tasks`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token.access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          task: {
            name: `${parent}/tasks/${jobId}-${attempt}`,
            dispatchDeadline: '900s',
            httpRequest: {
              httpMethod: 'POST',
              url: `${opts.rendererUrl}/render`,
              headers: { 'Content-Type': 'application/json' },
              body: Buffer.from(JSON.stringify({ babyId, jobId })).toString('base64'),
              oidcToken: { serviceAccountEmail: opts.serviceAccount, audience: opts.rendererUrl },
            },
          },
        }),
      });
      // 409: this attempt is already queued (a retried call), which is fine.
      if (!response.ok && response.status !== 409) {
        console.error('keepsake dispatch failed', { jobId, status: response.status });
        throw new KeepsakeJobError('failed-precondition', 'unavailable');
      }
    },
  };
}
