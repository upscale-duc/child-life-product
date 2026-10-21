# 37 — Landing V9 home page (desktop + mobile): changes from V8

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only; only `get_metadata` / `get_design_context` / `get_screenshot` were used, nothing was modified). Extracted 2026-10-21 from section `785:7030` "Child Life Website — V9".

- Desktop frame **`785:7031` "V9 · Trang chủ · Desktop"**, 1440 × 10409.2 (V8 7978.2).
- Mobile frame **`785:7890` "V9 · Trang chủ · Mobile"**, 390 × 13674.9 (V8 9437.7), incl. the sticky bar drawn at y 9322.7.
- The same section also holds `785:8698` "V9 · Năm đầu đời · Desktop", `785:9913` "V9 · Lumi · Desktop", `785:10743` "V9 · Chặng 2 (đang phát triển) · Desktop" and the note frame `793:68586` "Ghi chú V9 · sửa theo comment". **Not covered here.** The note frame has two bullets the brief did not quote — "• Năm đầu đời · Kỷ niệm: luồng…" and "• Lumi page: rút gọn còn ~4.10…" — and both belong to those other pages.

**Baseline.** V8 is built: spec `34-landing-v8-home.md`, code `apps/landing/src/pages/Home.tsx` with `sections/HomeIntro.tsx` (`HomeHero`, `HomeValues`), `HomeMemories.tsx`, `HomeFamily.tsx`, `HomeAssistant.tsx`, `HomeMore.tsx` (`HomeTools`, `HomeJourney`, `HomeTrust`), `Closing.tsx`, `components/StoreBadges.tsx`, `components/Chrome.tsx`, with styles in `styles/v8.css` and copy under `homePage`, `closing`, `stores` and `nav` in `content/vi.ts`. **This document lists only what V9 changes.** Anything not mentioned is unchanged from spec 34 and the built code, including any deliberate deviation from Figma already recorded there: nav label "Lumi", album "Bà nội thương 3 ảnh mới" (PROPOSED), chip "289.000 ₫", "Xem video mẫu" not built, FAQ answers 2–5 PROPOSED.

**Conventions.** These are the same as specs 28, 32, 33 and 34:

- **Colour tokens.** Colours are named by their token in `packages/design-tokens/dist/tokens.css` when one matches, and marked **(raw)** otherwise.
- **Copy.** Every visible string is copied **verbatim** from `get_design_context`.
- **Font.** Be Vietnam Pro throughout, in the weights Medium 500, SemiBold 600 and Bold 700. "lh normal" means `line-height: normal`.
- **Shadow.** "shadow-card" is drawn as `drop-shadow(0 8px 12px rgba(23,61,68,.08)) drop-shadow(0 1px 1px rgba(23,61,68,.06))`. Use the landing's existing shadow-card equivalent.
- **Links.** `<a>` means the layer has a link reaction. The destination is not exposed, so the targets below are proposals.
- **Layer names are stale.** Many text layers keep their V8 names (for example "Cùng chăm con, giữ từng khoảnh" now holds the V9 H1). Never trust layer names in `meta.xml`; every string below comes from `get_design_context`.

**Not drawn.** No hover, focus, pressed or disabled states, no tablet frame, no Night care frame and no motion. The landing stays light-only.

Working files are in `/private/tmp/claude-501/-Users-duckie2910-Documents-child-life-product/8f1c2e02-1c42-4b23-b126-2b499d293516/scratchpad/v9/` and are not committed:

- `meta.xml`, the outline.
- `notes.md`, the raw extraction notes.
- `s3-memories.txt`, `s4-family.txt`, `s5-lumi.txt` and `m3-memories.txt`, the compacted design context.
- `s4-family.png`, a 1200 px render of the desktop Cả nhà cùng chăm section.
- `dl/apple.svg` and `dl/play.svg`, the Kết badge logos, fetched for inspection only. They are not in the repo.

---

## 0. Section order and ids

| # | Section | Desktop node · y · h | Mobile node · y · h | id | Status |
|---|---|---|---|---|---|
| – | Nav | `785:7032` · 0 · 81 | `785:7891` · 0 · 62 | — | link order changed |
| 1 | Hero (lai) | `785:7042` · 81 · 676 | `785:7900` · 62 · 873.9 | `#gioi-thieu` | copy changed, support line + vision removed |
| 2 | Ba giá trị | `785:7108` · 757 · 825 | `785:7971` · 935.9 · 1360 | `#giup-gi` | pictures redrawn (3 rows each), new button; mobile layout changed |
| **2b** | **Bắt đầu lúc nào cũng kịp** | **`786:8714` · 1582 · 788** | **`791:69042` · 2295.9 · 822** | **`#bat-dau`** (proposal) | **new** |
| 3 | Kỷ niệm | `785:7166` · 2370 · 1328 | `785:7996` · 3117.9 · 2052 | `#ky-niem` | 6-step strip added, "Còn có" removed, lead removed (desktop) / changed (mobile) |
| 4 | Cả nhà cùng chăm + Trên cổ tay | `785:7290` · 3698 · 1381 | `785:8118` · 5169.9 · 2043 | `#cham-soc` (+ `#apple-watch` → propose `#ghi-nhanh`) | scenario hidden → family illustration; quick-log block added |
| 5 | Lumi & gợi ý cho bé | `785:7430` · 5079 · 1421 | `785:8258` · 7212.9 · 2128 | `#lumi` | "Thử hỏi Lumi" added |
| **5b** | **Nhắc thông minh** | **`789:8811` · 6500 · 752** | **`793:8899` · 9340.9 · 875** | **`#nhac-nho`** (proposal) | **new** |
| 6 | Tiện ích khác | `785:7600` · 7252 · 799 | `785:8428` · 10215.9 · 967 | `#tien-ich` | **unchanged** |
| 7 | Hành trình khi con lớn | `785:7683` · 8051 · 736 | `785:8497` · 11182.9 · 811 | `#hanh-trinh` | "Tìm hiểu thêm" per card |
| 8 | Miễn phí, niềm tin & hỏi đáp | `785:7828` · 8787 · 978 | `785:8639` · 11993.9 · 1044 | `#mien-phi` / `#hoi-dap` | **unchanged** |
| 9 | Kết | `785:7872` · 9765 · 460 | `785:8683` · 13037.9 · 407 | `#tai-app` | centred, photo removed, official-style badges |
| – | Footer | `785:7880` · 10225 · 184.2 | `785:8689` · 13444.9 · 230 | — | **unchanged** |
| – | Sticky download bar (mobile) | — | `785:8693` · 9322.7 · 74 | — | **unchanged** |

The new `Home.tsx` order is: `HomeHero` · `HomeValues` · **`HomeRestart` (2b)** · `HomeMemories` · `HomeFamily` · `HomeAssistant` · **`HomeAlerts` (5b)** · `HomeTools` · `HomeJourney` · `HomeTrust` · `Closing`.

**Section backgrounds after V9.** Read in page order, the backgrounds go:

| Section | Background |
|---|---|
| Hero | gradient |
| Ba giá trị | `var(--surface)` |
| 2b | **`var(--cloud)`** |
| Kỷ niệm | `#FFF7F0` |
| Cả nhà cùng chăm | `var(--surface)` |
| Lumi | gradient |
| 5b | **`var(--surface)`** |
| Tiện ích | gradient |
| Hành trình | none |
| Miễn phí | `var(--surface)` |
| Kết | `var(--surface)` |

2b needs a `home-section--cloud` modifier. 5b uses the existing `home-section--white`.

Shared section pattern (spec 34 §0.2) is unchanged. Desktop: column, gap 44, padding 96, header gap 12, eyebrow pill, H2 42/1.16, lead 18/1.55. Mobile: padding 56 × 20, gap 28, H2 28, lead 16.

### 0.1 Icons used by the new content

All of these are in `apps/landing/src/components/primitives.tsx` `icons`: `heart`, `camera`, `star`, `today`, `memories`, `arrow-right`, `check`, `cake`, `search`, `family`, `lock`, `journal`, `spark`, `clock`, `feed`, `sleep`, `diaper`, `drop`, `eye`, `link`, `chevron-down`.

**No icon is missing.** Non-icon artwork:

- The Siri "orb" is a CSS gradient.
- The Apple and Google Play logos are new assets (§9).
- The step numbers are text.

### 0.2 Raw colours introduced by V9 (no token matches)

| Value | Used for |
|---|---|
| `#FFDBCC` | avatar M |
| `#D1E5FF` | avatar B |
| `#EDE3FF` | avatar Bà |
| `#D9F2E0` | avatar Ô |
| `#FFF2C7` | avatar Cô |
| `#FAD9CC` bg + `#994526` text | memory step numbers |
| `#F0FAF7` | family illustration panel (already used by the hero gradient in `v8.css`) |
| `rgba(41,140,128,.35)` | 2b timeline fill |
| `#298C80` | notification app tile |
| `linear-gradient(143.13deg, #173D45 0%, #386B73 71.43%)` | 5b lock screen (mobile angle 136.23deg) |
| `#D9EBEB` | lock-screen date |
| `rgba(255,255,255,.92)` | notification background |
| `rgba(255,255,255,.55)` | "Gộp" |
| `rgba(255,255,255,.08)` | quick-log tiles |
| `rgba(255,255,255,.18)` | control buttons |
| `#9EBFBF` | quick-log labels |
| `#BFD9D9` | Siri replies |
| `linear-gradient(90deg, #6680FF, #E559B2 50%, #FFB24D)` | Siri orb |
| `#A6A6A6` | store badge border |
| `#000` | store badge fill |

The rest of the dark Trên cổ tay palette is unchanged: `#163D44`, `#CCE0E0`.

The avatar colours suggest a small `--avatar-*` set in `v8.css`. The existing `Initials` in `kit.tsx` uses `tint--coral/sleep/diaper/mint`, which is close but not equal.

### 0.3 Photo slots

These follow spec 34 §0.4: Figma's peach and sun placeholders map to `photos.peach` (Teddy at 8 months) and `photos.sun` (Teddy on the couch).

| Slot | Tones drawn | Fill with |
|---|---|---|
| Thumbnails in rows (26 px) | peach / sun | `<Photo tone>` |
| Kỷ niệm step photos (36 px) | peach / sun / peach | `<Photo tone>` |
| Family photo card | sun, a smiling sitting baby | `photos.sun` (`teddy-one-couch.jpg`), or `teddy-one-plush.jpg` (closer to the drawn subject) |

All of these use existing assets. Nothing new is needed.

---

## 1. Nav

### 1.1 Desktop `785:7032`

Only the order changes. Styles are identical.

- **V9:** "Năm đầu đời" (`<a>`, `785:7038`) · "Chăm sóc" · "Kỷ niệm" · "Trợ Lý Lumi" (`<a>`) · "Hỏi đáp" · button "Bắt đầu".
- **V8:** Chăm sóc · Kỷ niệm · Trợ Lý Lumi · Năm đầu đời · Hỏi đáp.

In `Chrome.tsx` `Nav`, move the `l.firstYear` entry to the top of `links`. This also changes the mobile menu panel order.

Labels are unchanged. Keep the built "Lumi" (`nav.links.lumi`) unless the owner wants Figma's "Trợ Lý Lumi" (spec 34 A-13).

### 1.2 Mobile `785:7891`

Unchanged.

---

## 2. Hero (lai)

### 2.1 Desktop `785:7042` (1440 × 676; V8 703)

**Copy column** (gap 20, width 600):

| Element | V8 (`homePage.hero.*`) | V9 |
|---|---|---|
| Eyebrow `785:7045` | `eyebrow` "Child Life · Bắt đầu từ năm đầu đời" (SemiBold) | "Child Life · " **SemiBold** + "Đồng hành cùng con khôn lớn" **Bold**. Mixed weight in one pill, still 13 px `var(--mint-text)` on `var(--mint-soft)`. |
| H1 `785:7046` (50 Bold, lh 1.12) | `title` "Cùng chăm con, giữ từng khoảnh khắc con lớn lên." | "Cùng con lớn lên, qua từng khoảnh khắc." |
| Lead `785:7047` (19 Medium, lh 1.55) | `lead` "Ghi bú, ngủ, tã để cả nhà cùng theo dõi. Lưu ảnh, tạo video và giữ lại những lần đầu tiên của con." | "Từ chăm sóc hằng ngày, theo dõi phát triển đến lưu giữ kỷ niệm — Child Life kết nối cả gia đình trong hành trình khôn lớn của con." |
| Support line (star) | `support` "Bắt đầu với năm đầu đời. Tiếp tục đồng hành khi con lớn." | **removed** |
| CTA `785:7048` | V8/CTA tải app *Sau ra mắt · Ngang* with caption (411.4 × 93) | same instance but **the caption is hidden**: 411.4 × 67, badges row only. Badges unchanged ("Tải trên" / "App Store", "Tải trên" / "Google Play", white placeholder style). |
| Link `785:7049` (15 SemiBold `var(--mint-text)` + `chevron-down` 16, padding 6 × 0) | `seeApp` "Xem app hoạt động" → `#giup-gi` | "Bắt đầu cùng con trong năm đầu đời". Not an `<a>` in Figma. Target: see A-4. |

**Visual** `785:7052`:

- The vision caption "Tầm nhìn" (`vision` "Hệ sinh thái đồng hành cùng con — từ ngày đầu đời đến khi trưởng thành.") is **removed**. The visual is the 620 × 580 illustration only.
- Landscape, nodes, float 1 ("Bú bình · 120 ml" / "Ba vừa ghi · 2 phút trước") and the video card are unchanged.

Stage chips have new statuses. Chip 1 is unchanged: "0–12 tháng · Đang có trong app", mint-deep. Chip 4 moves because its text is longer.

