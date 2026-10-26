# Today Adaptive v2: Version A vs Version B (Step 9A.1)

All images are real Flutter renders in `assets/` (see [README](README.md) to reproduce).

**Evidence levels:**

- **R:** seen in a render listed here.
- **C:** from code.
- **H:** needs verification.

Nothing here is measured with users. Statements about benefit are design judgements, not results.

## 1. Design goals

Improve hierarchy, scanability and density, grouping, composition, type and spacing, CTA clarity,
bilingual copy, loading / empty / error states, Night care and accessibility. Preserve every
Adaptive and customisation behaviour, the Customize entry, roles, navigation and business rules.

**Working decisions** (prototype only, not canonical):

- no global Attention Line;
- "Nhắc việc" (existing key `reminderPeekTitle` / `reminderPeekLabel`);
- the greeting intent kept with an empty-name fallback;
- "Nhịp hôm nay" as the care title;
- A keeps the greeting style, while B explores a lighter one;
- warm overdue styling.

## 2. Version A: Refined current

The current structure (one card per module, header inside the card), corrected:

- **Cards:** `ClRadius.card` (24) and `s4` padding; title `bodyStrong`, link `label`, with no
  literal sizes (they were 20 / 14 / 16 / 13).
- **Reminders:**
  - two-line rows (title, then status · time) with nothing truncated;
  - overdue shown as an alert icon + "Quá hạn …" in the warm `pending` colour on a
    `sunshineSoft` chip;
  - "Nhắc việc", "Xem tất cả" (unchanged: up to 3 rows, `ReminderPeek.shown`).
- **CTAs:** every in-card button demoted from filled primary to **tinted**.
- **Loading:** care tiles show `ClSkeleton` until records arrive.
- **Care section:** "Nhịp hôm nay · Xem lịch sử" for every band; no history link on first run.
- **Tiles:** laid out in content-sized rows (same size at 100 %, they grow at 200 %).
- **Greeting:** unchanged style (`largeTitle` at 26), with the empty-name fallback.

## 3. Version B: Adaptive Briefing

**One outer grammar:** a section heading (+ count, + one link) outside the content, as the care
tiles already do. Inside, each module gets its own pattern:

| Module | Pattern |
|---|---|
| Care | Tiles (unchanged widget) |
| Reminders | `ClCardGroup` of full-width two-line rows with a chevron, whole row tappable |
| Recent memories | A photo strip of tile-lifted thumbnails (`ClTileShadow`) + an "add" tile for parents; the count as a caption |
| Moment today | One large photo + an "Thêm khoảnh khắc" row |
| Create from memories | Two rows (Video kỷ niệm, Thiệp) |
| Growth | One tappable surface: the value (`title2`), "Đo lần cuối …", chevron |
| Family | Avatars row + "Mời người thân" row |
| Spending | A surface with the total and the category bar |
| Empty modules | **One invitation row** (icon + label + chevron) |

**Other differences:**

- no filled buttons anywhere on the page;
- greeting `title2`;
- the same skeleton, warm overdue and tile layout as A.

## 4. Visual comparison (R)

| Scenario | Triptych (Current \| A \| B) |
|---|---|
| 0–1, vi Light | [compare_0-1_light_vi](assets/compare_0-1_light_vi.png) |
| 0–1, vi Night care | [compare_0-1_nightCare_vi](assets/compare_0-1_nightCare_vi.png) |
| 0–1, en Light | [compare_0-1_light_en](assets/compare_0-1_light_en.png) |
| 0–1, en Night care | [compare_0-1_nightCare_en](assets/compare_0-1_nightCare_en.png) |
| 1–3 / 3–6 / 6–12 | [1-3](assets/compare_1-3_light_vi.png) · [3-6](assets/compare_3-6_light_vi.png) · [6-12](assets/compare_6-12_light_vi.png) (+ `_nightCare_en`) |
| Customised | [compare_customized_light_vi](assets/compare_customized_light_vi.png) |
| First run (0–1, 3–6) | [0-1](assets/compare_first-run_light_vi.png) · [3-6](assets/compare_first-run-3-6_light_vi.png) |
| No care logs | [compare_empty-care_light_vi](assets/compare_empty-care_light_vi.png) |
| Loading | [compare_loading_light_vi](assets/compare_loading_light_vi.png) |
| Long name | [compare_long-name_light_vi](assets/compare_long-name_light_vi.png) |
| Offline / pending | [compare_offline_light_vi](assets/compare_offline_light_vi.png) |
| 200 % text | [compare_text-200_light_vi](assets/compare_text-200_light_vi.png) |
| Relative (read-only) | [compare_relative_light_vi](assets/compare_relative_light_vi.png) |

