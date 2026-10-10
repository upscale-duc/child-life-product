# I — Component implementation specs (Figma file sJLG1fAXKDnDr9YI6Yx8ex, read-only)

Source: `get_design_context` (clientFrameworks flutter / dart) per component set on Components page 7:4, plus screen 46:2266 for the page scaffold. Read-only: no Figma writes.

Conventions in this file
- Tokens are referred to by name (see 07-foundations-components-motion.md §1 colour, §4 spacing, §5 radius, §6 shadow, §3 type). Night care values come from the same variable in the "Night care" mode — nothing in the components switches variables per mode, so **every token-bound value below flips automatically**.
- `raw` = value not bound to a variable/style in Figma (a hard-coded number or hex). Where a raw number equals a token value it is noted as "= space-3 (unbound)". Implement with the token unless stated.
- Shadows: Figma's generated CSS shows `drop-shadow(x y blur/2 …)`; the authoritative effect is the named style (shadow-card / shadow-chip / shadow-nav / shadow-sheet / shadow-tile) listed in §6 of file 07. Where only a raw drop-shadow appeared, the matching named style is given.
- Icons are 24×24 line SVG placeholders (1.8 stroke) whose colour is an override of the stroke; the MCP export does not expose the stroke variable, so **icon colour = the text colour token of the same component** unless noted (see §48 for the ones confirmed visually). Production: SF Symbols (iOS) — Android set is an open question.
- Text styles: `display 34/40 600`, `large-title 32/40 600`, `title 30/36 600`, `headline 18/26 500`, `body 16/24 400`, `body-strong 17/24 500`, `label 14/20 500`, `caption 12/16 500 +0.2`, `numeral-xl 52/56 500`, `numeral 28/34 500`.
- Min tap = `tap-min` 44 unless noted. Global interaction rules (from Button / QuickAction descriptions): press = scale 0.97 over duration-tap; disabled = opacity 0.40. No component in Figma has an explicit Pressed / Disabled / Focused variant except where listed.

---

## 1. Button (8:33)

Description: "Pill button, label = 1–2-word verb… Press: scale 0.97 in duration-tap. Disabled: opacity 40%. Stretch to fill width for block buttons."
Common to all styles: Row, `mainAxis center`, `cross center`, gap **space-2 (8)**, radius **radius-pill**, hug width (block buttons stretch to parent width), label **Text/body-strong** (17/24 Medium), one line (`nowrap`). Optional leading icon (`showIcon`, default false) **18×18**, colour = label colour. Default label "Bắt đầu".

| Style (node) | Height | Padding L/R | Fill | Border | Label colour | Icon |
|---|---|---|---|---|---|---|
| Primary (8:5) | **button-height 56** | space-6 (24) | mint-deep | — | on-mint-deep | 18, on-mint-deep |
| Secondary (8:9) | **52 (raw — no token)** | space-6 | surface-2 | — | ink | 18, ink |
| Tinted (8:13) | button-height 56 | space-6 | mint-soft | — | mint-text | 18, mint-text |
| Plain (8:17) | **tap-min 44** | **space-3 (12)** | none (transparent) | — | mint-text | 18, mint-text |
| Outline (8:21) | button-height 56 | space-6 | surface | **1.5 px control-border** (inside) | ink | 18, ink |
| Destructive (8:25) | button-height 56 | space-6 | error-soft | — | error | 18, error |
| Apple (8:29) | button-height 56 | space-6 | apple-button | — | apple-button-ink | 18, apple-button-ink (use official Sign in with Apple button in prod) |

States: no Pressed/Disabled variants — Pressed = scale 0.97 (duration-tap); Disabled = whole button opacity 0.40. No focus style defined (use focus-ring token if needed). No shadow on any style. Vertical padding: none (height fixed, content centred).

## 2. Button/Round (8:34)

| Prop | Value |
|---|---|
| Size | **next-button 64 × 64** |
| Fill | mint-deep |
| Radius | radius-pill (circle) |
| Content | icon `arrow-right` **24×24**, centred; colour on-mint-deep |
| Border / shadow | none |
| A11y | annotation: label **"Tiếp tục"** (button) — required, icon-only |

## 3. Button/Back (8:37)

| Prop | Value |
|---|---|
| Size | **tap-min 44 × 44** |
| Fill | surface-2 |
| Radius | radius-pill |
| Content | icon `back` **24×24**, centred, colour ink |
| A11y | "Quay lại" |

---

## 4. Chip (8:56)

Common: Row, gap **space-1 (4)**, padding L/R **12 (raw, = space-3 unbound)**, T/B **space-1 (4)** → height 28; radius-pill; leading icon **18×18**; label **Text/label** (14/20 Medium), nowrap. No border, no shadow.

| Style (node) | Fill | Label colour | Icon (default) | Sample |
|---|---|---|---|---|
| Neutral (8:40) | surface-2 | ink | lock, ink | "Chỉ ba mẹ" |
| Warm (8:45) | peach-soft | ink | family, ink | "Gia đình" |
| Sun (8:52) | sunshine | on-warm | spark, on-warm | "Lần đầu cười" |

Rule: Warm/Sun only on memory screens.

## 5. Chip/Floating (8:57)

| Prop | Value |
|---|---|
| Layout | Row, gap space-2 (8), cross center |
| Padding | L **7 (raw)**, R **14 (raw)**, T/B **7 (raw)** → 103×44 with default value |
| Fill / radius | chip / radius-pill |
| Shadow | **shadow-chip** |
| Lead | 30×30 circle (raw size), fill mint-soft, radius-pill, clip; icon 18×18 (feed) centred, colour ink/mint-text |
| Value | Text/label 14/20 Medium, ink, **tabular figures**; default "120 ml" |

## 6. SyncStatus (8:84)

Common: Row, gap space-1 (4), padding L/R **space-3 (12)**, T/B **6 (raw)** → height 32; radius-pill; icon 18×18; label Text/label, nowrap. No border/shadow.