| Chip | V8 text (`h.soon` "Sắp tới") | V9 text | Position (620 box) |
|---|---|---|---|
| 2 | "1–3 tuổi · Sắp tới" | "1–3 tuổi · Chặng tiếp theo" | (246, 424), unchanged |
| 3 | "3–6 tuổi · Sắp tới" | "3–6 tuổi · Trong tương lai" | (356, 346), unchanged |
| 4 | "6–12 tuổi · Sắp tới" | "6–12 tuổi · Trong tương lai" | **(412, 244)**; V8 (450, 246) |

In `HomeIntro.tsx` `nodes[3]`, set `chipX: 412, chipY: 244`.

Float 2 (0, 350) has new copy. The photo is unchanged (40 × 40 r10, tone **sun**).

| Line | V8 (`h.smile`) | V9 |
|---|---|---|
| Title (14 Bold `var(--ink)`) | "Lần đầu con cười" | "Học tập" |
| Sub (12 Medium **`var(--mint-text)`**) | "Đã lưu vào Kỷ niệm" | "Hôm nay con học thế nào?" |

**Height.** Section padding (40 / 56) and gap are unchanged. The section is shorter only because the support line and caption are gone.

### 2.2 Mobile `785:7900` (390 × 873.9; V8 902.9)

The mobile hero is **only partly ported**.

- **Copy** (gap 16):
  - The eyebrow is still the **V8** "Child Life · Bắt đầu từ năm đầu đời" (single weight).
  - The H1 and lead carry the V9 text but are drawn at **50 px / 19 px**, the desktop sizes. V8 mobile was 34 / 16, and the H1 is now 3 lines (168 high) at 350 wide. This is a design bug: keep 34 / 16 (A-2).
  - CTA *Sau ra mắt · Dọc* with **no caption** (339.25 × 54.86).
  - Link "Bắt đầu cùng con trong năm đầu đời" + `chevron-down`.
- **Visual** `785:7913`: 350 × 328, illustration only (no vision caption), same ×0.5645 scale. The illustration is **not updated**: chips still read "1–3 tuổi · Sắp tới" / "3–6 tuổi · Sắp tới" / "6–12 tuổi · Sắp tới", and float 2 is still "Lần đầu con cười" / "Đã lưu vào Kỷ niệm".

**Recommendation.** Render the desktop V9 strings on mobile too, since the hero is one component scaled by `Fit` (A-1). Note that `Fit` scales positions: chip 4 at (412, 244) × 0.5645.

---

## 3. Ba giá trị

### 3.1 Desktop `785:7108` (1440 × 825; V8 701)

**Header:**

| Element | V8 | V9 |
|---|---|---|
| Eyebrow | `values.eyebrow` "Child Life giúp gì" | "Child Life giúp gì trong năm đầu đời của con" |
| H2 | "Child Life giúp gia đình bạn ba việc." | **unchanged** |
| Lead | `values.lead` "Mỗi phần đều dùng được ngay trong năm đầu đời của con." | "Chăm sóc \| Phát triển \| Kỷ niệm" (literal vertical bars, 18 Medium muted) |

Render the lead as three words separated by `aria-hidden` "|" (A-11).

**Cards.** The shell is unchanged: `var(--cloud)`, r24, padding 14 14 24, gap 16, 400 wide, equal height. Card text (22 Bold / 15 Medium lh 1.55, padding 0 10):

| Card | Title | Body V8 → V9 |
|---|---|---|
| 1 | "Chăm con mỗi ngày" (unchanged) | "Ghi bú, ngủ, tã và đặt nhắc nhở. Cả nhà cùng biết con vừa được chăm thế nào." → **"Ghi bú, ngủ, tã; nhắc lịch chăm bé, dinh dưỡng và ăn dặm. Cả nhà cùng biết con vừa được chăm thế nào."** |
| 2 | "Hiểu con từng giai đoạn" | "Xem nhật ký, theo dõi mốc phát triển và tìm nội dung theo tuổi của bé." → **"Theo dõi mốc phát triển, nhận gợi ý hợp tuổi và lưu nhật ký lớn khôn của con."** |
| 3 | "Giữ những điều đáng nhớ" | "Lưu ảnh riêng tư, tạo thiệp và video từ những khoảnh khắc của con." → **"Tự tìm ảnh của bé, tạo thiệp và video, cất vào album gia đình riêng tư."** |

**Pictures "Hình" are all redrawn.** Each picture is the same box as V8: 372 wide, r20, padding 20, the card tint as background (card 1 `var(--care-bottle-soft)`, card 2 `var(--care-sleep-soft)`, card 3 `var(--peach-soft)`). Inside, **three rows** in a column (gap 8, width 332).

The row is a new primitive, "Dòng":

- Container: `var(--surface)`, **r14**, padding **9 × 10**, gap 10, align center.
- Icon box: padding 8, r12, icon 14.
- Text column (flex 1, gap 1): title **13 SemiBold** `var(--ink)` and sub **11 Medium** `var(--ink-muted)`.
- A trailing element: one of the types below.

Trailing element types:

- **chip**: padding 3 × 8, r999, 11 SemiBold.
- **icon trio**: three icon boxes, padding 8, r12, icon 12, gap 4.
- **thumbs**: 26 × 26 photos, r8, gap 4, `var(--surface-2)` behind.
- **avatars**: 22 circles with a 2 px `var(--surface)` border, overlapping by −6 px, letter 9 SemiBold `var(--ink)`.

The `.value-row` and `.value-rows` classes in `v8.css` can grow to take the sub line and trailing element.

| Card | Row (node) | Icon / box tint | Title | Sub | Trailing |
|---|---|---|---|---|---|
| 1 | `785:72124` | `feed` / `var(--care-bottle-soft)` | "Bú · ngủ · tã" | "Ghi nhanh 1 chạm" | icon trio: `feed` on `var(--care-bottle-soft)`, `sleep` on `var(--care-sleep-soft)`, `diaper` on `var(--care-diaper-soft)` |
| 1 | `785:72131` | `clock` / `var(--sunshine-soft)` | "Nhắc lịch chăm bé" | "Ăn dặm bữa trưa · 11:30" | chip `var(--sunshine-soft)` / `var(--ink)` "Dinh dưỡng" |
| 1 | `785:72139` | `family` / `var(--mint-soft)` | "Cả nhà cùng chăm" | "Bố vừa ghi cữ bú · 2 phút" | avatars "M" `#FFDBCC`, "B" `#D1E5FF`, "Bà" `#EDE3FF` |
| 2 | `785:72149` | `star` / `var(--sunshine-soft)` | "Mốc phát triển" | "Biết lẫy · 4 tháng" | chip `var(--mint-soft)` / `var(--mint-text)` "✓ Đã ghi" |
| 2 | `785:72156` | `spark` / `var(--care-sleep-soft)` | "Gợi ý theo độ tuổi" | "Chơi úp bụng 10 phút" | chip `var(--care-sleep-soft)` / `var(--care-sleep-ink)` "4 tháng" |
| 2 | `785:72163` | `journal` / `var(--mint-soft)` | "Nhật ký lớn khôn" | "Tuần 18 · 6 ghi chép" | thumbs ×2 (peach, sun) |
| 3 | `785:72171` | `search` / `var(--mint-soft)` | "Tự tìm ảnh của bé" | "8 ảnh mới đang chờ lưu" | thumbs ×3 (peach, sun, peach) |
| 3 | `785:72179` | `cake` / `var(--sunshine-soft)` | "Thiệp & video kỷ niệm" | "Tròn 6 tháng" | chip `var(--sunshine-soft)` / `var(--ink)` "Tạo ngay" |
| 3 | `785:72187` | `lock` / `var(--care-sleep-soft)` | "Album gia đình riêng tư" | "Chỉ người được mời" | avatars "M" `#FFDBCC`, "B" `#D1E5FF`, "Ô" `#D9F2E0` |

Removed from V8: `values.mock.rows` (Bú bình 120 ml / Ngủ 1 giờ 20 phút / Thay tã with times), `values.mock.week` ("Tuần này của bé · 4 tháng" card), `values.mock.milestone`, and the three-photo picture.

**New button row** `785:72195`: full width, `justify-content: center`. **`<a>`** "Nút · Xem tất cả tính năng cho năm đầu đời" `785:72196`:

- `var(--mint-deep)`, padding **16 × 28**, r999, gap 8.
- Label "Xem tất cả tính năng cho năm đầu đời", **17** SemiBold `var(--on-mint-deep)`, + `arrow-right` 16.

Target: the Năm đầu đời page (`pathOf('stage1')`).

This is the existing `.home-button` at a larger size: V8's button was 16 px, 14 × 22. Add `.home-button--lg` and centre it.

### 3.2 Mobile `785:7971` (390 × 1360; V8 606)

**The V8 mobile row list is replaced.** "Ba thẻ" `791:68877` stacks the three desktop cards (column gap 12, full width 350) with pictures.

- Card shell as desktop. The picture keeps the tint and r20 but has **padding 10** (desktop 20); the rows fill its width.
- Titles 22 and bodies 15 lh 1.55, the same as desktop. Strings are identical to desktop.
- Chips have fixed widths in Figma ("Dinh dưỡng" 78, "✓ Đã ghi" 64, "4 tháng" 59, "Tạo ngay" 67). Use hug instead.
- Header strings match desktop V9 (H2 28, lead 16 "Chăm sóc | Phát triển | Kỷ niệm").

**Button** `791:69038`:

- Full width (flex 1), padding **14 × 20**, 15 SemiBold.
- Label **"Xem tất cả tính năng năm đầu đời"**, without "cho". Desktop has "cho" (A-6).
- A frame, not an `<a>`, but it should link like desktop.

**Removed on mobile:** the V8 mobile-only icon boxes (`feed`, `star`, `heart`) and the row layout. `HomeValues` loses `.home-value__icon`.

---

## 4. NEW · 2b "Bắt đầu lúc nào cũng kịp"

### 4.1 Desktop `786:8714` (1440 × 788)

**Section:** `background: var(--cloud)`, column, gap 44, padding 96.

**Header** `786:8715` (gap 12):

- Eyebrow (mint): "Con 2 tháng hay 6 tháng cũng vậy"
- H2 (42 Bold, lh 1.16, width 820): "Bắt đầu lúc nào cũng kịp."
- **No lead on desktop.** Mobile has one (§4.2).

**Panel "Bảng"** `786:8720`: `var(--surface)`, r28, padding 32, shadow-card. Row, gap 24, `align-items: center`, full width 1248.

#### Left: "Hồ sơ của bé" `786:8721`

Width 560. `var(--mint-soft)`, r24, padding 24, column, gap 18. It is decorative: make it `aria-hidden` or render it as a static illustration.

1. **Head** `786:8722` (row, gap 10, center): icon box (`var(--surface)`, padding 8, r12, `heart` 16) + "Teddy bắt đầu dùng Child Life lúc…" 15 SemiBold `var(--ink)`. The text ends in a "…" ellipsis character.
2. **Age selector "Chọn tuổi"** `786:8727` (segmented control): `var(--surface)`, r999, padding 4, gap 4, full width. Four equal segments (flex 1), padding 10 × 0, r999, centred, 14 SemiBold. Inactive segments are `var(--ink-muted)` on transparent; the active one is `var(--mint-deep)` bg with `var(--on-mint-deep)` text.
   - "Mới sinh" · "2 tháng" · **"6 tháng"** (active) · "9 tháng"

   **Static in Figma.** Making it interactive (the timeline and rows change with the age) is a proposal (A-8). If interactive, use `role="radiogroup"` with radios and arrow-key navigation.
3. **Timeline "Dòng thời gian"** `786:8736` (column, gap 8):
   - Track `786:8737`: `var(--surface)`, h10, r999, full width (512).
   - Fill "Đã qua": `rgba(41,140,128,.35)` (raw), h10, r999, width 256 (**50 %**, 6 of 12 months).
   - Thumb "Hôm nay": 18 × 18 circle, `var(--mint-deep)` with a 3 px `var(--surface)` border, at x 247 (centred on the fill end), y −4.
   - Labels row "Nhãn": three flex-1 cells.
     - "Ngày sinh": 12 Medium muted, left.
     - "Hôm nay · 6 tháng": 12 **SemiBold** `var(--mint-text)`, centred.
     - "1 tuổi": 12 Medium muted, right.
4. **"Tự điền lại"** `786:8747` (column, gap 8):
   - Label "Child Life tự sắp xếp lại cho bạn": 12 SemiBold muted.
   - Three rows, the same "Dòng" primitive as §3.1, width 512:

| Row (node) | Icon / tint | Title | Sub | Trailing |
|---|---|---|---|---|
| `786:8771` | `camera` / `var(--sunshine-soft)` | "Tìm lại 214 ảnh từ ngày con chào đời" | "Xếp theo từng tháng · chờ bạn chọn" | thumbs ×3 (peach, sun, peach) |
| `786:8781` | `star` / `var(--care-sleep-soft)` | "Mốc đã qua: lẫy, cười thành tiếng" | "Đánh dấu nhanh nếu con đã làm được" | chip `var(--care-sleep-soft)` / `var(--care-sleep-ink)` "3 mốc" |
| `786:8790` | `today` / `var(--mint-soft)` | "Gợi ý & nhắc lịch đúng tuổi 6 tháng" | "Ăn dặm, giấc ngủ, lịch tiêm tiếp theo" | chip `var(--mint-soft)` / `var(--mint-text)` "Từ hôm nay" |

#### Right: "Ý chính" `786:8798`

Flex 1 (≈ 600), column, gap 24.

- Three items `786:8799` / `8806` / `8813`. Each is a row (gap 14, align start):
  - Icon box: padding 8, r12, icon **18**.
  - Text column (gap 4): title **19 Bold** `var(--ink)`; body **15 Medium lh 1.5** `var(--ink-muted)`.

