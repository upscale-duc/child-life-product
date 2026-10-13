import { createHash } from 'node:crypto';
import {
  recordAppEventSchema,
  sendFeedbackSchema,
  type FeedbackType,
  type MyTicket,
} from '@child-life/contracts';
import { FieldValue, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { AccountError, queueMail, type AccountCaller } from './account.js';
import { dayOf } from './analytics.js';

/**
 * Góp ý & đánh giá (FB1–FB5, D-065).
 *
 * - FB2 "Gửi góp ý" is a support ticket (`supportTickets`, category `feedback`) so the team
 *   answers it in the portal's Hỗ trợ like any other, and it is listed in the app's Trợ giúp &
 *   liên hệ (FB3). A "Vào ngay" identity may send one too, without "Cho phép liên hệ lại".
 * - The screenshot is uploaded by the app to `feedback/{uid}/{requestId}.{jpg|png}` first; only its
 *   path is kept. Message and screenshot are personal (P-124): never logged or counted.
 * - `appEventsDaily/{yyyy-mm-dd}` counts feedback by type and the FB5 prompt events, aggregate
 *   only (P-137); the portal can read it.
 */

const sha = (s: string) => createHash('sha256').update(s).digest('hex');

function parse<T>(
  schema: { safeParse(d: unknown): { success: boolean; data?: T } },
  data: unknown,
): T {
  const r = schema.safeParse(data);
  if (!r.success) throw new AccountError('invalid-argument', 'malformed');
  return r.data as T;
}

export interface FeedbackDeps {
  staffInbox: string;
  /** Whether the app's screenshot upload is there. */
  screenshotExists: (path: string) => Promise<boolean>;
}

export const screenshotPath = (uid: string, requestId: string, ext: 'jpg' | 'png') =>
  `feedback/${uid}/${requestId}.${ext}`;

const typeLabel: Record<FeedbackType, string> = {
  idea: 'Góp ý · Ý tưởng',
  bug: 'Góp ý · Báo lỗi',
  other: 'Góp ý · Khác',
};

export async function sendFeedback(
  db: Firestore,
  caller: AccountCaller,
  data: unknown,
  now: Date,
  deps: FeedbackDeps,
): Promise<{ ticket: string }> {
  const req = parse(sendFeedbackSchema, data);
  const email = req.replyByEmail ? caller.email : null;
  if (req.replyByEmail && (caller.anonymous || !caller.email)) {
    throw new AccountError('failed-precondition', 'email-required');
  }
  const path = req.screenshot ? screenshotPath(caller.uid, req.requestId, req.screenshot) : null;
  if (path && !(await deps.screenshotExists(path))) {
    throw new AccountError('failed-precondition', 'screenshot-missing');
  }
  const id = `t_${sha(`${caller.uid}:${req.requestId}`).slice(0, 20)}`;
  return db.runTransaction(async (tx) => {
    const ref = db.doc(`supportTickets/${id}`);
    const existing = await tx.get(ref);
    if (existing.exists) return { ticket: existing.get('ticket') as string };
    const counterRef = db.doc('counters/supportTickets');
    const counter = await tx.get(counterRef);
    const n = (counter.get('next') as number | undefined) ?? 1001;
    const ticket = `CL-${n}`;
    tx.set(counterRef, { next: n + 1 }, { merge: true });
    tx.create(ref, {
      ticket,
      category: 'feedback',
      feedbackType: req.type,
      message: req.message,
      diagnostics: req.diagnostics,
      screenshotPath: path,
      replyByEmail: req.replyByEmail,
      uid: caller.uid,
      // No email = the team cannot write back (replyTicket sends only with one).
      email,
      locale: req.locale,
      status: 'new',
      createdAt: now,
    });
    tx.set(
      db.doc(`appEventsDaily/${dayOf(now)}`),
      { day: dayOf(now), [`feedbackSent_${req.type}`]: FieldValue.increment(1) },
      { merge: true },
    );
    if (email) queueMail(tx, db, email, 'supportAck', req.locale, { ticket }, now);
    queueMail(
      tx,
      db,
      deps.staffInbox,
      'supportStaff',
      'vi',
      { ticket, category: typeLabel[req.type] },
      now,
    );
    return { ticket };
  });
}

/** FB3: the person's own tickets and feedback, newest first (the last 30). */
export async function myTickets(db: Firestore, caller: AccountCaller): Promise<MyTicket[]> {
  const snap = await db.collection('supportTickets').where('uid', '==', caller.uid).get();
  const at = (v: unknown) =>
    v instanceof Timestamp ? v.toDate() : v instanceof Date ? v : new Date(0);
  return snap.docs
    .map((d) => ({
      ticket: d.get('ticket') as string,
      category: d.get('category') as string,
      feedbackType: (d.get('feedbackType') as FeedbackType | undefined) ?? null,
      message: (d.get('message') as string).slice(0, 200),
      status: d.get('status') as string,
      at: at(d.get('createdAt')),
    }))
    .sort((a, b) => b.at.getTime() - a.at.getTime())
    .slice(0, 30)
    .map(({ at, ...t }) => ({ ...t, createdAt: at.toISOString() }));
}

/** FB5 "prompt_eligible" / "prompt_requested": a daily count, nothing about who. */
export async function recordAppEvent(db: Firestore, data: unknown, now: Date) {
  const req = parse(recordAppEventSchema, data);
  await db
    .doc(`appEventsDaily/${dayOf(now)}`)
    .set({ day: dayOf(now), [req.event]: FieldValue.increment(1) }, { merge: true });
  return { ok: true };
}
