# Child Life — Launch Film / Remotion (handoff)

Figma: file `sJLG1fAXKDnDr9YI6Yx8ex` · page **Child Life — Launch Film / Remotion** (807:1883).
Format: 1920×1080 · 30fps · 1800 frames (60s). Vertical: 1080×1920 (same timing, HERO_9x16 layouts).
Chapter 01 — First Moments (0–12 months). Message: “Cùng chăm con, giữ từng khoảnh khắc con lớn lên.” Tagline: “Growing together, every step of the way.” Pillars: Care · Grow · Remember.

## Page layout
- `A · Brand reference`: logo, colors, type, components, motion rules, open items. Internal only, not in the video.
- `B · Storyboard`: 8-scene contact sheet and a timeline bar.
- `E · Handoff chung`: Remotion structure, layer conventions, export list, safe zones, music.
- Each scene is one row, holding these frames:
  - START (x0)
  - HERO (x2040)
  - END (x4080)
  - MID, only for S03 and S05 (x0, one row below)
  - HERO_9x16 (x6120)
- Next to each scene's frames:
  - a `Handoff · Sxx` panel (x7320), with timing, layer order, local frames, easing, transition, assets and sound
  - an auto-extracted state table

## Timeline (sums to 60s / 1800f)
| Scene | Time | Frames | Text |
|---|---|---|---|
| S01 Opening | 0–5s | 0–150 | Con lớn lên / từng ngày. |
| S02 Intro | 5–10s | 150–300 | Cùng chăm con. / Giữ từng khoảnh khắc. |
| S03 Care | 10–19s | 300–570 | Nhẹ hơn những ngày bận rộn. + Bú · Ngủ · Thay tã |
| S04 Grow | 19–27s | 570–810 | Nhìn con lớn lên, / từng chút một. |
| S05 Remember | 27–39s | 810–1170 | Có những khoảnh khắc… / mình muốn giữ mãi. → Từ ảnh hằng ngày / thành những kỷ niệm đáng xem lại. |
| S06 Family | 39–46s | 1170–1380 | Cả nhà / cùng bên con. |
| S07 Personal | 46–53s | 1380–1590 | Đồng hành theo / nhịp lớn của con. |
| S08 Brand | 53–60s | 1590–1800 | Logo · headline · tagline · CTA “Khám phá Child Life” · childlife.app (hold ≥3s) |

## Motion tokens

These come from the file's Motion page, plus two film-only tokens.

| Token | Value |
|---|---|
| motion.instant | 100ms, bezier(0.2,0,0,1) |
| motion.quick | 200ms, bezier(0.2,0,0,1) |
| motion.standard | spring {stiffness:380, damping:33.5, mass:1} (iOS response .35, damping .86) |
| motion.exit | 250ms, bezier(0.4,0,1,1) |
| motion.gentle | 600ms, bezier(0.3,0,0,1) |
| film.gentle | 600–800ms, bezier(0.3,0,0,1) |
| film.spring.soft | {stiffness:120, damping:20, mass:1} |

- **Text in:** opacity 0→1 and translateY 24→0 over 600ms. The second line starts 6f later.
- **Text out:** opacity →0 and translateY −16 over 250ms.
- **Never animate everything at once.** Stagger thẻ/ảnh by 3–10f.

## Remotion structure
```
<Composition id="ChildLifeLaunch" width={1920} height={1080} fps={30} durationInFrames={1800}/>
<Composition id="ChildLifeLaunchVertical" width={1080} height={1920} fps={30} durationInFrames={1800}/>
<Series> S01 150 · S02 150 · S03 270 · S04 240 · S05 360 · S06 210 · S07 210 · S08 210 </Series>
```
- Shared bridge layers (Accent/Sun, Photo, AppScreen) should render above the Series, so they survive cuts between scenes.
- Interpolate between the START, MID, HERO and END states below, on the local frame ranges given in each Handoff panel.
- Coordinates are the top-left corner of the layer, in frame px. For scale, use w ÷ w at HERO, with the origin at the layer's center.

## Layer naming
- Allowed names: `Background`, `Headline`, `Headline/2`, `SupportingText`, `AppScreen/<screen>`, `Photo/<name> · PLACEHOLDER`, `Card/<type>`, `Accent/<shape>`, `Logo`, `CTA` (with `CTA/Button`, `CTA/Label`, `CTA/URL`).
- Reference-only layers, which should not render:
  - names starting with `_`
  - names containing "không render"
  - `Accent/LineReveal`, which is a clip mask

## Assets (export from Figma)

**SVG:**
- Logo/Lockup Horizontal Color (35:181), Logo/Mark (35:180)
- Accent/Sun, Accent/Band
- Feed, sleep and diaper icons
- Growth line vector (346:47846)

**PNG @2x:**

| Asset | Source node |
|---|---|
| A1 Hôm nay | 273:879 |
| A2 sheet Bú bình | 273:921; export the sheet region y431–812 separately |
| A3 Đã ghi | 273:950 |
| Toast | 273:976 |
| 10a Nhật ký | 133:16184 |
| Growth card | 346:47820; hide "Bình thường", the WHO band and median, the legend and the WHO link |
| 3d milestone | 311:1436 |
| Thiệp "1 tháng" | 531:9389 |
| Video preview | 530:9437 |
| Album Giờ tắm | 188:472 |
| MemberRow | 116:11310 / 11318 / 11327 / 11335 |
| 2a Thẻ theo tuổi | 310:42550; the age card 310:42591 at @3x |
| 10d Album | 135:17615 |

**Photos:**
- All photos are low-resolution placeholders from Illustration/Photo (131:758).
- Replace them with licensed photos of at least 2000px.

## Content guardrails
- No health evaluation: no "đạt chuẩn", "chậm", or WHO band.
- No medical advice. Lumi is not shown.
- No paywall, pricing, user counts or testimonials.
- No App Store / Google Play badges until the release is confirmed. The CTA label can switch to "Tải Child Life" after launch.
- Vertical safe zone: keep text out of the top 220px and the bottom 380px, with a 140px right margin.

## Music cues
Use a licensed piano/acoustic track at 72–80 BPM.

| Time | Cue |
|---|---|
| 0s | Opening |
| 5s and 7s | Two beats under the intro lines |
| 12.2s | Tap tick |
| 12.7s | Save "pop" |
| 19s | Scene change into Grow |
| 27s | Photos fly in |
| 32.7s | Swell (climax) |
| 53s | Resolving chord |
| 54–60s | Fade out |

The film must read with the sound off.

## Open items
1. Licensed baby and family photos.
2. Re-export the A1–A3 screens at @3x from the source screens (19, 19a, 22); the Proto frames are raster.
3. Confirm the release status for the CTA.
4. A music license.
5. The dev.childlife.app website was not reachable (robots), so copy was taken from Website V9 in Figma.