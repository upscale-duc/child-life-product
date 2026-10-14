# Apple Watch (W01 – W14): spec extracted from final Figma

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only), page **"Apple Watch"** (canvas `464:18`), read 2026-10-12. No Figma node was modified.

**Method.** `get_metadata` ×1 on the canvas `464:18`, `get_screenshot` ×1 on the canvas (`img/watch/464-18_canvas.png`, 2028 × 667). No `get_design_context` yet, so **colours below are read from the screenshot, not from tokens**; re-read each frame with `get_design_context` before building it. Strings are the text-layer contents from the metadata, checked against the screenshot (the W13 banner layer name is cut at 30 characters; its full text is read from the screenshot). Glosses in parentheses are engineering drafts.

**Device.** Every frame is **208 × 248 pt**, the 46 mm Apple Watch Series 10 / 11 screen. Content keeps a 10 pt side inset (188 pt column). Nothing is drawn for 41 / 42 / 45 mm or Ultra (49 mm).
**Theme.** Black background throughout (watchOS). W04 tints the whole screen deep indigo while the baby sleeps; W11 is the night variant in dim red. There is no Light variant (a watch app is always dark).
**Annotations.** None. The only design notes are the two row labels and the caption inside W11.
**Mock data.** Teddy (7 tháng on W12) and Na (3 tuổi); the user is "Mẹ"; the clock reads 9:41 / 10:09 / 17:02.

## Frame list

| Row | x | Node | Name | Content height | Screenshot |
|---|---|---|---|---|---|
| label | 0, y −60 | 464:19 | **"1 · Ghi nhanh trên cổ tay"** (Quick logging on the wrist) | — | — |
| 1 | 0 | 464:20 | W01 · Hôm nay | 298 (scrolls) | canvas |
| 1 | 260 | 464:61 | W02 · Bú bình · chọn lượng | 207 | canvas |
| 1 | 520 | 464:85 | W03 · Bú mẹ · đang bấm giờ | 176 | canvas |
| 1 | 780 | 464:104 | W04 · Ngủ · đang ngủ | 212 | canvas |
| 1 | 1040 | 464:118 | W05 · Thay tã | 187 | canvas |
| 1 | 1300 | 464:140 | W06 · Đã lưu | 211 | canvas |
| label | 0, y 300 | 465:49 | **"2 · Không cần mở app"** (No need to open the app) | — | — |
| 2 | 0 | 465:50 | W07 · Nhắc bú · thông báo | 211 | canvas |
| 2 | 260 | 465:64 | W08 · Ghi bằng giọng nói | 227 | canvas |
| 2 | 520 | 465:78 | W09 · Mặt đồng hồ · complication | 192 | canvas |
| 2 | 780 | 465:96 | W10 · Smart Stack | 177 | canvas |
| 2 | 1040 | 465:123 | W11 · Ban đêm | 213 | canvas |
| 2 | 1300 | 465:142 | W12 · Chọn bé | 161 | canvas |
| 2 | 1560 | 465:164 | W13 · Chưa có mạng | 147 | canvas |
| 2 | 1820 | 465:180 | W14 · Hút sữa · chạm 2 lần để dừng | 202 | canvas |

## Shared chrome

- **Top** row (188 × 25, or 28 with a back button): title left (baby name on home screens, the care type on flows, tinted in the care colour), spacer, clock "9:41" right (system time).
- **Back** (W02, W05): 22 pt circle with `Icon/back` 12, before the title.
- Buttons: full-width pills 188 × 39 – 41 (two-up: 91 × 36 – 39, gap 6). Primary pills are filled in the care colour; secondary pills are dark grey.
- Icons reused from the app set: `Icon/feed`, `Icon/drop`, `Icon/sleep`, `Icon/diaper`, `Icon/check`, `Icon/back`, `Icon/clock`, `Icon/cloud-off`, `Icon/retry`; the Nhắc tile uses a layer named `Icon/ruler` that renders as a reminder glyph (stale layer name).
- Care colours as seen: Bú bình blue, Bú mẹ pink, Ngủ indigo / lilac, Tã green, Hút sữa purple, Nhắc orange (to be mapped onto the `care-*` tokens).

