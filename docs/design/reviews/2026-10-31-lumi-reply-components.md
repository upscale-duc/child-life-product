# Lumi reply components: audit and L1/L2 fixes (2026-10-31)

Owner, 2026-10-31: "format ko tốt và ui/ux cũng rất khó đọc". Example: the care_summary card read
"Bottle feeds logged today (until 14:17): 2, 300 ml." / "Breastfeeds logged today: 0, 0 min." /
"Sleep logged today: 2, 362 min."

## Tóm tắt cho chủ sản phẩm

- **Thẻ đọc dữ liệu của Lumi (read card) đã được làm lại**: mỗi dòng là "nhãn ← → con số" như sao
  kê ngân hàng (nhãn mờ bên trái, số đậm bên phải), chi tiết phụ (giờ gần nhất, ngày đo, người
  được giao) nằm dòng nhỏ dưới nhãn. Không còn câu văn dài, không còn "0 lần, 0 phút", phút đổi
  thành giờ ("6 giờ 2 phút"), tiền có dấu chấm nghìn ("2.450.000 VND"), ngày bỏ năm hiện tại.
- Dòng có màn hình chi tiết thì **chạm cả dòng** (mũi tên ›), thay cho 8 lần "Xem chi tiết" lặp lại.
- "Ngày của bé" gộp "Gần nhất · …" vào đúng dòng của nó: 9 dòng → 5 dòng.
- Các thẻ khác (nháp, lưu một phần, tóm tắt bú, thông báo, lỗi, đồng ý dùng trợ lý) render tốt,
  giữ nguyên.
- Không đổi nội dung Lumi khẳng định (cảnh báo, sức khoẻ, AI), không đổi hợp đồng `readCardSchema`.

## Scope and evidence

- Renderers: `apps/mobile/lib/features/assistant/assistant_cards.dart` (`AsReadCard`, `AsNoticeCard`,
  receipts, guidance, recipes), `assistant_widgets.dart` (`AsDraftCard`, `AsSummaryCard`,
  `AsHealthCard`, `AsCard`), part switch in `assistant_screens.dart`.
- Server rows: `firebase/functions/src/assistant-reads.ts`, `assistant-tools.ts`
  (`careSummaryTool`, `sleepFactsTool`), `assistant-insight.ts`, recipe card in `assistant-care.ts`.
- Fresh renders (D-111): the 140 existing `as/` chat goldens (drafts, partial, summary, notices,
  failure, consent, health…) were re-run before any change and all matched (Current). Read cards
  had **no golden at all**; `test/golden/assistant_read_golden_test.dart` (new) renders one card per
  read tool in Light / Night care × vi / en (`goldens/as/rc_{daily,records,content}_*`).
- Before: `assets/2026-10-31-lumi-read-before-daily-vi.png`,
  `assets/2026-10-31-lumi-read-before-records-vi.png`. After: `apps/mobile/test/golden/goldens/as/rc_*`.

## Audit

Classification (D-112): **read card RESTRUCTURE**; all other reply components KEEP.

