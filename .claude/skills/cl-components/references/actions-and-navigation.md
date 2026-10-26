# Actions and navigation

Rule (D-105): **one dominant filled primary button per screen or sheet**, where a primary applies.
Dashboards may hold many interactive cards, each with one obvious destination. Secondary actions
never compete. Frequent actions are easy to find and reach. Clarity beats button counts.

## 1. Choosing the action component

| Need | Component | Notes |
|---|---|---|
| The main thing to do on a screen or sheet | `ClButton(style: ClButtonStyle.primary, expand: true)` at the bottom (thumb zone) | One. Label = verb, 1–3 words, naming where it goes |
| An alternative next to the primary | `ClButton(style: secondary)` (`surface2`) or `plain` | Never another `primary`. Not `secondary` on a `surface2` parent (invisible; use `plain`) |
| A quiet brand action (empty state, "add another") | `ClButton(style: tinted)` | `ClEmptyState` uses it |
| An inline text action, link, "Xem tất cả" | `ClButton(style: plain)`, or the `ClSectionHeader(linkLabel:, onLink:)` link | 44 pt via `ClPressable` |
| A destructive action | `ClButton(style: destructive)` (`errorSoft` + `error`) **inside a confirm sheet** | Not as the screen's dominant action |
| An action at a row's end ("Gỡ", "Đăng xuất") | `MeRowAction(label:, onPressed:, destructive:)` | — |
| An icon-only control | `ClPressable(semanticLabel: …, child: ClIcon(…))`, `ClBackButton`, `ClRoundButton` (64, flow "next") | The label is mandatory; 44 pt minimum |
| Go to a detail screen from a list | `MeRow(onTap:)`: chevron automatic | Whole row tappable |
| Go to a destination from a card | The card itself (`ClPressable(pressedOpacity: ClPressable.surfaceOpacity)`) | No button inside |
| The tab's frequent action | `ClDockAction(label:, onPressed:)` on `ClTabDock`: Ghi nhanh on Hôm nay, add photos on Kỷ niệm | Shell-owned; relatives get none |
| A frequent set of shortcuts | Quick actions (`TodayQuickActions` + `QuickActionIcon` in `features/today/`), the quick-log chooser (`showQuickLog`) | Order by frequency for the role |
| Confirm before something irreversible | A `showClSheet` with `ClSheetHeader`, one sentence, the confirm button, then `secondary` cancel (see `forms-and-feedback.md` §5) | — |
| A Premium upgrade | `PremiumGoldButton` inside Premium surfaces only | Never on ordinary cards |

**Avoid:** Material `ElevatedButton`, `TextButton`, `FilledButton`, `OutlinedButton`, `IconButton`
(30 uses remain in print_studio and diagnostics), a bare `GestureDetector`, and feature pill
buttons (`LbPillButton`, `RhPillButton`, `SpBottomButton`, …).

## 2. Cards, rows and nested targets

- **Prefer the whole surface as the target** when the card or row has one destination. A button
  inside it only adds a second, smaller target with the same meaning.
- **Nested tappables only when the interaction truly needs two outcomes:** a row that opens
  *and* a toggle; a media card that opens *and* has a favourite heart. Then:
  - the inner control has its own 44 pt target and its own label;
  - it doesn't sit where a thumb lands for the main tap;
  - the outer semantics don't swallow it.
- **A dashboard widget card** (`AxCard` pattern) may carry a header link ("Xem tất cả") *and*
  tappable inner rows. The link must go somewhere different from each row.
- **Label = destination** ("Xem tuần này" opens the week). A card titled "Tuần này" doesn't open
  today.

## 3. Visible or secondary placement

| Keep visible | Move to a secondary place (a sheet of options, the detail screen, the Me / settings area) |
|---|---|
| The action the 5-second question leads to | Rare or administrative actions (export, rename, delete) |
| Actions used daily (log, add a photo, start a timer) | Destructive actions: in the detail view, behind a confirm |
| Recovery from an error (retry) | Personalisation and settings |
| The next step in a flow | A second and third way to do the same thing |

There is no core overflow-menu component. A "more" control is an icon `ClPressable` (labelled)
that opens a `showClSheet` listing actions as `MeRow`s, with destructive actions last.

## 4. Frequency and context

- **The most frequent action of the tab is on the dock** (`ClDockAction`). Don't duplicate it as
  a big button on the same screen.
- **Quick actions are ordered by use for the reader's role.** Parents and caregivers log;
  relatives don't (no "+" for relatives, `roleCanQuickLog` in `cl_navigation.dart`).
- **In sheets, the primary is pinned at the bottom** (`CareSheetFrame` `primary:`). Inputs scroll
  above it.

## 5. Navigation components

| Need | Use |
|---|---|
| A tab root | `ClPinnedHeaderScaffold` + `BabyHeader` (`features/home/home_shell.dart`) |
| A pushed page | `MePage`, or a `Scaffold` with `ClTopBar(onBack:)`; route via go_router `context.push` (`app/router.dart`) |
| A step-by-step flow | `OnboardingScaffold` + `ClTopBar(progress:)` / `ClProgress` |
| A short task without leaving context | `showClSheet` |
| A view switch inside a screen | `ClSegmented` (2–3 options), `ClFilterChip` row |
| Back | Platform back / `ClBackButton`; never a custom route transition (D-013) |

Prefer go_router routes to imperative `Navigator.push(MaterialPageRoute…)` (15 files still do the
latter; that is debt). Don't call something a "sheet" if it pushes a page.

## Good / bad

```dart
// ✅ interactive card: one target
ClPressable(
  onPressed: openWeek,
  pressedOpacity: ClPressable.surfaceOpacity,
  semanticLabel: weekSummaryLabel, // one sentence built from ARB strings
  child: card,
)

// ❌ a button inside a card that already goes there
card(children: [..., ClButton(label: 'Xem chi tiết', onPressed: openWeek)])

// ❌ two primaries
Column(children: [ClButton(label: 'Lưu', ...), ClButton(label: 'Lưu và thêm', ...)])
// ✅
Column(children: [ClButton(label: 'Lưu', expand: true, ...), ClButton(label: 'Lưu và thêm', style: ClButtonStyle.plain, ...)])
```
