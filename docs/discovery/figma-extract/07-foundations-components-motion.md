# G — Foundations, Components, Motion (Figma file sJLG1fAXKDnDr9YI6Yx8ex, read-only)

Source: Figma MCP read-only calls (get_metadata, get_variable_defs, get_design_context, whoami). Values are exactly as returned by Figma. "n/a" = not present in Figma.

> Note: the Figma MCP rate-limited twice ("tool call limit for your Full seat on the Professional plan"); it is a per-minute limit — after ~60-90s back-off all planned reads completed. Remaining gaps are listed under "Coverage".

---

## 0. Pages

`get_metadata` with no nodeId lists only **2 top-level pages**: `0:1 Cover`, `33:2 Logo`.
However the canvases `17:467 Foundations` and `7:4 Components` (and the screen canvases referenced in `_screens_index.txt`) resolve fine by id. So the MCP page listing is incomplete — treat node ids as authoritative.

### Cover (0:1)
- Frame `17:468 Cover` (1920×600): brand art vectors + `Logo` instance (36:2267) + Tagline.
- Frame `17:492 "Về hệ thống"`: title "Child Life — Design System v2". Body (verbatim summary): private space for a family to co-care for the baby and keep memories; **"Ứng dụng iOS cho ba mẹ có con 0–12 tháng"**, sleep-deprived, often one-handed. Guiding question: "Một tay, lúc 3 giờ sáng, có làm được trong 10 giây không?"
- **Five principles** (verbatim):
  1. Trạng thái mới nhất trước tiên — mở Hôm nay là thấy "lần cuối bú / ngủ / thay tã".
  2. Một chạm để bắt đầu, tối đa ba chạm để lưu — giờ = bây giờ, loại sữa nhớ lần trước, ml không bắt buộc.
  3. Ít chữ, đúng chữ — một nhãn ngắn + một biểu tượng.
  4. Bình tĩnh, không phán xét — không streak, không điểm, không cảnh báo gây áy náy.
  5. Chia sẻ có chủ đích — người xem luôn hiện rõ trước khi đăng.
- "Cách dùng file": Foundations = variables Color (mode Light / Night care) & Size, text styles (Be Vietnam Pro), effect styles. Components = variants bound to variables; icons are placeholder drawings, production uses SF Symbols. Screens: "Màn Night đặt mode 'Night care' trên frame." Also says "'Child Life' là tên dự án; chưa có logo — đặt chữ bằng màu ink." — **stale**: an official logo now exists on the Logo page.

---

## 1. Color tokens (Foundations 17:467 → Color 18:2)

Color frame description (18:4), verbatim:
> "34 token ngữ nghĩa, 2 mode: Light và Night care (cho cữ bú đêm — không phải diện mạo thương hiệu). Bạc hà là điểm nhấn, không phải nền. Ấm (peach, sunshine) chỉ cho kỷ niệm. Trạng thái luôn có icon + câu."

(= 34 semantic tokens, 2 modes: Light and Night care — for night feeds, NOT the brand look. Mint is an accent, not a background. Warm colors (peach, sunshine) are for memories only. States always use icon + sentence.)

Swatch frames: Light 18:5 (swatches 18:8…18:173), Night care 18:178 (18:181…18:346). Variables are Figma variables with two modes; CSS-style names `--token`.

| # | Token | Light (18:5) | Night care (18:178) |
|---|---|---|---|
| 1 | cloud (app background) | #F6FCFB | #0C1719 |
| 2 | surface | #FFFFFF | #15242A |
| 3 | surface-2 | #EEF6F5 | #1C2E33 |
| 4 | separator | #DCE8E7 | #26393E |
| 5 | control-border | #7E959A | #6B8A90 |
| 6 | ink | #173D44 | #E6F2F1 |
| 7 | ink-muted | #55707A | #9DB3B4 |
| 8 | mint | #2CBFB3 | #2CBFB3 |
| 9 | mint-deep | #087F7B | #3FD0C3 |
| 10 | on-mint-deep | #FFFFFF | #062A2C |
| 11 | mint-text | #06716D | #3FD0C3 |
| 12 | mint-soft | #E6F7F5 | #123536 |
| 13 | sunshine | #FFD166 | #FFD166 |
| 14 | sunshine-soft | #FFF4D6 | #3A3115 |
| 15 | peach | #FFA58D | #FFA58D |
| 16 | peach-soft | #FFE3DA | #3A2620 |
| 17 | on-warm | #173D44 | #173D44 |
| 18 | card-mint | #2CBFB3 | #123536 |
| 19 | card-night | #173D44 | #1C2E33 |
| 20 | card-peach | #FFA58D | #3A2620 |
| 21 | card-sun | #FFD166 | #3A3115 |
| 22 | on-card | #173D44 | #E6F2F1 |
| 23 | chip | #FFFFFF | #1C2E33 |
| 24 | nav-bar | #173D44 | #1C2E33 |
| 25 | nav-icon | #B9CFCF | #9DB3B4 |
| 26 | nav-active | #FFFFFF | #3FD0C3 |
| 27 | on-nav-active | #173D44 | #062A2C |
| 28 | apple-button | #000000 | #FFFFFF |
| 29 | apple-button-ink | #FFFFFF | #000000 |
| 30 | error | #A12B32 | #FF8A8F |
| 31 | error-soft | #FBE9EA | #3A1C1E |
| 32 | pending | #7A5600 | #FFD166 |
| 33 | focus-ring | #087F7B | #3FD0C3 |
| 34 | scrim | #0C171952 (= rgba(12,23,25,0.32)) | #0000008F (swatch label "rgba(0, 0, 0, 0.56)") |

Extra color variables found on screens (not on the Color board):

| Token | Light | Night care | Seen on |
|---|---|---|---|
| card-edge | #FFFFFFD9 | #FFFFFF0F | 46:2266 Today / 70:4386 Today Night, 50:3572 / 70:4567 Ghi nhanh |

### Care category tokens (52:4491 "Care categories")

Description (52:4493), verbatim:
> "Mỗi loại chăm sóc có một màu riêng, dùng xuyên suốt: thẻ Hôm nay, dòng thời gian, biểu đồ ngày, sheet ghi, chi tiết. soft = nền · ink = chữ/icon trên nền đó (≥5,5:1) · accent = vạch/biểu đồ, không dùng cho chữ. Nút chính vẫn dùng mint (thương hiệu)."

(soft = background · ink = text/icon on that background (≥5.5:1 contrast) · accent = bars/charts, never for text. Primary buttons stay mint.)

Board shows 5 categories only (Bú bình, Bú mẹ, Ngủ, Thay tã, Tăng trưởng). **Hút sữa (pump)** is NOT on the board but exists as variables `care/pump/*` used on screens (Today, Timer hút sữa 113:11207 / 113:11255). Note naming inconsistency: pump variables are exposed as `care/pump/ink` (slash path) while others are exposed as `--care-bottle-ink` (CSS-var style) — likely pump variables lack a code-syntax setting.

