import {
  campaignKinds,
  campaignWindow,
  inboxGroups,
  localDateIn,
  notificationKinds,
  notificationSettingKeys,
  notificationSettingsOf,
  notificationStatMetrics,
  notificationTemplateIds,
  notificationTypes,
  staffNotificationDetailSchema,
  staffNotificationStatsSchema,
  staffNotificationTimelineSchema,
  staffRetryNotificationSchema,
  type InboxGroup,
  type NotificationDeliveryReason,
  type NotificationDeliveryState,
  type NotificationDetailCheck,
  type NotificationEntryDetail,
  type NotificationKind,
  type NotificationStatCounts,
  type NotificationStatsResponse,
  type NotificationTemplateId,
  type NotificationTimelineResponse,
  type StaffNotificationTimelineRequest,
  type TimelineEntry,
  type TimelineRecipient,
  type TimelineUpcoming,
} from '@child-life/contracts';
import { Timestamp, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import { LEDGER, STATS, STATS_ZONE } from './notification-ledger.js';
import { notificationOps } from './notification-runtime.js';
import { staffRequeueDelivery } from './notifications.js';
import { StaffError, familyCode, parse, requireStaff, staffAudit, type Staff } from './staff.js';

/**
 * Notifications & Engagement operations for the Portal (P-174, docs/notifications/07-portal.md):
 * aggregate delivery stats from the daily ledger counters, and one family's timeline. The
 * timeline is restricted (`notifications.timeline` = families at "view") and every view writes
 * `staffAudit`. It returns metadata only: kinds, states, reasons, template versions, masked
 * recipient references ("m1"), never uids, emails, names, copy, captions or DOB. Upcoming
 * opportunities separate what the engine holds scheduled (`confirmed`) from what rules may allow
 * later (`predicted`).
 */

const DAY_MS = 86_400_000;
const PAGE = 50;
const SCAN = 300;

const ms = (v: unknown) =>
  v instanceof Timestamp
    ? v.toMillis()
    : v instanceof Date
      ? v.getTime()
      : typeof v === 'number'
        ? v
        : 0;
const iso = (v: unknown): string | null => {
  const t = ms(v);
  return t > 0 ? new Date(t).toISOString() : null;
};
const vnStart = (day: string) => new Date(`${day}T00:00:00+07:00`);

// ---------- Stats ----------

function add(into: NotificationStatCounts, counts: Record<string, unknown> | undefined) {
  for (const m of notificationStatMetrics) {
    const v = Number(counts?.[m] ?? 0);
    if (v) into[m] = (into[m] ?? 0) + v;
  }
}

export async function notificationStats(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
): Promise<NotificationStatsResponse> {
  requireStaff(staff, 'notifications.view');
  const range = parse(staffNotificationStatsSchema, data) as { from: string; to: string };
  const [docs, first, ops, problems] = await Promise.all([
    db.collection(STATS).where('day', '>=', range.from).where('day', '<=', range.to).get(),
    db.collection(STATS).orderBy('day', 'asc').limit(1).get(),
    notificationOps(db, now.getTime()),
    db
      .collection(LEDGER)
      .where('delivery', 'in', ['retry_pending', 'failed', 'unknown'])
      .where('createdAt', '>=', vnStart(range.from))
      .orderBy('createdAt', 'desc')
      .limit(50)
      .get(),
  ]);
  const days = new Map<string, NotificationStatCounts>();
  const byKind = new Map<string, NotificationStatCounts>();
  const byGroup = new Map<string, NotificationStatCounts>();
  const byTemplate = new Map<string, NotificationStatCounts>();
  for (const d of docs.docs) {
    const day = String(d.get('day'));
    const total = days.get(day) ?? {};
    add(total, d.get('t') as Record<string, unknown>);
    days.set(day, total);
    for (const [map, field] of [
      [byKind, 'k'],
      [byGroup, 'g'],
      [byTemplate, 'v'],
    ] as const) {
      for (const [key, counts] of Object.entries(
        (d.get(field) as Record<string, Record<string, unknown>> | undefined) ?? {},
      )) {
        const c = map.get(key) ?? {};
        add(c, counts);
        map.set(key, c);
      }
    }
  }
  const familyCodes = new Map<string, string>();
  return {
    range,
    reportingZone: 'Asia/Ho_Chi_Minh',
    computedAt: now.toISOString(),
    sourceStartDay: first.empty ? null : String(first.docs[0]!.get('day')),
    days: [...days.entries()]
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([day, totals]) => ({ day, totals })),
    byKind: [...byKind.entries()]
      .filter(([k]) => (notificationKinds as readonly string[]).includes(k))
      .map(([kind, counts]) => ({ kind: kind as NotificationKind, counts })),
    byGroup: [...byGroup.entries()]
      .filter(([g]) => (inboxGroups as readonly string[]).includes(g))
      .map(([group, counts]) => ({ group: group as InboxGroup, counts })),
    byTemplate: [...byTemplate.entries()].map(([key, counts]) => {
      const [id, v] = key.split('@');
      const templateId = id!.replace(/~/g, '.');
      return {
        templateId: (notificationTemplateIds as readonly string[]).includes(templateId)
          ? (templateId as NotificationTemplateId)
          : ('none' as const),
        version: Number(v ?? 0),
        counts,
      };
    }),
    problems: problems.docs
      .filter((p) => ms(p.get('createdAt')) <= vnStart(range.to).getTime() + DAY_MS)
      .map((p) => {
        const fid = p.get('familyId') as string | null;
        if (fid && !familyCodes.has(fid)) familyCodes.set(fid, familyCode(fid));
        return {
          entry: p.id,
          kind: p.get('kind') as NotificationKind,
          delivery: p.get('delivery') as NotificationDeliveryState,
          reason: (p.get('deliveryReason') ?? 'none') as NotificationDeliveryReason,
          attempts: Number(p.get('attempts') ?? 0),
          createdAt: iso(p.get('createdAt')) ?? '',
          errorCode: (p.get('errorCode') as string | null) ?? null,
          familyCode: fid ? familyCodes.get(fid)! : null,
        };
      }),
    ops,
  };
}

