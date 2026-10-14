# 28 — Landing v5b home page (Chặng 1 frame, Các chặng tiếp theo, Cách giữ kỷ niệm)

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only, no node modified). Extracted 2026-10-13. Same conventions as `25-landing-v5-home.md` / `22-landing-v4-home.md` / `14-landing-v3-home.md`: token names from `07-foundations-components-motion.md` / `packages/design-tokens/dist/tokens.css`, non-token values marked **(raw)**, every visible string copied **verbatim from `get_design_context`**. Layer names are stale: the FAQ items are still named "Có cần ghi đủ mỗi ngày không?" etc., and the Lớn lên band layers still read "2026 / Ngày con chào đời" in older dumps.

> File number: `26-feedback-rating.md` and `27-auto-save.md` exist, so this doc takes **28**. It continues the landing series 14 → 22 → 25 → 28 and **supersedes 25 for the home page**. Section 25 §3 (watch faces), §7 (watch copy keys) and §8–§9 (watch parity and claims) still apply unchanged.

- Desktop frame `475:3726` "Landing v5 · Desktop" — **same node as yesterday, redesigned in place**: 1440 × 8082.2 → **1440 × 9250**. **Desktop only, no mobile frame.** §8 is a mobile *proposal*.
- What changed, in one line: the first-year content (Năm đầu đời bento, Tiện ích, Theo cách của bạn, Apple Watch) is now grouped inside **one mint framed block "Chặng 1 · Năm đầu đời"**, which ends with a **"Xem đầy đủ năm đầu đời" CTA card**; **Sức khoẻ, the family strip, the trust chips, the next-chapters list, the "more" button and the "Gia đình & chia sẻ" card are gone**. There is a **new "Các chặng tiếp theo" section** (4-step path and 3 stage cards) and a **new "Cách giữ kỷ niệm" grid** (6 memory products) under the Lớn lên band. The nav changes to **"Hành trình · Năm đầu đời · Apple Watch · Các chặng · Kỷ niệm · Hỏi đáp"**.
- As before: no prototype links, no motion, no hover/focus states, no tablet frame. Light page, static state. Page background `cloud` #F6FCFB.

Screenshots (not committed, 1:1 at 1440 wide, in `scratchpad/v5b/`): `full-thumb.png` (250 × 1600 thumbnail of the whole frame), `full/v5b-full.png` (1440 × 9250), `d-nav.png`, `d-hero.png`, `d-chang1.png` (whole framed block, 1440 × 3382), `d-chang1-head-bento.png`, `d-tien-ich.png`, `d-theo-cach.png`, `d-watch-in-frame.png`, `d-chi-tiet.png`, `d-cac-chang.png` (1440 × 1026), `d-lon-len.png` (1440 × 1766), `d-lon-len-band.png`, `d-ky-niem.png`, `d-hoi-dap.png` (1440 × 964).

Method: yesterday's metadata dump (`scratchpad/v5/v5.xml`) and today's (`v5b.xml`) were parsed as XML, normalised (ids stripped, coords rounded) and diffed per subtree. Then today's frame was rendered 1:1 (`get_screenshot`, 1440 × 9250) and **pixel-diffed per region against yesterday's 1:1 render** (`scratchpad/v5/full/v5-full.png`, threshold 24/255, background pixels excluded where the background colour changed). Today's render has a different sub-pixel origin, so unchanged text shows anti-aliasing noise (≤ ~1 % of a region's pixels, scattered); a real change shows as a dense block (e.g. bento tile 1: 86 k px). `get_design_context` read in full for Nav, Hero copy, the whole framed block `524:4030` (100 KB, saved), Tiện ích `516:5093`, Theo cách `475:4332`, CTA chi tiết `520:3980`, Các chặng `516:57063`, Band `475:4409`, Cách giữ kỷ niệm `517:56217`, Hỏi đáp `475:4453`. `download_assets` on `524:4031`, `516:57089`, `475:4409`, `517:56217`: every raster is an **existing** repo file (§0.6).

---

## 0. Global

### 0.1 Section order

| # | Section | Node | h (y) | Yesterday | Status | Id (today → proposed) |
|---|---|---|---|---|---|---|
| 1 | Nav | 475:3727 | 87 (0) | 87 | **changed** — links (§2) | — |
| 2 | Hero | 475:3740 | **668** (87) | 644 | copy and art identical; **bottom padding 24 → 48** | `#gioi-thieu` |
| 3 | Hành trình | 475:3812 | 806 (755) | 806 | identical | `#hanh-trinh` |
| 4 | **Chặng 1 · Năm đầu đời** (framed) | **524:4030** | **3382** (1561) | Năm đầu đời 1678 + Sức khoẻ 680 + Tiện ích 816 + Trên cổ tay 754 + Theo cách 620 | **regrouped / changed** (§3) | `#nam-dau-doi` (on the wrapper) |
| 5 | **Các chặng tiếp theo** | **516:57063** | **1026** (4943) | — | **new** (§4) | **`#cac-chang`** |
| 6 | Lớn lên cùng con | 475:4408 | **1766** (5969) | 466 | band **changed** + **new "Cách giữ kỷ niệm"** (§5) | `#lon-len` + **`#ky-niem`** on 517:56217 |
| 7 | CTA | 475:4431 | 367 (7735) | 367 | identical | `#tai-app` |
| 8 | Hỏi đáp | 475:4453 | **964** (8102) | 980 | texts identical, **padding 48/112 → 64/80** (§6) | `#hoi-dap` |
| 9 | Footer | 475:4493 | 184.2 (9066) | 184.2 | identical | — |

**Removed from the home page** (no node any more): Sức khoẻ `475:4103` (`Health.tsx`, `#suc-khoe`), the family strip "Cả nhà cùng chăm — ai cũng có chỗ bên con" + trust chips (`475:4034`, `#gia-dinh`), "Những chặng tiếp theo" list (`475:4076`), the outline "Xem chi tiết năm đầu đời" button (`475:4100`, replaced by the CTA card §3.6), the Tiện ích eyebrow + centred H2/lead, and the Tiện ích card 3 "Gia đình & chia sẻ".

Vertical rhythm: Hero (48 bottom) → Hành trình (64 / 64) → Chặng 1 wrapper `padding: 16px 48px 24px` → Các chặng `64 / 80` → Lớn lên `80 / 80` → CTA (40 / 40, unchanged) → Hỏi đáp `64 / 80` → Footer.

### 0.2 Text styles
No new font size. Re-used: eyebrow SemiBold 13; H2 Bold 44 / 1.18; lead Medium 18 / 1.55; card title Bold 20 / 22 / 28; body Medium 15 / 16 / 17 (1.5–1.55). **New uses**: H3-sized Bold **24** / normal (Tiện ích heading), Bold **32** / 1.18 (Theo cách title inside the frame), Bold **36** / 1.18 (CTA chi tiết), Bold **96** / normal (stage card number).

### 0.3 Colours (all tokens unless noted)
`mint-soft` #E6F7F5 (frame fill, eyebrows), `mint` #2CBFB3 (frame and CTA-card borders, button halo), `mint-deep` #087F7B (path node 1, CTA button, book cover, voice play), `surface`, `surface-2` #EEF6F5 (placeholders, format chips), `control-border` #7E959A (path connectors, dashed placeholder border, outline links), `separator`, `sunshine` #FFD166 ("Sắp ra mắt" badge), `card-sun` #FFD166 (book card), `sunshine-soft`, `peach-soft`, `care-sleep-soft`, `care-bottle-soft`, `care-growth-soft`, the matching `*-ink` text colours, `care-growth-accent` #E8894A (selected milestone, decorative stars). Raw: dark cards #163D44 (≈ `ink`, use `var(--ink)` as before), white 10 % / 45 % / 72 % / 85 % on the dark band, video scrim `linear-gradient(transparent → rgba(0,0,0,.6))`, progress track white 40 %.

### 0.4 Shadows
`shadow-card` everywhere (`0 1 2 #173D440F, 0 8 24 #173D4414`): Theo cách white card, CTA button, stage cards, memory cards, every floating pill / mock card in the memory illustrations. Figma prints it either as `shadow-[…]` or `drop-shadow(0 8 12 / 0 1 1)` — same style. **None** on the frame, the Tiện ích cards, the dark cards.

### 0.5 Icons (app set `apps/mobile/assets/icons/`, stroke 1.8 at 24)
New uses: arrow-right (play glyph, links), camera, speaker, star, check, **upload**, journal, **back**, memories, lock, bookmark, grid.