| Category (VN) | Key | soft L | ink L | accent L | soft Night | ink Night | accent Night |
|---|---|---|---|---|---|---|---|
| Bú bình | care/bottle | #E5F1FB | #1D5F99 | #3B8FD9 | #16314A | #9CCBF5 | #5AA6E8 |
| Bú mẹ | care/breast | #FCEAF0 | #A33A5E | #E07A9A | #3A1F2A | #F5B3C8 | #E88AA8 |
| Ngủ | care/sleep | #EDEEFC | #4447A8 | #6C6FD8 | #23244A | #BDBFF7 | #8A8DEB |
| Thay tã | care/diaper | #E7F4E3 | #2F6B24 | #5DAA4E | #1E3320 | #A8DA9C | #74BF63 |
| Tăng trưởng | care/growth | #FDEDE2 | #9A4A14 | #E8894A | #3A2617 | #F7C29A | #F09A5C |
| Hút sữa | care/pump | #F5EAFA | #7B3A94 | #B068C9 | #33203D | #E2B8F2 | #C285DA |

Sources: Light from 18:2 / 46:2266 / 113:11207; Night from 70:4386, 70:4567, 105:9797 (growth accent), 113:11255 (pump accent).

---

## 2. Night care mode semantics

- Defined on the Color board as a 2nd variable mode "Night care" — "for night feeds — not the brand look" (18:4). Every app screen exists in both `· Light` and `· Night care` variants.
- Appearance screen `13 Giao diện` (29:1063 Light / 29:1375 Night):
  - **ThemeOption** (23:339) choices: `Option=Light|Dark|Auto` × `Selected=True|False`; labels **"Sáng" / "Tối" / "Tự động"**. Description: "Appearance choice: mini preview (fixed colours — it shows the theme itself), label, radio. Selected preview gets a 2.5px mint-deep ring."
  - **SettingRow** "Night care" toggle; component default subtitle "Tự tối khi ghi sau 21:00"; on the screen instance subtitle = **"Theo lịch 21:00 – 06:00"**.
  - Schedule section header "Lịch Night care": DetailRows "Bật lúc 21:00" and "Tắt lúc 06:00" (sunrise/sunset-style icons, chevron → screen `13a Lịch Night care` 43:2067 / 43:2177).
  - Hint: **"Ngoài lịch, Night care vẫn tự bật khi bạn bắt đầu timer ngủ."** (Outside the schedule, Night care still auto-enables when you start a sleep timer.)
  - Footer: "Áp dụng ngay cho cả app" (applies immediately app-wide).
- Interpretation (from Figma text only): Night care = the dark palette; it is enabled by (a) user choosing "Tối", (b) "Tự động", (c) the Night care schedule toggle (default 21:00–06:00), and (d) auto-on when a sleep timer starts. How "Tự động" differs from the schedule (OS dark mode vs. schedule) is NOT stated in Figma → open question.
- Shadow rule in Night care (18:472): "Night care: thẻ không dùng bóng (dựa vào surface vs cloud); các style 'Night care/…' dùng cho sheet, chip, tab bar, thẻ nâng lên." (cards have no shadow in Night care; separate `Night care/…` shadow styles exist for sheet, chip, tab bar, raised cards).

---

## 3. Typography (18:351)

Description (18:353), verbatim:
> "Be Vietnam Pro (hỗ trợ tiếng Việt đầy đủ), trọng lượng 400 / 500 / 600. Con số dùng chữ số đều (tabular) để timer không nhảy. Map sang Dynamic Type, không khóa cỡ chữ; bố cục chịu được tiếng Việt dài hơn 30% và cỡ chữ 200%."

Font: **Be Vietnam Pro** — open-source (SIL Open Font License), available on Google Fonts (Flutter: `google_fonts` package or bundle TTFs). Weights used: 400 Regular, 500 Medium, 600 SemiBold. Numbers must use tabular figures (`FontFeature.tabularFigures()`). Must scale with Dynamic Type; layouts must tolerate +30% Vietnamese text length and 200% text size.

| Style | Size / LH | Weight | Letter spacing | Sample | Usage (verbatim) |
|---|---|---|---|---|---|
| Text/display | 34 / 40 | SemiBold 600 | -0.6px | "Cùng chăm con, giữ trọn tuổi thơ" | Welcome and form-screen headline. One per screen. |
| Text/large-title | 32 / 40 | SemiBold 600 | -0.4px | "Hôm nay" | Navigation large title on tab screens. |
| Text/title | 30 / 36 | SemiBold 600 | -0.5px | "Ghi nhanh, một tay" | Headline under an illustration card. At most 2 lines. |
| Text/headline | 18 / 26 | Medium 500 | 0 | "Bú bình" | Tile labels, card titles, section headers. |
| Text/body | 16 / 24 | Regular 400 | 0 | "Tối đa 3 chạm là xong." | One-line subtitle, list rows, memory captions. |
| Text/body-strong | 17 / 24 | Medium 500 | 0 | "Tiếp tục với Apple" | Button labels and the key value in a row. |
| Text/label | 14 / 20 | Medium 500 | 0 | "45 phút trước · Mẹ ghi" | Metadata, field labels, chips. Smallest size for meaningful text. |
| Text/caption | 12 / 16 | Medium 500 | +0.2px | "Hôm nay" | Rare: legal footnotes only. |
| Numbers/numeral-xl | 52 / 56 | Medium 500 | -1px | "1:24:08" | Sleep timer and value being typed. Tabular figures. |
| Numbers/numeral | 28 / 34 | Medium 500 | 0 | "120 ml" | Value on a Latest card and history summaries; tabular figures. |

Inconsistency observed: on `13 Giao diện · Light` (29:1063) the texts "Lịch Night care" (43:2013) and the hint (43:2038) use **Inter Regular 12** (not a defined style) — likely a design slip; implement with Text/caption or Text/label.

---

## 4. Spacing & size (18:415)

Description (18:417), verbatim: "Lề màn hình và đệm thẻ space-4, giữa thẻ space-3, giữa phần space-6, trên nút chính space-8. Mọi vùng chạm ≥ tap-min."
(Screen margin & card padding = space-4; between cards = space-3; between sections = space-6; above primary button = space-8. All touch targets ≥ tap-min.)

| Token | Value |
|---|---|
| space-1 | 4 |
| space-2 | 8 |
| space-3 | 12 |
| space-4 | 16 |
| space-6 | 24 |
| space-8 | 32 |
| tap-min | 44 |
| button-height | 56 |
| next-button | 64 |

(No space-5 / space-7 tokens.) Screens are 375 wide with 16px side padding (343 content width); phone frame radius 44, status bar 40 tall (pt 14, px 28), bottom content padding 34.

## 5. Radius (18:445)

