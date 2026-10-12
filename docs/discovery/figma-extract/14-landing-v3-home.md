# 14 — Landing v3 home page ("Hành trình lớn lên")

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only). Extracted 2026-10-11 with `get_design_context` on every desktop and mobile section (rendered text is authoritative — layer names are stale, e.g. the hero H1 layer is named "Con lớn từng ngày. Cả nhà lớn…" and the lead "Bớt phải nhớ chuyện bú ngủ, th…"), plus `get_metadata` for positions and the exported SVGs for icon stroke colours. Same conventions as `11-landing-specs.md` / `12-landing-v3-new-sections.md`: token names from `07-foundations-components-motion.md` / `packages/design-tokens/dist/tokens.css`, non-token values marked **(raw)**, Vietnamese text verbatim.

- Desktop frame `358:2901` "Landing v3 · Desktop" — 1440 × 4972.2.
- Mobile frame `362:3398` "Landing v3 · Mobile" — 375 × 5260.6.
- This is a **new, shorter home page**. The long feature page that is implemented today (`321:1222`, now renamed "Landing · Desktop v2.1 (tính năng)") reappears as **"Landing v3 · Chặng 1 · Desktop" `370:50752`** (12170 tall: Nav, Switcher, new Hero, then the v2.1 sections). Chặng 2–4 pages are `361:3457`, `361:3575`, `361:3693` (1440 × 1862). Those stage pages are **out of scope here**; they are the link targets of this page. No mobile frames exist for any stage page.
- As before: no prototype links, no motion, no hover/focus states, no tablet frame, no dark page. Light, static state only. Page background `cloud` #F6FCFB (verified from the render); every section is transparent over it.

Screenshots (not committed): `scratchpad/v3/h-d-{nav,hero,hanh-trinh,nam-dau-doi,lon-len,cta,faq,footer}.png` and `h-m-…png` (same names).

---

## 0. Global

### 0.1 Section order

| # | Section | Desktop node | Desktop h (y) | Mobile node | Mobile h (y) | Proposed id |
|---|---|---|---|---|---|---|
| 1 | Nav | 358:2902 | 87 (0) | 362:3399 | 66 (0) | — |
| 2 | Hero | 358:2923 | 644 (87) | 362:3403 | 710.4 (66) | `#gioi-thieu` |
| 3 | Hành trình | 359:2592 | 806 (731) | 362:3497 | 1013 (776.4) | `#hanh-trinh` |
| 4 | Năm đầu đời | 360:2568 | 1678 (1537) | 362:3556 | 1785 (1789.4) | `#nam-dau-doi` (family strip inside: `#gia-dinh`) |
| 5 | Lớn lên cùng con | 360:2693 | 466 (3215) | 362:3607 | 405 (3574.4) | `#lon-len` |
| 6 | CTA | 360:2788 | 367 (3681) | 362:3686 | 361.4 (3979.4) | `#tai-app` (keep) |
| 7 | Hỏi đáp | 360:2810 | 740 (4048) | 362:3704 | 767 (4340.8) | `#hoi-dap` (keep) |
| 8 | Footer | 360:2838 | 184.2 (4788) | 362:3728 | 152.8 (5107.8) | — |

Heights are hug-content; implement with paddings, not fixed heights (except the Hành trình cards, see §3).

### 0.2 Text styles introduced or changed on this page

| Name (proposed) | Font | Desktop | Mobile | Tracking | Colour |
|---|---|---|---|---|---|
| `display` (hero H1) | Bold 700 | **52 / 1.12**, 2 lines with a hard break | **36 / 1.15**, wraps (3 lines) | **0** (v2 hero: 57, −2 %) | `ink` (no mint lines any more) |
| hero lead | Medium 500 | 20 / **1.55** (v2: 20/32) | 16 / 1.55 | 0 | `ink-muted` |
| `h2` (Hành trình, Năm đầu đời) | Bold 700 | 44 / 1.18 | Hành trình **28 / 1.2**, Năm đầu đời **30 / 1.2** | 0 | `ink` |
| `h2` band (Lớn lên) | Bold 700 | **40 / 1.18** | **24 / 1.22** | 0 | white |
| `h2` CTA | Bold 700 | 44 / 1.18 | 28 / 1.2 | −0.66 / −0.28 | white (unchanged from v2) |
| `lead` | Medium 500 | 18 / 1.55 | 16 / 1.55 | 0 | `ink-muted` |
| `sub-title` (strip titles "Cả nhà cùng chăm…", "Những chặng tiếp theo") | Bold 700 | 22 / normal | 20 / normal | 0 | `ink` |
| `stage-title` (Hành trình cards) | Bold 700 | 22 / 1.25 | 18 / normal | 0 | `ink` |
| `stage-body` | Medium 500 | 15 / 1.55 | 14 / 1.5 | 0 | `ink-muted` |

Eyebrow pill geometry is unchanged (`padding: 6px 12px; radius 999`, SemiBold 13 / normal). Tones on this page: Hero, Hành trình, Năm đầu đời = `.eyebrow--mint` (`mint-soft` / `mint-text`); Lớn lên = **new** on-dark tone (`rgba(255,255,255,.12)` **(raw)** / white). The v2 hero eyebrow (`padding 8px 14px`, 14 px, "●  …") is **gone** — the v3 hero uses the normal 13 px pill.

### 0.3 Shadows
Only `shadow-card` is used (hero float cards; bento notification). No raw "float" shadows on this page. All other cards are flat with a 1 px `separator` border or a tinted fill.

### 0.4 Icons
All from `apps/mobile/assets/icons/` (already in the landing `Icon` map): plus, spark, memories, chevron-down, star, globe, feed, heart, arrow-right, sleep, clock, family, check, cake, bookmark, lock, cloud-off. Stroke = 1.8 at 24, scaled (e.g. 1.2 at 16, 1.5 at 20, 1.65 at 22, 1.95 at 26, 3 at 40, 1.05 at 14). **No new icons needed.**

---

