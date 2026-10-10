# C · Roles & multi-baby · Reminders · Offline/sync/lost access · Caregiver

Source: Figma `sJLG1fAXKDnDr9YI6Yx8ex`, Screens page `26:2` (sections 7, 8, 9, 12) + Components page `7:4`. Read-only extraction, 2026-10-10.
Method: `get_design_context` on each Light frame or its sub-nodes (copy, annotations, component descriptions, screenshots), plus the local metadata dump `_screens_meta.xml` for structure. Night-care variants were compared with Light by layer name and order (see §Night). Copy is quoted verbatim in Vietnamese, with an English gloss in (parentheses). Anything marked *(inferred)* is my reading, not something the design shows.

> Note on frame annotations: every frame in these sections has the same `data-annotations` text, copied from the Today screen. It reads "Thẻ lớn = vừa ghi vừa xem: chạm thẻ → mở sheet ghi mục đó (1 chạm); dòng dưới là lần cuối (bao lâu trước · chi tiết · ai ghi). Ngủ khi timer chạy → CareTile Tone=Active hiện thời gian đang chạy. Tăng trưởng: hàng riêng, + mở màn nhập số đo. “Lịch sử” → dòng thời gian." It applies to the Today tiles only. It is not specific to reminders, offline, and the other screens here.

---

## Navigation per role (NavBar evidence from screens)

| Role | Tabs in NavBar (in order) | Quick-log (+) button | Evidence |
|---|---|---|---|
| Ba mẹ / Cùng nuôi (parent, co-parent) | Hôm nay · Kỷ niệm · Gia đình · Me (avatar initial) | Yes | 125:13223, 125:13338, 127:13602 (avatar "M" = Mẹ) |
| Người chăm sóc (caregiver) | Hôm nay · Gia đình · Me (avatar) | Yes | 124:13717 (avatar "L" = Cô Lan); section label "7a Người chăm sóc · 2 tab" (2 content tabs + Me) |
| Người thân (relative) | Kỷ niệm · Gia đình · Me (avatar) | **No** | 124:13778 (avatar "H"); section label "7b Người thân · 2 tab · vào Kỷ niệm" (lands on Kỷ niệm) |

The NavBar component description says: "Each tab shows icon + label (caption) … Active tab: nav-active pill … Swap the Active variant per screen." The TabDock component description says: "Tab dock = NavBar + QuickLogButton". On the relative's screen the dock has no QuickLogButton.

---

## 7 · Vai trò & nhiều bé (Roles & multiple babies)

### 7a · `124:13717` Hôm nay · Người chăm sóc (Today, caregiver view)
- **Purpose:** the caregiver's home screen. It shows the same care dashboard parents see, with fewer tabs.
- **Header:** BabySwitcher "Teddy · 3 tuần" with a chevron (component 45:321: "chevron when the family has more than one baby. Shows whose log you are viewing"), and a Night-care toggle (moon icon).
- **Copy:** "Thứ Năm, 8 tháng 10" / "Hôm nay".
- **Care tiles:** these show the last entry of each type and who logged it. Records by other members are visible.
  - Bú bình "120 ml · 45 phút trước · Mẹ ghi" (Bottle 120 ml · 45 min ago · logged by Mom)
  - Bú mẹ "15 phút · Kết thúc 3 giờ 35 phút trước · Mẹ ghi"
  - Giấc ngủ "Đã thức 2 giờ · Dậy lúc 13:05 · Ba ghi" (Awake 2 h · woke 13:05 · logged by Dad)
  - Thay tã "Tã ướt · 1h 25p trước · Cô Lan ghi" (wet diaper, logged by the caregiver herself)
  - Hút sữa "90 ml · 2 giờ trước · Mẹ ghi"
  - Tăng trưởng "4,3 kg · 54,5 cm · +0,4 kg · hôm nay"
- **ReminderPeek:** "Nhắc việc · 3" / "Tiêm 6 trong 1" / "Thứ Bảy 08:30 · còn 2 ngày" (Reminders · 3 / 6-in-1 vaccine / Sat 08:30 · 2 days left). Tapping it opens the reminder list (component 128:665).
- **SectionHeader:** "Hôm nay" with the link "Lịch sử", which opens the timeline.
- **DayRhythm "Đã ghi hôm nay"** (Logged today): "2 cữ · 240 ml", "1 cữ · 15 phút", "Ngủ (đã xong) 7 giờ 50", "Thay tã 2 lần". A 24-hour strip (0h–24h) has a legend: Ngủ / Bú bình / Bú mẹ / Tã. Component note: "Running sleep is not counted until it ends."
- **Interactions:**
  - Tapping a tile opens the log sheet for that type in one tap.
  - The + button opens the chooser "(Bú · Ngủ · Tã · Tăng trưởng)" (QuickLogButton 44:363, a11y label "Ghi nhanh").
  - The Night toggle switches the theme.
  - The BabySwitcher opens "Chọn bé" (Choose baby).
- **Permissions shown:** the caregiver can log every care type (+ button and tiles). The caregiver sees records from Mẹ and Ba. There is no Kỷ niệm tab.