export async function retryNotification(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
): Promise<{ ok: boolean }> {
  const s = requireStaff(staff, 'notifications.ops');
  const { entry } = parse(staffRetryNotificationSchema, data) as { entry: string };
  const ok = await staffRequeueDelivery(db, entry, now);
  if (!ok) throw new StaffError('failed-precondition', 'not-retryable');
  const batch = db.batch();
  staffAudit(
    batch,
    db,
    s,
    {
      action: 'notifications.delivery.retry',
      category: 'notifications',
      target: entry,
      reason: null,
    },
    now,
  );
  await batch.commit();
  return { ok };
}

// ---------- Family timeline ----------

export interface FamilyContext {
  familyId: string;
  code: string;
  babyIds: string[];
  recipients: TimelineRecipient[];
  refOf: Map<string, string>;
}

const roleOrder = ['coParent', 'caregiver', 'relative'];

export async function familyContext(db: Firestore, code: string): Promise<FamilyContext> {
  const hit = await db.collection('familyDirectory').where('code', '==', code).limit(1).get();
  if (hit.empty) throw new StaffError('not-found', 'not-found');
  const familyId = hit.docs[0]!.id;
  const family = await db.doc(`families/${familyId}`).get();
  const babyIds = ((family.get('babyIds') as string[] | undefined) ?? []).slice(0, 10);
  const people = new Map<string, { role: string; since: number }>();
  for (const b of babyIds) {
    const members = await db.collection(`babies/${b}/members`).get();
    for (const m of members.docs) {
      const role = String(m.get('role'));
      const prev = people.get(m.id);
      // The strongest role across the babies names the person.
      if (!prev || roleOrder.indexOf(role) < roleOrder.indexOf(prev.role))
        people.set(m.id, { role, since: ms(m.get('joinedAt') ?? m.get('createdAt')) });
    }
  }
  const ordered = [...people.entries()].sort(
    (a, b) =>
      roleOrder.indexOf(a[1].role) - roleOrder.indexOf(b[1].role) ||
      a[1].since - b[1].since ||
      a[0].localeCompare(b[0]),
  );
  const refOf = new Map<string, string>();
  const recipients = ordered.map(([uid, p], i) => {
    const ref = `m${i + 1}`;
    refOf.set(uid, ref);
    return { ref, role: p.role, label: `${p.role} ${i + 1}` };
  });
  return { familyId, code, babyIds, recipients, refOf };
}

