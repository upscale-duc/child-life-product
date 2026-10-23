import {
  INBOX_RETENTION_DAYS,
  NOTIFICATION_MAX_ATTEMPTS,
  defaultUserPreferences,
  destinationFor,
  inQuietHours,
  notificationCategoryOf,
  notificationRouteOf,
  notificationSettingOf,
  notificationSettingsOf,
  notificationTypes,
  recordNotificationOpenSchema,
  notificationTemplates,
  renderTemplate,
  retryDelayMs,
  ringsInQuietHours,
  type InboxItem,
  type LocalizedTemplateCopy,
  type NotificationDeliveryReason,
  type NotificationDestinationId,
  type NotificationKind,
  type NotificationStatMetric,
  type NotificationTemplateId,
  type PlaceholderValue,
} from '@child-life/contracts';
import {
  FieldValue,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
} from 'firebase-admin/firestore';
import type { PushSender } from './social.js';
import {
  LEDGER,
  applyTransition,
  countStats,
  ledgerDeleteAfter,
  ledgerId,
  ledgerRef,
  transitionEntry,
} from './notification-ledger.js';
import { liveTemplate, notificationOps } from './notification-runtime.js';

/**
 * Notification centre (D-076 #2, EN06 / EN07) and unified platform (P-174): the one way a server
 * notification reaches people. For each recipient it
 * 1. honours `users/{uid}/settings/notifications` (a switched-off kind is neither pushed nor
 *    kept; the ledger records it as muted),
 * 2. persists FIRST, in one transaction: the inbox row `users/{uid}/notifications/n_{id}` and the
 *    server-only ledger entry `notificationDeliveries/d_{hash(uid, id)}`. Both ids are derived from
 *    the notice id, so a producer retry finds them and writes nothing twice,
 * 3. holds the push back in the person's quiet hours (`settings/personalization`, EN02 / EN07)
 *    except for reminders they set, and when the group's push kill switch is on; the row stays,
 * 4. pushes to their signed-in devices in each device's language with `inboxId` and the semantic
 *    `destination`, drops tokens the push service rejects for good, and records the outcome:
 *    `accepted` = the provider took at least one token (never proof of display). A transient
 *    provider error becomes `retry_pending` (bounded retries by `retryNotificationDeliveries`),
 *    except for callers that opt out (`retry: false`, Smart Engagement: an ambiguous send is
 *    `unknown` and never resent).
 * Copy is the producer's (template version 0) unless a published Portal template exists for the
 * notice's template id. Nothing about the child is logged here.
 */

export type PushMessage = Parameters<PushSender['send']>[1];
export type Language = 'vi' | 'en';

export interface Notice {
  kind: NotificationKind;
  /** Names the event once (per baby / rule / date …): the dedup key of the row and the ledger. */
  id: string;
  babyId: string | null;
  /** Ids only; `kind`, `inboxId` and `destination` are added. */
  data: Record<string, string>;
  /** Title, body and platform options in [language] (the built-in copy, template version 0). */
  message: (language: Language) => Omit<PushMessage, 'data'>;
  /** The zone quiet hours are read in (the baby's); Hồ Chí Minh when unknown. */
  zone?: string | undefined;
  /** ENG-00 lease-selected install; existing callers retain their multi-device behavior. */
  deviceId?: string;
  /** Portal template that may override the copy, with the producer's placeholder values. */
  template?: { id: NotificationTemplateId; values?: Record<string, PlaceholderValue> } | undefined;
  /** Narrower destination than the kind's default (derived from `data` when absent). */
  destination?: NotificationDestinationId | undefined;
  /** Smart Engagement link (the ledger's action dimension follows the intent). */
  engagement?: { id: string; kind: string };
  /** False: a provider error is ambiguous and never retried (ENG-00). Default true. */
  retry?: boolean;
  /**
   * Portal "Gửi thử" (D-092): delivered regardless of switches, quiet hours and kill switches,
   * marked `test` in the ledger, never counted in stats.
   */
  test?: { templateId: NotificationTemplateId; templateVersion: number } | undefined;
  /** Optional adapter observation; never means device presentation and never blocks delivery. */
  onResult?: (
    uid: string,
    result: {
      attempted: boolean;
      accepted: number;
      inbox: boolean;
      held: boolean;
      ambiguous?: boolean;
    },
  ) => Promise<void>;
}

