import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import {
  addDaysIso,
  daysBetweenIso,
  draftPayloadSchema,
  draftProblems,
  expenseCurrencySupported,
  localDateIn,
  noteActions,
  otherCategoryId,
  reminderAssigneeRoles,
  reminderAssigneeSupported,
  reminderNeedsTime,
  weekdayMatches,
  type AssistantError,
  type AssistantPart,
  type Clarification,
  type DraftPayload,
  type TaskOutcome,
} from '@child-life/contracts';
import {
  assistantFlagOn,
  memberOf,
  taskRef,
  type ScopeMember,
  type TrustedScope,
} from './assistant-common.js';
import { loadTaskImages, type AttachmentStore } from './assistant-attachments.js';
import {
  imagePromptVersion,
  parseImageReading,
  type ImageReading,
  type NoteLineReading,
  type ReceiptReading,
} from './assistant-image-model.js';
import {
  canCreateReminders,
  canRecordSpending,
  expenseIdForDraft,
  imageReviewFields,
} from './assistant-image-rules.js';
import { callWithTimeout, ModelUnavailable, type ModelGateway } from './assistant-model.js';
import type { StoredTask } from './assistant-store.js';
import { anchorOf, needsPeriod, type PreparedDraft } from './assistant-tools.js';
import { expenseDuplicateSuspected, householdBabyIds } from './assistant-writers-images.js';
import { chargeAi } from './staff.js';

/**
 * Child Life Assistant, slice A3: photo tasks in the worker (brief p.14–15, CH09–CH14, J03–J05).
 *
 * Order: the scope, flags, health rule, consent and the live model were checked by the worker;
 * here the photos are re-checked and decoded BEFORE the provider (M06), the provider reads them
 * once (`readImages`, strict schema), and the reading is cached server-side
 * (`assistantTasks/{t}/imageReading/current`, never client-readable, deleted when the task leaves
 * `awaiting_clarification`) so a clarification never re-sends a photo or charges again.
 *
 * Decisions (server, deterministic — the model never decides):
 * - unreadable → no drafts, credits released, "chụp lại hoặc nhập tay" (I01, J05);
 * - receipt → ONE expense draft with the printed total only (never subtotal + tax), whole VND;
 *   another currency stays in review (Q-077); an uncertain date blocks confirm until confirmed
 *   (I02, CH11); a suspected duplicate in the household is a warning to acknowledge (I03);
 * - note → per-line classification; only action candidates, only into one-off reminders, only
 *   after the person explicitly chooses "Lưu thành nhắc việc" (no Tasks module, I06, CH13);
 *   a weekday that does not match the date is asked, never picked (G03, I07); no time → an
 *   all-day reminder (D-075 #5; never a silent 09:00); a name written next to a line is never
 *   turned into a uid: the person picks the assignee among the members who may receive
 *   reminders, or nobody (D-075 #5); medicine lines, remarks and unclear lines are listed as
 *   excluded and never scheduled;
 * - mixed (e.g. receipt + prescription) → ask what to do; prescription only → nothing scheduled.
 * Credits: committed only when at least one draft exists (readable, actionable result); a
 * question holds them; unreadable, refused, declined or nothing actionable → released.
 */

export interface ImageWorkDeps {
  db: Firestore;
  now: Date;
  gateway: ModelGateway;
  files: AttachmentStore | undefined;
  timeoutMs?: number | undefined;
}

/** What the worker settles for a photo task (see `finalize` in assistant-worker.ts). */
export interface ImageWork {
  outcome: TaskOutcome;
  errorCode: AssistantError | null;
  drafts: PreparedDraft[];
  parts: AssistantPart[];
  /** A server-catalog question (its id is assigned at settle). */
  ask: Clarification | null;
  /** Ready but nothing to save (declined, nothing actionable): credits released. */
  releaseReady: boolean;
  /** The normalized reading to cache while asking (null → nothing to keep). */
  reading: StoredReading | null;
  modelCalls: number;
}

/** What is kept of a reading between clarification rounds (no medicine text, no raw OCR). */
export interface StoredReading {
  reading: ImageReading;
  sha256s: string[];
  keepReceipt: boolean;
  promptVersion: string;
}

const L = (vi: string, en: string) => ({ vi, en });
type Locale = 'vi' | 'en';

