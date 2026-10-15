import { Timestamp, type Firestore, type Query } from 'firebase-admin/firestore';
import {
  attachmentRef,
  deleteAttachmentObject,
  storedAttachment,
  type AttachmentStore,
} from './assistant-attachments.js';
import { taskRef } from './assistant-common.js';
import { storedTask } from './assistant-store.js';
import { releaseQuota } from './quota.js';

/**
 * Child Life Assistant, slice A3: data lifecycle (brief p.19; docs/assistant/data.md
 * "Retention", security.md).
 *
 * - Account deletion (`account.ts` step `personal`): the person's own conversations, messages,
 *   tasks (drafts, events, cached readings), quotes, photos (Storage prefix `assistant/{uid}/`
 *   and their documents), execution rows and request ledger go. Open reservations are released
 *   first. Domain records they confirmed stay with the family like any record they wrote
 *   (marked "Người dùng đã xoá" by the `authored` step).
 * - Baby deletion (`account.ts` step `documents`): every member's assistant data scoped to that
 *   baby goes (tasks, conversations, quotes, photos and their objects, execution rows); the
 *   baby's domain records go with the baby anyway.
 * - Consent withdrawal: besides stopping open tasks (A2), every photo of the person not yet
 *   deleted is deleted now (Storage-confirmed, else `deletion_pending` and retried).
 * - TTL (daily `cleanupAssistant`): execution rows and request-ledger entries older than 30 days;
 *   cached photo readings left by an interrupted run; attachment documents whose task is gone
 *   once their object is confirmed deleted. Expired, unsaved drafts keep their state and
 *   payload as part of the owner's conversation (deleted with it, with the account or the baby);
 *   their photos are released by the attachment sweeper.
 *
 * Nothing here logs content: counts and ids only.
 */

/** Storage removal the deletion jobs already have (`PurgeStore.deletePrefix`). */
export interface PrefixRemover {
  deletePrefix(prefix: string): Promise<void>;
}

export const ledgerTtlDays = 30;
const DAY_MS = 86_400_000;

async function deleteAll(db: Firestore, q: Query): Promise<number> {
  let total = 0;
  for (;;) {
    const snap = await q.limit(300).get();
    if (snap.empty) return total;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    total += snap.size;
  }
}

/** Releases a task's open reservation once (the task is about to be purged). */
async function releaseOpen(db: Firestore, taskId: string, now: Date): Promise<void> {
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(taskRef(db, taskId));
    if (!snap.exists) return;
    const t = storedTask(snap);
    if (t.reservationId && t.usage === 'reserved') {
      await releaseQuota(tx, db, {
        familyId: t.familyId,
        reservationId: t.reservationId,
        holder: taskId,
        reason: 'purged',
        now,
      });
      tx.update(snap.ref, { usage: 'released', updatedAt: Timestamp.fromDate(now) });
    }
  });
}

async function purgeTasks(db: Firestore, q: Query, now: Date): Promise<string[]> {
  const ids: string[] = [];
  for (;;) {
    const snap = await q.limit(100).get();
    if (snap.empty) return ids;
    for (const d of snap.docs) {
      await releaseOpen(db, d.id, now);
      await db.recursiveDelete(d.ref);
      ids.push(d.id);
    }
  }
}

/** Account deletion: everything assistant-owned by [uid] (domain records stay). */
export async function purgeAssistantForUser(
  db: Firestore,
  store: PrefixRemover,
  uid: string,
  now: Date,
): Promise<{ tasks: number; conversations: number; attachments: number }> {
  const tasks = await purgeTasks(
    db,
    db.collection('assistantTasks').where('ownerUid', '==', uid),
    now,
  );
  let conversations = 0;
  for (;;) {
    const snap = await db
      .collection('assistantConversations')
      .where('ownerUid', '==', uid)
      .limit(100)
      .get();
    if (snap.empty) break;
    for (const d of snap.docs) await db.recursiveDelete(d.ref);
    conversations += snap.size;
  }
  await deleteAll(db, db.collection('assistantQuotes').where('ownerUid', '==', uid));
  // Objects first: a failure leaves the documents, and the job step is retried (P-110).
  await store.deletePrefix(`assistant/${uid}/`);
  const attachments = await deleteAll(
    db,
    db.collection('assistantAttachments').where('ownerUid', '==', uid),
  );
  await deleteAll(db, db.collection('assistantExecutions').where('ownerUid', '==', uid));
  await deleteAll(db, db.collection('assistantRequests').where('uid', '==', uid));
  return { tasks: tasks.length, conversations, attachments };
}

