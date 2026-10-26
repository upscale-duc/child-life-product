# Elevation, surfaces and radius

Sources:

- `ClRadius` and `ClShadows` in `core/design/tokens.g.dart`;
- D-096 (page cards look like the Care cards);
- D-107 (shared rules, purposeful variation);
- `ClCardGroup` and `ClTileShadow` in `core/widgets/cl_rows.dart`;
- `ClSheetRoute` in `core/widgets/cl_sheet.dart`.

The future shared card component (`ClCard`) is **not** defined here; it belongs to the planned
`cl-components` skill. This file gives the foundation rules any card must follow.

## 1. Surface ladder

| Level | Token | Light | Night care | What sits here |
|---|---|---|---|---|
| 0 Page | `cloud` | #F6FCFB (mint-tinted white) | #0C1719 | Scaffold background |
| 1 Card | `surface` + `shadows.card` | White, two soft ink-tinted shadows | #15242A, **no shadow** | Cards and groups on the page (D-096) |
| 1′ Inset | `surface2` | #EEF6F5 | #1C2E33 | Fills *inside* a card or sheet: grouped fields, info notice, secondary button |
| 2 Sheet | `surface` + `shadows.sheet`, top radius `ClRadius.sheet` | White | Dark + black shadow | `showClSheet` |
| 3 Floating | `shadows.nav` / `chip` / `lift` | Ink-tinted | Black | Dock (`ClTabDock`), toast, dragged or lifted items |
| Picture | `shadows.tile` | Two layers | Two black layers | Photo, video, keepsake and album tiles (`ClTileShadow`, D-096) |
| Overlay | `scrim` (32 % Light, 56 % black Night) | — | — | Behind sheets |

**In Night care the hierarchy comes from fill steps** (`cloud` → `surface` → `surface2`),
because `shadows.card` is empty there. Never rely on a shadow alone to separate a card. The fill
difference must carry it in Night care.

## 2. When to use what

| Situation | Surface |
|---|---|
| A group of rows or a card on the page | `surface` + `shadows.card`: `ClCardGroup` default, D-096 |
| A group inside a sheet | `ClCardGroup(color: cl.colors.surface2)` (no shadow by default) |
| A quiet information block inside a card or page section | `surface2`, flat |
| A status that needs attention | Tinted fill (`sunshineSoft`, `errorSoft`), flat, with an icon |
| A category tile | `cl.care.X.soft`, flat |
| An illustration or hero card | `card*` tokens, flat; it is identity, not elevation |
| A photo tile | `ClTileShadow` |
| Outlined (selectable option, dashed "add") | `controlBorder` or `mintDeep` border, flat |
| Premium | `PremiumPalette` gradients; its own rules (`colors-and-themes.md` §7) |

**Flat is the default** for anything *inside* a card, inside a sheet, tinted or outlined. Only the
outermost page-level card gets `shadows.card`.

## 3. Avoid nested cards

- **One elevated level per region.** Never put a shadowed card inside a shadowed card.
- **Inside a card, separate content** with:
  - `separator` hairlines (as `ClCardGroup` does);
  - `surface2` insets;
  - spacing.
- **Never a card around a single row.** Put rows in a group.
- **A section is headed, not boxed:**
  - use a `ClSectionHeader` above the group;
  - don't add a card around the heading and its group.

## 4. Radius scale (implemented)

| Token | Value | Use |
|---|---|---|
| `ClRadius.sm` | 8 | Small badges, thumbnails inside rows, the inner corners of chips |
| `ClRadius.control` | 12 | Inputs (`cl_inputs.dart`), the icon tile in `ClDetailRow`, `ClCoachmark`, small tiles |
| `ClRadius.card` | 24 | Page cards and groups (`ClCardGroup`), toasts, `ClAccountRow` |
| `ClRadius.tile` | 28 | Large choice tiles (`ClChoiceTile`, `ClSelectTile`), quick-log tiles (`care_sheets.dart`) |
| `ClRadius.sheet` | 32 | Top corners of sheets (`cl_sheet.dart`) |
| `ClRadius.hero` | 36 | Hero art (`HeroArt` in `onboarding/widgets/onboarding_layout.dart`) |
| `ClRadius.pill` | 999 | Buttons, chips, segmented controls, the nav bar |

**Nested corners.** An inner element's radius should be about the outer radius minus the padding
between them. For example, a 24 card with 16 padding holds an 8 inner element (`ClRadius.sm`).

## 5. Radius debt and gaps

- **Literals:** 398 literal radii in features. The top values are 14, 16, 12, 20, 18, 10. Only 12
  is a token.
- **Feature kits use 20 (and 16 for groups):** `RhCard`, `NuCard`, `SpCard`, `LbCard`, `AxCard`,
  `PrintCard`, the care-hub tile. `MeNotice` uses `card - 6` = 18.
- **Token arithmetic:** `ClRadius.card - 6` × 19, `control + 4` × 17. These are signs of missing
  steps.
- **Core defaults that are not tokens:** `ClSkeleton` radius 14, `ClTileShadow` radius 12 (= control).

**Guidance for new work.**

- Page-level cards and groups use `ClRadius.card`.
- Compact cards in a dense list (a card per item, not a group) may use `control` or `card`; pick
  one per screen.
- Don't introduce 14, 16, 18 or 20. A "medium card radius" (~16–20) is a documented candidate
  token: propose it, don't inline it.

## 6. Purposeful variation (D-107)

Cards share **foundations**:

- the surface level;
- elevation per D-096;
- padding `s4`;
- a radius from the scale;
- press feedback (`ClPressable`, `surfaceOpacity`);
- semantics.

They may **vary by purpose**:

| Purpose | What may differ |
|---|---|
| Standard content | Default surface |
| Interactive action | Whole card tappable, trailing chevron or icon chip |
| Insight / stats | A `numeral` hero, a chart, a care-colour accent |
| Media / memories | A photo fills the card, `shadows.tile`, warm accents |
| Premium | `PremiumPalette` |

Variation comes from **content and accent**, never from a new radius, shadow or padding value.

## Good / bad

```dart
// ✅ group on a page
ClCardGroup(children: rows)
// ✅ inside a sheet
ClCardGroup(color: cl.colors.surface2, children: rows)

// ❌ shadowed card inside a shadowed card
ClCardGroup(children: [Container(decoration: BoxDecoration(boxShadow: cl.shadows.card, …))])
// ❌ new radius literal
BorderRadius.circular(20)
// ❌ shadow as the only separation (vanishes in Night care)
Container(decoration: BoxDecoration(color: cl.colors.cloud, boxShadow: cl.shadows.card))
```
