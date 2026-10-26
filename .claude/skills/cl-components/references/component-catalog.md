# Component catalogue (verified 2026-10-25)

Every entry here was checked against its source and constructor. Paths are relative to
`apps/mobile/lib/`. Usage counts are for `features/` + `app/`.

**Tiers:**

- **Core:** `core/widgets/*`, in the showcase (`features/showcase/`) and its goldens.
- **Shared:** lives in a feature folder but is used across features. Treat as shared; promote to
  core when it's next touched (see `component-evolution.md`).
- **Showcase-only:** core, but no product screen uses it yet. Check that it still matches the
  current look before relying on it, and render it.

Theme note for all of them: core widgets read `context.cl`, so Light and Night care come for
free. Night-care specifics are listed only where behaviour differs. Token rules are in
`cl-design-foundations`.

## 1. Layout and navigation

| Component | Source | Use for | Avoid when | Key API | A11y / theme | Used in |
|---|---|---|---|---|---|---|
| `ClPinnedHeaderScaffold` | `core/widgets/cl_navigation.dart` | Tab screens and Me-style pages: the header (baby switcher or back bar) stays pinned, the body scrolls under it, a hairline appears, and the title collapses like iOS | Flows with a step bar (use `ClTopBar`); sheets | `body`, `header`, `collapsedTitle`, `collapseAfter`, `scrollDepth` | Hairline only after scroll | `today/today_screen.dart` (8 files) |
| `ClNavHeader` | `cl_navigation.dart` | Large-title header: subtitle above a `largeTitle`, optional trailing control | Inside sheets | `title`, `subtitle`, `trailing` | Title is `Semantics(header: true)` | `family/family_screen.dart` (2 files) |
| `ClTopBar` | `cl_navigation.dart` | Flow and onboarding top bar: compose back, skip, progress, countdown, brand | Tab screens | `onBack`, `onSkip`, `progress`, `countdown`, `brand`, `trailing` | Back is 44 pt | `care/growth_standards_screen.dart` (27 files) |
| `ClProgress` / `ClPageDots` | `cl_navigation.dart` | 4 px setup progress; onboarding pagination | Upload progress with a label (see feedback) | `value`; `count`, `index` | — | `auto_save/auto_save_home.dart` |
| `ClNavBar` / `ClTabDock` / `ClDockAction` / `ClQuickLogButton` | `cl_navigation.dart` | The floating tab dock with the tab's own "+" | Anything but the home shell | `role`, `active`, `onSelect`, `action: ClDockAction(label:, onPressed:)`, `tabs`, `dots` | Tab switch haptic (`ClHaptics.selection`, silent at night); labels always shown (D-069) | `home/home_shell.dart` only |
| `ClBabySwitcher` | `cl_navigation.dart` | Avatar + baby name chip; opens the profile or the picker | — | `label`, `avatar`, `hasMultiple`, `onTap` | — | 14 files |
| `BabyHeader` (shared) | `features/home/home_shell.dart` | The tab header row: switcher plus actions (bell, Night care toggle) | Pushed pages | — | — | 8 files |
| `MePage` (shared) | `features/me/me_widgets.dart` | A pushed page with a large title, back, scrolling list, pull-to-refresh, safe bottom | Tab roots (use `ClPinnedHeaderScaffold`) | `title`, `children`, `back`, `trailing`, `onRefresh`, `bottomPadding` | Title is a header | `engagement/engagement_week.dart` (15 files) |
| `OnboardingScaffold` / `ScreenHeading` (shared) | `features/onboarding/widgets/onboarding_layout.dart` | Step screens: top bar, content, bottom action; a `title` / `largeTitle` heading with subtitle | Content-heavy pages | `content`, `topBar`, `bottom`, `padding`; `title`, `subtitle`, `large` | — | 29 / 11 files |
| `showClSheet` / `ClSheetRoute` | `core/widgets/cl_sheet.dart` | Every bottom sheet: chooser, form, confirm, picker | Full flows of 3+ steps (push a page) | `showClSheet<T>(context:, builder:, dismissible:)` | Drag past 30 % or flick to close; Night care has no bounce; Reduce Motion fades; closes toasts on open | 74 files |
| `ClSheetHeader` | `cl_sheet.dart` | Grabber, `title2` title, 44 pt close labelled "Đóng" | Pages | `title`, `titleColor`, `onClose` | Close is labelled | 70 files |
| `ClSectionHeader` | `core/widgets/cl_rows.dart` | A **page** section heading (`headline`) with an optional `mintText` link | A settings group label (use `MeSection`) | `title`, `linkLabel`, `onLink` | Header semantics; link 44 pt via `ClPressable` | `care/care_screens.dart` (18 files) |
| `MeSection` (shared) | `features/me/me_widgets.dart` | A **settings-group** label: small muted `label` / 600 above a group | A page section (use `ClSectionHeader`) | `MeSection(title)` | Header semantics | 9 files |

