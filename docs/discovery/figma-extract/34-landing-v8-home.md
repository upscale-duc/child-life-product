# 34 — Landing V8 home page (desktop + mobile) and the "V8/CTA tải app" component

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only; only `get_metadata` / `get_design_context` / `get_screenshot` were used, nothing was modified). Extracted 2026-10-19 from section `734:5373` "Child Life Website — V8".

- Desktop frame **`735:5377` "V8 · Trang chủ · Desktop"**, 1440 × 7978.2.
- Mobile frame **`736:65570` "V8 · Trang chủ · Mobile"**, 390 × 9437.7 (incl. the sticky bar drawn at the bottom).
- Component set **`734:5426` "V8/CTA tải app"**, 4 variants (§C).
- The same V8 section also holds `737:6362` "V8 · Năm đầu đời · Desktop" (not covered here; it is the target of the "Năm đầu đời" links).

Conventions (same as 28 / 32 / 33): colours are named by their token in `packages/design-tokens/dist/tokens.css` when the Figma variable matches one (`var(--mint-soft)` etc.); values with no token are marked **(raw)**. Every visible string is copied **verbatim** from `get_design_context` (punctuation, curly quotes “ ”, en dash –, em dash —, middle dot ·). Font is Be Vietnam Pro everywhere; weights: Medium 500, SemiBold 600, Bold 700. `lh normal` = `line-height: normal`. "shadow-card" = Figma effect style `0 1 2 #173D440F, 0 8 24 #173D4414` (drawn on most cards as a CSS drop-shadow `0 8 12 rgba(23,61,68,.08), 0 1 1 rgba(23,61,68,.06)`; use the existing shadow-card equivalent in the landing CSS).

`<a>` in the Figma code = the layer has a link / prototype reaction (destination not exposed). Only these are `<a>`: nav "Trợ Lý Lumi", nav "Năm đầu đời", "Khám phá Lumi", "Xem tất cả trong Năm đầu đời", Hành trình cards 1 and 2. Everything else that looks clickable is drawn as plain frames; targets in this doc are proposals.

Screenshots (not committed) in `/private/tmp/claude-501/-Users-duckie2910-Documents-child-life-product/8f1c2e02-1c42-4b23-b126-2b499d293516/scratchpad/v8/`: `cta.png` (component set), `s1-hero.png` (desktop hero), `s6.png` (Tiện ích), `s7.png` (Hành trình), `s8.png` (Miễn phí & hỏi đáp), `s9.png` (Kết), `m1-hero.png` (mobile hero). Metadata outline: `meta.xml` in the same folder.

No hover / focus / pressed / disabled states, no tablet frame, no Night care frame, no motion are drawn. The landing stays light-only (as today).

---

## 0. Global

### 0.1 Section order, nodes, sizes

| # | Section | Desktop node · y · h | Mobile node · y · h | Proposed id |
|---|---|---|---|---|
| – | Nav | `735:5378` · 0 · 81 | `736:65571` · 0 · 62 | — |
| 1 | Hero (lai) | `740:7360` · 81 · 703 | `740:7459` · 62 · 902.9 | `#gioi-thieu` |
| 2 | Ba giá trị | `735:5522` · 784 · 701 | `736:65714` · 964.9 · 606 | `#giup-gi` |
| 3 | Kỷ niệm | `735:5598` · 1485 · 1223 | `736:65740` · 1570.9 · 1496 | `#ky-niem` |
| 4 | Cả nhà cùng chăm (+ Trên cổ tay `742:66894` / `742:66990`) | `735:5743` · 2708 · 1002 | `736:65883` · 3066.9 · 1548 | `#cham-soc` (+ `#apple-watch` on Trên cổ tay) |
| 5 | Lumi & gợi ý cho bé | `735:6128` · 3710 · 1075 | `736:66185` · 4614.9 · 1502 | `#lumi` |
| 6 | Tiện ích khác | `735:6226` · 4785 · 799 | `736:66283` · 6116.9 · 967 | `#tien-ich` |
| 7 | Hành trình khi con lớn | `736:65411` · 5584 · 700 | `736:66345` · 7083.9 · 743 | `#hanh-trinh` |
| 8 | Miễn phí, niềm tin & hỏi đáp | `735:6445` · 6284 · 978 | `736:66501` · 7826.9 · 1044 | `#mien-phi` (FAQ list `#hoi-dap`) |
| 9 | Kết | `735:6497` · 7262 · 532 | `736:66553` · 8870.9 · 336.9 | `#tai-app` |
| – | Footer | `735:6525` · 7794 · 184.2 | `736:66574` · 9207.7 · 230 | — |
| – | Sticky download bar (mobile only) | — | `736:66587` · 9322.7 · 74 (fixed) | — |

### 0.2 Shared section pattern

Desktop sections 2, 3, 5, 6, 7, 8: `flex-direction: column; gap: 44px; padding: 96px` (content width 1248), header block "Tiêu đề" = column, gap 12:

- **Eyebrow** pill: padding 6 × 12, radius 999, text 13 SemiBold lh normal. Default `var(--mint-soft)` bg + `var(--mint-text)` text. Exceptions: Kỷ niệm = `var(--peach-soft)` + `var(--ink)`; Lumi = `var(--care-sleep-soft)` + `var(--care-sleep-ink)`.
- **H2**: 42 Bold, lh 1.16, `var(--ink)`, width 820 (Kỷ niệm 860, Hành trình 760). Cả nhà cùng chăm: 42 / lh 1.18.
- **Lead**: 18 Medium, lh 1.55, `var(--ink-muted)`, width 680.

Mobile sections: `padding: 56px 20px; gap: 28px` (content width 350); same eyebrow; H2 28 Bold lh 1.16 (Cả nhà 1.18) width 350; lead 16 Medium lh 1.55 width 350.

