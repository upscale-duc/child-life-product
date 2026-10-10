# Child Life: Motion spec (spec extracted from final Figma)

- **Source:** Figma file `sJLG1fAXKDnDr9YI6Yx8ex`, frame **Motion spec (269:19)**, 1760×6628.
  - Read-only extraction on 2026-10-10.
  - Tools: `get_metadata`, plus `get_design_context` on every child section.
- **Text is verbatim.** Every Vietnamese string below is copied exactly from the rendered text. An English gloss follows in *italics*.
- **Numbers marked "(measured)"** come from layer geometry or opacity in the keyframe illustrations, not from written text. Written text always wins where the two disagree.
- **Notation:**
  - "(inferred)" = not stated in Figma.
  - ⚠ = an inconsistency that needs a decision.
- **Keyframe data:** none in Figma.
  - `get_motion_context` (recursive) on 269:19 returned `{"nodes":[]}`.
  - The same call on pattern 270:108 also returned `{"nodes":[]}`.
  - All motion is described as static keyframe storyboards plus text. There are no Smart Animate, prototype or keyframe tracks.
- **Relation to earlier extracts:** this frame answers open question #1 in `07-foundations-components-motion.md` (motion durations were undefined).
  - The names differ, though. Component descriptions use `duration-tap/quick/base/breath/slow`. This frame uses `motion.instant/quick/standard/exit/gentle`.
  - See §6 for the reconciliation.

Section order in the frame:

1. Header (269:20)
2. Principles (269:25)
3. Tokens (269:41)
4. Patterns (270:18): P1–P10 + Ambient rules
5. Rules (271:463)

---

## 1. Header (269:20)

| Node | Text (verbatim) | Gloss |
|---|---|---|
| 269:21 (eyebrow pill, mint-soft) | Design system · Motion | *Design system · Motion* |
| 269:23 (H1 56/Bold) | Chuyển động trong Child Life | *Motion in Child Life* |
| 269:24 (lead 20/Medium) | Một bộ quy tắc chung để app trên iOS và Android cùng mượt, cùng nhịp. Chuyển động giúp ba mẹ hiểu chuyện gì vừa xảy ra — không để trang trí. | *A shared rule set so the app on iOS and Android is equally smooth and on the same rhythm. Motion helps parents understand what just happened — not for decoration.* |

## 2. Principles (269:25)

There are three cards, numbered 01–03.

| # | Title (verbatim) | Body (verbatim) | Gloss |
|---|---|---|---|
| 01 | Phản hồi ngay | Mọi lần chạm có phản hồi trong 100ms — nút co lại, rung nhẹ. Ba mẹ đang bế con cần biết chắc đã ghi xong. | ***Immediate feedback.*** *Every tap gets feedback within 100 ms: the button shrinks and there is a light vibration. Parents holding a baby need to know for sure the log was saved.* |
| 02 | Có chủ đích | Chuyển động chỉ để nói: cái gì vừa mở, nó đến từ đâu, đã lưu chưa. Không có hiệu ứng chỉ để đẹp. | ***Purposeful.*** *Motion only communicates three things: what just opened, where it came from, and whether it saved. No effect exists just to look nice.* |
| 03 | Dịu vào ban đêm | Night care bỏ hiệu ứng nảy, rút ngắn thời gian, không chớp sáng. Tôn trọng cài đặt "Giảm chuyển động" của máy. | ***Gentle at night.*** *Night care drops the bounce effect, shortens durations and never flashes. Respect the device's "Reduce Motion" setting.* |

## 3. Motion tokens (269:41)

- **Section heading (269:42):** "1 · Motion token"
- **Subheading (269:43):** "Dùng tên token trong code thay cho số cứng. Đổi một chỗ, cả app đổi theo." *(Use token names in code instead of hard-coded numbers. Change it in one place and the whole app follows.)*

### 3.1 Token cards (269:45)

Each card shows a curve diagram, the token name (mono), the duration, the curve label, the usage, and iOS/Android code lines. The code lines are verbatim.

