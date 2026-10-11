# Tiêm chủng (vaccination book): spec extracted from final Figma

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only), page/canvas **"v1.0 - improvement"** `345:35701`, cluster label **394:3800 "Label · Tiêm chủng"** (y ≈ 13925 on the canvas, below cluster 10 of `16-v1-improvement.md`). Extracted 2026-10-11. No Figma node was modified.

**What this cluster is.** A new vaccination book for each baby. It has a first-run checklist, a schedule matrix by vaccine and a timeline by month of age, a milestone screen where parents choose between the service and the free programme vaccine, a full form and a quick form for recording a dose, a dose detail screen, a vaccine info screen, a lock-screen reminder, and overdue handling. It is opened from a new **"Tiêm chủng" tile** on the Chăm sóc (Care) tab, which was added to both CS Chăm sóc frames of cluster 8 after `16` was extracted (see "Compared with the current app").

**How it was read**
- I called `get_design_context` (code, component descriptions and any `data-annotation`) and `get_screenshot` on all 13 frames. Large outputs were read from the saved tool result with a script that prints layer names, rendered text and fill and border tokens. Frames that reuse VX 1 or VX 1b as their background were diffed against them line by line, so only the differences are listed.
- Strings come from the rendered text in `get_design_context`, never from layer names (which `get_metadata` cuts at 30 characters). Layer names that do not match the rendered text are flagged.
- Prototype links: the generated code renders a node with a prototype interaction as `<a … cursor-pointer>`. Those nodes are reported as **"(prototype link)"**. The target frame is not in the code, so every target is inferred.
- **Annotation:** none of the 13 frames carries a frame annotation (no `data-annotation` in any output). The cluster label is the only stated intent.
- "(inferred)" marks anything the design does not state literally.
- Mock scenario: baby **Teddy**, born **17/9/2026** (Thursday). The "now" is **8/10/2026**, because "17/11 · còn 40 ngày" is exactly 40 days later; this matches the 3-week-old Teddy of `16`. The overdue frames assume about **22/11/2026** ("Quá hạn 5 ngày"). The family is Mẹ (the user, "Bạn") and **Ba Tuấn**.
- Screenshots: `docs/discovery/figma-extract/img/vx/<frame-id>.png`, one per frame plus `401-50608.png` (the preview copy, see below).

**Night care.** No Night variant is drawn for this cluster. All frames are Light.

**Second copy (401:50571 … 401:52226).** These frames live inside a hidden frame **`401:50570` "_preview"** at x −9000, y −9000 (5067 × 812). Each copy is the same node tree as its source frame (same names, same strings and same structure, checked for 401:50571 VX 0 and 401:50608 VX 1 with `get_metadata`, plus a screenshot of 401:50608), laid out in a row 391 px apart and **clipped to 812 px tall** (a phone viewport). They are **not Night care and not different content**: they are cropped copies of the same Light screens, made for a prototype or thumbnail. Because of the crop, the long frames lose everything below 812 px; in VX 1 the copy hides the TabDock, which sits at y 1414. They were not extracted further.

**Coverage.** All 13 frames and the 2 Care tiles were read and no call failed. See "Coverage" at the end.

## Frame list (canvas order, left to right, y 13995.5)
| x | Node | Name | Size |
|---|---|---|---|
| 0 | 400:4019 | VX 0 Thiết lập lần đầu | 375 × 812 |
| 415 | 396:3991 | VX 1 Tiêm chủng | 375 × 1507 |
| 830 | 400:4087 | VX 1a Xem theo | 375 × 812 |
| 1245 | 397:4091 | VX 1b Theo tháng tuổi | 375 × 1507 |
| 1660 | 400:4370 | VX 5 Tích nhanh | 375 × 812 |
| 2075 | 394:4082 | VX 2 Mốc 2 tháng | 375 × 930 |
| 2490 | 394:4166 | VX 3 Ghi mũi tiêm | 375 × 900 |
| 2905 | 396:4302 | VX 4 Đã ghi mũi tiêm | 375 × 1507 |
| 3320 | 401:4160 | VX 6 Chi tiết mũi đã tiêm | 375 × 812 |
| 3735 | 401:4214 | VX 7 Thông tin vắc xin | 375 × 812 |
| 4150 | 401:4291 | VX 8 Nhắc lịch tiêm | 375 × 812 |
| 4565 | 401:4320 | VX 9 Quá hạn | 375 × 1605 |
| 4980 | 401:4610 | VX 9a Xử lý mũi quá hạn | 375 × 812 |

VX 5 sits on the canvas between VX 1b and VX 2 because it follows from VX 1b. The sections below follow the numbering.

## Shared chrome
- StatusBar "9:41" / "•••" (component 11:135, "Placeholder iOS status bar for screen mockups.").
- Top row: a round white `back` button with **Icon/back** (20 px), a spacer, and **BabySwitcher** "Teddy" (avatar, name and chevron; component 45:321: "Baby switcher chip: avatar + name (+ chevron when the family has more than one baby). Shows whose log you are viewing."). VX 0 shows **Icon/close** instead of back; VX 6 shows an **Icon/edit** button instead of the BabySwitcher; VX 8 is a lock screen.
- Page bg `cloud #f6fcfb`, frame radius 40, content pt 52, px 16, gap 12–14, pb 120.
- Info banner "Banner": `surface-2 #eef6f5`, radius 14, **Icon/heart** 16 px and 13 px Medium `ink-muted` text. It is used in VX 1, 1b, 2, 3, 7 and 9a.
- TabDock (VX 1, 1b, 4, 5, 9, 9a): **NavBar v1.0.1** with Tab/Today · Tab/Memories · **Tab/Care active** (white pill, Icon/care and "Chăm sóc") · Tab/Family, plus QuickLogButton "+". TabDock (10:169): "Tab dock = NavBar + QuickLogButton, 24px above the home indicator. Swap the nested NavBar variant (Active) per tab." QuickLogButton (44:363): "Ghi nhanh (+): opens the quick-log chooser (Bú · Ngủ · Tã · Tăng trưởng). 68px, accessibility label “Ghi nhanh”." VX 0, 2, 3, 6 and 7 have **no dock** (pushed screens).
- Icon component description (all line icons): "Line icon (24px, 1.8 stroke) — placeholder drawing; production uses SF Symbols. Recolour by overriding the stroke with a text-colour token." (Icon/clock, drop, cake and camera read "… placeholder; production uses SF Symbols.")
- Button (8:33): "Pill button, label = 1–2-word verb (Lưu, Bắt đầu, Kết thúc, Chỉnh giờ, Mời, Thử lại). Primary h56 mint-deep/on-mint-deep, one per screen in the thumb zone. Secondary h52 surface-2. Tinted for secondary actions. Plain for text buttons (≥44 tap). Apple: use Apple’s official button in production. Press: scale 0.97 in duration-tap. Disabled: opacity 40%. Stretch to fill width for block buttons."
- SheetHeader (37:293): "Bottom-sheet header: grabber, title (24/32 semibold), close (44px, label “Đóng”)." Sheets are white, top radius 28, px 16, pb 34, over a `scrim rgba(12,23,25,0.32)`.
- Toggle (23:262): "iOS switch. On: mint-deep track. Off: separator track. White knob."

### Dose status tokens (VX 1 legend and matrix)
| Status | Copy | Dose circle (34 px matrix / 17 px legend) | Date label under the dot |
|---|---|---|---|
| Done | "Đã tiêm" (vaccinated) | fill `mint-deep #087f7b` with a white Icon/check | date given, e.g. "17/9" (10 px SemiBold `mint-text #06716d`) |
| Due next | "Sắp tới" (upcoming) | fill `sunshine-soft #fff4d6`, 2 px border `sunshine #ffd166`, dose number Bold 14 `ink` | planned date, e.g. "17/11" (`ink`) |
| Overdue | "Quá hạn" (overdue) | fill `error-soft #fbe9ea`, border `error #a12b32` | planned date (VX 9) |
| Not yet due | "Chưa tới" (not yet) | fill `surface-2 #eef6f5`, dose number SemiBold `ink-muted` | age, e.g. "3 th" (= 3 tháng, 3 months) |

"Sắp tới" is used only for the **next milestone's** doses (2 tháng). The later doses are all "Chưa tới".

---

## 400:4019 — VX 0 Thiết lập lần đầu (first-time setup)
**Annotation:** none.

