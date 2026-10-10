# Child Life: Onboarding, Auth, Baby Profile and Family/Invites (spec extracted from final Figma)

- **Source:** Figma file `sJLG1fAXKDnDr9YI6Yx8ex`, page **Screens (26:2)**. Read-only extraction via `get_design_context` (Light frames), 2026-10-10.
- **Sections covered:** 1 Chào mừng & giới thiệu chức năng · 2 Đăng nhập & xác minh · 3 Tạo hồ sơ bé & giao diện (plus extra frame **13a Lịch Night care 43:2067**, which belongs to this section) · 4 Gia đình & mời người · 4b Nhận lời mời.
- **Night care spot-checks:** 29:1375 (13 Giao diện · Night) and 121:12675 (14a Gia đình · Night).
  - Copy, structure and behavior are identical to the Light frames.
  - The only non-color difference: on 29:1375 the selected theme option is **"Tối"** instead of "Sáng".
- **Loose annotations:** none found.
  - The top-level text nodes in these sections ("T …" lines in `_screens_index.txt`) are screen labels and the "Light" / "Night care" row labels only.
  - All behavioral notes come from frame-level `data-annotations` and component descriptions. Both are quoted verbatim below.
- **Rate limiting:** one transient Figma MCP rate-limit error. `whoami` showed a Full seat on the Pro plan. After backoff the retry succeeded. **Every requested frame was read.**
- **Notation:**
  - "(inferred)" = not explicitly shown in the design.
  - Glosses are in *italics*.
  - Prototype links (destinations) are not exposed by MCP. Every "→ destination" is inferred from copy and frame order unless stated otherwise.

---

## Global component rules that apply to these screens (verbatim component descriptions)

| Component | Description (verbatim) |
|---|---|
| Button (8:33) | "Pill button, label = 1–2-word verb (Lưu, Bắt đầu, Kết thúc, Chỉnh giờ, Mời, Thử lại). Primary h56 mint-deep/on-mint-deep, one per screen in the thumb zone. Secondary h52 surface-2. Tinted for secondary actions. Plain for text buttons (≥44 tap). Apple: use Apple's official button in production. Press: scale 0.97 in duration-tap. Disabled: opacity 40%. Stretch to fill width for block buttons." |
| Icon/brand-mark (22:197) | "Placeholder for Apple / Google marks — use the official logos in production." |
| TopBar (23:226) | "Top bar for onboarding/auth (44px): round Back, "Bỏ qua" text button, setup progress, invite countdown, or the logo lockup (Logo/Lockup Horizontal, 28px) with a theme toggle." |
| Button/Back (8:37) | "Round back button, 44px tap target, surface-2. Accessibility label: Quay lại." |
| Button/Round (8:34) | "Round Next button (64px) on onboarding pages. Icon-only, so it MUST carry an accessibility label: "Tiếp tục" (VoiceOver: "Tiếp tục, nút"). Never rely on the arrow alone." |
| PageDots (23:185) | "Onboarding pagination: active = 24px mint-deep pill, others 6px separator dots." |
| Progress (23:190) | "Setup progress bar (4px). Fill mint-deep on separator track." |
| TextField (23:243) | "Text field: caption label above the value. Grouped = row inside a surface card (stack rows with a 1px separator). Standalone = its own surface card. Password shows a 32px eye toggle." |
| Segmented (9:124) | "Pill segmented control on surface-2 track (pad 5, gap 4). 2–3 short options (Sữa mẹ · Sữa công thức; Ướt · Bẩn · Cả hai). Remembers the last choice as the default." |
| Segmented/Item (9:111) | "One segment. Selected: surface + shadow-card, ink, weight 500. Unselected: transparent, ink-muted. Change animates in duration-quick." |
| SheetHeader (37:293) | "Bottom-sheet header: grabber, title (24/32 semibold), close (44px, label "Đóng")." |
| DateWheel (37:301) | "Date wheel (iOS UIDatePicker .wheels look-alike): Day · Month · Year, selected row on a surface-2 band. Use the native picker in production; default = today, cannot pick a future date." |
| OptionRow (37:348) | "Single-select list row (time zone, language…): title + subtitle, radio. Stack inside a surface card with separators." |
| Radio (23:257) | "Radio / single-select (24px). Checked: mint-deep with check. Unchecked: 1.5px control-border ring (3:1)." |
| SettingRow (23:340) | "Setting row with a switch: icon tile, title + one-line explanation, Toggle." |
| Toggle (23:262) | "iOS switch. On: mint-deep track. Off: separator track. White knob." |
| DetailRow (23:244) | "Settings/detail row: icon on mint-soft tile, label, current value (ink-muted), chevron. Stack inside a surface card with separators." |
| SelectTile (25:399) | "Multi-select tile (trackers): object art + label. Selected: mint-soft fill, 2px mint-deep border, check. Unselected: surface + shadow-card." |
| ThemeOption (23:339) | "Appearance choice: mini preview (fixed colours — it shows the theme itself), label, radio. Selected preview gets a 2.5px mint-deep ring." |
| CodeInput (23:355) | "Invite code entry: 10 characters, wide tracking, paste-friendly. Auto-uppercase." (**conflicts with the 6-digit code on screens; see Open questions**) |
| PermissionTile (23:369) | "What the invited role can / cannot do, shown before joining. Allowed: surface + mint-deep check. Not allowed: surface-2 + lock, ink-muted." |
| AccountRow (23:370) | "Existing account found for this email: initial, email, provider chip." |
| Chip (8:56) | "Audience and milestone chips. Neutral = surface-2 (Chỉ ba mẹ), Warm = peach-soft (memory audience), Sun = sunshine + on-warm (milestone badge). Warm colours only on memory screens." |
| BabySwitcher (45:321) | "Baby switcher chip: avatar + name (+ chevron when the family has more than one baby). Shows whose log you are viewing." |
| QuickLogButton (44:363) | "Ghi nhanh (+): opens the quick-log chooser (Bú · Ngủ · Tã · Tăng trưởng). 68px, accessibility label "Ghi nhanh"." |
| NavBar (44:362) | "Floating tab bar (nav-bar pill, h68, shadow-nav). Each tab shows icon + label (caption) — visible labels beat icon-only for tired parents and for VoiceOver parity. Active tab: nav-active pill, on-nav-active content. Swap the Active variant per screen." |
| TabDock (10:169) | "Tab dock = NavBar + QuickLogButton, 24px above the home indicator. Swap the nested NavBar variant (Active) per tab." |
| Logo/Mark (35:180) | "Child Life logo — Khoảnh khắc: một khung ảnh có nắng và đồi. Color is bound to logo/* variables, so it switches to the night palette automatically in Night care. …" |
| Line icons (all) | "Line icon (24px, 1.8 stroke) — placeholder drawing; production uses SF Symbols." |

---

# Section 1 · Chào mừng & giới thiệu chức năng

## 36:2233 · 00 Splash · Light

**Purpose:** launch and splash screen.

**Annotation (verbatim):**

> "Splash / launch: static launch screen = this layout without the glow (iOS LaunchScreen). In-app splash ≤ 1s: sun rises 8px + fade in (duration-base, ease-out), then crossfade to 01 Chào mừng. Reduce Motion: static logo, crossfade only. Follows system appearance — Night care uses the logo/* night palette."

**Content:**
- Logo mark and wordmark "child life" on a circular glow.
- Tagline: **"Cùng chăm con. Giữ tuổi thơ."** *(Care for the child together. Keep the childhood.)*

**Interactive elements:** none.

**Behavior:**
- Shows for at most 1s, then crossfades to **01 Chào mừng**.
- Respects Reduce Motion and the system dark appearance.
- The native launch screen is the same layout without the glow.

