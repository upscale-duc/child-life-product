import { z } from 'zod';
import {
  notificationCategoryOf,
  notificationKinds,
  notificationSettingOf,
  ringsInQuietHours,
  type NotificationKind,
  type NotificationSettingKey,
} from './notifications.js';

/**
 * Unified notification platform (P-174, docs/notifications/). One catalog of every notification
 * type, one semantic destination registry shared by the server, the Portal and the app, four
 * independent lifecycle dimensions, Portal-managed VI/EN templates with immutable versions, and the
 * shape of the server-only delivery ledger.
 *
 * Nothing here changes who receives what: `notifyUsers` (Functions) stays the single writer of the
 * inbox. Smart Engagement (ENG-00–06) is a producer on top of it, never a second pipeline.
 */

// ---------- Inbox groups (the app's chips) ----------

/** Chips of the in-app Notification Center: Tất cả · Kỷ niệm · Gia đình · Chăm sóc · Khác. */
export const inboxGroups = ['memories', 'family', 'care', 'other'] as const;
export type InboxGroup = (typeof inboxGroups)[number];

// ---------- Destinations ----------

export const notificationDestinationIds = [
  'CARE_RULE_REMINDER',
  'CARE_REMINDERS',
  'CARE_VACCINES',
  'SPENDING',
  'SPENDING_IMPORT',
  'MEMORIES',
  'MEMORIES_ALBUM',
  'MEMORIES_STORY',
  'MEMORIES_VIDEO_JOB',
  'MEMORIES_PENDING_REVIEW',
  'MEMORIES_KEEPSAKE_SUGGESTION',
  'MEMORIES_WEEKLY_RECAP',
  'FAMILY_MESSAGES',
  'FAMILY_SHARED_CONTENT',
  'FAMILY_STORAGE',
  'LUMI_INSIGHT',
  'INBOX',
] as const;
export type NotificationDestinationId = (typeof notificationDestinationIds)[number];

/** What the app checks before it navigates (the server checked again when it wrote the row). */
export type DestinationPermission =
  | 'signed_in'
  /** Current member of the baby the row names. */
  | 'member'
  /** Member who may read the baby's care (coParent, caregiver; relatives with daily care). */
  | 'care_read'
  /** Member who may see family Memories (coParent, relative). */
  | 'memories_read'
  /** coParent of the baby. */
  | 'co_parent'
  /** The engagement link is re-authorised by `actOnEngagement` on the server. */
  | 'engagement_server';

export interface DestinationParam {
  key: string;
  pattern: RegExp;
  required: boolean;
}

export interface NotificationDestination {
  id: NotificationDestinationId;
  /** Shown in the Portal ("Màn hình"). */
  screen: { vi: string; en: string };
  /** The app path; `:param` segments are filled from validated params. */
  path: string;
  params: readonly DestinationParam[];
  permission: DestinationPermission;
  /** Where the app goes when the target is gone, not allowed or the app is too old. */
  fallback: NotificationDestinationId | null;
  /** What "the intended action" means for this destination; `none` = opening is the point. */
  completion: { vi: string; en: string } | null;
}

const babyId: DestinationParam = {
  key: 'babyId',
  pattern: /^[A-Za-z0-9_-]{1,128}$/,
  required: true,
};
const engagementId: DestinationParam = {
  key: 'engagementId',
  pattern: /^[a-f0-9]{64}$/,
  required: true,
};
const t = (vi: string, en: string) => ({ vi, en });

export const notificationDestinations: Record<NotificationDestinationId, NotificationDestination> =
  {
    CARE_RULE_REMINDER: {
      id: 'CARE_RULE_REMINDER',
      screen: t('Nhắc việc theo quy tắc (mở thẻ nhắc)', 'Rule reminder (opens the reminder card)'),
      path: '/care/reminders/rules',
      params: [
        babyId,
        { key: 'ruleId', pattern: /^[A-Za-z0-9_-]{1,128}$/, required: true },
        { key: 'dueAt', pattern: /^\d{10,14}$/, required: false },
      ],
      permission: 'care_read',
      fallback: 'CARE_REMINDERS',
      completion: t(
        'Ghi lần chăm sóc, báo lại hoặc bỏ qua lần nhắc',
        'Log the care, snooze or skip this occurrence',
      ),
    },
    CARE_REMINDERS: {
      id: 'CARE_REMINDERS',
      screen: t('Nhắc nhở', 'Reminders'),
      path: '/care/reminders',
      params: [babyId],
      permission: 'care_read',
      fallback: 'INBOX',
      completion: null,
    },
    CARE_VACCINES: {
      id: 'CARE_VACCINES',
      screen: t('Sổ tiêm chủng', 'Vaccination book'),
      path: '/care/vaccines',
      params: [babyId, { key: 'date', pattern: /^\d{4}-\d{2}-\d{2}$/, required: false }],
      permission: 'care_read',
      fallback: 'INBOX',
      completion: t('Ghi nhận mũi tiêm', 'Record the dose'),
    },
    SPENDING: {
      id: 'SPENDING',
      screen: t('Chi tiêu', 'Spending'),
      path: '/utilities/spending',
      params: [babyId],
      permission: 'co_parent',
      fallback: 'INBOX',
      completion: null,
    },
    SPENDING_IMPORT: {
      id: 'SPENDING_IMPORT',
      screen: t('Kết quả nhập chi tiêu', 'Spending import result'),
      path: '/utilities/spending/import/:importId',
      params: [babyId, { key: 'importId', pattern: /^im_[a-f0-9]{32}$/, required: true }],
      permission: 'co_parent',
      fallback: 'SPENDING',
      completion: null,
    },
    MEMORIES: {
      id: 'MEMORIES',
      screen: t('Kỷ niệm', 'Memories'),
      path: '/memories',
      params: [babyId],
      permission: 'member',
      fallback: 'INBOX',
      completion: null,
    },
    MEMORIES_ALBUM: {
      id: 'MEMORIES_ALBUM',
      screen: t('Album', 'Album'),
      path: '/memories/album/:albumId',
      params: [babyId, { key: 'albumId', pattern: /^[A-Za-z0-9_-]{1,128}$/, required: true }],
      permission: 'memories_read',
      fallback: 'MEMORIES',
      completion: null,
    },
    MEMORIES_STORY: {
      id: 'MEMORIES_STORY',
      screen: t('Câu chuyện', 'Story'),
      path: '/story/:storyId',
      params: [babyId, { key: 'storyId', pattern: /^[A-Za-z0-9_-]{1,128}$/, required: true }],
      permission: 'memories_read',
      fallback: 'MEMORIES',
      completion: null,
    },
    MEMORIES_VIDEO_JOB: {
      id: 'MEMORIES_VIDEO_JOB',
      screen: t('Video kỷ niệm (kết quả)', 'Memory video (result)'),
      path: '/memories/video/job/:jobId',
      params: [babyId, { key: 'jobId', pattern: /^ksj_[a-f0-9]{32}$/, required: true }],
      permission: 'member',
      fallback: 'MEMORIES',
      completion: t('Xem, lưu hoặc chia sẻ video', 'Watch, save or share the video'),
    },
    MEMORIES_PENDING_REVIEW: {
      id: 'MEMORIES_PENDING_REVIEW',
      screen: t('Tự lưu · Ảnh chờ chọn', 'Auto Save · Pending review'),
      path: '/memories/auto-save/review',
      params: [babyId, engagementId],
      permission: 'engagement_server',
      fallback: 'MEMORIES',
      completion: t(
        'Ảnh đã duyệt được tải lên và sẵn sàng trên cloud',
        'Approved photos uploaded and cloud-ready',
      ),
    },
    MEMORIES_KEEPSAKE_SUGGESTION: {
      id: 'MEMORIES_KEEPSAKE_SUGGESTION',
      screen: t('Gợi ý video kỷ niệm theo mốc', 'Milestone keepsake suggestion'),
      path: '/memories/video',
      params: [babyId, engagementId],
      permission: 'engagement_server',
      fallback: 'MEMORIES',
      completion: t('Video kỷ niệm được tạo xong', 'Keepsake video completed'),
    },
    MEMORIES_WEEKLY_RECAP: {
      id: 'MEMORIES_WEEKLY_RECAP',
      screen: t('Nhìn lại tuần', 'Weekly recap'),
      path: '/memories',
      params: [babyId, engagementId],
      permission: 'engagement_server',
      fallback: 'MEMORIES',
      completion: t('Xem nội dung của tuần', 'View the week’s content'),
    },
    FAMILY_MESSAGES: {
      id: 'FAMILY_MESSAGES',
      screen: t('Lời nhắn gia đình', 'Family messages'),
      path: '/messages',
      params: [babyId],
      permission: 'co_parent',
      fallback: 'INBOX',
      completion: null,
    },
    FAMILY_SHARED_CONTENT: {
      id: 'FAMILY_SHARED_CONTENT',
      screen: t('Cập nhật gia đình (gom nhóm)', 'Family updates (grouped)'),
      path: '/memories',
      params: [babyId, engagementId],
      permission: 'engagement_server',
      fallback: 'MEMORIES',
      completion: t('Xem nội dung được chia sẻ', 'View the shared content'),
    },
    FAMILY_STORAGE: {
      id: 'FAMILY_STORAGE',
      screen: t('Dung lượng gia đình', 'Family storage'),
      path: '/me/storage',
      params: [],
      permission: 'signed_in',
      fallback: 'INBOX',
      completion: null,
    },
    LUMI_INSIGHT: {
      id: 'LUMI_INSIGHT',
      screen: t('Gợi ý cá nhân hoá trong ngày', 'Personal day suggestion'),
      path: '/rhythm/day',
      params: [babyId, engagementId],
      permission: 'engagement_server',
      fallback: 'INBOX',
      completion: t('Xem gợi ý nguồn', 'View the source suggestion'),
    },
    INBOX: {
      id: 'INBOX',
      screen: t('Hộp thông báo', 'Notification Center'),
      path: '/notifications',
      params: [],
      permission: 'signed_in',
      fallback: null,
      completion: null,
    },
  };