export interface NotifyResult {
  /** Tokens the push service accepted. */
  sent: number;
  /** Inbox rows written. */
  recorded: number;
  /** People whose push quiet hours held back. */
  held: number;
  /** People who already had this notice (a producer retry): nothing was written or sent. */
  duplicate: number;
}

const DAY_MS = 86_400_000;
const defaultZone = 'Asia/Ho_Chi_Minh';

export function inboxIdOf(noticeId: string): string {
  return `n_${noticeId.replace(/[^A-Za-z0-9_-]/g, '-').slice(0, 118)}`;
}

/** Sends [notice] to [uids] (see the file comment). */
export async function notifyUsers(
  db: Firestore,
  sender: PushSender | null,
  uids: string[],
  notice: Notice,
  now: Date,
): Promise<NotifyResult> {
  const result: NotifyResult = { sent: 0, recorded: 0, held: 0, duplicate: 0 };
  const people = [...new Set(uids)].filter((u) => u.length > 0);
  if (people.length === 0) return result;
  const type = notificationTypes[notice.kind];
  const settingKey = notice.test ? null : notificationSettingOf[notice.kind];
  const [settings, ops, baby] = await Promise.all([
    db.getAll(...people.map((u) => db.doc(`users/${u}/settings/notifications`))),
    notificationOps(db, now.getTime()),
    babyOf(db, notice.babyId),
  ]);
  const familyId = baby.familyId;
  const quietApplies = !notice.test && !ringsInQuietHours(notice.kind);
  const prefs = quietApplies
    ? await db.getAll(...people.map((u) => db.doc(`users/${u}/settings/personalization`)))
    : [];

  // Copy: the template (published version, else its built-in version 0) rendered with the
  // producer's values plus the baby's name (D-094); the producer's own copy if a value is missing.
  const builtin = { vi: notice.message('vi'), en: notice.message('en') };
  let templateVersion = 0;
  let renderError = false;
  let source: LocalizedTemplateCopy | null = null;
  if (notice.template) {
    const live =
      ops.templatesEnabled && !notice.test
        ? await liveTemplate(db, notice.template.id, now.getTime()).catch(() => null)
        : null;
    source = live?.copy ?? notificationTemplates[notice.template.id].builtin;
    templateVersion = live?.version ?? 0;
  }
  const values = { ...(notice.template?.values ?? {}) };
  if (baby.nickname && values.baby_name === undefined) values.baby_name = baby.nickname;
  /** The copy for one recipient: with the baby's name, or "bé" when they turned it off. */
  const copyFor = (withName: boolean) => {
    const copy = { vi: { ...builtin.vi }, en: { ...builtin.en } };
    if (!source) return copy;
    const own = { ...values };
    if (!withName) delete own.baby_name;
    const vi = renderTemplate(source, 'vi', own);
    const en = renderTemplate(source, 'en', own);
    if (vi.missing.length || en.missing.length) {
      renderError = templateVersion > 0;
      return copy;
    }
    copy.vi = { ...copy.vi, title: vi.title, body: vi.body };
    copy.en = { ...copy.en, title: en.title, body: en.body };
    return copy;
  };
  const named = copyFor(true);
  const unnamed = copyFor(false);
  const destination = notice.destination ?? destinationFor(notice.kind, notice.data);
  const inboxId = inboxIdOf(notice.id);
  const data = { ...notice.data, kind: notice.kind, inboxId, destination };
  // Platform options (category, collapse id, expiry) a retry needs; never the copy itself.
  const pushOptions: Record<string, unknown> = { ...builtin.vi };
  delete pushOptions.title;
  delete pushOptions.body;
  const templateId = notice.test?.templateId ?? notice.template?.id ?? type.templates[0] ?? null;
  if (notice.test) templateVersion = notice.test.templateVersion;
  const entryBase = {
    v: 1,
    familyId,
    babyId: notice.babyId,
    kind: notice.kind,
    group: type.group,
    producer: type.producer,
    templateId,
    templateVersion,
    destination,
    dedupKey: notice.id.slice(0, 200),
    correlationId: notice.engagement?.id ?? notice.id.slice(0, 200),
    engagementId: notice.engagement?.id ?? null,
    engagementKind: notice.engagement?.kind ?? null,
    read: 'unread',
    action: type.action === 'engagement' ? 'not_started' : 'none',
    attempts: 0,
    nextAttemptAt: null,
    acceptedTokens: 0,
    rejectedTokens: 0,
    createdAt: now,
    persistedAt: null as Date | null,
    attemptedAt: null,
    acceptedAt: null,
    failedAt: null,
    readAt: null,
    openedAt: null,
    openSurface: null,
    navigation: null,
    navigatedAt: null,
    actionAt: null,
    pushExpiresAt: typeof builtin.vi.expiresAt === 'number' ? new Date(builtin.vi.expiresAt) : null,
    push: pushOptions,
    retryable: notice.retry !== false,
    ...(notice.test ? { test: true } : {}),
    errorCode: null,
    deleteAfter: ledgerDeleteAfter(now),
    updatedAt: now,
  };
  const statKeys = { kind: notice.kind, group: type.group, templateId, templateVersion };

  for (const [i, uid] of people.entries()) {
    const acceptedBefore = result.sent;
    const observe = async (
      attempted: boolean,
      inbox: boolean,
      held: boolean,
      ambiguous = false,
    ) => {
      try {
        await notice.onResult?.(uid, {
          attempted,
          accepted: result.sent - acceptedBefore,
          inbox,
          held,
          ambiguous,
        });
      } catch {
        /* Optional measurement cannot fail a notification. */
      }
    };
    const entryId = ledgerId(uid, `${notice.kind}:${notice.id}`);
    const chosen = notificationSettingsOf(settings[i]!.data());
    const copy = chosen.babyName ? named : unnamed;
    if (settingKey && !chosen[settingKey]) {
      // Muted: no row, no push; the ledger keeps the fact (no copy) for the family timeline.
      await db
        .runTransaction(async (tx) => {
          const ref = ledgerRef(db, entryId);
          if ((await tx.get(ref)).exists) return;
          tx.create(ref, {
            ...entryBase,
            uid,
            inboxId: null,
            lifecycle: 'cancelled',
            delivery: 'cancelled',
            deliveryReason: 'setting_off',
            devices: 0,
            history: [{ at: now, d: 'lifecycle', to: 'cancelled', r: 'setting_off' }],
          });
          countStats(tx, db, entryId, now, statKeys, ['created', 'muted']);
        })
        .catch(() => undefined);
      await observe(false, false, false);
      continue;
    }
    // EN07 shows the same quiet hours (EN02's default until the person changes them).
    const quiet =
      quietApplies && inQuietHours(quietHoursOf(prefs[i]), notice.zone ?? defaultZone, now);

    const devices = await db.collection(`users/${uid}/devices`).get();
    const byLanguage = new Map<Language, DocumentSnapshot[]>();
    for (const d of devices.docs) {
      if (notice.deviceId && d.id !== notice.deviceId) continue;
      const token = d.get('token') as string | undefined;
      if (!token || d.get('signedOutAt')) continue;
      const language: Language = d.get('language') === 'en' ? 'en' : 'vi';
      byLanguage.set(language, [...(byLanguage.get(language) ?? []), d]);
    }
    const deviceCount = [...byLanguage.values()].reduce((n, l) => n + l.length, 0);
    const stop: NotificationDeliveryReason | null = quiet
      ? 'quiet_hours'
      : ops.pushPaused[type.group] && !notice.test
        ? 'kill_switch'
        : sender === null
          ? 'no_sender'
          : deviceCount === 0
            ? 'no_device'
            : null;
    const pushing = stop === null;

    const item: InboxItem = {
      kind: notice.kind,
      category: notificationCategoryOf[notice.kind],
      title: { vi: copy.vi.title, en: copy.en.title },
      body: { vi: copy.vi.body, en: copy.en.body },
      route: notificationRouteOf(notice.kind),
      babyId: notice.babyId,
      data,
      pushed: pushing,
      createdAt: now,
      readAt: null,
      archivedAt: null,
      expireAt: new Date(now.getTime() + INBOX_RETENTION_DAYS * DAY_MS),
      destination,
      group: type.group,
      templateId,
      templateVersion,
      ledgerId: entryId,
    };
    const created = await db.runTransaction(async (tx) => {
      const ref = ledgerRef(db, entryId);
      if ((await tx.get(ref)).exists) return false;
      tx.set(db.doc(`users/${uid}/notifications/${inboxId}`), item);
      tx.create(ref, {
        ...entryBase,
        uid,
        inboxId,
        lifecycle: 'persisted',
        persistedAt: now,
        delivery: pushing ? 'pending' : 'cancelled',
        deliveryReason: stop ?? 'none',
        devices: deviceCount,
        history: [
          { at: now, d: 'lifecycle', to: 'persisted' },
          ...(pushing ? [] : [{ at: now, d: 'delivery', to: 'cancelled', r: stop }]),
        ],
      });
      const metrics: NotificationStatMetric[] = ['created', 'inbox'];
      if (stop === 'quiet_hours') metrics.push('held');
      else if (stop === 'no_device') metrics.push('no_device');
      else if (stop) metrics.push('cancelled');
      if (renderError) metrics.push('render_error');
      countStats(tx, db, entryId, now, statKeys, metrics, Boolean(notice.test));
      return true;
    });
    if (!created) {
      result.duplicate += 1;
      continue;
    }
    result.recorded += 1;
    await pruneInbox(db, uid, now);
    if (quiet) {
      result.held += 1;
      await observe(false, true, true);
      continue;
    }
    if (!pushing || !sender) {
      await observe(false, true, false);
      continue;
    }
    await transitionEntry(
      db,
      entryId,
      { delivery: 'attempted', patch: { attempts: 1, attemptedAt: now } },
      now,
    );
    const outcome = await pushTo(db, sender, byLanguage, copy, data);
    result.sent += outcome.accepted;
    if (outcome.error) {
      if (notice.retry === false) {
        // ENG-00: a send whose outcome is unknown consumes its slot and is never resent.
        await settle(db, entryId, outcome, 'unknown', now);
        await observe(true, true, false, true);
        throw outcome.error;
      }
      await settle(
        db,
        entryId,
        outcome,
        outcome.accepted > 0 ? 'accepted' : ops.retryEnabled ? 'retry_pending' : 'failed',
        now,
        1,
      );
      await observe(true, true, false, outcome.accepted === 0);
      continue;
    }
    await settle(db, entryId, outcome, outcome.accepted > 0 ? 'accepted' : 'rejected', now);
    await observe(true, true, false);
  }
  return result;
}

