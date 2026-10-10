# Design assets — Child Life (Figma `sJLG1fAXKDnDr9YI6Yx8ex`, FINAL)

Exported read-only from Figma on 2026-10-10 via the Figma MCP (`get_design_context` asset URLs for vectors, `get_screenshot` for references).
All SVGs were checked with `xmllint`. Every file starts with `<svg` (no HTML or error pages).

Cleanup applied to **every** SVG:
- Removed Figma web-only root attributes: `preserveAspectRatio="none"`, `overflow="visible"`, `style="display: block;"`.
- Converted Figma `<mask>` elements to equivalent `<clipPath>` elements (`mask="url(#x)"` → `clip-path="url(#x)"`). They are alpha masks with a solid fill and inside-stroke masks. flutter_svg does not honour `mask-type:alpha`, so a mask could render the logo invisible. The clipPath gives the same result. This affects every `logo/mark-*`, every `logo/lockup-h-*`, `illustrations/mini-diaper.svg` and `illustrations/mini-pump.svg`.

---

## 1. `icons/`: 39 line icons (Components page, frame `7:6`)

Format: SVG, `viewBox="0 0 24 24"`, 24×24, stroke-based, `stroke-width="1.8"`, round caps and joins, root `fill="none"`.
**Colour substitution (all 39):** `stroke="#173D44"` (ink) → `stroke="currentColor"`. `fill="none"` is unchanged. Tint the icons with `ColorFilter` or `SvgPicture(colorFilter:)`, or use `currentColor` through the theme.

| File | Node | Bytes | | File | Node | Bytes |
|---|---|---|---|---|---|---|
| feed.svg | 7:9 | 494 | | globe.svg | 22:165 | 684 |
| sleep.svg | 7:12 | 795 | | cake.svg | 22:169 | 650 |
| diaper.svg | 7:16 | 695 | | clock.svg | 22:173 | 511 |
| heart.svg | 7:19 | 658 | | link.svg | 22:177 | 1102 |
| today.svg | 7:23 | 589 | | upload.svg | 22:180 | 441 |
| memories.svg | 7:27 | 889 | | journal.svg | 22:184 | 560 |
| family.svg | 7:33 | 952 | | drop.svg | 22:187 | 438 |
| plus.svg | 7:36 | 274 | | ruler.svg | 22:191 | 534 |
| back.svg | 7:39 | 256 | | star.svg | 22:194 | 327 |
| arrow-right.svg | 7:42 | 272 | | brand-mark.svg | 22:197 | 936 |
| check.svg | 7:45 | 262 | | search.svg | 37:292 | 460 |
| cloud-off.svg | 7:49 | 928 | | backspace.svg | 44:295 | 614 |
| alert.svg | 7:53 | 518 | | chevron-down.svg | 44:298 | 263 |
| spark.svg | 7:56 | 329 | | edit.svg | 44:302 | 400 |
| lock.svg | 7:60 | 665 | | sunrise.svg | 59:388 | 592 |
| close.svg | 7:63 | 301 | | sunset.svg | 59:392 | 591 |
| chevron-right.svg | 7:66 | 264 | | sliders.svg | 166:22720 | 761 |
| eye.svg | 22:153 | 563 | | bookmark.svg | 178:24812 | 253 |
| mail.svg | 22:157 | 517 | | retry.svg | 186:802 | 477 |
| camera.svg | 22:161 | 537 | | | | |

Notes:
- **sliders.svg (geometry tweak):** in Figma the two knobs had `fill="white"` to hide the track line behind them, which only works on white backgrounds. Instead, the track paths now stop at the knob edge: `M4 8H7.4M10.6 8H20` and `M4 16H13.4M16.6 16H20`. The knob fill is removed, so the icon is fully `currentColor` and looks the same on any background.
- **brand-mark.svg:** the Figma description says it is a placeholder for the Apple / Google marks. Use the official logos in production.
- The Figma description says every icon is a "placeholder drawing; production uses SF Symbols".

## 2. `logo/`: Logo page (official "Khoảnh khắc" mark)

Brand colours are kept as hard-coded hex values. No `currentColor` is used here.