/** Params of [destination] taken from [data]; null when a required one is missing or malformed. */
export function destinationParams(
  destination: NotificationDestinationId,
  data: Record<string, string>,
): Record<string, string> | null {
  const out: Record<string, string> = {};
  for (const p of notificationDestinations[destination].params) {
    const v = data[p.key];
    if (v === undefined || v === '') {
      if (p.required) return null;
      continue;
    }
    if (!p.pattern.test(v)) return null;
    out[p.key] = v;
  }
  return out;
}

/** The chain the app walks when a destination cannot open: itself, its fallback, … INBOX. */
export function destinationChain(id: NotificationDestinationId): NotificationDestinationId[] {
  const chain: NotificationDestinationId[] = [];
  let next: NotificationDestinationId | null = id;
  while (next && !chain.includes(next)) {
    chain.push(next);
    next = notificationDestinations[next].fallback;
  }
  return chain;
}

// ---------- Catalog ----------

export const notificationProducers = [
  'care.rules',
  'care.vaccines',
  'spending',
  'spending.import',
  'memories.batch',
  'memories.share',
  'memories.keepsake',
  'family.messages',
  'family.storage',
  'staff.storage',
  'engagement',
  'engineering',
] as const;
export type NotificationProducer = (typeof notificationProducers)[number];

export type NotificationPriority = 'time_sensitive' | 'transactional' | 'informational';

export interface NotificationTypeDef {
  kind: NotificationKind;
  group: InboxGroup;
  producer: NotificationProducer;
  /** Plain-language trigger, shown in the Portal catalog. */
  trigger: { vi: string; en: string };
  recipients: { vi: string; en: string };
  priority: NotificationPriority;
  templates: readonly NotificationTemplateId[];
  /** Default destination (some producers pick a narrower one per row, e.g. album / story). */
  destination: NotificationDestinationId;
  /** EN07 switch; null = always delivered (answer to the person's own request). */
  setting: NotificationSettingKey | null;
  quietHours: 'held' | 'rings';
  /** How the producer makes the same event write once (the ledger key adds the recipient). */
  dedup: { vi: string; en: string };
  /** `transactional`: the row is the result itself. ENG kinds carry an action lifecycle. */
  action: 'none' | 'engagement' | 'care_occurrence';
  /** Smart Engagement scenario the kind is used by (ENG-04 rides the Care reminder). */
  engagement: readonly ('ENG-01' | 'ENG-02' | 'ENG-03' | 'ENG-04' | 'ENG-05' | 'ENG-06')[];
  /** In V1 a producer exists and sends; `reserved` kinds have none (kept for settings / old rows). */
  status: 'live' | 'reserved';
}

const both = (vi: string, en: string) => ({ vi, en });

