import {
  FieldValue,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import { randomBytes } from 'node:crypto';
import {
  ageInMonths,
  assignCarePlanItemsSchema,
  carePlanAssignable,
  carePlanCan,
  carePlanLimits,
  carePlanRhythmDays,
  dayBoundsIn,
  deleteCarePlanItemSchema,
  isDraftMethod,
  publishCarePlanDaySchema,
  rhythmDraft,
  rhythmReady,
  saveCarePlanItemSchema,
  setCarePlanAutoDraftSchema,
  setCarePlanItemStatusSchema,
  startCarePlanDaySchema,
  templateDraft,
  templateOffered,
  type CarePlanMethod,
  type CarePlanRight,
  type MemberRole,
  type RhythmEvent,
} from '@child-life/contracts';
import { localInstant } from './assistant-tools.js';
import { currentProjectId, environmentForProject } from './env.js';
import { isActiveMember } from './family.js';

/**
 * Cùng Chăm Con (D-135): the day's shared plan of care tasks. Only these callables write it;
 * every write bumps the day's `revision` and adds one history entry (who, what, when). Nothing
 * about the child is logged. Each task also keeps `dueAt` (its time in the baby's zone, for the
 * N1 reminder query) and its own `revision`, bumped when its time or people change, so an edited
 * task is reminded again (`care-plan-reminders.ts`).
 */

export class CarePlanError extends Error {
  constructor(
    readonly code: 'invalid-argument' | 'permission-denied' | 'not-found' | 'failed-precondition',
    readonly reason: string,
  ) {
    super(reason);
  }
}

function parse<T>(
  schema: { safeParse(d: unknown): { success: boolean; data?: T } },
  data: unknown,
): T {
  const r = schema.safeParse(data);
  if (!r.success) throw new CarePlanError('invalid-argument', 'malformed');
  return r.data as T;
}

const dayRef = (db: Firestore, babyId: string, date: string) =>
  db.doc(`babies/${babyId}/carePlanDays/${date}`);
const itemsOf = (db: Firestore, babyId: string, date: string) =>
  db.collection(`babies/${babyId}/carePlanDays/${date}/items`);
const templateOf = (db: Firestore, babyId: string) =>
  db.collection(`babies/${babyId}/carePlanTemplate`);
const historyOf = (db: Firestore, babyId: string) =>
  db.collection(`babies/${babyId}/carePlanHistory`);
/** "Tự tạo lịch mỗi sáng" and the method last used (D-136 #3), server-written. */
export const carePlanSettingsRef = (db: Firestore, babyId: string) =>
  db.doc(`babies/${babyId}/carePlanSettings/family`);

const newId = (prefix: 'pi' | 'pt') => `${prefix}_${randomBytes(16).toString('hex')}`;

/** "2026-10-28" in [zone] for [at]. */
export function dateKeyIn(zone: string, at: Date): string {
  const p = new Intl.DateTimeFormat('en-CA', {
    timeZone: zone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(at);
  const v = (t: string) => p.find((x) => x.type === t)?.value ?? '';
  return `${v('year')}-${v('month')}-${v('day')}`;
}

/** [date] moved by [days] (calendar arithmetic, no zone). */
export function shiftDateKey(date: string, days: number): string {
  const d = new Date(`${date}T12:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

/** Plans can be changed from yesterday (late entries) up to a week ahead; older days are read-only. */
export function editableDate(zone: string, date: string, now: Date): boolean {
  const today = dateKeyIn(zone, now);
  return date >= shiftDateKey(today, -1) && date <= shiftDateKey(today, 6);
}

interface Caller {
  uid: string;
  role: MemberRole;
  zone: string;
}

/** The instant a task at [time] on [date] is due, in the baby's [zone]. */
export function carePlanDueAt(zone: string, date: string, time: string): Timestamp {
  return Timestamp.fromDate(localInstant(zone, date, time));
}

/** Reads the baby and the caller (inside [tx]) and checks [right] and the date. */
async function caller(
  db: Firestore,
  tx: Transaction,
  babyId: string,
  date: string,
  uid: string,
  now: Date,
  right: CarePlanRight,
): Promise<Caller> {
  const [baby, member] = await Promise.all([
    tx.get(db.doc(`babies/${babyId}`)),
    tx.get(db.doc(`babies/${babyId}/members/${uid}`)),
  ]);
  if (!baby.exists) throw new CarePlanError('not-found', 'not-found');
  if ((baby.get('state') ?? 'active') !== 'active') {
    throw new CarePlanError('failed-precondition', 'baby-closed');
  }
  if (!isActiveMember(member, now) || !carePlanCan(member.get('role'), right)) {
    throw new CarePlanError('permission-denied', 'not-allowed');
  }
  const zone = (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh';
  if (!editableDate(zone, date, now)) {
    throw new CarePlanError('failed-precondition', 'day-closed');
  }
  return { uid, role: member.get('role'), zone };
}

/** Every assignee must be an active Cùng nuôi or Người chăm sóc (D-018: never a relative). */
async function checkAssignees(
  db: Firestore,
  tx: Transaction,
  babyId: string,
  uids: string[],
  now: Date,
): Promise<void> {
  const snaps = await Promise.all(uids.map((u) => tx.get(db.doc(`babies/${babyId}/members/${u}`))));
  if (snaps.some((s) => !isActiveMember(s, now) || !carePlanAssignable(s.get('role')))) {
    throw new CarePlanError('invalid-argument', 'assignee-not-allowed');
  }
}

/** The day must exist before its tasks change (04-0 starts it). */
async function requireDay(
  db: Firestore,
  tx: Transaction,
  babyId: string,
  date: string,
): Promise<DocumentSnapshot> {
  const day = await tx.get(dayRef(db, babyId, date));
  if (!day.exists) throw new CarePlanError('failed-precondition', 'no-day');
  return day;
}

/** The same people, in any order. */
function sameMembers(a: string[] | undefined, b: string[]): boolean {
  const x = new Set(a ?? []);
  return x.size === b.length && b.every((u) => x.has(u));
}

function bump(tx: Transaction, day: DocumentSnapshot, uid: string, now: Date) {
  tx.update(day.ref, {
    revision: FieldValue.increment(1),
    updatedAt: Timestamp.fromDate(now),
    updatedBy: uid,
  });
}

interface HistoryEntry {
  action: 'start' | 'publish' | 'add' | 'edit' | 'delete' | 'assign' | 'done' | 'undone' | 'skip';
  date: string;
  itemIds?: string[];
  task?: string | null;
  title?: string | null;
  time?: string | null;
  scope?: 'today' | 'everyDay' | null;
  assignees?: string[] | null;
  from?: string | null;
  /** 20 Lịch sử thay đổi: the time before an edit ("Bú bình 13:00 → 13:30"), for Hoàn tác. */
  oldTime?: string | null;
}

function record(
  db: Firestore,
  tx: Transaction,
  babyId: string,
  uid: string,
  now: Date,
  e: HistoryEntry,
) {
  tx.set(historyOf(db, babyId).doc(), {
    at: Timestamp.fromDate(now),
    by: uid,
    action: e.action,
    date: e.date,
    itemIds: e.itemIds ?? [],
    task: e.task ?? null,
    title: e.title ?? null,
    time: e.time ?? null,
    scope: e.scope ?? null,
    assignees: e.assignees ?? null,
    from: e.from ?? null,
    oldTime: e.oldTime ?? null,
  });
}

// ---------- Callables ----------

type Seed = {
  task: string;
  title: string | null;
  time: string;
  assignees: string[];
  templateId: string | null;
  /** D-138: the planned ml of a bottle or pumping. */
  amountMl?: number | null;
};

/** The reference templates are offered on dev only until the owner reviews them (D-136 #1). */
export function carePlanTemplatesOffered(): boolean {
  try {
    return environmentForProject(currentProjectId()) === 'dev';
  } catch {
    return false;
  }
}

/** Feeds and sleeps of the [carePlanRhythmDays] days before [date], and the usual feed. */
async function rhythmEvents(
  db: Firestore,
  tx: Transaction,
  babyId: string,
  zone: string,
  date: string,
): Promise<{ events: RhythmEvent[]; dates: string[]; feed: 'bottle' | 'breast' }> {
  const dates = Array.from({ length: carePlanRhythmDays }, (_, i) =>
    shiftDateKey(date, i - carePlanRhythmDays),
  );
  const start = dayBoundsIn(zone, dates[0]!).start;
  const end = dayBoundsIn(zone, dates[dates.length - 1]!).end;
  const snap = await tx.get(
    db
      .collection(`babies/${babyId}/records`)
      .where('occurredAt', '>=', start)
      .where('occurredAt', '<', end),
  );
  const clock = new Intl.DateTimeFormat('en-GB', {
    timeZone: zone,
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  });
  const events: RhythmEvent[] = [];
  let bottles = 0;
  let breasts = 0;
  for (const d of snap.docs) {
    if (d.get('deleted') === true) continue;
    const type = d.get('type') as string;
    const at = d.get('occurredAt');
    if (!(at instanceof Timestamp)) continue;
    const kind =
      type === 'bottle' || type === 'breast' ? 'feed' : type === 'sleep' ? 'sleep' : null;
    if (!kind) continue;
    if (type === 'bottle') bottles += 1;
    if (type === 'breast') breasts += 1;
    const [h, m] = clock.format(at.toDate()).split(':').map(Number);
    events.push({ kind, date: dateKeyIn(zone, at.toDate()), minute: h! * 60 + m! });
  }
  return { events, dates, feed: breasts > bottles ? 'breast' : 'bottle' };
}

/**
 * The tasks a day starts with by [method]. Throws `not-enough-data` (rhythm, D-136 #2) and
 * `template-unavailable` (templates outside dev, D-136 #1).
 */
async function seedsFor(
  db: Firestore,
  tx: Transaction,
  babyId: string,
  date: string,
  zone: string,
  method: CarePlanMethod,
): Promise<Seed[]> {
  const plain = (t: { task: string; time: string }): Seed => ({
    task: t.task,
    title: null,
    time: t.time,
    assignees: [],
    templateId: null,
  });
  switch (method) {
    case 'everyday': {
      const t = await tx.get(templateOf(db, babyId));
      return t.docs.map((d) => ({
        task: d.get('task'),
        title: d.get('title') ?? null,
        time: d.get('time'),
        assignees: d.get('assignees') ?? [],
        templateId: d.id,
        amountMl: d.get('amountMl') ?? null,
      }));
    }
    case 'yesterday': {
      const y = await tx.get(itemsOf(db, babyId, shiftDateKey(date, -1)));
      return y.docs.map((d) => ({
        task: d.get('task'),
        title: d.get('title') ?? null,
        time: d.get('time'),
        assignees: d.get('assignees') ?? [],
        templateId: d.get('templateId') ?? null,
        amountMl: d.get('amountMl') ?? null,
      }));
    }
    case 'empty':
      return [];
    case 'rhythm': {
      const r = await rhythmEvents(db, tx, babyId, zone, date);
      if (!rhythmReady(r.events, r.dates)) {
        throw new CarePlanError('failed-precondition', 'not-enough-data');
      }
      return rhythmDraft(r.events, r.dates.length, r.feed).map(plain);
    }
    case 'basic':
    case 'easy35':
    case 'easy4': {
      if (!carePlanTemplatesOffered()) {
        throw new CarePlanError('failed-precondition', 'template-unavailable');
      }
      const [profile, r] = await Promise.all([
        tx.get(db.doc(`babies/${babyId}/restricted/profile`)),
        rhythmEvents(db, tx, babyId, zone, date),
      ]);
      const dob = profile.get('dateOfBirth');
      const known =
        typeof dob === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(dob) && dob <= date
          ? ageInMonths(dob, date)
          : null;
      // D-136 #4: EASY only for a baby under 6 months.
      if (!templateOffered(method, known)) {
        throw new CarePlanError('failed-precondition', 'template-unavailable');
      }
      return templateDraft(method, known ?? 4, r.feed).map(plain);
    }
  }
}

/**
 * Writes a new day (or replaces a draft's tasks) from [seeds]. A drafted method makes a draft:
 * its tasks carry `draft: true` and are not reminded (N1) until "Dùng lịch này".
 */
async function writeDay(
  db: Firestore,
  tx: Transaction,
  p: {
    babyId: string;
    date: string;
    zone: string;
    method: CarePlanMethod;
    seeds: Seed[];
    draft: boolean;
    by: string;
    now: Date;
    replacing: DocumentSnapshot | null;
  },
): Promise<void> {
  // Who left the family since is not carried over.
  const people = [...new Set(p.seeds.flatMap((s) => s.assignees))];
  const snaps = await Promise.all(
    people.map((u) => tx.get(db.doc(`babies/${p.babyId}/members/${u}`))),
  );
  const still = new Set(
    snaps
      .filter((s) => isActiveMember(s, p.now) && carePlanAssignable(s.get('role')))
      .map((s) => s.id),
  );
  const old = p.replacing ? await tx.get(itemsOf(db, p.babyId, p.date)) : null;
  const seeds = p.seeds.slice(0, carePlanLimits.itemsPerDay);
  const draft = p.draft;
  const at = Timestamp.fromDate(p.now);
  for (const d of old?.docs ?? []) tx.delete(d.ref);
  const ref = dayRef(db, p.babyId, p.date);
  if (p.replacing) {
    tx.update(ref, {
      source: p.method,
      status: draft ? 'draft' : 'published',
      revision: FieldValue.increment(1),
      updatedAt: at,
      updatedBy: p.by,
    });
  } else {
    tx.set(ref, {
      babyId: p.babyId,
      date: p.date,
      source: p.method,
      status: draft ? 'draft' : 'published',
      revision: 1,
      createdAt: at,
      createdBy: p.by,
      updatedAt: at,
      updatedBy: p.by,
    });
  }
  for (const s of seeds) {
    const id = newId('pi');
    tx.set(itemsOf(db, p.babyId, p.date).doc(id), {
      id,
      babyId: p.babyId,
      date: p.date,
      task: s.task,
      title: s.title,
      time: s.time,
      dueAt: carePlanDueAt(p.zone, p.date, s.time),
      revision: 1,
      assignees: s.assignees.filter((u) => still.has(u)),
      amountMl: s.amountMl ?? null,
      status: 'open',
      templateId: s.templateId,
      ...(draft ? { draft: true } : {}),
      doneBy: null,
      doneAt: null,
      createdAt: at,
      createdBy: p.by,
      updatedAt: at,
      updatedBy: p.by,
    });
  }
}

/**
 * 04-0 / 01: start the day. A day that exists is returned as it is (retries, two parents), except
 * a draft started again with another method ("Đổi cách khác"), whose tasks are replaced. The
 * method (other than `empty`) is kept as the family's, for the morning draft.
 */
export async function startCarePlanDay(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ created: boolean; items: number; draft: boolean }> {
  const req = parse(startCarePlanDaySchema, data);
  return db.runTransaction(async (tx) => {
    const { zone } = await caller(db, tx, req.babyId, req.date, uid, now, 'manage');
    const ref = dayRef(db, req.babyId, req.date);
    const day = await tx.get(ref);
    const isDraft = day.exists && day.get('status') === 'draft';
    if (day.exists && (!isDraft || day.get('source') === req.from)) {
      const items = await tx.get(itemsOf(db, req.babyId, req.date));
      return { created: false, items: items.size, draft: isDraft };
    }
    const seeds = await seedsFor(db, tx, req.babyId, req.date, zone, req.from);
    await writeDay(db, tx, {
      babyId: req.babyId,
      date: req.date,
      zone,
      method: req.from,
      seeds,
      draft: isDraftMethod(req.from),
      by: uid,
      now,
      replacing: day.exists ? day : null,
    });
    if (req.from !== 'empty') {
      tx.set(
        carePlanSettingsRef(db, req.babyId),
        { method: req.from, updatedAt: Timestamp.fromDate(now), updatedBy: uid },
        { merge: true },
      );
    }
    record(db, tx, req.babyId, uid, now, { action: 'start', date: req.date, from: req.from });
    return {
      created: true,
      items: Math.min(seeds.length, carePlanLimits.itemsPerDay),
      draft: isDraftMethod(req.from),
    };
  });
}

/** 02 "Dùng lịch này": the draft becomes the plan; its tasks are reminded from now on. */
export async function publishCarePlanDay(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ published: boolean }> {
  const req = parse(publishCarePlanDaySchema, data);
  return db.runTransaction(async (tx) => {
    await caller(db, tx, req.babyId, req.date, uid, now, 'manage');
    const day = await requireDay(db, tx, req.babyId, req.date);
    // Already in use (a retry, or the other parent tapped first).
    if (day.get('status') !== 'draft') return { published: false };
    const items = await tx.get(itemsOf(db, req.babyId, req.date));
    const at = Timestamp.fromDate(now);
    for (const i of items.docs) {
      if (i.get('draft') === true) tx.update(i.ref, { draft: FieldValue.delete(), updatedAt: at });
    }
    tx.update(day.ref, { status: 'published', publishedAt: at, publishedBy: uid });
    bump(tx, day, uid, now);
    record(db, tx, req.babyId, uid, now, { action: 'publish', date: req.date });
    return { published: true };
  });
}

/** 13 "Tự tạo lịch mỗi sáng" (D-136 #3): plan managers turn it on or off for the family. */
export async function setCarePlanAutoDraft(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ on: boolean }> {
  const req = parse(setCarePlanAutoDraftSchema, data);
  const member = await db.doc(`babies/${req.babyId}/members/${uid}`).get();
  if (!isActiveMember(member, now) || !carePlanCan(member.get('role'), 'manage')) {
    throw new CarePlanError('permission-denied', 'not-allowed');
  }
  await carePlanSettingsRef(db, req.babyId).set(
    { autoDraft: req.on, updatedAt: Timestamp.fromDate(now), updatedBy: uid },
    { merge: true },
  );
  return { on: req.on };
}

/**
 * The morning draft of one baby (`care-plan-morning.ts`): the family's method for [date], as a
 * draft, unless the day exists. Returns how many tasks it holds and the first, or null when
 * nothing was made (a day exists, no tasks, not enough data, templates not offered).
 */
export async function draftCarePlanDay(
  db: Firestore,
  babyId: string,
  date: string,
  zone: string,
  method: CarePlanMethod,
  now: Date,
): Promise<{ items: number; first: { task: string; time: string } } | null> {
  return db.runTransaction(async (tx) => {
    const day = await tx.get(dayRef(db, babyId, date));
    if (day.exists) return null;
    let seeds: Seed[];
    try {
      seeds = await seedsFor(db, tx, babyId, date, zone, method);
    } catch (e) {
      if (e instanceof CarePlanError) return null;
      throw e;
    }
    if (seeds.length === 0) return null;
    // Always a draft in the morning, whatever the method (D-136 #3).
    await writeDay(db, tx, {
      babyId,
      date,
      zone,
      method,
      seeds,
      draft: true,
      by: 'system',
      now,
      replacing: null,
    });
    record(db, tx, babyId, 'system', now, { action: 'start', date, from: method });
    const sorted = [...seeds].sort((a, b) => a.time.localeCompare(b.time));
    return {
      items: Math.min(seeds.length, carePlanLimits.itemsPerDay),
      first: { task: sorted[0]!.task, time: sorted[0]!.time },
    };
  });
}

/** 06 / 06b: create or edit a task; "Mọi ngày" also keeps it in the everyday tasks. */
export async function saveCarePlanItem(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ itemId: string; templateId: string | null }> {
  const req = parse(saveCarePlanItemSchema, data);
  return db.runTransaction(async (tx) => {
    const { zone } = await caller(db, tx, req.babyId, req.date, uid, now, 'manage');
    const day = await requireDay(db, tx, req.babyId, req.date);
    const ref = itemsOf(db, req.babyId, req.date).doc(req.itemId);
    const existing = await tx.get(ref);
    if (!existing.exists) {
      const all = await tx.get(itemsOf(db, req.babyId, req.date));
      if (all.size >= carePlanLimits.itemsPerDay) {
        throw new CarePlanError('failed-precondition', 'too-many');
      }
    }
    const oldTemplateId = existing.exists
      ? ((existing.get('templateId') as string | null) ?? null)
      : null;
    const template = oldTemplateId
      ? await tx.get(templateOf(db, req.babyId).doc(oldTemplateId))
      : null;
    await checkAssignees(db, tx, req.babyId, req.assignees, now);

    const at = Timestamp.fromDate(now);
    const title = req.task === 'custom' ? req.title : null;
    let templateId = oldTemplateId;
    if (req.scope === 'everyDay') {
      templateId = template?.exists ? oldTemplateId : newId('pt');
      tx.set(templateOf(db, req.babyId).doc(templateId!), {
        id: templateId,
        task: req.task,
        title,
        time: req.time,
        assignees: req.assignees,
        amountMl: req.amountMl ?? null,
        updatedAt: at,
        updatedBy: uid,
      });
    }
    const oldRevision = existing.exists
      ? ((existing.get('revision') as number | undefined) ?? 0)
      : 0;
    const moved =
      !existing.exists ||
      existing.get('time') !== req.time ||
      !sameMembers(existing.get('assignees') as string[] | undefined, req.assignees);
    tx.set(ref, {
      id: req.itemId,
      babyId: req.babyId,
      date: req.date,
      task: req.task,
      title,
      time: req.time,
      dueAt: carePlanDueAt(zone, req.date, req.time),
      revision: moved ? oldRevision + 1 : oldRevision,
      assignees: req.assignees,
      amountMl: req.amountMl ?? null,
      // Who gave the task to its people ("Mẹ nhờ Ba nhé", Figma 15): kept until they change.
      assignedBy: sameMembers(existing.get('assignees') as string[] | undefined, req.assignees)
        ? (existing.get('assignedBy') ?? null)
        : req.assignees.length > 0
          ? uid
          : null,
      status: existing.exists ? existing.get('status') : 'open',
      templateId,
      // A task added to or edited in a draft waits for "Dùng lịch này" like the others.
      ...(day.get('status') === 'draft' ? { draft: true } : {}),
      doneBy: existing.exists ? (existing.get('doneBy') ?? null) : null,
      doneAt: existing.exists ? (existing.get('doneAt') ?? null) : null,
      createdAt: existing.exists ? existing.get('createdAt') : at,
      createdBy: existing.exists ? existing.get('createdBy') : uid,
      updatedAt: at,
      updatedBy: uid,
    });
    bump(tx, day, uid, now);
    record(db, tx, req.babyId, uid, now, {
      action: existing.exists ? 'edit' : 'add',
      date: req.date,
      itemIds: [req.itemId],
      task: req.task,
      title,
      time: req.time,
      scope: req.scope,
      assignees: req.assignees,
      oldTime:
        existing.exists && existing.get('time') !== req.time
          ? (existing.get('time') as string)
          : null,
    });
    return { itemId: req.itemId, templateId };
  });
}

/** 06b "Xoá": today only, or also from every day. */
export async function deleteCarePlanItem(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ deleted: boolean }> {
  const req = parse(deleteCarePlanItemSchema, data);
  return db.runTransaction(async (tx) => {
    await caller(db, tx, req.babyId, req.date, uid, now, 'manage');
    const day = await requireDay(db, tx, req.babyId, req.date);
    const ref = itemsOf(db, req.babyId, req.date).doc(req.itemId);
    const item = await tx.get(ref);
    // Already gone (a retry, or someone else deleted it): nothing to do.
    if (!item.exists) return { deleted: false };
    const templateId = (item.get('templateId') as string | null) ?? null;
    tx.delete(ref);
    if (req.scope === 'everyDay' && templateId) {
      tx.delete(templateOf(db, req.babyId).doc(templateId));
    }
    bump(tx, day, uid, now);
    record(db, tx, req.babyId, uid, now, {
      action: 'delete',
      date: req.date,
      itemIds: [req.itemId],
      task: item.get('task'),
      title: item.get('title') ?? null,
      time: item.get('time'),
      scope: req.scope,
    });
    return { deleted: true };
  });
}

/** 05 Giao việc: the same people on one task or a whole group; today only. */
export async function assignCarePlanItems(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ updated: number }> {
  const req = parse(assignCarePlanItemsSchema, data);
  return db.runTransaction(async (tx) => {
    await caller(db, tx, req.babyId, req.date, uid, now, 'manage');
    const day = await requireDay(db, tx, req.babyId, req.date);
    const ids = [...new Set(req.itemIds)];
    const items = await Promise.all(
      ids.map((id) => tx.get(itemsOf(db, req.babyId, req.date).doc(id))),
    );
    await checkAssignees(db, tx, req.babyId, req.assignees, now);
    const found = items.filter((i) => i.exists);
    if (found.length === 0) throw new CarePlanError('not-found', 'not-found');
    const at = Timestamp.fromDate(now);
    for (const i of found) {
      if (sameMembers(i.get('assignees') as string[] | undefined, req.assignees)) continue;
      tx.update(i.ref, {
        assignees: req.assignees,
        assignedBy: req.assignees.length > 0 ? uid : null,
        revision: FieldValue.increment(1),
        updatedAt: at,
        updatedBy: uid,
      });
    }
    bump(tx, day, uid, now);
    record(db, tx, req.babyId, uid, now, {
      action: 'assign',
      date: req.date,
      itemIds: found.map((i) => i.id),
      assignees: req.assignees,
    });
    return { updated: found.length };
  });
}

/**
 * The ring: done (by the caller, whoever was assigned) or open again; "Bỏ qua" (skipped) needs
 * the right to manage. Setting the status it already has changes nothing (retries).
 */
export async function setCarePlanItemStatus(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ status: string; doneBy: string | null }> {
  const req = parse(setCarePlanItemStatusSchema, data);
  return db.runTransaction(async (tx) => {
    const me = await caller(db, tx, req.babyId, req.date, uid, now, 'complete');
    const ref = itemsOf(db, req.babyId, req.date).doc(req.itemId);
    const [day, item] = await Promise.all([requireDay(db, tx, req.babyId, req.date), tx.get(ref)]);
    if (!item.exists) throw new CarePlanError('not-found', 'not-found');
    const old = item.get('status') as string;
    const touchesSkip = req.status === 'skipped' || old === 'skipped';
    if (touchesSkip && !carePlanCan(me.role, 'manage')) {
      throw new CarePlanError('permission-denied', 'not-allowed');
    }
    if (old === req.status) {
      return { status: old, doneBy: (item.get('doneBy') as string | null) ?? null };
    }
    const at = Timestamp.fromDate(now);
    const done = req.status === 'done';
    tx.update(ref, {
      status: req.status,
      doneBy: done ? uid : null,
      doneAt: done ? at : null,
      updatedAt: at,
      updatedBy: uid,
    });
    bump(tx, day, uid, now);
    record(db, tx, req.babyId, uid, now, {
      action: done ? 'done' : req.status === 'skipped' ? 'skip' : 'undone',
      date: req.date,
      itemIds: [req.itemId],
      task: item.get('task'),
      time: item.get('time'),
    });
    return { status: req.status, doneBy: done ? uid : null };
  });
}