## 2. Content presentation

| Component | Source | Use for | Avoid when | Key API | A11y / theme | Used in |
|---|---|---|---|---|---|---|
| `ClCardGroup` | `cl_rows.dart` | The default container: rows or fields on a `surface` card, 1 px separators, `ClRadius.card`, `shadows.card` (D-096) | A single non-row block that needs its own layout (compose a card: see `card-system.md`) | `children`, `shadow`, `color` (in a sheet: `surface2`, no shadow) | Draws the input stroke for `ClTextField` children | 44 files |
| `MeRow` (shared) | `features/me/me_widgets.dart` | **The most used row** (108 refs, 20 files): icon / leading, title, subtitle, value, chevron when tappable, `destructive` | Selection lists (use `ClOptionRow`) | `title`, `icon`, `leading`, `subtitle`, `value`, `onTap`, `trailing`, `destructive`, `iconTint` | Reads "title, subtitle, value"; `MergeSemantics` when static | `care/care_hub_screen.dart` |
| `MeRowAction` (shared) | `me_widgets.dart` | A plain text action at a row's end ("Gỡ", "Đăng xuất") | A primary action | `label`, `onPressed`, `destructive` | — | 6 files |
| `ClListRow` | `cl_rows.dart` | A member or invite row: avatar leading, title, subtitle; min height 60 | Settings (use `MeRow`) | `title`, `subtitle`, `leading`, `onTap`, `isInvite`, `subtitleColor` | Wraps at 200 % | 9 files |
| `ClDetailRow` | `cl_rows.dart` | A settings row with an icon tile, label, value, chevron; height 56 | Long values | `icon`, `label`, `value`, `valueIsAccent`, `onTap` | — | `appearance/appearance_screen.dart` (7 files) |
| `ClOptionRow` + `ClRadio` | `cl_rows.dart` | Single choice in a list: title, subtitle, radio | 2–3 short options (use `ClSegmented`); multi-select | `title`, `selected`, `onTap`, `subtitle` | The radio shows a check, not just colour | `care/stats_screens.dart` (20 files) |
| `ClInfoRow` | `cl_rows.dart` | Read-only label / value, height 56 | — | `label`, `value` | — | **Showcase-only** (`MeRow` with `value` is what product uses) |
| `ClMemberRow` | `core/widgets/cl_misc.dart` | A family member: you / member / pending, resend | — | `initial`, `name`, `detail`, `status`, `onTap`, `onResend` … | — | `family/family_screen.dart` |
| `MeNotice` (shared) | `me_widgets.dart` | **The de facto notice:** icon, title, body, optional child; tones `info` (`surface2`), `warn` (`sunshineSoft` + `ink`), `error` (`errorSoft`) | A secondary `ClButton` as its child in the info tone (invisible); page-blocking errors | `title`, `body`, `icon`, `tone: MeTone`, `onTap`, `child` | Merged semantics, or `ClPressable` with "title. body" | 14 files |
| `ClErrorBanner` | `core/widgets/cl_status.dart` | Save failed: bold `error` lead plus a reassuring `ink` sentence | — | `lead`, `message` | Icon + words | **Showcase-only** |
| `ClChip` | `cl_status.dart` | Static audience or milestone chip: `neutral`, `warm`, `sun` (warm / sun on memory screens only) | Filters (use `ClFilterChip`) | `label`, `style`, `icon` | — | 3 files |
| `ClSyncStatus` | `cl_status.dart` | Sync pill: synced / pending / error, always icon + words | — | `state`, `label` | Never colour alone | `care/care_screens.dart` |
| `ClFloatChip` | `cl_status.dart` | A floating value chip on an illustration card (steady digits) | Data stats on a page | `value`, `lead`, `icon`, `initial` | Tabular | `onboarding/widgets/heroes.dart` |
| `ClAvatar` / `SavedBabyAvatar` (shared) | `cl_status.dart`; `features/baby/baby_avatar_view.dart` | Initial avatar (mint = adults, warm = baby / relatives, add); the baby's saved photo avatar | — | `style`, `initial`, `size`; `baby`, `size` | — | `ClAvatar` is used inside `ClListRow`; `SavedBabyAvatar` 18 files |
| `ClEmptyState` | `cl_misc.dart` | A whole area with no content: icon, `headline`, one sentence, one tinted action | An empty *section* on a dashboard (hide it or show one muted line) | `icon`, `title`, `message`, `actionLabel`, `actionIcon`, `onAction` | — | `print_studio/print_hub.dart` (13 files) |
| `ClSkeleton` | `core/widgets/cl_feedback.dart` | Loading blocks shaped like the content | A blocking server call (use `withClProgress`) | `width`, `height`, `radius` (default 14) | Static in Night care and under Reduce Motion | `family/join_screens.dart` (15 files) |
| `ClTabularText` | `core/design/tabular_text.dart` | Any number that changes or is compared (timers, stats) | Static numbers inside sentences | `text`, `style`, `semanticsLabel` | One spoken label | `care/history_screen.dart` (14 files) |
| `StackedDaysChart` / `WhoGrowthChart` | `features/care/stacked_days_chart.dart`, `growth_chart.dart` | 7 / 30-day stacked bars with an average; WHO growth curves | One-number answers (use a stat) | `bottoms`, `tops`, `labels`, colours, `average`…; `measure`, `points`, `unit`… | Wrap in `Semantics(label:)` with the takeaway | `care/stats_screens.dart`, `care/history_screen.dart` |
| `ClCoachmark` / `ClTourTip` | `cl_misc.dart` | First-run bubble; spotlight tour step | Persistent help | `text`; `step`, `title`, `body`, `onNext`… | Inverts in Night care | `ClTourTip`: `home/today_tour.dart`, `assistant/assistant_entry.dart`; `ClCoachmark` showcase-only |

