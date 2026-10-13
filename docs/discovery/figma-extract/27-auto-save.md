# Figma extraction — Tự lưu kỷ niệm (AS) and Lần mở app sau (AR)

Source: Figma `sJLG1fAXKDnDr9YI6Yx8ex`, page "v1.0 - improvement" `345:35701`. Extracted read-only via get_design_context (rendered text is authoritative) on 2026-10-13. Night twins AS07N/AS12N via screenshot only.

Owner decisions on this extraction: D-066 in [`../../product/business-map.md`](../../product/business-map.md); plan and engineering proposals in [`../../product/auto-save-plan.md`](../../product/auto-save-plan.md). The "Open questions" at the end are the raw list from the read; the plan says which are answered.

## Row "AS · Tự lưu kỷ niệm · Beta miễn phí" (label `479:7357`)

### AS01 · Kỷ niệm · lối vào Tự lưu (`479:7358`)
- **Purpose:** Memories (Kỷ niệm) timeline tab showing the new entry point card for Tự lưu kỷ niệm, sitting between the view chips and the upload pill.
- **Copy (reading order):**
  - Header: avatar chip `M` · BabySwitcher `Teddy · 3 tuần` (chevron) · icon buttons (sliders = view options, `+` = add)
  - Title: `Kỷ niệm`
  - View chips: `Dòng thời gian` (selected, dark) · `Ảnh & video`
  - Entry card (tappable row, spark icon on sunshine-soft tile, chevron-right): `Tự lưu kỷ niệm` + badge `Beta miễn phí`; subtitle `Gợi ý ảnh, video có Teddy từ thư viện máy`
  - Upload pill (mint-soft, thumbnail with ring progress, chevron): `Đang tải 4/7 mục` · progress bar · `Cứ làm việc khác, xong sẽ báo bạn`
  - Week group: `Tuần thứ 3` · `1 – 8 tháng 10 · 13 ảnh, 3 video`
    - Entry: `M` `Mẹ` `Hôm nay · 9:20` (family icon) · `Ngủ trưa ngon lành sau giờ tắm.` · photo · ♡ `Bà nội, Ông ngoại thương`
    - Entry: `B` `Ba` `Hôm qua · 19:05` (family icon) · `Lần đầu nắm chặt ngón tay ba.` · video tile with play + duration `0:42` · ♡ `2 người thả tim`
    - Entry: `M` `Mẹ` `Thứ Ba, 6 thg 10` (family icon) · `Bà nội sang thăm, mang theo đôi tất len tự đan.` · 2 photos
    - Note entry (sunshine-soft): `M` `Mẹ` `Thứ Hai, 5 thg 10` (lock icon = private) · `Đêm qua con ngủ một mạch 4 tiếng. Mẹ dậy mà vẫn thấy lạ.`
    - Entry: `M` `Mẹ` `Thứ Hai, 5 thg 10` (family icon) · milestone chip `★ Lần đầu cười · 5 thg 10` · grid of 4 tiles (one video `0:24`, one bookmarked/favorite, last tile private lock + `+3`)
  - Week group: `Tuần thứ 2` · `24 – 30 tháng 9 · 6 ảnh`
    - Entry: `B` `Ba` `Chủ nhật, 20 thg 9` · milestone chip `★ Ngày đầu về nhà · 20 thg 9` · 3 tiles (one bookmarked)
  - Tab bar: `Hôm nay` · `Kỷ niệm` (active) · `Chăm sóc` · `Tiện ích`
- **States / controls:** Entry card is a single tappable row (not dismissible in this frame; no close ×). Upload pill progress fill ≈ 44 % (label says 4/7). Timeline view chip selected.
- **Behaviour implied:** Tự lưu is reached from the Kỷ niệm tab, per currently selected baby (subtitle interpolates the baby name). The entry card is shown above the existing upload pill; uploads launched from Tự lưu use the same global upload pill as manual uploads ("Cứ làm việc khác, xong sẽ báo bạn" = background upload with completion notice). Beta badge travels with the feature name everywhere.
- **Annotations:** none.

### AS02 · Giới thiệu (`479:7512`)
- **Purpose:** Intro / value-prop sheet before setup.
- **Copy:**
  - Close button (×), top-left
  - Illustration: phone library grid → dotted arc with spark → card `Kỷ niệm` (heart) `12/10 · Teddy`
  - Title: `Tự lưu kỷ niệm` + badge `Beta miễn phí`
  - Lead: `Đỡ công lục thư viện. Child Life tìm ảnh và video có thể có con, bạn xem lại rồi mới tải lên.`
  - Steps:
    1. `Chọn bé và vài ảnh rõ mặt` — `Giúp app gợi ý đúng hơn`
    2. `App tìm trong ảnh mới` — `Chỉ những ảnh bạn cho phép xem`
    3. `Bạn duyệt rồi mới tải` — `Không tự tải, không tự chia sẻ`
  - Footnote: `Gợi ý có thể sót hoặc nhầm, nhất là khi ảnh tối, nghiêng hay có nhiều bé. Bản beta miễn phí; tệp đã tải vẫn tính vào dung lượng của gia đình (3,2 / 10 GB).`
  - Primary button: `Bắt đầu thiết lập`
- **States / controls:** Close (×) dismisses; one primary CTA. Storage figure is live family usage (3,2 / 10 GB).
- **Behaviour implied:** Setup is 3 steps (choose baby + sample faces → photo permission → review). Scans only "ảnh mới" (new media) and only what the OS permission exposes. Nothing uploads or shares automatically — explicit review is mandatory. Matching is fallible (dark, tilted, multiple babies). Beta is free of charge, but uploaded files still count against the family storage quota (10 GB plan shown).
- **Annotations:** none.

### AS03 · Chọn bé (`479:7566`)
- **Purpose:** Step 1/3 — choose which baby(ies) to suggest photos for.
- **Copy:**
  - Back (‹)
  - Title: `Gợi ý ảnh của bé nào?`
  - Subtitle: `Bước 1/3 · Có thể thêm bé khác sau trong Cài đặt.`
  - Row (selected, mint border, checked): avatar `T` · `Teddy` · `3 tuần · Bạn là Mẹ`
  - Row (unchecked): avatar `N` · `Na` · `14 tháng · Bạn là Mẹ`
  - Disabled row (lock icon, grey): `Bin · bạn là Người chăm sóc nên không bật được tính năng này`
  - Primary button: `Tiếp`
- **States / controls:** Multi-select checkboxes (square check). Default: the current baby (Teddy) pre-checked; Na unchecked. Bin not selectable.
- **Behaviour implied:** Multiple babies can be enabled (checkbox, "Có thể thêm bé khác sau trong Cài đặt"). Eligibility is per-baby by the user's role: as Mẹ (parent) → allowed; as `Người chăm sóc` (caregiver) → feature cannot be enabled for that baby. Each row shows age + the user's role for that baby.
- **Annotations:** none.

### AS04 · Ảnh mẫu của bé (`479:7606`)
- **Purpose:** Step 2/3 — pick 3–5 reference face photos for the chosen baby.
- **Copy:**
  - Back (‹)
  - Title: `Chọn vài ảnh rõ mặt Teddy`
  - Subtitle: `Bước 2/3 · 3–5 ảnh nhìn rõ mặt, đủ sáng. Ảnh mẫu chỉ dùng để gợi ý, không hiện trong Kỷ niệm.`
  - Selected strip: 3 round thumbnails + dashed `+` slot
  - Caption: `3/5 ảnh mẫu · chọn từ Kỷ niệm đã có`
  - 4×3 grid of existing Kỷ niệm photos with selection circles (3 checked)
  - Link: `Hoặc chọn từ thư viện máy`
  - Primary button: `Tiếp · 3 ảnh mẫu`
- **States / controls:** 3 of 5 selected; min 3, max 5. Button label carries the count. Source defaults to existing Kỷ niệm media; device library is the alternative.
- **Behaviour implied:** Sample ("ảnh mẫu") photos are a separate artefact used only for matching; they never appear in the Kỷ niệm timeline. Samples can come from already-uploaded memories or from the device library. Guidance: clear face, good light.
- **Annotations:** none.