**Text (reading order)**
- Top: close button (Icon/close) · spacer · BabySwitcher "Teddy".
- Icon disc: `peach-soft #ffe3da`, Icon/heart 32 px, round, 18 px padding.
- Title (Bold 26): "Teddy đã tiêm những mũi nào?" (Which shots has Teddy had?)
- Body (Medium 15 `ink-muted`): "Tích các mũi bé đã tiêm từ lúc sinh. Không nhớ ngày cũng không sao — bạn có thể bổ sung sau." (Tick the shots the baby has had since birth. It's fine if you don't remember the date — you can add it later.)
- List (white, radius 18, rows separated by a `separator` hairline), each row with a 22 px square checkbox (radius 7, filled `mint-deep` with a check: **all three are ticked**):
  1. "Vitamin K" / "Sơ sinh · thường tiêm tại bệnh viện" (Newborn · usually given at the hospital)
  2. "Lao (BCG)" (Tuberculosis (BCG)) / "Sơ sinh · thường tiêm tại bệnh viện"
  3. "Viêm gan B · mũi sơ sinh" (Hepatitis B · birth dose) / "Trong 24 giờ đầu" (Within the first 24 hours)
- Dashed card "scan" (white, 1 px dashed `control-border #7e959a`, radius 16): Icon/camera · "Chụp sổ tiêm chủng để lưu lại" (Photograph the vaccination book to keep it), SemiBold 14 `mint-text`.
- 40 px spacer.
- Primary Button (h56, mint-deep) **(prototype link)**: "Lưu 3 mũi đã tiêm" (Save 3 shots given)
- Plain Button (h44, mint-text): "Bỏ qua, làm sau" (Skip, do it later)

**Layout / components:** StatusBar, BabySwitcher, Illustration/BabyFace ("Small baby avatar for headers."), Icon/close, Icon/heart, Icon/check, Icon/camera, Button (primary and plain). The checkbox rows and the scan card are local frames. Text style Text/body-strong (Medium 17/24) on the buttons.

**Visual:** A calm checklist screen with a peach heart badge at the top left, a big question title, a white card with three ticked rows, a dashed "take a photo" card and a full-width green save button.

**Navigation**
- "Lưu 3 mũi đã tiêm" (prototype link) → VX 1 (inferred). The count in the label follows the number of ticked rows (inferred).
- "Bỏ qua, làm sau" → VX 1 with nothing recorded (inferred).
- Close (X) → dismiss to wherever the setup was opened from (inferred: modal presentation).
- "Chụp sổ tiêm chủng để lưu lại" → camera or photo picker (inferred). What is done with the photo (attached to the baby? OCR?) is not drawn.

**Notes / not shown**
- Only the 3 birth doses are listed because Teddy is 3 weeks old. The rule "list every dose due up to the baby's current age" is inferred. An older baby (for example 10 months) would get a long list, and that is not drawn.
- The copy says dates are optional, but VX 1 then shows dates (17/9, 18/9, 17/9) for these doses. Where those dates come from (asked later? defaulted to the DOB?) is not stated.
- When this screen appears is not drawn: the first open of Tiêm chủng (inferred), during onboarding, or from a prompt.
- The checkboxes are drawn pre-ticked. Whether they start ticked or empty is not stated.

---

## 396:3991 — VX 1 Tiêm chủng (schedule by vaccine; long scroll)
**Annotation:** none.

**Text (reading order)**
- Top: back · spacer · BabySwitcher "Teddy".
- Title (Bold 28): "Tiêm chủng" (Vaccinations)
- Card "Next" (**prototype link**; `sunshine-soft`, radius 16): a white round icon chip with Icon/clock · "Mũi tiếp theo · 17/11 · còn 40 ngày" (Next shot · 17/11 · 40 days left; Medium 12 muted) / "6in1 · Rota · Phế cầu (mũi 1)" (6-in-1 · Rota · Pneumococcal (dose 1); Bold 15) · Icon/chevron-right.
- Filters row: pill "f1" (**prototype link**; white, 1 px `separator`, radius 999) "Theo vắc xin" (By vaccine) + Icon/chevron-down · spacer · "Đã tiêm 3 / 30 mũi" (3 / 30 shots given; SemiBold 13 muted).
- Matrix (white, radius 18). Each row has a label column (name SemiBold 14 and schedule hint Medium 11 muted) and a row of dose dots. Status per dot follows the token table above.

| Row (name / hint) | Dots: number · label under it · status |
|---|---|
| "Vitamin K" / "Sơ sinh" | ✓ "17/9" Đã tiêm |
| "Lao (BCG)" / "Sơ sinh" | ✓ "18/9" Đã tiêm |
| "Viêm gan B" / "Sơ sinh" | ✓ "17/9" Đã tiêm |
| "6in1 hoặc 5in1" (6-in-1 or 5-in-1) / "2 · 3 · 4 tháng · nhắc 18th" (2 · 3 · 4 months · booster 18 mo) | 1 "17/11" Sắp tới · 2 "3 th" · 3 "4 th" · 4 "18 th" |
| "Rota" / "2 · 3 · 4 tháng" | 1 "17/11" Sắp tới · 2 "3 th" · 3 "4 th" |
| "Phế cầu" (Pneumococcal) / "2 · 3 · 4 tháng · 11–15th" | 1 "17/11" Sắp tới · 2 "3 th" · 3 "4 th" · 4 "12 th" |
| "Cúm mùa" (Seasonal flu) / "6 · 7 tháng · hằng năm" (6 · 7 months · yearly) | 1 "6 th" · 2 "7 th" |
| "Não mô cầu BC" (Meningococcal B+C) / "6 · 8 tháng" | 1 "6 th" · 2 "8 th" |
| "Não mô cầu ACYW" (Meningococcal ACYW) / "9 · 12 tháng" | 1 "9 th" · 2 "12 th" |
| "Sởi" (Measles) / "9 tháng" | 1 "9 th" |
| "Sởi – Quai bị – Rubella" (MMR) / "12 · 18 tháng" | 1 "12 th" · 2 "18 th" |
| "Viêm não Nhật Bản" (Japanese encephalitis) / "9 tháng · 24 tháng" | 1 "9 th" · 2 "10 th" · 3 "24 th" |
| "Thuỷ đậu" (Chickenpox) / "9 · 15 tháng" | 1 "9 th" · 2 "15 th" |
| "Viêm gan A" (Hepatitis A) / "13 · 18 tháng" | 1 "13 th" · 2 "18 th" |

