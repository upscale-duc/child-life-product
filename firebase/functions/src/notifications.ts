import {
  INBOX_RETENTION_DAYS,
  defaultUserPreferences,
  inQuietHours,
  notificationCategoryOf,
  notificationRouteOf,
  notificationSettingOf,
  notificationSettingsOf,
  ringsInQuietHours,
  type InboxItem,
  type NotificationKind,
} from '@child-life/contracts';
import {
  FieldValue,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
} from 'firebase-admin/firestore';
import type { PushSender } from './social.js';

/**
 * Notification centre (D-076 #2, EN06 / EN07): the one way a server push reaches people. For
 * each recipient it
 * 1. honours `users/{uid}/settings/notifications` (a switched-off kind is neither pushed nor
 *    kept),
 * 2. records the push in `users/{uid}/notifications/n_{id}-{time}` — the copy it showed (generic,
 *    R-120) in both languages and ids for the deep link (each sender already claims a push once),
 * 3. holds the push back in the person's quiet hours (`settings/personalization`, EN02 / EN07)
 *    except for reminders they set; the row still waits in the inbox,
 * 4. pushes to their signed-in devices in each device's language with `inboxId`, and drops
 *    tokens the push service rejects for good (the device row stays).
 * Nothing about the child is logged here.
 */

export type PushMessage = Parameters<PushSender['send']>[1];
export type Language = 'vi' | 'en';

export interface Notice {
  kind: NotificationKind;
  /** Names the push (per baby / rule / date …); the inbox row is `n_{id}-{time}` per person. */
  id: string;
  babyId: string | null;
  /** Ids only; `kind` is added. */
  data: Record<string, string>;
  /** Title, body and platform options in [language]. */
  message: (language: Language) => Omit<PushMessage, 'data'>;
  /** The zone quiet hours are read in (the baby's); Hồ Chí Minh when unknown. */
  zone?: string | undefined;
}

export interface NotifyResult {
  /** Tokens the push service accepted. */
  sent: number;
  /** Inbox rows written. */
  recorded: number;
  /** People whose push quiet hours held back. */
  held: number;
}

const DAY_MS = 86_400_000;
const defaultZone = 'Asia/Ho_Chi_Minh';

function safeId(id: string): string {
  return `n_${id.replace(/[^A-Za-z0-9_-]/g, '-')}`;
}

/** Sends [notice] to [uids] (see the file comment). */
export async function notifyUsers(
  db: Firestore,
  sender: PushSender | null,
  uids: string[],
  notice: Notice,
  now: Date,
): Promise<NotifyResult> {
  const result: NotifyResult = { sent: 0, recorded: 0, held: 0 };
  const people = [...new Set(uids)].filter((u) => u.length > 0);
  if (people.length === 0) return result;
  const settingKey = notificationSettingOf[notice.kind];
  const settings = await db.getAll(
    ...people.map((u) => db.doc(`users/${u}/settings/notifications`)),
  );
  const quietApplies = !ringsInQuietHours(notice.kind);
  const prefs = quietApplies
    ? await db.getAll(...people.map((u) => db.doc(`users/${u}/settings/personalization`)))
    : [];
  const copy = { vi: notice.message('vi'), en: notice.message('en') };
  const inboxId = safeId(`${notice.id.slice(0, 100)}-${now.getTime().toString(36)}`);
  const data = { ...notice.data, kind: notice.kind, inboxId };

  for (const [i, uid] of people.entries()) {
    const chosen = notificationSettingsOf(settings[i]!.data());
    if (settingKey && !chosen[settingKey]) continue;
    // EN07 shows the same quiet hours (EN02's default until the person changes them).
    const quiet =
      quietApplies && inQuietHours(quietHoursOf(prefs[i]), notice.zone ?? defaultZone, now);

    const devices = await db.collection(`users/${uid}/devices`).get();
    const byLanguage = new Map<Language, DocumentSnapshot[]>();
    for (const d of devices.docs) {
      const token = d.get('token') as string | undefined;
      if (!token || d.get('signedOutAt')) continue;
      const language: Language = d.get('language') === 'en' ? 'en' : 'vi';
      byLanguage.set(language, [...(byLanguage.get(language) ?? []), d]);
    }
    const pushing = !quiet && sender !== null && byLanguage.size > 0;

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
    };
    await db.doc(`users/${uid}/notifications/${inboxId}`).set(item);
    result.recorded += 1;
    await pruneInbox(db, uid, now);
    if (quiet) {
      result.held += 1;
      continue;
    }
    if (!pushing || !sender) continue;
    for (const [language, docs] of byLanguage) {
      const tokens = docs.map((d) => d.get('token') as string);
      const rejected = await sender.send(tokens, { ...copy[language], data });
      result.sent += tokens.length - rejected.length;
      // The token goes, the install stays in "Thiết bị đang đăng nhập" (13n) until it signs out;
      // the app writes a fresh token on its next launch.
      for (const t of rejected) {
        await docs.find((d) => d.get('token') === t)?.ref.update({ token: FieldValue.delete() });
      }
    }
  }
  return result;
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
 * `babies/{id}/notifications` have no `expireAt` and are never matched.
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
    removed += rows.length;
    if (due.size < 300) break;
  }
  return removed;
}
