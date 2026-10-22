import { randomUUID } from 'node:crypto';
import { deleteApp, initializeApp, type App } from 'firebase-admin/app';
import { Timestamp, getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import {
  inboxIdOf,
  notifyUsers,
  onInboxRowUpdated,
  recordNotificationOpen,
  retryNotificationDeliveries,
} from '../functions/src/notifications.js';
import {
  ledgerId,
  noteEngagementAction,
  purgeNotificationLedger,
} from '../functions/src/notification-ledger.js';
import {
  actOnNotificationTemplate,
  listNotificationTemplates,
  saveNotificationTemplate,
  setNotificationOps,
} from '../functions/src/notification-templates.js';
import { clearNotificationCaches } from '../functions/src/notification-runtime.js';
import {
  notificationDetail,
  notificationStats,
  notificationTimeline,
  retryNotification,
} from '../functions/src/notification-staff.js';
import { familyCode, type Staff } from '../functions/src/staff.js';
import type { PushSender } from '../functions/src/social.js';

// Unified notification platform (P-174) against the Firestore emulator: persist-first ledger,
// deterministic dedup, four independent states, bounded retries, Portal templates with immutable
// versions, family timeline with masked recipients and audit, stats counted exactly once.
const projectId = 'demo-child-life';
let app: App;
let db: Firestore;
const familyId = 'f_np0001';
const otherFamily = 'f_np0002';
const babyId = 'b_np0000000000000000001';
const otherBaby = 'b_np0000000000000000002';
const people = ['np-mom', 'np-dad', 'np-gran'];
const code = familyCode(familyId);
const day = '2026-10-20';
const at = new Date('2026-10-20T08:00:00Z'); // 15:00 in Vietnam, outside quiet hours

const owner: Staff = { uid: 's_owner', name: 'Owner', roles: ['owner'] };
const ops: Staff = { uid: 's_ops', name: 'Vận hành', roles: ['ops'] };
const expert: Staff = { uid: 's_expert', name: 'Chuyên gia', roles: ['expert'] };
const support: Staff = { uid: 's_support', name: 'Hỗ trợ', roles: ['support'] };
const eng: Staff = { uid: 's_eng', name: 'Kỹ sư', roles: ['eng'] };

const sent: { tokens: string[]; title: string; data: Record<string, string> }[] = [];
let failures = 0;
const sender: PushSender = {
  async send(tokens, message) {
    if (failures > 0) {
      failures -= 1;
      throw Object.assign(new Error('unavailable'), { code: 'messaging/internal-error' });
    }
    sent.push({ tokens, title: message.title, data: message.data });
    return [];
  },
};

const notice = (over: Partial<Parameters<typeof notifyUsers>[3]> = {}) => ({
  kind: 'memories' as const,
  id: `bn-${babyId}-batch1`,
  babyId,
  data: { babyId },
  message: (language: 'vi' | 'en') =>
    language === 'vi'
      ? { title: 'Có 2 khoảnh khắc mới', body: 'Mai vừa chia sẻ với gia đình. Mở để xem.' }
      : { title: '2 new moments', body: 'Mai just shared with the family. Open to see.' },
  template: { id: 'memories.new_moments' as const, values: { count: 2, actor_name: 'Mai' } },
  zone: 'Asia/Ho_Chi_Minh',
  ...over,
});

const entry = async (uid: string, n = notice()) =>
  db.doc(`notificationDeliveries/${ledgerId(uid, `${n.kind}:${n.id}`)}`).get();

const statTotals = async () => {
  const docs = await db.collection('notificationStats').where('day', '==', day).get();
  const out: Record<string, number> = {};
  for (const d of docs.docs)
    for (const [k, v] of Object.entries((d.get('t') as Record<string, number>) ?? {}))
      out[k] = (out[k] ?? 0) + v;
  return out;
};

async function wipe() {
  for (const name of [
    'notificationDeliveries',
    'notificationStats',
    'notificationTemplates',
    'staffAudit',
    'engagementIntents',
  ]) {
    await db.recursiveDelete(db.collection(name)).catch(() => undefined);
  }
  await db
    .doc('config/notifications')
    .delete()
    .catch(() => undefined);
  for (const uid of people) await db.recursiveDelete(db.doc(`users/${uid}`)).catch(() => undefined);
  for (const b of [babyId, otherBaby])
    await db.recursiveDelete(db.doc(`babies/${b}`)).catch(() => undefined);
}

beforeAll(() => {
  app = initializeApp({ projectId }, `np-${randomUUID()}`);
  db = getFirestore(app);
});

afterAll(async () => {
  await wipe();
  for (const f of [familyId, otherFamily]) {
    await db
      .doc(`families/${f}`)
      .delete()
      .catch(() => undefined);
    await db
      .doc(`familyDirectory/${f}`)
      .delete()
      .catch(() => undefined);
  }
  await deleteApp(app);
});

beforeEach(async () => {
  await wipe();
  clearNotificationCaches();
  sent.length = 0;
  failures = 0;
  await db.doc(`families/${familyId}`).set({ babyIds: [babyId] });
  await db.doc(`families/${otherFamily}`).set({ babyIds: [otherBaby] });
  await db.doc(`familyDirectory/${familyId}`).set({ code });
  await db.doc(`familyDirectory/${otherFamily}`).set({ code: familyCode(otherFamily) });
  await db.doc(`babies/${babyId}`).set({
    familyId,
    dob: '2026-08-01',
    timeZone: { zone: 'Asia/Ho_Chi_Minh' },
  });
  await db.doc(`babies/${otherBaby}`).set({ familyId: otherFamily });
  for (const [uid, role] of [
    ['np-mom', 'coParent'],
    ['np-dad', 'coParent'],
    ['np-gran', 'relative'],
  ] as const) {
    await db.doc(`babies/${babyId}/members/${uid}`).set({ role, status: 'active' });
    await db
      .doc(`users/${uid}/devices/d_${uid}`)
      .set({ token: `t-${uid}`, language: uid === 'np-dad' ? 'en' : 'vi' });
  }
});

describe('persist first, once', () => {
  it('a producer retry writes nothing twice; the four states start independent', async () => {
    const first = await notifyUsers(db, sender, ['np-mom', 'np-dad'], notice(), at);
    const again = await notifyUsers(db, sender, ['np-mom', 'np-dad'], notice(), at);
    expect(first).toEqual({ sent: 2, recorded: 2, held: 0, duplicate: 0 });
    expect(again).toEqual({ sent: 0, recorded: 0, held: 0, duplicate: 2 });
    expect(sent).toHaveLength(2);
    expect(sent[0]!.data).toMatchObject({
      inboxId: inboxIdOf(`bn-${babyId}-batch1`),
      destination: 'MEMORIES',
    });
    const e = await entry('np-mom');
    expect(e.data()).toMatchObject({
      familyId,
      babyId,
      kind: 'memories',
      group: 'memories',
      lifecycle: 'persisted',
      delivery: 'accepted',
      read: 'unread',
      action: 'none',
      templateId: 'memories.new_moments',
      templateVersion: 0,
      attempts: 1,
      acceptedTokens: 1,
    });
    // No copy, names or tokens in the ledger.
    expect(JSON.stringify(e.data())).not.toMatch(/Mai|t-np-mom|khoảnh khắc/);
    const row = await db
      .doc(`users/np-mom/notifications/${inboxIdOf(`bn-${babyId}-batch1`)}`)
      .get();
    expect(row.get('ledgerId')).toBe(e.id);
    expect(await statTotals()).toMatchObject({ created: 2, inbox: 2, attempted: 2, accepted: 2 });
  });

  it('a muted kind leaves a ledger fact without a row; quiet hours and the kill switch keep the row', async () => {
    await db.doc('users/np-mom/settings/notifications').set({ memories: false });
    await notifyUsers(db, sender, ['np-mom'], notice(), at);
    expect((await entry('np-mom')).data()).toMatchObject({
      inboxId: null,
      lifecycle: 'cancelled',
      delivery: 'cancelled',
      deliveryReason: 'setting_off',
    });
    expect((await db.collection('users/np-mom/notifications').get()).size).toBe(0);

    await setNotificationOps(
      db,
      eng,
      { config: { pushPaused: { memories: true, family: false, care: false, other: false } } },
      at,
    );
    await notifyUsers(db, sender, ['np-dad'], notice(), at);
    expect(sent).toHaveLength(0);
    expect((await entry('np-dad')).data()).toMatchObject({
      lifecycle: 'persisted',
      delivery: 'cancelled',
      deliveryReason: 'kill_switch',
    });
    // Care is its own group: a Memories kill switch never silences a reminder the person set.
    await notifyUsers(
      db,
      sender,
      ['np-dad'],
      notice({
        kind: 'reminderRule',
        id: 'rr-r1-1',
        data: { babyId, ruleId: 'r1' },
        template: undefined,
      }),
      at,
    );
    expect(sent).toHaveLength(1);
    const audit = await db.collection('staffAudit').where('category', '==', 'notifications').get();
    expect(audit.docs.map((d) => d.get('action'))).toContain('notifications.ops.set');
    expect(await statTotals()).toMatchObject({ muted: 1, cancelled: 1 });
  });
});

describe('retries', () => {
  it('a transient provider error retries with backoff and counts the attempt once', async () => {
    failures = 1;
    const r = await notifyUsers(db, sender, ['np-mom'], notice(), at);
    expect(r.recorded).toBe(1);
    let e = await entry('np-mom');
    expect(e.data()).toMatchObject({ delivery: 'retry_pending', deliveryReason: 'provider_error' });
    expect((e.get('nextAttemptAt') as Timestamp).toMillis()).toBe(at.getTime() + 60_000);
    // Not due yet.
    expect((await retryNotificationDeliveries(db, sender, at)).retried).toBe(0);
    const later = new Date(at.getTime() + 2 * 60_000);
    expect(await retryNotificationDeliveries(db, sender, later)).toMatchObject({
      retried: 1,
      accepted: 1,
    });
    e = await entry('np-mom');
    expect(e.data()).toMatchObject({ delivery: 'accepted', attempts: 2 });
    expect(sent).toHaveLength(1);
    // A second sweep (or a stale worker) cannot send it again.
    expect((await retryNotificationDeliveries(db, sender, later)).retried).toBe(0);
    expect(await statTotals()).toMatchObject({ attempted: 1, retry: 1, accepted: 1 });
  });

  it('exhausted retries fail; ops staff may requeue once; ENG sends are never retried', async () => {
    failures = 10;
    await notifyUsers(db, sender, ['np-mom'], notice(), at);
    let t = at.getTime();
    for (let i = 0; i < 4; i++) {
      t += 31 * 60_000;
      await retryNotificationDeliveries(db, sender, new Date(t));
    }
    const failed = await entry('np-mom');
    expect(failed.data()).toMatchObject({ delivery: 'failed', deliveryReason: 'retry_exhausted' });
    await expect(retryNotification(db, ops, { entry: failed.id }, at)).rejects.toMatchObject({
      reason: 'role',
    });
    failures = 0;
    await retryNotification(db, eng, { entry: failed.id }, new Date(t));
    await retryNotificationDeliveries(db, sender, new Date(t + 1));
    expect((await entry('np-mom')).get('delivery')).toBe('accepted');

    failures = 1;
    const eng1 = notice({
      kind: 'weeklySummary',
      id: 'eng-abc',
      retry: false,
      engagement: { id: 'a'.repeat(64), kind: 'ENG-03' },
      template: { id: 'eng.weekly_recap', values: {} },
    });
    await expect(notifyUsers(db, sender, ['np-dad'], eng1, at)).rejects.toThrow('unavailable');
    const unknown = await entry('np-dad', eng1);
    expect(unknown.data()).toMatchObject({
      delivery: 'unknown',
      deliveryReason: 'ambiguous',
      action: 'not_started',
      engagementId: 'a'.repeat(64),
    });
    await retryNotificationDeliveries(db, sender, new Date(at.getTime() + 3_600_000));
    expect((await entry('np-dad', eng1)).get('delivery')).toBe('unknown');
    // The engine's completion, not the tap, completes the action.
    await noteEngagementAction(db, 'a'.repeat(64), 'opened', at);
    await noteEngagementAction(db, 'a'.repeat(64), 'completed', at);
    expect((await entry('np-dad', eng1)).get('action')).toBe('completed');
  });
});

describe('read, open and action stay independent', () => {
  it('read on any device syncs once; an open records surface and navigation, never completion', async () => {
    await notifyUsers(db, sender, ['np-mom'], notice(), at);
    const rowRef = db.doc(`users/np-mom/notifications/${inboxIdOf(`bn-${babyId}-batch1`)}`);
    const before = await rowRef.get();
    await rowRef.update({ readAt: Timestamp.fromDate(at) });
    const after = await rowRef.get();
    await onInboxRowUpdated(db, before, after, at);
    await onInboxRowUpdated(db, before, after, at);
    expect((await entry('np-mom')).get('read')).toBe('read');

    // Someone else's inbox id is not theirs to open.
    expect(
      await recordNotificationOpen(
        db,
        'np-dad',
        { inboxId: before.id, surface: 'push', outcome: 'navigated' },
        at,
      ),
    ).toEqual({ ok: false });
    await recordNotificationOpen(
      db,
      'np-mom',
      { inboxId: before.id, surface: 'push', outcome: 'fallback' },
      at,
    );
    await recordNotificationOpen(
      db,
      'np-mom',
      { inboxId: before.id, surface: 'inbox', outcome: 'navigated' },
      at,
    );
    const e = await entry('np-mom');
    expect(e.data()).toMatchObject({
      read: 'read',
      openSurface: 'push',
      navigation: 'fallback',
      action: 'none',
      delivery: 'accepted',
    });
    expect(await statTotals()).toMatchObject({ read: 1, opened: 1, opened_push: 1, fallback: 1 });
    expect((await statTotals()).opened_inbox).toBeUndefined();
  });
});

describe('templates', () => {
  it('draft → review → publish is used at send time; pause and rollback fall back to code', async () => {
    const copy = {
      vi: { title: '{{count}} khoảnh khắc mới', body: '{{actor_name}} đã chia sẻ. Xem ngay.' },
      en: {
        title: '{{plural:count|A new moment|{{count}} new moments}}',
        body: '{{actor_name}} shared. Take a look.',
      },
    };
    await expect(
      saveNotificationTemplate(db, support, { templateId: 'memories.new_moments', copy }, at),
    ).rejects.toMatchObject({ reason: 'role' });
    await expect(
      saveNotificationTemplate(
        db,
        expert,
        {
          templateId: 'memories.new_moments',
          copy: { ...copy, vi: { title: '{{baby_name}} có ảnh mới', body: 'Xem https://x.y' } },
        },
        at,
      ),
    ).rejects.toMatchObject({ reason: 'template-invalid' });
    await saveNotificationTemplate(db, ops, { templateId: 'memories.new_moments', copy }, at);
    await expect(
      actOnNotificationTemplate(
        db,
        expert,
        { templateId: 'memories.new_moments', action: 'publish' },
        at,
      ),
    ).rejects.toMatchObject({ reason: 'stale' });
    await actOnNotificationTemplate(
      db,
      ops,
      { templateId: 'memories.new_moments', action: 'submit' },
      at,
    );
    await expect(
      actOnNotificationTemplate(
        db,
        ops,
        { templateId: 'memories.new_moments', action: 'publish' },
        at,
      ),
    ).rejects.toMatchObject({ reason: 'role' });
    const published = await actOnNotificationTemplate(
      db,
      expert,
      { templateId: 'memories.new_moments', action: 'publish', note: 'shorter' },
      at,
    );
    expect(published).toMatchObject({ status: 'published', liveVersion: 1, draftState: 'none' });

    await notifyUsers(db, sender, ['np-dad', 'np-mom'], notice(), at);
    expect(sent.map((s) => s.title).sort()).toEqual(['2 khoảnh khắc mới', '2 new moments']);
    expect((await entry('np-mom')).get('templateVersion')).toBe(1);

    await actOnNotificationTemplate(
      db,
      owner,
      { templateId: 'memories.new_moments', action: 'pause' },
      at,
    );
    sent.length = 0;
    await notifyUsers(db, sender, ['np-mom'], notice({ id: 'bn-2' }), at);
    expect(sent[0]!.title).toBe('Có 2 khoảnh khắc mới');

    await actOnNotificationTemplate(
      db,
      owner,
      { templateId: 'memories.new_moments', action: 'resume' },
      at,
    );
    await actOnNotificationTemplate(
      db,
      owner,
      { templateId: 'memories.new_moments', action: 'rollback', version: 0 },
      at,
    );
    sent.length = 0;
    await notifyUsers(db, sender, ['np-mom'], notice({ id: 'bn-3' }), at);
    expect(sent[0]!.title).toBe('Có 2 khoảnh khắc mới');
    // Version 1 is still there, immutable, and can be pointed at again.
    expect(
      (await db.doc('notificationTemplates/memories.new_moments/versions/1').get()).get('copy'),
    ).toEqual(copy);
    await actOnNotificationTemplate(
      db,
      owner,
      { templateId: 'memories.new_moments', action: 'rollback', version: 1 },
      at,
    );
    const list = await listNotificationTemplates(db, expert, at);
    expect(list.templates.find((t) => t.id === 'memories.new_moments')).toMatchObject({
      status: 'published',
      liveVersion: 1,
      latestVersion: 1,
    });
    const actions = (
      await db.collection('staffAudit').where('category', '==', 'notifications').get()
    ).docs
      .map((d) => d.get('action'))
      .sort();
    expect(actions).toEqual(
      [
        'notifications.template.pause',
        'notifications.template.publish',
        'notifications.template.resume',
        'notifications.template.rollback',
        'notifications.template.rollback',
        'notifications.template.save',
        'notifications.template.submit',
      ].sort(),
    );
  });

  it('a published copy whose value is missing falls back to version 0 and is counted', async () => {
    const copy = {
      vi: { title: 'Nhập xong', body: '{{import_summary}}' },
      en: { title: 'Import done', body: '{{import_summary}}' },
    };
    await saveNotificationTemplate(db, owner, { templateId: 'spending.import_done', copy }, at);
    await actOnNotificationTemplate(
      db,
      owner,
      { templateId: 'spending.import_done', action: 'submit' },
      at,
    );
    await actOnNotificationTemplate(
      db,
      owner,
      { templateId: 'spending.import_done', action: 'publish' },
      at,
    );
    await notifyUsers(
      db,
      sender,
      ['np-mom'],
      {
        kind: 'spending',
        id: 'sp-im-x-done',
        babyId,
        data: { babyId },
        message: (l) => ({ title: l === 'vi' ? 'Đã nhập xong chi tiêu' : 'Done', body: 'x' }),
        template: { id: 'spending.import_done', values: {} },
      },
      at,
    );
    expect(sent[0]!.title).toBe('Đã nhập xong chi tiêu');
    expect(await statTotals()).toMatchObject({ render_error: 1 });
  });
});

describe('family timeline and stats', () => {
  it('shows metadata with masked recipients, audits each view and never crosses families', async () => {
    await notifyUsers(db, sender, ['np-mom', 'np-dad'], notice(), at);
    await db.doc(`engagementIntents/${'b'.repeat(64)}`).set({
      uid: 'np-dad',
      babyId,
      familyId,
      kind: 'ENG-02',
      source: 'campaign:m6',
      status: 'in_app_only',
      reason: 'channel_unavailable',
      eligibleAt: at.getTime() - 3_600_000,
      expiresAt: at.getTime() + 5 * 86_400_000,
      proactive: true,
    });
    await db.doc(`babies/${babyId}/reminderRules/r1`).set({
      enabled: true,
      nextDueAt: Timestamp.fromMillis(at.getTime() + 3_600_000),
    });
    await expect(
      notificationTimeline(db, support, { code, from: day, to: day }, at),
    ).rejects.toMatchObject({ reason: 'role' });
    const t = await notificationTimeline(db, ops, { code, from: day, to: day }, at);
    expect(t.summary).toMatchObject({ notifications: 2, engagements: 1, suppressed: 1 });
    expect(t.recipients.map((r) => r.ref)).toEqual(['m1', 'm2', 'm3']);
    expect(JSON.stringify(t)).not.toMatch(/np-mom|np-dad|np-gran|b_np|Mai|2026-08-01/);
    const intent = t.entries.find((e) => e.entry.startsWith('e_'))!;
    expect(intent).toMatchObject({
      scenario: 'ENG-02',
      channel: 'in_app',
      engagementStatus: 'in_app_only',
    });
    const upcoming = t.upcoming.map((u) => `${u.scenario}:${u.certainty}:${u.state}`);
    expect(upcoming).toContain('ENG-04:confirmed:scheduled');
    expect(upcoming).toContain('ENG-02:predicted:suppressed');
    const engOnly = await notificationTimeline(
      db,
      ops,
      { code, from: day, to: day, view: 'engagement' },
      at,
    );
    expect(engOnly.entries.every((e) => e.scenario)).toBe(true);

    const detail = await notificationDetail(db, ops, { code, entry: intent.entry }, at);
    const checks = Object.fromEntries(detail.checks.map((c) => [c.rule, c.result]));
    expect(checks).toMatchObject({
      feature_enabled: 'pass',
      not_fatigued: 'pass',
      consent_and_category: 'fail',
      within_caps: 'unknown',
    });
    // The other family's code never opens this family's rows.
    await expect(
      notificationDetail(
        db,
        owner,
        { code: familyCode(otherFamily), entry: t.entries[0]!.entry },
        at,
      ),
    ).rejects.toMatchObject({ reason: 'not-found' });
    const audit = await db
      .collection('staffAudit')
      .where('action', '>=', 'notifications.timeline')
      .get();
    expect(audit.size).toBe(3);
  });

  it('stats aggregate the daily shards and list problems with the family code', async () => {
    failures = 10;
    await notifyUsers(db, sender, ['np-mom'], notice(), at);
    failures = 0;
    await notifyUsers(db, sender, ['np-dad'], notice({ id: 'bn-ok' }), at);
    await expect(notificationStats(db, expert, { from: day, to: day }, at)).rejects.toMatchObject({
      reason: 'role',
    });
    const s = await notificationStats(db, eng, { from: day, to: day }, at);
    expect(s.days).toEqual([
      { day, totals: expect.objectContaining({ created: 2, accepted: 1, retry: 1 }) },
    ]);
    expect(s.byKind[0]).toMatchObject({ kind: 'memories' });
    expect(s.byTemplate[0]).toMatchObject({ templateId: 'memories.new_moments', version: 0 });
    expect(s.problems).toEqual([
      expect.objectContaining({ delivery: 'retry_pending', familyCode: code, kind: 'memories' }),
    ]);
    expect(s.sourceStartDay).toBe(day);
  });

  it('deleting an account removes its ledger rows', async () => {
    await notifyUsers(db, sender, ['np-mom', 'np-dad'], notice(), at);
    expect(await purgeNotificationLedger(db, 'uid', 'np-mom')).toBe(1);
    expect((await entry('np-mom')).exists).toBe(false);
    expect((await entry('np-dad')).exists).toBe(true);
  });
});