### 7b · `124:13778` Kỷ niệm · Người thân (Memories, relative view)
- **Purpose:** a relative lands on Memories and sees only content shared with the family.
- **Header:** BabySwitcher "Teddy · 3 tuần" and the Night toggle. Subtitle "Chia sẻ với gia đình" (Shared with family). Title "Kỷ niệm". Month picker "Tháng 10 ▾".
- **MemoryCard 1:** milestone chip "Lần đầu cười" (First smile). Caption "Teddy cười khi nghe tiếng ba hát." Meta "3 tuần · 6 thg 10". Audience chip "Gia đình".
- **MemoryCard 2** (text only): "Lần đầu ra công viên, con ngủ suốt." / "Thứ Hai · 5 thg 10" / audience "Gia đình".
- **What is absent:**
  - No "Chỉ ba mẹ" items are visible. *(inferred: relatives are filtered to the Gia đình scope.)*
  - No add or upload control.
  - No quick-log button.
  - No Hôm nay tab.
  - No reaction button is drawn on these cards. Reactions ("thả thương") are covered in another section.
- MemoryCard component (10:122): "the audience is always visible (Gia đình / Chỉ ba mẹ)".

### 7c · `125:13223` Chọn bé (Choose baby) — bottom sheet, viewed by the parent "Mẹ"
- Sheet title "Chọn bé", with a close X (a11y "Đóng").
- **Rows** (avatar · name · "age · your role"):
  - "Teddy" — "3 tuần · Bạn là Mẹ" ✓ (selected, mint-soft background)
  - "Na" — "14 tháng · Bạn là Mẹ"
  - "Bin" — "2 tuổi · Bạn là **Người chăm sóc**" (you are the Caregiver for Bin)
- **Add row:** "+ Thêm hồ sơ bé" (Add baby profile) with the counter **"2/3"**.
- **Footnote (verbatim rule):** "Bạn tạo được tối đa 3 hồ sơ bé." (You can create at most 3 baby profiles.)
- **Business meaning:**
  - Role is **per baby, per membership**. The same person is Mẹ for Teddy and Na but Người chăm sóc for Bin.
  - The relationship or role label shows on every row.
  - The cap of 3 counts profiles **you created**. Three babies are listed, but the counter reads 2/3 because Bin belongs to someone else. *(inferred from 2/3 with 3 rows)*
  - The switcher lists every baby you hold a membership for, across families. *(inferred)*

### 7d · `125:13338` Hôm nay · Na (after switching baby)
- Section label: "7d Đổi bé → nội dung đổi theo" (switch baby → content follows).
- **Toast:** "Đã chuyển sang Na" (Switched to Na).
- **Header:** "Na · 14 tháng".
- **Tiles change to Na's data:**
  - Bú bình "180 ml · 2 giờ trước · Ba ghi"
  - Bú mẹ **"Chưa có" / "hôm nay"** (none today; this is the empty state). The component spec gives the empty state as "Chưa có / Chạm để ghi".
  - Giấc ngủ "Đã thức 1 giờ · Dậy lúc 14:00 · Bà ghi" (logged by Grandma)
  - Thay tã "Bẩn · 3 giờ trước · Mẹ ghi"
  - Tăng trưởng full width "9,6 kg · 76 cm · đo 1 thg 10"