Page background `var(--cloud)` (#F6FCFB): sections 7 and the desktop Footer have no fill and show it.

### 0.3 Icons — all exist in the landing Icon map

Used anywhere on the page: `star`, `chevron-down`, `spark`, `globe`, `feed`, `camera`, `arrow-right`, `sleep`, `diaper`, `journal`, `heart`, `bookmark`, `speaker`, `check`, `upload`, `back`, `grid`, `clock`, `eye`, `lock`, `drop`, `ruler`, `today`, `close`, `sliders`, `alert`, `plus`. **Every one is already in `apps/landing/src/components/primitives.tsx` `icons`** (that map also has `mail`, used in §C as a fix). Non-Icon artwork: Logo/Lockup (`Lockup`), Lumi button "Chat/Nút trợ lý" (`LumiMascot` in `components/kit.tsx`), store glyphs (`assets/figma/store-apple*.svg`, `store-play*.svg`), journey landscape (`assets/figma/journey-landscape.svg`), stage art (`assets/figma/journey-art-stage1..4.svg`), Apple Watch (`sections/Watch.tsx`). The Wear OS round watch (§4.6) is new.

### 0.4 Photo slots

Figma uses `Illustration/Photo` placeholders (privacy-safe library photos). The landing replaces them with Teddy photos through `photos` tones (`components/primitives.tsx`) / `scenes` (`components/scenes.ts`). Figma gradient → tone: peach `#FFE3D8→#F7B9A5` (asset 0d3f8), sun `#FFF1C9→#F9D77E` (22456), mint `#CFEFEA→#8FD6CB` (61240 / ae95e), lilac `#EDE3F8→#C8B1E8` (1025f), sky `#DCEBFA→#A9CBEF` (4222e). The raw Figma placeholders also exist as `assets/figma/baby-*.jpg` but the site policy (CREDITS.md, R-170) is real licensed photos. Per-slot mapping in each section.

---

## 1. Nav

### 1.1 Desktop `735:5378` (1440 × 81)

Row, `align-items: center; gap: 32px; padding: 20px 96px; background: var(--cloud)`.

1. Logo/Lockup Horizontal `735:5379` — mark 34 + wordmark 132.4 × 26.52, gap 9.52 → `<Lockup />` (scale 1).
2. spacer (flex 1).
3. Links, each 15 Medium lh normal `var(--ink)`, gap 32 between items:
   - "Chăm sóc" `735:5390` (text)
   - "Kỷ niệm" `735:5391` (text)
   - "Trợ Lý Lumi" `735:5392` (**`<a>`**)
   - "Năm đầu đời" `735:5393` (**`<a>`**)
   - "Hỏi đáp" `735:5394` (text)
4. Button "Nút · Bắt đầu" `735:5395`: `var(--mint-deep)` bg, padding 11 × 20, radius 999; text "Bắt đầu" 15 SemiBold `var(--on-mint-deep)`.

Targets (proposal): Chăm sóc → `#cham-soc` (§4); Kỷ niệm → `#ky-niem` (§3); Trợ Lý Lumi → `/lumi/` (`pathOf('lumi')`); Năm đầu đời → the V8 Năm đầu đời page (`737:6362`; today's route is `stage1` `/hanh-trinh/nhung-ngay-dau-doi/`); Hỏi đáp → `#hoi-dap` (§8); Bắt đầu → `#tai-app` (§9). On other pages the hash links become `{homePath}#…` (current `Nav` pattern). No language switch is drawn; keep the existing EN switch (D-012) between links and button.

### 1.2 Mobile `736:65571` (390 × 62)

Row, `align-items: center; gap: 10px; padding: 12px 20px; background: var(--cloud)`. **No links.**

1. Lockup: mark 26.52 + wordmark 103.27 × 20.69, gap 7.43 (≈ `Lockup scale={0.78}`).
2. spacer.
3. "Nút · Bắt đầu" `736:65583`: `var(--mint-deep)`, padding 8 × 14, radius 999; "Bắt đầu" 13 SemiBold `var(--on-mint-deep)` → `#tai-app`.
4. **"Menu" `736:65585`** (36 × 38): `var(--surface)` bg, radius 999, padding 12 × 10, column gap 4, three bars 16 × 2 radius 1 `var(--ink)` (hamburger).

What "Menu" implies (not drawn — gap): a mobile navigation panel listing the five desktop links (Chăm sóc, Kỷ niệm, Trợ Lý Lumi, Năm đầu đời, Hỏi đáp) plus the language switch (D-012; the mobile nav has no other place for it). Needs: `<button aria-expanded aria-controls>` with labels "Mở menu" / "Đóng menu" (new strings), an open state (sheet or drop-down under the 62 px bar; icon changes to `close`), Esc / outside tap / link tap closes, focus moves into the panel and back, body scroll locked while open. Desktop breakpoint where links collapse: today's nav shows links ≥ the desktop breakpoint only — keep it.

---

## 2. Section 1 · Hero (lai)

### 2.1 Desktop `740:7360` (1440 × 703)

Row, `align-items: center; gap: 40px; padding: 40px 96px 56px; background: linear-gradient(to bottom, #F0FAF7, #FAFCFC)` **(raw)**. Copy 600 + gap 40 + visual 620 = 1260 → right padding is 84, not 96 (§ Ambiguities).

**Copy `740:7361`** — column, gap 20, width 600:

1. Eyebrow `740:7363` (mint): "Child Life · Bắt đầu từ năm đầu đời"
2. H1 `740:7364`: 50 Bold, lh 1.12, `var(--ink)`, width 600 — "Cùng chăm con, giữ từng khoảnh khắc con lớn lên." (wraps to 3 lines at 600: "Cùng chăm con, giữ / từng khoảnh khắc con / lớn lên." — natural wrap, no forced break)
3. Lead `740:7365`: 19 Medium, lh 1.55, `var(--ink-muted)` — "Ghi bú, ngủ, tã để cả nhà cùng theo dõi. Lưu ảnh, tạo video và giữ lại những lần đầu tiên của con."
4. Support line "Dòng hỗ trợ" `740:7366`: row gap 8, `Icon star` 14 + text 15 SemiBold lh normal `var(--mint-text)` — "Bắt đầu với năm đầu đời. Tiếp tục đồng hành khi con lớn."
5. **V8/CTA tải app** instance `740:7370`, variant *Sau ra mắt · Ngang* (411.4 × 93) — §C.
6. "Nút · Xem app hoạt động" `740:7386`: row gap 8, padding 6 × 0, no bg; "Xem app hoạt động" 15 SemiBold `var(--mint-text)` + `Icon chevron-down` 16. Target (proposal): `#giup-gi` (smooth scroll to §3).

**Visual "Visual + tầm nhìn" `743:7582`** — column, gap 6, align center:

- Illustration `740:7390` 620 × 580 (absolute layout; same coordinates as today's `JourneyHero`):
  - Landscape `740:7391` at (50, 20), 540 × 540, radius 48, `linear-gradient(to bottom, #FFF5D9, #E0F5F0)` (raw), sun / clouds / hills ellipses + road vectors → **`assets/figma/journey-landscape.svg`** (already the same artwork).
  - Stage nodes (positions relative to the 620 box): ① photo node 86 at (117, 447): `var(--surface)` circle, 4 px solid `var(--mint-deep)` border, photo inside (tone **peach** → Teddy 8 months, as today); ② 64 at (248, 348): 4 px **dashed** `var(--sunshine)`, opacity 0.5, `Icon star` 25.6; ③ 56 at (362, 282): dashed `var(--care-sleep-accent)`, opacity 0.5, `Icon spark` 22.4; ④ 50 at (475, 185): dashed `var(--care-bottle-accent)`, opacity 0.5, `Icon globe` 20.
  - Stage chips (padding 4 × 10, radius 999, 12 SemiBold lh normal):
    - (110, 530) `var(--mint-deep)` bg, `var(--on-mint-deep)` text: "0–12 tháng · Đang có trong app"
    - (246, 424) `var(--surface)` bg, opacity 0.75, `var(--ink)`: "1–3 tuổi · Sắp tới"
    - (356, 346) same: "3–6 tuổi · Sắp tới"
    - (450, 246) same: "6–12 tuổi · Sắp tới"
  - Float card 1 `740:7422` at (10, 110): `var(--surface)`, radius 18, padding 12 × 14, shadow-card; row gap 8: icon box 32 (`var(--care-bottle-soft)`, radius 12, padding 8, `Icon feed` 16) + text column: "Bú bình · 120 ml" 14 Bold `var(--ink)` / "Ba vừa ghi · 2 phút trước" 12 Medium `var(--ink-muted)`.
  - Float card 2 `740:7429` at (0, 350): same card; photo 40 × 40 radius 10 (tone **sun**) + "Lần đầu con cười" 14 Bold / "Đã lưu vào Kỷ niệm" 12 Medium `var(--mint-text)`.
  - Video card "Kỷ niệm · Video đầy tháng" `740:7441` at (410, 380), width 210: `var(--surface)`, radius 20, padding 8 8 12, gap 8, shadow-card; photo 194 × 120 radius 14 (tone **peach**, image offset −37) with a white round play button (padding 8, `Icon arrow-right` 14) centred at (82, 45); title "Video đầy tháng của Teddy" 13 Bold `var(--ink)`; meta row gap 6: `Icon camera` 12 + "0:45 · từ ảnh bạn chọn" 11 Medium `var(--ink-muted)`.
- "Tầm nhìn" `743:7583`: 14 Medium, lh 1.5, `var(--ink-muted)`, centred, width 520 — "Hệ sinh thái đồng hành cùng con — từ ngày đầu đời đến khi trưởng thành."

Differences from today's `JourneyHero`: new copy; CTA + support line + "Xem app hoạt động" replace the promises list and "Xem hành trình của con"; chips carry a status and chip 1 is mint-deep; the third float ("Bà nội thương ảnh của Teddy" line) is replaced by the video card at (410, 380); the "Tầm nhìn" caption is new.

### 2.2 Mobile `740:7459` (390 × 902.9)

Column, `align-items: center; gap: 24px; padding: 20px 20px 40px`; same gradient.

- Copy `740:7460`: column gap **16**, width 350. Eyebrow same. H1 **34** Bold lh 1.12. Lead **16** Medium lh 1.55. Support line text **13** SemiBold (wraps to 2 lines). CTA instance `740:7469` variant **Sau ra mắt · Dọc** (339.25 × 80.86). "Xem app hoạt động" unchanged (15).
- Visual `743:7584`: column gap 10. "Minh hoạ hành trình" `740:7557` 350 × 328, overflow clip, containing the desktop illustration **scaled ×0.5645** (350 / 620) — all positions/sizes ×0.5645 (landscape 304.8 radius 27.1; chips text 6.77 px; float titles 7.9 px). Use the existing `Fit` with `mobileScale={0.5645}` (today 0.5403). "Tầm nhìn" `743:7585`: **13** Medium lh 1.5, centred, width 330.
- Order: copy first, visual second (same as desktop reading order). Nothing hidden.

---

## 3. Section 2 · Ba giá trị

### 3.1 Desktop `735:5522` (1440 × 701)

`background: var(--surface)`; column gap 44, padding 96.

Header `735:5523`: eyebrow (mint) "Child Life giúp gì"; H2 "Child Life giúp gia đình bạn ba việc."; lead "Mỗi phần đều dùng được ngay trong năm đầu đời của con."

"Ba cột" `735:5526`: row gap 24 (3 × 400 + 2 × 24 = 1248). Each card: `var(--cloud)` bg, radius 24, padding 14 14 24, column gap 16, width 400, equal height (self-stretch).

- **Picture "Hình"** 372 × 200, radius 20, padding 20, content vertically centred:
  - Card 1 `735:5527` — `var(--care-bottle-soft)`; three rows (column gap 8, width 332). Row = `var(--surface)`, radius 12, padding 8 × 10, gap 10: icon box (padding 8, radius 12, soft tint) with icon 14; label 13 SemiBold `var(--ink)` (flex 1); time 12 Medium `var(--ink-muted)`:
    - `feed` on `var(--care-bottle-soft)`: "Bú bình 120 ml" · "9:00"
    - `sleep` on `var(--care-sleep-soft)`: "Ngủ 1 giờ 20 phút" · "10:40"
    - `diaper` on `var(--care-diaper-soft)`: "Thay tã" · "11:05"
  - Card 2 `735:5555` — `var(--care-sleep-soft)`; "Tuần này của bé" card (`var(--surface)`, radius 14, padding 12, gap 4): "Tuần này của bé · 4 tháng" 13 Bold `var(--ink)` / "Bé thường bắt đầu với lấy đồ vật. Gợi ý: đặt đồ chơi trong tầm tay." 12 Medium lh 1.45 `var(--ink-muted)`; then one row: `star` on `var(--sunshine-soft)` "Mốc: Biết lẫy" · "đã ghi".
  - Card 3 `735:5571` — `var(--peach-soft)`; three photos in a row (gap 8): 105.33 × 100, 105.33 × **118**, 105.33 × 100 (middle one taller), radius 12, `var(--surface-2)` behind. Tones peach / sun / mint → Teddy 8 months / Teddy couch / Teddy newborn yawn.
- **Text "t"** (padding 0 10, column gap 8): title 22 Bold lh normal `var(--ink)`; body 15 Medium lh 1.55 `var(--ink-muted)`:
  - "Chăm con mỗi ngày" — "Ghi bú, ngủ, tã và đặt nhắc nhở. Cả nhà cùng biết con vừa được chăm thế nào."
  - "Hiểu con từng giai đoạn" — "Xem nhật ký, theo dõi mốc phát triển và tìm nội dung theo tuổi của bé."
  - "Giữ những điều đáng nhớ" — "Lưu ảnh riêng tư, tạo thiệp và video từ những khoảnh khắc của con."

No links in this section.

### 3.2 Mobile `736:65714` (390 × 606)

`var(--surface)`; padding 56 × 20, gap 28. Header same strings (H2 28, lead 16).

"Ba hàng" `736:65718`: column gap 12, width 350. **The pictures are hidden**; each card becomes a row: `var(--cloud)`, radius 20, padding 12, gap 14, `align-items: center`:
- Icon box 38 (padding 8, radius 12) with a 22 icon — **mobile-only icons**: `feed` on `var(--care-bottle-soft)`, `star` on `var(--care-sleep-soft)`, `heart` on `var(--peach-soft)`.
- Text column gap 4: title **17** Bold; body **14** Medium lh 1.5 `var(--ink-muted)`. Same strings as desktop.

---

## 4. Section 3 · Kỷ niệm

### 4.1 Desktop `735:5598` (1440 × 1223)

`background: #FFF7F0` **(raw)**; column gap 44, padding 96.

Header `735:5599`: eyebrow (peach-soft / ink) "Kỷ niệm"; H2 (width 860) "Những tấm ảnh hôm nay, thành kỷ niệm để mai này xem lại." (2 lines at 860: "…thành kỷ niệm / để mai này xem lại."); lead "Chọn ảnh của con để tạo video đầy tháng, thiệp cột mốc hoặc lưu vào album riêng của gia đình."

"Lưới kỷ niệm" `735:5604`: row gap 24, `align-items: flex-start` → left 640 + right column 592 = **1256** (8 px wider than the 1248 content box — §Ambiguities). All cards: `var(--surface)`, radius 24, shadow-card.

**Video kỷ niệm** `735:5605` (640 wide; padding 12 12 22; column gap 14):
- Illustration 616 × 430, radius 20, overflow clip; inner `var(--care-sleep-soft)` canvas 663.4 wide at x −23.7. Player frame at (89.07, 43) 485.3 × 301, radius 27.6, shadow `0 12.3 36.9 rgba(23,61,68,.08), 0 1.5 3.1 rgba(23,61,68,.06)`: photo (tone **peach** → `scenes.firstYearVideo`, offset −92); bottom scrim 147.4 high `linear-gradient(transparent, rgba(0,0,0,.6))`; template pill top-left (18.4, 18.4) white, padding 7.7 × 15.4, "Mẫu · Năm đầu đời" 16.9 Bold `var(--ink)`; round white play button (padding 18.4, `arrow-right` 27.6) at (210.4, 95.2); caption "Lần đầu biết lẫy · 4 tháng" 23 Bold white at (21.5, 208.9); progress track 442.3 × 6.1 `rgba(255,255,255,.4)` with a 168.9 white fill at (21.5, 267.2); time "0:16 / 0:45" 16.9 SemiBold white at (370.1, 239.6). Two pills below the player at y 362.4 (white, radius 999, padding 9.2 × 15.4, gap 9.2, shadow): `speaker` 21.5 + "Nhạc: Ru con nhẹ nhàng" 18.4 SemiBold; `star` 21.5 + "3 cột mốc".
- Text (padding 0 10, column gap 6): "Video kỷ niệm" 24 Bold `var(--ink)`; "Chọn ảnh và mẫu, có ngay video đầy tháng, 100 ngày hay thôi nôi để gửi cả nhà." 15 Medium lh 1.5 `var(--ink-muted)`; outline button "Nút · Xem video mẫu" (`var(--surface)`, 1 px `var(--control-border)`, radius 999, padding 10 × 16, gap 8): "Xem video mẫu" 14 SemiBold `var(--ink)` + `arrow-right` 16.

**Right column "Cột"** `735:5634` (column gap 24, width 592):
- **Thiệp cột mốc** `735:5635` — width **584** (padding 12 12 18; gap 12): illustration 560 × 160 radius 20 clip; inner `var(--sunshine-soft)` canvas 560 × 363 at y −181.5 (only the middle band shows). A card rotated 3° (white, radius 23.3, padding 15.6 15.6 20.7, gap 10.4, shadow): photo 228.1 × 194.4 radius 15.6 (tone **mint**); "100 ngày" 33.7 Bold `var(--care-growth-ink)`; "Teddy · 18.01.2027" 15.6 Medium `var(--ink-muted)`. Three `star` 20.7 sparkles. Template options at (339.6, 85.6), column gap 10.4, pills padding 9.1 × 15.6 radius 999, 15.6 SemiBold: white `star` "1 tháng"; **selected** `var(--care-growth-accent)` bg + white text `check` "100 ngày"; white `star` "Lần đầu biết lẫy". Pill (339.6, 259.3) white shadowed: `upload` 18.1 + "Lưu ảnh PNG". (Most of this composition is cropped by the 160 band — in the render you see the photo top, "100 ngày", the date, "Lần đầu biết lẫy" and "Lưu ảnh PNG".)
  Text (padding 0 8, gap 4): "Thiệp cột mốc" 18 Bold; "Tròn tháng, 100 ngày, lần đầu biết lẫy — chọn mẫu và ảnh, gửi cho ông bà." 14 Medium lh 1.5 muted.
- "Hai" row (gap 24):
  - **Ngày ấy & bây giờ** `735:5663` (284; padding 12 12 18; height 261): illustration 260 × 150 radius 20; `var(--care-bottle-soft)` canvas. Split frame 202.2 × 118 radius 10.8 at (28.9, 13.2 + 9.3 offset): two photos 101.1 wide (left tone **lilac**, right tone **mint** → use `scenes.thenBaby` / `scenes.nowBaby` as today's Keepsakes), 1.8 px white divider, a small white handle with `back` + `arrow-right` 7.2; labels "1 tháng" (left) and "12 tháng" (right) 6.6 Bold in white pills. Pills under it: `camera` + "Tạo video chuyển cảnh"; `grid` + "Lưu ảnh ghép" (7.2 SemiBold).
    Text: "Ngày ấy & bây giờ" 18 Bold; "Đặt hai tấm ảnh cạnh nhau để thấy con lớn thế nào." 14 lh 1.5 muted.
  - **Album gia đình riêng tư** `735:5688` (284; height **240**): box 260 × 150 `var(--peach-soft)` radius 18 padding 12, column gap 8: three photos 74.67 square radius 10 (gap 6; tones peach, sky, mint); row gap 6: avatar pill "B" (white, padding 3 × 7, 11 Bold) + "Bà nội đã xem 3 ảnh mới" 12 SemiBold `var(--ink)`.
    Text: "Album gia đình riêng tư" 18 Bold; "Ông bà ở xa vẫn theo dõi cháu." 14 lh 1.5 muted.

**"Còn có"** `735:5719` (full width 1248): `var(--surface)`, radius 24, padding 16 × 20, row gap 28, align center:
- "Còn có:" 15 Bold `var(--ink)`
- items (row gap 8): icon box (padding 8, radius 12, `var(--peach-soft)`, icon 14) + label 15 SemiBold `var(--ink)`: `journal` "Nhật ký của con"; `heart` "Lời nhắn cho con"; `bookmark` "Sách năm đầu đời" + chip "Sắp có" (`var(--surface-2)`, padding 3 × 8, radius 999, 11 SemiBold `var(--ink-muted)`).

Button **"Nút · Xem các mẫu kỷ niệm"** `735:5739`: `var(--mint-deep)`, padding 14 × 22, radius 999, gap 8: "Xem các mẫu kỷ niệm" 16 SemiBold `var(--on-mint-deep)` + `arrow-right` 16.

Targets (proposal, none is a link in Figma): "Xem video mẫu" → needs a sample video (no asset exists) — either play a short Remotion export in a dialog or drop the button; "Xem các mẫu kỷ niệm" → the Kỷ niệm section of the Năm đầu đời page (`737:6362`) until a template gallery exists.

### 4.2 Mobile `736:65740` (390 × 1496)

`#FFF7F0`; padding 56 × 20, gap 28. Header same strings (H2 28 → 3 lines, lead 16).

- **Video kỷ niệm** `736:65746` — width 350, **radius 20**, padding 12 12 22, gap 14: illustration 326 × 210 (the desktop composition scaled ≈ ×0.49: template pill text 8.3 px, caption 11.3 px, pills 9.1 px). Title **20** Bold; body 15 (same string); "Xem video mẫu" button unchanged.
- **"Danh sách"** `736:65775` — column gap 12; three **row cards** (350 wide, `var(--surface)`, radius 20, padding 12, gap 14, align center, shadow-card): thumbnail **110 × 110** radius 20 (a crop of each desktop illustration scaled ≈ ×0.30; text inside is 4.3–10 px) + text column gap 4 (title 17 Bold, body 14 lh 1.5 muted). **Mobile copy differs:**
  - "Thiệp cột mốc" — "Chọn mẫu và ảnh, gửi cho ông bà."
  - "Ngày ấy & bây giờ" — "Hai tấm ảnh, thấy con lớn thế nào."
  - "Album gia đình riêng tư" — "Ông bà ở xa vẫn theo dõi cháu." (thumb = peach-soft box padding 12 with three 24.67 photos and the "B · Bà nội đã xem 3 ảnh mới" line, which does not fit in 110 px — §Ambiguities)
- **"Còn có"** `736:65859` — `var(--surface)`, radius **20**, padding 16 × 20, **column** gap 10 (label then the three items stacked).
- Button "Xem các mẫu kỷ niệm" unchanged (240 × 48, left-aligned).

---

## 5. Section 4 · Cả nhà cùng chăm (+ Trên cổ tay)

### 5.1 Desktop `735:5743` (1440 × 1002)

`background: var(--surface)` (white in render); column gap 44, padding 96. Two blocks: "Hàng" `735:5744` (1248 × 346) and "Trên cổ tay" `742:66894` (1248 × 420).

**"Hàng"**: row gap 48, align center.

*Copy* `735:5745` — column gap 16, width 560:
1. Eyebrow (mint) "Cả nhà cùng chăm"
2. H2 42 Bold lh 1.18: "Ba vừa ghi, mẹ đã thấy. Không ai phải hỏi lại." (renders "Ba vừa ghi, mẹ đã thấy. / Không ai phải hỏi lại." at 560)
3. Three bullet rows (gap 12, align center): icon box (padding 8, radius 12, `var(--mint-soft)`, icon 16) + text 16 SemiBold lh 1.4 `var(--ink)`:
   - `journal` "Ghi và xem chung một nhật ký."
   - `clock` "Nhắc nhở đúng người đang chăm bé."
   - `eye` "Ba mẹ, người chăm và người thân có quyền xem khác nhau."
4. Trust note "Niềm tin" `735:5767`: `var(--mint-soft)`, radius 14, padding 12 × 14, gap 8: `lock` 16 + "Bạn chọn ai được xem ảnh và thông tin của con." 14 SemiBold `var(--mint-text)`.

*Scenario "Tình huống"* `735:5772` — `var(--cloud)`, radius 28, padding 36 × 28, row gap 12, width 640: three equal cards (flex 1, 161.3 wide, `var(--surface)`, radius 20, padding 16, column gap 10, shadow-card) separated by round arrow chips (`var(--mint-soft)`, padding 6, `arrow-right` 14):
- Header row gap 8: avatar pill (padding 5 × 10, radius 999, 13 Bold `var(--ink)`) + meta 12 Medium `var(--ink-muted)`; title 15 Bold lh 1.3; body 13 Medium lh 1.45 muted.
  - Card 1: avatar "B" on `var(--care-bottle-soft)`, "Ba · 09:00"; "Ba ghi cữ bú"; "Bú bình 120 ml — một chạm là xong."
  - Card 2: avatar "M" on `var(--peach-soft)`, "Mẹ · 09:01"; "Mẹ thấy ngay"; "“Ba vừa ghi: Bú bình 120 ml lúc 9:00.”"
  - Card 3: avatar "✓" on `var(--mint-soft)`, "Cả nhà"; "Không cần hỏi lại"; "Cữ tiếp theo đã có nhắc cho người đang chăm."

### 5.2 Trên cổ tay — desktop `742:66894` (1248 × 420)

`background: #163D44` **(raw; same value as `lumi.css` .lp-how card)**, radius 28, padding 40 × 48, row gap 40, align center.

*Copy* `742:66895` (column gap 14, width 480):
- Chip "Trên cổ tay": `var(--sunshine-soft)`, padding 5 × 10, radius 999, 12 SemiBold `var(--ink)`.
- Title 30 Bold lh 1.2 white: "Đang bế con? Ghi ngay trên đồng hồ."
- Lead 16 Medium lh 1.55 `#CCE0E0` (raw): "Một chạm để ghi bú, ngủ, tã — cả nhà thấy ngay trên điện thoại."
- Platform chips "Nền tảng" (wrap, gap 8), padding 5 × 10, radius 999, 12 SemiBold, icon 12 + gap 6:
  - "Chip · Apple Watch": `var(--mint-soft)` bg, `check` + "Apple Watch" `var(--mint-text)`
  - "Chip · Đồng hồ Android (Wear OS) · Sắp có": `var(--surface)` bg, `clock` + "Đồng hồ Android (Wear OS) · Sắp có" `var(--ink-muted)`

*Illustration "Minh hoạ đồng hồ"* `742:66910` (560 × 340, decorative):
- Glow ellipse 374 × 306 at (93, 17) (`watch-band__glow` equivalent).
- **Apple Watch W01** at (44.8, 8.5), 276.2 × 323: case `#292B2E`, radius 72.6; screen black 243.4 × 290.2 radius 53.8 at (16.4, 16.4); crown `#4D4F52` 11.7 × 39.8 at (274.3, 81.9). Content (scale ≈ 1.17 of W01): top row "Teddy" 17.6 Bold / "9:41" 17.6 SemiBold white; 2-column tiles (gap 7, radius 23.4, padding 11.7, bg `#1F2124`; icon circle in the care accent; label 14 SemiBold in the care accent; value 18.7 Bold white; caption 12.9 Medium `rgba(255,255,255,.6)`):
  - `feed` "Bú bình" "2:15" "từ cữ trước" (`var(--care-bottle-accent)`)
  - `drop` "Bú mẹ" "3:35" "từ cữ trước" (`var(--care-breast-accent)`)
  - `sleep` "Ngủ" "0:42" "đang ngủ" — **tile bg `var(--care-sleep-accent)`** (running timer)
  - `diaper` "Tã" "1:25" "từ lần trước" (`var(--care-diaper-accent)`)
  - `drop` "Hút sữa" "5:10" "từ lần trước" (`var(--care-pump-accent)`)
  - `ruler` "Nhắc" "17:00" "nhắc bú" (`var(--care-growth-accent)`)
  Content is 349 high in a 290 screen, so row 3 (Hút sữa / Nhắc) is cut by the screen edge — as in today's `HomeFace`.
- **Android watch (round)** `742:66966` at (316.4, 48.75), 210 × 262.5: straps `#333D45` 105 × 52.5 radius 15.75 top and bottom; bezel ellipse 210; button `#596169` 10.5 × 29.75; screen `#0A0D0F` circle 189: "9:41" 11.4 SemiBold white; "Teddy" 10.5 Medium `#B2BFC7`; four tiles 73.5 × 54.25 radius 15.75 (label 8.75 SemiBold, value 14.9 Bold, white): `#3D78D9` "Bú bình" "2:15"; `#D95C85` "Bú mẹ" "3:35"; `#6661D9` "Đang ngủ" "0:42"; `#33996B` "Tã" "1:25" (all raw). **New component.**
- Labels under the watches (white pill, padding 4 × 9, radius 999, 11 SemiBold `var(--ink)`): "Apple Watch" at (142.9, 318); "Wear OS" at (391.4, 318).

Link (proposal): none drawn; the "Apple Watch" chip could link to the Năm đầu đời page's watch section.

### 5.3 Mobile `736:65883` (390 × 1548)

`var(--surface)`; padding 56 × 20, gap 28.

"Hàng" `736:65884` → **column**, gap 24, align center:
- Copy (width 350, gap **14**): H2 **28** lh 1.18 (3 lines); bullet rows unchanged (16 SemiBold; the third wraps → 44 high); "Niềm tin" box full width 350, `align-items: flex-start`, text wraps (14 SemiBold).
- "Tình huống" `736:65912`: `var(--cloud)`, radius **24**, padding **20 × 16**, **column** gap 12, align center: the three cards stacked at **318** wide (padding 16, same contents); the two connectors use **`chevron-down`** 14 (instead of `arrow-right`) in the same mint-soft circles.

"Trên cổ tay" `742:66990` (350 × 545): `#163D44`, radius **24**, padding **24 × 20**, **column** gap 20, align center:
- Copy (width 310, gap 14): chip same; title **24** Bold lh 1.2; lead **14** lh 1.55; platform chips wrap onto two lines.
- Illustration 310 × 250: glow 275 × 225 at (17.5, 12.5); Apple Watch 203.1 × 237.5 at (24.8, 6.25) (×0.735 of desktop); Android watch 150 × 187.5 at (141.4, 41.25) (×0.714); labels at (86.3, 228) and (186.4, 228).

---

## 6. Section 5 · Lumi & gợi ý cho bé

### 6.1 Desktop `735:6128` (1440 × 1075)

`background: linear-gradient(135.1deg, #F2FCFA 14.3%, #F2F2FF 85.7%)` **(raw; same family as lumi.css)**; column gap 44, padding 96.

Header `735:6145` (column gap 12):
- "Đầu" row gap 12: Lumi button "Chat/Nút trợ lý" 52 (→ `LumiMascot size={52}`) + eyebrow (sleep tint) "Lumi · Trợ lý trong Child Life".
- H2 (820): "Nhắn một câu, Lumi lo phần ghi chép."
- Lead (680): "Lumi soạn nháp từ lời bạn nhắn và trả lời từ nhật ký của con. Khi mở app, bạn cũng thấy gợi ý liên quan đến những gì đã ghi."

"Lumi · trình diễn" `742:7440`: row gap 24, two panels 604 × 566 (total 1232, 16 px short of 1248). Panel: radius 28, padding 28 28 **0**, column gap 18, align center, overflow clip (the mock is cut at the panel's bottom edge — intentional phone crop).

**Panel A "Bạn nhắn — Lumi lo"** `742:7441` — `linear-gradient(136.9deg, #D1F2EB 14.3%, #DBDEFF 85.7%)` (raw).
- Head row gap 12: `LumiMascot` 44 + text (gap 2): "Bạn nhắn, Lumi lo phần ghi" 22 Bold lh 1.25 `var(--ink)`; "Một câu thành nhiều bản ghi. Hỏi là có câu trả lời từ nhật ký." 14 Medium lh 1.45 muted.
- Stage 548 × 470 (relative). Chat mock "Mock · Chat với Chi" (layer name is legacy; the text says Lumi) at (74, 0), width 400 (natural height 625): `var(--cloud)`, 1 px `var(--separator)`, **top** corners radius 32, padding 18 × 16, column gap 12, shadow-card:
  - Header row gap 10: `LumiMascot` 36 + "Lumi" 16 Bold / "Trợ lý của nhà Teddy" 12 Medium muted.
  - Parent bubble (right-aligned, max 294.4): `var(--mint-deep)`, radius 16, padding 9 × 13, 13 Medium lh 1.4 `var(--on-mint-deep)` — "Con bú 120 ml lúc 9h, ngủ từ 9h30, thay tã lúc 10h"
  - Lumi reply: avatar 22 (gradient `#2BC4B5 → #545CDB` 126.9°, `spark` 12) + bubble (`var(--surface)`, 1 px `var(--separator)`, radius 16, padding 9 × 13, gap 8): "Mình soạn 3 bản nháp, bạn xem lại rồi lưu nhé:" 13 Medium lh 1.45 `var(--ink)`; three draft rows (`var(--cloud)`, 1 px separator, radius 16, padding 10 × 12, gap 10; icon box padding 8 radius 12 icon 16; title 14 SemiBold; sub 12 Medium muted; chip "Nháp" `var(--surface-2)` padding 4 × 10, 12 SemiBold muted): `feed`/bottle-soft "Bú bình · 120 ml" "9:00"; `sleep`/sleep-soft "Giấc ngủ" "từ 9:30"; `diaper`/diaper-soft "Thay tã" "10:00"; full-width button `var(--mint-deep)` radius 999 padding 9 × 14 "Lưu cả 3" 13 SemiBold.
  - Parent bubble: "Mấy hôm nay con hay khó ngủ buổi tối"
  - Lumi reply: "3 tối gần đây có 2 lần bạn ghi “khó vào giấc”, đều sau 21h. Muốn xem lại các giấc quanh đó không?"
  - Composer (`var(--surface)`, 1 px `var(--control-border)`, radius 999, padding 10 × 12, gap 8): `camera` 16 + "Kể, hỏi hoặc gửi ảnh cho Lumi…" 13 Medium muted + send circle (`var(--mint-deep)`, padding 6, `arrow-right` 14).
- Floating chips (white, radius 999, padding 8 × 12, gap 8, shadow-card; icon circle padding 4, icon 12; 12 SemiBold `var(--ink)`):
  - at (−8, 340): `check` on `var(--mint-soft)` + "Đã lưu 3 bản ghi"
  - at (347, 400): `check` on `var(--care-sleep-soft)` + "Bạn xác nhận trước khi lưu"

**Panel B "Bạn mở app — đã có sẵn"** `742:7544` — `linear-gradient(136.9deg, #FFF0DB 14.3%, #FFE0DB 85.7%)` (raw).
- Head row gap 12: icon box (`var(--surface)`, padding 8, radius 12, `today` 22) + "Bạn mở app, điều cần xem đã có" 22 Bold / "Gợi ý xuất hiện kèm lý do — vì những gì bạn đã ghi." 14 muted.
- Stage 548 × 470. Mock "Mock · Hôm nay của bé" at (74, 0), width 400 (natural height 746): same shell (padding 20 × 16, gap 12):
  - Header row gap 10: avatar "T" (`var(--peach-soft)`, padding 7 × 11, 15 Bold) + "Hôm nay của Teddy" 17 Bold / "Thứ Năm · 3 điều đáng chú ý" 12 Medium muted + chip "Ví dụ minh hoạ" (`var(--surface)`, 1 px separator, padding 4 × 9, gap 6, `eye` 11 + 11 SemiBold muted).
  - Three cards (`var(--surface)`, radius 20, padding 14, gap 10, width 368, shadow-card). Head: icon box (padding 8, radius 12, icon 16) + title 15 Bold. Body 13 Medium lh 1.45 `var(--ink)`. "Vì sao" box (radius 12, padding 8 × 10, gap 3, soft tint): label `eye` 11 + "Vì sao bạn thấy thẻ này" 11 SemiBold, text 12 SemiBold lh 1.4 `var(--ink)`. Actions row gap 8: outline button (1 px `var(--control-border)`, radius 999, padding 8 × 12, 13 SemiBold + `arrow-right` 16), spacer, `heart` 14, `close` 14.
    1. `sleep` / `var(--care-sleep-soft)` "Nhìn lại giấc ngủ" — "2 tối gần đây con khó vào giấc, đều sau 21h." — why (sleep-soft, label `var(--care-sleep-ink)`): "Bạn đã ghi nhận “khó vào giấc” trong 2 ngày gần đây." — "Xem các ghi nhận liên quan"
    2. `bookmark` / `var(--sunshine-soft)` "Ý tưởng cho bữa tiếp theo" — "Cháo bí đỏ yến mạch · Khoai lang nghiền" — why (sunshine-soft, label ink): "Dựa trên tuổi, món đã thử và phản ứng bạn ghi." — "Xem món và nguyên liệu"
    3. `heart` / `var(--peach-soft)` "Giữ lại nụ cười đầu tiên" — body row: photo 44 radius 10 (tone peach) + "3 ảnh bạn chọn hôm qua đã sẵn sàng." — why (peach-soft): "Bạn vừa đánh dấu mốc “mỉm cười đáp lại”." — "Tạo thiệp từ ảnh đã chọn"
  - Footnote row gap 6: `sliders` 12 + "Bạn chọn chủ đề hiện ở đây, ẩn hoặc sửa bất cứ lúc nào." 11 Medium muted (cropped by the panel at desktop).
- Floating chips: (−8, 340) `eye` on `var(--peach-soft)` "Có lý do cho từng gợi ý"; (342, 400) `sliders` on `var(--sunshine-soft)` "Ẩn hoặc sửa bất cứ lúc nào".

CTA row `735:6220` (gap 16, align center): **`<a>` "Nút · Khám phá Lumi"** (`var(--mint-deep)`, padding 14 × 22, radius 999, 16 SemiBold + `arrow-right` 16) "Khám phá Lumi" → `/lumi/`; caption 13 Medium muted "Ví dụ minh hoạ. Lumi hỗ trợ nhập chữ và ảnh; bạn kiểm tra và bấm lưu."

### 6.2 Mobile `736:66185` (390 × 1502)

Gradient angle 101° (same stops); padding 56 × 20, gap 28.
- Header: Lumi button **40**; eyebrow text **"Lumi · trợ lý trong Child Life"** (lower-case "trợ lý" — differs from desktop); H2 28 (2 lines); lead 16.
- Demo → **column**, gap 12. Panels 350 wide, radius **24**, padding **20 16 0**: head title **18** (wraps; head 65 / 88 high); stage **318 × 400**; mocks **300** wide at x 9 (inner rows 268 wide, parent bubble text 188.4); everything else same strings and styles; floats move to (−8, **270**) and (**117**, **330**) in panel A, (−8, 270) and (**112**, 330) in panel B. Panel B is 526 high (head wraps more).
- CTA → **column**, gap 10: button then caption (wraps, full width).

---

## 7. Section 6 · Tiện ích khác

### 7.1 Desktop `735:6226` (1440 × 799)

`background: linear-gradient(to bottom, #F7FCFA, #FFFAF2)` **(raw)**; column gap 44, padding 96.

Header (no lead): eyebrow (mint) "Tiện ích"; H2 "Và những tiện ích nhỏ cho mỗi ngày."

"Lưới" `742:66722`: two rows (gap 24) of four cards (gap 24) → 4 × 300 + 3 × 24 = **1272** (24 px wider than 1248 — §Ambiguities). Card: `var(--surface)`, radius 24, padding 24, column gap 12, width 300, shadow-card, equal height per row (row 1 = 168, row 2 = 189 because one body wraps).
- Top row: icon box (padding 14, radius 18, icon 24) + spacer + chip (`var(--cloud)`, padding 4 × 9, radius 999, 11 SemiBold `var(--ink-muted)`).
- Title 18 Bold lh 1.3 `var(--ink)`; body 14 Medium lh 1.5 `var(--ink-muted)`.

| # | Node | Icon / tint | Chip | Title | Body |
|---|---|---|---|---|---|
| 1 | 742:66724 | `clock` / `var(--care-bottle-soft)` | "Cữ tiếp · 11:30" | "Nhắc bú, ngủ" | "Nhắc đúng cữ cho người đang chăm." |
| 2 | 742:66733 | `star` / `var(--sunshine-soft)` | "Biết lẫy ✓" | "Mốc phát triển" | "Đánh dấu và lưu những lần đầu." |
| 3 | 742:66741 | `today` / `var(--mint-soft)` | "Tuần 16" | "Gợi ý theo tuổi" | "Mỗi tuần, điều thường gặp ở tuổi bé." |
| 4 | 742:66750 | `bookmark` / `var(--peach-soft)` | "Cháo bí đỏ" | "Thư viện chăm bé & ăn dặm" | "Bài ngắn, công thức theo giai đoạn." |
| 5 | 742:66759 | `alert` / `var(--error-soft)` | "Hóc dị vật" | "Sơ cứu trẻ em" | "Hướng dẫn từng bước khi cần gấp." |
| 6 | 742:66768 | `grid` (drawn in `var(--care-growth-ink)`) / `var(--care-growth-soft)` | "289.000đ" | "Sổ chi tiêu cho bé" | "Ba mẹ cùng xem tiền đã chi cho con." |
| 7 | 742:66779 | `sliders` / `var(--care-sleep-soft)` | "Chế độ đêm" | "Tuỳ chỉnh & chế độ đêm" | "Chỉ hiện điều bạn cần; dịu mắt ban đêm." |
| 8 | 742:66790 | `clock` / `var(--care-diaper-soft)` | "Ghi 1 chạm" | "Apple Watch" | "Ghi nhanh ngay trên đồng hồ." |

Icon ink is not exposed for most (SVG strokes); follow the tint's `-ink` (as `IconBox` does).

**`<a>` "Nút · Xem tất cả trong Năm đầu đời"** `735:6282`: outline (`var(--surface)`, 1 px `var(--control-border)`, radius 999, padding 14 × 22, gap 8): "Xem tất cả trong Năm đầu đời" 15 SemiBold `var(--ink)` + `arrow-right` 16 → the Năm đầu đời page. Cards are not links (proposal: each could deep-link to its section on the Năm đầu đời page).

### 7.2 Mobile `736:66283` (390 × 967)

Same gradient; padding 56 × 20, gap 28; H2 28.
- Grid: **2 columns** of 170 (gap 12; rows gap 12) = **352** wide (2 px wider than 350). Card: radius **20**, padding **16**, gap **8**; icon box padding **10** radius **14** icon **20**; **the chips are hidden**; title **15** Bold lh 1.3; body **12** Medium lh 1.5. Order and strings as desktop (rows: 1-2, 3-4, 5-6, 7-8).
- Button unchanged.

---

## 8. Section 7 · Hành trình khi con lớn

### 8.1 Desktop `736:65411` (1440 × 700)

No fill (page `var(--cloud)`); column gap 44, padding 96.

Header: eyebrow (mint) "Hành trình"; H2 (760) "Con lớn, hành trình vẫn tiếp tục."; lead "Hôm nay Child Life dành cho năm đầu đời. Những chặng sau đang được phát triển cùng các gia đình."

"Chặng" → one row, gap 24, four cards 297 wide (4 × 297 + 3 × 24 = **1260**, 12 px over). Card: `var(--surface)`, radius 24, overflow clip, padding-bottom 20, column gap 10, equal height (307).
- Card 1 **`<a>`** `736:65419`: **2 px solid `var(--mint)`** border + shadow `0 8 24 rgba(23,61,68,.08), 0 1 2 rgba(23,61,68,.06)`.
- Card 2 **`<a>`** `736:65453`, cards 3 `736:65488` and 4 `736:65529` (not links in Figma): **1 px dashed `#D1D9E5`** (raw) border, no shadow.
- Art 297 × 154 (clip; image 297 × 171.4 at y −8.7) → `assets/figma/journey-art-stage{1..4}.svg` (same illustrations as today's `Chapters`).
- Body (padding 0 18, column gap 6):
  - Status chip (padding 3 × 9, radius 999, gap 6, icon 11, 11 SemiBold): card 1 `var(--mint-deep)` bg, `check`, "Đang có trong app" `var(--on-mint-deep)`; cards 2–4 `var(--surface-2)` bg, `clock`, "Đang phát triển" `var(--ink-muted)`.
  - Label 12 SemiBold muted; title 19 Bold lh 1.25 `var(--ink)`; description 14 Medium lh 1.5 muted:
    1. "Chặng 1 · 0–12 tháng" · "Những ngày đầu đời" · "Chăm con, hiểu con và giữ kỷ niệm năm đầu."
    2. "Chặng 2 · 1–3 tuổi" · "Con tập khám phá" · "Chơi, tập nói và những thói quen đầu tiên."
    3. "Chặng 3 · 3–6 tuổi" · "Tò mò và lớn khôn" · "Câu hỏi “vì sao”, tranh vẽ và lời con kể."
    4. "Chặng 4 · 6–12 tuổi" · "Thế giới riêng của con" · "Sở thích, dự án nhỏ và kế hoạch của con."

Targets (proposal): card 1 → Năm đầu đời page; cards 2–4 → the existing stage pages (`stage2..4` routes). Figma links only cards 1–2 — decide whether 3–4 link too (§Ambiguities).

### 8.2 Mobile `736:66345` (390 × 743)

Padding 56 × 20, gap 28; H2 28; lead 16.
- **2 × 2 grid**, cards 169 wide, gap 12 (rows gap 12). Card radius **20**, pb **14**; art **169 × 88** (image 169 × 97.6 at y −4.8); body padding 0 **12**, gap 6: chip, label 12, title **15** Bold lh 1.25. **Descriptions hidden.** Card 1 keeps the mint border + shadow; others dashed. (No `<a>` in the mobile layers; links should match desktop.)

---

## 9. Section 8 · Miễn phí, niềm tin & hỏi đáp

### 9.1 Desktop `735:6445` (1440 × 978)

`var(--surface)`; column gap 44, padding 96.

Header (no lead): eyebrow (mint) "Miễn phí & niềm tin"; H2 (820) "Bắt đầu miễn phí. Gia đình bạn giữ quyền kiểm soát." (2 lines).

"Bốn ý" `735:6448`: row gap 24, four equal cards (flex 1 → 294): `var(--cloud)`, radius 24, padding 24, column gap 10; icon box (`var(--mint-soft)`, padding 8, radius 12, icon 16); text 15 SemiBold lh 1.5 `var(--ink)`:
1. `check` — "Ghi chép, nhắc nhở, mốc phát triển và kỷ niệm cơ bản dùng miễn phí."
2. `spark` — "Lumi có sẵn với số lượt dùng miễn phí giới hạn mỗi tháng."
3. `star` — "Cần thêm lượt? Có thể chọn gói Lumi cao hơn bất cứ lúc nào."
4. `lock` — "Gia đình chọn ai được xem ảnh và thông tin của con."

"Hỏi đáp" `735:6470` (proposed id `#hoi-dap`): column gap 12, **width 900** (left-aligned). Items: `var(--surface)`, radius 20, padding 20 × 24; question row gap 12: question 17 SemiBold lh normal `var(--ink)` (flex 1) + icon 16.
- **Open** item (1 px `var(--mint)` border, gap 10): `close` icon; answer 15 Medium lh 1.55 muted.
- Closed items (1 px `var(--separator)` border): `plus` icon.

1. "App hiện dành cho bé mấy tuổi?" — **open** — "Hiện Child Life tập trung vào năm đầu đời, từ khi con chào đời đến 12 tháng. Các chặng sau đang được phát triển."
2. "Có mất phí không?" — answer **not drawn**
3. "Ông bà và người chăm dùng thế nào?" — answer **not drawn**
4. "Ai xem được ảnh và thông tin của con?" — answer **not drawn**
5. "Hết lượt Lumi thì sao?" — answer **not drawn**

Use native `<details>` like `Faq.tsx` (answers in HTML for SEO). No FAQ title / "Còn điều gì băn khoăn?" sub in V8 (today's `Faq` renders its own header — needs a headless variant).

### 9.2 Mobile `736:66501` (390 × 1044)

Padding 56 × 20, gap 28; H2 28 (3 lines).
- "Bốn ý" → **column** gap 12; each card a **row**: `var(--cloud)`, radius **20**, padding **16**, gap 10, align center (icon left, text 15 SemiBold flex 1).
- FAQ width 350, gap 12; items radius **16**, padding **16**; question **15** SemiBold; answer 15 lh 1.55. Same strings, item 1 open.

---

## 10. Section 9 · Kết (`#tai-app`)

### 10.1 Desktop `735:6497` (1440 × 532)

`var(--surface)`; padding 24 96 96.

Card "Thẻ" `735:6498`: `#163D44` (raw), **radius 40**, padding 56, row gap 48, align center, width 1248.
- Copy "c" (column gap 16, width 620):
  - Title 40 Bold lh 1.18 white: "Bắt đầu từ năm đầu đời của con." (renders "Bắt đầu từ năm đầu đời của / con." at 620 — consider `text-wrap: balance`)
  - Sub 17 Medium lh 1.55 `#CCE0E0`: "Ghi chép, nhắc nhở và kỷ niệm — cả nhà cùng một nơi."
  - **V8/CTA tải app** instance `735:6502`, *Sau ra mắt · Ngang*, with the caption colour **overridden to `#CCE0E0`** (badges stay white).
- Photo `735:6518` 420 × 300, radius 28, `var(--surface-2)` behind; Illustration/Photo tone **sun** (image 420 square at y −60; the Figma placeholder shows a teddy-bear plush in a basket) → `photos.sun` (Teddy on the couch) or `teddy-one-plush.jpg` (closer to the drawn subject).

### 10.2 Mobile `736:66553` (390 × 336.9)

`var(--surface)`; padding 8 20 48. Card `#163D44`, radius **28**, padding **28 × 20**, column; copy width 310 gap 16: title **28** lh 1.18; sub **15**; CTA variant **Sau ra mắt · Dọc** (caption `#CCE0E0`). **Photo hidden.**

---

## 11. Footer

### 11.1 Desktop `735:6525` (1440 × 184.2)

No fill; column gap 56, padding 32 96 40.
- Separator 1 px `var(--separator)` full width.
- "Bottom" (padding-top 28, `justify-content: space-between`, align center):
  - Left row gap 16: Lockup at 0.8 (mark 27.2, wordmark 105.9 × 21.2) + "© 2026 Child Life" 14 Medium `var(--ink-muted)`.
  - Right links row gap 28, 14 Medium muted: "Quyền riêng tư" · "Điều khoản" · "Liên hệ" (→ privacy page, terms page, `mailto:` as today).

### 11.2 Mobile `736:66574` (390 × 230)

`var(--surface)` (desktop has none); column gap 12, padding **28 20 110** (the 110 bottom leaves room for the sticky bar). **No separator.**
- Lockup at **full size** (mark 34, wordmark 132.4 — larger than the desktop footer's).
- One text line 14 Medium muted: "Quyền riêng tư · Điều khoản · Liên hệ" — implement as three links with "·" separators.
- "© 2026 Child Life" **13** Medium muted.

Keep the existing footer language link and the non-prod environment tag (additions).

---

## 12. Mobile sticky bar `736:66587` "Thanh tải app cố định · hiện sau hero" (390 × 74)

Fixed to the bottom of the viewport. `var(--surface)`, shadow `0 -4px 8px rgba(0,26,26,.12)` (raw), row gap 10, align center, padding **10 16 26** (26 = home-indicator area → use `calc(10px + env(safe-area-inset-bottom))`).
- Lockup at 0.6 (mark 20.4, wordmark 79.4 × 15.9).
- spacer.
- Button "Nút · Tải miễn phí" `736:66599`: `var(--mint-deep)`, padding 10 × 16, radius 999; "Tải miễn phí" 14 SemiBold `var(--on-mint-deep)`.

Behaviour (only "hiện sau hero" is specified): hidden while the hero is on screen; slides in once the hero's CTA has scrolled out; proposal — also hide while the Kết card (`#tai-app`) is visible and when the mobile menu is open; mobile only (no desktop equivalent). Button target: the store for the visitor's platform once listings exist (iOS → App Store, Android → Google Play, else `#tai-app`); **pre-launch see §C rule** — a "Tải miễn phí" button that only says "sắp có" is forbidden by the component note, so before launch the bar must say "Nhận tin ra mắt" and scroll to the email form, or not render. Must not cover the toast / language-suggestion aside (stack them above it).

---

## C. Component `734:5426` "V8/CTA tải app"

Figma description (verbatim): "Trước ra mắt: chỉ dùng khi đã có luồng đăng ký email thật. Sau ra mắt: nút App Store / Google Play dẫn thẳng tới trang ứng dụng. Không dùng nút “Tải ngay” rồi báo “sắp có”."

Properties: **Trạng thái** = `Sau ra mắt` | `Trước ra mắt`; **Bố cục** = `Ngang` | `Dọc`. Root: column, gap 10, align start; children = "Hàng" + caption.

| Variant | Node | Size | "Hàng" | Contents | Caption |
|---|---|---|---|---|---|
| Sau ra mắt · Ngang | 734:5374 | 411.4 × 93 | row, gap 12, align center | App Store + Google Play badges (large) | "Tải miễn phí trên iPhone và Android." |
| Trước ra mắt · Ngang | 734:5390 | 482 × 77 | row, gap 12, align center | email field (300 wide) + "Nhận tin ra mắt" button | "Chỉ dùng email để báo khi app ra mắt. Huỷ bất cứ lúc nào." |
| Sau ra mắt · Dọc | 734:5400 | 339.25 × 80.86 | **row**, gap 12, align start (badges still side by side, just smaller) | App Store + Google Play badges (small) | "Tải miễn phí trên iPhone và Android." |
| Trước ra mắt · Dọc | 734:5416 | 367 × 139 | **column**, gap 12, width 350 | email field (full width) above a full-width button | "Chỉ dùng email để báo khi app ra mắt. Huỷ bất cứ lúc nào." |

Caption: 13 Medium lh normal `var(--ink-muted)` (instances on the dark Kết card override it to `#CCE0E0`).

**Store badge** (both "Sau ra mắt" variants): `background: #FFFFFF` (raw white, not `--surface`), overflow clip, row align center, text `#141417` (raw), column text lh normal: prefix "Tải trên" Medium, name SemiBold ("App Store" / "Google Play"); Apple / Play glyphs.
- Large (Ngang): radius 16.1, padding 11.5 23 11.5 18.4, gap 11.5, glyph 25.3, prefix 12.65, name 21.85.
- Small (Dọc): radius 13.2, padding 9.43 18.86 9.43 15.09, gap 9.43, glyph 20.75, prefix 10.37, name 17.92.
These are exactly today's `.badges--light .badge` sizes (small < 1120 px, large ≥ 1120 px in `styles/layout.css`). The glyphs are placeholders: official Apple / Google badge artwork must replace them before launch (existing `StoreBadges` note). No border or shadow — on the white / near-white hero they read as white pills on a pale gradient.

**Email field "Ô email"**: `var(--surface)`, 1 px `var(--control-border)`, radius 999, padding 15 × 18, gap 8; icon **`journal`** 16 (should be `mail`, §Ambiguities) + placeholder "Email của bạn" 15 Medium `var(--ink-muted)`. Width 300 (Ngang) / 100 % (Dọc).

**Button "Nút · Nhận tin ra mắt"**: `var(--mint-deep)`, radius 999, padding 15 × 24, centred; "Nhận tin ra mắt" 16 SemiBold `var(--on-mint-deep)`. Width hug (Ngang) / 100 % (Dọc).

Not drawn: label (placeholder only — add a visually hidden `<label>`), focus ring, invalid email, sending, success ("đã đăng ký"), already subscribed, server error, consent / privacy link, how to unsubscribe; dark-background variant (the Kết card would need the field on `#163D44`).

Where it is used: Hero (Ngang desktop / Dọc mobile) and Kết (Ngang / Dọc, caption `#CCE0E0`). Both instances are set to **Sau ra mắt**.

Implementation rule (from the description + `site.ts`): render "Sau ra mắt" only when `storeLinks.appStore` / `googlePlay` are real URLs (badges are plain `<a>` to the store pages); render "Trước ra mắt" only when a real email sign-up endpoint exists; **never** a badge that opens a "sắp có" toast (today's `StoreBadges` does exactly that when `storeLinks` is null — must change). With neither available, the CTA cannot be shown — owner decision (§Claims 1).

---

## R. Reuse map

| V8 section | Reuse / adapt | New |
|---|---|---|
| Nav | `components/Chrome.tsx` `Nav` (sticky, scroll-spy `data-spy`, `#tai-app` CTA, EN switch, `Lockup`) — new link list/labels, button label "Bắt đầu" | Mobile "Menu" button + panel (open state, focus handling); `nav.links` keys change (§Copy) |
| CTA tải app | `components/StoreBadges.tsx` + `.badges--light` CSS (sizes already match Ngang/Dọc) | `AppCta` wrapper (badges + caption, `layout: 'row' \| 'stack'`, `tone: 'light' \| 'dark'` for the caption); pre-launch email form (backend, privacy, states); remove the "coming soon" toast path |
| 1 Hero | `sections/JourneyHero.tsx` (same `journey-landscape.svg`, node and chip coordinates, float cards 1–2 via `.journey-card`, `Fit`, `Photo`, `IconBox`), `styles/journey.css` `.journey-hero*` | Status chips (mint-deep chip 1), video float card (could reuse `Keepsakes` video pill styles), support line, "Xem app hoạt động", "Tầm nhìn" caption; `mobileScale` 0.5645 |
| 2 Ba giá trị | `IconBox`, `Photo`, row style close to `.cocare` feed rows / `mock.tsx` `QuickRow` | Whole section (3 cards + mobile rows) |
| 3 Kỷ niệm | `sections/Keepsakes.tsx` `Mock` compositions 0 (video), 1 (card), 3 (then/now) — rescale with `Fit` (they are 432 × 280; V8 frames are 616 × 430, 560 × 160 crop, 260 × 150); `scenes.firstYearVideo`, `thenBaby`, `nowBaby`; `home.keepsakes.mock.*` strings | Bento layout, album mini-composition, "Còn có" strip, mobile row list with 110 px thumbs |
| 4 Cả nhà cùng chăm | `components/Bullets.tsx` (icon + text rows), `kit` `IconBox`/`Chip` | Scenario strip (3 cards + arrows, vertical on mobile) |
| 4 Trên cổ tay | `sections/Watch.tsx` `Watch` + `HomeFace` (W01 tiles = `home.watch.mock.tiles`), `.watch-band` dark styles, glow | Platform chips; Wear OS round watch; drop the 4 bullets / BreastFace / NotifyFace |
| 5 Lumi | `sections/LumiDetail.tsx` `LumiHero` chat (`.lp-chat`, `Ask`, `Reply`, `Draft` from `Lumi.tsx`, `.lp-float`), `kit` `LumiMascot`; `sections/ForBaby.tsx` `TodayCard` (export it) + `.today-card` CSS; strings `lumiPage.hero.mock.*`, `forBaby.mock.*` | Two gradient panels with clipped stages, new floats ("Có lý do…", "Ẩn hoặc sửa…"), CTA caption |
| 6 Tiện ích | `kit` `IconBox` / `Chip`; card style close to `.utilities__cards` / `Everything` tiles | 4 × 2 grid (2 × 4 mobile, chips hidden) |
| 7 Hành trình | `sections/Chapters.tsx` (stage data `c.journey.stages`, art imports, `pathOf(stageIds[i])` links, `.chapters` CSS) | Simpler card (status chip, no thumb / chip row / link label), dashed borders, 2 × 2 mobile |
| 8 Miễn phí & hỏi đáp | `sections/Faq.tsx` (`<details>`, plus/chevron icons, `items` prop) | Four-point cards; FAQ without its own header (add a `headless` prop or render the list only); open-state `close` icon if the design is followed |
| 9 Kết | `sections/Cta.tsx` (`id="tai-app"`, reveal) | Dark card with photo, `AppCta` |
| Footer | `Chrome.tsx` `Footer` (links, lang link, env tag) | Mobile stacked layout, full-size lockup |
| Sticky bar | — | New fixed bar + IntersectionObserver (hero / `#tai-app`) in `effects.ts` |

Today's `Home.tsx` (JourneyHero, Chapters, FirstYear, NextStages, GrowUp, Cta, Faq) becomes: Hero · Ba giá trị · Kỷ niệm · Cả nhà cùng chăm · Lumi · Tiện ích · Hành trình · Miễn phí & hỏi đáp · Kết. `FirstYear`, `NextStages`, `GrowUp`, `LumiBlock`, `ForBabyBlock`, `Utilities`, `Keepsakes` (as a section) leave the home (they may still serve stage / Lumi pages).

---

## S. Copy vs current site (`apps/landing/src/content/vi.ts`)

### S.1 Strings that already exist (reuse the key; `en.ts` has the same path)

| V8 string | Key path in `vi.ts` |
|---|---|
| "Kỷ niệm" | `nav.links.memories` |
| "Năm đầu đời" | `nav.links.firstYear` |
| "Hỏi đáp" | `nav.links.faq` |
| "Hành trình" | `nav.links.journey` / `journey.label` |
| "Tải miễn phí" (sticky bar) | `nav.download` |
| "Tải trên", "App Store", "Google Play" | `stores.appStore`, `stores.googlePlay` |
| "Bú bình · 120 ml" | `home.hero.art.feed.title` (also `lumiPage.hero.mock.drafts[0].title`) |
| "Lần đầu con cười" / "Đã lưu vào Kỷ niệm" | `home.hero.art.smile.title` / `.sub` |
| "Chăm con mỗi ngày" | `journey.stages[0].chips[0]` |
| "Bú bình 120 ml" | `cocare.feed.rows[…][0]` |
| "Ngủ 1 giờ 20 phút" | `quick.large.recent[…].label` |
| "Thay tã" | `hero.today.tiles.diaper.label`, `lumiPage.hero.mock.drafts[2].title` |
| "Mẫu · Năm đầu đời", "Lần đầu biết lẫy · 4 tháng", "0:16 / 0:45", "Nhạc: Ru con nhẹ nhàng", "3 cột mốc" | `home.keepsakes.mock.video.template` / `.caption` / `.time` / `.music` / `.milestones` |
| "100 ngày", "Teddy · 18.01.2027", "1 tháng" / "100 ngày" / "Lần đầu biết lẫy", "Lưu ảnh PNG" | `home.keepsakes.mock.card.title` / `.sub` / `.options` / `.save` |
| "1 tháng", "12 tháng", "Tạo video chuyển cảnh", "Lưu ảnh ghép" | `home.keepsakes.mock.thenNow.then` / `.now` / `.video` / `.collage` |
| "Sách năm đầu đời" | `home.keepsakes.cards[5].title` |
| "Cả nhà cùng chăm" | `everything.tiles[…].title` |
| "Apple Watch" | `home.watch.eyebrow` |
| "Teddy", "9:41", watch tiles (Bú bình 2:15 từ cữ trước … Nhắc 17:00 nhắc bú) | `home.watch.mock.baby` / `.time` / `.tiles` |
| "Lumi", "Trợ lý của nhà Teddy", "Con bú 120 ml lúc 9h, ngủ từ 9h30, thay tã lúc 10h", "Mình soạn 3 bản nháp, bạn xem lại rồi lưu nhé:", drafts, "Nháp", "Lưu cả 3", "Mấy hôm nay con hay khó ngủ buổi tối", reply 2, "Kể, hỏi hoặc gửi ảnh cho Lumi…" | `lumiPage.hero.mock.name` / `.family` / `.ask` / `.reply` / `.drafts` / `.draft` / `.saveAll` / `.ask2` / `.reply2` / `.composer` |
| "Bạn xác nhận trước khi lưu" | `lumiPage.hero.promises[0]` |
| "Hôm nay của Teddy", "Thứ Năm · 3 điều đáng chú ý", "Ví dụ minh hoạ", "Vì sao bạn thấy thẻ này", the three cards (title / body / why / action), footnote | `forBaby.mock.name` / `.date` / `.sample` / `.why` / `.cards[0..2]` / `.footnote` |
| "Khám phá Lumi" | `home.lumi.cta` |
| "Mốc phát triển" | `everything.tiles[…].title` |
| "Sơ cứu trẻ em" | `home.utilities.cards[0].title` |
| "Hóc dị vật" | `firstAid.card.topics[0]` |
| "Chế độ đêm" | `home.yourWay.bullets[1].title` |
| "Cháo bí đỏ" | `home.lumi.mock.meals[0]` |
| "Chặng 1 · 0–12 tháng" | `home.firstYear.detail.eyebrow` (or build from `journey.number` + `journey.stages[i].ages`, which gives all four labels) |
| Stage names | `journey.stages[0..3].name` |
| "Có mất phí không?" | `faq.items[1].q`, `home.faq.items[3].q` (answers exist but conflict, §Claims) |
| "© 2026 Child Life", "Quyền riêng tư", "Điều khoản", "Liên hệ" | `footer.copyright` / `.privacy` / `.terms` / `.contact` |

### S.2 Near matches — same idea, different text (use the V8 text, new key)

| V8 | Today | Where |
|---|---|---|
| "Ba vừa ghi · 2 phút trước" | "Mẹ ghi · 2 phút trước" | `home.hero.art.feed.sub` |
| "Đã lưu 3 bản ghi" | "Đã lưu 3 bản ghi vào Nhật ký" | `lumiPage.hero.mock.saved` |
| "Chọn ảnh và mẫu, có ngay video đầy tháng, 100 ngày hay thôi nôi để gửi cả nhà." | "Chọn ảnh và mẫu, có ngay video đầy tháng." | `lumiPage.day.cards[…].body` |
| "Ai xem được ảnh và thông tin của con?" | "Ai được xem ảnh và thông tin của con?" (+ answer) | `faq.items[3]`, `home.faq.items[4]` |
| "App hiện dành cho bé mấy tuổi?" | "Child Life dành cho bé từ mấy tuổi?" / "Child Life dành cho bé mấy tuổi?" | `faq.items[0]`, `home.faq.items[1]` |
| "Hết lượt Lumi thì sao?" | "Hết lượt hỗ trợ thì sao?" (+ answer) | `lumiPage.faq.items[…]` |
| "Ông bà và người chăm dùng thế nào?" | "Ông bà không rành điện thoại có dùng được không?" (+ answer) | `faq.items[2]` |
| "Trợ Lý Lumi" | "Lumi" | `nav.links.lumi` |
| "Lumi · Trợ lý trong Child Life" | "Lumi · Trợ lý đồng hành trong Child Life" | `lumiPage.hero.eyebrow` |
| "Tiện ích" (eyebrow) | "Tiện ích cho ba mẹ" | `home.utilities.title` |
| "Nhắc bú, ngủ" | "Nhắc bú, ngủ theo giờ cố định hoặc sau lần ghi gần nhất." | `everything.tiles[…].body` |
| "Video kỷ niệm", "Thiệp cột mốc", "Ngày ấy & bây giờ" | "Câu chuyện kỷ niệm", "Phép màu cột mốc", "Ngày ấy và bây giờ" | `home.keepsakes.cards[0/1/3].title` |
| "289.000đ" | "289.000 ₫" | `home.lumi.mock.receipt.amount` (keep the site's "₫" format, §Ambiguities) |

### S.3 New strings

Everything not listed in S.1 is new — the full list with English drafts is §E (numbered E-01 … ). Suggested content keys follow a new `home.v8` (or replace `home`) object: `nav.links.{care,memories,lumi,firstYear,faq}`, `nav.start`, `nav.menuOpen/menuClose`, `appCta.{caption,email,emailLabel,notify,privacyNote}`, `home.hero.{eyebrow,title,lead,support,seeApp,vision,art.video,chips}`, `home.values.*`, `home.memories.*`, `home.family.*`, `home.wrist.*`, `home.lumi.*`, `home.tools.*`, `home.journey.*`, `home.trust.*`, `home.faq.items`, `home.end.*`, `stickyBar.cta`.

---

## E. English drafts (engineering drafts for owner review, D-012)

| # | Vietnamese (verbatim) | English draft |
|---|---|---|
| E-01 | Chăm sóc | Care |
| E-02 | Trợ Lý Lumi | Lumi assistant |
| E-03 | Bắt đầu | Get started |
| E-04 | (aria) Mở menu / Đóng menu — not in Figma | Open menu / Close menu |
| E-05 | Child Life · Bắt đầu từ năm đầu đời | Child Life · Starting with the first year |
| E-06 | Cùng chăm con, giữ từng khoảnh khắc con lớn lên. | Care for your baby together, and keep every moment as they grow. |
| E-07 | Ghi bú, ngủ, tã để cả nhà cùng theo dõi. Lưu ảnh, tạo video và giữ lại những lần đầu tiên của con. | Log feeds, sleep and diapers so the whole family can follow along. Save photos, make videos and keep your baby's firsts. |
| E-08 | Bắt đầu với năm đầu đời. Tiếp tục đồng hành khi con lớn. | Start with the first year. Stay with your child as they grow. |
| E-09 | Xem app hoạt động | See the app in action |
| E-10 | Ba vừa ghi · 2 phút trước | Dad logged it · 2 min ago |
| E-11 | Video đầy tháng của Teddy | Teddy's one-month video |
| E-12 | 0:45 · từ ảnh bạn chọn | 0:45 · from photos you picked |
| E-13 | 0–12 tháng · Đang có trong app | 0–12 months · In the app now |
| E-14 | 1–3 tuổi · Sắp tới / 3–6 tuổi · Sắp tới / 6–12 tuổi · Sắp tới ("Sắp tới") | 1–3 years · Coming up / 3–6 years · Coming up / 6–12 years · Coming up |
| E-15 | Hệ sinh thái đồng hành cùng con — từ ngày đầu đời đến khi trưởng thành. | A companion for your child — from their first days to growing up. |
| E-16 | Tải miễn phí trên iPhone và Android. | Free on iPhone and Android. |
| E-17 | Email của bạn | Your email |
| E-18 | Nhận tin ra mắt | Get launch news |
| E-19 | Chỉ dùng email để báo khi app ra mắt. Huỷ bất cứ lúc nào. | We'll only email you when the app launches. Unsubscribe any time. |
| E-20 | Child Life giúp gì | What Child Life does |
| E-21 | Child Life giúp gia đình bạn ba việc. | Child Life helps your family with three things. |
| E-22 | Mỗi phần đều dùng được ngay trong năm đầu đời của con. | Each one works from your baby's very first year. |
| E-23 | Ghi bú, ngủ, tã và đặt nhắc nhở. Cả nhà cùng biết con vừa được chăm thế nào. | Log feeds, sleep and diapers and set reminders. Everyone knows how the baby was just cared for. |
| E-24 | Tuần này của bé · 4 tháng | Baby's week · 4 months (Q-067 name "{Baby}'s week") |
| E-25 | Bé thường bắt đầu với lấy đồ vật. Gợi ý: đặt đồ chơi trong tầm tay. | Babies often start reaching for things. Tip: keep a toy within reach. |
| E-26 | Mốc: Biết lẫy | Milestone: Rolls over |
| E-27 | đã ghi | logged |
| E-28 | Hiểu con từng giai đoạn | Understand each stage |
| E-29 | Xem nhật ký, theo dõi mốc phát triển và tìm nội dung theo tuổi của bé. | Read the journal, track milestones and find content for your baby's age. |
| E-30 | Giữ những điều đáng nhớ | Keep what matters |
| E-31 | Lưu ảnh riêng tư, tạo thiệp và video từ những khoảnh khắc của con. | Save photos privately, and make cards and videos from your baby's moments. |
| E-32 | Kỷ niệm (eyebrow; same text as `nav.links.memories`, give it its own key) | Memories |
| E-33 | Những tấm ảnh hôm nay, thành kỷ niệm để mai này xem lại. | Today's photos, kept as memories to look back on. |
| E-34 | Chọn ảnh của con để tạo video đầy tháng, thiệp cột mốc hoặc lưu vào album riêng của gia đình. | Pick your baby's photos to make a one-month video or a milestone card, or save them to your family's private album. |
| E-35 | Video kỷ niệm | Memory videos |
| E-36 | Chọn ảnh và mẫu, có ngay video đầy tháng, 100 ngày hay thôi nôi để gửi cả nhà. | Pick photos and a template and get a video for one month, 100 days or the first birthday to share with the family. |
| E-37 | Xem video mẫu | Watch a sample |
| E-38 | Thiệp cột mốc | Milestone cards |
| E-39 | Tròn tháng, 100 ngày, lần đầu biết lẫy — chọn mẫu và ảnh, gửi cho ông bà. | One month, 100 days, first roll-over — pick a template and photos and send it to the grandparents. |
| E-40 | Chọn mẫu và ảnh, gửi cho ông bà. (mobile) | Pick a template and photos, send it to the grandparents. |
| E-41 | Ngày ấy & bây giờ | Then & now |
| E-42 | Đặt hai tấm ảnh cạnh nhau để thấy con lớn thế nào. | Put two photos side by side to see how much your baby has grown. |
| E-43 | Hai tấm ảnh, thấy con lớn thế nào. (mobile) | Two photos, and you see how they've grown. |
| E-44 | Album gia đình riêng tư | Private family album |
| E-45 | Ông bà ở xa vẫn theo dõi cháu. | Grandparents far away can still follow along. |
| E-46 | B (avatar) / Bà nội đã xem 3 ảnh mới | G / Grandma viewed 3 new photos |
| E-47 | Còn có: | Also: |
| E-48 | Nhật ký của con | Your baby's journal |
| E-49 | Lời nhắn cho con | Messages for your child |
| E-50 | Sắp có | Coming soon |
| E-51 | Xem các mẫu kỷ niệm | See memory templates |
| E-52 | Ba vừa ghi, mẹ đã thấy. Không ai phải hỏi lại. | Dad logs it, Mom sees it. No one has to ask again. |
| E-53 | Ghi và xem chung một nhật ký. | Log and read one shared journal. |
| E-54 | Nhắc nhở đúng người đang chăm bé. | Reminders go to whoever is caring for the baby. |
| E-55 | Ba mẹ, người chăm và người thân có quyền xem khác nhau. | Parents, caregivers and relatives each see what's right for them. |
| E-56 | Bạn chọn ai được xem ảnh và thông tin của con. | You choose who sees your baby's photos and details. |
| E-57 | B / Ba · 09:00 / Ba ghi cữ bú | D / Dad · 09:00 / Dad logs a feed |
| E-58 | Bú bình 120 ml — một chạm là xong. | Bottle, 120 ml — one tap and it's done. |
| E-59 | M / Mẹ · 09:01 / Mẹ thấy ngay | M / Mom · 09:01 / Mom sees it right away |
| E-60 | “Ba vừa ghi: Bú bình 120 ml lúc 9:00.” | “Dad just logged: Bottle, 120 ml at 9:00.” |
| E-61 | Cả nhà / Không cần hỏi lại | Family / No need to ask |
| E-62 | Cữ tiếp theo đã có nhắc cho người đang chăm. | The next feed already has a reminder for whoever is caring. |
| E-63 | Trên cổ tay | On your wrist |
| E-64 | Đang bế con? Ghi ngay trên đồng hồ. | Holding your baby? Log it on your watch. |
| E-65 | Một chạm để ghi bú, ngủ, tã — cả nhà thấy ngay trên điện thoại. | One tap to log a feed, sleep or diaper — the family sees it on their phones right away. |
| E-66 | Đồng hồ Android (Wear OS) · Sắp có | Android watches (Wear OS) · Coming soon |
| E-67 | Wear OS / Đang ngủ (round-watch tile) | Wear OS / Asleep |
| E-68 | Lumi · Trợ lý trong Child Life | Lumi · The assistant in Child Life |
| E-69 | Nhắn một câu, Lumi lo phần ghi chép. | Send one message, Lumi does the logging. |
| E-70 | Lumi soạn nháp từ lời bạn nhắn và trả lời từ nhật ký của con. Khi mở app, bạn cũng thấy gợi ý liên quan đến những gì đã ghi. | Lumi drafts entries from your messages and answers from your baby's journal. When you open the app, you also see suggestions based on what you've logged. |
| E-71 | Bạn nhắn, Lumi lo phần ghi | You message, Lumi logs |
| E-72 | Một câu thành nhiều bản ghi. Hỏi là có câu trả lời từ nhật ký. | One sentence becomes several entries. Ask, and the answer comes from the journal. |
| E-73 | Đã lưu 3 bản ghi | 3 entries saved |
| E-74 | Bạn mở app, điều cần xem đã có | Open the app, and what you need is already there |
| E-75 | Gợi ý xuất hiện kèm lý do — vì những gì bạn đã ghi. | Suggestions come with a reason — based on what you've logged. |
| E-76 | Có lý do cho từng gợi ý | A reason for every suggestion |
| E-77 | Ẩn hoặc sửa bất cứ lúc nào | Hide or change them any time |
| E-78 | Ví dụ minh hoạ. Lumi hỗ trợ nhập chữ và ảnh; bạn kiểm tra và bấm lưu. | Illustrative example. Lumi takes text and photos; you check and tap save. |
| E-79 | Tiện ích (eyebrow) | Tools |
| E-80 | Và những tiện ích nhỏ cho mỗi ngày. | And small tools for every day. |
| E-81 | Nhắc bú, ngủ / Nhắc đúng cữ cho người đang chăm. / Cữ tiếp · 11:30 | Feed & sleep reminders / On-time reminders for whoever is caring. / Next feed · 11:30 |
| E-82 | Đánh dấu và lưu những lần đầu. / Biết lẫy ✓ | Mark and keep the firsts. / Rolls over ✓ |
| E-83 | Gợi ý theo tuổi / Mỗi tuần, điều thường gặp ở tuổi bé. / Tuần 16 | Tips for your baby's age / Each week, what's common at your baby's age. / Week 16 |
| E-84 | Thư viện chăm bé & ăn dặm / Bài ngắn, công thức theo giai đoạn. | Baby care & solids library / Short reads and recipes for each stage. |
| E-85 | Hướng dẫn từng bước khi cần gấp. | Step-by-step help when it's urgent. |
| E-86 | Sổ chi tiêu cho bé / Ba mẹ cùng xem tiền đã chi cho con. / 289.000đ | Baby expenses / Parents see together what's been spent on the baby. / 289,000 ₫ (locale-formatted) |
| E-87 | Tuỳ chỉnh & chế độ đêm / Chỉ hiện điều bạn cần; dịu mắt ban đêm. | Customise & night mode / Show only what you need; easy on the eyes at night. |
| E-88 | Ghi nhanh ngay trên đồng hồ. / Ghi 1 chạm | Quick logging right on your watch. / One-tap log |
| E-89 | Xem tất cả trong Năm đầu đời | See everything in The first year |
| E-90 | Con lớn, hành trình vẫn tiếp tục. | Your child grows, and the journey goes on. |
| E-91 | Hôm nay Child Life dành cho năm đầu đời. Những chặng sau đang được phát triển cùng các gia đình. | Today Child Life is for the first year. The next stages are being built together with families. |
| E-92 | Đang có trong app / Đang phát triển | In the app now / In development |
| E-93 | Chăm con, hiểu con và giữ kỷ niệm năm đầu. | Care for and understand your baby, and keep the first year's memories. |
| E-94 | Chơi, tập nói và những thói quen đầu tiên. | Play, first words and first habits. |
| E-95 | Câu hỏi “vì sao”, tranh vẽ và lời con kể. | “Why?” questions, drawings and your child's own stories. |
| E-96 | Sở thích, dự án nhỏ và kế hoạch của con. | Hobbies, small projects and your child's own plans. |
| E-97 | Miễn phí & niềm tin | Free & trusted |
| E-98 | Bắt đầu miễn phí. Gia đình bạn giữ quyền kiểm soát. | Start for free. Your family stays in control. |
| E-99 | Ghi chép, nhắc nhở, mốc phát triển và kỷ niệm cơ bản dùng miễn phí. | Logging, reminders, milestones and basic memories are free. |
| E-100 | Lumi có sẵn với số lượt dùng miễn phí giới hạn mỗi tháng. | Lumi comes with a limited number of free uses each month. |
| E-101 | Cần thêm lượt? Có thể chọn gói Lumi cao hơn bất cứ lúc nào. | Need more? You can move to a bigger Lumi plan at any time. |
| E-102 | Gia đình chọn ai được xem ảnh và thông tin của con. | Your family chooses who sees your baby's photos and details. |
| E-103 | App hiện dành cho bé mấy tuổi? | What age is the app for right now? |
| E-104 | Hiện Child Life tập trung vào năm đầu đời, từ khi con chào đời đến 12 tháng. Các chặng sau đang được phát triển. | For now Child Life focuses on the first year, from birth to 12 months. The later stages are in development. |
| E-105 | Có mất phí không? (existing key) | Does it cost anything? (use `en.ts` `faq.items[1].q`) |
| E-106 | Ông bà và người chăm dùng thế nào? | How do grandparents and caregivers use it? |
| E-107 | Ai xem được ảnh và thông tin của con? | Who can see my baby's photos and details? |
| E-108 | Hết lượt Lumi thì sao? | What happens when I run out of Lumi uses? |
| E-109 | Bắt đầu từ năm đầu đời của con. | Start with your baby's first year. |
| E-110 | Ghi chép, nhắc nhở và kỷ niệm — cả nhà cùng một nơi. | Logs, reminders and memories — the whole family in one place. |

FAQ answers 2–5 are not in Figma (gap). Proposed Vietnamese (PROPOSED, needs owner approval) with English:
- Q2 "Có mất phí không?" — VI: "Ghi chép, nhắc nhở, mốc phát triển và kỷ niệm cơ bản dùng miễn phí cho cả gia đình. Lumi có số lượt miễn phí mỗi tháng; cần nhiều hơn thì nâng cấp gói." / EN: "Logging, reminders, milestones and basic memories are free for the whole family. Lumi has free uses every month; upgrade if you need more." (depends on Claims 3–5)
- Q3 "Ông bà và người chăm dùng thế nào?" — VI: "Ba mẹ mời ông bà, người thân hoặc người chăm vào gia đình. Người chăm ghi và xem việc chăm bé hằng ngày; ông bà, người thân xem ảnh và câu chuyện ba mẹ chia sẻ." / EN: "Parents invite grandparents, relatives or a caregiver to the family. Caregivers log and see the daily care; grandparents and relatives see the photos and stories parents share."
- Q4 — reuse `home.faq.items[4].a` ("Chỉ những người bạn mời vào gia đình. …").
- Q5 — reuse `lumiPage.faq.items` "Hết lượt hỗ trợ thì sao?" answer: "Bạn vẫn ghi trực tiếp và xem nhật ký như bình thường; hướng dẫn sức khoẻ thiết yếu vẫn mở. Lượt được làm mới đầu kỳ tiếp theo." (EN from `en.ts`).

---

## K. Claims to check against `docs/product/business-map.md`

1. **Store availability / CTA** — "Tải miễn phí trên iPhone và Android.", App Store / Google Play badges, sticky "Tải miễn phí": `site.ts` `storeLinks` are `null` (listings not published); Android release work is still planned (D-071, `android-plan.md`); the component note forbids a download button that reports "sắp có" (today's `StoreBadges` toast). The pre-launch alternative is an email sign-up, but R-170 records "No forms, no login" on the site and nothing exists to receive emails (privacy text, storage, unsubscribe). **Owner decision needed:** build the email capture (new R-entry, privacy review) or hide the CTA until listings exist.
2. **"… kỷ niệm cơ bản dùng miễn phí"** — implies paid keepsake tiers. Today Video kỷ niệm / Thiệp cột mốc (incl. ★ Cao cấp) are a free beta (D-068 #3, D-075 #1 beta may give all Premium free); when Cao cấp leaves the beta is open (Q-072); premium gating waits for the paid plan (Q-058).
3. **"Lumi có sẵn với số lượt dùng miễn phí giới hạn mỗi tháng."** — consistent with P-159 / D-075 #1 (Free 20 credits per calendar month, one household pool). The app hides credit counts on main screens (D-081) — the landing may still state the principle; owner to confirm.
4. **"Cần thêm lượt? Có thể chọn gói Lumi cao hơn bất cứ lúc nào."** — no purchase is possible: real Apple / Google payments are a later slice (D-074, `premium_billing` off); the app has one "Child Life Premium" (Free 20 / Premium 200), not "gói Lumi" tiers; SKUs and prices open (Q-071); Q-039 (v6 note) already flags the Free · Plus · Pro pricing. Conflict.
5. **FAQ "Có mất phí không?"** — the existing answers ("Không. Cả gia đình dùng miễn phí, đủ chỗ cho hàng nghìn ảnh…", `faq.items[1]`, `home.faq.items[3]`) contradict items 3–4; storage is 10 GB per family with +10 / +20 GB requests (Family entity, D-010), and generated cards/videos count toward it (D-068 #5).
6. **Apple Watch** — "Đang bế con? Ghi ngay trên đồng hồ.", "Một chạm để ghi bú, ngủ, tã — cả nhà thấy ngay trên điện thoại.", chip "✓ Apple Watch", "Ghi 1 chạm", "Ghi nhanh ngay trên đồng hồ.": the watch app runs in the simulator only and is not embedded in Runner / not linked to the phone (apple-watch-plan.md status 2026-10-12; P-142, Q-047); Q-039 (v5) flags "chỉ với một chạm" (bottle and diaper take two taps) and an unreleased watch app being advertised. The check-mark chip presents it as available.
7. **"Đồng hồ Android (Wear OS) · Sắp có"** + the Wear OS watch drawing — Q-048: a Wear OS app is **not in V1** (Android watches get mirrored phone notifications). "Sắp có" promises it. Conflict.
8. **"Bà nội đã xem 3 ảnh mới"** — seen receipts are not built (Q-009, R-171).
9. **"Nhắc nhở đúng người đang chăm bé." / "Nhắc đúng cữ cho người đang chăm." / "Cữ tiếp theo đã có nhắc cho người đang chăm."** — reminders gain an assignee (D-075 #5), but notifications fire only on the creating device (R-091); "choosing who is reminded" is in Q-039. Verify delivery to the assignee's device before claiming it.
10. **"Mẹ thấy ngay — “Ba vừa ghi: Bú bình 120 ml lúc 9:00.”"** — reads like a notification to Mẹ when Ba logs; no D/R entry for care-log notifications to other members (Q-039 lists "nhận nhắc… không lo ghi trùng"). The shared journal itself (realtime) is true.
11. **"Bạn chọn ai được xem ảnh và thông tin của con." / "Album gia đình riêng tư" / "Lưu ảnh riêng tư"** — new photos are shared with Gia đình by default (D-001); roles limit what caregivers and relatives see. Wording OK, but R-171 asks that privacy claims match the app.
12. **Video kỷ niệm (đầy tháng, 100 ngày, thôi nôi; music; "0:45 · từ ảnh bạn chọn") and Thiệp cột mốc ("Lưu ảnh PNG")** — in scope since D-068 (server Remotion render, portal templates incl. music, free beta). Q-039 (v5b) predates D-068; confirm the template set covers "thôi nôi" and PNG export.
13. **"Ngày ấy & bây giờ" (+ "Tạo video chuyển cảnh", "Lưu ảnh ghép")** — no D/R entry (Q-039 v5b).
14. **"Lời nhắn cho con"** — D-034 covers a one-way text message to parents attached to an item, not messages to the child; voice messages have no privacy / retention position (Q-039 v5b).
15. **"Sách năm đầu đời · Sắp có"** — no D/R entry (payment, print partner — Q-039 v5b); "Sắp có" is a roadmap promise.
16. **"Nhật ký của con"** — exists (Kỷ niệm tab Nhật ký, D-052). OK.
17. **"Sơ cứu trẻ em · Hướng dẫn từng bước khi cần gấp." / "Hóc dị vật"** — first aid is hidden on prod until a person with medical credentials approves the content (D-058); Q-039 (v4).
18. **"Sổ chi tiêu cho bé · Ba mẹ cùng xem tiền đã chi cho con."** — consistent with D-055 (Cùng nuôi; others only with granted rights). Q-039 (v4) flagged "cùng xem một sổ như nhau" — the V8 wording is safer.
19. **"Tuỳ chỉnh & chế độ đêm · Chỉ hiện điều bạn cần; dịu mắt ban đêm."** — Today customisation is per device (P-127); Night care is a palette (Q-039 v4 flagged "chữ to", not repeated here). OK.
20. **"Gợi ý theo tuổi · Mỗi tuần, điều thường gặp ở tuổi bé." / "Tuần này của bé · 4 tháng"** — name per Q-067 ("Tuần này của {bé}"); content shows a guidance footnote, not a review claim (D-082). OK.
21. **"Thư viện chăm bé & ăn dặm · Bài ngắn, công thức theo giai đoạn." and Lumi "Ý tưởng cho bữa tiếp theo … Dựa trên tuổi, món đã thử và phản ứng bạn ghi."** — solids library, recipes and personal suggestions are now decided (D-085, D-086, D-069 moves the library to Chăm sóc); Lumi itself has "no meal log or recipes yet" per P-157 (superseded in part) and Q-039 (v6) flags meal ideas avoiding a logged reaction. Confirm Lumi / Hôm nay surfaces these before claiming.
22. **"Hôm nay của bé" cards with reasons, heart / dismiss, topic hiding** — Q-039 (v6) lists per-card feedback and topic hiding and library content awaiting review.
23. **Lumi "Một câu thành nhiều bản ghi" / "trả lời từ nhật ký" / "Lumi hỗ trợ nhập chữ và ảnh"** — consistent with D-075, D-088 / P-167 (multi-entry logs, read cards). The app also has voice input in chat (D-081 mentions voice) — the landing under-claims, fine.
24. **"Hiện Child Life tập trung vào năm đầu đời, từ khi con chào đời đến 12 tháng." and "Chặng 1 · 0–12 tháng"** — editorial stages and milestones now reach 36 months (D-080). Not wrong for the product framing, but the FAQ answer understates the content.
25. **Roadmap / retention** — "Tiếp tục đồng hành khi con lớn.", "Hệ sinh thái đồng hành cùng con — từ ngày đầu đời đến khi trưởng thành.", Chặng 2–4 "Đang phát triển", "Những chặng sau đang được phát triển cùng các gia đình." — stages 2–4 are roadmap only (Q-039).
26. **"Ví dụ minh hoạ"** labels on mocks — D-082 removes "minh hoạ" labels inside the app; on the landing they mark illustrative mock-ups and stay (no conflict, noted for consistency).

---

## A. Ambiguities / design bugs

1. **Pre-launch CTA has no valid state** (§C, Claims 1): the only allowed pre-launch variant needs an email backend that does not exist; the sticky bar says "Tải miễn phí" regardless of state.
2. **Overflows on desktop**: Kỷ niệm grid 640 + 24 + 592 = 1256 (> 1248; also Thiệp cột mốc card is 584 inside a 592 column); Tiện ích 4 × 300 + 3 × 24 = 1272 (+24); Hành trình 4 × 297 + 3 × 24 = 1260 (+12); Lumi panels 1232 (−16). Mobile Tiện ích 2 × 170 + 12 = 352 (+2). Implement with fluid grids (`repeat(4, 1fr)`) inside the 1248 container.
3. **Hero right padding** is 84 (copy 600 + gap 40 + visual 620 from x 96); every other section uses 96.
4. **Kỷ niệm card heights**: Ngày ấy 261 vs Album 240 in the same row (`align-items: start`), and the video card (583) vs right column (535) — bottoms do not align. Recommend stretching to equal heights.
5. **Illegible mobile text inside scaled illustrations**: hero chips 6.8 px and float text 6.8–7.9 px; Kỷ niệm video 8.3–11.3 px; list thumbnails 4.3–10 px; round watch labels 6.25 px. Treat these as decorative images (`aria-hidden`) and accept, or redraw mobile versions with fewer, larger labels.
6. **Mobile Album thumbnail**: "B · Bà nội đã xem 3 ảnh mới" (~150 px) in a 110 px box — overflows / clips.
7. **Watch W01**: the "Nhắc" tile uses `Icon/ruler` (the growth icon) — should be `clock` (or a bell); the running "Ngủ" tile puts a sleep-accent icon circle on a sleep-accent tile (invisible circle); the screen crops row 3. Today's `HomeFace` has the same data — keep its icon choice.
8. **Wear OS drawing and chip** contradict Q-048 (Claims 7) — likely to be removed after owner review; build the round watch as an optional piece.
9. **Email field icon** is `Icon/journal`; should be `mail` (available in the Icon map).
10. **Form states missing** (label, focus, error, sending, success, duplicate, consent / privacy link, dark-card variant).
11. **"Dọc" naming**: *Sau ra mắt · Dọc* is not vertical — the two badges stay side by side at the smaller size; only *Trước ra mắt · Dọc* stacks.
12. **Store badge artwork** is placeholder (white pill with a generic glyph); Apple and Google require their official badges.
13. **Nav capitalisation**: "Trợ Lý Lumi" (title case) vs sentence case elsewhere ("Trợ lý của nhà Teddy"); the Lumi eyebrow is "Trợ lý" on desktop and "trợ lý" on mobile. Recommend "Trợ lý Lumi" and one eyebrow string.
14. **Status wording for the same stages differs**: hero chips "Sắp tới", Hành trình chips "Đang phát triển", today's NextStages "Sắp ra mắt", Còn có chip "Sắp có".
15. **Links**: only nav Lumi / Năm đầu đời, "Khám phá Lumi", "Xem tất cả trong Năm đầu đời" and Hành trình cards 1–2 are links; cards 3–4 are not although stage pages exist; "Xem video mẫu" has no sample video; "Xem các mẫu kỷ niệm" has no gallery; "Xem app hoạt động" has no target. Proposals in each section.
16. **FAQ**: only answer 1 drawn; the open item uses `close` while closed items use `plus` (today's Faq uses plus → chevron); no FAQ heading or contact line (today's Faq has both).
17. **Mobile menu open state** not drawn; **language switch** missing from both navs (D-012 requires it — keep the current EN switch).
18. **Sticky bar rules** beyond "after hero" not drawn (hide near `#tai-app`, with the menu open, z-order vs toast / language suggestion, safe-area).
19. **Footer**: desktop lockup 27.2 vs mobile 34 (mobile larger); desktop has a separator and no fill, mobile no separator and `--surface`.
20. **Currency**: "289.000đ" vs the site's "289.000 ₫" — use the locale formatter / "₫".
21. **Layer names** "Mock · Chat với Chi" / "Chi" (old assistant name) — the visible text is "Lumi"; ignore the names.
22. **Desktop mocks are clipped** at the panel bottom (Lumi chat 625 → 470, Today 746 → 470; Today footnote invisible) — intentional crop; reproduce with `overflow: hidden` and no bottom padding.
23. **Mobile-only additions**: Ba giá trị icons (`feed`, `star`, `heart`); **mobile-only removals**: Ba giá trị pictures, Tiện ích chips, Hành trình descriptions, Kết photo. Mobile Kỷ niệm copy is shorter for two cards (S.2 / E-40, E-43).
24. **Hero third float** changed from "Bà nội thương ảnh của Teddy" to the video card; `home.hero.art.love` becomes unused.
25. **Kết photo subject**: the placeholder shows a plush teddy bear in a basket; the site's `sun` tone maps to a photo of Teddy on a couch — pick deliberately (`teddy-one-plush.jpg` is closer).
26. **No tablet frame**: between 390 and 1440 the 4-column grids need an intermediate (2-column) layout; reuse the current breakpoints (1120 px for badges).
