import {
  Timestamp,
  type DocumentReference,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import {
  answerReminderRuleSchema,
  deleteReminderRuleSchema,
  nextDueOf,
  ruleRecordTypes,
  ruleTypeOfRecord,
  saveReminderRuleSchema,
  setReminderRuleEnabledSchema,
  type ReminderOutcome,
  type ReminderRuleType,
  type RuleSchedule,
} from '@child-life/contracts';
import { notifyUsers } from './notifications.js';
import { careInboxEngagement, careAdapterResult } from './engagement-observers.js';
import type { PushSender } from './social.js';

/**
 * Rule reminders (v1.0 improvement 370:1247, D-051): Cùng nuôi create, edit, pause and delete;
 * recipients are Cùng nuôi and Người chăm sóc (1d). The server keeps `nextDueAt`, pushes when it
 * is due, and the first log of the activity resolves the reminder for everyone. Pushes carry no
 * baby name (R-120); nothing about the child is logged.
 */

export class ReminderRuleError extends Error {
  constructor(
    readonly code: 'invalid-argument' | 'permission-denied' | 'not-found' | 'failed-precondition',
    readonly reason: string,
  ) {
    super(reason);
  }
}

type Author = { name: string; relation: string; relationCustom: string | null };

interface Member {
  uid: string;
  role: string;
  author: Author;
}

function memberOf(snap: DocumentSnapshot, now: Date): Member | null {
  if (!snap.exists || snap.get('status') !== 'active') return null;
  const until = snap.get('accessUntilAt') as Timestamp | null | undefined;
  if (until && until.toMillis() <= now.getTime()) return null;
  return {
    uid: snap.id,
    role: snap.get('role') as string,
    author: {
      name: (snap.get('displayName') as string | undefined) ?? '',
      relation: (snap.get('relation') as string | undefined) ?? 'other',
      relationCustom: (snap.get('relationCustom') as string | null | undefined) ?? null,
    },
  };
}

const canReceive = (m: Member | null) => m != null && ['coParent', 'caregiver'].includes(m.role);

async function caller(
  db: Firestore,
  tx: Transaction,
  babyId: string,
  uid: string,
  now: Date,
  parentOnly: boolean,
): Promise<Member> {
  const [baby, member] = await Promise.all([
    tx.get(db.doc(`babies/${babyId}`)),
    tx.get(db.doc(`babies/${babyId}/members/${uid}`)),
  ]);
  if (!baby.exists) throw new ReminderRuleError('not-found', 'not-found');
  if ((baby.get('state') ?? 'active') !== 'active') {
    throw new ReminderRuleError('failed-precondition', 'baby-closed');
  }
  const me = memberOf(member, now);
  if (!canReceive(me) || (parentOnly && me!.role !== 'coParent')) {
    throw new ReminderRuleError('permission-denied', 'not-allowed');
  }
  return me!;
}

function parse<T>(
  schema: { safeParse(d: unknown): { success: boolean; data?: T } },
  data: unknown,
): T {
  const r = schema.safeParse(data);
  if (!r.success) throw new ReminderRuleError('invalid-argument', 'malformed');
  return r.data as T;
}

const toDate = (v: unknown) => (v instanceof Timestamp ? v.toDate() : null);
const toTs = (d: Date | null) => (d ? Timestamp.fromDate(d) : null);

function scheduleOf(snap: DocumentSnapshot): RuleSchedule {
  return {
    mode: snap.get('mode'),
    enabled: snap.get('enabled') === true,
    intervalMinutes: snap.get('intervalMinutes') ?? null,
    times: snap.get('times') ?? [],
    days: snap.get('days') ?? [],
    quietNight: snap.get('quietNight') === true,
    anchorAt: toDate(snap.get('anchorAt')),
    skipBase: toDate(snap.get('skipBase')),
    snoozedUntil: toDate(snap.get('snoozedUntil')),
    pendingDueAt: toDate(snap.get('pendingDueAt')),
  };
}

async function zoneOf(db: Firestore, babyId: string, tx?: Transaction): Promise<string> {
  const ref = db.doc(`babies/${babyId}`);
  const baby = tx ? await tx.get(ref) : await ref.get();
  return (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh';
}

/**
 * The latest log a rule of [type] counts from. Sleep counts from waking up; while the baby is
 * asleep (a running sleep) there is nothing to remind, so the anchor is null.
 */
async function anchorFor(
  db: Firestore,
  babyId: string,
  type: ReminderRuleType,
  tx?: Transaction,
): Promise<{ at: Date | null; recordId: string | null }> {
  let best: { at: Date | null; recordId: string | null; started: number } = {
    at: null,
    recordId: null,
    started: 0,
  };
  for (const recordType of ruleRecordTypes[type]) {
    const q = db
      .collection(`babies/${babyId}/records`)
      .where('type', '==', recordType)
      .where('deleted', '==', false)
      .orderBy('occurredAt', 'desc')
      .limit(1);
    const snap = tx ? await tx.get(q) : await q.get();
    const doc = snap.docs[0];
    if (!doc) continue;
    const started = (doc.get('occurredAt') as Timestamp).toMillis();
    if (started <= best.started) continue;
    const ended = toDate(doc.get('endedAt'));
    best = {
      at: type === 'sleep' ? ended : new Date(started),
      recordId: doc.id,
      started,
    };
  }
  return { at: best.at, recordId: best.recordId };
}

function occurrence(
  tx: Transaction,
  rule: DocumentReference,
  dueAt: Date,
  outcome: ReminderOutcome,
  by: Member | { uid: string; author: Author } | null,
  now: Date,
  extra: Record<string, unknown> = {},
) {
  tx.set(rule.collection('occurrences').doc(), {
    dueAt: Timestamp.fromDate(dueAt),
    outcome,
    by: by?.uid ?? null,
    author: by?.author ?? null,
    at: Timestamp.fromDate(now),
    ...extra,
  });
  tx.update(rule, {
    lastOutcome: {
      outcome,
      dueAt: Timestamp.fromDate(dueAt),
      by: by?.uid ?? null,
      author: by?.author ?? null,
      at: Timestamp.fromDate(now),
      ...extra,
    },
  });
}

// ---------- Callables ----------

/** 1b → 1c / 1c2 → 1d "Lưu nhắc" (create or edit). */
export async function saveReminderRule(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ ruleId: string; nextDueAt: number | null }> {
  const req = parse(saveReminderRuleSchema, data);
  return db.runTransaction(async (tx) => {
    const me = await caller(db, tx, req.babyId, uid, now, true);
    const memberSnaps = await Promise.all(
      req.recipients.map((r) => tx.get(db.doc(`babies/${req.babyId}/members/${r}`))),
    );
    // 1d: only Cùng nuôi and Người chăm sóc can receive reminders.
    if (memberSnaps.some((s) => !canReceive(memberOf(s, now)))) {
      throw new ReminderRuleError('invalid-argument', 'recipient-not-allowed');
    }
    const ref = db.doc(`babies/${req.babyId}/reminderRules/${req.ruleId}`);
    const existing = await tx.get(ref);
    if (existing.exists && existing.get('type') !== req.type) {
      throw new ReminderRuleError('invalid-argument', 'type-changed');
    }
    const zone = await zoneOf(db, req.babyId, tx);
    const anchor = await anchorFor(db, req.babyId, req.type, tx);
    const times = [...req.times].sort();
    const days = [...req.days].sort();
    const schedule: RuleSchedule = {
      mode: req.mode,
      enabled: existing.exists ? existing.get('enabled') === true : true,
      intervalMinutes: req.intervalMinutes,
      times,
      days,
      quietNight: req.quietNight,
      anchorAt: anchor.at,
      // An edit starts afresh: no snooze, skip or unanswered reminder carries over.
      skipBase: null,
      snoozedUntil: null,
      pendingDueAt: null,
    };
    const next = nextDueOf(zone, schedule, now);
    tx.set(ref, {
      id: req.ruleId,
      babyId: req.babyId,
      type: req.type,
      mode: req.mode,
      intervalMinutes: req.intervalMinutes,
      times,
      days,
      quietNight: req.quietNight,
      recipients: req.recipients,
      enabled: schedule.enabled,
      anchorAt: toTs(anchor.at),
      anchorRecordId: anchor.recordId,
      skipBase: null,
      snoozedUntil: null,
      pendingDueAt: null,
      nextDueAt: toTs(next),
      lastOutcome: existing.exists ? (existing.get('lastOutcome') ?? null) : null,
      createdBy: existing.exists ? existing.get('createdBy') : uid,
      author: existing.exists ? existing.get('author') : me.author,
      createdAt: existing.exists ? existing.get('createdAt') : Timestamp.fromDate(now),
      updatedAt: Timestamp.fromDate(now),
      updatedBy: uid,
    });
    return { ruleId: req.ruleId, nextDueAt: next?.getTime() ?? null };
  });
}

/** 1a toggle: off = "Đang tạm dừng" (paused, kept). */
export async function setReminderRuleEnabled(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ nextDueAt: number | null }> {
  const req = parse(setReminderRuleEnabledSchema, data);
  return db.runTransaction(async (tx) => {
    await caller(db, tx, req.babyId, uid, now, true);
    const ref = db.doc(`babies/${req.babyId}/reminderRules/${req.ruleId}`);
    const rule = await tx.get(ref);
    if (!rule.exists) throw new ReminderRuleError('not-found', 'not-found');
    const zone = await zoneOf(db, req.babyId, tx);
    const anchor = req.enabled ? await anchorFor(db, req.babyId, rule.get('type'), tx) : null;
    const schedule: RuleSchedule = {
      ...scheduleOf(rule),
      enabled: req.enabled,
      anchorAt: anchor?.at ?? toDate(rule.get('anchorAt')),
      skipBase: null,
      snoozedUntil: null,
      pendingDueAt: null,
    };
    const next = nextDueOf(zone, schedule, now);
    tx.update(ref, {
      enabled: req.enabled,
      anchorAt: toTs(schedule.anchorAt),
      skipBase: null,
      snoozedUntil: null,
      pendingDueAt: null,
      nextDueAt: toTs(next),
      updatedAt: Timestamp.fromDate(now),
      updatedBy: uid,
    });
    return { nextDueAt: next?.getTime() ?? null };
  });
}

export async function deleteReminderRule(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ deleted: boolean }> {
  const req = parse(deleteReminderRuleSchema, data);
  const ref = db.doc(`babies/${req.babyId}/reminderRules/${req.ruleId}`);
  await db.runTransaction(async (tx) => {
    await caller(db, tx, req.babyId, uid, now, true);
  });
  await db.recursiveDelete(ref);
  return { deleted: true };
}

/**
 * 1f / 1g "Báo lại sau …" and "Bỏ qua lần này". If someone already handled the reminder, the
 * answer changes nothing and says who did (1h).
 */
export async function answerReminderRule(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ status: 'done' | 'handled'; nextDueAt: number | null }> {
  const req = parse(answerReminderRuleSchema, data);
  return db.runTransaction(async (tx) => {
    const me = await caller(db, tx, req.babyId, uid, now, false);
    const ref = db.doc(`babies/${req.babyId}/reminderRules/${req.ruleId}`);
    const rule = await tx.get(ref);
    if (!rule.exists) throw new ReminderRuleError('not-found', 'not-found');
    const pending = toDate(rule.get('pendingDueAt'));
    const next = toDate(rule.get('nextDueAt'));
    if (!pending || pending.getTime() !== req.dueAt) {
      return { status: 'handled' as const, nextDueAt: next?.getTime() ?? null };
    }
    const zone = await zoneOf(db, req.babyId, tx);
    const schedule = { ...scheduleOf(rule), pendingDueAt: null };
    let update: Record<string, unknown>;
    if (req.action === 'snooze') {
      const until = new Date(now.getTime() + req.minutes! * 60_000);
      update = {
        pendingDueAt: null,
        snoozedUntil: Timestamp.fromDate(until),
        nextDueAt: Timestamp.fromDate(until),
      };
      occurrence(tx, ref, pending, 'snoozed', me, now, { minutes: req.minutes });
    } else {
      const skipBase = schedule.mode === 'afterLast' ? pending : null;
      const after = nextDueOf(zone, { ...schedule, skipBase, snoozedUntil: null }, now);
      // A fixed rule already moved on to its next time when it rang; keep the later one.
      const keep = schedule.mode === 'fixed' && next && (!after || next < after) ? next : after;
      update = {
        pendingDueAt: null,
        snoozedUntil: null,
        skipBase: toTs(skipBase),
        nextDueAt: toTs(keep),
      };
      occurrence(tx, ref, pending, 'skipped', me, now);
    }
    tx.update(ref, update);
    const due = update.nextDueAt as Timestamp | null;
    return { status: 'done' as const, nextDueAt: due?.toMillis() ?? null };
  });
}

// ---------- Triggers ----------

/**
 * A care record was written: rules of that activity count from the newest log, and a reminder
 * that is due (or snoozed) is resolved for everyone by whoever logged first (1d, 1h).
 */
export async function onRecordForRules(
  db: Firestore,
  babyId: string,
  before: DocumentSnapshot | null,
  after: DocumentSnapshot | null,
  now: Date,
): Promise<{ updated: number }> {
  const recordType = ((after ?? before)?.get('type') as string | undefined) ?? '';
  const type = ruleTypeOfRecord(recordType);
  if (!type) return { updated: 0 };
  const rules = await db
    .collection(`babies/${babyId}/reminderRules`)
    .where('type', '==', type)
    .get();
  if (rules.empty) return { updated: 0 };
  // Only a new, live log answers a due reminder; edits and deletes just move the anchor.
  const logged = !before?.exists && after?.exists && after.get('deleted') !== true ? after : null;
  const zone = await zoneOf(db, babyId);
  let updated = 0;
  for (const r of rules.docs) {
    await db.runTransaction(async (tx) => {
      const rule = await tx.get(r.ref);
      if (!rule.exists) return;
      const anchor = await anchorFor(db, babyId, type, tx);
      const schedule = scheduleOf(rule);
      const waiting =
        schedule.pendingDueAt ??
        (schedule.snoozedUntil && schedule.snoozedUntil > now ? schedule.snoozedUntil : null);
      const update: Record<string, unknown> = {
        anchorAt: toTs(anchor.at),
        anchorRecordId: anchor.recordId,
      };
      const next: RuleSchedule = { ...schedule, anchorAt: anchor.at };
      if (logged && schedule.enabled) {
        // Any new log clears a skip; a due or snoozed reminder is handled by this person.
        next.skipBase = null;
        update.skipBase = null;
        if (waiting) {
          next.pendingDueAt = null;
          next.snoozedUntil = null;
          update.pendingDueAt = null;
          update.snoozedUntil = null;
          const author = (logged.get('author') as Author | undefined) ?? null;
          occurrence(
            tx,
            r.ref,
            schedule.pendingDueAt ?? waiting,
            'logged',
            {
              uid: logged.get('createdBy') as string,
              author: author ?? { name: '', relation: 'other', relationCustom: null },
            },
            now,
            { recordId: logged.id },
          );
        }
      }
      if (schedule.mode === 'afterLast' || !schedule.enabled) {
        update.nextDueAt = toTs(nextDueOf(zone, next, now));
      } else if (update.snoozedUntil === null && schedule.snoozedUntil) {
        // A fixed rule whose snooze was answered by the log goes back to its times.
        update.nextDueAt = toTs(nextDueOf(zone, next, now));
      }
      tx.update(r.ref, update);
      updated += 1;
    });
  }
  return { updated };
}

// ---------- Delivery ----------

const ruleName: Record<ReminderRuleType, { vi: string; en: string }> = {
  feed: { vi: 'nhắc bú', en: 'feeding reminder' },
  sleep: { vi: 'nhắc chuẩn bị ngủ', en: 'sleep reminder' },
  diaper: { vi: 'nhắc thay tã', en: 'diaper reminder' },
  pump: { vi: 'nhắc hút sữa', en: 'pumping reminder' },
};

const lastLabel: Record<ReminderRuleType, { vi: string; en: string }> = {
  feed: { vi: 'Lần bú gần nhất', en: 'Last feed' },
  sleep: { vi: 'Bé dậy lúc', en: 'Woke at' },
  diaper: { vi: 'Lần thay gần nhất', en: 'Last change' },
  pump: { vi: 'Lần hút sữa gần nhất', en: 'Last pump' },
};

function clock(zone: string, at: Date): string {
  return new Intl.DateTimeFormat('en-GB', {
    timeZone: zone,
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).format(at);
}

function ago(minutes: number, vi: boolean): string {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  if (vi) {
    if (h === 0) return `${m} phút trước`;
    return m === 0 ? `${h} giờ trước` : `${h} giờ ${m} phút trước`;
  }
  if (h === 0) return `${m} min ago`;
  return m === 0 ? `${h} h ago` : `${h} h ${m} min ago`;
}

/** 1f: "Đến giờ nhắc bú bạn đã đặt" / "Lần bú gần nhất 11:45 · 3 giờ trước" — no baby name. */
export function ruleCopy(
  type: ReminderRuleType,
  language: string,
  zone: string,
  anchorAt: Date | null,
  now: Date,
): { title: string; body: string } {
  const vi = !language.startsWith('en');
  const name = ruleName[type][vi ? 'vi' : 'en'];
  const title = vi ? `Đến giờ ${name} bạn đã đặt` : `Time for the ${name} you set`;
  if (!anchorAt) {
    return { title, body: vi ? 'Chưa có lần ghi nào gần đây' : 'Nothing logged recently' };
  }
  const minutes = Math.max(0, Math.round((now.getTime() - anchorAt.getTime()) / 60_000));
  const label = lastLabel[type][vi ? 'vi' : 'en'];
  return { title, body: `${label} ${clock(zone, anchorAt)} · ${ago(minutes, vi)}` };
}

/**
 * Every minute: rules whose time has come ring for their recipients. A fixed rule moves on to
 * its next time at once; an after-last rule waits for a log, a snooze or a skip.
 */
export async function fireDueRules(
  db: Firestore,
  sender: PushSender | null,
  now: Date,
): Promise<{ fired: number; sent: number }> {
  const due = await db
    .collectionGroup('reminderRules')
    .where('enabled', '==', true)
    .where('nextDueAt', '<=', Timestamp.fromDate(now))
    .limit(200)
    .get();
  let fired = 0;
  let sent = 0;
  for (const doc of due.docs) {
    const babyId = doc.ref.parent.parent!.id;
    const zone = await zoneOf(db, babyId);
    const rang = await db.runTransaction(async (tx) => {
      const rule = await tx.get(doc.ref);
      const dueAt = toDate(rule.get('nextDueAt'));
      if (!rule.exists || rule.get('enabled') !== true || !dueAt || dueAt > now) return null;
      const schedule = scheduleOf(rule);
      // A fixed time that rang unanswered before this one counts as missed.
      if (schedule.pendingDueAt && schedule.pendingDueAt.getTime() !== dueAt.getTime()) {
        occurrence(tx, doc.ref, schedule.pendingDueAt, 'missed', null, now);
      }
      const ringing: RuleSchedule = { ...schedule, pendingDueAt: dueAt, snoozedUntil: null };
      tx.update(doc.ref, {
        pendingDueAt: Timestamp.fromDate(dueAt),
        snoozedUntil: null,
        firedAt: Timestamp.fromDate(now),
        nextDueAt: toTs(nextDueOf(zone, ringing, now, dueAt)),
      });
      return {
        dueAt,
        type: rule.get('type') as ReminderRuleType,
        recipients: (rule.get('recipients') as string[] | undefined) ?? [],
        anchorAt: schedule.anchorAt,
      };
    });
    if (!rang) continue;
    fired += 1;
    sent += await pushRule(db, sender, babyId, doc.id, zone, rang, now);
  }
  return { fired, sent };
}

async function pushRule(
  db: Firestore,
  sender: PushSender | null,
  babyId: string,
  ruleId: string,
  zone: string,
  rang: { dueAt: Date; type: ReminderRuleType; recipients: string[]; anchorAt: Date | null },
  now: Date,
): Promise<number> {
  // Someone who left, or became a relative, stops receiving.
  const members = await db.getAll(
    ...rang.recipients.map((uid) => db.doc(`babies/${babyId}/members/${uid}`)),
  );
  const eligible = members.filter((m) => canReceive(memberOf(m, now))).map((m) => m.id);
  // ENG-04 cohort precedes category/channel filtering. Measurement never changes the schedule.
  await Promise.allSettled(
    eligible.map((uid) =>
      careInboxEngagement(
        db,
        uid,
        {
          kind: 'reminderRule',
          babyId,
          data: { ruleId, dueAt: String(rang.dueAt.getTime()) },
          eligibilityOnly: true,
        },
        now,
      ),
    ),
  );
  // D-076 #2: pushed, recorded in the inbox and switched by EN07 "Bú, ngủ, thay tã" in one place.
  const { sent } = await notifyUsers(
    db,
    sender,
    eligible,
    {
      kind: 'reminderRule',
      onResult: (uid, result) =>
        careAdapterResult(db, uid, babyId, ruleId, rang.dueAt.getTime(), result, now),
      id: `rr-${ruleId}-${rang.dueAt.getTime()}`,
      babyId,
      data: {
        kind: 'reminderRule',
        babyId,
        ruleId,
        type: rang.type,
        dueAt: String(rang.dueAt.getTime()),
      },
      message: (language) => ({
        ...ruleCopy(rang.type, language, zone, rang.anchorAt, now),
        // 1f actions (iOS categories registered by the app; Android draws them, A6); one
        // notification per rule.
        androidDraws: true,
        apns: {
          category: `CL_RULE_${rang.type.toUpperCase()}`,
          collapseId: `rr-${ruleId}`,
          threadId: ruleId,
        },
      }),
      zone,
    },
    now,
  );
  return sent;
}
