import { z } from 'zod';

/**
 * Notification centre (D-076 #2; Figma EN06 Hộp thông báo `560:2884`, EN07 Cài đặt thông báo
 * `560:2981`, EN08 mẫu nội dung `561:3011`).
 *
 * - Inbox `users/{uid}/notifications/{id}`: written only by Functions, once per push a server
 *   sender makes (one shared helper). It holds what the push showed (generic copy, R-120: no
 *   photo, caption or baby name) in both languages, ids for the deep link, and read / archived
 *   times. The owner may only set `readAt` / `archivedAt`. Kept 90 days.
 * - Settings `users/{uid}/settings/notifications`: per person, client-written, every key a bool;
 *   a missing key takes its default. Quiet hours and the suggestion time stay in
 *   `settings/personalization` (EN02, `userPreferencesSchema`): one source for both screens.
 */

// ---------- Settings (EN07) ----------

/**
 * EN07 switches. The first four predate EN07 (G-056) and keep their names; `vaccines` and
 * `spending` used to follow `reminders` and still do until set (see [notificationSettingsOf]).
 */
export const notificationSettingKeys = [
  // NHẮC VIỆC BẠN ĐẶT: "Bú, ngủ, thay tã" (rule and one-off reminders), "Tiêm chủng", Chi tiêu.
  'reminders',
  'vaccines',
  'spending',
  // GỢI Ý CHO BÉ (bundled, at most 2 a day).
  'rhythm',
  'stages',
  'milestones',
  'articles',
  'weeklySummary',
  // KỶ NIỆM & GIA ĐÌNH.
  'memories',
  'messages',
  'storage',
  'photoSuggestions',
  'keepsakePrompts',
  'familyActivity',
  // G-109 (D-092): someone joined, an invitation was declined.
  'familyMembers',
  // D-093: a family member sent this person a handover.
  'handovers',
  // D-094: show the baby's name in pushes (else "bé"). Not a kind switch.
  'babyName',
] as const;
export type NotificationSettingKey = (typeof notificationSettingKeys)[number];
export type NotificationSettings = Record<NotificationSettingKey, boolean>;

/** EN07 draws "Bài viết gợi ý" and "Hoạt động của gia đình" off; everything else on. */
export const defaultNotificationSettings: NotificationSettings = {
  reminders: true,
  vaccines: true,
  spending: true,
  rhythm: true,
  stages: true,
  milestones: true,
  articles: false,
  weeklySummary: true,
  memories: true,
  messages: true,
  storage: true,
  photoSuggestions: true,
  keepsakePrompts: true,
  familyActivity: false,
  familyMembers: true,
  handovers: true,
  babyName: true,
};

/** The stored document (Rules mirror it): any subset of the keys, plus `updatedAt`. */
export const notificationSettingsDocSchema = z
  .object({
    reminders: z.boolean().optional(),
    vaccines: z.boolean().optional(),
    spending: z.boolean().optional(),
    rhythm: z.boolean().optional(),
    stages: z.boolean().optional(),
    milestones: z.boolean().optional(),
    articles: z.boolean().optional(),
    weeklySummary: z.boolean().optional(),
    memories: z.boolean().optional(),
    messages: z.boolean().optional(),
    storage: z.boolean().optional(),
    photoSuggestions: z.boolean().optional(),
    keepsakePrompts: z.boolean().optional(),
    familyActivity: z.boolean().optional(),
    familyMembers: z.boolean().optional(),
    handovers: z.boolean().optional(),
    babyName: z.boolean().optional(),
    updatedAt: z.unknown().optional(),
  })
  .strict();

/** Settings with defaults; `vaccines` / `spending` follow `reminders` until set (G-056). */
export function notificationSettingsOf(doc: Record<string, unknown> | null | undefined) {
  const out = { ...defaultNotificationSettings };
  for (const k of notificationSettingKeys) {
    const v = doc?.[k];
    if (typeof v === 'boolean') out[k] = v;
  }
  if (typeof doc?.vaccines !== 'boolean') out.vaccines = out.reminders;
  if (typeof doc?.spending !== 'boolean') out.spending = out.reminders;
  return out;
}

// ---------- Kinds, categories, deep links ----------