const engagementKindOfNotice: Partial<Record<NotificationKind, string>> = {
  photoSuggestion: 'ENG-01',
  keepsakePrompt: 'ENG-02',
  weeklySummary: 'ENG-03',
  familyActivity: 'ENG-05',
  rhythm: 'ENG-06',
};

function ledgerEntry(d: DocumentSnapshot, ctx: FamilyContext): TimelineEntry {
  const kind = d.get('kind') as NotificationKind;
  const delivery = d.get('delivery') as NotificationDeliveryState;
  const reason = d.get('deliveryReason') as string | null;
  return {
    entry: d.id,
    at: iso(d.get('createdAt')) ?? '',
    kind,
    scenario: (d.get('engagementKind') as string | null) ?? null,
    group: d.get('group') as InboxGroup,
    recipient: ctx.refOf.get(String(d.get('uid'))) ?? 'former',
    templateId: (d.get('templateId') as string | null) ?? null,
    templateVersion: Number(d.get('templateVersion') ?? 0),
    channel: d.get('inboxId')
      ? delivery === 'cancelled' && reason !== 'none'
        ? 'inbox'
        : 'push_inbox'
      : 'none',
    lifecycle: d.get('lifecycle'),
    delivery,
    read: d.get('read'),
    action: d.get('action'),
    engagementStatus: null,
    reason: reason && reason !== 'none' ? reason : null,
    destination: d.get('destination'),
    ...(d.get('test') === true ? { test: true } : {}),
  };
}

function intentEntry(d: DocumentSnapshot, ctx: FamilyContext): TimelineEntry {
  const status = String(d.get('status'));
  return {
    entry: `e_${d.id}`,
    at: iso(d.get('eligibleAt')) ?? '',
    kind: null,
    scenario: String(d.get('kind')),
    group: null,
    recipient: ctx.refOf.get(String(d.get('uid'))) ?? 'former',
    templateId: null,
    templateVersion: null,
    channel: 'in_app',
    lifecycle: null,
    delivery: null,
    read: null,
    action:
      status === 'completed' || d.get('completedAt')
        ? 'completed'
        : status === 'expired'
          ? 'expired'
          : status === 'cancelled'
            ? 'unavailable'
            : 'not_started',
    engagementStatus: status,
    reason: (d.get('reason') as string | null) ?? null,
    destination: null,
    ...(d.get('test') === true ? { test: true } : {}),
  };
}

function matches(e: TimelineEntry, r: StaffNotificationTimelineRequest): boolean {
  if (r.view === 'engagement' && !e.scenario) return false;
  if (r.group !== 'all' && e.group !== r.group) return false;
  if (r.kind !== 'all' && e.kind !== r.kind) return false;
  if (r.scenario !== 'all' && e.scenario !== r.scenario) return false;
  if (r.delivery !== 'all' && e.delivery !== r.delivery) return false;
  if (r.recipient && e.recipient !== r.recipient) return false;
  return true;
}

