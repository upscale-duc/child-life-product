# Lumi end-to-end test report — 2026-10-16

First run of the plan in [`test-plan.md`](test-plan.md): 216 scripted conversations through the
real callables and worker, invariants on every snapshot, every snapshot replayed through the real
chat screen, and a live run on the real model. Synthetic data only; no message text outside the
catalogue was read or logged.

## 1. What was run

Two code states, because a parallel session was fixing Lumi while this ran:

- **HEAD** — Lumi code of `1440e8a` (HEAD `5b5e8de` only touched uploads): the server and app the
  owner's device bugs came from. Run from a `git archive` copy (no git state changed).
- **Tree** — HEAD + the uncommitted work of the parallel session (17 assistant files: timers,
  review fields, the inline fix panel, prompt `assistant-extract-v4`), as on disk at
  2026-10-15T18:58Z (server diff hash `19ace3d34f9b`) and the app at ≈ 19:05Z. The session then
  committed it as **`f846dda`** (19:10Z); the fake run, the app replay and a 17-case live subset
  were re-run on `f846dda` (§1.1).

| Run      | Code                   | Cases                                      | Snapshots | Pass    | P0                         | Notes                                      |
| -------- | ---------------------- | ------------------------------------------ | --------- | ------- | -------------------------- | ------------------------------------------ |
| a+b fake | tree                   | 216                                        | 417       | **197** | 16                         | ≈ 1 min, 204 scripted replies              |
| a+b fake | HEAD                   | 216                                        | 426       | **178** | 25                         |                                            |
| a+b live | tree                   | 207 (no photos, no provider-failure cases) | 447       | **127** | 13 (+10 wrong records, §3) | 195 model calls, `gpt-4.1-mini`, prompt v4 |
| a+b live | HEAD                   | 21 (device bugs and the worst live cases)  | 51        | 1       | 12                         | 22 model calls, prompt v3                  |
| c replay | tree server × tree app | 228 fixtures                               | 457       | 225     | 0                          | 3 × `FIELD_NOT_NAMED`                      |
| c replay | HEAD server × HEAD app | 214                                        | 426       | 192     | 3                          | DEV-1 dead end, 34 steps field not named   |
| c replay | tree server × HEAD app | 228                                        | 457       | 204     | 13                         | old app cannot show `timer` drafts         |
| c replay | live tree × tree app   | 205                                        | 447       | 202     | 0                          |                                            |
| c replay | live HEAD × HEAD app   | 21                                         | 51        | 8       | 3                          |                                            |

Live spend: **234 model calls** (budget 250: 195 tree + 22 HEAD + 17 `f846dda`), 955 142 prompt +
39 274 completion tokens ≈ **US$ 0.45** at `gpt-4.1-mini` list price ($0.40 / $1.60 per M); p50
2.0–2.3 s, p95 3.0–3.8 s per call. The key was read from Secret Manager into the run's environment
only, never printed or written.

The live run on the tree was scored with the field-control map of the HEAD app (no milk, no
observation or timer controls) and before the `WRONG_KIND` rule existed; §3 re-reads its
snapshots with the final rules.

### 1.1 Re-check on the committed `f846dda`

- Fake: 197/216, the same 19 failures (all baselined: LUMI-01, -03, -11, -12); no new violation.
- App replay (458 tests incl. the map check): passes with the baseline (LUMI-09, -10 named-field
  gaps only).
- Live, 17 cases (17 calls): **fixed** since the tree run — `bot-01` (milk no longer flagged,
  LUMI-08 on the server), `dev-01` (timer). **Still failing** — `WRONG_KIND` P0 on `dev-03a`,
  `dev-03b`, `pd-01`, `pd-05`, `rb-04` (LUMI-01, -15); `mi-08` 12h → 00:00 (LUMI-03); `dev-02` a
  breastfeeding timer with the side flagged and no side row (LUMI-07); `sl-07` start flagged
  (LUMI-09); `ca-01` observation instead of guidance (LUMI-10); `rd-08` (LUMI-14), `tk-10`
  (LUMI-12); `pd-11` a growth message → an expense draft; `ob-04` "biếng ăn" → health support.
  `sl-14` passed this time (the model read 13:00): LUMI-04 stays a risk because nothing on the
  server re-reads the hour.

