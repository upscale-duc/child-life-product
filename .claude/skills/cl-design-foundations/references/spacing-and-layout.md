# Spacing and layout

Source: `ClSpace` and `ClRadius` (radius is covered in `elevation-and-surfaces.md`) in
`core/design/tokens.g.dart`, generated from the `space` group of `tokens.json`.

## 1. Supported tokens (implemented)

| Token | Value | Typical use |
|---|---|---|
| `ClSpace.s1` | 4 | Icon-to-text in chips; title-to-subtitle gap; tight inline gaps |
| `ClSpace.s2` | 8 | Icon-to-label in buttons; between chips; vertical padding of rows |
| `ClSpace.s3` | 12 | Between elements in a row (`_RowShell` gap); between stacked cards in a list; section heading → content |
| `ClSpace.s4` | 16 | **Screen gutter**; card and row inner padding; between stacked groups |
| `ClSpace.s6` | 24 | Between sections; bottom safe padding; button horizontal padding |
| `ClSpace.s8` | 32 | Around an empty state; large breaks in a flow |
| `ClSpace.tapMin` | 44 | Minimum hit area (`ClPressable.minSize`), plain button height |
| `ClSpace.buttonHeight` | 56 | `ClButton` height (secondary 52) |
| `ClSpace.nextButton` | 64 | `ClRoundButton` |

There is **no** `s5`, `s7`, `s10`, or 2 / 6 / 10 / 14 / 20.

## 2. Verified conventions

| Situation | Value | Where |
|---|---|---|
| Screen gutter (left / right) | `s4` | `MePage`, `TodayScreen` list, `ClPinnedHeaderScaffold` header, `ClSheetRoute` body |
| Scroll bottom on tab screens | `HomeFloatingClearance.of(context)` + `s4` | `today_screen.dart` (clears the floating dock) |
| Scroll bottom on pushed pages | safe area + `s6` | `MePage` |
| Sheet body | `s4` sides, `s2` top, `s6` + safe area at the bottom | `cl_sheet.dart` |
| Row inner padding | `s4` horizontal, `s2` vertical, `s3` gap; min height 56–60 | `_RowShell` in `cl_rows.dart` |
| Card / notice inner padding | `s4` | `MeNotice`, `today_screen.dart` cards |
| Button padding | `s6` horizontal (plain `s3`) | `ClButton` |
| Between rows in a group | 1 px `separator`, no gap | `ClCardGroup` |

## 3. Practical guidance

| Need | Use |
|---|---|
| Between two sections of a screen | `s6` (one rhythm per screen; don't mix `s3` / `s4` / `s6` between sibling sections) |
| Section heading → its content | `s3` |
| Between cards stacked in one section | `s3` |
| Between two groups that belong together | `s4` |
| Inside a card | `s4` padding; `s3` between blocks; `s1`–`s2` between a title and its subtitle |
| Icon → text in a row | `s3` (the row shell does it) |
| Icon → text in a chip or button | `s2` (chip `s1` if tight) |
| A value and its unit | A space character, not a `SizedBox` |
| Above the primary button at the bottom | `s4`–`s6`, with the safe area added |

The values here describe the current rhythm. Choose by what reads best at real size in vi and en,
and keep sibling sections consistent.

## 4. Technical debt (exists, don't copy)

- **Literal gaps:** about 813 `SizedBox` and 481 `EdgeInsets` use literals. The most common are
  6, 4, 8, 2, 10, 12 and 14 (*Discovery §4.2*).
- **Per-section gaps on Today:** `today_screen.dart` `sectionParts` switches its gap per
  section.
- **Feature-kit paddings:** 14 (`PrintCard`, the care-hub tile), 16 × 14 (`LbCard`), 12 (`SpBanner`).

When you touch such code, move it onto the nearest token if the result looks the same or better.
Don't mass-rewrite.

## 5. Proposed future additions (NOT available)

Candidates under the token protocol (SKILL.md), with evidence:

| Candidate | Evidence | Status |
|---|---|---|
| A 2 px hairline gap | 94 uses | Proposed |
| A 6 px tight gap (chip internals, title ↔ subtitle) | 169 uses | Proposed: most common literal |
| A 10 px gap | 89 uses | Proposed; maybe fold into `s2` / `s3` instead |
| A 20 px gap | 8 uses | Not justified |

Until one is approved and generated, use `s1` / `s2` / `s3`, never the literal.

## 6. Touch targets and spacing

- **Every tappable is at least 44 × 44.** `ClPressable` enforces it (`minSize` defaults to
  `tapMin`).
- **Adjacent targets need a visible gap** of `s2` or more, so two 44 pt targets don't touch.
- **Small icon buttons** (close, more) keep a 24 px glyph inside the 44 pt area. Never shrink the
  hit area to match the glyph.

## 6b. Icon sizes (no token yet)

`ClIcon` defaults to 24 (the drawing grid: 1.8 stroke). Sizes in use in core: 18 in `ClButton`, 20
for the nav bar and `MeNotice`, 16 and 14 in chips and meta.

| Context | Size |
|---|---|
| Standalone or row-leading icon | 24 (default), or 20 inside a 36–40 icon tile |
| In a button or notice | 18–20 |
| In a chip, inline with `label` text | 16 |
| Inline with `caption` meta | 14 |

Avoid 12 (thin strokes break up) and odd sizes. An icon-size token set is a documented candidate,
not an API.

## 7. Responsive behaviour (current state)

- **Phone-first, single column.** No breakpoints, no max content width, no tablet layout
  (`shortestSide` is only read for analytics).
- **Grids use fixed `crossAxisCount`** (3 / 4 / 5 by screen). No `MaxCrossAxisExtent`.
- **Read sizes with `MediaQuery.sizeOf` / `paddingOf`.** Use `LayoutBuilder` only when the widget
  itself must adapt (charts, carousels).
- **New layouts:**
  - don't hardcode screen fractions (e.g. `height * .64`) unless the content is a
    viewer or canvas;
  - prefer intrinsic content height plus scrolling.

Tablet and max-width rules are an open owner decision; don't invent them per screen.

## 8. Dynamic Type

- No text-scale clamp exists, so text may reach 200 %.
- **Avoid fixed heights around text.** About 153 fixed `height: 20–39` exist in features (debt).
  Use `minHeight` constraints and padding.
- **Rows and cards must grow with text.** Core rows wrap.
- **Grids with a fixed `childAspectRatio`** (the Today care grid uses 166/156) clip at large text.
  Test them at 200 %.

The rest is in `accessibility.md`.

## Good / bad

```dart
// ✅
Padding(padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4), child: …)
const SizedBox(height: ClSpace.s6) // between sections

// ❌ new literal
const SizedBox(height: 14)
// ❌ token arithmetic that hides a missing step
EdgeInsets.all(ClSpace.s4 - 2)
// ❌ fixed height around text
SizedBox(height: 36, child: Text(label))  // → ConstrainedBox(constraints: BoxConstraints(minHeight: ClSpace.tapMin))
```