| Status (node) | Fill | Text + icon colour | Icon | Copy |
|---|---|---|---|---|
| Synced (8:70) | mint-soft | mint-text | check | "Đã đồng bộ" |
| Pending (8:74) | sunshine-soft | pending | cloud-off | "Chờ đồng bộ · 2" |
| Error (8:79) | error-soft | error | alert | "Chưa lưu được" |

## 7. Banner/Error (8:85)

| Prop | Value |
|---|---|
| Size | width 343 (fill parent), hug height (72 with default copy) |
| Layout | Row, cross **start**, gap space-3 (12) |
| Padding | L/R space-4 (16), T/B space-3 (12) |
| Fill / radius | error-soft / radius-card (24) |
| Icon | alert 24×24, colour error |
| Text | one paragraph, fills width: lead "Chưa lưu được." **Be Vietnam Pro Medium 16/24 in raw #A12B32** (= error Light — **not bound; non-token, and Medium 16 is not a named style** — implement as Text/body with w500, colour `error`), then " Thử lại, nội dung vẫn ở đây." **Text/body**, ink |
| Pair | Tinted "Thử lại" button below (per description) |

## 8. Avatar (8:97)

Common: **40×40 (raw)**, radius-pill, content centred, no border.

| Style (node) | Fill | Content |
|---|---|---|
| Mint (8:90) | mint-soft | initial "M", Text/body-strong 17/24, mint-text |
| Warm (8:92) | peach-soft | initial "T", Text/body-strong, ink |
| Add (8:94) | mint-soft | icon plus 18×18, mint-text |

Use: Mint = parents/caregivers; Warm = baby + view-only relatives; Add = "Mời người thân". Below 44 tap — when tappable wrap in a 44 hit area.

---

## 9. Segmented (9:124) + Segmented/Item (9:111)

Track (Segmented):

| Prop | Options=2 (9:112) | Options=3 (9:117) |
|---|---|---|
| Size | 343 (fill width) × 56 | same |
| Fill | surface-2 | surface-2 |
| Radius | radius-pill | radius-pill |
| Padding | **5 all sides (raw)** | same |
| Gap | **4 (raw; = space-1 unbound)** | same |
| Items | 2 × flex-1 | 3 × flex-1 |
| Defaults | "Sữa mẹ" (sel) · "Sữa công thức" | "Ướt"(sel) · "Bẩn" · "Cả hai" |

Item:

| Prop | Selected=True (9:107) | Selected=False (9:109) |
|---|---|---|
| Height | **46 (raw)** | 46 |
| Padding L/R | space-3 (12) | space-3 |
| Radius | radius-pill | radius-pill |
| Fill | surface | none |
| Shadow | **shadow-card** | none |
| Label | 16/24 **Medium 500** (Text/body metrics with w500 — not a named style), ink, centred, 1 line | **Text/body** 16/24 Regular, ink-muted |

Behaviour: change animates in duration-quick (thumb slides); remembers last choice. Tap target = item 46 h ≥ 44.

## 10. ListRow (9:139)

Common: 343 (fill) × **60 (fixed)**, fill **surface**, Row, cross center, gap **space-3 (12)**, padding L/R **space-4 (16)**, T/B 0. No radius on the row itself — rows are grouped in a surface card with radius-card and 1px separator dividers (per description). Text column flex-1, clip.

| Type (node) | Leading | Title | Subtitle | Trailing |
|---|---|---|---|---|
| Member (9:125) | Avatar Mint 40 | Text/body, ink ("Mẹ Lan") | Text/label, ink-muted ("Chủ sở hữu") | chevron-right **20×20**, colour ink-muted (assumed) |
| Invite (9:133) | Avatar Add 40 (mint-soft + plus 18 mint-text) | Text/body, **mint-text** ("Mời người thân") | — | — |

## 11. SectionHeader (9:140)

| Prop | Value |
|---|---|
| Size | 343 (fill) × 26 |
| Layout | Row, **baseline** aligned, space-between |
| Padding | L/R **4 (raw; = space-1 unbound)**, T/B 0 |
| Title | Text/headline 18/26, ink (default "Lần cuối") |
| Link (showLink, default true) | Text/label 14/20, mint-text ("Lịch sử") — tappable; wrap in ≥44 hit area |
| Spacing rule | space-6 above, space-2 below (description; applied by parent) |

## 12. EmptyState (9:143)

| Prop | Value |
|---|---|
| Size | 375 (fill) × hug (278) |
| Layout | Column, centred |
| Padding | L/R space-6 (24), T/B space-8 (32) |
| Icon circle | **64×64 (raw)**, mint-soft, radius-pill; icon 24×24 (today), mint-text (assumed) |
| Spacer | 16 (raw, = space-4) |
| Title | Text/headline, ink, centre ("Chưa có ghi chép hôm nay") |
| Spacer | 4 (raw, = space-1) |
| Message | Text/body, ink-muted, centre ("Ghi khi gia đình cần nhé.") |
| Spacer | 24 (raw, = space-6) |
| Action | Button **Tinted** with icon (feed 18) "Ghi cữ bú", hug width, h56 |

Note: title/message are `nowrap` in Figma — in Flutter allow wrapping + `TextAlign.center` (long Vietnamese / 200% text).

---

## 13. NavBar (44:362) — 10 variants

Container (all variants): **263 × 68** (inside TabDock it is flex-1 = 375 − 32 − 12 − 68 = 263), fill **nav-bar**, radius **999 (raw, = radius-pill unbound)**, padding **6 all sides (raw)**, Row, cross center, `space-between`, no gap, shadow **shadow-nav**.

Tab slots (each is full inner height **56**, radius 999, clip):