interface PushOutcome {
  accepted: number;
  rejected: number;
  error: unknown;
}

/** One push per device language; tokens rejected for good leave the device row. */
async function pushTo(
  db: Firestore,
  sender: PushSender,
  byLanguage: Map<Language, DocumentSnapshot[]>,
  copy: Record<Language, Omit<PushMessage, 'data'>>,
  data: Record<string, string>,
): Promise<PushOutcome> {
  const out: PushOutcome = { accepted: 0, rejected: 0, error: null };
  for (const [language, docs] of byLanguage) {
    const tokens = docs.map((d) => d.get('token') as string);
    let rejected: string[];
    try {
      rejected = await sender.send(tokens, { ...copy[language], data });
    } catch (error) {
      out.error = error;
      continue;
    }
    out.accepted += tokens.length - rejected.length;
    out.rejected += rejected.length;
    // The token goes, the install stays in "Thiết bị đang đăng nhập" (13n) until it signs out;
    // the app writes a fresh token on its next launch.
    for (const t of rejected) {
      await docs.find((d) => d.get('token') === t)?.ref.update({ token: FieldValue.delete() });
    }
  }
  return out;
}

async function settle(
  db: Firestore,
  entryId: string,
  outcome: PushOutcome,
  to: 'accepted' | 'rejected' | 'retry_pending' | 'failed' | 'unknown',
  now: Date,
  attempt = 1,
) {
  const reason: NotificationDeliveryReason =
    to === 'rejected'
      ? 'provider_rejected'
      : to === 'retry_pending' || to === 'failed'
        ? attempt >= NOTIFICATION_MAX_ATTEMPTS
          ? 'retry_exhausted'
          : 'provider_error'
        : to === 'unknown'
          ? 'ambiguous'
          : 'none';
  await transitionEntry(
    db,
    entryId,
    {
      delivery: to,
      deliveryReason: reason,
      patch: {
        acceptedTokens: FieldValue.increment(outcome.accepted),
        rejectedTokens: FieldValue.increment(outcome.rejected),
        ...(to === 'accepted' ? { acceptedAt: now } : {}),
        ...(to === 'failed' ? { failedAt: now } : {}),
        nextAttemptAt:
          to === 'retry_pending' ? new Date(now.getTime() + retryDelayMs(attempt)) : null,
        errorCode: outcome.error ? errorCodeOf(outcome.error) : null,
      },
    },
    now,
  ).catch(() => undefined);
}