**Native requirements:**
- iOS LaunchScreen and Android 12+ splash API (inferred).
- Reduce Motion setting.

## 26:4 · 01 Chào mừng · Light

**Purpose:** welcome and entry chooser.

**TopBar (Brand variant):**
- Logo lockup.
- Round **Theme toggle** button with a moon icon. Effect: switches Light ↔ Night care (inferred).

**Hero illustration (Illustration/Welcome):**
- Sleeping baby and a duck.
- Chips: "120 ml", "1:24", "Mốc mới" *(new milestone)*.

**Title:** **"Cùng chăm con, / giữ trọn tuổi thơ"** *(Care for the child together, keep the whole childhood)*

**Buttons:**

| Button | Style | Destination (inferred) |
|---|---|---|
| **"Khám phá"** *(Explore)* | Primary | 02 Chăm sóc (feature tour) |
| **"Đăng nhập"** *(Sign in)* | Secondary | 06 Chọn cách đăng nhập |
| **"Mã mời"** *(Invite code)* | Secondary | 15 Nhập mã mời |

**States:** none.

## 26:85 · 02 Chăm sóc · Light (tour 1/4)

- **TopBar:** "Bỏ qua" *(Skip)* text button, top-right. Skips the tour; destination not drawn (inferred: 06 sign-in or 11 profile).
- **Illustration:**
  - Chips: "Bú bình · 120 ml" (check lead = synced/done), "Thay tã · Ướt", "Ngủ · 1 giờ 20".
  - Badge: "3 chạm" *(3 taps)*.
- **Title:** **"Ghi bú, ngủ, tã / chỉ bằng một tay"** *(Log feeding, sleep, diapers one-handed)*
- **Body:** **"Tối đa 3 chạm là lưu xong."** *(At most 3 taps to save.)*
- **Controls:**
  - PageDots at step 1 of 4.
  - Round Next button (64px, arrow). Annotation: "Accessibility label: "Tiếp tục" — icon-only button, VoiceOver đọc "Tiếp tục, nút"."
- **Product promise:** logging takes at most 3 taps.

## 26:151 · 03 Cùng chăm · Light (tour 2/4)

- **Skip:** "Bỏ qua".
- **Illustration/Handover (dark card):**
  - Chip "Đã đồng bộ" *(Synced)*.
  - Ring timer "Đang ngủ" / "01:24:08".
  - Chips "M · Bú bình · 80 ml · Mẹ ghi" and "B · Thay tã · Ướt · Ba ghi".
  - Description: "Shared care: the latest logs, synced for the whole family — each chip reads "what · detail · who logged"."
- **Title:** **"Nhận ca, không cần hỏi"** *(Take over the shift without asking)*
- **Body:** **"Lần ghi gần nhất được đồng bộ cho cả nhà: ai ghi, ghi gì, lúc nào."** *(The latest log is synced to the whole family: who, what, when.)*
- **Controls:** PageDots at 2/4; round Next button.

## 26:211 · 04 Growth Story · Light (tour 3/4)

- **Skip:** "Bỏ qua".
- **Illustration (peach):**
  - Chips "Thẻ kỷ niệm tức thì" *(instant memory card)* and "Nhật ký tuần 8" *(week-8 journal)*.
  - Description: "Growth Story: a photo becomes an instant memory card; each week becomes a journal entry. Warm colours = memories only."
