# 11 — Landing page implementation spec (Figma "Website" page 210:759)

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only). Extracted 2026-10-10 with `get_design_context` (React+Tailwind reference output, visible text authoritative) for every desktop and mobile section, plus the 9 `Illustration/Photo` tone components. This supersedes the Website part of `06-story-links-website.md` (several strings and layout details there were from stale layer names or were incomplete — see §0.4).

- Desktop frame `219:1391` "Landing · Desktop v2" — 1440 × 7734.
- Mobile frame `233:804` "Landing · Mobile v2" — 375 × 9273.
- No prototype links, no motion/keyframes, no hover/pressed/focus states, no tablet frame and no Night (dark) variant of the page are defined in Figma. Everything below is the default (Light) static state.

Token names are from `07-foundations-components-motion.md` (CSS vars in `@child-life/design-tokens`). When a value is not a token it is given as a raw value and marked **(raw)**.

---

## 0. Global

### 0.1 Page
| Item | Desktop | Mobile |
|---|---|---|
| Page background | `cloud` #F6FCFB (all sections are transparent over it, except Tuổi thơ = `surface` #FFFFFF) | same |
| Content width | 1248 (side padding 96 at 1440) | 335 (side padding 20 at 375) |
| Font | Be Vietnam Pro — **Bold 700** (all headings), SemiBold 600, Medium 500. Regular 400 is not used on the landing. All four weights already exist in `apps/landing/public/fonts/`. | same |
| Extra fonts | StoryCard art only (Tuổi thơ tile 2): **Lora** Regular + Italic, **Dancing Script** Regular (Google Fonts, OFL). Text there is 4.5–15 px decoration. | same |

Section order and frame sizes (y = top inside the page frame):

| # | Section | Desktop node | Desktop h (y) | Mobile node | Mobile h (y) |
|---|---|---|---|---|---|
| 1 | Nav | 219:1392 | 87 (0) | 233:805 | 66 (0) |
| 2 | Hero | 219:1413 | 792 (87) | 233:818 | 827.2 (66) |
| 3 | Thao tác nhanh | 231:162 | 1106 (879) | 233:860 | 1198.7 (893.2) |
| 4 | Chăm sóc | 220:1801 | 760 (1985) | 233:995 | 898.1 (2091.9) |
| 5 | Cùng chăm | 220:1918 | 728 (2745) | 233:1027 | 852.1 (2989.9) |
| 6 | Tuổi thơ | 232:627 | 1499 (3473) | 233:1072 | 2136 (3842) |
| 7 | Night care | 221:2845 | 688 (4972) | 233:1296 | 656.3 (5978) |
| 8 | Quyền xem | 221:3347 | 831 (5660) | 233:1336 | 1375 (6634.3) |
| 9 | CTA | 221:3443 | 415 (6491) | 233:1430 | 361.4 (8009.3) |
| 10 | Hỏi đáp | 221:3455 | 644 (6906) | 233:1448 | 749 (8370.7) |
| 11 | Footer | 221:3488 | 184.2 (7550) | 233:1477 | 152.8 (9119.7) |

Heights are hug-content results of the paddings below; implement with paddings, not fixed heights.

### 0.2 Shared text styles used by the landing (not app text styles)
| Name (proposed) | Font | Size / line-height | Tracking | Colour |
|---|---|---|---|---|
| `display` (hero H1) | Bold 700 | 57 / 1.12 (desktop) · 31 / 1.12 (mobile) | −1.14 · −0.62 (= −2%) | `ink`; lines 2–3 `mint-text` #06716D |
| `h2` | Bold 700 | 44 / 1.18 (desktop) · 30 / 1.18 (mobile; Night care 28, CTA 28/1.2) | −0.66 · −0.3 (Night −0.42, CTA −0.28) | `ink` |
| `lead` (section subtitle) | Medium 500 | 18 / 1.55 (desktop) · 16 / 1.55 (mobile) | 0 | `ink-muted` |
| `hero-lead` | Medium 500 | 20 / 32 (desktop) · 16 / 32 (mobile) | 0 | `ink-muted` |
| `eyebrow` (pill) | SemiBold 600 | 13 / normal (hero eyebrow: 14) | 0 | per section |
| `bullet-title` | SemiBold 600 | 17 / normal | 0 | `ink` |
| `bullet-sub` | Medium 500 | 15 / normal | 0 | `ink-muted` |
| `tile-title` | Bold 700 | 19 (mobile 18) / normal | 0 | `ink` |
| `tile-body` | Medium 500 | 15 (mobile 14) / 1.5 | 0 | `ink-muted` |
| `small` | Medium 500 | 14 / normal | 0 | `ink-muted` |

"normal" line-height = font default (~1.26 for Be Vietnam Pro); use `line-height: normal` or 1.26.

Eyebrow pill geometry (all sections except hero): `padding: 6px 12px; border-radius: 999px` (hug ≈ 28 tall). Hero eyebrow: `padding: 8px 14px` (34 tall). Eyebrow colours differ per section:

| Section | Pill bg | Text |
|---|---|---|
| Hero | `mint-soft` | `mint-text`, text "●  Miễn phí cho cả gia đình" (bullet + 2 spaces, `white-space: pre`) |
| Thao tác nhanh, Chăm sóc | `mint-soft` | `mint-text` |
| Cùng chăm | `peach-soft` | `care-bottle-ink` #1D5F99 |
| Tuổi thơ | `sunshine-soft` | `care-growth-ink` #9A4A14 |
| Night care | `mint-deep` | `on-mint-deep` (white) |
| Quyền xem | `card-peach` #FFA58D | `care-bottle-ink` #1D5F99 |