export async function notificationTimeline(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
): Promise<NotificationTimelineResponse> {
  const s = requireStaff(staff, 'notifications.timeline');
  const r = parse(staffNotificationTimelineSchema, data) as StaffNotificationTimelineRequest;
  const ctx = await familyContext(db, r.code);
  const from = vnStart(r.from);
  const to = new Date(vnStart(r.to).getTime() + DAY_MS);
  const cursorAt = r.cursor ? Number(r.cursor) : null;
  if (r.cursor && !Number.isFinite(cursorAt)) throw new StaffError('invalid-argument', 'malformed');
  const upper = cursorAt ? new Date(Math.min(cursorAt, to.getTime())) : to;

  const [ledger, intents] = await Promise.all([
    db
      .collection(LEDGER)
      .where('familyId', '==', ctx.familyId)
      .where('createdAt', '>=', from)
      .where('createdAt', '<', upper)
      .orderBy('createdAt', 'desc')
      .limit(SCAN)
      .get(),
    db.collection('engagementIntents').where('familyId', '==', ctx.familyId).limit(SCAN).get(),
  ]);
  const ledgerEngagement = new Set(
    ledger.docs.map((d) => d.get('engagementId') as string | null).filter(Boolean),
  );
  const intentRows = intents.docs.filter((d) => {
    const at = ms(d.get('eligibleAt'));
    return at >= from.getTime() && at < upper.getTime();
  });
  const all = [
    ...ledger.docs.map((d) => ledgerEntry(d, ctx)),
    // An intent that produced a ledger row is shown once, as that row.
    ...intentRows.filter((d) => !ledgerEngagement.has(d.id)).map((d) => intentEntry(d, ctx)),
  ].sort((a, b) => b.at.localeCompare(a.at));
  // Engagement status rides on its ledger row too.
  const statusOf = new Map(intents.docs.map((d) => [d.id, String(d.get('status'))]));
  for (const e of all) {
    if (e.entry.startsWith('d_')) {
      const id = ledger.docs.find((d) => d.id === e.entry)?.get('engagementId') as string | null;
      if (id) e.engagementStatus = statusOf.get(id) ?? null;
      if (!e.scenario && e.kind) e.scenario = engagementKindOfNotice[e.kind] ?? null;
    }
  }
  const filtered = all.filter((e) => matches(e, r));
  const page = filtered.slice(0, PAGE);
  const truncated = ledger.size >= SCAN || intents.size >= SCAN;
  const last = page.at(-1);
  const nextCursor =
    filtered.length > PAGE && last
      ? String(Date.parse(last.at))
      : truncated && last
        ? String(Date.parse(last.at))
        : null;

  // Summary over the whole range scanned (not just the page).
  const summary = {
    notifications: ledger.docs.filter((d) => d.get('inboxId')).length,
    engagements: intentRows.length,
    completed: intentRows.filter((d) => d.get('completedAt') || d.get('status') === 'completed')
      .length,
    pending: intentRows.filter((d) =>
      ['eligible', 'deferred', 'attempted'].includes(String(d.get('status'))),
    ).length,
    suppressed: intentRows.filter((d) =>
      ['suppressed', 'in_app_only'].includes(String(d.get('status'))),
    ).length,
    failed: ledger.docs.filter((d) => ['failed', 'unknown'].includes(String(d.get('delivery'))))
      .length,
    lastActivityAt: all[0]?.at ?? null,
  };

  const [upcoming, preferences] = await Promise.all([
    upcomingFor(db, ctx, intents.docs, now),
    preferencesFor(db, ctx),
  ]);

  const batch = db.batch();
  staffAudit(
    batch,
    db,
    s,
    {
      action: 'notifications.timeline.view',
      category: 'notifications',
      target: ctx.code,
      reason: null,
      detail: { from: r.from, to: r.to, view: r.view },
    },
    now,
  );
  await batch.commit();

  return {
    family: { code: ctx.code, babies: ctx.babyIds.length, members: ctx.recipients.length },
    summary,
    recipients: ctx.recipients,
    entries: page,
    nextCursor,
    upcoming,
    preferences,
    truncated,
  };
}

