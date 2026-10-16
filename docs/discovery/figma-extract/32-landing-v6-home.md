# 32 — Landing v6 home page (Lumi in Chặng 1, Lumi suốt hành trình, illustrated stage art)

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only, no node modified). Extracted 2026-10-15. Same conventions as `28-landing-v5b-home.md`: token names from `07-foundations-components-motion.md` / `packages/design-tokens/dist/tokens.css`, non-token values marked **(raw)**, every visible string copied **verbatim from `get_design_context`**. Layer names are stale and partly corrupted by a find/replace: frames "Chi tiêu cho bé" / "Chi tiêu vis" are now named "Lumi tiêu cho bé" / "Lumi tiêu vis" and the receipt sub-line layer is "Lumi tiêu · hôm nay", but the **text** is unchanged ("Chi tiêu · hôm nay", "Sổ chi tiêu chung cho bé"). The Hành trình lead layer reads "…, Lumi" but the text still says "Child Life".

> File number: `31-chat-assistant.md` is the last one, so this doc takes **32**; the Lumi detail page (`650:4798`) is extracted separately as **33**. This doc **supersedes 28 for the home page**; 28 §3.1–§3.6 (Chặng 1 frame contents), §5 (Lớn lên band + Cách giữ kỷ niệm), §6 (FAQ) and 25 §3 (watch) still specify everything this doc marks "unchanged".

- Desktop frame **`649:6251` "Landing v6 · Desktop · Lumi"**, 1440 × **11550.2** (v5b `475:3726` was 1440 × 9250). **Desktop only, no mobile frame** — §9 is a proposal.
- What changed, in one line: the nav swaps **"Apple Watch" → "Lumi"** (accent colour, the only real link in the nav); a **new Lumi block "Gặp Lumi — trợ lý nhỏ cho năm đầu đời của con."** sits inside the Chặng 1 frame between Theo cách and the Apple Watch card (1244 × 1207: head + suggestion orbit + six feature cards with chat mocks); **Các chặng tiếp theo** grows a "Lumi ở chặng này" row on each stage card and a **new block "Lumi · suốt hành trình"** (1248 × 1026: Lumi across the four stages); **all stage art is now vector illustration** (Hành trình's four cards and Các chặng's three cards — the photo / icon / placeholder slots are gone); Lớn lên loses its top padding. Hero, CTA, FAQ, Footer and every string outside the new blocks are unchanged.
- As before: no motion, no hover/focus, no tablet frame. Light page, `cloud` #F6FCFB. Unlike v5b, several new elements are `<a>` in `get_design_context` (= they carry a link or prototype reaction): the nav "Lumi", "Khám phá Lumi", "Khám phá Lumi hôm nay" and the three "Lumi ở chặng này" rows. The destinations are not exposed by the read tools; the Lumi page `650:4798` is the obvious target (§8).

Screenshots (not committed, scratchpad `…/scratchpad/v6/`): `full/v6-full.png` (1:1, 1440 × 11551), `d-nav.png`, `d-hanh-trinh.png` (1440 × 806), `d-chang1.png` (whole section 1440 × 4613), `d-lumi-chang1.png` (1440 × 1207), `d-cac-chang.png` (1440 × 2175), `d-cac-chang-cards.png` (1440 × 654), `d-lumi-hanh-trinh.png` (1440 × 1026), `d-lon-len.png` (1440 × 1686), `d-hoi-dap.png` (1440 × 964). All are crops of the 1:1 `get_screenshot` render of `649:6251`.

Method: today's metadata (`scratchpad/v6/a.xml`) and the v5b dump (`scratchpad/v5/v5b.xml`) were parsed, normalised (ids stripped, coordinates rounded) and diffed per section (`scratchpad/v6/norm/`); the full 1:1 render was pixel-diffed per region against the v5b 1:1 render (threshold 24/255) — every region outside the changed blocks is at anti-aliasing noise level (≤ 0.5 % of its pixels, scattered). `get_design_context` read in full: Nav `649:6252`, Hero copy `649:6266`, Hành trình `649:6337`, Lumi block `649:7270` (52 KB, wrapper styles) with its head `649:7272` and features `649:7345`, the three stage cards `649:6853` / `649:6875` / `649:6898`, Lumi · suốt hành trình `678:5614`, Hỏi đáp `649:7172`, plus spot checks of the band body `649:6927`, the Kỷ niệm lead `649:6951` and the CTA sub `649:7154` (all unchanged). `download_assets` on the mascot instance `676:5571`, the four Hành trình illustrations `688:18 / 688:39 / 688:60 / 688:88` and the three Các chặng illustrations `684:537 / 684:568 / 684:600`.

---

## 0. Global

### 0.1 Section order

| # | Section | Node | h (y) | v5b | Status | Id (proposed) |
|---|---|---|---|---|---|---|
| 1 | Nav | 649:6252 | 87 (0) | 87 | **changed** — "Lumi" replaces "Apple Watch" (§1) | — |
| 2 | Hero | 649:6265 | 668 (87) | 668 | identical (copy verified, §2) | `#gioi-thieu` |
| 3 | Hành trình | 649:6337 | 806 (755) | 806 | **art changed** — vector illustrations (§3) | `#hanh-trinh` |
| 4 | Chặng 1 · Năm đầu đời | 649:6438 → frame 649:6439 | **4613** (1561) | 3382 | **+ Lumi block** `649:7270` (§4) | `#nam-dau-doi`; **`#lumi`** on 649:7270 |
| 5 | Các chặng tiếp theo | 649:6826 | **2175** (6174) | 1026 | **cards changed** (§5) + **new "Lumi · suốt hành trình"** `678:5614` (§6) | `#cac-chang`; **`#lumi-hanh-trinh`** on 678:5614 |
| 6 | Lớn lên cùng con | 649:6921 | **1686** (8349) | 1766 | **top padding 80 → 0** (§7), content identical | `#lon-len`, `#ky-niem` |
| 7 | CTA | 649:7150 | 367 (10035) | 367 | identical | `#tai-app` |
| 8 | Hỏi đáp | 649:7172 | 964 (10402) | 964 | identical — 9 questions, 2 open (§2) | `#hoi-dap` |
| 9 | Footer | 649:7216 | 184.2 (11366) | 184.2 | identical | — |

Height delta: +1231 (Lumi block 1207 + 24 gap) + 1149 (Các chặng: cards +75, Lumi journey 1026 + 48 gap) − 80 (Lớn lên) = +2300.

