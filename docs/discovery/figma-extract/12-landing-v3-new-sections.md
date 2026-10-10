# 12 — Landing v3: new sections spec (Figma "Website" page)

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only). Extracted 2026-10-10 with `get_design_context` (React+Tailwind reference output; visible text is authoritative, layer names are truncated/stale) on every new desktop and mobile section, plus `get_metadata` for absolute positions and the exported icon SVGs for stroke colours. Same conventions as `11-landing-specs.md`: token names from `07-foundations-components-motion.md`, non-token values marked **(raw)**, Vietnamese text verbatim.

- Desktop frame `321:1222` "Landing · Desktop v3" — 1440 × 12267.2.
- Mobile frame `324:45487` "Landing · Mobile v3" — 375 × 14466.9.
- Scope of this file: the **five new sections only** (Mọi thứ trong một app, Nhắc nhở, Hiểu con, Thư viện & ăn dặm, Sơ cấp cứu). Everything else keeps the v2 spec in `11-landing-specs.md` (but see §8.11 — some existing sections also changed in v3).
- As in v2: no prototype links, no motion, no hover/focus states, no tablet frame, no dark page variant. Light, static state only.

Screenshots (not committed; regenerate with `get_screenshot` if needed): `d-bento.png`, `m-bento.png`, `d-reminders.png`, `m-reminders.png`, `d-hieu-con.png`, `m-hieu-con.png`, `d-library.png`, `m-library.png`, `d-first-aid.png`, `m-first-aid.png`.

---

## 0. Global

### 0.1 v3 section order

y = top inside the page frame. **NEW** = specified in this file.

| # | Section | Desktop node | Desktop h (y) | Mobile node | Mobile h (y) |
|---|---|---|---|---|---|
| 1 | Nav | 321:1223 | 87 (0) | 324:45488 | 66 (0) |
| 2 | Hero | 321:1235 | 792 (87) | 324:45492 | 859.2 (66) |
| 3 | **Mọi thứ trong một app** (bento) — NEW | 322:1809 | 1080 (879) | 325:2406 "M · Mọi thứ" | 926 (925.2) |
| 4 | Thao tác nhanh | 321:1287 | 1106 (1959) | 324:45534 | 1198.7 (1851.2) |
| 5 | Chăm sóc | 321:1335 | 760 (3065) | 324:45571 | 898.1 (3049.9) |
| 6 | **Nhắc nhở** — NEW | 324:1946 | 760 (3825) | 325:2466 "M · Nhắc nhở" | 786 (3947.9) |
| 7 | Cùng chăm | 321:1368 | 728 (4585) | 324:45603 | 852.1 (4733.9) |
| 8 | **Hiểu con** — NEW | 324:45334 | 1093 (5313) | 325:2533 "M · Hiểu con" | 1897.4 (5586.0) |
| 9 | **Thư viện & ăn dặm** — NEW | 324:2042 | 760 (6406) | 325:2656 "M · Thư viện" | 828 (7483.4) |
| 10 | **Sơ cấp cứu** — NEW | 330:2582 | 760 (7166) | 330:2584 "M · Sơ cấp cứu" | 725 (8311.4) |
| 11 | Tuổi thơ | 321:1414 | 1499 (7926) | 324:45648 | 2136 (9036.4) |
| 12 | Night care | 321:1533 | 688 (9425) | 324:45773 | 656.3 (11172.4) |
| 13 | Quyền xem | 321:1570 | 831 (10113) | 324:45811 | 1375 (11828.7) |
| 14 | CTA | 321:1650 | 415 (10944) | 324:45889 | 361.4 (13203.7) |
| 15 | Hỏi đáp | 321:1672 | 724 (11359) — v2 was 644 | 324:45907 | 749 (13565.1) |
| 16 | Footer | 321:1700 | 184.2 (12083) | 324:45931 | 152.8 (14314.1) |

Heights are hug-content; implement with paddings, not fixed heights. Background: all five new sections are transparent over page `cloud` #F6FCFB.

### 0.2 Nav links and anchors (proposal — anchors are not defined in Figma)

v3 desktop nav links (321:1226, gap 36, Medium 15 `ink-muted`): **"Chăm con" · "Hiểu con" · "Kỷ niệm" · "Gia đình" · "Hỏi đáp"** ("Ban đêm" from v2 is gone). Mobile nav is unchanged: logo + "Tải app" only.

| Nav link | Target section | Proposed id |
|---|---|---|
| Chăm con | Thao tác nhanh (321:1287) — first care section, same as v2 (keeps existing links working) | `#cham-con` |
| **Hiểu con** | **Hiểu con (324:45334)** | **`#hieu-con`** |
| Kỷ niệm | Tuổi thơ | `#ky-niem` |
| Gia đình | Cùng chăm | `#gia-dinh` |
| Hỏi đáp | Hỏi đáp | `#hoi-dap` |

Other ids for the new sections (no nav link): `#tat-ca` (bento "Tất cả trong một app"), `#nhac-nho`, `#thu-vien` (Thư viện & ăn dặm), `#so-cap-cuu`. Keep `#ban-dem` on Night care so old links still resolve. Keep `scroll-margin-top` as in v2.

### 0.3 New shared text styles in v3 sections

| Name (proposed) | Font | Size / line-height | Tracking | Colour | Used in |
|---|---|---|---|---|---|
| `h2` (new sections) | Bold 700 | 44 / 1.18 desktop · **30 / 1.2** mobile | **0** in Figma (v2 sections use −0.66 / −0.3) — see §8.2 | `ink` | all five |
| `lead` | Medium 500 | 18 / 1.55 desktop · 16 / 1.55 mobile | 0 | `ink-muted` | all five (same as v2) |
| `bento-title` | Bold 700 | 20 / 1.25 desktop · 15 / 1.25 mobile | 0 | `ink` | bento tiles |
| `bento-body` | Medium 500 | 14 / 1.5 desktop · 13 / 1.45 mobile | 0 | `ink-muted` | bento tiles |
| `card-title` (Hiểu con columns) | Bold 700 | 22 / normal desktop · 20 / normal mobile | 0 | `ink` | Hiểu con |
| `card-body` (Hiểu con columns) | Medium 500 | 16 / 1.55 desktop · 15 / 1.5 mobile | 0 | `ink-muted` | Hiểu con |
| `chip` | SemiBold 600 | 12 / normal | 0 | per chip | everywhere |

Mobile section head (all five): left-aligned, `display:flex; flex-direction:column; gap:12px` (v2 mobile used 16) → eyebrow, h2, lead.

### 0.4 New eyebrow tones

Eyebrow geometry unchanged (`padding: 6px 12px; radius 999`, SemiBold 13 / normal).