- **There is no Hút sữa tile for Na.** The tile set is per baby. *(inferred: driven by each baby's "Chọn theo dõi" tracking choices)*
- **ReminderPeek changes:** "Nhắc việc · 1" / "Mua bỉm size L" / "Hôm nay 18:00". **Reminders are scoped per baby.**
- **DayRhythm:** "3 cữ · 480 ml", Bú mẹ "—", "Ngủ (đã xong) 11 giờ 20", "Thay tã 3 lần".
- **What changes on a switch:**
  - header and avatar
  - all tiles and the tile set
  - recorder names
  - reminders and their count
  - day totals and timeline
  - the role, and with it the NavBar tabs and rights. From 7c, switching to Bin would put Mẹ into the caregiver UI. *(inferred: not drawn)*

---

## 8 · Nhắc việc (Reminders, S15–S16)

Section labels: "8a S15 Danh sách", "8b S16 Tạo nhắc việc", "8c Xin quyền sau lần lưu đầu" (ask permission after the first save), "8d Từ chối quyền · vẫn đã lưu" (permission denied · still saved), "8e Chi tiết · đánh dấu xong" (detail · mark done).

### 8a · `127:13602` Nhắc việc · Danh sách (list, parent view)
- **Header:** Back button (a11y "Quay lại") and BabySwitcher "Teddy · 3 tuần". The switcher here means the list is per baby. Overline "Teddy". Title "Nhắc việc".
- **Groups, in this order:**
  1. **"Quá hạn"** (Overdue): "Mua sữa công thức" — red meta "Quá hạn · hôm qua 18:00 · Ba tạo" (Overdue · yesterday 18:00 · created by Dad). The check ring is red.
  2. **"Sắp tới"** (Upcoming):
     - "Tiêm 6 trong 1" — "Thứ Bảy, 10 thg 10 · 08:30 · Mẹ tạo"
     - "Tái khám rốn" — "Thứ Hai, 12 thg 10 · 09:00 · Mẹ tạo"
  3. **"Đã xong"** (Done): "Khám 1 tháng" — "Ba đánh dấu xong · 6 thg 10" (Dad marked done · 6 Oct). It has a filled mint check, muted text and no chevron.
- **Info line** (clock icon): **"Gia đình thấy nhắc việc trong app. Thông báo chỉ được đặt trên máy tạo nhắc việc."** (Family sees reminders in-app. Notifications are only set on the device that created the reminder.)
- **Primary button:** "+ Nhắc việc mới" (New reminder), which opens the 8b sheet.
- **Row behaviour:**
  - The leading circle marks the reminder done. *(inferred)*
  - The chevron opens the detail screen (8e).
  - Meta shows the creator ("X tạo"). Done rows show who completed it and when ("X đánh dấu xong · date").
- **ReminderRow component** (126:683) has states `Upcoming | Overdue | Done`:
  - Overdue uses the error colour for the ring and meta.
  - Done shows a mint check, muted text and no chevron.
- **NavBar:** parent dock with Hôm nay active. Reminders sit under Today.

### 8b · `127:13728` Tạo nhắc việc (create, bottom sheet)
- Sheet title **"Nhắc việc mới"**, with a close X.
- **Fields:**
  - TextField **"Việc cần nhớ"** (Thing to remember), e.g. "Tiêm 6 trong 1"
  - DetailRow **"Ngày giờ"** (Date & time): "T7, 10 thg 10 · 08:30" ›
  - DetailRow **"Báo trước"** (Advance notice): "1 giờ" ›. The list of options is not designed; only "1 giờ" is shown.
- **Footnote (verbatim):** **"Theo giờ của Teddy (GMT+7). Gia đình thấy nhắc việc trong app. Thông báo chỉ được đặt trên máy tạo nhắc việc."** (In Teddy's timezone (GMT+7)…). Reminder times use the **baby's timezone**.
- **Primary button:** **"Lưu nhắc việc"** (Save reminder).
- **Not present:**
  - repeat/recurrence
  - assignee
  - note
  - baby picker. The baby is the one currently selected.
  - delete

### 8c · `127:13809` Xin quyền thông báo (notification permission pre-prompt, after the first save)
- **Behind the sheet:** the list, plus the toast **"Đã lưu nhắc việc"** (Reminder saved). The reminder is saved *before* permission is requested.
- **Sheet** `127:13843`:
  - title **"Bật thông báo trên máy này?"** (Turn on notifications on this device?)
  - body "Gia đình thấy nhắc việc trong app. Thông báo chỉ được đặt trên máy tạo nhắc việc."
  - primary **"Bật thông báo"** (Turn on notifications), which then triggers the OS permission dialog *(inferred)*
  - plain **"Để sau"** (Later)

### 8d · `127:13867` Đã lưu · chưa bật thông báo (saved, notifications off)
- **Header:** Back, BabySwitcher, Night toggle. Overline "Teddy", title "Nhắc việc".
- **Notice card** at the top: **"Đã lưu nhắc việc. Chưa bật thông báo trên máy này."** (Reminder saved. Notifications are not enabled on this device.) It has the link **"Cài đặt"** (Settings), which deep-links to OS settings *(inferred)*.
- The list is unchanged. The reminder is kept even though permission was denied or deferred.

### 8e · `127:13910` Chi tiết nhắc việc (detail)
- **Header:** Back and BabySwitcher. Overline **"Nhắc việc · Teddy"**. Title "Tiêm 6 trong 1".
- **Detail rows** (each has a chevron):
  - "Ngày giờ" = "T7, 10 thg 10 · 08:30"
  - **"Múi giờ"** (Timezone) = "GMT+7"
  - "Báo trước" = "1 giờ"
  - **"Thông báo"** (Notification) = **"iPhone của Mai"**. This is the device that holds the local notification, named after the creator's device.
  - **"Người tạo"** (Creator) = "Mẹ · 8 thg 10"
- **Note:** **"Thông báo chỉ được đặt trên máy tạo nhắc việc. Đánh dấu xong khi đã làm."** (… Mark done once it's done.)
- **Buttons:** primary **"✓ Đánh dấu đã xong"** (Mark as done); plain **"Sửa nhắc việc"** (Edit reminder).
- **Not designed:** delete or cancel reminder, undo done, snooze.

---

## 9 · Offline, đồng bộ & mất quyền (Offline, sync & lost access)

Section labels: "9a Offline · chờ đồng bộ", "9b Sheet chờ đồng bộ", "9c Timer offline (S12)", "9d Mất quyền / bị xoá" (lost access / removed).

### 9a · `127:14758` Hôm nay · Offline
- **Sync banner** sits directly under the header. It has a sunshine-soft background, a cloud-off icon and a chevron.
  - Copy: **"Đang offline · 2 bản ghi chờ đồng bộ"** (Offline · 2 records waiting to sync).
  - Tapping it opens the 9b sheet. *(inferred from the chevron and the 9b sheet)*
- **Pending tiles** replace the "who logged" line with **"Chờ đồng bộ"** (Waiting to sync), shown in the `--pending` colour (#7a5600):
  - Bú bình "120 ml · 45 phút trước · Chờ đồng bộ"
  - Thay tã "Tã ướt · 1h 25p trước · Chờ đồng bộ"
- **Cached data still shows:**
  - other tiles, e.g. "Mẹ ghi", "Ba ghi"
  - ReminderPeek
  - DayRhythm totals. Totals include the pending local entries ("2 cữ · 240 ml", "2 lần"). *(inferred: local-first aggregation)*
- **Logging stays available offline:** the TabDock and the + button are still shown.

### 9b · `127:14970` Bản ghi chờ đồng bộ (pending-sync sheet, `127:15024`)
- Sheet title **"Chờ đồng bộ"** (Waiting to sync), with a close X.
- **Items** (TimelineItem, Pending variant):
  - "14:20 · Bú bình · 120 ml", chip **"Chờ"** (cloud-off icon), sub-line **"Chỉ lưu trên máy này"** (Saved only on this device)
  - "13:40 · Thay tã · Ướt", chip "Chờ", sub-line "Chỉ lưu trên máy này"
- **Footnote:** **"Tự gửi khi có mạng. Người cùng chăm chưa thấy các bản ghi này."** (Sends automatically when online. Co-carers can't see these records yet.)
- **Button:** secondary **"Thử lại ngay"** (Retry now).
- **Not designed:** discard or delete a pending item, per-item retry, per-item error state, conflict messaging.
- **Component rules:**
  - TimelineItem: "Pending = saved on device, waiting to sync."
  - LogRow (45:373): "Pending = saved on this device, waiting to sync (icon + words, never colour alone). Tap → record detail." Its pending chip reads "Chờ đồng bộ".

### 9c · `127:15087` Timer ngủ · Offline (S12)
- **Frame annotation (specific to this screen, verbatim):** "Tự bật Night care khi timer chạy trong lịch đêm. Vòng “thở” (duration-breath). Kết thúc → lưu giấc ngủ, haptic success. “Hủy, không lưu” hỏi xác nhận. Timer tiếp tục khi khóa máy (Live Activity)."
  - Gloss: Night care turns on automatically when the timer runs during the night schedule. Breathing ring. Ending saves the sleep with a success haptic. "Cancel, don't save" asks for confirmation. The timer continues on the lock screen (Live Activity).
- **Header:** Back button and the SyncStatus pill (Pending) **"Chỉ trên máy này"** (Only on this device).
- **Title:** "Bé Teddy đang ngủ" (Baby Teddy is sleeping). Sub-line "Ba bắt đầu lúc 21:42" (Dad started at 21:42).
- **Offline note** (cloud-off): **"Giấc ngủ này chưa được đồng bộ"** (This sleep hasn't been synced yet).
- **SleepTimer:** "Đang ngủ" / "01:27:06" / "Từ 21:42".
- **Buttons:**
  - primary **"Kết thúc giấc ngủ"** (End sleep)
  - secondary **"Sửa giờ bắt đầu"** (Edit start time)
  - plain **"Hủy, không lưu"** (Cancel, don't save), which needs a confirm step
- **Meaning:** a timer started offline exists only on that device. Other carers cannot see that the baby is sleeping until it syncs. *(inferred, consistent with 9b's footnote)*

### 9d · `127:15135` Mất quyền truy cập (lost access / removed member)
- **Layout:** TopBar with Back; Illustration/Expired (hourglass; component note: "calm … no alarm colours").
- **Title:** **"Bạn không còn quyền xem hồ sơ này"** (You no longer have permission to view this profile).
- **Body (rendered text):** **"Quyền của bạn đã thay đổi. Nội dung trên máy này đã được ẩn."** (Your permissions have changed. Content on this device has been hidden.)
  - The layer *name* says "Nhờ người mời gửi link mới nhé" (Ask the inviter to send a new link). That is a stale layer name; use the rendered text.
- **Buttons:**
  - primary **"Về trang chính"** (Go to home). It probably goes to the next baby you can still access, or onboarding. *(inferred)*
  - secondary **"Xin lời mời mới"** (Request a new invite)
- **Business meaning:** when access is revoked, cached local content must be hidden or purged on the device.

### Sync component states (Components page)
- **SyncStatus `8:84`** variants:
  - Synced "Đã đồng bộ" (mint)
  - Pending "Chờ đồng bộ · 2" (sunshine/pending)
  - Error "Chưa lưu được" (error)
- SyncStatus description: "always icon + words, never colour alone … Pending copy “Đã lưu trên máy này. Đang chờ đồng bộ.” … **Pending saves must survive an app restart.**"
- **Banner/Error `8:85`:** **"Chưa lưu được. Thử lại, nội dung vẫn ở đây."** (Couldn't save. Try again, your content is still here.) It is meant to be paired with a Tinted **"Thử lại"** (Retry) button.

---

## 12 · Người chăm sóc (Caregiver: nanny, grandparents looking after the baby)

### 12a · `192:19` RULES — "Người chăm sóc làm được gì?" (What can a caregiver do?), verbatim
**✓ Thấy & làm** (See & do)
- "• Hôm nay: ghi bú, ngủ, tã, hút sữa, tăng trưởng" (Today: log feeding, sleep, diaper, pumping, growth)
- "• Lịch sử chăm sóc của bé được giao" (Care history of the assigned baby)
- "• Nhắc việc: xem và đánh dấu xong" (Reminders: view and mark done)
- "• Danh sách gia đình (chỉ xem)" (Family list, view only)

**✎ Sửa được** (Can edit)
- "• Chỉ bản ghi do chính mình tạo" (Only records they created themselves)
- "• Bản ghi của ba mẹ: chỉ xem" (Parents' records: view only)

**✕ Không thấy** (Cannot see)
- "• Tab Kỷ niệm: ảnh, album, câu chuyện" (Memories tab: photos, albums, stories)
- "• Ngày sinh và hồ sơ đầy đủ của bé" (Baby's date of birth and full profile)
- "• Mời người, đổi quyền, dung lượng" (Inviting people, changing permissions, storage)

### 12b · `192:47` Hôm nay · người chăm
- Visually identical to 7a (screenshot compared): same tiles, ReminderPeek and DayRhythm.
- Caregiver NavBar: Hôm nay · Gia đình · Me "L", plus the + button.
- Section label: "12b Hôm nay · Hôm nay · Gia đình" (the caregiver has only the Today and Family tabs).

### 12c · `192:337` Ghi nhanh · người chăm (quick log sheet `192:365`)
- Sheet title **"Ghi nhanh"** (Quick log).
- Six ChoiceTiles: "Bú bình", "Bú mẹ", "Ngủ" / "Thay tã", "Tăng trưởng", "Hút sữa".
- The caregiver gets the same full log set as parents.
- ChoiceTile description: "Remembers the last choice."

### 12d · `192:618` Lịch sử · người chăm (history: edit only own records)
- **Header:** Back and BabySwitcher "Teddy". Title "Lịch sử", Month picker "Tháng 10".
- **Role note** (lock icon): **"Bạn sửa được bản ghi của mình. Bản ghi của ba mẹ chỉ xem."** (You can edit your own records. Parents' records are view-only.)
- **Day strip:** "T6 2 … T5 8". DayPill note: "Today is the right-most pill; swipe for earlier weeks."
- **Filters** (single-select): "Tất cả", "Bú", "Hút sữa", "Ngủ", "Tã", "Tăng trưởng".
- DayRhythm.
- **Timeline** by time of day:
  - **Chiều 13:00–18:00 · 2 mục**
    - 14:20 "Bú bình · 120 ml" / "Mẹ ghi"
    - 13:40 "Thay tã · Ướt" **[Chờ]** / "Cô Lan ghi" (the caregiver's own record, still pending)
  - **Trưa 11:00–13:00 · 2 mục**
    - 11:45 "Ngủ 1 giờ 20 phút" / "11:45 – 13:05 · Ba ghi" (span block)
    - 11:30 "Bú mẹ · Cả hai bên" / "15 phút · Mẹ ghi" (span block)
  - **Sáng 05:00–11:00 · 3 mục**
    - 10:15 "Hút sữa · 90 ml" / "Cả hai bên · 15 phút · Mẹ ghi"
    - 09:10 "Thay tã · Cả hai" / "Mẹ ghi"
    - 08:00 "Bú bình · 120 ml" / "Ba ghi"
  - **Đêm 22:00–05:00 · 1 mục**
    - 00:00 "Ngủ 6 giờ 30 phút" / "21:42 hôm qua – 06:30 · Ba ghi"
- **Annotation** (on 12e's frame, whose background is this screen): "Dòng thời gian mới nhất ở trên, chia theo buổi (Sáng/Trưa/Chiều/Tối). Giấc ngủ và bú mẹ là khối có thời lượng. Chạm mục → Chi tiết bản ghi. Lọc “Tăng trưởng” hiện các lần đo."
  - Gloss: newest first, grouped by time of day; sleep and breastfeeding are duration blocks; tapping an item opens record detail; the "Tăng trưởng" filter shows measurements.
- **TimeSectionHeader `59:431` description:** "Sáng (05–11) · Trưa (11–13) · Chiều (13–18) · Tối (18–22) · Đêm (22–05)".

### 12e · `192:32463` Bản ghi của Mẹ · chỉ xem (caregiver taps a parent's record)
- **Record detail sheet `192:1298`:** icon, **"Bú bình · 120 ml"**, "Hôm nay · 09:20 · Mẹ ghi".
- **Rows:**
  - "Lượng" (Amount) = "120 ml"
  - "Loại sữa" (Milk type) = "Sữa công thức" (formula)
  - "Ghi chú" (Note) = "Bé bú hết, ợ hơi tốt"
- **Role note** (lock): **"Bản ghi của Mẹ · chỉ xem. Nếu sai, nhắn Mẹ để sửa."** (Mom's record · view only. If it's wrong, message Mom to fix it.)
- **Button:** secondary **"Nhắn Mẹ"** (Message Mom).
- **Not shown:** edit and delete buttons.
- **Gap:** the destination of "Nhắn Mẹ" is not designed. It could be in-app chat, an OS share sheet, SMS or Zalo.

### 12f · `192:1327` Nhắc việc · người chăm (reminders: mark done only)
- Same groups and rows as 8a: Quá hạn / Sắp tới / Đã xong, the same info line, and chevrons into the detail screen.
- **There is no "+ Nhắc việc mới" button.**
- **Role note** (clock): **"Ba mẹ tạo nhắc việc. Bạn xem và đánh dấu Xong."** (Parents create reminders. You view and mark Done.)

### 12g · `192:1438` Gia đình · người chăm (family: view only, no invites)
- Overline **"Những người cùng chăm Teddy"** (People caring for Teddy). Title "Gia đình".
- **MemberRow list** (format: "relationship · role"):
  - "Mai" — "Mẹ · Cùng nuôi" ›
  - "Minh" — "Ba · Cùng nuôi" ›
  - "Cô Lan" — "Bảo mẫu · Người chăm sóc" with badge **"Bạn"** (You)
  - "Bà nội Hoa" — "Bà · Người thân" ›
- **Hidden layers:** the "Pending" section (SectionHeader `192:1455`, Pending `192:1457`) exists in the layers but does not render. Caregivers do not see pending invites.
- **Only action:** plain button **"Rời khỏi gia đình này"** (Leave this family).
- There is no invite ("Mời") button and no permission controls.
- **MemberRow `115:704`** has states `You | Member | Pending`. The Pending state shows a "Gửi lại" (Resend) pill, which is parent-only *(inferred)*.

---

## Components (page 7:4) referenced

| Component | Node | Variants / props | Behaviour notes (verbatim description) |
|---|---|---|---|
| NavBar | 44:362 | role Parent/Caregiver/Relative × active Today/Memories/Family/Me; `initial` | Parent: Today, Memories, Family, Me. Caregiver: Today, Family, Me. Relative: Memories, Family, Me. The Me label is **"Tôi"**. "visible labels beat icon-only for tired parents and for VoiceOver parity." |
| ReminderRow | 126:683 | state Upcoming / Overdue / Done; title; meta | Overdue = error ring + error meta. Done = filled mint check, muted text, no chevron. |
| ReminderPeek | 128:665 | label, title, meta | "Home entry to reminders (S15): next upcoming reminder + count. Tap opens reminder list." |
| SyncStatus | 8:84 | Synced "Đã đồng bộ" / Pending "Chờ đồng bộ · 2" / Error "Chưa lưu được" | "always icon + words, never colour alone … Pending saves must survive an app restart." |
| Banner/Error | 8:85 | — | "Chưa lưu được. Thử lại, nội dung vẫn ở đây." + Tinted "Thử lại" |
| LogRow (Pending) | 45:373 | pending bool | "Chờ đồng bộ" chip; "Tap → record detail" |
| MemberRow | 115:704 | status You / Member / Pending | You → "Bạn" badge; Member → chevron; Pending → outlined avatar + "Gửi lại" |
| BabySwitcher | 45:321 | name | "chevron when the family has more than one baby. Shows whose log you are viewing." |

### Night care variants
Night frames have the same layer names and order as their Light frames: 127:15330, 127:15528, 127:15611, 127:15880, 127:16067–16524, 127:16629–17154, and 195:32740–33761. No Night frame shows a behaviour difference. One frame-level behaviour applies: 9c says Night care turns on automatically when a sleep timer runs during the night schedule.

---

## Permission matrix (confirmed from design)

Legend: ✅ confirmed · ❌ confirmed absent or forbidden · ◐ partial · ? not designed · *(inf)* inferred

| Capability | Cùng nuôi / Ba mẹ | Người chăm sóc | Người thân | Evidence |
|---|---|---|---|---|
| Tabs | Hôm nay, Kỷ niệm, Gia đình, Tôi | Hôm nay, Gia đình, Tôi | Kỷ niệm, Gia đình, Tôi | NavBar 44:362; 124:13717; 124:13778 |
| Default landing tab | Hôm nay | Hôm nay | **Kỷ niệm** | 7b label "vào Kỷ niệm" |
| Quick log (+) all 6 types | ✅ | ✅ (Bú bình, Bú mẹ, Ngủ, Thay tã, Tăng trưởng, Hút sữa) | ❌ (no + button) | 192:365; 12a; 124:13778 |
| See Today tiles and others' records | ✅ | ✅ ("Mẹ ghi", "Ba ghi" visible) | ❌ by default; can be granted *(see note 1)* | 124:13717 |
| Care history (Lịch sử) | ✅ | ✅ "of the assigned baby" | ? (only via grant) | 12a, 192:618 |
| Edit or delete **own** care records | ✅ | ✅ | n/a | 12a "Chỉ bản ghi do chính mình tạo"; 12d role note |
| Edit or delete **others'** care records | ✅ *(inf: co-manage)* | ❌ view only; "Nếu sai, nhắn Mẹ để sửa" + "Nhắn Mẹ" | ❌ | 12a; 192:1298 |
| See reminders | ✅ | ✅ | ? (not designed) | 8a; 12f |
| Create reminder | ✅ ("+ Nhắc việc mới") | ❌ ("Ba mẹ tạo nhắc việc") | ❌ *(inf)* | 127:13602; 192:1436 |
| Edit reminder | ✅ ("Sửa nhắc việc") *(any parent or only the creator? — open)* | ❌ *(inf from "chỉ đánh dấu xong")* | ❌ | 127:14005; 12f label |
| Mark reminder done | ✅ ("Ba đánh dấu xong") | ✅ ("Bạn xem và đánh dấu Xong") | ? | 8a; 12f |
| Delete or cancel reminder | ? not designed | ❌ | ❌ | — |
| Memories tab (photos, albums, stories) | ✅ (both scopes) | ❌ "Tab Kỷ niệm: ảnh, album, câu chuyện" | ✅ "Gia đình" scope only *(inf: no "Chỉ ba mẹ" shown)* | 12a; 124:13778 |
| Baby DOB / full profile | ✅ | ❌ | ❌ by default *(plan: grantable)* | 12a |
| Family list | ✅ manage | ✅ view only (sees all members, relationship and role) | ✅ tab present (contents in another section) | 12g; NavBar |
| See pending invites | ✅ *(inf: MemberRow Pending + "Gửi lại")* | ❌ (hidden layers) | ? | 192:1457 hidden; 115:704 |
| Invite, change permissions, storage | ✅ | ❌ "Mời người, đổi quyền, dung lượng" | ❌ | 12a |
| Leave family | ✅ *(inf)* | ✅ "Rời khỏi gia đình này" | ✅ *(inf)* | 192:1460 |
| Switch baby | ✅ | ✅ (BabySwitcher with chevron) | ✅ (BabySwitcher with chevron) | 124:13717; 124:13778 |
| Create baby profile | ✅ up to 3 created by you | ? *(inf ❌)* | ? *(inf ❌)* | 125:13335 "2/3" |

**Note 1 — extra grants.** The product plan says "Parents can grant extra view of baby info or daily care" to Người thân. These screens do not show a granted state; see section 14b, 116:11916, which is outside this extraction. The 12a rules frame lists no extra grants for caregivers.

**Note 2 — scope.** Every right is **per baby (membership)**. 7c shows one user as "Mẹ" for Teddy and Na and as "Người chăm sóc" for Bin.

---

## Business rules confirmed (verbatim evidence)

1. **Caregiver scope** (12a, 192:19): "Hôm nay: ghi bú, ngủ, tã, hút sữa, tăng trưởng" · "Lịch sử chăm sóc của bé được giao" · "Nhắc việc: xem và đánh dấu xong" · "Danh sách gia đình (chỉ xem)".
2. **Caregiver edit rights:** "Chỉ bản ghi do chính mình tạo" · "Bản ghi của ba mẹ: chỉ xem" (12a). On-screen: "Bạn sửa được bản ghi của mình. Bản ghi của ba mẹ chỉ xem." (192:32478). In record detail: "Bản ghi của Mẹ · chỉ xem. Nếu sai, nhắn Mẹ để sửa." (192:1320).
3. **Caregiver cannot see:** "Tab Kỷ niệm: ảnh, album, câu chuyện" · "Ngày sinh và hồ sơ đầy đủ của bé" · "Mời người, đổi quyền, dung lượng" (12a).
4. **Reminders, caregiver:** "Ba mẹ tạo nhắc việc. Bạn xem và đánh dấu Xong." (192:1436).
5. **Reminder visibility vs notification:** "Gia đình thấy nhắc việc trong app. Thông báo chỉ được đặt trên máy tạo nhắc việc." (127:13681, repeated in 8b, 8c, 12f). Notifications are **local** and scheduled only on the creator's device. The detail screen shows the holding device: "Thông báo: iPhone của Mai" (8e).
6. **Reminder timezone:** "Theo giờ của Teddy (GMT+7)." (127:13803). The detail screen has a "Múi giờ: GMT+7" row. Reminders use the **baby's timezone**.
7. **Permission timing:** the reminder is saved first (toast "Đã lưu nhắc việc"), *then* the pre-prompt "Bật thông báo trên máy này?" appears with "Bật thông báo" / "Để sau" (8c). Section label: "Xin quyền sau lần lưu đầu".
8. **Denied permission keeps the reminder:** "Đã lưu nhắc việc. Chưa bật thông báo trên máy này." with "Cài đặt" (8d). Section label: "Từ chối quyền · vẫn đã lưu".
9. **Reminder states:** "Quá hạn" / "Sắp tới" / "Đã xong". Done records the actor and date ("Ba đánh dấu xong · 6 thg 10"). Creator attribution: "Mẹ tạo" / "Ba tạo"; detail row "Người tạo: Mẹ · 8 thg 10".
10. **Profile cap:** "Bạn tạo được tối đa 3 hồ sơ bé." with counter "2/3" (125:13336, 125:13335).
11. **Role is shown per baby:** "Bạn là Mẹ" / "Bạn là Người chăm sóc" (7c).
12. **Baby switch:** toast "Đã chuyển sang Na". Tiles, reminders, totals and recorder names all change to that baby (7d).
13. **Offline pending:**
    - "Đang offline · 2 bản ghi chờ đồng bộ" (9a)
    - "Chỉ lưu trên máy này" (9b)
    - "Tự gửi khi có mạng. Người cùng chăm chưa thấy các bản ghi này." (9b)
    - "Thử lại ngay" (9b)
    - SyncStatus: "Pending saves must survive an app restart."
14. **Offline timer:** "Chỉ trên máy này" · "Giấc ngủ này chưa được đồng bộ". Annotation: "Kết thúc → lưu giấc ngủ, haptic success. “Hủy, không lưu” hỏi xác nhận. Timer tiếp tục khi khóa máy (Live Activity)." and "Tự bật Night care khi timer chạy trong lịch đêm."
15. **Save failure:** "Chưa lưu được. Thử lại, nội dung vẫn ở đây." (Banner/Error 8:85).
16. **Lost access:** "Bạn không còn quyền xem hồ sơ này" · "Quyền của bạn đã thay đổi. Nội dung trên máy này đã được ẩn." · "Về trang chính" · "Xin lời mời mới" (9d).
17. **Relationship is separate from role:** "Bảo mẫu · Người chăm sóc", "Bà · Người thân", "Mẹ · Cùng nuôi" (12g).
18. **Daily totals:** "Running sleep is not counted until it ends." (DayRhythm 48:409). The timeline is grouped as "Sáng (05–11) · Trưa (11–13) · Chiều (13–18) · Tối (18–22) · Đêm (22–05)".

---

## Entities & fields implied

- **Membership** (user × baby):
  - `babyId`, `userId`, `role` ∈ {coParent "Cùng nuôi", caregiver "Người chăm sóc", relative "Người thân"}
  - `relationshipLabel` (free or preset: Mẹ, Ba, Bà, Bảo mẫu, Cô …)
  - `displayName`, `initial`
  - `status` ∈ {active, pending (invite), removed}
  - `extraGrants` (for relatives; see 14b)
- **BabyProfile:**
  - `id`, `name`, `dob` (hidden from caregivers and relatives), `ageLabel`
  - `timezone` (e.g. GMT+7)
  - `trackedTypes` (per-baby tile set: Na has no Hút sữa)
  - `createdBy` (counts toward the cap of 3 profiles per creator)
  - `familyId`
- **CareRecord:**
  - `id`, `babyId`, `type` ∈ {bottle, breast, sleep, diaper, pump, growth}
  - `startAt` / `endAt` (span) or `at` (event)
  - measurements: ml, milk type "Loại sữa", side "Cả hai bên", diaper kind "Ướt/Bẩn/Cả hai", kg/cm
  - `note` ("Ghi chú")
  - `createdBy` (shown as "X ghi")
  - `syncState` ∈ {local-pending, synced, error}
  - `clientOpId` for idempotent sync *(inf)*
- **SleepTimerSession:**
  - `babyId`, `startedBy`, `startAt` (editable via "Sửa giờ bắt đầu")
  - `state` ∈ {running, ended → CareRecord, cancelled}
  - `localOnly` flag while offline
- **Reminder:**
  - `id`, `babyId`, `title` ("Việc cần nhớ"), `dueAt`, `timezone` (baby's)
  - `leadTime` ("Báo trước", e.g. 1 giờ)
  - `createdBy`, `createdAt`
  - `notifyDeviceId` / `deviceName` ("iPhone của Mai")
  - `status` ∈ {upcoming, overdue (derived: dueAt < now and not done), done}
  - `doneBy`, `doneAt`
  - **No** recurrence, **no** assignee.
- **DeviceNotificationSchedule** (local only):
  - reminderId, deviceId, scheduledAt = dueAt − leadTime
  - OS permission state per device ("Chưa bật thông báo trên máy này")
- **LocalOutbox / PendingQueue:** ordered pending writes per device, surviving restart, with count shown in the banner ("2 bản ghi") and a manual retry ("Thử lại ngay").
- **AccessRevocation event:** triggers the 9d screen and a local cache purge or hide.

---

## Open questions / gaps (with node ids)

1. **"Báo trước" options** (127:13792, 127:13965): only "1 giờ" is shown. The full list is not designed (e.g. none, 15 phút, 30 phút, 1 giờ, 1 ngày?).
2. **Date-time picker for reminders** (127:13781): the picker UI is not designed. Can a time in the past be chosen?
3. **Reminder delete or cancel:** no control in 8e (127:13910) or anywhere else. The plan's acceptance list mentions "edit/cancel".
4. **Reminder edit rights:** can any parent edit another parent's reminder, or only the creator? The edit form (from "Sửa nhắc việc") is not designed. Can the "Múi giờ" and "Thông báo" rows in 8e be changed? They have chevrons.
5. **Undo "done":** there is no un-mark control. Done rows have no chevron (126:683 Done), so it is unclear whether the detail of a done reminder can be reopened.
6. **Notification on non-creator devices:** "Thông báo chỉ được đặt trên máy tạo nhắc việc". What happens when the creator's device is lost or logged out, or when the creator leaves the family? Can another member take over notifications via the "Thông báo" row (127:13975)?
7. **Overdue reminders:** the design does not say whether any notification fires or whether they only show red in-app. Timezone change for the baby: are reminders re-scheduled?
8. **Pending-sync sheet** (127:15024): no discard action, no per-item error, no failed or rejected state (e.g. the server rejects because permission was lost while offline). There is no conflict UI. How are two carers' offline records reconciled? (The plan says "never auto-merge" for overlapping sleep; that UI is in another section.)
9. **Offline timer conflict** (127:15087): another carer may start a timer while this one is local-only. The resolution is not designed.
10. **9d trigger and destination** (127:15135): "Về trang chính" goes where if the user has no other baby? Who receives "Xin lời mời mới" (push to inviter? share sheet?)? What happens to the user's unsynced pending records on revocation? Note that the layer name "Nhờ người mời gửi link mới nhé" disagrees with the rendered body.
11. **"Nhắn Mẹ"** (192:1321): the messaging channel is not designed. The app has no chat in these sections.
12. **Relative's access to reminders, care history and Today:** not designed here. The grant-based extra views are in 14b (116:11916). The relative's Gia đình tab contents are not covered in this section.
13. **3-profile cap scope** (125:13335): per user-creator (inferred from 2/3 with 3 babies) or per family? What happens at 3/3? The disabled state is not shown.
14. **Caregiver "bé được giao" (assigned baby):** caregiver membership is per baby. Is there an explicit assignment UI beyond the invite? (See 14b.)
15. **Member detail** (chevrons on MemberRow in 12g, 192:1450/1451/1453): the caregiver's view-only member detail is not designed.
16. **Leave family** (192:1460): confirmation and consequences are not designed. Are records the caregiver created kept? (The plan says yes.)
17. **ReminderPeek empty state:** what shows when there are 0 reminders? Not designed. ReminderPeek shows "còn 2 ngày" (relative countdown); the rule for "Hôm nay 18:00" vs "Thứ Bảy 08:30 · còn 2 ngày" formatting is inferred.
18. **Time-of-day buckets:** the TimeSectionHeader description lists 5 buckets including "Tối (18–22)". The component variants only include Morning/Noon/Afternoon/Night (Đêm 22–05), with no Tối variant (59:431). The plan's day/night split is 06:00–18:00.
19. **Sample-data inconsistency:** the 12e sheet says "Hôm nay · 09:20 · Mẹ ghi", but the timeline has bottle entries at 08:00 (Ba) and 14:20 (Mẹ). This is cosmetic.
20. **Frame annotations:** most frames carry the copied Today annotation. Only 9c (127:15087) and 12e (192:32463) have specific annotations; 9d has none. Interaction details for the 8a row circle (tap-to-complete directly from the list?) are therefore inferred.

---

## Coverage / limits of this extraction
- **Read with `get_design_context`:**
  - frames 124:13717, 124:13778, 125:13223, 125:13338, 127:13602, 127:13728, 127:15087, 127:15135, 192:19, 192:32463, 192:1327, 192:1438
  - sub-nodes 127:13843 (8c sheet), 127:13912 (8e content), 127:15024 (9b sheet), 127:14760 (9a content), 192:365 (12c sheet)
  - components 44:362, 8:84, 8:85, 45:373, 115:704
- **Screenshots only:** 192:47 (12b, identical to 7a) and 192:618 (12d, the same content as the 12e background).
- **From local metadata plus sub-node reads, without a full-frame design_context:** 8c and 8d frames (127:13809, 127:13867). Their frame-level annotations were not read, but the other frames carry the copied Today annotation, so these probably do too.
- **Night variants:** checked structurally via metadata; no Night frames were rendered.
- **Rate limiting:** the Figma MCP rate-limited several times (Pro, Full seat; `whoami` OK). The extraction backed off and completed. No write tools were used.
