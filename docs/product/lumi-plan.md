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
   the timer or the "Bé dậy chưa?" notification (§7.1). A finished span is made only when the words say it ended ("dậy",
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
- **Warm, not always on** (owner, 2026-10-19: no `minInstances`, keep the functions warm, it is
  cheaper). Text runs the worker inside `startTask` (the Firestore trigger stays for photos, retries
  and the sweep), so one fewer hop and one fewer function to keep warm. A scheduled `warmAssistant`
  sends an empty request to `startTask` and `getAssistantTask` every 5 minutes from 06:00 to 23:59
  Asia/Ho_Chi_Minh (the hours most families log; families abroad, D-087, may meet a cold start at
  night until usage says otherwise); the callables answer a warm-up before any auth or read.
  About 13 000 invocations a month (2 functions × 12 an hour × 18 hours), inside the free tier; no fixed instance cost. The worker trigger
  stops waking on its own writes.
- The app draws from its listeners and calls `getAssistantTask` only on reconnect or a gap.
- Parallel reads in `startTask` and the worker; `max_completion_tokens` 1600 → 400; the prompt sends
  the calendar and categories only when relevant.
- The phone shows an optimistic draft card from the same rules (marked "Đang kiểm tra…") that the
  server version replaces in place.

**L2 status (2026-10-19).** Built and on dev: the rule reader, text without a quote, the worker inside
`startTask` / `submitClarification` with a hand-off to the trigger, `warmAssistant`, parallel reads,
the trimmed prompt; rule-read logs cost 0. Engineering changes to the bullets above: the output cap is
1 100 (400 would cut a 3-feed reply), and the optimistic card is left out (the server card comes back
in well under a second warm). Measurements: `docs/assistant/latency-2026-10-19.md`.

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
- **Entries from some modules** (owner, 2026-10-19: "một số thôi"), through `IntentHint`, where
  people are already logging: the running timer screen ("Nói với Lumi": "bé dậy lúc 9h40", "thêm
  10 phút"), Lịch sử chăm sóc (a field above the list: "sửa cữ vừa rồi", "hôm nay bé bú mấy cữ?"),
  the Ăn dặm diary (a meal in words, D-085) and Chi tiêu (already there). No entry on vaccines,
  library, milestones, Kỷ niệm or settings; the "+" quick log keeps its tiles.
- **"Bé dậy chưa?"** for a running sleep timer, personal and well timed (§7.1); a feed reminder
  opens Lumi with "Bé vừa bú…" prefilled.
- **Home**: the Lumi button stays on Hôm nay; a one-line "Hỏi Lumi: …" suggestion appears on the
  module screens' empty states only (no Home card, D-076 #13).
- **Proactive, gently**: after 2 logs in Lumi, a tip "Lần sau chỉ cần nói ‘bé ngủ rồi’"; no
  unsolicited AI messages, no credits (D-081).
- **Links**: the allowlist opens every module the read cards name (library, first aid, vaccines,
  milestones, solids, nutrition, growth chart, stats); the wrong "Thư viện" and health links are fixed.

### 7.1 "Bé dậy chưa?" (owner, 2026-10-19: "cần cá nhân hoá và thông báo đúng hợp lý")

The timer was started when the baby fell asleep; it often keeps running after the baby woke because
the parent's hands were full again. The notification exists to close the sleep with the right
time, not to judge how long the baby sleeps.

- **Only for the person who started the timer** (or who took it over), on that phone, as a local
  notification scheduled when the timer starts or changes. Nothing goes through the server, so no
  child data leaves the phone (the D-077 device sync keeps it across cold starts).
- **When: from this baby's own sleeps.** The sleep is a nap or a night by its start in the baby's
  zone and the family's night window (default 19:00–06:00). The expected length is the median of
  the same kind over the last 14 days, needing at least 5 of them; it asks at
  **max(median × 1.3, median + 20 min)**, so most babies are already awake and the parent has had
  time to stop it themselves. With fewer than 5 similar sleeps: a nap asks after 2 h 30; a night
  asks only in the morning (next point).
- **Never at night or in quiet hours.** Nothing between the night window and the person's quiet
  hours (EN02 `quietFrom`/`quietTo`); a night sleep still running at the end of the window asks
  once, at the person's usual first log of the morning (median of the last 14 days, else 07:00).
  No sound or vibration in Night care.
- **Once, then at most one more.** Actions: **"Dậy rồi"** stops the timer now; **"Dậy lúc…"** opens
  the timer's end-time picker (the chat's linked times); **"Vẫn ngủ"** asks again once after half
  the expected length (at least 30 min). Stopping, editing or deleting the timer cancels it; a
  second timer of the same kind is never started from it.
- **Words, never a verdict.** "Bé ngủ được 1 giờ 45 phút rồi. Bé dậy chưa?" — no "quá lâu", no
  health language, no credit line (D-081). A sleep longer than the app's 18-hour limit goes to the
  timer's own review, not to this notification.
- **A switch.** "Hỏi khi bộ đếm giấc ngủ còn chạy" in Cài đặt thông báo (EN07), on by default for
  the person who starts a timer; the first notification says it can be turned off there.
- **Later, same rules:** a breastfeeding timer ("Bé còn bú không?") at max(median × 1.5, median +
  10 min), capped at 60 min; not in this slice.
- **Measures:** share of sleep timers closed from the notification, time between the asked time and
  the saved end, and the switch turned off (counts only).

## 8. Credits and measures

- **Decided (owner, 2026-10-19):** rule-read logs, read cards and app actions (stop a timer, mark a
  dose, save a photo) cost **0**; model calls keep the D-075 pool. The fast path is also the free
  path. The usage page ("Chi tiết") lists them as "0 lượt · không tính" like small talk today.
- Measures (counts only, never message content or child data): share of care logs made through Lumi;
  message → saved record rate; questions per log; dead ends (help after a question, unsupported);
  time to card p50/p95; weekly Lumi users; next-step chip taps.

## 9. Owner answers (2026-10-19) and what is still open

1. **Order (agreed):** L1 and L2 first, then L6 "Bé dậy chưa?", then Phase 2 reads together with
   Phase 4 next steps (L3, L4), and Phase 3 writes last, one module at a time (L5…).
2. Rule-read logs and read cards cost **0 lượt** (§8).
3. **No `minInstances`**; keep the functions warm with a scheduled ping instead (§4.4).
4. **"Bé dậy chưa?"** yes, personal and well timed (§7.1).
5. Lumi entries from **some** screens: the timer, Lịch sử chăm sóc, the Ăn dặm diary, Chi tiêu (§7).

## 10. Slices

| Slice | Content                                                         | Size | Touches                                                            |
| ----- | --------------------------------------------------------------- | ---- | ------------------------------------------------------------------ |
| L1    | §4.1–4.3 ongoing states, no needless questions, typed answers   | M    | contracts `assistant-text.ts`, functions `assistant-text.ts`, app controller; fixtures |
| L2    | §4.4 speed: rule reader, no quote for text, worker inside `startTask`, warm-up ping, fewer round trips | L    | `assistant.ts`, worker, a scheduled `warmAssistant`, app controller/repository |
| L3    | §5 read cards + links                                           | L    | new read tools, answer cards, link allowlist                       |
| L4    | §7 next-step chips and module entries                           | M    | app only (+ server chip hints)                                     |
| L5…   | §6 writes per module (solids, vaccines, milestones, edit/undo)  | M each | server writers + drafts                                         |
| L6    | §7.1 "Bé dậy chưa?" local notification and its switch           | M    | app only: timer, `reminder_notifications.dart` device sync, EN07 settings, ARB |

**L1 done (2026-10-19, dev).** Contracts `careStatesIn` (`CareState.sinceMin`, `saysFinished`),
`agoIn` ("cách đây X", "X rồi"), `dayHalfAnswerIn`; functions `timerPlan` (a state still going on
starts its timer `sinceMin` ago, the model's made-up end ignored), `clockOf` (`written`; a
computed clock with a relative phrase is never open), `resolveStartBefore` (length ± 10 min, < 6 h
before the end), `readTypedAnswer` in `submitClarification` (unreadable → the same question again),
`openQuestionInsteadOfHelp` in the worker; app `openQuestionFor` routes composer text to my open
question. Cases `firebase/tests/assistant-e2e/cases/16-care-ongoing-l1.json` (on-10…on-18, live
9/9). The timer card shows "Từ 11:21 · 5 phút" with the existing "Bắt đầu tính giờ ngủ · 11:21"
button; "Lưu và bắt đầu đếm" and "huỷ" as an answer are not done.

## 11. The conversation itself: review and redesign (2026-10-19, afternoon)

**Owner request:** "Hiện tại vấn đề lớn là nó không hiểu được prompt người dùng cho những follow-up
conversation … review và đề xuất cách triển khai mới về chatbox hoạt động tốt hơn." Two device
conversations on dev, 13:54 and 14:00 (after L1 and L2 were deployed):

| Turn                                       | Lumi                                        | What happened on the server (dev task docs, structure only)                        |
| ------------------------------------------ | ------------------------------------------- | ---------------------------------------------------------------------------------- |
| "Bé đã bú bình 180ml"                      | "Việc này lúc mấy giờ?" — **no chips**      | Rule-read task, `awaiting_clarification` `time.missing` with 3 chips (Vừa xong, 30 phút trước, 1 tiếng trước), still open |
| "13:00"                                    | "Bạn muốn xem nhật ký hay ghi thêm?" — no chips | A **new task** (model path): nothing to log → the model's `intent` question; the bottle task is left waiting |
| "Ghi"                                      | "Ok! Mình ở đây khi bạn cần."               | A new task: small talk `ack`                                                       |
| "Hỏi mấy giờ xong ko ghi gì là sao"        | "Bạn muốn xem nhật ký hay ghi thêm?"        | A new task: `intent` again                                                         |
| "Em bé đã thay tã" → "Bây giờ"             | the same two steps                          | the same                                                                           |

Two messages in between (13:59, 14:00) failed with `REGION_UNSUPPORTED`: a care topic (guidance)
is blocked when the family's country is not in `regions.advanced` (`assistant-care.ts:213`). The
family of the test baby is set to a country outside that list; a separate check (§11.4).

### 11.1 Root cause of the dead end: the app never sees the open question

- The server keeps the open question in the task document as **`pendingClarification`** and the
  rounds in `clarifications[]` as `{id, field, round, answer}` (no question, no chips;
  `assistant-worker.ts:1306-1312`). The callable view maps it to `clarification`
  (`assistant-store.ts:110`).
- The e2e harness feeds every typed answer through `submitClarification` (`harness.ts:769-792`);
  only `on-16` sends words as a new message, scripted with a model that returns nothing, so the
  fake suite never meets a real model's `clar: intent` for a bare clock. No case types "Bây giờ".
- The app reads `clarification` from the view, or **`clarifications[].clarification`** from a raw
  document (`assistant_models.dart:2156-2164`), a form the server has never written; its unit test
  (`assistant_test.dart:183`) asserts that invented form. It never reads `pendingClarification`.
  A raw document therefore parses with **`clarification == null`**.
- The Firestore listener on the task document (`assistant_repository.dart:472`) delivers that raw
  task; `mergeTask` lets an incoming task of the **same version** replace the current one
  (`assistant_rules.dart:591-595`). So whichever arrives last wins.
- Before L2: `startTask` returned a `queued` task; the worker ran on the trigger; the events
  listener saw `clarification_required` and called `getAssistantTask`; the view (with the
  question) usually arrived after the raw document and won. Fragile, but it held.
- After L2: `startTask` runs the worker inline and **returns the finished snapshot** (view, with
  the question, events already accepted by the client). The listener then delivers the raw
  document of the same version, replaces the task, and the question is gone: no chips, and
  `openQuestionFor` finds nothing, so the typed "13:00" starts a new task. L1's typed-answer
  routing was never reached. Any app build is affected, because the order of arrival changed on
  the server side.

### 11.2 What the review says about the design

The regression exposed the real limits of the model, which are not L1/L2's:

1. **No conversation state, only tasks.** A message is read on its own; "follow-up" exists only as
   (a) server questions inside one task (≤ 4 rounds) and (b) `previousTurnOf`, the previous task's
   text and drafts, for corrections (`assistant-text.ts:1790`). A bare reply ("13:00", "Bây giờ",
   "Ghi", "sáng", "180 chứ không phải 120") read alone has nothing to log, so it falls to small
   talk, the help text or the `intent` question. The rule reader (L2) does not see the previous
   turn at all.
2. **The open question lives in the client's head.** Only the app decides that typed words answer
   the question (`send()` → `openQuestionFor`). The server will happily start a new task while its
   own question is open in the same conversation for the same author. A notification reply, voice,
   an older app, or a lost listener all break it.
3. **Two sources of truth for a task.** The callable view and the raw Firestore document differ in
   shape, both reach the same state object, and "same version wins" chooses by arrival order.
4. **Questions the phone could answer** (§3.2 already): "Bé đã bú bình 180ml" — past tense, no time —
   asks for a time instead of taking **now** and letting the card's time be edited. The question
   turns a one-message log into a three-message one, and every extra turn is a chance to fall off.
5. **Dead ends read like a chatbot.** "Bạn muốn xem nhật ký hay ghi thêm?" with no chips, "Ok! Mình
   ở đây khi bạn cần." to "Ghi", and the same question again to a complaint. Lumi never says what
   it is waiting for.

### 11.3 The redesign (P-168)

**Principle: the conversation, not the message, is the unit of understanding.** Every message is
first resolved against the state of the conversation for this author; only then is it read.

1. **Dialogue state on the server.** `assistantConversations/{cv}/dialogue/{uid}` written in the
   worker's finalize and on every confirm/discard: the open question (task, field, chips, asked
   at), the drafts still waiting to be saved (kind, key fields, draft ids), the last saved records
   (kind, time, record id, for 30 min), the running timers, the last Lumi answer kind, and the
   last 3 turns compacted to kinds and times (no free text beyond the current message). Replaces
   `previousTurnOf`; expires with the question TTL / 2 hours.