### AS05 · Giải thích quyền ảnh (`480:6879`)
- **Purpose:** Step 3/3 — pre-permission explainer for two separate consents (library read access; uploading approved items, with a background-upload toggle).
- **Copy:**
  - Back (‹)
  - Title: `Hai điều Child Life cần bạn đồng ý`
  - Subtitle: `Bước 3/3 · Đây là hai lựa chọn riêng, bạn đổi được bất cứ lúc nào trong Cài đặt.`
  - Card 1: `1` `Cho Child Life xem thư viện ảnh` · `Để tìm ảnh, video mới có thể có Teddy. App không xoá hay sửa gì trong thư viện.` · info strip (alert icon): `Bấm tiếp, điện thoại sẽ hỏi quyền. Bạn có thể cho xem tất cả hoặc chỉ ảnh được chọn.`
  - Card 2: `2` `Tải lên những mục bạn đã duyệt` · `Chỉ mục bạn bấm duyệt mới được tải lên Child Life. Tắt nền thì tải khi bạn đang mở app.` · toggle row `Tiếp tục tải khi app chạy nền`
  - Primary button: `Cho phép xem ảnh`
  - Text link: `Để sau · thêm ảnh thủ công`
- **States / controls:** Toggle `Tiếp tục tải khi app chạy nền` = **OFF** by default (grey track in render). Primary CTA triggers the OS photo-permission prompt.
- **Behaviour implied:** Library access is read-only ("không xoá hay sửa gì"). OS permission may be full or limited ("tất cả hoặc chỉ ảnh được chọn") — both are supported. Upload consent is separate from read consent; only approved items upload. Background upload is opt-in; when off, uploads only run while the app is in the foreground. Both choices are changeable later in Settings (AS19). "Để sau" exits setup and falls back to the existing manual add-photo flow (no permission requested).
- **Annotations:** none.

### AS06 · Đang kiểm tra ảnh mới (`480:6919`)
- **Purpose:** First scan in progress (feature home while scanning), with early results reviewable.
- **Copy:**
  - Back (‹) · settings icon (sliders) top-right
  - Title: `Tự lưu kỷ niệm`
  - Status card (search icon): `Đang kiểm tra ảnh mới` · `640 / 1.380 tệp · chưa tải gì lên` · progress bar · `Có thể tạm dừng khi bạn rời app; lần mở sau sẽ kiểm tra tiếp.`
  - Found card: `Đã tìm thấy 9 gợi ý` · 5 thumbnails · `Bạn có thể xem ngay, kiểm tra vẫn tiếp tục.`
  - Row (camera icon): `Ảnh và video` · `Kiểm tra cả hai · chỉ ảnh bạn cho phép xem`
  - Primary button: `Xem 9 gợi ý`
- **States / controls:** Scan progress 640/1,380 files (bar ≈ 46 %). 9 suggestions so far. Upload count = 0.
- **Behaviour implied:** Scanning is on-device, counted in files, and explicitly separate from uploading ("chưa tải gì lên"). Scan may pause when the user leaves the app and resumes on next open (resumable cursor). Results stream in; user can review before the scan ends. Media types scanned: photos and videos (both), limited to what permission exposes. Settings reachable from the sliders icon.
- **Annotations:** none.

### AS07 · Gợi ý chờ duyệt (`480:6971`)
- **Purpose:** Review grid of pending suggestions, grouped by capture day, with opt-out selection.
- **Copy:**
  - Back (‹)
  - Title: `Có thể có Teddy`
  - Subtitle: `18 gợi ý · kiểm tra lúc 9:12 hôm nay. Bỏ chọn những mục không muốn lưu.`
  - Filter chips: `Tất cả · 18` (selected) · `Ảnh · 15` · `Video · 3`
  - Day header: `Hôm nay · 12/10` — `6 mục`; grid (one video tile `▶ 0:24`)
  - Day header: `Hôm qua · 11/10` — `8 mục`; grid (video `▶ 1:12`; one dimmed tile tagged `Đã có` with no checkbox; one tile tagged `Trên iCloud`, unchecked)
  - Day header: `09/10` — `4 mục`; grid (video `▶ 0:41`)
  - Footnote: `"Đã có": tệp trùng với Kỷ niệm, sẽ không tải lại. "Trên iCloud": tệp gốc chưa có trong máy (iCloud/Google Photos), sẽ lấy về khi có mạng.`
  - Sticky footer summary (tappable): `Đã chọn 15 · 13 ảnh, 2 video` — `~ 186 MB`
  - Primary button: `Tiếp tục với 15 mục`
- **States / controls:** Items are **pre-selected** (opt-out). Counted in render: Hôm nay 5/6 checked, Hôm qua 6/8 checked (1 `Đã có` not selectable, 1 `Trên iCloud` unchecked), 09/10 4/4 → 15 selected. Filter `Tất cả` active. Estimated upload size shown (~186 MB). NB design inconsistency: all three video tiles render checked, yet the summary says `13 ảnh, 2 video`.
- **Behaviour implied:** Suggestions are grouped by capture date (newest first) and carry the last check time. Default = everything selected; user deselects. Duplicate detection: a library file that already exists in Kỷ niệm is tagged `Đã có`, dimmed, not selectable and never re-uploaded. Cloud-only originals (iCloud / Google Photos) are tagged `Trên iCloud` and are fetched when online (the Google Photos mention implies Android parity). Tapping a tile opens AS08 full view. CTA moves to AS10 confirmation.
- **Annotations:** none.

### AS08 · Xem lớn gợi ý (`482:6922`)
- **Purpose:** Full-screen viewer for one suggestion, with per-item select / reject and baby reassignment.
- **Copy:**
  - Close (×) · position/time `3 / 18 · Hôm nay 9:05` · selected check badge (top-right)
  - Bottom sheet row: `Gợi ý cho` `Teddy` … `Đổi` (chevron-down)
  - Buttons: `Không phải ảnh của bé` (secondary) · `✓ Đã chọn` (primary, selected state)
- **States / controls:** Dark viewer. Item is selected (check badge + `Đã chọn`). Pager position 3 of 18. Baby assignment = Teddy, changeable via `Đổi` (opens AS09).
- **Behaviour implied:** Swipe/page through all suggestions. `Đã chọn` toggles inclusion. `Không phải ảnh của bé` rejects the item (removes it from suggestions; per AS09 copy this also feeds future matching). Suggestion can be reassigned to another enabled baby.
- **Annotations:** none.

### AS09 · Ảnh này của ai? (`482:6952`)
- **Purpose:** Bottom sheet over the AS08 viewer to reassign a suggestion to another baby or reject it.
- **Copy:**
  - (Behind scrim: AS08 viewer, `3 / 18 · Hôm nay 9:05`, `Gợi ý cho` `Teddy` `Đổi`, `Không phải ảnh của bé`, `Đã chọn`)
  - Sheet title: `Ảnh này của ai?` · close (×)
  - Radio row (selected, mint): avatar `T` · `Teddy` · `Đang được gợi ý`
  - Radio row: avatar `N` · `Na`
  - Radio row (× icon): `Không phải ảnh của bé` · `Bỏ khỏi gợi ý · giúp lần sau gợi ý tốt hơn`
  - Primary button: `Xong`
- **States / controls:** Single-choice radio; default = the currently suggested baby (Teddy). Na is offered (so Na is an enabled baby in this scenario, or all babies the user parents are listed — unclear).
- **Behaviour implied:** One suggestion belongs to exactly one baby (radio, not multi). Reassigning moves it to the other baby's suggestion set / upload target. Rejecting removes it from suggestions and is used as negative feedback for future matching ("giúp lần sau gợi ý tốt hơn"). No option for "both babies" (twins/siblings in one photo).
- **Annotations:** none.

