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
  // LUMI-16 (owner 2026-10-16): "mua sữa nào tốt?" is a question, never an expense.
  shopping: L(
    'Mình chưa so sánh hay gợi ý sản phẩm được. Khi đã mua, bạn nhắn “mua sữa hết 500k” để ghi chi tiêu, hoặc “nhắc mai mua sữa” để đặt nhắc việc. Không tính lượt.',
    'I can’t compare or recommend products yet. Once you’ve bought something, send “$20 formula” to log the expense, or “remind me tomorrow to buy formula” for a reminder. No credit was used.',
  ),
};

/** Nothing to log or read: what Lumi can do, never a dead end (0 credits). */
export function helpPart(
  locale: Locale,
  variant: 'help' | 'write' | 'shopping' = 'help',
): AssistantPart {
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

/** What each kind of item is called in a notice (LUMI-13: a dropped item is always named). */
export const kindNames: Record<DraftKind, { vi: string; en: string }> = {
  bottle: L('cữ bú bình', 'bottle feed'),
  breast: L('cữ bú mẹ', 'breastfeed'),
  sleep: L('giấc ngủ', 'sleep'),
  expense: L('khoản chi', 'expense'),
  reminder: L('nhắc việc', 'reminder'),
  observation: L('ghi nhận', 'note'),
  meal: L('bữa ăn', 'meal'),
  timer: L('đồng hồ', 'timer'),
  pump: L('lần hút sữa', 'pumping session'),
  diaper: L('lần thay tã', 'diaper change'),
  growth: L('số đo tăng trưởng', 'growth measurement'),
};

/** Kind-specific words for a notice that names the item (LUMI-13, P2 copy 2026-10-16). */
const namedNotices: Partial<
  Record<NoticeCode, Partial<Record<DraftKind, { vi: string; en: string }>>>
> = {
  MODULE_UNAVAILABLE: {
    meal: L(
      'Ứng dụng chưa có mục ghi bữa ăn, nên mình chưa ghi được bữa ăn này.',
      'The app has no meal log yet, so this meal was not saved.',
    ),
  },
};

const validationNamed = (k: DraftKind) =>
  L(
    `Mình chưa hiểu rõ phần ${kindNames[k].vi} để tạo bản nháp. Bạn nhắn lại rõ hơn giúp mình nhé.`,
    `The ${kindNames[k].en} part was not clear enough to prepare a draft. Could you say it again?`,
  );

/** One notice part per (code, kind), in the task's language; new codes carry `code` / `link`. */
export function noticePart(
  n: { code: NoticeCode; kind?: DraftKind | undefined; link?: string | undefined },
  locale: Locale,
): AssistantPart {
  const words =
    n.code === 'WRITE_DENIED' && n.kind && writeDenied[n.kind]
      ? writeDenied[n.kind]!
      : n.kind && namedNotices[n.code]?.[n.kind]
        ? namedNotices[n.code]![n.kind]!
        : n.code === 'VALIDATION_FAILED' && n.kind
          ? validationNamed(n.kind)
          : notices[n.code];
  return {
    type: 'text',
    schemaVersion: 1,
    text: words[locale],
    ...(codes.has(n.code) ? { code: n.code as 'DUPLICATE_SUSPECTED' } : {}),
    ...(n.link ? { link: n.link } : {}),
  };
}

// ---------- Lumi timers 2026-10-16 ----------

/**
 * "Con đang ngủ" while the sleep timer already runs (or "đang cho bú" while the feed timer
 * runs): say so with its start, and offer to end it (the `timer` stop draft that follows) or to
 * keep it running ("Để tiếp tục" discards that draft). [since] is the local "HH:mm" (with "hôm
 * qua" when it started yesterday).
 */
export function timerRunningPart(
  timer: 'sleep' | 'breast',
  since: { clock: string; yesterday: boolean },
  locale: Locale,
  link: string,
): AssistantPart {
  const at = since.yesterday
    ? L(`${since.clock} hôm qua`, `${since.clock} yesterday`)
    : L(since.clock, since.clock);
  const text =
    timer === 'sleep'
      ? L(
          `Bé đang ngủ, đồng hồ đã tính giờ từ ${at.vi}. Kết thúc giấc ngủ bây giờ, hay để đồng hồ tiếp tục?`,
          `The sleep timer is already running since ${at.en}. End the sleep now, or keep it running?`,
        )
      : L(
          `Cữ bú đang được tính giờ từ ${at.vi}. Kết thúc cữ bú bây giờ, hay để đồng hồ tiếp tục?`,
          `The feed timer is already running since ${at.en}. End the feed now, or keep it running?`,
        );
  return { type: 'text', schemaVersion: 1, text: text[locale], code: 'TIMER_RUNNING', link };
}

/** The same message again while its draft still waits above: nothing new, 0 credits. */
export function sameAsPendingPart(locale: Locale): AssistantPart {
  return {
    type: 'text',
    schemaVersion: 1,
    text: L(
      'Mình đã chuẩn bị mục này ngay ở trên và nó đang chờ bạn lưu. Bạn kiểm tra rồi bấm Lưu ở đó nhé. Không tính lượt.',
      'This is already prepared just above and waiting for you to save it. Check it and tap Save there. No credit was used.',
    )[locale],
    code: 'SAME_AS_PENDING',
  };
}

// ---------- Lumi fixes 2026-10-16 ----------

/**
 * LUMI-05: the app that sent the message cannot show a draft of [kind] (an older build): say what
 * was not prepared and where to add it directly ([link]); the person can also update the app.
 */
export function appUpdatePart(kind: DraftKind, locale: Locale, link: string | null): AssistantPart {
  const words =
    kind === 'timer'
      ? L(
          'Phiên bản ứng dụng này chưa bật được đồng hồ từ trò chuyện. Bạn mở Đồng hồ trong mục Chăm sóc để bắt đầu hoặc kết thúc, hoặc cập nhật ứng dụng để Lumi làm giúp nhé.',
          'This version of the app can’t start or stop a timer from chat. Open the timer in Care, or update the app so Lumi can do it for you.',
        )
      : L(
          `Phiên bản ứng dụng này chưa ghi được ${kindNames[kind].vi} qua trò chuyện. Bạn mở mục Chăm sóc để ghi trực tiếp, hoặc cập nhật ứng dụng nhé.`,
          `This version of the app can’t save a ${kindNames[kind].en} from chat. Add it in Care directly, or update the app.`,
        );
  return {
    type: 'text',
    schemaVersion: 1,
    text: words[locale],
    code: 'APP_UPDATE_NEEDED',
    ...(link ? { link } : {}),
  };
}