/** A provider error code without message text (no tokens or payloads in the ledger). */
function errorCodeOf(error: unknown): string {
  const code = (error as { code?: unknown } | null)?.code;
  return typeof code === 'string' ? code.slice(0, 80) : 'error';
}

/** The baby's family and nickname (D-094: the name pushes may show). */
async function babyOf(
  db: Firestore,
  babyId: string | null,
): Promise<{ familyId: string | null; nickname: string | null }> {
  if (!babyId) return { familyId: null, nickname: null };
  try {
    const baby = await db.doc(`babies/${babyId}`).get();
    const nickname = baby.get('nickname');
    return {
      familyId: (baby.get('familyId') as string | undefined) ?? null,
      nickname: typeof nickname === 'string' && nickname.trim() ? nickname.trim() : null,
    };
  } catch {
    return { familyId: null, nickname: null };
  }
}

/** The saved quiet hours; the EN02 default (22:00–06:00) until the person saves their own. */
function quietHoursOf(pref: DocumentSnapshot | undefined) {
  if (!pref?.exists) return defaultUserPreferences.quietHours;
  const q = pref.get('quietHours') as unknown;
  if (!q || typeof q !== 'object') return null;
  const { from, to } = q as { from?: unknown; to?: unknown };
  return typeof from === 'string' && typeof to === 'string' ? { from, to } : null;
}