Single images: `version-a_<scenario>_<palette>_<locale>.png`, `version-b_…`.

## 5. UX quality comparison (`cl-design-review` rubric)

**Coverage:**

- 0–1 in all four variants;
- other bands in vi Light + en Night care;
- states in vi Light (loading also in Night care);
- 200 % and long name in vi + en Light.

**Not evaluated:** screen reader, devices, motion, small phones, real photos.

### Critical gates

| Gate | Current | A | B |
|---|---|---|---|
| G1 Business meaning | **At risk:** loading renders four "Chưa có" tiles with "Ghi lần đầu" (R, simulated loading; on-device duration H) | Pass: skeleton (R) | Pass: skeleton (R) |
| G2 Critical action access | **At risk:** at 200 % the tiles overflow and clip their values ("120 ml" cut, R) | Pass for tiles (R); the header baby chip is clipped at 200 % (shared production header, R) | Same as A |
| G3 Data loss | Pass | Pass | Pass |
| G4 Permissions | Pass (relative: tiles + care duty only, R) | Pass (same set, R) | Pass (same set, R) |
| G5 AI / health | Pass (no claims) | Pass | Pass |
| G6 Primary task | Pass at 100 %; at risk at 200 % (G2) | Pass | Pass |

### Scores

0–5; NE = not evaluated.

| # | Dimension | Current | A | B | Note |
|---|---|---|---|---|---|
| 1 | Task clarity | 3 | 3 | 4 | B's headings name each module before its content; A matches current |
| 2 | Hierarchy | 3 | 3 | 4 | B: no filled buttons compete with content (1–3 current has a filled "Thêm khoảnh khắc" above the care tiles). A: tinted buttons still carry visual weight |
| 3 | Scan / density | 2 | 4 | 4 | Both fix the truncated times. B is more compact on 3–6 and first run, a modest gain: in the 3–6 first run B reaches the first reminder row, A only the reminders heading (R) |
| 4 | Interaction clarity | 3 | 3 | 4 | B: whole-row taps with chevrons; empty modules as one row. A: the added "Xem tất cả" squeezes the 3–6 card title onto 2 lines (R regression) |
| 5 | Navigation / flow | NE | NE | NE | No navigation exercised |
| 6 | Visual coherence | 3 | 4 | 4 | A: token radius / padding / type. B: one grammar; unchanged modules (care duty, quick actions) still use the old look when visible (C) |
| 7 | Content / l10n | 2 | 3 | 3 | Both: untruncated vi / en times, one reminders term, one care title, empty-name fallback. The en "Ended 3 h 20 min ago" still wraps (R) |
| 8 | States / trust | 2 | 4 | 4 | Both show skeletons on loading; warm overdue; no first-run history link |
| 9 | Accessibility | 1 | 3 | 3 | Current tiles overflow at 200 % (R); A / B tiles grow, but tile meta ellipsises ("3 giờ 2…") and the shared header chip clips (R). Max 3 without a screen-reader check |
| 10 | Child Life identity | 4 | 4 | 3 | A keeps each module's colour chip and card personality. B's create, spending and family modules read like settings rows (R): calmer, but less warm and inviting |

**Verdicts:**

- **Current:** gates G1 and G2 at risk; acceptable at 100 % only.
- **A:** no gate at risk; strong, low-risk improvement.
- **B:** no gate at risk; strongest for scanning and density, weakest on identity.

### Where A is stronger

- **Continuity:** parents' mental model and the AX design are kept.
- **Module personality:** colour chips and cards (memories, create, spending feel like distinct
  features).
- **Lower implementation risk:** changes stay inside `AxCard`, `ReminderPeek(ax:)`, the tile
  layout and copy.

### Where B is stronger

- **Scanning:** headings outside, rows with chevrons, one grammar shared with the care section.
- **No filled buttons competing with content.**
- **Empty and first-run states are compact** (one row per empty module); a modest gain in what fits the first viewport.
- **Reminders read as a list:** full width, chevrons, count in the heading.

### Does B's structure justify its complexity?

**Partly:**

- **What B adds beyond A:** mainly (a) empty modules as single rows and (b) the heading-outside
  grammar.
- **Where B costs:** it rewrites every Ax module (memories, moment, create, growth, family,
  spending) and moves headers.
- **Where B regresses:** identity on the create, spending and family modules.

**The fixes that matter most for parents are in both versions:** truncation, loading, warm
overdue, the 200 % tiles, and terminology.

## 6. Findings by age group (R)

