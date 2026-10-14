import { createHash } from 'node:crypto';
import {
  FieldValue,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
} from 'firebase-admin/firestore';
import {
  addDaysIso,
  ageCardFor,
  checkInSchema,
  checkInState,
  composeHomeRequestSchema,
  datesTouched,
  dayBoundsIn,
  dayQuality,
  daysBetweenIso,
  defaultRhythmRules,
  defaultUserPreferences,
  familyCan,
  feedbackMemory,
  localDateIn,
  needOf,
  needsHealthSupport,
  nextActionRequestSchema,
  observationState,
  recFeedbackSchema,
  recommend,
  recommendationIdFor,
  rhythmConfigSchema,
  rhythmContentSchema,
  setDueDateRequestSchema,
  sleepBaseline,
  sleepWindows,
  userPreferencesSchema,
  type CareType,
  type CheckIn,
  type ComposeHomeAnswer,
  type DayQuality,
  type DueDate,
  type FeedbackMemory,
  type FeedbackRef,
  type GrantEnvironment,
  type Need,
  type NextActionAnswer,
  type RecFeedback,
  type Recommendation,
  type RecommendOutcome,
  type RhythmContent,
  type RhythmRules,
  type UserPreferences,
} from '@child-life/contracts';
import {
  checkCapability,
  gateError,
  loadEntitlementContext,
  type EntitlementContext,
} from './entitlements.js';

/**
 * Nhịp lớn lên, Slice 2 (plan §5.4, §7.1, D-073): the due date, the next action after a
 * check-in, the Home suggestion and the facts version. Every rule lives in the contracts
 * (`rhythm.ts`, `personalization.ts`); this module only loads the inputs, applies the capability
 * gates and stores the result. Notes, names and dates of birth are never logged.
 */
export class RhythmError extends Error {
  constructor(
    readonly code: 'invalid-argument' | 'permission-denied' | 'not-found' | 'failed-precondition',
    readonly reason: string,
  ) {
    super(reason);
  }
}

const DEFAULT_ZONE = 'Asia/Ho_Chi_Minh';
const DAY_MS = 86_400_000;
/** Recommendation states that are still shown (H02 / PS02). */
const activeStates = ['suggested', 'started', 'done'] as const;

function parseOr<T>(
  schema: { safeParse(d: unknown): { success: boolean; data?: T } },
  data: unknown,
): T {
  const r = schema.safeParse(data);
  if (!r.success) throw new RhythmError('invalid-argument', 'bad-request');
  return r.data as T;
}

const millis = (v: unknown): number =>
  v instanceof Timestamp ? v.toMillis() : v instanceof Date ? v.getTime() : 0;

// ---------- Inputs shared by nextAction / composeHome ----------

interface RhythmInputs {
  zone: string;
  today: string;
  /** Actual age (from the date of birth, never corrected); null without a date of birth. */
  ageDays: number | null;
  babyState: string;
  content: RhythmContent | null;
  rules: RhythmRules;
}

/** `config/rhythm` rules; a missing or invalid document reads as the contract default. */
export async function readRhythmRules(db: Firestore): Promise<RhythmRules> {
  const parsed = rhythmConfigSchema.safeParse((await db.doc('config/rhythm').get()).data());
  return parsed.success ? parsed.data.rules : defaultRhythmRules;
}

/** The published content pack, or null when none is published (never an error). */
export async function readRhythmContent(db: Firestore): Promise<RhythmContent | null> {
  const parsed = rhythmContentSchema.safeParse(
    (await db.doc('publicConfig/content_rhythm').get()).data(),
  );
  return parsed.success ? parsed.data : null;
}

async function rhythmInputs(db: Firestore, babyId: string, now: Date): Promise<RhythmInputs> {
  const [baby, profile, content, rules] = await Promise.all([
    db.doc(`babies/${babyId}`).get(),
    db.doc(`babies/${babyId}/restricted/profile`).get(),
    readRhythmContent(db),
    readRhythmRules(db),
  ]);
  const zone = (baby.get('timeZone.zone') as string | undefined) ?? DEFAULT_ZONE;
  const today = localDateIn(zone, now);
  const dob = (profile.get('dateOfBirth') as string | undefined)?.slice(0, 10) ?? null;
  return {
    zone,
    today,
    ageDays: dob && dob <= today ? daysBetweenIso(dob, today) : null,
    babyState: (baby.get('state') as string | undefined) ?? 'active',
    content,
    rules,
  };
}