| Icon / tint | Title | Body |
|---|---|---|
| `heart` / `var(--care-bottle-soft)` | "Đồng hành chăm sóc từ hôm nay" | "Nhập tuổi con, mọi nhắc nhở, gợi ý ăn dặm và lịch chăm bé tự khớp với giai đoạn hiện tại." |
| `star` / `var(--care-sleep-soft)` | "Hiểu con ở đúng giai đoạn" | "Xem con đang ở đâu trong hành trình phát triển và những mốc sắp tới." |
| `memories` / `var(--sunshine-soft)` | "Lưu trọn cả những ngày đã qua" | "Ảnh cũ trong máy được tìm lại và xếp theo tháng, để album của con không thiếu trang nào." |

- Button "Nút · Bắt đầu với tuổi của con" `786:8821`: outline (`var(--surface)`, 1 px `var(--control-border)`, r999, padding **12 × 20**, gap 8). Label "Bắt đầu với tuổi của con" 15 SemiBold `var(--ink)` + `arrow-right` 16. Hug width, left-aligned.
  - **A frame, not an `<a>`.** Proposed target `#tai-app`.
  - Reuse `.home-button--outline`: same look, but padding 14 × 22 there versus 12 × 20 here.

### 4.2 Mobile `791:69042` (390 × 822)

`var(--cloud)`, padding 56 × 20, gap 28.

- **Header:** eyebrow and H2 (28 / 1.16) are the same strings. Mobile also has a **lead that exists only on mobile** (16 Medium lh 1.55 muted): "Dù con đã vài tháng tuổi, Child Life vẫn đồng hành chăm sóc, giúp bạn hiểu con và lưu trọn những khoảnh khắc — cả những ngày đã qua."
- **No white "Bảng" wrapper.** "Hồ sơ của bé" `791:69048` sits directly in the section: full width 350, `var(--mint-soft)`, r24, **padding 14**, gap 18.
- Segment labels are **12** SemiBold (desktop 14).
- The track is 322 wide: fill 161 (50 %), thumb at x 152.
- Rows are full width, with the same strings and styles.
- **"Ý chính" (3 items) and the "Bắt đầu với tuổi của con" button are not on mobile.**

Recommendation (A-9): show the three points on mobile too, as stacked rows, or accept the lead as their summary.

---

## 5. Kỷ niệm

### 5.1 Desktop `785:7166` (1440 × 1328; V8 1223)

**Header:**

- Eyebrow "Kỷ niệm" and H2 "Những tấm ảnh hôm nay, thành kỷ niệm để mai này xem lại." are unchanged.
- **The lead is removed.** `memories.lead` "Chọn ảnh của con để tạo video đầy tháng, thiệp cột mốc hoặc lưu vào album riêng của gia đình." is no longer drawn on desktop. Mobile has new lead text (§5.2).

**NEW strip "Hành trình kỷ niệm"** `787:8740`. It sits between the header and the grid: 1248 × 235, row, gap **12**, six cards of **198** (6 × 198 + 5 × 12 = 1248 exactly).

Card (`787:8741` … `787:8867`):

- Shell: `var(--surface)`, r20, padding 14, column, gap 10, shadow-card, equal height (self-stretch).
- **Head:** row, gap 8, center.
  - Number badge: 22 circle, bg `#FAD9CC` (raw), text 12 Bold `#994526` (raw), centred.
  - Spacer.
  - `arrow-right` 14, the step connector. **Not on step 6.**
- **Picture "Hình":** 170 × 72, bg `#FFF7F0` (raw, the section colour), r14, padding 0 10, content centred.
- **Title:** 15 Bold `var(--ink)`.
- **Sub:** 12 Medium lh 1.4 `var(--ink-muted)`.
- **Tags:** row, gap 4. Each chip is `var(--cloud)`, padding 3 × 8, r999, 11 SemiBold `var(--ink-muted)`.

| # | Picture content | Title | Sub | Tags |
|---|---|---|---|---|
| 1 | three photos 36 × 36 r8, gap 4 (peach, sun, peach) | "Tự động tìm ảnh" | "Ảnh mới của bé" | "Tự động" |
| 2 | two photos 36 (peach, sun) + a 22 circle `var(--mint-deep)` with `check` 12 (white), gap 6 | "Chọn & lưu" | "Giữ ảnh đẹp, bỏ ảnh trùng" | "1 chạm" |
| 3 | two tiles 44 × 52 r10, gap 6: `var(--care-sleep-soft)` with `arrow-right` 18 (play glyph, see A-14) and `var(--sunshine-soft)` with `cake` 18 | "Tạo thiệp, video" | "Từ mẫu có sẵn" | "Thiệp" · "Video" |
| 4 | four avatars 28 (2 px `var(--surface)` border, −6 overlap, 12 SemiBold ink): "M" `#FFDBCC`, "B" `#D1E5FF`, "Bà" `#EDE3FF`, "Ô" `#D9F2E0` | "Album & chia sẻ" | "Riêng cho gia đình, hoặc gửi ra ngoài" | "Gia đình" · "Link" |
| 5 | quote, left-aligned, padding 0 12: "“Hôm nay con cười thành tiếng lần đầu…”" 12 Medium lh 1.4 **`var(--ink)`** | "Câu chuyện, nhật ký" | "Ghi lại lời kể cho con" | "Nhật ký" |
| 6 | column gap 4, centred: chips `var(--sunshine-soft)` / `var(--ink)` 11 SemiBold "★ Biết lẫy" and "★ Mọc răng đầu" | "Các mốc" | "Lần đầu của con" | "Cột mốc" |

**Semantics.** Use an `<ol>` with the visible numbers `aria-hidden`; the arrows are decorative.

**Grid changes.** The layout and the video, card and then-and-now cards are unchanged. One string changes:

- Album card body: `memories.album.body` "Ông bà ở xa vẫn theo dõi cháu." → **"Cả nhà cùng xem, bình luận. Chia sẻ ra ngoài bằng link khi bạn muốn."**
- The seen line is still Figma's "Bà nội đã xem 3 ảnh mới". Keep the built PROPOSED "Bà nội thương 3 ảnh mới" (Q-009).

**"Còn có" strip is removed.** That covers `memories.alsoLabel`, `also`, `soon` and the `.mem-also` CSS.

**Kept:** "Xem video mẫu" (still drawn, still unbuilt; spec 34) and "Xem các mẫu kỷ niệm".

### 5.2 Mobile `785:7996` (390 × 2052; V8 1496)

- **Header:** the eyebrow and H2 are unchanged. Mobile has a **new lead** (16 Medium lh 1.55), different from V8 and absent on desktop: "Child Life tự tìm ảnh của con, giúp bạn chọn và lưu, tạo thiệp, video, rồi cất vào album riêng để cả nhà cùng xem."
- **Strip** `791:69125`: a column (gap 10) of **three rows of two** (row gap 10). Cards are flex 1 (170), with the same card specification, the picture full width × 72, the same strings and the arrows kept.
- **Rest as V8 mobile:** video card, the 3-row list and the button. The album row still reads "Ông bà ở xa vẫn theo dõi cháu." (**not updated**; A-1). "Còn có" is removed here too.

---

## 6. Cả nhà cùng chăm + Trên cổ tay

### 6.1 Desktop `785:7290` (1440 × 1381; V8 1002)

**"Hàng"** `785:7291`: row, gap 48, align center, 1248 × 454.

*Copy* `785:7292` (width 560):

- The eyebrow, H2 and trust note are unchanged.
- The bullet styles and icons are unchanged (`journal`, `clock`, `eye`). The text changes:

| # | V8 (`family.bullets[i]`) | V9 |
|---|---|---|
| 1 | "Ghi và xem chung một nhật ký." | "Bố mẹ, ông bà và người chăm bé cùng một hành trình." |
| 2 | "Nhắc nhở đúng người đang chăm bé." | "Bàn giao ca chăm: ai cũng biết con vừa ăn, ngủ, cần gì tiếp." |
| 3 | "Ba mẹ, người chăm và người thân có quyền xem khác nhau." | "Mỗi người một quyền: người ghi chăm sóc, người chỉ xem ảnh." |

**Scenario "Tình huống (V8 · ẩn)"** `785:7311` has `hidden="true"`. Remove `.family__steps` from the home, or keep it unrendered; the owner asked "để ẩn" (hidden).

**NEW "Gia đình · minh hoạ"** `787:8881`: 640 × 454, bg `#F0FAF7` (raw), r28, **absolute layout**. Render it with `Fit w={640} h={454}` on desktop; mobile uses its own flow layout. It is decorative and should be `aria-hidden`; the copy bullets carry the meaning.

1. **Photo card "Ảnh gia đình"** `787:8882` at (195, 28), width 250. `var(--surface)`, r22, padding 10 10 12, column, gap 10, shadow-card.
   - Photo 230 × 150, r14 (tone **sun**, a 230 square at y −40). Figma shows a sitting, smiling baby; use `photos.sun` or `teddy-one-plush.jpg`.
   - Lock strip "Khoá": `var(--mint-soft)`, r10, padding 6 × 8, gap 6. `lock` 12 + "Chỉ những người được mời mới xem được" 11 SemiBold `var(--mint-text)`, which wraps to 2 lines.
2. **Member pills.** Each is `var(--surface)`, r999, padding 6 12 6 6, gap 8, shadow-card:
   - Avatar 34 circle, 2 px `var(--surface)` border, letter 14 SemiBold `var(--ink)`.
   - Text column: name 13 Bold `var(--ink)`; role row (gap 4) with a 10 px icon + 11 Medium `var(--ink-muted)`.

| Pill (node) | Position | Avatar | Name | Role icon | Role |
|---|---|---|---|---|---|
| `787:8895` | (16, 40) | "B" `#D1E5FF` | "Bố" | `check` | "Ghi & xem tất cả" |
| `787:8904` | (463, 40) | "M" `#FFDBCC` | "Mẹ" | `star` | "Quản lý gia đình" |
| `787:8913` | (16, 150) | "Ô" `#D9F2E0` | "Ông bà" | `eye` | "Xem ảnh, bình luận" |
| `787:8923` | (471, 150) | "Cô" `#FFF2C7` | "Cô trông bé" | `feed` | "Ghi bú, ngủ, tã" |

3. **Handover card "Bàn giao ca"** `787:8932` at (32, 258), width 576. `var(--surface)`, r20, padding 16 × 18, column, gap 10, shadow-card.
   - Head (row, gap 8, center): icon box (`var(--sunshine-soft)`, padding 8, r12, `link` 14) + "Bàn giao ca · Mẹ → Cô trông bé" 14 Bold `var(--ink)` + spacer + "13:55" 12 Medium muted.
   - "Nội dung" (row, gap 8): three flex-1 tiles. Each tile is `var(--cloud)`, r12, padding 8 × 10, gap 8, with an icon box (padding 8, r12, icon 12) and a text column (12 SemiBold `var(--ink)` / 11 Medium muted):
     - `feed` on `var(--care-bottle-soft)`: "Bú 120 ml" / "lúc 13:00"
     - `sleep` on `var(--care-sleep-soft)`: "Đang ngủ" / "từ 13:30"
     - `clock` on `var(--sunshine-soft)`: "Nhắc tiếp" / "Vitamin D 15:00"
   - Note row (gap 6): `journal` 12 + "“Bé hơi quấy chiều nay, nhớ vỗ ợ hơi sau bú.” — Mẹ" 12 Medium muted.
   - Confirm row (gap 6): avatar 20 `#FFF2C7` "Cô" (8 SemiBold) + "Cô trông bé đã nhận bàn giao" 11 SemiBold `var(--mint-text)` + `check` 12.

**"Trên cổ tay"** `785:7337`: 1248 × **691** (V8 420). The shell is unchanged: `#163D44`, r28, padding 40 × 48, row, gap 40, align center. The watch illustration (560 × 340, Apple Watch + round Wear OS watch + labels) is **unchanged** and now sits vertically centred next to a taller copy column.

*Copy* `785:7338`: width 480, gap 14, height 611.

| Element | V8 (`homePage.wrist.*`) | V9 |
|---|---|---|
| Chip | "Trên cổ tay" | unchanged |
| Title (30 Bold lh 1.2 white) | `title` "Đang bế con? Ghi ngay trên đồng hồ." | "Đang bế con? Ghi nhanh không cần mở app." |
| Lead (16 Medium lh 1.55 `#CCE0E0`) | `lead` "Một chạm để ghi bú, ngủ, tã — cả nhà thấy ngay trên điện thoại." | "Một chạm trên đồng hồ, widget màn hình chính, nút điều khiển iOS — hoặc chỉ cần nói với Siri. Cả nhà thấy ngay trên điện thoại." |
| Platform chips (wrap, gap 8; padding 5 × 10, r999, 12 SemiBold, icon 12 + gap 6) | "✓ Apple Watch" (mint) · "🕒 Đồng hồ Android (Wear OS) · Sắp có" (surface / muted) | five chips, **all** `var(--mint-soft)` bg + `check` 12 + `var(--mint-text)`: "Apple Watch" · **"Wear OS"** (`794:8778`; layer misnamed "Chip · Apple Watch"; text colour raw `#06716D` = `--mint-text`) · "Widget" · "Điều khiển iOS" · "Siri". They wrap to 2 lines ("Siri" alone on line 2). |

**NEW "Cách ghi nhanh"** `787:68564`: row, gap 12, align start, 480 wide. Two flex-1 tiles (234).

- Tile: `rgba(255,255,255,.08)` (raw), r20, padding 12, column, gap 8.
- Tile label: 10 SemiBold `#9EBFBF` (raw), uppercase as typed.

1. **"Widget"** `787:68565` (234 × 138). Label "WIDGET".
   - Mock `787:68567`: white, r16, padding 10, column, gap 6.
   - "Teddy · bú cuối" 11 Medium `var(--ink-muted)`; "2 giờ 15 trước" 15 Bold `var(--ink)`.
   - A row (gap 6) of three icon boxes (padding 8, r12, icon 12): `feed` / `var(--care-bottle-soft)`, `sleep` / `var(--care-sleep-soft)`, `diaper` / `var(--care-diaper-soft)`.
