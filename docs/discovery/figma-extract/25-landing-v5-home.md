# 25 — Landing v5 home page (Trên cổ tay / Apple Watch)

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only, no node modified). Extracted 2026-10-12. Same conventions as `22-landing-v4-home.md` / `14-landing-v3-home.md`: token names from `07-foundations-components-motion.md` / `packages/design-tokens/dist/tokens.css`, non-token values marked **(raw)**, every visible string copied **verbatim from `get_design_context`**. Layer names are stale (e.g. the FAQ subtitle layer is named "Chưa thấy câu trả lời? Gửi cho…" but renders "Còn điều gì băn khoăn? Cứ nhắn cho chúng tôi nhé."; FAQ items 5–9 are all named "Có cần ghi đủ mỗi ngày không?").

> File number: `23-apple-watch.md` and `24-app-update.md` already exist, so this doc takes **25**. It continues the landing series 14 → 22 → 25.

- Desktop frame `475:3726` "Landing v5 · Desktop" — 1440 × 8082.2. **Desktop only — there is no v5 mobile frame.** §6 is a mobile *proposal*, not a design.
- v5 = v4 home (`459:3538`, spec `22`) **plus one new section "Trên cổ tay"** (Apple Watch) inserted between Tiện ích cho ba mẹ and Theo cách của bạn, a **6-link nav** (+ "Apple Watch") and a **9th FAQ question**. Everything else is pixel-identical (§1).
- As before: no prototype links, no motion, no hover/focus states, no tablet frame. Light page, static state. Page background `cloud` #F6FCFB. **New: the watch section is the first full-bleed dark band on the home page** (all other sections are transparent over `cloud`).

Screenshots (not committed, 1:1 at 1440 wide): `scratchpad/v5/d-tren-co-tay.png` (1440 × 754), `d-nav.png` (1440 × 87), `d-hoi-dap.png` (1440 × 980); full frames used for the diff in `scratchpad/v5/full/v4-full.png`, `v5-full.png`.

Method: metadata trees of v4 `459:3538` and v5 `475:3726` normalised (ids stripped, coords rounded) and diffed per section → only Nav and Hỏi đáp differ structurally; then both frames rendered whole at 1:1 with `get_screenshot` and **pixel-diffed per section** (BMP, threshold 24/255, ±1 row tolerance for the 8082 → 8083 render rounding) → every other section has **0 differing rows** (this also rules out same-size text edits that metadata cannot show). `get_design_context` read in full: the new section `475:4503`, Nav `475:3727`, Hỏi đáp `475:4453`. `download_assets` on `475:4503`: **no raster images** (`rawImages: []`); only icon vectors and one gradient ellipse.

---

## 0. Global

### 0.1 Section order

| # | Section | v5 node | h (y) | v4 node | Status | Id (today / proposed) |
|---|---|---|---|---|---|---|
| 1 | Nav | 475:3727 | 87 (0) | 459:3539 | **changed** — 6 links (§2) | — |
| 2 | Hero | 475:3740 | 644 (87) | 459:3551 | identical | `#gioi-thieu` |
| 3 | Hành trình | 475:3812 | 806 (731) | 459:3623 | identical | `#hanh-trinh` |
| 4 | Năm đầu đời | 475:3913 | 1678 (1537) | 459:3724 | identical | `#nam-dau-doi` |
| 5 | Sức khoẻ | 475:4103 | 680 (3215) | 459:4166 | identical | `#suc-khoe` |
| 6 | Tiện ích cho ba mẹ | 475:4255 | 816 (3895) | 459:4168 | identical | `#tien-ich` |
| 7 | **Trên cổ tay** | **475:4503** | **754 (4711)** | — | **new** (§3) | **`#apple-watch`** (proposed, §5) |
| 8 | Theo cách của bạn | 475:4332 | 620 (5465) | 459:4342 | identical | `#theo-cach-cua-ban` |
| 9 | Lớn lên cùng con | 475:4408 | 466 (6085) | 459:3914 | identical | `#lon-len` |
| 10 | CTA | 475:4431 | 367 (6551) | 459:3937 | identical | `#tai-app` |
| 11 | Hỏi đáp | 475:4453 | **980** (6918) | 459:3959 (900) | **changed** — 9 questions (§4) | `#hoi-dap` |
| 12 | Footer | 475:4493 | 184.2 (7898) | 459:3991 | identical | — |

Page height 7248.2 → 8082.2 (+754 new section, +80 one FAQ row).

Vertical rhythm: Tiện ích ends with its 72 bottom padding → **dark band** `96 / 96` (hard top and bottom edges, no radius) → Theo cách (96 top). In `Home.tsx` the new section goes between `<Utilities />` and `<YourWay />`.

### 0.2 Colours used by the new section