## 1. Nav

### Desktop 358:2902 (1440 × 87)
Identical geometry and styles to v2/v3 (`11` §1): `padding: 22px 96px`, lockup, flex spacer, links row (gap 36, Medium 15 / normal `ink-muted`), 40 spacer, CTA pill `ink` / `surface` `padding: 12px 22px` SemiBold 15 **"Tải miễn phí"**.

Links (row 401 wide at x 770), verbatim: **"Hành trình" · "Năm đầu đời" · "Gia đình" · "Hỏi đáp"**. (A fifth layer "Hỏi đáp" `358:2910` is hidden — ignore.)

| Link | Target on the home page | Notes |
|---|---|---|
| Hành trình | `#hanh-trinh` (§3) | Same target as the hero "Xem hành trình của con" button. |
| Năm đầu đời | `#nam-dau-doi` (§4) | On the stage pages (`370:51712` etc.) the same nav is reused — there it should go to the Chặng 1 page or `/#nam-dau-doi`; Figma does not say (§10). |
| Gia đình | `#gia-dinh` = the "Cả nhà cùng chăm — ai cũng có chỗ bên con" strip inside §4 | v2/v2.1 pointed "Gia đình" at Cùng chăm, which now lives on the Chặng 1 page. |
| Hỏi đáp | `#hoi-dap` (§7) | — |
| Tải miễn phí | `#tai-app` (§6) | unchanged |

Implementation: `Chrome.tsx` `sectionIds` becomes route-dependent (home: `['hanh-trinh','nam-dau-doi','gia-dinh','hoi-dap']`). The current ids `cham-con`, `hieu-con`, `ky-niem`, `ban-dem` move with their sections to the Chặng 1 page; keep them there so old deep links resolve (redirect `/#cham-con` → Chặng 1 page if needed).

### Mobile 362:3399 (375 × 66)
Unchanged: lockup ×0.78 + `mint-deep` pill **"Tải app"** (`padding: 10px 16px`, SemiBold 14 `on-mint-deep`). No links, no menu.

---

## 2. Hero

### Desktop 358:2923 (1440 × 644)
`display:flex; align-items:center; gap:40px; padding: 40px 96px 24px;` → **Copy** `flex:1` (588 × 456) + **Illustration** 620 × 580.

Copy (`flex-direction:column; gap:22px; align-items:flex-start`):
1. Eyebrow `mint-soft` / `mint-text`: **"Child Life · Hành trình lớn lên"**
2. H1 Bold 52 / 1.12 `ink`, two lines (explicit break): **"Cùng con lớn lên,"** / **"đồng hành từng bước."** (116 tall)
3. Lead Medium 20 / 1.55 `ink-muted` (2 lines at 588): **"Hệ sinh thái giúp cha mẹ chăm sóc, thấu hiểu và đồng hành cùng con — từ những ngày đầu đời đến khi trưởng thành."**
4. **Promises** list (`column; gap:12px`). Row `gap:12px; align-items:center`: icon box 30 × 30 (`padding: 7px; border-radius: 10px`, tinted) with a 16 px icon (stroke 1.2) + SemiBold 16 / normal `ink`, `nowrap`:

   | Icon box | Icon (colour) | Text |
   |---|---|---|
   | `mint-soft` | plus (`mint-text`) | "Chăm sóc con mỗi ngày, cả nhà cùng phối hợp" |
   | `care-sleep-soft` | spark (`care-sleep-ink`) | "Thấu hiểu con qua từng giai đoạn lớn lên" |
   | `peach-soft` | memories (`care-bottle-ink`) | "Đồng hành và lưu giữ hành trình của con" |

   Reuse `IconBox` (`kit.tsx`) — needs a 30 px / radius-10 size variant.
5. **Explore button** 257 × 48: `background: ink; color: surface; padding: 14px 22px; border-radius: 999px; display:flex; gap:10px; align-items:center;` SemiBold 16 **"Xem hành trình của con"** + chevron-down 16 (white, 1.2). It is an in-page link to `#hanh-trinh` (the chevron points down).

**Removed vs v2.1 hero:** store badges, the "Miễn phí trên iPhone và Android." caption, the M·B·L·H proof row, both phones and the mint circle. The hero has no download action — downloads are the nav pill and the CTA band.

#### Illustration (620 × 580, `position:relative`; decorative, `aria-hidden`)

**Decision:** the scenery (sky, sun, clouds, hills, road) is static vector art → one SVG **`apps/landing/src/assets/figma/journey-landscape.svg`** (540 × 540, clipped to radius 48, composed from the exported layers `358:2952`–`358:2964` at their exact positions — same approach as `nightcare-starfield.svg`). Everything with text, icons or a photo (stage nodes, age chips, the three float cards) stays **live HTML/CSS** on top, so the chips can be translated and icons come from the shared set. Do not export the whole node as one PNG/SVG: the age chips and float-card texts are content that needs en/vi.

Layers (positions inside the Illustration box; "L+" = inside the Landscape, which sits at (50, 20)):

