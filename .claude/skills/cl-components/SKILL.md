---
name: cl-components
description: Choosing, composing, extending and creating Flutter UI components in Child Life (apps/mobile). Use when picking a widget for a screen, sheet, row, card, notice, button, form field, picker, toast, loading state or media tile; when about to write a new widget class, a private _XxxCard / _XxxRow, a feature-prefixed kit widget, or a Container+BoxDecoration "card"; when changing or adding anything in lib/core/widgets; and when deciding whether to reuse, extend or promote a component. Holds the verified component catalogue, selection trees, the proposed ClCard family spec (not implemented), the missing-component protocol and the duplication / migration audit. Routed from senior-ui-ux; visual values come from cl-design-foundations.
---

# Child Life components

**Goal: a better experience for the parent. Reuse is how we get there, not the goal itself.** Use
the closest *suitable* component. Never force one whose interaction, density or meaning fights
the task. The Flutter code is the source of truth (D-104), and every component named here was
verified in it. Token values (colour, type, spacing, radius, motion) belong to
`cl-design-foundations`; this skill doesn't restate them.

## The procedure

1. **The user's task:** read, compare, choose, enter, act, navigate, recover.
2. **The interaction pattern:**
   - static information;
   - one destination;
   - an action;
   - a selection;
   - an entry;
   - feedback;
   - media.
3. **Search** `references/component-catalog.md`, then `lib/core/widgets/` and the showcase
   (`features/showcase/`).
4. **Inspect a similar screen** (`cl-screen-patterns` → `screen-archetypes.md`) and copy its composition.
5. **Pick the closest suitable component.** Purpose must match, not just looks.
6. **Compose** existing pieces before writing anything new.
7. **Extend** only for a reusable need that fits the component's purpose.
8. **Create** only when reuse or composition would hurt usability or maintainability, via
   `references/component-evolution.md`.

## House defaults (verified)

| Need | Default |
|---|---|
| Rows of information or settings | `MeRow` inside `ClCardGroup`; `MeSection` above a settings group |
| Single choice from a list | `ClOptionRow` |
| Page section heading | `ClSectionHeader` |
| 2–3 view switch | `ClSegmented`; `ClFilterChip` for filters |
| Any custom tappable | `ClPressable` (`surfaceOpacity` for rows and cards) |
| Text buttons | `ClButton` |
| Sheets | `showClSheet` + `ClSheetHeader`; forms in the `CareSheetFrame` pattern |
| Tab root | `ClPinnedHeaderScaffold`; pushed page `MePage`; flow `OnboardingScaffold` + `ClTopBar` |
| Notice (info / warn / error) | `MeNotice` |
| Toast after an action (+ undo) | `showClToast` / `ClToaster` |
| Loading | `ClSkeleton` (content); `ClButton(loading:)` (own action); `withClProgress` (blocking call without a button) |
| Whole-area empty | `ClEmptyState` |
| Text entry | `ClTextField` |
| Time | A `ClTimeRow` that opens a picker sheet like `pickCareTime` |
| Confirm | The `rhConfirm` shape |
| Photo / video | `MediaTile`; journal entry `MemoryEntryCard`; page tiles `ClTileShadow` |
| Changing numbers | `ClTabularText` |

**Core but showcase-only** (no product screen uses them; render before relying on them):
`ClInfoRow`, `ClErrorBanner`, `ClAmountField`, `ClRoleOption`, `ClCoachmark`.

## Rules of thumb

- **Cards.** **There is no `ClCard` yet.** The family (standard / interactive / insight / media,
  plus Premium kept in `features/premium`) is a **proposal** in `references/card-system.md`. Until
  it is built:
  - use `ClCardGroup` for rows;
  - otherwise use the interim card recipe;
  - inside a feature that already has a kit card, use that card;
  - never add a new feature-prefixed card.
- **Actions (D-105).**
  - One dominant `primary` per screen or sheet.
  - A card or row with one destination is tappable as a whole; no button inside it.
  - Frequent actions on the dock or quick actions; rare and destructive ones in a sheet or the
    detail view.
- **Feedback.**
  - Prefer **undo** over confirm when the action is reversible.
  - Confirm sheets name the object and the consequence, and the confirm verb repeats the action.
- **Off-system — don't add more:** `showModalBottomSheet`, `AlertDialog`, `SnackBar`, bare
  `CircularProgressIndicator`, raw `TextField`, Material buttons, `GestureDetector` tappables,
  `Icons.*`.
- **Similar look ≠ same component.**
  - `ClSectionHeader` and `MeSection` serve different purposes; so do `ClChip` and
    `ClFilterChip`, and `MeNotice(error)` and an error toast.
  - Check semantics before swapping or merging.
- **New reusable components:**
  - live in `lib/core/widgets/` with a `Cl` prefix and a semantic API (no `radius:` / `padding:` /
    `color:` knobs);
  - have both palettes, a11y, goldens and a showcase entry;
  - are L2 (autonomous) when they consolidate or redesign existing UI with existing tokens;
    they are L3 (owner) only when they need a new token or design-system direction, or change
    behaviour (`senior-ui-ux` §3).

## References

| File | Load when |
|---|---|
| `references/component-catalog.md` | Finding a component and its real API, accessibility, theme notes and an example usage |
| `references/component-selection.md` | Decision trees (present, act, choose, enter, feedback); similar-but-different pairs; anti-patterns |
| `references/card-system.md` | Anything card-like; the proposed `ClCard` variants; the interim card recipe |
| `references/actions-and-navigation.md` | Buttons vs tappable rows or cards, icon actions, dock and quick actions, visible vs secondary placement, navigation containers |
| `references/forms-and-feedback.md` | Inputs, pickers, validation, loading vs processing vs background, success / error, confirm and undo, progress |
| `references/component-evolution.md` | No suitable component; extend vs create; the duplication audit and migration table; the component quality checklist |

**Related skills:**

- `senior-ui-ux` runs the workflow and the approval thresholds;
- `cl-design-foundations` supplies the values;
- `cl-screen-patterns` owns screen composition and the layout of states;
- `cl-design-review` owns the review rubric and visual verification.

**Content slots are optional (D-110).** Redesigning a component's structure (composition, emphasis, variants) while it keeps the same
function and API contract is L2 (D-112): improve the shared component once rather than patching
each screen. Omit subtitles, descriptions, helpers, icons and badges
that don't help; never wrap a simple row in a decorative container or nest cards. Details and the
verified slot status: `references/component-selection.md` §5.

## Before finishing

- [ ] Every widget used exists (catalogue or `core/widgets`), with the right API.
- [ ] No new feature-prefixed kit widget, no new private card or row that duplicates a shared one.
- [ ] One dominant primary; whole-surface taps where there is one destination; no nested
      duplicate targets.
- [ ] Loading, success, error and confirm use the existing feedback components.
- [ ] A new or changed reusable component passes the quality checklist in
      `component-evolution.md`.
