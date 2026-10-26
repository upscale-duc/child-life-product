# Card system: the proposed `ClCard` family

> **PROPOSED, NOT IMPLEMENTED.** There is no `ClCard` in the codebase. Don't import it, don't
> write code against it, and don't describe it as available. Building it from existing tokens
> is L2 work (`senior-ui-ux` §3, D-109): it can be done autonomously as its own verified batch;
> only a new token, such as the compact radius below, is L3. Until it exists, build cards with
> the **interim recipe** in §4.

**Principle: standardise the foundation, not the personality of every card.** The family shares
its surface, elevation, padding, radius, press behaviour and semantics. Purpose decides content
and accent. It exposes **semantic variants, not free-form styling knobs**: no `radius:`,
`padding:`, `color:` or `shadow:` parameters that let a feature drift.

## 1. What exists today (evidence)

| Implementation | Source | Radius / padding | Elevation | Distinct idea worth keeping |
|---|---|---|---|---|
| `ClCardGroup` | `core/widgets/cl_rows.dart` | 24 / rows | `shadows.card` (D-096) | The only core container; separators; input stroke |
| `RhCard` (51 refs, 19 files) | `features/rhythm/rhythm_widgets.dart` | 20 / 16 | Shadow, or `outline` / `hairline` / tinted `color`; `onTap` + `semanticLabel` | Outline for selected / suggested; whole-card tap |
| `PrintCard` (34 refs) | `features/print_studio/print_widgets.dart` | 20 / 14 | `lifted`, `outlined`, `selected`, `onTap` | Selectable product card |
| `AsCard` (26 refs) | `features/assistant/assistant_widgets.dart` | 18 / 14, fixed width 300 | Tones: surface, quiet, warn, errorEdge, danger | Chat-bubble card tones |
| `AiStateCard` (16 refs) | `features/ai/ai_widgets.dart` | — | White | Icon chip + eyebrow + headline + muted body + link: a clean **insight / state** anatomy |
| `AxCard` (10 refs) | `features/adaptive/today_adaptive.dart` | 20 / 14 | Shadow | Icon chip + title + subtitle + header link + child: a **dashboard widget** anatomy |
| `NuCard`, `SpCard`, `LbCard` | nutrition / spending / library widgets | 20 / 16 (Lb 16×14) | Shadow unless tinted or `flat` | Same thing three times |
| `MtGroupCard`, `NuGroup`, `SpGroup`, `LbGroup` | milestones / nutrition / spending / library | 16 | Shadow | Re-implementations of `ClCardGroup` |
| Stats `_Card`, history `_SummaryCard` / `_StatCard`, baby-profile `_StatCard` | `care/stats_screens.dart`, `care/history_screen.dart`, `me/baby_profile_screens.dart` | 24 / 24 / 18 | Shadow | **Insight** cards with numbers and charts |
| Care-hub `_Tile`, Today `_CardRow` | `care/care_hub_screen.dart`, `today/today_cards.dart` | 20 / 14 | Shadow | **Interactive** tiles with a care-coloured icon chip |
| `MemoryEntryCard` | `features/memories/memory_widgets.dart` | 20 / 12 | — | **Media-first** journal entry |
| `PremiumInlineCard`, `VideoQuotaCard`, `_PlanCard` ×2 | `features/premium/premium_style.dart`, `premium_widgets.dart`, `family_plan_v2.dart`, `plan_screen.dart` | Premium | Premium gradients | **Premium** presentation |

What they share: a `surface` fill, `shadows.card` on the page, roughly 16 padding, a 20–24 radius,
an optional icon chip, a title plus a muted body, and an optional whole-card tap. What drifts:
radius (14 / 16 / 18 / 20 / 24), padding (12 / 14 / 16), flags (`flat`, `lifted`, `outline`,
`hairline`, `color`), header placement.

## 2. Shared foundation (all variants)

These are the foundation values from `cl-design-foundations`; they are not restated here.

- **Surface:** `surface` with `shadows.card` on the page (D-096). Flat `surface2` inside sheets or
  cards. In Night care, fills carry the hierarchy.
- **Radius:** `ClRadius.card`. Compact per-item cards in a dense list may use `ClRadius.control`
  (one choice per screen), as in `cl-design-foundations` → `elevation-and-surfaces.md`. A dedicated
  "compact" radius (~16–20) is a token proposal (D-106) that needs an owner decision before the
  family is built.
- **Padding** `ClSpace.s4`; `s3` between blocks; `s1`–`s2` between title and subtitle.
- **Press:** whole card via `ClPressable(pressedOpacity: ClPressable.surfaceOpacity)`, 44 pt,
  one `semanticLabel` that reads the card as a sentence.
- **Never nested:** no elevated card inside another; inner grouping uses `surface2` or hairlines.

## 3. Variants

### A. Standard card

| | |
|---|---|
| Purpose | Group related content; present simple information on a page |
| Anatomy | Optional heading (`headline` or `bodyStrong`) → content (rows, text, small visuals) → optional footnote (`caption`, `inkMuted`) |
| Interaction | None at the card level; inner rows may be tappable |
| Foundation | Shared foundation; no accent |
| A11y | Heading marked; content in reading order |
| Use | Static summaries, explanations, groups of mixed content |
| Anti-patterns | A card around a single row (use a group); a card around a section heading; stacking 5+ standard cards where rows would do |
| Migrate later | `NuCard`, `SpCard`, `LbCard`, `RhCard` (default), stats `_Card` |

### B. Interactive card