**Missing from the landing `Icon` map (`components/primitives.tsx`): `speaker`, `upload`, `back`, `camera`** — all four exist in `apps/mobile/assets/icons/` → four more `?raw` imports (`camera` is only needed if the placeholder slots ship as placeholders, or for the "Tạo video chuyển cảnh" / "Video MP4" chips — it is used there too, so add it). Everything else is mapped. (`bell` from 25 §0.5 is still optional.)

Icon colours in the memory mocks (from the exported SVGs): card 1 play + speaker `care-sleep-ink`, star `care-growth-ink`; card 2 decorative stars `care-growth-accent`, option stars `care-growth-ink`, selected check white, upload `mint-text`; card 3 check `mint-text`; card 4 back / arrow `ink`, camera + grid `care-bottle-ink`; card 5 play white, lock `mint-text`; card 6 bookmark + upload `mint-text`. Every format-chip icon is `ink`. CTA button arrow `mint-text` on a white circle; stage links arrow `ink`; band placeholder camera white; stage placeholder camera `ink-muted`.

### 0.6 Assets
`download_assets` on every new/changed block returns only files the repo already has (byte-identical, `cmp`):

| Figma raster | Repo file | Where on the page |
|---|---|---|
| `0d3f8` (Peach) | `apps/landing/src/assets/figma/baby-0d3f8.jpg` (220²) | CTA chi tiết photo 1, memory card 1 video frame (+ unchanged hero / Hành trình / bento uses) |
| `61240` (Mint) | `baby-61240.jpg` (220²) | CTA chi tiết photo 2, band "1 tuổi", card 2 thiệp, card 6 page |
| `4470d` (Rose) | `baby-4470d.jpg` (220²) | **stage card 2**, card 4 right half, card 6 page |
| `4222e` (Sky), `22456` (Sun), `ae95e` (Leaf), `1025f` (Lilac), `5d2ff` (Sand) | `baby-4222e.jpg`, `baby-22456.jpg`, `baby-ae95e.jpg`, `baby-1025f.jpg`, `baby-5d2ff.jpg` | card 3 media, card 6 pages, card 4 left half, card 6 cover |
| `20689` (1536 × 1024 PNG) | = app first-aid art `quan-bang`; landing uses `first-aid-bandage.webp` (1200 × 800) | Tiện ích card 1 |
| 384 × 256 PNG (second fill in `524:4031`) | low-res copy of the same first-aid art | not needed |

**No file added to `apps/landing/src/assets/figma/`** — nothing new exists in Figma; the four new slots are drawn placeholders (§7). Every `Illustration/Photo` is the 220 × 220 library JPEG; several new slots show it much larger (stage card 2 at 400 × 400, video frame at 316², CTA photos at 210²) → **soft at 1×, blurry at 2×** (§7).

---

## 1. Unchanged (verified)

- **Hero copy** (get_design_context, verbatim, = `home.hero` in `vi.ts`): eyebrow **"Child Life · Hành trình lớn lên"**, H1 **"Cùng con lớn lên,"** / **"đồng hành từng bước."**, lead **"Hệ sinh thái giúp cha mẹ chăm sóc, thấu hiểu và đồng hành cùng con — từ những ngày đầu đời đến khi trưởng thành."**, promises **"Chăm sóc con mỗi ngày, cả nhà cùng phối hợp"** · **"Thấu hiểu con qua từng giai đoạn lớn lên"** · **"Đồng hành và lưu giữ hành trình của con"**, button **"Xem hành trình của con"**. Metadata identical, pixels noise-only. Only change: section height 644 → 668 (Copy y 102 and Illustration y 40 unchanged → **bottom padding 24 → 48**).
- **Hành trình, CTA, Footer**: metadata identical, pixel diff noise-only (CTA crops compared visually as well).
- **Năm đầu đời Head + Bento** (inside the frame now): metadata identical; pixels identical except **bento tile 1** (§3.2).
- **Apple Watch section content** (`475:4503` copy + three watches): identical (pixel diff noise-only) — only its container changed (§3.5). `25` §3 still specifies the content.
- **Hỏi đáp texts** — see §6.

---

## 2. Nav (475:3727, 1440 × 87) — changed

Geometry/styles as v5 (`padding: 22px 96px`, links `gap: 36px` Medium 15 / normal `ink-muted`, nowrap, 40 spacer, CTA pill `ink` / `surface` SemiBold 15 `padding: 12px 22px` **"Tải miễn phí"**). Links row 633 → **646** wide, starts at x **525**; flex spacer 266 → 253. The hidden duplicate "Hỏi đáp" layer is gone.

Links, verbatim, in order: **"Hành trình" · "Năm đầu đời" · "Apple Watch" · "Các chặng" · "Kỷ niệm" · "Hỏi đáp"**.
- Removed: "Sức khoẻ" (`nav.links.health`), "Tiện ích" (`nav.links.utilities`).
- Moved: "Apple Watch" now third.
- Added: **"Các chặng"** (81 px) → `nav.links.stages`; **"Kỷ niệm"** (58 px) → `nav.links.memories`.

Targets and stage pages: §9. Width at 1120–1230 px: still overflows (176 + 646 + 40 + ≈ 215 ≈ 1077 > ≈ 971) — same fix options as `25` §5.

---

## 3. Chặng 1 · Năm đầu đời (524:4030, 1440 × 3382) — regrouped

```
524:4030 wrapper   column; padding: 16px 48px 24px                      (full width, transparent)
└─ 524:4031 "Khung chặng 1"  1344 × 3342
     background: mint-soft; border: 2px solid mint; border-radius: 48px; overflow: hidden;
     column; gap: 24px; padding-bottom: 48px  (no top/side padding — children carry their own)
     ├─ 475:3913 "Năm đầu đời"   column; align-items:center; gap: 40px; padding: 64px 48px 24px   (1340 × 2168)
     │    ├─ Head 475:3914          (unchanged, §3.1)
     │    ├─ Bento 475:3919         1248 wide (§3.2)
     │    ├─ Tiện ích 516:5093      1248 wide (§3.3)
     │    └─ Theo cách 475:4332     width 100 % = 1244 (§3.4)
     ├─ 524:4032 "Apple Watch · khung"   column; padding: 0 48px   → 475:4503 dark card (§3.5)
     └─ 520:3980 "Chi tiết năm đầu đời"  column; padding: 0 48px   → 520:3981 CTA card (§3.6)
```
The frame is 1344 wide (same 48-px gutter as the Lớn lên band); its content column is 1248 (Bento, Tiện ích) or 1244 (the three cards: frame 1340 inner − 2 × 48). Implementation: `<section id="nam-dau-doi" class="first-year">` → `.stage-frame` (`margin-inline: 48px` at 1440, i.e. a "wide container" of 1344, `border: 2px solid var(--mint); border-radius: 48px; background: var(--mint-soft); overflow: hidden`). Note the frame clips (overflow hidden) — the Theo cách panel overhang (§3.4) stays inside it.

### 3.1 Head 475:3914 — unchanged
Eyebrow **"Chặng 1 · Năm đầu đời"** (`mint-soft` / `mint-text`), H2 Bold 44 / 1.18 centred 760 **"Năm đầu đời của con, nhẹ nhàng hơn cho cả nhà."**, lead Medium 18 / 1.55 centred 640 **"Chăm con mỗi ngày, hiểu con từng tuần và giữ lại những lần đầu tiên — tất cả trong một ứng dụng."**
**Side effect:** the eyebrow pill is `mint-soft` on the now `mint-soft` frame → the pill is **invisible** (the render shows bare mint text). Same for every `mint-soft` element directly on the frame. Design call: keep (bare label) or give on-frame eyebrows `surface` (recommended: `surface` pill, matches the white tiles).

### 3.2 Bento 475:3919 — one change
Geometry, copy and tiles as `12` §1 / `14` §4, except **tile 1 "Ghi trong một chạm" 475:3920: background `mint-soft` → `surface`** (it would vanish on the mint frame otherwise). Its icon box (`surface`, `padding: 8px; radius 12`) and its two chips (`surface`, "Bú bình · 120 ml", "Đang ngủ 1:27") were **not** recoloured → **white-on-white, invisible** in the render (only the plus glyph and chip text show). Recommend `mint-soft` for that icon box and those chips (flagged §11).

### 3.3 Tiện ích cho ba mẹ 516:5093 (1248 × 520) — changed
`column; gap: 24px; align-items: flex-start` — **left-aligned heading, no eyebrow, no H2**:
1. `h` 516:5096 `column; gap: 6px`, nowrap:
   - Bold **24** / normal `ink`: **"Tiện ích cho ba mẹ"** (→ `<h3>`)
   - Medium **16** / normal `ink-muted`: **"Những thứ nhỏ giúp ngày làm cha mẹ nhẹ hơn — có sẵn trong tab Tiện ích."**
