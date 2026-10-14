# Remember 2.0 — 24 creative templates (Chapter 01, 0–12 months)

Status: **proposal for owner review** (2026-10-14). Creative specification for 12 Milestone Magic
cards (Flutter, drawn on the phone) and 12 Memory Story videos (Remotion, rendered on the server).
It is written against the data contract in `docs/product/keepsake-template-format.md` and
`packages/contracts/src/keepsakes.ts`, so every template is data published from the portal. Where a
template needs something the contract does not have yet, it is listed once in §2 (E-1 … E-12) and
referenced by id; every template also states what it does **without** that extension.

Not in scope: Figma screens, app UI changes (MM01–MM17 stay as designed), pricing (tiers below are
suggestions; Free/Premium is set in the portal, D-068 #8).

Contents:
- §1 Shared rules (formats, typography, colour, copy, fallbacks, assets, notation, brand mark)
- §2 Contract extensions this set needs
- §3 Cards C01–C12
- §4 Video system (scene kit, timing, motion, audio)
- §5 Videos V01–V12
- §6 Music briefs, sample media, rollout

---

## 1. Shared rules

### 1.1 Output

| | Cards | Videos |
|---|---|---|
| Formats | Dọc 4:5 (2160 × 2700), Vuông 1:1 (2160 × 2160), Story 9:16 (2160 × 3840) | 9:16, 1080 × 1920 |
| Files | PNG (lossless, default) or JPG q92 (MM12 "Lưu JPG") | MP4 H.264 High, yuv420p, CRF 20, 30 fps; AAC 160 kbps stereo 48 kHz; poster WebP |
| Drawn by | `KeepsakeCardView` (app), `CardPreview` (portal) — same layer rules | Remotion composition per template (`apps/renderer`) |
| Safe area | 5 % inset on every side for text; photos may bleed | Text inside x 80–1000 px, y 230–1590 px (clear of status bars and social overlays). Decoration may go anywhere |

Every card template ships all three formats unless noted. Video length is computed from the number
of photos (§4.2) and always lands inside the template's stated range.

### 1.2 Typography

All text is Vietnamese and English; every font below has full Vietnamese coverage (stacked
diacritics: ẫ ặ ễ ổ ợ ữ ỹ).

| Token | Family | Used for | Status |
|---|---|---|---|
| `beVietnamPro` | Be Vietnam Pro 400–700 | UI-like labels, dates, numbers, modern headlines | in contract |
| `lora` | Lora 400–700, italic | Elegant names and titles | in contract |
| `dancingScript` | Dancing Script 400–700 | Short script accents (≤ 4 words) | in contract |
| `playfair` | Playfair Display 400–700 | Editorial display numerals (C03, C11, V08, V09) | **E-1** |
| `baloo` | Baloo 2 500–800 | Rounded playful display (C07, C08, C12, V04, V06, V07, V12) | **E-1** |
| `patrickHand` | Patrick Hand 400 | Handwritten notes and letters (C09, V10) | **E-1** |

Without E-1: `playfair` → `lora` 700; `baloo` → `beVietnamPro` 700; `patrickHand` →
`dancingScript` 500 at 1.15× size.

Text rules (cards and videos):
- Sizes are fractions of the card width (cards) or px at 1080 wide (videos).
- A one-line text never wraps: it scales down to fit (already in the app, `FittedBox`). Minimum
  60 % of its size, then it is cut with "…".
- Multi-line texts wrap up to `maxLines`, then end with "…".
- An empty value draws nothing (already in the app). Layouts below never depend on an optional
  text for alignment.
- Script fonts (`dancingScript`, `patrickHand`) are never set in all caps. Display caps use
  `letterSpacing` 0.08 em (**E-4**). Without E-4, caps are written into the default copy instead
  ("THÁNG").
- Vietnamese line height ≥ 1.25 for any text with diacritics. English copy is drafted by
  engineering for owner review (D-012).

### 1.3 Colour

Each template has a default palette (`background`, `ink`, `accent`) and 2–3 alternates for MM11
"Màu". All `ink` on `background` pairs below are ≥ 4.5 : 1. Fixed colours (`#RRGGBB`) are used
only where the art needs them (gold foil, red seal). Templates whose overlay art is coloured state
which slots the alternates may change.

### 1.4 Data the templates read

Everything below is already on the phone or in the job snapshot. None of it goes to logs or
analytics (CLAUDE.md, security).

| Value | Source | Formatting (vi / en) | Fallback |
|---|---|---|---|
| `name` | Baby nickname (`MemoryCtx.nickname`) | as typed | "Bé" / "Baby" |
| `dob` | Baby private profile | `dd.MM.yyyy` / `MMM d, yyyy` | age-derived texts are hidden; template still renders |
| `date` | The occasion's day (age occasions: DOB + n; firsts: newest tagged memory; else today) | `dd.MM.yyyy` / `MMM d, yyyy` | today |
| `age` | `date` − `dob` | "3 tháng", "100 ngày", "1 tuổi" / "3 months", "100 days", "1 year" | hidden |
| `ageNumber`, `ageUnit` | same | "3" + "THÁNG" / "3" + "MONTHS"; days < 31 → NGÀY/DAYS; 12 months → "1" + "TUỔI"/"YEAR" | hidden |
| `occasion` | The occasion's title (`keepsake_occasions.dart`) | "1 tháng", "Lần đầu biết lẫy" | the template's `title` default |
| `birthStats` | Earliest growth record (`weightKg`, `lengthCm`) within 7 days of `dob` | "3,2 kg · 50 cm" / "3.2 kg · 50 cm"; one value alone if only one is recorded | hidden |
| `photoLabelN` | Photo N's `takenAt` − `dob` | "Ngày đầu", "Tuần 2", "Tháng 6" / "Day 1", "Week 2", "Month 6" | editable; default "Lúc ấy" / "Then", "Bây giờ" / "Now" |
| photo `takenAt` | Media item (EXIF, else upload time) | — | upload order |

Age wording: day 0–13 → days; 14–59 → weeks; 60–364 → months (floor); 365+ → years.

### 1.5 Photo slots

- Photos are the parent's own media (`MediaItem`), never uploaded to the catalog.
- Cards: the parent picks per slot and can pan/zoom inside the slot ("Chạm ảnh để đổi · kéo để căn").
  Each slot below states its aspect and where faces should sit.
- Videos: the parent picks N photos in scene order (MM06). Each scene states its crop: `cover`
  (fill, focal point centre-upper third) or `contain` (whole photo on a blurred copy of itself).
- Portrait / landscape mix: video scenes with `cover` use a focal point at 40 % height. When a
  landscape photo goes into a portrait frame it is never stretched; `contain` scenes exist for
  that.

### 1.6 Assets

Decorative art is uploaded in the portal (Tệp) as transparent WebP, at most 2160 px wide (cards) or
1080 px (videos). Naming: `{template}-{part}`, e.g. `c04-bear-left`. Art direction for every asset
is in the template's "Assets" table; each one must work on all of that template's palettes (neutral
or palette-independent colours) unless noted.

**Overlay frames.** Organic or torn frames (C04, C05, C09) are drawn as an `image` layer *above* the
photo: an opaque border in the background colour with a transparent window. This works with
today's primitives; the trade-off is that the overlay's colour is fixed, so those templates'
alternates keep `background`. E-5 (masks) would remove the trade-off.

### 1.7 Layer notation (cards)

Each layout is the exact layer list, bottom to top. A line maps 1 : 1 to a contract layer:

```
bg     <color> [asset]                                  → background
photo  s<slot> (x,y,w,h) rect|circle [r=<radius>]       → photo
text   <field> (x,y,w,h) <font> <weight> <size> <color> <align> [lines=n] [italic] [op=<opacity>] [caps] [rot=<deg>]
shape  rect|circle|star (x,y,w,h) <color> [→<gradientTo>] [r=<radius>] [stroke=<w>]
image  <asset> (x,y,w,h) cover|contain|fill [op=<opacity>] [rot=<deg>]
```

Rects are fractions of the card (x, y = top-left). Colours are palette slots (`background`, `ink`,
`accent`) or hex. `caps` needs E-4; `rot` needs E-3 (without it the element is drawn level). Text
`lines` defaults to 1.

Square and Story layouts follow the Dọc one; only changed rects are listed ("Δ").

`brand` lines need E-13:

```
brand  lockup|wordmark|mark (x,y,w,h) <color> [op=<opacity>]           → brand (E-13)
```

### 1.8 Child Life brand mark (owner, 2026-10-14: every template carries the logo)

Every card and every video shows the official Child Life logo — the horizontal **lockup** (photo-frame
mark + "child life" wordmark, `apps/mobile/assets/logo/lockup-h-*.svg`, aspect 5.17 : 1). It is
part of the template, not something the parent can remove.

Cards:
- One `brand` layer per format, listed in every layout below (last line, on top).
- Drawn from the SVG bundled in the app (and the portal / renderer), recoloured to a single colour:
  normally the palette's `ink` (so it always contrasts with the background and follows "Màu"),
  `#FFFFFF` when it sits on a photo. Never the multicolour lockup on a template palette.
- Size: width 0.16 of the card width in every format (346 × 67 px at 2160 wide); minimum rendered
  height 48 px. Opacity 0.6–0.75 so it signs the card without competing with the baby.
- Place: inside a 3 % edge inset, never over a face, never overlapping text. Usually centred under
  the last text line, or in the bottom-right corner when the text block is left-aligned.
- Rect height per format for w = 0.16: Dọc 0.0248, Vuông 0.031, Story 0.0174.

Videos:
- `BrandMark` (§4.3) on every scene: lockup 200 px wide, bottom-right (80 px from the right, 280 px
  from the bottom, below the polaroid frames); opacity from the template's `brand.opacity` (0.75);
  palette `ink` over flat backgrounds, white with a soft shadow over full-bleed photos.
- Configurable per video template (`brand`: `corner`, `endCard`, `opacity`; portal "Logo Child
  Life"); a change publishes a new template version. Jobs freeze the template, so a video already
  made, or retried from an older job, keeps the branding it was asked with.
- `EndCard` shows the lockup again, 320 px wide, centred at y 1480, full opacity, fading in with
  the closing line.
- The same applies to the "Xem mẫu" preview MP4s and the WebView player (they use the same
  compositions).

Without E-13 (cards): an `image` layer with an uploaded `brand-lockup-ink` / `brand-lockup-white`
WebP at the same rect. This cannot follow "Màu", so the template's alternates are limited to
palettes of the same lightness as the default until E-13 ships.

---

## 2. Contract extensions this set needs

Each is a small, separate change. Cards need an **app release** for E-1 to E-6 (the app draws
cards); videos need a renderer + Functions deploy only. Suggested order: E-2, E-6, E-7, E-8 first
(they unlock most templates), then E-13 (brand), E-1, E-3, E-4, then the rest.

| Id | Change | Where | Unlocks | Without it |
|---|---|---|---|---|
| E-1 | Fonts `playfair`, `baloo`, `patrickHand` (bundled; OFL) | contracts `keepsakeFonts`, app fonts, portal `fonts`, renderer `@remotion/google-fonts` or bundled files | C03, C07, C08, C09, C11, C12, V04, V06–V10, V12 | fallbacks in §1.2 |
| E-2 | Text fields `age`, `ageNumber`, `ageUnit`, `birthStats`, `headline`, `message`, `photoLabel0`, `photoLabel1` | contracts `keepsakeTextFields`; app value map (§1.4) | C01, C02, C03, C10, C11, C12 | template text keys only |
| E-3 | `rotate` (degrees, −45…45) on `photo`, `text`, `shape`, `image` | contracts layer schema; app `Transform.rotate`; portal CSS | C08, C09, C12 (playful tilt) | drawn level |
| E-4 | `letterSpacing` (em) and `caps` on `text` | contracts; app `TextStyle`; portal | C03, C11, C12 | caps written in copy; default spacing |
| E-5 | `mask` (asset, alpha) on `photo` | contracts; app `ShaderMask`/`ClipPath` via image alpha; portal CSS mask | C04, C05 organic frames with palette-free colours | overlay frames (§1.6) |
| E-6 | Cards with 2 photos (`photos.max` 2; memories accept 2 media for a card creation) | contracts `memories.ts` card rule; app MM11 two slots | C09 (2nd photo optional), C10 | C10 not offered; C09 one photo |
| E-7 | Occasions `birth`, `m2`…`m11`, `m6` alias, `laughs`, `sits_up`, `stands`, `first_tooth`, `first_solids`, `first_word` | contracts `occasions` (milestone ids exist: `p_laughs`, `p_sits_up`, `p_first_tooth`, `p_first_solids`, `p_first_word`; add `p_stands`, `p_birth`); app titles; nudges (D-068 #9) only for age occasions | C01, C03, C08, C09, V01, V05, V07, V09 | those templates use "any occasion" with an editable title |
| E-8 | Video props v2 (§4.1): photo metadata (takenAt → age label), `locale`, `texts` map (`title`, `message`, `closing`, `lines`, `letter`, `headline`), `birthStats`, `dob` | contracts `KeepsakeJobInput`, `requestMemoryStory`; Functions; renderer | every new video | V1 props only (title, message, dateLine, mark) |
| E-9 | Template text keys `headline`, `closing`, `lines` (multi-line, one entry per line), `letter` (≤ 400) | contracts `keepsakeTextFieldSchema`; MM07 shows one input per key the template declares | V03, V09, V10, V12 | defaults only |
| E-10 | Short video clips in videos (≤ 3 s used per clip, muted, `OffthreadVideo`) | renderer, job input (media kind), MM06 allows videos | V06 | photos only |
| E-11 | Music moods `emotional`, `romantic`, `uplifting`, `festive`, `cinematic` | contracts `keepsakeMoods`; portal labels | §6 | closest existing mood |
| E-12 | `@remotion/transitions` 4.0.529 and `@remotion/google-fonts` (or bundled fonts) in the renderer | `apps/renderer/package.json` | all videos | hand-written crossfades |
| E-13 | Layer `brand` {`kind`: lockup \| wordmark \| mark, `rect`, `color`, `opacity`}, drawn from the bundled logo SVGs tinted to `color`; catalog check: every published card format has exactly one `brand` layer | contracts layer schema + `keepsakeTemplateSchema` refine; app (`ClLogo` assets with a colour filter); portal `CardPreview`; renderer `BrandMark` | the brand rule (§1.8) on every card | `image` layer with an uploaded lockup WebP (§1.8) |

Data rules that go with E-2 / E-8: `birthStats` and `dob` are child data; they are rendered, never
logged. The job snapshot already holds the photos; adding `dob` and growth values follows the same
retention (deleted with the job).

---

## 3. Milestone Magic cards

Common to all cards unless stated:
- Photo slot 0 is required; the card cannot be exported without it (MM11 shows "Chạm để chọn ảnh").
- Editable texts are the template's `texts` (keys `title`, `quote`, `message`, `headline`), shown in
  MM11 "Chữ" with their max length. Auto texts (`name`, `date`, `age`, …) come from §1.4 and are not
  editable on the card (they are edited in the baby's profile).
- `nameDate` = "Name · date".

### C01 — Welcome, Little One · `card_welcome_little_one`

| | |
|---|---|
| Occasion / age | `birth` (E-7; today: any), ageDays 0–30 |
| Tier (suggested) | Free |
| Mood | Peaceful, precious, timeless. A birth announcement you would frame |
| Formats | Dọc, Vuông, Story |
| Fonts | `lora` (name, title), `beVietnamPro` (details) |

Palettes (MM11 "Màu"):

| | background | ink | accent | Note |
|---|---|---|---|---|
| Kem (default) | `#F7F1E6` | `#3A2E26` | `#B08D57` | warm cream, espresso ink, antique gold |
| Hồng sữa | `#F8ECE8` | `#3D2A2E` | `#C08A86` | |
| Xanh sương | `#EEF2F0` | `#25363A` | `#7D9C94` | |

Photo: slot 0, portrait 4:5 window, rounded 2 %; face in the upper half.

Texts:

| Key / field | Source | vi default | en default | Max | Fallback |
|---|---|---|---|---|---|
| `title` | template | Chào con, thiên thần nhỏ | Welcome, little one | 40 | — |
| `name` | auto | — | — | — | "Bé" |
| `date` | auto (DOB) | 14.10.2026 | Oct 14, 2026 | — | today |
| `birthStats` (E-2) | auto | 3,2 kg · 50 cm | 3.2 kg · 50 cm | — | hidden; the details line moves up (layout reserves no gap — see rule) |
| `quote` | template | Con là điều kỳ diệu nhất của ba mẹ | You are our sweetest miracle | 60 | hidden when cleared |

Assets:

| Asset | Size | Description |
|---|---|---|
| `c01-paper` | 2160 × 3840 | Very subtle cotton-paper grain, neutral grey on transparent, 6 % visible; tiles to any crop |
| `c01-sprig` | 600 × 240 | Fine-line olive sprig, single stroke 6 px, warm grey `#8C8172`, transparent |
| `c01-rule` | 1200 × 24 | Hairline with a centred tiny diamond, `#B08D57` gold |

Layout — Dọc 4:5:

```
bg     background c01-paper
shape  rect (0.07,0.055,0.86,0.89) accent r=0.01 stroke=0.002        # hairline gold border
image  c01-sprig (0.40,0.063,0.20,0.03)  contain op=0.8
photo  s0 (0.14,0.10,0.72,0.52) rect r=0.02
text   title     (0.10,0.645,0.80,0.05)  lora 400 0.042 ink center italic
text   name      (0.10,0.70,0.80,0.085)  lora 600 0.085 ink center
image  c01-rule  (0.30,0.795,0.40,0.008) contain
text   date      (0.10,0.815,0.80,0.035) beVietnamPro 500 0.028 ink center op=0.75
text   birthStats(0.10,0.853,0.80,0.035) beVietnamPro 500 0.028 accent center
brand  lockup    (0.42,0.90,0.16,0.0248) ink op=0.6
```

Δ Vuông: photo `(0.22,0.08,0.56,0.50)`; title y 0.605; name y 0.655; rule y 0.755; date y 0.775;
birthStats y 0.815; brand `(0.42,0.865,0.16,0.031)`; `quote` not shown.
Δ Story: photo `(0.12,0.11,0.76,0.50)`; title y 0.64; name y 0.685 size 0.09; rule y 0.775; date
y 0.79; birthStats y 0.825; `quote` added `(0.12,0.865,0.76,0.06) lora 400 0.036 ink center italic
lines=2`; brand `(0.42,0.925,0.16,0.0174)`.

Optional line: when `birthStats` is empty its line stays empty (layers do not reflow). The gap sits
between the date and the brand mark and reads as breathing room; no extension is needed.

### C02 — My First Week · `card_my_first_week`

| | |
|---|---|
| Occasion / age | `d7`, ageDays 5–21 |
| Tier | Free |
| Mood | Gentle, cute, heartwarming |
| Fonts | `beVietnamPro` 700 (7), `dancingScript` (ngày), `lora` (title) |

Palettes:

| | background | ink | accent |
|---|---|---|---|
| Mây hồng (default) | `#FBEFF1` | `#3E3350` | `#F2A7B8` |
| Mây xanh | `#ECF4FB` | `#2E3B55` | `#9CC3EA` |
| Mây vàng | `#FFF6E3` | `#4A3A28` | `#F5C76B` |

Photo: slot 0, circle; face centred.

Texts:

| Key / field | vi | en | Max | Fallback |
|---|---|---|---|---|
| `ageNumber` (E-2; without: fixed "7" in `title`) | 7 | 7 | — | "7" (the occasion is d7) |
| `ageUnit` | ngày | days | — | — |
| `title` | Tuần đầu tiên của {name} | {name}'s first week | 40 | — |
| `message` (optional) | Bảy ngày, và ba mẹ đã yêu con hơn cả thế giới. | Seven days, and we already love you more than the world. | 90 | hidden |
| `date` | auto | auto | | |

Assets:

| Asset | Size | Description |
|---|---|---|
| `c02-clouds-top` | 2160 × 900 | Three soft white clouds with a faint pale-lilac shadow, flat vector, fluffy edges, transparent |
| `c02-clouds-bottom` | 2160 × 700 | Two clouds, mirrored rhythm to the top set |
| `c02-stars` | 2160 × 2160 | 9 tiny 4-point sparkles and dots scattered around a central empty circle (keeps the photo clear), white with 60 % opacity |
| `c02-moon` | 300 × 300 | Small smiling crescent, soft yellow `#F5D68A` |

Layout — Dọc:

```
bg     background
image  c02-stars        (0.00,0.02,1.00,0.80) contain
image  c02-clouds-top   (-0.05,-0.02,1.10,0.30) contain
shape  circle (0.205,0.155,0.59,0.472) #FFFFFF                     # white ring behind the photo
photo  s0     (0.225,0.171,0.55,0.44) circle
image  c02-moon         (0.74,0.14,0.12,0.096) contain
text   ageNumber (0.10,0.625,0.38,0.17) beVietnamPro 700 0.17 accent right
text   ageUnit   (0.50,0.665,0.40,0.10) dancingScript 700 0.085 ink left
text   title     (0.08,0.79,0.84,0.05) lora 600 0.048 ink center
text   message   (0.12,0.845,0.76,0.07) beVietnamPro 400 0.03 ink center lines=2 op=0.8
image  c02-clouds-bottom(-0.05,0.86,1.10,0.18) contain
text   date      (0.10,0.915,0.80,0.03) beVietnamPro 500 0.024 ink center op=0.6
brand  lockup    (0.42,0.952,0.16,0.0248) ink op=0.6
```

Δ Vuông: photo + ring move to y 0.10/0.085, size w 0.50; ageNumber/ageUnit y 0.60; title y 0.77;
message hidden; date y 0.88; brand `(0.42,0.925,0.16,0.031)`.
Δ Story: stars `(0,0.05,1,0.6)`; ring+photo y 0.14, w 0.62; ageNumber y 0.56 size 0.2; ageUnit y
0.61; title y 0.73; message y 0.785 lines=3; clouds-bottom y 0.88; date y 0.93; brand
`(0.42,0.962,0.16,0.0174)`.

### C03 — Monthly Milestone · `card_monthly_milestone`

| | |
|---|---|
| Occasion / age | `m1`…`m11` (E-7), `y1`; ageDays 25–380. Without E-7: `m1`, `y1` and "any" |
| Tier | Free |
| Mood | Modern, minimal, stylish — a magazine cover |
| Fonts | `playfair` 700 (numeral, E-1), `beVietnamPro` 600 (unit, labels) |

Palettes (all slots swappable; the layout is pure type):

| | background | ink | accent |
|---|---|---|---|
| Giấy trắng (default) | `#F4F1EC` | `#1E1E1E` | `#D9583B` (terracotta numeral) |
| Đen | `#141414` | `#F4F1EC` | `#E9C46A` |
| Xanh rêu | `#E6EBE3` | `#1F2B24` | `#4F7B5E` |
| Hồng đất | `#F3E4DE` | `#2B1F1C` | `#B4534A` |

Photo: slot 0, portrait window 0.62 × 0.60 of the card, square corners; face upper third.

Texts:

| Field | vi | en | Fallback |
|---|---|---|---|
| `ageNumber` | 3 | 3 | the occasion's number |
| `ageUnit` (caps, E-4) | THÁNG | MONTHS | — |
| `name` | auto | | "Bé" |
| `date` | auto | | |
| `quote` (optional) | Lớn thêm một chút, thương thêm thật nhiều. | A little bigger, loved a lot more. | hidden |

No assets — the typography is the art.

Layout — Dọc (numeral overlaps the photo edge, magazine style):

```
bg     background
photo  s0 (0.30,0.07,0.62,0.60) rect r=0
text   ageNumber (0.04,0.40,0.56,0.40) playfair 700 0.40 accent left        # bottom half overlaps photo
text   ageUnit   (0.07,0.79,0.40,0.05) beVietnamPro 600 0.045 ink left caps
shape  rect (0.07,0.855,0.10,0.003) ink                                    # short rule
text   name      (0.07,0.87,0.86,0.05) beVietnamPro 700 0.05 ink left
text   date      (0.07,0.925,0.50,0.03) beVietnamPro 500 0.026 ink left op=0.6
text   quote     (0.50,0.80,0.43,0.10) lora 400 0.028 ink right lines=3 italic op=0.8
brand  lockup    (0.77,0.93,0.16,0.0248) ink op=0.7
```

Two-digit numerals ("10", "11"): `ageNumber` is one line, so it scales down to fit its rect
(§1.2). Year ("1" + "TUỔI" / "YEAR") reads the same.
Δ Vuông: photo `(0.40,0.06,0.54,0.62)`; numeral `(0.04,0.36,0.52,0.40)`; unit y 0.76; rule y
0.825; name y 0.84; date y 0.90; quote hidden; brand `(0.77,0.905,0.16,0.031)`.
Δ Story: photo `(0.18,0.06,0.76,0.56)`; numeral `(0.04,0.47,0.70,0.30)` size 0.44; unit y 0.77;
rule y 0.83; name y 0.845; date y 0.895; quote `(0.07,0.93,0.86,0.05)` left lines=2; brand top-right
`(0.81,0.03,0.16,0.0174)` (above the photo, which starts at 0.06).

### C04 — Little Teddy Bear · `card_little_teddy`

| | |
|---|---|
| Occasion / age | `m1`, `d100` (+ any month with E-7); ageDays 20–130 |
| Tier | Premium |
| Mood | Cozy, adorable, nostalgic — a teddy on a knitted blanket |
| Fonts | `lora` 700 (title), `beVietnamPro` (details) |

Palettes (overlay art is beige; alternates change `ink`/`accent` only):

| | background | ink | accent |
|---|---|---|---|
| Caramel (default) | `#EFE2CF` | `#4A3426` | `#B9804F` |
| Cacao | `#EFE2CF` | `#3B2A22` | `#8A5A3C` |
| Mật ong | `#EFE2CF` | `#4A3426` | `#D49A3A` |

Photo: slot 0 under an organic blob window (≈ 0.70 × 0.56); face centre.

Texts:

| Key / field | vi | en | Max |
|---|---|---|---|
| `title` | {name} tròn {age} | {name} is {age} | 40 |
| `quote` | Mỗi ngày bên con là một cái ôm thật ấm. | Every day with you is a warm hug. | 70 |
| `date` | auto | | |

`{age}` in `title` is filled by the app from §1.4 (E-2); without E-2 the default reads
"Gấu con của ba mẹ" / "Our little bear".

Assets:

| Asset | Size | Description |
|---|---|---|
| `c04-blanket` | 2160 × 3840 | Soft knitted-blanket texture in beige `#EFE2CF` with gentle cable pattern, low contrast; also the page background |
| `c04-frame-blob` | 2160 × 2700 (+ `-square` 2160², `-story` 2160 × 3840) | Overlay: beige knit fill with a transparent organic rounded window (soft pebble shape) and a stitched dashed edge in caramel `#B9804F` |
| `c04-bear-peek` | 900 × 700 | Plush teddy peeking over the window's lower-left edge, paws resting on it; warm brown felt with visible fuzz, hand-painted look |
| `c04-heart` | 220 × 200 | Tiny felt heart, caramel |

Layout — Dọc:

```
bg     background c04-blanket
photo  s0 (0.12,0.07,0.76,0.62) rect r=0.06
image  c04-frame-blob (0,0,1,1) fill
image  c04-bear-peek  (0.02,0.53,0.42,0.26) contain
image  c04-heart      (0.80,0.10,0.09,0.065) contain
text   title (0.30,0.735,0.62,0.07) lora 700 0.06 ink left lines=2
text   quote (0.30,0.825,0.62,0.07) beVietnamPro 400 0.03 ink left lines=2 op=0.85
text   date  (0.30,0.905,0.62,0.03) beVietnamPro 600 0.026 accent left
brand  lockup (0.76,0.945,0.16,0.0248) ink op=0.6
```

Δ Vuông: uses `c04-frame-blob-square`; photo `(0.16,0.06,0.68,0.60)`; bear `(0.02,0.50,0.38,0.28)`;
title `(0.36,0.70,0.58,0.08)`; quote hidden; date y 0.88; brand `(0.78,0.925,0.16,0.031)`.
Δ Story: `-story` frame; photo `(0.10,0.08,0.80,0.56)`; bear `(0.02,0.52,0.44,0.20)`; title
`(0.08,0.73,0.84,0.06)` center; quote `(0.10,0.80,0.80,0.07)` center lines=3; date center y 0.89;
brand `(0.42,0.935,0.16,0.0174)`.

### C05 — Blooming With Love · `card_blooming_love`

| | |
|---|---|
| Occasion / age | any (title is the milestone); ageDays any |
| Tier | Premium |
| Mood | Natural, elegant, delicate — watercolour botanicals |
| Fonts | `lora` 600 italic (title), `dancingScript` 600 (name), `beVietnamPro` (date) |

Palettes (florals are sage/blush/cream art; alternates change ink/accent):

| | background | ink | accent |
|---|---|---|---|
| Sương (default) | `#F6F3EC` | `#2F3A31` | `#C9897F` |
| Lá non | `#F6F3EC` | `#2F3A31` | `#7E9C7A` |
| Hồng phấn | `#F6F3EC` | `#3A2C2C` | `#D49A97` |

Photo: slot 0, arch window (top fully rounded) 0.60 × 0.58; face upper centre.

Texts:

| Key / field | vi | en | Max |
|---|---|---|---|
| `title` | Nở rộ trong yêu thương | Blooming with love | 40 |
| `occasion` | auto (e.g. "100 ngày") | | |
| `name` | auto | | |
| `date` | auto | | |

Assets:

| Asset | Size | Description |
|---|---|---|
| `c05-arch` | 2160 × 2700 (+ square, story) | Overlay: cream fill with a transparent arch window (radius = half width) |
| `c05-bloom-top` | 1600 × 1100 | Watercolour garland of blush peonies, sage eucalyptus, tiny white buds, cascading from top-right over the arch; soft edges, transparent |
| `c05-bloom-bottom` | 1400 × 800 | Smaller cluster bottom-left: leaves + one bloom, overlapping the arch base |
| `c05-petals` | 2160 × 2700 | 5–6 loose falling petals, 30 % opacity |

Layout — Dọc:

```
bg     background
photo  s0 (0.20,0.08,0.60,0.58) rect r=0
image  c05-arch        (0,0,1,1) fill
image  c05-petals      (0,0,1,1) contain op=0.6
image  c05-bloom-top   (0.42,0.02,0.56,0.27) contain
image  c05-bloom-bottom(0.06,0.52,0.40,0.18) contain
text   occasion (0.10,0.69,0.80,0.04) beVietnamPro 600 0.03 accent center caps
text   title    (0.08,0.735,0.84,0.065) lora 600 0.058 ink center italic
text   name     (0.10,0.81,0.80,0.07) dancingScript 600 0.07 accent center
text   date     (0.10,0.895,0.80,0.03) beVietnamPro 500 0.026 ink center op=0.7
brand  lockup   (0.42,0.94,0.16,0.0248) ink op=0.6
```

Δ Vuông: photo `(0.27,0.06,0.46,0.56)`; blooms scaled 0.85; occasion y 0.65; title y 0.69;
name y 0.77; date y 0.86; brand `(0.42,0.905,0.16,0.031)`.
Δ Story: photo `(0.14,0.09,0.72,0.52)`; bloom-top `(0.40,0.04,0.58,0.22)`; occasion y 0.65; title
y 0.69 lines=2; name y 0.775; date y 0.86; brand `(0.42,0.915,0.16,0.0174)`.

### C06 — Dreamy Little Star · `card_dreamy_star`

| | |
|---|---|
| Occasion / age | any; best with `m1`, `d100` |
| Tier | Premium |
| Mood | Magical, peaceful, dreamy — a night sky with the baby on the moon |
| Fonts | `lora` 700 (title), `beVietnamPro` (details) |

Palettes:

| | background | ink | accent |
|---|---|---|---|
| Nửa đêm (default) | `#1C2541` | `#F4EBDD` | `#D8B76A` (muted gold) |
| Tím đêm | `#272042` | `#F2E9F1` | `#C9A3D9` |
| Xanh biển | `#0F2E3D` | `#EAF2F1` | `#9ED0C9` |

Photo: slot 0, circle "moon" with a soft glow ring; face centred.

Texts:

| Key / field | vi | en | Max |
|---|---|---|---|
| `title` | Ngôi sao nhỏ của ba mẹ | Our little star | 40 |
| `occasion` | auto ("1 tháng") — large | | |
| `quote` | Ngủ ngoan nhé, ngôi sao nhỏ. | Sleep tight, little star. | 50 |
| `nameDate` | auto | | |

Assets:

| Asset | Size | Description |
|---|---|---|
| `c06-sky` | 2160 × 3840 | Tiny white and gold dot stars plus a faint white nebula haze (8 %) on transparent, so the palette background shows through and "Màu" keeps working |
| `c06-moon-glow` | 1600 × 1600 | Radial cream glow, 35 % centre → 0 edge |
| `c06-crescent` | 700 × 700 | Gold-line crescent hugging the photo circle's upper-left edge |
| `c06-cloudline` | 2160 × 600 | Low wispy clouds, white 25 % |

Layout — Dọc:

```
bg     background
image  c06-sky        (0,0,1,1) cover
image  c06-moon-glow  (0.12,0.02,0.76,0.61) contain
photo  s0 (0.23,0.11,0.54,0.432) circle
shape  circle (0.225,0.106,0.55,0.44) accent stroke=0.004
image  c06-crescent   (0.15,0.06,0.33,0.26) contain
shape  star (0.82,0.12,0.05,0.04) accent
shape  star (0.10,0.42,0.035,0.028) accent
shape  star (0.86,0.48,0.03,0.024) ink
text   occasion (0.08,0.60,0.84,0.10) lora 700 0.095 accent center
text   title    (0.08,0.705,0.84,0.05) lora 400 0.045 ink center italic
image  c06-cloudline (0,0.76,1,0.16) contain
text   quote    (0.12,0.82,0.76,0.05) beVietnamPro 400 0.03 ink center lines=2 op=0.85
text   nameDate (0.10,0.915,0.80,0.03) beVietnamPro 600 0.026 ink center op=0.7
brand  lockup   (0.42,0.955,0.16,0.0248) ink op=0.6
```

Δ Vuông: photo/ring `(0.29,0.08,0.42,0.42)`; occasion y 0.56; title y 0.665; quote hidden; nameDate
y 0.88; brand `(0.42,0.925,0.16,0.031)`. Δ Story: photo/ring `(0.18,0.12,0.64,0.36)`; occasion y
0.55 size 0.11; title y 0.66; quote y 0.75 lines=3; cloudline y 0.80; nameDate y 0.92; brand
`(0.42,0.955,0.16,0.0174)`.

### C07 — My First Smile · `card_first_smile`

| | |
|---|---|
| Occasion / age | `first_smile`, `laughs` (E-7); ageDays 21–200 |
| Tier | Free |
| Mood | Joyful, cheerful, energetic |
| Fonts | `baloo` 800 (headline, E-1), `beVietnamPro` |

Palettes:

| | background | ink | accent |
|---|---|---|---|
| Nắng (default) | `#FFE9A8` | `#3B2A14` | `#FF7A59` |
| Bạc hà | `#CFF1E6` | `#173D35` | `#FF8FA3` |
| Kẹo | `#FFD9E4` | `#41203A` | `#7C5CFF` |

Photo: slot 0, big rounded rectangle tilted −3° (E-3); face fills the frame.

Texts:

| Key | vi | en | Max |
|---|---|---|---|
| `title` | Nụ cười đầu tiên! | My first smile! | 30 |
| `quote` | Nụ cười của con làm cả nhà bừng sáng. | Your smile lights up our whole home. | 70 |
| `nameDate` | auto | | |

For `laughs`, the default title is "Tiếng cười đầu tiên!" / "My first giggle!" (the app picks the
default by occasion; E-7).

Assets:

| Asset | Size | Description |
|---|---|---|
| `c07-smileys` | 2160 × 2700 | 6 hand-drawn smiley doodles, sun rays and squiggles around the edges (none in the centre), white + `#3B2A14` outlines, transparent |
| `c07-burst` | 1400 × 1400 | Sunburst behind the headline, white 50 % |
| `c07-sticker` | 500 × 500 | Round white sticker with a coral outline and a laughing-face doodle (no words, so it works in vi and en) |

Layout — Dọc:

```
bg     background
image  c07-smileys (0,0,1,1) contain
shape  rect (0.10,0.075,0.80,0.60) #FFFFFF r=0.05 rot=-3              # white mat
photo  s0   (0.13,0.098,0.74,0.555) rect r=0.04 rot=-3
image  c07-sticker (0.70,0.56,0.22,0.176) contain rot=8
image  c07-burst   (0.10,0.62,0.80,0.30) contain
text   title    (0.06,0.69,0.88,0.10) baloo 800 0.09 ink center
text   quote    (0.12,0.80,0.76,0.07) beVietnamPro 500 0.032 ink center lines=2
text   nameDate (0.10,0.905,0.80,0.03) beVietnamPro 700 0.028 accent center
brand  lockup   (0.42,0.948,0.16,0.0248) ink op=0.7
```

Δ Vuông: mat/photo `(0.17,0.06,0.66,0.56)`; title y 0.66; quote hidden; nameDate y 0.86; brand
`(0.42,0.91,0.16,0.031)`.
Δ Story: mat/photo `(0.08,0.08,0.84,0.56)`; title y 0.69 size 0.1; quote y 0.79 lines=3; nameDate
y 0.90; brand `(0.42,0.945,0.16,0.0174)`.

### C08 — Look What I Can Do! · `card_i_can_do_it`

| | |
|---|---|
| Occasion / age | `rolls_over`, `sits_up`, `crawls`, `stands`, `first_steps` (E-7 adds sits_up, stands); ageDays 90–420 |
| Tier | Free |
| Mood | Proud, playful, celebratory — a gold medal and stickers |
| Fonts | `baloo` 800, `beVietnamPro` 700 |

Palettes:

| | background | ink | accent |
|---|---|---|---|
| Xanh trời (default) | `#DCEEFF` | `#14253D` | `#FF9F1C` |
| Cỏ non | `#E2F5D9` | `#1C3317` | `#F25F5C` |
| Tím mộng | `#ECE4FF` | `#24184A` | `#FFB703` |

Photo: slot 0, rounded square 0.70 × 0.56, face centre.

Texts (title default depends on occasion; parent can edit):

| Occasion | vi `title` | en `title` |
|---|---|---|
| rolls_over | Con biết lẫy rồi! | I rolled over! |
| sits_up | Con ngồi vững rồi! | I can sit up! |
| crawls | Con biết bò rồi! | I can crawl! |
| stands | Con đứng được rồi! | I can stand! |
| first_steps | Con đi được rồi! | I took my first steps! |
| (any) | Nhìn con làm được nè! | Look what I can do! |

| Other | vi | en | Max |
|---|---|---|---|
| `headline` (E-2, badge text) | Kỹ năng mới | New skill | 16 |
| `date` | auto | | |
| `name` | auto | | |

Assets:

| Asset | Size | Description |
|---|---|---|
| `c08-badge` | 800 × 800 | Rosette medal: gold scalloped ribbon + accent-neutral white centre (text drawn by the `headline` layer on top) |
| `c08-stickers` | 2160 × 2700 | Confetti dots, stars, a rocket, a thumbs-up and a "WOW" bubble around the edges; flat, saturated, white outlines like vinyl stickers |
| `c08-tape` | 400 × 140 | Two strips of washi tape, pale yellow |

Layout — Dọc:

```
bg     background
image  c08-stickers (0,0,1,1) contain
shape  rect (0.13,0.10,0.74,0.59) #FFFFFF r=0.06 rot=2
photo  s0   (0.15,0.115,0.70,0.56) rect r=0.05 rot=2
image  c08-tape  (0.40,0.08,0.20,0.05) contain rot=-4
image  c08-badge (0.66,0.55,0.30,0.24) contain rot=10
text   headline (0.70,0.64,0.22,0.06) baloo 800 0.032 ink center rot=10 lines=2
text   title (0.06,0.72,0.70,0.12) baloo 800 0.075 ink left lines=2
text   name  (0.06,0.865,0.60,0.04) beVietnamPro 700 0.04 accent left
text   date  (0.06,0.91,0.60,0.03) beVietnamPro 600 0.027 ink left op=0.7
brand  lockup (0.78,0.93,0.16,0.0248) ink op=0.7
```

Δ Vuông: photo `(0.17,0.07,0.60,0.55)`; badge `(0.70,0.47,0.27,0.27)`; title `(0.06,0.68,0.64,0.12)`;
name y 0.83; date y 0.88; brand `(0.78,0.905,0.16,0.031)`. Δ Story: photo `(0.10,0.10,0.80,0.52)`;
badge `(0.64,0.52,0.32,0.18)`; title `(0.06,0.68,0.88,0.10)` center; name y 0.80 center; date y
0.845 center; brand `(0.42,0.93,0.16,0.0174)`.

### C09 — Tiny Firsts · `card_tiny_firsts`

| | |
|---|---|
| Occasion / age | `first_tooth`, `first_solids`, `first_word` (E-7), plus any "first"; ageDays 120–420 |
| Tier | Premium |
| Mood | Personal, handmade, nostalgic — a scrapbook page |
| Fonts | `patrickHand` (notes, E-1), `lora` 700 (title) |
| Photos | 1 required + 1 optional (E-6). Without E-6: one photo, the second polaroid shows a doodle |

Palettes (kraft paper is art; alternates change ink/accent):

| | background | ink | accent |
|---|---|---|---|
| Giấy kraft (default) | `#E9DCC6` | `#3A2F25` | `#C0573E` |
| Kraft xanh | `#E9DCC6` | `#24363A` | `#3F7F8C` |

Texts:

| Occasion | vi `title` | en `title` |
|---|---|---|
| first_tooth | Chiếc răng đầu tiên | My first tooth |
| first_solids | Bữa ăn dặm đầu tiên | My first meal |
| first_word | Tiếng gọi đầu tiên | My first word |
| (any) | Lần đầu tiên của con | My tiny first |

| Other | vi | en | Max |
|---|---|---|---|
| `message` (the story) | Hôm nay con … Ba mẹ ghi lại để mai sau con đọc nhé. | Today you … We wrote it down so you can read it one day. | 140 |
| `date` | auto | | |
| `name` | auto | | |

Assets:

| Asset | Size | Description |
|---|---|---|
| `c09-paper` | 2160 × 3840 | Kraft paper with fibres and a faint grid; slight vignette |
| `c09-polaroid-a` / `-b` | 1100 × 1300 | Overlay: white polaroid border with a transparent square window, soft drop shadow, slight paper curl |
| `c09-tape` | 420 × 140 | Torn masking tape, translucent beige |
| `c09-doodles` | 2160 × 2700 | Pencil doodles: arrows, small hearts, a spoon, a tooth, underline swooshes, in `#3A2F25` |
| `c09-note` | 1200 × 700 | Torn lined-notebook scrap |
| `c09-doodles-alt` | 900 × 700 | Pencil sketch of a heart and a little star, centred; fills the second polaroid when it has no photo |

Layout — Dọc:

```
bg     background c09-paper
photo  s0 (0.10,0.10,0.48,0.385) rect rot=-4
image  c09-polaroid-a (0.07,0.07,0.54,0.52) fill rot=-4
image  c09-tape (0.25,0.05,0.18,0.06) contain rot=-12
image  c09-doodles-alt (0.53,0.31,0.36,0.28) contain rot=5                   # covered by s1 when present
photo  s1 (0.52,0.30,0.38,0.30) rect rot=5                                  # optional (E-6)
image  c09-polaroid-b (0.495,0.275,0.43,0.40) fill rot=5
image  c09-tape (0.66,0.26,0.16,0.055) contain rot=14
image  c09-doodles (0,0,1,1) contain op=0.8
image  c09-note (0.06,0.68,0.88,0.24) fill rot=-1
text   title   (0.12,0.615,0.76,0.06) lora 700 0.055 ink left rot=-2
text   message (0.12,0.72,0.76,0.13) patrickHand 400 0.036 ink left lines=4 rot=-1
text   date    (0.12,0.87,0.40,0.035) patrickHand 400 0.03 accent left rot=-1
text   name    (0.52,0.87,0.36,0.035) patrickHand 400 0.03 accent right rot=-1
brand  lockup  (0.42,0.94,0.16,0.0248) ink op=0.6
```

When slot 1 is empty the photo layer draws nothing and `c09-doodles-alt` shows through the second
polaroid. Without E-6 that is always the case.
Δ Vuông: one polaroid only (s0) `(0.14,0.07,0.44,0.43)`; note `(0.55,0.20,0.40,0.55)` with
title/message inside, message lines=5; brand `(0.78,0.93,0.16,0.031)`. Δ Story: polaroids stacked
vertically (s0 top-left, s1 mid-right), note bottom `(0.06,0.70,0.88,0.22)`; brand
`(0.42,0.945,0.16,0.0174)`.

### C10 — Then & Now · `card_then_now`

| | |
|---|---|
| Occasion / age | any; ageDays 30–420 (needs a gap between photos) |
| Tier | Premium |
| Mood | Emotional, reflective, surprising |
| Fonts | `beVietnamPro` (labels), `lora` 700 (title) |
| Photos | 2 required (E-6). **Not offered without E-6** |

Palettes:

| | background | ink | accent |
|---|---|---|---|
| Sữa (default) | `#FAF7F2` | `#232323` | `#E07A5F` |
| Than | `#1D1D1F` | `#F5F2EC` | `#F2CC8F` |
| Xanh xám | `#EDF1F3` | `#1F2A30` | `#3D8A9B` |

Photo slots: s0 "then" (older), s1 "now" (newer); the app sorts the pair by `takenAt` so s0 is
always the older one.

Texts:

| Key / field | vi | en | Max | Fallback |
|---|---|---|---|---|
| `title` | Con lớn nhanh quá! | Look how you've grown! | 36 | |
| `photoLabel0` (E-2) | Ngày đầu | Day 1 | 14 | "Lúc ấy" / "Then" |
| `photoLabel1` | Tháng 6 | Month 6 | 14 | "Bây giờ" / "Now" |
| `name` | auto | | | |

Layout — Dọc (side by side, timeline under):

```
bg     background
text   title (0.06,0.06,0.88,0.07) lora 700 0.06 ink center
photo  s0 (0.06,0.16,0.43,0.54) rect r=0.02
photo  s1 (0.51,0.16,0.43,0.54) rect r=0.02
shape  rect (0.12,0.765,0.76,0.004) ink                    # timeline
shape  circle (0.255,0.752,0.03,0.024) accent
shape  circle (0.715,0.752,0.03,0.024) accent
text   photoLabel0 (0.06,0.79,0.43,0.05) beVietnamPro 700 0.04 ink center
text   photoLabel1 (0.51,0.79,0.43,0.05) beVietnamPro 700 0.04 accent center
text   name        (0.10,0.885,0.80,0.04) beVietnamPro 500 0.03 ink center op=0.7
brand  lockup      (0.42,0.94,0.16,0.0248) ink op=0.6
```

Δ Vuông: photos `(0.06,0.15,0.43,0.55)` / `(0.51,0.15,0.43,0.55)`; timeline y 0.75; labels y 0.775;
name y 0.87; brand `(0.42,0.92,0.16,0.031)`. Δ Story (stacked): title y 0.05; s0 `(0.08,0.12,0.84,0.36)`; label0 over s0 bottom-left
`(0.10,0.42,0.40,0.045)` white on a `#00000066` rect scrim; s1 `(0.08,0.52,0.84,0.36)`; label1 same at
y 0.82; vertical timeline `(0.045,0.14,0.004,0.72)` with two dots; name y 0.91; brand
`(0.42,0.95,0.16,0.0174)`.

### C11 — 100 Days of Love · `card_hundred_days_love`

| | |
|---|---|
| Occasion / age | `d100`, ageDays 90–130 |
| Tier | Premium |
| Mood | Meaningful, festive, sophisticated — inspired by Vietnamese family celebrations (lì xì red, gold, peach-blossom accents) without lanterns or dragons |
| Fonts | `playfair` 700 (100), `lora` (name), `beVietnamPro` |

Palettes:

| | background | ink | accent | Note |
|---|---|---|---|---|
| Kem đỏ (default) | `#F8F1E7` | `#5A1F1B` | `#B23A2E` | cream, deep red ink, festive red; gold is fixed art `#C2A15A` |
| Đỏ son | `#9E2B25` | `#FCEFD9` | `#E8C77A` | inverted, red ground |
| Kem vàng | `#F8F1E7` | `#3E2B17` | `#C2A15A` | |

Photo: slot 0, arched-top rectangle under a thin gold double frame; face centred.

Texts:

| Key / field | vi | en | Max |
|---|---|---|---|
| `headline` (E-2; without: in `title`) | 100 | 100 | — fixed |
| `title` | ngày yêu thương | days of love | 30 |
| `name` | auto | | |
| `date` | auto | | |
| `quote` | Trăm ngày bình an, trọn đời hạnh phúc. | A hundred peaceful days, a lifetime of joy. | 60 |

Assets:

| Asset | Size | Description |
|---|---|---|
| `c11-pattern` | 2160 × 3840 | Very faint repeating cloud-scroll (tường vân) motif, line art 4 % opacity, transparent |
| `c11-frame` | 2160 × 2700 (+ square, story) | Overlay: gold double-line frame with an arched top window, small corner flourishes; outside the window transparent (so background colour shows) |
| `c11-blossom` | 900 × 600 | Two peach-blossom sprigs (mai/đào), soft pink petals, gold stamens, corner placement |
| `c11-seal` | 300 × 300 | Round red seal with the numeral "100" in gold — palette-independent |

Layout — Dọc:

```
bg     background c11-pattern
photo  s0 (0.17,0.07,0.66,0.50) rect r=0.01
image  c11-frame   (0,0,1,1) fill
image  c11-blossom (0.60,0.02,0.38,0.17) contain
image  c11-seal    (0.70,0.47,0.16,0.128) contain
text   headline (0.10,0.585,0.80,0.15) playfair 700 0.16 accent center
text   title    (0.10,0.725,0.80,0.05) lora 400 0.05 ink center italic
shape  rect (0.42,0.79,0.16,0.002) #C2A15A
text   name     (0.10,0.805,0.80,0.05) lora 700 0.05 ink center
text   date     (0.10,0.86,0.80,0.03) beVietnamPro 500 0.026 ink center op=0.7 caps
text   quote    (0.12,0.895,0.76,0.045) lora 400 0.03 ink center italic lines=2
brand  lockup   (0.42,0.945,0.16,0.0248) ink op=0.6
```

Δ Vuông: photo `(0.25,0.06,0.50,0.48)`; seal hidden; headline y 0.55; title y 0.69; rule y 0.755;
name y 0.77; date y 0.83; quote hidden; brand `(0.42,0.90,0.16,0.031)`. Δ Story: photo
`(0.14,0.08,0.72,0.47)`; headline y 0.57 size 0.2; title y 0.72; rule y 0.785; name y 0.80; date y
0.855; quote y 0.895 lines=2; brand `(0.42,0.955,0.16,0.0174)`.

### C12 — My First Birthday · `card_first_birthday`

| | |
|---|---|
| Occasion / age | `y1`, ageDays 350–400 |
| Tier | Free |
| Mood | Joyful, colourful, memorable |
| Fonts | `baloo` 800 (ONE / 1 tuổi), `beVietnamPro` |

Palettes:

| | background | ink | accent |
|---|---|---|---|
| Kẹo bông (default) | `#FFF4E8` | `#2F2140` | `#FF6F91` |
| Bầu trời | `#E7F3FF` | `#172A46` | `#3D7BFF` |
| Chanh | `#F6FBE3` | `#24310F` | `#F4A300` |

Photo: slot 0, circle with a thick white ring; face centred.

Texts:

| Key / field | vi | en | Max |
|---|---|---|---|
| `headline` (E-2) | 1 tuổi | ONE | 10 |
| `title` | Mừng sinh nhật {name}! | Happy birthday, {name}! | 40 |
| `date` | auto | | |

Assets:

| Asset | Size | Description |
|---|---|---|
| `c12-balloons` | 1200 × 2000 | Bunch of 5 glossy balloons (pink, yellow, mint, lilac, blue) with curly strings, top-left |
| `c12-confetti` | 2160 × 3840 | Scattered confetti and streamers, multi-colour, clear centre |
| `c12-cake` | 700 × 700 | Small one-candle cake, pastel frosting, flat illustration |
| `c12-bunting` | 2160 × 400 | Pennant bunting across the top, multi-colour |

Layout — Dọc:

```
bg     background
image  c12-confetti (0,0,1,1) cover
image  c12-bunting  (0,0.00,1,0.13) contain
image  c12-balloons (0.00,0.08,0.36,0.48) contain rot=-6
shape  circle (0.26,0.14,0.60,0.48) #FFFFFF
photo  s0 (0.285,0.16,0.55,0.44) circle
image  c12-cake (0.70,0.50,0.22,0.176) contain
text   headline (0.06,0.62,0.88,0.17) baloo 800 0.17 accent center
text   title    (0.06,0.79,0.88,0.06) baloo 700 0.052 ink center
text   date     (0.10,0.87,0.80,0.03) beVietnamPro 600 0.028 ink center op=0.7
brand  lockup   (0.42,0.93,0.16,0.0248) ink op=0.7
```

Δ Vuông: balloons `(0,0.06,0.28,0.40)`; ring/photo `(0.32,0.10,0.50,0.50)`; headline y 0.60;
title y 0.77; date y 0.85; brand `(0.42,0.90,0.16,0.031)`. Δ Story: ring/photo
`(0.18,0.15,0.64,0.36)`; balloons `(0,0.10,0.34,0.30)`; cake `(0.70,0.45,0.24,0.135)`; headline y
0.55 size 0.2; title y 0.70 lines=2; date y 0.80; brand `(0.42,0.94,0.16,0.0174)`.

---

## 4. Video system

### 4.1 Props (E-8)

One prop shape for every composition (superset of today's `MemoryStoryProps`):

```ts
interface StoryProps {
  photos: { url: string; takenAt: string | null; ageLabel: string | null }[]; // scene order
  name: string;
  dob: string | null;              // ISO date; never logged
  locale: 'vi' | 'en';
  texts: Partial<Record<'title' | 'message' | 'closing' | 'headline' | 'lines' | 'letter', string>>;
  dateLine: string;                 // formatted by the server in `locale`
  mark: string | null;              // "1", "7", "100"
  birthStats: string | null;        // "3,2 kg · 50 cm"
  palette: { background: string; ink: string; accent: string };
  music: string | null;
  durationSec: number;              // computed by the server (§4.2), not the template's fixed value
}
```

`ageLabel` is computed by Functions from `takenAt − dob` with §1.4's wording (so the renderer has
no date logic). `{name}` in any text is replaced by the server.

### 4.2 Timing

All at 30 fps. Each template defines fixed scenes (intro, special cards, outro) and a per-photo
time range. The server computes:

```
perPhoto = clamp((maxTotal − fixed) / n, perMin, perMax)
total    = fixed + n × perPhoto − overlaps
```

so few photos stay at a comfortable pace and many photos never exceed the template's maximum.
Crossfade overlaps (15 frames unless stated) are subtracted. The template's `photos.min/max` in the
catalog equals the table below; `durationSec` in the catalog stores `maxTotal` (shown in lists).

### 4.3 Scene kit (`apps/renderer/src/kit/`)

Every composition is a timeline of these blocks, with `BrandMark` mounted over the whole timeline
(owner rule, §1.8). Each block takes `{props, from, length}` and
palette-driven colours; templates only configure them. Parameters in brackets.

| Block | What it draws | Motion (frames) |
|---|---|---|
| `TitleCard` [font, size, mark?, sub?] | Centered title, optional big mark, sub line | Words rise 40 px + fade, staggered 4 f; mark springs from 0.6 → 1 (damping 14) |
| `PhotoKenBurns` [crop, zoomFrom, zoomTo, driftX, driftY] | One photo full-bleed | Linear zoom 1.00 → 1.10 over the scene, drift ±30 px alternating; ease-in-out |
| `PhotoFramed` [frame: polaroid\|arch\|circle\|rounded, tilt] | Photo inside a frame on the palette background | Frame drops in: y +80 → 0, rotate tilt+4 → tilt, spring damping 12 |
| `PhotoBlurFill` | `contain` photo over a 40 px-blurred, 1.2× copy of itself | slow zoom 1.0 → 1.05 |
| `Collage` [layout: 2up\|3up\|4grid, gap] | 2–4 photos in a grid | Tiles pop in staggered 6 f, scale 0.85 → 1 spring; whole grid drifts up 20 px |
| `SplitCompare` [direction: horizontal\|wipe] | Two photos with labels | Wipe line moves 0 → 100 % over 30 f, ease-in-out; labels slide in |
| `TextOverlay` [position: top\|bottom\|center, style: caption\|handwritten\|label] | Text over a photo with a 0 → 55 % black gradient scrim | Fade 10 f, 20 px rise |
| `AgeLabel` | Pill "Tháng 3" bottom-left | Slide in from left 12 f |
| `Badge` [icon asset, text] | Circular badge/medal | Scale 0 → 1.1 → 1 spring, 6° wobble settle |
| `LetterPage` [font] | Lined paper with text revealed | Typewriter reveal 2 chars / frame for handwritten, line by line |
| `Countdown` [from] | "3, 2, 1" | Each number 15 f: scale 1.4 → 1, fade out |
| `Particles` [kind: stars\|confetti\|petals\|hearts, density] | Seeded random particles (`random(seed)`) | Fall / twinkle; deterministic per frame |
| `PaperTexture` [asset, opacity] | Overlay grain | static |
| `LightLeak` [color] | Warm radial leak sweeping across | 45 f, opacity 0 → 0.35 → 0 |
| `EndCard` [closing, name, signature] | Closing line, name, and the Child Life lockup 320 px wide at y 1480 (§1.8) | Same as TitleCard, lockup fades in 12 f after the closing; holds 1.5 s; music fades over last 45 f |
| `BrandMark` | Child Life lockup 200 px wide, bottom-right (80 px from the right, 280 px from the bottom), opacity from `brand.opacity` | Fades in over 15 f at frame 15 and stays; colour per scene: palette `ink` on flat backgrounds, white + 25 % shadow on photos; hidden during `EndCard` (which shows the large one) |

Transitions (`@remotion/transitions`, E-12): `fade()` 15 f, `slide({direction})` 18 f,
`wipe()` 20 f, `clockWipe` 24 f (V12 only), plus custom `paperFlip` (V02) and `iris` (V01, circle
mask opening from centre, 24 f). Springs use `{ damping: 14, mass: 0.8 }` unless stated.

### 4.4 Audio

- Music: the parent's pick or the template default (§6), started at 0, volume 0 → 0.8 over 30 f,
  held, faded to 0 over the last 45 f. Tracks are ≥ 75 s, so they never loop.
- No voice-over, no sound effects in V1 (keeps licensing to music only).

### 4.5 Fallbacks (all videos)

| Missing | Behaviour |
|---|---|
| Fewer photos than min | MM06 blocks "Tiếp tục" (existing); never rendered |
| `takenAt` | Photos stay in the parent's order; `ageLabel` hidden |
| `dob` | `ageLabel`, `birthStats`, `mark` hidden; titles without `{age}` |
| `birthStats` | V01's birth-details card shows name + date only |
| Long name | Title scales to fit width (min 60 %), then two lines |
| Texts cleared by the parent | That overlay is skipped; scene timing unchanged |
| Landscape photos | `cover` scenes crop around 40 % height; `PhotoBlurFill` for scenes marked `contain` |

### 4.6 Poster

Each composition exports `posterFrame(props)` (used by `renderStill` and the portal's auto-cover):
the middle of the first photo scene, or the frame stated per template.

---

## 5. Memory Story videos

Notation for scene tables: **Scene · length · block [params] · text · transition out**.

### V01 — Welcome to the World · `video_welcome_world` · composition `WelcomeWorld`

| | |
|---|---|
| Occasion / age | `birth` (E-7), ageDays 0–45 |
| Duration | 25–30 s · photos 5–8 |
| Timing | fixed 11.5 s (intro 4 + details 3.5 + outro 4); per photo 2.2–3.2 s |
| Style | Cinematic, timeless, emotional — dark-to-light, letterbox feel, warm film grain |
| Palette | default `#0E0D0C` / `#F5EFE6` / `#D9B77E` (black, warm white, soft gold); alt "Sáng" `#F7F1E6` / `#3A2E26` / `#B08D57` |
| Fonts | `lora` (name, closing), `beVietnamPro` 500 (details, tracking 0.12 em caps) |
| Music | mood `emotional` (E-11) — soft solo piano; default `music_ru_em` until the piano track exists |
| Poster | middle of the first photo scene |

Texts (MM07):

| Key | vi | en | Max |
|---|---|---|---|
| `title` | Chào con, {name} | Hello, {name} | 40 |
| `closing` (E-9) | Chào mừng con đến với thế giới của ba mẹ. | Welcome to our world, little one. | 70 |

Scenes:

1. **Intro · 4.0 s** · `TitleCard` on black: screen starts black; a soft white light blooms at
   centre (radial gradient opacity 0 → 1, frames 0–45); `title` fades in letter by letter (2 f
   per char) at y 900, `lora` 600 84 px; `dateLine` beneath at 36 px, 60 % opacity, from frame 60.
   Out: `iris` (24 f) opening onto photo 1.
2. **Photo 1 · perPhoto + 0.6 s** · `PhotoKenBurns` [zoom 1.15 → 1.00 (reverse, "revealing")],
   film grain 6 %, letterbox bars 90 px top/bottom (black) that slide away over the first 30 f.
   Out: `fade` 20 f.
3. **Birth details · 3.5 s** · `TitleCard` on background colour with `PaperTexture`:
   `name` (`lora` 700 110 px), gold hairline, `dateLine` ("Chào đời 14.10.2026" / "Born Oct 14,
   2026"), `birthStats` (accent). Lines appear staggered 8 f. Out: `fade`.
4. **Photos 2…n · perPhoto each** · alternate `PhotoKenBurns` (zoom in, drift L) and
   `PhotoKenBurns` (zoom out, drift R); a `LightLeak` (warm `#F3C98B`) on photos 3 and 6. Out:
   `fade` 15 f each.
5. **Outro · 4.0 s** · `EndCard`: background fades from black to `background` slowly
   (dark-to-light echo); `closing` in `lora` italic 64 px, max 3 lines; `name` below in accent.

### V02 — Our First Days · `video_our_first_days` · composition `OurFirstDays`

| | |
|---|---|
| Occasion / age | `d7`, `m1`; ageDays 3–45 |
| Duration | 25–35 s · photos 6–10 |
| Timing | fixed 8 s (intro 3.5 + outro 4.5); per photo 2.0–3.0 s |
| Style | Gentle, cozy, intimate — photos as prints on a linen table, paper texture, soft crossfades |
| Palette | default `#F3ECE2` / `#3B302A` / `#C98B6B`; alt `#EEF0EA` / `#2E3A33` / `#8FA58C` |
| Fonts | `lora` (title), `dancingScript` (date stamps) |
| Music | mood `warm` — acoustic guitar + piano; default `music_ru_em` |

Texts: `title` "Những ngày đầu bên nhau" / "Our first days together" (40); `message` "Cảm ơn con đã
đến, làm ba mẹ của con là món quà lớn nhất." / "Thank you for coming to us. Being your parents is
our greatest gift." (140).

Scenes:
1. **Intro · 3.5 s** · `TitleCard` over `PaperTexture` (linen asset `v02-linen`): `title` in
   `lora` 600 76 px; a hand-drawn underline draws itself (SVG path `strokeDashoffset`, 30 f).
2. **Photos · perPhoto** · `PhotoFramed` [frame: print — white 24 px border, 3 % shadow, tilt
   alternating −3° / +2°]; each print slides in from the bottom onto the previous one (stack of 3
   visible, older prints dim to 70 %); `AgeLabel` written in `dancingScript` on the print's bottom
   border ("Ngày 2", "Ngày 5"; from `ageLabel`). Transition: `paperFlip` (the top print lifts 8°
   and slides off left) every 3rd photo, `fade` otherwise.
3. **Message · 4.5 s** (outro) · `LetterPage` on cream: `message` revealed line by line
   (`lora` italic 54 px), signed "Ba mẹ" / "Mom & Dad" in `dancingScript`.

### V03 — Little Love Story · `video_little_love_story` · composition `LittleLoveStory`

| | |
|---|---|
| Occasion / age | `m1`, `m2`, `m3` (E-7), any; ageDays 20–120 |
| Duration | 25–35 s · photos 5–8 |
| Timing | fixed 7.5 s (intro 3.5 + outro 4); per photo 3.0–3.8 s (each carries a line) |
| Style | Poetic, warm, elegant — blush tones, serif type, each photo paired with a line of love |
| Palette | default `#F7E9E6` / `#4A2C33` / `#C76D7E`; alt `#EFE9F4` / `#3A2C4A` / `#9A7BBF` |
| Fonts | `lora` 400 italic (lines), `dancingScript` 700 (title) |
| Music | `romantic` (E-11) — strings + piano; default `music_ru_em` |

Texts: `title` "Chuyện tình nhỏ bắt đầu…" / "A little love story began…"; `lines` (E-9, one per
photo, cycled if fewer):

| # | vi | en |
|---|---|---|
| 1 | Ngày con đến, mọi thứ đều đổi khác. | The day you came, everything changed. |
| 2 | Bàn tay bé xíu nắm lấy tim ba mẹ. | Your tiny hand holds our hearts. |
| 3 | Mỗi tiếng thở của con là một bài hát. | Every breath you take is a lullaby. |
| 4 | Ba mẹ học yêu thương từ con. | You taught us a new kind of love. |
| 5 | Chậm thôi con, ba mẹ muốn nhớ hết. | Slow down, we want to remember it all. |
| 6 | Con là bình yên của nhà mình. | You are the calm of our home. |
| 7 | Nụ cười con làm ngày dài ngắn lại. | Your smile makes the long days short. |
| 8 | Và câu chuyện mới chỉ bắt đầu. | And the story has only begun. |

`closing` "Con là tình yêu lớn nhất của ba mẹ." / "You are our greatest love." (60).

Scenes:
1. **Intro · 3.5 s** · `TitleCard`: `title` in `dancingScript` 96 px, drawn with a left-to-right
   reveal mask (40 f); `Particles` [petals, low density].
2. **Photo + line · perPhoto** · `PhotoBlurFill` in the top 62 % (rounded 32 px card, 64 px side
   margin) over the palette background; the line below in `lora` italic 52 px, max 3 lines, fading
   in 12 f after the photo settles. Transition: `slide({direction: 'from-right'})` 18 f, the line
   cross-fades separately.
3. **Outro · 4.0 s** · `EndCard`: `closing`, `name`, a heart that draws itself (path, 30 f).

### V04 — Tiny Moments · `video_tiny_moments` · composition `TinyMoments`

| | |
|---|---|
| Occasion / age | any; ageDays any |
| Duration | 15–25 s · photos 6–12 |
| Timing | fixed 5 s (intro 2.5 + outro 2.5); photos shown in collages: 1-up, 2-up, 3-up groups, per photo 1.2–1.8 s |
| Style | Cute, energetic, fun — bouncy, stickers, bright |
| Palette | default `#FFF1D6` / `#2D2A32` / `#FF6B6B`; alt `#DDF4FF` / `#1D2B3A` / `#FFB703`; alt `#E9F9E4` / `#203522` / `#FF7AA2` |
| Fonts | `baloo` 800 (E-1), `beVietnamPro` |
| Music | `playful` — light ukulele/glockenspiel, ~115 bpm; default `music_nang_mai` |

Texts: `title` "Những khoảnh khắc nhỏ" / "Tiny moments" (30); `closing` "Khoảnh khắc nhỏ, kỷ niệm
lớn." / "Little moments, big memories." (50).

Grouping: photos are split into groups following the pattern `[1, 2, 3, 1, 2, …]` until all are
used (a last group of 1 is merged into the previous). Group length = size × perPhoto.

Scenes:
1. **Intro · 2.5 s** · `title` letters bounce in (each letter spring from y +120, stagger 2 f,
   damping 9); `Particles` [confetti dots]; sticker `v04-star` spins in.
2. **Groups** · `Collage` [1-up: rounded 40 px card at 88 % width, tilt ±3°; 2-up: stacked with
   10 px white borders; 3-up: one large + two small]; each group enters with `slide` from
   alternating sides and a "boing" overshoot (spring damping 10); 1–2 stickers per group from
   `v04-stickers` (hearts, star, "yay", milk bottle) pop at group start, positioned in fixed
   corners per layout. Beat-sync: group changes on 4-beat boundaries of the default track (115 bpm →
   2.09 s / 4 beats) when perPhoto allows.
3. **Outro · 2.5 s** · `closing` in `baloo` 72 px bouncing in; `name` sticker label.

Assets: `v04-stickers` (sprite sheet 6 × 512 px, flat, white outline), `v04-star`.

### V05 — Growing So Fast · `video_growing_so_fast` · composition `GrowingSoFast`

| | |
|---|---|
| Occasion / age | `m2`…`m11`, `y1` (E-7), any; ageDays 45–400 |
| Duration | 25–40 s · photos 6–12 |
| Timing | fixed 10 s (intro 3 + compare 4 + outro 3); per photo 1.8–2.6 s |
| Order | **Chronological by `takenAt`** (the renderer sorts; parent order is the tie-break) |
| Style | Timeline, growth, transformation — a progress line runs along the bottom |
| Palette | default `#F2F5F7` / `#1C2A33` / `#2BA89A`; alt `#FBF3EA` / `#33261B` / `#E07A5F` |
| Fonts | `beVietnamPro` 700 (labels), `lora` (title) |
| Music | `uplifting` (E-11) — piano that builds; default `music_nang_mai` |

Texts: `title` "Con lớn nhanh quá!" / "Look how much you've grown!" (40); `closing` "Mỗi ngày một
lớn, mỗi ngày một thương." / "Growing every day, loved every day." (60).

Scenes:
1. **Intro · 3.0 s** · `TitleCard`, `title`; a timeline bar draws across the bottom (0 → 100 % over
   40 f) with a dot at the start.
2. **Photos · perPhoto** · `PhotoKenBurns` [zoom 1.0 → 1.08]; `AgeLabel` big at bottom-left
   (`beVietnamPro` 700 64 px, white on accent pill) from `ageLabel`; the bottom timeline stays on
   screen (y 1700, 4 px) with a dot advancing to `i / (n−1)`. Transition: smooth zoom-through —
   outgoing photo scales to 1.25 and fades while incoming scales 0.92 → 1.0 (18 f).
3. **Then vs now · 4.0 s** · `SplitCompare` [first photo vs last photo, wipe left → right], labels
   = their `ageLabel` (fallback "Lúc ấy"/"Bây giờ").
4. **Outro · 3.0 s** · `EndCard` with `closing`.

### V06 — Hello, Little Smile · `video_hello_smile` · composition `HelloSmile`

| | |
|---|---|
| Occasion / age | `first_smile`, `laughs`; ageDays 21–240 |
| Duration | 15–25 s · media 4–8 (photos; short clips with E-10) |
| Timing | fixed 5.5 s (intro 2.5 + outro 3); per item 2.0–3.0 s (a clip uses up to 3 s of itself) |
| Style | Playful, colourful, heartwarming — sunny gradients, rounded type, smiley doodles |
| Palette | default `#FFE29A` / `#3B2A14` / `#FF7A59`; alt `#FFD6E0` / `#40213A` / `#7C5CFF` |
| Fonts | `baloo` 800, `beVietnamPro` |
| Music | `happy` — bright, claps-free pop instrumental; default `music_nang_mai` |

Texts: `title` "Nụ cười đầu tiên ấy…" / "That first little smile…" (40); `closing` "Cười thật nhiều
nhé, mặt trời nhỏ!" / "Keep smiling, little sunshine!" (50).

Scenes:
1. **Intro · 2.5 s** · Background gradient (accent → background) rotating 20° over the scene; a
   smiley doodle draws itself (path 30 f); `title` pops word by word.
2. **Items** · `PhotoFramed` [rounded, tilt alternating ±4°] over a moving radial "sunshine"
   (rays rotating 6°/s); doodle stickers (`v06-doodles`: smiley, sun, sparkles) bounce around the
   frame corners; transitions alternate `slide` up and a zoom-pop (scale 0.8 → 1.05 → 1). Clips
   (E-10): `OffthreadVideo` muted, `startFrom` at the clip's middle − 1.5 s.
3. **Outro · 3.0 s** · `closing` in `baloo` 76 px, letters wave (sin offset per letter); `name`.

### V07 — My First Milestone · `video_first_milestone` · composition `FirstMilestone`

| | |
|---|---|
| Occasion / age | `rolls_over`, `sits_up`, `crawls`, `stands`, `first_steps`; ageDays 90–420 |
| Duration | 20–30 s · photos 4–8 |
| Timing | fixed 8 s (badge intro 3.5 + outro 4.5); per photo 2.2–3.2 s |
| Style | Achievement, playful, proud — medal, ribbon, confetti burst |
| Palette | default `#DCEEFF` / `#14253D` / `#FF9F1C`; alt `#E2F5D9` / `#1C3317` / `#F25F5C` |
| Fonts | `baloo` 800, `beVietnamPro` 700 |
| Music | `uplifting` / `festive`; default `music_nang_mai` |

Texts: `headline` = the occasion's achievement (same table as C08: "Con biết lẫy rồi!" … / "I rolled
over!" …) (36); `message` (per-photo caption, optional, cycled): "Cố lên nào!", "Gần được rồi!",
"Làm được rồi!" / "Here we go!", "Almost there!", "Did it!" via `lines` (E-9); `closing` "Thêm
một bước nhỏ, thêm một kỷ niệm lớn." / "Another little step, another big memory." (60).

Scenes:
1. **Badge intro · 3.5 s** · `Badge` [`v07-medal`] springs in at centre; ribbon unfurls (scaleY 0 →
   1, 12 f); `headline` below in `baloo` 80 px; `dateLine` small; `Particles` [confetti] burst at
   frame 20 (one burst, 60 particles, gravity).
2. **Photos · perPhoto** · `PhotoFramed` [rounded, white 20 px border, tilt 2°]; caption from
   `lines` as a sticker-label at the bottom (`TextOverlay` style `label`); a small medal icon stays
   in the top-right corner. Transitions: `slide` from bottom.
3. **Outro · 4.5 s** · `closing`, then the medal returns small next to `name` and the date; a
   second, smaller confetti burst.

### V08 — 100 Days of Love · `video_hundred_days_love` · composition `HundredDaysLove`

| | |
|---|---|
| Occasion / age | `d100`, ageDays 90–130 |
| Duration | 30–40 s · photos 8–12 |
| Timing | fixed 10 s (title 4 + outro 6); per photo 2.0–2.6 s |
| Order | chronological (birth → day 100) |
| Style | Elegant, festive, sentimental — cream and red, gold hairlines, peach-blossom petals |
| Palette | default `#F8F1E7` / `#5A1F1B` / `#B23A2E`; alt `#9E2B25` / `#FCEFD9` / `#E8C77A` |
| Fonts | `playfair` 700 (100), `lora` |
| Music | `cinematic` (E-11) — warm strings + piano; default `music_ru_em` |

Texts: `title` "100 ngày yêu thương" / "100 days of love" (30); `message` (family message)
"Cả nhà chúc con trăm ngày bình an, một đời hạnh phúc." / "With love from all of us: a hundred
peaceful days and a lifetime of joy." (140).

Scenes:
1. **Title · 4.0 s** · gold double frame (`v08-frame`) draws in (stroke dash 30 f); "100" in
   `playfair` 360 px accent counts up 1 → 100 over 36 f (ease-out) then settles; `title` below;
   `Particles` [petals, peach `#F4B7B2`, slow].
2. **Photos · perPhoto** · `PhotoFramed` [frame: arch, gold hairline] centred on cream with the
   faint cloud-scroll texture (`v08-pattern`); `AgeLabel` styled as a small red seal with the day
   count ("Ngày 30"); transitions `fade` 18 f with a gold shimmer sweep (`LightLeak` gold) every
   4th photo.
3. **Outro · 6.0 s** · `LetterPage` (cream, no lines): `message` in `lora` italic 54 px, then
   `name` in `lora` 700 96 px accent with the "100" seal stamped beside it (scale 1.3 → 1, 10 f,
   slight shake).

### V09 — Half a Year With You · `video_half_year` · composition `HalfYear`

| | |
|---|---|
| Occasion / age | `m6` (E-7), ageDays 170–220 |
| Duration | 35–45 s · photos 8–12 |
| Timing | fixed 8 s (intro 4 + outro 4) + 0.8 s per month chapter card (≤ 6); per photo 2.0–2.6 s |
| Order | chronological; grouped by month of age (1…6) from `takenAt` |
| Style | Documentary, reflective, inspiring — chapter cards per month |
| Palette | default `#F1EEE8` / `#22262A` / `#3D8A9B`; alt `#1D1F22` / `#EDE7DD` / `#E0B15C` |
| Fonts | `playfair` (numerals), `beVietnamPro` (labels), `lora` italic (closing) |
| Music | `emotional` → `uplifting`: piano that builds into a full melody at ~60 % of the length; default `music_ru_em` |

Texts: `title` "Sáu tháng yêu con" / "Six months of loving you" (40); `closing` "Và hành trình của
chúng ta chỉ mới bắt đầu." / "And our journey is just beginning." (60).

Scenes:
1. **Intro · 4.0 s** · `TitleCard`, `mark` "6" huge in `playfair` 520 px behind the title at 15 %
   opacity, `title` over it.
2. **Chapters** · for each month that has photos: a **chapter card 0.8 s** ("Tháng 1" / "Month 1"
   in `beVietnamPro` 700 caps, thin rule, slide from left) then its photos with `PhotoKenBurns`.
   Months without photos are skipped; if no `takenAt`/`dob`, chapters are omitted and photos play
   in order. Chapter cards count into `fixed` when the server computes perPhoto.
3. **Lift moment** · at the photo nearest 60 % of the timeline: background shifts to accent tint,
   `LightLeak`, and the cut rhythm tightens to the music build (perPhoto × 0.85 for the rest).
4. **Outro · 4.0 s** · `closing` in `lora` italic, `name`, `dateLine`.

### V10 — A Letter to My Baby · `video_letter` · composition `LetterToBaby`

| | |
|---|---|
| Occasion / age | any |
| Duration | 30–45 s · photos 5–10 |
| Timing | fixed 9 s (letter opening 5 + signature 4); photos play *with* the letter: per photo 2.4–3.6 s |
| Style | Intimate, poetic, deeply emotional — handwritten letter on paper, photos fade under the text |
| Palette | default `#F5EFE3` / `#2E2620` / `#9C6B4E`; alt `#EEF1F5` / `#22303D` / `#5D7FA3` |
| Fonts | `patrickHand` (letter, E-1; fallback `dancingScript` 500), `lora` (signature) |
| Music | `gentle` — soft piano or fingerpicked guitar; default `music_ru_em` |

Texts: `letter` (E-9, ≤ 400 chars):
- vi: "Con yêu, ba mẹ viết cho con vài dòng để mai sau con đọc. Ngày con đến, ba mẹ đã khóc vì hạnh
  phúc. Từ đó, mỗi sáng thức dậy đều có lý do để mỉm cười. Con cứ lớn lên thật bình an, ba mẹ sẽ
  luôn ở đây."
- en: "Dear little one, we're writing a few lines for you to read one day. The day you arrived, we
  cried with happiness. Since then, every morning has a reason to smile. Grow up safe and happy —
  we'll always be right here."

`closing` "Thương con thật nhiều, Ba & Mẹ" / "With all our love, Mom & Dad" (50).

Scenes:
1. **Letter opening · 5.0 s** · paper (`v10-paper`, lined, deckled edge) slides up; "Gửi con, {name}"
   / "Dear {name}," writes itself (typewriter, 2 chars/frame, with a pen-nib cursor dot).
2. **Letter + photos** · the letter is split into sentences; the n photos are spread over the
   sentences (a photo per 1–2 sentences). Layout: photo top 55 % (`PhotoBlurFill`, rounded 28 px,
   soft vignette), paper card bottom 45 % with the current sentence handwritten-revealed
   (`patrickHand` 54 px, max 5 lines); previous sentence fades to 0. Transitions `fade` 20 f.
   perPhoto stretches to the sentence's reading time: max(perMin, chars × 0.06 s).
3. **Signature · 4.0 s** · full paper; `closing` written in `lora` italic 60 px, a small heart.

If the parent clears the letter, scenes 2 use the photos alone (`PhotoKenBurns`) and the closing
remains.

### V11 — Then & Now · `video_then_now` · composition `ThenAndNow`

| | |
|---|---|
| Occasion / age | any; ageDays 30–420 |
| Duration | 15–25 s · photos 2–6 |
| Timing | fixed 5 s (intro 2 + outro 3); pairs: photos are taken in chronological pairs (oldest with newest, 2nd oldest with 2nd newest…); per pair 4.0–5.5 s; an odd photo becomes a single `PhotoKenBurns` |
| Style | Minimal, surprising, emotional — clean white/black, big labels, precise wipes |
| Palette | default `#FAFAF8` / `#111111` / `#E07A5F`; alt `#111111` / `#FAFAF8` / `#F2CC8F` |
| Fonts | `beVietnamPro` 700 |
| Music | `gentle` / `uplifting`; default `music_ru_em` |

Texts: `title` "Lúc ấy…" / "Then…" (20); `closing` "Con đã lớn thật nhiều!" / "You've grown so
much!" (40).

Scenes:
1. **Intro · 2.0 s** · `title` alone, centred, 120 px, a blinking ellipsis.
2. **Pair · perPair** · `SplitCompare` [wipe]: the older photo full-screen with label (its
   `ageLabel`, else "Lúc ấy"/"Then") for 40 % of the pair; a vertical wipe reveals the newer photo
   ("Bây giờ"/"Now" or its `ageLabel`) — the wipe line is accent, 6 px; hold 40 %; then both shrink
   side by side (each 50 % width) for the last 20 %. Transition between pairs: `fade` to
   background 12 f.
3. **Outro · 3.0 s** · `closing`, `name`.

### V12 — My First Birthday · `video_first_birthday` · composition `FirstBirthday`

| | |
|---|---|
| Occasion / age | `y1`, ageDays 350–400 |
| Duration | 35–45 s · photos 10–15 |
| Timing | fixed 11 s (countdown 3.5 + "ONE" 3 + outro 4.5); per photo 1.8–2.4 s |
| Order | chronological; months 1–12 shown as small labels |
| Style | Celebratory, colourful, emotional — balloons, confetti, candle |
| Palette | default `#FFF4E8` / `#2F2140` / `#FF6F91`; alt `#E7F3FF` / `#172A46` / `#3D7BFF` |
| Fonts | `baloo` 800, `beVietnamPro` |
| Music | `festive` (E-11) — joyful instrumental (glockenspiel, strings, light percussion); default `music_nang_mai` |

Texts: `headline` "1 tuổi" / "ONE" (10); `title` "Một năm đầu tiên của {name}" / "{name}'s first
year" (40); `closing` "Chúc mừng sinh nhật đầu tiên, {name}!" / "Happy 1st birthday, {name}!" (50).

Scenes:
1. **Countdown · 3.5 s** · dark-blue night background; `Countdown` 3 → 2 → 1 in `baloo` 400 px,
   each with a soft drum-like visual pulse (scale); at the end, a burst of light.
2. **ONE · 3.0 s** · `headline` slams in (scale 2.0 → 1.0, spring damping 8) on the palette
   background, balloons (`v12-balloons`) float up from the bottom (y +400 → −200 over the scene,
   slight sway ±20 px), `Particles` [confetti] continuous; `title` beneath.
3. **Year in photos · perPhoto** · alternating `PhotoFramed` [polaroid tilt ±3°] and `Collage`
   [2up] every 4th photo; `AgeLabel` ("Tháng 1" … "Tháng 12") as a balloon-shaped tag; transitions
   `clockWipe` for month changes, `slide` otherwise; confetti light throughout (density low).
4. **Outro · 4.5 s** · cake (`v12-cake`) rises in; the candle flame flickers (scale noise); `closing`
   in `baloo` 80 px; `name`; final big confetti burst at 1.5 s before the end.

---

## 6. Music, sample media, rollout

### 6.1 Music briefs (Thư viện nhạc)

Owned or licensed tracks, ≥ 75 s, mastered to −14 LUFS, no vocals. Existing: "Ru êm"
(`music_ru_em`, gentle music box) and "Nắng mai" (`music_nang_mai`, happy plucks) — originals.

| Id (proposed) | Mood (E-11) | Brief | Default for |
|---|---|---|---|
| `music_piano_dawn` | emotional | Solo felt piano, 70 bpm, D major, slow arpeggios, one swell at 0:20 | V01, V09 |
| `music_cozy_morning` | warm | Fingerpicked acoustic guitar + soft piano, 84 bpm | V02, V10 |
| `music_love_letter` | romantic | Strings pad + piano melody, 72 bpm, gentle rubato | V03 |
| `music_bubbles` | playful | Ukulele, glockenspiel, finger snaps, 115 bpm | V04 |
| `music_rising` | uplifting | Piano ostinato building to strings + light drums at 0:25 | V05, V07, V09 (build) |
| `music_sunshine` | happy | Bright pop instrumental, claps-free, 120 bpm | V06 |
| `music_hundred_days` | cinematic | Warm strings, đàn tranh-like plucked motif (synthesised or licensed), 76 bpm | V08 |
| `music_party` | festive | Glockenspiel + strings + light percussion, 118 bpm | V12 |
| (reuse) `music_ru_em` | gentle | — | V11 |

Until a track exists, each template's default falls back as listed in §5.

### 6.2 Sample media for "Xem mẫu"

- Photos of real people only with a licence **and** a model / guardian release (owner, 2026-10-14);
  `make-previews.ts` refuses anything else (`licence.json`). Until such photos are bought, the
  previews use illustrated placeholders. Wanted set: a newborn in a blanket, hands/feet details, a
  smiling 3-month-old, rolling/sitting/crawling/standing, a first meal, a birthday, and "then/now"
  pairs. Status in `apps/renderer/preview-credits.md`.
- `apps/renderer/scripts/make-previews.ts` gains a plan entry per composition (photo ids, mark,
  texts) and renders 720 × 1280 previews + covers; `seed-keepsakes.ts --media` publishes them.
- Card previews draw live from layers; no files needed.

### 6.3 Rollout

1. **Contracts first:** E-2, E-6, E-7, E-8, E-9, E-11, E-12 (one PR each, with tests), then the app
   release that carries E-1 … E-6 for cards.
2. **Cards:** upload assets per template in the portal (Tệp), create each template with "＋ Mẫu
   mới" from the closest existing one, paste the layer JSON generated from §3 (a small script can
   turn the notation into JSON), publish as `draft`, review on device (Light and Night care, vi/en),
   then `published`.
3. **Videos:** build the scene kit, then one composition per template (each with a
   `compositions.test.ts` entry and a stills snapshot at three frames like `scripts/sample.ts`);
   deploy renderer + player page + functions + portal; create templates in the portal; render
   previews.
4. **Brand on what is already live:** the current `MemoryStory` composition gets `BrandMark` and
   the logo in its outro; the seed cards get a `brand` layer (or the WebP fallback), published as a
   new version. Saved creations are not changed.
5. **Existing seed templates:** archive `card_round`, `card_full_photo`, `card_blush`,
   `card_starry_night` and the four seed videos once their replacements (C03/C06, V02/V04/V08)
   are published. Saved creations keep the version they used.
6. **Checklist:** each template is "done" only after it renders end-to-end on dev, iOS and Android,
   vi and en, all formats (CLAUDE.md coverage rule).