export const notificationTypes: Record<NotificationKind, NotificationTypeDef> = {
  reminderRule: {
    kind: 'reminderRule',
    group: 'care',
    producer: 'care.rules',
    trigger: both(
      'Mỗi phút: quy tắc nhắc đến giờ (sau lần ghi gần nhất hoặc giờ cố định)',
      'Every minute: a rule reminder comes due (after last log or fixed time)',
    ),
    recipients: both(
      'Người nhận đã chọn trong quy tắc, còn là Cùng nuôi / Người chăm sóc',
      'The rule’s chosen recipients who are still co-parents / caregivers',
    ),
    priority: 'time_sensitive',
    templates: ['care.rule_due'],
    destination: 'CARE_RULE_REMINDER',
    setting: 'reminders',
    quietHours: 'rings',
    dedup: both(
      'Giao dịch dời nextDueAt trước khi gửi; khoá = quy tắc + giờ đến hạn',
      'Transaction moves nextDueAt before sending; key = rule + due time',
    ),
    action: 'care_occurrence',
    engagement: ['ENG-04'],
    status: 'live',
  },
  vaccine: {
    kind: 'vaccine',
    group: 'care',
    producer: 'care.vaccines',
    trigger: both(
      '3 ngày trước, tối hôm trước và sáng ngày tiêm dự kiến',
      '3 days before, the evening before and the morning of a planned dose',
    ),
    recipients: both(
      'Cùng nuôi và Người chăm sóc (hoặc người nhận đã chọn)',
      'Co-parents and caregivers (or the chosen recipients)',
    ),
    priority: 'time_sensitive',
    templates: ['care.vaccine_3d', 'care.vaccine_eve', 'care.vaccine_morning'],
    destination: 'CARE_VACCINES',
    setting: 'vaccines',
    quietHours: 'rings',
    dedup: both(
      'Mốc babies/{id}/vaccineReminders/{ngày}_{loại} tạo một lần',
      'Marker babies/{id}/vaccineReminders/{date}_{kind} created once',
    ),
    action: 'none',
    engagement: [],
    status: 'live',
  },
  spending: {
    kind: 'spending',
    group: 'care',
    producer: 'spending',
    trigger: both(
      'Khoản định kỳ được thêm (00:30), chi tiêu chạm 80% ngân sách, nhập chi tiêu xong / lỗi',
      'Recurring items added (00:30), spending reaches 80% of the budget, an import finishes / fails',
    ),
    recipients: both('Cùng nuôi (nhập: người nhập)', 'Co-parents (import: the importer)'),
    priority: 'transactional',
    templates: [
      'spending.recurring',
      'spending.budget80',
      'spending.import_done',
      'spending.import_failed',
    ],
    destination: 'SPENDING',
    setting: 'spending',
    quietHours: 'held',
    dedup: both(
      'Định kỳ: một lần mỗi ngày; ngân sách: alertedMonth; nhập: một lần mỗi kết quả',
      'Recurring: once a day; budget: alertedMonth; import: once per outcome',
    ),
    action: 'none',
    engagement: [],
    status: 'live',
  },
  memories: {
    kind: 'memories',
    group: 'memories',
    producer: 'memories.batch',
    trigger: both(
      'Một đợt tải ảnh/video của người thân đã xong',
      'A family member’s upload batch is complete',
    ),
    recipients: both(
      'Cùng nuôi và người thân, trừ người tải lên',
      'Co-parents and relatives, except the uploader',
    ),
    priority: 'informational',
    templates: ['memories.new_moments'],
    destination: 'MEMORIES',
    setting: 'memories',
    quietHours: 'held',
    dedup: both('Một thông báo mỗi đợt tải (batchId)', 'One notice per upload batch (batchId)'),
    action: 'none',
    engagement: ['ENG-05'],
    status: 'live',
  },
  shared: {
    kind: 'shared',
    group: 'memories',
    producer: 'memories.share',
    trigger: both(
      'Một khoảnh khắc được chia sẻ với gia đình',
      'A moment is shared with the family',
    ),
    recipients: both(
      'Cùng nuôi và người thân, trừ người chia sẻ',
      'Co-parents and relatives, except the sharer',
    ),
    priority: 'informational',
    templates: ['memories.new_moments'],
    destination: 'MEMORIES',
    setting: 'memories',
    quietHours: 'held',
    dedup: both('Một thông báo mỗi lần chia sẻ', 'One notice per share'),
    action: 'none',
    engagement: ['ENG-05'],
    status: 'live',
  },
  album: {
    kind: 'album',
    group: 'memories',
    producer: 'memories.share',
    trigger: both('Album được chia sẻ hoặc cập nhật', 'An album is shared or updated'),
    recipients: both(
      'Cùng nuôi và người thân, trừ người cập nhật',
      'Co-parents and relatives, except the editor',
    ),
    priority: 'informational',
    templates: ['memories.new_moments'],
    destination: 'MEMORIES_ALBUM',
    setting: 'memories',
    quietHours: 'held',
    dedup: both('Một thông báo mỗi lần cập nhật album', 'One notice per album update'),
    action: 'none',
    engagement: ['ENG-05'],
    status: 'live',
  },
  story: {
    kind: 'story',
    group: 'memories',
    producer: 'memories.share',
    trigger: both('Một câu chuyện mới được lưu', 'A new story is saved'),
    recipients: both(
      'Cùng nuôi và người thân, trừ người viết',
      'Co-parents and relatives, except the author',
    ),
    priority: 'informational',
    templates: ['memories.new_story'],
    destination: 'MEMORIES_STORY',
    setting: 'memories',
    quietHours: 'held',
    dedup: both('Một thông báo mỗi câu chuyện', 'One notice per story'),
    action: 'none',
    engagement: ['ENG-05'],
    status: 'live',
  },
  message: {
    kind: 'message',
    group: 'family',
    producer: 'family.messages',
    trigger: both('Người thân gửi “Nhắn ba mẹ”', 'A family member sends “Message the parents”'),
    recipients: both('Cùng nuôi, trừ người gửi', 'Co-parents, except the sender'),
    priority: 'transactional',
    templates: ['family.message'],
    destination: 'FAMILY_MESSAGES',
    setting: 'messages',
    quietHours: 'held',
    dedup: both('Một thông báo mỗi lời nhắn', 'One notice per message'),
    action: 'none',
    engagement: ['ENG-05'],
    status: 'live',
  },
  storage: {
    kind: 'storage',
    group: 'family',
    producer: 'family.storage',
    trigger: both(
      'Dung lượng gia đình vượt 80% / 95% / 100%',
      'Family storage passes 80% / 95% / 100%',
    ),
    recipients: both('Chủ gia đình và Cùng nuôi', 'Family owner and co-parents'),
    priority: 'transactional',
    templates: ['family.storage_almost_full', 'family.storage_full'],
    destination: 'FAMILY_STORAGE',
    setting: 'storage',
    quietHours: 'held',
    dedup: both('Một lần mỗi mức (storageNoticeState)', 'Once per level (storageNoticeState)'),
    action: 'none',
    engagement: [],
    status: 'live',
  },
  storageGranted: {
    kind: 'storageGranted',
    group: 'family',
    producer: 'staff.storage',
    trigger: both('Nhân viên duyệt thêm dung lượng', 'Staff grant more storage'),
    recipients: both('Ba mẹ của gia đình', 'The family’s parents'),
    priority: 'transactional',
    templates: ['family.storage_granted'],
    destination: 'FAMILY_STORAGE',
    setting: null,
    quietHours: 'held',
    dedup: both('Một lần mỗi yêu cầu', 'Once per request'),
    action: 'none',
    engagement: [],
    status: 'live',
  },
  keepsakeVideo: {
    kind: 'keepsakeVideo',
    group: 'memories',
    producer: 'memories.keepsake',
    trigger: both('Video kỷ niệm đã tạo xong', 'A memory video finished rendering'),
    recipients: both('Người yêu cầu video', 'The person who asked for the video'),
    priority: 'transactional',
    templates: ['memories.video_ready'],
    destination: 'MEMORIES_VIDEO_JOB',
    setting: null,
    quietHours: 'held',
    dedup: both('Một lần mỗi video (jobId)', 'Once per video (jobId)'),
    action: 'none',
    engagement: [],
    status: 'live',
  },
  keepsakeVideoFailed: {
    kind: 'keepsakeVideoFailed',
    group: 'memories',
    producer: 'memories.keepsake',
    trigger: both('Không tạo được video kỷ niệm', 'A memory video could not be made'),
    recipients: both('Người yêu cầu video', 'The person who asked for the video'),
    priority: 'transactional',
    templates: ['memories.video_failed'],
    destination: 'MEMORIES_VIDEO_JOB',
    setting: null,
    quietHours: 'held',
    dedup: both('Một lần mỗi lần thử (jobId + retries)', 'Once per attempt (jobId + retries)'),
    action: 'none',
    engagement: [],
    status: 'live',
  },
  rhythm: {
    kind: 'rhythm',
    group: 'other',
    producer: 'engagement',
    trigger: both(
      'ENG-06: gợi ý cá nhân hoá trong ngày đã có, đủ dữ liệu, đến giờ đã chọn',
      'ENG-06: an opted-in personal day suggestion is ready, data is sufficient, at the chosen time',
    ),
    recipients: both(
      'Người đã bật gợi ý, trên thiết bị được chọn',
      'The opted-in person, on the selected device',
    ),
    priority: 'informational',
    templates: ['eng.lumi_insight'],
    destination: 'LUMI_INSIGHT',
    setting: 'rhythm',
    quietHours: 'held',
    dedup: both('Mã ENG (sha-256), không bao giờ gửi lại', 'ENG id (sha-256), never resent'),
    action: 'engagement',
    engagement: ['ENG-06'],
    status: 'live',
  },
  stage: reserved('stage', 'stages'),
  milestone: reserved('milestone', 'milestones'),
  article: reserved('article', 'articles'),
  weeklySummary: {
    kind: 'weeklySummary',
    group: 'memories',
    producer: 'engagement',
    trigger: both(
      'ENG-03: tuần ISO đã đóng có kỷ niệm mới đã lưu',
      'ENG-03: a closed ISO week has newly saved memories',
    ),
    recipients: both('Người đã bật “Nhìn lại tuần”', 'The person who opted into weekly recap'),
    priority: 'informational',
    templates: ['eng.weekly_recap'],
    destination: 'MEMORIES_WEEKLY_RECAP',
    setting: 'weeklySummary',
    quietHours: 'held',
    dedup: both('Mã ENG theo tuần, không gửi lại', 'ENG id per week, never resent'),
    action: 'engagement',
    engagement: ['ENG-03'],
    status: 'live',
  },
  photoSuggestion: {
    kind: 'photoSuggestion',
    group: 'memories',
    producer: 'engagement',
    trigger: both(
      'ENG-01: ảnh tự lưu chờ chọn ≥ 24 giờ sau lần phát hiện đầu',
      'ENG-01: Auto Save photos pending review ≥ 24 h after first detection',
    ),
    recipients: both(
      'Cùng nuôi bật Tự lưu trên thiết bị có ảnh',
      'The Auto Save co-parent on the device with the photos',
    ),
    priority: 'informational',
    templates: ['eng.pending_photos'],
    destination: 'MEMORIES_PENDING_REVIEW',
    setting: 'photoSuggestions',
    quietHours: 'held',
    dedup: both('Mã ENG theo đợt chờ, không gửi lại', 'ENG id per review episode, never resent'),
    action: 'engagement',
    engagement: ['ENG-01'],
    status: 'live',
  },
  keepsakePrompt: {
    kind: 'keepsakePrompt',
    group: 'memories',
    producer: 'engagement',
    trigger: both(
      'ENG-02: mốc 1 tháng · 100 ngày · 6 tháng · 1 tuổi sắp đến (D−3 09:00), có ảnh và mẫu',
      'ENG-02: 1 month · 100 days · 6 months · 1 year is near (D−3 09:00), with photos and a template',
    ),
    recipients: both(
      'Một Cùng nuôi đã bật gợi ý (gần đây hoạt động Kỷ niệm nhất)',
      'One opted-in co-parent (most recent Memories activity)',
    ),
    priority: 'informational',
    templates: ['eng.keepsake_suggestion'],
    destination: 'MEMORIES_KEEPSAKE_SUGGESTION',
    setting: 'keepsakePrompts',
    quietHours: 'held',
    dedup: both(
      'Một lần mỗi mốc mỗi gia đình (engagementCampaigns)',
      'Once per milestone per family (engagementCampaigns)',
    ),
    action: 'engagement',
    engagement: ['ENG-02'],
    status: 'live',
  },
  familyActivity: {
    kind: 'familyActivity',
    group: 'family',
    producer: 'engagement',
    trigger: both(
      'ENG-05: các cập nhật gia đình chưa xem được gom trong 30 phút',
      'ENG-05: unseen family updates grouped over 30 minutes',
    ),
    recipients: both(
      'Người đã bật “Hoạt động gia đình”',
      'The person who opted into family activity',
    ),
    priority: 'informational',
    templates: ['eng.family_recap'],
    destination: 'FAMILY_SHARED_CONTENT',
    setting: 'familyActivity',
    quietHours: 'held',
    dedup: both('Mã ENG theo nhóm 30 phút', 'ENG id per 30-minute group'),
    action: 'engagement',
    engagement: ['ENG-05'],
    status: 'live',
  },
  test: {
    kind: 'test',
    group: 'other',
    producer: 'engineering',
    trigger: both('Kỹ sư kiểm tra đường gửi', 'Engineering delivery check'),
    recipients: both('Một tài khoản thử', 'One test account'),
    priority: 'informational',
    templates: [],
    destination: 'INBOX',
    setting: null,
    quietHours: 'held',
    dedup: both('Theo lần kiểm tra', 'Per check'),
    action: 'none',
    engagement: [],
    status: 'reserved',
  },
};

