# Component selection

**Reuse is a means, not the goal: the goal is a better experience for the parent.** If the closest
component makes the task harder (wrong interaction, wrong density, misleading semantics), don't
force it. Compose, or follow the missing-component protocol (`component-evolution.md`).

## 1. The procedure (before writing any widget)

1. **Task.** What is the reader trying to do here: read, compare, choose, enter, act, navigate,
   or recover?
2. **Interaction pattern:**
   - static information;
   - one tappable destination;
   - an action;
   - selection (single or multi);
   - entry;
   - feedback;
   - media.
3. **Search** `component-catalog.md`, then `core/widgets/` and the showcase
   (`features/showcase/showcase_sections.dart`).
4. **Look at a similar screen** (the archetype references in `cl-screen-patterns` → `screen-archetypes.md`) and copy *its*
   composition.
5. **Choose the closest suitable component.** Suitable means its purpose matches, not just its
   look.
6. **Compose** existing pieces (e.g. `ClCardGroup` + `MeRow` + `ClSectionHeader`) before writing
   anything new.
7. **Extend** only for a genuinely reusable need that fits the component's purpose.
8. **Create** only when reuse or composition would hurt usability or maintainability. Then follow
   `component-evolution.md`.

## 2. Decision trees

### Presenting information

```
Is it a label + value?
 ├─ one or several related facts → MeRow(title:, value:) inside ClCardGroup
 │     (ClInfoRow exists but no product screen uses it; MeRow is the house row)
 ├─ needs an icon-tile settings look → ClDetailRow
 └─ a person (avatar, role, pending) → ClListRow / ClMemberRow

Is it a number that answers "how much / how many"?
 ├─ changes live or is compared → ClTabularText(style: cl.text.numeral) + unit + label
 │     (no core stat tile yet: compose it inside a card; see card-system.md §C)
 ├─ a trend over days → StackedDaysChart; growth → WhoGrowthChart
 └─ inside a sentence and static → plain Text (fine when clearer; 3+ competing values → tiles or rows; cl-ux-writing → numbers-dates-and-units.md)

Is it a tappable destination?
 ├─ one of several in a list → MeRow(onTap:) (chevron added automatically)
 └─ a card-sized item with its own visual → a tappable card (card-system.md §B: ClPressable(surfaceOpacity))

Is it a photo, video or memory?
 └─ MediaTile (grid / strip), MemoryEntryCard (journal entry), ClTileShadow on page-level tiles

Is it a warning, info or error?
 ├─ inline information / attention / non-blocking error → MeNotice(tone: info | warn | error)
 ├─ a save failed → MeNotice(tone: error) today (ClErrorBanner is the intended core but is showcase-only)
 ├─ a result of an action the user just did → showClToast (error: true when it failed)
 └─ real danger (first aid) → feature-owned danger UI (first_aid/*), never reuse it for ordinary errors

Is it a section of a screen?
 ├─ page section → ClSectionHeader + content
 └─ settings group label → MeSection + ClCardGroup
```

### Taking an action

See `actions-and-navigation.md`. In short:

- one dominant `ClButton(style: primary)` per screen or sheet;
- the whole card tappable rather than a button inside it;
- a `plain` / `tinted` style for quiet actions;
- `MeRowAction` at a row's end;
- the dock "+" for the tab's frequent action.

### Choosing

```
2–3 short, mutually exclusive views → ClSegmented
filter a list (scrolling row) → ClFilterChip
one option from a list with explanations → ClOptionRow (in ClCardGroup)
one big one-handed choice with art → ClChoiceTile; several (multi) → ClSelectTile
on / off setting → MeRow(trailing: ClToggle) in a group, or ClSettingRow standalone
a day in a strip → ClDayPill; a relation → ClRelationChip
```

### Entering

```
text → ClTextField (grouped inside ClCardGroup, or standalone: true)
a code → ClCodeInput
a time / duration → a ClTimeRow that opens a showClSheet picker (pattern: pickCareTime / pickDuration)
an amount with a unit → today: care's AmountInput (feature) — ClAmountField is showcase-only; see evolution
a whole form in a sheet → CareSheetFrame pattern (header, fields, one primary)
```

### Feedback

See `forms-and-feedback.md`:

- `ClSkeleton` for a loading screen or section;
- `ClButton(loading:)` for the button's own action;
- `withClProgress` for a blocking call without a button;
- `showClToast` + undo after a save;
- a confirm sheet for irreversible actions.

## 3. Similar look, different meaning

Don't merge or swap these just because they look alike:

| Pair | Difference |
|---|---|
| `ClSectionHeader` vs `MeSection` | A page section (`headline`, can link) vs a settings group label (small muted). Both are right in their place |
| `ClChip` vs `ClFilterChip` | A static tag vs an interactive filter |
| `MeNotice(warn)` vs `danger` UI | Attention vs real-world danger |
| `MeNotice(error)` vs `showClToast(error: true)` | A persistent state on the page vs a transient result of an action |
| `ClSegmented` vs tabs (`ClNavBar`) | Switching a view inside a screen vs app navigation |
| `ClOptionRow` vs `MeRow` with a check | Choosing one value vs navigating |
| `ClSkeleton` vs `withClProgress` | Content arriving vs an action blocking the screen |

## 4. Anti-patterns

- **Picking a component by appearance.** A grey box is not automatically `MeNotice(info)`; ask
  whether it is a notice.
- **A `Container` + `BoxDecoration` "card"** when `ClCardGroup` or the card foundation fits.
- **One card per row.** Rows go in one group.
- **A private `_XxxRow` that re-implements `MeRow`** with different paddings.
- **Material widgets in feature UI:** `ElevatedButton`, `TextButton`, `ListTile`, `AlertDialog`,
  `SnackBar`, `showModalBottomSheet`.
- **Hand-styled interaction:** `GestureDetector` instead of `ClPressable` (no 44 pt, no press
  feedback, no semantics).
- **Forcing a component** whose density, interaction or semantics fight the task, just to
  "reuse".

## 5. Content slots (D-110)

Shared components must never force content. Every element must earn its place
(`senior-ui-ux` → `references/content-simplification.md`).

- **Optional slots stay optional.** Pass a subtitle, description, helper, icon or badge only when
  it is Essential or genuinely helps. A title-only row or card is a complete component.
- **Verified slot status (2026-10-25):**
  - optional already: `MeRow` subtitle / value / icon, `MeNotice` body / icon, `ClListRow`
    subtitle / leading, `ClSectionHeader` link, `ScreenHeading` subtitle, `ClSheetHeader`
    (title only);
  - **required:** `ClEmptyState.message` and `.icon` (`core/widgets/cl_misc.dart`). Write the
    shortest true message; when a screen genuinely needs a title-only empty state, relax the
    parameter to optional (backward compatible, L2) rather than inventing filler text;
  - private tiles that require a subtitle (e.g. `care_hub_screen.dart` `_Tile`) become optional
    when touched.
- **No decorative container around a simple row.** A single `MeRow` or `ClListRow` doesn't need a
  `ClCardGroup` of its own unless it sits beside other groups that need visual parity.
- **No card inside a card.** If a component already draws a surface, don't wrap it in another.
- **Helper text in forms** (`FieldLabel`, input hints) only when the field is ambiguous or
  validation needs it.
- **Don't change a component API just to remove content.** Omit the optional argument at the
  call site; change the API only when it forces content (as above).