| Section | Pill bg | Text | Existing class? |
|---|---|---|---|
| Mọi thứ trong một app | `mint-soft` | `mint-text` | `.eyebrow--mint` |
| Nhắc nhở | `sunshine-soft` | **`ink`** | **new** (`.eyebrow--sun` uses `care-growth-ink`) — e.g. `.eyebrow--sun-ink` |
| Hiểu con | `care-sleep-soft` | `care-sleep-ink` | **new** — e.g. `.eyebrow--sleep` |
| Thư viện & ăn dặm | `mint-soft` | `mint-text` | `.eyebrow--mint` |
| Sơ cấp cứu | `peach-soft` | `care-bottle-ink` | `.eyebrow--peach` |

### 0.5 Recurring v3 building blocks

**Compact bullet** (Nhắc nhở, Thư viện, Sơ cấp cứu) — differs from the v2 `Bullets` (40 box / 17 / 15):
- List `display:flex; flex-direction:column; gap: 18px` (mobile **16**).
- Row `display:flex; gap:16px; align-items:flex-start`.
- Icon box **36 × 36**: `padding: 9px; border-radius: 12px;` tinted bg; icon **18**, stroke 1.35 (= 1.8 at 24), colour per row.
- Text col `gap: 3px`: title SemiBold **16** / normal `ink`; sub Medium **14 / 1.5** `ink-muted`. Desktop is `white-space: nowrap`; mobile wraps (`flex:1`).
- Implementation: add a `compact` variant to `Bullets` (`.bullets--compact`), do not fork it.

**Chip** (pill) — the generic mock chip used across the new visuals:
- `display:inline-flex; align-items:center; gap:6px; padding: 6px 12px; border-radius: 999px;` SemiBold 12 / normal. Optional leading icon 14 (stroke 1.05 = 1.8 at 24). Height ≈ 27.
- Small variant (food/symptom/time chips): `padding: 4px 10px` (≈ 23 tall). Tag variant (article topic): `padding: 3px 8px`, SemiBold **11** (mobile `padding: 2px 8px`).
- Floating variant (white chip over a panel): `surface` + `shadow-card`.

**Card shadow**: every white card in the new sections uses `drop-shadow(0 8 12 rgba(23,61,68,.08)), (0 1 1 rgba(23,61,68,.06))` or `box-shadow: 0 8 24 / 0 1 2` = the **`shadow-card` token** (Figma names it). Not the v2 raw "float" shadows.

**Push notification** (iOS-style, new; used in bento tile 2 and Nhắc nhở): `background: surface; display:flex; flex-direction:column;` + `shadow-card`.
- Header row `gap:6px; align-items:center`: app icon (`logo-app-icon.svg`, fully rounded clip) + "CHILD LIFE" SemiBold + flex spacer + "bây giờ" Medium, both `ink-muted`.
- Title Bold `ink`; sub Medium `ink-muted`; optional actions row.
- Sizes:

  | Use | Width | Radius | Padding | Gap | App icon | Header text | Title | Sub | Actions |
  |---|---|---|---|---|---|---|---|---|---|
  | Bento tile 2 (desktop) | 249 (fill) | 16 | 10 / 12 | 3 | 16 | 10 | Bold 13 | Medium 12 | none |
  | Nhắc nhở desktop | 400 | 24 | 14 / 16 | 4 | 18 | 11 | Bold 16 | Medium 14 | `padding-top:8px; gap:8px`, pills `padding: 8px 12px`, SemiBold 13 |
  | Nhắc nhở mobile | 299 (fill) | 20 | 12 / 14 | 4 | 16 | 10 | Bold 15 | Medium 13 | `padding-top:6px; gap:6px`, pills `padding: 6px 12px`, SemiBold 12 |

- Not the same as the v2 Tuổi thơ `.notice` (avatar + heart) or the Live Activity — new component.

**Toggle** (app `Toggle` 23:262 "On: mint-deep track. Off: separator track. White knob.", scaled). CSS only, no asset: track `mint-deep`, radius pill; knob white circle, inset 1.7 px at the 0.85 size, `box-shadow: 0 1.7px 3.4px rgba(0,0,0,.15)` **(raw)**. Base 51 × 31 (knob 27, inset 2, shadow 0 2 4 15 %) × scale:

| Where | Size | Scale |
|---|---|---|
| Nhắc nhở desktop | 43.35 × 26.35 | 0.85 |
| Nhắc nhở mobile | 40.8 × 24.8 | 0.8 |
| Hiểu con desktop (WW reminder row) | 38.25 × 23.25 | 0.75 |
| Hiểu con mobile | 32.03 × 19.47 | 0.75 × 0.8375 |

Always "on"; decorative (`aria-hidden`, not a real `<input>`).

**Initial avatar** — small pill with a letter; two variants:
- Overlapping (bento tile 3): `padding: 7px 11px; border: 2px solid surface; radius 999; margin-right: −8px` (last 0), Bold 13. Same pattern as the v2 hero proof avatars (which are `padding: 8px 13px`, SemiBold 14 `ink`) — reuse that markup with a size/colour modifier.
- Inline (Nhắc nhở rule card): `padding: 6px 10px; radius 999`, Bold 12, row `gap:4px`, no border, no overlap.
- Colours (both): **M** `card-peach` / `care-bottle-ink`; **B** `care-sleep-soft` / `care-sleep-ink`; **L** `care-diaper-soft` / `care-diaper-ink`; **H** `mint-soft` / `mint-text`.

**Photo window**: `.photo` (bg `surface-2`, overflow hidden) with an `Illustration/Photo` raster `object-fit: cover`. All photos in the new sections are **existing** files (verified byte-identical): Peach `baby-0d3f8.jpg`, Sun `baby-22456.jpg`, Sky `baby-4222e.jpg`, Night `baby-2d978.jpg`. Use the existing `<Photo>` primitive / `photos` map (`night` is not yet in the map — add `night: baby2d978`).

### 0.6 Icons

All icons are instances of the app icon set (`apps/mobile/assets/icons/*.svg`, `stroke="currentColor"`); no new SVG assets are needed. Stroke width in Figma is always 1.8 at 24 scaled to the drawn size. The landing `Icon` primitive (`apps/landing/src/components/primitives.tsx`) currently lacks: **`spark`, `cake`, `arrow-right`, `search`, `alert`, `drop`** — add these imports (files exist in the app icon folder). Already present and reused: plus, clock, family, star, bookmark, feed, memories, sleep, check, heart, eye, chevron-right.

---

## 1. Mọi thứ trong một app ("Tất cả trong một app" — bento)

### Desktop 322:1809 (1440 × 1080)
`display:flex; flex-direction:column; align-items:center; gap:56px; padding: 112px 96px 64px;`

**Head** (760 wide, col centre, gap 16):
- Eyebrow `mint-soft` / `mint-text`: "Tất cả trong một app"
- H2 44/1.18 centred, 760 wide (1 line): "Mọi điều về con, ở cùng một nơi."
- Lead 18/1.55 centred, 640 wide (2 lines): "Từ cữ bú lúc nửa đêm đến lần đầu con cười — ghi lại thật nhanh, hiểu con hơn mỗi tuần và giữ trọn tuổi thơ của con."