## 2. The four device bugs

| Bug                                                                                                                             | Cases                                             | HEAD — fake                                                                                   | HEAD — live                            | HEAD — app replay                                                    | Tree                                                                      |
| ------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- | --------------------------------------------------------------------------------------------- | -------------------------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| **DEV-1** "Con đang ngủ" → observation in review, `missingFields: ['date']` with a date, "Kiểm tra lại mục này" + disabled save | `dev-01*`, `ob-02`                                | ✗ `NR_MISSING_BUT_SET` (date set), `NR_NO_CONTROL`, `DEAD_END` (P0)                           | ✗ same, real model                     | ✗ `NO_FIX_CONTROL` (P0) + `FIELD_NOT_NAMED`                          | ✓ fixed: a sleep timer start (fake, live, replay)                         |
| **DEV-2** "bú mẹ" → "Vừa xong (01:08)" → review, unticked, "Chọn mục muốn lưu" disabled, no hint                                | `dev-02*`, `fl-02`, `bot-05/06`, `br-04`, `sl-04` | ✗ `NR_MISSING_BUT_SET` (occurredAt answered, still "missing") + side missing → `EXPECT_READY` | ✗ same (+ durationMin)                 | ✗ `FIELD_NOT_NAMED` (only "Kiểm tra lại mục này rồi lưu."), unticked | ✓ fake and replay; live still flags `side` (LUMI-07)                      |
| **DEV-3** "thay tã ướt", "hút sữa 120ml", "bé nặng 5,2kg" → `MODULE_UNAVAILABLE`                                                | `dev-03*`, `pd-01…12`, `mi-06`                    | ✗ `FALSE_UNAVAILABLE` (P0)                                                                    | ✗ observation dead end / bottle / help | ✗ `NO_FIX_CONTROL`                                                   | ✗ **still failing, and worse live: wrong records one tap away** (LUMI-01) |
| **DEV-4** "mua sữa hết 500k" (fixed 2026-10-15)                                                                                 | `dev-04`, `ex-*`                                  | ✓                                                                                             | ✓ draft (merchant flagged, LUMI-17)    | ✓                                                                    | ✓ regression passes                                                       |

All four are caught by the harness; DEV-4 passes as expected.

## 3. Results by group

| Group                             | Cases | Fake · tree         | Fake · HEAD         | Live · tree         |
| --------------------------------- | ----- | ------------------- | ------------------- | ------------------- |
| device                            | 8     | 5/8 (3 P0)          | 1/8 (6 P0)          | 3/8 (3 P0)          |
| care.bottle                       | 25    | 25/25               | 22/25 (1 P0)        | 2/25 (1 P0)         |
| care.breast                       | 14    | 14/14               | 12/14               | 12/14               |
| care.sleep                        | 18    | 18/18               | 17/18               | 13/18 (1 P0)        |
| care.ongoing                      | 8     | 8/8                 | 2/8                 | 8/8                 |
| care.types (pump, diaper, growth) | 12    | 0/12 (12 P0)        | 0/12 (12 P0)        | 0/12                |
| care.observation                  | 5     | 5/5                 | 3/5 (5 P0)          | 4/5                 |
| multi                             | 10    | 8/10 (1 P0)         | 8/10 (1 P0)         | 4/10 (1 P0)         |
| expense                           | 20    | 20/20               | 20/20               | 18/20 (1 P0)        |
| reminder                          | 14    | 13/14               | 13/14               | 13/14               |
| read                              | 11    | 11/11               | 11/11               | 9/11 (2 P0)         |
| care (guidance, recipes)          | 6     | 6/6                 | 6/6                 | 3/6 (4 P0)          |
| health                            | 7     | 7/7                 | 7/7                 | 7/7                 |
| talk                              | 11    | 11/11               | 11/11               | 10/11               |
| roles                             | 9     | 9/9                 | 9/9                 | 7/9                 |
| gating                            | 13    | 13/13               | 13/13               | 7/9                 |
| photo                             | 5     | 5/5                 | 5/5                 | —                   |
| flow (multi-turn)                 | 12    | 11/12               | 10/12               | 6/12                |
| robust                            | 8     | 8/8                 | 8/8                 | 1/8                 |
| **all**                           | 216   | **197/216** (16 P0) | **178/216** (25 P0) | **127/207** (13 P0) |

