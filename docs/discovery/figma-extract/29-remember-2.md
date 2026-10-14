# Figma extraction — Kỷ niệm 2.0: Video kỷ niệm (MM01–MM09) and Thiệp cột mốc & các trạng thái (MM10–MM17)

Source: Figma `sJLG1fAXKDnDr9YI6Yx8ex`, page "v1.0 - improvement" `345:35701`. Extracted read-only on 2026-10-13: get_metadata for every frame, get_design_context on the text-bearing nodes (rendered text is authoritative; several layer names are truncated or stale, e.g. the "Chọn từ Tệp" subtitle layer is named "iCloud Drive, Google Drive, US…" but renders `iCloud Drive`), get_screenshot for every frame. Screenshots are in [`img/mm/`](img/mm/), one PNG per frame named after the node id with `-` for `:` (e.g. `528-9260.png`).

**Theme.** Every frame in both rows renders in **Night care** (dark surfaces, mint accents). No Light twins and no "N" frames were found for this feature.

**Coverage.** 15 frames found. **MM04 and MM05 (row 1, x = 1245 and 1660) could not be located** — see "Frames not found" at the end. No row label was found for row 1, no MM18+ in row 2, and no annotation or sticky-note nodes beside either row.

Relation to the map: the landing v5b section "Câu chuyện kỷ niệm" / "Phép màu cột mốc" (`28-landing-v5b-home.md` §12, Q-039) promised exactly these two products; today the app has text + photo Stories (D-041) and a 5-template photo card exported through the share sheet (R-161).

## Row 1 · Video kỷ niệm (y 32100; label not found — the owner calls it "MM · Kỷ niệm 2.0 · Câu chuyện kỷ niệm & Thiệp cột mốc")

### MM01 · Kỷ niệm · lối vào tạo mới (`528:9260`)
- **Purpose:** Kỷ niệm tab (Ảnh view) with a new "create from memories" section at the top.
- **Copy (reading order):**
  - Header: avatar `D` · BabySwitcher `Teddy` (chevron) · filter button (sliders) · mint `+` button
  - Big tabs: `Ảnh` (active) · `Album` · `Nhật ký` · `Câu chuyện` (cut off at the right edge)
  - Filter chips: `Theo tuần tuổi` ▾ · `Ảnh & video` ▾ · round check button (select mode)
  - Section header: `Tạo từ kỷ niệm của Teddy` · link `Xem mẫu`
  - Card 1: fanned preview of three 9:16 video templates (Peach, Mint with big `1`, Sky) · `Video kỷ niệm` + badge `Mới` · `Ảnh + chữ + nhạc`
  - Card 2: two milestone-card previews (`7 ngày` / `Teddy ·`; `1 tháng` / `Teddy` / `14.11`) · `Thiệp cột mốc` + badge `Mới` · `Ảnh PNG để chia sẻ`
  - Week group: `Tuần 4` · `8–14 tháng 10 · 26 ảnh, 2 video`; 4-column photo grid (two video tiles `▶ 0:35`)
  - Floating week pill `Tuần 4` ▾ · mint FAB `+`
  - Dock: Hôm nay (icon) · `Kỷ niệm` (active, labelled) · Chăm sóc (icon) · Tiện ích (icon)
- **States / controls:** both cards are tappable (whole card); `Xem mẫu` is a text link. Badges `Mới` on both.
- **Behaviour implied:** the creation entry is per selected baby (`của Teddy`) and sits above the timeline on the Ảnh tab. `Xem mẫu` presumably opens a template gallery (not drawn — see MM04/MM05). The milestone card is described as a PNG image for sharing.
- **Annotations:** none.

