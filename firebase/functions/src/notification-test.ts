import { randomUUID } from 'node:crypto';
import {
  NOTIFICATION_TEST_HOURLY_LIMIT,
  engagementPriority,
  localizedTemplateCopySchema,
  notificationDestinations,
  notificationSettingsOf,
  notificationTemplates,
  notificationTypes,
  renderTemplate,
  staffSendTestNotificationSchema,
  type EngagementKind,
  type LocalizedTemplateCopy,
  type NotificationDestinationId,
  type NotificationTestResult,
  type NotificationTestTargets,
  type PlaceholderValue,
  type StaffSendTestNotification,
} from '@child-life/contracts';
import type { Firestore } from 'firebase-admin/firestore';
import { engHash } from './engagement.js';
import { LEDGER, ledgerId } from './notification-ledger.js';
import { liveTemplate } from './notification-runtime.js';
import { familyContext } from './notification-staff.js';
import { inboxIdOf, notifyUsers } from './notifications.js';
import type { PushSender } from './social.js';
import { StaffError, familyCode, parse, requireStaff, staffAudit, type Staff } from './staff.js';

/**
 * Portal "Gửi thử" (owner D-092): one real push to a real device, to see a notification on the
 * lock screen and where a tap leads, without waiting for the real event. Guard rails:
 * - dev only (and the emulator): the project id decides, not a flag someone can flip;
 * - recipients: the staff member's own app account, or members of an internal (test) family;
 * - `notifications.edit`, at most 20 sends an hour per staff member, every send audited;
 * - delivered regardless of switches / quiet hours / kill switches, marked `test` in the ledger
 *   and never counted in stats; the inbox row is a normal row so the inbox path is tested too;
 * - ENG kinds: a test suggestion (`engagementIntents`, `test: true`, never dispatched, gone
 *   within an hour) so the tap opens the scenario's real screen.
 * Copy is the live (or built-in) template, or the unpublished draft, with the template's sample
 * values — never anything about the recipient's child.
 */

const ENG_OF_KIND: Partial<Record<string, EngagementKind>> = {
  photoSuggestion: 'ENG-01',
  keepsakePrompt: 'ENG-02',
  weeklySummary: 'ENG-03',
  familyActivity: 'ENG-05',
  rhythm: 'ENG-06',
};

export function testSendEnabled(): boolean {
  const project = process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT ?? '';
  return project === 'child-life-dev' || project.startsWith('demo-');
}

async function memberUids(db: Firestore, babyIds: string[]) {
  const out = new Map<string, string>();
  for (const b of babyIds) {
    const members = await db
      .collection(`babies/${b}/members`)
      .where('status', '==', 'active')
      .get();
    for (const m of members.docs) out.set(m.id, String(m.get('role')));
  }
  return out;
}

export async function notificationTestTargets(
  db: Firestore,
  staff: Staff | null,
  now: Date,
): Promise<NotificationTestTargets> {
  const s = requireStaff(staff, 'notifications.edit');
  const used = await usedThisHour(db, s.uid, now);
  if (!testSendEnabled()) return { enabled: false, families: [], usedThisHour: used };
  const familyIds = new Set<string>();
  // My own app account (same Firebase project): the families I am a member of.
  const mine = await db.collectionGroup('members').where('uid', '==', s.uid).limit(20).get();
  const myBabies = mine.docs
    .filter((m) => m.get('status') === 'active')
    .map((m) => m.ref.parent.parent!.id);
  for (const b of myBabies) {
    const baby = await db.doc(`babies/${b}`).get();
    const f = baby.get('familyId') as string | undefined;
    if (f) familyIds.add(f);
  }
  const internal = await db.collection('families').where('internal', '==', true).limit(20).get();
  for (const f of internal.docs) familyIds.add(f.id);

  const families: NotificationTestTargets['families'] = [];
  for (const id of familyIds) {
    const code = familyCode(id);
    let ctx;
    try {
      ctx = await familyContext(db, code);
    } catch {
      continue; // not in the family directory yet
    }
    const family = await db.doc(`families/${id}`).get();
    const isInternal = family.get('internal') === true;
    const active = await memberUids(db, ctx.babyIds);
    const members: NotificationTestTargets['families'][number]['members'] = [];
    for (const [uid, ref] of ctx.refOf) {
      if (!active.has(uid)) continue;
      // Only my own account in a non-internal family; anyone in an internal one.
      if (!isInternal && uid !== s.uid) continue;
      const devices = await db.collection(`users/${uid}/devices`).get();
      members.push({
        ref,
        role: active.get(uid)!,
        me: uid === s.uid,
        devices: devices.docs.filter((d) => d.get('token') && !d.get('signedOutAt')).length,
      });
    }
    if (members.length)
      families.push({
        code,
        mine: [...ctx.refOf.keys()].includes(s.uid),
        internal: isInternal,
        babies: ctx.babyIds.length,
        members,
      });
  }
  return { enabled: true, families, usedThisHour: used };
}