| Use | Value | Token |
|---|---|---|
| Section background (full bleed 1440) | #163D44 **(raw)** | ≈ `ink` / `card-night` / `nav-bar` #173D44 (1 off in red). Use `var(--ink)` like `.grow-up__band` and `.btn--ink`; the difference is invisible. |
| Eyebrow pill | `sunshine` #FFD166 bg, `ink` text | tokens — **new eyebrow tone** (existing `sun` = sunshine-soft/growth-ink, `sun-ink` = sunshine-soft/ink) |
| H2, bullet titles | #FFFFFF | (raw) white |
| Lead, note text | rgba(255,255,255,0.75) **(raw)** | — |
| Bullet subs | rgba(255,255,255,0.65) **(raw)** | — |
| Bullet icon box | rgba(255,255,255,0.10) **(raw)**, icon stroke white | — |
| Note pill bg | rgba(255,255,255,0.08) **(raw)** | — |
| Glow ellipse | radial #FACC5C @ 35 % → #FACC5C @ 0 % **(raw)** | close to `sunshine` but not equal |
| Watch body | #292B2E **(raw)** | — |
| Watch crown | #4D4F52 **(raw)** | — |
| Watch screen | #000000 | — |
| Watch tiles / secondary buttons | #1F2124 **(raw)** | — |
| Watch care colours | `care-bottle-accent` #3B8FD9, `care-breast-accent` #E07A9A, `care-sleep-accent` #6C6FD8, `care-diaper-accent` #5DAA4E, `care-pump-accent` #B068C9 (Figma var `care/pump/accent`), `care-growth-accent` #E8894A | Light values of the tokens (the landing is pinned to `data-theme="light"`, so `var(--care-*-accent)` resolves to these). Note: the real watch app uses the **Night care** values (§8). |
| Watch notification app chip | `mint-deep` #087F7B | token |
| "Dừng" button | #DB4A45 | `danger` |

### 0.3 Text styles
No new font size on the copy side — same scale as the v4 split sections, recoloured for a dark background:

| Use | Font | Colour |
|---|---|---|
| Eyebrow | SemiBold 13 / normal, `padding: 6px 12px; radius 999` | `sunshine` / `ink` |
| H2 | Bold 44 / 1.18, tracking 0, nowrap, **hard line break** | white |
| Lead | Medium 18 / 1.55, 460 wide | white 75 % |
| Bullet title / sub | SemiBold 16 / normal · Medium 14 / 1.5, gap 3 | white · white 65 % |
| Note pill | SemiBold 13 / normal, `padding: 8px 14px; radius 999` | white 75 % on white 8 % |

### 0.4 Shadows
**None** in the section (the watches have no drop shadow; depth comes from overlap, 85 % opacity on the side watches and the glow).

### 0.5 Icons (app set `apps/mobile/assets/icons/`, stroke 1.8 at 24, scaled)
Used: check, clock, sleep, cloud-off (bullets, 18 / 1.35 white); feed, drop, sleep, **diaper**, ruler, clock (watch faces).

**Missing from the landing `Icon` map (`components/primitives.tsx`): `diaper`** (`apps/mobile/assets/icons/diaper.svg` exists) → one more `?raw` import. If the Nhắc tile follows the app instead of Figma (§8), also **`bell`** (`bell.svg` exists). Everything else (check, clock, sleep, cloud-off, feed, drop, ruler) is already mapped.

### 0.6 Assets
- **No raster** in the section (`download_assets` → `rawImages: []`). Nothing to `cmp` against `apps/landing/src/assets/figma/`; **no file added**.
- The glow is a single SVG circle with a radial gradient — build it in CSS, not as a file: `width/height: 460px; border-radius: 50%; background: radial-gradient(closest-side, rgba(250,204,92,.35), rgba(250,204,92,0));`.
- The watch faces contain live text → build them in HTML/CSS (recommended, translatable, crisp) — no export.

---

## 1. Unchanged sections (verified)

Hero, Hành trình, Năm đầu đời, Sức khoẻ, Tiện ích cho ba mẹ, Theo cách của bạn, Lớn lên cùng con, CTA and Footer: identical metadata **and 0 differing pixel rows** between v4 and v5 (only their y moved for the three sections below the insert). → `JourneyHero.tsx`, `Chapters.tsx`, `FirstYear.tsx`, `Health.tsx`, `Utilities.tsx`, `YourWay.tsx`, `GrowUp.tsx`, `Cta.tsx`, footer: **no change**; `22` §3–§5 remain the spec for the v4 sections.

---

## 2. Nav (475:3727, 1440 × 87) — changed

Geometry/styles identical to v4 (`padding: 22px 96px`, links `gap: 36px` Medium 15 / normal `ink-muted`, nowrap, 40 spacer, CTA pill `ink` / `surface` SemiBold 15 `padding: 12px 22px` **"Tải miễn phí"**). The links row grows 501 → **633** wide and starts at x **538** (was 670); the flex spacer shrinks 398 → 266.

Links, verbatim, in order: **"Hành trình" · "Năm đầu đời" · "Sức khoẻ" · "Tiện ích" · "Apple Watch" · "Hỏi đáp"**.
- Added: **"Apple Watch"** (96 px wide) between "Tiện ích" and "Hỏi đáp" → new key `nav.links.watch`.
- Unchanged: the other five (`nav.links.journey`, `firstYear`, `health`, `utilities`, `faq`).
- The hidden layer "Hỏi đáp" (hidden, x 437) is still there — ignore.

Targets and the width problem at 1120–1230 px: §5.

---

## 3. Trên cổ tay (475:4503, 1440 × 754) — NEW

