import { FieldValue, type DocumentSnapshot, type Firestore } from 'firebase-admin/firestore';
import { mutedRecipients } from './account.js';

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
  await db.doc(`babies/${babyId}/notifications/message_${message.id}`).set({
    kind: 'message',
    babyId,
    count: 1,
    actor: message.get('author') ?? null,
    recipients: parents.docs.map((p) => p.id).filter((uid) => uid !== from),
    context: message.get('context') ?? null,
    createdAt: now,
    delivered: false,
  });
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
  const apns = {
    ...(message.apns?.collapseId
      ? { headers: { 'apns-collapse-id': message.apns.collapseId } }
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
      android: { priority: 'high' as const },
    };
  }
  return {
    notification: { title: message.title, body: message.body },
    data: message.data,
    apns,
    android: { priority: 'high' as const, notification: androidNotification(message) },
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

/** Generic lock-screen copy (11b, R-120) in the recipient's language. */
export function noticeCopy(kind: string, count: number, actorName: string, language: string): Copy {
  const vi = !language.startsWith('en');
  switch (kind) {
    case 'memories':
    case 'shared':
    case 'album':
      return vi
        ? {
            title: `Có ${count} khoảnh khắc mới`,
            body: `${actorName} vừa chia sẻ với gia đình. Mở để xem.`,
          }
        : {
            title: count === 1 ? '1 new moment' : `${count} new moments`,
            body: `${actorName} just shared with the family. Open to see.`,
          };
    // Video kỷ niệm ready (D-068 #4, MM17), to the person who asked only.
    case 'keepsakeVideo':
      return vi
        ? { title: 'Video kỷ niệm đã sẵn sàng', body: 'Mở Child Life để xem, lưu và chia sẻ.' }
        : {
            title: 'Your memory video is ready',
            body: 'Open Child Life to watch, save and share.',
          };
    // Video kỷ niệm could not be made (MM14), to the person who asked only.
    case 'keepsakeVideoFailed':
      return vi
        ? { title: 'Chưa tạo được video kỷ niệm', body: 'Mở Child Life để thử lại.' }
        : { title: 'Your memory video couldn’t be made', body: 'Open Child Life to try again.' };
    case 'story':
      return vi
        ? { title: 'Có 1 câu chuyện mới', body: 'Từ Kỷ niệm của gia đình' }
        : { title: '1 new story', body: 'From the family’s Memories' };
    case 'storage':
      return count >= 100
        ? vi
          ? { title: 'Đã dùng hết dung lượng', body: 'Tạm dừng tải ảnh, video. Mở để xem.' }
          : { title: 'Storage is full', body: 'Photo and video uploads are paused. Open to see.' }
        : vi
          ? {
              title: 'Dung lượng sắp đầy',
              body: `Gia đình đã dùng ${count}% dung lượng. Mở để xem.`,
            }
          : {
              title: 'Storage is almost full',
              body: `Your family has used ${count}% of its space. Open to see.`,
            };
    case 'storageGranted':
      return vi
        ? {
            title: 'Đã thêm dung lượng',
            body: `Gia đình có thêm ${count} GB. Ảnh, video đang chờ sẽ tự tải tiếp.`,
          }
        : {
            title: 'More storage added',
            body: `Your family has ${count} GB more. Waiting uploads will continue.`,
          };
    case 'message':
      return vi
        ? { title: 'Có lời nhắn mới', body: `${actorName} vừa nhắn cho ba mẹ. Mở để đọc.` }
        : { title: 'New message', body: `${actorName} sent the parents a message. Open to read.` };
    default:
      return vi
        ? { title: 'Child Life', body: 'Có cập nhật mới từ gia đình.' }
        : { title: 'Child Life', body: 'Something new from the family.' };
  }
}

/**
 * Sends a recorded notice to its recipients' devices (`users/{uid}/devices`), once. Tokens the
 * push service rejects are removed. Without a sender (emulator) it is only marked delivered.
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
  let sent = 0;
  const recipients = (claimed.get('recipients') as string[] | undefined) ?? [];
  // "Thông báo" settings (G-056): a muted kind is recorded but not pushed.
  const muted = await mutedRecipients(db, kind, recipients);
  for (const uid of recipients) {
    if (muted.has(uid)) continue;
    const devices = await db.collection(`users/${uid}/devices`).get();
    const byLanguage = new Map<string, { tokens: string[]; refs: Map<string, DocumentSnapshot> }>();
    for (const d of devices.docs) {
      const token = d.get('token') as string | undefined;
      if (!token) continue;
      const language = (d.get('language') as string | undefined) ?? 'vi';
      const entry = byLanguage.get(language) ?? {
        tokens: [] as string[],
        refs: new Map<string, DocumentSnapshot>(),
      };
      entry.tokens.push(token);
      entry.refs.set(token, d);
      byLanguage.set(language, entry);
    }
    for (const [language, { tokens, refs }] of byLanguage) {
      if (!sender) continue;
      const copy = noticeCopy(kind, count, actor, language);
      const rejected = await sender.send(tokens, {
        ...copy,
        // The job a Video kỷ niệm notice opens (MM09 / MM14); ids only.
        data: {
          babyId,
          kind,
          noticeId,
          ...(typeof context?.jobId === 'string' ? { jobId: context.jobId } : {}),
        },
      });
      sent += tokens.length - rejected.length;
      for (const t of rejected) await refs.get(t)?.ref.delete();
    }
  }
  return { sent };
}