function reserved(kind: NotificationKind, setting: NotificationSettingKey): NotificationTypeDef {
  return {
    kind,
    group: 'other',
    producer: 'engagement',
    trigger: both(
      'Chưa có máy chủ gửi trong V1 (cài đặt EN07 được giữ)',
      'No server sender in V1 (the EN07 setting is kept)',
    ),
    recipients: both('—', '—'),
    priority: 'informational',
    templates: [],
    destination: 'INBOX',
    setting,
    quietHours: 'held',
    dedup: both('—', '—'),
    action: 'none',
    engagement: [],
    status: 'reserved',
  };
}

/** The app's chip for [kind]; unknown kinds (a newer server) show under "Khác". */
export function inboxGroupOf(kind: string): InboxGroup {
  return (
    (notificationTypes as Record<string, NotificationTypeDef | undefined>)[kind]?.group ?? 'other'
  );
}

/**
 * Family & account events that the brief lists but V1 does not push (they are email-only or not
 * sent). Shown in the Portal catalog so the owner sees the gap instead of a silent omission (G-109).
 */
export const notificationCatalogGaps = [
  {
    id: 'family.invite_received',
    group: 'family' as const,
    channel: 'email' as const,
    note: both(
      'Lời mời gửi qua email / liên kết; người nhận chưa có tài khoản nên không có push',
      'Invites go by email / link; the invitee has no account yet, so no push',
    ),
  },
  {
    id: 'family.invite_accepted',
    group: 'family' as const,
    channel: 'none' as const,
    note: both(
      'Chưa gửi trong V1 — cần quyết định của chủ sản phẩm (G-109)',
      'Not sent in V1 — needs an owner decision (G-109)',
    ),
  },
  {
    id: 'family.invite_declined',
    group: 'family' as const,
    channel: 'none' as const,
    note: both('Chưa gửi trong V1 (G-109)', 'Not sent in V1 (G-109)'),
  },
  {
    id: 'family.role_changed',
    group: 'family' as const,
    channel: 'none' as const,
    note: both('Chưa gửi trong V1 (G-109)', 'Not sent in V1 (G-109)'),
  },
  {
    id: 'family.member_removed',
    group: 'family' as const,
    channel: 'none' as const,
    note: both(
      'Chưa gửi trong V1; quyền truy cập mất ngay, thông báo cũ bị chặn khi mở',
      'Not sent in V1; access ends at once and old rows are blocked when opened',
    ),
  },
  {
    id: 'account.security',
    group: 'other' as const,
    channel: 'email' as const,
    note: both(
      'Email (xác minh, đặt lại mật khẩu, xoá tài khoản, chuyển quyền sở hữu)',
      'Email (verification, password reset, account deletion, ownership transfer)',
    ),
  },
] as const;

// ---------- Lifecycle (four independent dimensions) ----------

export const notificationLifecycleStates = [
  'created',
  'persisted',
  'cancelled',
  'expired',
] as const;
export type NotificationLifecycleState = (typeof notificationLifecycleStates)[number];

/**
 * Delivery: `accepted` means the push provider (FCM/APNs) accepted at least one token. It is never
 * proof that a device showed the notification.
 */
export const notificationDeliveryStates = [
  'pending',
  'scheduled',
  'attempted',
  'accepted',
  'rejected',
  'retry_pending',
  'failed',
  'cancelled',
  'unknown',
] as const;
export type NotificationDeliveryState = (typeof notificationDeliveryStates)[number];

export const notificationReadStates = ['unread', 'read'] as const;
export type NotificationReadState = (typeof notificationReadStates)[number];

export const notificationActionStates = [
  'none',
  'not_started',
  'started',
  'completed',
  'expired',
  'unavailable',
] as const;
export type NotificationActionState = (typeof notificationActionStates)[number];

/** Why delivery did not happen or ended where it did. */
export const notificationDeliveryReasons = [
  'none',
  'setting_off',
  'quiet_hours',
  'no_device',
  'no_sender',
  'kill_switch',
  'provider_rejected',
  'provider_error',
  'retry_exhausted',
  'ambiguous',
  'expired',
  'aborted',
  'staff_retry',
] as const;
export type NotificationDeliveryReason = (typeof notificationDeliveryReasons)[number];

const deliveryNext: Record<NotificationDeliveryState, readonly NotificationDeliveryState[]> = {
  pending: ['scheduled', 'attempted', 'cancelled', 'unknown'],
  scheduled: ['attempted', 'cancelled', 'unknown'],
  attempted: ['accepted', 'rejected', 'retry_pending', 'failed', 'unknown', 'cancelled'],
  retry_pending: ['attempted', 'failed', 'cancelled'],
  // A staff retry may reopen a failed row (never one that a provider accepted).
  failed: ['retry_pending'],
  accepted: [],
  rejected: [],
  cancelled: [],
  unknown: [],
};
const lifecycleNext: Record<NotificationLifecycleState, readonly NotificationLifecycleState[]> = {
  created: ['persisted', 'cancelled'],
  persisted: ['expired', 'cancelled'],
  cancelled: [],
  expired: [],
};
const actionNext: Record<NotificationActionState, readonly NotificationActionState[]> = {
  none: [],
  not_started: ['started', 'completed', 'expired', 'unavailable'],
  started: ['completed', 'expired', 'unavailable'],
  completed: [],
  expired: [],
  unavailable: [],
};

/** Stale workers and retries never move a dimension backwards or out of a terminal state. */
export function canTransition(
  dimension: 'lifecycle' | 'delivery' | 'read' | 'action',
  from: string,
  to: string,
): boolean {
  if (from === to) return false;
  switch (dimension) {
    case 'lifecycle':
      return (lifecycleNext[from as NotificationLifecycleState] ?? []).includes(
        to as NotificationLifecycleState,
      );
    case 'delivery':
      return (deliveryNext[from as NotificationDeliveryState] ?? []).includes(
        to as NotificationDeliveryState,
      );
    case 'read':
      return from === 'unread' && to === 'read';
    case 'action':
      return (actionNext[from as NotificationActionState] ?? []).includes(
        to as NotificationActionState,
      );
  }
}

export function deliveryIsTerminal(state: NotificationDeliveryState): boolean {
  return deliveryNext[state].length === 0;
}

/** Retry policy for transient provider errors (not for ENG, whose ambiguous sends never retry). */
export const NOTIFICATION_MAX_ATTEMPTS = 3;
export function retryDelayMs(attempt: number): number {
  return [60_000, 5 * 60_000, 30 * 60_000][Math.min(Math.max(attempt - 1, 0), 2)]!;
}

// ---------- Ledger (server-only) ----------

export const NOTIFICATION_LEDGER_RETENTION_DAYS = 120;

