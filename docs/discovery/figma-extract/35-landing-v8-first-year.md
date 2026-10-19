# 35 — Landing V8: "Năm đầu đời" page (replaces the Chặng 1 page)

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only; no node modified). Extracted 2026-10-19. Same conventions as `28-landing-v5b-home.md` / `33-landing-lumi-page.md`: token names from `packages/design-tokens/dist/tokens.css` (every `var(--…)` used below exists there), non-token values marked **(raw)**, every visible string copied **verbatim from `get_design_context`** (layer names are stale or cut at 30 characters; never copy them — e.g. the Quick title layer is named "Bận tay? Ghi một chạm ngay trê…" but its text is "Ghi nhanh từ widget và màn hình khoá.").

- Frame **`737:6362` "V8 · Năm đầu đời · Desktop"**, 1440 × 13710.2, inside section `734:5373` "Child Life Website — V8" (siblings: home desktop `735:5377`, home mobile `736:65570`, Lumi `737:67153`, Chặng 2 `738:7309`, component `734:5426` "V8/CTA tải app", notes `739:7389` / `739:7403`). **Desktop, Vietnamese only, Light only. No mobile frame for this page**, no hover/focus states, no motion.
- Page background **`cloud`** (#F6FCFB): sections without a fill sit on it.
- **Most sections already exist** on the current Chặng 1 page (`StagePage.tsx`, Figma `370:50752`) or inside the home "Năm đầu đời" frame (`FirstYear.tsx`). For those, this doc lists **only what differs**; everything not mentioned (panel mock-ups, coordinates, bullets, chip copy) was checked against the current code and is **unchanged** (`at()` positions in `Care.tsx`, `Reminders.tsx`, `Cocare.tsx`, `Library.tsx`, `Night.tsx`, `Quick.tsx` match the V8 nodes to the pixel).
- Screenshots (not committed): `scratchpad/v8/fy-hero.png` (1200 × 370), `scratchpad/v8/fy-vaccines.png` (1200 × 567).

Designer notes that apply (`739:7389` #10, verbatim): "10. Trang Năm đầu đời gom 5 nhóm + điều hướng nhanh; tiêu đề mô tả chức năng; “Thẻ theo tuổi” → “Gợi ý theo tuổi”; “cha mẹ” → “ba mẹ”." Verified in §0.4.

---

## 0. Global

### 0.1 Section order (Figma) and what to build

| # | Figma section | Node | y · h | Background | Padding (t r b l) | Status vs current site | Component |
|---|---|---|---|---|---|---|---|
| 1 | Nav | 737:6363 | 0 · 81 | `cloud` | 20 96 | changed links (§1) | `Chrome.tsx Nav` |
| 2 | Hero | 737:6382 | 81 · 444 | `mint-soft` | 48 96 56 96 | **NEW** (replaces StageSwitcher + StageHero) | new |
| 3 | Điều hướng nhanh | 737:6434 | 525 · 63 | `surface` + bottom border `separator` | 14 96 | **NEW** | new |
| 4 | Nhóm 01 · Ghi & nhắc | 737:6462 | 588 · 131 | page | 64 96 8 96 | **NEW** | new `GroupHeader` |
| 5 | Thao tác nhanh | 737:6469 | 719 · 1106 | page | 96 96 64 96 | title changed | `Quick` |
| 6 | Chăm sóc | 737:6749 | 1825 · 760 | page | 96 96 64 96 | title changed | `Care` |
| 7 | Nhắc nhở | 737:6870 | 2585 · 760 | page | 96 96 64 96 | title changed | `Reminders` |
| 8 | Nhóm 02 · Cả nhà cùng chăm | 737:6966 | 3345 · 131 | page | 64 96 8 96 | **NEW** | `GroupHeader` |
| 9 | Cùng chăm | 737:6973 | 3476 · 728 | page | 64 96 | title changed | `Cocare` |
| 10 | Quyền xem | 737:7063 | 4204 · 883 | page | 112 96 96 96 | title changed; **moved up** (was after Night) | `Roles` |
| 11 | Nhóm 03 · Hiểu con theo tuổi | 737:7159 | 5087 · 131 | page | 64 96 8 96 | **NEW** | `GroupHeader` |
| 12 | Hiểu con | 737:7166 | 5218 · 1093 | page | 112 96 96 96 | title + column 1 title changed | `Understand` |
| 13 | Lịch tiêm & tăng trưởng | 737:7319 | 6311 · 680 | page | 96 96 64 96 | **NEW section** | new `Vaccines` |
| 14 | Thư viện & ăn dặm | 737:7485 | 6991 · 760 | page | 96 96 64 96 | title changed | `Library` |
| 15 | Sơ cấp cứu | 737:7581 | 7751 · 760 | page | 96 96 64 96 | title changed | `FirstAid` |
| 16 | Nhóm 04 · Kỷ niệm | 737:7665 | 8511 · 131 | page | 64 96 8 96 | **NEW** | `GroupHeader` |
| 17 | Tuổi thơ | 737:7672 | 8642 · 1499 | `surface` | 112 96 | title changed | `Memories` |
| 18 | Nhóm 05 · Tiện ích | 737:7890 | 10141 · 131 | page | 64 96 8 96 | **NEW** | `GroupHeader` |
| 19 | Night care | 737:7897 | 10272 · 688 | page (dark card) | 64 96 | title changed | `Night` |
| 20 | Theo cách của bạn | 737:8081 | 10960 · 588 | page (white card) | 24 96 | **added to this page** (was home only), unchanged copy | `YourWay` |
| 21 | Apple Watch | 737:8209 | 11548 · 722 | page (dark card) | 24 96 (+ inner 0 48) | **added to this page** (was home only), unchanged copy | `WatchSection` |
| 22 | Hỏi đáp | 737:8244 | 12270 · 724 | page | **32** 96 112 96 | unchanged; **now before** the CTA | `Faq` |
| 23 | Kết | 737:8276 | 12994 · 532 | `surface` | 24 96 96 96 | **NEW card** (replaces the `Cta` band) | new / `Cta` variant |
| 24 | Footer | 737:8304 | 13526 · 184 | page | 32 96 40 96 | unchanged | `Footer` |

**Removed from the current Chặng 1 page** (`StagePage.tsx` stage1 branch): `StageSwitcher` ("Hành trình ›" + 4 stage pills), `StageHero` ("Những ngày đầu đời."), `Everything` (bento "Tất cả trong một app" / "Mọi điều về con, ở cùng một nơi."), `StagePrevNext` ("Các chặng" prev/next), the `Cta` band ("Bớt phải nhớ. / Thêm thời gian bên con."). Content keys `c.everything.*`, `c.cta.*`, `c.journey.prev/next/prevNextLabel` stay if other pages still use them (BentoGrid is used by the home `FirstYear`; `Cta` by the home and Chặng 2–4) — check before deleting.

**Not on this page** (live elsewhere today): `Utilities` (Sơ cứu trẻ em card + "Sổ chi tiêu chung cho bé"), `LumiBlock`, `ForBabyBlock`, `FirstYearDetail` ("Xem đầy đủ năm đầu đời"). The spending book is therefore **not advertised** on this page except the YourWay bullet "Danh mục chi tiêu riêng".

### 0.2 Text styles (Be Vietnam Pro)

H1 **Bold 50 / 1.12** (hero, new size); H2 Bold 44 / 1.18, tracking −0.66 px (all feature sections; Nhắc nhở, Hiểu con, Lịch tiêm, Thư viện, Sơ cấp cứu have **no tracking** in V8 — the current CSS value is fine, do not special-case); **group title Bold 30 / normal** (new); Kết title Bold 40 / 1.18; FAQ title Bold 36 / 1.2 (−0.36); YourWay title Bold 32 / 1.18; leads Medium 18 / 1.55; group subtitle **Medium 15 / normal** (new); eyebrow SemiBold 13 (pill 6 × 12, r 999); chips SemiBold 14 (quick nav) / 12 (hero).

### 0.3 Reused tokens

`cloud` #F6FCFB, `surface` #FFFFFF, `surface-2` #EEF6F5, `separator` #DCE8E7, `ink` #173D44, `ink-muted` #55707A, `mint-soft` #E6F7F5, `mint-deep` #087F7B, `on-mint-deep` #FFFFFF, `mint-text` #06716D, `sunshine-soft` #FFF4D6, `peach-soft` #FFE3DA, `care-growth-soft` #FDEDE2, `care-bottle-soft` #E5F1FB. Dark cards: `#163d44` **(raw)** for Apple Watch and Kết (≈ `ink` #173D44 — use `var(--ink)` only if the card must not flip in a Night palette; the current `.watch-band` already uses `var(--ink)`), `#0c1719` **(raw)** for Night care (unchanged).

### 0.4 Design-note verification (`739:7389` #10)

| Note | Found in frame? |
|---|---|
| "gom 5 nhóm + điều hướng nhanh" | **Yes** — 5 group headers 01–05 and the "Đi nhanh tới:" bar with 5 chips whose labels equal the group titles. |
| "tiêu đề mô tả chức năng" | **Yes** — 11 section titles rewritten to say what the feature is (§5–§19 below; e.g. "Nhắc cữ bú, giấc ngủ cho đúng người.", "Lịch tiêm và biểu đồ tăng trưởng."). Not applied to Apple Watch ("Tay bế con, vẫn ghi kịp từng cữ." unchanged) or Theo cách của bạn. |
| "“Thẻ theo tuổi” → “Gợi ý theo tuổi”" | **Yes** in Hiểu con column 1 title and the H2. **Not propagated** by Figma to `everything.tiles[*].body` "Thẻ theo tuổi và lịch Wonder Week…" (home bento, not on this page) or FAQ answer 5 "…các thẻ theo tuổi…" (collapsed in Figma, so not visible). Recommend applying it there too (§9). |
| "“cha mẹ” → “ba mẹ”" | **No “cha mẹ” on this page** (the remaining ones in `vi.ts` are home-only: `home.hero.lead`, `home.faq.items[0].a`, `home.utilities.lead`). **But** Nhắc nhở bullet 2 still says "**Bố** mẹ và người chăm — không làm phiền ông bà" in Figma — see §25 #3. |

---

## 1. Nav (`737:6363`)

Layout unchanged from today (`cloud` bg, `padding 20px 96px`, gap 32, logo lockup 176 × 34, spacer, links Medium 15 `ink`, button). **Links and button changed** — shared by every V8 page (home `735:5378` reads "Trợ Lý Lumi" instead of "Lumi", see §25 #1):

| Position | Figma text (verbatim) | Current `c.nav.links` | Target on this page (proposal) |
|---|---|---|---|
| 1 | "Chăm sóc" | — (new; `journey: 'Hành trình'` is dropped) | `#ghi-va-nhac` (group 01 on this page), scroll-spy |
| 2 | "Kỷ niệm" | `memories: 'Kỷ niệm'` (moved from 5th to 2nd) | `#ky-niem` (group 04 on this page), scroll-spy |
| 3 | "Lumi" (an `<a>` in Figma) | `lumi: 'Lumi'` | `/lumi/` · `/en/lumi/`; keeps the mint accent |
| 4 | "Năm đầu đời" | `firstYear: 'Năm đầu đời'` | this page, `aria-current="page"` (Figma draws no active state; keep the current one) |
| 5 | "Hỏi đáp" | `faq: 'Hỏi đáp'` | `#hoi-dap` on this page |
| button | "Bắt đầu" (pill `mint-deep`, `padding 11px 20px`, SemiBold 15 `on-mint-deep`) | `download: 'Tải miễn phí'`, `downloadShort: 'Tải app'` | `#tai-app` (the Kết card) |

Removed links: "Hành trình" and "Các chặng". The language switch ("EN" + globe) is our addition (D-012) — keep it between the links and the button. Home targets for "Chăm sóc" / "Kỷ niệm" belong to the V8 home spec; on other pages they should link to this page's `#ghi-va-nhac` / `#ky-niem` only if the V8 home has no equivalent — coordinate with that spec. New key needed: `nav.links.care` = "Chăm sóc"; `nav.download` = "Bắt đầu" (keep `downloadShort` for mobile, "Tải app" is fine).

---

## 2. Hero (`737:6382`) — NEW

Replaces `StageSwitcher` + `StageHero` on this page. `section` bg **`mint-soft`**, `display:flex; gap:56px; align-items:center; padding:48px 96px 56px`. Height 444.

**Copy column** (`737:6383`): width 620, flex column, gap 18.
1. Chip row (`737:6384`): flex, gap 8.
   - Chip "Đang có trong app" (`737:6388`): bg `mint-deep`, `padding 5px 10px`, r 999, gap 6; `check` icon 12 px in `on-mint-deep` (white); text **SemiBold 12 `on-mint-deep`**: **"Đang có trong app"**.
   - Chip (`737:6390`): bg `surface`, `padding 5px 10px`, r 999; **SemiBold 12 `ink`**: **"Chặng 1 · 0–12 tháng"** (en dash, middle dot).
2. H1 (`737:6391`) **Bold 50 / 1.12 `ink`**: **"Năm đầu đời của con, gọn trong một app."** (one string; wraps after "con," at 620 px).
3. Lead (`737:6392`) **Medium 18 / 1.55 `ink-muted`**: **"Ghi chép và nhắc nhở cho cả nhà, gợi ý theo tuổi, sơ cứu, ăn dặm và nơi giữ kỷ niệm của con — dùng được ngay hôm nay."**
4. Download block = instance of **"V8/CTA tải app"** (`737:6393` → component `734:5426`, props `Bố cục = Ngang`, `Trạng thái = Sau ra mắt`): flex column, gap 10.
   - Row (gap 12) of two white badges (`#fff` **(raw)**, r 16.1, `padding 11.5px 23px 11.5px 18.4px`, gap 11.5, glyph 25.3 px, text `#141417` **(raw)**: prefix Medium 12.65 "Tải trên", name SemiBold 21.85 "App Store" / "Google Play"). Same strings as `c.stores.*` — reuse `StoreBadges variant="light"` (white badges).
   - Caption Medium 13 `ink-muted`: **"Tải miễn phí trên iPhone và Android."** (new string; the current `hero.caption` is "Miễn phí trên iPhone và Android.").
   - Component description (verbatim): "Trước ra mắt: chỉ dùng khi đã có luồng đăng ký email thật. Sau ra mắt: nút App Store / Google Play dẫn thẳng tới trang ứng dụng. Không dùng nút “Tải ngay” rồi báo “sắp có”." → conflicts with today's `StoreBadges` (toast `stores.comingSoon` while `storeLinks` are `null`) — see §24 #1.

**Illustration** (`737:6433` "Minh hoạ"): 572 × 340, r 32, `overflow:hidden`, no fill of its own (sits on `mint-soft`).
- It is **exactly the Hành trình card art at 2×**: `src/assets/figma/journey-art-stage1.svg` (295 × 170, baby on a mint blanket, moon, bottle, three sparkles; its own comment says the band colour and the two light circles are drawn by the page). Render it at **590 × 340**, `left:-8.5px; top:0` inside the panel (Art frame `737:6409` is 589 × 340 at x −8.5).
- Two decorative circles (inside the Art frame): 440 × 440 at (300, 80) and 240 × 240 at (−60, −80) — the same as `.chapter__circle--a` (220 at 150, 40, `#fff` opacity 0.45) and `--b` (120 at −30, −40, opacity 0.35) doubled. Reuse those styles ×2.
- Decorative: `alt=""` / `aria-hidden`. Eager-load (above the fold).

Mobile (not designed): stack copy then art (art full width, aspect 572:340), H1 ~34 px.

---

## 3. Điều hướng nhanh (`737:6434`) — NEW

A full-width bar under the hero. bg `surface`, `border-bottom: 1px solid var(--separator)`, `display:flex; align-items:center; gap:10px; padding:14px 96px`. Height 63.

- Label (`737:6435`) **SemiBold 14 `ink-muted`**: **"Đi nhanh tới:"**
- 5 chips, each `display:flex; gap:6px; align-items:center; padding:8px 14px; border-radius:999px`, icon 14 px + text **SemiBold 14**:

| # | Node | Icon (`Icon` map) | Text (verbatim) | Fill / text in Figma | Links to |
|---|---|---|---|---|---|
| 1 | 737:6439 | `feed` ✔ | "Ghi & nhắc" | **`mint-deep` / `on-mint-deep`** (selected state) | `#ghi-va-nhac` |
| 2 | 737:6446 | `family` ✔ | "Cả nhà cùng chăm" | `cloud` / `ink` | `#ca-nha-cung-cham` |
| 3 | 737:6450 | `star` ✔ | "Hiểu con theo tuổi" | `cloud` / `ink` | `#hieu-con-theo-tuoi` |
| 4 | 737:6454 | `heart` ✔ | "Kỷ niệm" | `cloud` / `ink` | `#ky-niem` |
| 5 | 737:6461 | `sliders` ✔ | "Tiện ích" | `cloud` / `ink` | `#tien-ich` |

All five icons exist in `components/primitives.tsx`. Icon colour = text colour (`currentColor`).

Behaviour (proposal; Figma is static): `<nav aria-label="Đi nhanh tới các nhóm">` with plain anchor links. Chip 1 is drawn "selected": implement as **scroll-spy** (the chip of the group in view gets the `mint-deep` style and `aria-current="true"`), reusing the nav's `data-spy` mechanism (`effects.ts startNav`). Optionally sticky under the nav (`top` = nav height) — not in Figma; if sticky, keep the bottom border. On mobile: one row, horizontal scroll (`overflow-x:auto`, no scrollbar), label hidden or kept as the first item.

---

## 4. Group headers "Nhóm · …" — NEW (`737:6462`, `737:6966`, `737:7159`, `737:7665`, `737:7890`)

One component, 5 instances. Frame: no fill (all five sit on the page background `cloud`), `display:flex; align-items:center; gap:16px; padding:64px 96px 8px`. Height 131.

- **n** pill: bg `mint-deep`, `padding:8px 14px`, r 999 (45 × 35); text **Bold 15 `on-mint-deep`**, two digits.
- **t** block: flex column, gap 2, no wrap: title **Bold 30 / normal `ink`**; subtitle **Medium 15 / normal `ink-muted`**.
- Rule: `flex:1; height:1px; background: var(--separator)`.

| n | t (title, verbatim) | subtitle (verbatim) | Wraps sections | Proposed id |
|---|---|---|---|---|
| "01" | "Ghi & nhắc" | "Ghi trong vài chạm, nhắc đúng lúc." | Thao tác nhanh, Chăm sóc, Nhắc nhở | `ghi-va-nhac` |
| "02" | "Cả nhà cùng chăm" | "Ba mẹ, ông bà và người chăm cùng một nhật ký." | Cùng chăm, Quyền xem | `ca-nha-cung-cham` |
| "03" | "Hiểu con theo tuổi" | "Mốc, tiêm chủng, bài đọc và sơ cứu theo tuổi của bé." | Hiểu con, Lịch tiêm & tăng trưởng, Thư viện & ăn dặm, Sơ cấp cứu | `hieu-con-theo-tuoi` |
| "04" | "Kỷ niệm" | "Giữ lại những lần đầu tiên của con." | Tuổi thơ | `ky-niem` |
| "05" | "Tiện ích" | "Chế độ đêm, tuỳ chỉnh màn hình và Apple Watch." | Night care, Theo cách của bạn, Apple Watch | `tien-ich` |

Semantics: each group = a `<section id="…" aria-labelledby="…">` whose header title is the `<h2>`; the feature sections inside then become `<h3>` (their visual H2 style stays). The number is decorative (`aria-hidden`). Add `scroll-margin-top` = nav height (+ quick-nav height if sticky).

Mobile (proposal): `padding:40px 16px 8px`, title 24 px, subtitle wraps (drop `nowrap`), rule hidden below 600 px.

Note: group 01's subtitle and Thao tác nhanh's eyebrow "Khi bận tay" are both kept. Group 05 says "Chế độ đêm, tuỳ chỉnh màn hình và Apple Watch." — "tuỳ chỉnh màn hình" refers to Theo cách của bạn.

---

## 5. Thao tác nhanh (`737:6469`) — `Quick`

Layout, stage (1248 × 600, r 40, gradient), widgets, lock screen, labels, note, steps: **unchanged**.

| Key | Current | V8 (verbatim) |
|---|---|---|
| `quick.title` | "Tay bế con, vẫn ghi lại được trong một chạm." | **"Ghi nhanh từ widget và màn hình khoá."** |
| `quick.eyebrow` | "Khi bận tay" | unchanged |
| `quick.lead` | unchanged: "Không cần mở app, không cần nhớ giờ. Chạm ngay trên màn hình điện thoại là xong — để bạn ở bên con lâu hơn một chút." | — |
| `quick.steps[2].sub` | "Không ai phải hỏi lại “con ăn chưa?”" | Figma uses straight quotes `"con ăn chưa?"` — **keep the curly quotes** (typography fix, not a copy change). |

Section padding `96 96 64` (was the generic section padding); head width 1100 (title), lead 660. `id="cham-con"` stays (now inside group `ghi-va-nhac`).

## 6. Chăm sóc (`737:6749`) — `Care`

Panel left (640 × 600, `mint-soft`, r 40), copy right, gap 96 — **unchanged**.

| Key | Current | V8 (verbatim) |
|---|---|---|
| `care.title` | "Nhìn là hiểu một ngày của con." | **"Nhật ký một ngày của con, nhìn là hiểu."** |

Eyebrow "Chăm sóc mỗi ngày", lead, 3 bullets, tiles, chip "Vẫn đếm giờ khi bạn tắt màn hình", "Đã ghi hôm nay" card: unchanged.

## 7. Nhắc nhở (`737:6870`) — `Reminders`

Copy left, panel right (`sunshine-soft`), gap 96 — **unchanged**.

| Key | Current | V8 (verbatim) |
|---|---|---|
| `reminders.title` | "Nhắc đúng lúc, cả nhà cùng biết." | **"Nhắc cữ bú, giấc ngủ cho đúng người."** |
| `reminders.bullets[1].sub` | "Bố mẹ và người chăm — không làm phiền ông bà" | Figma unchanged ("Bố mẹ…"); see §25 #3 for the "ba mẹ" note |

Lead, notification, rule card, fixed card, done chip: unchanged.

## 8. Cùng chăm (`737:6973`) — `Cocare`

Panel left (`sunshine` 640 × 600 with Illustration/Family), copy right — **unchanged**. Section padding **64 96** (top 64, not 96, because the group header precedes it).

| Key | Current | V8 (verbatim) |
|---|---|---|
| `cocare.title` | "Cả nhà cùng chăm, không ai phải hỏi lại." | **"Cả nhà ghi chung một nhật ký."** |
| `cocare.lead` | "…không cần nhắn tin hỏi “con ăn lúc mấy giờ?”." | Figma straight quotes — keep curly. |

Bullets ("Biết con đã được chăm đến đâu", "Đi làm vẫn yên tâm khi bé ở nhà với bà, với cô", "Không có mạng vẫn ghi được, không mất gì"), "Bạn chọn quyền", "Vừa ghi" feed: unchanged.

## 9. Quyền xem (`737:7063`) — `Roles` (moved)

**Order change:** now directly after Cùng chăm inside group 02 (today it is after `Night`, near the end). Layout (centred head, 3 role cards, 2 notes) unchanged; padding `112 96 96`, gap 48.

| Key | Current | V8 (verbatim) |
|---|---|---|
| `roles.title` | "Ảnh của con, chỉ người nhà mới thấy." | **"Bạn chọn ai được xem ảnh và thông tin của con."** (width 1000) |
| `roles.eyebrow`, `roles.lead` | "Riêng tư", "Mỗi người trong nhà thấy đúng phần cần thấy. Bạn luôn là người quyết định." | unchanged |
| `roles.cards[1].permissions[1]` | PROPOSED (Q-008): `allowed:false`, "Không xem ảnh và kỷ niệm của con" | Figma **still** `check`, "Gửi ảnh bé cho ba mẹ, không xem album riêng" → **keep the PROPOSED override** (Q-008, R-171). |
| `roles.notes[0]` | PROPOSED (D-001): "Mỗi ảnh mới, bạn chọn ai được xem: cả gia đình hay chỉ ba mẹ. Đổi lại lúc nào cũng được." | Figma **still** "Ảnh mới mặc định chỉ ba mẹ thấy. Muốn khoe cả nhà, bạn chỉ cần chọn "Gia đình"." → **keep the PROPOSED override** (contradicts D-001, R-171). |

Section id `rieng-tu` stays.

## 10. Hiểu con (`737:7166`) — `Understand`

Centred head + 3 columns (Visual 428 tall: `sunshine-soft` / `care-sleep-soft` / `peach-soft`, r 32) + footnote pill — **unchanged** except:

| Key | Current | V8 (verbatim) |
|---|---|---|
| `understand.title` | "Hiểu con hơn, mỗi tuần một chút." | **"Gợi ý theo tuổi: tuần này của bé."** (width 760, no tracking) |
| `understand.columns[0].title` | "Thẻ theo tuổi" | **"Gợi ý theo tuổi"** |

Unchanged: eyebrow "Hiểu con", lead, column bodies (column 1 body still "Mỗi giai đoạn một thẻ ngắn: bé đang thế nào, ba mẹ có thể thử gì, kèm bài viết và mốc liên quan." — Figma keeps "thẻ" here), age card, Wonder Week card, milestone card, note "Nội dung do đội chuyên môn Child Life soạn và rà soát. Lịch Wonder Week chỉ là dự kiến — mỗi bé có nhịp riêng, app không chấm điểm hay so sánh con."

Also apply the rename where Figma does not show it (recommendation, engineering): `faq.items[4].a` "…cập nhật các thẻ theo tuổi, bài viết…" → "…cập nhật các gợi ý theo tuổi, bài viết…" (same text in `home.faq.items[*]`); `everything.tiles[*].body` "Thẻ theo tuổi và lịch Wonder Week dự kiến cho từng giai đoạn." → "Gợi ý theo tuổi và lịch Wonder Week dự kiến cho từng giai đoạn." and `bodyShort` "Thẻ theo tuổi & Wonder Week" → "Gợi ý theo tuổi & Wonder Week" (home bento).

## 11. Lịch tiêm & tăng trưởng (`737:7319`) — NEW section

Section: `padding:96px 96px 64px`; Row `display:flex; gap:96px; align-items:center` — **panel left, copy right** (use `split split--visual-first`). Height 680. Proposed `id="tiem-chung"`.

### 11.1 Panel (`737:7321`)
600 × 520, bg `mint-soft`, r 40, `overflow:hidden`, children absolute.

**Card "Lịch tiêm"** (`737:7322`): at (40, 40), width 440, bg `surface`, r 22, `padding:20px 22px`, flex column gap 12, shadow `0 8px 12px rgba(23,61,68,.08), 0 1px 1px rgba(23,61,68,.06)` (the site's `shadow-card` drop shadow pair).
- Title **Bold 16 `ink`**: **"Lịch tiêm chủng · Teddy"**
- Header row: a 104 px empty label cell, then 6 columns of **46 px**, centred, **SemiBold 11 `ink-muted`**: **"Sơ sinh"**, **"2 th"**, **"3 th"**, **"4 th"**, **"6 th"**, **"9 th"**.
- 6 rows (row height 28; label cell 104 px, **SemiBold 13 `ink`**), cells 46 × 28 centred:

| Row label (verbatim) | Sơ sinh | 2 th | 3 th | 4 th | 6 th | 9 th |
|---|---|---|---|---|---|---|
| "Viêm gan B" | ✔ | · | · | · | · | · |
| "Lao" | ✔ | · | · | · | · | · |
| "6 trong 1" | · | ✔ | ✔ | ○ | · | · |
| "Phế cầu" | · | ✔ | ✔ | · | · | · |
| "Rota" | · | ✔ | ✔ | · | · | · |
| "Sởi" | · | · | · | · | · | ○ |

  - ✔ **done**: circle bg `mint-deep`, `padding:3px`, r 999, `check` icon 12 px white (≈ 18 px disc).
  - · **no dose**: a small dot ≈ 4 px, `separator`-grey (exported as an SVG in Figma; draw with CSS).
  - ○ **next / due**: ≈ 14 px circle, fill `sunshine-soft`, 1.5 px border `sunshine` (#FFD166) (from the screenshot; the SVG was not downloaded).
  - Use a real `<table>` (caption = the title) with `aria-label`s on the cells ("Đã tiêm", "Sắp tới") or mark the whole mock `aria-hidden` like the other panels and rely on the copy column. Recommendation: `aria-hidden`, consistent with the other mock panels.
- "next" strip (`737:7437`): bg `sunshine-soft`, r 14, `padding:10px 12px`, gap 8; `clock` icon 16 (`ink`); **SemiBold 13 `ink`**: **"Mũi tiếp theo: 6 trong 1 · lần 3 · 17/11"**. Hugs its content (not full width).

**Card "Growth"** (`737:7440`): at (330, 370), width 240, bg `surface`, r 22, `padding:16px 18px`, flex column gap 6, same shadow; overlaps the bottom-right of the schedule card.
- **Medium 13 `ink-muted`**: **"Cân nặng"**
- **Bold 24 `ink`**: **"7,8 kg"**
- Chip: bg `mint-soft`, `padding:4px 10px`, r 999, **SemiBold 12 `mint-text`**: **"Trong khoảng chuẩn WHO"**

### 11.2 Copy (`737:7445`)
Flex column gap 36.
- Head (gap 16):
  - Eyebrow pill `mint-soft` / **SemiBold 13 `mint-text`**: **"Sức khoẻ của con"**
  - H2 **Bold 44 / 1.18 `ink`**, width 520: **"Lịch tiêm và biểu đồ tăng trưởng."**
  - Lead **Medium 18 / 1.55 `ink-muted`**, width 480: **"Biết con đã tiêm gì, sắp tiêm gì, lớn lên ra sao — không cần lục sổ."**
- Bullets (gap 18; each row gap 16; icon tile `padding:9px; r 12`, icon 18; title **SemiBold 16 `ink`**, sub **Medium 14 / 1.5 `ink-muted`**, gap 3) — the same pattern as Nhắc nhở / Thư viện bullets (`CompactBullets` or the feature bullet list):

| # | Icon (tile tint) | Title (verbatim) | Sub (verbatim) |
|---|---|---|---|
| 1 | `check` (`mint-soft`) | "Lịch tiêm theo tháng tuổi" | "Đánh dấu mũi đã tiêm, nhắc trước ngày tiêm cho cả nhà." |
| 2 | `ruler` (`care-growth-soft`) | "Cân nặng, chiều dài theo chuẩn WHO" | "Biểu đồ dễ đọc, không chấm điểm hay so sánh con." |
| 3 | `feed` (`care-bottle-soft`) | "Dinh dưỡng theo giai đoạn" | "Lượng sữa tham khảo và nhóm chất cần chú ý theo tuổi." |

- Footnote **Medium 13 / normal `ink-muted`**, width 480: **"Nội dung tham khảo, được chuyên môn rà soát. Lịch tiêm cụ thể theo hướng dẫn của cơ sở y tế."**

All icons (`check`, `ruler`, `feed`, `clock`) exist in the `Icon` map. Icon stroke colours follow the existing bullet tints (mint-text / care-growth-ink / care-bottle-ink).

Mobile (proposal): copy first then the panel scaled with `Fit` (600 × 520), like the other split sections.

New content key: `vaccines` (see §16 for en).

## 12. Thư viện & ăn dặm (`737:7485`) — `Library`

Copy left, panel right (`mint-soft`) — **unchanged**.

| Key | Current | V8 (verbatim) |
|---|---|---|
| `library.title` | "Băn khoăn gì, có bài đọc ngắn và dễ hiểu." | **"Thư viện chăm bé và ăn dặm."** |

Eyebrow "Thư viện & ăn dặm", lead, bullets, search, articles, solids card, "Đã lưu vào Thư viện": unchanged.

## 13. Sơ cấp cứu (`737:7581`) — `FirstAid`

Panel left (`peach-soft`), copy right — **unchanged**.

| Key | Current | V8 (verbatim) |
|---|---|---|
| `firstAid.title` | "Khi con gặp chuyện bất ngờ, bạn đã có sẵn hướng dẫn." | **"Sơ cứu trẻ em: hướng dẫn từng bước."** |

Everything else unchanged (6 topics, "Bỏng nhẹ · bước 1/4", bullets incl. "Rà soát cùng chuyên gia y tế").

## 14. Tuổi thơ (`737:7672`) — `Memories`

`surface` band, `padding:112px 96px`, gap 56; timeline 1248 × 580 and 3 tiles — **unchanged**.

| Key | Current | V8 (verbatim) |
|---|---|---|
| `memories.title` | "Nơi lưu giữ trọn tuổi thơ của con." | **"Ảnh, thiệp, video và nhật ký của con."** (width 900) |
| `memories.tiles.family.notifications[1].text` | PROPOSED (Q-009): "Ông ngoại thương 3 ảnh mới" | Figma **still** "Ông ngoại đã xem 12 ảnh mới" → **keep the PROPOSED override** (Q-009). |

Lead, timeline (7 items + "…và mọi năm sau nữa"), tile copy, letter, polaroid, other notifications: unchanged.

Id: the Memories `<section>` currently owns `id="ky-niem"`; on this page the **group 04 wrapper** takes `ky-niem` (nav + chip target), so `Memories` needs an `id` prop (or no id) here to avoid a duplicate id.

## 15. Night care (`737:7897`) — `Night`

Dark card (`#0c1719`, r 40, `padding-left:80px`, gap 64; visual 600 × 560) — **unchanged**. Section padding **64 96**.

| Key | Current | V8 (verbatim) |
|---|---|---|
| `night.title` | "Dịu mắt cho những cữ bú lúc nửa đêm." | **"Chế độ đêm cho những cữ bú khuya."** (width 460) |

Eyebrow "Cho những đêm thức giấc", lead, 2 checks, live activity, widgets, circular accessories: unchanged.

## 16. Theo cách của bạn (`737:8081`) — `YourWay` (moved here)

Today rendered only inside the home `FirstYear` frame (`c.home.yourWay`). On this page: wrapper `padding:24px 96px`; inner white card = the current `.your-way` desktop style (`surface`, r 32, `padding:40px 48px`, `shadow-card`), Row gap 96, panel 600 × 460 `sunshine-soft` r 40. **All strings identical to `c.home.yourWay`** (eyebrow "Theo cách của bạn", title "Ứng dụng của nhà bạn, theo nhịp của nhà bạn." Bold 32 / 1.18, lead, 3 bullets, mock "Tuỳ chỉnh Hôm nay", chip "Chế độ đêm dịu mắt"). Minor: the night chip is at (40, **322**) in V8 vs `at(40, 330)` in code — align to 322.

Heading level: the component renders `<h3>`; inside group 05 that is correct. If the V8 home drops YourWay (its "6 · Tiện ích khác" is a grid), move the keys from `c.home.yourWay` to a page-level key (e.g. `c.yourWay`) — coordinate with the home spec.

## 17. Apple Watch (`737:8209`) — `WatchSection` (moved here)

Today rendered only inside the home `FirstYear` frame (`c.home.watch`). On this page: wrapper `padding:24px 96px`, inner frame `padding:0 48px` → the dark card is **1152 px** wide (not 1248); card bg `#163d44` **(raw, ≈ `ink`)**, r 40, `padding:56px 48px 56px 64px`, gap 80; watches visual 560 × 560. **All strings identical to `c.home.watch`** (eyebrow "Apple Watch" on `sunshine`, title "Tay bế con," / "vẫn ghi kịp từng cữ.", lead, 4 bullets, note "Dành cho Apple Watch, đi kèm ứng dụng iPhone", W01 / W03 / W07 mocks). Keep `id="apple-watch"`. Same key-move remark as §16.

## 18. Hỏi đáp (`737:8244`) — `Faq`

Unchanged component and items: title "Câu hỏi thường gặp", sub "Còn điều gì băn khoăn? Cứ nhắn cho chúng tôi nhé.", the same **6 questions as `c.faq.items`** (1–2 open with chevron, 3–6 closed with plus; Figma shows only answers 1–2, identical to today). Two Figma layers are misnamed "Có cần ghi đủ mỗi ngày không?" but read "Nội dung gợi ý trong app do ai soạn?" and "Lịch Wonder Week có đúng với mọi bé không?" — ignore the names.

**Order change:** FAQ now comes **before** the closing CTA (today: `Cta` then `Faq`). Section padding **32 96 112** (small top because Apple Watch's wrapper ends with 24).

## 19. Kết (`737:8276`) — NEW closing card (replaces the `Cta` band here)

Section bg **`surface`**, `padding:24px 96px 96px`. Proposed `id="tai-app"` (nav button target; today's `Cta` owns it).

Card "Thẻ" (`737:8277`): width 1248, bg `#163d44` **(raw)**, r 40, `padding:56px`, `display:flex; gap:48px; align-items:center`.
- Copy column (`737:8278`) width 620, flex column gap 16:
  - Title **Bold 40 / 1.18 white**: **"Bắt đầu từ năm đầu đời của con."**
  - Sub **Medium 17 / 1.55 `#cce0e0` (raw)**: **"Ghi chép, nhắc nhở và kỷ niệm — cả nhà cùng một nơi."**
  - "V8/CTA tải app" (`737:8281`, Ngang / Sau ra mắt): the same white badges as §2; caption Medium 13 **`#cce0e0`** (not `ink-muted`): **"Tải miễn phí trên iPhone và Android."**
- Photo (`737:8297`): 420 × 300, r 28, bg `surface-2`, `overflow:hidden`; Illustration/Photo with the **sun** gradient (255,241,201 → 249,215,126) = `photos.sun` (`teddy-one-couch.jpg`) in `components/primitives.tsx`; the 420 × 420 image is offset `top:-60px` → `object-fit:cover; object-position:50% 50%` in a 420 × 300 box. Decorative `alt=""`.

The current `Cta` (title pair + `cta.sub` "Miễn phí trên iPhone và Android. Mời cả nhà chỉ trong một phút." + caption "Miễn phí cho cả gia đình" + circle decoration, no photo) does not match: add a variant (`<Cta variant="card" photo …>`) or a new `ClosingCard` reading new keys. The V8 home and Chặng 2 Kết frames use the same component (`735:6497`, `738:7450`) with their own copy — coordinate.

Mobile (proposal): stack, photo full width (aspect 420:300) below the copy, card `padding:32px 20px`, title 28 px.

## 20. Footer (`737:8304`)

Unchanged: rule `separator` 1 px, lockup 0.8, "© 2026 Child Life", "Quyền riêng tư", "Điều khoản", "Liên hệ" (all equal `c.footer.*`); the language link stays (our addition).

---

## 21. Section order and ids (proposal)

```
Nav
Hero                                  #gioi-thieu
Điều hướng nhanh (nav)                —
<section #ghi-va-nhac>       Nhóm 01 → Quick #cham-con · Care #cham-soc · Reminders #nhac-nho
<section #ca-nha-cung-cham>  Nhóm 02 → Cocare #gia-dinh · Roles #rieng-tu
<section #hieu-con-theo-tuoi> Nhóm 03 → Understand #hieu-con · Vaccines #tiem-chung · Library #thu-vien · FirstAid #so-cap-cuu
<section #ky-niem>           Nhóm 04 → Memories (no id on this page)
<section #tien-ich>          Nhóm 05 → Night #ban-dem · YourWay #theo-cach-cua-ban · Watch #apple-watch
Faq                                   #hoi-dap
Kết                                   #tai-app
Footer
```

Quick-nav chips → the five group ids. Nav: "Chăm sóc" → `#ghi-va-nhac`, "Kỷ niệm" → `#ky-niem`, "Hỏi đáp" → `#hoi-dap`, "Bắt đầu" → `#tai-app`. English page uses the same ids (ids are not translated today).

## 22. Route

- **This page replaces the current Chặng 1 page** (`page: 'stage1'`): hero chip "Chặng 1 · 0–12 tháng", nav "Năm đầu đời", and note #12 ("Trang chặng tương lai: … CTA chính dẫn về năm đầu đời") all point at one "first year" page. Implement as a new page component (e.g. `pages/FirstYearPage.tsx`) and route `stage1` to it; `StagePage` keeps Chặng 2–4 (their V8 template `738:7309` is a separate spec).
- **Path:** keep `/hanh-trinh/nhung-ngay-dau-doi/` and `/en/journey/first-days/` (already prerendered, linked from the home, possibly shared). A rename to `/nam-dau-doi/` · `/en/first-year/` would need hosting redirects — owner call; engineering recommends keeping the path for V8 and updating only titles/meta.
- Meta (new, engineering draft): title "Năm đầu đời của con — Child Life" / "Your baby's first year — Child Life"; description = hero lead.
- **Nav on this page** (left → right): logo → home; "Chăm sóc" → `#ghi-va-nhac`; "Kỷ niệm" → `#ky-niem`; "Lumi" → `/lumi/`; "Năm đầu đời" → this page (`aria-current="page"`); "Hỏi đáp" → `#hoi-dap`; language switch → `/en/journey/first-days/`; button "Bắt đầu" → `#tai-app`. No "Hành trình" / "Các chặng" links (the StageSwitcher is gone too): the only way to the other stages from this page is the home.

## 23. English drafts (engineering, for owner review)

| Key (proposed) | vi (Figma) | en draft |
|---|---|---|
| `nav.links.care` | "Chăm sóc" | "Care" |
| `nav.download` | "Bắt đầu" | "Get started" |
| `firstYearPage.hero.badge` | "Đang có trong app" | "In the app now" |
| `firstYearPage.hero.stage` | "Chặng 1 · 0–12 tháng" | "Stage 1 · 0–12 months" |
| `firstYearPage.hero.title` | "Năm đầu đời của con, gọn trong một app." | "Your baby's first year, all in one app." |
| `firstYearPage.hero.lead` | "Ghi chép và nhắc nhở cho cả nhà, gợi ý theo tuổi, sơ cứu, ăn dặm và nơi giữ kỷ niệm của con — dùng được ngay hôm nay." | "Logs and reminders for the whole family, age-based tips, first aid, starting solids and a home for your baby's memories — ready to use today." |
| `stores.caption` (hero + Kết) | "Tải miễn phí trên iPhone và Android." | "Free to download on iPhone and Android." |
| `firstYearPage.jump.label` | "Đi nhanh tới:" | "Jump to:" |
| `firstYearPage.jump.navLabel` (aria, new) | — | vi "Đi nhanh tới các nhóm" / en "Jump to a section" |
| `firstYearPage.groups[0]` | "Ghi & nhắc" / "Ghi trong vài chạm, nhắc đúng lúc." | "Log & remind" / "Log in a few taps, reminded right on time." |
| `firstYearPage.groups[1]` | "Cả nhà cùng chăm" / "Ba mẹ, ông bà và người chăm cùng một nhật ký." | "Caring together" / "Parents, grandparents and caregivers share one log." |
| `firstYearPage.groups[2]` | "Hiểu con theo tuổi" / "Mốc, tiêm chủng, bài đọc và sơ cứu theo tuổi của bé." | "Know your baby by age" / "Milestones, vaccinations, reading and first aid for your baby's age." |
| `firstYearPage.groups[3]` | "Kỷ niệm" / "Giữ lại những lần đầu tiên của con." | "Memories" / "Keep your baby's firsts." |
| `firstYearPage.groups[4]` | "Tiện ích" / "Chế độ đêm, tuỳ chỉnh màn hình và Apple Watch." | "Tools" / "Night mode, a home screen your way and Apple Watch." |
| `quick.title` | "Ghi nhanh từ widget và màn hình khoá." | "Log fast from widgets and the lock screen." |
| `care.title` | "Nhật ký một ngày của con, nhìn là hiểu." | "Your baby's day in one log, clear at a glance." |
| `reminders.title` | "Nhắc cữ bú, giấc ngủ cho đúng người." | "Feed and sleep reminders for the right people." |
| `cocare.title` | "Cả nhà ghi chung một nhật ký." | "The whole family keeps one log." |
| `roles.title` | "Bạn chọn ai được xem ảnh và thông tin của con." | "You choose who sees your baby's photos and details." |
| `understand.title` | "Gợi ý theo tuổi: tuần này của bé." | "Age-based tips: your baby this week." |
| `understand.columns[0].title` | "Gợi ý theo tuổi" | "Age-based tips" (was "Age cards") |
| `vaccines.eyebrow` | "Sức khoẻ của con" | "Your baby's health" |
| `vaccines.title` | "Lịch tiêm và biểu đồ tăng trưởng." | "Vaccinations and growth charts." |
| `vaccines.lead` | "Biết con đã tiêm gì, sắp tiêm gì, lớn lên ra sao — không cần lục sổ." | "Know which shots your baby has had, what's next and how they're growing — no digging through the health book." |
| `vaccines.bullets[0]` | "Lịch tiêm theo tháng tuổi" / "Đánh dấu mũi đã tiêm, nhắc trước ngày tiêm cho cả nhà." | "Vaccinations by age" / "Tick off each dose and get a reminder before the next one." (see §24 — "cho cả nhà" dropped in en pending Q-039) |
| `vaccines.bullets[1]` | "Cân nặng, chiều dài theo chuẩn WHO" / "Biểu đồ dễ đọc, không chấm điểm hay so sánh con." | "Weight and length against WHO standards" / "Easy-to-read charts that never score or compare your baby." |
| `vaccines.bullets[2]` | "Dinh dưỡng theo giai đoạn" / "Lượng sữa tham khảo và nhóm chất cần chú ý theo tuổi." | "Nutrition by stage" / "Reference milk amounts and the nutrients to watch at each age." |
| `vaccines.note` | "Nội dung tham khảo, được chuyên môn rà soát. Lịch tiêm cụ thể theo hướng dẫn của cơ sở y tế." | "For reference, reviewed by experts. Follow your clinic for your baby's exact vaccination schedule." |
| `vaccines.mock.title` | "Lịch tiêm chủng · Teddy" | "Vaccinations · Teddy" |
| `vaccines.mock.columns` | "Sơ sinh", "2 th", "3 th", "4 th", "6 th", "9 th" | "Birth", "2 mo", "3 mo", "4 mo", "6 mo", "9 mo" |
| `vaccines.mock.rows` | "Viêm gan B", "Lao", "6 trong 1", "Phế cầu", "Rota", "Sởi" | "Hepatitis B", "BCG", "6-in-1", "Pneumococcal", "Rotavirus", "Measles" |
| `vaccines.mock.next` | "Mũi tiếp theo: 6 trong 1 · lần 3 · 17/11" | "Next dose: 6-in-1 · dose 3 · 17 Nov" |
| `vaccines.mock.growth` | "Cân nặng" / "7,8 kg" / "Trong khoảng chuẩn WHO" | "Weight" / "7.8 kg" / "Within the WHO range" |
| `library.title` | "Thư viện chăm bé và ăn dặm." | "A library for baby care and starting solids." |
| `firstAid.title` | "Sơ cứu trẻ em: hướng dẫn từng bước." | "First aid for children, step by step." |
| `memories.title` | "Ảnh, thiệp, video và nhật ký của con." | "Your baby's photos, cards, videos and journal." |
| `night.title` | "Chế độ đêm cho những cữ bú khuya." | "Night mode for late-night feeds." |
| `firstYearPage.closing.title` | "Bắt đầu từ năm đầu đời của con." | "Start with your baby's first year." |
| `firstYearPage.closing.sub` | "Ghi chép, nhắc nhở và kỷ niệm — cả nhà cùng một nơi." | "Logs, reminders and memories — the whole family in one place." |
| `faq.items[4].a`, `home.faq…`, `everything.tiles[*].body/bodyShort` | "thẻ theo tuổi" → "gợi ý theo tuổi" (§10) | "age cards" → "age-based tips" |
| `meta` (page) | "Năm đầu đời của con — Child Life" | "Your baby's first year — Child Life" |

vi and en must keep the same ids (D-012).

## 24. Claims to check (`docs/product/business-map.md`)

Every claim below is already flagged under **Q-039** unless noted; the V8 note `739:7403` asks the same questions (verbatim excerpts: "Apple Watch, widget/màn hình khoá, chế độ đêm, sổ chi tiêu, sơ cứu, lịch tiêm: đã live chưa."; "Nội dung gợi ý theo tuổi, ăn dặm, sơ cứu đã được chuyên môn duyệt chưa; quyền dùng tên “Wonder Weeks”."; "Dung lượng lưu trữ cho gia đình (bản cũ từng ghi “10 GB” — đã bỏ khỏi UI tới khi xác nhận).").

1. **"Đang có trong app" / "dùng được ngay hôm nay" / store badges "Sau ra mắt"** — the app is not in the stores (`site.ts storeLinks` are `null`; `StoreBadges` shows the "sắp có" toast the V8 component forbids). Owner: publish V8 only after listings exist, or show the "Trước ra mắt" variant (needs a real email sign-up flow — none exists; R-170 "No forms") — note `739:7403` bullets 1–2.
2. **Widgets / lock screen / Dynamic Island** (Thao tác nhanh, group 01): iOS extensions wait on the Apple account / App Groups (**D-045**); Android widgets are planned, not shipped (**D-071**, D-004); Live Activity only for sleep/breast, not pump (**D-026**). "Ghi nhanh từ widget và màn hình khoá." is a stronger, feature-named claim than the old title.
3. **Reminders "cho đúng người" / "Chọn ai nhận nhắc" / "nhắc tự tắt với mọi người"** — **R-091** (local notifications on the creating device only); assignee exists only for one-off reminders (reminders-allday-assignee-plan, D-075 #5). The new title makes "đúng người" the headline — Q-039.
4. **Quyền xem**: "Ảnh mới mặc định chỉ ba mẹ thấy" contradicts **D-001** (keep PROPOSED); caregiver photo sending contradicts **Q-008**; "đường link gửi đi sẽ tự hết hạn" / lock screen — **R-171**.
5. **Gợi ý theo tuổi / Wonder Week / Mốc** — content review not recorded ("Nội dung do đội chuyên môn Child Life soạn và rà soát", "được chuyên môn rà soát", "Rà soát cùng chuyên gia y tế"): **Q-039**, and **D-082** says unreviewed content must read "Biên soạn theo hướng dẫn WHO, AAP, NHS · Tham khảo, không thay thế bác sĩ" in the app — the landing's "đã rà soát" wording is stronger than the app's. **Wonder Weeks naming**: **D-072** — "Lịch tham khảo", labelled as a reference, "never implying partnership; the name/model rights check stays a release gate before prod". The landing uses "Wonder Week 1" / "lịch Wonder Week" as a product feature name → owner/legal.
6. **Lịch tiêm (new section)** — Sổ tiêm chủng **P-133** (30-dose VN schedule, reference data for medical review; "no age or interval warnings, R-012"), **D-084** (schedules for six countries abroad). "nhắc trước ngày tiêm **cho cả nhà**" — Q-039 says vaccine reminders reach Cùng nuôi + Người chăm sóc only (and R-091 device-local). "Lịch tiêm cụ thể theo hướng dẫn của cơ sở y tế" is fine.
7. **"Trong khoảng chuẩn WHO" / "Cân nặng, chiều dài theo chuẩn WHO"** — **D-049** (WHO standards; the app's status label is "Bình thường" / "Dưới mức tham chiếu" / "Trên mức tham chiếu"; no other medical inference, R-012). "không chấm điểm hay so sánh con" vs a WHO status chip: wording, not a blocker.
8. **"Dinh dưỡng theo giai đoạn"** — **D-083** brought it back (reverses D-069's drop); its content "ships as drafts and needs the qualified review before prod". Q-039 v4 note ("app: Sớm ra mắt") is now outdated.
9. **Thư viện & ăn dặm** — library and solids content review: **D-085**, **D-086**, **D-087** (country-aware content, "gọi 115" fixed per country), Q-039 ("đội chuyên môn soạn, rà soát và cập nhật").
10. **Sơ cấp cứu** — **D-058**: hidden on **prod** until a person with medical credentials approves; "Rà soát cùng chuyên gia y tế" is untrue until then. Hero lead also lists "sơ cứu".
11. **Kỷ niệm "Ảnh, thiệp, video và nhật ký"** — "thiệp" = milestone cards / story cards (**D-068** Kỷ niệm 2.0, `StoryCardExport`), "video" = memory video (D-068) — confirm both are V1 (note `739:7403` bullet 3). "Ông ngoại đã xem 12 ảnh mới" — **Q-009** (keep PROPOSED). "Cô Lan thương câu chuyện" shows a caregiver reacting to a story — caregivers never see Memories (**Q-008**, app matrix line 262); suggest a relative instead (§25 #6).
12. **Night care** — "chữ to" (palette only, Q-039 v4); "Tự bật vào giờ bạn chọn" = flag `night_auto` (FeatureFlag) — confirm on.
13. **Theo cách của bạn** — Today customisation is **per device** (**P-127**); "Danh mục chi tiêu riêng" exists (spending-plan 8m–8o, P-140), but spending rights are Cùng nuôi only (**D-055**).
14. **Apple Watch** — watch app not released (**Q-047**, **P-142**, Q-039 v5: pump timer, Double Tap, notification log action, complication not built; "chạm hai ngón" should be "chạm hai lần"; "chỉ với một chạm" vs two taps for bottle/diaper); no Wear OS (**Q-048**, D-071). Unchanged copy, same open issues — now on a page that says "Đang có trong app".
15. **Storage** — this page makes no GB claim (good; D-010 covers +10/+20 GB requests only). FAQ 2 answer "đủ chỗ cho hàng nghìn ảnh của con" stays as today.
16. **"Miễn phí"** — "Tải miễn phí" is fine; nothing on this page mentions Lumi plans (Q-071 not affected).

## 25. Ambiguities / design bugs

1. **Nav label mismatch**: this page (and Lumi, Chặng 2) say "Lumi"; the V8 home (`735:5392`) says "Trợ Lý Lumi". Pick one for all pages (recommend "Lumi", which matches the current site).
2. **Quick-nav selected chip**: chip 1 is drawn in `mint-deep` with no explanation — interpreted as the scroll-spy active state (§3). Whether the bar is sticky is not designed.
3. **"Bố mẹ" vs the note "cha mẹ → ba mẹ"**: Nhắc nhở bullet 2 sub still reads "Bố mẹ và người chăm — không làm phiền ông bà". The note only names "cha mẹ"; the group 02 subtitle uses "Ba mẹ". Recommend "Ba mẹ và người chăm — không làm phiền ông bà" (and `subShort` "Ba mẹ và người chăm") as PROPOSED; en unchanged ("Parents and caregivers…").
4. **Stale layer names**: Quick title/lead layers are named "Bận tay? Ghi một chạm ngay trê…" / "Widget, màn hình khoá và Dynam…" but contain "Ghi nhanh từ widget và màn hình khoá." and the unchanged lead. The text content is authoritative; possibly an abandoned draft lead mentioning Dynamic Island.
5. **Mock data inconsistency**: the vaccine card has Teddy's 2- and 3-month doses done, "7,8 kg", next dose "lần 3 · 17/11", while every other mock on the page has Teddy at 3 weeks ("Teddy · 3 tuần", "TEDDY · 3 TUẦN TUỔI"). Harmless for a mock; the owner may want 3-week-consistent data (only "Sơ sinh" done, next "6 trong 1 · lần 1"). Keep Figma unless asked.
6. **"Cô Lan thương câu chuyện"** (Tuổi thơ tile 3) — a caregiver reacting to a story contradicts the app's caregiver rules (Q-008). Already on the live site; suggest "Bà ngoại thương câu chuyện" as PROPOSED.
7. **Vertical rhythm**: each group header has 64 top / 8 bottom, then the first section adds 96 (Quick, Hiểu con 112) → ~104–120 px between a group title and its first eyebrow, while sections inside a group are separated by 64 + 96 = 160. Implement as drawn; tighten only if the owner finds the headers float.
8. **Background bands**: Tuổi thơ and Kết are `surface` (white) while FAQ and Footer sit on `cloud`; Kết's white band ends at the footer, which drops back to `cloud`. Implement as drawn (footer has its own top rule).
9. **Apple Watch width**: the watch card is inset 48 px more than every other card (1152 vs 1248) because of an extra wrapper frame — probably carried over from the home frame. Implement as drawn or align to 1248 (recommend 1248 for a clean edge; low risk).
10. **Hero art reuse**: the hero illustration is the Hành trình stage-1 art at 2× (§2); the SVG is 295 × 170, so scale it, do not re-export.
11. **No mobile frame** for this page: mobile layouts in §2–§4, §11 and §19 are engineering proposals; the other sections keep their current mobile layouts.
12. **Straight quotes** in Figma ("con ăn chưa?", "con ăn lúc mấy giờ?", "Gia đình") — keep the site's curly quotes.
13. **Kết vs home Kết**: same component, different copy per page — the copy here is page-specific ("Bắt đầu từ năm đầu đời của con."); check the V8 home spec before sharing keys.
14. **FAQ answers 3–6** are still not in Figma (G-065, current PROPOSED answers stay).