**Bento** 1248 × 680: `display:flex; flex-wrap:wrap; gap:20px;` → 8 tiles **297 × 330** (4 per row; use `grid-template-columns: repeat(4, 1fr); gap: 20px` with `height: 330px`).

Tile: `border-radius: 28px; padding: 24px; display:flex; flex-direction:column; align-items:flex-start; gap:10px;` no shadow.
1. Icon box: `background: surface; padding: 8px; border-radius: 12px;` (36 × 36) + icon 20, stroke 1.5.
2. Title `bento-title` Bold 20/1.25 `ink` (1 line).
3. Body `bento-body` Medium 14/1.5 `ink-muted` (2 lines at 249).
4. Flex spacer (`flex:1`).
5. Footer composition (bottom-aligned, width 249).

| # | Tile (node) | Tile bg | Icon (colour) | Title | Body |
|---|---|---|---|---|---|
| 1 | 322:1861 | `mint-soft` | plus (`mint-text`) | "Ghi trong một chạm" | "Bú, ngủ, tã — ngay trên màn hình chính, cả khi đang bế con." |
| 2 | 322:1881 | `sunshine-soft` | clock (`ink`) | "Nhắc đúng lúc" | "Nhắc bú, ngủ theo giờ cố định hoặc sau lần ghi gần nhất." |
| 3 | 322:1889 | `peach-soft` | family (`care-bottle-ink`) | "Cả nhà cùng chăm" | "Ba mẹ, người chăm, ông bà — ai cũng biết con vừa thế nào." |
| 4 | 322:1907 | `care-sleep-soft` | spark (`care-sleep-ink`) | "Hiểu con theo tuần" | "Thẻ theo tuổi và lịch Wonder Week dự kiến cho từng giai đoạn." |
| 5 | 322:1925 | `care-growth-soft` #FDEDE2 | star (`care-growth-ink`) | "Mốc phát triển" | "Ghi lại lần đầu con cười, lẫy, ngồi — kèm ảnh và ghi chú." |
| 6 | 322:1939 | `surface` + `border: 1px solid separator` | bookmark (`mint-text`) in a **`mint-soft`** icon box | "Thư viện chăm bé" | "Bài viết ngắn về bú, ngủ, mọc răng, sốt — đội chuyên môn rà soát." |
| 7 | 322:1961 | `care-bottle-soft` | feed (`care-bottle-ink`) | "Ăn dặm nhẹ nhàng" | "Nhật ký bữa ăn, món bé đã thử và công thức cho từng giai đoạn." |
| 8 | 322:1968 | `card-peach` #FFA58D | memories (`care-bottle-ink`) | "Giữ trọn tuổi thơ" | "Ảnh, video và câu chuyện của con — riêng tư cho người nhà." |

(Tile 6 has a 1 px border so its content sits at 25 instead of 24 — use `box-sizing: border-box` with padding 24 and the border inside.)

Footers (chips = §0.5 chip, `surface` bg unless stated; chip rows `flex-wrap; gap: 6px`):

1. **Ghi trong một chạm** — two chips stacked (wrap): [feed 14 `care-bottle-ink`] "Bú bình · 120 ml" text `care-bottle-ink`; [sleep 14 `care-sleep-ink`] "Đang ngủ 1:27" text `care-sleep-ink`.
2. **Nhắc đúng lúc** — Push notification, bento size (§0.5): "CHILD LIFE" / "bây giờ" / **"Đến giờ nhắc bú bạn đã đặt"** / "Lần bú gần nhất 11:45". 249 × 73, no actions.
3. **Cả nhà cùng chăm** — col `gap:10px`: overlapping initial avatars **M · B · L · H** (§0.5, ≈ 121 × 34), then chip [check 14 `mint-text`] "Ba Tuấn vừa ghi thay tã" text `mint-text`.
4. **Hiểu con theo tuần** — chips: [cake 14 `ink`] "3 tuần tuổi" text `ink`; "Wonder Week 1 · còn 3 ngày" — bg **`care-sleep-accent`** #6C6FD8, text `surface` (white), no icon.
5. **Mốc phát triển** — milestone row 249 × 60: `background: surface; border-radius: 16px; padding: 10px 12px; display:flex; gap:10px; align-items:center;` photo window 40 × 40 radius 10 (Peach, `baby-0d3f8.jpg`) + col gap 2: Bold 13 `ink` "Mỉm cười đáp lại"; Medium 12 **`mint-text`** "Đã quan sát · 08/10".
6. **Thư viện chăm bé** — topic chips, no icons: `care-sleep-soft`/`care-sleep-ink` "Giấc ngủ"; `sunshine-soft`/`ink` "Mọc răng"; `care-bottle-soft`/`care-bottle-ink` "Bú & sữa".
7. **Ăn dặm nhẹ nhàng** — chips: [check 14 `mint-text`] "Bí đỏ", "Cà rốt", "Bơ" (text `mint-text`); "+11 món" (text `ink`, no icon) wraps to row 2.
8. **Giữ trọn tuổi thơ** — photo fan, 249 × 119.4 box (`position:relative`). Each photo: 96 × 110, `border: 4px solid surface; border-radius: 14px; background: surface-2; overflow:hidden`; image 110 × 110 at (−11, −4) inside the border box (= cover, slightly cropped). Absolute rotated bounding boxes (centre the photo in them), later ones on top:

   | z | Tone / file | Rotation | Bounding box (x, y, w × h) |
   |---|---|---|---|
   | 1 | Peach `baby-0d3f8.jpg` | +6° | (11.5, 0, 107.0 × 119.4) |
   | 2 | Sun `baby-22456.jpg` | −4° | (77.0, 8.2, 103.4 × 116.4) |
   | 3 | Sky `baby-4222e.jpg` | +3° | (156.2, 2.3, 101.6 × 114.9) |

   The third photo ends at x 257.8 (8.8 past the 249 content box, still inside the tile padding — do not clip at the footer).

Reuse: none of the tiles is an existing v2 component; chips, avatars, notification and photo windows are the §0.5 building blocks. The `Photo` primitive covers the photo windows.

