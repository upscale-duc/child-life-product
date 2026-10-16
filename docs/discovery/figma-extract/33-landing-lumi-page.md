# 33 — Landing: Lumi detail page ("Lumi · Trang chi tiết")

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only; no node modified). Extracted 2026-10-15. Same conventions as `28-landing-v5b-home.md` / `15-landing-v3-stages.md`: token names from `07-foundations-components-motion.md` / `packages/design-tokens/dist/tokens.css`, non-token values marked **(raw)**, every visible string copied **verbatim from `get_design_context`** (layer names are stale or cut at 30 characters; never copy them).

> File number: `32` is left to the home v6 spec written in parallel (first free number); this doc takes **33**.

- Frame **`650:4798` "Lumi · Trang chi tiết · Desktop · VI"**, 1440 × 8134.2, at (1640, 37000) on the same canvas as the home v6 frame `649:6251` "Landing v6 · Desktop · Lumi" (at (0, 37000)). **Desktop, Vietnamese only. No English frame, no mobile frame** (see §19); §14 is a mobile *proposal* and §15 gives English *drafts*.
- A new page of the landing site: a product page for **Lumi**, the in-app chat assistant (extract `31-chat-assistant.md`; app strings `asLumiIntro*`, `asFabLabel` "Mở Lumi"; D-076 #11). It sells Lumi's jobs (log by one sentence, receipts, questions over the logs, suggestions, keepsakes), explains draft-and-confirm, and introduces **three paid tiers "Free · Plus · Pro" with prices** — which **contradict the app's single "Child Life Premium" plan** (§16).
- No prototype links, no motion, no hover/focus states, no tablet frame, Light only. Page background `cloud` #F6FCFB (root fill).

Screenshots (not committed; `scratchpad/v6/`): `l-full-thumb.png` (284 × 1600), `l-nav.png`, `l-hero.png` (1440 × 889), `l-loi-ich.png`, `l-mot-ngay.png`, `l-con-nhieu-viec.png`, `l-hanh-trinh.png` (1440 × 1122), `l-cach-lam-viec.png`, `l-goi.png` (1440 × 2047), `l-hoi-dap.png`, `l-ket.png`, `l-footer.png`.

Method: metadata dump of `650:4798` (`scratchpad/v6/b.xml`, 1238 lines) for structure; `get_design_context` on every section (`650:4799`, `650:4822`, `650:4957`, `691:5659`, `651:4895`, `691:5979`, `651:4956`, `651:4994`, `651:5301`, `651:5338`, `651:5367`) and on the home block `678:5614` for the comparison in §6; `get_screenshot` per section; `download_assets` on the mascot instance `650:4825`; per-icon SVGs downloaded to read stroke colours. `get_metadata` on candidate canvases to find siblings (§19).

---

## 0. Global

### 0.1 Section order

| # | Section | Node | y · h | Background | Padding (t r b l) | Proposed id |
|---|---|---|---|---|---|---|
| 1 | Nav | 650:4799 | 0 · 87 | page | 22 96 | — |
| 2 | Hero | 650:4822 | 87 · 889 | page | 72 96 96 96 | `#gioi-thieu` |
| 3 | Lợi ích | 650:4957 | 976 · 495 | `surface` | **4** 96 96 96 | `#loi-ich` |
| 4 | Một ngày cùng Lumi | 691:5659 | 1471 · 982 | page | **0** 96 96 96 | `#mot-ngay` |
| 5 | Còn nhiều việc | 651:4895 | 2453 · 643 | `surface` | **0** 96 96 96 | `#viec-khac` |
| 6 | Lumi suốt hành trình | 691:5979 (block 691:5838) | 3096 · 1122 | page | 0 96 96 96 | `#suot-hanh-trinh` |
| 7 | Cách Lumi làm việc | 651:4956 | 4218 · 647 | page (dark card) | 0 96 96 96 | `#cach-lam-viec` |
| 8 | Gói | 651:4994 | 4865 · 2047 | gradient (raw) | **0** 96 112 96 | `#goi` |
| 9 | Hỏi đáp | 651:5301 | 6912 · 623 | page | 96 | `#hoi-dap` |
| 10 | Kết | 651:5338 | 7535 · 415 | page (gradient card) | 0 96 **3** 96 | `#tai-app` |
| 11 | Footer | 651:5367 | 7950 · 184 | page | 32 96 40 | — |

**Vertical-rhythm bug:** sections 3, 4, 5 and 8 have **0–4 px top padding**, so their eyebrows sit on the top edge of the white / gradient bands (visible in `l-full-thumb.png`); every section has 96 px *bottom* padding instead. Implement **96 px top padding on the coloured bands (3, 5, 8)** and keep section 4 at 0 (it follows a white band whose bottom padding already spaces it) — or ask design. Kết's 3 px bottom padding is noise: use 96 (the Footer's 32 top then follows).

### 0.2 Text styles (Be Vietnam Pro)
Eyebrow SemiBold 13 / normal (pill `padding: 6px 12px; r 999`); H1 **Bold 52 / 1.1** (hero only, new size); H2 Bold 44 / 1.18 (Lợi ích, Còn nhiều việc, Cách, Gói), **Bold 40 / 1.18** (Một ngày, Kết), **Bold 36 / 1.2** (FAQ), **Bold 34 / 1.2** (journey block); hero lead **Medium 19 / 1.55** (new); leads Medium 18 / 17 / 16 / 1.55; card titles Bold 22 / 20 / 19 / 18 (1.25); body Medium 15 / 14 / 13 (1.45–1.55); chips SemiBold 13 / 12 / 11; plan name Bold 26; credit number Bold 44; price Bold 34.

### 0.3 Colours
Tokens: `cloud`, `surface`, `surface-2`, `separator`, `control-border`, `ink`, `ink-muted`, `mint` #2CBFB3, `mint-soft`, `mint-text` #06716D, `mint-deep` #087F7B, `on-mint-deep`, `sunshine-soft`, `peach-soft`, `card-peach` #FFA58D, `care-bottle-soft` / `care-bottle-ink` #1D5F99, `care-sleep-soft` #EDEEFC / `care-sleep-ink` #4447A8, `care-diaper-soft` / `care-diaper-ink` #2F6B24, `care-growth-soft` #FDEDE2.

**Lumi palette (raw, new; propose `--lumi-*` landing tokens):**
- `--lumi-teal` **#2BC4B5**, `--lumi-deep` **#086B73**, `--lumi-indigo` **#545CDB**.
- Lumi gradient (avatar dots, step numbers, Plus icon box, Kết card): `linear-gradient(≈127–156deg, #2BC4B5 14.286%, #545CDB 85.714%)` (Figma angles 126.87 / 128.6 / 131.05 / 131.83 / 156.24° — use 135° everywhere except the Kết card, 156°).
- Soft page gradients: hero mockup `linear-gradient(119.5deg, #E0F7F2 14.286%, #E8E8FF 85.714%)`; journey block `linear-gradient(132.37deg, #F2FCFA 14.286%, #F0F0FF 85.714%)` + border 1.5 px **#D1DBF7**; Gói section `linear-gradient(117.82deg, #F5FCFA 14.286%, #F2F2FF 85.714%)`.
- Others raw: dashed path **#8C99E6 @ 50 %**; dashed node circles stroke ≈ **#99A3EB** 1.5 px, fill white; dashed stage-card border **#D1D9F2**; Plus card border 2.5 px **#2BC4B5** (≈ `mint`); Pro accent **#FCD66B** (≈ `sunshine` #FFD166 — use the token); dark card **#163D44** (≈ `ink`, as in 28); on-dark text **#C7DEDE** (step bodies) and **#D9EBEB** (trust lines); table header row **#F2FAF7**, alternate rows **#FBFEFC** / white.
- The app paints the same mascot with **#2CBFB3 / #0B8A84 / #5B5FD6** (`LumiColors` in `apps/mobile/lib/features/assistant/lumi_button.dart`) — close but not equal to Figma's #2BC4B5 / #086B73 / #545CDB. Pick one set (Figma) and align the app later.

### 0.4 Shadows
`shadow-card` (`0 1 2 #173D440F, 0 8 24 #173D4414`; Figma prints it also as `drop-shadow(0 8 12 / 0 1 1)`): hero chat card and its two floats, Một ngày cards, Còn nhiều việc cards, Plus card, comparison table. The mascot carries its own shadows inside the SVG.

### 0.5 Icons
Used: chevron-down, check, spark, feed, sleep, diaper, camera, arrow-right, cloud-off, eye, clock, journal, star, heart, **link**, bookmark, lock, alert, grid, close, plus.
**Missing from the landing `Icon` map (`components/primitives.tsx`): `link` only** — `apps/mobile/assets/icons/link.svg` exists → one more `?raw` import. Everything else is mapped.

Stroke colours read from the exported SVGs: hero chevron `ink`; hero check chips `mint-text`; draft icons feed `care-bottle-ink`, sleep `care-sleep-ink`, diaper `care-diaper-ink`; composer camera `ink-muted`; send arrow white; cloud-off `ink`; "Ví dụ minh hoạ" eye `ink-muted`; Lợi ích clock `care-bottle-ink`, journal `mint-text`, star `ink`, heart `ink`; Một ngày time-chip clock `mint-text`, receipt arrow `ink-muted`, source / dish / evidence chip icons (link, bookmark, sleep, journal, camera) `ink`, play arrow `ink`; Còn nhiều việc clocks `ink`; journey stage-1 sparks `mint-text`, stages 2–4 sparks `care-sleep-ink`, "Định hướng" clock `ink-muted`, "Đang có" check white; Cách trust icons **#FCD66B**; plan feature icons `mint-text` (grid drawn as 4 rounded squares, `mint-text`); Plus spark white, Pro spark `ink`; price-note alert `ink-muted`; table checks `mint-text`; "Lượt hỗ trợ là gì" spark `care-sleep-ink`; FAQ close / plus `ink-muted`.

**Semantic misuse:** the expense drafts ("Bỉm · 289.000đ", hero float and Một ngày card 2) use **cloud-off** (= offline) as the expense icon. Use the landing's Chi tiêu icon (`grid`, as in 28 §3.3 card 2) — flag to design.