### AS10 · Xác nhận trước khi tải (`482:7011`)
- **Purpose:** Final confirmation of upload destination, audience and notification before uploading approved items.
- **Copy:**
  - Back (‹)
  - Title: `Kiểm tra trước khi tải`
  - Thumbnail strip: 6 thumbs + `+9`
  - Group rows:
    - `Nguồn` — `Thư viện ảnh trên máy · 15 mục (13 ảnh, 2 video)`
    - `Bé` — `Teddy` (chevron)
    - `Lưu vào` — `Dòng thời gian, theo ngày chụp · Album: không` (chevron)
  - Section label: `Ai thấy`
  - Visibility cards: `Chỉ ba mẹ` (lock) — `Mặc định cho Tự lưu` (selected) · `Gia đình` (family icon) — `Cả nhà cùng xem`
  - Toggle row: `Báo cho gia đình` — `Tắt · không gửi thông báo`
  - Storage card: `Dung lượng sau khi tải` — `3,4 / 10 GB` · bar
  - Primary button: `Tải lên 15 mục`
  - Footnote: `Ảnh gốc vẫn ở trong máy. Tải xong mới hiện "Đã lưu".`
- **States / controls:** Visibility default = **Chỉ ba mẹ** ("Mặc định cho Tự lưu"). `Báo cho gia đình` toggle = **OFF**. Album = none. Storage projection 3,4 / 10 GB (bar ≈ 34 %). Baby and Lưu vào rows are editable (chevrons).
- **Behaviour implied:** Auto-saved items are private to parents by default (stricter than manual default); family visibility is opt-in per batch. Family notification is off by default for Tự lưu batches. Items are placed on the timeline by capture date (not upload date), no album unless chosen. Storage impact is previewed before upload (current 3,2 GB + ~186 MB → 3,4 GB). Device originals are never deleted/moved. Items are only marked `Đã lưu` after the upload completes (no optimistic "saved").
- **Annotations:** none.

### AS11 · Hàng đợi tải lên (`482:7084`)
- **Purpose:** Upload queue detail with per-item states, near-full storage warning and Wi-Fi-only video setting.
- **Copy:**
  - Back (‹)
  - Title: `Đang tải lên`
  - Status card (upload icon): `5 / 15 đã lưu · từ Tự lưu kỷ niệm` · `Còn khoảng 3 phút · tiến độ tải, không phải tiến độ kiểm tra` · progress bar
  - Item rows:
    - `IMG_2101.HEIC` — `Đã lưu vào Kỷ niệm` (✓)
    - `IMG_2102.HEIC` — `Đang tải · 62% · 2,1/3,4 MB`
    - `IMG_2104.MOV` — `Chờ Wi-Fi · video 48 MB`
    - `IMG_2107.HEIC` — `Đang lấy tệp gốc từ iCloud`
    - `IMG_2110.HEIC` — `Mất kết nối khi đang tải` (error red) · button `Thử lại` (retry icon)
  - Warning banner (alert): `Gần đầy dung lượng: còn 220 MB. Mục chưa vừa sẽ giữ trên máy, không bị mất.` · link `Xem dung lượng`
  - Toggle row: `Video chỉ tải qua Wi-Fi` — `Theo cài đặt Tự lưu`
- **States / controls:** Overall 5/15 saved (bar ≈ 29 %), ETA ~3 min. Per-item states: saved / uploading with % and MB / waiting for Wi-Fi / fetching original from iCloud / failed with manual retry. `Video chỉ tải qua Wi-Fi` = **ON**.
- **Behaviour implied:** Upload progress is presented separately from scan progress. Per-file states listed above are the canonical queue states. Videos wait for Wi-Fi when the Wi-Fi-only setting is on (default on; mirrored from AS19). Cloud-only originals are downloaded before upload. Network failures are per-item with a manual `Thử lại`. When quota is nearly exhausted, items that don't fit stay queued on the device (not lost); user is pointed to storage. File names shown are device file names (filenames are child-related content → must not be logged).
- **Annotations:** none.

### AS12 · Tự lưu kỷ niệm · trang chính (`482:7153`)
- **Purpose:** Feature home (steady state) — last check, pending suggestions, upload status, history, manual add fallback.
- **Copy:**
  - Back (‹) · settings (sliders)
  - Title: `Tự lưu kỷ niệm` + badge `Beta miễn phí`
  - Status card (search icon): `Lần kiểm tra gần nhất: hôm nay 9:12` · `1.380 tệp mới · Teddy` · secondary button `Kiểm tra ảnh mới` · `App kiểm tra khi bạn mở và khi điện thoại cho phép chạy nền; thời điểm không cố định.`
  - Suggestions card: `18 gợi ý chờ duyệt` (chevron) · 5 thumbs · primary button `Duyệt gợi ý`
  - Group rows:
    - `Đang tải lên` — `10 mục · 1 chờ Wi-Fi · 1 lỗi` (chevron → AS11)
    - `Đã lưu từ Tự lưu` — `42 mục trong tháng 10` (chevron)
    - `Thêm ảnh thủ công` — `Chọn từ thư viện như trước` (chevron)
- **States / controls:** Manual `Kiểm tra ảnh mới` button available. Pending count 18. Upload summary 10 remaining, 1 waiting Wi-Fi, 1 error. Monthly saved count 42.
- **Behaviour implied:** Checks run on app open and opportunistically in background when the OS allows — no fixed schedule promised ("thời điểm không cố định"); user can force a check. Status shows per-baby new-file count. History of items saved via Tự lưu is tracked per month (provenance flag on memories). Manual add-photo flow remains unchanged and reachable from here.
- **Annotations:** none.

### AS13 · Quyền giới hạn (`483:7060`)
- **Purpose:** Feature home when the OS grants only limited photo access (iOS "Selected Photos" / Android partial access).
- **Copy:**
  - Back (‹) · settings (sliders)
  - Title: `Tự lưu kỷ niệm` + badge `Beta miễn phí`
  - Status card (lock icon on sunshine-soft): `Đang xem 120 ảnh bạn đã chọn` · `Child Life chỉ gợi ý trong những ảnh này · kiểm tra lúc 9:12` · secondary button `Chọn thêm ảnh` · link `Cho xem tất cả trong Cài đặt điện thoại`
  - Suggestions card: `4 gợi ý chờ duyệt` (chevron) · 5 thumbs · primary button `Duyệt gợi ý`
  - Group rows: `Đang tải lên` — `10 mục · 1 chờ Wi-Fi · 1 lỗi` · `Đã lưu từ Tự lưu` — `42 mục trong tháng 10` · `Thêm ảnh thủ công` — `Chọn từ thư viện như trước`
- **States / controls:** Limited access with 120 selected items; 4 pending suggestions. (Frame sits off-grid at x = −390 on the canvas, left of the row; content is a normal state.) NB: 5 thumbnails rendered for "4 gợi ý" — placeholder inconsistency.
- **Behaviour implied:** Limited permission is a supported, non-error state: the feature keeps working but only within the user-selected subset. `Chọn thêm ảnh` re-opens the OS limited-library picker; the link deep-links to OS Settings to grant full access. Status still shows last check time.
- **Annotations:** none.

### AS14 · Quyền bị từ chối (`483:7145`)
- **Purpose:** Feature home when photo permission is denied/revoked.
- **Copy:**
  - Back (‹) · settings (sliders)
  - Title: `Tự lưu kỷ niệm` + badge `Beta miễn phí`
  - Status card (lock icon on error-soft): `Child Life chưa được xem ảnh` · `Tự lưu đang tạm dừng. Kỷ niệm đã lưu không bị ảnh hưởng.` · primary button `Mở Cài đặt điện thoại`
  - Row: `Thêm ảnh thủ công` — `Chọn từ thư viện như trước`
- **States / controls:** Feature paused. Only manual-add row remains; no suggestion/upload/history rows.
- **Behaviour implied:** Denied permission pauses Tự lưu (it is not turned off/deleted); already-saved memories are unaffected. Only recovery path is OS Settings (the app cannot re-prompt once denied). Manual add remains available (manual picker on iOS works without library permission).
- **Annotations:** none.

