# Child Life Assistant — API (slice A2, server core)

Callables in `firebase/functions/src/index.ts` (block "Child Life Assistant, slice A2"), logic in
`firebase/functions/src/assistant.ts`, DTOs in `packages/contracts/src/assistant.ts`. Region
`asia-southeast1`. Every callable needs a signed-in **account** (anonymous "Vào ngay" identities get
`permission-denied`, `account-required`). The uid comes from the token; the plan from stored grants;
the scope is re-verified on every call (Admin SDK bypasses Rules). Nothing the client sends as
`authorUid`, plan or path is trusted.

## Envelope

Request (every command): `contractVersion: 1`, `clientRequestId` (UUID, the idempotency key),
`locale: 'vi' | 'en'`, and since 2026-10-16 (LUMI-05) the optional `clientDraftKinds: string[]` —
the draft kinds this app build can show and save. Absent = an app from before the field
(`legacyClientDraftKinds`: bottle, breast, sleep, expense, reminder, observation, meal); the server
never sends a draft of another kind to such a build (see "Lumi fixes 2026-10-16").

Answer (`AssistantResponse<T>`):

| Field | Meaning |
|---|---|
| `contractVersion` | `1` |
| `requestId` | echo of `clientRequestId` |
| `taskId` | the task concerned, or `null` |
| `serverTime` | ISO instant of the server clock |
| `dataVersion` | task `version` / draft `revision` the data describes; `0` if not versioned |
| `status` | `ok` · `blocked` (e.g. start at 0 credits, kept for resume) · `partial` (confirm: some items not saved) |
| `reasonCode` | an `assistantErrors` code when `blocked` / `partial`, else `null` |
| `retryable` | `true` only for `AI_UNAVAILABLE`-type conditions |
| `data` | the payload below |

Hard failures are `HttpsError`s: `message` = the reason code, `details = { reason, retryable, …field
details }` (field names / problem codes only, never values, stacks or provider text).

| Reason | HttpsError code |
|---|---|
| `AUTH_REQUIRED` | `unauthenticated` |
| `NOT_MEMBER`, `READ_DENIED`, `WRITE_DENIED`, `CONSENT_REQUIRED`, `FEATURE_DISABLED`, `REGION_UNSUPPORTED` | `permission-denied` |
| `USAGE_EXHAUSTED` | `resource-exhausted` |
| `IDEMPOTENCY_CONFLICT` | `already-exists` |
| `VALIDATION_FAILED` | `invalid-argument` |
| `AI_UNAVAILABLE` | `unavailable` |
| everything else (`QUOTE_EXPIRED`, `QUOTE_MISMATCH`, `SCOPE_CHANGED`, `DRAFT_*`, `REVIEW_REQUIRED`, `DOMAIN_CONFLICT`, `MODULE_UNAVAILABLE`, `INVALID_STATE`…) | `failed-precondition` |

A task or conversation that does not exist or belongs to someone else answers `NOT_MEMBER` (no
enumeration).

## D-075 changes (2026-10-15)

- **#1 credits**: `getAssistantUsage` / quotes use the Premium limit while any valid grant gives
  `assistant.premium_budget` (paid, promo, or a beta campaign; legacy paid / promo grants with
  `templates.premium` too), else Free (`usage.md`). AI summaries (`generateSummary`,
  `listSummaries`) charge / show the same pool: answers gain `credits: SummaryCredits`, `quota` is
  `{ day: null, month: <pool window> }`; `ai.assistance` no longer answers `PREMIUM_REQUIRED` for
  Free (role, `ai_assist`, region and consent still apply). `getCapabilities` lists the new
  capability `assistant.premium_budget`.
