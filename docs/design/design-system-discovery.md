# Child Life — Design System Discovery (Flutter app)

Step 1 of the Product Design Skill System. Read-only analysis of `apps/mobile` on branch
`s2-onboarding`, 2026-10-25. No source, copy or CLAUDE.md was changed; Figma was not used.

**Evidence labels.** **[V]** verified in source (file reference or grep count over
`apps/mobile/lib/features/**` unless stated). **[A]** assumption or impression — inferred from
names, comments or partial reading, not confirmed by rendering the screen. Counts are grep counts:
they show scale and direction, and a few may include unrelated matches.

Target: MB Bank's clarity, scanability and action orientation, combined with Child Life's warm,
minimal, family-centred identity.

---

## 1. Executive Summary

Child Life already has a **real, token-driven design system**. It has three parts:

- **Generated tokens.** `packages/design-tokens/tokens.json` generates
  `apps/mobile/lib/core/design/tokens.g.dart` and the web CSS.
- **Themed typography.** `ClTheme` is exposed as `context.cl` and has two palettes: Light, and
  Night care (a calmer palette for night-time care).
- **A core widget kit.** About 40 `Cl*` widgets in `lib/core/widgets`, used heavily:
  - `ClButton` in 109 files, `ClPressable` in 113, `ClIcon` in 134.
  - `showClSheet` in 74, `ClToaster` in 78.

Motion, haptics, reduce-motion, tabular numerals, the two palettes and accessibility minimums are
built into the core rather than left to each screen. About 1,786 golden PNGs cover the
Light × Night care × vi × en matrix.

The weakness is **what sits between the core and the screens**. The core has rows, sheets and
buttons, but no general **card**, **notice/banner**, **stat tile**, **icon chip**, **date/time
picker sheet** or **async-state wrapper**. As a result, roughly 15 features each grew their own
mini kit (`Rh*`, `Nu*`, `Sp*`, `Lb*`, `Mt*`, `Sd*`, `As*`, `Print*`, `Fa*`, `Me*`, `Premium*`).
These kits re-implement the same card, banner, pill, round icon and page frame with slightly
different radii, paddings and font sizes. The visual language stays recognisable but drifts:

- Card radii in use: 24, 20, 18, 16 and 14.
- 593 font-size overrides; the most common sizes, 15 and 13, are not on the type scale.
- Most screens never show a loading or error state.

UX writing is a similar story:

- **Strengths.** A large, disciplined ARB catalog: 6,097 keys, full vi/en parity, almost no
  hardcoded strings. The tone is warm and peer-level.
- **Weaknesses.** Shared actions ("Xong", "Thử lại", "Để sau") are copied per feature rather than
  reused. Core nouns have competing names ("ghi nhận / nhật ký / ghi chép / bản ghi";
  "gia đình / nhà / hộ"). A long tail of multi-sentence explanatory strings exists, and system
  words ("đồng bộ", "bản ghi", "offline") reach main surfaces.

The work ahead is consolidation and convention, not a new visual direction.

---

## 2. Current Design Architecture

### 2.1 App structure [V]

| Layer | Location | Notes |
|---|---|---|
| Entry / bootstrap | `lib/main.dart`, `lib/app/bootstrap.dart`, `lib/app/app.dart` | `MaterialApp.router`; `ClKeyboardDismiss` wraps the whole app (`core/widgets/cl_keyboard.dart`). |
| Environment | `lib/app/environment.dart` | Build refuses mixed config (`resolveEnvironment`). |
| Routing | `lib/app/router.dart` (900 lines), `lib/app/navigation.dart`, `lib/app/route_guard.dart` | go_router via `SafeGoRouter`; `StatefulShellRoute.indexedStack` (`router.dart:260`) with 6 branches; feature route groups spread in (`rhythmRoutes()`, `libraryRoutes()`, `todayRoutes()` …). |
| State | Riverpod (`lib/app/providers.dart`, per-feature `*_repository.dart` / providers) | — |
| Shell | `lib/features/home/home_shell.dart` (1,284 lines) | `HomeShell`, `BabyHeader`, `ClTabDock`, `HomeFloatingClearance`. |
| Design core | `lib/core/design/` | `tokens.g.dart` (generated), `cl_theme.dart`, `cl_typography.dart`, `tabular_text.dart`, `motion.dart`, `haptics.dart`, `page_transitions.dart`. |
| Widget core | `lib/core/widgets/` (12 files, ~4,100 lines) | `cl_button`, `cl_rows`, `cl_sheet`, `cl_feedback`, `cl_inputs`, `cl_choices`, `cl_status`, `cl_misc`, `cl_navigation`, `cl_pressable`, `cl_icon`, `cl_art`, `cl_segmented`. |
| Features | `lib/features/<feature>/` (37 folders, ~379 Dart files in `lib/`) | Layout is usually `*_models`, `*_repository`, `*_screen(s)`, `*_sheets`, `*_widgets`. |
| Localisation | `lib/l10n/` | `app_vi.arb` (template), `app_en.arb`, generated `app_localizations*.dart`, `glance_copy.dart` (widget/Live Activity copy). |
| Dev catalogue | `lib/features/showcase/` | Showcase of core widgets (reached from diagnostics). |

### 2.2 Theme pipeline [V]

```
packages/design-tokens/tokens.json ──generate.ts──▶ core/design/tokens.g.dart  (+ dist/tokens.css for web)
                                                   │ ClColors, ClCareColors, ClShadows,
                                                   │ ClSpace, ClRadius, ClTextSpecs, ClMotion
core/design/cl_theme.dart  ── ClTheme (ThemeExtension) ── buildClTheme(palette) ── context.cl
```

- `ClTheme` carries `palette`, `colors`, `care`, `shadows` and `text`. `lerp` blends Light and
  Night care so the switch fades (`cl_theme.dart:46`).
- `buildClTheme` maps tokens onto the Material 3 `ColorScheme` and `TextTheme`. It also sets
  `NoSplash` and platform page transitions (iOS Cupertino; Android predictive back), with a
  fade under Reduce Motion (D-013).
- **Night care is a care mode, not a "dark mode"** (`core/appearance/appearance.dart:58`). It
  turns on in four cases:
  - the user chose "Tối";
  - the "Tự động" setting follows a dark system theme;
  - the time falls inside the 21:00–06:00 schedule;
  - a sleep or feed timer is running.

### 2.3 Navigation [V]

- **Tabs:** `ClTab { today, memories, care, utilities, explore, profile }`
  (`core/widgets/cl_navigation.dart:23`). The tab set depends on role (`tabsForRole`, `:48`) and
  on a flag:
  - NavBar v1 for a parent: Hôm nay · Kỷ niệm · Chăm sóc · Tiện ích.
  - NavBar v2 / Adaptive (`adaptiveNavProvider`, `home_shell.dart:93`, P-178):
    Hôm nay · Kỷ niệm · Khám phá · Hồ sơ.
- **Dock:** `ClTabDock` is the floating pill nav plus a contextual "+" (`ClDockAction`):
  Ghi nhanh on Hôm nay, add photos on Kỷ niệm.
- **Headers:** two mechanisms.
  - `ClPinnedHeaderScaffold` (8 files) gives tab and Me screens an iOS large-title collapse.
  - `ClTopBar` (27 files) serves flows.
