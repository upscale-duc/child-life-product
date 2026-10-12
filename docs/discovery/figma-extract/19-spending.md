# Chi tiêu (spending): spec extracted from final Figma

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only), page **"v1.1"**, cluster **"Chi tiêu"** (frames 8a–8o, one row at canvas y 15770). Read 2026-10-12. No Figma node was modified; only `get_metadata`, `get_design_context` and `get_screenshot` were called.

**What this cluster is.** A per-baby spending log. It is opened from a new **"Chi tiêu" tile** on the Chăm sóc tab (8a). The month screen (8b) shows the month total against a budget, spend by category and the latest items. From there the user adds an expense (8c), opens statistics for 6 months (8d) or since birth (8e), the full history (8f) and an item detail (8g), sets a monthly budget (8h) and recurring items (8i). There is an empty / first-run screen (8j), a cost prompt after a vaccination dose is recorded (8k), a per-member permission screen in Gia đình (8l), and category management: list (8m), add/edit (8n) and delete (8o).

**How it was read**
- For each of the 14 frames other than 8b, I called `get_design_context` (code, component descriptions, any `data-annotation`), `get_metadata` (canvas position, size and layer tree) and `get_screenshot` (saved as PNG). 8b was read with `get_design_context` earlier in the session by the requester (summary supplied); in this pass it got `get_metadata` and `get_screenshot` only. 8c's background is a byte-for-byte copy of 8b's content (same strings and the same token classes), and that copy was used to confirm 8b's typography and tokens.
- Strings come from the rendered text in `get_design_context`, never from layer names (which `get_metadata` cuts at 30 characters). Layer names that disagree with the rendered text are flagged with **Layer name ≠ text**.
- Prototype links: the generated code renders a node that has a prototype interaction as `<a … cursor-pointer>`. Those are marked **(prototype link)**. The target frame is never in the code, so every target is **inferred**.
- **Annotations:** no frame in this cluster has a `data-annotation`. Intent comes only from frame names, copy and component descriptions.
- "(inferred)" marks anything the design does not state literally.
- Screenshots: `docs/discovery/figma-extract/img/v11/<node-id with : → ->.png`, one per frame (15 files).
- The ₫ glyph: every amount is typed as "… ₫" (U+20AB). Be Vietnam Pro draws it as an underlined "đ", which is what the screenshots show.

**Mock scenario.** Baby **Teddy**; "now" is **Monday 12/10/2026** ("Hôm nay, 12/10", "Đến 12/10"). The family is Mẹ (the user; "Ghi bởi Mẹ"), Bố, and Ông bà; the member in 8l is **Bà ngoại**, a **Người chăm** who joined 03/2026. 8e says Teddy is **7 months old** ("Từ khi Teddy chào đời · 7 tháng"), with spending since **03/2026**. This **contradicts the vaccination cluster** (`17-vaccination.md`: Teddy born 17/9/2026, 3 weeks old on 8/10, dose 1 of 6in1 due 17/11), while 8b/8k here show "Mũi 6 trong 1 · lần 2" given on 09/10/2026. The two clusters use different mock ages for the same baby.

**Night care.** No Night variant is drawn for this cluster. All frames are Light (`cloud #f6fcfb` page background).

**Coverage.** All 15 frames were read and screenshotted; no call failed and no rate limit was hit. See "Coverage" at the end.

## Frame list (canvas order, left to right, y 15770, pitch 415)
| x | Node | Name | Size |
|---|---|---|---|
| 0 | 437:3596 | 8a · Chăm sóc · ô Chi tiêu | 375 × 1411 |
| 415 | 437:3183 | 8b · Chi tiêu · tháng này | 375 × 1339 |
| 830 | 437:3759 | 8c · Thêm khoản chi | 375 × 880 |
| 1245 | 438:3382 | 8d · Thống kê · 6 tháng | 375 × 1281 |
| 1660 | 438:3586 | 8e · Thống kê · từ khi sinh | 375 × 1101 |
| 2075 | 438:52517 | 8f · Lịch sử chi tiêu | 375 × 943 |
| 2490 | 438:52658 | 8g · Chi tiết khoản chi | 375 × 812 |
| 2905 | 438:52717 | 8h · Ngân sách tháng | 375 × 965 |
| 3320 | 438:53053 | 8i · Khoản định kỳ | 375 × 812 |
| 3735 | 438:53127 | 8j · Chi tiêu · lần đầu | 375 × 812 |
| 4150 | 438:53200 | 8k · Tiêm chủng · ghi chi phí | 375 × 812 |
| 4565 | 438:53271 | 8l · Gia đình · quyền xem chi tiêu | 375 × 812 |
| 4980 | 439:3641 | 8m · Danh mục chi tiêu | 375 × 916 |
| 5395 | 439:3794 | 8n · Thêm / sửa danh mục | 375 × 812 |
| 5810 | 439:3894 | 8o · Xoá danh mục | 375 × 900 |

The page id of "v1.1" is not listed by `get_metadata` (it lists only Cover `0:1` and Logo `33:2`, as noted in `README.md` / Q-032); the frames were reached by node id. A cluster label node was not looked up.