- **#2 shared thread** (`data.md` "Shared conversation per baby"): `startTask` routes a shared task
  (child scope, text, not `expense`, Cùng nuôi / Người chăm sóc) to `cv_<babyId>` whatever
  `conversationId` the app sent (a readable conversation of the same scope, or the shared id
  before it exists; another person's private one → `NOT_MEMBER`); a private task continues the
  caller's own private conversation, else a new one — never the shared thread. `quoteTask` accepts
  the shared thread's id. `getAssistantTask`, `confirmDrafts`, `patchDraft`, `discardDraft` accept
  any active Cùng nuôi / Người chăm sóc for a **shared** task (patch / discard only for a draft
  whose module their role may save; confirm re-checks each item against the confirmer's role);
  private tasks stay owner-only (`NOT_MEMBER`). `submitClarification`, `cancelTask`,
  `submitAssistantFeedback`, `planAssistantActivity` stay author-only. Views gain `task.visibility`,
  `task.author`, `message.author`, `draft.confirmedBy`, `conversation.shared` (`ownerUid` null for
  the shared thread). `listAssistantHistory` (conversations) puts the shared thread first on the
  first page (for Cùng nuôi / Người chăm sóc) and pages the caller's private ones after it (cursor
  `private` = the private list from its start). `deleteAssistantConversation` on the shared thread:
  Cùng nuôi only (`WRITE_DENIED` for a caregiver), deletes every member's tasks of it; answers
  `{ deletedTasks, domainRecordsKept: true }`.

## Rework 2026-10-15 (Lumi on the real model)

Owner feedback after testing on a device with the real OpenAI model on dev. Server, contracts and
docs only; the app agent adapts the chat UI. Code: `packages/contracts/src/assistant-text.ts`
(deterministic text rules), `firebase/functions/src/assistant-text.ts` (planning),
`assistant-talk.ts` (server replies, private thread id), `assistant-model.ts` (prompt
`assistant-extract-v3`), `assistant-worker.ts`, `assistant.ts`. Evaluation:
[`eval-2026-10-15.md`](eval-2026-10-15.md). All changes are **additive** (old drafts and old app
builds still parse); `contractVersion` stays `1`.

### What changed in behaviour

| Message | Before | Now |
|---|---|---|
| "Mua sữa hết 500k", "đóng tiền học bơi 1tr2", "$20 diapers", "hôm qua mua bỉm 350.000đ ở Con Cưng" | `MODULE_UNAVAILABLE` (expense was photo-only) | one `expense` draft: amount re-read from the words in minor units (`500k` → 500 000 VND, `1tr2` → 1 200 000, `$20` → 2000 USD), date from "hôm qua / hôm kia" (else today), category from the household's list (unknown → `c_other` + review), merchant, what was bought (`note`) |
| "nhắc mai 9h mua bỉm", "thứ 6 đưa bé đi tiêm", "nhắc bố đi lấy kết quả tối nay" | `MODULE_UNAVAILABLE` | one `reminder` draft: date from the words ("mai", "thứ 6", "thứ 2 tuần sau", "20/10"), all day without an hour, `time.ampm` asked only when both halves are still ahead, assignee only through the `reminder.assignee.<i>` question (eligible members; a name in the text is never mapped) |
| Any message with money words (amount or mua / trả tiền / tiền / học phí / hoá đơn / spent / paid / bought…), mixed messages too | could be written to the baby's shared thread | **private from `startTask`**: the task and its user message go to the author's private thread (`task.routing`), never the shared one |
| "Báo ngủ 9 tiếng" | a sleep draft with no times | asks only the start (`time.start`, chips such as "21:00 tối qua" / "22:00 tối qua", or a typed time), computes the end; `durationMin` + `linked` on the draft |
| "dậy lúc 6h, ngủ 9 tiếng", "đêm qua 9h tối đến 6h sáng", "10 giờ tối bú 90ml" (said in the morning) | review / wrong day | start computed (21:00 last night), overnight kept on its days, last night's evening |
| "8 giờ bú 120ml" at 14:20 | always asked morning / evening | 08:00 (20:00 would be in the future); asked only when both are possible (e.g. at 21:30) |
| "bé bú 120ml" (no time) | the model's free-text "mấy giờ?" | `time.missing` with chips "Vừa xong (14:20)", "30 phút trước (13:50)", "1 tiếng trước (13:20)" and a typed time |
| "à không, 150ml", "nhầm, 10h30 mới dậy", "bên phải chứ" | a second, separate draft (or a question) | the corrected draft **replaces** the sender's previous unsaved draft (old one `discarded`, `errorCode: 'REPLACED'`); a saved one is never changed (`PREVIOUS_SAVED` + `link`) |
| A feed like one logged within 10 minutes | saved twice | `warnings: ['duplicate_suspected']`; confirm answers `conflict` / `DUPLICATE_SUSPECTED` unless `acknowledge` has it ("Vẫn lưu") |
| "cảm ơn Lumi", "chào", "ok", "Thanks!", "vừa ghi rồi" | "Xem nhật ký hay ghi thêm?" (1 credit held) | a short reply at `startTask` (`SMALL_TALK`), **0 credits, no model** |
| "thời tiết hôm nay?", "giúp mình với", "write me a poem", an injection | "Xem nhật ký hay ghi thêm?" / failed | `HELP` reply (what Lumi can do), `ready`, **0 credits**; never a dead end |
| "con 7 tháng ăn gì được?" | "Xem nhật ký hay ghi thêm?" | the care meal-ideas topic (approved recipes, else the honest fallback) |
| Medicine reminder ("nhắc 8h cho bé uống siro") | — | no draft; `MEDICINE_NOT_SCHEDULED` notice (add it yourself in Nhắc việc), released |

Unchanged: health signs first and free (keywords at `startTask`, structured signs in the
worker), roles per module (Chi tiêu right, reminders Cùng nuôi only, care `rhythm.checkin`),
confirm-only writes, idempotency, fencing, 30-min clarification TTL, ≤ 4 rounds.

### Contract changes (exact fields)

**Drafts** (`draftPayloadSchema`; all new fields optional, so old drafts parse):

```ts
type SpanLink = { derived: 'startedAt' | 'endedAt' | 'occurredAt' | 'durationMin' } | null;

// sleep
{ kind: 'sleep', startedAt: iso | null, endedAt: iso | null,
  durationMin?: int > 0 | null,   // NEW: minutes; = endedAt − startedAt whenever both are set
  linked?: SpanLink }             // NEW: which field the server computed
// breast
{ kind: 'breast', occurredAt, durationMin, side,
  linked?: SpanLink }             // NEW: { derived: 'occurredAt' } when the start came from an end
// expense
{ kind: 'expense', merchant, totalMinor, currency, date, subtotalMinor, taxMinor, categoryId,
  babyId, keepReceipt,
  note?: string (≤ 80) | null }   // NEW: what was bought ("sữa"); saved as "sữa · Con Cưng"
```

Keeping a span linked while editing (CH06 sheet), recommended:

- **sleep** `linked.derived = 'endedAt'` ("ngủ 9 tiếng" + a start): moving the start moves the end
  by the same amount (duration kept); editing the end recomputes `durationMin`; editing the
  duration moves the end. `derived = 'startedAt'` ("dậy lúc 6h, ngủ 9 tiếng"): the end is the
  fixed point — moving the end moves the start; editing the duration moves the start.
  `null` / absent: two independent times, `durationMin` is shown read-only as end − start.
- **breast** `linked.derived = 'occurredAt'` ("vừa bú mẹ 20 phút", "bú 15 phút, xong lúc 8h"):
  the end (occurredAt + durationMin) is the fixed point — editing the duration moves the start.
- `patchDraft` accepts `durationMin` / `linked` back; for a sleep with both ends the **server
  recomputes `durationMin` = end − start** (its figure wins), so the app never has to be exact.
- The expense `note` is editable (≤ 80); the saved Chi tiêu note is `note · merchant` (≤ 80).

**Clarifications** (server catalog, `Clarification` shape unchanged; the app treats choice ids as
opaque and sends them back as `choiceId`, or `text` when `allowText`):

| `field` | Question (vi) | Choices | `allowText` | Answer |
|---|---|---|---|---|
| `time.ampm` | "Giờ đó là buổi sáng hay chiều tối?" | `am` "Buổi sáng", `pm` "Chiều / tối" | false | applies to every time without a period word in the message |
| `time.missing` | "Việc này lúc mấy giờ?" | `ago_0` "Vừa xong (14:20)", `ago_30` "30 phút trước (13:50)", `ago_60` "1 tiếng trước (13:20)" | **true** | a chip, or a typed time ("21h", "9h tối", "21:30"); never in the future |
| `time.start` | "Bé bắt đầu ngủ lúc mấy giờ?" | `at_<YYYY-MM-DD>_<HH:mm>` × 2 on the half hour, latest = send time − length, labels "21:00 tối qua" / "22:00 tối qua" / "12:30 hôm nay" | **true** | a chip, or a typed time; the end is computed (`linked.derived = 'endedAt'`) |
| `reminder.assignee.<i>` | "Tin nhắn ghi “bố” cho việc “đi lấy kết quả”. Giao việc này cho ai?" | eligible members (uid ids, "Bạn (Mai)" first) + `none` "Không giao" | false | the member's uid on the draft (`assigneeUid`), re-checked at confirm |

`allowText: true` → show a "Khác" entry that opens a time input and sends `text`. An answer the
server cannot read leaves the field missing on the draft (review), never a second question.
Server questions reuse the first reading: **no second model call, no extra credit**.

**Task view** (`AssistantTaskView`):

```ts
routing?: { reason: 'spending'; from: 'shared_thread'; at: 'start' | 'worker' } | null  // NEW
```

- `at: 'start'`: money in the words → the task's `conversationId` is the author's private thread
  `cv_p_<32 hex>` (one per person and baby, listed by `listAssistantHistory` with the other private
  threads) even though the app sent the shared thread id. Show the reply there (or a link to it)
  and the `SPENDING_PRIVATE` notice; the shared thread never gets the message.
- `at: 'worker'`: the detector missed it but the model found an expense: in the settle transaction
  the task, its user message(s) and every later part move to the author's private thread (the
  shared copy is deleted, the thread's `lastTaskId` goes back to the previous task). A shared-thread
  listener sees the user message disappear; `getAssistantTask` now answers `NOT_MEMBER` to the
  other members. The app should refresh the task snapshot (its `conversationId` changed).

**Text parts**: `{ type: 'text', text, code?, link? }` — `link` is NEW (an app route built by the
server). New `code`s (`assistantNoticeCodes`): `SMALL_TALK`, `HELP`, `SPENDING_PRIVATE`,
`CORRECTION_APPLIED`, `PREVIOUS_SAVED` (with `link` to the saved record), `MEDICINE_NOT_SCHEDULED`,
`DUPLICATE_SUSPECTED`. Unknown codes must still render as plain text.

**Outcomes / credits** (additions to the Worker table below):

| Outcome | State | Credits | Parts |
|---|---|---|---|
| small talk (at `startTask`, no model) | `ready` | **0** (`usage: none`, no reservation) | `text` `SMALL_TALK` |
| small talk / out of scope / "Ghi thêm" with nothing (model) | `ready` | **release** | `text` `HELP` (or `SMALL_TALK`) |
| correction of a saved item / medicine reminder only | `ready` | release | `PREVIOUS_SAVED` / `MEDICINE_NOT_SCHEDULED` |
| server question (`time.*`, `reminder.assignee.*`) | `awaiting_clarification` | hold (same reservation) | `clarification` |
| drafts (typed expense / reminder included) | `ready` | commit 1 | notices + `draft_reference` |
| caregiver: expense / reminder only | `failed` · `WRITE_DENIED` | release | notice ("Vai trò của bạn chưa được ghi Chi tiêu" / "Chỉ Cùng nuôi tạo được nhắc việc") |

**Quote / start**: unchanged requests. `startTask` may now answer a ready task with `credits: 0`
for small talk (like health). `taskVisibilityFor` (contracts) takes an optional `text`.

**Not changed**: `confirmDrafts`, `discardDraft`, events, history paging, the photo flow.

## Timers and review fields (Lumi 2026-10-16)

Owner report on a device (dev, 2026-10-16 01:05 and 01:09): "Con đang ngủ" became an
OBSERVATION draft in `needs_review` with `missingFields: ['date']` although `date` was set, and the
card showed "Cần kiểm tra · Kiểm tra lại mục này rồi lưu" with a disabled "Lưu ghi nhận" — a dead
end; sending it again set the first draft aside. A breastfeed answered with "Vừa xong (01:08)" kept
`missingFields: ['occurredAt', 'side']` although the time was filled and the care form never
requires a side. Root causes and what changed:

| Cause | Fix |
|---|---|
| The model's `missingFields` were trusted and mapped by name (`time` → observation `date`), and never re-checked after the server filled the field | Contracts `draftReviewFields(payload, problems, uncertain)`: **missing = the kind's `requiredDraftFields` that are empty**; the model's list is advice only; an unsure field is kept only if it is a real, filled field of the kind; every `DraftProblem` maps through the total table `draftProblemFields[kind][problem]` (contracts test: every kind × every problem names a field of that kind). Used by the text planner, the A2 helper, photos, `patchDraft`. |
| `side` was a blocking field on nursing drafts | Optional, as in the form: not said → the form's default (other side of the last feed, else `both`); the writer saves `side ?? 'both'` like the app. A value the server defaulted (side, bottle milk) is never "unsure" because the model doubted it. |
| Plain states were read as observations | Prompt `assistant-extract-v4`: an observation is only "something different noticed" (khó ngủ, quấy hơn, ăn ít…); `phase` on sleep / breast items. Server guard `checkIntents` (contracts `careStatesIn`, `observationCueIn`): a sleep / feeding observation without a difference cue next to a state, a log or a sleep length is dropped; a state the model missed gets its item. |
| A repeated message was taken as a correction | Same words (`sameMessage`) are never a correction; and see "Repeated messages" below. |

Optional per kind (never `missingFields`): observation `when` / `note`, breast `durationMin` /
`side`, sleep `durationMin`, reminder `time` / `assigneeUid`, expense `merchant` / `categoryId` /
`note`. Required: bottle `amountMl`, `occurredAt`, `milk`; breast `occurredAt`; sleep `startedAt`,
`endedAt`; expense `totalMinor`, `date`, `currency`; reminder `title`, `date`; observation
`observation`, `date`; timer `at`.

### Ongoing states drive the app's timers

Design: **one source of truth** — the app's own running timer document `babies/{b}/timers/{sleep |
breast}` (S5, P-011; every member's app, the Home tile and the widgets listen to it). The chat
never keeps its own timer state. A new draft kind `timer` (additive; older apps show it as an
unknown item):

```ts
{ kind: 'timer', timer: 'sleep' | 'breast', action: 'start' | 'stop',
  at: iso | null,            // start: when it began ("lúc 21h", else the send time); stop: when it ended
  side: 'left' | 'right' | null,   // breast start: the side that runs first (one at a time)
  sessionId: 32hex | null,   // stop: the running session it ends (record r_<sessionId>)
  startedAt: iso | null }    // stop: the running timer's start