const conditionsOf: Record<string, string[]> = {
  'ENG-01': ['flag', 'consent', 'category', 'device_lease', 'fresh_source', 'caps', 'quiet_hours'],
  'ENG-02': [
    'flag',
    'consent',
    'category',
    'ready_photos',
    'usable_template',
    'no_keepsake',
    'caps',
  ],
  'ENG-03': ['flag', 'consent', 'category', 'saved_this_week', 'caps', 'quiet_hours'],
  'ENG-04': ['rule_enabled', 'recipient_member', 'reminders_setting'],
  'ENG-05': ['flag', 'consent', 'category', 'unseen_family_content', 'caps'],
  'ENG-06': ['flag', 'consent', 'category', 'personal_day_ready', 'caps', 'seven_day_spacing'],
};

async function upcomingFor(
  db: Firestore,
  ctx: FamilyContext,
  intents: DocumentSnapshot[],
  now: Date,
): Promise<TimelineUpcoming[]> {
  const out: TimelineUpcoming[] = [];
  const t = now.getTime();
  // Care rule reminders: the server holds the next time — the only truly confirmed schedule.
  for (const b of ctx.babyIds) {
    const rules = await db
      .collection(`babies/${b}/reminderRules`)
      .where('enabled', '==', true)
      .limit(20)
      .get();
    for (const rule of rules.docs) {
      const at = ms(rule.get('nextDueAt'));
      if (at <= t) continue;
      out.push({
        scenario: 'ENG-04',
        certainty: 'confirmed',
        state: 'scheduled',
        at: new Date(at).toISOString(),
        expiresAt: null,
        conditions: conditionsOf['ENG-04']!,
        recipient: null,
      });
    }
  }
  for (const d of intents) {
    const kind = String(d.get('kind'));
    if (kind === 'ENG-04') continue;
    const status = String(d.get('status'));
    const expiresAt = ms(d.get('expiresAt'));
    const nextAt = ms(d.get('nextAt'));
    if (['completed', 'cancelled', 'expired', 'accepted', 'failed', 'unknown'].includes(status))
      continue;
    if (expiresAt && expiresAt <= t) continue;
    const state: TimelineUpcoming['state'] = ['suppressed', 'in_app_only'].includes(status)
      ? 'suppressed'
      : expiresAt && expiresAt - t < 2 * DAY_MS
        ? 'expiring'
        : nextAt > t
          ? 'scheduled'
          : 'waiting';
    out.push({
      scenario: kind,
      // The engine rechecks consent, caps and the source right before a send: never confirmed.
      certainty: 'predicted',
      state,
      at: nextAt > t ? new Date(nextAt).toISOString() : null,
      expiresAt: expiresAt ? new Date(expiresAt).toISOString() : null,
      conditions: conditionsOf[kind] ?? [],
      recipient: ctx.refOf.get(String(d.get('uid'))) ?? null,
    });
  }
  // Milestone campaigns not yet open (ENG-02): predicted from the baby's age, at day precision.
  for (const b of ctx.babyIds) {
    const baby = await db.doc(`babies/${b}`).get();
    const dob = baby.get('dob') as string | undefined;
    const zone = String(baby.get('timeZone.zone') ?? 'Asia/Ho_Chi_Minh');
    if (!dob || !/^\d{4}-\d{2}-\d{2}$/.test(dob)) continue;
    for (const c of campaignKinds) {
      const w = campaignWindow(dob, c, zone, now);
      if (w.dueAt <= t || w.dueAt - t > 60 * DAY_MS) continue;
      if (intents.some((d) => String(d.get('source')).startsWith(`campaign:${c}`))) continue;
      out.push({
        scenario: 'ENG-02',
        certainty: 'predicted',
        state: 'waiting',
        at: new Date(w.dueAt).toISOString(),
        expiresAt: new Date(w.pushExpiresAt).toISOString(),
        conditions: conditionsOf['ENG-02']!,
        recipient: null,
      });
    }
  }
  return out.sort((a, b) => (a.at ?? '9').localeCompare(b.at ?? '9')).slice(0, 40);
}