### 0.6 Lumi mascot — `Chat/Nút trợ lý` (component `628:9074`)
Component description (verbatim): "Nút nổi mở Trợ lý chat. Dùng Logo/Mark Child Life + huy hiệu AI. …". Layers at 52 px (scale everything by size/52): **Hào quang** blurred circle (gradient #2BC4B5→#545CDB @ 55 %, blur σ 4.06); **Bong bóng** 43.9 px speech bubble (corners 21.9 / 21.9 / 6.5 bottom-right / 21.9), fill `linear-gradient(135deg, #2BC4B5 14.3 %, #086B73 53.6 %, #545CDB 85.7 %)`, 1.2 px white 45 % border, drop shadow `0 6.5 14.6 −2 rgba(31,77,153,.35)` + inset `0 1.6 3.25 rgba(255,255,255,.35)`; **Bóng sáng** white sheen ellipse 32 % → 0; **Logo/Mark** 19.5 px (sun #FFD980 95 %, band white 55 %, ground white 22 %, masked to r 6.8); two **Sao AI** sparkles (gold #FFD166 13 px with gold glow; white 7.3 px with indigo glow) at the top-right.

**Asset added:** `apps/landing/src/assets/figma/lumi-mascot.svg` — the export of instance `650:4825`, page backgrounds removed, ids prefixed `lumi-`, `viewBox` cropped to the 52 × 52 button box with `overflow="visible"` (the halo and sparkles reach ≈ 9 px past it). Import it `?raw` and inline it (like the icons) so the glow is not clipped; when several mascots are inlined on one page the identical gradient / filter ids repeat harmlessly (same definitions) — or render once as `<symbol>` and `<use>` it.
**App:** the app does **not** ship this art as a file; it paints it in code (`LumiMascot` CustomPainter, "one gold eye, a soft smile" = the sun and band of the logo mark). Nothing to reuse from `apps/mobile/assets`.

Sizes on this page: 52 (hero eyebrow), 36 (chat header, journey eyebrow), 54 / 32.2 @ 57 % / 37.2 @ 69 % / 42.2 @ 81 % (journey path), 56 (Kết). The home uses 44 and 104 as well (`649:7275`, `676:5571`).

---

## 1. Nav (650:4799, 1440 × 87)

Identical structure to the home v6 nav `649:6252` (`padding: 22px 96px`, lockup 175.9 × 34, flex spacer, links `gap: 36px` Medium 15 / normal nowrap, 40-px spacer, CTA pill `ink` / `surface` SemiBold 15 `padding: 12px 22px` **"Tải miễn phí"**).
Links, verbatim, in order: **"Hành trình" · "Năm đầu đời" · "Lumi" · "Các chặng" · "Kỷ niệm" · "Hỏi đáp"** — "Apple Watch" (v5b) is gone, **"Lumi"** is new (third).
**Current-page style:** on this page "Lumi" is **Bold, `mint-text`**; the others are Medium **`ink`** (v5b was `ink-muted`). Implement as `aria-current="page"` + `.nav__link--current`. Targets: §13.

---

## 2. Hero (650:4822, 1440 × 889)

`display:flex; gap: 64px; align-items:center; padding: 72px 96px 96px;`

### 2.1 Copy 650:4823 (640 wide, `column; gap: 24px`)
1. **eb** `gap: 12px; align-items:center`: mascot 52 + eyebrow **`care-sleep-soft` / `care-sleep-ink`** **"Lumi · Trợ lý đồng hành trong Child Life"**.
2. H1 Bold **52 / 1.1** `ink`, two hard lines: **"Kể một câu."** / **"Lumi ghi giúp, nhớ giúp."**
3. Lead Medium **19 / 1.55** `ink-muted` (3 lines): **"Lumi là trợ lý của cả nhà trong Child Life. Gõ như đang nhắn tin, chụp một tấm ảnh hay hỏi một câu — Lumi soạn sẵn bản ghi, trả lời từ chính nhật ký của con và gợi ý một việc nhỏ cho hôm nay."**
4. CTA row `gap: 12px`:
   - Primary `mint-deep`, `padding: 16px 28px; r 999`, SemiBold 17 `on-mint-deep` **"Dùng thử Lumi"** (176 × 54).
   - Secondary (a `<button>` in Figma) `surface` + 1 px `control-border`, `padding: 16px 26px; gap: 8px; r 999`, SemiBold 17 `ink` **"Nâng cấp gói"** + chevron-down 16 `ink` (191 × 56). The chevron means "scroll down" → an anchor to `#goi`.
5. "Cam kết" chips `gap: 8px`: `surface`, `padding: 6px 12px; gap: 6px; r 999`, check 12 + SemiBold 12 `mint-text`: **"Bạn xác nhận trước khi lưu"** · **"Trả lời từ nhật ký của con"** · **"Cả nhà dùng theo quyền"**.

### 2.2 Mockup 650:4862 (544 × 721, `border-radius: 44px`, hero gradient §0.3; `position: relative`)
Decorative (`aria-hidden`), HTML/CSS so every string translates. Paint order:

**a. Chat card "Mock · Chat với Lumi"** 650:4863 at (72, 48), 400 wide (625 tall by content): `background: cloud; border: 1px solid separator; border-radius: 32px; padding: 18px 16px; column; gap: 12px; shadow-card`.
- Header `gap: 10px`: mascot 36; column gap 1: Bold 16 `ink` **"Lumi"**, Medium 12 `ink-muted` **"Trợ lý của nhà Teddy"**.
- Parent bubble (right-aligned, `mint-deep`, `padding: 9px 13px; r 16`, Medium 13 / 1.4 `on-mint-deep`, text 268 wide → 2 lines): **"Con bú 120 ml lúc 9h, ngủ từ 9h30, thay tã lúc 10h"**.
- Lumi turn `gap: 8px`: avatar dot (22 circle, Lumi gradient, `padding: 5px`, spark 12 white) + bubble `surface; border 1px separator; r 16; padding: 9px 13px; column; gap: 8px`:
  - Medium 13 / 1.45 `ink` **"Mình soạn 3 bản nháp, bạn xem lại rồi lưu nhé:"**
  - three **draft rows** (`cloud`, 1 px `separator`, `r 16; padding: 10px 12px; gap: 10px`): icon box `padding: 8px; r 12` + icon 16; column gap 2: SemiBold 14 `ink` title, Medium 12 `ink-muted` sub; chip `surface-2` `padding: 4px 10px; r 999` SemiBold 12 `ink-muted` **"Nháp"**:
    | Box / icon | Title | Sub |
    |---|---|---|
    | `care-bottle-soft` / feed | **"Bú bình · 120 ml"** | **"9:00"** |
    | `care-sleep-soft` / sleep | **"Giấc ngủ"** | **"từ 9:30"** |
    | `care-diaper-soft` / diaper | **"Thay tã"** | **"10:00"** |
  - full-width button `mint-deep`, `padding: 9px 14px; r 999`, SemiBold 13 `on-mint-deep` **"Lưu cả 3"**.
- Parent bubble (nowrap): **"Mấy hôm nay con hay khó ngủ buổi tối"**.
- Lumi turn: **"3 tối gần đây có 2 lần bạn ghi “khó vào giấc”, đều sau 21h. Muốn xem lại các giấc quanh đó không?"**
- Composer `surface; border 1px control-border; r 999; padding: 10px 12px; gap: 8px`: camera 16 `ink-muted`; Medium 13 `ink-muted` flex 1 **"Kể, hỏi hoặc gửi ảnh cho Lumi…"**; send `mint-deep` circle `padding: 6px` + arrow-right 14 white.

**b. Float "Đã lưu"** 650:4937 at (−40, 30) (overhangs the mockup's left edge by 40): `surface; r 16; padding: 10px 14px; gap: 8px; shadow-card`; `mint-soft` circle `padding: 4px` + check 12 `mint-text`; SemiBold 13 `ink` **"Đã lưu 3 bản ghi vào Nhật ký"**.

**c. Float expense draft** 650:4942 at (324, 613), 250 wide (overhangs the right edge by 30): `surface; border 1px separator; r 16; padding: 10px 12px; gap: 10px; shadow-card`; `peach-soft` box + cloud-off 16 `ink` (§0.5); SemiBold 14 **"Bỉm · 289.000đ"** / Medium 12 `ink-muted` **"Từ ảnh hoá đơn → Chi tiêu"** (2 lines in 120 px); chip **"Nháp"**.

**d. Chip** 650:4956 at (391, 24): `surface; padding: 6px 12px; gap: 6px; r 999`, eye 12 `ink-muted` + SemiBold 12 `ink-muted` **"Ví dụ minh hoạ"** — a disclosure that the conversation is illustrative; keep it.

Implementation: a new `LumiChat` mock (atoms reusable in §4/§5: `Bubble`, `LumiTurn`, `DraftRow`, `SourceChip`), composed at 544 × 721 with `Fit`/`at()` like the other mocks. The app's real components are `Chat/Thẻ nháp` `611:7695` / `Chat/Ô nhập` `611:7763` (31 §Components); the landing draws a simplified version.

---

## 3. Lợi ích (650:4957, 1440 × 495)

`background: surface; column; align-items:center; gap: 48px;` padding §0.1.
- Head (`gap: 14px`, centred): eyebrow `mint-soft` / `mint-text` **"Lumi giúp gì cho nhà bạn"**; H2 Bold 44 / 1.18 centred 760 (2 lines) **"Bớt việc phải nhớ, thêm thời gian bên con."**
- Row `gap: 20px`: 4 cards 297 wide (1248), `align-self: stretch` (201 tall): `background: cloud; r 24; padding: 24px 22px; column; gap: 12px;` icon box `padding: 8px; r 12` + icon 20; title Bold **19** / 1.25 `ink`; body Medium 15 / 1.55 `ink-muted`.

| # | Box / icon | Title | Body |
|---|---|---|---|
| 1 | `care-bottle-soft` / clock (`care-bottle-ink`) | **"Nhanh khi tay đang bận"** | **"Một câu thay cho nhiều lần chạm. Lumi tách thành từng bản ghi đúng mục."** |
| 2 | `mint-soft` / journal (`mint-text`) | **"Hiểu con từ chính nhật ký"** | **"Hỏi gì Lumi cũng trả lời từ dữ liệu nhà bạn đã ghi, kèm nguồn để mở lại."** |
| 3 | `sunshine-soft` / star (`ink`) | **"Một việc nhỏ cho hôm nay"** | **"Gợi ý vừa sức theo tuổi và những gì bạn đã ghi — bạn chọn điều phù hợp."** |
| 4 | `peach-soft` / heart (`ink`) | **"Giữ lại từng khoảnh khắc"** | **"Từ ảnh trong máy thành thiệp, đoạn phim nhỏ cho những cột mốc đầu đời."** |

---

## 4. Một ngày cùng Lumi (691:5659, 1440 × 982)

`column; gap: 44px;` padding §0.1.
- Head `display:flex; gap: 40px; align-items:flex-end;`:
  - left 640, `gap: 14px`: eyebrow **`care-sleep-soft` / `care-sleep-ink`** **"Một ngày cùng Lumi"**; H2 Bold **40** / 1.18 (2 lines) **"Từ cữ bú sáng sớm đến video cuối tháng."**
  - right `flex: 1` (568): Medium 17 / 1.55 `ink-muted` **"Sáu khoảnh khắc quen thuộc, mỗi lúc chỉ cần một câu hoặc một tấm ảnh."**
- Grid: 2 rows `gap: 24px`, each 3 cards **400** wide `gap: 24px` (341 tall): `surface; r 26; padding: 12px 12px 22px; column; gap: 14px; shadow-card`.
  - **Minh hoạ** 376 × 210, `r 18; padding: 14px; column; justify-content:center; gap: 8px; overflow:hidden;` tinted bg; decorative.
  - **body** `padding: 0 8px; column; gap: 6px`: time chip `mint-soft`, `padding: 4px 10px; gap: 6px; r 999`, clock 12 + SemiBold 12 `mint-text`; title Bold 20 / 1.25 `ink`; body Medium 15 / 1.5 `ink-muted` (1 line).

| # | Node | Illus bg | Time | Title | Body |
|---|---|---|---|---|---|
| 1 | 691:5669 | `care-bottle-soft` | **"06:30"** | **"Đang bế con, vẫn ghi kịp"** | **"Kể một câu, Lumi soạn sẵn bản ghi."** |
| 2 | 691:5700 | `peach-soft` | **"10:15"** | **"Hoá đơn thành khoản chi"** | **"Chụp hoá đơn, Lumi điền sẵn số tiền."** |
| 3 | 691:5731 | `mint-soft` | **"13:00"** | **"Hỏi nhanh, biết ngay"** | **"Trả lời từ nhật ký, kèm nguồn để mở lại."** |
| 4 | 691:5756 | `sunshine-soft` | **"17:30"** | **"Hôm nay con ăn gì?"** | **"Món hợp tuổi, tránh món con từng phản ứng."** |
| 5 | 691:5784 | `care-sleep-soft` | **"21:30"** | **"Mấy hôm nay con khó ngủ"** | **"Đặt các ghi nhận gần đây cạnh nhau."** |
| 6 | 691:5813 | `card-peach` (hidden by the photo) | **"Cuối tháng"** | **"Tròn tháng, thành phim nhỏ"** | **"Chọn ảnh và mẫu, có ngay video đầy tháng."** |

Mocks (atoms from §2.2; bubbles in a 348-wide column; Lumi bubble 318):
1. Parent bubble **"Con bú 120 ml lúc 9h, ngủ từ 9h30"**; draft rows "Bú bình · 120 ml" / "9:00" (bottle) and "Giấc ngủ" / "từ 9:30" (sleep), each with "Nháp".
2. Row `gap: 10px; align-items:center`: photo window 64 × 84 `surface-2` r 10 (library **Sand** at 84² left −10 — a baby photo standing in for a **receipt**, §12); arrow-right 16 `ink-muted`; draft row flex 1 with **`surface`** icon box + cloud-off: **"Bỉm · 289.000đ"** / **"Chi tiêu · hôm nay"** / "Nháp". Below, Medium **11** / 1.4 `ink-muted`: **"Ngày trên hoá đơn mờ — Lumi hỏi lại trước khi lưu."**
3. Parent **"Hôm nay con bú thế nào?"**; Lumi: **"5 cữ bú bình · tổng 580 ml. Cữ gần nhất lúc 14:20."** + source chip (`cloud`, `padding: 3px 8px; gap: 6px; r 999`, icon 11 `ink` + SemiBold 11 `ink`) link **"Mở nhật ký nguồn"**.
4. Parent **"Hôm nay cho Na ăn gì?"**; Lumi: **"Gợi ý cho bé 7 tháng, đã bỏ trứng vì từng ghi nổi mẩn:"** + two stacked chips (gap 6) bookmark **"Cháo bí đỏ"**, **"Khoai lang nghiền"**.
5. Parent **"Mấy hôm nay con khó vào giấc"**; Lumi: **"3 tối gần đây có 2 ghi nhận khó vào giấc, đều sau 21h. Xem lại các giấc quanh đó nhé?"** + chips (row gap 6) sleep **"6 giấc ngủ"**, journal **"2 ghi chú"**.
6. Full-bleed photo 376 × 210 (library **Peach** 376² at top −83, §12); play button `surface` circle `padding: 10px` + arrow-right 16 `ink` centred at (170, 87); chip at (12, 176) `surface`, `padding: 4px 8px; gap: 6px; r 999`, camera 11 + SemiBold 11 `ink` **"Một tháng đầu của Teddy · 0:45"**.

---

## 5. Còn nhiều việc (651:4895, 1440 × 643)

`background: surface; column; gap: 48px; align-items:flex-start;` padding §0.1.
- Head (left-aligned, `gap: 14px`): eyebrow `mint-soft` / `mint-text` **"Và còn nhiều việc khác"**; H2 Bold 44 / 1.18 800 wide **"Lumi lớn lên cùng nhà bạn."**; lead Medium 18 / 1.55 `ink-muted` 680 wide **"Càng ghi nhiều, Lumi càng hiểu nếp nhà bạn để nhắc đúng lúc và gợi ý sát hơn."**
- Row `gap: 20px`: 4 cards 297 wide (335 tall): `surface; r 24; padding: 12px 12px 22px; column; gap: 14px; shadow-card`; Minh hoạ 273 × 170 `r 18; padding: 14px; column; justify-content:center;`; body `padding: 0 8px; gap: 6px`: Bold **18** / 1.25 `ink`; Medium **14** / 1.55 `ink-muted`.

| # | Node | Illus bg | Mock | Title | Body |
|---|---|---|---|---|---|
| 1 | 651:4902 | `care-growth-soft` | photo 56 × 70 r 8 (library **Sand**, 70² left −7 — stands in for a **paper note**, §12) + column gap 6 of two `surface` chips (`padding: 4px 8px; gap: 6px`, clock 11 `ink`, SemiBold 11 `ink`): **"Mua bỉm size M · thứ Bảy"**, **"Hẹn khám 2 tháng · 9h T5"** | **"Ảnh giấy dặn → nhắc việc"** | **"Chụp tờ giấy dặn hay bảng ghi chú, Lumi tách thành từng nhắc việc để bạn chọn lưu."** |
| 2 | 651:4926 | `mint-soft` | white box 245 `r 14; padding: 12px; gap: 6px`: Bold 13 **"Tuần này của Teddy"**; Medium 11 / 1.45 `ink-muted` **"Ngủ đêm dài hơn 2 tối · thêm mốc “cười thành tiếng” · lịch tiêm tuần sau."** | **"Tóm tắt tuần cho cả nhà"** | **"Mỗi tuần một bản ngắn: con ăn ngủ ra sao, mốc mới, việc sắp tới — gửi ông bà theo quyền."** |
| 3 | 651:4934 | `care-sleep-soft` | same box: Bold **12** **"Giai đoạn 2 (Wonder Weeks) · tham khảo"**; Medium 11 **"Bạn đã ghi: bám mẹ hơn 3 ngày, bú đêm thêm 1 cữ."** | **"Nhịp lớn lên của riêng con"** | **"Đặt những thay đổi bạn đã ghi cạnh lịch giai đoạn tham khảo — Giai đoạn N (Wonder Weeks) chỉ để đối chiếu."** |
| 4 | 651:4942 | `sunshine-soft` | parent bubble (text 170 wide, 2 lines) **"Bé 4 tháng ngủ ngày mấy giấc?"**; Lumi turn (bubble 215) **"Theo thư viện: thường 3–4 giấc… (nội dung minh hoạ · chờ duyệt)"** | **"Hỏi đáp chăm bé"** | **"Hỏi về giấc ngủ, ăn dặm, vệ sinh — Lumi trả lời từ thư viện nội dung và chỉ đường đến hướng dẫn an toàn khi cần."** |

Card 1: the chip column frame is 100 wide but its chips are 166–172 wide — they overflow it (they still fit in the 245 illustration). Lay out as `flex: 1; min-width: 0` with nowrap chips.

---

## 6. Lumi suốt hành trình (691:5979 → block 691:5838, 1248 × 1026)

**Shared with the home page:** the block `691:5838` is **identical to the home block `678:5614`** (same structure, sizes, styles, every string and every exported asset hash) **except the closing button label: home "Khám phá Lumi hôm nay" (an `<a>`, 265 wide) vs here "Dùng thử Lumi hôm nay" (256 wide)**. Build **one component** `LumiJourney` with a `cta: { label, href }` prop; on the home page it sits inside "Các chặng tiếp theo" (`649:6826`, below the stage cards), here it is its own section (`padding: 0 96px 96px`).

Block: `border: 1.5px solid #D1DBF7; border-radius: 40px; background: journey gradient (§0.3); padding: 56px 56px 48px; column; gap: 40px;`

**Head** `display:flex; gap: 40px; align-items:flex-end;`
- left 720, `gap: 14px`: row `gap: 10px` = mascot 36 + eyebrow `care-sleep-soft` / `care-sleep-ink` **"Lumi theo con suốt hành trình"**; H2 Bold **34 / 1.2** `ink` **"Con lớn lên, Lumi cũng lớn theo con."**
- right `flex: 1` (373): Medium 16 / 1.55 `ink-muted` (4 lines) **"Hôm nay Lumi đồng hành cùng ba mẹ trong năm đầu đời. Ở mỗi chặng sau, Lumi sẽ có thêm cách giúp mới — vừa với tuổi của con và nhịp của gia đình."**

**Path "Đường hành trình"** 1136 × 72, `overflow: hidden`, absolute (decorative):
- dashed line (136, 36) → 1000: 2 px **#8C99E6 @ 50 %**, `dasharray 6 6`; solid segment (136, 36) → 272: **3 px `mint`**.
- node 1: mascot **54** at (109, 9) (centre x 136, full opacity).
- nodes 2–4: white circle with 1.5 px dashed ≈ #99A3EB stroke, mascot inside, growing and fading in: circle **52** at (398, 10) + mascot 32.24 @ **57 %**; circle **60** at (682, 6) + mascot 37.2 @ **69 %**; circle **68** at (966, 2) + mascot 42.16 @ **81 %** (centres x 424 / 712 / 1000). Figma exports the circles as PNG (`Ellipse`); draw them in CSS (`border: 1.5px dashed`, `border-radius: 50%`).
- Node centres line up with the four stage cards below (cards start at 0 / 288 / 576 / 864; centres 136 / 424 / 712 / 1000) — keep that alignment.

**Stage cards "Các chặng"** `gap: 16px`, 4 × 272 (`align-self: stretch`, 512 tall): `surface; r 24; padding: 20px 18px 22px; column; gap: 12px;` card 1 **border 2 px `mint`**, cards 2–4 **border 1 px dashed #D1D9F2**.
- head row `gap: 6px`: stage chip `padding: 4px 9px; r 999` SemiBold 11 + spacer + status chip (`padding: 4px 9px; gap: 6px; r 999`, icon 11 + SemiBold 11).
- title Bold 20 / 1.25 `ink`; lead Medium 14 / 1.5 `ink-muted`; 1 px `separator`; items `gap: 10px` (spark 14 inside `padding: 4px 0`; column gap 2: SemiBold 14 / 1.4 `ink` title + Medium 13 / 1.5 `ink-muted` description).

| Card | Stage chip (bg / text) | Status | Title | Lead | Items (title — description) |
|---|---|---|---|---|---|
| 1 | `mint-soft` / `mint-text` **"Chặng 1 · 0–12 tháng"** | `mint-deep` + white check **"Đang có"** | **"Năm đầu đời"** | **"Nhẹ nhàng hơn cho cả nhà."** | sparks `mint-text`, titles only: **"Kể một lần, ghi đúng chỗ."** · **"Hỏi về nhật ký của con."** · **"Gợi ý món ăn dặm hôm nay."** |
| 2 | `sunshine-soft` / `ink` **"Chặng 2 · 1–3 tuổi"** | `cloud` + clock `ink-muted` **"Định hướng"** | **"Con tập khám phá"** | **"Bớt nghĩ chơi gì, thêm những điều cùng con thử."** | **"Hôm nay chơi gì cùng con?"** — **"Gợi ý hoạt động ngắn theo tuổi, sở thích đã ghi và những vật dụng có sẵn."** · **"Từng lời đầu tiên, không bị quên."** — **"Gom những câu nói ngộ nghĩnh, tiếng cười và bước tiến nhỏ thành nhật ký của con."** · **"Cùng xây những thói quen nhỏ."** — **"Chuẩn bị những bước đơn giản cho giờ ngủ, đánh răng hay thu dọn đồ chơi, theo cách gia đình lựa chọn."** |
| 3 | `peach-soft` / `ink` **"Chặng 3 · 3–6 tuổi"** | **"Định hướng"** | **"Tò mò và lớn khôn"** | **"Thêm ý tưởng cho những câu hỏi không ngừng."** | **"“Vì sao?” cũng thành giờ chơi."** — **"Biến điều con tò mò thành câu chuyện, trò chơi hoặc hoạt động để cùng khám phá."** · **"Một ngày của con, dễ kể lại hơn."** — **"Từ vài ghi chú của ba mẹ, gợi ý câu hỏi để cùng con trò chuyện về ngày ở lớp."** · **"Bức vẽ nhỏ, câu chuyện lớn."** — **"Giữ tác phẩm cùng lời con kể, rồi gom thành bộ sưu tập qua từng năm."** |
| 4 | `care-sleep-soft` / `care-sleep-ink` **"Chặng 4 · 6–12 tuổi"** | **"Định hướng"** | **"Thế giới riêng của con"** | **"Đồng hành gần hơn, dành chỗ cho con tự lớn."** | **"Ý tưởng của con có nơi bắt đầu."** — **"Cùng chia một dự án nhỏ thành những bước vừa sức — trồng cây, làm mô hình hay viết truyện."** · **"Kế hoạch do con cùng lựa chọn."** — **"Chuẩn bị lịch học, việc nhà và thời gian cho sở thích; ba mẹ và con cùng điều chỉnh."** · **"Một năm nhìn bằng mắt con."** — **"Gom thành quả, câu chuyện và điều con tự hào thành cuốn kỷ niệm có tiếng nói của chính con."** |

Stage titles equal `journey.stages[i].name` (reuse); stage leads and items are new. Stage 2–4 sparks are `care-sleep-ink`.

**Closing bar "Kết khối"** `surface; r 24; padding: 22px 24px; gap: 24px; align-items:center;`: column `flex: 1; gap: 4px`: Bold 20 `ink` **"Bắt đầu từ hôm nay. Cùng chờ những chặng tiếp theo."**; Medium 14 / 1.5 `ink-muted` **"Các trải nghiệm trên là định hướng đang được phát triển. Phạm vi và thời điểm ra mắt sẽ được cập nhật theo từng chặng."** Button `mint-deep`, `padding: 15px 24px; gap: 8px; r 999`, SemiBold 16 `on-mint-deep` **"Dùng thử Lumi hôm nay"** (home: **"Khám phá Lumi hôm nay"**) + arrow-right 16 white.

---

## 7. Cách Lumi làm việc (651:4956, 1440 × 647)

Section `padding: 0 96px 96px;` → card "Thẻ" 1248: `background: #163D44 (raw ≈ ink); border-radius: 40px; padding: 64px; column; gap: 48px;`
- Head `gap: 14px`: eyebrow `sunshine-soft` / `ink` **"Lumi làm việc thế nào"**; H2 Bold 44 / 1.18 **white, nowrap** **"Lumi soạn sẵn. Bạn là người quyết định."**
- Steps `gap: 20px`: three 362-wide boxes `background: rgba(255,255,255,.08); r 24; padding: 24px; column; gap: 10px;`: number pill (Lumi gradient, `padding: 6px 13px; r 999`, Bold 15 white); title Bold 20 white; body Medium 15 / 1.55 **#C7DEDE**.
  1. **"1"** **"Kể, hỏi hoặc chụp"** — **"Gõ như nhắn tin, hoặc gửi ảnh hoá đơn, giấy dặn."**
  2. **"2"** **"Lumi soạn nháp"** — **"Tách đúng mục, hỏi lại chỗ thiếu hoặc chưa rõ."**
  3. **"3"** **"Bạn xem và lưu"** — **"Sửa, bỏ hoặc lưu từng bản. Lumi không tự lưu."**
- Trust row "Tin cậy" `gap: 28px`: three 378-wide items `gap: 10px`: icon 18 **#FCD66B** + Medium 14 / 1.5 **#D9EBEB**:
  - eye **"Chỉ người trong nhà, theo quyền bạn cấp"**
  - lock **"Ảnh gửi cho Lumi chỉ để đọc nội dung, bạn chọn có giữ ảnh gốc hay không"**
  - alert **"Lumi không thay bác sĩ. Khi lo lắng về sức khoẻ, Lumi chỉ đường đến hướng dẫn an toàn và số khẩn cấp"**
- **Overflow bugs:** card inner width is 1120 (1248 − 2 × 64) but the steps row is 1126 and the trust row 1190 → the third trust line runs 70 px into the right padding (`l-cach-lam-viec.png`). Implement both rows as `display:grid; grid-template-columns: repeat(3, 1fr); gap: 20px / 28px`.

---

## 8. Gói (651:4994, 1440 × 2047)

Section `background: Gói gradient (§0.3); column; align-items:center; gap: 44px;` padding §0.1. Content width **1188** (not 1248).

### 8.1 Head 651:4995 (centred, `gap: 14px`)
Eyebrow `mint-soft` / `mint-text` **"Nâng cấp gói"**; H2 Bold 44 / 1.18 centred 800 (2 lines) **"Mọi việc Lumi làm, nhà nào cũng dùng được."**; lead Medium 18 / 1.55 `ink-muted` centred 680 **"Ba gói chỉ khác nhau ở số lượt hỗ trợ mỗi tháng. Chọn mức hợp với nhịp nhà bạn — đổi gói bất cứ lúc nào."**

### 8.2 "Kỳ hạn" toggle 651:5000 (241 × 44)
`background: surface; padding: 4px; gap: 4px; r 999;` two segments `padding: 9px 20px; r 999` SemiBold 14: **selected** `mint-deep` / `on-mint-deep` **"Theo tháng"**; unselected transparent / `ink` **"Theo năm"**.
**Only the monthly state is drawn.** Nothing in Figma says what "Theo năm" changes. Proposal (owner review):
- Implement as a real control (`role="radiogroup"`, two `role="radio"` buttons, arrow keys) that swaps the three price blocks (§8.3) and the hidden "Giá mỗi tháng" table row (§8.5); everything else (credits, videos) stays — credits are per month in both cases (but see §16 row 6).
- Yearly state: big price **"790.000đ"** / **"1.790.000đ"** + suffix **"/ năm"**; sub-line **"≈ 65.800đ/tháng · tiết kiệm 2 tháng"** / **"≈ 149.200đ/tháng · tiết kiệm 2 tháng"** (790 000 / 12 = 65 833; 1 790 000 / 12 = 149 167); Free unchanged ("0đ" / "Không cần thẻ thanh toán"). Monthly state as drawn ("hoặc 790.000đ/năm · tiết kiệm 2 tháng").
- Prerender the monthly state (no-JS readers see the drawn page); the toggle is progressive enhancement.
- Alternative if the owner prefers fewer moving parts: drop the toggle — the monthly cards already state the yearly price.

### 8.3 "Ba gói" 651:5005 (1188 × 557)
Row `gap: 24px; align-items:flex-start`, 3 cards **380** wide, `align-self: stretch`: `background: surface; r 28; padding: 28px; column; gap: 16px;`

| | Free 651:5006 | Plus 651:5043 | Pro 651:5083 |
|---|---|---|---|
| Card border | 1 px `separator` | **2.5 px #2BC4B5** + `shadow-card` (highlighted) | 1 px `separator` |
| Header icon | none | 26 box Lumi gradient `padding: 6px; r 10` + spark 14 white | 26 box **#FCD66B** + spark 14 `ink` |
| Name (Bold 26 `ink`) | **"Free"** | **"Plus"** | **"Pro"** |
| Tagline (Medium 13 `ink-muted`, right) | **"Để bắt đầu"** | **"Cho ngày nhiều việc"** | **"Cho cả nhà dùng nhiều"** |
| Credits box (`cloud`, r 20, p 18; Bold 44 `ink` + Medium 14 `ink-muted`) | **"30"** **"lượt hỗ trợ / tháng"** | **"300"** **"lượt hỗ trợ / tháng"** | **"1.000"** **"lượt hỗ trợ / tháng"** |
| check | **"Tất cả việc Lumi làm được"** | same | same |
| camera | **"≈ 10 ảnh hoá đơn, giấy dặn"** | **"≈ 100 ảnh hoá đơn, giấy dặn"** | **"≈ 330 ảnh hoá đơn, giấy dặn"** |
| heart | **"1 video kỷ niệm / tháng"** | **"5 video kỷ niệm / tháng"** | **"15 video kỷ niệm / tháng"** |
| grid | **"Mọi mẫu thiệp & video"** | same | same |
| check | **"Sửa, xác nhận nháp không tính thêm lượt"** (2 lines) | same | same |
| Price (Bold 34 `ink` + Medium 15 `ink-muted` **"/ tháng"**) | **"0đ"** | **"79.000đ"** | **"179.000đ"** |
| Sub (13) | Medium `ink-muted` **"Không cần thẻ thanh toán"** | SemiBold `mint-text` **"hoặc 790.000đ/năm · tiết kiệm 2 tháng"** | SemiBold `mint-text` **"hoặc 1.790.000đ/năm · tiết kiệm 2 tháng"** |
| Button (full width, `padding: 14px 22px; r 999`, SemiBold 16) | `surface` + 1 px `control-border`, **opacity 0.7**, `ink` **"Đang dùng"** | `mint-deep` / `on-mint-deep` **"Nâng cấp lên Plus"** | **#FCD66B** / `ink` **"Nâng cấp lên Pro"** |

Feature rows: `gap: 10px; align-items:flex-start`, icon 16 `mint-text`, Medium 15 / 1.45 `ink`. Arithmetic checks: 30 / 3 = 10, 300 / 3 = 100, 1 000 / 3 ≈ 333 → "≈ 330"; 79 000 × 10 = 790 000, 179 000 × 10 = 1 790 000 ("tiết kiệm 2 tháng" ✓).
Buttons on the web: **"Đang dùng"** is meaningless for a visitor (nobody is signed in on the site) — propose **"Bắt đầu miễn phí"** → download; "Nâng cấp lên Plus/Pro" cannot buy on the web (purchases are in-app through App Store / Google Play, D-072 #6, and not open yet, D-074) → link to the download section / store, with a line "Nâng cấp trong ứng dụng" (owner review).

### 8.4 "Ghi chú giá" 693:6453
Row `gap: 8px`: alert 14 `ink-muted` + Medium 13 `ink-muted` nowrap (864 px): **"Giá đã gồm VAT, thanh toán qua App Store / Google Play. Gói năm tiết kiệm 2 tháng. Huỷ gia hạn bất cứ lúc nào trong cài đặt cửa hàng."**

### 8.5 "Bảng so sánh" 651:5123 (1188 × 583)
`background: surface; r 24; overflow: hidden; shadow-card;` rows `padding: 16px 24px` (53 tall), cells: label **396**, Free **256**, Plus **256**, Pro **232**. Header row `#F2FAF7` (raw), SemiBold 15 / 1.4 `ink`; body rows alternate **#FBFEFC** / white (raw); label SemiBold 15 / 1.4 `ink`; values Medium 15 `ink`; ✓ = `mint-soft` circle `padding: 4px` + check 13 `mint-text`. **No ✗ anywhere — every feature is ✓ on every plan.**

| Row | Free | Plus | Pro |
|---|---|---|---|
| *(header, first cell empty)* | **"Free"** | **"Plus"** | **"Pro"** |
| ~~**"Giá mỗi tháng"**~~ (693:6106, Bold 15) — **hidden** in Figma (in the node tree, not in the render; overlaps the next row's position) | **"0đ"** | **"79.000đ"** | **"179.000đ"** |
| **"Lượt hỗ trợ mỗi tháng"** | **"30"** | **"300"** | **"1.000"** |
| **"Ghi nhật ký bằng một câu"** | ✓ | ✓ | ✓ |
| **"Hỏi đáp từ nhật ký của con"** | ✓ | ✓ | ✓ |
| **"Đọc ảnh hoá đơn, giấy dặn (≈3 lượt/ảnh)"** | ✓ | ✓ | ✓ |
| **"Nhìn lại mấy ngày & gợi ý cho hôm nay"** | ✓ | ✓ | ✓ |
| **"Tóm tắt tuần cho cả nhà"** | ✓ | ✓ | ✓ |
| **"Nhịp lớn lên của riêng con"** | ✓ | ✓ | ✓ |
| **"Mọi mẫu thiệp & video"** | ✓ | ✓ | ✓ |
| **"Xuất video kỷ niệm mỗi tháng"** | **"1"** | **"5"** | **"15"** |
| **"Ghi trực tiếp & hướng dẫn an toàn khi hết lượt"** | ✓ | ✓ | ✓ |

Implement as a real `<table>` (`<caption class="visually-hidden">So sánh các gói</caption>`, `<th scope="col">` with a visually hidden "Tính năng" in the empty corner, `<th scope="row">` labels, ✓ as an icon with `aria-label="Có"`). Ship the price row or not per owner (recommend: keep it hidden while prices are unconfirmed, §16).

### 8.6 "Lượt hỗ trợ là gì" 651:5271 (1188 × 246)
`surface; border 1px separator; r 24; padding: 28px 32px; gap: 32px;`
- Left 300 `gap: 8px`: `care-sleep-soft` box `padding: 8px; r 12` + spark 18 `care-sleep-ink`; Bold 22 `ink` **"Lượt hỗ trợ là gì?"**; Medium 14 / 1.5 `ink-muted` **"Mỗi lần Lumi làm việc cho bạn là một lượt. Lượt làm mới đầu mỗi kỳ."**
- Right "Quy tắc" `flex: 1; column; gap: 12px`: rows `gap: 12px; align-items:center` = Medium 15 `ink` label `flex: 1` + chip `padding: 6px 12px; r 999` SemiBold 13:

| Label | Chip (bg / text) |
|---|---|
| **"Một câu ghi nhật ký hoặc một câu hỏi"** | `cloud` / `ink` **"1 lượt"** |
| **"Đọc một ảnh hoá đơn, giấy dặn"** | `cloud` / `ink` **"≈ 3 lượt"** |
| **"Hỏi lại, sửa hay xác nhận nháp trong cùng việc"** | `mint-soft` / `mint-text` **"Không tính"** |
| **"Lỗi hệ thống, thử lại"** | `mint-soft` / `mint-text` **"Không tính"** |
| **"Hết lượt"** | `cloud` / `ink` **"Vẫn ghi trực tiếp, xem nhật ký bình thường"** |

Use a `<dl>`. These rules match the app's cost table (CH19 / `asCost*`) — see §16.

---

## 9. Hỏi đáp (651:5301, 1440 × 623)

`display:flex; gap: 72px; align-items:flex-start; padding: 96px;`
- Left 400 `gap: 14px`: eyebrow `mint-soft` / `mint-text` **"Hỏi đáp"**; H2 Bold 36 / 1.2 `ink` (2 lines) **"Những điều ba mẹ hay hỏi về Lumi."**
- List 776 `gap: 10px`: item `surface; r 18; padding: 18px 20px;` question SemiBold 16 `ink` `flex: 1` + icon 16 `ink-muted`.
  - **open** (1st): border 1 px **`mint`**, `gap: 10px`, icon **close**, answer Medium 15 / 1.55 `ink-muted`.
  - **closed**: border 1 px `separator`, icon **plus**.

| # | Question (verbatim) | Answer |
|---|---|---|
| 1 (open) | **"Lumi có tự ghi vào nhật ký không?"** | **"Không. Lumi soạn nháp, bạn xem lại và bấm lưu. Bạn có thể sửa hoặc bỏ từng bản."** |
| 2 | **"Hết lượt hỗ trợ thì sao?"** | *(none in Figma)* draft: "Bạn vẫn ghi trực tiếp và xem nhật ký như bình thường; hướng dẫn sức khoẻ thiết yếu vẫn mở. Lượt được làm mới đầu kỳ tiếp theo." |
| 3 | **"Gói Free có bị thiếu tính năng không?"** | *(none)* draft per the design's claim: "Không. Mọi việc Lumi làm đều có trong gói Free; các gói chỉ khác nhau ở số lượt mỗi tháng." — **conflicts with the app's Premium features (§16)** |
| 4 | **"Có thể đổi gói giữa chừng không?"** | *(none)* draft: "Có. Bạn đổi gói trong ứng dụng; gia hạn và huỷ do App Store / Google Play quản lý." — depends on store setup (D-074) |
| 5 | **"Ai trong nhà dùng chung lượt?"** | *(none)* draft: "Cả nhà dùng chung một quỹ lượt của hộ. Chỉ chủ hộ mua và quản lý gói." (D-072 #1, P-159) |
| 6 | **"Thông tin của con được dùng thế nào?"** | *(none)* draft: "Lumi chỉ đọc những gì bạn gửi và phần nhật ký bạn được quyền xem, để trả lời và soạn nháp. Bạn đồng ý trước khi dùng và tắt được bất cứ lúc nào." — **legal review (Q-070, P-160)** |

Drafts are engineering text for owner review (D-012); do not ship unanswered items. Reuse `sections/Faq.tsx` (native `<details>`), but it hard-codes `id="hoi-dap"`, the home title and the mail sub-line → add props for eyebrow / title / items and the open-item style (mint border, close icon). FAQPage JSON-LD (`seo.ts`) for the answered items only.

---

## 10. Kết (651:5338, 1440 × 415)

Section `padding: 0 96px` (bottom 3 raw → use 96, §0.1). Card 1248: `background: linear-gradient(156.24deg, #2BC4B5 14.286%, #545CDB 85.714%); r 40; padding: 56px; display:flex; gap: 48px; align-items:center;`
- Copy 640 `gap: 18px`: mascot 56; H2 Bold 40 / 1.18 **white** (2 lines) **"Để Lumi lo phần ghi chép. Bạn dành thời gian cho con."**; buttons `gap: 12px`: `surface` pill `padding: 14px 22px` SemiBold 16 `ink` **"Dùng thử Lumi"**; text button (no fill, `padding: 6px 0`) SemiBold 16 white **"Xem các gói"** → `#goi`.
- Photo 440 × 300 `r 28; surface-2; overflow:hidden`: library **Sun** `22456` at 440² top −70 (teddy bear and basket, no baby) — §12.
- **Contrast:** white on #2BC4B5 is ≈ 2.2 : 1 — fails WCAG even for 40-px bold (3 : 1) on the left third of the card, and the 16-px "Xem các gói" fails 4.5 : 1. Darken the start stop (e.g. `--lumi-deep` #086B73 → #545CDB) or add a scrim; ask design.

---

## 11. Footer (651:5367, 1440 × 184)
Same as the home footer: `padding: 32px 96px 40px; column; gap: 56px;` 1 px `separator`; bottom row `padding-top: 28px; justify-content: space-between;` lockup (mark 27.2) + Medium 14 `ink-muted` **"© 2026 Child Life"**; links `gap: 28px` Medium 14 `ink-muted` **"Quyền riêng tư"** · **"Điều khoản"** · **"Liên hệ"**. Reuse `Chrome.tsx` footer unchanged.

---

## 12. Image slots

| # | Node | Section | Slot | Figma | Depicts | Action |
|---|---|---|---|---|---|---|
| 1 | 691:5703/5704 | Một ngày · card 2 | 64 × 84, r 10 | Lib 220 **Sand** `5d2ff` at 84² | a newborn — **meant to be a receipt** | **Do not use a baby photo.** Draw a small receipt in HTML/CSS (white slip, 3–4 grey lines, "289.000đ" total, slightly rotated) or source a receipt photo (no real shop / personal data) |
| 2 | 691:5815/5816 | Một ngày · card 6 | 376 × 210 (r 18 via card), photo 376² top −83 | Lib 220 **Peach** `0d3f8` (×1.7, blurry) | parent kissing a baby | Teddy at one month: **`teddy-newborn-yawn.jpg`** (720 × 480, landscape, fits 376 × 210 at 2×≈ 752 — slightly soft) — matches the chip "Một tháng đầu của Teddy". Not `photos.peach` (= eight months) |
| 3 | 651:4905/4906 | Còn nhiều việc · card 1 | 56 × 70, r 8 | Lib 220 **Sand** at 70² | a newborn — **meant to be a paper note** ("giấy dặn") | HTML note (lined paper, 2 handwritten-style lines "Mua bỉm size M", "Khám 2 tháng 9h T5") — same strings as the chips, so it translates |
| 4 | 651:5360/5361 | Kết | 440 × 300, r 28, photo 440² top −70 | Lib 220 **Sun** `22456` (×2, blurry) | teddy bear in a basket | `photos.sun` = **`teddy-one-couch.jpg`** (720 × 480, 2× would need 880 × 600 → soft) or `teddy-eight-months.jpg` (860 × 548); prefer a parent-with-baby moment if one is added later |
| — | mascots, bubbles, drafts | all | — | vector / HTML | — | `lumi-mascot.svg` + HTML |

No new raster comes from Figma; all four slots are `Illustration/Photo` library placeholders. **No photo added.**

---

## 13. Route, page id, SEO, links, section ids (proposal — Figma defines none)

**Route** (`apps/landing/src/routes.ts`): page id **`'lumi'`** (add to `PageId`); paths **`/lumi/`** (vi) and **`/en/lumi/`** (en) — the product name needs no translation and stays short in shares. `isStage('lumi')` is false.

**SEO drafts** (`content/{vi,en}.ts` → `meta.lumi`, owner review):
- vi title: **"Lumi — trợ lý của cả nhà trong Child Life"**; description: **"Kể một câu, Lumi soạn sẵn bản ghi bú, ngủ, thay tã; chụp hoá đơn thành khoản chi; hỏi gì cũng trả lời từ nhật ký của con. Bạn xem lại rồi mới lưu."**
- en title: **"Lumi — your family's assistant in Child Life"**; description: **"Say it in one sentence and Lumi drafts the feed, sleep and nappy logs; snap a receipt and it becomes an expense; ask anything and it answers from your child's own logs. You review before anything is saved."**
- OG image: `og/{vi,en}-lumi.png` (extend `scripts/render-brand-assets.mjs`; `seo.ts` builds the URL from `route.page`). JSON-LD: `WebPage` + `FAQPage` (answered items). **No `Offer` / price markup** until prices are confirmed (§16).

**Linked from:**
- Nav **"Lumi"** on every page (home v6 nav `649:7235` has it too) → `pathOf('lumi', locale)`; `current` on this page.
- Home Lumi block (inside the Chặng 1 frame, `649:7271`) button **"Khám phá Lumi"** (`649:7299`) → `/lumi/`.
- Home journey block (`678:5614`) button **"Khám phá Lumi hôm nay"** → `/lumi/`.
- Optionally the footer (not in Figma).

**Nav targets on the Lumi page:** "Hành trình" → `${homePath}#hanh-trinh`; "Năm đầu đời" → as on the other non-home pages (`${homePath}#nam-dau-doi`, or the Chặng 1 page — follow the home v6 spec 32); "Lumi" → current; "Các chặng" → `${homePath}#cac-chang`; "Kỷ niệm" → `${homePath}#ky-niem`; **"Hỏi đáp" → local `#hoi-dap`** (this page has its own FAQ, like the Chặng 1 page); **"Tải miễn phí" → local `#tai-app`** (put the id on the Kết card).

**Section ids:** `#gioi-thieu`, `#loi-ich`, `#mot-ngay`, `#viec-khac`, `#suot-hanh-trinh`, `#cach-lam-viec`, **`#goi`** (target of hero "Nâng cấp gói" and Kết "Xem các gói"), `#hoi-dap`, `#tai-app`. Heading ids `lumi-title`, `benefits-title`, `day-title`, `more-title`, `journey-lumi-title`, `how-title`, `plans-title`, `faq-title`.

**Files (proposal):** `pages/LumiPage.tsx`; sections `LumiHero`, `LumiBenefits`, `LumiDay`, `LumiMore`, `LumiJourney` (shared with Home), `LumiHow`, `LumiPlans` (toggle, cards, note, table, credits), `LumiCta`; atoms in `components/lumi.tsx` (`LumiMascot`, `Bubble`, `LumiTurn`, `DraftRow`, `SourceChip`); styles `styles/lumi.css`; content `content.lumi` typed in `content/types.ts`.

---

## 14. Mobile — PROPOSAL (no mobile frame)

Same breakpoint as the rest of the site (`< 1120`), patterns of `28` §8 / `22` §8. 375 viewport, 20-px gutter (335 content). Needs design sign-off.

- **Nav:** unchanged mobile nav (logo + EN + "Tải app", no links).
- **Hero:** stacked, `padding: 24px 20px 48px; gap: 28px`. Eyebrow row (mascot 40 + pill, wraps if needed); H1 Bold 36 / 1.12 (two lines kept as two `<span>` blocks, each may wrap); lead Medium 16 / 1.55; CTAs full width stacked `gap: 10px` (primary first); chips wrap (`flex-wrap; gap: 8px`). Mockup below: keep the 544 × 721 composition and scale with `Fit` to 335 wide (× 0.616 → 444 tall) with the two floats pulled inside the box (float "Đã lưu" at left 8; expense float right 8) so nothing overflows the viewport; or show only the chat card at 335 (× 0.84).
- **Lợi ích:** head left-aligned, H2 Bold 28 / 1.2; cards 2 × 2 grid at ≥ 560, single column below, `padding: 20px`, title 18.
- **Một ngày:** head stacked (eyebrow, H2 Bold 28 / 1.2, lead 15); six cards as a **horizontal snap carousel** (card 300, `scroll-snap-align: start`, 20-px inset, 12-px gap, next card peeking), illustration rendered at 376 × 210 and scaled ×0.766 (288 × 161), body full size (title 18, body 14).
- **Còn nhiều việc:** same carousel pattern (card 260, illustration 273 × 170 at ×0.88) or 1-column stack (4 × ≈ 330 = 1 320 px — prefer the carousel).
- **Lumi suốt hành trình:** block `margin: 0 10px; padding: 32px 16px 20px; r 32; gap: 24px`; head stacked (H2 Bold 24 / 1.2, lead 15); **path hidden** (it only echoes the cards); stage cards in a horizontal snap row (card 272 unchanged, 12-px gap) so the dashed "định hướng" cards read as "more to come"; closing bar stacked, button full width.
- **Cách Lumi làm việc:** dark card `margin: 0 10px; r 32; padding: 36px 20px; gap: 28px`; H2 Bold 28 / 1.2, **wrapping** (drop `nowrap`); steps stacked `gap: 12px`; trust lines stacked `gap: 14px`.
- **Gói:** head left-aligned or centred (H2 Bold 28 / 1.2, lead 16); toggle centred full width (two equal segments). Plan cards: horizontal snap carousel (card 300) **starting on Plus** (`scrollIntoView` on load, or order Plus · Free · Pro on mobile only) — or stacked (3 × 557). Price note wraps (no nowrap), 12 px. **Comparison table:** a plan switcher (segmented Free / Plus / Pro, default Plus) above a 2-column list (label · value), or a horizontally scrollable table with the label column `position: sticky; left: 0` (min width 560). "Lượt hỗ trợ là gì": stacked; each rule = label on one line, chip below (`align-items:flex-start`).
- **Hỏi đáp:** stacked (`gap: 24px`), H2 Bold 28 / 1.2, items full width.
- **Kết:** card `margin: 0 10px; r 32; padding: 32px 20px; column; gap: 24px`; H2 Bold 28 / 1.18; buttons stacked full width ("Xem các gói" as an outline-white pill); photo full width 300 × 200 below (or hidden).
- **Footer:** existing mobile footer.

---

## 15. Copy keys (proposal) and English drafts

New `content.lumi` (types in `content/types.ts`, vi = Figma verbatim, en = engineering drafts for owner review, D-012):

| Key | vi (verbatim) | en draft |
|---|---|---|
| `nav.links.lumi` | "Lumi" | "Lumi" |
| `hero.eyebrow` | "Lumi · Trợ lý đồng hành trong Child Life" | "Lumi · The helper inside Child Life" |
| `hero.title` | ["Kể một câu.", "Lumi ghi giúp, nhớ giúp."] | ["Say it once.", "Lumi logs it and remembers it."] |
| `hero.lead` | §2.1 | "Lumi is the whole family's assistant in Child Life. Type as if you were texting, snap a photo or ask a question — Lumi drafts the logs, answers from your child's own records and suggests one small thing for today." |
| `hero.try` / `hero.plans` | "Dùng thử Lumi" / "Nâng cấp gói" | "Try Lumi" / "See plans" |
| `hero.promises` | 3 chips §2.1 | "You confirm before it's saved" · "Answers from your child's logs" · "The family uses it by role" |
| `hero.mock` | every string §2.2 | "Teddy's family assistant"; "Fed 120 ml at 9, asleep from 9:30, nappy at 10"; "I drafted 3 logs — check them, then save:"; "Bottle · 120 ml" / "9:00", "Sleep" / "from 9:30", "Nappy" / "10:00", "Draft", "Save all 3"; "Bedtime has been hard these past few days"; "On 2 of the last 3 evenings you noted “hard to settle”, both after 9 pm. Want to look at the sleeps around then?"; "Tell, ask or send Lumi a photo…"; "3 logs saved"; "Nappies · 289,000 ₫" / "From a receipt photo → Spending"; "Sample conversation" |
| `benefits` | §3 | "What Lumi does for your family" / "Less to remember, more time with your child." / "Quick when your hands are full" — "One sentence instead of many taps. Lumi splits it into the right logs."; "Understand your child from your own logs" — "Lumi answers from what your family has logged, with the source to open."; "One small thing for today" — "Ideas that fit your child's age and what you've logged — you pick what suits you."; "Keep every moment" — "Turn photos on your phone into cards and short films for the first milestones." |
| `day` | §4 | "A day with Lumi" / "From the first morning feed to the end-of-month video." / "Six familiar moments, each needing just a sentence or a photo." Cards: "Holding the baby, still logging" — "Say one sentence, Lumi drafts the log."; "Receipts become expenses" — "Snap the receipt, Lumi fills in the amount."; "Ask and know" — "Answers from your logs, with the source to open."; "What should they eat today?" — "Age-appropriate dishes that avoid what your child reacted to."; "Bedtime has been hard lately" — "Lays recent notes side by side."; "A month old, a little film" — "Pick photos and a template for a one-month video." Mock strings translated 1:1 ("Open source log", "Pumpkin congee", "Mashed sweet potato", "6 sleeps", "2 notes", "Teddy's first month · 0:45", "Blurry date on the receipt — Lumi asks before saving.", "End of month") |
| `more` | §5 | "And much more" / "Lumi grows with your family." / "The more you log, the better Lumi knows your family's rhythm — to remind you at the right time and suggest things that fit." Cards: "Note photo → reminders"; "Weekly summary for the family"; "Your child's own rhythm"; "Childcare Q&A" (bodies translated 1:1; "Stage 2 (Wonder Weeks) · reference") |
| `journey` (shared) | §6 | "Lumi stays with your child the whole way" / "As your child grows, Lumi grows too." / lead; stage leads and items translated 1:1; "Available" / "Planned"; "Start today. The next stages are on their way." / "Everything above is a direction we are building. Scope and timing will be updated stage by stage."; CTA "Try Lumi today" (Lumi page) / "Discover Lumi today" (home) |
| `how` | §7 | "How Lumi works" / "Lumi drafts. You decide." / "Tell, ask or snap" — "Type like a message, or send a receipt or a note."; "Lumi drafts" — "Puts each thing in the right place and asks about anything missing or unclear."; "You review and save" — "Edit, drop or save each one. Lumi never saves on its own."; trust: "Only your family, with the access you give"; "Photos sent to Lumi are only read for their content; you choose whether to keep the original"; "Lumi is not a doctor. When you're worried about health, Lumi points you to safety guidance and the emergency number" |
| `plans` | §8 | "Plans" / "Everything Lumi does, for every family." / "The three plans differ only in monthly help. Pick what fits your family's pace — switch any time." / "Monthly" · "Yearly"; "To get started" / "For busy days" / "For the whole family"; "help credits / month"; "Everything Lumi can do"; "≈ 10 receipt or note photos"; "1 memory video / month"; "All card & video templates"; "Editing and confirming drafts costs nothing extra"; "/ month"; "No card needed"; "or 790,000 ₫/year · 2 months free"; "Current plan" (→ proposal "Start free"); "Upgrade to Plus" / "Upgrade to Pro"; note "Prices include VAT, paid through the App Store / Google Play. The yearly plan saves 2 months. Cancel renewal any time in your store settings."; table rows "Price per month", "Help credits per month", "Log with one sentence", "Q&A from your child's logs", "Read receipt and note photos (≈3 credits/photo)", "Look back over recent days & today's suggestion", "Weekly family summary", "Your child's own rhythm", "All card & video templates", "Memory video exports per month", "Direct logging & safety guidance when credits run out"; "What is a help credit?" / "Each time Lumi does something for you uses one credit. Credits refresh at the start of each period." / rules "One log sentence or one question" "1 credit"; "Reading one receipt or note photo" "≈ 3 credits"; "Follow-ups, edits or confirming drafts in the same task" "Free"; "System error, retry" "Free"; "Out of credits" "Keep logging directly and viewing logs as usual" |
| `faq` | §9 | "FAQ" / "What parents often ask about Lumi." / "Does Lumi write to the log by itself?" — "No. Lumi drafts, you review and tap save. You can edit or drop each one."; "What happens when I run out of credits?"; "Is anything missing from the Free plan?"; "Can I switch plans mid-way?"; "Who in the family shares the credits?"; "How is my child's information used?" |
| `cta` | §10 | "Let Lumi handle the note-taking. You spend the time with your child." / "Try Lumi" / "See plans" |

Naming: the app calls the unit **"lượt hỗ trợ AI"** / "AI help" (`asUsageTitle`); the page says **"lượt hỗ trợ"**. The EN app string is "AI help"; "help credits" above is a draft — align with the app's EN wording once the owner picks one.

---

## 16. Prices, plans and credits — page vs app / product docs

Verbatim on the page: plans **"Free"** ("Để bắt đầu"), **"Plus"** ("Cho ngày nhiều việc"), **"Pro"** ("Cho cả nhà dùng nhiều"); credits **"30"** / **"300"** / **"1.000"** **"lượt hỗ trợ / tháng"**; photos **"≈ 10"** / **"≈ 100"** / **"≈ 330"**; videos **"1"** / **"5"** / **"15"** **"video kỷ niệm / tháng"**; prices **"0đ"** / **"79.000đ"** / **"179.000đ"** **"/ tháng"**, **"hoặc 790.000đ/năm · tiết kiệm 2 tháng"**, **"hoặc 1.790.000đ/năm · tiết kiệm 2 tháng"**, **"Không cần thẻ thanh toán"**; note **"Giá đã gồm VAT, thanh toán qua App Store / Google Play. …"**.

| # | Topic | Lumi page (Figma 650:4798) | App / product docs | Conflict |
|---|---|---|---|---|
| 1 | Plan model | **3 tiers: Free · Plus · Pro** | **One paid plan "Child Life Premium"** per household, monthly or yearly (`pmPlanPremium`, `pmPaywallSubtitle` "Một gói cho cả hộ…"; CH22 annotation "Một gói Premium (tháng/năm cùng quyền lợi)"; PR01 "Một SKU/entitlement"); entitlement plans `free` / `premium` / `beta` (`assistant-staff.ts`) | **Yes — structural.** Two paid tiers do not exist in contracts, entitlements, paywall, portal or ledger |
| 2 | Free credits | **30 / tháng** | **20 / calendar month** (P-159; `defaultEntitlementsConfig.quotas.assistant.free = 20`; CH19 "15 / 20") — QA value, Q-071 open | **Yes** (30 ≠ 20) |
| 3 | Paid credits | Plus **300**, Pro **1.000** per month | Premium **200 per paid period** (P-159; `premium: 200`; CH23 "200/200" fixture; CH22 "Hạn mức trợ lý cao hơn mỗi kỳ (chưa chốt)") | **Yes** |
| 4 | Prices | **79.000đ / 179.000đ per month; 790.000đ / 1.790.000đ per year** | **No price decided** — Q-071 open (SKUs, price, intro offer, quotas); PR01 "⚑ Chưa chốt: giá, SKU tháng/năm, quota"; P-152 "prices from the storefront only"; the exploratory paywall PW01 `603:6187` shows **"US$39.99/năm"** (`30-personalization-premium.md` appendix "Premium exploration") | **Yes — unapproved prices.** Owner decision needed before any price is published; storefront prices (with local tax rounding) must match the site |
| 5 | Payments live | "thanh toán qua App Store / Google Play", "Huỷ gia hạn … trong cài đặt cửa hàng", "đổi gói bất cứ lúc nào" | **Real payments later** (D-074): store gateway "not open yet", `premium_billing` off; `pmPlanBuySoon` "Mua và quản lý gói ngay trong app sẽ có ở bản sau." | **Yes** — the page sells something the app cannot sell yet; plan switching (upgrade/downgrade proration between two tiers) is undesigned |
| 6 | Reset period | "lượt hỗ trợ / tháng", "Lượt làm mới đầu mỗi kỳ" | Free: monthly on the 1st in household time (`asUsageResetFree`); Premium: **per Premium period** (`asUsageResetPremium` "Làm mới {date} theo kỳ Premium") — a yearly subscriber's period is a year | **Yes** for yearly plans: "300 / tháng" on a yearly plan needs monthly refills inside a yearly period (not built) |
| 7 | Video exports | 1 / 5 / 15 per month | video quota **free 1 / calendar month, premium 5 / billing period** (`quotas.video`, P-152); separate from AI credits (`asVideoQuotaSub`) | Free 1 ✓; Plus 5 ≈ premium 5 but per *period*; **Pro 15 does not exist** |
| 8 | Credit costs | text/question 1, photo ≈ 3, follow-ups / edits / confirm free, system error free, out of credits → still log directly | text 1, image 3 (`textCredits 1`, `imageCredits 3`), follow-ups / confirm free, error / retry free, unreadable photo 0, health 0 (CH19, CH21, CH28, P-159) | ✓ consistent. The page omits "unreadable photo 0" and "health guidance free" (could add) |
| 9 | "Ba gói chỉ khác nhau ở số lượt", "Tất cả việc Lumi làm được", table all ✓ | Premium carries **group A "Cá nhân hoá & Nhịp lớn lên nâng cao"** (`pmGroupA1` "Một việc phù hợp mỗi ngày từ ghi nhận của nhà mình", `pmGroupA2` handover, `pmGroupA3` "Tóm tắt AI có căn cứ") and **group B "Mẫu thẻ & video Premium"** (`pmGroupB1` "Toàn bộ thư viện mẫu Premium", `pmGroupB2` "Thêm lượt xuất video mỗi kỳ"); Free = "mẫu cơ bản" (`pmPaywallFreeBody`) | **Yes.** "Mọi mẫu thiệp & video" ✓ on Free contradicts Premium templates (★ Cao cấp, Q-072); "Nhìn lại mấy ngày & gợi ý cho hôm nay", "Nhịp lớn lên của riêng con" ✓ on Free contradict group A. D-075 #1 allows a *beta* to give every Premium feature for free — the page would then describe a temporary campaign as the permanent offer. Also D-076 #9 forbids "Miễn phí / Luôn miễn phí" labels on Premium-feature screens |
| 10 | Who buys | (not said) FAQ "Ai trong nhà dùng chung lượt?" | household pool (P-159); **only the family owner buys and manages** (D-072 #1) | Answer must say so (draft §9) |
| 11 | Unit name | "lượt hỗ trợ" | "Lượt hỗ trợ AI" / EN "AI help" | Minor naming difference |
| 12 | Money format | "79.000đ", "289.000đ" | app Chi tiêu "1.020.000 ₫" (P-140); the landing's spending mock uses "4.215.000 ₫" | Pick one for the site (₫ with a space for amounts in mocks; prices as the store shows them) |

**Recommendation:** do not ship §8 (or its prices) until the owner decides Q-071 and whether the business model becomes Free / Plus / Pro. If the page must launch first, ship it without the pricing section (hero "Nâng cấp gói" and Kết "Xem các gói" then point to the in-app paywall copy, or are removed) and with the credit rules (§8.6) only.

---

## 17. Copy claims vs `docs/product/business-map.md`

No R-170-style entry covers a Lumi page; R-170 / R-171 must gain a Lumi section. Claims with no D / R entry or in conflict:

| # | Claim (verbatim) | Map / app support | Conflict / gap |
|---|---|---|---|
| 1 | Pricing, tiers, VAT, store billing, "đổi gói bất cứ lúc nào" | Q-071 open, D-074, D-072 #6 | §16 rows 1–7; VAT statement and store-cancel copy need legal |
| 2 | "Ba gói chỉ khác nhau ở số lượt…", "Mọi việc Lumi làm, nhà nào cũng dùng được.", FAQ "Gói Free có bị thiếu tính năng không?" | Premium groups A/B; Q-072; D-075 #1 (beta) | §16 row 9 |
| 3 | "Lumi là trợ lý của cả nhà", "Cả nhà dùng theo quyền", "Chỉ người trong nhà, theo quyền bạn cấp" | D-075 #2 one shared conversation per baby for Cùng nuôi + caregiver; spending private; P-160 per-person consent | Mostly ✓; relatives (viewers) only ask, never log (`asLumiIntroBodyViewer`); caregiver cannot generate AI summaries (D-072 #2) — "cả nhà" is broader than the rules |
| 4 | "Lumi soạn nháp … Lumi không tự lưu", "Bạn xác nhận trước khi lưu" | Draft-and-confirm (31; P-156) | ✓ — but 31 lists two exceptions that write on tap (CH27 "Lưu thành nhắc việc", CH17 feedback chips); keep the absolute claim only if those are fixed |
| 5 | "Trả lời từ nhật ký của con", "kèm nguồn để mở lại", "Mở nhật ký nguồn" | CH08 (answer over logs) | ✓ — CH08 has the "Mở nhật ký nguồn" link (31 §CH08); R-136 "AI never invents facts" is product-plan only |
| 6 | "Gợi ý vừa sức theo tuổi và những gì bạn đã ghi", "Một việc nhỏ cho hôm nay", "Nhìn lại mấy ngày & gợi ý cho hôm nay" | Personalization engine (plan §5.4), group A Premium | Premium in the app (§16 row 9); content still "chờ chuyên môn duyệt" (D-073 #2, Q-069) |
| 7 | "Giữ lại từng khoảnh khắc — Từ ảnh trong máy thành thiệp, đoạn phim nhỏ…", "Tròn tháng, thành phim nhỏ — Chọn ảnh và mẫu, có ngay video đầy tháng.", "Một tháng đầu của Teddy · 0:45" | D-068 Video kỷ niệm & Thiệp cột mốc; D-076 #3 weekly video | Features exist, but **they are not Lumi (the chat assistant)**: the page attributes memory videos to Lumi. Premium templates (Q-072). Decide whether "Lumi" names only the assistant (31, D-076 #11) or a wider AI brand |
| 8 | "Hoá đơn thành khoản chi", "Chụp hoá đơn, Lumi điền sẵn số tiền.", "Ngày trên hoá đơn mờ — Lumi hỏi lại trước khi lưu." | CH09–CH12; D-075 #4 currencies | ✓ (Chi tiêu is Cùng nuôi only, D-055 — "cả nhà" again) |
| 9 | "Ảnh gửi cho Lumi chỉ để đọc nội dung, bạn chọn có giữ ảnh gốc hay không" | CH "Giữ ảnh hoá đơn" toggle; **D-075 #3: receipt photos are kept with the expense** | **Conflict**: after D-075 #3 the photo is kept by default; "bạn chọn" holds only if the toggle still exists — confirm. Provider retention (G05, Q-070) also needed before "chỉ để đọc nội dung" |
| 10 | "Hôm nay con ăn gì? — Món hợp tuổi, tránh món con từng phản ứng.", "Gợi ý cho bé 7 tháng, đã bỏ trứng vì từng ghi nổi mẩn:", "Cháo bí đỏ", "Khoai lang nghiền" | P-157: **no meal log or recipes yet** → MODULE_UNAVAILABLE / "chưa có công thức được duyệt"; CH18 flagged the allergy case with no professional referral | **Conflict / over-claim**: recipes not available; avoiding allergens is a health claim needing medical review (D-058 pattern). Also **"Na" is "3 tuổi"** in the watch design (W12 `465:157`) but "bé 7 tháng" here |
| 11 | "Mấy hôm nay con khó ngủ — Đặt các ghi nhận gần đây cạnh nhau.", "3 tối gần đây có 2 lần bạn ghi “khó vào giấc”…" | CH15–CH16 (sleep question, observations) | ✓ |
| 12 | "Ảnh giấy dặn → nhắc việc", "Mua bỉm size M · thứ Bảy", "Hẹn khám 2 tháng · 9h T5" | CH13; D-075 #5 date-only + assignee | ✓ once D-075 #5 ships ("thứ Bảy" is date-only) |
| 13 | "Tóm tắt tuần cho cả nhà … gửi ông bà theo quyền", "Tuần này của Teddy" | D-076 #3 weekly summary EN09 (notification centre) | "**gửi** ông bà" — the summary is in-app for members; sending to relatives is not specified (who receives it, which roles) |
| 14 | "Nhịp lớn lên của riêng con", "Giai đoạn 2 (Wonder Weeks) · tham khảo", "Giai đoạn N (Wonder Weeks) chỉ để đối chiếu." | D-072 #7 (label rule ✓); rights check is a release gate | Wording ✓; Premium in the app (group A); Wonder Weeks name/model rights still open before prod |
| 15 | "Hỏi đáp chăm bé — Lumi trả lời từ thư viện nội dung và chỉ đường đến hướng dẫn an toàn khi cần.", mock "(nội dung minh hoạ · chờ duyệt)" | Thư viện chăm bé D-076 #7; D-073 #2 review pending | Content unreviewed; the mock ships a review label on a marketing page — replace with a reviewed sample before prod |
| 16 | "Lumi không thay bác sĩ … số khẩn cấp" | CH28; P-141 (115 as a pack field) | ✓ (emergency number is per region) |
| 17 | "Lumi lớn lên cùng nhà bạn. Càng ghi nhiều, Lumi càng hiểu nếp nhà bạn để nhắc đúng lúc và gợi ý sát hơn." | P-155: the model only extracts and words; no long-term AI memory; reminders are user-created | **Over-claim**: implies learning and proactive reminders by Lumi; no D/R entry |
| 18 | Journey block: stage 2–4 Lumi features ("Định hướng"), "Các trải nghiệm trên là định hướng đang được phát triển…" | Q-039 (stages 2–4 roadmap) | Disclaimer present ✓; extend Q-039 with these Lumi items (also on the home) |
| 19 | FAQ "Thông tin của con được dùng thế nào?" | P-160 consent, P-155 `store:false`, Q-070 (provider, consent and retention text) open, no child data in logs | Answer requires legal/privacy sign-off; do not promise "không dùng để huấn luyện" without the provider terms |
| 20 | "Đã lưu 3 bản ghi vào Nhật ký", "nhật ký của con" for care logs | App: care records live in Hôm nay / Lịch sử; **"Nhật ký" is the memories journal tab** (D-052); the chat designs also say "nhật ký" for care logs (CH21) | Naming ambiguity; pick one term with the app team |

Owner decisions needed: (1) business model — keep "one Premium" or adopt Free / Plus / Pro (then contracts, entitlements, paywall, portal, ledger all change); (2) prices and credit amounts (Q-071) and whether the site shows prices at all before store billing exists (D-074); (3) whether Free really includes "mọi mẫu thiệp & video" and the personalization features (Q-072, group A/B); (4) whether "Lumi" covers memory videos / cards or only the assistant; (5) recipe / allergen claims; (6) receipt-photo retention wording after D-075 #3; (7) FAQ answers 2–6; (8) the "Lumi learns your family" claim.

---

## 18. Ambiguities and design bugs (implementation)

1. **No mobile and no English frame** (§14, §15 are proposals).
2. Top padding 0–4 px on Lợi ích, Một ngày, Còn nhiều việc, Gói; Kết bottom 3 px (§0.1).
3. Cách: steps row (1126) and trust row (1190) overflow the 1120 inner width (§7).
4. Kết: white text on the teal end of the gradient fails contrast (§10).
5. Comparison table "Giá mỗi tháng" row is hidden (§8.5); decide.
6. "Theo năm" state not drawn (§8.2).
7. Free button "Đang dùng" (opacity 0.7) is meaningless on the web; upgrade buttons cannot purchase on the web (§8.3).
8. Expense drafts use the cloud-off (offline) icon (§0.5).
9. Library baby photos stand in for a receipt and a paper note (§12 rows 1, 3); the Kết photo is a teddy bear; two slots are upscaled ×1.7–2.
10. Hero mockup floats overhang the 544 box (−40 left, +30 right) — fine at 1440, must be contained on narrow screens.
11. Child names: "Teddy" everywhere except Một ngày card 4 "Na" (7 months here, 3 years in the watch design).
12. Lumi gradient angles vary (127–156°) — normalise.
13. Mascot colours differ slightly between Figma and the app painter (§0.3).
14. FAQ: five of six answers missing (§9).
15. The journey block is shared with the home: keep one component, CTA label by prop (§6).
16. Nav current style ("Lumi" Bold `mint-text`) is new; other links are now `ink` (v5b: `ink-muted`) — check the home v6 nav colour in spec 32 and apply consistently.
17. Content width alternates 1248 (most sections) and 1188 (Gói) — follow the design.

---

## 19. Sibling frames (English / mobile variants)

- The document's page list (`get_metadata` without a node) returns only **"Cover" `0:1`** and **"Logo" `33:2`** (as noted in 20 / 21), so the parent canvas of `650:4798` could not be listed directly. Canvases checked by id: `0:1` Cover, `345:35701` "v1.0 - improvement", `464:18` "Apple Watch", `568:18` "Cá nhân hoá & Nhịp lớn lên" — **none contains `650:4798` or `649:6251`**; guessed ids `321:18`, `219:18`, `219:2`, `649:6250`, `459:3537` do not exist.
- Known frames at y 37000 on that unlisted canvas: **`649:6251` "Landing v6 · Desktop · Lumi"** (home, 1440 × 11550, at x 0) and **`650:4798` "Lumi · Trang chi tiết · Desktop · VI"** (at x 1640). The "· VI" suffix suggests an EN (and maybe a mobile) frame is planned, but **no "Lumi" EN or mobile frame was found**. To confirm, ask the owner for a link to the canvas (any node URL on it gives the page via the URL's `node-id`).
- Related nodes elsewhere: mascot component set `628:9074` (`Chat/Nút trợ lý`), app FAB `627:62667`, first-run tooltip `669:64442` (D-076 #11); home Lumi block `649:7271` (inside the Chặng 1 frame) and home journey block `678:5614`.
