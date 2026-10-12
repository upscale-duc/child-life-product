# Chăm sóc and Tiện ích tabs (new dock without Gia đình): spec extracted from final Figma

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only), page **"v1.0 - improvement"** (canvas `345:35701`), read 2026-10-12. No Figma node was modified.

**Method.** `get_metadata` ×2 on the targets, then once on the canvas `345:35701`. The page list shows only Cover and Logo, and the targets are not on `304:18` (v1.1) or `26:2` (v1.0); they sit on the improvement page. The canvas dumps were saved and split locally. `get_design_context` ×6: CS2a `450:6424`, CS2b `450:6597`, CS2c `450:6873`, R1 `456:6246`, R3 `456:6785`, R4 `456:6952`, R5 `456:7022`. `get_screenshot` ×8. There were no failures, no rate limits, and no write tool was used. Strings below are the rendered text, not layer names; layer names are cut at 30 characters and several are stale. Glosses in parentheses are engineering drafts. **(prototype link)** means the node is rendered as `<a … cursor-pointer>`; the MCP never exposes the target, so every target is **(inferred)**.

**Annotations.** No CS2 or R frame has its own annotation. R1 carries the v1.0 Today annotation, copied over unchanged (quoted under R1).
**Night care.** None of these frames is drawn in Night care; every one is Light (`cloud #f6fcfb`).
**Mock data.** Teddy, 3 weeks (R frames: "Teddy · 3 tuần"); the user is Mẹ Mai ("M"); the family has 4 members and 1 pending invite; next vaccine 17/11; spending this month 4.215.000 ₫; 25 first-aid situations.

## Frame list

All frames are 375 wide and sit on the improvement canvas in the row at y 9079, next to the v1.0 "Chăm sóc (Care) · Hôm nay" cluster.

| x | Node | Name | Size | Dock drawn | Screenshot |
|---|---|---|---|---|---|
| 0 | 370:1248 | CS Hôm nay (v1.0, context) | 375 × 1135 | yes | — |
| 415 | 370:1525 | CS Tuỳ chỉnh Hôm nay (v1.0) | 375 × 812 | yes | — |
| 830 | 370:1898 | CS Tôi (từ avatar) (v1.0) | 375 × 812 | no | — |
| 1245 | 370:1971 | CS Chăm sóc (v1.0, what the app implements) | 375 × 1411 | yes | — |
| 1660 | 370:2174 | CS Chăm sóc · người chăm (v1.0) | 375 × 1281 | no | — |
| **2075** | **450:6424** | **CS2a · Chăm sóc** (target) | 375 × 1277 | **no** | `img/v11/450-6424.png` |
| **2490** | **450:6597** | **CS2b · Tiện ích** (target) | 375 × 812 | **no** | `img/v11/450-6597.png` |
| 2905 | 450:6873 | CS2c · Tiện ích · người chăm | 375 × 812 | yes (caregiver) | `img/v11/450-6873.png` |
| — | 456:6245 | text label **"Label · R · Tab chính · đề xuất"** (Main tabs · proposal) at x 3735, y 9009 | — | — | — |
| 3735 | 456:6246 | R1 · Hôm nay | 375 × 1135 | yes | `img/v11/456-6246.png` |
| 4150 | 456:6482 | R2 · Kỷ niệm | 375 × 1604.5 | yes (no "+") | `img/v11/456-6482.png` |
| 4565 | 456:6785 | R3 · Chăm sóc | 375 × 1277 | yes | `img/v11/456-6785.png` |
| 4980 | 456:6952 | R4 · Tiện ích | 375 × 812 | yes | `img/v11/456-6952.png` |
| 5395 | 456:7022 | R5 · Tôi | 375 × 812 | no (pushed screen) | `img/v11/456-7022.png` |

No label sits over CS2a–CS2c; they continue the "CS" cluster (label `370:1246`). The **R row** is labelled "Tab chính · đề xuất" (main tabs, proposal). It has higher node ids, so it is newer. It redraws CS2a and CS2b with the dock (R3 = CS2a, R4 = CS2b) and adds the parent dock and Tôi. **This document treats R1–R5 as the latest state** (inferred), with CS2a/CS2b as the same content without a dock. The differences are listed in each section.

There is **no relative (Người thân) frame** and **no caregiver Chăm sóc frame** for the new model. The v1.0 caregiver Chăm sóc `370:2174` still applies (inferred).

---

