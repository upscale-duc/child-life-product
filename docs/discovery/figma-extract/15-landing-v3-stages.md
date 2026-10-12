# 15 — Landing v3: stage pages ("Chặng 1–4") spec (Figma "Website" page)

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only). Extracted 2026-10-11 with `get_design_context` (React+Tailwind reference output; rendered text is authoritative, layer names are stale) on every new block, `get_metadata` for geometry, `download_assets` / asset URLs for the SVG colours and rasters, and a full-page pixel diff for the Chặng 1 sections reused from v2.1. Same conventions as `11-landing-specs.md` / `12-landing-v3-new-sections.md`: token names from `07-foundations-components-motion.md` (CSS vars in `packages/design-tokens/dist/tokens.css`), non-token values marked **(raw)**, Vietnamese text verbatim.

The v3 site is a home page (`358:2901` desktop / `362:3398` mobile; specified separately) plus four stage pages. **Only desktop frames exist for the stage pages.** The mobile layouts in §9 are an engineering proposal derived from the v3 home mobile frame `362:3398`; nothing in §9 is in Figma.

| Page | Desktop frame | Size | Template |
|---|---|---|---|
| Chặng 1 · Những ngày đầu đời | `370:50752` "Landing v3 · Chặng 1 · Desktop" | 1440 × 12170.2 | Stage header (§1–3) + the v2.1 feature sections (§6) + Prev next + CTA (v2 style) + Hỏi đáp + Footer |
| Chặng 2 · Con tập khám phá | `361:3457` "Landing v3 · Chặng 2 · Desktop" | 1440 × 1862.2 | Stage template (§1–5, §7, §8) |
| Chặng 3 · Tò mò và lớn khôn | `361:3575` "Landing v3 · Chặng 3 · Desktop" | 1440 × 1862.2 | Stage template |
| Chặng 4 · Thế giới riêng của con | `361:3693` "Landing v3 · Chặng 4 · Desktop" | 1440 × 1862.2 | Stage template |

As before: no prototype links, no motion, no hover/focus/pressed states, no tablet frame, no dark page variant. Light, static state only.

Screenshots (not committed; regenerate with `get_screenshot` if needed) in the session scratchpad `v3/`: `s1-switcher.png`, `s1-hero.png`, `s1-prevnext.png`, `s1-cta.png`, and for N = 2, 3, 4: `sN-switcher.png`, `sN-hero.png`, `sN-highlights.png`, `sN-prevnext.png`, `sN-cta.png` (crops of `full-sN.png`, 1440 px wide, 1×).

---

## 0. Global

### 0.1 Section order

Chặng 2 / 3 / 4 (identical geometry; y = top inside the page frame):

| # | Block | Chặng 2 node | Chặng 3 node | Chặng 4 node | h (y) |
|---|---|---|---|---|---|
| 1 | Nav | 361:3458 | 361:3576 | 361:3694 | 87 (0) |
| 2 | Switcher | 361:3470 | 361:3588 | 361:3706 | 38 (87) |
| 3 | Hero | 361:3484 | 361:3602 | 361:3720 | 508 (125) |
| 4 | Highlights | 361:3505 | 361:3623 | 361:3742 | 529 (633) |
| 5 | Prev next | 361:3536 | 361:3654 | 361:3773 | 149 (1162) |
| 6 | CTA | 361:3543 | 361:3661 | 361:3780 | **367** (1311) |
| 7 | Footer | 361:3565 | 361:3683 | 361:3802 | 184.2 (1678) |

Chặng 1 (`370:50752`):

| # | Block | Node | h (y) | Spec |
|---|---|---|---|---|
| 1 | Nav | 370:51712 | 87 (0) | §1 |
| 2 | Switcher | 370:51724 | 38 (87) | §2 |
| 3 | Hero | 372:3543 | 508 (125) | §3 (photo variant) |
| 4 | Mọi thứ trong một app | 370:50817 | 1080 (633) | = v2.1 `322:1809` → `12` §1 |
| 5 | Thao tác nhanh | 370:50938 | 1106 (1713) | = v2.1 `321:1287` → `11` §3 |
| 6 | Chăm sóc | 370:50986 | 760 (2819) | = v2.1 `321:1335` → `11` §4 |
| 7 | Nhắc nhở | 370:51019 | 760 (3579) | = v2.1 `324:1946` → `12` §2 |
| 8 | Cùng chăm | 370:51097 | 728 (4339) | = v2.1 `321:1368` (mirrored layout) → `13` §5 |
| 9 | Hiểu con | 370:51143 | 1093 (5067) | = v2.1 `324:45334` → `12` §3 |
| 10 | Thư viện & ăn dặm | 370:51269 | 760 (6160) | = v2.1 `324:2042` → `12` §4 |
| 11 | Sơ cấp cứu | 370:51346 | 760 (6920) | = v2.1 `330:2582` → `12` §5 |
| 12 | Tuổi thơ | 370:51412 | 1499 (7680) | = v2.1 `321:1414` → `11` §6 |
| 13 | Night care | 370:51531 | 688 (9179) | = v2.1 `321:1533` → `11` §7 |
| 14 | Quyền xem | 370:51568 | 831 (9867) | = v2.1 `321:1570` → `11` §8 |
| 15 | Prev next | 370:51738 | 149 (10698) | §5 (no "previous") |
| 16 | CTA | 370:51648 | **415** (10847) | = v2.1 `321:1650` → `11` §9 unchanged |
| 17 | Hỏi đáp | 370:51670 | 724 (11262) | = v2.1 `321:1672` → `13` §10 unchanged |
| 18 | Footer | 370:51702 | 184.2 (11986) | = `11` §11 |