### AS15 · Chưa có ảnh mẫu (`483:7222`)
- **Purpose:** Feature home when an enabled baby (Na) has no sample photos yet.
- **Copy:**
  - Back (‹) · settings (sliders)
  - Title: `Tự lưu kỷ niệm` + badge `Beta miễn phí`
  - Status card (camera icon on sunshine-soft): `Na chưa có ảnh mẫu` · `Thêm 3–5 ảnh rõ mặt để bắt đầu gợi ý ảnh của Na` · 4 dashed `+` slots · primary button `Thêm ảnh mẫu`
  - Group rows: `Đang tải lên` — `10 mục · 1 chờ Wi-Fi · 1 lỗi` · `Đã lưu từ Tự lưu` — `42 mục trong tháng 10` · `Thêm ảnh thủ công` — `Chọn từ thư viện như trước`
- **States / controls:** Na has 0 samples → suggestions for Na are inactive. (4 slots drawn though max is 5.)
- **Behaviour implied:** Matching per baby requires ≥3 samples; a baby enabled without samples shows this prompt instead of suggestions (AS19 calls it `Chưa có ảnh mẫu · tạm tắt`). Upload/history rows are shared across babies (not per-baby) — or the screen is scoped to the selected baby; unclear.
- **Annotations:** none.

### AS16 · Không có ảnh mới (`483:7315`)
- **Purpose:** Feature home after a check that found no matches.
- **Copy:**
  - Back (‹) · settings (sliders)
  - Title: `Tự lưu kỷ niệm` + badge `Beta miễn phí`
  - Status card (check icon on mint-soft): `Chưa có ảnh mới có thể có Teddy` · `Kiểm tra lúc 9:12 · 46 tệp mới từ lần trước` · secondary button `Kiểm tra ảnh mới`
  - Group rows: `Đang tải lên` — `10 mục · 1 chờ Wi-Fi · 1 lỗi` · `Đã lưu từ Tự lưu` — `42 mục trong tháng 10` · `Thêm ảnh thủ công` — `Chọn từ thư viện như trước`
- **States / controls:** 0 suggestions; suggestions card hidden. Manual re-check available.
- **Behaviour implied:** Incremental scanning — each check only looks at files added since the previous check ("46 tệp mới từ lần trước"). Empty result is a calm success state, not an error.
- **Annotations:** none.

### AS17 · Đang kiểm tra (trang chính) (`483:7394`)
- **Purpose:** Feature home while a check is running in the steady state (after onboarding), showing scan and upload progress side by side.
- **Copy:**
  - Back (‹) · settings (sliders)
  - Title: `Tự lưu kỷ niệm` + badge `Beta miễn phí`
  - Status card (search icon): `Đang kiểm tra ảnh mới` · `640 / 1.380 tệp · tiến độ kiểm tra` · progress bar · `Tách riêng với tiến độ tải lên bên dưới.`
  - Suggestions card: `9 gợi ý chờ duyệt · đang tìm thêm` (chevron) · 5 thumbs · primary button `Duyệt gợi ý`
  - Group rows: `Đang tải lên` — `10 mục · 1 chờ Wi-Fi · 1 lỗi` · `Đã lưu từ Tự lưu` — `42 mục trong tháng 10` · `Thêm ảnh thủ công` — `Chọn từ thư viện như trước`
- **States / controls:** Scan 640/1,380 (≈ 46 %). 9 suggestions, still growing. Upload queue active concurrently. No `Kiểm tra ảnh mới` button while a check runs.
- **Behaviour implied:** Scan and upload are independent pipelines that can run concurrently, each with its own progress label (scan = files checked; upload = items saved). Review is allowed while scanning ("đang tìm thêm").
- **Annotations:** none.

### AS18 · Không đủ dung lượng (`483:54740`)
- **Purpose:** AS10 confirmation variant when the family storage quota cannot fit the batch.
- **Copy:**
  - Back (‹)
  - Title: `Kiểm tra trước khi tải`
  - Thumbnail strip: 6 thumbs + `+9`
  - Rows: `Nguồn` — `Thư viện ảnh trên máy · 15 mục (13 ảnh, 2 video)` · `Bé` — `Teddy` · `Lưu vào` — `Dòng thời gian, theo ngày chụp · Album: không`
  - `Ai thấy`: `Chỉ ba mẹ` — `Mặc định cho Tự lưu` (selected) · `Gia đình` — `Cả nhà cùng xem`
  - Toggle row: `Báo cho gia đình` — `Tắt · không gửi thông báo`
  - Error banner (alert): `Không đủ dung lượng: 15 mục cần 186 MB, gia đình còn 40 MB. Bạn có thể tải trước 3 ảnh vừa đủ, phần còn lại vẫn giữ trên máy.` · link `Xem dung lượng`
  - Storage card: `Dung lượng sau khi tải` — `9,96 / 10 GB` · bar in error red
  - Primary button: `Tải trước 3 ảnh vừa đủ`
  - Footnote: `Mục chưa tải vẫn ở trong máy và trong danh sách gợi ý.`
- **States / controls:** Visibility still `Chỉ ba mẹ`; notify OFF. Storage projection 9,96/10 GB (bar ≈ 96 %, red). CTA changes from "Tải lên 15 mục" to a partial upload of the subset that fits.
- **Behaviour implied:** Pre-flight quota check: if the batch exceeds remaining family quota, offer to upload the largest prefix that fits (here 3 photos) rather than block. Items that don't fit stay in the device and remain in the pending suggestion list (not dismissed). Quota is family-wide (10 GB shown). Link to storage management.
- **Annotations:** none.

### AS19 · Cài đặt Tự lưu kỷ niệm (`483:54819`)
- **Purpose:** Settings for the feature: master switch, media types, network, background, notifications, per-baby samples, last status, permission, data deletion.
- **Copy:**
  - Back (‹)
  - Title: `Cài đặt Tự lưu`
  - Row (spark icon): `Tự lưu kỷ niệm` — `Đang bật · Beta miễn phí` · toggle
  - Section: `Tìm trong`
    - `Ảnh` · toggle
    - `Video` — `Video lớn tốn nhiều dung lượng` · toggle
    - `Chỉ tải qua Wi-Fi` — `Áp dụng cho mục đã duyệt` · toggle
    - `Tiếp tục tải khi app chạy nền` · toggle
    - `Báo khi có ảnh mới` — `Tối đa 1 lần/ngày · không báo trong giờ yên lặng` · toggle
  - Section: `Bé & ảnh mẫu`
    - `T` `Teddy` — `3 ảnh mẫu · đang gợi ý` · stacked sample thumbs · chevron
    - `N` `Na` — `Chưa có ảnh mẫu · tạm tắt` · chevron
    - `+` `Thêm bé` · chevron
  - Section: `Trạng thái gần nhất`
    - `Kiểm tra` — `Hôm nay 9:12 · 1.380 tệp · 18 gợi ý`
    - `Tải lên` — `Hôm nay 9:30 · 5 đã lưu, 1 chờ Wi-Fi, 1 lỗi` · chevron
    - `Quyền xem ảnh` — `Toàn bộ thư viện` · chevron
  - Info banner (lock): `Tắt Tự lưu không xoá kỷ niệm đã lưu. App chỉ ngừng tìm và gợi ý ảnh mới.`
  - Destructive link (red): `Xoá ảnh mẫu và dữ liệu gợi ý`
- **States / controls (render):** `Tự lưu kỷ niệm` **ON**; `Ảnh` **ON**; `Video` **ON**; `Chỉ tải qua Wi-Fi` **ON**; `Tiếp tục tải khi app chạy nền` **OFF**; `Báo khi có ảnh mới` **ON**. Teddy active with 3 samples; Na enabled but paused (no samples). Permission = full library.
- **Behaviour implied:** Master switch is reversible and non-destructive (turning off stops scanning/suggesting only; saved memories stay). Media type scope per type (photo / video). Wi-Fi-only applies to approved uploads (AS11 copy narrows it to videos — inconsistency). Background upload default off (matches AS05). New-photo notification: at most once per day and never during quiet hours (reuses app-wide quiet hours). Per-baby sample management; a baby without samples is "tạm tắt" (paused, not removed). `Thêm bé` adds another eligible baby. Separate destructive action deletes sample photos + suggestion data (face references / match cache) — distinct from turning the feature off; does not mention deleting saved memories. Permission row deep-links to OS settings / shows current scope ("Toàn bộ thư viện" vs limited).
- **Annotations:** none.