2. **"Điều khiển iOS"** `787:68581` (234 × 122). Label "ĐIỀU KHIỂN iOS". Keep the lower-case "i" in "iOS", so do not use `text-transform`.
   - Buttons row: gap 8, padding 10 × 4.
   - Three items, each a centred column (gap 4): a 40 circle `rgba(255,255,255,.18)` (raw) with an 18 icon in white, then a label 10 Medium `#CCE0E0`.
     - `feed` "Bú"
     - `sleep` "Ngủ"
     - `diaper` "Tã"

**NEW "Siri"** `787:68600` (480 × 173, full width). `rgba(255,255,255,.08)`, r20, padding 12 × 14, column, gap 8.

- Head (gap 8): orb, a 20 circle with `linear-gradient(90deg, #6680FF, #E559B2 50%, #FFB24D)` (raw), + "Hey Siri…" 12 SemiBold `#9EBFBF`.
- Three commands. Each is a column (gap 2): the spoken line in 14 SemiBold white, then a reply row (gap 6) with `check` 11 + 12 Medium `#BFD9D9` (raw).

| Spoken | Reply |
|---|---|
| "“Lumi ghi cữ bú 120 ml.”" | "Đã ghi bú bình 120 ml lúc 9:00." |
| "“Lần bú cuối của Teddy lúc mấy giờ?”" | "2 giờ 15 phút trước, bú bình 120 ml." |
| "“Bắt đầu giấc ngủ cho Teddy.”" | "Đang tính giờ ngủ từ 9:30." |

The quotes are curly “ ” inside the string.

### 6.2 Mobile `785:8118` (390 × 2043; V8 1548)

**"Hàng"** `785:8119`: column, gap 24.

- **Copy:** the same three new bullets; H2 28 / 1.18; trust note align start.
- "Tình huống" `785:8139` is hidden.

**"Gia đình · minh hoạ"** `792:8915` uses a **flow layout** on mobile, not absolute: `#F0FAF7`, r24, padding 16, column, gap 12, full width.

- **Photo card:** `var(--surface)`, r18, padding 8 8 10, gap 8, shadow-card. Photo full width × 150, r12 (sun; a 302 square at y −76). Lock strip as desktop, on 1 line.
- **"Thành viên"** (column, gap 8): two rows (gap 8) of two flex-1 member cards.
  - Card: `var(--surface)`, **r16**, padding 6 8 6 6, gap 8, **no shadow**.
  - Avatar **30** (13 SemiBold); name 13 Bold; role **10** Medium muted, with **no role icons**.
  - Strings as desktop: Bố / "Ghi & xem tất cả", Mẹ / "Quản lý gia đình", Ông bà / "Xem ảnh, bình luận", Cô trông bé / "Ghi bú, ngủ, tã".
- **Handover card:** padding 16 × 14. "Nội dung" becomes a **column** (gap 6) of full-width tiles. The other content is the same.

**"Trên cổ tay"** `785:8165`: 350 × **884** (V8 545). Shell as V8 mobile: `#163D44`, r24, padding 24 × 20, column, gap 20.

*Copy* `785:8166` (width 310, gap 14):

- Title 24 / 1.2 "Đang bế con? Ghi nhanh không cần mở app."
- **Lead, mobile only** (14 lh 1.55 `#CCE0E0`): "Một chạm trên đồng hồ, widget, nút điều khiển iOS — hoặc nói với Siri."
- **Platform chips differ from desktop.** "Apple Watch" ✓ mint · **"Wear OS · Sắp có"** (`792:9001`: bg `rgba(255,255,255,.12)` (raw), text `#CCE0E0`, its check icon hidden) · "Widget" ✓ · "Điều khiển iOS" ✓ · "Siri" ✓.
- "Cách ghi nhanh" `792:9013`: row, gap 12, two flex-1 tiles (≈ 149). Same content.
- Siri block: full width, same content.

The watch illustration (310 × 250) is unchanged from V8 mobile.

---

## 7. Lumi & gợi ý cho bé

### 7.1 Desktop `785:7430` (1440 × 1421; V8 1075)

Header, both demo panels, floats, CTA button and caption: **identical strings and layout to V8.**

**NEW "Hỏi Lumi"** `788:8801`: inserted between the demo row and the CTA. Column, gap 16, full width.

- **Head** `788:8802` (row, gap 8, center): icon box (`var(--care-sleep-soft)`, padding 8, r12, `spark` 14) + "Thử hỏi Lumi" 18 Bold `var(--ink)` + "· Lumi hiểu nhật ký, mốc và kỷ niệm của con" 14 Medium `var(--ink-muted)`. The middle dot belongs to the second string.
- **Cards "Thẻ"** `788:8808`: row, gap 12, fixed height 256. Four cards of **303** (4 × 303 + 3 × 12 = 1248).
  - Card shell: `var(--surface)`, r24, padding 16, column, gap 12, shadow-card, full height.
  - **Question "Câu hỏi":** `var(--mint-deep)`, r18, padding 10 × 14, full width; text 14 SemiBold lh 1.35 `var(--on-mint-deep)`. This mirrors the parent bubble in the chat mock.
  - **Answer "Trả lời":** `var(--cloud)`, r18, padding 12, column, gap 8, flex 1 (fills the card).
    - "Lumi" label row (gap 6): icon box (`var(--mint-soft)`, padding 8, r12, `spark` 10) + "Lumi" 12 SemiBold `var(--mint-text)`.

| # (node) | Question | Visual answer |
|---|---|---|
| 1 `788:8809` | "Con 6 tháng có thể ăn gì?" | Food chips (wrap, gap 6; padding 5 × 10, r999, 12 SemiBold `var(--ink)`): "Cháo rây" `var(--sunshine-soft)`, "Bí đỏ nghiền" `var(--care-bottle-soft)`, "Chuối" `var(--sunshine-soft)`, "Khoai lang" `var(--care-diaper-soft)`. Then "Thử 1 món mới mỗi 3 ngày." 12 Medium muted. |
| 2 `788:8828` | "Gợi ý hoạt động phù hợp cho hôm nay" | Two rows, each `var(--surface)`, r12, padding 8 × 10, gap 8, with an icon box (padding 8, r12, icon 12), a title 13 SemiBold `var(--ink)` (flex 1) and a duration 11 Medium muted: `heart` / `var(--care-bottle-soft)` "Chơi úp bụng" "10 phút"; `journal` / `var(--sunshine-soft)` "Đọc sách tranh" "5 phút". |
| 3 `788:8850` | "Tóm tắt nhật ký tuần này" | Bar chart "Biểu đồ ngủ" (row, gap 6, align end, padding 4 × 2): 7 flex-1 columns (gap 3, centred), each a bar 14 wide r4 over a label 9 Medium muted. Bars T2–T7 are `var(--mint-soft)`, heights 42 / 48 / 30 / 54 / 60 / 36; "CN" is 48 in **`var(--mint-deep)`** (today). Labels "T2" "T3" "T4" "T5" "T6" "T7" "CN". Then chips (padding 3 × 8, r999, 12 SemiBold): "Ngủ TB 13 giờ" (`var(--care-sleep-soft)` / `var(--care-sleep-ink)`) and "42 cữ bú" (`var(--care-bottle-soft)` / `var(--care-bottle-ink)`). |
| 4 `788:8886` | "Lần bú cuối lúc mấy giờ?" | "2 giờ 15" **30 Bold** `var(--ink)`; "trước · bú bình 120 ml · Bố ghi" 12 Medium muted; a row (gap 6) with `clock` 12 + "Cữ tiếp khoảng 11:30" 12 SemiBold `var(--mint-text)`. |

The chart is decorative: mark it `aria-hidden` and give the card a visually hidden summary.

**CTA** `785:7595`: unchanged ("Khám phá Lumi" `<a>` + caption).

### 7.2 Mobile `785:8258` (390 × 2128; V8 1502)

The header and panels are as V8 mobile (eyebrow still the lower-case "Lumi · trợ lý trong Child Life").

**"Hỏi Lumi"** `793:8796` (350 × 640):

- Head: icon + "Thử hỏi Lumi" only. **No "· Lumi hiểu…" subtitle.**
- Cards: two rows (`793:8887` h298, `793:8888` h280; 16 between rows), each with two flex-1 cards (≈ 170, gap 10).
- Card differences from desktop:
  - Card padding **10**.
  - Question **12** SemiBold.
  - Answer padding **12 × 8**.
  - Activity rows have **no icon boxes** (`var(--surface)`, r12, padding 8; 12 SemiBold + 11 Medium).
  - "2 giờ 15" at **22** Bold.
- Same strings and order (1–2 in row 1, 3–4 in row 2).

**CTA** `785:8423`: the button only. **The caption "Ví dụ minh hoạ. Lumi hỗ trợ nhập chữ và ảnh; bạn kiểm tra và bấm lưu." is removed on mobile**; V8 mobile had it. Keep the caption (A-1): it is the "illustrative example" disclaimer.

---

## 8. NEW · 5b "Nhắc thông minh" ("Không bỏ lỡ khoảnh khắc quan trọng")

### 8.1 Desktop `789:8811` (1440 × 752)

`background: var(--surface)`, padding 96. One child, "Hàng" `789:8812`: a row, gap **56**, align center, full width.

#### Left: Copy `789:8813`

Flex 1 (≈ 632), column, gap 24.

- **Header** (gap 12):
  - Eyebrow (mint): "Nhắc nhở & cá nhân hoá"
  - H2 (42 Bold lh 1.16): "Không bỏ lỡ những khoảnh khắc quan trọng."
  - Lead (18 Medium lh 1.55 muted): "Child Life nhắc đúng lúc, theo tuổi và thói quen của con — từ cữ bú, mốc phát triển, món ăn mới đến những tấm ảnh chưa kịp lưu."
- **Modules "Mô-đun"** `789:8819` (column, gap 10). Four rows, each `var(--cloud)`, r16, padding 10 × 14, row, gap 12, align center:
  - Icon box: padding 8, r12, icon 14.
  - Text column (flex 1, gap 1): title **15 Bold** `var(--ink)`; sub **13 Medium** `var(--ink-muted)`.
  - Toggle "Bật": 40 × 24, `var(--mint-deep)`, r999, padding 2, knob 20 white on the right, so **on**. Use `kit.tsx` `Toggle` with `scale ≈ 0.78` (base 51 × 31).

| Row (node) | Icon / tint | Title | Sub |
|---|---|---|---|
| `789:8820` | `today` / `var(--care-bottle-soft)` | "Chăm sóc" | "Cữ bú, giấc ngủ, lịch tiêm" |
| `789:8830` | `star` / `var(--care-sleep-soft)` | "Phát triển" | "Mốc sắp tới, gợi ý chơi hợp tuổi" |
| `789:8839` | `drop` / `var(--sunshine-soft)` | "Dinh dưỡng" | "Món mới, lịch ăn dặm" |
| `789:8848` | `memories` / `var(--mint-soft)` | "Kỷ niệm" | "Ảnh chờ lưu, ngày tròn tháng, sinh nhật" |

The toggles are drawn as a static illustration with all four on. **Do not make them real switches.** If kept, render them `aria-hidden` (they control nothing on the site).

- **Note** `789:8858`: 13 Medium muted, "Bạn chọn nhận gì và lúc nào. Không gửi vào giờ ngủ của con."

#### Right: Lock screen "Màn hình khoá" `789:8859`

Width 560, r32, padding 28 × 24, column, gap 10, centred. Background `linear-gradient(143.13deg, #173D45 0%, #386B73 71.43%)` (raw). Decorative: `aria-hidden`, plus a short visually hidden description.

- Date: "Thứ Bảy, 18 tháng 1", 14 SemiBold `#D9EBEB` (raw).
- Time: "9:41", 56 Bold white.
- **Notifications.** Each is 512 wide, `rgba(255,255,255,.92)`, r18, padding 12, row, gap 10, align start, shadow-card.
  - App tile: 30 × 30, r8, `#298C80` (raw), with a 16 icon (white).
  - Text column (flex 1, gap 2):
    - Head row (gap 6): title 13 SemiBold `var(--ink)` (flex 1) + time 11 Medium muted.
    - Body 12 Medium lh 1.4 muted.
    - Category chip: padding 3 × 8, r999, 11 SemiBold.

| Node | Icon | Title | Time | Body | Chip |
|---|---|---|---|---|---|
| `789:8862` | `camera` | "Bạn có 8 ảnh mới của bé" | "bây giờ" | "Đang chờ lưu — cùng giữ lại những khoảnh khắc này nhé." | "Kỷ niệm" (`var(--mint-soft)` / `var(--mint-text)`) |
| `789:8874` | `cake` | "Teddy đã tròn 1 tuổi!" | "8:00" | "Tạo thiệp sinh nhật từ ảnh cả năm nào." | "Kỷ niệm" (mint) |
| `789:8886` | `star` | "Sắp đến mốc: tự đứng vững" | "hôm qua" | "Con 11 tháng — xem 3 trò chơi giúp con tập đứng." | "Phát triển" (`var(--care-sleep-soft)` / `var(--care-sleep-ink)`) |
| `789:8897` | `drop` | "Gợi ý món cho bữa trưa" | "hôm qua" | "Cháo bí đỏ thịt gà hợp với con lúc này." | "Dinh dưỡng" (`var(--sunshine-soft)` / `var(--ink)`) |

- **"Gộp"** `789:8908`: width 472, `rgba(255,255,255,.55)`, r16, padding 8 × 12, centred. Text "+2 nhắc nhở chăm sóc", 12 SemiBold muted.

**Reuse.** `kit.tsx` `Push` is a different (iOS banner) style with the app icon and actions. Build a small `LockNotice` instead. The app tile could reuse `art.appIcon` (`assets/figma/logo-app-icon.svg`) instead of a teal square with a glyph (A-15).