const t = {
  unreadable: L(
    'Ảnh hơi mờ nên mình chưa đọc chắc được. Bạn chụp lại gần hơn, đủ sáng, hoặc nhập tay nhé.',
    'The photo is too blurry to read reliably. Retake it closer and in good light, or type it in.',
  ),
  refused: L(
    'Tệp này không phải ảnh đọc được nên mình không gửi đi đọc.',
    'This file isn’t a readable image, so it wasn’t sent for reading.',
  ),
  gone: L(
    'Ảnh không còn dùng được (đã hết hạn hoặc không thuộc cuộc trò chuyện này).',
    'The photo can’t be used any more (expired or not part of this chat).',
  ),
  prescription: L(
    'Ảnh có thông tin thuốc: mình không tạo lịch hay liều dùng thuốc. Hãy hỏi bác sĩ hoặc dược sĩ.',
    'The photo has medicine information: no medicine schedule or dose is created. Ask your doctor or pharmacist.',
  ),
  mixed: L(
    'Ảnh có nhiều loại nội dung. Mình sẽ không tự xử lý tất cả.',
    'This photo has more than one kind of content. Nothing is handled automatically.',
  ),
  mixedMedicine: L(
    'Phần thuốc trong ảnh sẽ không được chuyển thành lịch hay liều.',
    'The medicine part of the photo is never turned into a schedule or a dose.',
  ),
  nothing: L('Mình không ghi gì từ ảnh này.', 'Nothing was saved from this photo.'),
  spendDenied: L(
    'Vai trò của bạn chưa được ghi Chi tiêu, nên mình không tạo khoản chi.',
    'Your role can’t record expenses, so no expense was prepared.',
  ),
  remindDenied: L(
    'Chỉ Cùng nuôi tạo được nhắc việc, nên mình không tạo nhắc việc từ ảnh này.',
    'Only co-parents can create reminders, so none were prepared from this photo.',
  ),
  noReceipt: L(
    'Mình chưa đọc được phần hoá đơn trong ảnh.',
    'The receipt part of the photo couldn’t be read.',
  ),
  currency: L(
    'Chi tiêu chưa hỗ trợ ngoại tệ: khoản này cần bạn kiểm tra, chưa lưu được với đơn vị tiền này.',
    'Expenses support VND only for now: this one needs checking and can’t be saved in this currency.',
  ),
  noTotal: L(
    'Hoá đơn không in tổng tiền: mình không tự cộng tạm tính và thuế. Bạn nhập tổng nhé.',
    'The receipt has no printed total: subtotal and tax are not added up for you. Please enter the total.',
  ),
  taxIncluded: L(
    'Tổng tiền đã gồm thuế: chỉ ghi một khoản, không cộng thêm tạm tính hay thuế.',
    'The total already includes tax: one expense, subtotal and tax are not added again.',
  ),
  duplicate: L(
    'Có thể trùng với một khoản đã ghi trong gia đình. Kiểm tra trước khi lưu; mình không tự gộp.',
    'This may duplicate an expense your family already logged. Check before saving; nothing is merged automatically.',
  ),
  noActions: L('Mình không thấy việc cần làm nào trong ảnh.', 'No to-dos were found in the photo.'),
  noReminders: L('Không tạo nhắc việc nào.', 'No reminders were created.'),
  // ---- D-075 #5 (reminders): all day and assignee ----
  noAssignee: L(
    'Nhắc việc chưa có người phụ trách: tên ghi trong ảnh không được gán cho ai.',
    'Reminders have no assignee yet: names written in the photo aren’t assigned to anyone.',
  ),
  assigneeLater: L(
    'Tên ghi trong ảnh không tự gán cho ai: bạn chọn người phụ trách khi sửa nhắc việc.',
    'Names written in the photo aren’t assigned automatically: pick who does it when you edit the reminder.',
  ),
  needTime: L(
    'Nhắc việc cần ngày và giờ: bạn chọn trước khi lưu (mình không tự đặt giờ).',
    'Reminders need a date and a time: pick them before saving (no time is set for you).',
  ),
  needDate: L(
    'Nhắc việc cần ngày: bạn chọn trước khi lưu. Không có giờ thì là nhắc cả ngày.',
    'Reminders need a date: pick it before saving. Without a time it’s an all-day reminder.',
  ),
  allDay: L(
    'Việc không ghi giờ được lưu thành nhắc cả ngày, báo theo giờ nhắc cả ngày bạn chọn trong Nhắc việc (mình không tự đặt giờ).',
    'To-dos without a time are saved as all-day reminders, notified at the all-day time you chose in Reminders (no time is set for you).',
  ),
};