/** Every kind a server push carries in `data.kind` (and the inbox keeps). */
export const notificationKinds = [
  'reminderRule',
  'vaccine',
  'spending',
  'memories',
  'shared',
  'album',
  'story',
  'message',
  'storage',
  'storageGranted',
  'keepsakeVideo',
  'keepsakeVideoFailed',
  // EN08 suggestion pushes (no server sender yet; settings are kept for them).
  'rhythm',
  'stage',
  'milestone',
  'article',
  'weeklySummary',
  'photoSuggestion',
  'keepsakePrompt',
  'familyActivity',
  // A push sent by engineering to check delivery (D-076 #2).
  'test',
  // G-109 (D-092): family membership events.
  'memberJoined',
  'inviteDeclined',
  'roleChanged',
  'memberRemoved',
  // D-093: "Gửi cho Jun" — a handover sent to one member.
  'handoverSent',
  // D-135 N1: a Cùng Chăm Con task of this person is due soon.
  'careTaskDue',
  // D-136 N5: the morning draft of the day's plan is ready (plan managers).
  'carePlanReady',
  // Cùng Chăm Con N2: someone else finished a task ("Teddy no bụng rồi, nhờ có Mẹ đó!").
  'careTaskDone',
  // Cùng Chăm Con N3: a heart or thanks for a task this person did ("Mẹ thả tim cho Ba").
  'careThanks',
] as const;
export type NotificationKind = (typeof notificationKinds)[number];

/** EN06 chips: Nhắc việc · Cho bé · Gia đình; `general` shows under "Tất cả" only. */
export const notificationCategories = ['reminders', 'baby', 'family', 'general'] as const;
export type NotificationCategory = (typeof notificationCategories)[number];

export const notificationCategoryOf: Record<NotificationKind, NotificationCategory> = {
  reminderRule: 'reminders',
  vaccine: 'reminders',
  spending: 'reminders',
  memories: 'family',
  shared: 'family',
  album: 'family',
  story: 'family',
  message: 'family',
  storage: 'family',
  storageGranted: 'family',
  keepsakeVideo: 'family',
  keepsakeVideoFailed: 'family',
  rhythm: 'baby',
  stage: 'baby',
  milestone: 'baby',
  article: 'baby',
  weeklySummary: 'baby',
  photoSuggestion: 'family',
  keepsakePrompt: 'family',
  familyActivity: 'family',
  test: 'general',
  memberJoined: 'family',
  inviteDeclined: 'family',
  roleChanged: 'family',
  memberRemoved: 'family',
  handoverSent: 'family',
  careTaskDue: 'reminders',
  carePlanReady: 'reminders',
  careTaskDone: 'family',
  careThanks: 'family',
};

/**
 * The switch that silences a kind (no push and no inbox entry). Null: always delivered — the
 * answer to something this person asked for (a video, more storage) or the delivery check.
 */
export const notificationSettingOf: Record<NotificationKind, NotificationSettingKey | null> = {
  reminderRule: 'reminders',
  vaccine: 'vaccines',
  spending: 'spending',
  memories: 'memories',
  shared: 'memories',
  album: 'memories',
  story: 'memories',
  message: 'messages',
  storage: 'storage',
  storageGranted: null,
  keepsakeVideo: null,
  keepsakeVideoFailed: null,
  rhythm: 'rhythm',
  stage: 'stages',
  milestone: 'milestones',
  article: 'articles',
  weeklySummary: 'weeklySummary',
  photoSuggestion: 'photoSuggestions',
  keepsakePrompt: 'keepsakePrompts',
  familyActivity: 'familyActivity',
  test: null,
  memberJoined: 'familyMembers',
  inviteDeclined: 'familyMembers',
  // About the person's own access: always delivered.
  roleChanged: null,
  memberRemoved: null,
  handoverSent: 'handovers',
  // "Nhắc trước · Tắt" in the person's Cùng Chăm Con settings (`users/{uid}/settings/carePlan`)
  // is its switch: the producer does not send to someone who turned it off.
  careTaskDue: null,
  // The family's "Tự tạo lịch mỗi sáng" (`carePlanSettings/family.autoDraft`) is its switch.
  carePlanReady: null,
  // "Khi người khác làm xong" in the person's Cùng Chăm Con settings (`settings/carePlan.team`)
  // is the switch for both: the producer does not send to someone who turned it off.
  careTaskDone: null,
  careThanks: null,
};

/**
 * Reminders the person set ring on time even in quiet hours (EN07 "Luôn đến đúng giờ"). Care
 * tasks (D-135 Q5) ring by default; each person may hold them (`settings/carePlan.quietHours`).
 */
export function ringsInQuietHours(kind: NotificationKind): boolean {
  return kind === 'reminderRule' || kind === 'vaccine' || kind === 'careTaskDue';
}

/** Where tapping an inbox row (or its push) goes; ids travel in `data`. */
export const notificationRoutes = [
  'ruleReminder',
  'vaccine',
  'spending',
  'memories',
  'keepsakeJob',
  'inbox',
] as const;
export type NotificationRoute = (typeof notificationRoutes)[number];