## Shared chrome (CS2a, CS2b, CS2c, R3, R4)

- Content column: `px 16`, `pt 52`, `pb 120`, `gap 14`, on `cloud #f6fcfb`. StatusBar 40.
- **Top row** (h 40, gap 8):
  - **UserAvatar**: pill `card-peach #ffa58d`, `px 11 py 6`, letter "M" Bold 14 `care-bottle-ink #1d5f99`. Opens Tôi (R5) (inferred; same as v1.0).
  - **BabySwitcher** (`surface-2 #eef6f5` pill, avatar 32, name Medium 16, chevron 16). CS2*: "Teddy". R*: **"Teddy · 3 tuần"** (Teddy · 3 weeks).
  - spacer.
  - **night** button: `surface #fff` circle, p 8 (34 px), `Icon/today` 18. This is the existing Night care toggle (inferred from the layer name "night"). It is drawn in **CS2a/CS2b/CS2c only**; **R3 and R4 have no night button**, and R1 (Hôm nay) shows a labelled pill "Đêm" instead (see the dock section).
- **Large title**: Bold 32 `ink #173d44`, leading normal. (R5/R1 use Text/large-title SemiBold 32/40, −0.4.)
- **Section header**: Bold 17 `ink`, then a spacer. There is no trailing link.

---

## CS2a · Chăm sóc `450:6424` (R3 · Chăm sóc `456:6785`)

Frame 375 × 1277 (content 1237). R3 adds the TabDock at y 1209 with **Chăm sóc active**.

### Reading order (vi exactly, English gloss)
1. Top row: "M" · BabySwitcher "Teddy" (R3: "Teddy · 3 tuần") · night button (CS2a only).
2. Title **"Chăm sóc"** (Care).
3. Search field **"Tìm trong Chăm sóc…"** (Search in Care…).
4. Section **"Chăm hằng ngày"** (Daily care). **R3: "Theo dõi bé"** (Tracking the baby); the layer is still named "Section · Chăm hằng ngày".
5. Grid (2 columns):
   | # | Tile | Icon (layer) | Chip tint | Subline CS2a | Subline R3 |
   |---|---|---|---|---|---|
   | 1 | **Nhắc nhở** (Reminders) | Icon/clock | `mint-soft #e6f7f5` | "3 nhắc đang bật" (3 reminders on) | same |
   | 2 | **Tiêm chủng** (Vaccinations) | Icon/heart | `peach-soft #ffe3da` | "Mũi tiếp theo 17/11" (Next shot 17/11) | same |
   | 3 | **Thống kê** (Statistics) | Icon/sliders | `care-sleep-soft #edeefc` | "Bú, ngủ theo ngày" (Feeding, sleep by day) | **"Bú, ngủ, tã theo ngày"** (Feeding, sleep, diapers by day) |
   | 4 | **Lịch sử** (History) | Icon/journal | `care-diaper-soft #e7f4e3` | "Mọi lần đã ghi" (Everything logged) | **"Mọi lần ghi, theo ngày"** (Every log, by day) |
   | 5 | **Tăng trưởng** (Growth) | Icon/ruler | `care-growth-soft #fdede2` | "Cân nặng, chiều dài" (Weight, length) | same |