async function preferencesFor(db: Firestore, ctx: FamilyContext) {
  const uids = [...ctx.refOf.keys()].slice(0, 20);
  if (uids.length === 0) return [];
  const [settings, engagement] = await Promise.all([
    db.getAll(...uids.map((u) => db.doc(`users/${u}/settings/notifications`))),
    db.getAll(...uids.map((u) => db.doc(`users/${u}/settings/engagement`))),
  ]);
  return uids.map((u, i) => {
    const chosen = notificationSettingsOf(settings[i]!.data());
    const consent = engagement[i]!.get('preferences.consent');
    return {
      recipient: ctx.refOf.get(u)!,
      muted: notificationSettingKeys.filter((k) => !chosen[k]),
      engagementConsent: typeof consent === 'boolean' ? consent : null,
    };
  });
}

// ---------- Detail ----------

/** The engine's rule order (`decideEngagement`): the reason names the first rule that failed. */
const ruleOrder: Array<{ rule: string; fails: string[] }> = [
  { rule: 'feature_enabled', fails: ['disabled'] },
  { rule: 'authorized', fails: ['not_authorized'] },
  { rule: 'source_open', fails: ['source_resolved'] },
  { rule: 'not_dismissed', fails: ['user_choice'] },
  { rule: 'not_sent_before', fails: ['duplicate'] },
  { rule: 'window_open', fails: ['window_closed'] },
  { rule: 'source_verified', fails: ['awaiting_verification'] },
  { rule: 'not_fatigued', fails: ['fatigue_paused'] },
  { rule: 'consent_and_category', fails: ['channel_unavailable'] },
  { rule: 'post_completion_quiet', fails: ['post_completion_quiet'] },
  { rule: 'not_holdout', fails: ['holdout'] },
  { rule: 'not_grouped', fails: ['digest_member'] },
  { rule: 'due', fails: ['not_due', 'snoozed', 'higher_priority'] },
  { rule: 'outside_quiet_hours', fails: ['quiet_hours'] },
  { rule: 'within_caps', fails: ['budget'] },
];

export function engagementChecks(reason: string | null, status: string): NotificationDetailCheck[] {
  const sent =
    ['attempted', 'accepted', 'failed', 'unknown'].includes(status) || reason === 'reserved';
  const failAt = sent ? -1 : ruleOrder.findIndex((r) => r.fails.includes(reason ?? ''));
  return ruleOrder.map((r, i) => ({
    rule: r.rule,
    result: sent || (failAt >= 0 && i < failAt) ? 'pass' : i === failAt ? 'fail' : 'unknown',
    ...(i === failAt && reason ? { detail: reason } : {}),
  }));
}