Live-tree P0s re-read with the final rules and the tree app: the 4 `DEAD_END`s on a flagged timer
side (`dev-02`, `rd-09`) and observation `when` / `date` (`ca-01`, `ca-04`) become P1 (the tree app
shows a fix row); `WRONG_KIND` adds **10 P0**: `dev-03a`, `dev-03b`, `pd-01`, `pd-04`, `pd-05…08`,
`rb-04` (drafts of the wrong kind, ready to save without review).

What held everywhere (fake and live, both trees): every save passed the contracts schema and the
app's own create Rules, showed in the app's list query, and a retried save wrote nothing more;
credits matched the policy on every snapshot (0 leaks); spending stayed out of the shared thread
and unreadable by other members in every fake case; health went to health support for 0 credits
and 0 model calls (7/7 live); no time chip was in the future; photos (fake reader) passed.

## 4. Prioritised bug list

IDs are for this report; cases are in `firebase/tests/assistant-e2e/cases/`, snapshots of every
run in the run's `snapshots/` folder. "Tree" = the parallel session's work in progress.

### P0 — dead ends, privacy, wrong records

**LUMI-01 · Pump, diaper and growth have no path in chat (DEV-3), and with the real model they
become wrong records.** Tree and HEAD.

- Fake (the deployed model's reply, kind `meal`): `dev-03a` turn 1 → `failed · MODULE_UNAVAILABLE`,
  parts "Mục này chưa ghi được qua trò chuyện. Bạn có thể mở mục tương ứng để ghi trực tiếp." +
  "Chưa xử lý được yêu cầu này. Không tính lượt."; the app shows "Chưa có nơi lưu việc này · App
  chưa có module cho loại việc này" — false, the app logs all three. `FALSE_UNAVAILABLE` on 15 cases.
- Live, tree: "thay tã ướt lúc 13h" → `{kind: observation, observation: "usual", note: "thay tã
ướt"}` state `draft`, nothing flagged; "hút sữa 120ml lúc 10h" → `{kind: bottle, amountMl: 120}`
  state `draft`; "hôm qua đi khám bé nặng 5kg8" → an expense draft (`MISSING_AMOUNT`); "bé nặng
  5,2kg" → `HELP`. `WRONG_KIND` on 8 cases: one tap saves a pump as a bottle feed or a diaper change
  as "như thường lệ". At HEAD the same replies were mostly stuck in review (DEV-1-style dead end).
- Mixed message (`mi-06` "thay tã rồi cho bú 90ml lúc 13h"): the diaper silently disappears
  (`DROPPED_ITEM`).
- Cause: contracts `draftKinds` / `moduleRegistry` (`assistant-tools.ts:60`) have no pump / diaper /
  growth; the prompt (`assistant-model.ts` `extractionSystemPrompt`) lists no such intents, so the
  model picks the nearest kind; `planTextIntents` default → `MODULE_UNAVAILABLE`; the worker turns
  the first notice into the task error (`assistant-worker.ts` ≈ l. 648); the app card copy
  (`assistant_screens.dart` `_moduleCard`, `asModuleBody`). The pending diaper / pump / growth work
  should also make the server refuse an `observation` / `bottle` whose words name another care type.

**LUMI-02 · Observation dead end (DEV-1).** HEAD; fixed in the tree. `dev-01` turn 1 (HEAD, fake and
live): `{kind: observation, observation: "sleep", date: "2026-10-15"}` `needs_review`,
`missingFields: ["date"]`. `NR_MISSING_BUT_SET` + `NR_NO_CONTROL` + `DEAD_END`; app 1440e8a: no
editor for observations, "Lưu ghi nhận" disabled forever (`NO_FIX_CONTROL`). Cause:
`assistant-text.ts` `draftField.time.observation = 'date'` maps the model's "time missing" to a
filled date; `assistant_screens.dart` `editable` excludes observations. Same dead end live at HEAD
for "thay tã ướt" and "hôm qua đi khám bé nặng 5kg8". Kept as regression: `fixtures/device/`.

**LUMI-03 · "12h" in a batch is saved as midnight; one morning / evening answer moves every
time.** Tree and HEAD, fake and live. `mi-08` "bé bú 3 lần: 6h 90ml, 9h 120ml, 12h 100ml" at 14:20 →
asks `time.ampm`; "Buổi sáng" → drafts 06:00, 09:00, **00:00** (state `draft`, nothing flagged);
"Chiều / tối" would make 18:00 and 21:00 (future) and 12:00. `WRONG_VALUE_SILENT`. Cause:
`assistant-text.ts` `hoursOf` treats 12 as ambiguous (0 / 12) and `clockOf` applies the `ampm`
answer to every clock without a period word, including 6h / 9h that were already resolved.
"12h" means noon in Vietnamese unless "đêm" / "khuya" is said.

**LUMI-04 · A clock time the model misreads is saved unflagged.** Live, tree. `sl-14` "be ngu tu 1h
trua den 2h chieu" → `startedAt` 12:00 (`2026-10-15T05:00Z`), `endedAt` 14:00, state `draft`
(HEAD flagged both ends). `WRONG_VALUE_SILENT`. Cause: `planTextIntents` trusts `fields.time`;
the evidence ("1h trua") is used only to decide "explicit", not re-read like amounts
(`bottleMlIn`, `parseMoney`). Re-read the hour from the evidence and flag a mismatch.

**LUMI-05 · App 1440e8a cannot show `timer` drafts.** Replay of the tree server on the HEAD app:
`DRAFT_NOT_SHOWN` on 9 fixtures ("Con đang ngủ", "bé dậy rồi", "đang cho bú bên trái"…): the reply
has nothing to save on a phone that has not updated. `contractVersion` stays 1 and api.md calls the
changes additive. Ship the app before the server, or send a `sleep` / `breast` draft to clients
that do not declare timer support.

### P1 — wrong fields, extra taps, wrong questions

**LUMI-07 · An answered time stays "missing"; side / length flagged (DEV-2).** HEAD: `dev-02`
after "Vừa xong (01:08)" → `{kind: breast, occurredAt: 18:08Z, side: null}` `missingFields:
["occurredAt","side"]` (`NR_MISSING_BUT_SET`); the card says only "Kiểm tra lại mục này rồi lưu.",
unticked, "Chọn mục muốn lưu" disabled (`FIELD_NOT_NAMED`). Same after `time.start` (`sl-04`) and
typed times (`bot-06`). Cause: model `missingFields` mapped onto draft fields and never cleared
after the server fills them (`assistant-text.ts`), `side` required. Fixed in the tree (fake and
replay); live tree still flags `side` as uncertain (`dev-02b`: `side: "both"`, `uncertain:
["side"]`) and a timer's side (`dev-02`, `rd-09`), which has no fix row (only "Kiểm tra lại mục
này" + an editor that cannot change it).

**LUMI-08 · Almost every bottle needs a review tap for the milk.** Live, tree and HEAD: 23/25 bottle
cases, e.g. `bot-01` "bé bú 120ml lúc 8h sáng" → `milk: "breast_milk"` (the preset) with
`uncertain: ["milk"]`. App 1440e8a has no milk control (`FIELD_NOT_NAMED`; "bé bú 100ml sữa dê" →
milk null, `FIX_DOES_NOT_CLEAR`, a dead end); the tree app has milk chips (still one tap per feed).
Cause: the model's milk uncertainty is kept when it echoes the preset. **Fixed on the server in
`f846dda`** (`bot-01` live: ready); app 1440e8a still has no milk control for an unclear milk.

**LUMI-09 · Duration-only sleep keeps the answered start flagged.** Live, tree: `sl-07` "bé ngủ trưa
1 tiếng rưỡi" → chip "12:30 hôm nay" → `uncertain: ["startedAt"]`; `sl-04`, `sl-05`, `sl-15`
flag `endedAt`. The tree app does not name the start (`FIELD_NOT_NAMED`). Same cause as LUMI-07
(model doubts on a server-filled field).

**LUMI-10 · Sleep concerns no longer reach care guidance; an observation's day / night cannot be
fixed.** Live, tree: `ca-01` "dạo này bé khó ngủ về đêm" → observation draft `when: "night"`,
`uncertain: ["when"]` + "Chưa có gợi ý đã duyệt phù hợp…". Cause: the v4 prompt line "observation
(ONLY … khó ngủ, hay thức giấc …)" competes with the care line ("khó ngủ → care sleep_concern").
App (tree): `fixRowsFor` offers day / night only while `when` is empty, so a flagged `when` gets the
generic row (`FIELD_NOT_NAMED`, `ob-05`, baselined).

**LUMI-11 · A reminder for a time already past is shown ready and refused at save.** Tree and HEAD:
`rm-14` "nhắc 10h sáng nay gọi bác sĩ" at 14:20 → `{date: today, time: "10:00"}` state `draft`; save
→ `failed · VALIDATION_FAILED · PAST_TIME` (`SAVE_REFUSED_READY`). Check `PAST_TIME` when preparing.

**LUMI-12 · Extra or wrong questions.** `fl-12` correction "à không, ngủ từ 12h30" of a 13h–14h sleep
asks morning / evening (tree and HEAD); live: "Lumi làm được gì?" asks "Xem nhật ký hay ghi thêm?"
(a credit held) instead of `HELP` (`tk-10`, tree and HEAD); "mấy hôm nay bé biếng ăn" asks "Bé khó
vào giấc hay hay thức giấc?" — a sleep question for a feeding concern (`ob-04`, tree; HEAD went to
health support).

