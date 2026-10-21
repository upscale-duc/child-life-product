# 39 — Landing V9: Lumi page and the future-stage page

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only; nothing modified). Extracted 2026-10-21 from section **`785:7030` "Child Life Website — V9"**. Conventions follow `33` / `36`. Token names come from `packages/design-tokens/dist/tokens.css`, and values with no token are marked **(raw)**. Every string is copied **verbatim from `get_design_context`**. Layer names are cut at 30 characters and several are stale, so never copy them (§E.3).

- **Part A** — frame **`785:9913` "V9 · Lumi · Desktop"** (1440 × 4131.2). Written as a **diff against the build** (`pages/LumiPage.tsx`, `sections/LumiDetail.tsx`, `sections/ForBaby.tsx` `ForBabyDetail`, content `lumiPage` / `forBaby.detail`, spec 36 Part A). The new section "Lumi hiểu cả app" is documented in full.
- **Part B** — frame **`785:10743` "V9 · Chặng 2 (đang phát triển) · Desktop"** (1440 × 2034.2). Written as a diff against the built V8 template (`pages/StagePage.tsx`, `sections/Stage.tsx`, `sections/Closing.tsx`, spec 36 Part B).
- **§B.3** — the store-badge artwork, compared with `apps/landing/src/assets/figma/store-*.svg`.
- Siblings: `785:7031` V9 Trang chủ Desktop, `785:7890` V9 Trang chủ Mobile, `785:8698` V9 Năm đầu đời Desktop (specs written in parallel), and the yellow note **`793:68586` "Ghi chú V9 · sửa theo comment"**. **There is no mobile frame and no English frame for either page.** The only mobile Kết is the home's `785:8683` (§B.2.2). There are no prototype links, hover states or motion. The landing site is Light only (`seo.ts`), so Night care does not apply.

Designer notes in `793:68586` (verbatim) that apply here:
- “• Lumi page: rút gọn còn ~4.100px; thêm “Lumi hiểu cả app” (6 mô-đun + câu hỏi mẫu); bỏ phần Gói/giá & câu hỏi về lượt, gói.”
- “• Hành trình: thêm “Tìm hiểu thêm” mỗi chặng. Kết: huy hiệu App Store / Google Play có logo, bỏ ảnh gấu, căn giữa.”
- “• Lumi: thêm “Thử hỏi Lumi” 4 câu, trả lời bằng hình/tag ít chữ.” **This is home-only.** "Thử hỏi Lumi" exists as `788:8801` (home desktop) and `793:8796` (home mobile). No node in `785:9913` carries it (checked in the outline). The Lumi page's own sample Q&A is "Lumi hiểu cả app" (§A.4).

Screenshots (not committed, saved in `scratchpad/v9/`): `lumi-full-thumb.png` (558 × 1600), `lumi-hieu-ca-app.png` (1200 × 776), `stage2-ket.png` (1200 × 327). Icon and badge-logo SVGs were downloaded to `scratchpad/v9/icons/` and `scratchpad/v9/badges/` to read their colours. No photos were downloaded.

Method: the `get_metadata` outline (`scratchpad/v9/meta.xml`, lines 5969–6627), then `get_design_context` on `785:9925` (hero copy), `785:9948` (hero mock-up), `785:10017`, `791:68734`, `785:10386`, `785:10690`, `785:10721`, `785:10758` (Chặng 2 hero copy), `785:10805`, `785:10841`, `785:10856`, `785:8683` (home mobile Kết, for the badge layout on mobile) and `793:68586`, plus `get_metadata` on `794:8818`.

---

## The eight things the implementer must know