### 8.2 Mobile `793:8899` (390 × 875)

`var(--surface)`, padding 56 × 20, gap 28. The order is **header → lock screen → module chips**.

- **Header:** eyebrow and H2 28 are the same. **Mobile lead (shorter):** "Nhắc đúng lúc, theo tuổi và thói quen của con — từ cữ bú, mốc phát triển, món ăn mới đến ảnh chưa kịp lưu."
- **Lock screen** `793:8905`: full width, r28, padding 20 × 12, gap 8, gradient at 136.23deg.
  - **No date.** "9:41" at **40** Bold.
  - Four notifications, full width, same style.
  - **All times "bây giờ".** Two bodies are shorter:
    - #1 "Cùng giữ lại những khoảnh khắc này nhé."
    - #3 "Xem 3 trò chơi giúp con tập đứng."
    - #2 and #4 are as desktop.
  - **No "+2 nhắc nhở chăm sóc".**
- **Modules → chips** `793:8953` (wrap, gap 6). Each is `var(--mint-soft)`, padding 6 × 12, r999, 13 SemiBold `var(--mint-text)`: "✓ Chăm sóc" · "✓ Phát triển" · "✓ Dinh dưỡng" · "✓ Kỷ niệm". There are no subs and no toggles.
- **The note "Bạn chọn nhận gì và lúc nào…" is absent on mobile.** Keep it (A-1).

---

## 9. Hành trình khi con lớn

### 9.1 Desktop `785:7683` (1440 × 736; V8 700)

Header and cards are unchanged. **NEW in each card body**, after the description: "Nút · Tìm hiểu thêm" (`790:8840`, `790:8845`, `790:8850`, `790:8855`).

- Row, gap 8, padding 6 × 0, hug width, left-aligned.
- "Tìm hiểu thêm" 14 SemiBold `var(--mint-text)` + `arrow-right` 16.

Link structure in Figma: cards 1–2 are `<a>` with the button as a plain frame; cards 3–4 are not `<a>` but their button is. The built code already wraps every card in `<a href={pathOf(stageIds[i])}>`. Keep the whole card as the link and render "Tìm hiểu thêm" as a non-interactive `<span>` inside it, since nested links are invalid.

Targets:

| Card | Page |
|---|---|
| 1 | Năm đầu đời (`stage1`) |
| 2–4 | stage pages `stage2`..`stage4` |

The wrapper "Chặng" became a column holding one row, "Hàng". No visual effect.

### 9.2 Mobile `785:8497` (390 × 811; V8 743)

Each 2 × 2 card gets "Tìm hiểu thêm" (`793:8963`, `8967`, `8971`, `8975`), 115 × 28, below the title. Descriptions stay hidden on mobile. Card 1's title wraps to two lines, so the rows differ in height.

---

## 10. Kết (`#tai-app`)

### 10.1 Desktop `785:7872` (1440 × 460; V8 532)

`var(--surface)`, padding 24 96 96 (unchanged).

**Card "Thẻ"** `785:7873`:

- `#163D44`, r40, **padding 64 × 56**, `display: flex; justify-content: center; align-items: center`, width 1248.
- **The photo is removed** (`closing__photo`, V8 `735:6518`).

**Content "c"** `785:7874`: column, gap **20**, `align-items: center`, `text-align: center`.

1. Title: "Bắt đầu từ năm đầu đời của con." 40 Bold lh 1.18 white, one line (nowrap), `closing.title` unchanged.
2. Sub: "Ghi chép, nhắc nhở và kỷ niệm — cả nhà cùng một nơi." 17 Medium lh 1.55 `#CCE0E0`, `closing.sub` unchanged.
3. **Badges "Huy hiệu tải app"** `790:8824`: row, gap 12. This is **not** the V8/CTA tải app component instance, but plain frames.
4. Caption `790:8823`: "Miễn phí trên iPhone và Android." 13 Medium `#CCE0E0`, centred. V8 caption `stores.caption`: "Tải miễn phí trên iPhone và Android."

**Store badges: exactly as drawn**

| | App Store `790:8825` | Google Play `790:8831` |
|---|---|---|
| Fill / border | `#000` + 1 px `#A6A6A6` (raw) | same |
| Radius / padding / gap | r12; padding 10 18 10 14; gap 10 | same |
| Logo | `790:8826` "Logo App Store", 28 × 28 | `790:8832` "Logo Google Play", 28 × 28 |
| Logo artwork | the **real Apple logo silhouette** (bitten apple + leaf path), filled **white** | a **four-colour Play triangle**: left `#00D7FE`, top `#00F076`, right `#FFCE00`, bottom `#FF3A44`. These are the colours of the pre-2022 Google Play mark, approximated, not the current official logo. |
| Text | white; prefix 11 Medium "Tải về trên"; name 21 SemiBold "App Store" | white; prefix 11 Medium "Tải nó trên"; name 21 SemiBold "Google Play" |

**What this means:**

- The badges imitate the **official** black store badges: black fill, `#A6A6A6` hairline and logo plus two-line text. Apple's standard black badge is exactly black with a `#A6A6A6` border.
- The text is set in Be Vietnam Pro and the localisation is guessed.
  - Apple's Vietnamese badge reads "Tải về trên App Store", which is plausible.
  - Google's is generated by Google's badge tool. "Tải nó trên" is a literal rendering of "GET IT ON" and must be checked against the official vi badge (A-12).
- **Do not rebuild them as HTML text.** Apple and Google brand rules require their unmodified badge artwork. Download the official localized SVGs:
  - Apple: Marketing Resources, black badge, vi and en.
  - Google: Play badge generator, vi and en.
- Ship those as `assets/figma/badge-app-store-{vi,en}.svg` and `badge-google-play-{vi,en}.svg`, as `<img alt>` inside the store links. The Figma vectors for the two logos are in nodes `790:8826` and `790:8832` (and mobile `793:8981`, `793:8987`). They are reference only; nothing was downloaded into the repo.
- **The existing glyphs do not match.** `assets/figma/store-apple*.svg` is a placeholder of a circle and a tilted ellipse in `#141417`. `store-play*.svg` is a single flat `#141417` triangle. Both stay as the hero's white placeholder badges (§2, unchanged in V9) until the official artwork replaces them everywhere (A-13).

**Shared component.** `Closing` is shared by the home, Năm đầu đời and Chặng 2–4 pages. The V9 versions of those pages (`785:9895` and `785:10856`, both 460 high) appear to use the same centred card, but they are not verified here. Change `Closing` once, and check those frames when their spec is written.

### 10.2 Mobile `785:8683` (390 × 407; V8 336.9)

`var(--surface)`, padding 8 20 48. Card: `#163D44`, r28, padding 28 × 20. Content: width 310, gap 16, **left-aligned**, unlike desktop.

- Title 28 lh 1.18; sub 15 lh 1.55, both unchanged.
- **Badges** `793:8979`: a **column**, gap 12. **Each badge is full width (310)**, `justify-content: center`, r10, padding 9 15 9 12, gap 9. Logo 24; prefix 9 Medium; name 18 SemiBold. Same fill and border.
- Caption "Miễn phí trên iPhone và Android.", 12 Medium `#CCE0E0`.

With official artwork, use the badge images at a fixed height (≈ 48) and centre them; do not stretch an official badge to 310 (A-12).

---

## 11. Unchanged

These were verified by extraction (desktop) or by metadata structure and heights (mobile):

- **Tiện ích khác** `785:7600` / `785:8428`: same 8 cards, chips, strings and "Xem tất cả trong Năm đầu đời".
- **Miễn phí & hỏi đáp** `785:7828` / `785:8639`: same four points and the same five questions; answer 1 open.
- **Footer** `785:7880` / `785:8689`.
- **Mobile sticky bar** `785:8693`: "Tải miễn phí".
- **Mobile nav** `785:7891`.

---

## R. Reuse map

| V9 part | Reuse / adapt | New |
|---|---|---|
| Nav order | `Chrome.tsx` `Nav`: reorder `links` | — |
| Hero | `HomeIntro.tsx` `HomeHero`, `.home-hero*` | Two-weight eyebrow (`<strong>` inside `Eyebrow`); drop `.home-hero__support`, `.home-hero__vision`, the hero `AppCta` caption (or a `caption={false}` prop); new chip status per stage; `nodes[3]` chip at (412, 244); float 2 text |
| Ba giá trị rows | `.value-row` / `.value-rows`, `IconBox`, `Photo` | `Row` component (title + sub + trailing: chip, icon trio, thumbs, avatars), reused by 2b; `Avatars` (22 / 28 / 34 sizes, raw colours); remove `.home-value__icon` and mobile row mode; `.home-button--lg` centred |
| 2b | `Row`, `IconBox`, `.home-button--outline`, `.home-head` | `HomeRestart` section, segmented age control (static), timeline bar, two-column panel, `home-section--cloud` |
| Kỷ niệm strip | `Photo`, `Chip`-like tags, `Avatars` | `MemorySteps` (`<ol>`, 6 × 198 desktop, 3 × 2 mobile); remove `.mem-also`; album body string |
| Family illustration | `Fit` (640 × 454, desktop), `Photo`, `IconBox`, `Avatars` | Member pill, handover card, mobile flow variant; drop `.family__steps` / `.family-step` / `.family__arrow` from the home |
| Trên cổ tay | `.wrist*`, `Watch` + `HomeFace`, `RoundWatch`, `.wrist__platforms` | Chip set of 5 (all "ready" style on desktop; Wear OS chip dimmed on mobile); `QuickLog` (Widget mock, iOS Controls, Siri card) |
| Thử hỏi Lumi | Bubble colours from `.lp-chat` parent bubble; `IconBox`; `Chip` | `AskLumi` grid (4 × 303 desktop, 2 × 2 mobile), mini bar chart |
| 5b | `kit.tsx` `Toggle` (scale ≈ 0.78), `IconBox`, `home-section--white` | `HomeAlerts` section, module rows, lock-screen panel, `LockNotice` |
| Hành trình | `HomeMore.tsx` `HomeJourney`, `.stage-v8*` | `.stage-v8__more` span ("Tìm hiểu thêm" + arrow) |
| Kết | `Closing.tsx`, `.closing*` | Centred layout, no photo; `OfficialBadges` (official artwork, link or static per `storeLinks`); new caption; mobile column badges |

`StoreBadges.tsx` rule (spec 34 §C, R-170 owner 2026-10-19) still applies to the Kết badges: before `storeLinks` exist, a badge is a picture, not a link, and the caption must not promise availability (A-5).

---

## S. Copy keys

### S.1 Existing keys

**Changed values** (vi and en):

| Key | New vi value |
|---|---|
| `homePage.hero.title` | "Cùng con lớn lên, qua từng khoảnh khắc." |
| `homePage.hero.lead` | "Từ chăm sóc hằng ngày, theo dõi phát triển đến lưu giữ kỷ niệm — Child Life kết nối cả gia đình trong hành trình khôn lớn của con." |
| `homePage.hero.seeApp` | "Bắt đầu cùng con trong năm đầu đời" (rename to `firstYearLink` if the target changes, A-4) |
| `homePage.values.eyebrow` | "Child Life giúp gì trong năm đầu đời của con" |
| `homePage.values.lead` | "Chăm sóc \| Phát triển \| Kỷ niệm". Better as `pillars: ['Chăm sóc', 'Phát triển', 'Kỷ niệm']`. |
| `homePage.values.cards[0..2].body` | §3.1 |
| `homePage.memories.album.body` | "Cả nhà cùng xem, bình luận. Chia sẻ ra ngoài bằng link khi bạn muốn." |
| `homePage.memories.lead` | the mobile V9 text (§5.2), if shown (A-1) |
| `homePage.family.bullets[0..2]` | §6.1 |
| `homePage.wrist.title` | "Đang bế con? Ghi nhanh không cần mở app." |
| `homePage.wrist.lead` | desktop text (§6.1) |
| `homePage.wrist.wear` | "Wear OS" (desktop) or "Wear OS · Sắp có" (mobile), A-7 |

**Removed:**

- `homePage.hero.support`, `homePage.hero.vision` and `homePage.hero.smile`. `smile` is reused in no other place; grep before deleting.
- `homePage.hero.soon` (replaced by two statuses).
- `homePage.values.mock`.
- `homePage.memories.alsoLabel`, `also`, `soon`.
- `homePage.family.steps` (or keep it for the hidden V8 scenario).

**Reused unchanged:**

| Key | Value |
|---|---|
| `homePage.values.cards[i].title` | |
| `homePage.memories.eyebrow` / `title` / `video` / `card` / `thenNow` / `album.title` / `album.seen` / `button` | |
| `homePage.family.eyebrow` / `title` / `trust` | |
| `homePage.wrist.chip` / `apple` / `wearLabel` / `round` | |
| `homePage.assistant.*` | all |
| `homePage.tools.*`, `homePage.trust.*` | |
| `homePage.journey.*` | |
| `closing.title` / `sub` | |
| `homePage.hero.now` | "Đang có trong app" |
| `home.watch.mock.baby` | "Teddy" |
| `firstYearPage.groups[1].title` | "Cả nhà cùng chăm", also the Ba giá trị row title |
| `forBaby.*` / `lumiPage.*` | where a string is identical |
| `homePage.memories.album.title` | "Album gia đình riêng tư" (Ba giá trị row 3) |
| `homePage.tools.cards[1].title` | "Mốc phát triển" (row) |

### S.2 New keys (proposal)

