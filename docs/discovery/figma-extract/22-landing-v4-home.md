# 22 — Landing v4 home page (Sức khoẻ, Tiện ích, Theo cách của bạn)

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only). Extracted 2026-10-12. Same conventions as `14-landing-v3-home.md`: token names from `07-foundations-components-motion.md` / `packages/design-tokens/dist/tokens.css`, non-token values marked **(raw)**, every visible string copied **verbatim from `get_design_context`** (layer names are stale — e.g. the Chi tiêu body layer is named "Ghi nhanh sữa, tã, tiêm chủng,…" but renders "Mọi khoản chi cho con ở một chỗ…").

> File number: `16-v1-improvement.md` already exists; this doc shares the number because it continues the landing series 14 → 15 → 16. Rename if a strict sequence matters.

- Desktop frame `459:3538` "Landing v4 · Desktop" — 1440 × 7248.2. **Desktop only — there is no v4 mobile frame.** §8 is a mobile *proposal*, not a design.
- v4 = v3 home (`358:2901`, spec `14`) **plus three new sections** inserted between Năm đầu đời and Lớn lên cùng con, a 5-link nav and two more FAQ questions. Everything else is unchanged (verified, §1).
- As before: no prototype links, no motion, no hover/focus states, no tablet frame, no dark page. Light, static state. Page background `cloud` #F6FCFB; every section is transparent over it.

Screenshots (not committed, desktop 1:1 at 1440 wide): `scratchpad/v4/d-nav.png`, `d-suc-khoe.png`, `d-tien-ich.png`, `d-theo-cach.png`, `d-hoi-dap.png`, plus `d-full-overview.png` (whole frame, 318 × 1600 thumbnail).

---

## 0. Global

### 0.1 Section order

| # | Section | v4 node | h (y) | v3 node | Status | Proposed id |
|---|---|---|---|---|---|---|
| 1 | Nav | 459:3539 | 87 (0) | 358:2902 | **changed** — 5 links (§2) | — |
| 2 | Hero | 459:3551 | 644 (87) | 358:2923 | identical | `#gioi-thieu` |
| 3 | Hành trình | 459:3623 | 806 (731) | 359:2592 | identical | `#hanh-trinh` |
| 4 | Năm đầu đời | 459:3724 | 1678 (1537) | 360:2568 | identical (family strip `#gia-dinh` inside) | `#nam-dau-doi` |
| 5 | **Sức khoẻ** | 459:4166 | 680 (3215) | — | **new** (§3) | `#suc-khoe` |
| 6 | **Tiện ích cho ba mẹ** | 459:4168 | 816 (3895) | — | **new** (§4) | `#tien-ich` |
| 7 | **Theo cách của bạn** | 459:4342 | 620 (4711) | — | **new** (§5) | `#theo-cach-cua-ban` |
| 8 | Lớn lên cùng con | 459:3914 | 466 (5331) | 360:2693 | identical | `#lon-len` |
| 9 | CTA | 459:3937 | 367 (5797) | 360:2788 | identical | `#tai-app` |
| 10 | Hỏi đáp | 459:3959 | **900** (6164) | 360:2810 (740) | **changed** — 8 questions (§6) | `#hoi-dap` |
| 11 | Footer | 459:3991 | 184.2 (7064) | 360:2838 | identical | — |

Page height 4972.2 → 7248.2 (+2116 for the three sections, +160 for two FAQ rows).

Vertical rhythm around the new block: Năm đầu đời ends with its 64 bottom padding → Sức khoẻ `96 / 64` → Tiện ích `72 / 72` → Theo cách `96 / 64` → Lớn lên (24 top). Heights are hug-content except the Tiện ích cards (fixed 440, see §4).

### 0.2 Text styles on the new sections
All already exist on the page (`14` §0.2, `12` §0.5) — **no new text style**:

| Use | Font | Colour |
|---|---|---|
| Eyebrow pill | SemiBold 13 / normal, `padding: 6px 12px; radius 999` | `.eyebrow--mint` (Sức khoẻ, Tiện ích); `.eyebrow--sun-ink` = `sunshine-soft` / `ink` (Theo cách) — both classes exist |
| H2 | Bold 44 / 1.18, tracking 0 (`.h2.h2--flat`) | `ink` |
| Lead | Medium 18 / 1.55 | `ink-muted` |
| Compact bullet | SemiBold 16 / normal title + Medium 14 / 1.5 sub, gap 3; icon box 36 (`p 9`, `r 12`) + icon 18 (stroke 1.35); row gap 16; list gap 18 | `ink` / `ink-muted` — **= `CompactBullets`** (`components/Bullets.tsx`, `.bullets--compact`) |
| Card title (Tiện ích) | Bold 22 / normal | `ink` |
| Card body (Tiện ích) | Medium 15 / 1.5 | `ink-muted` |
| Footnote (Sức khoẻ) | Medium 13 / normal | `ink-muted` |

### 0.3 Shadows
Only `shadow-card` (the floating app cards in the Sức khoẻ and Theo cách panels; get_design_context prints it as `drop-shadow(0 8 12 / 0 1 1)`, the style itself is `shadow-card` = `0 1 2 #173D440F, 0 8 24 #173D4414`). Tiện ích cards and their inner "app" cards are flat.

### 0.4 Icons (app set `apps/mobile/assets/icons/`, stroke 1.8 at 24, scaled)
Used in the new sections: check, clock, ruler, feed, alert, grid, cake, family, sliders, sleep.

**Missing from the landing `Icon` map (`components/primitives.tsx`): `grid` and `ruler`** — both exist in `apps/mobile/assets/icons/` (`grid.svg`, `ruler.svg`, `currentColor` strokes) → add two `?raw` imports. Everything else (alert, cake, check, clock, family, feed, sleep, sliders) is already mapped.

---

## 1. Unchanged sections (verified)

Method: metadata trees of v3 `358:2901` and v4 `459:3538` normalised (ids stripped, coords rounded) and diffed per section; then each section rendered with `get_screenshot` at 1:1 in both frames and **pixel-diffed** (BMP compare, threshold 24/255): Hero, Hành trình, Năm đầu đời, Lớn lên cùng con and Footer have **0 differing rows**. Hero copy and CTA were also re-read with `get_design_context` — texts identical to `14` §2 / §6.

→ `JourneyHero.tsx`, `Chapters.tsx`, `FirstYear.tsx`, `GrowUp.tsx`, `Cta.tsx` (title `journey.ctaTitle` "Bắt đầu hành trình cùng con" / "ngay hôm nay."), footer: **no change**.

---

## 2. Nav (459:3539, 1440 × 87) — changed

