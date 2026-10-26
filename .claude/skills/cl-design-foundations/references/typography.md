# Typography

Source: `ClTextSpecs` in `core/design/tokens.g.dart`, built into `ClTypography`
(`core/design/cl_typography.dart`) and read as `cl.text.*`. Every style defaults to
`colors.ink`; override the colour only, with `.copyWith(color: …)`.

Font: **Be Vietnam Pro** everywhere. The Playfair serif is limited to keepsakes and Premium
headlines (`PremiumPalette.serif`).

## 1. The scale (implemented)

| `cl.text.` | Size / line height | Weight | Uses in `lib/` | Built into |
|---|---|---|---|---|
| `display` | 34/40 | 600 | 3 | Welcome-level heroes |
| `largeTitle` | 32/40 | 600 | 52 | `ClNavHeader`, `MePage`, `ScreenHeading(large)` |
| `title` | 30/36 | 600 | 42 | `ScreenHeading`, `ClCodeInput` digits |
| `title2` | 24/32 | 600 | 74 | `ClSheetHeader` title |
| `headline` | 18/26 | 500 | 100 | `ClSectionHeader`, `ClEmptyState` title, tile titles (`ClChoiceTile`, `ClSelectTile`) |
| `body` | 16/24 | 400 | 281 | Row titles (`ClListRow`, `ClDetailRow`, `ClOptionRow`, `MeRow`), field values, body copy |
| `bodyStrong` | 17/24 | 500 | 258 | `ClButton` labels, `ClInfoRow` value, emphasised lines, `MeNotice` title |
| `label` | 14/20 | 500 | 621 | Row subtitles, section links, chips, secondary lines |
| `caption` | 12/16 | 500, +0.2 | 622 | Metadata, field labels, nav labels, timestamps |
| `numeralXl` | 52/56 | 500, tabular | 8 | `ClAmountField`, timers |
| `numeral` | 28/34 | 500, tabular | 3 | Stat values (under-used) |

## 2. Role map

| Role | Style | Colour | Example in code |
|---|---|---|---|
| Hero number (timer, amount being entered) | `numeralXl` via `ClTabularText` | `ink` | `ClAmountField`, `care/timer_screens.dart` |
| Stat value (a tile's number) | `numeral` via `ClTabularText`, unit in `label` | `ink` value, `inkMuted` unit / label | Few exist yet; see `senior-ui-ux` §5.4 |
| Screen title (tab or page) | `largeTitle` | `ink` | `ClNavHeader`, `MePage` |
| Flow step title | `title` (or `largeTitle` when `large`) | `ink` | `ScreenHeading` |
| Sheet title | `title2` | `ink` | `ClSheetHeader` |
| Section heading on a page | `headline` | `ink` | `ClSectionHeader` (with `Semantics(header: true)`) |
| Card title | `headline` (one card per section) or `bodyStrong` (several in a list) | `ink` | `ClEmptyState`, `MeNotice` |
| Row title | `body` | `ink` | `ClListRow`, `MeRow` |
| Row subtitle / secondary information | `label` | `inkMuted` | `ClListRow` |
| Primary body copy | `body` | `ink` | Notices, explanations |
| Metadata (time, author, "45 phút trước · Mẹ ghi") | `caption` | `inkMuted` | Showcase foundations |
| Footnote / disclaimer | `caption` (or `label` when it must be read) | `inkMuted` | One per screen at most |
| Button label | `bodyStrong` (inside `ClButton`) | from the button style | Don't style button labels by hand |
| Link / plain action | `label` | `mintText` | `ClSectionHeader` link |
| Dynamic number inline in a row | `body` / `bodyStrong` via `ClTabularText` | `ink` | Values that tick or update |

**Hierarchy rules.**

- At most **three text levels per card** (title, value or body, meta).
- **One `largeTitle` per screen.**
- A section heading is never smaller than the row titles under it.
- Emphasise with weight or colour **within the scale**, not with new sizes.

## 3. `ClTabularText`

`core/design/tabular_text.dart`. Be Vietnam Pro has no `tnum` feature (P-064), so the widget lays
each digit in a fixed-width box.

- **Use it for** any number that changes while visible (timers, counters, live amounts) and for
  numbers compared in a column or row (stat tiles, totals, times in a list).
- **Skip it for** static numbers inside a sentence ("Bé 3 tháng tuổi").
- **API:** `ClTabularText(text, style: cl.text.numeral, semanticsLabel: '…')`. Pass a
  `semanticsLabel` with units in words when the visible text is terse ("1:24:08" → "1 giờ 24
  phút"). Digit width follows the text scaler.

## 4. Where the scale is insufficient (gaps, not APIs)

The following are **not implemented**. Do not write `cl.text.rowTitle` or similar.

| Gap | Evidence | Today's workaround (debt) | Recommendation |
|---|---|---|---|
| No step between `label` 14 and `body` 16 for dense row titles | `fontSize: 15` × 133; `spRowTitle` (`spending/spending_widgets.dart`) | `.copyWith(fontSize: 15, fontWeight: w600)` | **Proposed:** a semantic "dense row title" (15/20 · 600), only through the token protocol |
| No 13 px meta between `caption` 12 and `label` 14 | `fontSize: 13` × 99 | Literal 13 | Prefer `caption` or `label`; propose only if a review shows 12 is too small *and* 14 too big |
| No bold weight on the scale (600 max) | `FontWeight.w700` × 213 | Inline `w700` | Use the 600 styles (`title2`, `headline` are 600/500); stat emphasis goes through `numeral`. Propose only if a role truly needs 700 |
| `bodyStrong` is bigger (17) as well as heavier than `body` (16) | Spec | `body.copyWith(fontWeight: w500/600)` for same-size emphasis | Acceptable; document it in reviews. A same-size strong style is a candidate token |
| Text below 12 px | 9–11 px × ~83 (`PremiumCrest` 7–9 px, nav labels 11 px per the NavBar spec) | Literals | **Don't go below `caption` (12)** except in the documented nav label and Premium crest |

**Approval (L3, D-109).** A new text style is a token change (D-106):

1. propose it with usage evidence and the role it serves;
2. get the owner's OK;
3. add it to `tokens.json` → `generate.ts` → `ClTypography`;
4. then migrate the call sites when they are touched.

Until then, use the nearest existing style.

## 5. Density without shrinking

**Never reduce font size to fit more.** Density comes from:

- grouping rows in `ClCardGroup`;
- one fact per line;
- removing duplicated sentences;
- moving explanation behind a tap;
- compact numbers (`numeral` + unit).

If a layout only fits with 11–13 px text, the layout is wrong.

## 6. Long strings and scaling

- Vietnamese runs longer than English. Allow wrapping on titles and row titles (core rows wrap
  rather than truncate; `_LabelValue` in `cl_rows.dart`).
- Truncate (`maxLines` + ellipsis) only:
  - names in tight chips;
  - single-line buttons (`ClButton` is single-line);
  - previews with a "more" affordance.
- No global text-scale clamp exists (`app/app.dart`). Text can reach 200 %. See
  `accessibility.md`.

## Good / bad

```dart
// ✅ row title + meta
Text(title, style: cl.text.body);
Text('2 giờ trước · 07:30', style: cl.text.caption.copyWith(color: cl.colors.inkMuted));

// ✅ stat value
ClTabularText('120', style: cl.text.numeral, semanticsLabel: '120 mi-li-lít');

// ❌ a new size and weight inline
Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700));
// ❌ a hand-styled button label
ClPressable(child: Text('Lưu', style: cl.text.label.copyWith(fontWeight: FontWeight.w700)))  // → ClButton
```
