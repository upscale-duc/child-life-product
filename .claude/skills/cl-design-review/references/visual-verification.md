# Visual verification (Flutter goldens)

All facts below were verified in the repository on 2026-10-25. §0 (freshness) comes first.

## 0. Freshness first (D-111)

**Source code = implementation truth. Fresh render = visual truth.** No image stored in the
repository is assumed to show the current UI: goldens are test baselines, screenshots in docs may
predate later code, and other sessions change shared code without always re-rendering.

### Classify every image you use as evidence

| Class | Means | Use it as |
|---|---|---|
| **Current** | Rendered from the current code (a golden that just passed a run, `failures/*_testImage.png`, a probe or simulator capture made in this task) | Primary visual evidence (R) |
| **Outdated** | Known to come from an older implementation (a golden that fails against the current code; the `*_masterImage` of a failure) | "Before" only; never a finding about the current UI |
| **Unverified** | Can't tell which code produced it (screenshots in docs, PNGs without a test, images from another branch) | Context only; mark findings H and say "Unverified / potentially outdated" |
| **Historical** | Kept on purpose for comparison or documentation (`docs/design/explorations/**`, `docs/design/reviews/**` assets, `docs/discovery/figma-extract/**`, Figma) | History; never the current production UI |

### The freshness check (before every audit or redesign)

1. Read the current implementation: routes, screens, shared widgets, fixtures.
2. Find the goldens for those screens (§1) and their test cases and fixtures.
3. **Render fresh**, without touching baselines:

   ```bash
   cd apps/mobile && tool/golden_freshness.sh test/golden/<feature>_golden_test.dart
   ```

   It runs the golden tests without `--update-goldens` and writes
   `test/golden/failures/FRESHNESS.txt`. Passing cases mean the baseline **is** the fresh render
   (Current). Each failing case is **Outdated**: its fresh render is
   `failures/<name>_testImage.png`, the old baseline `failures/<name>_masterImage.png`, and the
   difference `failures/<name>_isolatedDiff.png`.