/** The caller's own preferences (EN01, EN05), or the defaults. */
async function readPreferences(db: Firestore, uid: string): Promise<UserPreferences> {
  const data = (await db.doc(`users/${uid}/settings/personalization`).get()).data();
  if (!data) return defaultUserPreferences;
  const updatedAt =
    data.updatedAt instanceof Timestamp ? data.updatedAt.toDate().toISOString() : data.updatedAt;
  const parsed = userPreferencesSchema.safeParse({ ...data, updatedAt: updatedAt ?? null });
  return parsed.success ? parsed.data : defaultUserPreferences;
}

type FeedbackRow = RecFeedback & { createdAtMs: number };

/** The baby's feedback from every author, newest first (malformed rows are ignored). */
async function readFeedback(db: Firestore, babyId: string): Promise<FeedbackRow[]> {
  const snap = await db
    .collection(`babies/${babyId}/recFeedback`)
    .orderBy('createdAt', 'desc')
    .limit(300)
    .get();
  const rows: FeedbackRow[] = [];
  for (const d of snap.docs) {
    const parsed = recFeedbackSchema.safeParse(d.data());
    if (parsed.success && parsed.data.babyId === babyId) {
      rows.push({ ...parsed.data, createdAtMs: millis(d.get('createdAt')) });
    }
  }
  return rows;
}

// ---------- Sleep facts ("Từ nhật ký", B01–B06, M13) ----------

/**
 * Per-day quality over the baseline lookback plus the recent window, then the comparison. Days
 * without records, with a running sleep timer or an open overlap are invalid, never zero.
 */
export async function sleepFacts(
  db: Firestore,
  babyId: string,
  zone: string,
  today: string,
  now: Date,
  rules: RhythmRules,
): Promise<NonNullable<NextActionAnswer['sleep']>> {
  const span = rules.baselineLookbackDays + rules.recentDays;
  const dates = Array.from({ length: span }, (_, i) => addDaysIso(today, -span + i));
  const from = dayBoundsIn(zone, dates[0]!).start.getTime();
  const to = dayBoundsIn(zone, today).start.getTime();
  const cover = rules.pointCoverMinutes * 60_000;
  const [records, timer, conflicts] = await Promise.all([
    db
      .collection(`babies/${babyId}/records`)
      .where('occurredAt', '>=', new Date(from - DAY_MS))
      .where('occurredAt', '<', new Date(to + cover))
      .get(),
    db.doc(`babies/${babyId}/timers/sleep`).get(),
    db.collection(`babies/${babyId}/conflicts`).where('status', '==', 'open').get(),
  ]);
  const rows = records.docs
    .filter((d) => d.get('deleted') !== true && d.get('occurredAt') instanceof Timestamp)
    .map((d) => ({
      type: d.get('type') as CareType,
      occurredAt: (d.get('occurredAt') as Timestamp).toDate(),
      endedAt: (d.get('endedAt') as Timestamp | null | undefined)?.toDate() ?? null,
    }));
  const openSleepTimerSince = timer.exists
    ? ((timer.get('startedAt') as Timestamp | undefined)?.toDate() ?? new Date(0))
    : null;
  // An unresolved overlap invalidates every day either record touches.
  const overlapDays = new Map<string, number>();
  for (const c of conflicts.docs) {
    const ids = (c.get('recordIds') as string[] | undefined) ?? [];
    const touched = new Set<string>();
    for (const id of ids) {
      const r = await db.doc(`babies/${babyId}/records/${id}`).get();
      const occurredAt = (r.get('occurredAt') as Timestamp | undefined)?.toDate();
      if (!occurredAt) continue;
      const endedAt = (r.get('endedAt') as Timestamp | null | undefined)?.toDate() ?? null;
      for (const date of datesTouched(zone, { occurredAt, endedAt })) touched.add(date);
    }
    for (const date of touched) overlapDays.set(date, (overlapDays.get(date) ?? 0) + 1);
  }
  const days: DayQuality[] = dates.map((date) =>
    dayQuality({
      zone,
      date,
      now,
      records: rows,
      openSleepTimerSince,
      openConflicts: overlapDays.get(date) ?? 0,
      rules,
    }),
  );
  const windows = sleepWindows(today, days, rules);
  const result = sleepBaseline(windows.baseline, windows.recent, rules);
  return {
    status: result.status,
    baseline: 'baseline' in result ? result.baseline : null,
    recent: 'recent' in result ? result.recent : null,
    validDays: result.validBaselineDays + result.validRecentDays,
  };
}

