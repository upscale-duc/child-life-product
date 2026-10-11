# v1.0 · improvement — spec extracted from final Figma (page "v1.0 - improvement")

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only), page/canvas **"v1.0 - improvement"** `345:35701`. Extracted 2026-10-11. No Figma node was modified.

**What this page is.** A set of improvement clusters on top of the V1 screens in `01`–`05`. Each cluster on the canvas starts with a bold label (a text node, 28px) that states the intent; this document quotes every label verbatim and follows the canvas order (top to bottom). Frames inside a cluster are listed left to right.

**How it was read**
- `get_design_context` (code + data-annotations + component descriptions + screenshot) on every frame, or on the sheet sub-node plus a full-frame screenshot for sheets; label text nodes read individually. Large frames were read from the saved tool output with a script that lists annotations, rendered text, layer names and component props.
- Chart values: taken from layer names where they carry values (e.g. "21h · 54 ml", "T5 · 6.5 giờ"); otherwise derived from bar heights/positions in the generated code and marked "approx.". The px scale used is stated.
- Rendered text is authoritative over layer names; stale layer names are flagged.
- "(inferred)" marks anything the design does not state literally. Frame annotations are quoted verbatim; several frames carry an annotation copy-pasted from another screen, which is flagged where it happens.
- Night care: only cluster 1 has a Night twin on this page (`345:35703`, identical node tree to Light). Every other frame is Light only.
- Mock scenario as in `02`: Thursday 8 Oct 2026, now 15:05, baby Teddy born 17 Sep (3 weeks), family Mẹ (Mai), Ba, caregiver Cô Lan; a second baby "Na" appears in 20d-below-reference and in Tôi.

**Coverage.** All 45 frames and all 10 label nodes were read (the Night twin 345:35703 by structure diff + screenshot). No call failed and no rate-limit error occurred. See "Coverage" at the end.

**"Compared with the current app".** Each cluster ends with a diff against the Flutter app in `apps/mobile/lib` as of 2026-10-11 (working tree). The working tree has uncommitted, in-progress work on this same page (e.g. `features/care/who_growth.dart`, `growth_standards_screen.dart`, `growth_chart.dart`, `stacked_days_chart.dart`); diffs describe the committed behaviour and mention that in-progress work where it overlaps.

## Cross-cutting change: NavBar v1.0.1 (new tab model)
Every in-app frame on this page uses the nested **"NavBar v1.0.1"** inside TabDock:
- Parent: **Tab/Today · Tab/Memories · Tab/Care ("Chăm sóc") · Tab/Family** + QuickLogButton "+". Active tab = white pill with icon + label; others icon only.
- **No Me/"Tôi" tab.** "Tôi" is opened from a **user avatar at the left of the Today/Care header** (frame "CS Tôi (từ avatar)", cluster 8) and is a pushed screen without the dock.
- **New "Chăm sóc" (Care) tab** is the hub for Nhắc nhở (reminders), Thống kê (stats), Lịch sử (history) and Tăng trưởng (growth); the stats, history and growth frames on this page all show "Chăm sóc" active.
- Caregiver ("người chăm"): Today · Care · Family (no Memories), still with "+".
- Memories frames (cluster 10) show the dock **without** the "+" button.
- Exception: the background of "22 Ghi bú bình · gợi ý nhanh" still shows the old NavBar (Hôm nay · Kỷ niệm · Gia đình · Me avatar); it is a stale background.
Current app: `ClTab {today, memories, family, me}` in `apps/mobile/lib/core/widgets/cl_navigation.dart` (`tabsForRole`, `ClNavBar`, `ClTabDock`, `_MeRing`), branch order Hôm nay · Kỷ niệm · Gia đình · Tôi, "+" on every tab for parents and caregivers; stats/history/growth routes live in the Today branch (`/today/stats/*`, `/today/history`, `/today/reminders`). Moving to v1.0.1 means a new Care branch, re-homing those routes, removing the Me tab, adding a header avatar, and updating the role → tabs matrix in `03-roles-reminders-offline-caregiver.md` ("Navigation per role"). The relative ("Người thân") dock for v1.0.1 is not drawn on this page.

---

## Cluster 1 — Label 345:35702 (verbatim): "Avatar khi chưa biết là ai → icon gia đình"
(When we don't know who the person is yet, the avatar becomes a family icon.)

### 345:35762 — 10 Email đã có tài khoản · Light (cải tiến) [Night 345:35703]
**Purpose:** account-linking dead end. The email the user typed already belongs to an account created with Apple, so they must sign in with Apple first and then link. The improvement is the avatar: instead of a person initial / photo it shows the generic `Icon/family` glyph, because the app does not yet know which family member this is.

**Text (reading order)**
- TopBar (Type=Back): round Button/Back only (a11y "Quay lại").
- Illustration/AccountLink (mint card `card-mint #2cbfb3`, radius-hero 36, h236): two linked circles — left dark-mint circle containing **Icon/family** (52px, white), a yellow link badge, right white circle with an envelope icon.
- Title (Text/title 30): "Email đã có tài khoản" (This email already has an account)
- Body (ink-muted 16): "Đăng nhập bằng Apple, rồi liên kết." (Sign in with Apple, then link.)
- AccountRow (white card, radius-card 24, shadow-card): Avatar 36px mint-deep circle containing **Icon/family 18px** (not an initial, not a photo) · "mai.nguyen@email.com" · Chip (Neutral, surface-2) "Apple" (the provider that owns the account).
- Flex spacer.
- Button (Apple style, black, h56, Apple mark icon): "Tiếp tục với Apple" (Continue with Apple)
- Button (Plain, mint-text): "Dùng email khác" (Use a different email)

**Components used:** StatusBar, TopBar (Back), Button/Back, Illustration/AccountLink, Icon/family, AccountRow (local frame: Avatar + text + Chip), Chip (Neutral), Button (Apple variant + Plain). Component note (verbatim, Button 8:33): "Apple: use Apple’s official button in production." Icon/brand-mark (22:197): "Placeholder for Apple / Google marks — use the official logos in production."

**Navigation (inferred from copy):** "Tiếp tục với Apple" → native Sign in with Apple, then link the email credential to that account; "Dùng email khác" → back to the email entry; Back → previous step.

**States / variants:** Light and Night care only. Night 345:35703 has an identical node tree (same text, same instances: TopBar, Illustration/AccountLink with Icon/family, AccountRow with Icon/family avatar, Chip, two Buttons); only theme tokens differ (confirmed by screenshot: dark surfaces, white Apple button with black text, same copy).

**Notes / not shown**
- The provider chip is "Apple" only; a Google-owned variant ("Tiếp tục với Google") is not drawn on this page (the original screen 10 in `01-onboarding-auth-profile-family.md` is the reference for other providers).
- The rule implied by the label is general: wherever the app shows an avatar for a person it cannot identify yet (no member profile, no name), render the family icon on mint-deep rather than an initial or a placeholder face.

### Compared with the current app (cluster 1)
- Screen exists: `AccountExistsScreen` (`apps/mobile/lib/features/auth/auth_screens.dart`, route `/auth/exists`). Its `AccountLinkHero` / `ClIllustration.accountLink` and `ClAccountRow` render the **email's first letter (or "@")** as the avatar. The design now wants **`Icon/family`** in both places (the 52px glyph in the hero's left circle and the 18px glyph in the 36px mint-deep row avatar), not a letter.
- Copy differs: the app shows "Đăng nhập bằng Apple hoặc Google, rồi liên kết." and the provider label "Apple · Google", with both an Apple and a Google button. The design shows one provider: "Đăng nhập bằng Apple, rồi liên kết.", chip "Apple", one button "Tiếp tục với Apple" plus "Dùng email khác". To match, the screen must know which provider owns the email (e.g. from `fetchSignInMethodsForEmail` / the `account-exists-with-different-credential` error) and show only that one. The Google variant is implied, not drawn.
- The rule generalises to any avatar of an unknown or not-yet-identified person (no member profile yet), so check other `ClAvatar` / initial fallbacks too (inferred scope).

---

## Cluster 2 — Label 346:63 (verbatim): "Thống kê bú: Tất cả · Bú bình · Bú mẹ"
(Feeding stats: All · Bottle · Breast.)

Three versions of the feeding-stats screen, one per **type filter**, plus two bottom sheets (SH Thống kê bú · Loại / · Thời gian, frames 391:3185 and 391:3373, placed on the canvas next to these three and described at the end of this cluster).

### Shared chrome (all three 20g frames)
- Row: Button/Back (a11y "Quay lại") · BabySwitcher "Teddy" (avatar + name + chevron; no age suffix here).
- Title "Thống kê bú" (Feeding statistics), Text/title 30.
- **Filters row (new; replaces the old Hôm nay | 7 ngày | 30 ngày segmented control):** two dropdown pills (white, 1px separator border, radius 999, 14px SemiBold):
  - Type pill: Icon/feed + "Tất cả" / "Bú bình" / "Bú mẹ" + Icon/chevron-down → opens **SH Thống kê bú · Loại**.
  - Time pill: Icon/clock + "7 ngày" + Icon/chevron-down → opens **SH Thống kê bú · Thời gian**.