### AS20 · Tương lai · Tự tải vào vùng riêng tư (`483:54919`)
- **Purpose:** Explicitly out-of-scope concept: auto-upload matches into a private staging area before review.
- **Copy:**
  - Dark pill: `Ý tưởng tương lai · chưa thuộc bản beta đầu`
  - Back (‹)
  - Title: `Tự tải vào vùng riêng tư`
  - Lead: `Gợi ý có Teddy được tải thẳng vào một khu riêng chỉ bạn thấy. Bạn duyệt sau, rồi mới chuyển vào Kỷ niệm.`
  - Card (lock): `Chờ bạn duyệt · 12 mục` · 5 thumbs · `Không ai khác thấy · không tính là kỷ niệm cho đến khi bạn chuyển`
  - Toggle row: `Tự tải vào vùng riêng tư` — `Mặc định tắt · chỉ bật khi bạn đồng ý`
  - Warning banner (alert): `Cần thêm: quyền chạy nền, quy tắc dung lượng riêng và cách xoá tự động mục không duyệt. Đánh giá sau khi có dữ liệu beta.`
- **States / controls:** Toggle **OFF** (default off, opt-in only).
- **Behaviour implied:** NOT in the first beta. Future idea: pre-upload to a user-only private area, then promote to Kỷ niệm on approval. Pending prerequisites named by the design: background-run permission, a separate storage-quota rule, and auto-deletion of unreviewed items. To be evaluated with beta data. First beta therefore = review-before-upload only.
- **Annotations:** none (the pill + banner act as an in-frame note).

### AS07N · Gợi ý chờ duyệt · Night care (`483:54960`) — screenshot only
- Same copy, counts, chip states and selection as AS07 (`Có thể có Teddy`, `18 gợi ý · kiểm tra lúc 9:12 hôm nay. Bỏ chọn những mục không muốn lưu.`, `Tất cả · 18` / `Ảnh · 15` / `Video · 3`, day groups 6 / 8 / 4, footnote, `Đã chọn 15 · 13 ảnh, 2 video` · `~ 186 MB`, `Tiếp tục với 15 mục`).
- Differences: dark background/surfaces; selected filter chip becomes light (pale mint fill, dark text) instead of dark ink; primary CTA is bright mint with dark ink label; selection badges are bright mint. The `Đã có` tile renders as a dimmed dark tile whose tag pill reads as a blank grey lozenge (label not legible at night — contrast to verify); `Trên iCloud` keeps the sunshine tag.

### AS12N · Tự lưu kỷ niệm · trang chính · Night care (`483:55087`) — screenshot only
- Same copy and data as AS12 (`Lần kiểm tra gần nhất: hôm nay 9:12`, `1.380 tệp mới · Teddy`, `Kiểm tra ảnh mới`, `App kiểm tra khi bạn mở và khi điện thoại cho phép chạy nền; thời điểm không cố định.`, `18 gợi ý chờ duyệt`, `Duyệt gợi ý`, `Đang tải lên` — `10 mục · 1 chờ Wi-Fi · 1 lỗi`, `Đã lưu từ Tự lưu` — `42 mục trong tháng 10`, `Thêm ảnh thủ công` — `Chọn từ thư viện như trước`).
- Differences: dark theme; `Beta miễn phí` badge keeps the sunshine fill; primary `Duyệt gợi ý` is bright mint with dark label; secondary button and icon tiles use dark-teal surfaces. No layout or copy change.

---

## Row "AS · Lần mở app sau · tự kiểm tra & báo duyệt" (label `486:7158`)

### AR01 · Mở app · kiểm tra im lặng (`486:7159`)
- **Purpose:** Next app open (Today tab): the check runs silently; nothing about Tự lưu is shown yet.
- **Copy:** Standard Today screen — `M` · `Teddy · 3 tuần` · `Đêm` (night toggle) · `Thứ Năm, 8 tháng 10` · `Hôm nay` · `Tuỳ chỉnh`; care tiles `Bú bình` `120 ml` `45 phút trước` `Mẹ ghi` · `Bú mẹ` `15 phút` `3 giờ 35 phút trước` `Mẹ ghi` · `Giấc ngủ` `Đã thức 2 giờ` `Dậy lúc 13:05` `Ba ghi` · `Thay tã` `Tã ướt` `1 giờ 25 phút trước` `Cô Lan ghi` · `Hút sữa` `90 ml` `2 giờ trước` `Mẹ ghi` · `Tăng trưởng` `4,3 kg` `54,5 cm` `Đo hôm nay`; reminder peek `Nhắc nhở · 3 đang bật` `Tiêm mũi 6 trong 1` `Thứ Bảy 08:30 · còn 2 ngày`; `Nhịp hôm nay` · `Xem lịch sử`; `Tổng đã ghi` `Bú bình` `2 cữ · 240 ml` · `Bú mẹ` `1 cữ · 15 phút` · `Ngủ` `7 giờ 50` · `Thay tã` `2 lần`; axis `0h` `6h` `12h` `18h` `24h`; legend `Ngủ` `Bú bình` `Bú mẹ` `Tã`; tab bar `Hôm nay` (active) · `Kỷ niệm` · `Chăm sóc` · `Tiện ích` · `+`.
- **States / controls:** No banner, no badge, no spinner, no progress indicator for the scan.
- **Behaviour implied:** On app open the incremental check runs in the background with **no UI** ("im lặng") — it must not block or decorate Today until it has results.
- **Annotations (verbatim, frame-level, inherited from the base Today frame, not specific to Tự lưu):** `Thẻ lớn = vừa ghi vừa xem: chạm thẻ → mở sheet ghi mục đó (1 chạm); dòng dưới là lần cuối (bao lâu trước · chi tiết · ai ghi). Ngủ khi timer chạy → CareTile Tone=Active hiện thời gian đang chạy. Tăng trưởng: hàng riêng, + mở màn nhập số đo. “Lịch sử” → dòng thời gian.`

### AR02 · Hôm nay · có ảnh mới chờ duyệt (`486:7227`)
- **Purpose:** Today tab after the silent check found matches: an in-app banner + a dot badge on the Kỷ niệm tab.
- **Copy:**
  - Header/title as AR01 (`M`, `Teddy · 3 tuần`, `Đêm`, `Thứ Năm, 8 tháng 10`, `Hôm nay`, `Tuỳ chỉnh`)
  - Banner (sunshine-soft, 3 stacked thumbs, close ×): `8 ảnh mới có thể có Teddy` · `Từ thư viện máy · chưa tải lên` · buttons `Xem & chọn ảnh` (primary) · `Để sau` (secondary)
  - Rest of Today identical to AR01 (care tiles, reminder peek, rhythm, tab bar)
  - Dot badge on the `Kỷ niệm` tab icon
- **States / controls:** Banner dismissible (× and `Để sau`). Kỷ niệm tab shows an unread dot.
- **Behaviour implied:** When a check finds new suggestions, Today shows a single banner above the care tiles (placed under the title, above tiles) stating the count, baby name, source and that nothing has been uploaded. `Xem & chọn ảnh` opens review (AR05 quick review / AS07). `Để sau` / × hides the banner without discarding suggestions; the Kỷ niệm tab dot persists as a reminder (AR04). Banner is per baby currently selected in the switcher.
- **Annotations (verbatim, inherited Today annotation):** same text as AR01.

### AR03 · Thông báo khi app chạy nền (`486:7372`)
- **Purpose:** System push notification (lock screen) when a background check found new matches.
- **Copy:**
  - Lock screen: `Thứ Bảy, 18 tháng 10` · `9:41`
  - Notification: app icon · `Child Life` · `bây giờ` · title `Có 8 ảnh mới có thể có Teddy` · body `Chạm để xem và chọn ảnh muốn lưu vào Kỷ niệm.`
  - Design tag (dark pill, bottom of frame): `Thông báo hệ thống · tối đa 1 lần/ngày, không gửi trong giờ yên lặng`