const weekdays = {
  vi: ['Chủ nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'],
  en: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
};
const weekdayOf = (date: string) => {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay();
};
const dm = (date: string) => `${date.slice(8, 10)}/${date.slice(5, 7)}`;
const clip = (s: string, n = 60) => (s.length > n ? `${s.slice(0, n - 1)}…` : s);

// ---------- Clarification catalog (photos): the model never writes a question ----------

export function imageIntentQuestion(contains: readonly string[]): Clarification {
  const choices: Clarification['choices'] = [];
  if (contains.includes('receipt')) {
    choices.push({ id: 'expense', label: L('Ghi chi tiêu', 'Log expense') });
  }
  if (contains.includes('note')) {
    choices.push({ id: 'reminders', label: L('Lưu thành nhắc việc', 'Save as reminders') });
  }
  choices.push({ id: 'none', label: L('Không làm gì', 'Nothing') });
  return {
    id: 'pending',
    field: 'image.intent',
    question: L('Bạn muốn làm gì với ảnh này?', 'What would you like to do with this photo?'),
    choices,
    allowText: false,
  };
}

export function noteConvertQuestion(): Clarification {
  return {
    id: 'pending',
    field: 'note.convert',
    question: L(
      'Chưa có mục Công việc. Lưu các việc cần làm thành nhắc việc?',
      'There’s no Tasks section yet. Save the to-dos as reminders?',
    ),
    choices: [
      { id: 'reminders', label: L('Lưu thành nhắc việc', 'Save as reminders') },
      { id: 'none', label: L('Không lưu', 'Don’t save') },
    ],
    allowText: false,
  };
}

/** The date of [weekday] nearest to [date] (within 3 days), or null. */
export function nearestWeekday(date: string, weekday: number): string | null {
  for (let i = 1; i <= 3; i++) {
    for (const d of [addDaysIso(date, -i), addDaysIso(date, i)]) {
      if (weekdayOf(d) === weekday) return d;
    }
  }
  return null;
}

/** G03: "Thứ Hai 20/10" in 2026 (a Tuesday) → ask which day, never pick for the person. */
export function reminderDateQuestion(index: number, line: NoteLineReading): Clarification {
  const date = line.date!;
  const written = line.weekday!;
  const other = nearestWeekday(date, written);
  const title = clip(line.title.trim(), 50);
  const choices: Clarification['choices'] = [
    {
      id: 'written',
      label: L(
        `${weekdays.vi[weekdayOf(date)]} ${dm(date)}`,
        `${weekdays.en[weekdayOf(date)]} ${dm(date)}`,
      ),
    },
  ];
  if (other) {
    choices.push({
      id: 'weekday',
      label: L(`${weekdays.vi[written]} ${dm(other)}`, `${weekdays.en[written]} ${dm(other)}`),
    });
  }
  choices.push({ id: 'later', label: L('Chọn sau', 'Pick later') });
  return {
    id: 'pending',
    field: `reminder.date.${index}`,
    question: L(
      `“${title}” ghi ${weekdays.vi[written]} nhưng ${dm(date)} là ${weekdays.vi[weekdayOf(date)]}. Bạn muốn nhắc ngày nào?`,
      `“${title}” says ${weekdays.en[written]}, but ${dm(date)} is a ${weekdays.en[weekdayOf(date)]}. Which day should the reminder be?`,
    ),
    choices,
    allowText: false,
  };
}

// ---- D-075 #5: who does a note line (reminders) ----

/** Members who may be assigned a reminder (`reminderAssigneeRoles`), the asker first. */
export async function assignableMembers(
  db: Firestore,
  s: Pick<TrustedScope, 'babyId' | 'uid'>,
  now: Date,
): Promise<ScopeMember[]> {
  const snaps = await db.collection(`babies/${s.babyId}/members`).get();
  const rank = (m: ScopeMember) => (m.uid === s.uid ? 0 : m.role === 'coParent' ? 1 : 2);
  return snaps.docs
    .map((d) => memberOf(d, now))
    .filter(
      (m): m is ScopeMember =>
        m !== null &&
        (reminderAssigneeRoles as readonly string[]).includes(m.role) &&
        // A choice id is at most 40 characters; 'none' is "Không giao".
        m.uid.length <= 40 &&
        m.uid !== 'none',
    )
    .sort((a, b) => rank(a) - rank(b) || a.displayName.localeCompare(b.displayName))
    .slice(0, 5);
}

