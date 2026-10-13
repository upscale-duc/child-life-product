# 26 · Góp ý & đánh giá (FB1–FB5)

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only), page **"v1.0 - improvement"** `345:35701`, row
**"FB · Góp ý & đánh giá"** (label text node `477:6397`, canvas y 26430; frames at y 26500, x 0 /
415 / 830 / 1245 / 1660). Read 2026-10-13: `get_metadata` on the canvas (saved locally, frames
found by name), `get_design_context` on the label and on all five frames. No Figma node was
modified, no asset was downloaded.

**Node ids.** The links first given for FB1 (`477:5768`), FB2 (`477:6115`) and FB3 (`477:6491`)
are wrong: the first two do not exist, and `477:6491` is the `Icon/chevron-right` inside FB1's
"Đánh giá trên App Store" row. The real frames are:

| Frame | Node | Exact name | Size |
| --- | --- | --- | --- |
| Row label | `477:6397` | "Label · FB · Góp ý & đánh giá" (renders "FB · Góp ý & đánh giá", Bold 28 ink) | 300×35 |
| FB1 | `477:6398` | "FB1 · Tôi · Góp ý" | 375×1089 (scrolling screen) |
| FB2 | `477:6493` | "FB2 · Góp ý" | 375×812 |
| FB3 | `477:6549` | "FB3 · Đã gửi góp ý" | 375×812 |
| FB4 | `477:6564` | "FB4 · Chụp màn hình · báo lỗi nhanh" | 375×812 |
| FB5 | `477:6608` | "FB5 · Khoảnh khắc vui · hỏi đánh giá" | 375×812 |

**Annotations.** FB1, FB2, FB3 and FB5 carry no `data-annotations`. FB4 carries one, but it is the
Hôm nay annotation copy-pasted with the screen (quoted below); nothing on the row describes the
feedback behaviour in words. The label is the only text node next to the frames.

**Screenshots** (from `get_design_context`, local tool output of this session, not copied into
`img/`):
`~/.claude/projects/-Users-duckie2910-Documents-child-life-product/7ef1a69d-795c-5961-94d0-e77d68b7fe79/tool-results/`
`mcp-claude_ai_Figma-blob-1791853662131-lsx6q9.png` (FB1), `…1791853661239-zmz7q0.png` (FB2),
`…1791853661694-67nnez.png` (FB3), `…1791853676361-p2idac.png` (FB4),
`…1791853676178-tnwcfv.png` (FB5).

Light only: no Night twin exists for this row. Tokens as in `07` (hex = Light value). Font: Be
Vietnam Pro throughout. "lh normal" = no fixed line height in Figma.

---

## FB1 · Tôi · Góp ý `477:6398`

**Purpose.** The "Tôi" (Me) screen opened from the header avatar, with two new rows at the end of
the second group: **"Góp ý cho Child Life"** (opens FB2) and **"Đánh giá trên App Store"** (rate
the app). It is the same screen as `16` → `370:1898` "CS Tôi (từ avatar)" with several copy changes
(see "Changes against 370:1898").

**Text (reading order)**
- StatusBar "9:41" / "•••".
- Back button (no title in the bar).
- "Tôi" (Me) — large title.
- Profile: avatar "M"; "Mai"; "mai.nguyen@gmail.com"; "Mẹ · quản lý hồ sơ Teddy, Na" (Mom · manages Teddy's and Na's profiles); chevron.
- Storage card: "Dung lượng" (Storage) · "3,2 GB / 10 GB"; bar; legend "● Teddy 2,4 GB" · "● Na 0,8 GB"; "Dùng chung cho tất cả các bé của bạn" (Shared by all your babies).
- Group 1:
  - [cake] "Các bé" (Babies) / "Teddy, Na" · value "2" · chevron
  - [family] "Gia đình" (Family) / "4 thành viên" (4 members) · chevron
  - [today] "Thông báo" (Notifications) · value "Bật" (On) · chevron
  - [globe] "Giao diện" (Appearance) · value "Tự động" (Automatic) · chevron
- Group 2:
  - [link] "Liên kết chia sẻ" (Share links) / "2 liên kết đang mở" (2 links open) · chevron
  - [lock] "Tài khoản & đăng nhập" (Account & sign-in) / "Email, Apple, đổi máy" (Email, Apple, change device) · chevron
  - [mail] "Trợ giúp & liên hệ" (Help & contact) · chevron
  - **new** [mail] "Góp ý cho Child Life" (Feedback for Child Life) / "Báo lỗi, đề xuất tính năng" (Report a bug, suggest a feature) · chevron
  - **new** [star] "Đánh giá trên App Store" (Rate on the App Store) · chevron