| Tab state | Width | Layout | Fill | Icon | Label |
|---|---|---|---|---|---|
| Active | **flex-1** (= 95 with 4 tabs, 147 with 3 tabs) | Row, centred, gap **6 (raw)**, padding L/R **14 (raw)** | **nav-active** | **22×22**, colour on-nav-active | shown: Be Vietnam Pro **Medium 14 / LH 16 / +0.2 tracking** (raw — not a named style; description calls it "caption"), **on-nav-active**, nowrap |
| Inactive | **52 fixed** | Column, centred, gap 2 (raw) | none | 22×22, colour **nav-icon** | hidden (label layer exists but `hidden`) |

Me tab content = initial-avatar ring instead of an icon: **22×22** circle, radius 999, **border 1.6 px** (raw), initial **11 px** (raw, line-height normal):

| Me state | Ring border | Initial |
|---|---|---|
| Inactive | nav-icon | **SemiBold 11**, nav-icon |
| Active | on-nav-active | **Medium 11**, on-nav-active (+ label "Tôi") |

Note: with 4 tabs the active pill is 95 wide but icon(22)+gap(6)+"Hôm nay"(62) = 90 > 95 − 28 padding; Figma lets content overflow the horizontal padding (content centred, padding effectively ~2.5). Implement the active tab as flex-1 with content centred and padding min(14, available).

Variants (Role × Active → tab order; ● = active):

| Variant (node) | Tabs (left→right) | Active pill width |
|---|---|---|
| Parent / Today (44:308) | ●Hôm nay · Kỷ niệm · Gia đình · Tôi | 95 |
| Parent / Memories (44:326) | Hôm nay · ●Kỷ niệm · Gia đình · Tôi | 95 |
| Parent / Family (44:344) | Hôm nay · Kỷ niệm · ●Gia đình · Tôi | 95 |
| Parent / Me (196:105) | Hôm nay · Kỷ niệm · Gia đình · ●Tôi | 95 |
| Caregiver / Today (124:62) | ●Hôm nay · Gia đình · Tôi (no Kỷ niệm) | 147 |
| Caregiver / Family (124:74) | Hôm nay · ●Gia đình · Tôi | 147 |
| Caregiver / Me (196:123) | Hôm nay · Gia đình · ●Tôi | 147 |
| Relative / Memories (124:86) | ●Kỷ niệm · Gia đình · Tôi (no Hôm nay) | 147 |
| Relative / Family (124:96) | Kỷ niệm · ●Gia đình · Tôi | 147 |
| Relative / Me (196:138) | Kỷ niệm · Gia đình · ●Tôi | 147 |

Icons: today / memories / family. Prop `initial` default "M". Every tab needs an a11y label (Hôm nay / Kỷ niệm / Gia đình / Tôi) even when the visible label is hidden. Inactive tab hit area 52×56 ≥ tap-min.

## 14. TabDock (10:169)

| Prop | Value |
|---|---|
| Size | 375 (screen width) × 68 |
| Layout | Row, cross center, gap **space-3 (12)**, padding L/R **space-4 (16)** |
| Children | NavBar (flex-1 → 263) + QuickLogButton (68×68, shrink 0) |
| Placement | "24px above the home indicator" (description) — see §47 scaffold |
| Background | none (floats over content) |

## 15. QuickLogButton (44:363)

| Prop | Value |
|---|---|
| Size | **68×68 (raw)** |
| Fill / radius | mint-deep / 999 (raw = radius-pill) |
| Shadow | **shadow-nav** (generated CSS 0 12 15 rgba(23,61,68,.25)) |
| Icon | plus **28×28**, colour on-mint-deep |
| A11y | "Ghi nhanh" — opens quick-log chooser (Bú · Ngủ · Tã · Tăng trưởng) |

## 16. NavHeader (11:138)

| Prop | Value |
|---|---|
| Size | 343 (fill) × hug (80) |
| Layout | Row, cross **end** (bottom-aligned), space-between |
| Padding | T **space-2 (8)**, B **space-3 (12)**, L/R 0 |
| Titles column | Column, start-aligned, no gap, clip |
| Subtitle (top) | Text/label 14/20, ink-muted ("Thứ Năm, 8 tháng 10") |
| Title | **Text/large-title** 32/40 SemiBold −0.4, ink ("Hôm nay") |
| Trailing (showTrailing, default true) | swap slot: default Avatar Warm 40 ("T"); alternatives per description: pill (e.g. BabySwitcher / SyncStatus) or Tinted + button |

## 17. SheetHeader (37:293)

| Prop | Value |
|---|---|
| Size | 375 × 69 |
| Layout | Column, centred, gap **12 (raw = space-3 unbound)** |
| Padding | T **8 (raw = space-2)**, L/R **16 (raw = space-4)**, B 0 |
| Grabber | **40×5**, fill separator, radius **3 (raw)** — NB BottomSheet/Feed grabber uses radius 999 |
| Row | fill width, Row, space-between, cross center |
| Title | **SemiBold 24/32** (no named style; non-token), ink ("Ngày sinh") |
| Close | 44×44 hit area, no fill; icon close 24×24, ink; a11y "Đóng" |

## 18. BottomSheet/Feed (11:159) — sheet container

| Prop | Value |
|---|---|
| Width | 375 (full screen width), hug height (381) |
| Fill | **surface** |
| Radius | top-left / top-right **radius-sheet (32)**; bottom 0 |
| Shadow | **shadow-sheet** (0,−8,32, ink 12%); Night: Night care/shadow-sheet |
| Padding | T **space-2 (8)**, L/R **space-4 (16)**, B **space-6 (24)** (+ bottom safe area in app) |
| Grabber wrap | full width, centred, padding-bottom **space-3 (12)** |
| Grabber | **40×5**, separator, radius 999 |
| Header row | space-between, cross center, padding-bottom **space-4 (16)**; title **SemiBold 24/32** ink (non-token style); close 44×44 + icon close 24 ink |
| Body ("Fields") | Column, gap **space-3 (12)**, full width: Segmented → NumField → FieldRow → Primary Button (full width, h56 "Lưu") |
| Presentation | spring ≈ duration-base over **scrim** token; keyboard must never cover Lưu |