## Shared chrome
- **StatusBar** "9:41" / "•••" (11:135: "Placeholder iOS status bar for screen mockups.").
- **Top row** (8b–8m, 8o): a round white `back` button (36 px, `surface`, Icon/back 20 px), a spacer and **BabySwitcher** "Teddy" (45:321: "Baby switcher chip: avatar + name (+ chevron when the family has more than one baby). Shows whose log you are viewing."; Illustration/BabyFace 25:323 "Small baby avatar for headers."). 8g has an edit button instead of the BabySwitcher; 8n has a close (X) button and no BabySwitcher.
- **Page:** `cloud #f6fcfb`, frame radius 40, content pt 52, px 16, gap 14–18.
- **Title:** Bold 28 `ink #173d44` (8a: Bold 32; 8j/8k Bold 24/28; 8l Bold 26).
- **Section header:** Bold 17 `ink`, optional right link SemiBold 14 `mint-text #06716d`.
- **Card / group:** `surface` white, radius 16 (lists) / 20 (charts) / 24 (total card), some with `shadow-card` (#173D440F 0/1/2 + #173D4414 0/8/24; the code shows it as drop-shadow 0/8/12 0.08 + 0/1/1 0.06).
- **Category icon chip:** 36 px, radius 12, p 9, category *soft* tint, 18 px line icon. Category progress bar: 8 px, `surface-2 #eef6f5` track, radius 999, category *accent* fill.
- **Transaction row** ("Tx · …"): chip · title SemiBold 15 `ink` · subline Medium 12 `ink-muted #55707a` · amount SemiBold 15 `ink` right-aligned · optional "Có hoá đơn" SemiBold 11 `mint-text` under the amount.
- **Segmented** (8c, 8d, 8e, 8k): `surface-2` track, radius 14, p 4; selected segment white radius 10 SemiBold 14 `ink`; others Medium 14 `ink-muted`.
- **Button** (8:33): "Pill button, label = 1–2-word verb (Lưu, Bắt đầu, Kết thúc, Chỉnh giờ, Mời, Thử lại). Primary h56 mint-deep/on-mint-deep, one per screen in the thumb zone. Secondary h52 surface-2. Tinted for secondary actions. Plain for text buttons (≥44 tap). Apple: use Apple's official button in production. Press: scale 0.97 in duration-tap. Disabled: opacity 40%. Stretch to fill width for block buttons." Several labels here break the "1–2-word verb" rule (e.g. "Thêm khoản chi đầu tiên", "Xuất file chi tiêu (CSV)", "Xoá và chuyển 4 khoản").
- **Bottom bar** (8b, 8h, 8m, 8n): `cloud` strip, pt 12, pb 30, px 16, with one primary Button.
- **SheetHeader** (37:293): "Bottom-sheet header: grabber, title (24/32 semibold), close (44px, label "Đóng")." Sheets (8c, 8k, 8o): white, top radius 28, px 16, pb 34, over `scrim rgba(12,23,25,0.32)`.
- **Toggle** (23:262): "iOS switch. On: mint-deep track. Off: separator track. White knob."
- **Icons:** all line icons carry "Line icon (24px, 1.8 stroke) — placeholder drawing; production uses SF Symbols. Recolour by overriding the stroke with a text-colour token." (some read "… placeholder; production uses SF Symbols."). Icon/grid is drawn as four 2.5-radius squares stroked with a text token.
- **No TabDock** on any frame except 8a (8b–8o are pushed screens).

---

## 437:3596 — 8a · Chăm sóc · ô Chi tiêu (Care tab with the Spending tile)
**Purpose:** the Care tab (parent view) with a sixth "Chăm hằng ngày" tile, **Chi tiêu**, as the entry point.

**Text (reading order)**
- Top: UserAvatar "M" (`card-peach #ffa58d`, Bold 14 `care-bottle-ink`) · BabySwitcher "Teddy" · spacer · round white button "night" with **Icon/today** (sun, 18 px; Night care toggle, inferred).
- Title (Bold 32): "Chăm sóc"
- Search field (white, 1 px `control-border #7e959a`, radius 14, Icon/search): placeholder "Tìm trong Chăm sóc…" (Search in Care…)
- Section "Chăm hằng ngày" (Daily care). Grid of 6 tiles (165.5 × 118, white, radius 20, shadow), each: icon chip (34 px, radius 12) · title Bold 15 · subline Medium 12 muted:
  1. "Nhắc nhở" / "3 nhắc đang bật" (3 reminders on) — `mint-soft`, Icon/clock
  2. "Tiêm chủng" / "Mũi tiếp theo 17/11" (Next shot 17/11) — `peach-soft`, Icon/heart
  3. "Thống kê" / "Bú, ngủ theo ngày" (Feeds, sleep by day) — `care-sleep-soft`, Icon/sliders
  4. "Lịch sử" / "Mọi lần đã ghi" (Everything logged) — `care-diaper-soft`, Icon/journal
  5. "Tăng trưởng" / "Cân nặng, chiều dài" (Weight, length) — `care-growth-soft`, Icon/ruler
  6. **"Chi tiêu" / "4,2 tr tháng này"** (4.2 million this month) — `care-growth-soft #fdede2`, **Icon/grid** stroked `care-growth-ink #9a4a14` — **(prototype link)**
- Section "Sớm ra mắt" (Coming soon). **Layer name ≠ text:** the section frame is "Section · Hiểu con hơn". Grid of 5 disabled tiles (`surface-2` background, icon chip at 50 % opacity, title/subline at 60 %, a "Sớm ra mắt" badge SemiBold 11 on `surface-2`): "Wonder Week" / "Giai đoạn phát triển dự kiến"; "Thẻ theo tuổi" / "Gợi ý theo tuổi của bé"; "Mốc phát triển" / "Ghi lại lần đầu của con"; "Thư viện chăm bé" / "Bài viết được chuyên môn rà soát"; "Ăn dặm" / "Nhật ký & thư viện ăn dặm".
- Section "Cài đặt" (Settings), white group: "Tuỳ chỉnh theo dõi" / "Chọn loại hoạt động cần ghi" (Icon/sliders, chevron); "Thông báo" / **"Nhắc nhở, gia đình"** (Icon/alert, chevron). **Layer name ≠ text:** the subline layer is named "Nhắc nhở, Wonder Week, gia đìn…"; the rendered text has no "Wonder Week".
- TabDock (10:169: "Tab dock = NavBar + QuickLogButton, 24px above the home indicator. Swap the nested NavBar variant (Active) per tab.") with NavBar v1.0.1, **Tab/Care active** (white pill "Chăm sóc"), QuickLogButton (44:363: "Ghi nhanh (+): opens the quick-log chooser (Bú · Ngủ · Tã · Tăng trưởng). 68px, accessibility label "Ghi nhanh".").

**Interactive:** only the **Chi tiêu tile** is a prototype link → 8b (inferred; or 8j when nothing is recorded yet, inferred). Other tiles behave as in the existing Care tab.

**States / notes**
- The tile subline is the current month total in short form ("4,2 tr" = 4.215.000 ₫ from 8b). Copy for an empty month, for a viewer without spending permission, or for a caregiver is not drawn.
- **No caregiver variant** of the Care tab with this tile is drawn. 8l implies a caregiver can be allowed to record expenses, but whether they get the tile is not stated.
- The tile reuses the Tăng trưởng tint (`care-growth-soft`) and the Icon/grid that also means "Khác" (8c/8d) and "Thống kê" (8b pill).

---

## 437:3183 — 8b · Chi tiêu · tháng này (this month)
(Content read earlier with `get_design_context`; confirmed here from `get_metadata`, the screenshot and the identical background of 8c.)

**Purpose:** the monthly home of the feature.

**Text (reading order)**
- Top: back **(prototype link)** · spacer · BabySwitcher "Teddy".
- Title: "Chi tiêu" (Spending)
- Month row: round button "‹" (Icon/back 16 px) · "Tháng 10 · 2026" (SemiBold 16) · round button "›" (Icon/chevron-right) · spacer · "Đến 12/10" (Up to 12/10; Medium 13 muted).
- Total card "Tổng" (white, radius 24, shadow-card, p 18): "Đã chi cho Teddy" (Spent on Teddy; Medium 13 muted) · **"4.215.000 ₫"** (Bold 34) · progress bar (10 px `surface-2` track, `mint-deep #087f7b` fill 159 / 307 px) · "53% ngân sách 8.000.000 ₫" (53 % of the 8,000,000 ₫ budget; Medium 13 muted) · spacer · "Còn 3.785.000 ₫" (3,785,000 ₫ left; SemiBold 13 `mint-text`) · two KPI tiles (`surface-2`, radius 14): "351.000 ₫" / "Trung bình/ngày" (Average/day) and "Thấp hơn 6%" / "So với tháng 9" (6 % lower / Compared with September).
- Quick pills (white, 1 px `separator #dce8e7`, radius 999, 14 px icon `ink`, SemiBold 13), each **(prototype link)**: "Thống kê" (Icon/grid) → 8d · "Ngân sách" (Icon/sliders) → 8h · "Định kỳ" (Icon/retry) → 8i.
- Section "Theo danh mục" (By category) + link "Xem thống kê" (See statistics) **(prototype link)** → 8d.
- Category list (white group, radius 16): see the category table below. Sublines: Giữ trẻ & học "Định kỳ · 1/2 tháng" (Recurring · 1 of 2 this month, inferred); Y tế & tiêm chủng "Gồm 1 mũi tiêm" (Includes 1 vaccine shot).
  | Row | Amount | Bar fill (of 267 px track) |
  |---|---|---|
  | Giữ trẻ & học | 2.000.000 ₫ | 108.1 |
  | Sữa & ăn dặm | 1.120.000 ₫ | 62.1 |
  | Tã & vệ sinh | 540.000 ₫ | 29.9 |
  | Y tế & tiêm chủng | 395.000 ₫ | 20.7 |
  | Quần áo | 160.000 ₫ | 9.2 |
- Section "Gần đây" (Recent) + link "Xem tất cả" (See all) **(prototype link)** → 8f.
- Recent rows:
  1. "Sữa công thức ×2" (Formula ×2) / "Hôm nay · Mẹ trả" (Today · Mum paid) / "1.020.000 ₫"
  2. "Tã dán size M" (Tape diapers size M) / "Hôm qua · Bố trả" (Yesterday · Dad paid) / "285.000 ₫"
  3. "Mũi 6 trong 1 · lần 2" (6-in-1 shot · dose 2) / "09/10 · Từ Tiêm chủng" (From Vaccinations) / "395.000 ₫" / "Có hoá đơn" (Has receipt) — **(prototype link)** → 8g
  4. "Cô giữ trẻ · nửa đầu tháng" (Nanny · first half of month) / "01/10 · Định kỳ" (Recurring) / "2.000.000 ₫"
- Footnote (Medium 12 muted, centred): "Chỉ cha mẹ thấy chi tiêu. Có thể cấp quyền cho người khác trong Gia đình." (Only parents see spending. You can give others access in Family.)
- Bottom bar: primary Button "Thêm khoản chi" (Add expense) **(prototype link)** → 8c.

**Layer name ≠ text:** row 1's frame is "Tx · Sữa công thức 800g ×2"; the rendered title is "Sữa công thức ×2".

**Arithmetic check:** categories sum to 4.215.000 ✓; 4.215.000 / 8.000.000 = 52.7 % → "53%" ✓; 8.000.000 − 4.215.000 = 3.785.000 ✓; 4.215.000 / 12 days = 351.250 → "351.000 ₫" (rounded down to the thousand, or to the nearest thousand). Bars: fill ≈ share of the month total × **230 px** (47.4 % → 108.1, 26.6 % → 62.1, 12.8 % → 29.9, 9.4 % → 20.7, 3.8 % → 9.2); the track is 267 px, so a full bar would never reach the end (a design artefact; the intent is "share of month", inferred). "Thấp hơn 6%" cannot be reproduced from any figure in the cluster (September is 8,3 tr in 8d; see Gaps).

**States not drawn:** empty month (8j covers "never used"), future month, month without budget, over budget, loading/offline, caregiver view.

---

## 437:3759 — 8c · Thêm khoản chi (add expense sheet)
**Purpose:** bottom sheet over 8b for recording an expense. Background = 8b content (only back is a prototype link in this copy); scrim over everything.

**Sheet text (reading order)**
- SheetHeader: "Thêm khoản chi" (Add expense) + close.
- "Số tiền" (Amount; Medium 13 muted, centred) · **"1.020.000 ₫"** (Bold 36, centred).
- Suggestion chips ("Gợi ý", `surface-2`, radius 999, SemiBold 12): "Lần trước 1.020.000" (Last time 1,020,000) · "+100.000" · "+500.000".
- Header row "Cat head": "Danh mục" (Category; SemiBold 13 muted) · spacer · **"Sửa danh mục"** (Edit categories; SemiBold 13 `mint-text`) **(prototype link)** → 8m.
- Category chips (wrap, radius 999, 16 px icon, 13 px text):
  - **Selected:** "Sữa & ăn dặm" — `care-bottle-soft` fill, 1.5 px `care-bottle-accent #3b8fd9` border, Bold `care-bottle-ink #1d5f99`, Icon/feed.
  - Unselected (white, 1 px `separator`, Medium `ink`): "Tã & vệ sinh" (Icon/diaper) · "Y tế & tiêm chủng" (Icon/heart) · "Giữ trẻ & học" (Icon/family) · "Quần áo" (Icon/star) · "Bơi & vận động" (Icon/journal) · "Khác" (Icon/grid in `care-sleep-ink #4447a8`).
  - **"+ Danh mục"** (dashed 1 px `control-border`, Icon/plus, SemiBold `mint-text`) **(prototype link)** → 8n (new category, inferred).
- Field "Nội dung" (Description): box (white, 1 px `control-border`, radius 14) with "Sữa công thức ×2".
- "Ai trả" (Who paid): Segmented **Mẹ** (selected) · Bố · Ông bà · Khác (Mum · Dad · Grandparents · Other).
- White group of rows (34 px `surface-2` icon chips):
  - Icon/today · "Hôm nay, 12/10" (Today, 12/10) · chevron → date picker (inferred, not drawn).
  - Icon/camera · "Ảnh hoá đơn" (Receipt photo) · Icon/plus → camera/photo picker (inferred).
  - Icon/retry · "Lặp lại hằng tháng" (Repeat monthly) · Toggle **off**.
- Primary Button "Lưu khoản chi" (Save expense) — **not** a prototype link.

**Notes**
- The sheet is prefilled (amount, description, category) as if repeating the last formula purchase; the empty state of the form is not drawn. How "Lần trước" is chosen (last expense in the selected category? same description?) is not stated.
- "Lặp lại hằng tháng" only offers monthly; 8i shows twice-monthly, every-2-weeks and yearly schedules.
- The hidden category "Đồ dùng & đồ chơi" (8m) is correctly absent from the chips.
- No time-of-day field; no field for which baby other than the BabySwitcher on the screen behind.
- No validation, error, keyboard or numeric-pad state is drawn.

---

## 438:3382 — 8d · Thống kê · 6 tháng (statistics, 6 months)
**Purpose:** stacked monthly chart and breakdowns for the last 6 months.

**Text (reading order)**
- Top: back **(prototype link)** · BabySwitcher.
- Title: "Thống kê chi tiêu" (Spending statistics)
- Segmented: "Tháng" (Month) · **"6 tháng"** (selected) · "Từ khi sinh" (Since birth) **(prototype link)** → 8e. The "Tháng" segment is not a link.
- KPI tiles (white, radius 16, value SemiBold 18, label Medium 11 muted): "41,8 tr" / "Tổng 6 tháng" (6-month total) · "7,5 tr" / "TB mỗi tháng" (Average per month) · "8,3 tr" / "Cao nhất · T9" (Highest · Sep).
- Card "Theo tháng" (By month) / "T10 đang tính đến 12/10" (Oct counted up to 12/10).
  - Chart 311 × 226: gridlines `separator` at "0 tr", "5 tr", "10 tr" (17 px per million). Stacked bars per month **T5 T6 T7 T8 T9 T10**, 26 px wide; stack order bottom→top Giữ trẻ (`care-growth-accent #e8894a`), Sữa (`care-bottle-accent #3b8fd9`), Tã (`care-diaper-accent #5daa4e`), Y tế (`care/pump/accent #b068c9`), Khác (`care-sleep-accent #6c6fd8`). Non-selected bars at **55 % opacity**; **T9** at 100 % with its label Bold `ink`.
  - Dashed average line labelled "TB 7,5 tr" (SemiBold 10 muted).
  - Tooltip (ink fill, radius 10, white SemiBold 11): "T9 · 8,3 tr".
  - Bar heights → millions: T5 ≈ 6.8 · T6 ≈ 7.2 · T7 ≈ 7.9 · T8 ≈ 7.4 · T9 ≈ 8.3 · T10 ≈ 4.2. (T9 segments: Giữ trẻ 3.38, Sữa 2.08, Tã 0.98, Y tế 1.08, Khác 0.30.)
  - Legend: "Giữ trẻ" · "Sữa" · "Tã" · "Y tế" · "Khác" (10 px rounded squares).
- Section "Theo danh mục" (no link). Rows (bar fill = share × 230 px again):
  | Category | Amount | Subline |
  |---|---|---|
  | Giữ trẻ & học | 18.500.000 ₫ | "44% · cố định mỗi tháng" (fixed every month) |
  | Sữa & ăn dặm | 11.320.000 ₫ | "27% · tăng từ T7 khi bé ăn dặm" (up since July when baby started solids) |
  | Tã & vệ sinh | 5.740.000 ₫ | "14%" |
  | Y tế & tiêm chủng | 3.395.000 ₫ | "8% · 3 lần tiêm chủng" (3 vaccination visits) |
  | Khác | 2.860.000 ₫ | "7% · quần áo, đồ dùng, khác" (clothes, gear, other) |
- Section "Ai trả" (Who paid), card: a 14 px split bar (`mint-deep` 169.05 · `peach #ffa58d` 116.18 · `sunshine #ffd166` 19.77 px, 3 px gaps, radius 6) and rows with 10 px dots: "Mẹ" "23.000.000 ₫ · 55%" · "Bố" "15.880.000 ₫ · 38%" · "Ông bà" "2.920.000 ₫ · 7%".

**Arithmetic check:** categories sum to 41.815.000 → "41,8 tr" ✓ and payers to 41.800.000 ✓. Percentages match the category sums ✓. **"TB mỗi tháng 7,5 tr" = (41.8 − 4.2) / 5**, i.e. the average **excludes the partial current month** (41.8 / 6 would be 7.0). Chart segments for T10 do not match 8b exactly (Giữ trẻ 1.88 vs 2.0; Sữa 1.0 vs 1.12; Y tế 0.28 vs 0.395).

**Notes**
- The 6-month view **folds Quần áo (and anything else) into "Khác"** ("quần áo, đồ dùng, khác"); it shows the top 4 categories plus Khác. The rule for which categories get their own row/colour is not stated.
- The "Tháng" segment has no drawn screen (8b may be it, inferred).
- Tapping a bar to move the tooltip is implied, not drawn.

---

## 438:3586 — 8e · Thống kê · từ khi sinh (statistics since birth)
**Text (reading order)**
- Top: back **(prototype link)** · BabySwitcher.
- Title: "Thống kê chi tiêu"; Segmented: "Tháng" · "6 tháng" **(prototype link)** → 8d · **"Từ khi sinh"** (selected).
- Total card (white, radius 24, shadow): "Từ khi Teddy chào đời · 7 tháng" (Since Teddy was born · 7 months) · **"48.620.000 ₫"** (Bold 32) · "Trung bình 6,9 tr mỗi tháng tuổi · 214 khoản chi" (Average 6.9 m per month of age · 214 expenses).
- Card "Theo tháng tuổi" (By month of age) / "Tháng đầu gồm đồ dùng sơ sinh" (The first month includes newborn gear).
  - Chart 311 × 206, gridlines "0 tr", "5 tr", "10 tr" (15 px per million); single-colour `mint-deep` bars, 24 px, x labels **0 1 2 3 4 5 6**; bar 0 at 100 % with label Bold `ink`, others at 55 %.
  - Tooltip "Tháng đầu · 6,8 tr" (First month · 6.8 m).
  - Heights → millions: 6.8 · 5.9 · 6.2 · 6.8 · 7.2 · 7.9 · 7.8 (sum 48.6 ✓).
- Section "Khoản lớn nhất" (Largest items):
  1. "Xe đẩy & nôi" (Stroller & crib) / "03/2026 · Bố trả" / "6.200.000 ₫" — chip `care-sleep-soft` + Icon/spark. **Layer:** chip named "ic · Đồ dùng & đồ chơi" (the category now hidden in 8m).
  2. "Sữa công thức · thùng 6 hộp" (Formula · case of 6 tins) / "08/2026 · Ông bà trả" / "2.940.000 ₫"
  3. "Cô giữ trẻ · tháng 9" (Nanny · September) / "09/2026 · Định kỳ" / "3.500.000 ₫"
  4. "Mũi phế cầu · lần 1" (Pneumococcal shot · dose 1) / "06/2026 · Mẹ trả" / "1.050.000 ₫"
- Secondary Button (h52, `surface-2`): "Xuất file chi tiêu (CSV)" (Export spending file (CSV)) — not a prototype link.
- Footnote: "Số liệu chỉ để gia đình tự theo dõi, không so sánh với gia đình khác." (Figures are for the family's own tracking, not compared with other families.)

**Notes**
- "Khoản lớn nhất" is **not sorted by amount** (6.2 m, 2.94 m, 3.5 m, 1.05 m).
- "6,9 tr" = 48.62 / 7 = 6.95 → shown as 6,9 (truncation, or the denominator is not 7; unclear).
- Month-of-age buckets (0–6) vs calendar months (T5–T10 in 8d) — the boundary rule (DOB + N months) is not stated.
- "214 khoản chi" vs 8m category counts 12 + 64 + 58 + 9 + 21 + 4 + 6 (hidden) = 174 plus an unshown count for Khác (would be 40).
- "Cô giữ trẻ · tháng 9" is 3.500.000 ₫ here, but 8i schedules 2 × 2.000.000 ₫ a month and 8h budgets 4.000.000 ₫.
- CSV scope (this baby only? all time? which columns?) and where the file goes are not drawn.

---

## 438:52517 — 8f · Lịch sử chi tiêu (history)
**Text (reading order)**
- Top: back **(prototype link)** · BabySwitcher.
- Title: "Tất cả khoản chi" (All expenses)
- Search (white, 1 px `control-border`, radius 14, Icon/search): "Tìm khoản chi…" (Search expenses…)
- Filter chips (horizontally scrolling, clipped at the right edge): **"Tháng 10"** (selected: `ink` fill, white SemiBold 13) · "Tất cả danh mục" (All categories) + Icon/chevron-down · "Ai trả" + chevron-down · "Có hoá đơn" + chevron-down (the last chip starts at x 355 of a 343 px row, so it is cut off).
- Day groups (header SemiBold 14 muted + day total Medium 13 muted, then a white group):
  - "Hôm nay · 12/10" — "1.020.000 ₫": "Sữa công thức ×2" / "Mẹ trả" / "1.020.000 ₫" / "Có hoá đơn"
  - "Hôm qua · 11/10" — "445.000 ₫": "Tã dán size M" / "Bố trả" / "285.000 ₫"; "Bộ body cotton" (Cotton bodysuit) / "Mẹ trả" / "160.000 ₫" (Quần áo, `care-breast-soft`, Icon/star)
  - "09/10" — "395.000 ₫": "Mũi 6 trong 1 · lần 2" / "Mẹ trả · từ Tiêm chủng" / "395.000 ₫" / "Có hoá đơn" — **(prototype link)** → 8g
  - "05/10" — "355.000 ₫": "Khăn ướt ×6" (Wet wipes ×6) / "Mẹ trả" / "255.000 ₫"; "Bột ăn dặm vị bí đỏ" (Pumpkin baby cereal) / "Ông bà trả" / "100.000 ₫"
  - "01/10" — "2.000.000 ₫": "Cô giữ trẻ · nửa đầu tháng" / "Bố trả · định kỳ" / "2.000.000 ₫"

**Arithmetic check:** the 7 items are the whole of October: day totals sum to 4.215.000 ✓ and per category they reproduce 8b exactly (Sữa 1.020.000 + 100.000; Tã 285.000 + 255.000; Quần áo 160.000; Y tế 395.000; Giữ trẻ 2.000.000) ✓.

**Inconsistencies with 8b:** 8b shows "Sữa công thức ×2" **without** "Có hoá đơn" and the vaccine row **without a payer** ("09/10 · Từ Tiêm chủng"), and the nanny row **without a payer** ("01/10 · Định kỳ"); 8f shows "Có hoá đơn", "Mẹ trả · từ Tiêm chủng" and "Bố trả · định kỳ". The subline format also differs: 8b = "<date> · <payer|source>", 8f = "<payer> [· source]" (the date is in the group header).

**Notes:** day header format: "Hôm nay · 12/10", "Hôm qua · 11/10", then bare "dd/MM". The Tháng chip suggests one month at a time; no infinite scroll / month switch is drawn. Filter sheets, search results and empty-filter states are not drawn. Swipe actions are not drawn.

---

## 438:52658 — 8g · Chi tiết khoản chi (expense detail)
**Text (reading order)**
- Top: back **(prototype link)** · spacer · round white button with **Icon/edit** (→ edit form, inferred; the form is not drawn — presumably 8c prefilled). **Layer name ≠ content:** the edit button frame is named "more".
- Head (centred): chip 44 px `care/pump/soft #f5eafa` with Icon/heart 28 px · **"395.000 ₫"** (Bold 34) · "Mũi 6 trong 1 · lần 2" (SemiBold 16).
- White group of label/value rows (label SemiBold 15 `ink`, value Medium 12 muted):
  - "Danh mục" / "Y tế & tiêm chủng"
  - "Ngày" (Date) / "09/10/2026"
  - "Ai trả" / "Mẹ"
  - "Ghi bởi" (Recorded by) / "Mẹ · 09/10, 10:24"
  - "Liên kết" (Link) / "Lịch tiêm chủng · Mũi 6 trong 1 lần 2" (Vaccination schedule · 6-in-1 dose 2) — with a `care/pump/soft` Icon/heart chip and chevron → the vaccination dose detail (VX 6 in `17`, inferred). **Not** a prototype link.
- "Hoá đơn" (Receipt; Bold 15) · card "Receipt" (white, radius 16, shadow): a `surface-2` "paper" with five grey bars (a placeholder receipt image) · "Chạm để xem ảnh lớn" (Tap to see the large image).
- Secondary Button (h52, `surface-2`): "Xoá khoản chi" (Delete expense). Not destructive-styled and no confirmation is drawn (compare 8o, where delete is `error` red).

**Notes:** confirms that **"Có hoá đơn" = a receipt photo is attached**. The rows are not tappable (no chevrons) except Liên kết. Frame content is 933 tall in an 812 frame; the button sits at the bottom edge.

---

## 438:52717 — 8h · Ngân sách tháng (monthly budget)
**Text (reading order)**
- Top: back **(prototype link)** · BabySwitcher.
- Title: "Ngân sách tháng" (Monthly budget)
- Intro (Medium 14 muted): "Đặt mức dự kiến để dễ theo dõi. Có thể bỏ trống danh mục." (Set an expected amount to track it easily. Categories can be left empty.)
- Card "Tổng" (white, radius 20, shadow): "Ngân sách mỗi tháng" (Budget per month) · **"8.000.000 ₫"** (Bold 26) · Icon/edit 18 px (inline edit, inferred) · bar 8 px (`mint-deep` 159 / 311 px) · "Tháng 10: đã dùng 53%" (October: 53 % used).
- Section "Theo danh mục". Rows "<spent> / <cap>" (SemiBold 14, **no ₫**), bar (fill = % × 230 px), subline:
  | Category | Text | Subline |
  |---|---|---|
  | Giữ trẻ & học | "2.000.000 / 4.000.000" | "50% đã dùng" (50 % used) |
  | Sữa & ăn dặm | "1.120.000 / 2.200.000" | "51% đã dùng" |
  | Tã & vệ sinh | "540.000 / 1.000.000" | "54% đã dùng" |
  | Y tế & tiêm chủng | "395.000 / 400.000" | **"Gần chạm mức · còn 5.000 ₫"** (Nearly at the limit · 5,000 ₫ left) in `error #a12b32` |
  | **Quần áo, đồ dùng, khác** (`care-sleep-soft`, Icon/grid) | "Chưa đặt mức" (No limit set) | Icon/plus (→ set a cap, inferred) |
- Group: "Nhắc khi dùng 80% ngân sách" (Remind when 80 % of the budget is used) / "Gửi cho cha mẹ" (Sent to parents) · Toggle **on**.
- Bottom bar: primary Button "Lưu ngân sách" (Save budget) — not a prototype link.

**Notes**
- Category caps sum to 7.600.000 ₫, below the 8.000.000 ₫ total; how the two relate (is the total independent? is the remainder "unallocated"?) is not stated.
- The last row merges **Quần áo + Bơi & vận động + Khác** (and "đồ dùng") into one budget line, unlike the 7 categories in 8c/8m. Whether a cap can be set per custom category is not shown.
- "Near limit" fires at 98.75 % here; the threshold for that red copy (vs the 80 % notification) is not stated. Over-budget (> 100 %) state is not drawn.
- The budget is shown with the BabySwitcher, so it is per baby (inferred). Whether it is the same every month or can differ per month is not stated ("mỗi tháng" suggests one standing amount).

---

## 438:53053 — 8i · Khoản định kỳ (recurring items)
**Text (reading order)**
- Top: back **(prototype link)** · BabySwitcher.
- Title: "Khoản định kỳ" (Recurring items)
- Intro: "Tự thêm vào chi tiêu đúng ngày. Bạn nhận nhắc để xác nhận số tiền." (Added to spending automatically on the day. You get a reminder to confirm the amount.)
- White group "Rec · …" (chip · title SemiBold 15 · schedule Medium 12 muted · amount SemiBold 14 with a Toggle under it):
  1. "Cô giữ trẻ" (Nanny) / "Ngày 1 và 16 hằng tháng · Bố trả" (1st and 16th of every month · Dad pays) / "2.000.000 ₫" / Toggle **on** (Giữ trẻ & học)
  2. "Sữa công thức" / "Mỗi 2 tuần · Mẹ trả" (Every 2 weeks · Mum pays) / "1.020.000 ₫" / Toggle **on** (Sữa & ăn dặm)
  3. "Bảo hiểm sức khoẻ của bé" (Baby's health insurance) / "Ngày 5/3 hằng năm" (5 March every year; **no payer**) / "1.800.000 ₫" / Toggle **off** (Y tế & tiêm chủng)
- Secondary Button: "Thêm khoản định kỳ" (Add recurring item) — not a link; its form is **not drawn**.
- Banner (`mint-soft #e6f7f5`, radius 14, Icon/clock, Medium 13 `mint-text`): "Ngày 16/10: Cô giữ trẻ 2.000.000 ₫ sẽ được thêm. Bạn có thể sửa số tiền trước khi lưu." (On 16/10: Nanny 2,000,000 ₫ will be added. You can change the amount before it is saved.)

**Layout bug:** the amount column is only 43 px wide (the Toggle's width), so the amounts wrap onto three lines ("2.000 / .000 / ₫") in the screenshot.

**Notes**
- The intro ("added automatically… reminder to confirm") and the banner ("you can change the amount before it is saved") do not settle whether an occurrence is **saved automatically** or **waits for confirmation**.
- Schedules seen: twice a month on fixed days, every N weeks, yearly on a date. 8c only offers "Lặp lại hằng tháng".
- The rows have no chevron; editing or deleting a recurring item is not drawn. Recipients of the reminder are not stated.
- "Mỗi 2 tuần" formula at 1.020.000 ₫ would add two formula items in October, but 8f has only one (12/10), and that one is not marked "Định kỳ".

---

## 438:53127 — 8j · Chi tiêu · lần đầu (first use / empty state)
**Text (reading order)**
- Top: back (**not** a prototype link here) · BabySwitcher.
- Title: "Chi tiêu"
- Illustration card (`mint-soft`, radius 28): four 40 px chips — `care-bottle-soft` Icon/feed · `care-diaper-soft` Icon/diaper · `care/pump/soft` Icon/heart · `care-growth-soft` Icon/family.
- Heading (Bold 24, centred): "Ghi lại chi tiêu cho Teddy" (Record spending for Teddy)
- Body (Medium 15 muted, centred): "Biết mỗi tháng tốn bao nhiêu cho sữa, tã, tiêm chủng, giữ trẻ. Chỉ cha mẹ thấy, có thể chia sẻ cho người khác." (Know how much each month goes on milk, diapers, vaccinations, childcare. Only parents see it; it can be shared with others.)
- White card of three points (34 px `mint-soft` chips): Icon/plus "Ghi nhanh trong vài giây" (Record in a few seconds) · Icon/grid "Thống kê theo tháng, danh mục, người trả" (Statistics by month, category, payer) · Icon/sliders "Ngân sách và khoản định kỳ" (Budget and recurring items).
- Primary Button "Thêm khoản chi đầu tiên" (Add the first expense) **(prototype link)** → 8c.
- Text link (SemiBold 14 `mint-text`, centred): "Đặt ngân sách sau" (Set the budget later) — not a link.

**Notes:** "Đặt ngân sách sau" reads like a skip for a budget step, but no budget step is on this screen; its target (dismiss? 8h?) is unclear. When this screen appears (no expense ever for this baby, inferred) is not stated.

---

## 438:53200 — 8k · Tiêm chủng · ghi chi phí (vaccination: record the cost)
**Purpose:** after a dose is marked given, a sheet offers to log its cost.

**Background:** back (not a link) · BabySwitcher · title "Mũi 6 trong 1 · lần 2" (Bold 24) · card "Done" (`mint-soft`, radius 20): `mint-deep` round check · "Đã tiêm · 09/10/2026" (Given · 09/10/2026; SemiBold 15 `mint-text`).

**Sheet (top at y 320)**
- SheetHeader: "Ghi chi phí mũi tiêm?" (Record the cost of the shot?) + close.
- Body: "Lưu vào Chi tiêu, danh mục Y tế & tiêm chủng. Có thể bỏ qua." (Saved to Spending, category Medical & vaccinations. You can skip.)
- Field "Số tiền": box "395.000 ₫" (prefilled).
- "Ai trả": Segmented **Mẹ** · Bố · Ông bà · Khác.
- Row Icon/camera "Ảnh hoá đơn" + Icon/plus.
- Primary Button "Lưu vào Chi tiêu" (Save to Spending).
- Text button "Bỏ qua" (Skip; SemiBold 15 `mint-text`).

**Interactive:** no prototype links in this frame.

**Notes:** where "395.000 ₫" comes from (a price list per vaccine? the last price paid? typed by the user?) is not stated. The category is fixed; the date is the dose date (no date field). This sheet does not exist in the vaccination cluster (`17-vaccination.md`, VX 3 / VX 5), so the trigger point (after "Lưu mũi tiêm"? after the quick tick?) is inferred. A free-programme dose ("Trạm y tế · Miễn phí" in VX 2) would presumably not prompt; not stated.

---

## 438:53271 — 8l · Gia đình · quyền xem chi tiêu (family: spending permissions)
**Text (reading order)**
- Top: back (not a link) · BabySwitcher.
- Title (Bold 26): "Bà ngoại" (Maternal grandmother)
- Subline: "Người chăm · tham gia 03/2026" (Caregiver · joined 03/2026)
- Section "Quyền với Teddy" (Permissions for Teddy). White group, each row label + description + Toggle:
  - "Ghi chăm sóc" / "Bú, ngủ, tã, tăng trưởng" (Log care / Feeds, sleep, diapers, growth) — **on**
  - "Xem kỷ niệm" / "Ảnh, video, câu chuyện" (See memories / Photos, videos, stories) — **on**
  - **"Ghi khoản đã chi" / "Chỉ thấy khoản do mình ghi"** (Record expenses / Only sees the items they recorded) — **on**
  - **"Xem toàn bộ chi tiêu" / "Tổng, thống kê, mọi khoản chi"** (See all spending / Totals, statistics, every expense) — **off**
- Banner (`surface-2`, Icon/lock, Medium 13 muted): "Chi tiêu mặc định chỉ cha mẹ thấy. Người chăm được bật "Ghi khoản đã chi" sẽ không thấy tổng hay khoản của người khác." (Spending is visible only to parents by default. A caregiver with "Record expenses" on will not see the totals or other people's items.)

**Interactive:** no prototype links; no save button (toggles apply immediately, inferred).

**Notes**
- This is the first design of **per-member, per-baby toggles**. Today roles are fixed (Cùng nuôi / Người chăm sóc / Người thân; D-017, D-022). "Ghi chăm sóc" and "Xem kỷ niệm" as toggles are a new model for those features too, or are display-only reminders of the role (unclear).
- "Người chăm" (here) vs "Người chăm sóc" (role name elsewhere) — copy differs.
- Whether relatives (Người thân) can get these toggles, and whether "Xem toàn bộ" implies "Ghi", is not stated. The behaviour when both are on is not stated.
- The entry point (Gia đình → member row?) is not drawn in this cluster.

---

## 439:3641 — 8m · Danh mục chi tiêu (categories)
**Text (reading order)**
- Top: back **(prototype link)** · BabySwitcher.
- Title: "Danh mục" (Categories)
- Intro: "Kéo để sắp xếp. Danh mục dùng chung cho mọi bé trong gia đình." (Drag to reorder. Categories are shared by every baby in the family.)
- Section "Đang dùng" (In use). Rows: drag handle (three 14 × 2 bars `control-border`) · chip · name SemiBold 15 · subline Medium 12 muted · chevron-right:
  1. "Giữ trẻ & học" / "12 khoản" (12 items)
  2. "Sữa & ăn dặm" / "64 khoản"
  3. "Tã & vệ sinh" / "58 khoản"
  4. "Y tế & tiêm chủng" / "9 khoản"
  5. "Quần áo" / "21 khoản"
  6. "Bơi & vận động" (Swimming & activities) / "Tự tạo · 4 khoản" (Custom · 4 items) — `sunshine-soft #fff4d6` chip, Icon/journal — **(prototype link)** → 8n (edit)
  7. "Khác" (Other) / "Mặc định · không xoá được" (Default · cannot be deleted) — Icon/lock instead of chevron.
- Section "Đã ẩn" (Hidden). Row at 60 % opacity: "Đồ dùng & đồ chơi" (Gear & toys; `care-sleep-soft`, Icon/spark) / "Ẩn khỏi danh sách chọn · vẫn giữ 6 khoản cũ" (Hidden from the picker · keeps its 6 old items) · text action **"Hiện lại"** (Show again; SemiBold 13 `mint-text`).
- Bottom bar: primary Button "Thêm danh mục" (Add category) **(prototype link)** → 8n (new).

**Notes**
- Built-in categories also have chevrons, so they can presumably be renamed/re-iconed (inferred); only "Khác" is locked.
- Hiding is offered here as a state but the **"hide" action itself** is only drawn as "Ẩn danh mục thay vì xoá" in 8o. Where "Xoá danh mục" is started from (8n has no delete button) is not drawn.
- The BabySwitcher appears although the copy says categories are family-wide; the "N khoản" counts are per baby or per family (unclear).
- The hidden category "Đồ dùng & đồ chơi" has the same tint as "Khác".

---

## 439:3794 — 8n · Thêm / sửa danh mục (add / edit category)
**Text (reading order)**
- Top: round white button with **Icon/close** **(prototype link)** (layer "back") → back to 8m (inferred). No BabySwitcher.
- Title: **"Danh mục mới"** (New category)
- Preview card (white, radius 20): 46 px `sunshine-soft` chip with Icon/journal 22 px · "Bơi & vận động" (Bold 18).
- Field "Tên danh mục" (Category name): box "Bơi & vận động" · helper "Tối đa 24 ký tự" (At most 24 characters).
- "Biểu tượng" (Icon): 16 tiles 44 px (white, 1 px `separator`, radius 12); the selected one 46 px with 2 px `ink` border on `sunshine-soft`: journal (selected) · feed · diaper · heart · family · star · spark · cake · camera · drop · ruler · sleep · bookmark · globe · mail · grid.
- "Màu" (Colour): 8 swatches 32 px; selected = 2.5 px `ink` stroke. Fills (from the swatch SVGs): **#FFF4D6 sunshine-soft (selected)** · #E5F1FB care-bottle-soft · #E7F4E3 care-diaper-soft · #F5EAFA care/pump/soft · #FDEDE2 care-growth-soft · #FCEAF0 care-breast-soft · #EDEEFC care-sleep-soft · #E6F7F5 mint-soft (others stroked `separator #dce8e7`).
- Bottom bar: primary Button "Lưu danh mục" (Save category) — not a link.

**Notes**
- One frame serves both "add" and "edit" (frame name "Thêm / sửa"); it shows the title "Danh mục mới" with a filled name, i.e. the add flow after typing. The edit title, a delete entry point and the empty form are not drawn.
- Only the soft (background) colour is chosen; the accent used for bars/charts for a custom colour (e.g. sunshine has `sunshine #ffd166`) is not stated. Two categories can share a colour (Khác and Đồ dùng & đồ chơi do).
- Duplicate names, the 24-char error and the keyboard state are not drawn.

---

## 439:3894 — 8o · Xoá danh mục (delete category)
**Background:** 8m (identical content; back not a link here). **Sheet** (top y 410):
- SheetHeader title, as rendered in the screenshot: **Xoá "Bơi & vận động"?** (Delete "Swimming & activities"?). (The generated code passes the title with single quotes, `Xoá 'Bơi & vận động'?`; the rendered glyphs are double quotes.)
- Body: "Danh mục này có 4 khoản chi (1.240.000 ₫). Chọn nơi chuyển các khoản này:" (This category has 4 expenses (1,240,000 ₫). Choose where to move them:)
- Radio card **selected** (`mint-soft`, 2 px `mint-deep` border, radius 14): "Chuyển sang "Khác"" (Move to "Other") / "Giữ nguyên số liệu thống kê" (Keeps the statistics intact).
- Radio card (white, 1 px `control-border`): "Chuyển sang danh mục khác" (Move to another category) / "Chọn danh mục" (Choose a category).
- Banner (`surface-2`, Icon/eye): "Muốn giữ số liệu cũ mà không thấy danh mục khi ghi? Hãy chọn Ẩn thay vì Xoá." (Want to keep old figures without seeing the category when recording? Choose Hide instead of Delete.)
- **Destructive** Button (`error #a12b32` fill, `on-mint-deep` white text): "Xoá và chuyển 4 khoản" (Delete and move 4 items).
- Text button: "Ẩn danh mục thay vì xoá" (Hide the category instead of deleting).

**Interactive:** no prototype links.

**Notes:** deleting never deletes expenses — they must be moved. "Giữ nguyên số liệu thống kê" under "Khác" is odd (moving to Khác changes per-category statistics; it keeps totals). The category picker for "Chọn danh mục" is not drawn. What happens to recurring items and budget caps in the deleted category is not stated.

---

## Data model implied (as designed)

### Expense (khoản chi)
| Field | Evidence / examples |
|---|---|
| baby | BabySwitcher on every screen; "Đã chi cho Teddy" |
| amount (VND, integer) | 1.020.000 ₫; 285.000 ₫; 395.000 ₫; 2.000.000 ₫ |
| category | one of the categories below; e.g. Sữa & ăn dặm |
| description ("Nội dung") | "Sữa công thức ×2", "Tã dán size M", "Bộ body cotton", "Khăn ướt ×6", "Bột ăn dặm vị bí đỏ", "Xe đẩy & nôi", "Mũi phế cầu · lần 1" |
| date | "Hôm nay, 12/10"; "09/10/2026"; history grouped by day; stats by month and by month of age |
| paid by ("Ai trả") | Mẹ · Bố · Ông bà · Khác (fixed 4-way choice, not member accounts); may be empty (8b vaccine and nanny rows show none) |
| receipt photo ("Ảnh hoá đơn") | optional; shown as "Có hoá đơn" and in 8g "Hoá đơn · Chạm để xem ảnh lớn"; a filter in 8f |
| recurring origin | "Định kỳ" / "định kỳ" subline; created from a recurring item (8i) or "Lặp lại hằng tháng" (8c) |
| source / link | "Từ Tiêm chủng"; 8g "Liên kết: Lịch tiêm chủng · Mũi 6 trong 1 lần 2" |
| recorded by + recorded at | 8g "Ghi bởi: Mẹ · 09/10, 10:24" (time to the minute) |

### Category (danh mục)
| Field | Evidence |
|---|---|
| name (≤ 24 chars) | 8n "Tối đa 24 ký tự" |
| icon (16 choices) | 8n grid |
| colour (8 soft tints) | 8n swatches |
| order (drag) | 8m "Kéo để sắp xếp" |
| state: in use / hidden | 8m "Đang dùng" / "Đã ẩn"; hidden = not in the picker, keeps old items, "Hiện lại" |
| built-in vs custom | "Tự tạo"; "Khác" = "Mặc định · không xoá được" |
| scope: family-wide | "Danh mục dùng chung cho mọi bé trong gia đình" |
| item count | "12 khoản", "Tự tạo · 4 khoản", "vẫn giữ 6 khoản cũ" |

### Budget (ngân sách)
| Field | Evidence |
|---|---|
| monthly total | 8.000.000 ₫ ("Ngân sách mỗi tháng") — per baby (inferred from BabySwitcher) |
| per-category cap (optional) | 4.000.000 / 2.200.000 / 1.000.000 / 400.000; "Chưa đặt mức" |
| alert at 80 % | toggle, "Gửi cho cha mẹ" |
| derived | % used ("53%", "50% đã dùng"), remaining ("Còn 3.785.000 ₫"), near-limit ("Gần chạm mức · còn 5.000 ₫") |

### Recurring item (khoản định kỳ)
| Field | Evidence |
|---|---|
| title | "Cô giữ trẻ", "Sữa công thức", "Bảo hiểm sức khoẻ của bé" |
| category | via chip tint |
| amount | 2.000.000 / 1.020.000 / 1.800.000 ₫ |
| schedule | "Ngày 1 và 16 hằng tháng"; "Mỗi 2 tuần"; "Ngày 5/3 hằng năm"; 8c "Lặp lại hằng tháng" |
| paid by | Bố / Mẹ / none |
| enabled | toggle (insurance off) |
| next occurrence + confirm | banner "Ngày 16/10: … sẽ được thêm. Bạn có thể sửa số tiền trước khi lưu." |

### Member permission (per baby)
"Ghi khoản đã chi" (record; see only own) and "Xem toàn bộ chi tiêu" (totals, stats, all items), alongside "Ghi chăm sóc" and "Xem kỷ niệm" (8l).

### Derived statistics
Month total; budget %; average per day; comparison with the previous month; per-category totals and shares; 6-month stacked chart (top 4 categories + Khác), 6-month total, average per month (complete months only), highest month; since-birth total, months of age, average per month of age, item count, by-month-of-age chart, largest items; payer split (amount and %).

## Categories seen
| Category | Icon | Soft tint (chip) | Accent (bars/charts) | Where |
|---|---|---|---|---|
| Giữ trẻ & học (Childcare & learning) | Icon/family | `care-growth-soft #fdede2` | `care-growth-accent #e8894a` | all; legend "Giữ trẻ" |
| Sữa & ăn dặm (Milk & solids) | Icon/feed | `care-bottle-soft #e5f1fb` | `care-bottle-accent #3b8fd9` (ink #1d5f99) | all; legend "Sữa" |
| Tã & vệ sinh (Diapers & hygiene) | Icon/diaper | `care-diaper-soft #e7f4e3` | `care-diaper-accent #5daa4e` | all; legend "Tã" |
| Y tế & tiêm chủng (Medical & vaccinations) | Icon/heart | `care/pump/soft #f5eafa` | `care/pump/accent #b068c9` | all; legend "Y tế"; Tiêm chủng link |
| Quần áo (Clothes) | Icon/star | `care-breast-soft #fceaf0` | `care-breast-accent #e07a9a` | 8b, 8c, 8f, 8m; folded into Khác in 8d and 8h |
| Bơi & vận động (Swimming & activities; custom) | Icon/journal | `sunshine-soft #fff4d6` (8m/8n; no tint in the 8c chip) | not shown | 8c, 8m, 8n, 8o |
| Khác (Other; default, locked) | Icon/grid (`care-sleep-ink #4447a8`) | `care-sleep-soft #edeefc` | `care-sleep-accent #6c6fd8` | 8c, 8d, 8h (as "Quần áo, đồ dùng, khác"), 8m |
| Đồ dùng & đồ chơi (Gear & toys; hidden) | Icon/spark | `care-sleep-soft #edeefc` | — | 8m, 8o; 8e "Xe đẩy & nôi" (layer name only) |

Token naming: the pump tokens use the slash form `care/pump/soft`, `care/pump/accent`, while every other care token uses hyphens (`care-bottle-soft`).

## Money and number formatting seen
- Full amounts: dot thousands separator, a space, then "₫" as a suffix: "4.215.000 ₫", "5.000 ₫". No decimals anywhere.
- Without the symbol: suggestion chips "Lần trước 1.020.000", "+100.000", "+500.000"; budget fractions "2.000.000 / 4.000.000".
- Short millions: comma decimal + "tr" (triệu): "4,2 tr tháng này", "41,8 tr", "7,5 tr", "8,3 tr", "6,9 tr", "6,8 tr", axis "0 tr" / "5 tr" / "10 tr", "TB 7,5 tr". One decimal.
- Percentages: integer with "%", no space: "53%", "44%", "Thấp hơn 6%", "55%".
- Rounding seen: 52.7 % → 53 %; 50.9 % → 51 %; 351.250 → 351.000; 4.215 m → 4,2 tr; 6.946 m → 6,9 tr; 41.815 m → 41,8 tr.
- Dates: "Hôm nay", "Hôm qua", "dd/MM" ("09/10"), "dd/MM/yyyy" ("09/10/2026"), "dd/MM, HH:mm" ("09/10, 10:24"), "MM/yyyy" ("03/2026"), "Tháng 10 · 2026", "T5…T10", "Đến 12/10", "Ngày 5/3" (no zero padding), month-of-age "0…6".
- Multiplier in titles: "×2", "×6".

## Roles and permissions stated
- "Chỉ cha mẹ thấy chi tiêu. Có thể cấp quyền cho người khác trong Gia đình." (8b) / "Chỉ cha mẹ thấy, có thể chia sẻ cho người khác." (8j) / "Chi tiêu mặc định chỉ cha mẹ thấy." (8l).
- Per member, per baby (8l): **Ghi khoản đã chi** — "Chỉ thấy khoản do mình ghi"; banner: such a caregiver "sẽ không thấy tổng hay khoản của người khác". **Xem toàn bộ chi tiêu** — "Tổng, thống kê, mọi khoản chi".
- Budget alert recipients: "Gửi cho cha mẹ" (8h).
- "Cha mẹ" is not a role name in the app; the closest is **Cùng nuôi** (D-017). Whether the owner and every Cùng nuôi count as "cha mẹ" is not stated.
- Who can edit or delete an expense, a budget, recurring items or categories is **not stated** (8g shows edit and delete with no role context).
- "Số liệu chỉ để gia đình tự theo dõi, không so sánh với gia đình khác." (8e) — no cross-family benchmarks.

## Links to other features
- **Chăm sóc:** the "Chi tiêu" tile (8a), sixth tile in "Chăm hằng ngày", subline "4,2 tr tháng này".
- **Tiêm chủng:** 8k prompts "Ghi chi phí mũi tiêm?" after "Đã tiêm"; the expense keeps a link ("Từ Tiêm chủng", 8g "Liên kết · Lịch tiêm chủng · Mũi 6 trong 1 lần 2"); the category row says "Gồm 1 mũi tiêm" (8b) and "3 lần tiêm chủng" (8d). Not reflected in `17-vaccination.md`.
- **Gia đình:** member permission screen (8l) with the two spending toggles; 8b's footnote points there.
- **Notifications:** budget 80 % alert to parents (8h); recurring-item reminder to confirm the amount (8i). Neither push is drawn.
- **Export:** "Xuất file chi tiêu (CSV)" (8e).
- **Current app:** `apps/mobile/lib`, `packages/contracts/src` and `firebase/` contain no spending, expense or budget code (grep 2026-10-12). `docs/product/business-map.md` has no D/R/Q item about spending.

## Gaps and questions
1. **"Trung bình/ngày" (351.000 ₫):** total ÷ days elapsed (12) is 351.250; is it rounded down or to the nearest thousand? Elapsed days or days with spending? Does a big one-off (the 2.000.000 nanny item) skew it?
2. **"Thấp hơn 6% · So với tháng 9":** September is 8,3 tr (8d); October-to-date 4,2 tr is 49 % lower and its daily rate (351k vs ~277k) is higher. Same period last month (1–12/9)? Projected month? Not reproducible from the design.
3. **"53% ngân sách":** the bar (159 / 307 px ≈ 52 %) and text are consistent; the over-budget look (> 100 %), and whether the budget is per baby or per family, are not drawn.
4. **"Định kỳ · 1/2 tháng":** read as "1 of 2 occurrences this month" (inferred from 8i "Ngày 1 và 16"). Confirm, and the copy for other schedules.
5. **Category bars** are drawn at share × 230 px on a 267 px track (8b, 8d, 8h); confirm the intended scale (share of month total? share of the largest? % of cap in 8h).
6. **Which categories get their own row/colour** in stats (top 4 + Khác in 8d; "Quần áo, đồ dùng, khác" in 8h) vs the 7 categories in 8b/8c/8m.
7. **Budget total vs category caps:** caps sum to 7,6 m of 8 m; independent or must they add up? Near-limit threshold for the red "Gần chạm mức" copy? A single standing budget or per month? Alert channel and copy for the 80 % alert (push? baby name in copy, R-120?).
8. **Recurring items:** auto-saved on the day, or pending until confirmed ("Bạn nhận nhắc để xác nhận" vs "có thể sửa số tiền trước khi lưu")? Who gets the reminder? Add/edit form not drawn; schedule options (8c offers only monthly). What a paused item does. Recurring items without a payer.
9. **Who can edit/delete** an expense (any parent? the recorder? as D-022 for care records), the budget, recurring items and categories. Does a caregiver with "Ghi khoản đã chi" see the tile on their Care tab, the month screen with only their own items, the budget?
10. **Mapping "cha mẹ"** to roles (owner, Cùng nuôi) and "Người chăm" to Người chăm sóc / Người thân; whether relatives can be granted spending access; whether "Xem toàn bộ" implies "Ghi"; whether "Ghi chăm sóc"/"Xem kỷ niệm" toggles are new per-member permissions or just display the role.
11. **Payer ("Ai trả")** is a fixed list Mẹ/Bố/Ông bà/Khác, not family members: what about two mums, single parents, other caregivers, multiple grandparents? Is it optional (8b shows rows without a payer)? Does it relate to "Ghi bởi"?
12. **"Có hoá đơn"** = a receipt photo (8g). How many photos, storage path and quota (shared family storage), retention, privacy (never in Memories / stories / exports?), and is it included in CSV? Is it child data for logging rules (CLAUDE.md)?
13. **Currency:** only VND (₫, no decimals) is drawn. Other currencies, the en locale format, and max amount are not stated.
14. **Rounding / short format:** "tr" for millions — what about < 1 m ("950 k"?), ≥ 1 billion ("tỷ")? English equivalents (D-012).
15. **Mock-data inconsistencies:** Teddy is 7 months here but 3 weeks old in the vaccination cluster; nanny is 2 × 2.000.000/month (8i) but "tháng 9" is 3.500.000 (8e) and the T9 chart segment ~3,4 tr; 8b vs 8f differ in payer and receipt flags for the same items; "Mỗi 2 tuần" formula vs one October formula item; "Khoản lớn nhất" not sorted; 214 items vs 8m counts.
16. **Vaccination cost (8k):** source of the prefilled 395.000 ₫; whether free-programme doses prompt; the trigger in the VX flow; what happens to the expense when the dose is edited or deleted (and vice versa: deleting the expense keeps the dose?).
17. **Category management:** where "Xoá danh mục" is started from (8n has no delete); hide action entry point; can built-in categories be renamed/re-iconed; are categories family-wide while counts and budgets are per baby; duplicate names; accent colour for custom colours; effect of delete/hide on budgets and recurring items; "Giữ nguyên số liệu thống kê" meaning.
18. **Undrawn states:** empty month, future/previous month navigation, no budget, over budget, loading, offline (writes queued? the app shows pending writes elsewhere), error, permission-denied, search/filter results and empty results, filter sheets, date picker, edit-expense form, delete confirmation for an expense, CSV export progress/result, caregiver variants, **Night care** variants of every frame.
19. **Time zone / day boundary** for "Hôm nay", month buckets and month-of-age buckets (baby's zone, P-014?).
20. **Privacy:** no amounts, descriptions, payers or receipt photos in logs, analytics or crash keys (CLAUDE.md); spending is financial data about the child's household and should be treated at least as sensitively as care payloads.
21. **Button copy** breaks the Button description ("1–2-word verb"): "Thêm khoản chi đầu tiên", "Xuất file chi tiêu (CSV)", "Xoá và chuyển 4 khoản", "Lưu vào Chi tiêu".
22. **8i layout bug:** amounts wrap to three lines in a 43 px column.
23. **Layer-name mismatches:** 8a "Section · Hiểu con hơn" renders "Sớm ra mắt"; 8a "Nhắc nhở, Wonder Week, gia đìn…" renders "Nhắc nhở, gia đình"; 8b/8c "Tx · Sữa công thức 800g ×2" renders "Sữa công thức ×2"; 8g edit button frame "more"; 8n close button frame "back"; 8e chip "ic · Đồ dùng & đồ chơi" on "Xe đẩy & nôi".

## Coverage
| Node | Frame | Read with | Screenshot |
|---|---|---|---|
| 437:3596 | 8a · Chăm sóc · ô Chi tiêu | get_design_context + get_metadata | img/v11/437-3596.png (375 × 1411) |
| 437:3183 | 8b · Chi tiêu · tháng này | get_design_context (earlier, by requester) + get_metadata; tokens confirmed via 8c background | img/v11/437-3183.png (375 × 1339) |
| 437:3759 | 8c · Thêm khoản chi | get_design_context (output was marked truncated after the last element; all sheet content through "Lưu khoản chi" was present) + get_metadata | img/v11/437-3759.png (375 × 880) |
| 438:3382 | 8d · Thống kê · 6 tháng | get_design_context + get_metadata | img/v11/438-3382.png (375 × 1281) |
| 438:3586 | 8e · Thống kê · từ khi sinh | get_design_context + get_metadata | img/v11/438-3586.png (375 × 1101) |
| 438:52517 | 8f · Lịch sử chi tiêu | get_design_context + get_metadata | img/v11/438-52517.png (375 × 943) |
| 438:52658 | 8g · Chi tiết khoản chi | get_design_context + get_metadata | img/v11/438-52658.png (375 × 812) |
| 438:52717 | 8h · Ngân sách tháng | get_design_context + get_metadata | img/v11/438-52717.png (375 × 965) |
| 438:53053 | 8i · Khoản định kỳ | get_design_context + get_metadata | img/v11/438-53053.png (375 × 812) |
| 438:53127 | 8j · Chi tiêu · lần đầu | get_design_context + get_metadata | img/v11/438-53127.png (375 × 812) |
| 438:53200 | 8k · Tiêm chủng · ghi chi phí | get_design_context + get_metadata | img/v11/438-53200.png (375 × 812) |
| 438:53271 | 8l · Gia đình · quyền xem chi tiêu | get_design_context + get_metadata | img/v11/438-53271.png (375 × 812) |
| 439:3641 | 8m · Danh mục chi tiêu | get_design_context + get_metadata | img/v11/439-3641.png (375 × 916) |
| 439:3794 | 8n · Thêm / sửa danh mục | get_design_context + get_metadata; swatch fills read from the 8 returned SVG assets | img/v11/439-3794.png (375 × 812) |
| 439:3894 | 8o · Xoá danh mục | get_design_context + get_metadata | img/v11/439-3894.png (375 × 900) |

Not read / errors: none. No rate-limit error occurred. No frame has an annotation. Not looked up: the page id of "v1.1", any cluster label node, and Night care twins (none found or referenced).