### MM02 · Thêm vào Kỷ niệm (bottom sheet) (`528:9538`; sheet `537:9720`, video chip `540:10078`)
- **Purpose:** the `+` add sheet over MM01 (scrim), now with a "creative & automatic" group.
- **Copy:**
  - Handle · title `Thêm vào Kỷ niệm` · close ×
  - `Ảnh mới chụp hôm nay` · `Chạm để chọn`; strip of 6 thumbnails with empty selection circles (one video `0:12`)
  - Highlighted row (mint border): `Chụp ảnh hoặc quay video` — `Lưu thẳng vào Kỷ niệm`
  - `Chọn từ Thư viện ảnh` — `Chọn nhiều ảnh, video một lần`
  - `Chọn từ Tệp` — `iCloud Drive`
  - `Viết ghi chú` — `Kỷ niệm chỉ có chữ, thêm ảnh sau`
  - Group label `SÁNG TẠO & TỰ ĐỘNG`
  - Two tiles: `Video kỷ niệm` + `Mới` — `Ảnh + chữ + nhạc`; `Thiệp cột mốc` + `Mới` — `Ảnh để chia sẻ`
  - Row: `Tự lưu kỷ niệm` + badge `Beta miễn phí` — `Đang bật · 8 ảnh mới chờ duyệt` · button `Duyệt`
- **States / controls:** today's photos are multi-select (circles); every row has a chevron; the Tự lưu row has an inline `Duyệt` button (pending state of `27-auto-save.md` AS01).
- **Behaviour implied:** Video kỷ niệm and Thiệp cột mốc are also reachable from the add sheet, grouped with Tự lưu under "Sáng tạo & tự động". Note the tile subtitle differs from MM01 (`Ảnh để chia sẻ` here vs `Ảnh PNG để chia sẻ` on MM01).
- **Annotations:** none.

### MM03 · Gợi ý theo cột mốc (`528:9864`; card `528:10023`)
- **Purpose:** Kỷ niệm tab with a dismissible milestone nudge replacing the MM01 create cards.
- **Copy:**
  - Same header, tabs, filter chips as MM01
  - Card (mint border): preview of a video template (`1`) overlapped by a `1 tháng` card · cake icon `Thứ Bảy này · 14/11` · `Teddy sắp tròn 1 tháng! Cùng tạo một kỷ niệm thật đẹp nhé.` · close ×
  - Actions: primary pill `Tạo video` (camera icon) · outline pill `Tạo thiệp` (star icon) · text `Để sau`
  - Below: `Tuần 4` · `8–14 tháng 10 · 26 ảnh, 2 video`, grid, week pill, FAB, dock as MM01
- **States / controls:** × and `Để sau` both dismiss (difference not specified). Two CTAs.
- **Behaviour implied:** the app knows upcoming age milestones from the baby profile (DOB → "tròn 1 tháng" on 14/11) and nudges a few days ahead ("Thứ Bảy này"). `Tạo video` would go to the video flow pre-set to the matching template (MM06 header shows `Tháng đầu tiên`); `Tạo thiệp` to MM10 with `1 tháng` pre-selected (MM10 marks `1 tháng` as `Gợi ý`).
- **Annotations:** none.

### MM04 / MM05 — not located
Positions x = 1245 and 1660 on y 32100 are implied by the 415 px spacing and the numbering, but no node was found (see "Frames not found"). By the flow they most likely hold the **video template picker** (target of `Xem mẫu` / the Video kỷ niệm card) and a **template preview** or similar. Their content is unknown — do not assume a premium/free split for video templates from this extraction.

### MM06 · Chọn ảnh cho video (`529:9070`)
- **Purpose:** pick photos to fill the template's scenes.
- **Copy:**
  - Back ‹ · template name top-right `Tháng đầu tiên`
  - Title `Chọn ảnh cho video`
  - Progress card: `6/8 cảnh đã có ảnh` · `Tối thiểu 6`; scene strip of 8 slots — six numbered thumbnails `1`…`6`, two dashed `+` slots; caption `Cảnh 7: Bé cười  ·  Cảnh 8: Cả nhà (không bắt buộc)`
  - Segmented: `Từ Kỷ niệm` (selected) · `Thư viện máy`
  - Hint (spark icon): `Gợi ý: ảnh tuần 1–4 của Teddy`
  - 4-column grid: selected tiles have a mint border and a numbered badge in pick order (1–6); unselected tiles show an empty circle; one video tile `▶ 0:35`
  - Bottom bar: `Đã chọn 6 ảnh` · `Có thể thêm 2` · primary button `Tiếp tục`