- "Đăng xuất" (Sign out) — own card, error colour.

**Layout and components**
- Frame bg cloud `#f6fcfb`, radius 40 (mock frame), no border. Content column: pt 52, px 16, pb 120, absolute; StatusBar overlaid at top. **No TabDock** (pushed screen).
- Top row (h 36): back button = surface `#ffffff` circle (radius 999), padding 8, `Icon/back` 20; flexible spacer.
- "Tôi": Text/large-title — SemiBold 32 / lh 40 / tracking −0.4, ink `#173d44`. Then 16 gap.
- Profile row (gap 14, centred): avatar circle peach-soft `#ffe3da`, padding 24 × 18 (≈73×71), "M" SemiBold 28 on-warm `#173d44`; text column gap 2: "Mai" SemiBold 24 ink; email Medium 14 ink-muted `#55707a`; role Text/caption (Medium 12 / lh 16 / tracking 0.2) ink-muted; spacer; chevron 18. Then 20 gap.
- Storage card: surface, radius 20, padding 16, gap 10, shadow-tile (`#122E331A` 0/2 blur 4 + `#122E3329` 0/10 blur 22 spread −4). Header row space-between: "Dung lượng" SemiBold 14 ink, "3,2 GB / 10 GB" Medium 14 ink-muted. Bar h 10, radius 999, track separator `#dce8e7`, segments mint-deep `#087f7b` (74.64 of 311 = 24 %, Teddy) and peach `#ffa58d` (24.88 = 8 %, Na), no gap between them. Legend row gap 14, Text/caption: "● Teddy 2,4 GB" mint-text `#06716d`, "● Na 0,8 GB" on-warm `#173d44`. Footnote Text/caption ink-muted. Then 16 gap.
- Groups: surface, radius 18, no shadow, no dividers, overflow clipped. 12 gap between the two groups, 16 before "Đăng xuất".
  - Older rows ("Các bé", "Thông báo", "Giao diện", "Liên kết chia sẻ", "Tài khoản & đăng nhập", "Trợ giúp & liên hệ"): padding 14 × 13, gap 12, icon 20, title SemiBold 14 ink, sub Text/caption ink-muted, value Medium 14 ink-muted, `Icon/chevron-right` 16. Heights 62 (two lines) / 46 (one line).
  - Newer rows ("Gia đình", "Góp ý cho Child Life", "Đánh giá trên App Store"): padding **16 × 14**, gap 12, icon 20, title **SemiBold 15** ink, sub **Medium 12 / lh 1.4** ink-muted (no tracking), chevron 16. Heights 66 / 66 / 48. The two row styles are mixed in the same group; one row style for all is the obvious implementation (inferred).
- "Đăng xuất": surface card radius 18, padding 14 × 13, SemiBold 14 error `#a12b32`.
- Components: StatusBar, `Icon/back`, `Icon/cake`, `Icon/family`, `Icon/today`, `Icon/globe`, `Icon/link`, `Icon/lock`, `Icon/mail` (×2), `Icon/star`, `Icon/chevron-right`, "chev" 18. All rows are local frames (no ListRow component). Icon description (verbatim): "Line icon (24px, 1.8 stroke) — placeholder; production uses SF Symbols."

**Visual.** Same look as 370:1898: large "Tôi", peach avatar, white storage card with a teal + peach bar, two white groups, red sign-out. The two new rows sit under "Trợ giúp & liên hệ" with the same envelope icon and a star outline icon. Content is 1069 tall, so the screen scrolls; "Đăng xuất" ends at y 949.

**Navigation (inferred)**
- "Góp ý cho Child Life" → FB2 (FB2 has a close "×", so it is presented modally).
- "Đánh giá trên App Store" → store review page (iOS: App Store "write review" URL; Android: Google Play listing, copy "Đánh giá trên Google Play" — not drawn).
- Other rows as in `16` (370:1898).

**Changes against 370:1898 "CS Tôi (từ avatar)"** (copy, so it matters for ARB):
- Role line "Mẹ · chủ hồ sơ của Teddy, Na" → "Mẹ · quản lý hồ sơ Teddy, Na".
- "Hồ sơ các bé" → "Các bé".
- New row "Gia đình" / "4 thành viên" (`Icon/family`) after "Các bé".
- "Đã chia sẻ ra ngoài" → "Liên kết chia sẻ".
- New rows "Góp ý cho Child Life" and "Đánh giá trên App Store".
- The UP6 "Phiên bản 1.0.3" row (`24`) is not in this frame (frames drawn separately).