/** What one ledger entry (`notificationDeliveries/{id}`) records; Functions write, Rules deny. */
export interface NotificationLedgerEntry {
  v: 1;
  uid: string;
  familyId: string | null;
  babyId: string | null;
  kind: NotificationKind;
  group: InboxGroup;
  producer: NotificationProducer;
  templateId: NotificationTemplateId | null;
  /** 0 = the built-in copy in code; n = the Portal-published version n. */
  templateVersion: number;
  destination: NotificationDestinationId;
  dedupKey: string;
  inboxId: string | null;
  correlationId: string;
  engagementId: string | null;
  engagementKind: string | null;
  lifecycle: NotificationLifecycleState;
  delivery: NotificationDeliveryState;
  deliveryReason: NotificationDeliveryReason;
  read: NotificationReadState;
  action: NotificationActionState;
  attempts: number;
  nextAttemptAt: Date | null;
  acceptedTokens: number;
  rejectedTokens: number;
  devices: number;
  createdAt: Date;
  persistedAt: Date | null;
  attemptedAt: Date | null;
  acceptedAt: Date | null;
  failedAt: Date | null;
  readAt: Date | null;
  openedAt: Date | null;
  openSurface: 'push' | 'inbox' | null;
  navigation: 'navigated' | 'fallback' | 'unavailable' | null;
  navigatedAt: Date | null;
  actionAt: Date | null;
  pushExpiresAt: Date | null;
  errorCode: string | null;
  deleteAfter: Date;
}

/** Stat counters on `notificationStatsDaily/{yyyy-mm-dd}` (Vietnam day), per kind and template. */
export const notificationStatMetrics = [
  'created',
  'muted',
  'inbox',
  'held',
  'no_device',
  'cancelled',
  'attempted',
  'accepted',
  'rejected',
  'retry',
  'failed',
  'unknown',
  'read',
  'opened',
  'opened_push',
  'opened_inbox',
  'navigated',
  'fallback',
  'unavailable',
  'action_completed',
  'render_error',
] as const;
export type NotificationStatMetric = (typeof notificationStatMetrics)[number];

// ---------- Templates ----------

export const notificationTemplateIds = [
  'care.rule_due',
  'care.vaccine_3d',
  'care.vaccine_eve',
  'care.vaccine_morning',
  'spending.recurring',
  'spending.budget80',
  'spending.import_done',
  'spending.import_failed',
  'memories.new_moments',
  'memories.new_story',
  'memories.video_ready',
  'memories.video_failed',
  'family.message',
  'family.storage_almost_full',
  'family.storage_full',
  'family.storage_granted',
  'eng.pending_photos',
  'eng.keepsake_suggestion',
  'eng.weekly_recap',
  'eng.family_recap',
  'eng.lumi_insight',
] as const;
export type NotificationTemplateId = (typeof notificationTemplateIds)[number];

/**
 * Approved placeholders. A value is either a number or a per-language string the producer
 * computes; staff can place them, never define new ones. No child name, DOB, caption, care value
 * or free text from a user is ever a placeholder (R-120); `actor_name` is the family member's own
 * display name, as R-120's drawn copy shows ("Mai vừa chia sẻ…").
 */
export const notificationPlaceholders = {
  count: {
    type: 'number',
    sensitivity: 'safe',
    fallback: '1',
    maxLength: 6,
    description: both('Số lượng (khoảnh khắc, khoản…)', 'A count (moments, items…)'),
  },
  pending_count: {
    type: 'number',
    sensitivity: 'safe',
    fallback: '',
    maxLength: 6,
    description: both('Số ảnh đang chờ chọn', 'Photos waiting for review'),
  },
  percent: {
    type: 'number',
    sensitivity: 'safe',
    fallback: '80',
    maxLength: 3,
    description: both('Phần trăm dung lượng đã dùng', 'Percent of storage used'),
  },
  gb: {
    type: 'number',
    sensitivity: 'safe',
    fallback: '',
    maxLength: 5,
    description: both('Số GB được thêm', 'GB added'),
  },
  actor_name: {
    type: 'text',
    sensitivity: 'member_name',
    fallback: both('Người thân', 'A family member'),
    maxLength: 40,
    description: both(
      'Tên hiển thị của người thân đã làm việc này',
      'Display name of the family member who did it',
    ),
  },
  activity_name: {
    type: 'text',
    sensitivity: 'safe',
    fallback: both('nhắc việc', 'reminder'),
    maxLength: 30,
    description: both('Tên hoạt động (bú, ngủ, thay tã…)', 'Activity name (feed, sleep, diaper…)'),
  },
  last_logged_line: {
    type: 'text',
    sensitivity: 'safe',
    fallback: both('Chưa có lần ghi nào gần đây', 'Nothing logged recently'),
    maxLength: 80,
    description: both(
      'Dòng “Lần bú gần nhất 11:45 · 3 giờ trước”',
      'Line “Last feed 11:45 · 3 h ago”',
    ),
  },
  dose_list: {
    type: 'text',
    sensitivity: 'safe',
    fallback: both('Mũi tiêm sắp tới', 'Upcoming dose'),
    maxLength: 120,
    description: both('Tên vắc xin và mũi', 'Vaccine names and doses'),
  },
  age_label: {
    type: 'text',
    sensitivity: 'safe',
    fallback: '',
    maxLength: 40,
    description: both('Mốc tuổi (“Mốc 2 tháng tuổi”)', 'Age milestone (“2-month milestone”)'),
  },
  import_summary: {
    type: 'text',
    sensitivity: 'safe',
    fallback: '',
    maxLength: 120,
    description: both('Tóm tắt kết quả nhập (số dòng)', 'Import result summary (row counts)'),
  },
  milestone_label: {
    type: 'text',
    sensitivity: 'safe',
    fallback: both('mốc đáng nhớ', 'a special milestone'),
    maxLength: 40,
    description: both('Tên mốc (1 tháng, 100 ngày…)', 'Milestone name (1 month, 100 days…)'),
  },
} as const;
export type NotificationPlaceholder = keyof typeof notificationPlaceholders;
export type PlaceholderValue = number | string | { vi: string; en: string };

export interface TemplateCopy {
  title: string;
  body: string;
}
export interface LocalizedTemplateCopy {
  vi: TemplateCopy;
  en: TemplateCopy;
}

export interface NotificationTemplateDef {
  id: NotificationTemplateId;
  kind: NotificationKind;
  name: { vi: string; en: string };
  placeholders: readonly NotificationPlaceholder[];
  /** Placeholders a published version must keep (the copy loses its meaning without them). */
  required: readonly NotificationPlaceholder[];
  /** The copy in code (template version 0). Rendering it with the producer's values gives today's push. */
  builtin: LocalizedTemplateCopy;
  sample: Partial<Record<NotificationPlaceholder, PlaceholderValue>>;
}

const tpl = (
  id: NotificationTemplateId,
  kind: NotificationKind,
  name: [string, string],
  placeholders: readonly NotificationPlaceholder[],
  builtin: LocalizedTemplateCopy,
  sample: NotificationTemplateDef['sample'] = {},
  required: readonly NotificationPlaceholder[] = [],
): NotificationTemplateDef => ({
  id,
  kind,
  name: both(name[0], name[1]),
  placeholders,
  required,
  builtin,
  sample,
});