export function notificationRouteOf(kind: NotificationKind): NotificationRoute {
  switch (kind) {
    case 'reminderRule':
      return 'ruleReminder';
    case 'vaccine':
      return 'vaccine';
    case 'spending':
      return 'spending';
    case 'keepsakeVideo':
    case 'keepsakeVideoFailed':
      return 'keepsakeJob';
    case 'memories':
    case 'shared':
    case 'album':
    case 'story':
    case 'message':
    case 'storage':
    case 'storageGranted':
      return 'memories';
    default:
      return 'inbox';
  }
}

// ---------- Inbox item ----------

export const INBOX_RETENTION_DAYS = 90;

const localizedLine = z.object({
  vi: z.string().min(1).max(240),
  en: z.string().min(1).max(240),
});

/** Ids only (the push `data`): never a name, caption or care value. */
const linkData = z
  .record(
    z.string().regex(/^[A-Za-z][A-Za-z0-9]{0,31}$/),
    z
      .string()
      .max(200)
      .regex(/^[^\n]*$/),
  )
  .refine((d) => Object.keys(d).length <= 16, 'too many keys');

/** `users/{uid}/notifications/{id}` as Functions write it (timestamps as Date on the server). */
export const inboxItemSchema = z
  .object({
    kind: z.enum(notificationKinds),
    category: z.enum(notificationCategories),
    title: localizedLine,
    body: localizedLine,
    route: z.enum(notificationRoutes),
    babyId: z.string().min(1).max(64).nullable(),
    data: linkData,
    /** False when quiet hours held the push back, or no device had a token. */
    pushed: z.boolean(),
    createdAt: z.date(),
    readAt: z.date().nullable(),
    archivedAt: z.date().nullable(),
    expireAt: z.date(),
    // P-174 (optional: rows written before the unified platform lack them).
    /** Semantic destination id (`notificationDestinations`); the app's resolver opens it. */
    destination: z
      .string()
      .regex(/^[A-Z_]{4,40}$/)
      .optional(),
    /** Inbox chip (`inboxGroups`). */
    group: z.enum(['memories', 'family', 'care', 'other']).optional(),
    templateId: z.string().max(40).nullable().optional(),
    templateVersion: z.number().int().min(0).optional(),
    /** The server-only ledger entry (`notificationDeliveries/{id}`); an opaque hash. */
    ledgerId: z
      .string()
      .regex(/^d_[a-f0-9]{40}$/)
      .optional(),
  })
  .strict();
export type InboxItem = z.infer<typeof inboxItemSchema>;

export const inboxIdSchema = z.string().regex(/^n_[A-Za-z0-9_-]{6,120}$/);

// ---------- Quiet hours ----------

const hhmm = /^([01]\d|2[0-3]):[0-5]\d$/;

/** "HH:mm" of [now] in [zone]. */
export function localClockIn(zone: string, now: Date): string {
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: zone,
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(now);
  const get = (t: string) => parts.find((p) => p.type === t)?.value ?? '00';
  return `${get('hour')}:${get('minute')}`;
}

/** True when [now] in [zone] falls in [quiet] ("22:00"–"06:00" wraps midnight; from == to = off). */
export function inQuietHours(
  quiet: { from: string; to: string } | null | undefined,
  zone: string,
  now: Date,
): boolean {
  if (!quiet || !hhmm.test(quiet.from) || !hhmm.test(quiet.to) || quiet.from === quiet.to) {
    return false;
  }
  const t = localClockIn(zone, now);
  return quiet.from < quiet.to ? t >= quiet.from && t < quiet.to : t >= quiet.from || t < quiet.to;
}

// ---------- EN08 copy (no baby name, R-120) ----------

/**
 * EN08 templates for the suggestion pushes, without the baby's name (R-120): "bé" stands in for
 * "Teddy". No server sender uses them yet; vaccine reminders carry the EN08 line in
 * `vaccineCopy`.
 */
export const suggestionCopy = {
  rhythm: {
    vi: {
      title: 'Bé sắp đến một giai đoạn mới',
      body: 'Theo lịch tham khảo, có thể con cần được dỗ nhiều hơn. Xem gợi ý nhẹ nhàng.',
    },
    en: {
      title: 'A new phase may be coming',
      body: 'Per the reference calendar, your baby may need more soothing. See gentle tips.',
    },
  },
  milestone: {
    vi: {
      title: 'Mốc có thể thấy tuần này',
      body: 'Có một mốc thường gặp ở tuổi này. Ghi lại khi bé làm được nhé.',
    },
    en: {
      title: 'A milestone you may see this week',
      body: 'A milestone is common at this age. Note it when your baby does it.',
    },
  },
  weeklySummary: {
    vi: { title: 'Tóm tắt tuần của bé', body: 'Xem tuần qua của cả nhà.' },
    en: { title: 'Your weekly summary', body: 'See the family’s past week.' },
  },
} as const;