## Row 1 · Ghi nhanh trên cổ tay

### W01 · Hôm nay `464:20`
- Top: "Teddy" · "9:41".
- 2-column grid of **6 tiles** (91 × 79, gap 6), each: 21 pt icon chip + label in the care colour, a large value (elapsed h:mm), a caption.
  - Bú bình · "2:15" · "từ cữ trước" (since the last feed)
  - Bú mẹ · "3:35" · "từ cữ trước"
  - Ngủ · "0:42" · "đang ngủ" (sleeping) — **running state: the tile is filled indigo**
  - Tã · "1:25" · "từ lần trước" (since last time)
  - Hút sữa · "5:10" · "từ lần trước"
  - Nhắc · "17:00" · "nhắc bú" (feed reminder) — the next reminder, not an elapsed time
- The third row (Hút sữa, Nhắc) is below the fold: the screen scrolls (Digital Crown).
- Tap targets (inferred): Bú bình → W02, Bú mẹ → W03, Ngủ → W04, Tã → W05, Hút sữa → W14, Nhắc → not drawn.

### W02 · Bú bình · chọn lượng `464:61`
- Top: back · "Bú bình" (blue) · "9:41".
- Amount "120" (large, ~44 pt), caption "ml · xoay núm để chỉnh" (ml · turn the crown to adjust).
- Quick picks: "90" · **"120" (selected, blue)** · "150" (60 × 28 pills).
- Primary "Lưu" (Save) with `Icon/check`, blue, full width.
- A 4 × 36 blue bar at the right edge (x 202, y 80): the Digital Crown focus indicator.
- Inferred: the amount is prefilled from the last bottle (as the app's sheet, 16-v1-improvement), the picks come from the reference data `bottle.quickPicks` (P-138); saving shows W06.

### W03 · Bú mẹ · đang bấm giờ `464:85`
- Top: "Bú mẹ" (pink) · "9:41" (no back while running).
- Two side cards (91 × 56): **"Trái" "8:12" (filled pink = the side running)** · "Phải" "4:20" (dark).
- Caption "Tổng 12:32 · đang bú bên trái" (Total 12:32 · feeding on the left).
- Buttons: "Đổi bên" (Switch side, dark) · "Dừng" (Stop, red).
- Not drawn: the start screen (pick a side; the app remembers the last side and suggests the other), pause, cancel, edit start time.

### W04 · Ngủ · đang ngủ `464:104`
- Whole screen tinted deep indigo. Top: "Ngủ" (lilac) · "9:41".
- Ring 110 pt (track + progress ellipse) with "0:42" (~30 pt) and "từ 13:05" (since 13:05).
- Primary "Bé đã dậy" (Baby woke up), indigo, full width.
- Not drawn: starting a sleep from the watch, edit start, cancel, Always-On.

### W05 · Thay tã `464:118`
- Top: back · "Thay tã" (Diaper change, green) · "9:41".
- Three full-width buttons (188 × 41): "Ướt" (Wet, `Icon/drop`) · "Bẩn" (Dirty, `Icon/diaper`) · "Cả hai" (Both, `Icon/check`).
- Inferred: one tap saves at "now" and shows W06.

### W06 · Đã lưu `464:140`
- Green circle 58 with `Icon/check` 30.
- "Đã ghi tã ướt" (Wet diaper logged), "10:24 · Mẹ ghi" (10:24 · logged by Mẹ, R-022).
- Secondary "Hoàn tác" (Undo), 188 × 32.
- Not drawn: how long Undo stays (the widgets use ~5 s, R-100w), the auto-return to W01.

## Row 2 · Không cần mở app

### W07 · Nhắc bú · thông báo `465:50`
- A notification long look: app row `Icon/clock` in a teal circle + "CHILD LIFE".
- Title "Đến giờ nhắc bú bạn đã đặt" (Time for the feed reminder you set).
- Body "Cữ trước 14:45 · 120 ml" (Last feed 14:45 · 120 ml).
- Actions: **"Ghi bú bình 120 ml"** (Log a 120 ml bottle, blue) · "Nhắc lại sau 15 phút" (Remind me again in 15 minutes, dark).

### W08 · Ghi bằng giọng nói `465:64`
- Quoted utterance: "\"Ghi bú bình 120 ml cho Teddy\"" (Log a 120 ml bottle for Teddy).
- Confirmation card (188 × 95): `Icon/feed` in a blue circle, "Bú bình · 120 ml", "Teddy · 17:02".
- Buttons "Huỷ" (Cancel) · "Lưu" (Save, blue).
- Not drawn: whether this is Siri or in-app dictation, misheard / unparsed speech, a missing amount.

### W09 · Mặt đồng hồ · complication `465:78`
- A watch face with two Child Life complications:
  - **Circular** (42 pt): `Icon/feed` over "2:15" (time since the last feed).
  - **Rectangular** (188 × 48): `Icon/sleep` + "Teddy đang ngủ" (Teddy is sleeping, lilac), then "0:42 · cữ bú tiếp ~ 17:00" (0:42 · next feed ~17:00).
- Face date "T5 8" and time "10:09" are the system's.
- Note: the rectangular complication **shows the baby's name on the watch face** (always visible), unlike the generic lock-screen copy of R-116 / R-120.

### W10 · Smart Stack `465:96`
- System time "10:09" top right; one widget card (188 × 91, dark teal): "Teddy" · "Child Life", then three columns `Icon/feed` "2:15" · `Icon/diaper` "1:25" · `Icon/sleep` "0:42"; page dots below (3).

### W11 · Ban đêm `465:123`
- Same top as W01, **everything in dim red on black**.
- A list instead of tiles (188 × 44 rows): "Bú bình" "2:15 trước" · "Bú mẹ" "3:35 trước" · "Tã" "1:25 trước" (… ago).
- Caption inside the frame: "Màu đỏ dịu, không làm chói mắt" (Soft red, not glaring) — reads as a designer note, not UI (inferred).
- Not drawn: Ngủ / Hút sữa / Nhắc rows, how night mode turns on (inferred: the baby's Night care schedule, 13a), what a row tap does.

### W12 · Chọn bé `465:142`
- Top: "Chọn bé" (Choose baby) · "9:41".
- Rows (188 × 53): avatar letter "T" (peach) "Teddy" "7 tháng" **selected (teal row + `Icon/check`)**; "N" "Na" "3 tuổi".
- Not drawn: how W12 is opened from W01 (inferred: tapping the baby name in the top row).

### W13 · Chưa có mạng `465:164`
- Top as W01. Banner (olive / sunshine, `Icon/cloud-off`): "Đã lưu trên đồng hồ. Sẽ gửi lên khi có mạng." (Saved on the watch. Will be sent when there is a connection.)
- Row `Icon/retry` "3 lần ghi chờ gửi" (3 entries waiting to send).

### W14 · Hút sữa · chạm 2 lần để dừng `465:180`
- Top: "Hút sữa" (purple) · "9:41".
- Timer "14:08" (~40 pt), "cả hai bên" (both sides).
- Hint pill "Chạm 2 lần ngón tay để dừng" (Double-tap your fingers to stop) — the watchOS Double Tap gesture.
- Primary "Dừng · nhập ml" (Stop · enter ml), purple.
- Not drawn: start (single / double pump), the ml entry after stopping (inferred: W02's layout in purple).

## Gaps (not drawn anywhere)
1. Linking the watch to the account (first run, phone signed out, signed-in account changed, signed out on the phone).
2. Empty states (no record yet, no baby, caregiver whose access expired, relative who cannot log).
3. Start screens for Bú mẹ (side), Ngủ, Hút sữa (single / double); edit start time; cancel a timer.
4. A timer started on another device (the family sees it, `activeTimers`) and stopping it from the watch.
5. Save failure, sleep overlap conflict (R-075), permission denied.
6. Undo window and return to W01.
7. Smaller screens (41 / 42 / 45 mm) and the largest Dynamic Type sizes.
8. Always-On (wrist down) for W03 / W04 / W14.
9. Complication families other than circular / rectangular (corner, inline) and their privacy.
10. English copy (engineering draft, D-012).