```

| Message | Running timer of that kind | Result |
|---|---|---|
| "con đang ngủ", "bé vừa ngủ", "bé ngủ rồi", "She fell asleep" | none | `timer` start at the send time — card "Bắt đầu tính giờ ngủ · 01:05" (one tap) |
| "bắt đầu ngủ lúc 21h" (at 21:30) | none | start at 21:00 (said time; not in the future, ≤ 24 h / 240 min ago) |
| "đang cho bú (trái)", "bé đang ti mẹ bên phải" | none | breast start, that side (not said: the other side of the last feed, else left) |
| any start | running | text `TIMER_RUNNING` ("Bé đang ngủ, đồng hồ đã tính giờ từ 00:25. Kết thúc … hay để đồng hồ tiếp tục?", `link` = `/care/timer/sleep?babyId=`) + a `timer` stop draft at the send time: "Kết thúc giấc ngủ · 01:05" or "Để tiếp tục" (= discard) |
| "con dậy rồi", "bé vừa dậy", "dậy lúc 6h", "bú xong rồi", "he just woke up" | running | `timer` stop at the said time (else now) |
| "dậy rồi" / "dậy lúc 6h" | none | a finished `sleep` ending then; the server asks `time.start` "Bé dậy lúc 01:05. Bé bắt đầu ngủ lúc mấy giờ?" with chips "Khoảng 1 / 2 / 3 tiếng (từ 00:05…)" (`at_<date>_<HH:mm>`), a typed time or a typed length ("2 tiếng") |
| "bú xong rồi" | none | the usual finished breastfeed (time asked with `time.missing`) |
| a length or both times ("ngủ 2 tiếng", "ngủ từ 9h đến 11h", "bú 15 phút") | — | a finished log, never a timer |

The reading: the model's `phase` (v4) or the deterministic `careStatesIn` (vi with / without
diacritics, en; "dậy" only with its diacritics when the text has any — "dạy", "đầy" are other words;
concerns such as "khó ngủ", "chưa ngủ", bottles and lengths excluded). The planner reads the running
timers (`runningTimersOf`) and the next breast side (`nextBreastSideOf`); no question is asked for a
start or a stop. Credits: like any draft (commit 1).

**Confirm** (`confirmDraftItem` → `assistant-timers.ts` `planTimerWrite`, same transaction, role
`rhythm.checkin` = Rules `canLog`, membership, baby, `draftProblems` against the confirm time):

- start → creates `babies/{b}/timers/{type}` with exactly the `validNewTimer` key set: `type, babyId,
  sessionId (= sha('timer|'+draftId)[0:32]), startedAt = at, startedBy = the confirmer, author =
  the confirmer's membership, sides (sleep null; breast { left / right: { accumulatedMs: 0,
  runningSince: at on the chosen side } }), paused false, pausedSides [], updatedAt, updatedBy`.
  A timer already there → `conflict` / `TIMER_RUNNING` (the app shows the running one); this draft's
  own session there, or its record already written → adopted as `saved`. `recordId` =
  `r_<sessionId>` (the record its end will write), `recordLink` = `/care/timer/{type}?babyId=`.
- stop → the running session must still be `sessionId`: writes `babies/{b}/records/r_<sessionId>`
  (contracts `timerRecordAt` = the app's `CareTimer.toRecord`: sleep start … min(end, start + 24 h);
  breast total of the sides in whole minutes 1…240, `leftMin`, `rightMin`, `side`, `endSide`) with
  `source: 'assistant'` and the confirmer as author, and **deletes the timer** — the same result as
  the app's "Kết thúc". The record already exists (ended on a phone, a replay) → `saved` with it;
  another session runs / none and no record → `conflict` / `TIMER_CHANGED`. `onRecordWritten` then
  recomputes the day and opens sleep-overlap conflicts as for app writes.
- `patchDraft` on a timer may change `at` (and a start's `side`) only; `timer`, `action`,
  `sessionId`, `startedAt` changed → `VALIDATION_FAILED`.
- Problems: `MISSING_TIME` (no `at`), `FUTURE_TIME`, `INVALID_TIME` (start older than 24 h sleep /
  240 min feed; stop not after `startedAt`).

New `assistantErrors`: `TIMER_RUNNING`, `TIMER_CHANGED` (confirm conflicts). New notice codes:
`TIMER_RUNNING` (with `link`), `SAME_AS_PENDING`.

### Repeated messages

`startTask`: the same words (`sameMessage`: case, spaces and punctuation ignored) as the thread's
last task, within `assistantRepeatWindowMin` (10 min), by the same person (or a shared task in the
shared thread), while one of its drafts still waits (`draft` / `needs_review`, not expired) → answered
at once: task `ready`, 0 credits, no quote use, no model, one text part `SAME_AS_PENDING` ("Mình đã
chuẩn bị mục này ngay ở trên…"); the waiting draft is untouched and the thread's `lastTaskId` stays
on it (`repeatOf` on the task). A real correction ("à không, 150ml") still replaces the previous
unsaved draft; the same words never do.

### App (Lumi chat card)

- `timer` drafts: "Tính giờ ngủ · Từ 01:05" → primary "Bắt đầu tính giờ ngủ · 01:05" (breast: "Bắt
  đầu tính giờ bú · trái · 01:05"), "Không cần"; a stop: "00:25 – 01:05 · 40 phút", the live running
  timer ("Đang ngủ · 00:40:00", from the same timer document, per second), "Kết thúc giấc ngủ ·
  01:05" / "Để tiếp tục". Saved start: the live timer inline and "Mở đồng hồ" (`pushSafe`
  `/care/timer/{type}`; Back returns to the chat). The `TIMER_RUNNING` notice links the timer too.
- A `needs_review` draft opens its fix **inside the card by itself**: each missing / unsure field in
  plain words ("Chưa rõ bé bú bên nào", "Chưa có giờ bé dậy", "Lượng 120 ml có đúng không?",
  "Giờ 01:30 chưa tới…") with chips first (Trái / Phải / Cả hai; Vừa xong / 30 phút / 1 tiếng
  trước; 60–180 ml; Ngủ 1 / 2 / 3 tiếng; Hôm nay / Ngày mai; "Đúng rồi" for an unsure value) and a
  picker or "Khác…" only when no chip fits; optional rows (a sleep note's "Ban ngày / Ban đêm / Cả
  hai") are muted and never block. A chip patches the draft with that field confirmed; as soon as
  nothing blocks, the card turns valid and is ticked by itself.
- One draft in a task saves from its own card with a concrete label ("Lưu cữ bú", "Lưu giấc ngủ",
  "Lưu ghi nhận"); no tick box and no "Chọn mục muốn lưu" bar. Several drafts: complete ones are
  pre-ticked; the bar reads "Lưu 2 mục", or "Còn N mục cần bổ sung ở trên" while none can be saved.
  A disabled save always has its reason next to it.

## Lumi fixes 2026-10-16 (LUMI-01…17)

Bugs of [`test-report-lumi-2026-10-16.md`](test-report-lumi-2026-10-16.md); every one is a case in
`firebase/tests/assistant-e2e/cases/` first (device / live replies scripted as the model gave them).
Prompt `assistant-extract-v5` (`v6` since the owner decisions of 2026-10-16: head circumference, purchases without an amount).

**New draft kinds — the care module's other logs (LUMI-01).** "hút sữa 120ml", "thay tã ướt",
"bé nặng 5,2kg" are drafted as the app's own forms write them (never a bottle feed, an observation,
an expense or "no place to save"):

```ts
{ kind: 'pump', amountMl: number | null,   // whole ml 1…1000 (PumpSheet)
  occurredAt: iso | null, side: 'left' | 'right' | 'both' | null, durationMin: int | null,
  linked?: { derived: 'occurredAt' } | null }      // "vừa hút 20 phút": started 20 min ago
{ kind: 'diaper', diaper: 'wet' | 'dirty' | 'both' | null, occurredAt: iso | null }   // DiaperSheet
{ kind: 'growth', weightKg: number | null,  // 0.3…40, one decimal (GrowthScreen)
  lengthCm: number | null,                  // 20…150, one decimal, optional
  measuredOn: 'YYYY-MM-DD' | null,          // "Ngày đo"
  headCm?: number | null }                  // 20…60, one decimal, optional (owner 2026-10-16)