export const notificationTemplates: Record<NotificationTemplateId, NotificationTemplateDef> = {
  'care.rule_due': tpl(
    'care.rule_due',
    'reminderRule',
    ['Nhắc việc đến giờ', 'Rule reminder due'],
    ['activity_name', 'last_logged_line'],
    {
      vi: { title: 'Đến giờ {{activity_name}} bạn đã đặt', body: '{{last_logged_line}}' },
      en: { title: 'Time for the {{activity_name}} you set', body: '{{last_logged_line}}' },
    },
    {
      activity_name: both('nhắc bú', 'feeding reminder'),
      last_logged_line: both('Lần bú gần nhất 11:45 · 3 giờ trước', 'Last feed 11:45 · 3 h ago'),
    },
    ['activity_name'],
  ),
  'care.vaccine_3d': tpl(
    'care.vaccine_3d',
    'vaccine',
    ['Lịch tiêm sau 3 ngày', 'Vaccination in 3 days'],
    ['dose_list', 'age_label'],
    {
      vi: { title: 'Còn 3 ngày đến lịch tiêm của bé', body: '{{dose_list}} · {{age_label}}' },
      en: { title: 'A vaccination is due in 3 days', body: '{{dose_list}} · {{age_label}}' },
    },
    {
      dose_list: both('6in1 · Rota (mũi 1)', '6in1 · Rota (dose 1)'),
      age_label: both('Mốc 2 tháng tuổi', '2-month milestone'),
    },
    ['dose_list'],
  ),
  'care.vaccine_eve': tpl(
    'care.vaccine_eve',
    'vaccine',
    ['Lịch tiêm ngày mai', 'Vaccination tomorrow'],
    ['dose_list', 'age_label'],
    {
      vi: {
        title: 'Ngày mai có lịch tiêm của bé',
        body: '{{dose_list}} · {{age_label}}. Nhớ mang sổ tiêm và một chiếc khăn mỏng.',
      },
      en: {
        title: 'A vaccination is due tomorrow',
        body: '{{dose_list}} · {{age_label}}. Remember the vaccination book and a thin towel.',
      },
    },
    {
      dose_list: both('6in1 · Rota (mũi 1)', '6in1 · Rota (dose 1)'),
      age_label: both('Mốc 2 tháng tuổi', '2-month milestone'),
    },
    ['dose_list'],
  ),
  'care.vaccine_morning': tpl(
    'care.vaccine_morning',
    'vaccine',
    ['Lịch tiêm hôm nay', 'Vaccination today'],
    ['dose_list', 'age_label'],
    {
      vi: {
        title: 'Hôm nay có lịch tiêm của bé',
        body: '{{dose_list}} · {{age_label}}. Nhớ mang sổ tiêm và một chiếc khăn mỏng.',
      },
      en: {
        title: 'A vaccination is due today',
        body: '{{dose_list}} · {{age_label}}. Remember the vaccination book and a thin towel.',
      },
    },
    {
      dose_list: both('6in1 · Rota (mũi 1)', '6in1 · Rota (dose 1)'),
      age_label: both('Mốc 2 tháng tuổi', '2-month milestone'),
    },
    ['dose_list'],
  ),
  'spending.recurring': tpl(
    'spending.recurring',
    'spending',
    ['Khoản định kỳ đã thêm', 'Recurring items added'],
    ['count'],
    {
      vi: {
        title: '{{plural:count|Đã thêm khoản định kỳ|Đã thêm {{count}} khoản định kỳ}}',
        body: 'Mở Chi tiêu để xem hoặc sửa.',
      },
      en: {
        title: '{{plural:count|Recurring expense added|{{count}} recurring expenses added}}',
        body: 'Open Spending to see or edit.',
      },
    },
    { count: 2 },
  ),
  'spending.budget80': tpl(
    'spending.budget80',
    'spending',
    ['Chạm 80% ngân sách', 'Budget at 80%'],
    [],
    {
      vi: { title: 'Chi tiêu đã dùng 80% ngân sách tháng', body: 'Mở Chi tiêu để xem chi tiết.' },
      en: {
        title: 'Spending reached 80% of the monthly budget',
        body: 'Open Spending to see the details.',
      },
    },
  ),
  'spending.import_done': tpl(
    'spending.import_done',
    'spending',
    ['Nhập chi tiêu xong', 'Spending import done'],
    ['import_summary'],
    {
      vi: { title: 'Đã nhập xong chi tiêu', body: '{{import_summary}}' },
      en: { title: 'Your spending import is done', body: '{{import_summary}}' },
    },
    { import_summary: both('Đã thêm 42 khoản vào Chi tiêu.', 'Added 42 expenses to Spending.') },
  ),
  'spending.import_failed': tpl(
    'spending.import_failed',
    'spending',
    ['Nhập chi tiêu lỗi', 'Spending import failed'],
    [],
    {
      vi: { title: 'Chưa nhập được chi tiêu', body: 'Mở app để thử lại.' },
      en: { title: 'Your spending import didn’t finish', body: 'Open the app to try again.' },
    },
  ),
  'memories.new_moments': tpl(
    'memories.new_moments',
    'memories',
    ['Khoảnh khắc mới', 'New moments'],
    ['count', 'actor_name'],
    {
      vi: {
        title: 'Có {{count}} khoảnh khắc mới',
        body: '{{actor_name}} vừa chia sẻ với gia đình. Mở để xem.',
      },
      en: {
        title: '{{plural:count|1 new moment|{{count}} new moments}}',
        body: '{{actor_name}} just shared with the family. Open to see.',
      },
    },
    { count: 7, actor_name: 'Mai' },
  ),
  'memories.new_story': tpl('memories.new_story', 'story', ['Câu chuyện mới', 'New story'], [], {
    vi: { title: 'Có 1 câu chuyện mới', body: 'Từ Kỷ niệm của gia đình' },
    en: { title: '1 new story', body: 'From the family’s Memories' },
  }),
  'memories.video_ready': tpl(
    'memories.video_ready',
    'keepsakeVideo',
    ['Video kỷ niệm sẵn sàng', 'Memory video ready'],
    [],
    {
      vi: { title: 'Video kỷ niệm đã sẵn sàng', body: 'Mở Child Life để xem, lưu và chia sẻ.' },
      en: {
        title: 'Your memory video is ready',
        body: 'Open Child Life to watch, save and share.',
      },
    },
  ),
  'memories.video_failed': tpl(
    'memories.video_failed',
    'keepsakeVideoFailed',
    ['Video kỷ niệm lỗi', 'Memory video failed'],
    [],
    {
      vi: { title: 'Chưa tạo được video kỷ niệm', body: 'Mở Child Life để thử lại.' },
      en: { title: 'Your memory video couldn’t be made', body: 'Open Child Life to try again.' },
    },
  ),
  'family.message': tpl(
    'family.message',
    'message',
    ['Lời nhắn mới', 'New message'],
    ['actor_name'],
    {
      vi: { title: 'Có lời nhắn mới', body: '{{actor_name}} vừa nhắn cho ba mẹ. Mở để đọc.' },
      en: {
        title: 'New message',
        body: '{{actor_name}} sent the parents a message. Open to read.',
      },
    },
    { actor_name: 'Bà Lan' },
  ),
  'family.storage_almost_full': tpl(
    'family.storage_almost_full',
    'storage',
    ['Dung lượng sắp đầy', 'Storage almost full'],
    ['percent'],
    {
      vi: {
        title: 'Dung lượng sắp đầy',
        body: 'Gia đình đã dùng {{percent}}% dung lượng. Mở để xem.',
      },
      en: {
        title: 'Storage is almost full',
        body: 'Your family has used {{percent}}% of its space. Open to see.',
      },
    },
    { percent: 80 },
    ['percent'],
  ),
  'family.storage_full': tpl(
    'family.storage_full',
    'storage',
    ['Hết dung lượng', 'Storage full'],
    [],
    {
      vi: { title: 'Đã dùng hết dung lượng', body: 'Tạm dừng tải ảnh, video. Mở để xem.' },
      en: { title: 'Storage is full', body: 'Photo and video uploads are paused. Open to see.' },
    },
  ),
  'family.storage_granted': tpl(
    'family.storage_granted',
    'storageGranted',
    ['Đã thêm dung lượng', 'Storage added'],
    ['gb'],
    {
      vi: {
        title: 'Đã thêm dung lượng',
        body: 'Gia đình có thêm {{gb}} GB. Ảnh, video đang chờ sẽ tự tải tiếp.',
      },
      en: {
        title: 'More storage added',
        body: 'Your family has {{gb}} GB more. Waiting uploads will continue.',
      },
    },
    { gb: 50 },
    ['gb'],
  ),
  'eng.pending_photos': tpl(
    'eng.pending_photos',
    'photoSuggestion',
    ['ENG-01 Ảnh chờ chọn', 'ENG-01 Pending photos'],
    [],
    {
      vi: { title: 'Kỷ niệm của bạn', body: 'Bạn có ảnh đang chờ chọn lưu.' },
      en: { title: 'Your memories', body: 'Some photos are ready for your review.' },
    },
  ),
  'eng.keepsake_suggestion': tpl(
    'eng.keepsake_suggestion',
    'keepsakePrompt',
    ['ENG-02 Gợi ý video theo mốc', 'ENG-02 Milestone keepsake'],
    [],
    {
      vi: { title: 'Kỷ niệm của bạn', body: 'Có một gợi ý làm video kỷ niệm dành cho bạn.' },
      en: { title: 'Your memories', body: 'A memory video idea is ready for you.' },
    },
  ),
  'eng.weekly_recap': tpl(
    'eng.weekly_recap',
    'weeklySummary',
    ['ENG-03 Nhìn lại tuần', 'ENG-03 Weekly recap'],
    [],
    {
      vi: { title: 'Nhìn lại tuần qua', body: 'Bạn có những kỷ niệm đã lưu để xem lại.' },
      en: { title: 'Look back on your week', body: 'Your saved memories are ready to revisit.' },
    },
  ),
  'eng.family_recap': tpl(
    'eng.family_recap',
    'familyActivity',
    ['ENG-05 Cập nhật gia đình', 'ENG-05 Family updates'],
    [],
    {
      vi: { title: 'Gia đình của bạn', body: 'Có cập nhật được chia sẻ trong gia đình.' },
      en: { title: 'Your family', body: 'There are shared family updates.' },
    },
  ),
  'eng.lumi_insight': tpl(
    'eng.lumi_insight',
    'rhythm',
    ['ENG-06 Gợi ý trong ngày', 'ENG-06 Personal day idea'],
    [],
    {
      vi: { title: 'Gợi ý dành cho bạn', body: 'Có một gợi ý mới để bạn xem khi thuận tiện.' },
      en: { title: 'An idea for you', body: 'A fresh suggestion is ready when you are.' },
    },
  ),
};

