import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { Timestamp, getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  answerReminderRule,
  fireDueRules,
  onRecordForRules,
  ruleCopy,
  saveReminderRule,
  setReminderRuleEnabled,
} from '../functions/src/reminder-rules.js';
import type { PushSender } from '../functions/src/social.js';

// Rule reminders (v1.0 370:1247, D-051) against the Firestore emulator: save, ring, snooze,
// skip and the first log resolving the reminder for everyone. Times are Hồ Chí Minh (UTC+7).
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const babyId = 'b_rr00000000000000000001';
const ruleId = `rr_${'c'.repeat(32)}`;
const vn = (hh: number, mm = 0) => new Date(Date.UTC(2026, 9, 8, hh - 7, mm));

const member = (uid: string, role: string, name: string, relation: string) => ({
  uid,
  babyId,
  role,
  status: 'active',
  displayName: name,
  relation,
  relationCustom: null,
});

let seq = 0;
async function log(type: string, at: Date, by = 'dad', ended: Date | null = null) {
  const id = `r_${(++seq).toString(16).padStart(32, '0')}`;
  const ref = db.doc(`babies/${babyId}/records/${id}`);
  await ref.set({
    id,
    babyId,
    type,
    occurredAt: Timestamp.fromDate(at),
    endedAt: ended ? Timestamp.fromDate(ended) : null,
    data: {},
    createdBy: by,
    author: {
      name: by === 'dad' ? 'Tuấn' : 'Mai',
      relation: by === 'dad' ? 'father' : 'mother',
      relationCustom: null,
    },
    deleted: false,
    deletedAt: null,
  });
  return ref.get();
}

const rule = async () => (await db.doc(`babies/${babyId}/reminderRules/${ruleId}`).get()).data()!;
const occurrences = async () =>
  (await db.collection(`babies/${babyId}/reminderRules/${ruleId}/occurrences`).get()).docs.map(
    (d) => d.data(),
  );

const sent: {
  tokens: string[];
  title: string;
  body: string;
  data: Record<string, string>;
  category?: string | undefined;
}[] = [];
const sender: PushSender = {
  async send(tokens, message) {
    sent.push({ tokens, ...message, category: message.apns?.category });
    return [];
  },
};

const feedRule = {
  babyId,
  ruleId,
  type: 'feed',
  mode: 'afterLast',
  intervalMinutes: 180,
  times: [],
  days: [1, 2, 3, 4, 5, 6, 7],
  quietNight: false,
  recipients: ['mom', 'dad', 'nanny'],
};

