import { createHash } from 'node:crypto';
import {
  NOTIFICATION_LEDGER_RETENTION_DAYS,
  canTransition,
  localDateIn,
  type NotificationActionState,
  type NotificationDeliveryReason,
  type NotificationDeliveryState,
  type NotificationLifecycleState,
  type NotificationStatMetric,
} from '@child-life/contracts';
import {
  FieldValue,
  Timestamp,
  type DocumentReference,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';

/**
 * Notification ledger (P-174, docs/notifications/03-lifecycle-and-data-model.md): one server-only
 * entry per recipient and notice in `notificationDeliveries/{d_…}`, the current state of four
 * independent dimensions (lifecycle, delivery, read, action) plus a bounded append-only `history`.
 * Every transition is validated by `canTransition`, so a stale worker or a late retry never moves a
 * dimension backwards. The first time an entry reaches a state, the matching counter on
 * `notificationStats/{day}_{shard}` moves in the same transaction: daily stats count each entry
 * once per metric, whatever the retries. Nothing about the child or the copy is stored here.
 */

export const LEDGER = 'notificationDeliveries';
export const STATS = 'notificationStats';
const STAT_SHARDS = 8;
const HISTORY_MAX = 24;
const DAY_MS = 86_400_000;
export const STATS_ZONE = 'Asia/Ho_Chi_Minh';

export function ledgerId(uid: string, dedupKey: string): string {
  return `d_${createHash('sha256').update(`${uid}\n${dedupKey}`).digest('hex').slice(0, 40)}`;
}

export function ledgerRef(db: Firestore, id: string): DocumentReference {
  return db.doc(`${LEDGER}/${id}`);
}

export function ledgerDeleteAfter(now: Date): Date {
  return new Date(now.getTime() + NOTIFICATION_LEDGER_RETENTION_DAYS * DAY_MS);
}

/** The stats doc an entry counts in: its creation day (Vietnam time) and a stable shard. */
export function statsRef(db: Firestore, entryId: string, createdAt: Date): DocumentReference {
  const day = localDateIn(STATS_ZONE, createdAt);
  const shard = parseInt(entryId.slice(2, 6), 16) % STAT_SHARDS;
  return db.doc(`${STATS}/${day}_${shard}`);
}

export interface StatKeys {
  kind: string;
  group: string;
  templateId: string | null;
  templateVersion: number;
}

/** Field paths a metric moves: totals, per kind, per group, per template version. */
export function statFields(keys: StatKeys, metrics: NotificationStatMetric[]) {
  const out: Record<string, FieldValue> = {};
  const tpl = `${(keys.templateId ?? 'none').replace(/\./g, '~')}@${keys.templateVersion}`;
  for (const m of metrics) {
    out[`t.${m}`] = FieldValue.increment(1);
    out[`k.${keys.kind}.${m}`] = FieldValue.increment(1);
    out[`g.${keys.group}.${m}`] = FieldValue.increment(1);
    out[`v.${tpl}.${m}`] = FieldValue.increment(1);
  }
  return out;
}

export function countStats(
  tx: Transaction,
  db: Firestore,
  entryId: string,
  createdAt: Date,
  keys: StatKeys,
  metrics: NotificationStatMetric[],
  test = false,
) {
  // Portal test pushes (D-092) never reach the numbers.
  if (metrics.length === 0 || test) return;
  const ref = statsRef(db, entryId, createdAt);
  tx.set(
    ref,
    { day: localDateIn(STATS_ZONE, createdAt), ...nestStats(statFields(keys, metrics)) },
    { merge: true },
  );
}

/** `set(merge)` needs nested objects (dotted keys would be literal field names). */
function nestStats(flat: Record<string, FieldValue>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [path, value] of Object.entries(flat)) {
    const parts = path.split('.');
    let node = out;
    for (const p of parts.slice(0, -1)) {
      node[p] = (node[p] as Record<string, unknown> | undefined) ?? {};
      node = node[p] as Record<string, unknown>;
    }
    node[parts.at(-1)!] = value;
  }
  return out;
}

export function keysOf(entry: DocumentSnapshot): StatKeys {
  return {
    kind: String(entry.get('kind')),
    group: String(entry.get('group')),
    templateId: (entry.get('templateId') as string | null) ?? null,
    templateVersion: Number(entry.get('templateVersion') ?? 0),
  };
}

export function createdAtOf(entry: DocumentSnapshot): Date {
  const v = entry.get('createdAt');
  return v instanceof Timestamp ? v.toDate() : v instanceof Date ? v : new Date(0);
}

const deliveryMetric: Partial<Record<NotificationDeliveryState, NotificationStatMetric>> = {
  attempted: 'attempted',
  accepted: 'accepted',
  rejected: 'rejected',
  retry_pending: 'retry',
  failed: 'failed',
  unknown: 'unknown',
};

export interface Transition {
  lifecycle?: NotificationLifecycleState;
  delivery?: NotificationDeliveryState;
  deliveryReason?: NotificationDeliveryReason;
  read?: 'read';
  action?: NotificationActionState;
  /** Extra fields written with the transition (timestamps, counters, error code). */
  patch?: Record<string, unknown>;
  /** Extra metrics counted with it (e.g. opened / navigated). */
  metrics?: NotificationStatMetric[];
}