**Not shown.** Caregiver / relative variants of the new rows; whether the rate row is hidden after
the user has rated; Android wording; Night care.

---

## FB2 · Góp ý `477:6493`

**Purpose.** The feedback form: pick a type, write a message, optionally attach a screenshot,
choose whether to send device info and whether the team may reply by email, then send.

**Text (reading order)**
- StatusBar "9:41" / "•••".
- Close button "×" (no title in the bar).
- "Góp ý" (Feedback) — title.
- "Đội ngũ Child Life đọc từng góp ý. Cảm ơn bạn đã giúp app tốt hơn cho các gia đình." (The Child Life team reads every piece of feedback. Thank you for helping make the app better for families.)
- Type chips: "Ý tưởng" (Idea, selected) · "Báo lỗi" (Report a bug) · "Khác" (Other).
- Field label: "Bạn muốn chia sẻ điều gì?" (What would you like to share?)
- Field value (typed by the user, example): "Mong có thêm biểu đồ giấc ngủ theo tuần, để biết bé ngủ trưa có đều không." (I'd like a weekly sleep chart, to see whether baby naps regularly.)
- Attachment tile: "Ảnh chụp màn hình" (Screenshot).
- Toggle row: "Gửi kèm thông tin thiết bị" (Attach device info) / "Phiên bản app, hệ điều hành · không gồm ảnh hay dữ liệu của bé" (App version, operating system · no photos or baby data) — on.
- Toggle row: "Cho phép liên hệ lại" (Allow us to contact you) / "mai.nguyen@gmail.com" — on.
- Primary button: "Gửi góp ý" (Send feedback).

**Layout and components**
- Frame bg cloud `#f6fcfb`, radius 40. Content column: pt 52, px 16, pb 130, **gap 16** between every block; StatusBar overlaid.
- Top row (h 36): surface circle, padding 8, `Icon/close` 20 (ink); spacer.
- Title "Góp ý": **Bold 28**, lh normal, ink (not the large-title style; same as UP1 "Cần cập nhật…" in `24`).
- Intro: Medium 14 / lh 1.5, ink-muted `#55707a`, full width (two lines).
- Type chips row: 3 equal chips (flex 1, gap 8, each 109×36), pill radius 999, padding 14 × 9, content centred, gap 6, icon 14 + label SemiBold 13.
  - Selected ("Ý tưởng", `Icon/spark`): bg mint-soft `#e6f7f5`, 1 px border mint-deep `#087f7b`, label mint-text `#06716d` (icon tinted to match).
  - Unselected ("Báo lỗi" `Icon/alert`, "Khác" `Icon/mail`): bg surface `#ffffff`, 1 px border separator `#dce8e7`, label ink `#173d44`.
  - Single choice (inferred). Default selection not stated (example shows "Ý tưởng").
- Field: column gap 6. Label SemiBold 13 ink-muted. Box: surface, 1 px border control-border `#7e959a`, radius 14, **fixed height 120**, padding 14 × 13; text Medium 15 / lh 1.45 ink. Multi-line, top-aligned. Placeholder text and character limit not drawn.
- Attachment: one tile 150×80, **dashed** 1 px control-border border, radius 16, no fill (cloud shows through), column centred, gap 4, py 14: `Icon/camera` 20 + "Ảnh chụp màn hình" Medium 12 ink-muted. (In the render the caption is clipped on the left by 1 px; a Figma artefact.) Left-aligned in the row; there is room for more tiles to its right (inferred: chosen screenshot thumbnails go there).
- Settings group: surface, radius 16, clipped, no dividers. Rows padding 14 × 12, gap 12; text column flex: title SemiBold 15 ink, sub Medium 12 / lh 1.4 ink-muted, gap 2; `Toggle` instance scaled to 43.35 × 26.35 (the component is the iOS switch at 85 %). Toggle description (verbatim): "iOS switch. On: mint-deep track. Off: separator track. White knob." Both are **on** in the design.
- Bottom bar (pinned, y 714, h 98): bg cloud, pt 12, px 16, pb 30; `Button` Primary h 56, full width, mint-deep `#087f7b`, radius-pill, label Text/body-strong (Medium 17 / lh 24) on-mint-deep white "Gửi góp ý". Button description (verbatim): "Pill button, label = 1–2-word verb (Lưu, Bắt đầu, Kết thúc, Chỉnh giờ, Mời, Thử lại). Primary h56 mint-deep/on-mint-deep, one per screen in the thumb zone. Secondary h52 surface-2. Tinted for secondary actions. Plain for text buttons (≥44 tap). Apple: use Apple’s official button in production. Press: scale 0.97 in duration-tap. Disabled: opacity 40%. Stretch to fill width for block buttons."
- Components: StatusBar, `Icon/close`, `Icon/spark`, `Icon/alert`, `Icon/mail`, `Icon/camera`, `Toggle` ×2, `Button`. Chips, field and rows are local frames.

**Visual.** Light mint page, close circle top-left, big bold "Góp ý" with a grey two-line intro. Three
pill chips in a row, the first tinted mint with a teal outline. A white text box with a grey
outline holding the example message. A dashed rounded tile with a camera icon. A white card with two
teal toggles. A full-width teal "Gửi góp ý" pill at the bottom.

**Navigation (inferred)**
- Opened from FB1 "Góp ý cho Child Life" (modal, close "×") and from FB4 "Báo lỗi" (then "Báo lỗi" chip preselected and the screenshot already attached).
- "×" → back to the previous screen (discard confirmation when text was typed: not drawn).
- "Ảnh chụp màn hình" → photo picker (screenshots).
- "Gửi góp ý" → sends, then FB3.

**Not shown.** Empty state / placeholder text in the box; disabled send button (empty message);
sending spinner and error state; an attached-screenshot thumbnail and how to remove it; how many
screenshots; what "thông tin thiết bị" contains exactly beyond "Phiên bản app, hệ điều hành";
whether the email row is hidden for accounts without email (Apple private relay); keyboard
behaviour; Night care.

---

## FB3 · Đã gửi góp ý `477:6549`

**Purpose.** Confirmation after sending.

**Text (reading order)**
- StatusBar "9:41" / "•••".
- Check mark in a circle.
- "Đã nhận góp ý của bạn" (We've received your feedback).
- "Nếu cần thêm thông tin, đội ngũ sẽ trả lời qua email trong 2 ngày làm việc. Bạn xem lại góp ý trong Tôi › Trợ giúp & liên hệ." (If we need more information, the team will reply by email within 2 working days. You can review your feedback in Me › Help & contact.)
- Button: "Xong" (Done).

**Layout and components**
- Frame bg cloud, radius 40. Content column: **pt 140**, px 16, pb 120, gap 16, all centred. No top bar, no close button.
- Check: circle mint-soft `#e6f7f5`, padding 22 (84×84), `Icon/check` 40 (mint-deep/mint-text stroke in the render).
- Title: Bold 26, lh normal, ink, centred.
- Body: Medium 15 / lh 1.5, ink-muted, centred, 3 lines. "›" is a literal character in the copy.
- `Button` Primary h 56, full width, mint-deep, "Xong" — placed directly under the text (y 374), **not** pinned to the bottom.
- Components: StatusBar, `Icon/check`, `Button`.

**Visual.** Mostly empty light page; a pale mint circle with a teal tick in the upper third, bold
centred title, grey centred paragraph, teal "Xong" pill right below; the lower half is empty.

**Navigation (inferred).** "Xong" → closes the feedback flow back to where it started (Tôi, or the
screen the screenshot came from). The copy promises the feedback is visible later in "Tôi ›
Trợ giúp & liên hệ" — i.e. a feedback item becomes a support ticket the user can see there
(ties to `SupportTicket`, D-038, G-057 in the business map).

**Not shown.** Variant when "Cho phép liên hệ lại" is off (the email sentence would be wrong);
Android back behaviour; Night care.

---

## FB4 · Chụp màn hình · báo lỗi nhanh `477:6564` (brief)

**Annotation (verbatim; stale, copied from the Hôm nay frame, says nothing about the toast):**
"Thẻ lớn = vừa ghi vừa xem: chạm thẻ → mở sheet ghi mục đó (1 chạm); dòng dưới là lần cuối (bao lâu trước · chi tiết · ai ghi). Ngủ khi timer chạy → CareTile Tone=Active hiện thời gian đang chạy. Tăng trưởng: hàng riêng, + mở màn nhập số đo. “Lịch sử” → dòng thời gian."

**What it shows.** Hôm nay (same content as `16`: header with "M" avatar, BabySwitcher "Teddy · 3
tuần", "Đêm" pill; "Thứ Năm, 8 tháng 10"; "Hôm nay" + "Tuỳ chỉnh"; six CareTiles Bú bình 120 ml /
Bú mẹ 15 phút / Giấc ngủ Đã thức 2 giờ / Thay tã Tã ướt / Hút sữa 90 ml / Tăng trưởng 4,3 kg;
ReminderPeek "Nhắc nhở · 3 đang bật" "Tiêm mũi 6 trong 1"; "Nhịp hôm nay" / "Xem lịch sử";
DayRhythm) right after the user took a system screenshot, with a toast floating over the third
tile row.

**Toast `477:6599`** — x 16, y 604 in the frame, **343 wide** (92 tall), bg **ink `#173d44`**,
**radius 20**, padding 14 × 12, row gap 12, centred vertically; no shadow in the design.
- Thumbnail `477:6600`: **36×64**, bg surface-2 `#eef6f5`, 2 px border surface `#ffffff`, radius 6 (stands for the screenshot just taken).
- Text column (flex, gap 2, white): **"Có gì chưa ổn ở màn này?"** (Something not right on this screen?) Bold 14; **"Gửi kèm ảnh vừa chụp để báo lỗi"** (Attach the screenshot you just took to report a bug) Medium 12, 70 % opacity. Both wrap to two lines at this width.
- Pill `477:6605`: **mint-deep** `#087f7b`, radius 999, padding 12 × 8, **"Báo lỗi"** (Report a bug) Bold 13 on-mint-deep white.
- `Icon/close` 16 (white).

**Navigation (inferred).** "Báo lỗi" → FB2 with "Báo lỗi" selected and the screenshot attached;
close → dismiss (auto-dismiss timing not drawn). Triggered by the OS screenshot event.

**Dock.** The frame's TabDock (NavBar v1.0.1: Hôm nay · Kỷ niệm · Chăm sóc · **Tiện ích**
(`Tab/Utilities`, `Icon/grid`) + QuickLogButton) sits at y 1041, outside the 812 frame, so it is not
visible.

**Not shown.** How often the toast may appear (every screenshot? once per session?), opt-out, what
happens on screens with child photos (privacy: the screenshot may contain a child's photo or name —
consent before upload is implied by the explicit "Báo lỗi" tap), Android behaviour (Android 14
screenshot callback), Night care.

---

## FB5 · Khoảnh khắc vui · hỏi đánh giá `477:6608` (brief)

**Annotation:** none.

**What it shows.** The system in-app review prompt shown after a happy moment: a background
"milestone saved" screen dimmed by a scrim, with the native review dialog on top.
- Background (Content, px 24, py 90, gap 14): art card sunshine-soft `#fff4d6`, radius 28, py 28, with a sunshine `#ffd166` circle (padding 20) holding `Icon/star` 40; "Lần đầu cười · 5 tháng 10" (First smile · 5 October) SemiBold 13 mint-text, centred; **"Đã lưu mốc đáng nhớ của Teddy"** (Teddy's milestone has been saved) Bold 24 ink, centred.
- Scrim: black 30 % over the whole frame.
- Dialog "SKStoreReview (hệ thống iOS)" (iOS system): 270 wide, bg `rgba(245,245,247,0.96)`, radius 14. Top block padding 16 × 18, gap 6, centred: `Logo/App Icon` 56; "Bạn thích Child Life?" (Enjoying Child Life?) SemiBold 16 black; "Chạm vào một ngôi sao để đánh giá trên App Store." (Tap a star to rate it on the App Store.) Medium 13 black; five `Icon/star` 22, gap 8, system blue `#007aff`. Divider 1 px black 15 %. "Không phải bây giờ" (Not now) Medium 16 `#007aff`, py 12.
- Designer tag (not app UI): ink pill, padding 12 × 6, at y 720: **"Hộp thoại hệ thống iOS · Android: In-App Review"** (iOS system dialog · Android: In-App Review) SemiBold 11 white.

**Meaning.** The app does not draw this dialog: it calls `SKStoreReviewController` / StoreKit
`requestReview` on iOS and the Play In-App Review API on Android (e.g. the `in_app_review` Flutter
package), after a positive moment such as saving a milestone. The OS decides whether it shows
(quota) and renders its own copy and language.

**Not shown.** Which moments count as "happy" besides a saved milestone, minimum usage before
asking, frequency cap, never asking during Night care or for caregivers/relatives (inferred
sensible defaults, need an owner decision).

---

## Coverage

All 5 frames and the row label were read with `get_design_context` (one call each); metadata from
one canvas `get_metadata`. No call failed, no rate-limit error. Nothing on the row was unreadable;
the only missing information is behavioural (listed under "Not shown" per frame), plus the wrong
node ids in the original links (corrected above).