```
section  background #163D44 (raw ≈ ink), full bleed
  display:flex; gap:80px; align-items:center; padding:96px;
  ├─ Copy 475:4504   flex:1 (= 608 at 1440), column, gap:28px, align-items:flex-start  (562 tall)
  └─ Watches 475:4542  560 × 560, position:relative (no clip)
```
The row is exactly **1248** wide (608 + 80 + 560), so it fills the standard `.container` — no 1216-in-1248 issue as in v4. Copy top y 96, watches top y 97 (both centred in the 562-tall row).

Implementation: full-bleed `<section id="apple-watch" class="section watch-band">` with `background: var(--ink)` and an inner `.container` flex row (`.split`-like, but copy-first and visual `flex: 0 0 560px`). The band needs `color-scheme`-independent white text (the page is light-only today).

### 3.1 Copy 475:4504 (`column; gap: 28px` — all five blocks are siblings, unlike v4's Head gap 16 + 36)
1. **Eyebrow** 475:4506 (108 × 28): `background: sunshine; color: ink;` SemiBold 13 **"Apple Watch"** → `Eyebrow tone="sunshine"` (new tone: `.eyebrow--sunshine { background: var(--sunshine); color: var(--ink); }`).
2. **H2** 475:4507 Bold 44 / 1.18 white, nowrap, 431 wide, **two `<p>` (hard break)**: **"Tay bế con,"** / **"vẫn ghi kịp từng cữ."** → store as a 2-item array like `home.utilities.title`; `.h2.h2--flat` + white.
3. **Lead** 475:4508 Medium 18 / 1.55, rgba(255,255,255,.75), **460 wide** (2 lines; the em dash starts line 2): **"Ghi bú, ngủ, tã ngay trên đồng hồ chỉ với một chạm — không cần tìm điện thoại."**
4. **Bullets** 475:4509 = **`CompactBullets` geometry exactly** (list gap 18; row gap 16, `align-items:flex-start`; box 36 = `padding 9; radius 12` + icon 18 / stroke 1.35; text gap 3; title SemiBold 16 / normal; sub Medium 14 / 1.5; nowrap), recoloured:

   | Icon (white) | Title | Sub |
   |---|---|---|
   | check | **"Ghi trong một chạm"** | **"Bú bình xoay núm chọn ml, tã ướt hay bẩn chỉ một lần chạm."** |
   | clock | **"Bấm giờ bú mẹ, ngủ, hút sữa"** | **"Đổi bên, dừng nhanh — kể cả chạm hai ngón khi tay bận."** |
   | sleep (moon) | **"Nhắc đúng lúc, xem nhanh"** | **"Thông báo có sẵn nút ghi; mặt đồng hồ hiện cữ trước bao lâu."** |
   | cloud-off | **"Không cần điện thoại bên cạnh"** | **"Ghi lưu trên đồng hồ, tự đồng bộ cho cả nhà khi có mạng."** |

   Box: rgba(255,255,255,.10), icon stroke white; title white; sub rgba(255,255,255,.65). Reuse `CompactBullets` with (a) a new `Tint` value, e.g. `'glass'` → `.tint--glass { background: rgba(255,255,255,.1); color: #fff; }`, and (b) a list modifier (`.bullets--on-dark`: title `#fff`, sub `rgba(255,255,255,.65)`), e.g. a `tone="dark"` prop. 4 items (v4 sections have 3) — the component already maps any length. `subShort` is required → drafts in §6.
