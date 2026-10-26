# Golden baseline audit (2026-10-25)

**Principle (D-111):** the current Flutter code is the implementation truth, a fresh render is
the current visual evidence, and a verified golden is the approved regression baseline. A passing
golden doesn't prove the design is right; a failing one doesn't prove a regression.

Method: `apps/mobile/tool/golden_freshness.sh` (new) runs the golden tests **without**
`--update-goldens`, writes `test/golden/failures/FRESHNESS.txt`, and leaves the fresh render of
every mismatch in `test/golden/failures/<name>_testImage.png`. A JSON-reporter run listed every
golden test name to find images that no test produces. Run on macOS at `7bb2d9e9` plus the
uncommitted tree (this session's Care pass and the parallel Today Version A session).

## A. Inventory

| Item | Value |
|---|---|
| Golden test files | 34 in `apps/mobile/test/golden/*_golden_test.dart` (tag `golden`), plus `test/features/print_studio_test.dart` (8 `print/current_*` images, **untagged**) |
| Golden comparisons | 1,746 in `test/golden` |
| Baseline images | 1,794 PNGs under `test/golden/goldens/` (1,786 committed + 8 new Care loading baselines) |
| Groups | ai 44, as 232, ax 68, root showcase 32, fa 28, hn 44, journal 6, lb 48, mm 22, ms 32, nt 24, pd 24, pm 72, print 26, pv2 80, rh 112, s2 52, s3 68, s4 64, s5 36, s6 76, s7 84, s9 108, s10 88, s11 76, s12 76, sp 104, up 16, ut 8, vx 44 |
| Variants | Light + Night care × vi + en for almost every case; theme-only for `journal/`, `mm/` and some `print/` |
| Conditions | 375 × 812 (long screens 375 × 1100 / 1800), DPR 1, real fonts (`flutter_test_config.dart`), fixed clocks (`careNow`, `minuteClockProvider`), fake repositories; macOS only (`dart_test.yaml`, CI macOS job) |
| Fixtures | `test/helpers/*_fixtures.dart` (care, family, adaptive, premium, memory …); `careOverrides(rangeLoading: true)` added for loading states |

**Missing coverage** (reported, not filled with permutations):

- No 200 % text-scale baselines. Care has a reproducible probe
  (`test/design_explorations/care_probe/care_scale_probe_test.dart`, its own output folder);
  other features have none.
- No long-name fixtures.
- No error-state goldens for care ranges (History / Stats).
- Sleep chooser at 200 % not reached by the probe.

## B. Freshness findings

### Current

**1,742 / 1,746** comparisons match a fresh render of the current code (final run).

### Stale, verified (updated)

| Baselines | Cause | Evidence |
|---|---|---|
| `s9/10f_viewer_*` (4), `s10/10f_viewer_thread_*` (4) | Commit `58c7895f` (2026-10-25) added a Print Studio rail button (`ClIcons.memories`, label `psTitle`) to the media viewer for parents, photos only; the baselines predate it. The diff is the new button plus the rail moving up (39 % of pixels because the rail sits on the photo gradient) | `docs/design/reviews/assets/care-2026-10-25/golden_10f_viewer_baseline_fresh_diff.png` (baseline / fresh / diff / thread Night en) |
| Care pass baselines (this session) | Intended Care changes, each inspected | `docs/design/reviews/care-autonomous-improvement.md` §5 |

Note for a later design review: the Print Studio rail icon reads like an Instagram glyph; its
meaning isn't obvious without a label (Medium, interaction clarity).

### Regression suspected (left unchanged)

| Baselines | What the fresh render shows | Why it is suspicious |
|---|---|---|
| `pd/notes_editor_*` (4) | The notes switch reads "Cả nhà dùng chung" instead of "Chia sẻ với người được xem chăm sóc bé" | The key `pv2Shared` is shared by personalization v2 (notes) and Premium v2 (family plan tag, `family_plan_v2.dart:332`). Commit `58c7895f` rewrote it for Premium; the notes switch changed meaning as a side effect (from "people who can view care" to "the whole family"). Fix: give Premium its own key, restore the notes wording (`cl-ux-writing` verified meaning). Baselines kept as the evidence of the intended copy. |

### Unverified (reported, not deleted)

- `print/{book,details,edit,export,hub,options,order_review,preview,products,shipping}_{light,nightCare}.png`
  (20 files, committed in `58c7895f`): no test produces them. Probably an earlier Print Studio
  harness. Confirm with the Print Studio owner before removing.

### Historical (never used as current UI)

| Location | Count | Notes |
|---|---|---|
| `docs/design/explorations/today-adaptive-v2/assets/` | 72 | Version A / B prototypes (D-108) |
| `docs/design/reviews/assets/` | 10 | Before / after evidence of reviews |
| `docs/discovery/figma-extract/` | 302 | Figma history (D-104) |
| `apps/mobile/test/design_explorations/**` outputs | 68 | Prototype and probe renders; Current only at the time of their run |
| `artifacts/**` (untracked) | 1,944 | Audit and Premium phase captures (2026-10-23/24): Outdated by default |

## C. Updated baselines

| Files | Reason | Evidence |
|---|---|---|
| `s9/10f_viewer_{light,nightCare}_{vi,en}.png`, `s10/10f_viewer_thread_*` | Stale, verified (above) | Fresh render opened; only the new rail button and rail position differ |
| `s6/20_history_*_en`, `20a_history_feed_*_en`, `12d_history_caregiver_*_en`, `20e_history_empty_*`, `s4/v1i_care_hub_*`, `s4/24_diaper_*`, `s5/25a_sleep_chooser_*`, `s5/26_manual_sleep_*`; new `s6/20i_history_loading_*`, `s6/20j_sleep_stats_loading_*` | Care pass, intended | Care report §5 |

Not touched: the `ax/`, `hn/`, `s4/19_today*`, `9a_today_offline*`, `s5/19_sleep_running*`
baselines changed in the tree by the Today Version A session (its own work), and the
`pd/notes_editor_*` baselines.

## D. Verification

- `tool/golden_freshness.sh` (all 34 files) after the updates: 1,742 pass, 4 fail
  (`pd/notes_editor_*`, regression suspected, unresolved).
- `flutter test --exclude-tags golden`: passes (three Care tests updated to the new copy).
- `flutter analyze` on the changed code: no issues.
- `git status` checked: no baseline outside the lists above was changed by this session.

**Non-deterministic fixture (found 2026-10-26):** `print/current_options` renders the delivery
window from the real clock ("Đặt hôm nay, nhận khoảng 01/11–03/11" became "02/11–04/11" when the
date changed), so `print_studio_test.dart` fails on a new day. Fix: inject the clock in that test;
don't refresh the baseline.

**Infrastructure risk:** `test/features/print_studio_test.dart` compares goldens but isn't
tagged `golden`, so CI's Linux job (`--exclude-tags golden`) runs it, where golden comparisons
are unreliable. Recommend tagging its golden cases (owner of that test).

## E. Design skills

| Skill | Change |
|---|---|
| `senior-ui-ux` | Workflow Discover → Verify sources → Fresh render → Audit → Simplify → Structure → Design → Implement → Re-render → Review → Iterate → Verify; goldens are baselines, not proof; the multi-screen baseline step uses the freshness script |
| `cl-design-review` | `visual-verification.md` §0: Current / Outdated / Unverified / Historical, the freshness check, baselines updated only on purpose, keeping baselines fresh; Inspect phase and non-negotiables require fresh renders |
| `cl-screen-patterns` | Inspect = a fresh render |
| `cl-ux-writing`, `cl-components`, `cl-design-foundations` | No freshness duplication (they point to the master); D-110 simplification rules added the same day |

**Future tasks:** before any UI/UX change, run
`cd apps/mobile && tool/golden_freshness.sh test/golden/<feature>_golden_test.dart`, audit the
fresh renders, investigate every Outdated baseline, then re-render after the change and update
only the touched, inspected baselines. When shared widgets change, run the script on the whole
suite and attribute every diff.