| Band | Current | A | B |
|---|---|---|---|
| 0–1 (tiles first) | Truncated reminder times; red overdue | Fixed; similar density | Fixed; reminders as a list |
| 1–3 (memories first) | A filled "Thêm khoảnh khắc" dominates the top; "Ghi nhanh" title | Tinted button; "Nhịp hôm nay" | Photo strip + add tile; no button; tiles start higher |
| 3–6 (moment, create, spending) | Three cards with three buttons (one filled) | Tinted buttons; the moment card title wraps (A regression) | Rows; most compact; create / spending feel utilitarian |
| 6–12 (memories, reminders, spending, growth) | Truncated reminders; two buttons | Fixed | Fixed; more fits per viewport |

**Correction to Step 8 TA-6:**

- **What it looked like:** the large grey area on 3–6 seemed to be an empty placeholder.
- **What it is:** `AxMomentToday` only renders when photos exist; the fixture photos have no
  bytes, so they render grey.
- **Status:** TA-6 is most likely a **fixture artefact** (H), not a production problem. Confirm
  with a real photo.

## 7. Findings by locale and theme (R)

- **vi / en:**
  - both versions show full times in both languages ("Overdue · yesterday 18:00",
    "Saturday 08:30 · in 2 days");
  - the long-name greeting wraps cleanly to 2 lines in all three;
  - en tile meta "Ended 3 h 20 min ago" wraps to 3 lines in all versions (copy, via
    `cl-ux-writing`).