async function usedThisHour(db: Firestore, uid: string, now: Date): Promise<number> {
  const doc = await db.doc(`notificationTestQuota/${uid}`).get();
  return doc.get('bucket') === Math.floor(now.getTime() / 3600_000)
    ? Number(doc.get('count') ?? 0)
    : 0;
}

async function latestId(
  db: Firestore,
  path: string,
  pattern: RegExp,
  filter?: (d: FirebaseFirestore.QueryDocumentSnapshot) => boolean,
): Promise<string | null> {
  const rows = await db
    .collection(path)
    .orderBy('createdAt', 'desc')
    .limit(20)
    .get()
    .catch(() => null);
  const docs = rows?.docs ?? (await db.collection(path).limit(20).get()).docs;
  const hit = docs.find((d) => pattern.test(d.id) && (!filter || filter(d)));
  return hit?.id ?? null;
}

const ANY_ID = /^[A-Za-z0-9_-]{1,128}$/;

export async function sendTestNotification(
  db: Firestore,
  sender: PushSender | null,
  staff: Staff | null,
  data: unknown,
  now: Date,
): Promise<NotificationTestResult> {
  const s = requireStaff(staff, 'notifications.edit');
  if (!testSendEnabled()) throw new StaffError('failed-precondition', 'dev-only');
  const r = parse(staffSendTestNotificationSchema, data) as StaffSendTestNotification;
  const ctx = await familyContext(db, r.code);
  const family = await db.doc(`families/${ctx.familyId}`).get();
  const uid = [...ctx.refOf.entries()].find(([, ref]) => ref === r.recipient)?.[0];
  if (!uid) throw new StaffError('not-found', 'not-found');
  if (family.get('internal') !== true && uid !== s.uid)
    throw new StaffError('permission-denied', 'test-recipient');
  const babyId = ctx.babyIds[r.baby - 1];
  if (!babyId) throw new StaffError('not-found', 'not-found');
  const member = await db.doc(`babies/${babyId}/members/${uid}`).get();
  if (member.get('status') !== 'active')
    throw new StaffError('failed-precondition', 'not-a-member');

  // Rate limit, counted before any I/O to the device.
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`notificationTestQuota/${s.uid}`);
    const bucket = Math.floor(now.getTime() / 3600_000);
    const doc = await tx.get(ref);
    const count = doc.get('bucket') === bucket ? Number(doc.get('count') ?? 0) : 0;
    if (count >= NOTIFICATION_TEST_HOURLY_LIMIT)
      throw new StaffError('failed-precondition', 'rate-limited');
    tx.set(ref, { bucket, count: count + 1 });
  });

  // Copy: the draft, the live published version, or the built-in one.
  const def = notificationTemplates[r.templateId];
  let copy: LocalizedTemplateCopy = def.builtin;
  let templateVersion: number | 'draft' = 0;
  if (r.copy === 'draft') {
    const doc = await db.doc(`notificationTemplates/${r.templateId}`).get();
    const draft = localizedTemplateCopySchema.safeParse(doc.get('draft'));
    if (!draft.success) throw new StaffError('failed-precondition', 'no-draft');
    copy = draft.data;
    templateVersion = 'draft';
  } else {
    const live = await liveTemplate(db, r.templateId, now.getTime());
    if (live) {
      copy = live.copy;
      templateVersion = live.version;
    }
  }
  // Sample values, but the chosen baby's real name unless the recipient turned names off (D-094).
  const [babyDoc, recipientSettings] = await Promise.all([
    db.doc(`babies/${babyId}`).get(),
    db.doc(`users/${uid}/settings/notifications`).get(),
  ]);
  const values: Record<string, PlaceholderValue> = { ...def.sample };
  const nickname = babyDoc.get('nickname');
  // Never the sample "Bin": the real nickname, or "bé" when there is none or names are off.
  if (
    notificationSettingsOf(recipientSettings.data()).babyName !== false &&
    typeof nickname === 'string' &&
    nickname.trim()
  )
    values.baby_name = nickname.trim();
  else delete values.baby_name;
  const rendered = {
    vi: renderTemplate(copy, 'vi', values),
    en: renderTemplate(copy, 'en', values),
  };

  // Destination params from the baby's real data (or ids that do not exist, on purpose).
  const kind = def.kind;
  const type = notificationTypes[kind];
  const destination: NotificationDestinationId = type.destination;
  const missingVariant = r.variant === 'missing_target';
  const params: Record<string, string> = { babyId };
  const missing: string[] = [];
  const need = new Set(notificationDestinations[destination].params.map((p) => p.key));
  const fill = async (key: string, find: () => Promise<string | null>, fake: string) => {
    if (!need.has(key)) return;
    const value = missingVariant ? fake : await find();
    if (value) params[key] = value;
    else missing.push(key);
  };
  await fill(
    'ruleId',
    () => latestId(db, `babies/${babyId}/reminderRules`, ANY_ID),
    'missing-rule',
  );
  if (need.has('dueAt')) params.dueAt = String(now.getTime());
  if (need.has('date')) params.date = now.toISOString().slice(0, 10);
  await fill(
    'importId',
    () => latestId(db, `babies/${babyId}/spendingImports`, /^im_[a-f0-9]{32}$/),
    `im_${'0'.repeat(32)}`,
  );
  await fill(
    'albumId',
    () => latestId(db, `babies/${babyId}/albums`, ANY_ID, (d) => d.get('deleted') !== true),
    'missing-album',
  );
  await fill(
    'storyId',
    () => latestId(db, `babies/${babyId}/stories`, ANY_ID, (d) => d.get('status') === 'saved'),
    'missing-story',
  );
  await fill(
    'jobId',
    () => latestId(db, `babies/${babyId}/keepsakeJobs`, /^ksj_[a-f0-9]{32}$/),
    `ksj_${'0'.repeat(32)}`,
  );

  // ENG kinds: a short-lived test suggestion the tap re-authorises on the server.
  const engKind = ENG_OF_KIND[kind];
  let testSuggestion = false;
  if (engKind) {
    if (missingVariant) {
      params.engagementId = engHash(`missing:${randomUUID()}`);
    } else {
      const id = engHash(`test:${uid}:${babyId}:${engKind}:${now.getTime()}`);
      const baby = await db.doc(`babies/${babyId}`).get();
      const zone = String(baby.get('timeZone.zone') ?? 'Asia/Ho_Chi_Minh');
      await db.doc(`engagementIntents/${id}`).set({
        id,
        uid,
        babyId,
        familyId: ctx.familyId,
        kind: engKind,
        source: 'test',
        context: 'current',
        zone,
        eligibleAt: now.getTime(),
        dueAt: now.getTime(),
        expiresAt: now.getTime() + 3600_000,
        windowClosesAt: now.getTime() + 3600_000,
        priority: engagementPriority[engKind],
        status: 'in_app_only',
        reason: 'none',
        sourceData: {},
        sentAt: null,
        snoozedUntil: 0,
        dismissed: false,
        completedAt: null,
        test: true,
        // Never dispatched, never on the shelf, never measured.
        proactive: false,
        deleteAfter: new Date(now.getTime() + 2 * 3600_000),
      });
      params.engagementId = id;
      testSuggestion = true;
    }
  }

  // Platform options of the real push (lock-screen actions for reminders and vaccines).
  let platform: { apns?: { category?: string; collapseId?: string }; androidDraws?: boolean } = {};
  if (kind === 'reminderRule') {
    let ruleType = 'feed';
    if (params.ruleId && !missingVariant) {
      const rule = await db.doc(`babies/${babyId}/reminderRules/${params.ruleId}`).get();
      ruleType = String(rule.get('type') ?? 'feed');
    }
    params.type = ruleType;
    platform = { androidDraws: true, apns: { category: `CL_RULE_${ruleType.toUpperCase()}` } };
  } else if (kind === 'vaccine') {
    params.months = '2';
    platform = { androidDraws: true, apns: { category: 'CL_VACCINE' } };
  }
  if (params.albumId)
    Object.assign(params, { sourceCollection: 'albums', sourceId: params.albumId });
  if (params.storyId)
    Object.assign(params, { sourceCollection: 'stories', sourceId: params.storyId });

  const noticeId = `test-${s.uid.slice(0, 12)}-${now.getTime().toString(36)}`;
  const result = await notifyUsers(
    db,
    sender,
    [uid],
    {
      kind,
      id: noticeId,
      babyId,
      data: { ...params, test: '1' },
      destination,
      message: (language) => ({
        title: rendered[language].title,
        body: rendered[language].body,
        ...platform,
      }),
      test: {
        templateId: r.templateId,
        templateVersion: templateVersion === 'draft' ? -1 : templateVersion,
      },
      ...(engKind && params.engagementId
        ? { engagement: { id: params.engagementId, kind: engKind } }
        : {}),
      zone: 'Asia/Ho_Chi_Minh',
    },
    now,
  );
  const entry = ledgerId(uid, `${kind}:${noticeId}`);
  const ledger = await db.doc(`${LEDGER}/${entry}`).get();

  const batch = db.batch();
  staffAudit(
    batch,
    db,
    s,
    {
      action: 'notifications.test.send',
      category: 'notifications',
      target: r.code,
      reason: null,
      detail: {
        templateId: r.templateId,
        copy: r.copy,
        recipient: r.recipient,
        baby: r.baby,
        variant: r.variant,
      },
    },
    now,
  );
  await batch.commit();

  return {
    code: r.code,
    entry,
    inboxId: inboxIdOf(noticeId),
    kind,
    destination,
    params: Object.fromEntries(Object.entries(params).filter(([k]) => k !== 'test')),
    missing,
    templateVersion,
    devices: Number(ledger.get('devices') ?? 0),
    accepted: result.sent,
    testSuggestion,
  };
}
