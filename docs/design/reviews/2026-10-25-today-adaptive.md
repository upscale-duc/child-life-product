# Design review — Hôm nay, Adaptive (A · Dashboard) · 2026-10-25

Sample review produced with the `cl-design-review` skill (Step 8). Read-only: nothing was changed.

> **Update 2026-10-25:** the owner chose Version A (D-108). The Approval column predates D-109:
>
> - **Routine** is now L1 / L2;
> - TA-4 (canonical term) is still L3;
> - TA-5 (greeting addressee) is L1 / L2 copy, and D-108 keeps the current intent.

## 1. Executive summary

- **Screen:** Adaptive Today (`apps/mobile/lib/features/today/today_screen.dart` with
  `adaptiveOnProvider` on; sections from `features/adaptive/today_adaptive.dart`, order from
  `rankToday` in `features/adaptive/adaptive_engine.dart`). Archetype **A, Dashboard**. Role
  reviewed: parent (relative and caregiver only in code).
- **User job:** see the latest care state of this baby, notice what's due or overdue, and log the
  next thing with one tap.
- **Overall assessment:**
  - **Critical gates:** none failed. **G1 at risk** (loading can render as "Chưa có"; visibility
    unverified).
  - **Dimension scores:** strong care tiles and identity; weakest on content and localisation,
    states, and accessibility (essential reminder times truncated in vi and en).
- **Top problems:**
  1. **Reminder status and time are cut off** in both languages, including the overdue time, so a
     parent can't tell when the vaccine is due.
  2. **Loading uses the empty fallback:** tiles can say "Chưa có" before data arrives, telling a
     parent nothing was logged when it was.
  3. **Overdue is shown in error red** and the section is named "Nhắc nhở" here but "Nhắc việc"
     on legacy Today, which makes it alarming and inconsistent.
  4. **For the 3–6 band, an empty placeholder dominates** the first viewport (`ax12`).
- **Main recommendation:** make the reminders card a two-line row layout (title, then status and
  time, untruncated), and show a skeleton until the first data arrives. Both are routine,
  behaviour-preserving fixes.

## 2. Evidence coverage

| Source | Inspected |
|---|---|
| Code | `today_screen.dart:66-90` (data reads, `readOnly`), `today_adaptive.dart:66-90` (greeting), `today_adaptive.dart:138` (`AxCard`), `adaptive_engine.dart` (`RankWeights`, `rankToday`) |
| Goldens | `ax/ax10_today_0_1_light_vi.png`, `ax10_today_0_1_nightCare_vi.png`, `ax10_today_0_1_nightCare_en.png`, `ax40_first_0_1_light_vi.png`, `ax12_today_3_6_light_en.png` |
| Locales | vi ✓ · en ✓ (`ax10` Night, `ax12` Light) |
| Themes | Light ✓ · Night care ✓ |
| States | Loaded (0–1 band) ✓ · first run (0–1) ✓ · 3–6 band ✓ · offline adaptive ✗ (legacy offline seen in `s4/9a_today_offline`) · loading ✗ (not renderable in goldens) |
| Roles | Parent ✓ · relative / caregiver: code only (`readOnly`, `availableWidgetsProvider`) |
| **Not evaluated** | Text scale, long names, small screens, screen reader and focus order, motion, real devices, the 1–3 and 6–12 bands (`ax11`, `ax13` not opened), en Light for `ax10` |

**Fixture caveat:**

- the `ax12` (3–6 years) render shows the header chip "Teddy · 3 weeks";
- the first-run render (`ax40`) shows an overdue reminder.

Both are fixture artefacts: judge the layouts, not the data combination.

## 3. Scorecard

**Critical gates:**

| Gate | Status | Why |
|---|---|---|
| G1 Business meaning | **At risk** | C: `today_screen.dart:70` `recentRecordsProvider(...).value ?? const []` → tiles render `todayTileEmpty` "Chưa có" while loading. H: whether it's visible depends on cache speed |
| G2 Critical action access | Pass | Tiles and the dock reachable, with labels; 200 % text not evaluated |
| G3 Data-loss risk | Pass | No destructive actions on the screen |
| G4 Permissions | Pass (C) | Relatives: `readOnly` hides logging, reminders and quick actions; not rendered |
| G5 AI and health claims | Pass | No AI or health claims in the reviewed widgets |
| G6 Primary task usability | Pass | |

