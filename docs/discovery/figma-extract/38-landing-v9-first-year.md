# 38 — Landing V9: "Năm đầu đời" page (revision of the V8 page)

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only; no node modified). Extracted 2026-10-21. Same conventions as `35-landing-v8-first-year.md`: token names from `packages/design-tokens/dist/tokens.css`, non-token values marked **(raw)**, every visible string copied **verbatim from `get_design_context`** (layer names are stale or cut at 30 characters — e.g. the Tuổi thơ title layer is still named "Nơi lưu giữ trọn tuổi thơ của " but reads "Từ tấm ảnh trong máy đến kỷ niệm cả nhà cùng giữ.").

- Frame **`785:8698` "V9 · Năm đầu đời · Desktop"**, 1440 × 13672.2 (V8 `737:6362` was 13710.2), inside section `785:7030` "Child Life Website — V9" (siblings: home desktop `785:7031`, home mobile `785:7890`, Lumi `785:9913`, Chặng 2 `785:10743`, notes `793:68586`). **Desktop, Vietnamese only, Light only, no mobile frame**, no hover/focus states, no motion — as in V8.
- Baseline: the built V8 page (`pages/FirstYear.tsx`, `sections/FirstYearPage.tsx` and the reused sections) and spec 35. **This doc lists only differences.**
- Method: the V8 and V9 node trees were diffed (names, sizes, offsets; scratchpad `v9/v8tree.txt`, `v9/v9tree.txt`). Every section whose tree is identical was then confirmed by `get_design_context` text against `content/vi.ts` where it carries copy (Thao tác nhanh, Chăm sóc, Nhắc nhở, Cùng chăm, Quyền xem, Hiểu con, Lịch tiêm, Thư viện, Sơ cấp cứu, Night care); Nav, Điều hướng nhanh, group headers, Theo cách của bạn, Apple Watch, Hỏi đáp and Footer have identical trees (every text node the same name and size) and were not re-read.
- Screenshots (not committed): `scratchpad/v9/shots/fy-tuoitho.png` (1128 × 1200), `scratchpad/v9/shots/fy-ket.png` (1200 × 384).

Designer notes (`793:68586`, verbatim) and where they land:

| Note | On this page? |
|---|---|
| "• Ghi nhanh: thêm Widget, Điều khiển iOS, Siri (“Lumi ghi cữ bú 120 ml”…)." | **No.** The chips "Điều khiển iOS" / "Siri", the "ĐIỀU KHIỂN iOS" card and "Hey Siri…" / "“Lumi ghi cữ bú 120 ml.”" exist only on the V9 **home** (`787:68556`, `787:68581`, `787:68600`; mobile `792:9007`). This page's Thao tác nhanh `785:8768` is byte-identical to V8 (§5). Nothing to build here. |
| "• Năm đầu đời · Kỷ niệm: luồng 5 bước (tự tìm & chọn ảnh → xem theo mốc/tháng/tuần → video, thiệp → album cả nhà tương tác → câu chuyện & chia sẻ mạng xã hội)." | **Yes** — Tuổi thơ `785:9495` (§14), fully specified below. |
| (V9 Kết pattern: centred, store badges "có logo", no photo) | **Yes** — Kết `785:9895` (§19). |

---

## 0. Summary of changes

| # | Section | Node | y · h (V9) | Change |
|---|---|---|---|---|
| 1 | Nav | 785:8699 | 0 · 81 | **Link order changed** (§1) |
| 2 | Hero | 785:8709 | 81 · 444 | **Caption under the store badges removed** (§2) |
| 3 | Điều hướng nhanh | 785:8744 | 525 · 63 | unchanged |
| 4 | Nhóm 01–05 headers | 785:8761, 785:8927, 785:9060, 785:9488, 785:9614 | — | unchanged |
| 5 | Thao tác nhanh | 785:8768 | 719 · 1106 | unchanged (no Siri / Controls on this page) |
| 6 | Chăm sóc | 785:8816 | 1825 · 760 | unchanged |
| 7 | Nhắc nhở | 785:8849 | 2585 · 760 | unchanged |
| 8 | Cùng chăm | 785:8934 | 3476 · 728 | unchanged |
| 9 | Quyền xem | 785:8980 | 4204 · 883 | unchanged |
| 10 | Hiểu con | 785:9067 | 5218 · 1093 | unchanged |
| 11 | Lịch tiêm & tăng trưởng | 785:9193 | 6311 · 680 | unchanged |
| 12 | Thư viện & ăn dặm | 785:9345 | 6991 · 760 | unchanged |
| 13 | Sơ cấp cứu | 785:9422 | 7751 · 760 | unchanged |
| 14 | Tuổi thơ | 785:9495 | 8642 · **1533** (was 1499) | **NEW title + lead; timeline and 3 tiles replaced by a 5-step flow** (§14) |
| 15 | Night care | 785:9621 | 10306 · 688 | unchanged (moved down 34 px) |
| 16 | Theo cách của bạn | 785:9658 | 10994 · 588 | unchanged |
| 17 | Apple Watch | 785:9735 | 11582 · 722 | unchanged |
| 18 | Hỏi đáp | 785:9863 | 12304 · 724 | unchanged |
| 19 | Kết | 785:9895 | 13028 · **460** (was 532) | **NEW layout: centred, black store badges with logos, caption, no photo** (§19) |
| 20 | Footer | 785:9903 | 13488 · 184 | unchanged |

Section order, ids and groups (spec 35 §21) are unchanged.

---

## 1. Nav (`785:8699`) — link order

Layout, sizes, button unchanged. The five text links are re-ordered: **"Năm đầu đời" moves from 4th to 1st**.