5. **Note pill** 475:4541 (hug 337 × 32): `background: rgba(255,255,255,.08); padding: 8px 14px; border-radius: 999px;` SemiBold 13 / normal rgba(255,255,255,.75), nowrap: **"Dành cho Apple Watch, đi kèm ứng dụng iPhone"**. Close to `.eyebrow--on-dark` (white 12 % / #fff, 6/12 padding) but not equal → small new class (`.watch-band__note`).

### 3.2 Watches 475:4542 (560 × 560, decorative → `aria-hidden="true"`, like the v4 panels)

Composition (absolute, design px, in paint order — later on top):

| Layer | Node | Box (x, y, w × h) | Scale of base | Opacity |
|---|---|---|---|---|
| Glow ellipse | 475:4543 | 50, 50, 460 × 460 | — | 1 (gradient 35 % → 0) |
| Watch W07 (notification) | 475:4547 | **330, 180**, 224.2 × 262.2 | **×0.95** | **0.85** |
| Watch W03 (breast timer) | 475:4564 | **0, 180**, 224.2 × 262.2 | **×0.95** | **0.85** |
| Watch W01 (home) | 475:4588 | **132.5, 110**, 295 × 345 | **×1.25** | 1 |

W01 covers the inner halves of both side watches: visible are W03's left ~132 px ("Bú mẹ", the "Trái 8:12" tile, "Đổi bên", a sliver of "Dừng") and W07's right ~127 px (cut text "…nhắc bú bạn", "…5 · 120 ml", "…bình 120 ml", "…i sau 15 phút"). Build the full faces anyway — the cut is done by overlap, so English text lengths do not matter.

**Every watch is the same device drawn at a scale** — W01 ×1.25 and W03/W07 ×0.95 of the 46 mm Apple Watch frame of page `464:18` (`23-apple-watch.md`: screen 208 × 248 pt). Base geometry (scale 1):

| Part | Base value |
|---|---|
| Case | 236 × 276, `border-radius: 62px`, `background: #292B2E` (raw), `overflow: hidden` |
| Screen | inset 14 (208 × 248), `border-radius: 46px`, black, `overflow: hidden` |
| Digital Crown | 10 × 34, `border-radius: 4px`, `#4D4F52` (raw), at **left 234, top 70** of the case box (sticks out 8 px on the right; sibling of the case, not clipped) |

(Check: 13.3 / 0.95 = 17.5 / 1.25 = 14; 58.9 / 0.95 = 77.5 / 1.25 = 62; 43.7 / 0.95 = 57.5 / 1.25 = 46; crown 222.2 / 0.95 = 293 / 1.25 ≈ 234, 66.5 / 0.95 = 87.5 / 1.25 = 70.)

Recommendation: one `<Watch scale={…}>` component built at base size and scaled with `transform: scale(var(--s)); transform-origin: 0 0` inside a wrapper sized `236s × 276s` (the same `--s` pattern as `Toggle`), the three placed with `at()` inside a `Fit w={560} h={560}`. All values below are **base** (divide the Figma numbers by 1.25 for W01, by 0.95 for W03/W07).

#### W01 · Hôm nay (475:4589) — the front watch
Content `column; gap: 6px; padding: 8px 10px 10px;` (content is 297 tall in a 248 screen → **row 3 is cut by the screen edge**: only the Hút sữa / Nhắc headers and the top of their values show — a "scrolls" hint, keep the clip).
- Top `display:flex; align-items:center; padding: 6px 8px 0;` Bold 15 white **"Teddy"** · spacer · SemiBold 15 white **"9:41"**.
- 3 rows `display:flex; gap: 6px;` of 2 tiles. Tile `flex:1 (91 wide); column; gap: 2px; padding: 10px; border-radius: 20px; background: #1F2124 (raw);`
  - header `gap: 6px; align-items:center;`: icon chip `padding: 4px; border-radius: 999px; background: <accent>;` with a **black** 13 icon (stroke ≈ 1) + SemiBold 12 label in `<accent>`;
  - value Bold 16 white; caption Medium 11 rgba(255,255,255,.6).

  | Tile | Accent | Icon | Label | Value | Caption |
  |---|---|---|---|---|---|
  | 1 | `care-bottle-accent` | feed | **"Bú bình"** | **"2:15"** | **"từ cữ trước"** |
  | 2 | `care-breast-accent` | drop | **"Bú mẹ"** | **"3:35"** | **"từ cữ trước"** |
  | 3 · running | `care-sleep-accent` — **whole tile filled** | sleep | **"Ngủ"** | **"0:42"** | **"đang ngủ"** |
  | 4 | `care-diaper-accent` | **diaper** | **"Tã"** | **"1:25"** | **"từ lần trước"** |
  | 5 (cut) | `care-pump-accent` | drop | **"Hút sữa"** | **"5:10"** | **"từ lần trước"** |
  | 6 (cut) | `care-growth-accent` | ruler (layer `Icon/ruler`) | **"Nhắc"** | **"17:00"** | **"nhắc bú"** |

  **Design bug:** on the running Ngủ tile the icon chip and the "Ngủ" label use the same `care-sleep-accent` as the tile fill, so both are **invisible** in the render (only the black moon glyph shows). The watch app draws the running tile's label and icon **white** (white 22 % chip) — recommend that (§8, §10).

#### W03 · Bú mẹ · đang bấm giờ (475:4565) — left, behind
Content `column; gap: 8px; padding: 8px 10px 10px;` (176 tall).
- Top `padding: 6px 8px 0;` Bold 15 `care-breast-accent` **"Bú mẹ"** · spacer · SemiBold 15 white **"9:41"**.
- Sides `display:flex; gap: 6px;` two tiles `flex:1; column; align-items:center; padding: 8px 0; border-radius: 16px;`:
  - active: `background: care-breast-accent`, black text: SemiBold 12 **"Trái"**, Bold 20 **"8:12"**;
  - idle: `#1F2124`: SemiBold 12 rgba(255,255,255,.6) **"Phải"**, Bold 20 white **"4:20"**.
- Medium 11 rgba(255,255,255,.6), centred: **"Tổng 12:32 · đang bú bên trái"**.
- Actions `gap: 6px;` two pills `flex:1; padding: 10px; border-radius: 999px;` SemiBold 15 white: **"Đổi bên"** on `#1F2124`, **"Dừng"** on `danger` #DB4A45.

#### W07 · Nhắc bú · thông báo (475:4548) — right, behind
Content `column; gap: 8px; padding: 22px 10px 10px;` (211 tall).
- App row `gap: 6px; align-items:center;`: circle `padding: 4px; background: mint-deep;` with clock 12 white + SemiBold 11 rgba(255,255,255,.6) **"CHILD LIFE"** (uppercase in the source text).
- Bold 16 / 1.25 white, full width (2 lines): **"Đến giờ nhắc bú bạn đã đặt"**.
- Medium 12 rgba(255,255,255,.6): **"Cữ trước 14:45 · 120 ml"**.
- Two full-width pills `padding: 9px 10px; border-radius: 999px;` SemiBold 14, centred: **"Ghi bú bình 120 ml"** on `care-bottle-accent` with **black** text; **"Nhắc lại sau 15 phút"** on `#1F2124` with white text.

Reuse: the landing `Push` (`kit.tsx`) is an iOS banner (app icon, "bây giờ", 3 actions) — **not** reusable for W07; `QuickTile` / `CareTile` (`components/mock.tsx`) are the phone tiles (light, different sizes) — not reusable either. New small set: `.watch`, `.watch__screen`, `.watch__crown`, `.watch-tile`, `.watch-pill`. `Icon` covers every glyph once `diaper` is added.

---

## 4. Hỏi đáp (475:4453, 1440 × 980) — changed

Styles, left column and paddings (`48px 96px 112px`, row gap 80, left column 360) are unchanged: Bold 36 / 1.2 tracking −0.36 **"Câu hỏi thường gặp"** / Medium 16 / 1.5 **"Còn điều gì băn khoăn? Cứ nhắn cho chúng tôi nhé."** Item style unchanged (`surface`, 1 px `separator`, radius 20, `padding: 22px 24px`, question SemiBold 17, answer Medium 15 / 1.55 `ink-muted`, chevron-down when open / plus when closed). The list grows 740 → **820** (one more closed item, 68 tall + 12 gap).

All 9 items, verbatim:

| # | State | Question | Answer in Figma | vi.ts |
|---|---|---|---|---|
| 1 | open | "Child Life là gì?" | "Hệ sinh thái giúp cha mẹ chăm sóc, thấu hiểu và đồng hành cùng con qua từng chặng lớn lên. Ứng dụng hiện tập trung vào năm đầu đời của con." | `home.faq.items[0]` — unchanged |
| 2 | open | "Child Life dành cho bé mấy tuổi?" | "Từ ngày con chào đời. Năm đầu, app giúp cả nhà chăm con mỗi ngày; những chặng tiếp theo sẽ cùng con lớn lên đến tuổi trưởng thành." | `[1]` — unchanged |
| 3 | closed | "Khi con lớn, ảnh và hồ sơ của con có còn không?" | none | `[2]` — unchanged (PROPOSED answer) |
| 4 | closed | "Có mất phí không?" | none | `[3]` — unchanged |
| 5 | closed | "Ai được xem ảnh và thông tin của con?" | none | `[4]` — unchanged |
| 6 | closed | "Nội dung gợi ý trong app do ai soạn?" | none | `[5]` — unchanged |
| 7 | closed | "Sơ cứu trong app có thay thế bác sĩ không?" | none | `[6]` — unchanged |
| 8 | closed | "Ai xem được chi tiêu của gia đình?" | none | `[7]` — unchanged |
| 9 | closed | **"Có dùng Child Life trên Apple Watch được không?"** | none | **new `[8]`** — answer PROPOSED (§7) |

`Faq.tsx` needs no change; only `home.faq.items` grows (vi + en, D-012).

---

## 5. Section id and nav targets (proposal — Figma defines none)

| Nav link (vi.ts key) | Home | Stage pages (Chặng 1–4) |
|---|---|---|
| "Hành trình" (`nav.links.journey`) | `#hanh-trinh` | `${homePath}#hanh-trinh` (as today) |
| "Năm đầu đời" (`nav.links.firstYear`) | `#nam-dau-doi` | Chặng 1 page (as today) |
| "Sức khoẻ" (`nav.links.health`) | `#suc-khoe` | `${homePath}#suc-khoe` |
| "Tiện ích" (`nav.links.utilities`) | `#tien-ich` | `${homePath}#tien-ich` |
| **"Apple Watch"** (new `nav.links.watch`) | **`#apple-watch`** | **`${homePath}#apple-watch`** |
| "Hỏi đáp" (`nav.links.faq`) | `#hoi-dap` | `${homePath}#hoi-dap` on stages 2–4; Chặng 1 keeps its own `#hoi-dap` |
| "Tải miễn phí" | `#tai-app` | unchanged |

- **Id `apple-watch`**: the v4 ids are the slug of the nav label (`suc-khoe`, `tien-ich`); the label here is "Apple Watch", so `#apple-watch` is the guessable deep link (and the same in vi and en). Alternative `#tren-co-tay` (the frame name) — no visible text says "Trên cổ tay", so not recommended. No clash with existing ids (checked `src/sections/*.tsx`). Heading id `watch-title` for `aria-labelledby`.
- `Chrome.tsx` `links` gains one entry between utilities and faq: `{ label: l.watch, ...(onHome ? local('apple-watch') : { href: \`${homePath}#apple-watch\` }) }`. The scroll-spy then needs the dark band to set the active link like the others.
- **Width problem (implementation, not in Figma):** 6 links = 633 px. At the 1120 px breakpoint the container is 1120 − 2 × 74.7 (gutter `clamp(32px, 6.67vw, 96px)`) ≈ **971** px, but the nav needs 176 (lockup) + 633 + 40 + ≈ 215 (EN switch ≈ 70 + 12 + CTA 133) ≈ **1064** → **overflows from 1120 to ≈ 1230 px** (v4's 501 px fit). Options: (a) show the links from **1280** (below that the mobile nav: logo + EN + "Tải app"), simplest; (b) between 1120 and 1279 shrink `gap` 36 → 20 and `nav__actions` margin 40 → 24 (≈ 968, just fits in vi; en "Journey · First year · Health · Tools · Apple Watch · FAQ" is shorter); (c) drop the EN label to the globe icon. Recommend (a) or (b); confirm with design.

---

## 6. Mobile — PROPOSAL (no v5 mobile frame exists)

Derived from the v3 mobile frame `362:3398` and the split-section mobile rules (`12` §2–§5 mobile: "Head → Panel → Bullets", panels re-composed in flow at readable sizes) and `22` §8. Breakpoint as today (`< 1120`). Needs design sign-off.

**Trên cổ tay (mobile):** full-bleed dark band (`background: var(--ink)`, no radius — or the `.grow-up__band` radius-32 card inside the gutter if design prefers the existing dark-card pattern), `padding: 48px 20px;`, column, left-aligned:
1. **Head** `gap: 12px`: eyebrow unchanged; H2 Bold **30 / 1.2** white **keeping the hard break** (both lines fit: "vẫn ghi kịp từng cữ." ≈ 294 px at 30 px < 335); lead Medium 16 / 1.55 white 75 %.
2. **Watch** (gap 24 above/below), re-composed, not uniformly scaled: **W01 alone at base size ×1.0** (236 × 276 — the real 46 mm screen at 1 pt = 1 px, every text ≥ 11 px), centred over a 320 px glow (same gradient); W03 and W07 dropped. Composition box ≈ 335 × 300. Alternative (if design wants all three): `Fit w={560} h={560} mobileScale={0.598}` — but the side faces' text drops to ~6–9 px, purely decorative.
3. **Bullets** `CompactBullets` dark variant (mobile gap 16 from CSS), 4 items with `subShort` — engineering drafts (owner review):
   - "Ghi trong một chạm" → **"Xoay núm chọn ml, tã ướt hay bẩn một chạm."**
   - "Bấm giờ bú mẹ, ngủ, hút sữa" → **"Đổi bên, dừng nhanh khi tay bận."**
   - "Nhắc đúng lúc, xem nhanh" → **"Thông báo có nút ghi; mặt đồng hồ hiện cữ trước."**
   - "Không cần điện thoại bên cạnh" → **"Lưu trên đồng hồ, tự đồng bộ khi có mạng."**
4. **Note pill** SemiBold **12** (at 13 px the pill is 337 > 335 px), or allow wrapping with `border-radius: 16px`.

**Nav mobile:** unchanged (logo + EN + "Tải app", no links). **FAQ mobile:** 9 items, same text (the new question is short enough).

---

## 7. Copy keys (vi.ts) — what changes

| Area | Key (proposed) | Change / verbatim value |
|---|---|---|
| Nav | `nav.links.watch` | **new** "Apple Watch" (en "Apple Watch") |
| Watch section | `home.watch.eyebrow` | "Apple Watch" |
| | `home.watch.title` (2-item array) | "Tay bế con," / "vẫn ghi kịp từng cữ." |
| | `home.watch.lead` | "Ghi bú, ngủ, tã ngay trên đồng hồ chỉ với một chạm — không cần tìm điện thoại." |
| | `home.watch.bullets[4]{title,sub,subShort}` | §3.1 table (+ `subShort` drafts §6) |
| | `home.watch.note` | "Dành cho Apple Watch, đi kèm ứng dụng iPhone" |
| | `home.watch.mock.home` | `{ baby: 'Teddy', time: '9:41', tiles: [ {label:'Bú bình', value:'2:15', caption:'từ cữ trước'}, {label:'Bú mẹ', value:'3:35', caption:'từ cữ trước'}, {label:'Ngủ', value:'0:42', caption:'đang ngủ'}, {label:'Tã', value:'1:25', caption:'từ lần trước'}, {label:'Hút sữa', value:'5:10', caption:'từ lần trước'}, {label:'Nhắc', value:'17:00', caption:'nhắc bú'} ] }` |
| | `home.watch.mock.breast` | `{ title:'Bú mẹ', time:'9:41', left:'Trái', leftValue:'8:12', right:'Phải', rightValue:'4:20', total:'Tổng 12:32 · đang bú bên trái', switchSide:'Đổi bên', stop:'Dừng' }` |
| | `home.watch.mock.notify` | `{ app:'CHILD LIFE', title:'Đến giờ nhắc bú bạn đã đặt', sub:'Cữ trước 14:45 · 120 ml', log:'Ghi bú bình 120 ml', snooze:'Nhắc lại sau 15 phút' }` |
| FAQ | `home.faq.items[8]` | **new** q "Có dùng Child Life trên Apple Watch được không?", `open: false`, answer **PROPOSED** (G-065 pattern): "Có, nếu bạn dùng iPhone. Kết nối đồng hồ một lần từ ứng dụng trên iPhone, sau đó bạn ghi bú, ngủ, thay tã và bấm giờ ngay trên Apple Watch, kể cả khi điện thoại không ở bên cạnh. Hiện chưa có ứng dụng cho đồng hồ Android." — if the landing ships before the watch app, use "Sắp có. …" instead (§9). |
| Everything else | — | no change |

English (engineering drafts for owner review, D-012): title "Baby in your arms," / "every feed still logged."; lead "Log feeds, sleep and diapers right on your watch with one tap — no need to find your phone."; bullets "Log with one tap" / "Turn the crown to pick the bottle amount; wet or dirty diaper in one tap." · "Time breastfeeds, sleep and pumping" / "Switch sides or stop in a moment — even with a double tap when your hands are full." · "Timely reminders, quick glances" / "Notifications come with a log button; your watch face shows the time since the last feed." · "No phone needed nearby" / "Logs are saved on the watch and sync to the family once you're online."; note "For Apple Watch, works with the iPhone app"; FAQ "Can I use Child Life on Apple Watch?". **Mock en: reuse the watch app's own en strings** (`apps/mobile/ios/watch/Localizable.xcstrings`): "Bottle", "Breast", "Sleep", "Diaper", "Pumping", "Reminder", "since last feed", "since last time", "asleep", "feed reminder", "Left", "Right", "Total 12:32 · on the left", "Switch side", "Stop"; notification en from the ARB `ruleDueFeed` en.

---

## 8. Watch mock vs the real watch app (parity check)

The watch app exists as **uncommitted work** (`apps/mobile/ios/watch/` untracked in git; `docs/product/apple-watch-plan.md` untracked): target `watch`, scheme `watch-dev`, W01–W06, W11–W13 run in the **simulator only** with demo data. Strings in `ios/watch/Localizable.xcstrings` (generated by `tool/watch_strings.py`, 47 `watch*` ids in the ARB).

| Mock element | Watch app (`HomeView.swift`, `FlowViews.swift`, `WatchTheme.swift`) | Matches | Differs (landing → app) |
|---|---|---|---|
| W01 tile labels / captions | `watchTileBottle` … `watchTileReminder`, `watchSinceFeed` "từ cữ trước", `watchSinceLast` "từ lần trước", `watchSleeping` "đang ngủ", `watchFeedReminder` "nhắc bú" | all six labels and captions ✔ | — |
| Tile colours | `CareKind.accent` = **Night care** values (#5AA6E8, #E88AA8, #8A8DEB, #74BF63, pump **#B98AD6**, reminder #E8894A); tile `Color(white: 0.14)`, radius 18 | layout | Mock uses the **light** token values (#3B8FD9 …) and #1F2124 tiles, radius 20. Pump: app #B98AD6 ≠ token night `care-pump-accent` #C285DA ≠ light #B068C9 (an app-side drift, not a landing issue) |
| Tile icon chip | accent glyph on accent 22 % circle | — | Mock: **solid accent chip, black glyph** |
| Running Ngủ tile | filled accent, **white** label / icon (white 22 % chip), value counts h:mm:ss | filled tile ✔ | Mock label/chip accent-on-accent (invisible), value "0:42" (h:mm) |
| Nhắc tile icon | `Icon-bell` | — | Mock `Icon/ruler` (stale; `23-apple-watch.md` noted the same layer) |
| W03 | `watchSideLeft/Right` "Trái"/"Phải", `watchBreastTotalLeft` "Tổng {t} · đang bú bên trái", `watchSwitchSide` "Đổi bên", `watchStop` "Dừng", `WatchColor.danger` #DB4A45 | ✔ all | — |
| W07 notification | **not built** (plan step 5); server push title `ruleDueFeed` "Đến giờ nhắc bú bạn đã đặt" ✔ | title ✔ | Server body is "Lần bú gần nhất {time} · {ago}" (no ml; plan §4.8 draws "Cữ trước 14:45 · 120 ml" from the watch cache); the existing snooze action on iOS is **"Báo lại sau 15 phút"** (`RuleNotifications.swift`), mock says **"Nhắc lại sau 15 phút"** (= Figma W07) |

---

## 9. Copy claims vs `docs/product/business-map.md` and the repo (owner confirmation before prod; extend Q-039 / R-170)

Watch status: **P-142** (proposal, defaults owner-to-confirm), **Q-047** (priority: Wave 1 now or after S8 — open), Q-048 (Wear OS: default "not in V1"), Q-049 … Q-053, gaps G-092 … G-101. Plan build steps: 0 spikes (SW-1 … SW-4) open, 1 CareKit open, 2 targets partly, 3 Wave 1 screens in the simulator, **4 complications, 5 notifications, 6 pump + Double Tap, 7 voice, 8 device QA — not started**. Linking over WatchConnectivity and real writes to dev Firebase are **not verified**; the watch is **not embedded in Runner** yet; nothing is on TestFlight or the store. R-170 (landing scope) still describes v4 and must be updated (6-link nav, Trên cổ tay, 9 FAQ).

| # | Claim (verbatim) | Support | Conflict / over-claim |
|---|---|---|---|
| 1 | The whole section ("Tay bế con, vẫn ghi kịp từng cữ.", nav "Apple Watch") | P-142, plan | **Advertises an unreleased, uncommitted app.** Q-047 (priority) is open; prod landing must wait for the watch release or label it "Sắp có" (Q-039 / R-171 rule: landing claims are things the app must make true) |
| 2 | "…chỉ với một chạm" / "Ghi trong một chạm" — "Bú bình xoay núm chọn ml, tã ướt hay bẩn chỉ một lần chạm." | W02, W05 built | From the watch home, bottle = tile → crown → "Lưu" and diaper = tile → "Ướt"/"Bẩn" (2 taps each). "Một chạm" is true only inside the flow (or from a W07 action / complication, not built). Mild over-claim |
| 3 | "Bấm giờ bú mẹ, ngủ, hút sữa" | W03, W04 built | **Pump timer (W14) is Wave 2**, build step 6 — not built |
| 4 | "Đổi bên, dừng nhanh — kể cả chạm hai ngón khi tay bận." | P-142 (Double Tap also stops breast/sleep = **proposal**) | Double Tap not built (step 6), only Series 9 / 10 / 11 and Ultra 2 (Q-053). Wording: Apple's Vietnamese name is "Chạm hai lần" and Figma W14 says "chạm 2 lần để dừng"; **"chạm hai ngón" (two-finger tap) is a different gesture** → reword, e.g. "kể cả chạm hai lần khi tay bận" |
| 5 | "Thông báo có sẵn nút ghi" | P-142, plan §4.8 | W07 long-look actions **not built** (step 5) and depend on spike SW-2; today's iOS actions are "Ghi lần bú" (opens the app) and "Báo lại sau 15 phút" |
| 6 | "mặt đồng hồ hiện cữ trước bao lâu" | P-142 Wave 1 circular complication | **Not built** (step 4) |
| 7 | "Không cần điện thoại bên cạnh" — "Ghi lưu trên đồng hồ, tự đồng bộ cho cả nhà khi có mạng." | Plan §4.2 (watch talks HTTPS itself), §4.6 offline queue, W13 built | Unverified (SW-1); the watch must be **linked once from the iPhone** (G-092); "cho cả nhà" = members whose role sees care (D-018: relatives only with "Chăm sóc hằng ngày") |
| 8 | "Dành cho Apple Watch, đi kèm ứng dụng iPhone" / FAQ "Có dùng Child Life trên Apple Watch được không?" | Q-048 default (no Wear OS in V1) | Android users get no watch app (D-004 parity) — the FAQ answer should say so; P-142: only **Cùng nuôi and Người chăm sóc** use the watch (relatives do not) — consider saying "ba mẹ và người chăm bé" |
| 9 | Bullet "Nhắc đúng lúc, xem nhanh" uses the **sleep (moon)** icon; Nhắc tile uses **ruler** | — | Icon semantics: the app's reminder glyph is `bell`; recommend bell for both (add `bell` to the Icon map) |
| 10 | W03 / W01 show **"Teddy"** on the watch | Q-049 (name on always-visible faces) | Mock only — fine; Q-049 concerns complications |
| 11 | "Apple Watch", "iPhone" as nav label and copy | — | Apple trademark use: keep the exact spelling, never possessive/plural; the site has no trademark notice — consider "Apple Watch và iPhone là nhãn hiệu của Apple Inc." in the footer (legal/owner call) |
| 12 | FAQ 9 has no answer in Figma | G-065 (answers missing) | Draft in §7 must not promise unbuilt features (voice, pump, complications) |

---

## 10. Ambiguities, gaps and conflicts

**Design / implementation**
1. **No mobile frame** for v5 — §6 is engineering's proposal (W01 alone at true size; dark band in flow).
2. **Nav overflow 1120–≈1230 px** with 6 links — not visible in the 1440 frame; needs a breakpoint or spacing decision (§5).
3. **Ngủ running tile**: label and icon chip invisible (same colour as the fill) — design bug; recommend white as in the watch app.
4. **Nhắc tile icon** is the ruler (stale layer) — recommend `bell` like the app; bullet 3 uses a moon for reminders.
5. **Accent values**: the mock uses light care accents while the real watch uses Night care accents (§8); the side-by-side screenshot of the real app will look lighter/pastel. Design call: keep Figma (light tokens) or match the device.
6. **Section background #163D44** is raw, 1 off from `ink` #173D44 — use `var(--ink)`.
7. **Glow #FACC5C** is raw (not `sunshine` #FFD166) — keep raw in CSS or snap to `sunshine`.
8. **First full-bleed dark band** on the home page: the reveal/scroll-spy and the sticky frosted nav over a dark band need a check (nav background over dark content).
9. **Eyebrow tone `sunshine`** (solid), **dark CompactBullets**, **note pill** and the **watch kit** are new CSS; `Push`, `CareTile`, `QuickTile` are not reusable.
10. **Copy gap 28** (one flat column) differs from v4's Head 16 + 36 — follow the design.
11. W01 content is clipped mid-row by the screen (scroll hint) — keep `overflow: hidden` on the screen.
12. Side watches at 85 % opacity — apply opacity to the whole watch (case + crown), as in Figma (`opacity-85` on the wrapper).
13. **Snooze wording**: mock "Nhắc lại sau 15 phút" vs iOS action "Báo lại sau 15 phút".
14. **Spelling**: "Tã" / "hút sữa" etc. match the watch strings; "CHILD LIFE" is uppercase text in the source (not `text-transform`).

**Product (owner decisions before prod)**
1. Advertising the watch before it ships (Q-047 open; app uncommitted, simulator only) — hold the section for the watch release, or mark it "Sắp có".
2. Pump timer, Double Tap, notification actions and complications are **not built** (steps 4–6) — drop or soften those phrases until they ship.
3. "chạm hai ngón" → "chạm hai lần" (Apple's term, Figma W14).
4. "chỉ với một chạm" — two taps from the home screen for bottle and diaper.
5. FAQ 9 answer (PROPOSED §7) — iPhone only, no Wear OS (Q-048), who can use it (P-142).
6. Update R-170 (nav, new section, 9 FAQ) and add the landing watch claims to Q-039.
7. Trademark notice for "Apple Watch" / "iPhone".