/** Character guidance shown in the editor (lock screens truncate around here). */
export const templateLengthGuide = {
  title: { recommended: 40, max: 65 },
  body: { recommended: 110, max: 178 },
} as const;

const tokenPattern =
  /\{\{\s*(plural:)?([a-z_]+)\s*(?:\|((?:[^{}|]|\{\{[a-z_]+\}\})*)\|((?:[^{}|]|\{\{[a-z_]+\}\})*))?\}\}/g;

export interface TemplateIssue {
  language: 'vi' | 'en';
  field: 'title' | 'body';
  code:
    | 'unknown_placeholder'
    | 'not_allowed'
    | 'plural_needs_number'
    | 'missing_required'
    | 'empty'
    | 'too_long'
    | 'unbalanced_braces'
    | 'forbidden_content';
  placeholder?: string;
}

/** Validates staff-edited copy for [template] (both languages, both fields). */
export function validateTemplateCopy(
  template: NotificationTemplateDef,
  copy: LocalizedTemplateCopy,
): TemplateIssue[] {
  const issues: TemplateIssue[] = [];
  for (const language of ['vi', 'en'] as const) {
    const used = new Set<string>();
    for (const field of ['title', 'body'] as const) {
      const text = copy[language][field];
      const at = { language, field };
      if (text.trim().length === 0) issues.push({ ...at, code: 'empty' });
      // Length is what a lock screen shows: the copy rendered with the sample values.
      if (
        renderTemplateText(text, language, template.sample).text.length >
        templateLengthGuide[field].max
      )
        issues.push({ ...at, code: 'too_long' });
      // URLs, scripts and markup are never copy; destinations come from the registry only.
      if (/https?:\/\/|<\s*\/?\s*[a-z]|javascript:|\$\{/i.test(text))
        issues.push({ ...at, code: 'forbidden_content' });
      const stripped = text.replace(tokenPattern, '');
      if (/\{\{|\}\}/.test(stripped)) issues.push({ ...at, code: 'unbalanced_braces' });
      for (const m of text.matchAll(tokenPattern)) {
        const name = m[2]!;
        const plural = Boolean(m[1]);
        used.add(name);
        for (const inner of [m[3] ?? '', m[4] ?? '']) {
          for (const n of inner.matchAll(/\{\{([a-z_]+)\}\}/g)) {
            used.add(n[1]!);
            if (!(template.placeholders as readonly string[]).includes(n[1]!))
              issues.push({ ...at, code: 'not_allowed', placeholder: n[1]! });
          }
        }
        if (!(name in notificationPlaceholders)) {
          issues.push({ ...at, code: 'unknown_placeholder', placeholder: name });
        } else if (!(template.placeholders as readonly string[]).includes(name)) {
          issues.push({ ...at, code: 'not_allowed', placeholder: name });
        } else if (
          plural &&
          notificationPlaceholders[name as NotificationPlaceholder].type !== 'number'
        ) {
          issues.push({ ...at, code: 'plural_needs_number', placeholder: name });
        }
      }
    }
    for (const r of template.required) {
      if (!used.has(r))
        issues.push({ language, field: 'body', code: 'missing_required', placeholder: r });
    }
  }
  return issues;
}

/** Renders one string; a missing value takes the registry fallback (an empty fallback = error). */
export function renderTemplateText(
  text: string,
  language: 'vi' | 'en',
  values: Partial<Record<string, PlaceholderValue>>,
): { text: string; missing: string[] } {
  const missing: string[] = [];
  const valueOf = (name: string): string => {
    const v = values[name];
    const def = notificationPlaceholders[name as NotificationPlaceholder];
    const raw =
      v === undefined || v === null
        ? def
          ? typeof def.fallback === 'string'
            ? def.fallback
            : def.fallback[language]
          : ''
        : typeof v === 'object'
          ? v[language]
          : String(v);
    if (raw === '' && (v === undefined || v === null)) missing.push(name);
    const max = def?.maxLength ?? 80;
    return raw.length > max ? `${raw.slice(0, max - 1)}…` : raw;
  };
  const out = text.replace(
    tokenPattern,
    (_all, plural: string | undefined, name: string, one?: string, other?: string) => {
      if (!plural) return valueOf(name);
      const n = Number(values[name] ?? NaN);
      const chosen = n === 1 ? (one ?? '') : (other ?? '');
      return chosen.replace(/\{\{([a-z_]+)\}\}/g, (_m, inner: string) => valueOf(inner));
    },
  );
  return { text: out.replace(/\s{2,}/g, ' ').trim(), missing };
}

export function renderTemplate(
  copy: LocalizedTemplateCopy,
  language: 'vi' | 'en',
  values: Partial<Record<string, PlaceholderValue>>,
): { title: string; body: string; missing: string[] } {
  const title = renderTemplateText(copy[language].title, language, values);
  const body = renderTemplateText(copy[language].body, language, values);
  return { title: title.text, body: body.text, missing: [...title.missing, ...body.missing] };
}

// ---------- Template documents and staff API ----------

/** `notificationTemplates/{id}`: draft workflow + the denormalised live copy producers read. */
export const notificationTemplateStatuses = [
  'builtin',
  'draft',
  'ready_for_review',
  'published',
  'paused',
  'archived',
] as const;
export type NotificationTemplateStatus = (typeof notificationTemplateStatuses)[number];

/** Source text (placeholders and plural branches included); rendered length is checked apart. */
const copyLine = z.object({
  title: z.string().trim().min(1).max(160),
  body: z.string().trim().min(1).max(320),
});
export const localizedTemplateCopySchema = z.object({ vi: copyLine, en: copyLine }).strict();

export const templateIdSchema = z.enum(notificationTemplateIds);

export const staffSaveTemplateSchema = z
  .object({ templateId: templateIdSchema, copy: localizedTemplateCopySchema })
  .strict();

export const staffTemplateActionSchema = z.discriminatedUnion('action', [
  z.object({ templateId: templateIdSchema, action: z.literal('submit') }).strict(),
  z.object({ templateId: templateIdSchema, action: z.literal('discard') }).strict(),
  z
    .object({
      templateId: templateIdSchema,
      action: z.literal('publish'),
      note: z.string().trim().max(200).default(''),
    })
    .strict(),
  z.object({ templateId: templateIdSchema, action: z.literal('pause') }).strict(),
  z.object({ templateId: templateIdSchema, action: z.literal('resume') }).strict(),
  z.object({ templateId: templateIdSchema, action: z.literal('archive') }).strict(),
  z
    .object({
      templateId: templateIdSchema,
      action: z.literal('rollback'),
      version: z.number().int().min(0).max(10_000),
    })
    .strict(),
]);
export type StaffTemplateAction = z.infer<typeof staffTemplateActionSchema>;

/** Operational switches (`config/notifications`), audited, editable in Portal → Cài đặt. */
export const notificationOpsConfigSchema = z
  .object({
    /** Off: every producer uses the built-in copy (version 0), whatever is published. */
    templatesEnabled: z.boolean().default(true),
    /** Off: transient provider errors are marked failed at once (no scheduled retry). */
    retryEnabled: z.boolean().default(true),
    /** Kill switch per inbox group: the row is still written, the push is cancelled. */
    pushPaused: z
      .object({
        memories: z.boolean().default(false),
        family: z.boolean().default(false),
        care: z.boolean().default(false),
        other: z.boolean().default(false),
      })
      .strict()
      .default({ memories: false, family: false, care: false, other: false }),
  })
  .strict();
export type NotificationOpsConfig = z.infer<typeof notificationOpsConfigSchema>;
export const defaultNotificationOpsConfig = notificationOpsConfigSchema.parse({});

export const staffSetNotificationOpsSchema = z
  .object({ config: notificationOpsConfigSchema })
  .strict();

const dateOnly = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);

export const staffNotificationStatsSchema = z
  .object({ from: dateOnly, to: dateOnly })
  .strict()
  .refine((r) => r.from <= r.to && (Date.parse(r.to) - Date.parse(r.from)) / 86_400_000 < 92, {
    message: 'Invalid range',
  });