Geometry/styles identical to v3 (`padding: 22px 96px`, links gap 36 Medium 15 / normal `ink-muted`, 40 spacer, CTA pill `ink`/`surface` SemiBold 15 **"Tải miễn phí"**). The links row grows 401 → **501** wide and starts at x **670** (was 770); the flex spacer shrinks 498 → 398.

Links, verbatim, in order: **"Hành trình" · "Năm đầu đời" · "Sức khoẻ" · "Tiện ích" · "Hỏi đáp"**.
- Removed: **"Gia đình"** (`nav.links.family`).
- Added: **"Sức khoẻ"** (spelled *khoẻ*, old-style tone placement — same in the section eyebrow) and **"Tiện ích"**.
- The hidden layer "Hỏi đáp" (`459:3547`, hidden) is still there — ignore.

Targets: see §7.

---

## 3. Sức khoẻ (459:4166, 1440 × 680) — NEW

`display:flex; flex-direction:column; align-items:flex-start; padding: 96px 96px 64px;` → **Row** 459:4167 `display:flex; gap:96px; align-items:center;` (1216 × 520) = **Panel (left) 600 × 520** + **Copy (right) 520 × 492** (copy top at y 14 in the row).

The row is **1216 wide inside a 1248 content box** and left-aligned (right margin 128 vs left 96). Recommend the existing `.split.split--visual-first` with the visual capped at 600 (`flex: 0 1 600px`) and copy `flex:1` (= 552) with the Figma text widths as `max-width` (H2 520, lead/footnote 480) — this fills 1248 and keeps the wraps. (v3 had the opposite problem — 1296 > 1248, `12` §8.1.)

### 3.1 Panel 459:4001 (600 × 520)
`background: mint-soft; border-radius: 40px; overflow: hidden; position: relative;` (= `.panel--mint` shell). Two absolute app cards, decorative (`aria-hidden`, the copy carries the meaning):

**A. Vaccination card "Lịch tiêm"** 459:4002 at **(40, 40)**, **440** wide, hug height 376:
`background: surface; border-radius: 22px; padding: 20px 22px; display:flex; flex-direction:column; gap:12px; shadow-card;`

1. Title Bold 16 / normal `ink`, nowrap: **"Lịch tiêm chủng · Teddy"**
2. Header row (380 × 16): empty label cell 104 × 14, then 6 column heads, each 46 wide × 16, centred, SemiBold **11** / normal `ink-muted`: **"Sơ sinh"**, **"2 th"**, **"3 th"**, **"4 th"**, **"6 th"**, **"9 th"**.
3. Six vaccine rows (380 × 28, `align-items:center`): label cell 104 × 20, SemiBold **13** / normal `ink`; then 6 cells 46 × 28 with the mark centred:

   | Row label | Sơ sinh | 2 th | 3 th | 4 th | 6 th | 9 th |
   |---|---|---|---|---|---|---|
   | "Viêm gan B" | ✔ | · | · | · | · | · |
   | "Lao" | ✔ | · | · | · | · | · |
   | "6 trong 1" | · | ✔ | ✔ | ○ | · | · |
   | "Phế cầu" | · | ✔ | ✔ | · | · | · |
   | "Rota" | · | ✔ | ✔ | · | · | · |
   | "Sởi" | · | · | · | · | · | ○ |

   - ✔ **done**: 18 circle `mint-deep` (`padding: 3px; border-radius: 999px`) with check **12** white (stroke 0.9).
   - ○ **due / next**: circle 16 + 2 px ring (outer 18): fill `sunshine-soft` #FFF4D6, stroke `sunshine` #FFD166 2 px.
   - · **not yet / not applicable**: dot 6 × 6 `separator` #DCE8E7.
4. Footer pill "next" 459:4130 (277 × 36, left-aligned, hug): `background: sunshine-soft; border-radius: 14px; padding: 10px 12px; display:flex; gap:8px; align-items:center;` clock **16** (`ink`, 1.2) + SemiBold 13 / normal `ink` nowrap: **"Mũi tiếp theo: 6 trong 1 · lần 3 · 17/11"**

   Implementation: a real `<table>` is semantically right but the card is decorative — a CSS grid `grid-template-columns: 104px repeat(6, 46px)` with `aria-hidden` is enough. Marks are pure CSS (no SVG needed).

**B. Growth card** 459:4131 at **(330, 370)**, 240 × 113 — overlaps card A's bottom-right (A ends at y 416, x 480) and is clipped by nothing (ends 483 < 520):
`background: surface; border-radius: 22px; padding: 16px 18px; display:flex; flex-direction:column; gap:6px; align-items:flex-start; shadow-card;`
1. Medium 13 / normal `ink-muted` **"Cân nặng"**
2. Bold **24** / normal `ink` **"7,8 kg"** (Vietnamese decimal comma)
3. `Chip size="sm" tint="mint"` (`mint-soft` / `mint-text`, `padding: 4px 10px`, SemiBold 12): **"Trong khoảng chuẩn WHO"**

   Close to the v2/v3 float cards (`14` §2 "Float card", radius 18) but radius 22 and a column layout — new small class.

### 3.2 Copy 459:4163 (520 wide)
`display:flex; flex-direction:column; gap:36px; align-items:flex-start;`
1. **Head** (`gap:16px`):
   - Eyebrow `.eyebrow--mint`: **"Sức khoẻ của con"**
   - H2 Bold 44 / 1.18 `ink`, 520 wide (2 lines): **"Lịch tiêm và tăng trưởng, nhìn là hiểu."**
   - Lead Medium 18 / 1.55 `ink-muted`, 480 wide (2 lines): **"Biết con đã tiêm gì, sắp tiêm gì, lớn lên ra sao — không cần lục sổ."** (em dash)