2. **A resolver before any reader.** In `startTask`, before rules or the model, for the author's
   dialogue state:
   - **Answer**: a question is open → the message is its answer (`readTypedAnswer`, else re-ask
     with the chips and "Hoặc gõ: 13:00, vừa xong, 30 phút trước"). The app's `openQuestionFor`
     becomes a hint only; the server is the authority, so voice, notifications and old apps work.
   - **Correction / addition** of a waiting draft or a record saved in the last 30 minutes: "180
     chứ", "bình chứ không phải mẹ", "thêm 10 phút", "lúc 13h mới đúng", "xoá cái vừa ghi" →
     `patchDraft` / an edit draft of the record (Phase 3 §6), never a new log.
   - **Continuation**: "rồi ngủ lúc 10h", "xong rồi bé ngủ" → a new log that inherits the
     previous one's day and order.
   - **Meta**: "là sao", "sao không ghi", "mình gõ rồi mà" → Lumi restates what it is waiting for
     ("Mình đang chờ giờ của cữ bú 180ml — chọn ở trên hoặc gõ giờ") with the chips again.
   - **New intent** → rules (L2), then the model, both receiving the compacted dialogue state;
     the model's schema gets `replyTo` (question / draft / record) and `corrects` fields.
   Short replies (≤ 3 words, a number, a time, ừ/ok/đúng/không) are **never** read as a new task
   while anything is waiting.