6. Section **"Sớm ra mắt"** (Coming soon). The layer is named "Section · Hiểu con hơn" (stale).
7. Grid (2 columns). Every tile has the badge **"Sớm ra mắt"**:
   | # | Tile | Icon (layer) | Chip tint | Subline |
   |---|---|---|---|---|
   | 1 | **Wonder Week** | Icon/spark | `care-sleep-soft #edeefc` | "Giai đoạn phát triển dự kiến" (Expected developmental phases); wraps to 2 lines, tile h 135 |
   | 2 | **Thẻ theo tuổi** (Age cards) | Icon/cake | `sunshine-soft #fff4d6` | "Gợi ý theo tuổi của bé" (Suggestions for baby's age) |
   | 3 | **Mốc phát triển** (Milestones) | Icon/star | `peach-soft #ffe3da` | "Ghi lại lần đầu của con" (Record your child's firsts) |
   | 4 | **Ăn dặm** (Solid food) | Icon/feed | `care-bottle-soft #e5f1fb` | "Nhật ký & thư viện ăn dặm" (Solid-food diary & library); 2 lines, h 135 |
   | 5 | **Dinh dưỡng** (Nutrition) **NEW** | Icon/spark | `mint-soft #e6f7f5` | "Sữa, vi chất theo giai đoạn" (Milk, micronutrients by stage); 2 lines, h 135 |

What is **not** on the screen any more:
- the red **Sơ cứu** entry (now in Tiện ích);
- the **Chi tiêu** tile (now in Tiện ích);
- the **Thư viện chăm bé** teaser (now a row in Tiện ích);
- the v1.0 "Cài đặt" section (already removed in the app, P-127).

### Layout and tokens
- Search: `surface #fff`, 1 px `control-border #7e959a`, radius 14, `px 14 py 13` (h 50), gap 8. Icon/search 18. Placeholder Medium 15, leading 1.45, `ink`.
- Grid: wrap, gap 12, tile width 165.5 (2 columns in 343).
- **Tile**: `surface #fff`, radius 20, p 14, column gap 10, shadow-card (0 1 2 `#173D440F` + 0 8 24 `#173D4414`). Height 118 with a 1-line subline, 135 with 2 lines.
  - top row: chip `p 8`, radius 12, the tint above, icon 18 `ink` (34 px); spacer; optional badge.
  - title Bold 15 `ink`; subline Medium 12, leading 1.4, `ink-muted #55707a`.
  - **"Sớm ra mắt" badge**: `sunshine #ffd166` pill, `px 8 py 3`, Bold 11 `ink` (80 × 20).
- Teaser tiles are drawn **exactly like live tiles** (white, shadow, coloured chip, full opacity). Only the badge marks them.

### Links (none drawn as prototype links on CS2a/R3; all inferred, same as the app today)
- Nhắc nhở → reminders list. Tiêm chủng → vaccination book. Thống kê → feed/sleep stats (the app's chooser). Lịch sử → history. Tăng trưởng → history filtered to growth.
- Teasers → "Sớm ra mắt" toast (inferred; the v1.1 page designs the screens behind them, see `20-v11-content-features.md`).
- R3 dock: **Tab/Utilities is a prototype link** (→ R4).

### Data on sublines
- Nhắc nhở: rules that are on, plus one-time reminders still ahead (caregiver: the ones that ring on their phone, v1.0 `370:2174`).
- Tiêm chủng: the next due date (`vxTile*` variants stay: overdue / setup / all done).
- The other sublines are static copy.

---

## CS2b · Tiện ích `450:6597` (R4 · Tiện ích `456:6952`)

Frame 375 × 812 (content 693). R4 adds the TabDock at y 744 with **Tiện ích active**. CS2b and R4 have identical content; R4 has no night button and its switcher reads "Teddy · 3 tuần".

### Reading order
1. Top row (as above).
2. Title **"Tiện ích"** (Utilities).
3. Section **"Cho bé"** (For the baby).
4. White group card (3 rows):
   | # | Row | Icon (layer) | Subline (vi) | Gloss | Trailing | Link |
   |---|---|---|---|---|---|---|
   | 1 | **Sơ cứu trẻ em** | Icon/alert | "25 tình huống · dùng khi không có mạng" | 25 situations · works offline | chevron | **prototype link** → Sơ cứu home 7b (inferred) |
   | 2 | **Chi tiêu** | Icon/grid | "Tháng này 4.215.000 ₫" | This month 4,215,000 ₫ | chevron | **prototype link** → Chi tiêu month view 8b (inferred) |
   | 3 | **Thư viện chăm bé** | Icon/bookmark | "Bài viết được chuyên môn rà soát" (2 lines; text column narrowed to 177) | Articles reviewed by professionals | **"Sớm ra mắt" badge**, no chevron | not linked → toast (inferred) |
5. Section **"Gia đình"** (Family).
6. White group card (2 rows):
   | # | Row | Icon (layer) | Subline | Gloss | Trailing | Link |
   |---|---|---|---|---|---|---|
   | 1 | **Thành viên & chia sẻ** | Icon/family | "4 người · 1 lời mời đang chờ" | 4 people · 1 invite pending | chevron | → the current Gia đình screen (members, pending invites, permissions) (inferred) |
   | 2 | **Mời người thân** | Icon/plus | "Ông bà, người chăm cùng theo dõi bé" | Grandparents, caregivers follow the baby together | chevron | → the invite flow (`/family/invite`) (inferred) |

### Layout and tokens
- Group card: `surface #fff`, radius 16, `overflow clip`, **no shadow and no row dividers** drawn.
- Row: `px 14 py 12`, gap 12, h 62 (79 for the 2-line library row).
  - chip: `surface-2 #eef6f5` (**neutral on every row; Sơ cứu is no longer red**), p 8, radius 12, icon 18 `ink`.
  - text: title SemiBold 15 `ink`, gap 2, subline Medium 12 / 1.4 `ink-muted #55707a`.
  - trailing: Icon/chevron-right 16, or the sunshine badge (as in Chăm sóc).
- Icon/grid here is the 18 px variant: four 6 px rounded squares, 1.5 stroke `ink`.

### Data on sublines
- Sơ cứu: the number of situations in the downloaded pack (`faEntrySub`).
- Chi tiêu: the month-to-date total, **written in full** with dot thousands and " ₫", with the label first ("Tháng này …"). Today the app shows `spTileMonth` "{amount} tháng này" with a short amount. Empty and record-only states are not drawn for parents (inferred: keep `spTileEmpty`).
- Thành viên & chia sẻ: "{n} người" = active members of this baby (n = 4 incl. the user, inferred), "· {k} lời mời đang chờ" = pending invites. The second half is presumably hidden when k = 0 (inferred).

---

## CS2c · Tiện ích · người chăm `450:6873` (caregiver)

375 × 812. The dock is drawn (Tiện ích active). Header as in CS2b (avatar still "M" in the mock; inferred: it would be the caregiver's own letter, e.g. "L").

1. Title **"Tiện ích"**.
2. Section **"Cho bé"**, group:
   - **Sơ cứu trẻ em**: "25 tình huống · dùng khi không có mạng", chevron. Prototype link.
   - **Khoản tôi đã chi** (Expenses I paid), Icon/grid: **"Mẹ đã cho phép ghi khoản chi"** (Mum allowed you to record expenses), chevron. Not a prototype link. Inferred target: the caregiver's own expense list or add (D-055 "Ghi khoản đã chi"). "Mẹ" = the relation label of the Cùng nuôi who granted the right (inferred).
   - **Thư viện chăm bé**: "Bài viết được chuyên môn rà soát" + "Sớm ra mắt".
3. Section **"Gia đình"**, group (1 row):
   - **Thành viên & chia sẻ**, Icon/family: **"Xem thành viên gia đình"** (See family members), chevron.
   - **No "Mời người thân" row**: only Cùng nuôi invite (matches today's `isCoParent` gate).
4. Rows that only show with a right: the Chi tiêu row appears only with a spending right (D-055; inferred, a caregiver without one sees no row). With "Xem toàn bộ chi tiêu" the row is presumably the parent's "Chi tiêu · Tháng này …" (not drawn).

---

## Dock: TabDock `10:169` with nested "NavBar v1.0.1" (R1, R2, R3, R4, CS2c)

### Tabs, order and labels
| Role | Tabs (left → right) | Source |
|---|---|---|
| Cùng nuôi (parent) | **Hôm nay · Kỷ niệm · Chăm sóc · Tiện ích** + QuickLog "+" | R1, R3, R4 (R2 without "+") |
| Người chăm sóc (caregiver) | **Hôm nay · Chăm sóc · Tiện ích** + "+" | CS2c |
| Người thân (relative) | not drawn | — |

- **Removed:** Tab/Family "Gia đình" (Icon/family).
- **Added:** **Tab/Utilities "Tiện ích"**, Icon/grid, always last.
- Chăm sóc keeps Icon/care and its 3rd place; Gia đình's slot (4th) becomes Tiện ích.
- This supersedes the "NavBar v1.1" in `20-v11-content-features.md` Part A (Today · Memories · Family · Utilities), where Care was the tab that disappeared. In the R proposal **Care stays and Family goes**.

### Visual change to the NavBar
Every tab now shows **icon above label**, and labels are visible on **inactive** tabs too. Today the app draws an icon-only inactive tab (52 w) and a horizontal labelled pill for the active tab.
- NavBar: `nav-bar #173d44` pill, h 68, p 6 (R3: `px 4 py 6`), shadow-nav (0 12 30 `#173D4440`), `justify-between`.
- Tab: **w 64** in a 4-tab bar, **w 80** in the caregiver's 3-tab bar; full height (56), radius 20, column `gap 3`, `px 2 py 6`.
  - icon 20 (grid: four 6.667 px squares, 1.667 stroke);
  - label 11 / 16, tracking 0.2.
  - **Inactive:** icon and label `nav-icon #b9cfcf`, label Medium.
  - **Active:** background `nav-active #ffffff`, icon `on-nav-active #173d44`, label **Bold** `on-nav-active`.
- TabDock: h 68, `px 16`, gap 12, QuickLogButton 68 `mint-deep #087f7b`, Icon/plus 28. On Kỷ niệm (R2) there is no "+" and the NavBar spans the full width, so its tabs are wider (from the screenshot).
- Prototype links: R3 Tab/Utilities → R4, R4 Tab/Care → R3.

### Neighbouring R frames (context only; not part of this change)
- **R1 · Hôm nay `456:6246`.** Annotation (copied from v1.0 Today) — "Thẻ lớn = vừa ghi vừa xem: chạm thẻ → mở sheet ghi mục đó (1 chạm) …" (big tiles both log and show; tap opens that log sheet).
  - Header: the night toggle is a **labelled pill "Đêm"** (Icon/sleep 16 + SemiBold 13, `surface`, `px 10 py 8`).
  - ReminderPeek label "Nhắc nhở · 3 đang bật", title "Tiêm mũi 6 trong 1".
  - Otherwise the same as v1.0 Today.
- **R2 · Kỷ niệm `456:6482`.** Header shows switcher + sliders button + mint "+"; segmented tabs **"Dòng thời gian · Ảnh & video"** (Timeline · Photos & videos), which differs from D-052's Ảnh · Album · Nhật ký · Câu chuyện; then an upload pill and the weekly timeline. Not analysed further here.

---

## Where Gia đình went

1. **Tiện ích → section "Gia đình"**:
   - "Thành viên & chia sẻ" → today's `FamilyScreen` (members, pending invites, member sheet, relation and rights) (inferred);
   - "Mời người thân" → `Routes.invite` (parents only).
2. **Tôi (R5 · Tôi `456:7022`) → new row "Gia đình" · "4 thành viên"** (Family · 4 members), Icon/family 20, chevron, in the first group between **"Các bé · Teddy, Na · 2"** and **"Thông báo · Bật"**. Row `px 16 py 14`, title SemiBold 15, subline Medium 12 / 1.4. Target → FamilyScreen (inferred).
   - R5 is otherwise the v1.0 Tôi: back button, "Tôi", profile Mai / mai.nguyen@gmail.com / "Mẹ · quản lý hồ sơ Teddy, Na", Dung lượng card, Giao diện, Liên kết chia sẻ, Tài khoản & đăng nhập, Trợ giúp & liên hệ, Đăng xuất.
   - It draws **no Ngôn ngữ (language) and no Tin nhắn (messages) row**. Both exist in the app today; treat this as not drawn rather than removed (inferred).
3. FamilyScreen no longer has a dock and becomes a pushed screen with a back button (inferred, like Tôi).

---

## Caregiver, relative and Night care

- **Caregiver.**
  - Dock: Hôm nay · Chăm sóc · Tiện ích.
  - Tiện ích per CS2c: no invite row, "Xem thành viên gia đình", "Khoản tôi đã chi" when allowed.
  - Chăm sóc: no new frame, so v1.0 `370:2174` applies: no Tăng trưởng tile, Nhắc nhở "{n} nhắc giao cho bạn". The new "Dinh dưỡng" teaser and the removals apply too (inferred).
- **Relative.**
  - Not drawn. Today the dock is Kỷ niệm · Gia đình (+ Hôm nay when granted daily care, D-018).
  - With Gia đình gone, the inferred dock is **Kỷ niệm · Tiện ích**, or Hôm nay · Kỷ niệm · Tiện ích when granted. Tiện ích would show Sơ cứu, Thư viện (soon), Chi tiêu only with a D-055 right, and "Thành viên & chia sẻ" read-only. This is an open question.
- **Night care.** Not drawn for any of these frames. Use the Night tokens of the existing components (inferred).

---

## Diff vs current app

Files:
- `apps/mobile/lib/features/care/care_hub_screen.dart`
- `apps/mobile/lib/core/widgets/cl_navigation.dart`
- `apps/mobile/lib/features/home/home_shell.dart`
- `apps/mobile/lib/app/router.dart`
- `apps/mobile/lib/app/route_guard.dart`
- `apps/mobile/lib/features/family/family_screen.dart`
- `apps/mobile/lib/features/me/me_screen.dart`
- `apps/mobile/lib/features/first_aid/first_aid_modes.dart`

### Chăm sóc tab (`CareHubScreen`)
- **Remove** `FirstAidEntry` (the red Sơ cứu card) from Chăm sóc; it moves to Tiện ích as a neutral row.
- **Remove** the Chi tiêu tile from the daily grid; it moves to Tiện ích.
- **Remove** the "Thư viện chăm bé" teaser; it becomes a Tiện ích row with a "Sớm ra mắt" badge.
- **Add** a "Dinh dưỡng" teaser (last), Icon/spark, `mint-soft`, subline "Sữa, vi chất theo giai đoạn". This needs new ARB ids, e.g. `careNutrition` / `careNutritionSub`, vi + en.
- **Teaser order:** Wonder Week · Thẻ theo tuổi · Mốc phát triển · Ăn dặm · Dinh dưỡng.
- **Teaser look:**
  - today: `surface2` card, no shadow, opacity 0.5/0.6, Icon/spark for all, badge on `surface` in `inkMuted`;
  - Figma: white card + shadow-card, full opacity, **own icon + tint per tile** (spark/`care-sleep-soft`, cake/`sunshine-soft`, star/`peach-soft`, feed/`care-bottle-soft`, spark/`mint-soft`), badge `sunshine #ffd166` Bold 11 `ink`.
- **Copy (R3, the newest):**
  - section `careDaily` "Chăm hằng ngày" → **"Theo dõi bé"**;
  - `careStatsSub` "Bú, ngủ theo ngày" → **"Bú, ngủ, tã theo ngày"**;
  - `careHistorySub` "Mọi lần đã ghi" → **"Mọi lần ghi, theo ngày"**.
  - CS2a keeps the old copy, so the owner must pick (see open questions). English drafts are needed.
- **Sizes:**
  - icon chip in Figma is 34 (p 8 + icon 18); the code uses `ClIcon` size 20;
  - tile radius 20, p 14, gap 10;
  - title Bold 15, subline Medium 12;
  - title Bold 32 (the code uses `largeTitle`).
  - Check against `_Tile` (unchanged from v1.0 except the icon size).
- **Search:** it still filters only the Chăm sóc tiles. With Sơ cứu gone from the tab, search no longer reaches first aid (inferred; see the open questions).
- The night toggle (`NightCareToggle` in `BabyHeader`) is drawn in CS2a but not in R3 (open question).
- Doc comment: cite `450:6424` / `456:6785`, and drop "Chi tiêu (v1.1 8a)" and the first-aid "7a" references.

### New Tiện ích tab
- **Add** a screen (e.g. `features/utilities/utilities_screen.dart`) with the `BabyHeader`, title "Tiện ích" and two sections.
  - **"Cho bé":**
    - Sơ cứu trẻ em (Icon/alert, `faEntryTitle` / `faEntrySub`) → `Routes.firstAid`. Decide whether it hides before the pack is on the device, as `FirstAidEntry` does today (open question).
    - Chi tiêu (Icon/grid) → `Routes.spending`, only when `SpendingAccess.any`. Parent and view-all subline: "Tháng này {amount}" with the full amount. Record-only: title "Khoản tôi đã chi", subline "{relation} đã cho phép ghi khoản chi".
    - Thư viện chăm bé (Icon/bookmark, `careLibrary` / `careLibrarySub`) with the badge → toast.
  - **"Gia đình":**
    - Thành viên & chia sẻ (Icon/family). Subline: parent "{n} người · {k} lời mời đang chờ", other roles "Xem thành viên gia đình". Opens FamilyScreen.
    - Mời người thân (Icon/plus, "Ông bà, người chăm cùng theo dõi bé"), Cùng nuôi only → `Routes.invite`.
- Row widget: grouped white card radius 16, rows `px 14 py 12`, 34 px `surface-2` chip, title SemiBold 15, subline Medium 12, chevron 16. Check whether `cl_rows.dart` has a matching grouped row before adding one.
- New ARB ids, vi + en (D-012):
  - `tabUtilities` "Tiện ích";
  - `utilTitle`;
  - sections "Cho bé" and "Gia đình";
  - "Thành viên & chia sẻ";
  - "{n} người";
  - "{k} lời mời đang chờ";
  - "Xem thành viên gia đình";
  - "Mời người thân";
  - "Ông bà, người chăm cùng theo dõi bé";
  - "Khoản tôi đã chi";
  - "{who} đã cho phép ghi khoản chi";
  - "Tháng này {amount}".

### Dock (`cl_navigation.dart`, `home_shell.dart`, router)
- `enum ClTab { today, memories, care, family }` → **`{ today, memories, care, utilities }`**. Label `tabUtilities` "Tiện ích", icon `ClIcons.grid` (exists).
- `tabsForRole`:
  - parent → today, memories, care, utilities;
  - caregiver → today, care, utilities;
  - relative → memories, utilities (+ today when granted) **(inferred)**.
- `shellTabs` / `_tabRoots` / StatefulShellBranch: replace the `/family` branch with a `/utilities` branch (path inferred).
- `/family` and its `invite` children become pushed routes outside the shell (no dock, back button), like `/me`. Redirects that fall back to `Routes.family` (`router.dart` ~484/490) need a new fallback (e.g. `Routes.utilities`).
- Routes `/care/first-aid…` and `/care/spending…` are currently children of the Care branch. Opening them from Tiện ích would switch the active branch to Chăm sóc. Either move them under `/utilities/…` or make them top-level pushed routes (implementation choice; Figma silent).
- **NavBar redesign:**
  - every tab shows an icon (20) above a label (11/16, tracking 0.2);
  - inactive tabs are labelled in `nav-icon`, Medium;
  - active is a white rounded-20 block with a Bold `on-nav-active` label;
  - tab width 64 (4 tabs) or 80 (3 tabs).
  - This replaces the current "icon-only 52 + horizontal labelled pill" with its width-morph animation. The D-048 spring can still drive the background and colour cross-fade (inferred). Update the doc comment `44:362` → NavBar v1.0.1 as drawn in `456:*`.
- Goldens for the dock and every tab root need regenerating (Light/Night × vi/en).

### Gia đình and Tôi
- `FamilyScreen`: drop the tab-root assumptions (dock padding `ClTabDock.contentBottomPadding`, the header without back) and add a back bar.
- `MeScreen`: **add a row "Gia đình" · "{n} thành viên"** (Icon/family) after the babies row → FamilyScreen.
- `tabFamily` stays as the screen title and the Tiện ích section header.

---

## Open questions

1. **Which set is final, CS2 or R?** R3/R4 are newer but labelled "đề xuất" (proposal). Copy differs: "Chăm hằng ngày" vs "Theo dõi bé", and the two sublines. The header differs too (night button vs none; switcher with age).
2. **Night care toggle placement.** R3/R4 drop the top-right night button; R1 turns it into a labelled "Đêm" pill on Hôm nay only. Should Chăm sóc and Tiện ích lose the toggle?
3. **Relative dock and Tiện ích** for Người thân (not drawn): Kỷ niệm · Tiện ích? Can a relative see "Thành viên & chia sẻ"? Do relatives with a D-055 spending right reach Chi tiêu only through Tiện ích?
4. **Sơ cứu row before the pack is downloaded.** Today the entry hides until a guide is on the device. Should the Tiện ích row always show (with a download or offline state)?
5. **Search scope.** "Tìm trong Chăm sóc…" no longer reaches Sơ cứu, Chi tiêu or Thư viện. Should Care search include Tiện ích items, or should Tiện ích get its own search?
6. **"Khoản tôi đã chi" target and subline.** Does it open the 8b month view filtered to "my items", or the add sheet? Do we store who granted the right ("Mẹ đã cho phép…")? What is shown for a non-parent with "Xem toàn bộ chi tiêu"?
7. **"Thành viên & chia sẻ"**: does "chia sẻ" mean the share links (today under Tôi → Liên kết chia sẻ) should also live there, or only members and invites? Does "{n} người" count the current user and the pending invitees?
8. **Two ways to Gia đình.** Tôi → "Gia đình · 4 thành viên" and Tiện ích → "Thành viên & chia sẻ · 4 người · …" use different copy for the same screen. Is that intended?
9. **NavBar redesign scope.** Do labels under every tab apply to every role and to Kỷ niệm (R2 has no "+")? Does the width-morph animation of D-048 go away?
10. **Chi tiêu amount format.** Full "4.215.000 ₫" with "Tháng này" first (Figma), vs today's short "{amount} tháng này". Which wins on the Tiện ích row?
11. **Kỷ niệm R2.** It shows "Dòng thời gian · Ảnh & video" tabs, which conflicts with D-052. Is that part of this proposal? (Out of scope here; flagged only.)
