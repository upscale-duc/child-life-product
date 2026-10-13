import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import type { AccountCaller } from '../functions/src/account.js';
import {
  myTickets,
  recordAppEvent,
  screenshotPath,
  sendFeedback,
} from '../functions/src/feedback.js';

// Góp ý & đánh giá (FB2 / FB3 / FB5, D-065) against the Firestore emulator.
const projectId = 'demo-child-life';
const now = new Date('2026-10-13T03:00:00Z');
let app: App;
let db: Firestore;
const uploaded = new Set<string>();
const deps = {
  staffInbox: 'team@example.com',
  screenshotExists: async (path: string) => uploaded.has(path),
};
const caller = (uid: string, over: Partial<AccountCaller> = {}): AccountCaller => ({
  uid,
  email: `${uid}@example.com`,
  anonymous: false,
  locale: 'vi',
  ...over,
});
const feedback = (over: Record<string, unknown> = {}) => ({
  requestId: randomUUID(),
  type: 'idea',
  message: 'Mong có thêm biểu đồ giấc ngủ theo tuần',
  screenshot: null,
  diagnostics: null,
  replyByEmail: true,
  locale: 'vi',
  ...over,
});
const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'ok',
    (e: { reason?: string }) => e.reason,
  );

beforeAll(() => {
  app = initializeApp({ projectId }, `feedback-${randomUUID()}`);
  db = getFirestore(app);
});
afterAll(async () => {
  await deleteApp(app);
});
beforeEach(async () => {
  uploaded.clear();
  for (const c of ['supportTickets', 'counters', 'mail', 'appEventsDaily']) {
    await db.recursiveDelete(db.collection(c));
  }
});

describe('FB2 "Gửi góp ý"', () => {
  it('is a numbered ticket of category feedback, acknowledged by email, counted by type', async () => {
    const req = feedback();
    const first = await sendFeedback(db, caller('mom'), req, now, deps);
    expect(first.ticket).toBe('CL-1001');
    expect(await sendFeedback(db, caller('mom'), req, now, deps)).toEqual(first);
    const t = (await db.collection('supportTickets').get()).docs[0]!.data();
    expect(t).toMatchObject({
      category: 'feedback',
      feedbackType: 'idea',
      email: 'mom@example.com',
      replyByEmail: true,
      screenshotPath: null,
      status: 'new',
    });
    const mail = (await db.collection('mail').get()).docs.map((d) => d.data());
    expect(mail.map((m) => m.to).sort()).toEqual(['mom@example.com', 'team@example.com']);
    expect(JSON.stringify(mail)).not.toContain('biểu đồ');
    expect((await db.doc('appEventsDaily/2026-10-13').get()).get('feedbackSent_idea')).toBe(1);
  });

  it('without "Cho phép liên hệ lại": no email kept or sent; a temporary identity may send', async () => {
    await sendFeedback(
      db,
      caller('anon', { anonymous: true, email: null }),
      feedback({ type: 'bug', replyByEmail: false }),
      now,
      deps,
    );
    const t = (await db.collection('supportTickets').get()).docs[0]!.data();
    expect(t.email).toBeNull();
    const mail = (await db.collection('mail').get()).docs.map((d) => d.data());
    expect(mail.map((m) => m.to)).toEqual(['team@example.com']);
    expect(
      await reason(
        sendFeedback(db, caller('anon', { anonymous: true, email: null }), feedback(), now, deps),
      ),
    ).toBe('email-required');
  });

  it('a screenshot must be uploaded first, under the sender and the request', async () => {
    const req = feedback({ type: 'bug', screenshot: 'png' });
    expect(await reason(sendFeedback(db, caller('mom'), req, now, deps))).toBe(
      'screenshot-missing',
    );
    uploaded.add(screenshotPath('mom', req.requestId, 'png'));
    await sendFeedback(db, caller('mom'), req, now, deps);
    const t = (await db.collection('supportTickets').get()).docs[0]!.data();
    expect(t.screenshotPath).toBe(`feedback/mom/${req.requestId}.png`);
    expect(await reason(sendFeedback(db, caller('mom'), { ...req, type: 'x' }, now, deps))).toBe(
      'malformed',
    );
  });
});

describe('FB3 history and FB5 counters', () => {
  it('lists only my own tickets, newest first', async () => {
    await sendFeedback(db, caller('mom'), feedback(), now, deps);
    await sendFeedback(
      db,
      caller('mom'),
      feedback({ type: 'other' }),
      new Date(now.getTime() + 60_000),
      deps,
    );
    await sendFeedback(db, caller('dad'), feedback(), now, deps);
    const mine = await myTickets(db, caller('mom'));
    expect(mine.map((t) => [t.ticket, t.feedbackType])).toEqual([
      ['CL-1002', 'other'],
      ['CL-1001', 'idea'],
    ]);
  });

  it('counts prompt events per day, nothing else', async () => {
    await recordAppEvent(db, { event: 'reviewPromptEligible' }, now);
    await recordAppEvent(db, { event: 'reviewPromptEligible' }, now);
    await recordAppEvent(db, { event: 'reviewPromptRequested' }, now);
    expect((await db.doc('appEventsDaily/2026-10-13').get()).data()).toEqual({
      day: '2026-10-13',
      reviewPromptEligible: 2,
      reviewPromptRequested: 1,
    });
    expect(await reason(recordAppEvent(db, { event: 'uid:mom' }, now))).toBe('malformed');
  });

  it('Tự lưu counters add several at once (P-148)', async () => {
    await recordAppEvent(db, { event: 'autoSaveApproved', n: 15 }, now);
    await recordAppEvent(db, { event: 'autoSaveApproved' }, now);
    expect((await db.doc('appEventsDaily/2026-10-13').get()).get('autoSaveApproved')).toBe(16);
    expect(await reason(recordAppEvent(db, { event: 'autoSaveApproved', n: 0 }, now))).toBe(
      'malformed',
    );
  });
});