- **Title:** **"Khoảnh khắc / thành chuyện"** *(Moments become stories)*
- **Body:** **"Một ảnh thành thẻ kỷ niệm ngay. Cuối tuần có nhật ký của bé."** *(One photo becomes a memory card instantly. At week's end there's the baby's journal.)*
  - Implies a weekly journal cadence (business rule for the Story feature; inferred).
- **Controls:** PageDots at 3/4; round Next button.

## 26:277 · 05 Chia sẻ riêng tư · Light (tour 4/4)

- **Skip:** "Bỏ qua".
- **Illustration (sun):**
  - Avatars M (star), B, Bà (heart), L (bottle).
  - Chips "Bạn chọn quyền" *(You choose permissions)* (lock) and "Mời người thân" *(Invite relatives)* (+).
  - Description: "Private sharing: invite relatives and choose what each can see or log. Operational details (link expiry) live on the real invite screen."
- **Title:** **"Đúng người, / đúng quyền"** *(Right person, right permission)*
- **Body:** **"Bà được xem ảnh, cô trông trẻ được ghi cữ bú. Bạn quyết định ai thấy gì."** *(Grandma can view photos, the nanny can log feeds. You decide who sees what.)*
- **Primary:** **"Tạo hồ sơ bé"** *(Create baby profile)* replaces the round Next button.
  - Destination: either sign-in (06) first or profile (11) directly. Unclear; see Open questions.
- **Controls:** PageDots at 4/4.

---

# Section 2 · Đăng nhập & xác minh

## 27:488 · 06 Chọn cách đăng nhập · Light

**Purpose:** choose an auth provider.

**Layout:**
- Full-bleed hero (Illustration/SignIn: toy blocks spelling "Bé" plus a heart).
- Button/Back, top-left.
- Bottom sheet with grabber.

**Copy:**
- Title **"Chào bạn"** *(Hello)*
- Sub **"Đăng nhập để bắt đầu."** *(Sign in to start.)*

**Buttons, in order:**
1. **"Tiếp tục với Apple"** (black; apple-button token). Sign in with Apple (native). Per spec: "use Apple's official button in production".
2. **"Tiếp tục với Google"** (outlined). Google Sign-In.
3. **"Dùng email"** *(Use email)* (secondary, mail icon). Goes to 07 Email.

**Footer link:** **"Điều khoản · Quyền riêng tư"** *(Terms · Privacy)*. Opens the legal pages (web/in-app browser; inferred).
- There is no consent checkbox. Legal text is a link only.

**Auth providers shown:** Apple, Google, Email/password. No phone/SMS and no Facebook.

## 27:538 · 07 Email · Light

**Header:** Back. Title **"Email"**.

**Segmented control:** **"Tài khoản mới"** *(New account)* (selected) | **"Đăng nhập"** *(Sign in)*
- Per component: it remembers the last choice.

**Fields (grouped card):**
- "Email", placeholder `ten@email.com`.
- "Mật khẩu" *(Password)*, placeholder **"8+ ký tự"** *(8+ characters)*, with a 32px eye toggle (show/hide).

**Buttons:**
- Primary **"Tạo tài khoản"** *(Create account)*.
  - The label for the "Đăng nhập" segment is not drawn (inferred: "Đăng nhập").
- Plain link **"Email đã dùng với Apple/Google?"** *(Email already used with Apple/Google?)*. Goes to 10 Email đã có tài khoản (inferred).

**Validation shown:**
- Password minimum is **8 characters** (from the placeholder).
- No other password rules are shown.
- No inline error states (invalid email, weak password, wrong password) are drawn.

**Not drawn:**
- The "Quên mật khẩu?" link that leads to 09. It presumably lives on the "Đăng nhập" segment (inferred).
- Loading or disabled state of the button. The global rule is disabled = 40% opacity.

## 27:588 · 08 Xác minh email · Light

- **Header:** Back. Illustration/VerifyEmail (envelope with check).
- **Title:** **"Kiểm tra email"** *(Check your email)*
- **Body:** **"Mình đã gửi link xác minh tới"** *(We sent a verification link to)*, followed by a chip with the address (e.g. `mai.nguyen@email.com`).
- **Buttons:**
  - Primary **"Mở Mail"** *(Open Mail)*. Opens the device mail app (iOS `message://` / Android mail intent; inferred).
  - Plain **"Gửi lại email"** *(Resend email)*.
- **Verification method:** a **link** (not an OTP code).
- **Not drawn:**
  - Resend cooldown or countdown.
  - Sent confirmation and error states.
  - Change-email action. Back is the only route.
- **After verification:** behavior after tapping the link (deep-link return into the app) is not drawn (inferred: universal link → continue to 10a/11).

## 27:634 · 09 Quên mật khẩu · Light

- **Header:** Back. Illustration/Recover (key).
- **Title:** **"Quên mật khẩu"** *(Forgot password)*
- **Body:** **"Nhập email, mình gửi link đặt lại."** *(Enter email, we'll send a reset link.)*
- **Field:** standalone "Email".
- **Primary:** **"Gửi link"** *(Send link)*.
- **Reset method:** an email link (inferred: Firebase password-reset email).
- **Not drawn:** success, error and "account not found" states.

## 27:673 · 10 Email đã có tài khoản · Light

**Purpose:** account-collision / linking flow. The typed email already belongs to an Apple- or Google-provider account.

**Content:**
- Back. Illustration/AccountLink (initial "M" chained to an envelope).
- Title **"Email đã có tài khoản"** *(Email already has an account)*
- Body **"Đăng nhập bằng Apple, rồi liên kết."** *(Sign in with Apple, then link.)*
- AccountRow: avatar "M", `mai.nguyen@email.com`, provider chip **"Apple"**.
  - The provider name is dynamic: Apple or Google (inferred).

**Buttons:**
- Primary **"Tiếp tục với Apple"**. Signs in with the existing provider, then links the email/password credential to the same account (inferred).
- Plain **"Dùng email khác"** *(Use another email)*. Returns to 07.

**Implication:** one person = one account, with multiple linked providers. This requires account linking (Firebase `linkWithCredential`; inferred).

## 115:11756 · 10a Bạn là ai với bé · Light

**Purpose:** capture the user's display name and relationship label to the baby.

**TopBar:** Back plus setup Progress.
- Fill is 208px of a ~271px track, about 77%. That is higher than 11 Hồ sơ bé (50%); see Open questions.

**Copy:**
- Title **"Bạn là ai với bé?"** *(Who are you to the baby?)*
- Sub **"Cả nhà sẽ thấy "Mẹ ghi" trên từng bản ghi."** *(The whole family will see "Mẹ ghi" (logged by Mom) on every record.)*

**Fields:**
- TextField **"Tên của bạn"** *(Your name)*, example "Mai".
- Label **"Bạn là"** *(You are)*.
- RelationChips, single-select: **Mẹ** (selected), **Ba**, **Bà**, **Ông**, **Bảo mẫu**, **Họ hàng**, **Khác…**
  - *(Mom, Dad, Grandma, Grandpa, Nanny, Relative, Other…)*
  - "Khác…" presumably opens free-text entry (inferred; not drawn).

**Primary:** **"Tiếp"** *(Next)*.

**Rule:** the relationship label is shown as attribution on records ("<label> ghi"), e.g. "Mẹ ghi", "Ba ghi", "Cô Lan ghi" (seen on 16c).
- The attribution sometimes uses the relation and sometimes the name; see Open questions.

---

# Section 3 · Tạo hồ sơ bé & giao diện

## 29:721 · 11 Hồ sơ bé · Light

**Purpose:** create the baby profile.

**TopBar:** Back plus Progress (value "50").

**Avatar:** 148px placeholder (Illustration/BabyAvatar) with a camera badge button. Goes to the **11c** sheet.

**Name:**
- Label **"Tên thân mật"** *(Nickname)*.
- Large editable value "Teddy" (inline text edit; inferred).

**Detail rows (with chevrons):**
- **"Ngày sinh"** *(Date of birth)* = "17 tháng 9, 2026". Goes to the **11a** sheet.
- **"Múi giờ"** *(Time zone)* = "GMT+7". Goes to the **11b** sheet.

**Gender:**
- Label **"Giới tính · không bắt buộc"** *(Gender · optional)*.
- Segmented: **"Bé gái"** *(Girl)* (selected) | **"Bé trai"** *(Boy)* | **"Không nêu"** *(Not specified)*.

**Privacy note (lock icon):** **"Người thân chỉ thấy tên thân mật"** *(Relatives only see the nickname)*.
- Implies there may also be a real or legal name that is hidden from relatives (inferred). No full-name field is drawn here.

**Primary:** **"Tiếp"**.

**Data captured:**
- nickname (string, required; inferred)
- avatar (photo or illustrated preset)
- dateOfBirth (date, not in the future)
- timezone
- gender: girl / boy / unspecified (optional)

## 38:1498 · 11a Chọn ngày sinh · Light (sheet over 11)

- **Header:** SheetHeader **"Ngày sinh"** plus close (a11y "Đóng").
- **Picker:** DateWheel with Day · Month · Year. Example selection 17 · "Tháng 9" · 2026.
  - Rows shown: 15–19, Tháng 7–11, 2024–2028.
- **Age hint (cake icon):** **"Teddy được 3 tuần tuổi"** *(Teddy is 3 weeks old)*. Live computed age.
- **Primary:** **"Xong"** *(Done)*.
- **Rules (component):**
  - Native picker in production.
  - Default = today.
  - **Cannot pick a future date.**

## 38:1581 · 11b Chọn múi giờ · Light (sheet over 11)

- **Header:** SheetHeader **"Múi giờ"** plus close.
- **Search:** pill with placeholder **"Tìm thành phố hoặc quốc gia"** *(Search city or country)*.
- **SettingRow (globe):** **"Tự động theo máy"** *(Automatic from device)*, subtitle **"Đang dùng GMT+7 · Việt Nam"** *(Currently using GMT+7 · Vietnam)*, plus Toggle.
  - The toggle is rendered **OFF** in the mock while a manual GMT+7 is selected.
- **Single-select OptionRows with radio:**

| Option | Cities shown |
|---|---|
| GMT+7 (selected) | "Hà Nội, TP. Hồ Chí Minh, Bangkok" |
| GMT+8 | "Singapore, Kuala Lumpur, Đài Bắc" |
| GMT+9 | "Tokyo, Seoul" |
| GMT+10 | "Sydney, Melbourne" |
| GMT+1 | "Paris, Berlin" |
| GMT−5 | "New York, Toronto" |

- **Primary:** **"Xong"**.
- **Native:** reads the device time zone.
- **Data:** baby.timezone, plus possibly a flag for "auto from device" (inferred).
- See Open questions: fixed offsets vs IANA zones (DST).

## 41:1861 · 11c Chọn ảnh đại diện · Light (sheet over 11; read via Sheet 41:1887)

- **Header:** SheetHeader **"Ảnh đại diện"** *(Avatar)* plus close.
- **Action rows:**
  - **"Chụp ảnh"** *(Take photo)*. Camera; needs camera permission.
  - **"Chọn từ thư viện"** *(Choose from library)*. Photo picker; needs photo-library access (PHPicker / Android Photo Picker; inferred).
- **Caption:** **"Hoặc chọn hình minh họa"** *(Or choose an illustration)*.
- **Illustrated avatars:** 4 presets (mint/teal, peach, sun, night). Single-select; the selected one gets a ring and a check.
- **Privacy (lock):** **"Chỉ người trong gia đình xem được ảnh này."** *(Only people in the family can see this photo.)*
  - The profile photo is private to members. It must be stored in private Storage (inferred).
- **Primary:** **"Xong"**.
- **Not drawn:** crop UI and permission-denied states.

## 29:795 · 12 Chọn theo dõi · Light

**TopBar:** Back plus Progress (~77%).

**Copy:**
- Title **"Theo dõi gì?"** *(Track what?)*
- Sub **"Đổi lại lúc nào cũng được."** *(You can change this anytime.)*

**Multi-select tiles (2×2, all selected in mock):** **Bú bình** *(Bottle)*, **Bú mẹ** *(Breastfeeding)*, **Giấc ngủ** *(Sleep)*, **Thay tã** *(Diaper)*

**Full-width rows (radio-style control, unselected in mock):** **"Hút sữa"** *(Pumping)*, **"Tăng trưởng"** *(Growth)*
- These are probably also multi-select toggles (inferred).

**Primary:** **"Xong · 4 mục"** *(Done · 4 items)*. The counter reflects the number of selected trackers.

**Data:** baby.trackers = subset of {bottle, breast, sleep, diaper, pump, growth}.
- Defaults: the first four ON; pump and growth OFF (as mocked).
- Whether at least one tracker must be selected is not drawn; see Open questions.

## 29:1063 · 13 Giao diện · Light

- **TopBar:** Back only. There is **no progress bar and no primary/continue button**.
- **Title:** **"Giao diện"** *(Appearance)*
- **Theme options (radio):** **"Sáng"** *(Light)* (selected) | **"Tối"** *(Dark)* | **"Tự động"** *(Automatic)*. Each has a mini preview.
- **SettingRow (night tile):** **"Night care"** / **"Theo lịch 21:00 – 06:00"** *(On schedule 21:00–06:00)*, Toggle **ON**.
  - Component default subtitle: "Tự tối khi ghi sau 21:00" *(auto-dark when logging after 21:00)*.
- **Section "Lịch Night care"** *(Night care schedule)*, DetailRows:
  - **"Bật lúc"** *(Turn on at)* 21:00 >
  - **"Tắt lúc"** *(Turn off at)* 06:00 >
  - Both lead to the 13a sheet.
- **Hint:** **"Ngoài lịch, Night care vẫn tự bật khi bạn bắt đầu timer ngủ."** *(Outside the schedule, Night care still auto-enables when you start a sleep timer.)*
- **Footer:** **"Áp dụng ngay cho cả app"** *(Applies immediately to the whole app)*. No save button; changes are live.
- **Night variant 29:1375:** identical, except **"Tối"** is selected. This suggests that "Tối" uses the Night care palette (inferred).
- **Data (per device or per user; unknown):**
  - theme ∈ {light, dark, auto}
  - nightCare.enabled (bool)
  - nightCare.start (HH:mm)
  - nightCare.end (HH:mm)
  - auto-on when a sleep timer starts (rule)

## 43:2067 · 13a Lịch Night care · Light (extra; read via Sheet 43:2092)

- **Header:** SheetHeader **"Lịch Night care"** plus close.
- **Segmented:** **"Bật lúc · 21:00"** (selected) | **"Tắt lúc · 06:00"**. Edits one end of the window at a time.
- **Picker:**
  - Column labels **"Giờ"** *(Hour)* and **"Phút"** *(Minute)*.
  - TimeWheel: hours shown 19–23 (21 selected); minutes in **5-minute steps** (50, 55, 00, 05, 10).
- **Preset chips:** 20:00, **21:00** (highlighted), 22:00, 23:00.
- **Duration hint:** **"Night care trong 9 giờ, đến 06:00 sáng"** *(Night care for 9 hours, until 06:00 am)*. Computed and spans midnight.
- **Primary:** **"Xong"**.

---

# Section 4 · Gia đình & mời người

## 116:11226 · 14a Gia đình · Light (Family tab)

**Frame annotation (verbatim):**

> "Thẻ lớn = vừa ghi vừa xem: chạm thẻ → mở sheet ghi mục đó (1 chạm); dòng dưới là lần cuối (bao lâu trước · chi tiết · ai ghi). Ngủ khi timer chạy → CareTile Tone=Active hiện thời gian đang chạy. Tăng trưởng: hàng riêng, + mở màn nhập số đo. "Lịch sử" → dòng thời gian."

- This annotation describes the Today care tiles and appears to have been copied onto this Family frame (and onto 14f, 16c, 16d). It is **not** about the family list; see Open questions.

**Header:**
- BabySwitcher **"Teddy · 3 tuần"** with chevron. Switches baby; the chevron appears only with more than one baby.
- **Night care toggle** round button (sleep icon). Quick manual Night care on/off (inferred).

**Copy:**
- Sub **"Những người cùng chăm Teddy"** *(People caring for Teddy)*
- Title **"Gia đình"** *(Family)*

**Members card.** Each row shows avatar initial, name, and "relationship · role".

| Name | Detail | Trailing |
|---|---|---|
| Mai | "Mẹ · Cùng nuôi" | badge **"Bạn"** *(You)*, no chevron |
| Minh | "Ba · Cùng nuôi" | chevron → 14f sheet |
| Cô Lan | "Bảo mẫu · Người chăm sóc" | chevron |
| Bà nội Hoa | "Bà · Người thân" | chevron |

**Pending invites:**
- Section **"Đang chờ nhận lời (1)"** *(Awaiting acceptance (1))*.
- Pending row: avatar "?", **"ba.ngoai@gmail.com"**, detail **"Bà ngoại · hết hạn 15 thg 10"** *(Maternal grandma · expires 15 Oct)*, chip **"Gửi lại"** *(Resend)*.

**Primary:** (+) **"Mời người cùng chăm"** *(Invite a co-carer)*. Goes to 14b.

**TabDock:**
- Tabs: Today | Memories | **Gia đình** (active, labelled) | Me (avatar).
- QuickLog (+) button.

**States shown:** member list, pending list (count 1), resend.

**Not drawn:**
- Empty family.
- Revoking or cancelling a pending invite.
- A non-parent's view of this tab (role-based); see Open questions.

## 116:11916 · 14b Mời · Vai trò & quyền · Light

**TopBar:** Back plus Progress.

**Copy:**
- Title **"Mời người cùng chăm"** *(Invite a co-carer)*
- Sub **"Chọn người đó là ai và được làm gì."** *(Choose who they are and what they can do.)*

**Relationship:**
- Label **"Người được mời là"** *(The invitee is)*.
- RelationChips, single-select: **Ba, Bà** (selected), **Ông, Bảo mẫu, Họ hàng, Bạn bè** *(Friend)*, **Khác…**
- "Mẹ" is absent and "Bạn bè" is added compared with 10a.

**Role:**
- Label **"Quyền"** *(Permission / role)*.
- OptionRows, single-select radio:

| Role | Subtitle (verbatim) | Gloss |
|---|---|---|
| **Cùng nuôi** | "Toàn quyền, như ba mẹ" | *Full rights, like parents* |
| **Người chăm sóc** (selected) | "Ghi & xem chăm sóc" | *Log & view care* |
| **Người thân** | "Xem kỷ niệm, chọn thêm quyền xem" | *View memories, choose extra view rights* |

**Buttons:**
- Plain **"Xem chi tiết quyền"** *(See permission details)*. Opens the permission sheet (14b2 for Người thân; inferred).
- Primary **"Tiếp · Gửi lời mời"** *(Next · Send invite)*. Goes to 14c.

**Notes:**
- No invitee name, email or phone field on this screen. The email is captured later in the "Email" tab of 14c (not drawn).
- The mock pairs **relation "Bà" with role "Người chăm sóc"**. This confirms that relationship and role are independent.

## 121:11672 · 14b2 Quyền Người thân · Light (sheet over 14b; relation "Họ hàng", role "Người thân")

- **Header:** SheetHeader **"Quyền của Người thân"** *(Relative's permissions)* plus close.
- **Fixed banner (check):** **"Luôn có: xem kỷ niệm, thả tim"** *(Always: view memories, react with heart)*.
- **Label:** **"Cho xem thêm"** *(Allow viewing more)*.
- **Toggles (SettingRows):**

| Toggle | Subtitle | Gloss | Mock state |
|---|---|---|---|
| **"Thông tin bé"** | "Ngày sinh, cân nặng" | *Baby info: DOB, weight* | ON |
| **"Chăm sóc hằng ngày"** | "Bú, ngủ, tã · chỉ xem" | *Daily care: feeds, sleep, diapers · view only* | OFF |

- **Primary:** **"Xong"**.
- **Data:** invite.role = relative, plus permission flags `viewBabyInfo`, `viewDailyCare`. The defaults may simply be the mock state (open question).

## 117:11435 · 14c Mời · Gửi lời mời (QR) · Light

**TopBar:** Back plus Progress.

**Copy (personalized by relation):**
- Title **"Gửi lời mời cho Bà"** *(Send invite to Grandma)*
- Sub **"Bà mở camera điện thoại và quét mã."** *(Grandma opens her phone camera and scans the code.)*
  - Scanned with the **native OS camera**, so the QR must encode an https universal/app link (inferred).

**Summary banner:** **"Bà · Người chăm sóc"** plus link **"Đổi"** *(Change)*. Returns to 14b.

**Channel segmented control:** **"Mã QR"** (selected) | **"Link"** | **"Email"**
- The Link and Email tab contents are **not drawn**.

**QR card:**
- QR code (200px) with the app icon in the center.
- **"Hoặc nhập mã"** *(Or enter code)*.
- Code **"482 913"**: 6 digits, displayed 3+3.
- **"Hết hạn sau 7 ngày"** *(Expires in 7 days)*.

**Buttons:**
- Primary **"Chia sẻ lời mời"** *(Share invite)*. Opens the native share sheet (inferred).
- Plain **"Bà không quét được?"** *(Grandma can't scan?)*. Opens the 14c2 sheet.

## 121:12549 · 14c2 Không quét được · Light (sheet over 14c; read via Sheet 121:12577)

- **Header:** SheetHeader **"Bà không vào được?"** *(Grandma can't get in?)* plus close.
- **Steps:**
  1. **"Mở app Child Life, chọn "Tôi có mã mời""** *(Open the Child Life app, choose "I have an invite code")*
  2. **"Nhập mã 482 913"** *(Enter code 482 913)*
  3. **"Vẫn lỗi? Tạo mã mới bên dưới"** *(Still failing? Create a new code below)*
- **Buttons:**
  - Secondary **"Tạo mã mới"** *(Create new code)*. Regenerates the code. Whether the old code is invalidated is unknown (inferred: yes).
  - Plain **"Gửi qua email thay thế"** *(Send by email instead)*. Goes to the Email channel.
- **Copy mismatch:** step 1 references the button "Tôi có mã mời", but the welcome screen button is labelled **"Mã mời"**.

## 117:12007 · 14d Mời · Đã gửi · Light

- **Header:** Back. Illustration/InviteCode (ticket labelled "Bà").
- **Title:** **"Đã gửi email cho Bà"** *(Email sent to Grandma)*
- **Sub:** `ba.ngoai@gmail.com`
- **Buttons:**
  - Primary **"Xong"**. Returns to 14a with a new pending row (inferred).
  - Plain **"Bà không nhận được?"** *(Grandma didn't receive it?)*. Destination not drawn.
- **Side effect:** the server sends a transactional invite email (see 14e).

## 118:11494 · 14e Email lời mời · Light (mock of the recipient's mail client)

**Mail header:**
- Back "‹ Hộp thư" *(Inbox)*.
- Subject **"Mai mời bạn cùng chăm Teddy"** *(Mai invites you to care for Teddy together)*.
- From **"Child Life"**, `hello@childlife.app · đến ba.ngoai@gmail.com`; time 15:06.

**Email body:**
- Child Life logo lockup.
- Illustration (inviter initial plus baby).
- H1 **"Mai mời bạn cùng chăm Teddy"**.
- **"Vai trò: Người chăm sóc"** *(Role: Caregiver)*. Shows the role, not the relation.
- CTA button **"Nhận lời mời"** *(Accept invite)*. Universal link that opens the app at 16 Nhận lời mời, or a web fallback (inferred).
- **"Hoặc nhập mã trong app · hết hạn 15 thg 10"** *(Or enter the code in the app · expires 15 Oct)*.
- Code box **"482 913"**. Same code as the QR, so one invite has one code across channels.
- Divider.
- **"Không quen người gửi? Bỏ qua email này."** *(Don't know the sender? Ignore this email.)*
- Footer **"Child Life · Riêng tư cho gia đình · Huỷ nhận email"** *(Private for families · Unsubscribe)*. An unsubscribe link is required.

**Native/infra requirements:**
- Transactional email provider with sender `hello@childlife.app`.
- Universal Links / App Links.
- Possibly a web landing page for users without the app (inferred).

## 118:12056 · 14f Thành viên · Đổi quyền · Light (sheet over 14a)

**Background:** same as 14a, plus a footnote under the invite button:
> **"Người được mời chỉ thấy những gì bạn cho phép. Bạn có thể đổi quyền hoặc xoá bất cứ lúc nào."** *(Invitees only see what you allow. You can change permissions or remove them anytime.)*

**Sheet:**
- SheetHeader **"Cô Lan"** plus close.
- Meta **"Bảo mẫu · tham gia 20 thg 9 · đã ghi 46 lần"** *(Nanny · joined 20 Sep · logged 46 times)*. Relation, join date and record count.
- Label **"Quyền"**. OptionRows, single-select:

| Role | Subtitle (verbatim) | Gloss |
|---|---|---|
| **Cùng nuôi** | "Toàn quyền như ba mẹ" | *Full rights like parents* |
| **Người chăm sóc** (selected) | "Ghi & xem chăm sóc, không mời người" | *Log & view care, cannot invite people* |
| **Người thân** | "Chỉ xem kỷ niệm được chia sẻ" | *Only view shared memories* |

- DetailRow (clock) **"Thời hạn"** *(Duration / validity)* = **"Đến 31 tháng 12, 2026"** *(Until 31 Dec 2026)*. **Membership access can expire.** The picker is not drawn.
- DetailRow (pencil) **"Là ai với bé"** *(Relation to baby)* = "Bảo mẫu". Edits the relation label.
- Destructive tinted button **"Xoá Cô Lan khỏi gia đình"** *(Remove Cô Lan from family)*.
- Caption **"Bản ghi của Cô Lan vẫn được giữ."** *(Cô Lan's records are kept.)*

**Not drawn:**
- A confirmation dialog for removal.
- A Save button. Changes apply immediately (inferred).
- Changing the role to Người thân does not show the extra-permission toggles here (open question).

---

# Section 4b · Nhận lời mời

## 30:1222 · 15 Nhập mã mời · Light

- **Header:** Back. Illustration/InviteCode.
- **Title:** **"Nhập mã mời"** *(Enter invite code)*
- **Sub:** **"6 số trong lời mời, hoặc quét mã QR."** *(The 6 digits in the invite, or scan the QR code.)*
- **CodeInput:** a single wide-tracked field, e.g. "482913". Numeric keyboard (inferred).
- **Primary:** **"Tiếp tục"** *(Continue)*. Validates the code server-side, then goes to 16 (valid) or 17 (expired).
- **Plain with camera icon:** **"Quét mã QR"** *(Scan QR code)*. In-app QR scanner; needs camera permission.
- **Conflict:** the CodeInput component description says "10 characters … Auto-uppercase", but the screen copy and codes are 6 digits.
- **Not drawn:** wrong-code error, rate-limit/lockout, loading, already-a-member.

## 30:1259 · 16 Nhận lời mời · Light

**TopBar (Back+Countdown):** clock chip **"Còn 68 giờ"** *(68 hours left)*. Time remaining on the invite, at hour granularity.

**Illustration:** inviter initial "M" plus baby.

**Copy:**
- Title **"Mẹ Mai mời bạn"** *(Mom Mai invites you)*. Format: relation + inviter name.
- **"cùng chăm bé Teddy với vai trò"** *(to care for baby Teddy in the role of)* followed by chip **"Người chăm sóc"**.

**PermissionTiles (preview of the role's rights):**
- Allowed (check): **"Ghi bú, ngủ, tã"** *(Log feeds, sleep, diapers)*, **"Xem lịch"** *(View schedule/calendar)*, **"Xem nhắc việc"** *(View reminders)*
- Not allowed (lock): **"Kỷ niệm"** *(Memories)*

**Buttons:**
- Primary **"Tham gia"** *(Join)*. Opens the 16b sheet.
- Plain **"Không phải tôi"** *(Not me)*. Wrong-recipient path; destination not drawn.

## 123:12571 · 16b Chọn cách vào · Light (sheet over 16)

**Background inconsistency:**
- The background is 16, but its tiles read: allowed "Ghi bú, ngủ, tã", "Xem lịch", **"Xem kỷ niệm"**; locked **"Mời người khác"** *(Invite others)*.
- This conflicts with 16, where "Xem nhắc việc" is allowed and "Kỷ niệm" is locked. It is likely a stale default label on a component instance.

**Sheet:**
- SheetHeader **"Vào gia đình Teddy"** *(Enter Teddy's family)* plus close.
- Body **"Không cần tạo tài khoản. Có thể lưu lại sau."** *(No account needed. You can save it later.)*
- Primary **"Vào ngay"** *(Enter now)*. Joins with a temporary/anonymous identity (inferred: Firebase anonymous auth).
- Divider **"hoặc lưu tài khoản ngay"** *(or save an account now)*.
- **"Tiếp tục với Apple"**
- **"Tiếp tục với Google"**
- **No email option on this sheet**, although 16d offers email.

## 118:12227 · 16a Xác nhận vai trò · Light

**TopBar:** Back plus Progress.

**Copy:**
- Title **"Bạn là ai với Teddy?"** *(Who are you to Teddy?)*
- Sub **"Mai đã chọn "Bà". Đổi nếu chưa đúng."** *(Mai chose "Grandma". Change it if it's wrong.)*

**Fields:**
- TextField **"Tên của bạn"** = "Hoa".
- "Bạn là" chips: Mẹ, Ba, **Bà** (pre-selected from the invite), Ông, Bảo mẫu, Họ hàng, Khác…

**Primary:** **"Vào xem Teddy"** *(Go see Teddy)*. Goes to Today.

**Rules:**
- The invitee can change the **relation label** but not the **role**.
- The display name is captured at join.

**Order in flow:** 16 → 16b (Vào ngay) → 16a → 16c (inferred from frame order and labels).

## 123:12623 · 16c Hôm nay · Chưa lưu tài khoản · Light

**Frame annotation:** the same Today annotation quoted under 14a (verbatim).

**Header:** BabySwitcher "Teddy · 3 tuần" and Night care toggle.

**Save banner (sunshine-soft, cloud-off icon):** **"Chưa lưu tài khoản"** *(Account not saved)* with action **"Lưu"** *(Save)*. Opens the 16d sheet.
- Shown persistently while the identity is temporary (inferred).

**Today content (context for other agents):**
- Date "Thứ Năm, 8 tháng 10" *(Thursday, 8 October)*; title "Hôm nay" *(Today)*.
- CareTiles:

| Tile | Value | When | Who |
|---|---|---|---|
| Bú bình | 120 ml | 45 phút trước | Mẹ ghi |
| Bú mẹ | 15 phút | Kết thúc 3 giờ 35 phút trước | Mẹ ghi |
| Giấc ngủ | Đã thức 2 giờ | Dậy lúc 13:05 | Ba ghi |
| Thay tã | Tã ướt | 1h 25p trước | Cô Lan ghi |
| Hút sữa | 90 ml | 2 giờ trước | Mẹ ghi |
| Tăng trưởng | 4,3 kg | 54,5 cm | +0,4 kg · hôm nay |

- ReminderPeek: "Nhắc việc · 3" / "Tiêm 6 trong 1" / "Thứ Bảy 08:30 · còn 2 ngày".
- "Hôm nay" section with link "Lịch sử".
- DayRhythm "Đã ghi hôm nay" totals: "2 cữ · 240 ml", "1 cữ · 15 phút", "Ngủ (đã xong) 7 giờ 50", "2 lần", plus a 24h strip.
  - Component description: "Running sleep is not counted until it ends."
- TabDock with Today active ("Hôm nay").

**Inconsistency for a caregiver guest (Hoa):**
- The Memories tab is visible.
- The Me avatar shows "M".
- Pump and Growth tiles are shown.
- This is probably a reused parent Today mock. Role-based UI must hide what the role cannot access (per 16 PermissionTiles: Memories locked).

## 123:12712 · 16d Lưu tài khoản · Light (sheet over 16c)

- **Header:** SheetHeader **"Lưu tài khoản"** *(Save account)* plus close.
- **Body:** **"Để không mất Teddy khi đổi máy hoặc cài lại app."** *(So you don't lose Teddy when changing phones or reinstalling the app.)*
- **Buttons:**
  - **"Tiếp tục với Apple"**
  - **"Tiếp tục với Google"**
  - **"Dùng email"** (secondary)
  - Plain **"Để sau"** *(Later)*
- **Mechanic:** upgrade the anonymous user to a permanent one by linking a credential.
  - Membership and records must be preserved (product plan).
  - If the credential already belongs to an existing account, a merge/collision path is needed. It is not drawn.
- **Not drawn:** success confirmation; banner disappearance.

## 30:1346 · 17 Lời mời hết hạn · Light

- **Header:** Back. Illustration/Expired. Component description: "Invite expired: calm hourglass on surface-2 — no alarm colours."
- **Title:** **"Lời mời đã hết hạn"** *(The invite has expired)*
- **Body:** **"Nhờ người mời gửi link mới nhé."** *(Ask the inviter to send a new link.)*
- **Buttons:**
  - Primary **"Nhập mã khác"** *(Enter another code)*. Goes to 15.
  - Secondary **"Về trang đầu"** *(Back to start)*. Goes to 01.
- **States covered:** expired.
- **Not designed:** revoked, already used, invalid.

---

# Flow summary (inferred from frame order and copy)

1. **New parent, part 1:** 00 Splash → 01 Chào mừng.
   - "Khám phá" → 02 → 03 → 04 → 05.
   - "Bỏ qua" skips the tour.
   - "Tạo hồ sơ bé" → 06 Chọn cách đăng nhập.
2. **New parent, part 2:** 06 → (Apple | Google | Email 07 → 08 verify link) → 10a Bạn là ai với bé → 11 Hồ sơ bé (+ 11a / 11b / 11c sheets) → 12 Chọn theo dõi → 13 Giao diện? → 18 Today first-run (other section).
3. **Email collision:** 07 → 10 Email đã có tài khoản → sign in with the existing provider and link.
4. **Returning user:** 01 "Đăng nhập" → 06 → 07 ("Đăng nhập" tab) → 09 Quên mật khẩu if needed.
5. **Invite (parent):**
   1. 14a → "Mời người cùng chăm" → 14b (relation + role [+ 14b2 extra view rights for Người thân]) → 14c (QR / Link / Email; 6-digit code; 7-day expiry; share sheet; 14c2 help / regenerate).
   2. Email channel → 14d sent; the recipient gets 14e.
   3. A pending row appears on 14a with "Gửi lại".
   4. Manage a member → 14f (change role, access expiry, relation; remove).
6. **Invitee:**
   1. QR (native camera) / email CTA / link → 16 Nhận lời mời. Alternatively 01 "Mã mời" → 15 Nhập mã mời (or in-app QR scan) → 16.
   2. 16 "Tham gia" → 16b: "Vào ngay" (anonymous) or Apple/Google → 16a confirm name + relation → 16c Today with "Chưa lưu tài khoản" banner → "Lưu" → 16d (Apple/Google/Email/Để sau).
   3. Expired → 17.

---

# Business rules confirmed by design (verbatim evidence)

1. **Auth providers are Apple, Google and email/password.** Evidence: 06 buttons "Tiếp tục với Apple", "Tiếp tục với Google", "Dùng email". The Apple button must be official (Button and brand-mark descriptions).
2. **Password minimum is 8 characters.** Evidence: 07 placeholder "8+ ký tự".
3. **Email verification uses a link.** Evidence: 08 "Mình đã gửi link xác minh tới"; actions "Mở Mail" and "Gửi lại email".
4. **Password reset uses an emailed link.** Evidence: 09 "Nhập email, mình gửi link đặt lại." with "Gửi link".
5. **Provider collision is resolved by linking accounts.** Evidence: 10 "Email đã có tài khoản" / "Đăng nhập bằng Apple, rồi liên kết."
6. **Relationship label is distinct from role; records are attributed by label.** Evidence: 10a "Cả nhà sẽ thấy "Mẹ ghi" trên từng bản ghi."; 14b example "Bà" + "Người chăm sóc"; member detail format "Bảo mẫu · Người chăm sóc".
7. **Relationship options.**
   - Self (10a / 16a): Mẹ, Ba, Bà, Ông, Bảo mẫu, Họ hàng, Khác…
   - Invitee (14b): Ba, Bà, Ông, Bảo mẫu, Họ hàng, Bạn bè, Khác…
8. **Relatives see only the baby's nickname.** Evidence: 11 "Người thân chỉ thấy tên thân mật".
9. **Gender is optional.** Evidence: 11 "Giới tính · không bắt buộc" with Bé gái / Bé trai / Không nêu.
10. **Date of birth cannot be in the future and defaults to today.** Evidence: DateWheel description "default = today, cannot pick a future date". Age is shown live ("Teddy được 3 tuần tuổi").
11. **The baby has a time zone, auto or manual.** Evidence: 11b "Tự động theo máy" / "Đang dùng GMT+7 · Việt Nam" and the offset list.
12. **The baby photo is family-private.** Evidence: 11c "Chỉ người trong gia đình xem được ảnh này."
13. **Trackers are selectable and changeable later.** Evidence: 12 "Theo dõi gì?" / "Đổi lại lúc nào cũng được." with the counter "Xong · 4 mục".
14. **Theme options and Night care schedule.** Evidence: 13 Sáng / Tối / Tự động; "Night care" "Theo lịch 21:00 – 06:00"; "Ngoài lịch, Night care vẫn tự bật khi bạn bắt đầu timer ngủ."; "Áp dụng ngay cho cả app". 13a has minutes in 5-minute steps and presets 20:00–23:00.
15. **The three roles, with their stated rights.**
   - Evidence 14b: Cùng nuôi "Toàn quyền, như ba mẹ"; Người chăm sóc "Ghi & xem chăm sóc"; Người thân "Xem kỷ niệm, chọn thêm quyền xem".
   - Evidence 14f: Người chăm sóc "Ghi & xem chăm sóc, không mời người"; Người thân "Chỉ xem kỷ niệm được chia sẻ".
16. **Người thân base rights plus two optional view toggles.** Evidence: 14b2 "Luôn có: xem kỷ niệm, thả tim"; "Thông tin bé · Ngày sinh, cân nặng"; "Chăm sóc hằng ngày · Bú, ngủ, tã · chỉ xem".
17. **Caregiver preview of rights.** Evidence 16: allowed "Ghi bú, ngủ, tã", "Xem lịch", "Xem nhắc việc"; locked "Kỷ niệm". Evidence 16b: locked "Mời người khác".
18. **Invite channels and code.**
   - Channels are QR / Link / Email (14c segmented control).
   - The code is **6 digits** ("482 913"; 15 "6 số trong lời mời").
   - The same code appears in the email (14e).
19. **Invites expire after 7 days.**
   - Evidence: 14c "Hết hạn sau 7 ngày"; pending row "hết hạn 15 thg 10"; email "hết hạn 15 thg 10".
   - Countdown on accept screen: "Còn 68 giờ".
   - Expired screen 17: "Lời mời đã hết hạn" / "Nhờ người mời gửi link mới nhé."
20. **Invites can be resent and the code can be regenerated.** Evidence: 14a "Gửi lại"; 14c2 "Tạo mã mới", "Gửi qua email thay thế".
21. **Invites show as pending until accepted.** Evidence: 14a "Đang chờ nhận lời (1)".
22. **Invite email content.** Subject "Mai mời bạn cùng chăm Teddy"; sender `hello@childlife.app`; CTA "Nhận lời mời"; role line; code; "Không quen người gửi? Bỏ qua email này."; "Huỷ nhận email".
23. **Members' roles and relations are editable, members are removable, and their records are kept.** Evidence: 14f role radio, "Là ai với bé", "Xoá Cô Lan khỏi gia đình", "Bản ghi của Cô Lan vẫn được giữ."; footnote "Bạn có thể đổi quyền hoặc xoá bất cứ lúc nào."
24. **Membership can be time-limited.** Evidence: 14f "Thời hạn · Đến 31 tháng 12, 2026".
25. **Members show join date and activity count.** Evidence: 14f "tham gia 20 thg 9 · đã ghi 46 lần".
26. **"Enter now, save account later".** Evidence: 16b "Không cần tạo tài khoản. Có thể lưu lại sau." / "Vào ngay"; 16c banner "Chưa lưu tài khoản · Lưu"; 16d "Để không mất Teddy khi đổi máy hoặc cài lại app." with Apple / Google / Email / "Để sau".
27. **The invitee confirms their name and can change the relation.** Evidence: 16a "Mai đã chọn "Bà". Đổi nếu chưa đúng."
28. **Wrong-recipient escape exists.** Evidence: 16 "Không phải tôi".
29. **Multi-baby switching.** Evidence: BabySwitcher shows a chevron "when the family has more than one baby".
30. **Splash timing and accessibility.** Evidence: in-app splash ≤ 1s; Reduce Motion; icon-only buttons need labels ("Tiếp tục", "Quay lại", "Đóng", "Ghi nhanh").
31. **Logging speed promise.** Evidence: 02 "Tối đa 3 chạm là lưu xong."
32. **Weekly journal cadence.** Evidence: 04 "Cuối tuần có nhật ký của bé."

---

# Entities & fields implied

**User / Account**
- uid
- providers[] ∈ {apple, google, password}
- email
- emailVerified
- isAnonymous (temporary identity from "Vào ngay")
- displayName ("Tên của bạn")
- appearance prefs (may be per device):
  - theme ∈ {light, dark, auto}
  - nightCare {enabled, start HH:mm, end HH:mm, autoOnSleepTimer=true}

**Baby (profile)**
- babyId
- familyId
- nickname ("Tên thân mật", visible to all members)
- (possible private full name; not drawn)
- avatar: {type: photo | illustration, presetId | storagePath}
- dateOfBirth (date ≤ today)
- gender ∈ {girl, boy, unspecified} (optional)
- timezone {mode: auto | manual, zone/offset}
- trackers[] ⊆ {bottle, breast, sleep, diaper, pump, growth}

**Family**
- familyId
- babies[]
- members[]
- pending invites
- (owner unknown; 10 GB quota from the plan)

**Membership** (per baby, or per family; see Open questions)
- uid
- babyId / familyId
- role ∈ {coParent "Cùng nuôi", caregiver "Người chăm sóc", relative "Người thân"}
- relationLabel ∈ {Mẹ, Ba, Bà, Ông, Bảo mẫu, Họ hàng, Bạn bè, Khác(custom text)}
- extraPermissions (relative only) {viewBabyInfo, viewDailyCare}
- accessUntil (date, optional: "Thời hạn")
- joinedAt
- recordCount (derived)
- invitedBy
- status

**Invite**
- inviteId
- familyId / babyId
- inviterUid (+ inviter display "Mẹ Mai")
- relationLabel
- role
- extraPermissions
- code (6 digits, unique while active)
- deep link / QR payload
- channel(s) ∈ {qr, link, email}
- recipientEmail (email channel)
- createdAt
- expiresAt (+7 days)
- status ∈ {pending, accepted, expired, revoked/regenerated}
- resendCount / lastSentAt (inferred)

**EmailOutbox / transactional email**
- invite emails from `hello@childlife.app`
- unsubscribe preference ("Huỷ nhận email")

**Record attribution**
- createdBy uid, rendered as "<relationLabel or name> ghi"

---

# Native capabilities required (from these screens)

- **Auth SDKs:**
  - Sign in with Apple (official button).
  - Google Sign-In.
  - Email/password with email-link verification and reset.
  - Anonymous auth with later credential linking.
- **Universal Links / Android App Links:**
  - Invite CTA in email.
  - QR scanned by the native camera.
  - Email verification and reset links.
- **Mail app intent:** "Mở Mail".
- **Camera:**
  - Avatar "Chụp ảnh".
  - In-app QR scanning "Quét mã QR".
- **Photo library / picker:** "Chọn từ thư viện".
- **Native share sheet:** "Chia sẻ lời mời".
- **Device time zone:** "Tự động theo máy".
- **Native date and time pickers:** DateWheel (specified as native); TimeWheel.
- **OS appearance and Reduce Motion:** splash, theme "Tự động".
- **Launch screen:** iOS LaunchScreen and Android splash.

---

# Open questions / gaps

1. **26:277 / 26:4: order of auth vs profile.** Does "Tạo hồ sơ bé" (05) require sign-in (06) first, or can a profile be created before an account exists? Where does "Khám phá" end, and where does "Bỏ qua" go?
2. **115:11756 / 29:721 / 29:795: setup order.** Progress values conflict: 10a ≈ 77%, 11 = 50%, 12 ≈ 77%, and 14b / 14c / 16a also ≈ 77% (same fill). Is 10a shown before or after the baby profile? Is the Progress instance just left at a default?
3. **29:1063: is 13 Giao diện part of onboarding?** It has no progress bar and no continue button, only Back plus "Áp dụng ngay cho cả app". It may be a settings screen. What follows 12 "Xong · 4 mục": Today first-run (18)?
4. **27:538: incomplete email screen.**
   - The "Đăng nhập" segment state, the "Quên mật khẩu?" entry point, and error states (invalid email, weak password, wrong password, too many attempts) are not drawn.
   - The only password rule is "8+ ký tự". Are there complexity rules?
5. **27:588: verification gating and resend.** Resend cooldown, verification-link landing, and whether an unverified email blocks app use are not specified.
6. **27:673: provider-name logic.** The chip says "Apple". Should it dynamically show Google when relevant? What happens if the existing account is email/password and the user tried Apple or Google (reverse collision)?
7. **30:1222 vs CodeInput 23:355: code format.** The component says "10 characters … Auto-uppercase"; the screens say 6 digits. Which is authoritative? The screens suggest 6 digits. What are the brute-force limits?
8. **117:11435: unseen channel tabs.** The "Link" and "Email" tab contents of 14c (email input field, copy link) are not drawn. Is the email recipient captured there?
9. **121:12549: code regeneration and copy mismatch.**
   - Does "Tạo mã mới" invalidate the previous code and QR? Does it reset the 7-day expiry?
   - Copy references a button "Tôi có mã mời", but 01 shows "Mã mời".
10. **117:12007: dead-end link.** The destination of "Bà không nhận được?" is not drawn.
11. **30:1259: wrong-person flow.** The destination of "Không phải tôi" is not drawn. Does it decline the invite, notify the inviter, or just exit?
12. **123:12571 / 30:1259: caregiver rights.** The PermissionTiles conflict: 16 shows "Xem nhắc việc ✓, Kỷ niệm 🔒" while 16b's background shows "Xem kỷ niệm ✓, Mời người khác 🔒". Need the authoritative capability list per role.
13. **123:12571 vs 123:12712: email at join.** 16b offers only Apple and Google to save an account at join time, while 16d also offers "Dùng email". Is email intentionally omitted at join?
14. **123:12623: role-based UI for guests.** The guest caregiver Today shows the Memories tab, pump and growth tiles, and avatar "M". Which tabs and tiles should a caregiver or relative actually see? The anonymous banner's behavior after "Để sau" (persist? reminder cadence?) is unspecified.
15. **123:12712: anonymous upgrade collision.** What happens if the chosen Apple/Google/email credential already has an account? Merge memberships? Data-preservation rules are required by the plan but not drawn.
16. **118:12056: membership changes.**
    - The "Thời hạn" (access expiry) picker and what happens at expiry (auto-remove? notify?) are not drawn.
    - Removal has no confirmation dialog.
    - Can co-parents remove each other? Who is the owner?
    - Do the Người thân extra toggles appear here when switching role?
17. **116:11226: Family-tab scope.**
    - Pending row: can an invite be cancelled or revoked (only "Gửi lại" is shown)?
    - What do non-parent roles see on the Family tab?
    - Are invite and membership per baby or per family? The BabySwitcher implies per-baby context; the plan says "membership per baby".
18. **116:11226 / 118:12056 / 123:12623 / 123:12712: stale annotation.** The frame annotation on these screens describes the Today care tiles. Confirm it is a copy-paste and not a requirement for these screens.
19. **121:11672: toggle defaults.** Are the Người thân toggle defaults (Thông tin bé ON, Chăm sóc hằng ngày OFF) true defaults or just mock state? Does "Thông tin bé" also govern visibility of the DOB/weight that 11 otherwise hides?
20. **38:1581: time-zone model.**
    - The list shows fixed GMT offsets (no DST). Should the stored value be an IANA zone?
    - The "Tự động theo máy" toggle is OFF while GMT+7 shows as "Đang dùng". Which is the default?
    - What happens to records when the baby's timezone changes?
21. **29:721: name model.** Is there a real or full name in addition to "Tên thân mật"? It is implied by "Người thân chỉ thấy tên thân mật" but there is no field. What are the nickname length limits?
22. **29:795: tracker selection limits.** Must at least one tracker be selected? Pump and Growth use radio-styled controls; confirm they are multi-select toggles.
23. **115:11756 / 118:12227: attribution format.** For "Khác…", is the label free text, and what are its limits? Attribution sometimes uses the relation ("Mẹ ghi", "Ba ghi") and sometimes the name ("Cô Lan ghi"). What is the rule?
24. **29:1063 / 29:1375: theme semantics.** Is "Tối" the same as the Night care palette? The Night variant selects "Tối". Are the theme and Night care schedule stored per device or per account?
25. **27:488: legal acceptance.** "Điều khoản · Quyền riêng tư" is a link only. Is explicit consent required (e.g. under Vietnam's personal-data decree for child data)? No checkbox is designed.
26. **Global: missing states.** No loading or error states are designed for any network action in these sections: sign-in failure, offline, invite send failure, code invalid, link already used, already a member, max members. Limits are unknown: maximum babies per family, maximum members, maximum pending invites.
