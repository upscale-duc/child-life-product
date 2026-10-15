# Child Life Assistant — test report (2026-10-15)

| | |
|---|---|
| Pack | `Child-Life-Chat-v3` (37 contract cases, 21 model-eval cases, integration checklist M01–M12), brief v3 J01–J10 (p.23); vectors copied to `packages/contracts/test/vectors/assistant-v3/` (synthetic, `test_` ids) |
| Commit | `9a105a0` (branch `s2-onboarding`). Other sessions were editing `firebase/functions/src/assistant-images.ts`, `packages/contracts/src/index.ts` and adding `assistant-staff.ts` while these suites ran; the runs used the working tree at that moment. Re-run before any deploy. |
| Runs | 2026-10-15, 13:20–13:40 (Asia/Ho_Chi_Minh), macOS, Node 22.22, Flutter 3.44.8 |
| Clock | fixture clock 2026-10-15T07:20Z (14:20 Asia/Ho_Chi_Minh); tests use fixed instants |
| Environments | contracts and functions vitest (no network); Firestore + Storage emulators on an isolated config (ports 8590 / 9690, private `TMPDIR`); Flutter widget and golden tests with a fake repository. **Not deployed to dev; no device run.** |
| Model | scripted `fakeModelGateway` everywhere; the OpenAI request shape is unit-tested without network. **No live model call was made.** |
| Locales / themes | vi and en; goldens in Light and Night care (no Night care frames exist in Figma) |
| Decisions | P-155–P-161, D-075 #1–#5; evaluation and rollout in `docs/assistant/evaluation.md`, `runbook.md` |

**PASS** = ran here and matched. **BLOCKED** = needs something not available (key, approval,
reviewer, devices, a deploy). **POSTPONED** = the owner moved it later (D-074 store payments).
**NOT COVERED** = no test proves it; listed in §8. The pack's `run_simulation.py` result is reference
simulation only and is not evidence here. Test-file keys (`C`, `FM`, `FI`, `AI`, `II`, `CI`, `AR`,
`IR`, `DT`, `DC`, `DP`, `G4`, `G5`) and full test names per case: `docs/assistant/evaluation.md` §1–§3.

## 1. Pack contract cases through the real code (37 / 37)