Description (18:447), verbatim: "Nút, segmented, chip, avatar, tab bar: pill. Tile & thẻ kỷ niệm: tile. Nhóm danh sách: card. Sheet: sheet. Thẻ minh họa: hero."

| Token | Value | Use |
|---|---|---|
| radius-sm | 8 | (small elements) |
| radius-control | 12 | icon tiles, controls |
| radius-card | 24 | list groups / cards |
| radius-tile | 28 | tiles & memory cards |
| radius-sheet | 32 | bottom sheets |
| radius-hero | 36 | illustration (hero) cards |
| radius-pill | 999 | buttons, segmented, chips, avatar, tab bar |

Non-token radii seen: ThemeOption preview 18; foundation swatch cards 16; care swatch 20 / chip 6.

## 6. Shadow (18:470)

Description (18:472), verbatim: "Bóng mềm, nhuộm màu mực. Night care: thẻ không dùng bóng (dựa vào surface vs cloud); các style “Night care/…” dùng cho sheet, chip, tab bar, thẻ nâng lên."

Light (ink-tinted, color base #173D44 / #122E33):

| Style | Layers (x, y, blur, spread, color) |
|---|---|
| shadow-card | (0,1,2,0,#173D440F = 6%) + (0,8,24,0,#173D4414 = 8%) |
| shadow-chip | (0,8,24,0,#173D4429 = 16%) |
| shadow-sheet | (0,-8,32,0,#173D441F = 12%) |
| shadow-nav | (0,12,30,0,#173D4440 = 25%) |
| shadow-lift | (0,12,32,0,#173D442E = 18%) |
| shadow-tile (not on board; used on Today) | (0,2,4,0,#122E331A = 10%) + (0,10,22,-4,#122E3329 = 16%) |

Night care styles found on screens:

| Style | Layers |
|---|---|
| Night care/shadow-tile | (0,2,4,0,#00000059 = 35%) + (0,10,24,-4,#00000073 = 45%) |
| Night care/shadow-sheet | (0,-8,32,0,#00000080 = 50%) |
| Night care/shadow-chip, Night care/shadow-nav, Night care/shadow-lift | **Not found** on any node inspected (Night Today 70:4386, Night Ghi nhanh 70:4567, Night Welcome 26:359, Night growth 105:9797). Night screens still bind the Light `shadow-nav` / `shadow-chip` / `shadow-card` styles. |

Non-named shadows seen in components: QuickAction / Segmented item / SettingRow / HeroCard / SelectTile use drop-shadow (0,8,12 rgba(23,61,68,0.08)) + (0,1,1 rgba(23,61,68,0.06)); Chip/Floating & FloatChip (0,8,12 rgba(23,61,68,0.16)); NavBar/QuickLogButton (0,12,15 rgba(23,61,68,0.25)); BottomSheet/Feed (0,-8,16 rgba(23,61,68,0.12)) — these are the CSS drop-shadow renderings of the named styles (blur halved), implement with the named styles above.



---

## 6b. Logo color variables (`logo/*`, mode-aware)

| Token | Light (36:2233 Splash, 35:180) | Night care (36:2249, 26:359) |
|---|---|---|
| logo-sky | #2CBFB3 | #173D44 |
| logo-sun | #FFD166 | #FFD166 |
| logo-band | #FFFFFF | #2E8F8A |
| logo-ground | #087F7B | #3FD0C3 |

---

## 7. Motion tokens referenced in component descriptions (NOT defined as variables)

Component descriptions reference named durations, but **no duration/easing variables or values exist** in any `get_variable_defs` result, and Foundations has no Motion board. Names referenced (verbatim usage):

| Token name | Where referenced | Usage text |
|---|---|---|
| duration-tap | Button 8:33 | "Press: scale 0.97 in duration-tap." |
| duration-quick | QuickAction 9:35; Segmented/Item 9:111 | "After save: bounce + checkmark in duration-quick, haptic .success."; "Change animates in duration-quick." |
| duration-base | LatestCard/Row 9:60; BottomSheet/Feed 11:159 | "Number rolls to the new value on save (duration-base)."; "Presents with spring ≈ duration-base over a scrim." |
| duration-breath | SleepTimer 10:83 | "arc ... breathing opacity 1 ↔ 0.55 over duration-breath (ease-in-out); static with Reduce Motion." |
| duration-slow | MemoryCard 10:122 | "New card: lifts with shadow-lift, −1.5° tilt, sunshine sparks over duration-slow." |

Other motion/interaction rules from descriptions: QuickAction press scale **0.96**; Button press scale **0.97**; Button disabled opacity **40%**; QuickAction save → haptic `.success`; Widget "Đã ghi · Hoàn tác" visible ~**5 s**; Reduce Motion → SleepTimer static. **Millisecond values for the duration-* tokens are not in Figma → must be defined by engineering (open question).**

## 8. Motion / prototype findings (get_motion_context, recursive=true)

| Node | Name | Result |
|---|---|---|
| 36:2233 | 00 Splash · Light | `{"nodes":[]}` — no motion data in Figma |
| 26:4 | Welcome | `{"nodes":[]}` — no motion data in Figma |
| 46:2266 | 19 Hôm nay · Light | `{"nodes":[]}` — no motion data in Figma |
| 47:3028 | 25 Timer ngủ · Light | `{"nodes":[]}` — no motion data in Figma |
| 50:3572 | 19a Ghi nhanh · Light | `{"nodes":[]}` — no motion data in Figma |
| 10:83 | SleepTimer component | `{"nodes":[]}` — no motion data in Figma |
| 84:6579 | widget tap | `{"nodes":[]}` — no motion data in Figma |
| 133:16184 | memories timeline | `{"nodes":[]}` — no motion data in Figma |
| 206:136 | sort blocks | `{"nodes":[]}` — no motion data in Figma |
| 219:1413 | landing hero | `{"nodes":[]}` — no motion data in Figma |

**Conclusion: the Figma file contains no keyframe animations, easing curves, or durations on any requested node.** Prototype interactions/transitions are not exposed by the read-only MCP tools (get_motion_context only reports keyframe tracks), so none could be confirmed. All motion must be derived from the description text in §7 plus engineering defaults.

---

## 9. Components inventory (Components page 7:4)

Section descriptions (verbatim):
- Icons 8:2 — (icon description below)
- Buttons 8:100: "Nút dạng pill. Nhãn là động từ 1–2 từ. Một nút Primary mỗi màn, nằm trong vùng ngón cái."
- Chips, Status & Avatar 8:104: "Trạng thái luôn có icon + câu, không chỉ dựa vào màu. Màu ấm chỉ cho kỷ niệm."
- Care 9:161: "Hành động nhanh, thẻ "Lần cuối", segmented. Màn chăm sóc giữ thuần bạc hà + mực."
- Lists & Empty state 9:164: "Hàng danh sách, tiêu đề nhóm, trạng thái trống."
- Sleep, Memories & Navigation 10:190: "Timer ngủ "thở", thẻ kỷ niệm ấm, tab bar nổi."
- Sheet & Screen parts 11:213: "Sheet ghi nhanh, ô số, hàng trường, header, hero, status bar, bàn phím số."
- Onboarding & Auth 23:381: "Thành phần cho luồng chào mừng, đăng nhập, tạo hồ sơ bé và nhận lời mời."
- Care (v2) 45:410: "Thành phần cho flow Chăm sóc: lịch sử, ghi nhanh, chi tiết bản ghi."
- Widgets 73:401: "Home screen (S/M/L), Lock screen, Live Activity & Dynamic Island. Ghi 1 chạm + hoàn tác (iOS 17 App Intents)."

### 9.1 Icons (8:2; frame 7:6) — 39 symbols, 24×24
Description on every icon: "Line icon (24px, 1.8 stroke) — placeholder drawing; production uses SF Symbols. Recolour by overriding the stroke with a text-colour token."

feed 7:9 · sleep 7:12 · diaper 7:16 · heart 7:19 · today 7:23 · memories 7:27 · family 7:33 · plus 7:36 · back 7:39 · arrow-right 7:42 · check 7:45 · cloud-off 7:49 · alert 7:53 · spark 7:56 · lock 7:60 · close 7:63 · chevron-right 7:66 · eye 22:153 · mail 22:157 · camera 22:161 · globe 22:165 · cake 22:169 · clock 22:173 · link 22:177 · upload 22:180 · journal 22:184 · drop 22:187 · ruler 22:191 · star 22:194 · brand-mark 22:197 · search 37:292 · backspace 44:295 · chevron-down 44:298 · edit 44:302 · sunrise 59:388 · sunset 59:392 · sliders 166:22720 · bookmark 178:24812 · retry 186:802

Sizes used in instances: 24 (default), 22 (NavBar), 20 (SettingRow/ListRow), 18 (button/chip/detail), 16 (FloatChip lead, QueueRow), 14 (Radio/check), 12 (MediaTile lock), 28 (QuickLogButton plus).

### 9.2 Inventory table

| Component | Node | Variants / props | Size | Purpose / description (Figma, verbatim or close) |
|---|---|---|---|---|
| Button | 8:33 | Style = Primary 8:5, Secondary 8:9, Tinted 8:13, Plain 8:17, Outline 8:21, Destructive 8:25, Apple 8:29; props label (default "Bắt đầu"), showIcon (18px icon) | h56 (Secondary h52, Plain h44), px space-6 (Plain space-3), gap space-2, pill | "Pill button, label = 1–2-word verb (Lưu, Bắt đầu, Kết thúc, Chỉnh giờ, Mời, Thử lại). Primary h56 mint-deep/on-mint-deep, one per screen in the thumb zone. Secondary h52 surface-2. Tinted for secondary actions. Plain for text buttons (≥44 tap). Apple: use Apple's official button in production. Press: scale 0.97 in duration-tap. Disabled: opacity 40%. Stretch to fill width for block buttons." Fills: Primary mint-deep / on-mint-deep; Secondary surface-2 / ink; Tinted mint-soft / mint-text; Plain transparent / mint-text; Outline surface + 1.5px control-border / ink; Destructive error-soft / error; Apple apple-button / apple-button-ink. Label = Text/body-strong 17/24. |
| Button/Round | 8:34 | icon slot | 64×64 (next-button), mint-deep | "Round Next button (64px) on onboarding pages. Icon-only, so it MUST carry an accessibility label: "Tiếp tục" (VoiceOver: "Tiếp tục, nút"). Never rely on the arrow alone." |
| Button/Back | 8:37 | — | 44×44, surface-2 | "Round back button, 44px tap target, surface-2. Accessibility label: Quay lại." |
| Chip | 8:56 | Style = Neutral 8:40, Warm 8:45, Sun 8:52 | h28, px12 py4, 18px icon, label 14/20 | "Audience and milestone chips. Neutral = surface-2 (Chỉ ba mẹ), Warm = peach-soft (memory audience), Sun = sunshine + on-warm (milestone badge). Warm colours only on memory screens." |
| Chip/Floating | 8:57 | icon, value ("120 ml") | 103×44, 30px icon circle mint-soft | "Floating chip on an illustration card (value + small icon, e.g. 120 ml, 1:24). chip fill, shadow-chip, tabular figures." |
| SyncStatus | 8:84 | Status = Synced 8:70, Pending 8:74, Error 8:79 | h32, px12 py6, 18px icon | "Sync pill — always icon + words, never colour alone. Synced: mint-soft/mint-text. Pending (offline / waiting): sunshine-soft/pending, copy "Đã lưu trên máy này. Đang chờ đồng bộ." Error: error-soft/error. Pending saves must survive an app restart." Labels: "Đã đồng bộ" / "Chờ đồng bộ · 2" / "Chưa lưu được". |
| Banner/Error | 8:85 | — | 343×72, radius-card | "Save-failed banner: error-soft ground, alert icon, bold error lead + reassuring sentence in ink. Pair with a Tinted "Thử lại" button." Copy: "Chưa lưu được. Thử lại, nội dung vẫn ở đây." |
| Avatar | 8:97 | Style = Mint 8:90, Warm 8:92, Add 8:94 | 40×40 | "40px round avatar. Mint for parents/caregivers, Warm (peach-soft) for the baby and relatives who only view memories, Add for "Mời người thân"." |
| QuickAction | 9:35 | Type = Default 9:20, Active 9:25, Memory 9:30 | 80×84, radius-tile | "One-tap logging tile on Today (4-column grid, gap space-2; 2 columns at Accessibility text sizes). Default: surface + shadow-card, icon on mint-soft. Active (timer running): mint-soft fill + 2.5px mint-deep border. Memory: icon on peach-soft. Press: scale 0.96. After save: bounce + checkmark in duration-quick, haptic .success." |
| QuickAction/Grid | 9:36 | — | 343×84 | "Today's 4-tile quick-log grid." (Bú, Ngủ, Thay tã, Kỷ niệm) |
| LatestCard/Row | 9:60 | ago, icon, meta, unit, value | 343×78 | "One "Lần cuối" row: care icon on mint-soft, value + who/when, time-ago in numeral (tabular). Number rolls to the new value on save (duration-base)." |
| LatestCard | 9:70 | — | 343×236 | "Grouped "Lần cuối" card — newest first, latest state before anything else. surface, radius-card, shadow-card, hairline separators." |
| Segmented/Item | 9:111 | Selected = True 9:107 / False 9:109; label | h46 | "One segment. Selected: surface + shadow-card, ink, weight 500. Unselected: transparent, ink-muted. Change animates in duration-quick." |
| Segmented | 9:124 | Options = 2 (9:112), 3 (9:117) | 343×56, track surface-2 pad 5 gap 4 | "Pill segmented control on surface-2 track (pad 5, gap 4). 2–3 short options (Sữa mẹ · Sữa công thức; Ướt · Bẩn · Cả hai). Remembers the last choice as the default." |
| ListRow | 9:139 | Type = Member 9:125, Invite 9:133 | 343×60 | "List row (min 60px) for family members and settings: avatar, name (body) + role (label, ink-muted), chevron. Invite row in mint-text. Group rows in a surface card with radius-card and 1px separator dividers." |
| SectionHeader | 9:140 | title, link, showLink | 343×26 | "Section header: headline title + optional mint-text link. space-6 above, space-2 below." |
| EmptyState | 9:143 | title, message | 375×278 | "Calm, no-guilt empty state: 64px icon on mint-soft, headline, one muted sentence, one Tinted action. Never "Bạn chưa hoàn thành…"." |
| SleepTimer | 10:83 | since, elapsed, by | 272×272 | "Running sleep timer, 272px. Track surface-2, arc mint (12–13px, round cap) breathing opacity 1 ↔ 0.55 over duration-breath (ease-in-out); static with Reduce Motion. Elapsed in numeral-xl with tabular figures. Pair with Primary "Kết thúc" + Plain "Chỉnh giờ bắt đầu"." (Note: the section's variables include `care-sleep-accent #6C6FD8`, so the drawn arc may be sleep-accent, not mint — see open questions.) |
| MemoryCard | 10:122 | Photo = True 10:91 (308×319), False 10:112 (308×92) | w308, radius-tile | "Memory card: radius-tile, shadow-card. Photo 4:3 with optional Sun milestone badge; caption (body); date + audience chip — the audience is always visible (Gia đình / Chỉ ba mẹ). New card: lifts with shadow-lift, −1.5° tilt, sunshine sparks over duration-slow." |
| TabBar (deprecated · icon-only) | 10:168 | Active = Today 10:123, Memories 10:138, Family 10:153 | 263×68 | **Description: "Deprecated — use NavBar."** Confirmed deprecated; replacement = NavBar 44:362 (inside TabDock 10:169). |
| TabDock | 10:169 | nested NavBar Active | 375×68, gap space-3, px space-4 | "Tab dock = NavBar + QuickLogButton, 24px above the home indicator. Swap the nested NavBar variant (Active) per tab." |
| NavBar | 44:362 | Role × Active: Parent {Today 44:308, Memories 44:326, Family 44:344, Me 196:105}; Caregiver {Today 124:62, Family 124:74, Me 196:123}; Relative {Memories 124:86, Family 124:96, Me 196:138}; prop initial ("M") | 263×68, p6, pill | "Floating tab bar (nav-bar pill, h68, shadow-nav). Each tab shows icon + label (caption) — visible labels beat icon-only for tired parents and for VoiceOver parity. Active tab: nav-active pill, on-nav-active content. Swap the Active variant per screen." Tab labels: Hôm nay / Kỷ niệm / Gia đình / Tôi; inactive tabs 52 wide icon-only (22px), "Me" tab = 22px initial-avatar ring (1.6px). Label text 14px/16 +0.2 (caption-like). |
| QuickLogButton | 44:363 | — | 68×68, mint-deep, 28px plus | "Ghi nhanh (+): opens the quick-log chooser (Bú · Ngủ · Tã · Tăng trưởng). 68px, accessibility label "Ghi nhanh"." |
| StatusBar | 11:135 | — | 375×40 | "Placeholder iOS status bar for screen mockups." (don't implement) |
| NavHeader | 11:138 | title, subtitle, showTrailing | 343×80 | "Large-title navigation header — one large-title per screen; subtitle in label/ink-muted; trailing avatar, pill or tinted + button (swap the trailing instance)." |
| HeroCard | 11:144 | baby, state, since | 343×104 | "Today hero: the baby's current state first (Đang thức / Đang ngủ), with the sync pill. State text 24/32 semibold." (24/32 SemiBold is NOT a named text style.) |
| NumField | 11:153 | value, unit | 343×80, surface-2, radius-card | "Numeric entry (ml / kg) in numeral-xl, tabular figures. Optional — amount is never required to save." |
| FieldRow | 11:156 | label, value | 343×44 | "Tappable field row (≥44): label + current value in mint-text. Smart default: time = now." |
| BottomSheet/Feed | 11:159 | title | 375×381, top radius-sheet, pt space-2, pb space-6, grabber 40×5 separator | "Quick-log bottom sheet (Ghi cữ bú): grabber, title + close, segmented type, optional amount, time row, full-width Lưu. ≤3 taps to save; the keyboard never covers Lưu. Presents with spring ≈ duration-base over a scrim." Title 24/32 SemiBold. |
| Keypad | 11:184 | — | 375×236, keys h46 radius-control | "Decimal pad mock (system keypad in production): digits, decimal comma, backspace." |
| FloatChip | 23:164 | Lead = Icon 23:150, Check 23:155, Avatar 23:160 | h40 | "Floating chip on an illustration card: chip fill + shadow-chip. Lead = small care icon on mint-soft, a check on mint-deep (done/synced), or an initial avatar (who logged). Value uses tabular figures." |
| PageDots | 23:185 | Step = 1–4 | 60×6 | "Onboarding pagination: active = 24px mint-deep pill, others 6px separator dots." |
| Progress | 23:190 | Value = 50, 100 | 208×4 | "Setup progress bar (4px). Fill mint-deep on separator track." |
| TopBar | 23:226 | Type = Back, Skip, Back+Skip, Back+Progress, Back+Countdown, Brand | 343×44 | "Top bar for onboarding/auth (44px): round Back, "Bỏ qua" text button, setup progress, invite countdown, or the logo lockup (Logo/Lockup Horizontal, 28px) with a theme toggle." |
| TextField | 23:243 | Style = Grouped, Standalone | 343×66 | "Text field: caption label above the value. Grouped = row inside a surface card (stack rows with a 1px separator). Standalone = its own surface card. Password shows a 32px eye toggle." |
| DetailRow | 23:244 | — | 343×56 | "Settings/detail row: icon on mint-soft tile, label, current value (ink-muted), chevron. Stack inside a surface card with separators." (Note: on 13 Giao diện the value is mint-text.) |
| Radio | 23:257 | Checked = True/False | 24×24 | "Radio / single-select (24px). Checked: mint-deep with check. Unchecked: 1.5px control-border ring (3:1)." |
| Toggle | 23:262 | On = True/False | 51×31 | "iOS switch. On: mint-deep track. Off: separator track. White knob." |
| ThemeOption | 23:339 | Option = Light/Dark/Auto × Selected | 84×196; preview 84×132 r18 | "Appearance choice: mini preview (fixed colours — it shows the theme itself), label, radio. Selected preview gets a 2.5px mint-deep ring." Labels: Sáng / Tối / Tự động. |
| SettingRow | 23:340 | title, subtitle | 343×68 | "Setting row with a switch: icon tile, title + one-line explanation, Toggle." |
| Coachmark | 23:349 | — | 203×44 | "First-run coachmark: ink bubble with surface text (inverts in Night care). One per screen, dismiss on first tap." |
| CodeInput | 23:355 | — | 343×72 | "Invite code entry: 10 characters, wide tracking, paste-friendly. Auto-uppercase." |
| PermissionTile | 23:369 | Allowed = True/False | 166×56 | "What the invited role can / cannot do, shown before joining. Allowed: surface + mint-deep check. Not allowed: surface-2 + lock, ink-muted." |
| AccountRow | 23:370 | — | 343×60 | "Existing account found for this email: initial, email, provider chip." |
| SheetHeader | 37:293 | — | 375×69 | "Bottom-sheet header: grabber, title (24/32 semibold), close (44px, label "Đóng")." |
| DateWheel | 37:301 | — | 343×220 | "Date wheel (iOS UIDatePicker .wheels look-alike): Day · Month · Year, selected row on a surface-2 band. Use the native picker in production; default = today, cannot pick a future date." |
| OptionRow | 37:348 | Selected = True/False | 343×60 | "Single-select list row (time zone, language…): title + subtitle, radio. Stack inside a surface card with separators." |
| TourTip | 102:631 | Arrow = Top, Bottom, Bottom right | 300×175 | "Spotlight tour tooltip. Use with a Scrim + highlighted target (focus ring). Pointer x aligns to target centre." |
| RoleOption | 115:679 | Selected = True/False | 343×186/184 | "Invite role card: title, who it is for, permission list (check = allowed, lock = not allowed)." |
| MemberRow | 115:704 | Status = You, Member, Pending | 343×68 | (no description returned) |
| RelationChip | 115:709 | Selected = True/False | ~53×40 | (no description returned) |
| BabySwitcher | 45:321 | — | 130×40 | "Baby switcher chip: avatar + name (+ chevron when the family has more than one baby). Shows whose log you are viewing." |
| DayPill | 45:342 | Selected = True/False | 44×64 | "Day strip pill (44×64 ≥ tap target). Selected = mint-deep. Today is the right-most pill; swipe for earlier weeks." |
| FilterChip | 45:347 | Selected = True/False | 83×40 | "Single-select filter chip (h40). Selected = mint-deep / on-mint-deep. Row scrolls horizontally; last chip may peek to signal more." |
| SummaryTile | 45:348 | — | 108×90 | "Daily summary tile: category, count/total, one detail. Facts only — no goals, no judgement." |
| LogRow | 45:373 | Pending = False/True | 343×68 | "History row: care icon, "what · detail", "time · who logged". Pending = saved on this device, waiting to sync (icon + words, never colour alone). Tap → record detail." |
| ChoiceTile | 45:386 | Selected = True/False | 106×120 | "Big single-choice tile for one-hand logging (diaper type…). Selected: mint-soft + 2.5px mint-deep border. Remembers the last choice." |
| TimeRow | 45:387 | — | 343×52 | "When it happened. Default = now; tap the chip to pick another time (wheel). Label is "Thời gian" — short and plain." |
| InfoRow | 45:394 | — | 343×56 | "Read-only key/value row for record details." |
| AmountField | 45:403 | State = Focused/Default | 343×88 | "Numeric amount (ml, kg, cm, phút) in numeral-xl, tabular figures. Focused = mint-soft + 2px mint-deep. Always optional unless stated." |
| TimelineItem | 48:407 | Type=Event × Category=Bottle 48:372 / Diaper 52:479 / Growth 52:494 / Pump 106:676; Type=Span × Category=Sleep 48:389 / Breast 52:509 | Event 343×66, Span 343×74 | "Day timeline entry: time column (tabular), rail with category marker, content. Event = point in time (feed, diaper, growth). Span = something with a duration (sleep, breastfeed) shown as a block with a duration bar. Pending = saved on device, waiting to sync. Turn off the line on the last item. Category variant colours the marker, span block and bar with care/<type> tokens. Marker is 40px and holds the care type art (Illustration/Mini/*) via the Icon property." |
| DayRhythm | 104:646 | Filter = All 48:409, Feed 104:484, Sleep 104:538, Diaper 104:592 | 343×226 | ""Đã ghi hôm nay": totals of what was logged today (bottle feeds + ml, breastfeeds + minutes, finished sleep, diaper changes) and a 24h strip in care colours. Running sleep is not counted until it ends." |
| CareTile | 54:530 | Type = Bottle 54:428, Breast 54:445 (h158), Sleep 54:462, Sleep running 54:479, Diaper 54:496, Empty 54:513 (h114), Pump 106:631, Growth 106:656 | 166×138 | "Care tile on Today. Tinted card (care/<type>/soft) with a line icon in a care-accent-20% circle, type label (care ink), key value, ⏱ when, 👤 who logged. Tap = log that type. Sleep running = live elapsed + accent border. Empty = "Chưa có / Chạm để ghi" (swap the icon + colours per type)." Uses shadow-tile + card-edge. |
| GrowthRow | 54:531 | — | 343×104 | "Growth on Today: weight · length, measurement date and change versus a named date. Tap → growth (enter new measurement + history)." |
| TimeSectionHeader | 59:431 | Period = Morning, Noon, Afternoon, Evening, Night | 343×71 | "Sticky time-of-day header for the timeline: Sáng (05–11) · Trưa (11–13) · Chiều (13–18) · Tối (18–22) · Đêm (22–05). Each period has its own icon + tint so sections are easy to scan; count = entries in that period." |
| EntryOption | 69:609 | Style = Primary, Secondary | 343×103/102 | "Large entry choice with icon, title, subtitle and chevron. Primary = recommended path." |
| ReminderRow | 126:683 | State = Upcoming, Overdue, Done | 343×70 | (no description returned) |
| ReminderPeek | 128:665 | — | 343×82 | "Home entry to reminders (S15): next upcoming reminder + count. Tap opens reminder list." |
| Widget/Small | 73:483 | Type = Bottle, Breast, Sleep, Sleeping, Diaper, Bottle logged, Breast running, Diaper logged, Empty, Signed out | 170×170 | "Home screen small widget (170×170). Primary button logs in 1 tap; widget then shows the Logged state with Undo." |
| Widget/Medium | 74:551 | State = Default, Logged, Offline | 364×170 | "Medium widget: 4 one-tap quick-log tiles (Bottle = last amount, Breast/Sleep = start timer, Diaper = Wet). Logged state shows Undo for ~5s." |
| Widget/Large | 74:552 | — | 364×382, r22, p14 | "Large widget: sleep status + quick log + 3 most recent entries." |
| Lock/Circular | 75:524 | Type = Sleep, Feed | 76×76 | (no description) |
| Lock/Rectangular | 75:525 | — | 172×76 | (no description) |
| Lock/Inline | 75:532 | — | 240×20 | (no description) |
| LiveActivity/Lock screen | 75:576 | Type = Sleep, Breast | 364×158 | "Live Activity on Lock screen for running Sleep / Breast timers. Buttons end or adjust without opening the app." |
| DynamicIsland/Sleep | 75:606 | Mode = Compact (250×37), Minimal (37×37), Expanded (371×168) | — | (no description) |
| Illustration/Photo | 131:758 | Tone = Mint, Peach, Sun, Sky, Lilac, Night, Sand, Leaf, Rose | 200×200 | "Illustrated baby photo placeholder (privacy-safe). Use instead of real photos in mockups." |
| MediaTile | 131:860 | State = Default 131:759, Selected 131:782, Uploading 131:808, Failed 131:834; props duration ("0:24"), favorite, isVideo, private | 110×110, r12 | (no own description) Video badge rgba(0,0,0,.55) pill + duration caption; private lock badge rgba(0,0,0,.45); overlay rgba(0,0,0,.35) on Uploading/Failed; progress ring 34px; Failed = 32px error + "!"; favorite = 18px bookmark; Selected = 24px check. |
| UploadPill | 132:898 | State = Uploading, Paused, Failed, Done | 343×68, r18 | (no own description) bg mint-soft / sunshine-soft (Paused) / error-soft (Failed); 44px thumbnail; title 14/20 SemiBold; 4px progress (fill mint-deep / sunshine / error); caption. Copy: "Đang tải 4/7 mục · Cứ làm việc khác, xong sẽ báo bạn"; "Tạm dừng · chờ mạng · Tự tải tiếp khi có mạng"; "2 mục chưa tải được · Chạm để thử lại hoặc bỏ qua"; "Đã tải xong 7 mục · Đã báo cho Bà nội, Ông ngoại". |
| QueueRow | 132:1036 | State = Uploading, Waiting, Failed, Unreadable, Done | 343×68 | (no own description) 48px thumb; filename 14/20 + status caption (mint-text / on-warm / error); action 32px surface-2 (close/check) or error-soft "Thử lại" pill with retry icon. Copy: "62% · 2,1 MB/3,4 MB", "Chờ Wi-Fi · video 48 MB", "Mất kết nối khi đang tải", "Tệp bị lỗi · không thử lại được", "Đã tải lên". |
| StoryCard | 207:225 | Template = "Một khoảnh khắc" 207:122, "Ba khung" 207:135, "Bốn góc" 207:161, "Lá thư" 207:194, "Đêm dịu" 207:213 | 320×400, r6 | (no description) Exportable story cards. **Uses extra fonts not in the type system: Lora (SemiBold, Italic, Regular) and Dancing Script (Regular)**, plus fixed non-token colors (#FAF5EC paper, #1E262C night, #3E342C ink, #8C7C6C muted, #D6B478 gold, #F7F0E0, #789480, #E8C4B8). Footer "Child Life" 9px tracking 1.08. |

### 9.3 Illustrations (24:365 + Components root)

| Illustration | Node | Size / bg | Description |
|---|---|---|---|
| Illustration/Welcome | 24:183 | 343×392, card-mint, radius-hero | "Welcome hero: sleeping baby + rubber duck on card-mint, chips hint at feeds, sleep and milestones." (FloatChips "120 ml", "1:24", "Mốc mới") |
| Illustration/SignIn | 24:355 | 375×440, card-mint, full-bleed | "Sign-in hero (full-bleed, sits under the sign-in sheet): toy blocks spelling "Bé"." |
| Illustration/VerifyEmail | 25:238 | 343×300, card-mint | "Verify email: letter in an envelope with a check badge." |
| Illustration/Recover | 25:251 | 343×200, card-sun | "Recover password: key on card-sun (the bow hole follows card-sun)." |
| Illustration/AccountLink | 25:260 | 343×236, card-mint | "Account exists: your initial linked to an email." |
| Illustration/InviteCode | 25:269 | 343×236, card-sun | "Invite code: a ticket on card-sun (notches follow card-sun)." |
| Illustration/Invite | 25:282 | 343×212, card-mint | "Invite received: inviter initial next to the baby." |
| Illustration/Expired | 25:298 | 343×320, surface-2 | "Invite expired: calm hourglass on surface-2 — no alarm colours." |
| Illustration/BabyAvatar | 25:308 | 148×148 + 40px mint-deep camera button | "Baby profile photo placeholder with camera button." |
| Illustration/BabyFace | 25:323 | 36×36 | "Small baby avatar for headers." |
| TodayHero/Empty | 25:361 | 343×172, card-night, radius-sheet | "Today hero before the first log: card-night with moon and clouds; text is #E6F2F1 on card-night in both themes." |
| SelectTile | 25:399 | Selected True/False, 166×128 | "Multi-select tile (trackers): object art + label. Selected: mint-soft fill, 2px mint-deep border, check. Unselected: surface + shadow-card." |
| LogTile | 25:420 | Active True/False, 166×92 | "Today log tile (2-column): label bottom-left, object art top-right. Active = the suggested first action (mint-soft + mint-deep border)." |
| Illustration/Mini/Bottle, Drop, Moon, Diaper, Ruler, WetDirty, Pump | 25:334, 25:341, 25:345, 25:350, 25:356, 44:303, 106:621 | 56×56 | "Small 3D-style object for tracker tiles (fixed colours)." Pump: "Mini art: breast pump (Hút sữa)" |
| Illustration/GrowthStory | 24:278 | 343×408 | (description not read) onboarding 04 |
| Illustration/Care | 24:221 | 343×408 | (description not read) onboarding 02 |
| Illustration/Handover | 24:251 | 343×408 | (description not read) onboarding 03 |
| Illustration/Family | 24:314 | 343×408 | (description not read) onboarding 05 |
| Illustration/Photo | 131:758 | 9 tones, 200×200 | privacy-safe photo placeholder (mockups only) |

Illustrations are vector art exported as SVG from Figma (asset URLs expire after 7 days — re-export via MCP when implementing).

---

## 10. Logo & app-icon assets (Logo page 33:2)

**Official logo: "Khoảnh khắc"** — sheet 35:240 "Logo sheet · Khoảnh khắc (official)": "Một khung ảnh có nắng và đồi. Mỗi ngày là một trang câu chuyện." (a photo frame with sun and hills). Screenshot saved: `figma-notes/img/logo_sheet_35-240.png`.

| Component set | Node | Variants | Size | Description |
|---|---|---|---|---|
| Logo/Mark | 35:180 | Style = Color 35:152, Color Night 35:159, Mono Ink 35:166, Mono White 35:173 | 160×160 | "Child Life logo — Khoảnh khắc: một khung ảnh có nắng và đồi. Color is bound to logo/* variables, so it switches to the night palette automatically in Night care. Color Night = fixed night palette (for assets outside Figma modes). Mono Ink / Mono White for one-colour use. Corner radius ≈ 31% of the side." |
| Logo/Lockup Horizontal | 35:217 | Style = Color 35:181, Color Night 35:190, Mono Ink 35:199, Mono White 35:208 | 517×100 | "Lockup ngang cho phương án 2: khung ảnh + wordmark "child life"." (TopBar Brand uses it at 28px height) |
| Logo/Lockup Stacked | 36:335 | Style = Color 36:295, Color Night 36:305, Mono Ink 36:315, Mono White 36:325 | 389×282 | — |
| Logo/Wordmark | 33:31 | Style = Color 33:19, Mono Ink 33:23, Mono White 33:27 | 389×78 | "Wordmark "child life", lower-case, Be Vietnam Pro SemiBold −2.5 tracking, outlined. Color variant uses ink (flips in Night care)." |
| Logo/App Icon | 35:239 | Appearance = Light 35:218, Dark 35:225, Tinted 35:232 | 1024×1024 | "App icon 1024 full-bleed cho phương án 2 (iOS tự bo góc). Light / Dark / Tinted." |

App icon visuals (from screenshot): Light = mint sky, yellow sun, white wave band, deep-teal ground; Dark = dark-ink sky, yellow sun, teal bands; Tinted = black/grey/white greyscale. iOS size ladder shown on sheet: 180 (iPhone), 120, 87, 80 (Spotlight), 60, 40, 29, 20 + Dark 120 + Tinted 120.

Archived (do NOT use): "Mầm" option 1 — frames 33:18 (Mark), 33:74 (Lockup Horizontal), 33:75 (Lockup Stacked), 33:94 (App Icon), sheet 34:26 "Mầm — phương án 1 (không dùng)". Its sheet contains brand rules that likely still apply (not restated on the official sheet): clear space = sun diameter (x) on every side; minimum size mark ≥ 16px, horizontal lockup ≥ 96px wide; don't recolor, rotate, distort, or add shadow/stroke.

Rendering note: in the official sheet screenshot the large Overview mark (35:246) and the two mono avatars (35:312, 35:318) render clipped/misshapen — likely an instance-override/render glitch in Figma; use the component set 35:180 as the source of truth.

Android adaptive icon / web favicon / PWA assets: **not present** in Figma.

---

## 11. Design-system open questions

1. **Motion durations**: duration-tap / quick / base / breath / slow are referenced but have no values anywhere in Figma; no keyframes/easing/prototype data on any inspected node. Engineering must define ms values + curves (suggest documenting them as a token table and getting sign-off).
2. **Night care shadows**: Foundations says Night care uses separate "Night care/…" styles for sheet, chip, tab bar, raised cards, but only `Night care/shadow-tile` and `Night care/shadow-sheet` exist on screens; Night screens still bind Light shadow-nav/chip/card. Need values for Night care/shadow-chip, -nav, -lift (and confirm cards have no shadow in Night).
3. **Night care trigger semantics**: ThemeOption offers Sáng / Tối / Tự động plus a separate "Night care" schedule toggle (21:00–06:00) and auto-on when a sleep timer starts. Is "Tối" == Night care palette? Does "Tự động" follow OS dark mode or the schedule? What happens when the timer ends — revert? Component default subtitle ("Tự tối khi ghi sau 21:00") differs from screen copy ("Theo lịch 21:00 – 06:00").
4. **Pump (Hút sữa) category** is not on the Care categories board and its variables use a different naming/code-syntax (`care/pump/*` vs `--care-*`). Confirm it is a first-class category (it has CareTile, TimelineItem, Mini art, Timer screen).
5. **Platform**: Cover says "Ứng dụng iOS" and icons are "placeholder drawing; production uses SF Symbols"; widgets are iOS-only (App Intents, Live Activity, Dynamic Island). The brief requires Flutter iOS + Android — need an Android icon set (Material Symbols? custom SVG export of the placeholders?), Android widget/notification equivalents, Android adaptive app icon.
6. **Extra fonts in StoryCard**: Lora and Dancing Script (both OFL / Google Fonts) are used only in StoryCard templates — confirm licensing/bundling and Vietnamese glyph coverage (Dancing Script Vietnamese support should be verified).
7. **Non-token values**: HeroCard / SheetHeader / BottomSheet title use 24/32 SemiBold (no named style); Inter Regular 12 appears on 13 Giao diện (43:2013, 43:2038); StoryCard and MediaTile gradients use raw colors. Add a `Text/title-2 24/32 SemiBold` style or map to an existing one?
8. **SleepTimer arc color**: description says "arc mint", but the component binds `care-sleep-accent` (#6C6FD8). Which is final?
9. **Tabular figures** required for timers/numbers: Be Vietnam Pro supports `tnum` — confirm in Flutter via `FontFeature.tabularFigures()`.
10. **Dynamic Type**: "Map sang Dynamic Type, không khóa cỡ chữ; … cỡ chữ 200%" — QuickAction grid switches 4→2 columns at accessibility sizes; other breakpoints are unspecified.
11. **Deprecated/archived assets** to exclude from implementation: TabBar (deprecated · icon-only) 10:168; Logo "Mầm" archived frames; StatusBar & Keypad are mockup-only (use system).
12. **Cover text is stale** ("chưa có logo") — confirm the "Khoảnh khắc" logo is final.
13. **Components without descriptions**: MemberRow, RelationChip, ReminderRow, Lock/* widgets, DynamicIsland/Sleep, MediaTile, UploadPill, QueueRow, StoryCard — behavior must be inferred from screens.
14. Figma MCP top-level page listing returns only Cover and Logo; Foundations/Components/screens canvases are reachable only by id — confirm no hidden pages are missing from our index.

---

## Coverage

Read successfully: Color 18:2 (Light + Night incl. design context of 18:178), Typography 18:351, Spacing/Radius/Shadow 18:414, Care categories 52:4491; variable defs on 46:2266, 70:4386, 50:3572, 70:4567, 105:9797, 113:11207, 113:11255, 36:2233, 36:2249, 26:359, 35:180, 10:188; design context of all requested Components sections (8:98, 8:102, 9:159, 9:162, 10:188, 11:211, 23:379, 45:408, 73:399, 131:860, 132:898, 132:1036, 207:225, 24:365) and 13 Giao diện 29:1063; get_motion_context on all 10 requested nodes; Cover 0:1 and Logo 33:2 metadata; logo sheet screenshot.

Not read: section 8:2 Icons description text (8:4) — its title/description node only (icon list itself complete via metadata); descriptions of Illustration/GrowthStory, Care, Handover, Family (root symbols); Night-mode values for Night care/shadow-chip/-nav/-lift (not found anywhere).