```ts
homePage: {
  hero: {
    eyebrowStrong: 'Đồng hành cùng con khôn lớn',      // rendered "Child Life · <strong>…</strong>"
    next: 'Chặng tiếp theo', future: 'Trong tương lai',  // stage 2 / stages 3–4
    learning: { title: 'Học tập', sub: 'Hôm nay con học thế nào?' },
  },
  values: {
    rows: [ // per card, 3 × { title, sub, chip? }
      [{ title: 'Bú · ngủ · tã', sub: 'Ghi nhanh 1 chạm' }, { title: 'Nhắc lịch chăm bé', sub: 'Ăn dặm bữa trưa · 11:30', chip: 'Dinh dưỡng' }, { title: 'Cả nhà cùng chăm', sub: 'Bố vừa ghi cữ bú · 2 phút' }],
      [{ title: 'Mốc phát triển', sub: 'Biết lẫy · 4 tháng', chip: '✓ Đã ghi' }, { title: 'Gợi ý theo độ tuổi', sub: 'Chơi úp bụng 10 phút', chip: '4 tháng' }, { title: 'Nhật ký lớn khôn', sub: 'Tuần 18 · 6 ghi chép' }],
      [{ title: 'Tự tìm ảnh của bé', sub: '8 ảnh mới đang chờ lưu' }, { title: 'Thiệp & video kỷ niệm', sub: 'Tròn 6 tháng', chip: 'Tạo ngay' }, { title: 'Album gia đình riêng tư', sub: 'Chỉ người được mời' }],
    ],
    avatars: { mom: 'M', dad: 'B', grandma: 'Bà', grandpa: 'Ô' },
    all: 'Xem tất cả tính năng cho năm đầu đời',
  },
  restart: {
    eyebrow: 'Con 2 tháng hay 6 tháng cũng vậy', title: 'Bắt đầu lúc nào cũng kịp.',
    lead: 'Dù con đã vài tháng tuổi, Child Life vẫn đồng hành chăm sóc, giúp bạn hiểu con và lưu trọn những khoảnh khắc — cả những ngày đã qua.', // mobile
    profile: {
      title: 'Teddy bắt đầu dùng Child Life lúc…',
      ages: ['Mới sinh', '2 tháng', '6 tháng', '9 tháng'],
      birth: 'Ngày sinh', today: 'Hôm nay · 6 tháng', year: '1 tuổi',
      label: 'Child Life tự sắp xếp lại cho bạn',
      rows: [ { title: 'Tìm lại 214 ảnh từ ngày con chào đời', sub: 'Xếp theo từng tháng · chờ bạn chọn' },
              { title: 'Mốc đã qua: lẫy, cười thành tiếng', sub: 'Đánh dấu nhanh nếu con đã làm được', chip: '3 mốc' },
              { title: 'Gợi ý & nhắc lịch đúng tuổi 6 tháng', sub: 'Ăn dặm, giấc ngủ, lịch tiêm tiếp theo', chip: 'Từ hôm nay' } ],
    },
    points: [ { title: 'Đồng hành chăm sóc từ hôm nay', body: '…' }, { title: 'Hiểu con ở đúng giai đoạn', body: '…' }, { title: 'Lưu trọn cả những ngày đã qua', body: '…' } ],
    button: 'Bắt đầu với tuổi của con',
  },
  memories: {
    steps: [ { title: 'Tự động tìm ảnh', sub: 'Ảnh mới của bé', tags: ['Tự động'] },
             { title: 'Chọn & lưu', sub: 'Giữ ảnh đẹp, bỏ ảnh trùng', tags: ['1 chạm'] },
             { title: 'Tạo thiệp, video', sub: 'Từ mẫu có sẵn', tags: ['Thiệp', 'Video'] },
             { title: 'Album & chia sẻ', sub: 'Riêng cho gia đình, hoặc gửi ra ngoài', tags: ['Gia đình', 'Link'] },
             { title: 'Câu chuyện, nhật ký', sub: 'Ghi lại lời kể cho con', tags: ['Nhật ký'], quote: '“Hôm nay con cười thành tiếng lần đầu…”' },
             { title: 'Các mốc', sub: 'Lần đầu của con', tags: ['Cột mốc'], milestones: ['★ Biết lẫy', '★ Mọc răng đầu'] } ],
  },
  family: {
    photoLock: 'Chỉ những người được mời mới xem được',
    members: [ { initial: 'B', name: 'Bố', role: 'Ghi & xem tất cả' }, { initial: 'M', name: 'Mẹ', role: 'Quản lý gia đình' },
               { initial: 'Ô', name: 'Ông bà', role: 'Xem ảnh, bình luận' }, { initial: 'Cô', name: 'Cô trông bé', role: 'Ghi bú, ngủ, tã' } ],
    handover: { title: 'Bàn giao ca · Mẹ → Cô trông bé', time: '13:55',
      items: [['Bú 120 ml', 'lúc 13:00'], ['Đang ngủ', 'từ 13:30'], ['Nhắc tiếp', 'Vitamin D 15:00']],
      note: '“Bé hơi quấy chiều nay, nhớ vỗ ợ hơi sau bú.” — Mẹ', done: 'Cô trông bé đã nhận bàn giao' },
  },
  wrist: {
    leadShort: 'Một chạm trên đồng hồ, widget, nút điều khiển iOS — hoặc nói với Siri.', // mobile
    widget: 'Widget', controls: 'Điều khiển iOS', siri: 'Siri',
    quick: { widgetLabel: 'WIDGET', widgetTitle: 'Teddy · bú cuối', widgetValue: '2 giờ 15 trước',
             controlsLabel: 'ĐIỀU KHIỂN iOS', buttons: ['Bú', 'Ngủ', 'Tã'],
             siriLabel: 'Hey Siri…', commands: [ ['“Lumi ghi cữ bú 120 ml.”', 'Đã ghi bú bình 120 ml lúc 9:00.'],
               ['“Lần bú cuối của Teddy lúc mấy giờ?”', '2 giờ 15 phút trước, bú bình 120 ml.'], ['“Bắt đầu giấc ngủ cho Teddy.”', 'Đang tính giờ ngủ từ 9:30.'] ] },
  },
  assistant: {
    ask: { title: 'Thử hỏi Lumi', sub: '· Lumi hiểu nhật ký, mốc và kỷ niệm của con', who: 'Lumi',
      foods: { q: 'Con 6 tháng có thể ăn gì?', items: ['Cháo rây', 'Bí đỏ nghiền', 'Chuối', 'Khoai lang'], tip: 'Thử 1 món mới mỗi 3 ngày.' },
      play: { q: 'Gợi ý hoạt động phù hợp cho hôm nay', items: [['Chơi úp bụng', '10 phút'], ['Đọc sách tranh', '5 phút']] },
      week: { q: 'Tóm tắt nhật ký tuần này', days: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'], sleep: 'Ngủ TB 13 giờ', feeds: '42 cữ bú' },
      last: { q: 'Lần bú cuối lúc mấy giờ?', value: '2 giờ 15', sub: 'trước · bú bình 120 ml · Bố ghi', next: 'Cữ tiếp khoảng 11:30' } },
  },
  alerts: {
    eyebrow: 'Nhắc nhở & cá nhân hoá', title: 'Không bỏ lỡ những khoảnh khắc quan trọng.',
    lead: '…desktop…', leadShort: '…mobile…',
    modules: [ { title: 'Chăm sóc', sub: 'Cữ bú, giấc ngủ, lịch tiêm' }, { title: 'Phát triển', sub: 'Mốc sắp tới, gợi ý chơi hợp tuổi' },
               { title: 'Dinh dưỡng', sub: 'Món mới, lịch ăn dặm' }, { title: 'Kỷ niệm', sub: 'Ảnh chờ lưu, ngày tròn tháng, sinh nhật' } ],
    note: 'Bạn chọn nhận gì và lúc nào. Không gửi vào giờ ngủ của con.',
    lock: { date: 'Thứ Bảy, 18 tháng 1', time: '9:41', more: '+2 nhắc nhở chăm sóc',
      notices: [ { title: 'Bạn có 8 ảnh mới của bé', when: 'bây giờ', body: 'Đang chờ lưu — cùng giữ lại những khoảnh khắc này nhé.', bodyShort: 'Cùng giữ lại những khoảnh khắc này nhé.', tag: 0 },
                 { title: 'Teddy đã tròn 1 tuổi!', when: '8:00', body: 'Tạo thiệp sinh nhật từ ảnh cả năm nào.', tag: 3 },
                 { title: 'Sắp đến mốc: tự đứng vững', when: 'hôm qua', body: 'Con 11 tháng — xem 3 trò chơi giúp con tập đứng.', bodyShort: 'Xem 3 trò chơi giúp con tập đứng.', tag: 1 },
                 { title: 'Gợi ý món cho bữa trưa', when: 'hôm qua', body: 'Cháo bí đỏ thịt gà hợp với con lúc này.', tag: 2 } ],
      now: 'bây giờ' },   // tag = index into modules[].title for the chip
  },
  journey: { more: 'Tìm hiểu thêm' },
},
closing: { caption: 'Miễn phí trên iPhone và Android.' },
stores: { badgeAlt: { appStore: 'Tải về trên App Store', googlePlay: 'Tải nó trên Google Play' } }, // alt for official artwork; wording per the official badge (A-12)
```

A few notes on the proposal:

- Mobile "✓ Chăm sóc" and similar are `'✓ ' + modules[i].title`. Render the ✓ as a `check` icon or keep it in the string; do not add separate keys.
- "Xem tất cả tính năng năm đầu đời" (mobile, without "cho") should not get its own key; use `values.all` everywhere (A-6).
- `types.ts` needs the matching shapes. `vi.ts` and `en.ts` must keep identical ids (D-012).

---

## E. English drafts (engineering drafts for owner review, D-012)

