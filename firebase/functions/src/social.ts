import { FieldValue, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import {
  notificationKinds,
  type NotificationKind,
  type NotificationTemplateId,
  type PlaceholderValue,
} from '@child-life/contracts';
import { notifyUsers } from './notifications.js';

/**
 * Loves, messages and family notices (S10). The app writes loves (`reactions`), favourites and
 * messages itself (Rules check them); the server keeps love counts on their targets, turns a new
 * message into a notice for the parents (D-034) and delivers notices to devices — always generic,
 * never a photo, a caption or the baby's name (R-116, R-120). Message text is never logged.
 */

const targetCollection: Record<string, string> = {
  media: 'media',
  memory: 'memories',
  album: 'albums',
  story: 'stories',
};

/** "♥ 4": a love added or taken back moves its target's count. */
export async function onReactionWritten(
  db: Firestore,
  babyId: string,
  before: DocumentSnapshot | null,
  after: DocumentSnapshot | null,
): Promise<void> {
  const delta = (after?.exists ? 1 : 0) - (before?.exists ? 1 : 0);
  if (delta === 0) return;
  const doc = after?.exists ? after : before!;
  const collection = targetCollection[doc.get('target') as string];
  const targetId = doc.get('targetId') as string | undefined;
  if (!collection || !targetId) return;
  const ref = db.doc(`babies/${babyId}/${collection}/${targetId}`);
  if (!(await ref.get()).exists) return;
  await ref.update({ loveCount: FieldValue.increment(delta) });
}

/** "Nhắn ba mẹ" (D-034): one notice to every Cùng nuôi except the sender. */
export async function onMessageCreated(
  db: Firestore,
  babyId: string,
  message: DocumentSnapshot,
  now: Date,
): Promise<void> {
  const from = message.get('from') as string;
  const parents = await db
    .collection(`babies/${babyId}/members`)
    .where('role', '==', 'coParent')
    .where('status', '==', 'active')
    .get();
  // `create`: a redelivered trigger finds the notice and stops (P-174 dedup).
  await createOnce(db.doc(`babies/${babyId}/notifications/message_${message.id}`), {
    kind: 'message',
    sourceCollection: 'messages',
    sourceId: message.id,
    actorUid: from,
    babyId,
    count: 1,
    actor: message.get('author') ?? null,
    recipients: parents.docs.map((p) => p.id).filter((uid) => uid !== from),
    context: message.get('context') ?? null,
    createdAt: now,
    delivered: false,
  });
}

/** Creates [ref] unless it exists (ALREADY_EXISTS = a retry; nothing to do). */
export async function createOnce(
  ref: FirebaseFirestore.DocumentReference,
  data: Record<string, unknown>,
): Promise<boolean> {
  try {
    await ref.create(data);
    return true;
  } catch (error) {
    if ((error as { code?: number }).code === 6) return false;
    throw error;
  }
}

export interface PushSender {
  /** Sends to [tokens]; returns the tokens the push service rejected for good. */
  send(
    tokens: string[],
    message: {
      title: string;
      body: string;
      data: Record<string, string>;
      /** iOS notification category (actions), collapse id and thread. */
      apns?: { category?: string; collapseId?: string; threadId?: string };
      /**
       * Android draws this one itself, with the iOS category's actions (Android plan A6): a
       * system-drawn FCM notification cannot carry buttons.
       */
      androidDraws?: boolean;
      /** ENG expiry bounds offline provider delivery; no change for existing notices. */
      expiresAt?: number;
    },
  ): Promise<string[]>;
}

/**
 * The FCM message for a push. iOS shows the alert with its category; Android shows the
 * notification block (Android plan A1) — or, for pushes with actions (`androidDraws`, A6), gets
 * the title, body and tag as data and draws it in the app (PushService.kt), since a system-drawn
 * FCM notification cannot carry buttons.
 */
export function pushPayload(message: Parameters<PushSender['send']>[1]) {
  const expiryHeaders =
    message.expiresAt === undefined
      ? {}
      : { 'apns-expiration': String(Math.floor(message.expiresAt / 1000)) };
  const ttl =
    message.expiresAt === undefined
      ? {}
      : { ttl: Math.max(0, Math.min(28 * 86400_000, message.expiresAt - Date.now())) };
  const apns = {
    ...(message.apns?.collapseId || message.expiresAt !== undefined
      ? {
          headers: {
            ...expiryHeaders,
            ...(message.apns?.collapseId ? { 'apns-collapse-id': message.apns.collapseId } : {}),
          },
        }
      : {}),
    payload: {
      aps: {
        sound: 'default',
        ...(message.androidDraws ? { alert: { title: message.title, body: message.body } } : {}),
        ...(message.apns?.category ? { category: message.apns.category } : {}),
        ...(message.apns?.threadId ? { threadId: message.apns.threadId } : {}),
      },
    },
  };
  if (message.androidDraws) {
    return {
      data: {
        ...message.data,
        title: message.title,
        body: message.body,
        draw: '1',
        tag: message.apns?.collapseId ?? '',
      },
      apns,
      android: { priority: 'high' as const, ...ttl },
    };
  }
  return {
    notification: { title: message.title, body: message.body },
    data: message.data,
    apns,
    android: { priority: 'high' as const, ...ttl, notification: androidNotification(message) },
  };
}

/**
 * The Android side of a push (Android plan A1): the channel the app created in its language, the
 * status-bar icon and accent, and a tag so a newer notice for the same rule or day replaces the
 * earlier one, as `apns-collapse-id` does on iOS.
 */
export function androidNotification(message: Parameters<PushSender['send']>[1]) {
  const kind = message.data.kind;
  return {
    channelId:
      kind === 'reminderRule' || kind === 'vaccine'
        ? 'reminders'
        : kind === 'spending'
          ? 'spending'
          : 'family',
    icon: 'ic_stat_notify',
    color: '#087F7B',
    ...(message.apns?.collapseId ? { tag: message.apns.collapseId } : {}),
  };
}

type Copy = { title: string; body: string };

/** The Portal template and values of a family notice (P-174); [noticeCopy] is its version 0. */
export function noticeTemplate(
  kind: string,
  count: number,
  actorName: string,
  context?: Record<string, unknown> | null,
): { id: NotificationTemplateId; values: Record<string, PlaceholderValue> } | undefined {
  // An unknown sender takes the placeholder's fallback ("Người thân"): titles start with the name.
  const actor: Record<string, PlaceholderValue> = actorName ? { actor_name: actorName } : {};
  // D-135 N4: a helper's handover for the whole family, with the tasks still waiting.
  if (kind === 'handoverSent' && context?.family === true) {
    const open = typeof context.openTasks === 'number' ? context.openTasks : 0;
    return open > 0 ? { id: 'ai.handover_family', values: { ...actor, count: open } } : undefined;
  }
  switch (kind) {
    case 'memories':
    case 'shared':
    case 'album':
      return { id: 'memories.new_moments', values: { count, ...actor } };
    case 'keepsakeVideo':
      return { id: 'memories.video_ready', values: {} };
    case 'keepsakeVideoFailed':
      return { id: 'memories.video_failed', values: {} };
    case 'story':
      return { id: 'memories.new_story', values: {} };
    case 'storage':
      return count >= 100
        ? { id: 'family.storage_full', values: {} }
        : { id: 'family.storage_almost_full', values: { percent: count } };
    case 'storageGranted':
      return { id: 'family.storage_granted', values: { gb: count } };
    case 'message':
      return { id: 'family.message', values: actor };
    case 'memberJoined':
      return { id: 'family.member_joined', values: actor };
    case 'inviteDeclined':
      return { id: 'family.invite_declined', values: {} };
    case 'roleChanged':
      return { id: 'family.role_changed', values: {} };
    case 'memberRemoved':
      return { id: 'family.member_removed', values: {} };
    case 'handoverSent':
      return { id: 'ai.handover_sent', values: actor };
    default:
      return undefined;
  }
}

/** Generic lock-screen copy (11b, R-120) in the recipient's language. */
export function noticeCopy(
  kind: string,
  count: number,
  actorName: string,
  language: string,
  context?: Record<string, unknown> | null,
): Copy {
  const vi = !language.startsWith('en');
  // D-135 N4: who sent it and how many tasks wait; never anything about the child.
  if (kind === 'handoverSent' && context?.family === true) {
    const open = typeof context.openTasks === 'number' ? context.openTasks : 0;
    const who = actorName || (vi ? 'Người chăm sóc' : 'Your helper');
    return vi
      ? {
          title: `${who} vừa bàn giao cho cả nhà`,
          body:
            open > 0
              ? `Còn ${open} việc chờ ba mẹ, mở xem để tiếp nối nhé.`
              : 'Mở xem bàn giao để nắm tình hình của bé nhé.',
        }
      : {
          title: `${who} sent the family a handover`,
          body:
            open > 0
              ? `${open} ${open === 1 ? 'task' : 'tasks'} left for you. Open it to pick up from here.`
              : 'Open it to catch up on how your baby is doing.',
        };
  }
  switch (kind) {
    case 'memories':
    case 'shared':
    case 'album':
      return vi
        ? {
            title: `${count} khoảnh khắc mới`,
            body: `${actorName || 'Người thân'} vừa chia sẻ với cả nhà, cùng xem nhé.`,
          }
        : {
            title: count === 1 ? '1 new moment' : `${count} new moments`,
            body: `${actorName || 'A family member'} just shared with the family. Come take a look!`,
          };
    // Video kỷ niệm ready (D-068 #4, MM17), to the person who asked only.
    case 'keepsakeVideo':
      return vi
        ? { title: 'Video kỷ niệm đã xong rồi', body: 'Xem ngay rồi lưu hoặc gửi cho cả nhà nhé.' }
        : {
            title: 'Your memory video is ready',
            body: 'Watch it now, then save it or share it with the family.',
          };
    // Video kỷ niệm could not be made (MM14), to the person who asked only.
    case 'keepsakeVideoFailed':
      return vi
        ? {
            title: 'Chưa tạo được video kỷ niệm',
            body: 'Ảnh và video của bạn vẫn còn nguyên. Bạn mở app để thử lại nhé.',
          }
        : {
            title: 'Your memory video couldn’t be made',
            body: 'Your photos and videos are safe. Open the app to try again.',
          };
    case 'story':
      return vi
        ? {
            title: 'Có câu chuyện mới',
            body: 'Một trang mới vừa được thêm vào Kỷ niệm của gia đình.',
          }
        : { title: 'A new story', body: 'A new page was just added to the family’s Memories.' };
    case 'storage':
      return count >= 100
        ? vi
          ? {
              title: 'Dung lượng của gia đình đã đầy',
              body: 'Ảnh, video mới đang tạm chờ, chưa tải lên. Mở để xem cách tiếp tục lưu nhé.',
            }
          : {
              title: 'Your family’s storage is full',
              body: 'New photos and videos are waiting to upload. Open to see how to keep saving.',
            }
        : vi
          ? {
              title: 'Dung lượng của gia đình sắp đầy',
              body: `Đã dùng ${count}%. Bạn xem qua để ảnh, video mới vẫn được lưu đều nhé.`,
            }
          : {
              title: 'Your family’s storage is almost full',
              body: `${count}% is used. Take a look so new photos and videos keep saving.`,
            };
    case 'storageGranted':
      return vi
        ? {
            title: `Gia đình vừa có thêm ${count} GB`,
            body: 'Ảnh, video đang chờ sẽ tự tải lên tiếp, bạn không cần làm gì thêm.',
          }
        : {
            title: `Your family just got ${count} GB more`,
            body: 'Waiting photos and videos will upload on their own. Nothing else to do.',
          };
    case 'message':
      return vi
        ? {
            title: `Có lời nhắn mới từ ${actorName || 'Người thân'}`,
            body: 'Lời nhắn gửi ba mẹ, mở ra đọc nhé.',
          }
        : {
            title: `New message from ${actorName || 'A family member'}`,
            body: 'A message for the parents. Open it to read.',
          };
    // G-109 (D-092): membership events, no baby name (R-120).
    case 'memberJoined':
      return vi
        ? {
            title: 'Chào mừng thành viên mới',
            body: `${actorName || 'Người thân'} vừa vào gia đình, cùng chào đón nhé!`,
          }
        : {
            title: 'Say hello to a new family member',
            body: `${actorName || 'A family member'} just joined the family.`,
          };
    case 'inviteDeclined':
      return vi
        ? {
            title: 'Lời mời chưa được nhận',
            body: 'Một lời mời vào gia đình đã bị từ chối. Bạn có thể gửi lời mời khác bất cứ lúc nào.',
          }
        : {
            title: 'Invitation not accepted',
            body: 'An invitation to join the family was declined. You can send another one any time.',
          };
    case 'roleChanged':
      return vi
        ? {
            title: 'Vai trò của bạn trong gia đình đã thay đổi',
            body: 'Mở để xem giờ bạn có thể làm những gì nhé.',
          }
        : {
            title: 'Your role in the family changed',
            body: 'Open to see what you can do now.',
          };
    case 'memberRemoved':
      return vi
        ? {
            title: 'Bạn không còn ở trong một gia đình nữa',
            body: 'Bạn sẽ không xem được hồ sơ của bé ở gia đình đó. Nếu có nhầm lẫn, hãy liên hệ ba mẹ của bé nhé.',
          }
        : {
            title: 'You’re no longer in a family',
            body: 'You can no longer see the child’s profile in that family. If this is a mistake, please contact the child’s parents.',
          };
    // D-093: who sent it; never anything about the child.
    case 'handoverSent':
      return vi
        ? {
            title: `${actorName || 'Người thân'} vừa bàn giao cho bạn`,
            body: 'Mở xem bàn giao để nắm tình hình của bé nhé.',
          }
        : {
            title: `${actorName || 'A family member'} sent you a handover`,
            body: 'Open it to catch up on how your baby is doing.',
          };
    default:
      return vi
        ? { title: 'Child Life', body: 'Có cập nhật mới từ gia đình.' }
        : { title: 'Child Life', body: 'Something new from the family.' };
  }
}

function isNotificationKind(kind: string): kind is NotificationKind {
  return (notificationKinds as readonly string[]).includes(kind);
}

/** The baby's zone, for quiet hours. */
async function babyZone(db: Firestore, babyId: string): Promise<string | undefined> {
  const baby = await db.doc(`babies/${babyId}`).get();
  return (baby.get('timeZone.zone') as string | undefined) ?? undefined;
}

/**
 * Sends a recorded notice to its recipients' devices (`users/{uid}/devices`), once. Tokens the
 * push service rejects are removed. Without a sender (emulator) it is only marked delivered
 * and recorded in the inbox.
 */
export async function deliverNotice(
  db: Firestore,
  sender: PushSender | null,
  babyId: string,
  noticeId: string,
  now: Date,
): Promise<{ sent: number }> {
  const ref = db.doc(`babies/${babyId}/notifications/${noticeId}`);
  const claimed = await db.runTransaction(async (tx) => {
    const n = await tx.get(ref);
    if (!n.exists || n.get('delivered') === true) return null;
    tx.update(ref, { delivered: true, deliveredAt: now });
    return n;
  });
  if (!claimed) return { sent: 0 };
  const actor = (claimed.get('actor') as { name?: string } | null)?.name ?? '';
  const kind = claimed.get('kind') as string;
  const count = (claimed.get('count') as number | undefined) ?? 1;
  const context = claimed.get('context') as Record<string, unknown> | null | undefined;
  const recipients = (claimed.get('recipients') as string[] | undefined) ?? [];
  // D-076 #2: one helper pushes, records the inbox row and honours EN07 / quiet hours (the
  // "Thông báo" switches of G-056 included).
  const { sent } = await notifyUsers(
    db,
    sender,
    recipients,
    {
      kind: isNotificationKind(kind) ? kind : 'memories',
      id: `bn-${babyId}-${noticeId}`,
      babyId,
      // The job a Video kỷ niệm notice opens (MM09 / MM14); ids only.
      data: {
        babyId,
        kind,
        noticeId,
        ...(typeof claimed.get('sourceId') === 'string'
          ? { sourceId: claimed.get('sourceId'), sourceCollection: claimed.get('sourceCollection') }
          : {}),
        // P-174 destination params (MEMORIES_ALBUM / MEMORIES_STORY).
        ...(claimed.get('sourceCollection') === 'albums' &&
        typeof claimed.get('sourceId') === 'string'
          ? { albumId: claimed.get('sourceId') }
          : {}),
        ...(claimed.get('sourceCollection') === 'stories' &&
        typeof claimed.get('sourceId') === 'string'
          ? { storyId: claimed.get('sourceId') }
          : {}),
        // MEMORIES_SHARED: the moments one share made visible to the family.
        ...(claimed.get('sourceCollection') === 'shares' &&
        typeof claimed.get('sourceId') === 'string'
          ? { shareId: claimed.get('sourceId') }
          : {}),
        ...(typeof context?.jobId === 'string' ? { jobId: context.jobId } : {}),
        // D-093 CARE_HANDOVER: the summary that was sent.
        ...(claimed.get('sourceCollection') === 'summaries' &&
        typeof claimed.get('sourceId') === 'string'
          ? { summaryId: claimed.get('sourceId') }
          : {}),
      },
      message: (language) => noticeCopy(kind, count, actor, language, context),
      template: noticeTemplate(kind, count, actor, context),
      zone: await babyZone(db, babyId),
    },
    now,
  );
  return { sent };
}