```

| | pump | diaper | growth |
|---|---|---|---|
| Required (`requiredDraftFields`) | `amountMl`, `occurredAt` | `diaper`, `occurredAt` | `weightKg`, `measuredOn` |
| Defaults | side: as said, else the last pump's side, else `both` (never flagged) | none: wet / dirty not said → `diaper` missing (the person picks; never a guess) | `measuredOn`: the day said ("hôm qua đi khám"), else today |
| Problems | `MISSING_AMOUNT`, `INVALID_AMOUNT` (amount, or length > 240 — names the value out of range), `MISSING_TIME`, `FUTURE_TIME` | `MISSING_TIME`, `FUTURE_TIME` | `MISSING_AMOUNT`, `INVALID_AMOUNT` (weight, length or head circumference out of range — names it), `MISSING_DATE`, `FUTURE_TIME` |
| Record (`careRecordFromDraft`, Rules `validCareData`) | `type: 'pump'`, `data { side, amountMl, durationMin }`, `endedAt = start + durationMin` | `type: 'diaper'`, `data { kind }` | `type: 'growth'`, `data { weightKg, lengthCm, measuredOn, headCm? }` (one decimal; `headCm` only when given, as GrowthScreen writes it), `occurredAt` = now when measured today, else noon of that day in the baby's zone |

Role: `rhythm.checkin` (Rules `canLog`), like the other care logs. A breastfeed or pumping session
with a length now ends `durationMin` after it starts (the app's record); one logged right after it
ended starts that long before now (the form's `CareRecord.spanStart`), so the Rules accept it.
Duplicates: a pump within 10 min and 10 % of the amount, a diaper of the same kind within 10 min →
`duplicate_suspected`. Head circumference (owner decision 2026-10-16): "vòng đầu 39cm" is re-read
from the words (`growthIn`) and saved with the record; the server no longer sends `PART_NOT_SAVED`
for it (the code stays for messages already stored). The model's length equal to the head's number
with no length in the words is dropped. A draft prepared before the field has no `headCm` (null).

**Backstops (deterministic, contracts `assistant-text.ts`; functions `careBackstops`).** Whatever
the model named it: pumping words (`pumpCueIn`: hút sữa, vắt sữa, pumped) turn a bottle / breast /
meal item into `pump` (a "sữa vắt" given to the baby stays a bottle); a diaper change (`diaperIn`:
thay tã / bỉm, tã ướt / bẩn, ị, tè, poop; buying diapers is money) turns an observation (no
difference cue) or a meal into `diaper`; a measurement (`growthIn`: "5,2kg", "5kg8" = 5.8, "5200g",
"dài 62cm", "vòng đầu 40cm") turns a meal or an observation into `growth` and drops an expense with
no money said ("hôm qua đi khám bé nặng 5kg8"). A log the model missed gets its item from the words.
"bé bu 120m" (a bare `m` ≥ 50 after bú, no "mẹ") is a 120 ml bottle (`bareMAmountIn`), never a
120-minute breastfeed; a feed / pump length with no time unit in the words over 60 min is flagged.

**Times, one token at a time (LUMI-03 / -04).** Contracts `clockTokensIn` reads every clock time
of the message with ITS OWN period words (after it: "9h tối", "8h sáng nay", "10pm"; right before
it: "tối qua lúc 9h"; with diacritics when the message has any — "tới 10 giờ" is "until"). "12h" /
"12 giờ" is noon unless "đêm / khuya" is said ("12h đêm" = 00:00), also in typed answers
(`clockTimeIn`). Each model time is matched to its token (its evidence words, else the only match):
a model hour the words do not allow (`1h trua` read as 12:00) → the words win and the field is
flagged (`uncertainFields`); a token whose half of the day is open takes the model's reading only
when the message has a period word somewhere, else the readings are resolved by plausibility (not
in the future, ≤ 36 h ago). `time.ampm` is asked only for the times still open, its question names
them ("8:00, 9:00 là buổi sáng hay chiều tối?"), and the answer applies only to them — a time
already resolved (6h at 14:20) is never moved.

**Client capabilities (LUMI-05).** `startTask` stores `clientDraftKinds` on the task
(`clientKinds`; a resume keeps the first). The planner never drafts a kind outside
`clientDraftKindsOf(clientKinds)`: for an app from before 2026-10-16 a timer start / stop or a pump /
diaper / growth item becomes a text part `APP_UPDATE_NEEDED` ("Phiên bản ứng dụng này chưa …", `link`
= the timer screen, `/care/growth` or `/care`); with nothing else useful the task is an honest
fallback (`ready`, 0 credits). New notice codes: `APP_UPDATE_NEEDED`, `PART_NOT_SAVED`.

**Review fields and questions.**

| Bug | Rule now |
|---|---|
| LUMI-07 | A breastfeed / pump / timer side comes from the words only (grounded evidence, or `breastSideIn` when it is the only such item); the model's guess is neither a value nor a doubt. A `timer` draft is checked by its time only (plus a misread time). |
| LUMI-09 | The model's doubt about a time it did not read (a chip, a typed answer, a length, "vừa") is dropped: `startedAt` / `endedAt` / `occurredAt` are flagged only when the model's own time was used (or misread). |
| LUMI-10 | A sleep concern (`sleepConcernIn`: khó ngủ, hay thức đêm… without a single day said, or with "dạo này / mấy hôm / hay") → care `sleep_concern` with the facts the words give (never an observation draft). A "sleep concern" on words with no sleep at all ("biếng ăn") → dropped; a feeding worry → an `observation` (feeding). |
| LUMI-11 | `zoneDraftProblems` (the writers' rules in the baby's zone) runs when a draft is prepared, shown (`draftView`) and edited (`patchDraft`): a reminder already past → `PAST_TIME` on `time` (or `date` all day); expense / observation / growth dates after today → `FUTURE_TIME`. A draft never looks ready and is then refused at save. |
| LUMI-12 | "Lumi làm được gì?" (`asksWhatLumiDoes`) with nothing extracted → `HELP`, 0 credits, never "Xem nhật ký hay ghi thêm?". |
| LUMI-13 | Notices name their item ("Ứng dụng chưa có mục ghi bữa ăn…", "Mình chưa hiểu rõ phần nhắc việc…"); pump / diaper / growth are drafted, never dropped. |
| LUMI-14 | Every read tool is offered to the model; the server answers `READ_DENIED` (free) for a read the member may not use, and never answers a care question with the credit balance (`usage_snapshot` on words about feeds / sleep and not about credits → `READ_DENIED`, or `care_summary` for a member who may read). |
| LUMI-16 | Goods counted by the box / pack ("hai hộp sữa") are a spending signal: the task is private from `startTask`. The prompt says goods bought at a shop are an expense even with no amount (amount `null` → missing, reviewed). |
| LUMI-16 (owner decision 2026-10-16, prompt `assistant-extract-v6`) | Contracts `purchasesIn` reads each clause with a buying word (mua, đặt hàng / tã…, order, bought): **done** ("mua hai hộp sữa", "vừa mua bỉm ở Con Cưng", "đặt tã online") → an expense draft with `totalMinor` missing, in the household currency, private (D-075 #2; "đặt …" is a spending signal at `startTask`); the app asks "Hết bao nhiêu tiền?" on the card (amount field, currency picker, thousands chips) and saves in the same tap once an amount is typed (`patchDraft` with `totalMinor`, `currency` confirmed, then `confirmDrafts`). **Plan / to-do** ("mai đi mua sữa", "nhớ mua bỉm", "cần mua…", "chưa mua", "need to buy") → never an expense: the model's expense becomes a reminder in the person's words ("mua sữa", the day from the words) unless the model returned one; nothing from the model → nothing. **Question** ("mua sữa nào tốt?", "nên mua bỉm gì") → no expense, `HELP` "Mình chưa so sánh hay gợi ý sản phẩm được…", 0 credits, never the `intent` question. A purchase made that the model missed is drafted from the words; one it returned as an undated reminder is the expense. A later day in a mixed message ("…, mai nhớ mua sữa") is never the date of the money spent. Functions `checkPurchases`. |
| P2 | "Bé khó vào giấc hay thức giấc?" (no "hay hay"); the credit answer's reset date reads "1/11/2026" / "1 Nov 2026". |

## Commands

| Callable | Request (beyond the envelope) | `data` | Notes |
|---|---|---|---|
| `setAssistantConsent` | `consent: { version } \| null` | `{ assistant: { version, grantedAt } \| null, stoppedTasks }` | Only `assistant-consent-v1`. Writes `assistant` on `users/{uid}/settings/ai` with `mergeFields` (the summaries `consent` is untouched; `setAiConsent` now also merges, so it keeps `assistant`). Withdrawing fails the caller's `queued` / `awaiting_clarification` / `blocked` tasks with `CONSENT_REQUIRED` and releases their credits; a running task drops its output at settle time. |
| `quoteTask` | `conversationId \| null, scope, modality, attachmentCount, intentHint` | `AssistantQuote` | `status: blocked` + `reason` = first failing gate: `CONSENT_REQUIRED` → `AI_UNAVAILABLE` (`assistant_live` off, no provider key, AI budget spent) → `USAGE_EXHAUSTED`. Never calls a model, never reserves. TTL 5 min. `image` needs `assistant_images` (A3). Idempotent per `clientRequestId`. |
| `startTask` | `conversationId \| null, scope, quoteId?, intentHint?, text, attachmentIds` | `AssistantTaskSnapshot & { usage: AssistantUsage }` (since Lumi L2; before: `{ task, usage }`) | See "Start" and "Lumi L2" below. Text needs no `quoteId` (quoted inline); photos keep theirs. `{ warmup: true }` alone is answered `{ warm: true }` before any auth or read. |
| `submitClarification` | `taskId, expectedVersion, clarificationId, choiceId \| null, text \| null` | `AssistantTaskSnapshot` (since Lumi L2; before: `{ task }`) | Same task, same reservation, 0 extra credits. Wrong state / version / id → `INVALID_STATE`; a choice not offered or empty free text → `VALIDATION_FAILED`; past the 30-min TTL → credits released, task `failed`, `QUOTE_EXPIRED`. Idempotent per `clientRequestId`. |
| `patchDraft` | `draftId, expectedRevision, payload, confirmedFields` | `{ draft: AssistantDraftView }` | Revision + 1, validated like the form (`draftProblems` against the server clock), no model, no credits, no domain write. `DRAFT_SAVED`, `DRAFT_EXPIRED`, `DRAFT_STALE`, `INVALID_STATE` (discarded), `VALIDATION_FAILED` (schema, kind change). Changed or confirmed fields leave `uncertainFields`; remaining problems put the draft in `needs_review`. |
| `confirmDrafts` | `taskId, selected[{ draftId, revision, acknowledge[] }], scope?` | `ConfirmDraftsResult` | No model, no credits (works at 0 credits while the TTL holds). Needs `assistant` + `assistant_writes`. `scope` (optional) different from the task's → `SCOPE_CHANGED` before anything. Per item: `saved` / `failed` / `conflict` (see "Confirm"). `status: partial` when any item is not saved. Idempotent per `clientRequestId`; the same id with another selection → `IDEMPOTENCY_CONFLICT`. |
| `discardDraft` | `draftId, expectedRevision` | `{ draft }` | State `discarded`; never a domain delete, never a refund. Saved → `DRAFT_SAVED`. |
| `cancelTask` | `taskId` | `{ task }` | Unfinished (`blocked`, `queued`, `processing`, `awaiting_clarification`) → `canceled`, reservation released once; a late worker is fenced. `ready` / `failed` / `canceled` unchanged (no refund for a ready answer). |
| `submitAssistantFeedback` | `taskId, contentId, contentVersion, outcome` | `{ feedbackId \| null, outcome }` | 0 credits, no model. Role `rhythm.feedback` (Cùng nuôi, Người chăm sóc) else `WRITE_DENIED`. `contentId`/`contentVersion` must be a published activity of `publicConfig/content_rhythm`. `helpful` / `unsure` / `not_suitable` → `babies/{b}/recFeedback/fb_<hash(uid,task,content,version)>`; the same again is idempotent, another outcome → `DOMAIN_CONFLICT`. `not_tried` ("Chưa thử") writes nothing to the module, only `feedback[]` on the task. |
| `getAssistantUsage` | `babyId` | `AssistantUsage` | Household pool now (an unused window reads empty). |
| `listAssistantHistory` | `babyId, conversationId \| null, cursor \| null, limit ≤ 50` | `AssistantHistoryPage<AssistantConversationView \| AssistantMessage>` | `conversationId: null` → the baby's shared thread first (Cùng nuôi / Người chăm sóc, first page only, D-075 #2), then the caller's own private conversations about `babyId`, newest `updatedAt` first, cursor = last conversation id (or `private`). Otherwise a readable conversation's messages (with `author`), newest first, cursor = last sequence. Other members' private chats are never listed (P-158). |
| `getAssistantTask` | `taskId, afterSequence \| null` | `AssistantTaskSnapshot` | `{ warmup: true }` alone → `{ warm: true }` (Lumi L2). Task (with `visibility`, `author`), drafts (with `problems`, `confirmedBy`), events after `afterSequence` (ordered), the task's messages (with `author`). The authority on reconnect (M11). Owner — or, for a shared task, any active Cùng nuôi / Người chăm sóc — still a member. |
| `deleteAssistantConversation` | `conversationId, confirm: true` | `{ deletedTasks, domainRecordsKept: true }` | Private: its owner. Shared thread: a Cùng nuôi only (`WRITE_DENIED` otherwise), for everyone (D-075 #2). Cancels unfinished tasks (credits released), deletes the conversation, its messages, its tasks with drafts and events. Never touches care records, check-ins, feedback, reminders, expenses, the credit ledger or execution rows. An already deleted conversation answers `deletedTasks: 0`. |

## Start (`startTask`)

1. Validate (text or attachments required; `image` → `FEATURE_DISABLED` without `assistant_images`,
   else `MODULE_UNAVAILABLE` until A3), membership of `scope`, `assistant` flag.
2. Task id = `tk_<hash(uid, clientRequestId)>`. Same id + same `taskInputKey` → the same task
   (replay, no new charge); a different input → `IDEMPOTENCY_CONFLICT`.
3. Health signs in the text (`healthSignalsIn`, vi/en) → **health support at once**: task `ready`,
   assistant message `[{ type: 'health_support', signs }]`, 0 credits, no quote check, no consent
   check, no model — also at quota 0 (U10, J10).
4. Consent (`CONSENT_REQUIRED`), quote (`QUOTE_MISMATCH` when not the caller's, another scope,
   modality, attachment count, used by another task, or the pool / credits moved since; `QUOTE_EXPIRED`
   after 5 min).
5. Model off (`assistant_live`, no provider key, AI budget spent) → `blocked` / `AI_UNAVAILABLE`,
   nothing reserved. Otherwise `reserveQuota` in the **same transaction** as the task: denied →
   `blocked` / `USAGE_EXHAUSTED` (assistant message `usage_notice`); reserved → task `queued`, quote
   `usedBy`. A window that moved since the quote aborts with `QUOTE_MISMATCH`.
6. A `blocked` task resumes when the same `clientRequestId` and input come with a fresh quote (e.g.
   after a verified upgrade the quote is at the paid pool, CH23): it reserves once and goes `queued`;
   "today" stays the original send instant.

## Lumi L2: fast routine logs (D-088 §4.4, P-167 #4, #8, #9)

- **No quote for text.** `startTask` without `quoteId` is its own quote: the same gates in the same
  order (scope, role, region and flags in the trusted scope; health first; consent; the model; the
  pool), `intentHint` from the request. An older app's quote is still checked; a rule-read log is
  never a `QUOTE_MISMATCH` for costing less than its quote.
- **Rules before the model** (`firebase/functions/src/assistant-rules.ts`): a message that is ONE
  plain log — bottle ml + time, breast minutes / side, wet / dirty diaper, sleep start / stop / span
  / length, pump ml, weight / length / head — is read into the extraction the model returns, and
  `ruleRead: true` is stored on the task. Every word must be one the reader knows and every number
  must belong to what it read; anything else (two events, a question, a correction, money, medicine,
  a concern, English, "lúc nãy", an ongoing state with a length, a clock later than now) goes to the
  model. A rule-read task needs no model (`assistant_live` off or no credits left still works),
  reserves **0 units** (listed as "0 lượt · không tính" in "Gần đây") and the worker never calls the
  model for it.
- **The worker runs inside the request.** A text task is created `processing` under the request's
  own lease (`<task>#1`, 90 s) with `accepted` + `progress` events, run at once, and the answer is the
  whole snapshot (drafts, messages, events) — the card draws without `getAssistantTask`.
  `submitClarification` does the same for the next round. The trigger ignores such a task (not
  `queued`); it keeps photos, retries and the sweep. An inline run stops starting model calls 24 s
  after the request began (the phone waits 30 s): out of time — or a call cut by that deadline — the
  task goes back to `queued` and the trigger runs it (never a failure). A request that dies leaves its
  lease to expire; `sweepAssistant` requeues it.