### Mobile 325:2406 (375 × 926)
- `display:flex; flex-direction:column; gap:24px; padding: 48px 20px;` head left-aligned (gap 12): eyebrow, H2 **30/1.2** (2 lines "Mọi điều về con, ở / cùng một nơi."), lead 16/1.55 — **shorter text**: "Ghi lại thật nhanh, hiểu con hơn mỗi tuần và giữ trọn tuổi thơ của con."
- Grid `flex-wrap; gap: 12px` → 2 columns of **161.5** wide tiles, **height hugs content** (row 1: 158 / 139, row 2: 158 / 158, row 3: 139 / 141, row 4: 139 / 139 — uneven; recommend `display:grid; grid-template-columns: 1fr 1fr; gap:12px` with `align-items: stretch`).
- Tile: `border-radius: 22px; padding: 16px 14px; gap: 8px;` same backgrounds, border (tile 6) and icon colours as desktop; icon box `padding: 8px; radius 12` with icon **18**; title Bold **15**/1.25 (wraps to 2 lines on tiles 1, 3, 4, 7); body Medium **13**/1.45. **No footer compositions, no spacer.**
- Mobile bodies (shortened, verbatim):

  | # | Body |
  |---|---|
  | 1 | "Bú, ngủ, tã ngay trên màn hình chính" |
  | 2 | "Giờ cố định hoặc sau lần ghi gần nhất" |
  | 3 | "Ai cũng biết con vừa thế nào" |
  | 4 | "Thẻ theo tuổi & Wonder Week" |
  | 5 | "Lần đầu cười, lẫy, ngồi…" (Unicode ellipsis) |
  | 6 | "Đội chuyên môn rà soát" |
  | 7 | "Nhật ký & công thức" |
  | 8 | "Ảnh, video, câu chuyện" |

---

## 2. Nhắc nhở

### Desktop 324:1946 (1440 × 760)
`padding: 96px 96px 64px;` Row `display:flex; align-items:center; gap:96px;` → **Copy (left)** + **Panel 640 × 600 (right)**. In Figma the copy is fixed 560 wide, so the row is **1296** wide and overflows the 1248 content box by 48 px (panel ends at x 1392) — see §8.1; implement with the existing `.split` (copy `flex:1` = 512).

**Copy** (col gap 36). Head (gap 16):
- Eyebrow `sunshine-soft` / **`ink`**: "Nhắc nhở"
- H2 44/1.18, width 560 (2 lines "Nhắc đúng lúc, cả nhà / cùng biết."): "Nhắc đúng lúc, cả nhà cùng biết."
- Lead 18/1.55, width 480 (3 lines): "Đặt nhắc bú, ngủ theo giờ cố định hoặc tự tính từ lần ghi gần nhất. Một người ghi xong, nhắc tự tắt với mọi người."

Compact bullets (§0.5):

| Icon box | Icon (colour) | Title | Sub |
|---|---|---|---|
| `sunshine-soft` | clock (`ink`) | "Hai cách nhắc" | "Giờ cố định, hoặc sau lần bú, ngủ gần nhất" |
| `peach-soft` | family (`care-bottle-ink`) | "Chọn ai nhận nhắc" | "Bố mẹ và người chăm — không làm phiền ông bà" |
| `mint-soft` | check (`mint-text`) | "Xử lý ngay trên thông báo" | "Ghi, báo lại sau hoặc bỏ qua chỉ một chạm" |

**Panel** 640 × 600: `background: sunshine-soft; border-radius: 40px; overflow:hidden; position:relative;` (new `.panel--sun-soft`; v2 `.panel--sun` is `sunshine`). Children (absolute):

| z | Element | Pos | Size |
|---|---|---|---|
| 1 | Notification | (56, 88) | 400 × 136 |
| 2 | Rule card | (204, 262) | 380 × 107 |
| 3 | Fixed-time card | (56, 410) | 250 × 93 |
| 4 | Done chip | (300, 500) | 283 × 28 |

- **Notification** — Push notification, desktop Nhắc nhở size (§0.5): "CHILD LIFE" / "bây giờ" / "Đến giờ nhắc bú bạn đã đặt" / "Lần bú gần nhất 11:45 · 3 giờ trước". Actions: `mint-deep` / `on-mint-deep` "Ghi lần bú"; `surface-2` / `ink` "Báo lại 15 phút"; `surface-2` / `ink` "Bỏ qua".
- **Rule card**: `surface; radius 24; padding: 16px 18px; display:flex; flex-direction:column; gap:10px; shadow-card`.
  - Row 1 `gap:12px; align-items:center`: icon box `care-bottle-soft` (`padding:8px; radius:12px`) + feed 18 (`care-bottle-ink`, 1.35); text col `flex:1; gap:2px`: Bold 16 `ink` "Nhắc bú"; Medium 13 `ink-muted` "3 giờ sau lần bú gần nhất"; Toggle 43.35 × 26.35 (on).
  - Row 2 `gap:8px; align-items:center`: chip `mint-soft` [clock 14 `mint-text`] "Tiếp theo 14:45" text `mint-text`; flex spacer; inline initial avatars (§0.5) **M**, **B**, **L**.
- **Fixed-time card**: `surface; radius 22; padding: 14px 16px; col gap 8; shadow-card`.
  - Row `gap:10px; align-items:center`: icon box `care-sleep-soft` (p 8, r 12) + sleep 18 (`care-sleep-ink`) + Bold 14 `ink` "Nhắc chuẩn bị ngủ".
  - Times row `gap:6px`: small chips `surface-2` / `ink` (`padding: 4px 10px`, SemiBold 12): "09:00", "13:00", "19:30".
- **Done chip**: floating chip (`surface`, `shadow-card`, `padding: 6px 12px`, gap 6): check 14 `mint-text` + SemiBold **13** `mint-text` "Ba Tuấn đã ghi lúc 14:52 · nhắc tự tắt".

Reuse: none of these is a v2 mock; the panel shell matches `.panel` and the done chip is close to `.note-chip`/`.panel-chip` (but `shadow-card` and pill radius).

### Mobile 325:2466 (375 × 786)
- `display:flex; flex-direction:column; gap:24px; padding: 48px 20px;` order **Head → Panel → Bullets** (the visual sits between head and bullets — different from v2 Chăm sóc/Cùng chăm where the visual is last).
- Head (gap 12): eyebrow; H2 30/1.2 (2 lines "Nhắc đúng lúc, cả nhà / cùng biết."); lead 16/1.55 — **different first word**: "Nhắc bú, ngủ theo giờ cố định hoặc tự tính từ lần ghi gần nhất. Một người ghi xong, nhắc tự tắt với mọi người."
- **Panel** — re-composed in normal flow (not a scaled copy): `background: sunshine-soft; border-radius: 32px; padding: 24px 18px; display:flex; flex-direction:column; gap:12px; align-items:flex-start;` (335 × 279). **Fixed-time card removed.**
  1. Notification, mobile size (§0.5), full width (299 × 120): sub is only "Lần bú gần nhất 11:45"; actions "Ghi lần bú", **"Báo lại"**, "Bỏ qua".
  2. Rule card full width (299 × 60): `radius 20; padding: 12px 14px;` **only row 1** (gap 10): icon box + feed 18; Bold **15** "Nhắc bú"; Medium **12** "3 giờ sau lần bú gần nhất"; Toggle 40.8 × 24.8. No "Tiếp theo"/avatars row.
  3. Chip **without shadow** (`surface`, `padding: 6px 12px`): check 14 `mint-text` + SemiBold **12** `mint-text` "Ba Tuấn đã ghi · nhắc tự tắt".