- The **label of the Rota row** is a **prototype link**.
- Legend: ✓ "Đã tiêm" · ○ "Sắp tới" · ○ "Quá hạn" · ○ "Chưa tới" (17 px dots in the status colours; the empty dots hold a zero-width text node).
- Banner (heart): "Chạm vào một mũi để ghi đã tiêm hoặc xem chi tiết. Lịch tham khảo, có thể thay đổi theo chỉ định của bác sĩ." (Tap a shot to record it as given or see details. Reference schedule; it may change on the doctor's advice.)
- TabDock (Care active).

**Layout / components:** BabySwitcher, Icon/back, clock, chevron-right, chevron-down, check, heart, TabDock / NavBar v1.0.1 / QuickLogButton. The matrix, rows, dots and legend are local frames (named "Matrix", "Row · …", "dose col", "Dose N", "Legend"). Row height is about 71 px, the label column 124 px wide, and dots are 34 px with a 4 px gap.

**Visual:** A long white table: three green ticks for the birth doses; yellow-ringed "1" dots for the three 2-month vaccines; everything later is pale grey numbered dots with "N th" under them. A yellow "next shot" card sits at the top and a heart tip at the bottom above the dark dock.

**Navigation**
- "Next" card (prototype link) → VX 2 Mốc 2 tháng (inferred from content).
- "Theo vắc xin" pill (prototype link) → VX 1a sheet.
- Rota row label (prototype link) → VX 7 Thông tin vắc xin (Rota) (inferred from content).
- Tap a dose dot → record it (VX 3 / VX 5) or see details (VX 6), as the banner states. VX 4 links the recorded 6in1 dot (see VX 4).
- Back → Chăm sóc tab (inferred, via the "Tiêm chủng" tile).

**Notes / not shown**
- **"30 mũi"** is the number of dose dots in the matrix: 3 + 4 + 3 + 4 + 2 + 2 + 2 + 1 + 2 + 3 + 2 + 2 = **30**. It includes **Vitamin K** (not a vaccine), only **2** flu doses although the row says "hằng năm" (yearly), and **one** 6in1/5in1 track; there is no separate polio row for the 5in1 path (see VX 2).
- The hints do not always match the dots: Phế cầu "11–15th" against dot 4 "12 th"; Viêm não Nhật Bản "9 tháng · 24 tháng" against 3 dots at 9 / 10 / 24 th.
- No programme (service or free) and no route (oral or injected) appear on this screen. They appear only on VX 2 and VX 7.
- No empty state (a baby with nothing recorded) and no "not applicable / skipped" dot style are drawn.

---

## 400:4087 — VX 1a Xem theo (view-mode sheet)
**Annotation:** none.

**Background:** VX 1 unchanged (identical node tree and strings), under the scrim.

**Text (sheet)**
- SheetHeader: "Xem lịch tiêm theo" (View the schedule by) · close.
- Group (white, radius 16) with two radio rows (22 px ellipse):
  - ● **selected** "Theo vắc xin" (By vaccine) / "Mỗi loại một dòng, thấy ngay mũi nào còn thiếu" (One line per vaccine; see at once which shots are missing)
  - ○ "Theo tháng tuổi" (By month of age) / "Từng mốc tuổi tiêm gì, tích khi đã tiêm" (What to give at each age milestone; tick when given), a **prototype link**.

**Layout / components:** SheetHeader, Icon/close, local radio rows. The sheet starts at y 567.

**Visual:** A short bottom sheet over the dimmed matrix, with a filled green radio on "Theo vắc xin".

**Navigation:** "Theo tháng tuổi" (prototype link) → VX 1b. Close → VX 1 (inferred).

**Notes:** Whether the chosen view is remembered (per user / per device) is not stated.

---

## 397:4091 — VX 1b Theo tháng tuổi (timeline by month of age; long scroll)
**Annotation:** none.

**Text (reading order)**
- Top: back · BabySwitcher "Teddy". Title "Tiêm chủng".
- **No "Next" card** in this view.
- Filters: pill "Theo tháng tuổi" ▾ · "Đã tiêm 3 / 30 mũi".
- Timeline (white, radius 18). Each age block has a left column 84 px wide (age Bold 14 and calendar date Medium 11 muted) and a list of items, each with a 20 px checkbox (radius 7) and a label. The **current milestone block** (2 tháng) has a `sunshine-soft` background.

| Age · date | Items (checkbox state) |
|---|---|
| "Sơ sinh" · "17/9/2026" | ✓ "Vitamin K" "Đã tiêm" · ✓ "Lao" "Đã tiêm" · ✓ "Viêm gan B" "Đã tiêm" (done rows: label Medium muted, status "Đã tiêm" SemiBold 11 mint-text) |
| "2 tháng" · "17/11/2026" (highlighted) | ☐ "6in1 · 1" · ☐ "Rota · 1" (prototype link) · ☐ "Phế cầu · 1" (boxes white with 2 px `sunshine` border = Sắp tới) |
| "3 tháng" · "17/12/2026" | ☐ "6in1 · 2" · ☐ "Rota · 2" · ☐ "Phế cầu · 2" |
| "4 tháng" · "17/1/2027" | ☐ "6in1 · 3" · ☐ "Rota · 3" · ☐ "Phế cầu · 3" |
| "6 tháng" · "17/3/2027" | ☐ "Cúm · 1" · ☐ "Não mô cầu BC · 1" |
| "7 tháng" · "17/4/2027" | ☐ "Cúm · 2" |
| "8 tháng" · "17/5/2027" | ☐ "Não mô cầu BC · 2" |
| "9 tháng" · "17/6/2027" | ☐ "Não mô cầu ACYW · 1" · ☐ "Sởi" · ☐ "Viêm não NB · 1" · ☐ "Thuỷ đậu · 1" |
| "12 tháng" · "17/9/2027" | ☐ "Não mô cầu ACYW · 2" · ☐ "Sởi–Quai bị–Rubella · 1" · ☐ "Phế cầu · 4" |
| "13 tháng" · "17/10/2027" | ☐ "Viêm gan A · 1" |
| "15 tháng" · "17/12/2027" | ☐ "Thuỷ đậu · 2" |
| "18 tháng" · "17/3/2028" | ☐ "6in1 · 4" · ☐ "Viêm gan A · 2" · ☐ "Sởi–Quai bị–Rubella · 2" |
| "24 tháng" · "17/9/2028" | ☐ "Viêm não NB · 3" |

(Future boxes: white with a 1.5 px `control-border` border. Undone labels are SemiBold 14 ink.)
- Banner: "Tích vào ô khi bé đã tiêm — app sẽ hỏi ngày và nơi tiêm. Lịch tham khảo, có thể thay đổi theo chỉ định của bác sĩ." (Tick the box when the baby has had the shot — the app will ask the date and place. Reference schedule; it may change on the doctor's advice.)
- TabDock (Care active).

**Visual:** A tall card with age milestones down the left and checkboxes on the right. The 2-month block is tinted yellow with yellow-outlined boxes; the newborn block has three green ticks.

**Navigation:** "Rota · 1" (prototype link) → VX 5 Tích nhanh. Ticking any box opens the quick sheet (inferred from the banner). The pill → VX 1a.

**Notes / not shown**
- **Japanese encephalitis dose 2 is missing.** There is no "10 tháng" block, so "Viêm não NB · 2" (10 th in VX 1) is not listed. The timeline has **29** items while the header says "3 / 30".
- Milestone dates are DOB + N calendar months (17/9 → 17/11 …). How the 17th is handled in short months (for example a DOB on the 31st) is not stated.
- Short names differ from VX 1 ("Lao" vs "Lao (BCG)", "Cúm" vs "Cúm mùa", "Viêm não NB" vs "Viêm não Nhật Bản"), and the en dashes in "Sởi–Quai bị–Rubella" are unspaced here.
- The 6in1 / 5in1 choice is not visible here (items say "6in1").

---

## 394:4082 — VX 2 Mốc 2 tháng (2-month milestone)
**Annotation:** none. Pushed screen, no dock; frame 930 tall.

**Text (reading order)**
- Top: back · BabySwitcher "Teddy".
- "Dự kiến 17/11/2026 · còn 40 ngày" (Planned 17/11/2026 · 40 days left; Medium 13 muted)
- Title (Bold 28): "2 tháng tuổi" (2 months old)
- "Chọn một trong hai" (Choose one of the two; SemiBold 13 muted)
- Option card **selected** ("Opt · 6in1 · Dịch vụ": `mint-soft #e6f7f5`, 2 px `mint-deep` border, radius 16, filled radio):
  - "6in1 · Dịch vụ" (6-in-1 · Service/private)
  - "Bạch hầu, ho gà, uốn ván, bại liệt, Hib, viêm gan B — một mũi" (Diphtheria, pertussis, tetanus, polio, Hib, hepatitis B — one shot)
  - Pill (white, 11 SemiBold): "Có phí" (Paid)
- Option card (white, 1 px `separator`, empty radio):
  - "5in1 + Bại liệt · Trạm y tế" (5-in-1 + Polio · Commune health station)
  - "Tiêm chủng mở rộng, uống/tiêm thêm bại liệt" (Expanded Programme on Immunization; polio given additionally by mouth or injection)
  - Pill: "Miễn phí" (Free)
- "Các mũi khác" (Other shots; SemiBold 13 muted)
- Group (white, radius 16):
  - Row: icon chip `care-bottle-soft #e5f1fb` with **Icon/drop** · "Rota · mũi 1" (Rota · dose 1) / "Uống · Dịch vụ" (Oral · Service) · pill button "Ghi" (Record; mint-deep, white 12 SemiBold), a **prototype link**.
  - Row: icon chip `peach-soft` with **Icon/heart** · "Phế cầu · mũi 1" (Pneumococcal · dose 1) / "Tiêm · Dịch vụ" (Injection · Service) · "Ghi".
- Group (white, radius 16):
  - Row: "Nhắc trước 3 ngày" (Remind 3 days before) / "Bạn, Ba Tuấn" (You, Dad Tuấn) · **Toggle ON** (mint-deep track).
  - Row: icon chip `surface-2` with Icon/clock · "Đặt lịch hẹn" (Book an appointment) / "Chưa chọn nơi tiêm" (No vaccination place chosen yet) · Icon/chevron-right.
- Banner (heart): "Hỏi bác sĩ hoặc nhân viên y tế để chọn loại vắc xin phù hợp với bé." (Ask a doctor or health worker to choose the right vaccine for the baby.)

**Layout / components:** BabySwitcher, Icon/back, drop, heart, clock, chevron-right, Toggle (23:262). The option cards, rows and "Ghi" pills are local.

**Visual:** A milestone page: the selected mint option card at the top, a plain alternative below, a list of the other two shots with green "Ghi" pills, then a reminder toggle and an appointment row, and a grey tip banner.

**Navigation**
- "Ghi" on Rota (prototype link) → VX 3 is the likely next frame (inferred), but VX 3's sheet records **6in1 · mũi 1**, not Rota (see VX 3 notes).
- "Đặt lịch hẹn" → an appointment / place picker, **not drawn**.
- "Nhắc trước 3 ngày" toggle → per-milestone reminder (VX 8).
- Recipients "Bạn, Ba Tuấn" → recipient picker, not drawn (inferred: like CS 1d in `16` cluster 9).

**Notes / not shown**
- **The choice affects the schedule.** 6in1 covers polio; the 5in1 path adds polio ("uống/tiêm thêm bại liệt"), but there is no polio row in VX 1 / VX 1b and no polio dose in "30 mũi". Choosing 5in1 should add doses (count and timing not drawn).
- The selected option has no "Ghi" button; how to record the 6in1 dose itself from this screen is not drawn (presumably by tapping the card or the 6in1 dot in VX 1).
- Only Rota and Phế cầu are listed as "Các mũi khác" for 2 months, so both are **service-only** in this design. Whether the choice is made once (for the whole series) or per dose is not stated.
- The appointment ("lịch hẹn") object (date, time, place) is not designed beyond this row.

---

## 394:4166 — VX 3 Ghi mũi tiêm (record a dose: full form)
**Annotation:** none. Frame 900 tall.

**Background:** VX 2 unchanged (same strings, toggle on) under the scrim.

**Text (sheet, top at y 291)**
- SheetHeader: "Ghi mũi tiêm" (Record a shot) · close.
- Header row: icon chip `mint-soft` with Icon/heart · "6in1 · mũi 1" (6-in-1 · dose 1; Bold 16) / "Mốc 2 tháng tuổi" (2-month milestone; Medium 12 muted).
- Two fields side by side:
  - "Ngày tiêm" (Date given) — box (white, 1 px `control-border`, radius 14) with Icon/cake · "17/11/2026"
  - "Giờ" (Time) — box with Icon/clock · "09:30"
- "Nơi tiêm" (Where) — Segmented (`surface-2`, radius 14): "Bệnh viện" (Hospital) · **"Dịch vụ" selected** (white, SemiBold ink) · "Trạm y tế" (Health station).
- "Tên cơ sở (không bắt buộc)" (Facility name (optional)) — placeholder "VD: Trung tâm tiêm chủng gần nhà" (e.g. The vaccination centre near home).
- "Phản ứng sau tiêm (không bắt buộc)" (Reaction after the shot (optional)) — placeholder "Sốt nhẹ, quấy hơn…" (Mild fever, fussier…).
- Dashed chip (1 px dashed `control-border`, radius 14): Icon/camera · "Chụp sổ tiêm / phiếu tiêm" (Photograph the vaccination book / slip).
- Primary Button (**prototype link**): "Lưu mũi tiêm" (Save the shot).

**Layout / components:** SheetHeader, Icon/close, heart, cake (used for date), clock, camera, Button. Fields and the segmented control are local frames (not the design-system field component).

**Visual:** A tall white sheet covering most of the milestone screen: date and time boxes, a 3-way segmented "Nơi tiêm", two optional text fields, a dashed photo button and the green save button.

**Navigation:** "Lưu mũi tiêm" (prototype link) → VX 4 (the toast confirms "6in1 mũi 1"). Close → VX 2.

**Notes / not shown**
- **Date not in the past.** In the mock, "today" is 8/10 and the date field holds 17/11/2026, the planned date. Either the field defaults to the planned date, or this screen is set on the day itself. Whether future dates are allowed is not stated (inferred: they must not be, since a future dose is not "given").
- "Nơi tiêm" mixes venue and programme: "Dịch vụ" (private service) and "Trạm y tế" (usually the free programme) are payment or programme types, while "Bệnh viện" is a venue. There is no explicit "programme" field. The 6in1/5in1 choice of VX 2 is the only place the programme appears.
- Not drawn: batch or lot number, the product / brand name, injection site, which doctor, and multiple photos.
- The reaction is free text; there are no structured reaction choices and no "see a doctor" guidance (R-012 calm UX / no medical inference applies, inferred).

---

## 396:4302 — VX 4 Đã ghi mũi tiêm (dose saved)
**Annotation:** none. Frame 1507 tall (VX 1 layout).

**Differences from VX 1 (everything else identical)**
- "Next" card second line: "Rota · Phế cầu (mũi 1)" (6in1 removed).
- Counter: "Đã tiêm 4 / 30 mũi".
- 6in1 row, dot 1: now **Done** (mint-deep with a check); the label under it is still "17/11". The dot is a **prototype link**.
- **Toast** (ink `#173d44` pill, white text, centred at the bottom above the dock, y 1354): Icon/check · "Đã lưu 6in1 mũi 1 · mũi 2 dự kiến 17/12" (Saved 6-in-1 dose 1 · dose 2 planned 17/12).

**Visual:** Same matrix with the first 6in1 dot turned green, and a dark confirmation toast over the bottom of the list.

**Navigation:** The recorded 6in1 dot 1 (prototype link) → VX 6 Chi tiết mũi đã tiêm (inferred from content).

**Notes / not shown**
- The "Next" card still says "· 17/11 · còn 40 ngày" because Rota and Phế cầu are still due that day.
- **Next-dose date rule.** "mũi 2 dự kiến 17/12" equals both the age milestone (3 tháng = 17/12) and the given date + 4 weeks (≈ 15/12) rounded to the milestone. Whether the next due date moves when a dose is given late is not stated (see "Rule model summary").

---

## 400:4370 — VX 5 Tích nhanh (quick tick)
**Annotation:** none. Frame 812.

**Background:** VX 1b, with **"Rota · 1" ticked** (mint-deep box with a check) while 6in1 · 1 and Phế cầu · 1 stay yellow-outlined. The counter still says "Đã tiêm 3 / 30 mũi" (not saved yet).

**Text (sheet)**
- Small grabber only (no SheetHeader / close).
- Header: icon chip `mint-soft` with Icon/check · "Đã tiêm Rota · mũi 1" (Rota dose 1 given; Bold) / "Mốc 2 tháng tuổi".
- "Tiêm ngày nào?" (Which day?) — chips: **"Hôm nay"** (Today; selected, mint-deep / white) · "Hôm qua" (Yesterday; surface-2) · Icon/cake "Chọn ngày" (Pick a date; surface-2).
- "Tiêm ở đâu?" (Where?) — Segmented "Bệnh viện" · **"Dịch vụ"** (selected) · "Trạm y tế".
- Primary Button: "Lưu" (Save)
- Plain Button (mint-text): "Thêm chi tiết (phản ứng, ảnh sổ tiêm)" (Add details (reaction, photo of the book))

**Layout / components:** Button (primary and plain), Icon/check, Icon/cake. Chips and the segmented control are local.

**Visual:** A short sheet over the month-of-age list, with the ticked Rota row visible behind the scrim; the green "Hôm nay" chip and a big green "Lưu".

**Navigation (inferred):** "Lưu" → back to VX 1b with Rota · 1 recorded (a toast as in VX 4). "Thêm chi tiết…" → VX 3 full form, prefilled. Swipe down → cancel and untick.

**Notes / not shown**
- There is no time field (the full form has "Giờ"). The quick save presumably stores the date only.
- "Hôm nay" is pre-selected while the dose was planned for 17/11 (40 days ahead in the mock). Ticking a future dose as given today is allowed by this design. Whether the app should warn when the date is far before the planned age (minimum age or interval) is not stated.
- The "Chọn ngày" date picker is not drawn.

---

## 401:4160 — VX 6 Chi tiết mũi đã tiêm (given-dose detail)
**Annotation:** none. Pushed screen, no dock.

**Text (reading order)**
- Top: back · spacer · white round button with **Icon/edit** (18 px).
- Chips: "Đã tiêm" (`mint-soft`, Icon/check, mint-text) · "Mốc 2 tháng" (2-month milestone; `surface-2`, ink).
- Title (Bold 28): "6in1 · mũi 1"
- Key-value group (white, radius 16; key column 110 px Medium muted, value SemiBold ink):
  - "Ngày tiêm" — "Thứ Ba, 17/11/2026 · 09:30" (Tuesday, 17/11/2026 · 09:30; correct weekday)
  - "Nơi tiêm" — "Dịch vụ · Trung tâm tiêm chủng gần nhà" (Service · The vaccination centre near home)
  - "Người ghi" (Recorded by) — "Mẹ" (Mum)
  - "Phản ứng" (Reaction) — "Sốt nhẹ buổi tối, hết sau 1 ngày" (Mild fever in the evening, gone after 1 day)
- "Ảnh sổ tiêm" (Photo of the book) — one 100 × 120 thumbnail (`Illustration/Photo`, radius 14).
- Card "next" (`sunshine-soft`, radius 16): Icon/clock · "Mũi 2 dự kiến 17/12 · đã bật nhắc" (Dose 2 planned 17/12 · reminder on).
- Plain Button (mint-text): "Xoá mũi tiêm này" (Delete this shot)

**Layout / components:** Icon/back, check, clock, edit; **Illustration/Photo** (131:758): "Illustrated baby photo placeholder (privacy-safe). Use instead of real photos in mockups."; Button (plain).

**Visual:** A detail page with two chips, a big title, a white facts table, a single photo thumbnail, a yellow "next dose" strip and a text-only delete button.

**Navigation (inferred):** Edit → VX 3 prefilled. Photo → full-screen viewer. "Xoá mũi tiêm này" → confirmation, then the dot returns to Sắp tới / Quá hạn. Back → VX 1 / VX 4.

**Notes / not shown**
- Attribution uses the relation label "Mẹ" (consistent with D-024). An edit history and "who edited" are not shown.
- The delete button is plain mint text, not destructive red. The confirmation is not drawn.
- The photo is "Ảnh sổ tiêm", so it is sensitive health data (see "Open questions": storage, sharing and whether it can appear in Memories).
- Who may edit or delete (Cùng nuôi only? the caregiver who recorded it?) is not shown.

---

## 401:4214 — VX 7 Thông tin vắc xin (vaccine info: Rota)
**Annotation:** none. Pushed screen, no dock.

**Text (reading order)**
- Top: back · BabySwitcher "Teddy".
- Title (Bold 28): "Rota"
- Body (Medium 15 muted): "Vắc xin dạng uống, giúp phòng tiêu chảy do virus Rota." (An oral vaccine that helps prevent diarrhoea caused by rotavirus.)
- Key-value group:
  - "Số liều" (Number of doses) — "3 liều" (3 doses)
  - "Thời điểm" (Timing) — "2 · 3 · 4 tháng tuổi" (2 · 3 · 4 months old)
  - "Khoảng cách" (Interval) — "Tối thiểu 4 tuần giữa các liều" (At least 4 weeks between doses)
  - "Nơi tiêm" (Where) — "Dịch vụ" (Service)
- "Các liều của Teddy" (Teddy's doses)
- Group:
  - "Liều 1" (Dose 1) / "Dự kiến 17/11 · còn 40 ngày" — icon chip `sunshine-soft` with Icon/clock · pill "Ghi" (mint-deep).
  - "Liều 2" / "Dự kiến 17/12" — `surface-2` clock · chevron-right.
  - "Liều 3" / "Dự kiến 17/1/2027" — `surface-2` clock · chevron-right.
- Banner (heart): "Thông tin tham khảo, do đội chuyên môn Child Life rà soát. Hỏi bác sĩ nếu bạn còn băn khoăn." (Reference information, reviewed by the Child Life expert team. Ask a doctor if you still have doubts.)

**Visual:** An info page: a big title, a one-line description, a facts table and a list of the baby's three doses, the first with a green "Ghi" pill.

**Navigation (inferred):** "Ghi" → VX 5 or VX 3. A future dose row → its planned-dose detail (not drawn). Back → VX 1.

**Notes / not shown**
- This screen uses "liều" (dose) where every other screen uses "mũi" (shot). That fits an oral vaccine, but it is inconsistent.
- Only Rota's info is drawn. The content for the other 13 rows (description, doses, timing, interval, programme) must be authored. The banner claims it is reviewed by a "đội chuyên môn Child Life", which ties to Q-039 (who reviews health content).
- "Nơi tiêm: Dịch vụ" is a programme fact stated as a place.
- Minimum and maximum age (for example Rota's upper age limit) and contraindications are not drawn (and would be medical guidance; R-012).

---

## 401:4291 — VX 8 Nhắc lịch tiêm (vaccination reminder on the lock screen)
**Annotation:** none.

**Text (reading order)**
- Lock screen (gradient `#2e525c` → `#122129`): "Thứ Hai, 16 tháng 11" (Monday, 16 November; SemiBold 17 white) · "19:00" (Bold 84 white).
- Notification card (white 82 %, radius 22, **prototype link**): Logo/App Icon 20 px · "CHILD LIFE" · "bây giờ" (now) / **"Ngày mai Teddy có lịch tiêm"** (Teddy has a vaccination tomorrow; Bold 15) / "6in1 · Rota · Phế cầu (mũi 1) · Mốc 2 tháng tuổi" (6-in-1 · Rota · Pneumococcal (dose 1) · 2-month milestone).
- Actions (white 82 %, radius 16):
  - "Xem lịch tiêm" (View the schedule) — layer name **"Ghi lần bú"** (stale)
  - "Nhắc lại sáng mai" (Remind me again tomorrow morning) — layer name **"Báo lại sau 15 phút"** (stale)
  - "Dời lịch" (Reschedule; `error` red text) — layer name **"Bỏ qua lần này"** (stale)
- Caption (white 70 %, 12): "Chạm giữ để xem tuỳ chọn" (Touch and hold to see options).

**Layout / components:** StatusBar, Logo/App Icon (35:239): "App icon 1024 full-bleed cho phương án 2 (iOS tự bo góc). Light / Dark / Tinted." (App icon 1024 full-bleed for option 2 (iOS rounds the corners)). The notification and actions are local frames copied from the rule-reminder lock screen (CS 1f in `16` cluster 9), as the stale layer names show.

**Visual:** The iOS lock screen with a big clock, one expanded notification and a three-action menu below it.

**Navigation (inferred):** Tap the notification (prototype link) → VX 2 (the 2-month milestone) or VX 1. "Xem lịch tiêm" → VX 1. "Nhắc lại sáng mai" → snooze until the next morning (time not stated). "Dời lịch" → the reschedule flow of VX 9a, which needs the app open.

**Notes / not shown**
- **Lead-time conflict.** VX 2 says "Nhắc trước 3 ngày" (3 days before), but this notification fires **the evening before at 19:00** ("Ngày mai"). Either there are two reminders (3 days before and the evening before), or the copy differs. Neither the fire time (19:00) nor the 3-day notification is drawn.
- **The copy names the baby** ("Ngày mai Teddy có lịch tiêm"), while rule-reminder pushes are "copy without the baby's name" (R-120 in D-051). This needs an owner decision for vaccination pushes.
- "Dời lịch" in red suggests a destructive or attention action; it is not destructive. Android layout not drawn.
- Who receives it: VX 2 shows recipients "Bạn, Ba Tuấn", so this is a **push to several members**, not the one-device local notification of one-time reminders (R-091).

---

## 401:4320 — VX 9 Quá hạn (overdue)
**Annotation:** none. Frame 1605 tall (VX 1 + the overdue banner).

**Differences from VX 1**
- "Next" card turns `error-soft`: "Quá hạn 5 ngày · dự kiến 17/11" (Overdue by 5 days · planned 17/11) / "6in1 · Rota · Phế cầu (mũi 1)".
- New card "Overdue" below it (white, 1 px `error #a12b32` border, radius 16): **Icon/alert** · "3 mũi đã quá ngày dự kiến. Nếu bé đã tiêm, hãy tích để cập nhật; nếu chưa, đặt lại lịch với cơ sở tiêm." (3 shots are past their planned date. If the baby has had them, tick to update; if not, rebook with the vaccination place.)
- Dot 1 of 6in1, Rota and Phế cầu: **Quá hạn** (error-soft fill, error border). Rota dot 1 is a **prototype link**.
- Counter unchanged: "Đã tiêm 3 / 30 mũi". Legend, banner and dock unchanged.

**Visual:** The matrix with a red-tinted top card, a red-outlined alert card and three red-ringed "1" dots in the 2-month column.

**Navigation:** Rota dot 1 (prototype link) → VX 9a.

**Notes / not shown**
- "5 ngày" is counted from the milestone date (17/11), so "overdue" starts the day after the planned date. There is no grace period. The design does not say whether overdue applies after 1 day or after a window (for example the end of the month of age).
- Overdue in this design is **prominent red** on the screen. For one-time reminders, D-032 limits overdue to "only turn red in the app" (no repeated push). Whether an overdue vaccination sends any push is not drawn.

---

## 401:4610 — VX 9a Xử lý mũi quá hạn (handle an overdue dose)
**Annotation:** none. Frame 812.

**Background:** VX 9 (same strings) under the scrim.

**Text (sheet)**
- SheetHeader: "Rota · mũi 1" · close.
- "Dự kiến 17/11 · đã quá 5 ngày" (Planned 17/11 · 5 days overdue; muted).
- Group (white, radius 16), three rows with chevrons:
  - chip `mint-soft` Icon/check · "Bé đã tiêm rồi" (The baby has had it) / "Ghi ngày và nơi tiêm" (Record the date and place)
  - chip `sunshine-soft` Icon/clock · "Dời lịch" (Reschedule) / "Chọn ngày hẹn mới, app nhắc lại trước 1 ngày" (Pick a new appointment date; the app reminds you 1 day before)
  - chip `surface-2` Icon/close · "Không tiêm mũi này" (Not giving this shot) / "Theo tư vấn của bác sĩ · có thể ghi lý do" (On the doctor's advice · you can note a reason)
- Banner (heart): "Hỏi cơ sở tiêm chủng hoặc bác sĩ để được hướng dẫn lịch tiêm bù phù hợp." (Ask the vaccination place or a doctor for advice on a suitable catch-up schedule.)

**Visual:** A bottom sheet with three choices (green check, yellow clock, grey cross) and a tip.

**Navigation (inferred):** "Bé đã tiêm rồi" → VX 5 / VX 3 (the date defaults to a past date). "Dời lịch" → date picker → a new planned date with a reminder 1 day before (not drawn). "Không tiêm mũi này" → a reason form (not drawn), after which the dose leaves the "due" set.

**Notes / not shown**
- **"Không tiêm mũi này"** creates a **skipped / declined** state that has no dot style in the legend and no copy elsewhere. It is not clear whether it still counts towards "/ 30 mũi".
- "Dời lịch" here says "nhắc lại trước 1 ngày" (1 day before), while VX 2 says 3 days. Two different reminder lead times.
- The sheet is per dose. VX 9 has 3 overdue doses; there is no "handle all 3 at once" option.
- Catch-up scheduling (later doses shifting when one is late) is left to the doctor ("tiêm bù"); the app does not recompute (inferred from the banner).

---

## Vaccine schedule as drawn
Taken from VX 1 (matrix), VX 1b (timeline), VX 0, VX 2 and VX 7. "Programme" and "route" are filled **only where a frame states them**; "—" = not drawn.

| Age milestone (VX 1b date) | Vaccine (VX 1 label) | Dose label (VX 1 / VX 1b) | Programme (as drawn) | Route (as drawn) | Note |
|---|---|---|---|---|---|
| Sơ sinh (17/9/2026) | Vitamin K | dot 1 / "Vitamin K" | — | — | "Sơ sinh · thường tiêm tại bệnh viện" (VX 0). Not a vaccine, but counted in "30 mũi". Done 17/9. |
| Sơ sinh | Lao (BCG) | dot 1 / "Lao" | — | — | "thường tiêm tại bệnh viện". Done 18/9. |
| Sơ sinh | Viêm gan B | dot 1 / "Viêm gan B" ("Viêm gan B · mũi sơ sinh" in VX 0) | — | — | "Trong 24 giờ đầu". Done 17/9. |
| 2 tháng (17/11/2026) | 6in1 hoặc 5in1 | 1 / "6in1 · 1" ("6in1 · mũi 1") | **either** 6in1 · Dịch vụ ("Có phí") **or** 5in1 + Bại liệt · Trạm y tế ("Tiêm chủng mở rộng", "Miễn phí") | tiêm (inferred); the 5in1 path adds polio "uống/tiêm" | 6in1 = "Bạch hầu, ho gà, uốn ván, bại liệt, Hib, viêm gan B — một mũi". Recorded in VX 3/4. |
| 3 tháng (17/12/2026) | 6in1 hoặc 5in1 | 2 / "6in1 · 2" | as above | — | "mũi 2 dự kiến 17/12" (VX 4 toast, VX 6) |
| 4 tháng (17/1/2027) | 6in1 hoặc 5in1 | 3 / "6in1 · 3" | as above | — | |
| 18 tháng (17/3/2028) | 6in1 hoặc 5in1 | 4 / "6in1 · 4" | as above | — | hint "nhắc 18th" (booster) |
| 2 tháng | Rota | 1 / "Rota · 1" ("Rota · mũi 1", "Liều 1") | Dịch vụ | **Uống** (oral) | VX 7: "3 liều", "Tối thiểu 4 tuần giữa các liều" |
| 3 tháng | Rota | 2 / "Rota · 2" | Dịch vụ | Uống | "Dự kiến 17/12" |
| 4 tháng | Rota | 3 / "Rota · 3" | Dịch vụ | Uống | "Dự kiến 17/1/2027" |
| 2 tháng | Phế cầu | 1 / "Phế cầu · 1" ("Phế cầu · mũi 1") | Dịch vụ | **Tiêm** (injection) | |
| 3 tháng | Phế cầu | 2 / "Phế cầu · 2" | Dịch vụ (inferred, same series) | Tiêm | |
| 4 tháng | Phế cầu | 3 / "Phế cầu · 3" | — | — | |
| 12 tháng (17/9/2027) | Phế cầu | 4 / "Phế cầu · 4" | — | — | hint "11–15th"; dot "12 th" |
| 6 tháng (17/3/2027) | Cúm mùa | 1 / "Cúm · 1" | — | — | hint "6 · 7 tháng · hằng năm" |
| 7 tháng (17/4/2027) | Cúm mùa | 2 / "Cúm · 2" | — | — | yearly doses after 7 tháng not drawn or counted |
| 6 tháng | Não mô cầu BC | 1 / "Não mô cầu BC · 1" | — | — | |
| 8 tháng (17/5/2027) | Não mô cầu BC | 2 / "Não mô cầu BC · 2" | — | — | |
| 9 tháng (17/6/2027) | Não mô cầu ACYW | 1 / "Não mô cầu ACYW · 1" | — | — | |
| 12 tháng | Não mô cầu ACYW | 2 / "Não mô cầu ACYW · 2" | — | — | |
| 9 tháng | Sởi | 1 / "Sởi" | — | — | single dose; MMR follows at 12 / 18 tháng |
| 12 tháng | Sởi – Quai bị – Rubella | 1 / "Sởi–Quai bị–Rubella · 1" | — | — | |
| 18 tháng | Sởi – Quai bị – Rubella | 2 / "Sởi–Quai bị–Rubella · 2" | — | — | |
| 9 tháng | Viêm não Nhật Bản | 1 / "Viêm não NB · 1" | — | — | hint "9 tháng · 24 tháng" |
| 10 tháng | Viêm não Nhật Bản | 2 / **missing in VX 1b** | — | — | dot "10 th" in VX 1 only |
| 24 tháng (17/9/2028) | Viêm não Nhật Bản | 3 / "Viêm não NB · 3" | — | — | |
| 9 tháng | Thuỷ đậu | 1 / "Thuỷ đậu · 1" | — | — | |
| 15 tháng (17/12/2027) | Thuỷ đậu | 2 / "Thuỷ đậu · 2" | — | — | |
| 13 tháng (17/10/2027) | Viêm gan A | 1 / "Viêm gan A · 1" | — | — | |
| 18 tháng | Viêm gan A | 2 / "Viêm gan A · 2" | — | — | |
| (2 · 3 · 4 tháng, 5in1 path only) | Bại liệt (polio) | **no row** | Tiêm chủng mở rộng (implied) | "uống/tiêm" | Implied by VX 2 only; not in the matrix, the timeline or "30 mũi". |

**What "30 mũi" counts:** every dot in the VX 1 matrix: 14 rows, **30 dots** (Vitamin K 1, BCG 1, Viêm gan B 1, 6in1/5in1 4, Rota 3, Phế cầu 4, Cúm mùa 2, Não mô cầu BC 2, Não mô cầu ACYW 2, Sởi 1, MMR 2, Viêm não NB 3, Thuỷ đậu 2, Viêm gan A 2). It counts **Vitamin K** and the **oral Rota** doses as "mũi", counts **flu only twice**, treats **6in1/5in1 as one 4-dose series** (no extra polio doses), and stops at **24 months**. It mixes free-programme and service vaccines in one total, so a family on the free programme only would never reach 30/30. The design does not show whether the total changes with the 6in1/5in1 choice or with "Không tiêm mũi này".

Programme coverage: **only 6in1/5in1 (VX 2), Rota and Phế cầu (VX 2, VX 7)** carry a programme or route in the design. The other rows need owner or medical input (see Open questions). This document does not fill them in from outside knowledge.

---

## Rule model summary (as designed)
1. **One book per baby** (BabySwitcher on every screen). Opened from the "Tiêm chủng" tile in Chăm sóc → "Chăm hằng ngày" (subtitle "Mũi tiếp theo 17/11").
2. **Catalogue:** a fixed reference schedule of 14 vaccine rows / 30 doses from birth to 24 months (table above), with age milestones (Sơ sinh, 2, 3, 4, 6, 7, 8, 9, (10), 12, 13, 15, 18, 24 tháng). Each dose's planned date = DOB + its month of age. Banner: "Lịch tham khảo, có thể thay đổi theo chỉ định của bác sĩ."
3. **Dose statuses:** **Đã tiêm** (given, green check + date) · **Sắp tới** (the next milestone's doses, yellow ring) · **Quá hạn** (past the planned date and not given, red ring; "Quá hạn N ngày") · **Chưa tới** (later, grey). From VX 9a, an implied **"Không tiêm"** (declined / skipped on the doctor's advice, with an optional reason) has no visual style. There is no "not applicable" status. There is no state for "given elsewhere, date unknown" (VX 0 allows unknown dates).
4. **Product choice per milestone:** at 2 tháng, "Chọn một trong hai": 6in1 · Dịch vụ (Có phí) vs 5in1 + Bại liệt · Trạm y tế (Miễn phí, Tiêm chủng mở rộng). Other doses show "Uống/Tiêm · Dịch vụ".
5. **Recording a dose:**
   - Full form (VX 3): Ngày tiêm (date) · Giờ (time) · Nơi tiêm (Bệnh viện / Dịch vụ / Trạm y tế) · Tên cơ sở (optional) · Phản ứng sau tiêm (optional free text) · photo "Chụp sổ tiêm / phiếu tiêm" → "Lưu mũi tiêm".
   - Quick tick (VX 5, from the month-of-age view): tick → sheet "Tiêm ngày nào?" (Hôm nay / Hôm qua / Chọn ngày) + "Tiêm ở đâu?" → "Lưu", or "Thêm chi tiết (phản ứng, ảnh sổ tiêm)".
   - First-time setup (VX 0): tick the doses already given since birth (dates optional), "Lưu N mũi đã tiêm" or "Bỏ qua, làm sau", plus an option to photograph the whole book.
   - After saving: toast "Đã lưu {vaccine} mũi {n} · mũi {n+1} dự kiến {date}"; the counter "Đã tiêm N / 30 mũi" goes up; the "Next" card drops that vaccine.
   - Detail (VX 6): Ngày tiêm (weekday, date · time), Nơi tiêm (type · facility), **Người ghi** (who recorded), Phản ứng, Ảnh sổ tiêm, next-dose strip; Edit; "Xoá mũi tiêm này".
6. **Programme** is not a separate field: it comes from the milestone choice (VX 2) and the "Nơi tiêm" segment (Dịch vụ / Trạm y tế).
7. **Reminders:** per milestone, "Nhắc trước 3 ngày" toggle (on by default in the mock) with recipients ("Bạn, Ba Tuấn"). The lock-screen push the evening before at 19:00 reads "Ngày mai Teddy có lịch tiêm" with the vaccine list and milestone, and offers the actions Xem lịch tiêm · Nhắc lại sáng mai · Dời lịch. A reschedule (VX 9a) reminds 1 day before. "Đặt lịch hẹn" (appointment + place) is a separate, undrawn object.
8. **Overdue:** the day after the planned date. The top card turns red ("Quá hạn N ngày · dự kiến …"), an alert card says "N mũi đã quá ngày dự kiến …", and the dots turn red. Tapping an overdue dose → 3 options: **Bé đã tiêm rồi** (record it) · **Dời lịch** (new date, reminder 1 day before) · **Không tiêm mũi này** (doctor's advice, optional reason). Catch-up is left to the doctor ("lịch tiêm bù").
9. **View modes:** "Xem lịch tiêm theo" sheet: **Theo vắc xin** (matrix; one row per vaccine, "thấy ngay mũi nào còn thiếu") or **Theo tháng tuổi** (timeline by age; "tích khi đã tiêm"). The "Next" card appears only in the by-vaccine view.
10. **Vaccine info** (VX 7): description, Số liều, Thời điểm, Khoảng cách, Nơi tiêm, the baby's doses with "Ghi"; content "do đội chuyên môn Child Life rà soát".
11. **Who can edit:** **not shown.** VX 6 records "Người ghi: Mẹ". The tile also appears on the **caregiver's** Care tab (394:4461), so caregivers can at least open it. Relatives are not drawn. Nothing says whether caregivers can record, edit or delete doses, or whether relatives see the book.

---

## Compared with the current app
The Flutter app (`apps/mobile/lib`, working tree 2026-10-11) has **no vaccination feature**: no model, screen, route, Firestore collection or contract. `grep -i "vaccin|tiêm chủng"` over `apps/mobile/lib`, `packages/contracts/src` and `firebase/` finds only reminder copy in the ARB files: `remindersEmptyBody` "Ghi lịch tiêm, tái khám hay việc cần mua để cả nhà cùng thấy." and `reminderWhatHint` "Ví dụ: Tiêm 6 trong 1". Today, families track vaccinations as **free-text one-time reminders**.

### Where the "Tiêm chủng" tile attaches
- Figma: **394:4451 "Tile · Tiêm chủng"** sits in **370:1971 "CS Chăm sóc"** → Content 370:1972 → **Grid 370:1988** ("Chăm hằng ngày") at (177.5, 0), the **second tile, top right, right after "Nhắc nhở"**. **394:4461** is the same tile in **370:2174 "CS Chăm sóc · người chăm"** (the caregiver view) → Grid 370:2191, at the same position.
  - Tile (165.5 × 118, white, radius 20, shadow-card: #173D440F 0/1/2 + #173D4414 0/8/24): icon chip `peach-soft #ffe3da` radius 12 with **Icon/heart** 18 px · "Tiêm chủng" (Bold 15 ink) · "Mũi tiếp theo 17/11" (Next shot 17/11; Medium 12 muted).
  - Grid order now: parent **Nhắc nhở · Tiêm chủng · Thống kê · Lịch sử · Tăng trưởng** (3 rows; the frame grew to 1411 tall). Caregiver **Nhắc nhở · Tiêm chủng · Thống kê · Lịch sử** (2 rows; 1281 tall). Elsewhere on the page "Tiêm chủng" appears only in these two tiles and the label, so Hôm nay has no vaccination card.
- App: `lib/features/care/care_hub_screen.dart`, `_CareHubScreenState.build` → the `daily` list (`_Tile` widgets: Nhắc nhở `ClIcons.clock`/`mintSoft`, Thống kê, Lịch sử, `if (!caregiver)` Tăng trưởng), filtered by the search box (`_matches`) and laid out by `_Grid` in 2 columns. The new tile goes **at index 1** (after Nhắc nhở), **not** inside the `!caregiver` guard (the caregiver frame has it). It uses `ClIcons.heart` (exists) on `cl.colors.peachSoft`, a title and a dynamic subtitle ("Mũi tiếp theo {d/M}"; copy for "all done", "overdue" and "nothing recorded" is not drawn). It needs vi and en ARB keys (D-012) and a new route, for example `Routes.vaccines = '/care/vaccines'` in `lib/app/route_guard.dart` next to `/care/reminders` and `/care/growth`. The class doc comment (370:1971 / 370:2174 tile list) should be updated.
- `docs/discovery/figma-extract/16-v1-improvement.md` cluster 8 describes the grids **without** this tile (4 tiles / 3 tiles). The tile was added to Figma later, so that section is now stale on this point.

### Overlap with reminders (`lib/features/reminders/`)
- **One-time reminders** (`reminder_models.dart`, `reminder_notifications.dart`, `reminder_screens.dart`; R-090…R-094, D-029…D-032): free title, `dueAt`, `leadMinutes` ∈ {0, 10, 30, 60, 120, 1440} (**no 3-day option**), a **local notification on one device** (`notifyDevice`, R-091 "never push to all devices"), no recipients, no lock-screen actions, overdue derived and "only red in the app" (D-032).
- **Rule reminders** (`rule_models.dart`, `rule_notifications.dart`, `rule_screens.dart`; D-051): **server-scheduled push to recipients** (Cùng nuôi / Người chăm sóc), lock-screen actions (Ghi … · Báo lại sau 15 phút · Bỏ qua lần này) handled in `openRulePush`, copy **without the baby's name** (R-120), muted by Thông báo → Nhắc việc.
- **VX 2 / VX 8 need a third kind.** It is per dose or per milestone and generated from the schedule, with **recipients** ("Bạn, Ba Tuấn"), so it is a push like D-051, not R-091's single-device local notification. It needs a **3-day** lead ("Nhắc trước 3 ngày") **and/or** an evening-before notification at 19:00. Its actions are **"Xem lịch tiêm · Nhắc lại sáng mai · Dời lịch"**, and its copy **includes the baby's name**, which conflicts with R-120. The closest reuse is the rule-reminder push pipeline (Functions checking every minute, recipients, iOS action categories in `ios/Runner/RuleNotifications.swift`) with a new reminder type and action set. Building it on one-time reminders would break the multi-recipient promise.
- Open integration points: whether vaccination reminders appear in **Nhắc nhở** (the "Một lần" / "Theo quy tắc" list), in the Care tile count "N nhắc đang bật", and in the Hôm nay "next 3" reminder card (D-051). Also what happens to existing manual "Tiêm 6 trong 1" one-time reminders (duplicates).
- The VX 8 frame copies the CS 1f rule-reminder lock screen (stale layer names "Ghi lần bú", "Báo lại sau 15 phút", "Bỏ qua lần này").

### Other app impact (inferred)
- Data: a per-baby collection (for example `babies/{id}/vaccinations`) for given, declined and rescheduled doses (date, time, place type, facility, reaction, photo, recordedBy), plus the milestone product choice and appointments. Writes need Rules / callable Functions with zod validation (CLAUDE.md). This is **child health data**: no vaccine names, reactions or photos in logs, analytics or crash keys.
- Schedule catalogue: versioned reference data (rows, doses, ages, intervals, programme, route, info copy), probably in `packages/contracts`, with medical review.
- Photos of the book: storage path, size and quota (storage is shared per family, `16` cluster 8), and whether they are excluded from Memories, story links and sharing.
- Week/month-of-age helpers already exist for growth (`who_growth.dart`) and photos by week (`16` cluster 10). DOB + N months for milestone dates must use the same rule.

---

## Open questions (for the owner / business-map)
1. **Schedule source and medical review.** Which schedule is authoritative (Bộ Y tế Tiêm chủng mở rộng + common service vaccines?), who reviews it, and the claim "do đội chuyên môn Child Life rà soát" (VX 7; ties to Q-039 and R-012 "no medical inference"). Supply programme (TCMR / Dịch vụ / both) and route for every row; only 6in1/5in1, Rota and Phế cầu are drawn.
2. **What "30 mũi" counts.** Keep Vitamin K (not a vaccine) and oral Rota in the count? Flu is "hằng năm" but only 2 doses are counted. Does the total change with the 5in1 + polio path (which adds polio doses that have no row) and with "Không tiêm mũi này"? Is the end age 24 months (later boosters not shown)?
3. **Inconsistencies to fix in the design:** JE dose 2 ("10 th") missing from VX 1b (29 vs 30 items); hints vs dots (Phế cầu "11–15th" vs "12 th"; JE "9 tháng · 24 tháng" vs 9/10/24); short names differ between views; "liều" (VX 7) vs "mũi" elsewhere.
4. **6in1 vs 5in1 choice.** Chosen once for the whole series or per dose? Can it be changed after dose 1? What polio rows and doses does the 5in1 path add, and how is the 6in1 dose recorded from VX 2 (no "Ghi" on the selected card)?
5. **Next-dose date rule.** After a dose is given late, is the next dose planned at its age milestone (as drawn) or at given date + minimum interval (VX 7 "Tối thiểu 4 tuần")? Should the app warn when a dose is recorded before the minimum age or interval? (That would be medical inference.)
6. **Reminders.** Lead time: 3 days before (VX 2), the evening before at 19:00 (VX 8), or 1 day before after a reschedule (VX 9a). One reminder or several? Push to the chosen recipients (like D-051) rather than R-091's one device? The baby's name in the copy vs R-120. The snooze time for "Nhắc lại sáng mai". Do vaccination reminders show in Nhắc nhở, in the Care tile count and in Hôm nay's next-3 card? What happens to existing manual one-time "Tiêm …" reminders?
7. **Overdue.** Overdue starts the day after the planned date with no grace window. Is there any overdue push (D-032 keeps one-time reminders silent once overdue)? What is the visual and count treatment of **"Không tiêm mũi này"** (declined), and can it be undone?
8. **Appointments.** "Đặt lịch hẹn · Chưa chọn nơi tiêm" and "Dời lịch" imply an appointment object (date, time, place, maybe a saved facility list). It is not designed.
9. **Permissions.** Who can record, edit and delete doses (Cùng nuôi only? the caregiver who recorded, as D-022 for care records?), and do caregivers (tile present in 394:4461) and relatives see the book? Is "Người ghi" enough, or is an edit history needed?
10. **First-time setup.** When VX 0 appears (first open of the tile? onboarding?), which doses it lists for an older baby, and whether rows start ticked. How doses without a date are stored and shown (VX 1 shows dates for them).
11. **Photos of the book** ("Chụp sổ tiêm chủng", "Ảnh sổ tiêm"): one per dose or for the whole book, storage and quota, privacy (excluded from Memories, story links and exports?), and any OCR (not implied).
12. **Date and time rules.** Is a future "Ngày tiêm" allowed (VX 3 shows the planned date 17/11 while "now" is 8/10; VX 5 defaults to "Hôm nay")? Is the time required? Which time zone (the baby's, as P-014)?
13. **Night care and caregiver variants** are not drawn for any VX frame. **Empty, all-done and offline states** are not drawn.

---

## Coverage
| Node | Read with | Screenshot |
|---|---|---|
| 400:4019 VX 0 | get_design_context | img/vx/400-4019.png |
| 396:3991 VX 1 | get_design_context (saved output, scripted) | img/vx/396-3991.png |
| 400:4087 VX 1a | get_design_context (saved output; background diffed vs VX 1) | img/vx/400-4087.png |
| 397:4091 VX 1b | get_design_context | img/vx/397-4091.png |
| 394:4082 VX 2 | get_design_context | img/vx/394-4082.png |
| 394:4166 VX 3 | get_design_context | img/vx/394-4166.png |
| 396:4302 VX 4 | get_design_context (saved output; diffed vs VX 1) | img/vx/396-4302.png |
| 400:4370 VX 5 | get_design_context (saved output) | img/vx/400-4370.png |
| 401:4160 VX 6 | get_design_context | img/vx/401-4160.png |
| 401:4214 VX 7 | get_design_context | img/vx/401-4214.png |
| 401:4291 VX 8 | get_design_context | img/vx/401-4291.png |
| 401:4320 VX 9 | get_design_context (saved output; diffed vs VX 1) | img/vx/401-4320.png (1605 tall, rendered at 374 × 1600) |
| 401:4610 VX 9a | get_design_context (saved output; diffed vs VX 9) | img/vx/401-4610.png |
| 401:50570 "_preview" copies | get_metadata on 401:50571 and 401:50608; screenshot of 401:50608 | img/vx/401-50608.png |
| 394:4451 / 394:4461 Tile · Tiêm chủng | get_design_context (394:4451); parents via get_metadata of page 345:35701 | — |

Not read / errors: none. No rate-limit error occurred. No frame has an annotation.