Embedded parts (bonus): **NumField 11:153** — surface-2, radius-card, padding L/R space-4 T/B space-3, Row baseline-aligned centred gap space-2; value numeral-xl 52/56 −1 ink (tabular); unit Text/headline ink-muted. **FieldRow 11:156** — h tap-min 44, Row space-between; label Text/body ink; value **16/24 Medium** (non-named) mint-text.

---

## 19. TopBar (23:226) — 6 types

Common: **343 (fill) × 44**, Row, cross center, **space-between**, no padding, no fill.

| Type (node) | Left | Right / middle |
|---|---|---|
| Back (23:191) | Button/Back 44 (surface-2, back 24 ink) | — |
| Skip (23:195) | empty 44×44 spacer | "Bỏ qua" Text/label, **mint-text** (text button — give ≥44 hit area) |
| Back+Skip (23:198) | Button/Back 44 | "Bỏ qua" Text/label, mint-text |
| Back+Progress (23:203) | Button/Back 44 | Progress bar flex-1 (h4, see §32) then a **28×4 trailing spacer (raw)**; NB no gap between Back and bar in Figma — bar starts right after the 44 button |
| Back+Countdown (23:210) | Button/Back 44 | Chip Neutral (surface-2, px 12 py 4, clock 18 ink, Text/label ink "Còn 68 giờ") |
| Brand (23:221) | Logo lockup: Logo/Mark **30×30** + Logo/Wordmark **116.8×23.4**, gap **8.4** (raw) — description says "Logo/Lockup Horizontal, 28px" | Theme toggle **44×44** surface-2 radius-pill, icon **20×20** (sleep/moon), ink |

## 20. TextField (23:243)

Common: 343 (fill) × hug (66), Row, cross center, gap **space-3 (12)**, padding L/R **space-4 (16)**, T/B **space-3 (12)**. Text column flex-1, Column, gap **2 (raw)**, clip.

| Part | Value |
|---|---|
| Label (top) | **Text/caption** 12/16 +0.2, ink-muted (default "Email") |
| Value | **Text/body** 16/24, ink (default "ten@email.com"); placeholder colour not specified (use ink-muted) |
| Eye toggle (showEye, password) | **32×32 (raw)** circle, surface-2, radius-pill; eye icon 18×18, ink |

| Style (node) | Fill | Radius | Shadow |
|---|---|---|---|
| Grouped (23:227) | none (sits in a parent surface card, radius-card; rows separated by **1 px separator**) | — | — |
| Standalone (23:235) | **surface** | **radius-card (24)** | **shadow-card** |

States: **no Focused / Error / Disabled variants in Figma.** Suggest focus = 2 px focus-ring (AmountField uses 2 px mint-deep + mint-soft when focused — §44).

## 21. DetailRow (23:244)

| Prop | Value |
|---|---|
| Size | 343 (fill) × **56 (fixed)** |
| Layout | Row, cross center, gap space-3 (12), padding L/R space-4 (16) |
| Icon tile | **32×32 (raw)**, mint-soft, **radius-control (12)**; icon 18×18 (cake), mint-text (assumed) |
| Label | Text/body, ink, flex-1 |
| Value | Text/body, **ink-muted** (on 13 Giao diện screen instances it is mint-text), nowrap |
| Trailing | chevron-right **18×18**, ink-muted (assumed) |
| Container | none — stack inside a surface card (radius-card) with 1 px separator dividers |

## 22. Radio (23:257)

| Checked (node) | Size | Fill | Border | Content |
|---|---|---|---|---|
| True (23:253) | 24×24 | mint-deep | — | check icon **14×14**, on-mint-deep, centred |
| False (23:256) | 24×24 | none | **1.5 px control-border** | — |

Radius radius-pill. Tap area must be the whole row (≥44).

## 23. Toggle (23:262)

Flattened to a single SVG per variant (no layer data). Size **51×31** (iOS switch). Image bleeds 2 px right/left and 4 px bottom = knob drop shadow.

