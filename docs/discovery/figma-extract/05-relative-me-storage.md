# E · Relative view (§11) + Tab Tôi / Storage / Baby profiles (§13)

Source: Figma `sJLG1fAXKDnDr9YI6Yx8ex`, page Screens `26:2`. Read-only. Extracted 2026-10-10.

## How each frame was read (important for confidence)

| Frame | Method | Confidence |
|---|---|---|
| 188:835, 151:18383, 152:17833, 187:29763, 187:30126, 188:472, 188:680, 188:729, 208:36344 (all of §11 Light) | `get_design_context` (full text + screenshot) | Full |
| 194:78 Tôi·Ba/Mẹ, 194:164 Dung lượng | `get_design_context` | Full |
| 194:267, 194:377, 195:18, 195:177, 197:286, 197:391, 199:83, 199:168, 199:292, 199:385, 199:501, 199:602 | **Figma MCP hit the plan limit** after 13 calls ("You've reached the Figma MCP tool call limit for your Full seat on the Professional plan"; `whoami` = Pro / Full seat, admin). Fell back to the cached page metadata `_screens_meta.xml`. In that file text layer names are **cut off at about 30 characters**, and text inside component instances (Button labels, TopBar title, DetailRow, Segmented, TextField, UploadPill, SheetHeader) is missing. | Partial. Text cut off by the metadata is marked `…[cut]`. |
| Night-care variants (188:31843…, 197:35xxx, 199:35775…) | Not read through MCP (limit). The metadata shows the same structure and node counts as Light, so only colours differ (inferred). | Inferred |

**Re-read these when the quota resets:** 194:267, 194:377, 195:18, 195:177, 199:83, 199:168, 199:292, 199:385, 199:501, 199:602 (and 197:286/197:391 to check button text). They hold the missing full sentences, button labels and the sign-out and delete-account behaviour.

---

## §11 · Người thân xem gì khi được chia sẻ (what a relative sees when content is shared)