| # | Dimension | Score | Coverage | Note |
|---|---|---|---|---|
| 1 | Task clarity | 3 | vi / en, L / N | The tiles answer "latest state" well. The greeting "Chào buổi chiều, Teddy" addresses the baby (C: `baby?.nickname`), while the reader is the parent |
| 2 | Information hierarchy | 3 | 0–1 + 3–6 bands | 0–1: tiles first, then reminders, then memories: right order. 3–6: the empty "Save today's moment" placeholder (large grey box + filled button) dominates the first viewport |
| 3 | Scanability and density | 3 | vi / en | Tiles are excellent (value + relative time + who). The reminder rows lose status and time to ellipsis |
| 4 | Interaction clarity | 3 | vi / en | One tap per tile; "Ghi lần đầu" pills clear. Header links vary ("Xem lịch sử", "Tất cả", "Xem tất cả") |
| 5 | Navigation and flow | Not evaluated | — | No navigation evidence inspected |
| 6 | Visual coherence | 3 | L / N | The AxCard (hand-rolled, radius 20) differs from the core group radius 24. Night care is consistent |
| 7 | Content and localisation | 2 | vi / en | Truncation in both languages; "Nhắc nhở" vs legacy "Nhắc việc"; the greeting's addressee. `{name}` empty while loading → "Chào buổi chiều, " (C) |
| 8 | States and trust | 2 | Code + first run | Loading = empty fallback (C). First run is good: tiles invite "Ghi lần đầu". Adaptive offline not rendered |
| 9 | Accessibility and adaptability | 2 | Default text only | An essential value (the overdue time) truncated at 100 % text; 200 %, screen reader and long names **not evaluated** |
| 10 | Product identity | 4 | L / N | Warm care colours and art, calm Night care. Error red for a routine overdue item is the one off-tone element |

**Verdict:** no gate failed (G1 at risk). **Acceptable with High-severity issues.** The lowest
dimensions are 7, 8 and 9. Mean of the nine evaluated dimensions 2.8 (25 / 9); not used alone.

## 4. Findings

| ID | Screen | User job | Observed issue | Evidence | Reference | User impact | Severity | Priority | Recommended improvement | Approval | Confidence |
|---|---|---|---|---|---|---|---|---|---|---|---|
| TA-1 | Adaptive Today, reminders card | Know what's due | The status and time column is ellipsised: "còn 2 n…"; en "yesterday 18:…", "in 2 d…" | R | `ax/ax10_today_0_1_light_vi`, `_nightCare_en`; = patterns audit #1 | Can't tell when the vaccine is due or how overdue the item is | **High** | **P0** (daily screen) | Two-line rows: title, then status and time (as legacy Today renders); never ellipsise the time | Routine | High |
| TA-2 | Today (both paths) | Trust the latest state | Tiles fall back to an empty list while loading, so "Chưa có" can show for logged categories | C (+ H visibility) | `today_screen.dart:70`, `todayTileEmpty`; = patterns audit #5 | A parent may think a feed wasn't saved, and log it twice | **High** | **P1** (verify visibility first: a cold start on a device) | A skeleton for the tiles until the first value arrives; "Chưa có" only after data resolves | Routine (presentation) | Medium |
| TA-3 | Adaptive Today, reminders | Notice urgency calmly | Overdue "Quá hạn · hôm qua 18:00" in error red; Handover shows overdue on warm `sunshineSoft` | R | `ax10_*`, `ai/su01_ai`; = patterns audit #2 | Alarm tone for routine tasks; inconsistent urgency language | Medium | P1 | The warm attention treatment + icon, everywhere | Routine (check that red wasn't a decision) | High |
| TA-4 | Adaptive vs legacy Today | Find reminders | Section "Nhắc nhở" (adaptive) vs "Nhắc việc · 3" (legacy) | R | `ax10_*`, `s4/19_today`; = ux-writing #9 | The same feature named differently depending on a flag | Medium | P2 | One term | **Owner** (canonical) | High |
| TA-5 | Adaptive Today, greeting | Feel addressed | "Chào buổi chiều, Teddy" greets the baby; with no nickname yet it renders "Chào buổi chiều, " | R + C | `ax10_*`; `today_adaptive.dart:68` (`baby?.nickname ?? ''`) | An odd voice for the parent; a broken string while loading | Low | P2 | Decide the addressee; never render an empty `{name}` (fallback "bé" / omit) | **Owner** (copy intent) / Routine (empty-name fallback) | Medium |
| TA-6 | Adaptive Today, 3–6 band | See what matters now | The empty "Save today's moment" card with a large grey placeholder + filled button fills the first viewport | R | `ax/ax12_today_3_6_light_en` | Prime space spent on an empty slot; care information pushed down | Medium | P2 | Collapse the empty state to one compact invitation row; show the media area only when there is a moment | Routine (layout, same behaviour) | Medium |
| TA-7 | Adaptive Today, section links | Know where a link goes | Three link labels for the same "see more" pattern: "Xem lịch sử", "Tất cả", "Xem tất cả" | R | `ax10_*`, `ax40_*` | Minor inconsistency | Low | P3 | One link label pattern naming the destination | Routine (copy via `cl-ux-writing`) | High |
| TA-8 | First run | Start logging | The first-run header link "Xem lịch sử" leads to an empty history | R + H | `ax40_first_0_1_light_vi` | A dead end on the first visit | Low | P3 | Hide the history link until there is history | Routine | Low (H: check the destination) |

