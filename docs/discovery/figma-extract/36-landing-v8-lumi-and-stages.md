# 36 — Landing V8: Lumi page and the future-stage page template

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only; no node modified). Extracted 2026-10-19 from section **`734:5373` "Child Life Website — V8"**. Conventions as in `33-landing-lumi-page.md` / `15-landing-v3-stages.md`: token names from `packages/design-tokens/dist/tokens.css`, non-token values marked **(raw)**, every string copied **verbatim from `get_design_context`** (layer names are cut at 30 characters; never copy them).

- **Part A** — frame **`737:67153` "V8 · Lumi · Desktop"** (1440 × 7781.2). Documented as a **diff against what is built** (`pages/LumiPage.tsx`, `sections/LumiDetail.tsx`, `sections/ForBaby.tsx` `ForBabyDetail`, `sections/Lumi.tsx` `LumiJourney`, content `lumiPage` / `forBaby.detail` / `lumiJourney` in `content/{vi,en}.ts`, spec 33). Anything not listed is unchanged and stays as built.
- **Part B** — frame **`738:7309` "V8 · Chặng 2 (đang phát triển) · Desktop"** (1440 × 2106.2), the new template for stage pages 2–4. Documented in full.
- Siblings in the same section: `735:5377` V8 Trang chủ Desktop, `736:65570` V8 Trang chủ Mobile, `737:6362` V8 Năm đầu đời Desktop (specs written in parallel), component set **`734:5426` "V8/CTA tải app"** (§B.0), and two yellow note frames **`739:7389` "Thay đổi chính so với V1"** and **`739:7403` "Thông tin sản phẩm cần xác nhận"** (quoted where relevant). **There is no mobile frame and no English frame for either page** (only the home has a mobile frame).
- No prototype links, hover/focus states or motion. Light only.

Screenshots (not committed; `scratchpad/v8/`): `lumi-full-thumb.png` (297 × 1600), `lumi-motngay.png` (Một ngày cùng Lumi, 900 wide), `stage2-full.png` (821 × 1200).

Method: `get_metadata` outline (`scratchpad/v8/meta.xml`); `get_design_context` on every Lumi section (`737:67154`, `…173`, `…266`, `…292`, `…319`, `…458`, `…645`, `…677`, `…949`, `…980`), every Chặng 2 section (`738:7310`, `…329`, `…334`, `…385`, `…428`, `…445`, `…473`), the component `734:5426` and both note frames; icon SVGs downloaded to read stroke colours; the Chặng 2 hero vector downloaded and compared with `assets/figma/stage-art-2.svg`.

---

## The ten things the implementer must know

1. **Lumi page: two sections are gone** — "Còn nhiều việc" (`lumiPage.more`, `#viec-khac`) and "Lumi suốt hành trình" (`LumiJourney`, `#suot-hanh-trinh`). Confirmed: no node in `737:67153` carries their strings. Note `739:7389` #11: "bỏ phần lặp và roadmap theo chặng".
2. **Lumi page: a new "Điều hướng nhanh" chip bar** after Lợi ích ("Trên trang này:" + 5 anchor chips) (§A.4).
3. **Hero copy changed:** H1 "Nhắn một câu." / "Lumi soạn sẵn bản ghi."; primary "Mở Lumi trong app"; secondary "Xem các gói" (§A.2).
4. **Gói head changed** to "Bắt đầu miễn phí. Thêm lượt khi nhà bạn cần." / "Các gói có cùng tính năng. Khác nhau ở lượt hỗ trợ Lumi và số video kỷ niệm mỗi tháng."; eyebrow "Xem các gói". **Prices, credits, video counts, plan names and the price note are unchanged** (79.000đ / 179.000đ). **No USD price is drawn**; "$3.99 / $8.99" appears only in note `739:7403` as "giá gợi ý". **The comparison-table row "Giá mỗi tháng" is now visible** (it was hidden in 650:4798 and is not built today) (§A.8).
5. **Pricing is still unapproved** (Q-071 open, D-074 store payments later). And the credit rule "Một câu ghi nhật ký hoặc một câu hỏi — 1 lượt" is now **out of date**: the owner decided on 2026-10-19 (D-088, `lumi-plan.md` §8) that rule-read logs and read cards cost **0** (§C.1).
6. **Cách Lumi làm việc:** the third trust line becomes "Lumi không thay bác sĩ và không chẩn đoán. Khi lo lắng về sức khoẻ, Lumi chỉ tới hướng dẫn an toàn và số khẩn cấp" (§A.7).
7. **Kết (Lumi):** the white pill now reads "Mở Lumi trong app". This Kết does **not** use `V8/CTA tải app`; the stage page's Kết does (§A.10, §B.6).
8. **Stage pages 2–4 get a new template:** a top status band, a hero with an "Đang phát triển" chip and two CTAs, "Ba trải nghiệm" cards (the **Lumi roadmap items** from `lumiJourney.stages[i].items`, now shown as stage directions), a "Chặng khác" pair of links, and a dark Kết card with `V8/CTA tải app`. The switcher, highlights and quote band are gone. The hero art is **exactly `assets/figma/stage-art-2.svg`** (§B).
9. **"Nhận tin khi chặng 2 sẵn sàng"** is drawn as a plain secondary outline pill with no email field and no target. Note `739:7403` says: do not use it unless a real email sign-up flow exists. None exists (R-170: "No forms, no login"). **Do not ship it.** Render the primary CTA only (§B.3).
10. **`V8/CTA tải app` forbids "coming soon" taps.** Its description says: “Không dùng nút “Tải ngay” rồi báo “sắp có”.” But `StoreBadges` today shows `stores.comingSoon` while `storeLinks` are `null`. This is an owner decision before launch (§B.0, §C.3).

---

# PART A — V8 · Lumi · Desktop (`737:67153`)

## A.0 Section order (old → new)

| # | V8 section | Node | y · h | Background | Padding (t r b l) | Today (`LumiPage.tsx`) | Change |
|---|---|---|---|---|---|---|---|
| 1 | Nav | 737:67154 | 0 · 81 | `cloud` | 20 96 | `Chrome` nav | **changed** (§A.1) |
| 2 | Hero | 737:67173 | 81 · 889 | page | 72 96 96 | `LumiHero` `#gioi-thieu` | copy (§A.2) |
| 3 | Lợi ích | 737:67266 | 970 · 495 | `surface` | **4** 96 96 | `LumiBenefits` `#loi-ich` | none |
| 4 | **Điều hướng nhanh** | 737:67292 | 1465 · 62 | `surface` | 14 96 | — | **NEW** (§A.4) |
| 5 | Một ngày cùng Lumi | 737:67319 | 1527 · 982 | page | **0** 96 96 | `LumiDay` `#mot-ngay` | top padding (§A.5) |
| 6 | Một ngày dành riêng cho con | 737:67458 | 2509 · 1356 | #FFF9F2 (raw) | 104 96 | `ForBabyDetail` `#mot-ngay-cho-con` | none (§A.6) |
| — | ~~Còn nhiều việc~~ | — | — | — | — | `LumiMore` `#viec-khac` | **REMOVED** |
| — | ~~Lumi suốt hành trình~~ | — | — | — | — | `LumiJourney` `#suot-hanh-trinh` | **REMOVED** |
| 7 | Cách Lumi làm việc | 737:67645 | 3865 · 647 | page (dark card) | 0 96 96 | `LumiHow` `#cach-lam-viec` | 1 string (§A.7) |
| 8 | Gói | 737:67677 | 4512 · 2047 | Gói gradient | **0** 96 **112** | `LumiPlans` `#goi` | head copy + price row (§A.8) |
| 9 | Hỏi đáp | 737:67949 | 6559 · 623 | page | 96 | `LumiFaq` `#hoi-dap` | none (§A.9) |
| 10 | Kết | 737:67980 | 7182 · 415 | page (gradient card) | 0 96 **3** | `LumiCta` `#tai-app` | 1 label (§A.10) |
| 11 | Footer | 737:67992 | 7597 · 184 | page | 32 96 40 | `Chrome` footer | none |

New `LumiPage` order: `LumiHero`, `LumiBenefits`, **`LumiQuickNav`**, `LumiDay`, `ForBabyDetail`, `LumiHow`, `LumiPlans`, `LumiFaq`, `LumiCta`. Remove `LumiMore` and the `#suot-hanh-trinh` wrapper from the page.