/** Baby deletion: every member's assistant data scoped to [babyId]. */
export async function purgeAssistantForBaby(
  db: Firestore,
  store: PrefixRemover,
  babyId: string,
  now: Date,
): Promise<{ tasks: number; attachments: number }> {
  const tasks = await purgeTasks(
    db,
    db.collection('assistantTasks').where('scope.babyId', '==', babyId),
    now,
  );
  for (const id of tasks) {
    await deleteAll(db, db.collection('assistantExecutions').where('taskId', '==', id));
  }
  for (;;) {
    const snap = await db
      .collection('assistantConversations')
      .where('scope.babyId', '==', babyId)
      .limit(100)
      .get();
    if (snap.empty) break;
    for (const d of snap.docs) await db.recursiveDelete(d.ref);
  }
  await deleteAll(db, db.collection('assistantQuotes').where('scope.babyId', '==', babyId));
  let attachments = 0;
  for (;;) {
    const snap = await db
      .collection('assistantAttachments')
      .where('scope.babyId', '==', babyId)
      .limit(100)
      .get();
    if (snap.empty) break;
    for (const d of snap.docs) {
      await store.deletePrefix(storedAttachment(d).storagePath);
      await d.ref.delete();
      attachments += 1;
    }
  }
  return { tasks: tasks.length, attachments };
}

/**
 * Consent withdrawn (P-160): every photo of [uid] not yet deleted goes now — uploaded, waiting,
 * kept for an unsaved expense. Storage-confirmed or `deletion_pending` (retried), never faked.
 */
export async function revokeAssistantPhotos(
  db: Firestore,
  files: AttachmentStore | undefined,
  uid: string,
  now: Date,
): Promise<{ deleted: number; pending: number }> {
  let deleted = 0;
  let pending = 0;
  if (!files) return { deleted, pending };
  const snap = await db.collection('assistantAttachments').where('ownerUid', '==', uid).get();
  for (const d of snap.docs) {
    if (d.get('state') === 'deleted') continue;
    const r = await deleteAttachmentObject(db, files, d.id, now);
    if (r === 'deleted') deleted += 1;
    else if (r === 'deletion_pending') pending += 1;
  }
  return { deleted, pending };
}

/**
 * A deleted conversation's tasks: their photos are deleted now (Storage-confirmed); confirmed
 * ones lose their document, a pending one keeps it (marked `orphan`) until the sweeper confirms.
 */
export async function purgeTaskAttachments(
  db: Firestore,
  files: AttachmentStore | undefined,
  taskId: string,
  now: Date,
): Promise<void> {
  const snap = await db.collection('assistantAttachments').where('taskId', '==', taskId).get();
  for (const d of snap.docs) {
    const r = files ? await deleteAttachmentObject(db, files, d.id, now) : null;
    if (r === 'deleted') await d.ref.delete();
    else await attachmentRef(db, d.id).update({ orphan: true, updatedAt: Timestamp.fromDate(now) });
  }
}

/**
 * Daily TTL: ledgers older than 30 days, readings left by an interrupted run, and the documents
 * of orphaned photos once their object is confirmed gone. Bounded per run.
 */
export async function cleanupAssistant(
  db: Firestore,
  now: Date,
): Promise<{ executions: number; requests: number; readings: number; orphans: number }> {
  const before = Timestamp.fromMillis(now.getTime() - ledgerTtlDays * DAY_MS);
  const page = async (name: string) => {
    let n = 0;
    for (let i = 0; i < 10; i++) {
      const snap = await db.collection(name).where('createdAt', '<', before).limit(300).get();
      if (snap.empty) break;
      const batch = db.batch();
      snap.docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();
      n += snap.size;
    }
    return n;
  };
  const executions = await page('assistantExecutions');
  const requests = await page('assistantRequests');
  let readings = 0;
  const stale = await db
    .collectionGroup('imageReading')
    .where('savedAt', '<', Timestamp.fromMillis(now.getTime() - DAY_MS))
    .limit(300)
    .get();
  for (const d of stale.docs) {
    const task = d.ref.parent.parent;
    if (!task || task.parent.id !== 'assistantTasks') continue;
    const t = await task.get();
    if (t.exists && t.get('state') === 'awaiting_clarification') continue;
    await d.ref.delete();
    readings += 1;
  }
  let orphans = 0;
  const gone = await db
    .collection('assistantAttachments')
    .where('state', '==', 'deleted')
    .limit(300)
    .get();
  for (const d of gone.docs) {
    const taskId = d.get('taskId') as string | null;
    const orphan =
      d.get('orphan') === true || (taskId !== null && !(await taskRef(db, taskId).get()).exists);
    if (!orphan) continue;
    await d.ref.delete();
    orphans += 1;
  }
  return { executions, requests, readings, orphans };
}
