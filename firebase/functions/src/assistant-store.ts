import {
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import type {
  AssistantAuthor,
  AssistantError,
  AssistantEvent,
  AssistantMessage,
  AssistantPart,
  AssistantRouting,
  AssistantScope,
  AssistantTaskSnapshot,
  AssistantTaskView,
  Clarification,
  TaskEventType,
  TaskModality,
  TaskState,
} from '@child-life/contracts';
import { conversationRef, seqId, taskRef, toIso } from './assistant-common.js';
import { draftView } from './assistant-writers.js';
// Slice A3 (photos): the task's attachments and their real retention state.
import { attachmentViews } from './assistant-attachments.js';
// Slice A5 (care): the task's care thread (plan, CH17 follow-up).
import { careView } from './assistant-care.js';

/**
 * Assistant documents (docs/assistant/data.md): views for the app and the ordered, coalesced
 * events and messages. Counters (`eventSeq` on the task, `messageSeq` on the conversation) move
 * inside the transaction that writes the rows, so sequences never repeat (M11).
 */

/** Stored task fields the code reads (Firestore types loosened). */
export interface StoredTask {
  id: string;
  ownerUid: string;
  familyId: string;
  scope: AssistantScope;
  conversationId: string;
  requestId: string;
  inputKey: string;
  input: { text: string | null; attachmentIds: string[] };
  anchorInstant: Timestamp;
  timezone: string;
  locale: 'vi' | 'en';
  modality: TaskModality;
  quoteId: string | null;
  credits: number;
  plan: 'free' | 'premium';
  windowId: string | null;
  reservationId: string | null;
  usage: 'none' | 'reserved' | 'committed' | 'released';
  state: TaskState;
  version: number;
  round: number;
  clarifications: {
    id: string;
    field: string;
    round: number;
    answer: { choiceId: string | null; text: string | null } | null;
  }[];
  pendingClarification: Clarification | null;
  clarificationExpiresAt: Timestamp | null;
  lease: { holder: string; until: Timestamp } | null;
  attempt: number;
  errorCode: AssistantError | null;
  eventSeq: number;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  /** D-075 #2: absent on tasks from before D-075 (private). */
  visibility?: 'shared' | 'private';
  author?: AssistantAuthor | null;
  // ---- Lumi rework 2026-10-15 ----
  /** Private because of money although sent from the shared thread. */
  routing?: AssistantRouting | null;
  /** The conversation's last task when this one started (the sender's previous turn). */
  previousTaskId?: string | null;
}

export const storedTask = (snap: DocumentSnapshot) => snap.data() as StoredTask;

export function taskView(snap: DocumentSnapshot, now: Date | null = null): AssistantTaskView {
  const t = storedTask(snap);
  // Slice A5: present only on care tasks; the follow-up needs the server clock.
  const care = careView(t, now);
  return {
    id: snap.id,
    conversationId: t.conversationId,
    scope: t.scope,
    state: t.state,
    version: t.version,
    modality: t.modality,
    credits: t.credits,
    plan: t.plan,
    usage: t.usage,
    errorCode: t.errorCode ?? null,
    round: t.round,
    clarification: t.pendingClarification ?? null,
    clarificationExpiresAt: toIso(t.clarificationExpiresAt),
    anchorInstant: toIso(t.anchorInstant) ?? '',
    timezone: t.timezone,
    createdAt: toIso(t.createdAt) ?? '',
    updatedAt: toIso(t.updatedAt) ?? '',
    ...(care ? { care } : {}),
    // D-075 #2: shared thread or private, and who asked.
    visibility: t.visibility ?? 'private',
    author: t.author ?? null,
    // Rework 2026-10-15: kept private because of money (null otherwise).
    routing: t.routing ?? null,
  };
}

export function eventView(snap: DocumentSnapshot): AssistantEvent {
  const d = snap.data() ?? {};
  return {
    taskId: d.taskId as string,
    eventId: d.eventId as string,
    sequence: d.sequence as number,
    type: d.type as TaskEventType,
    emittedAt: toIso(d.emittedAt) ?? '',
    payload: (d.payload as Record<string, unknown> | undefined) ?? {},
  };
}

export function messageView(snap: DocumentSnapshot): AssistantMessage {
  const d = snap.data() ?? {};
  return {
    id: snap.id,
    conversationId: d.conversationId as string,
    role: d.role as 'user' | 'assistant',
    parts: (d.parts as AssistantPart[] | undefined) ?? [],
    taskId: (d.taskId as string | null | undefined) ?? null,
    sequence: d.sequence as number,
    createdAt: toIso(d.createdAt) ?? '',
    attachmentIds: (d.attachmentIds as string[] | undefined) ?? [],
    author: (d.author as AssistantAuthor | null | undefined) ?? null,
  };
}

/** Writes [events] after [lastSeq] in [tx]; returns the new last sequence. */
export function appendEvents(
  tx: Transaction,
  db: Firestore,
  taskId: string,
  lastSeq: number,
  events: { type: TaskEventType; payload: Record<string, unknown> }[],
  now: Date,
): number {
  let seq = lastSeq;
  for (const e of events) {
    seq += 1;
    tx.set(taskRef(db, taskId).collection('events').doc(seqId(seq)), {
      taskId,
      eventId: `${taskId}:${seq}`,
      sequence: seq,
      type: e.type,
      emittedAt: Timestamp.fromDate(now),
      payload: e.payload,
    });
  }
  return seq;
}

/** Writes [messages] after [lastSeq] in conversation [conversationId]; returns the last sequence. */
export function appendMessages(
  tx: Transaction,
  db: Firestore,
  conversationId: string,
  lastSeq: number,
  messages: {
    role: 'user' | 'assistant';
    parts: AssistantPart[];
    taskId: string | null;
    /** Slice A3: the photos a user message carried. */
    attachmentIds?: string[];
    /** D-075 #2: who wrote it (sender / confirmer); null for the assistant's replies. */
    author?: AssistantAuthor | null;
  }[],
  now: Date,
): number {
  let seq = lastSeq;
  for (const m of messages) {
    seq += 1;
    tx.set(conversationRef(db, conversationId).collection('messages').doc(seqId(seq)), {
      conversationId,
      role: m.role,
      parts: m.parts,
      taskId: m.taskId,
      sequence: seq,
      createdAt: Timestamp.fromDate(now),
      attachmentIds: m.attachmentIds ?? [],
      author: m.author ?? null,
    });
  }
  return seq;
}

/** The authoritative snapshot (M11): task, drafts, events after [afterSequence], messages. */
export async function taskSnapshot(
  db: Firestore,
  taskId: string,
  now: Date,
  afterSequence = 0,
): Promise<AssistantTaskSnapshot> {
  const ref = taskRef(db, taskId);
  const task = await ref.get();
  const t = storedTask(task);
  const [drafts, events, messages] = await Promise.all([
    ref.collection('drafts').get(),
    ref.collection('events').where('sequence', '>', afterSequence).orderBy('sequence').get(),
    conversationRef(db, t.conversationId)
      .collection('messages')
      .where('taskId', '==', taskId)
      .get(),
  ]);
  // Slice A3: photo tasks expose each photo's state (deleted only once Storage confirmed it).
  const attachmentIds = t.input?.attachmentIds ?? [];
  return {
    task: taskView(task, now),
    drafts: drafts.docs.map((d) => draftView(d, now)).sort((a, b) => a.itemIndex - b.itemIndex),
    events: events.docs.map(eventView),
    messages: messages.docs.map(messageView).sort((a, b) => a.sequence - b.sequence),
    ...(attachmentIds.length > 0 ? { attachments: await attachmentViews(db, attachmentIds) } : {}),
  };
}