/**
 * Applies [t] to the live entry inside [tx] (the caller read it in the same transaction). Each
 * dimension moves only along the allowed edges; the call returns the dimensions that moved.
 */
export function applyTransition(
  tx: Transaction,
  db: Firestore,
  entry: DocumentSnapshot,
  t: Transition,
  now: Date,
): string[] {
  if (!entry.exists) return [];
  const moved: string[] = [];
  const update: Record<string, unknown> = {};
  const history: Record<string, unknown>[] = [];
  const metrics: NotificationStatMetric[] = [...(t.metrics ?? [])];
  const step = (
    dimension: 'lifecycle' | 'delivery' | 'read' | 'action',
    to: string | undefined,
  ) => {
    if (!to) return;
    const from = String(entry.get(dimension));
    if (!canTransition(dimension, from, to)) return;
    update[dimension] = to;
    moved.push(dimension);
    history.push({
      at: now,
      d: dimension,
      to,
      ...(dimension === 'delivery' && t.deliveryReason ? { r: t.deliveryReason } : {}),
    });
  };
  step('lifecycle', t.lifecycle);
  step('delivery', t.delivery);
  step('read', t.read);
  step('action', t.action);
  if (moved.includes('delivery')) {
    update.deliveryReason = t.deliveryReason ?? 'none';
    const m = deliveryMetric[t.delivery!];
    // A retried attempt counts once: the entry is attempted at most once in the stats.
    if (m && !(m === 'attempted' && Number(entry.get('attempts') ?? 0) > 0)) metrics.push(m);
    if (t.delivery === 'cancelled') metrics.push('cancelled');
  }
  if (moved.includes('read')) metrics.push('read');
  if (moved.includes('action') && t.action === 'completed') metrics.push('action_completed');
  if (moved.length === 0 && !t.patch && metrics.length === 0) return [];
  const prior = (entry.get('history') as unknown[] | undefined) ?? [];
  update.history = [...prior, ...history].slice(-HISTORY_MAX);
  Object.assign(update, t.patch ?? {});
  update.updatedAt = now;
  tx.update(entry.ref, update);
  countStats(
    tx,
    db,
    entry.id,
    createdAtOf(entry),
    keysOf(entry),
    metrics,
    entry.get('test') === true,
  );
  return moved;
}

/** Reads and transitions one entry in its own transaction. */
export async function transitionEntry(
  db: Firestore,
  id: string,
  t: Transition | ((entry: DocumentSnapshot) => Transition | null),
  now: Date,
): Promise<string[]> {
  return db.runTransaction(async (tx) => {
    const entry = await tx.get(ledgerRef(db, id));
    if (!entry.exists) return [];
    const resolved = typeof t === 'function' ? t(entry) : t;
    if (!resolved) return [];
    return applyTransition(tx, db, entry, resolved, now);
  });
}

/**
 * ENG stage → action dimension of the ledger entries the intent produced (push or inbox).
 * `opened` starts the action; completion is the engine's authoritative outcome, not a tap.
 */
export async function noteEngagementAction(
  db: Firestore,
  engagementId: string,
  stage: string,
  now: Date,
): Promise<void> {
  const action: NotificationActionState | null =
    stage === 'opened'
      ? 'started'
      : stage === 'completed'
        ? 'completed'
        : stage === 'expired'
          ? 'expired'
          : stage === 'cancelled' || stage === 'dismissed'
            ? 'unavailable'
            : null;
  if (!action) return;
  const rows = await db.collection(LEDGER).where('engagementId', '==', engagementId).limit(3).get();
  for (const row of rows.docs) {
    await transitionEntry(db, row.id, { action }, now).catch(() => undefined);
  }
}

/** Account or baby deletion: the ledger rows go (aggregate stats hold no identifiers). */
export async function purgeNotificationLedger(
  db: Firestore,
  field: 'uid' | 'babyId',
  value: string,
): Promise<number> {
  let removed = 0;
  for (let round = 0; round < 50; round += 1) {
    const rows = await db.collection(LEDGER).where(field, '==', value).limit(300).get();
    if (rows.empty) break;
    const batch = db.batch();
    for (const d of rows.docs) batch.delete(d.ref);
    await batch.commit();
    removed += rows.size;
    if (rows.size < 300) break;
  }
  return removed;
}

/** Daily: entries past retention (TTL on `deleteAfter` is prepared as a second mechanism). */
export async function sweepNotificationLedger(db: Firestore, now: Date): Promise<number> {
  let removed = 0;
  for (let round = 0; round < 10; round += 1) {
    const rows = await db
      .collection(LEDGER)
      .where('deleteAfter', '<=', Timestamp.fromDate(now))
      .limit(300)
      .get();
    if (rows.empty) break;
    const batch = db.batch();
    for (const d of rows.docs) batch.delete(d.ref);
    await batch.commit();
    removed += rows.size;
    if (rows.size < 300) break;
  }
  // Inbox rows past their own expiry: lifecycle → expired (bounded, best effort).
  return removed;
}