4. **Investigate every Outdated baseline before acting on it.** Is it an intended change by
   another session or commit (check `git log` / `git status` for the screen's files), a
   regression, or fixture drift? Never treat a diff as a defect, or as approved, without knowing
   which.
5. Screens without a golden (or states the harness can't reach): render them in a probe test
   outside `test/golden/` (e.g. `test/design_explorations/<topic>/`, writing to its own folder),
   or on the simulator. If nothing can be rendered, mark the evidence Unverified.
6. **Audit on fresh renders only.** A finding drawn from an Outdated or Unverified image is H at
   most and says so.

### Fixtures must show the product families actually see

A fresh render is only as true as its fixture. Before judging a screen, check in the code which
states depend on data, flags or published content (feature flags, portal content, plans, roles)
and render the state real families are in. Example (2026-10-26): the default care fixture has no
published stages or articles and the `rhythm` flag off, so `s4/v1i_care_hub` shows four "Sớm ra
mắt" teasers that no family on dev sees; `s4/v1i_care_hub_live` renders the live hub. A fallback
state (teaser, empty, locked) is reviewed as a fallback, never mistaken for the normal screen. When
unsure what is live, ask or check the dev data rather than designing around the fixture.

### Baselines are updated only on purpose

- `--update-goldens` only for the screens your change touches, after opening the new render and
  confirming the change is intended. Never to make a run pass.
- Never update a baseline another session's change made outdated: tell that session or report it.
- Never overwrite or delete Historical evidence (exploration and review assets). Unused or
  obsolete images are reported, not deleted, until their purpose is confirmed.

### Keeping baselines fresh

- Fixtures are deterministic (`careNow`, the 19 mock day, fixed `minuteClockProvider`); keep new
  cases on them, never `DateTime.now()`.
- Every case renders Light + Night care × vi + en at 375 × 812 (or the documented long size);
  text-scale probes use `TextScaler.linear(2.0)` and their own output folder.
- A shared-widget change runs the **whole** golden suite and attributes every diff.
- Commits that change UI include their regenerated goldens, so the committed baseline stays the
  fresh render of committed code.

## 1. Where goldens live and how they're named

| Item | Value |
|---|---|
| Tests | `apps/mobile/test/golden/*_golden_test.dart` (34 files), tagged `@Tags(['golden'])`; also `test/features/print_studio_test.dart` (8 `print/current_*`, untagged). Inventory and freshness status: `docs/design/golden-baseline-audit.md` |
| Images | `apps/mobile/test/golden/goldens/` (about 1,786 PNGs), grouped by feature folder: `ai/ as/ ax/ fa/ hn/ journal/ lb/ mm/ ms/ nt/ pd/ pm/ print/ pv2/ rh/ s2/ … s12/ sp/ up/ ut/ vx/`, plus core showcase sections at the root (`foundations_*`, `buttons_*`, `rows_*` …) |
| Naming | `<group>/<screen-id>_<palette>_<locale>.png`, e.g. `ax/ax10_today_0_1_nightCare_en.png`. Palette = `light` \| `nightCare`; locale = `vi` \| `en`. A few groups have a theme only (`journal/*_light.png`, `mm/*_light.png`) or unsuffixed "current_" print shots |
| Matrix | Most tests loop `for palette in ClPalette.values × [vi, en]` (e.g. `adaptive_golden_test.dart:227`); test names follow `'<id> <palette> <locale>'` |
| Viewport | 375 × 812 (`test/helpers/router_pump.dart`); long screens 375 × 1100 / 1800 |
| Fixtures | `apps/mobile/test/helpers/*_fixtures.dart` (care, adaptive, premium, memory …). Baby "Teddy", members "Mai", "Cô Lan" |
| Fonts | Real fonts are loaded by `apps/mobile/test/flutter_test_config.dart` |
| Platform | **Goldens match only on macOS** (`apps/mobile/dart_test.yaml`); CI runs them in the macOS job (`.github/workflows/ci.yml`: `flutter test --tags golden`; other jobs `--exclude-tags golden`) |

## 2. Commands (from `apps/mobile`)

```bash
cd apps/mobile && flutter test --tags golden
```

```bash
cd apps/mobile && flutter test --tags golden test/golden/adaptive_golden_test.dart
```

```bash
cd apps/mobile && flutter test --tags golden test/golden/adaptive_golden_test.dart --plain-name "ax10_today_0_1 nightCare vi"
```

The run compares against the baselines. On a mismatch, Flutter writes diff images to
`apps/mobile/test/golden/failures/` (gitignored: `.gitignore`, `apps/mobile/.gitignore`): the
`*_masterImage`, `*_testImage`, `*_isolatedDiff`, `*_maskedDiff` PNGs.

**Updating baselines** (`flutter test --tags golden --update-goldens`, documented in
`dart_test.yaml`) **overwrites production goldens.** It belongs to an implementation (autonomous L1 / L2, or an
L3 the owner decided), limited to the tests of the screens the change touches. Never run it in
audit-only mode. During any review:

- **don't** run `--update-goldens`;
- **to see the "after" of an uncommitted change,** run the comparison (without update) and open
  `failures/*_testImage.png`;
- **to see the committed "before",** use `git show HEAD:apps/mobile/test/golden/goldens/<path>.png`
  redirected into a scratch file outside the repo.

## 3. Inspecting images

- **Open the PNGs themselves** (an image viewer, or Claude's Read tool on the `.png`), never just
  the test result.
- **Look at the same screen in all four variants** (vi / en × Light / Night care). Scan the vi
  variant for wrapping and the en variant for plurals and truncation.
- **Compare variants by state** (`…_offline`, `…_empty`, `…_first`, role variants such as
  `s4/12e_view_only`, `s6/12d_history_caregiver`).
- **Read text in the image literally.** Quote truncated strings exactly ("còn 2 n…").

## 4. Spotting regressions

- **Unexpected diffs in unrelated goldens** after a change: shared-component fallout.
- **Text that newly wraps or truncates in one locale.**
- **Night care-only regressions:** contrast, a missing tint, raw `Colors.white`.
- **Changed hierarchy:** a new element competing with the hero.
- **Lost information:** something that was visible before is gone (check against the before
  image).

## 5. Missing coverage: document it, don't hide it

Known gaps (2026-10-25):

- **Text scale:** no harness except `test/features/assistant_chat_feel_test.dart` and
  `assistant_replay/assistant_replay_test.dart`, which pass `TextScaler.linear(…)` via
  `MediaQuery`.
- **Long names:** no fixtures.
- **Small and large phones:** only 375 pt wide.
- **Loading states:** goldens render loaded data, so "loading looks empty" can't be seen.
- **Motion, gestures, haptics, performance:** not representable.
- **Some fixtures don't match the scenario:** e.g. the `ax12` (3–6 years) Today uses a baby shown
  as "3 tuần / 3 weeks" in the header chip.

When a check needs a variant that doesn't exist, report **"Unverified: no golden for <variant>"**.
Adding coverage (e.g. a text-scale variant using the assistant tests' `TextScaler.linear` pattern)
is a test-only change (L1).

## 6. Evidence levels

| Level | Meaning | Example |
|---|---|---|
| **R** (rendered) | Observed in a golden, screenshot or running app | A status label truncated in `ax/ax10_today_0_1_light_vi.png` |
| **C** (code confirmed) | Confirmed in the implementation, not seen | `.value ?? const []` ⇒ an empty state can show while loading (`today_screen.dart:70`) |
| **H** (hypothesis) | Plausible; needs verification | The same truncation on a real device at 200 % text |

**Combine levels when true** (R + C: seen in a golden and explained by the code). **Never upgrade H
to R or C without the evidence.**

## 7. What goldens can and can't show

| Can demonstrate | Can't prove |
|---|---|
| Layout at one viewport, wrapping and truncation per locale | Gesture usability, one-handed reach |
| Light / Night care differences | Screen-reader correctness and order |
| Visual regressions between commits | Animation and timing quality |
| Selected / empty / offline variants that have fixtures | Real-device performance and memory |
| — | Successful task completion by real users |