| Case | Evidence (server · app) | Status |
|---|---|---|
| D01 draft does not write | `AI` D01, `C` text batch · `DT`, `DC` text task | PASS |
| D02 edit and save | `AI` D02 · `DC` CH06 edit | PASS |
| D03 partial save, retry | `AI` D03, J01 · `DC` CH07 partial, retry only failed | PASS |
| D04 stale | `AI` D04, `C` D04/D05 · `DC` stale draft, `DT` D04/D05 | PASS |
| D05 expiry | `AI` D05 · `DT` D04/D05 | PASS |
| D06 invalid amount | `AI` D06, `C` D06 · `DT` D06 | PASS |
| D07 invalid sleep | `AI` D07, `C` future / never flipped · `DT` D07 | PASS |
| D08 confirm at 0 credits | `AI` D08 · `DC` CH21 | PASS |
| U01 replay | `AI` U01, M01 · `DC` same-id retry | PASS |
| U02 key conflict | `AI` U02, `C` U02 · `DT` U02 | PASS |
| U03 block photo before dispatch | `AI` U03, `II` U03 · `DC` CH20 | PASS |
| U04 error release | `AI` U04, model timeout, `C` failure → release | PASS |
| U05 clarify in the same task | `AI` U05, `C` clarify → hold · `DC` chip / "Tự nhập" | PASS |
| U06 cancel + late callback | `AI` U06, M03 · `DC` "Huỷ" | PASS |
| U07 concurrent reservation | `AI` M02 (20 concurrent starts, 1 credit → ≤ 1) | PASS (emulator) |
| U08 upgrade resume | `AI` U08 · `DC` CH22 → CH23, resume once | PASS (fake store) |
| U09 unverified purchase | `AI` U09 | PASS |
| U10 health at zero | `AI` U10, `C` health, `FM` urgent signs · `DC` CH28 at 0 | PASS |
| S01 viewer reads, no write | `AI` S01, `AR` relatives read nothing · `DC` viewer (CH27) | PASS |
| S02 cross household | `AI` S02, `AR` | PASS |
| S03 cross child | `AI` S03 · `DC` another scope | PASS |
| S04 consent | `AI` S04 · `DC` no consent / declining | PASS |
| S05 consent revoked before worker | `AI` S05, M09; `II` M09 (photos) | PASS |
| S06 membership revoked after draft | `AI` S06, M05 | PASS |
| I01 blurry, no charge | `II` I01, J05, `C` blurry · `DP` CH14 unreadable | PASS |
| I02 receipt review, total incl. tax | `II` I02 ×2, J03, `C` I02 · `DP` date "?" / duplicate | PASS |
| I03 duplicate review | `II` I03 · `DP` "Vẫn lưu", "Mở khoản chi trùng" | PASS |
| I04 unknown currency | `II` I04, `IR` USD, `C` I04 · `DP` refused currency | PASS |
| I05 honest retention | `II` I05, M07 · `DP` G05 ×2 | PASS (emulator Storage, failing delete simulated) |
| I06 note fallback | `II` I06 ×2, J04, `C` I06 · `DP` CH13 | PASS |
| I07 note dates | `II` I07, `C` I07 / G03, `FI` G03 · `DP` weekday ≠ date | PASS |
| R01 summary | `AI` R01, J02, `C` R01, `FM` wording numbers · `DC` CH08, `DT` R01 | PASS |
| R02 recipe eligibility | `CI` R02, J07, `C` R02 · `DP` CH18 | PASS (seeded test content) |
| R03 read, no write | `AI` R03 | PASS |
| E01 unsupported tool | `AI` E01, `FM` strict schema, `C` injection · `DC` unknown part | PASS |
| E02 duplicate finish | `AI` E02, M03 · `DT` duplicate events | PASS |
| E03 no edit charge | `AI` E03 | PASS |

## 2. Golden journeys J01–J10 (brief p.23)

The brief asks for these end to end **on the app**. Each runs as one server integration test (real
Firestore, scripted model) plus widget tests on a fake repository; none on a device against dev.