// ---------- Due date (NL02b) ----------

/** `setDueDate` (Cùng nuôi, `rhythm.setup`): stored with the date of birth, merge only. */
export async function setDueDate(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
  environment: GrantEnvironment,
): Promise<{ dueDate: DueDate | null }> {
  const req = parseOr(setDueDateRequestSchema, data);
  const ctx = await loadEntitlementContext(db, uid, req.babyId, now, environment);
  const allowed = checkCapability(ctx, 'wonder.reference', now, 'rhythm.setup');
  if (!allowed.allowed) throw gateError(allowed.reason);
  const babyRef = db.doc(`babies/${req.babyId}`);
  const profileRef = babyRef.collection('restricted').doc('profile');
  await db.runTransaction(async (tx) => {
    const [baby, profile] = await Promise.all([tx.get(babyRef), tx.get(profileRef)]);
    if (baby.get('state') === 'deleting') throw new RhythmError('failed-precondition', 'deleting');
    const dob = (profile.get('dateOfBirth') as string | undefined)?.slice(0, 10);
    // Gestation 22–44 weeks at birth: the due date lies 4 weeks before to 18 weeks after birth.
    if (req.dueDate && dob) {
      const offset = daysBetweenIso(dob, req.dueDate.date);
      if (offset < -28 || offset > 126) {
        throw new RhythmError('invalid-argument', 'due-date-out-of-range');
      }
    }
    tx.set(profileRef, { dueDate: req.dueDate, updatedAt: now }, { merge: true });
  });
  return { dueDate: req.dueDate };
}

// ---------- Recommendations ----------

/** Fields kept next to the `Recommendation` contract so a retry returns the same answer. */
interface StoredRecommendation extends Recommendation {
  babyId: string;
  checkInId: string;
  checkInRevision: number;
  need: Need;
  locale: 'vi' | 'en';
  secondary: { contentId: string; contentVersion: number }[];
  ageCardId: string | null;
  sleep: NextActionAnswer['sleep'];
  /** Who asked (not who reported): the caller's interests shaped the ranking. */
  requestedBy: string;
  supersededBy: string | null;
}

function recommendationOf(d: DocumentSnapshot): StoredRecommendation {
  return d.data() as StoredRecommendation;
}

function publicRecommendation(r: StoredRecommendation): Recommendation {
  return {
    id: r.id,
    contentId: r.contentId,
    contentVersion: r.contentVersion,
    reasonCode: r.reasonCode,
    supportingIds: r.supportingIds,
    requiredCapability: r.requiredCapability,
    state: r.state,
    changes: r.changes,
    cooldownUntil: r.cooldownUntil,
    generatedAt: r.generatedAt,
  };
}

/** Feedback ids that explain the ranking (PS02 "Dựa trên phản hồi của bạn"), newest first. */
function supportingFeedback(
  out: Extract<RecommendOutcome, { kind: 'suggestion' }>,
  rows: readonly FeedbackRow[],
  memory: FeedbackMemory,
  content: RhythmContent,
  need: Need,
  today: string,
): string[] {
  const needMatch = (contentId: string) =>
    content.activities.some((a) => a.id === contentId && a.needs.includes(need));
  const ids: string[] = [];
  for (const r of rows) {
    if (
      (out.changes.includes('prefers_helpful') &&
        r.kind === 'helpful' &&
        r.contentId === out.primary.id) ||
      (out.changes.includes('excluded_not_suitable') &&
        r.kind === 'not_suitable' &&
        memory.notSuitable.has(r.contentId) &&
        needMatch(r.contentId)) ||
      (out.changes.includes('cooling_down') &&
        r.kind === 'not_today' &&
        (memory.cooldownUntil.get(r.contentId) ?? '') >= today &&
        needMatch(r.contentId))
    ) {
      ids.push(r.id);
    }
  }
  return ids.slice(0, 5);
}

interface RankContext {
  uid: string;
  babyId: string;
  locale: 'vi' | 'en';
  need: Need;
  inputs: RhythmInputs & { content: RhythmContent; ageDays: number };
  country: string | null;
  feedback: FeedbackRow[];
}