| Pos | V8 (`737:6363`) | V9 (`785:8699`, verbatim) | x (V9) |
|---|---|---|---|
| 1 | "Chăm sóc" | **"Năm đầu đời"** | 762 |
| 2 | "Kỷ niệm" | "Chăm sóc" | 889 |
| 3 | "Lumi" | "Kỷ niệm" | 995 |
| 4 | "Năm đầu đời" | "Lumi" | 1085 |
| 5 | "Hỏi đáp" | "Hỏi đáp" | 1153 |
| button | "Bắt đầu" | "Bắt đầu" | 1244 |

The V9 Lumi frame (`785:9913`) uses the same order, so this is a site-wide nav change: reorder the `links` array in `components/Chrome.tsx` (`l.firstYear` first, then `l.care`, `l.memories`, `l.lumi`, `l.faq`). Targets, scroll-spy and `aria-current` stay as built. No new strings. Coordinate with the V9 home spec (same component).

## 2. Hero (`785:8709`) — caption removed

Everything is unchanged (chips "Đang có trong app" / "Chặng 1 · 0–12 tháng", H1 "Năm đầu đời của con, gọn trong một app.", lead, art 572 × 340) **except the "V8/CTA tải app" instance (`785:8719`)**: it is now **67 px tall (was 93) and contains only the badge row** — the caption line under the badges ("Tải miễn phí trên iPhone và Android." in V8) is gone. The badges are still the white V8 badges, prefix "Tải trên", names "App Store" / "Google Play". Copy column height 340 → 314 (re-centred, y 48 → 61; no spacing change).

Every V9 hero uses the 67 px instance (home `785:7048`, this page), so this is a component-level change. Implementation: `AppCta` gets a way to drop the caption (e.g. `<AppCta caption={false} />`) and the hero uses it. **Pre-launch conflict:** today's caption is `stores.captionSoon` "Sắp có trên iPhone và Android." while `storeLinks` are `null` (owner, 2026-10-19: badges are pictures with that line). Removing the caption pre-launch leaves two non-clickable badges with no explanation — see §25 #2.

The art is now exported as one flattened SVG in Figma, but the node tree (two circles + the stage-1 vector) is unchanged; keep `journey-art-stage1.svg` + the two circles.

## 3–13. Unchanged sections

- **Điều hướng nhanh** `785:8744` — unchanged ("Đi nhanh tới:", 5 chips).
- **Group headers** — unchanged (same five numbers, titles and subtitles; Tuổi thơ still sits alone in group 04 "Kỷ niệm" / "Giữ lại những lần đầu tiên của con.").
- **Thao tác nhanh** `785:8768` — unchanged: the full `get_design_context` output equals V8's (`scratchpad/v8/quick.tsx`) after stripping node ids. Title "Ghi nhanh từ widget và màn hình khoá.", lead, stage, steps all as built. **No Widget/Điều khiển iOS/Siri additions on this page.**
- **Chăm sóc** `785:8816`, **Nhắc nhở** `785:8849`, **Cùng chăm** `785:8934`, **Quyền xem** `785:8980`, **Hiểu con** `785:9067`, **Lịch tiêm & tăng trưởng** `785:9193`, **Thư viện & ăn dặm** `785:9345`, **Sơ cấp cứu** `785:9422`, **Night care** `785:9621` — unchanged; every string equals `vi.ts`, except the PROPOSED overrides already in code, which Figma still does not carry: Nhắc nhở bullet 2 sub still "Bố mẹ và người chăm — không làm phiền ông bà" (code "Ba mẹ…"), Quyền xem caregiver card still "Gửi ảnh bé cho ba mẹ, không xem album riêng" (Q-008) and note 1 still "Ảnh mới mặc định chỉ ba mẹ thấy. Muốn khoe cả nhà, bạn chỉ cần chọn "Gia đình"." (D-001). **Keep the overrides.**
- **Theo cách của bạn** `785:9658`, **Apple Watch** `785:9735`, **Hỏi đáp** `785:9863`, **Footer** `785:9903` — unchanged.

---

## 14. Tuổi thơ (`785:9495`) — NEW 5-step flow

Replaces, on this page, the V8 Tuổi thơ body (horizontal timeline 1248 × 580 + three tiles). `Memories` (`sections/Memories.tsx`) is used **only** by `pages/FirstYear.tsx`, and `c.memories.*` is read only there, so the component can be rewritten in place.

### 14.1 Section and head

Section (unchanged frame styles): bg **`surface`**, `display:flex; flex-direction:column; align-items:center; gap:56px; padding:112px 96px`. Height 1533.

Head (`785:9496`): flex column, gap 16, centred.
- Eyebrow (unchanged): pill `sunshine-soft`, `padding:6px 12px`, r 999, **SemiBold 13 `care-growth-ink`**: "Kỷ niệm".
- Title (`785:9499`) **Bold 44 / 1.18, tracking −0.66 px, `ink`, centred, width 900** — two lines at 900:

| Key | V8 / current | V9 (verbatim) |
|---|---|---|
| `memories.title` | "Ảnh, thiệp, video và nhật ký của con." | **"Từ tấm ảnh trong máy đến kỷ niệm cả nhà cùng giữ."** |
| `memories.lead` | "Ảnh, video và những câu chuyện nhỏ được xếp theo từng tháng tuổi của con. Không lạc giữa hàng nghìn ảnh trong điện thoại, không sợ mất — mở ra là thấy con lớn lên." | **"Child Life tự tìm ảnh của con, xếp theo mốc, tháng, tuần; giúp bạn tạo video, thiệp, chia sẻ với gia đình và kể lại thành câu chuyện."** |

- Lead (`785:9500`) **Medium 18 / 1.55 `ink-muted`, centred, width 700** (two lines).

### 14.2 Flow container "Luồng kỷ niệm" (`791:8807`)

1248 × 1033, `display:flex; flex-direction:column; gap:24px`. Three children: the step strip, row 1 (2 cards), row 2 (3 cards).