- **States / controls:** Tap = open app to review.
- **Behaviour implied:** When the OS lets the app run a background check and it finds matches, send at most one local/system notification per day, never during quiet hours (consistent with AS19 `Báo khi có ảnh mới`, which can be switched off). Copy contains the baby's first name and a count — no image thumbnail in the notification. Tapping deep-links to the review (AR05 sheet or AS07). NB date shown (Sat 18/10) differs from the Today frames (Thu 8/10) — mock data only.
- **Annotations:** the in-frame tag above (no `data-annotations`).

### AR04 · Kỷ niệm · có gợi ý mới (`486:7391`)
- **Purpose:** Kỷ niệm tab when suggestions are pending: the entry card becomes highlighted with a count and a `Duyệt` action.
- **Copy:**
  - Header: `M` · `Teddy · 3 tuần` · sliders · `+`
  - Title `Kỷ niệm` · chips `Dòng thời gian` (selected) · `Ảnh & video`
  - Entry card (sunshine-soft fill, spark icon): `Tự lưu kỷ niệm` + badge `Beta miễn phí` · subtitle `8 ảnh mới chờ duyệt · kiểm tra lúc 9:12` · pill button `Duyệt`
  - Upload pill: `Đang tải 4/7 mục` · `Cứ làm việc khác, xong sẽ báo bạn`
  - Timeline identical to AS01 (`Tuần thứ 3` · `1 – 8 tháng 10 · 13 ảnh, 3 video` … `Tuần thứ 2` · `24 – 30 tháng 9 · 6 ảnh` …)
  - Tab bar: `Hôm nay` · `Kỷ niệm` (active) · `Chăm sóc` · `Tiện ích`
- **States / controls:** Entry card switches from neutral (AS01: white, chevron, `Gợi ý ảnh, video có Teddy từ thư viện máy`) to highlighted (sunshine fill, count + last check time, `Duyệt` button) when there are pending suggestions.
- **Behaviour implied:** The Kỷ niệm entry card is the persistent home of pending suggestions (the Today banner is transient). `Duyệt` opens review. Pending suggestions are never auto-inserted into the timeline.
- **Annotations:** none.