3. **Ask less, show more.** A completed log with no time takes **now** (anchor) and the card shows
   "Lúc 13:54 · Sửa giờ"; `time.missing` is asked only when the words say the time is not now
   ("sáng nay", "hồi nãy" without a length) or when a span needs it. The morning/evening question
   stays as L1 left it. The `intent` question ("xem nhật ký hay ghi thêm") is asked only for a bare
   kind word with nothing waiting; otherwise Lumi answers with the day's facts and a chip to log.
4. **One task shape, one merge rule.** The task document and the view carry the same
   `clarification` (the server writes it into the document too; the app also reads
   `pendingClarification`); `mergeTask` prefers, at equal versions, the task that carries more
   (a question, drafts) and never drops an open question for a null; the inline snapshot marks
   the listener state as already current. A client replay test runs the two arrival orders.
5. **The composer shows what it will do.** While a question is open: a line above the field
   "Đang trả lời: Việc này lúc mấy giờ?" with × ("Hỏi việc khác"); the chips stay under the
   question; typing and sending answers it. While a draft waits: "Đang chờ bạn lưu cữ bú 180ml"
   with "Lưu" and "Bỏ". Nothing is sent by itself.
6. **Every reply says what Lumi did or needs.** No bare "Ok!"; an unreadable reply gets the
   question back with examples; a complaint gets the state; a new topic while a question is
   open closes the question ("Mình bỏ câu hỏi về cữ bú 180ml nhé" with "Giữ lại").