/**
 * "Ảnh ghi “Mẹ” cạnh “Đặt lịch khám”. Giao việc này cho ai?": the written name is shown, never
 * matched to a member; the person picks one of the eligible members or nobody.
 */
export function reminderAssigneeQuestion(
  index: number,
  line: NoteLineReading,
  members: readonly ScopeMember[],
  meUid: string,
): Clarification {
  const title = clip(line.title.trim(), 50);
  const written = clip((line.assigneeText ?? '').trim(), 20);
  const name = (m: ScopeMember, locale: Locale) =>
    m.displayName.trim() ||
    (m.role === 'caregiver' ? L('Người chăm sóc', 'Caregiver') : L('Cùng nuôi', 'Co-parent'))[
      locale
    ];
  return {
    id: 'pending',
    field: `reminder.assignee.${index}`,
    question: L(
      `Ảnh ghi “${written}” cạnh “${title}”. Giao việc này cho ai?`,
      `The photo says “${written}” next to “${title}”. Who should do it?`,
    ),
    choices: [
      ...members.map((m) => ({
        id: m.uid,
        label:
          m.uid === meUid
            ? L(`Bạn (${name(m, 'vi')})`, `You (${name(m, 'en')})`)
            : L(name(m, 'vi'), name(m, 'en')),
      })),
      { id: 'none', label: L('Không giao', 'No one') },
    ],
    allowText: false,
  };
}
// ---- end D-075 #5 ----

// ---------- Run ----------

const empty = (over: Partial<ImageWork>): ImageWork => ({
  outcome: { kind: 'drafts', items: [] },
  errorCode: null,
  drafts: [],
  parts: [],
  ask: null,
  releaseReady: false,
  reading: null,
  modelCalls: 0,
  ...over,
});

const say = (text: { vi: string; en: string }, locale: Locale): AssistantPart => ({
  type: 'text',
  schemaVersion: 1,
  text: text[locale],
});

/** Refused before / without a useful reading: failed with [code], credits released. */
const refuse = (code: AssistantError, parts: AssistantPart[], modelCalls = 0): ImageWork =>
  empty({
    outcome: { kind: 'rejected', detail: code },
    errorCode: code,
    parts,
    modelCalls,
  });

/** Ready with nothing to save (declined, nothing actionable, medicine only): released. */
const nothingToSave = (parts: AssistantPart[], modelCalls: number): ImageWork =>
  empty({ releaseReady: true, parts, modelCalls });

export const readingRef = (db: Firestore, taskId: string) =>
  taskRef(db, taskId).collection('imageReading').doc('current');

/** Answers of earlier rounds by field (choice id or text). */
const answersOf = (task: StoredTask) =>
  new Map(
    (task.clarifications ?? [])
      .filter((c) => c.answer !== null)
      .map((c) => [c.field, c.answer!.choiceId ?? c.answer!.text ?? ''] as const),
  );