2. **Bullets** = `CompactBullets` (gap 18):

   | Icon box (tint) | Icon (stroke colour) | Title | Sub |
   |---|---|---|---|
   | `mint-soft` (`mint`) | check (`mint-text` #06716D) | "Lịch tiêm theo tháng tuổi" | "Đánh dấu mũi đã tiêm, nhắc trước ngày tiêm cho cả nhà." |
   | `care-growth-soft` (`growth`) | **ruler** (`care-growth-ink` #9A4A14) | "Cân nặng, chiều dài theo chuẩn WHO" | "Biểu đồ dễ đọc, không chấm điểm hay so sánh con." |
   | `care-bottle-soft` (`bottle`) | feed (`care-bottle-ink` #1D5F99) | "Dinh dưỡng theo giai đoạn" | "Lượng sữa tham khảo và nhóm chất cần chú ý theo tuổi." |

   `CompactBulletItem` requires `subShort` (mobile wording) — no mobile design; reuse `sub` or draft shorter ones (§8).
3. **Footnote** Medium 13 / normal `ink-muted`, 480 wide (2 lines): **"Nội dung tham khảo, được chuyên môn rà soát. Lịch tiêm cụ thể theo hướng dẫn của cơ sở y tế."**

---

## 4. Tiện ích cho ba mẹ (459:4168, 1440 × 816) — NEW

`display:flex; flex-direction:column; align-items:center; gap:40px; padding: 72px 96px;`

### 4.1 Head 459:4169 (900 wide, centred, `gap:16px`)
- Eyebrow `.eyebrow--mint`: **"Tiện ích cho ba mẹ"**
- H2 Bold 44 / 1.18 `ink`, centred, 900 wide, **hard line break** (two `<p>` in Figma): **"Những thứ nhỏ giúp"** / **"ngày làm cha mẹ nhẹ hơn."** → store as a 2-item array like `hero.title`.
- Lead Medium 18 / 1.55 `ink-muted`, centred, 600 wide (1 line): **"Có sẵn trong tab Tiện ích, mở ra là dùng được."**

### 4.2 Cards 459:4174
Row `display:flex; gap:20px; align-items:flex-start;` → 3 cards **396 × 440** (row 1228, centred → x 106 in the 1248 box). Recommend `flex: 1` (≈ 402.7 at 1248) — the 6 px difference is invisible.

Card: `border-radius: 28px; padding: 28px; display:flex; flex-direction:column; gap:12px; align-items:flex-start; height: 440px;` no border, no shadow.
1. Icon box: `background: surface; padding: 8px; border-radius: 12px;` + icon **20** (stroke 1.5) → `IconBox tint="white"` with an ink override (`ink--*` classes exist for mint; growth ink needs a class).
2. Title Bold 22 / normal `ink`, nowrap.
3. Body Medium 15 / 1.5 `ink-muted`, 340 wide (3 lines).
4. Spacer `flex: 1` → the visual sits at the bottom.
5. Visual, 340 wide.

| Card | Node | Bg | Icon (colour) | Title | Body | Visual |
|---|---|---|---|---|---|---|
| 1 Sơ cứu | 459:4176 | `peach-soft` | **alert** (`ink`) | **"Sơ cứu trẻ em"** | **"25 tình huống thường gặp, từng bước có hình minh hoạ, đọc to hướng dẫn. Dùng được cả khi không có mạng."** | Photo 340 × 200 (§4.3) |
| 2 Chi tiêu | 459:4205 | `care-growth-soft` | **grid** (`care-growth-ink`) | **"Sổ chi tiêu chung cho bé"** | **"Mọi khoản chi cho con ở một chỗ. Ba và mẹ cùng ghi, cùng xem một sổ như nhau — biết con cần gì, cả nhà đã lo đến đâu."** | Spending card (§4.4) |
| 3 Gia đình | 459:4240 | `mint-soft` | **family** (`mint-text`) | **"Gia đình & chia sẻ"** | **"Mời ông bà, người chăm cùng theo dõi bé. Mỗi người một quyền riêng, ba mẹ quyết định ai thấy gì."** | Member list (§4.5) |

Card heights: Figma fixes 440; card 2's content is 445 tall (visual 207 + paddings) so it already overflows by ~5 px in Figma (the render shows a 24 px bottom padding instead of 28). Use `min-height: 440px` + `align-items: stretch` on the row so English / wrapping never overflows (same advice as `14` §3).

### 4.3 Card 1 visual — first-aid illustration 459:4175
`width: 340px; height: 200px; border-radius: 20px; overflow:hidden;` image `object-fit: cover` (source 3:2 → crops ~13 px top and bottom at 340 × 200).
- The Figma raster (1536 × 1024 PNG, 1.77 MB) is **byte-identical** to `content/first-aid/source/illustrations/quan-bang.png` — the app's own first-aid art (pack topic with `"hero": "quan-bang"`, `content/first-aid/pack.seed.json:1859`; a child having a forearm bandaged, green check badge).
- Added **`apps/landing/src/assets/figma/first-aid-bandage.webp`** = copy of the app's shipped derivative `content/first-aid/images/quan-bang.webp` (1200 × 800, 36.6 KB) — plenty for 340 × 200 at 2×. Do not ship the 1.77 MB PNG. Alt text: decorative next to the card text (`alt=""`), or a short description if the image is the only visual cue.

### 4.4 Card 2 visual — spending summary 463:3724 (340 × 207)
App-style card: `background: surface; border-radius: 20px; padding: 16px 18px; display:flex; flex-direction:column; gap:12px; align-items:flex-start;` no shadow.
1. Header row `gap:8px; align-items:center;`: circle `care-growth-soft` (`padding: 6px; border-radius: 999px`) with **cake 16** (`care-growth-ink`, 1.2) + SemiBold 13 / normal `ink-muted` **"Chi cho Teddy · tháng này"**
2. Total Bold **26** / normal `ink`: **"4.215.000 ₫"** (dot thousands separator, U+20AB ₫ after a space)
3. Split bar (303 × 10): `display:flex; gap:3px; border-radius: 6px; overflow:hidden;` segment 1 `mint-deep` 165 wide, segment 2 `peach` #FFA58D 135 wide (both 10 tall). Proportions = 2.320.000 : 1.895.000 ≈ 55 : 45 → implement as `flex: 2320` / `flex: 1895`.
4. Legend row `gap:14px`: two items `gap:6px; align-items:center;` dot 8 (`mint-deep` / `peach`) + Medium 12 `ink-muted` label + SemiBold 12 `ink` amount:
   - **"Mẹ ghi"** **"2.320.000 ₫"**
   - **"Ba ghi"** **"1.895.000 ₫"**
5. Divider 300 × 1 `separator` (**(raw)** 300, the content box is 304 — use `width:100%`).
6. Footer row `gap:8px; align-items:center;`: two overlapping avatars 28 (`border: 2px solid surface; border-radius: 999px;` first `margin-right: -8px`), Bold 12: **"M"** on `card-peach` / `care-bottle-ink`, **"B"** on `mint-soft` / `care-bottle-ink` + SemiBold 13 `ink` **"Ba và mẹ cùng xem như nhau"**.
   - Reuse `Initials` (`kit.tsx`) — its tints are coral (= `card-peach`/`care-bottle-ink` ✔) then sleep; this needs coral then **mint-soft with `care-bottle-ink` letters** (raw pairing — the kit's mint tint uses `mint-text`). Add a `tints` prop or accept `mint`.

### 4.5 Card 3 visual — member list 459:4215 (340 × 200)
`display:flex; flex-direction:column; gap:8px;` four rows, each `background: surface; border-radius: 14px; padding: 8px 12px; display:flex; gap:10px; align-items:center; width:340px;` (44 tall): avatar 28 circle `card-peach` with Bold 12 `care-bottle-ink` initial (no border) + SemiBold 14 / normal `ink` name + spacer `flex:1` + Medium 12 / normal `ink-muted` role, right-aligned.

| Initial | Name | Role label |
|---|---|---|
| M | "Mẹ" | "Toàn quyền" |
| B | "Ba" | "Toàn quyền" |
| L | "Cô Lan" | "Ghi chăm sóc" |
| B | "Bà ngoại" | "Xem kỷ niệm" |

All four avatars use the same `card-peach` tint (unlike `Initials`, which rotates tints). The initials are content-derived — keep them in the copy file next to the names.

---

## 5. Theo cách của bạn (459:4342, 1440 × 620) — NEW

`padding: 96px 96px 64px;` Row 459:4343 `display:flex; gap:96px; align-items:center;` (1216 × 460) = **Copy (left) 520 × 424** (top y 18) + **Panel (right) 600 × 460**. Same 1216-in-1248 note as §3 → `.split` with visual `flex: 0 1 600px`, copy `flex:1`, text max-widths 520 / 480.

### 5.1 Copy 459:4340 (`column; gap:36px`)
1. Head (`gap:16px`):
   - Eyebrow **`.eyebrow--sun-ink`** (`sunshine-soft` / `ink`): **"Theo cách của bạn"**
   - H2 Bold 44 / 1.18 `ink`, 520 wide (2 lines): **"Ứng dụng của nhà bạn, theo nhịp của nhà bạn."**
   - Lead Medium 18 / 1.55 `ink-muted`, 480 wide (2 lines, "dùng." wraps alone): **"Chỉ hiện những gì bạn cần. Bớt đi những gì bạn không dùng."**
2. Bullets = `CompactBullets`:

   | Icon box (tint) | Icon (stroke) | Title | Sub |
   |---|---|---|---|
   | `sunshine-soft` (`sun`) | sliders (`ink`; its two knobs are filled white) | "Bật, tắt và sắp xếp màn hình Hôm nay" | "Bú bình hay bú mẹ, có hút sữa hay không — tuỳ nhà bạn." |
   | `care-sleep-soft` (`sleep`) | sleep (`care-sleep-ink` #4447A8) | "Chế độ đêm" | "Màn hình tối, chữ to, ghi nhanh lúc 3 giờ sáng." |
   | `care-growth-soft` (`growth`) | **grid** (`care-growth-ink`) | "Danh mục chi tiêu riêng" | "Thêm, sửa, ẩn danh mục cho đúng cách nhà bạn chi." |

### 5.2 Panel 459:4250 (600 × 460)
`background: sunshine-soft; border-radius: 40px; overflow:hidden; position:relative;` (a `.panel--sun-soft` was proposed in `12` §3 for Nhắc nhở — reuse it if it exists, else add). Decorative, `aria-hidden`.

**A. "Tuỳ chỉnh" card** 459:4251 at **(40, 40)**, **420** wide, hug 283:
`background: surface; border-radius: 22px; padding: 20px 22px; display:flex; flex-direction:column; gap:14px; shadow-card;`
1. Bold **18** / normal `ink`: **"Tuỳ chỉnh Hôm nay"**
2. Three rows (376 × 36) `display:flex; gap:12px; align-items:center;`:
   - Drag handle 14 × 12: three bars 14 × 2 `control-border` #7E959A, `gap: 3px` (column).
   - Text col `flex:1; gap:2px`, nowrap: SemiBold **15** `ink` title + Medium **12** `ink-muted` sub.
   - Toggle **43.35 × 26.35** = the app Toggle 51 × 31 at **×0.85** (`Toggle scale={0.85}`).

   | Title | Sub | Toggle |
   |---|---|---|
   | "Ô theo dõi nhanh" | "Bú, ngủ, tã, hút sữa, tăng trưởng" | on (`mint-deep` track, knob right) |
   | "Nhắc nhở sắp tới" | "3 nhắc đang bật" | on |
   | "Nhịp trong ngày" | "Biểu đồ 24 giờ" | **off** — `separator` #DCE8E7 track, knob left |

   `kit.tsx` `Toggle` is "always on" → add an `on={false}` variant (`background: separator`, knob `left` instead of `right`). Knob shadow in Figma: `0 1.7 3.4 rgba(0,0,0,.15)` at this scale = the existing `0 2s 4s` rule.
3. Chips row `display:flex; flex-wrap:wrap; gap:6px;` (2 lines: 4 + 1): each `background: mint-soft; padding: 5px 10px; border-radius: 999px; gap:6px;` check **14** (`mint-text`, 1.05) + SemiBold 12 `mint-text`: **"Bú bình"**, **"Bú mẹ"**, **"Ngủ"**, **"Thay tã"**, **"Hút sữa"**. → `Chip tint="mint" icon="check"`; padding 5/10 **(raw)** sits between `chip--sm` (4/10) and the default (6/12) — use `sm` + 1 px or a modifier.

**B. Night chip** 459:4307 at **(40, 322)** (overlaps the card's bottom edge by 1 px — renders as touching), hug 192 × 38: `background: ink; border-radius: 999px; padding: 10px 16px; display:flex; gap:6px; align-items:center;` no shadow; sleep **14** (white, 1.05) + SemiBold **14** white **"Chế độ đêm dịu mắt"**. Close to `Chip` (`size="lg"` is 13 px) — new dark variant (`tint--ink`?).

The panel content ends at y ≈ 360 of 460: the bottom ~100 px of the panel is empty in Figma (see §10).

---

## 6. Hỏi đáp (459:3959, 1440 × 900) — changed

Styles, left column and paddings (`48px 96px 112px`) are unchanged from v3 (`14` §7): **"Câu hỏi thường gặp"** / **"Còn điều gì băn khoăn? Cứ nhắn cho chúng tôi nhé."** The list grows 580 → **740** (two more closed items, 68 tall + 12 gap each).

All 8 items, verbatim (questions and the two open answers re-read with `get_design_context`):

| # | State | Question | Answer in Figma | vi.ts |
|---|---|---|---|---|
| 1 | open | "Child Life là gì?" | "Hệ sinh thái giúp cha mẹ chăm sóc, thấu hiểu và đồng hành cùng con qua từng chặng lớn lên. Ứng dụng hiện tập trung vào năm đầu đời của con." | `home.faq.items[0]` — unchanged |
| 2 | open | "Child Life dành cho bé mấy tuổi?" | "Từ ngày con chào đời. Năm đầu, app giúp cả nhà chăm con mỗi ngày; những chặng tiếp theo sẽ cùng con lớn lên đến tuổi trưởng thành." | `[1]` — unchanged |
| 3 | closed | "Khi con lớn, ảnh và hồ sơ của con có còn không?" | none | `[2]` — unchanged (PROPOSED answer) |
| 4 | closed | "Có mất phí không?" | none | `[3]` — unchanged (PROPOSED) |
| 5 | closed | "Ai được xem ảnh và thông tin của con?" | none | `[4]` — unchanged (PROPOSED) |
| 6 | closed | "Nội dung gợi ý trong app do ai soạn?" | none | `[5]` — unchanged (PROPOSED) |
| 7 | closed | **"Sơ cứu trong app có thay thế bác sĩ không?"** | none | **new** `[6]` — answer to draft (§9) |
| 8 | closed | **"Ai xem được chi tiêu của gia đình?"** | none | **new** `[7]` — answer to draft (§9) |

(Layer names of items 5–8 are the stale "Có cần ghi đủ mỗi ngày không?" — ignore.) `Faq.tsx` needs no change; only `home.faq.items` grows (vi + en, D-012).

---

## 7. Section ids and nav targets (proposal — Figma defines none)

| Nav link (vi.ts key) | Home | Stage pages (Chặng 1–4) |
|---|---|---|
| "Hành trình" (`nav.links.journey`) | `#hanh-trinh` | `${homePath}#hanh-trinh` (as today) |
| "Năm đầu đời" (`nav.links.firstYear`) | `#nam-dau-doi` | Chặng 1 page (as today) |
| **"Sức khoẻ"** (new `nav.links.health`) | `#suc-khoe` | `${homePath}#suc-khoe` |
| **"Tiện ích"** (new `nav.links.utilities`) | `#tien-ich` | `${homePath}#tien-ich` |
| "Hỏi đáp" (`nav.links.faq`) | `#hoi-dap` | `${homePath}#hoi-dap` on stages 2–4; Chặng 1 keeps its own `#hoi-dap` |
| "Tải miễn phí" | `#tai-app` | unchanged |

- New section ids: `suc-khoe`, `tien-ich`, `theo-cach-cua-ban` (no nav link; available for deep links). ASCII, matching the existing `hanh-trinh` / `nam-dau-doi` style.
- **"Gia đình" leaves the nav.** `nav.links.family` / the `#gia-dinh` link in `Chrome.tsx` go; keep the `id="gia-dinh"` on the Năm đầu đời family strip (and on Cocare on Chặng 1) so old deep links still land. Alternative: point a future family link at the "Gia đình & chia sẻ" card (`#tien-ich`).
- `Chrome.tsx` `links` becomes 5 items; the scroll-spy keys follow the ids above. Width check: 5 links = 501 px; at the 1120 px desktop breakpoint the nav needs 176 (lockup) + 501 + 40 + 133 = 850 ≤ 928 available — fits; English labels must stay short ("Health", "Toolkit"/"Tools" rather than "Parent utilities").
- Existing id clash to avoid: Chặng 1 already has `#so-cap-cuu` (FirstAid section) — the home card does not need an id.

---

## 8. Mobile — PROPOSAL (no v4 mobile frame exists)

Derived from the v3 mobile frame `362:3398` (`14` §3–§5 mobile) and the v3 split-section mobile rules (`12` §2–§5 mobile: "Head → Panel → Bullets", panels **re-composed in flow** at readable sizes, not uniformly scaled). Breakpoint as today (`< 1120`). Needs design sign-off.

Common: section `padding: 48px 20px` (v3 feature sections) — `40px 20px` is also used on the v3 home; pick one for all three. Head `gap:12px`, left-aligned; eyebrow unchanged; H2 Bold **30 / 1.2** (Năm đầu đời mobile size); lead Medium 16 / 1.55; bullets `CompactBullets` (mobile gap 16 already in CSS).

**Sức khoẻ (mobile):** Head → Panel → Bullets → Footnote.
- Panel in flow: `background: mint-soft; border-radius: 32px; padding: 20px 16px; display:flex; flex-direction:column; gap:12px;` (335 wide).
- Vaccine card full width (303): `padding: 16px; radius 20; shadow-card`. Six 46-px columns do not fit (inner 271): **show 4 columns** ("Sơ sinh", "2 th", "3 th", "4 th") and 5 rows (drop "Sởi", whose only mark is at 9 th) → `grid-template-columns: 95px repeat(4, 44px)`; keep 11 / 13 px text and the 18-px marks; keep the next-dose pill (it may wrap to 2 lines).
- Growth card in flow below (no overlap), `align-self:flex-start`, same content, no shadow (v3 mobile panels drop most shadows).
- Footnote Medium 12 / 1.5.

**Tiện ích (mobile):** Head (H2 as one wrapping line, not the desktop break) → 3 cards stacked, `gap:16px`.
- Card full width (335): `border-radius: 24px; padding: 20px; gap: 10px;` **height auto** (no fixed 440, no spacer; 8 px extra gap before the visual). Title Bold 20, body Medium 14 / 1.5 (same text — or `bodyShort` if the owner wants shorter).
- Visuals full width (295): illustration 295 × 174 (same 1.7 ratio, radius 16); spending card unchanged structure (bar segments `flex`, legend may wrap to 2 lines at 263 inner width — allow `flex-wrap`); member rows unchanged (they fit at 295).

**Theo cách của bạn (mobile):** Head → Panel → Bullets.
- Panel in flow: `background: sunshine-soft; border-radius: 32px; padding: 20px 16px; display:flex; flex-direction:column; gap:12px; align-items:flex-start;` — this also removes the empty bottom area of the desktop panel.
- Card full width (303): `padding: 16px 18px; radius 20;` title Bold 16; row titles SemiBold 14, subs Medium 12 (first sub "Bú, ngủ, tã, hút sữa, tăng trưởng" ≈ 190 px fits in the ≈ 180-px text column only just — allow ellipsis or wrap); toggles stay ×0.85; chips wrap.
- Night chip in flow under the card (`align-self:flex-start`), unchanged.

**Nav mobile:** unchanged (logo + "Tải app" pill, no links). **FAQ mobile:** 8 items; the v3 mobile frame shortened every question — the two new ones are already short, use them as is (or one text per item for both breakpoints, as recommended in `14` §7).

---

## 9. Copy keys (vi.ts) — what changes

| Area | Key (proposed) | Change |
|---|---|---|
| Nav | `nav.links.health` = "Sức khoẻ", `nav.links.utilities` = "Tiện ích" | **new**; `nav.links.family` ("Gia đình") **removed** from the nav (delete the key if unused elsewhere) |
| Sức khoẻ | `home.health.{eyebrow,title,lead,bullets[3]{title,sub,subShort},footnote}` and `home.health.mock.{title,columns[6],rows[6],next,growthLabel,growthValue,growthChip}` | **new** — all strings in §3 |
| Tiện ích | `home.utilities.{eyebrow,title[2],lead,cards[3]{title,body}}`, `home.utilities.mock.spending.{header,total,me,meAmount,dad,dadAmount,together}`, `home.utilities.mock.members[4]{initial,name,role}`, `home.utilities.imageAlt` | **new** — §4 |
| Theo cách | `home.yourWay.{eyebrow,title,lead,bullets[3]}`, `home.yourWay.mock.{title,rows[3]{title,sub,on},chips[5],night}` | **new** — §5 |
| FAQ | `home.faq.items[6]` "Sơ cứu trong app có thay thế bác sĩ không?", `[7]` "Ai xem được chi tiêu của gia đình?" | **new**, answers PROPOSED (G-065) |
| Hero / Hành trình / Năm đầu đời / Lớn lên / CTA | — | no change |

English for every new string is engineering-drafted for owner review (D-012). Mock values ("4.215.000 ₫", "7,8 kg", "17/11") need locale formatting in en ("₫4,215,000" or keep VND style; "7.8 kg"; "Nov 17").

**Reuse summary:** `Eyebrow` (mint, sun-ink), `.h2.h2--flat`, `.lead`, `CompactBullets`, `.split` / `.split--visual-first`, `.panel--mint` shell, `IconBox` (white + ink override), `Chip` (`sm` mint for the WHO chip; mint + check icon for the Theo cách chips), `Toggle` (+ off state), `Initials` (+ tint override), `Icon` (+ `grid`, `ruler`). New CSS: vaccine grid + marks, growth card, Tiện ích card (`.utility-card`), spending card, member rows, dark night chip, `.panel--sun-soft` (if not present).

---

## 10. Ambiguities, gaps and conflicts

(App parity → §11; product claims vs `business-map.md` → §12.)

**Design / implementation**
1. **No mobile frame** for v4 — §8 is engineering's proposal (column subsets in the vaccine card, stacked utility cards, re-composed panels). Needs owner/design confirmation.
2. **Row width 1216 vs 1248** in Sức khoẻ and Theo cách (left-aligned, 128 px right margin). Recommend filling 1248 with `.split` (copy `flex:1`), text max-widths as in Figma.
3. **Tiện ích cards fixed 440** while card 2's content is ~445 → use `min-height` + stretch.
4. **Theo cách panel** has ~100 px of empty space below the night chip (content ends at y 360 of 460). Either intentional breathing room or a missing element; build as designed (absolute positions) unless design adds something.
5. **Night chip** overlaps the Tuỳ chỉnh card by 1 px (y 322 vs card bottom 323) — treat as "touching", or add the 8–12 px gap design probably meant.
6. **Toggle off state** and a **dark chip** are new kit variants; chip padding 5/10 is between existing sizes.
7. **`Initials` tint order** for the spending footer (coral then mint-soft with `care-bottle-ink` letters) and the all-`card-peach` member avatars don't match the kit's rotating tints.
8. **First-aid image**: Figma embeds the 1.77 MB source PNG; the landing should use the app's 1200 × 800 WebP (added). Same art as the app topic → if the app art changes, the landing image should follow (consider importing from `content/first-aid/images/` instead of copying, like the icons are imported from `apps/mobile`).
9. **"Gia đình" nav link removed** — the `#gia-dinh` strip still exists inside Năm đầu đời; confirm nobody needs that entry point (it was the "Cả nhà cùng chăm" target in v3).
10. **Spelling**: "Sức khoẻ", "Tuỳ chỉnh", "minh hoạ", "tuỳ nhà bạn" use the old-style tone placement — consistent with the app (ARB `customizeTitle` "Tuỳ chỉnh Hôm nay", first-aid category "Sức khoẻ"); keep verbatim.
11. **Decorative mocks contain fixed data** (Teddy, 17/11, amounts, "Cô Lan", "Bà ngoại") — fine as illustrations, but they are translatable text, not images; en versions needed.
12. **Mock labels drift from the app** (§11): "6 trong 1 · lần 3", "Trong khoảng chuẩn WHO", "Mẹ ghi / Ba ghi", "Nhắc nhở sắp tới", "Ngủ", "Chế độ đêm", "Toàn quyền / Ghi chăm sóc / Xem kỷ niệm" — align to app strings or accept; owner/design call.

---

## 11. Mock UI vs the real app (parity check)

The new sections draw five app surfaces. They are **simplified marketing mocks, not copies** of the app screens — wording and data differ in places. Paths: app code under `apps/mobile/lib/`, strings in `apps/mobile/lib/l10n/app_vi.arb`.

| Mock | App screen (Figma / code) | Matches | Differs (landing → app) |
|---|---|---|---|
| Vaccine grid "Lịch tiêm chủng · Teddy" | VX 1 `396:3991` (`17-vaccination.md`); `features/vaccines/vaccine_screens.dart` (`_Matrix`, `_Dot`, `_NextCard`) | Mark colours: given = `mint-deep` + white check; upcoming = `sunshine-soft` + 2 px `sunshine` ring (`_Dot`); "Sơ sinh" (`vxBirth`), "{n} th" (`vxMonthsShort`); names "Viêm gan B", "Lao", "Phế cầu", "Rota", "Sởi" exist | App has **no age-column grid** (by-vaccine rows of dose circles with dates under them, or a by-age timeline); **"6 trong 1" → app "6in1"** (or "6in1 hoặc 5in1"); **"lần 3" → app "mũi 3"**; "Mũi tiếp theo: …" → app `vxNextLine` "Mũi tiếp theo · {date} · {left}"; next-dose is a full card (radius 16, clock in a white circle, chevron), not a pill; app rows also include Vitamin K, Cúm, Não mô cầu… |
| Growth card "Cân nặng / 7,8 kg" | 20d Tăng trưởng `346:47706` (`16-v1-improvement.md`); `features/care/history_screen.dart` `_GrowthPanel` | Chip colours `mint-soft` / `mint-text` | **"Trong khoảng chuẩn WHO" does not exist in the app** — app status is `whoNormal` "Bình thường" (+ check icon), `whoBelow` "Dưới mức tham chiếu", `whoAbove` "Trên mức tham chiếu"; legend `whoBand` "Khoảng bình thường"; app value adds the age ("4,3 kg · 3 tuần tuổi") |
| Spending card | 8b month home `437:3183`, 8d stats `438:3382` (`19-spending.md`); `features/spending/spending_screens.dart`, `spending_stats.dart` | "4.215.000 ₫" format (`money()`); split bar style (radius 6, 3 px gaps, `mint-deep` then `peach`) exists on Stats | Month home has **no per-member split** (only Stats → "Ai trả", 14 px bar); app wording is who **paid** ("{payer} trả", "Mẹ"/"Bố"), not who **logged** ("Mẹ ghi"/"Ba ghi"); header "Chi cho Teddy · tháng này" → app `spSpentOn` "Đã chi cho {name}"; "Ba và mẹ cùng xem như nhau" + avatars not in the app — the app says `spParentsOnly` "Chỉ cha mẹ thấy chi tiêu. Có thể cấp quyền cho người khác trong Gia đình."; app icon for spending is `grid` (✔ card icon), not cake |
| Member list | 14a Gia đình `116:11226` (`01-…family.md`); `features/family/family_screen.dart`, `ClMemberRow` | Role meanings: `roleCoParentHint` "Toàn quyền, như ba mẹ", `roleCaregiverHint` "Ghi & xem chăm sóc", `permViewMemories` "Xem kỷ niệm" | App shows "{relation} · {role}" as a subline ("Mẹ · Cùng nuôi", "Bà · Người thân"), not a right-aligned label; app role names are **"Cùng nuôi" / "Người chăm sóc" / "Người thân"**; "Toàn quyền" / "Ghi chăm sóc" / "Xem kỷ niệm" are not row labels in the app; avatar fills rotate (peach-soft, mint-soft, sunshine-soft, sleep-soft) with `ink` letters |
| "Tuỳ chỉnh Hôm nay" | CS Tuỳ chỉnh Hôm nay `370:1525` (`16-v1-improvement.md`); `features/today/today_layout.dart` (uncommitted work) | Title `customizeTitle` "Tuỳ chỉnh Hôm nay"; "Ô theo dõi nhanh" / "Bú, ngủ, tã, hút sữa, tăng trưởng"; "{count} nhắc đang bật"; "Nhịp trong ngày" / "Biểu đồ 24 giờ"; chips "Bú bình", "Bú mẹ", "Thay tã", "Hút sữa" with check | **"Nhắc nhở sắp tới" → app "Nhắc việc sắp tới"**; **chip "Ngủ" → app "Giấc ngủ"**; app also has "Tăng trưởng" chip and three opt-in rows (Tạo nhanh, Mũi tiêm sắp tới, Chi tiêu tháng này); Rhythm is **on** by default in the app (off in the mock — fine as a "user turned it off" state); when tiles are on, the app replaces the tiles sub-line with the chips; drag handle is `ink-muted` in the app (`control-border` in the mock) |
| Night chip "Chế độ đêm dịu mắt" / bullet "Chế độ đêm" | Night care (ARB `nightCareTitle` = **"Night care"** in vi too) | — | The app never says "Chế độ đêm" or "dịu mắt" — it keeps the English name "Night care" in Vietnamese (`nightCareSchedule` "Lịch Night care"); "chữ to" is false — see §12 |
| First-aid card | Sơ cứu (`20-v11-content-features.md`); `features/first_aid/*`, `utilities_screen.dart` | **"25 tình huống"** = 25 situations in `content/first-aid/pack.seed.json` (8 + 7 + 5 + 5) and the count is data-driven (`faEntrySub` "{count} tình huống · dùng khi không có mạng"); read-aloud `faReadAloud` "Đọc to hướng dẫn" (flutter_tts, offline voice); offline `faOffline` "Dùng được khi không có mạng"; image = topic "Băng bó cơ bản" (TH10) hero | Hard-coded "25" on the landing will drift if the pack grows — keep it in copy and update with content releases |
| "Có sẵn trong tab Tiện ích" | Tiện ích tab `450:6597` (`21-care-utilities-tabs.md`); `features/utilities/utilities_screen.dart` | Tab exists: "Cho bé" → "Sơ cứu trẻ em", "Chi tiêu", "Thư viện chăm bé" (Sớm ra mắt); "Gia đình" → "Thành viên & chia sẻ", "Mời người thân" ("Ông bà, người chăm cùng theo dõi bé" ✔ same phrase as the card body) | Card title "Gia đình & chia sẻ" vs app entry "Thành viên & chia sẻ"; card title "Sổ chi tiêu chung cho bé" vs app "Chi tiêu" |

Recommendation: either align the mock labels to the app strings (cheap — they are live text: "6in1", "mũi 3", "Bình thường", "Nhắc việc sắp tới", "Giấc ngủ", "Night care", "Cùng nuôi"…) or keep Figma wording and accept the drift. Owner/design call; listed in §12.

---

## 12. Copy claims vs `docs/product/business-map.md` (owner confirmation before prod; extend Q-039 / R-170)

Status of the features: vaccination (P-133, `vaccination-plan.md`), WHO growth (D-049), Tuỳ chỉnh Hôm nay (P-127) and the Tiện ích tab come from the Figma "v1.0 improvement" page; Chi tiêu (D-055, D-056, P-140, `spending-plan.md`) and Sơ cứu (D-058, P-141, `first-aid-plan.md`) from the Figma **v1.1** page. All are committed and deployed to **dev only** (no git tags, nothing in prod, nothing "done" in the coverage checklist). No rule forbids advertising v1.1 features before release — but Q-039 requires owner confirmation of landing claims beyond the map before the prod landing goes live, and R-170 / R-171 say landing claims are things the app must make true.

| # | Claim (verbatim) | Support | Conflict / over-claim | No D/R entry |
|---|---|---|---|---|
| 1 | Sức khoẻ head "Lịch tiêm và tăng trưởng, nhìn là hiểu." / "Biết con đã tiêm gì, sắp tiêm gì, lớn lên ra sao — không cần lục sổ." | P-133, D-049 | — | — |
| 2 | "Đánh dấu mũi đã tiêm, nhắc trước ngày tiêm cho cả nhà." | P-133 + `vaccination-plan.md` (server push 3 days before and the evening before, to chosen recipients) | **"cho cả nhà" over-claims**: recipients are Cùng nuôi + Người chăm sóc only (`firebase/functions/src/vaccine-reminders.ts`); relatives never get vaccine reminders | — |
| 3 | Vaccine mock (6 rows × "Sơ sinh … 9 th", "Mũi tiếp theo: 6 trong 1 · lần 3 · 17/11") | Schedule `packages/contracts/src/vaccines.ts`: Viêm gan B 0 ✔, Lao 0 ✔, 6in1 2·3·4 (dose 3 at 4 th ✔), Sởi 9 ✔ | **Rota is 2·3·4** (mock shows 2 doses with nothing due at 4 th), **Phế cầu 2·3·4·12** (same); none of the six mocked vaccines falls at 6 th (empty column); app name "6in1", dose word "mũi"; the app's own Figma scenario uses 17/11 for dose 1 at 2 months | — |
| 4 | "Cân nặng, chiều dài theo chuẩn WHO" — "Biểu đồ dễ đọc, không chấm điểm hay so sánh con." + chip "Trong khoảng chuẩn WHO" | D-049 (growth compared with the WHO band; replaces R-056's "no percentiles" for growth) | **Tension**: the app *does* compare with WHO and labels "Dưới / Trên mức tham chiếu" — "không chấm điểm hay so sánh con" must mean "no score, no comparison with other babies", which is defensible but needs owner OK. Chip text not in the app ("Bình thường"); the app says "tham chiếu", not "chuẩn" | — |
| 5 | "Dinh dưỡng theo giai đoạn" — "Lượng sữa tham khảo và nhóm chất cần chú ý theo tuổi." | — | **Not a feature**: only a "Sớm ra mắt" teaser tile in Chăm sóc (`care_hub_screen.dart`, ARB "Sữa, vi chất theo giai đoạn") — presented here as available | **yes** |
| 6 | Footnote "Nội dung tham khảo, được chuyên môn rà soát. …" | Q-039 (open: who reviews health content) | **Conflict**: no medical review is recorded (`content/first-aid/pack.seed.json` `"review": null`; vaccine data "for medical review"); P-133 / P-141 / `first-aid-plan.md` deliberately avoid claiming review. Second sentence matches the app banner "Lịch tham khảo, có thể thay đổi theo chỉ định của bác sĩ" | — |
| 7 | "Có sẵn trong tab Tiện ích, mở ra là dùng được." | Commit 3e2ffb2, `21-care-utilities-tabs.md` | D-058 / P-127 still place Sơ cứu and Chi tiêu in Chăm sóc (stale vs the Tiện ích tab). "mở ra là dùng được": Sơ cứu needs the guide downloaded once; Chi tiêu needs a D-055 right; relatives' Tiện ích is an open question | **Tiện ích tab: yes** |
| 8 | "25 tình huống thường gặp, từng bước có hình minh hoạ, đọc to hướng dẫn. Dùng được cả khi không có mạng." | D-058 (offline pack, "Đọc to hướng dẫn"), P-141 (device voice); 25 situations in the seed ✔ | **"từng bước có hình minh hoạ" over-claims** (one hero picture per situation; 8 of 94 steps have their own image); offline only **after the first download**; on prod the entry stays hidden until a medical reviewer approves the pack (D-058) | — |
| 9 | "Ba và mẹ cùng ghi, cùng xem một sổ như nhau…"; mock "Mẹ ghi / Ba ghi", "Ba và mẹ cùng xem như nhau" | D-055 (spending is for Cùng nuôi), D-056 ("Ai trả"), P-140 | True only for **two Cùng nuôi**; others only via "Ghi khoản đã chi" (own items) / "Xem toàn bộ". **No split by who logged** — only by payer ("Ai trả"), and only in the 6-month stats | split by recorder: yes |
| 10 | "Mời ông bà, người chăm cùng theo dõi bé. Mỗi người một quyền riêng, ba mẹ quyết định ai thấy gì." + Mẹ/Ba "Toàn quyền" | Roles (Cùng nuôi / Người chăm sóc / Người thân), D-017, D-019, D-024 | Two parents can both be Cùng nuôi ("Toàn quyền, như ba mẹ") but are not fully equal: only the owner adds/removes another Cùng nuôi (D-017) and deletes the baby (R-045). Acceptable simplification; flag | — |
| 11 | "Ứng dụng của nhà bạn, theo nhịp của nhà bạn." / "Chỉ hiện những gì bạn cần…" | general principles | — | yes (tone only) |
| 12 | "Bật, tắt và sắp xếp màn hình Hôm nay" — "Bú bình hay bú mẹ, có hút sữa hay không — tuỳ nhà bạn." | P-127 (Hôm nay layout kept **on this device, per baby** — owner to confirm) , R-010 (trackers chosen at setup) | Customisation hides/orders sections and tiles on one device; "tuỳ nhà bạn" reads as a family-wide setting. Choosing bottle vs breast is the setup tracker choice (R-010); P-127: no tracker editor after setup yet | only P-127 (proposal) |
| 13 | "Chế độ đêm" — "Màn hình tối, chữ to, ghi nhanh lúc 3 giờ sáng." / "Chế độ đêm dịu mắt" | R-011, P-061, R-071, R-200 | **"chữ to" is false** — Night care only swaps the palette (`cl_theme.dart`); no text scaling (the same claim was already in v1/v3, `11` l.401). App name is "Night care" | "chữ to": yes |
| 14 | "Danh mục chi tiêu riêng" — "Thêm, sửa, ẩn danh mục cho đúng cách nhà bạn chi." | P-140 / `spending-plan.md` (family-wide categories, add/edit/hide/reorder; "Khác" locked; only Cùng nuôi manage) | — | — |
| 15 | FAQ "Sơ cứu trong app có thay thế bác sĩ không?" (no answer) | D-058, P-141, app `faDisclaimer` "Nội dung tham khảo, không thay thế chẩn đoán của bác sĩ." | Draft must not claim expert review. PROPOSED: "Không. Hướng dẫn sơ cứu trong app chỉ để tham khảo khi chờ hỗ trợ y tế, không thay thế chẩn đoán của bác sĩ. Khi con nguy kịch, hãy gọi 115 ngay." | G-065 (answers missing) |
| 16 | FAQ "Ai xem được chi tiêu của gia đình?" (no answer) | D-055, D-056, P-140 (no amounts in analytics / push) | PROPOSED: "Mặc định chỉ ba mẹ (thành viên Cùng nuôi) thấy chi tiêu. Ba mẹ có thể cho người khác ghi khoản mình đã chi, hoặc xem toàn bộ, trong phần Gia đình." | G-065 |

Also carried over from `14` §10: multi-stage roadmap, retention promise, "không lo ghi trùng", trust chips — unchanged.

**Most important (owner decisions before prod):**
1. "được chuyên môn rà soát" (Sức khoẻ footnote) — no recorded review (Q-039); same issue as the existing trust chip.
2. "Dinh dưỡng theo giai đoạn" advertised as available — it is a "Sớm ra mắt" teaser. Drop, or mark "Sắp có".
3. Night care "chữ to" — false; reword (e.g. "Màn hình tối, dịu mắt, ghi nhanh lúc 3 giờ sáng.").
4. Spending "cùng xem một sổ như nhau" / "Mẹ ghi · Ba ghi" — only for Cùng nuôi, and the app splits by payer, not by recorder → mock should read "Mẹ trả / Bố trả" or drop the legend.
5. Growth "không chấm điểm hay so sánh con" vs D-049 status labels; chip text "Trong khoảng chuẩn WHO" → app "Bình thường".
6. Vaccine reminders "cho cả nhà" → "cho ba mẹ và người chăm".
7. First aid "từng bước có hình minh hoạ" and "Dùng được cả khi không có mạng" (after first download); first aid hidden on prod until medical approval (D-058) — the whole card may need to wait for v1.1 prod.
8. Vaccine mock data (Rota / Phế cầu dose counts, empty 6 th column, "6 trong 1 · lần 3").
9. Tiện ích tab has no D/R entry; D-058 / P-127 are stale about where Sơ cứu and Chi tiêu live → map update.
10. Today customisation is device-local (P-127 unconfirmed); "tuỳ nhà bạn" implies family-wide.