- **Pushes:** `context.push` (335) dominates. `withOverlayTwins` / `/o` routes push tab pages
  above the shell (`navigation.dart:118`).
- **Divergence:** 15 files bypass the router with an imperative
  `Navigator.push(MaterialPageRoute/PageRouteBuilder)`. Examples: print_studio,
  `stories/story_editor.dart`, `memories/media_viewer.dart`, `care/growth_standards_screen.dart`,
  `adaptive/today_adaptive.dart:995`, the last of which is named `showGoalsSheet` yet pushes a
  page.

### 2.4 Responsive conventions [V]

- **Phone-first, single column.** The app uses `MediaQuery.paddingOf` / `sizeOf` and
  `LayoutBuilder` (21 files, mostly charts and carousels).
- **No tablet breakpoints or max content width.** `shortestSide >= 600` appears only in analytics
  (`core/platform/device_heartbeat.dart`).
- **No text-scale clamp** anywhere (no `MediaQuery` override in `app/app.dart`). Dynamic Type
  passes through untouched. Core rows are written to wrap at 200 % (`cl_rows.dart:374`).
- **Grids use fixed `crossAxisCount`** of 3, 4 or 5 depending on the screen. No
  `SliverGridDelegateWithMaxCrossAxisExtent` is used.

---

## 3. Design Tokens

### 3.1 Colour [V] — `core/design/tokens.g.dart`

There are 44 semantic colours per palette (`ClColors`), plus 6 care categories with
soft / ink / accent triples (`ClCareColors`).

| Group | Light values | Role |
|---|---|---|
| Backgrounds | `cloud` #F6FCFB, `surface` #FFF, `surface2` #EEF6F5, `separator`, `controlBorder` | Mint-tinted neutrals; never pure grey. |
| Text | `ink` #173D44 (deep teal), `inkMuted` #55707A | Brand ink instead of black. |
| Brand | `mint` #2CBFB3, `mintDeep` #087F7B (primary fill), `mintText` #06716D, `mintSoft` | The primary action colour is `mintDeep`; `mint` is decorative. |
| Warm | `sunshine` #FFD166 / `sunshineSoft`, `peach` #FFA58D / `peachSoft`, `onWarm` | Attention and memories. |
| Illustration cards | `cardMint`, `cardNight`, `cardPeach`, `cardSun`, `onCard` | Hero cards. |
| Navigation | `navBar` (= ink), `navIcon`, `navActive`, `onNavActive` | Dark floating dock in Light mode too. |
| Status | `error` / `errorSoft`, `danger` / `dangerSoft` / `onDanger`, `live` / `onLive`, `pending` | `error` = failure; `danger` = real-world danger (first aid). |
| Care | `bottle` blue, `breast` pink, `sleep` indigo, `diaper` green, `growth` orange, `pump` violet | Category colour coding across logging, charts and history. |

Contrast check on Light tokens [V, computed]. All main text pairs pass WCAG AA:

| Pair | Ratio |
|---|---|
| `inkMuted` on `surface` | 5.27 |
| `inkMuted` on `surface2` | 4.80 |
| `mintText` on `surface` | 5.85 |
| white on `mintDeep` | 4.85 |
| `ink` on `sunshineSoft` | 10.7 |
| `error` on `errorSoft` | 6.17 |

Three pairs need care:

- `mint` with white text gives 2.28. `mint` must stay decorative.
- `controlBorder` on surface gives 3.16. That is acceptable for a non-text boundary.
- In Night care, `onWarm` stays dark ink (#173D44) while `sunshineSoft` / `peachSoft` become dark
  (#3A3115 / #3A2620). Text on soft warm fills must therefore use `ink`, not `onWarm`. This is a
  known trap, and nothing in the token naming prevents it.

**Off-token colour [V].**

| Usage | Count |
|---|---|
| `Color(0x…)` | 144–158 in 25 files |
| `Colors.white` | 126–144 |
| `Colors.black` | 27–46 |
| `Colors.*` in total | ~218 in 38 files |

These concentrate in four places:

- `premium/premium_style.dart` (`PremiumPalette`): a deliberate, documented dark-and-gold palette.
- `premium/paywall_v2.dart`
- `assistant/lumi_button.dart` (`LumiColors`)
- the photo surfaces: media viewer, memory tiles, print_studio.

Raw `Colors.white` / `black` on photo overlays is often legitimate. On regular surfaces it is not
Night-care-aware [A].

### 3.2 Radius [V]

`ClRadius`: `sm` 8, `control` 12, `card` 24, `tile` 28, `sheet` 32, `hero` 36, `pill` 999.

| Usage | Count |
|---|---|
| `circular(ClRadius.*)` | 283 |
| — of which arithmetic on tokens (`card - 6` ×19, `control + 4` ×17, `card - 4`, `card - 8`) | ~43 |
| `circular(<literal>)` in 102 files | 398 |

Top literals: 14 (72), 16 (67), 12 (50), 20 (40), 18 (26) and 10 (26). Only 12 matches a token.
Two conclusions follow:

- The *de facto* scale in use is 12 / 14 / 16 / 20 / 24, while the token scale offers
  12 / 24 / 28.
- The core itself is inconsistent: `ClSkeleton` defaults to radius 14 and `ClTileShadow` to 12.

### 3.3 Elevation [V]

`ClShadows` has `card`, `chip`, `sheet`, `nav`, `lift` and `tile`. In Light mode they are
two-layer, ink-tinted soft shadows. In Night care, `card` is empty (flat surfaces) and the others
are black.

Feature kits apply `shadows.card` by hand inside `BoxDecoration`: 850 `BoxDecoration(` calls in
146 files. Rules for when a card is flat, outlined or shadowed are reinvented per kit (e.g.
`RhCard` has `outline` / `hairline` / `color` flags; `NuCard` has `flat`).

### 3.4 Motion and haptics [V]

- **`ClMotion`** defines `instant` 100 ms, `quick` 200, `standard` 350 (spring 0.35 / 0.86),
  `exit` 250 and `gentle` 600, plus stagger of 30 ms × max 6, scrim 0.32 and disabled opacity
  0.4.
- **Reduce Motion** is honoured via `context.motion()` and `context.reduceMotion`
  (`core/design/motion.dart`).
- **Haptics are deliberately sparse** (`core/design/haptics.dart`): tab switch and
  success-with-toast only, success only in Night care (owner, 2026-10-11).

### 3.5 Tokens that do not exist [V]

There are no tokens for:

- icon size;
- spacing of 2 / 6 / 10 / 14 / 20 (see §4.2);
- a type size between `label` (14) and `body` (16);
- a bold weight;
- a content max-width;
- a grid tile size;
- an overlay or scrim on photos.

---

## 4. Typography & Spacing

### 4.1 Type scale [V] — `ClTextSpecs`, `core/design/cl_typography.dart`

Font: **Be Vietnam Pro** throughout. Playfair Display is shipped for keepsakes and Premium
headlines (`PremiumPalette.serif`).

| Token | Size / line height | Weight | Typical use |
|---|---|---|---|
| `display` | 34/40 | 600 | Hero numbers / welcome |
| `largeTitle` | 32/40 | 600 | Tab large titles |
| `title` | 30/36 | 600 | Screen titles |
| `title2` | 24/32 | 600 | Sheet titles (`ClSheetHeader`) |
| `headline` | 18/26 | 500 | Section headers (`ClSectionHeader`) |
| `body` | 16/24 | 400 | Body |
| `bodyStrong` | 17/24 | 500 | Row titles, button labels |
| `label` | 14/20 | 500 | Secondary text, links |
| `caption` | 12/16 | 500, +0.2 tracking | Meta |
| `numeralXl` | 52/56 | 500, tabular | Amount entry, timers |
| `numeral` | 28/34 | 500, tabular | Stat values |

- Be Vietnam Pro has no `tnum` feature, so `ClTabularText` lays each digit in a fixed box
  (`core/design/tabular_text.dart`, P-064). It is used in 14 files.
- `cl.text.*` is read about 1,990 times in 160 files. It is the norm.

**Drift [V].**

| Override | Count |
|---|---|
| `fontSize: <literal>` in 89–94 files | 593 |
| — of which 15 / 13 / 12 / 14 / 11 / 10 / 9 / 12.5 | 133 / 99 / 62 / 56 / 52 / 20 / 11 / 10 |
| `FontWeight.w600` | 421 |
| `FontWeight.w700` | 213 |
| raw `TextStyle(` in 16 files | 82 |

Two conclusions follow:

- Designers and implementers clearly need a ~15 pt "row title" and a ~13 pt "meta" style that
  the scale does not offer. `spRowTitle` in `spending/spending_widgets.dart` (15/20 w600) is one
  such re-invention.
- The token weights are 400 / 500 / 600 only, yet **w700 appears 213 times**.

Two further oddities:

- `bodyStrong` (17) is larger than `body` (16), so "strong" also means "bigger".
- 9–11 pt text (~83 uses) is below a comfortable minimum for tired parents [A: accessibility
  impact depends on where it is used].

### 4.2 Spacing [V]

`ClSpace`: `s1` 4, `s2` 8, `s3` 12, `s4` 16, `s6` 24, `s8` 32. There is also `tapMin` 44,
`buttonHeight` 56 and `nextButton` 64.

| Usage | With `ClSpace` | With literals |
|---|---|---|
| `SizedBox` gaps | 2,044 | 813 |
| `EdgeInsets` | 449 | 481 |

Top literal gaps: 6 (169), 4 (145, which duplicates `s1`), 8 (103), 2 (94), 10 (89), 12 (84) and
14 (45).

- The scale has no 2, 6, 10, 14 or 20. Those values are used anyway, as literals.
- Card internal padding varies: 16 (`NuCard`, `RhCard`, `SpCard`), 16×14 (`LbCard`), 14
  (`PrintCard`, care-hub `_Tile`) and 12 (`SpBanner`).
- Gaps between Today sections switch between s2, s3, s4 and s6 inside `sectionParts`
  (`today/today_screen.dart:113-243`).

### 4.3 Layout conventions [V]

- Screen gutter is s4 (16). A card group is a surface with `ClRadius.card` and hairline separators
  (`ClCardGroup`).
- One primary button per screen, placed in the thumb zone (doc comment on `ClButton`,
  `cl_button.dart:19`).
- Hit area is ≥ 44 pt by default via `ClPressable.minSize` (`cl_pressable.dart:22`).
- Tab content gets bottom clearance from `HomeFloatingClearance` (`home_shell.dart:1126`).

---

## 5. Component Inventory

### 5.1 Core kit (`lib/core/widgets`) — usage across `features/` + `app/` [V]

| Component | File | Refs / files | Notes |
|---|---|---|---|
| `ClButton` (primary, secondary, tinted, plain, outline, destructive, apple; `loading`, `expand`) | `cl_button.dart:20` | 479 / 109 | Pill; 1–2 word verb; busy state keeps label. |
| `ClRoundButton` (64), `ClBackButton` (44) | `cl_button.dart:119,149` | 3 / 3, 10 / 7 | Under-used; ≥6 feature "round icon" copies exist. |
| `ClPressable` | `cl_pressable.dart:14` | 493 / 113 | Shared press feedback, 44 pt min, disabled 40 %. The real foundation. |
| `ClIcon` + `ClIcons` (~62 line icons, SVG, `srcIn` tint) | `cl_icon.dart` | 620 / 134 | Material `Icons.*` only 21 uses (print_studio, keepsake editor, diagnostics, play glyphs). |
| `ClArt` / `ClIllustration`, `ClLogo` | `cl_art.dart` | 21 / 11 | Fixed-colour Figma illustrations. |
| `ClCardGroup` | `cl_rows.dart:11` | 124 / 44 | Only shared "card"; rows with separators. |
| `ClSectionHeader` | `cl_rows.dart:62` | 31 / 18 | Headline + mint link. Most screens hand-roll headers instead (127 `header: true` in 73 files). |
| `ClListRow`, `ClDetailRow`, `ClInfoRow`, `ClOptionRow`, `ClRadio` | `cl_rows.dart` | 19, 27, 2, 35 refs | `MeRow` (feature) is used more than all of these. |
| `ClTileShadow` | `cl_rows.dart:408` | 6 / 2 | Picture tiles (D-096). |
| `showClSheet` / `ClSheetRoute` / `ClSheetHeader` | `cl_sheet.dart` | 182 / 74, 168 / 70 | Strongest pattern in the app. |
| `showClToast`, `ClToaster`, `dismissClToasts` | `cl_feedback.dart` | 278 / 99 | Toast with optional action (undo); survives the closing sheet. |
| `withClProgress` | `cl_feedback.dart:87` | 33 / 16 | Full-screen blocking spinner for row/sheet-initiated server calls; silent below 150 ms. |
| `ClSkeleton` | `cl_feedback.dart:330` | 32 / 15 | Content-shaped shimmer; static in Night care / Reduce Motion. |
| `ClEmptyState` | `cl_misc.dart:12` | 23 / 13 | Icon, headline, one sentence, one Tinted action. |
| `ClErrorBanner` | `cl_status.dart:109` | **1 / 1 (showcase only)** | Not used in product. |
| `ClChip`, `ClSyncStatus`, `ClFloatChip`, `ClAvatar` | `cl_status.dart` | 6, 8, 16, 4 | Low adoption; features build their own chips. |
| `ClTextField`, `ClInputGroup`, `ClToggle`, `ClSettingRow`, `ClCodeInput`, `ClAmountField`, `ClTimeRow` | `cl_inputs.dart` | 55 / 33; `ClAmountField` 3 / 1; `ClTimeRow` 7 / 5 | 23 raw `TextField(` remain. |
| `ClSegmented` | `cl_segmented.dart` | 28 / 23 | 2–3 options; caller persists the choice. |
| `ClFilterChip`, `ClRelationChip`, `ClDayPill`, `ClChoiceTile`, `ClSelectTile`, `ClPermissionTile`, `ClRoleOption`, `ClEntryOption` | `cl_choices.dart` | `ClFilterChip` 20 / 14; tiles 2–4 each | Private `_FilterChip` / `_FilterPill` copies exist in milestones and memories. |
| `ClNavBar`, `ClTabDock`, `ClQuickLogButton`, `ClNavHeader`, `ClTopBar`, `ClProgress`, `ClPageDots`, `ClBabySwitcher`, `ClPinnedHeaderScaffold`, `ClHiddenTabFreeze` | `cl_navigation.dart` | `ClTopBar` 53 / 27; `ClNavHeader` 2 / 2; `ClPinnedHeaderScaffold` 8 / 8 | 88 raw `Scaffold(` calls. |
| `ClEmptyState`, `ClCoachmark`, `ClTourTip`, `ClMemberRow`, `ClAccountRow`, `ClThemeOption` | `cl_misc.dart` | — | — |

### 5.2 Feature-level shared widgets acting as a shadow design system [V]

Used outside their own feature:

| Widget | File | Used by |
|---|---|---|
| `SavedBabyAvatar` | `features/baby/baby_avatar_view.dart` | 11 features |
| `OnboardingScaffold`, `ScreenHeading` | `features/onboarding/widgets/onboarding_layout.dart` | 11 / 6 features |
| **`MeRow`**, `MePage`, `MeSection`, **`MeNotice`** (info / warn / error) | `features/me/me_widgets.dart` | `MeRow` 106 uses in 10 features |
| `BabyHeader` | `features/home/home_shell.dart:327` | 8 features |
| `MediaTile` | `features/memories/memory_widgets.dart:156` | 7–10 files |
| `CareSheetFrame` | `features/care/care_sheets.dart:266` | care, solids |
| `ClRedDot` | `features/family/my_invites.dart` | A `Cl`-prefixed widget living in a feature folder |

### 5.3 Per-feature kits that duplicate each other [V]

| Concept | Core equivalent | Feature re-implementations |
|---|---|---|
| **Page frame** | `ClPinnedHeaderScaffold` / `ClTopBar` | `MePage`, `LbPage`, `MtPage`, `NuPage`, `SdPage`, `SpPage`, `AutoSavePage`, `OnboardingScaffold`; private `_TopBar` in reminders, rhythm week, paywall_v2, stories share |
| **Card** | — (none) | `AxCard` 20, `RhCard` 20 (50 uses), `NuCard` 20, `SpCard` 20, `LbCard` 20, `PrintCard` 20 (33 uses), `AsCard` 18 (25 uses), `MtGroupCard` 16, care-hub `_Tile` 20, `_CardRow` 20, stats `_Card` 24; 43 private `_*Card` classes in 28 files |
| **List group** | `ClCardGroup` (24) | `NuGroup` 16, `SpGroup` 16 (no hairlines), `LbGroup` 16, `FaGroup`, `MtGroupCard` 16 |
| **Notice / banner** | `ClErrorBanner` (unused) | `MeNotice` 18, `NuBanner` 16, `SpBanner` 14, `VxBanner` 14, `PrintNotice` 14, `RhInfoBox` 14, `LbOfflineBanner` 14, `FaCalloutBox` 20, `AsOfflineBanner`, `AsNoticeCard`, `RhSavedBanner`, `KeepsakeReadyBanner`, `WhatsNewBanner`, `AutoSaveTodayBanner`, `ResumedBanner`, `_SyncBanner` |
| **Section heading** | `ClSectionHeader` | `MeSection`, `LbSection`, `MtSection`, `NuSection`, `NuCardHeader`, `RhCardHeading`, `ForBabyHeader`, `_SectionTitle`, `_SectionHeader`, `_Label` ×3 |
| **Round icon button** | `ClRoundButton` | `AsRoundButton`, `FaRoundButton`, `LbRoundButton`, `MtRoundIcon`, `RhRoundIcon`, `SpRoundIcon`, `KeepsakeRoundIcon`, `_RoundIcon` (paywall) |
| **Tinted icon chip** | — | `QuickActionIcon`, `AxCard` chip, `MtGroupIcon`, `NuIconChip`, `RhIconTile`, `CategoryBadge`, care-hub `_Tile` |
| **Pill / chip / tag** | `ClChip`, `ClFilterChip` | `AsChip`, `LbChip`, `MtChip`, `MtBadge`, `NuTag`, `RhChip`, `RhPill`, `SdPill`, `SdTag`, `SdFoodChip`, `SpPill`, `SpChoiceChip`, `FaTag`, `PrintPill`, `MilestoneChip`, `StoryMilestoneChip`, `AutoSaveTag` |
| **Pill button** | `ClButton` | `AsButton`, `LbPillButton`, `RhPillButton`, `PremiumGoldButton`, `PremiumTextButton`, `SpBottomButton`; 30 Material `*Button` uses (print_studio, diagnostics) |
| **Footnote** | — | `AsFootnote`, `NuFootnote`, `SdFootnote`, `MtContentNote`, `RhNote` |
| **Empty state** | `ClEmptyState` | `LbEmpty`, `NuEmpty`, `_EmptyState` (assistant), `_EmptyDay` (history) |
| **Amount input** | `ClAmountField` | `AmountInput` (care), `SpAmountInput`, `AsAmountAsk` |
| **Date / time wheel sheet** | `ClTimeRow` (thin) | `CupertinoDatePicker` / `CupertinoPicker` sheets in 17 files, 13 private `CupertinoTextThemeData` copies, `_Wheel` ×2, `_ClockWheel` |
| **Drag handle** | inside `ClSheetHeader` | `DragHandle` (`today/today_layout.dart:666`), `_Handle` (`spending/spending_categories.dart:219`) |

---

## 6. UI Pattern Inventory

Each pattern is described from what the code shows; divergences are listed after.

### 6.1 Dashboard sections — Today [V]

**What exists**

- `today/today_screen.dart:53` `TodayScreen` uses `ClPinnedHeaderScaffold` with
  `BabyHeader(actions: [NotificationBell, NightCareToggle])` above a `ListView` of sections built
  by `sectionParts`.
- There are two orderings:
  - **Legacy:** `TodayLayout.defaultOrder` (`today/today_layout.dart:62`) gives tiles, forYou,
    solids, reminders, quickActions, vaccine, spending, rhythm. It is user-customisable through
    `showTodayCustomizeSheet`.
  - **Adaptive** (flag): `rankToday` (`adaptive/adaptive_engine.dart:405`) ranks `WidgetId`s and
    renders `AxCard`s from `adaptive/today_adaptive.dart:138`. The ids add recentMemories,
    momentToday, growth, familyView and careDuty.

**Divergences**

- Section titles use `ClSectionHeader` in some sections, while `AxCard` puts its title and link
  *inside* the card.
- `AxCard` uses radius 20, padding 14 and title fontSize 16 (21 font-size literals in the file).
- The gap between sections varies per section.
- Two Today implementations coexist behind a flag [V]. Which one owners treat as the target is an
  **[A]**; the commit history suggests adaptive.

### 6.2 Summary cards and stat tiles [V]

**What exists**

- Stats: `care/stats_screens.dart:261` `_Card` (token-correct).
- History: `care/history_screen.dart:531` `_SummaryCard` and `:734` `_StatCard`.
- Baby profile: `me/baby_profile_screens.dart:426` `_StatCard` (radius 18).
- Spending: `spending/spending_screens.dart:439` `_TotalCard` (radius 14).
- Charts: all custom `CustomPainter`s (~30, no chart package). `StackedDaysChart` is reused 5× and
  `WhoGrowthChart` 2×.

**Divergences**

- There is **no shared stat tile**, even though the senior-ui-ux skill prescribes "big tabular
  number + short label + unit".
- `numeral` / `numeralXl` and `ClTabularText` exist but are wired per screen.

### 6.3 Action cards, quick actions and CTAs [V]

**What exists**

- `ClButton` is the norm.
- Quick actions: `TodayQuickActions` + `QuickActionIcon` (`today/today_cards.dart:30`,
  `today_layout.dart:708`).
- Quick log: `showQuickLog` / `_QuickTile` (`care/care_sheets.dart:148,217`), plus the dock "+"
  (`ClQuickLogButton`).
- Lumi entry: `AssistantTodayCard` (`assistant/assistant_entry.dart:46`) and `LumiButton`
  (own palette).
- AI nudges: `AiMomentNudge` and `AiStateCard` (`ai/ai_widgets.dart`).
- Premium upsell: `PremiumInlineCard` (`premium/premium_style.dart`).

**Divergences**

- The tinted-icon-in-rounded-square motif is rebuilt about 7 times with radius 12, `size*0.32`
  and others.
- The round icon button is rebuilt about 8 times.

### 6.4 Tracking interfaces [V]

**What exists**

- `openCareLog` (`care/care_sheets.dart:75`) opens `FeedSheet`, `PumpSheet` or `DiaperSheet`.
  All three are framed by `CareSheetFrame` (`:266`: `ClSheetHeader` + scroll + primary button).
- `solids/solids_sheet.dart` reuses `CareSheetFrame`. This is good cross-feature reuse.
- Timers: `care/timer_screens.dart` (`TimerScreen`, `SleepRing` painter, `ManualSleepScreen`).
- Night care auto-activates while a timer runs.
- Care category colours (`ClCareColors`) code each care type consistently in sheets, history and
  charts.
- The Lumi assistant (`assistant/*`, 2,379-line `assistant_widgets.dart`) is a conversational
  logging surface with its own kit: `AsCard`, `AsButton`, `AsChip`, `AsComposer`,
  `AsDraftCard`, `AsSummaryCard`.

**Divergences**

- 4 amount-input variants.
- 17 date/time picker sheets.
- 23 raw `TextField`s.
- `FieldLabel` (`care_sheets.dart:532`) and `_ErrorText` (`:546`) are local.

### 6.5 Memories and photo galleries [V]

**What exists**

- `MediaTile` (`memories/memory_widgets.dart:156`) is reused across memories, albums, keepsakes,
  auto_save, storage, milestones and adaptive.
- Full-screen viewer: `memories/media_viewer.dart:44`.
- `ClTileShadow` lifts picture tiles (D-096).
- Social layer: `LoveButton`, `FavoriteButton`, `LovesLine`, `MessageTile`
  (`memories/social_widgets.dart`).
- Upload state: `UploadPill` and `ClSyncStatus`.

**Divergences**

- Grid columns are fixed at 3, 4 or 5 depending on the screen.
- At least 5 other thumbnail widgets exist (`_Thumbs`, `SdPhotoTile`, `LibraryTile`,
  `_ShotTile`, vaccine photos).
- Upload tiles use raw `CircularProgressIndicator` with `Colors.white`.
- Keepsakes and print_studio use their own serif and Material dialogs.

### 6.6 Development insights [V]

**What exists**

- Milestones: `milestones/milestone_screens.dart` with the `Mt*` kit.
- Explore: `adaptive/explore_screen.dart`.
- Stories: `stories/stories_view.dart` (`StoryCard`).
- Growth: `care/growth_chart.dart` (`WhoGrowthChart`) and `care/growth_standards_screen.dart`.
- Handover / AI summary: `ai/handover_screen.dart` and `handover_now.dart`.
- Rhythm insights: the `rhythm/*` kit `Rh*` (largest feature kit: 21 widgets, `RhCard` 50 uses).

**Divergences**

- `_FilterChip` (milestones) duplicates `ClFilterChip`.
- `CupertinoActivityIndicator` loading in ai and rhythm vs `ClSkeleton` elsewhere.

### 6.7 Forms and input screens [V]

**What exists**

- Onboarding: `OnboardingScaffold` / `ScreenHeading` with `ClTopBar`, `ClProgress` and
  `ClPageDots`. `onboarding/setup_screens.dart` has 0 literal radii and 0 font sizes, which makes
  it the cleanest feature.
- Family invites, baby profile and reminders use core inputs and `ClCardGroup`.
- No `Form` widget is used; validation is manual per screen. Inline errors use local widgets
  (`_ErrorText`) [V], and their consistency is **[A]**.

### 6.8 Bottom sheets [V]

**What exists**

- `showClSheet` (182 uses) + `ClSheetHeader` (grabber, 24/32 title, 44 pt "Đóng"). It handles
  springs, drag-to-dismiss at 30 %, Night care (no bounce) and Reduce Motion (fade), and closes
  toasts when opening.
- Confirmations are sheets rather than dialogs.

**Divergences**

- 9 `showModalBottomSheet` (premium, family plan, rhythm personalisation, keepsake editor,
  print), each styled differently.
- 6 Material `showDialog` / `AlertDialog` (print_studio, keepsakes).

### 6.9 Notifications [V]

**What exists**

- In-app inbox: `notifications/inbox_screen.dart` (`InboxScreen`, `InboxRow` with `Dismissible`,
  `ClSkeleton` loading, `ClEmptyState`).
- `NotificationBell` in `BabyHeader`.
- Settings: `notification_settings_screen.dart`.
- Foreground push becomes a toast or a direct open (`memories/push_registration.dart:117`); there
  is no in-app banner component.
- Toasts (`showClToast`) are the universal transient feedback. There is one stray `SnackBar` in
  `first_aid/first_aid_modes.dart:121`.

**Divergences**

- Persistent in-page notices are fragmented into about 16 banner widgets (§5.3), with radii from
  14 to 20, paddings from 12 to 16 and three or four tone vocabularies:
  - `MeTone` info / warn / error;
  - `RhInfoTone` neutral / mint;
  - `AsTone` surface / quiet / warn / errorEdge / danger;
  - plus ad-hoc ones.

### 6.10 Premium and paywall [V]

**What exists**

- `premium/paywall_screen.dart` delegates to `PaywallV2View` (`paywall_v2.dart`). The legacy
  private widgets (`_BenefitCard`, `_PlanTile`, `_FreeBox`) still exist in the file.
- `premium/premium_style.dart` is an explicit, documented separate visual language: always dark
  with gold and a Playfair serif, in both Light and Night care (Figma 958:13863). Its components
  are `PremiumCrest`, `PremiumGoldButton`, `PremiumTextButton`, `PremiumSuggestionSheet` and
  `PremiumInlineCard`.
- Plan cards: `_PlanCard` is duplicated in `family_plan_v2.dart:318` and `plan_screen.dart:212`.
- Gates: `premium/premium_gate.dart`.
- Quota UI: `VideoQuotaCard`, `PremiumExpiredStrip`, `ResumedBanner`
  (`premium/premium_widgets.dart`).

**Divergences**

- `paywall_v2.dart` is the most token-free file in the app: 38 `Color(0x`, 42 font sizes, 38
  `TextStyle(`.
- The intent (a dark premium world) is documented [V]. Whether it should be tokenised as a third
  palette is a design decision, not a bug [A].

### 6.11 Loading, empty and error states [V]

**What exists**

- Loading: `ClSkeleton` in 15 files; the `ClButton.loading` busy state; `withClProgress` for
  blocking server calls.
- Empty: `ClEmptyState` in 13 files.

**Divergences**

- **Loading and errors are mostly implicit.** Async values are read as `ref.watch(x).value ?? …`
  264 times in 109 files, against only 7 `.when(` calls, 16 `hasError` and 41 `isLoading`.
  - Most screens render defaults or an empty layout while loading and do not surface a fetch
    error [V for the code shape]. How visible this is depends on cache warmth [A].
- Spinners instead of skeletons in about 20 places: 31 `CircularProgressIndicator`, 13 raw
  `LinearProgressIndicator`, 7 `CupertinoActivityIndicator`.
- `ClErrorBanner` is never used in product.
- Empty-state copies: `LbEmpty`, `NuEmpty`, `_EmptyState`, `_EmptyDay`.

---

## 7. UX Writing Observations

Source: `lib/l10n/app_vi.arb` (template), `app_en.arb`, `glance_copy.dart`. Counts come from a
script over the catalogs [V]; matching is case-insensitive and word-bounded, so a few counts
include unrelated uses.

### 7.1 Structure [V]

- **Size and parity.** 6,097 keys, with full vi/en parity. vi has an `@` description for 5,957 of
  them; 416 cite Figma nodes and 1,041 cite D-/Q- ids. `required-resource-attributes: true`
  (`l10n.yaml`).
- **Key prefixes are short and often opaque.** `as` 559, `rh` 478, `pv` 424, `sd` 339, `ps` 288,
  `sp` 243, `ks` 229, `vx` 153, `pm` 151, `ax` 131. Older features use readable prefixes
  (`today*`, `reminder*`, `invite*`).
- **ICU usage.** Plurals: 60 in vi, 237 in en. **No `select`**, so nothing varies by role or
  gender.
- **Placeholders.** `{count}` 297, `{name}` 245, `{date}` 130, `{n}` 113, `{time}` 90,
  `{who}` 44, `{baby}` 34.
- **`{name}` is ambiguous.** It means the baby (`dobAgeHint`), a family member
  (`memberRecordsKept`) or the user (`axHello`). 218 of the 245 descriptions do not say which.
- **Hardcoded copy is near zero.** Exceptions:
  - "Tiếng Việt" / "English" literals in keepsakes;
  - bilingual vaccine data in generated `vaccines/vaccine_schedule.g.dart`;
  - city labels in `baby/time_zones.dart`;
  - one date pattern `"d 'tháng' M"` in `care/history_screen.dart:2525`.
- **Widget copy uses literal placeholders.** `glance_copy.dart` passes `'{x}'` text for Swift to
  fill, so English plurals cannot apply there.

### 7.2 Common terminology [V]

- **The child.** "bé" (275) is the default; "con" (~120) appears mostly in milestone cheers
  ("Con biết bò rồi!"). Personalisation by name via `{name}` / `{baby}` is less common than
  generic "bé".
- **The user.** "bạn" (383) is the address. "nhà mình" (43) is the warm collective form.
  "ba mẹ" (55) dominates over "cha mẹ" (7, all spending) and "bố mẹ" (2).
- **Roles.**
  - "Cùng nuôi", "Người chăm sóc" and "Người thân" are the canonical names.
  - The caregiver also appears as "Người chăm" (12) and "người cùng chăm" (5).
  - en "Caregiver" maps to two vi forms.
- **Features.**
  - "Hôm nay" (150) and "Kỷ niệm" (151).
  - "Nhịp" (53) is both a product name and a common noun.
  - The assistant is "Lumi" (28), "trợ lý" (14) or "AI" (63).

### 7.3 CTA conventions [V]

- **Form.** Verb-first, 1–3 words (the `ClButton` doc says 1–2). The convention holds in most
  places [A: by sampling].
- **Same intent, many strings:**

  | Intent | vi | en |
  |---|---|---|
  | Done / save | "Xong" 10, "Lưu" 7, "Đã xong" 3, "Lưu thay đổi" 2, "Lưu lại" 1, "Ghi" 1 | Done 12, Save 8, Got it 2, Okay 1 |
  | Retry | "Thử lại" 8, "Thử lại lần nữa" 3 | Try again 7, Retry 1 |
  | Continue | "Tiếp tục" 8, "Tiếp" 4 | Continue 7, Next 5 |
  | Dismiss | "Để sau" 10, "Bỏ qua" 5, "Huỷ" 5, "Đóng" 4 | Later 9, Not now 1 |
  | Delete | "Xoá" 8, "Gỡ" 1, "Bỏ" 1 | Delete 7, Remove 2 |

- **Shared actions are re-declared per feature.** `actionDone` exists, yet "Xong" is in
  `glanceDone`, `customizeDone`, `fbDone`, `rhDone`, `pmDone` …; "Hoàn tác" has 7 keys and "Sửa"
  has 6.
- **Translation drift between duplicates.** "Chọn" has four en renderings (Choose / Pick /
  Select / Tick); "Tiếp tục" is Continue or Resume.

### 7.4 Titles, subtitles and length [V]

| Key kind | n | median words | p90 | max |
|---|---|---|---|---|
| Title | 479 | 4 | 8 | 22 |
| Subtitle | 115 | 7 | 12 | 29 |
| Body | 251 | 15 | 25 | 39 |
| Hint | 211 | 7 | 13 | 27 |
| Note | 82 | 13 | 30 | 39 |
| Empty | 80 | 8 | 16 | 20 |
| Error | 103 | 8 | 15 | 27 |

- **Titles.** 67 are questions and 20 end with "." (some are full sentences, e.g. `sdS1Title`,
  22 words).
- **en casing.** Sentence case almost everywhere; 6 Title-Case outliers ("Add to Memories",
  "Customise Today").
- **Length.** Median 18 characters per vi string, p90 55, max 241 (`stFullBody`).
  - 507 strings have two or more sentences; 30 have three or more.
  - The longest cluster in auto_save, assistant, premium and print (`autoSaveIntroFootnote`,
    `asVoiceIntroServerIos`, `aiConsentIntro`, `meSignOutPending`, `pmRenewTerms`).
- **Progress copy.** "Đang …" starts 126 strings; "…" is the ellipsis everywhere (never "...").

### 7.5 Personalisation [V]

- Names: `{name}` / `{baby}`. Age: `{age}` (22 strings, e.g. `msSuggest` "Gợi ý cho bé {age}").
  Relation: `{relation}` (22). Logger: `{who}` (`careLoggedBy` "{who} ghi").
- en is gender-neutral (they / their). vi only shows gender in pickers.
- Greetings use emoji (`axHello` 👋, `axGreetMorning` ☀️) [V]. Personalisation stops at
  substitution; there are no role-aware variants (no ICU `select`).

### 7.6 Inconsistent naming [V]

| Concept | vi variants (count) | en variants |
|---|---|---|
| A care entry | ghi nhận 88 · nhật ký 65 · ghi chép 25 · ghi nhanh 25 · bản ghi 19 · ghi lại 12 | log 130 · item 98 · record 39 · entry 8 |
| Memories | kỷ niệm 151 · album 50 · câu chuyện 30 · khoảnh khắc 19 | Memories · Memory · Moments |
| Reminders | nhắc việc 56 · nhắc nhở 9 (`remindersTitle` = "Nhắc nhở", list uses "nhắc việc") | — |
| Family | gia đình 112 · nhà 116 · hộ / chủ hộ 30 / 9 | family 211 · household 27 |
| Link | link 25 · liên kết 13 | — |

- **vi spelling variants:** "Xoá" 144 / "Xóa" 3; "Huỷ" 40 / "Hủy" 2; "tuỳ" 10 / "tùy" 6.
- **en spelling mix:** Customise / Customize, colour / color; "Sign in" / "Sign-in" / "sign-in".
- **Duplicate values:**
  - 439 vi values are shared by more than one key (802 redundant keys); "Hôm nay" ×13,
    "Tất cả" ×11, "Xong" ×10.
  - 183 shared vi values have different en translations.
  - Shared en values also map to different vi: "Back" is "Quay lại" or "Mặt sau"; "Diaper" is
    "Tã", "Loại tã" or "Thay tã".

### 7.7 Repetitive or over-explanatory text [V counts, A judgement]

- **System words in user copy:** "xác nhận" 37, "dữ liệu" 29, "tải lên" 27, "bản ghi" 19,
  "đồng bộ" 19, "máy chủ" 7, "thiết bị" 7, "cấu hình" 4.
  - Main-surface examples: `offlineBanner` "Đang offline · {count} bản ghi chờ đồng bộ";
    `carePending` "Chờ đồng bộ".
  - "đối soát" and "quan sát" (flagged by the senior-ui-ux skill) are already gone.
- **Mechanism-explaining copy:** permissions, on-device processing and storage policy
  (`autoSaveKeptHereBody`, `asVoiceIntroServer*`, `detailFooter`, `pendingFootnote`).
  - Some of this is legally or trust-required (AI consent, privacy) [A].
  - Much of it could sit behind a "Tìm hiểu thêm" tap [A].
- **Tone markers:** "nhé" 59, "rồi" 57, "cùng" 74; exclamation marks 24 (almost all in keepsake
  celebrations); emoji 9. The tone is calm everywhere except celebrations. That is a strength.

---

## 8. Existing Strengths (preserve)

1. **Single token source across platforms.** `tokens.json` generates both Dart and CSS, with
   Figma node ids in the generated comments. Night care is a full second palette with `lerp`
   transitions, not an inverted afterthought.
2. **Warm, distinctive palette.** Teal ink instead of black, mint-tinted neutrals, sunshine and
   peach for warmth, and per-care-category colour triples (`ClCareColors`) that make bottle,
   sleep and diaper scannable at a glance. This is the base for MB-Bank-like scanability.
3. **`ClPressable` + `ClButton` + `showClSheet` + `ClToaster`.** A coherent, well-adopted
   interaction core:
   - consistent press feedback and 44 pt minimum;
   - one primary per screen;
   - sheets for every confirmation;
   - an undo-capable toast that survives the sheet closing;
   - Reduce Motion and Night care handled centrally.
4. **Night care as a product concept.** It auto-activates during night timers. Haptics are muted
   at night (only the success haptic plays). Skeletons go static and shadows go flat. It is
   family-centred and specific to the job of caring at 3 a.m.
5. **Steady numerals.** `ClTabularText` with the `numeral` / `numeralXl` tokens is the right
   foundation for "numbers as visuals" stat tiles and timers.
6. **`ClCardGroup` + row family** (`ClDetailRow`, `ClOptionRow`, `MeRow`). Grouped rows with
   hairlines are the closest thing to MB Bank's dense, scannable list. Core rows already wrap at
   200 % text.
7. **`CareSheetFrame` and `MediaTile`.** Proven cross-feature reuse; templates for how
   consolidation should look.
8. **Copy discipline.**
   - Every string is in ARB with descriptions, Figma ids and decision ids.
   - Full vi/en parity.
   - A gender-neutral en.
   - A warm peer tone ("bạn", "nhà mình", "nhé").
   - Calm, no-guilt empty states (`ClEmptyState` doc: "Calm, no-guilt").
   - Celebration reserved for milestones.
9. **Role-aware navigation.** Tabs and quick-log visibility per role (`tabsForRole`,
   `ClRole`). `ClBabySwitcher` in a consistent header makes the child always present.
10. **Golden coverage.** About 1,786 goldens across Light/Night × vi/en make visual regressions
    detectable. Any consolidation can be verified image by image.
11. **Documented intent.** Widget doc comments cite Figma nodes, decisions (D-0xx) and owner
    feedback with dates, so the *why* of each choice is recoverable.

---

## 9. Design System Gaps

### 9.1 Missing reusable components [V]

| Missing core component | Evidence of need |
|---|---|
| `ClCard` (surface / tinted / outlined / flat variants, standard padding, optional tap) | 11 named card bases + 43 private `_*Card` classes; radii 14–24 |
| `ClNotice` (info / warn / error / offline / success tones; title, body, optional action) | About 16 banner widgets; `ClErrorBanner` unused; `MeNotice` is the de facto one |
| `ClStatTile` / `ClStatRow` (value + unit + label + optional range or delta) | No shared stat tile; the senior-ui-ux skill §4 requires them |
| `ClIconChip` (tinted square + icon, care-colour aware) and a usable round icon button | About 7 tinted-chip copies and about 8 round-icon copies |
| `ClTag` / status pill (neutral / warm / sun / care / premium) | About 17 chip and tag copies |
| `ClDateTimeSheet` / `ClWheelPicker` | 17 hand-built Cupertino picker sheets |
| `ClAsync` (loading skeleton / error with retry / empty) | 264 `.value ??` reads vs 7 `.when` |
| `ClPage` / `ClSection` (screen frame + section heading + spacing rhythm) | 8 `*Page` frames, about 12 heading variants, 88 raw `Scaffold`s |
| `ClFootnote` / "learn more" disclosure | 5 footnote copies + many long explanatory strings |
| Photo grid (`ClMediaGrid`, extent-based) | Fixed 3 / 4 / 5 columns in different screens |

### 9.2 Inconsistent tokens [V]

- **Radius.** The token scale (8 / 12 / 24 / 28 / 32 / 36) does not match practice
  (12 / 14 / 16 / 20 / 24). Token arithmetic (`card - 6`, `control + 4`) hides two missing
  steps.
- **Spacing.** 2, 6, 10, 14 and 20 are used about 450 times as literals.
- **Type.** No 15 pt row-title or 13 pt meta style (232 literal uses). `w700` is used 213 times
  outside the scale. `bodyStrong` is both bolder and bigger than `body`.
- **Icon size.** No token; 18 / 16 / 14 / 20 / 12 are all used.
- **Colour.** `onWarm` is unsafe on soft warm fills in Night care. There are no named tokens for
  photo overlays (raw white / black). Premium and Lumi palettes live outside `tokens.json`.

### 9.3 Duplicated patterns [V]

- Duplicates are listed in §5.3.
- Two Today renderers coexist (legacy sections vs `AxCard` adaptive).
- Two paywall implementations coexist in one file (v2 live, v1 widgets still present).
- `_PlanCard` is defined twice.

### 9.4 Unclear component responsibilities [V / A]

- **`MeRow` / `MeNotice`.** They live in `features/me` but are the app's de facto row and notice
  (10+ features import them).
- **Misplaced `Cl` widget.** `ClRedDot` is `Cl`-prefixed but sits in `features/family`.
- **Unclear core-row roles.** `ClListRow` vs `ClDetailRow` vs `ClOptionRow` vs `MeRow` vs
  `RhOptionRow`: when each applies is not written down [A].
- **Blurred tones.** `error` vs `danger`, and the warn vocabularies (`MeTone.warn`,
  `AsTone.warn`, sunshine vs peach), are defined in doc comments but not enforced by a component.
- **Ambiguous surface names.** "Sheet" names cover pages (`showGoalsSheet`). Some flows bypass
  go_router (15 files).

### 9.5 Missing UX Writing conventions [V]

- No glossary that fixes the canonical term for the following, so variants grow per feature:
  - entry / log (ghi nhận vs nhật ký vs bản ghi);
  - family (gia đình vs nhà vs hộ);
  - reminders (nhắc việc vs nhắc nhở);
  - the assistant (Lumi vs trợ lý vs AI);
  - the caregiver role.
- No shared action keys policy: there are 800 redundant duplicate keys.
- No rule for `{name}` vs `{baby}`. The same placeholder means three different people.
- No length budgets for title, subtitle, body or notice. Current p90s (8 / 12 / 25 words) are
  emergent, not designed.
- No rule for system words (đồng bộ, dữ liệu, offline) or for when an explanation goes behind a
  tap.
- No spelling standard for vi tone marks (Xoá / Xóa, Huỷ / Hủy) or en (British vs US).
- No role-aware copy mechanism (no ICU `select`).

### 9.6 Potential accessibility issues [V code shape / A impact]

- **No text-scale clamp; many fixed heights.** About 153 fixed `height: 20–39`, plus fixed
  `childAspectRatio` grids (Today care grid 166/156). Clipping at large Dynamic Type is likely
  outside core rows [A, needs rendering at 200 %].
- **Small text.** 9–11 pt literals (about 83 uses), e.g. `PremiumCrest` at 7 and 9 pt.
- **Raw colours on non-photo surfaces** can fail in Night care [A].
- **Headers are announced, but the levels are flat.** `header: true` appears in 73 files, which
  is good. Hand-rolled headers rarely set heading levels [A].
- **Spinners have no semantics label** (`CircularProgressIndicator` ×31), whereas
  `withClProgress` and `ClSkeleton` are designed for it [A].
- **Colour as meaning.** `ClSyncStatus` enforces icon + words; feature banners and chips do not
  consistently [A].

---

## 10. Recommendations for the Five Product Design Skills

The skills should **codify and consolidate** what exists, not introduce a new look. Each one
should point at real `Cl*` APIs and be checkable against goldens. The existing `senior-ui-ux`
skill (`.claude/skills/senior-ui-ux/`) is the process layer; the five below should be the
reference layer it calls into.

1. **Design Tokens & Foundations.**
   - Documents `context.cl`, the palettes and care colours, and the safe pairs (`ink` on soft
     warm fills; `mint` never under text).
   - Proposes the token additions the code already wants:
     - radius 14 / 16 / 20;
     - spacing 2 / 6 / 10 / 14 / 20;
     - a 15 pt row title and 13 pt meta;
     - icon sizes;
     - a photo-overlay colour;
     - a rule on w700.
   - Bans new literals in reviews.
   - Owns the Premium dark palette question: a third palette, or a documented exception.
2. **Component Library & Composition.**
   - Defines the missing core components (§9.1) by promoting the best existing implementation
     rather than writing new ones:
     - `MeNotice` becomes `ClNotice`;
     - `RhCard` / `NuCard` become `ClCard`;
     - `CareSheetFrame` becomes the sheet-form pattern;
     - the care `pickCareTime` becomes `ClDateTimeSheet`.
   - Includes a "which row / which card / which chip" decision table.
   - Includes a migration map from each `Xx*` kit widget to its core replacement.
3. **Screen Patterns (MB-Bank-style scanability).**
   - Templates for:
     - dashboard sections — one hero, 2–4 sections, `ClSectionHeader`, a fixed section rhythm;
     - summary / stat tiles — numbers as visuals with `ClTabularText`;
     - action rows and quick actions;
     - tracking sheets;
     - galleries — an extent-based grid;
     - insights cards;
     - forms;
     - premium surfaces.
   - Reconciles the legacy Today with adaptive `AxCard`.
4. **States, Feedback & Accessibility.**
   - Mandates an async wrapper with skeleton, error-with-retry and empty states (§6.11).
   - Sets the toast vs notice vs sheet vs `withClProgress` rules, and offline/sync presentation.
   - Covers Night care behaviour, Reduce Motion, 44 pt targets, 200 % text, minimum text size,
     semantics labels for whole tiles, and never using colour alone.
5. **UX Writing (vi-first, en mirrored).**
   - A glossary fixing the canonical terms (§9.5) and a CTA lexicon with shared keys (Xong /
     Lưu / Thử lại / Để sau / Tiếp tục).
   - Title, subtitle and body length budgets.
   - `{baby}` vs `{name}` placeholder rules.
   - A banned system-word list with plain replacements.
   - "Explain behind a tap" guidance.
   - Spelling standards (vi tone-mark placement, en US or UK).
   - ARB key-naming guidance for new features.
   - Tone: "bạn" / "nhà mình", "nhé", celebration only for milestones.

### Architectural limitations the skills must account for [V]

- **Tokens are generated.** Additions go through `packages/design-tokens/tokens.json` +
  `generate.ts` (and affect the web via CSS), never `tokens.g.dart` by hand.
- **Figma is the stated V1 source of truth** (CLAUDE.md), and many feature-kit values cite Figma
  frames (e.g. radius 20 / 16 drawn in specific frames). Normalising them changes pixels against
  Figma, so it needs an owner decision logged in `docs/product/business-map.md`.
- **Goldens will churn.** Any token or component consolidation rewrites many of the about 1,786
  goldens. Skills should require staged, per-component migrations with before/after images.
- **Two live Today paths and two nav versions behind flags** (`adaptiveOnProvider`,
  `adaptiveNavProvider`). Patterns must work in both until one is retired.
- **Premium is intentionally off-palette.** Rules must allow a sanctioned exception without
  re-opening it everywhere.
- **Copy changes are owner decisions** when they differ from Figma (senior-ui-ux §5). ARB
  consolidation must keep vi/en parity and `@` descriptions (`required-resource-attributes`).
  Widget copy goes through `glance_copy.dart` with literal placeholders, so plural rules don't
  reach it.
- **Shared working tree.** Parallel sessions work on the same branch (whole-tree `dart format` and
  prettier on business-map are disallowed). Migrations must be file-scoped.
- **No tablet or text-scale strategy exists yet.** A skill can set rules, but enforcing them
  needs an app-level decision (clamp or no clamp; max width).