| z | Element | Position | Size | Style |
|---|---|---|---|---|
| 0 | **Landscape** | (50, 20) | 540 × 540 | `border-radius: 48px; overflow:hidden;` background = `journey-landscape.svg` |
| 0a | ↳ sky (in SVG) | L+(0, 0) | 540 × 540 | `linear-gradient(180deg, #FFF5D9, #E0F5F0)` **(raw)** |
| 0b | ↳ sun (SVG) | L+(400, 46) | 90 circle | `sunshine` #FFD166; halo 130 circle at L+(380, 26), `sunshine` 25 % |
| 0c | ↳ clouds (SVG) | L+(60–164, 70–114) and L+(250–323, 40–71) | 3 ellipses each | white 90 % |
| 0d | ↳ hills (SVG) | L+(−300, 330) 900 × 420 · L+(120, 380) 800 × 380 · L+(−180, 450) 700 × 300 | ellipses | `care-growth-soft` #FDEDE2 · `mint-soft` #E6F7F5 · `care-diaper-soft` #E7F4E3 |
| 0e | ↳ road (SVG) | L+(110, 190) | 340 × 280 | white stroke 10, round caps; centre line `separator` #DCE8E7 stroke 3, dash `2 10`. Curve runs from L+(110, 470) to L+(450, 190) through L+(230, 360) and L+(340, 290) |
| 1 | Node 0–12 tháng (photo) | L+(67, 427) | 86 circle | `background: surface; border: 4px solid mint-deep; border-radius: 50%; overflow:hidden;` photo **Peach** `baby-0d3f8.jpg` cover (Figma: 86 photo at −4/−4 under the border) |
| 2 | Node 1–3 tuổi | L+(198, 328) | 64 circle | `surface`, `border: 4px solid sunshine`; star 25.6 centred (stroke `sunshine` #FFD166, 1.92) |
| 3 | Node 3–6 tuổi | L+(312, 262) | 56 circle | `surface`, `border: 4px solid care-sleep-accent`; spark 22.4 centred (`care-sleep-accent` #6C6FD8, 1.68) |
| 4 | Node 6–12 tuổi | L+(425, 165) | 50 circle | `surface`, `border: 4px solid care-bottle-accent`; globe 20 centred (`care-bottle-accent` #3B8FD9, 1.5) |
| 5 | Age chips | L+(60, 510) "0–12 tháng" 88 × 23 · L+(196, 404) "1–3 tuổi" 68 × 23 · L+(306, 326) "3–6 tuổi" 71 × 23 · L+(400, 226) "6–12 tuổi" 76 × 23 | — | `Chip size="sm"` tint white: `surface`, `padding: 4px 10px`, pill, SemiBold 12 `ink`, **no shadow** (en dashes) |
| 6 | Float 1 | (10, 110) | 189 × 57 | float card (below): icon box `care-bottle-soft` (`padding:8px; radius:12px`) + feed 16 (`care-bottle-ink`, 1.2); Bold 14 `ink` **"Bú bình · 120 ml"** / Medium 12 `ink-muted` **"Mẹ ghi · 2 phút trước"** |
| 7 | Float 2 | (0, 350) | 197 × 64 | photo 40 × 40 radius 10 **Sun** `baby-22456.jpg`; Bold 14 `ink` **"Lần đầu con cười"** / Medium 12 **`mint-text`** **"Đã lưu vào Kỷ niệm"** |
| 8 | Float 3 | (250, 535) | 236 × 40 | heart 14 (`care-bottle-ink`, 1.05) + SemiBold 13 `ink` **"Bà nội thương ảnh của Teddy"**, row gap 6. Hangs 15 px below the landscape. |

Float card: `background: surface; border-radius: 18px; padding: 12px 14px; shadow-card;` inner row `gap: 8px; align-items:center`; text col no gap, `nowrap`. Close to the v2 hero chips (`11` §2: radius 18, padding 12/16, raw shadow) — reuse that markup with `shadow-card` and the 14 px padding.

Float 1 and 2 overlap the landscape's left edge (landscape starts at x 50). Nothing overflows the 620 × 580 box.

### Mobile 362:3403 (375 × 710.4)
`display:flex; flex-direction:column; gap:18px; padding: 20px 20px 32px; align-items:flex-start;` order: eyebrow → H1 → lead → **illustration** → explore button. **No promises list on mobile.**
- Eyebrow same text. H1 Bold **36 / 1.15** `ink`, one paragraph "Cùng con lớn lên, đồng hành từng bước." (wraps to 3 lines at 335). Lead Medium 16 / 1.55 (same text, 3 lines).
- Illustration 335 × 313.39 = desktop 620 × 580 × **0.5403** exactly (landscape 291.8 at (27.0, 10.8), radius 25.9; node borders 2.16; chip text **6.48 px**, float titles 7.57 px, subs 6.48 px). Use `Fit w={620} h={580} mobileScale={0.5403}`; text inside is decorative at this size (see §10).
- Explore button **full width**, centred content: `padding: 14px 20px; gap: 8px;` SemiBold **15** + chevron-down **14** (white, 1.05).

---

## 3. Hành trình ("Hành trình lớn lên")

### Desktop 359:2592 (1440 × 806)
`display:flex; flex-direction:column; align-items:center; gap:36px; padding: 64px 96px;`

**Head** (900 wide, centred, gap 16):
- Eyebrow `mint-soft` / `mint-text`: **"Hành trình lớn lên"**
- H2 44 / 1.18 centred, 900 wide (1 line): **"Đi cùng con qua từng chặng."**
- Lead 18 / 1.55 centred, 640 wide (2 lines): **"Mỗi giai đoạn con lớn lên, Child Life cùng ba mẹ chăm con, hiểu con và giữ lại những điều đáng nhớ."**

**Chapters** row 1248, `display:flex; gap:20px; align-items:flex-start;` → 4 cards `flex:1` (≈ 297), **fixed height 474** in Figma (recommend `min-height: 474px` + `align-items: stretch`, link pinned to the bottom with `margin-top:auto`, so longer English copy does not overflow).

Card: `background: surface; border-radius: 28px; overflow:hidden; display:flex; flex-direction:column;` **no shadow**.
- Card 1 (current stage, highlighted): `border: 2px solid mint-deep`. Cards 2–4: `border: 1px solid separator`.
- **Art** strip: full width × **170**, tinted bg, `position:relative; overflow:hidden`:
  - Ellipse 220 × 220 at (150, 40), white **45 %**; ellipse 120 × 120 at (−30, −40), white **35 %** (CSS circles, all cards).
  - Big number at (18, 70): Bold **72** / normal, **opacity .15**, colour per card (it is clipped by the strip bottom).
  - Card 1: photo circle 112 at (92, 29), `border: 5px solid surface; border-radius:50%; overflow:hidden; background: surface-2`, photo **Peach** `baby-0d3f8.jpg` cover.
  - Cards 2–4: white circle 96 at (100, 37) + icon **40** at (128, 65), stroke 3.
- **Body**: `flex:1; display:flex; flex-direction:column; gap:10px; padding: 20px 22px 24px;`
  1. Label row (`display:flex; align-items:center`): SemiBold 13 / normal stage label (colour per card) + flex spacer + (card 1 only) badge `Chip size="tag"`: `mint-soft` / `mint-text`, `padding: 3px 8px`, SemiBold 11 **"Có trên app"**.
  2. Title `stage-title` Bold 22 / 1.25 `ink`.
  3. Body `stage-body` Medium 15 / 1.55 `ink-muted` (3 lines).
  4. Chips row `flex-wrap; gap:6px` — `Chip size="sm"` (`padding: 4px 10px`, SemiBold 12), tint per card.
  5. Link row `gap:6px; align-items:center`: SemiBold 14 + arrow-right 14 (stroke 1.05), both in the card colour.

| Card | Node | Art bg | Number / label / link colour | Art centre | Label | Title | Body | Chips (bg / text) | Link text → target |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 359:2599 | `mint-soft` | `mint-text` | photo Peach | "Chặng 1 · 0–12 tháng" + badge "Có trên app" | "Những ngày đầu đời" | "Làm quen với nhau qua từng cữ bú, giấc ngủ — và giữ lại những lần đầu tiên của con." | `mint-soft` / `mint-text`: "Chăm con mỗi ngày", "Hiểu từng tuần tuổi", "Lưu giữ khoảnh khắc" (one per line at 250) | **"Khám phá năm đầu đời"** → Chặng 1 page `370:50752` |
| 2 | 359:2631 | `sunshine-soft` | `ink` | star (`ink`) | "Chặng 2 · 1–3 tuổi" | "Con tập khám phá" | "Cùng con chập chững, bập bẹ những từ đầu tiên và tập những thói quen nhỏ." | `sunshine-soft` / `ink`: "Nếp sinh hoạt", "Chơi & vận động", "Từ đầu tiên" | "Xem chặng này" → Chặng 2 page `361:3457` |
| 3 | 359:2657 | `care-sleep-soft` | `care-sleep-ink` | spark (`care-sleep-ink`) | "Chặng 3 · 3–6 tuổi" | "Tò mò và lớn khôn" | "Cùng con chơi, đọc, vẽ và trả lời những câu hỏi “vì sao” không ngừng." (curly quotes) | `care-sleep-soft` / `care-sleep-ink`: "Học qua chơi", "Cảm xúc", "Tác phẩm của con" | "Xem chặng này" → Chặng 3 page `361:3575` |
| 4 | 359:2683 | `peach-soft` | `care-bottle-ink` | globe (`care-bottle-ink`) | "Chặng 4 · 6–12 tuổi" | "Thế giới riêng của con" | "Đồng hành nhẹ nhàng khi con tự lập, có sở thích và những ước mơ riêng." | `peach-soft` / `care-bottle-ink`: "Sở thích", "Tự lập", "Nhìn lại hành trình" | "Xem chặng này" → Chặng 4 page `361:3693` |

Big numbers: "1", "2", "3", "4". Stage labels use an en dash and "·". The whole card can be the link (one `<a>` per card, visible link text as above) — but keep the link text as the accessible name.

### Mobile 362:3497 (375 × 1013)
`display:flex; flex-direction:column; gap:18px; padding: 40px 20px; align-items:flex-start;` — no separate head wrapper: eyebrow, H2 Bold **28 / 1.2** (2 lines "Đi cùng con qua từng / chặng."), lead 16 / 1.55 (same text, 3 lines), then the 4 cards stacked (gap 18).
- Card: full width, `display:flex; gap:14px; align-items:flex-start; padding:16px; border-radius:24px;` same borders (card 1 2 px `mint-deep`, others 1 px `separator`), `surface`.
- Thumb 64 × 64 circle (`border-radius: 32px`): card 1 = photo Peach (no white border); cards 2–4 = tinted circle (`sunshine-soft` / `care-sleep-soft` / `peach-soft`) with icon **26** centred (stroke 1.95, same colours).
- Text col `flex:1; gap:4px`: label SemiBold **12** (card colour); title Bold **18** / normal `ink`; body Medium **14 / 1.5** `ink-muted` (same texts); link SemiBold **13** + arrow-right **13** (card colour), same link texts.
- **Removed on mobile:** art strip, big numbers, "Có trên app" badge, chips.

---

## 4. Năm đầu đời

### Desktop 360:2568 (1440 × 1678)
`display:flex; flex-direction:column; align-items:center; gap:36px; padding: 64px 96px;` (from metadata: head y 64, bento y 320, family y 1036, next y 1375, button y 1564, bottom padding 64). Five children:

**4.1 Head** 360:2569 (760 wide, centred, gap 16):
- Eyebrow `mint-soft` / `mint-text`: **"Chặng 1 · Năm đầu đời"**
- H2 44 / 1.18 centred, 760 wide (2 lines): **"Năm đầu đời của con, nhẹ nhàng hơn cho cả nhà."**
- Lead 18 / 1.55 centred, 640 wide (2 lines): **"Chăm con mỗi ngày, hiểu con từng tuần và giữ lại những lần đầu tiên — tất cả trong một ứng dụng."**

**4.2 Bento** 360:2574 (1248 × 680) — **identical to the existing bento** (`12` §1, `apps/landing/src/sections/Everything.tsx`, content `everything.*` in `vi.ts`). Verified tile by tile: same 8 tiles, order, backgrounds, icon boxes and icon colours, titles, bodies, footers (chips "Bú bình · 120 ml" / "Đang ngủ 1:27"; push "Đến giờ nhắc bú bạn đã đặt" / "Lần bú gần nhất 11:45"; M·B·L·H + "Ba Tuấn vừa ghi thay tã"; "3 tuần tuổi" / "Wonder Week 1 · còn 3 ngày"; milestone "Mỉm cười đáp lại" / "Đã quan sát · 08/10"; topics "Giấc ngủ" / "Mọc răng" / "Bú & sữa"; foods "Bí đỏ" / "Cà rốt" / "Bơ" / "+11 món"; photo fan Peach / Sun / Sky at +6° / −4° / +3°). Only differences:
- **Head text** (above) replaces "Tất cả trong một app" / "Mọi điều về con, ở cùng một nơi." / the old lead.
- The photo fan is drawn as a flex row with `margin-right: −30px` overlaps instead of absolute boxes — same rendered result; keep the current implementation.
- Section paddings: v2.1 bento section was `112px 96px 64px` with gap 56; here the bento is one child of a `64px 96px`, gap-36 section.

→ Reuse `Everything.tsx` with the head content passed in (new content keys, e.g. `home.firstYear.eyebrow/title/lead/leadShort`), or split it into `BentoHead` + `BentoGrid` and render only the grid here.

**4.3 Family strip** 365:3512 (1248 × 303), `id="gia-dinh"`: `display:flex; flex-direction:column; gap:20px; padding-top:8px; align-items:flex-start;` (left-aligned although the section head is centred).
1. Title row `gap:10px; align-items:center`: family 20 (`mint-text`, 1.5) + Bold 22 / normal `ink` **"Cả nhà cùng chăm — ai cũng có chỗ bên con"** (em dash).
2. **Roles** row `gap:20px`, 3 cards `flex:1` (≈ 403 × 137): `background: surface; border: 1px solid separator; border-radius: 24px; padding: 22px; display:flex; gap:16px; align-items:flex-start;` no shadow. Icon box 46 × 46 (`padding: 12px; border-radius: 16px`) with a 22 px icon (stroke 1.65). Text col `flex:1; gap:4px`: SemiBold 13 / normal `ink-muted` role; Bold 20 / normal `ink` title; Medium 14 / 1.5 `ink-muted` body (2 lines).

   | Icon box | Icon (colour) | Role | Title | Body |
   |---|---|---|---|---|
   | `mint-soft` | family (`mint-text`) | "Ba mẹ" | "Bớt phải nhớ" | "Cùng chăm, cùng quyết định ai được xem gì." |
   | `care-diaper-soft` | heart (`care-diaper-ink` #2F6B24) | "Người chăm sóc" | "Phối hợp rõ ràng" | "Ghi và nhận nhắc cho bé được giao, không lo ghi trùng." |
   | `peach-soft` | memories (`care-bottle-ink`) | "Ông bà, người thân" | "Gần con dù ở xa" | "Xem ảnh mới của cháu, thả thương, tải ảnh về." |

   Not the same as the v2 Quyền xem role cards (`11` §8: avatar pill + permission rows) — new, simpler card. `IconBox` covers the icon box (new 46 / r16 size).
3. **Trust chips** row: `display:flex; flex-wrap:wrap; gap:10px; justify-content:center; align-items:center;` (2 rows: 4 + 1, 90 tall). Chip: `background: surface; border: 1px solid separator; border-radius: 999px; padding: 10px 16px; gap: 6px;` icon 14 (`ink`, 1.05) + SemiBold **14** `ink`, `nowrap`. Larger than the kit `Chip` (12 px) — add a bordered `lg` variant.

   | Icon | Text |
   |---|---|
   | lock | "Riêng tư, không mạng xã hội" |
   | heart | "Không áp lực ghi đủ" |
   | star | "Không chấm điểm hay so sánh con" |
   | check | "Nội dung được chuyên môn rà soát" |
   | cloud-off | "Dữ liệu của con, quyền của bạn" |

**4.4 Next chapters** 365:3520 (1248 × 153): `column; gap:16px; padding-top:16px;`
1. Bold 22 / normal `ink` **"Những chặng tiếp theo"** (full width, left, no icon).
2. Row `gap:20px`, 3 cards `flex:1` (≈ 403 × 93): tinted bg, `border-radius: 24px; padding: 18px 20px; display:flex; gap:14px; align-items:center;` no border, no shadow, **no arrow / link** in Figma. White circle 44 (`padding: 12px; border-radius: 999px`) with icon 20 (1.5). Text col `gap:2px`, `nowrap`: SemiBold 12 label (colour); Bold 17 `ink` title; Medium 13 `ink-muted` sub.

   | Bg | Icon (colour) | Label (colour) | Title | Sub |
   |---|---|---|---|---|
   | `sunshine-soft` | star (`ink`) | "Chặng 2 · 1–3 tuổi" (`ink`) | "Con tập khám phá" | "Đang cùng con chuẩn bị" |
   | `care-sleep-soft` | spark (`care-sleep-ink`) | "Chặng 3 · 3–6 tuổi" (`care-sleep-ink`) | "Tò mò và lớn khôn" | "Đang cùng con chuẩn bị" |
   | `peach-soft` | globe (`care-bottle-ink`) | "Chặng 4 · 6–12 tuổi" (`care-bottle-ink`) | "Thế giới riêng của con" | "Đang cùng con chuẩn bị" |

   They duplicate Hành trình cards 2–4 one section above; recommend making them links to the same stage pages (§10).

**4.5 Button** 360:2692 (268 × 50, centred): `background: surface; border: 1px solid separator; border-radius: 999px; padding: 14px 22px; display:flex; gap:8px; align-items:center;` SemiBold 16 `ink` **"Xem chi tiết năm đầu đời"** + arrow-right 16 (`ink`, 1.2) → Chặng 1 page `370:50752`. Secondary-button style (v2 had no outlined pill on the landing — new class, e.g. `.btn--outline`).

### Mobile 362:3556 (375 × 1785)
`display:flex; flex-direction:column; gap:24px; padding: 40px 20px; align-items:flex-start;`
1. Head (`gap:12px`, left): eyebrow "Chặng 1 · Năm đầu đời"; H2 Bold **30 / 1.2** (3 lines "Năm đầu đời của con, / nhẹ nhàng hơn cho cả / nhà."); lead 16 / 1.55 **shorter**: **"Chăm con mỗi ngày, hiểu con từng tuần và giữ lại những lần đầu tiên."**
2. Grid = the existing **mobile bento** exactly (`12` §1 mobile: 2 columns 161.5, gap 12, tiles `padding: 16px 14px; radius 22; gap 8`, icon 18, title Bold 15 / 1.25, body Medium 13 / 1.45, the 8 short bodies "Bú, ngủ, tã ngay trên màn hình chính" … "Ảnh, video, câu chuyện"; no footers). Verified identical.
3. Family (`column; gap:12px; padding-top:8px`):
   - Title Bold **20** / normal `ink` **"Cả nhà cùng chăm"** (shortened, **no icon**).
   - 3 role rows full width: `surface; border: 1px solid separator; border-radius: 20px; padding: 14px 16px; display:flex; gap:14px; align-items:center;` icon box `padding: 10px; radius 14px` + icon **20** (1.5, same tints/colours); text col `gap:2px`: SemiBold **12** `ink-muted` role + Bold **18** `ink` title. **No body text on mobile.**
   - Trust chips `flex-wrap; gap:8px;` **left-aligned**, chip `padding: 8px 12px`, SemiBold **13**, icon 14. **Only 4 chips, shortened:** [lock] "Riêng tư" · [heart] "Không áp lực ghi đủ" · [star] "Không chấm điểm con" · [check] "Chuyên môn rà soát". ("Dữ liệu của con, quyền của bạn" is dropped.)
4. Next chapters (`column; gap:10px; padding-top:8px`): title Bold **20** "Những chặng tiếp theo"; 3 cards full width stacked, `border-radius: 20px; padding: 14px 16px; gap:12px;` circle `padding: 10px` + icon **18** (1.35); label SemiBold 12, title Bold **16**, sub Medium **12** (same texts).
5. Button full width, centred: `padding: 14px 20px; gap: 8px;` SemiBold **15** + arrow-right **14**.

---

## 5. Lớn lên cùng con (dark band)

### Desktop 360:2693 (1440 × 466)
Outer `display:flex; flex-direction:column; padding: 24px 48px;` — **48 px side margin, not 96** (the band is 1344 wide, wider than the 1248 content column).

**Band** 360:2694 (1344 × 418): `background: #163D44` **(raw — 1 step off `ink` #173D44; use `ink`)**; `border-radius: 48px; padding: 64px; display:flex; gap:48px; align-items:center;`
- **Copy** `flex:1` (690), `column; gap:16px; align-items:flex-start`:
  - Eyebrow on dark: `background: rgba(255,255,255,.12)` **(raw)**, `padding: 6px 12px; radius 999`, SemiBold 13 white: **"Một hồ sơ, lớn lên cùng con"**
  - H2 Bold **40 / 1.18** white (2 lines): **"Những gì bạn lưu hôm nay, con sẽ còn xem lại khi lớn."**
  - Body Medium **17 / 1.55** `rgba(255,255,255,.72)` **(raw)** (2 lines): **"Từ tấm ảnh đầu tiên đến bức tranh con vẽ tặng bà — hành trình của con nằm trọn ở một nơi, không mất đi khi con lớn."**
- **Years** (478 × 290): `display:flex; gap:14px; align-items:flex-end;` three columns (`column; gap:8px; align-items:flex-start`), staircase heights:

  | Photo window (w × h, radius 20, bg `surface-2`) | Photo (cover) | Year — Bold 22 / normal white | Caption — Medium 13 `rgba(255,255,255,.72)` |
  |---|---|---|---|
  | 150 × 170 | Peach `baby-0d3f8.jpg` (Figma: 170² at left −10) | "2026" | "Ngày con chào đời" |
  | 150 × 200 | Sun `baby-22456.jpg` (200² at left −25) | "2027" | "Bước đi đầu tiên" |
  | 150 × 230 | Sky `baby-4222e.jpg` (230² at left −40) | "2029" | "Ngày đầu đi học" |

  Use `<Photo tone=…>` with `object-fit: cover` (centre crop). The 220 px source JPEGs are upscaled to 230 here — soft at 2× (see §9).

Reuse: none of the existing sections (Night care is a dark card but different content/tokens). New section, e.g. `sections/GrowUp.tsx`.

### Mobile 362:3607 (375 × 405)
Outer `padding: 16px` (band 343 wide — **16 px gutter, not the page's 20**). Band: same bg, `border-radius: 32px; padding: 36px 24px; column; gap:16px;`
- **No eyebrow.** H2 Bold **24 / 1.22** white (3 lines). Body Medium **15 / 1.5** white 72 %, **shorter**: **"Hành trình của con nằm trọn ở một nơi, không mất đi khi con lớn."**
- Years row `gap:10px; align-items:flex-start` (no staircase): each column `gap:6px`: photo **90 × 110**, radius 16 (photo 110² at left −10) + year Bold **16** white. **No captions.**

---

## 6. CTA

### Desktop 360:2788 (1440 × 367)
**Same style as the existing CTA** (`11` §9 / `Cta.tsx`) — `mint-deep` card, radius 40, `padding: 72px`, gap 48, white-6 % circle 420 at (−140, −220), light (white) store badges `StoreBadges variant="light"` (glyph SVGs byte-identical to `store-apple-dark.svg` / `store-play-dark.svg`), caption. Differences:
- Outer padding **`40px 96px`** (v2: `32px 96px 96px`) → card 1248 × 287, section 367 (v2 415).
- H2 (Bold 44 / 1.18, −0.66, white, 2 lines, `nowrap`): **"Bắt đầu hành trình cùng con"** / **"ngay hôm nay."** (replaces "Bớt phải nhớ." / "Thêm thời gian bên con.").
- Unchanged: sub Medium 18 `rgba(255,255,255,.8)` "Miễn phí trên iPhone và Android. Mời cả nhà chỉ trong một phút."; caption Medium 13 `rgba(255,255,255,.75)` "Miễn phí cho cả gia đình" (right-aligned under the badges).

### Mobile 362:3686 (375 × 361.4)
Identical to v2 mobile CTA (`padding: 24px 20px 32px`; card radius 28, `padding: 36px 24px`, gap 16, no circle, badges `flex:1` gap 10, no caption) except the H2: Bold 28 / 1.2, −0.28, one paragraph **"Bắt đầu hành trình cùng con ngay hôm nay."** (3 lines). Sub Medium 15 / 1.5 unchanged.

Implementation: `Cta.tsx` unchanged; add a home-page title (`home.cta.title`) or make `cta.title` a prop. The Chặng pages use their own CTA frames (367 tall too) — check their copy separately.

---

## 7. Hỏi đáp

### Desktop 360:2810 (1440 × 740)
Same layout and item styles as `11` §10 (Row gap 80; left column 360: Bold 36 / 1.2 −0.36 "Câu hỏi thường gặp" + Medium 16 / 1.5 "Còn điều gì băn khoăn? Cứ nhắn cho chúng tôi nhé."; list gap 12; item `surface`, 1 px `separator`, radius 20, `padding: 22px 24px`, question SemiBold 17, answer Medium 15 / 1.55 `ink-muted`; chevron-down 20 when open, plus 20 when closed, both `ink-muted` 1.5). Only the outer padding changes: **`48px 96px 112px`** (v2 `32px 96px 112px`).

Questions — **6 items, new set** (layer names are the old questions; text below is what renders):

| # | State | Question | Answer in Figma |
|---|---|---|---|
| 1 | open | "Child Life là gì?" | "Hệ sinh thái giúp cha mẹ chăm sóc, thấu hiểu và đồng hành cùng con qua từng chặng lớn lên. Ứng dụng hiện tập trung vào năm đầu đời của con." |
| 2 | open | "Child Life dành cho bé mấy tuổi?" (no "từ" — v2 was "…bé từ mấy tuổi?") | "Từ ngày con chào đời. Năm đầu, app giúp cả nhà chăm con mỗi ngày; những chặng tiếp theo sẽ cùng con lớn lên đến tuổi trưởng thành." |
| 3 | closed | "Khi con lớn, ảnh và hồ sơ của con có còn không?" | **none** |
| 4 | closed | "Có mất phí không?" | **none** (was open with an answer in v2) |
| 5 | closed | "Ai được xem ảnh và thông tin của con?" | **none** |
| 6 | closed | "Nội dung gợi ý trong app do ai soạn?" | **none** |

Gone from the home FAQ: "Ông bà không rành điện thoại có dùng được không?" and "Lịch Wonder Week có đúng với mọi bé không?" (they may live on the Chặng 1 page FAQ `370:51670`).

### Mobile 362:3704 (375 × 767)
Same as v2 mobile (`padding: 24px 20px 48px`, gap 12, title Bold 26 −0.26, **no subtitle**, items `padding: 22px 18px`, question SemiBold 16, answer Medium 14 / 1.55). **6 items on mobile too** (desktop/mobile now match in count), but **every text is shortened**:

| # | State | Question | Answer |
|---|---|---|---|
| 1 | open | "Child Life là gì?" | "Hệ sinh thái giúp cha mẹ chăm sóc, thấu hiểu và đồng hành cùng con qua từng chặng lớn lên. Ứng dụng hiện tập trung vào năm đầu đời." |
| 2 | open | "Child Life dành cho bé mấy tuổi?" | "Từ ngày con chào đời. Năm đầu, app giúp cả nhà chăm con mỗi ngày; những chặng sau sẽ cùng con lớn lên." |
| 3 | closed | "Khi con lớn, ảnh của con có còn không?" | none |
| 4 | closed | "Có mất phí không?" | none |
| 5 | closed | "Ai được xem ảnh của con?" | none |
| 6 | closed | "Nội dung gợi ý do ai soạn?" | none |

Recommend one text per item for both breakpoints (use the desktop wording; the mobile differences are trims, not meaning changes) unless the owner wants parity.

---

## 8. Footer

Desktop 360:2838 and mobile 362:3728 are **identical to the existing footer** (`11` §11, `Chrome.tsx` `Footer`): divider, lockup ×0.8 (mobile ×0.7), "© 2026 Child Life", links "Quyền riêng tư" · "Điều khoản" · "Liên hệ" (desktop gap 28 Medium 14; mobile gap 20 Medium 13, copyright on its own line). No change.

---

## 9. Assets

| File | Status | Use |
|---|---|---|
| `apps/landing/src/assets/figma/journey-landscape.svg` | **new** (2.2 KB) | Hero landscape: sky gradient, sun + halo, 2 clouds, 3 hills, road + dashed centre line, clipped to radius 48. Composed from the exported layers `358:2952`–`358:2964` (positions and colours exact; rendered and checked against the Figma render). Nodes, chips, photo and float cards are live HTML on top. |
| `baby-0d3f8.jpg` (Peach), `baby-22456.jpg` (Sun), `baby-4222e.jpg` (Sky) | existing — Figma rasters downloaded and **byte-identical** | Hero node + float 2, Hành trình card 1 (desktop + mobile), bento milestone + fan, Lớn lên photos. `photos.peach / sun / sky` in `primitives.tsx`. |
| `store-apple-dark.svg`, `store-play-dark.svg` | existing — byte-identical | CTA light badges |
| `logo-app-icon.svg`, `nav-logo-mark.svg`, `nav-logo-wordmark.svg` | existing | bento push, nav, footer (`Lockup`) |
| Line icons | existing app set | §0.4 — all already in the landing `Icon` map (globe included) |

CSS only (no asset): Hành trình art ellipses and white icon circles, stage nodes (bordered circles), age chips, float cards, Lớn lên band, CTA circle.

Photo resolution: the 220 × 220 JPEGs are shown at up to 230 px (Lớn lên) and 112 px (Hành trình) — soft at 2×. Request higher-resolution originals if that matters (same note as `11` §14).

---

## 10. Ambiguities, gaps and conflicts

**Product claims vs `docs/product/business-map.md` (owner confirmation before prod; extend Q-039 / R-170):**
1. **Multi-stage "ecosystem" promise.** Hero lead "…từ những ngày đầu đời đến khi trưởng thành", the four stages up to "6–12 tuổi" (chips "Nếp sinh hoạt", "Chơi & vận động", "Từ đầu tiên", "Học qua chơi", "Cảm xúc", "Tác phẩm của con", "Sở thích", "Tự lập", "Nhìn lại hành trình"), FAQ 2 "những chặng tiếp theo sẽ cùng con lớn lên đến tuổi trưởng thành" and Lớn lên "bức tranh con vẽ tặng bà" describe a roadmap with **no D/R/P entries**; V1 scope is year one. The page does mark it ("Có trên app" only on Chặng 1, "Đang cùng con chuẩn bị" on 2–4), but the stage pages 2–4 still need copy that does not promise dates/features. Owner call.
2. **Retention promise.** Lớn lên "không mất đi khi con lớn" and FAQ 3 "Khi con lớn, ảnh và hồ sơ của con có còn không?" (unanswered) imply indefinite storage. The map has a 10 GB family quota (R-121, D-010), owner deletion (R-125) and exports (R-187, D-038) but no long-term retention policy. Answer copy must not over-promise.
3. **Caregiver card** "Ghi và nhận nhắc cho bé được giao, không lo ghi trùng.": "bé được giao" matches R-021/R-123; "nhận nhắc" is only partly true — notifications are local to one device (R-091), a member can move a reminder's notification to their own device (D-029); "không lo ghi trùng" has no rule behind it (opId de-duplication only covers retries of the same command, not two people logging the same feed).
4. **Relatives card** "Xem ảnh mới của cháu, thả thương, tải ảnh về." — consistent with D-001, D-036, R-119. **Parents card** — consistent.
5. **Trust chips**: "Nội dung được chuyên môn rà soát" / "Chuyên môn rà soát" and "Không chấm điểm hay so sánh con" belong to the Hiểu con / library claims in Q-039 (who reviews health content). "Dữ liệu của con, quyền của bạn" is acceptable given R-187 (media export is owner-only). "Riêng tư, không mạng xã hội" and "Không áp lực ghi đủ" — no conflict.
6. **Bento** keeps the Q-039 claims (interval reminders, Wonder Week, library, ăn dặm) — unchanged from `12` §8.10.
7. **FAQ answers missing** for Q3–Q6 (extend G-065). Reusable drafts already in `vi.ts`: "Có mất phí không?" (v2 Figma answer; R-171 storage wording "đủ chỗ cho hàng nghìn ảnh"), "Ai được xem ảnh và thông tin của con?" and "Nội dung gợi ý trong app do ai soạn?" (PROPOSED). Q3 (retention) needs new copy. Q1 is new and answered.

**Design / implementation:**
8. **Routing.** This page introduces stage pages: card 1 and the "Xem chi tiết năm đầu đời" button → Chặng 1 page (`370:50752`, the current long page plus a switcher and new hero); cards 2–4 → `361:3457/3575/3693`. Proposed paths (not in Figma): `/hanh-trinh/nam-dau-doi`, `/hanh-trinh/1-3-tuoi`, `/hanh-trinh/3-6-tuoi`, `/hanh-trinh/6-12-tuoi` (+ `/en/…`). **No mobile design exists for any stage page.** The "Những chặng tiếp theo" cards have no link affordance; recommend linking them to the same pages.
9. **Nav targets** are not defined. Mapping in §1 is a proposal; "Gia đình" now points to a sub-strip, not a section; on stage pages the same four links must resolve to home anchors or pages. The old ids (`cham-con`, `hieu-con`, `ky-niem`, `ban-dem`) leave the home page.
10. **No download in the hero** (v2.1 had badges + caption). Intentional per Figma; the store badges only appear in the CTA. Flag for the owner (conversion).
11. **Hero H1** is 52 px with no tracking and no mint lines (v2: 57 px, −2 %, lines 2–3 `mint-text`); H2s on this page have tracking 0 while the CTA keeps −0.66. Treat as intended (new page), but the shared `.h2` class currently applies −0.66 — needs a modifier or a decision.
12. **Mobile hero illustration** is a uniform ×0.5403 scale: chip text 6.5 px, float text 6.5–7.6 px — decorative only; consider bumping or hiding the float cards on mobile.
13. **Hành trình cards** are fixed 474 tall in Figma; use `min-height` + stretch so English and wrapping chips do not overflow. Card 1's link text differs ("Khám phá năm đầu đời") from the others ("Xem chặng này") — intentional.
14. **Lớn lên band**: colour #163D44 is 1 step off `ink` #173D44 (use the token); desktop uses a 48 px side margin and mobile a 16 px gutter (rest of the page: 96 / 20) — intentional "full-bleed-ish" band, confirm.
15. **Desktop vs mobile copy** differs in: Năm đầu đời lead, family title ("Cả nhà cùng chăm — ai cũng có chỗ bên con" vs "Cả nhà cùng chăm"), role bodies (mobile none), trust chips (5 long vs 4 short), Lớn lên body, Lớn lên captions (mobile none), all six FAQ texts. Either mobile-specific keys (`…Short`, as `everything.*` already does) or one text — owner/design call. English must be drafted for every new string (D-012).
16. **Bento reuse**: grid and tiles are identical to `Everything.tsx`; only the head changes. Make the head configurable instead of forking.
17. **Contrast** (carried over from `12` §8.8): bento tile 8 body `ink-muted` on `card-peach` ≈ 2.8:1; white on `care-sleep-accent` chip ≈ 4.3:1. New on this page: Hành trình big numbers at 15 % opacity are decorative (`aria-hidden`); white 72 % on the dark band passes (≈ 6.9:1).
18. **Hidden nav layer** `358:2910` ("Hỏi đáp", hidden) — ignore.