| Token | Duration | Curve (verbatim label) | Usage (verbatim + gloss) | iOS (verbatim) | Android (verbatim) |
|---|---|---|---|---|---|
| `motion.instant` | **100 ms** | Ease out · (0.2, 0, 0, 1) | Nhấn nút, công tắc, phản hồi khi chạm *(button press, switches, touch feedback)* | `.easeOut(duration: 0.1)` | `tween(100, FastOutSlowIn)` |
| `motion.quick` | **200 ms** | Ease out · (0.2, 0, 0, 1) | Hiện/ẩn chip, đổi tab con, thông báo nhỏ *(show/hide chips, switch sub-tabs, small notices)* | `.easeOut(duration: 0.2)` | `tween(200, FastOutSlowIn)` |
| `motion.standard` | **~350 ms** | Spring · nảy rất nhẹ *(spring, very slight bounce)* | Mở sheet, chuyển màn, mở ảnh toàn màn hình *(open sheet, screen transition, open full-screen photo)* | `.spring(response: 0.35, dampingFraction: 0.86)` | `spring(dampingRatio = 0.86f, stiffness = 380f)` |
| `motion.exit` | **250 ms** | Ease in · (0.4, 0, 1, 1) | Đóng sheet, đóng ảnh, ẩn thông báo *(close sheet, close photo, hide notice)* | `.easeIn(duration: 0.25)` | `tween(250, FastOutLinearIn)` |
| `motion.gentle` | **600 ms** | Ease out mềm · (0.3, 0, 0, 1) *(soft ease out)* | Thiệp câu chuyện, mốc kỷ niệm, màn chào *(story cards, milestones, welcome screen)* | `.easeOut(duration: 0.6)` | `tween(600, EaseOutQuart)` |

**Flutter mapping (inferred, not in Figma).** The project is Flutter.

| Token | Duration | Flutter curve / simulation |
|---|---|---|
| instant | `Duration(milliseconds: 100)` | `Cubic(0.2, 0, 0, 1)` (= `Easing.standard` in Material 3) |
| quick | 200 ms | `Cubic(0.2, 0, 0, 1)` |
| exit | 250 ms | `Cubic(0.4, 0, 1, 1)` (= `Easing.legacyAccelerate`) |
| gentle | 600 ms | `Cubic(0.3, 0, 0, 1)` |
| standard | — | `SpringDescription.withDampingRatio(mass: 1, stiffness: ≈322–380, ratio: 0.86)` |

- **Spring stiffness range.** iOS `response 0.35` converts to stiffness ≈ (2π/0.35)² ≈ 322. Android uses 380, which is response ≈ 0.32 s. The two values are close but not identical. ⚠ Pick one.
- **Spring overshoot.** ζ = 0.86 gives ≈ 0.5% overshoot. That is consistent with "nảy tối đa 4px" *(max 4 px bounce)* in P2.

**⚠ Platform snippets do not exactly match the stated bezier values.** The bezier label should be the source of truth.

- **instant / quick.** The label is (0.2, 0, 0, 1). But iOS `.easeOut` is (0, 0, 0.58, 1) and Android `FastOutSlowIn` is (0.4, 0, 0.2, 1).
- **gentle.** The label is (0.3, 0, 0, 1). But Android `EaseOutQuart` is ≈ (0.25, 1, 0.5, 1) and iOS `.easeOut` is (0, 0, 0.58, 1).
- **exit.** Android `FastOutLinearIn` = (0.4, 0, 1, 1) matches. iOS `.easeIn` (0.42, 0, 1, 1) is close.

### 3.2 Extra rules (269:111)

| Card (verbatim title) | Value (verbatim) | Gloss |
|---|---|---|
| Khoảng dịch | Chuyển màn: 30% chiều rộng · Thông báo: 24px · Chip: 8px | ***Translation distance.*** *Screen transition: 30% of width · Toast: 24 px · Chip: 8 px* |
| Tỉ lệ khi nhấn | Nút, ô ghi nhanh: 0.96 · Thẻ ảnh: 0.98 | ***Press scale.*** *Buttons and quick-log tiles: 0.96 · Photo cards: 0.98* |
| Lớp mờ nền (scrim) | 0 → 32% trong motion.standard | ***Scrim.*** *0 → 32% opacity over motion.standard* |
| Nhiều phần tử | Xuất hiện lần lượt, mỗi phần tử cách 30ms, tối đa 6 phần tử | ***Multiple elements.*** *Appear one after another, 30 ms apart, maximum 6 elements (stagger)* |

⚠ **Press scale conflict.** The Button component description (8:33) says "Press: scale 0.97 in duration-tap". The motion spec says buttons are **0.96**.

- QuickAction (9:35) already says 0.96.
- Recommendation: follow the motion spec (0.96) and update the Button description.

---

## 4. Patterns (270:18)

- **Section heading (270:19):** "2 · Mẫu chuyển động" *(Motion patterns)*
- **Subheading (270:20):** "Mỗi mẫu gồm các khung hình chính, thời điểm và token dùng. Dev dựng theo đúng thứ tự này." *(Each pattern lists the key frames, their timing and the tokens used. Dev builds them in exactly this order.)*

**Card structure.** Every pattern card has:

- An info column: the P-number, the title, a trigger/scope sentence, token chips, and a "Rung" *(Haptic)* box.
- 3–4 keyframe illustrations. Each has a mono timing label and a caption.