- **Warm, not always on.** `warmAssistant` (Cloud Scheduler `*/5 6-23 * * *` Asia/Ho_Chi_Minh) POSTs
  `{ "data": { "warmup": true } }` to `startTask` and `getAssistantTask`; no `minInstances`.
- **Timings.** `assistant timing` log lines: `op`, `taskId`, `path` (`rules` / `model` / `cached` /
  `handoff` / `talk` / `health` / `trigger`), `state`, per-hop milliseconds, `totalMs` (and `lag` for
  the trigger) — never text, drafts or child data.
- The model request carries the calendar only when a date word, money or a reminder is in the words
  (with the previous turn and the answers), the household categories only for money;
  `max_completion_tokens` 1 100 (all 6 items fit; 400 would cut a 3-feed reply).
- **Compact output (prompt `assistant-extract-v7`, 2026-10-19).** The strict schema has one branch
  per intent kind with only the fields the planner reads for it (`intentKindFields`: a bottle writes
  `amountMl`, `milk`, `time`, `dayOffset`; an expense `title`, `amount`, `currency`, `categoryId`,
  `merchant`, `date`…), `correctsPrevious` only when a previous turn travels, and the evidence /
  uncertain / missing lists defined once (`$defs`). `parseExtraction` fills every other field with
  null, so `planTextIntents` reads the same extraction as from a v6 reply (still accepted). About
  half the output tokens and ≈ 0.6 s less per model call:
  [`latency-2026-10-19.md`](latency-2026-10-19.md) §5.