In other words, **Chặng 1 = the v2.1 long page with its Hero replaced by the stage header (Switcher + stage Hero) and a Prev next block inserted before the CTA.** The v2.1 Hero (`321:1235`) is not on the Chặng 1 page.

Page background: `cloud` #F6FCFB; every stage block is transparent over it (Tuổi thơ keeps its `surface` band, as in v2.1).

### 0.2 Stage theme (the only thing that varies between the stage pages)

Each stage has one soft tint (chip bg, illustration panel, highlight icon boxes, quote band) and one ink (chip text, big number, icons, quote text). All are existing tokens and map to existing eyebrow classes in `apps/landing/src/styles` (`layout.css` / `features.css`).

| Stage | Tint (`--stage-soft`) | Ink (`--stage-ink`) | Quote text | Existing eyebrow class |
|---|---|---|---|---|
| 1 | `mint-soft` #E6F7F5 | `mint-text` #06716D | — (no quote band) | `.eyebrow--mint` |
| 2 | `sunshine-soft` #FFF4D6 | **`ink`** #173D44 | `ink` | `.eyebrow--sun-ink` |
| 3 | `care-sleep-soft` #EDEEFC | `care-sleep-ink` #4447A8 | `care-sleep-ink` | `.eyebrow--sleep` |
| 4 | `peach-soft` #FFE3DA | `care-bottle-ink` #1D5F99 | `care-bottle-ink` | `.eyebrow--peach` |

Recommended implementation: a `data-stage="1..4"` attribute on the page root that sets `--stage-soft` / `--stage-ink`, and stage blocks that only read those two variables.

### 0.3 Text styles used on the stage blocks

| Name (proposed) | Font | Size / line-height | Tracking | Colour | Where |
|---|---|---|---|---|---|
| `stage-h1` | Bold 700 | **54 / 1.12** | **0** (home display is −2 %) | `ink` | Hero title (1 line at 652) |
| `stage-lead` | Medium 500 | 20 / **1.55** (≈ 31) | 0 | `ink-muted` | Hero lead (2 lines at 652) |
| `stage-chip` | SemiBold 600 | 13 / normal | 0 | `--stage-ink` | Hero age chip + highlight chips (= `.eyebrow` geometry) |
| `stage-h2` | Bold 700 | 28 / normal | 0 | `ink` | "Ở chặng này, Child Life cùng ba mẹ" |
| `hl-title` | Bold 700 | 22 / 1.25 | 0 | `ink` | Highlight card title |
| `hl-body` | Medium 500 | 16 / 1.55 | 0 | `ink-muted` | Highlight card body (2 lines at 348.7) |
| `quote` | SemiBold 600 | 20 / 1.5 | 0 | per §0.2 | Quote band (1 line at 1076) |
| `pn-label` | Medium 500 | 13 / normal | 0 | `ink-muted` | "← Chặng trước" / "Chặng tiếp theo →" / "Quay lại" |
| `pn-title` | Bold 700 | 18 / normal | 0 | `ink` | Prev/next target title |
| `crumb` | Medium 500 | 14 / normal | 0 | `ink-muted` | "Hành trình  ›" |
| `tab-num` / `tab-name` | Bold 700 / SemiBold 600 | 13 / normal | 0 | see §2 | Switcher pills |

### 0.4 Assets

- **No new assets.** Every raster in the stage pages is byte-identical (`cmp`) to an existing file: Chặng 1 hero `baby-0d3f8.jpg` (Peach), Chặng 2 quote `baby-22456.jpg` (Sun), Chặng 3 quote `baby-4222e.jpg` (Sky), Chặng 4 quote `baby-ae95e.jpg` (Leaf). Use the existing `<Photo tone=…>` primitive (`peach`, `sun`, `sky`, `leaf`).
- Store glyphs in the CTA are byte-identical to `store-apple-dark.svg` / `store-play-dark.svg` (light badge variant, `StoreBadges variant="light"`).
- Icons are app icons already imported by the landing `Icon` primitive: `star`, `clock`, `heart`, `spark`, `journal`, `globe`, `check`, `lock` (plus `chevron-down`, `plus` for the FAQ). Figma stroke = 1.8 at 24 (6.75 at the 90 px hero icon, 1.65 at 22); colour = `--stage-ink`.
- The illustration-panel circles are plain white ellipses with opacity (exported SVGs `f7286` / `a153f` / `68c52` / `b5ce8` are just `<circle fill="white" fill-opacity=…>`): build them in CSS, do not ship the SVGs.

---

## 1. Nav (all four stage pages)