7. **Tests at conversation level.** The e2e harness runs scripted conversations (log → question →
   typed answer → correction → "xoá cái vừa ghi" → "hôm nay bé bú mấy cữ"), with the fake model and
   a live subset; the app replay feeds each step through both arrival orders (view first, document
   first). The two device conversations above become fixtures.

### 11.4 Slices

| Slice | Content                                                                                   | Size | Touches                                                                                       |
| ----- | ----------------------------------------------------------------------------------------- | ---- | --------------------------------------------------------------------------------------------- |
| L1b   | **Hotfix now**: app reads `pendingClarification`; server writes `clarification` into the document; `mergeTask` never drops an open question; `startTask` answers the author's open question in that conversation instead of starting a new text task; `openQuestionInsteadOfHelp` also covers the `intent` question and small-talk `ack` while a question is open; "bây giờ / giờ / vừa xong / mới xong" as a typed answer reads as `ago_0` (today it leaves the time in review); `openQuestionFor` skips a thread without a snapshot instead of giving up; replay test for both arrival orders; the two conversations as fixtures (e2e `say "Bé đã bú bình 180ml"` then `say "13:00"` / `"Bây giờ"` with the model scripted to `clar: intent`) | S | app models/rules/controller, `assistant-worker.ts` finalize, `assistant.ts` start, `assistant-text.ts` typed answers, tests |
| L7    | §11.3 #1–#2, #6: dialogue state, the resolver, meta replies                               | L    | `assistant.ts`, worker, a `dialogue` doc, model schema `replyTo` / `corrects`, e2e scripts     |
| L8    | §11.3 #3, #5: now by default with "Sửa giờ", composer state line, `intent` question narrowed | M    | server planner, app composer + ARB                                                            |
| —     | Region: why the test family's country blocks care guidance on dev (`regions.advanced`); decide whether guidance follows the content country of D-087 | S | config / owner check                                                                      |

Order: L1b at once (it blocks every question on dev), then L6 as agreed, then L7 and L8 with
Phase 2 reads (they share the resolver and the composer).