1. **The Lumi page is cut down to 6 sections:** Hero → Lợi ích → **Lumi hiểu cả app (NEW)** → Cách Lumi làm việc → Hỏi đáp → Kết. **Removed:** the quick-nav chips, Một ngày cùng Lumi, Một ngày dành riêng cho con (`ForBabyDetail`) and the whole of Gói (toggle, tiers, price note, comparison table, "Lượt hỗ trợ là gì?"). Confirmed: `785:9913` has no other children (§A.0).
2. **Hero copy changed:** H1 **["Lumi hiểu cả hành trình", "của con."]**. The new lead ends **"Miễn phí cho mọi gia đình."** **"Xem các gói" is gone**, leaving one CTA, "Mở Lumi trong app". The mock-up and chips are unchanged (§A.2).
3. **New section "Lumi hiểu cả app"** (§A.4): a lilac band (#F5F5FF raw), a centred head, a Lumi pill, **6 module cards** (each with a title, a subline, a question bubble and a spark answer tag) and a "Lumi có thể:" chip row. All 7 icons already exist in `primitives.tsx`, and there is no image slot.
4. **Hỏi đáp now has 5 questions:** Q1 and the privacy question stay. Three are new: **"Lumi trả lời dựa trên những gì?"**, **"Lumi có thay thế bác sĩ không?"** and **"Lumi có mất phí không?"**. All three credit/plan questions are gone. Only Q1 has an answer in Figma. PROPOSED answers are in §A.6 / §C. `seo.ts` publishes these answers as FAQPage JSON-LD.
5. **The Lumi Kết is centred and has no photo, no "Xem các gói" and no store badges.** It has only the mascot, the title and a white pill "Mở Lumi trong app" (§A.7). The web has no target for that pill. Recommendation: render the V9 black badge row in its place until an app link exists (owner decision, §E.4).
6. **Every V9 Kết that uses `Closing` (home, Năm đầu đời, Chặng 2–4) becomes the centred dark card:** no bear photo, padding 64 / 56, **official-style black badges with logos**, caption **"Miễn phí trên iPhone và Android."** (§B.2). Changing `Closing.tsx` changes all three pages at once.
7. **The badges imitate the official localised artwork, but they are not the official artwork.** They are black with a 1 px #A6A6A6 border, r 12, a real Apple-logo path and a legacy-coloured four-triangle Play mark, with live Be Vietnam Pro text "Tải về trên" / "App Store" and "Tải nó trên" / "Google Play". The built badges are white, with placeholder glyphs (a circle and a triangle) and "Tải trên" on both. **Use Apple's and Google's official vi / en badge files** (with owner OK for the download), not a hand-built copy. The pre-launch rule still applies: static pictures plus "Sắp có trên iPhone và Android." (§B.3).
8. **Claims:** removing Gói clears the Q-071 / D-074 / Q-072 / D-081 conflicts (good news). But the new section claims reads that Lumi does **not** have: **"Tìm ảnh lần đầu con cười"**, the **"Tìm ảnh"** chip, **"Tóm tắt tuần"**, **"Hôm nay ai đã chăm con?" → "Bố ghi 4 lần · Bà 2 lần"**, and "kỷ niệm" in the hero lead. The rest match D-088 / P-167 Phase 2 reads, which are **on dev only** (§C).

---

# PART A — V9 · Lumi · Desktop (`785:9913`)

## A.0 Section order (built → V9)

| # | V9 section | Node | y · h | Background | Padding (t r b l) | Built (`LumiPage.tsx`) | Change |
|---|---|---|---|---|---|---|---|
| 1 | Nav | 785:9914 | 0 · 81 | `cloud` | 20 96 | `Chrome` | link order (§A.1) |
| 2 | Hero | 785:9924 | 81 · 889 | page | as V8 | `LumiHero` `#gioi-thieu` | **copy + one CTA** (§A.2) |
| 3 | Lợi ích | 785:10017 | 970 · 495 | `surface` | **4** 96 96 | `LumiBenefits` `#loi-ich` | none (§A.3) |
| — | ~~Điều hướng nhanh~~ ("Trên trang này:") | — | — | — | — | `LumiQuickNav` | **REMOVED** |
| — | ~~Một ngày cùng Lumi~~ | — | — | — | — | `LumiDay` `#mot-ngay` | **REMOVED** |
| — | ~~Một ngày dành riêng cho con~~ | — | — | — | — | `ForBabyDetail` `#mot-ngay-cho-con` | **REMOVED** |
| 4 | **Lumi hiểu cả app** | **791:68734** | 1465 · 931 | **#F5F5FF (raw)** | 96 | — | **NEW** (§A.4) |
| 5 | Cách Lumi làm việc | 785:10386 | 2396 · 647 | page (dark card) | 0 96 96 | `LumiHow` `#cach-lam-viec` | none (§A.5) |
| — | ~~Gói~~ (toggle, 3 tiers, note, table, credits) | — | — | — | — | `LumiPlans` `#goi` | **REMOVED** |
| 6 | Hỏi đáp | 785:10690 | 3043 · 555 | page | 96 | `LumiFaq` `#hoi-dap` | **questions** (§A.6) |
| 7 | Kết | 785:10721 | 3598 · 349 | page (gradient card) | 0 96 **3** | `LumiCta` `#tai-app` | **layout** (§A.7) |
| 8 | Footer | 785:10733 | 3947 · 184 | page | as V8 | `Chrome` | none |

Removals are confirmed by the outline: the direct children of `785:9913` are exactly the 8 frames above. No node carries "Trên trang này:", "Một ngày cùng Lumi", "Một ngày dành riêng cho con", "Theo tháng", "Free", "79.000đ", "Giá mỗi tháng" or "Lượt hỗ trợ là gì?".

**New `LumiPage` order:** `LumiHero`, `LumiBenefits`, **`LumiModules`** (new), `LumiHow`, `LumiFaq`, `LumiCta`.

**Cleanup once nothing renders them** (checked with grep):
- `LumiQuickNav` + `lumiPage.quickNav` + `.jump--lumi` (v8.css). Keep the base `.jump`, which `FirstYearPage.tsx` uses.
- `LumiDay` + `lumiPage.day` + `DayCard` + the `.lp-day` CSS (lumi.css). The home feature mocks it reused stay.
- `ForBabyDetail` + `forBaby.detail` + `.for-baby-detail` CSS (v8.css and lumi.css). **Keep `forBaby.mock` / `TodayMock`**, which the home uses.
- `LumiPlans` + `lumiPage.plans` (all of it) + `PlanTier` + the `.lp-plans` / `.lp-period` / `.lp-tier*` / `.lp-table*` / `.lp-credits*` CSS.
- `lumiPage.hero.plans` + `.lp-outline` (used only by the hero's second button).
- `lumiPage.cta.plans` + `.lp-cta__plans` + `.lp-cta__photo`.
- The `LumiPlans` doc comment about noindex ("the page is dev-only") goes with it.

No other page links to `#goi`, `#mot-ngay` or `#mot-ngay-cho-con` (checked).

## A.1 Nav (785:9914)

Same as V8 (cloud, `padding: 20px 96px`, "Bắt đầu" pill) except **the link order**: **"Năm đầu đời" · "Chăm sóc" · "Kỷ niệm" · "Lumi" · "Hỏi đáp"** (x 762, 889, 995, 1085, 1153). V8 and the build use "Chăm sóc" · "Kỷ niệm" · "Lumi" · "Năm đầu đời" · "Hỏi đáp". The V9 home (`785:7032`) has the same new order. Its fourth layer is named "Trợ Lý Lumi", so check the home spec for that label. **The V9 Chặng 2 nav keeps the old order** (§B.1, §E.7). The nav is shared (`Chrome.tsx`), so follow the V9 home spec. On this page, "Hỏi đáp" still points to local `#hoi-dap` and "Bắt đầu" to local `#tai-app`.

## A.2 Hero (785:9924)

The mock-up `785:9948` was verified node by node and is **unchanged**: same positions (chat 72 / 48, "Đã lưu" float −40 / 30, expense float 324 / 613, "Ví dụ minh hoạ" chip 391 / 24), same strings and same drafts. It still draws "Bỉm · 289.000đ" while the build keeps "Bỉm · 289.000 ₫". The eyebrow "Lumi · Trợ lý đồng hành trong Child Life" (`care-sleep-soft` / `care-sleep-ink`) is unchanged. The three chips "Bạn xác nhận trước khi lưu" · "Trả lời từ nhật ký của con" · "Cả nhà dùng theo quyền" are unchanged. Copy column `gap: 24px`; the type sizes are unchanged (H1 Bold 52 / 1.1, lead Medium 19 / 1.55 `ink-muted`).

| Key path | Built | V9 (verbatim) |
|---|---|---|
| `lumiPage.hero.title` | ["Nhắn một câu.", "Lumi soạn sẵn bản ghi."] | **["Lumi hiểu cả hành trình", "của con."]** (two hard lines) |
| `lumiPage.hero.lead` | "Lumi là trợ lý của cả nhà trong Child Life. Gõ như đang nhắn tin, chụp một tấm ảnh hay hỏi một câu — Lumi soạn sẵn bản ghi, trả lời từ chính nhật ký của con và gợi ý một việc nhỏ cho hôm nay." | **"Lumi đọc được nhật ký, mốc phát triển, bữa ăn, kỷ niệm và lịch nhắc trong Child Life — để ghi hộ, trả lời và gợi ý đúng với con bạn. Miễn phí cho mọi gia đình."** |
| `lumiPage.hero.tryNow` | "Mở Lumi trong app" | unchanged: `mint-deep`, `padding: 16px 28px`, SemiBold 17 `on-mint-deep`, 214 × 54 → `#tai-app` |
| `lumiPage.hero.plans` | "Xem các gói" (outline + chevron) | **REMOVED.** The CTA row holds only the primary button. |

Claims in the new title and lead: §C rows 1–3. Optional: `lumiPage.meta.description` still starts "Kể một câu, Lumi soạn sẵn…". A proposal is in §D (SEO text, not drawn).

## A.3 Lợi ích (785:10017) — unchanged

Verified: same eyebrow, H2 "Bớt việc phải nhớ, thêm thời gian bên con.", four cards, icons, tints, and the 4 px top padding (built as 96, per the 33 §0.1 bug). The section now sits directly above the lilac "Lumi hiểu cả app" band: `surface` then #F5F5FF, a visible colour change with no divider.

## A.4 Lumi hiểu cả app (791:68734) — NEW

Screenshot: `scratchpad/v9/lumi-hieu-ca-app.png`. Proposed id **`#hieu-ca-app`**, `aria-labelledby="modules-title"`.

### A.4.1 Layout

- **Section:** `background: #F5F5FF (raw)`. No token; the nearest is `care-sleep-soft` #EDEEFC, and the build already uses #F5F5FF for the stage 4 hero (`v8.css`). Then `display: flex; flex-direction: column; align-items: center; gap: 44px; padding: 96px;` (1440 × 931).
- **Head** (`791:68735`): `column; align-items: center; gap: 12px`.
  - Eyebrow pill: `mint-soft` / `mint-text`, `padding: 6px 12px; r 999`, SemiBold 13: **"Một trợ lý, hiểu mọi phần của app"** (`<Eyebrow tone="mint">`)
  - H2: Bold **42 / 1.16** `ink`, centred, 820 wide, one line: **"Hỏi về bất cứ điều gì của con."**
  - Lead: Medium **18 / 1.55** `ink-muted`, centred, 680 wide, 2 lines: **"Lumi kết nối dữ liệu từ mọi thứ về con nên trả lời đúng với con bạn, không chung chung."**
- **Lumi pill** (`791:68753`, 299 × 72): `surface`, `box-shadow: var(--shadow-card)`, `display: flex; align-items: center; gap: 10px; padding: 10px 18px 10px 10px; border-radius: 999px`.
  - Mascot 52: the `Chat/Nút trợ lý` instance, i.e. `<LumiMascot size={52} />` (`components/kit.tsx`), as in the hero eyebrow.
  - Text column, nowrap: Bold 16 `ink` **"Lumi"**, then Medium 12 `ink-muted` **"Đọc dữ liệu từ 6 phần của Child Life"**.
- **Modules** (`791:68757`): drawn as two rows of three (`gap: 16px` between rows and cards), 1248 wide. Build it as **one `<ul>` grid**: `display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; width: 100%`. Cards are 405 wide and 167 tall.
  - **Card:** `surface`, `box-shadow: var(--shadow-card)`, `border-radius: 24px; padding: 18px; display: flex; flex-direction: column; align-items: flex-start; gap: 12px`.
  - **Head row:** `display: flex; align-items: center; gap: 10px; width: 100%`.
    - Icon box `padding: 8px; border-radius: 12px` (`.lp-icon` already has exactly this), holding a 16 px icon.
    - Text column, nowrap: title Bold **16** `ink` (`<h3>`), subline Medium **12** `ink-muted`.
  - **Question bubble** ("Hỏi"): `background: mint-deep; padding: 10px 14px; border-radius: 18px`, hugging its content (`align-self: flex-start`). Text SemiBold **14** `on-mint-deep`, nowrap at desktop: the question **including the curly quotes**.
  - **Answer tag** ("Đáp"): `background: cloud; display: flex; align-items: center; gap: 8px; padding: 8px 12px; border-radius: 14px; width: 100%`. Contents: `spark` 14 with stroke `mint-text` (#06716D), then SemiBold **14** `ink`.
- **"Lumi làm được" row** (`791:68850`, 732 wide): `display: flex; align-items: center; justify-content: center; gap: 8px`.
  - Label SemiBold 14 `ink-muted` **"Lumi có thể:"**
  - 5 chips, no icon: `mint-soft` / `mint-text`, `padding: 6px 12px; r 999`, SemiBold 13, nowrap.

### A.4.2 The six modules (verbatim)

Icon stroke colours were read from the downloaded SVGs. Every icon is in the landing `Icon` map (`components/primitives.tsx`: `today`, `star`, `drop`, `memories`, `family`, `clock`, `spark`). The stroke follows `color`, so the existing tint classes recolour it.

| # | Node | Icon · stroke | Box fill → class | Title | Subline | Question (bubble) | Answer (tag) |
|---|---|---|---|---|---|---|---|
| 1 | 791:68759 | `today` (draws as a sun) · #1D5F99 `care-bottle-ink` | `care-bottle-soft` → `tint--bottle` | **"Chăm sóc"** | **"Ghi bú, ngủ, tã"** | **"“Hôm nay con bú bao nhiêu?”"** | **"6 cữ · 720 ml"** |
| 2 | 791:68774 | `star` · #4447A8 `care-sleep-ink` | `care-sleep-soft` → `tint--sleep` | **"Phát triển"** | **"Mốc & gợi ý theo tuổi"** | **"“Con 8 tháng thường làm được gì?”"** | **"Bò, ngồi vững · 3 mốc"** |
| 3 | 791:68788 | `drop` · #173D44 `ink` | `sunshine-soft` → `tint--sun` | **"Dinh dưỡng"** | **"Ăn dặm & món ăn"** | **"“Con 6 tháng có thể ăn gì?”"** | **"Cháo rây, bí đỏ, chuối"** |
| 4 | 791:68803 | `memories` · #2F6B24 `care-diaper-ink` | `care-diaper-soft` → `tint--diaper` | **"Kỷ niệm"** | **"Ảnh, thiệp, video"** | **"“Tìm ảnh lần đầu con cười”"** | **"Tìm thấy 3 ảnh · 5 tuần"** |
| 5 | 791:68818 | `family` · #06716D `mint-text` | `mint-soft` → `tint--mint` | **"Cả nhà"** | **"Người chăm & bàn giao"** | **"“Hôm nay ai đã chăm con?”"** | **"Bố ghi 4 lần · Bà 2 lần"** |
| 6 | 791:68835 | `clock` · #173D44 `ink` | **`cloud`** (#F6FCFB on a white card, almost invisible; §E.2) → propose `tint--plain` (`surface-2` / `ink`) | **"Nhắc lịch"** | **"Lịch tiêm & nhắc nhở"** | **"“Mũi tiêm tiếp theo khi nào?”"** | **"6 trong 1 · thứ Hai tới"** |

Chips (verbatim, in order): **"Ghi hộ từ một câu nhắn"** · **"Trả lời từ nhật ký"** · **"Tóm tắt tuần"** · **"Tìm ảnh"** · **"Gợi ý theo tuổi"**.

The answers are illustrative values for the sample baby (Teddy, around 8 months). Unlike the hero, this section draws no "Ví dụ minh hoạ" chip (§E.9).

### A.4.3 Build notes

- Component `LumiModules` in `sections/LumiDetail.tsx`, between `LumiBenefits` and `LumiHow`. Per-card look, by index, in code: `[{icon:'today',tint:'bottle'},{icon:'star',tint:'sleep'},{icon:'drop',tint:'sun'},{icon:'memories',tint:'diaper'},{icon:'family',tint:'mint'},{icon:'clock',tint:'plain'}]`. Do not add `ink--*`: each `tint--*` already sets the matching ink colour (`features.css`), except `tint--sun`, whose ink is `ink`, which matches the drawn `drop`. The spark uses `ink--mint`.
- Content (new): `lumiPage.modules = { eyebrow, title, lead, lumi: { name, sub }, items: [6 × { title, sub, q, a }], canLabel, can: [5 strings] }`. Type `items` as a 6-tuple and `can` as a 5-tuple. Store `q` **without** the curly quotes and render `“{q}”` in JSX: vi and en both use “ ”, so this keeps the strings clean for i18n. Render `lumi.name` with the existing `lumiPage.hero.mock.name` ("Lumi") or a new key.
- Markup: `<section id="hieu-ca-app" class="lp-modules" aria-labelledby="modules-title">`, a `<header>` (eyebrow, `<h2 id="modules-title">`, `<p class="lead">`), the pill as a `<p>` or `<div>` with the mascot `aria-hidden`, `<ul class="lp-modules__grid">` of `<li>` (each: `<h3>`, a subline `<p>`, a question `<p class="lp-module__q">`, and an answer `<p class="lp-module__a">` with `<Icon name="spark">`), then `<p>` "Lumi có thể:" with a `<ul>` of chips. The question/answer pair is an illustration and not interactive, so do not use `<button>` or a link.
- Motion: as on the rest of the page, add `reveal` on the head and `staggerStyle(i)` on the cards.
- **Mobile (no frame; proposal):** the section uses `padding: 56px 20px; gap: 28px` with H2 Bold 28 / 1.2 and lead 16. The pill stays centred. The grid is **1 column** below 720 px and 2 columns from 720 to 1119 px (`gap: 12px`). Bubble text may wrap (`white-space: normal`). The chip row wraps and centres (`flex-wrap: wrap`), with the label on its own line.

## A.5 Cách Lumi làm việc (785:10386) — unchanged

Verified, identical to the build: the dark card #163D44, eyebrow "Lumi làm việc thế nào", H2 "Lumi soạn sẵn. Bạn là người quyết định.", steps 1–3 and the three trust lines. The third line is still "Lumi không thay bác sĩ và không chẩn đoán. Khi lo lắng về sức khoẻ, Lumi chỉ tới hướng dẫn an toàn và số khẩn cấp". The trust row is now `flex: 1` per item with `gap: 28px`, which the build's grid already handles. The steps row still overflows (1126 in 1120) and is already fixed in the build.
**Spacing:** the section's top padding is still 0. It now follows the lilac band's 96 px bottom padding, so the dark card **starts exactly at the band's lower edge** (`lumi-full-thumb.png`). Keep the build's current `lp-section` top spacing so the card sits on the page background below the band. It must not touch the band (§E.1).

## A.6 Hỏi đáp (785:10690) — 5 questions

Layout is unchanged: left head (eyebrow "Hỏi đáp", H2 Bold 36 / 1.2 **"Những điều ba mẹ hay hỏi về Lumi."**) and a 776-wide list, `gap: 10px`. Items are `surface`, 1 px `separator` (the open one 1 px `mint`), `padding: 18px 20px; r 18`, with the question SemiBold 16 `ink` and the answer Medium 15 / 1.55 `ink-muted`. The first item is open (`close` icon); the others are closed (`plus`).

| # | Node | Question (verbatim) | Answer in Figma | Today in content | Action |
|---|---|---|---|---|---|
| 1 | 785:10696 | **"Lumi có tự ghi vào nhật ký không?"** | **"Không. Lumi soạn nháp, bạn xem lại và bấm lưu. Bạn có thể sửa hoặc bỏ từng bản."** | same, item 1 | keep, `open: true` |
| 2 | 791:68862 | **"Lumi trả lời dựa trên những gì?"** | none | — | **NEW**, PROPOSED answer below |
| 3 | 791:68866 | **"Lumi có thay thế bác sĩ không?"** | none | — | **NEW**, PROPOSED answer below |
| 4 | 791:68870 | **"Lumi có mất phí không?"** | none | — | **NEW**, PROPOSED answer below (**owner must confirm**, §C row 1) |
| 5 | 785:10717 | **"Thông tin của con được dùng thế nào?"** | none | item 6, PROPOSED: "Lumi chỉ đọc những gì bạn gửi và phần nhật ký bạn được quyền xem, để trả lời và soạn nháp. Bạn đồng ý trước khi dùng và tắt được bất cứ lúc nào." | keep the PROPOSED answer (legal review Q-070 / P-160 still open) |

**Removed** (no node in V9): "Hết lượt hỗ trợ thì sao?", "Gói Free có bị thiếu tính năng không?", "Có thể đổi gói giữa chừng không?", "Ai trong nhà dùng chung lượt?", together with their PROPOSED answers. This matches the note "bỏ … câu hỏi về lượt, gói". Change `faq.items` to a **5-tuple** in `types.ts`.

PROPOSED answers (engineering drafts for owner review, D-012; each claim checked in §C):
- Q2: **"Từ những gì nhà bạn đã ghi trong Child Life — bú, ngủ, tã, tăng trưởng, mốc, ăn dặm, lịch tiêm và nhắc việc — cùng nội dung tham khảo theo tuổi của con. Câu trả lời có liên kết để mở lại đúng phần đó trong app."**
- Q3: **"Không. Lumi không chẩn đoán. Khi bạn lo lắng về sức khoẻ của con, Lumi chỉ tới hướng dẫn an toàn và số khẩn cấp; hãy liên hệ bác sĩ hoặc cơ sở y tế khi cần."**
- Q4: **"Mọi gia đình đều dùng được Lumi miễn phí. Ghi chép thường ngày và xem nhanh nhật ký không tính lượt; những việc Lumi cần suy nghĩ thêm, như đọc ảnh hoá đơn, có giới hạn mỗi tháng."**

`seo.ts` emits `lumiPage.faq.items` as FAQPage JSON-LD on `/lumi/`. **Every item needs an answer before prod**, or Q2–Q4 must be left out of the JSON-LD until the owner signs the copy.

## A.7 Kết (785:10721) — centred, no photo, no badges

Section: page background, `padding: 0 96px 3px`. The 3 px bottom is the same bug as V8; keep the build's 96.
Card `785:10722` (1248 × 346): `background: linear-gradient(159.71deg, #2BC4B5 14.286%, #545CDB 85.714%)` (the built `--lumi-deep` → `--lumi-indigo`; the angle was 156.24° in V8), `border-radius: 40px; padding: 56px; display: flex; align-items: center; justify-content: center`.
Content `785:10723`: 640 wide, `column; align-items: center; gap: 18px`:
1. Mascot 56 (`<LumiMascot size={56} />`, unchanged)
2. H2 Bold 40 / 1.18 **white, centred**, 2 lines: **"Để Lumi lo phần ghi chép. Bạn dành thời gian cho con."** (unchanged string, `lumiPage.cta.title`)
3. White pill: `surface`, `padding: 14px 22px; r 999`, SemiBold 16 `ink`, **"Mở Lumi trong app"**

| Element | Built | V9 |
|---|---|---|
| Layout | row: copy left, photo 440 × 300 right (`scenes.nowBaby`) | **centred column, no photo** |
| Download | `AppCta tone="dark"` (white badges + caption) | **none drawn**; only the pill "Mở Lumi trong app" |
| "Xem các gói" (`lumiPage.cta.plans` → `#goi`) | text button | **REMOVED** (Gói is gone) |

Recommendation (owner / design, §E.4): `#tai-app` is where "Bắt đầu" (nav) and the hero's "Mở Lumi trong app" both land. The page must therefore still offer the download. The drawn pill has no web target: D-059 app links cover `/i/{token}` only. Build the card as drawn (centred, no photo), and **in the pill's slot render the V9 badge row + caption** (§B.3, the same component as the shared Kết). Add `lumiPage.cta.tryNow` = "Mở Lumi trong app" (reuse `hero.tryNow`) only if an app link is added later (a G-gap). If the owner insists on the pill now, link it to the store listing when `launched`, and hide it before launch, because the V8 component rule forbids a "sắp có" tap.
White text on the teal start of the gradient still fails contrast (33 §10). The text is now centred over the whole gradient, so the left half is the weakest; this is unchanged and still a design question.

## A.8 Footer — unchanged

## A.9 Image slots

**None are left on the Lumi page.** The Một ngày receipt and Peach slots and the Kết Sun photo go with their sections. `scenes.nowBaby` stops being used on this page; keep it if other pages import it. Nothing new is needed for "Lumi hiểu cả app".

---

# PART B — V9 · Chặng 2 (`785:10743`) vs the built V8 template

## B.1 Unchanged (verified)

| Section | Node | Check |
|---|---|---|
| Nav | 785:10744 | **V8 order kept**: "Chăm sóc" · "Kỷ niệm" · "Lumi" · "Năm đầu đời" · "Hỏi đáp" (x 762 … 1153). This differs from the V9 home and Lumi page (§A.1, §E.7). |
| Trạng thái band | 785:10754 | same geometry (text 697 × 18 at x 384.5, clock 16), layer name identical. Text not re-read; it is assumed to be the V8 string, already built as `stagePage.band`. |
| Hero | 785:10757 | copy `785:10758` verified: chips "Đang phát triển" / "Chặng 2 · 1–3 tuổi", H1 "Con tập khám phá.", the same lead, primary "Dùng Child Life cho năm đầu đời", and **still the secondary "Nhận tin khi chặng 2 sẵn sàng"**, which stays unbuilt (no email flow, R-170, 36 §B.4). The art frame is unchanged (512 tall). |
| Định hướng | 785:10805 | verified: every string, tint, icon, dashed card and note is identical. |
| Chặng khác | 785:10841 | verified: identical (mint-bordered stage 1 card "Đang có trong app", stage 3 card "Đang phát triển"). |
| Footer | 785:10864 | identical |

## B.2 Kết (785:10856) — centred, badges with logos, no photo

The frame shrinks from 532 to 460 tall, which makes the page 2034 instead of 2106. The home (`785:7872`) and Năm đầu đời (`785:9895`) Kết frames have the **same structure** (same child sizes and positions, badge group at 131 / 113), so this one change to the shared `sections/Closing.tsx` serves all three pages. Confirm against the home spec.

### B.2.1 Desktop

- Section (unchanged): `background: surface; padding: 24px 96px 96px`.
- Card `794:8814` (1248 × 340): `background: #163D44 (raw); border-radius: 40px; display: flex; align-items: center; justify-content: center; **padding: 64px 56px**`. The built padding is 56 all round.
- Content `794:8815` (651 wide, hugs): `display: flex; flex-direction: column; **align-items: center; gap: 20px**`. The built copy is left-aligned with gap 16.
  1. H2 Bold 40 / 1.18 white, **centred, one line (nowrap at 1440)**: "Bắt đầu từ năm đầu đời của con." (`closing.title`, unchanged)
  2. Medium 17 / 1.55 **#CCE0E0 (raw)**, centred, one line: "Ghi chép, nhắc nhở và kỷ niệm — cả nhà cùng một nơi." (`closing.sub`, unchanged)
  3. Badge row `794:8818` (389 × 63): `display: flex; gap: 12px; align-items: center` (§B.3)
  4. Caption Medium **13** / normal **#CCE0E0**, centred: **"Miễn phí trên iPhone và Android."** The built caption is "Tải miễn phí trên iPhone và Android." (`stores.caption`) and, before launch, "Sắp có trên iPhone và Android." (`stores.captionSoon`).
- **Photo removed** ("bỏ ảnh gấu"): drop `.closing__photo` and `photos.sun` from `Closing.tsx`.

CSS delta (desktop, ≥ 1120 px) on `v8.css` `.closing*`: `.closing__card { justify-content: center; padding: 64px 56px; }`, `.closing__copy { flex: none; align-items: center; gap: 20px; text-align: center; }`, `.closing__title { white-space: nowrap; }` (or `text-wrap: balance` for safety at 1120–1280), `.app-cta--dark { align-items: center; }`, caption centred. Delete the `.closing__photo` rules.

### B.2.2 Mobile (from the home's `785:8683`; the stage page has no mobile frame)

Section `padding: 8px 20px 48px` (as built). Card 350 wide: `padding: 28px 20px; border-radius: 28px; #163D44`. Content `column; gap: 16px; **align-items: flex-start**`. **Mobile stays left-aligned**; only desktop is centred. Title Bold 28 / 1.18 white; sub Medium 15 / 1.55 #CCE0E0. Badges are **stacked and full width** (310), `gap: 12px`, each centred inside (§B.3 mobile sizes). Caption Medium **12** #CCE0E0, left. This matches the built mobile Kết except for the badge style and the caption string.

## B.3 Store badges — Figma vs the build

### What Figma draws (V9, all Kết frames)

| Property | Desktop (`794:8819` / `794:8825`) | Mobile (`793:8980` / `793:8986`) |
|---|---|---|
| Fill / border | **black #000000**, **1 px #A6A6A6**, r **12** | same, r **10** |
| Padding / gap | `10px 18px 10px 14px`, gap 10 | `9px 15px 9px 12px`, gap 9, `justify-content: center`, full width |
| Logo | 28 × 28 | 24 × 24 |
| Line 1 | Medium **11** white: **"Tải về trên"** (Apple) / **"Tải nó trên"** (Google) | Medium 9 |
| Line 2 | SemiBold **21** white: **"App Store"** / **"Google Play"** | SemiBold 18 |
| Size | 178 × 63 / 199 × 63 | 310 × ~49 each |
| Font | Be Vietnam Pro (live text) | same |

Logo nodes: Apple `794:8820` "Logo App Store" (one white path "Vector"; child id not exposed by `get_metadata`, presumably `794:8821`); Google `794:8826` "Logo Google Play" (four paths "Vector" … "Vector_4", presumably `794:8827–8830`). The same frames recur on the home `790:8826` / `790:8832`, Năm đầu đời `793:68571` / `793:68577` and home mobile `793:8981` / `793:8987`. Downloaded for inspection: `scratchpad/v9/badges/fig-apple.svg`, `fig-play.svg`.
- **Apple logo:** a real Apple silhouette path (bitten apple and leaf), fill white, 28-px box.
- **Google Play logo:** the four-triangle Play mark, filled **#00D7FE / #FFCE00 / #00F076 / #FF3A44**. These approximate the **pre-2022** Play icon colours. They are **not** the current official Play logo (new geometry, Google brand colours).

**Verdict:** this is the **style** of the official badges (Apple "Download on the App Store", black with the #A6A6A6 hairline; Google "GET IT ON Google Play", black with a grey border), in their **Vietnamese localisations** ("Tải về trên App Store", "TẢI NÓ TRÊN Google Play"). It is **not the official artwork**: the text is live Be Vietnam Pro, Google's prefix is sentence case instead of caps, and the Play mark is a legacy-coloured redraw. **Black badges** with logos, not white.

### What is built

- `assets/figma/store-apple.svg` / `store-apple-dark.svg`: 25.3 px **placeholder** "apple" (a circle + a rotated ellipse), white / #141417. `store-play.svg` / `store-play-dark.svg`: a **plain triangle**, white / #141417. The `StoreBadges` doc comment already says these must be replaced before launch.
- `AppCta` always renders `StoreBadges variant="light"`: **white** badges (#fff, text #141417), r 16.1, `padding: 11.5px 23px 11.5px 18.4px`, glyph 25.3, text 12.65 / 21.85. There is no border.
- Text: `stores.appStore.prefix` = `stores.googlePlay.prefix` = **"Tải trên"** (vi); en "Download on the" / "Get it on".

### Recommendation

1. **Use the official badge artwork**, not a hand-built copy:
   - Apple: App Store Marketing Guidelines badge, black, `vi` "Tải về trên App Store" and `en` "Download on the App Store".
   - Google: the Play badge generator, `vi` "TẢI NÓ TRÊN Google Play" and `en` "GET IT ON Google Play".
   - Store each as an SVG in `assets/` per locale. Render as `<img alt="Tải về trên App Store">` (en "Download on the App Store") inside the link, or as a picture before launch.
   - Both guidelines forbid recreating or altering the badge, and require equal heights and clear space. The official Apple badge is 40 px tall at 1× (≥ 40 px on screen); Figma draws 63 / 49. Pick one height for both badges, e.g. 56 desktop and 48 mobile.
   - Downloading the files is the implementer's step and needs the owner's OK (source and licence).
2. If the owner prefers the drawn version, replace the four placeholder SVGs with the two Figma logos, set `prefix` to "Tải về trên" / "Tải nó trên", and restyle `.badge` (black, 1 px #A6A6A6, r 12 / 10, the paddings above). This still is not the official artwork, and Google's guidelines do not allow a recoloured or redrawn mark.
3. **Pre-launch rule unchanged** (R-170 note, owner 2026-10-19): while `storeLinks` are `null`, the badges are static pictures (`badge--static`, `aria-hidden`) and the caption is `stores.captionSoon` "Sắp có trên iPhone và Android.". After launch the caption becomes the new **"Miễn phí trên iPhone và Android."** Change `stores.caption` (vi) to this; en "Free on iPhone and Android." is already right.
4. The hero download blocks (home `HomeIntro`, `FirstYearPage`) also use `AppCta` with white badges. Whether they switch to black badges is decided in the V9 home / Năm đầu đời specs. Make the badge colour a prop (`variant`), not a global change.

---

# PART C — Claims to check (`docs/product/business-map.md`)

| # | Claim (verbatim) | Map | Status |
|---|---|---|---|
| 1 | Hero lead "… **Miễn phí cho mọi gia đình.**"; FAQ "**Lumi có mất phí không?**" (no answer drawn) | **P-159** (Free 20 credits / calendar month, Premium 200), **D-075 #1** (one pool; a beta may give Premium free), **D-088 / `lumi-plan.md` §8** (rule-read logs, read cards and app actions cost **0**), **Q-071** open | **True with a limit:** every family gets Lumi, and routine logs and recognised reads are free, but model calls draw from a monthly pool. Acceptable only if the FAQ answer says so (PROPOSED Q4, §A.6). Owner to confirm the wording. |
| 2 | **Removed:** Gói (Free · Plus · Pro, "30 / 300 / 1.000" lượt, "79.000đ" / "179.000đ", "Nâng cấp lên …", VAT note, "Giá mỗi tháng" row, "Các gói có cùng tính năng…", credit rules) and the credit / plan FAQs | **Q-071** (prices open), **D-074** (store payments later), **Q-072** / Premium groups A/B ("cùng tính năng"), **D-081** (credits out of sight), D-088 (rule copy out of date) | **Good news.** Every open pricing / credit conflict from 33 §16 and 36 §C.1 rows 1–7 leaves the page; the "$3.99 / $8.99" question is moot. Record in Q-039 / R-170 when shipped. |
| 3 | H1 "**Lumi hiểu cả hành trình của con.**"; lead "Lumi đọc được nhật ký, mốc phát triển, bữa ăn, **kỷ niệm** và lịch nhắc…" | **D-088** "answers about every module and opens it"; **P-167 #5** read cards (day, diapers, pump, growth, timer, vaccines, reminders, spending, Ăn dặm, Mốc, first aid, library); `lumi-plan.md` §13.1: Phase 2 reads **done on dev, prod not deployed**; **P-155** (no long-term memory); **Q-039** (stages 2–4 not in the app) | Nhật ký / mốc / bữa ăn / lịch nhắc ✓ on dev. **"kỷ niệm" ✗**: there is no Kỷ niệm read, and Phase 3 "a photo to the album" is not started. "cả hành trình" reads as beyond the first year (Q-039). Propose dropping "kỷ niệm" from the lead, or ship after a Kỷ niệm read exists. **The prod landing must wait for the Lumi Phase 2 prod deploy.** |
| 4 | "**Lumi kết nối dữ liệu từ mọi thứ về con nên trả lời đúng với con bạn, không chung chung.**"; pill "**Đọc dữ liệu từ 6 phần của Child Life**" | **D-088**, **P-167** | ✓ (dev). Lumi reads more than 6 areas (Chi tiêu is private, D-075 #2; Sơ cứu; Thư viện); "6" counts the cards and is not a limit. |
| 5 | Chăm sóc "“Hôm nay con bú bao nhiêu?”" → "6 cữ · 720 ml" | P-167 #5 day card (`phase2-review-2026-10-20.md`) | ✓ |
| 6 | Phát triển "“Con 8 tháng thường làm được gì?”" → "Bò, ngồi vững · 3 mốc" | P-167 #5 Mốc / Giai đoạn read; **D-082** (unreviewed guidance footnote) | ✓ on dev; milestone content is unreviewed (D-082 / D-078 #6), so Lumi's answer carries the footnote. |
| 7 | Dinh dưỡng "“Con 6 tháng có thể ăn gì?”" → "Cháo rây, bí đỏ, chuối" | `meal_ideas` reads the solids diary (P-167, D-085 / **D-086**); D-083 nutrition review; Q-039 | ✓ on dev; food suggestions are health-adjacent and still need the D-082 caveat. |
| 8 | Kỷ niệm "“**Tìm ảnh lần đầu con cười**”" → "**Tìm thấy 3 ảnh · 5 tuần**"; chip "**Tìm ảnh**" | No Lumi photo search in P-167 or Phase 2. Tự lưu (D-066, P-146 / P-149) recognises the baby's face on the device but does not search by moment. Remember 2 has the `p_first_smile` occasion, but Lumi does not read it. | **✗ Not built.** Lumi cannot find photos, let alone a "first smile". Owner: drop it, swap in a module Lumi can answer (e.g. Tăng trưởng "“Con nặng bao nhiêu rồi?”" → percentile card), or add it to the Lumi plan (Phase 3+ / new P-entry) and keep the card off prod until then. |
| 9 | Cả nhà "“**Hôm nay ai đã chăm con?**”" → "**Bố ghi 4 lần · Bà 2 lần**"; subline "Người chăm & bàn giao" | Phase 2 day card has counts, no per-author breakdown; handover summaries exist (D-075 #1, AI summary); shared thread (D-075 #2) | **✗ as drawn**: no read answers "who logged how often". The handover summary is a different feature. Owner: reword the question to something supported (e.g. "“Tóm tắt để bàn giao cho bà”") or add a per-author count to the day card. |
| 10 | Nhắc lịch "“Mũi tiêm tiếp theo khi nào?”" → "6 trong 1 · thứ Hai tới" | P-167 #5 vaccines read (family schedule, D-084; VN schedule abroad D-078 #3) | ✓ on dev |
| 11 | Chips "Ghi hộ từ một câu nhắn" · "Trả lời từ nhật ký" · "**Tóm tắt tuần**" · "**Tìm ảnh**" · "Gợi ý theo tuổi" | `lumi-plan.md` §1 "Thống kê, weekly summary: partly (`sleep_facts`) / ✗"; P-172 (personalization v2: an optional combined weekly summary, a plan) | "Tóm tắt tuần" **✗** (not built); "Tìm ảnh" **✗** (row 8); the other three ✓. |
| 12 | FAQ Q3 "Lumi có thay thế bác sĩ không?" (PROPOSED "Không. Lumi không chẩn đoán…") and the trust line | CH28 free health path (`lumi-plan.md` §1); P-141 emergency number per country (D-078 #2) | ✓ |
| 13 | FAQ Q2 (PROPOSED "Từ những gì nhà bạn đã ghi … cùng nội dung tham khảo theo tuổi … liên kết để mở lại") | P-167 #5 reads + module links; D-082 | ✓ on dev (no Kỷ niệm in the list on purpose). |
| 14 | Kết caption "**Miễn phí trên iPhone và Android.**"; badges "Tải về trên App Store" / "Tải nó trên Google Play" | D-004 (Android in V1); `site.ts` `storeLinks` = `null`; owner 2026-10-19 pre-launch rule (R-170) | Free download ✓ (Premium is optional). The badges cannot link yet: ship the static pictures + "Sắp có…" until listings exist. Apple / Google badge guidelines require the official artwork (§B.3). |
| 15 | Stage page claims | unchanged from 36 §C.2 | — |

---

# PART D — English drafts (engineering, for owner review; D-012)

| Key (proposed) | vi (verbatim) | en draft |
|---|---|---|
| `lumiPage.hero.title` | ["Lumi hiểu cả hành trình", "của con."] | ["Lumi understands", "your child's whole journey."] |
| `lumiPage.hero.lead` | "Lumi đọc được nhật ký, mốc phát triển, bữa ăn, kỷ niệm và lịch nhắc trong Child Life — để ghi hộ, trả lời và gợi ý đúng với con bạn. Miễn phí cho mọi gia đình." | "Lumi reads the logs, milestones, meals, memories and reminders in Child Life — to log for you, answer and suggest what fits your child. Free for every family." |
| `lumiPage.meta.description` (optional, not drawn) | — | vi: "Lumi đọc nhật ký, mốc phát triển, bữa ăn và lịch nhắc của con trong Child Life — ghi hộ từ một câu nhắn, trả lời đúng với con bạn. Bạn xem lại rồi mới lưu." / en: "Lumi reads your child's logs, milestones, meals and reminders in Child Life — logs from one message and answers for your child. You review before anything is saved." |
| `lumiPage.modules.eyebrow` | "Một trợ lý, hiểu mọi phần của app" | "One assistant that knows every part of the app" |
| `lumiPage.modules.title` | "Hỏi về bất cứ điều gì của con." | "Ask anything about your child." |
| `lumiPage.modules.lead` | "Lumi kết nối dữ liệu từ mọi thứ về con nên trả lời đúng với con bạn, không chung chung." | "Lumi connects everything about your child, so its answers fit your child — never generic." |
| `lumiPage.modules.lumi.sub` | "Đọc dữ liệu từ 6 phần của Child Life" | "Reads from 6 parts of Child Life" |
| item 1 | "Chăm sóc" / "Ghi bú, ngủ, tã" / "Hôm nay con bú bao nhiêu?" / "6 cữ · 720 ml" | "Care" / "Feeds, sleep, nappies" / "How much did baby drink today?" / "6 feeds · 720 ml" |
| item 2 | "Phát triển" / "Mốc & gợi ý theo tuổi" / "Con 8 tháng thường làm được gì?" / "Bò, ngồi vững · 3 mốc" | "Development" / "Milestones & ideas by age" / "What can an 8-month-old usually do?" / "Crawling, sitting steady · 3 milestones" |
| item 3 | "Dinh dưỡng" / "Ăn dặm & món ăn" / "Con 6 tháng có thể ăn gì?" / "Cháo rây, bí đỏ, chuối" | "Nutrition" / "Solids & recipes" / "What can a 6-month-old eat?" / "Smooth porridge, pumpkin, banana" |
| item 4 (§C row 8) | "Kỷ niệm" / "Ảnh, thiệp, video" / "Tìm ảnh lần đầu con cười" / "Tìm thấy 3 ảnh · 5 tuần" | "Memories" / "Photos, cards, videos" / "Find baby's first smile" / "Found 3 photos · 5 weeks" |
| item 5 (§C row 9) | "Cả nhà" / "Người chăm & bàn giao" / "Hôm nay ai đã chăm con?" / "Bố ghi 4 lần · Bà 2 lần" | "Family" / "Caregivers & handovers" / "Who looked after baby today?" / "Dad logged 4 times · Grandma 2" |
| item 6 | "Nhắc lịch" / "Lịch tiêm & nhắc nhở" / "Mũi tiêm tiếp theo khi nào?" / "6 trong 1 · thứ Hai tới" | "Reminders" / "Vaccines & reminders" / "When is the next vaccine?" / "6-in-1 · next Monday" |
| `lumiPage.modules.canLabel` | "Lumi có thể:" | "Lumi can:" |
| `lumiPage.modules.can` | "Ghi hộ từ một câu nhắn" · "Trả lời từ nhật ký" · "Tóm tắt tuần" · "Tìm ảnh" · "Gợi ý theo tuổi" | "Log from one message" · "Answer from your logs" · "Weekly summary" · "Find photos" · "Ideas by age" |
| `lumiPage.faq.items[1]` | "Lumi trả lời dựa trên những gì?" / PROPOSED §A.6 | "What does Lumi base its answers on?" / "On what your family has logged in Child Life — feeds, sleep, nappies, growth, milestones, solids, vaccines and reminders — plus reference content for your child's age. Each answer links back to that part of the app." |
| `lumiPage.faq.items[2]` | "Lumi có thay thế bác sĩ không?" / PROPOSED §A.6 | "Does Lumi replace a doctor?" / "No. Lumi does not diagnose. When you're worried about your child's health, Lumi points you to safety guidance and the emergency number; contact a doctor or clinic when needed." |
| `lumiPage.faq.items[3]` | "Lumi có mất phí không?" / PROPOSED §A.6 | "Does Lumi cost anything?" / "Every family can use Lumi for free. Everyday logging and quick looks at your logs don't use credits; tasks that need more thinking, like reading a receipt photo, have a monthly limit." |
| `lumiPage.cta.tryNow` (only if the pill is built) | "Mở Lumi trong app" | "Open Lumi in the app" (= existing `hero.tryNow`) |
| `stores.caption` (vi changes) | "Miễn phí trên iPhone và Android." | "Free on iPhone and Android." (unchanged) |
| `stores.appStore.prefix` (only if badges are built as drawn) | "Tải về trên" | "Download on the" (unchanged) |
| `stores.googlePlay.prefix` (only if badges are built as drawn) | "Tải nó trên" | "Get it on" (official en badge: "GET IT ON") |
| badge `alt` (official artwork) | "Tải về trên App Store" / "Tải nó trên Google Play" | "Download on the App Store" / "Get it on Google Play" |

Strings deleted with the removed sections need no translation.

---

# PART E — Ambiguities and design bugs

1. **The Cách card touches the lilac band.** "Lumi hiểu cả app" has 96 px bottom padding on #F5F5FF, and Cách has 0 top padding on the page background, so the dark card starts on the band's edge (`lumi-full-thumb.png`). Give the card the build's normal section gap. Lợi ích's 4 px top and Kết's 3 px bottom are carried over from V8 (already corrected in the build).
2. **Nhắc lịch icon box is `cloud` on a white card**, so it is practically invisible; the other five boxes are tinted. Propose `surface-2` (`tint--plain`), or ask design for a tint (e.g. `peach-soft`).
3. **Stale layer names.**
   - Hero H1 layer "Kể một câu. Lumi ghi giúp, nhớ …" vs text "Lumi hiểu cả hành trình / của con."
   - Section H2 layer "Child Life giúp gia đình bạn b…" vs "Hỏi về bất cứ điều gì của con."
   - Lead layer "Mỗi phần đều dùng được ngay tr…" vs the drawn lead.
   - Three FAQ layers named "Thông tin của con được dùng th…" carry different questions.
   - Hero button layer "Nút · Dùng thử Lumi" says "Mở Lumi trong app".
   Copy the text, never the names.
4. **The Lumi Kết has no download and an untargetable pill**, yet "Bắt đầu" and the hero CTA land on `#tai-app`. Recommendation in §A.7 (badge row in the pill's slot); owner / design to confirm.
5. **No mobile frame** for the Lumi page or Chặng 2. The module-grid and Kết mobile layouts are proposals (§A.4.3, §B.2.2 from the home mobile).
6. **The Kết is centred on desktop but left-aligned on the home mobile frame** (`785:8683`). That looks intentional; build it as drawn.
7. **Nav order differs between V9 frames:** home and Lumi use "Năm đầu đời" · "Chăm sóc" · "Kỷ niệm" · "Lumi" · "Hỏi đáp"; Chặng 2 keeps V8's "Chăm sóc" · "Kỷ niệm" · "Lumi" · "Năm đầu đời" · "Hỏi đáp". The nav is one component; follow the V9 home and tell design that Chặng 2 is stale.
8. **FAQ answers 2–5 are missing in Figma.** The PROPOSED answers go into the FAQPage JSON-LD, so the owner must sign them before prod.
9. **"Lumi hiểu cả app" shows sample data with no "Ví dụ minh hoạ" marker** (the hero mock-up has one). Ask design whether the section needs one. Proposal: none, since the bubbles read as examples.
10. **Module claims that Lumi cannot do yet** (§C rows 8, 9, 11): "Tìm ảnh lần đầu con cười", "Hôm nay ai đã chăm con?", "Tóm tắt tuần", "Tìm ảnh". Design and owner must replace them or accept them as roadmap. Without that the section misleads.
11. **The badges are lookalikes, not the official artwork**, with a legacy-coloured Play mark (§B.3). Use the official files.
12. **Caption "Miễn phí…" vs the pre-launch "Sắp có…"**: Figma draws the post-launch state only; keep the owner's pre-launch rule.
13. **Chặng 2 still draws "Nhận tin khi chặng 2 sẵn sàng"**; it stays unbuilt (36 §B.4, R-170).
14. **Gradient angle** of the Lumi Kết changed from 156.24° to 159.71° (a centred layout); take the new angle.
15. **"Thử hỏi Lumi" is not on the Lumi page** (home only, `788:8801` / `793:8796`). If design wants the Lumi page to share the home's Q&A card style, the two sections should become one component; they are drawn differently today (home answers with pictures, Lumi page with spark tags).