export async function processImageTask(
  deps: ImageWorkDeps,
  task: StoredTask,
  s: TrustedScope,
): Promise<ImageWork> {
  const { db, now } = deps;
  const locale = task.locale;
  if (!assistantFlagOn(s, 'assistant_images')) return refuse('FEATURE_DISABLED', []);
  if (!deps.files) return refuse('MODULE_UNAVAILABLE', []);
  const answers = answersOf(task);

  let stored: StoredReading | null = null;
  let modelCalls = 0;
  if ((task.round ?? 0) > 0) {
    const cached = await readingRef(db, task.id).get();
    if (cached.exists) stored = cached.data() as StoredReading;
  }
  if (!stored) {
    if (!deps.gateway.readImages) return refuse('AI_UNAVAILABLE', []);
    // M06: photos re-checked and decoded before anything reaches the provider.
    const loaded = await loadTaskImages(db, deps.files, task, now);
    if (!loaded.ok) {
      return refuse('VALIDATION_FAILED', [
        say(loaded.reason === 'invalid_image' ? t.refused : t.gone, locale),
      ]);
    }
    const quote = task.quoteId ? await db.doc(`assistantQuotes/${task.quoteId}`).get() : null;
    const hint = (quote?.get('intentHint') as StoredHint | undefined) ?? null;
    let raw: unknown;
    const gateway = deps.gateway;
    try {
      raw = await callWithTimeout(
        (signal) =>
          gateway.readImages!(
            {
              images: loaded.images.map((i) => ({
                mime: 'image/jpeg' as const,
                base64: i.jpeg.toString('base64'),
                width: i.width,
                height: i.height,
              })),
              intentHint: hint,
              locale,
              anchor: anchorOf(s.zone, task.anchorInstant.toDate()),
            },
            signal,
          ),
        deps.timeoutMs ?? 90_000,
      );
    } catch (error) {
      if (gateway.name === 'openai') await charge(db, now);
      return empty({
        outcome: {
          kind: 'error',
          code:
            error instanceof ModelUnavailable && error.kind === 'timeout'
              ? 'timeout'
              : 'AI_UNAVAILABLE',
        },
        errorCode: 'AI_UNAVAILABLE',
        modelCalls: 1,
      });
    }
    if (gateway.name === 'openai') await charge(db, now);
    modelCalls = 1;
    const parsed = parseImageReading(raw);
    // Unknown keys (a "tool", a URL), kinds or shapes: rejected, never executed, 0 credits.
    if (!parsed.ok) return refuse('VALIDATION_FAILED', [], modelCalls);
    stored = {
      reading: redact(parsed.value),
      sha256s: loaded.sha256s,
      keepReceipt: loaded.keepReceipt,
      promptVersion: imagePromptVersion,
    };
  }
  const work = await decide(deps, task, s, stored, answers);
  return { ...work, modelCalls, reading: work.ask ? stored : null };
}

type StoredHint = 'care' | 'expense' | 'reminder' | 'question' | 'meal';

/** Reading a photo costs about three text calls internally (never shown in the app). */
export const imageReadCostVnd = 900;

async function charge(db: Firestore, now: Date) {
  try {
    await chargeAi(db, now, imageReadCostVnd);
  } catch {
    // The budget counter never fails a task.
  }
}

/** Medicine lines keep their kind only: no text, dose or schedule is kept or shown. */
function redact(r: ImageReading): ImageReading {
  return {
    ...r,
    noteLines: r.noteLines.map((l) =>
      l.kind === 'medicalText'
        ? {
            ...l,
            title: '',
            dateText: null,
            date: null,
            timeText: null,
            time: null,
            assigneeText: null,
          }
        : l,
    ),
  };
}

type Kind = 'unreadable' | 'receipt' | 'note' | 'prescription' | 'mixed';

function kindOf(r: ImageReading): Kind {
  if (r.documentKind === 'unreadable' || r.readability === 'unreadable') return 'unreadable';
  if (r.documentKind === 'receipt') return r.receipt ? 'receipt' : 'unreadable';
  if (r.documentKind === 'note') return r.noteLines.length > 0 ? 'note' : 'unreadable';
  if (r.documentKind === 'prescription') return 'prescription';
  const has = new Set(r.contains);
  const useful = (has.has('receipt') && r.receipt ? 1 : 0) + (has.has('note') ? 1 : 0);
  if (useful === 0) return has.has('prescription') ? 'prescription' : 'unreadable';
  return 'mixed';
}

async function decide(
  deps: ImageWorkDeps,
  task: StoredTask,
  s: TrustedScope,
  stored: StoredReading,
  answers: Map<string, string>,
): Promise<ImageWork> {
  const locale = task.locale;
  const r = stored.reading;
  const kind = kindOf(r);
  switch (kind) {
    case 'unreadable':
      // I01 / J05: nothing invented, nothing charged; retake or type it in.
      return empty({
        outcome: { kind: 'unreadable' },
        errorCode: 'OCR_UNREADABLE',
        parts: [say(t.unreadable, locale)],
      });
    case 'prescription':
      return nothingToSave([say(t.prescription, locale)], 0);
    case 'mixed': {
      const choice = answers.get('image.intent');
      if (choice === undefined) {
        const parts = [say(t.mixed, locale)];
        if (r.contains.includes('prescription')) parts.push(say(t.mixedMedicine, locale));
        return empty({
          outcome: { kind: 'clarification', clarification: imageIntentQuestion(r.contains) },
          ask: imageIntentQuestion(r.contains),
          parts,
        });
      }
      if (choice === 'expense') {
        return r.receipt
          ? receiptDrafts(deps, task, s, stored, r.receipt)
          : nothingToSave([say(t.noReceipt, locale)], 0);
      }
      if (choice === 'reminders') return noteDrafts(deps, task, s, r, answers);
      return nothingToSave([say(t.nothing, locale)], 0);
    }
    case 'receipt':
      return receiptDrafts(deps, task, s, stored, r.receipt!);
    case 'note':
      return noteDrafts(deps, task, s, r, answers);
  }
}