**No core stat tile and no core card exist.** See `card-system.md` and `component-evolution.md`.

## 3. Actions

| Component | Source | Use for | Avoid when | Key API | A11y / theme | Used in |
|---|---|---|---|---|---|---|
| `ClButton` | `core/widgets/cl_button.dart` | Every text button. Styles: `primary` (`mintDeep`), `secondary` (`surface2`, 52 high), `tinted` (`mintSoft`), `plain` (text, 44), `outline`, `destructive` (`errorSoft`), `apple` | Whole-card taps (make the card tappable); icon-only actions | `label`, `onPressed`, `style`, `icon`, `leading`, `expand`, `loading` | Single-line label (ellipsis); `loading` keeps the label, ignores taps, is a live region; 56 pt | 109 files |
| `ClRoundButton` | `cl_button.dart` | 64 pt round "next" (icon only) | General icon buttons | `semanticLabel` (required), `onPressed`, `icon` | Label mandatory | 3 files |
| `ClBackButton` | `cl_button.dart` | 44 pt round back | — | `semanticLabel`, `onPressed` | — | 7 files |
| `ClPressable` | `core/widgets/cl_pressable.dart` | Make any custom surface tappable: opacity press, 44 pt minimum, disabled 40 %, semantics, long-press | Text buttons (use `ClButton`) | `onPressed`, `semanticLabel`, `pressedOpacity` (`ClPressable.surfaceOpacity` 0.7 for rows and cards), `isButton`, `selected`, `minSize`, `onLongPress` | Button semantics + label; selected state | 113 files |
| `TodayQuickActions` / `showQuickLog` (feature) | `features/today/today_cards.dart`, `features/care/care_sheets.dart` | The quick-action strip on Hôm nay; the quick-log chooser sheet | Other screens (compose your own with tiles) | — | — | Today, the dock "+" |

## 4. Forms and selection

