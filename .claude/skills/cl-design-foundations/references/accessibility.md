# Accessibility foundations

**[V]** = verified in the current code. **[R]** = recommendation that needs testing (render it,
or run it with a screen reader).

## 1. Touch targets

- [V] `ClPressable` enforces at least 44 × 44 (`ClSpace.tapMin`) on every button, row, tile and
  link built on it, including `ClSectionHeader` links and `ClButtonStyle.plain`.
- [V] Filter chips are 40 high with hit slop to 44 (`ClFilterChip`). `ClBackButton` is 44;
  `ClRoundButton` is 64.
- [R] Keep at least `s2` between adjacent targets. Never put tappables in a bare
  `GestureDetector` (there is no minimum there).

## 2. Text scaling to 200 %

- [V] There is no text-scale clamp (`app/app.dart` has no `MediaQuery` override), so system
  Dynamic Type passes through.
- [V] Core rows wrap label and value instead of truncating (`_LabelValue`, `cl_rows.dart`).
- [V] `ClTabularText` scales the digit width with the text scaler.
- [V] Known weak points:
  - `ClButton` is a fixed height (56, secondary 52) with a **single-line label and an ellipsis**,
    so long labels truncate at large sizes;
  - about 153 fixed heights of 20–39 in features;
  - fixed-ratio grids (Today care grid `childAspectRatio: 166/156`);
  - `TextScaler.noScaling` in `print_studio` (print artwork only, which is acceptable).
- [R] For any new or changed screen, render one golden at `textScaler: TextScaler.linear(2.0)`
  (vi). Check for:
  - clipping;
  - overlapping;
  - lost actions;
  - ellipsised key information.
- [R] Keep button labels to 1–3 words so they survive 200 %.
- [R] Prefer `minHeight` and padding to fixed heights.

## 3. Contrast

- [V] Computed from the tokens; full table in `colors-and-themes.md`.
- [V] Main text pairs pass AA in both palettes:
  - `ink` on `cloud`, `surface`, `surface2`: 10.7–15.9;
  - `inkMuted` on `surface`: 5.3 Light / 7.2 Night;
  - `mintText` on `surface`: 5.9 / 8.4;
  - white on `mintDeep`: 4.85 / 8.0.
- [V] Fail or large-text-only:
  - text on `mint`;
  - `onWarm` on soft warm fills (Night);
  - `onCard` on `cardNight` (Light);
  - text on care `accent`;
  - `onDanger` / `danger` (3.0 Night);
  - `onLive` / `live` (3.6 Light);
  - `danger` / `dangerSoft` (3.6 Light).
- [V] `separator` (1.25) is decorative. Controls that must be seen use `controlBorder`
  (3.2 / 4.3) or `clInputStroke`.
- [R] `inkMuted` on `surface2` is 4.80 in Light: fine for text ≥ 14 px, marginal at 12 px. Keep
  12 px `caption` on `surface` / `cloud` when possible.

## 4. Semantic labels

- [V] `ClIcon` is **decorative by default** (`ExcludeSemantics`) unless `semanticLabel` is given.
  Label icon-only controls.
- [V] `ClPressable(semanticLabel:)` and `ClButton` (label = semantics) mark buttons.
  `ClPressable(selected:)` exposes the selected state.
- [V] Headings: `ClSectionHeader`, `MePage` and `ClNavHeader` set `Semantics(header: true)`. Hand-made
  headings must do the same (127 uses across 73 files already do).
- [V] Live regions: toasts, `withClProgress` and `ClButton(loading:)` announce.
- [R] A tappable card or tile reads as **one sentence**: "Bú, 120 ml, 2 giờ trước". Use
  `MergeSemantics` or a `semanticLabel` that composes the visible parts. Don't let a screen reader
  stop on every fragment.

## 5. Numbers for screen readers

- [V] `ClTabularText(semanticsLabel:)` replaces the per-digit layout with one label.
- [R] Give terse visuals a spoken form, with units as words:
  - `1:24:08` → "1 giờ 24 phút";
  - `120 ml` → "120 mi-li-lít";
  - `24/10` → "24 tháng 10";
  - `07:30` with its relative time.

  Build spoken strings from ARB, never from code concatenation of English.
- [R] Charts (`CustomPainter`) are silent. Wrap them in `Semantics(label:)` with the key takeaway
  ("Tuần này ngủ trung bình 13 giờ mỗi ngày").

## 6. Long Vietnamese and English strings

- [V] vi strings are the template; en often differs in length. A median vi string is 18
  characters; the p90 is 55.
- [R] Test the en and vi goldens for every change. Watch:
  - chips, segments (`ClSegmented` has 2–3 short options), nav labels and buttons;
  - names (long baby or relative names, 3+ babies).
- [R] Wrap rather than truncate for titles and row titles. Truncate only where a full view exists.

## 7. Night care readability

- [V] The palette has its own values for every token. Shadows are removed from cards; the
  hierarchy is carried by `cloud` → `surface` → `surface2`.
- [V] Traps: `onWarm` on soft fills (1.1); `ink` on `mint` (2.0). Raw `Colors.white` / `black` don't adapt.
- [R] Every UI change renders its **Night care** goldens (vi + en) and is looked at. Night care
  is used at 3 a.m. in a dark room: no bright full-white panels and no glowing highlights; keep
  calm fills.

## 8. Reduced Motion

[V] Covered by `context.motion()`, `ClPageTransitionsBuilder`, `ClSheetRoute`, toasts and
`ClSkeleton`. See `motion-and-interaction.md`. [R] Any new animation uses `context.motion(token)`
and has a static end state that makes sense without the animation.

## 9. Status independent of colour

- [V] `ClSyncStatus` (icon + words) and `ClErrorBanner` (bold lead + sentence). Selection uses a
  check (`ClRadio`) or a fill change plus weight (`ClFilterChip`).
- [R] Any status, category, chart series or overdue state carries an **icon or text** as well as
  its colour. Warn / attention uses an icon (`ClIcons.alert`, `clock`) plus words, not just a
  `sunshineSoft` fill.

## Checklist (foundations part of review)

- [ ] 44 pt targets, `s2` apart.
- [ ] Renders at 200 % text without clipping key content or actions.
- [ ] No pair from the "fail" list; Night care golden looked at.
- [ ] Icon-only controls labelled; tiles read as one sentence; headings marked.
- [ ] Changing numbers use `ClTabularText` with a spoken label where terse.
- [ ] vi and en goldens checked for overflow.
- [ ] Motion wrapped in `context.motion`.
- [ ] No status by colour alone.