- Bullets: compact, gap 16, text wraps (`flex:1`). Mobile subs (shortened): "Giờ cố định, hoặc sau lần ghi gần nhất"; "Bố mẹ và người chăm"; "Ghi, báo lại hoặc bỏ qua". Titles unchanged.

---

## 3. Hiểu con

### Desktop 324:45334 (1440 × 1093)
`display:flex; flex-direction:column; align-items:center; gap:56px; padding: 112px 96px 96px;`

**Head** (760 wide, centred, gap 16):
- Eyebrow `care-sleep-soft` / `care-sleep-ink`: "Hiểu con"
- H2 44/1.18 centred, 760 wide (1 line): "Hiểu con hơn, mỗi tuần một chút."
- Lead 18/1.55 centred, 620 wide (2 lines): "Gợi ý theo đúng tuổi của con, lịch Wonder Week dự kiến và những mốc đáng nhớ — để bạn bớt lo và tận hưởng nhiều hơn."

**Cards** row 1248, `display:flex; gap:24px; align-items:flex-start;` → 3 columns `flex:1` (400). Column: `display:flex; flex-direction:column; gap:20px;` = **Visual** (400 × **428**, `border-radius: 32px; padding: 22px; display:flex; flex-direction:column; gap:14px;` tinted bg) + **Text** (`gap:6px`: `card-title` Bold 22/normal `ink`; `card-body` Medium 16/1.55 `ink-muted`). Column heights 532 / 557 / 557.

Inner white card style (all three): `background: surface; border-radius: 24px; padding: 16px; display:flex; flex-direction:column; gap:12px; shadow-card;` width 356 (fill).
Secondary row style (cols 2–3, below the card): `background: surface; border-radius: 18px; padding: 12px 14px; display:flex; gap:10px; align-items:center;` **no shadow**, width 356.

**Column 1 — "Thẻ theo tuổi"** (Visual bg `sunshine-soft`). AgeCard at (22, 22), 356 × 384:
1. Photo window 324 × 140, radius 16: Sky photo `baby-4222e.jpg`, Figma draws it 320 × 320 at top −90 (leaves a 4 px `surface-2` strip on the right — Figma slip; use `width:100%; object-fit:cover; object-position: center 64%`).
2. Chips row gap 6: `sunshine-soft` / `ink` "3–4 tuần"; `surface-2` / `ink` "Teddy · 3 tuần".
3. Bold 18/1.3 `ink` (2 lines): "Bé nhìn theo mặt người, nghe giọng quen"
4. Two point rows (`gap:8px; align-items:flex-start`): heart 15 (`care-bottle-ink`, stroke 1.125) + Medium 14/1.5 `ink`:
   - "Nói chuyện, hát nhẹ khi bé thức"
   - "Cho bé nằm sấp vài phút, có người lớn bên cạnh" (2 lines)
5. Footer row `gap:6px; align-items:center`: SemiBold 13 `mint-text` "2 bài viết · 2 mốc thường gặp" + spacer + arrow-right 16 (`mint-text`, 1.2).

Text: "Thẻ theo tuổi" — "Mỗi giai đoạn một thẻ ngắn: bé đang thế nào, ba mẹ có thể thử gì, kèm bài viết và mốc liên quan."

**Column 2 — "Wonder Week"** (Visual bg `care-sleep-soft`). WW card at (22, 22), 356 × 285:
1. Header row `gap:6px; align-items:center`: chip `care-sleep-soft` / `care-sleep-ink` "Wonder Week 1"; spacer; chip `care-sleep-accent` / `surface` (white) "Còn 3 ngày".
2. Bold 20/normal **`care-sleep-ink`** "Cảm giác thay đổi"
3. Medium 13 `ink-muted` "Dự kiến tuần 4–5 · 11/10 – 18/10" (en dashes)
4. **Weeks strip** 324 × 27: `display:flex; gap:3px;` 12 cells `flex:1` (24.25), each col centre `gap:4px`: bar 100 % × 10, radius 5 + label Medium 10 `ink-muted` "1"…"12".

   | Week | Bar | Label |
   |---|---|---|
   | 1, 2, 6, 7, 10 | `surface-2` | Medium 10 `ink-muted` |
   | **3** (current age) | `mint-deep` | **Bold** 10 `mint-text` |
   | 4, 5 (this leap) | `care-sleep-accent` | Medium 10 `ink-muted` |
   | 8, 9, 11, 12 (later leaps) | `care-sleep-accent` at **35 % opacity** | Medium 10 `ink-muted` |

5. SemiBold 12 `ink-muted` "Biểu hiện thường gặp"
6. Small chips `surface-2` / `ink` (wrap, gap 6): "Quấy hơn", "Bám ba mẹ", "Ngủ xáo trộn"
7. SemiBold 12 `ink-muted` "Bé đang học gì"
8. Point row: spark 15 (`care-sleep-ink`, 1.125) + Medium 14/1.5 `ink` "Cảm nhận rõ hơn âm thanh, ánh sáng, mùi"

Reminder row at (22, 321), 356 × 47.25 (secondary row style): clock 16 (`care-sleep-ink`, 1.2) + SemiBold 14 `ink` "Nhắc trước 3 ngày" + spacer + Toggle 38.25 × 23.25 (on).

Text: "Wonder Week" — "Lịch dự kiến theo ngày dự sinh, nhắc trước 3 ngày. Đọc bé đang học gì và ghi lại những gì bạn thấy ở con." (3 lines)

**Column 3 — "Mốc phát triển"** (Visual bg `peach-soft`). Milestone card at (22, 22), 356 × 310:
1. Photos row `gap:8px`: two windows 156 × 150, radius 16: Peach `baby-0d3f8.jpg`, Sun `baby-22456.jpg` (image 156² at top −3 = cover).
2. Chips row gap 6: `mint-soft` [check 14 `mint-text`] "Đã quan sát" (text `mint-text`); `peach-soft` / `care-bottle-ink` "Giao tiếp".
3. Bold 20/normal `ink` "Mỉm cười đáp lại"
4. Medium 13/1.5 `ink-muted` (2 lines): "08/10/2026 · Mẹ ghi · “Bé cười khi mẹ hát sau cữ bú sáng.”" (curly quotes).

Saved row at (22, 346), 356 × 42 (secondary row style): memories 16 (`care-bottle-ink`, 1.2) + SemiBold 14 `ink` "Đã lưu vào Kỷ niệm" + spacer + chevron-right 14 (`ink-muted`, 1.05).

Text: "Mốc phát triển" — "Chọn mốc gợi ý hoặc tự tạo mốc riêng như “Lần đầu về quê”. Thêm ảnh, ghi chú — và lưu thành kỷ niệm." (curly quotes)