| Component | Source | Use for | Avoid when | Key API | A11y / theme | Used in |
|---|---|---|---|---|---|---|
| `ClTextField` | `core/widgets/cl_inputs.dart` | Text entry: caption label above the value; grouped (inside `ClCardGroup`) or `standalone` | Numeric amounts with units (see the amount row below) | `label`, `controller`, `placeholder`, `standalone`, `password`, `keyboardType`, `textInputAction`, `autofillHints`, `onChanged`, `onSubmitted`, `maxLength`, `maxLines`, `focusNode` | Focus ring 2 px; resting stroke `clInputStroke`. **No error parameter** (see `forms-and-feedback.md`) | 33 files |
| `ClCodeInput` | `cl_inputs.dart` | 6-digit invite code | — | `controller`, `length`, `onCompleted`, `semanticLabel` | — | `family/join_screens.dart` |
| `ClToggle` / `ClSettingRow` | `cl_inputs.dart` | An iOS switch; a standalone setting card with a switch | A switch inside a grouped list (use `MeRow(trailing: ClToggle(…))`) | `value`, `onChanged`, `semanticLabel`; `icon`, `title`, `value`, `onChanged`, `subtitle` | — | 8+ files |
| `ClAmountField` | `cl_inputs.dart` | A big numeric amount (`numeralXl`) + unit, focused style | — | `value`, `unit`, `focused`, `onTap` | Steady digits | **Showcase-only**; care uses its own `AmountInput` |
| `ClTimeRow` | `cl_inputs.dart` | "When it happened" row; tap opens a picker | — | `label`, `value`, `onTap`, `icon` | — | `care/care_screens.dart` (5 files) |
| `pickCareTime` / `pickDuration` (feature) | `features/care/care_sheets.dart` | Time wheel in a `showClSheet` (≤ now, 60-day floor); duration wheel | Dates far back (copy its pattern) | `pickCareTime(context, initial:, earliest:)` | Night-care-aware `CupertinoTheme` | care, timers |
| `ClSegmented<T>` | `core/widgets/cl_segmented.dart` | 2–3 short mutually exclusive views (asserts 2–3) | 4+ options, long labels | `options`, `selected`, `onChanged`, `labelOf` | Caller persists the last choice | 23 files |
| `ClFilterChip` | `core/widgets/cl_choices.dart` | Single-select filter in a scrolling row; h40, hit 44 | Static tags (use `ClChip`) | `label`, `selected`, `onTap` | Selected = fill + weight | 14 files |
| `ClRelationChip`, `ClDayPill` | `cl_choices.dart` | Relationship pick (Mẹ, Ba, Bà…); the day strip (today right-most) | — | `label`, `selected`, `onTap`; `weekday`, `day`… | — | family, history |
| `ClChoiceTile` / `ClSelectTile` | `cl_choices.dart` | Big one-hand single choice with art (106×120); multi-select tracker tiles (166×128) | Text-only options | `label`, `art`, `selected`, `onTap` | — | assistant, onboarding |
| `ClEntryOption`, `ClRoleOption`, `ClPermissionTile` | `cl_choices.dart` | Large entry choice in a care colour; invite role card; what a role can do | — | see source | — | timers; `ClRoleOption` **showcase-only**; `ClPermissionTile` in invites |
| `CareSheetFrame` + `FieldLabel` (shared) | `features/care/care_sheets.dart` | A sheet form: header in a care colour, scrolling fields, a pinned primary | Non-form sheets | `title`, `titleColor`, `children`, `primary` | — | care, solids |

## 5. Feedback

| Component | Source | Use for | Key API | A11y / theme |
|---|---|---|---|---|
| `showClToast` / `ClToaster` / `dismissClToasts` | `core/widgets/cl_feedback.dart` | A result after an action, optionally with **undo**; 4 s | `showClToast(context, message:, actionLabel:, onAction:, error:)`; `ClToaster.of(context)` captured before an `await` | Announced; Night care has no glow |
| `withClProgress` | `cl_feedback.dart` | A blocking server call from a row, sheet or icon (no button to spin); shows after 150 ms | `withClProgress(context, () => work())` | Live region |
| `ClButton(loading: true)` | `cl_button.dart` | The button's own action is running | — | Live region |
| `ClSyncStatus`, `UploadPill` (shared, `features/memories/memory_widgets.dart`) | — | Background sync and upload state | — | Icon + words |

There is no shared confirmation component. See `forms-and-feedback.md`.

## 6. Media

| Component | Source | Use for | Avoid when | Key API | Notes |
|---|---|---|---|---|---|
| `MediaTile` (shared) | `features/memories/memory_widgets.dart` | A photo or video thumbnail: loads the display rendition when large; video shows the duration or a play mark; selection and favourite states | Non-memory images | `item`, `onTap`, `onLongPress`, `selecting`, `selected`, `radius` (6), `favorite` | Labels itself as photo or video + duration. 11 files |
| `PlayGlyph` (shared) | `memory_widgets.dart` | The play mark on video | — | — | 6 files |
| `MemoryEntryCard` (shared) | `memory_widgets.dart` | One journal entry: compact photo strip / grid with "+N", author, date | Single photos elsewhere | `memory`, `items`, `myUid`, `dateLabel`, `onOpen`, `favorites`, `footer` | `memories/memories_screen.dart` |
| `ClTileShadow` | `core/widgets/cl_rows.dart` | Lift a picture tile off the page (D-096) | Inside cards | `child`, `radius`; `ClTileShadow.stripPadding` for horizontal strips | — |
| `ClArt` / `ClLogo` | `core/widgets/cl_art.dart` | Fixed-colour illustrations; the logo | Photos | `ClArt(ClIllustration.x)`; `ClLogo(kind:)` | Decorative unless labelled |

## Not here on purpose

Feature-prefixed kits (`Rh*`, `Nu*`, `Sp*`, `Lb*`, `Mt*`, `Sd*`, `As*`, `Print*`, `Fa*`), private
`_*Card` / `_*Row` widgets and the Premium components are **not general-purpose**. Their status
and migration path are in `component-evolution.md`; the Premium components are in
`card-system.md` §E.