/** Rows older than the retention go when a new one comes (a few at a time). */
async function pruneInbox(db: Firestore, uid: string, now: Date): Promise<void> {
  const old = await db
    .collection(`users/${uid}/notifications`)
    .where('createdAt', '<', Timestamp.fromMillis(now.getTime() - INBOX_RETENTION_DAYS * DAY_MS))
    .limit(20)
    .get();
  for (const d of old.docs) await d.ref.delete();
}

/**
 * Daily: inbox rows past `expireAt` for people who got nothing new since (the collection-group
 * index on `notifications.expireAt` is in firestore.indexes.json). Family notices under
 * `babies/{id}/notifications` have no `expireAt` and are never matched. Their ledger entries move
 * to lifecycle `expired`.
 */
export async function sweepExpiredInbox(db: Firestore, now: Date): Promise<number> {
  let removed = 0;
  for (let round = 0; round < 20; round += 1) {
    const due = await db
      .collectionGroup('notifications')
      .where('expireAt', '<=', Timestamp.fromDate(now))
      .limit(300)
      .get();
    const rows = due.docs.filter((d) => d.ref.parent.parent?.parent.id === 'users');
    if (rows.length === 0) break;
    const batch = db.batch();
    for (const d of rows) batch.delete(d.ref);
    await batch.commit();
    for (const d of rows) {
      const id = d.get('ledgerId') as string | undefined;
      if (id) await transitionEntry(db, id, { lifecycle: 'expired' }, now).catch(() => undefined);
    }
    removed += rows.length;
    if (due.size < 300) break;
  }
  return removed;
}