2. Cards 516:5097 `display:flex; gap: 20px;` **two** cards `flex: 1` (**614** × 440). Card styles exactly `22` §4.2 (radius 28, padding 28, gap 12, icon box `surface` p 8 r 12 + 20 icon, title Bold 22, body Medium 15 / 1.5 340 wide, spacer, visual 340 wide):
   | Card | Node | Bg | Icon | Title | Body | Visual |
   |---|---|---|---|---|---|---|
   | 1 | 516:5098 | `peach-soft` | alert (`ink`) | **"Sơ cứu trẻ em"** | **"25 tình huống thường gặp, từng bước có hình minh hoạ, đọc to hướng dẫn. Dùng được cả khi không có mạng."** | first-aid image 340 × 200 r 20 (`22` §4.3) |
   | 2 | 516:5105 | `care-growth-soft` | grid (`care-growth-ink`) | **"Sổ chi tiêu chung cho bé"** | **"Mọi khoản chi cho con ở một chỗ. Ba và mẹ cùng ghi, cùng xem một sổ như nhau — biết con cần gì, cả nhà đã lo đến đâu."** | spending card (`22` §4.4, every string identical: "Chi cho Teddy · tháng này", "4.215.000 ₫", "Mẹ ghi" "2.320.000 ₫", "Ba ghi" "1.895.000 ₫", "M", "B", "Ba và mẹ cùng xem như nhau") |
   Contents keep their 340-px width, so each 614-px card has ~218 px of empty right side (as designed).

### 3.4 Theo cách của bạn 475:4332 (1244 × 540) — changed container + title size
Now a **white card**: `background: surface; box-shadow: shadow-card; border-radius: 32px; padding: 40px 48px;` → Row `display:flex; gap: 96px; align-items:center;` (1148 wide).
- Copy (`column; gap: 36px`): Head (`gap: 16px`): eyebrow `sunshine-soft` / `ink` **"Theo cách của bạn"**; title Bold **32** / 1.18 (was 44) `ink`, 520 wide, 2 lines **"Ứng dụng của nhà bạn, theo nhịp của nhà bạn."**; lead Medium 18 / 1.55 480 wide **"Chỉ hiện những gì bạn cần. Bớt đi những gì bạn không dùng."**; bullets unchanged (`CompactBullets`, "Bật, tắt và sắp xếp màn hình Hôm nay" / "Bú bình hay bú mẹ, có hút sữa hay không — tuỳ nhà bạn.", "Chế độ đêm" / "Màn hình tối, chữ to, ghi nhanh lúc 3 giờ sáng.", "Danh mục chi tiêu riêng" / "Thêm, sửa, ẩn danh mục cho đúng cách nhà bạn chi.").
- Panel 475:4359 unchanged (600 × 460, `sunshine-soft`, r 40; mock "Tuỳ chỉnh Hôm nay" etc. = `22` §5.2).
- **Design bug:** 520 + 96 + 600 = 1216 > 1148 → the panel **overhangs the card's right edge by 20 px** (visible in `d-theo-cach.png`). Recommend: copy `flex: 1` (452) with the panel fixed 600, or keep 520 copy and shrink the gap to 28. Do not reproduce the overhang.

### 3.5 Apple Watch 524:4032 → 475:4503 (1244 × 674) — container changed
No longer a full-bleed band: a **rounded dark card inside the frame**: `background: #163D44` (raw ≈ `ink`); `border-radius: 40px; overflow: hidden; display:flex; gap: 80px; align-items:center; padding: 56px 48px 56px 64px;` → Copy `flex: 1` (**492**, was 608) + Watches 560 × 560 (composition unchanged, `25` §3.2). All copy unchanged (`25` §3.1; the 460-wide lead and the nowrap bullet lines fit in 492). Keep `id="apple-watch"` on this card.

### 3.6 CTA chi tiết 520:3980 → 520:3981 (1244 × 400) — NEW (replaces the outline "more" button)
`background: surface; border: 2px solid mint; border-radius: 40px; padding: 48px 56px; display:flex; gap: 48px; align-items:center;`
- **Copy** 520:3982 `flex: 1; column; gap: 18px`:
  - eyebrow `mint-soft` / `mint-text` **"Chặng 1 · 0–12 tháng"**
  - Bold **36** / 1.18 `ink`, 560 wide: **"Xem đầy đủ năm đầu đời"** (→ `<h3>`)
  - Medium **17** / 1.55 `ink-muted`, 540 wide (2 lines): **"Từng phần chi tiết: ghi nhanh, nhắc nhở, lịch tiêm, ăn dặm, sơ cứu, chế độ đêm và quyền xem của cả nhà."**
- **Visual "Nút nổi bật"** 520:4015, 420 × 300, `position: relative` (absolute children, paint order):
  | Layer | Box | Content |
  |---|---|---|
  | Photo 1 | bbox (−1.95, 10, 191.0 × 226.6), rotate **+6°** | window 170 × 210, `border-radius: 24px`, `surface-2`; Peach `baby-0d3f8.jpg` 210² at left −20 |
  | Photo 2 | bbox (210, −14.82, 187.7 × 224.0), rotate **−5°** | window 170 × 210, r 24; Mint `baby-61240.jpg` 210² at left −20 |
  | Halo | (30, 196) 360 × 96, `mint`, r 999 | a second `mint` pill 332 × 76 at (44, 206) is the same colour → invisible, ignore |
  | **Button** `<a>` | (49.5, 212) | `mint-deep`, `shadow-card`, `padding: 18px 28px; gap: 12px; border-radius: 999px;` Bold **18** `on-mint-deep` **"Xem chi tiết năm đầu đời"** + white circle (`surface`, `padding: 6px`) with arrow-right 16 `mint-text` |
  The halo is centred on the button (button ≈ 321 × 64; halo = button + 19.5 / 16 px) → implement as a wrapper pill `padding: 16px 19.5px; background: var(--mint)` around the real `<a>`, not two rectangles. The button overlaps the photos' lower part (as drawn). Photos decorative (`alt=""`).
- Target: the Chặng 1 page (`pathOf('stage1', locale)`), same as today's `firstYear.more` button; reuse `firstYear.more` for the button label (identical string).

---

## 4. Các chặng tiếp theo (516:57063, 1440 × 1026) — NEW

`background: cloud` (= page); `display:flex; flex-direction:column; align-items:center; gap: 48px; padding: 64px 96px 80px;`

### 4.1 Head 516:57064 (820 wide, centred, `gap: 16px`)
- Eyebrow `mint-soft` / `mint-text`: **"Các chặng tiếp theo"**
- H2 Bold 44 / 1.18 `ink`, centred, 820 wide, one line: **"Con lớn, Child Life lớn theo con."**
- Lead Medium 18 / 1.55 `ink-muted`, centred, 640 wide (2 lines): **"Sau năm đầu đời, mỗi chặng mang đến cách chăm mới, điều mới cần để ý và những kỷ niệm mới. Các chặng này đang được chuẩn bị."**

### 4.2 "Đường chặng" 516:57069 (785 × 39) — 4-step path
`display:flex; gap: 12px; align-items:center;` node · connector · node · connector · node · connector · node. Connector: 48 × 2 `control-border`.
- Node: `border-radius: 999px; padding: 8px 14px 8px 8px; display:flex; gap: 8px; align-items:center;` number chip `padding: 3px 9px; border-radius: 999px;` Bold 12; label SemiBold 14, nowrap.
  | Node | Fill | Number chip | Label |
  |---|---|---|---|
  | n1 | `mint-deep` | `surface` / `mint-text` **"1"** | `on-mint-deep` **"Năm đầu đời · đang có"** |
  | n2 | `surface` + 1 px `separator` | `surface-2` / `ink-muted` **"2"** | `ink` **"1–3 tuổi"** |
  | n3 | same | **"3"** | **"3–6 tuổi"** |
  | n4 | same | **"4"** | **"6–12 tuổi"** |
- Static in Figma. Recommendation: an ordered list (`<ol>`), n1 links to `#nam-dau-doi`, n2–n4 to the stage pages (or leave static; the cards below link anyway).

### 4.3 "Thẻ chặng" 516:57089 — three cards
Row `display:flex; gap: 24px; align-items:flex-start;` → 3 cards `flex: 1` (**400** × 579): `background: surface; border-radius: 32px; box-shadow: shadow-card; overflow: hidden; display:flex; flex-direction:column;`
1. **"Minh hoạ"** 400 × 260, `overflow: hidden`, tinted background, containing:
   - image slot 400 × 260 (§7: card 2 photo; cards 3–4 **placeholders**);
   - big number Bold **96** / normal at (24, 4), nowrap;
   - badge at (285, 24) = **right 24**: `background: sunshine; padding: 5px 12px; border-radius: 999px;` Bold 12 `ink` **"Sắp ra mắt"**.