**Note** pill, centred, 1104 × 48: `background: surface; border: 1px solid separator; border-radius: 999px; padding: 14px 20px; display:flex; gap:10px; align-items:center;` heart 16 (`care-bottle-ink`, 1.2) + Medium 14 `ink-muted`, `nowrap` in Figma (allow wrapping below ~1180 px): "Nội dung do đội chuyên môn Child Life soạn và rà soát. Lịch Wonder Week chỉ là dự kiến — mỗi bé có nhịp riêng, app không chấm điểm hay so sánh con."

Reuse: the 3-column "visual + title + body" layout is new (closest is v2 Tuổi thơ tiles, but here text sits **outside** the tinted box). Build each visual once at 400 × 428 and reuse it on mobile via `Fit` (below).

### Mobile 325:2533 (375 × 1897.4)
- `display:flex; flex-direction:column; gap:24px; padding: 48px 20px;` head (gap 12): eyebrow; H2 30/1.2 (2 lines "Hiểu con hơn, mỗi / tuần một chút."); lead 16/1.55 — shorter: "Gợi ý theo đúng tuổi, lịch Wonder Week dự kiến và những mốc đáng nhớ."
- Three items stacked (gap 24), each `display:flex; flex-direction:column; gap:14px;` = visual + title Bold **20**/normal + body Medium **15/1.5** (same texts as desktop).
- Visuals 335 × 358.45 = desktop visual × **0.8375** exactly (radius 26.8, padding 18.425, card radius 20.1, all text and icons × 0.8375 — e.g. week labels 8.4 px, chips 10.05 px, Toggle 32.03 × 19.47). Use `Fit` (`w=400, h=428, mobileScale=0.8375`), `aria-hidden`.
- Note: not a pill — `border-radius: 18px; padding: 14px 16px; align-items:flex-start;` heart 16 + Medium **13/1.5** `ink-muted` (wraps, `flex:1`), shorter text: "Nội dung do đội chuyên môn soạn và rà soát. Lịch Wonder Week chỉ là dự kiến — mỗi bé có nhịp riêng."

---

## 4. Thư viện & ăn dặm

### Desktop 324:2042 (1440 × 760)
`padding: 96px 96px 64px;` Row `gap:96px; align-items:center;` → **Copy (left, 560)** + **Panel 640 × 600 (right)** — same 1296-wide overflow as Nhắc nhở (§8.1).

**Copy** (col gap 36). Head (gap 16):
- Eyebrow `mint-soft` / `mint-text`: "Thư viện & ăn dặm"
- H2 44/1.18, width 560 (2 lines "Băn khoăn gì, có bài đọc / ngắn và dễ hiểu."): "Băn khoăn gì, có bài đọc ngắn và dễ hiểu."
- Lead 18/1.55, width 480 (3 lines): "Thư viện chăm bé và thư viện ăn dặm do đội chuyên môn soạn, rà soát và cập nhật. Tìm theo chủ đề, độ tuổi — lưu lại để đọc khi cần."

Compact bullets:

| Icon box | Icon (colour) | Title | Sub |
|---|---|---|---|
| `mint-soft` | search (`mint-text`) | "Tìm và lọc nhanh" | "Theo chủ đề, độ tuổi, thời gian đọc" |
| `care-sleep-soft` | bookmark (`care-sleep-ink`) | "Lưu để đọc lại" | "Bài nào được cập nhật, bạn sẽ thấy ngay" |
| `care-bottle-soft` | feed (`care-bottle-ink`) | "Nhật ký ăn dặm" | "Bữa ăn, lượng bé ăn và những món bé đã thử" |

**Panel** 640 × 600: `background: mint-soft; border-radius: 40px; overflow:hidden; position:relative;` (= `.panel--mint`). Children (absolute, later on top):