| # | Vietnamese (verbatim) | English draft |
|---|---|---|
| V9-01 | Đồng hành cùng con khôn lớn (eyebrow tail) | Growing up together |
| V9-02 | Cùng con lớn lên, qua từng khoảnh khắc. | Grow with your child, moment by moment. |
| V9-03 | Từ chăm sóc hằng ngày, theo dõi phát triển đến lưu giữ kỷ niệm — Child Life kết nối cả gia đình trong hành trình khôn lớn của con. | From daily care and tracking development to keeping memories — Child Life brings the whole family together as your child grows. |
| V9-04 | Bắt đầu cùng con trong năm đầu đời | Start with your baby's first year |
| V9-05 | 1–3 tuổi · Chặng tiếp theo | 1–3 years · Next stage |
| V9-06 | 3–6 tuổi · Trong tương lai / 6–12 tuổi · Trong tương lai | 3–6 years · In the future / 6–12 years · In the future |
| V9-07 | Học tập / Hôm nay con học thế nào? | Learning / How did they learn today? |
| V9-08 | Child Life giúp gì trong năm đầu đời của con | How Child Life helps in your baby's first year |
| V9-09 | Chăm sóc \| Phát triển \| Kỷ niệm | Care \| Development \| Memories |
| V9-10 | Ghi bú, ngủ, tã; nhắc lịch chăm bé, dinh dưỡng và ăn dặm. Cả nhà cùng biết con vừa được chăm thế nào. | Log feeds, sleep and diapers; get reminders for care, nutrition and solids. Everyone knows how the baby was just cared for. |
| V9-11 | Theo dõi mốc phát triển, nhận gợi ý hợp tuổi và lưu nhật ký lớn khôn của con. | Track milestones, get tips for your baby's age and keep a journal of them growing up. |
| V9-12 | Tự tìm ảnh của bé, tạo thiệp và video, cất vào album gia đình riêng tư. | Finds your baby's photos for you, makes cards and videos, and keeps them in a private family album. |
| V9-13 | Bú · ngủ · tã / Ghi nhanh 1 chạm | Feeds · sleep · diapers / One-tap logging |
| V9-14 | Nhắc lịch chăm bé / Ăn dặm bữa trưa · 11:30 / Dinh dưỡng | Care reminders / Lunch solids · 11:30 / Nutrition |
| V9-15 | Cả nhà cùng chăm / Bố vừa ghi cữ bú · 2 phút | Caring together / Dad just logged a feed · 2 min |
| V9-16 | M / B / Bà / Ô / Cô (avatars) | M / D / G / G / N (Mom, Dad, Grandma, Grandpa, Nanny). Initials must follow the English names. |
| V9-17 | Mốc phát triển / Biết lẫy · 4 tháng / ✓ Đã ghi | Milestones / Rolls over · 4 months / ✓ Logged |
| V9-18 | Gợi ý theo độ tuổi / Chơi úp bụng 10 phút / 4 tháng | Tips for their age / 10 minutes of tummy time / 4 months |
| V9-19 | Nhật ký lớn khôn / Tuần 18 · 6 ghi chép | Growing-up journal / Week 18 · 6 entries |
| V9-20 | Tự tìm ảnh của bé / 8 ảnh mới đang chờ lưu | Finds your baby's photos / 8 new photos waiting to be saved |
| V9-21 | Thiệp & video kỷ niệm / Tròn 6 tháng / Tạo ngay | Memory cards & videos / 6 months old / Make one |
| V9-22 | Album gia đình riêng tư / Chỉ người được mời | Private family album / Invited people only |
| V9-23 | Xem tất cả tính năng cho năm đầu đời | See every feature for the first year |
| V9-24 | Con 2 tháng hay 6 tháng cũng vậy | Whether your baby is 2 months or 6 |
| V9-25 | Bắt đầu lúc nào cũng kịp. | It's never too late to start. |
| V9-26 | Dù con đã vài tháng tuổi, Child Life vẫn đồng hành chăm sóc, giúp bạn hiểu con và lưu trọn những khoảnh khắc — cả những ngày đã qua. | Even if your baby is already a few months old, Child Life helps with care, helps you understand them and keeps every moment — including the days already gone. |
| V9-27 | Teddy bắt đầu dùng Child Life lúc… | Teddy started Child Life at… |
| V9-28 | Mới sinh / 2 tháng / 6 tháng / 9 tháng | Newborn / 2 months / 6 months / 9 months |
| V9-29 | Ngày sinh / Hôm nay · 6 tháng / 1 tuổi | Birth / Today · 6 months / 1 year |
| V9-30 | Child Life tự sắp xếp lại cho bạn | Child Life sorts it out for you |
| V9-31 | Tìm lại 214 ảnh từ ngày con chào đời / Xếp theo từng tháng · chờ bạn chọn | Found 214 photos since birth / Sorted by month · waiting for you to choose |
| V9-32 | Mốc đã qua: lẫy, cười thành tiếng / Đánh dấu nhanh nếu con đã làm được / 3 mốc | Past milestones: rolling over, laughing out loud / Tick them off if your baby already does them / 3 milestones |
| V9-33 | Gợi ý & nhắc lịch đúng tuổi 6 tháng / Ăn dặm, giấc ngủ, lịch tiêm tiếp theo / Từ hôm nay | Tips & reminders for 6 months / Solids, sleep, next vaccines / From today |
| V9-34 | Đồng hành chăm sóc từ hôm nay / Nhập tuổi con, mọi nhắc nhở, gợi ý ăn dặm và lịch chăm bé tự khớp với giai đoạn hiện tại. | Care support from today / Enter your baby's age and reminders, solids tips and the care schedule match their current stage. |
| V9-35 | Hiểu con ở đúng giai đoạn / Xem con đang ở đâu trong hành trình phát triển và những mốc sắp tới. | Understand the stage they're in / See where your baby is in their development and which milestones come next. |
| V9-36 | Lưu trọn cả những ngày đã qua / Ảnh cũ trong máy được tìm lại và xếp theo tháng, để album của con không thiếu trang nào. | Keep the days already gone / Older photos on your phone are found and sorted by month, so no page of the album is missing. |
| V9-37 | Bắt đầu với tuổi của con | Start with your baby's age |
| V9-38 | Child Life tự tìm ảnh của con, giúp bạn chọn và lưu, tạo thiệp, video, rồi cất vào album riêng để cả nhà cùng xem. (mobile lead) | Child Life finds your baby's photos, helps you pick and save them, makes cards and videos, then keeps them in a private album for the whole family. |
| V9-39 | Tự động tìm ảnh / Ảnh mới của bé / Tự động | Finds photos / Your baby's new photos / Automatic |
| V9-40 | Chọn & lưu / Giữ ảnh đẹp, bỏ ảnh trùng / 1 chạm | Pick & save / Keep the best, drop duplicates / One tap |
| V9-41 | Tạo thiệp, video / Từ mẫu có sẵn / Thiệp / Video | Cards & videos / From ready-made templates / Cards / Video |
| V9-42 | Album & chia sẻ / Riêng cho gia đình, hoặc gửi ra ngoài / Gia đình / Link | Album & sharing / Just for family, or share outside / Family / Link |
| V9-43 | Câu chuyện, nhật ký / Ghi lại lời kể cho con / Nhật ký / “Hôm nay con cười thành tiếng lần đầu…” | Stories & journal / Write their story down / Journal / “Today you laughed out loud for the first time…” |
| V9-44 | Các mốc / Lần đầu của con / Cột mốc / ★ Biết lẫy / ★ Mọc răng đầu | Milestones / Your baby's firsts / Milestones / ★ Rolls over / ★ First tooth |
| V9-45 | Cả nhà cùng xem, bình luận. Chia sẻ ra ngoài bằng link khi bạn muốn. | The whole family can view and comment. Share outside with a link when you want. |
| V9-46 | Bố mẹ, ông bà và người chăm bé cùng một hành trình. | Parents, grandparents and caregivers on one journey. |
| V9-47 | Bàn giao ca chăm: ai cũng biết con vừa ăn, ngủ, cần gì tiếp. | Shift handovers: everyone knows what the baby just ate, how they slept and what comes next. |
| V9-48 | Mỗi người một quyền: người ghi chăm sóc, người chỉ xem ảnh. | Everyone has their own access: some log care, some only see photos. |
| V9-49 | Chỉ những người được mời mới xem được | Only people you invite can see this |
| V9-50 | Bố / Ghi & xem tất cả; Mẹ / Quản lý gia đình; Ông bà / Xem ảnh, bình luận; Cô trông bé / Ghi bú, ngủ, tã | Dad / Logs & sees everything; Mom / Manages the family; Grandparents / See photos, comment; Nanny / Logs feeds, sleep, diapers |
| V9-51 | Bàn giao ca · Mẹ → Cô trông bé / 13:55 | Shift handover · Mom → Nanny / 13:55 |
| V9-52 | Bú 120 ml / lúc 13:00; Đang ngủ / từ 13:30; Nhắc tiếp / Vitamin D 15:00 | Fed 120 ml / at 13:00; Asleep / since 13:30; Next reminder / Vitamin D 15:00 |
| V9-53 | “Bé hơi quấy chiều nay, nhớ vỗ ợ hơi sau bú.” — Mẹ | “A bit fussy this afternoon, remember to burp after feeds.” — Mom |
| V9-54 | Cô trông bé đã nhận bàn giao | Nanny accepted the handover |
| V9-55 | Đang bế con? Ghi nhanh không cần mở app. | Holding your baby? Log it without opening the app. |
| V9-56 | Một chạm trên đồng hồ, widget màn hình chính, nút điều khiển iOS — hoặc chỉ cần nói với Siri. Cả nhà thấy ngay trên điện thoại. | One tap on your watch, a Home Screen widget or an iOS control — or just ask Siri. The family sees it on their phones right away. |
| V9-57 | Một chạm trên đồng hồ, widget, nút điều khiển iOS — hoặc nói với Siri. (mobile) | One tap on your watch, a widget or an iOS control — or ask Siri. |
| V9-58 | Wear OS / Wear OS · Sắp có / Widget / Điều khiển iOS / Siri | Wear OS / Wear OS · Coming soon / Widgets / iOS Controls / Siri |
| V9-59 | WIDGET / Teddy · bú cuối / 2 giờ 15 trước | WIDGET / Teddy · last feed / 2 h 15 m ago |
| V9-60 | ĐIỀU KHIỂN iOS / Bú / Ngủ / Tã | iOS CONTROLS / Feed / Sleep / Diaper |
| V9-61 | Hey Siri… | Hey Siri… |
| V9-62 | “Lumi ghi cữ bú 120 ml.” / Đã ghi bú bình 120 ml lúc 9:00. | “Lumi, log a 120 ml feed.” / Logged a 120 ml bottle at 9:00. |
| V9-63 | “Lần bú cuối của Teddy lúc mấy giờ?” / 2 giờ 15 phút trước, bú bình 120 ml. | “When was Teddy's last feed?” / 2 h 15 m ago, a 120 ml bottle. |
| V9-64 | “Bắt đầu giấc ngủ cho Teddy.” / Đang tính giờ ngủ từ 9:30. | “Start Teddy's sleep.” / Timing sleep since 9:30. |
| V9-65 | Thử hỏi Lumi / · Lumi hiểu nhật ký, mốc và kỷ niệm của con | Try asking Lumi / · Lumi knows your baby's journal, milestones and memories |
| V9-66 | Con 6 tháng có thể ăn gì? / Cháo rây / Bí đỏ nghiền / Chuối / Khoai lang / Thử 1 món mới mỗi 3 ngày. | What can a 6-month-old eat? / Smooth rice porridge / Mashed pumpkin / Banana / Sweet potato / Try one new food every 3 days. |
| V9-67 | Gợi ý hoạt động phù hợp cho hôm nay / Chơi úp bụng 10 phút / Đọc sách tranh 5 phút | Suggest activities for today / Tummy time 10 min / Picture books 5 min |
| V9-68 | Tóm tắt nhật ký tuần này / T2 … CN / Ngủ TB 13 giờ / 42 cữ bú | Summarise this week's journal / Mon … Sun / Avg sleep 13 h / 42 feeds |
| V9-69 | Lần bú cuối lúc mấy giờ? / 2 giờ 15 / trước · bú bình 120 ml · Bố ghi / Cữ tiếp khoảng 11:30 | When was the last feed? / 2 h 15 m / ago · 120 ml bottle · logged by Dad / Next feed around 11:30 |
| V9-70 | Nhắc nhở & cá nhân hoá | Reminders & personalisation |
| V9-71 | Không bỏ lỡ những khoảnh khắc quan trọng. | Never miss the moments that matter. |
| V9-72 | Child Life nhắc đúng lúc, theo tuổi và thói quen của con — từ cữ bú, mốc phát triển, món ăn mới đến những tấm ảnh chưa kịp lưu. | Child Life reminds you at the right time, based on your baby's age and routine — from feeds and milestones to new foods and photos you haven't saved yet. |
| V9-73 | Nhắc đúng lúc, theo tuổi và thói quen của con — từ cữ bú, mốc phát triển, món ăn mới đến ảnh chưa kịp lưu. (mobile) | Timely reminders based on your baby's age and routine — feeds, milestones, new foods and unsaved photos. |
| V9-74 | Chăm sóc / Cữ bú, giấc ngủ, lịch tiêm | Care / Feeds, sleep, vaccines |
| V9-75 | Phát triển / Mốc sắp tới, gợi ý chơi hợp tuổi | Development / Upcoming milestones, play ideas for their age |
| V9-76 | Dinh dưỡng / Món mới, lịch ăn dặm | Nutrition / New foods, solids schedule |
| V9-77 | Kỷ niệm / Ảnh chờ lưu, ngày tròn tháng, sinh nhật | Memories / Photos to save, monthly milestones, birthdays |
| V9-78 | Bạn chọn nhận gì và lúc nào. Không gửi vào giờ ngủ của con. | You choose what you get and when. Nothing is sent during your baby's sleep time. |
| V9-79 | Thứ Bảy, 18 tháng 1 / 9:41 | Saturday, 18 January / 9:41 (locale-formatted) |
| V9-80 | Bạn có 8 ảnh mới của bé / bây giờ / Đang chờ lưu — cùng giữ lại những khoảnh khắc này nhé. / Cùng giữ lại những khoảnh khắc này nhé. | 8 new photos of your baby / now / Waiting to be saved — let's keep these moments. / Let's keep these moments. |
| V9-81 | Teddy đã tròn 1 tuổi! / 8:00 / Tạo thiệp sinh nhật từ ảnh cả năm nào. | Teddy is one today! / 8:00 / Make a birthday card from the whole year's photos. |
| V9-82 | Sắp đến mốc: tự đứng vững / hôm qua / Con 11 tháng — xem 3 trò chơi giúp con tập đứng. / Xem 3 trò chơi giúp con tập đứng. | Milestone coming up: standing alone / yesterday / 11 months — 3 games to help them practise standing. / 3 games to help them practise standing. |
| V9-83 | Gợi ý món cho bữa trưa / Cháo bí đỏ thịt gà hợp với con lúc này. | Lunch idea / Pumpkin and chicken porridge suits your baby right now. |
| V9-84 | +2 nhắc nhở chăm sóc | +2 care reminders |
| V9-85 | Tìm hiểu thêm | Learn more |
| V9-86 | Miễn phí trên iPhone và Android. | Free on iPhone and Android. |
| V9-87 | Tải về trên App Store / Tải nó trên Google Play (badge alt) | Download on the App Store / Get it on Google Play. These are the official English badge texts. |

---

## K. Claims to check against `docs/product/business-map.md`

Everything from spec 34 §K still applies to the unchanged sections. The claims below are new or changed in V9.

1. **Automatic photo finding from the date of birth.** Affected strings:
   - "Tự tìm ảnh của bé · 8 ảnh mới đang chờ lưu"
   - "Tìm lại 214 ảnh từ ngày con chào đời"
   - "Ảnh cũ trong máy được tìm lại và xếp theo tháng, để album của con không thiếu trang nào."
   - Step 1 "Tự động tìm ảnh · Tự động"
   - Mobile Kỷ niệm lead "Child Life tự tìm ảnh của con"
   - 5b "Bạn có 8 ảnh mới của bé"

   Tự lưu is a **free beta, iOS only** (D-066; D-071: "Tự lưu (D-066) … stay iOS-only"). Access is a rollout flag (P-148: off → internal → % → all iOS). Its **first scan looks back 30 days, or to the birth date only if the baby is younger** (`auto-save-plan.md` §7). For a 6-month-old it does *not* find "214 ảnh từ ngày con chào đời". Later scans see only new files. Matching is Apple Vision on the phone and "does not have to be accurate" (P-149). The page presents all of this as available on both platforms (Kết: "Miễn phí trên iPhone và Android."). **Conflict.** Owner to decide: label it iOS / beta, or extend the first-scan window (a product change).
2. **Siri, iOS Controls, widgets (D-045, D-071).** Affected strings:
   - Desktop chips: "✓ Widget", "✓ Điều khiển iOS", "✓ Siri", "✓ Apple Watch", "✓ Wear OS"
   - Title "Ghi nhanh không cần mở app."
   - The Siri dialogue

   Claim by claim:
   - **Widgets:** exist in code (`ios/widget/CareWidgets.swift`, `LockAndLive.swift`, `LogIntents.swift`, App Intents one-tap logging R-100w). D-045 recorded that the interim iOS dev identity had no App Groups, so widget extensions "still wait"; confirm they ship in the release build. Android widgets are planned, not built (D-071, `android-plan.md`).
   - **iOS Controls** (Control Center, iOS 18 `ControlWidget`): **no code and no D/R entry**.
   - **Siri:** no `AppShortcutsProvider` in the app. The only Siri item is Q-052, voice on the *watch*, with the proposal "Both, always with the W08 confirm card" after spike SW-4. "“Lumi ghi cữ bú 120 ml.”" also implies Siri routing into Lumi, which has no entry. Lumi saves only after the parent confirms (`lumiPage` promise "Bạn xác nhận trước khi lưu"; D-088), whereas the Siri reply "Đã ghi…" says it saved directly. Conflict.
   - **Apple Watch:** still unreleased, simulator only (Q-047, P-142, `apple-watch-plan.md`).
   - **Wear OS:** **desktop now shows "✓ Wear OS" as available**, a stronger claim than V8's "Sắp có", and contradicts Q-048 (not in V1). Mobile shows "Wear OS · Sắp có".
   - **Platform reach:** iOS-only features (Controls, Siri, Watch) sit next to "Miễn phí trên iPhone và Android." with no platform note.