## 5. Recommended improvements

| Group | Items |
|---|---|
| Fix now, routine | TA-1 (truncation); TA-3 (overdue tone); TA-2 after confirming visibility on a device; the empty-name fallback in TA-5 |
| Needs owner decision | TA-4 (term); the TA-5 addressee |
| Next cycle, routine | TA-6, TA-7, TA-8 |
| Coverage to add (test-only, authorised separately) | Text-scale and long-name variants for `ax10`; an adaptive offline golden; a loading-state widget test |

**Owning skills:**

- `cl-screen-patterns`: TA-1, TA-6, TA-8;
- `cl-design-foundations`: TA-3;
- `cl-ux-writing`: TA-4, TA-5, TA-7;
- `cl-components`: the TA-2 skeleton.

## 6. Before / after verification

Not applicable: nothing implemented.

## 7. Open questions

- Should the adaptive greeting address the parent or the baby? (TA-5)
- Which term is canonical: "Nhắc việc" or "Nhắc nhở"? (TA-4)
- Was error red for overdue reminders a deliberate decision? (TA-3)

## 8. Tóm tắt cho chủ sản phẩm

- **Vấn đề:**
  - Thẻ nhắc việc trên màn Hôm nay (bản mới) bị cắt chữ ở cả tiếng Việt và tiếng Anh, nên ba mẹ
    không đọc được việc quá hạn từ khi nào hay bao giờ tới hạn.
  - Lúc app vừa mở, các ô chăm sóc có thể hiện "Chưa có" dù đã ghi rồi.
  - Việc quá hạn đang hiện màu đỏ như báo lỗi, và mục này được gọi "Nhắc nhở" ở bản mới nhưng
    "Nhắc việc" ở bản cũ.
- **Vì sao quan trọng:** đây là màn ba mẹ mở nhiều nhất. Thông tin bị cắt hoặc hiện sai lúc tải
  làm ba mẹ mất niềm tin, có khi ghi trùng một cữ bú.
- **Nên thay đổi:**
  - cho giờ nhắc việc xuống dòng thay vì bị cắt;
  - hiện khung chờ khi đang tải, thay vì "Chưa có";
  - đổi màu quá hạn sang vàng ấm như màn Bàn giao.

  Tên mục và lời chào cần anh/chị chọn.
- **Phụ huynh sẽ thấy:** nhìn một lần là đọc đủ việc sắp tới; con số luôn đúng ngay khi mở app;
  cảnh báo bình tĩnh, nhất quán.

---

## Appendix: calibration across six screens (rubric applied briefly)

Applied to test the methodology. Details of each finding are in
`.claude/skills/cl-screen-patterns/references/screen-pattern-audit.md` (P-#) and
`.claude/skills/cl-ux-writing/references/content-audit.md` (W-#).

| Screen | Archetype | Gates | Lowest dimensions (score, coverage) | Strongest | Main finding |
|---|---|---|---|---|---|
| Today, legacy (`s4/19_today`) | A | G1 at risk (same loading path) | 8 States: 2 (C) | 3 Scan: 4 | Loading fallback (P-5); overdue red (P-2) |
| Care History (`s6/20_history`) | B | Pass; G1 at risk (`_EmptyDay` while loading, C) | 7 Content: 2 ("1 feeds", R en) | 1 Task: 5, 2 Hierarchy: 5 | Plural bug (P-4 / W-1); non-tappable baby chip (P-10, C) |
| Sleep stats (`s6/20h_sleep_stats`) | C | Pass | 9 A11y: Not evaluated (chart semantics unchecked) | 3 Scan: 5 | The summary restates the chart (P-15, Low) |
| Memories (`s9/10a_journal`, `10b2_select`) | F | Pass | 4 Interaction: 2 (selection bar covers items, R) | 10 Identity: 5 | P-6, P-7, P-8 |
| Paywall v2 (`pv2/pw01_video`, `pv40b_free`) | H | Pass | 9 A11y: 3 (fine print size and contrast H) | 10 Identity: 4, 7 Content: 4 (calm, price on the CTA) | P-12 (H) |
| Handover (`ai/su01_ai`, `su01_stale`) | I / C | Pass (G5 explicitly well handled: basis, AI collapsed, stale notice) | 5 Flow: Not evaluated | 2 Hierarchy: 5, 8 States: 5 | Reference implementation |

**Calibration notes:**

- Gate-first scoring surfaced "G1 at risk" on three screens from one shared code pattern
  (`.value ??`). That's useful prioritisation that visual-only review missed.
- "Not evaluated" appeared for text scale and screen reader on every screen; adding that coverage
  is the highest-leverage test investment.
