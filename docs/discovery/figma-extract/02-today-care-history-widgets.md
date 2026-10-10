# B · Hôm nay & Chăm sóc (Today & Care) + Widgets — product spec extracted from final Figma

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only). Screens page `26:2`: section **5 · Hôm nay & Chăm sóc** (`45:2809`) and section **6 · Widgets** (`76:5439`). Components page widgets frame `73:399`. Extracted 2026-10-10.

**How it was read**
- `get_design_context` was run on every Light frame in scope. Some frames were read as sub-nodes, with the frame annotation read separately. Each call returned code, `data-annotations`, component descriptions and usually a screenshot.
- The Figma MCP returned the Pro/Full-seat **rate-limit error** several times (`whoami`: Duc N., team "pro", Full seat). Each time we backed off and retried. In the end every Light frame in scope was read, except as noted under Coverage below.
- **Night care** variants were checked two ways:
  - A structural diff of all text and instance names, Light vs Night, for every frame in sections 5 and 6 found no differences. Night frames have the same copy and the same instances.
  - Screenshot spot-checks of 109:12017, 76:7129 and 76:7122 found the same copy and states on dark surfaces.
  - Conclusion: Night care has **no behavioural differences**; only the theme changes.
- **Layer names in the local metadata dump can be stale.** Example: in 28 Tăng trưởng the layer is named "+0,8 kg · +3,5 cm…" but the rendered text reads "+0,4 kg · +1,5 cm…". Rendered text from `get_design_context` is authoritative and is what this document quotes.
- The mock scenario is Thursday 8 Oct 2026, now = 15:05. The baby is "Teddy", born 17 Sep (3 weeks old), timezone GMT+7. Family members are Mẹ (Mai, the current user in some screens), Ba and the caregiver Cô Lan.
- "(inferred)" marks anything the design does not state literally.

**Coverage**
- Fully read (Light): 29:904, 103:8099, 103:8275, 46:2266, 50:3572, 46:2469, 104:8724, 104:9429, 104:10130, 105:9063, 105:9471, 108:10271, 109:10562, 110:10949, 111:10994, 46:2649, 46:3141, 46:3234, 112:11135, 106:11118, 113:11207, 46:3308, 69:4213, 47:3028, 47:3074, 47:3145, 47:3210, 76:5441, 76:6650, 76:5703, 76:5779, 76:5852, 84:6579 and Components 73:399.
- Read only from metadata (not from a render): the W5 caption text nodes 84:6580, 84:6581, 84:7022 and 84:7042. Their content agrees with the rendered widget states.
- Night frames 76:6879, 76:6976, 76:7113 and 84:7190 were not rendered. The structural diff shows them identical to Light.

**Contents:** Part A (Today, tour, quick log) · Part B (log sheets, timers, sleep, growth, record detail) · Part C (History, filters, date picker, stats) · Part D (Widgets, Live Activity, Dynamic Island) · Consolidated sections at the end.

---

# Part A — Today (Hôm nay), first-run tour, quick log
## 29:904 — 18 Hôm nay (lần đầu) · Hướng dẫn 1/3 (Light) [Night 29:1275]
Annotation (verbatim, on 29:904, 103:8099, 103:8275): "Trạng thái trống dùng cùng bố cục với Hôm nay có dữ liệu: thẻ giữ màu từng loại, giá trị “Chưa có / Chạm để ghi”. Coachmark tắt sau lần ghi đầu tiên. Không streak, không mục tiêu."
(Empty state uses same layout as Today-with-data; tiles keep per-type colours; value "Chưa có / Chạm để ghi". Coachmark turns off after the first log. No streaks, no goals.)
- Header: BabySwitcher chip "Teddy · 3 tuần" (name · age in weeks) with chevron (component desc: chevron shown only when family has >1 baby; "Shows whose log you are viewing"). Right: "Night care toggle" round button (moon icon, 44px).
- Date line "Thứ Năm, 8 tháng 10" (Thursday, 8 October); large title "Hôm nay".
- 6 CareTiles in 3 rows x 2: Bú bình (bottle, blue), Bú mẹ (breast, pink), Giấc ngủ (sleep, indigo), Thay tã (diaper, green), Hút sữa (pump, purple), Tăng trưởng (growth, orange). Empty value "Chưa có" (none yet) + "Chạm để ghi" (tap to log).
- CareTile component desc (54:530): "Tinted card (care/<type>/soft) with a line icon ..., type label (care ink), key value, ⏱ when, 👤 who logged. Tap = log that type. Sleep running = live elapsed + accent border. Empty = “Chưa có / Chạm để ghi”".
- Section "Hôm nay" + empty card: "Chưa có ghi chép hôm nay." / "Ghi khi gia đình cần nhé. Tổng trong ngày sẽ hiện ở đây." (No entries today. Log when the family needs. Daily totals will show here.)
- TabDock: NavBar tabs Hôm nay (active, labelled) · Kỷ niệm (memories icon) · Gia đình (family icon) · Me (avatar initial "M"); QuickLogButton "+" (desc: "Ghi nhanh (+): opens the quick-log chooser (Bú · Ngủ · Tã · Tăng trưởng). 68px, accessibility label “Ghi nhanh”.").
- Tour overlay: Scrim + Spotlight on Bú bình tile. TourTip: "Bước 1/3" / "Ghi cữ bú đầu tiên" (Log the first feed) / "Chạm thẻ Bú bình để ghi. Các thẻ khác cũng ghi y như vậy." (Tap Bottle tile to log; other tiles work the same) / actions "Bỏ qua" (Skip) · "Tiếp" (Next).

## 103:8099 — 18b Hướng dẫn 2/3 [Night 103:8432]
Same base. Spotlight on Tăng trưởng tile. TourTip: "Bước 2/3" / "Theo dõi Teddy lớn lên" (Track Teddy growing) / "Nhập cân nặng, chiều dài lúc sinh. Mỗi lần đo sau, app tự so với lần trước." (Enter birth weight & length. Each later measurement the app auto-compares with the previous one.) / "Bỏ qua" · "Tiếp". Baby name is interpolated in title.

## 103:8275 — 18c Hướng dẫn 3/3 [Night 103:8608]
Spotlight on QuickLogButton (+). TourTip: "Bước 3/3" / "Ghi nhanh từ mọi nơi" (Quick log from anywhere) / "Nút + luôn ở đây, ở mọi tab. Chạm để chọn việc cần ghi." (+ is always here on every tab; tap to choose what to log) / "Bỏ qua" · "Bắt đầu" (Start).
Tour behaviour: 3 steps; Skip ends tour (inferred); coachmark disabled after first log (annotation).