- 3 KPI tiles (white, radius 16, value 18 SemiBold, label 11 Medium muted).
- First card is a **per-day bar chart for the window** (new), with a dashed average line + label "TB …", day labels T6 T7 CN T2 T3 T4 **T5** (today bold; today's bar drawn at full opacity, previous days at 55% opacity — so the highlighted bar = the selected/today day), and a dark **Tooltip** above the chart for the highlighted day.
- **TabDock uses NavBar v1.0.1 (new):** tabs Tab/Today (sun icon) · Tab/Memories · **Tab/Care "Chăm sóc" (active, labelled)** · Tab/Family, plus QuickLogButton "+". There is **no Me/avatar tab** in this NavBar; stats now live under the Care tab, not under Today. (See cluster 7 for the Care tab.)
- Frame annotation on all three frames is the stale History annotation copied over (verbatim): "Dòng thời gian mới nhất ở trên, chia theo buổi (Sáng/Trưa/Chiều/Tối). Giấc ngủ và bú mẹ là khối có thời lượng. Chạm mục → Chi tiết bản ghi. Lọc “Tăng trưởng” hiện các lần đo." — it does not describe these screens (same copy-paste issue noted in `02-today-care-history-widgets.md` Part C §0.1).

### 346:64 — 20g Thống kê bú · Tất cả (filter = All feeds, 7 days)
**Text (reading order)**
- Filters: "Tất cả" ▾ · "7 ngày" ▾
- KPIs: "8 cữ" / "TB mỗi ngày" (avg feeds per day) · "640 ml" / "Bú bình/ngày" (bottle ml per day) · "42 phút" / "Bú mẹ/ngày" (breastfeeding minutes per day)
- Card **"Bú mỗi ngày"** (Feeds per day) / subtitle "Số cữ bú bình và bú mẹ · 7 ngày" (Number of bottle and breast feeds · 7 days)
  - Stacked bar chart, Y axis 0 / 4 / 8 (feeds). Each day's bar = bottle (care-bottle-accent #3b8fd9, bottom) + breast (care-breast-accent #e07a9a, top). Values read from bar heights (15 px per feed):
    | Day | T6 | T7 | CN | T2 | T3 | T4 | T5 (today) |
    |---|---|---|---|---|---|---|---|
    | Bú bình (feeds) | 5 | 6 | 5 | 4 | 5 | 6 | 5 |
    | Bú mẹ (feeds) | 3 | 2 | 3 | 4 | 3 | 2 | 3 |
  - Dashed average line at 8 labelled "TB 8 cữ".
  - Tooltip (dark ink pill): "T5 · 5 bình 600 ml · 3 mẹ 45′" (Thu · 5 bottles 600 ml · 3 breast 45 min). (Layer name is stale: "T5 · 5 cữ bình 600 ml · 3 cữ m…".)
  - Legend: ■ "Bú bình" · ■ "Bú mẹ"
  - Ratio bar 62:38 (bottle blue : breast pink) + two lines: "Bú bình 62% · 640 ml/ngày" / "Bú mẹ 38% · 42 phút/ngày". (What the 62/38 is a share of is not stated; 5/8 feeds = 62.5% → by feed count, inferred.)
- Card **"Bú ngày và đêm"** (unchanged from old 20g): subtitle "Ngày 06:00–18:00 · Đêm 18:00–06:00 · TB 7 ngày"; ratio bar (sunshine / sleep-accent; still drawn flex 1:1 although labels say 62/38); legend "Ngày 62%" / "400 ml · 5 cữ", "Đêm 38%" / "240 ml · 3 cữ"; insight "Đêm qua bú 3 cữ, khoảng nghỉ dài nhất 3 giờ 40 phút (00:20–04:00)." (Last night 3 feeds, longest gap 3 h 40 (00:20–04:00).)
- Card **"Bú mẹ"** (unchanged): "TB 7 ngày"; "3 cữ" / "mỗi ngày"; "14 phút" / "mỗi cữ"; side bar 52:48; legend "Bên trái 52%" · "Bên phải 48%"; hint (breast-soft) "Lần trước kết thúc bên phải → lần tới nên bắt đầu bên trái."
- Not on this filter: the "Lượng sữa theo giờ" hourly card (moved to the Bú bình filter).

### 346:354 — 20g Thống kê bú · Bú bình (filter = Bottle, 7 days)
**Text (reading order)**
- Filters: "Bú bình" ▾ · "7 ngày" ▾
- KPIs: "640 ml" / "TB mỗi ngày" · "5 cữ" / "TB mỗi ngày" · "120 ml" / "TB mỗi cữ" (avg per feed)
- Card **"Lượng sữa mỗi ngày"** (Milk volume per day) / "Tổng ml bú bình · 7 ngày" (Total bottle ml · 7 days)
  - Stacked bars, Y axis 0 / 400 / 800 (ml). Bottom segment = **"Sữa mẹ vắt"** (expressed breast milk, care/pump/accent #b068c9), top segment = **"Sữa công thức"** (formula, bottle blue). Values from bar heights (75 px per 400 ml), approx.:
    | Day | T6 | T7 | CN | T2 | T3 | T4 | T5 |
    |---|---|---|---|---|---|---|---|
    | Sữa mẹ vắt (ml) | ~230 | ~230 | ~170 | ~290 | ~230 | ~230 | ~230 |
    | Sữa công thức (ml) | ~360 | ~420 | ~400 | ~300 | ~380 | ~420 | ~360 |
    | Total (ml) | ~590 | ~650 | ~570 | ~590 | ~610 | ~650 | ~590 (tooltip says 600) |
  - Dashed average line "TB 640 ml".
  - Tooltip: "T5 · 600 ml · 5 cữ".
  - Legend: ■ "Sữa mẹ vắt" · ■ "Sữa công thức".
- Card **"Bú ngày và đêm"**: identical copy and numbers to the Tất cả frame ("400 ml · 5 cữ" / "240 ml · 3 cữ", same insight).
- Card **"Lượng sữa theo giờ"** (moved here from the old 20g): "Bú bình · trung bình 7 ngày (ml)"; 24 hourly bars, Y 0/20/40/60, X 0h 6h 12h 18h 24h, night shading 0–6h and 18–24h; hourly values (layer names) 0h 19, 1h 28, 2h 13, 3h 35, 4h 9, 5h 25, 6h 38, 7h 13, 8h 44, 9h 9, 10h 22, 11h 41, 12h 13, 13h 19, 14h 44, 15h 16, 16h 25, 17h 38, 18h 19, 19h 28, 20h 35, 21h 54 (peak, bottle-ink), 22h 19, 23h 32; peak label "21h · 54 ml"; legend "ml mỗi giờ" · "Khung đêm".
- No "Bú mẹ" card on this filter.

### 346:590 — 20g Thống kê bú · Bú mẹ (filter = Breastfeeding, 7 days)
**Text (reading order)**
- Filters: "Bú mẹ" ▾ · "7 ngày" ▾
- KPIs: "42 phút" / "TB mỗi ngày" · "3 cữ" / "TB mỗi ngày" · "14 phút" / "TB mỗi cữ"
- Card **"Thời gian bú mẹ mỗi ngày"** (Breastfeeding time per day) / "Tổng phút · bên trái và bên phải" (Total minutes · left and right side)
  - Stacked bars, Y axis "0′" / "30′" / "60′" (minutes). Bottom = "Bên trái" (care-breast-accent #e07a9a), top = "Bên phải" (care-breast-ink #a33a5e). Values from bar heights (2.5 px per minute), approx.:
    | Day | T6 | T7 | CN | T2 | T3 | T4 | T5 |
    |---|---|---|---|---|---|---|---|
    | Bên trái (min) | ~21 | ~14 | ~23 | ~29 | ~19 | ~13 | ~23 |
    | Bên phải (min) | ~20 | ~13 | ~22 | ~28 | ~22 | ~16 | ~21 |
    | Total (min) | ~41 | ~27 | ~45 | ~57 | ~41 | ~29 | ~44 (tooltip 45) |
  - Dashed average line "TB 42 phút".
  - Tooltip: "T5 · 45 phút · 3 cữ".
  - Legend: ■ "Bên trái" · ■ "Bên phải".
  - Banner (surface-2, Icon/clock): "Bú mẹ khó đo lượng sữa, nên app thống kê bằng thời gian bú." (Breast milk volume is hard to measure, so the app counts breastfeeding by time.)
- Card **"Bú ngày và đêm"** — same title and subtitle, but values switch to minutes: "Ngày 62%" / "26 phút · 2 cữ", "Đêm 38%" / "16 phút · 1 cữ" (bar still drawn 1:1). Insight: "Đêm qua bú mẹ 1 cữ, 16 phút (02:10)." (Last night 1 breastfeed, 16 min (02:10).)
- Card **"Bú mẹ"** — identical to the Tất cả frame ("TB 7 ngày", "3 cữ"/"mỗi ngày", "14 phút"/"mỗi cữ", 52:48, hint).
- No hourly ml card on this filter.

### 391:3185 — SH Thống kê bú · Loại (type filter sheet)
**Background:** 20g Thống kê bú · Tất cả (same copy and numbers as 346:64), dimmed by Scrim (`scrim rgba(12,23,25,0.32)`).
**Sheet** (white, top radius 28, pb 34): SheetHeader (grabber, title, close ✕ 44px "Đóng") title **"Loại bú"** (Feed type). Radio list (22px radio circles; filled mint = selected), each row title 15 SemiBold + caption 12 muted:
- ● "Tất cả" / "Bú bình và bú mẹ" (Bottle and breast) — selected
- ○ "Bú bình" / "Theo lượng sữa (ml)" (By milk volume (ml))
- ○ "Bú mẹ" / "Theo thời gian bú (phút)" (By feeding time (minutes))
**Behaviour (inferred):** tapping a row sets the type pill and closes the sheet; the screen swaps to 346:64 / 346:354 / 346:590. No "Hút sữa" (pump) option.

### 391:3373 — SH Thống kê bú · Thời gian (time range sheet)
**Background:** 20g Tất cả, dimmed.
**Sheet:** SheetHeader title **"Khoảng thời gian"** (Time range). Radio rows:
- ○ "Hôm nay" (Today) — no caption
- ● "7 ngày" / "2 – 8 tháng 10" (2–8 October) — selected
- ○ "30 ngày" / "9/9 – 8/10"
- ○ "Tuỳ chọn" / "Chọn từ ngày – đến ngày" (Custom / Choose from date – to date)
**Notes / not shown:** the custom-range picker after "Tuỳ chọn" is not drawn; how the per-day chart renders for "Hôm nay" (single day) or 30 days / a long custom range is not drawn (the old 20g2 "Hôm nay" layout from `02-…` Part C §9 is the only Today reference). The caption date formats differ between rows ("2 – 8 tháng 10" vs "9/9 – 8/10"). The 7-day window ends today (2–8 Oct, inclusive).

### Compared with the current app (cluster 2)
Current: `FeedStatsScreen` in `apps/mobile/lib/features/care/stats_screens.dart` (route `/today/stats/feed`, reached from History "Bú" filter via "Xem thống kê bú"), maths in `care_calc.dart` `feedStats()` with `StatsWindow {today, week, month}` and a `ClSegmented` Hôm nay / 7 ngày / 30 ngày saved in prefs `stats.feed.window`.
New or different:
1. **Controls:** replace the segmented control with two dropdown pills (type + time) and two new bottom sheets: "Loại bú" (Tất cả / Bú bình / Bú mẹ, with captions) and "Khoảng thời gian" (Hôm nay / 7 ngày / 30 ngày / **Tuỳ chọn** custom from–to range with date captions "2 – 8 tháng 10", "9/9 – 8/10"). A custom range needs a date-range picker (not designed) and `feedStats()` must accept arbitrary [from, to] instead of the 3-value enum. Persist type as well as window (inferred, matching the Segmented "remembers last choice" rule).
2. **New per-day bar chart** as the first card for every type: Tất cả = "Bú mỗi ngày" (stacked bottle/breast feed counts per day, avg line "TB 8 cữ", ratio bar + two summary lines); Bú bình = "Lượng sữa mỗi ngày" (stacked ml per day split **Sữa mẹ vắt / Sữa công thức**, avg line); Bú mẹ = "Thời gian bú mẹ mỗi ngày" (stacked minutes per day **Bên trái / Bên phải**, avg line, banner "Bú mẹ khó đo lượng sữa, nên app thống kê bằng thời gian bú."). Each has a dark tooltip for the highlighted day ("T5 · 5 bình 600 ml · 3 mẹ 45′", "T5 · 600 ml · 5 cữ", "T5 · 45 phút · 3 cữ") — so bars need tap/selection handling (today selected by default, inferred); current painters have no gestures.
3. **New data split:** per-day bottle ml by milk type (`milk` field on bottle records: breast milk vs formula) and per-day breast minutes by side (`leftMin`/`rightMin`, or `durationMin` + `side` when not timed). Records that have neither side minutes nor a side need a rule (not designed).
4. **KPI sets change per type:** Tất cả = "8 cữ / TB mỗi ngày", "640 ml / Bú bình/ngày", "42 phút / Bú mẹ/ngày" (new: breast minutes per day; average gap KPI dropped); Bú bình = ml/day, feeds/day, **"TB mỗi cữ"** ml per feed (new); Bú mẹ = minutes/day, feeds/day, minutes per feed.
5. **Card set per type:** Tất cả = per-day + Bú ngày và đêm + Bú mẹ (hourly ml card removed); Bú bình = per-day + Bú ngày và đêm + Lượng sữa theo giờ; Bú mẹ = per-day + Bú ngày và đêm (in **minutes**, new insight "Đêm qua bú mẹ 1 cữ, 16 phút (02:10).") + Bú mẹ card. The day/night card must compute by type (ml for bottle, minutes for breast).
6. **Navigation:** the screen now sits under the new **Care tab ("Chăm sóc")** in NavBar v1.0.1 (Today · Memories · Care · Family, no Me tab) — see cluster 7. Today the route lives in the Today branch and the dock is Hôm nay · Kỷ niệm · Gia đình · Tôi.
7. New copy strings (vi + en ARB) for every label above; none exist today except the unchanged day/night, hourly and breast cards.
Not designed: Hôm nay / 30 ngày / custom layouts of the new per-day chart; empty states; how pumping relates (no Hút sữa type; "Sữa mẹ vắt" here is bottle-fed expressed milk, not pump sessions).

---

## Cluster 3 — Label 346:47150 (verbatim): "Ghi bú bình: gợi ý lượng sữa theo tuổi + nhớ lần trước"
(Bottle log: suggest milk amounts by age + remember last time.)

### 346:47151 — 22 Ghi bú bình · gợi ý nhanh (Bottle feed sheet with quick picks)
**Frame annotation (verbatim; identical to the original 22, 46:3141):** "Mặc định: Bú bình (nhớ loại lần trước), thời gian = bây giờ, loại sữa nhớ lần trước. Lượng ml không bắt buộc — có thể Lưu ngay (2 chạm). Bàn phím số có dấu phẩy; nút Lưu luôn nằm trên bàn phím."
(Defaults: Bottle (remembers last feed type), time = now, milk type remembers last. ml not required — can Save right away (2 taps). Number pad has a comma; the Save button always sits above the keypad.)

**Background (dimmed by Scrim):** the old 19 Hôm nay — BabySwitcher "Teddy · 3 tuần", Night care toggle, "Thứ Năm, 8 tháng 10", "Hôm nay", 6 CareTiles, ReminderPeek, SectionHeader "Hôm nay" / "Lịch sử", DayRhythm ("Đã ghi hôm nay", "Bú bình 2 cữ · 240 ml", "Bú mẹ 1 cữ · 15 phút", "Ngủ (đã xong) 7 giờ 50", "Thay tã 2 lần"), and the **old** NavBar (Tab/Today "Hôm nay" · Memories · Family · Tab/Me avatar "M"). The background was not updated to the new Care-tab dock; treat it as context only.

**Sheet (Sheet dock 346:47179) — text in reading order**
- SheetHeader: "Ghi cữ bú" (title in care-bottle-ink #1d5f99) · close ✕ ("Đóng").
- Segmented: "Bú bình" (selected) | "Bú mẹ".
- Field label (changed): **"Lượng sữa · đã điền theo lần trước"** (Milk amount · filled in from last time). Old label was "Lượng sữa · tùy chọn".
- AmountField (Focused): "120" "ml" — prefilled with the previous bottle amount.
- **Quick picks (new)**: a row of 4 equal-width pill chips (surface-2, 15 SemiBold value + 12 Medium unit): "60 ml" · "90 ml" · **"120 ml"** (selected: mint-deep / white — matches the field value) · "150 ml".
- **Caption row (new)**, 12 Medium muted:
  - left: Icon/clock + "Lần trước 120 ml · 11:45" (Last time 120 ml · 11:45)
  - right: Icon/cake + "Gợi ý cho bé 3 tuần" (Suggestions for a 3-week-old baby) — i.e. the 4 chip values are an age-based preset for the baby's age in weeks.
- "Loại sữa" (Milk type): FilterChip "Sữa mẹ" (selected) · FilterChip "Sữa công thức".
- TimeRow "Thời gian" · value chip "Bây giờ · 15:05".
- Primary Button "Lưu cữ bú" (Save feed).
- Keypad (11:184) docked below: 1–9, "," and ⌫ — "Decimal pad mock (system keypad in production): digits, decimal comma, backspace."

**Components used:** Scrim, Sheet dock, SheetHeader, Segmented + Segmented/Item, AmountField (State=Focused), local "Quick picks" frame (chips + caption with Icon/clock, Icon/cake), FilterChip ×2, TimeRow, Button (Primary), Keypad.
Relevant component descriptions (verbatim): AmountField 45:403 "Numeric amount (ml, kg, cm, phút) in numeral-xl, tabular figures. Focused = mint-soft + 2px mint-deep. Always optional unless stated." · Segmented 9:124 "Pill segmented control on surface-2 track (pad 5, gap 4). 2–3 short options (Sữa mẹ · Sữa công thức; Ướt · Bẩn · Cả hai). Remembers the last choice as the default." · Icon/cake 22:169 "Line icon (24px, 1.8 stroke) — placeholder; production uses SF Symbols."

**Behaviour (inferred from label + copy):**
- On open, the amount = the last bottle amount for this baby; caption shows that amount and its time.
- Tapping a chip sets the amount (chip turns selected); typing a different value deselects the chips (inferred).
- Chip values come from an age table keyed on the baby's age ("bé 3 tuần" → 60/90/120/150 ml). The table itself (values for other ages) is **not in the design**.
- Save is still allowed with no amount (annotation).

**Notes / not shown**
- No state for a first-ever bottle feed (no "Lần trước" yet) — presumably field empty and the caption shows only the age suggestion.
- No oz unit; ml only.
- Whether the chip set or the "last time" prefill also applies to the Hút sữa (pump) sheet is not shown.

### Compared with the current app (cluster 3)
Current: `FeedSheet` in `apps/mobile/lib/features/care/care_sheets.dart` (opened by `openCareLog(context, CareType.bottle)`), label `amountOptional` "Lượng sữa · tùy chọn", empty `AmountInput`, remembers only feed type and milk type (`CareMemory`, prefs `care.{babyId}.feedType` / `.milk`).
New or different:
1. **Prefill the amount from the last bottle feed** of this baby and change the label to "Lượng sữa · đã điền theo lần trước" (new ARB string). Needs the last bottle record (amount + time) when the sheet opens — available from the records already watched for Today tiles (inferred).
2. **Quick-pick chips** (4 values) under the field; selected chip mirrors the field value.
3. **Age-based suggestion table** (new data/config): chip values per baby age; only "bé 3 tuần → 60 / 90 / 120 / 150 ml" is shown. The full table must be provided by the owner (or `config/limits`), and its wording must stay a suggestion (no medical claim — consistent with the no-inference principle in 28).
4. **Caption row** "Lần trước {ml} ml · {HH:mm}" + "Gợi ý cho bé {age}" (new strings; age uses the baby's age label in weeks).
5. Editing an existing record: not shown; presumably no prefill/caption when editing (inferred).

---

## Cluster 4 — Label 346:47461 (verbatim): "Thống kê ngủ: tổng giờ ngủ mỗi ngày"
(Sleep stats: total sleep hours per day.)

### 346:47462 — 20h Thống kê ngủ · tổng mỗi ngày
(Sleep statistics · total per day). Frame 375x1599, bg cloud #f6fcfb.

**Frame annotation (verbatim)**
"Dòng thời gian mới nhất ở trên, chia theo buổi (Sáng/Trưa/Chiều/Tối). Giấc ngủ và bú mẹ là khối có thời lượng. Chạm mục → Chi tiết bản ghi. Lọc “Tăng trưởng” hiện các lần đo."
(Timeline newest on top, split by part of day (Morning/Noon/Afternoon/Evening). Sleep and breastfeeding are blocks with duration. Tap an item → Record detail. Filter “Growth” shows the measurements.)
→ Copy-pasted from the History/timeline screen (20d); it does not describe this sleep-stats screen.

**Text (reading order)**
Header
- StatusBar "9:41" / "•••" (placeholder)
- Button/Back (no text; a11y label "Quay lại")
- BabySwitcher: "Teddy"
- Title: "Thống kê ngủ" (Sleep statistics)

Segmented (period)
- "Hôm nay" (Today) — unselected
- "7 ngày" (7 days) — SELECTED
- "30 ngày" (30 days) — unselected

KPI tiles (3, white cards r16)
- "14g 20p" (14 h 20 min) / "TB mỗi ngày" (avg per day)
- "6 giấc" (6 sleeps) / "TB mỗi ngày" (avg per day)
- "6g 30p" (6 h 30 min) / "Giấc dài nhất" (longest sleep)

Card 1 "Tổng giờ ngủ mỗi ngày" (Total sleep hours per day) — layer name same
- Subtitle: "Đêm 18:00–06:00 · Ngày 06:00–18:00" (Night 18:00–06:00 · Day 06:00–18:00)
- Tooltip (dark ink pill, white text): "T5 · 14g 30p · đêm 10g · ngày 4g 30p" (Thu · 14 h 30 min · night 10 h · day 4 h 30 min)
- Y axis: "0g", "6g", "12g", "18g" (0h/6h/12h/18h)
- X axis: "T6", "T7", "CN", "T2", "T3", "T4", "T5" (Fri, Sat, Sun, Mon, Tue, Wed, Thu) — "T5" bold ink (selected/today), others muted
- Average line label: "TB 14g 20p" (avg 14 h 20 min) at right end of a dashed line
- Legend: "Ngủ đêm" (Night sleep, colour care-sleep-accent #6c6fd8), "Ngủ ngày" (Day sleep, colour sunshine #ffd166)
- Insight (surface-2 box, Icon/sleep 14px): "Tổng giờ ngủ ổn định quanh 14 giờ/ngày trong 7 ngày qua." (Total sleep stable around 14 hours/day over the past 7 days.)

Card 2 "Ngủ ngày và đêm" (Day and night sleep)
- Subtitle: "Đêm 18:00–06:00 · Ngày 06:00–18:00 · TB 7 ngày" (Night 18:00–06:00 · Day 06:00–18:00 · 7-day average)
- Ratio bar (14px tall, 2px gap): layer "Đêm 64%" (flex 64, #6c6fd8, left rounded) + layer "Ngày 36%" (flex 36, #ffd166, right rounded)
- Legend col 1: swatch purple, "Đêm" (Night) "64%", sub "9 giờ 10 · 2–3 giấc" (9 h 10 · 2–3 sleeps)
- Legend col 2: swatch yellow, "Ngày" (Day) "36%", sub "5 giờ 10 · 3–4 giấc" (5 h 10 · 3–4 sleeps)
- Insight: "Giấc đêm dài nhất tăng từ 3 giờ 30 lên 6 giờ 30 trong 7 ngày." (Longest night sleep rose from 3 h 30 to 6 h 30 over 7 days.)

Card 3 "Nhịp ngủ 7 ngày" (7-day sleep rhythm)
- Subtitle: "Mỗi hàng là một ngày · thanh tím là lúc ngủ" (Each row is one day · purple bar is when asleep)
- Row labels: "T6 2", "T7 3", "CN 4", "T2 5", "T3 6", "T4 7", "T5 8" (weekday + day-of-month; T5 8 is SemiBold ink = today). Consistent with Fri 2 Oct – Thu 8 Oct 2026.
- X axis: "0h", "6h", "12h", "18h", "24h"
- Legend: "Ngủ" (Sleep, #6c6fd8 swatch), "Khung đêm" (Night window, surface-2 #eef6f5 swatch)

Card 4 "Giấc dài nhất mỗi ngày" (Longest sleep each day)
- Subtitle: "Giờ ngủ liền một mạch" (Hours slept in one stretch)
- Y axis: "0g", "4g", "8g"
- X axis: "T6", "T7", "CN", "T2", "T3", "T4", "T5" (T5 SemiBold ink)
- Value labels shown only on first and last bar: "3g30" (above T6), "6g30" (above T5)

Tab dock: active tab label "Chăm sóc" (Care)

**Layout / components**
- StatusBar; Content (px16, pt4, pb120); Row = Button/Back (44px, surface-2) + BabySwitcher (name "Teddy"; desc: "Baby switcher chip: avatar + name (+ chevron when the family has more than one baby). Shows whose log you are viewing.")
- Title Text/title 30/36 SemiBold.
- Segmented (instance 346:47471, 3 Segmented/Item). Component description: "Pill segmented control on surface-2 track (pad 5, gap 4). 2–3 short options (Sữa mẹ · Sữa công thức; Ướt · Bẩn · Cả hai). Remembers the last choice as the default." Item: "One segment. Selected: surface + shadow-card, ink, weight 500. Unselected: transparent, ink-muted. Change animates in duration-quick."
- KPIs: 3 equal flex tiles, gap 8, p12, r16, shadow-card; value 18/26 SemiBold, label 12/16 Medium muted.
- Cards: white, r20, p16, gap 12, shadow-card. Card 1 title 17 SemiBold; cards 2–4 title 17/24 Medium (Text/body-strong). Gaps 16 between blocks.
- TabDock (346:47605) = NavBar "NavBar v1.0.1" + QuickLogButton (mint-deep #087f7b, 68px, Icon/plus). NavBar shows 4 tabs: Tab/Today (icon), Tab/Memories (icon), Tab/Care (ACTIVE: white pill, icon + label "Chăm sóc"), Tab/Family (icon). No "Tôi"/Me tab in this variant. TabDock desc: "Tab dock = NavBar + QuickLogButton, 24px above the home indicator. Swap the nested NavBar variant (Active) per tab." QuickLogButton desc: "Ghi nhanh (+): opens the quick-log chooser (Bú · Ngủ · Tã · Tăng trưởng). 68px, accessibility label “Ghi nhanh”."

**Charts**
Card 1 — stacked bar, chart box 311x206. Gridlines at y=184 (0g), 134 (6g), 84 (12g), 34 (18g), x from 28 to 311 → scale 50px/6h = 8.333 px/h. Bars 22px wide, night (purple, bottom, bottom-rounded 5) under day (yellow, top, top-rounded 5); bars end at y=182 (2px above baseline) so value ≈ (height+2)/8.333 for the night segment. Non-selected bars at opacity 55%; T5 bar full opacity. Derived (approx.):
| Day | Night h (px) | Night ≈ | Day h (px) | Day ≈ | Total ≈ |
|---|---|---|---|---|---|
| T6 | 73 | 9.0 h | 41.667 | 5.0 h | 14.0 h |
| T7 | 77.167 | 9.5 h | 37.5 | 4.5 h | 14.0 h |
| CN | 68.833 | 8.5 h | 45.833 | 5.5 h | 14.0 h |
| T2 | 81.333 | 10.0 h | 33.333 | 4.0 h | 14.0 h |
| T3 | 73 | 9.0 h | 41.667 | 5.0 h | 14.0 h |
| T4 | 77.167 | 9.5 h | 41.667 | 5.0 h | 14.5 h |
| T5 | 81.333 | 10.0 h | 37.5 | 4.5 h | 14.5 h (matches tooltip 14g30p · đêm 10g · ngày 4g30p) |
- Dashed average line at y=64.58 → (184−64.58)/8.333 ≈ 14.33 h = 14g20p, labelled "TB 14g 20p" (SemiBold 10px muted, right end).
- Tooltip anchored at top of chart (x=91, y=0), dark ink #173d44 bg, r10.

Card 2 — single 100% ratio bar: Đêm 64 / Ngày 36.

Card 3 — "Nhịp ngủ" 24h timeline, one row per day (rows 14px tall, pitch 22px). Bar layer names carry the hour ranges (decimal hours):
- T6 2: 0–3.5, 4.5–7, 9–10.5, 12–13.5, 15–16.5, 19–21, 22–24 (7 segments, sum 14.5 h)
- T7 3: 0–3, 3.8–6.8, 9.5–11, 12.5–14.5, 16–17, 19.5–21.5, 22.3–24 (7 seg, sum 14.2 h)
- CN 4: 0–4, 4.7–7.2, 9–10.8, 13–14.5, 16.2–17.3, 20–24 (6 seg, sum 14.6 h)
- T2 5: 0–4.2, 5–7, 9.3–11, 12.8–14.4, 16–17, 20.5–24 (6 seg, sum 14.0 h)
- T3 6: 0–5, 5.6–7.3, 9.5–11.2, 13–14.8, 16.5–17.4, 21–24 (6 seg, sum 14.9 h)
- T4 7: 0–5.5, 6–7.5, 9.2–11, 13.2–15, 16.8–17.6, 21.7–24 (6 seg, sum 14.9 h)
- T5 8 (today): 0–6.5, 11.75–13.08 (i.e. 00:00–06:30, 11:45–13:05), then layer "Bây giờ" (Now: 2px×22px ink vertical line) at x≈209 → ≈15:05 (approx., scale ≈11.2 px/h from 0h at x≈40), then layer "Chưa tới" (Not yet: separator-grey bar, 50% opacity, from now to 24h).
- Background bands (layer "Đêm", surface-2 #eef6f5, full height of the 7 rows): 0–6h and 18–24h = the "Khung đêm" (night window).
Card 4 — vertical bars, chart 130px tall; gridlines y=100 (0g), 54 (4g), 8 (8g) → 11.5 px/h. Bar layer names hold values: "T6 · 3.5 giờ", "T7 · 3 giờ", "CN · 4 giờ", "T2 · 4.2 giờ", "T3 · 5 giờ", "T4 · 5.5 giờ", "T5 · 6.5 giờ" (heights 40.25/34.5/46/48.3/57.5/63.25/74.75 confirm). Bars 20px wide, top-rounded 4, colour care-sleep-accent #6c6fd8; T5 (today) darker care-sleep-ink #4447a8.


**States / controls**
- Segmented Hôm nay / 7 ngày / 30 ngày: switches the period; only "7 ngày" is designed. "Hôm nay" and "30 ngày" states not shown (inferred: same cards with 1/30 data points).
- Card 1 bar selection: T5 shown selected (full opacity, bold label, tooltip). Inferred: tap a bar → tooltip for that day; other bars dim to 55%.
- Back → returns to previous screen (inferred: Care / sleep log). BabySwitcher → switch baby (no chevron shown in this mock? The component has an Icon node; screenshot shows a small chevron next to "Teddy").
- QuickLogButton opens quick-log chooser (per component description).

**Notes / not shown**
- Annotation is copy-pasted from the History screen (20d), not specific to this screen.
- KPI "14g 20p TB mỗi ngày" vs card-1 bars: bars sum to 14,14,14,14,14,14.5,14.5 → mean ≈ 14.14 h (14g 08p), not 14g 20p. The dashed line is drawn at 14g20p.
- Card 2 "9 giờ 10" + "5 giờ 10" = 14 h 20 (consistent with KPI; 9.17/14.33 = 64%). But the card-1 bars average night ≈ 9.36 h (9g21p) and day ≈ 4.79 h (4g47p) — mismatch.
- Rhythm rows sum to 14.0–14.9 h per day, not matching card-1 totals exactly (e.g. T6 14.5 vs 14.0; T3 14.9 vs 14.0).
- Night split from the rhythm data for T6: night (18–06) ≈ 9.0 h, day ≈ 5.5 h — card 1 says day 5.0 h.
- Longest-sleep card splits sleeps at midnight (e.g. T6 22–24 + T7 0–3 is one 5 h stretch; CN 20–24 + T2 0–4.2 is 8.2 h) but the card shows 3 h and 4.2 h. Design does not define how a sleep spanning midnight is attributed (start day? split?). KPI "Giấc dài nhất 6g 30p" = max of card-4 values (T5 0–6.5).
- KPI "6 giấc TB mỗi ngày": rhythm rows have 7,7,6,6,6,6 segments (+2 so far today) — counting rule (cross-midnight sleeps counted once or twice? does today's partial day count?) undefined.
- "2–3 giấc" night / "3–4 giấc" day: range rule undefined.
- Card 2 uses "giờ" format ("9 giờ 10") while card 1/KPIs use "14g 20p" — two duration formats on one screen.
- Insight copy rules (when to show which insight; thresholds for "ổn định") are not defined.
- Night window 18:00–06:00 is fixed in copy; not stated whether configurable.
- "Hôm nay"/"30 ngày" layouts, empty state (no sleep logged), and loading are not shown. Night (dark) care theme not shown.
- 30-day x-axis labelling undefined.

### Compared with the current app (cluster 4)
Current: `SleepStatsScreen` in `apps/mobile/lib/features/care/stats_screens.dart` (route `/today/stats/sleep`, from History "Ngủ" filter via "Xem thống kê ngủ"), maths in `care_calc.dart` `sleepStats()` returning `SleepDayRow{start, bars, longest, total}`; segmented Hôm nay / 7 ngày / 30 ngày saved in prefs `stats.sleep.window`. Already has the 3 KPIs, "Ngủ ngày và đêm", "Nhịp ngủ {days} ngày" and "Giấc dài nhất mỗi ngày".
New or different:
1. **New first card "Tổng giờ ngủ mỗi ngày"**: stacked bars per day (night 18:00–06:00 purple at the bottom, day 06:00–18:00 yellow on top), Y axis "0g/6g/12g/18g", dashed average line "TB 14g 20p", selectable bar with tooltip "T5 · 14g 30p · đêm 10g · ngày 4g 30p" (non-selected bars at 55% opacity), legend "Ngủ đêm" / "Ngủ ngày", and an insight "Tổng giờ ngủ ổn định quanh 14 giờ/ngày trong 7 ngày qua." `SleepDayRow.total` is computed today but never drawn; the card also needs a **per-day night/day split** (night window 18–06 attributed to which calendar day — not defined) and bar tap handling.
2. New insight copy and its rule ("ổn định quanh N giờ/ngày") — threshold for "stable" is not defined; owner must supply (or pick a neutral wording).
3. Unchanged: the segmented control stays here (unlike feeding stats, which moved to dropdown pills); the other three cards are unchanged from the original 20h.
4. Tab dock: same NavBar v1.0.1 with "Chăm sóc" active (cluster 7).
5. New strings: card title/subtitle, legend "Ngủ đêm"/"Ngủ ngày", tooltip format, average label, insight.

---

## Cluster 5 — Label 346:47705 (verbatim): "Tăng trưởng: tập trung tab đã chọn · so sánh chuẩn WHO · thêm chiều dài"
(Growth: focus on the selected tab · compare with the WHO standard · add length.)

Reading of the label against the frames: "tập trung tab đã chọn" = the growth card shows only the selected measure (Cân nặng or Chiều dài: headline, chips and chart all switch; the other measure is no longer shown as a muted secondary value); "so sánh chuẩn WHO" = normal-range band + WHO median on the chart, a status chip, and a new WHO table screen (20i); "thêm chiều dài" = a full Chiều dài variant of the card and chart (346:47899).

### 346:47706 — 20d Tăng trưởng · Cân nặng
(Growth · Weight). Frame 375x1117. This is the History screen ("Lịch sử") with filter "Tăng trưởng" selected.

**Frame annotation (verbatim)**
"Dòng thời gian mới nhất ở trên, chia theo buổi (Sáng/Trưa/Chiều/Tối). Giấc ngủ và bú mẹ là khối có thời lượng. Chạm mục → Chi tiết bản ghi. Lọc “Tăng trưởng” hiện các lần đo."
(Timeline newest on top, split by part of day (Morning/Noon/Afternoon/Evening). Sleep and breastfeeding are blocks with duration. Tap an item → Record detail. Filter “Growth” shows the measurements.)
→ Same annotation as the generic History screen; only the last sentence applies here.

**Text (reading order)**
Header
- StatusBar "9:41" "•••"; Button/Back; BabySwitcher "Teddy" (with chevron)
- Title: "Lịch sử" (History) — Text/large-title 32/40
- Month picker pill (white, separator border): "Tháng 10" (October) + Icon/chevron-down

Filters (FilterChip row, horizontally scrolled — first chips are off-screen to the left in the mock)
- "Tất cả" (All; default label, off-screen at x=-185) · "Bú" (Feed; off-screen) · "Hút sữa" (Pumping; partially visible "...t sữa") · "Ngủ" (Sleep) · "Tã" (Diaper) · "Tăng trưởng" (Growth) — SELECTED (mint-deep)

Growth card (white r20 p16 gap12, layer "Growth")
- Segmented (custom, not the Segmented component: surface-2 track r14 p4 gap2; items r10): "Cân nặng" (Weight) — SELECTED (white, SemiBold ink) · "Chiều dài" (Length) — unselected (Medium, ink-muted)
- Value row: "4,3 kg" (Bold 28) + "· 3 tuần tuổi" (· 3 weeks old, 13 Medium muted)
- Status chips:
  - "Bình thường" (Normal) — mint-soft #e6f7f5 bg, Icon/check 14, mint-text #06716d
  - "+0,4 kg so với 1 thg 10" (+0.4 kg vs 1 Oct) — care-growth-soft #fdede2 bg, care-growth-ink #9a4a14
- Chart Y labels: "2 kg", "4 kg", "6 kg"
- Chart X labels: "Sinh" (Birth), "1 tuần", "2 tuần", "3 tuần", "4 tuần", "5 tuần" (1–5 weeks)
- Legend: "Khoảng bình thường" (Normal range; mint-soft swatch 14x10), "Trung vị WHO" (WHO median; mint-text 14x2 line), "Teddy" (baby name; care-growth-accent #e8894a swatch)
- Link row (surface-2 r14 p12): Icon/ruler + "Xem tiêu chuẩn tăng trưởng WHO" (View WHO growth standards; SemiBold 14 mint-text) + Icon/chevron-right

List
- SectionHeader title "Các lần đo" (Measurements), showLink=false
- TimelineItem 1: time col "8 thg 10" (8 Oct; clipped to "8 thg 1" in the 44px column in the screenshot); title "4,3 kg · 54,5 cm"; sub "+0,4 kg · +1,5 cm · Mẹ ghi" (+0.4 kg · +1.5 cm · logged by Mum)
- TimelineItem 2: "1 thg 10" (1 Oct; clipped "1 thg 1("); "3,9 kg · 53 cm"; "+0,7 kg · +3 cm · Mẹ ghi"
- TimelineItem 3: "17 thg 9" (17 Sep; clipped "17 thg"); "3,2 kg · 50 cm"; "Lúc sinh · Ba ghi" (At birth · logged by Dad); no rail line (last item)
- Markers: 40px care-growth-soft circle with growth mini-illustration (Illustration/Mini/Ruler — yellow ruler)

Button: "Thêm số đo" (Add measurement) — mint-soft bg, Icon/plus 18, mint-text label, h56, full width (Tinted variant)

TabDock: active "Chăm sóc" (Care)

**Layout / components**
- FilterChip desc: "Single-select filter chip (h40). Selected = mint-deep / on-mint-deep. Row scrolls horizontally; last chip may peek to signal more."
- SectionHeader desc: "Section header: headline title + optional mint-text link. space-6 above, space-2 below." (used with title "Các lần đo", link hidden)
- TimelineItem desc: "Day timeline entry: time column (tabular), rail with category marker, content. Event = point in time (feed, diaper, growth). Span = something with a duration (sleep, breastfeed) shown as a block with a duration bar. Pending = saved on device, waiting to sync. Turn off the line on the last item. Category variant colours the marker, span block and bar with care/<type> tokens. Marker is 40px and holds the care type art (Illustration/Mini/*) via the Icon property."
- Illustration/Mini/Ruler desc: "Small 3D-style object for tracker tiles (fixed colours)."
- Button desc: "Pill button, label = 1–2-word verb (Lưu, Bắt đầu, Kết thúc, Chỉnh giờ, Mời, Thử lại). Primary h56 mint-deep/on-mint-deep, one per screen in the thumb zone. Secondary h52 surface-2. Tinted for secondary actions. Plain for text buttons (≥44 tap). Apple: use Apple’s official button in production. Press: scale 0.97 in duration-tap. Disabled: opacity 40%. Stretch to fill width for block buttons." — here: tinted (mint-soft) block button "Thêm số đo".
- BabySwitcher, Button/Back, QuickLogButton, TabDock descriptions as in 20h. NavBar "NavBar v1.0.1": Today, Memories, Care (ACTIVE, label "Chăm sóc"), Family — 4 tabs, no Me tab.
- Gaps: 8 under header row, 16 after title, 16 after filters, 24 before SectionHeader, 16 before button; content pb120.

**Chart (Growth chart 311x202)**
- Gridlines: y=180 (2 kg), y=104.44 (4 kg), y=28.89 (6 kg) → 37.78 px/kg; plot x from 34 to 303 (269px) for Birth→5 weeks → 53.8 px/week.
- "Khoảng bình thường" band (Vector 346:47844, filled mint-soft, widening to the right): bbox y 32.67–161.07, x 34–303 → lower edge at birth ≈ 2.5 kg, upper edge at 5 weeks ≈ 5.9 kg (approx.; matches the 20i table "Thấp" at Mới sinh = 2,5 and "Cao" at 5 tuần = 5,9). In the screenshot the band rises from ≈2.5–4.3 kg at birth to ≈3.6–5.9 kg at 5 weeks (approx., consistent with table rows).
- "Trung vị WHO" line (Vector 346:47845, dashed dark green mint-text): bbox y 78–130.9 → ≈3.3 kg at birth to ≈4.7 kg at 5 weeks (matches table median 3,3 → 4,7).
- "Teddy" line (Vector 346:47846, solid orange #e8894a), x 34–195.4 (birth → 3 weeks). Points:
  - Ellipse 8px, centre (34, 134.67) → Birth, ≈3.2 kg (= 17 thg 9 entry 3,2 kg) — hollow/white-filled with orange stroke
  - Ellipse 8px, centre (141.6, 108.22) → 2 weeks, ≈3.9 kg (= 1 thg 10 entry) — hollow
  - Ellipse 12px, centre (195.4, 93.11) → 3 weeks, ≈4.3 kg (= 8 thg 10 latest) — larger, solid orange (latest highlighted)
- X axis is age in weeks since birth (17 Sep → 1 Oct = 2 weeks; → 8 Oct = 3 weeks); chart shows birth to 5 weeks (forward window of 2 weeks beyond latest).


**States / controls**
- Filter "Tăng trưởng" selected → replaces timeline with Growth card + "Các lần đo" list (per annotation "Lọc “Tăng trưởng” hiện các lần đo").
- Segmented "Cân nặng" selected (this frame); "Chiều dài" → frame 346:47899.
- "Xem tiêu chuẩn tăng trưởng WHO" → opens 20i Tiêu chuẩn tăng trưởng WHO (347:806) (inferred from label + page label "so sánh chuẩn WHO").
- Measurement row tap → Record detail (per annotation "Chạm mục → Chi tiết bản ghi"; inferred applies to growth items).
- "Thêm số đo" → growth log sheet (inferred; same as QuickLog "Tăng trưởng").
- Month picker "Tháng 10" → choose month (inferred). BabySwitcher → switch baby.
- Status chip "Bình thường" — alternative state "Dưới mức tham chiếu" shown in 347:935.

**Notes / not shown**
- Annotation copy is the generic History one.
- Month picker "Tháng 10" yet the list includes "17 thg 9" (September) — unclear whether growth filter ignores month scoping or shows all-time measurements.
- Time column (44px) truncates "8 thg 10"/"1 thg 10"/"17 thg 9" in the screenshot — layout bug in design; dates do not fit.
- Delta chip "+0,4 kg so với 1 thg 10" compares to the previous measurement (inferred rule); behaviour with no previous measurement (only birth) is undefined.
- Age label "3 tuần tuổi" (weeks); when the unit switches to months (see 347:935 "· 7 tháng") is not specified here (20i has a "Theo tuần / Theo tháng" toggle).
- Status thresholds ("Bình thường" = within Thấp–Cao band) inferred from legend/20i; exact percentiles not stated on this screen.
- Chart x-range rule (how far ahead to extend, when to switch to months) undefined. Sex used for the WHO band is not shown on this screen (20i has Bé trai/Bé gái).
- Who-logged suffix ("Mẹ ghi"/"Ba ghi") uses the family role name.
- Empty state (no measurements), single measurement, and Night care theme not shown.

---

### 346:47899 — 20d Tăng trưởng · Chiều dài
(Growth · Length). Frame 375x1117. Identical to 346:47706 except the Growth card is on the "Chiều dài" segment.

**Frame annotation (verbatim)** same generic History annotation as 346:47706:
"Dòng thời gian mới nhất ở trên, chia theo buổi (Sáng/Trưa/Chiều/Tối). Giấc ngủ và bú mẹ là khối có thời lượng. Chạm mục → Chi tiết bản ghi. Lọc “Tăng trưởng” hiện các lần đo." (copy-pasted; only last sentence relevant).

**Text (reading order)**
- Header, title "Lịch sử", month picker "Tháng 10", filter chips (Tất cả · Bú · Hút sữa · Ngủ · Tã · **Tăng trưởng** selected) — identical to 346:47706.
- Growth card:
  - Segmented: "Cân nặng" (Weight) unselected (Medium muted) · "Chiều dài" (Length) SELECTED (white, SemiBold ink)
  - Value: "54,5 cm" + "· 3 tuần tuổi" (· 3 weeks old)
  - Chips: "Bình thường" (Normal; check icon, mint) · "+1,5 cm so với 1 thg 10" (+1.5 cm vs 1 Oct; growth-soft/ink)
  - Y labels: "45", "50", "55", "60" (no unit on the axis, unlike weight "2 kg"/"4 kg"/"6 kg")
  - X labels: "Sinh", "1 tuần", "2 tuần", "3 tuần", "4 tuần", "5 tuần"
  - Legend: "Khoảng bình thường" · "Trung vị WHO" · "Teddy"
  - Link: "Xem tiêu chuẩn tăng trưởng WHO" (+ ruler icon, chevron-right)
- "Các lần đo" list — identical to weight frame (both values per row): "8 thg 10" "4,3 kg · 54,5 cm" "+0,4 kg · +1,5 cm · Mẹ ghi"; "1 thg 10" "3,9 kg · 53 cm" "+0,7 kg · +3 cm · Mẹ ghi"; "17 thg 9" "3,2 kg · 50 cm" "Lúc sinh · Ba ghi".
- Button "Thêm số đo"; TabDock active "Chăm sóc".

**Layout / components** — same as 346:47706 (FilterChip, SectionHeader showLink=false, TimelineItem ×3 growth variant, tinted Button, TabDock NavBar v1.0.1 with Today/Memories/Care(active)/Family).

**Chart (311x202)**
- Gridlines: y=180 (45), 123.33 (50), 66.67 (55), 10 (60) → 11.33 px/cm; x: birth at 34, 53.8 px/week.
- Band "Khoảng bình thường" (Vector 346:48039, mint-soft fill): bbox y 22.47–165.27 → lower edge at birth ≈ 46.3 cm, upper edge at 5 weeks ≈ 58.9 cm (approx.).
- "Trung vị WHO" dashed line (Vector 346:48040): bbox y 63.27–124.47 → ≈49.9 cm at birth to ≈55.3 cm at 5 weeks (approx.).
- Teddy line (Vector 346:48041, orange, x 34–195.4). Points: birth (34,123.33) ≈ 50.0 cm (hollow 8px); 2 weeks (141.6, 89.33) ≈ 53.0 cm (hollow 8px); 3 weeks (195.4, 72.33) ≈ 54.5 cm (solid 12px, latest). Matches list values.
- Visual: same mint-soft band (light teal) widening to the right, dark-green dashed median, orange Teddy polyline with white-filled small points and a bigger filled latest point; Teddy sits above the median.

**WHO table** — n/a here (see 20i; 20i in the design only shows a weight table, no length table values).

**States / controls** — as 346:47706; tapping "Cân nặng" returns to the weight frame; link opens 20i (inferred), which presumably opens on the "Chiều dài" tab when coming from here (inferred; not specified).

**Notes / not shown**
- Y axis labels have no unit ("45"…"60") whereas weight labels include "kg" — inconsistency.
- Length band/median values have no source table in the file (20i only shows the weight table with "Cân nặng" selected) — the length reference values (Thấp/Trung vị/Cao per week) are not specified anywhere; engineering must source them from WHO length-for-age.
- Delta "+1,5 cm so với 1 thg 10" = 54,5 − 53 ✓. List row deltas: 53 − 50 = +3 cm ✓; 3,9 − 3,2 = +0,7 kg ✓; 4,3 − 3,9 = +0,4 kg ✓.
- Measurement where only weight OR only length is logged: row/chip format undefined.
- Head circumference not present (only weight and length in V1 design).
- Same time-column truncation issue as the weight frame.

---

### 347:806 — 20i Tiêu chuẩn tăng trưởng WHO
(WHO growth standards). Frame 375x1000, r40, bg cloud. Content pt52 px16 gap14 pb120.

**Frame annotation** none (no data-annotations on the frame or children).

**Text (reading order)**
Header (custom "Top" row, NOT Button/Back component)
- StatusBar "9:41" "•••"
- back: white circle (p8) with Icon/back 20px (no label)
- BabySwitcher "Teddy" (with chevron)

Title & intro
- "Tiêu chuẩn tăng trưởng" (Growth standards) — Bold 28
- "Theo bảng chuẩn tăng trưởng trẻ em của WHO. Mỗi bé lớn theo nhịp riêng." (Based on the WHO child growth standards table. Every baby grows at their own pace.) — Medium 14 muted, lh 1.45

Segmented (custom, same style as 20d: surface-2 track r14 p4)
- "Cân nặng" (Weight) — SELECTED (white, SemiBold ink)
- "Chiều dài" (Length) — unselected

Options row ("opts")
- "Bé trai" (Boy) — SELECTED: ink #173d44 fill, white Icon/check 14 + white SemiBold 13 text
- "Bé gái" (Girl) — unselected: white with separator border, ink text
- spacer
- "Theo tuần" (By week) — SELECTED: mint-soft #e6f7f5 fill, mint-text #06716d
- "Theo tháng" (By month) — unselected: white with separator border (in the screenshot this chip overflows/clips past the right edge of the 375 frame)

Table (white card r18, rows px14 py12; column widths 92 / 76 / 76 / 70; numeric columns right-aligned)
Header row (surface-2 bg): "Tuổi" (Age; 14 Medium muted) | "Thấp" (Low; 12 Medium muted) | "Trung vị" (Median; 12 SemiBold muted) | "Cao" (High; 12 Medium muted)

| Tuổi (Age) | Thấp (Low) | Trung vị (Median) | Cao (High) |
|---|---|---|---|
| Mới sinh (Newborn) | 2,5 | 3,3 | 4,3 |
| 1 tuần (1 week) | 2,6 | 3,5 | 4,5 |
| 2 tuần (2 weeks) | 2,8 | 3,8 | 4,9 |
| 3 tuần (3 weeks) — HIGHLIGHTED row (mint-soft bg; age label SemiBold) | 3,1 | 4,1 | 5,2 |
| 4 tuần (4 weeks) | 3,4 | 4,4 | 5,6 |
| 5 tuần (5 weeks) | 3,6 | 4,7 | 5,9 |
| 6 tuần (6 weeks) | 3,8 | 4,9 | 6,2 |

- Styling: age column 14 Medium ink; Thấp/Cao 14 Medium ink-muted; Trung vị 14 SemiBold ink (bold-looking in the screenshot).
- Under the highlighted 3-week row, inside the same mint-soft band (layer "you"): white pill chip with Icon/check (mint) + "Teddy 4,3 kg · Bình thường" (Teddy 4.3 kg · Normal; SemiBold 12 mint-text). Layer name = same text.
- 7 data rows total (Mới sinh → 6 tuần); no more rows below 6 tuần in the frame.

Footnotes / disclaimers (verbatim)
- "Đơn vị: kg. “Thấp” và “Cao” là ngưỡng dưới và ngưỡng trên của khoảng bình thường." (Unit: kg. “Low” and “High” are the lower and upper thresholds of the normal range.) — 12 Medium muted
- Banner (surface-2 r14, Icon/heart 16): "Nếu số đo của bé nằm ngoài khoảng bình thường, hãy trao đổi với bác sĩ của bé." (If your baby's measurement falls outside the normal range, talk to your baby's doctor.) — 13 Medium muted
- Source line: "Nguồn: WHO Child Growth Standards · Child Life cập nhật 09/2026" (Source: WHO Child Growth Standards · Child Life updated 09/2026) — 12 Medium muted

**Layout / components**
- Not using Button/Back or TabDock: custom white back circle; NO tab dock on this screen (pushed detail screen; inferred full-screen push).
- BabySwitcher desc: "Baby switcher chip: avatar + name (+ chevron when the family has more than one baby). Shows whose log you are viewing."
- Icon/heart, Icon/check: generic line-icon descriptions ("placeholder drawing; production uses SF Symbols").
- Option chips are ad-hoc frames (not FilterChip component): two single-select pairs — sex (Bé trai/Bé gái, ink-filled when selected) and granularity (Theo tuần/Theo tháng, mint-soft when selected) — note the two pairs use DIFFERENT selected styles.

**Charts** none (table only).

**WHO table — verification against WHO weight-for-age (boys) LMS, checked during extraction against the WHO weight-for-age LMS tables (not part of the design)**
- "Trung vị" = WHO boys median (3.3, 3.5, 3.8, 4.1, 4.4, 4.7, 4.9) ✓ all rows.
- "Thấp" = WHO boys P3 (2.5, 2.6, 2.8, 3.1, 3.4, 3.6, 3.8) ✓ all rows (−2 SD would give 3.3 at 4 wk and 3.5 at 5 wk, so the design uses P3, not −2 SD).
- "Cao" = WHO boys P97 (4.3, 4.5, 4.9, 5.2, 5.6, 5.9, 6.25→ design shows 6,2) ✓ (+2 SD would give 4.4/4.6/…). 6-week P97 = 6.252 → design rounds down to 6,2 (round-half-up gives 6,3).
- So "khoảng bình thường" (normal range) ≈ P3–P97 (inferred; the design never names the percentiles).
- The 20d chart bands also match: weight band 2.5→5.9, median 3.3→4.7; length band lower 46.3 (= boys P3 at birth) → upper ≈ 58.9 (≈ P97 59.0 at 5 wk), median 49.9→55.3 (= boys median).

**States / controls**
- Segmented Cân nặng / Chiều dài: only Cân nặng designed; Chiều dài table (cm) NOT shown.
- Bé trai / Bé gái: only Bé trai designed (presumably pre-selected from the baby's sex; inferred). Girl values not shown.
- Theo tuần / Theo tháng: only Theo tuần designed; monthly table not shown.
- Highlighted row = the baby's current age (3 tuần) with the baby's latest measurement chip (inferred rule).
- Back → returns to 20d growth card (inferred).
- BabySwitcher → switch baby (inferred: table re-highlights for that baby).

**Notes / not shown**
- No frame annotation.
- Only 7 weekly rows (0–6 weeks); range covered by "Theo tuần" (WHO weekly tables go to 13 weeks) and by "Theo tháng" (0–24/60 months?) is undefined. Scrolling behaviour of a long table undefined.
- Length table, girl table, monthly table — not designed; footnote "Đơn vị: kg." must change to cm for length (copy not given).
- Status chip shows "Bình thường" only; the in-table chip for an out-of-range value is not designed (see 347:935 for the out-of-range wording on the growth card).
- Rule for matching a measurement to a row (exact age in days vs nearest week; measurement date vs today) is not defined — Teddy measured 8 Oct at 21 days = exactly 3 weeks here.
- Rounding rule (6.25 → 6,2) inconsistent with standard rounding; engineering should decide (round-half-up or show WHO-published table values).
- "Child Life cập nhật 09/2026" — data-version date hard-coded in copy.
- "Theo tháng" chip clipped at the right edge — options row overflows at 375 px width.
- Medical disclaimer wording present (banner); no link to a source URL.

---

### 347:935 — 20d Tăng trưởng · Dưới mức tham chiếu
(Growth · Below reference range). Frame 375x812, r40, bg cloud. A different baby ("Na", 7 months). Shows ONLY the growth card (no filters, no chart, no list, no tab dock) — a state variant of the Growth card.

**Frame annotation** none.

**Text (reading order)**
Header (custom "Top" row like 20i)
- StatusBar "9:41" "•••"
- back: white circle p8 with Icon/back 20px
- Baby chip (custom, layer "b", NOT the BabySwitcher component — no avatar): "Na" (SemiBold 15) + Icon/chevron-down 14, white pill
- Title: "Lịch sử" (History) — Bold 28 (differs from 20d's Text/large-title SemiBold 32 and has no Month picker)

Growth card (white r20, px16 py14, gap 12)
- Segmented: "Cân nặng" (Weight) SELECTED · "Chiều dài" (Length)
- Value: "6,1 kg" (Bold 28) + "· 7 tháng" (· 7 months; Medium 13 muted) — note: "7 tháng", not "7 tháng tuổi" (20d uses "3 tuần tuổi")
- Status chips:
  - "Dưới mức tham chiếu" (Below reference range) — sunshine-soft #fff4d6 bg, Icon/alert 14, ink SemiBold 12
  - "Ngưỡng dưới 6,4 kg" (Lower threshold 6.4 kg) — surface-2 bg, ink SemiBold 12
- Banner (sunshine-soft #fff4d6, r14, Icon/heart 16): "Cân nặng của Na đang thấp hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới." (Na's weight is currently lower than the range commonly seen at this age. Every baby grows at their own pace — you should talk to the doctor at the next check-up.) — Medium 13 ink
- Link row: Icon/ruler + "Xem tiêu chuẩn tăng trưởng WHO" (View WHO growth standards) + Icon/chevron-right

**Layout / components**
- Only Icon components (Icon/back, Icon/chevron-down, Icon/alert, Icon/heart, Icon/ruler, Icon/chevron-right) — descriptions all the generic line-icon text ("placeholder drawing; production uses SF Symbols. Recolour by overriding the stroke with a text-colour token.").
- Out-of-range tone = sunshine-soft (warm yellow) chip + banner; NO red/error colour; alert icon in ink. In-range tone (20d) = mint-soft chip with check icon + growth-soft delta chip.
- In the out-of-range state the delta chip ("+x so với …") is REPLACED by the threshold chip "Ngưỡng dưới 6,4 kg", and the chart + legend are NOT shown (banner sits where the chart would be) — either intentionally hidden or the frame is a cropped snippet (unclear).

**Charts** none in this frame.

**WHO table** n/a. Engineering check against WHO weight-for-age (WHO weight-for-age LMS tables, not in the design): girl at 7 months (213 d) P3 ≈ 6.09 kg, −2 SD ≈ 6.01; boy P3 ≈ 6.74. "Ngưỡng dưới 6,4 kg" matches neither for exactly 7 months (girl P3 reaches ≈6.34 only at ~8 months / 243 d). Sample number appears illustrative, not WHO-derived. Na's sex is not shown.

**States / controls**
- State shown: weight below lower threshold ("Dưới mức tham chiếu"). Implied counterpart for above upper threshold (e.g. "Trên mức tham chiếu" / "Ngưỡng trên … kg") — NOT designed.
- Link → 20i WHO standards (inferred). Baby chip "Na ▾" → switch baby (inferred; multi-baby family because chevron shown).
- Back → previous screen (inferred).

**Notes / not shown**
- No annotation. Frame is a partial/state mock: lacks filters, month picker, chart, measurement list, "Thêm số đo" button and TabDock present in 346:47706 — whether those remain in the real screen is undefined (most likely yes; inferred).
- Header uses a different baby chip (no avatar, white) and a different title style than the 20d frames — inconsistent with BabySwitcher component.
- "· 7 tháng" — age unit switches from weeks to months; switch-over age not defined (also "tháng" vs "tháng tuổi" wording).
- Above-range state, length-below-range wording ("Chiều dài của … đang thấp hơn …"), and case with both weight and length out of range not designed.
- Threshold source: 20i defines Thấp/Cao as range bounds; the 6,4 kg value here is inconsistent with WHO P3/−2SD at 7 months for either sex (see §5).
- Banner copy is advisory ("trao đổi với bác sĩ ở lần khám tới"); no CTA button, no dismiss.
- Night care theme not shown.

### Compared with the current app (cluster 5)
Committed code: growth entry `GrowthScreen` (`apps/mobile/lib/features/care/care_screens.dart`, route `/care/growth`) and the History growth panel `_GrowthPanel` / `_MiniToggle` / `_GrowthLinePainter` (`history_screen.dart`, `/today/history?filter=growth`) — summary card with "Gần nhất · {when}", Cân nặng | Chiều dài toggle, primary + muted secondary value, delta chip "{delta} so với {date}", time-proportional line chart with date labels; code comment and R-056 say "no percentiles". The working tree also has **uncommitted, in-progress** files `who_growth.dart` (LMS interpolation, `range()`, `zScore()`, `band()` → below/normal/above, week 0–13 / month table), `who_growth_data.g.dart`, `growth_chart.dart`, `growth_standards_screen.dart` and ARB keys `whoIntro`… / `whoStandardsTitle`, so part of this cluster is being built now.
New or different versus the committed app:
1. **Product-rule change:** the original 28/20d rule "không bách phân vị, không đánh giá tốt/xấu" (R-056) is reversed in part: the card now shows a status chip "Bình thường" / "Dưới mức tham chiếu" and a WHO band. Business-map R-056 needs an owner decision recorded (new D-xxx) before shipping, plus the medical-disclaimer copy shown here.
2. **Card focus:** headline shows only the selected measure + age ("4,3 kg · 3 tuần tuổi" / "54,5 cm · 3 tuần tuổi"); the current muted secondary value is dropped; label "Gần nhất · {when}" is not shown on the new card.
3. **Chart:** X axis becomes **age** ("Sinh, 1 tuần … 5 tuần"), not measurement dates; extends ~2 weeks past the latest point; adds mint "Khoảng bình thường" band (WHO P3–P97 per 20i) and dashed "Trung vị WHO" line; Teddy line orange with hollow earlier points and a filled latest point; legend with baby name. Needs baby **sex** (`babyPrivateProfileProvider.gender`; "unspecified" case not designed) and DOB.
4. **Chips:** status chip (mint + check for normal; sunshine-soft + alert for below, with a second chip "Ngưỡng dưới {x} kg" replacing the delta chip) and the delta chip "+0,4 kg so với 1 thg 10". Above-range state ("Trên mức tham chiếu") not designed.
5. **New screen 20i "Tiêu chuẩn tăng trưởng"** (from the link row "Xem tiêu chuẩn tăng trưởng WHO"): measure toggle, Bé trai/Bé gái, Theo tuần/Theo tháng, table Tuổi | Thấp | Trung vị | Cao with the baby's current age row highlighted and the chip "{name} {value} · Bình thường", unit footnote, doctor banner and source line "Nguồn: WHO Child Growth Standards · Child Life cập nhật 09/2026". Full-screen push without tab dock. Requires bundled WHO weight-for-age and length-for-age tables for both sexes (weekly 0–13 w, monthly) and a rounding rule (design shows P97 6.252 as "6,2").
6. **Below-reference banner** (sunshine-soft, heart icon): "Cân nặng của {name} đang thấp hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới." Length wording and both-out-of-range wording not designed.
7. **List** "Các lần đo" and "Thêm số đo" are unchanged in substance; the 44px date column truncation bug carries over.
8. **Navigation:** History now shows the Care-tab dock ("Chăm sóc" active) — growth history lives under the Care tab.
9. Growth entry screen 28 itself is not redrawn on this page (no change shown).

---

## Cluster 6 — Label 368:836 (verbatim): "Onboarding · cài app lần đầu"
(Onboarding · first install of the app.)

Flow (frame order; arrows inferred unless stated): 00 Splash (≤1 s, stated) → 01 Chào mừng → 02–05 carousel (PageDots 1–4, "Bỏ qua" on each, round Next) → 05 "Tạo hồ sơ bé" → 06 Chọn cách đăng nhập → 07a email link (default) → 07b Đã gửi link; or 07a → 07c password.

### 368:838 — OB 00 Splash

**Annotation (verbatim):** "Splash / launch: static launch screen = this layout without the glow (iOS LaunchScreen). In-app splash ≤ 1s: sun rises 8px + fade in (duration-base, ease-out), then crossfade to 01 Chào mừng. Reduce Motion: static logo, crossfade only. Follows system appearance — Night care uses the logo/\* night palette."

**Text (reading order)**
- StatusBar placeholder "9:41" / "•••"
- [logo wordmark, outlined vector] "child life"
- 368:842 "Cùng chăm con. Giữ tuổi thơ." (Care for the child together. Keep the childhood.) — bottom tagline, 14px Medium, ink-muted #55707a, centered, y=711.

**Layout / components**
- Frame 375x780, bg cloud #f6fcfb, border separator #dce8e7, radius 44.
- StatusBar (11:135) — "Placeholder iOS status bar for screen mockups."
- Glow 368:840 (320x320 vector circle, centred at top 129).
- Logo 368:841 = instance of Logo/Lockup Stacked (36:335) — "Stacked lockup (splash, square, social)." Contains Logo/Mark (112, mark 101.8) + Logo/Wordmark (247.8x49.6), gap 17.8.
- Logo/Mark description (verbatim): "Child Life logo — Khoảnh khắc: một khung ảnh có nắng và đồi. Color is bound to logo/\* variables, so it switches to the night palette automatically in Night care. Color Night = fixed night palette (for assets outside Figma modes). Mono Ink / Mono White for one-colour use. Corner radius ≈ 31% of the side." (Khoảnh khắc: một khung ảnh có nắng và đồi = "Moment: a photo frame with sun and hills")
- Logo/Wordmark description (verbatim): "Wordmark “child life”, lower-case, Be Vietnam Pro SemiBold −2.5 tracking, outlined. Color variant uses ink (flips in Night care)."

**Visual:** Pale mint background; large very-light teal circular glow behind logo. Logo mark: rounded square, teal top with yellow sun circle top-right, white wave band, darker teal hill at bottom. Below it dark teal/ink wordmark "child life". Tagline small muted grey at bottom. No buttons.

**Navigation:** auto — after ≤1s crossfades to 368:843 OB 01 Chào mừng (stated, for first install). (For returning user, R0 Splash → R1 presumably; inferred from section label.)

**Notes / not shown:** no loading/error/offline state; no indication of what happens if user is already signed in (inferred: skip to home). Launch-screen variant = same without glow (stated).

### 368:843 — OB 01 Chào mừng

**Annotation:** none on the frame or children.

**Text (reading order)**
- StatusBar "9:41" / "•••"
- TopBar: logo lockup "child life" (vector) + theme toggle icon button (moon icon, no text label)
- Illustration (368:930) captions, top→bottom:
  - Float card 368:967 "Bú bình · 120 ml" (Bottle feed · 120 ml) / 368:968 "Mẹ ghi · 2 phút trước" (Mom logged · 2 minutes ago)
  - Chip 368:961 "6–12 tuổi" (6–12 years)
  - Chip 368:959 "3–6 tuổi" (3–6 years)
  - Float card 368:974 "Lần đầu con cười" (Baby's first smile) / 368:975 "Đã lưu vào Kỷ niệm" (Saved to Memories) — mint-text #06716d
  - Chip 368:957 "1–3 tuổi" (1–3 years)
  - Chip 368:955 "0–12 tháng" (0–12 months)
  - Float card 368:979 (heart icon) "Bà nội thương ảnh của Teddy" (Grandma (paternal) loved Teddy's photo)
- Title 368:850 (Text/title SemiBold 30/36, −0.5): "Cùng con lớn lên," / "đồng hành từng bước." (Grow up with your child, / walking alongside every step.)
- Body 368:998 (Medium 15, ink-muted): "Chăm sóc, thấu hiểu và lưu giữ hành trình của con — bắt đầu từ năm đầu đời." (Care for, understand and keep your child's journey — starting from the first year of life.)
- Primary button 368:852: "Bắt đầu chặng đầu cùng con" (Start the first stage with your child)
- Secondary button 368:855: "Đăng nhập" (Sign in)
- Secondary button 368:856: "Mã mời" (Invite code)
- No page dots, no "Bỏ qua" on this screen.

**Layout / components**
- Content padding 16 h, pt 4, pb 34. TopBar (component 23:226) type = "Brand" → Logo/Lockup Horizontal (30px mark + wordmark 116.8x23.4) + "Theme toggle" 44px round surface-2 (#eef6f5) button with moon icon.
- TopBar description (verbatim): "Top bar for onboarding/auth (44px): round Back, “Bỏ qua” text button, setup progress, invite countdown, or the logo lockup (Logo/Lockup Horizontal, 28px) with a theme toggle."
- Logo/Lockup Horizontal description (verbatim): "Lockup ngang cho phương án 2: khung ảnh + wordmark “child life”." (Horizontal lockup for option 2: photo frame + wordmark.)
- Illustration 368:930 (341x319, custom group, not a named Illustration/* component): "Landscape" 297px rounded 26.4 with gradient #fff5d9→#e0f5f0, sun, clouds, rolling hills, dotted path with 4 milestone nodes (Illustration/Photo baby avatar in mint-deep ring; Icon/star in sunshine #ffd166 ring; Icon/spark in care-sleep-accent #6c6fd8 ring; Icon/globe in care-bottle-accent #3b8fd9 ring) + age chips + 3 "Float" cards (shadowed white).
- Illustration/Photo description: "Illustrated baby photo placeholder (privacy-safe). Use instead of real photos in mockups."
- Icons description: "Line icon (24px, 1.8 stroke) — placeholder drawing; production uses SF Symbols. Recolour by overriding the stroke with a text-colour token."
- Button 368:852 Primary (h56, mint-deep #087f7b, label on-mint-deep white, full width). Buttons 368:855/368:856 Secondary (h52, surface-2, ink label), row gap 12, equal flex.
- Button description (verbatim): "Pill button, label = 1–2-word verb (Lưu, Bắt đầu, Kết thúc, Chỉnh giờ, Mời, Thử lại). Primary h56 mint-deep/on-mint-deep, one per screen in the thumb zone. Secondary h52 surface-2. Tinted for secondary actions. Plain for text buttons (≥44 tap). Apple: use Apple’s official button in production. Press: scale 0.97 in duration-tap. Disabled: opacity 40%. Stretch to fill width for block buttons."
- Text styles: Text/title (Be Vietnam Pro SemiBold 30/36, −0.5); Text/body-strong (Medium 17/24) for buttons.

**Visual:** Mint/cloud background. Warm cream-to-mint landscape card with big yellow sun top-right, white clouds, peach/green hills, a dotted white path rising from bottom-left (baby photo avatar "0–12 tháng") through star (1–3), spark (3–6), globe (6–12) milestones — the "growth journey". Floating white cards overlap the landscape edges (feed log, first-smile memory, grandma heart reaction). Big dark ink headline, muted body, dark teal full-width primary pill, two light grey-mint secondary pills side by side.

**Navigation**
- "Bắt đầu chặng đầu cùng con" → OB 02 Chăm sóc (carousel slide 1) (inferred; frame order).
- "Đăng nhập" → OB 06 Chọn cách đăng nhập (inferred) — or straight to sign-in for existing users.
- "Mã mời" → invite-code entry flow (inferred; not in this section — likely in invite/join section).
- Theme toggle → toggles Light / Night care appearance (inferred from name "Theme toggle" + moon icon).

**Notes / not shown**
- Primary button label is 6 words, conflicts with Button description "1–2-word verb".
- Title copy "Cùng con lớn lên, đồng hành từng bước." differs from splash tagline "Cùng chăm con. Giữ tuổi thơ." and from the text-layer name in outline ("Cùng chăm con, giữ trọn tuổi t…") — layer name is stale; visible text is the one above.
- Age chips in illustration (0–12 tháng → 6–12 tuổi) suggest whole-childhood scope though V1 copy says "bắt đầu từ năm đầu đời".
- Theme toggle exists only here (Brand TopBar); unclear whether choice persists (inferred: local preference).
- Illustration text sizes are tiny (6.6–7.7px) — decorative, probably part of a raster/vector illustration rather than localisable text (needs decision for i18n D-012).

### 368:1000 — OB 02 Chăm sóc

**Annotation(s):** frame — none. On 368:1013 (Next button, verbatim): "Accessibility label: “Tiếp tục” — icon-only button, VoiceOver đọc “Tiếp tục, nút”." (VoiceOver reads "Continue, button".)

**Text (reading order)**
- StatusBar "9:41" / "•••"
- TopBar right: "Bỏ qua" (Skip) — 14 Medium, mint-text #06716d
- Illustration/Care: badge "3" / "chạm" (3 / taps); FloatChip "Bú bình · 120 ml" (Bottle feed · 120 ml); FloatChip "Thay tã · Ướt" (Diaper change · Wet); FloatChip "Ngủ · 1 giờ 20" (Sleep · 1 h 20)
- Title 368:1007 (Text/title): "Ghi bú, ngủ, tã" / "chỉ bằng một tay" (Log feeds, sleep, diapers / with just one hand)
- Body 368:1009 (Text/body Regular 16/24, ink-muted): "Tối đa 3 chạm là lưu xong." (At most 3 taps and it's saved.)
- Page dots (4, step 1 active)
- Round Next button (arrow-right icon; a11y label "Tiếp tục" = Continue)

**Layout / components**
- TopBar type = "Skip": 44px spacer left, "Bỏ qua" text right.
- Illustration/Care (24:221) 343x408, card-mint #2cbfb3, radius-hero 36. Description (verbatim): "Care feature: one-hand logging for feeds, sleep and diapers — chips name all three; “3 chạm” badge."
- FloatChip (23:164) ×3. Description (verbatim): "Floating chip on an illustration card: chip fill + shadow-chip. Lead = small care icon on mint-soft, a check on mint-deep (done/synced), or an initial avatar (who logged). Value uses tabular figures." Here: Bú bình chip lead = check on mint-deep; Thay tã lead = diaper icon on mint-soft; Ngủ lead = sleep (moon) icon on mint-soft.
- PageDots (23:185) step = "1". Description (verbatim): "Onboarding pagination: active = 24px mint-deep pill, others 6px separator dots."
- Button/Round (8:34) 64px mint-deep, Icon/arrow-right. Description (verbatim): "Round Next button (64px) on onboarding pages. Icon-only, so it MUST carry an accessibility label: “Tiếp tục” (VoiceOver: “Tiếp tục, nút”). Never rely on the arrow alone."
- Styles: Text/label (Medium 14/20), shadow-chip (#173D4429, 0/8, blur 24), Text/title, Text/body.

**Visual:** Large teal (card-mint) rounded card, central pale circle with a baby bottle (pink nipple, yellow collar, white body half-filled cream milk, teal graduation marks). Yellow circle badge top-right "3 chạm". White pill chips: top-left "Bú bình · 120 ml" with dark-teal check, bottom-left "Thay tã · Ướt", bottom-right "Ngủ · 1 giờ 20". Page dots bottom-left: 1st active (long mint-deep pill), 3 grey dots. Dark-teal round arrow button bottom-right.

**Navigation**
- Next (→) → OB 03 Cùng chăm (inferred; carousel order). Swipe left presumably also advances (inferred).
- "Bỏ qua" → skips remaining carousel → OB 06 Chọn cách đăng nhập (inferred).
- No Back control (system back / swipe right → OB 01, inferred).

**Notes / not shown:** 4 dots = slides 02–05 (01 Chào mừng not counted). Body copy "Tối đa 3 chạm" is a product rule (≤3 taps to save a care log) — check business-map R-xxx. Chip values use tabular figures.

### 368:1014 — OB 03 Cùng chăm

**Annotation(s):** frame — none. On 368:1027 Next button (verbatim): "Accessibility label: “Tiếp tục” — icon-only button, VoiceOver đọc “Tiếp tục, nút”."

**Text (reading order)**
- StatusBar "9:41" / "•••"
- TopBar: "Bỏ qua" (Skip)
- Illustration/Handover: FloatChip (check lead) "Đã đồng bộ" (Synced); timer label "Đang ngủ" (Sleeping); timer "01:24:08"; FloatChip (avatar "M") "Bú bình · 80 ml · Mẹ ghi" (Bottle feed · 80 ml · Mom logged); FloatChip (avatar "B") "Thay tã · Ướt · Ba ghi" (Diaper change · Wet · Dad logged)
- Title 368:1021: "Nhận ca, không cần hỏi" (Take over the shift, no need to ask)
- Body 368:1023: "Lần ghi gần nhất được đồng bộ cho cả nhà: ai ghi, ghi gì, lúc nào." (The latest log is synced for the whole family: who logged, what, and when.)
- Page dots (step 2 active)
- Round Next button (a11y "Tiếp tục")

**Layout / components**
- TopBar type "Skip". Illustration/Handover (24:251) 343x408, card-night #173d44, radius-hero 36. Description (verbatim): "Shared care: the latest logs, synced for the whole family — each chip reads “what · detail · who logged”. Timer shows “Đang ngủ 01:24:08”."
- FloatChip lead variants used: "Check" (mint-deep check, "Đã đồng bộ") and initial-avatar (M, B on mint-deep, white SemiBold 12).
- PageDots step = "2". Button/Round 64px + Icon/arrow-right (same descriptions as OB 02).

**Visual:** Dark night-teal card with yellow crescent moon top-right, small yellow star dots, white clouds at bottom. Central teal progress ring (partially filled, lighter track) with "Đang ngủ" muted label above large light "01:24:08". White pill chips: top-left synced check, bottom-left "M" chip, bottom-right-ish "B" chip overlapping clouds. Page dots: 2nd active. Dark-teal round arrow bottom-right.

**Navigation:** Next → OB 04 Growth Story (inferred); "Bỏ qua" → OB 06 (inferred); back → OB 02 (inferred).

**Notes / not shown:** chip avatars use family-role initials (M = Mẹ, B = Ba) — implies display of "who logged" in the product. Body copy implies real-time sync of last log across caregivers.

### 368:1028 — OB 04 Growth Story

**Annotation(s):** frame — none. On 368:1041 Next button (verbatim): "Accessibility label: “Tiếp tục” — icon-only button, VoiceOver đọc “Tiếp tục, nút”."

**Text (reading order)**
- StatusBar "9:41" / "•••"
- TopBar: "Bỏ qua" (Skip)
- Illustration/GrowthStory: FloatChip (spark icon) "Thẻ kỷ niệm tức thì" (Instant memory card); FloatChip (journal icon) "Nhật ký tuần 8" (Week 8 journal)
- Title 368:1035: "Khoảnh khắc" / "thành chuyện" (Moments / become stories)
- Body 368:1037: "Một ảnh thành thẻ kỷ niệm ngay. Cuối tuần có nhật ký của bé." (One photo becomes a memory card instantly. At the end of the week there's your baby's journal.)
- Page dots (step 3 active)
- Round Next button (a11y "Tiếp tục")

**Layout / components**
- TopBar type "Skip". Illustration/GrowthStory (24:278) 343x408, card-peach #ffa58d, radius-hero 36. Description (verbatim): "Growth Story: a photo becomes an instant memory card; each week becomes a journal entry. Warm colours = memories only."
- FloatChip ×2, lead = care-style icon on mint-soft (Icon/spark, Icon/journal).
- PageDots step = "3". Button/Round 64 + Icon/arrow-right.

**Visual:** Peach/coral card with pale circle, a mint back card and a white polaroid-style memory card in front showing an illustrated sleeping baby (yellow hat) in teal blanket with yellow sun, cream sky, yellow caption bar and small red heart; pink hearts top-left, yellow sparkle strokes top-right. Chips top-left and bottom-right. Page dots: 3rd active.

**Navigation:** Next → OB 05 Chia sẻ riêng tư (inferred); "Bỏ qua" → OB 06 (inferred).

**Notes / not shown:** Rule in description "Warm colours = memories only." Body promises weekly journal ("Cuối tuần có nhật ký của bé") — check V1 scope for weekly journal feature.

### 368:1042 — OB 05 Chia sẻ riêng tư

**Annotation:** none (frame and children).

**Text (reading order)**
- StatusBar "9:41" / "•••"
- TopBar: "Bỏ qua" (Skip)
- Illustration/Family: FloatChip (lock icon) "Bạn chọn quyền" (You choose the permissions); avatar initials "M" (Mẹ/Mom, with star badge = owner?), "B" (Ba/Dad), "L" (unclear — likely a nanny/caregiver, with a baby-bottle badge), "Bà" (Grandma, with heart badge); FloatChip (plus icon) "Mời người thân" (Invite relatives)
- Title 368:1049: "Đúng người," / "đúng quyền" (The right people, / the right permissions)
- Body 368:1051: "Bà được xem ảnh, cô trông trẻ được ghi cữ bú. Bạn quyết định ai thấy gì." (Grandma can view photos, the nanny can log feeds. You decide who sees what.)
- Page dots (step 4 active)
- Primary Button 368:1055: "Tạo hồ sơ bé" (Create baby profile) — replaces round Next on the last slide

**Layout / components**
- TopBar type "Skip". Illustration/Family (24:314) 343x408, card-sun #ffd166, radius-hero 36. Description (verbatim): "Private sharing: invite relatives and choose what each can see or log. Operational details (link expiry) live on the real invite screen."
- FloatChip ×2 (lead = Icon/lock, Icon/plus on mint-soft). Icon/star badge on "M" avatar.
- PageDots step = "4".
- Button (8:33) Primary h56 mint-deep, hug width (not stretched), right of dots in the Row.

**Visual:** Sunny yellow card; centre: sleeping baby face with teal beanie inside a cream circle; dashed orbit circle with 4 avatar bubbles — "M" dark teal (star badge), "B" teal, "L" white/pale with small mint bottle badge, "Bà" peach with red heart badge. Chips "Bạn chọn quyền" top-right, "Mời người thân" bottom-left. Page dots: 4th (last) active. Dark-teal pill "Tạo hồ sơ bé" bottom-right.

**Navigation**
- "Tạo hồ sơ bé" → OB 06 Chọn cách đăng nhập (inferred: account must be created before baby profile) — or directly to baby-profile setup if sign-in comes later (unclear; not stated).
- "Bỏ qua" → OB 06 (inferred). Note "Bỏ qua" still shown on last slide.

**Notes / not shown:** last slide still shows "Bỏ qua" although its CTA already ends the carousel (redundant). "L" initial unexplained (maybe "Lan" nanny). Permission model hinted: grandma = view photos, nanny = log feeds (cf. family roles in business-map). Button label "Tạo hồ sơ bé" (3 words) vs description "1–2-word verb".

### 368:1056 — OB 06 Chọn cách đăng nhập

**Annotation:** none (frame and children).

**Text (reading order)**
- StatusBar "9:41" / "•••"
- Back button (icon only; a11y label per component: "Quay lại" = Back)
- Illustration (same growth-journey landscape as OB 01, scaled 1.056): "Bú bình · 120 ml" / "Mẹ ghi · 2 phút trước"; "6–12 tuổi"; "3–6 tuổi"; "Lần đầu con cười" / "Đã lưu vào Kỷ niệm"; "1–3 tuổi"; "0–12 tháng"; "Bà nội thương ảnh của Teddy" (same glosses as OB 01)
- Sheet title 368:1064: "Chào bạn" (Hello / Hi there)
- Sheet body 368:1066: "Đăng nhập để bắt đầu hành trình cùng con." (Sign in to start the journey with your child.)
- Button 368:1068: "Tiếp tục với Apple" (Continue with Apple)
- Button 368:1070: "Tiếp tục với Google" (Continue with Google)
- Button 368:1072: "Dùng email" (Use email) — mail icon
- Footer link 368:1074: "Điều khoản · Quyền riêng tư" (Terms · Privacy) — mint-text, centered

**Layout / components**
- Background "Illustration" 368:1084 (375x440, cloud) holding growth-journey illustration 368:1089 (custom, not Illustration/* component).
- Button/Back (8:37) at top-left 44px, surface-2. Description (verbatim): "Round back button, 44px tap target, surface-2. Accessibility label: Quay lại."
- Sheet 368:1060: white surface, top radius-sheet 32, shadow-sheet (#173D441F, 0/−8, blur 32), pt 8, px 16, pb 34; Grabber 40x5 separator. Sits at y=408 (bottom sheet, non-modal look).
- Button 368:1068 = Apple variant: bg apple-button (black), ink apple-button-ink (white), h56, Icon/brand-mark 18px.
- Button 368:1070 = Google/outline variant: surface white, 1.5px border control-border #7e959a, h56, Icon/brand-mark.
- Button 368:1072 = Secondary (h52 surface-2) with Icon/mail.
- Button description (verbatim): "Pill button, label = 1–2-word verb (Lưu, Bắt đầu, Kết thúc, Chỉnh giờ, Mời, Thử lại). Primary h56 mint-deep/on-mint-deep, one per screen in the thumb zone. Secondary h52 surface-2. Tinted for secondary actions. Plain for text buttons (≥44 tap). Apple: use Apple’s official button in production. Press: scale 0.97 in duration-tap. Disabled: opacity 40%. Stretch to fill width for block buttons."
- Icon/brand-mark description (verbatim): "Placeholder for Apple / Google marks — use the official logos in production."
- Icon/mail: "Line icon (24px, 1.8 stroke) — placeholder; production uses SF Symbols."

**Visual:** Top half shows the OB 01 landscape (sun, clouds, hills, milestone path, floating cards) with a round back button overlapping top-left. White bottom sheet with grabber, large "Chào bạn", muted subline, black Apple pill, white outlined Google pill, mint-grey "Dùng email" pill, teal footer links. Brand marks are placeholder squares.

**Navigation**
- Back → previous screen (OB 05 or OB 01 depending on entry) (inferred).
- "Tiếp tục với Apple" → native Sign in with Apple sheet → on success, new user → baby profile setup / existing → home (inferred).
- "Tiếp tục với Google" → Google sign-in (inferred).
- "Dùng email" → OB 07a Đăng nhập · link qua email (inferred; frame order).
- "Điều khoản · Quyền riêng tư" → Terms / Privacy pages (inferred; two separate links in one line).

**Notes / not shown:** No phone/SMS option. No explicit consent checkbox; terms link only (implicit acceptance — legal copy like "Khi tiếp tục, bạn đồng ý…" absent). Apple shown first (App Store guideline). On Android, Apple button visibility not specified. No loading / error / cancelled states for social sign-in. Sheet appears non-dismissable (grabber present but no defined dismiss behaviour). Same frame used for both "Tạo hồ sơ bé" and "Đăng nhập" entry? — title "Chào bạn" is neutral (works for both).

### 368:1139 — OB 07a Đăng nhập · link qua email

**Annotation:** none (frame and children).

**Text (reading order)**
- StatusBar "9:41" / "•••"
- Back button (icon only; a11y "Quay lại")
- Title 368:1144 (Text/display SemiBold 34/40, −0.6): "Đăng nhập" (Sign in)
- Segmented: "Đăng nhập" (Sign in) [selected] | "Tài khoản mới" (New account)
- TextField label "Email" / value "ten@email.com" (name@email.com — shown as filled value, styled ink, not placeholder grey)
- Helper 368:1180 (Medium 13, ink-muted, 1.5): "Chúng tôi sẽ gửi link đăng nhập vào email — không cần nhớ mật khẩu." (We'll send a sign-in link to your email — no need to remember a password.)
- Primary Button 368:1153: "Gửi link đăng nhập" (Send sign-in link)
- Text link 368:1155 (Text/label, mint-text, centered): "Đăng nhập bằng mật khẩu" (Sign in with password)

**Layout / components**
- TopBar type = "Back" (Button/Back 44px only).
- Segmented (9:124) with 2 Segmented/Item. Descriptions (verbatim): Segmented — "Pill segmented control on surface-2 track (pad 5, gap 4). 2–3 short options (Sữa mẹ · Sữa công thức; Ướt · Bẩn · Cả hai). Remembers the last choice as the default." Segmented/Item — "One segment. Selected: surface + shadow-card, ink, weight 500. Unselected: transparent, ink-muted. Change animates in duration-quick."
- "Field group" 368:1148: white surface card, radius-card 24, shadow-card; contains TextField (23:243) props: label="Email", value="ten@email.com", style="Grouped", showEye=false. Description (verbatim): "Text field: caption label above the value. Grouped = row inside a surface card (stack rows with a 1px separator). Standalone = its own surface card. Password shows a 32px eye toggle."
- Button Primary h56 full width (mint-deep) bottom; plain text link below.
- Styles: Text/display, Text/caption (label 12/16 +0.2), Text/body (value), Text/body-strong, Text/label, shadow-card.

**Visual:** Plain cloud background, round back button top-left, large dark "Đăng nhập" heading, pill segmented control with white selected "Đăng nhập" and grey "Tài khoản mới", white rounded email card, small grey helper text, big empty space, full-width dark teal "Gửi link đăng nhập" pill, teal text link "Đăng nhập bằng mật khẩu" under it.

**Navigation**
- Back → OB 06 (inferred).
- Segment "Tài khoản mới" → same screen in sign-up mode (inferred; no frame for it in this section). Segment presumably changes copy/CTA (not shown).
- "Gửi link đăng nhập" → sends magic link (Firebase email-link auth, inferred) → OB 07b Đã gửi link.
- "Đăng nhập bằng mật khẩu" → OB 07c Đăng nhập · mật khẩu.

**Notes / not shown:** No "Tài khoản mới" state frame; unclear what differs (magic link works for both sign-in and sign-up — segmented may be redundant). No invalid-email error, empty state/disabled CTA, sending/loading, rate-limit, or keyboard-up layout. Segmented component description says "Remembers the last choice as the default" — for auth that rule is odd. Value "ten@email.com" is example content, not a placeholder (placeholder style undefined). Button label 3 words vs "1–2-word verb" rule.

### 368:1184 — OB 07b Đã gửi link

**Annotation:** none (frame and children).

**Text (reading order)**
- StatusBar "9:41" / "•••"
- Back (icon only, custom small white round button — not Button/Back component)
- Mail icon in mint-soft circle (no text)
- Title 368:1198 (Bold 28): "Kiểm tra email của bạn" (Check your email)
- Body 368:1199 (Medium 15, 1.5, ink-muted): "Đã gửi link đăng nhập đến mai.nguyen@email.com. Mở link trên điện thoại này trong 15 phút để vào app." (A sign-in link was sent to mai.nguyen@email.com. Open the link on this phone within 15 minutes to get into the app.)
- Banner 368:1205 (alert icon, Medium 13): "Không thấy email? Xem thư mục Quảng cáo hoặc Spam." (Don't see the email? Check the Promotions or Spam folder.)
- Primary Button 368:1207: "Mở ứng dụng Mail" (Open the Mail app)
- Secondary Button 368:1211: "Gửi lại sau 0:45" (Resend in 0:45)
- Plain Button 368:1216: "Đổi email" (Change email)

**Layout / components**
- Frame built ad hoc (no frame border, radius 40 vs 44 elsewhere; Content absolute, pt 52, gap 14, px 16). No TopBar component — custom "Top" row with white 36px "back" circle (Icon/back 20px, surface white instead of surface-2, smaller than 44 tap target).
- "ic": mint-soft circle p22 with Icon/mail 40px (mint-deep stroke).
- Banner 368:1200: surface-2, radius 14, px14 py12, Icon/alert 16px + text (not a named component).
- Button (8:33) variants: Primary h56 (Mở ứng dụng Mail), Secondary h52 surface-2 (Gửi lại sau 0:45 — countdown, looks enabled not 40% disabled), Plain h44 mint-text (Đổi email).
- Button description as in OB 01 (Disabled: opacity 40%).
- Text styles not bound to tokens for title/body (Bold 28, Medium 15 — not Text/title/body styles).

**Visual:** Cloud background, small white back circle top-left, big pale-mint circle with dark-teal envelope icon, bold dark heading, grey body with email, light grey info banner with circled "!" icon, dark-teal "Mở ứng dụng Mail" pill, grey "Gửi lại sau 0:45" pill, teal "Đổi email" text button. Bottom half empty.

**Navigation**
- "Mở ứng dụng Mail" → opens the default mail app (iOS mailto/message: scheme; Android: email app chooser) (inferred).
- "Gửi lại sau 0:45" → disabled during cooldown; becomes "Gửi lại" (Resend) when timer hits 0 → resends link (inferred; enabled state not shown).
- "Đổi email" → back to OB 07a with email field editable (inferred).
- Back → OB 07a (inferred).
- Tapping link in email on this device → deep link opens app, signs in → baby setup / home (inferred; no "signing in…" frame).

**Notes / not shown**
- Link validity "15 phút" (15 minutes) and resend cooldown shown as 0:45 (likely 60 s start; exact cooldown not stated).
- "Mở link trên điện thoại này" — same-device requirement (Firebase email link needs stored email; cross-device flow not designed).
- No state for: resend enabled, resend success toast, link expired / invalid link, opened on another device, deep-link verifying spinner.
- Visual inconsistencies: frame radius 40 / no border vs other frames 44 + border; custom back button (white 36px) vs Button/Back (surface-2 44px); title Bold 28 vs Text/display 34 on 07a.
- Example email "mai.nguyen@email.com" differs from 07a's "ten@email.com".
- Android lacks a single "Mail" app — label needs platform variant.

### 368:1221 — OB 07c Đăng nhập · mật khẩu

**Annotation:** none (frame and children).

**Text (reading order)**
- StatusBar "9:41" / "•••"
- Back button (icon only; a11y "Quay lại")
- Title 368:1226 (Text/display): "Đăng nhập" (Sign in)
- Segmented: "Đăng nhập" (Sign in) [selected] | "Tài khoản mới" (New account)
- TextField 1: label "Email" / value "ten@email.com" (name@email.com)
- TextField 2: label "Mật khẩu" (Password) / value "8+ ký tự" (8+ characters) — shown in ink as value; acts as placeholder hint; eye toggle
- Primary Button 368:1235: "Đăng nhập" (Sign in)
- Footer link 368:1237 (Text/label, mint-text, centered): "Quên mật khẩu? · Gửi link đăng nhập" (Forgot password? · Send sign-in link)

**Layout / components**
- TopBar type = "Back" (Button/Back 44 surface-2).
- Segmented (9:124) + 2 Segmented/Item (same descriptions as 07a).
- Field group 368:1230 (surface card, radius-card 24, shadow-card): TextField (Grouped, label "Email", value "ten@email.com", showEye=false) + Divider 1px separator + TextField (Grouped, label "Mật khẩu", value "8+ ký tự", showEye=true → 32px surface-2 circle with Icon/eye 18px).
- TextField description (verbatim): "Text field: caption label above the value. Grouped = row inside a surface card (stack rows with a 1px separator). Standalone = its own surface card. Password shows a 32px eye toggle."
- Icon/eye: "Line icon (24px, 1.8 stroke) — placeholder; production uses SF Symbols."
- Button Primary h56 full width; plain text link line (single text node, two actions).

**Visual:** Identical to 07a but card has two rows (email, password with eye icon at right), no helper text, CTA "Đăng nhập", footer "Quên mật khẩu? · Gửi link đăng nhập" in teal.

**Navigation**
- "Đăng nhập" → email/password sign-in → home (returning) or baby profile setup (no child yet) (inferred).
- "Quên mật khẩu?" → password reset (inferred: Firebase reset email; no frame).
- "Gửi link đăng nhập" → back to OB 07a magic-link mode (inferred).
- Eye toggle → show/hide password (inferred).
- Segment "Tài khoản mới" → sign-up with password (inferred; no frame).
- Back → OB 07a (inferred).

**Notes / not shown:** Password rule "8+ ký tự" (min 8 chars) only implied by hint. No wrong-password / user-not-found / too-many-attempts errors, no loading, no disabled CTA state, no password reset flow, no sign-up (Tài khoản mới) password frame (confirm password? terms?). Two actions in one text node — needs split into two tappable links ≥44pt. Placeholder vs value styling identical (ambiguous).

### Compared with the current app (cluster 6)
Current: `SplashScreen`, `WelcomeScreen`, `TourScreen` (`apps/mobile/lib/features/onboarding/welcome_screens.dart`), `SignInScreen`, `EmailScreen`, `VerifyEmailScreen`, `ForgotPasswordScreen`, `AccountExistsScreen` (`features/auth/auth_screens.dart`); routes `/`, `/welcome`, `/tour`, `/auth`, `/auth/email`, `/auth/verify`, `/auth/forgot`, `/auth/exists`.
New or different:
1. **01 Chào mừng — new copy and art:** title "Cùng con lớn lên, / đồng hành từng bước." (app: "Cùng chăm con, / giữ trọn tuổi thơ"); new body "Chăm sóc, thấu hiểu và lưu giữ hành trình của con — bắt đầu từ năm đầu đời." (app has none); primary "Bắt đầu chặng đầu cùng con" (app: "Khám phá"); "Đăng nhập" and "Mã mời" are now two secondary buttons side by side. New "growth journey" landscape illustration (age chips 0–12 tháng → 6–12 tuổi, three floating cards) replaces `WelcomeHero` — new asset, with tiny embedded text that needs an i18n decision (D-012).
2. **02–05 carousel:** copy is unchanged from the current tour; same illustrations (Illustration/Care, Handover, GrowthStory, Family). No change needed beyond verifying "Bỏ qua" is still shown on 05.
3. **06 sign-in chooser:** body becomes "Đăng nhập để bắt đầu hành trình cùng con." (app: "Đăng nhập để bắt đầu."); the hero behind the sheet is the same growth-journey landscape as 01 (app: mint hero with toy blocks).
4. **07a — new passwordless email-link sign-in as the default email path** (app has email + password only; nothing uses `sendSignInLinkToEmail`): title "Đăng nhập", segmented "Đăng nhập | Tài khoản mới" (order reversed vs app's "Tài khoản mới | Đăng nhập"), single Email field, helper "Chúng tôi sẽ gửi link đăng nhập vào email — không cần nhớ mật khẩu.", button "Gửi link đăng nhập", link "Đăng nhập bằng mật khẩu". Needs Firebase Email Link auth enabled on dev/prod, ActionCodeSettings with an app link / universal link domain, iOS Associated Domains + Android App Links for both flavors, storing the pending email on device, and handling the incoming link (`isSignInWithEmailLink` → `signInWithEmailLink`), plus linking when the email already has an Apple/Google account (cluster 1).
5. **07b "Kiểm tra email của bạn" — new screen** (the app's 08 verify screen is for post-sign-up verification, different copy): body with the address and "trong 15 phút" + "trên điện thoại này" (same-device rule), Spam/Quảng cáo banner, "Mở ứng dụng Mail", "Gửi lại sau 0:45" countdown (the app has a resend cooldown pattern "Gửi lại sau {s} giây" to reuse, but the format here is m:ss), "Đổi email". The 15-minute validity must be checked against what Firebase email links actually allow (inferred risk).
6. **07c password sign-in:** same fields as the app's 07 "Đăng nhập" segment, but reached from 07a; footer "Quên mật khẩu? · Gửi link đăng nhập" (two separate links) instead of the app's standalone "Quên mật khẩu?"; the "Email đã dùng với Apple/Google?" link is not on this frame.
7. Not drawn: "Tài khoản mới" variants of 07a/07c, errors, loading, link expired/invalid, deep-link landing, invite code.

---

## Cluster 7 — Label 368:837 (verbatim): "Đăng nhập lại (đã từng dùng app) · không hiện onboarding"
(Sign in again (has used the app before) · do not show onboarding.)

Flow (inferred from frame order + label): R0 Splash → R1 "Chào mừng trở lại" sign-in sheet (no Back, no Welcome/carousel) → R2 email link (= 07a) → 07b / 07c reused.

### 368:1261 — OB R0 Splash

**Annotation (verbatim, identical to OB 00):** "Splash / launch: static launch screen = this layout without the glow (iOS LaunchScreen). In-app splash ≤ 1s: sun rises 8px + fade in (duration-base, ease-out), then crossfade to 01 Chào mừng. Reduce Motion: static logo, crossfade only. Follows system appearance — Night care uses the logo/\* night palette."

**Text (reading order)**
- StatusBar "9:41" / "•••"
- [wordmark vector] "child life"
- 368:1265 "Cùng chăm con. Giữ tuổi thơ." (Care for the child together. Keep the childhood.)

**Layout / components:** Pixel-identical copy of OB 00 — Glow 368:1263 (320px), Logo 368:1264 = Logo/Lockup Stacked (Logo/Mark 112 + Logo/Wordmark), tagline 14 Medium ink-muted. Same component descriptions as OB 00.

**Visual:** Same as OB 00 (mint background, pale glow circle, teal photo-frame logo with yellow sun, ink "child life" wordmark, muted tagline at bottom).

**Navigation:** → OB R1 Đăng nhập lại (inferred from section "Đăng nhập lại (đã từng dùng app) · không hiện onboarding"). If session still valid → straight to Home (inferred).

**Notes / not shown:** Annotation was copy-pasted from OB 00 and says "then crossfade to 01 Chào mừng" — contradicts the section label (returning users must NOT see onboarding); should crossfade to R1. How the app knows the user "used the app before" (local flag vs signed-out session vs reinstall) is not specified.

### 368:1266 — OB R1 Đăng nhập lại

**Annotation:** none (frame and children).

**Text (reading order)**
- StatusBar "9:41" / "•••"
- (No back button — differs from OB 06)
- Illustration (same as OB 06): "Bú bình · 120 ml" / "Mẹ ghi · 2 phút trước"; "6–12 tuổi"; "3–6 tuổi"; "Lần đầu con cười" / "Đã lưu vào Kỷ niệm"; "1–3 tuổi"; "0–12 tháng"; "Bà nội thương ảnh của Teddy"
- Sheet title 368:1274: "Chào mừng trở lại" (Welcome back)
- Sheet body 368:1276: "Đăng nhập để tiếp tục hành trình cùng con." (Sign in to continue the journey with your child.)
- Button 368:1278: "Tiếp tục với Apple" (Continue with Apple)
- Button 368:1280: "Tiếp tục với Google" (Continue with Google)
- Button 368:1282: "Dùng email" (Use email)
- Footer 368:1284: "Điều khoản · Quyền riêng tư" (Terms · Privacy)

**Layout / components:** Same structure as OB 06 — background Illustration 368:1294 (growth-journey landscape), Sheet 368:1270 (radius-sheet 32, shadow-sheet, grabber), Apple button (apple-button black / apple-button-ink white, h56, Icon/brand-mark), Google outline button (surface, 1.5px control-border, h56, Icon/brand-mark), Secondary "Dùng email" (h52 surface-2, Icon/mail), footer Text/label mint-text. Only differences vs OB 06: no Button/Back, title/body copy. Component descriptions same as OB 06 (Button, Icon/brand-mark "Placeholder for Apple / Google marks — use the official logos in production.").

**Visual:** Identical look to OB 06 minus the back button; heading "Chào mừng trở lại".

**Navigation**
- Apple / Google → provider sign-in → Home (existing account) (inferred).
- "Dùng email" → OB R2 Đăng nhập · link qua email.
- Terms · Privacy → legal pages (inferred).
- No route to onboarding carousel, "Mã mời" or "Tài khoản mới" from here except via email screen segment (inferred).

**Notes / not shown:** No "Không phải bạn? / Tạo tài khoản mới" or invite-code entry for a returning device used by a different person. No last-used provider hint (e.g. "Bạn đã đăng nhập bằng Google lần trước"). Errors / loading not shown.

### 368:1349 — OB R2 Đăng nhập · link qua email

**Annotation:** none (frame and children).

**Text (reading order) — identical copy to OB 07a**
- StatusBar "9:41" / "•••"
- Back button (icon only; a11y "Quay lại")
- Title 368:1354: "Đăng nhập" (Sign in)
- Segmented: "Đăng nhập" (Sign in) [selected] | "Tài khoản mới" (New account)
- TextField label "Email" / value "ten@email.com"
- Helper 368:1388: "Chúng tôi sẽ gửi link đăng nhập vào email — không cần nhớ mật khẩu." (We'll send a sign-in link to your email — no need to remember a password.)
- Primary Button 368:1363: "Gửi link đăng nhập" (Send sign-in link)
- Link 368:1365: "Đăng nhập bằng mật khẩu" (Sign in with password)

**Layout / components:** Exact duplicate of OB 07a — TopBar type "Back" (Button/Back), Text/display title, Segmented (9:124) + 2 Segmented/Item, Field group card with TextField (Grouped, label Email, value ten@email.com, showEye=false), helper caption 13 Medium, Primary Button h56, plain mint-text link. Same component descriptions as OB 07a.

**Visual:** Pixel-identical to OB 07a.

**Navigation**
- Back → OB R1 (inferred).
- "Gửi link đăng nhập" → "Đã gửi link" (OB 07b equivalent; no R-specific frame) (inferred).
- "Đăng nhập bằng mật khẩu" → OB 07c equivalent (inferred).
- "Tài khoản mới" segment → sign-up mode (inferred; contradicts "returning user" context but kept).

**Notes / not shown:** Returning-user email screen does not prefill the last-used email (value is generic "ten@email.com"). No R-specific "link sent" or password frames — reuse 07b/07c. Same gaps as 07a (errors, loading, Tài khoản mới state).

### Compared with the current app (cluster 7)
- **New routing state:** the app does not distinguish a first install from a returning user — `guardRoute` (`apps/mobile/lib/app/route_guard.dart`) sends every signed-out user to `/welcome`. The design needs a persisted device flag (e.g. "has signed in on this device before", set on first successful sign-in and kept after sign-out) so that signed-out returning users land on **R1** instead of 01/carousel. Whether the flag should survive a reinstall (iOS Keychain) is not specified.
- **R1 "Chào mừng trở lại" — new screen variant** of 06: title "Chào mừng trở lại", body "Đăng nhập để tiếp tục hành trình cùng con.", no Back button, same three buttons and footer. There is no route from R1 to "Mã mời" or to the tour (gap: a returning device used by someone with an invite).
- **R2** = 07a (email link), so the email-link work from cluster 6 applies; no prefill of the last-used email is designed.
- The R0 annotation still says "crossfade to 01 Chào mừng" (copy-paste) — follow the label (go to R1), and if a session is still valid skip straight to Today (inferred).

---

## Cluster 8 — Label 370:1246 (verbatim): "Chăm sóc (Care) · Hôm nay"
(Care · Today.)

Five frames that define the new tab model: Today with a user avatar and a "Tuỳ chỉnh" entry, the Today customise sheet, "Tôi" opened from the avatar, and the new **Chăm sóc** tab (parent and caregiver views).

### 370:1248 — CS Hôm nay

**Annotation (frame, verbatim):** "Thẻ lớn = vừa ghi vừa xem: chạm thẻ → mở sheet ghi mục đó (1 chạm); dòng dưới là lần cuối (bao lâu trước · chi tiết · ai ghi). Ngủ khi timer chạy → CareTile Tone=Active hiện thời gian đang chạy. Tăng trưởng: hàng riêng, + mở màn nhập số đo. “Lịch sử” → dòng thời gian."
(Gloss: Big tiles = both log and view: tap a tile → opens that item's log sheet (1 tap); lines below are the last entry (how long ago · detail · who logged). Sleep while timer is running → CareTile Tone=Active shows running time. Growth: its own row, + opens the measurement input screen. "Lịch sử" → timeline.)
   Note: says "Tăng trưởng: hàng riêng" but in the frame Growth shares Row 3 with Hút sữa (Pump) — not its own row; no "+" visible on the Growth tile.

**Text (reading order)**
- StatusBar "9:41" / "•••"
- Header: UserAvatar 370:1253 "M" (peach #ffa58d pill, initial M); BabySwitcher name "Teddy · 3 tuần" (Teddy · 3 weeks) + chevron-down; spacer; Night care toggle (44px round, Icon/sleep moon, no label).
- 370:1259 "Thứ Năm, 8 tháng 10" (Thursday, 8 October)
- Title row: 370:1261 "Hôm nay" (Today, large title 32) · chip button 370:1265 [Icon/sliders] "Tuỳ chỉnh" (Customize)
- Care tiles (2-col grid, 3 rows):
  - Row 1: CareTile Bú bình — "Bú bình" (Bottle feed) / "120 ml" / "45 phút trước" (45 min ago) / "Mẹ ghi" (Mom logged)
  - Row 1: CareTile Bú mẹ — "Bú mẹ" (Breastfeed) / "15 phút" (15 min) / "Kết thúc 3 giờ 35 phút trước" (Ended 3 h 35 min ago) / "Mẹ ghi" (Mom logged)
  - Row 2: CareTile Giấc ngủ — "Giấc ngủ" (Sleep) / "Đã thức 2 giờ" (Awake 2 hours) / "Dậy lúc 13:05" (Woke at 13:05) / "Ba ghi" (Dad logged)
  - Row 2: CareTile Thay tã — "Thay tã" (Diaper change) / "Tã ướt" (Wet diaper) / "1h 25p trước" (1h 25m ago) / "Cô Lan ghi" (Ms. Lan logged)
  - Row 3: CareTile type=Pump — "Hút sữa" (Pumping) / "90 ml" / "2 giờ trước" (2 hours ago) / "Mẹ ghi"
  - Row 3: CareTile type=Growth — "Tăng trưởng" (Growth) / "4,3 kg" / "54,5 cm" / "+0,4 kg · hôm nay" (+0.4 kg · today)
- ReminderPeek (defaults): label "Nhắc việc · 3" (Reminders · 3) / title "Tiêm 6 trong 1" (6-in-1 vaccine) / meta "Thứ Bảy 08:30 · còn 2 ngày" (Saturday 08:30 · 2 days left) / chevron-right
- SectionHeader: "Hôm nay" (Today) · link "Lịch sử" (History, mint-text)
- DayRhythm (Filter=All): "Đã ghi hôm nay" (Logged today); "Bú bình" "2 cữ · 240 ml" (2 feeds · 240 ml); "Bú mẹ" "1 cữ · 15 phút" (1 feed · 15 min); "Ngủ (đã xong)" (Sleep (finished)) "7 giờ 50" (7 h 50); "Thay tã" "2 lần" (2 times); 24h track axis "0h 6h 12h 18h 24h"; legend "Ngủ" (Sleep) · "Bú bình" · "Bú mẹ" · "Tã" (Diaper). Track layers: Sleep 00:00–06:30, Sleep 11:45–13:05, Feed 08:00, Breastfeed 11:30–11:45, Feed 14:20, Diaper 09:10, Diaper 13:40, Now 15:05 (ink line).
- TabDock: NavBar v1.0.1 + QuickLogButton (+).

**Layout / components**
- Frame 375x1135 (scrolling), bg cloud #f6fcfb, radius 44. Content px16 pt4 pb120.
- Header: UserAvatar (local frame, peach pill with initial, not a component instance) · BabySwitcher (45:321) · spacer · "Night care toggle" (frame, surface-2 44px circle, Icon/sleep 20px).
- BabySwitcher description: "Baby switcher chip: avatar + name (+ chevron when the family has more than one baby). Shows whose log you are viewing."
- "Tuỳ chỉnh" = local pill (surface white, separator border, Icon/sliders 14 + SemiBold 13).
- CareTile (54:530) ×6: Bottle (bottle-soft #e5f1fb), Breast (breast-soft #fceaf0), Sleep (sleep-soft #edeefc), Diaper (diaper-soft #e7f4e3), Pump (pump soft #f5eafa, ink #7b3a94), Growth (growth-soft #fdede2, ink #9a4a14). Each: label (care ink, Medium 16), value (SemiBold 20), When + Who lines (Medium 14 muted), mini 3D art 84px bottom-right (Illustration/Mini/Bottle, Drop, Moon, Diaper, Pump, Ruler). Variant prop `type` exposed only as "Bottle" | "Pump" | "Growth" in the generated code (other tiles are detached-like overrides). Tone=Active mentioned in annotation (not shown here).
- CareTile description (verbatim): "Care tile on Today. Tinted card (care/<type>/soft) with a line icon in a care-accent-20% circle, type label (care ink), key value, ⏱ when, 👤 who logged. Tap = log that type. Sleep running = live elapsed + accent border. Empty = “Chưa có / Chạm để ghi” (swap the icon + colours per type)." (Chưa có / Chạm để ghi = None yet / Tap to log). Note: description says line icon in circle + ⏱/👤 icons; frame shows no line icon / no ⏱👤 glyphs — uses mini art instead.
- ReminderPeek (128:665) description: "Home entry to reminders (S15): next upcoming reminder + count. Tap opens reminder list." Sunshine-soft 40px circle with Icon/clock.
- SectionHeader (9:140): "Section header: headline title + optional mint-text link. space-6 above, space-2 below."
- DayRhythm Filter=All (48:409) description: "“Đã ghi hôm nay”: totals of what was logged today (bottle feeds + ml, breastfeeds + minutes, finished sleep, diaper changes) and a 24h strip in care colours. Running sleep is not counted until it ends."
- TabDock (10:169): "Tab dock = NavBar + QuickLogButton, 24px above the home indicator. Swap the nested NavBar variant (Active) per tab." NavBar v1.0.1 (dark #173d44 pill): tabs in order Tab/Today (ACTIVE: white pill, icon + label "Hôm nay"), Tab/Memories (icon only), Tab/Care (icon only), Tab/Family (icon only). 4 tabs — NO Me/"Tôi" tab; Me is reached from the header avatar (see 370:1898).
- QuickLogButton (44:363): "Ghi nhanh (+): opens the quick-log chooser (Bú · Ngủ · Tã · Tăng trưởng). 68px, accessibility label “Ghi nhanh”." (Bú · Ngủ · Tã · Tăng trưởng = Feed · Sleep · Diaper · Growth; note: no Pump listed.)

**Visual:** Pastel tiles with soft shadow, 3D mini objects peeking at bottom-right (bottle, teal drop, yellow crescent moon, diaper, pump, yellow ruler). Avatar "M" peach pill at far left of header; baby face avatar inside switcher. Moon icon toggle top right. Reminder card white with yellow clock circle. DayRhythm strip: purple sleep bars, blue/pink/green ticks, dark "now" line. Bottom: dark nav pill with Today active (white pill w/ sun icon + label), heart/photo, hand-heart, people icons; teal round + button right.

**Navigation**
- UserAvatar "M" → Tôi (Me) screen (370:1898 "CS Tôi (từ avatar)") (inferred from frame name).
- BabySwitcher → switch baby (chevron shown; inferred sheet/menu).
- Night care toggle → toggles Night care theme (inferred).
- "Tuỳ chỉnh" → CS Tuỳ chỉnh Hôm nay (370:1525) (inferred by name).
- Tap CareTile → opens log sheet for that type, 1 tap (stated). Growth → measurement input screen (stated). Sleep running → Tone=Active live elapsed (stated).
- ReminderPeek → reminder list (stated, "S15") → likely 370:2365 CS 1a · Nhắc nhở (inferred).
- "Lịch sử" → timeline/history (stated).
- QuickLogButton → quick-log chooser (stated).
- Tabs: Memories / Care (370:1971) / Family (inferred).

**Notes / not shown**
- Annotation says Growth on its own row with "+"; frame puts Growth beside Pump without a "+".
- ReminderPeek here shows a vaccine reminder ("Tiêm 6 trong 1") — a dated one-off reminder, not a feed/sleep rule reminder; the peek's relation to rule reminders (1a–1h) not specified.
- No empty state, no running-sleep (Tone=Active) state, no multi-baby state shown in this frame.
- Date "Thứ Năm, 8 tháng 10" while ReminderPeek "Thứ Bảy … còn 2 ngày" (consistent: Sat = +2 days).

### 370:1525 — CS Tuỳ chỉnh Hôm nay

**Annotation:** frame carries the SAME annotation as 370:1248, copy-pasted verbatim ("Thẻ lớn = vừa ghi vừa xem: chạm thẻ → mở sheet ghi mục đó (1 chạm); … “Lịch sử” → dòng thời gian."). No annotation specific to the customize sheet.

**Text (reading order)**
- Background (dimmed under scrim, identical to 370:1248 at 812 height): header "M", "Teddy · 3 tuần", night toggle; "Thứ Năm, 8 tháng 10"; "Hôm nay"; "Tuỳ chỉnh"; tiles etc. (same values as 370:1248).
- Sheet:
  - SheetHeader title "Tuỳ chỉnh Hôm nay" (Customize Today) + close (X).
  - 370:1594 "Bật, tắt và kéo để sắp xếp những gì hiện trên Hôm nay." (Turn on, turn off and drag to arrange what shows on Today.)
  - Section rows (each: drag handle ≡ · title · subtitle · Toggle):
    - 370:1602 "Ô theo dõi nhanh" (Quick tracking tiles) / 370:1603 "Bú, ngủ, tã, hút sữa, tăng trưởng" (Feeding, sleep, diaper, pumping, growth) — Toggle ON
    - 370:1611 "Nhắc việc sắp tới" (Upcoming reminders) / 370:1612 "3 nhắc đang bật" (3 reminders on) — Toggle ON
    - 370:1647 "Nhịp trong ngày" (Daily rhythm) / 370:1648 "Biểu đồ 24 giờ" (24-hour chart) — Toggle ON
  - 370:1650 "Ô theo dõi hiển thị" (Visible tracking tiles)
  - Chips (all selected, check icon, mint-soft bg, mint-text): "Bú bình" (Bottle), "Bú mẹ" (Breastfeed), "Ngủ" (Sleep), "Thay tã" (Diaper), "Hút sữa" (Pumping), "Tăng trưởng" (Growth)
  - Buttons: Secondary "Đặt lại" (Reset) · Primary "Xong" (Done)

**Layout / components**
- Scrim (rgba(12,23,25,0.32)) full frame; Sheet white, top radius 28, top y=286, px16 pb34, gap 12.
- SheetHeader (37:293): "Bottom-sheet header: grabber, title (24/32 semibold), close (44px, label “Đóng”)." (Đóng = Close)
- Rows: local frames "Row · Ô theo dõi nhanh", "Row · Nhắc việc sắp tới", "Row · Nhịp trong ngày" inside "Group" (white, radius 16). Each has "handle" (3 bars 14x2 ink-muted = drag handle) and Toggle (rendered as image; visually ON).
- Toggle (23:262): "iOS switch. On: mint-deep track. Off: separator track. White knob."
- Tile chips: local frames (not a Chip component), Icon/check 14 + SemiBold 13 mint-text on mint-soft #e6f7f5.
- Button (8:33) description: "Pill button, label = 1–2-word verb (Lưu, Bắt đầu, Kết thúc, Chỉnh giờ, Mời, Thử lại). Primary h56 mint-deep/on-mint-deep, one per screen in the thumb zone. Secondary h52 surface-2. Tinted for secondary actions. Plain for text buttons (≥44 tap). Apple: use Apple’s official button in production. Press: scale 0.97 in duration-tap. Disabled: opacity 40%. Stretch to fill width for block buttons." (Lưu=Save, Bắt đầu=Start, Kết thúc=End, Chỉnh giờ=Adjust time, Mời=Invite, Thử lại=Retry)
- Background TabDock: Today active; tabs Today/Memories/Care/Family; no Me tab.

**Visual:** Sheet covers bottom ~65% of screen. Three section rows with hamburger-style drag handles on the left and green (ON) switches on the right. Below, 6 pill chips in two lines, all mint with checkmarks (all selected). Bottom: two equal buttons — light "Đặt lại" (h52) and teal "Xong" (h56). Close X teal at top-right of sheet.

**Navigation**
- Opened from "Tuỳ chỉnh" pill on Hôm nay (inferred).
- Drag handle → reorder the 3 sections on Today (stated in body copy "kéo để sắp xếp").
- Toggles → show/hide each section on Today (stated "Bật, tắt").
- Chips → choose which care tiles are visible (inferred: toggle selected/unselected).
- "Đặt lại" → reset to default layout (inferred). "Xong" → save and close (inferred). X → close (inferred: discard?).

**Notes / not shown**
- No unselected chip state shown; no OFF toggle shown; no minimum-tile rule (e.g. can all tiles be hidden?).
- Tile chips cannot be reordered here (no handles) — tile order not customizable (inferred).
- Whether settings are per-user or per-family / per-baby not stated.
- Section subtitle "3 nhắc đang bật" matches ReminderPeek "Nhắc việc · 3".
- Annotation copy-pasted from Hôm nay.

### 370:1898 — CS Tôi (từ avatar)

**Annotation:** none.

**Text (reading order)**
- StatusBar "9:41" / "•••"
- Top: back button (white circle, Icon/back), no title in bar.
- 370:1904 "Tôi" (Me) — large title 32.
- Profile row: Avatar circle "M" (peach-soft #ffe3da, 28 SemiBold); 370:1910 "Mai"; 370:1911 "mai.nguyen@gmail.com"; 370:1912 "Mẹ · chủ hồ sơ của Teddy, Na" (Mom · profile owner of Teddy, Na); chevron.
- Storage card: 370:1918 "Dung lượng" (Storage) · 370:1919 "3,2 GB / 10 GB"; stacked bar (mint-deep segment ≈ Teddy, peach segment ≈ Na, separator track); legend 370:1924 "● Teddy 2,4 GB" (mint-text) · 370:1925 "● Na 0,8 GB" (ink); 370:1926 "Dùng chung cho tất cả các bé của bạn" (Shared across all your babies).
- Group 1 rows:
  - [Icon/cake] "Hồ sơ các bé" (Babies' profiles) / "Teddy, Na" · value "2" · chevron
  - [Icon/today (sun)] "Thông báo" (Notifications) · value "Bật" (On) · chevron
  - [Icon/globe] "Giao diện" (Appearance) · value "Tự động" (Automatic) · chevron
- Group 2 rows:
  - [Icon/link] "Đã chia sẻ ra ngoài" (Shared externally) / "2 liên kết đang mở" (2 links open) · chevron
  - [Icon/lock] "Tài khoản & đăng nhập" (Account & sign-in) / "Email, Apple, đổi máy" (Email, Apple, change device) · chevron
  - [Icon/mail] "Trợ giúp & liên hệ" (Help & contact) · chevron
- 370:1969 "Đăng xuất" (Sign out) — error red #a12b32, own white card.

**Layout / components**
- Frame 375x812, bg cloud, radius 40 (others 44), no border. Content absolute pt52 px16 pb120. NO TabDock / NavBar on this screen (pushed screen with back).
- All rows are local frames (not a ListRow component); only Icon/* + StatusBar instances. Icon descriptions are generic placeholders ("Line icon (24px, 1.8 stroke) — placeholder; production uses SF Symbols.").
- Storage card has shadow-tile; groups white radius 18.

**Visual:** Back chevron in white circle top-left; big "Tôi" title; large peach circle avatar with "M"; chevron at right of profile. Storage bar mostly grey with ~22% teal + ~7% peach. Thông báo row uses a sun (today) icon — likely placeholder for a bell. Sign-out in red text in separate card.

**Navigation**
- Reached by tapping UserAvatar "M" on Hôm nay (frame name "từ avatar" = from avatar). Back → Hôm nay (inferred).
- Profile row → edit own profile (inferred).
- "Hồ sơ các bé" → list of baby profiles (inferred).
- "Thông báo" → notification settings (inferred; value "Bật" = notifications on). Relevant to reminders permission (1e).
- "Giao diện" → appearance (Auto/Light/Night) (inferred).
- "Đã chia sẻ ra ngoài" → external share links management (inferred).
- "Tài khoản & đăng nhập" → account/sign-in methods, change device (inferred).
- "Trợ giúp & liên hệ" → help/contact (inferred).
- "Đăng xuất" → sign out (inferred; confirmation not shown).

**Notes / not shown**
- No language picker row here (G-081 language picker in Tôi per repo commit history — not in this frame).
- No notification-settings sub-screen in this section; no reminders entry here.
- Storage quota 10 GB, per-baby breakdown; plan/upgrade not shown.
- Thông báo icon is Icon/today (sun) — probably wrong icon.
- Corner radius 40 vs 44 on sibling frames; no border.

### 370:1971 — CS Chăm sóc

**Annotation:** none.

**Text (reading order)**
- StatusBar "9:41" / "•••"
- Top: UserAvatar "M" (peach pill); BabySwitcher name "Teddy" (default, + chevron); spacer; "night" button (white circle, Icon/today = sun icon, 18px).
- 370:1980 "Chăm sóc" (Care) — Bold 32 title.
- Search field: [Icon/search] placeholder 370:1984 "Tìm trong Chăm sóc…" (Search in Care…)
- Section 370:1986 "Chăm hằng ngày" (Daily care):
  - Tile · Nhắc nhở: [Icon/clock on mint-soft] "Nhắc nhở" (Reminders) / "3 nhắc đang bật" (3 reminders on)
  - Tile · Thống kê: [Icon/sliders on sleep-soft] "Thống kê" (Statistics) / "Bú, ngủ theo ngày" (Feeding, sleep by day)
  - Tile · Lịch sử: [Icon/journal on diaper-soft] "Lịch sử" (History) / "Mọi lần đã ghi" (Every logged entry)
  - Tile · Tăng trưởng: [Icon/ruler on growth-soft] "Tăng trưởng" (Growth) / "Cân nặng, chiều dài" (Weight, length)
- Section 370:2018 "Sớm ra mắt" (Coming soon) [layer name "Section · Hiểu con hơn" = "Understand your child better"]:
  - Tile · Wonder Week: badge "Sớm ra mắt"; "Wonder Week" / "Giai đoạn phát triển dự kiến" (Expected developmental phases)
  - Tile · Thẻ theo tuổi: badge "Sớm ra mắt"; "Thẻ theo tuổi" (Age-based cards) / "Gợi ý theo tuổi của bé" (Suggestions by baby's age)
  - Tile · Mốc phát triển: badge "Sớm ra mắt"; "Mốc phát triển" (Milestones) / "Ghi lại lần đầu của con" (Record your child's firsts)
  - Tile · Thư viện chăm bé: badge "Sớm ra mắt"; "Thư viện chăm bé" (Baby-care library) / "Bài viết được chuyên môn rà soát" (Expert-reviewed articles)
  - Tile · Ăn dặm: badge "Sớm ra mắt"; "Ăn dặm" (Weaning/solids) / "Nhật ký & thư viện ăn dặm" (Solids diary & library)
- Section 370:2052 "Cài đặt" (Settings):
  - Row · Tuỳ chỉnh theo dõi: [Icon/sliders] "Tuỳ chỉnh theo dõi" (Customize tracking) / "Chọn loại hoạt động cần ghi" (Choose activity types to log) · chevron
  - Row · Thông báo: [Icon/alert] "Thông báo" (Notifications) / "Nhắc nhở, gia đình" (Reminders, family) · chevron
- TabDock.

**Layout / components**
- Frame 375x1281 (scroll), radius 40, bg cloud. Content pt52 px16 gap14 pb120.
- Search "Field ·" (local, white box, control-border #7e959a, radius 14).
- Tiles = local frames ("Tile · …", 165.5 wide, radius 20, shadow-card). Active tiles white bg; coming-soon tiles surface-2 bg, icon 50% opacity, title/subtitle 60% opacity, "Sớm ra mắt" pill badge top-right (11px SemiBold).
- Settings rows local, in white Group radius 16.
- TabDock / NavBar v1.0.1: tabs in order Today (icon only), Memories (icon only), Care (ACTIVE — white pill, Icon/care + label "Chăm sóc"), Family (icon only). 4 tabs, NO Me tab. QuickLogButton (+) to the right. NavBar px4 (vs p6 on Today) and inactive tabs 48w.

**Visual:** Search bar outlined; 2x2 grid of white daily-care tiles with tinted icon squares; five greyed "coming soon" tiles in 2-col grid (last alone); settings list. Header "night" button shows a sun icon (white circle) — differs from Today's moon icon on surface-2.

**Navigation**
- Tile Nhắc nhở → reminder list CS 1a (370:2365) (inferred).
- Thống kê → stats; Lịch sử → history timeline; Tăng trưởng → growth (inferred).
- Coming-soon tiles → not tappable / or a "coming soon" note (inferred, not stated).
- Tuỳ chỉnh theo dõi → choose which activity types to log (inferred; relates to Tuỳ chỉnh Hôm nay tile chips).
- Thông báo → notification settings (reminders, family) (inferred).
- Search → search within Care (inferred).
- Avatar → Tôi; BabySwitcher → switch baby; sun/night → Night care toggle (inferred).

**Notes / not shown**
- Header night toggle uses Icon/today (sun) on white here vs Icon/sleep (moon) on surface-2 on Hôm nay — inconsistent.
- BabySwitcher shows "Teddy" only (no age) vs "Teddy · 3 tuần" on Hôm nay.
- Section layer named "Hiểu con hơn" but visible title "Sớm ra mắt".
- No search results state.

### 370:2174 — CS Chăm sóc · người chăm

(Care tab as seen by a caregiver — "người chăm" = caregiver role, e.g. nanny "Cô Lan".)

**Annotation:** none.

**Text (reading order):** identical to 370:1971 except:
- UserAvatar 370:2178 "L" (diaper-soft #e7f4e3 bg instead of peach) — caregiver Lan.
- Tile · Nhắc nhở subtitle 370:2198 "2 nhắc giao cho bạn" (2 reminders assigned to you) — instead of "3 nhắc đang bật".
- "Chăm hằng ngày" grid has only 3 tiles: Nhắc nhở, Thống kê ("Bú, ngủ theo ngày"), Lịch sử ("Mọi lần đã ghi"). Tăng trưởng tile is ABSENT.
- "Sớm ra mắt" section: same 5 coming-soon tiles (Wonder Week, Thẻ theo tuổi, Mốc phát triển, Thư viện chăm bé, Ăn dặm).
- "Cài đặt": same 2 rows — "Tuỳ chỉnh theo dõi" / "Chọn loại hoạt động cần ghi"; "Thông báo" / "Nhắc nhở, gia đình".
- Header: BabySwitcher "Teddy", sun "night" button; title "Chăm sóc"; search "Tìm trong Chăm sóc…".

**Layout / components**
- Same structure as 370:1971 (local tiles/rows). Frame 375x1281, radius 40.
- TabDock / NavBar v1.0.1 with only 3 tabs: Tab/Today (icon), Tab/Care (ACTIVE, label "Chăm sóc"), Tab/Family (icon). Tab/Memories is ABSENT for the caregiver. No Me tab. QuickLogButton present.

**Visual:** Same look; avatar circle pale green with "L"; nav pill shows sun, active "Chăm sóc" pill, people icon.

**Navigation (inferred):** Nhắc nhở → reminders list filtered/scoped to reminders assigned to this caregiver; other rows as in 370:1971.

**Notes / not shown**
- Role-based differences: caregiver sees no Memories tab and no Growth tile; reminder count reflects assigned recipients ("giao cho bạn") — ties to recipients step 1d.
- Whether caregiver can create/edit reminders, or Customize tracking / Notifications rows are the same scope, not stated.
- Caregiver still sees "Sớm ra mắt" tiles incl. "Mốc phát triển" (memories-like) — possibly inconsistent with no-Memories rule.

### Compared with the current app (cluster 8)
Current: `TodayScreen` (`apps/mobile/lib/features/today/today_screen.dart`), header `BabyHeader` / `NightCareToggle` (`features/home/home_shell.dart`), tabs `ClTab {today, memories, family, me}` (`core/widgets/cl_navigation.dart`), Me tab `/me` (`features/me/me_screen.dart`).
New or different:
1. **Tab model (NavBar v1.0.1):** Today · Memories · **Care** · Family; Me tab removed. Caregiver: Today · Care · Family. New Care branch/route (e.g. `/care`) and new `Icon/care`. Stats, history, growth and reminders move under Care (today they are `/today/...`).
2. **Today header:** new **user avatar** (initial on peach for Mẹ; diaper-soft for Cô Lan) at the far left, before the BabySwitcher; tap → "Tôi" pushed screen. Today has no user avatar in the header.
3. **"Tuỳ chỉnh" pill** next to the "Hôm nay" title → new **"Tuỳ chỉnh Hôm nay"** sheet: show/hide + drag-to-reorder the three Today sections (Ô theo dõi nhanh · Nhắc việc sắp tới · Nhịp trong ngày) and pick visible tiles (Bú bình, Bú mẹ, Ngủ, Thay tã, Hút sữa, Tăng trưởng); "Đặt lại" / "Xong". Nothing like this exists (tiles come only from `baby.trackers`, chosen at setup). Needs a stored Today layout (scope — per user, per baby or per device — not stated) and Today rendering sections in that order. The Care tab's settings row "Tuỳ chỉnh theo dõi · Chọn loại hoạt động cần ghi" looks like the post-setup editor for `baby.trackers` (inferred) — two different settings (what is tracked vs what Today shows) that must be kept distinct.
4. **"Tôi" as a pushed screen** (no dock): profile row "Mai / mai.nguyen@gmail.com / Mẹ · chủ hồ sơ của Teddy, Na", storage card "Dung lượng 3,2 GB / 10 GB" with **per-baby breakdown** (Teddy 2,4 GB · Na 0,8 GB) and "Dùng chung cho tất cả các bé của bạn", rows Hồ sơ các bé (2) · Thông báo (Bật) · Giao diện (Tự động) · Đã chia sẻ ra ngoài (2 liên kết đang mở) · Tài khoản & đăng nhập (Email, Apple, đổi máy) · Trợ giúp & liên hệ · Đăng xuất. The current Me screen has most of these (account, appearance, babies, notifications, help, storage, shared-out links, sign out) but also **Language** (G-081) and messages, which this frame omits — keep them (inferred) unless the owner drops them. Per-baby storage split may need new data.
5. **New "Chăm sóc" tab screen:** title "Chăm sóc", search field "Tìm trong Chăm sóc…" (search scope not designed), section "Chăm hằng ngày" tiles Nhắc nhở ("3 nhắc đang bật") · Thống kê ("Bú, ngủ theo ngày") · Lịch sử ("Mọi lần đã ghi") · Tăng trưởng ("Cân nặng, chiều dài"); section "Sớm ra mắt" with 5 disabled teaser tiles (Wonder Week, Thẻ theo tuổi, Mốc phát triển, Thư viện chăm bé, Ăn dặm); section "Cài đặt" rows Tuỳ chỉnh theo dõi · Thông báo ("Nhắc nhở, gia đình"). Where "Thống kê" lands (feeding vs sleep chooser) is not designed — today stats are reached only from History filters.
6. **Caregiver Care tab:** no Tăng trưởng tile, reminder tile "2 nhắc giao cho bạn" (needs reminder recipients, cluster 9), dock without Memories.
7. Header inconsistency to resolve: Today uses a moon toggle on surface-2; Care uses a sun icon on white.
8. Today body (tiles, ReminderPeek, DayRhythm, annotation) is otherwise unchanged from 19 Hôm nay.

---

## Cluster 9 — Label 370:1247 (verbatim): "Nhắc bú/ngủ có quy tắc"
(Rule-based feeding/sleep reminders.)

Nine frames: list (1a), create flow in 3 steps (1b type + mode → 1c / 1c2 timing → 1d recipients), save + permission (1e), lock-screen notification (1f), in-app due sheet (1g) and the handled state (1h). Only 1g carries an annotation, and it is copy-pasted from Hôm nay.

### 370:2365 — CS 1a · Nhắc nhở

**Annotation:** none.

**Text (reading order)**
- StatusBar "9:41" / "•••"
- Top: back button (white circle, Icon/back); spacer; BabySwitcher "Teddy" + chevron (right-aligned).
- 370:2372 "Nhắc nhở" (Reminders) — Bold 28.
- Segmented (2 segments): "Theo quy tắc" (Rule-based) — SELECTED (white pill, SemiBold ink) · "Một lần" (One-time) — unselected (muted).
- Reminder list (white group):
  - Row · Nhắc bú: [Icon/feed on bottle-soft] "Nhắc bú" (Feeding reminder) / "3 giờ sau lần bú gần nhất" (3 hours after the latest feed) / status pill [clock] "Tiếp theo 14:45" (Next 14:45, mint-soft/mint-text) · Toggle ON
  - Row · Nhắc chuẩn bị ngủ: [Icon/sleep on sleep-soft] "Nhắc chuẩn bị ngủ" (Get-ready-for-sleep reminder) / "Cố định 09:00 · 13:00 · 19:30" (Fixed 09:00 · 13:00 · 19:30) / pill [clock] "Tiếp theo 13:00" (Next 13:00) · Toggle ON
  - Row · Nhắc thay tã: [Icon/diaper on diaper-soft] "Nhắc thay tã" (Diaper-change reminder) / "2 giờ 30 phút sau lần thay gần nhất" (2 h 30 min after the latest change) / pill [clock, muted] "Đang tạm dừng" (Paused, surface-2/ink-muted) · Toggle OFF
- 370:2409 "Người nhận: bạn, Ba Tuấn, Cô Lan" (Recipients: you, Dad Tuấn, Ms. Lan) — 13 Medium muted, below the list.
- Primary Button "Thêm nhắc" (Add reminder).

**Layout / components**
- Frame 375x812, radius 40; pushed screen, NO TabDock. Content pt52 px16 gap14.
- Segmented: local frame "Segmented" (surface-2 track radius 14, p4; selected segment white radius 10).
- Rows: local "Row · …" frames with tinted icon square (radius 12), title SemiBold 15, rule line 12 Medium muted, status pill; Toggle (23:262) instance rendered as image (ON = mint-deep track, OFF = separator track).
- Toggle description: "iOS switch. On: mint-deep track. Off: separator track. White knob."
- Button (8:33) Primary h56 full width.

**Visual:** Back arrow left, Teddy chip right. Segmented control with "Theo quy tắc" active. Three reminder rows; first two toggles teal ON, diaper toggle grey OFF with grey "Đang tạm dừng" pill. Recipient line grey text. Big teal "Thêm nhắc" button directly under (not pinned at bottom). Lots of empty space below.

**Navigation / rule model**
- Reached from Care tile "Nhắc nhở" / ReminderPeek on Hôm nay (inferred).
- Back → previous screen. BabySwitcher → reminders are per-baby (inferred: switcher scopes list to Teddy).
- Segmented "Theo quy tắc" vs "Một lần": two reminder families — rule-based recurring (this flow) vs one-time dated reminders (e.g. vaccine "Tiêm 6 trong 1" on ReminderPeek) (inferred). "Một lần" tab content not shown.
- Rule model visible here:
  - Type Feeding: interval "after last log" (3 h after latest feed) → next time computed from last log (Tiếp theo 14:45).
  - Type Sleep prep: "fixed time" schedule, multiple times per day (09:00 · 13:00 · 19:30) → next 13:00.
  - Type Diaper: "after last log" 2 h 30 min; toggled OFF → status "Đang tạm dừng" (Paused). Toggle OFF = pause (not delete).
- Toggle → enable/pause a reminder (inferred from paused pill).
- Row tap → edit reminder (inferred; likely opens 1c/1c2 time setup).
- "Người nhận" line → recipients shown at list level (single line for all reminders?) — possibly per-reminder in 1d; tap behavior not stated.
- "Thêm nhắc" → CS 1b · Chọn loại nhắc (370:2444) (inferred).

**Notes / not shown**
- Recipients shown once for the whole list, while 1d sets recipients per reminder (inferred) — ambiguity: global vs per-reminder recipients.
- No swipe-to-delete / delete control; no empty state; no "Một lần" tab content; no quiet hours displayed here.
- Primary button label "Thêm nhắc" is 2 words — matches Button rule.
- No count badge although Care tile says "3 nhắc đang bật" while only 2 are ON here (diaper paused) — inconsistency (3 enabled vs 2 ON + 1 paused).

### 370:2444 — CS 1b · Chọn loại nhắc

**Annotation:** none.

**Text (reading order)**
- StatusBar "9:41" / "•••"
- Top: close button (white circle, Icon/close — layer still named "back"); spacer; BabySwitcher "Teddy" + chevron.
- 370:2451 "Nhắc mới" (New reminder) — Bold 28.
- 370:2452 "Bạn muốn nhắc việc gì?" (What do you want to be reminded about?)
- Type grid (2x2 option cards):
  - Opt · Bú: [Icon/feed on bottle-soft] "Bú" (Feeding) — SELECTED (mint-soft bg, 2px mint-deep border, Icon/check top-right)
  - Opt · Ngủ: [Icon/sleep on sleep-soft] "Ngủ" (Sleep)
  - Opt · Thay tã: [Icon/diaper on diaper-soft] "Thay tã" (Diaper change)
  - Opt · Hút sữa: [Icon/drop on pump-soft] "Hút sữa" (Pumping)
- 370:2479 "Cách nhắc" (How to remind) — Bold 17 section title.
- Radio rows:
  - Row · Sau lần ghi gần nhất — radio SELECTED (filled mint-deep), row bg mint-soft: "Sau lần ghi gần nhất" (After the latest log) / "Ví dụ: 3 giờ sau lần bú gần nhất" (E.g. 3 hours after the latest feed)
  - Row · Giờ cố định — radio unselected (grey ring), white bg: "Giờ cố định" (Fixed times) / "Ví dụ: 09:00, 13:00, 19:30 mỗi ngày" (E.g. 09:00, 13:00, 19:30 every day)
- Primary Button "Tiếp tục" (Continue).

**Layout / components**
- Frame 375x812, radius 40; no TabDock. Step 1 of a create flow (no progress indicator).
- Option cards: local frames "Opt · …" (165.5w, radius 18; unselected white + 1px separator border; selected mint-soft + 2px mint-deep border + check).
- Radio rows: local frames with "radio" image (22px), not a RadioRow component instance.
- Button (8:33) primary h56, label "Tiếp tục".

**Visual:** X top-left, Teddy chip top-right. "Bú" card highlighted with teal outline and check. "Sau lần ghi gần nhất" row tinted mint with filled teal radio; "Giờ cố định" white with empty radio. Teal "Tiếp tục" button under options (not bottom-pinned).

**Navigation / rule model**
- Opened by "Thêm nhắc" on 1a (inferred). X → cancel creation (inferred).
- Reminder types available: Bú (feeding), Ngủ (sleep), Thay tã (diaper), Hút sữa (pumping). Single-select (inferred from one check).
- Trigger mode ("Cách nhắc"): "Sau lần ghi gần nhất" (interval after last log of that type) vs "Giờ cố định" (fixed daily times). Single-select radio.
- "Tiếp tục" → 1c (370:2517, after-last-log timing) when "Sau lần ghi gần nhất" selected; → 1c2 (370:2584, fixed times) when "Giờ cố định" selected (inferred from frame names).

**Notes / not shown**
- Growth (Tăng trưởng) and breast vs bottle split not offered as reminder types; "Bú" covers both feeds (inferred).
- Sleep reminder in 1a is named "Nhắc chuẩn bị ngủ" (sleep-prep) — type Ngủ + fixed times.
- No reminder title/name field, no note field.
- Whether a type+mode combination can be duplicated (e.g., two feed reminders) not stated.

### 370:2517 — CS 1c · Đặt thời gian · sau lần ghi

**Annotation:** none.

**Text (reading order)**
- StatusBar "9:41" / "•••"
- Top: back (Icon/back); spacer; BabySwitcher "Teddy" + chevron.
- 370:2524 "Bước 2/3" (Step 2/3)
- 370:2525 "Nhắc bú" (Feeding reminder) — Bold 28.
- Card "Interval":
  - 370:2527 "Nhắc sau mỗi" (Remind after every)
  - Stepper: "−" button · value 370:2532 "3 giờ 00 phút" (3 h 00 min, Bold 28) · "+" button
  - Preset chips: "2 giờ" (2 h) · "2 giờ 30" (2 h 30) · "3 giờ" (3 h) — SELECTED (mint-deep bg, white text) · "3 giờ 30" (3 h 30)
  - 370:2545 "tính từ lần bú gần nhất (bú bình hoặc bú mẹ)" (counted from the latest feed (bottle or breast))
- Card "Preview" (mint-soft, mint-text):
  - 370:2547 "Ví dụ hôm nay" (Example today)
  - 370:2548 "Bú lúc 11:45 → nhắc lúc 14:45" (Fed at 11:45 → reminder at 14:45)
  - 370:2549 "Ghi lần bú mới thì giờ nhắc tự lùi theo." (Log a new feed and the reminder time shifts automatically.)
- Settings group:
  - Row · Không nhắc ban đêm: "Không nhắc ban đêm" (No reminders at night) / "22:00 – 06:00" · Toggle OFF
  - Row · Ngày áp dụng: "Ngày áp dụng" (Days applied) / "Mỗi ngày" (Every day) · chevron
- Primary Button "Tiếp tục" (Continue).

**Layout / components**
- Frame 375x812, radius 40; no TabDock.
- Stepper: local frame "stepper" ("-" and "+" surface-2 radius 12 buttons, value centered) — not a Stepper component instance.
- Chips: local frames named by value; selected = mint-deep/on-mint-deep, unselected = surface-2/ink.
- Toggle (23:262) instance, OFF state (separator track).
- Button (8:33) primary.

**Visual:** White interval card with large "3 giờ 00 phút" between − and + square buttons; four preset pills with "3 giờ" filled teal. Mint preview card with bold teal example. Night-quiet toggle grey OFF. "Ngày áp dụng" row with chevron.

**Navigation / rule model**
- From 1b with type=Bú + mode "Sau lần ghi gần nhất". Back → 1b.
- Interval: stepper −/+ (step size not stated; presets in 30-min increments 2h–3h30) — "after last log" interval measured from the latest feed of EITHER bottle or breast (stated).
- Next due = last feed time + interval; logging a new feed reschedules ("tự lùi theo") (stated).
- Quiet hours: "Không nhắc ban đêm" 22:00–06:00 toggle (OFF here); whether range is editable not shown (no chevron).
- Repeat days: "Ngày áp dụng" → day-of-week picker (inferred; value "Mỗi ngày").
- "Tiếp tục" → step 3/3 = 1d Người nhận (370:2660) (inferred).

**Notes / not shown**
- Step count "Bước 2/3" implies 1b = step 1 (but 1b shows no step label), 1d = step 3.
- Stepper min/max/increment not stated; behaviour when no feed has been logged yet (no anchor) not specified; what happens if a reminder falls in quiet hours (skip vs defer to 06:00) not stated.
- Whether a running breastfeed/ongoing timer counts as "latest feed" (start vs end) not stated — preview uses "Bú lúc 11:45".
- Ngày áp dụng picker screen not in this section.

### 370:2584 — CS 1c2 · Đặt thời gian · giờ cố định

**Annotation:** none.

**Text (reading order)**
- StatusBar "9:41" / "•••"
- Top: back (Icon/back); spacer; BabySwitcher "Teddy" + chevron.
- 370:2591 "Bước 2/3" (Step 2/3)
- 370:2592 "Nhắc chuẩn bị ngủ" (Get-ready-for-sleep reminder) — Bold 28.
- Card "Times":
  - 370:2594 "Giờ nhắc mỗi ngày" (Reminder times each day)
  - Time row: "09:00" (Bold 20) · "Giấc sáng" (Morning nap) · [Icon/close ×]
  - Time row: "13:00" · "Giấc trưa" (Midday nap) · [×]
  - Time row: "19:30" · "Giấc đêm" (Night sleep) · [×]
  - Add row (dashed border): [Icon/plus] "Thêm giờ" (Add time, mint-text)
- 370:2613 "Ngày trong tuần" (Days of the week)
- Day pills (all 7 SELECTED, mint-deep/white): "T2" (Mon) · "T3" (Tue) · "T4" (Wed) · "T5" (Thu) · "T6" (Fri) · "T7" (Sat) · "CN" (Sun)
- Banner (surface-2, Icon/globe): 370:2632 "Nhắc theo giờ của bé (GMT+7). Khi đi xa, giờ nhắc vẫn giữ theo nơi bé ở." (Reminders follow the baby's time (GMT+7). When travelling, reminder times stay with where the baby lives.)
- Primary Button "Tiếp tục" (Continue).

**Layout / components**
- Frame 375x812, radius 40; no TabDock.
- Time rows: local frames "t" (surface-2 radius 14), each with time, auto label (nap name), remove ×. Add row: dashed control-border.
- Day pills: local frames, flex equal width, all selected.
- Banner: local frame (not an InfoBanner component instance).
- Button (8:33) primary.

**Visual:** White card with three grey time rows and a dashed "+ Thêm giờ" row; seven teal day pills; grey info banner with globe icon; teal "Tiếp tục".

**Navigation / rule model**
- From 1b with mode "Giờ cố định" (here with type Ngủ → named "Nhắc chuẩn bị ngủ"). Back → 1b.
- Fixed schedule: list of daily times, each optionally labelled (Giấc sáng/trưa/đêm — labels appear auto-derived from time of day, inferred); × removes a time; "Thêm giờ" → time picker (inferred, not shown).
- Repeat days: weekday multi-select T2…CN (all on = every day).
- Time zone rule (stated): reminders are scheduled in the baby's time zone (GMT+7) and do not shift when the user travels.
- "Tiếp tục" → 1d Người nhận (inferred).

**Notes / not shown**
- No quiet-hours toggle on fixed-time variant (only on 1c); 1c uses "Ngày áp dụng" row → picker while 1c2 uses inline day pills — inconsistent repeat-day UI between the two modes.
- Whether nap labels are editable/auto not stated; max number of times not stated; time picker not shown.
- Baby's timezone source (family/baby setting) not shown; the GMT+7 rule presumably also applies to 1c but not stated there.

### 370:2660 — CS 1d · Người nhận

**Annotation:** none.

**Text (reading order)**
- StatusBar "9:41" / "•••"
- Top: back (Icon/back); spacer; BabySwitcher "Teddy" + chevron.
- 370:2667 "Bước 3/3" (Step 3/3)
- 370:2668 "Ai sẽ nhận nhắc?" (Who will receive the reminder?) — Bold 28.
- Member list (white group), each: avatar initial · name / role · checkbox:
  - Row · Mai (bạn): avatar "M" (peach) · "Mai (bạn)" (Mai (you)) / "Bố mẹ" (Parent) · CHECKED
  - Row · Ba Tuấn: avatar "T" (sleep-soft) · "Ba Tuấn" (Dad Tuấn) / "Bố mẹ" (Parent) · CHECKED
  - Row · Cô Lan: avatar "L" (diaper-soft) · "Cô Lan" (Ms. Lan) / "Người chăm" (Caregiver) · CHECKED
  - Row · Bà nội: avatar "B" (surface-2, muted) · "Bà nội" (Grandma, paternal — muted text) / "Gia đình · chỉ xem" (Family · view only) · UNCHECKED (empty outlined box, appears disabled)
- Banner (mint-soft, Icon/family): 370:2705 "Chỉ bố mẹ và người chăm nhận được nhắc. Ai ghi hoạt động trước, nhắc sẽ tự tắt với mọi người." (Only parents and caregivers can receive reminders. Whoever logs the activity first, the reminder turns off automatically for everyone.)
- Summary card (surface-2): 370:2707 "Nhắc bú" (Feeding reminder) / 370:2708 "Mỗi 3 giờ sau lần bú gần nhất · cả ngày · 3 người nhận" (Every 3 hours after the latest feed · all day · 3 recipients)
- Primary Button "Lưu nhắc" (Save reminder).

**Layout / components**
- Frame 375x812, radius 40; no TabDock.
- Rows: local frames "Row · <name>" with "av" initial pill, "tx", and "check" box (checked: mint-deep fill + white check, radius 7; unchecked: 1.5px control-border outline). Not a component instance.
- Banner + Summary: local frames.
- Button (8:33) primary "Lưu nhắc".

**Visual:** Four member rows; first three with teal filled checkboxes; Bà nội row greyed (muted name, grey avatar) with empty checkbox — disabled-looking. Mint banner with people icon. Grey summary card. Teal save button.

**Navigation / rule model**
- From 1c / 1c2 "Tiếp tục". Back → previous step.
- Recipients: multi-select from family members of this baby. Eligibility rule (stated): only roles "Bố mẹ" (parent) and "Người chăm" (caregiver) can receive reminders; "Gia đình · chỉ xem" (family view-only) members are shown but not selectable.
- Dedup/auto-resolve rule (stated): whoever logs the activity first → reminder is turned off for everyone.
- Summary composes: type · interval rule · "cả ngày" (all day — i.e. quiet hours off) · N recipients.
- "Lưu nhắc" → saves; → 1e Đã lưu · xin quyền thông báo (370:2738) (inferred).

**Notes / not shown**
- Recipients are per-reminder here, while 1a shows one "Người nhận" line under the list.
- "cả ngày" in summary corresponds to "Không nhắc ban đêm" OFF in 1c.
- Default selection (all eligible checked?) not stated; minimum 1 recipient rule not stated.
- What a non-selected parent sees (reminder visible but no notification?) not stated.
- Caregiver view 370:2174 "2 nhắc giao cho bạn" — implies caregiver is recipient of a subset.

### 370:2738 — CS 1e · Đã lưu · xin quyền thông báo

**Annotation:** none.

**Text (reading order)**
- Background (dimmed by scrim): identical copy of 1a list — back, BabySwitcher "Teddy"; "Nhắc nhở"; Segmented "Theo quy tắc" (selected) / "Một lần"; rows "Nhắc bú" / "3 giờ sau lần bú gần nhất" / "Tiếp theo 14:45" (ON); "Nhắc chuẩn bị ngủ" / "Cố định 09:00 · 13:00 · 19:30" / "Tiếp theo 13:00" (ON); "Nhắc thay tã" / "2 giờ 30 phút sau lần thay gần nhất" / "Đang tạm dừng" (OFF); "Người nhận: bạn, Ba Tuấn, Cô Lan"; button "Thêm nhắc".
- Toast (top, ink pill, over header): [Icon/check] 370:2797 "Đã lưu nhắc bú" (Feeding reminder saved)
- System alert (iOS-style, centered):
  - 370:2788 "“Child Life” muốn gửi thông báo" ("Child Life" would like to send notifications)
  - 370:2789 "Để báo đúng giờ nhắc bú, ngủ bạn đã đặt — kể cả khi không mở ứng dụng." (To alert you right on time for the feeding/sleep reminders you set — even when the app isn't open.)
  - Buttons: "Không cho phép" (Don't allow, regular, #007aff) · "Cho phép" (Allow, bold, #007aff)

**Layout / components**
- Frame 375x812, radius 40. Background = 1a content (all local), scrim rgba(12,23,25,0.32).
- "System alert": local mock of iOS permission dialog (270w, rgba(245,245,247,0.96), radius 14) — not a component.
- "Toast": local ink pill (#173d44) with white check icon + SemiBold 14 white text, top 60, centered.

**Visual:** List screen dimmed; dark toast "✓ Đã lưu nhắc bú" at top overlapping the header; iOS-style alert in middle with two blue buttons side by side.

**Navigation / rule model**
- After "Lưu nhắc" on 1d → returns to reminder list (1a) with the new reminder present + success toast (stated by frame name "Đã lưu").
- Notification permission is requested at this moment (after first reminder saved — contextual ask) (stated by frame name "xin quyền thông báo"). The usage/pre-prompt text is the iOS purpose string shown inside the system alert (custom body copy).
- "Cho phép" → grant, reminders delivered via push/local notifications (inferred). "Không cho phép" → denied; fallback (in-app only / settings deep link) not shown.

**Notes / not shown**
- The list after saving still shows the same 3 rules as 1a (the new "Nhắc bú" equals the existing one) — mock reuse; no visual highlight of the newly added row.
- No in-app pre-permission screen (soft ask) — directly the system alert; Android 13 POST_NOTIFICATIONS variant not shown.
- Denied state / banner prompting to enable notifications not shown (Tôi → Thông báo row shows "Bật").
- Toast overlaps the BabySwitcher.
- Alert body is custom copy; on iOS the system alert body can't be customised except via app purpose string (no NSUserNotificationUsageDescription exists on iOS) — copy likely needs a pre-prompt screen instead (implementation note).

### 370:2831 — CS 1f · Thông báo màn hình khoá

**Annotation:** none.

**Text (reading order)**
- StatusBar "9:41" / "•••" (ink on dark bg — barely visible)
- Lock screen: 370:2833 "Thứ Năm, 8 tháng 10" (Thursday, 8 October) · 370:2834 "14:45" (84 Bold white)
- Notification card:
  - Header: [Logo/App Icon 20px] 370:2839 "CHILD LIFE" · 370:2841 "bây giờ" (now)
  - Title 370:2842 "Đến giờ nhắc bú bạn đã đặt" (It's time for the feeding reminder you set)
  - Body 370:2843 "Lần bú gần nhất 11:45 · 3 giờ trước" (Latest feed 11:45 · 3 hours ago)
- Action list (expanded notification actions):
  - 370:2846 "Ghi lần bú" (Log a feed)
  - 370:2848 "Báo lại sau 15 phút" (Remind again in 15 minutes) — snooze
  - 370:2850 "Bỏ qua lần này" (Skip this time) — red (error #a12b32), destructive
- Hint 370:2851 "Chạm giữ để xem tuỳ chọn" (Touch and hold to see options) — white 70%

**Layout / components**
- Frame 375x812, radius 40, gradient #2e525c → #122129 (lock-screen mock). Content pt90 px16 gap10.
- Logo/App Icon (35:239) description: "App icon 1024 full-bleed cho phương án 2 (iOS tự bo góc). Light / Dark / Tinted." (App icon 1024 full-bleed for option 2 (iOS rounds the corners itself). Light / Dark / Tinted.)
- Notification + Actions: local frames, rgba(255,255,255,0.82), radius 22 / 16; actions separated by separator borders.

**Visual:** Dark teal lock screen, big white clock 14:45, empty space, then a frosted notification card and a frosted action menu (as if long-pressed), hint text below.

**Navigation / rule model**
- Fires at 14:45 = last feed 11:45 + 3 h interval (matches 1c preview).
- Lock-screen content: title states reminder type; body states last log time + elapsed. No baby name in the notification (privacy-friendly; inferred intentional).
- Actions (long-press): "Ghi lần bú" → opens app to the feed log sheet (inferred; may log directly?) ; "Báo lại sau 15 phút" → snooze 15 min (fixed duration); "Bỏ qua lần này" → skip this occurrence (reminder stays on; next computed from next log/schedule — inferred).
- Tap notification body → opens app to in-app due sheet 1g (inferred).

**Notes / not shown**
- No baby name in notification copy — with multiple babies the user can't tell which baby (gap) — though privacy rule (no child data in logs) does not cover notification text.
- Snooze duration fixed at 15 min; not configurable in the flow.
- Android notification layout not shown; StatusBar text is ink on dark background (mock flaw).
- Whether "Ghi lần bú" logs in background (which feed type/amount?) or opens the app is not stated.

### 370:2860 — CS 1g · Đến giờ nhắc (trong app)

**Annotation:** the frame carries the SAME annotation copy-pasted from 370:1248 Hôm nay ("Thẻ lớn = vừa ghi vừa xem: chạm thẻ → mở sheet ghi mục đó (1 chạm); … “Lịch sử” → dòng thời gian."). Nothing specific to the due sheet.

**Text (reading order)**
- Background (dimmed): Hôm nay screen identical to 370:1248 (812 height) — "M", "Teddy · 3 tuần", night toggle, "Thứ Năm, 8 tháng 10", "Hôm nay", "Tuỳ chỉnh", CareTiles (Bú bình 120 ml / 45 phút trước / Mẹ ghi; Bú mẹ 15 phút / Kết thúc 3 giờ 35 phút trước / Mẹ ghi; Giấc ngủ Đã thức 2 giờ / Dậy lúc 13:05 / Ba ghi; Thay tã Tã ướt / 1h 25p trước / Cô Lan ghi; …), ReminderPeek, DayRhythm, TabDock.
- Sheet (bottom, no grabber/SheetHeader):
  - Header: [Icon/feed on bottle-soft] 370:2933 "Nhắc bú · 14:45" (Feeding reminder · 14:45) / 370:2934 "Đến giờ nhắc bú bạn đã đặt" (It's time for the feeding reminder you set) — Bold 18
  - Banner (surface-2, Icon/clock): 370:2938 "Lần bú gần nhất 11:45 (bú bình 120 ml) · Mẹ ghi" (Latest feed 11:45 (bottle 120 ml) · Mom logged)
  - Primary Button "Ghi lần bú" (Log a feed)
  - 370:2940 "Báo lại sau" (Remind again in)
  - Snooze chips: "10 phút" (10 min) · "15 phút" (15 min) · "30 phút" (30 min) — none selected
  - Plain Button "Bỏ qua lần này" (Skip this time, mint-text, h44)

**Layout / components**
- Frame 375x812, radius 44 with border (same shell as Hôm nay). Scrim + Sheet (white, top radius 28, top 424, px16 pb34, gap14). Sheet has an empty 14px "Frame" at top (no grabber, no close X).
- Button (8:33) Primary "Ghi lần bú"; Button Plain variant "Bỏ qua lần này" (text button ≥44).
- Snooze chips: local frames, equal width, surface-2.
- Background TabDock: Today active; tabs Today/Memories/Care/Family; no Me tab.

**Visual:** Today screen dimmed; white bottom sheet with feed icon, bold title, grey info banner, big teal "Ghi lần bú" button, three grey snooze pills, teal text "Bỏ qua lần này".

**Navigation / rule model**
- Shown when the app is in foreground at due time (frame name "trong app" = in app), or when opening from the notification (inferred).
- Context line shows the anchor log (time, type, amount, who logged) — richer than lock-screen body.
- "Ghi lần bú" → opens feed log sheet (inferred) → after logging, reminder resolves for everyone (per 1d rule) → 1h handled state (inferred).
- "Báo lại sau" 10/15/30 min → snooze; in-app offers 3 durations vs lock-screen only 15 min.
- "Bỏ qua lần này" → skip this occurrence (inferred: dismiss without logging; next reminder computed per rule).
- Dismiss by scrim tap/swipe not indicated (no grabber).

**Notes / not shown**
- Annotation copy-pasted from Hôm nay.
- "Bỏ qua lần này" is red/destructive on lock screen (1f) but mint-text plain here — inconsistent styling.
- Snooze options differ: lock screen 15 min only; in-app 10/15/30.
- Banner says last feed 11:45 "bú bình 120 ml", but background tile shows Bú bình "45 phút trước" (i.e. ~14:00) and Bú mẹ ended 3h35 ago; DayRhythm shows Feed 14:20 and breastfeed 11:30–11:45 — data inconsistent with "last feed 11:45 bottle".
- Multiple recipients: whether the sheet also shows for others / who else was notified not shown.

### 370:3155 — CS 1h · Đã xử lý

**Annotation:** none.

**Text (reading order)**
- StatusBar "9:41" / "•••"
- Top: back (Icon/back); spacer; BabySwitcher "Teddy" + chevron.
- 370:3162 "Nhắc nhở" (Reminders) — Bold 28.
- Banner (mint-soft, Icon/check): 370:3166 "Ba Tuấn đã ghi lần bú lúc 14:52 · nhắc tiếp theo 17:52" (Dad Tuấn logged a feed at 14:52 · next reminder 17:52)
- Segmented: "Theo quy tắc" (selected) · "Một lần"
- Reminder list (only one row):
  - Row · Nhắc bú: [Icon/feed] "Nhắc bú" / "3 giờ sau lần bú gần nhất" / pill [clock] "Tiếp theo 17:52" (Next 17:52) · Toggle ON
- Section 370:3184 "Gần đây" (Recent)
- History rows (reminder occurrence log):
  - [Icon/check] "14:45 · Đã ghi" (14:45 · Logged) / "Ba Tuấn ghi bú bình 110 ml" (Dad Tuấn logged bottle 110 ml)
  - [Icon/clock] "11:45 · Báo lại 15 phút" (11:45 · Snoozed 15 min) / "Mẹ ghi lúc 12:02" (Mom logged at 12:02)
  - [Icon/close] "08:30 · Bỏ qua" (08:30 · Skipped) / "Mẹ" (Mom) — muted text

**Layout / components**
- Frame 375x812, radius 40; no TabDock. All local frames; Toggle (23:262) instance ON.
- History rows: local "Row · <time> · <outcome>" with status icon (check / clock / close), SemiBold 15 title, 12 muted subtitle; skipped row fully muted.

**Visual:** Mint success banner at top; single feed reminder row with teal toggle and "Tiếp theo 17:52"; "Gần đây" list with check, clock, and x icons; the skipped row greyed.

**Navigation / rule model**
- Handled state: the due occurrence at 14:45 was resolved by another recipient (Ba Tuấn) logging a feed at 14:52 → reminder auto-turned-off for everyone (per 1d banner) and next due recomputed = 14:52 + 3 h = 17:52 (after-last-log rule).
- Occurrence outcomes recorded: "Đã ghi" (logged — who + what), "Báo lại 15 phút" (snoozed — then who logged and when), "Bỏ qua" (skipped — by whom).
- Banner likely shown to other recipients after someone else handled the reminder (inferred; possibly transient).
- Row tap → edit reminder; toggle → pause (inferred, as in 1a).

**Notes / not shown**
- List here shows only "Nhắc bú" (the sleep and diaper rules from 1a are missing) — this frame focuses on one reminder (maybe a per-reminder detail view, though titled "Nhắc nhở" with segmented — ambiguous whether this is the list or a detail screen).
- History timing inconsistency: "14:45 · Đã ghi" but subtitle/banner say feed was logged at 14:52; "11:45 · Báo lại 15 phút … Mẹ ghi lúc 12:02" conflicts with 1c/1f where 11:45 was the feed time anchoring the 14:45 reminder (an 11:45 reminder occurrence would imply an 08:45 feed). "08:30 · Bỏ qua" doesn't fit a 3h after-last-log cadence either. Mock data only.
- History retention/length and where "Gần đây" lives (per reminder vs all) not stated.
- Notification to others when someone handles it (silent dismissal of delivered notifications) not specified beyond the 1d banner rule.

### Rule model summary (as designed)
- Two families: "Theo quy tắc" (rule-based recurring) and "Một lần" (one-time; content not shown in this section — ReminderPeek "Tiêm 6 trong 1 · Thứ Bảy 08:30 · còn 2 ngày" looks like a one-time reminder).
- Types: Bú (covers bottle + breast), Ngủ, Thay tã, Hút sữa.
- Modes: "Sau lần ghi gần nhất" (interval from latest log of the type; presets 2h/2h30/3h/3h30 + stepper; auto-reschedules on each new log) and "Giờ cố định" (list of daily times with labels + weekday pills T2–CN).
- Options: "Không nhắc ban đêm" 22:00–06:00 (only on interval mode), "Ngày áp dụng" (interval mode, row → picker), timezone fixed to baby's (GMT+7) (stated on fixed-time mode).
- Recipients: parents + caregivers selectable; view-only family excluded; first person to log resolves the reminder for everyone.
- Create flow: 1a "Thêm nhắc" → 1b type+mode (step 1) → 1c / 1c2 timing (Bước 2/3) → 1d recipients + summary (Bước 3/3) "Lưu nhắc" → 1a with toast "Đã lưu nhắc bú" + iOS notification permission ask.
- Delivery: lock-screen notification "Đến giờ nhắc bú bạn đã đặt" / "Lần bú gần nhất 11:45 · 3 giờ trước" with actions Ghi lần bú / Báo lại sau 15 phút / Bỏ qua lần này; in-app due sheet with Ghi lần bú, snooze 10/15/30 phút, Bỏ qua lần này.
- Pause: toggle OFF → "Đang tạm dừng".
- Handled: banner "<who> đã ghi … · nhắc tiếp theo …" + "Gần đây" occurrence history (Đã ghi / Báo lại / Bỏ qua).
- Role views: caregiver Care tab shows "2 nhắc giao cho bạn", 3 tabs (no Memories), no Growth tile.
- Not shown anywhere: edit/delete reminder, "Một lần" tab, Ngày áp dụng picker, time picker for "Thêm giờ", denied-permission state, Android notification, multi-baby notification copy, empty reminder list.

### Compared with the current app (cluster 9)
Current: `apps/mobile/lib/features/reminders/` — one-time reminders only: `Reminder{id, babyId, title, dueAt, leadMinutes, notifyDevice, createdBy, author, createdAt, done, doneAt, doneBy, doneAuthor}` in `babies/{babyId}/reminders`; list `/today/reminders` titled "Nhắc việc" (Quá hạn / Sắp tới / Đã xong); a **local** notification on the single device that created the reminder (rule "Thông báo chỉ được đặt trên máy tạo nhắc việc"); no notification actions; 8c in-app pre-prompt sheet before the OS dialog.
New or different:
1. **Two families:** segmented "Theo quy tắc" | "Một lần". "Một lần" is presumably the existing one-time reminders (content not drawn) — the screen title becomes "Nhắc nhở" (current "Nhắc việc").
2. **New rule entity** (per baby): type (Bú — bottle or breast —, Ngủ, Thay tã, Hút sữa), mode (`afterLastLog` interval in minutes, presets 2h/2h30/3h/3h30 + stepper | `fixedTimes` list of HH:mm with auto labels "Giấc sáng/trưa/đêm" + weekdays T2–CN), quiet hours "Không nhắc ban đêm 22:00–06:00" (interval mode), "Ngày áp dụng" (interval mode), recipients (member ids), enabled/paused, computed next due ("Tiếp theo 14:45"), and an **occurrence log** (Đã ghi / Báo lại / Bỏ qua with who + when). Times in the baby's time zone (stated on 1c2).
3. **Recipients across devices** (only "Bố mẹ" and "Người chăm"; "Gia đình · chỉ xem" disabled) and **auto-resolve for everyone when anyone logs** the activity — this cannot be done with the current one-device local notification. Needs server-side scheduling (Cloud Functions + FCM push to recipients' devices, cancel/resolve on new care record), recomputing next due from the latest record of the type on every write, and Rules/Functions for the new collections (zod-validated callables per CLAUDE.md). The notification payload must not include child data in logs/analytics; the designed copy has no baby name.
4. **Notification actions** (1f): "Ghi lần bú", "Báo lại sau 15 phút", "Bỏ qua lần này" — iOS notification categories / Android actions, plus deep links into the app (the due sheet or the log sheet).
5. **In-app due sheet** (1g) on Today: anchor line "Lần bú gần nhất 11:45 (bú bình 120 ml) · Mẹ ghi", "Ghi lần bú", snooze chips 10/15/30 phút, "Bỏ qua lần này". New.
6. **Handled state** (1h): banner "Ba Tuấn đã ghi lần bú lúc 14:52 · nhắc tiếp theo 17:52" and "Gần đây" history. New.
7. **Permission ask** right after the first save: toast "Đã lưu nhắc bú" + OS alert with custom body (iOS can't customise that body — keep the existing 8c pre-prompt sheet with this copy, inferred).
8. **Entry points:** Care tab tile "Nhắc nhở · 3 nhắc đang bật" (caregiver "2 nhắc giao cho bạn"), Today ReminderPeek, Today customise row "Nhắc việc sắp tới · 3 nhắc đang bật". The reminder list is a pushed screen without the dock.
9. Business-map: the current one-device rule (and the 8a–8e behaviour) is superseded for rule reminders; needs owner decisions on snooze options (15 on lock screen vs 10/15/30 in app), quiet-hours behaviour (skip vs defer), min/max interval, and "Một lần" scope.

---

## Cluster 10 — Label 382:2793 (verbatim): "Nhật ký gọn hơn"
(A more compact journal.)

Five frames: the compact Journal (10a), the Photos tab grouped by week of age (10b), and three bottom sheets opened from 10b (Xem theo, Loại, Chọn tuần). None of the five frames carries an annotation; all navigation below is inferred from layer names and matching labels.

### 382:2794 — 10a Nhật ký · gọn
Frame 375 x 1604.5 (long scroll mock), bg var(--cloud,#f6fcfb), radius 40. Content padding 52 top / 16 sides / 120 bottom.

**Annotations:** none (no data-annotations on the frame or any child).

**Text (reading order)**
- StatusBar: "9:41", "•••"
- Header: BabySwitcher name="Teddy · 3 tuần" (Teddy · 3 weeks) + chevron-down; right actions: round 44px `View` button (Icon/sliders, surface-2 bg) and round 44px `Add` button (Icon/plus, mint-deep #087f7b fill). No text labels.
- Title (Text/large-title 32 SemiBold): "Nhật ký" (Journal)
- UploadPill (component instance, mint-soft bg, radius 18): 44px MediaTile thumb with dark overlay + progress ring + tiny bookmark (Favorite) badge; "Đang tải 4/7 mục" (Uploading 4/7 items); progress bar ~44% filled; "Cứ làm việc khác, xong sẽ báo bạn" (Go do something else, we'll let you know when done); chevron-right.
- Group head: "Tuần thứ 3" (Week 3) — right side "1 – 8 tháng 10 · 13 ảnh, 3 video" (1–8 October · 13 photos, 3 videos)
  - Entry · 1 ảnh (1 photo): avatar chip "M" (peach-soft) · "Mẹ" (Mom) · "Hôm nay · 9:20" (Today · 9:20) · Icon/family (visibility: family). Caption "Ngủ trưa ngon lành sau giờ tắm." (Napped soundly after bath time.) Photo 128px tall full width. Reaction row: Icon/heart + "Bà nội, Ông ngoại thương" (Grandma (paternal), Grandpa (maternal) loved this).
  - Entry · 1 video: avatar "B" (sunshine-soft) · "Ba" (Dad) · "Hôm qua · 19:05" (Yesterday · 19:05) · Icon/family. Caption "Lần đầu nắm chặt ngón tay ba." (First time gripping Dad's finger tightly.) Photo 128px with 18% dark scrim, centred 56px white play circle, duration pill bottom-left "0:42". Reaction: heart + "2 lượt thương" (2 loves).
  - Entry · 2 ảnh (2 photos): "M" · "Mẹ" · "Thứ Ba, 6 thg 10" (Tuesday, 6 Oct) · Icon/family. Caption "Bà nội sang thăm, mang theo đôi tất len tự đan." (Grandma came to visit, bringing a pair of hand-knitted wool socks.) Two photos side by side, each 96px tall, gap 6. No reaction row.
  - Entry · ghi chú (note, text-only): card bg sunshine-soft #fff4d6 (warm yellow, not white). "M" · "Mẹ" · "Thứ Hai, 5 thg 10" (Monday, 5 Oct) · **Icon/lock** (private). Text "Đêm qua con ngủ một mạch 4 tiếng. Mẹ dậy mà vẫn thấy lạ." (Last night baby slept 4 hours straight. Mom woke up and still found it strange.) No media, no reaction row.
  - Entry · nhiều ảnh (many photos): "M" · "Mẹ" · "Thứ Hai, 5 thg 10" · Icon/family. Milestone chip (sunshine #ffd166, pill): "★ Lần đầu cười · 5 thg 10" (★ First smile · 5 Oct) (layer name "★ Lần đầu cười · 5/10"). No caption. Grid row of 4 tiles 70.25px (radius 12, gap 6, row width 312): tile1 photo; tile2 photo with video pill "▶ 0:24"; tile3 photo with Favorite (bookmark) badge bottom-right; tile4 "+more" = MediaTile with Private (lock) badge top-left + dark overlay rgba(15,38,43,.55) + "+3" (Bold 18 white). No reaction row.
- Group head: "Tuần thứ 2" (Week 2) — "24 – 30 tháng 9 · 6 ảnh" (24–30 September · 6 photos)
  - Entry · nhiều ảnh: avatar "B" · "Ba" · "Chủ nhật, 20 thg 9" (Sunday, 20 Sep) · Icon/family. Milestone chip "★ Ngày đầu về nhà · 20 thg 9" (★ First day home · 20 Sep). Grid of 3 tiles 70.25px: photo, photo, photo with Favorite bookmark badge. No caption, no reaction.
- TabDock / NavBar v1.0.1: "Kỷ niệm" (Memories) label on the active pill.

**Layout / components**
- StatusBar (11:135), BabySwitcher (45:321) with `name="Teddy · 3 tuần"`, UploadPill (instance; inner MediaTile 132:786 with Overlay/Ring track/Ring/Favorite layers), MediaTile instances (134:42 Photo layer; optional Video pill 131:775, Favorite 174:23293, Private 131:778), Illustration/Photo, TabDock (10:169) → nested "NavBar v1.0.1".
- Entry cards are plain frames (not component instances): names "Entry · 1 ảnh", "Entry · 1 video", "Entry · 2 ảnh", "Entry · ghi chú", "Entry · nhiều ảnh". Card: surface white, radius 20, padding 12, gap 8, shadow-tile. Entry head row: avatar initial chip (pill, px8 py3, 12 SemiBold; peach-soft for Mẹ, sunshine-soft for Ba), author 14 SemiBold, time caption 12 muted (flex), visibility icon 14px (family or lock).
- Week group: frame named "Tuần thứ N", gap 10 between head and cards; head = title 15 SemiBold + caption right-aligned. Gap 20 between week groups.
- NavBar tabs in order: Tab/Today (icon only), **Tab/Memories (active, white pill, label "Kỷ niệm")**, Tab/Care (icon only), Tab/Family (icon only). 4 tabs, no QuickLogButton visible in the dock despite the TabDock description.
- Bottom fade 190px gradient to #f5faf7 above the dock.
- No memory sub-tabs (Nhật ký / Ảnh / Album / Câu chuyện) on this frame — unlike the SH frames which have "Memory tabs (floating)".
- Component descriptions (rule-bearing): BabySwitcher — "Baby switcher chip: avatar + name (+ chevron when the family has more than one baby). Shows whose log you are viewing." TabDock — "Tab dock = NavBar + QuickLogButton, 24px above the home indicator. Swap the nested NavBar variant (Active) per tab." Illustration/Photo — "Illustrated baby photo placeholder (privacy-safe). Use instead of real photos in mockups." Icons — "Line icon (24px, 1.8 stroke) — placeholder drawing; production uses SF Symbols. Recolour by overriding the stroke with a text-colour token."
- Text styles: Text/large-title (32/40 SemiBold, -0.4), Text/caption (12/16 Medium, +0.2). Effects: shadow-tile, shadow-nav.

**Visual (screenshot)**
- "Compact" journal: cards have 12px padding (vs normal larger cards), single photo/video preview capped to a 128px-tall cropped strip (not full aspect), two-photo entries 96px tall, many-photo entries as a single row of four ~70px square thumbnails with "+N" on the 4th. Caption 16/22 Regular. Reactions collapsed to a one-line muted caption with small heart.
- Grouped by week of age ("Tuần thứ 3" newest first, then "Tuần thứ 2"); entries reverse-chronological inside the week.
- Text-only private note stands out with a warm yellow card + lock icon.
- Upload progress pill sits between title and the first week group.

**Navigation**
- BabySwitcher → baby picker (inferred; chevron shown).
- Sliders (View) button → view/filter options sheet (inferred; likely "Xem theo"/density/filter).
- Plus (Add) → add memory / pick from library flow (inferred).
- UploadPill chevron → upload queue / progress detail (inferred).
- Tapping an entry card or tile → media viewer / entry detail (inferred); "+3" tile → opens the full entry / viewer at 4th item (inferred).
- Reaction caption → who-loved list (inferred).
- NavBar tabs → Today / Memories / Care / Family root tabs.

**Notes / not shown**
- Week dates inconsistent: Tuần thứ 2 header says "24 – 30 tháng 9" but its entry is dated "Chủ nhật, 20 thg 9" (which falls in "Tuần thứ 1 · 17 – 23 tháng 9" per SH Chọn tuần). Tuần thứ 3 range "1 – 8 tháng 10" spans 8 days; with birth 17 Sep, week 3 would be 1–7 Oct (and week 2 = 24–30 Sep). Counts: week 2 header "6 ảnh" but only 3 tiles in the one entry; week 3 "13 ảnh, 3 video" vs only one visible video entry + one video tile.
- Outline lists two extra MediaTiles (382:2879, 382:2880) in the many-photo grid not rendered in code (hidden or clipped by the 312px overflow-clip row) — the "+3" implies 7 items total, but the layer contains 6 tiles.
- Milestone chip and caption appear mutually exclusive in the mock (many-photo entries have chip but no caption) — unknown if both can show.
- No memory sub-tab switcher (Nhật ký/Ảnh/Album/Câu chuyện) shown here; no empty/loading/error state; no Night-care/dark variant; no per-entry overflow (…) menu; no comment count shown (only loves).
- Visibility icon semantics (family vs lock) not explained on the frame.

### 386:2757 — 10b Ảnh · theo tuần tuổi
Frame 375 x 812, bg var(--cloud,#f6fcfb), radius 40. Same Content padding as 10a (52/16/120).

**Annotations:** none.

**Text (reading order)**
- StatusBar "9:41", "•••"
- Header: BabySwitcher "Teddy · 3 tuần" (Teddy · 3 weeks) + chevron; `View` (Icon/sliders) and `Add` (Icon/plus, mint-deep) round 44px buttons — identical to 10a.
- Title: "Ảnh" (Photos)
- Filter pills row (gap 8): 
  - "Filter · Theo tuần tuổi": Icon/cake + "Theo tuần tuổi" (By week of age) + chevron-down
  - "Filter · Ảnh & video": Icon/camera + "Ảnh & video" (Photos & videos) + chevron-down
- Section head "Tuần thứ 3" (Week 3, 18 SemiBold) — "1 – 8 tháng 10 · 13 ảnh" (1–8 October · 13 photos)
- Grid of 16 MediaTiles; tile badges: video pills "▶ 0:24" (tile 3) and "▶ 0:12" (tile 10); Favorite bookmark badges (tiles 1, 4, 7, 10, 14); Private lock badges top-left (tiles 6, 13).
- Section head "Tuần thứ 2" (Week 2) — "24 – 30 tháng 9 · 6 ảnh" (24–30 September · 6 photos)
- Grid of 8 MediaTiles (only first row visible above the dock); Favorite badges on tiles 2, 5, 8.
- Floating "Date scrubber" pill (right edge, y≈420): "Tuần 3" (Week 3) + chevron-down.
- TabDock: active "Kỷ niệm" (Memories).

**Layout / components**
- BabySwitcher name="Teddy · 3 tuần"; Filter pills are plain frames (not instances): surface white, 1px border var(--separator,#dce8e7), pill radius, px12 py7, gap 6, 14px icons, label 14 SemiBold ink. Neither pill shows a selected/filled state — both look identical (default "dropdown chip").
- Section head: flex baseline row, title 18 SemiBold (larger than 10a's 15), caption 12 Medium muted right-aligned. Gap 14 after filters, 8 under head, 16 between sections.
- Grid: wrap, width 340, gap 4, MediaTile 82×82, radius 12 → **4 columns**. MediaTile sub-layers: Photo (134:42), Video pill (131:775, "▶ m:ss"), Favorite (174:23293, Icon/bookmark bottom-right), Private (131:778, Icon/lock on dark rounded chip top-left). A tile can carry both Video and Favorite (tile 10).
- Date scrubber: surface white pill, shadow-chip (0,8,24 #173D4429), px10 py6, "Tuần 3" 12 SemiBold + 12px chevron-down; absolutely positioned at right edge (x282) mid-screen like a fast-scroll thumb.
- NavBar v1.0.1 tabs: Today (icon), **Memories (active, "Kỷ niệm")**, Care (icon), Family (icon). No QuickLogButton.
- No Memory sub-tabs (Nhật ký/Ảnh/Album/Câu chuyện) on this frame (they appear only in the SH frames built on it).
- Component descriptions with rules: same as 10a (BabySwitcher, TabDock, Illustration/Photo, icons). Icon/cake and Icon/camera: "Line icon (24px, 1.8 stroke) — placeholder; production uses SF Symbols."

**Visual (screenshot)**
- Dense photo grid: 4 columns of ~82px rounded squares with 4px gutters, edge to edge within 16px side margins. Week 3 shows 4 full rows; Week 2 shows one row then fades under the bottom gradient/dock.
- Grouped by week of age, newest first. Small overlay badges: bookmark (favourite) bottom-right, lock (private) top-left, dark pill with play glyph + duration bottom-left for videos.
- Date scrubber floats over the right column of the grid around row 3 (overlapping the 4th-column tile).

**Navigation**
- "Theo tuần tuổi" pill → SH Ảnh · Xem theo (391:2761) grouping sheet (inferred from layer names; sheet title confirms).
- "Ảnh & video" pill → SH Ảnh · Loại (391:2888) type filter sheet (inferred).
- Date scrubber "Tuần 3 ⌄" → SH Ảnh · Chọn tuần (391:3028) jump-to-week sheet (inferred); likely also a drag scrubber (inferred from layer name).
- Tile tap → media viewer (10f) (inferred). Sliders → view options (inferred; possibly the same "Xem theo" sheet). Plus → add/library picker (inferred).

**Notes / not shown**
- Counts inconsistent: "13 ảnh" header but 16 tiles incl. 2 videos (should read e.g. "14 ảnh, 2 video"); Week 2 "6 ảnh" but grid has 8 tiles. SH Chọn tuần lists Week 3 as "16 mục" and Week 2 as "6 mục" — counts differ between screens.
- Date range "1 – 8 tháng 10" (8 days) same issue as 10a.
- How the user reaches "Ảnh" vs "Nhật ký" is not shown on 10b itself (no sub-tab switcher); the SH frames add a floating "Memory tabs" bar — 10b likely lost/hid it.
- No empty state, no multi-select mode, no long-press menu, no dark variant; no indication of the title changing with grouping (e.g. "Theo tháng tuổi").

### 391:2761 — SH Ảnh · Xem theo
Frame 375 x 812. Background = a copy of 10b (identical header, title "Ảnh", filter pills, Week 3/Week 2 grids, date scrubber "Tuần 3", TabDock) **plus** a "Memory tabs (floating)" bar (391:2820) that 10b itself does not have. Scrim + bottom sheet on top.

**Annotations:** none (whole frame read via get_design_context; no data-annotations).

**Text (reading order)**
- Background (dimmed): same strings as 10b — "Teddy · 3 tuần", "Ảnh", "Theo tuần tuổi", "Ảnh & video", "Tuần thứ 3", "1 – 8 tháng 10 · 13 ảnh", tile badges "0:24", "0:12", "Tuần 3", "Tuần thứ 2", "24 – 30 tháng 9 · 6 ảnh", "Kỷ niệm".
- Memory tabs (floating), left→right: "Nhật ký" (Journal; layer name "Dòng thời gian" = Timeline), **"Ảnh" (Photos — active)**, "Album" (Albums), "Câu chuyện" (Stories). (Positioned at y=667, x=21, just above the TabDock; covered by the sheet in this frame.)
- Sheet:
  - SheetHeader title: "Xem ảnh theo" (View photos by) + close (X) button.
  - Row · Tuần tuổi — **selected (filled radio)**: "Tuần tuổi" (Week of age) / caption "Tuần 1, tuần 2… hợp với năm đầu đời" (Week 1, week 2… suited to the first year of life)
  - Row · Tháng tuổi — unselected: "Tháng tuổi" (Month of age) / "1 tháng, 2 tháng…" (1 month, 2 months…)
  - Row · Tháng trong năm — unselected: "Tháng trong năm" (Calendar month) / "Tháng 10, tháng 9…" (October, September…)
  - No confirm/apply button.

**Layout / components**
- Scrim: full-frame var(--scrim, rgba(12,23,25,0.32)).
- Sheet (391:2860): surface white, top radius 28, px16, pb34, gap 10, top at y=501 (height ≈311). SheetHeader instance (37:293) title="Xem ảnh theo". Description: "Bottom-sheet header: grabber, title (24/32 semibold), close (44px, label “Đóng”)." (Grabber 40×5 separator colour.)
- Group (391:2887): white, radius 16, rows stacked with no dividers. Each row: p14, gap 12, 22px radio drawn as an Ellipse vector (not a component instance; selected = mint-deep filled ring with dot, unselected = grey outline ring), text column title 15 SemiBold ink + caption 12 Medium muted (line-height 1.4).
- Memory tabs (floating): frosted pill (rgba(255,255,255,0.86), backdrop-blur 10, shadow 0/12/30 #173D4440), p4, gap 2; each tab px14 py8 pill, label 14; active tab bg var(--ink,#173d44) with white SemiBold text; inactive = muted Medium text, no bg. Plain frames, not a component instance.
- TabDock NavBar v1.0.1: Today, **Memories (active "Kỷ niệm")**, Care, Family.

**Visual (screenshot)**
- Background 10b grid dimmed by the scrim; sheet covers the lower ~40% (from below grid row 3). Memory tabs bar and TabDock are hidden under the sheet.
- Selected option: **"Tuần tuổi"** (teal filled radio). Others empty grey circles. Close X at top-right in teal.

**Navigation**
- Opened by tapping the "Theo tuần tuổi" filter pill on 10b (inferred; sheet title matches pill).
- Selecting a row regroups the Photos grid (section heads switch to week-of-age / month-of-age / calendar month) and updates the pill label (inferred; no "Theo tháng tuổi"/"Theo tháng" pill shown) — likely closes immediately on tap since there is no apply button (inferred).
- X / scrim tap / drag-down → dismiss (inferred from SheetHeader).

**Notes / not shown**
- No screen shows the grid grouped by "Tháng tuổi" or "Tháng trong năm"; pill label/scrubber label for those modes ("Tháng 1"? "Tháng 10"?) not specified.
- Whether the grouping choice also applies to Nhật ký (10a groups by week too) or persists per user/baby is not stated.
- Memory tabs (floating) appear here but not on 10a/10b — inconsistency in where the Nhật ký/Ảnh/Album/Câu chuyện switcher lives (floating above dock vs absent).
- Radio uses an Ellipse vector, not a shared Radio component.

### 391:2888 — SH Ảnh · Loại
Frame 375 x 812. Background = same 10b copy + "Memory tabs (floating)" (Nhật ký / **Ảnh active** / Album / Câu chuyện, at y=667) as in SH Xem theo. Scrim + taller sheet.

**Annotations:** none (whole frame read).

**Text (reading order)**
- Background (dimmed): identical to 10b / SH Xem theo ("Teddy · 3 tuần", "Ảnh", "Theo tuần tuổi", "Ảnh & video", "Tuần thứ 3", "1 – 8 tháng 10 · 13 ảnh", "0:24", "0:12", "Tuần 3", …, memory tabs "Nhật ký", "Ảnh", "Album", "Câu chuyện", dock "Kỷ niệm").
- Sheet:
  - SheetHeader title: "Hiển thị" (Show / Display) + close X.
  - Row · Ảnh & video — **selected (trailing Icon/check, teal)**: Icon/camera · "Ảnh & video" (Photos & videos) / "19 mục" (19 items)
  - Row · Chỉ ảnh: Icon/memories · "Chỉ ảnh" (Photos only) / "15 ảnh" (15 photos)
  - Row · Chỉ video: Icon/eye · "Chỉ video" (Videos only) / "4 video" (4 videos)
  - Row · Đã yêu thích: Icon/heart · "Đã yêu thích" (Favourited) / "6 mục" (6 items)
  - No apply button.

**Layout / components**
- Scrim var(--scrim, rgba(12,23,25,0.32)); Sheet (391:2987) top y=435 (height ≈377), white, top radius 28, px16 pb34 gap 10; SheetHeader (37:293) title="Hiển thị" — "Bottom-sheet header: grabber, title (24/32 semibold), close (44px, label “Đóng”)."
- Group (391:3027) radius 16, rows p14 gap 12, **leading 20px icon** (not radio), title 15 SemiBold + count caption 12 Medium muted, **selection = trailing 20px Icon/check** on the chosen row only. Single-select list pattern (differs from the radio pattern in "Xem ảnh theo").
- Icons: Icon/camera (22:161), Icon/memories (7:27), Icon/eye (22:153), Icon/heart (7:19), Icon/check (7:45) — all "Line icon (24px, 1.8 stroke) — placeholder…; production uses SF Symbols."
- TabDock NavBar v1.0.1: Today, **Memories active "Kỷ niệm"**, Care, Family.

**Visual (screenshot)**
- Sheet covers bottom ~46% (from mid grid row 3). Date scrubber "Tuần 3" peeks just above the sheet edge at right.
- Selected: **"Ảnh & video"** (teal checkmark at right). Icons are teal-ish outlines on the left of each row.

**Navigation**
- Opened from the "Ảnh & video" filter pill on 10b (inferred; layer names match).
- Selecting a row filters the Photos grid by type (all / photos only / videos only / favourites) and updates the pill label to the option name (inferred); closes on selection (inferred; no apply button).
- X / scrim → dismiss (inferred).

**Notes / not shown**
- Sheet title "Hiển thị" differs from the frame name "Loại" (Type) and from the pill label "Ảnh & video".
- Counts: 19 = 15 + 4 consistent internally, but the background grid shows 24 tiles (16 + 8) with only 2 video badges, and section heads say "13 ảnh" + "6 ảnh" = 19 photos (all labelled "ảnh"). Favourites "6 mục" vs 8 tiles with bookmark badges in the grid.
- Favourite iconography inconsistent: the filter uses **Icon/heart** ("Đã yêu thích") but MediaTile's "Favorite" badge uses **Icon/bookmark**; 10a reactions also use heart ("thương" = love), so heart = love reaction vs bookmark = favourite is ambiguous.
- "Chỉ video" uses Icon/eye (no video icon in the set); "Chỉ ảnh" uses Icon/memories.
- No "Riêng tư" (private only) option, no filter by author; pill label for non-default selection not shown.

### 391:3028 — SH Ảnh · Chọn tuần
Frame 375 x 812. Background = same 10b copy + "Memory tabs (floating)" (Nhật ký / **Ảnh active** / Album / Câu chuyện) as the other SH frames. Scrim + tallest sheet (top y=411, ≈401 tall) which covers the Date scrubber (y=420) that opens it.

**Annotations:** none (whole frame read).

**Text (reading order)**
- Background (dimmed): same as 10b ("Teddy · 3 tuần", "Ảnh", "Theo tuần tuổi", "Ảnh & video", "Tuần thứ 3", "1 – 8 tháng 10 · 13 ảnh", "0:24", …; scrubber "Tuần 3" hidden under sheet; memory tabs and dock "Kỷ niệm" under sheet).
- Sheet:
  - SheetHeader title: "Đi tới tuần" (Go to week) + close X.
  - Row · Tuần thứ 3 — **selected (trailing Icon/check)**: 44px cover thumbnail · "Tuần thứ 3" (Week 3) / "1 – 8 tháng 10 · 16 mục" (1–8 October · 16 items)
  - Row · Tuần thứ 2: thumb · "Tuần thứ 2" (Week 2) / "24 – 30 tháng 9 · 6 mục" (24–30 September · 6 items)
  - Row · Tuần thứ 1: thumb · "Tuần thứ 1" (Week 1) / "17 – 23 tháng 9 · 9 mục" (17–23 September · 9 items)
  - Row · Mới sinh: thumb · "Mới sinh" (Newborn) / "17 tháng 9 · 4 mục" (17 September · 4 items)
  - No apply button.

**Layout / components**
- Scrim var(--scrim, rgba(12,23,25,0.32)); Sheet (391:3127) white, top radius 28, px16 pb34 gap 10; SheetHeader (37:293) title="Đi tới tuần" ("Bottom-sheet header: grabber, title (24/32 semibold), close (44px, label “Đóng”).").
- Group (391:3184) radius 16; rows p14 gap 12: leading 44×44 cover photo (radius 10, surface-2 bg, Illustration/Photo), text column title 15 SemiBold + caption "date range · N mục" 12 Medium muted, trailing 20px Icon/check on the current week only. Same check-mark single-select pattern as "Hiển thị".
- Order: newest week first, ending with a special "Mới sinh" bucket (birth day).

**Visual (screenshot)**
- Sheet covers from just below grid row 2 to the bottom; four rows with photo thumbnails (week cover = probably first/best photo of the week).
- Selected: **"Tuần thứ 3"** (teal check at right) = the week currently in view (matches scrubber "Tuần 3").

**Navigation**
- Opened by tapping the floating "Date scrubber" pill "Tuần 3 ⌄" on 10b (inferred; frame name + matching label).
- Tapping a row scrolls the Photos grid to that week's section and closes the sheet; scrubber label updates to "Tuần N" (inferred).
- X / scrim → dismiss (inferred).

**Notes / not shown**
- Item counts conflict across frames: Week 3 = "16 mục" here vs "13 ảnh" in the section head (grid has 16 tiles); Week 2 = "6 mục" here and in head, but grid has 8 tiles. Sum here = 16+6+9+4 = 35 items vs "Ảnh & video · 19 mục" in SH Loại.
- Date ranges: Week 1 = 17–23 Sep (birth day 17 Sep included), Week 2 = 24–30 Sep, Week 3 = "1 – 8 tháng 10" (should be 1–7 Oct for 7-day weeks). "Mới sinh · 17 tháng 9" overlaps Week 1's first day — rule for whether birth-day items sit in "Mới sinh" or "Tuần thứ 1" (and whether weeks are 0- or 1-indexed: "Teddy · 3 tuần" at ~8 Oct) is not specified.
- 10a's Week 2 entry dated "Chủ nhật, 20 thg 9" belongs in Week 1 by this sheet's ranges.
- Long lists (52+ weeks in the first year; months after) — scrolling/sectioning of this sheet, and the label for month-based groupings ("Đi tới tháng"?), not shown.
- Weeks with zero items: hidden or shown with "0 mục" — not shown.


### Compared with the current app (cluster 10)
Current: `MemoriesScreen` / `JournalView` / `PhotosView` (`apps/mobile/lib/features/memories/memories_screen.dart`), `MemoryEntryCard`, `MediaTile` (`memory_widgets.dart`), `showViewOptions` (10c "Cách xem"), `showGotoMonth` (`memory_sheets.dart`); route `/memories`.
New or different:
1. **Compact journal card (10a)** — a new density for `MemoryEntryCard`: 12px padding, radius 20; single photo/video cropped to a **128px-tall strip** (app: full width with aspect 0.75–1.6); 2 photos side by side at **96px**; 3+ items as **one row of 4 square ~70px tiles** with "+N" on the 4th (app: 3-column grid up to 6 with "+N"); reactions collapsed to one muted line with a small heart ("Bà nội, Ông ngoại thương" / "2 lượt thương"); the app's "Nhắn ba mẹ" footer is not shown. Author shown as a small initial chip + name; milestone chip stays. Grouping by week of age with "1 – 8 tháng 10 · 13 ảnh, 3 video" is what the app already does. Whether the compact card replaces the current one or is a "Kiểu xem" option is not stated (label says "gọn hơn" = make it more compact → replace, inferred).
2. **Ảnh tab grouped by week of age (10b)** — the app's Ảnh tab is always grouped by calendar month and ignores "Nhóm theo". New: section heads "Tuần thứ N · {date range} · {count}", 4-column 82px grid (same as the app's "Lưới nhỏ"), and a floating **"Tuần 3 ⌄" scrubber** (app: month scrubber "Th 10, 2026").
3. **Two new filter pills replace the current chip row** ("Tất cả", "Tháng ▾", "Chọn"): "Theo tuần tuổi ▾" (grouping) and "Ảnh & video ▾" (type). The "Chọn" (select) entry point is not on 10b — where multi-select is entered from is not designed.
4. **New sheet "Xem ảnh theo"**: Tuần tuổi / Tháng tuổi / Tháng trong năm (radio, captions). The app's "Cách xem" has Nhóm theo Ngày/Tuần/Tháng — the new set drops "Ngày" and splits month into month-of-age vs calendar month. Needs month-of-age grouping (new) and DOB.
5. **New sheet "Hiển thị"**: Ảnh & video · {n} mục / Chỉ ảnh · {n} ảnh / Chỉ video · {n} video / **Đã yêu thích** · {n} mục (check-mark list with counts). The app's "Hiện" option set is Tất cả / Ảnh / Video / Có mốc — "Có mốc" is dropped here and "Đã yêu thích" is new as a filter; counts per option are new (need cheap counts per baby).
6. **New sheet "Đi tới tuần"**: one row per week of age with a 44px cover thumbnail, "Tuần thứ N · {range} · {n} mục", newest first, ending with "Mới sinh · {DOB} · {n} mục"; current week checked. Replaces "Đi tới tháng" when grouping is by week (inferred). Needs per-week counts and a cover photo per week (rule not designed).
7. **Sub-tab bar**: the SH frames show a floating frosted "Nhật ký / Ảnh / Album / Câu chuyện" bar above the dock (app: large-title tabs that swipe); 10a/10b don't show it — placement is unresolved.
8. **Dock**: NavBar v1.0.1 (Today · Kỷ niệm active · Chăm sóc · Gia đình), and no QuickLogButton on the Memories tab (app shows "+" on every tab for parents). Confirm with owner (cluster 8).
9. Counts and week ranges in the mock are inconsistent (see notes above); engineering should define: week N = days [7(N−1)+1 … 7N] after birth or similar, whether the birth day is "Mới sinh" or "Tuần thứ 1", and what "mục" counts.

---

## Open questions raised by this page (for business-map)
1. **WHO comparison vs R-056.** The original growth rule "không bách phân vị, không đánh giá" is replaced by a WHO band, a "Bình thường / Dưới mức tham chiếu" status and a doctor banner. Needs an owner decision (D-xxx), the above-range wording, length wording, the definition of "khoảng bình thường" (design values = WHO P3–P97), the rounding rule (P97 6.252 shown as "6,2"), the sex = "unspecified" case, and the week → month switch-over age. The "Ngưỡng dưới 6,4 kg" at 7 months in 347:935 does not match WHO for either sex (illustrative).
2. **NavBar v1.0.1.** Confirm: Me tab removed and replaced by the header avatar; relatives' dock under v1.0.1 (not drawn); whether Memories hides the "+" button (cluster 10 frames) or that is a mock omission.
3. **Today customise vs tracker choice.** Scope of the "Tuỳ chỉnh Hôm nay" layout (per user / per baby / per device) and how it relates to "Tuỳ chỉnh theo dõi" (baby.trackers).
4. **Rule reminders.** Server push vs local notifications; snooze options; quiet hours behaviour; anchor for breastfeeding (start or end); interval bounds; per-reminder vs list-level recipients (1a shows one line); content of "Một lần"; Android notification layout.
5. **Email-link sign-in.** Feasibility of the stated 15-minute validity, same-device requirement, link domain per flavor, and what "Tài khoản mới" changes on 07a/07c.
6. **Returning user detection.** What marks a device as "đã từng dùng app" (survives sign-out? reinstall?).
7. **Feeding stats.** What the "Bú bình 62% / Bú mẹ 38%" share is computed on (feeds, inferred); layouts for Hôm nay / 30 ngày / Tuỳ chọn; tooltip selection behaviour.
8. **Sleep stats.** Day attribution of the 18:00–06:00 night window per bar; definition of "ổn định" in the new insight; the mock numbers do not reconcile (KPI 14g20p vs bars ≈14g08p).
9. **Bottle quick picks.** The age → amounts table (only 3 weeks → 60/90/120/150 ml is drawn) and its source.
10. **Photos by week of age.** Week boundaries (birth day = "Mới sinh" or week 1), what "mục" counts, cover photo rule, favourite icon (heart vs bookmark), placement of the Nhật ký/Ảnh/Album/Câu chuyện switcher, where multi-select is entered.
11. **Copy-pasted annotations** on 20g ×3, SH Thống kê bú ×2, 20h, 20d ×2 (History annotation), CS Tuỳ chỉnh Hôm nay and CS 1g (Hôm nay annotation), OB R0 (splash annotation pointing to 01 Chào mừng). Treat the cluster labels as the intent.

## Coverage
| Cluster (label) | Frames | Read with |
|---|---|---|
| 345:35702 | 345:35762 (Light), 345:35703 (Night) | get_design_context (Light); Night by metadata structure diff + screenshot |
| 346:63 | 346:64, 346:354, 346:590, 391:3185, 391:3373 | get_design_context (391:3373 via sheet 391:3533 + full screenshot) |
| 346:47150 | 346:47151 | get_design_context on sheet 346:47179 + full frame (annotation) |
| 346:47461 | 346:47462 | get_design_context |
| 346:47705 | 346:47706, 346:47899, 347:806, 347:935 | get_design_context |
| 368:836 | 368:838, 368:843, 368:1000, 368:1014, 368:1028, 368:1042, 368:1056, 368:1139, 368:1184, 368:1221 | get_design_context |
| 368:837 | 368:1261, 368:1266, 368:1349 | get_design_context |
| 370:1246 | 370:1248, 370:1525, 370:1898, 370:1971, 370:2174 | get_design_context |
| 370:1247 | 370:2365, 370:2444, 370:2517, 370:2584, 370:2660, 370:2738, 370:2831, 370:2860, 370:3155 | get_design_context |
| 382:2793 | 382:2794, 386:2757, 391:2761, 391:2888, 391:3028 | get_design_context |

Not read / errors: none. All 10 label text nodes were read with get_design_context; each label equals its layer name minus the "Label · " prefix.