**Shared art.** Phone mockups use scrim colour `#0a1a1c`. Toasts and tooltips use bg `#163d44`.

### P1 · Lưu một lần ghi *(Save a log entry)* — 270:22

- **Trigger (verbatim):** "Bấm "Lưu" trong sheet ghi bú, ngủ, tã — hoặc chạm nút + trên widget." *(Press "Save" in the feed/sleep/diaper log sheet — or tap the + button on the widget.)*
- **Tokens:** `instant` · `exit` · `standard` · `quick`
- **Haptic (verbatim):** "Nhẹ khi chạm · "Thành công" khi lưu xong" *(Light on tap · "Success" when the save completes)*
- **Applies to:** BottomSheet/Feed and the other log sheets; the widget + button; CareTile on Today ("Hôm nay").

**Sequence:**

| Key | Timing label | Caption (verbatim) | Gloss | Measured details |
|---|---|---|---|---|
| 1 | 0 ms | Nhấn nút Lưu: co lại 0.96 | Press Save: scales to 0.96 | Button "Lưu cữ bú" *(Save feed)* with a 64 px touch-ripple ellipse over it. `instant`. |
| 2 | 100 → 350 ms | Sheet trượt xuống (exit), nền sáng lại | Sheet slides down (exit), background brightens again | Scrim 15% (measured, fading from 32%). Sheet shown with a 25%-opacity ghost 30 px above it. `exit` 250 ms starts at 100 ms. |
| 3 | 350 ms | Thông báo trượt lên 24px, tự ẩn sau 4 giây | Toast slides up 24 px, auto-hides after 4 s | Toast "Đã ghi · Bú bình 120 ml" *(Logged · Bottle 120 ml)* + "Hoàn tác" *(Undo)*. Pill `#163d44`, check circle `#59ccb8`, undo text `#8ce5cc`. |
| 4 | 400 ms | Ô trên Hôm nay cập nhật số, viền sáng nhẹ rồi tắt | The tile on Today updates its number; border glows softly then fades | CareTile "Bú bình / 120 ml / 45 phút trước / Mẹ ghi" *(Bottle / 120 ml / 45 min ago / logged by Mom)* with a 3 px `#179487` highlight border (measured). |