| On (node) | Track | Knob |
|---|---|---|
| True (23:258) | mint-deep | white (raw #FFFFFF — "White knob"), right |
| False (23:260) | separator | white, left |

Implement: iOS `CupertinoSwitch(activeTrackColor: mint-deep, inactiveTrackColor: separator, thumbColor: white)`. Night care: knob stays white (no token) — open question.

## 24. ThemeOption (23:339) — Option × Selected

Common: Column, centred, gap **8 (raw = space-2)**, padding-top **4 (raw)**; overall 84 × 196.

| Part | Value |
|---|---|
| Preview frame | **84×132**, radius **18 (raw, non-token)**, clip, content centred |
| Mini screen | 76×124 SVG artwork, **fixed colours** (shows the theme itself — do NOT theme it) |
| Label | Text/label, ink — "Sáng" / "Tối" / "Tự động" |
| Radio | §22, 24×24 |

| Selected | Preview border | Radio |
|---|---|---|
| True (Light 23:263, Dark 23:287, Auto 23:313) | **2.5 px mint-deep** | checked |
| False (Light 23:276, Dark 23:301, Auto 23:327) | **1 px separator** | unchecked |

## 25. SettingRow (23:340)

| Prop | Value |
|---|---|
| Size | 343 (fill) × hug (68) |
| Fill / radius / shadow | **surface / radius-card / shadow-card** (standalone card) |
| Layout | Row, cross center, gap space-3 (12), padding L/R space-4 (16), T/B space-3 (12) |
| Icon tile | **36×36 (raw)**, **card-night** fill, radius-control (12); icon 20×20 (sleep/moon) — colour not exposed (renders light on card-night; use on-card-night ≈ #E6F2F1 / sunshine — confirm) |
| Title | **Medium 16/24** (non-named; Text/body metrics w500), ink ("Night care") |
| Subtitle | Text/label 14/20, ink-muted ("Tự tối khi ghi sau 21:00"; screen copy "Theo lịch 21:00 – 06:00") |
| Trailing | Toggle 51×31 |

## 26. Coachmark (23:349)

| Prop | Value |
|---|---|
| Size | hug (203 × 44) |
| Layout | Column, start-aligned: arrow row on top, bubble below |
| Arrow | **16×8** triangle, fill ink, inset left **24 (raw)** |
| Bubble | fill **ink**, radius **radius-control (12)**, padding L/R space-3 (12), T/B space-2 (8), clip |
| Text | Text/label 14/20, **surface** colour ("Chạm để ghi việc đầu tiên") |
| Shadow | none |
| Behaviour | inverts in Night care automatically (ink ↔ surface tokens); one per screen; dismiss on first tap |

## 27. TourTip (102:631) — Arrow = Top / Bottom / Bottom right

Common: width **300 (raw)**, Column. Pointer strip **h 9** full width containing a **20×10** tip (ink), at left **56 (raw)** (Top, Bottom) or **234** (Bottom right). Top: pointer above card; Bottom / Bottom right: card above pointer, tip rotated 180°. Pointer x must align to target centre (description).

| Card part | Value |
|---|---|
| Fill | **ink** |
| Radius | **18 (raw, non-token)** |
| Padding | T **14**, B **12**, L/R **16** (all raw) |
| Gap | **6 (raw)** |
| Shadow | **shadow-lift** (0,12,32, ink 18%) |
| Step | **SemiBold 12/16 +0.2** (non-named; caption metrics w600), **mint** ("Bước 1/3") |
| Title | **SemiBold 18/26** (non-named; headline metrics w600), **surface** ("Ghi cữ bú đầu tiên"), wraps |
| Body | Text/label 14/20, **surface-2 @ opacity 0.85**, wraps |
| Actions row | Row, gap 8, padding-top 6 (raw): "Bỏ qua" Text/label surface-2 @ **opacity 0.75**; spacer flex; **Next** button **80×34** (raw, below tap-min — pad hit area to 44), fill **mint**, radius 999, px 16, label **SemiBold 14/20** (non-named) **ink** ("Tiếp") |

Variants: Top (102:607), Bottom (102:619), Bottom right (103:18). Use over a Scrim with the target highlighted by focus-ring.

---

## 28. CodeInput (23:355)

| Prop | Value |
|---|---|
| Outer | 343 (fill) × hug (72); fill **surface**, radius **radius-card (24)**, shadow **shadow-card**, padding **6 all (raw)** |
| Field | flex-1 × **60 (raw)**, fill **surface-2**, radius **20 (raw, non-token)**, content centred, clip |
| Text | Be Vietnam Pro **Medium 24, line-height normal, tracking +6 px** (non-named style), ink; default "482913" |
| Behaviour | 10 chars, auto-uppercase, paste-friendly; no focus/error variant in Figma |

## 29. PermissionTile (23:369)

Common: **166 × 56 (fixed)**, Row, cross center, gap **space-2 (8)**, padding L/R **space-3 (12)**, radius **radius-card (24)**. Label Text/label, nowrap. Mark = **24×24** circle, radius-pill.

| Allowed (node) | Fill | Shadow | Mark fill | Mark icon | Label colour | Sample |
|---|---|---|---|---|---|---|
| True (23:358) | surface | **shadow-card** | mint-deep | check **14×14**, on-mint-deep | ink | "Xem kỷ niệm" |
| False (23:363) | surface-2 | none | surface | lock **13×13 (raw)**, ink-muted | ink-muted | "Lịch chăm sóc" |

## 30. OptionRow (37:348)

| Prop | Value |
|---|---|
| Size | 343 (fill) × **60 (fixed)** |
| Layout | Row, cross center, gap **12 (raw = space-3)**, padding L/R **16 (raw = space-4)** |
| Text column | flex-1, Column, gap 2 (raw), clip |
| Title / Subtitle | **Inter Regular 12, line-height normal — NON-TOKEN font (design slip)**; title ink ("GMT+7"), subtitle ink-muted ("Hà Nội, TP. Hồ Chí Minh"). Implement as **Text/body ink + Text/label ink-muted** (matches ListRow) |
| Trailing | Radio 24 (§22): Selected=True (37:336) checked; False (37:343) unchecked — the only difference |
| Container | none — stack in a surface card with separators |

## 31. PageDots (23:185) — Step 1–4

| Prop | Value |
|---|---|
| Layout | Row, cross center, gap **6 (raw)**, 4 marks → 60 × 6 |
| Active | **24×6** pill, mint-deep, radius **3 (raw)** |
| Inactive | **6×6** dot, separator, radius 3 |
| Variants | Step=1 (23:165) active 1st · Step=2 (23:170) 2nd · Step=3 (23:175) 3rd · Step=4 (23:180) 4th |

## 32. Progress (23:190)

| Prop | Value |
|---|---|
| Track | **208 × 4** (flex-1 inside TopBar), separator, radius **2 (raw)** |
| Fill | mint-deep, h 4, radius 2, left-aligned |
| Variants | Value=50 (23:186) fill 104; Value=100 (23:188) fill 208 → implement as fraction |

## 33. FloatChip (23:164) — Lead = Icon / Check / Avatar

Common: fill **chip**, radius-pill, shadow **shadow-chip**, Row, cross center, gap **space-2 (8)**, padding L **6**, R **14**, T/B **6** (all raw) → h40. Value Text/label 14/20, ink, **tabular figures**. Lead circle **28×28 (raw)**, radius-pill.

| Lead (node) | Lead fill | Lead content | Sample value |
|---|---|---|---|
| Icon (23:150) | mint-soft | care icon (feed) **16×16**, mint-text (assumed) | "120 ml" |
| Check (23:155) | mint-deep | check **16×16**, on-mint-deep | "Đã đồng bộ" |
| Avatar (23:160) | mint-deep | initial **SemiBold 12, LH normal (non-named)**, on-mint-deep | "Bú · 12:40" |

Note: Chip/Floating (§5) is the older 44-tall sibling (30 px lead, 7/14/7 padding) — prefer FloatChip.

## 34. RoleOption (115:679)

Common: 343 × hug (186 sel / 184 unsel — border width diff), Column, gap **12 (raw)**, padding **16 all (raw)**, radius **20 (raw, non-token)**.

| Part | Value |
|---|---|
| Header row | Row, cross center, gap 12: icon circle **40×40** radius 999 + text column flex-1 + radio **22×22 (flattened SVG — differs from Radio 24)** |
| Icon | today **20×20** |
| Title | Text/body-strong 17/24, ink ("Người chăm sóc") |
| Subtitle | Text/caption 12/16 +0.2, ink-muted ("Ông bà, bảo mẫu") |
| Permissions | Column, gap **6 (raw)**; each row: Row gap 8, icon **16×16** + Text/label (flex-1, wraps). Allowed = check icon + **ink** text; Not allowed = lock icon + **ink-muted** text |

| Selected (node) | Fill | Border | Icon circle fill | Icon colour | Radio |
|---|---|---|---|---|---|
| True (115:621) | **mint-soft** | **2 px mint-deep** | mint-deep | on-mint-deep | checked (mint-deep) |
| False (115:650) | surface | **1 px separator** | surface-2 | ink (assumed) | unchecked ring |

## 35. MemberRow (115:704) — Status = You / Member / Pending (no description in Figma)

Common: 343 × hug (68), Row, cross center, gap **12**, padding L/R **16**, T/B **12** (all raw = space-3/space-4 unbound). No fill (sits in a surface card).

| Part | Value |
|---|---|
| Avatar | **44×44 (raw)** circle; initial Text/body-strong ink |
| Name | Text/body-strong 17/24, ink ("Mai") |
| Detail | Text/caption 12/16 +0.2, ink-muted ("Mẹ · Cùng nuôi"); text column gap 2 |

| Status (node) | Avatar | Trailing |
|---|---|---|
| You (115:680) | peach-soft fill | Badge "Bạn": mint-soft, radius 999, padding **10 / 3 (raw)**, **SemiBold 12/16 +0.2** (non-named) mint-text |
| Member (115:688) | peach-soft fill | chevron-right **18×18**, ink-muted (assumed) |
| Pending (115:696) | **surface + 1.5 px control-border** | "Gửi lại" pill: surface-2, radius 999, padding **12 / 6 (raw)** → 28 h, **SemiBold 12/16 +0.2** ink — below tap-min, pad hit area to 44 |

## 36. RelationChip (115:709) (no description in Figma)

| Selected (node) | Fill | Border | Label |
|---|---|---|---|
| True (115:705) | mint-deep | — | **SemiBold 14/20** (non-named; label metrics w600), on-mint-deep |
| False (115:707) | surface | **1 px separator** | SemiBold 14/20, ink |

Common: padding L/R **16**, T/B **10** (raw) → h 40, radius 999, hug width (~53 for "Mẹ"). Height 40 < 44: add vertical hit slop.

## 37. AccountRow (23:370)

| Prop | Value |
|---|---|
| Size | 343 (fill) × hug (60) |
| Fill / radius / shadow | surface / radius-card / **shadow-card** |
| Layout | Row, cross center, gap space-3 (12), padding L/R space-4 (16), T/B space-3 (12) |
| Avatar | **36×36 (raw)**, mint-deep, radius-pill; initial **SemiBold 15, LH normal (non-token)**, on-mint-deep |
| Email | Text/label 14/20, ink, flex-1 (wraps) |
| Provider chip | Chip Neutral without icon: surface-2, radius-pill, px 12 py space-1; Text/label ink ("Apple") |

---

## 38. BabySwitcher (45:321)

| Prop | Value |
|---|---|
| Size | hug (130 × 40) |
| Fill / radius | **surface-2** / 999 (raw = radius-pill) |
| Layout | Row, cross center, gap **8 (raw)**, padding L **4**, R **12**, T/B **4** (raw) |
| Avatar | Illustration/BabyFace scaled to **32×32** (fixed-colour art; real photo in app) |
| Name | **Medium 16/24** (non-named; body metrics w500), ink ("Teddy") |
| Chevron | chevron-down **16×16**, ink (assumed); shown only when the family has >1 baby |
| Hit area | 40 h → add 2 px vertical slop to reach 44 |

## 39. FilterChip (45:347)

| Selected (node) | Fill | Label |
|---|---|---|
| True (45:343) | mint-deep | **Medium 16/24** (non-named), on-mint-deep |
| False (45:345) | surface-2 | Medium 16/24, ink |

Common: **h 40 (raw)**, padding L/R **16 (raw)**, radius 999, hug width (83 for "Tất cả"), no border/shadow. Row scrolls horizontally; last chip may peek. Default label "Tất cả".

## 40. DayPill (45:342)

| Selected (node) | Fill | Shadow | Weekday | Day |
|---|---|---|---|---|
| True (45:336) | mint-deep | none | Text/caption 12/16 +0.2, on-mint-deep | **SemiBold 20/26** (non-named), on-mint-deep |
| False (45:339) | surface | **shadow-card** | Text/caption, ink-muted | SemiBold 20/26, ink |

Common: **44 × 64**, radius **22 (raw = fully rounded)**, Column centred, no gap. Defaults "T5" / "8". Today = right-most pill.

## 41. ChoiceTile (45:386)

| Selected (node) | Fill | Border |
|---|---|---|
| True (45:374) | mint-soft | **2.5 px mint-deep** |
| False (45:380) | **surface-2** | — |

Common: **106 × 120**, radius **28 (raw — equals radius-tile but not bound)**, Column centred, gap **8 (raw)**; art Illustration/Mini/* scaled to **52×52** (fixed colours); label **Text/headline** 18/26 ink ("Ướt"). No shadow. Remembers last choice.

## 42. TimeRow (45:387)

| Prop | Value |
|---|---|
| Size | 343 (fill) × **52** |
| Layout | Row, cross center, gap **10 (raw, non-token)**, no padding |
| Icon | clock **20×20**, ink-muted (assumed) |
| Label | Text/body, ink, flex-1 ("Thời gian") |
| Value chip | mint-soft, radius 999, padding **14 / 8 (raw)** → 40 h; text **Medium 16/24** (non-named) mint-text ("Bây giờ · 15:05") — tap opens time wheel |

## 43. InfoRow (45:394)

| Prop | Value |
|---|---|
| Size | 343 (fill) × **56** |
| Layout | Row, space-between, cross center, padding L/R **16 (raw)** |
| Label | Text/body, **ink-muted** ("Thời gian") |
| Value | **Text/body-strong** 17/24, ink ("Hôm nay · 14:20") |
| Container | none (sits in a surface card with separators) — read-only, not tappable |

## 44. AmountField (45:403) — State = Focused / Default

Common: 343 (fill) × **88**, radius **24 (raw — equals radius-card, unbound)**, Row, **baseline**-aligned, centred, gap **8 (raw)**, padding-top **14 (raw)**. Value **Numbers/numeral-xl** 52/56 −1, ink, **tabular figures**; unit **Text/headline** ink-muted ("ml").

| State (node) | Fill | Border |
|---|---|---|
| Focused (45:397) | **mint-soft** | **2 px mint-deep** |
| Default (45:400) | surface-2 | — |

Optional field (never required to save). Font family in export lacks explicit family on the paragraph, styles are named → Be Vietnam Pro.

## 45. EntryOption (69:609) — Style = Primary / Secondary

Common: 343 × hug (103 / 102), Row, cross center, gap **14 (raw)**, padding **16 all (raw)**, radius **20 (raw, non-token)**. Icon circle **48×48**, radius **24 (raw)**; icon clock **24×24**. Text column flex-1, gap 2: title **Text/headline** ink ("Bắt đầu hẹn giờ"); subtitle **Text/label** ink-muted (wraps). Trailing chevron-right **20×20**, ink-muted (assumed).

| Style (node) | Fill | Border | Icon circle | Icon colour |
|---|---|---|---|---|
| Primary (69:589) | **care-sleep-soft** | **1.5 px care-sleep-accent** | care-sleep-accent | white (visually confirmed; use surface or on-mint-deep-like white) |
| Secondary (69:599) | surface | **1 px separator** | care-sleep-soft | care-sleep-ink (visually confirmed purple) |

Note: uses care/sleep tokens (sleep entry screen); swap to the matching care category when reused.

## 46. SelectTile (25:399)

| Selected (node) | Fill | Border | Shadow | Check |
|---|---|---|---|---|
| True (25:373) | mint-soft | **2 px mint-deep** | none | **24×24** mint-deep circle, check **14×14** on-mint-deep, top-right |
| False (25:386) | surface | — | **shadow-card** | none |

Common: **166 × 128**, radius **radius-tile (28)**, Column, space-between, padding **14 all (raw)**. Top row: art Illustration/Mini/* **48×48** (fixed colours) + check. Label **Text/headline** ink ("Bú bình"), bottom-left. Multi-select.

---

## 47. Page scaffold — screen "19 Hôm nay · Light" (46:2266)

Frame 375 × 1125 (long scroll mock). Figma-only mock chrome: frame border 1 px separator + radius 44 (device outline) and StatusBar 11:135 (40 tall, pt 14, px 28) — **do not implement**; use the system status bar.

| Prop | Value |
|---|---|
| Background | **cloud** (Light #F6FCFB / Night #0C1719) |
| Top safe area | StatusBar mock = 40 → in app: `SafeArea(top)`; content starts **4 (raw)** below it |
| Content padding | L/R **16 (= space-4, unbound)**, top **4**, bottom **120 (raw)** = clearance so last content scrolls above the TabDock (68 + 24 + ~28) |
| Content width | 341 in the mock (the 1 px frame border steals 2 px) → **343 in app** (375 − 2×16) |
| Header row (44 h) | Row, space-between, cross center: **BabySwitcher** (name "Teddy · 3 tuần") left · **Night care toggle** right = 44×44 circle surface-2 radius 999, icon sleep (moon) **20×20** ink |
| Gap | **8 (raw = space-2)** |
| Date subtitle | Text/label, ink-muted ("Thứ Năm, 8 tháng 10") |
| Large title | **Text/large-title** 32/40 −0.4, ink ("Hôm nay"), left-aligned at x 16 — placed inline in the scroll content (not the NavHeader component, not a collapsing app bar) |
| Gap | **12 (raw = space-3)** |
| Care tiles grid | 3 rows × 2 CareTiles; column gap **11** and row gap **11 (raw — NOT space-3)**; tiles flex-1 (≈165 w); row 1 tiles 158 h (stretch to tallest), rows 2–3 138 h. CareTile: radius **24 (raw, = radius-card)**, padding T 12 / L-R 12 / B 14, gap 8, **1 px card-edge** border, **shadow-tile**, art 84×84 bleeding bottom −13 / right −15 |
| Gap | 12 |
| ReminderPeek (128:665) | surface, **radius 18 (raw)**, shadow-card, pl 14 pr 12 py 12, gap 12; icon circle 40 sunshine-soft r20, clock 20; label SemiBold 12/16 ink-muted, title Text/body-strong ink, meta caption ink-muted; chevron 18 |
| Gap | **16 (raw)** |
| SectionHeader instance | "Hôm nay" + "Lịch sử" link; instance overrides padding **T 20, B 8**, L/R 4 (→ 54 h) — with the preceding 16 gap the title sits 36 below ReminderPeek; component rule says space-6 above / space-2 below |
| DayRhythm (48:409) | surface, radius 24, shadow-card, pt 14 pb 12 px 16, gap 8 |
| TabDock | `position: absolute`, full width 375, height 68, px 16, gap 12; **bottom edge 24 above the screen bottom** in the mock (frame 1125, dock y 1032–1100 + 1 px border). Description: "24px above the home indicator". → Flutter: `Positioned(left:0,right:0,bottom: 24 + MediaQuery.padding.bottom?)` — mock shows 24 from the physical bottom with no home-indicator drawn; recommend `bottom: max(24, safeBottom)` and confirm with design. Content scrolls under it (no background behind dock) |
| Annotation on frame | "Thẻ lớn = vừa ghi vừa xem: chạm thẻ → mở sheet ghi mục đó (1 chạm); dòng dưới là lần cuối (bao lâu trước · chi tiết · ai ghi). Ngủ khi timer chạy → CareTile Tone=Active hiện thời gian đang chạy. Tăng trưởng: hàng riêng, + mở màn nhập số đo. "Lịch sử" → dòng thời gian." |

---

## 48. Visual check (screenshots 69:609 EntryOption, 23:379 Onboarding & Auth section)

Confirmed icon colours: EntryOption Primary icon = white on care-sleep-accent, Secondary icon = care-sleep ink/accent on care-sleep-soft, chevrons grey (ink-muted); SettingRow moon icon light on card-night; TopBar Brand theme toggle moon ink; PermissionTile not-allowed lock ink-muted; RoleOption selected icon white on mint-deep; **RoleOption radio (22 px flattened) is a filled mint-deep circle with a white inner dot, not the Radio check** — implement as its own radio look or reuse Radio 24 (decision needed); MemberRow chevron ink-muted; FloatChip Icon lead icon dark (mint-text/ink). Remaining "assumed" icon colours in this file were not visually verified.

---

## 49. Non-token / unbound values summary (implementation decisions needed)

Fonts / text styles not in the type scale
- **Inter Regular 12** in OptionRow (37:348) title + subtitle — design slip → use Text/body + Text/label.
- SemiBold 24/32 — SheetHeader, BottomSheet/Feed title (also HeroCard). Propose `Text/title-2`.
- Medium 16/24 (body metrics, w500) — Segmented selected label, SettingRow title, FilterChip, BabySwitcher name, TimeRow value, FieldRow value, Banner lead.
- Medium 14/16 +0.2 — NavBar active label (description says "caption").
- SemiBold 12/16 +0.2 — TourTip step, MemberRow badges, ReminderPeek label.
- SemiBold 14/20 — RelationChip, TourTip Next. SemiBold 18/26 — TourTip title. SemiBold 20/26 — DayPill day, CareTile value.
- Initials: SemiBold/Medium 11 (NavBar Me ring), SemiBold 12 (FloatChip avatar), SemiBold 15 (AccountRow), all line-height normal.
- CodeInput Medium 24 / LH normal / tracking +6.

Colours
- Banner/Error lead text raw **#A12B32** (= error Light) — bind to `error` or it will not flip in Night care.
- Toggle knob white (no token). Mini-illustrations, ThemeOption previews, BabyFace: fixed-colour art by design.
- TourTip body/skip use opacity 0.85 / 0.75 on surface-2.

Radii not on the scale: 18 (ThemeOption preview, TourTip card, ReminderPeek), 20 (CodeInput field, RoleOption, EntryOption), 22 (DayPill), 3 (SheetHeader grabber, PageDots), 2 (Progress), 24 raw (AmountField, EntryOption circle, CareTile — equal to radius-card but unbound), 28 raw (ChoiceTile = radius-tile unbound), 999 raw (NavBar, QuickLogButton, BabySwitcher, FilterChip, RelationChip, MemberRow badges = radius-pill unbound).

Spacing not on the scale: 2, 5 (Segmented pad), 6 (NavBar pad, SyncStatus py, FloatChip, CodeInput pad, TourTip gap), 7 / 14 (Chip/Floating), 10 (TimeRow gap, RelationChip py, MemberRow badge px), 11 (Today tile grid gap), 14 (SelectTile pad, EntryOption gap, TourTip pt, AmountField pt, active NavBar tab px), 18/20/24/28 sizes etc. Values equal to tokens but unbound: 4, 8, 12, 16 in SheetHeader, OptionRow, MemberRow, RoleOption, RelationChip, InfoRow, SectionHeader, Chip px 12.

Sizes not tokenised: Button Secondary h52; Segmented item h46; Avatar 40; MemberRow avatar 44; AccountRow avatar 36; SettingRow tile 36; DetailRow tile 32; TextField eye 32; Chip/Floating lead 30; FloatChip lead 28; QuickLogButton 68; NavBar 263×68; TourTip 300 w; TourTip Next 80×34 (< tap-min); MemberRow "Gửi lại" 28 h (< tap-min); FilterChip / RelationChip / BabySwitcher 40 h (< tap-min — add hit slop).

Shadows: all bound to named styles (shadow-card / -chip / -nav / -sheet / -lift / -tile); none raw. Night care variants of chip/nav/lift still missing (see 07 §6).

States: no Pressed / Disabled / Focused variants exist except AmountField (Focused) and the Selected/Checked/On variants listed. TextField has no focus/error state.

## Coverage

Read via get_design_context: all 50 requested components (Button + Round + Back, Chip, Chip/Floating, SyncStatus, Banner/Error, Avatar, Segmented + Item, ListRow, SectionHeader, EmptyState, NavBar (all 10 variants + metadata for slot widths), TabDock, QuickLogButton (via TabDock), NavHeader, SheetHeader, BottomSheet/Feed (+ NumField, FieldRow), TopBar (6), TextField, DetailRow, Radio, Toggle (flattened SVG — track/knob colours from description), ThemeOption, SettingRow, Coachmark, TourTip, CodeInput, PermissionTile, OptionRow, PageDots, Progress, FloatChip, RoleOption, MemberRow, RelationChip, AccountRow, BabySwitcher, FilterChip, DayPill, ChoiceTile, TimeRow, InfoRow, AmountField, EntryOption, SelectTile) and screen 46:2266. Icon stroke colours are not exposed by the MCP (SVG assets); see §48.