export const staffNotificationTimelineSchema = z
  .object({
    code: z.string().regex(/^F-[A-Z2-9]{4}$/),
    view: z.enum(['all', 'engagement']).default('all'),
    from: dateOnly,
    to: dateOnly,
    group: z.enum(['all', ...inboxGroups]).default('all'),
    kind: z.enum(['all', ...notificationKinds]).default('all'),
    scenario: z
      .enum(['all', 'ENG-01', 'ENG-02', 'ENG-03', 'ENG-04', 'ENG-05', 'ENG-06'])
      .default('all'),
    delivery: z.enum(['all', ...notificationDeliveryStates]).default('all'),
    recipient: z
      .string()
      .regex(/^m\d{1,2}$/)
      .optional(),
    cursor: z.string().max(200).optional(),
  })
  .strict()
  .refine((r) => r.from <= r.to && (Date.parse(r.to) - Date.parse(r.from)) / 86_400_000 < 92, {
    message: 'Invalid range',
  });
export type StaffNotificationTimelineRequest = z.infer<typeof staffNotificationTimelineSchema>;

export const staffNotificationDetailSchema = z
  .object({
    code: z.string().regex(/^F-[A-Z2-9]{4}$/),
    entry: z.string().regex(/^(d|e)_[a-f0-9]{24,64}$/),
  })
  .strict();

export const staffRetryNotificationSchema = z
  .object({ entry: z.string().regex(/^d_[a-f0-9]{24,64}$/) })
  .strict();

export const recordNotificationOpenSchema = z
  .object({
    inboxId: z.string().regex(/^n_[A-Za-z0-9_-]{6,120}$/),
    surface: z.enum(['push', 'inbox']),
    outcome: z.enum(['navigated', 'fallback', 'unavailable']),
    destination: z.enum(notificationDestinationIds).optional(),
  })
  .strict();
export type RecordNotificationOpen = z.infer<typeof recordNotificationOpenSchema>;

// ---------- Derived helpers ----------

/** The destination a row opens, from what the producer put in `data` (legacy rows included). */
export function destinationFor(
  kind: NotificationKind,
  data: Record<string, string>,
): NotificationDestinationId {
  const explicit = data.destination as NotificationDestinationId | undefined;
  if (explicit && (notificationDestinationIds as readonly string[]).includes(explicit))
    return explicit;
  if (kind === 'spending' && data.importId) return 'SPENDING_IMPORT';
  if (kind === 'album' && data.sourceCollection === 'albums' && data.sourceId)
    return 'MEMORIES_ALBUM';
  if (kind === 'story' && data.sourceCollection === 'stories' && data.sourceId)
    return 'MEMORIES_STORY';
  if ((kind === 'keepsakeVideo' || kind === 'keepsakeVideoFailed') && !data.jobId)
    return 'MEMORIES';
  return notificationTypes[kind].destination;
}

/** Whether quiet hours hold this kind's push (care the person set rings anyway). */
export function quietHoursHold(kind: NotificationKind): boolean {
  return !ringsInQuietHours(kind);
}

/** Sanity: every kind is in the catalog with the same switch and legacy category the inbox uses. */
export function catalogConsistent(): string[] {
  const problems: string[] = [];
  for (const kind of notificationKinds) {
    const def = notificationTypes[kind];
    if (!def) {
      problems.push(`${kind}: missing`);
      continue;
    }
    if (def.setting !== notificationSettingOf[kind]) problems.push(`${kind}: setting`);
    if ((def.quietHours === 'rings') !== ringsInQuietHours(kind)) problems.push(`${kind}: quiet`);
    if (!notificationCategoryOf[kind]) problems.push(`${kind}: category`);
    for (const t of def.templates) {
      if (!notificationTemplates[t]) problems.push(`${kind}: template ${t}`);
    }
  }
  return problems;
}

// ---------- Staff API responses (Portal ↔ Functions) ----------

export interface NotificationTemplateVersion {
  version: number;
  copy: LocalizedTemplateCopy;
  publishedAt: string;
  publishedBy: string;
  note: string;
}

export interface NotificationTemplateRow {
  id: NotificationTemplateId;
  kind: NotificationKind;
  group: InboxGroup;
  status: NotificationTemplateStatus;
  /** A draft waits on top of the live copy (status shows the live state when published). */
  draftState: 'none' | 'draft' | 'ready_for_review';
  liveVersion: number;
  latestVersion: number;
  hasVi: boolean;
  hasEn: boolean;
  destination: NotificationDestinationId;
  updatedAt: string | null;
  updatedBy: string | null;
  /** Rows created with this template in the last 30 days (from daily stats). */
  sent30d: number | null;
}

export interface NotificationTemplateDetail extends NotificationTemplateRow {
  live: LocalizedTemplateCopy;
  draft: LocalizedTemplateCopy | null;
  draftBy: string | null;
  submittedBy: string | null;
  versions: NotificationTemplateVersion[];
  issues: TemplateIssue[];
}

export type NotificationStatCounts = Partial<Record<NotificationStatMetric, number>>;

export interface NotificationStatsResponse {
  range: { from: string; to: string };
  reportingZone: 'Asia/Ho_Chi_Minh';
  computedAt: string;
  /** First day any ledger stat exists; earlier days are unavailable, not zero. */
  sourceStartDay: string | null;
  days: Array<{ day: string; totals: NotificationStatCounts }>;
  byKind: Array<{ kind: NotificationKind; counts: NotificationStatCounts }>;
  byGroup: Array<{ group: InboxGroup; counts: NotificationStatCounts }>;
  byTemplate: Array<{
    templateId: NotificationTemplateId | 'none';
    version: number;
    counts: NotificationStatCounts;
  }>;
  /** Deliveries waiting for a retry or failed in the range (bounded list, newest first). */
  problems: Array<{
    entry: string;
    kind: NotificationKind;
    delivery: NotificationDeliveryState;
    reason: NotificationDeliveryReason;
    attempts: number;
    createdAt: string;
    errorCode: string | null;
    familyCode: string | null;
  }>;
  ops: NotificationOpsConfig;
}

export interface TimelineRecipient {
  /** Masked reference stable within one response ("m1", "m2" …), never a uid or email. */
  ref: string;
  role: string;
  label: string;
}

export interface TimelineEntry {
  /** `d_…` ledger entry, `e_…` engagement intent without a ledger row (in-app / suppressed). */
  entry: string;
  at: string;
  kind: NotificationKind | null;
  scenario: string | null;
  group: InboxGroup | null;
  recipient: string;
  templateId: string | null;
  templateVersion: number | null;
  channel: 'push_inbox' | 'inbox' | 'in_app' | 'none';
  lifecycle: NotificationLifecycleState | null;
  delivery: NotificationDeliveryState | null;
  read: NotificationReadState | null;
  action: NotificationActionState | null;
  engagementStatus: string | null;
  reason: string | null;
  destination: NotificationDestinationId | null;
}

export interface TimelineUpcoming {
  scenario: string;
  /** confirmed = the engine holds a scheduled send; predicted = conditional on rules at that time. */
  certainty: 'confirmed' | 'predicted';
  state: 'scheduled' | 'waiting' | 'suppressed' | 'expiring';
  at: string | null;
  expiresAt: string | null;
  conditions: string[];
  recipient: string | null;
}

export interface NotificationTimelineResponse {
  family: { code: string; babies: number; members: number };
  summary: {
    notifications: number;
    engagements: number;
    completed: number;
    pending: number;
    suppressed: number;
    failed: number;
    lastActivityAt: string | null;
  };
  recipients: TimelineRecipient[];
  entries: TimelineEntry[];
  nextCursor: string | null;
  upcoming: TimelineUpcoming[];
  preferences: Array<{ recipient: string; muted: string[]; engagementConsent: boolean | null }>;
  /** Bounded scan: true when more rows exist in the range than the page holds. */
  truncated: boolean;
}

export interface NotificationDetailCheck {
  rule: string;
  result: 'pass' | 'fail' | 'unknown';
  detail?: string;
}

export interface NotificationEntryDetail {
  entry: string;
  scenario: string | null;
  kind: NotificationKind | null;
  why: string | null;
  checks: NotificationDetailCheck[];
  decision: string | null;
  reason: string | null;
  templateId: string | null;
  templateVersion: number | null;
  destination: NotificationDestinationId | null;
  timeline: Array<{ at: string; dimension: string; to: string; reason: string | null }>;
  pushAttempted: boolean | null;
  providerAccepted: boolean | null;
  opened: boolean | null;
  navigated: 'navigated' | 'fallback' | 'unavailable' | null;
  completed: boolean | null;
  cancelledOrExpired: string | null;
  errors: string[];
}