// ---------- Retries ----------

/**
 * Every 5 minutes: deliveries in `retry_pending` whose time came. Each is claimed (→ attempted) in
 * a transaction first, so two workers never send the same row. The copy is the inbox row's (what
 * the person already sees); an expired push or a row the person no longer has is cancelled.
 */
export async function retryNotificationDeliveries(
  db: Firestore,
  sender: PushSender | null,
  now: Date,
): Promise<{ retried: number; accepted: number; failed: number }> {
  const out = { retried: 0, accepted: 0, failed: 0 };
  if (!sender) return out;
  const due = await db
    .collection(LEDGER)
    .where('delivery', '==', 'retry_pending')
    .where('nextAttemptAt', '<=', Timestamp.fromDate(now))
    .limit(100)
    .get();
  for (const doc of due.docs) {
    const claim = await db.runTransaction(async (tx) => {
      const live = await tx.get(doc.ref);
      if (live.get('delivery') !== 'retry_pending') return null;
      const expires = live.get('pushExpiresAt') as Timestamp | null;
      const attempts = Number(live.get('attempts') ?? 0);
      if (expires && expires.toMillis() <= now.getTime()) {
        applyTransition(tx, db, live, { delivery: 'cancelled', deliveryReason: 'expired' }, now);
        return null;
      }
      if (attempts >= NOTIFICATION_MAX_ATTEMPTS || live.get('retryable') === false) {
        applyTransition(
          tx,
          db,
          live,
          { delivery: 'failed', deliveryReason: 'retry_exhausted', patch: { failedAt: now } },
          now,
        );
        return null;
      }
      applyTransition(
        tx,
        db,
        live,
        { delivery: 'attempted', patch: { attempts: attempts + 1, attemptedAt: now } },
        now,
      );
      return { attempt: attempts + 1, live };
    });
    if (!claim) continue;
    out.retried += 1;
    const { live, attempt } = claim;
    const uid = String(live.get('uid'));
    const row = await db.doc(`users/${uid}/notifications/${String(live.get('inboxId'))}`).get();
    if (!row.exists || row.get('archivedAt')) {
      await transitionEntry(db, doc.id, { delivery: 'cancelled', deliveryReason: 'aborted' }, now);
      continue;
    }
    const devices = await db.collection(`users/${uid}/devices`).get();
    const byLanguage = new Map<Language, DocumentSnapshot[]>();
    for (const d of devices.docs) {
      const token = d.get('token') as string | undefined;
      if (!token || d.get('signedOutAt')) continue;
      const language: Language = d.get('language') === 'en' ? 'en' : 'vi';
      byLanguage.set(language, [...(byLanguage.get(language) ?? []), d]);
    }
    if (byLanguage.size === 0) {
      await transitionEntry(
        db,
        doc.id,
        { delivery: 'failed', deliveryReason: 'no_device', patch: { failedAt: now } },
        now,
      );
      out.failed += 1;
      continue;
    }
    const options = (live.get('push') as Omit<PushMessage, 'data' | 'title' | 'body'>) ?? {};
    const title = row.get('title') as { vi: string; en: string };
    const body = row.get('body') as { vi: string; en: string };
    const copy = {
      vi: { ...options, title: title.vi, body: body.vi },
      en: { ...options, title: title.en, body: body.en },
    };
    const outcome = await pushTo(
      db,
      sender,
      byLanguage,
      copy,
      row.get('data') as Record<string, string>,
    );
    if (outcome.error && outcome.accepted === 0) {
      await settle(
        db,
        doc.id,
        outcome,
        attempt >= NOTIFICATION_MAX_ATTEMPTS ? 'failed' : 'retry_pending',
        now,
        attempt,
      );
      if (attempt >= NOTIFICATION_MAX_ATTEMPTS) out.failed += 1;
      continue;
    }
    await settle(db, doc.id, outcome, outcome.accepted > 0 ? 'accepted' : 'rejected', now, attempt);
    if (outcome.accepted > 0) out.accepted += 1;
  }
  return out;
}