| # | Component | Problem (evidence R = rendered) | Severity | Level | Fix |
|---|---|---|---|---|---|
| 1 | care_summary card | Rows are sentences with an empty label; count and total run together ("2, 300 ml"); "(until 14:17)" repeats the snapshot line; zero modules listed ("0 lần, 0 phút"); 362 phút not as hours (R) | High | L2 | Label/value rows Bú bình / Bú mẹ / Giấc ngủ, "2 cữ · 300 ml", "2 giấc · 6 giờ 2 phút"; zero modules left out; one "Chưa ghi cữ bú hay giấc ngủ nào." row when all are empty; date in the title |
| 2 | All read cards (layout) | Every row stacks label over value (≈60 pt per fact); value 16 pt under a 14 pt label; nothing to scan down (R) | High | L2 | Beside rows: muted label left, bold figure right, detail lines under the label; long values stack, one paragraph per line; hairline separators |
| 3 | All read cards (links) | "Xem chi tiết" under every linked row — 8× in Ngày của bé — competes with the card action (R) | High | L2 | The whole row is tappable with a chevron (same destinations); one action link at the bottom |
| 4 | day_overview | "Gần nhất · bú bình/…" are five extra rows repeating the date "15/10/2026"; "0 lần · 0 ml" rows; minutes as minutes; "1 feeds" (R) | High | L2 | One row per module: "2 cữ · 270 ml" + "Gần nhất 11:00"; nothing today but an earlier log → "Chưa ghi · Gần nhất 22:10 · 14/10"; never logged → row left out; hours; en plurals |
| 5 | diaper_summary (en) | Labels were the raw keys "wet", "dirty", "both"; bare numbers "5"; zero kinds listed (R) | High (en) | L1 | "Wet / Dirty / Wet and dirty", "5 changes", zero kinds left out, single empty-state row |
| 6 | Snapshot line | "Dữ liệu đến 15/10/2026 · 14:17" in full on every card, 12 pt gap after the title (R) | Medium | L1 | Time only when the snapshot is today ("Dữ liệu đến 14:17"), date otherwise, year only if different; tight under the title |
| 7 | sleep_facts | One sentence, "742 phút mỗi ngày" (R) | Medium | L2 | "Gần đây (mỗi ngày) · khoảng 12 giờ 22 phút" / "Trước đó (mỗi ngày) · …" (the model keeps its sentence) |
| 8 | growth_snapshot | "7.2 kg · 10/10/2026 · WHO P50.0" plus a separate delta row "Cân nặng · so với lần trước · +0.35 kg · 12/09/2026 → 10/10/2026"; dot decimals in vi (R) | Medium | L2 | "7,2 kg · WHO P50" + "Đo 10/10 · +0,35 kg so với 12/09" in one row |
| 9 | spending_month | "2450000 VND" without grouping; "Tổng đã chi · VND" even with one currency (R) | Medium | L1 | "2.450.000 VND" / "2,450,000 VND"; currency in the label only when several; "Ngân sách tháng" |
| 10 | vaccine_next, reminders, solids, milestones | Status and people appended with " · " into one long value; repeated "Đã ghi nhận" label with the name in the value (R) | Medium | L2 | Figure first, detail second line ("10/10" + "Lịch đã qua, chưa ghi đã tiêm"; "Cả ngày · Chưa xong" + "Mai"; "2 lần · Chưa hợp" + "Gần nhất 14/10 · Nổi mẩn, mề đay"); milestone name as the label, "Đã ghi 02/10" / "Quanh tuổi bé" as the value |
| 11 | stage | Lists joined with line breaks, no bullets (R) | Low | L1 | "• " per item |
| 12 | insight_basis | Five sentences as one 9-line paragraph (R) | Medium | L1 | One sentence per line (same words, `assistant-insight.ts` joins with `\n`) |
| 13 | Caveat | Bare caption between the rows and the action (R) | Low | L1 | `AsFootnote` box, so the note reads as a note |
| 14 | Recipe ideas card | "…summary · Nguyên liệu đã thử: 2" on one line | Low | L1 | Second line |
| 15 | Drafts, batch bar, partial save, receipt, source summary (CH08), notices, failure/offline, health | Clear state chips, one primary action, units present (R, 140 goldens Current) | — | KEEP | none |
| 16 | Consent card | Long, but legal/privacy wording (R) | — | L3 | untouched |
| 17 | Durations wrap mid-unit ("5 h ⏎ 10 min") in long paragraphs (R) | Low | L1 | not fixed: needs non-breaking spaces in the server text, which the Hiểu con tests match literally; left for a follow-up |

## Simplify (D-110)