| z | Element | Pos | Size |
|---|---|---|---|
| 1 | Search bar | (56, 52) | 528 × 55 |
| 2 | Article A | (56, 140) | 260 × 222 |
| 3 | Solids card | (322, 150) | 290 × 154 |
| 4 | Article B (overlaps A's bottom by 2 px) | (120, 360) | 240 × 213 |
| 5 | Saved chip | (390, 500) | 170 × 28 |

- **Search bar**: `surface; radius 18; padding: 14px 18px; display:flex; gap:10px; align-items:center; shadow-card`: search 18 (`ink-muted`, 1.35) + Medium 15 `ink-muted` "Bé hay giật mình khi ngủ…" (Unicode ellipsis) + spacer + chip `mint-soft` / `mint-text` "0–3 tháng".
- **Article card**: `surface; radius 22; overflow:hidden; shadow-card; display:flex; flex-direction:column;` Photo strip full width, then text block `padding: 12px 16px 16px; gap:4px`: tag chip (`padding: 3px 8px`, SemiBold 11) + Bold 16/1.3 `ink` title + Medium 12 `ink-muted` meta.

  | Card | Photo strip | Photo | Tag (bg / text) | Title | Meta |
  |---|---|---|---|---|---|
  | A | 260 × 130 | Night `baby-2d978.jpg` (cover, image 260² at top −65) | `care-sleep-soft` / `care-sleep-ink` "Giấc ngủ" | "Giấc ngủ của bé sơ sinh" | "6 phút đọc · đội chuyên môn rà soát" |
  | B | 240 × 100 | Sun `baby-22456.jpg` (image 240² at top −70) | `care-sleep-soft` / `care-sleep-ink` "Ăn dặm · Công thức" | "Cháo bí đỏ cho bé mới tập" (2 lines) | "15 phút · 6–7 tháng" |

- **Solids card**: `surface; radius 24; padding: 16px 18px; col gap 10; shadow-card`:
  - Row `gap:10px; align-items:center`: icon box `care-bottle-soft` (p 8, r 12) + feed 18 (`care-bottle-ink`); col `gap:1px`: Medium 12 `ink-muted` "Ăn dặm hôm nay"; Bold 15 `ink` "Cháo bí đỏ · 4 thìa".
  - SemiBold 12 `ink-muted` "Món bé đã thử · 14"
  - Food chips (small, `surface-2` / `ink`, wrap gap 6): "Gạo", "Bí đỏ", "Cà rốt", "Bơ", "Chuối", **"Khoai lang"** (bg `sunshine-soft`, leading spark 12 `ink` stroke 0.9, gap 6 — the "new food" highlight), "+8".
- **Saved chip**: floating chip (`surface`, `shadow-card`): bookmark 14 `mint-text` + SemiBold **13** `mint-text` "Đã lưu vào Thư viện".

### Mobile 325:2656 (375 × 828)
- `gap:24px; padding: 48px 20px;` order **Head → Panel → Bullets**.
- Head: H2 30/1.2 (2 lines "Băn khoăn gì, có bài / đọc ngắn và dễ hiểu."); lead shorter: "Do đội chuyên môn soạn và rà soát. Tìm theo chủ đề, độ tuổi — lưu lại để đọc khi cần."
- **Panel** (flow, re-composed): `background: mint-soft; border-radius: 32px; padding: 20px 16px; display:flex; flex-direction:column; gap:12px;` (335 × 321). **Cards have no shadow.** Article B and the saved chip are removed.
  1. Search: `surface; radius 16; padding: 12px 14px; gap:8px;` search 16 (`ink-muted`, 1.2) + Medium 14 `ink-muted` "Bé hay giật mình khi ngủ…". **No age chip.**
  2. Article A as a horizontal row: `surface; radius 20; padding: 10px; display:flex; gap:12px; align-items:center;` photo 72 × 72 radius 14 (Night) + col `flex:1; gap:3px`: tag (`padding: 2px 8px`, SemiBold 11) "Giấc ngủ"; Bold 15 `ink` "Giấc ngủ của bé sơ sinh"; Medium 12 `ink-muted` **"6 phút đọc"**.
  3. Solids: `surface; radius 20; padding: 14px; gap:8px;` same header row; **no "Món bé đã thử · 14" label**; chips "Gạo", "Bí đỏ", "Cà rốt", "Bơ", "Khoai lang" (`sunshine-soft`, **no spark icon**), **"+9"** (Chuối dropped, so the count still totals 14).
- Bullets compact, gap 16; subs shortened: "Theo chủ đề, độ tuổi"; "Bài cập nhật, bạn thấy ngay"; "Bữa ăn và những món bé đã thử".

---

## 5. Sơ cấp cứu

### Desktop 330:2582 (1440 × 760)
`padding: 96px 96px 64px;` Row `gap:96px; align-items:center;` → **Panel 640 × 600 (left)** + **Copy (right, 560 wide, 504 tall)** — mirrored like v2 Chăm sóc; same 1296-wide overflow (§8.1).

**Copy** (col gap 36). Head (gap 16):
- Eyebrow `peach-soft` / `care-bottle-ink`: "Sơ cấp cứu"
- H2 44/1.18, width 560 (3 lines "Khi con gặp chuyện bất / ngờ, bạn đã có sẵn / hướng dẫn."): "Khi con gặp chuyện bất ngờ, bạn đã có sẵn hướng dẫn."
- Lead 18/1.55, width 480 (3 lines): "Những tình huống nhỏ thường gặp ở trẻ — sốt, ngã, bỏng nhẹ, côn trùng cắn — được giải thích ngắn gọn, nhẹ nhàng để bạn bình tĩnh chăm con."

Compact bullets:

| Icon box | Icon (colour) | Title | Sub |
|---|---|---|---|
| `peach-soft` | heart (`care-bottle-ink`) | "Tình huống thường gặp" | "Sốt, ngã, bỏng nhẹ, hóc dị vật, côn trùng cắn…" |
| `sunshine-soft` | eye (`ink`) | "Từng bước, có hình minh hoạ" | "Dễ đọc cả khi đang bế con" |
| `mint-soft` | check (`mint-text`) | "Rà soát cùng chuyên gia y tế" | "Luôn nhắc bạn hỏi bác sĩ khi cần" |

**Panel** 640 × 600: `background: peach-soft; border-radius: 40px; overflow:hidden; position:relative;`. Single child: **FirstAid card** at (70, 96.125), 500 × 418.25 — an app-style card at **×1.25** (the mobile version is the same card at ×1, see below; build once at ×1 = 400 wide and `transform: scale(1.25)` on desktop, or author both sizes from the table).

FirstAid card (desktop values; ×1 in brackets): `background: surface; border-radius: 35px [28]; padding: 22.5px [18]; display:flex; flex-direction:column; gap: 17.5px [14]; shadow-card ×1.25`.
1. Header row `gap: 12.5 [10]; align-items:center`: icon box `peach-soft` (`padding: 10 [8]; radius 15 [12]`) + heart 25 [20] (`care-bottle-ink`, stroke 1.875 [1.5]); col gap 1.25 [1]: Bold 22.5 [18] `ink` "Sơ cấp cứu"; Medium 15 [12] `ink-muted` "Hướng dẫn từng bước, dễ làm theo".
2. Topics grid: 2 columns, `gap: 10px`, tiles 222.5 × 57.5: `background: surface-2; border-radius: 20px; padding: 12.5px; display:flex; gap:10px; align-items:center;` icon box (`padding: 7.5px; radius 12.5px`) + icon 17.5 (stroke 1.3125) + SemiBold 17.5 `ink`:

   | Topic | Icon box | Icon (colour) |
   |---|---|---|
   | "Hóc dị vật" | `peach-soft` | alert (`care-bottle-ink`) |
   | "Sốt" | `sunshine-soft` | drop (`ink`) |
   | "Bỏng nhẹ" | `care-bottle-soft` | spark (`care-bottle-ink`) |
   | "Ngã, va đập" | `care-sleep-soft` | heart (`care-sleep-ink`) |
   | "Côn trùng cắn" | `care-diaper-soft` | eye (`care-diaper-ink`) |
   | "Chảy máu cam" | `mint-soft` | drop (`mint-text`) |

3. Step row (455 × 97.5): `background: peach-soft; border-radius: 22.5px; padding: 15px 17.5px; display:flex; gap:15px; align-items:center;` photo 60 × 60 radius 15 (Peach `baby-0d3f8.jpg`) + col `flex:1; gap:2.5px`: SemiBold 15 `care-bottle-ink` "Bỏng nhẹ · bước 1/4"; Medium 16.25/1.4 `ink` (2 lines) "Giữ bình tĩnh, làm theo từng bước có hình minh hoạ".

### Mobile 330:2584 (375 × 725)
- `display:flex; flex-direction:column; gap:20px; padding: 48px 20px;` order **Head → Panel**. **No bullets on mobile.**
- Head (gap 12): H2 30/1.2 (3 lines "Khi con gặp chuyện / bất ngờ, bạn đã có / sẵn hướng dẫn."); lead shorter: "Sốt, ngã, bỏng nhẹ, côn trùng cắn — giải thích ngắn gọn, nhẹ nhàng để bạn bình tĩnh chăm con."
- Panel (flow): `background: peach-soft; border-radius: 32px; padding: 20px 16px;` (335 × 374) containing the FirstAid card full width (303): `radius 28; padding 18; gap 14; shadow-card;` header at ×1 (icon box p 8 r 12 + heart 20; Bold 18; Medium 12).
  - Topics: tiles **129.5** wide, `gap: 8px`, `background: surface-2; radius 16; padding: 10px 8px; gap: 6px;` icon box `padding: 6px; radius 10px` + icon 14; SemiBold **13** `ink`. "Chảy máu cam" (≈ 143 px of content) overflows its 129.5 tile by ~13 px in Figma — allow the label to wrap or reduce the inner gap.
  - Step: `radius 18; padding: 12px 14px; gap: 12px;` photo 48 × 48 radius 12; SemiBold **12** `care-bottle-ink` "Bỏng nhẹ · bước 1/4"; Medium **13**/1.4 `ink` (2 lines).

---

## 6. Mobile behaviour summary (new sections)

| Section | Desktop | Mobile |
|---|---|---|
| Bento | 4 × 2 tiles 297 × 330 with footer mock-ups | 2-col grid 161.5 wide, text-only tiles, shortened bodies |
| Nhắc nhở | Copy left / absolute panel right | Head → re-composed flow panel (2 cards + chip, no Fixed card) → bullets |
| Hiểu con | 3 columns | 3 stacked items; visuals = desktop × 0.8375 (scale-transform with `Fit`) |
| Thư viện | Copy left / absolute panel right | Head → flow panel (search, 1 article row, solids; no shadows) → bullets |
| Sơ cấp cứu | Panel left / copy right | Head → panel (card at ×1); **no bullets** |

Unlike v2 (uniform scale-downs), Nhắc nhở, Thư viện and Sơ cấp cứu panels are **re-composed** on mobile at readable sizes; only Hiểu con uses a uniform scale. Mobile H2 is 30/1.2 throughout; mobile head gap 12; mobile bullets gap 16.

All mock visuals are decorative (`aria-hidden="true"`, their texts are illustrative); real content lives in the copy. Section copy and tile/card titles + bodies are real content and must go through the web `messages`/content catalogs (`apps/landing/src/content/vi.ts` + `en.ts`, same ids — D-012). Mobile shortened texts need either separate content keys or a decision to use one text for both (§8.4).

---

## 7. Assets

**No new asset files were added.** Everything needed already exists:

| Need | Source |
|---|---|
| Photos | `apps/landing/src/assets/figma/baby-0d3f8.jpg` (Peach), `baby-22456.jpg` (Sun), `baby-4222e.jpg` (Sky), `baby-2d978.jpg` (Night). The Figma rasters for these sections were downloaded and are byte-identical to the existing files (220 × 220 JPEG — soft at 2× in the 324 × 140 AgeCard window and 260 × 130 article strip; request higher-res originals if that matters). |
| App icon in notifications | `apps/landing/src/assets/figma/logo-app-icon.svg` (render at 16 / 18 with `border-radius: 50%`-style clip — Figma clips with a very large radius). |
| Line icons | `apps/mobile/assets/icons/`: plus, clock, family, spark, star, bookmark, feed, memories, sleep, check, cake, heart, arrow-right, chevron-right, search, alert, drop, eye. Add `spark`, `cake`, `arrow-right`, `search`, `alert`, `drop` to the landing `Icon` map. |
| Toggle, weeks strip, chips, avatars, photo fan | CSS only. |

---

## 8. Ambiguities / gaps

1. **Row overflow (Nhắc nhở, Thư viện, Sơ cấp cứu):** copy is fixed 560 wide + gap 96 + panel 640 = 1296 > 1248 content, so the panel ends at x 1392 (48 px right margin vs 96 left). Recommend the existing `.split` (copy `flex:1` → 512, same as v2 Chăm sóc/Cùng chăm). Check H2 wrapping at 512: "Băn khoăn gì, có bài đọc ngắn và dễ hiểu." and "Khi con gặp chuyện bất ngờ…" may gain a line.
2. **H2 tracking:** new-section H2s have letter-spacing 0 (desktop 44/1.18, mobile 30/**1.2**) while existing v3 sections keep −0.66 (verified on 321:1348) and v2 mobile 30/1.18 −0.3. Recommend the shared `.h2` everywhere (treat as a design slip) unless design confirms.
3. **Two bullet styles** on one page: v2 (40 box, 17/15) and v3 compact (36 box, 16/14). Implement as a variant; ask design whether to unify.
4. **Desktop vs mobile copy differs** in many places (leads, bento bodies, bullet subs, "Báo lại 15 phút" vs "Báo lại", "+8" vs "+9", notification sub, Hiểu con note). Either add mobile-specific content keys (the site already has `only-desktop-inline` / `only-mobile-inline`) or pick one text — owner/design call. English needs drafting for all new strings.
5. **Mobile bento tiles have uneven heights** (hug content, `items-start`); recommend stretch.
6. **AgeCard photo** is 320 wide in a 324 window (4 px strip) — implement as cover.
7. **Mobile "Chảy máu cam" topic** overflows its tile.
8. **Contrast:** bento tile 8 body `ink-muted` on `card-peach` ≈ **2.8:1** (fails AA for 14 px); white on `care-sleep-accent` chip ("Wonder Week 1 · còn 3 ngày", "Còn 3 ngày") ≈ **4.3:1** (just below AA for 12 px SemiBold). Suggest `ink` (6.2:1) for the tile 8 body and `care-sleep-ink` for the chip bg, pending design.
9. **Terminology:** Nhắc nhở uses "Bố mẹ" ("Bố mẹ và người chăm…") while the rest of the site and app use "Ba mẹ". Likely should be "Ba mẹ".
10. **Product claims vs V1 scope (`docs/product/business-map.md`)** — needs owner confirmation before shipping this copy:
    - Reminders: the page promises interval reminders ("3 giờ sau lần bú gần nhất"), choosing recipients, actionable notifications (Ghi / Báo lại / Bỏ qua) and "Một người ghi xong, nhắc tự tắt với mọi người". V1 reminders are shared to-dos with a **local notification on the creating device only** (R-091, R-092), no interval rules, no recipient choice, no auto-dismiss on log.
    - Hiểu con (age cards, Wonder Week calendar with reminders, milestones), Thư viện chăm bé, ăn dặm diary/recipes and Sơ cấp cứu have **no D/R/P entries** in the business map — not in the current V1 scope. "Đội chuyên môn rà soát" / "Rà soát cùng chuyên gia y tế" are content-governance claims that also need backing; first-aid content may carry medical/legal review requirements.
    - Bento tile 1 "ngay trên màn hình chính" (widgets) and tile 3 are consistent with existing features.
11. **Other v3 changes outside these five sections (not extracted here):** nav links ("Ban đêm" → "Hiểu con"); Hỏi đáp is re-written (desktop 724 tall; subtitle now starts "Chưa thấy câu trả lời? Gửi cho…"; answers re-worded, e.g. "Phù hợp nhất với bé từ sơ sinh…", "Miễn phí. Cả gia đình dùng chu…"; "Có dùng được trên Android không?" replaced by "Có cần ghi đủ mỗi ngày không?"; new questions "Lịch Wonder Week có đúng với mọi bé không?" and "Nội dung gợi ý trong app do ai soạn?" exist in the frame); mobile hero is 859.2 tall (v2 827.2). Run a v2→v3 diff pass on those sections before implementing (layer names are stale; use `get_design_context`).
12. Link targets: bento tiles, "2 bài viết · 2 mốc thường gặp →", "Đã lưu vào Kỷ niệm ›" look tappable but are mock UI — no targets; keep them non-interactive.