3. **Notification categories and per-type toggles (5b).** The app's EN07 settings (D-076 #2, `notification_settings_screen.dart`) group pushes as "Nhắc việc bạn đặt · Gợi ý cho bé · Kỷ niệm & gia đình" (+ Chi tiêu), **not** "Chăm sóc / Phát triển / Dinh dưỡng / Kỷ niệm". Point by point:
   - **Reminders:** they fire **only on the creating device** (R-091), so "Chăm sóc · Cữ bú, giấc ngủ, lịch tiêm" pushes are partial.
   - **Milestone and occasion nudges** (D-068 #9): local at **09:00** (Figma "8:00") for 7 ngày / 1 tháng / 100 ngày / 1 tuổi, "**No setting turns them off**". This contradicts per-type on/off for "Kỷ niệm · … ngày tròn tháng, sinh nhật".
   - **"Sắp đến mốc: tự đứng vững · xem 3 trò chơi":** an upcoming-milestone push has no D/R entry.
   - **"Gợi ý món cho bữa trưa":** solids suggestions are on-device (D-085); a push or digest is not decided (P-172 B1 / G-108 open).
   - **"Không gửi vào giờ ngủ của con":** the app has quiet hours set by the parent (default 22:00–06:00) and P-167 #10's night window, not the baby's actual sleep.
   - **"theo … thói quen của con":** only "Bé dậy chưa?" (P-167 #10) learns from the baby's history.
   - **"Bạn có 8 ảnh mới của bé":** Tự lưu, iOS only (claim 1).
   - **R-120:** family notifications carry no photo and no baby name. Local D-068 notifications include the name ("Có tên bé"), so "Teddy đã tròn 1 tuổi!" is fine.
4. **Family roles and handover.** Point by point:
   - **Roles:** the app has Cùng nuôi (both parents, equal rights), Người chăm sóc and Người thân (R-020/R-021, R-032/R-033). "Mẹ · Quản lý gia đình" versus "Bố · Ghi & xem tất cả" implies different parent roles, which do not exist. R-123's "chủ hồ sơ" is the closest, if the owner wants it.
   - **Comments:** "Ông bà · Xem ảnh, bình luận" and "Cả nhà cùng xem, bình luận" refer to comments, which are **not built**. Relatives get "xem kỷ niệm, thả tim" (R-033). Use "thả tim" or drop "bình luận".
   - **Handover:** the "Bàn giao ca · Mẹ → Cô trông bé" card with "Cô trông bé đã nhận bàn giao" (acceptance) is **open**. Q-085 / P-172 H is phase 3 of Personalization v2 and proposes acceptance by assigned caregivers. The AI handover summaries use credits (D-075 #1; Q-070 open).
   - **Bullet 2** "Bàn giao ca chăm: ai cũng biết con vừa ăn, ngủ, cần gì tiếp." is true for the shared journal (realtime). The "handover" product is not built.
   - **Bullet 3** "người chỉ xem ảnh": consistent with Người thân rights.
   - **"Chỉ những người được mời mới xem được":** consistent with invites. New photos default to Gia đình (D-001), and caregivers do not see Kỷ niệm (R-104).
5. **Memory video and cards (D-068).** Point by point:
   - "Thiệp & video kỷ niệm · Tròn 6 tháng · Tạo ngay": D-068 #9's occasion list is 7 ngày / 1 tháng / 100 ngày / 1 tuổi; confirm a "6 tháng" template exists.
   - "Tạo thiệp sinh nhật từ ảnh cả năm nào.": confirm a first-birthday card template ("Thôi nôi").
   - "Từ mẫu có sẵn" and "Chọn & lưu · Giữ ảnh đẹp, bỏ ảnh trùng · 1 chạm": consistent with D-068 and the Tự lưu review grid (P-146). "1 chạm" is generous: the review is per suggestion.
   - "Album & chia sẻ · Link": story and card links exist (R-163 to R-165); confirm album links.
   - "Lời nhắn cho con" and "Sách năm đầu đời" are gone (V8 claims K-14 and K-15 resolved by removal).
6. **Lumi answers ("Thử hỏi Lumi").** Q-by-Q:
   - **Q1 "Con 6 tháng có thể ăn gì?":** general food guidance with "Thử 1 món mới mỗi 3 ngày." (health advice). P-157: no approved recipes in Lumi; D-085 solids suggestions live in the Ăn dặm module. Content awaits review (D-080 / D-082; D-082's footnote rule applies to Lumi's care answers).
   - **Q2 "Gợi ý hoạt động phù hợp cho hôm nay":** activities come from Nhịp lớn lên content, unreviewed (D-080).
   - **Q3 "Tóm tắt nhật ký tuần này":** weekly summary (D-076 #3, EN09); confirm Lumi answers it (P-167 #5 read cards do not list a week summary).
   - **Q4:** the read card is fine, but "Cữ tiếp khoảng 11:30" is an *estimate*. P-142: "cữ bú tiếp = next feed reminder, never an estimate".
   - **"· Lumi hiểu nhật ký, mốc và kỷ niệm của con":** P-167's read cards cover care, milestones, Ăn dặm and others, but **not Kỷ niệm / photos**.
   - **Credits:** quick reads are 0 credits (D-088). Credits are not shown on the landing (D-081), which matches.
7. **Journey stage pages and "Tìm hiểu thêm".** Stage 2–4 pages exist as "Đang phát triển" templates; Chặng 3 and 4 titles are PROPOSED (`stagePage.titles`). The hero adds roadmap claims: chips "Chặng tiếp theo", "Trong tương lai"; float "Học tập · Hôm nay con học thế nào?", a school-age feature shown beside first-year features; eyebrow "Đồng hành cùng con khôn lớn"; lead "hành trình khôn lớn của con" (Q-039 roadmap and retention).
8. **2b age-based setup.** Point by point:
   - "Nhập tuổi con, **mọi** nhắc nhở, gợi ý ăn dặm và lịch chăm bé tự khớp": vaccine reminders (P-133) and age content do follow the DOB, but care reminders are user-made (R-091). "mọi" overclaims.
   - Onboarding asks a date of birth, not age chips; the selector is illustrative.
   - "Mốc đã qua … Đánh dấu nhanh": the milestone module exists (D-076 #6). D-068 #9 adds "Nhìn lại" nudges for passed occasions.
   - "Ăn dặm" tracking starts at 6 months (D-085 #4), which is consistent.
9. **Ba giá trị rows.**
   - "Bú · ngủ · tã · Ghi nhanh 1 chạm": widget one-tap is real; in-app bottle and diaper take two taps (Q-039 v5).
   - The "Dinh dưỡng" chip and "nhắc lịch … dinh dưỡng": "Dinh dưỡng" was dropped as a module (D-069); nutrition content awaits review (Q-039 v4).
   - "Nhật ký lớn khôn": Nhật ký tab (D-052), which is fine.
10. **Store availability.** The Kết caption becomes "Miễn phí trên iPhone và Android.". R-170 (owner, 2026-10-19) says that before the listings exist, the badges are pictures with "Sắp có trên iPhone và Android.". The hero caption is now hidden, so pre-launch the hero badges have no qualifying line at all. Android release work is still planned (D-071). Official badge artwork must be licensed and used per Apple and Google rules.
11. **"Ba / Bố" naming.** V9 introduces "Bố" in some places ("Bố vừa ghi cữ bú", the "Bố" member pill, "Bố ghi") while keeping "Ba" in others (H2 "Ba vừa ghi, mẹ đã thấy.", the hero float "Ba vừa ghi", Lumi demo). R-022 attributes records as "<label> ghi" with the member's own label, so both are valid labels. The page should pick one for Teddy's family (A-10).

---

## A. Ambiguities / design bugs

1. **The mobile frame is only partly ported**, contrary to the note "Mobile trang chủ: đã port các thay đổi trên". Still V8 or inconsistent on mobile:
   - Hero eyebrow (V8 text).
   - Hero chips and float 2 (V8 text).
   - Album body (V8 "Ông bà ở xa vẫn theo dõi cháu.").
   - Wear OS chip ("Sắp có", versus desktop ✓).
   - Lumi CTA caption removed.
   - 5b note and "+2" removed.
   - 2b points and button missing.
   - Kỷ niệm has a lead on mobile only; 2b has a lead on mobile only.

   **Recommendation:** one content set per section; desktop wins for text, mobile for layout. Exceptions (keep mobile-only short text as `*Short` keys): Kỷ niệm card bodies, the wrist lead and the 5b lead and bodies. Owner to confirm.
2. **The mobile hero H1 and lead are drawn at desktop sizes** (50 / 19 px in a 350 column). Keep V8 mobile 34 / 16.
3. **The desktop hero CTA has no caption**, and mobile likewise. Pre-launch, R-170 needs "Sắp có trên iPhone và Android.", so keep the caption until launch, or get the owner's OK.
4. **Hero link target.** "Bắt đầu cùng con trong năm đầu đời" with a down chevron. In V8 it scrolled to `#giup-gi`; the new wording suggests the Năm đầu đời page (and a right arrow). Proposal: keep the scroll to `#giup-gi`, since the chevron is drawn and Ba giá trị ends with "Xem tất cả tính năng cho năm đầu đời".
5. **Kết caption** "Miễn phí trên iPhone và Android." versus the pre-launch rule (claim 10). Implement it as `launched ? closing.caption : stores.captionSoon`.
6. **The button label differs between desktop and mobile:** "…cho năm đầu đời" versus "…năm đầu đời". Use the desktop one. Two buttons now lead to the same Năm đầu đời page: Ba giá trị and Tiện ích.
7. **Wear OS:** desktop "✓ Wear OS" versus mobile "Wear OS · Sắp có" versus Q-048. The desktop chip layer is misnamed "Chip · Apple Watch" and its colour is a raw hex rather than the token. Likely a copy-paste slip; recommend the mobile treatment or removal.
8. **2b age selector is static.** Interactive behaviour (other ages change the timeline, rows and labels) is not drawn and has no copy for the other ages. Ship it static (`aria-hidden`), or the owner supplies the per-age content.
9. **2b mobile drops the three points and the button.** This is probably a crop: the frame is 822 high with nothing below the profile.
10. **"Ba" versus "Bố"** in one page (claim 11).
11. **The lead "Chăm sóc | Phát triển | Kỷ niệm"** uses pipe characters as separators. Render the words with `aria-hidden` dividers so screen readers do not read "pipe". English needs its own words, not pipes.
12. **Store badges in Kết are hand-built imitations.**
    - The Google prefix "Tải nó trên" is a literal translation of "GET IT ON". Check it against Google's official Vietnamese badge.
    - The Play logo colours are the old 2016 mark, approximated.
    - The badges are rebuilt in Be Vietnam Pro.
    - Mobile stretches each badge to 310 wide, which official artwork does not allow.

    Use official localized artwork (vi and en) at native aspect ratio, centred, about 48 px tall on mobile.
13. **Two badge styles on one page:** the hero keeps the white placeholder badges ("Tải trên"), while Kết has black official-style ones ("Tải về trên" / "Tải nó trên"). Recommend official badges in both, with black on the light hero.
14. **Play glyph as `arrow-right`.** Memory step 3 (and the video mocks since V8) use `Icon/arrow-right` as a play glyph. There is no `play` icon in the map; keep `arrow-right` or add a `play` icon.
15. **5b notification app tile** is a teal `#298C80` square with a feature glyph, not the Child Life app icon. Real iOS notifications show the app icon. Recommend `art.appIcon`, or keep the glyph if the owner wants the category visible.
16. **5b data inconsistencies on one lock screen:**
    - "Thứ Bảy, 18 tháng 1" with "Teddy đã tròn 1 tuổi!", next to "Con 11 tháng — xem 3 trò chơi…".
    - Kỷ niệm's card says "100 ngày · Teddy · 18.01.2027".
    - Hero and 2b say Teddy is 6 months.

    Ages across the page do not agree. Desktop times "8:00" / "hôm qua" versus mobile "bây giờ" ×4.
17. **The 5b toggles are fake controls.** They must not be focusable (`aria-hidden`), or users will try them.
18. **Lumi Q4 "Bố ghi"** versus the hero "Ba vừa ghi"; Q4 "Cữ tiếp khoảng 11:30" is an estimate (claim 6).
19. **Kết on other pages.** `Closing` is shared; the V9 Năm đầu đời (`785:9895`) and Chặng 2 (`785:10856`) Kết frames must be checked before the shared component changes.
20. **Mobile Lumi caption** "Ví dụ minh hoạ…" is gone. It is the only disclaimer that the Lumi mocks are illustrative; keep it.
21. **Heights grow by about 2,400 px on desktop and 4,200 px on mobile.** The mobile Ba giá trị alone is 1,360 because full cards replace rows. Consider keeping the V8 mobile rows with only the new copy if page length matters; owner call.
22. **Overflow fixes from V8 are no longer needed in the new parts:** the Kỷ niệm strip (1248), Thử hỏi Lumi (1248) and 2b panel are exact. The Tiện ích (1272) and Hành trình (1260) overflows remain as in spec 34 and are already fluid in code.
23. **No tablet frame.** New grids need intermediate layouts between 390 and 1440, using the existing 1120 px breakpoint. Proposals:
    - Memory strip: 3 × 2.
    - Thử hỏi Lumi: 2 × 2.
    - 2b panel: stacked.
    - 5b: stacked, with the phone below the copy.
    - Family illustration: the mobile flow layout below 1120.