**Removed** from this page: the 1248-wide timeline (`timeline-wide`, `timeline-list`) as a standalone block, the three `.tile`s ("Ảnh của con, gọn gàng một chỗ", "Câu chuyện của con", "Ông bà ở xa vẫn thấy cháu lớn") and their titles / bodies. Their mock art is **reused inside the step cards** (see below). Keys that become unused: `memories.tiles.photos.title/body`, `memories.tiles.story.title/body`, `memories.tiles.family.title/body` (the chip, letter, moment and notifications stay).

### 14.3 Step strip "Các bước" (`791:8808`)

`display:flex; gap:8px; align-items:center; justify-content:center`, full width, height 42. Five pills separated by four `arrow-right` icons (14 px; colour from the asset, use `ink-muted`).

Pill: bg `surface`, `border:1px solid var(--separator)`, r 999, `padding:8px 14px 8px 8px`, gap 8, align center.
- Number disc: 24 × 24, r 999, bg **`#fad9cc` (raw)**, text **Bold 12 `#994526` (raw)**, centred.
- Label **SemiBold 14 `ink`**.

| # | Node | Label (verbatim) |
|---|---|---|
| 1 | 791:8809 | "Tự tìm & chọn ảnh" |
| 2 | 791:8815 | "Xem theo mốc, tháng, tuần" |
| 3 | 791:8821 | "Tạo video, thiệp" |
| 4 | 791:8827 | "Album cả nhà" |
| 5 | 791:8833 | "Câu chuyện & chia sẻ" |

Semantics (proposal; Figma static): an `<ol>` summary, `aria-hidden="true"` (the cards below repeat "Bước n" and the full titles), or plain links to the card anchors — not required. `#fad9cc` / `#994526` have no token; closest are `peach-soft` #FFE3DA and `care-growth-ink` #9A4A14 — keep raw, or map with owner OK.

### 14.4 Step card (shared shape)

Each card: bg `surface`, r **24**, `overflow:hidden`, shadow **`var(--shadow-card)`** (Figma `0 8px 24px rgba(23,61,68,.08), 0 1px 2px rgba(23,61,68,.06)`), flex column, `align-self:stretch` (cards in a row share the tallest height).
- **Art** block: full card width × **280**, own tint (per step), `position:relative; overflow:hidden`.
- **Text** block "tx": flex column, gap 8, `padding:20px 24px 24px`:
  - Step chip: bg `cloud`, `padding:3px 8px`, r 999, **SemiBold 11 `ink-muted`**: "Bước n".
  - Title **Bold 20 / normal `ink`** (an `<h3>`).
  - Body **Medium 15 / 1.5 `ink-muted`**.
  - Tags row: gap 6; each tag bg `mint-soft`, `padding:3px 8px`, r 999, **SemiBold 11 `mint-text`**.