Vertical rhythm: Hero (48 bottom) → Hành trình `64 / 64` → Chặng 1 wrapper `16 48 24` → Các chặng `64 96 80` (now with two blocks, gap 48) → **Lớn lên `0 48 80`** (the band starts right after Các chặng's 80-px bottom padding) → CTA → Hỏi đáp `64 96 80` → Footer.

### 0.2 Text styles
New sizes on the page: **Bold 40 / 1.18** (Lumi head title), **Bold 34 / 1.2** (Lumi journey title), **Bold 19 / 1.25** (Lumi feature card titles), **Bold 20 / 1.25** (journey stage names, outro title), SemiBold 11 (stage / status chips, "Lumi ở chặng này"), Medium 13 / 1.4–1.45 (chat bubbles), Medium 11 / 1.4 (receipt footnote). Everything else re-uses existing styles (eyebrow SemiBold 13, lead Medium 18 / 1.55, Medium 16 / 1.55, Medium 14 / 1.5–1.55, SemiBold 14 / 16).

### 0.3 Colours
Tokens: `care-sleep-soft` / `care-sleep-ink` (Lumi eyebrows, "Lumi ở chặng này", stage-4 chips), `mint-deep` + `on-mint-deep` (buttons, parent bubbles, "Đang có"), `mint` (stage-1 column border), `mint-text`, `mint-soft`, `care-bottle-soft` / `care-bottle-ink`, `sunshine-soft`, `peach-soft`, `care-growth-soft` / `care-growth-ink`, `card-peach` (#FFA58D, hidden under the photo), `cloud` (draft rows, source chips, "Định hướng"), `surface`, `surface-2`, `separator`, `ink`, `ink-muted`.

**Lumi palette (raw, brand art — not tokens):** bubble gradient `linear-gradient(135deg, #2BC4B5 14.286%, #086B73 53.571%, #545CDB 85.714%)`; avatar gradient `linear-gradient(126.87deg, #2BC4B5 14.286%, #545CDB 85.714%)`; block backgrounds `linear-gradient(127.7deg, #F2FCFA 14.286%, #F0F0FF 85.714%)` (Chặng 1 block) and `linear-gradient(132.37deg, …same stops…)` (journey block); block border `#D1DBF7` 1.5 px; journey dashed card border `#D1D9F2`; "Lumi ở chặng này" row `linear-gradient(169.89deg, #EDFAF7 14.286%, #F0F0FF 85.714%)`; path line `#8C99E6` at 50 % (dashed 6/6), progress `#2CBFB3`; dashed ring `#99A3EB`; orbit rings `rgba(115,200,191,.45)` / `rgba(141,154,232,.3)`; glow `radial-gradient(#99E6D9 .75 → #C7C7FF .35 at 60 % → #F2F2FF 0)`; orbit dots `#FFD166`, `#2CBFB3`, `#6C6FD8`, `#FFA58D`. The app paints the mascot with `LumiColors` teal #2CBFB3 / deep #0B8A84 / indigo #5B5FD6 / gold #FFD166 (`apps/mobile/lib/features/assistant/lumi_button.dart`) — close to, not equal to, Figma's stops; on the landing use the Figma SVG as is.

### 0.4 Shadows
`shadow-card` on the Lumi feature cards, orbit chips, the "Lumi" name pill and the stage cards (Figma prints it as `drop-shadow(0 8 12 / 0 1 1)` or `shadow-[0 8 24, 0 1 2]` — same style). The mascot carries its own shadow / glow inside the SVG. **None** on the two Lumi block containers, the journey stage columns or the outro card.

### 0.5 Icons (app set `apps/mobile/assets/icons/`)
Used in the new blocks: feed, sleep, bookmark, camera, cloud-off, journal, spark, **link**, check, clock, arrow-right. **Missing from the landing `Icon` map (`components/primitives.tsx`): `link` only** (`apps/mobile/assets/icons/link.svg` exists → one more `?raw` import). Colours read from the exported SVGs:
- Orbit chips: feed `care-bottle-ink`, sleep `care-sleep-ink`, bookmark `ink`, camera `ink`, cloud-off `care-growth-ink`, journal `mint-text`.
- Feature cards: draft-row feed `care-bottle-ink`, sleep `care-sleep-ink`; avatar spark white; every source / menu chip icon (link, sleep, journal, bookmark, camera), the receipt cloud-off and the play arrow `ink`.
- Journey: stage-1 sparks `mint-text`, stages 2–4 sparks `care-sleep-ink`, clock `ink-muted`, check white; buttons' arrow white.
- **Icon choice to fix:** "Chụp hoá đơn bỉm" (orbit) and the receipt draft row use **`cloud-off`** — the same misuse the chat extraction flagged (31 Q17). A receipt / camera glyph is meant; use `camera` (exists) unless design adds a receipt icon.

### 0.6 Assets

| Asset | Figma | File | Notes |
|---|---|---|---|
| **Lumi mascot** (Chat/Nút trợ lý `628:9074`: bubble, Logo/Mark face, sheen, halo, two "Sao AI" sparkles) | instances 649:7275 (44), 676:5571 (104), 678:5618 (36), 678:5640 (54), 678:5654/5668/5682 (32.2 / 37.2 / 42.2 at 57 / 69 / 81 % opacity), 678:5564/5581/5598 (24) | **reuse** `apps/landing/src/assets/figma/lumi-mascot.svg` (added today by the Lumi-page extraction, same component, 52-px box, `viewBox="8.9375 4.875 52 52"` with `overflow="visible"` for the halo and sparkles) | The app has **no file to reuse**: it paints Lumi in code (`LumiMascot` CustomPainter). Scale the one SVG to each size. Inline it (`?raw`) as the file comment says; it defines fixed ids `lumi-*` — several inline copies on one page duplicate ids (harmless as the defs are identical, but invalid HTML): prefer one hidden `<svg><symbol id="lumi">` + `<use href="#lumi">` per instance, or `<img>` (then the overflow is clipped — pad the box). |
| **Hành trình art**, stage 1–4 | 688:18, 688:39, 688:60, 688:88 (295 × 170) | **added** `journey-art-stage1.svg` … `journey-art-stage4.svg` | Transparent background (the tinted band, its two light circles and the big number stay page-drawn). Stage 1: sleeping baby in a mint hammock, moon, bottle; 2: toddler with stacked blocks and a ball; 3: child with a magnifier, "?" bubbles and an easel; 4: child at a desk with a rocket, plant and lamp. 688:60 was a frame (no flat asset): its export was cut out of the page context. |
| **Các chặng art**, stage 2–4 | 684:537, 684:568, 684:600 (400 × 260) | **added** `stage-art-2.svg`, `stage-art-3.svg`, `stage-art-4.svg` | Include their own background (#FFF2D6 / #FFEBE3 / #EBEBFF raw) — i.e. **the stage-3 peach / stage-4 lavender mapping is baked in** (§5.3). 684:568 was cut out of the page context like 688:60. |
| Orbit glow, rings, dots, typing dots; journey line, rings | 676:5564–5570, 676:5586, 678:5638/5639/5653/5667/5681 | none | Simple shapes → CSS / inline SVG (values §4.2, §6.2). Figma exports the dashed rings as 2× PNGs; do not ship those. |
| `Illustration/Photo` Sand (receipt) and Peach (memory video) | 649:7444, 649:7469 | existing Teddy photos | §10 |

All added SVGs keep Figma's geometry; only the page-context rectangles were removed and internal ids were made unique per file (`_ja1`…`_ja4`, `_sa2`…`_sa4`), so they can be inlined together. Sources: `scratchpad/v6/home-dl/`.

---

## 1. Nav (649:6252, 1440 × 87) — changed

Geometry/styles as v5b (`padding: 22px 96px`, links `gap: 36px` Medium 15 / normal, nowrap, 40 spacer, CTA pill `ink` / `surface` SemiBold 15 `padding: 12px 22px` **"Tải miễn phí"**). Links row 646 → **586** wide, starts at x **585**; flex spacer 253 → 313.

Links, verbatim, in order: **"Hành trình" · "Năm đầu đời" · "Lumi" · "Các chặng" · "Kỷ niệm" · "Hỏi đáp"**.
- **"Lumi"** (36 px, node 649:7235) replaces "Apple Watch" in third place. It is the only link drawn as `<a>` and the only one in **`mint-text`** (#06716D); the other five stay `ink-muted`. Read as a permanent accent (a "new" feature and a link to its own page), not a current-page state.
- Removed: "Apple Watch" (`nav.links.watch`) — the watch card stays on the page (inside the Chặng 1 frame) and keeps `id="apple-watch"`.
- The Lumi page `650:4798` has the same six links (row 587 wide), so the nav is shared.
- Width: 60 px narrower than v5b; the 1120–≈1230 overflow (`25` §5, `28` §2) shrinks but does not vanish (≈ 176 + 586 + 40 + 215 = 1017 > ≈ 971 at 1120).

---

## 2. Unchanged (verified)

- **Hero copy** (`649:6266`, verbatim, = `home.hero`): eyebrow **"Child Life · Hành trình lớn lên"**; H1 **"Cùng con lớn lên,"** / **"đồng hành từng bước."**; lead **"Hệ sinh thái giúp cha mẹ chăm sóc, thấu hiểu và đồng hành cùng con — từ những ngày đầu đời đến khi trưởng thành."**; promises **"Chăm sóc con mỗi ngày, cả nhà cùng phối hợp"** · **"Thấu hiểu con qua từng giai đoạn lớn lên"** · **"Đồng hành và lưu giữ hành trình của con"**; button **"Xem hành trình của con"** (+ chevron-down). Hero metadata identical, pixels noise-only. **No Lumi mention in the hero.**
- **Chặng 1 frame contents** other than the new block: Head, Bento, Tiện ích, Theo cách, Apple Watch card, "Xem đầy đủ năm đầu đời" card — metadata identical (frame names aside), pixels noise-only. Frame styles unchanged (`mint-soft`, 2 px `mint`, r 48, gap 24, padding-bottom 48). 28 §3 applies, including its open issues (invisible eyebrow pill on the mint frame, Theo cách panel overhang).
- **Lớn lên band + Cách giữ kỷ niệm**: identical (band body verified: "Từ sinh nhật đầu tiên đến ngày con vào lớp 1, rồi những ước mơ tuổi 12 — hành trình của con nằm trọn ở một nơi, không mất đi khi con lớn."; Kỷ niệm lead "Video, thiệp, nhật ký, lời nhắn và cả một cuốn sách — tạo từ chính ảnh và câu chữ của gia đình bạn."). Only the section's top padding changed (§7).
- **CTA** identical (sub verified: "Miễn phí trên iPhone và Android. Mời cả nhà chỉ trong một phút.").
- **Hỏi đáp** (`649:7172`) identical to v5b / `home.faq.items`: `padding: 64px 96px 80px`; left Bold 36 / 1.2 (−0.36 tracking) **"Câu hỏi thường gặp"**, Medium 16 / 1.5 **"Còn điều gì băn khoăn? Cứ nhắn cho chúng tôi nhé."**
  1. (open) **"Child Life là gì?"** — **"Hệ sinh thái giúp cha mẹ chăm sóc, thấu hiểu và đồng hành cùng con qua từng chặng lớn lên. Ứng dụng hiện tập trung vào năm đầu đời của con."**
  2. (open) **"Child Life dành cho bé mấy tuổi?"** — **"Từ ngày con chào đời. Năm đầu, app giúp cả nhà chăm con mỗi ngày; những chặng tiếp theo sẽ cùng con lớn lên đến tuổi trưởng thành."**
  3–9 (closed, no answer in Figma): **"Khi con lớn, ảnh và hồ sơ của con có còn không?"** · **"Có mất phí không?"** · **"Ai được xem ảnh và thông tin của con?"** · **"Nội dung gợi ý trong app do ai soạn?"** · **"Sơ cứu trong app có thay thế bác sĩ không?"** · **"Ai xem được chi tiêu của gia đình?"** · **"Có dùng Child Life trên Apple Watch được không?"**
  **No Lumi question** although Lumi is now the page's biggest new feature, and the shipped (proposed) answer to "Có mất phí không?" ("Không. Cả gia đình dùng miễn phí…") now contradicts Lumi's credit limits (§12).

---

## 3. Hành trình (649:6337, 1440 × 806) — art changed

Head and card bodies unchanged (verbatim: eyebrow **"Hành trình lớn lên"**, H2 **"Đi cùng con qua từng chặng."**, lead **"Mỗi giai đoạn con lớn lên, Child Life cùng ba mẹ chăm con, hiểu con và giữ lại những điều đáng nhớ."**; cards as `home.chapters` + `journey.stages`: "Chặng 1 · 0–12 tháng" + chip "Có trên app", "Những ngày đầu đời", chips "Chăm con mỗi ngày" / "Hiểu từng tuần tuổi" / "Lưu giữ khoảnh khắc", link "Khám phá năm đầu đời"; cards 2–4 link "Xem chặng này").

**Art band** (`h 170`, card-wide, `overflow: hidden`, tint `mint-soft` / `sunshine-soft` / `care-sleep-soft` / `peach-soft` as before) now contains, in paint order:
1. the two light circles (220 at (150, 40), 120 at (−30, −40)) — unchanged;
2. the big number Bold **72** at **left 14** (was 18), top 70: `rgba(43,153,143,.28)` / `rgba(250,158,89,.28)` / `rgba(115,115,217,.28)` / `rgba(242,128,115,.28)` (raw);
3. **"Minh hoạ vector"** 295 × 170 at (0, 0) → `journey-art-stage{1..4}.svg` (§0.6), **on top of the number** (the art overlaps the number's right part on cards 1–2 — as designed).

Removed: stage 1's 112-px circular **photo** (`Photo tone="peach"` = `teddy-eight-months.jpg` in code) and stages 2–4's 96-px disc + 40-px icon (`stageLooks[i].icon`). Implementation: `chapter__art` keeps circles + number, replaces `chapter__photo` / `chapter__disc` with `<img src={journeyArt[i]} alt="" width="295" height="170">` (decorative; the card already names the stage). Card 1's band is 294 wide inside its 2-px border — let the SVG overflow-clip.

---

## 4. Chặng 1 · Lumi block (649:7270, 1340 × 1207) — NEW

```
649:6439 "Khung chặng 1"  (frame unchanged: mint-soft, 2px mint, r 48, column, gap 24, padding-bottom 48)
├─ 475:… "Năm đầu đời" (Head, Bento, Tiện ích, Theo cách)      unchanged, y 2
├─ 649:7270 "Lumi · khung"   column; padding: 0 48px            NEW, y 2194
│    └─ 649:7271 "Lumi"  1244 × 1207
│         border: 1.5px solid #D1DBF7 (raw); border-radius: 40px; padding: 56px; column; gap: 44px;
│         background: linear-gradient(127.7deg, #F2FCFA 14.286%, #F0F0FF 85.714%) (raw)
│         ├─ 649:7272 "Đầu khối"   row; gap: 56px; align-items: center   (1132 × 340)
│         └─ 649:7345 "Tính năng"  column; gap: 20px                     (1132 × 708)
├─ 524:4032-equivalent "Apple Watch · khung" → dark card       unchanged, y 3425
└─ "Chi tiết năm đầu đời" → CTA card                            unchanged, y 4123
```
Same 48-px inner gutter and 1244 width as the watch and CTA cards. The block is a light lavender-mint card on the mint frame (it is the only non-white, non-dark card in the frame).

### 4.1 Head copy 649:7273 (560 wide, `column; gap: 20px`)
- **eb** `row; gap: 10px; align-items: center`: mascot **44** (`lumi-mascot.svg`) + eyebrow pill `care-sleep-soft` / `care-sleep-ink` SemiBold 13, `padding: 6px 12px; r 999`: **"Mới · Lumi · trợ lý đồng hành"**
- H Bold **40** / 1.18 `ink` (2 lines): **"Gặp Lumi — trợ lý nhỏ cho năm đầu đời của con."** (→ `<h3>` inside `#nam-dau-doi`, id `lumi-title`)
- Lead Medium 18 / 1.55 `ink-muted` (3 lines): **"Đang bế con mà vẫn ghi kịp cữ bú. Hỏi một câu là biết hôm nay con ăn ngủ ra sao. Lumi lo phần ghi chép và tổng hợp, ba mẹ chỉ cần xem lại và bấm lưu."**
- Button `<a>` `mint-deep`, `padding: 15px 24px; gap: 8px; r 999`, SemiBold 16 `on-mint-deep` **"Khám phá Lumi"** + arrow-right 16 white → **Lumi page** (§8). No shadow.

### 4.2 "Lumi · quỹ đạo gợi ý" 649:7304 (516 × 340, `position: relative`, decorative → `aria-hidden`, but the chip texts are content-like: keep them in the DOM for translation)
| Layer | Box (x, y, w × h) | Spec |
|---|---|---|
| Glow "Quầng sáng" 676:5564 | 118, 50, 280 × 240 | ellipse, `radial-gradient(closest-side, rgba(153,230,217,.75), rgba(199,199,255,.35) 60%, rgba(242,242,255,0))` (raw) |
| Ring 1 "Vòng 1" 676:5565 | 158, 70, 200 × 200 | circle, dashed ~1.5 px `rgba(115,200,191,.45)` (raw; Figma ships a PNG) |
| Ring 2 "Vòng 2" 676:5566 | 28, 20, 460 × 300 | ellipse, dashed ~1.5 px `rgba(141,154,232,.3)` (raw) |
| Dots 676:5567–5570 | (354,158) (24,176) (404,286) (134,26), 8 × 8 | `#FFD166` (= `sunshine`), `#2CBFB3` (= `mint`), `#6C6FD8` (raw), `#FFA58D` (= `card-peach`) |
| Mascot 676:5571 | 206, 112, 104 × 104 | `lumi-mascot.svg` at 104 |
| Name pill "Tên" 676:5584 | 215.5, 220 | `surface`, `shadow-card`, `padding: 5px 12px; gap: 6px; r 999`: Bold 14 `ink` **"Lumi"** + typing dots 21 × 5 (three 5-px `mint` dots, gap 3, opacity .9 / .6 / .3) |
| Chips "Gợi ý" | see below | `surface`, `shadow-card`, `padding: 7px 14px 7px 7px; gap: 10px; r 999`; icon circle `padding: 7px` + icon 14; SemiBold 14 `ink`, nowrap |

Chips (position · icon circle · icon colour · text):
1. (0, 0) · `care-bottle-soft` · feed `care-bottle-ink` · **"“Con vừa bú 120 ml lúc 9h”"**
2. (262, 22) · `care-sleep-soft` · sleep `care-sleep-ink` · **"“Hôm nay con ngủ bao lâu?”"**
3. (−18, 140) · `sunshine-soft` · bookmark `ink` · **"Gợi ý ăn dặm"**
4. (327, 140) · `peach-soft` · camera `ink` · **"Làm video đầy tháng"**
5. (10, 268) · `care-growth-soft` · cloud-off (→ camera, §0.5) `care-growth-ink` · **"Chụp hoá đơn bỉm"**
6. (266, 290) · `mint-soft` · journal `mint-text` · **"“Mấy hôm nay con khó ngủ”"**

Chip 3 hangs 18 px left of the box and chip 4 reaches x 534 (18 px past the right edge) — inside the 56-px block padding, fine at 1440; clip-safe below. Build as an absolutely positioned 516 × 340 stage scaled with the existing `Fit` helper.

### 4.3 "Tính năng" 649:7345 — six feature cards (2 rows × 3, `gap: 20px` both ways)
Card: `surface`, `shadow-card`, `border-radius: 26px; padding: 12px 12px 22px; column; gap: 14px;` width **364**, rows stretch to equal height (344).
- **Illustration** 340 × 200, `border-radius: 18px; padding: 14px; column; gap: 8px; justify-content: center; overflow: hidden;` tinted (table). Decorative mock → `aria-hidden`, built in HTML/CSS (all strings translate).
- **Text** `padding: 0 8px; column; gap: 6px;` title Bold **19** / 1.25 `ink` (→ `<h4>`), body Medium 14 / 1.55 `ink-muted`.

| # | Node | Illus bg | Title | Body |
|---|---|---|---|---|
| 1 | 649:7347 | `care-bottle-soft` | **"Kể một lần, ghi đúng chỗ"** | **"Gõ một câu như đang nhắn cho người nhà — Lumi tách thành từng bản ghi bú, ngủ, tã để bạn xem lại."** |
| 2 | 649:7373 | `mint-soft` | **"Hỏi bằng lời của bạn"** | **"“Hôm nay con bú thế nào?” — Lumi trả lời từ chính nhật ký của con, kèm nguồn để mở lại."** |
| 3 | 649:7392 | `care-sleep-soft` | **"Nhìn lại mấy ngày qua"** | **"Khi con khó ngủ hay bú ít, Lumi đặt các ghi nhận gần đây cạnh nhau để bạn thấy rõ hơn."** |
| 4 | 649:7417 | `sunshine-soft` | **"Hôm nay con ăn gì?"** | **"Gợi ý món theo tuổi từ thư viện, tránh những món nhà bạn đã ghi là con từng phản ứng."** |
| 5 | 649:7440 | `peach-soft` | **"Chụp hoá đơn, xong chi tiêu"** | **"Chụp hoá đơn bỉm, sữa — Lumi soạn khoản chi, hỏi lại chỗ chưa rõ trước khi lưu."** |
| 6 | 649:7466 | `card-peach` (covered) | **"Biến ảnh thành kỷ niệm"** | **"Chọn ảnh và mẫu, Lumi giúp ghép thành thiệp hay đoạn phim nhỏ cho những cột mốc đầu đời."** |

**Shared chat-mock parts** (all mirror the app's chat: Chat/Tin nhắn, Chat/Thẻ nháp, `31-chat-assistant.md`):
- **Parent bubble** "Ba mẹ": row, `justify-content: flex-end`, 312 wide; bubble `mint-deep`, `padding: 9px 13px; r 16`, Medium 13 / 1.4 `on-mint-deep`, nowrap.
- **Lumi reply** "Lumi": row `gap: 8px; align-items: flex-start`, 312 wide: avatar 22 circle, `padding: 5px`, avatar gradient (§0.3) + spark 12 white; bubble `surface` + 1 px `separator`, `padding: 9px 13px; r 16; column; gap: 8px; flex: 1`, Medium 13 / 1.45 `ink`.
- **Source / menu chip**: `cloud`, `padding: 3px 8px; gap: 6px; r 999`, icon 11 `ink` + SemiBold 11 `ink`.
- **Draft row** "Nháp · …": `cloud` + 1 px `separator`, `padding: 10px 12px; gap: 10px; r 16; align-items: center`, 312 wide: icon box `padding: 8px; r 12` + icon 16; text `column; gap: 2px; flex: 1`: SemiBold 14 `ink` / Medium 12 `ink-muted`; chip `surface-2`, `padding: 4px 10px; r 999`, SemiBold 12 `ink-muted` **"Nháp"**.

Mocks (verbatim):
1. Parent **"Con bú 120 ml lúc 9h, ngủ từ 9h30"** → draft (feed, box `care-bottle-soft`) **"Bú bình · 120 ml"** / **"9:00"** · **"Nháp"** → draft (sleep, box `care-sleep-soft`) **"Giấc ngủ"** / **"từ 9:30"** · **"Nháp"**.
2. Parent **"Hôm nay con bú thế nào?"** → Lumi **"5 cữ bú bình · tổng 580 ml. Cữ gần nhất lúc 14:20."** + chip (link) **"Mở nhật ký nguồn"**.
3. Parent **"Mấy hôm nay con khó vào giấc"** → Lumi **"3 tối gần đây có 2 ghi nhận khó vào giấc, đều sau 21h. Xem lại các giấc quanh đó nhé?"** + chips `gap: 6px` (sleep) **"6 giấc ngủ"**, (journal) **"2 ghi chú"**.
4. Parent **"Hôm nay cho Na ăn gì?"** → Lumi **"Gợi ý cho bé 7 tháng, đã bỏ trứng vì từng ghi nổi mẩn:"** + chips stacked `column; gap: 6px` (bookmark) **"Cháo bí đỏ"**, (bookmark) **"Khoai lang nghiền"**.
5. Row `gap: 10px; align-items: center`: photo 52 × 68 `r 10` (§10 slot 1) + draft (cloud-off → camera, box `surface`) **"Bỉm · 289.000đ"** / **"Chi tiêu · hôm nay"** · **"Nháp"**; below, Medium 11 / 1.4 `ink-muted` full width **"Ngày trên hoá đơn mờ — Lumi hỏi lại trước khi lưu."**
6. Illustration **without padding**: photo 340 × 200 (§10 slot 2; 340² at top −70); play button white circle `padding: 10px` at (152, 82) with arrow-right 16 `ink`; chip at (12, 166) `surface`, `padding: 4px 8px; gap: 6px; r 999`: camera 11 `ink` + SemiBold 11 `ink` **"Một tháng đầu của Teddy · 0:45"**.

Fixture notes: card 4 uses **"Na"** (the chat extraction's CH18 baby "Bé Na · 7 tháng"), every other baby on the page is **Teddy** — pick one (Teddy is 3 weeks in the chat fixtures and cannot eat solids; on the landing Teddy has no stated age, so "Hôm nay cho Teddy ăn gì?" + "bé 7 tháng" works). Money format **"289.000đ"** differs from the page's "4.215.000 ₫" (spending card) and the app's "… ₫" — use **"289.000 ₫"**.

---

## 5. Các chặng tiếp theo (649:6826, 1440 × 2175) — cards changed

Section unchanged: `column; align-items: center; gap: 48px; padding: 64px 96px 80px;`. Head, path (28 §4.1–§4.2) identical. Children: Head · Path · **Thẻ chặng 649:6852 (1248 × 654)** · **Lumi · suốt hành trình 678:5614 (1248 × 1026, §6)**.

### 5.1 Card changes (649:6853 / 649:6875 / 649:6898, 400 × **654**, was 579)
Card styles unchanged (`surface`, r 32, `shadow-card`, `overflow: hidden`, column). Body `flex: 1; column; gap: 14px; padding: 24px 28px 28px` now **394** tall.
1. **"Minh hoạ" 400 × 260**: background #FFF2D6 / #FFEBE3 / #EBEBFF (raw — close to `sunshine-soft` #FFF4D6 / `peach-soft` #FFE3DA / `care-sleep-soft` #EDEEFC); the photo / dashed placeholder is replaced by **`stage-art-{2,3,4}.svg`** 400 × 260 at (0, 0); then the number and the badge on top.
   - Number Bold 96 at (24, 4): card 2 `rgba(250,158,89,.35)` × opacity **.85**; cards 3–4 `rgba(250,128,115,.35)` / `rgba(115,115,217,.35)` × opacity **.18** (≈ 6 % — nearly invisible). Recommend one style for all three: the colour at .35 with no extra opacity (≈ card 2).
   - Badge unchanged: `sunshine`, `padding: 5px 12px; r 999`, Bold 12 `ink` **"Sắp ra mắt"** at right 24 / top 24.
2. Body as 28 §4.3 (label, title, lead, chips, spacer), then **NEW "Lumi ở chặng này" row** `<a>` above the link:
   - `width: 100%; padding: 8px 12px 8px 8px; gap: 8px; border-radius: 14px; align-items: center;` background `linear-gradient(169.89deg, #EDFAF7 14.286%, #F0F0FF 85.714%)` (raw).
   - mascot **24** + text `column`, nowrap: SemiBold 11 `care-sleep-ink` **"Lumi ở chặng này"** / SemiBold 13 `ink`:
     - card 2: **"Hôm nay chơi gì cùng con?"**
     - card 3: **"“Vì sao?” cũng thành giờ chơi"**
     - card 4: **"Ý tưởng của con có nơi bắt đầu"**
   - Each teaser is the first item of that stage in the journey block (§6.3) without the final full stop → link it to **`#lumi-hanh-trinh`** (the block right below; on the Lumi page the same block is its section 691:5979).
   - Then the outline link, unchanged (**"Xem trước chặng 2/3/4"** → stage page).
3. **Link alignment fixed by design:** all three rows sit at body y 261 and the links at y 321 (spacer absorbs card 4's one-line chips). Implement with the spacer (`flex: 1`) or `margin-top: auto` on the Lumi row; no fixed card height needed.

### 5.2 Label / chip colours (unchanged from v5b, conflict persists)
Card 2 `care-growth-ink` on `sunshine-soft`; card 3 label + chips `care-bottle-ink` on **`peach-soft`**; card 4 `care-sleep-ink` on `care-sleep-soft`.

### 5.3 Tint conflict, now baked into art
Hành trình (and `stageLooks` in `Chapters.tsx`, used by `NextStages.tsx` today) maps stage 3 → `sleep`, stage 4 → `peach`, and the **new Hành trình illustrations are drawn that way** (stage 3 on a lavender ground, stage 4 on peach). Các chặng and the new journey block map **stage 3 → peach, stage 4 → sleep**, and **`stage-art-3/4.svg` carry those backgrounds**. Shipping both SVG sets as drawn shows the same stage in two colours on one page. Options: (a) ask design to swap the Các chặng backgrounds / chips (preferred: Hành trình is the canonical map since v3); (b) keep Figma literally and drop `stageLooks` from `NextStages` (code today follows (a)'s mapping; 28 §11.5). Until decided, code follows `stageLooks` and the stage-art backgrounds clash on cards 3–4.

---

## 6. Lumi · suốt hành trình (678:5614, 1248 × 1026) — NEW

`border: 1.5px solid #D1DBF7; border-radius: 40px; padding: 56px 56px 48px; column; gap: 40px;` background `linear-gradient(132.37deg, #F2FCFA 14.286%, #F0F0FF 85.714%)` (raw). Content width 1136. **The Lumi page uses the same block** (`691:5979` → 1248 × 1026, identical except the outro button label "Dùng thử Lumi hôm nay") → one shared component with a CTA prop.

### 6.1 Head 678:5615 (`row; gap: 40px; align-items: flex-end`)
- Left (720, `column; gap: 14px`): eb `row; gap: 10px` = mascot **36** + pill `care-sleep-soft` / `care-sleep-ink` SemiBold 13 **"Lumi theo con suốt hành trình"**; title Bold **34** / 1.2 `ink`, one line: **"Con lớn lên, Lumi cũng lớn theo con."** (→ `<h3>` in `#cac-chang`, id `lumi-journey-title`)
- Right (`flex: 1` = 373): Medium 16 / 1.55 `ink-muted` (4 lines): **"Hôm nay Lumi đồng hành cùng ba mẹ trong năm đầu đời. Ở mỗi chặng sau, Lumi sẽ có thêm cách giúp mới — vừa với tuổi của con và nhịp của gia đình."**

### 6.2 "Đường hành trình" 678:5636 (1136 × 72, decorative, `aria-hidden`)
- Dashed line at y 36 from x 136, 864 long: 2 px `#8C99E6` at 50 %, dash 6 / gap 6 (raw).
- Progress line on top, x 136 → 272 (136 long): 3 px solid `mint` (#2CBFB3).
- Nodes centred on the four column centres (x 136, 424, 712, 1000):
  - stage 1: mascot **54** at (109, 9), no ring;
  - stages 2–4: ring 52 / 60 / 68 (white fill + ~1.5-px dashed `#99A3EB` border) with a mascot **32.2 / 37.2 / 42.2** at opacity **.57 / .69 / .81** — "Lumi grows with the child".

### 6.3 "Các chặng" 678:5695 — four columns (`row; gap: 16px`, each 272 wide, stretched to 512)
Column: `surface`, `border-radius: 24px; padding: 20px 18px 22px; column; gap: 12px;` stage 1 **2 px solid `mint`**; stages 2–4 **1 px dashed #D1D9F2** (raw).
- Header row `gap: 6px; align-items: center` (spacer between): stage chip `padding: 4px 9px; r 999` SemiBold 11 + status chip `padding: 4px 9px; gap: 6px; r 999` icon 11 + SemiBold 11.
- Name Bold 20 / 1.25 `ink`; sub Medium 14 / 1.5 `ink-muted`; divider 1 px `separator`.
- Items `row; gap: 10px`: spark 14 (`padding: 4px 0`) + `column; gap: 2px`: SemiBold 14 / 1.4 `ink` title, Medium 13 / 1.5 `ink-muted` description (stage 1: titles only).

| Stage | Stage chip | Status chip | Name | Sub | Items (title — description) |
|---|---|---|---|---|---|
| 1 | `mint-soft` / `mint-text` **"Chặng 1 · 0–12 tháng"** | `mint-deep` + check white + `on-mint-deep` **"Đang có"** | **"Năm đầu đời"** | **"Nhẹ nhàng hơn cho cả nhà."** | sparks `mint-text`: **"Kể một lần, ghi đúng chỗ."** · **"Hỏi về nhật ký của con."** · **"Gợi ý món ăn dặm hôm nay."** |
| 2 | `sunshine-soft` / `ink` **"Chặng 2 · 1–3 tuổi"** | `cloud` + clock `ink-muted` + `ink-muted` **"Định hướng"** | **"Con tập khám phá"** | **"Bớt nghĩ chơi gì, thêm những điều cùng con thử."** | sparks `care-sleep-ink`: **"Hôm nay chơi gì cùng con?"** — **"Gợi ý hoạt động ngắn theo tuổi, sở thích đã ghi và những vật dụng có sẵn."** · **"Từng lời đầu tiên, không bị quên."** — **"Gom những câu nói ngộ nghĩnh, tiếng cười và bước tiến nhỏ thành nhật ký của con."** · **"Cùng xây những thói quen nhỏ."** — **"Chuẩn bị những bước đơn giản cho giờ ngủ, đánh răng hay thu dọn đồ chơi, theo cách gia đình lựa chọn."** |
| 3 | `peach-soft` / `ink` **"Chặng 3 · 3–6 tuổi"** | same **"Định hướng"** | **"Tò mò và lớn khôn"** | **"Thêm ý tưởng cho những câu hỏi không ngừng."** | **"“Vì sao?” cũng thành giờ chơi."** — **"Biến điều con tò mò thành câu chuyện, trò chơi hoặc hoạt động để cùng khám phá."** · **"Một ngày của con, dễ kể lại hơn."** — **"Từ vài ghi chú của ba mẹ, gợi ý câu hỏi để cùng con trò chuyện về ngày ở lớp."** · **"Bức vẽ nhỏ, câu chuyện lớn."** — **"Giữ tác phẩm cùng lời con kể, rồi gom thành bộ sưu tập qua từng năm."** |
| 4 | `care-sleep-soft` / `care-sleep-ink` **"Chặng 4 · 6–12 tuổi"** | same **"Định hướng"** | **"Thế giới riêng của con"** | **"Đồng hành gần hơn, dành chỗ cho con tự lớn."** | **"Ý tưởng của con có nơi bắt đầu."** — **"Cùng chia một dự án nhỏ thành những bước vừa sức — trồng cây, làm mô hình hay viết truyện."** · **"Kế hoạch do con cùng lựa chọn."** — **"Chuẩn bị lịch học, việc nhà và thời gian cho sở thích; ba mẹ và con cùng điều chỉnh."** · **"Một năm nhìn bằng mắt con."** — **"Gom thành quả, câu chuyện và điều con tự hào thành cuốn kỷ niệm có tiếng nói của chính con."** |

Names and ages re-use `journey.stages[i].name` / `ages` and `journey.number`; the subs and items are new strings (they differ from `journey.stages[i].lead`). Semantics: `<ol>` of four `<li>` columns, item lists as `<ul>`; status as text (not colour only).

### 6.4 Outro "Kết khối" 678:5828 (1133 wide)
`surface`, `border-radius: 24px; padding: 22px 24px; row; gap: 24px; align-items: center;`
- Text `flex: 1; column; gap: 4px`: Bold 20 / normal `ink` **"Bắt đầu từ hôm nay. Cùng chờ những chặng tiếp theo."**; Medium 14 / 1.5 `ink-muted` **"Các trải nghiệm trên là định hướng đang được phát triển. Phạm vi và thời điểm ra mắt sẽ được cập nhật theo từng chặng."**
- Button `<a>` (as §4.1) **"Khám phá Lumi hôm nay"** + arrow → Lumi page. (Lumi page variant: **"Dùng thử Lumi hôm nay"** → `#tai-app`.)

---

## 7. Lớn lên cùng con (649:6921, 1440 × 1686) — padding only
`column; gap: 64px; padding: 0 48px 80px;` (v5b `80px 48px`). The band now starts 80 px under the Lumi journey block (Các chặng's bottom padding). Content identical (28 §5).

---

## 8. Links, section ids and nav targets (proposal — Figma shows link layers but no destinations)

| Element | Home | Stage 1 page | Stages 2–4 / Lumi page |
|---|---|---|---|
| Nav "Hành trình" | `#hanh-trinh` | `${homePath}#hanh-trinh` | same |
| Nav "Năm đầu đời" | `#nam-dau-doi` (spy target = whole frame; nested `#lumi` and `#apple-watch` no longer have nav links, so no nested spy needed) | current | Chặng 1 page |
| **Nav "Lumi"** (new `nav.links.lumi`) | **Lumi page** (`pathOf('lumi')`, route by the Lumi-page extraction, e.g. `/lumi/` · `/en/lumi/`), always `mint-text` | Lumi page | current on the Lumi page (`aria-current="page"`) |
| Nav "Các chặng" | `#cac-chang` | `${homePath}#cac-chang` | same |
| Nav "Kỷ niệm" / "Hỏi đáp" / "Tải miễn phí" | as 28 §9 | | |
| "Khám phá Lumi" (§4.1), "Khám phá Lumi hôm nay" (§6.4) | Lumi page | — | — |
| "Lumi ở chặng này" rows (§5.1) | `#lumi-hanh-trinh` | — | — |

- New ids: **`lumi`** on 649:7270 (inside `#nam-dau-doi`; for deep links / shares like `/#lumi`), **`lumi-hanh-trinh`** on 678:5614 (inside `#cac-chang`). Heading ids `lumi-title`, `lumi-journey-title`. Keep `apple-watch` on the watch card (no nav link now; old links still land).
- If the owner prefers the nav to stay in-page on the home (like every other link), point "Lumi" to `#lumi` there and to the Lumi page elsewhere; then drop the accent colour or keep it as a "new" highlight — design call (§11.2).
- `Chrome.tsx`: replace the `watch` entry by `lumi` (page link, `className` accent), order journey, firstYear, lumi, stages, memories, faq.

---

## 9. Mobile — PROPOSAL (no mobile frame)

Breakpoint `< 1120` as today; frame inset rules from 28 §8.
- **Hành trình cards**: art band keeps 170 high; the SVG scales to the card width (`width: 100%; height: auto`, `object-fit: cover` anchored right so the figure stays visible on 335-wide cards). The mobile thumbnail (`chapter__thumb`) uses the same art cropped to a 56-px circle, or drop the thumb.
- **Lumi block (in the Chặng 1 frame)**: card `r 32; padding: 28px 20px; gap: 28px`. Head stacked: eb, title Bold 28 / 1.2, lead Medium 16 / 1.55, button full width. Orbit: the 516 × 340 stage scaled with `Fit` to 295 wide (×0.57, chips ≈ 8 px text — too small), so **replace it** on mobile by the mascot (72) centred over a 2-column wrap of the six chips at full size (SemiBold 13). Features: **horizontal snap carousel** (card 300 wide, illustration scaled ×0.86 with `Fit`, body full size, title Bold 18, body Medium 14 / 1.5), next card peeking; alternative stacked cards (≈ 6 × 330 px).
- **Các chặng cards**: as 28 §8, art 335 × 218 (`stage-art` scaled ×0.84), number Bold 64; the Lumi row stays full width (text may wrap to 2 lines: drop `nowrap`).
- **Lumi · suốt hành trình**: card `r 32; padding: 28px 20px 24px; gap: 24px`; head stacked (title Bold 24 / 1.2, lead Medium 15 / 1.55); hide the path line; stage columns as a **horizontal snap carousel** (272 wide, the four mascot sizes moved into each column's header) — or stacked with stages 2–4 collapsed to name + first item; outro stacked, button full width.
- Nav mobile: unchanged (logo + EN + "Tải app"); a "Lumi" link is not shown (no section links on mobile). FAQ mobile unchanged.

---

## 10. Image slots in the new / changed blocks

| # | Node | Block | Slot | Figma | Map to (apps/landing/src/assets/photos) | Note |
|---|---|---|---|---|---|---|
| 1 | 649:7443/7444 | Lumi card 5 "Chụp hoá đơn" | 52 × 68, r 10 (photo 68² at left −8) | Lib **Sand** `5d2ff` — a swaddled newborn | **None fits — the slot means the receipt photo.** Draw a small receipt in HTML/CSS (white slip, 3–4 grey lines, "289.000 ₫") or source one stock photo of a paper receipt for diapers / milk (≥ 104 × 136). Do **not** use `photos.sand` (= `teddy-two-months.jpg`) | new art or new photo needed |
| 2 | 649:7468/7469 | Lumi card 6 "Biến ảnh thành kỷ niệm" | 340 × 200, r 18 via the illustration (photo 340² at top −70) | Lib **Peach** `0d3f8` | **`teddy-newborn-yawn.jpg`** (720 × 480, scene `thenBaby`) — matches the chip "Một tháng đầu của Teddy"; `photos.peach` (= `teddy-eight-months.jpg`) contradicts "một tháng" | ok at 2× (680 × 400 needed) |
| 3 | 649:6346… / 688:18 | Hành trình card 1 | was 112² photo | **vector art** now | — (code today: `Photo tone="peach"` = `teddy-eight-months.jpg`) | design change: photo → illustration (§11.1) |
| 4 | 684:537 / 684:568 / 684:600 | Các chặng cards 2–4 | 400 × 260 | **vector art** now | — (code today: `scenes.toddler` / `preschool` / `schoolAge`) | same; the three photos stay in use on the stage pages' quotes |
| — | mascot, chat mocks, orbit | Lumi blocks | — | SVG / HTML | — | none |

No other photo slot in the new blocks. Lớn lên / Kỷ niệm / CTA chi tiết slots are unchanged (28 §7 + `CREDITS.md`).

---

## 11. Ambiguities, gaps and conflicts (design / implementation)

1. **Photos → illustrations.** v6 replaces the stage photos the owner approved on 2026-10-13 (`CREDITS.md`) with vector illustrations on Hành trình (card 1) and Các chặng (cards 2–4). Recommendation: follow v6 (one illustrated style for "stages", the photos keep their place in Chặng 1 content, Lớn lên and the stage pages), but it is an owner call; both sets are ready in the repo.
2. **Nav "Lumi" target and colour**: an `<a>` in `mint-text` among plain `ink-muted` labels — page link (proposed) or home anchor `#lumi`; and is the accent permanent? (§8)
3. **Stage tint mapping** now conflicts inside one section *and* inside the new SVGs (§5.3).
4. **Stage-number opacity** .85 vs .18 on the three Các chặng cards (§5.1).
5. **Icon misuse**: `cloud-off` for "Chụp hoá đơn bỉm" and the receipt draft (§0.5).
6. **Fixtures**: "Na" vs Teddy (§4.3), "289.000đ" vs "… ₫", receipt slot shows a baby, video photo is an 8-month baby under "Một tháng đầu".
7. **Duplicate SVG ids** if `lumi-mascot.svg` is inlined 10 times on the home (§0.6).
8. **Chat bubbles are `nowrap`** in Figma (parent bubbles, Lumi row lines): EN strings will be longer — allow wrapping with `max-width: 100%`.
9. **Heading levels**: Lumi head is `<h3>` under the Chặng 1 `<h2>`; feature titles `<h4>`; the journey block title `<h3>` under "Các chặng tiếp theo".
10. **Watch card has no nav entry** any more; the Lớn lên band now sits 80 px under a 1026-px tinted block (visual weight — design check).
11. **No FAQ for Lumi** (what it is, credits / price, privacy, not a doctor) — §12.
12. Unchanged open items from 28 §11 (mint-frame eyebrow invisibility, Theo cách overhang, path nodes static, nav width 1120–1230).

---

## 12. Copy claims vs `docs/product/business-map.md` — NEW claims only

Product facts used: Lumi = the in-app assistant (D-076 #11, app strings "Gặp Lumi, trợ lý của nhà bạn", in-chat surfaces still say "Trợ lý"); one household credit pool, **Free 20 / month, Premium 200** (P-159, D-075 #1), beta may open everything; draft-and-confirm writes (P-156); supported drafts: **bottle, breast, sleep, observation, expense (photos), reminder (photos)** — no diaper, no meal (P-157, `docs/assistant/tools.md` module registry); care topics `sleep_concern` and `meal_ideas` only; **no meal log or reaction record** (tools.md: recorded reactions return none in production); separate AI consent (P-160), provider OpenAI with `store:false` (P-155), kill switches (P-161); receipt photos kept with the expense (D-075 #3); Video kỷ niệm / Thiệp cột mốc are their own features, server-rendered, free in beta (D-068), not assistant tasks; health: assistant is not an emergency service.

| # | Claim (verbatim) | Map support | Conflict / over-claim |
|---|---|---|---|
| 1 | "Lumi tách thành từng bản ghi bú, ngủ, tã" (card 1) | bottle / breast / sleep drafts (P-157) | **No diaper draft kind** — "tã" over-claims. Drop "tã" or add a diaper writer. |
| 2 | "Gợi ý món theo tuổi từ thư viện, tránh những món nhà bạn đã ghi là con từng phản ứng." + mock "đã bỏ trứng vì từng ghi nổi mẩn" (card 4); orbit "Gợi ý ăn dặm"; journey "Gợi ý món ăn dặm hôm nay." | `meal_ideas` care topic; recipes from the reviewed library | **No meal log / reaction record exists**, so nothing "đã ghi là con từng phản ứng" can be honoured; the app itself says "Child Life chưa có nhật ký ăn dặm nên chưa biết con từng phản ứng với món nào." Also recipes are "chờ chuyên môn duyệt" (CH16/CH18). Rephrase to age-based suggestions only, or ship a reaction log first. |
| 3 | "Chọn ảnh và mẫu, Lumi giúp ghép thành thiệp hay đoạn phim nhỏ…" (card 6); orbit "Làm video đầy tháng" | Video kỷ niệm & Thiệp cột mốc (D-068) — separate features, not in the assistant | **Lumi has no card / video task.** Either attribute to Kỷ niệm ("Child Life giúp ghép…") or add an assistant hand-off to the video / card flows. |
| 4 | "Khi con khó ngủ hay bú ít, Lumi đặt các ghi nhận gần đây cạnh nhau" (card 3) | `sleep_concern` (CH15–CH17) | "bú ít" (feeding concern) is not a care topic; sleep only. |
| 5 | "Lumi trả lời từ chính nhật ký của con, kèm nguồn để mở lại." (card 2) | CH08 "Mở nhật ký nguồn" | ✓ consistent. |
| 6 | "Chụp hoá đơn bỉm, sữa — Lumi soạn khoản chi, hỏi lại chỗ chưa rõ trước khi lưu." (card 5) | expense from photos (A3), uncertain date → ask (CH11), D-075 #3/#4 | ✓, but photo reading costs ≈3 credits and depends on `assistant_images` (P-161) and the Chi tiêu role (Cùng nuôi or "Ghi khoản đã chi"). |
| 7 | Lead "Lumi lo phần ghi chép và tổng hợp, ba mẹ chỉ cần xem lại và bấm lưu." / "Hỏi một câu là biết hôm nay con ăn ngủ ra sao." | draft-and-confirm (P-156), ask-data (CH08) | ✓ wording; **no mention anywhere that Lumi is credit-limited (Free 20 / month) or that Premium raises it** (D-075, CH19–CH24), nor that it needs a separate AI consent and sends messages / photos to an AI provider (P-155, P-160). |
| 8 | Eyebrow "Mới · Lumi · trợ lý đồng hành"; "Gặp Lumi — trợ lý nhỏ cho năm đầu đời của con." | D-076 #11 (Lumi name, "Mới" tooltip eyebrow) | ✓ naming matches the app ("Gặp Lumi, trợ lý của nhà bạn"). App inner screens still say "Trợ lý Child Life" (`asEntryTitle`) — align the app or accept two names. |
| 9 | Journey stages 2–4 (all items, "Định hướng"), Các chặng "Lumi ở chặng này" teasers; outro "Các trải nghiệm trên là định hướng đang được phát triển. Phạm vi và thời điểm ra mắt sẽ được cập nhật theo từng chặng." | Q-039 (stages 2–4 roadmap) | New roadmap promises with no D/R entry; hedged well by "Định hướng" and the outro. Sharper items: **"tiếng cười"** (audio of the child), **"cuốn kỷ niệm có tiếng nói của chính con"** (child voice recordings — new sensitive child data, cf. 28 §12 #5), **"sở thích đã ghi"** (no hobby data), **"ngày ở lớp"** (school context). Extend Q-039. |
| 10 | Stage-1 column "Đang có" + "Kể một lần, ghi đúng chỗ." · "Hỏi về nhật ký của con." · "Gợi ý món ăn dặm hôm nay." | as rows 1–2 | "Đang có" holds only while the `assistant` flag is on and only on app versions with the assistant; meal ideas carry row 2's caveat. |
| 11 | FAQ (unchanged) + shipped proposed answer "Có mất phí không? — Không. Cả gia đình dùng miễn phí…" (`vi.ts`, G-065) | D-072 (Premium plan), D-075 #1 (credits; beta may open all) | **Now false next to Lumi**: Lumi is limited on Free and Premium exists (even if the beta opens it). D-076 #9 also bans "Miễn phí / Luôn miễn phí" labels on Premium-feature screens. Rewrite the answer (e.g. free core app + Lumi with a monthly free allowance, Premium for more) and consider a Lumi FAQ ("Lumi là gì?", "Lumi có đọc dữ liệu của con không?", "Lumi có thay bác sĩ không?"). |
| 12 | CTA "Miễn phí trên iPhone và Android." (unchanged) | — | Fine for the app; keep it away from the Lumi blocks. |

Owner decisions needed: (1) photos vs v6 illustrations for stage art (§11.1); (2) stage tint mapping (§5.3); (3) nav "Lumi" target (§8); (4) rows 1–4 — trim the claims (tã, reactions, video/card, bú ít) or commit the features; (5) whether and how the landing discloses credits / Premium / AI consent for Lumi, and the FAQ "Có mất phí không?" rewrite; (6) R-170 rewrite for v6 (nav with Lumi, Lumi block in Chặng 1, Lumi · suốt hành trình, illustrated stage art) and Q-039 extension with rows 9–10.

---

## 13. Copy keys (vi.ts) — proposal

| Area | Key | Value |
|---|---|---|
| Nav | `nav.links` | drop `watch` from the nav (keep the string if used elsewhere); add `lumi: 'Lumi'` |
| Lumi (Chặng 1) | `home.lumi` | `eyebrow` 'Mới · Lumi · trợ lý đồng hành', `title`, `lead`, `cta` 'Khám phá Lumi', `name` 'Lumi', `suggestions[6]` (§4.2), `features[6] { title, body }` (§4.3), `mock` (every mock string §4.3) |
| Lumi journey | `home.lumiJourney` | `eyebrow` 'Lumi theo con suốt hành trình', `title` 'Con lớn lên, Lumi cũng lớn theo con.', `lead`, `current` 'Đang có', `planned` 'Định hướng', `stages[4] { sub, items[{ title, body? }] }` (§6.3), `outroTitle`, `outroBody`, `cta` 'Khám phá Lumi hôm nay' (Lumi page: 'Dùng thử Lumi hôm nay'); stage chip = `journey.number` + ' · ' + `journey.stages[i].ages`, name = `journey.stages[i].name` (stage 1 shows **"Năm đầu đời"** = `home.stages.firstName`) |
| Các chặng | `home.stages` | add `lumiLabel` 'Lumi ở chặng này', `lumiTeasers` ['Hôm nay chơi gì cùng con?', '“Vì sao?” cũng thành giờ chơi', 'Ý tưởng của con có nơi bắt đầu'] |
| Hành trình / Các chặng | — | no text change |

English drafts (engineering, owner review, D-012): nav "Lumi"; "New · Lumi · your companion assistant" / "Meet Lumi — a little assistant for your baby's first year." / "Holding the baby and still logging the feed on time. Ask one question and see how your baby ate and slept today. Lumi handles the notes and the summing up; you just review and tap save." / "Explore Lumi"; suggestions "“Baby just had 120 ml at 9”", "“How long did baby sleep today?”", "Weaning ideas", "Make a one-month video", "Snap a nappy receipt", "“Baby's been sleeping badly lately”"; features "Say it once, logged in the right place" / "Type one line as if texting family — Lumi splits it into feed, sleep and nappy entries for you to review." (drop "nappy" if row 1 is trimmed); "Ask in your own words" / "“How did baby feed today?” — Lumi answers from your baby's own log, with the source to open."; "Look back at the last few days" / "When sleep or feeds get harder, Lumi lines up recent entries so you can see more clearly."; "What can baby eat today?" / "Age-based ideas from the library, avoiding foods you've noted a reaction to."; "Snap the receipt, expense done" / "Snap a nappy or milk receipt — Lumi drafts the expense and checks anything unclear before saving."; "Turn photos into memories" / "Pick photos and a template; Lumi helps turn them into a card or a short film for the first milestones."; journey "Lumi grows with your child" / "As your child grows, Lumi grows too." / "Today Lumi helps you through the first year. At each later stage Lumi will gain new ways to help — right for your child's age and your family's rhythm." / "Available" / "In the works" / "Start today. The next stages are on their way." / "Everything above is a direction in development. Scope and timing will be updated stage by stage." / "Explore Lumi today"; "Lumi at this stage".