**LUMI-13 · A dropped item is not named.** `mi-06`: the notice "Mục này chưa ghi được qua trò
chuyện…" does not say which item and links nowhere (`assistant-talk.ts:80`).

**LUMI-14 · A relative without daily care asking about feeds gets the credit balance and pays a
credit.** Live, tree and HEAD: `rd-08` "hôm nay bé bú mấy lần?" as a relative → "Hộ còn 999 / 1000
lượt trợ lý, làm mới ngày 2026-11-01.", `usage: committed`. The model picks `usage_snapshot`, the
only read allowed to that role. Answer `READ_DENIED` (free) when the question is about care data.

**LUMI-15 · "bé bu 120m" becomes a 2-hour breastfeed.** Live, tree: `rb-04` → `{kind: breast,
durationMin: 120, side: "both"}` state `draft` (`WRONG_KIND` under the final rules; HEAD flagged
the side). An ambiguous unit should be asked.

**LUMI-16 · An expense only the model can see is missed.** Live, tree: `ex-18` "Con Cưng hôm nay hai
hộp sữa, bé bú 90ml lúc 13h" → bottle only, task in the shared thread. No amount was written, so
no money reached the shared thread; the expense is lost.

**LUMI-17 · "mua sữa hết 500k" flags an empty store.** Live, HEAD (DEV-4 on the deployed model):
`merchant: null`, `uncertain: ["merchant"]` → review. Passes on the tree.

