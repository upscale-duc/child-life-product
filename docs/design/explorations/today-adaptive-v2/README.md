# Today Adaptive v2: visual exploration (Step 9A.1)

A controlled design experiment, **not production code.** Two prototype renderings of Hôm nay
(Adaptive) are compared with the current screen, using real Flutter widgets, tokens, fonts,
fixtures and the real Adaptive ranking.

| | |
|---|---|
| **Current** | The production `TodayScreen` (`apps/mobile/lib/features/today/today_screen.dart`), rendered unchanged |
| **Version A, "Refined current"** | The AX card structure kept; its execution corrected |
| **Version B, "Adaptive Briefing"** | Headings outside, one content pattern per module, empty modules as rows |

The findings and recommendation are in [comparison.md](comparison.md).

## Files

| Path | What |
|---|---|
| `apps/mobile/test/design_explorations/today_v2/today_v2_prototypes.dart` | `TodayProtoA`, `TodayProtoB`, and the shared read-only data context `TodayData` |
| `apps/mobile/test/design_explorations/today_v2/today_v2_exploration.dart` | The scenarios and the renderer (current \| A \| B triptychs + single A / B images) |
| `docs/design/explorations/today-adaptive-v2/assets/` | 72 PNGs, `ranked_orders.txt`, `overflows.txt` |

**Isolation:**

- Everything lives under `test/` (never shipped) in **new, untracked files.**
- The file names avoid `_test.dart`, so `flutter test` and CI never run them on their own.
- No production file, ARB string, token, provider, route or golden baseline was modified.

## Reproduce (macOS, from the repo root)

```bash
cd apps/mobile && flutter test --update-goldens test/design_explorations/today_v2/today_v2_exploration.dart
```

`--update-goldens` here writes **only** the images this file names (all under
`docs/design/explorations/today-adaptive-v2/assets/`). Production baselines in
`apps/mobile/test/golden/goldens/` are never touched. To re-render one scenario:

```bash
cd apps/mobile && flutter test --update-goldens test/design_explorations/today_v2/today_v2_exploration.dart --plain-name "compare 0-1_light_vi"
```

```bash
cd apps/mobile && flutter analyze test/design_explorations
```

## How the prototypes get their data (no simulation of ranking)

- **Same harness as `test/golden/adaptive_golden_test.dart`:** 375 × 812, mock clock 8 Oct 2026
  10:00, `careOverrides` + `adaptiveOverrides`, `FakeExperienceRepository`, the real
  `MaterialApp` / theme / localisations / fonts.
- **Order and visibility come from `adaptiveTodayProvider`,** which runs the real `rankToday`:
  pins, manual order, hidden widgets, band defaults, goals and signals. The order each render
  consumed is written to `assets/ranked_orders.txt`, e.g.
  `customized light vi: recent_memories [pinned] → reminders → tiles → care_duty → growth (hidden) …`.
- **Both versions read production providers read-only** (`recentRecordsProvider`,
  `remindersProvider`, `mediaProvider`, `familyMembersProvider`, `watchSpending`, …) and reuse the
  same formatting helpers as `ReminderPeek` (`groupReminders`, `reminderWhenRelative`, …).
- **Production widgets reused unchanged in both versions:**
  - `CareTile`, `BabyHeader`, `AxStageCard`, `AxCustomizeLink` (the existing Customize entry);
  - `TodayHandoverRow`, `CareDutyChip`;
  - `TodayForBabySection`, `SdTodayCard`, `TodayQuickActions`, `TodayVaccineCard`, `DayRhythm`.

## Simulations and limits (documented)

| Scenario | How it is produced | Limit |
|---|---|---|
| Customised Today | `Experience(pinned: [recentMemories], order: [...], hidden: [growth])` through the real engine | — |
| Loading | A nested `ProviderScope` gives `recentRecordsProvider` a stream that never emits | Providers derived in the root scope (e.g. `todayFirstRunProvider`) still see the fixture records, so the header reads "Nhịp hôm nay" as on a real cold start with cached state |
| Long child name | A nested `ProviderScope` overrides `babyProvider` with "Nguyễn Hoàng Bảo Ngọc Anh" | Same scope note; widgets that read the baby directly show it |
| Offline / pending | `mockDay(offline: true)` + `online: false` (the fixture behind `s4/9a_today_offline`) | The prototypes redraw the private `_SyncBanner` |
| 200 % text | `TextScaler.linear(2)` on the phone's `MediaQuery` | Layout exceptions are recorded in `overflows.txt` and drawn with Flutter's overflow stripes |
| Relative | `member(… MemberRole.relative, extra: ExtraRights(viewDailyCare: true))` (D-018) | — |

**Fixture caveats:**

- **Photos render as grey boxes:** fixture media have no image bytes. In production they show
  real photos.
- **Wrong age label in older bands:** the 1–3, 3–6 and 6–12 renders show the fixture baby
  "Teddy · 3 tuần".
- **First run has reminders:** the first-run fixtures still contain the fixture reminders.

**Strings without an ARB key** (the empty-name greeting fallback, the loading semantics label,
"Thêm" on the add tile) are prototype-local (`_proto` in `today_v2_prototypes.dart`). In
production they would go through a `tool/*_strings.py` script.

**Not evaluated:** screen reader and focus order, real devices, motion, small (320 pt) and large
phones, real photos.

## Cleanup

The prototype is disposable. To remove it:

```bash
rm -r apps/mobile/test/design_explorations
```

Keep `docs/design/explorations/today-adaptive-v2/` as the record of the decision.