Desktop `370:51712` / `361:3458` / `361:3576` / `361:3694` — 1440 × 87. Geometry, logo, link styling and CTA button are **identical to the v2/v3 desktop nav** (`11` §1: `padding: 22px 96px`, Lockup 175.9 × 34, links gap 36 Medium 15 `ink-muted`, 40 spacer, `ink` pill button `padding: 12px 22px` SemiBold 15 `surface` "Tải miễn phí"). Only the links changed (same as the v3 home `358:2905`):

**"Hành trình" · "Năm đầu đời" · "Gia đình" · "Hỏi đáp"** (4 links; a 5th duplicate "Hỏi đáp" layer `…:3466` / `370:51720` is hidden — ignore it).

No active/current-page styling is drawn for the links.

### Proposed targets (not defined in Figma)

| Link | On Chặng 1 page | On Chặng 2–4 pages | Notes |
|---|---|---|---|
| Hành trình | `/#hanh-trinh` (home "Hành trình" `359:2592`) | same | |
| Năm đầu đời | top of the Chặng 1 page (`aria-current="page"`) | Chặng 1 page | Home's "Xem chi tiết năm đầu đời" (`360:2692`) and "Khám phá năm đầu đời" also lead there |
| Gia đình | `#gia-dinh` on the same page (Cùng chăm `370:51097`) | `/#gia-dinh` (home "Family" block `365:3512`) | |
| Hỏi đáp | `#hoi-dap` on the same page (`370:51670`) | `/#hoi-dap` (home FAQ `360:2810`) | Chặng 2–4 have no FAQ |
| Tải miễn phí | `#tai-app` (same page CTA) | `#tai-app` (same page CTA) | Every stage page has the CTA |

Implementation note: `Chrome.tsx` `Nav` hard-codes the five v2.1 section ids (`cham-con`, `hieu-con`, `ky-niem`, `gia-dinh`, `hoi-dap`) and prefixes `homePath` off the home page. It needs a per-page link list (label + href) instead. The language switch stays as is (D-012 addition, not in Figma).

---

## 2. Switcher ("Hành trình ›" + 4 stage pills)

Desktop `370:51724` / `361:3470` / `361:3588` / `361:3706` — 1440 × 38, directly under the nav.