// ---------- Receipt → one expense draft ----------

const digits = (s: string) => s.replace(/\D/g, '');

async function receiptDrafts(
  deps: ImageWorkDeps,
  task: StoredTask,
  s: TrustedScope,
  stored: StoredReading,
  rc: ReceiptReading,
): Promise<ImageWork> {
  const locale = task.locale;
  if (!canRecordSpending(s.member)) {
    return refuse('WRITE_DENIED', [say(t.spendDenied, locale)]);
  }
  const anchor = task.anchorInstant.toDate();
  const today = localDateIn(s.zone, anchor);
  const partial = stored.reading.readability === 'partial';
  const evidence = (f: string) => rc.evidence.find((e) => e.field === f)?.text ?? null;
  const uncertain = new Set<string>();
  const parts: AssistantPart[] = [];

  // The printed TOTAL only; subtotal, tax and discount are informational (brief p.14).
  const total = rc.totalMinor;
  if (total !== null) {
    const ev = evidence('totalMinor');
    // Grounding without locale parsing: the evidence's digits must be exactly the integer.
    if (rc.totalUncertain || partial || !ev || digits(ev) !== String(total)) {
      uncertain.add('totalMinor');
    }
  } else if (rc.subtotalMinor !== null || rc.taxMinor !== null) {
    parts.push(say(t.noTotal, locale));
  }
  const currency = rc.currency;
  if (currency !== null && (rc.currencyUncertain || !evidence('currency')))
    uncertain.add('currency');
  if (currency !== null && !expenseCurrencySupported(currency)) parts.push(say(t.currency, locale));
  const date = rc.documentDate;
  if (date !== null) {
    if (rc.dateUncertain || partial || !evidence('documentDate')) uncertain.add('date');
    if (date > today || daysBetweenIso(date, today) > 366) uncertain.add('date');
  }
  if (total !== null && rc.taxMinor !== null) parts.push(say(t.taxIncluded, locale));
  const merchant = rc.merchant?.trim() ? rc.merchant.trim().slice(0, 120) : null;
  if (merchant !== null && (partial || !evidence('merchant'))) uncertain.add('merchant');

  const payload: DraftPayload = {
    kind: 'expense',
    merchant,
    totalMinor: total !== null && total > 0 ? total : null,
    currency,
    date,
    subtotalMinor: rc.subtotalMinor,
    taxMinor: rc.taxMinor,
    categoryId: rc.categoryHint ?? otherCategoryId,
    babyId: s.babyId,
    keepReceipt: stored.keepReceipt,
  };
  if (total !== null && total <= 0) uncertain.add('totalMinor');
  const checked = draftPayloadSchema.safeParse(payload);
  if (!checked.success) return refuse('VALIDATION_FAILED', [], 0);
  const problems = draftProblems(checked.data, anchor);
  const review = imageReviewFields(checked.data, problems);
  for (const u of review.uncertain) uncertain.add(u);
  for (const m of review.missing) uncertain.delete(m);

  const draftId = `dr_${task.id.slice(3)}_0`;
  const duplicate = await expenseDuplicateSuspected(deps.db, {
    familyId: s.familyId,
    babyIds: await householdBabyIds(deps.db, s.familyId, s.babyId),
    date,
    total: payload.totalMinor,
    // D-075 #4: a duplicate is the same amount in the same currency.
    currency: payload.currency,
    merchant,
    sha256s: stored.sha256s,
    excludeExpenseId: expenseIdForDraft(draftId),
    excludeAttachmentIds: task.input?.attachmentIds ?? [],
  });
  if (duplicate) parts.push(say(t.duplicate, locale));
  return empty({
    outcome: { kind: 'drafts', items: [checked.data] },
    parts,
    drafts: [
      {
        payload: checked.data,
        missingFields: review.missing,
        uncertainFields: [...uncertain].sort(),
        problems,
        warnings: duplicate ? ['duplicate_suspected'] : [],
      },
    ],
  });
}