| File | Source node | Format | Size | Notes |
|---|---|---|---|---|
| mark-color.svg | Logo/Mark 35:180 → Style=Color 35:152 | SVG | 160×160 | #2CBFB3 frame, #FFD166 sun, white band, #087F7B ground. The Light values of the `logo/*` variables are baked in. |
| mark-night.svg | 35:180 → Color Night 35:159 | SVG | 160×160 | #173D44 / #FFD166 / #2E8F8A / #3FD0C3 |
| mark-mono-ink.svg | 35:180 → Mono Ink 35:166 | SVG | 160×160 | Tonal ink: #173D44, white, #A9B6B8 |
| mark-mono-white.svg | 35:180 → Mono White 35:173 | SVG | 160×160 | White frame with #173D44 / #A9B6B8 details, as in Figma |
| lockup-h-color.svg | Logo/Lockup Horizontal 35:217 → Color 35:181 | SVG | 517.421×100 | **Composed:** mark-color scaled to 100px, a 28px gap, then wordmark-color (389.421×78, centred at y=11) |
| lockup-h-night.svg | 35:217 → Color Night 35:190 | SVG | 517.421×100 | Composed: mark-night + **Mono White** wordmark, matching the Figma variant mapping |
| lockup-h-mono-ink.svg | 35:217 → Mono Ink 35:199 | SVG | 517.421×100 | Composed: mark-mono-ink + Mono Ink wordmark |
| lockup-h-mono-white.svg | 35:217 → Mono White 35:208 | SVG | 517.421×100 | Composed: mark-mono-white + Mono White wordmark |
| wordmark-color.svg | Logo/Wordmark 33:31 → Color 33:19 | SVG | 389.421×78 | Outlined text, fill #173D44. Figma says the Color variant "flips in Night care", so use the night lockup or tint it yourself. |

The lockups are composed because the MCP exports a lockup as two separate assets (mark + wordmark). They were rebuilt with the exact Figma auto-layout values (mark 100px, gap 28, centred) and checked visually against the Figma render.

## 3. `app_icon/`: Logo/App Icon 35:239

| File | Source node | Format | Size |
|---|---|---|---|
| app-icon-light-1024.png | Appearance=Light 35:218 | PNG, 8-bit RGB (no alpha), sRGB | 1024×1024 |
| app-icon-dark-1024.png | Appearance=Dark 35:225 | PNG, 8-bit RGB (no alpha), sRGB | 1024×1024 |
| app-icon-tinted-1024.png | Appearance=Tinted 35:232 | PNG, 8-bit RGB (no alpha), sRGB | 1024×1024 |
| app-icon-{light,dark,tinted}-fullbleed.svg | same nodes | SVG source | 1024×1024 |

**Full-bleed: confirmed.** All 4 corner pixels are opaque, the minimum alpha is 255, and the PNGs carry no alpha channel.

The PNGs are not raw `get_screenshot` output. The Figma component frame clips the art to `rx=232`, so the screenshot had transparent rounded corners, even though the description says "1024 full-bleed (iOS rounds the corners)". The vector art itself is full-bleed, so the PNGs were rendered from the vector with the frame clip removed. The colours match the Figma hex values exactly: Light #2CBFB3 / #FFD166 / white / #087F7B; Dark #173D44 / #FFD166 / #2E8F8A / #3FD0C3; Tinted black / white / #5E5E5E / #BDBDBD.

Android adaptive-icon layers, favicons and PWA icons do not exist in Figma.

## 4. `illustrations/`

All illustrations are exported as **SVG vectors** (no PNG fallback was needed). They contain only the **art layer**, with a transparent background.

The coloured card background and corner radius belong to the container in Figma and are not in the SVG. Draw them in Flutter using the token listed in the table. Live text and FloatChips are **not** in the SVGs; they are separate layers in Figma and must be built as widgets on top. Colours are fixed hex values (Light palette); none were substituted.