beforeAll(() => {
  app = initializeApp({ projectId }, `rules-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await deleteApp(app);
});

beforeEach(async () => {
  sent.length = 0;
  await db.recursiveDelete(db.doc(`babies/${babyId}`)).catch(() => undefined);
  await db.doc(`babies/${babyId}`).set({ timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' } });
  await db.doc(`babies/${babyId}/members/mom`).set(member('mom', 'coParent', 'Mai', 'mother'));
  await db.doc(`babies/${babyId}/members/dad`).set(member('dad', 'coParent', 'Tuấn', 'father'));
  await db.doc(`babies/${babyId}/members/nanny`).set(member('nanny', 'caregiver', 'Lan', 'nanny'));
  await db.doc(`babies/${babyId}/members/aunt`).set(member('aunt', 'relative', 'Hoa', 'relative'));
  for (const uid of ['mom', 'dad', 'nanny']) {
    await db
      .doc(`users/${uid}/devices/d_${uid}`)
      .set({ token: `t-${uid}`, language: uid === 'dad' ? 'en' : 'vi' });
  }
});

describe('saving (1b–1d)', () => {
  it('Cùng nuôi only; recipients are parents and caregivers', async () => {
    await expect(saveReminderRule(db, 'nanny', feedRule, vn(12))).rejects.toThrow('not-allowed');
    await expect(
      saveReminderRule(db, 'mom', { ...feedRule, recipients: ['mom', 'aunt'] }, vn(12)),
    ).rejects.toThrow('recipient-not-allowed');
    await expect(
      saveReminderRule(db, 'mom', { ...feedRule, intervalMinutes: null }, vn(12)),
    ).rejects.toThrow('malformed');
  });

  it('counts from the latest feed (bottle or breast): 11:45 + 3 h → 14:45', async () => {
    await log('bottle', vn(9));
    await log('breast', vn(11, 45));
    const { nextDueAt } = await saveReminderRule(db, 'mom', feedRule, vn(12));
    expect(nextDueAt).toBe(vn(14, 45).getTime());
    expect((await rule()).enabled).toBe(true);
  });
});

describe('ringing and answering (1f–1h)', () => {
  it('rings at 14:45 for every recipient, in their language, with the 1f actions', async () => {
    await log('bottle', vn(11, 45));
    await saveReminderRule(db, 'mom', feedRule, vn(12));
    expect((await fireDueRules(db, sender, vn(14, 44))).fired).toBe(0);
    const { fired } = await fireDueRules(db, sender, vn(14, 45));
    expect(fired).toBe(1);
    expect(sent.map((s) => s.tokens[0]).sort()).toEqual(['t-dad', 't-mom', 't-nanny']);
    const vi = sent.find((s) => s.tokens[0] === 't-mom')!;
    expect(vi.title).toBe('Đến giờ nhắc bú bạn đã đặt');
    expect(vi.body).toBe('Lần bú gần nhất 11:45 · 3 giờ trước');
    expect(vi.category).toBe('CL_RULE_FEED');
    expect(sent.find((s) => s.tokens[0] === 't-dad')!.title).toBe(
      'Time for the feeding reminder you set',
    );
    const r = await rule();
    expect(r.pendingDueAt.toDate()).toEqual(vn(14, 45));
    expect(r.nextDueAt).toBeNull();
    // It does not ring twice.
    expect((await fireDueRules(db, sender, vn(14, 46))).fired).toBe(0);
  });

  it('the first log resolves it for everyone; the next counts from that log (1h)', async () => {
    await log('bottle', vn(11, 45));
    await saveReminderRule(db, 'mom', feedRule, vn(12));
    await fireDueRules(db, sender, vn(14, 45));
    const snap = await log('bottle', vn(14, 52), 'dad');
    await onRecordForRules(db, babyId, null, snap, vn(14, 52));
    const r = await rule();
    expect(r.pendingDueAt).toBeNull();
    expect(r.nextDueAt.toDate()).toEqual(vn(17, 52));
    expect(r.lastOutcome.outcome).toBe('logged');
    expect(r.lastOutcome.author.name).toBe('Tuấn');
    expect(await occurrences()).toEqual([
      expect.objectContaining({ outcome: 'logged', by: 'dad', recordId: snap.id }),
    ]);
    // A late "Bỏ qua" from another phone changes nothing.
    const late = await answerReminderRule(
      db,
      'nanny',
      { babyId, ruleId, action: 'skip', dueAt: vn(14, 45).getTime() },
      vn(14, 53),
    );
    expect(late.status).toBe('handled');
  });

  it('"Báo lại sau 15 phút" rings again; "Bỏ qua lần này" waits another interval', async () => {
    await log('bottle', vn(11, 45));
    await saveReminderRule(db, 'mom', feedRule, vn(12));
    await fireDueRules(db, sender, vn(14, 45));
    const snooze = await answerReminderRule(
      db,
      'nanny',
      { babyId, ruleId, action: 'snooze', minutes: 15, dueAt: vn(14, 45).getTime() },
      vn(14, 46),
    );
    expect(snooze).toEqual({ status: 'done', nextDueAt: vn(15, 1).getTime() });
    expect((await fireDueRules(db, sender, vn(15, 1))).fired).toBe(1);
    const skip = await answerReminderRule(
      db,
      'mom',
      { babyId, ruleId, action: 'skip', dueAt: vn(15, 1).getTime() },
      vn(15, 2),
    );
    expect(skip.nextDueAt).toBe(vn(18, 1).getTime());
    expect((await occurrences()).map((o) => o.outcome).sort()).toEqual(['skipped', 'snoozed']);
  });

  it('a paused rule never rings; resuming counts from the latest log', async () => {
    await log('bottle', vn(11, 45));
    await saveReminderRule(db, 'mom', feedRule, vn(12));
    await setReminderRuleEnabled(db, 'mom', { babyId, ruleId, enabled: false }, vn(12));
    expect((await rule()).nextDueAt).toBeNull();
    expect((await fireDueRules(db, sender, vn(15))).fired).toBe(0);
    const { nextDueAt } = await setReminderRuleEnabled(
      db,
      'mom',
      { babyId, ruleId, enabled: true },
      vn(13),
    );
    expect(nextDueAt).toBe(vn(14, 45).getTime());
  });
});

describe('fixed times and sleep (1c2)', () => {
  it('rings at each time and moves on; an unanswered one is missed', async () => {
    await saveReminderRule(
      db,
      'mom',
      {
        ...feedRule,
        type: 'sleep',
        mode: 'fixed',
        intervalMinutes: null,
        times: ['13:00', '09:00'],
      },
      vn(8),
    );
    expect((await rule()).nextDueAt.toDate()).toEqual(vn(9));
    await fireDueRules(db, sender, vn(9));
    expect((await rule()).nextDueAt.toDate()).toEqual(vn(13));
    await fireDueRules(db, sender, vn(13));
    expect((await occurrences()).map((o) => o.outcome)).toEqual(['missed']);
  });

  it('the sleep copy says when the baby woke', () => {
    expect(ruleCopy('sleep', 'vi', 'Asia/Ho_Chi_Minh', vn(13, 5), vn(15, 5)).body).toBe(
      'Bé dậy lúc 13:05 · 2 giờ trước',
    );
  });
});