// ---------- Note → reminder drafts (selected lines only) ----------

const LINK = /(https?:\/\/|www\.|[\w.+-]+@[\w-]+\.[\w.]+|\b[\w-]+\.(com|net|org|vn|io)\b)/i;

async function noteDrafts(
  deps: ImageWorkDeps,
  task: StoredTask,
  s: TrustedScope,
  r: ImageReading,
  answers: Map<string, string>,
): Promise<ImageWork> {
  const locale = task.locale;
  const lines = r.noteLines;
  // A line carrying a link or an address is never a task (photo text is data, brief p.15).
  const classified = lines.map((l) =>
    l.kind === 'actionCandidate' && (LINK.test(l.title) || !l.title.trim())
      ? { ...l, kind: 'unclear' as const }
      : l,
  );
  const excluded = excludedSummary(classified, locale);
  const candidates = classified
    .map((l, index) => ({ ...l, index }))
    .filter((l) => l.kind === 'actionCandidate');
  if (candidates.length === 0) {
    return nothingToSave([...excluded, say(t.noActions, locale)], 0);
  }
  // No Tasks module: reminders only, only for a Cùng nuôi, only on the explicit choice.
  if (!canCreateReminders(s.member)) {
    return refuse('WRITE_DENIED', [...excluded, say(t.remindDenied, locale)]);
  }
  const convert =
    answers.get('note.convert') ??
    (answers.get('image.intent') === 'reminders' ? 'reminders' : undefined);
  if (convert === undefined) {
    const found = L(
      `Mình thấy ${lines.length} dòng. ${candidates.length} dòng có thể thành nhắc việc.`,
      `I found ${lines.length} lines. ${candidates.length} can become reminders.`,
    );
    return empty({
      outcome: { kind: 'clarification', clarification: noteConvertQuestion() },
      ask: noteConvertQuestion(),
      parts: [say(found, locale), ...excluded],
    });
  }
  const selected = noteActions(
    candidates,
    { tasks: false, reminders: true },
    convert === 'reminders',
  );
  if (selected.length === 0) return nothingToSave([say(t.noReminders, locale)], 0);

  const anchor = task.anchorInstant.toDate();
  const today = localDateIn(s.zone, anchor);
  const rounds = task.round ?? 0;
  const drafts: PreparedDraft[] = [];
  // D-075 #5: the members a written name may be given to, read once, only when one is written.
  const assignable =
    reminderAssigneeSupported() && selected.some((l) => l.assigneeText?.trim())
      ? await assignableMembers(deps.db, s, deps.now)
      : [];
  let assigneeLater = false;
  for (const line of selected) {
    let date = line.date;
    const uncertain = new Set<string>();
    if (line.uncertain.includes('title')) uncertain.add('title');
    if (line.uncertain.includes('date')) uncertain.add('date');
    if (line.uncertain.includes('time')) uncertain.add('time');
    if (date !== null && line.weekday !== null && !weekdayMatches(date, line.weekday)) {
      const field = `reminder.date.${line.index}`;
      const answer = answers.get(field);
      if (answer === undefined) {
        // Ask (one question per round, within the cap); past the cap the person picks the date.
        if (rounds < 4) {
          const q = reminderDateQuestion(line.index, line);
          return empty({
            outcome: { kind: 'clarification', clarification: q },
            ask: q,
            parts: [],
          });
        }
        date = null;
      } else if (answer === 'weekday') date = nearestWeekday(date, line.weekday);
      else if (answer === 'later') date = null;
    } else if (date === null && line.weekday !== null) {
      // Only a weekday written ("Thứ Hai"): the next one, marked for review — never silent.
      for (let i = 0; i < 7; i++) {
        const d = addDaysIso(today, i);
        if (weekdayOf(d) === line.weekday) {
          date = d;
          break;
        }
      }
      uncertain.add('date');
    }
    if (date !== null && (date < today || daysBetweenIso(today, date) > 366)) uncertain.add('date');
    const time = line.time;
    if (time !== null && needsPeriod([line.timeText ?? time])) uncertain.add('time');
    // ---- D-075 #5: a name read from the photo is never turned into a uid; the person picks ----
    let assigneeUid: string | null = null;
    if (reminderAssigneeSupported() && line.assigneeText?.trim()) {
      const field = `reminder.assignee.${line.index}`;
      const answer = answers.get(field);
      if (answer === undefined) {
        if (rounds < 4 && assignable.length > 0) {
          const q = reminderAssigneeQuestion(line.index, line, assignable, s.uid);
          return empty({
            outcome: { kind: 'clarification', clarification: q },
            ask: q,
            parts: [],
          });
        }
        assigneeLater = true;
      } else {
        // Re-checked against the members read now (and again at confirm).
        assigneeUid = assignable.find((m) => m.uid === answer)?.uid ?? null;
      }
    }
    const payload: DraftPayload = {
      kind: 'reminder',
      title: line.title.trim().slice(0, 120),
      date,
      time,
      assigneeUid,
    };
    const checked = draftPayloadSchema.safeParse(payload);
    if (!checked.success) continue;
    const problems = draftProblems(checked.data, anchor);
    const review = imageReviewFields(checked.data, problems);
    for (const u of review.uncertain) uncertain.add(u);
    for (const m of review.missing) uncertain.delete(m);
    drafts.push({
      payload: checked.data,
      missingFields: review.missing,
      uncertainFields: [...uncertain].sort(),
      problems,
      warnings: [],
    });
  }
  if (drafts.length === 0) return refuse('VALIDATION_FAILED', excluded, 0);
  const parts = [...excluded];
  // ---- D-075 #5: date-only reminders are all day; say so, never a silent time ----
  if (drafts.some((d) => d.missingFields.length > 0)) {
    parts.push(say(reminderNeedsTime() ? t.needTime : t.needDate, locale));
  }
  if (
    !reminderNeedsTime() &&
    drafts.some((d) => d.payload.kind === 'reminder' && d.payload.time === null)
  ) {
    parts.push(say(t.allDay, locale));
  }
  if (!reminderAssigneeSupported() && selected.some((l) => l.assigneeText)) {
    parts.push(say(t.noAssignee, locale));
  } else if (assigneeLater) {
    parts.push(say(t.assigneeLater, locale));
  }
  return empty({
    outcome: { kind: 'drafts', items: drafts.map((d) => d.payload) },
    drafts,
    parts,
  });
}