### AR05 · Duyệt nhanh (`486:55233`)
- **Purpose:** Quick-review bottom sheet over Today (from the banner's `Xem & chọn ảnh` or the notification), using saved defaults.
- **Copy:**
  - Background: AR02 (Today with banner `8 ảnh mới có thể có Teddy` / `Từ thư viện máy · chưa tải lên` / `Xem & chọn ảnh` / `Để sau`; Kỷ niệm tab badge) under scrim
  - Sheet title: `8 ảnh mới có thể có Teddy` · close (×)
  - Subtitle: `Chụp từ 15–18/10 · bỏ chọn ảnh không muốn lưu`
  - 4×2 grid with selection badges (one video `▶ 0:18`)
  - Defaults row (lock icon): `Dòng thời gian · Chỉ ba mẹ` · `Không báo cho gia đình` · link `Đổi`
  - Primary button: `Tải lên 7 mục`
  - Links: `Xem lớn từng ảnh` (left) · `Bỏ qua lần này` (right, muted)
- **States / controls:** 7 of 8 pre-selected (one deselected). Defaults summary = timeline, parents-only, no family notification. Button count follows selection.
- **Behaviour implied:** Fast path: review and upload in one sheet without going through AS07/AS10. Opt-out selection (all pre-checked). The AS10 defaults are summarised in one row and editable via `Đổi`. `Xem lớn từng ảnh` opens the AS08 viewer. `Bỏ qua lần này` dismisses this batch (see AR08). Range label is capture-date range of the batch.
- **Annotations (verbatim, inherited Today annotation):** same text as AR01.

### AR06 · Đang tải sau khi duyệt (`486:55349`)
- **Purpose:** Today after approving: banner gone, a toast shows upload progress.
- **Copy:**
  - Today as AR01 (no banner); tab bar without badge
  - Toast (dark ink, bottom above tab bar): `Đang tải 7 mục lên Kỷ niệm · 3/7` · progress bar · `Xem`
- **States / controls:** Progress 3/7 (bar ≈ 41 %). `Xem` opens the upload queue (AS11).
- **Behaviour implied:** After approval the banner is removed and the Kỷ niệm badge cleared; upload continues while the user uses the app, with non-blocking progress feedback.
- **Annotations (verbatim, inherited Today annotation):** same text as AR01.

### AR07 · Đã lưu xong (`486:55603`)
- **Purpose:** Today after the approved batch finished uploading: success toast.
- **Copy:**
  - Today as AR01 (no banner, no badge)
  - Toast (dark ink, check icon on mint circle): `Đã lưu 7 mục vào Kỷ niệm của Teddy` · `Xem`
- **States / controls:** `Xem` opens the saved items in Kỷ niệm.
- **Behaviour implied:** Completion is confirmed in-app with the count and baby name; this is the "xong sẽ báo bạn" promise from the upload pill. (Whether a system notification is also sent when the app is in background is not shown.)
- **Annotations (verbatim, inherited Today annotation):** same text as AR01.

### AR08 · Bỏ qua lần này (`486:55858`)
- **Purpose:** Today after the user chose `Bỏ qua lần này` in the quick-review sheet.
- **Copy:**
  - Today as AR01 (banner gone)
  - Toast (dark ink): `Đã bỏ qua 8 ảnh · sẽ không gợi ý lại` · `Hoàn tác`
- **States / controls:** Undo available (`Hoàn tác`) on the toast only.
- **Behaviour implied:** `Bỏ qua lần này` dismisses the **whole batch** (all 8, regardless of the 7 that were selected) and those files are **never suggested again**; nothing is uploaded; the feature keeps running for future photos. Undo restores the batch to pending. Contrast: banner `Để sau` / × only defers (items stay pending, Kỷ niệm card still shows them).
- **Annotations (verbatim, inherited Today annotation):** same text as AR01.

### Row boundary check
- AR08 (`486:55858`, x 2905, y 29750) is the last frame of the AR row and the last top-level node on page `345:35701` (XML ends right after it). No AR09+ frames.
- No sticky notes, connectors, or free-standing text/annotation nodes exist near either row; the only top-level text nodes are the two row labels (`479:7357` `Label · AS · Tự lưu kỷ niệm · Beta miễn phí`, `486:7158` `Label · AS · Lần mở app sau · tự kiểm tra & báo duyệt`).
- Layout quirk: AS13 `483:7060` sits at x = −390, y = 28788 (left of the second AS line, which otherwise starts at x = 415, y = 28700); AS07N/AS12N sit at the end of the second AS line (x 3320 / 3735).
- Only `data-annotations` found: the generic Today-screen annotation on AR01, AR02, AR05, AR06, AR07, AR08 (inherited from the base Today frame; not about Tự lưu). In-frame design notes: AR03 bottom tag and AS20 pill + banner.

---

## Cross-screen rules

1. **Name and beta label.** The feature is `Tự lưu kỷ niệm`. Every entry point carries the badge `Beta miễn phí` (Kỷ niệm card, intro, feature home, Settings row `Đang bật · Beta miễn phí`). The beta is free, but uploads still count against the family quota: `tệp đã tải vẫn tính vào dung lượng của gia đình (3,2 / 10 GB)`.
2. **Entry point.** A card on the Kỷ niệm timeline sits under the view chips and above the upload pill. Neutral state: `Gợi ý ảnh, video có {bé} từ thư viện máy` + chevron. Pending state (sunshine fill): `{n} ảnh mới chờ duyệt · kiểm tra lúc {hh:mm}` + `Duyệt` button. The feature home's back button returns to Kỷ niệm.
3. **Setup flow.** AS02 intro → AS03 `Bước 1/3` choose baby → AS04 `Bước 2/3` sample photos → AS05 `Bước 3/3` consents → OS permission prompt → AS06 first scan. Escapes: × on the intro, and `Để sau · thêm ảnh thủ công` on step 3 (falls back to the manual add flow).
4. **Eligibility is per baby and depends on the user's role.** A parent (`Bạn là Mẹ`) can turn it on. A caregiver cannot: `Bin · bạn là Người chăm sóc nên không bật được tính năng này`. More than one baby can be on at once (checkboxes), and more can be added later (`Có thể thêm bé khác sau trong Cài đặt.`, `Thêm bé`). The pre-selected baby is the one currently chosen in the switcher.
5. **Sample photos (ảnh mẫu).**
   - Each baby needs 3–5 photos with a clear face and good light (`3–5 ảnh nhìn rõ mặt, đủ sáng`). They can come from existing Kỷ niệm (the default) or from the device library.
   - Samples are only used for matching: `Ảnh mẫu chỉ dùng để gợi ý, không hiện trong Kỷ niệm.`
   - A baby with 0 samples is paused (`Chưa có ảnh mẫu · tạm tắt`) and the feature home shows the AS15 prompt instead.
   - Samples and suggestion data can be deleted on their own (`Xoá ảnh mẫu và dữ liệu gợi ý`).
6. **Two separate consents** (`Đây là hai lựa chọn riêng, bạn đổi được bất cứ lúc nào trong Cài đặt.`):
   - (a) read access to the library, through the OS prompt. Full or limited access both work: `cho xem tất cả hoặc chỉ ảnh được chọn`.
   - (b) uploading approved items.
   - Background upload `Tiếp tục tải khi app chạy nền` is **OFF by default**. With it off, uploads only run while the app is open (`Tắt nền thì tải khi bạn đang mở app.`).
7. **The library is read-only.** `App không xoá hay sửa gì trong thư viện.`; `Ảnh gốc vẫn ở trong máy.`
8. **Nothing uploads or shares without explicit approval.** `Bạn duyệt rồi mới tải — Không tự tải, không tự chia sẻ`; `Chỉ mục bạn bấm duyệt mới được tải lên Child Life.` Auto-upload into a private area (AS20) is explicitly out of the first beta: `Ý tưởng tương lai · chưa thuộc bản beta đầu`.
9. **When it scans.**
   - Triggers: on app open, plus in the background whenever the OS allows. No fixed time: `App kiểm tra khi bạn mở và khi điện thoại cho phép chạy nền; thời điểm không cố định.` A manual `Kiểm tra ảnh mới` is also available.
   - Incremental: each check only looks at files added since the previous one (`46 tệp mới từ lần trước`).
   - Resumable: `Có thể tạm dừng khi bạn rời app; lần mở sau sẽ kiểm tra tiếp.`
   - Silent on app open: no UI until there are results (AR01).
   - Results stream in, so the user can review mid-scan (`Bạn có thể xem ngay, kiểm tra vẫn tiếp tục.`, `· đang tìm thêm`).
   - Scanning uploads nothing (`chưa tải gì lên`). This implies on-device matching.
10. **Scan progress and upload progress are separate and labelled as such.** Scan: `640 / 1.380 tệp · tiến độ kiểm tra` / `Tách riêng với tiến độ tải lên bên dưới.` Upload: `tiến độ tải, không phải tiến độ kiểm tra`.
11. **Media types.** Photos and videos are both scanned by default (`Kiểm tra cả hai`), with a toggle for each in Settings (both ON). Videos carry a warning: `Video lớn tốn nhiều dung lượng`.
12. **Review grid.**
    - Title `Có thể có {bé}`.
    - Grouped by capture day, newest first (`Hôm nay · 12/10`, `Hôm qua · 11/10`, `09/10`), each with an item count.
    - Filters `Tất cả · n` / `Ảnh · n` / `Video · n`.
    - Selection is **opt-out**: everything starts selected (`Bỏ chọn những mục không muốn lưu.`).
    - A sticky summary shows `Đã chọn {n} · {a} ảnh, {v} video` and an estimated size `~ 186 MB`. The CTA is `Tiếp tục với {n} mục`.
13. **Dedupe.** A library file that already exists in Kỷ niệm is tagged `Đã có`, dimmed, and can't be selected: `"Đã có": tệp trùng với Kỷ niệm, sẽ không tải lại.`
14. **Cloud-only originals.** These are tagged `Trên iCloud`: `tệp gốc chưa có trong máy (iCloud/Google Photos), sẽ lấy về khi có mạng`. Their queue state is `Đang lấy tệp gốc từ iCloud`. In the render this tile is unselected; whether that is the default is unclear.
15. **Per-item correction.**
    - The full-screen viewer (`{i} / {n} · {ngày giờ}`) offers `Đã chọn` (toggle), `Không phải ảnh của bé`, and `Gợi ý cho {bé} · Đổi`.
    - The `Ảnh này của ai?` sheet is single-choice: one baby, or `Không phải ảnh của bé — Bỏ khỏi gợi ý · giúp lần sau gợi ý tốt hơn`. Rejection feeds back into matching.
16. **Upload defaults (confirmation screen and quick sheet).**
    - `Lưu vào`: `Dòng thời gian, theo ngày chụp · Album: không`.
    - `Ai thấy`: **`Chỉ ba mẹ` — `Mặc định cho Tự lưu`**. The alternative is `Gia đình — Cả nhà cùng xem`.
    - `Báo cho gia đình`: **OFF** (`Tắt · không gửi thông báo`).
    - The storage projection (`Dung lượng sau khi tải`) is shown before upload.
    - Quick-sheet summary: `Dòng thời gian · Chỉ ba mẹ` / `Không báo cho gia đình` / `Đổi`.
17. **"Saved" means confirmed.** `Tải xong mới hiện "Đã lưu".` Items are dated by capture date.
18. **Upload queue states:**
    - `Đã lưu vào Kỷ niệm`
    - `Đang tải · {p}% · {x}/{y} MB`
    - `Chờ Wi-Fi · video {n} MB`
    - `Đang lấy tệp gốc từ iCloud`
    - `Mất kết nối khi đang tải` + `Thử lại` (manual retry)
    - Overall progress is shown as `{x} / {n} đã lưu · từ Tự lưu kỷ niệm` + ETA `Còn khoảng 3 phút`.
19. **Wi-Fi.** `Chỉ tải qua Wi-Fi` is **ON by default**, but the scope conflicts between screens: Settings says `Áp dụng cho mục đã duyệt` (all approved items), while the queue says `Video chỉ tải qua Wi-Fi · Theo cài đặt Tự lưu` and photos upload anyway.
20. **Storage.**
    - Nearly full: `Gần đầy dung lượng: còn 220 MB. Mục chưa vừa sẽ giữ trên máy, không bị mất.` + `Xem dung lượng`.
    - Not enough space (pre-flight check): `Không đủ dung lượng: 15 mục cần 186 MB, gia đình còn 40 MB. Bạn có thể tải trước 3 ảnh vừa đủ, phần còn lại vẫn giữ trên máy.` The CTA becomes `Tải trước 3 ảnh vừa đủ`, with `Mục chưa tải vẫn ở trong máy và trong danh sách gợi ý.`
21. **Permission states.**
    - Limited: a supported, normal state. Suggestions only come from the selected subset (`Đang xem 120 ảnh bạn đã chọn` / `Child Life chỉ gợi ý trong những ảnh này`), with `Chọn thêm ảnh` and `Cho xem tất cả trong Cài đặt điện thoại`.
    - Denied: `Child Life chưa được xem ảnh` / `Tự lưu đang tạm dừng. Kỷ niệm đã lưu không bị ảnh hưởng.` + `Mở Cài đặt điện thoại`. Only manual add remains.
22. **Manual add is always available.** `Thêm ảnh thủ công — Chọn từ thư viện như trước` appears on every feature-home state.
23. **Nudges after a background or silent check finds matches:**
    - (a) Today banner `{n} ảnh mới có thể có {bé}` / `Từ thư viện máy · chưa tải lên` with `Xem & chọn ảnh` / `Để sau` / ×.
    - (b) a dot badge on the Kỷ niệm tab.
    - (c) the highlighted Kỷ niệm card.
    - (d) a system push `Có {n} ảnh mới có thể có {bé}` / `Chạm để xem và chọn ảnh muốn lưu vào Kỷ niệm.` Its limits: **at most 1 per day, never during quiet hours** (`Tối đa 1 lần/ngày · không báo trong giờ yên lặng`). It can be turned off with `Báo khi có ảnh mới` (default **ON**).
24. **Quick review (bottom sheet over Today).**
    - Title `{n} ảnh mới có thể có {bé}`, subtitle `Chụp từ {d1}–{d2} · bỏ chọn ảnh không muốn lưu`.
    - Pre-selected grid, the defaults row, and the CTA `Tải lên {k} mục`.
    - Links `Xem lớn từng ảnh` and `Bỏ qua lần này`.
25. **Defer vs skip.**
    - `Để sau` / × only hides the banner; the items stay pending.
    - `Bỏ qua lần này` drops the whole batch for good: `Đã bỏ qua 8 ảnh · sẽ không gợi ý lại`, with `Hoàn tác` (undo) on the toast.
26. **Upload feedback.**
    - Kỷ niệm upload pill: `Đang tải {x}/{n} mục` / `Cứ làm việc khác, xong sẽ báo bạn`.
    - Today toast: `Đang tải {n} mục lên Kỷ niệm · {x}/{n}` + `Xem`.
    - Completion toast: `Đã lưu {n} mục vào Kỷ niệm của {bé}` + `Xem`.
27. **Turning the feature off is non-destructive.** `Tắt Tự lưu không xoá kỷ niệm đã lưu. App chỉ ngừng tìm và gợi ý ảnh mới.` Deleting samples and suggestion data is a separate, destructive action (red).
28. **Provenance.** Items saved through the feature are counted separately (`Đã lưu từ Tự lưu · 42 mục trong tháng 10`), so memories need a source flag.
29. **Status in Settings.**
    - `Kiểm tra — Hôm nay 9:12 · 1.380 tệp · 18 gợi ý`
    - `Tải lên — Hôm nay 9:30 · 5 đã lưu, 1 chờ Wi-Fi, 1 lỗi`
    - `Quyền xem ảnh — Toàn bộ thư viện`
30. **Honest expectations.** `Gợi ý có thể sót hoặc nhầm, nhất là khi ảnh tối, nghiêng hay có nhiều bé.` Suggestion wording is always hedged: `có thể có {bé}`.
31. **Privacy (implementation, per CLAUDE.md).** Sample photos, face templates and embeddings, device filenames (`IMG_2101.HEIC`), counts tied to a baby name, and suggestion sets are child data. None of it may go into logs, analytics or crash keys. Notification text holds only the name and a count.
32. **Night care.** Same copy and layout. Dark surfaces; the primary CTA becomes bright mint with a dark label; the beta badge keeps its sunshine fill. Check legibility of the `Đã có` tag in dark mode.
33. **Future (not V1 beta), AS20.** Auto-upload of matches into a private area visible only to the user (`Không ai khác thấy · không tính là kỷ niệm cho đến khi bạn chuyển`), default OFF and opt-in. Its prerequisites are named in the design: background permission, a separate storage rule, and auto-deletion of unreviewed items. To be evaluated on beta data.

## Open questions

1. **Beta lifecycle.** How long does `Beta miễn phí` last? Who gets it: everyone, opt-in, or flag-gated via `config/flags`? What happens when it ends (paid tier? feature switched off?), and what happens to samples, pending suggestions and settings at that point? Do items already saved stay? (Presumably yes, per the AS19 banner.)
2. **Where matching runs.** The copy implies on-device (`chưa tải gì lên`), but this isn't stated. Are sample photos or face templates ever uploaded or synced? Where are they stored and how are they deleted? A child's face template is biometric, sensitive personal data, so a legal/consent review is needed (Vietnam's personal-data decree), along with a decision on whether it falls under the existing privacy policy.
3. **Android parity.** Only the mention of `Google Photos` hints at Android; the tags still say `Trên iCloud`. We need: Android copy for cloud-only items; Android 14 partial media access (the equivalent of AS13); background scheduling (WorkManager vs iOS BGTask); notification channel; and the Settings deep link.
4. **Video handling.** Is a video matched by sampling frames? Are there max duration/size limits, and do they reuse the existing upload limits in `config/limits`? Does Wi-Fi-only apply to videos only (AS11) or to all approved items (AS19)?
5. **Roles.** The design only shows Mẹ = allowed and Người chăm sóc = blocked. What about Ba (presumably allowed) and Ông/Bà or other relatives with upload rights? Is the rule "parents only", matching the `Chỉ ba mẹ` default audience? Can a caregiver see items that Tự lưu uploaded with Gia đình visibility?
6. **Multi-device and two parents.**
   - Are settings, samples and the scan cursor per device or per account?
   - If both parents turn it on, do suggestions sync between them, and is `Đã có` dedupe family-wide (content hash) or per device/asset id?
   - Can the same photo from two phones be uploaded twice?
7. **Backlog scope of the first scan.** "Ảnh mới" plus the first scan of 1,380 files: does the first scan cover the whole library, files since the baby's birth date, the last N days, or only files from enablement onward?
8. **Multiple babies in one photo.** The AS09 sheet is single-choice. How do twins/siblings work? Can one file be suggested for two babies? Is the per-baby scan one pass or several?
9. **What the skip and reject actions actually do.**
   - Does `Bỏ qua lần này` also train the matcher (unlike `Không phải ảnh của bé`)?
   - Is there any way to recover skipped or rejected items after the undo toast?
   - Do pending suggestions expire?
   - Does `Bỏ qua` drop all 8 even when only some were unselected? (The design says all 8.)
10. **Quiet hours.** The app has no global quiet-hours setting today; reminders have a per-rule `Không nhắc ban đêm 22:00–06:00`. Which window applies to `Báo khi có ảnh mới`? Is the cap 1/day per baby, per device or per account? Is a push also sent when a background upload completes?
11. **Destinations.** Where does the push land, AR05 quick sheet or AS07? What does `Đổi` in AR05 open (AS10?), and what does `Xem` on the toasts open?
12. **Album.** `Album: không` is the default. Can an album be picked here, and does picking one inherit the album's `Ai thấy`?
13. **Storage-fit selection order.** `Tải trước 3 ảnh vừa đủ`: which items get picked first (oldest, newest, smallest, photos before videos)? Is quota reserved at confirm time, or checked per item while uploading?
14. **Turning off with work in flight.** If Tự lưu is switched off (or permission revoked) mid-upload, does the queue continue? Are pending suggestions kept or discarded?
15. **Media fidelity.** Are HEIC/MOV originals uploaded as-is or transcoded, and at what quality? Is it the same pipeline as manual upload?
16. **Background reliability (iOS).** iOS background refresh isn't guaranteed and limited access hides new photos. The copy hedges with `thời điểm không cố định`. What service level do we commit to?
17. **Beta evaluation telemetry** (`Đánh giá sau khi có dữ liệu beta`). Which aggregate metrics count (suggestion acceptance and rejection rates, false positives) without logging child data?
18. **Design inconsistencies to confirm:**
    - AS07: all 3 video tiles are checked, but the summary says `13 ảnh, 2 video`.
    - AS13: `4 gợi ý` shown with 5 thumbnails.
    - AS15: 4 sample slots, but the max is 5.
    - AR03 date (Thứ Bảy 18/10) doesn't match Today (Thứ Năm 8/10).
    - Wi-Fi scope wording differs between AS11 and AS19.
    - The `Tìm trong` section header in AS19 also covers the Wi-Fi, background and notification toggles.
    - The `Trên iCloud` tile is unselected by default (unclear if intended).
    - The AS01 entry card has no dismiss control.
19. **Sharing defaults.** Should `Ai thấy` and `Báo cho gia đình` remember the user's last choice, or always reset to the Tự lưu defaults (`Chỉ ba mẹ`, off)?
20. **Admin/portal.** Is there a kill switch, a beta-enrolment view, or support tooling for this feature (e.g. a flag in `config/flags` mirrored to `publicConfig`)?