### 0.3 Recurring shadows (Figma raw → token)
| Raw in design | Use token |
|---|---|
| `drop-shadow(0 8 12 rgba(23,61,68,.08)), (0 1 1 rgba(23,61,68,.06))` | `shadow-card` (0 1 2 #173D440F, 0 8 24 #173D4414) |
| `0 11.8 17.6 rgba(23,61,68,.16)` (FloatChip) | `shadow-chip` (0 8 24 #173D4429) scaled |
| `0 12 26.4 −4.8 rgba(18,46,51,.16), 0 2.4 4.8 rgba(18,46,51,.1)` (CareTile ×1.2) | `shadow-tile` ×1.2 |
| `0 18 40 rgba(13,38,33,.14)` widgets / lock screen; `0 16 18 rgba(13,38,33,.14)` polaroids, chips, notifications; `0 16 36 rgba(13,38,33,.14)` StoryCard / night widgets; `0 18 20 rgba(13,38,33,.14)` floating chips | **(raw)** landing-only "float" shadows — tint #0D2621 @14%. Recommend one token `--shadow-float: 0 16px 36px rgba(13,38,33,.14)` |
| `0 30 60 rgba(13,38,38,.25)` hero phones | **(raw)** `--shadow-phone` |
| `0 12 28 rgba(0,26,26,.12)` hero chips | **(raw)** close to `shadow-chip` |

### 0.4 Corrections vs `06-story-links-website.md`
- Thao tác nhanh: the left stage widget is **Widget/Large** (with "Thứ Năm, 8 tháng 10", sleep status, quick log, recent list, totals); the **Widget/Medium** shows only header "Teddy · 2 cữ · ngủ 7g50 hôm nay" + 4 quick tiles. The caption chip text is "Một chạm là đã ghi xong" (separate from the "→" chip).
- Quyền xem, Người chăm → Chăm con sub is "Ghi lại việc chăm bé trong ngày".
- Cùng chăm H2 is "Cả nhà cùng chăm, không ai phải hỏi lại." (layer name "Cả nhà cùng một nhịp…" is stale).
- Mobile hero: no proof/avatar row; mobile CTA: no caption under badges; mobile FAQ: no subtitle (confirmed).
- The `Illustration/Photo` placeholders are **raster baby photographs** (220×220 JPEG) over a tone gradient, not vector illustrations. Tones Sand / Leaf / Rose reuse the Mint gradient.

---

## 1. Nav

### Desktop 219:1392 (1440 × 87)
- `display:flex; align-items:center; padding: 22px 96px;` no background (sits on `cloud`). Not sticky in Figma (no fixed-position info) — sticky is an implementation choice.
- Left: **Logo/Lockup Horizontal** 175.9 × 34 = Logo/Mark 34 × 34 (`nav-logo-mark.svg`) + gap 9.52 + Logo/Wordmark 132.4 × 26.52 (`nav-logo-wordmark.svg`, ink).
- Spacer `flex:1`.
- Links row, gap 36, Medium 15 / normal, `ink-muted`, no underline, verbatim: **"Chăm con" · "Kỷ niệm" · "Gia đình" · "Ban đêm" · "Hỏi đáp"**.
- Fixed spacer 40.
- CTA button 133 × 43: `background: ink; color: surface; padding: 12px 22px; border-radius: 999px;` SemiBold 15: **"Tải miễn phí"**.

### Mobile 233:805 (375 × 66)
- `justify-content: space-between; padding: 14px 20px`.
- Lockup at 0.78 scale: mark 26.52 + gap 7.43 + wordmark 103.3 × 20.7.
- Button 85 × 38: **`mint-deep`** bg (desktop uses `ink`), `on-mint-deep` text, `padding: 10px 16px; radius 999`, SemiBold 14: **"Tải app"**.
- No links, no hamburger, no drawer is designed. Mobile navigation = logo + download button only.

### Anchors (not defined in Figma — proposed mapping)
| Nav link | Target section | Proposed id |
|---|---|---|
| Chăm con | Thao tác nhanh (231:162) — first care section; Chăm sóc follows | `#cham-con` |
| Kỷ niệm | Tuổi thơ (eyebrow "Kỷ niệm") | `#ky-niem` |
| Gia đình | Cùng chăm (co-care) — alternative: Quyền xem (roles) | `#gia-dinh` |
| Ban đêm | Night care | `#ban-dem` |
| Hỏi đáp | Hỏi đáp | `#hoi-dap` |
| Tải miễn phí / Tải app | CTA band (store badges) — or direct store link by user agent | `#tai-app` |
Other ids: `#gioi-thieu` (hero), `#cham-soc`, `#rieng-tu` (Quyền xem). Use `scroll-margin-top` ≈ 87 if the nav is made sticky.

---

## 2. Hero

### Desktop 219:1413 (1440 × 792)
Layout: `display:flex; align-items:center; gap:40px; padding: 56px 96px 96px;` → Copy column `flex:1` (608 wide, 537 tall, `gap: 28px`, items start) + Visual 600 × 640.

Copy (top to bottom):
1. Eyebrow pill (see §0.2) 215 × 34: "●  Miễn phí cho cả gia đình".
2. H1 `display` 57 / 1.12, −1.14, 3 lines (608 wide, 192 tall):
   - "Cùng chăm con." — `ink`
   - "Giữ từng khoảnh khắc" — `mint-text`
   - "con lớn lên." — `mint-text`
3. Lead Medium 20 / 32 `ink-muted` (2 lines at 608): "Một không gian riêng tư cho cả nhà: cùng chăm con, lưu ảnh, video, câu chuyện và nhìn lại hành trình con lớn lên."
4. Download block (col, gap 12):
   - Store badges row, gap 12 — see §12 Store badges (dark variant): "Tải trên / App Store" (189.2 × 67) and "Tải trên / Google Play" (210.2 × 67).
   - Caption Medium 14 `ink-muted`: "Miễn phí trên iPhone và Android."
5. Proof row (589 × 38, items center): 4 overlapping initial avatars then text.
   - Avatar = pill `padding: 8px 13px; border: 2px solid surface; radius 999; margin-right: −8px;` SemiBold 14 `ink`. Order/fill: **M** `peach-soft`, **B** `sunshine-soft`, **L** `mint-soft`, **H** `surface-2` (≈ 40 × 38 each; later avatars on top).
   - Text Medium 14 `ink-muted`: "Ba mẹ, người chăm và ông bà — ai cũng có chỗ của mình bên con" (Figma prefixes 4 spaces; use `margin-left: 16px` instead → text starts at x 147).

Visual (600 × 640, `position:relative`, overflow visible — chip 1 hangs 40 px left of the box):
- z0 Circle 560 × 560 at (30, 40), `mint-soft` (CSS circle).
- z1 **Phone A** (Today): rotated −4°. Rotated bounding box 308.4 × 577.5 at (30, 61.2); centre the 270 × 560 phone in it.
  - Body 270 × 560, `background:#121618` **(raw)**, radius 43.2, `box-shadow: 0 30px 60px rgba(13,38,38,.25)`, overflow hidden.
  - Screen inset 8 → 254 × 544, radius 37.8, bg `cloud`, overflow hidden; image `hero-snapshot-today.png` placed top-left at 254 × 762 (cropped at bottom; source 1125 × 3375).
- z2 **Phone B** (Album): rotated +3°. Bounding box 321 × 614.4 at (248.6, 20). Body 290 × 600 radius 46.4 (same colour/shadow); screen 274 × 584 radius 40.6; image `hero-snapshot-album.png` at 274 × 593.3 (source 750 × 1624).
- z3 **Chip 1** at (−40, 470), 203 × 64: `background: surface; radius 18; padding: 12px 16px; gap 10; box-shadow: 0 12px 28px rgba(0,26,26,.12)`.
  - Thumb 40 × 40 radius 12, overflow hidden: Illustration/Photo **Peach** (`photo-peach.svg` or `baby-0d3f8.jpg` cover).
  - Text col gap 2: SemiBold 14 `ink` "Bú bình · 120 ml"; Medium 12 `ink-muted` "Mẹ ghi · 2 phút trước".
- z4 **Chip 2** at (300, 560), 284 × 64, same style; thumb Photo **Mint** (`baby-61240.jpg`); "Bà nội thương ảnh của Teddy" / "vừa xong".

### Mobile 233:818 (375 × 827)
- Single column `gap: 20px; padding: 24px 20px 48px;` all left-aligned, order: eyebrow → H1 → lead → download → visual. **No proof row.**
- H1 31 / 1.12, −0.62 (same 3 lines/colours). Lead Medium 16 / 32 (3 lines).
- Badges: row `gap:10`, each `flex:1` (162.5 × 54.9), content centred, mobile badge metrics (§12). Caption Medium **13** `ink-muted` "Miễn phí trên iPhone và Android."
- Visual box 335 × 357.3 = desktop visual × **0.5583** (all coords/sizes multiplied): circle 312.7 at (16.75, 22.3); phone A body 150.75 × 312.7 r 24.1, bezel 4.47; phone B 161.9 × 335 r 25.9; chip radius 10.05, padding 6.7/8.9, thumb 22.3 r 6.7, texts **7.8 / 6.7 px** (too small to read — recommend rendering the desktop visual with `transform: scale(.5583)` and accepting it as decoration, or bumping chip text to ≥ 11 px); chip 1 at (−22.3, 262.4) bleeds ~2 px past the viewport edge (clip with `overflow-x: hidden` on the page).

---

## 3. Thao tác nhanh ("Khi bận tay")

### Desktop 231:162 (1440 × 1106)
`display:flex; flex-direction:column; align-items:center; gap:48px; padding: 96px 96px 64px;`

**Head** (1100 wide, col centre, gap 16):
- Eyebrow `mint-soft`/`mint-text`: "Khi bận tay"
- H2 44, centred, 1100 wide (1 line): "Tay bế con, vẫn ghi lại được trong một chạm."
- Lead 18/1.55 centred, 660 wide (2 lines): "Không cần mở app, không cần nhớ giờ. Chạm ngay trên màn hình điện thoại là xong — để bạn ở bên con lâu hơn một chút."

**Stage** 1248 × 600, `border-radius: 40px; overflow:hidden; position:relative;`
`background: linear-gradient(147.34deg, #D1F0E8 0%, #EDEBFA 39.286%, #FCE5DB 71.429%)` **(raw)**.
Children (absolute, x/y inside stage):

| z | Element | Pos | Size |
|---|---|---|---|
| 1 | Label pill "Ngay trên màn hình điện thoại" | (56, 48) | 221 × 32 |
| 2 | Widget/Large | (56, 100) | 364 × 382 |
| 3 | Widget/Medium | (452, 100) | 364 × 170 |
| 4 | Widget/Small (Bottle, default) | (452, 294) | 170 × 170 |
| 5 | Widget/Small (Bottle, logged) | (646, 294) | 170 × 170 |
| 6 | Tap ring | (570, 410) | 44 |
| 7 | Tap dot | (584, 424) | 16 |
| 8 | Arrow chip "→" | (608, 364) | 34 × 30 |
| 9 | Note chip "Một chạm là đã ghi xong" | (452, 484) | 210 × 36 |
| 10 | Label pill "Cả khi điện thoại đang khoá" | (876, 48) | 210 × 32 |
| 11 | Lock screen | (876, 100) | 316 × 440 |

- **Label pills**: `background: rgba(255,255,255,.8); padding: 8px 14px; radius 999;` SemiBold 13 `ink`.
- **Widget shell** (all four): `background: surface` (logged small widget: `care-bottle-soft`), `border-radius: 22px; padding: 14px; box-shadow: 0 18px 40px rgba(13,38,33,.14); overflow:hidden; display:flex; flex-direction:column;`
- **Widget/Large** (col, gap 10):
  1. Header row gap 6, items centre: `illustrations/baby-face.svg` 22 + "Teddy" SemiBold 14/20 `ink` + right-aligned flex-1 "Thứ Năm, 8 tháng 10" Medium 12/16 +0.2 `ink-muted`.
  2. Sleep status row: `care-sleep-soft`, radius 16, `padding: 10px 12px`, gap 10: `mini-moon.svg` 36 + col("Đã thức 2 giờ" Medium 17/24 `ink`; "Dậy lúc 13:05 · ngủ 7g50 hôm nay" Medium 12/16 +0.2 `ink-muted`) + pill button h 34, `padding: 0 12px`, `care-sleep-accent` bg, SemiBold 14/20 white "Ngủ".
  3. Quick-log row (gap 8) of 4 QuickTiles — see below.
  4. "Gần đây" SemiBold 12/16 +0.2 `ink-muted`.
  5. Recent list col gap 8; row gap 10 items centre: dot 8 (care accent) + time Medium 12/16 `ink-muted` width 36 + label Medium 14/20 `ink` flex-1 + who Medium 12/16 `ink-muted`:
     - (#3B8FD9 `care-bottle-accent`) "14:20" "Bú bình · 120 ml" "Mẹ"
     - (#5DAA4E `care-diaper-accent`) "13:40" "Thay tã · Ướt" "Cô Lan"
     - (#6C6FD8 `care-sleep-accent`) "11:45" "Ngủ 1 giờ 20 phút" "Ba"
  6. Flex spacer, then Totals bar: `surface-2`, radius 12, `padding: 8px 12px`, Medium 12/16 +0.2 `ink-muted`: "Hôm nay: 2 cữ bình 240 ml · 1 lần bú mẹ · 2 tã".
- **QuickTile** (flex 1, col centre, gap 4, `padding: 10px 6px`, radius 16, `position:relative`): art 34 + label SemiBold 12/16 +0.2 in care ink + value Medium 12/16 +0.2 `ink-muted`; plus badge 22 × 22 white circle at top 6 / right 6 containing `icons/plus.svg` 14 stroked in care ink.

  | Tile | bg | art | label (colour) | value |
  |---|---|---|---|---|
  | Bú bình | `care-bottle-soft` | `mini-bottle.svg` | "Bú bình" (`care-bottle-ink`) | "45 phút" |
  | Bú mẹ | `care-breast-soft` | `mini-drop.svg` | "Bú mẹ" (`care-breast-ink`) | "3g 35p" |
  | Ngủ | `care-sleep-soft` | `mini-moon.svg` | "Ngủ" (`care-sleep-ink`) | "thức 2g" |
  | Thay tã | `care-diaper-soft` | `mini-diaper.svg` | "Thay tã" (`care-diaper-ink`) | "1g 25p" |
- **Widget/Medium** (gap 12): header (baby-face + "Teddy" + right "2 cữ · ngủ 7g50 hôm nay") + the same 4 QuickTiles.
- **Widget/Small default**: top row gap 8 (`mini-bottle.svg` 30 + "Bú bình" SemiBold 14/20 `care-bottle-ink`), 10 px gap, "45 phút trước" SemiBold 19/26 `ink`, "120 ml · Mẹ ghi" Medium 12/16 +0.2 `ink-muted`, flex spacer, full-width pill h 36 `care-bottle-accent` "+ 120 ml" SemiBold 14 white.
- **Widget/Small logged** (bg `care-bottle-soft`): top row adds a Done badge 20 × 20 radius 10 `care-bottle-accent` with white check 12; "Vừa xong" SemiBold 19/26; "Đã ghi 120 ml · Bạn"; two pills (gap 6) h 36 `surface` bg, SemiBold 14 `care-bottle-ink`: "Hoàn tác", "Sửa".
- **Tap indicator** (over default widget's button): ring 44 — fill white 35 %, 3 px white stroke; dot 16 — #141417 @35 %.
- **Arrow chip**: `surface`, `padding: 6px 10px`, radius 999, `shadow-card`; Bold 14 `mint-text` "→". Sits between the two small widgets (from default to logged).
- **Note chip**: `surface`, radius 14, `padding: 10px 14px`, gap 8, shadow `0 18px 20px rgba(13,38,33,.14)`; `icons/check.svg` 16 stroked `mint-text`; SemiBold 13 `ink` "Một chạm là đã ghi xong".
- **Lock screen** 316 × 440: radius 36, `background: linear-gradient(180deg, #33455C, #6B5C85)` **(raw)**, widget shadow, overflow hidden. Inside:
  - Dynamic Island (compact sleep) at (33, 14) 250 × 37: black, radius 19, `padding: 0 8px`, space-between: `mini-moon.svg` 24 + "1:27" SemiBold 14/20 `care-sleep-accent`.
  - Date, centred, top 70: Medium 14 `rgba(255,255,255,.8)` "Thứ Năm, 8 tháng 10".
  - Clock, centred, top 88: SemiBold 64 white "9:41".
  - Two **Lock/Circular** 76 × 76 at (64, 184) and (176, 184): bg `rgba(255,255,255,.12)`, radius 38 (circle); ring 72 inset 2, stroke width 4.32: track white 25 %, progress white — **sleep ≈ 62 %** clockwise from 12 o'clock, **feed ≈ 38 %**; centred col gap 1: icon 18 white (`icons/sleep.svg` / `icons/feed.svg`) + SemiBold 14/20 white "1:27" / "45p". Build ring with an SVG `<circle>` + `stroke-dasharray`.
  - **LiveActivity/Lock screen** at (12.4, 286) 291.2 × 126.4 (the 364-wide component at 0.8): `surface`, radius 24, `padding: 11.2px 12.8px`, col gap 9.6:
    - Top row gap 4.8: app icon 14.4 (`logo-app-icon.svg`, radius ≈ 3.3) + "Child Life" SemiBold 9.6/12.8 +0.2 `ink-muted` + spacer + "Cả nhà đang thấy" Medium 9.6/12.8 `ink-muted`.
    - Main row gap 9.6: `mini-moon.svg` 32 + col("Teddy đang ngủ" Medium 13.6/19.2 `ink`; "Từ 21:42 · Ba bắt đầu" Medium 9.6/12.8 `ink-muted`) + "1:27:06" Medium 22.4/27.2 `care-sleep-ink` (tabular).
    - Actions gap 6.4: two pills h 32 flex 1: `care-sleep-accent` "Thức dậy" SemiBold 11.2 white; `surface-2` "Sửa giờ bắt đầu" SemiBold 11.2 `ink`.

**Steps** row 1248 × 82, gap 24, 3 equal cards: `background: surface; radius 24; padding: 20px 24px; display:flex; align-items:center; gap:16px;` (no shadow). Number pill `mint-deep`, `padding: 8px 14px`, Bold 16 `on-mint-deep`. Text col gap 2: SemiBold 17 `ink` + Medium 14 `ink-muted`:
1. "Chạm một lần" — "Ngay khi vừa cho bé bú xong"
2. "Tự lưu lại cho bạn" — "Lỡ chạm nhầm cũng sửa được ngay"
3. "Cả nhà thấy ngay" — "Không ai phải hỏi lại "con ăn chưa?"" (straight double quotes in Figma)

### Mobile 233:860 (375 × 1199)
- `gap: 20px; padding: 48px 20px;` left-aligned head: H2 30 (2 lines "Tay bế con, vẫn ghi lại / được trong một chạm."), lead 16/1.55.
- Stage 335 × 697.7, radius 28, same 3-stop gradient at **109.8deg**. Removed on mobile: both label pills, Widget/Large, arrow chip, note chip, tap dot.
  - Widget/Medium (16, 20) 303 × 141.5 (component at 0.833: padding 11.65, face 18.3, "Teddy" 11.65, meta 9.99, art 28.3, tile text 9.99, plus badge 18.3; shadow `0 12 28 rgba(13,38,33,.14)`).
  - Widget/Small default (16, 175.5) and logged (175, 175.5), 144 × 144 (0.847: padding 11.86, art 25.4, "45 phút trước" 16.09/22, meta 10.16, buttons h 30.5 text 11.86, Done badge 16.9).
  - Tap ring only, 36 × 36 at (114, 273.5) (white 35 % + 3 px white stroke, no inner dot).
  - Lock screen (47.5, 339.5) 240 × 334.2 = desktop lock screen × 0.76 (radius 27.3; DI 189.9 × 28.1 at (25.1, 10.6); date 10.6 at top 53.2; clock 48.6 at top 66.8; circulars 57.7 at (48.6, 139.7) & (133.7, 139.7) text 10.6; LA 221.2 × 96 at (9.4, 217.2), texts 7.3 / 10.3 / 17.0 timer / 8.5 buttons, buttons h 24.3).
- Steps: 3 stacked full-width cards (`padding: 16px 18px`, radius 24, gap 16), title SemiBold **16**, sub Medium **13**. Figma fixes each card at height 40 (content overflows — design bug); implement auto height (~72) and a 12 px gap.

---

## 4. Chăm sóc ("Chăm sóc mỗi ngày")

### Desktop 220:1801 (1440 × 760)
`padding: 96px 96px 64px;` Row `display:flex; align-items:center; gap:96px;` → **Panel 640 × 600 (left)** + Copy `flex:1` (512, right).

**Panel**: `background: mint-soft; radius 40; overflow:hidden; position:relative`. Children:
- **CareTile Bú bình** at (80, 72), 199.2 wide (hug ≈ 166.6) — app CareTile at ×1.2: `background: care-bottle-soft; border: 1.2px solid card-edge (rgba(255,255,255,.85)); radius 24; padding: 14.4px 14.4px 16.8px; gap 9.6; shadow-tile ×1.2; overflow:hidden`.
  - Art `mini-bottle.svg` 100.8 at bottom −15.6 / right −18 (bleeds, clipped by tile).
  - "Bú bình" Medium 19.2/28.8 `care-bottle-ink`; "120 ml" SemiBold 24/31.2 `ink`; meta col gap 4.8: "45 phút trước", "Mẹ ghi" Medium 16.8/24 `ink-muted`.
- **CareTile Giấc ngủ** at (295.2, 72), same geometry, `care-sleep-soft`, art `mini-moon.svg`: "Giấc ngủ" (`care-sleep-ink`) / "Đang ngủ" / "01:27:06 · từ 21:42" / "Ba bắt đầu".
- **Chip** at (335.2, 44), 266 × 36, above the sleep tile's top-right: `surface; radius 999; padding: 10px 14px; gap 8; shadow 0 18px 20px rgba(13,38,33,.14)`; `icons/clock.svg` 16 stroked `care-sleep-ink`; SemiBold 13 `ink` "Vẫn đếm giờ khi bạn tắt màn hình".
- **DayRhythm** at (83.33, 262.6), 473.34 wide (≈ 317.7 tall) — app component ×1.38: `surface; radius 24; padding: 19.32px 22.08px 16.56px; gap 11.04; shadow-card`.
  - "Đã ghi hôm nay" Medium 19.32/27.6 `ink-muted`.
  - Totals: 2 rows (gap 11.04), each row 2 items (flex 1, gap 16.56); item row gap 11.04: key bar 5.52 × 44.16 radius 2 in care accent + col(label Medium 16.56/22.08 +0.2 in care ink; value Medium 23.46/33.12 `ink`):
    - Bú bình — "2 cữ · 240 ml" | Bú mẹ — "1 cữ · 15 phút"
    - Ngủ (đã xong) — "7 giờ 50" | Thay tã — "2 lần"
  - 24 h track, height 38.64, `position:relative; overflow:hidden`: base `surface-2` radius 8 full; bars vertically centred, positions as `left%` / `right%`:
    | Bar | colour | h | radius | left | right |
    |---|---|---|---|---|---|
    | Sleep 00:00–06:30 | sleep accent | 27.6 | 6 | 0 | 72.92 % |
    | Sleep 11:45–13:05 | sleep accent | 27.6 | 6 | 48.96 % | 45.5 % |
    | Feed 08:00 | bottle accent | 22.08 | 2 | 32.85 % | 66.18 % |
    | Diaper 09:10 | diaper accent | 22.08 | 2 | 37.73 % | 61.31 % |
    | Breastfeed 11:30–11:45 | breast accent | 22.08 | 2 | 47.43 % | 51.28 % |
    | Diaper 13:40 | diaper accent | 22.08 | 2 | 56.48 % | 42.56 % |
    | Feed 14:20 | bottle accent | 22.08 | 2 | 59.23 % | 39.81 % |
    | Now 15:05 | `ink` | full height | 0 | 62.83 % | 36.52 % |
  - Axis `justify-content: space-between`, Medium 16.56/22.08 +0.2 `ink-muted`: "0h" "6h" "12h" "18h" "24h".
  - Legend row gap 16.56; item gap 5.52: square 13.8 radius 3 + Medium 16.56 `ink-muted`: "Ngủ" (sleep), "Bú bình" (bottle), "Bú mẹ" (breast), "Tã" (diaper).

**Copy** (col gap 36): Head col gap 16:
- Eyebrow `mint-soft`/`mint-text` "Chăm sóc mỗi ngày"
- H2 44, width 560 (2 lines): "Nhìn là hiểu một ngày của con."
- Lead width 460: "Con đã bú bao nhiêu, ngủ được bao lâu, thay tã lúc nào — tất cả hiện rõ trong một màn hình. Không cần nhớ, không phải đoán, kể cả lúc 3 giờ sáng."

Bullets (col gap 18). Bullet row gap 16, items start: icon box 40 × 40 (`padding:10px; radius:14px`, tinted bg) with 20 px line icon (stroke 1.5, care ink) + text col gap 2 (SemiBold 17 `ink`; Medium 15 `ink-muted`):
| Icon box | Icon | Title | Sub |
|---|---|---|---|
| `care-bottle-soft` | plus, `care-bottle-ink` | "Cả ngày của con trong một cái nhìn" | "Dễ nhận ra nhịp ăn ngủ của bé" |
| `care-sleep-soft` | clock, `care-sleep-ink` | "Đếm giờ giúp bạn khi bé ngủ, khi bú mẹ" | "Liếc điện thoại là biết" |
| `care-diaper-soft` | journal, `care-diaper-ink` | "Có sẵn số liệu khi đưa con đi khám" | — |

### Mobile 233:995 (375 × 898)
- Col `gap: 24px; padding: 48px 20px;` order **Head → Bullets → Visual** (visual moves below copy).
- H2 30 (1 line wraps to 2), lead 16/1.55; bullets unchanged (titles wrap at 279).
- Visual 335 × 314.06: the desktop Panel × **0.5234** (radius 20.94; CareTiles 104.3 wide at (41.9, 37.7) & (154.5, 37.7); DayRhythm 247.8 wide at (43.6, 137.5); chip at (175.5, 23.0), text 6.8). Implement by rendering the 640 × 600 panel inside a 335 × 314 box with `transform: scale(0.5234); transform-origin: 0 0` (texts become 8.7–12.6 px — decorative).

---

## 5. Cùng chăm

### Desktop 220:1918 (1440 × 728)
`padding: 64px 96px;` Row gap 96, items centre → **Copy flex 1 (512, left)** + **Panel 640 × 600 (right)** (mirrors Chăm sóc).

Copy (col gap 36): Head gap 16:
- Eyebrow `peach-soft` / `care-bottle-ink`: "Cùng chăm"
- H2 44, width 480 (2 lines "Cả nhà cùng chăm, / không ai phải hỏi lại."): "Cả nhà cùng chăm, không ai phải hỏi lại."
- Lead width 460: "Ai cho bé bú, ai thay tã, ai ru ngủ — cả nhà đều thấy. Đổi ca cho nhau nhẹ nhàng, không cần nhắn tin hỏi "con ăn lúc mấy giờ?"."
- Bullets gap 18, single-line titles (SemiBold 17 `ink`), same icon-box style:
  | Icon box | Icon (stroke 1.5) | Text |
  |---|---|---|
  | `mint-soft` | check, `mint-text` | "Biết con đã được chăm đến đâu" |
  | `care-sleep-soft` | family, `care-sleep-ink` | "Đi làm vẫn yên tâm khi bé ở nhà với bà, với cô" |
  | `sunshine-soft` | cloud-off, `care-growth-ink` #9A4A14 | "Không có mạng vẫn ghi được, không mất gì" |

Panel: `background: sunshine; radius 40; overflow:hidden; position:relative`.
- **Illustration/Family** at (67.79, 0), 504.41 × 600, bg `card-sun` (= sunshine), radius 52.94 (radius-hero scaled), art `cungcham-family.svg` (same art as `apps/mobile/assets/illustrations/family.svg` at 343 × 408, scale 1.4706): sleeping baby in cream circle, dashed orbit, four coloured avatar discs with white rings, star badge on M, heart badge on Bà. Initials are live text overlays (SemiBold, centred on x, `top` = y):
  | Letter | size | colour | centre-x | top |
  |---|---|---|---|---|
  | M | 35.29 | white | 94.12 | 116.18 |
  | B | 29.41 | white | 429.41 | 146.32 |
  | Bà | 26.47 | `ink` | 420.59 | 397.79 |
  | L | 26.47 | `ink` | 97.06 | 409.56 (hidden behind the Feed card) |
  - Star icon (`icons/star.svg`) 17.6 at (120.59, 94.12), stroke `ink` 2.65 — badge on the M disc.
  - **FloatChip** at (236.76, 23.53): `chip` (white), radius pill, `padding: 8.8px 20.6px 8.8px 8.8px`, gap 11.8, `shadow-chip`; lead circle 41.2 `mint-soft` with `icons/lock.svg` 23.5 stroked `mint-text`; Medium 20.59/29.4 `ink` "Bạn chọn quyền".
- **Feed card** at (32, 362), ≈ 197 × 206, above the illustration: `surface; radius 24; padding 20; gap 14; shadow-card`.
  - "Vừa ghi" SemiBold 13 `ink-muted`.
  - 3 rows gap 12, items centre: disc 32 (`padding:8; radius 999`, tinted) with 16 px icon stroke 1.2 + col gap 2 (SemiBold 15 `ink`; Medium 12 `ink-muted`):
    - `care-bottle-soft` + plus (`care-bottle-ink`): "Bú bình 120 ml" / "Ba · 13:05"
    - `care-diaper-soft` + check (`care-diaper-ink`): "Thay tã" / "Người chăm · 14:20"
    - `care-sleep-soft` + clock (`care-sleep-ink`): "Ngủ 1 giờ 20" / "Mẹ · 15:40"

### Mobile 233:1027 (375 × 852)
- `gap: 24px; padding: 48px 20px;` order Head → Bullets → Visual. H2 30, lead 16. Bullets 2 and 3 wrap to 2 lines.
- Visual 335 × 314.06 = desktop Panel × 0.5234 (radius 20.94; illustration 264 × 314 at x 35.5, radius 27.7; FloatChip text 10.8; Feed card (16.75, 189.5) text 7.85 / 6.28). Use the scale-transform approach.

---

## 6. Tuổi thơ ("Kỷ niệm")

### Desktop 232:627 (1440 × 1499) — background `surface` (white)
`display:flex; flex-direction:column; align-items:center; gap:56px; padding: 112px 96px;`

**Head** (900 wide, centred, gap 16):
- Eyebrow `sunshine-soft` / `care-growth-ink`: "Kỷ niệm"
- H2 44 centred, 900 wide: "Nơi lưu giữ trọn tuổi thơ của con."
- Lead 700 wide centred (3 lines): "Ảnh, video và những câu chuyện nhỏ được xếp theo từng tháng tuổi của con. Không lạc giữa hàng nghìn ảnh trong điện thoại, không sợ mất — mở ra là thấy con lớn lên."

**Timeline** 1248 × 580, `position:relative` (horizontal, polaroids alternate above/below):
- Rail at (24, 288), 1180 × 4, radius 2: `linear-gradient(90deg, #2EA899 0%, #FAB88C 85%, rgba(250,184,140,0) 100%)` **(raw)**.
- Nodes, 18 × 18 at top 281, left = 51 + 180·k (k = 0…6): white centre 10 px + 4 px ring (`box-sizing:border-box; border: 4px solid …; background: white`). Ring `mint-deep` for k = 0–4, `peach` #FFA58D for k = 5–6.
- Stems 2 × 40 `separator`, centred on node (left = 59 + 180·k): k even → top 242 (up), k odd → top 300 (down).
- **Polaroid card**: `background: surface; radius 18; padding: 10px 10px 14px; display:flex; flex-direction:column; gap:10px; shadow 0 16px 18px rgba(13,38,33,.14)`.
  - Photo window 150 × 120, radius 12, overflow hidden, bg `surface-2`; Illustration/Photo 150 × 150 positioned at top −15 (crop centre).
  - Caption `padding: 0 4px`, col gap 2: age Bold 13 (`mint-text`, or `care-bottle-ink` for k = 5–6); title SemiBold 15 `ink`.
  - Card ≈ 170 × 188 unrotated. Positions are the rotated bounding boxes (centre the card in them):

| k | Age | Title | Rotation | Bounding box (x, y, w × h) | Photo tone / file |
|---|---|---|---|---|---|
| 0 | Ngày đầu | Về nhà | +2° | (−31.7, 51, 176.6 × 196.8) | Sand · `baby-5d2ff.jpg` |
| 1 | 5 tuần | Lần đầu cười | −2° | (155, 334.1, 176.6 × 196.8) | Sun · `baby-22456.jpg` |
| 2 | 4 tháng | Lần đầu lẫy | +1.5° | (330, 51, 174.9 × 195.4) | Mint · `baby-61240.jpg` |
| 3 | 9 tháng | Chiếc răng đầu tiên | −2° | (515, 333.9, 180.6 × 197.0) | Peach · `baby-0d3f8.jpg` |
| 4 | 1 tuổi | Sinh nhật đầu tiên | +2° | (688.3, 51, 176.6 × 196.8) | Lilac · `baby-1025f.jpg` |
| 5 | 2 tuổi | Những bước chạy | −1.5° | (875, 335.6, 174.9 × 195.4) | Leaf · `baby-ae95e.jpg` |
| 6 | 3 tuổi | Ngày đầu đi học | +1° | (1051.7, 51, 173.3 × 193.9) | Sky · `baby-4222e.jpg` |

- End label at (1090, 304): SemiBold 15 `ink-muted` "…và mọi năm sau nữa" (Unicode ellipsis).
- Note: card k = 0 starts at x −31.7 (overhangs the 1248 container by ~32 px on the left).

**Tiles** row 1248, gap 24, 3 × `flex:1` (400 wide), `align-items: flex-start` (tile 3 is shorter: 364 vs 387 — recommend `stretch` for equal heights). Tile: `background: cloud; radius 28; overflow:hidden; display:flex; flex-direction:column`. Art area height 240 (tinted, `position:relative; overflow:hidden`). Text block `padding: 22px 24px 26px; gap 6`: `tile-title` Bold 19 `ink`, `tile-body` Medium 15/1.5 `ink-muted`.

1. **"Ảnh của con, gọn gàng một chỗ"** — "Không còn lẫn với ảnh chụp màn hình hay hoá đơn. Đánh dấu những tấm bạn thương nhất để tìm lại trong vài giây."
   - Art bg `mint-soft`. 3 × 2 photo grid, each 96 × 96 radius 14 (bg `surface-2`) at x 40 / 144 / 248, y 22 / 126. Tones row 1: Mint (61240), Peach (0d3f8), Sun (22456); row 2: Lilac (1025f), Sky (4222e), Leaf (ae95e).
   - Chip at (220, 184), 125 × 31: `surface; radius 999; padding: 8px 12px; gap 6; shadow 0 16 18 rgba(13,38,33,.14)`; `icons/bookmark.svg` 14 stroked `mint-text`; SemiBold 12 `ink` "Yêu thích · 48".
2. **"Câu chuyện của con"** — "Từ những gì bạn đã ghi, app gợi ý thành một câu chuyện nhỏ. Bạn sửa vài chữ cho đúng giọng mình, rồi gửi tặng người thân."
   - Art bg `sunshine-soft`. Two **StoryCard**s 160 × 200, `background: #FAF5EC` **(raw)**, radius 6, `box-shadow: 0 16px 36px rgba(13,38,33,.14)`, overflow hidden:
   - **Card A "Lá thư"** — bbox (49.1, 40, 180 × 215.6), rotate **+6°**, behind:
     - 7 ruled lines 134 × 0.5 `rgba(232,196,184,.6)` at x 13, y 76, 88, 100, 112, 124, 136, 148.
     - Mini photo 37 × 46, radius 2, `border: 2.5px solid white`, bg #E6E6E6, rotate −6°, bbox (108, 8.1, 41.6 × 49.6); Lilac photo 46 × 46 at (−7, −2.5).
     - "Gửi Teddy," Dancing Script 15 #3E342C at (13, 22).
     - Body Lora Regular 7 / 12 #3E342C, width 134, at (13, 67): "Sáng thứ Hai, mẹ vừa hát xong câu ru quen thuộc thì con bỗng nhoẻn miệng cười. Cả nhà đứng yên mấy giây, sợ chỉ cần thở mạnh là nụ cười sẽ biến mất."
     - Signature Dancing Script 9.5 #8C7C6C at (69, 166): "— Mẹ, mùa thu 2026"
     - "Child Life" Be Vietnam Pro Medium 4.5, +0.54, #8C7C6C at (125, 188).
   - **Card B "Một khoảnh khắc"** — bbox (190, 16.1, 176.8 × 213.2), rotate **−5°**, on top:
     - Polaroid 118 × 131 white, `box-shadow: 0 3px 8px rgba(77,51,26,.18)`, rotate +3°, bbox (13.1, 15, 124.7 × 137): photo 106 × 103 at (6, 6), bg #E6E6E6, Mint photo 106 × 106 at top −1.5; caption Dancing Script 9 #8C7C6C at (8, 113): "Lần đầu cười · 5.10".
     - Quote Lora Italic 8 / 12 #3E342C, centred, width 130, top 150: "“Như thể con cũng thuộc lời ru ấy.”" (curly quotes).
     - "TEDDY · 3 TUẦN TUỔI" Medium 4.5, +0.81, #8C7C6C, centred, top 166.
     - "Child Life" Medium 4.5 at (125, 188).
3. **"Ông bà ở xa vẫn thấy cháu lớn"** — "Có ảnh mới là ông bà được báo và thả tim ngay. Không cần gửi lẻ từng tấm qua tin nhắn."
   - Art bg `peach-soft`. 3 notification cards staggered at (30, 28), (44, 94), (58, 160) (≈ 286 / 279 / 263 × 52): `surface; radius 16; padding: 10px 14px 10px 10px; gap 10; items centre; shadow 0 16 18 rgba(13,38,33,.14)`.
     - Avatar pill `padding: 8px 10px; radius 999`, Bold 13 `ink`; text col gap 1: SemiBold 13 `ink` + Medium 11 `ink-muted`; `icons/heart.svg` 16 stroked `care-bottle-ink` (1.2).
     - (`card-peach`, "Bà") "Bà nội thương ảnh của Teddy" / "vừa xong"
     - (`care-sleep-soft`, "Ô") "Ông ngoại đã xem 12 ảnh mới" / "5 phút trước"
     - (`mint-soft`, "C") "Cô Lan thương câu chuyện" / "hôm qua"

### Mobile 233:1072 (375 × 2136) — background `surface`
- Col `gap: 24px; padding: 56px 20px;` head left-aligned: H2 30 ("Nơi lưu giữ trọn tuổi / thơ của con."), lead 16.
- **Vertical timeline** (col gap 14, `position:relative`):
  - Rail line at (6.5, 30), 3 × 556, `mint-soft` (solid, no gradient).
  - Row: gap 14, items centre: node 16 × 16 (white centre 8 + 4 px ring; `mint-deep` first five, `peach` last two) + card `flex:1`: `surface; radius 18; padding: 8px 14px 8px 8px; gap 12; items centre; shadow 0 12px 14px rgba(13,38,33,.14)`; photo window 72 × 60 radius 12 (photo 72 × 72 at top −15) + caption (Bold 13 age / SemiBold 15 title). **No rotation.** Same 7 items, colours and photos as desktop.
  - End label SemiBold **14** `ink-muted` "…và mọi năm sau nữa".
- Tiles stacked full width (335), gap 24: art height **210**; title Bold **18**; body Medium **14**/1.5.
  - Tile 1 grid at x 10 / 114 / 218, y 12 / 116; chip at (190, 174).
  - Tile 2 cards at bbox (19.1, 30) and (160, 6.1) — card B is clipped at the right edge.
  - Tile 3 notifications at (0, 18), (14, 84), (28, 150).

---

## 7. Night care ("Cho những đêm thức giấc")

### Desktop 221:2845 (1440 × 688)
Outer `padding: 64px 96px;` (on page `cloud`). Inner card "Night" 1248 × 560: `background: #0C1719` (= `cloud` in Night care mode), `border-radius: 40px; overflow:hidden; display:flex; align-items:center; gap:64px; padding-left:80px;` → Copy `flex:1` (504) + Visual 600 × 560.

Copy (col gap 28): Head gap 16:
- Eyebrow `mint-deep` / `on-mint-deep`: "Cho những đêm thức giấc"
- H2 44, #F2F5F2 **(raw)**, width 460 (2 lines "Dịu mắt cho những / cữ bú lúc nửa đêm."): "Dịu mắt cho những cữ bú lúc nửa đêm."
- Lead 18/1.55, #BFCCCC **(raw)**, width 440: "Buổi tối, màn hình tự dịu lại: nền tối ấm, chữ to, không chói mắt. Bé ngủ tiếp, bạn cũng dễ ngủ lại."
- Check list (col gap 14), row gap 12 items centre: `icons/check.svg` 18 stroked #99D9C7 **(raw)** (1.35) + Medium 16 #E5EBE5 **(raw)**:
  - "Tự bật vào giờ bạn chọn, không cần nhớ"
  - "Nút to, một tay vẫn bấm được khi đang bế con"

Visual 600 × 560 (`position:relative; overflow:hidden`). All mockup colours are the **Night care** token values:
- z0 `nightcare-starfield.svg` (600 × 560 layer): radial glow circle 520 at (50, 20), `#6673CC` 40 % → 0 %, plus 14 white stars 2–4 px at 50–80 % opacity.
- z1 Moon `nightcare-moon.svg` (Illustration/Mini/Moon, #FFD166 crescent + 2 dots) 123.2 × 123.2 at (420, 40).
- z2 **LiveActivity** at (40, 170), 418.6 × 181.7 (component ×1.15): bg #15242A (`surface` night), radius 24, `padding: 16.1px 18.4px`, col gap 13.8, shadow `0 16px 36px rgba(13,38,33,.14)`.
  - Top row gap 6.9: `logo-app-icon.svg` 20.7 + "Child Life" SemiBold 13.8/18.4 +0.2 #9DB3B4 + spacer + "Cả nhà đang thấy" Medium 13.8 #9DB3B4.
  - Main row gap 13.8: mini moon 46 + col("Teddy đang ngủ" Medium 19.55/27.6 #E6F2F1; "Từ 21:42 · Ba bắt đầu" Medium 13.8/18.4 #9DB3B4) + "1:27:06" Medium 32.2/39.1 #BDBFF7 (night `care-sleep-ink`).
  - Actions gap 9.2: pills h 46 flex 1: #8A8DEB (night sleep accent) "Thức dậy" SemiBold 16.1/23 #15242A; #1C2E33 (night `surface-2`) "Sửa giờ bắt đầu" SemiBold 16.1 #E6F2F1.
- z3 **Widget/Small sleep** at (40, 380) 170 × 170: bg #23244A (night `care-sleep-soft`), radius 22, padding 14, same shadow: top row gap 8 (mini moon 30 + "Đang ngủ" SemiBold 14/20 #BDBFF7); gap 10; "1:27:06" Medium 28/34 (Numbers/numeral, tabular) #E6F2F1; "Từ 21:42 · Ba" Medium 12/16 +0.2 #9DB3B4; spacer; pill h 36 #8A8DEB "Thức dậy" SemiBold 14 #15242A.
- z4 **Widget/Small bottle** at (226, 380): bg #15242A: mini bottle 30 + "Bú bình" #9CCBF5; "45 phút trước" SemiBold 19/26 #E6F2F1; "120 ml · Mẹ ghi" #9DB3B4; pill #5AA6E8 "+ 120 ml" SemiBold 14 #15242A.
- z5/z6 **Lock/Circular** ×1.3 (98.8 × 98.8) at (410, 290) = sleep and (410, 400) = feed: bg `rgba(255,255,255,.12)`, radius 38 (rounded square, not a full circle at this size), ring 93.6 inset 2.6, stroke 5.6 (track white 25 %, progress white: sleep ≈ 62 %, feed ≈ 38 %), centre col gap 1.3: icon 23.4 white + SemiBold 18.2/26 white "1:27" / "45p". They overlap the Live Activity's right edge (LA ends at x 458.6) and are drawn **above** it.

### Mobile 233:1296 (375 × 656)
- Outer `padding: 16px 20px;` card radius **28**, `padding: 32px 20px 24px;` col gap 20 (copy then visual).
- H2 **28**/1.18, −0.42 (3 lines); lead Medium **15**/1.55; list items Medium **14** (2nd item is `nowrap` 318 wide and overflows the 295 column in Figma — allow wrapping).
- Visual 295 × 275.3 = desktop visual × **0.4917** (moon 60.6; LA 205.8 wide; widgets 83.6; circulars 48.6; texts 5.9–15.8 px). Scale-transform the desktop visual.

---

## 8. Quyền xem ("Riêng tư")

### Desktop 221:3347 (1440 × 831)
`display:flex; flex-direction:column; align-items:center; gap:48px; padding: 112px 96px 96px;`

Head (1000 wide, centred, gap 16):
- Eyebrow `card-peach` / `care-bottle-ink`: "Riêng tư"
- H2 44 centred: "Ảnh của con, chỉ người nhà mới thấy."
- Lead 600 wide centred (2 lines): "Mỗi người trong nhà thấy đúng phần cần thấy. Bạn luôn là người quyết định."

Role cards row 1248, gap 24, 3 × `flex:1` (400 × 277): `background: surface; radius 28; padding 28; col gap 20; shadow-card`.
- Top row gap 14 items centre: avatar pill `padding: 10px 15px; radius 999`, Bold 16 + col gap 2 (Bold 19 `ink` role; Medium 14 `ink-muted` description).
- 3 permission rows, gap 12 items start: icon 18 + col gap 2 (SemiBold 15 title; Medium 14 sub).
  - **Allowed**: `icons/check.svg` stroked `mint-text` (1.35); title `ink`, sub `ink-muted`.
  - **Not allowed**: `icons/lock.svg` stroked `ink-muted`; title **and** sub `ink-muted`.

| Card | Avatar | Role / description | Chăm con | Kỷ niệm | Mời người thân |
|---|---|---|---|---|---|
| 1 | `mint-soft`, "M" `mint-text` | "Ba mẹ" / "Người quyết định mọi thứ" | ✓ "Thấy và ghi mọi việc chăm con" | ✓ "Giữ mọi ảnh, video, câu chuyện" | ✓ "Mời ai, cho xem gì — do bạn chọn" |
| 2 | `care-sleep-soft`, "C" `care-sleep-ink` | "Người chăm" / "Bảo mẫu, cô giúp việc" | ✓ "Ghi lại việc chăm bé trong ngày" | ✓ "Gửi ảnh bé cho ba mẹ, không xem album riêng" | 🔒 "Không" |
| 3 | `card-peach`, "B" `care-bottle-ink` | "Người thân" / "Ông bà, cô chú" | 🔒 "Không thấy chuyện ăn ngủ hằng ngày" | ✓ "Xem ảnh và câu chuyện ba mẹ chia sẻ" | 🔒 "Không" |

(Row titles are literally "Chăm con", "Kỷ niệm", "Mời người thân".)

Notes row 1248, gap 24, 2 × `flex:1` (612 × 82): `background: mint-soft; radius 20; padding: 18px 20px; gap 14; items centre`; icon 20 stroked `mint-text` (1.5); Medium 15/1.5 `ink`:
- (lock) "Ảnh mới mặc định chỉ ba mẹ thấy. Muốn khoe cả nhà, bạn chỉ cần chọn "Gia đình"."
- (eye) "Ảnh của con không hiện trên màn hình khoá, và đường link gửi đi sẽ tự hết hạn."

### Mobile 233:1336 (375 × 1375)
- Col `gap: 16px; padding: 56px 20px 48px;` left-aligned; H2 30 (2 lines), lead 16.
- Role cards stacked full width (335), **padding 22** (desktop 28), same content; card 2's Kỷ niệm sub wraps to 2 lines.
- Notes stacked, text Medium **14**/1.5.

---

## 9. CTA

### Desktop 221:3443 (1440 × 415)
Outer `padding: 32px 96px 96px;`. Card 1248 × 287: `background: mint-deep; radius 40; overflow:hidden; padding 72; display:flex; align-items:center; gap 48; position:relative`.
- Decorative circle 420 × 420 at (−140, −220), white 6 % (CSS).
- Left col `flex:1`, gap 16:
  - H2 Bold 44/1.18, −0.66, white, 2 lines: "Bớt phải nhớ." / "Thêm thời gian bên con."
  - Medium 18 `rgba(255,255,255,.8)`: "Miễn phí trên iPhone và Android. Mời cả nhà chỉ trong một phút."
- Right col `align-items: flex-end`, gap 12: badges row (gap 12) in the **light** variant (white bg, #141417 text/icons, §12); caption Medium 13 `rgba(255,255,255,.75)` right-aligned: "Miễn phí cho cả gia đình".
- No email/waitlist form.

### Mobile 233:1430 (375 × 361)
- Outer `padding: 24px 20px 32px;` card radius **28**, `padding: 36px 24px;` col gap 16, **no decorative circle**.
- H2 Bold **28**/1.2, −0.28 (2 lines); sub Medium **15**/1.5.
- Badges row gap 10, two light badges `flex:1` (138.5 × 53.4). **No caption.**

---

## 10. Hỏi đáp

### Desktop 221:3455 (1440 × 644)
`padding: 32px 96px 112px;` Row gap 80, items start → left column 360 + list `flex:1` (808).
- Left (gap 12): Bold 36/1.2, −0.36 `ink` "Câu hỏi thường gặp"; Medium 16/1.5 `ink-muted` (2 lines): "Còn điều gì băn khoăn? Cứ nhắn cho chúng tôi nhé."
- List col gap 12. Item: `background: surface; border: 1px solid separator; radius 20; padding: 22px 24px; col gap 10`.
  - Question row gap 16 items centre: SemiBold 17 `ink` flex 1 + icon 20 stroked `ink-muted` (1.5): `chevron-down` when expanded, `plus` when collapsed.
  - Answer Medium 15/1.55 `ink-muted`.

| # | State | Question | Answer |
|---|---|---|---|
| 1 | open | "Child Life dành cho bé từ mấy tuổi?" | "Từ ngày con chào đời. Những năm đầu, app giúp bạn chăm con mỗi ngày; khi con lớn hơn, đây là nơi giữ lại ảnh và câu chuyện của con." |
| 2 | open | "Có mất phí không?" | "Không. Cả gia đình dùng miễn phí, đủ chỗ cho hàng nghìn ảnh của con. Cần thêm chỗ, bạn chỉ cần nhắn cho chúng tôi." |
| 3 | closed | "Ông bà không rành điện thoại có dùng được không?" | **not in design** |
| 4 | closed | "Ai được xem ảnh và thông tin của con?" | **not in design** |
| 5 | closed | "Có dùng được trên Android không?" | **not in design** |

Implement as `<details>`/accordion (multiple open allowed — design shows two open). Icon swap chevron-down ⇄ plus is the only state cue. "Cứ nhắn cho chúng tôi" has no link target.

### Mobile 233:1448 (375 × 749)
- Col gap 12, `padding: 24px 20px 48px;` title Bold **26**/normal −0.26; **no subtitle**.
- Items `padding: 22px 18px`; question SemiBold **16** (wraps to 2 lines for Q1, Q3–Q5); answer Medium **14**/1.55.

---

## 11. Footer

### Desktop 221:3488 (1440 × 184)
- Col gap 56, `padding: 32px 96px 40px;` divider 1 px `separator` full width (1248).
- Bottom row `justify-content: space-between; align-items:center; padding-top: 28px`:
  - Left gap 16: lockup at 0.8 (mark 27.2 + gap 7.6 + wordmark 105.9 × 21.2) + Medium 14 `ink-muted` "© 2026 Child Life".
  - Right links gap 28, Medium 14 `ink-muted`: "Quyền riêng tư" · "Điều khoản" · "Liên hệ" (no targets in design; no social links, no language switch).

### Mobile 233:1477 (375 × 153)
- Col gap 12, `padding: 24px 20px 36px;` divider; lockup (mark 23.8 + gap 6.66 + wordmark 92.7 × 18.6); links row gap 20 Medium **13** `ink-muted`; "© 2026 Child Life" Medium 13 on its own line.

---

## 12. Store badges

**Custom, not the official Apple/Google badge artwork.** The design uses a self-drawn pill with placeholder glyphs: the "apple" is a filled circle + a rotated leaf ellipse (not the Apple logo), the "play" is a plain right-pointing triangle (not the Google Play logo), and the labels are Be Vietnam Pro "Tải trên / App Store" and "Tải trên / Google Play". Before launch these must be replaced by the official localized badges (Apple "Download on the App Store" VN badge, Google Play badge) per their brand guidelines — the Figma geometry is only a size/placement guide.

| Variant | Where | bg | text / icon | Size | Radius | Padding | Icon | "Tải trên" | Store name |
|---|---|---|---|---|---|---|---|---|---|
| Dark desktop | Hero | #141417 | white | App Store 189.2 × 67, Google Play 210.2 × 67 | 16.1 | 11.5 / 23 / 11.5 / 18.4 (T R B L), gap 11.5 | 25.3 (`store-apple.svg`, `store-play.svg`) | Medium 12.65 | SemiBold 21.85 |
| Dark mobile | Hero | #141417 | white | 162.5 × 54.9 each (`flex:1`), centred | 13.2 | 9.43 / 18.86 / 9.43 / 15.09, gap 9.43 | 20.75 | Medium 10.37 | SemiBold 17.92 |
| Light desktop | CTA | white | #141417 | same as dark desktop | 16.1 | same | 25.3 (`store-apple-dark.svg`, `store-play-dark.svg`) | 12.65 | 21.85 |
| Light mobile | CTA | white | #141417 | 138.5 × 53.4 each (`flex:1`) | 12.88 | 9.2 / 18.4 / 9.2 / 14.72, gap 9.2 | 20.24 | 10.12 | 17.48 |

Text column has no gap ("Tải trên" sits directly above the store name, `line-height: normal`).

---

## 13. Mobile behaviour summary
- Breakpoint: only 1440 and 375 exist. Suggested: ≥ 1024 desktop layout; < 768 mobile layout; in between, stack like mobile but with wider content (max 640) — not designed.
- Nav: logo + "Tải app" only, no menu; nothing sticky is specified.
- All two-column sections stack copy-first, visual-last (Chăm sóc, Cùng chăm, Night care); Hero visual follows the badges.
- Mockup visuals on mobile are uniform scale-downs of the desktop compositions (Hero 0.5583, Chăm sóc/Cùng chăm 0.5234, Night care 0.4917; Thao tác nhanh is re-composed at ~0.83 with fewer pieces). Recommended: build each visual once at desktop size and scale with `transform` inside a fixed-aspect wrapper; mark visuals `aria-hidden="true"` (their text is illustrative), and keep the real content in the copy.
- Tuổi thơ: timeline becomes vertical (no rotation); tiles stack.
- Quyền xem: cards and notes stack.
- FAQ: subtitle removed.

---

## 14. Asset list (`apps/landing/src/assets/figma/`)

All files verified to start with `<svg` (SVG) or to be valid JPEG/PNG. Colours left as exported (logo/art colours are the fixed brand/art palette).

| File | Source node | Use |
|---|---|---|
| `nav-logo-mark.svg` | Logo/Mark (in 219:1393) | Lockup mark; viewBox fixed to 34 × 34 (export had a 54.4 viewBox around a 34 px drawing). Scale for footer (27.2) / mobile (26.5, 23.8). |
| `nav-logo-wordmark.svg` | Logo/Wordmark (in 219:1393) | "child life" wordmark, ink #173D44, 132.4 × 26.52 |
| `logo-app-icon.svg` | Logo/App Icon (Live Activity) | 14.4 px app icon with rounded clip (Light). Night LA uses the same art. |
| `store-apple.svg`, `store-play.svg` | 226:164, 226:171 | White placeholder glyphs for dark badges |
| `store-apple-dark.svg`, `store-play-dark.svg` | 226:196, 226:203 | #141417 glyphs for light (CTA) badges |
| `hero-snapshot-today.png` | 224:3092 "Snapshot · 7a Hôm nay · Người chăm sóc · Light" | Phone A screen (1125 × 3375, 768 KB — compress/convert to WebP/AVIF at build) |
| `hero-snapshot-album.png` | 224:3093 "Snapshot · 10d Kỷ niệm · Album · Light" | Phone B screen (750 × 1624, 546 KB — compress) |
| `cungcham-family.svg` | Illustration/Family 231:637 (24:314) | Cùng chăm panel art 504.4 × 600 (initials + star + FloatChip are separate live elements) |
| `nightcare-starfield.svg` | 232:862–232:876 | Composed from the exported glow + 14 star ellipses, 600 × 560 layer (positions exact) |
| `nightcare-moon.svg` | Illustration/Mini/Moon 232:877 | 123.2 px moon (same art as `apps/mobile/assets/illustrations/mini-moon.svg`) |
| `photo-mint.svg` | 131:668 Tone=Mint | 200 × 200 SVG: tone gradient + embedded `baby-61240.jpg` |
| `photo-peach.svg` | 131:683 Tone=Peach | gradient #FFE3D8→#F7B9A5 + `baby-0d3f8.jpg` |
| `photo-sun.svg` | 131:698 Tone=Sun | #FFF1C9→#F9D77E + `baby-22456.jpg` |
| `photo-sky.svg` | 131:713 Tone=Sky | #DCEBFA→#A9CBEF + `baby-4222e.jpg` |
| `photo-lilac.svg` | 131:728 Tone=Lilac | #EDE3F8→#C8B1E8 + `baby-1025f.jpg` |
| `photo-night.svg` | 131:743 Tone=Night | #2B3A55→#16233A + `baby-2d978.jpg` (not used on the landing) |
| `photo-sand.svg` | 142:52 Tone=Sand | Mint gradient + `baby-5d2ff.jpg` |
| `photo-leaf.svg` | 143:58 Tone=Leaf | Mint gradient + `baby-ae95e.jpg` |
| `photo-rose.svg` | 144:39 Tone=Rose | Mint gradient + `baby-4470d.jpg` (not used on the landing) |
| `baby-*.jpg` (9 files: 0d3f8, 1025f, 22456, 2d978, 4222e, 4470d, 5d2ff, 61240, ae95e) | Raster fills of Illustration/Photo | 220 × 220 JPEGs (4–9 KB). Use directly with `object-fit: cover` (lighter than the SVG wrappers). Only 220 px — soft at 2× on the 150 px timeline photos; request higher-res originals if needed. |

Note on `photo-<tone>.svg`: Figma's Illustration/Photo is a raster photo over a 143.13° tone gradient (gradient stops 0 % and 71.429 %), not vector art; there is no vector export. These SVG wrappers reproduce the component faithfully (gradient + base64 image, `preserveAspectRatio="xMidYMid slice"`), so they are SVG files, but contain a JPEG.

Reuse from the app (do not duplicate):
- Icons `apps/mobile/assets/icons/`: plus, clock, journal, check, family, cloud-off, lock, eye, heart, bookmark, chevron-down, sleep, feed, star (all `stroke="currentColor"`; set colour via CSS; Figma uses stroke 1.2–1.5 at 16–20 px and 1.8 at 24).
- Illustrations `apps/mobile/assets/illustrations/`: mini-bottle, mini-drop, mini-moon, mini-diaper, baby-face, family.

CSS-only (not exported): hero mint circle, CTA white-6 % circle, stage gradients, lock-screen gradient, timeline rail gradient and nodes, tap ring/dot, Lock/Circular rings (SVG circles), DayRhythm bars.

---

## 15. Gaps / not in the design
1. FAQ answers for Q3–Q5 (221:3473, 221:3478, 221:3483 / mobile 233:1462, 233:1467, 233:1472) — copy needed.
2. Link targets: nav anchors (mapping above is a proposal), "Tải miễn phí"/"Tải app", store URLs, footer "Quyền riêng tư", "Điều khoản", "Liên hệ", FAQ "Cứ nhắn cho chúng tôi".
3. Official App Store / Google Play badges (current ones are placeholders).
4. Interaction states (hover/focus/pressed) for nav links, buttons, badges, FAQ items; accordion animation; any scroll/entrance motion (Figma has none; `10-motion-spec.md` app motion may be borrowed).
5. Tablet layout, dark-mode page variant, mobile menu.
6. SEO/meta copy (title, description, OG image) — not on the Website page.
7. Mobile design issues to fix in build: Thao tác nhanh step cards fixed at 40 px height (content overflows); Night care list item overflows its column; tiny (< 9 px) text inside scaled mockups; hero chip bleeds off-screen.
8. Product-copy checks carried over from `06`: caregiver "Gửi ảnh bé cho ba mẹ, không xem album riêng" implies caregiver photo upload; "Ông ngoại đã xem 12 ảnh mới" implies seen-receipts for relatives; "đủ chỗ cho hàng nghìn ảnh" (storage quota wording) — confirm against the app.