## Worker (`runAssistantTask` trigger on `assistantTasks/{taskId}`)

Claims a `queued` task (or a `processing` one whose lease ended) in a transaction: `processing`,
`lease { holder: <task>#<attempt>, until: +300 s }`. Then: trusted scope → `assistant` flag → health
rule (free) → consent → `assistant_live` + provider + AI budget → one `extract` call (60 s deadline)
→ strict schema → clarification (model field from the catalog, or `time.ampm` when an hour has no
morning/evening anywhere, or `intent` when nothing was found; each field asked once, ≤ 4 rounds) →
read tools → wording (number-guarded) → prepare tools → **one fenced settle transaction**: task still
`processing` with this holder (else nothing is written or charged), consent re-read (withdrawn →
`CONSENT_REQUIRED`), part types allowlisted, credits per `usageForOutcome` (commit once / hold while
asking / release), drafts, assistant message, coalesced events, task state. More than 3 attempts →
`failed` / `AI_UNAVAILABLE`, released. `sweepAssistant` (every 10 min) requeues tasks whose lease ended,
fails unanswered clarifications after 30 min (`QUOTE_EXPIRED`, released) and deletes quotes older than
a day.

Task outcomes → state / credits:

| Outcome | State | Credits | Message parts |
|---|---|---|---|
| drafts (≥ 1) | `ready` | commit | summaries/wording if also read, notices, `draft_reference` × n |
| answer (read tools) | `ready` | commit | `source_summary`, `text` |
| clarification | `awaiting_clarification` | hold | `clarification` |
| health | `ready` | release (0) | `health_support` |
| provider error / timeout | `failed` · `AI_UNAVAILABLE` | release | `text` (no charge) |
| invalid output, unknown tool / intent / field | `failed` · `VALIDATION_FAILED` | release | `text` |
| only unavailable modules / denied role | `failed` · `MODULE_UNAVAILABLE` / `WRITE_DENIED` / `READ_DENIED` | release | notice `text` + `text` |
| consent withdrawn / membership lost | `failed` · `CONSENT_REQUIRED` / `NOT_MEMBER` / `SCOPE_CHANGED` | release | `text` |