Row 1 (`791:8837`): `display:flex; gap:24px`, two cards **612** wide (card height 459). Row 2 (`791:8838`): `display:flex; gap:24px`, three cards **400** wide (height 484 — card 4's title wraps to two lines and the others stretch).

### 14.5 Card 1 — "Bước 1 · Tự tìm & chọn ảnh" (`791:8839`, 612 × 459)

Art (`791:8840`) 612 × 280, bg **`#e5f5f2` (raw, ≈ `mint-soft` #E6F7F5 — use `mint-soft`)**.
- Photo grid group (`791:8854`) at **(202, 30)**, 400 × 240, `overflow:hidden` — **identical to the V8 tile 1 art** (`.tile__group--grid`): six 96 × 96 photos, r 14, bg `surface-2`, at x 40 / 144 / 248, y 22 / 126; tones in order **mint, peach, sun, lilac, sky, mint** (current code uses `leaf` for the 6th; either is fine); favourite chip (`791:8867`) at (220, 184): bg `surface`, `padding:8px 12px`, r 999, gap 6, shadow `0 16px 18px rgba(13,38,33,.14)` (raw drop shadow, same as today's `.grid-chip`), `bookmark` 14 + **SemiBold 12 `ink`** "Yêu thích · 48" (= `memories.tiles.photos.chip`). Reuse the existing grid markup offset to (202, 30).
- **NEW card "Đã tìm thấy"** (`791:8870`) at **(28, 56)**, width 250, bg `surface`, r 18, `padding:14px`, flex column gap 10, shadow `0 8px 12px rgba(23,61,68,.08), 0 1px 1px rgba(23,61,68,.06)` (the site's small card drop shadow, as on the Vaccines cards). It overlaps the grid's left column.
  - Header row, gap 8, align center: icon tile bg `mint-soft`, `padding:8px`, r 12, `search` 14 (`mint-text`); **SemiBold 13 `ink`**: "Tìm thấy 8 ảnh mới của Teddy".
  - **Medium 12 `ink-muted`**: "Chụp hôm nay · 2 ảnh trùng đã ẩn".
  - Buttons row, gap 8: "Lưu tất cả" — bg `mint-deep`, `padding:8px 14px`, r 999, **SemiBold 13 `on-mint-deep`**; "Chọn ảnh" — bg `surface`, `border:1px solid var(--control-border)`, `padding:8px 14px`, r 999, **SemiBold 13 `ink`**. Decorative (`aria-hidden`, not buttons).

Text:
- Chip "Bước 1"
- Title: "Tự động tìm, bạn chỉ chọn và lưu"
- Body: "Ảnh mới của con được nhận ra và gom lại. Lưu tất cả, hoặc chọn những tấm đẹp nhất — ảnh trùng, ảnh mờ được lọc bớt."
- Tags: "Tự động", "Chọn nhanh", "Riêng tư"

### 14.6 Card 2 — "Bước 2 · Xem theo mốc, tháng, tuần" (`791:8883`, 612 × 459)

Art (`791:8884`) 612 × 280, bg **`#ededfc` (raw, ≈ `care-sleep-soft` #EDEEFC — use the token)**.
- **NEW view switch "Chế độ xem"** (`791:8898`) at **(193, 18)**, 226 × 40: bg `surface`, `padding:4px`, gap 4, r 999, small card shadow (as above). Three segments, each `padding:8px 18px`, r 999, **SemiBold 13**: "Mốc" (selected: bg `mint-deep`, text `on-mint-deep`), "Tháng" and "Tuần" (no fill, `ink-muted`).
- **Mini timeline** (`791:8905`) at **(90.83, 66)**, 430.345 × 200: **exactly the V8 / current `timeline-wide` composition (1248 × 580) scaled by 0.34483** (430.345 / 1248 = 200 / 580): same rail gradient (`#2ea899 → #fab88c 85% → transparent`), 7 nodes, stems, 7 rotated polaroids and the end label, same strings from `memories.timeline` / `memories.timelineEnd` ("Ngày đầu"/"Về nhà", "5 tuần"/"Lần đầu cười", "4 tháng"/"Lần đầu lẫy", "9 tháng"/"Chiếc răng đầu tiên", "1 tuổi"/"Sinh nhật đầu tiên", "2 tuổi"/"Những bước chạy", "3 tuổi"/"Ngày đầu đi học", "…và mọi năm sau nữa"). Implement by rendering the existing 1248 × 580 markup inside a box with `transform: scale(0.34483); transform-origin: 0 0` (or `<Fit w={1248} h={580}>` in a 430 × 200 slot). At this scale the captions are 4.5–5.2 px: decorative only, `aria-hidden` (§25 #4). The draw-in animation (`grow-x`, `pop`) can stay.

Text:
- Chip "Bước 2"
- Title: "Xem lại theo mốc, tháng hoặc tuần"
- Body: "Một chạm để đổi cách xem: theo những lần đầu tiên của con, theo từng tháng tuổi, hay từng tuần gần đây."
- Tags: "Mốc", "Tháng", "Tuần"

### 14.7 Card 3 — "Bước 3 · Tạo video, thiệp" (`791:8964`, 400 × 484)

Art (`791:8965`) 400 × 280, bg **`#fff5db` (raw, ≈ `sunshine-soft` #FFF4D6 — use the token)**. All NEW:
- Video still "Photo" (`791:8977`) at **(30, 40)**, 200 × 150, r 16, bg `surface-2`, `overflow:hidden`; photo tone **peach** (`photos.peach` = `teddy-eight-months.jpg`) 200 × 200 at `top:-25px` (→ `object-fit:cover` in the 200 × 150 box). Alternative with motion intent: `scenes.firstYearVideo` (the Keepsakes memory-video still) if it reads better — owner/design choice; Figma uses the library photo.
- Play button "Phát" (`791:8984`) at **(108, 93)**, 44 × 44, r 999, bg `rgba(255,255,255,0.92)` (raw), centred `arrow-right` 18 (`ink`). (Figma uses the arrow icon as a play glyph; there is no `play` icon in `primitives.tsx`.)
- Duration chip (`791:8988`) at **(40, 200)**: bg `surface`, `padding:3px 8px`, r 999, **SemiBold 11 `ink`**: "0:45 · Tròn 6 tháng".
- Card "Thiệp" (`791:8989`): rotated **+4°**, its 161.1 × 175.1 bounding box at **(213.02, 80)** (centre the card in it); card width 150, bg **`#fffcf2` (raw)**, `padding:14px`, gap 4, r 14, small card shadow, items centred:
  - Photo 122 × 90, r 8, bg `surface-2`, tone **sun** (`photos.sun` = `teddy-one-couch.jpg`), 122 × 122 at `top:-16px`.
  - **Bold 20 `#994526` (raw)**: "100 ngày"
  - **Medium 11 `ink-muted`**: "Teddy · 18.01"

Text:
- Chip "Bước 3"
- Title: "Tạo video, thiệp trong vài chạm"
- Body: "Chọn mẫu tròn tháng, 100 ngày, sinh nhật — app ghép ảnh, nhạc và chữ cho bạn."
- Tags: "Video", "Thiệp"

### 14.8 Card 4 — "Bước 4 · Album cả nhà" (`791:8999`, 400 × 484)

Art (`791:9000`) 400 × 280, bg **`#ffe5db` (raw, ≈ `peach-soft` #FFE3DA — use the token)**. Inner group (`791:9014`) at **(0, 20)**, 400 × 240 = **the V8 tile 3 art unchanged** (`.tile__group--notes`): three notification chips at (30, 28), (44, 94), (58, 160); bg `surface`, r 16, `padding:10px 14px 10px 10px`, gap 10, shadow `0 16px 18px rgba(13,38,33,.14)`; avatar `padding:8px 10px` r 999 **Bold 13 `ink`** on `card-peach` / `care-sleep-soft` / `mint-soft`; text **SemiBold 13 `ink`** + **Medium 11 `ink-muted`**; `heart` 16.

| Avatar | Text (Figma, verbatim) | When | Code today |
|---|---|---|---|
| "Bà" | "Bà nội thương ảnh của Teddy" | "vừa xong" | same |
| "Ô" | "Ông ngoại đã xem 12 ảnh mới" | "5 phút trước" | PROPOSED (Q-009) "Ông ngoại thương 3 ảnh mới" — **keep the override** |
| "C" | "Cô Lan thương câu chuyện" | "hôm qua" | same (see §25 #6) |

Only the vertical offset changes (art is 280 tall, group top 20 instead of the V8 tile's 18 / 240-tall art).

Text:
- Chip "Bước 4"
- Title (wraps to 2 lines at 352): "Album riêng, cả nhà cùng tương tác"
- Body: "Mời ông bà, người thân vào album. Mọi người xem, thả tim và bình luận dưới từng ảnh."
- Tags: "Chia sẻ", "Bình luận", "Thả tim"

### 14.9 Card 5 — "Bước 5 · Câu chuyện & chia sẻ" (`791:9036`, 400 × 484)

Art (`791:9037`) 400 × 280, bg **`#f2f7e5` (raw; no token — light leaf green)**.
- Inner group (`791:9049`) at **(0, −10)**, 400 × 240 = **the V8 tile 2 art unchanged**: StoryCard "letter" (rotated +6°, box (49.09, 40) 180 × 215.6) and StoryCard "moment" (rotated −5°, box (190, 16.06) 176.8 × 213.2); all strings as today (`memories.tiles.story.letter.*`, `.moment.*`: "Gửi Teddy,", the letter body, "— Mẹ, mùa thu 2026", "Lần đầu cười · 5.10", "“Như thể con cũng thuộc lời ru ấy.”", "TEDDY · 3 TUẦN TUỔI", "Child Life"). Today's `.tile__group--story` positions apply, shifted to the new art box.
- **NEW share bar "Chia sẻ"** (`791:9052`) at **(31, 230)**, 338 × 36: bg `surface`, `padding:8px 10px`, gap 6, r 999, small card shadow, align center. It overlaps the bottom of the story cards.
  - **SemiBold 12 `ink-muted`**: "Chia sẻ:"
  - Four chips, bg `cloud`, `padding:3px 8px`, r 999, **SemiBold 11 `ink`**: "Facebook", "Instagram", "Zalo", "Lưu ảnh". Plain text, no brand logos (do not add any).

Text:
- Chip "Bước 5"
- Title: "Gợi ý câu chuyện, chia sẻ ra ngoài"
- Body: "App gợi ý câu chuyện từ ảnh và nhật ký. Bạn sửa vài chữ rồi đăng lên mạng xã hội khi muốn."
- Tags: "Câu chuyện", "Mạng xã hội"

### 14.10 Implementation notes

- **Icons**: `arrow-right`, `search`, `bookmark`, `heart` all exist in `components/primitives.tsx`. No new icon needed (no `play`; Figma uses `arrow-right`).
- **Image slots** (no new downloads): grid and story/notification art reuse today's `Photo` tones (`photos` map → `assets/photos/teddy-*.jpg`); video still = `photos.peach` (or `scenes.firstYearVideo`); card photo = `photos.sun`; mini timeline = today's timeline tones.
- **Semantics**: `<ol class="mem-flow">` of five `<li><article aria-labelledby>`; each art block `aria-hidden="true"`; card titles one level below the section title (today `Memories` renders its title as `<h2 class="h2">`, so the cards use `<h3>`, as the V8 tiles do).
- **Content keys** (proposal; vi and en same ids, D-012):

```ts
memories: {
  eyebrow, title, lead,            // title + lead changed
  timeline, timelineEnd,           // kept (card 2 mini timeline)
  steps: [                          // NEW: strip label + card
    { label: 'Tự tìm & chọn ảnh', title, body, tags: ['Tự động', 'Chọn nhanh', 'Riêng tư'] },
    { label: 'Xem theo mốc, tháng, tuần', title, body, tags: ['Mốc', 'Tháng', 'Tuần'] },
    { label: 'Tạo video, thiệp', title, body, tags: ['Video', 'Thiệp'] },
    { label: 'Album cả nhà', title, body, tags: ['Chia sẻ', 'Bình luận', 'Thả tim'] },
    { label: 'Câu chuyện & chia sẻ', title, body, tags: ['Câu chuyện', 'Mạng xã hội'] },
  ],
  stepChip: 'Bước {n}',
  found: { title: 'Tìm thấy 8 ảnh mới của Teddy', sub: 'Chụp hôm nay · 2 ảnh trùng đã ẩn', saveAll: 'Lưu tất cả', pick: 'Chọn ảnh' },
  views: ['Mốc', 'Tháng', 'Tuần'],   // switch in card 2 art (same words as the tags; may share)
  video: { chip: '0:45 · Tròn 6 tháng' },
  card: { title: '100 ngày', meta: 'Teddy · 18.01' },
  share: { label: 'Chia sẻ:', targets: ['Facebook', 'Instagram', 'Zalo', 'Lưu ảnh'] },
  tiles: { photos: { chip }, story: { letter, moment }, family: { notifications } }, // titles/bodies removed
}
```

- **Mobile (not designed, proposal)**: step strip becomes a horizontally scrollable row (no wrap) or is hidden below 600 px (cards carry "Bước n"); cards stack one per row, full width; each 612 × 280 / 400 × 280 art is rendered at its desktop size inside `Fit` (`mobileScale` = width / 612 or / 400); the old `timeline-list` vertical list is no longer needed.
- `content-visibility` / `contain-intrinsic-size` on `.memories` (layout.css) should be updated to the new height (~1533 desktop).

---

## 19. Kết (`785:9895`) — NEW centred card (same template on V9 home `785:7872` and Chặng 2 `785:10856`)

Shared component: `sections/Closing.tsx` is used by Home, StagePage and this page, and all three V9 Kết frames are the same template (badges `790:8824`, `793:68569`, `794:8818`), so this is a **site-wide** change of `Closing`. Coordinate with the V9 home spec.

Section (`785:9895`): bg **`surface`**, `display:flex; flex-direction:column; padding:24px 96px 96px`. Height **460** (was 532).

Card "Thẻ" (`785:9896`): width 1248, height 340, bg **`#163d44` (raw, ≈ `ink`; same as V8)**, r **40**, `padding:64px 56px`, `display:flex; align-items:center; justify-content:center`. **No photo** (V8's 420 × 300 `photos.sun` panel is removed; remove `.closing__photo`).

Column "c" (`785:9897`): flex column, **gap 20, items centred, text centred**:
1. Title (`785:9898`) **Bold 40 / 1.18 white, centred, one line (nowrap)**: "Bắt đầu từ năm đầu đời của con." (= `closing.title`, unchanged)
2. Sub (`785:9899`) **Medium 17 / 1.55 `#cce0e0` (raw), centred, one line**: "Ghi chép, nhắc nhở và kỷ niệm — cả nhà cùng một nơi." (= `closing.sub`, unchanged)
3. **Badge row "Huy hiệu tải app"** (`793:68569`): `display:flex; gap:12px`, 389 × 63. **New badge style** (official-store look, not the V8 white badge):
   - Each badge: bg **black (raw `#000`)**, `border:1px solid #a6a6a6` (raw), r **12**, `padding:10px 18px 10px 14px`, gap 10, align center. App Store 178 × 63, Google Play 199 × 63.
   - **Logo 28 × 28**: the real Apple logo (white) and the multi-colour Google Play triangle — "có logo" in the V9 note. The current glyphs `assets/figma/store-apple.svg` / `store-play.svg` are **placeholders** (a circle + ellipse, a white triangle) and do not match.
   - Text column, white, no wrap: prefix **Medium 11**, name **SemiBold 21**.

     | Badge | Prefix (verbatim) | Name |
     |---|---|---|
     | App Store (`793:68570`) | "Tải về trên" | "App Store" |
     | Google Play (`793:68576`) | "Tải nó trên" | "Google Play" |

   - Recommendation: use the **official Vietnamese badge artwork** from Apple (App Store Marketing Guidelines) and Google (Play badge generator) as SVG files in `assets/` instead of re-typing the text and drawing logos — both stores require their artwork unaltered, and the Figma texts are exactly their Vietnamese lockups ("Tải về trên App Store", "TẢI NÓ TRÊN Google Play"). The artwork is a download from those sites — ask the owner before fetching. Until then, implement as drawn with text + logo SVG.
   - Links: unchanged rule (`StoreBadges`: a link to the listing once `storeLinks` has it, a static `aria-hidden` picture before).
4. Caption (`793:68585`) **Medium 13 / normal `#cce0e0` (raw), centred**: "Miễn phí trên iPhone và Android." (new wording, see table).

| Key | Current vi | V9 vi (verbatim) | en today |
|---|---|---|---|
| `stores.caption` | "Tải miễn phí trên iPhone và Android." | **"Miễn phí trên iPhone và Android."** | "Free on iPhone and Android." (already matches) |
| `stores.appStore.prefix` (Kết badge) | "Tải trên" | **"Tải về trên"** | "Download on the" (already the official en text) |
| `stores.googlePlay.prefix` (Kết badge) | "Tải trên" | **"Tải nó trên"** | "Get it on" (already the official en text) |

The hero (§2) still draws the white V8 badges with "Tải trên"; see §25 #1 for unifying.

Implementation sketch: `Closing` → centred column, `<StoreBadges variant="official" />` (new black variant) + caption (`launched ? stores.caption : stores.captionSoon`); drop the photo; card height follows content (64 + 47 + 20 + 26 + 20 + 63 + 20 + 16 + 64 ≈ 340). Mobile (V9 home mobile Kết `785:8683` exists — follow the V9 home spec for the stacked badges; 310 px wide group, badges stacked).

---

## 23. English drafts (engineering, for owner review)

| Key (proposed) | vi (Figma) | en draft |
|---|---|---|
| `memories.title` | "Từ tấm ảnh trong máy đến kỷ niệm cả nhà cùng giữ." | "From the photos on your phone to memories the whole family keeps." |
| `memories.lead` | "Child Life tự tìm ảnh của con, xếp theo mốc, tháng, tuần; giúp bạn tạo video, thiệp, chia sẻ với gia đình và kể lại thành câu chuyện." | "Child Life finds your baby's photos for you and sorts them by milestone, month and week; then helps you make videos and cards, share with family and turn them into stories." |
| `memories.steps[0].label` | "Tự tìm & chọn ảnh" | "Find & pick photos" |
| `memories.steps[1].label` | "Xem theo mốc, tháng, tuần" | "View by milestone, month, week" |
| `memories.steps[2].label` | "Tạo video, thiệp" | "Make videos, cards" |
| `memories.steps[3].label` | "Album cả nhà" | "Family album" |
| `memories.steps[4].label` | "Câu chuyện & chia sẻ" | "Stories & sharing" |
| `memories.stepChip` | "Bước {n}" | "Step {n}" |
| `memories.steps[0].title` | "Tự động tìm, bạn chỉ chọn và lưu" | "Found for you — just pick and save" |
| `memories.steps[0].body` | "Ảnh mới của con được nhận ra và gom lại. Lưu tất cả, hoặc chọn những tấm đẹp nhất — ảnh trùng, ảnh mờ được lọc bớt." | "New photos of your baby are recognised and gathered. Save them all or pick the best ones — duplicates and blurry shots are filtered out." |
| `memories.steps[0].tags` | "Tự động", "Chọn nhanh", "Riêng tư" | "Automatic", "Quick pick", "Private" |
| `memories.found.title` | "Tìm thấy 8 ảnh mới của Teddy" | "Found 8 new photos of Teddy" |
| `memories.found.sub` | "Chụp hôm nay · 2 ảnh trùng đã ẩn" | "Taken today · 2 duplicates hidden" |
| `memories.found.saveAll` / `.pick` | "Lưu tất cả" / "Chọn ảnh" | "Save all" / "Choose photos" |
| `memories.steps[1].title` | "Xem lại theo mốc, tháng hoặc tuần" | "Look back by milestone, month or week" |
| `memories.steps[1].body` | "Một chạm để đổi cách xem: theo những lần đầu tiên của con, theo từng tháng tuổi, hay từng tuần gần đây." | "One tap to switch views: by your baby's firsts, by month of age, or week by week lately." |
| `memories.steps[1].tags` / `memories.views` | "Mốc", "Tháng", "Tuần" | "Milestones", "Months", "Weeks" |
| `memories.steps[2].title` | "Tạo video, thiệp trong vài chạm" | "Videos and cards in a few taps" |
| `memories.steps[2].body` | "Chọn mẫu tròn tháng, 100 ngày, sinh nhật — app ghép ảnh, nhạc và chữ cho bạn." | "Pick a monthly, 100-day or birthday template — the app puts the photos, music and words together for you." |
| `memories.steps[2].tags` | "Video", "Thiệp" | "Video", "Card" |
| `memories.video.chip` | "0:45 · Tròn 6 tháng" | "0:45 · 6 months old" |
| `memories.card.title` / `.meta` | "100 ngày" / "Teddy · 18.01" | "100 days" / "Teddy · 18 Jan" |
| `memories.steps[3].title` | "Album riêng, cả nhà cùng tương tác" | "A private album the whole family enjoys" |
| `memories.steps[3].body` | "Mời ông bà, người thân vào album. Mọi người xem, thả tim và bình luận dưới từng ảnh." | "Invite grandparents and relatives. Everyone can look, send a heart and comment on each photo." (see §24 #4 — "comment" is not in the app) |
| `memories.steps[3].tags` | "Chia sẻ", "Bình luận", "Thả tim" | "Share", "Comment", "Heart" |
| `memories.steps[4].title` | "Gợi ý câu chuyện, chia sẻ ra ngoài" | "Suggested stories, shared beyond the family" |
| `memories.steps[4].body` | "App gợi ý câu chuyện từ ảnh và nhật ký. Bạn sửa vài chữ rồi đăng lên mạng xã hội khi muốn." | "The app suggests a story from your photos and journal. Change a few words, then post it on social media when you like." |
| `memories.steps[4].tags` | "Câu chuyện", "Mạng xã hội" | "Stories", "Social media" |
| `memories.share.label` | "Chia sẻ:" | "Share:" |
| `memories.share.targets` | "Facebook", "Instagram", "Zalo", "Lưu ảnh" | "Facebook", "Instagram", "Zalo", "Save image" |
| `stores.caption` | "Miễn phí trên iPhone và Android." | "Free on iPhone and Android." (unchanged) |
| `stores.appStore.prefix` | "Tải về trên" | "Download on the" (unchanged) |
| `stores.googlePlay.prefix` | "Tải nó trên" | "Get it on" (unchanged) |

Unchanged en for the reused art: `memories.timeline*`, `tiles.photos.chip` "Favourites · 48", `tiles.story.letter/moment`, `tiles.family.notifications` (en already reads "Grandpa loved 3 new photos" — the Q-009 override — and "Aunt Lan loved the story").

## 24. Claims to check (`docs/product/business-map.md`)

1. **"Child Life tự tìm ảnh của con" / Bước 1 "Tự động tìm…", "Tìm thấy 8 ảnh mới của Teddy"** — this is Tự lưu (**D-066**): **iOS only** in the beta, behind the rollout flag `auto_save` (**P-148**, off → internal → % → all), needs a separate face-analysis consent (**P-147**), "v1 recognition does not have to be accurate" (**P-149**). Android users get nothing from step 1. The title-level lead makes it the headline of the section. Owner: accept as a beta feature, or soften ("Child Life có thể tự tìm ảnh của con trên iPhone…"). Week-of-age scanning from the date of birth is **P-171**; the date of birth stays on the phone (D-068 #9).
2. **"ảnh trùng, ảnh mờ được lọc bớt" / "2 ảnh trùng đã ẩn"** — duplicates: the dedupe ledger **P-150** ("Đã có"); bursts grouped with the best photo pre-selected, scored partly on sharpness (**P-146**). "Lọc bớt ảnh mờ" is a reasonable reading of P-146 ranking but nothing hides blurry photos — wording, not a blocker.
3. **"Riêng tư" (step 1 tag)** — supported by D-066 (face data on the phone, never uploaded; uploads default to Chỉ ba mẹ).
4. **Bước 4 "thả tim và bình luận dưới từng ảnh", tag "Bình luận"** — **there are no comments in the app.** The data model has `Reaction` ("Thương") only; the nearest feature is **D-034** "Nhắn ba mẹ" (a one-way message to parents attached to an item), which relatives can send but not read as a thread. **Must change before release** (proposal: body "Mời ông bà, người thân vào album. Mọi người xem, thả tim và nhắn ba mẹ dưới từng ảnh." and tag "Nhắn ba mẹ", or drop "và bình luận"). "Mời ông bà, người thân vào album": invites are to the family, albums carry an audience (**D-002**, R-033 "Luôn có: xem kỷ niệm, thả tim") — acceptable shorthand. "Album riêng" fits "Chỉ ba mẹ" / Gia đình audiences.
5. **"Ông ngoại đã xem 12 ảnh mới"** — **Q-009** (no seen receipts); keep the PROPOSED "Ông ngoại thương 3 ảnh mới". **"Cô Lan thương câu chuyện"** — fine if Cô Lan is a relative (en "Aunt Lan"); a caregiver can never love or see Memories (**Q-008**, app matrix "Love ("Thương")" ❌ for Người chăm).
6. **Bước 2 "Xem lại theo mốc, tháng hoặc tuần"** — Ảnh groups by "Tuần tuổi · Tháng tuổi · Tháng trong năm" (**P-131**) and the view sheet groups by Tuần / Ngày / Tháng with a "Có mốc" filter (**R-112**). A "Mốc" *view* as drawn (segmented Mốc / Tháng / Tuần) does not exist; "Có mốc" is a filter. Wording OK as marketing; the switch mock is not the app UI.
7. **Bước 3 "Tạo video, thiệp trong vài chạm" / "tròn tháng, 100 ngày, sinh nhật" / "app ghép ảnh, nhạc và chữ"** — Video kỷ niệm and Thiệp cột mốc are **D-068** (free beta, rollout flag per family; the nudged occasions are 7 ngày, 1 tháng, 100 ngày, 1 tuổi — confirm that "tròn tháng" templates exist for every month, since the mock chip says "Tròn 6 tháng"). **Music** is open: **Q-062** (licensed source, picker not in V1) — "nhạc" should stay only if at least one licensed track ships.
8. **Bước 5 "App gợi ý câu chuyện từ ảnh và nhật ký"** — story suggestions are written **from text only** (captions, notes, milestones, dates, counts) with ≤ 9 photos attached by the server (**D-041**); the model does not read the photos. Proposal: "App gợi ý câu chuyện từ nhật ký và kỷ niệm của con." **"đăng lên mạng xã hội" / Facebook, Instagram, Zalo, "Lưu ảnh"** — supported by **R-160** ("Ra ngoài — Thiệp ảnh (Facebook, Instagram, Zalo)"; "Chỉ ba mẹ thấy mục 'Ra ngoài'. Mặc định ẩn tên thật và ngày sinh."): the share is a photo card through the system share sheet, parents only. OK; the landing must not imply relatives can post. No brand logos on the landing (none drawn).
9. **Siri / iOS Controls / widgets** (note "Ghi nhanh: thêm Widget, Điều khiển iOS, Siri") — **not on this page.** For the home spec: iOS widget and Live Activity extensions still wait on the Apple account / App Groups (**D-045**); Android widgets are planned, not shipped (**D-071**, `android-plan.md`); Siri / voice logging is an open question for the watch (**Q-052**) with no phone decision; Control Center controls have no D/R entry. Live Activity is only for sleep / breastfeeding, never pumping (**D-026**) — the unchanged Thao tác nhanh and Night care mocks show a sleep Live Activity, which is fine.
10. **Kết caption "Miễn phí trên iPhone và Android."** and hero without caption — store listings do not exist (`site.ts storeLinks` null); the owner's 2026-10-19 rule shows "Sắp có trên iPhone và Android." with static badges. Keep `captionSoon` until launch (§25 #2). "Miễn phí" is fine (no Lumi plan claim; Q-071 untouched).
11. **Store badge artwork** — Apple and Google require their official badges, unaltered; the current glyphs are placeholders (already noted in `StoreBadges.tsx`). V9 now draws real logos: a release gate for the landing, not a product decision.

## 25. Ambiguities / design bugs

1. **Two badge styles on one page.** The hero still uses the white V8 badges with "Tải trên", the Kết uses black official-style badges with "Tải về trên" / "Tải nó trên". Recommend one style site-wide: the official badges (black, official Vietnamese text) everywhere, changing `stores.*.prefix` once; the en strings are already the official ones. Owner/design call.
2. **Hero without caption before launch.** V9 removes the caption under the hero badges. Before the listings exist the badges are static pictures; with no caption the hero shows two dead badges. Recommend: keep the hero caption **only while not launched** (`captionSoon`), drop it after launch as drawn; Kết always shows its caption (`launched ? caption : captionSoon`).
3. **Step colours without tokens**: number disc `#fad9cc` / `#994526`, card-3 thiệp `#fffcf2` and title `#994526`, card-5 art `#f2f7e5`, Kết `#163d44` / `#cce0e0`, badge `#000` / `#a6a6a6`. The art tints `#e5f5f2`, `#ededfc`, `#fff5db`, `#ffe5db` are 1–2 units off `mint-soft`, `care-sleep-soft`, `sunshine-soft`, `peach-soft` — use the tokens (Night palette safety).
4. **Unreadable mini timeline.** Card 2 scales the whole 1248 px timeline to 34 %: captions are 4.5–5.2 px. Decorative only (`aria-hidden`); if the owner wants it legible, show 4 polaroids at a larger scale instead (design change).
5. **Mock data inconsistent with the rest of the page** (as in V8 §25 #5): Teddy is "3 tuần" everywhere, but the flow shows "0:45 · Tròn 6 tháng", a "100 ngày" card dated "18.01" and a timeline up to "3 tuổi". Harmless for marketing; keep Figma unless the owner asks.
6. **"Cô Lan"** — reads as a nanny in Vietnamese as easily as an aunt; the Roles card calls the caregiver "Bảo mẫu, cô giúp việc" with avatar "C". If the owner means a caregiver, it contradicts Q-008 — safer "Bà ngoại thương câu chuyện" (already suggested in spec 35 §25 #6). en already says "Aunt Lan".
7. **Step labels vs card titles differ** ("Tự tìm & chọn ảnh" vs "Tự động tìm, bạn chỉ chọn và lưu"; "Album cả nhà" vs "Album riêng, cả nhà cùng tương tác") — intentional short / long forms; both kept as separate keys.
8. **Step strip not interactive** in Figma; whether it links to the cards or scroll-spies is not designed — keep static.
9. **Card 4 title wraps** to two lines at 352 px, making row 2 25 px taller than its siblings' content; Figma stretches all three (`align-self:stretch`) — implement the same.
10. **Kết title / sub `nowrap`** — on narrow viewports they must wrap (mobile follows the V9 home mobile Kết).
11. **Nav order** — "Năm đầu đời" first on every V9 page; the home spec must agree (shared `Chrome.tsx`).
12. **Removed V8 tile copy** — "Không còn lẫn với ảnh chụp màn hình hay hoá đơn…", "Từ những gì bạn đã ghi, app gợi ý thành một câu chuyện nhỏ…", "Có ảnh mới là ông bà được báo và thả tim ngay…" disappear from the site with this change (they were only on this page). Delete the keys or keep them for the home if the V9 home reuses them — check the home spec before deleting.