/** Staff "Thử gửi lại" on a failed delivery (never an accepted, ENG or expired one). */
export async function staffRequeueDelivery(
  db: Firestore,
  entryId: string,
  now: Date,
): Promise<boolean> {
  const moved = await transitionEntry(
    db,
    entryId,
    (entry) => {
      if (entry.get('delivery') !== 'failed' || entry.get('retryable') === false) return null;
      if (entry.get('engagementId')) return null;
      const expires = entry.get('pushExpiresAt') as Timestamp | null;
      if (expires && expires.toMillis() <= now.getTime()) return null;
      return {
        delivery: 'retry_pending',
        deliveryReason: 'staff_retry',
        // One more attempt than the budget already used.
        patch: { nextAttemptAt: now, attempts: NOTIFICATION_MAX_ATTEMPTS - 1 },
      };
    },
    now,
  );
  return moved.includes('delivery');
}

// ---------- Read and open receipts ----------

/** Trigger: the person (any of their devices) marked the row read → ledger read state. */
export async function onInboxRowUpdated(
  db: Firestore,
  before: DocumentSnapshot | null,
  after: DocumentSnapshot | null,
  now: Date,
): Promise<void> {
  if (!after?.exists) return;
  const id = after.get('ledgerId') as string | undefined;
  if (!id) return;
  if (!before?.get('readAt') && after.get('readAt')) {
    const readAt = after.get('readAt') as Timestamp;
    await transitionEntry(db, id, { read: 'read', patch: { readAt: readAt.toDate() } }, now);
  }
}

/**
 * The app opened a row (from the push or the inbox) and tells where it got: the destination,
 * its fallback, or nowhere. Only the caller's own rows (the path is theirs); the first open of an
 * entry counts. Opening is not completing: the action dimension moves only from its producer.
 */
export async function recordNotificationOpen(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<{ ok: boolean }> {
  const parsed = recordNotificationOpenSchema.safeParse(data);
  if (!parsed.success) return { ok: false };
  const { inboxId, surface, outcome } = parsed.data;
  const row = await db.doc(`users/${uid}/notifications/${inboxId}`).get();
  const id = row.get('ledgerId') as string | undefined;
  if (!row.exists || !id) return { ok: false };
  await transitionEntry(
    db,
    id,
    (entry) => {
      if (entry.get('uid') !== uid || entry.get('openedAt')) return null;
      return {
        read: 'read',
        patch: {
          openedAt: now,
          openSurface: surface,
          navigation: outcome,
          navigatedAt: outcome === 'unavailable' ? null : now,
          ...(entry.get('readAt') ? {} : { readAt: now }),
        },
        metrics: ['opened', surface === 'push' ? 'opened_push' : 'opened_inbox', outcome],
      };
    },
    now,
  );
  return { ok: true };
}