export async function notificationDetail(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
): Promise<NotificationEntryDetail> {
  const s = requireStaff(staff, 'notifications.timeline');
  const { code, entry } = parse(staffNotificationDetailSchema, data) as {
    code: string;
    entry: string;
  };
  const ctx = await familyContext(db, code);
  let ledger: DocumentSnapshot | null = null;
  let intent: DocumentSnapshot | null = null;
  if (entry.startsWith('d_')) {
    ledger = await db.doc(`${LEDGER}/${entry}`).get();
    const eid = ledger.get('engagementId') as string | null;
    if (eid) intent = await db.doc(`engagementIntents/${eid}`).get();
  } else {
    intent = await db.doc(`engagementIntents/${entry.slice(2)}`).get();
  }
  // A code never reveals another family's rows.
  const familyOk =
    (ledger?.exists && ledger.get('familyId') === ctx.familyId) ||
    (!ledger && intent?.exists && intent.get('familyId') === ctx.familyId);
  if (!familyOk) throw new StaffError('not-found', 'not-found');

  const status = intent?.exists ? String(intent.get('status')) : '';
  const reason = intent?.exists ? ((intent.get('reason') as string | null) ?? null) : null;
  const history = (
    (ledger?.get('history') as Array<Record<string, unknown>> | undefined) ?? []
  ).map((h) => ({
    at: iso(h.at) ?? '',
    dimension: String(h.d),
    to: String(h.to),
    reason: (h.r as string | undefined) ?? null,
  }));
  const kind = (ledger?.get('kind') as NotificationKind | undefined) ?? null;
  const delivery = ledger?.get('delivery') as NotificationDeliveryState | undefined;
  const errors = [
    ...(ledger?.get('errorCode') ? [String(ledger.get('errorCode'))] : []),
    ...(delivery === 'failed' || delivery === 'unknown' ? [`delivery_${delivery}`] : []),
  ];
  const scenario = intent?.exists ? String(intent.get('kind')) : null;
  const why = scenario
    ? `${scenario}:${String(intent!.get('source') ?? '').split(':')[0]}`
    : kind
      ? `${notificationTypes[kind].producer}`
      : null;

  const batch = db.batch();
  staffAudit(
    batch,
    db,
    s,
    {
      action: 'notifications.timeline.detail',
      category: 'notifications',
      target: ctx.code,
      reason: null,
      detail: { entry },
    },
    now,
  );
  await batch.commit();

  return {
    entry,
    scenario,
    kind,
    why,
    checks: intent?.exists
      ? engagementChecks(reason, status)
      : ledger
        ? [
            {
              rule: 'setting_on',
              result: ledger.get('deliveryReason') === 'setting_off' ? 'fail' : 'pass',
            },
            {
              rule: 'outside_quiet_hours',
              result: ledger.get('deliveryReason') === 'quiet_hours' ? 'fail' : 'pass',
            },
            {
              rule: 'push_not_paused',
              result: ledger.get('deliveryReason') === 'kill_switch' ? 'fail' : 'pass',
            },
            {
              rule: 'device_registered',
              result: ledger.get('deliveryReason') === 'no_device' ? 'fail' : 'pass',
            },
          ]
        : [],
    decision: intent?.exists ? status : ((ledger?.get('delivery') as string | undefined) ?? null),
    reason: reason ?? (ledger?.get('deliveryReason') as string | undefined) ?? null,
    templateId: (ledger?.get('templateId') as string | null | undefined) ?? null,
    templateVersion: ledger ? Number(ledger.get('templateVersion') ?? 0) : null,
    destination: (ledger?.get('destination') as NotificationEntryDetail['destination']) ?? null,
    timeline: history,
    pushAttempted: ledger ? Number(ledger.get('attempts') ?? 0) > 0 : null,
    providerAccepted: ledger ? Number(ledger.get('acceptedTokens') ?? 0) > 0 : null,
    opened: ledger ? Boolean(ledger.get('openedAt')) : null,
    openSurface: (ledger?.get('openSurface') as 'push' | 'inbox' | null | undefined) ?? null,
    navigated: (ledger?.get('navigation') as NotificationEntryDetail['navigated']) ?? null,
    completed: intent?.exists
      ? Boolean(intent.get('completedAt')) || status === 'completed'
      : ledger
        ? ledger.get('action') === 'completed'
        : null,
    cancelledOrExpired:
      status === 'cancelled' || status === 'expired'
        ? status
        : ledger?.get('lifecycle') === 'expired' || ledger?.get('lifecycle') === 'cancelled'
          ? String(ledger.get('lifecycle'))
          : null,
    errors,
  };
}

/** Today in the reporting zone (used by the Portal's default range). */
export function reportingToday(now: Date): string {
  return localDateIn(STATS_ZONE, now);
}
