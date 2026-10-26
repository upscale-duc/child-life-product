# Responsive layout and accessibility (screen level)

Token-level rules (contrast, 44 pt, type, motion) are in `cl-design-foundations` →
`accessibility.md`; this file covers how **whole screens** adapt.

## 1. Current reality (verified)

- **Goldens render at 375 × 812** (`test/helpers/router_pump.dart`; 48 sizes in `test/golden/`).
  Some long screens use 375 × 1100 or 375 × 1800. There are **no small-phone (320 pt) or large-phone
  renders.**
- **No text-scale clamp** in the app. **No golden renders at increased text scale**, except the
  assistant chat-feel and replay tests (`test/features/assistant_chat_feel_test.dart`).
- **No long-name fixtures:** the baby is "Teddy" and members are "Mai" / "Cô Lan".
- Rendered truncation and wrapping already visible at 375 pt and 100 % text:
  - adaptive Today reminders cut the time column ("còn 2 n…", "yesterday 18:…", `ax/ax10_*`);
  - en History wraps "420 / ml" (`s6/20_history_nightCare_en`);
  - care tiles wrap "Kết thúc 3 giờ 20 phút trước" over two lines (`s4/19_today`).
- **Phone-only:** no tablet or max-width layout (an owner decision is pending).

## 2. Layout rules for screens

| Situation | Rule |
|---|---|
| Small phones (≤ 360 pt) and 200 % text | Single column; rows grow vertically; tiles in a 2-column grid may become 1 column or grow in height. **Never fix tile height around text.** Truncate only secondary metadata, never the value or the state |
| Large phones | Same layout; more content above the fold, not wider tiles |
| Label / value rows | The value moves under the label when space runs out (core rows wrap, `_LabelValue`); don't ellipsise times or amounts |
| Horizontal chip / filter rows | Scroll horizontally; the cut-off item signals more. Keep the selected item visible |
| Title tabs (Memories "Ảnh · Album · Nhật ký · Câu chuyện") | The selected tab is never clipped; check that a long en / vi label still reads |
| Charts | Use `LayoutBuilder` width; axis labels stay ≥ `caption`; the legend wraps |
| Bottom actions | Pinned primary stays visible above the keyboard and the dock (`HomeFloatingClearance`) |
| Sheets | Scroll their content; the primary stays pinned (`CareSheetFrame`) |

## 3. Content variability

| Variable | Design for it |
|---|---|
| **Long Vietnamese strings** | Usually longer than en for titles; **not always.** en can be longer for counts and units ("4 feeds · 420 ml" wrapped, "1 h 25 min ago"). Test both |
| **Long names** (baby nickname, member display names up to 40 chars in push, R-120) | Header chip, greeting, "{who} ghi" meta, member rows |
| **Multiple children** | Switcher label, per-baby storage breakdown (rendered on Me), push names |
| **Age bands** | Adaptive Today varies by age (`ax/ax10`–`ax13` = 0–1, 1–3, 3–6, 6–12 y); check each band's goldens |
| **Data volume** | Empty day / one entry / a busy day (10+ events) / 30-day history |
| **Roles** | Parent / caregiver / relative variants (`s4/12e_view_only`, `s6/12d_history_caregiver`, `s7/12f_*`, `s10/11*_relative`) |

## 4. Screen reader structure

- **Reading order** = visual order: title → hero / state → sections (each heading marked
  `header: true`) → actions.
- **Each tile and row reads as one sentence:** "Bú bình, 120 ml, 45 phút trước, Bạn ghi". Charts
  get a summary label (the insight sentence).
- **The selection mode is announced** ("5 mục đã chọn"), and each item exposes its selected state.
- **Dynamic updates** (toast, banner, timer) use live regions sparingly; a running timer must not
  announce every second.

## 5. Night care and reduced motion

- Night care is used in the dark, half-asleep:
  - large values first;
  - fewer accents;
  - no bright full-width panels;
  - warm (not red) attention.
- Under Reduce Motion, screen content appears without movement; carousels (paywall) don't
  auto-advance.

## 6. Required validation for substantial screen changes

Render and **look at**:

- [ ] vi + Light;
- [ ] vi + Night care;
- [ ] en + Light;
- [ ] en + Night care;
- [ ] increased text scale (at least 1.5×, ideally 2.0×) for the changed screen;
- [ ] a long-name fixture (baby and member) where names appear;
- [ ] the relevant empty, loading, error, offline and role states.

Golden tests passing only proves the image didn't change. Open the PNGs. Where a check can't be
rendered (e.g. no text-scale harness for that screen), say so in the report instead of claiming
it passes.