- **Night care:**
  - warm overdue (`pending` = #FFD166 on dark) stays readable;
  - B's flat rows separate well by fill (`surface` on `cloud`);
  - A's cards rely on fills too (card shadows are empty at night), and the difference is visible.
- **Fixture:** the 1–3 / 3–6 / 6–12 renders keep "Teddy · 3 tuần" in the header chip.

## 8. Customisation preservation (R + C)

- `assets/ranked_orders.txt` shows the order each panel consumed, e.g.
  `customized light vi: recent_memories [pinned] → reminders → tiles → care_duty → growth (hidden)`.
- `compare_customized_light_vi` shows all three panels in that order, with growth absent.
- **The order is the engine's, not hard-coded:**
  - both prototypes iterate `adaptiveTodayProvider` and draw only `visible` widgets;
  - band orders match `bandDefaults` (e.g. 3–6:
    `moment_today → create_from_memories → spending → reminders → family_view`).
- **The relative's restricted set** (`tiles → care_duty`) is respected.
- **The Customize entry** is the production `AxCustomizeLink` in both.

## 9. State coverage

| State | Rendered | Notes |
|---|---|---|
| Populated 0–1 ×4 variants | ✓ | — |
| 1–3, 3–6, 6–12 | ✓ | vi Light + en Night care |
| Customised | ✓ | vi + en Light |
| First run (0–1, 3–6) | ✓ | — |
| No care logs (not first run) | ✓ | — |
| Overdue reminder | ✓ | In every populated fixture |
| Loading | ✓ | Simulated (nested scope); vi Light + Night care |
| Long name | ✓ | Simulated (nested scope); vi + en |
| Offline / pending | ✓ | vi Light |
| 200 % text | ✓ | vi + en; exceptions in `overflows.txt` |
| Read-only relative | ✓ | vi Light |
| Error (load failed) | **Not rendered** | Production providers fall back to empty; no error UI exists to render (Needs behavior verification) |
| Caregiver | Not rendered | `availableWidgetsProvider` gives care widgets only (C) |

## 10. Accessibility limitations

- **200 % renders:**
  - current: 6–7 layout exceptions (tiles);
  - A / B: one 30–40 px horizontal overflow, from the shared header row (the baby chip at
    200 %);
  - tile meta ellipsises inside tiles.

  None verified on a device.
- **Not evaluated:**
  - screen-reader reading order and labels (the prototypes add header semantics to the greeting
    and row labels such as "Mua sữa công thức, Quá hạn · hôm qua 18:00", but no semantics test
    ran);
  - focus, motion;
  - small phones.
- **Contrast:** warm overdue uses `pending` on `surface` (6.65:1 Light, 11.05:1 Night, from the
  token table).

## 11. Implementation trade-offs

| | A | B |
|---|---|---|
| Files | `features/adaptive/today_adaptive.dart` (`AxCard` tokens, button styles, greeting fallback); `features/reminders/reminder_screens.dart` (`ReminderPeek(ax:)` rows and colours; **shared with legacy Today**); `features/today/today_screen.dart` (skeleton, tile layout, care header, first-run link); ARB (3 strings) | All of A, plus rewrites of every Ax module's layout and new headers in `today_screen.dart` |
| New components | None. The tile row layout and skeleton are local; `ClSkeleton` exists | None required. An "add" tile and invitation rows compose existing `MeRow`, `ClCardGroup`, `ClTileShadow` |
| Golden churn | `ax10`–`ax13`, `ax40`–`ax43` × 4 variants + legacy `s4` Today | The same + larger diffs |
| Risk | Low: same structure | Medium: new grammar; identity regression to manage |
| Effort (estimate) | ~1–2 days incl. goldens | ~3–5 days incl. goldens and copy review |
| Approval class | Mostly routine (fixes); visible AX restyle (tinted buttons, radius 24) needs a nod | Owner (major screen restructure) |

**Production implication shared by both:**

- `ReminderPeek` is shared with legacy Today, so its row change shows there too.
- The tile layout change must also go into legacy Today, or the two will diverge.

**Sequencing:** another session currently has uncommitted edits in `today_screen.dart` and
`today_adaptive.dart`; production work starts after those land.

## 12. Recommendation

**Implement Version A in production first,** plus **one element from B**: empty modules as a
single invitation row (B's strongest gain, at low cost and no identity loss).

**Why:**

- **A carries the improvements that matter most to a tired parent:** readable reminder times,
  calm overdue, no false "Chưa có", tiles that survive 200 %, one set of names.
- **A carries them at low risk,** and it keeps the warmth of per-module cards.
- **B's remaining gains** (heading-outside grammar, list-like modules) are real for scanning but
  cost a broad rewrite and make create, spending and family feel like settings.
- **Revisit B's grammar** once the `ClCard` family exists (cl-components), which could give B's
  structure A's personality.

**Compromises that remain:**

- en tile meta still wraps (copy);
- the header baby chip clips at 200 % (shared header, separate fix);
- A's "Xem tất cả" on the 3–6 moment card wraps the title (drop the link there, or shorten the
  title);
- reminder rows: the prototypes show 3, the current adaptive card shows 2 (a density choice for
  the owner).

---

## Tóm tắt cho chủ sản phẩm

**Bản A (tinh chỉnh bản hiện tại) tốt hơn ở:**
- giữ nguyên cảm giác quen thuộc và nét riêng của từng thẻ (kỷ niệm, chi tiêu, tạo video có màu và biểu tượng riêng), ấm áp;
- sửa được đúng những lỗi khiến ba mẹ khó chịu, mà ít rủi ro:
  - giờ nhắc việc đọc trọn, việc quá hạn hiện vàng ấm có biểu tượng thay vì chữ đỏ;
  - lúc đang tải hiện khung chờ, không hiện "Chưa có" sai;
  - chữ to 200% thì các ô chăm sóc tự cao lên, không bị cắt;
  - tên gọi thống nhất "Nhắc việc", "Nhịp hôm nay";
  - nút trong thẻ nhẹ đi.

**Bản B (Bản tin) tốt hơn ở:**
- dễ quét hơn: tiêu đề mỗi mục nằm ngoài, nội dung là các dòng bấm được có mũi tên;
- không còn nút đậm nào tranh sự chú ý;
- mục trống chỉ còn một dòng mời, nên màn đầu tiên gọn hơn một chút.

Đổi lại, các mục "Tạo từ kỷ niệm", "Chi tiêu", "Gia đình" trông giống trang cài đặt, kém ấm hơn; và phải viết lại gần như mọi thẻ.

**Đề xuất:** làm bản A trước, lấy thêm từ B cách hiển thị mục trống (một dòng mời). Để bản B sau, khi có bộ thẻ dùng chung (ClCard) để giữ được nét riêng của từng mục.

**Còn tồn tại:**
- dòng "Kết thúc 3 giờ 20 phút trước" ở tiếng Anh vẫn xuống dòng;
- tên bé trên thanh đầu trang bị cắt khi chữ 200% (lỗi chung, sửa riêng);
- ở bản A, thẻ "Lưu khoảnh khắc hôm nay" (3–6 tuổi) bị xuống dòng tiêu đề khi thêm "Xem tất cả".

Khung xám lớn ở màn 3–6 tuổi trong ảnh thử là do ảnh mẫu không có dữ liệu ảnh, không phải lỗi thật (cần kiểm tra lại với ảnh thật).

**Cần anh/chị duyệt trước khi làm thật:**
1. Chọn A, B, hay A + mục trống của B.
2. "Nhắc việc" thành tên chính thức.
3. Một tiêu đề "Nhịp hôm nay" cho mọi độ tuổi.
4. Hiện 2 hay 3 nhắc việc trên Hôm nay.
5. Nút trong thẻ đổi từ đậm sang nhạt; bo góc thẻ theo chuẩn chung.
6. Câu chào khi chưa có tên bé ("Chào buổi chiều").

Lưu ý: thay đổi phần nhắc việc và cách xếp các ô sẽ áp dụng cả màn Hôm nay bản cũ.