## Confirm (per item)

In one transaction per item: draft state (`saved` → answers `saved` with its record, never rewrites
it, even if the record was edited in the form since), TTL (`DRAFT_EXPIRED`), revision
(`DRAFT_STALE`), review (`REVIEW_REQUIRED` while `needs_review` / uncertain / missing), module
(`MODULE_UNAVAILABLE`), membership (`NOT_MEMBER`), role for that module (`WRITE_DENIED`), baby still in
the task's household (`SCOPE_CHANGED`) and open, form validation (`VALIDATION_FAILED` + `problems`),
domain conflict (`conflict` / `DOMAIN_CONFLICT`: an overlapping live sleep unless `acknowledge`
contains `overlap`; a check-in already written by this person for that observation and day). Then
the record, the draft's `saved` state, the execution row and an `item_saved` event commit together.
A record already present at the draft's id is adopted as saved (crash after write, M04). After all
items one assistant message `action_result` is appended.

Record links (built by the server, app routes for A4): care `/care/records/{babyId}/{recordId}`,
check-in `/rhythm/checkins/{babyId}/{checkInId}`.

## Events

`assistantTasks/{taskId}/events/{seq}` — `{ taskId, eventId: "<taskId>:<seq>", sequence, type,
emittedAt, payload }`, sequence 1, 2, 3… with no gaps (the counter moves in the writing
transaction). Types: `accepted` (start, resume, clarification answered), `progress` (claimed),
`clarification_required`, `drafts_ready`, `answer_ready`, `usage_updated` (`{ usage, credits }`),
`item_saved`, `item_failed`, `task_failed` (`{ state: failed | canceled, errorCode }`). No per-token
writes. Clients ignore duplicates / old sequences; after a reconnect, `getAssistantTask` is the
authority.

## Care (slice A5, CH15–CH18, CH28)

