# D · Section 10 — Kỷ niệm: ảnh, album, tải lên & chia sẻ (Screens page 26:2)

STATUS: PARTIAL. The Figma MCP returned a rate-limit error ("You've reached the Figma MCP tool call limit for your Full seat on the Professional plan") after 4 reads. whoami worked (Duc N., Full seat, pro plan), but tool calls are blocked until the quota resets.
Read so far: 133:16184 (10a Light) in full, plus components UploadPill 132:898, QueueRow 132:1036, MediaTile 131:860 (variant names only) and MemoryCard 10:122 (variant names only).
Three background transcription agents were started for the other 30 nodes. They write raw notes to `figma-notes/D_raw/A.md` (10a2–10d), `B.md` (10e–10e10) and `C.md` (10f–10o). They are likely to hit the same rate limit. When the quota resets, check those files or re-run the reads.

Section frame titles from `_screens_index.txt` (these are designer annotations above each frame, verbatim):
10a Dòng thời gian · đang tải nền · 10a2 Nút + · chọn nguồn ảnh · 10a3 Camera trong app · chụp liên tục · 10b Tất cả ảnh (ngoài album) · 10b2 Chọn nhiều · thao tác hàng loạt · 10b3 Nút chia sẻ · tác vụ chính & thêm · 10b4 Xác nhận xoá · 10b5 Đi tới tháng · có năm · 10c View mode (sheet) · 10d Album · 10e Chi tiết album · 10e2 Album Yêu thích (tự động) · 10e3 Nút ••• · tuỳ chọn album · 10e4 Đổi tên album · 10e5 Đổi ảnh bìa · 10e6 Ai thấy album · 10e7 Sắp xếp album · 10e8 Chọn ảnh trong album · 10e9 Tải cả album về máy · 10e10 Xoá album · 10f Xem toàn màn hình · 10g Chọn từ Thư viện ảnh (chọn nhiều) · 10h Soạn nhanh · chọn ai thấy & báo gia đình · 10h2 Chọn ngày · 10h3 Chọn mốc · có sẵn & tự tạo · 10h4 Tạo mốc mới · 10h5 Chọn album · 10i Hàng đợi · lỗi, chờ Wi‑Fi, thử lại · 10j Khoá máy · tải nền & báo xong · 10k Chia sẻ từ app Ảnh (share extension) · 10o Chia sẻ mục riêng tư · ai sẽ thấy.
Note: "10b Tất cả ảnh (ngoài album)" means the Ảnh tab shows all photos, including those not in any album (inferred).
Related screens in other sections: 13d "Đã đầy 10 GB · tạm dừng tải lên", 13f "Kỷ niệm · khi hết dung lượng" (195:177), and section 11 "Người thân xem gì khi được chia sẻ" (11a–11h).

---

## 133:16184 — 10a Kỷ niệm · Dòng thời gian · Light (READ)
**Purpose:** Memories tab home. A journal timeline grouped by week of the baby's age, with a background-upload pill at the top.

**Header**
- BabySwitcher chip: "Teddy · 3 tuần" (baby name · age in weeks)
- Icon button "View" (Icon/sliders): opens 10c Cách xem, the view-mode sheet (inferred)
- Icon button "Add" (Icon/plus): opens 10a2, the source chooser
- Large title: "Nhật ký" (Journal)

**UploadPill (State=Uploading)**
- Text: "Đang tải 4/7 mục" (Uploading 4 of 7 items), with a progress bar
- Subtext: "Cứ làm việc khác, xong sẽ báo bạn" (Go do other things, we'll tell you when it's done)
- Thumbnail with a progress ring. A chevron opens 10i Hàng đợi tải lên (inferred)

**Week groups** (left mint rule)
- "Tuần thứ 3" (Week 3) — "1 – 8 tháng 10 · 13 ảnh, 3 video" (1–8 October · 13 photos, 3 videos)
- "Tuần thứ 2" (Week 2) — "24 – 30 tháng 9 · 6 ảnh"
- Grouping is by the baby's age in weeks, with a date range and media counts per group (inferred).