/** One run of the contract ranking for a need; `null` when nothing is eligible. */
async function rank(db: Firestore, x: RankContext) {
  const prefs = await readPreferences(db, x.uid);
  const memory = feedbackMemory(x.feedback, x.inputs.rules.cooldownDays);
  const out = recommend({
    locale: x.locale,
    today: x.inputs.today,
    ageDays: x.inputs.ageDays,
    need: x.need,
    interests: prefs.interests,
    fewer: prefs.fewer,
    country: x.country,
    healthFlag: false,
    memory,
    activities: x.inputs.content.activities,
  });
  if (out.kind !== 'suggestion') return null;
  return {
    out,
    feedbackIds: supportingFeedback(
      out,
      x.feedback,
      memory,
      x.inputs.content,
      x.need,
      x.inputs.today,
    ),
  };
}

/** Stores [rec] and retires the household's other shown recommendations (one primary, H02). */
async function storeRecommendation(db: Firestore, rec: StoredRecommendation) {
  const col = db.collection(`babies/${rec.babyId}/recommendations`);
  await db.runTransaction(async (tx) => {
    const shown = await tx.get(col.where('state', 'in', [...activeStates]));
    for (const d of shown.docs) {
      if (d.id !== rec.id) tx.update(d.ref, { state: 'dismissed', supersededBy: rec.id });
    }
    tx.set(col.doc(rec.id), rec);
  });
}

function answerOf(r: StoredRecommendation): NextActionAnswer {
  return {
    state: 'suggestion',
    recommendation: publicRecommendation(r),
    secondary: r.secondary,
    ageCardId: r.ageCardId,
    gate: null,
    sleep: r.sleep,
  };
}

// ---------- nextAction (PS01 / PS01F / HL01) ----------

/**
 * After a check-in: health signs → `health` (free, before any ranking, no gate); `usual` →
 * `normal`; otherwise group A ranks the published activities, without it the free age card with
 * the gate reason. The same check-in (same revision) returns the stored recommendation.
 */
export async function nextAction(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
  environment: GrantEnvironment,
): Promise<NextActionAnswer> {
  const req = parseOr(nextActionRequestSchema, data);
  const ctx = await loadEntitlementContext(db, uid, req.babyId, now, environment);
  // Member, role (Cùng nuôi, Người chăm sóc), the `rhythm` kill switch.
  const base = checkCapability(ctx, 'rhythm.checkin', now, 'rhythm.suggestions');
  if (!base.allowed) throw gateError(base.reason);

  const snap = await db.doc(`babies/${req.babyId}/checkins/${req.checkInId}`).get();
  if (!snap.exists) throw new RhythmError('not-found', 'checkin-not-found');
  const parsed = checkInSchema.safeParse(snap.data());
  if (!parsed.success || parsed.data.babyId !== req.babyId || parsed.data.id !== snap.id) {
    throw new RhythmError('failed-precondition', 'checkin-invalid');
  }
  const checkIn: CheckIn = parsed.data;
  const none = {
    recommendation: null,
    secondary: [],
    ageCardId: null,
    gate: null,
    sleep: null,
  } satisfies Omit<NextActionAnswer, 'state'>;

  // Brief p.11 #1: health wins over everything, in every plan state.
  if (needsHealthSupport(checkIn)) return { state: 'health', ...none };

  const inputs = await rhythmInputs(db, req.babyId, now);
  if (inputs.babyState === 'deleting') throw new RhythmError('failed-precondition', 'deleting');
  const ageCard =
    inputs.content && inputs.ageDays !== null
      ? ageCardFor(inputs.content.ageCards, inputs.ageDays)
      : null;
  const groupA = checkCapability(ctx, 'personalization.cross_module', now);
  const advanced = checkCapability(ctx, 'rhythm.advanced', now).allowed;
  const gate = groupA.allowed ? null : groupA.reason;
  const sleep = advanced
    ? await sleepFacts(db, req.babyId, inputs.zone, inputs.today, now, inputs.rules)
    : null;
  const plain = { ...none, ageCardId: ageCard?.id ?? null, gate, sleep };

  if (checkInState(checkIn) === 'normal') return { state: 'normal', ...plain };
  if (!groupA.allowed) return { state: 'free_content', ...plain };

  const recId = recommendationIdFor(checkIn.id);
  const stored = await db.doc(`babies/${req.babyId}/recommendations/${recId}`).get();
  if (stored.exists && stored.get('checkInRevision') === checkIn.revision) {
    return answerOf(recommendationOf(stored));
  }

  const need = needOf(checkIn.observation);
  if (need === null || !inputs.content || inputs.ageDays === null) {
    return { state: 'no_suggestion', ...plain };
  }
  const ranked = await rank(db, {
    uid,
    babyId: req.babyId,
    locale: req.locale,
    need,
    inputs: { ...inputs, content: inputs.content, ageDays: inputs.ageDays },
    country: ctx.family.country,
    // Using feedback in the ranking is advanced (plan §5.4); the feedback itself stays free.
    feedback: advanced ? await readFeedback(db, req.babyId) : [],
  });
  if (!ranked) return { state: 'no_suggestion', ...plain };
  const { out, feedbackIds } = ranked;
  // DATA_INSIGHT only when the logged facts pass the quality rules and show a change.
  const reasonCode =
    out.reasonCode === 'SELF_REPORTED_NEED' &&
    need === 'sleep' &&
    sleep?.status === 'change_detected'
      ? 'DATA_INSIGHT'
      : out.reasonCode;
  const rec: StoredRecommendation = {
    id: recId,
    contentId: out.primary.id,
    contentVersion: out.primary.version,
    reasonCode,
    supportingIds: [checkIn.id, ...feedbackIds],
    requiredCapability: 'personalization.cross_module',
    state: 'suggested',
    changes: out.changes,
    cooldownUntil: null,
    generatedAt: now.toISOString(),
    babyId: req.babyId,
    checkInId: checkIn.id,
    checkInRevision: checkIn.revision,
    need,
    locale: req.locale,
    secondary: out.secondary.map((a) => ({ contentId: a.id, contentVersion: a.version })),
    ageCardId: plain.ageCardId,
    sleep,
    requestedBy: uid,
    supersededBy: null,
  };
  await storeRecommendation(db, rec);
  return answerOf(rec);
}

