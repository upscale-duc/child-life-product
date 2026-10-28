import {
  FieldValue,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import { randomBytes } from 'node:crypto';
import {
  assignCarePlanItemsSchema,
  carePlanAssignable,
  carePlanCan,
  carePlanLimits,
  deleteCarePlanItemSchema,
  saveCarePlanItemSchema,
  setCarePlanItemStatusSchema,
  startCarePlanDaySchema,
  type CarePlanRight,
  type MemberRole,
} from '@child-life/contracts';
import { localInstant } from './assistant-tools.js';
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
  action: 'start' | 'add' | 'edit' | 'delete' | 'assign' | 'done' | 'undone' | 'skip';
  date: string;
  itemIds?: string[];
  task?: string | null;
  title?: string | null;
  time?: string | null;
  scope?: 'today' | 'everyDay' | null;
  assignees?: string[] | null;
  from?: string | null;
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
  });
}

// ---------- Callables ----------

/** 04-0: start the day; a day that already exists is returned as it is (retries, two parents). */
export async function startCarePlanDay(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ created: boolean; items: number }> {
  const req = parse(startCarePlanDaySchema, data);
  return db.runTransaction(async (tx) => {
    const { zone } = await caller(db, tx, req.babyId, req.date, uid, now, 'manage');
    const ref = dayRef(db, req.babyId, req.date);
    const day = await tx.get(ref);
    if (day.exists) {
      const items = await tx.get(itemsOf(db, req.babyId, req.date));
      return { created: false, items: items.size };
    }
    type Seed = {
      task: string;
      title: string | null;
      time: string;
      assignees: string[];
      templateId: string | null;
    };
    let seeds: Seed[] = [];
    if (req.from === 'everyday') {
      const t = await tx.get(templateOf(db, req.babyId));
      seeds = t.docs.map((d) => ({
        task: d.get('task'),
        title: d.get('title') ?? null,
        time: d.get('time'),
        assignees: d.get('assignees') ?? [],
        templateId: d.id,
      }));
    } else if (req.from === 'yesterday') {
      const y = await tx.get(itemsOf(db, req.babyId, shiftDateKey(req.date, -1)));
      seeds = y.docs.map((d) => ({
        task: d.get('task'),
        title: d.get('title') ?? null,
        time: d.get('time'),
        assignees: d.get('assignees') ?? [],
        templateId: d.get('templateId') ?? null,
      }));
    }
    // Who left the family since is not carried over.
    const people = [...new Set(seeds.flatMap((s) => s.assignees))];
    const snaps = await Promise.all(
      people.map((u) => tx.get(db.doc(`babies/${req.babyId}/members/${u}`))),
    );
    const still = new Set(
      snaps
        .filter((s) => isActiveMember(s, now) && carePlanAssignable(s.get('role')))
        .map((s) => s.id),
    );
    seeds = seeds.slice(0, carePlanLimits.itemsPerDay);
    const at = Timestamp.fromDate(now);
    tx.set(ref, {
      babyId: req.babyId,
      date: req.date,
      source: req.from,
      revision: 1,
      createdAt: at,
      createdBy: uid,
      updatedAt: at,
      updatedBy: uid,
    });
    for (const s of seeds) {
      const id = newId('pi');
      tx.set(itemsOf(db, req.babyId, req.date).doc(id), {
        id,
        babyId: req.babyId,
        date: req.date,
        task: s.task,
        title: s.title,
        time: s.time,
        dueAt: carePlanDueAt(zone, req.date, s.time),
        revision: 1,
        assignees: s.assignees.filter((u) => still.has(u)),
        status: 'open',
        templateId: s.templateId,
        doneBy: null,
        doneAt: null,
        createdAt: at,
        createdBy: uid,
        updatedAt: at,
        updatedBy: uid,
      });
    }
    record(db, tx, req.babyId, uid, now, { action: 'start', date: req.date, from: req.from });
    return { created: true, items: seeds.length };
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
      status: existing.exists ? existing.get('status') : 'open',
      templateId,
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