- Row: `display:flex; align-items:center; gap:8px; padding: 4px 96px 0;` (no bottom padding; the hero's 40 px top padding follows).
- Breadcrumb text (not a pill): Medium 14 / normal `ink-muted`, `white-space: pre`, verbatim **"Hành trình  ›"** (two spaces before ›). Proposed link: `/#hanh-trinh`.
- Pill (`Tab 1…4`): `display:inline-flex; align-items:center; gap:6px; padding: 8px 14px; border-radius: 999px; white-space: nowrap;` 13 px, two spans:
  - number span Bold 700 "Chặng N"
  - name span SemiBold 600 (stage title)
- **Inactive**: `background: surface; border: 1px solid separator;` number `ink-muted`, name `ink` → 34 tall.
- **Active** (current page): `background: ink;` no border, both spans `surface` (white) → 32 tall in Figma (the row centres it). Recommend `border: 1px solid transparent` (or `border-color: var(--ink)`) on the active pill so all pills are 34 tall and nothing shifts between pages.
- Pills, in order (same on every page):

| Pill | Number | Name | Width inactive / active |
|---|---|---|---|
| 1 | "Chặng 1" | "Những ngày đầu đời" | 218 / 216 |
| 2 | "Chặng 2" | "Con tập khám phá" | 210 / 208 |
| 3 | "Chặng 3" | "Tò mò và lớn khôn" | 207 / 205 |
| 4 | "Chặng 4" | "Thế giới riêng của con" | 235 / 233 |

- Active pill per page: Chặng 1 page → pill 1, Chặng 2 → pill 2, Chặng 3 → pill 3, Chặng 4 → pill 4.
- Semantics: `<nav aria-label="Hành trình">` with an `<ol>` of links; the active one is `aria-current="page"`. Breadcrumb + pills fit on one line at 1440 (ends at x 1080); no overflow behaviour is drawn.

---

## 3. Hero (stage)

Desktop `372:3543` / `361:3484` / `361:3602` / `361:3720` — 1440 × 508.

`display:flex; align-items:center; gap:56px; padding: 40px 96px 48px;` → Copy `flex:1` (652 wide) + Illustration 540 × 420.

### 3.1 Copy (col, `gap: 18px`, items start; 652 × 232, vertically centred → top at y 134 inside the hero)
1. **Age chip** = eyebrow geometry: `padding: 6px 12px; radius 999;` bg `--stage-soft`, SemiBold 13 `--stage-ink` (28 tall). Text per stage (§8).
2. **H1** `stage-h1` Bold 54 / 1.12, `ink`, 1 line (60 tall). Ends with a full stop.
3. **Lead** `stage-lead` Medium 20 / 1.55, `ink-muted`, 2 lines (62 tall).
4. **Highlight chips** row `gap: 8px` (wrap if narrower): 3 chips, same style as the age chip (`--stage-soft` / `--stage-ink`). Static labels — no link or tap target in Figma.

### 3.2 Illustration panel (540 × 420)
`position:relative; overflow:hidden; border-radius: 44px; background: --stage-soft;` `aria-hidden="true"`. Children (absolute, in paint order; coordinates inside the panel):

| z | Element | Pos (x, y) | Size | Fill |
|---|---|---|---|---|
| 1 | Circle A | (260, 140) | 380 | white 45 % **(raw `rgba(255,255,255,.45)`)** — bleeds off the bottom-right, clipped |
| 2 | Circle B | (−60, −60) | 220 | white 35 % — clipped top-left |
| 3 | Circle C | (420, −30) | 140 | white 50 % — clipped top-right |
| 4a | **Chặng 2–4:** Circle D | (160, 100) | 220 | white 100 % (`surface`) |
| 5a | **Chặng 2–4:** stage icon | (225, 165) | 90 | line icon, stroke 6.75 (= 1.8 @ 24), `--stage-ink`; centred in circle D (centre 270, 210) |
| 4b | **Chặng 1:** Photo | (150, 90) | 240 | circle (`radius 120`), `border: 8px solid surface`, bg `surface-2`, overflow hidden, `Illustration/Photo` Peach (`baby-0d3f8.jpg`, gradient #FFE3D8→#F7B9A5 behind it) `object-fit: cover` filling the 240 box (224 visible inside the border); same centre (270, 210). No Circle D, no icon. |
| 6 | Big number | (30, 170) | text box ≈ 78–130 × 228 | Bold **180** / normal, `opacity: .1`, colour `--stage-ink` ("1" `mint-text`, "2" `ink`, "3" `care-sleep-ink`, "4" `care-bottle-ink`); does not overlap the circle |

Note: the Chặng 1 photo is the 220 px raster scaled to 240 px (soft at 2×); request a larger original if it matters.

---

## 4. Highlights ("Ở chặng này, Child Life cùng ba mẹ") — Chặng 2–4 only

Desktop `361:3505` / `361:3623` / `361:3742` — 1440 × 529.

`display:flex; flex-direction:column; gap:28px; padding: 24px 96px 64px;`

1. **Title** `stage-h2` Bold 28 / normal `ink`, full width, left-aligned, verbatim **"Ở chặng này, Child Life cùng ba mẹ"** (same on all three pages). Use an `<h2>`.
2. **Row** `display:flex; gap:20px;` 3 cards `flex:1` (402.67 × 206). Recommend `align-items: stretch` (Figma is `start`, but all bodies are 2 lines so heights match).
   - Card: `background: surface; border: 1px solid separator; border-radius: 28px; padding: 28px 26px; display:flex; flex-direction:column; gap:12px;` no shadow.
   - Icon box: `background: --stage-soft; padding: 12px; border-radius: 16px;` (46 × 46) + icon 22, stroke 1.65, `--stage-ink`.
   - Title `hl-title` Bold 22 / 1.25 `ink` (1 line; `<h3>`).
   - Body `hl-body` Medium 16 / 1.55 `ink-muted` (2 lines at 348.7).
3. **Quote band** 1248 × 144: `background: --stage-soft; border-radius: 32px; padding: 28px 32px; display:flex; align-items:center; gap:20px;`
   - Photo 88 × 88 circle (`radius 44`), bg `surface-2`, overflow hidden, `Illustration/Photo` raster `object-fit: cover` (tone per stage, §8).
   - Text `quote` SemiBold 20 / 1.5, `flex:1`, colour per §0.2, 1 line. **No quotation marks in the rendered text** (the layer names start with “ but the rendered strings do not). Use `<p>` (or `<blockquote>` without added quote glyphs).

---

## 5. Prev next

Desktop `370:51738` (Chặng 1) / `361:3536` / `361:3654` / `361:3773` — 1440 × 149.

`display:flex; gap:20px; align-items:flex-start; padding: 16px 96px 48px;` → two slots `flex:1` (614 × 85 each).

- Card: `background: surface; border: 1px solid separator; border-radius: 24px; padding: 20px 24px; display:flex; flex-direction:column; gap:4px; white-space: nowrap;` no shadow. Whole card is the link (proposed; no interaction drawn).
  - Label `pn-label` Medium 13 `ink-muted`.
  - Title `pn-title` Bold 18 `ink`.
- Previous card (left slot): `align-items: flex-start` (left-aligned text).
- Next card (right slot): `align-items: flex-end` (right-aligned text).

| Page | Left slot | Right slot |
|---|---|---|
| Chặng 1 | **empty** — a `flex:1` spacer (`370:51739`), no card | "Chặng tiếp theo →" / "Chặng 2 · Con tập khám phá" → Chặng 2 page |
| Chặng 2 | "← Chặng trước" / "Chặng 1 · Những ngày đầu đời" → Chặng 1 page | "Chặng tiếp theo →" / "Chặng 3 · Tò mò và lớn khôn" → Chặng 3 page |
| Chặng 3 | "← Chặng trước" / "Chặng 2 · Con tập khám phá" → Chặng 2 | "Chặng tiếp theo →" / "Chặng 4 · Thế giới riêng của con" → Chặng 4 |
| Chặng 4 | "← Chặng trước" / "Chặng 3 · Tò mò và lớn khôn" → Chặng 3 | **"Quay lại"** (no arrow) / **"Toàn bộ hành trình"** → proposed `/#hanh-trinh` |

The arrows are text characters inside the label (`←` U+2190, `→` U+2192), separated by one space; mark them `aria-hidden` by splitting the span if the accessible name should not read "arrow". Chặng 1's metadata reports the spacer 589 and the card 639 wide although both are `flex:1` in the generated code — implement equal halves (614).

Semantics: `<nav aria-label="Các chặng">` with `rel="prev"` / `rel="next"` on the links.

---

## 6. Chặng 1 — the v2.1 sections (no changes)

Method ("cheap diff"): every Chặng 1 section subtree from Mọi thứ trong một app to Quyền xem, plus CTA, Hỏi đáp and Footer, was compared with its v2.1 counterpart in `321:1222` (metadata dump, ids stripped, coordinates rounded to 0.1). **All 14 pairs are identical** — same node names, types, order, x/y/w/h, including every text node's box. A pixel diff of the two full-page renders (1440 px, 1×; Chặng 1 y 633–10698 vs v2.1 y 879–10944, and CTA→Footer) shows no difference beyond 5 isolated anti-aliasing pixels. `get_design_context` was additionally run on the Chặng 1 Nav, Switcher, Hero, Prev next, CTA and Hỏi đáp.

Therefore, on the Chặng 1 page:
- Reuse the existing sections unchanged (`apps/landing/src/sections`: `Everything`, `Quick`, `Care`, `Reminders`, `Cocare`, `Understand`, `Library`, `FirstAid`, `Memories`, `Night`, `Roles`, `Cta`, `Faq`) with the specs in `11` / `12` / `13` and the existing `vi.ts` / `en.ts` strings (including the PROPOSED overrides listed in `13` §0).
- **CTA** (`370:51648`) is the v2 CTA exactly: `padding: 32px 96px 96px`, mint-deep card, H2 "Bớt phải nhớ." / "Thêm thời gian bên con.", sub "Miễn phí trên iPhone và Android. Mời cả nhà chỉ trong một phút.", light badges, caption "Miễn phí cho cả gia đình". It is **not** the stage-2–4 variant (§7).
- **Hỏi đáp** (`370:51670`) is the v2.1 FAQ exactly (`13` §10): "Câu hỏi thường gặp" / "Còn điều gì băn khoăn? Cứ nhắn cho chúng tôi nhé."; Q1 "Child Life dành cho bé từ mấy tuổi?" (open), Q2 "Có mất phí không?" (open), Q3 "Ông bà không rành điện thoại có dùng được không?", Q4 "Ai được xem ảnh và thông tin của con?", Q5 "Nội dung gợi ý trong app do ai soạn?", Q6 "Lịch Wonder Week có đúng với mọi bé không?" (Q3–Q6 collapsed, no answers in Figma). Answers Q1/Q2 verbatim as in `11` §10.
- Section ids: keep the home v2.1 ids (`#tat-ca`, `#cham-con`, `#nhac-nho`, `#gia-dinh`, `#hieu-con`, `#thu-vien`, `#so-cap-cuu`, `#ky-niem`, `#ban-dem`, `#rieng-tu`, `#tai-app`, `#hoi-dap`) on the Chặng 1 page so old deep links can be redirected there.

---

## 7. CTA (Chặng 2–4) — v2 card, new copy, new outer padding

Desktop `361:3543` / `361:3661` / `361:3780` — 1440 × **367**. Compared with `Cta.tsx` and `11` §9:

| | `11` §9 / `Cta.tsx` / Chặng 1 | Chặng 2–4 |
|---|---|---|
| Outer padding | `32px 96px 96px` (415 tall) | **`40px 96px`** (367 tall) — same as the v3 home CTA `360:2788` |
| Card | `mint-deep` #087F7B, radius 40, padding 72, gap 48, items centre, overflow hidden, 1248 × 287 | same |
| Decorative circle | 420 at (−140, −220), white 6 % | same |
| H2 (Bold 44 / 1.18, −0.66, white, 2 lines) | "Bớt phải nhớ." / "Thêm thời gian bên con." | **"Bắt đầu hành trình cùng con" / "ngay hôm nay."** |
| Sub (Medium 18 / normal, `rgba(255,255,255,.8)`) | "Miễn phí trên iPhone và Android. Mời cả nhà chỉ trong một phút." | same |
| Badges | light variant (white bg, #141417 text, `store-*-dark.svg`), App Store 189.2 × 67, Google Play 210.2 × 67, gap 12 | same |
| Caption (Medium 13, `rgba(255,255,255,.75)`, right-aligned) | "Miễn phí cho cả gia đình" | same |

So the CTA is **not a new style** — it is the existing teal (mint-deep) card with white badges; only the H2 and the outer padding change. Implementation: give `Cta` a `title` prop (or a `variant: 'home' | 'stage'` that selects `c.cta.title` vs a new `c.stages.ctaTitle`) and a padding modifier (`.cta--compact { padding-block: 40px; }` at ≥ 1120 px). Keep `id="tai-app"` on every page.

Stale layer names in this block (`361:3547` "Đăng ký để là những gia đình đ…", `361:3564` "Miễn phí · 10 GB cho cả gia đì…") do **not** render; there is no sign-up form or "10 GB" claim in the design.

Footer (`361:3565` …) = `11` §11 unchanged ("© 2026 Child Life", "Quyền riêng tư" · "Điều khoản" · "Liên hệ").

---

## 8. Per-stage content and theme table

All text verbatim from `get_design_context`. English is an engineering draft for owner review (D-012: vi/en must have the same ids).

### 8.1 Shared strings (all stage pages)

| Key (proposed) | vi | en (draft) |
|---|---|---|
| `nav.links.journey` | Hành trình | Journey |
| `nav.links.firstYear` | Năm đầu đời | First year |
| `nav.links.family` | Gia đình | Family |
| `nav.links.faq` | Hỏi đáp | FAQ |
| `stages.crumb` | Hành trình  › | Journey  › |
| `stages.highlightsTitle` | Ở chặng này, Child Life cùng ba mẹ | At this stage, Child Life is with you |
| `stages.prev` | ← Chặng trước | ← Previous stage |
| `stages.next` | Chặng tiếp theo → | Next stage → |
| `stages.backLabel` | Quay lại | Back to |
| `stages.backTitle` | Toàn bộ hành trình | The whole journey |
| `stages.ctaTitle` | Bắt đầu hành trình cùng con / ngay hôm nay. | Start the journey with your child / today. |
| `stages.n.number` | Chặng N | Stage N |

### 8.2 Per stage

| Item | Chặng 1 | Chặng 2 | Chặng 3 | Chặng 4 |
|---|---|---|---|---|
| Stage name (switcher, prev/next "Chặng N · …") | Những ngày đầu đời | Con tập khám phá | Tò mò và lớn khôn | Thế giới riêng của con |
| Age chip | Chặng 1 · 0–12 tháng | Chặng 2 · 1–3 tuổi | Chặng 3 · 3–6 tuổi | Chặng 4 · 6–12 tuổi |
| H1 | Những ngày đầu đời. | Con tập khám phá. | Tò mò và lớn khôn. | Thế giới riêng của con. |
| Lead | Làm quen với nhau qua từng cữ bú, giấc ngủ — và giữ lại những lần đầu tiên của con. | Cùng con chập chững, bập bẹ những từ đầu tiên và tập những thói quen nhỏ. | Cùng con chơi, đọc, vẽ và trả lời những câu hỏi “vì sao” không ngừng. | Đồng hành nhẹ nhàng khi con tự lập, có sở thích và những ước mơ riêng. |
| Chips | Chăm con mỗi ngày · Hiểu từng tuần tuổi · Lưu giữ khoảnh khắc | Nếp sinh hoạt · Chơi & vận động · Từ đầu tiên | Học qua chơi · Cảm xúc · Tác phẩm của con | Sở thích · Tự lập · Nhìn lại hành trình |
| Tint / ink | `mint-soft` / `mint-text` | `sunshine-soft` / `ink` | `care-sleep-soft` / `care-sleep-ink` | `peach-soft` / `care-bottle-ink` |
| Panel centre | Photo 240, Peach (`baby-0d3f8.jpg`), 8 px white ring | white circle 220 + `star` 90 | white circle 220 + `spark` 90 | white circle 220 + `globe` 90 |
| Big number | 1 | 2 | 3 | 4 |
| HL 1 icon / title / body | — | `star` / Những bước chân đầu tiên / Ghi lại khi con chập chững, bập bẹ từ đầu tiên và những chuyến đi xa đầu đời. | `spark` / Học qua chơi / Cùng con đọc truyện, vẽ tranh và làm những món đồ nhỏ xinh. | `star` / Điều con yêu thích / Lưu lại sở thích, dự án và những thành quả con tự hào. |
| HL 2 | — | `clock` / Nếp nhỏ mỗi ngày / Cả nhà cùng nắm giờ ăn, giờ ngủ của con, nhẹ nhàng tập những thói quen đầu tiên. | `journal` / Những câu hỏi “vì sao” / Giữ lại điều con tò mò và những câu nói ngộ nghĩnh của con. | `check` / Tự lập theo cách của con / Cả nhà cùng đặt mục tiêu nhỏ, con chủ động thực hiện. |
| HL 3 | — | `heart` / Chơi cùng con / Những ý tưởng chơi, vận động và trò chuyện vừa với tuổi của con. | `heart` / Lớn khôn từng chút / Cùng con tập tự làm và gọi tên những cảm xúc của mình. | `lock` / Khoảng riêng của con / Đồng hành mà vẫn tôn trọng thế giới riêng con đang lớn dần. |
| Quote photo | — | Sun `baby-22456.jpg` (gradient #FFF1C9→#F9D77E) | Sky `baby-4222e.jpg` (#DCEBFA→#A9CBEF) | Leaf `baby-ae95e.jpg` (Mint gradient #CFEFEA→#8FD6CB) |
| Quote text (colour) | — | Những bước chân đầu tiên, những lần cả nhà vỡ oà — đều đáng được giữ lại. (`ink`) | Mỗi câu hỏi “vì sao” của con là một kỷ niệm nhỏ, đáng được lưu lại. (`care-sleep-ink`) | Con có thế giới riêng rồi. Ba mẹ vẫn ở đây, mỗi khi con cần. (`care-bottle-ink`) |
| Prev | (none) | Chặng 1 · Những ngày đầu đời | Chặng 2 · Con tập khám phá | Chặng 3 · Tò mò và lớn khôn |
| Next | Chặng 2 · Con tập khám phá | Chặng 3 · Tò mò và lớn khôn | Chặng 4 · Thế giới riêng của con | Quay lại · Toàn bộ hành trình |
| CTA H2 | Bớt phải nhớ. / Thêm thời gian bên con. | Bắt đầu hành trình cùng con / ngay hôm nay. | same as 2 | same as 2 |
| Body after hero | v2.1 sections (§6) | Highlights | Highlights | Highlights |

English drafts for the per-stage strings:

| Item | Chặng 1 | Chặng 2 | Chặng 3 | Chặng 4 |
|---|---|---|---|---|
| Name | The very first days | Exploring the world | Curious and growing | A world of their own |
| Age chip | Stage 1 · 0–12 months | Stage 2 · 1–3 years | Stage 3 · 3–6 years | Stage 4 · 6–12 years |
| Lead | Getting to know each other one feed and one nap at a time — and keeping your child's firsts. | Toddling, first words and small new habits, together. | Playing, reading, drawing and answering an endless stream of "why?". | Gently by their side as they grow independent, with interests and dreams of their own. |
| Chips | Everyday care · Week by week · Keep the moments | Daily rhythm · Play & movement · First words | Learning through play · Feelings · Their creations | Interests · Independence · Look back on the journey |
| HL 1 | — | First steps — Capture the wobbly first steps, the first words and the first trips away from home. | Learning through play — Read stories, draw and make little things together. | What they love — Keep their hobbies, projects and the things they're proud of. |
| HL 2 | — | Small daily rhythms — The whole family keeps track of meals and naps, and gently builds first habits. | All the "why?" questions — Keep what they wonder about and the funny things they say. | Independent, their way — Set small goals as a family; your child takes the lead. |
| HL 3 | — | Play together — Ideas for play, movement and conversation that suit their age. | Growing up bit by bit — Practise doing things on their own and naming their feelings. | Their own space — Stay close while respecting the world they are building. |
| Quote | — | First steps, the moments the whole family cheers — all worth keeping. | Every "why?" is a small memory worth saving. | They have a world of their own now. You're still here whenever they need you. |

---

## 9. Mobile (375) — PROPOSAL, not in Figma

There are no mobile frames for the stage pages. The layout below is derived from the v3 home mobile frame `362:3398`, whose Nav (`362:3399`), CTA (`362:3686`) and Footer (`362:3728`) are geometrically identical to the v2/v2.1 mobile ones (`11` §1, §9, §11), and from its "Hành trình" stage cards (`362:3502`…). Content width 335, side gutter 20, all single-column, copy first.

| Block | Proposal |
|---|---|
| Nav | `11` §1 mobile: lockup ×0.78 + "Tải app" (`mint-deep` pill, `padding: 10px 16px`, SemiBold 14), `padding: 14px 20px`, no links (the mobile home has none). |
| Switcher | One horizontally scrolling row: `display:flex; gap:8px; padding: 4px 20px 0; overflow-x:auto; scroll-snap-type:x proximity; scrollbar-width:none;` same pill metrics as desktop (13 px, 34 tall); breadcrumb "Hành trình  ›" stays as the first item; scroll the active pill into view on load (`scroll-padding-inline: 20px`). Total ≈ 960 px wide, so it always scrolls. |
| Hero | Col, `gap: 16px; padding: 24px 20px 40px;` chip → H1 Bold **31 / 1.12** (`11` mobile display size; 1–2 lines) → lead Medium **16 / 1.55** → chips `flex-wrap: wrap; gap: 8px`. Then the illustration panel full width, `aspect-ratio: 540 / 420` (335 × 260.6): build it at 540 × 420 and scale with `transform: scale(.6204)` inside the wrapper (radius 44 → 27.3; use 28). |
| Highlights | `padding: 8px 20px 40px; gap: 20px;` title Bold **22** / normal; cards stacked `gap: 12px`, `padding: 22px 20px; radius 24;` icon box 40 (padding 10, icon 20), title Bold **19** / 1.25, body Medium **15** / 1.5. Quote band `padding: 20px; radius: 24px; gap: 16px;` photo **56**, text SemiBold **17** / 1.5 (wraps 2–3 lines). |
| Prev next | Stacked, `gap: 12px; padding: 8px 20px 32px;` each card full width, `padding: 16px 20px; radius 20;` label Medium 13, title Bold **16**. Prev left-aligned, next right-aligned (as desktop). Chặng 1 shows only "next"; Chặng 4 shows prev + "Quay lại / Toàn bộ hành trình". |
| CTA | `11` §9 mobile (`padding: 24px 20px 32px`; card radius 28, `padding: 36px 24px`, gap 16, no circle; H2 Bold 28 / 1.2, −0.28; sub Medium 15 / 1.5; light badges `flex:1` 138.5 × 53.4, gap 10; **no caption**). Chặng 2–4 H2 = "Bắt đầu hành trình cùng con ngay hôm nay." as one flowing string (wraps to ~3 lines at 287). |
| Chặng 1 body | The v2.1 mobile sections from `324:45487` exactly as implemented today (`11`, `12` §§ mobile, `13`), including the mobile FAQ (title 26, no subtitle). |
| Footer | `11` §11 mobile. |

Breakpoints: reuse the landing's existing 1120 px switch (`@media (min-width: 1120px)` in `styles/*.css`).

---

## 10. Implementation notes

- Routes (`apps/landing/src/routes.ts`): add `PageId`s `stage1`…`stage4` with vi/en paths, e.g. `/hanh-trinh/nhung-ngay-dau-doi/`, `/hanh-trinh/con-tap-kham-pha/`, `/hanh-trinh/to-mo-va-lon-khon/`, `/hanh-trinh/the-gioi-rieng-cua-con/` and `/en/journey/first-days/`, `/en/journey/exploring/`, `/en/journey/curious/`, `/en/journey/own-world/` (proposal; slugs are not in Figma). Prerender all eight; `alternateOf` already pairs pages by `page`.
- New components: `StageSwitcher`, `StageHero` (variant `photo` for Chặng 1, `icon` for 2–4), `StageHighlights`, `StagePrevNext`. Reuse `Photo`, `Icon`, `.eyebrow--*`, `Cta` (+ `title` prop and compact padding), `Nav` (+ per-page links), `Footer`.
- Headings: one `<h1>` per page (stage H1). On Chặng 1 the v2.1 sections keep their `<h2>`s; the v2.1 hero H1 is not rendered there.
- SEO/meta (title, description, OG image) for each stage page is not in Figma — needs copy.
- Privacy/logging: these pages hold no user data; nothing to add for R-xxx logging rules.

---

## 11. Ambiguities / gaps

1. **Nav vs `business-map.md` R-170.** R-170 lists the v3 nav as "Chăm con · Hiểu con · Kỷ niệm · Gia đình · Hỏi đáp" and a single long page. The stage pages (and the v3 home) use **"Hành trình · Năm đầu đời · Gia đình · Hỏi đáp"** and a multi-page site. R-170 needs updating once the owner confirms the split; link targets (§1) are a proposal.
2. **Stages 2–4 promise features with no D/R entry** (extends Q-039): logging first steps / first words / first trips (HL "Những bước chân đầu tiên"), routines for meals and naps beyond the baby care log ("Nếp nhỏ mỗi ngày"), age-appropriate play/movement ideas ("Chơi cùng con"), capturing "why" questions and sayings, emotions ("Cảm xúc", "gọi tên những cảm xúc"), children's artwork ("Tác phẩm của con"), family goals the child carries out ("Cả nhà cùng đặt mục tiêu nhỏ, con chủ động thực hiện"), and "Khoảng riêng của con" ("tôn trọng thế giới riêng con") which implies child-facing privacy controls — the model has no child users. The v3 home marks stages 2–4 as "Đang cùng con chuẩn bị" (`365:3529`), but the stage pages themselves carry no "coming soon" cue and the CTA says "Bắt đầu hành trình cùng con ngay hôm nay." with download badges. Owner decision needed: add a "Sắp có" chip/notice on stages 2–4, or confirm the copy.
3. **Age range.** Hero chips say Chặng 1 = 0–12 tháng … Chặng 4 = 6–12 tuổi; the FAQ answer "Từ ngày con chào đời… khi con lớn hơn, đây là nơi giữ lại ảnh và câu chuyện của con" is consistent, but no rule defines what the app does for a baby older than 12 months (care log, Hiểu con cards, Wonder Week). Confirm the V1 age scope.
4. **Chặng 4 "next" slot** is "Quay lại" / "Toàn bộ hành trình" with no arrow and no target; proposed `/#hanh-trinh`. Chặng 1 has no "previous" card (empty half) — not a link back to the home page.
5. **Active switcher pill** is 32 tall vs 34 for inactive pills (no border); recommended equalising with a transparent/ink border.
6. **No hover/focus/pressed states** for pills, prev/next cards, chips; chips are drawn as static labels (no targets).
7. **Stale layer names** in the stage CTA ("Đăng ký để là những gia đình đầu tiên…", "Miễn phí · 10 GB cho cả gia đình") and the quote texts (leading “) — the rendered copy is used here; if the owner intended a waitlist/sign-up for stages 2–4 it is not drawn (R-170: no forms).
8. **CTA padding differs** between Chặng 1 (32/96, = v2) and Chặng 2–4 (40/40, = v3 home). Kept as drawn; could be unified.
9. **Hero H1** is 54 px with no tracking, unlike the home display (57, −2 %). Kept as drawn.
10. **Chặng 1 hero photo** uses the 220 px raster at 240 px (soft at 2×) — same limitation as `11` §14.
11. **FAQ Q3–Q6 answers** still absent on the Chặng 1 page (as on v2.1; G-065); Chặng 2–4 have no FAQ at all.
12. **Mobile** (§9) and **routes/slugs** (§10) are engineering proposals; the owner/designer should review before the coverage checklist rows are marked done.