// ---------- composeHome (H01 / H02 / PS02) ----------

const feedbackRef = (r: FeedbackRow): FeedbackRef => ({
  id: r.id,
  contentId: r.contentId,
  kind: r.kind,
  date: r.date,
  authorUid: r.authorUid,
});

/** Feedback that moves the ranking; "Mình sẽ thử" only marks the suggestion started. */
const rerankKinds: readonly RecFeedback['kind'][] = ['helpful', 'not_suitable', 'not_today'];

/**
 * The household's current suggestion. Feedback given since it was generated (Có ích, Không phù
 * hợp, Không phải hôm nay) re-ranks the same need, so the next open shows what changed (M18,
 * PS02). Without group A: the free age card and the gate; the free Home never fails.
 */
export async function composeHome(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
  environment: GrantEnvironment,
): Promise<ComposeHomeAnswer> {
  const req = parseOr(composeHomeRequestSchema, data);
  const ctx: EntitlementContext = await loadEntitlementContext(
    db,
    uid,
    req.babyId,
    now,
    environment,
  );
  if (!ctx.member) throw gateError('NOT_MEMBER');
  if (!familyCan(ctx.member, 'history.read')) throw gateError('ROLE_DENIED');
  const inputs = await rhythmInputs(db, req.babyId, now);
  const ageCardId =
    inputs.content && inputs.ageDays !== null
      ? (ageCardFor(inputs.content.ageCards, inputs.ageDays)?.id ?? null)
      : null;
  const empty = (state: ComposeHomeAnswer['state'], gate: string | null): ComposeHomeAnswer => ({
    state,
    recommendation: null,
    secondary: [],
    ageCardId,
    gate,
    sleep: null,
    lastFeedback: null,
  });

  // Reading the household's suggestion: history.read roles (relatives with Chăm sóc hằng ngày).
  const rhythm = checkCapability(ctx, 'wonder.reference', now, 'history.read');
  if (!rhythm.allowed) return empty('free_content', rhythm.reason);
  const groupA = checkCapability(ctx, 'personalization.cross_module', now, 'history.read');
  if (!groupA.allowed) return empty('free_content', groupA.reason);
  const advanced = checkCapability(ctx, 'rhythm.advanced', now, 'history.read').allowed;

  const latest = await db
    .collection(`babies/${req.babyId}/recommendations`)
    .orderBy('generatedAt', 'desc')
    .limit(20)
    .get();
  const doc = latest.docs.find((d) =>
    (activeStates as readonly string[]).includes(d.get('state') as string),
  );
  if (!doc) return empty('no_suggestion', null);
  let current = recommendationOf(doc);
  const feedback = advanced ? await readFeedback(db, req.babyId) : [];
  const generated = Date.parse(current.generatedAt);
  const since = feedback.filter((r) => r.createdAtMs > generated);
  const trigger = since.find((r) => rerankKinds.includes(r.kind));

  if (trigger && inputs.content && inputs.ageDays !== null) {
    const id = `rec_${createHash('sha256')
      .update(`${current.checkInId}:${trigger.id}`)
      .digest('hex')
      .slice(0, 32)}`;
    const existing = await db.doc(`babies/${req.babyId}/recommendations/${id}`).get();
    if (existing.exists) {
      current = recommendationOf(existing);
    } else {
      const ranked = await rank(db, {
        uid,
        babyId: req.babyId,
        locale: req.locale,
        need: current.need,
        inputs: { ...inputs, content: inputs.content, ageDays: inputs.ageDays },
        country: ctx.family.country,
        feedback,
      });
      if (!ranked) {
        await doc.ref.update({ state: 'dismissed', supersededBy: null });
        return { ...empty('no_suggestion', null), lastFeedback: feedbackRef(trigger) };
      }
      const { out, feedbackIds } = ranked;
      current = {
        ...current,
        id,
        contentId: out.primary.id,
        contentVersion: out.primary.version,
        reasonCode: out.reasonCode,
        supportingIds: [current.checkInId, ...new Set([trigger.id, ...feedbackIds])].slice(0, 6),
        state: 'suggested',
        changes: out.changes,
        generatedAt: now.toISOString(),
        locale: req.locale,
        secondary: out.secondary.map((a) => ({ contentId: a.id, contentVersion: a.version })),
        ageCardId,
        requestedBy: uid,
        supersededBy: null,
      };
      await storeRecommendation(db, current);
    }
  } else if (
    current.state === 'suggested' &&
    since.some((r) => r.kind === 'started' && r.contentId === current.contentId)
  ) {
    current = { ...current, state: 'started' };
    await doc.ref.update({ state: 'started' });
  }

  const byId = new Map(feedback.map((r) => [r.id, r]));
  const behind = current.supportingIds
    .map((i) => byId.get(i))
    .filter((r): r is FeedbackRow => r !== undefined)
    .sort((a, b) => b.createdAtMs - a.createdAtMs)[0];
  return {
    ...answerOf(current),
    ageCardId,
    sleep: null,
    lastFeedback: behind ? feedbackRef(behind) : null,
  };
}