/** "Không chuyển thành việc" (CH13): remarks quoted, medicine never repeated (no dose). */
function excludedSummary(lines: readonly NoteLineReading[], locale: Locale): AssistantPart[] {
  const out: string[] = [];
  for (const l of lines) {
    if (l.kind === 'informational' && l.title.trim()) {
      out.push(
        locale === 'vi'
          ? `“${clip(l.title.trim())}”: ghi chú, không phải việc cần làm.`
          : `“${clip(l.title.trim())}”: a note, not a to-do.`,
      );
    }
  }
  const medical = lines.filter((l) => l.kind === 'medicalText').length;
  if (medical > 0) {
    out.push(
      locale === 'vi'
        ? `${medical} dòng về thuốc: không tạo lịch hay liều dùng thuốc. Hỏi bác sĩ.`
        : `${medical} medicine line${medical > 1 ? 's' : ''}: no medicine schedule or dose is created. Ask your doctor.`,
    );
  }
  const unclear = lines.filter((l) => l.kind === 'unclear').length;
  if (unclear > 0) {
    out.push(
      locale === 'vi'
        ? `${unclear} dòng chưa đọc rõ: không chuyển thành việc.`
        : `${unclear} unclear line${unclear > 1 ? 's' : ''}: not turned into to-dos.`,
    );
  }
  if (out.length === 0) return [];
  const head = locale === 'vi' ? 'Không chuyển thành việc:' : 'Not turned into to-dos:';
  return [{ type: 'text', schemaVersion: 1, text: [head, ...out].join('\n') }];
}

/** Settle helper: the reading is kept only while a question is open (then deleted). */
export function writeReadingTx(
  tx: FirebaseFirestore.Transaction,
  db: Firestore,
  taskId: string,
  reading: StoredReading | null,
  now: Date,
): void {
  const ref = readingRef(db, taskId);
  if (reading) tx.set(ref, { ...reading, savedAt: Timestamp.fromDate(now) });
  else tx.delete(ref);
}