Section header text node 187:18. The labels above each frame are design notes. Quoted exactly:
- 11a "Quy tắc: thấy · không thấy · làm được" (rules: sees · doesn't see · can do)
- 11b "Thông báo · chung chung, không ảnh" (notification: generic, no photo)
- 11c "Nhật ký · chỉ mục “Gia đình”" (journal: only items marked "Family")
- 11d "Ảnh · không có nút + / Chọn" (photos: no + / Select buttons)
- 11e "Album · chỉ album được chia sẻ" (albums: shared albums only)
- 11f "Chi tiết album · chỉ Thương & Tải về" (album detail: Love & Download only)
- 11g "Xem ảnh · Thương, Yêu thích, Tải về, Nhắn" (photo viewer: Love, Favorite, Download, Message)
- 11h "Chưa có gì được chia sẻ" (nothing shared yet)
- 11i "Đọc câu chuyện · Thương & Nhắn ba mẹ" (read story: Love & Message parents)

### Relative navigation (all §11 screens)
- The TabDock has **3 tabs**: Kỷ niệm (Memories, active, labelled) · Gia đình (Family, icon only) · Tôi (Me, avatar initial "H" for Bà nội Hoa).
- There is **no Today/care tab and no QuickLog "+" button** (compare 194:78, where the parent has Today · Memories · Family · Me + the "+" button). This matches section 7b "Người thân · 2 tab · vào Kỷ niệm" (relative · 2 tabs · lands in Memories).
- The 7b label says "2 tab" but the §11 dock shows 3 icons (Memories, Family, Me). Possibly Me is not counted as a tab. **Gap: check this.**
- A floating Memories sub-tab bar holds: **Nhật ký · Ảnh · Album · Câu chuyện** (Journal · Photos · Albums · Stories). It is the same as the parent's bar.
- The BabySwitcher chip "Teddy · 3 tuần" shows a chevron, so a relative can switch between babies they follow. Component description: "chevron when the family has more than one baby".

### 188:835 · 11a Người thân thấy gì · quy tắc (rules card, VERBATIM)
Title: **"Người thân thấy gì?"** (What does a relative see?)

**✓ Thấy (Sees)**
- "• Ảnh, video, ghi chú ba mẹ chọn “Gia đình”" (photos, videos and notes that parents set to "Family")
- "• Album và câu chuyện được chia sẻ" (shared albums and stories)
- "• Mốc gắn trên các mục đó" (milestones tagged on those items)
- "• Lượt thương của cả nhà" (the whole family's Loves)

**✕ Không thấy (Doesn't see)**
- "• Mục “Chỉ ba mẹ” và album riêng tư" (items set to "Parents only" and private albums)
- "• Bú, ngủ, tã, tăng trưởng (trừ khi ba mẹ bật lúc mời)" (feeding, sleep, diapers, growth, unless parents turned this on when inviting)
- "• Yêu thích của ba mẹ, hàng đợi tải lên, dung lượng" (parents' favourites, the upload queue, storage)

**♡ Làm được (Can do)**
- "• Thương, đánh dấu Yêu thích của riêng mình" (Love; mark their own private Favorites)
- "• Tải ảnh về máy, nhắn ba mẹ" (download photos to the device; message the parents)
- "• Không thêm, sửa, xoá hay đổi “Ai thấy”" (cannot add, edit, delete or change "Who sees")

Related, from section 12 metadata (caregiver rules 195:32740, one line cut off): "• Ngày sinh và hồ sơ đầy đủ củ…[cut]" (birth date and full profile of…). Relatives get the same treatment from the baby-profile side: see 199:292, "Người thân chỉ thấy tên thân mật" (relatives only see the nickname).

### 151:18383 · 11b Thông báo trên màn hình khoá (lock-screen notification)
Purpose: show that family-share push notifications are **generic and carry no photo**.
- Caption above the notifications: **"Không kèm ảnh · chỉ báo chung chung"** (no photo attached · generic alert only)
- Notification 1: title "Child Life" · time "bây giờ" (now) · **"Có 7 khoảnh khắc mới"** (7 new moments) / **"Mai vừa chia sẻ với gia đình. Mở để xem."** (Mai just shared with the family. Open to view.)
- Notification 2: "Child Life" · "Hôm qua" (yesterday) · **"Có 1 câu chuyện mới"** (1 new story) / **"Từ Kỷ niệm của gia đình"** (from the family's Memories)
- Rules: one notification per share batch, with a count and the sharer's first name. No baby name and no image. Stories get their own notification. Tapping opens the app (inferred: lands on Memories → Journal).

### 152:17833 · 11c Nhật ký người thân (relative's journal)
- Header: BabySwitcher "Teddy · 3 tuần"; title **"Kỷ niệm"**; subtitle **"Những gì ba mẹ chia sẻ với gia đình"** (what the parents share with the family)
- "New share" card:
  - Avatar "M"; **"Mai chia sẻ 7 khoảnh khắc mới"** (Mai shared 7 new moments); "Hôm nay · 9:41"; badge **"Mới"** (New)
  - Photo mosaic: 1 large + 2 small, with a "+4" overflow
  - Milestone chip ★ "Lần đầu cười" (first smile)
  - Caption "“Teddy cười khi nghe mẹ hát.”"
  - Actions: **[♡ Thương]** (peach pill) · **[✉ Nhắn ba mẹ]** (mail icon, "message parents")
- Section **"Tuần trước"** (last week): media tiles. One tile shows the **bookmark (Favorite) badge**, so the relative's own favourites are marked on tiles.
- No "+", no Select, no edit controls.

### 187:29763 · 11d Ảnh · người thân (relative's photos)
- Title "Ảnh". Filter chips: **"Tất cả"** (All, active) · **"Tháng ▾"** (Month).
- Month headers with counts: "Tháng 10, 2026 · 24 ảnh · 3 video"; "Tháng 9, 2026 · 61 ảnh · 4 video".
- 4-column grid. Video tiles show a duration badge ("0:24", "0:12"). A floating date scrubber chip shows "Th 10, 2026 ⌄".
- **Unlike the parent's Photos view there is no "+" (add) and no "Chọn" (select) button.** The section label says so: "không có nút + / Chọn".

### 187:30126 · 11e Album · người thân (relative's albums)
- Title "Album"; subtitle **"2 album ba mẹ chia sẻ"** (2 albums the parents shared).
- Album cards:
  - "Giờ tắm · 12 ảnh · 3 video" (bath time)
  - "Bàn tay nhỏ · 9 ảnh" (little hands)
  - **"Yêu thích · 6 ảnh · của riêng bạn"**: the relative's PRIVATE Favorites album ("yours only"). It appears automatically and is not counted in "2 album ba mẹ chia sẻ".
- Section **"Gom từ mốc bạn đã gắn"** ("gathered from milestones *you* tagged"): ★ Lần đầu cười · ★ Ngày về nhà · ★ Tròn 3 tuần.
  - **Gap:** relatives cannot tag milestones, so "bạn đã gắn" (you tagged) is probably copy reused from the parent screen. Suggest "Gom theo mốc" (grouped by milestone) for relatives. Treat it as milestone collections built only from items the relative can see (inferred).
- No "create album" control.

### 188:472 · 11f Chi tiết album · người thân (album detail)
- Hero: "Giờ tắm" / **"12 ảnh · 3 video · cập nhật hôm qua"** (updated yesterday) / chip ⚇ **"Mẹ chia sẻ với gia đình"** (Mum shared with the family).
- Back button. 3-column grid with video badges.
- Floating action bar with exactly two actions:
  - **[♡ Thương]**: Love the *album*. Layer name "Thương album".
  - **[↓ Tải về]**: download, presumably the whole album (inferred).
- No "…" menu, no edit/share/"Ai thấy" (who sees) controls.

### 188:680 · 11g Xem ảnh · người thân (full-screen photo viewer)
- Close (✕) top-left. Pager dots (5).
- Milestone chip **"★ Lần đầu cười"**; caption **"Teddy cười khi nghe ba hát bài ru quen."**; meta **"Thứ Hai, 5 tháng 10 · Mẹ chia sẻ"** (Monday, 5 October · shared by Mum).
- Action pills:
  1. **"♥ 4"**: Love + total count (whole family's loves, per the rule "Lượt thương của cả nhà"). Filled peach heart = this user has loved it.
  2. **"🔖 Yêu thích"**: Favorite, private to this user, uses the bookmark icon.
  3. **"Tải về"** (layer name "Lưu về máy" = save to device).
  4. **"Nhắn"** (layer name "Nhắn ba mẹ" = message parents).
- No edit, delete, share-out or "Ai thấy".
- Parent-side reaction display (10a, from metadata): "2 lượt thương" (2 loves) and **"Bà nội, Ông ngoại thương"** (Grandma, Grandpa loved this). So Love is **non-anonymous**: parents see who loved.

### 188:729 · 11h Chưa có gì được chia sẻ (empty state)
- Title "Kỷ niệm"; Illustration/Family with chips "Bạn chọn quyền" / "Mời người thân".
- **"Chưa có kỷ niệm nào được chia sẻ"** (no memories shared yet)
- **"Khi ba mẹ chia sẻ ảnh với gia đình, bạn sẽ nhận một thông báo và thấy ở đây."** (When the parents share photos with the family, you'll get a notification and see them here.)
- No call to action.
- The illustration is a shared component that shows "Mời người thân" (invite relatives) and "Bạn chọn quyền" (you choose permissions). Those are parent-side concepts and are not tappable here (inferred).

### 208:36344 · 11i Đọc câu chuyện (read a story, relative)
- Back button. Hero photo.
- Meta ⚇ **"Mẹ chia sẻ với gia đình · hôm nay"** (Mum shared with the family · today).
- Title (Lora serif) **"Tuần Teddy biết cười"** (the week Teddy learned to smile).
- Milestone chip "Lần đầu cười · 5 thg 10".
- Body paragraphs, a 2-photo row and a pull quote "“Như thể con cũng thuộc lời ru ấy.”"
- **Reply bar (sticky bottom):**
  - **[♡ Thương · 4]**
  - text field placeholder **"Nhắn ba mẹ…"** (message the parents…) with a send arrow (→)
  - So "Nhắn" is an **inline text composer inside the app**, not a share sheet.

### What "Nhắn / Nhắn ba mẹ" does. Evidence:
1. 11i shows an in-app text input "Nhắn ba mẹ…" with a send arrow → the user writes a message in the app.
2. 11c uses the mail icon (Icon/mail) and 11g uses a plain "Nhắn" pill.
3. Searching all of Screens metadata: **"Zalo" and "Messenger" appear ONLY in 14j "Thiệp · gửi đi" (208:312)**, the story-card OS share sheet. They never appear near "Nhắn".
4. **No chat or thread screen, inbox, or parent-side "tin nhắn" (messages) view exists anywhere in Screens.** No notification copy for "X nhắn…" (X sent a message) exists either.
- **Conclusion (inferred):** this is an in-app private note or reply from the relative to the baby's parents, tied to one memory or story. It is a one-way reply, not a chat app, and does **not** deep-link to an external messenger. **Not designed:**
  - where parents read these messages
  - push notification copy for a received message
  - whether parents can reply
  - whether all parents or only the sharer receive it
  - what the 11c/11g "Nhắn" tap opens: probably the same composer as 11i, as a sheet (inferred)
  
  **Open question, high priority.**

### Reactions ("Thương") semantics
- A single reaction type, Love. It works on individual items/entries (11c, 11g), **whole albums** (11f "Thương album") and stories (11i).
- Shows a count ("♥ 4", "Thương · 4"). The rules say everyone sees "Lượt thương của cả nhà" (the family's loves). The parent timeline shows who loved ("Bà nội, Ông ngoại thương").
- Toggle on/off per user (inferred).

### Private favorites
- "đánh dấu Yêu thích của riêng mình" (mark one's own Favorites). Shown as a bookmark badge on tiles and as an auto album "Yêu thích · N ảnh · của riêng bạn".
- Parents' favourites are invisible to relatives ("Yêu thích của ba mẹ" listed under Không thấy). So favourites are stored **per user**, not per item.

### Download rights
- Relatives may download photos ("Tải ảnh về máy"), from single items (11g) and from a whole album (11f).
- Rules text says "ảnh" (photos). Whether **videos** can be downloaded is not stated explicitly, but album download covers albums that contain videos. **Open question.**
- No per-relative download toggle appears in this section. Story private links have a separate "allow photo download" option (section 14).

---

## §13 · Tab Tôi: hồ sơ người dùng & dung lượng (10 GB shared by all babies)

Section title, VERBATIM: **"13 · Tab Tôi: hồ sơ người dùng & dung lượng (10 GB cho tất cả các bé)"** ("Me tab: user profile & storage, 10 GB for all babies").

Sub-labels:
- 13a "Tab Tôi · hồ sơ người dùng (ba/mẹ)" (Me tab, parent)
- 13b "Dung lượng · theo bé & theo loại" (storage by baby & by type)
- 13c "Sắp đầy (80%)" (nearly full)
- 13d "Đã đầy 10 GB · tạm dừng tải lên" (10 GB full · uploads paused)
- 13e "Liên hệ quản trị · xin thêm dung lượng" (contact admin · request more storage)
- 13f "Kỷ niệm · khi hết dung lượng" (Memories when storage runs out)
- 13g "Tab Tôi · người chăm sóc" (Me tab, caregiver)
- 13h "Tab Tôi · người thân" (Me tab, relative)
- 13i "Hồ sơ các bé (tối đa 3)" (baby profiles, max 3)
- 13j "Hồ sơ bé · xem" (view baby profile)
- 13k "Sửa hồ sơ bé (dùng lại form tạo)" (edit baby profile, reuses the create form)
- 13l "Xoá hồ sơ bé · gõ tên để xác nhận" (delete baby profile · type the name to confirm)
- 13m "Sửa hồ sơ người dùng" (edit user profile)
- 13n "Tài khoản & đăng nhập" (account & sign-in)

### 194:78 · 13a Tôi · Ba/Mẹ (Me tab, parent). Full read.
- Title **"Tôi"** (Me).
- Profile row → 13m (chevron):
  - avatar initial "M"
  - name "Mai"
  - email "mai.nguyen@gmail.com"
  - role line **"Mẹ · chủ hồ sơ của Teddy, Na"** ("Mum · profile owner of Teddy, Na")
- **Storage card** → 13b:
  - "Dung lượng" + **"3,2 GB / 10 GB"**
  - segmented bar, one colour per baby
  - legend "● Teddy 2,4 GB" / "● Na 0,8 GB"
  - footnote **"Dùng chung cho tất cả các bé của bạn"** (shared across all your babies)
- Group 1:
  - **"Hồ sơ các bé"** (baby profiles) / "Teddy, Na" / count "2" → 13i
  - **"Thông báo"** (notifications) / value "Bật" (On) → notification settings. **No dedicated screen found in §13. Gap.**
  - **"Giao diện"** (appearance) / value "Tự động" (Automatic) → theme screen 29:1063 "13 Giao diện" in section 3. That screen has 3 ThemeOptions, a "Lịch Night care" (Night-care schedule) section with 2 DetailRows, "Ngoài lịch, Night care vẫn tự …[cut]" (outside the schedule, Night care still automatically…) and "Áp dụng ngay cho cả app" (applies immediately to the whole app).
- Group 2:
  - **"Đã chia sẻ ra ngoài"** (shared externally) / **"2 liên kết đang mở"** (2 links open) → **14m 208:36267 "Đã chia sẻ ra ngoài"**. Section label "14m Quản lý liên kết · thu hồi (từ Tôi)" (manage links · revoke, from Me). **This is the "Quản lý liên kết" entry point, shown for parents only.**
  - **"Tài khoản & đăng nhập"** (account & sign-in) / **"Email, Apple, đổi máy"** (Email, Apple, change device) → 13n
  - **"Trợ giúp & liên hệ"** (help & contact) → **no destination screen designed. Gap.**
- **"Đăng xuất"** (sign out), red text row. No confirmation dialog designed. **Gap.**
- TabDock: Today · Memories · Family · **Tôi** (active, avatar "M") + QuickLog "+".
- Not present: language, units, data export, delete account (it lives in 13n).

### 194:164 · 13b Dung lượng (storage). Full read.
- Back "Tôi". Title "Dung lượng".
- Big number **"3,2 GB"** "/ 10 GB"; bar segmented per baby.
- Footnote **"Dùng chung cho tất cả các bé · ảnh ba và mẹ tải lên đều tính vào đây"** (shared by all babies · photos uploaded by both dad and mum count here). Quota is per family/owner, and every co-parent's uploads count.
- **"Theo bé"** (by baby), rows with chevrons:
  - Teddy: "312 ảnh · 24 video" · 2,4 GB
  - Na: "96 ảnh · 6 video" · 0,8 GB
  - Destination (inferred): baby profile 13j, or that baby's media filtered.
- **"Theo loại"** (by type):
  - **"Video"** / **"Xem video lớn nhất"** (view largest videos) · 2,2 GB → largest-videos list. **Not designed. Gap.**
  - **"Ảnh"** (photos) · 0,9 GB →
  - **"Câu chuyện & ghi chú"** (stories & notes) · 40 MB →
- Contact card:
  - **"Cần thêm dung lượng?"** (need more storage?)
  - **"Mỗi gia đình có 10 GB. Liên hệ quản trị Child Life để mở rộng."** (Each family has 10 GB. Contact the Child Life administrators to expand.)
  - Secondary button **"Liên hệ quản trị"** (contact admin) → 13e sheet
- Breakdown dimensions: **per baby** (photo/video counts + size) and **per type** (Video / Ảnh / Câu chuyện & ghi chú). The numbers add up: 2,4 + 0,8 = 3,2; 2,2 + 0,9 + 0,04 ≈ 3,2.

### 194:267 · 13c Dung lượng · sắp đầy (nearly full). Metadata only.
- Big "8,2 GB" / 10 GB. Same footnote.
- **Warn banner** (Icon/alert):
  - **"Sắp đầy · 82%"** (nearly full · 82%)
  - "Video chiếm nhiều chỗ nhất. Xo…[cut]" (videos take the most space. [probably "Xoá…/Xem…": delete/view…]). It points users to deleting large videos.
- By baby: Teddy 6,1 GB · Na 2,1 GB. By type: Video 5,7 GB · Ảnh 2,3 GB · Câu chuyện & ghi chú 40 MB.
- Contact card unchanged.
- **Threshold:** the section label says **80%**. The screen shows 82%, so the warning starts at ≥80%.
- Not designed: whether an 80% push notification or an in-app banner elsewhere is sent. **Gap.**

### 194:377 · 13d Dung lượng · đã đầy (full). Metadata only.
- Big "10 GB" / 10 GB.
- **Full banner:**
  - **"Đã dùng hết 10 GB"** (all 10 GB used)
  - **"Tạm dừng tải ảnh, video. 3 mục…[cut]"** (photo and video uploads paused. 3 items… [probably "đang chờ" = waiting in the queue])
- By baby: Teddy 7,4 · Na 2,6. By type: Video 7,0 · Ảnh 2,8 · Câu chuyện & ghi chú 40 MB.
- Contact card + "Liên hệ quản trị".
- **What pauses:** photo and video uploads. Pending items stay queued (the "3 mục" count).
- **What still works (inferred from wording and 13f):**
  - viewing
  - care logging (not media)
  - notes and stories? Text only, tiny. **Not explicitly stated. Gap.**

### 195:18 · 13e Liên hệ quản trị (contact admin). Metadata only.
- Background is the 13d full state, with a **bottom sheet** (SheetHeader; title text is in the instance and was not readable).
- **"Cần thêm bao nhiêu?"** (how much more do you need?) with chip choices **"+10 GB" · "+20 GB" · "Khác"** (other).
- Field **"Lời nhắn (không bắt buộc)"** (message, optional). Sample text "Nhà mình có 2 bé, video nhiều …[cut]" (our family has 2 babies, lots of video…).
- Info box **"Gửi kèm: mai.nguyen@gmail.com …[cut]"** (sent along: mai.nguyen@gmail.com …). The account email is attached automatically, possibly with family/usage info.
- Primary Button (label in the instance, not readable; probably "Gửi" = send).
- Footnote **"Quản trị Child Life sẽ trả lời…[cut]"** (Child Life admin will reply…, probably by email).
- **Who the admin is:** **company staff** ("Quản trị Child Life", Child Life administrators), not an in-family admin. 13b says "Liên hệ quản trị Child Life để mở rộng".
- **Channel:** an in-app request form. The reply goes to the attached email (inferred).
- No price, plan or purchase UI. **The quota grant is manual, by staff.** This implies a back-office/portal function: review request → grant +N GB to the family. **Portal not in Screens. Check the Website page.**

### 195:177 · 13f Kỷ niệm · hết dung lượng (Memories when out of storage). Metadata only.
- Parent Memories journal with header actions:
  - "View" (Icon/sliders)
  - "Add" (Icon/plus): still shown. Behaviour when full is not visible in metadata.
- **UploadPill** instance at the top (its text sits in the component instance and could not be read). Presumably shows the "hết dung lượng / tạm dừng" (out of storage / paused) state and links to 13b/13d (inferred).
- Journal content still browsable:
  - "Tuần thứ 3 · 1 – 8 tháng 10 · 13 ảnh, 3 video" (week 3 · 1–8 October · 13 photos, 3 videos)
  - entries by Mẹ/Ba, notes, loves "Bà nội, Ông ngoại thương", "2 lượt thương", milestones
  - "Tuần thứ 2 · 24 – 30 tháng 9 · 6 ảnh" (week 2 · 24–30 September · 6 photos)
- So **existing memories stay fully viewable when full**. Only new uploads pause.

### 197:286 · 13g Tôi · người chăm (Me tab, caregiver). Metadata only.
- Profile "L" / **"Cô Lan"** / "lan.bao.mau@gmail.com" / **"Bảo mẫu · chăm Teddy"** (nanny · cares for Teddy). The relationship label is separate from the role.
- **No storage card.**
- Group:
  - **"Bé được giao"** (assigned baby) / **"Teddy · do Mai mời"** (Teddy · invited by Mai) / "1"
  - "Thông báo · Bật" (notifications · on)
  - "Giao diện · Tự động" (appearance · automatic)
- Group:
  - "Tài khoản & đăng nhập · Email, Apple, đổi máy" (account & sign-in · Email, Apple, change device)
  - "Trợ giúp & liên hệ" (help & contact)
- "Đăng xuất" (sign out)
- **No "Đã chia sẻ ra ngoài" (shared externally), no "Hồ sơ các bé" (baby profiles) management.**

### 197:391 · 13h Tôi · người thân (Me tab, relative). Metadata only.
- Profile "H" / **"Bà nội Hoa"** / "hoa.nguyen@gmail.com" / **"Bà · người thân của Teddy"** (Grandma · relative of Teddy).
- **No storage card.**
- Group:
  - **"Các bé bạn theo dõi"** (babies you follow) / **"Teddy · Mai chia sẻ"** (Teddy · shared by Mai) / "1"
  - "Thông báo · Bật"
  - "Giao diện · Tự động"
- Group:
  - "Tài khoản & đăng nhập · Email, Apple, đổi máy"
  - "Trợ giúp & liên hệ"
- "Đăng xuất"
- No external-share entry and no baby management. This matches the rule that relatives don't see "dung lượng" (storage).
- **Gap:** no "leave family / stop following" (rời gia đình) action is designed for caregivers or relatives.

### 199:83 · 13i Hồ sơ các bé (baby profiles). Metadata only.
- Back "Tôi". Title "Hồ sơ các bé".
- Rows:
  - **Teddy** / "3 tuần tuổi · 4 người cùng chă…[cut]" (3 weeks old · 4 people caring…)
  - **Na** / "2 tuổi 1 tháng · 3 người cùng …[cut]" (2 years 1 month · 3 people…)
- **"+ Thêm bé · 2/3"** (add baby · 2/3)
- Footnote **"Mỗi tài khoản tạo được tối đa …[cut]"** (each account can create at most…). Full text in 7c (125:13223): **"Bạn tạo được tối đa 3 hồ sơ bé."** (You can create at most 3 baby profiles.)
- **Limit = 3 profiles *created/owned* per account.** In 7c the picker lists Teddy (Bạn là Mẹ = you are Mum), Na (Bạn là Mẹ) and Bin ("Bạn là Người chăm sóc" = you are the caregiver) with "Thêm hồ sơ bé 2/3". So **profiles where you are only a member do not count**.
- Inconsistency: Na's age is "14 tháng" (14 months) in 7c and "2 tuổi 1 tháng" (2 years 1 month) in 13i. Mock data only.

### 199:168 · 13j Hồ sơ bé · Teddy (view baby profile). Metadata only.
- Back "Hồ sơ các bé"; action **"Sửa"** (edit) → 13k.
- Head: avatar, "Teddy", "3 tuần tuổi · sinh ngày 17 thá…[cut]" (3 weeks old · born 17 Sep…).
- Stats: "4,3 kg · Cân nặng · hôm nay" (weight · today) and "54,5 cm · Chiều cao · hôm nay" (height · today). Taken from the latest growth records.
- **"Thông tin"** (info):
  - Ngày sinh (birth date) 17 thg 9, 2026
  - Giới tính (sex) Bé trai (boy)
  - Múi giờ (time zone) GMT+7
- **"Của bé"** (the baby's):
  - **"Gia đình của Teddy"** (Teddy's family) / "Mai, Minh, Cô Lan, Bà nội Hoa" / 4 → family/members screen
  - **"Tăng trưởng"** (growth) / "Biểu đồ cân nặng, chiều cao" (weight & height charts) → growth chart
  - **"Dung lượng của Teddy"** (Teddy's storage) / **"Tính vào 10 GB của bạn"** (counts toward your 10 GB) / 2,4 GB
- Destructive row **"Xoá hồ sơ Teddy"** (delete Teddy's profile) / **"Chỉ chủ hồ sơ (Mai) làm được"** (only the profile owner (Mai) can do this) → 13l.

### 199:292 · 13k Sửa hồ sơ bé (edit baby profile). Metadata only. "dùng lại form tạo" (reuses the create form).
- TopBar (title in the instance; probably "Sửa hồ sơ bé"). Illustration/BabyAvatar.
- **"Tên thân mật"** (nickname) = "Teddy"
- Group of 2 DetailRows (labels in the instance; probably Ngày sinh (birth date) and Múi giờ (time zone), per 13j). **Not verified.**
- **"Giới tính"** (sex) **"· không bắt buộc"** (optional) + Segmented (options not readable; probably Bé trai (boy) / Bé gái (girl)).
- Lock row (Icon/lock): **"Người thân chỉ thấy tên thân m…[cut]"** (relatives only see the nickname [ật…]). Privacy: relatives see the nickname only. Full name, birth date and so on are hidden (inferred from the §12 rule "Ngày sinh và hồ sơ đầy đủ…", birth date and full profile).
- Bottom primary Button (probably "Lưu" = save).
- Field set mirrors section 3, baby-profile creation ("dùng lại form tạo").

### 199:385 · 13l Xoá hồ sơ bé (delete baby profile). Metadata only.
- 13j in the background with a **sheet**:
  - Title **"Xoá hồ sơ Teddy?"** (delete Teddy's profile?)
  - Body **"Mọi ghi chép chăm sóc, ảnh, vi…[cut]"** (all care records, photos, vi[deos]…) **[full text missing]**
  - Info box **"Giải phóng 2,4 GB · 4 người mấ…[cut]"** (frees 2,4 GB · 4 people lose [access]…)
  - **"Nên tải ảnh về máy trước khi x…[cut]"** (you should download photos before [deleting]…)
  - **"Gõ “Teddy” để xác nhận"** (type "Teddy" to confirm) + input showing "Teddy"
  - Button 1, h56, primary/destructive (probably "Xoá hồ sơ" = delete profile)
  - Button 2, h44, plain (probably "Huỷ" = cancel)
- **Who may delete:** only the profile owner ("Chỉ chủ hồ sơ (Mai) làm được").
- **Consequences:** deletes all care records and media of that baby for everyone, frees that baby's storage, revokes access for the members. Matches product plan flow F.

### 199:501 · 13m Hồ sơ của bạn (edit user profile). Metadata only.
- Back "Tôi"; action **"Lưu"** (save).
- Avatar "M" + **"Đổi ảnh"** (change photo).
- TextField (label in the instance; probably "Tên" = name, value "Mai").
- **"Bạn là ai với bé"** (who you are to the baby): per-baby relationship rows "Teddy – Mẹ", "Na – Mẹ" (editable per baby; picker = section 2 10a "Bạn là ai với bé").
- Footnote **"Gia đình thấy tên và vai trò n…[cut]"** (the family sees the name and role [này = this]…).
- **No email field here.** Email is managed in 13n.

### 199:602 · 13n Tài khoản & đăng nhập (account & sign-in). Metadata only.
- Back "Tôi"; title **"Tài khoản"** (account).
- **"Đăng nhập"** (sign-in):
  - **Email** / "mai.nguyen@gmail.com · đã xác …[cut]" (verified)
  - **Apple** / **"Đã liên kết"** (linked) / action **"Gỡ"** (unlink)
- **"Thiết bị đang đăng nhập"** (signed-in devices):
  - "iPhone 15 của Mai" / **"Máy này · Hồ Chí Minh"** (this device · Ho Chi Minh City)
  - "iPad mini" / **"Hoạt động 3 ngày trước"** (active 3 days ago) / action **"Đăng xuất"** (sign out remotely)
- **"Xoá tài khoản"** (delete account) / **"Cần chuyển chủ hồ sơ của Teddy…[cut]"** (you need to transfer profile ownership of Teddy… [and Na first]).
- Sign-in methods in this design: **Email (+ verification) and Apple**. Section 2 "06 Chọn cách đăng nhập" (choose sign-in method) has 3 button instances, labels unreadable (likely Apple / Google / Email). **Verify whether Google exists.**
- Not designed:
  - change email
  - change password (password reset exists in section 2, "09 Quên mật khẩu" = forgot password)
  - link another provider ("Thêm" = add)
  - **the profile-ownership transfer flow**
  - the delete-account confirmation/flow itself

---

## Business rules confirmed (verbatim evidence)

1. Relatives see only items set to "Gia đình" (Family), shared albums and stories, the milestones on them, and the family's loves: 188:835 "Ảnh, video, ghi chú ba mẹ chọn “Gia đình”" / "Album và câu chuyện được chia sẻ" / "Mốc gắn trên các mục đó" / "Lượt thương của cả nhà".
2. Relatives do not see "Chỉ ba mẹ" (parents-only) items or private albums. They do not see care data (feeding, sleep, diapers, growth) unless enabled at invite time. They do not see parents' favourites, the upload queue or storage: 188:835.
3. Relatives can Love, keep private Favorites, download photos and message parents. They can never add, edit, delete or change "Ai thấy": 188:835 "Không thêm, sửa, xoá hay đổi “Ai thấy”".
4. Family-share push notifications are generic, with no photo: 151:18383 "Không kèm ảnh · chỉ báo chung chung"; "Có 7 khoảnh khắc mới / Mai vừa chia sẻ với gia đình. Mở để xem."; "Có 1 câu chuyện mới / Từ Kỷ niệm của gia đình".
5. The relative empty state promises a notification on the first share: 188:729.
6. Relative's Photos has no add or select: label 187:30125 "Ảnh · không có nút + / Chọn".
7. Album detail for relatives offers only Love and Download: label 188:679.
8. A relative's favourites form a private album: 187:30126 "Yêu thích · 6 ảnh · của riêng bạn".
9. Love is visible by name to parents: 10a "Bà nội, Ông ngoại thương".
10. Storage is 10 GB per family, shared by all babies; both parents' uploads count: 194:164 "Mỗi gia đình có 10 GB…"; "Dùng chung cho tất cả các bé · ảnh ba và mẹ tải lên đều tính vào đây"; 199:168 "Tính vào 10 GB của bạn".
11. Near-full warning at 80%: label 194:376 "13c Sắp đầy (80%)"; screen "Sắp đầy · 82%".
12. When full, photo and video uploads pause: label 194:487 "Đã đầy 10 GB · tạm dừng tải lên"; "Đã dùng hết 10 GB"; "Tạm dừng tải ảnh, video. 3 mục…".
13. Expanding storage goes through Child Life staff, not a purchase: 194:164 "Liên hệ quản trị Child Life để mở rộng"; 195:18 "+10 GB / +20 GB / Khác", "Lời nhắn (không bắt buộc)", "Gửi kèm: <email>…", "Quản trị Child Life sẽ trả lời…".
14. Storage is visible only to parents; the caregiver and relative Me tabs have no storage card: 197:286, 197:391, 188:835.
15. An account can create at most 3 baby profiles: 7c "Bạn tạo được tối đa 3 hồ sơ bé."; 13i "Thêm bé · 2/3".
16. Only the profile owner can delete a baby profile, by typing the name: 199:168 "Chỉ chủ hồ sơ (Mai) làm được"; 199:385 "Gõ “Teddy” để xác nhận".
17. Deleting an account requires transferring profile ownership first: 199:602 "Cần chuyển chủ hồ sơ của Teddy…".
18. Relatives see only the baby's nickname: 199:292 "Người thân chỉ thấy tên thân m…".
19. Baby edit reuses the create form: label 199:384.
20. The external-link manager is reached from Me (parents): 194:78 "Đã chia sẻ ra ngoài · 2 liên kết đang mở" → 14m 208:36267.
21. Sign-in methods include Email (verified) and Apple, with Apple unlinking ("Gỡ"). Remote sign-out per device: 199:602.

## Entities & fields implied

- **User/Account:** id, displayName, avatarPhoto, email, emailVerified, authProviders[] (password/email, apple, maybe google), devices/sessions[] (name, location (city), lastActive, isCurrent), notificationPrefs (on/off + details, not designed), themePref (Tự động / Light / Night care + Night-care schedule, from 29:1063).
- **Membership (user × baby):** role (parent/co-parent, caregiver, relative), relationshipLabel ("Mẹ", "Bảo mẫu", "Bà"), invitedBy ("do Mai mời", "Mai chia sẻ"), extra permissions (care visibility enabled at invite time).
- **Baby profile:** nickname ("Tên thân mật"), birthDate, sex (optional), timezone, avatar, **ownerUserId** ("chủ hồ sơ"), member count. Derived: age string, latest weight/height, storage bytes.
- **Owner quota:** limit of 3 created profiles per account.
- **Family storage quota:** limitBytes (10 GB default, raisable by staff), usedBytes; breakdown byBaby (bytes, photoCount, videoCount) and byType (video, photo, story&note). Thresholds: nearFull ≥ 80%, full ≥ 100%. Quota scope = the set of babies of an owner, "của bạn" (inferred: owner-scoped "family"). **Product plan still lists "whose quota with multiple co-parents" as an open question.**
- **StorageRequest (admin ticket):** familyId/ownerId, requesterUserId, requestedAmount (+10 GB / +20 GB / custom "Khác"), message (optional), attached contact email, usage snapshot (inferred), status, adminReply, grantedBytes.
- **Reaction ("Thương"):** userId, targetType (memory item/entry, album, story), targetId, createdAt. Counts are public to the family; names are shown to parents.
- **Favorite:** userId, mediaId. Private per user; virtual album "Yêu thích".
- **MessageToParents ("Nhắn"):** senderUserId, babyId, context (memoryId/albumId/storyId), text, createdAt, recipients (parents), readAt. **Recipient UI not designed.**
- **Notification (family share):** type (newMoments{count, sharerName} | newStory), no media, no baby name.
- **Download event** (optional audit, inferred).
- **External share link** (section 14): handled by the other agent; entry from Me.

## Open questions / gaps (with node ids)

1. **"Nhắn ba mẹ" destination** (152:17909, 188:714, 208:36394):
   - The composer exists only in 11i. There is no screen where parents read relative messages, no notification copy, no reply ability.
   - Is it in-app (likely) or an OS share/Zalo hand-off? There is no evidence for the external option: Zalo/Messenger appear only in 14j 208:312.
   - **Must decide.**
2. **Account deletion** (199:646): an entry exists with the precondition "Cần chuyển chủ hồ sơ…". **Not designed:** the confirmation, grace period, data consequences, and the **ownership-transfer flow** (no screen found).
3. **Data export:** **not designed anywhere** in §11/§13. The only related item is "Nên tải ảnh về máy trước khi xoá" (download photos before deleting), i.e. per-photo/album download. No "Xuất dữ liệu" (export data) or bulk export.
4. **Admin/support portal:** 13e sends requests to "Quản trị Child Life". No staff tooling exists in Screens. Check the Website page (210:759) for a portal. Needs: a request queue, quota grants, a reply channel (email?).
5. **Quota expansion purchase:** **not designed.** No price, IAP or plan screens. Expansion is a free-text request to staff (+10/+20/Khác). Who pays, and whether this is free, is unknown.
6. "Trợ giúp & liên hệ" (197:43) has no destination screen. Unknown whether it is the same form as 13e, email or FAQ.
7. "Thông báo · Bật" (194:119): no notification settings screen (which categories: family shares, reminders, quota alerts, loves, messages?).
8. "Video · Xem video lớn nhất" (194:212): no largest-videos/cleanup screen. Is deleting to free space designed elsewhere?
9. 80% threshold: in-app banner only, or also a push notification? Who receives it (all parents, or the owner only)?
10. When full:
    - Do text notes and stories still save?
    - Does the "+" in 13f (195:185) block, or queue with a warning?
    - UploadPill text in 195:190 is unread.
    - Does the 13d "3 mục" (3 items) queue resume automatically after quota increases?
11. Quota scope with two co-parents: 13a says "Dùng chung cho tất cả các bé *của bạn*" (shared across all *your* babies, owner-scoped). 13b says "ảnh ba và mẹ tải lên đều tính vào đây" (both dad's and mum's uploads count). What if co-parents own different babies? What if a parent is owner of one baby and member of another?
12. Profile limit wording: 13i "Mỗi tài khoản tạo được tối đa …" vs 7c "Bạn tạo được tối đa 3". Confirm that only created/owned profiles count (7c lists a caregiver baby separately).
13. "Gom từ mốc bạn đã gắn" (187:30175) shown to relatives who cannot tag. Copy should probably differ.
14. 11f "Tải về" (188:678): whole album including videos? Original quality? Is a progress UI designed?
15. Can relatives download videos? The rule says "Tải ảnh" (download photos).
16. There is no "Rời gia đình / bỏ theo dõi" (leave family / unfollow) for caregivers and relatives (197:286, 197:391), and no self-removal.
17. 13n (199:602):
    - no change email, change/set password, or add-provider controls
    - is Google sign-in present? 06 buttons 27:515/522/529 are unread
    - "Gỡ" Apple when it is the only method: guard not designed
18. Sign-out (194:137 etc.): no confirmation, no handling of the pending upload queue on sign-out (offline drafts would be lost).
19. Text cut off in metadata (re-read when the MCP quota resets):
    - 194:293
    - 194:403 / 195:41
    - 195:167, 195:169, 195:175
    - 199:107, 199:126, 199:137, 199:192
    - 199:314
    - 199:483, 199:485, 199:486
    - 199:571
    - 199:619, 199:645
    - instance labels 195:148 / 195:170 / 199:295 / 199:303 / 199:305 / 199:310 / 199:316 / 199:490 / 199:495 / 199:520 / 195:190
20. "7b Người thân · 2 tab" vs the 3-icon dock in §11 (Memories, Family, Me). Confirm what the relative's Family tab shows (probably a read-only member list, like 12g for the caregiver).
21. Night-care variants were not inspected (MCP limit). Assumed visual-only.


---

# Gap-fill pass (full reads of §13 frames; supersedes metadata-only notes above)

# E2 gap-fill — Me / Storage / Baby profiles / Account (Figma sJLG1fAXKDnDr9YI6Yx8ex, Screens page, Light)

Source: get_design_context rendered text (authoritative). Read-only extraction.

---

## 194:267 — 13c Dung lượng · sắp đầy (Storage, nearly full) — READ FULLY

Tab dock: Me tab ("Tôi", avatar "M") active; QuickLog (+) FAB.

- Back pill (Icon/back) + label "Tôi" (Me) → back to Me screen
- Title: "Dung lượng" (Storage)
- Big number: "8,2 GB" + "/ 10 GB"
- Bar: 2 segments — mint-deep (~ Teddy 6,1 GB share) + peach (~ Na 2,1 GB share) on separator track (segments = per-baby colours)
- Helper: "Dùng chung cho tất cả các bé · ảnh ba và mẹ tải lên đều tính vào đây" (Shared across all babies · photos uploaded by dad and mom all count here)
- WARN banner (sunshine-soft bg, Icon/alert):
  - Title: "Sắp đầy · 82%" (Almost full · 82%)
  - Body: "Video chiếm nhiều chỗ nhất. Xoá bớt video dài hoặc liên hệ quản trị để mở rộng." (Videos take the most space. Delete some long videos or contact the admin to expand.)
- Section "Theo bé" (By baby) — rows with cake icon in baby colour, chevron → (per-baby storage / media list):
  - "Teddy" · "312 ảnh · 24 video" (312 photos · 24 videos) · "6,1 GB" ›   (mint-soft icon bg)
  - "Na" · "96 ảnh · 6 video" · "2,1 GB" ›   (peach-soft icon bg)
- Section "Theo loại" (By type), chevron rows:
  - "Video" · sub "Xem video lớn nhất" (See largest videos) · "5,7 GB" ›
  - "Ảnh" (Photos) · "2,3 GB" ›
  - "Câu chuyện & ghi chú" (Stories & notes) · "40 MB" ›
- Contact card (surface-2):
  - Title: "Cần thêm dung lượng?" (Need more storage?)
  - Body: "Mỗi gia đình có 10 GB. Liên hệ quản trị Child Life để mở rộng." (Each family has 10 GB. Contact the Child Life admin to expand.)
  - Secondary button (h52 surface-2): "Liên hệ quản trị" (Contact admin) → opens 13e contact-admin sheet
- Rules: quota is per-family 10 GB, shared across all babies; warning state at 82% (threshold likely ~80%); sunshine (yellow) tone for warning.

---

## 194:377 — 13d Dung lượng · đã đầy (Storage, full) — READ FULLY

Same layout as 13c; differences:
- Back "Tôi"; Title "Dung lượng"
- Big number "10 GB" in ERROR colour (#a12b32) + "/ 10 GB"
- Bar: first segment turns error red (Teddy share), second stays peach (Na)
- Helper: "Dùng chung cho tất cả các bé · ảnh ba và mẹ tải lên đều tính vào đây"
- FULL banner (error-soft bg, Icon/cloud-off):
  - Title (error colour): "Đã dùng hết 10 GB" (All 10 GB used)
  - Body: "Tạm dừng tải ảnh, video. 3 mục mới được giữ trên máy, không mất. Ghi chép chăm sóc vẫn lưu bình thường." (Photo/video uploads paused. 3 new items are kept on the device, not lost. Care logs still save normally.)
- "Theo bé": Teddy "312 ảnh · 24 video" "7,4 GB" › ; Na "96 ảnh · 6 video" "2,6 GB" ›
- "Theo loại": Video "Xem video lớn nhất" "7,0 GB" › ; Ảnh "2,8 GB" › ; "Câu chuyện & ghi chú" "40 MB" ›
- Contact card: "Cần thêm dung lượng?" / "Mỗi gia đình có 10 GB. Liên hệ quản trị Child Life để mở rộng."
  - Button becomes PRIMARY (h56 mint-deep, white label): "Liên hệ quản trị" → 13e sheet
- Rules: at 100% → media upload paused; pending new media queued locally on device ("N mục mới được giữ trên máy"); care logs (feeds/sleep/diaper etc.) unaffected; CTA escalates secondary → primary when full.
- Note: sample numbers inconsistent (photos/video counts unchanged vs 13c though sizes grew) — mock data only.

---

## 195:18 — 13e Liên hệ quản trị (Contact admin sheet) — READ FULLY

Background: 13d full-storage screen under scrim (rgba(12,23,25,0.32)). Bottom sheet (surface, top radius 28).
- SheetHeader: grabber; title "Xin thêm dung lượng" (Request more storage); Close (X, 44px, a11y label "Đóng" = Close)
- Label: "Cần thêm bao nhiêu?" (How much more do you need?)
- Amount chips (single-select): "+10 GB" (selected: ink bg / white text), "+20 GB", "Khác" (Other)
- Message field (surface-2 card): label "Lời nhắn (không bắt buộc)" (Message (optional)); sample value "Nhà mình có 2 bé, video nhiều nên sắp hết chỗ." (We have 2 kids, lots of videos so we're running out of space.)
- Info card (read-only): "Gửi kèm: mai.nguyen@gmail.com · đang dùng 10 GB / 10 GB" (Attached: <user email> · using 10 GB / 10 GB)
- Primary button: "Gửi yêu cầu" (Send request)
- Footnote: "Quản trị Child Life sẽ trả lời qua email, thường trong 1–2 ngày làm việc." (Child Life admin will reply by email, usually within 1–2 business days.)
- Rules: request auto-attaches user's account email + current usage; message optional; amount options +10/+20/Other; response channel = email (no in-app purchase/upgrade flow). "Khác" behaviour not shown (presumably free input).

---

## 195:177 — 13f Kỷ niệm · hết dung lượng (Memories when out of storage) — READ FULLY

Tab: "Kỷ niệm" (Memories) active. NOTE: this frame's TabDock has NO QuickLog FAB (NavBar only).
- Header: BabySwitcher chip "Teddy · 3 tuần" (Teddy · 3 weeks) with chevron (multi-baby family); actions: View/filter button (Icon/sliders, 44px, surface-2) + Add button (Icon/plus, 44px mint-deep)
- Title: "Nhật ký" (Journal/Diary)
- UPLOAD PILL in error state (error-soft bg, replaces normal upload-progress pill):
  - Thumbnail MediaTile 44px with dark overlay + red error badge "!"
  - Title (error colour): "Hết dung lượng 10 GB" (Out of 10 GB storage)
  - Progress bar (error fill ~53%, stalled)
  - Sub: "3 mục giữ trên máy · chạm để xem" (3 items kept on device · tap to view)
  - Chevron › → tap opens storage screen (13d) / pending items list
- Timeline (week sections with mint left border):
  - "Tuần thứ 3" (Week 3) · "1 – 8 tháng 10 · 13 ảnh, 3 video" (Oct 1–8 · 13 photos, 3 videos)
    - Entry 1 ảnh: author chip "M" "Mẹ" (Mom) · "Hôm nay · 9:20" (Today · 9:20) · Icon/family (shared with family) · text "Ngủ trưa ngon lành sau giờ tắm." (Napped soundly after bath.) · photo · reactions "Bà nội, Ông ngoại thương" (Grandma (paternal), Grandpa (maternal) love this)
    - Entry 1 video: "B" "Ba" (Dad) · "Hôm qua · 19:05" (Yesterday) · family icon · "Lần đầu nắm chặt ngón tay ba." (First time gripping dad's finger tightly.) · video w/ play + duration "0:42" · "2 lượt thương" (2 loves)
    - Entry 2 ảnh: "Mẹ" · "Thứ Ba, 6 thg 10" (Tue, Oct 6) · family · "Bà nội sang thăm, mang theo đôi tất len tự đan." (Grandma visited, bringing hand-knitted wool socks.) · 2 photos
    - Entry ghi chú (note; sunshine-soft bg): "Mẹ" · "Thứ Hai, 5 thg 10" (Mon, Oct 5) · Icon/lock (PRIVATE) · "Đêm qua con ngủ một mạch 4 tiếng. Mẹ dậy mà vẫn thấy lạ." (Last night baby slept 4 hours straight. Mom woke up still amazed.)
    - Entry nhiều ảnh: "Mẹ" · "Thứ Hai, 5 thg 10" · family · milestone chip "★ Lần đầu cười · 5 thg 10" (★ First smile · Oct 5) · 3x2 grid: video badge "0:24", favourite bookmark, private-lock tile, video "0:12", favourite
  - "Tuần thứ 2" (Week 2) · "24 – 30 tháng 9 · 6 ảnh"
    - Entry: "B" "Ba" · "Chủ nhật, 20 thg 9" (Sun, Sep 20) · family · milestone chip "★ Ngày đầu về nhà · 20 thg 9" (★ First day home · Sep 20) · 3 photos (one favourite)
- Floating memory tabs (segmented): "Nhật ký" (selected) · "Ảnh" (Photos) · "Album" · "Câu chuyện" (Stories)
- Bottom fade gradient over content.
- Rules: when storage full, Memories feed still browsable; upload pill shows error state with count of locally held items; existing content unaffected. Visibility icons per entry: family icon = shared, lock = private.

---

## 197:286 — 13g Tôi · người chăm (Me, caregiver role) — READ FULLY

NavBar for caregiver has only 3 tabs: Today (Icon/today), Family (Icon/family), Me ("Tôi", avatar "L") — NO Memories tab. QuickLog (+) FAB present.
- Title: "Tôi" (Me) — no back button (root tab)
- Profile block: avatar circle "L" (peach-soft); name "Cô Lan" (Ms. Lan); email "lan.bao.mau@gmail.com"; role line "Bảo mẫu · chăm Teddy" (Nanny · cares for Teddy)
  (Profile block presumably tappable → 13m edit profile; no chevron shown)
- Group 1:
  - Icon/cake · "Bé được giao" (Assigned baby) · sub "Teddy · do Mai mời" (Teddy · invited by Mai) · value "1" › → list of assigned babies
  - Icon/today(sun) · "Thông báo" (Notifications) · value "Bật" (On) ›
  - Icon/globe · "Giao diện" (Appearance) · value "Tự động" (Automatic) ›
- Group 2:
  - Icon/lock · "Tài khoản & đăng nhập" (Account & sign-in) · sub "Email, Apple, đổi máy" (Email, Apple, change device) › → 13n
  - Icon/mail · "Trợ giúp & liên hệ" (Help & contact) ›
- Standalone row (error colour text): "Đăng xuất" (Sign out)
- Rules: caregiver has NO "Dung lượng" (Storage) row, NO "Các bé" baby-profiles management row (replaced with read-only "Bé được giao" count), no Memories tab. Layer name of row "Các bé của bạn" is stale; rendered "Bé được giao".

---

## 197:391 — 13h Tôi · người thân (Me, relative role) — READ FULLY

NavBar for relative has 3 tabs: Memories (Icon/memories), Family (Icon/family), Me ("Tôi", avatar "H") — NO Today tab. QuickLog (+) FAB IS present in this mock (questionable for a view-only relative — flag; may be design oversight or relative quick-add memory).
- Title: "Tôi"
- Profile: avatar "H" (peach-soft); name "Bà nội Hoa" (Grandma Hoa, paternal); email "hoa.nguyen@gmail.com"; role line "Bà · người thân của Teddy" (Grandma · relative of Teddy)
- Group 1:
  - Icon/cake · "Các bé bạn theo dõi" (Babies you follow) · sub "Teddy · Mai chia sẻ" (Teddy · shared by Mai) · "1" ›
  - "Thông báo" · "Bật" ›
  - "Giao diện" · "Tự động" ›
- Group 2:
  - "Tài khoản & đăng nhập" · sub "Email, Apple, đổi máy" › → 13n
  - "Trợ giúp & liên hệ" ›
- "Đăng xuất" (error colour)
- Rules: relative has no Storage row, no baby-profile management; follows babies shared with them; no Today (care-log) tab.

---

## 199:83 — 13i Hồ sơ các bé (Baby profiles list) — READ FULLY

Parent (owner "M") view; full 4-tab NavBar, Me active, QuickLog FAB.
- Back pill + "Tôi" → Me
- Title: "Hồ sơ các bé" (Baby profiles)
- Card (shadow-tile, radius 20): BabyFace avatar on mint-soft · "Teddy" · "3 tuần tuổi · 4 người cùng chăm" (3 weeks old · 4 people co-caring) › → 13j
- Card: BabyFace on peach-soft · "Na" · "2 tuổi 1 tháng · 3 người cùng chăm" (2 years 1 month · 3 people co-caring) › → 13j
- Dashed add tile (control-border dashed): Icon/plus + "Thêm bé" (Add baby, mint-text) + "· 2/3" (count used / max) → add-baby flow (onboarding baby step)
- Footnote: "Mỗi tài khoản tạo được tối đa 3 hồ sơ bé." (Each account can create at most 3 baby profiles.)
- Rules: MAX 3 baby profiles per account (creator-scoped); counter "n/3" shown on add tile; age format "N tuần tuổi" for infants vs "N tuổi M tháng" for older; per-baby colour (mint/peach) consistent with storage screen.

---

## 199:168 — 13j Hồ sơ bé · Teddy (Baby profile view) — READ FULLY

Viewer: owner "M" (Mai). Full NavBar, Me active, FAB.
- Top: Back pill + "Hồ sơ các bé" (Baby profiles) → 13i ; right text button "Sửa" (Edit, mint-text) → 13k
- Head (centered): large BabyFace avatar 108px on mint-soft; name "Teddy" (28 semibold); "3 tuần tuổi · sinh ngày 17 tháng 9, 2026" (3 weeks old · born Sep 17, 2026)
- Stats cards (2-up):
  - card-peach: "4,3 kg" / "Cân nặng · hôm nay" (Weight · today)
  - card-sun: "54,5 cm" / "Chiều cao · hôm nay" (Height · today)
- Section "Thông tin" (Info) — read-only rows (no chevrons):
  - Icon/cake "Ngày sinh" (Birth date) · "17 thg 9, 2026"
  - "Giới tính" (Sex) · "Bé trai" (Boy)   (no icon)
  - Icon/globe "Múi giờ" (Time zone) · "GMT+7"
- Section "Của bé" (Baby's):
  - Icon/family "Gia đình của Teddy" (Teddy's family) · sub "Mai, Minh, Cô Lan, Bà nội Hoa" · "4" › → family/members screen for this baby
  - Icon/ruler "Tăng trưởng" (Growth) · sub "Biểu đồ cân nặng, chiều cao" (Weight, height chart) › → growth chart
  - Icon/cloud-off "Dung lượng của Teddy" (Teddy's storage) · sub "Tính vào 10 GB của bạn" (Counts toward your 10 GB) · "2,4 GB" › → storage detail
- Delete card (error-soft bg):
  - "Xoá hồ sơ Teddy" (Delete Teddy's profile, error colour)
  - sub "Chỉ chủ hồ sơ (Mai) làm được" (Only the profile owner (Mai) can do this) → 13l delete sheet
- Rules: baby has a single OWNER (creator); only owner can delete profile; time zone stored per baby; storage counts toward owner's 10 GB ("của bạn" = your). Member count 4 includes owner.
- Note: storage value 2,4 GB here vs 6,1 GB on 13c — mock inconsistency.

---

## 199:292 — 13k Sửa hồ sơ bé (Edit baby profile) — READ FULLY

Full-screen form, NO tab dock (pushed/modal). Reuses onboarding baby-step components.
- TopBar: round Back button (44px, a11y "Quay lại" = Back) → 13j (discard)
- Illustration/BabyAvatar 148px with camera button (mint-deep circle, Icon/camera) → change photo
- Label "Tên thân mật" (Nickname); value "Teddy" (32 semibold, centered; tappable to edit inline)
- Card (DetailRow ×2, mint-soft icon tiles, chevron):
  - Icon/cake "Ngày sinh" (Birth date) · "17 tháng 9, 2026" › → date picker sheet (SheetHeader default title "Ngày sinh")
  - Icon/globe "Múi giờ" (Time zone) · "GMT+7" › → time zone picker
- Gender: label "Giới tính" (Sex) + "· không bắt buộc" (· optional)
  - Segmented (3 options): "Bé gái" (Girl) · "Bé trai" (Boy, selected) · "Không nêu" (Not stated / prefer not to say)
- Privacy note (Icon/lock): "Người thân chỉ thấy tên thân mật" (Relatives only see the nickname)
- Primary button (bottom, thumb zone): "Lưu thay đổi" (Save changes)
- Rules: editable fields = photo, nickname, birth date, time zone, sex (optional, 3-way). Relatives (người thân) only see nickname — implies a real/legal name may exist but is hidden (no full-name field on this screen; privacy rule). No delete here — delete lives on 13j.
- Note: Gender label uses Inter Regular 12 (font inconsistency in design; should be Be Vietnam Pro caption).

---

## 199:385 — 13l Xoá hồ sơ bé (Delete baby profile sheet) — READ FULLY

Background: 13j under scrim. Bottom sheet (no grabber/SheetHeader; pt 24, radius 28).
- Title: "Xoá hồ sơ Teddy?" (Delete Teddy's profile?) — 22 semibold
- Body: "Mọi ghi chép chăm sóc, ảnh, video và câu chuyện của Teddy sẽ bị xoá với cả gia đình. Không khôi phục được." (All of Teddy's care logs, photos, videos and stories will be deleted for the whole family. Cannot be recovered.)
- Info card (surface-2):
  - "Giải phóng 2,4 GB · 4 người mất quyền xem" (Frees 2.4 GB · 4 people lose viewing access)
  - "Nên tải ảnh về máy trước khi xoá." (You should download photos to your device before deleting.)
- Prompt: "Gõ “Teddy” để xác nhận" (Type "Teddy" to confirm)
- Input (surface-2, 1.5px ERROR border when filled/active) value "Teddy"
- Destructive button (error-soft bg, error text, h56): "Xoá vĩnh viễn" (Delete permanently) — enabled only when typed name matches
- Plain text button (mint-text, h44): "Huỷ" (Cancel)
- Rules: type-to-confirm with baby's nickname; hard delete (no undo/recovery); cascades to all members' access; shows freed storage + affected member count; owner-only.

---

## 199:501 — 13m Hồ sơ của bạn (Edit user profile) — READ FULLY

Frame name "Hồ sơ của bạn" (Your profile). Full NavBar, Me active, FAB.
- Top: Back pill + "Tôi" → Me ; right text button "Lưu" (Save, mint-text)
- Avatar 104px peach-soft with initial "M"; chip button below: Icon/camera + "Đổi ảnh" (Change photo) → photo picker
- TextField (standalone card): label "Tên hiển thị" (Display name), value "Mai"
- Section label: "Bạn là ai với bé" (Who you are to the baby)
- Per-baby role rows (BabyFace avatar in baby colour, chevron):
  - "Teddy" · "Mẹ" (Mom) › → role picker for that baby
  - "Na" · "Mẹ" › → role picker
- Footnote: "Gia đình thấy tên và vai trò này khi bạn ghi chép hay chia sẻ." (Family sees this name and role when you log or share.)
- Rules: display name is global per account; relationship/role (Mẹ/Ba/Bà…) is set PER BABY; name + role are what appear as author labels on entries (e.g., "Mẹ" author chips in 13f). Email NOT editable here (lives in 13n). Save is a top-right text action (no bottom primary button).

---

## 199:602 — 13n Tài khoản & đăng nhập (Account & sign-in) — READ FULLY

Full NavBar, Me active, FAB.
- Back pill + "Tôi" → Me
- Title: "Tài khoản" (Account)
- Section "Đăng nhập" (Sign-in):
  - Icon/mail · "Email" · sub "mai.nguyen@gmail.com · đã xác minh" (· verified)   (no chevron, no action shown)
  - Icon/lock · "Apple" · sub "Đã liên kết" (Linked) · trailing text action "Gỡ" (Unlink/Remove)
- Section "Thiết bị đang đăng nhập" (Signed-in devices):
  - "iPhone 15 của Mai" (Mai's iPhone 15) · sub "Máy này · Hồ Chí Minh" (This device · Ho Chi Minh City)   (no action on current device)
  - "iPad mini" · sub "Hoạt động 3 ngày trước" (Active 3 days ago) · trailing text action "Đăng xuất" (Sign out — remote sign-out of that device)
- Delete account card (error-soft):
  - "Xoá tài khoản" (Delete account, error colour)
  - sub "Cần chuyển chủ hồ sơ của Teddy, Na cho Minh trước" (Must transfer ownership of Teddy's and Na's profiles to Minh first)
- Rules: sign-in methods = Email (verified) + Apple (linkable/unlinkable); device list with per-device remote sign-out (current device labelled "Máy này" with city); DELETE-ACCOUNT PRECONDITION: user must transfer baby-profile ownership to another member (here Minh) before account deletion — card appears disabled/blocked state with the precondition as sub-text. Unlink Apple presumably only allowed if another method (email) exists.

---

## Cross-screen rules summary
- Storage: 10 GB per family, shared across all babies; counted from all uploaders (ba & mẹ). Warning state ~80% (82% shown, sunshine banner); full state 100% (error banner, uploads paused, new items held on device, care logs unaffected). Expansion only via admin request (email reply 1–2 business days), options +10/+20/Khác.
- Baby profiles: max 3 per account ("Thêm bé · 2/3"); single owner per baby; only owner can delete; delete = type nickname to confirm, permanent, family-wide, shows freed GB & members losing access, advises downloading photos first.
- Baby fields: photo, nickname ("Tên thân mật"), birth date, time zone, sex optional (Bé gái / Bé trai / Không nêu). Relatives only see nickname.
- User profile: display name + per-baby role ("Bạn là ai với bé"); family sees name & role on logs/shares.
- Role-based Me screens: Owner/parent (full rows incl. Storage, Baby profiles); Caregiver (Bảo mẫu) — "Bé được giao", tabs Today/Family/Me (no Memories); Relative (người thân) — "Các bé bạn theo dõi", tabs Memories/Family/Me (no Today). Both have Thông báo, Giao diện, Tài khoản & đăng nhập ("Email, Apple, đổi máy"), Trợ giúp & liên hệ, Đăng xuất.
- Account deletion precondition: transfer baby-profile ownership first.

## Nodes status
All 12 nodes read fully via get_design_context (no rate-limit errors): 194:267, 194:377, 195:18, 195:177, 197:286, 197:391, 199:83, 199:168, 199:292, 199:385, 199:501, 199:602.
Not shown in these frames: parent/owner "Tôi" root screen (13a/13b presumably), role-picker sheet, time-zone picker, "Khác" amount input, ownership-transfer flow, delete-account confirmation.