| Journey | Evidence | Status |
|---|---|---|
| J01 text batch | `AI` J01 · `DC` CH04–CH07 · `G4` ch04–ch07 | PASS (emulator + widget); device BLOCKED |
| J02 summary | `AI` J02 · `DC` CH08 · `G4` ch08 | PASS (emulator + widget); device BLOCKED |
| J03 receipt | `II` J03 · `DP` CH09–CH12 · `G5` ch09–ch12 | PASS (emulator + widget); device and real OCR BLOCKED |
| J04 note | `II` J04 · `DP` CH13 · `G5` ch13 | PASS (emulator + widget); real handwriting OCR BLOCKED |
| J05 blurry | `II` J05 · `DP` CH14 · `G5` ch14 | PASS (emulator + widget) |
| J06 sleep | `CI` J06 + 5 related · `DP` CH15–CH17 · `G5` ch15–ch17 | PASS (emulator + widget); content review BLOCKED (Q-069) |
| J07 meal | `CI` J07, R02 · `DP` CH18 · `G5` ch18 | PASS with the TEST-ONLY reaction fixture; no reaction module exists, so in production no ingredient is excluded (caveat shown) |
| J08 upgrade | `AI` U03 + U08, `II` U03 · `DC` CH20, CH22 → CH23 | PASS (fake store); real purchase POSTPONED (D-074) |
| J09 paid exhausted | `DC` CH24, CH19 video separate · `G4` ch24 | PASS (widget); server cross-check NOT COVERED (§8 #3) |
| J10 viewer / health | `AI` J10 · `DC` CH27 / CH28 · `G4` ch27, ch28 | PASS (emulator + widget); health numbers' review BLOCKED |

## 3. Integration checklist M01–M12 (pack `integration-checklist.md`)

Environment for every PASS below: Firestore + Storage emulators, commit `9a105a0`, 2026-10-15, Node
22, locale vi fixtures (en for the EN-specific cases). "Dev" = the same check on `child-life-dev` with
`test_` families, which D-072 #4 makes the staging stand-in.

| ID | Expected | Evidence | Emulator | Dev / device |
|---|---|---|---|---|
| M01 replay / same key other input | same task / conflict | `AI` M01, U01, U02 | PASS | BLOCKED (not deployed) |
| M02 20 requests, quota for one | ≤ 1 reservation | `AI` M02 | PASS | BLOCKED (concurrency on real Firestore not run) |
| M03 duplicate worker / late callback after cancel | one charge, stale worker fenced | `AI` M03, U06, E02 | PASS | BLOCKED |
| M04 timeout after write, retry | one record, same id | `AI` M04 | PASS | BLOCKED |
| M05 role revoked / child changed after preview | denied / scope mismatch | `AI` M05, S06 | PASS | BLOCKED |
| M06 other household image / expired target / MIME | rejected before provider | `II` M06 ×3, `IR` Storage refusals | PASS | BLOCKED (real bucket, Cloud Run) |
| M07 Storage delete fails | pending + retry, never false "đã xoá" | `II` M07, I05 · `DP` G05 | PASS (in-memory failing store) | BLOCKED (real GCS failure not provoked) |
| M08 duplicate / out-of-order purchases | verified period, no extra pool | `AI` U08, U09 (same grant → same window); `billing.integration.test.ts` "renew, grace, revoke, duplicates and out-of-order events reconcile to one grant" (12 / 12 run here) | PASS (fake store) | POSTPONED (D-074: no store yet) |
| M09 consent revoked queued / running | no dispatch, safe reconciliation | `AI` S05, M09; `II` M09 (photos) | PASS | BLOCKED |
| M10 stale draft / TTL / source record edited | review conflict, no overwrite | `AI` M10, D04, D05 | PASS | BLOCKED |
| M11 drop / reorder / duplicate reconnect events | one card, final snapshot correct | `AI` M11 · `DT` reconnect group · `DC` "duplicate / old events and older snapshots are ignored", "back online: open tasks are fetched again" | PASS | BLOCKED (real network drops on devices) |
| M12 month / DST / zone boundary | reservation pinned, one reset | `AI` M12 (task across 2026-10-31 → 11-01 local midnight stays in October) | PASS (month boundary) | DST and a household zone change: NOT COVERED (§8 #5); dev BLOCKED |

Also required by the pack: real OCR / NLP evaluation — **BLOCKED** (§4); actual Flutter UI EN / VI —
**PASS on widgets and goldens, device BLOCKED**; iOS / Android sandbox purchases — **POSTPONED**
(D-074); approved regional clinical content — **BLOCKED** (Q-069); consent and provider retention
terms — **BLOCKED** (owner copy, G05 / Q-076).

## 4. Model evaluation dataset (21 cases) — NOT RUN LIVE

Every case is **BLOCKED**: no `OPENAI_API_KEY` on dev, no owner approval for spend and for sending
the synthetic images to the provider, harness not built (`evaluation.md` §5–§7). What the scripted
tests already fix is the server's handling **given** a model output; whether the model produces it is
unknown.

| Cases | Server behaviour already tested with scripted output | Live |
|---|---|---|
| `text_vi`, `text_en`, `typo` | drafts not writes, local times in the baby zone (`AI` D01, `FM` zone) | BLOCKED |
| `ambiguous_vi`, `ambiguous_en` | AM/PM asked, never guessed; sleep never flipped overnight (`AI` "\"8 giờ\" …", D07) | BLOCKED |
| `missing_unit` | a bottle without ml cannot be saved (`MISSING_AMOUNT`, contracts `draftProblems`) | BLOCKED |
| `summary_vi`, `summary_en` | numbers from `careSummary`, wording limited to its facts (`AI` R01, `FM`) | BLOCKED |
| `sleep_vi`, `sleep_en`, `meal_vi`, `meal_en` | care from approved content only; child scope; recorded reactions excluded (`CI` J06, J07) | BLOCKED |
| `currency` | an expense without a supported currency cannot be saved (`draftProblems`, `II` I04) | BLOCKED |
| `weekday` | weekday ≠ date asked, never picked (`II` I07, `FI` G03) | BLOCKED |
| `unsupported`, `injection` | strict schema: unknown tool / key → rejected, 0 credits, no write (`AI` E01, `FM`) | BLOCKED |
| `health_fixture` | health support free, no generated advice, regional number only (`AI` U10, `CI` health ×3) | BLOCKED |
| `mixed` | receipt + prescription asks what to do; medicine never scheduled (`II` "prescription only …") | BLOCKED |
| `receipt_image`, `board_image`, `blur_image` | printed total 486 000, note line kinds, unreadable → 0 credits (`II` I01, I02, I06, J03–J05) | BLOCKED |

## 5. D-075 owner answers

| Answer | Evidence | Status |
|---|---|---|
| #1 one credit pool (chat + summaries), beta may give every Premium feature | `AI` "Free is 20; a beta campaign giving the Premium budget makes it 200 …", "a promo grant giving Premium uses the premium pool …"; `ai-summary.integration.test.ts` D-075 #1 ×3, A01; `entitlements.integration.test.ts` "D-075 #1: a beta with templates opens Cao cấp templates and the Premium credit budget"; contracts `entitlements.test.ts` D-075 #1 ×3 | PASS (emulator); portal campaign form not re-run here |
| #2 one shared conversation per baby, spending excluded | `AI` D-075 #2 ×6; `AR` D-075 #2 ×4; `DP` "D-075 #2 shared thread" ×5 | PASS |
| #3 receipt photos kept with the expense by default | `II` "D-075 #3: without a choice the receipt is kept …"; `DP` "retention default follows D-075 #3"; `FI` D-075 | PASS |
| #4 Chi tiêu currencies | `II` I04; `IR` "expense in USD: cents and the currency …"; `FI` currencies; `G5` ch11_receipt_usd | PASS |
| #5 date-only reminders and an assignee | `II` I07, "D-075 #5: a written name → the person picks …"; `IR` "reminder all day with an assignee …"; `DP` "D-075 #5 reminder drafts" ×3 | PASS |

## 6. Suites run for this report

| Suite | Command | Result |
|---|---|---|
| Contracts | `pnpm --filter @child-life/contracts test` | 20 files, **223 pass** (assistant 20, entitlements 32) |
| Functions unit | `cd firebase/functions && npx vitest run` | 11 files, **82 pass, 1 skipped** (mail preview gallery); assistant-model 15 + assistant-image-model 11 |
| Emulator (Rules + integration) | `firebase emulators:exec --config <own copy> --only firestore,storage … vitest run assistant ai-summary entitlements quota` | 12 files, **232 / 232 pass**: assistant.integration 63, assistant-images.integration 32, assistant-care.integration 19, assistant.rules 16, assistant-images.rules 13, ai-summary.integration 28, ai-summary.rules 11, entitlements.integration 15, entitlements.rules 6, quota.integration 16, quota-sweeper.integration 2, video-quota.integration 11 |
| Emulator, billing (M08) | same config, `vitest run billing.integration` | 1 file, **12 / 12 pass** |
| Flutter assistant | `flutter test test/features/assistant_test.dart test/features/assistant_chat_test.dart test/features/assistant_photo_care_test.dart test/golden/assistant_golden_test.dart test/golden/assistant_a5_golden_test.dart` | **248 pass**: assistant_test 29, assistant_chat 45, assistant_photo_care 46, goldens 68 (17 scenes × Light / Night care × vi / en) + 60 (15 scenes × 4) |

Assistant-specific total: **20 + 26 + 143 + 248 = 437** tests, all passing. Not re-run for this
report: `pnpm typecheck`, `pnpm lint`, `flutter analyze`, the whole `firebase/tests` suite, portal
vitest.

## 7. Not verified (required before production — `docs/assistant/runbook.md` §9)

| Check | Status | Why |
|---|---|---|
| Deploy to `child-life-dev`, callable invoker curl-check, indexes built | BLOCKED | Not deployed in this work; docs only |
| End to end on iPhone and Android against dev, Light / Night care, vi / en | BLOCKED | No device run; checklist §22 rows stay ◐ |
| Live model evaluation (text, receipts, notes, safety), latency, tokens, cost | BLOCKED | No `OPENAI_API_KEY` on dev, no owner approval; harness not built (`evaluation.md` §7) |
| Human review of outputs in vi / en | BLOCKED | Needs the live run and reviewers |
| Care content, recipes, health numbers per region | BLOCKED | Q-069 reviewer; recipe pack not published |
| Consent / retention copy and provider terms | BLOCKED | Owner copy (G05, Q-076) |
| Store sandbox purchase, restore, renew (U08, M08, J08 on stores) | POSTPONED | D-074 |
| Race checks (M02, M03) and index behaviour on dev | BLOCKED | Emulator only so far |
| Night care visual review | BLOCKED | Figma has no Night care chat frames; goldens are built from tokens |

## 8. NOT COVERED — gaps found while writing this report

1. ~~Stale assistant reservations are never swept.~~ **Fixed after this report**: `sweepAiQuota` also
   releases stale summary credits (`su_*`) in the `assistant` pool; test
   `quota-sweeper.integration.test.ts` "D-075 #1: releases a stale summary credit".
2. ~~A task stuck in `queued` is never requeued.~~ **Fixed after this report**: `sweepAssistant` nudges
   a `queued` task untouched for 10 min (3 times), then fails it and releases its credits; test
   `assistant.integration.test.ts` "sweeper: a task left queued is nudged three times".
3. **J09 server side**: no test asserts that direct logging, Cao cấp templates and the video quota
   keep working when the assistant pool is empty (true by construction — separate ledgers or none —
   but unproven).
4. **`deletion_pending` retries without a limit** (backoff capped at 6 h) and nothing alerts; the
   brief asks for no infinite retries and a manual fallback (p.26). Test covers the pending state, not
   an escalation.
5. **M12 DST / zone change**: only the month boundary in Asia/Ho_Chi_Minh (no DST) is tested; a
   household changing time zone mid-window, or a DST zone, is not.
6. **Tokens and latency are not recorded per task**; cost is a flat 300 VND per call
   (`assistantCallCostVnd`). The live eval must measure them; production has no cost-per-task metric.
7. **No assistant analytics events** (`appEventsDaily` counters) — the pilot metrics in brief p.25
   (time saved, corrections, return days) cannot be measured yet.
8. **No push / lock-screen path** for the CH17 follow-up; it appears only in the chat when due (brief
   p.26 asks that reminders never expose health content — nothing is sent today).
9. **App Check is not enforced** on the assistant callables (`security.md` §1).
10. **HEIC**: accepted at upload; decoding depends on the server's sharp build; no test with a real
    HEIC file.
11. **Goldens missing** for CH01b (Chi tiêu entry), CH03 (history), CH22 (upgrade sheet) and CH23
    (resumed task); their behaviour is covered by widget tests only.
12. **Portal assistant operations** (usage, tasks, stuck-task tools) are not built yet; the
    `assistant-staff.ts` work was in progress in another session and is not covered here.
13. **Recorded reactions**: no module records them, so J07's exclusion is only proven with the
    TEST-ONLY fixture; in production every recipe carries the "tolerance unknown" caveat.