2. **body** `flex: 1; column; gap: 14px; padding: 24px 28px 28px;`
   - label Bold 14 / normal, stage ink, nowrap
   - title Bold **28** / 1.2 `ink`
   - lead Medium 16 / 1.55 `ink-muted`
   - chips `flex-wrap; gap: 8px;` chip `padding: 6px 12px; border-radius: 999px;` SemiBold 13, stage soft bg + stage ink
   - spacer `flex: 1`
   - link `border: 1px solid control-border; padding: 12px 18px; border-radius: 999px; gap: 8px;` SemiBold 15 `ink` + arrow-right 16 `ink`

| Card | Node | Minh hoạ bg | Image | Number | Label (colour) | Title | Lead | Chips (bg / text) | Link |
|---|---|---|---|---|---|---|---|---|---|
| 2 | 516:57090 | `sunshine-soft` | Rose `baby-4470d.jpg`, 400² at top −70 | **"2"** white, opacity **0.85** | **"Chặng 2 · 1–3 tuổi"** (`care-growth-ink`) | **"Con tập khám phá"** | **"Cùng con chập chững, bập bẹ những từ đầu tiên và tập những thói quen nhỏ."** | `sunshine-soft` / `care-growth-ink`: **"Nếp sinh hoạt"**, **"Chơi & vận động"**, **"Từ đầu tiên"** | **"Xem trước chặng 2"** |
| 3 | 516:57129 | `peach-soft` | placeholder 519:4780 | **"3"** `care-bottle-ink`, opacity **0.18** | **"Chặng 3 · 3–6 tuổi"** (`care-bottle-ink`) | **"Tò mò và lớn khôn"** | **"Cùng con chơi, đọc, vẽ và trả lời những câu hỏi “vì sao” không ngừng."** | `peach-soft` / `care-bottle-ink`: **"Học qua chơi"**, **"Cảm xúc"**, **"Tác phẩm của con"** | **"Xem trước chặng 3"** |
| 4 | 516:57169 | `care-sleep-soft` | placeholder 519:4785 | **"4"** `care-sleep-ink`, opacity **0.18** | **"Chặng 4 · 6–12 tuổi"** (`care-sleep-ink`) | **"Thế giới riêng của con"** | **"Đồng hành nhẹ nhàng khi con tự lập, có sở thích và những ước mơ riêng."** | `care-sleep-soft` / `care-sleep-ink`: **"Sở thích"**, **"Tự lập"**, **"Nhìn lại hành trình"** | **"Xem trước chặng 4"** |

- Titles, leads and chips are **identical to `journey.stages[1..3]`** (`name`, `lead`, `chips`) and the ages to `stages[i].ages` → reuse them; only "Sắp ra mắt", "Chặng {n} · {ages}" (reuse `journey.number`), "Xem trước chặng {n}", the head and the path labels are new strings.
- Placeholder (cards 3–4): `background: surface-2; border: 2px dashed control-border;` column centred, gap 8: camera 24 `ink-muted` + SemiBold 13 `ink-muted` **"Ảnh thật · bé 3–6 tuổi"** / **"Ảnh thật · bé 6–12 tuổi"**. These are **design notes, not content** — do not ship the text; see §7.
- Number styling: card 2 (on a photo) white 85 %; cards 3–4 (on the placeholder) tinted 18 %. Once real photos go in, **use the card-2 style for all three** (white 85 %, maybe a subtle text-shadow).
- Link targets: `pathOf(stageIds[i])` (the existing stage pages).
- **Height:** cards are fixed 579; cards 2–3 have chips on 2 lines and their link ends at 306 of a 319 body → bottom padding shrinks to 13 px; card 4 (1-line chips) keeps 28 → the three links do not line up (291 vs 306). Implement `align-items: stretch` + `margin-top: auto` on the link + a real 28 px bottom padding (cards grow to ≈ 594) so links align.
- **Tint conflict:** Hành trình (`stageLooks` in `Chapters.tsx`, Figma `475:3818`) uses stage 3 = `sleep`, stage 4 = `peach`; here stage 3 = peach bg with **bottle (blue) ink**, stage 4 = sleep. Ask design which mapping is canonical; card 3's peach + blue mix looks accidental (likely `care-bottle-soft` intended).

---

## 5. Lớn lên cùng con (475:4408, 1440 × 1766) — changed + NEW block

Section `display:flex; flex-direction:column; gap: 64px; padding: 80px 48px;` (from metadata: band y 80, next block y 562, bottom 80; was `padding: 24px 48px` with one child).