Note `739:7389` #11 (verbatim): “11. Trang Lumi: Giá trị → Ví dụ → Gợi ý dành cho bé → Cách hoạt động & quyền kiểm soát → Gói → Hỏi đáp; bỏ phần lặp và roadmap theo chặng; gói nói rõ khác nhau ở lượt Lumi và số video.”

**Cleanup:** after this change `lumiPage.more` (vi/en/types) and the `LumiMore` component are unused on every page, so delete them. **Keep `lumiJourney.stages[i].sub` / `.items`**, because Part B reads them (§B.7). Whether `LumiJourney` itself still renders on the home is decided in the V8 home spec. Note #5 says “bỏ roadmap Lumi theo chặng khỏi home”. If neither page renders it, move the stage data into `journey.stages[i]` as proposed in §B.7 and delete `lumiJourney`.

## A.1 Nav (737:67154) — shared with every V8 page

`background: cloud; padding: 20px 96px; gap: 32px` (v6: `22px 96px`). Lockup 175.9 × 34, flex spacer, then the links **Medium 15 `ink`, nowrap**, in this order (verbatim): **"Chăm sóc" · "Kỷ niệm" · "Lumi" · "Năm đầu đời" · "Hỏi đáp"**. The links are spaced by the row gap of 32 (v6: 36, plus a 40 spacer). After them comes the CTA pill: `mint-deep` (v6: `ink`), `padding: 11px 20px; r 999`, SemiBold 15 `on-mint-deep`, **"Bắt đầu"** (v6: "Tải miễn phí").

- Old → new (`nav.links`, `nav.download`): "Hành trình", "Năm đầu đời", "Lumi", "Các chặng", "Kỷ niệm", "Hỏi đáp" → "Chăm sóc", "Kỷ niệm", "Lumi", "Năm đầu đời", "Hỏi đáp"; "Tải miễn phí" → "Bắt đầu". **"Hành trình" and "Các chặng" are dropped; "Chăm sóc" is new.**
- **No current-page style is drawn.** "Lumi" is plain Medium `ink` on the Lumi page. In v6 it was Bold `mint-text`. Keep `aria-current="page"` for accessibility. The visual style follows the V8 home spec.
- The nav is the same on every V8 frame. Implement it once, from the V8 home spec, which owns the targets for "Chăm sóc" / "Kỷ niệm" / "Năm đầu đời". **Lumi-page targets:** "Lumi" → current page; **"Hỏi đáp" → local `#hoi-dap`**; **"Bắt đầu" → local `#tai-app`** (Kết).

## A.2 Hero (737:67173) — copy changes only

Layout, mock-up, chips and every mock string are identical to 33 §2 (verified node by node).

| Key path | Old (built) | New (V8, verbatim) |
|---|---|---|
| `lumiPage.hero.title` | ["Kể một câu.", "Lumi ghi giúp, nhớ giúp."] | **["Nhắn một câu.", "Lumi soạn sẵn bản ghi."]** (two hard lines, Bold 52 / 1.1 `ink`) |
| `lumiPage.hero.tryNow` | "Dùng thử Lumi" | **"Mở Lumi trong app"** (primary `mint-deep`, `padding: 16px 28px`, SemiBold 17 `on-mint-deep`, 214 × 54) |
| `lumiPage.hero.plans` | "Nâng cấp gói" | **"Xem các gói"** (outline + chevron-down 16 `ink`, 183 × 56) |

Unchanged (verbatim): eyebrow "Lumi · Trợ lý đồng hành trong Child Life"; lead "Lumi là trợ lý của cả nhà trong Child Life. Gõ như đang nhắn tin, chụp một tấm ảnh hay hỏi một câu — Lumi soạn sẵn bản ghi, trả lời từ chính nhật ký của con và gợi ý một việc nhỏ cho hôm nay."; the three chips; every mock string. The mock still draws **"Bỉm · 289.000đ"**. The built content uses "Bỉm · 289.000 ₫", an earlier engineering choice (33 §16 row 12); keep it.