- **Toast entry curve:** slides up 24 px; the token is presumably `standard` or `quick` (inferred).
- **Toast dismiss:** `exit`.
- **Reduce Motion (Rules table):** "Thông báo mờ dần, không trượt" *(the toast fades, doesn't slide)*.
- **Night care (Rules table):** "Như bình thường, thông báo nền tối, không viền sáng" *(as normal, dark toast, no glow border)*.
- **Not animated:** none stated.
- **Do / don't:**
  - Do confirm the save with haptic + ✓ + toast.
  - In Night care, don't do the tile border glow.
- ⚠ **Undo window conflict.** The toast hides after **4 s** here. `07-foundations-components-motion.md` records the widget "Đã ghi · Hoàn tác" as visible ~**5 s**. Reconcile.

### P2 · Mở và đóng sheet *(Open and close a sheet)* — 270:108

- **Trigger (verbatim):** "Chạm ô ghi nhanh, nút + hoặc ••• để mở. Kéo xuống hoặc chạm nền mờ để đóng." *(Tap a quick-log tile, the + button or ••• to open. Drag down or tap the scrim to close.)*
- **Tokens:** `standard` · `exit`
- **Haptic (verbatim):** "Không rung khi mở · Nhẹ khi đóng bằng kéo" *(No haptic on open · Light when closed by dragging)*
- **Applies to:** all bottom sheets (BottomSheet/Feed, quick-log, ••• action sheets).

**Sequence:**

| Key | Timing | Caption (verbatim) | Gloss | Measured |
|---|---|---|---|---|
| 1 | 0 ms | Nền mờ 0%, sheet nằm dưới màn | Scrim 0%, sheet below the screen | — |
| 2 | 120 ms | Sheet lên 60%, nền mờ 16% | Sheet 60% up, scrim 16% | Scrim opacity 0.16 |
| 3 | 350 ms | Dừng ở vị trí, nảy tối đa 4px | Settles in place, bounce max 4 px | Scrim 0.32. Grabber 38×4. Content: 3 care chips (bottle/breast/sleep soft colours). |
| 4 | Kéo xuống *(Drag down)* | Kéo quá 30% hoặc vuốt nhanh thì đóng (exit 250ms); chưa đủ thì bật về | Drag past 30% or flick fast → closes (exit 250 ms); otherwise springs back | Scrim 0.20 while dragging, so the scrim tracks the drag. |

- **Open:** `standard` spring + scrim 0 → 32%.
- **Close:** `exit` 250 ms (0.4, 0, 1, 1).
- **Dismiss threshold:** 30% of sheet height, or a fast fling. The velocity threshold is not specified (inferred: platform default).
- **Reduce Motion:** "Mờ dần 150ms, không trượt" *(fade 150 ms, no slide)*.
- **Night care:** "Không nảy, 250ms ease-out" *(no bounce, 250 ms ease-out)*.
- **Do / don't:** don't vibrate on open.

### P3 · Mở ảnh toàn màn hình *(Open photo full-screen)* — 270:175

- **Trigger (verbatim):** "Chạm ảnh trong nhật ký, lưới ảnh hoặc album. Vuốt xuống để đóng." *(Tap a photo in the journal, photo grid or album. Swipe down to close.)*
- **Tokens:** `standard` · `exit`
- **Haptic (verbatim):** "Không rung" *(No haptic)*
- **Applies to:** Memories/journal, photo grid (MediaTile), album (shared-element / hero transition).

**Sequence:**

| Key | Timing | Caption (verbatim) | Gloss | Measured |
|---|---|---|---|---|
| 1 | 0 ms | Ảnh nằm trong lưới | Photo sits in the grid | 3×2 grid of 58 px tiles, r8. The tapped tile has a 3 px `#179487` border. |
| 2 | 150 ms | Ảnh phóng to từ đúng vị trí, nền tối dần | Photo zooms from its exact position; background darkens | Black scrim 50%. Photo at 160×150, r10. |
| 3 | 350 ms | Toàn màn hình, nền đen, hiện thanh thao tác | Full screen, black background, action bar appears | Bg `#050505`. Photo full width, no radius. Action bar `rgba(255,255,255,0.08)`, 36 px tall. |
| 4 | Vuốt xuống *(Swipe down)* | Ảnh thu nhỏ theo tay, nền nhạt dần; thả tay sau 100px thì thu về lưới | Photo shrinks with the finger, background fades; release after 100 px → returns to the grid | Scrim 35%. Photo 140×120, r12 (corner radius grows back). |

- **Open:** `standard` spring. Corner radius animates 8 → 0 (measured).
- **Close:** `exit`, back to the original grid cell. Dismiss threshold is **100 px**.
- **Reduce Motion:** "Mờ dần chéo 200ms" *(crossfade 200 ms)*.
- **Night care:** "Nền tối sẵn, thời gian ngắn hơn 20%" *(background already dark, duration 20% shorter)*.
  - Inferred: ~280 ms spring-equivalent and exit 200 ms.
- **Do / don't:** zoom from the exact source position; no haptic.

### P4 · Thanh tab nổi khi cuộn *(Floating tab bar on scroll)* — 270:296

- **Scope (verbatim):** "Áp dụng cho thanh Nhật ký · Ảnh · Album · Câu chuyện và thanh menu dưới." *(Applies to the Journal · Photos · Album · Stories bar and the bottom menu bar.)*
- **Tokens:** `quick`
- **Haptic:** "Không rung" *(No haptic)*

**Sequence:**

| Key | Timing | Caption (verbatim) | Gloss | Measured |
|---|---|---|---|---|
| 1 | Đứng yên *(At rest)* | Thanh nổi hiện đầy đủ | Floating bar fully visible | Pill bar (white, shadow) with tabs "Nhật ký" (selected, ink bg) · "Ảnh" · "Album" |
| 2 | Cuộn xuống *(Scroll down)* | Trượt xuống 16px và mờ đi (200ms) | Slides down 16 px and fades (200 ms) | Opacity 30% in the frame, y +16, shadow removed |
| 3 | Cuộn lên *(Scroll up)* | Hiện lại ngay khi cuộn ngược lên 8px | Reappears as soon as the user scrolls back up 8 px | — |

- **Reduce Motion / Night care:** not specified.
  - Inferred: Reduce Motion fades only, with no translate.
- **Do / don't:** react to direction change after just 8 px of reverse scroll; no haptic.

### P5 · Tải ảnh, video lên *(Upload photos/videos)* — 271:102

- **Trigger (verbatim):** "Sau khi chọn ảnh và bấm Lưu. Người dùng vẫn làm việc khác được." *(After choosing photos and pressing Save. The user can keep doing other things.)*
- **Tokens:** `quick` · `standard`
- **Haptic (verbatim):** ""Thành công" khi tải xong tất cả" *("Success" when everything has finished uploading)*
- **Applies to:** UploadPill + MediaTile (Uploading state: 35% black overlay + progress ring).

**Sequence:**

| Key | Timing | Caption (verbatim) | Gloss | UI text in art |
|---|---|---|---|---|
| 1 | 0 ms | Thanh tải hiện từ trên, trượt xuống 8px | Upload pill appears from the top, sliding down 8 px | "Đang tải 4/7 mục" *(Uploading 4/7 items)* · "Cứ làm việc khác, xong sẽ báo bạn" *(Go ahead and do other things, we'll tell you when it's done)* |
| 2 | Đang tải *(Uploading)* | Thanh tiến trình chạy liên tục, không giật theo từng tệp | Progress bar runs continuously, no jumps per file | Same; fill ≈ 44% |
| 3 | Xong *(Done)* | Đổi sang dấu ✓, giữ 1,5 giây | Switches to a ✓, holds for 1.5 s | "Đã tải xong 7 mục" *(Finished uploading 7 items)* · "Đã báo cho Bà nội, Ông ngoại" *(Notified Grandma (paternal), Grandpa (maternal))* |
| 4 | +1,5 s | Thu gọn và mờ đi (exit), ảnh mới hiện lần lượt cách 30ms | Shrinks and fades (exit); new photos appear one by one, 30 ms apart | Pill at ≈ 0.92 scale, 25% opacity, moving up 6 px (measured) |

- **Entry:** `quick`, translate 8 px.
- **Progress:** continuous and interpolated, not stepped per file.
- **Exit:** `exit`.
- **New items:** stagger 30 ms, max 6.
- **Not animated:** per-file progress jumps.
- **Reduce Motion / Night care:** not specified.
  - Inferred: fade only; no stagger, per the story-card rule.
- ⚠ **Mockup inconsistency.** In the "Xong" frame the progress fill is drawn at ≈ 76%, not 100%.

### P6 · Thả tim, lưu yêu thích *(Heart / save as favourite)* — 271:269

- **Trigger (verbatim):** "Chạm tim (gia đình thương) hoặc dấu lưu (yêu thích cá nhân) trên ảnh." *(Tap the heart (family "love") or the bookmark (personal favourite) on a photo.)*
- **Tokens:** `instant` · `quick`
- **Haptic (verbatim):** "Nhẹ khi chạm" *(Light on tap)*

**Sequence:**

| Key | Timing | Caption (verbatim) | Gloss | Measured |
|---|---|---|---|---|
| 1 | 0 ms | Tim rỗng | Empty (outline) heart | Icon 36 px |
| 2 | 120 ms | Tim đầy màu, phóng 1.25 | Heart fills with colour, scales to 1.25 | 45 px |
| 3 | 250 ms | Về lại 1.0, hiện "Bà nội và 2 người thương" | Back to 1.0; shows "Grandma and 2 others loved this" | Label 12/SemiBold next to the heart |

- **Timing:** scale-up 0 → 120 ms; settle 120 → 250 ms.
- **Reduce Motion:** "Chỉ đổi màu" *(colour change only)*.
- **Night care:** "Không phóng to, chỉ đổi màu" *(no scale-up, colour change only)*.

### P7 · Chuyển màn hình *(Screen transition)* — 271:324

- **Trigger (verbatim):** "Đi sâu vào chi tiết (album, câu chuyện, hồ sơ bé). Quay lại bằng nút hoặc vuốt từ mép trái." *(Drill into detail (album, story, baby profile). Go back with the button or by swiping from the left edge.)*
- **Tokens:** `standard`
- **Haptic:** "Không rung" *(No haptic)*

**Sequence:**

| Key | Timing | Caption (verbatim) | Gloss | Measured |
|---|---|---|---|---|
| 1 | 0 ms | Màn hiện tại | Current screen | — |
| 2 | 150 ms | Màn cũ lùi 30% và tối đi, màn mới trượt vào từ phải | Old screen recedes 30% and darkens; new screen slides in from the right | Old screen x −45 px (= 30% of 150 px), dim 18% `#0a1a1c`. New screen has a shadow. |
| 3 | 350 ms | Màn mới đứng yên | New screen at rest | — |
| 4 | Vuốt từ mép *(Edge swipe)* | Màn mới đi theo tay; thả quá 40% thì quay lại màn cũ | New screen follows the finger; release past 40% → returns to the old screen | Dim 12% mid-swipe |

- **Parallax:** the old screen moves 30% of the width (the iOS-style push).
- **Back-swipe commit threshold:** 40%.
- **Reduce Motion:** "Mờ dần 150ms, không trượt" *(fade 150 ms, no slide)*.
- **Night care:** "Không nảy, 250ms ease-out" *(no bounce, 250 ms ease-out)*.

### P8 · Đang tải dữ liệu *(Loading data)* — 271:393

- **Trigger (verbatim):** "Lần đầu mở tab hoặc kéo xuống để làm mới." *(First time opening a tab, or pull to refresh.)*
- **Tokens:** `gentle` · `quick`
- **Haptic (verbatim):** "Nhẹ khi kéo đủ để làm mới" *(Light once pulled far enough to refresh)*

**Sequence:**

| Key | Timing | Caption (verbatim) | Gloss | Measured |
|---|---|---|---|---|
| 1 | 0 ms | Khung xám đúng hình dạng nội dung, ánh sáng lướt qua mỗi 1,2 giây | Grey skeleton matching the content shape; a light sweep passes every 1.2 s | Skeleton `surface-2 #eef6f5`, r14. Shimmer band 40 px wide, white 0 → 70% → 0 horizontal gradient. |
| 2 | Có dữ liệu *(Data loaded)* | Nội dung mờ dần vào (quick), không nhảy bố cục | Content fades in (quick), no layout shift | CareTiles "Bú bình 120 ml · 45 phút trước · Mẹ ghi" and "Giấc ngủ · Đã thức 2 giờ · Dậy lúc 13:05 · Ba ghi" *(Sleep · Awake 2 h · Woke at 13:05 · Dad logged)* |
| 3 | Chờ > 10 giây *(Waiting > 10 s)* | Hiện dòng chữ nhẹ nhàng: "Mạng hơi chậm, vẫn đang tải…" | Show a gentle line of text: "Network is a bit slow, still loading…" | 12/Medium, ink-muted, below the skeleton |

- **Shimmer period:** 1.2 s, loop.
- **Content reveal:** `quick` fade.
- **`gentle`:** listed as a token; probably for the shimmer or the pull indicator (inferred).
- **Not animated:** layout must not jump when data arrives.
- **Reduce Motion:** "Khung xám đứng yên" *(skeleton static)*.
- **Night care:** "Khung xám đứng yên, độ sáng thấp" *(skeleton static, low brightness)*.

### P9 · Gợi ý (tooltip) *(Hint / tooltip)* — 272:259

- **Trigger (verbatim):** "Lần đầu thấy tính năng mới, hoặc nhấn giữ một nút. Mỗi lần chỉ hiện một gợi ý." *(First time seeing a new feature, or long-pressing a button. Only one hint is shown at a time.)*
- **Tokens:** `quick` · `exit`
- **Haptic:** "Không rung" *(No haptic)*

**Sequence:**

| Key | Timing | Caption (verbatim) | Gloss | Measured |
|---|---|---|---|---|
| 1 | 0 ms | Nút đích có vòng sáng nhẹ để gây chú ý | Target control gets a soft glow ring to draw attention | 200×170 ellipse glow behind the CareTile |
| 2 | 200 ms | Gợi ý mờ dần vào và nảy lên 8px từ phía nút | Tooltip fades in and rises 8 px from the button side | Opacity 60% in the frame, offset +10 px (measured) |
| 3 | Đứng yên *(At rest)* | Giữ đến khi người dùng chạm bất kỳ đâu; không tự ẩn trong 3 giây đầu | Stays until the user taps anywhere; never auto-hides in the first 3 s | Tooltip text "Chạm để ghi bú bình nhanh" *(Tap to quickly log a bottle feed)*. Bg `#163d44`, r14, padding 14/10, white 12/SemiBold, 14×8 arrow. |
| 4 | Đóng *(Close)* | Mờ đi 150ms tại chỗ, không trượt | Fades out in place over 150 ms, no slide | Opacity 20% in the frame |

- **Enter:** `quick` 200 ms, fade + 8 px rise.
- **Exit:** fade 150 ms in place.
- ⚠ **Exit duration conflict.** The token chip says `exit` (250 ms), but the caption says 150 ms. Caption likely wins.
- **Not animated:** no slide on close; no auto-dismiss within 3 s.
- **Reduce Motion / Night care:** not specified.
  - Inferred: fade only, and no glow ring at night per "không chớp sáng" *(no flashing)*.

### P10 · Đồng hồ đang ngủ (chuyển động nền) *(Sleep timer — ambient motion)* — 272:368

- **Scope (verbatim):** "Khi bé đang ngủ hoặc đang bú mẹ: màn Hôm nay, widget, màn hình khoá, Dynamic Island." *(While the baby is sleeping or breastfeeding: Today screen, widget, lock screen, Dynamic Island.)*
- **Tokens:** `4 s/nhịp` *(4 s per breath cycle)* · `quick`
- **Haptic (verbatim):** "Không rung khi chạy · "Thành công" khi bấm Thức dậy" *(No haptic while running · "Success" on pressing Wake up)*
- **Applies to:** SleepTimer (10:83), the breastfeeding timer, Live Activity / Dynamic Island, widgets.

**Sequence (dark art bg `#0c1719`):**

| Key | Timing | Caption (verbatim) | Gloss | Measured |
|---|---|---|---|---|
| 1 | 0 s | Trăng "thở": phóng 1.0 → 1.04, quầng sáng đậm dần | Moon "breathes": scale 1.0 → 1.04; halo intensifies | Timer "1:27:06" `#9ea3ff` 24/SemiBold. Label "Teddy đang ngủ" *(Teddy is sleeping)* white 70%. Moon 55.2 px. Halo 170 px; progress ring 150 px. |
| 2 | 2 s | Đỉnh nhịp thở; vòng tiến trình chạy đều theo giây | Peak of the breath; progress ring advances evenly each second | Moon 57.4 px (= 1.04). Timer "1:27:08". |
| 3 | 4 s | Về lại 1.0 — lặp lại, nhịp chậm như hơi thở | Back to 1.0 — repeat, slow like breathing | "1:27:10" |
| 4 | Bấm Thức dậy *(Press Wake up)* | Số dừng lại, trăng mờ dần thành mặt trời nhỏ (gentle), hiện "Đã ghi · ngủ 1 giờ 27" | Counter stops; the moon cross-fades into a small sun (gentle); shows "Logged · slept 1 h 27" | Light bg. Timer "1:27:12" in care-sleep-ink `#4447a8`. Pill `#163d44`. Sun 54 px. |

- **Breath cycle:** scale 1.0 → 1.04 → 1.0 over 4 s (2 s up, 2 s down), looping. Curve not stated (inferred: ease-in-out sine).
- **Wake:** `gentle` 600 ms moon → sun cross-fade.
- ⚠ **SleepTimer component conflict.** The component description (10:83) says "breathing opacity 1 ↔ 0.55 over duration-breath (ease-in-out)" on the arc. This frame specifies a moon **scale** 1.0 ↔ 1.04 plus halo, and an evenly advancing ring. Reconcile (likely: duration-breath = 4 s).

### Ambient rules (272:425) — mint callout under P10

| Verbatim | Gloss |
|---|---|
| • Chuyển động nền (đang ngủ, đang bú, đang tải lên) phải chậm và êm: một nhịp 4 giây, biên độ nhỏ, độ tương phản thấp. | *Ambient motion (sleeping, breastfeeding, uploading) must be slow and smooth: a 4-second cycle, small amplitude, low contrast.* |
| • Chỉ chạy khi màn đang hiển thị. Tạm dừng khi app chạy nền, máy tiết kiệm pin, hoặc người dùng bật "Giảm chuyển động" — lúc đó chỉ còn số đếm. | *Run only while the screen is visible. Pause when the app is in the background, the device is in battery-saver, or the user enabled "Reduce Motion" — then only the counter remains.* |
| • Widget và màn hình khoá không tự chạy animation: chỉ cập nhật số giờ theo hệ thống (đồng hồ đếm của iOS/Android). | *Widgets and the lock screen don't run their own animation: they only update the time via the system (the iOS/Android native timer/count-up).* |

Inferred implementation for widgets and the lock screen:

- **iOS:** `Text(timerInterval:)` / `Text(date, style: .timer)`.
- **Android:** `Chronometer`.

---

## 5. Rules (271:463)

- **Heading (271:464):** "3 · Ban đêm, Giảm chuyển động và rung" *(Night, Reduce Motion and haptics)*
- **Subheading (271:465):** "Một bảng duy nhất để dev biết khi nào đổi cách chuyển động." *(A single table so dev knows when to change the motion behaviour.)*

### 5.1 Table (271:467) — verbatim, with gloss

| Tình huống *(Situation)* | Bình thường *(Normal)* | Night care | Giảm chuyển động (cài đặt máy) *(Reduce Motion, device setting)* |
|---|---|---|---|
| Mở/đóng sheet, chuyển màn *(open/close sheet, screen transition)* | Spring, nảy rất nhẹ (standard) *(spring, very slight bounce)* | Không nảy, 250ms ease-out *(no bounce, 250 ms ease-out)* | Mờ dần 150ms, không trượt *(fade 150 ms, no slide)* |
| Lưu một lần ghi *(save a log)* | Nút co lại, ✓, thông báo trượt lên *(button shrinks, ✓, toast slides up)* | Như bình thường, thông báo nền tối, không viền sáng *(as normal, dark toast, no glow border)* | Thông báo mờ dần, không trượt *(toast fades, no slide)* |
| Mở ảnh toàn màn hình *(open photo full-screen)* | Phóng to từ vị trí ảnh *(zoom from photo position)* | Nền tối sẵn, thời gian ngắn hơn 20% *(already-dark bg, 20% shorter)* | Mờ dần chéo 200ms *(crossfade 200 ms)* |
| Thả tim *(heart)* | Phóng 1.25 rồi về *(scale 1.25 then back)* | Không phóng to, chỉ đổi màu *(no scale, colour only)* | Chỉ đổi màu *(colour only)* |
| Đang tải *(loading)* | Ánh sáng lướt qua khung xám *(shimmer over skeleton)* | Khung xám đứng yên, độ sáng thấp *(static skeleton, low brightness)* | Khung xám đứng yên *(static skeleton)* |
| Thiệp câu chuyện, mốc kỷ niệm *(story cards, milestones)* | gentle 600ms, xuất hiện lần lượt *(gentle 600 ms, staggered)* | gentle, bỏ xuất hiện lần lượt *(gentle, no stagger)* | Hiện ngay, không hiệu ứng *(appear immediately, no effect)* |

### 5.2 Haptics (271:537)

| Type (verbatim) | When (verbatim) | Gloss | Inferred platform API |
|---|---|---|---|
| Nhẹ (light) | Chạm ô ghi nhanh, thả tim, bật công tắc | Tap quick-log tile, heart, toggle a switch | iOS `UIImpactFeedbackGenerator(.light)`; Android `HapticFeedbackConstants.VIRTUAL_KEY`/`CLOCK_TICK`; Flutter `HapticFeedback.lightImpact()` |
| Thành công (success) | Lưu xong một lần ghi, tải xong ảnh, lưu câu chuyện | Log saved, photos finished uploading, story saved | iOS `UINotificationFeedbackGenerator(.success)`; Android `CONFIRM` (API 30+) |
| Cảnh báo (warning) | Trước khi xoá, khi ghi trùng giờ | Before deleting; when logging an overlapping time | iOS `.warning`; Android `REJECT` |
| Không rung *(no haptic)* | Cuộn, chuyển tab, mở sheet, mọi lúc trong Night care trừ khi lưu xong | Scrolling, switching tabs, opening sheets, and **at all times in Night care except when a save completes** | — |

Flutter has no built-in success/warning notification haptic. A plugin or platform channel is needed (inferred).

### 5.3 Note (271:551)

> "Kiểm tra trên máy thật cấu hình thấp: chuyển động phải giữ 60 khung hình/giây. Nếu không giữ được, bỏ hiệu ứng, giữ phản hồi."

*Test on a real low-end device: motion must hold 60 fps. If it can't, drop the effect and keep the feedback.*

---

## 6. Reconciliation with component descriptions (inferred mapping)

Component descriptions (see `07-foundations-components-motion.md` §7) use different token names. The most likely mapping is below. **Needs design sign-off.**

| Component-description name | Where used | Likely motion-spec token |
|---|---|---|
| duration-tap | Button press | `motion.instant` 100 ms |
| duration-quick | QuickAction save bounce + ✓; Segmented change | `motion.quick` 200 ms |
| duration-base | LatestCard number roll; BottomSheet spring | `motion.standard` ~350 ms spring |
| duration-breath | SleepTimer breathing | 4 s cycle (P10) |
| duration-slow | MemoryCard new-card lift | `motion.gentle` 600 ms |
| — (new) | sheet/photo/toast dismiss | `motion.exit` 250 ms |

## 7. Open issues ⚠

1. **Button press scale.** Button 8:33 says 0.97; the motion spec says 0.96.
2. **Curve snippets vs bezier labels.** For instant/quick/gentle, the iOS/Android snippets don't reproduce the stated cubic-beziers. Decide whether the bezier or the platform default is canonical. For Flutter, use the bezier.
3. **standard spring values.** iOS response 0.35 (stiffness ≈ 322) vs Android stiffness 380.
4. **P9 tooltip close.** 150 ms caption vs `exit` 250 ms token chip.
5. **Undo window.** Toast 4 s (P1) vs widget "Đã ghi · Hoàn tác" ~5 s (component description).
6. **SleepTimer breathing.** Opacity 1↔0.55 (component) vs moon scale 1.0↔1.04 + halo (P10).
7. **Unspecified Reduce Motion / Night care variants.** P4 tab bar, P5 upload, P9 tooltip and P10 have none (P10 only says "chỉ còn số đếm" *(only the counter remains)*).
8. **Night care curve.** "250ms ease-out" doesn't name a curve. Inferred: (0.2, 0, 0, 1).
9. **No keyframes.** Figma has no keyframe/prototype data, so this storyboard is the only source.
