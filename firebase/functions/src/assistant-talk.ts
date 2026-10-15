import type { AssistantPart, DraftKind, SmallTalkKind } from '@child-life/contracts';
import { sha } from './assistant-common.js';

/**
 * Lumi rework 2026-10-15: the server's own short replies (small talk, "what I can do", the
 * spending privacy notice, text notices) and the author's private thread id. The model never
 * writes these words; vi / en are kept side by side like every assistant catalog.
 */

const L = (vi: string, en: string) => ({ vi, en });
type Locale = 'vi' | 'en';

/**
 * The author's private thread about one baby (D-075 #2): where a message with money in it goes
 * when it was sent from the baby's shared thread. Deterministic, so every such message of the
 * same person lands in the same thread.
 */
export const privateConversationId = (uid: string, babyId: string) =>
  `cv_p_${sha(`private|${uid}|${babyId}`).slice(0, 32)}`;

const smallTalk: Record<SmallTalkKind, { vi: string; en: string }> = {
  thanks: L(
    'Không có gì! Khi cần ghi bú, ngủ, chi tiêu hay đặt nhắc việc, cứ nhắn Lumi nhé.',
    'You’re welcome! Message me anytime to log feeds, sleep, expenses or reminders.',
  ),
  greeting: L(
    'Chào bạn! Mình là Lumi. Bạn nhắn để ghi bú, ngủ, chi tiêu, đặt nhắc việc hoặc hỏi nhật ký của bé nhé.',
    'Hi! I’m Lumi. Message me to log feeds, sleep, expenses, set reminders or ask about the log.',
  ),
  ack: L('Ok! Mình ở đây khi bạn cần.', 'OK! I’m here when you need me.'),
  bye: L('Tạm biệt! Hẹn gặp lại bạn và bé.', 'Bye for now!'),
};

/** A short friendly reply to small talk ("cảm ơn Lumi"): 0 credits, no model. */
export function smallTalkPart(kind: SmallTalkKind, locale: Locale): AssistantPart {
  return { type: 'text', schemaVersion: 1, text: smallTalk[kind][locale], code: 'SMALL_TALK' };
}

const help = {
  help: L(
    'Mình chưa giúp được việc này. Lumi có thể: ghi bú, ngủ và ghi nhận của bé (“bé bú 120ml lúc 8h”), ghi chi tiêu (“mua sữa hết 500k”), đặt nhắc việc (“nhắc mai 9h mua bỉm”) và trả lời về nhật ký (“hôm nay con bú thế nào?”). Không tính lượt.',
    'I can’t help with that one. Lumi can log feeds, sleep and notes (“fed 120 ml at 8”), expenses (“$20 diapers”), set reminders (“remind me tomorrow at 9 to buy diapers”) and answer about the log (“how did feeds go today?”). No credit was used.',
  ),
  write: L(
    'Bạn nhắn giúp mình việc cần ghi nhé, ví dụ “bé bú 120ml lúc 8h” hoặc “mua sữa hết 500k”. Không tính lượt.',
    'Tell me what to log, e.g. “fed 120 ml at 8” or “$20 diapers”. No credit was used.',
  ),
};

/** Nothing to log or read: what Lumi can do, never a dead end (0 credits). */
export function helpPart(locale: Locale, variant: 'help' | 'write' = 'help'): AssistantPart {
  return { type: 'text', schemaVersion: 1, text: help[variant][locale], code: 'HELP' };
}

/** D-075 #2: shown first in a task kept out of the shared thread because of money. */
export function spendingPrivatePart(locale: Locale): AssistantPart {
  return {
    type: 'text',
    schemaVersion: 1,
    text: L(
      'Tin này có chi tiêu nên chỉ bạn xem được: mình để trong cuộc trò chuyện riêng của bạn, không hiện trong cuộc trò chuyện chung của bé.',
      'This message mentions money, so only you can see it: it’s in your private chat, not in the baby’s shared chat.',
    )[locale],
    code: 'SPENDING_PRIVATE',
  };
}

type NoticeCode =
  | 'MODULE_UNAVAILABLE'
  | 'WRITE_DENIED'
  | 'VALIDATION_FAILED'
  | 'READ_DENIED'
  | 'MEDICINE_NOT_SCHEDULED'
  | 'DUPLICATE_SUSPECTED'
  | 'PREVIOUS_SAVED'
  | 'CORRECTION_APPLIED';

const notices: Record<NoticeCode, { vi: string; en: string }> = {
  MODULE_UNAVAILABLE: L(
    'Mục này chưa ghi được qua trò chuyện. Bạn có thể mở mục tương ứng để ghi trực tiếp.',
    'This can’t be saved from chat yet. You can open the matching section to add it directly.',
  ),
  WRITE_DENIED: L(
    'Vai trò của bạn chỉ xem được, không ghi được mục này.',
    'Your role can view but not add this.',
  ),
  VALIDATION_FAILED: L(
    'Có một phần mình chưa hiểu rõ để tạo bản nháp.',
    'Part of this was not clear enough to prepare a draft.',
  ),
  READ_DENIED: L(
    'Vai trò của bạn không xem được nhật ký chăm sóc.',
    'Your role cannot see the care log.',
  ),
  MEDICINE_NOT_SCHEDULED: L(
    'Mình không đặt lịch cho thuốc. Nếu cần, bạn tự thêm nhắc việc trong mục Nhắc việc và hỏi bác sĩ về liều dùng.',
    'I don’t schedule medicine. If you need it, add a reminder yourself in Reminders and ask the doctor about doses.',
  ),
  DUPLICATE_SUSPECTED: L(
    'Có thể trùng với một mục vừa ghi. Bạn kiểm tra trước khi lưu nhé; mình không tự gộp.',
    'This may duplicate something just logged. Check before saving; nothing is merged automatically.',
  ),
  PREVIOUS_SAVED: L(
    'Mục trước đã được lưu nên mình không đổi nó. Bạn mở mục đó để sửa nhé.',
    'The previous item is already saved, so it isn’t changed here. Open it to edit.',
  ),
  CORRECTION_APPLIED: L(
    'Mình đã sửa theo ý bạn và bỏ bản nháp trước.',
    'Corrected; the previous draft was set aside.',
  ),
};

const writeDenied: Partial<Record<DraftKind, { vi: string; en: string }>> = {
  expense: L(
    'Vai trò của bạn chưa được ghi Chi tiêu, nên mình không tạo khoản chi.',
    'Your role can’t record expenses, so no expense was prepared.',
  ),
  reminder: L(
    'Chỉ Cùng nuôi tạo được nhắc việc, nên mình không tạo nhắc việc.',
    'Only co-parents can create reminders, so no reminder was prepared.',
  ),
};

const codes = new Set<string>([
  'MEDICINE_NOT_SCHEDULED',
  'DUPLICATE_SUSPECTED',
  'PREVIOUS_SAVED',
  'CORRECTION_APPLIED',
]);

/** One notice part per (code, kind), in the task's language; new codes carry `code` / `link`. */
export function noticePart(
  n: { code: NoticeCode; kind?: DraftKind | undefined; link?: string | undefined },
  locale: Locale,
): AssistantPart {
  const words =
    n.code === 'WRITE_DENIED' && n.kind && writeDenied[n.kind]
      ? writeDenied[n.kind]!
      : notices[n.code];
  return {
    type: 'text',
    schemaVersion: 1,
    text: words[locale],
    ...(codes.has(n.code) ? { code: n.code as 'DUPLICATE_SUSPECTED' } : {}),
    ...(n.link ? { link: n.link } : {}),
  };
}