// ---------- Facts version (triggers) ----------

/** `babies/{b}/facts/state.dataVersion`: bumped on every check-in, feedback or care write. */
export async function bumpDataVersion(db: Firestore, babyId: string, now: Date): Promise<boolean> {
  // A profile being purged (13l) gets nothing written back under it by late triggers.
  const baby = await db.doc(`babies/${babyId}`).get();
  if (!baby.exists || (baby.get('state') ?? 'active') !== 'active') return false;
  await db
    .doc(`babies/${babyId}/facts/state`)
    .set({ dataVersion: FieldValue.increment(1), updatedAt: now }, { merge: true });
  return true;
}

/**
 * A check-in was created, edited or deleted: bump the facts version and recompute what the
 * day's check-ins say together (X01–X03: both authors are kept, "mixed" when they disagree).
 */
export async function onCheckInWritten(
  db: Firestore,
  babyId: string,
  before: DocumentSnapshot | null,
  after: DocumentSnapshot | null,
  now: Date,
): Promise<{ dates: string[] }> {
  if (!(await bumpDataVersion(db, babyId, now))) return { dates: [] };
  const dates = new Set<string>();
  for (const s of [before, after]) {
    const date = s?.exists ? (s.get('date') as string | undefined) : undefined;
    if (date && /^\d{4}-\d{2}-\d{2}$/.test(date)) dates.add(date);
  }
  for (const date of dates) {
    const snap = await db.collection(`babies/${babyId}/checkins`).where('date', '==', date).get();
    const rows = snap.docs
      .map((d) => checkInSchema.safeParse(d.data()))
      .filter((p) => p.success)
      .map((p) => p.data!);
    const ref = db.doc(`babies/${babyId}/facts/day_${date}`);
    if (rows.length === 0) {
      await ref.delete();
      continue;
    }
    const states = rows.map((c) => ({ state: checkInState(c) }));
    await ref.set({
      date,
      state: observationState(states),
      checkIns: rows.length,
      normal: states.filter((s) => s.state === 'normal').length,
      changed: states.filter((s) => s.state === 'changed').length,
      health: rows.some((c) => needsHealthSupport(c)),
      updatedAt: now,
    });
  }
  return { dates: [...dates].sort() };
}