## 46:2266 — 19 Hôm nay (Light, 375x1125) [Night 70:4386]
Annotation (verbatim): "Thẻ lớn = vừa ghi vừa xem: chạm thẻ → mở sheet ghi mục đó (1 chạm); dòng dưới là lần cuối (bao lâu trước · chi tiết · ai ghi). Ngủ khi timer chạy → CareTile Tone=Active hiện thời gian đang chạy. Tăng trưởng: hàng riêng, + mở màn nhập số đo. “Lịch sử” → dòng thời gian."
(Big tile = both log & view: tap tile → opens that type's log sheet (1 tap); lines below = last entry (how long ago · detail · who logged). Sleep with running timer → CareTile Tone=Active shows running time. Growth: own row, + opens measurement entry screen. "Lịch sử" → timeline.)
- Header identical to empty state (BabySwitcher "Teddy · 3 tuần", Night care toggle), date "Thứ Năm, 8 tháng 10", title "Hôm nay".
- CareTiles with data (value / when / who):
  - Bú bình: "120 ml" / "45 phút trước" / "Mẹ ghi" (Mum logged)
  - Bú mẹ: "15 phút" / "Kết thúc 3 giờ 35 phút trước" (ended 3h35m ago) / "Mẹ ghi"
  - Giấc ngủ: "Đã thức 2 giờ" (awake 2 h) / "Dậy lúc 13:05" (woke at 13:05) / "Ba ghi" (Dad logged)
  - Thay tã: "Tã ướt" (wet diaper) / "1h 25p trước" / "Cô Lan ghi" (caregiver "Cô Lan")
  - Hút sữa: "90 ml" / "2 giờ trước" / "Mẹ ghi"
  - Tăng trưởng: "4,3 kg" / "54,5 cm" / "+0,4 kg · hôm nay" (delta vs previous measurement · measured today). Decimal comma (vi locale).
  - Note inconsistent relative-time formats in design: "45 phút trước", "1h 25p trước", "2 giờ trước", "Kết thúc 3 giờ 35 phút trước" → open question: canonical format.
  - Attribution label = "<relationship label> ghi" (Mẹ/Ba/Cô Lan) → uses member relationship label (inferred).
- ReminderPeek (component 128:665 desc: "Home entry to reminders (S15): next upcoming reminder + count. Tap opens reminder list."): label "Nhắc việc · 3" (Reminders · count 3), title "Tiêm 6 trong 1" (6-in-1 vaccine), meta "Thứ Bảy 08:30 · còn 2 ngày" (Saturday 08:30 · 2 days left), chevron →.
- SectionHeader "Hôm nay" + link "Lịch sử" (History → screen 20 Lịch sử).
- DayRhythm card (component "Filter=All" 48:409, desc verbatim: "“Đã ghi hôm nay”: totals of what was logged today (bottle feeds + ml, breastfeeds + minutes, finished sleep, diaper changes) and a 24h strip in care colours. Running sleep is not counted until it ends.")
  - "Đã ghi hôm nay" (Logged today); "Bú bình 2 cữ · 240 ml"; "Bú mẹ 1 cữ · 15 phút"; "Ngủ (đã xong) 7 giờ 50" (sleep finished 7h50); "Thay tã 2 lần" (2 times).
  - Pump and growth are NOT in day totals (pump not counted as baby intake — business rule).
  - 24h strip 0h–24h (axis labels "0h 6h 12h 18h 24h"); segments: sleep 00:00–06:30, sleep 11:45–13:05 (sleep bars full-height), feed 08:00, breastfeed 11:30–11:45, feed 14:20, diaper 09:10, diaper 13:40 (thin ticks), "Now 15:05" vertical marker. Legend: Ngủ · Bú bình · Bú mẹ · Tã. Note: sleep 00:00–06:30 counted in today's total (7h50 = 6h30 + 1h20) → confirmed by 26 Nhập giấc ngủ: overnight sleep is split into each day by the baby timezone (totals clipped per day).
  - Variant property `filter` exists with value "All" → other filter variants exist (used on Lịch sử filter screens, inferred).
- TabDock unchanged.
  - CareTile component default text for diaper "when" = "1 giờ 25 phút trước" (full form) while the 19 Hôm nay instance overrides "1h 25p trước" → prefer full form "X giờ Y phút trước" (inferred).

## 50:3572 — 19a Ghi nhanh (Quick log sheet) [Night 70:4567]
Annotation (verbatim): "Mở từ nút + ở dock. 1 chạm chọn mục → mở sheet ghi tương ứng (22/23/24, timer ngủ 25, tăng trưởng 28). Ngủ: nếu chưa có timer thì bắt đầu ngay, nhấn giữ để nhập thủ công."
(Opened from + in dock. 1 tap on an item → opens matching log sheet (22 bottle / 23 breast / 24 diaper, sleep timer 25, growth 28). Sleep: if no timer running, START IMMEDIATELY; long-press to enter manually.)
- Bottom sheet over Today (scrim). SheetHeader (component 37:293: grabber, title, close 44px labelled “Đóng”): title "Ghi nhanh"; close ✕.
- 6 ChoiceTiles in 2 rows of 3: "Bú bình" → 22 Ghi bú bình; "Bú mẹ" → 23 Ghi bú mẹ; "Ngủ" → starts sleep timer immediately (25 Timer ngủ) if none running; long-press → manual entry (26 Nhập giấc ngủ); "Thay tã" → 24 Thay tã; "Tăng trưởng" → 28 Tăng trưởng; "Hút sữa" → 23a Ghi hút sữa (pump not listed in annotation but present in sheet; inferred → 23a).
- ChoiceTile component desc (45:386): "Big single-choice tile for one-hand logging (diaper type…). Selected: mint-soft + 2.5px mint-deep border. Remembers the last choice."
- Note QuickLogButton description lists only "(Bú · Ngủ · Tã · Tăng trưởng)" — outdated vs 6-tile sheet incl. Hút sữa.
- Open Q: if a sleep timer is already running, what does tapping "Ngủ" do (open running timer 25, inferred)?

---

# Part B — Log sheets, timers, sleep, growth, record detail


## 46:2649 — 21 Chi tiết bản ghi (Record detail) [Night 70:5099]
Annotation (verbatim): "Xóa: hỏi xác nhận bằng action sheet, sau đó hiện toast “Đã xóa · Hoàn tác” 5 giây. Bản ghi của người khác: nút Sửa/Xóa ẩn nếu không có quyền."
(Delete: confirm via action sheet, then toast "Đã xóa · Hoàn tác" (Deleted · Undo) for 5 s. Someone else's record: Edit/Delete buttons hidden if no permission.)
- Top: Button/Back (a11y "Quay lại") · Tinted button "Sửa" (Edit, pencil icon) → opens that type's log sheet prefilled (inferred; W5 confirms "Sửa" opens 22 "mở sẵn bản vừa ghi").
- Hero (care-bottle-soft): "Bú bình · Sữa mẹ" (type · milk type) / "120 ml" (numeral-xl 52) / "Hôm nay, 14:20".
- InfoRows (component 45:394 "Read-only key/value row for record details"):
  - "Thời gian" (Time) = "Hôm nay · 14:20" (event time)
  - "Người ghi" (Logged by) = "Mẹ Mai (bạn)" (relationship + name, "(bạn)" = you)
  - "Ghi lúc" (Recorded at) = "14:22" (creation timestamp — distinct from event time)
  - "Đồng bộ" (Sync) = SyncStatus "Đã đồng bộ" (Synced)
- SyncStatus component desc (8:84, verbatim): "Sync pill — always icon + words, never colour alone. Synced: mint-soft/mint-text. Pending (offline / waiting): sunshine-soft/pending, copy “Đã lưu trên máy này. Đang chờ đồng bộ.” Error: error-soft/error. Pending saves must survive an app restart."
- Footer: "Mọi người trong gia đình thấy bản ghi này. Chỉ người ghi hoặc chủ sở hữu được sửa." (Everyone in the family sees this record. Only the person who logged it or the owner can edit.)
- Destructive button "Xóa bản ghi" (Delete record) → action-sheet confirm → toast "Đã xóa · Hoàn tác" 5 s.
- Button component desc (8:33, verbatim): "Pill button, label = 1–2-word verb (Lưu, Bắt đầu, Kết thúc, Chỉnh giờ, Mời, Thử lại). Primary h56 mint-deep/on-mint-deep, one per screen in the thumb zone. Secondary h52 surface-2. Tinted for secondary actions. Plain for text buttons (≥44 tap). Apple: use Apple’s official button in production. Press: scale 0.97 in duration-tap. Disabled: opacity 40%. Stretch to fill width for block buttons."

## 46:3141 — 22 Ghi bú bình (Feed log sheet, Bottle segment) [Night 70:5155]
Sheet (sub-node 46:3166) over Today + numeric keypad docked below.
- SheetHeader title "Ghi cữ bú" (Log a feed; in care-bottle-ink) + close ✕ (a11y "Đóng").
- Segmented: "Bú bình" (selected) | "Bú mẹ" → the same "Ghi cữ bú" sheet switches between bottle (22) and breastfeed (23).
- "Lượng sữa · tùy chọn" (Milk amount · optional) → AmountField focused "120" unit "ml". Units: ml only (no oz shown).
- "Loại sữa" (Milk type): FilterChips "Sữa mẹ" (breast milk, selected) | "Sữa công thức" (formula).
- TimeRow "Thời gian" value chip "Bây giờ · 15:05" (Now · 15:05).
- Primary "Lưu cữ bú" (Save feed).
- Keypad (11:184): digits, decimal comma "," and backspace ⌫ — "Decimal pad mock (system keypad in production)".
- Component rules (verbatim):
  - Segmented 9:124: "Pill segmented control on surface-2 track (pad 5, gap 4). 2–3 short options (Sữa mẹ · Sữa công thức; Ướt · Bẩn · Cả hai). Remembers the last choice as the default."
  - AmountField 45:403: "Numeric amount (ml, kg, cm, phút) in numeral-xl, tabular figures. Focused = mint-soft + 2px mint-deep. Always optional unless stated."
  - FilterChip 45:347: "Single-select filter chip (h40). Selected = mint-deep / on-mint-deep. Row scrolls horizontally; last chip may peek to signal more."
  - TimeRow 45:387: "When it happened. Default = now; tap the chip to pick another time (wheel). Label is “Thời gian” — short and plain."

## 46:3234 — 23 Ghi bú mẹ (Feed log sheet, Breast segment) [Night 70:5403]
Annotation (verbatim): "Bú mẹ: chọn bên (nhớ bên lần trước, gợi ý bên còn lại), thời lượng tùy chọn. “Bấm giờ” đổi ô thời lượng thành đồng hồ đếm, có thể tạm dừng khi đổi bên."
(Breastfeed: choose side (remembers last side, suggests the other side), duration optional. "Bấm giờ" turns the duration field into a running counter, can be paused when switching side.)
- SheetHeader "Ghi cữ bú" (title colour care-breast-ink). Segmented "Bú bình" | "Bú mẹ" (selected).
- "Bên" (Side): Segmented 3 options "Trái" (Left) | "Phải" (Right) | "Cả hai" (Both; selected in mock).
- "Thời lượng · tùy chọn" (Duration · optional): AmountField "15" unit "phút" (minutes), Default (unfocused) state — no keypad shown in mock.
- Plain button (timer icon) "Bấm giờ thay vì nhập" (Time it instead of typing) → 23b Timer bú mẹ.
- TimeRow label "Bắt đầu" (Start) value "Bây giờ · 15:05" → for breastfeeding the time is the START time.
- Primary "Lưu cữ bú".

## 112:11135 — 23b Timer bú mẹ (Breastfeed timer) [Night 112:11193]
Annotation (verbatim): "Tự bật Night care khi timer chạy trong lịch đêm. Vòng “thở” (duration-breath). Kết thúc → lưu giấc ngủ, haptic success. “Hủy, không lưu” hỏi xác nhận. Timer tiếp tục khi khóa máy (Live Activity)."
(Auto-enable Night care when timer runs within the night schedule. "Breathing" ring (duration-breath). End → save [annotation says "giấc ngủ"/sleep — copy-paste from sleep timer; should be the feed record], haptic success. "Hủy, không lưu" asks for confirmation. Timer continues when phone is locked (Live Activity).)
- Back + SyncStatus pill (Synced style) text "Cả nhà đang thấy" (Whole family is seeing [this running timer]) → running timer is shared live to family.
- Title "Teddy đang bú mẹ" (Text/title 30); subtitle "Mẹ bắt đầu lúc 15:02" (<who> started at HH:mm).
- "Tổng thời gian" (Total time) "11:52" (mm:ss numeral-xl) = sum of sides (08:12 + 03:40).
- Side discs 150px: "TRÁI" "08:12" "Đang bú" (filled breast-accent = active side) ; "PHẢI" "03:40" "Chạm để đổi bên" (outlined = inactive; tap to switch side). Per-side accumulated durations.
- Hint pill: "Lần trước kết thúc bên phải" (Last feed ended on the right).
- Primary "Kết thúc cữ bú" (End feed → saves breastfeed record with per-side durations; haptic success).
- Secondary "Tạm dừng" (Pause; resume label inferred "Tiếp tục").
- Plain "Hủy, không lưu" (Cancel, don't save) → confirmation.

## 106:11118 — 23a Ghi hút sữa (Pump log sheet) [Night 106:11378]
Annotation: identical copy of the breastfeed annotation (verbatim): "Bú mẹ: chọn bên (nhớ bên lần trước, gợi ý bên còn lại), thời lượng tùy chọn. “Bấm giờ” đổi ô thời lượng thành đồng hồ đếm, có thể tạm dừng khi đổi bên." (copy-paste; treat as: side remembered, timer option.)
- SheetHeader "Ghi hút sữa" (Log pumping; care/pump/ink). No Bú bình/Bú mẹ segmented — pumping is its own sheet.
- "Bên": Segmented "Trái" | "Phải" | "Cả hai" (selected).
- "Lượng sữa" (Amount — NOT labelled optional, unlike bottle) AmountField "90" "ml".
- Plain button "Nhập riêng từng bên" (Enter each side separately) → per-side amounts (expanded state not designed — open Q).
- TimeRow "Thời lượng" (Duration) chip "15 phút" (wheel picker); TimeRow "Bắt đầu" (Start) chip "Bây giờ · 15:05".
- Plain button (timer icon) "Bấm giờ thay vì nhập" → 23c Timer hút sữa.
- Primary "Lưu hút sữa" (Save pumping).
- Pumped milk is not added to baby intake (excluded from "Đã ghi hôm nay"; product plan rule).

## 113:11207 — 23c Timer hút sữa (Pump timer) [Night 113:11255]
Annotation: identical to 23b (verbatim): "Tự bật Night care khi timer chạy trong lịch đêm. Vòng “thở” (duration-breath). Kết thúc → lưu giấc ngủ, haptic success. “Hủy, không lưu” hỏi xác nhận. Timer tiếp tục khi khóa máy (Live Activity)."
- Back + SyncStatus "Cả nhà đang thấy" (family sees live timer).
- Title "Mẹ đang hút sữa" (Mum is pumping) — subject is the parent; subtitle "Bắt đầu lúc 15:02 · cho Teddy" (Started 15:02 · for Teddy).
- "Tổng thời gian" "12:30". Sides "TRÁI" "12:30" "Đang hút" and "PHẢI" "12:30" "Đang hút" — both active simultaneously (double pumping); total = wall-clock elapsed, NOT sum of sides (contrast with breastfeeding where total = sum).
- Hint: "Hút đôi · chạm 1 bên để dừng riêng" (Double pump · tap one side to stop it individually).
- Primary "Xong · nhập lượng sữa" (Done · enter milk amount) → after stopping, prompts amount (ml) (inferred → returns to 23a with duration prefilled).
- Secondary "Tạm dừng"; plain "Hủy, không lưu" (confirm).
- Live Activity for pumping NOT designed (only Sleep & Breast) — open Q.

## 46:3308 — 24 Thay tã (Diaper sheet) [Night 70:5627]
Annotation (verbatim): "2 chạm: chọn loại → Lưu. Mặc định chọn loại lần trước. Sau khi lưu: tile Thay tã ở Hôm nay nảy nhẹ + dấu ✓, thẻ Lần cuối cập nhật."
(2 taps: choose type → Save. Default = last type chosen. After saving: the Thay tã tile on Today bounces lightly + ✓ mark; "last" card updates.)
- SheetHeader "Thay tã" (care-diaper-ink) + close.
- 3 ChoiceTiles: "Ướt" (Wet; Mini/Drop art; selected = mint-soft + 2.5px mint-deep border), "Bẩn" (Dirty), "Cả hai" (Both).
- TimeRow "Thời gian" "Bây giờ · 15:05".
- Primary "Lưu" (Save).
- No notes/colour/consistency fields for diaper.

## 69:4213 — 25a Ghi giấc ngủ (Sleep entry chooser sheet) [Night 70:5851]
(Read sheet sub-node 69:4237; frame-level annotation not read separately.)
- SheetHeader "Ghi giấc ngủ" (Log sleep) + close.
- Prompt: "Teddy đang ngủ hay đã ngủ xong rồi?" (Is Teddy sleeping now or already finished?)
- EntryOption Primary (recommended; sleep-soft + accent border, clock icon): "Bắt đầu hẹn giờ" / "Teddy vừa ngủ. Đồng hồ chạy, cả nhà cùng thấy" (Start timer / Teddy just fell asleep. The clock runs and the whole family sees it) → 25 Timer ngủ.
- EntryOption Secondary (edit icon): "Nhập giấc đã ngủ" / "Quên bấm giờ? Chọn giờ bắt đầu và kết thúc" (Enter a past sleep / Forgot to time it? Pick start and end time) → 26 Nhập giấc ngủ.
- Footnote: "Đổi cách bất cứ lúc nào: từ đồng hồ có thể sửa giờ bắt đầu, từ nhập tay có thể chuyển sang hẹn giờ."
- EntryOption component 69:609 desc: "Large entry choice with icon, title, subtitle and chevron. Primary = recommended path."
- Relationship to Quick log (19a annotation): from the + sheet, "Ngủ" starts the timer immediately; long-press → manual. 25a is the chooser reached from the Giấc ngủ CareTile (inferred).

## 47:3028 — 25 Timer ngủ (Sleep timer) [Night 70:6064]
Annotation (verbatim; origin of the shared timer annotation): "Tự bật Night care khi timer chạy trong lịch đêm. Vòng “thở” (duration-breath). Kết thúc → lưu giấc ngủ, haptic success. “Hủy, không lưu” hỏi xác nhận. Timer tiếp tục khi khóa máy (Live Activity)."
(Auto-enable Night care when the timer runs within the night schedule. Breathing ring. End → save sleep, success haptic. "Cancel, don't save" asks for confirmation. Timer continues while locked (Live Activity).)
- Back + SyncStatus "Cả nhà đang thấy".
- Title "Bé Teddy đang ngủ" (Baby Teddy is sleeping); subtitle "Ba bắt đầu lúc 21:42" (Dad started at 21:42).
- SleepTimer ring (272px): "Đang ngủ" / "01:27:06" (hh:mm:ss) / "Từ 21:42" (Since 21:42). Component 10:83 desc (verbatim): "Running sleep timer, 272px. Track surface-2, arc mint (12–13px, round cap) breathing opacity 1 ↔ 0.55 over duration-breath (ease-in-out); static with Reduce Motion. Elapsed in numeral-xl with tabular figures. Pair with Primary “Kết thúc” + Plain “Chỉnh giờ bắt đầu”." (Screen arc is sleep-accent purple, not mint.)
- Primary "Kết thúc giấc ngủ" (End sleep) → saves sleep record (start→now), haptic success; then overlap check (→27 if conflicting, inferred).
- Secondary "Sửa giờ bắt đầu" (Edit start time) → time wheel (inferred). Live Activity deep link "Sửa giờ bắt đầu" opens this screen (W5).
- Plain "Hủy, không lưu" → confirm → discard.
- No pause for sleep timer (unlike feed/pump timers).
- Offline timer variant 9c (127:15087) belongs to section 9.

## 47:3074 — 26 Nhập giấc ngủ (Manual sleep entry, full screen) [Night 70:6103]
(No frame annotation.)
- Back + BabySwitcher ("Teddy", chevron). Large title "Nhập giấc ngủ".
- Duration hero (sleep-soft, moon & clouds): "Thời lượng" (Duration) "7 giờ 28 phút" (computed end − start) + Chip "Qua đêm" (Overnight; shown when the interval crosses midnight).
- Times card: TimeRow "Bắt đầu" (moon icon) "Hôm qua · 21:42"; TimeRow "Kết thúc" (sun icon) "Hôm nay · 05:10". Relative day labels Hôm qua / Hôm nay + HH:mm.
- Note (verbatim): "Giấc qua đêm được chia vào tổng của từng ngày theo múi giờ của bé (GMT+7)." (An overnight sleep is split into each day's total by the baby's timezone (GMT+7).) → confirms midnight split in the baby's timezone.
- Link row: "Teddy đang ngủ?" + "Bắt đầu hẹn giờ" (chevron) → switches to 25 Timer.
- Primary "Lưu giấc ngủ" (Save sleep) → overlap check → 27 if overlap (inferred).
- Validation not shown (end before start, future end, > 24h) — open Q.

## 47:3145 — 27 Giấc ngủ trùng nhau (Overlapping sleeps resolver) [Night 70:6176]
Annotation (verbatim): "Chỉ hiện khi đồng bộ phát hiện 2 giấc ngủ chồng thời gian. Nút chính bị khoá (40% opacity) cho tới khi chọn một bản. Bản không chọn được giữ 30 ngày trong “Đã xoá gần đây”."
(Shown only when SYNC detects 2 sleeps overlapping in time. Primary button disabled (40% opacity) until one version is chosen. The unchosen version is kept 30 days in "Đã xoá gần đây" (Recently deleted).)
- Back + SyncStatus (synced style) "Đã có mạng lại" (Back online) → trigger context: reconnect sync.
- Title "Có hai giấc ngủ trùng nhau" (There are two overlapping sleeps). Body "Chọn bản đúng. App không tự gộp hay ghi đè." (Pick the correct one. The app never auto-merges or overwrites.)
- Shared axis 21:00 · 22:00 · 23:00 · 00:00 (window auto-fitted around both spans, inferred).
- Option 1 (selected, 2px mint-deep border; span bar mint): "21:40 – 23:06" + Radio checked; "1 giờ 26 phút · Ba ghi" + SyncStatus Synced "Cả nhà đang thấy" (server copy by another member).
- Option 2 (span bar sunshine): "21:42 – 23:10" + Radio unchecked; "1 giờ 28 phút · Bạn ghi" + SyncStatus Pending (cloud-off icon) "Chỉ trên máy này" (Only on this device = local offline record).
- Primary "Giữ bản đã chọn" (Keep selected) — disabled until a choice.
- Plain "Sửa tay từ bản của tôi" (Edit manually from my version) → opens 26 Nhập giấc ngủ prefilled with local version (inferred).
- Discarded version → "Đã xoá gần đây" for 30 days (restorable; location of that list not in this section — open Q).

## 47:3210 — 28 Tăng trưởng (Growth entry) [Night 70:6236]
Annotation (verbatim): "Chỉ ghi và so sánh với lần trước — không bách phân vị, không đánh giá “tốt/xấu” (nguyên tắc: không suy luận y khoa). Đơn vị kg/cm, dấu phẩy thập phân."
(Only record and compare with the previous measurement — no percentiles, no "good/bad" judgement (principle: no medical inference). Units kg/cm, decimal comma.)
- Back + BabySwitcher "Teddy · 3 tuần". Large title "Tăng trưởng".
- Measure card: TimeRow (ruler icon) "Ngày đo" (Measurement date) chip "Hôm nay" (date only, no time).
- Fields: "Cân nặng" (Weight) AmountField focused "4,3" "kg" (REQUIRED — not marked optional); "Chiều dài · tùy chọn" (Length · optional) "54,5" "cm". No head circumference.
- Delta line (growth-ink): "+0,4 kg · +1,5 cm so với lần đo 1 thg 10" (vs measurement on 1 Oct). (Metadata layer name says "+0,8 kg · +3,5 cm…" — stale layer name; rendered text is authoritative.)
- "Các lần đo trước" (Previous measurements) + link "Xem tất cả" (See all → History filtered Tăng trưởng 20d, inferred).
- LogRows: "3,9 kg · 53 cm" / "1 thg 10 · Mẹ ghi"; "3,2 kg · 50 cm" / "17 thg 9 · Lúc sinh · Ba ghi" (birth measurement tagged "Lúc sinh"). Chevron → 21 detail.
- LogRow component 45:373 desc (verbatim): "History row: care icon, “what · detail”, “time · who logged”. Pending = saved on this device, waiting to sync (icon + words, never colour alone). Tap → record detail."
- Primary "Lưu số đo" (Save measurement).
- Date formats: "1 thg 10", "17 thg 9" (short month "thg").

### 22 Ghi bú bình — frame annotation (46:3141, verbatim)
"Mặc định: Bú bình (nhớ loại lần trước), thời gian = bây giờ, loại sữa nhớ lần trước. Lượng ml không bắt buộc — có thể Lưu ngay (2 chạm). Bàn phím số có dấu phẩy; nút Lưu luôn nằm trên bàn phím."
(Defaults: Bú bình (remembers last feed type), time = now, milk type remembers last. ml amount NOT required — can Save immediately (2 taps). Numeric keypad with comma; Save button always sits above the keypad.)

- 25a frame annotation (69:4213) is a verbatim copy of the 19a Ghi nhanh annotation: "Mở từ nút + ở dock. 1 chạm chọn mục → mở sheet ghi tương ứng (22/23/24, timer ngủ 25, tăng trưởng 28). Ngủ: nếu chưa có timer thì bắt đầu ngay, nhấn giữ để nhập thủ công." → conflicts with the chooser sheet shown on 25a (open question: does "Ngủ" start the timer immediately, or show 25a chooser?).

---

# Part C — History (Lịch sử), filters, date picker, statistics (Thống kê)


Source: Figma file `sJLG1fAXKDnDr9YI6Yx8ex`, Screens page `26:2`, section "5 · Hôm nay & Chăm sóc". All frames are Light variants unless noted. The extraction was read-only.

Tools used per node:
- get_design_context (full code + annotations + component descriptions): 46:2469, 104:8724, 104:9429, 104:10130, 105:9063, 105:9471, 108:10271 (large output, parsed from file), 109:10562, 110:10949, 111:10994.
- get_screenshot: all of the above + Night 109:12017.
- Rate limit: hit once (after 104:10130). Backed off, called `whoami` (Pro plan, Full seat), and later calls succeeded. **Nothing was left unread.**

Scenario implied by the mock data: today is **Thursday 8 Oct 2026 (T5 8)**. The current time is **15:05** (marker "Now 15:05"). The status bar "9:41" is just a placeholder. The baby is **Teddy**, born **17 Sep** (birth date confirmed in 20f).

---

## 0. Cross-screen facts

### 0.1 Frame-level annotation (verbatim; identical on EVERY frame in this set, including the stats frames, where it looks copy-pasted)
> "Dòng thời gian mới nhất ở trên, chia theo buổi (Sáng/Trưa/Chiều/Tối). Giấc ngủ và bú mẹ là khối có thời lượng. Chạm mục → Chi tiết bản ghi. Lọc “Tăng trưởng” hiện các lần đo."

Gloss: "Timeline newest on top, split by period of the day (Morning/Noon/Afternoon/Evening). Sleep and breastfeeding are blocks with a duration. Tap an item → Record detail. The 'Growth' filter shows the measurements."

### 0.2 Component descriptions that state rules (verbatim)
- **TimeSectionHeader (59:431):** "Sticky time-of-day header for the timeline: Sáng (05–11) · Trưa (11–13) · Chiều (13–18) · Tối (18–22) · Đêm (22–05). Each period has its own icon + tint so sections are easy to scan; count = entries in that period."
- **TimelineItem (48:407):** "Day timeline entry: time column (tabular), rail with category marker, content. Event = point in time (feed, diaper, growth). Span = something with a duration (sleep, breastfeed) shown as a block with a duration bar. Pending = saved on device, waiting to sync. Turn off the line on the last item. Category variant colours the marker, span block and bar with care/<type> tokens. Marker is 40px and holds the care type art (Illustration/Mini/*) via the Icon property."
- **DayRhythm summary card (48:409 Filter=All; the same text is copied onto 104:484 Feed, 104:538 Sleep, 104:592 Diaper):** "“Đã ghi hôm nay”: totals of what was logged today (bottle feeds + ml, breastfeeds + minutes, finished sleep, diaper changes) and a 24h strip in care colours. Running sleep is not counted until it ends."
- **DayPill (45:342):** "Day strip pill (44×64 ≥ tap target). Selected = mint-deep. Today is the right-most pill; swipe for earlier weeks."
- **FilterChip (45:347):** "Single-select filter chip (h40). Selected = mint-deep / on-mint-deep. Row scrolls horizontally; last chip may peek to signal more."
- **BabySwitcher (45:321):** "Baby switcher chip: avatar + name (+ chevron when the family has more than one baby). Shows whose log you are viewing."
- **Button/Back (8:37):** "Round back button, 44px tap target, surface-2. Accessibility label: Quay lại."
- **QuickLogButton (44:363):** "Ghi nhanh (+): opens the quick-log chooser (Bú · Ngủ · Tã · Tăng trưởng). 68px, accessibility label “Ghi nhanh”."
- **NavBar (44:362):** "Floating tab bar … Each tab shows icon + label (caption) — visible labels beat icon-only for tired parents and for VoiceOver parity. Active tab: nav-active pill…"
- **Segmented (9:124)** (used on the stats screens): "Pill segmented control on surface-2 track (pad 5, gap 4). 2–3 short options (Sữa mẹ · Sữa công thức; Ướt · Bẩn · Cả hai). Remembers the last choice as the default."
- **Segmented/Item (9:111):** "Selected: surface + shadow-card, ink, weight 500. Unselected: transparent, ink-muted. Change animates in duration-quick."
- **Button (8:33):** "Pill button, label = 1–2-word verb (Lưu, Bắt đầu, Kết thúc, Chỉnh giờ, Mời, Thử lại). Primary h56 mint-deep/on-mint-deep, one per screen in the thumb zone. Secondary h52 surface-2. Tinted for secondary actions. Plain for text buttons (≥44 tap)… Disabled: opacity 40%."
- **SectionHeader (9:140):** "Section header: headline title + optional mint-text link."
- **Illustration/Mini/Pump (106:621):** "Mini art: breast pump (Hút sữa)".

### 0.3 Shared chrome on the History screens (20 – 20f)
- **Back button** (top-left, a11y "Quay lại"). Effect: back to the Today screen (inferred).
- **BabySwitcher** "Teddy ▾" (top-right). Effect: switch the baby whose log is shown. The chevron appears only for families with more than one baby.
- **Title** "Lịch sử" (History).
- **Month picker chip** "Tháng 10 ▾" (Month 10) sits right of the title. Tapping it opens 20f "Chọn ngày".
- **Day strip** (hidden on the Growth filter): 7 DayPills, each showing a weekday abbreviation over the day number: "T6 2", "T7 3", "CN 4", "T2 5", "T3 6", "T4 7", "T5 8". Today is right-most and selected by default. It is a rolling 7 days ending today, not a Mon–Sun week. Swipe for earlier weeks. Weekday codes: T2=Mon … T7=Sat, CN=Sun.
- **Filter chips** (single-select, horizontal scroll, last chip peeks): "Tất cả" (All) · "Bú" (Feeding) · "Hút sữa" (Pumping) · "Ngủ" (Sleep) · "Tã" (Diaper) · "Tăng trưởng" (Growth).
- **TabDock**: NavBar with "Hôm nay" (Today) active, plus Memories, Family and Me (avatar "M") icons. QuickLog "+" button ("Ghi nhanh"). History lives under the **Hôm nay tab**.
- **Period sections** (TimeSectionHeader): an icon circle, then the name, the time range and a count pill "N mục" (N items).
  - "Sáng" 05:00 – 11:00 (sunrise icon)
  - "Trưa" 11:00 – 13:00 (today/sun icon)
  - "Chiều" 13:00 – 18:00 (sunset icon)
  - "Tối" 18–22 (only in the component description; not shown in any mock)
  - "Đêm" 22:00 – 05:00 (sleep/moon icon)
  - Sections are ordered newest first: Chiều → Trưa → Sáng → Đêm. Empty periods are omitted (inferred: there is no "Tối" in the 15:05 scenario).
- **Row anatomy**: the time column (HH:mm, tabular) on the left, then a rail with a 40px category marker (mini art), then the body.
  - Body line 1 (17px) is the title. Body line 2 (14px, muted) is the detail plus attribution.
  - Span items (sleep, breastfeed) get a tinted block background and a duration bar (6px, care accent; every mock uses a fixed width of 120px).
  - The rail line between items is turned off on the last item.
- **Attribution format**: "<who> ghi" (logged by <who>). Examples: "Mẹ ghi" (Mom), "Ba ghi" (Dad), "Cô Lan ghi" (caregiver "Ms. Lan").
- **Pending sync marker**: a pill on the right of the title row. It has a cloud-off icon and the text "Chờ" (Pending), on sunshine-soft (#fff4d6) with pending-ink (#7a5600). Meaning: "saved on device, waiting to sync".

---

## 1. 46:2469 — "20 Lịch sử · Light" (History, filter = Tất cả, today)

**Purpose:** a day timeline of every care log for the selected day, with a summary card on top.

**Summary card "Đã ghi hôm nay"** (Logged today), DayRhythm Filter=All:
| Key (colour) | Label | Value |
|---|---|---|
| bottle blue | "Bú bình" (bottle feed) | "2 cữ · 240 ml" (2 feeds · 240 ml) |
| breast pink | "Bú mẹ" (breastfeed) | "1 cữ · 15 phút" (1 feed · 15 min) |
| sleep purple | "Ngủ (đã xong)" (sleep, finished) | "7 giờ 50" (7 h 50) |
| diaper green | "Thay tã" (diaper change) | "2 lần" (2 times) |

- **24h strip**: a track over 0–24h with surface-2 background.
  - Sleep blocks (h20, 6px radius): 00:00–06:30 and 11:45–13:05.
  - Event ticks (h16, about 1% wide): Feed 08:00 (blue), Breastfeed 11:30–11:45 (pink), Feed 14:20 (blue), Diaper 09:10 (green), Diaper 13:40 (green).
  - Now marker: a dark vertical line at 15:05.
- **Axis**: "0h", "6h", "12h", "18h", "24h".
- **Legend**: "Ngủ", "Bú bình", "Bú mẹ", "Tã".
- **Not in the card**: pumping ("Hút sữa") has no total in the card and no mark on the strip, even though a 10:15 pump entry exists in the list. The component description lists only bottle, breast, finished sleep and diapers.

**Timeline (newest first):**
- **Chiều** 13:00 – 18:00 · "2 mục"
  - 14:20 · bottle marker · "Bú bình · 120 ml" / "Mẹ ghi"
  - 13:40 · diaper marker · "Thay tã · Ướt" (wet) + **"Chờ"** pending pill / "Cô Lan ghi"
- **Trưa** 11:00 – 13:00 · "2 mục"
  - 11:45 · moon marker · span block (sleep-soft) · "Ngủ 1 giờ 20 phút" / "11:45 – 13:05 · Ba ghi" + purple duration bar
  - 11:30 · drop marker · span block (breast-soft) · "Bú mẹ · Cả hai bên" (both sides) / "15 phút · Mẹ ghi" + pink duration bar
- **Sáng** 05:00 – 11:00 · "3 mục"
  - 10:15 · pump marker (care/pump/soft #f5eafa) · "Hút sữa · 90 ml" / "Cả hai bên · 15 phút · Mẹ ghi". This is an **event**, not a span block, even though it has a duration.
  - 09:10 · diaper · "Thay tã · Cả hai" (both wet+dirty) / "Mẹ ghi"
  - 08:00 · bottle · "Bú bình · 120 ml" / "Ba ghi"
- **Đêm** 22:00 – 05:00 · "1 mục"
  - 00:00 · moon · span block · "Ngủ 6 giờ 30 phút" / "21:42 hôm qua – 06:30 · Ba ghi" (21:42 yesterday – 06:30) + bar

**Interactive elements:**
- Tap a row → "Chi tiết bản ghi" (Record detail), per the annotation.
- DayPill → change the selected day.
- Filter chip → filter the list and swap the summary card variant.
- Month picker → 20f.
- BabySwitcher → switch baby.
- Back → previous screen.
- "+" → quick-log chooser (Bú · Ngủ · Tã · Tăng trưởng).
- Tapping the summary card or strip does nothing that the design shows (inferred).

**Observations and ambiguities:**
- A sleep that crosses midnight is **clipped to the selected day**.
  - The time column shows "00:00", not 21:42.
  - The duration shown, "6 giờ 30 phút", is only the in-day part. The real span 21:42→06:30 is 8 h 48.
  - The card's sleep total of 7 giờ 50 = 6:30 + 1:20, which confirms clipping.
- The 06:30 end time puts this sleep in Đêm (22–05), based on the in-day start of 00:00.
- The duration format differs by place: the card uses "7 giờ 50" (no "phút"), while rows use "1 giờ 20 phút".

---

## 2. 104:8724 — "20a Lịch sử · Lọc Bú · Light" (filter = Bú)

**Purpose:** a feed-only view for today.

**Filter scope:** the **Bú chip includes bottle ("Bú bình") and breast ("Bú mẹ") only**. The 10:15 pump entry is excluded, and the Sáng count drops to "1 mục". Pumping has its own chip, "Hút sữa".

**Summary card "Bú hôm nay"** (Feeding today):
| Label | Value |
|---|---|
| "Bú bình" | "2 cữ · 240 ml" |
| "Bú mẹ" | "1 cữ · 15 phút" |
| "Cữ gần nhất" (last feed; neutral grey key) | "45 phút trước" (45 min ago) = 15:05 − 14:20 |
| "Cách nhau trung bình" (average interval) | "3 giờ 10 phút" |

- **Interval check**: feeds at 08:00, 11:30 and 14:20 give gaps of 3:30 and 2:50, which average **3:10**. So the average uses the start-time gaps of bottle and breast feeds combined, within the day.
- **Strip**: Feed 08:00, Breastfeed 11:30–11:45, Feed 14:20, and Now 15:05. Legend: "Bú bình", "Bú mẹ".

**Stats link card** (bottle-soft background, clock icon, chevron-right):
- "**Xem thống kê bú**" (View feeding stats)
- "Tỉ lệ ngày/đêm · lượng sữa theo giờ · bú mẹ trái/phải" (day/night ratio · milk volume by hour · breastfeeding left/right)
- Effect: opens 20g / 20g2 "Thống kê bú". Which segment it opens on is not specified (open question).

**Timeline:**
- Chiều "1 mục": 14:20 "Bú bình · 120 ml" / "Mẹ ghi"
- Trưa "1 mục": 11:30 "Bú mẹ · Cả hai bên" / "15 phút · Mẹ ghi" (span)
- Sáng "1 mục": 08:00 "Bú bình · 120 ml" / "Ba ghi"

---

## 3. 104:9429 — "20b Lịch sử · Lọc Ngủ · Light" (filter = Ngủ)

**Summary card "Ngủ hôm nay"** (Sleep today):
| Label | Value |
|---|---|
| "Tổng đã ngủ" (total slept) | "7 giờ 50" |
| "Số giấc" (number of sleeps) | "2 giấc" |
| "Giấc dài nhất" (longest sleep) | "6 giờ 30" (the clipped in-day portion of the overnight sleep) |
| "Đang thức" (awake for) | "2 giờ · từ 13:05" (2 h · since 13:05) = 15:05 − 13:05 |

- **Strip**: Sleep 00:00–06:30, Sleep 11:45–13:05, and Now 15:05. Legend: "Ngủ".

**Stats link card** (sleep-soft):
- "**Xem thống kê ngủ**" (View sleep stats)
- "Tỉ lệ ngày/đêm · nhịp ngủ 7 ngày · giấc dài nhất" (day/night ratio · 7-day sleep rhythm · longest sleep)
- Effect: opens 20h.

**Timeline:**
- Trưa "1 mục": 11:45 "Ngủ 1 giờ 20 phút" / "11:45 – 13:05 · Ba ghi"
- Đêm "1 mục": 00:00 "Ngủ 6 giờ 30 phút" / "21:42 hôm qua – 06:30 · Ba ghi"

**Notes:**
- "Đang thức" applies only when no sleep is running. The design has no "Đang ngủ" (sleeping now) state for this card, so that is a gap.
- Per the description, a running sleep is not counted until it ends.

---

## 4. 104:10130 — "20c Lịch sử · Lọc Tã · Light" (filter = Tã)

**Summary card "Tã hôm nay"** (Diapers today):
| Label | Value |
|---|---|
| "Tổng" (total) | "2 lần" |
| "Gần nhất" (latest) | "1 giờ 25 phút trước" (15:05 − 13:40). The text is **truncated** in the screenshot ("…phút trư"), which is a layout overflow. |
| "Ướt" (wet) | "2 lần" |
| "Bẩn" (dirty) | "1 lần" |

- **Counting rule shown**: "Cả hai" (both) counts toward **both** Ướt and Bẩn. Entries are 09:10 Cả hai and 13:40 Ướt, giving Ướt 2 and Bẩn 1.
- The **pending ("Chờ") entry is included in the totals**.
- **Strip**: Diaper 09:10, Diaper 13:40, Now 15:05. Legend: "Tã".
- **No stats link** under the Diaper filter. There is no diaper statistics screen.

**Timeline:**
- Chiều "1 mục": 13:40 "Thay tã · Ướt" + "Chờ" / "Cô Lan ghi"
- Sáng "1 mục": 09:10 "Thay tã · Cả hai" / "Mẹ ghi"

---

## 5. 105:9063 — "20d Lịch sử · Lọc Tăng trưởng · Light" (filter = Tăng trưởng)

**Purpose:** growth measurements across all time. The annotation reads: "Lọc “Tăng trưởng” hiện các lần đo."

**Layout differences from the other filters:** the **day strip is hidden**, though the month picker "Tháng 10" is still shown. The DayRhythm card is replaced by a growth summary card.

**Growth summary card:**
- Label: "Gần nhất · hôm nay" (Latest · today).
- Metric toggle (mini segmented): "**Cân nặng**" (weight, selected) | "Chiều dài" (length).
- Value: "**4,3 kg**" with "· 54,5 cm" (the secondary metric, muted). The design uses a decimal comma.
- Delta pill (growth-soft #fdede2, growth-ink #9a4a14): "**+0,4 kg so với 1 thg 10 · +1,5 cm**" (+0.4 kg vs 1 Oct · +1.5 cm). The comparison is against the previous measurement.
- Line chart (growth orange):
  - Y gridlines and labels "3 kg", "4 kg", "5 kg".
  - X labels are the measurement dates "17 thg 9", "1 thg 10", "8 thg 10".
  - X is **proportional to time**: 14 days = 174 px, 7 days = 87 px.
  - The latest point is filled; earlier points are hollow.
  - No percentile or WHO curves and no legend.

**Section "Các lần đo"** (Measurements; SectionHeader, no link). It is a timeline whose time column shows a **date**, not a time:
- "8 thg 10" · ruler marker · "4,3 kg · 54,5 cm" / "+0,4 kg · +1,5 cm · Mẹ ghi"
- "1 thg 10" · "3,9 kg · 53 cm" / "+0,7 kg · +3 cm · Mẹ ghi"
- "17 thg 9" · "3,2 kg · 50 cm" / "**Lúc sinh** · Ba ghi" (At birth)

**Visual bug:** in the screenshot the date column (44px wide) truncates "8 thg 10", "1 thg 10" and "17 thg 9".

**Button** (tinted, mint-soft, full width): "**+ Thêm số đo**" (Add measurement). Effect: opens the growth log form (inferred).

**Interactive elements:**
- Metric toggle switches the chart and headline between weight and length (inferred).
- Tap a row → Record detail.
- Add-measurement button.
- The month picker's role here is unclear, because the list spans Sep–Oct (open question).

---

## 6. 105:9471 — "20e Lịch sử · Lọc Tã · Ngày trống · Light" (empty day, filter = Tã)

**Setup:** the selected DayPill is "T2 5" (Mon 5 Oct). Today's pill "T5 8" is still at the right, unselected.

**Summary card is hidden.** It is replaced by an **Empty card** (white, 24 radius, centred):
- Diaper mini illustration (72px).
- "**Chưa ghi thay tã ngày 5 thg 10**" (No diaper change logged on 5 Oct)
- "Nếu quên ghi lúc đó, bạn có thể ghi bù với giờ của ngày này." (If you forgot to log it at the time, you can back-log it with a time on this day.)
- Button (tinted mint-soft): "**+ Ghi bù thay tã**" (Back-log diaper change). Effect: opens the diaper log form pre-set to 5 Oct (inferred from the copy "với giờ của ngày này").

**Text link** (mint-text, centred): "**Xem tất cả ghi chép ngày 5 thg 10**" (See all records for 5 Oct). Effect: switches the filter to "Tất cả" for that day (inferred).

**Notes:**
- The empty copy is filter-specific ("thay tã"). Other filters presumably follow the pattern "Chưa ghi <type> ngày <d thg m>" (inferred; not designed).
- Day 5 has records (the 20f calendar shows dots on day 5), so "empty" means empty for this filter.
- No all-filter empty state is designed (no records at all that day).

---

## 7. 108:10271 — "20f Chọn ngày" (date picker; tapping "Tháng 10")

**Presentation:** a bottom sheet over a scrim. The History screen ("Tất cả", today) shows dimmed behind it.

**SheetHeader:**
- A grabber bar.
- Title "**Chọn ngày**" (Pick a date).
- Close "×" icon. Effect: dismisses the sheet.

**Month nav:**
- "‹" previous month (enabled).
- "**Tháng 10, 2026**" (October 2026).
- "›" next month, **disabled** (opacity 35%) because the next month is in the future.

**Weekday header:** "T2 T3 T4 T5 T6 T7 CN". The week starts on **Monday**.

**Grid** (Oct 2026: the 1st falls on T5):
- Days 1–8 are enabled, and each shows a row of 3 coloured **dots**. One shared dots asset is used: blue, purple, green. Most likely the dots are care-type colours (inferred).
- **Day 8 (today) is selected**, shown as a mint-deep circle with white number.
- **Days 9–31 are future**: rendered at 35% opacity with no dots, so they cannot be selected.

**Footnote (verbatim):** "**Chấm màu = ngày có ghi chép. Teddy sinh ngày 17 tháng 9, không chọn được ngày trước đó.**"
- Gloss: "Coloured dot = day with records. Teddy was born on 17 September; dates before that cannot be selected."

**Button** (tinted mint-soft, full width): "**Về hôm nay**" (Back to today). Effect: selects today and closes (inferred).

**Effect of picking a day:** closes the sheet. The History screen then jumps to that day: the day strip recentres or scrolls to the week containing the day, and the month chip updates (inferred).

**Open:** do the dot colours encode which care types were logged (one dot per type present) or are they decorative? The mock uses identical dots on every day.

---

## 8. 109:10562 — "20g Thống kê bú · 7 ngày · Light" (Feeding stats, 7 days)

**Chrome:**
- Back button, BabySwitcher "Teddy".
- Title "**Thống kê bú**" (Feeding statistics), 30px.
- TabDock with Hôm nay active.
- No day strip, filters or month picker.

**Segmented** (3 options): "**Hôm nay**" (Today) | "**7 ngày**" (7 days, selected) | "**30 ngày**" (30 days). Per the Segmented component description, it "remembers the last choice as the default".

**KPI tiles** (3 across; value / label):
- "640 ml" / "TB mỗi ngày" (average per day)
- "8 cữ" / "TB mỗi ngày" (average feeds per day)
- "2g 50p" / "Cách nhau TB" (average interval; g = giờ, p = phút)

**Card "Bú ngày và đêm"** (Day and night feeding):
- Subtitle: "**Ngày 06:00–18:00 · Đêm 18:00–06:00 · TB 7 ngày**" (Day 06–18 · Night 18–06 · 7-day average)
- Ratio bar: day in sunshine yellow #ffd166, night in sleep purple #6c6fd8.
  - In the 7-day frame both segments are flex 1:1, so they draw 50/50 although the labels say 62/38. This looks like a design artifact; the Hôm nay frame uses a true 47:53.
- Legend:
  - "Ngày **62%**" / "400 ml · 5 cữ"
  - "Đêm **38%**" / "240 ml · 3 cữ"
- Insight box: "**Đêm qua bú 3 cữ, khoảng nghỉ dài nhất 3 giờ 40 phút (00:20–04:00).**" (Last night: 3 feeds; longest gap 3 h 40 (00:20–04:00).)

**Card "Lượng sữa theo giờ"** (Milk volume by hour):
- Subtitle: "**Bú bình · trung bình 7 ngày (ml)**" (Bottle · 7-day average (ml))
- Chart: 24 vertical bars for hours 0h–23h.
  - Y gridlines 0 / 20 / 40 / 60.
  - X labels 0h, 6h, 12h, 18h, 24h.
  - Night shading over 0–6h and 18–24h.
- Hourly values (from layer names):
  - 0h 19, 1h 28, 2h 13, 3h 35, 4h 9, 5h 25
  - 6h 38, 7h 13, 8h 44, 9h 9, 10h 22, 11h 41
  - 12h 13, 13h 19, 14h 44, 15h 16, 16h 25, 17h 38
  - 18h 19, 19h 28, 20h 35, **21h 54 (peak)**, 22h 19, 23h 32
  - These sum to about 638 ml, which is about 640 ml/day.
- The peak bar is drawn darker (bottle-ink) with a callout "**21h · 54 ml**".
- Legend: "ml mỗi giờ" (ml per hour), "Khung đêm" (night window).
- **Inconsistency:** the day hours 6–17 sum to about 322 ml and the night hours to about 316 ml. That does not match the "Ngày 400 ml / Đêm 240 ml" split in the card above.

**Card "Bú mẹ"** (Breastfeeding):
- Subtitle "TB 7 ngày".
- "**3 cữ**" / "mỗi ngày" (per day).
- "**14 phút**" / "mỗi cữ" (per feed).
- Side bar (breast accent #e07a9a = left, breast ink #a33a5e = right) at 52:48.
- Legend: "Bên trái 52%" (left side), "Bên phải 48%" (right side).
- Hint (breast-soft): "**Lần trước kết thúc bên phải → lần tới nên bắt đầu bên trái.**" (Last time ended on the right → next time start on the left.)

**Interactions:**
- Segmented → swaps the window (Hôm nay = 20g2; 30 ngày was not designed).
- Back → History (Bú filter).
- BabySwitcher → switch baby.
- Tapping bars to inspect values was not designed. The peak callout appears static (inferred).

---

## 9. 110:10949 — "20g2 Thống kê bú · Hôm nay · Light" (Feeding stats, Today)

**Segmented:** "Hôm nay" is selected.

**KPI tiles:**
- "**510 ml**" / "**Từ 18h hôm qua**" (since 18:00 yesterday). So the "Hôm nay" window = **18:00 yesterday → now**.
- "**6 cữ**" / "**5 bình · 1 mẹ**" (5 bottle · 1 breast). This shows the **feed count includes both bottle and breast**.
- "**3g 10p**" / "Cách nhau TB"

**Card "Đêm qua và hôm nay"** (Last night and today):
- Subtitle: "**Đêm qua 18:00–06:00 · Hôm nay từ 06:00**" (Last night 18–06 · Today from 06:00)
- Ratio bar at flex 47:53.
- Legend:
  - "Hôm nay **47%**" / "240 ml · 3 cữ"
  - "Đêm qua **53%**" / "270 ml · 3 cữ"
- **Percentage is by ml**: 240/510 = 47.06%. The cữ counts include breast: "Hôm nay 3 cữ" = 2 bottles + 1 breast.
- Insight: "**Khoảng nghỉ dài nhất đêm qua: 3 giờ 40 phút (00:20–04:00).**" (Longest gap last night: 3 h 40 (00:20–04:00).)

**Card "Từng cữ hôm nay"** (Each feed today):
- Subtitle: "**Mỗi cột là một cữ bú bình (ml) · chấm hồng là bú mẹ**" (Each bar is one bottle feed (ml) · pink dot is breastfeed)
- Chart:
  - Y axis 0 / 50 / 100 / 150; X axis 0h–24h.
  - **One bar per bottle feed**, placed at its time, with a value label on top: 00:20 "90", 04:00 "90", 08:00 "120", 14:20 "120".
  - **Breastfeed is a pink dot** on the baseline at 11:30, labelled "**15p**".
  - Night shading 0–6h.
  - A "**Chưa tới**" (not yet) shaded region runs from now to 24h at 60% opacity.
  - Now line: "Bây giờ 15:05".
- Legend: "Bú bình (ml)", "Bú mẹ", "Đêm / chưa tới" (Night / not yet).
- The chart covers the calendar day 0–24h only. Yesterday's 18:00–24:00 feed (implied: 270 − 90 − 90 = 90 ml) counts in the KPI and the "Đêm qua" figure but is **not plotted**.

**Card "Bú mẹ":**
- Subtitle "Hôm nay".
- "**1 cữ**" / "hôm nay".
- "**15 phút**" / "**cả hai bên**" (both sides).
- Side bar at 50:50 in this frame.
- Legend in **minutes** instead of %: "**Trái 8 phút**" (left 8 min), "**Phải 7 phút**" (right 7 min).
- The hint repeats: "Lần trước kết thúc bên phải → lần tới nên bắt đầu bên trái."

**Data inconsistencies with History 20 / 20a (same day, same baby):**
- The stats show bottle feeds at 00:20 and 04:00 (90 ml each). History for today lists no such feeds: its Đêm section has only the sleep 21:42–06:30, and "Bú bình 2 cữ · 240 ml".
- The overnight sleep 21:42–06:30 also overlaps those feed times.
- History's "Đã ghi hôm nay / Bú hôm nay" covers calendar-day 00:00–24:00, whereas stats "Hôm nay" covers 18:00 yesterday → now. That window difference is a confirmed design choice, but the mock data does not reconcile.
- "Cách nhau TB 3g 10p" matches the 06:00+ feeds (08:00, 11:30, 14:20). Using the whole window from 18h yesterday would give about 3:30. Which window the interval uses is unclear.

---

## 10. 111:10994 — "20h Thống kê ngủ · 7 ngày · Light" (Sleep stats, 7 days)

**Chrome:** title "**Thống kê ngủ**" (Sleep statistics). Segmented "Hôm nay | **7 ngày** | 30 ngày" with 7 ngày selected. Only this one segment is designed.

**KPI tiles:**
- "**14g 20p**" / "TB mỗi ngày" (average sleep per day)
- "**6 giấc**" / "TB mỗi ngày" (average sleeps per day)
- "**6g 30p**" / "**Giấc dài nhất**" (longest sleep in the window)

**Card "Ngủ ngày và đêm"** (Day and night sleep). Night comes first here, the reverse of the feeding card:
- Subtitle: "**Đêm 18:00–06:00 · Ngày 06:00–18:00 · TB 7 ngày**"
- Ratio bar at flex 64:36, night purple then day yellow.
- Legend:
  - "Đêm **64%**" / "**9 giờ 10 · 2–3 giấc**" (9 h 10 · 2–3 sleeps)
  - "Ngày **36%**" / "**5 giờ 10 · 3–4 giấc**" (5 h 10 · 3–4 naps)
- Check: 9:10 + 5:10 = 14:20, and 550/860 = 64%. **Percentage is by duration.** The sleep count is shown as a **range** (min–max per day across the window, inferred).
- Insight: "**Giấc đêm dài nhất tăng từ 3 giờ 30 lên 6 giờ 30 trong 7 ngày.**" (Longest night sleep grew from 3 h 30 to 6 h 30 over 7 days.)

**Card "Nhịp ngủ 7 ngày"** (7-day sleep rhythm):
- Subtitle: "**Mỗi hàng là một ngày · thanh tím là lúc ngủ**" (Each row is a day · purple bars are sleep)
- Chart: rows "T6 2", "T7 3", "CN 4", "T2 5", "T3 6", "T4 7", "**T5 8**" (today in bold), oldest at the top.
- X axis 0h–24h; night shading 0–6h and 18–24h.
- Sleeps that cross midnight are **split at midnight** across two rows. For example, T4 7 ends with 21.7–24 and T5 8 starts with 0–6.5.
- The today row has a "**Bây giờ**" (now) marker and a grey "**Chưa tới**" (not yet) bar after now.
- Bar data (hours) per row:
  - T6 2: 0–3.5, 4.5–7, 9–10.5, 12–13.5, 15–16.5, 19–21, 22–24
  - T7 3: 0–3, 3.8–6.8, 9.5–11, 12.5–14.5, 16–17, 19.5–21.5, 22.3–24
  - CN 4: 0–4, 4.7–7.2, 9–10.8, 13–14.5, 16.2–17.3, 20–24
  - T2 5: 0–4.2, 5–7, 9.3–11, 12.8–14.4, 16–17, 20.5–24
  - T3 6: 0–5, 5.6–7.3, 9.5–11.2, 13–14.8, 16.5–17.4, 21–24
  - T4 7: 0–5.5, 6–7.5, 9.2–11, 13.2–15, 16.8–17.6, 21.7–24
  - T5 8: 0–6.5, 11.75–13.08
- Legend: "Ngủ", "Khung đêm".

**Card "Giấc dài nhất mỗi ngày"** (Longest sleep each day):
- Subtitle: "**Giờ ngủ liền một mạch**" (Hours slept in one stretch)
- Bar chart: Y 0g / 4g / 8g. Bars:
  - T6 3.5 (labelled "3g30")
  - T7 3
  - CN 4
  - T2 4.2
  - T3 5
  - T4 5.5
  - **T5 6.5** (darker sleep-ink, labelled "6g30", bold "T5")
- Only the first and last bars carry value labels.
- **The longest stretch is computed on the midnight-split segments.** T5's 6.5 h is the 00:00–06:30 piece of a sleep that began at 21:42 on T4, about 8.8 h in full.

---

## 11. 109:12017 — "Thống kê bú · Night care" (Night variant spot-check)

- Copy, values, layout, segments and cards are **identical** to 20g (7 ngày). The ratio bar draws 50/50 here too.
- Only the theme changes: a dark background and surfaces.
  - The peak bar is a lighter blue instead of darker.
  - "Bên phải" uses a light pink.
  - The hint box is dark red-brown.
  - The active nav pill and "+" use bright mint.
- **No behavioural differences found.** The Night variant does not hide or simplify any stats.

---

## Part C summary — business rules (verbatim evidence)

1. **The timeline is newest-first and grouped by time-of-day period.** Evidence: annotation "Dòng thời gian mới nhất ở trên, chia theo buổi (Sáng/Trưa/Chiều/Tối)."
   - Periods (TimeSectionHeader description): "Sáng (05–11) · Trưa (11–13) · Chiều (13–18) · Tối (18–22) · Đêm (22–05)".
   - The count pill is "N mục"; "count = entries in that period".
2. **Sleep and breastfeeding render as duration blocks; feed, diaper and growth render as point events.** Evidence: "Giấc ngủ và bú mẹ là khối có thời lượng."; "Event = point in time (feed, diaper, growth). Span = something with a duration (sleep, breastfeed)".
   - Pumping renders as an event, even with "15 phút" (20, 10:15 row).
3. **Tapping an entry opens Record detail.** Evidence: "Chạm mục → Chi tiết bản ghi."
4. **The Growth filter shows measurements, not a day timeline.** Evidence: "Lọc “Tăng trưởng” hiện các lần đo." The day strip is hidden (105:9063).
5. **Filters are single-select chips**: Tất cả · Bú · Hút sữa · Ngủ · Tã · Tăng trưởng. Evidence: "Single-select filter chip".
   - **Bú = bottle + breastfeed; pumping is excluded and has its own chip** (104:8724 omits the 10:15 "Hút sữa").
6. **Day strip**: "Today is the right-most pill; swipe for earlier weeks." It is a rolling 7 days ending today.
7. **Pending sync**: a "Chờ" pill with a cloud-off icon. Evidence: "Pending = saved on device, waiting to sync." Pending entries count toward the summary totals (104:10130).
8. **Attribution**: every row shows "<người> ghi" (Mẹ ghi / Ba ghi / Cô Lan ghi). Caregivers are attributed by name.
9. **Today's summary rules**: totals cover bottle feeds + ml, breastfeeds + minutes, finished sleep, and diaper changes. Evidence: "Running sleep is not counted until it ends." The sleep label is literally "Ngủ (đã xong)".
10. **Pumping is not part of "Đã ghi hôm nay"** (no tile, no strip mark), as shown in 46:2469.
11. **Diaper "Cả hai" counts as both Ướt and Bẩn** (Ướt 2 / Bẩn 1 from one Ướt and one Cả hai).
12. **An empty day per filter offers back-logging.** Evidence: "Chưa ghi thay tã ngày 5 thg 10" / "Nếu quên ghi lúc đó, bạn có thể ghi bù với giờ của ngày này." / "Ghi bù thay tã" / "Xem tất cả ghi chép ngày 5 thg 10".
13. **The date picker cannot go before birth or into the future.** Evidence: "Chấm màu = ngày có ghi chép. Teddy sinh ngày 17 tháng 9, không chọn được ngày trước đó."
    - Future days and the next-month arrow are disabled (35% opacity). There is a "Về hôm nay" shortcut. Weeks start on Monday (T2).
14. **The stats windows are "Hôm nay · 7 ngày · 30 ngày"** (Segmented), and the Segmented "Remembers the last choice as the default."
15. **The stats day/night boundary is 06:00 / 18:00.** Evidence: "Ngày 06:00–18:00 · Đêm 18:00–06:00".
    - This differs from the History period headers, where Đêm is 22–05.
16. **The feeding "Hôm nay" window starts at 18:00 the previous evening.** Evidence: "510 ml" / "Từ 18h hôm qua"; "Đêm qua 18:00–06:00 · Hôm nay từ 06:00".
17. **Feed counts include breastfeeds; volumes are bottle-only.** Evidence: "6 cữ" / "5 bình · 1 mẹ"; "Lượng sữa theo giờ — Bú bình · trung bình 7 ngày (ml)"; "Mỗi cột là một cữ bú bình (ml) · chấm hồng là bú mẹ".
18. **The breast-side suggestion**: "Lần trước kết thúc bên phải → lần tới nên bắt đầu bên trái." The next side to start on is the opposite of the side the last session ended on.
19. **Growth deltas compare to the previous measurement**: "+0,4 kg so với 1 thg 10 · +1,5 cm". The first record is labelled "Lúc sinh" (at birth).
20. **Stats entry points**: the stats link cards appear only under the Bú filter ("Xem thống kê bú") and the Ngủ filter ("Xem thống kê ngủ"). There is none for Tã, Hút sữa, Tăng trưởng or Tất cả.
21. **Number and unit formatting**:
    - Decimal comma ("4,3 kg", "54,5 cm").
    - Volumes in ml. Durations as "X giờ Y phút" in rows, and "X giờ Y" in cards (e.g. "7 giờ 50").
    - Compact "Xg Yp" in stats KPIs and chart labels ("14g 20p", "3g30"); "p" alone for minutes ("15p").
    - Dates as "d thg m" ("5 thg 10"), or "d tháng m" in prose ("17 tháng 9"). Calendar month header "Tháng 10, 2026".
    - Relative time: "45 phút trước", "1 giờ 25 phút trước".
    - Counts: "cữ" (feeds), "giấc" (sleeps), "lần" (times), "mục" (items).
22. **The Night variant behaves the same** as Light (109:12017).

## Part C summary — computation rules (as shown)

**History summary card (calendar day 00:00–24:00 of the selected day):**
- Bottle: count of bottle feeds · sum of ml.
- Breast: count · sum of minutes.
- Sleep "Ngủ (đã xong)" / "Tổng đã ngủ": the sum of finished sleep duration **clipped to the day**. A sleep from 21:42 yesterday to 06:30 contributes 6:30.
- "Số giấc": the number of sleep segments within the day, including the clipped overnight one.
- "Giấc dài nhất": the longest **clipped** segment.
- "Đang thức": now − end of the last sleep, shown as "2 giờ · từ 13:05".
- "Cữ gần nhất": now − start of the last feed (bottle or breast).
- "Cách nhau trung bình": the mean gap between consecutive feed **start** times (bottle + breast combined) within the day. Example: 08:00 / 11:30 / 14:20 → 3:10.
- Diaper:
  - Tổng = count.
  - Ướt = count of (Ướt + Cả hai).
  - Bẩn = count of (Bẩn + Cả hai).
  - Gần nhất = now − last change.
- 24h strip: 0–24h track. Spans are drawn as blocks (sleep h20, breastfeed h16), events as ticks, plus a now line.

**Feeding stats:**
- **7 ngày / 30 ngày**: per-day averages over the window.
  - "TB mỗi ngày" ml = bottle ml / days.
  - "cữ" = (bottle + breast) count / days (inferred from 20g2).
  - "Cách nhau TB" = mean interval between feeds.
- **Day/night split**: Day = 06:00–18:00, Night = 18:00–06:00. Show % **by ml** (confirmed in 20g2: 240/510 = 47%) and absolute ml + cữ per bucket.
- **Insight "Đêm qua …"**: the count of feeds last night (18–06) and the longest gap between consecutive feeds, with its start–end times.
- **"Lượng sữa theo giờ"** (7d): for each clock hour 0–23, the average bottle ml per day. The peak hour is highlighted with the callout "<h>h · <ml> ml".
- **Hôm nay**:
  - Window = 18:00 yesterday → now. KPIs: total bottle ml; feed count split "N bình · M mẹ"; mean interval.
  - Split "Đêm qua (18–06)" vs "Hôm nay (từ 06:00)" by ml.
  - Per-feed chart for calendar-day 0–24h: bars = bottle ml at their time, pink dots = breastfeeds labelled with minutes, "Chưa tới" shading after now.
- **Bú mẹ**:
  - 7d: average breastfeeds per day ("3 cữ mỗi ngày"), average minutes per feed ("14 phút mỗi cữ"), and the left/right share as % of time (52/48).
  - Hôm nay: count, total minutes and sides ("cả hai bên"), with left/right shown in **minutes** ("Trái 8 phút" / "Phải 7 phút").
  - Next-side hint = the opposite of the last session's ending side.

**Sleep stats (7 ngày):**
- "TB mỗi ngày" = total sleep / days.
- "giấc TB mỗi ngày" = number of sleeps / days.
- "Giấc dài nhất" = the maximum single uninterrupted stretch in the window (computed on midnight-split segments in the mock).
- Day/night split by **duration**: Night 18:00–06:00, Day 06:00–18:00. Each bucket shows the average duration per day and the range of sleep counts per day ("2–3 giấc").
- Insight: the trend of the longest night sleep from the first to the last day of the window ("tăng từ 3 giờ 30 lên 6 giờ 30 trong 7 ngày").
- "Nhịp ngủ 7 ngày": one row per day (oldest on top, today last and bold). Sleep bars run 0–24h, split at midnight. Night shading covers 0–6 and 18–24. Today shows a now marker and a "Chưa tới" area.
- "Giấc dài nhất mỗi ngày": the per-day maximum stretch, as a bar chart in hours. Today's bar is highlighted; the first and last bars are labelled in "XgYY" format.

**Growth:**
- The headline is the latest measurement: the selected metric is primary and the other is secondary.
- Delta = latest − previous measurement, with the previous date given ("so với 1 thg 10").
- The chart is a time-proportional line of all measurements for the selected metric. The row subtitle gives the delta vs the previous record, or "Lúc sinh" for the first.

## Part C — open questions (detail)

1. **Midnight-crossing sleep (46:2469, 104:9429, 111:10994).**
   - The row reads "Ngủ 6 giờ 30 phút" with "21:42 hôm qua – 06:30", but the real span is 8 h 48.
   - Should the row show the full duration and only the totals be clipped?
   - Should "Giấc dài nhất" (KPI and per-day chart) use full uninterrupted sleeps (8 h 48) or midnight-split pieces (6 h 30, as in the mock)?
   - The time column shows "00:00", not the real start.
2. **Section periods (46:2469).**
   - The annotation lists "Sáng/Trưa/Chiều/Tối", while the component lists 5 periods including Đêm 22–05.
   - Within one calendar day, are 22:00–24:00 entries shown under "Đêm" at the top (newest)? Then Đêm would appear twice, once for 00–05 and once for 22–24.
   - "Tối" (18–22) is never shown in the mocks.
3. **Window mismatch between History and Stats.**
   - History "hôm nay" is calendar-day 00–24 and its sections use Đêm 22–05.
   - Stats "Hôm nay" is 18:00 yesterday → now, and its day/night is 06–18 / 18–06.
   - Confirm the intended difference and the labels for each.
4. **Mock data inconsistency (110:10949 vs 46:2469 / 104:8724).** The stats show bottle feeds at 00:20 and 04:00 (90 ml each), which are absent from the History timeline for the same day and overlap the 21:42–06:30 sleep. This needs a reconciled dataset for QA.
5. **Ratio vs chart inconsistency (109:10562).**
   - The hourly bars give a day share of about 322 ml vs night about 316 ml, but the ratio says Ngày 400 ml (62%) / Đêm 240 ml (38%).
   - The 7-day ratio bar is drawn 50/50, despite the 62/38 label.
   - The 20g2 side bar is drawn 50/50 with "Trái 8 / Phải 7" minutes.
   - Is "Ngày %" computed by ml or by count? 20g2 suggests ml.
6. **"Cách nhau TB" window (110:10949).** "3g 10p" matches only the 06:00+ feeds. Clarify whether it covers the whole "Từ 18h hôm qua" window, and whether bottle and breast are mixed (20a suggests yes).
7. **"8 cữ TB mỗi ngày" (109:10562).** Does it include breastfeeds? Inferred yes from 20g2 ("5 bình · 1 mẹ"); then Ngày 5 cữ / Đêm 3 cữ include breast. Should pumping ever count? It is presumably excluded.
8. **The 30 ngày segment is not designed** for either stats screen. The **Hôm nay segment for Thống kê ngủ** is also not designed. Do charts change form at 30 days (e.g., "Nhịp ngủ 30 ngày" with 30 rows)?
9. **Which segment the stats link opens on** (104:8724 → 20g/20g2, 104:9429 → 20h): the last-used segment (per Segmented "remembers last choice") or 7 ngày?
10. **Pumping ("Hút sữa").**
    - There is no filtered screen, no summary-card variant and no stats.
    - Should the "Đã ghi hôm nay" card include pumped ml?
    - Should the pump row be a span block like breastfeeding (it has 15 phút)?
    - Does pumped milk later fed by bottle double-count?
11. **Diaper stats.** There is no diaper stats link or screen. Confirm this is intended out of scope.
12. **Summary card on a past day.** The title is "…hôm nay" in all mocks; the copy for a non-today selection (e.g., "Đã ghi ngày 5 thg 10") is not designed. "Cữ gần nhất", "Đang thức" and the now line would also be meaningless on past days.
13. **Empty states.** Only the Tã filter's empty-day state is designed (105:9471). The copy for the Bú, Ngủ, Hút sữa, Tất cả and Tăng trưởng empty states (no measurements yet) is missing. Stats empty or insufficient data is also missing, e.g. a 7-day average before the baby is 7 days old.
14. **Loading and error states** are not designed for History or Stats, and there is no offline banner. Only the per-row "Chờ" pending pill exists. Is there a failed-sync state, beyond "Chờ"?
15. **Running sleep display.** How does an in-progress sleep or breastfeed appear in the timeline and in the "Ngủ hôm nay" card (no "Đang ngủ" state)? "Đang thức" would be replaced.
16. **Month picker under the Growth filter (105:9063).** The list spans Sep–Oct. Does the month chip filter measurements or do nothing? The calendar dots also do not differentiate growth.
17. **Calendar dots (108:10271).** Do the three colours encode care types present that day (bottle/sleep/diaper?), or is it a generic "has records" marker? One identical asset is used for all days.
18. **Duration bar width.** Every span bar is a fixed 120px in the mock. Should it be proportional to duration, and on what scale?
19. **Layout truncation bugs:**
    - "1 giờ 25 phút trước" is clipped in the Tã card (104:10130).
    - The growth date column (44px) clips "8 thg 10", "1 thg 10" and "17 thg 9" (105:9063).
20. **Growth chart.** There are no WHO percentile curves, no units toggle and no age axis. Confirm this is intentional. The "Chiều dài" toggle state is not designed.
21. **Interactivity in charts.** Tooltips and tap-to-inspect on bars or rows are not specified. The peak callout "21h · 54 ml" looks static.
22. **The stats frames carry the History annotation** (copy-paste). No stats-specific annotation exists, so the computation rules above are inferred from the numbers shown.

---

# Part D — Widgets, Lock screen, Live Activity, Dynamic Island


File key: `sJLG1fAXKDnDr9YI6Yx8ex` · Screens page 26:2 · Components page frame 73:399
Read-only extraction (get_metadata / get_design_context / get_screenshot). Mark "(inferred)" = not shown literally in the design.

> No `data-annotations` attributes were present on any node read in this section. The rules come from (a) the section note, (b) caption text nodes in W3/W5, and (c) Figma **component descriptions** (English). All are quoted verbatim below.

---

## 0. Section-level copy

| Node | Verbatim | Gloss |
|---|---|---|
| 76:5439 | `6 · Widgets` | Section title |
| 76:5440 | `Ghi nhanh ngoài app: Home screen, Lock screen, Live Activity & Dynamic Island. Bấm = ghi ngay, widget hiện "Đã ghi · Hoàn tác" ~5 giây.` | Quick logging outside the app: Home screen, Lock screen, Live Activity and Dynamic Island. Tap = log right away; the widget shows "Logged · Undo" for about 5 seconds. |
| 73:401 (Components page) | `Home screen (S/M/L), Lock screen, Live Activity & Dynamic Island. Ghi 1 chạm + hoàn tác (iOS 17 App Intents).` | Home screen (S/M/L), Lock screen, Live Activity & Dynamic Island. 1-tap log + undo (iOS 17 App Intents). |

Sample data used throughout: baby **Teddy**; caregivers **Mẹ** (Mum), **Ba** (Dad), **Cô Lan** (nanny/other caregiver), **Bạn** (You = current user).

---

## 1. Widget families and sizes (from Components 73:399)

| Family | Component (node) | Size (pt) | Variant property → values (verbatim) |
|---|---|---|---|
| Home screen Small | `Widget/Small` (set 73:483) | 170×170, radius 22 | **Type** = `Bottle` (73:402), `Breast` (73:419), `Sleep` (73:433), `Sleeping` (73:448), `Diaper` (73:463), `Bottle logged` (81:545), `Breast running` (81:567), `Diaper logged` (81:583), `Empty` (81:608), `Signed out` (81:625) |
| Home screen Medium | `Widget/Medium` (set 74:551) | 364×170 | **State** = `Default` (74:421), `Logged` (74:483), `Offline` (81:642) |
| Home screen Large | `Widget/Large` (symbol 74:552, no variants) | 364×382 | — |
| Lock screen circular | `Lock/Circular` (frame 75:524) | 76×76 | **Type** = `Sleep` (75:512), `Feed` (75:518) |
| Lock screen rectangular | `Lock/Rectangular` (75:525) | 172×76 | — |
| Lock screen inline | `Lock/Inline` (75:532) | 240×20 | — |
| Live Activity (Lock screen banner) | `LiveActivity/Lock screen` (set 75:576) | 364×158, radius 24 | **Type** = `Sleep` (75:537), `Breast` (75:557) |
| Dynamic Island | `DynamicIsland/Sleep` (set 75:606) | Compact 250×37 · Minimal 37×37 · Expanded 371×168 | **Mode** = `Compact` (75:577), `Minimal` (75:584), `Expanded` (75:590) |

Notes:
- Lock-screen family container frame 75:536 is named `Lock screen widgets`.
- Only a **Sleep** Dynamic Island component exists. No Breast Dynamic Island variant was designed, although a Breast Live Activity exists. See Open questions.
- No Medium/Large "Signed out"/"Empty" variants and no Lock-screen state variants exist.

### Component descriptions (verbatim)
- **Widget/Small (73:483):** "Home screen small widget (170×170). Primary button logs in 1 tap; widget then shows the Logged state with Undo."
- **Widget/Medium (74:551):** "Medium widget: 4 one-tap quick-log tiles (Bottle = last amount, Breast/Sleep = start timer, Diaper = Wet). Logged state shows Undo for ~5s."
- **Widget/Large (74:552):** "Large widget: sleep status + quick log + 3 most recent entries."
- **LiveActivity/Lock screen (75:576):** "Live Activity on Lock screen for running Sleep / Breast timers. Buttons end or adjust without opening the app."
- Icons (Icon/plus 7:36, Icon/check 7:45, Icon/feed 7:9, Icon/sleep 7:12, Icon/cloud-off 7:49): "Line icon (24px, 1.8 stroke) — placeholder drawing; production uses SF Symbols. Recolour by overriding the stroke with a text-colour token."
- Illustration/Mini/Bottle 25:334, /Drop 25:341, /Moon 25:345, /Diaper 25:350: "Small 3D-style object for tracker tiles (fixed colours)."
- Illustration/BabyFace 25:323: "Small baby avatar for headers."
- Logo/App Icon 35:239: "App icon 1024 full-bleed cho phương án 2 (iOS tự bo góc). Light / Dark / Tinted." (iOS rounds the corners itself; Light/Dark/Tinted app-icon variants.)

---

## 2. Per-frame details

### 2.1 76:5441 "W1 Home screen · Light"
**Purpose:** Home screen (iPhone 393×852) showing a Medium widget on top and a Small "Giấc ngủ" widget next to app icons (Ảnh, Lịch, Child Life, Ghi chú).

**Widget/Medium — State=Default (74:421)**
- Header: baby avatar + `Teddy` · right-aligned summary `2 cữ · ngủ 7g50 hôm nay` (2 feeds · slept 7h50 today).
- 4 QuickTiles, each with a 3D mini illustration, label, "time since" meta, and a white round **+** badge top-right:
  | Tile | Label | Meta (verbatim) | Gloss |
  |---|---|---|---|
  | Bottle (bottle-soft #e5f1fb) | `Bú bình` | `45 phút` | bottle feed · 45 min ago |
  | Breast (breast-soft #fceaf0) | `Bú mẹ` | `3g 35p` | breastfeed · 3h35m ago |
  | Sleep (sleep-soft #edeefc) | `Ngủ` | `thức 2g` | sleep · awake 2h |
  | Diaper (diaper-soft #e7f4e3) | `Thay tã` | `1g 25p` | diaper · 1h25m ago |
- Tap behavior (from description): Bottle = log last amount; Breast/Sleep = start timer; Diaper = log Wet. All one-tap, then Logged state with Undo ~5s.

**Widget/Small — Type=Sleep (73:433)**
- Title `Giấc ngủ` (Sleep) · big `Đã thức 2 giờ` (awake 2 hours) · sub `Dậy lúc 13:05` (woke at 13:05) · button `Bắt đầu ngủ` (Start sleep).

Other copy: status-bar `9:41`; app icon labels `Ảnh` (Photos), `Lịch` (Calendar), `Child Life`, `Ghi chú` (Notes) (placeholder phone UI).

### 2.2 76:6650 "W1b Home screen trang 2 · Light" (home screen page 2)
**Purpose:** Shows the Large widget plus two Small widgets (Bottle, Diaper).

**Widget/Large (74:552)**
- Header: avatar + `Teddy` · date `Thứ Năm, 8 tháng 10` (Thursday, 8 October).
- Sleep status card (sleep-soft): moon · `Đã thức 2 giờ` (awake 2 hours) · `Dậy lúc 13:05 · ngủ 7g50 hôm nay` (woke 13:05 · slept 7h50 today) · pill button `Ngủ` (Sleep → start sleep timer, (inferred) same intent as "Bắt đầu ngủ").
- Quick log row: identical 4 tiles as Medium (`Bú bình 45 phút`, `Bú mẹ 3g 35p`, `Ngủ thức 2g`, `Thay tã 1g 25p`).
- Section label `Gần đây` (Recent) — 3 rows, each: coloured dot (category colour) · time · description · who logged:
  - `14:20` · `Bú bình · 120 ml` · `Mẹ`
  - `13:40` · `Thay tã · Ướt` (diaper · wet) · `Cô Lan`
  - `11:45` · `Ngủ 1 giờ 20 phút` (slept 1h20m) · `Ba`
- Totals footer: `Hôm nay: 2 cữ bình 240 ml · 1 lần bú mẹ · 2 tã` (Today: 2 bottle feeds 240 ml · 1 breastfeed · 2 diapers).

**Widget/Small Type=Bottle (73:402):** title `Bú bình` · big `45 phút trước` (45 min ago) · sub `120 ml · Mẹ ghi` (120 ml · logged by Mum) · button `+ 120 ml` (logs another bottle with the last amount).

**Widget/Small Type=Diaper (73:463):** title `Thay tã` · big `1 giờ 25 phút` · sub `trước · Ướt` (ago · Wet) · 3 buttons `Ướt` (Wet, primary filled), `Bẩn` (Dirty), `Cả hai` (Both).

### 2.3 76:5703 "W2 Lock screen · Light"
**Purpose:** iOS Lock screen showing all accessory widget families + a running Sleep Live Activity + Dynamic Island compact.

- **Dynamic Island (Compact, 75:577):** moon icon left · `1:27` (elapsed, sleep-accent colour) right.
- **Lock/Inline (75:532)** (above clock): feed icon + `Teddy bú 45 phút trước` (Teddy fed 45 min ago).
- Clock `9:41`.
- **Lock/Circular Type=Sleep (75:512):** progress ring + sleep icon + `1:27` (running sleep elapsed h:mm).
- **Lock/Circular Type=Feed (75:518):** progress ring + feed icon + `45p` (45 min since last feed). Ring fill presumably = time since feed vs expected interval (inferred; no rule shown).
- **Lock/Rectangular (75:525):** feed icon + `Teddy` / `Bú 45p · Tã 1g25p` (fed 45m · diaper 1h25m) / `Thức 2 giờ · ngủ 7g50` (awake 2h · slept 7h50). (Note: rectangular shows "Thức 2 giờ" while a sleep is shown running elsewhere on the same screen — demo inconsistency, see gaps.)
- **LiveActivity/Lock screen Type=Sleep (75:537):**
  - Top: app icon + `Child Life` · right `Cả nhà đang thấy` (The whole family is seeing this → activity is shared to all caregivers).
  - Main: moon · `Teddy đang ngủ` (Teddy is sleeping) · `Từ 21:42 · Ba bắt đầu` (since 21:42 · started by Dad) · timer `1:27:06`.
  - Buttons: `Thức dậy` (Wake up — primary; ends the sleep, runs in background) · `Sửa giờ bắt đầu` (Edit start time — opens app to "25 Timer ngủ", per W5 deep-link table).

### 2.4 76:5779 "W3 Dynamic Island · Light"
**Purpose:** Dynamic Island modes and Breast Live Activity.
- **Expanded (75:590):** moon · `Teddy đang ngủ` · `Từ 21:42 · Ba` · `1:27:06` · buttons `Thức dậy` (sleep-accent fill, black text) and `Sửa giờ` (Edit time).
- Caption 76:5800 (verbatim): `Chạm giữ Dynamic Island để mở rộng. Thu gọn: icon trăng + thời gian; khi có 2 Live Activity: dạng Minimal.` — Long-press the Dynamic Island to expand. Collapsed: moon icon + time; when there are 2 Live Activities: Minimal form.
- **Compact (75:577):** moon + `1:27`.
- **Minimal (75:584):** moon icon only (37×37 circle).
- **LiveActivity/Lock screen Type=Breast (75:557):**
  - Top: `Child Life` · `Cả nhà đang thấy`.
  - Main: drop illustration · `Bú mẹ · bên trái` (Breastfeeding · left side) · `Từ 15:02 · Mẹ` (since 15:02 · Mum) · timer `08:12` (mm:ss, breast-ink colour).
  - Buttons: `Đổi bên` (Switch side, secondary) · `Kết thúc` (End, primary breast-accent).
- Caption 76:5851 (verbatim): `Live Activity bú mẹ: đổi bên / kết thúc ngay trên màn khoá.` — Breastfeeding Live Activity: switch side / end right on the lock screen.

### 2.5 76:5852 "W4 Widget states · Light"
**Purpose:** catalogue of Small types and Medium states.
Small row:
| Type | Title | Big value | Sub | Button(s) |
|---|---|---|---|---|
| Bottle | `Bú bình` | `45 phút trước` | `120 ml · Mẹ ghi` | `+ 120 ml` |
| Breast | `Bú mẹ` | `3 giờ 35 phút` | `trước · 15 phút` (ago · lasted 15 min) | `Bắt đầu bú` (Start feeding) |
| Sleep | `Giấc ngủ` | `Đã thức 2 giờ` | `Dậy lúc 13:05` | `Bắt đầu ngủ` |
| Sleeping (bg sleep-soft) | `Đang ngủ` (Sleeping) | `1:27:06` (28pt numeral) | `Từ 21:42 · Ba` | `Thức dậy` |
| Diaper | `Thay tã` | `1 giờ 25 phút` | `trước · Ướt` | `Ướt` / `Bẩn` / `Cả hai` |

Medium row: Default (as W1) and **Logged (74:483)**:
- Header replaced by dark "Undo toast" pill (ink #173d44): check icon · `Đã ghi Thay tã · Ướt` (Logged Diaper · Wet) · `Hoàn tác` (Undo, mint #2cbfb3).
- Diaper tile meta changes to `Vừa xong` (Just now, diaper-ink, semibold) and the + badge becomes a filled green check badge.

### 2.6 84:6579 "W5 Khi chạm widget · Light" (What happens when tapping the widget)
Title 84:6580 `Khi chạm widget` (When tapping the widget).
Rule text 84:6581 (verbatim): `Nút trên widget chạy ngầm (App Intent): app không mở, widget tự đổi trạng thái và hiện Hoàn tác ~5 giây. Chạm vùng khác của widget mới mở app đúng màn.`
— Buttons on the widget run in the background (App Intent): the app does not open; the widget changes state by itself and shows Undo for ~5 s. Tapping any other area of the widget opens the app at the right screen.

#### Flow "Bú bình" (84:6982)
1. Small Bottle: `45 phút trước` / `120 ml · Mẹ ghi` / `+ 120 ml`
2. Step `Chạm “+ 120 ml”` (Tap "+ 120 ml") →
3. **Type=Bottle logged (81:545)** — bg bottle-soft, title `Bú bình` + filled check badge · `Vừa xong` (Just now) · `Đã ghi 120 ml · Bạn` (Logged 120 ml · You) · buttons `Hoàn tác` (Undo) and `Sửa` (Edit → opens app "22 Ghi bú bình (mở sẵn bản vừa ghi)").
4. Step `Sau 5 giây` (After 5 seconds) →
5. Back to normal Bottle: `Vừa xong` / `120 ml · Bạn ghi` (120 ml · logged by you) / `+ 120 ml`.

#### Flow "Bú mẹ" (84:6990)
1. Small Breast: `3 giờ 35 phút` / `trước · 15 phút` / `Bắt đầu bú`
2. Step `Chạm “Bắt đầu bú”` →
3. **Type=Breast running (81:567)** — bg breast-soft, title `Đang bú` (Feeding) · timer `08:12` · `Bên trái · từ 15:02` (Left side · since 15:02) · buttons `Đổi bên` (Switch side, white) + `Xong` (Done, breast-accent).
4. Step `Chạm “Xong”` →
5. Breast normal: `Vừa xong` / `Bú 12 phút · Bạn ghi` (fed 12 min · logged by you) / `Bắt đầu bú`.
- Note: no Undo state shown after "Xong" for breast, and no "Hoàn tác" shown after "Bắt đầu bú" (timer start). (gap)
- Side starts as `Bên trái` by default in the demo (default-side rule not stated — gap).

#### Flow "Giấc ngủ" (84:6998)
1. Small Sleep: `Đã thức 2 giờ` / `Dậy lúc 13:05` / `Bắt đầu ngủ`
2. Step `Chạm “Bắt đầu ngủ”` →
3. Sleeping: `Đang ngủ` / `1:27:06` / `Từ 21:42 · Ba` / `Thức dậy`
4. Step `Chạm “Thức dậy”` →
5. Sleep normal: `Vừa thức dậy` (Just woke up) / `Ngủ 1 giờ 27 phút` (Slept 1h27m) / `Bắt đầu ngủ`.
- No undo state shown for sleep start/stop (gap).

#### Flow "Thay tã" (84:7006)
1. Small Diaper: `1 giờ 25 phút` / `trước · Ướt` / `Ướt` `Bẩn` `Cả hai`
2. Step `Chạm “Ướt”` →
3. **Type=Diaper logged (81:583)** — bg diaper-soft, check badge · `Vừa xong` · `Đã ghi Ướt · Bạn` (Logged Wet · You) · buttons `Hoàn tác` (Undo) + `Đổi loại` (Change type → opens app "24 Thay tã (mở sẵn bản vừa ghi)").
4. Step `Sau 5 giây` →
5. Diaper normal: `Vừa xong` / `Ướt · Bạn ghi` / `Ướt` `Bẩn` `Cả hai`.

#### Flow "Ghi nhanh (M)" (84:7014) — Medium quick log
1. Medium Default.
2. Step `Chạm ô Thay tã` (Tap the Diaper tile) →
3. Medium Logged: toast `Đã ghi Thay tã · Ướt` + `Hoàn tác`; diaper tile `Vừa xong` + check.
4. Step `Sau 5 giây` →
5. Medium Default again (mock still shows `Thay tã 1g 25p` and header `2 cữ …` — likely not updated in mock; real behaviour should show fresh value, (inferred)).

#### "Những chỗ sẽ mở app" (Places that open the app) — table 84:7023 (verbatim, left = trigger, right = destination screen #)
| Trigger | Destination |
|---|---|
| `Chạm vùng trống / tiêu đề widget` (tap empty area / widget title) | `19 Hôm nay` (Today) |
| `“Sửa” sau khi ghi bú bình` ("Edit" after logging a bottle) | `22 Ghi bú bình (mở sẵn bản vừa ghi)` (Log bottle, pre-opened with the entry just logged) |
| `“Đổi loại” sau khi thay tã` ("Change type" after diaper) | `24 Thay tã (mở sẵn bản vừa ghi)` (Diaper, pre-opened with entry just logged) |
| `“Sửa giờ bắt đầu” trên Live Activity` ("Edit start time" on Live Activity) | `25 Timer ngủ` (Sleep timer) |
| `Chạm một dòng “Gần đây” (widget L)` (tap a "Recent" row, Large widget) | `21 Chi tiết bản ghi` (Entry detail) |
| `Widget trống / chưa đăng nhập` (empty / signed-out widget) | `18 Hôm nay lần đầu / Đăng nhập` (Today first-run / Sign in) |

#### "Trạng thái đặc biệt" (Special states) — 84:7043
- **Small Type=Empty (81:608):** title `Child Life` (mint-text) · `Hôm nay chưa ghi` (Nothing logged today) · `Ghi cữ đầu tiên nhé` (Log the first feed) · button `+ Ghi nhanh` (+ Quick log, mint-deep). Destination per table: `18 Hôm nay lần đầu` (inferred that the button opens the app rather than logging in background, because the table lists "Widget trống" as an app-opening place).
- **Small Type=Signed out (81:625):** title `Child Life` · `Đăng nhập để dùng widget` (Sign in to use the widget) · `Mở app` (Open app) · button `Mở Child Life` (Open Child Life) → `Đăng nhập`.
- **Medium State=Offline (81:642):** header `Teddy` · `Chưa đồng bộ · 2 bản ghi chờ` (Not synced · 2 entries pending; colour token `--pending` #7a5600) + `Icon/cloud-off`. Tiles remain fully usable.
- Caption 84:7189 (verbatim): `Mất mạng: vẫn ghi được, bản ghi lưu trên máy và hiện “Chưa đồng bộ”. Khi có mạng sẽ tự gửi lên cho cả nhà.` — Offline: logging still works; entries are stored on the device and show "Not synced". When back online they're automatically sent up for the whole family.

---

## 3. Night care variants (spot-checked)
- 76:7129 "W4 Widget states · Night care" (screenshot): **same copy and same states**; dark surfaces (near-black teal bg, dark tiles tinted per category, lighter accent buttons). Undo toast inverts to a **light** pill with dark text and mint `Hoàn tác`.
- 76:7122 "W3 Dynamic Island · Night care" (screenshot): same copy/captions; Live Activity card is dark; buttons `Đổi bên` (dark) / `Kết thúc` (pink).
- No behavioural differences observed. Not read: 76:6879, 76:6976, 76:7113, 84:7190 (assumed same copy, dark theme).
- Inferred: widgets follow system dark mode / the app's "Night care" theme. Whether widget theme follows the app's Night-care schedule or iOS appearance is unspecified (gap).

---

## 4. Behaviour summary (consolidated)

**Per-type widget actions**
| Type | Primary action(s) on widget | Immediate effect (background App Intent) | Post-action state (~5 s) | Secondary actions in post-state |
|---|---|---|---|---|
| Bottle | `+ 120 ml` (amount = last logged amount, per Medium description "Bottle = last amount") | Creates bottle entry with last amount, by current user | `Bottle logged`: `Vừa xong` / `Đã ghi 120 ml · Bạn` | `Hoàn tác` (delete entry), `Sửa` (opens 22 with entry) |
| Breast | `Bắt đầu bú` | Starts breast timer (side shown: `Bên trái`) | `Breast running`: `Đang bú` timer | `Đổi bên` (switch side), `Xong` (stop & save) |
| Sleep | `Bắt đầu ngủ` / Large `Ngủ` | Starts sleep timer | `Sleeping`: `Đang ngủ` timer + `Từ hh:mm · <who>` | `Thức dậy` (stop & save) |
| Diaper | `Ướt` / `Bẩn` / `Cả hai` (Medium tile = Wet) | Creates diaper entry of that type | `Diaper logged`: `Vừa xong` / `Đã ghi Ướt · Bạn` | `Hoàn tác`, `Đổi loại` (opens 24 with entry) |
| Medium/Large tiles | tap tile (+ badge) | Bottle=last amount, Breast/Sleep=start timer, Diaper=Wet | Medium `Logged`: toast `Đã ghi <Type> · <detail>` + `Hoàn tác`; tile `Vừa xong` + check | `Hoàn tác` |

**Undo window:** ~5 s ("~5 giây", "Sau 5 giây", "Undo for ~5s"). After 5 s the widget returns to the default state showing the new latest value with `Bạn ghi`. (Inferred: Undo deletes/rolls back the entry; on timers, Undo not shown.)

**Attribution copy:** `Mẹ ghi`, `Bạn ghi`, `· Bạn`, `Ba bắt đầu`, `· Ba`, `Cô Lan` — widgets show who logged; the current user is rendered as `Bạn` (You).

**Relative time formats seen:** `45 phút trước`, `45 phút`, `3g 35p`, `1g 25p`, `1g25p`, `thức 2g`, `Đã thức 2 giờ`, `3 giờ 35 phút` + `trước · …`, `Vừa xong`, `Vừa thức dậy`, `45p`; timers `1:27:06` (h:mm:ss), `08:12` (mm:ss), compact `1:27` (h:mm).

**Live Activities:** for running **Sleep** and **Breast** timers only (no pumping/bottle timer shown). Header `Cả nhà đang thấy` implies the activity is visible to all family caregivers (inferred: started on other caregivers' devices too, e.g. via push-to-start/remote updates). Buttons act without opening the app ("Buttons end or adjust without opening the app"), except `Sửa giờ bắt đầu` which deep-links to `25 Timer ngủ`.

**Dynamic Island:** Compact = moon + `1:27`; Minimal = moon only (when 2 Live Activities); Expanded (long-press) = name, since/by, `1:27:06`, `Thức dậy` + `Sửa giờ`.

**Multi-baby:** Not designed. All widgets show a single baby (`Teddy`) in header/titles. (Section 7c "Chọn bé · tối đa 3" exists elsewhere in the file — up to 3 babies — so widget baby selection is an open question.)

**Android:** Not shown anywhere in this section. Copy references only iOS (SF Symbols, iOS 17 App Intents, Dynamic Island).

---

## 5. Native capabilities required
- **WidgetKit** home-screen widgets: systemSmall, systemMedium, systemLarge (shown).
- **WidgetKit accessory families** (Lock screen): accessoryCircular (Sleep, Feed), accessoryRectangular, accessoryInline (shown).
- **App Intents interactive widgets (iOS 17+)** — explicit: "Ghi 1 chạm + hoàn tác (iOS 17 App Intents)", "Nút trên widget chạy ngầm (App Intent)". Intents needed (inferred names): LogBottleLastAmount, StartBreast, SwitchBreastSide, StopBreast, StartSleep, StopSleep (Wake), LogDiaper(type), UndoLastLog.
- **ActivityKit Live Activities + Dynamic Island** (iOS 16.1+; interactive buttons in Live Activities need iOS 17+) — shown. Inferred: push-token/remote updates so "Cả nhà đang thấy" works across caregivers' devices (ActivityKit push notifications; iOS 17.2+ push-to-start if activities should appear on other family devices without opening the app).
- **Deep links / widgetURL / Link** to screens 18, 19, 21, 22, 24, 25 (shown as table).
- **App Group shared storage + offline queue** — inferred from Offline state (`Chưa đồng bộ · 2 bản ghi chờ`) and caption (store on device, auto-upload later).
- **Timeline refresh / WidgetCenter.reloadTimelines** after app-side or other-caregiver changes (inferred; relative times like "45 phút trước" require periodic timeline entries or `Text(date, style: .relative/.timer)`).
- **Flutter note (inferred):** widgets/Live Activities must be native Swift extensions (e.g. via `home_widget` / `live_activities` plugins or custom platform channels); Android equivalents (Jetpack Glance AppWidget, ongoing notification for timers) are not designed.

---

## Part D summary — business rules (verbatim evidence)
1. One tap on a widget button logs immediately without opening the app — 76:5440 "Bấm = ghi ngay"; 84:6581 "Nút trên widget chạy ngầm (App Intent): app không mở, widget tự đổi trạng thái và hiện Hoàn tác ~5 giây."
2. Undo is available for ~5 seconds after a widget log — 76:5440 "widget hiện "Đã ghi · Hoàn tác" ~5 giây"; 74:551 "Logged state shows Undo for ~5s"; W5 steps "Sau 5 giây".
3. Tapping outside buttons opens the app at the relevant screen — 84:6581 "Chạm vùng khác của widget mới mở app đúng màn."; deep-link table 84:7023 (19/22/24/25/21/18).
4. Medium tile defaults: "Bottle = last amount, Breast/Sleep = start timer, Diaper = Wet" — 74:551.
5. Bottle quick-add uses the last logged amount (`+ 120 ml` after `120 ml · Mẹ ghi`) — 73:402 / 74:551.
6. Diaper small widget offers `Ướt` / `Bẩn` / `Cả hai` — 73:463.
7. After logging, `Sửa` (bottle) and `Đổi loại` (diaper) open the editor pre-loaded with that entry — 84:7029 "22 Ghi bú bình (mở sẵn bản vừa ghi)", 84:7032 "24 Thay tã (mở sẵn bản vừa ghi)".
8. Live Activities exist for running Sleep and Breast timers and their buttons work without opening the app — 75:576 description; 76:5851 "Live Activity bú mẹ: đổi bên / kết thúc ngay trên màn khoá."
9. "Sửa giờ bắt đầu" on the Live Activity opens `25 Timer ngủ` — 84:7035.
10. Dynamic Island: long-press expands; compact = moon + time; Minimal when 2 Live Activities — 76:5800.
11. Live Activity is visible to the whole family — 75:541 "Cả nhà đang thấy"; starter attribution "Ba bắt đầu".
12. Offline: logging still works, stored locally, marked "Chưa đồng bộ", auto-sync when online for the whole family — 84:7189; 81:646 "Chưa đồng bộ · 2 bản ghi chờ".
13. Signed-out widget prompts sign-in and opens app — 81:625 "Đăng nhập để dùng widget" / "Mở Child Life"; table row 84:7040 → "18 … / Đăng nhập".
14. Empty-day widget — 81:608 "Hôm nay chưa ghi" / "Ghi cữ đầu tiên nhé" / "+ Ghi nhanh" → "18 Hôm nay lần đầu".
15. Large widget shows 3 most recent entries with who logged, and tapping a row opens entry detail — 74:552 description; 84:7038 "21 Chi tiết bản ghi".
16. Widgets show who logged; current user shown as "Bạn" — 81:551 "Đã ghi 120 ml · Bạn", "120 ml · Bạn ghi".
17. Interactive widgets target iOS 17 App Intents — 73:401.

## Part D — open questions (detail)
1. **Multi-baby:** no baby picker/configuration for widgets (all show `Teddy`). Which baby does a widget show; is it configurable per widget (AppIntentConfiguration)? Relates to 7c "Chọn bé · tối đa 3" (125:13337). Nodes: 74:421, 74:552, 75:525.
2. **Bottle amount source:** "last amount" — last by anyone or by this user? What if no previous bottle exists? (73:402, 81:545)
3. **Breast default side:** demo starts `Bên trái` (81:567, 75:557). Rule (alternate from last side?) not stated.
4. **Undo for timers:** no undo state for `Bắt đầu bú` / `Xong` / `Bắt đầu ngủ` / `Thức dậy` (84:6990, 84:6998). Accidental start/stop recovery unspecified.
5. **Medium post-5s state** (84:6920) still shows `1g 25p` / `2 cữ` — mock not updated; confirm tile should show the new value.
6. **No Breast Dynamic Island** component (only `DynamicIsland/Sleep` 75:606); Breast compact/minimal/expanded content undefined. Also behaviour when Sleep + Breast run simultaneously (only "Minimal" mentioned, 76:5800).
7. **Pumping / bottle timers** not covered by widgets or Live Activities.
8. **Lock/Circular Feed ring** semantics (75:518) — what does progress represent (time since feed vs target interval?). Sleep ring (75:512) likewise.
9. **Lock/Rectangular & Inline** (75:525, 75:532) — tap destination not listed in deep-link table (assume 19 Hôm nay, inferred). Content when a sleep is running (W2 shows "Thức 2 giờ" next to a running sleep — inconsistent demo).
10. **Permission-lost / revoked caregiver access, no-baby (signed in but no baby profile), Live Activities disabled in Settings** — no states designed. Only Empty, Signed out, Offline exist.
11. **Offline + Live Activity / timers** — how do timers behave offline; conflict when two caregivers stop the same sleep (shared "Cả nhà đang thấy").
12. **Medium/Large Empty & Signed-out variants** not designed (only Small 81:608 / 81:625).
13. **Pending state on Small** widgets (only Medium Offline 81:642 shows "Chưa đồng bộ").
14. **Undo semantics on Medium Logged** (74:483) — Undo applies to which tile if user taps two tiles within 5 s?
15. **Night care theming trigger** for widgets (system dark mode vs app night schedule) — 76:7129, 76:7122.
16. **Android** equivalents not designed at all.
17. **Breast flow result** `Bú 12 phút · Bạn ghi` while running timer showed `08:12` — demo numbers only; confirm whether breast entry records per-side durations when `Đổi bên` is used.
18. Not read due to MCP rate limiting / scope: Night frames 76:6879, 76:6976, 76:7113, 84:7190 (only spot-checked 76:7129 and 76:7122 via screenshot). Metadata-only (not design context) for W5 title texts 84:6580/84:6581/84:7022/84:7042 — copy taken from the text layers' auto-generated names (Figma names text layers after their content unless renamed); not cross-checked against a render.

---

# Consolidated: navigation map (screen → destinations)

**Today (19, 46:2266)**
- CareTile Bú bình → 22 (sheet "Ghi cữ bú", Bú bình segment).
- CareTile Bú mẹ → 23 (same sheet, Bú mẹ segment).
- CareTile Giấc ngủ → 25a chooser, or → 25 Timer when a sleep is running (inferred).
- CareTile Thay tã → 24.
- CareTile Hút sữa → 23a.
- CareTile Tăng trưởng → 28.
- ReminderPeek → reminders list (S15, section 8).
- "Lịch sử" → 20.
- BabySwitcher → baby picker (section 7c).
- Night care toggle (moon) → toggles the Night care theme (inferred; see Foundations notes).
- "+" → 19a.

**Quick log (19a, 50:3572)**
- Bú bình → 22; Bú mẹ → 23; Thay tã → 24; Tăng trưởng → 28; Hút sữa → 23a.
- Ngủ → starts the sleep timer immediately (→ 25). A long-press opens manual entry (→ 26).
- Note that 25a shows a chooser sheet; see Open questions.

**Log sheets**
- 23 / 23a "Bấm giờ thay vì nhập" → 23b / 23c timers.
- 23c "Xong · nhập lượng sữa" → amount entry (inferred: back to 23a, prefilled).

**Sleep**
- 25a: "Bắt đầu hẹn giờ" → 25; "Nhập giấc đã ngủ" → 26.
- 26: "Bắt đầu hẹn giờ" → 25.
- 25: "Sửa giờ bắt đầu" → time wheel (inferred).
- Saving a sleep or syncing that conflicts → 27 (27 appears only when sync detects an overlap).

**Growth (28)**
- "Xem tất cả" → 20d (inferred).
- LogRow → 21.

**History (20)**
- Row → 21.
- "Tháng 10" → 20f.
- Bú filter "Xem thống kê bú" → 20g / 20g2.
- Ngủ filter "Xem thống kê ngủ" → 20h.
- Empty-day "+ Ghi bù thay tã" → 24, preset to that day (inferred).
- "Xem tất cả ghi chép ngày …" → Tất cả filter for that day (inferred).
- 20d "+ Thêm số đo" → 28.

**Record detail (21)**
- "Sửa" → that record type's sheet, prefilled.
- "Xóa bản ghi" → action-sheet confirmation, then the toast "Đã xóa · Hoàn tác" (5 s).

**Widgets** (deep-link table 84:7023)
- Empty area / title → 19.
- "Sửa" → 22, prefilled.
- "Đổi loại" → 24, prefilled.
- Live Activity "Sửa giờ bắt đầu" → 25.
- Large "Gần đây" row → 21.
- Empty / signed-out → 18 / Sign in.

---

# Business rules confirmed by design (verbatim evidence)

## Today, logging and quick log
1. **Empty Today reuses the data layout. The coachmark ends after the first log. No streaks or goals.**
   - 29:904: "Trạng thái trống dùng cùng bố cục với Hôm nay có dữ liệu: thẻ giữ màu từng loại, giá trị “Chưa có / Chạm để ghi”. Coachmark tắt sau lần ghi đầu tiên. Không streak, không mục tiêu."
2. **One tap on a tile opens that type's log. Tiles show the last entry (how long ago · detail · who logged).**
   - 46:2266: "Thẻ lớn = vừa ghi vừa xem: chạm thẻ → mở sheet ghi mục đó (1 chạm); dòng dưới là lần cuối (bao lâu trước · chi tiết · ai ghi). Ngủ khi timer chạy → CareTile Tone=Active hiện thời gian đang chạy. Tăng trưởng: hàng riêng, + mở màn nhập số đo. “Lịch sử” → dòng thời gian."
3. **The "+" quick log maps one tap to a sheet. Sleep starts immediately; a long-press enters it manually.**
   - 50:3572: "Mở từ nút + ở dock. 1 chạm chọn mục → mở sheet ghi tương ứng (22/23/24, timer ngủ 25, tăng trưởng 28). Ngủ: nếu chưa có timer thì bắt đầu ngay, nhấn giữ để nhập thủ công."
4. **Today totals cover bottle (count + ml), breast (count + minutes), finished sleep and diaper count. A running sleep is not counted until it ends. Pumping and growth are not part of the totals.**
   - Component 48:409: "“Đã ghi hôm nay”: totals of what was logged today (bottle feeds + ml, breastfeeds + minutes, finished sleep, diaper changes) and a 24h strip in care colours. Running sleep is not counted until it ends."
5. **Bottle defaults.** Remember the last type, time = now, remember the last milk type. ml is optional, so a 2-tap save is possible. The keypad has a decimal comma and the Save button sits above it.
   - 46:3141: "Mặc định: Bú bình (nhớ loại lần trước), thời gian = bây giờ, loại sữa nhớ lần trước. Lượng ml không bắt buộc — có thể Lưu ngay (2 chạm). Bàn phím số có dấu phẩy; nút Lưu luôn nằm trên bàn phím."
6. **Breastfeeding.** Pick a side; the app remembers the last side and suggests the other. Duration is optional. The timer can be paused when switching sides.
   - 46:3234: "Bú mẹ: chọn bên (nhớ bên lần trước, gợi ý bên còn lại), thời lượng tùy chọn. “Bấm giờ” đổi ô thời lượng thành đồng hồ đếm, có thể tạm dừng khi đổi bên."
   - Stats hint: "Lần trước kết thúc bên phải → lần tới nên bắt đầu bên trái."
7. **Diaper is two taps.** The default is the last type. After saving, the Today tile bounces and shows a ✓.
   - 46:3308: "2 chạm: chọn loại → Lưu. Mặc định chọn loại lần trước. Sau khi lưu: tile Thay tã ở Hôm nay nảy nhẹ + dấu ✓, thẻ Lần cuối cập nhật."
8. **Choice controls remember the last choice.**
   - Segmented 9:124: "Remembers the last choice as the default."
   - ChoiceTile 45:386: "Remembers the last choice."
9. **Amounts are optional unless stated. Units are ml, kg, cm and phút, with tabular figures.**
   - AmountField 45:403: "Numeric amount (ml, kg, cm, phút) … Always optional unless stated."
   - Pump "Lượng sữa" and growth "Cân nặng" are not labelled optional; the others are labelled "· tùy chọn".
10. **Time defaults to now and is picked on a wheel.**
    - TimeRow 45:387: "Default = now; tap the chip to pick another time (wheel)."

## Timers, sleep and conflicts
11. **Timer behaviour.** Night care turns on automatically during the night schedule. The ring "breathes". Ending saves with a success haptic. Cancelling requires confirmation. The timer keeps running when the phone is locked, via Live Activity.
    - 47:3028 (also on 112:11135 and 113:11207): "Tự bật Night care khi timer chạy trong lịch đêm. Vòng “thở” (duration-breath). Kết thúc → lưu giấc ngủ, haptic success. “Hủy, không lưu” hỏi xác nhận. Timer tiếp tục khi khóa máy (Live Activity)."
12. **Running timers are visible to the whole family.**
    - Pill "Cả nhà đang thấy" on 25, 23b and 23c, and on the Live Activity header.
    - Sleep chooser: "Đồng hồ chạy, cả nhà cùng thấy".
13. **Users can switch between the timer and manual entry.**
    - 69:4237: "Đổi cách bất cứ lúc nào: từ đồng hồ có thể sửa giờ bắt đầu, từ nhập tay có thể chuyển sang hẹn giờ."
14. **Overnight sleep is split by day in the baby's timezone.**
    - 47:3074: "Giấc qua đêm được chia vào tổng của từng ngày theo múi giờ của bé (GMT+7)."
15. **Overlap resolution: the user picks one version; nothing is merged automatically. The unpicked version is soft-deleted for 30 days.**
    - 47:3145: "Chỉ hiện khi đồng bộ phát hiện 2 giấc ngủ chồng thời gian. Nút chính bị khoá (40% opacity) cho tới khi chọn một bản. Bản không chọn được giữ 30 ngày trong “Đã xoá gần đây”."
    - Copy: "Chọn bản đúng. App không tự gộp hay ghi đè."
    - Options: "Giữ bản đã chọn" / "Sửa tay từ bản của tôi".
16. **Pump double-pumping.** The two sides run at the same time and can be stopped separately.
    - "Hút đôi · chạm 1 bên để dừng riêng".
    - Ending: "Xong · nhập lượng sữa".

## Records, permissions and sync
17. **Visibility and edit rights.**
    - 46:2649: "Mọi người trong gia đình thấy bản ghi này. Chỉ người ghi hoặc chủ sở hữu được sửa."
    - Annotation: "Bản ghi của người khác: nút Sửa/Xóa ẩn nếu không có quyền."
18. **Delete flow:** confirmation, then a 5-second undo.
    - 46:2649: "Xóa: hỏi xác nhận bằng action sheet, sau đó hiện toast “Đã xóa · Hoàn tác” 5 giây."
19. **Sync status is always shown with an icon plus words. Pending saves survive an app restart.**
    - SyncStatus 8:84: "Pending (offline / waiting): sunshine-soft/pending, copy “Đã lưu trên máy này. Đang chờ đồng bộ.” … Pending saves must survive an app restart."
    - Labels seen: "Đã đồng bộ", "Cả nhà đang thấy", "Đã có mạng lại", "Chỉ trên máy này", and the "Chờ" row pill.
20. **Pending entries count in the totals.** Shown in 104:10130.
21. **Attribution appears everywhere.**
    - Rows read "<who> ghi"; the current user is "Bạn".
    - Detail screen: "Người ghi" = "Mẹ Mai (bạn)", plus "Ghi lúc" (the creation time, separate from the event time).
    - Timers: "<who> bắt đầu lúc HH:mm".

## Growth
22. **Growth shows no percentiles and no judgement; it only compares with the previous measurement. Units are kg/cm with a decimal comma.**
    - 47:3210: "Chỉ ghi và so sánh với lần trước — không bách phân vị, không đánh giá “tốt/xấu” (nguyên tắc: không suy luận y khoa). Đơn vị kg/cm, dấu phẩy thập phân."
    - The birth record is labelled "Lúc sinh".

## History and stats
23. **Timeline ordering and grouping.**
    - "Dòng thời gian mới nhất ở trên, chia theo buổi (Sáng/Trưa/Chiều/Tối). Giấc ngủ và bú mẹ là khối có thời lượng. Chạm mục → Chi tiết bản ghi. Lọc “Tăng trưởng” hiện các lần đo."
    - Periods: "Sáng (05–11) · Trưa (11–13) · Chiều (13–18) · Tối (18–22) · Đêm (22–05)".
24. **Filters.**
    - Chips: Tất cả · Bú · Hút sữa · Ngủ · Tã · Tăng trưởng.
    - Bú = bottle + breast. Pumping has its own chip.
    - Diaper "Cả hai" counts toward both Ướt and Bẩn.
25. **Date picker limits.**
    - "Chấm màu = ngày có ghi chép. Teddy sinh ngày 17 tháng 9, không chọn được ngày trước đó."
    - Future dates are disabled. Weeks start on Monday. A "Về hôm nay" button returns to today.
26. **Empty days offer back-logging.**
    - "Nếu quên ghi lúc đó, bạn có thể ghi bù với giờ của ngày này."
27. **Stats windows and day/night boundaries.**
    - Windows: "Hôm nay · 7 ngày · 30 ngày".
    - Day/night: "Ngày 06:00–18:00 · Đêm 18:00–06:00".
    - The feeding "Hôm nay" window is "Từ 18h hôm qua".

## Widgets
28. **Widget buttons log in the background; other taps open the app at the right screen.**
    - 76:5440: "Bấm = ghi ngay, widget hiện "Đã ghi · Hoàn tác" ~5 giây."
    - 84:6581: "Nút trên widget chạy ngầm (App Intent): app không mở, widget tự đổi trạng thái và hiện Hoàn tác ~5 giây. Chạm vùng khác của widget mới mở app đúng màn."
    - 73:401: "Ghi 1 chạm + hoàn tác (iOS 17 App Intents)."
29. **Medium widget tile defaults.**
    - 74:551: "Bottle = last amount, Breast/Sleep = start timer, Diaper = Wet".
30. **Widgets work offline.**
    - 84:7189: "Mất mạng: vẫn ghi được, bản ghi lưu trên máy và hiện “Chưa đồng bộ”. Khi có mạng sẽ tự gửi lên cho cả nhà."
31. **Live Activity.**
    - 75:576: "Live Activity on Lock screen for running Sleep / Breast timers. Buttons end or adjust without opening the app."
    - 76:5851: "Live Activity bú mẹ: đổi bên / kết thúc ngay trên màn khoá."
    - Dynamic Island, 76:5800: "Chạm giữ Dynamic Island để mở rộng. Thu gọn: icon trăng + thời gian; khi có 2 Live Activity: dạng Minimal."

---

# Entities & fields implied (care record types and their fields)

## Common to every CareRecord (inferred from the UI)
| Field | Evidence |
|---|---|
| `id`, stable client-generated op id | Offline "Chỉ trên máy này" plus idempotent sync (brief) |
| `babyId` | BabySwitcher: "Shows whose log you are viewing" |
| `type` ∈ {bottle, breast, pump, sleep, diaper, growth} | 6 tiles, 6 chips |
| `occurredAt` (start for span types) | TimeRow "Thời gian" / "Bắt đầu" |
| `endedAt` / `durationSec` (span types) | sleep, breast, pump |
| `createdBy` (memberId), shown with relationship label + name | "Mẹ ghi", "Người ghi: Mẹ Mai (bạn)" |
| `createdAt` | "Ghi lúc 14:22" (distinct from the event time 14:20) |
| `updatedAt` / revision | edit; overlap conflict detection |
| `syncState` ∈ {pending (local only), synced, error} | SyncStatus variants Synced / Pending / Error |
| `deletedAt` (soft delete; undo 5 s; "Đã xoá gần đây" for 30 days) | 46:2649, 47:3145 |
| `source` ∈ {app, widget, liveActivity, timer, manual} | widget / App Intent flows (inferred, for analytics and dedup) |
| `timezone` used for day bucketing = the baby's timezone | "theo múi giờ của bé (GMT+7)" |

## Per-type fields
| Type | Fields | Required? / defaults | Units / format |
|---|---|---|---|
| **Bottle (Bú bình)** | `amountMl?`; `milkType` ∈ {breastMilk "Sữa mẹ", formula "Sữa công thức"}; `occurredAt` | amount optional; milkType = last used; time = now | ml, integer (keypad allows a comma) |
| **Breastfeed (Bú mẹ)** | `side` ∈ {left "Trái", right "Phải", both "Cả hai"}; `durationMin?`; `startedAt`; per-side durations `leftSec`, `rightSec` (from the timer); `endSide` (last active side, drives "Lần trước kết thúc bên phải"); pauses (inferred) | side = suggested opposite of last `endSide`; duration optional | minutes ("15 phút"); timer mm:ss |
| **Pump (Hút sữa)** | `side` ∈ {Trái, Phải, Cả hai}; `amountMl` (optional per-side amounts via "Nhập riêng từng bên"); `durationMin`; `startedAt`; per-side stop times (double pump) | amount not marked optional; not counted as baby intake | ml, minutes |
| **Sleep (Giấc ngủ)** | `startedAt`, `endedAt` (null while running); computed duration; `isOvernight` (chip "Qua đêm") | — | "7 giờ 28 phút"; timer hh:mm:ss |
| **Diaper (Thay tã)** | `kind` ∈ {wet "Ướt", dirty "Bẩn", both "Cả hai"}; `occurredAt` | kind = last used | — |
| **Growth (Tăng trưởng)** | `measuredOn` (date "Ngày đo"); `weightKg` (required); `lengthCm?`; `isBirth` ("Lúc sinh"); computed delta vs previous | no head circumference | kg / cm, one decimal place, decimal comma |

## Running timer (session entity; separate from the record)
`ActiveTimer { babyId, type ∈ {sleep, breast, pump}, startedAt, startedBy, state ∈ {running, paused}, activeSide(s), perSideAccumulated, pausedAt?, liveActivityId? }`
- It is shared with the family ("Cả nhà đang thấy").
- Stopping it creates exactly one record (product plan: "Timer = running session; on stop creates record exactly once").
- "Hủy, không lưu" discards it.
- Start time is editable ("Sửa giờ bắt đầu").

## Other
- **SleepConflict** (inferred): `{recordA, recordB, detectedAt, resolvedBy?, keptRecordId}`. The losing record goes to the soft-delete bin for 30 days.
- **Widget state** (inferred, App Group): `lastBottleAmount`, last diaper kind, per-type latest-entry snapshot, pending queue count ("2 bản ghi chờ"), active timer snapshot, `undoToken` with a 5 s expiry.

---

# Computation rules for stats

All day bucketing uses the **baby's timezone** (rule 14).

## Today card "Đã ghi hôm nay" (DayRhythm, calendar day 00:00–24:00 of the selected day)
- Bottle: count · Σ ml.
- Breast: count · Σ minutes.
- Sleep: Σ duration of finished sleeps, clipped to the day. Running sleep is excluded.
- Diaper: count.
- Pump and growth are excluded.
- 24h strip: sleep and breastfeed as blocks, feeds and diapers as ticks, plus a "now" line.

## CareTile "when / detail / who" lines
- Bottle: last amount · "N phút trước" · "<who> ghi".
- Breast: duration · "Kết thúc X trước" (measured from the end) · who.
- Sleep: "Đã thức X" = now − last sleep end · "Dậy lúc HH:mm" · who. A running sleep shows live elapsed time instead (Tone=Active).
- Diaper: kind · relative time · who.
- Pump: ml · relative time · who.
- Growth: weight · length · "±Δ kg · <date>".

## Filtered history cards
- **"Cữ gần nhất"** = now − start of the last feed (bottle or breast).
- **"Cách nhau trung bình"** = mean gap between consecutive feed **start** times (bottle and breast combined) within the window. Example: 08:00 / 11:30 / 14:20 → 3 h 10.
- **Sleep card**
  - "Tổng đã ngủ" = clipped sum.
  - "Số giấc" = number of segments in the day.
  - "Giấc dài nhất" = longest clipped segment.
  - "Đang thức" = now − last sleep end ("2 giờ · từ 13:05").
- **Diaper card**
  - Tổng = count.
  - Ướt = wet + both.
  - Bẩn = dirty + both.
  - Gần nhất = now − last change.

## Feeding stats (20g / 20g2)
- **7 ngày / 30 ngày**
  - "TB mỗi ngày" ml = Σ bottle ml / days.
  - Average cữ per day = (bottle + breast) count / days.
  - "Cách nhau TB" = mean feed interval.
  - Day/night %: by ml, Ngày 06–18 vs Đêm 18–06. Each bucket shows ml and cữ.
  - Insight: last night's feed count and its longest gap with start–end times.
  - "Lượng sữa theo giờ": for each clock hour 0–23, the average bottle ml; the peak hour is called out.
  - Bú mẹ: average feeds per day, average minutes per feed, and the left/right share by time.
- **Hôm nay**
  - Window = 18:00 yesterday → now.
  - KPIs: total ml ("Từ 18h hôm qua"); feeds "N bình · M mẹ"; average interval.
  - Split "Đêm qua 18–06" vs "Hôm nay từ 06:00" by ml.
  - Per-feed chart for calendar day 0–24h: bottle bars with ml labels, breast shown as pink dots labelled with minutes, and a "Chưa tới" area after now.
  - Breast: count, total minutes, and left/right in minutes.

## Sleep stats (20h, 7 ngày)
- KPIs: "TB mỗi ngày" (total / days), sleeps per day, and the longest stretch in the window.
- Day/night split **by duration**, Đêm 18–06 vs Ngày 06–18. Each bucket shows the average duration per day and the min–max count range ("2–3 giấc").
- Insight: the trend of the longest night sleep across the window.
- "Nhịp ngủ 7 ngày": one row per day, split at midnight, with night shading 0–6 and 18–24.
- "Giấc dài nhất mỗi ngày": bars show the maximum stretch per day.
- In the mock, both are computed on segments split at midnight; see the open questions.

## Growth
- Delta = latest − previous measurement ("so với lần đo 1 thg 10").
- The chart is a line over time with a proportional x axis. Metric toggle: Cân nặng / Chiều dài.

## Formatting
- Decimal comma.
- Durations: "X giờ Y phút" in rows; "X giờ Y" in cards; "Xg Yp" in KPIs and widgets; "15p" as a chart label.
- Timers: "h:mm:ss" (sleep) and "mm:ss" (breast/pump); Dynamic Island compact uses "h:mm".
- Dates: "Thứ Năm, 8 tháng 10" (header), "d thg m" (short), "Hôm qua · 21:42" / "Hôm nay · 05:10" / "Bây giờ · 15:05" (time chips).
- Relative times: "Vừa xong", "45 phút trước", "1 giờ 25 phút trước".

---

# Native capabilities required (iOS shown; Android not designed)
- **Interactive home-screen widgets (WidgetKit).** systemSmall (10 types/states), systemMedium (Default / Logged / Offline), systemLarge. Buttons run as iOS 17 **App Intents**, and Undo is available for about 5 s.
- **Lock-screen widgets (WidgetKit).** accessoryCircular (Sleep, Feed), accessoryRectangular, accessoryInline.
- **Live Activities and Dynamic Island (ActivityKit).** For running Sleep and Breast timers. Actions: Thức dậy / Sửa giờ (sleep) and Đổi bên / Kết thúc (breast). Dynamic Island modes: compact, minimal and expanded.
  - Shared visibility across the family ("Cả nhà đang thấy") implies push updates. iOS 17.2+ push-to-start would be needed for other devices (inferred).
- **App Group shared storage** for the widget and app offline queue, kept across restarts ("Pending saves must survive an app restart").
- **Background sync with reconnect detection.** Needed for "Đã có mạng lại" and for the overlap detection on sync.
- **Haptics.** Success haptic when a timer ends; a small bounce on the tile after saving.
- **System decimal keypad** with a comma ("system keypad in production") and a **time/date wheel picker**.
- **Night care auto-switch** when a timer runs inside the night schedule.
- **Reduce Motion.** The breathing ring turns static.
- **Android equivalents** (Glance app widgets, ongoing-notification timers) are **not designed** → open question.

---

# Open questions / gaps

## A. Today, quick log and entry points
1. **Quick-log sleep conflict (50:3572 vs 69:4213).** 19a says tapping "Ngủ" starts the timer immediately and a long-press opens manual entry. Yet 25a shows a chooser sheet ("Bắt đầu hẹn giờ" / "Nhập giấc đã ngủ"), and its frame annotation is a copy of 19a's. Which entry point shows the chooser: the Giấc ngủ CareTile, the "+" sheet, or both? What does "Ngủ" do when a timer is already running?
2. **QuickLogButton description is stale (44:363).** It lists 4 types "(Bú · Ngủ · Tã · Tăng trưởng)", but the sheet shows 6, including Hút sữa. The sheet is assumed authoritative.
3. **Relative-time format is inconsistent.**
   - Forms seen: "45 phút trước", "1h 25p trước" (19 override), "1 giờ 25 phút trước" (component default), "Kết thúc 3 giờ 35 phút trước", and widget "3g 35p".
   - Decide the canonical formats per surface.
   - Also decide the threshold between "Vừa xong" and minutes.
4. **Running-sleep CareTile (Tone=Active / "Sleep running").** It exists as a component variant (54:530 Type=Sleep running) but is not shown on a section-5 frame. Its exact copy needs reading from Components.
5. **Night care toggle (moon icon on Today).** The tap behaviour (manual override versus schedule) is not annotated here; see Foundations 13 / 13a.

## B. Logging and timers
6. **Copy-pasted annotations.**
   - 23b and 23c carry the sleep-timer annotation ("Kết thúc → lưu giấc ngủ"); 23a carries the breastfeed annotation.
   - Confirm that pump and breast timers also turn Night care on automatically and continue under a Live Activity. Note there is no pump Live Activity or Dynamic Island component.
7. **Pump timer → amount.** "Xong · nhập lượng sữa": the amount-entry step after stopping is not designed. Is it 23a prefilled with the duration?
   - The expanded state of "Nhập riêng từng bên" (per-side ml) is not designed either.
8. **Breast timer pause/resume.** The "Tạm dừng" button exists, but the paused state (label, Live Activity) is not designed.
   - The default starting side in the widget ("Bên trái") versus the "suggest opposite" rule.
   - Whether per-side durations are stored when switching sides from the widget or Live Activity.
9. **Unit choices.** Only ml, kg and cm are shown; no oz/lb. Is a unit setting needed?
   - Validation ranges (max ml, plausible kg/cm, max sleep length, end before start, future times) are not designed. Neither are validation error states.
10. **Bottle "Bú bình · Sữa mẹ" detail hero.** When the amount is empty, what does the hero, tile and widget show?
11. **Edit flow for each type.** The "Sửa" destination (sheet prefilled) is inferred. The edit-mode copy (title, "Lưu thay đổi"?) is not designed. Nor is the hidden-button state for a member without permission.
12. **Delete confirmation.** The action-sheet copy (title and buttons) is not designed. The "Đã xóa · Hoàn tác" toast is.
13. **"Đã xoá gần đây" (Recently deleted, 30 days).** It is referenced by 47:3145, but no screen for it is in this section. Where does it live, and who can restore?
14. **Overlap detection scope.** It is "only when sync detects". Should a local manual entry that overlaps an existing synced sleep also be blocked or warned at save time? Can overlaps happen for breast or pump?
    - With 3+ overlapping sleeps, does the resolver handle it?
    - If both versions are on the server (two online devices), what happens?

## C. History and stats (details in Part C)
15. **Midnight-crossing sleep.**
    - Totals are clipped per day (confirmed by 47:3074).
    - Should the row show the full duration (8 h 48) or the clipped part (6 h 30, as mocked), and should the time column show 00:00?
    - Should "Giấc dài nhất" use full uninterrupted sleeps or midnight-split pieces?
16. **Two different day/night boundaries:**
    - History period headers: Đêm 22–05, with Sáng/Trưa/Chiều/Tối.
    - Stats: 06–18 / 18–06.
    - Feeding stats "Hôm nay" window: 18:00 yesterday → now.
    - History "hôm nay": calendar day.
    - Confirm all four are intended.
17. **Mock data does not reconcile** between 20 / 20a and 20g2 (night bottle feeds at 00:20 and 04:00 appear only in stats). The 7-day ratio bar is drawn 50/50 despite the 62/38 label, and the hourly bars disagree with that 62/38 ml split.
18. **Undesigned stats views.**
    - Feeding and sleep stats for "30 ngày".
    - Sleep stats for "Hôm nay".
    - Pumping filter or stats, and diaper stats.
    - Summary card copy for past days.
    - Empty states for filters other than Tã, and an all-empty day.
    - Loading and error states, and sync-error rows.
19. **Visual truncation bugs:**
    - The "Gần nhất" value in the Tã card (104:10130).
    - The growth date column (105:9063).

## D. Widgets (details in Part D)
20. **Multi-baby widget configuration.** All widgets show "Teddy", and there is no baby picker.
21. **No undo for timer start/stop** from widgets.
22. **No Breast Dynamic Island.** Behaviour when Sleep and Breast run at the same time.
23. **States not designed:**
    - Permission lost or revoked.
    - Signed in but no baby.
    - Live Activities disabled.
    - Medium/Large in Empty or Signed-out states.
    - Pending on Small.
24. **Lock-screen accessory semantics.** What the progress ring means, and the tap targets for the lock-screen accessories.
25. **Android equivalents** for all of Part D are not designed. A decision is needed (brief: "explain OS constraints and propose a solution").
26. **Whether the widget follows the app's Night care schedule or the system appearance.**

## E. Permissions
27. **Caregiver edit rights.**
    - 46:2649 says "Chỉ người ghi hoặc chủ sở hữu được sửa" (only the creator or the owner can edit). The product plan says a caregiver can edit only their own records.
    - Can a co-parent who is not the owner edit another member's records? The footer says only the creator or the owner can.
    - Which member is the "chủ sở hữu" (owner)?
