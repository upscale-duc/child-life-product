import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { Timestamp, getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { inboxItemSchema } from '@child-life/contracts';
import { notifyUsers, sweepExpiredInbox } from '../functions/src/notifications.js';
import { deliverNotice, type PushSender } from '../functions/src/social.js';
import { ringVaccineReminders } from '../functions/src/vaccine-reminders.js';

// Notification centre (D-076 #2) against the Firestore emulator: every server push is recorded
// in the recipient's inbox, EN07 switches silence a kind (no push, no row), quiet hours hold a
// push back but keep the row, reminders the person set ring anyway, rows expire after 90 days.
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const babyId = 'b_nt0000000000000000001';
const people = ['nt-mom', 'nt-dad', 'nt-nanny'];
// Asia/Ho_Chi_Minh is UTC+7.
const vn = (d: string, h: number, m = 0) =>
  new Date(`${d}T${String(h - 7).padStart(2, '0')}:${String(m).padStart(2, '0')}:00Z`);

const sent: { tokens: string[]; title: string; data: Record<string, string> }[] = [];
let reject: string[] = [];
const sender: PushSender = {
  async send(tokens, message) {
    sent.push({ tokens, title: message.title, data: message.data });
    return tokens.filter((t) => reject.includes(t));
  },
};

const inbox = async (uid: string) =>
  (await db.collection(`users/${uid}/notifications`).get()).docs.map((d) => ({
    id: d.id,
    ...d.data(),
  })) as ({ id: string } & Record<string, unknown>)[];

const notice = (over: Partial<Parameters<typeof notifyUsers>[3]> = {}) => ({
  kind: 'memories' as const,
  id: `test-${babyId}`,
  babyId,
  data: { babyId },
  message: (language: 'vi' | 'en') =>
    language === 'vi'
      ? { title: 'Có 2 khoảnh khắc mới', body: 'Mai vừa chia sẻ với gia đình. Mở để xem.' }
      : { title: '2 new moments', body: 'Mai just shared with the family. Open to see.' },
  zone: 'Asia/Ho_Chi_Minh',
  ...over,
});

beforeAll(() => {
  app = initializeApp({ projectId }, `nt-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  // Leave nothing that rings in other files (the vaccine plan) on the shared emulator.
  await db.recursiveDelete(db.doc(`babies/${babyId}`)).catch(() => undefined);
  for (const uid of people) {
    await db.recursiveDelete(db.doc(`users/${uid}`)).catch(() => undefined);
  }
  await deleteApp(app);
});

beforeEach(async () => {
  sent.length = 0;
  reject = [];
  for (const uid of people) {
    await db.recursiveDelete(db.doc(`users/${uid}`)).catch(() => undefined);
    await db
      .doc(`users/${uid}/devices/d_${uid}`)
      .set({ token: `t-${uid}`, language: uid === 'nt-dad' ? 'en' : 'vi' });
  }
  await db.recursiveDelete(db.doc(`babies/${babyId}`)).catch(() => undefined);
});

describe('notifyUsers', () => {
  it('pushes in each device language and records the row with both languages', async () => {
    const at = vn('2026-10-15', 15);
    const r = await notifyUsers(db, sender, ['nt-mom', 'nt-dad'], notice(), at);
    expect(r).toEqual({ sent: 2, recorded: 2, held: 0 });
    expect(sent.find((s) => s.tokens[0] === 't-nt-dad')!.title).toBe('2 new moments');
    const [row] = await inbox('nt-mom');
    expect(row!.id).toMatch(/^n_test-b_nt0000000000000000001-[a-z0-9]+$/);
    // The push carries the row's id, so opening it marks the row read.
    expect(sent[0]!.data).toMatchObject({ kind: 'memories', babyId, inboxId: row!.id });
    const stored: Record<string, unknown> = { ...row };
    delete stored.id;
    const parsed = inboxItemSchema.parse({
      ...stored,
      createdAt: (row!.createdAt as Timestamp).toDate(),
      expireAt: (row!.expireAt as Timestamp).toDate(),
    } as unknown as Record<string, unknown>);
    expect(parsed).toMatchObject({
      category: 'family',
      route: 'memories',
      pushed: true,
      readAt: null,
      archivedAt: null,
      title: { vi: 'Có 2 khoảnh khắc mới', en: '2 new moments' },
    });
    expect(parsed.expireAt.getTime() - at.getTime()).toBe(90 * 86_400_000);
  });

  it('a switched-off kind is neither pushed nor kept; old G-056 keys still count', async () => {
    await db.doc('users/nt-mom/settings/notifications').set({ memories: false });
    // Spending follows the old "Nhắc việc" switch until "Chi tiêu" is set.
    await db.doc('users/nt-dad/settings/notifications').set({ reminders: false });
    const at = vn('2026-10-15', 15);
    await notifyUsers(db, sender, ['nt-mom', 'nt-dad'], notice(), at);
    expect(sent.map((s) => s.tokens[0])).toEqual(['t-nt-dad']);
    expect(await inbox('nt-mom')).toHaveLength(0);
    sent.length = 0;
    await notifyUsers(
      db,
      sender,
      ['nt-dad'],
      notice({ kind: 'spending', id: 'sp-budget', data: { babyId, reason: 'budget' } }),
      at,
    );
    expect(sent).toHaveLength(0);
    await db.doc('users/nt-dad/settings/notifications').set({ reminders: false, spending: true });
    await notifyUsers(
      db,
      sender,
      ['nt-dad'],
      notice({ kind: 'spending', id: 'sp-budget2', data: { babyId } }),
      at,
    );
    expect(sent).toHaveLength(1);
  });

  it('EN07 defaults: family activity and articles stay off until turned on', async () => {
    const at = vn('2026-10-15', 15);
    await notifyUsers(db, sender, ['nt-mom'], notice({ kind: 'familyActivity' }), at);
    await notifyUsers(db, sender, ['nt-mom'], notice({ kind: 'article' }), at);
    expect(sent).toHaveLength(0);
    await notifyUsers(db, sender, ['nt-mom'], notice({ kind: 'keepsakeVideo' }), at);
    expect(sent).toHaveLength(1);
  });

  it('quiet hours hold the push but keep the row; reminders the person set still ring', async () => {
    // Mom keeps EN02's default 22:00–06:00 (no document); Dad turned quiet hours off.
    await db.doc('users/nt-dad/settings/personalization').set({ quietHours: null });
    const night = vn('2026-10-15', 23, 10);
    const r = await notifyUsers(db, sender, ['nt-mom', 'nt-dad'], notice(), night);
    expect(r).toMatchObject({ recorded: 2, held: 1 });
    expect(sent.map((s) => s.tokens[0])).toEqual(['t-nt-dad']);
    const [held] = await inbox('nt-mom');
    expect(held!.pushed).toBe(false);
    sent.length = 0;
    await notifyUsers(
      db,
      sender,
      ['nt-mom'],
      notice({ kind: 'reminderRule', id: 'rr-1', data: { babyId, ruleId: 'r1' } }),
      night,
    );
    expect(sent.map((s) => s.tokens[0])).toEqual(['t-nt-mom']);
  });

  it('records without a push service (emulator) and drops rejected tokens', async () => {
    const at = vn('2026-10-15', 15);
    await notifyUsers(db, null, ['nt-mom'], notice(), at);
    expect((await inbox('nt-mom'))[0]!.pushed).toBe(false);
    reject = ['t-nt-dad'];
    await notifyUsers(db, sender, ['nt-dad'], notice(), at);
    const device = await db.doc('users/nt-dad/devices/d_nt-dad').get();
    expect(device.exists).toBe(true);
    expect(device.get('token')).toBeUndefined();
  });

  it('rows older than 90 days go: when a new one comes, and in the daily sweep', async () => {
    const old = vn('2026-06-01', 10);
    await notifyUsers(db, sender, ['nt-mom', 'nt-dad'], notice({ id: 'old' }), old);
    const later = vn('2026-10-15', 10);
    await notifyUsers(db, sender, ['nt-mom'], notice({ id: 'new' }), later);
    expect((await inbox('nt-mom')).map((r) => r.id)).toEqual([expect.stringMatching(/^n_new-/)]);
    // A family notice under babies/ has no expireAt and stays.
    await db.doc(`babies/${babyId}/notifications/keep`).set({ kind: 'memories' });
    expect(await sweepExpiredInbox(db, later)).toBeGreaterThanOrEqual(1);
    expect(await inbox('nt-dad')).toHaveLength(0);
    expect((await db.doc(`babies/${babyId}/notifications/keep`).get()).exists).toBe(true);
  });
});

describe('senders record the inbox', () => {
  it('a family notice (deliverNotice) lands in each recipient’s inbox, once', async () => {
    await db.doc(`babies/${babyId}`).set({ timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' } });
    await db.doc(`babies/${babyId}/notifications/memories_1`).set({
      kind: 'memories',
      babyId,
      count: 3,
      actor: { name: 'Mai' },
      recipients: ['nt-mom', 'nt-dad'],
      createdAt: new Date(),
      delivered: false,
    });
    const at = vn('2026-10-15', 15);
    expect((await deliverNotice(db, sender, babyId, 'memories_1', at)).sent).toBe(2);
    expect((await deliverNotice(db, sender, babyId, 'memories_1', at)).sent).toBe(0);
    const [row] = await inbox('nt-mom');
    expect(row).toMatchObject({
      kind: 'memories',
      title: { vi: 'Có 3 khoảnh khắc mới', en: '3 new moments' },
      data: { babyId, kind: 'memories', noticeId: 'memories_1', inboxId: row!.id },
    });
  });

  it('a vaccine reminder lands in the inbox with its route and EN07 "Tiêm chủng" silences it', async () => {
    await db.doc(`babies/${babyId}`).set({ timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' } });
    for (const [uid, role] of [
      ['nt-mom', 'coParent'],
      ['nt-dad', 'coParent'],
    ] as const) {
      await db.doc(`babies/${babyId}/members/${uid}`).set({ uid, babyId, role, status: 'active' });
    }
    for (const id of ['vitk', 'bcg', 'hepb']) {
      await db.doc(`babies/${babyId}/vaccines/${id}_1`).set({ status: 'given', plannedOn: null });
    }
    await db.doc(`babies/${babyId}/vaccinePlan/main`).set({
      dtp: null,
      setupDone: true,
      scheduleFrom: '2026-09-17',
      remind: true,
      recipients: [],
      bookPhotos: [],
    });
    await db.doc('users/nt-dad/settings/notifications').set({ vaccines: false });
    await ringVaccineReminders(db, sender, vn('2026-11-16', 19, 0));
    // Other files' babies may ring at the same time on this emulator: only ours count.
    expect(sent.map((s) => s.tokens[0]).filter((t) => t!.startsWith('t-nt-'))).toEqual([
      't-nt-mom',
    ]);
    const [row] = await inbox('nt-mom');
    expect(row).toMatchObject({
      kind: 'vaccine',
      category: 'reminders',
      route: 'vaccine',
      babyId,
      data: { kind: 'vaccine', babyId, date: '2026-11-17', months: '2' },
    });
    expect(await inbox('nt-dad')).toHaveLength(0);
  });
});