- **States / controls:** selection order = scene order; min 6 / max 8 for this template; `Tiếp tục` enabled at the minimum. Scenes have names (Cảnh 7 "Bé cười", Cảnh 8 "Cả nhà") and the last can be optional.
- **Behaviour implied:** templates define a scene count, a minimum, and scene hints. Photos come from existing Kỷ niệm (pre-filtered to the template's age range, "tuần 1–4") or the device library. A video tile is selectable — whether video clips are used as clips or as a still is not shown.
- **Annotations:** none.

### MM07 · Hoàn thiện video (`530:9248`)
- **Purpose:** final edit before rendering.
- **Copy:**
  - Back ‹ · title `Hoàn thiện video`
  - Summary: 9:16 thumbnail (`1` / `Tháng đầu tiên`) · chip ✓ `Điền sẵn từ hồ sơ của bé` · `Bé` `Teddy · 1 tháng` · `Ngày mốc` `14.11.2026`
  - Field `Tiêu đề` (pencil): `Tháng đầu tiên của Teddy`
  - Field `Lời nhắn cuối video`: `Một tháng qua, con dạy ba mẹ biết yêu thương nhiều hơn.`
  - `6 ảnh · thứ tự xuất hiện` · `Giữ và kéo để đổi`; strip of 6 thumbnails + `+`
  - Row `Nhạc nền` — `Ru con nhẹ nhàng` · link `Đổi`
  - Row `Ai xem được` — `Chỉ ba mẹ · lưu vào Kỷ niệm` · chevron
  - Bottom bar: primary `Tạo video` · `Mất khoảng 1–2 phút · bạn có thể rời màn hình`
- **States / controls:** title and closing message editable and pre-filled; drag to reorder; `+` adds photos; music has a `Đổi` action; visibility row opens something (not drawn).
- **Prefilled:** baby name + age at the milestone and the milestone date from the profile; a default title and a default closing message from the template; a default track per template.
- **Annotations:** none.

### MM08 · Đang tạo video (`530:9372`)
- **Purpose:** rendering progress.
- **Copy:**
  - Close ×
  - Dimmed 9:16 preview (`1` / `Tháng đầu tiên của Teddy`) with a progress ring `64%`
  - `Đang tạo video cho Teddy…`
  - `Thường mất 1–2 phút. Bạn có thể rời màn hình này, Child Life sẽ báo khi video sẵn sàng.`
  - Steps: ✓ `Sắp xếp 6 ảnh theo mẫu` · ✓ `Thêm chữ, lời nhắn và nhạc` · ⏱ `Xuất video 9:16` (current, bold)
  - Secondary button `Về Kỷ niệm`
- **States / controls:** percentage + 3 named steps; × and `Về Kỷ niệm` both leave without cancelling (no cancel action drawn).
- **Behaviour implied:** rendering continues when the user leaves (server-side or background); completion triggers a notice (MM17). Output format is always **9:16**.
- **Annotations:** none.

### MM09 · Video đã sẵn sàng (`530:9423`)
- **Purpose:** success screen.
- **Copy:**
  - Close × · edit (pencil) top-right
  - 9:16 video preview with play button, duration `0:45`, `1` / `Tháng đầu tiên của Teddy` / `14.10 – 14.11.2026`, sparkle stars around
  - `Video đã sẵn sàng!`
  - Chip ✓ `Đã lưu vào Kỷ niệm · Tuần 4 · Chỉ ba mẹ`
  - Actions: `Lưu vào máy` · `Chia sẻ` · `Xem trong Kỷ niệm`
  - Next-step row: mini `1 tháng` card · `Tạo thêm thiệp “1 tháng”` — `Dùng lại ảnh vừa chọn` · chevron
- **States / controls:** saved automatically (no save button); three secondary actions; edit pencil re-opens editing (target not drawn).
- **Behaviour implied:** the video is saved as a memory in the week bucket with the chosen visibility. Cross-sell into a milestone card reusing the same photos.
- **Annotations:** none.

## Row 2 · "Label · MM · Thiệp cột mốc & các trạng thái" (label `530:9514`, y 33080; frames y 33150)

### MM10 · Thiệp cột mốc · chọn mẫu (`530:9515`, frame height 895)
- **Purpose:** pick the occasion, the format and the card template.
- **Copy:**
  - Back ‹ · title `Thiệp cột mốc`
  - `Chọn dịp`; chips: `1 tháng` + badge `Gợi ý` (selected, mint) · `7 ngày` · `100 ngày` · `Lần đầu cười` (heart) · `Lần đầu biết lẫy` (star) · `Biết bò` (star) · `Bước đi đầu tiên` (star) · `Sinh nhật 1 tuổi` (cake)
  - Segmented format: `Dọc 4:5` (selected) · `Vuông` · `Story 9:16`
  - 2×2 template grid, each preview pre-filled `1 tháng` / `Teddy` / `14.11.2026`:
    - `Tròn trịa` — badge `Miễn phí` (cream card, round photo)
    - `Toàn ảnh` — badge `Miễn phí` (full-bleed photo, gradient)
    - `Hồng phấn` — badge ★ `Cao cấp` (pink card, framed photo)
    - `Đêm sao` — badge ★ `Cao cấp` (navy card, round photo)
- **States / controls:** single-select chip, single-select segment; tapping a template continues (no bottom CTA). No lock icon on premium templates; nothing drawn for what happens when a free user taps `Cao cấp`.
- **Behaviour implied:** age occasions (cake icon) are computed from DOB; "first" occasions (heart/star) map to developmental milestones. The suggested occasion is the nearest one. Premium is per template, not per feature.
- **Annotations:** none.

### MM11 · Thiệp cột mốc · chỉnh sửa (`530:9663`)
- **Purpose:** edit the card.
- **Copy:**
  - Close × · link `Xem trước`
  - Large card preview: round photo · hint pill (camera) `Chạm ảnh để đổi · kéo để căn` · `1 tháng` · `Teddy` · `14.11.2026` · `“Một tháng yêu thương”` · stars
  - Tool tabs: `Ảnh` · `Bố cục` (selected) · `Lời nhắn` · `Màu`
  - Layout strip (Bố cục): 4 layouts — round photo (selected, mint border), full-bleed, framed, navy
  - Bottom bar: primary `Lưu thiệp` · `Tên, tuổi và ngày được điền sẵn từ hồ sơ của Teddy`
- **States / controls:** tap photo to replace, drag to reposition; 4 tools (only Bố cục drawn open); `Xem trước` link.
- **Prefilled:** name, age label and date from the baby profile; a default quote per occasion (`“Một tháng yêu thương”`).
- **Behaviour implied:** the Bố cục strip shows the same four layouts as MM10 including the two `Cao cấp` ones, with no badge here.
- **Annotations:** none.

### MM12 · Thiệp đã sẵn sàng (`531:9375`)
- **Purpose:** card saved / export.
- **Copy:**
  - Close × · edit (pencil)
  - Tilted card on a warm glow with stars (`1 tháng` / `Teddy` / `14.11.2026` / `“Một tháng yêu thương”`)
  - `Thiệp đã sẵn sàng!` · chip ✓ `Đã lưu vào Kỷ niệm · Chỉ ba mẹ`
  - `Xuất ảnh` · toggle `PNG` (selected) · `JPG`
  - Actions: `Lưu vào máy` · `Chia sẻ` · `Tạo video 1 tháng`
- **States / controls:** export format choice affects device save / share only; card already saved to Kỷ niệm.
- **Behaviour implied:** symmetric cross-sell to MM09 (card → video for the same occasion). No processing state for cards (rendered instantly).
- **Annotations:** none.

### MM13 · Chưa đủ ảnh (`531:9447`)
- **Purpose:** video photo picker when Kỷ niệm doesn't have enough suitable photos.
- **Copy:**
  - Back ‹ · template name `100 ngày yêu thương`
  - `Chọn ảnh cho video`
  - Progress: `3/10 cảnh đã có ảnh` · `Tối thiểu 8` (peach/warning colour); 3 thumbnails + 7 empty `+` slots
  - Warning banner (sunshine-soft, alert icon): `Kỷ niệm của Teddy hiện chỉ có 3 ảnh phù hợp. Mẫu này cần ít nhất 8 ảnh.`
  - Options:
    - `Chọn thêm từ thư viện máy` — `Chỉ ảnh bạn chọn mới được dùng`
    - `Đổi sang mẫu ngắn hơn` — `“Khoảnh khắc nhỏ” · cần 3 ảnh`
    - `Lưu nháp, làm tiếp sau` — `Giữ nguyên 3 ảnh đã chọn`
  - Bottom bar: `Đã chọn 3 ảnh` · `Cần thêm 5` (peach) · `Tiếp tục` **disabled** (40 % opacity)
- **Behaviour implied:** "phù hợp" means within the template's window (100 days). Device-library photos are used only if picked. A shorter template exists (`Khoảnh khắc nhỏ`, 3 photos). Drafts are a first-class object.
- **Annotations:** none.

### MM14 · Tạo video chưa thành công (`531:9555`)
- **Purpose:** render failure.
- **Copy:**
  - Close ×
  - Dimmed 9:16 preview (`1` / `Tháng đầu tiên của Teddy`) with a red alert badge
  - `Chưa tạo được video`
  - `Kết nối bị gián đoạn khi xuất video. Ảnh, chữ và lời nhắn bạn đã chọn vẫn được giữ nguyên.`
  - Primary `Thử lại` · secondary `Chỉnh lại lựa chọn`
  - `Bản nháp được lưu trong Câu chuyện · Bản nháp`
- **Behaviour implied:** a failed render keeps all inputs as a draft in Câu chuyện; retry re-submits without re-picking. Only the network-interruption cause is drawn.
- **Annotations:** none.

### MM15 · Tab Câu chuyện · đã tạo (`532:9453`)
- **Purpose:** the Câu chuyện tab as the home of created videos and cards.
- **Copy:**
  - Header as MM01; tabs scrolled so `Nhật ký` · `Câu chuyện` (active) show
  - Quick-create row: `Video kỷ niệm` (camera tile) · `Thiệp cột mốc` (star tile)
  - Section `Video kỷ niệm` · `2 video`: `Tháng đầu tiên` (`▶ 0:45`) — `Chỉ ba mẹ`; `7 ngày đầu đời` (`▶ 0:30`) — `Chỉ ba mẹ`; dashed draft tile `Bản nháp` — `100 ngày · 3/10 ảnh` — link `Làm tiếp`
  - Section `Thiệp cột mốc` · `3 thiệp`: `1 tháng` (round, cream), `7 ngày` (pink framed), `Lần đầu cười` (full-bleed) — row scrolls horizontally
  - Dock as MM01
- **Behaviour implied:** each item shows its visibility; drafts appear inline in the video list. **No existing text Stories (D-041) appear on this tab** in the design.
- **Annotations:** none.

### MM16 · Tab Câu chuyện · trống (`532:9636`)
- **Purpose:** empty state of the Câu chuyện tab.
- **Copy:**
  - Header/tabs as MM15
  - Collage: two 9:16 video templates (`1` / `Tháng đầu tiên`) + a `100 ngày` / `Teddy` card
  - `Biến kỷ niệm thành video và thiệp`
  - `Chọn một mẫu, thêm vài tấm ảnh của Teddy — Child Life sẽ làm phần còn lại. Bạn luôn tự chọn ảnh và quyết định chia sẻ.`
  - Primary `Tạo video kỷ niệm` · secondary `Tạo thiệp cột mốc`
- **Behaviour implied:** privacy promise in the copy: nothing is auto-selected or auto-shared.
- **Annotations:** none.

### MM17 · Video xong · thông báo trong app (`532:9741`)
- **Purpose:** in-app completion notice after leaving MM08.
- **Copy:**
  - Kỷ niệm › Ảnh tab, `Tuần 5` · `15–21 tháng 10 · 18 ảnh, 1 video, 1 thiệp`
  - Grid: first tile badge (camera) `Câu chuyện`; another tile badge (star) `Thiệp`; one plain video `▶ 0:35`
  - Floating banner above the dock: video thumbnail · `Video đã sẵn sàng` · `“Tháng đầu tiên của Teddy” · 0:45` · button `Xem`
  - FAB hidden while the banner shows
- **Behaviour implied:** created videos and cards also appear in the Ảnh grid, badged by type, and the week header counts them separately ("1 video, 1 thiệp"). The notice is an in-app banner; no OS push is drawn.
- **Annotations:** none.

### Frames not found
- **MM04 and MM05** (row 1, x = 1245 / 1660). Probed: every id in the gaps around the found frames (`528:9672…9863` — the original nodes there were deleted; `528:10068…10500`; `529:8200…9069`; `529:9309…9700`; `530:9050…9237`; `531:9200…9374`, `531:9596…9900`; `532:9100…9452`; `532:9999…10001`) and sample ids in sessions 527, 533–541, 543. None hit. Ask the owner for a link to these two frames.
- **Row 1 label** (expected near y 32030): not found (`528:9259`, `528:9257`, `528:9258` absent).
- **MM18+** in row 2 (x ≥ 3320): nothing after MM17 (`532:9999`/`10000`/`10001` absent).
- No Night/Light twins and no annotation nodes were found; there is no evidence either way beyond the probed ids.

## Cross-screen flow

### Navigation graph as drawn
```
Kỷ niệm › Ảnh (MM01) ──Video kỷ niệm card / Xem mẫu──▶ [MM04/MM05 not found: template picker?]
        │                                                         │
        ├──+ / FAB──▶ Thêm vào Kỷ niệm sheet (MM02) ──Video kỷ niệm / Thiệp cột mốc tiles──▶ (same entries)
        │
Kỷ niệm › Ảnh with milestone nudge (MM03) ──Tạo video──▶ MM06 (template "Tháng đầu tiên" pre-set)
                                           └─Tạo thiệp──▶ MM10 (occasion "1 tháng · Gợi ý")
                                           └─× / Để sau──▶ dismiss

VIDEO:  MM06 Chọn ảnh ──Tiếp tục──▶ MM07 Hoàn thiện ──Tạo video──▶ MM08 Đang tạo
        │ (not enough photos) = MM13 ──Chọn thêm từ thư viện / Đổi sang mẫu ngắn hơn / Lưu nháp──▶ …
        MM08 ──success──▶ MM09 Video đã sẵn sàng ──Tạo thêm thiệp "1 tháng"──▶ card flow (MM10/MM11)
             ──× / Về Kỷ niệm──▶ Kỷ niệm; later MM17 banner ──Xem──▶ MM09 (presumably)
             ──failure──▶ MM14 ──Thử lại──▶ MM08 · ──Chỉnh lại lựa chọn──▶ MM06/MM07 · draft in Câu chuyện

CARD:   MM10 Chọn dịp + format + mẫu ──tap template──▶ MM11 Chỉnh sửa ──Lưu thiệp──▶ MM12 Thiệp đã sẵn sàng
        MM12 ──Tạo video 1 tháng──▶ video flow · ──Lưu vào máy / Chia sẻ──▶ OS

CÂU CHUYỆN tab: empty MM16 ──Tạo video kỷ niệm / Tạo thiệp cột mốc──▶ flows; filled MM15 lists videos, drafts (Làm tiếp ▶ MM13-like picker), cards
```

### Rules the frames imply
1. **Two products, one family.** `Video kỷ niệm` = "Ảnh + chữ + nhạc", always **9:16** (MM08 step `Xuất video 9:16`). `Thiệp cột mốc` = one image, formats **Dọc 4:5 / Vuông / Story 9:16**, export **PNG or JPG** (MM10, MM12). Both carry the badge `Mới` at the entry points.
2. **Entry points:** Kỷ niệm › Ảnh top section (MM01), the `+` sheet group `SÁNG TẠO & TỰ ĐỘNG` (MM02), the milestone nudge (MM03), the Câu chuyện tab quick-create row and empty state (MM15, MM16), cross-sell from each success screen (MM09 → card, MM12 → video).
3. **Milestone nudge:** shown a few days before an age milestone computed from DOB (`Thứ Bảy này · 14/11`, `Teddy sắp tròn 1 tháng!`), with both CTAs, `Để sau` and ×.
4. **Video templates** carry: a name (`Tháng đầu tiên`, `7 ngày đầu đời`, `100 ngày yêu thương`, `Khoảnh khắc nhỏ`), a scene count (8, 10, 3), a minimum (6, 8, 3), named scenes with optional ones (`Cảnh 8: Cả nhà (không bắt buộc)`), an age window for suggestions (`ảnh tuần 1–4`), a default title, a default closing message and a default track (`Ru con nhẹ nhàng`).
5. **Photo sources:** existing Kỷ niệm (default, pre-filtered to the template's window) or `Thư viện máy`; only picked photos are used (`Chỉ ảnh bạn chọn mới được dùng`). Pick order = scene order; reorder by long-press drag on MM07.
6. **Prefill from the baby profile:** name, age at the milestone, milestone date (`Điền sẵn từ hồ sơ của bé`; `Tên, tuổi và ngày được điền sẵn từ hồ sơ của Teddy`). Date range on the video (`14.10 – 14.11.2026`) = birth to milestone.
7. **Rendering is asynchronous for videos** (`Thường mất 1–2 phút`, "bạn có thể rời màn hình"), with % and 3 steps; completion notice = in-app banner `Video đã sẵn sàng` · `“{title}” · {duration}` · `Xem` (MM17). Cards have no processing state.
8. **Failure:** `Chưa tạo được video` + cause line; inputs are kept; `Thử lại` / `Chỉnh lại lựa chọn`; the job becomes a draft in `Câu chuyện · Bản nháp` (MM14).
9. **Not enough photos:** banner + three escapes (pick from device, switch to a shorter template, save draft); `Tiếp tục` disabled with `Cần thêm {n}` (MM13).
10. **Drafts** appear in Câu chuyện › Video kỷ niệm as a dashed tile with template and progress (`100 ngày · 3/10 ảnh`) and `Làm tiếp` (MM15).
11. **Where outputs go:**
    - Saved automatically as a memory: video `Đã lưu vào Kỷ niệm · Tuần 4 · Chỉ ba mẹ` (MM09), card `Đã lưu vào Kỷ niệm · Chỉ ba mẹ` (MM12).
    - Listed in the **Câu chuyện** tab under `Video kỷ niệm` / `Thiệp cột mốc` (MM15).
    - Also shown in the **Ảnh** grid, badged `Câu chuyện` (video) or `Thiệp` (card), and counted in the week header (MM17).
    - Not shown in Album or Nhật ký in any frame.
    - Off-app: `Lưu vào máy` and `Chia sẻ` (OS share) on both success screens.
12. **Visibility default `Chỉ ba mẹ`** for both products (MM07 row, MM09/MM12 chips, MM15 captions); changeable on MM07 via `Ai xem được` (picker not drawn).
13. **Premium:** only on **card templates** — `Tròn trịa`, `Toàn ảnh` = `Miễn phí`; `Hồng phấn`, `Đêm sao` = ★ `Cao cấp` (MM10). No premium marking on video anywhere drawn (but the video template picker MM04/MM05 is missing). No paywall, lock, trial or upsell screen is drawn.
14. **Privacy promise:** `Bạn luôn tự chọn ảnh và quyết định chia sẻ.` (MM16); nothing auto-shared.

## Open questions / what the design leaves open

1. **MM04 / MM05 are missing from the extraction** — likely the video template gallery and preview, which is where premium/free for video, template count, music and duration would be decided. Need the owner's link.
2. **Premium paywall:** what happens on tapping a `Cao cấp` card template (MM10) without a plan — paywall, preview with watermark, or locked? Is there a paid plan at all yet (Q-058 says not)? Are any video templates premium?
3. **No music picker** — MM07 `Nhạc nền · Ru con nhẹ nhàng · Đổi` has no target. Track catalogue, licensing and whether users can use their own audio are open (landing Q-039 already flags music licensing).
4. **No `Ai xem được` picker** for videos/cards; options (Chỉ ba mẹ / Gia đình / …) and whether saving to Gia đình sends a family notice (D-001, D-041 rule "first save to Gia đình sends one notice") are not drawn.
5. **Câu chuyện tab vs existing Stories (D-041):** MM15/MM16 show only videos and cards — where do text + photo Stories and the weekly AI draft go? Is "Câu chuyện" being repurposed?
6. **Tabs `Ảnh / Album / Nhật ký / Câu chuyện`** vs D-052 / D-066 (current Kỷ niệm tabs kept "như cũ"): is the 4-tab layout in scope, or do the entries go on the existing tabs?
7. **Relation to R-161 photo cards** (5 templates, 1080×1350, OS share): do Thiệp cột mốc replace or sit beside them?
8. **Rendering:** server or on-device? What sends the completion notice when the app is closed — an OS push (not drawn) or only the in-app banner (MM17)? Can a render be cancelled (no cancel on MM08)?
9. **Failure causes** other than "Kết nối bị gián đoạn" (server error, photo deleted meanwhile, quota/storage full) and retry limits are not drawn.
10. **Storage quota:** do generated videos/cards count against family storage (as Tự lưu does)? Not mentioned.
11. **Week bucket inconsistency:** MM09 says `Tuần 4` but MM17 shows the new video under `Tuần 5`. Is the memory dated by the milestone date, the creation date or the last photo?
12. **Ảnh grid badges:** the video tile is badged `Câu chuyện` (not `Video`) in MM17 — intended wording?
13. **Card editing tools:** only `Bố cục` is drawn; `Ảnh`, `Lời nhắn`, `Màu` panels, the `Xem trước` screen and the MM09/MM12 edit (pencil) targets are not drawn. Can a saved video be edited and re-rendered (new memory or replace)?
14. **Milestone nudge rules:** how many days ahead, which milestones trigger it (age only, or also "first" milestones), once per milestone, per parent or per family, and what × vs `Để sau` mean (snooze vs never).
15. **"First" occasions** (`Lần đầu cười`, `Lần đầu biết lẫy`, `Biết bò`, `Bước đi đầu tiên`): is the date taken from a logged milestone (R-103/R-105), and what if none is logged?
16. **Video tiles in the picker** (MM06 shows `▶ 0:35` selectable): are clips used as moving scenes, trimmed, or as stills? Max clip length?
17. **Roles:** can a Người chăm sóc / Người thân create videos or cards? No role gating is drawn.
18. **Sharing format:** `Chia sẻ` shares the file or a link? Is there a watermark / "Child Life" mark (R-161 has one)?
19. **Light theme:** every frame is Night care; Light versions are assumed but not drawn.
20. **Admin side:** no portal screens for managing video/card templates, music, occasions or premium flags are drawn.