| Element | Class | Action |
|---|---|---|
| "Xem chi tiết" per row | Redundant | REMOVE → row tap + chevron |
| "Gần nhất · …" rows | Redundant as rows | MERGE into the module row's detail |
| Zero-count rows / kinds | Redundant | REMOVE (kept as "Chưa ghi" when an earlier log exists) |
| "(đến 14:17)" in care_summary | Redundant | REMOVE (snapshot line says it) |
| Year in dates, full date in the snapshot | Redundant | REMOVE when current |
| Weight delta row | Contextual | MERGE into the weight row |
| " · VND" in a single-currency total | Redundant | REMOVE |
| Caveats, "Lịch đã qua…", symptoms, units, snapshot time | Essential | PRESERVE |

## What did not change

- `readCardSchema` (contract) — rows are still `{label, value, link?}`; the app treats `\n` lines
  as detail, which old cards already used (stage).
- Model-facing facts (`r.facts` sentences) and the understanding prompt: unchanged, so no live run.
- Destinations: row links now open the same routes the "Xem chi tiết" links did; care_summary rows
  gained the stats links Ngày của bé already used. Day overview no longer links to the single
  latest record of each module (reachable from Hôm nay / Lịch sử) — accepted L2 trade-off for 4
  fewer rows.
- Caveat and safety wording, Premium/sparse texts, consent and health cards.

## Verification

- `flutter analyze`: no issues.
- `flutter test test/features/assistant_replay/`: 787 passed.
- `flutter test test/features/assistant_reads_test.dart`: 5 passed (snapshot expectation updated).
- Golden: `assistant_read_golden_test.dart` 12 new baselines; `assistant_golden_test`,
  `assistant_chat_golden_test`, `assistant_shell`, `assistant_timer` unchanged and passing.
  `assistant_a5_golden_test` `ch09_sheet` (photo sheet) differs ~18.7 % — not rendered by any
  changed file (no read card); attributed to another session's uncommitted work, baseline untouched.
- Functions: `tsc`, eslint, `vitest test/assistant*` 169 passed; emulator
  `assistant-reads.integration.test.ts` 11 passed (expectations updated for the new rows).
- Fake e2e (`docs/assistant/test-plan.md` §7): 372 cases, 371 pass, 0 new failures (1 known
  gating failure); read group 47/47. No live (paid) run: model-facing text unchanged.
- Replay fixtures (`assistant_replay/fixtures/rd-*`) still hold the old row text (server snapshots);
  re-export them with the next fake run that owns those files.

## Follow-up after the device check (2026-10-31)

Owner screenshot: "Tuần vừa rồi của con thế nào" → a CH08 card for 25/10 "đến 00:00", a
"✓ Câu hỏi không tạo cữ bú mới" line, and a sentence repeating the card ("2026-10-25 … 822 phút").

| Problem | Fix |
|---|---|
| "Câu hỏi không tạo cữ bú mới" under the CH08 card (V1 reassurance; a question never creates a record) | Removed (D-110, Redundant). The `asNoRecordCreated` ARB key is left unused because others have uncommitted ARB edits; remove it with the next ARB change |
| Text reply repeated the card in raw form (ISO date, minutes) | `assistant-worker.ts`: facts become a sentence only for results without their own card (usage still answers in words) |
| A week question read one day (the model picked dayOffset −6) | `asksAboutWeek` (`assistant-reads.ts`): "tuần vừa rồi / tuần trước / tuần này / 7 ngày / last week" → the read card over the last seven days to now, titled "Bú và ngủ đã ghi · 25/10 – 31/10" (dates shown, so the period is never ambiguous) |
| A finished day showed "đến 00:00" | CH08 card shows "đến HH:mm" only while the snapshot is inside that day |

Tests: `assistant_chat_test` (CH08: note gone; finished day without "đến 00:00"), `ch08_summary`
goldens ×4 regenerated (only the note line removed), integration +1 week case (12 pass), functions
vitest 169, replay 787, fake e2e 0 new failures (read 47/47).