| File | Source node | Size (viewBox) | Container bg / radius | Text and chips **not** included (overlay in code) |
|---|---|---|---|---|
| welcome.svg | Illustration/Welcome 24:183 | 343×392 | card-mint #2CBFB3 / radius-hero 36 | 3 FloatChips: "120 ml" (feed icon), "1:24" (sleep icon), "Mốc mới" (heart, sunshine lead) |
| sign-in.svg | Illustration/SignIn 24:355 | 375×440 | card-mint, full-bleed (no radius) | ⚠ Block letters **"B"** and **"é"** are live text and are missing from the blocks. Draw them as Be Vietnam Pro SemiBold 56, #173D44, rotated −8° / +8°, centred at about (149, 234) / (229, 254). A PNG fallback was not usable because `get_screenshot` returned only 1x (375×440). |
| verify-email.svg | Illustration/VerifyEmail 25:238 | 343×300 | card-mint / 36 | — |
| recover.svg | Illustration/Recover 25:251 | 343×200 | card-sun #FFD166 / 36 | — (the bow hole is baked as #FFD166, the card-sun value) |
| account-link.svg | Illustration/AccountLink 25:260 | 343×236 | card-mint / 36 | Initial "M" (SemiBold 40, white, centred at x≈108) |
| invite-code.svg | Illustration/InviteCode 25:269 | 343×236 | card-sun / 36 | "Bà" on the ticket avatar (SemiBold 12, #173D44, −8°). Ticket notches are baked as #FFD166. |
| invite.svg | Illustration/Invite 25:282 | 343×212 | card-mint / 36 | Inviter initial "M" (SemiBold 34, white, centred at x≈124) |
| expired.svg | Illustration/Expired 25:298 | 343×320 | surface-2 #EEF6F5 / 36 | — |
| baby-avatar.svg | Illustration/BabyAvatar 25:308 | 148×148 | none | **Composed:** art + camera button (40px #087F7B circle with a 3px #F6FCFB cloud ring at (106,104), plus the white 20px camera icon) |
| baby-face.svg | Illustration/BabyFace 25:323 | 36×36 | none | — |
| today-hero-empty.svg | TodayHero/Empty 25:361 | 343×172 | card-night #173D44 / radius-sheet 32 | "Lần cuối" / "Chưa có ghi chép" / "Ghi khi cần nhé." |
| mini-bottle.svg | Illustration/Mini/Bottle 25:334 | 56×56 | none | — |
| mini-drop.svg | Illustration/Mini/Drop 25:341 | 56×56 | none | — |
| mini-moon.svg | Illustration/Mini/Moon 25:345 | 56×56 | none | — |
| mini-diaper.svg | Illustration/Mini/Diaper 25:350 | 56×56 | none | — (mask converted to clipPath) |
| mini-ruler.svg | Illustration/Mini/Ruler 25:356 | 56×56 | none | **Composed:** the MCP exported only the inner 52×20.8 group. It was rebuilt with the Figma transform `rotate(-10 28 28) translate(2 17.2)`. |
| mini-wet-dirty.svg | Illustration/Mini/WetDirty 44:303 | 56×56 | none | — |
| mini-pump.svg | Illustration/Mini/Pump 106:621 | 56×56 | none | — (mask converted to clipPath) |
| care.svg | Illustration/Care 24:221 | 343×408 | card-mint / 36 | Badge text "3" / "chạm" (centred at x≈290). FloatChips: "Bú bình · 120 ml", "Ngủ · 1 giờ 20", "Thay tã · Ướt" |
| handover.svg | Illustration/Handover 24:251 | 343×408 | card-night #173D44 / 36 | Timer "Đang ngủ" + "01:24:08" (centred at x=171). FloatChips: "Đã đồng bộ", "Bú bình · 80 ml · Mẹ ghi", "Thay tã · Ướt · Ba ghi" |
| growth-story.svg | Illustration/GrowthStory 24:278 | 343×408 | card-peach #FFA58D / 36 | FloatChips: "Thẻ kỷ niệm tức thì", "Nhật ký tuần 8" |
| family.svg | Illustration/Family 24:314 | 343×408 | card-sun #FFD166 / 36 | Avatar initials "M", "B" (white), "Bà", "L" (#173D44). FloatChips: "Mời người thân", "Bạn chọn quyền". The small star badge (12px, node 24:339) **is** merged into the SVG at (82,64). |

All five chip illustrations (Welcome, Care, Handover, GrowthStory, Family) were exported **without** chip or text layers, so no text is baked into any vector.

## Not exported / limitations

- **Sign-in letters "Bé":** not in the SVG (see above). A high-resolution PNG was not possible because `get_screenshot` does not upscale past the node's natural size.
- **Logo/Lockup Stacked (36:335), Wordmark Mono variants (33:23, 33:27):** not requested, so not saved as standalone files. The Mono wordmarks are embedded inside the lockups.
- **Illustration/Photo (131:758), SelectTile and LogTile:** not requested.
- No Figma asset failed to download (every download returned HTTP 200 with `image/svg+xml` or `image/png`).