**Entry cards** (layer names describe each type)
- "Entry · 1 ảnh" — author chip "M" + "Mẹ"; "Hôm nay · 9:20" (Today · 9:20); family icon (scope Gia đình); caption "Ngủ trưa ngon lành sau giờ tắm." (Napped well after bath time.); 1 photo; reaction row with heart icon: "Bà nội, Ông ngoại thương" (Grandma, Grandpa loved this)
- "Entry · 1 video" — "Ba"; "Hôm qua · 19:05"; family icon; "Lần đầu nắm chặt ngón tay ba." (First time gripping dad's finger.); video with play button and duration "0:42"; "2 lượt thương" (2 loves)
- "Entry · 2 ảnh" — "Mẹ"; "Thứ Ba, 6 thg 10"; family icon; "Bà nội sang thăm, mang theo đôi tất len tự đan."; 2 photos side by side; no reaction row (zero loves means the row is hidden — inferred)
- "Entry · ghi chú" (text-only note, warm background) — "Mẹ"; "Thứ Hai, 5 thg 10"; **lock icon** (scope Chỉ ba mẹ); "Đêm qua con ngủ một mạch 4 tiếng. Mẹ dậy mà vẫn thấy lạ." This shows a memory can be text-only.
- "Entry · nhiều ảnh" — "Mẹ"; "Thứ Hai, 5 thg 10"; family icon; milestone chip "★ Lần đầu cười · 5 thg 10" (★ First smile · 5 Oct); 3-column grid of 6 tiles:
  - a video tile showing "0:24"
  - tiles with a **Favorite** (bookmark) badge
  - a tile with a **Private** lock badge, so one item inside a Gia đình memory can be Chỉ ba mẹ. Visibility therefore applies per media item as well as per memory (inferred).
  - a video tile showing "0:12"
- Week 2 entry — "Ba"; "Chủ nhật, 20 thg 9"; family icon; milestone "★ Ngày đầu về nhà · 20 thg 9" (First day home); 3 tiles, one favorited

**Date label formats:** "Hôm nay · H:MM", "Hôm qua · H:MM", "Thứ X, D thg M"

**Floating memory tabs:** "Nhật ký" (active) · "Ảnh" · "Album" · "Câu chuyện"

**Bottom TabDock:** Today icon · "Kỷ niệm" (active) · Family icon · Me avatar "M"

**Memory fields seen:** creator (role label plus initial avatar), date/time, scope icon (family = Gia đình, lock = Chỉ ba mẹ), caption (optional), milestone (optional, ★ name · date), media list (0..n photos/videos), reactions ("thương" by named relatives), and a per-item favorite badge.

---

## Components (READ)
**UploadPill 132:898** — four states. Each state shows a title / subtitle:

| State | Title | Subtitle |
|---|---|---|
| Uploading | "Đang tải 4/7 mục" | "Cứ làm việc khác, xong sẽ báo bạn" |
| Paused (yellow) | "Tạm dừng · chờ mạng" (Paused · waiting for network) | "Tự tải tiếp khi có mạng" (Resumes automatically when online) |
| Failed (red) | "2 mục chưa tải được" (2 items not uploaded) | "Chạm để thử lại hoặc bỏ qua" (Tap to retry or skip) |
| Done | "Đã tải xong 7 mục" (Finished uploading 7 items) | "Đã báo cho Bà nội, Ông ngoại" (Notified Grandma, Grandpa) |

The Done state names the family members who were notified. That is evidence the notify-family action runs once, when the whole batch completes.

**QueueRow 132:1036** — five states. Each state shows a filename + status line and an action:

| State | Example | Status line | Action |
|---|---|---|---|
| Uploading | "IMG_2041.HEIC" | "62% · 2,1 MB/3,4 MB" | close (cancel) |
| Waiting | "IMG_2043.MOV" | "Chờ Wi-Fi · video 48 MB" (Waiting for Wi‑Fi · video 48 MB) | close (cancel) |
| Failed | "IMG_2044.HEIC" | "Mất kết nối khi đang tải" (Lost connection while uploading) | "Thử lại" (Retry) pill |
| Unreadable | "IMG_2050.HEIC" | "Tệp bị lỗi · không thử lại được" | close (remove) |
| Done | "IMG_2039.HEIC" | "Đã tải lên" (Uploaded) | check |

The Waiting state uses a video (.MOV), which matches the plan rule that video waits for Wi‑Fi. The Unreadable state is explicitly non-retryable.

**MediaTile 131:860** — variants: Default / Selected / Uploading / Failed. Overlays seen in 10a: Video (duration), Private (lock), Favorite (bookmark), progress ring.

**MemoryCard 10:122** — variants: Photo=True / Photo=False.

**Illustration/Photo 131:758** — "Illustrated baby photo placeholder (privacy-safe)."

---

## Screens NOT READ (rate limited) — fill in from D_raw/*.md or a later pass
159:18345 10a2, 159:18609 10a3, 133:16697 10b, 171:22503 10b2, 171:23012 10b3, 171:23114 10b4, 175:23809 10b5, 158:20925 10c, 135:17615 10d, 177:18 10e, 177:425 10e2, 179:18 10e3, 180:18 10e4, 180:95 10e5, 180:356 10e6, 180:440 10e7, 181:18 10e8, 181:360 10e9, 181:429 10e10, 135:18156 10f, 146:17006 10g, 158:21241 10h, 185:18 10h2, 185:260 10h3, 185:461 10h4, 185:639 10h5, 158:21349 10i, 149:17761 10j, 150:17772 10k, 158:21457 10o. Night variants: none read.

---

## Business rules confirmed (verbatim evidence)
- Uploads run in the background and the user is told when they finish: "Cứ làm việc khác, xong sẽ báo bạn" (133:16184, UploadPill).
- When there is no network, uploads pause and resume automatically: "Tạm dừng · chờ mạng" / "Tự tải tiếp khi có mạng" (UploadPill Paused).
- A partial failure can be retried or skipped: "2 mục chưa tải được" / "Chạm để thử lại hoặc bỏ qua" (UploadPill Failed).
- Family members are notified when the batch completes, and the pill names them: "Đã báo cho Bà nội, Ông ngoại" (UploadPill Done).
- Video waits for Wi‑Fi: "Chờ Wi-Fi · video 48 MB" (QueueRow Waiting).
- A network error is retryable ("Mất kết nối khi đang tải" + "Thử lại"). A corrupt file is not: "Tệp bị lỗi · không thử lại được".
- There are two visibility scopes: the family icon is Gia đình and the lock icon is Chỉ ba mẹ. The scope shows on each memory, and a lock badge can also appear on a single media tile (133:16184).
- Relatives react with "thương" ("Bà nội, Ông ngoại thương", "2 lượt thương").
- Milestones attach to a memory as "★ <name> · <date>" (examples: "Lần đầu cười", "Ngày đầu về nhà").

## Entities & fields implied
- **Memory:** id, babyId, creatorMemberId (role label "Mẹ"/"Ba"), occurredAt (date+time), caption?, milestoneId?, scope {gia_dinh | chi_ba_me}, mediaItems[], reactions[] (member, type "thương"), albumIds[] (inferred). Text-only memories are allowed.
- **MediaItem:** id, type photo/video, durationSec (video), per-item scope override? (lock tile inside a Gia đình memory — inferred), favoritedBy (per user? — open), upload status.
- **Milestone:** name, date (preset vs custom — not read).
- **UploadBatch:** total and done counts, state {uploading, paused, failed(partial), done}, notifiedMembers[].
- **UploadItem:** filename, bytesSent/bytesTotal, state {uploading, waiting_wifi, failed_retryable, unreadable, done}.

## State machines
- **Upload item:** queued → uploading(%) → done.
  - uploading → failed ("Mất kết nối…") → [Thử lại] → uploading.
  - queued(video on cellular) → waiting_wifi → uploading once on Wi‑Fi.
  - any → unreadable (terminal, remove only).
  - uploading/waiting → cancelled (close button).
- **Upload batch pill:** uploading → paused (no network, auto-resumes) → uploading → done ("Đã tải xong N mục", family notified) | failed ("N mục chưa tải được"; retry or skip).
- **Memory publish:** draft (10h) → items uploading → published when items finish → notify family once (if the toggle is on and scope is Gia đình — inferred). It is not confirmed whether a memory appears before all of its items finish.

## Open questions / gaps
- All 30 screens listed above are unread, so these remain open:
  - visibility options, default scope and "báo gia đình" copy (158:21241)
  - milestone presets (185:260 / 185:461)
  - album rules: delete keeps memories? sort options, Ai thấy album propagation (180:356, 181:429, 180:440)
  - batch actions (171:22503 / 171:23012)
  - delete confirmation (171:23114)
  - viewer actions (135:18156)
  - share extension (150:17772)
  - lock-screen copy (149:17761)
  - effect of sharing a Chỉ ba mẹ item (158:21457)
  - size/duration limits and photo cellular rule (158:21349)
- Is visibility set per memory or per media item? 133:16184 shows a lock badge on one tile inside a Gia đình memory.
- Is Favorite (bookmark) per user or shared? Needs 177:425.
- Is the batch "Done" notification held back until every item finishes, including Wi‑Fi‑waiting videos? Needs 158:21349.


---

# Batch A (10a2–10d)

# D_raw / A — Section "10 · Kỷ niệm" (Light), Figma file sJLG1fAXKDnDr9YI6Yx8ex

Source: get_design_context (read-only). Shared chrome on Memories screens: StatusBar "9:41" / "•••"; BabySwitcher chip "Teddy · 3 tuần" (baby avatar + name + chevron-down; component note: "chevron when the family has more than one baby. Shows whose log you are viewing"); header actions = "View" button (Icon/sliders → opens 10c Cách xem sheet) + "Add" button (Icon/plus, filled mint → opens 10a2 sheet); bottom TabDock NavBar: Tab/Today (sun icon, no label), Tab/Memories ACTIVE (memories icon + label "Kỷ niệm"), Tab/Family (family icon), Tab/Me (avatar circle letter "M"). Bottom fade gradient behind floating controls.

Media tile overlay vocabulary (component MediaTile, layer names): "Video" = dark pill bottom-left with play triangle + duration (e.g. "0:24"); "Private" = dark rounded badge top-left with Icon/lock (private / Chỉ ba mẹ); "Favorite" = Icon/bookmark bottom-right (favorite); "Overlay" + "Ring track" + "Ring" = dimmed tile with circular upload-progress ring; "Check" + "Icon/check" = selected check top-right (select mode); "Select ring" = empty circle top-right (unselected in select mode).

---

## 1. 159:18345 — "10a2 Thêm mới (nút +) · Light"
Purpose: "Nút + · chọn nguồn ảnh" — bottom sheet opened by the header "+" button to choose the source for adding a memory. Background is the Nhật ký (timeline) tab, dimmed by a Scrim.

### Background screen (under scrim), reading order
- "Teddy · 3 tuần" — baby switcher (Teddy · 3 weeks)
- "Nhật ký" — large title (Journal / timeline)
- UploadPill (layer "UploadPill"): thumbnail with upload ring + favorite bookmark;
  - "Đang tải 4/7 mục" — Uploading 4/7 items (progress bar ~44% filled)
  - "Cứ làm việc khác, xong sẽ báo bạn" — Go do other things, we'll notify you when done
  - chevron-right (tap → upload detail/queue)
- Week section (layer "Tuần thứ 3", left mint border):
  - "Tuần thứ 3" — Week 3
  - "1 – 8 tháng 10 · 9 ảnh, 2 video" — 1–8 October · 9 photos, 2 videos
  - Milestone chip (layer "★ Lần đầu cười · 5/10"): "★ Lần đầu cười · 5 thg 10" — ★ First smile · 5 Oct
  - Grid of 6 tiles: plain; video "0:24"; favorite; private(lock); video "0:12"; favorite
- Week section "Tuần thứ 2":
  - "Tuần thứ 2" — Week 2
  - "24 – 30 tháng 9 · 6 ảnh" — 24–30 September · 6 photos
  - Milestone chip (layer "★ Ngày đầu về nhà · 20/9"): "★ Ngày đầu về nhà · 20 thg 9" — ★ First day home · 20 Sep
  - 3 tiles (third = favorite)
- Floating "Memory tabs (floating)" segmented pill: "Nhật ký" (ACTIVE; layer name "Dòng thời gian" = timeline) · "Ảnh" (Photos) · "Album" · "Câu chuyện" (Stories)
- TabDock (Kỷ niệm active)

### Sheet (foreground)
- SheetHeader: grabber; title "Thêm vào Kỷ niệm" — Add to Memories; close X (component note: close label "Đóng")
- Recent head row:
  - "Ảnh mới chụp hôm nay" — Photos taken today
  - "Chạm để thêm nhanh" — Tap to add quickly
- Recent strip: 5 thumbnails (3rd = video "0:18"; 4th = favorite bookmark) — tap a thumbnail to quick-add
- EntryOption 1 (PRIMARY / highlighted, recommended path), camera icon:
  - "Chụp ảnh hoặc quay video" — Take photo or record video
  - "Lưu thẳng vào Kỷ niệm" — Saves straight to Memories
  - → 10a3 Chụp ảnh (in-app camera)
- EntryOption 2, memories/photo icon:
  - "Chọn từ Thư viện ảnh" — Choose from Photo Library
  - "Chọn nhiều ảnh, video một lần" — Pick multiple photos/videos at once
  - → system photo picker (multi-select)
- EntryOption 3, upload icon:
  - "Chọn từ Tệp" — Choose from Files
  - "iCloud Drive, Google Drive, USB…" — (sources)
  - → system document picker
- EntryOption 4, edit/pencil icon:
  - "Viết ghi chú" — Write a note
  - "Kỷ niệm chỉ có chữ, thêm ảnh sau" — Text-only memory, add photos later
  - → note composer
- Component note (EntryOption): "Large entry choice with icon, title, subtitle and chevron. Primary = recommended path."
- No annotation/sticky text found in frame.

---

## 2. 159:18609 — "10a3 Chụp ảnh · Light"
Purpose: "Camera trong app · chụp liên tục" — in-app camera, burst/continuous capture into Teddy's memories. Black full-screen UI.

### Text in reading order
- "9:41" / "•••" — status bar (white)
- Top bar: close X (Icon/close, exits camera)
- Destination chip (layer "dest"/"chip"): "Lưu vào Kỷ niệm của Teddy" — Save to Teddy's Memories (destination is the currently selected baby)
- "Flash" — flash toggle (text button, top-right)
- Viewfinder (live preview)
- Mode switcher (layer "Mode"): "VIDEO" (inactive) · "ẢNH" (ACTIVE, highlighted yellow) — Video / Photo
- Bottom row:
  - "Last" thumbnail (last captured shot, has favorite bookmark overlay) with count badge (layer "n"): "3" — 3 shots captured this session; tap → review captured
  - Shutter button (double ring, center)
  - Button (layer "Xong"): "Xong (3)" — Done (3) → goes to compose & share
- Hint: "Chụp liên tục · bấm Xong để soạn & chia sẻ" — Continuous shooting · tap Done to compose & share

### Behavior
- Default mode = ẢNH (photo). Capture multiple; counter on thumbnail and Done button both show count. Done → compose/share step.
- No annotation text found.

---

## 4. 171:22503 — "10b2 Chọn nhiều · Light"
Purpose: "thao tác hàng loạt" — multi-select mode on the Ảnh (all photos) tab for bulk actions.

### Text in reading order
- "Teddy · 3 tuần" — baby switcher; header actions sliders (View) + "+" (Add)
- "Ảnh" — large title (Photos)
- Month filter row (layer "Month filter"):
  - "Tất cả" — All (ACTIVE chip, dark fill)
  - "Tháng ▾" — Month ▾ (dropdown chip; layer name "Tháng 10"; → 10b5 Chọn tháng & năm)
  - spacer
  - "Xong" — Done (dark chip; layer name "Chọn" = the Select button, which becomes "Xong" in select mode; exits select mode)
- Section header (layer "Tháng 10"):
  - "Tháng 10, 2026" — October 2026
  - "Chọn cả tháng" — Select whole month (mint link)
- Grid Oct (4 cols, 16 tiles). Selected (Check) tiles: #1 (also favorite), #3 (video "0:24"), #6 (private lock), #7 (favorite), #10 (video "0:12", favorite) = 5 selected. Others show empty "Select ring". Other overlays: #4 favorite, #14 private lock, #15 favorite.
- Section header (layer "Tháng 9"):
  - "Tháng 9, 2026" — September 2026
  - "Chọn cả tháng" — Select whole month
- Grid Sep (8 tiles visible, all unselected; favorites on #2, #5, #8)
- Floating "Selection pill (floating)" (replaces Memory tabs while selecting):
  - Left round button (layer "Chia sẻ & tuỳ chọn" = Share & options), Icon/upload (share) → 10b3 Thêm thao tác sheet
  - "5 mục đã chọn" — 5 items selected (center counter)
  - Right round button (layer "Xoá" = Delete), red Icon/trash → 10b4 Xoá mục confirm
- TabDock (Kỷ niệm active)

### Notes
- Selection count label pattern: "{n} mục đã chọn".
- No annotation text found.

---

## 3. 133:16697 — "10b Kỷ niệm · Tất cả ảnh · Light"
Purpose: "Tất cả ảnh (ngoài album)" — Ảnh tab: every photo/video of the baby in a month-grouped 4-column grid (browse mode, not selecting).
(Note: first call was rate-limited; retried after whoami and read OK.)

### Text in reading order
- "9:41" / "•••"
- "Teddy · 3 tuần" — baby switcher; actions: sliders (View → 10c Cách xem) + "+" (Add → 10a2)
- "Ảnh" — large title (Photos)
- Month filter row (layer "Month filter"):
  - "Tất cả" — All (ACTIVE/selected chip, dark)
  - "Tháng ▾" — Month ▾ (inactive chip; layer name "Tháng 10"; → 10b5 Chọn tháng & năm)
  - spacer
  - Chip (layer "Chọn") with Icon/check + "Chọn" — Select (→ 10b2 Chọn nhiều multi-select mode)
- Section header (layer "Tháng 10"):
  - "Tháng 10, 2026" — October 2026
  - "32 ảnh · 4 video" — 32 photos · 4 videos (muted count)
  Tiles: 1 fav, 3 video 0:24, 4 fav, 6 lock, 7 fav, 10 video 0:12+fav, 13 lock, 14 fav; others plain.
- Section header (layer "Tháng 9"):
  - "Tháng 9, 2026" — September 2026
  - "94 ảnh · 5 video" — 94 photos · 5 videos
- Grid Sep (8 tiles; favorites on #2, #5, #8)
- Floating "Date scrubber" pill on right edge (shadow-chip): "Th 10, 2026" + chevron-down — Oct 2026 (abbrev "Th" = Tháng); fast-scroll date indicator / tap → jump to month (10b5)
- Floating "Memory tabs (floating)": "Nhật ký" · "Ảnh" (ACTIVE) · "Album" · "Câu chuyện"
- TabDock: Kỷ niệm active

### Interactions
- Tap tile → media viewer. Long-press likely → select mode.
- "Chọn" enters select mode (10b2) where it becomes "Xong" and the section count becomes "Chọn cả tháng".
- Month section header count format: "{n} ảnh · {m} video".
- No annotation text found.
---

## 5. 171:23012 — "10b3 Thêm thao tác · Light"
Purpose: "Nút chia sẻ · tác vụ chính & thêm" — bottom sheet opened from the Share (upload icon) button in the selection pill (10b2); main actions + more actions for the selected items.
(Response was truncated by tool size limit at the very end, but the sheet content appears complete and matches the screenshot.)

### Background (dimmed by Scrim): identical to 10b2 select mode — "Ảnh", chips "Tất cả" (active) / "Tháng ▾" / "Xong"; "Tháng 10, 2026" + "Chọn cả tháng"; same 5 selected tiles; "Tháng 9, 2026" + "Chọn cả tháng"; selection pill "5 mục đã chọn" with share + trash buttons; TabDock.

### Sheet text in reading order
- SheetHeader: grabber; title "5 mục đã chọn" — 5 items selected; close X ("Đóng")
- "Main actions" row — 4 equal tiles (icon above label):
  1. Icon/family + "Ai thấy" — Who sees (layer "Ai thấy"; → visibility/audience picker: Gia đình vs Chỉ ba mẹ)
  2. Icon/memories + "Album" — Album (layer "Vào album" = add to album; → album picker)
  3. Icon/download (arrow down) + "Tải về" — Download (layer "Tải về máy" = save to device)
  4. Icon/link + "Gửi đi" — Send (layer "Gửi app khác" = send to another app; → system share sheet)
- Section label: "Thêm" — More
- "More" grouped list (rows: icon, title, subtitle, chevron-right):
  1. Icon/bookmark — "Thêm vào Yêu thích" — Add to Favorites / "Gom vào album Yêu thích của bạn" — Collects into your Favorites album
  2. Icon/star — "Gắn mốc" — Tag a milestone / "Ví dụ: Lần đầu cười" — e.g. First smile
  3. Icon/clock — "Đổi ngày" — Change date / "Khi ngày chụp bị sai" — When the capture date is wrong
  4. Icon/spark — "Kể thành câu chuyện" — Turn into a story / "Dùng 5 mục này làm bản nháp" — Use these 5 items as a draft (count interpolated)
  5. DISABLED (50% opacity, no chevron) Icon/memories — "Đặt làm ảnh bìa album" — Set as album cover / "Chỉ dùng khi chọn 1 ảnh" — Only available when 1 photo is selected

### Notes
- Bookmark icon = Yêu thích (favorite; per-user "your" Favorites album).
- Set-as-cover is disabled for multi-select (>1 item). Rule: enabled only when exactly 1 photo selected.
- Delete is NOT in this sheet; it is the trash button in the selection pill (→ 10b4).
- No annotation text found.
---

## 6. 171:23114 — "10b4 Xoá mục · Light"
Purpose: "Xác nhận xoá" — delete-confirmation bottom sheet opened from the red trash button in the selection pill (10b2), for the 5 selected items.
(Read via get_metadata on frame + get_design_context on Sheet 161:19062.)

### Background (dimmed by Scrim): same as 10b2 select mode ("Ảnh", "Tất cả"/"Tháng ▾"/"Xong", "Tháng 10, 2026"/"Chọn cả tháng", "Tháng 9, 2026"/"Chọn cả tháng", selection pill "5 mục đã chọn" + share + trash, TabDock). A "Date scrubber" ("Th 10, 2026" + chevron-down) exists but is HIDDEN in select mode.

### Sheet text in reading order
- SheetHeader: grabber; title "Xoá 5 mục?" — Delete 5 items?; close X ("Đóng")
- "Items" row: 5 thumbnails of the selected items (3rd has favorite bookmark)
- Body: "Mục sẽ biến mất khỏi Kỷ niệm của cả gia đình. Ảnh gốc trên máy bạn vẫn còn." — Items will disappear from the whole family's Memories. The original photos on your device remain.
- Info box (layer "Recover"), Icon/clock: "Khôi phục được trong 30 ngày ở “Đã xoá gần đây”." — Recoverable for 30 days in "Recently deleted".
- Permission line (layer "Own"), Icon/lock: "Chỉ ba mẹ mới xoá được." — Only parents can delete.
  - NOTE: the text layer's NAME (stale/longer copy) reads "Chỉ ba mẹ xoá được. Người thân chỉ ẩn kh…" (truncated in metadata) — i.e. "Only parents can delete. Relatives can only hide (from their view)…". Visible copy is the shorter sentence; layer name reveals the rule that relatives (non-parents) get a hide action instead of delete.
- Destructive button (tinted error, full width, h56): "Xoá 5 mục" — Delete 5 items
- Plain text button: "Huỷ" — Cancel

### Rules captured
- Delete is family-wide (removes from everyone's Memories), does not touch device originals.
- Soft delete: 30-day recovery in "Đã xoá gần đây" (Recently deleted).
- Only parents (ba mẹ) can delete; lock icon = parent-only permission.
- Count interpolated in title and button: "Xoá {n} mục?" / "Xoá {n} mục".
---

## 7. 175:23809 — "10b5 Chọn tháng & năm · Light"
Purpose: "Đi tới tháng · có năm" — month+year jump sheet opened from the "Tháng ▾" chip (or the Date scrubber "Th 10, 2026 ▾") on the Ảnh tab.
(Read via get_metadata on frame + get_design_context on Sheet 175:23882; first attempt rate-limited, retried OK.)

### Background (dimmed by Scrim): same as 10b browse mode — "Ảnh"; chips "Tất cả" (active) / "Tháng ▾" / "✓ Chọn"; "Tháng 10, 2026" + "32 ảnh · 4 video"; "Tháng 9, 2026" + "94 ảnh · 5 video"; Memory tabs "Nhật ký" · "Ảnh" · "Album" · "Câu chuyện"; Date scrubber "Th 10, 2026" (visible); TabDock.

### Sheet text in reading order
- SheetHeader: grabber; title "Đi tới tháng" — Go to month; close X ("Đóng")
- Year chips (layer "Years"):
  - "2025" — disabled/dimmed (40% opacity; no content that year)
  - "2026" — SELECTED (dark fill)
  - "2027" — disabled/dimmed (40%)
- Month grid 4×3 (layer "Months"; each cell = month label + item count, "—" when empty):
  - "Th 1" / "—" (disabled, 45% opacity)
  - "Th 2" / "—" (disabled)
  - "Th 3" / "—" (disabled)
  - "Th 4" / "—" (disabled)
  - "Th 5" / "—" (disabled)
  - "Th 6" / "—" (disabled)
  - "Th 7" / "—" (disabled)
  - "Th 8" / "—" (disabled)
  - "Th 9" / "94 mục" — Sep / 94 items (enabled)
  - "Th 10" / "36 mục" — Oct / 36 items (CURRENT/SELECTED: mint outline + mint-soft fill)
  - "Th 11" / "—" (disabled)
  - "Th 12" / "—" (disabled)
- Footnote: "Teddy sinh ngày 17 tháng 9, 2026 · năm khác sẽ hiện khi có ảnh" — Teddy was born on 17 Sep 2026 · other years will appear once they have photos

### Rules / notes
- Months/years with no media are shown but disabled ("—"); range starts at baby's birth.
- Count unit here is "mục" (items = photos + videos). Th 10: 36 mục = 32 ảnh + 4 video (consistent). Th 9: "94 mục" vs section header "94 ảnh · 5 video" (=99) — copy/data inconsistency in the mock.
- Abbreviation "Th {n}" = Tháng {n}.
- Tap enabled month → scroll grid to that month section and close sheet.
---

## 8. 158:20925 — "10c Cách xem · Light"
Purpose: "View mode (sheet)" — view-options sheet opened from the header sliders ("View") button; controls grouping, layout, media filter and audience filter.
(Read via get_metadata on frame + get_design_context on Sheet 133:17566.)

### Background (dimmed by Scrim): Ảnh tab browse mode — same as 10b ("Ảnh"; "Tất cả"/"Tháng ▾"/"✓ Chọn"; "Tháng 10, 2026" "32 ảnh · 4 video"; "Tháng 9, 2026" "94 ảnh · 5 video"; Date scrubber "Th 10, 2026"; Memory tabs; TabDock).

### Sheet text in reading order (single-select chip groups; dark chip = selected)
- SheetHeader: grabber; title "Cách xem" — View options; close X ("Đóng")
- Group label "Nhóm theo" — Group by
  - "Ngày" — Day
  - "Tuần" — Week (SELECTED)
  - "Tháng" — Month
- Group label "Kiểu xem" — Layout
  - "Lưới nhỏ" — Small grid (SELECTED)
  - "Lưới lớn" — Large grid
  - "Danh sách" — List (layer name "Theo ngày" = by day; stale name)
- Group label "Hiện" — Show
  - "Tất cả" — All (SELECTED)
  - "Ảnh" — Photos
  - "Video" — Videos
  - "Có mốc" — With milestone
- Group label "Ai thấy" — Who can see (audience filter)
  - "Tất cả" — All (SELECTED)
  - "Gia đình" — Family (items shared with family)
  - "Chỉ ba mẹ" — Parents only (private items; = lock icon on tiles)
- Row (layer "Preview as"), Icon/today (sun) + chevron-right:
  - "Xem như người thân" — View as a relative
  - "Kiểm tra người thân đang thấy những gì" — Check what relatives are seeing
  - → preview mode showing the library as a relative sees it (private items hidden)
- Primary button (full width): "Áp dụng" — Apply

### Notes
- Defaults: Group by Tuần, Small grid, Show Tất cả, Audience Tất cả.
- Changes are applied only on "Áp dụng" (not live).
- Interesting: background is the Ảnh tab (month sections) yet default "Nhóm theo" shows Tuần — grouping option likely shared with Nhật ký (weekly sections).
- No annotation text found.
---

## 9. 135:17615 — "10d Kỷ niệm · Album · Light"
Purpose: Album tab — grid of user albums (each with audience badge) plus auto-collected milestone albums.

### Text in reading order
- "9:41" / "•••"
- "Teddy · 3 tuần" — baby switcher; actions sliders (View → 10c) + "+" (Add → 10a2)
- "Album" — large title
- "Album bar":
  - "4 album" — 4 albums (count, muted)
  - Mint pill button (layer "Album mới") Icon/plus + "Album mới" — New album (→ create album flow)
- "Albums" 2-col grid (cover photo + badge top-left + name + count):
  1. "Yêu thích" — Favorites; badge Icon/lock (Chỉ ba mẹ / private); "18 ảnh · 2 video"
  2. "Giờ tắm" — Bath time; badge Icon/family (Gia đình / shared with family); "12 ảnh · 3 video"
  3. "Ngủ ngoan" — Sleeping sweetly; badge Icon/lock (private); "28 ảnh · 1 video"
  4. "Bàn tay nhỏ" — Little hands; badge Icon/family (family); "9 ảnh" (photo-only count omits video part)
- Section title: "Gom từ mốc bạn đã gắn" — Collected from milestones you tagged
- "Milestones" horizontal row (cover + caption; likely horizontally scrollable):
  - "★ Lần đầu cười" — ★ First smile
  - "★ Ngày về nhà" — ★ Day came home
  - "★ Tròn 3 tuần" — ★ 3 weeks old
- Floating "Memory tabs (floating)": "Nhật ký" · "Ảnh" · "Album" (ACTIVE) · "Câu chuyện"
- TabDock: Kỷ niệm active

### Notes
- Album badge semantics: lock = private (Chỉ ba mẹ), family icon = shared with Gia đình. Favorites ("Yêu thích") album is private (lock) — consistent with 10b3 "Gom vào album Yêu thích của bạn".
- Count format: "{n} ảnh · {m} video"; when 0 videos, only "{n} ảnh".
- Milestone albums are auto-generated from milestone tags (★ prefix), not counted in "4 album".
- Tap album → album detail; tap milestone → milestone collection.
- No annotation text found.
---

## Night spot-check

### 178:29689 — "10b3 Thêm thao tác · Night care"
(Read via get_metadata + get_design_context on Sheet 178:29780.)
- Frame name uses suffix "· Night care" (not "· Night").
- Structure, layer names and ALL copy identical to Light 10b3: title "5 mục đã chọn"; main actions "Ai thấy" / "Album" / "Tải về" / "Gửi đi"; "Thêm"; rows "Thêm vào Yêu thích"/"Gom vào album Yêu thích của bạn", "Gắn mốc"/"Ví dụ: Lần đầu cười", "Đổi ngày"/"Khi ngày chụp bị sai", "Kể thành câu chuyện"/"Dùng 5 mục này làm bản nháp", "Đặt làm ảnh bìa album"/"Chỉ dùng khi chọn 1 ảnh" (still disabled at 50%, no chevron).
- Background identical (select mode, "Xong", "Chọn cả tháng", selection pill "5 mục đã chọn", Date scrubber hidden).
- No behavior or copy differences — color theme only.

### 178:30152 — "10b4 Xoá mục · Night care"
(Read via get_metadata + get_design_context on Sheet 178:30243; first attempt rate-limited, retried OK.)
- Copy identical to Light: "Xoá 5 mục?"; "Mục sẽ biến mất khỏi Kỷ niệm của cả gia đình. Ảnh gốc trên máy bạn vẫn còn."; "Khôi phục được trong 30 ngày ở “Đã xoá gần đây”."; "Chỉ ba mẹ mới xoá được."; buttons "Xoá 5 mục" / "Huỷ".
- Same stale layer name on the permission line: "Chỉ ba mẹ xoá được. Người thân chỉ ẩn kh…".
- Same 5 thumbnails (3rd favorite), Date scrubber hidden in background.
- No behavior or copy differences — color theme only.

---

## Global observations (cross-screen)
- Memories sub-tabs (floating pill above TabDock): "Nhật ký" (layer "Dòng thời gian") · "Ảnh" · "Album" · "Câu chuyện". In select mode the pill is replaced by the "Selection pill" (share · "{n} mục đã chọn" · trash).
- Header actions are constant on all Memories tabs: sliders (→ "Cách xem" sheet) and mint "+" (→ "Thêm vào Kỷ niệm" sheet).
- Icon semantics: lock = Chỉ ba mẹ / private (tile badge, album badge, parent-only permission); family icon = Gia đình / shared (album badge; "Ai thấy" action); bookmark = Yêu thích / favorite (tile overlay, "Thêm vào Yêu thích"); star ★ = mốc / milestone; spark = câu chuyện; clock = date/recovery; upload icon = share & options; trash = delete. No heart icon used for favorite on these screens ("Icon/memories" is a heart-in-frame glyph used for Kỷ niệm/album/library).
- Tile overlays: video duration pill (play ▶ + "0:24"/"0:12"/"0:18"); Private lock badge top-left; Favorite bookmark bottom-right; upload ring (Overlay + Ring track + Ring) seen in UploadPill thumbnail; selection Check / Select ring top-right. No error overlay seen on these screens.
- Counts formats: "{n} ảnh · {m} video" (section header & album), "{n} ảnh" when no video, "{n} mục" in month picker, "{n} mục đã chọn" selection, "Đang tải {x}/{y} mục" upload.
- No sticky/annotation text boxes were found inside any of the read frames.


---

# Batch B (10e–10e10 albums)

# D_raw / B — Section "10 · Kỷ niệm" · Album detail & album options (Light)

Figma file sJLG1fAXKDnDr9YI6Yx8ex. Read-only transcription via get_design_context.

## Shared album-detail backdrop (used by 10e, 10e3–10e10)

All option sheets sit on top of the "Giờ tắm" album detail screen (10e) with a dimming scrim (layer "Scrim"). Backdrop copy is identical to 10e unless noted.

---

## 177:18 — "10e Album · Giờ tắm · Light" (Chi tiết album)

Purpose: detail page of a user-made album ("Giờ tắm" = Bath time), full-bleed cover hero + 3-column media grid + floating action bar.

Text (reading order):
- `9:41` / `•••` — status bar placeholder
- (Back button, icon only; layer "Back")
- (More button `•••`, icon only; layer "More") — opens 10e3 album options sheet
- `Giờ tắm` — album title ("Bath time")
- `12 ảnh · 3 video · cập nhật hôm qua` — "12 photos · 3 videos · updated yesterday"
- `Gia đình` — visibility pill with family icon ("Family"); layer "Share"
- Grid tiles: video duration badges `0:12` and `0:31` (play-triangle + duration on video tiles)
- Floating bar: [family icon button, layer "Ai thấy" = who can see] · `Thêm ảnh` ("Add photos", primary, plus icon) · [spark icon button, layer "Kể thành chuyện" = "Turn into a story"]

Interactive / states:
- Back → previous (Kỷ niệm / album list).
- More (•••) → 10e3 Tuỳ chọn album sheet.
- Visibility pill "Gia đình" (family icon) reflects album visibility; "Ai thấy" button in floating bar (family icon) → likely 10e6 Ai thấy album sheet.
- "Thêm ảnh" → add photos to album (picker).
- Spark button "Kể thành chuyện" → generate a story from the album.
- Media tiles: 15 shown (3 columns, 2px gaps); video tiles show duration overlay; no favorite marks here.
- Layer names: "Hero", "Scrim", "Album info", "Share", "Grid", "MediaTile", "Bottom fade", "Album actions (floating)", "Ai thấy", "Thêm ảnh", "Kể thành chuyện".

---

## 177:425 — "10e2 Album · Yêu thích · Light" (Album Yêu thích, tự động)

Purpose: the automatic "Favorites" album — collects items the current user has bookmarked; private to the user.

Text (reading order):
- `9:41` / `•••`
- (Back, More icons)
- `Yêu thích` — album title ("Favorites")
- `18 ảnh · 2 video · ảnh bạn đã đánh dấu` — "18 photos · 2 videos · photos you have marked"
- `Chỉ mình bạn` — visibility pill with LOCK icon ("Only you")
- Video badges `0:12`, `0:31`
- Floating bar: [LOCK icon button, layer "Ai thấy"] · `Thêm ảnh` · [spark, layer "Kể thành chuyện"]

Interactive / states:
- Every tile has a bookmark overlay bottom-right (layer "Favorite" > "Icon/bookmark") — favorite = bookmark icon, per-person.
- Visibility is "Chỉ mình bạn" (lock) — i.e. the favorites album is private to the current person (not "Chỉ ba mẹ"; it's per-user). The "Ai thấy" floating button shows a lock instead of family icon.
- No annotation text in this frame describing auto rules beyond the subtitle "ảnh bạn đã đánh dấu" (auto-populated from items you bookmark). "Thêm ảnh" is still shown in the design (same floating bar as normal albums).
- Video tiles show both duration badge (bottom-left) and bookmark (bottom-right).

---

## 179:18 — "10e3 Tuỳ chọn album · Light" (Nút ••• · tuỳ chọn album)

Purpose: bottom sheet opened by the ••• button on album detail; lists album actions.

Backdrop: 10e (Giờ tắm) dimmed.

Sheet text (reading order):
- `Giờ tắm` — sheet title = album name; close (X) button top-right (SheetHeader; close label "Đóng")
- Group 1 (layer "Album"):
  - `Đổi tên album` — "Rename album" (pencil/edit icon, chevron) → 10e4
  - `Đổi ảnh bìa` — "Change cover photo" (camera icon, chevron) → 10e5
  - `Ai thấy album này` — "Who sees this album" (family icon)
    - subtitle `Mọi người thân trong gia đình` — "All relatives in the family"
    - trailing value `Gia đình` — "Family" (current value) + chevron → 10e6
- Group 2 (layer "Ảnh" = Photos):
  - `Chọn ảnh` — "Select photos" (check icon)
    - subtitle `Bỏ khỏi album, đổi ai thấy…` — "Remove from album, change who sees…" + chevron → 10e8
  - `Sắp xếp` — "Sort" (clock icon), trailing value `Mới nhất` ("Newest") + chevron → 10e7
  - `Tải cả album về máy` — "Download whole album to device" (down-arrow icon)
    - subtitle `12 ảnh · 3 video · khoảng 180 MB` — "12 photos · 3 videos · about 180 MB" + chevron → 10e9
- Destructive card (layer "Xoá album", red tinted):
  - `Xoá album` — "Delete album" (red)
  - subtitle `Chỉ xoá album, ảnh vẫn còn trong Kỷ niệm` — "Only deletes the album; photos remain in Kỷ niệm (Memories)" → 10e10

States: current visibility = Gia đình; current sort = Mới nhất. No disabled rows.

---

## 180:18 — "10e4 Đổi tên album · Light"

Purpose: bottom sheet to rename the album, with suggestion chips.

Sheet text (reading order):
- `Đổi tên album` — sheet title "Rename album"; close X
- Text field label `Tên album` — "Album name"
- Text field value `Giờ tắm của Teddy` — "Teddy's bath time" (edited value; baby name Teddy)
- `Gợi ý` — "Suggestions"
- Chips: `Giờ tắm` ("Bath time") · `Tắm nắng` ("Sunbathing") · `Lần đầu đi bơi` ("First time swimming")
- Primary button `Lưu tên` — "Save name"

States: chips unselected (neutral); tapping a chip presumably fills the field. Button enabled. Layer "Gợi ý" holds chips.

---

## 180:95 — "10e5 Đổi ảnh bìa · Light"

Purpose: bottom sheet to choose a cover photo from album items, with live preview.

Sheet text (reading order):
- `Chọn ảnh bìa` — sheet title "Choose cover photo" (note: differs from row label "Đổi ảnh bìa"); close X
- Preview card (layer "Preview"): selected photo with overlaid album title `Giờ tắm`
- Grid of 8 rounded thumbnails (4 per row, layer "Grid" > "MediaTile"); 2nd tile is SELECTED (check badge top-right, layers "Check" + "Icon/check") — preview shows that photo
- Primary button `Đặt làm ảnh bìa` — "Set as cover photo"

States: single-select; selected tile = 2nd thumbnail. No videos indicated in picker.

---

## 180:356 — "10e6 Ai thấy album · Light"

Purpose: bottom sheet to set who can see the album (album-level visibility), with propagation note and family notification toggle.

Sheet text (reading order):
- `Ai thấy album này` — title "Who sees this album"; close X
- Option card (layer "Chỉ ba mẹ"), LOCK icon:
  - `Chỉ ba mẹ` — "Parents only"
  - `Chỉ ba mẹ xem được` — "Only parents can view"
- Option card (layer "Gia đình"), FAMILY icon — SELECTED (highlighted border, check icon on right):
  - `Gia đình` — "Family"
  - `Cả nhà cùng xem` — "The whole family views together"
- Note card (layer "Note") — BUSINESS RULE:
  - `Áp dụng cho cả 15 mục trong album` — "Applies to all 15 items in the album" (15 = 12 ảnh + 3 video; count is dynamic)
  - `Ảnh thêm sau này cũng theo quyền của album. Người chăm không thấy Kỷ niệm.` — "Photos added later also follow the album's permission. Caregivers (Người chăm) do not see Kỷ niệm (Memories)."
- Row (layer "Notify") with Toggle ON:
  - `Báo cho gia đình` — "Notify the family"
  - `1 thông báo chung, không kèm ảnh` — "1 general notification, no photos attached"
- Primary button `Lưu` — "Save"

States / rules:
- Only two options: Chỉ ba mẹ (lock) / Gia đình (family). Default/current here = Gia đình (checked).
- Changing album visibility applies retroactively to ALL items currently in the album AND to items added later.
- Caregiver role never sees Kỷ niệm regardless of setting.
- No copy here about items that belong to multiple albums (not addressed in this frame).
- Notify toggle default ON; sends a single aggregated notification without photos.

## 180:440 — "10e7 Sắp xếp album · Light"

Purpose: bottom sheet to pick the album sort order (single-select radio list).

Sheet text (reading order):
- `Sắp xếp` — title "Sort"; close X
- Option (OptionRow, radio CHECKED): `Mới nhất` — "Newest" / `Ảnh chụp gần đây ở trên` — "Recently taken photos on top"
- Option (unchecked): `Cũ nhất` — "Oldest" / `Kể lại từ đầu, hợp để xem lại` — "Retell from the beginning, good for looking back"
- Option (unchecked): `Mới thêm vào album` — "Recently added to album" / `Theo lúc bạn thêm ảnh` — "By when you added the photo"

States: default = Mới nhất (by capture date desc). Cũ nhất = capture date asc. Mới thêm vào album = by date added to album. No Save button — selection applies immediately (tap row). Sort appears to be per album (shown as trailing value in 10e3 "Sắp xếp · Mới nhất").

## 181:18 — "10e8 Chọn ảnh trong album · Light"

Purpose: in-place multi-select mode on the album detail grid (entered via "Chọn ảnh" in 10e3) — select items to remove from album or share/other options.

Text (reading order):
- `9:41` / `•••`
- `Xong` — "Done" pill top-right (replaces Back/More; exits selection mode) — layer "Xong"
- Hero unchanged: `Giờ tắm` / `12 ảnh · 3 video · cập nhật hôm qua` / `Gia đình`
- Video badges `0:12`, `0:31`
- Floating bar (replaces normal action bar):
  - [upload/share icon button, layer "Chia sẻ & tuỳ chọn" = "Share & options"]
  - `3 mục đã chọn` — "3 items selected" (live counter)
  - `Bỏ khỏi album` — "Remove from album" (red tinted, X icon; layer "Bỏ khỏi album")

States:
- Back and ••• buttons hidden in this mode; only "Xong".
- Selected tiles: filled check badge top-right (3 selected: tile 1, tile 5, tile 6). Unselected tiles: empty "Select ring" top-right.
- "Bỏ khỏi album" removes from this album only (consistent with 10e3 subtitle "Bỏ khỏi album, đổi ai thấy…"); the share/options button presumably opens a sheet with more actions (e.g., change who sees selected items / download) — not shown in this frame.
- No confirmation dialog or toast copy in this frame.

## 181:360 — "10e9 Tải album về máy · Light" (Tải cả album về máy)

Purpose: bottom sheet confirming download of the whole album to the device's photo library.

Sheet text (reading order):
- `Tải về máy` — title "Download to device" (shorter than row label "Tải cả album về máy"); close X
- Summary card (layer "Summary"):
  - `15 mục · khoảng 180 MB` — "15 items · about 180 MB"
  - `Lưu vào album "Giờ tắm" trong app Ảnh của iPhone` — "Saves into an album "Giờ tắm" in the iPhone Photos app" (straight double quotes in source)
- Row (layer "Wifi") with Toggle ON:
  - `Chỉ tải qua Wi‑Fi` — "Download over Wi‑Fi only" (uses non-breaking hyphen in "Wi‑Fi")
  - `Video lớn sẽ đợi Wi‑Fi` — "Large videos will wait for Wi‑Fi"
- Primary button `Tải 15 mục` — "Download 15 items" (count dynamic)
- Footer caption `Tải ở nền — xong sẽ báo bạn.` — "Downloads in the background — you'll be notified when done."

States / rules:
- Wi‑Fi-only toggle default ON.
- Creates/saves into a same-named album in iOS Photos.
- Background download + completion notification; NO in-sheet progress bar/percentage shown in this frame (no progress copy).
- Size estimate is "khoảng" (approximate); 10e3 row subtitle breaks it down as `12 ảnh · 3 video · khoảng 180 MB`.

## 181:429 — "10e10 Xoá album · Light"

Purpose: confirmation bottom sheet for deleting an album (album only; media is kept).

Sheet text (reading order):
- `Xoá album 'Giờ tắm'?` — title "Delete album 'Giờ tắm'?" (text layer uses straight single quotes; renders like double quotes in screenshot — dev should normalise to typographic quotes “Giờ tắm”); close X
- Body: `15 ảnh và video vẫn còn ở tab Ảnh và Nhật ký. Chỉ album bị xoá.` — "15 photos and videos remain in the Ảnh (Photos) tab and Nhật ký (Journal). Only the album is deleted."
- Info row (layer "Who", family icon): `Gia đình sẽ không thấy album này nữa.` — "The family will no longer see this album." (variant shown for a Gia đình-visibility album; presumably omitted/different for Chỉ ba mẹ)
- Destructive button (red tinted) `Xoá album` — "Delete album"
- Plain text button `Huỷ` — "Cancel"

Rules:
- Deleting an album NEVER deletes memories: all items stay in the Ảnh tab and Nhật ký (consistent with 10e3 subtitle "Chỉ xoá album, ảnh vẫn còn trong Kỷ niệm").
- Album disappears for family members who could see it.
- No undo toast shown in this frame.

---

## Night spot-check

### 181:27615 — "10e6 Ai thấy album · Night care"
- Read via get_design_context. Copy IDENTICAL to Light 10e6: `Ai thấy album này`; `Chỉ ba mẹ` / `Chỉ ba mẹ xem được`; `Gia đình` / `Cả nhà cùng xem` (selected, check); note `Áp dụng cho cả 15 mục trong album` / `Ảnh thêm sau này cũng theo quyền của album. Người chăm không thấy Kỷ niệm.`; `Báo cho gia đình` / `1 thông báo chung, không kèm ảnh` (toggle ON); `Lưu`.
- No behavior differences. Theme is named "Night care" (frame suffix). Only visual: back/more glyphs on hero are very low-contrast under the night scrim (colors only).

### 181:28514 — "10e10 Xoá album · Night" (checked via screenshot only, to save rate-limit budget)
- Copy IDENTICAL to Light 10e10: `Xoá album "Giờ tắm"?`; `15 ảnh và video vẫn còn ở tab Ảnh và Nhật ký. Chỉ album bị xoá.`; `Gia đình sẽ không thấy album này nữa.`; `Xoá album` (destructive); `Huỷ`.
- No behavior differences.

---

## Cross-cutting rules extracted (for spec)

1. Delete album = album container only. Copy (2 places): 10e3 `Chỉ xoá album, ảnh vẫn còn trong Kỷ niệm` and 10e10 `15 ảnh và video vẫn còn ở tab Ảnh và Nhật ký. Chỉ album bị xoá.` Plus `Gia đình sẽ không thấy album này nữa.` when the album was Gia đình-visible.
2. Album visibility has exactly 2 values: `Chỉ ba mẹ` (lock icon) and `Gia đình` (family icon). Changing it applies to ALL items already in the album (`Áp dụng cho cả 15 mục trong album`) and to items added later (`Ảnh thêm sau này cũng theo quyền của album.`). Caregivers (`Người chăm`) never see Kỷ niệm. Optional single, photo-less family notification (`Báo cho gia đình`, default ON).
   - NOT covered in these frames: what happens to an item that is in multiple albums with different visibility (no copy about this). Flag as open question.
3. Favorites album `Yêu thích` is automatic and per-person private: pill `Chỉ mình bạn` (lock), subtitle `ảnh bạn đã đánh dấu`; tiles carry bookmark overlay (bookmark = favorite). Note: it shows `Chỉ mình bạn` — a third visibility label distinct from the album options (`Chỉ ba mẹ`/`Gia đình`), reserved for the auto favorites album. The design still shows the `Thêm ảnh` CTA and a `•••` button on this album (options for it not drawn).
4. Sort options (per album): `Mới nhất` (default, by capture time desc), `Cũ nhất`, `Mới thêm vào album`.
5. Download all: summary `15 mục · khoảng 180 MB`, saves into iPhone Photos album with the same name, `Chỉ tải qua Wi‑Fi` default ON (`Video lớn sẽ đợi Wi‑Fi`), CTA `Tải 15 mục`, background download with completion notification (`Tải ở nền — xong sẽ báo bạn.`). No progress UI drawn.
6. Selection mode: `Xong` exits; bar shows `N mục đã chọn`, share/options button (`Chia sẻ & tuỳ chọn`) and `Bỏ khỏi album` (remove from album only, does not delete media).
7. Rename: field `Tên album`, suggestions under `Gợi ý` as chips, CTA `Lưu tên`.
8. Cover: sheet title `Chọn ảnh bìa`, single-select from album items with live preview, CTA `Đặt làm ảnh bìa`.
9. Album detail floating bar: `Ai thấy` (icon reflects visibility: family vs lock), `Thêm ảnh` (primary), `Kể thành chuyện` (spark icon).

## Read status
- OK (get_design_context): 177:18, 177:425, 179:18, 180:18, 180:95, 180:356, 180:440, 181:18, 181:360, 181:429, 181:27615.
- OK (get_screenshot only): 181:28514.
- No separate annotation/sticky text boxes exist inside any of these frames; the only rule-like copy is the in-UI note/subtitle text captured above. The short descriptions in the task ("Chi tiết album", "Album Yêu thích (tự động)", "Nút ••• · tuỳ chọn album", "Tải cả album về máy") are canvas labels outside the frames and were not re-read.
- Rate-limited several times (Figma Pro per-minute cap); retried after waits — nothing lost.


---

# Batch C (10f–10o)

# D_raw / C — Section "10 · Kỷ niệm" (Memories), batch C (Light variants)

Figma file: sJLG1fAXKDnDr9YI6Yx8ex. Read-only transcription via get_design_context.

---

## 135:18156 — 10f Xem ảnh · Light ("Xem toàn màn hình")

**Purpose:** Fullscreen memory viewer (black background), swipeable through the memory's media, showing milestone, caption, meta and quick actions.

### Text (reading order)
- `9:41` / `•••` — status bar placeholder (not app copy).
- [Top-left round button, icon close / X] — Close viewer.
- `Gia đình` — "Family" (audience/visibility pill, top-right; layer "Audience"). Icon in the pill is the `Icon/today` placeholder (sun-like glyph), standing in for the "family" scope icon.
- [Photo, 420 px tall, full width]
- [Page dots: 5 dots; the 2nd is larger = current item 2 of 5]
- `★ Lần đầu cười` — "★ First smile" (milestone chip, sunshine/yellow; layer named "★ Lần đầu cười").
- `Teddy cười khi nghe ba hát bài ru quen.` — "Teddy smiled when hearing Dad sing a familiar lullaby." (caption, semibold 18)
- `Thứ Hai, 5 tháng 10 · Mẹ đăng · album Giờ tắm` — "Monday, 5 October · posted by Mom · album Bath time" (meta line: date · author · album)
- Action pills row (left→right):
  - `♥` `4` — heart "thương" reaction with count 4 (layer "Thương"; heart in peach colour = reacted/active look).
  - [bookmark icon] `Yêu thích` — "Favourite" (layer "Yêu thích"; bookmark icon = favourite).
  - `Tải về` — "Download" (layer name "Lưu về máy" = "Save to device").
  - `Chia sẻ` — "Share" (layer "Chia sẻ").

### Interactions / states
- Close (X) → back to memory feed/detail.
- Audience pill "Gia đình" → likely opens visibility/who-sees info or the scope picker (memory is visible to Family).
- Horizontal swipe between media (dots indicate 5 items; currently 2nd).
- ♥ Thương toggles love reaction; count 4 shown.
- Yêu thích toggles favourite (bookmark); appears not-selected (white icon, same pill style).
- Tải về → save to device (Photos).
- Chia sẻ → system share sheet (see 10o for "Chỉ ba mẹ" items).
- NOT present in this frame: Sửa (edit), Xoá (delete), Thông tin (info), video controls — no overflow/more menu button is drawn (the "•••" is only the status bar). No video playback UI in this Light frame (current item is a photo).

### Layer names of note
- "Audience" (scope pill), "Thương", "Yêu thích", "Lưu về máy" (Download), "Chia sẻ", "Dots", "Info", "Actions".
- Component note: Illustration/Photo = "Illustrated baby photo placeholder (privacy-safe)".

---

## 146:17006 — 10g Chọn ảnh nhanh · Light ("Chọn từ Thư viện ảnh (chọn nhiều)")

**Purpose:** In-app multi-select photo/video picker from the device Photo Library, with a bottom selection tray and count limit.

### Text (reading order)
- `Huỷ` — "Cancel" (top-left text button, mint).
- `Gần đây` — "Recent" (title, centre).
- Source filter chips:
  - `Gần đây` — "Recent" (SELECTED: dark/ink filled).
  - `Có Teddy` — "With Teddy" (photos containing the child — face/people album).
  - `Video` — "Videos".
  - `Album` — "Albums".
- Grid of 4-column media tiles (24 shown). Video tiles show a play-triangle badge with duration: `0:24` (selected), `0:41` (not selected).
- Selected tiles show a round check badge top-right (7 tiles checked: grid positions 2, 3, 5, 6 [video 0:24], 9, 10, 13).
- Bottom "Selection bar" sheet:
  - Selected strip: 7 thumbnails (one is the 0:24 video with mini badge).
  - `7 mục · 6 ảnh, 1 video` — "7 items · 6 photos, 1 video" (left).
  - `Tối đa 30 mục/lần` — "Max 30 items per time/batch" (right; business rule: up to 30 media per add).
  - Primary button: `Thêm 7 mục` — "Add 7 items" (count reflects selection).

### Interactions / states
- Huỷ → dismiss picker without adding.
- Chips switch source (Recent active by default).
- Tap tile toggles selection (check badge); order shown in tray strip.
- Thêm N mục → proceeds to 10h Soạn & chia sẻ (compose) with selected media.
- Rule: max 30 items per batch; counter shows mix of photos/videos.

### Layer names of note
- "Top bar", "Source", "Grid", "MediaTile" (with "Check", "Video" badge sublayers), "Selection bar", "Selected strip", "Info", "Primary".
- Button component description (design system): label = 1–2-word verb; primary h56 one per screen in thumb zone; disabled = 40% opacity.

---

## 158:21241 — 10h Soạn & chia sẻ · Light ("Soạn nhanh · chọn ai thấy & báo gia đình")

**Purpose:** Bottom sheet "Add to Memories" composed over the Nhật ký (journal/timeline) tab: shows selected media, optional caption, date/milestone/album rows, audience ("who sees") choice, notify-family toggle, and upload CTA.

### Background screen (dimmed by scrim, partially visible)
- BabySwitcher chip: `Teddy · 3 tuần` — "Teddy · 3 weeks" (baby name · age).
- Header actions: [sliders icon] (layer "View" — view/filter options), [+] (layer "Add", mint filled — add memory).
- `Nhật ký` — "Journal" (large title).
- Week group "Tuần thứ 3": `Tuần thứ 3` — "Week 3"; `1 – 8 tháng 10 · 9 ảnh, 2 video` — "1 – 8 October · 9 photos, 2 videos".
  - Milestone chip `★ Lần đầu cười · 5 thg 10` — "★ First smile · 5 Oct" (layer "★ Lần đầu cười · 5/10").
  - 6 media tiles; overlays: bookmark (Favorite) bottom-right on tiles 1 and 4; video badges `0:24`, `0:12`; lock badge top-left on tile 4 (layer "Private" = Chỉ ba mẹ item).
- Week group "Tuần thứ 2": `Tuần thứ 2` — "Week 2"; `24 – 30 tháng 9 · 6 ảnh` — "24 – 30 September · 6 photos".
  - Milestone chip `★ Ngày đầu về nhà · 20 thg 9` — "★ First day home · 20 Sep".
  - 3 tiles (tile 1 favourite bookmark).
- Floating memory tabs: `Nhật ký` (SELECTED; layer name "Dòng thời gian" = "Timeline"), `Ảnh` ("Photos"), `Album` ("Albums"), `Câu chuyện` ("Stories").
- TabDock/NavBar: Today (icon), `Kỷ niệm` ("Memories", ACTIVE), Family (icon), Me (avatar "M").

### Sheet text (reading order)
- `Thêm vào Kỷ niệm` — "Add to Memories" (sheet title) + close (X; component label "Đóng" = Close).
- Selected strip: 5 thumbnails + `+2` tile — "+2 more" (7 items total). Overlays: bookmark (favourite) on 1st and 5th thumbnails; video badge `0:24` on 4th.
- Caption field placeholder: `Viết vài dòng… (không bắt buộc)` — "Write a few lines… (optional)". No char counter shown.
- Details group (rows with chevron →):
  - [clock icon] `Ngày` — "Date" · value `Theo ngày chụp` — "By capture date" (default) → 10h2 Chọn ngày.
  - [star icon] `Mốc` — "Milestone" · value `Lần đầu cười` — "First smile" → 10h3 Chọn mốc.
  - [memories icon] `Album` — "Album" · value `Giờ tắm` — "Bath time" → 10h5 Chọn album.
- `Ai thấy` — "Who sees" (section label).
- Audience cards (2, side by side):
  - [lock icon] `Chỉ ba mẹ` — "Parents only" / `Chỉ ba mẹ xem được` — "Only parents can view". (unselected)
  - [family icon] `Gia đình` — "Family" / `Cả nhà cùng xem` — "The whole family views together". (SELECTED: mint border + mint-soft fill, mint title = DEFAULT in this frame)
- Notify row:
  - `Báo cho gia đình` — "Notify family"
  - `Gia đình nhận 1 thông báo` — "Family receives 1 notification" (i.e. one batched notification for the whole upload, not one per item)
  - Toggle: ON.
- Primary button: `Tải lên 7 mục` — "Upload 7 items".
- Footnote: `Ảnh tải ở nền — xong sẽ báo bạn.` — "Photos upload in the background — you'll be notified when done."

### Interactions / states
- Close X → dismiss sheet (back to Nhật ký).
- Thumbnails strip — review selection (+2 overflow tile).
- Ngày/Mốc/Album rows → sub-sheets 10h2/10h3/10h5.
- Audience: single choice between Chỉ ba mẹ and Gia đình; Gia đình selected in this frame. (Presumably the "Báo cho gia đình" row is only relevant when Gia đình is selected — not shown here; see 10h Night note if different.)
- Toggle Báo cho gia đình: ON → sends one notification to family.
- Tải lên 7 mục → enqueue upload (10i queue), background upload with completion notice (10j).

### Layer names of note
- "Sheet", "Body", "Selected", "+2", "Caption", "Details" with rows "Ngày", "Mốc", "Album"; "Audience" with cards "Chỉ ba mẹ" / "Gia đình"; "Notify"; tile overlays "Favorite" (Icon/bookmark), "Private" (Icon/lock), "Video".
- Floating tabs layer "Memory tabs (floating)", first tab layer "Dòng thời gian".
- BabySwitcher description: "avatar + name (+ chevron when the family has more than one baby). Shows whose log you are viewing."
- Toggle description: "iOS switch. On: mint-deep track. Off: separator track."

---

## 185:18 — 10h2 Chọn ngày · Light

**Purpose:** Sub-sheet from the compose sheet's "Ngày" row: choose the memory date mode — keep each photo's capture date, or one date for all (with date wheel).

### Background screen (dimmed, partially visible) — Nhật ký timeline WITH an in-progress upload pill
- `Teddy · 3 tuần`, sliders + add buttons, `Nhật ký` title.
- UploadPill (layer "UploadPill", mint-soft card, chevron →): thumbnail with dark overlay + progress ring; `Đang tải 4/7 mục` — "Uploading 4/7 items"; linear progress bar (~44% filled); `Cứ làm việc khác, xong sẽ báo bạn` — "Go do other things, we'll notify you when done". Tap → 10i queue.
- Week "Tuần thứ 3" · `1 – 8 tháng 10 · 13 ảnh, 3 video` — "1 – 8 October · 13 photos, 3 videos".
- Entry cards (layer names "Entry · 1 ảnh", "Entry · 1 video", "Entry · 2 ảnh", "Entry · ghi chú", "Entry · nhiều ảnh"):
  - av `M` · `Mẹ` · `Hôm nay · 9:20` · [family icon] — "Mom · Today · 9:20"; caption `Ngủ trưa ngon lành sau giờ tắm.` — "Napped soundly after bath time."; photo; [heart] `Bà nội, Ông ngoại thương` — "Paternal Grandma, Maternal Grandpa loved this".
  - av `B` · `Ba` · `Hôm qua · 19:05` · [family] — "Dad · Yesterday · 19:05"; `Lần đầu nắm chặt ngón tay ba.` — "First time tightly gripping Dad's finger."; video with centred play button + duration `0:42`; [heart] `2 lượt thương` — "2 loves".
  - `M` `Mẹ` `Thứ Ba, 6 thg 10` [family] — "Tuesday, 6 Oct"; `Bà nội sang thăm, mang theo đôi tất len tự đan.` — "Paternal grandma visited, bringing hand-knitted wool socks."; two photos.
  - Note entry (sunshine-soft card; layer "Entry · ghi chú" = text-only note): `M` `Mẹ` `Thứ Hai, 5 thg 10` [LOCK icon = Chỉ ba mẹ]; `Đêm qua con ngủ một mạch 4 tiếng. Mẹ dậy mà vẫn thấy lạ.` — "Last night baby slept 4 hours straight. Mom woke up and still found it strange."
  - `M` `Mẹ` `Thứ Hai, 5 thg 10` [family]; chip `★ Lần đầu cười · 5 thg 10`; grid of 6 tiles (video 0:24, favourite bookmark, lock "Private" badge, video 0:12, favourite).
- Week "Tuần thứ 2" · `24 – 30 tháng 9 · 6 ảnh`; entry `B` `Ba` `Chủ nhật, 20 thg 9` [family]; chip `★ Ngày đầu về nhà · 20 thg 9`; 3 tiles.
- Floating tabs `Nhật ký` (active) / `Ảnh` / `Album` / `Câu chuyện`; NavBar `Kỷ niệm` active.

### Sheet text
- `Ngày của kỷ niệm` — "Date of the memory" (title) + close X.
- Option rows (radio, single-select):
  - `Theo ngày chụp` — "By capture date" / `Mỗi ảnh giữ ngày riêng · 5 – 8 thg 10` — "Each photo keeps its own date · 5 – 8 Oct" (range of the selected media's dates). SELECTED (default).
  - `Một ngày cho tất cả` — "One date for all" / `Dùng khi ngày chụp bị sai` — "Use when the capture date is wrong". Unselected.
- DateWheel (Day · Month · Year) — DISABLED (40% opacity) while "Theo ngày chụp" is selected; enabled when "Một ngày cho tất cả" chosen. Values: days `6 7 [8] 9 10`; months `Tháng 8, Tháng 9, [Tháng 10], Tháng 11, Tháng 12`; years `2024, 2025, [2026], 2027, 2028`. Selected = 8 Tháng 10 2026.
- Helper: `Không chọn được ngày trước khi Teddy chào đời.` — "Can't pick a date before Teddy was born." (rule: min date = baby's birth date).
- Primary: `Xong` — "Done".

### Rules / notes
- DateWheel component description: native iOS picker in production; "default = today, cannot pick a future date". Combined with helper text: valid range = [birth date, today].
- Xong → returns to 10h with the chosen Ngày value.

---

## 185:260 — 10h3 Chọn mốc · Light ("có sẵn & tự tạo")

**Purpose:** Sub-sheet from compose "Mốc" row: tag the memory with one milestone — age-based suggestions (preset), family-created custom milestones, or create new.

### Background: same Nhật ký timeline with UploadPill `Đang tải 4/7 mục` (as 10h2), dimmed.

### Sheet text (reading order)
- `Gắn mốc` — "Tag a milestone" (title) + close X.
- Search field [search icon] placeholder: `Tìm hoặc gõ mốc mới…` — "Search or type a new milestone…" (typing a non-existent name can create a new one).
- Section: `Gợi ý cho bé 3 tuần` — "Suggestions for a 3-week-old baby" (age-dependent preset list).
- Preset suggestion chips (each with star icon), FULL list in order:
  1. `Lần đầu cười` — "First smile" — SELECTED (ink/dark filled, white text).
  2. `Lần đầu tắm` — "First bath"
  3. `Ngẩng đầu` — "Lifts head"
  4. `Lần đầu đi dạo` — "First stroll/outing"
  5. `Đầy tháng` — "One-month celebration (full month)"
  6. `Lần đầu gặp ông bà` — "First time meeting grandparents"
- Section: `Mốc nhà mình đã tạo` — "Milestones our family created" (custom, shared within family).
  - `Ngày đầu về nhà` — "First day home"
  - `Lần đầu nắm tay ba` — "First time holding Dad's hand"
- Dashed button [+]: `Tạo mốc mới` — "Create new milestone" → 10h4.
- Clear row: `Không gắn mốc` — "No milestone" (left, tap to clear) · `Mỗi kỷ niệm 1 mốc` — "One milestone per memory" (right; business rule).
- Primary: `Xong` — "Done".

### Interactions / states
- Single-select chips (one milestone per memory). Selected = filled dark chip.
- Search filters both lists; typing new text → create.
- Tạo mốc mới → 10h4 Tạo mốc mới.
- Không gắn mốc → clears milestone.
- Xong → back to 10h with Mốc value.

### Layer names
- "Search", "Suggest" (preset group), "Own" (family-created group), "Tạo mốc mới", "Clear".

---

## 185:461 — 10h4 Tạo mốc mới · Light

**Purpose:** Short sheet to create a custom (family-shared) milestone and immediately tag it on the memory.

### Background: same Nhật ký timeline with UploadPill `Đang tải 4/7 mục` / `Cứ làm việc khác, xong sẽ báo bạn` (as 10h2), dimmed.

### Sheet text (reading order)
- `Tạo mốc mới` — "Create new milestone" (title) + close X.
- Text field (standalone): label `Tên mốc` — "Milestone name"; value `Lần đầu lật người` — "First time rolling over". (No char counter shown.)
- Row [clock icon] `Ngày` — "Date" · value `Hôm nay` — "Today" · chevron → (opens date picker; default today).
- Preview: `Xem trước` — "Preview" + sunshine chip [star] `Lần đầu lật người · hôm nay` — "First time rolling over · today".
- Helper: `Mốc mới được lưu cho cả nhà dùng lại lần sau.` — "The new milestone is saved for the whole family to reuse next time." (rule: custom milestones shared across family; they appear under "Mốc nhà mình đã tạo" in 10h3).
- Primary: `Tạo & gắn mốc` — "Create & tag milestone".

### Interactions / states
- Custom milestone fields = name + date (default Hôm nay). Preview chip format "<name> · <date>".
- Tạo & gắn mốc → saves milestone to family list, selects it, returns to 10h3/10h.
- Close X → back to 10h3.

### Layer names
- "TextField" (label "Tên mốc"), "Date", "Preview", "chip".

---

## 185:639 — 10h5 Chọn album · Light

**Purpose:** Sub-sheet from compose "Album" row: add the memory to one or more albums, or create a new album.

### Background: same Nhật ký timeline with UploadPill `Đang tải 4/7 mục` / `Cứ làm việc khác, xong sẽ báo bạn`, dimmed.

### Sheet text (reading order)
- `Thêm vào album` — "Add to album" (title) + close X.
- Mint-soft row [+]: `Tạo album mới` — "Create new album" (layer "Album mới").
- Album list (layer "Albums"; each row: cover thumb, name, scope icon + counts, round check):
  - `Giờ tắm` — "Bath time" · [family icon] `12 ảnh · 3 video` — "12 photos · 3 videos" — CHECKED (filled mint check).
  - `Ngủ ngoan` — "Sleep tight" · [LOCK icon] `28 ảnh · 1 video` — "28 photos · 1 video" — unchecked. (Lock = album is Chỉ ba mẹ / private.)
  - `Bàn tay nhỏ` — "Little hands" · [family icon] `9 ảnh` — "9 photos" — unchecked.
- Helper: `Có thể chọn nhiều album. Ảnh vẫn theo quyền "Ai thấy" bạn đã chọn.` — "You can pick multiple albums. Photos still follow the 'Who sees' permission you chose." (rule: album membership does not change item visibility; multi-select).
- Primary: `Xong` — "Done".

### Interactions / states
- Multi-select checkboxes (round check style); Giờ tắm checked by default (matches 10h value).
- Tạo album mới → create album flow (not in this batch).
- Album scope icons: family = shared with family; lock = parents-only album.
- Xong → back to 10h with Album value (presumably shows first album name / count when multiple).

### Layer names
- "Album mới", "Albums", rows named by album ("Giờ tắm", "Ngủ ngoan", "Bàn tay nhỏ"), "ck" (check), "m" (meta).

---

## 158:21349 — 10i Hàng đợi tải lên · Light ("Hàng đợi · lỗi, chờ Wi‑Fi, thử lại")

**Purpose:** Upload queue sheet (opened from the UploadPill on Nhật ký): overall progress, pause, per-item states, Wi‑Fi rule toggle, retry all.

### Background (dimmed): Nhật ký with UploadPill `Đang tải 4/7 mục` / `Cứ làm việc khác, xong sẽ báo bạn` (pill thumbnail has progress ring + favourite badge); Week 3 `1 – 8 tháng 10 · 9 ảnh, 2 video`, chip `★ Lần đầu cười · 5 thg 10`; Week 2 `24 – 30 tháng 9 · 6 ảnh`, chip `★ Ngày đầu về nhà · 20 thg 9`; floating tabs; NavBar Kỷ niệm active.

### Sheet text (reading order)
- `Đang tải lên` — "Uploading" (title) + close X.
- Summary card:
  - `4/7 mục · còn khoảng 1 phút` — "4/7 items · about 1 minute left"
  - Pill button `Tạm dừng` — "Pause" (layer "Pause"; when paused presumably becomes "Tiếp tục" — not shown).
  - Progress bar (~55%).
  - `Gia đình sẽ được báo khi tải xong` — "Family will be notified when the upload finishes" (ties to Báo cho gia đình toggle in 10h).
  - [red dot] `2 mục lỗi · 1 tệp không đọc được` — "2 items failed · 1 file unreadable" (layer "Errors").
- Queue rows (layer "QueueRow"; thumbnail + filename + status + action):
  1. `IMG_2041.HEIC` — status `62% · 2,1 MB/3,4 MB` — "62% · 2.1 MB/3.4 MB" (UPLOADING; progress ring on thumb; mint status text) — action [X] (cancel/remove; layer "Action").
  2. `IMG_2043.MOV` — status `Chờ Wi-Fi · video 48 MB` — "Waiting for Wi‑Fi · video 48 MB" (WAITING_WIFI; ring on thumb) — action [X].
  3. `IMG_2044.HEIC` — status `Mất kết nối khi đang tải` — "Lost connection while uploading" (FAILED, retryable; red "!" on thumb) — action pill [retry icon] `Thử lại` — "Retry" (layer "Retry").
  4. `IMG_2047.MOV` — status `Mất kết nối khi đang tải` (FAILED, retryable) — `Thử lại`.
  5. `IMG_2050.HEIC` — status `Tệp bị lỗi · không thử lại được` — "File is corrupt · cannot retry" (UNREADABLE/CORRUPT; red "!") — action [X] (layer "Remove").
- Wi‑Fi row (toggle ON):
  - `Video chỉ tải qua Wi‑Fi` — "Videos upload over Wi‑Fi only"
  - `Ảnh vẫn tải bằng dữ liệu di động` — "Photos still upload over mobile data"
- Secondary button [retry icon] `Thử lại tất cả (2)` — "Retry all (2)" (count = retryable failed items).
- Footnote: `Mục lỗi được giữ trên máy · tự thử lại khi có mạng.` — "Failed items are kept on the device · automatically retried when back online."

### States / rules captured
- Item states: uploading (% + bytes), waiting for Wi‑Fi (video, size shown), failed-retryable (connection lost → Thử lại), corrupt/unreadable (no retry → remove only). DONE and PAUSED item states are NOT drawn in this frame.
- Cellular rule: video waits for Wi‑Fi when toggle ON (default ON); photos use cellular.
- No explicit size/duration limits shown here (only file sizes: 3,4 MB photo, 48 MB video).
- Note the error summary count "2 mục lỗi" = the 2 retryable failures; "1 tệp không đọc được" = the corrupt one.
- Global: Tạm dừng pauses all; Thử lại tất cả retries retryable failures; auto-retry on reconnect.

### Layer names
- "Summary", "Pause", "Bar", "Errors", "Queue", "QueueRow", "Action" (X), "Retry", "Remove", "Wifi".

---

## 149:17761 — 10j Màn hình khoá · đang tải nền · Light ("Khoá máy · tải nền & báo xong")

**Purpose:** iOS lock screen while uploading in background: a Live Activity showing progress plus a push notification about a video waiting for Wi‑Fi.

### Text (reading order)
- `Thứ Năm, 8 tháng 10` — "Thursday, 8 October" (lock-screen date)
- `9:41` (lock-screen clock)
- Notification card (layer "Notification"; app icon):
  - `Child Life` (app name) · `2 phút trước` — "2 minutes ago"
  - Title: `1 video đang chờ Wi‑Fi` — "1 video is waiting for Wi‑Fi"
  - Body: `Ảnh vẫn đang tải. Video sẽ tự tải khi có Wi‑Fi.` — "Photos are still uploading. The video will upload automatically when Wi‑Fi is available."
- Live Activity card (layer "LiveActivity/Upload"):
  - Header: [app icon] `Child Life` · `Kỷ niệm của Teddy` — "Teddy's memories"
  - [upload icon] `Đang tải 4/7 mục` — "Uploading 4/7 items"; sub `Xong sẽ báo bạn` — "We'll notify you when done"; right `57%`
  - Progress bar (~57%).
- Annotation-ish caption on wallpaper: `Không kèm ảnh trên màn hình khoá` — "No photos attached on the lock screen" (privacy rule: lock-screen notifications/Live Activity must not include photo thumbnails; only text + app icon).

### Notes / not shown
- The "báo xong" (upload-complete) notification copy is NOT drawn in this frame; only in-progress Live Activity and the waiting-for-Wi‑Fi notification. Completion copy implied by "Xong sẽ báo bạn".
- No interactive buttons on Live Activity (tap presumably opens app → 10i queue).

### Layer names
- "LiveActivity/Upload" (hd, main, Bar), "Notification", Logo/App Icon.

---

## 150:17772 — 10k Chia sẻ từ app Ảnh · Light ("share extension")

**Purpose:** iOS Share Extension sheet shown over the system Photos app when the user shares photos to Child Life — a minimal compose: pick baby, who sees, notify family, then add (upload in background).

### Text (reading order)
- (Background: Photos app showing a photo, dimmed; status bar 9:41.)
- Top bar: `Huỷ` — "Cancel" (left) · `Thêm vào Kỷ niệm` — "Add to Memories" (title) · `Thêm` — "Add" (right, semibold = confirm).
- Items: 3 thumbnails (1st has favourite bookmark overlay) + `3 ảnh từ app Ảnh` — "3 photos from the Photos app".
- Baby row: `Bé` — "Baby" · value `Teddy` · chevron-down (dropdown to choose which baby, for multi-baby families).
- `Ai thấy` — "Who sees"
- Audience chips (single-select):
  - [lock] `Chỉ ba mẹ` — "Parents only" (unselected)
  - [family] `Gia đình` — "Family" — SELECTED (dark/ink filled)
- Notify row: `Báo cho gia đình` — "Notify family" / `Gửi 1 thông báo khi tải xong` — "Send 1 notification when the upload finishes" — Toggle ON.
- Footnote: `Ảnh tải ở nền — xong sẽ báo bạn.` — "Photos upload in the background — you'll be notified when done."

### Behavior notes
- Share extension omits caption, date, milestone, album fields (date presumably = capture date by default; those can be edited later in-app). Only Baby, Ai thấy, Báo cho gia đình.
- Defaults: Gia đình selected; notify ON.
- Thêm → enqueue to background upload (10i/10j); Huỷ → dismiss extension.
- Notification copy differs slightly from 10h: here "Gửi 1 thông báo khi tải xong" vs 10h "Gia đình nhận 1 thông báo" (both = one batched notification sent after upload completes).

### Layer names
- "Share extension", "Top", "Items", "Baby", "Audience" ("Chỉ ba mẹ", "Gia đình"), "Notify".

---

## 158:21457 — 10o Chia sẻ mục "Chỉ ba mẹ" · Light ("Chia sẻ mục riêng tư · ai sẽ thấy")

**Purpose:** Confirmation sheet when the parent selects private ("Chỉ ba mẹ") items and chooses to share them with family: shows who will gain access, who still won't, and a notify toggle.

### Background (dimmed): Ảnh (Photos) tab of Kỷ niệm
- `Teddy · 3 tuần`, sliders + add.
- `Ảnh` — "Photos" (large title).
- Filter row: `Tất cả` — "All" (SELECTED), `Tháng ▾` — "Month ▾" (dropdown), [check] `Chọn` — "Select" (enter multi-select mode).
- Section `Tháng 10, 2026` — "October 2026" · `32 ảnh · 4 video` — "32 photos · 4 videos".
- Grid of 82px tiles with overlays: bookmark (favourite), video badges `0:24`, `0:12`, lock badges (private).
- Section `Tháng 9, 2026` — "September 2026" · `94 ảnh · 5 video` — "94 photos · 5 videos".
- Floating date scrubber pill: `Th 10, 2026` + chevron-down — "Oct 2026" (jump-to-date; layer "Date scrubber").
- Floating tabs: `Nhật ký`, `Ảnh` (ACTIVE), `Album`, `Câu chuyện`. NavBar `Kỷ niệm` active.

### Sheet text (reading order)
- `Chia sẻ với gia đình?` — "Share with family?" (title) + close X.
- Items: 3 thumbnails each with LOCK badge (3rd also favourite bookmark) + `3 ảnh riêng tư` — "3 private photos".
- Section: `Sẽ thấy sau khi chia sẻ` — "Will see after sharing".
- People card (layer "People"; row layer named "Bà nội"):
  - Avatar `G` · `Gia đình` — "Family" / `2 người thân` — "2 relatives" · [eye icon] (= will be able to view).
- [lock icon] `Người chăm (Cô Lan) không thấy Kỷ niệm.` — "The caregiver (Ms. Lan) does not see Memories." (rule: caregiver role has no access to Memories at all, even after sharing).
- Notify row: `Báo cho gia đình` — "Notify family" / `Gửi 1 thông báo chung, không kèm ảnh` — "Send 1 general notification, without photos attached" — Toggle ON.
- Primary: `Chia sẻ 3 ảnh` — "Share 3 photos".
- Plain/text button: `Để sau` — "Later" (dismiss without sharing).

### What sharing changes (10o)
- Changes the items' visibility from Chỉ ba mẹ (lock) → Gia đình: family members (here 2 relatives) gain view access; lock badges would be removed.
- Caregiver (Người chăm) still excluded — Memories are not visible to caregiver role.
- Optional single batched notification to family, with no photo preview in the notification (privacy).

### Layer names
- "Month filter" ("Tất cả", "Tháng 10" [label shows "Tháng ▾"], "Chọn"), "Date scrubber", "Sheet", "Items", "People" > "Bà nội", "Not" (who won't see), "Notify".

---

## Night spot-check

### 178:28165 — 10i Hàng đợi tải lên · Night care
- Frame is named "Night care" (night theme variant).
- Copy: IDENTICAL to Light 10i (title, summary `4/7 mục · còn khoảng 1 phút`, `Tạm dừng`, `Gia đình sẽ được báo khi tải xong`, `2 mục lỗi · 1 tệp không đọc được`, all 5 queue rows and statuses, `Video chỉ tải qua Wi‑Fi` / `Ảnh vẫn tải bằng dữ liệu di động` toggle ON, `Thử lại tất cả (2)`, footnote). Same states, same actions, same toggle default.
- Behavior: no differences.
- Defect to flag (legibility, not palette choice): the waiting row status `Chờ Wi-Fi · video 48 MB` keeps the Light "on-warm" dark-ink text token in Night, so it renders nearly invisible on the dark sheet. Implementation should use a readable (warning/muted) token for the waiting-for-Wi‑Fi status in dark mode.

### 178:27859 — 10h Soạn & chia sẻ · Night care
- Copy: IDENTICAL to Light 10h sheet (`Thêm vào Kỷ niệm`, `+2`, `Viết vài dòng… (không bắt buộc)`, `Ngày`/`Theo ngày chụp`, `Mốc`/`Lần đầu cười`, `Album`/`Giờ tắm`, `Ai thấy`, `Chỉ ba mẹ`/`Chỉ ba mẹ xem được`, `Gia đình`/`Cả nhà cùng xem` (selected), `Báo cho gia đình`/`Gia đình nhận 1 thông báo` (toggle ON), `Tải lên 7 mục`, `Ảnh tải ở nền — xong sẽ báo bạn.`).
- Defaults/states: same (Gia đình selected, notify ON).
- Background difference: same journal list; header/background identical copy. No behavior difference.

---

## Cross-screen summary of rules (from this batch)
- Memory fields: media (≤30 per add; photos + videos), caption (optional, placeholder "Viết vài dòng… (không bắt buộc)"), date (default "Theo ngày chụp" = per-item capture date; alt "Một ngày cho tất cả"; range birth date → today), milestone (one per memory; age-based presets + family-created custom; "Không gắn mốc"), album (multi-select; does not change visibility), who sees (Chỉ ba mẹ | Gia đình; default Gia đình in all compose frames), notify family (toggle default ON; 1 batched notification; no photos in notification).
- Milestone presets shown for a 3-week-old: Lần đầu cười, Lần đầu tắm, Ngẩng đầu, Lần đầu đi dạo, Đầy tháng, Lần đầu gặp ông bà. Family-created examples: Ngày đầu về nhà, Lần đầu nắm tay ba. Custom milestone = name + date (default Hôm nay), shared to whole family.
- Upload: background upload with in-app UploadPill ("Đang tải N/M mục" + "Cứ làm việc khác, xong sẽ báo bạn"), queue sheet with pause, per-item cancel/retry/remove, video Wi‑Fi-only toggle (default ON; photos use cellular), auto-retry when online, failed items kept on device. Lock screen: Live Activity with % and no photo previews; notification for video waiting Wi‑Fi.
- Roles: caregiver ("Người chăm") never sees Memories; Chỉ ba mẹ items/albums show a lock; family-visible items show a family icon in entry header.
- Icons: lock = Chỉ ba mẹ; family (two people) = Gia đình; bookmark = Yêu thích (favourite); heart/♥ = Thương (love reaction); star ★ = milestone; play ▶ + duration = video.
- NOT present in this batch's frames: viewer actions Sửa / Xoá / Thông tin, video player controls, upload "done"/"paused" item states, explicit size/duration limits, completion notification copy.