Details in `tools.md` "Care tools"; credits in `usage.md`. Callable in `index.ts` (block "slice A5
care"), logic in `firebase/functions/src/assistant-care.ts`.

| Callable | Request (beyond the envelope) | `data` | Notes |
|---|---|---|---|
| `planAssistantActivity` | `taskId, contentId, contentVersion` | `{ plan: AssistantCarePlan, feedbackId }` | "Thử tối nay": an intention, not "đã thử". 0 credits, no model, idempotent per `clientRequestId` and per task + item. Owner, member, role `rhythm.feedback` (`WRITE_DENIED`), the task's own published guidance (`VALIDATION_FAILED`). Writes `care.plan` and `recFeedback` kind `started`. |

Changes to A2 callables: `submitAssistantFeedback` on a care task accepts only that task's guidance
and refuses a tried outcome before the plan's `feedbackOpensAt` (`INVALID_STATE`); `getAssistantTask`
adds `task.care` (`AssistantCareView`, with the CH17 `followUp` once due); `submitClarification`
resets the per-run attempt counter. Worker outcome `fallback` (no approved content fits): state
`ready`, credit released, event `answer_ready`. New parts fields (all optional): `text.code`,
`approved_content.{reasonCode, content, alternatives}`, `recipe_list.{items, excludedCount,
mealLogAvailable}`, `health_support.emergency`.

## Photos (slice A3, CH09–CH14)

Logic in `assistant-attachments.ts` (upload targets, verification, image checks, retention),
`assistant-images.ts` (worker branch), `assistant-image-model.ts` (reading schema / prompt),
`assistant-writers-images.ts` (Chi tiêu and reminder writers), `assistant-lifecycle.ts` (purges,
TTL). Callable and schedules in `index.ts` (block "slice A3 photos"). Security: `security.md`.

| Callable | Request (beyond the envelope) | `data` | Notes |
|---|---|---|---|
| `createAttachmentUpload` | `quoteId, mime (jpeg/png/heic/webp), bytes (≤ 8 MB), sha256, retention (keep_with_record — default, D-075 #3 \| delete_after_read)` | `AssistantUploadTarget { attachmentId, uploadPath, mime, maxBytes, expiresAt, retention }` | The quote must be the caller's, `image`, unexpired, unused and `allowed`; the household must still have the quoted credits **now**, the photo flag and the consent must hold — else the quote's reason / `USAGE_EXHAUSTED` / `FEATURE_DISABLED` / `CONSENT_REQUIRED` and **no target** (U03). One target per photo the quote counted (`VALIDATION_FAILED` beyond). Idempotent per `clientRequestId` (same `at_*`). Target valid 15 min. Nothing reserved. |

The app uploads the bytes once to `uploadPath` (`assistant/{uid}/{at_*}`) with the declared
content type, then calls `startTask` with `attachmentIds` and the same (or a fresh) image quote.

**`startTask` with photos** (replaces A2's `MODULE_UNAVAILABLE`): `modality` from the quote must be
`image` with ≥ 1 attachment (`VALIDATION_FAILED`); before any credit moves each attachment must be
the caller's (`NOT_MEMBER`), of the same household and scope (`SCOPE_CHANGED`), not used by another
task / deleted / refused (`VALIDATION_FAILED`, `details.problem: attachment_used | attachment_gone`),
uploaded before its target expired (`attachment_expired`), and present in Storage with the declared
type and no more than the declared size (`upload_missing | upload_mismatch`). The verified object
generation is bound to the task in the reservation transaction (also while `blocked`, for resume).
A replay of the same request returns the same task even after its photo was deleted. The user
message carries `attachmentIds`.

**Worker (photo tasks)**: after the A2 gates (scope, flag, health, consent, live model), the photos
are re-checked (owner, household, task, `ready`, generation), their bytes sniffed (magic numbers must
match the declared type) and decoded with sharp (≤ 40 MP, ≥ 32 px) **before any provider call**;
only a re-encoded JPEG (≤ 2048 px, no EXIF / GPS / ICC) goes out, once (`readImages`, 90 s). The
reading is cached server-side while a question is open; a clarification never re-sends a photo.

| Outcome | State | Credits (3) | Parts |
|---|---|---|---|
| refused photo (not an image, undecodable, moved, gone) | `failed` · `VALIDATION_FAILED` | release | `text` (no charge) |
| provider error / timeout | `failed` · `AI_UNAVAILABLE` | release | `text` |
| invalid reading (schema, extra key such as a "tool") | `failed` · `VALIDATION_FAILED` | release | `text` |
| unreadable (I01, J05) | `failed` · `OCR_UNREADABLE` | release | retake / type it in |
| receipt → one expense draft (I02–I04, J03) | `ready` | commit | notices (tax included, no total, other currency, possible duplicate) + `draft_reference` |
| note → asks `note.convert` (I06) | `awaiting_clarification` | hold | "Mình thấy N dòng…", "Không chuyển thành việc" list, `clarification` |
| note, weekday ≠ date (I07, G03) → asks `reminder.date.<line>` | `awaiting_clarification` | hold | `clarification` |
| note → reminder drafts for action lines (J04) | `ready` | commit | excluded list, "cần ngày và giờ", "chưa có người phụ trách", `draft_reference` × n |
| mixed (receipt + note / prescription) → asks `image.intent` | `awaiting_clarification` | hold | "nhiều loại nội dung", medicine notice, `clarification` |
| declined (`none`), nothing actionable, prescription only | `ready` | **release** | `text` ("Không tính lượt") |
| role cannot save (Chi tiêu right / Cùng nuôi for reminders) | `failed` · `WRITE_DENIED` | release | notice |

Photo clarifications (server catalog, vi/en, `allowText: false`): `image.intent` (`expense` "Ghi chi
tiêu", `reminders` "Lưu thành nhắc việc", `none` "Không làm gì" — only what the photo holds),
`note.convert` (`reminders`, `none`), `reminder.date.<i>` (`written` = the date as written,
`weekday` = the written weekday's date within ±3 days, `later` = leave the date to the person).

**Drafts**: `expense` `{ merchant, totalMinor (printed total only), currency, date, subtotalMinor,
taxMinor (informational, never added), categoryId (built-in hint or `c_other`), babyId (scope),
keepReceipt (= retention keep_with_record) }`; `reminder` `{ title, date, time (null unless written —
never 09:00), assigneeUid: null }`. Review: an uncertain date / total / currency / title, a missing
total / date / currency / time block confirm until `patchDraft` fixes or confirms them
(`confirmedFields`). `problems` (snapshot) now include the module's own: `CURRENCY_UNSUPPORTED` for
any currency other than VND (Q-077), `MISSING_TIME` and `INVALID_TITLE` (> 80) for reminders, plus
new `PAST_TIME`. These module limits live only in contracts `expenseCurrencySupported`,
`reminderNeedsTime` and `reminderAssigneeSupported` (D-075 #4 / #5 follow-up flips them). Warning `duplicate_suspected` (I03): confirm answers `conflict` /
`DUPLICATE_SUSPECTED` unless `acknowledge` contains it; never merged.

**Confirm (expense / reminder)**: role per module — Chi tiêu: Cùng nuôi or `extraRights.recordSpending`
(Rules `canRecordSpending`); reminders: Cùng nuôi only; else `WRITE_DENIED`. Expense:
`babies/{b}/expenses/x_<hash(draftId)>` (another baby of the household only with the same right
there), whole VND 1…1 000 000 000, date not after today, category built-in or existing; duplicate
re-checked inside the transaction. Reminder: `babies/{b}/reminders/rm_<hash(draftId)>`, due time
from date + time in the baby's zone, not before now (5 min) and ≤ 366 days, lead 60 min, no device.
A record already at the id is adopted (replay). Links: `/utilities/spending/expense/{id}?babyId=`,
`/care/reminders/{id}?babyId=`. With `keepReceipt`, a re-encoded JPEG (≤ 4 MB) is written to
`babies/{b}/expenses/{x}.jpg` before the transaction and set as `receiptPath`; removed again if the
expense is not saved.

**Retention in snapshots**: `getAssistantTask` adds `attachments: AssistantAttachmentView[]`
(`state`, `deletedAt` only once Storage confirmed, `keptWithRecord`, `rejected`). `cancelTask` on an
unfinished photo task deletes its photos at once; `setAssistantConsent(null)` deletes every photo of
the caller; `deleteAssistantConversation` deletes the conversation's photos (a failed delete stays
`deletion_pending` and is retried).

| Schedule | What |
|---|---|
| `sweepAssistantFiles` (15 min) | retries due `deletion_pending`; deletes uploads never started (target + 1 h), "xoá sau khi đọc" photos of finished tasks, kept photos no expense can still use (draft discarded / expired / saved), photos of blocked tasks after 24 h |
| `cleanupAssistant` (daily 03:20 VN) | `assistantExecutions` / `assistantRequests` older than 30 days; cached readings left by an interrupted run (> 1 day, task not asking); attachment rows of deleted tasks once their object is confirmed gone |


## Staff (slice A6, portal "Trợ lý AI")

Staff callables (`staffCall`: signed-in staff claim, role levels re-read on every call; `StaffError`
reasons `not-staff`, `role`, `malformed`, `no-task`). Logic in `firebase/functions/src/assistant-staff.ts`,
DTOs in `packages/contracts/src/assistant-staff.ts`, screen `apps/portal/src/screens/Assistant.tsx`.
Answers carry family / baby codes (`F-XXXX`, `B-XXXX`), closed codes, counts and times only — never a
uid, name, message, draft payload, clarification answer, health sign, photo or Storage path.

| Callable | Role | Request | Answer |
|---|---|---|---|
| `staffAssistantUsage` | `premium.view` | — | `StaffAssistantUsage`: last 30 Vietnam days — credit pool by budget (`free` / `premium` / `beta` from the window id; committed split chat / AI summaries, released, held, households, households out of credits), credits committed / released per day, tasks by state / outcome / modality, health-support count, error codes, model calls, estimated cost (calls × 300 đ text / 900 đ photo), created → ready p50 / p95, the monthly AI budget and the credit settings in force. |
| `staffAssistantTask` | `premium.view` | `{ taskId: 'tk_' + 32 hex }` | `StaffAssistantTask`: state, modality, plan / pool, credits and usage, error code, outcome kind and counts, clarification fields asked (answered or not), attempts, model calls, model / prompt / policy versions, timestamps, the ledger reservation (state, units, times, release reason), drafts (kind, state, revision, field names, warnings), photo states, the 50 newest event types. |
| `staffAssistantSwitches` | `features.view` | — | `StaffAssistantSwitches`: the six flags (P-161) with family codes, last edit and the 10 latest audit entries for them. |

- **Switching** uses the existing `staffSetFlag` (Features dialog): role `flags.toggle` (Kỹ sư, Admin,
  Owner) for on / off, `flags.rollout` for scope, reason required, one `staffAudit` entry
  (`flags.on` / `flags.off`, category `features`). There is no assistant-specific write path.
- **Credit settings** are edited only in Premium › Cấu hình (`staffSetPremiumConfig`, D-075 #1); the
  Usage tab shows them and links there.
- **Cost of the Usage read** (no new counter, no background job): `assistantTasks` with `createdAt`
  in the period (newest 5 000, selected fields); collection group `quotaOps` with `feature ==
  'assistant'` and `reservedAt` in the period (newest 5 000; composite index `quotaOps (feature,
  reservedAt desc)`, collection-group scope, in `firestore.indexes.json`); `getAll` of the distinct
  windows they touched (≤ 1 000). About 11 000 reads at most per opening; `truncated` says when a cap
  was hit. Time to ready is created → `readyAt` (queue + model + settle); the worker records no
  per-call latency.
