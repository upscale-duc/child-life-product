# Lumi: product review and plan (2026-10-19)

**Owner request (2026-10-19):** "Hãy như product management, product owner phân tích toàn bộ các
tính năng của toàn bộ hệ thống để cải thiện cái trợ lý Lumi để tạo kết nối toàn bộ chức năng và
tiện cho người dùng … encourage người dùng xài trợ lý Lumi nhiều hơn và tạo ra giá trị cho người
dùng hơn … con ngủ rồi họ mới muốn bắt đầu log giờ, vì con ngủ họ mới rảnh … tạo sự kết nối nhiều
hơn giữa các flow, hiệu năng tốt hơn, nhanh chóng và mượt mà." Recorded as **D-088**. The choices
marked **P-167** are product defaults the owner can overturn; the open questions are in §9.

**Sources**
- Lumi today: server `firebase/functions/src/assistant*.ts`, shared rules
  `packages/contracts/src/assistant-text.ts`, app `apps/mobile/lib/features/assistant/`.
- The device case of 2026-10-19 11:21–11:27 (screenshot in the owner's message, §2).
- Test runs: `docs/assistant/test-report-lumi-2026-10-16.md`, `docs/assistant/eval-2026-10-15.md`,
  the replay fixtures in `apps/mobile/test/features/assistant_replay/fixtures/`.
- Decisions: D-075, D-076 (#11–#13), D-081, D-083, D-085/D-086; proposals P-155–P-161.

## 1. Where we start

**What Lumi does well.** One message becomes reviewed drafts that save in one tap: bottle, breast,
sleep, observation, pump, diaper, growth with head (`assistant-tools.ts:57-76`); sleep and breast
timers started or stopped from chat (`assistant-timers.ts`); one-off reminders with an assignee;
expenses from text or a receipt photo, kept in my private thread (D-075 #2); sleep-concern guidance
and meal ideas from reviewed content; a free health path before any model call
(`assistant.ts:361`); voice dictation; a shared thread per baby.

**What it can reach.** a = create, b = answer about it, c = open it from the chat.

| Area                                   | a                          | b                                     | c                                       |
| -------------------------------------- | -------------------------- | ------------------------------------- | --------------------------------------- |
| Feeds (bottle, breast)                 | ✓                          | ✓ one day's count / ml / minutes      | ✓ record, history                       |
| Sleep                                  | ✓ incl. timer start / stop | ✓ `care_summary`, `sleep_facts`       | ✓ record, timer                         |
| Pump, diaper                           | ✓                          | ✗ (`careSummary` skips them)          | history only                            |
| Growth                                 | ✓                          | ✗                                     | history filter, not the chart           |
| Reminders                              | ✓ one-off                  | ✗                                     | the list, not the new reminder          |
| Chi tiêu                               | ✓ text, photo              | ✗ no month total / budget             | ✓                                       |
| Nhịp lớn lên                           | ✓ observation, plan        | ✓ sleep concern                       | ✓                                       |
| Sổ tiêm chủng                          | ✗                          | ✗                                     | ✗                                       |
| Mốc, Kỷ niệm (album, card, video)      | ✗ (`new_skill` → Rhythm)   | ✗                                     | ✗                                       |
| Ăn dặm (D-085/086)                     | ✗ (`meal` kind off)        | meal ideas ignore the diary           | ✗                                       |
| Dinh dưỡng, Giai đoạn, Thư viện, Sơ cứu | ✗                          | ✗                                     | ✗ ("Thư viện" opens `/rhythm`, health opens `/rhythm/health`) |
| Thống kê, weekly summary               | –                          | partly (`sleep_facts`)                | ✗                                       |

Links the chat may open are limited to records, spending, reminders, rhythm and history
(`assistant_labels.dart:359-427`; `moduleRoute` allows `/care*`, `/rhythm*` only,
`assistant_screens.dart:4384-4411`).

**Where people meet Lumi.** The floating button on the Hôm nay root (`home_shell.dart:200`) and the
Chi tiêu entry (`spending_screens.dart:309`). The Today card was removed (D-076 #13). No other module,
notification, quick log or running timer opens Lumi, although `IntentHint` already has care,
reminder, question and meal (`assistant_models.dart:135`); only `expense` is used.

**How long a log takes.** One typed log ("bé bú 120ml lúc 8h") makes 3 callable round trips
(`quoteTask`, `startTask`, `getAssistantTask`), a Firestore trigger hop, about 12 sequential reads
and transactions, and one `gpt-4.1-mini` call of p50 2.4 s / p95 4.1 s (≈ 3 800 prompt tokens).
Roughly **4–6 s warm**; no function has `minInstances`, so a cold start adds seconds. There is no
rule-based path for routine logs: every feed goes to the model.

## 2. The case of 2026-10-19 (and why it matters)

The parent logs when the baby has just fallen asleep, because that is when their hands are free.
Lumi failed three times in a row:

| What they wrote                              | What Lumi did                                   | Root cause                                                                                                                                                                                                                                                                                         |
| -------------------------------------------- | ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| "Bé đang ngủ. Vừa ngủ được 5p rồi"           | A finished sleep 11:21–11:26 · 5 phút           | Any duration cancels a sleep start: `careStatesIn` drops the start when it sees "ngủ được" + a length (`contracts/src/assistant-text.ts:948`, made for "vừa ngủ dậy, ngủ được 2 tiếng"); `timerPlan` returns no timer when a length is known (`functions/src/assistant-text.ts:602`); "vừa" then reads as "ended now". |
| "Đang ngủ và ngủ cách đây 5p"                | "11:21 là buổi sáng hay chiều tối?"             | "cách đây" is not an "ago" phrase (`agoIn` knows only "trước/ago"), so 5p is a length again; the model's own clock 11:21 has no morning/evening word, and a 23:21 start also fits the 18 h window (`resolveStartBefore`), so the server asks — at 11:26, about a time 5 minutes ago.                    |
| "Sáng. Hiện tại thì biết sáng hay tối chứ"   | The generic help text                           | The morning/evening question allows no typed answer (`allowText: false`, `assistant-text.ts:1585`), so the words start a new task; it has nothing to log and gets `helpPart` while the first task still waits.                                                                                         |

None of these is in the replay fixtures and `known_failures.json` is empty. The pattern is the
lesson: **a parent's message describes the baby's state now** ("đang ngủ", "đang bú", "vẫn chưa
dậy"), **often with how long it has lasted**, and Lumi must turn it into a running timer started in
the past — never a question about what the clock already says.

## 3. Principles (P-167)

1. **Log when you are free.** Every "đang …" (sleep, breastfeeding, pumping) with "được X / cách đây
   X / từ Xh / lúc Xh" starts the app's timer at that moment; the end comes later from "bé dậy rồi",
   the timer or a notification. A finished span is made only when the words say it ended ("dậy",
   "xong", "từ … đến …").
2. **Never ask what the phone knows.** No morning/evening question for a relative time, a time
   within the last few hours, or a clock the length already fixes. Today's date, the baby's zone and
   the running timers are known.
3. **Any words answer the open question.** While my latest task waits on a question, what I type is
   its answer (re-asked if unreadable), never a new task and never the help text.
4. **Lumi knows what the app knows.** Every module a parent can open, Lumi can answer about (read
   tools at 0 model cost where possible), log into, and open from the chat.
5. **Every answer has a next step.** After a save: the next useful thing (open the chart, see the
   day, stop the timer, remind the next feed) as one chip — never a dead end, never a credit line
   (D-081).
6. **Fast first.** Routine logs are read by rules on the server (and drawn optimistically on the
   phone); the model handles only what rules cannot.

## 4. Phase 1 — Right and fast (the trust fixes)

**4.1 Ongoing states and backdated starts.** In `careStatesIn` / `timerPlan`:
- A present-tense marker ("đang ngủ", "vẫn đang ngủ", "ngủ được X rồi", "đang bú", "đang hút") with
  no wake/finish word → `start` with `at = now − X` (or the said clock), even when a length is said.
- `agoIn` reads "cách đây X", "X rồi", "được X rồi", "khoảng X trước".
- "Vừa ngủ dậy, ngủ được 2 tiếng" (sl-08) stays a finished sleep.
- The timer card says "Bắt đầu lúc 11:21 · đã 5 phút" with "Lưu và bắt đầu đếm"; a running timer
  of the same kind gets "Đang đếm từ 11:20" instead of a second one (on-07 already).

**4.2 No question the clock answers.** `clockOf` / `resolveStartBefore`: a clock the model computed
from a relative phrase is never open; a known length fixes the start (end − length ± 10 min); a clock
within 6 h before now takes today's reading. The morning/evening question stays only for a written
hour 1–11 far from now ("ngủ lúc 9h" at 15:00).

**4.3 Typed answers.** `time.ampm` and every choice question accept text (sáng / trưa / chiều / tối /
đêm / am / pm, a clock, "không", "huỷ"); the app sends typed words as the answer while my own latest
task waits (`send()` in `assistant_controller.dart`), with a small "Trả lời câu hỏi trên" hint in the
composer. The server never answers help while a question is open: it re-shows the question.

**4.4 Speed.** Targets: a routine log's card in **≤ 1.5 s p50 / ≤ 3 s p95** warm; any message ≤ 5 s p95.
- A rule-based reader for routine logs before the model (bottle ml + time, breast minutes + side,
  diaper wet/dirty, sleep start/stop/span, pump ml, weight/length/head) feeding `planTextIntents`;
  the model is called only when rules leave something unread.
- Text skips `quoteTask` (`startTask` quotes inline; it re-checks the gates already).
- `minInstances: 1` for `startTask`, `runAssistantTask`, `getAssistantTask` (dev 0, prod 1; billing
  needs owner approval). The worker trigger stops waking on its own writes.
- The app draws from its listeners and calls `getAssistantTask` only on reconnect or a gap.
- Parallel reads in `startTask` and the worker; `max_completion_tokens` 1600 → 400; the prompt sends
  the calendar and categories only when relevant.
- The phone shows an optimistic draft card from the same rules (marked "Đang kiểm tra…") that the
  server version replaces in place.

**4.5 Tests.** New fixtures: "đang ngủ … được 5p", "ngủ cách đây 5p", "bé ngủ từ 11h20", "đang bú bên
trái được 10 phút", typed "Sáng" to an open question, a log with a timer already running; live cases
only for these (the Lumi live-cost rule). A latency check in the eval report (p50/p95 per hop).

## 5. Phase 2 — Lumi knows the whole app (reads)

Server read tools, each a typed answer card with a link (no model when the question is recognised):

| Question                                            | Answer card                                                    | Opens                  |
| --------------------------------------------------- | -------------------------------------------------------------- | ---------------------- |
| "Hôm nay bé thế nào?"                               | The day: feeds, sleep total, diapers, pump, last of each, what runs now | Hôm nay / Thống kê     |
| "Bé thay mấy tã?", "hút được bao nhiêu?"            | Counts and totals today / 7 days                               | Lịch sử filtered       |
| "Bé nặng bao nhiêu, có chuẩn không?"                | Last measurement, WHO percentile, trend (never a diagnosis)    | `/care/growth`         |
| "Bé ngủ được bao lâu rồi?"                          | The running timer                                              | the timer              |
| "Sắp tới bé tiêm gì?"                               | Next doses and due dates by the family's schedule (D-084)      | Sổ tiêm chủng          |
| "Hôm nay có nhắc gì?"                               | Today's reminders and who has them                             | the reminder           |
| "Tháng này tiêu bao nhiêu?"                         | Month total by category, private thread only (D-075 #2)        | Chi tiêu               |
| "Bé đã ăn thử những gì?"                            | Foods tried, reactions (D-085/086)                             | Ăn dặm                 |
| "Bé biết làm gì rồi?", "tháng này bé nên …"         | Milestones reached and next ones; the stage page               | Mốc / Giai đoạn        |
| "Bé sốt / sặc / ngã thì làm gì?"                    | Health support with the first-aid guide                        | Sơ cứu (not `/rhythm/health`) |
| "Bài về …"                                          | Up to 3 library articles for the baby's age and country (D-087) | Thư viện bài           |

`meal_ideas` reads the solids diary (tried foods, reactions, allergens) instead of an empty list.

## 6. Phase 3 — Lumi does what the app does (writes)

- **Ăn dặm meals** from chat ("trưa bé ăn cháo bí 3 thìa, lần đầu ăn bí") → a meal draft with first
  tries; turns the `meal` kind on.
- **Vaccines**: "bé tiêm 6in1 mũi 1 hôm nay" marks the dose; "dời mũi … sang thứ 6" moves it.
- **Mốc**: "bé biết lật rồi" → save the milestone, offer "Tạo thẻ kỷ niệm" with a photo.
- **Kỷ niệm**: a baby photo sent to Lumi → "Lưu vào album" (no reading, no credits).
- **Edit and undo**: "sửa cữ vừa rồi thành 150ml", "xoá giấc vừa ghi", "bé dậy rồi" (stops the
  running timer, no question), "thêm 10 phút".
- **Recurring reminders**: "nhắc uống vitamin D 9h sáng mỗi ngày" (rules already exist in
  Reminders).
- **Temperature / medicine**: stays out until a module exists (prescriptions keep the notice).

## 7. Phase 4 — Lumi everywhere (entry points and next steps)

- **Next-step chips after a save** (one or two, by kind): sleep → "Xem nhịp hôm nay", "Nhắc khi bé
  ngủ quá 2 giờ"; feed → "Nhắc cữ tiếp lúc 11:00"; growth → "Xem biểu đồ"; meal → "Món thử tiếp";
  expense → "Xem tháng này".
- **Entries from modules** through `IntentHint`: a Lumi field on the care history, the solids diary,
  reminders, vaccines and the timer screen ("Nói với Lumi"); the "+" quick log gets "Nói nhanh với
  Lumi" with the mic.
- **From notifications**: a running sleep timer's notification asks "Bé dậy chưa?" with "Dậy rồi" /
  "Vẫn ngủ"; a feed reminder opens Lumi with "Bé vừa bú…" prefilled.
- **Home**: the Lumi button stays on Hôm nay; a one-line "Hỏi Lumi: …" suggestion appears on the
  module screens' empty states only (no Home card, D-076 #13).
- **Proactive, gently**: after 2 logs in Lumi, a tip "Lần sau chỉ cần nói ‘bé ngủ rồi’"; no
  unsolicited AI messages, no credits (D-081).
- **Links**: the allowlist opens every module the read cards name (library, first aid, vaccines,
  milestones, solids, nutrition, growth chart, stats); the wrong "Thư viện" and health links are fixed.

## 8. Credits and measures

- Rule-read logs, read cards and app actions (stop a timer, mark a dose, save a photo) cost **0**;
  model calls keep the D-075 pool. This makes the fast path also the cheap path.
- Measures (counts only, never message content or child data): share of care logs made through Lumi;
  message → saved record rate; questions per log; dead ends (help after a question, unsupported);
  time to card p50/p95; weekly Lumi users; next-step chip taps.

## 9. Open questions for the owner

1. Proposed order: Phase 1 now (one slice), Phase 2 reads and Phase 4 next steps together, Phase 3
   per module. Agree?
2. Rule-read logs and read cards at 0 credits (§8)?
3. `minInstances: 1` in prod for three functions (a small fixed monthly cost)?
4. Notification actions on a running sleep timer ("Bé dậy chưa?") — wanted?
5. Lumi entries inside module screens (history, solids, reminders, vaccines, timer) — all, or some?

## 10. Slices

| Slice | Content                                                         | Size | Touches                                                            |
| ----- | --------------------------------------------------------------- | ---- | ------------------------------------------------------------------ |
| L1    | §4.1–4.3 ongoing states, no needless questions, typed answers   | M    | contracts `assistant-text.ts`, functions `assistant-text.ts`, app controller; fixtures |
| L2    | §4.4 speed: rule reader, no quote for text, fewer round trips   | L    | `assistant.ts`, worker, app controller/repository; `minInstances` needs approval |
| L3    | §5 read cards + links                                           | L    | new read tools, answer cards, link allowlist                       |
| L4    | §7 next-step chips and module entries                           | M    | app only (+ server chip hints)                                     |
| L5…   | §6 writes per module (solids, vaccines, milestones, edit/undo)  | M each | server writers + drafts                                         |