### P2 — copy

- "Bé khó vào giấc **hay hay** thức giấc?" (`assistant-tools.ts:300`).
- `MODULE_UNAVAILABLE`: "Mục này chưa ghi được qua trò chuyện. Bạn có thể mở mục tương ứng để ghi
  trực tiếp." names no item and has no link; "Chưa xử lý được yêu cầu này. Không tính lượt." follows
  it; the app's "App chưa có module cho loại việc này" is false for pump / diaper / growth.
- Credits answer "làm mới ngày **2026-11-01**" — an ISO date in user copy (`assistant-tools.ts:465`).
- The fix panel's fallback row is still "Kiểm tra lại mục này rồi lưu." for fields without a row
  (observation `when` with a value, a timer's side).

## 5. Notes for the parallel sessions

- Baselines: `firebase/tests/assistant-e2e/known-failures.json` (LUMI-01, -03, -11, -12) and
  `apps/mobile/test/features/assistant_replay/known_failures.json` (LUMI-09, -10). When a fix
  lands, the run reports the case as "no longer seen": remove the entry in the same commit.
- Diaper / pump / growth (LUMI-01): the cases script those intents as `"diaper|meal"`,
  `"pump|meal"`, `"growth|meal"` with `title` / `amountMl` / `time`; once the kinds exist, give the
  scripts the new fields (e.g. the diaper kind, weight) and the expectations their values.
- `field_controls.json` describes the tree app (inline fix rows). Map of app 1440e8a used for the
  HEAD runs: bottle `amountMl`, `occurredAt`; breast `occurredAt`, `durationMin`, `side`; sleep
  `startedAt`, `endedAt`, `durationMin`; reminder `title`, `date`, `time`, `assigneeUid`; expense
  `merchant`, `date`, `totalMinor`, `currency`, `categoryId`; observation, meal: none (no editor);
  no timer kind.

## 6. Limits of this run

- The tree was changing during the run; a rerun after the parallel session commits is needed
  before the next dev deploy (`test-plan.md` §6).
- Live: one run per case at temperature 0, one labeller; 14 English cases only.
- The replay reads the cards; it does not tap each fix. "Named" means the words appear on the card.
- Not covered by automation (owner checklist, `test-plan.md` §8): voice, keyboards, haptics, Night
  care in a dark room, push, real networks, two phones at once, the camera.

## 7. After the fixes (2026-10-16, prompt `assistant-extract-v5`)

Every bug of §4 got a case first (28 + 6 new cases: the live / device replies that went wrong,
scripted as the model gave them, e.g. `pd-13…15` a pump read as a bottle, a diaper as an
observation, a weight as an expense; `sl-19` a misread hour; `dev-05*` an app from before
2026-10-16; `br-17` an end time put in `time`), then the fix, then the runs below. Design in
[`api.md`](api.md) "Lumi fixes 2026-10-16", rules in [`tools.md`](tools.md).

| Run                                                                                 | Code                             | Cases                                         | Pass             | P0                       | Notes                                                                  |
| ----------------------------------------------------------------------------------- | -------------------------------- | --------------------------------------------- | ---------------- | ------------------------ | ---------------------------------------------------------------------- |
| a+b fake                                                                            | final                            | 250                                           | **250**          | 0                        | `known-failures.json` **empty** (was 4 bugs / 19 cases)                |
| a+b live, mid                                                                       | v5, before the last server fixes | 138 (device, care, multi, read, talk, robust) | 130              | 0                        | 134 calls                                                              |
| a+b live, full                                                                      | v5                               | 237 (no photos, no provider-failure cases)    | **232** (97.9 %) | 1 (`br-06`, fixed below) | 225 calls                                                              |
| a+b live, re-run of the groups changed after the full run                           | final                            | 46 (care.breast, care.observation, expense)   | **46**           | 0                        | 47 calls; covers the 5 failures of the full run                        |
| live, combined (full run with the re-run groups replaced)                           | final                            | 237                                           | **237** (100 %)  | **0**                    | 0 wrong-record saves (`WRONG_KIND` / `WRONG_VALUE_SILENT`)             |
| text eval (`firebase/functions/test/eval`, 97 cases incl. the 2026-10-16 additions) | final                            | 97                                            | **97**           | —                        | 91 calls, every metric 100 %, 0 silent wrong fields, 0 over-asking     |
| c replay (fixtures of the final fake run)                                           | final server × final app         | 248 fixtures + 14 device                      | 542 tests        | 0                        | normal and `REPLAY_STRICT=true` green; `known_failures.json` **empty** |

Live spend for these fixes: **506 model calls** (budget 600): 2 361 967 prompt + 98 394 completion
tokens ≈ **US$ 1.10** at `gpt-4.1-mini` list price; p50 2.1 s, p95 3.4 s per call. The key was read
from Secret Manager into the run's environment only.

The full live run's 5 failures and what fixed them (all re-run live, passing): `br-06` (P0) — the
model put the end "xong lúc 8h sáng" in `time` with phase stop → a time whose words say it ended is
the end (`endFirst`); `br-16`, `ob-06`, `ex-09` — the model's doubt about a value the server derived
(a start computed from the end, a day not named, a category the words name) is not kept; `ex-18` —
the same two drafts in the other order (expectation). One case is fake-only by design: `sl-19` (a
scripted misreading; its live counterpart is `sl-14`).

| Bug                                       | Status                                                                                                                                                                                                                                     | Where                                                                                                                                     |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| LUMI-01 pump / diaper / growth (P0)       | **fixed**: three draft kinds, writers = the forms' records (Rules-tested), backstops on the words, app cards / fix rows / editors                                                                                                          | contracts `assistant.ts`, `assistant-text.ts`; functions `assistant-text.ts` (`careBackstops`), `assistant-writers.ts`; app `assistant_*` |
| LUMI-02 observation dead end              | fixed earlier (`f846dda`), still green                                                                                                                                                                                                     | —                                                                                                                                         |
| LUMI-03 "12h" / one answer for every time | **fixed**: `clockTokensIn` per token, "12h" = noon, the question names the open times and moves only them                                                                                                                                  | contracts, functions `assistant-text.ts`                                                                                                  |
| LUMI-04 misread hour saved unflagged      | **fixed**: each model time checked against its own words; a mismatch → the words' reading, flagged                                                                                                                                         | functions `assistant-text.ts`                                                                                                             |
| LUMI-05 old app cannot show `timer`       | **fixed**: `clientDraftKinds` in the envelope, stored on the task; kinds the app did not declare → `APP_UPDATE_NEEDED` with a link, 0 credits                                                                                              | contracts, `assistant.ts`, worker; app sends it on every call                                                                             |
| LUMI-07 side flagged / no row             | **fixed**: side from the words only; timer drafts checked by time only; app side row on breast timers                                                                                                                                      | functions; app `assistant_fix.dart`                                                                                                       |
| LUMI-08 milk review                       | fixed earlier (`f846dda`)                                                                                                                                                                                                                  | —                                                                                                                                         |
| LUMI-09 answered start flagged            | **fixed** (server drops doubts on server-filled times; app names the start / end)                                                                                                                                                          | functions; app                                                                                                                            |
| LUMI-10 sleep concern → observation       | **fixed**: `sleepConcernIn` → care; app `when` row also when set                                                                                                                                                                           | worker; app                                                                                                                               |
| LUMI-11 past reminder ready then refused  | **fixed**: `zoneDraftProblems` at prepare / view / edit; `PAST_TIME` names `time`                                                                                                                                                          | `assistant-writers-images.ts`, `assistant.ts`, store                                                                                      |
| LUMI-12 extra / wrong questions           | **fixed**: "Lumi làm được gì?" → HELP; a feeding worry is not a sleep question; "12h30" correction; "bú sữa" alone asks read or log (no timer without "đang / vừa / rồi")                                                                  | worker, planner                                                                                                                           |
| LUMI-13 dropped item not named            | **fixed**: notices name the item; pump / diaper / growth drafted; head circumference → `PART_NOT_SAVED` with `/care/growth`                                                                                                                | `assistant-talk.ts`                                                                                                                       |
| LUMI-14 relative gets the credit balance  | **fixed**: every read offered, `READ_DENIED` (free) for what the role cannot read; never the balance for a care question                                                                                                                   | worker                                                                                                                                    |
| LUMI-15 "bé bu 120m"                      | **fixed**: a bare `m` ≥ 50 after bú is ml; a feed length > 60 min without a unit is flagged                                                                                                                                                | contracts `bareMAmountIn`, planner                                                                                                        |
| LUMI-16 expense only the model sees       | **partly**: goods counted by the box ("hai hộp sữa") keep the task private from the start; the prompt asks for an expense with no amount. When the model still returns only the feed, nothing is invented (`ex-21`) — owner decision below | contracts spending signals, prompt                                                                                                        |
| LUMI-17 empty store flagged               | passes (only filled fields are ever unsure)                                                                                                                                                                                                | —                                                                                                                                         |
| P2 copy                                   | **fixed**: "hay hay", an ISO reset date, the item named in notices, every flagged field has its own fix row                                                                                                                                | tools, talk; app                                                                                                                          |

For the owner to decide:

1. **Head circumference** ("vòng đầu 40cm"): the growth module (form, Rules `validCareData`) has no
   such field, so chat names it (`PART_NOT_SAVED`) and saves weight and length only. Adding it is a
   module change (contracts `growthDataSchema`, Rules, GrowthScreen, charts).
2. **Goods bought with no amount and no expense from the model** (LUMI-16, `ex-21`): kept private,
   no expense invented. A deterministic "shop + goods" expense draft (amount to fill) is possible but
   would also fire on messages that are not purchases.
3. **Old app builds**: they now get "Phiên bản ứng dụng này chưa …" with a link instead of a timer /
   pump / diaper / growth draft. Server and app can ship in either order; the new app must be in
   the stores before the copy asks people to update.

## Owner decisions 2026-10-16 (items 1 and 2 above) — run of the same day

1. **Head circumference** is now part of Tăng trưởng: contracts `growthDataSchema.headCm`
   (optional, 20…60 cm, one decimal), Rules `validCareData` (optional key, old records and old
   apps unchanged), GrowthScreen / record detail / history (a "Vòng đầu" tab with the WHO
   head-circumference-for-age band from `hcanthro`) / 20i / the baby profile, Lumi's growth draft
   (writer, review fields, editor, inline fix). `PART_NOT_SAVED` is no longer sent for it.
2. **A purchase without an amount** is an expense draft whose amount Lumi asks on the card ("Hết
   bao nhiêu tiền?"); plans / to-dos become a reminder or nothing, questions get help (functions
   `checkPurchases`, contracts `purchasesIn`, prompt `assistant-extract-v6`).

| Run                                  | Cases                                            | Result             | Model calls | Tokens in / out | Est. cost (gpt-4.1-mini) |
| ------------------------------------ | ------------------------------------------------ | ------------------ | ----------- | --------------- | ------------------------ |
| fake, full catalogue, strict         | 272 (28 new)                                     | 272 / 272, 0 known | 0 (free)    | —               | 0                        |
| live, new cases only (§5a test plan) | 20 (`pd-16`, `pd-23…28`, `ex-30…35`, `ex-40…46`) | 18 / 20            | 20          | 95 485 / 3 950  | ≈ US$0.045               |
| live, the two fixed cases again      | 2 (`ex-32`, `ex-42`)                             | 2 / 2              | 2           | 9 579 / 375     | ≈ US$0.005               |

Live findings, fixed and scripted as fake cases: the model returned "đặt tã online" as an undated
reminder (now the expense, `ex-37`); "cần mua thêm tã" as a reminder (accepted: a to-do is a
reminder or nothing, `ex-42`). App replay strict: 0 violations (new check `NO_AMOUNT_ASK`).