### 5.1 Band 475:4409 (1344 × 418) — changed copy and photos
Styles unchanged (`14` §5: #163D44 raw, r 48, p 64, gap 48; copy `flex: 1` now **644**; eyebrow white 12 % "Một hồ sơ, lớn lên cùng con"; H2 Bold 40 / 1.18 white **"Những gì bạn lưu hôm nay, con sẽ còn xem lại khi lớn."** unchanged).
- Body (changed), Medium 17 / 1.55 white 72 %: **"Từ sinh nhật đầu tiên đến ngày con vào lớp 1, rồi những ước mơ tuổi 12 — hành trình của con nằm trọn ở một nơi, không mất đi khi con lớn."**
- Years (`gap: 14px; align-items:flex-end`, now 524 wide — the columns hug the longer captions: 159 / 165 / 172):

  | Slot (r 20) | Image | Year — Bold 22 white | Caption — Medium 13 white 72 %, nowrap |
  |---|---|---|---|
  | 150 × 170 | **Mint** `baby-61240.jpg` (170² at left −10) — was Peach | **"1 tuổi"** | **"2027 · Sinh nhật đầu tiên"** |
  | 150 × 200 | **placeholder** 519:4797 | **"6 tuổi"** | **"2032 · Ngày đầu vào lớp 1"** |
  | 150 × 230 | **placeholder** 519:4802 | **"12 tuổi"** | **"2038 · Những ước mơ riêng"** |

  Dark placeholder: `background: rgba(255,255,255,.1); border: 2px dashed rgba(255,255,255,.45);` camera 24 white + SemiBold 13 white 85 % centred 126 wide **"Ảnh thật · 6 tuổi"** / **"Ảnh thật · 12 tuổi"** (design notes, not content).
- `GrowUp.tsx`: `years[].year` becomes an age label ("1 tuổi") and `caption` "{year} · {event}"; photo tones `['mint', …]`.

### 5.2 Cách giữ kỷ niệm 517:56217 (1344 × 1124) — NEW
`column; align-items:center; gap: 40px;` — 1344 wide (band width, **not** the 1248 container).

**Head** 517:56218 (`gap: 16px`, centred): eyebrow `mint-soft` / `mint-text` **"Kỷ niệm của con"**; H2 Bold 44 / 1.18 760 wide one line **"Không chỉ để lưu, mà để kể lại."**; lead Medium 18 / 1.55 600 wide (2 lines) **"Video, thiệp, nhật ký, lời nhắn và cả một cuốn sách — tạo từ chính ảnh và câu chữ của gia đình bạn."**

**Grid "Lưới"** 522:3981: two rows `gap: 24px`, each `display:flex; gap: 24px;` → 6 cards `flex: 1` (**432** × 446): `background: surface; border-radius: 28px; box-shadow: shadow-card; overflow: hidden; column;`
- **Illustration "Minh hoạ chức năng"** 432 × 280, tinted bg, absolute mock (decorative → `aria-hidden`, build in HTML/CSS: all strings translate).
- **body** `flex: 1; column; gap: 10px; padding: 22px 26px 26px;` → `h` (`column; gap: 10px`): format chip `surface-2`, `padding: 5px 10px; r 999; gap: 6px;` icon 13 `ink` + SemiBold 12 `ink`; title Bold 20 / normal `ink` nowrap; then description Medium 15 / 1.55 `ink-muted` (2 lines).

| # | Card | Illus bg | Format chip (icon) | Title | Description |
|---|---|---|---|---|---|
| 1 | 522:4216 | `care-sleep-soft` | camera **"Video MP4"** | **"Câu chuyện kỷ niệm"** | **"Video kỷ niệm theo mẫu có sẵn, kết hợp ảnh, chữ, nhạc và các cột mốc của con."** |
| 2 | 522:4227 | `sunshine-soft` | grid **"Ảnh PNG/JPG"** | **"Phép màu cột mốc"** | **"Thiệp cột mốc thật đẹp: tròn 1 tháng, 100 ngày, lần đầu biết lẫy… lưu ảnh hoặc gửi cho cả nhà."** |
| 3 | 522:4240 | `peach-soft` | journal **"Nhật ký"** | **"Khoảnh khắc nhỏ"** | **"Một bài viết ngắn kèm ảnh hoặc video, lưu thẳng vào dòng thời gian kỷ niệm của con."** |
| 4 | 522:4252 | `care-bottle-soft` | memories **"Ảnh / Video"** | **"Ngày ấy và bây giờ"** | **"So sánh ảnh của con ở hai thời điểm, có thể tạo video chuyển cảnh từ ngày ấy sang bây giờ."** |
| 5 | 522:4263 | `mint-soft` | speaker **"Giọng nói + chữ"** | **"Lời yêu thương của gia đình"** | **"Lời nhắn bằng giọng nói hoặc chữ từ ba mẹ, ông bà — giữ lại để con nghe khi lớn."** |
| 6 | 522:4275 | `card-sun` (#FFD166) | bookmark **"PDF / Sách ảnh in"** | **"Sách năm đầu đời"** | **"Cuốn sách tổng hợp hành trình 12 tháng đầu đời của con — tải PDF hoặc đặt in thành sách ảnh."** |

**Shared "pill"** (cards 1, 2, 4, 5, 6): `background: surface; box-shadow: shadow-card; padding: 6px 10px; border-radius: 999px; gap: 6px;` icon 14 (12 for lock) + SemiBold 12 `ink`.

**Mock 1 — video** (positions inside the 432 × 280 illustration):
- Player 522:3983 at (58, 28) 316 × 196, `background: white; border-radius: 18px; overflow: hidden; shadow-card`: photo Peach 316² at top −60; scrim 316 × 96 at top 100 `linear-gradient(to bottom, rgba(0,0,0,0), rgba(0,0,0,.6))`; template chip (12, 12) `surface`, `padding: 5px 10px; r 999` Bold 11 `ink` **"Mẫu · Năm đầu đời"**; play button (137, 62) white circle `padding: 12px` + arrow-right 18 `care-sleep-ink`; Bold 15 white at (14, 136) **"Lần đầu biết lẫy · 4 tháng"**; SemiBold 11 white at (241, 156) **"0:16 / 0:45"**; progress at (14, 174): track 288 × 4 white 40 % r 2, fill 110 × 4 white.
- Pills at (58, 236) speaker (`care-sleep-ink`) **"Nhạc: Ru con nhẹ nhàng"**; at (262, 236) star (`care-growth-ink`) **"3 cột mốc"**.

**Mock 2 — milestone card**:
- Card "Thiệp" rotated **+3°**, bbox (31.33, 22, 212.4 × 252.1): `surface; shadow-card; border-radius: 18px; padding: 12px 12px 16px; column; align-items:center; gap: 8px;` photo 176 × 150 r 12 (Mint, 176² at top −13); Bold **26** `care-growth-ink` **"100 ngày"**; Medium 12 `ink-muted` **"Teddy · 18.01.2027"**.
- Decorative stars 16 `care-growth-accent` at (236, 26), (400, 40), (400, 250).
- Template list (262, 66) `column; gap: 8px;` options `padding: 7px 12px; r 999; gap: 6px;` icon 12 + SemiBold 12: `surface` star **"1 tháng"**; **selected** `care-growth-accent` bg, white check, white text **"100 ngày"**; `surface` star **"Lần đầu biết lẫy"**.
- Pill (262, 200) upload (`mint-text`) **"Lưu ảnh PNG"**.

**Mock 3 — journal post** 522:4046 at (48, 22), 336 wide: `surface; shadow-card; border-radius: 18px; padding: 14px 16px; column; gap: 10px;`
- Header `gap: 8px`: avatar 28 `care-bottle-soft` Bold 12 `care-bottle-ink` **"M"**; Bold 13 `ink` **"Mẹ"** / Medium 11 `ink-muted` **"12/10 · 21:30"**.
- Medium 13 / 1.45 `ink`: **"Hôm nay con nhìn theo mẹ cả buổi, cười khúc khích khi nghe mẹ hát."**
- Media `gap: 6px`: three 96 × 72 r 10 (Sky, Sun, Leaf; 96² at top −12); the third carries a duration chip at (58, 50) `ink` bg, `padding: 2px 6px; r 6` Bold 10 white **"0:18"**.
- Footer `gap: 6px`: check 12 `mint-text` + SemiBold 11 `mint-text` **"Đã lưu vào dòng thời gian kỷ niệm"**.

**Mock 4 — then / now** 522:4083 at (48, 22) 336 × 196, `white; r 18; overflow hidden; shadow-card`: left half 168 × 196 Lilac (196² at left −14), right half 168 × 196 Rose; white divider 3 × 196 at x 166.5; handle (147, 84) white circle `padding: 8px; gap: 2px; shadow-card` with back 12 + arrow-right 12 (`ink`); labels `surface` chips `padding: 5px 10px` Bold 11 `ink` **"1 tháng"** at (12, 12), **"12 tháng"** at (256, 12). Pills (48, 232) camera (`care-bottle-ink`) **"Tạo video chuyển cảnh"**; (240, 232) grid (`care-bottle-ink`) **"Lưu ảnh ghép"**.

**Mock 5 — voice + text messages**:
- Voice bubble (40, 30): `surface; shadow-card; border-radius: 22px; padding: 10px 14px 10px 10px; gap: 10px; align-items:center;` avatar 36 `care-sleep-soft` Bold 12 `care-sleep-ink` **"B"**; play `mint-deep` circle `padding: 8px` + white arrow-right 14; waveform 22 bars `width: 3px; gap: 3px; border-radius: 2px; background: mint-text`, heights **8 26 12 25 17 22 21 19 23 15 25 11 26 10 25 14 24 18 21 22 17 24**; SemiBold 12 `ink-muted` **"0:32"**.
- SemiBold 11 `ink-muted` at (58, 92): **"Bà nội · lời nhắn giọng nói"**.
- Text bubble (110, 122): `surface; shadow-card; r 22; padding: 12px 16px 12px 12px; gap: 10px; align-items:flex-start;` avatar 36 `care-bottle-soft` Bold 12 `care-bottle-ink` **"Ba"**; column gap 2: Bold 12 `care-bottle-ink` **"Ba"**, SemiBold 13 `ink` 220 wide **"“Con trai của ba, mỗi ngày bên con là một ngày vui.”"**
- Pill (40, 228) lock (`mint-text`) **"Chỉ gia đình nghe được"**.

**Mock 6 — photo book** rotated **+2°**, bbox (39.02, 22, 346.8 × 211.7): `surface; border-radius: 10px; overflow:hidden; shadow-card; display:flex;`
- Cover 170 × 200 `mint-deep`: photo 146 × 120 r 8 at (12, 12) (Sand, 146² at top −13); Bold 16 / 1.2 `on-mint-deep` at (12, 142) **"Năm đầu đời"** / **"của Teddy"** (hard break).
- Page `column; gap: 6px; padding: 12px; height: 200px;`: Bold 12 `ink-muted` **"Tháng 6"**; 2 rows × 2 photos 70 × 62 r 6 (Sky, Rose / Sun, Mint); SemiBold 11 `ink` **"Bữa ăn dặm đầu tiên"**.
- Pills (46, 236) bookmark (`mint-text`) **"PDF · 48 trang"**; (206, 236) upload (`mint-text`) **"Đặt in sách ảnh"**.

Implementation: new `sections/Memories*.tsx`-style component for the home (the stage-1 `Memories.tsx` is a different section — don't overload it); compositions at 432 × 280 via `Fit`/`at()` like the other mocks; reuse `<Photo tone>` for every photo window.

---

## 6. Hỏi đáp (475:4453, 1440 × 964) — padding only

`padding: 64px 96px 80px` (was `48px 96px 112px`). Row, left column and items unchanged. Every text verbatim (get_design_context) and identical to `home.faq.items` + the v5 9th item:
- Left: Bold 36 / 1.2 **"Câu hỏi thường gặp"**; Medium 16 / 1.5 **"Còn điều gì băn khoăn? Cứ nhắn cho chúng tôi nhé."**
- 1 (open) **"Child Life là gì?"** — **"Hệ sinh thái giúp cha mẹ chăm sóc, thấu hiểu và đồng hành cùng con qua từng chặng lớn lên. Ứng dụng hiện tập trung vào năm đầu đời của con."**
- 2 (open) **"Child Life dành cho bé mấy tuổi?"** — **"Từ ngày con chào đời. Năm đầu, app giúp cả nhà chăm con mỗi ngày; những chặng tiếp theo sẽ cùng con lớn lên đến tuổi trưởng thành."**
- 3–9 (closed, no answer in Figma): **"Khi con lớn, ảnh và hồ sơ của con có còn không?"** · **"Có mất phí không?"** · **"Ai được xem ảnh và thông tin của con?"** · **"Nội dung gợi ý trong app do ai soạn?"** · **"Sơ cứu trong app có thay thế bác sĩ không?"** · **"Ai xem được chi tiêu của gia đình?"** · **"Có dùng Child Life trên Apple Watch được không?"**

No FAQ about the new memory products — consider one (e.g. sách in, giá) if they ship (§10).

---

## 7. Image slots — every image on the page

Status: **(a)** raster in Figma (file in repo) · **(b)** placeholder (dashed "Ảnh thật · cần thay" box) · **(c)** vector / HTML. "Lib 220" = the `Illustration/Photo` library JPEG, 220 × 220 (described in Figma as a "privacy-safe placeholder", but it is photographic).

| # | Node | Section | Slot (w × h, radius) | Figma today | Depicts / meant to depict | Action |
|---|---|---|---|---|---|---|
| 1 | 475:3763 | Hero | 540 × 540 landscape, r 48 | (c) `journey-landscape.svg` | sky, sun, hills, road | none |
| 2 | 475:3778/3779 | Hero, road node 1 | 86 × 86 circle | (a) Lib 220 Peach `0d3f8` | parent kissing a newborn | ok (≤ 2× 172) |
| 3 | 475:3803/3804 | Hero float "Lần đầu con cười" | 40 × 40 | (a) Lib 220 (Sun `22456`) | thumbnail | ok |
| 4 | 475:3823/3824 | Hành trình, Chặng 1 card | 112 × 112 circle | (a) Lib 220 Peach | newborn with parent | ok |
| 5 | 475:3985/3986 | Bento "Mốc phát triển" row | 40 × 40, r 10 | (a) Lib 220 Peach | "Mỉm cười đáp lại" | ok |
| 6 | 475:4028–4033 | Bento "Giữ trọn tuổi thơ" fan | 3 × ≈ 96 × 110, r 14, ±4–6° | (a) Lib 220 Peach / Sun / Sky | family photos | ok |
| 7 | 516:5104 | Tiện ích · Sơ cứu | 340 × 200, r 20 | (a) app first-aid art `quan-bang` (→ `first-aid-bandage.webp`) | boy getting a forearm bandaged, ✓ badge | ok |
| 8 | 475:4542 | Apple Watch | 560 × 560 | (c) HTML watch mock | — | none |
| 9 | 520:4016/4017 | CTA chi tiết, photo 1 | 170 × 210, r 24, +6° | (a) Lib 220 Peach at 210² | parent + newborn | **soft** (2× needs 420 × 520); hi-res original or new photo |
| 10 | 520:4023/4024 | CTA chi tiết, photo 2 | 170 × 210, r 24, −5° | (a) Lib 220 Mint at 210² | smiling infant on a white blanket | same |
| 11 | **519:4773/4774** | **Các chặng · Chặng 2** | **400 × 260** (top corners r 32 by the card) | (a) Lib 220 Rose `4470d` shown at **400 × 400** (×1.8, ×3.6 at 2×) | toddler on a play mat with toys, seen from above | **replace / hi-res** — proposal A |
| 12 | **519:4780** | **Các chặng · Chặng 3** | **400 × 260** | **(b) placeholder** "Ảnh thật · bé 3–6 tuổi" | — | **source** — proposal B |
| 13 | **519:4785** | **Các chặng · Chặng 4** | **400 × 260** | **(b) placeholder** "Ảnh thật · bé 6–12 tuổi" | — | **source** — proposal C |
| 14 | 519:4790/4791 | Lớn lên band, "1 tuổi" | 150 × 170, r 20 | (a) Lib 220 Mint | a ~3–4-month-old lying down — **not a first birthday** | **replace** — proposal D |
| 15 | **519:4797** | **Lớn lên band, "6 tuổi"** | **150 × 200**, r 20 | **(b) placeholder** (dark dashed) "Ảnh thật · 6 tuổi" | — | **source** — proposal E |
| 16 | **519:4802** | **Lớn lên band, "12 tuổi"** | **150 × 230**, r 20 | **(b) placeholder** "Ảnh thật · 12 tuổi" | — | **source** — proposal F |
| 17 | 522:3984/3985 | Kỷ niệm · video frame | 316 × 196, r 18 (photo 316² top −60) | (a) Lib 220 Peach at 316² | parent kissing baby | **soft**; hi-res — proposal G |
| 18 | 522:4013/4014 | Kỷ niệm · thiệp "100 ngày" | 176 × 150, r 12 | (a) Lib 220 Mint | smiling infant | ok-ish (2× 352) |
| 19 | 522:4055/4062/4069 | Kỷ niệm · journal media | 3 × 96 × 72, r 10 | (a) Lib 220 Sky / Sun / Leaf | sleeping baby; teddy bear in a basket; adult hand holding a baby hand | ok |
| 20 | 522:4084/4085 | Kỷ niệm · "1 tháng" half | 168 × 196 (photo 196²) | (a) Lib 220 Lilac `1025f` | crying newborn | **mismatch** — proposal H |
| 21 | 522:4091/4092 | Kỷ niệm · "12 tháng" half | 168 × 196 | (a) Lib 220 Rose | toddler with toys (a different child) | **mismatch** — proposal H |
| 22 | 522:4166/4167 | Kỷ niệm · book cover | 146 × 120, r 8 | (a) Lib 220 Sand `5d2ff` | swaddled newborn | ok |
| 23 | 522:4176–4199 | Kỷ niệm · book page | 4 × 70 × 62, r 6 | (a) Lib 220 Sky / Rose / Sun / Mint | assorted | ok |
| — | avatars, initials, watch faces, app cards | — | — | (c) HTML | — | none |

**Proposals for the slots to source** (all: natural daylight, warm and calm, no visible faces of identifiable real families unless model-released, Vietnamese / Southeast-Asian family context, uncluttered, deliver ≥ 2× the slot):
- **A — Chặng 2 (1–3 tuổi), 400 × 260 landscape (deliver ≥ 1200 × 780):** a toddler of ~18 months taking first steps holding an adult's fingers, or squatting on a play mat stacking blocks; subject centre-right (the "2" sits top-left, "Sắp ra mắt" top-right); playful, sunny. Keeping today's toy-mat photo is fine only as a hi-res original.
- **B — Chặng 3 (3–6 tuổi), 400 × 260 landscape:** a 4–5-year-old drawing or painting at a low table, or reading a picture book with a parent and pointing ("vì sao"); curious, bright; subject centre-right.
- **C — Chặng 4 (6–12 tuổi), 400 × 260 landscape:** a ~9-year-old absorbed in a hobby alone (sketchbook, building a model / robot kit, reading on a window seat), a parent softly in the background or absent; independent, calm.
- **D — "1 tuổi · Sinh nhật đầu tiên", 150 × 170 portrait (≥ 450 × 510):** a one-year-old at a first-birthday table with a "1" candle / small cake, sitting up; joyful.
- **E — "6 tuổi · Ngày đầu vào lớp 1", 150 × 200 portrait (≥ 450 × 600):** a 6-year-old with a backpack (and uniform) at a school gate or classroom door, morning light; proud, a bit shy.
- **F — "12 tuổi · Những ước mơ riêng", 150 × 230 portrait (≥ 450 × 690):** a 12-year-old with a personal passion (guitar, telescope, football, painting), confident, looking ahead; not a phone/screen shot.
- **G — video frame and CTA photos:** higher-resolution originals of the current Peach / Mint shots (≥ 640 px), or new parent-and-baby close-ups (4-month "lần đầu biết lẫy" for the video: baby rolling over on a play mat).
- **H — "Ngày ấy và bây giờ":** a matched pair of the **same child** at ~1 month and ~12 months, same framing/pose (e.g. on the same blanket or with the same teddy), each 168 × 196 portrait (≥ 340 × 400). Two different babies undercut the feature.

The dashed text "Ảnh thật · …" in Figma is an instruction to replace, not copy — never render it. Until images arrive, fall back to a `surface-2` window (no label) or the nearest library photo, and do not show the dashed border.

---

## 8. Mobile — PROPOSAL (no mobile frame for v5b)

Derived from the v3 mobile frame `362:3398` (`14` §3–§5 mobile), the split-section rules (`12` §2–§5) and `22` §8 / `25` §6. Breakpoint `< 1120` as today. Needs design sign-off.

**Chặng 1 frame:** keep the frame as an inset card so the existing 335-wide mobile layouts drop in unchanged: outer gutter **10 px**, `border: 2px solid mint; border-radius: 32px;` inner side padding **8 px** (375 − 20 − 4 − 16 = 335), `padding: 40px 8px 24px; gap: 24px`. Alternative if design prefers: full-bleed `mint-soft` band with 2-px `mint` top/bottom rules. Inside:
- Head + bento: the current mobile bento (`14` §4 mobile) — head left-aligned, H2 30 / 1.2, `leadShort`. Tile 1 white.
- Tiện ích: heading Bold 20 + sub Medium 14 / 1.5 (wraps); two cards stacked, `gap: 16px`, card `r 24; padding: 20px; height: auto` (as `22` §8).
- Theo cách: white card `r 24; padding: 24px 16px;` Head → Panel → Bullets (`22` §8), title Bold 24 / 1.2.
- Apple Watch: dark card `r 32; padding: 36px 20px;` content as `25` §6 (W01 alone at ×1.0 over a 320 glow).
- CTA chi tiết: card `r 32; padding: 28px 20px; column; gap: 20px;` copy (eyebrow, Bold 26 / 1.2, Medium 15 / 1.55) → visual re-composed: the two photos 130 × 160 (±6°) side by side, then the button **full width** (no absolute overlap; halo as `box-shadow: 0 0 0 10px var(--mint)`).

**Các chặng tiếp theo:** `padding: 48px 20px; gap: 24px;` head left-aligned (H2 Bold 30 / 1.2, lead 16 / 1.55). Path (785 px) does not fit: **horizontal scroll strip** (`overflow-x: auto; scroll-snap-type: x mandatory;` 20-px inset, connectors 24 px) — or hide it on mobile (the cards carry the same labels). Cards stacked, full width 335, `gap: 16px`: image 335 × 200 (r 24 top via the card), number Bold 64, badge unchanged; body `padding: 20px 20px 24px; gap: 10px`, title Bold 22 / 1.2, lead Medium 15 / 1.5, chips 12, link hug-width.

**Lớn lên band:** v3 mobile band unchanged (`14` §5 mobile: 16-px gutter, r 32, `padding: 36px 24px`, no eyebrow, H2 24 / 1.22, short body, years 90 × 110 r 16, no staircase, **year labels "1 tuổi" / "6 tuổi" / "12 tuổi", no captions**). New `bodyShort` draft: **"Từ sinh nhật đầu tiên đến những ước mơ tuổi 12 — tất cả ở một nơi."** (owner review).

**Cách giữ kỷ niệm:** `padding: 0 20px 48px; gap: 24px;` head left-aligned. Six 446-tall cards stacked would be ≈ 2 400 px → recommend a **horizontal snap carousel**: card 300 wide (`scroll-snap-align: start`, 20-px inset, 12-px gap, next card peeking), illustration rendered at 432 × 280 and scaled with `Fit` (×0.694 → 300 × 194; mock text becomes ~8 px, purely decorative, `aria-hidden`), body full size (title Bold 18, description Medium 14 / 1.5). Alternative: stacked cards with the same `Fit` scaling (×0.775 at 335).

**Nav mobile:** unchanged (logo + EN + "Tải app", no links). **FAQ mobile:** unchanged.

---

## 9. Section ids and nav targets (proposal — Figma defines none)

| Nav link (key) | Home | Stage 1 page | Stages 2–4 |
|---|---|---|---|
| "Hành trình" (`nav.links.journey`) | `#hanh-trinh` | `${homePath}#hanh-trinh` | same |
| "Năm đầu đời" (`nav.links.firstYear`) | `#nam-dau-doi` (on the 524:4030 wrapper) | current page (`current: true`) | Chặng 1 page |
| "Apple Watch" (`nav.links.watch`) | `#apple-watch` (the dark card inside the frame) | `${homePath}#apple-watch` | same |
| **"Các chặng"** (new `nav.links.stages`) | **`#cac-chang`** (516:57063) | `${homePath}#cac-chang` | same (the stage pages also have `StageSwitcher` at the top; do not point there) |
| **"Kỷ niệm"** (new `nav.links.memories`) | **`#ky-niem`** (517:56217, the "Kỷ niệm của con" block, not the whole `#lon-len`) | **local `#ky-niem`** (the Chặng 1 page already has `Memories.tsx` with `id="ky-niem"`, like FAQ) | `${homePath}#ky-niem` |
| "Hỏi đáp" (`nav.links.faq`) | `#hoi-dap` | local `#hoi-dap` | `${homePath}#hoi-dap` |
| "Tải miễn phí" | `#tai-app` | `#tai-app` | `#tai-app` |

- Ids follow the v4 rule (slug of the label / eyebrow): `cac-chang` ("Các chặng"), `ky-niem` ("Kỷ niệm"). No clash on the home page (`ky-niem` exists only on the Chặng 1 page). Heading ids `stages-title`, `keepsakes-title`.
- Keep `id="tien-ich"` on the Tiện ích sub-block (old deep links still land). `#suc-khoe` and `#gia-dinh` disappear (sections removed) — old links fall back to the page top; acceptable, or alias `#suc-khoe` to `#nam-dau-doi`.
- `Chrome.tsx`: drop the health and utilities entries, add stages / memories, reorder to journey, firstYear, watch, stages, memories, faq. Scroll-spy: the spy target for "Năm đầu đời" is the 3382-px frame, which **contains** "Apple Watch" — let the inner `#apple-watch` win while it is in view (nested spy), otherwise both links light up.
- Width problem 1120–≈1230 px: unchanged (`25` §5).

---

## 10. Copy keys (vi.ts) — what changes

| Area | Key | Change / verbatim value |
|---|---|---|
| Nav | `nav.links` | remove `health`, `utilities`; add `stages` **"Các chặng"**, `memories` **"Kỷ niệm"** (order §9) |
| Năm đầu đời | `home.firstYear` | remove `familyTitle(Short)`, `roles`, `trust`, `nextTitle`, `preparing` (home only — check the Chặng 1 page does not use them); add `detail: { eyebrow: 'Chặng 1 · 0–12 tháng', title: 'Xem đầy đủ năm đầu đời', body: 'Từng phần chi tiết: ghi nhanh, nhắc nhở, lịch tiêm, ăn dặm, sơ cứu, chế độ đêm và quyền xem của cả nhà.' }`; keep `more` as the button label |
| Tiện ích | `home.utilities` | `title` → **'Tiện ích cho ba mẹ'** (string), `lead` → **'Những thứ nhỏ giúp ngày làm cha mẹ nhẹ hơn — có sẵn trong tab Tiện ích.'**, drop `eyebrow`, `cards` → 2 items (drop "Gia đình & chia sẻ"); `spending` unchanged |
| Theo cách | `home.yourWay` | no text change (title size only) |
| Sức khoẻ | `home.health` | unused on the home page (Health.tsx has no other caller) — remove with the section, or keep for later |
| Các chặng (new) | `home.stages` | `eyebrow` 'Các chặng tiếp theo', `title` 'Con lớn, Child Life lớn theo con.', `lead` 'Sau năm đầu đời, mỗi chặng mang đến cách chăm mới, điều mới cần để ý và những kỷ niệm mới. Các chặng này đang được chuẩn bị.', `current` 'đang có' (n1 = `journey.stages[0]` short name **'Năm đầu đời'** + ' · ' + current), `soon` 'Sắp ra mắt', `preview` 'Xem trước chặng {n}'; card label = `journey.number` + ' · ' + `stages[i].ages`; title/lead/chips = `journey.stages[i]` |
| Lớn lên | `home.growUp` | `body` → new text (§5.1), `bodyShort` → draft (§8), `years` → `[{ year: '1 tuổi', caption: '2027 · Sinh nhật đầu tiên' }, { year: '6 tuổi', caption: '2032 · Ngày đầu vào lớp 1' }, { year: '12 tuổi', caption: '2038 · Những ước mơ riêng' }]` |
| Kỷ niệm (new) | `home.keepsakes` | `eyebrow` 'Kỷ niệm của con', `title` 'Không chỉ để lưu, mà để kể lại.', `lead` §5.2, `cards[6] { format, title, body }` §5.2 table, `mock` = every string of mocks 1–6 (§5.2) |
| FAQ | — | no change |

English drafts (engineering, owner review, D-012): nav "Stages", "Memories"; detail "Stage 1 · 0–12 months" / "See the whole first year" / "Every part in detail: quick logging, reminders, vaccine schedule, solids, first aid, night mode and who sees what."; utilities sub "Small things that make parenting lighter — ready in the Tools tab."; stages "Next stages" / "As your child grows, Child Life grows too." / "After the first year, each stage brings new ways to care, new things to watch for and new memories. These stages are on the way." / "First year · available" / "Coming soon" / "Preview stage {n}"; band "From the first birthday to the first day of school and the dreams at twelve — your child's story stays in one place and never gets lost as they grow." years "Age 1" "2027 · First birthday", "Age 6" "2032 · First day of school", "Age 12" "2038 · Dreams of their own"; keepsakes "Your child's memories" / "Not just kept, but told." / "Videos, cards, journals, messages and even a book — made from your family's own photos and words." Cards: "Memory story" / "A memory video from ready-made templates, with photos, words, music and your child's milestones."; "Milestone magic" / "Beautiful milestone cards: one month, 100 days, first roll-over… save the image or send it to the family."; "Little moments" / "A short post with photos or videos, saved straight to your child's memory timeline."; "Then and now" / "Compare your child's photos from two moments, and make a transition video from then to now."; "Love from the family" / "Voice or written messages from parents and grandparents — kept for your child to hear when they grow up."; "First-year book" / "A book of your child's first 12 months — download the PDF or order a printed photo book."

---

## 11. Ambiguities, gaps and conflicts

**Design / implementation**
1. **No mobile frame** — §8 is a proposal (frame inset, stage cards stacked, memories carousel).
2. **Invisible elements on the mint frame**: the "Chặng 1 · Năm đầu đời" eyebrow pill (§3.1) and bento tile 1's icon box and chips (§3.2) are `mint-soft` / `surface` on the same colour. Recommend `surface` eyebrows on the frame and `mint-soft` box/chips on the white tile.
3. **Theo cách panel overhangs its white card by 20 px** (§3.4) — fix in code, ask design.
4. **Stage-card heights**: fixed 579 squeezes the bottom padding of cards 2–3 to 13 px and misaligns the links (§4.3).
5. **Stage tints**: Các chặng uses stage 3 = peach + blue ink, stage 4 = sleep; Hành trình uses stage 3 = sleep, stage 4 = peach (§4.3).
6. **Number style** differs between the photo card (white 85 %) and the placeholder cards (tinted 18 %) — use the photo style once images exist.
7. **Placeholders** (5 slots: stage 3, stage 4, band 6 and 12 tuổi; plus the mismatched "1 tuổi" and "Ngày ấy và bây giờ" pair) — need real images before prod (§7); never render the "Ảnh thật · cần thay" text.
8. **Library photos are 220 px**: stage 2 (400²), video frame (316²), CTA photos (210²), "Ngày ấy" halves (196²) will be blurry on retina.
9. **"Ngày ấy và bây giờ" uses two different children.**
10. **Width:** Kỷ niệm grid and Lớn lên band are 1344 (48 gutter) while Các chặng is 1248 (96 gutter) — two content widths alternate down the page; follow the design (wide container for frame/band/grid).
11. **CTA chi tiết halo**: two identical `mint` pills; implement one (§3.6).
12. **Heading levels**: inside `#nam-dau-doi` the Tiện ích, Theo cách, Apple Watch and CTA headings should be `<h3>` (Figma sizes 24 / 32 / 44 / 36 — the watch title keeps 44, larger than its parent's peers; design call whether it should drop to 32 like Theo cách).
13. **Nav spy** with the watch nested inside the Năm đầu đời frame (§9); nav width 1120–1230 still overflows.
14. Path nodes are static in Figma; links are a proposal.
15. Old anchors `#suc-khoe`, `#gia-dinh` vanish; `Health.tsx`, the family strip, trust chips and next-stage list become dead code on the home page (check the stage pages before deleting).
16. Hero bottom padding 24 → 48 (minor, easy to miss).

**Product (owner decisions before prod)** — see §12.

---

## 12. Copy claims vs `docs/product/business-map.md` — NEW claims only (extend Q-039 / R-170)

R-170 still describes v5 (Sức khoẻ, Tiện ích with Gia đình, family roles, trust chips, next stages, 6-link nav with Sức khoẻ/Tiện ích) and must be rewritten for this layout. New claims with no D/R entry:

| # | Claim (verbatim) | Map support | Conflict / over-claim |
|---|---|---|---|
| 1 | "Câu chuyện kỷ niệm" — "Video kỷ niệm theo mẫu có sẵn, kết hợp ảnh, chữ, nhạc và các cột mốc của con.", chip "Video MP4", "Mẫu · Năm đầu đời", "Nhạc: Ru con nhẹ nhàng" | Stories exist as **text + photo blocks** (D-041, `Story` / `StoryBlock`), photo-card export with 5 templates (R-161) | **No video generation, no templates with music, no MP4 export** anywhere in the map; music needs licensing |
| 2 | "Phép màu cột mốc" — "Thiệp cột mốc thật đẹp: tròn 1 tháng, 100 ngày, lần đầu biết lẫy… lưu ảnh hoặc gửi cho cả nhà.", "Lưu ảnh PNG", "Ảnh PNG/JPG" | Milestones exist (R-103, R-105, `Milestone`); story cards exist (R-161) | **No milestone-card templates** (age milestones like "100 ngày") and no PNG export of a milestone; "gửi cho cả nhà" — family sharing is via memories/stories (D-001), not card sending |
| 3 | "Khoảnh khắc nhỏ" — "Một bài viết ngắn kèm ảnh hoặc video, lưu thẳng vào dòng thời gian kỷ niệm của con." | `Memory` journal entry, Nhật ký tab (D-052, R-103) | Mostly true; "dòng thời gian kỷ niệm" wording ≠ app tab names (Ảnh · Album · Nhật ký · Câu chuyện) |
| 4 | "Ngày ấy và bây giờ" — "So sánh ảnh của con ở hai thời điểm, có thể tạo video chuyển cảnh…", "Tạo video chuyển cảnh", "Lưu ảnh ghép" | — | **Not in the map** (no compare view, no transition video, no collage export) |
| 5 | "Lời yêu thương của gia đình" — "Lời nhắn bằng giọng nói hoặc chữ từ ba mẹ, ông bà — giữ lại để con nghe khi lớn.", "Giọng nói + chữ", "Chỉ gia đình nghe được" | D-034 "Nhắn ba mẹ" = one-way **text** from a relative **to the parents** | **No voice recording, no keepsake messages addressed to the child**; voice is a new kind of child-related personal data (storage, retention, "chỉ gia đình" audience rules, R-security); relatives' write rights differ by role (D-018) |
| 6 | "Sách năm đầu đời" — "Cuốn sách tổng hợp hành trình 12 tháng đầu đời của con — tải PDF hoặc đặt in thành sách ảnh.", "PDF · 48 trang", "Đặt in sách ảnh" | — | **Not in the map.** Print ordering implies commerce (payment, address, fulfilment partner, pricing — cf. Q-058 for paid features), none of which exists in V1 |
| 7 | Head lead "Video, thiệp, nhật ký, lời nhắn và cả một cuốn sách — tạo từ chính ảnh và câu chữ của gia đình bạn." | — | Summarises 1–6: only "nhật ký" (and photo cards for stories) exist |
| 8 | Các chặng: "Các chặng này đang được chuẩn bị.", "Sắp ra mắt", "Năm đầu đời · đang có", "Xem trước chặng 2/3/4" | Q-039 (stages 2–4 roadmap) | Wording changes from "Đang cùng con chuẩn bị" to **"Sắp ra mắt"** (a nearer promise); "Xem trước" links to stage pages that still do not say "coming soon" (Q-039) |
| 9 | Band: "Từ sinh nhật đầu tiên đến ngày con vào lớp 1, rồi những ước mơ tuổi 12 — … không mất đi khi con lớn.", "2032 · Ngày đầu vào lớp 1", "2038 · Những ước mơ riêng" | Q-039 retention promise | Extends the retention promise to **12 years with concrete dates (2038)**; same owner question, now sharper |
| 10 | CTA chi tiết: "…lịch tiêm, ăn dặm, sơ cứu…" | v4 Q-039 items | Not new as features, but the Sức khoẻ section that qualified them is gone; "sơ cứu" is hidden on prod until medical review (D-058) |

Owner decisions needed: (1) whether the six "Cách giữ kỷ niệm" products are V1, later (label "Sắp có"), or removed from the prod landing; (2) a privacy/retention position for voice messages before advertising them; (3) print-book commerce scope; (4) "Sắp ra mắt" vs "Đang chuẩn bị" for stages 2–4; (5) image sourcing and licences for the six real-photo slots (§7); (6) R-170 rewrite and Q-039 extension with rows 1–9.