Links (unchanged): "Mở Lumi trong app" → `#tai-app` (the web cannot open the app's Lumi; see §C.3); "Xem các gói" → `#goi`.

Optional: `lumiPage.meta.description` starts "Kể một câu, Lumi soạn sẵn…". It may stay; it is SEO text and is not drawn.

## A.3 Lợi ích (737:67266) — unchanged

Verified identical: strings, icons, tints and the **4 px top padding** (33 §0.1 bug, built with the fix). Keep as built.

## A.4 Điều hướng nhanh (737:67292) — NEW

A full-width white strip directly under Lợi ích. Both are `surface`, so they read as one white band.

- Section: `background: surface; display: flex; align-items: center; gap: 10px; padding: 14px 96px;` (1440 × 62). Content is left-aligned on the 1248 grid. It does not wrap at 1440 (≈ 800 px of chips).
- Label: SemiBold 14 `ink-muted` nowrap **"Trên trang này:"**
- 5 chips, `display: flex; align-items: center; gap: 6px; padding: 8px 14px; border-radius: 999px`, icon 14 + SemiBold 14 nowrap:

| # | Label (verbatim) | Icon | State drawn | Fill / text / icon stroke | Target (proposal) |
|---|---|---|---|---|---|
| 1 | **"Ví dụ"** | `feed` | **selected** | `mint-deep` / `on-mint-deep` / white | `#mot-ngay` (Một ngày cùng Lumi) |
| 2 | **"Gợi ý dành cho bé"** | `today` | default | `cloud` / `ink` / `ink` | `#mot-ngay-cho-con` |
| 3 | **"Cách hoạt động"** | `check` | default | `cloud` / `ink` / `ink` | `#cach-lam-viec` |
| 4 | **"Các gói"** | `grid` (4 rounded squares, `ink`) | default | `cloud` / `ink` / `ink` | `#goi` |
| 5 | **"Hỏi đáp"** | `journal` | default | `cloud` / `ink` / `ink` | `#hoi-dap` |

All five icons are already in the landing `Icon` map (`components/primitives.tsx`).

Implementation (proposal; Figma defines no behaviour):
- `<nav class="lp-quicknav" aria-label="Trên trang này">` with the label as a visible `<span>` (not a heading) and a `<ul>` of `<a href="#…">` chips. Reuse the existing section ids; none changes.
- The **selected** style means "the section in view". Scroll-spy with `IntersectionObserver` sets `aria-current="true"` and `.is-current` on the chip of the section whose top has passed ~40 % of the viewport. The prerendered HTML has no chip selected; no-JS readers simply get links. If scroll-spy is unwanted, render all five as default chips. Do **not** hard-code chip 1 as selected.
- Not sticky. Figma does not say; sticking under the nav would cover anchor targets and would need `scroll-margin-top`. Ask design if they want it sticky.
- Smooth scroll follows the site's existing anchor behaviour (respect `prefers-reduced-motion`).
- Mobile (no frame; proposal): one horizontal scroll row (`overflow-x: auto; scrollbar-width: none; padding: 12px 20px`), with the label on its own line above the chips, or hidden with the `aria-label` kept.

Content: `lumiPage.quickNav = { label: 'Trên trang này:', items: [{ label, href }] }` (labels are new strings; §D).

## A.5 Một ngày cùng Lumi (737:67319) — unchanged content, top padding

Every string, mock, tint and size is identical to 33 §4 (verified).
**Spacing bug, new in V8:** the section still has **0 px top padding**. It now follows the 62-px quick-nav band (14 px bottom padding), not Lợi ích's 96, so its eyebrow touches the white band (`lumi-motngay.png`). Implement **72–96 px top padding** on `#mot-ngay`. Recommend 88, matching Part B's 88-px section rhythm, or ask design.

## A.6 Một ngày dành riêng cho con (737:67458) — unchanged

Verified identical to the built `ForBabyDetail` (spec 700:5832): `#FFF9F2` band, `padding: 104px 96px`, `gap: 44px`. Eyebrow `peach-soft` / `ink` "Một ngày dành riêng cho con"; H2 Bold 42 / 1.16 ["Không cần nghĩ ra câu hỏi.", "Điều đáng chú ý đã chờ sẵn."]. Two modes (Lumi / "Hôm nay của bé"), modes note, the three scenario cards (1 "Ba mẹ đã ghi" → 2 "Hôm nay ba mẹ thấy" → 3 "Bạn quyết định"), "Bạn luôn kiểm soát:" chips and the note "Ví dụ minh hoạ. Gợi ý món ăn, hoạt động lấy từ thư viện nội dung đang chờ chuyên môn duyệt; chỉ giới thiệu như tính năng có sẵn khi đã triển khai." No change. It is the target of quick-nav chip 2.

## A.7 Cách Lumi làm việc (737:67645) — one string

| Key path | Old (built) | New (V8, verbatim) |
|---|---|---|
| `lumiPage.how.trust[2]` | "Lumi không thay bác sĩ. Khi lo lắng về sức khoẻ, Lumi chỉ đường đến hướng dẫn an toàn và số khẩn cấp" | **"Lumi không thay bác sĩ và không chẩn đoán. Khi lo lắng về sức khoẻ, Lumi chỉ tới hướng dẫn an toàn và số khẩn cấp"** |

Everything else is identical: dark card #163D44, steps 1–3, trust lines 1–2 and the alert / lock / eye icons in #FCD66B. The overflow bug from 33 §7 is still present (steps row 1126 and trust row 1190 in a 1120 inner width) and is already fixed in the build with a 3-column grid. The new line is longer and wraps to 3 lines at 378 px, the same as before.

## A.8 Gói (737:67677) — head copy, price row; prices unchanged

Section: same gradient `linear-gradient(117.82deg, #F5FCFA 14.286%, #F2F2FF 85.714%)` (raw), `gap: 44px`, **`padding: 0 96px 112px`** (top 0 is the 33 §0.1 bug, built with 96).

### A.8.1 Head — changed

| Key path | Old (built) | New (V8, verbatim) |
|---|---|---|
| `lumiPage.plans.eyebrow` | "Nâng cấp gói" | **"Xem các gói"** (`mint-soft` / `mint-text`) |
| `lumiPage.plans.title` | "Mọi việc Lumi làm, nhà nào cũng dùng được." | **"Bắt đầu miễn phí. Thêm lượt khi nhà bạn cần."** (Bold 44 / 1.18 `ink`, centred, 800 wide → 2 lines) |
| `lumiPage.plans.lead` | "Ba gói chỉ khác nhau ở số lượt hỗ trợ mỗi tháng. Chọn mức hợp với nhịp nhà bạn — đổi gói bất cứ lúc nào." | **"Các gói có cùng tính năng. Khác nhau ở lượt hỗ trợ Lumi và số video kỷ niệm mỗi tháng."** (Medium 18 / 1.55 `ink-muted`, centred, 680 wide) |

The new lead **drops "đổi gói bất cứ lúc nào"** (a plan-switch promise D-074 cannot keep yet), which is good. It now names video counts as a difference, which matches the cards.

### A.8.2 Kỳ hạn toggle — unchanged
"Theo tháng" (selected, `mint-deep` / `on-mint-deep`) · "Theo năm" (transparent / `ink`); `surface` track, `padding: 4px; gap: 4px`. Only the monthly state is drawn. Keep the built radio-group behaviour (33 §8.2).

### A.8.3 Ba gói — unchanged (verified every string)

| | Free 737:67689 | Plus 737:67720 | Pro 737:67753 |
|---|---|---|---|
| Name / tagline | "Free" / "Để bắt đầu" | "Plus" / "Cho ngày nhiều việc" | "Pro" / "Cho cả nhà dùng nhiều" |
| Credits | "30" "lượt hỗ trợ / tháng" | "300" "lượt hỗ trợ / tháng" | "1.000" "lượt hỗ trợ / tháng" |
| Features | "Tất cả việc Lumi làm được" · "≈ 10 ảnh hoá đơn, giấy dặn" · "1 video kỷ niệm / tháng" · "Mọi mẫu thiệp & video" · "Sửa, xác nhận nháp không tính thêm lượt" | same with "≈ 100 …", "5 video kỷ niệm / tháng" | same with "≈ 330 …", "15 video kỷ niệm / tháng" |
| Price | "0đ" "/ tháng"; "Không cần thẻ thanh toán" | "79.000đ" "/ tháng"; "hoặc 790.000đ/năm · tiết kiệm 2 tháng" | "179.000đ" "/ tháng"; "hoặc 1.790.000đ/năm · tiết kiệm 2 tháng" |
| Button | "Đang dùng" (outline) | "Nâng cấp lên Plus" (`mint-deep`) | "Nâng cấp lên Pro" (#FCD66B) |

- **No USD price anywhere in the frame.** The only mention is note `739:7403` (verbatim): “• Gói Lumi Free/Plus/Pro: số lượt, số video, giá (79.000đ / 179.000đ, $3.99 / $8.99 là giá gợi ý), lượt có dùng chung cả nhà không, gia hạn/hoàn tiền.” These are **suggested** prices awaiting confirmation (Q-071). Do not put $3.99 / $8.99 on the English page (§C.1).
- The Free button is still drawn as **"Đang dùng"**. The build already uses the engineering label **"Bắt đầu miễn phí"** → `#tai-app` (33 §8.3). Keep it. It now echoes the new title "Bắt đầu miễn phí."

### A.8.4 Ghi chú giá — unchanged
alert 14 `ink-muted` + Medium 13 `ink-muted`: "Giá đã gồm VAT, thanh toán qua App Store / Google Play. Gói năm tiết kiệm 2 tháng. Huỷ gia hạn bất cứ lúc nào trong cài đặt cửa hàng."

### A.8.5 Bảng so sánh — **price row now visible**
Table 1188 × **636** (12 rows × 53; v6 was 583 with the price row hidden). Row order:

| Row | Label (verbatim) | Free | Plus | Pro | Row fill | Text |
|---|---|---|---|---|---|---|
| header | *(empty, U+200B)* | "Free" | "Plus" | "Pro" | #F2FAF7 | SemiBold 15 |
| **price — NEW in build** | **"Giá mỗi tháng"** | **"0đ"** | **"79.000đ"** | **"179.000đ"** | #FBFEFC | **Bold 15** (label and values) |
| credits | "Lượt hỗ trợ mỗi tháng" | "30" | "300" | "1.000" | #FBFEFC | label SemiBold, values Medium |
| | "Ghi nhật ký bằng một câu" | ✓ | ✓ | ✓ | white | |
| | "Hỏi đáp từ nhật ký của con" | ✓ | ✓ | ✓ | #FBFEFC | |
| | "Đọc ảnh hoá đơn, giấy dặn (≈3 lượt/ảnh)" | ✓ | ✓ | ✓ | white | |
| | "Nhìn lại mấy ngày & gợi ý cho hôm nay" | ✓ | ✓ | ✓ | #FBFEFC | |
| | "Tóm tắt tuần cho cả nhà" | ✓ | ✓ | ✓ | white | |
| | "Nhịp lớn lên của riêng con" | ✓ | ✓ | ✓ | #FBFEFC | |
| | "Mọi mẫu thiệp & video" | ✓ | ✓ | ✓ | white | |
| | "Xuất video kỷ niệm mỗi tháng" | "1" | "5" | "15" | #FBFEFC | |
| | "Ghi trực tiếp & hướng dẫn an toàn khi hết lượt" | ✓ | ✓ | ✓ | white | |

- Build: add the price row as the first body row, using the existing `lumiPage.plans.table.price` ("Giá mỗi tháng", already in content) and each tier's `price`. Put it in its **own `<tbody class="lp-table__price">`** with the #FBFEFC fill and Bold text, so the existing zebra striping of the following rows does not shift. Figma has two tinted rows in a row (price + credits); that is a side effect of un-hiding the row, kept as drawn.
- In the "Theo năm" state the label says "mỗi tháng", so keep the monthly prices in this row. Do not swap to the yearly price.
- **Gate:** this row publishes prices in a second place. Ship it only together with the price cards, and only after the owner approves prices (§C.1). If the plan section is hidden pre-approval, the row goes with it.

### A.8.6 Lượt hỗ trợ là gì — unchanged in Figma, but now contradicted by D-088
"Lượt hỗ trợ là gì?" / "Mỗi lần Lumi làm việc cho bạn là một lượt. Lượt làm mới đầu mỗi kỳ." Rules: "Một câu ghi nhật ký hoặc một câu hỏi" — "1 lượt"; "Đọc một ảnh hoá đơn, giấy dặn" — "≈ 3 lượt"; "Hỏi lại, sửa hay xác nhận nháp trong cùng việc" — "Không tính"; "Lỗi hệ thống, thử lại" — "Không tính"; "Hết lượt" — "Vẫn ghi trực tiếp, xem nhật ký bình thường". See §C.1 row 6: routine logs and read answers are now 0 lượt.

## A.9 Hỏi đáp (737:67949) — unchanged
Same six questions, first open ("Lumi có tự ghi vào nhật ký không?" — "Không. Lumi soạn nháp, bạn xem lại và bấm lưu. Bạn có thể sửa hoặc bỏ từng bản."). Questions 2–6 still have **no answer in Figma**; the build ships the PROPOSED answers (33 §9). The new Gói lead affects answer 3; see §C.1 row 4.

## A.10 Kết (737:67980) — one label; not the V8 component

Card unchanged: gradient `156.24deg, #2BC4B5 → #545CDB`, r 40, p 56, mascot 56, H2 Bold 40 white "Để Lumi lo phần ghi chép. Bạn dành thời gian cho con.", photo slot 440 × 300 (placeholder 22456 "Sun", built with `scenes.nowBaby`). Bottom padding 3 px (bug, built as 96).

| Element | Old Figma (650:4798) | V8 (verbatim) | Built today |
|---|---|---|---|
| White pill (`surface`, `padding: 14px 22px`, SemiBold 16 `ink`) | "Dùng thử Lumi" | **"Mở Lumi trong app"** | replaced by `StoreBadges` (white) |
| Text button (SemiBold 16 white, `padding: 6px 0`) | "Xem các gói" | "Xem các gói" (unchanged) | `lumiPage.cta.plans` → `#goi` |

**This Kết does not contain `V8/CTA tải app`.** The component is used on the Chặng 2 page (§B.6) and, per note #9, on the home. What it shows is in §B.0.

Recommendation: keep the built `StoreBadges` + "Xem các gói", because `#tai-app` must install the app (the nav "Bắt đầu" and hero primary land here). Render the badges with the component's caption **"Tải miễn phí trên iPhone và Android."** under them (Medium 13, on this gradient use white @ 85 % — raw; the component's #CCE0E0 is tuned for the dark card). The drawn label "Mở Lumi trong app" is right only once a universal link into the app's Lumi exists (none today; §C.3). If the owner wants the pill as drawn: new key `lumiPage.cta.tryNow` = "Mở Lumi trong app", linking to the store listing (`storeLinks`), never to a "sắp có" toast.

Contrast: white on the teal start of the gradient still fails (33 §10). Unchanged; still a design question.

## A.11 Footer — unchanged
Same as v6 / `Chrome` footer ("© 2026 Child Life", "Quyền riêng tư", "Điều khoản", "Liên hệ").

## A.12 Image slots — unchanged
Một ngày card 2 (receipt placeholder), card 6 (Peach → `teddy-newborn-yawn.jpg`), Kết (Sun → `scenes.nowBaby`), as built (33 §12). Removing "Còn nhiều việc" also removes the paper-note slot (33 §12 row 3).

---

# PART B — V8 · Chặng 2 (đang phát triển) · Desktop (`738:7309`) — template for stages 2–4

Note `739:7389` #12 (verbatim): “12. Trang chặng tương lai: dải “Đang phát triển” trên cùng, CTA chính dẫn về năm đầu đời, CTA “Nhận tin” phụ.”

## B.0 Component `V8/CTA tải app` (`734:5426`)

Component set with two properties: **Trạng thái** = "Sau ra mắt" | "Trước ra mắt", and **Bố cục** = "Ngang" | "Dọc". Description (verbatim): “Trước ra mắt: chỉ dùng khi đã có luồng đăng ký email thật. Sau ra mắt: nút App Store / Google Play dẫn thẳng tới trang ứng dụng. Không dùng nút “Tải ngay” rồi báo “sắp có”.”

Root `column; gap: 10px`, then a row `gap: 12px` (Ngang `align-items:center`; Dọc `column`), then a caption Medium 13 `ink-muted` nowrap.

| Variant | Row content | Caption (verbatim) |
|---|---|---|
| **Sau ra mắt · Ngang** (`734:5374`, the one on Chặng 2) | two white store badges, `padding: 11.5px 23px 11.5px 18.4px; gap: 11.5px; r 16.1`: glyph 25.3 + column (Medium 12.65 **"Tải trên"**, SemiBold 21.85 **"App Store"** / **"Google Play"**), text #141417 (raw) | **"Tải miễn phí trên iPhone và Android."** |
| Sau ra mắt · Dọc (`734:5400`) | same badges at 82 % (r 13.2, glyph 20.75, 10.37 / 17.92 text), stacked | same |
| Trước ra mắt · Ngang (`734:5390`) | email field 300 wide (`surface`, 1 px `control-border`, `padding: 15px 18px; r 999`, journal 16 + Medium 15 `ink-muted` placeholder **"Email của bạn"**) + button `mint-deep` `padding: 15px 24px` SemiBold 16 `on-mint-deep` **"Nhận tin ra mắt"** | **"Chỉ dùng email để báo khi app ra mắt. Huỷ bất cứ lúc nào."** |
| Trước ra mắt · Dọc (`734:5416`) | same, 350 wide, both full width | same |

Build: the "Sau ra mắt" variant is the existing `StoreBadges` (badges + caption). Add the caption string `stores.caption` = "Tải miễn phí trên iPhone và Android." (shared with the V8 home spec). **Do not build "Trước ra mắt"** until an email flow is approved: no D/R entry, R-170 "No forms", and it would need consent, storage, unsubscribe and a privacy-policy update.

## B.1 Global

| # | Section | Node | y · h | Background | Padding (t r b l) | Proposed id |
|---|---|---|---|---|---|---|
| 1 | Nav | 738:7310 | 0 · 81 | `cloud` | 20 96 | — |
| 2 | Trạng thái (band) | 738:7329 | 81 · 42 | `sunshine-soft` | 12 96 | — |
| 3 | Hero | 738:7334 | 123 · 512 | **#FFF5E0** (raw, ≈ `sunshine-soft` #FFF4D6) | 56 96 72 | — (`<h1 id="stage-title">`) |
| 4 | Định hướng | 738:7385 | 635 · 577 | `surface` | 88 96 | `#dinh-huong` |
| 5 | Chặng khác | 738:7428 | 1212 · 178 | page (`cloud`) | 48 96 | `<nav>` (no id) |
| 6 | Kết ("9 · Kết") | 738:7445 | 1390 · 532 | `surface` | **24** 96 96 | `#tai-app` |
| 7 | Footer | 738:7473 | 1922 · 184 | page | 32 96 40 | — |

Page root `cloud` (#F6FCFB). Content width 1248. Text: Be Vietnam Pro. Colours from tokens except the raw values marked.

**Removed vs the built Chặng 2–4 template** (`StagePage.tsx`, spec 15): `StageSwitcher` ("Hành trình ›" + 4 pills), the `StageHero` panel with circles and number, `StageHighlights` ("Ở chặng này, Child Life cùng ba mẹ" + 3 cards + quote band with photo), `StagePrevNext` (as drawn), `Cta compact`. All are replaced by the sections below.

## B.2 Nav (738:7310)
Identical to §A.1 (same strings, "Bắt đầu" pill). No current-page highlight; no link points at a stage page. Targets on a stage page: **"Bắt đầu" → `#tai-app`**. **"Hỏi đáp"** has no local FAQ here → home `#hoi-dap`. Other links per the V8 home spec.

## B.3 Trạng thái band (738:7329)

`background: sunshine-soft; display:flex; justify-content:center; align-items:center; gap: 10px; padding: 12px 96px;` (42 tall, full bleed)
- clock 16, stroke `ink`
- SemiBold 14 `ink`, nowrap at 1440 (697 px): **"Đang phát triển — chặng này chưa có trong app. Hiện Child Life dành cho năm đầu đời (0–12 tháng)."**

Not dismissible. Markup: a `<p>` inside a `<div role="note">` right after the nav (not `role="alert"`; it is static). Mobile: wrap to 2–3 lines, `padding: 10px 20px`, centred text, icon top-aligned.

## B.4 Hero (738:7334)

`background: #FFF5E0 (raw); display:flex; gap: 56px; align-items:center; padding: 56px 96px 72px;`

**Copy** 600 wide, `column; gap: 18px`:
1. Chip row `gap: 8px`:
   - status chip `surface-2`, `padding: 5px 10px; gap: 6px; r 999`, clock 12 (`ink`) + SemiBold 12 `ink` **"Đang phát triển"**
   - stage chip `surface`, `padding: 5px 10px; r 999`, SemiBold 12 `ink` **"Chặng 2 · 1–3 tuổi"**
2. H1 Bold **56 / 1.1** `ink`: **"Con tập khám phá."**
3. Lead Medium 18 / 1.55 `ink-muted` (2 lines): **"Bớt nghĩ chơi gì, thêm những điều cùng con thử. Đây là định hướng cho chặng 1–3 tuổi; phạm vi và thời điểm ra mắt sẽ được cập nhật."**
4. CTA row `gap: 12px; align-items:center`:
   - **Primary** `mint-deep`, `padding: 15px 24px; r 999`, SemiBold 16 `on-mint-deep` nowrap **"Dùng Child Life cho năm đầu đời"** (305 × 50) → the first-year page `pathOf('stage1', locale)` (the V8 "Năm đầu đời" page `737:6362` replaces it; follow that spec's route).
   - **Secondary — exactly as drawn:** `surface` + 1 px `control-border`, `padding: 15px 22px; r 999`, SemiBold 16 `ink` nowrap **"Nhận tin khi chặng 2 sẵn sàng"** (282 × 52). **No icon, no email field, no helper text, no prototype link.** The frame does not say what it does. Note `739:7403` (verbatim): “• Luồng đăng ký nhận tin (email) có thật không — nếu không, không dùng variant “Trước ra mắt” và nút “Nhận tin khi chặng 2 sẵn sàng”.” **No such flow exists → do not render it.** Keep the key in content (commented as not shipped) so it can be switched on with a real flow. Do not wire it to `mailto:` or a toast.

**Minh hoạ** 592 × 384, `border-radius: 36px; overflow: hidden` (vector, `aria-hidden`): a toddler with stacking blocks, a ball, sparkles, sun circle on #FFF2D6. **It is the same artwork as `apps/landing/src/assets/figma/stage-art-2.svg`** (Figma 684:537; identical fill palette and the same 1.538 aspect, 400 × 260 → 592 × 384.8). **Reuse that file**: `<img src={art2} alt="" width=592 height=385>` with `object-fit: cover` in the rounded box. The art carries its own #FFF2D6 background, so on #FFF5E0 the panel reads as a slightly darker card (as drawn).

## B.5 Định hướng (738:7385)

`background: surface; column; gap: 36px; padding: 88px 96px;`

**Head** `column; gap: 12px`:
- eyebrow `mint-soft` / `mint-text`, `padding: 6px 12px; r 999`, SemiBold 13: **"Những điều đang được chuẩn bị"**
- H2 Bold **42 / 1.16** `ink`, 820 wide: **"Ba trải nghiệm cho tuổi chập chững."**

**Ba hướng** row `gap: 24px`, 3 cards **400** wide, `align-self: stretch` (224 tall):
`background: cloud; border: 1px dashed #D9D9E0 (raw); border-radius: 28px; padding: 28px 26px; column; gap: 14px;`
- head row `gap: 8px; align-items:center; width:100%`: icon box `padding: 8px; r 12` + icon 20 (stroke `ink`); flex spacer; chip `surface`, `padding: 3px 8px; r 999`, SemiBold 11 `ink-muted` **"Định hướng"**
- title Bold 22 / 1.25 `ink`
- body Medium 15 / 1.55 `ink-muted`

| # | Box tint / icon | Title (verbatim) | Body (verbatim) |
|---|---|---|---|
| 1 | `sunshine-soft` / `star` | **"Hôm nay chơi gì cùng con?"** | **"Gợi ý hoạt động ngắn theo tuổi, sở thích đã ghi và những vật dụng có sẵn."** |
| 2 | `peach-soft` / `journal` | **"Từng lời đầu tiên, không bị quên."** (2 lines) | **"Gom những câu nói ngộ nghĩnh, tiếng cười và bước tiến nhỏ thành nhật ký của con."** |
| 3 | `mint-soft` / `clock` | **"Cùng xây những thói quen nhỏ."** | **"Chuẩn bị những bước đơn giản cho giờ ngủ, đánh răng hay thu dọn đồ chơi, theo cách gia đình lựa chọn."** |

These are exactly `lumiJourney.stages[1].items[0..2]` (`title` / `body`), and the chip is `lumiJourney.planned` ("Định hướng"). Markup: `<ul>` of `<li>` with `<h3>`.

**Lưu ý** row `gap: 8px; align-items:center`: alert 14 (`ink-muted`) + Medium 13 `ink-muted` nowrap: **"Các trải nghiệm trên là định hướng đang được phát triển, chưa có trong ứng dụng."**

## B.6 Chặng khác (738:7428)

`display:flex; gap: 24px; padding: 48px 96px;` (page background). Two link cards, `flex: 1` (612 each):
`background: surface; border-radius: 24px; padding: 20px 24px; display:flex; gap: 14px; align-items:center;`
- icon 18 (stroke `ink`)
- column `flex: 1; gap: 2px`: Medium 12 `ink-muted` stage line + Bold 18 `ink` stage name
- status chip `padding: 3px 9px; r 999`, SemiBold 11

| Card | Border | Icon | Line 1 | Line 2 | Chip (fill / text) | Target |
|---|---|---|---|---|---|---|
| left (738:7429) | **1 px `mint`** | `back` | **"Chặng 1 · 0–12 tháng"** | **"Những ngày đầu đời"** | `mint-deep` / `on-mint-deep` **"Đang có trong app"** | first-year page (`pathOf('stage1')`) |
| right (738:7437) | 1 px `separator` | `arrow-right` | **"Chặng 3 · 3–6 tuổi"** | **"Tò mò và lớn khôn"** | `surface-2` / `ink-muted` **"Đang phát triển"** | `pathOf('stage3')` |

Markup: `<nav aria-label={journey.prevNextLabel}>` with two `<a>` (`rel="prev"` / `rel="next"`), the whole card clickable. The mint border marks the **available** stage, not the direction. See §B.8 for stages 3–4.

## B.7 Kết (738:7445)

Section `background: surface; padding: 24px 96px 96px;`. Card 1248: `background: #163D44 (raw ≈ ink, as in 33 §7); border-radius: 40px; padding: 56px; display:flex; gap: 48px; align-items:center;`
- Copy 620 wide, `column; gap: 16px`:
  - H2 Bold 40 / 1.18 **white** (2 lines at 620): **"Bắt đầu từ năm đầu đời của con."**
  - Medium 17 / 1.55 **#CCE0E0** (raw): **"Ghi chép, nhắc nhở và kỷ niệm — cả nhà cùng một nơi."**
  - **`V8/CTA tải app`** instance (738:7450), variant **Sau ra mắt · Ngang** (§B.0): two white badges "Tải trên" / "App Store", "Tải trên" / "Google Play"; caption **"Tải miễn phí trên iPhone và Android."**, overridden to **#CCE0E0** on the dark card.
- Photo 420 × 300, `border-radius: 28px; background: surface-2; overflow: hidden`; library placeholder **22456 "Sun"** (teddy bear in a basket) at 420² top −60. **Use `scenes.nowBaby`** (`teddy-one-couch.jpg`, 720 × 480). It is the same placeholder → same photo as the Lumi Kết, and a first-year baby fits "Bắt đầu từ năm đầu đời". Alternative: `scenes.parentNewborn`. `alt=""`, lazy.

Implementation: a new `Cta` variant (`variant="dark"`) or a `StageCta` section; ids `#tai-app` / `cta-title`. The existing `Cta` (title pair + `cta.sub` + badges + `cta.caption`) differs in layout, palette and copy.

## B.8 Footer (738:7473)
Identical to the Lumi footer / `Chrome` footer.

## B.9 Generalising to stages 3 and 4

### B.9.1 Template slot → content key

| Slot | Stage 2 (verbatim) | Source today | Status / proposed key |
|---|---|---|---|
| Band text | "Đang phát triển — chặng này chưa có trong app. Hiện Child Life dành cho năm đầu đời (0–12 tháng)." | — | **NEW, shared:** `journey.devBand`. Stage-independent; "0–12 tháng" = `journey.stages[0].ages` (interpolate `{ages}` or keep literal) |
| Status chip | "Đang phát triển" | — | **NEW, shared:** `journey.statusDev` (the V8 home uses the same label, note #7) |
| Stage chip | "Chặng 2 · 1–3 tuổi" | `journey.number` ("Chặng {n}") + " · " + `journey.stages[i].ages` | existing |
| H1 | "Con tập khám phá." | `journey.stages[1].title` | existing |
| Lead, part 1 | "Bớt nghĩ chơi gì, thêm những điều cùng con thử." | `lumiJourney.stages[1].sub` | existing (propose moving to `journey.stages[i].sub`) |
| Lead, part 2 | "Đây là định hướng cho chặng 1–3 tuổi; phạm vi và thời điểm ra mắt sẽ được cập nhật." | — | **NEW, shared template:** `journey.devLead` = "Đây là định hướng cho chặng {ages}; phạm vi và thời điểm ra mắt sẽ được cập nhật." |
| Primary CTA | "Dùng Child Life cho năm đầu đời" | — | **NEW, shared:** `journey.useFirstYear` |
| Secondary CTA (not shipped) | "Nhận tin khi chặng 2 sẵn sàng" | — | **NEW, shared template, hidden:** `journey.notifyWhenReady` = "Nhận tin khi chặng {n} sẵn sàng" |
| Hero art | `stage-art-2.svg` | `sections/NextStages.tsx` imports `stage-art-2/3/4.svg` | existing assets |
| Hero band colour | #FFF5E0 (raw) | — | per stage, §B.9.3 |
| Eyebrow | "Những điều đang được chuẩn bị" | — | **NEW, shared:** `journey.directionsEyebrow` |
| H2 | "Ba trải nghiệm cho tuổi chập chững." | — | **NEW, per stage:** `journey.stages[i].directionsTitle` |
| Card chip | "Định hướng" | `lumiJourney.planned` | existing |
| Cards ×3 | §B.5 table | `lumiJourney.stages[i].items` | existing (propose moving to `journey.stages[i].directions`) |
| Card icons / tints | star·sunshine, journal·peach, clock·mint | `stageArt` in `sections/Stage.tsx` | per stage, §B.9.3 |
| Note | "Các trải nghiệm trên là định hướng đang được phát triển, chưa có trong ứng dụng." | — | **NEW, shared:** `journey.directionsNote` |
| Link card line 1 | "Chặng 1 · 0–12 tháng" | `journey.number` + `journey.stages[n].ages` | existing |
| Link card line 2 | "Những ngày đầu đời" / "Tò mò và lớn khôn" | `journey.stages[n].name` | existing |
| Link chip (available) | "Đang có trong app" | — | **NEW, shared:** `journey.statusAvailable` (shared with the V8 home) |
| Link nav label | — | `journey.prevNextLabel` ("Các chặng") | existing |
| Kết H2 | "Bắt đầu từ năm đầu đời của con." | — | **NEW, shared:** `journey.cta.title` |
| Kết sub | "Ghi chép, nhắc nhở và kỷ niệm — cả nhà cùng một nơi." | — | **NEW, shared:** `journey.cta.sub` |
| Kết caption | "Tải miễn phí trên iPhone và Android." | — | **NEW, shared:** `stores.caption` (§B.0) |
| Kết photo | Sun placeholder | `scenes.nowBaby` | existing |

Content no longer used by stages 2–4 after the switch: `journey.stages[i].lead`, `.chips`, `.highlights`, `.quote`, `journey.highlightsTitle`, `journey.prev` / `next` / `backLabel` / `backTitle` (unless used per §B.9.2 stage 4), `journey.ctaTitle`, `stageArt[*].photo` / `tone` / `icon`. Check the V8 home and Năm đầu đời specs before deleting: `lead` / `chips` may still feed the home's Hành trình cards.

### B.9.2 Proposed stage 3 and stage 4 (Vietnamese, reusing existing strings only)

Only the H2 "Ba trải nghiệm cho …" has no existing per-stage source. The proposal below builds it from the existing `ages` value and **needs owner copy review**. Nothing else is new text.

| Slot | Stage 3 | Stage 4 |
|---|---|---|
| Stage chip | "Chặng 3 · 3–6 tuổi" | "Chặng 4 · 6–12 tuổi" |
| H1 | "Tò mò và lớn khôn." (`journey.stages[2].title`) | "Thế giới riêng của con." (`journey.stages[3].title`) |
| Lead | "Thêm ý tưởng cho những câu hỏi không ngừng. Đây là định hướng cho chặng 3–6 tuổi; phạm vi và thời điểm ra mắt sẽ được cập nhật." | "Đồng hành gần hơn, dành chỗ cho con tự lớn. Đây là định hướng cho chặng 6–12 tuổi; phạm vi và thời điểm ra mắt sẽ được cập nhật." |
| Hidden secondary | "Nhận tin khi chặng 3 sẵn sàng" | "Nhận tin khi chặng 4 sẵn sàng" |
| Art | `stage-art-3.svg` (own bg #FFEBE3) | `stage-art-4.svg` (own bg #EBEBFF) |
| H2 (**NEW — owner copy**) | "Ba trải nghiệm cho chặng 3–6 tuổi." | "Ba trải nghiệm cho chặng 6–12 tuổi." |
| Card 1 | "“Vì sao?” cũng thành giờ chơi." — "Biến điều con tò mò thành câu chuyện, trò chơi hoặc hoạt động để cùng khám phá." | "Ý tưởng của con có nơi bắt đầu." — "Cùng chia một dự án nhỏ thành những bước vừa sức — trồng cây, làm mô hình hay viết truyện." |
| Card 2 | "Một ngày của con, dễ kể lại hơn." — "Từ vài ghi chú của ba mẹ, gợi ý câu hỏi để cùng con trò chuyện về ngày ở lớp." | "Kế hoạch do con cùng lựa chọn." — "Chuẩn bị lịch học, việc nhà và thời gian cho sở thích; ba mẹ và con cùng điều chỉnh." |
| Card 3 | "Bức vẽ nhỏ, câu chuyện lớn." — "Giữ tác phẩm cùng lời con kể, rồi gom thành bộ sưu tập qua từng năm." | "Một năm nhìn bằng mắt con." — "Gom thành quả, câu chuyện và điều con tự hào thành cuốn kỷ niệm có tiếng nói của chính con." |
| Left link | "Chặng 2 · 1–3 tuổi" / "Con tập khám phá" · "Đang phát triển" · `back` · `separator` border → stage 2 | "Chặng 3 · 3–6 tuổi" / "Tò mò và lớn khôn" · "Đang phát triển" · `back` → stage 3 |
| Right link | "Chặng 4 · 6–12 tuổi" / "Thế giới riêng của con" · "Đang phát triển" · `arrow-right` → stage 4 | **no next stage** → proposal: "Chặng 1 · 0–12 tháng" / "Những ngày đầu đời" · "Đang có trong app" · mint border · `arrow-right` → first-year page. Alternative: the existing `journey.backLabel` / `journey.backTitle` ("Quay lại" / "Toàn bộ hành trình") → home `#hanh-trinh` |

Neighbour rule (proposal; design drew only stage 2): left = previous stage, right = next stage. The mint border + "Đang có trong app" follow the **status** (only stage 1 has them), not the position. Design question: should every future-stage page always link stage 1 (the stage that exists) instead of a neighbour? For stage 2 the two coincide.

### B.9.3 Per-stage look (proposal; only stage 2 is drawn)

| | Stage 2 (drawn) | Stage 3 | Stage 4 |
|---|---|---|---|
| Hero band | #FFF5E0 (raw) | #FFF5F1 (raw, a lighter tint of the art's #FFEBE3) | #F5F5FF (raw, a lighter tint of #EBEBFF) |
| Card icons (1, 2, 3) | star, journal, clock | spark, journal, heart (as `stageArt.stage3.highlights`) | star, clock, heart |
| Card tints (1, 2, 3) | sunshine-soft, peach-soft, mint-soft | same order | same order |
| Status band | `sunshine-soft` | same (status colour, not stage colour) | same |

Implementation: drive these from `stageArt` in `sections/Stage.tsx` (add `heroBg`, `art`, `directionIcons`) and `[data-stage]` CSS, as today.

### B.9.4 Routes and SEO
Routes unchanged (`/hanh-trinh/con-tap-kham-pha/` etc.). SEO titles/descriptions per stage: keep the existing ones if any. The page must not be marked up as a product: no `SoftwareApplication` offers for stages 2–4.

### B.9.5 Mobile (no frame; proposal)
Band 2–3 lines; hero stacked (`padding: 24px 20px 40px; gap: 24px`), H1 Bold 36 / 1.12, lead 16, primary CTA full width, art full width at 592:385 aspect with r 24 below the copy; Định hướng `padding: 56px 20px`, H2 Bold 28 / 1.2, cards stacked `gap: 12px`, note wraps; Chặng khác stacked `gap: 12px`, `padding: 32px 20px`; Kết card `margin: 0 10px; padding: 32px 20px; column`, H2 28, badges stacked or wrapped, photo full width 300 × 200 (or hidden).

---

# PART C — Claims to check (`docs/product/business-map.md`)

## C.1 Lumi page

| # | Claim (verbatim) | Map | Status |
|---|---|---|---|
| 1 | Prices "79.000đ" / "179.000đ" "/ tháng", "hoặc 790.000đ/năm · tiết kiệm 2 tháng" / "hoặc 1.790.000đ/năm · tiết kiệm 2 tháng", **now also in the table row "Giá mỗi tháng"**; note `739:7403` "$3.99 / $8.99 là giá gợi ý" | **Q-071 open** (SKUs, price, quotas); P-152 "prices from the storefront only"; one "Premium" plan in the app (33 §16 rows 1, 4) | **Unapproved.** Do not ship prices (cards or table row) until Q-071 is answered and the storefront prices match. No USD on `/en/lumi/` until the owner confirms the USD prices *and* the storefront shows them (D-078 families abroad see local store prices) |
| 2 | Free · Plus · Pro, "30" / "300" / "1.000" lượt, "1" / "5" / "15" video | P-159 Free **20** / calendar month, Premium **200** / paid period; P-152 video free 1, premium 5 / period; no Pro tier | Unchanged conflict (33 §16 rows 1–3, 7) |
| 3 | "Giá đã gồm VAT, thanh toán qua App Store / Google Play … Huỷ gia hạn bất cứ lúc nào trong cài đặt cửa hàng."; buttons "Nâng cấp lên Plus" / "Nâng cấp lên Pro" | **D-074**: real Apple / Google payment later, store gateway "not open yet"; D-072 #1 only the family owner buys | Page sells what the app cannot sell yet; VAT wording needs legal |
| 4 | **NEW** "Các gói có cùng tính năng. Khác nhau ở lượt hỗ trợ Lumi và số video kỷ niệm mỗi tháng."; "Bắt đầu miễn phí. Thêm lượt khi nhà bạn cần."; table all ✓; FAQ "Gói Free có bị thiếu tính năng không?" (PROPOSED answer "Không. Mọi việc Lumi làm đều có trong gói Free; …") | Premium groups A/B (`pmGroupA*`, `pmGroupB*`), **Q-072** (★ Cao cấp templates subscribers-only later), D-075 #1 (beta may give all Premium free) | **Conflict** (33 §16 row 9): "cùng tính năng" contradicts Premium-only personalization and templates. True only during a D-075 #1 beta. Owner must choose: adopt the claim (change entitlements) or reword |
| 5 | Dropped from the lead: "đổi gói bất cứ lúc nào" | D-074 | Improvement ✓ (the PROPOSED FAQ 4 answer "Có. Bạn đổi gói trong ứng dụng…" still promises it; keep under review) |
| 6 | "Một câu ghi nhật ký hoặc một câu hỏi — 1 lượt", "Mỗi lần Lumi làm việc cho bạn là một lượt." | **D-088 / `lumi-plan.md` §8 (owner, 2026-10-19): "rule-read logs, read cards and app actions … cost 0; model calls keep the D-075 pool"**; P-159 (text 1, photo 3, health 0) | **Now inaccurate**: routine logs and recognised questions are free. The rules block (and the "≈3 lượt/ảnh" / "1 lượt" figures it implies for the plan cards) needs new owner copy before publishing. Engineering does not invent it; until then ship the rules as drawn only if the owner accepts the inaccuracy, else hide the "1 lượt" row |
| 7 | Credits shown prominently (cards, table, rules) | **D-081**: credits stay out of the app's main screens, shown only in "Chi tiết" | D-081 governs the app, not the site, but the owner's intent ("Tôi ko muốn show mấy cái credit này…") argues for a lighter credits story on the site too. Ask |
| 8 | **NEW** "Lumi không thay bác sĩ và không chẩn đoán. Khi lo lắng về sức khoẻ, Lumi chỉ tới hướng dẫn an toàn và số khẩn cấp" | CH28 free health path (`lumi-plan.md` §1 "a free health path before any model call"); P-141 emergency number per pack | ✓ ("không chẩn đoán" matches the health path; the emergency number is per region) |
| 9 | Hero "Nhắn một câu. Lumi soạn sẵn bản ghi.", chips "Bạn xác nhận trước khi lưu", FAQ 1 "Không. Lumi soạn nháp, bạn xem lại và bấm lưu." | `lumi-plan.md` §1 "One message becomes reviewed drafts that save in one tap"; D-088 timers "Lưu và bắt đầu đếm" | ✓ (drafts still need a tap). Re-check if D-088 L5 adds any write without a card. The 33 §17 row 4 exceptions (CH27, CH17) still apply |
| 10 | Composer "Kể, hỏi hoặc gửi ảnh cho Lumi…"; note `739:7403` "• Lumi chỉ nhận chữ và ảnh (không giọng nói) — xác nhận." | `lumi-plan.md` §1 lists **"voice dictation"** | Answer for design: the app has voice **dictation** (speech typed as text); the page does not claim voice, so no change. Tell design the note's premise is wrong |
| 11 | Removed sections took their claims with them: "Lumi lớn lên cùng nhà bạn…" (33 §17 row 17, over-claim), the stage 2–4 Lumi roadmap on this page (Q-039), "gửi ông bà theo quyền", "(nội dung minh hoạ · chờ duyệt)" (D-082) | — | ✓ fewer open claims. The table still lists "Tóm tắt tuần cho cả nhà" and "Nhịp lớn lên của riêng con" as ✓ on Free (row 4) |
| 12 | "Một ngày dành riêng cho con" note "…thư viện nội dung đang chờ chuyên môn duyệt…" | **D-082**: no "minh hoạ / chờ duyệt" label in the app; footnote "Biên soạn theo hướng dẫn WHO, AAP, NHS · Tham khảo, không thay thế bác sĩ" | Unchanged from the build; consider aligning the site note with D-082 wording (owner) |
| 13 | Recipes / allergen ("đã bỏ trứng vì từng ghi nổi mẩn", "Cháo bí đỏ yến mạch") | D-083, D-085, **D-086** (Ăn dặm diary + library + personal suggestions now decided) | Closer to true than at 33 §17 row 10; allergen avoidance is still a health claim. Keep the D-058 / D-082 review caveat |

## C.2 Stage page template

| # | Claim (verbatim) | Map | Status |
|---|---|---|---|
| 1 | "Đang phát triển — chặng này chưa có trong app. Hiện Child Life dành cho năm đầu đời (0–12 tháng)." | V1 scope = first year; **Q-039** (stages 2–4 roadmap) | ✓ honest. It fixes the Q-039 complaint that stage pages lacked a roadmap marker; record in Q-039 / R-170 when shipped |
| 2 | Cards "Hôm nay chơi gì cùng con?", "Từng lời đầu tiên, không bị quên.", "Cùng xây những thói quen nhỏ." + "Định hướng" + "…chưa có trong ứng dụng." | **Q-039** (roadmap features, no D/R) | Disclaimed ✓. **These were Lumi roadmap items** (v6 "Lumi theo con suốt hành trình"); here they are unattributed stage experiences. That is acceptable but changes what is promised. Extend Q-039 with the stage 3/4 items reused in §B.9.2 |
| 3 | "Nhận tin khi chặng 2 sẵn sàng"; `V8/CTA tải app` "Trước ra mắt" ("Email của bạn", "Nhận tin ra mắt", "Chỉ dùng email để báo khi app ra mắt. Huỷ bất cứ lúc nào.") | **R-170: "No forms, no login."** No D-entry for email capture; privacy policy and consent (Q-020-type legal) | **Not shippable**: no flow, storage, double opt-in or unsubscribe. Needs an owner decision + a new D-entry before building |
| 4 | "Tải miễn phí trên iPhone và Android." / badges "Tải trên App Store" / "Google Play" | D-004 (Android in scope); `site.ts` `storeLinks` = `null` (not published) | Badges cannot link yet; see §C.3 |
| 5 | "Ghi chép, nhắc nhở và kỷ niệm — cả nhà cùng một nơi." | Care logs (V1 core), reminders (R-090, D-075 #5), Kỷ niệm (D-052), shared family | ✓ |

## C.3 Download / app-link behaviour (both pages)

- `V8/CTA tải app` (verbatim): "Không dùng nút “Tải ngay” rồi báo “sắp có”." Note `739:7403`: “• App đã có trên App Store / Google Play chưa? Frame đang hiển thị trạng thái “Sau ra mắt”; đổi variant nếu chưa phát hành.” The build's `StoreBadges` shows `stores.comingSoon` ("Child Life sắp có mặt trên {store}. Hẹn bạn sớm nhé!") while `storeLinks` are `null`, which is the forbidden pattern. **Owner decision:** (a) ship only after store listings exist (then fill `storeLinks`); or (b) pre-launch, replace the badges with neutral text (e.g. caption only) until (a). (c) "Trước ra mắt" is not an option without an email flow (C.2 #3). This also affects the home (V8 home spec).
- "Mở Lumi trong app" (Lumi hero + Kết): the web has no link into the app's Lumi. D-059 universal / app links exist for invites only (`/i/{token}`). Keep the hero button → `#tai-app`. A real "open in app" needs a new app-link route; that is a G-gap for the owner.

---

# PART D — English drafts (engineering, for owner review; D-012)

| Key (proposed) | vi (verbatim) | en draft |
|---|---|---|
| `nav.links` (V8, shared) | "Chăm sóc" · "Kỷ niệm" · "Lumi" · "Năm đầu đời" · "Hỏi đáp"; "Bắt đầu" | "Care" · "Memories" · "Lumi" · "First year" · "FAQ"; "Get started" (final wording owned by the V8 home spec) |
| `lumiPage.hero.title` | ["Nhắn một câu.", "Lumi soạn sẵn bản ghi."] | ["Send one message.", "Lumi drafts the log."] |
| `lumiPage.hero.tryNow` | "Mở Lumi trong app" | "Open Lumi in the app" |
| `lumiPage.hero.plans` | "Xem các gói" | "See plans" (already the en value) |
| `lumiPage.quickNav.label` | "Trên trang này:" | "On this page:" |
| `lumiPage.quickNav.items` | "Ví dụ" · "Gợi ý dành cho bé" · "Cách hoạt động" · "Các gói" · "Hỏi đáp" | "Examples" · "Ideas for your baby" · "How it works" · "Plans" · "FAQ" |
| `lumiPage.how.trust[2]` | "Lumi không thay bác sĩ và không chẩn đoán. Khi lo lắng về sức khoẻ, Lumi chỉ tới hướng dẫn an toàn và số khẩn cấp" | "Lumi is not a doctor and does not diagnose. When you're worried about health, Lumi points you to safety guidance and the emergency number" |
| `lumiPage.plans.eyebrow` | "Xem các gói" | "Plans" (keep) |
| `lumiPage.plans.title` | "Bắt đầu miễn phí. Thêm lượt khi nhà bạn cần." | "Start free. Add more help when your family needs it." |
| `lumiPage.plans.lead` | "Các gói có cùng tính năng. Khác nhau ở lượt hỗ trợ Lumi và số video kỷ niệm mỗi tháng." | "Every plan has the same features. They differ in Lumi help credits and memory videos each month." |
| `lumiPage.plans.table.price` (now shown) | "Giá mỗi tháng" | "Price per month" (existing en key; values stay VND until the owner approves store prices — §C.1 #1) |
| `lumiPage.cta.tryNow` (only if the pill is built) | "Mở Lumi trong app" | "Open Lumi in the app" |
| `stores.caption` (shared) | "Tải miễn phí trên iPhone và Android." | "Free on iPhone and Android." |
| `journey.devBand` | "Đang phát triển — chặng này chưa có trong app. Hiện Child Life dành cho năm đầu đời (0–12 tháng)." | "In development — this stage isn't in the app yet. Child Life is currently for the first year (0–12 months)." |
| `journey.statusDev` | "Đang phát triển" | "In development" |
| `journey.statusAvailable` | "Đang có trong app" | "Available in the app" |
| `journey.devLead` | "Đây là định hướng cho chặng {ages}; phạm vi và thời điểm ra mắt sẽ được cập nhật." | "This is the direction for the {ages} stage; scope and timing will be updated." |
| `journey.useFirstYear` | "Dùng Child Life cho năm đầu đời" | "Use Child Life for the first year" |
| `journey.notifyWhenReady` (not shipped) | "Nhận tin khi chặng {n} sẵn sàng" | "Tell me when stage {n} is ready" |
| `journey.directionsEyebrow` | "Những điều đang được chuẩn bị" | "What we're preparing" |
| `journey.stages[1].directionsTitle` | "Ba trải nghiệm cho tuổi chập chững." | "Three experiences for the toddler years." |
| `journey.stages[2].directionsTitle` (NEW, owner copy) | "Ba trải nghiệm cho chặng 3–6 tuổi." | "Three experiences for ages 3–6." |
| `journey.stages[3].directionsTitle` (NEW, owner copy) | "Ba trải nghiệm cho chặng 6–12 tuổi." | "Three experiences for ages 6–12." |
| card chip (`lumiJourney.planned`) | "Định hướng" | "In the works" (existing en) |
| cards | `lumiJourney.stages[i].items` | existing en (`lumiJourney.stages[i].items`) |
| lead part 1 | `lumiJourney.stages[i].sub` | existing en ("Less wondering what to play, more things to try together." / "More ideas for endless questions." / "Closer by their side, with room to grow on their own.") |
| `journey.directionsNote` | "Các trải nghiệm trên là định hướng đang được phát triển, chưa có trong ứng dụng." | "The experiences above are directions in development and are not in the app yet." |
| `journey.cta.title` | "Bắt đầu từ năm đầu đời của con." | "Start with your child's first year." |
| `journey.cta.sub` | "Ghi chép, nhắc nhở và kỷ niệm — cả nhà cùng một nơi." | "Logs, reminders and memories — the whole family in one place." |
| V8 CTA pre-launch (not shipped) | "Email của bạn" / "Nhận tin ra mắt" / "Chỉ dùng email để báo khi app ra mắt. Huỷ bất cứ lúc nào." | "Your email" / "Get launch news" / "We only use your email to tell you when the app launches. Unsubscribe any time." |

H1 / stage names / ages in English already exist (`journey.stages[i].title`, `.name`, `.ages`: "Exploring the world.", "Curious and growing.", "A world of their own.", "0–12 months", "1–3 years", …). With `devLead` the English reads "…for the 1–3 years stage…".

---

# PART E — Ambiguities and design bugs

1. **No mobile and no English frame** for either page (only the home has `736:65570`). §A.4 / §B.9.5 are proposals.
2. **Lumi · Một ngày cùng Lumi has 0 top padding** right under the new 62-px quick-nav band (`lumi-motngay.png`); use 72–96 (§A.5). Lợi ích top 4 px, Gói top 0 and Kết bottom 3 px persist from 650:4798 (already corrected in the build).
3. **Quick-nav "selected" chip** ("Ví dụ", `mint-deep`): static highlight or scroll-spy? Sticky or not? Undefined (§A.4).
4. **Comparison table**: the price row is visible again with Bold text and the same tint as the credits row (two tinted rows in a row) (§A.8.5); and it duplicates unapproved prices.
5. **Free button still "Đang dùng"** (meaningless on the web); the build's "Bắt đầu miễn phí" stays (§A.8.3).
6. **Kết (Lumi) pill "Mở Lumi trong app"** has no web target; the build keeps store badges (§A.10, §C.3). White-on-teal contrast still fails (33 §10).
7. **Cách Lumi làm việc** row overflow (1126 / 1190 in 1120) persists (built as a grid).
8. **Expense drafts still use `cloud-off`** (offline icon) for "Bỉm · 289.000đ" (33 §0.5); the build's choice stands.
9. **"Nhận tin khi chặng 2 sẵn sàng"** has no defined behaviour and no flow (§B.4); the component description and note `739:7403` both say not to use it without a real email flow.
10. **Store badges vs "sắp có"**: the component forbids it, the build does it (§C.3).
11. **Stage template drawn for stage 2 only**: H2 per stage, hero band colours, card icons and the stage 4 "next" link are proposals (§B.9.2–B.9.3). It is undecided whether the link pair is neighbours or always "stage 1 + neighbour".
12. **Stage hero art is a vector frame identical to `stage-art-2.svg`** (exported from the v6 card 684:537); no new asset needed. Art bg #FFF2D6 ≠ band #FFF5E0 (intentional card look).
13. **Kết (stage) caption colour** is an instance override (#CCE0E0 on the dark card); the component default is `ink-muted`. Make the colour a prop / context class.
14. **Status band and hero chip both say "Đang phát triển"** (redundant but intended by note #12).
15. **Nav "Hỏi đáp" on a stage page** has no local FAQ; it points to the home FAQ (§B.2). **No nav current state** anywhere in V8 (§A.1).
16. The Lumi FAQ answers 2–6 are still missing in Figma; the build's PROPOSED answers stand, but answer 3 (Free has everything) and answer 4 (switch plans) depend on §C.1 #4 / #5.
17. Note `739:7403` asks "Lumi chỉ nhận chữ và ảnh (không giọng nói)"; the app has voice dictation (`lumi-plan.md` §1). Answer design; no page change needed.