| | |
|---|---|
| Purpose | Go to one destination, or surface a frequent action |
| Anatomy | Leading icon chip (care / brand tint) → title → one-line subtitle or status → trailing chevron, or the action's verb in `mintText` |
| Interaction | **The whole card is the tap target.** One destination. No buttons inside. A header link is allowed only on dashboard widgets whose body has its own content (like `AxCard`), and it must go somewhere different from the card |
| Foundation | Shared foundation + press feedback |
| A11y | `semanticLabel` = "title, status"; button role; 44 pt guaranteed |
| Use | Dashboard tiles (care hub, Today widgets), "continue where you left off", entry points |
| Anti-patterns | A `ClButton` inside a tappable card; two tap targets with the same destination; a title that doesn't match the destination (D-105) |
| Migrate later | Care-hub `_Tile`, Today `_CardRow`, `AxCard` (with header link), `RhCard(onTap:)` |

### C. Insight card

| | |
|---|---|
| Purpose | Show a statistic, trend or interpretation, and why it matters |
| Anatomy | Eyebrow or label → **hero number** (`numeral` via `ClTabularText`) + unit (or 2–3 stat tiles) → visual (bar, range, 7-day bars, `StackedDaysChart`) → one-line context ("thường 8–9 giờ") → optional link to detail |
| Interaction | Optional whole-card tap to the detail view |
| Foundation | Shared foundation; care-category accent for the visual only (`cl.care.X.accent` on graphics, `ink` / `soft` for text) |
| A11y | `semanticLabel` states the takeaway in words with units; the chart wrapped in `Semantics(label:)` |
| Use | Stats, sleep / feed summaries, growth, AI insight states (`AiStateCard` anatomy) |
| Anti-patterns | Numbers inside sentences; more than one highlighted tile; colour-only good / bad; a clinical judgement without a safe basis |
| Migrate later | Stats `_Card`, history `_SummaryCard` / `_StatCard`, baby-profile `_StatCard`, `AiStateCard`, `AsSummaryCard` |

### D. Media card

| | |
|---|---|
| Purpose | Present photos, videos, memories, milestones |
| Anatomy | Media first (`MediaTile` strip or grid, or a full-bleed image) → title / caption → meta (author · date in `caption`) → optional social row |
| Interaction | Tap opens the viewer or the entry; long-press for selection where the grid supports it |
| Foundation | Picture tiles use `shadows.tile` (`ClTileShadow`) when they sit on the page; text over a photo needs a gradient scrim (foundations, photo overlays); warm accents allowed |
| A11y | Each media item labelled (photo / video + duration, as `MediaTile` does); actions reachable without long-press |
| Use | Journal entries, keepsakes, album covers, milestone moments |
| Anti-patterns | Text on a photo without a scrim; tiny tap targets on overlay icons; cropping faces with arbitrary aspect ratios; a shadow on a tile inside a card |
| Migrate later | `MemoryEntryCard` (already the model), keepsake and album tiles, `_Thumbs` |

### E. Premium card

| | |
|---|---|
| Purpose | Explain a Premium feature or an upgrade, calmly |
| Anatomy | Short headline (Premium serif) → one-sentence value → gold action (`PremiumGoldButton`) → optional quiet secondary link |
| Interaction | One gold action; a dismiss or "Để sau" where it interrupts |
| Foundation | **Sanctioned exception:** `PremiumPalette` (`features/premium/premium_style.dart`), dark and gold in both palettes. Used **only** for Premium surfaces |
| A11y | Gold-on-dark text pairs come from `PremiumPalette`; the action is labelled; no fine print below 12 px except the crest |
| Use | The inline Premium suggestion (`PremiumInlineCard`), the paywall, plan cards, quota (`VideoQuotaCard`) |
| Anti-patterns | Gold or dark gradients on ordinary cards; several upsells on one screen; blocking a care task with an upsell; guilt copy |
| Migrate later | `_PlanCard` (two copies) → one Premium plan card; keep `PremiumInlineCard` as the model |

## 4. Interim recipe (until `ClCard` exists)

- **Rows** → `ClCardGroup`.
- **Anything else on a page:** a `Container` with exactly:
  - `color: cl.colors.surface`;
  - `borderRadius: BorderRadius.circular(ClRadius.card)`;
  - `boxShadow: cl.shadows.card`;
  - `padding: EdgeInsets.all(ClSpace.s4)`.

  Wrap it in `ClPressable(onPressed:, pressedOpacity: ClPressable.surfaceOpacity,
  semanticLabel:)` when it is interactive.
- **Inside a sheet:** `surface2`, no shadow.
- **Within a feature that already has a kit card** (`RhCard`, `NuCard`…), use that kit card for
  consistency *within that feature*, and don't create another one.
- **Never add a new feature-prefixed card class.** If you need the same card in a second
  feature, that is the signal to build the family (protocol in `component-evolution.md`).

## 5. Proposed API shape (for the future implementation, not for use now)

```dart
// Illustrative only — not in the codebase.
ClCard.standard({title?, child, footnote?})
ClCard.action({icon, tint: ClCareColor?, title, status?, onTap, semanticLabel})
ClCard.insight({label, value, unit?, visual?, context?, onTap?, semanticLabel})
ClCard.media({media, title?, meta?, onTap})
// Premium stays in features/premium (PremiumInlineCard, plan cards): not a ClCard variant in core,
// so Premium styling can't leak into ordinary surfaces.
```

Before building it:

1. An owner decision on the compact radius.
2. Goldens for each variant: Light / Night × vi / en, plus 200 % text.
3. A showcase section.
4. Migration one feature at a time when touched (`component-evolution.md`).
