# Multi-screen execution

Use this for requests like "audit and improve all Care screens" or "review and improve the whole
app". It runs the autonomous workflow (`SKILL.md` §2) over batches, under the L1 / L2 / L3
policy (§3), without routine owner approvals.

## 1. Inventory

- **List the screens in scope from code:**
  - routes in `apps/mobile/lib/app/router.dart`;
  - screen classes under `apps/mobile/lib/features/<feature>/`.
- **List the goldens** that cover them (`apps/mobile/test/golden/goldens/<group>/`; naming in
  `cl-design-review` → `visual-verification.md`).
- **Note for each screen:**
  - its archetype (`cl-screen-patterns` → `screen-archetypes.md`);
  - its roles;
  - its flags;
  - the shared components it uses;
  - how often it is used (daily: Hôm nay, care sheets, history; weekly: stats, memories; rare:
    settings, onboarding).

## 2. Group

Group by feature **and** by shared component.

Shared components cross feature lines. For example:

- `ReminderPeek` is on both Today paths;
- `CareTile` is on Today and the care hub;
- `MeRow` / `MeNotice` are in about 15 features.

A fix to a shared piece is one change, verified everywhere it renders.

## 3. Baseline

Before changing anything:

- reuse current evidence or run `tool/golden_freshness.sh <files>` (macOS, never writes baselines) to confirm which
  baselines match the code; audit on the fresh renders (`failures/*_testImage.png` for the
  Outdated ones) and classify every image Current / Outdated / Unverified / Historical;
- inspect images selected by `cl-design-review/references/visual-verification.md` → Visual evidence policy;
- score each screen quickly with the `cl-design-review` rubric (gates first).

Note fixture artefacts (e.g. grey photos without image bytes) so they aren't mistaken for
defects.

## 4. Cross-screen inconsistencies

Look across the group for:

- the same thing named differently (terms, link labels);
- the same pattern drawn differently (cards, notices, pickers, empty states);
- different overdue / attention colours;
- loading drawn as empty;
- truncation of key values.

Prefer one shared fix (`cl-components` → `component-evolution.md`) over many local ones.

## 5. Prioritise

Order the work by:

1. gate failures and trust issues (loading-as-empty, misleading status);
2. Blocker / High usability and accessibility (truncated key values, 200 % overflow);
3. frequency × reach (daily screens and all roles first);
4. shared fixes that improve many screens at once;
5. Medium consistency;
6. Low polish.

Skip cosmetic consistency when it would cost usability.

## 6. Batches

- **Size:** a batch is small enough to verify fully. Typically one screen, or one shared
  component with every screen it touches.
- **Per batch:** Simplify (`content-simplification.md`) → Structure → Design → Implement → Render (reuse current evidence or render affected code; automated matrix and visual selection
  follow the central Visual evidence policy) → Review (gates, rubric, regression of destinations,
  roles, preferences) → Iterate → tests (`flutter analyze`, `flutter test`, the touched golden
  tests) → a short batch report.
- **Traceable and reversible:** one batch = one commit (when committing is part of the task),
  its message listing the screens and the findings fixed.
- **Shared tree:**
  - never include other sessions' files;
  - never reformat whole directories;
  - sequence after uncommitted edits on the same files.

## 7. L3 items inside a batch

When a batch hits an L3 question (a term, a behaviour, a token):

- keep the current behaviour for that item;
- note it in the batch report as "Owner decision" with the trade-off;
- finish the rest of the batch.

Collect all open L3 items in the final report. Don't stop the batch or the run for them.

## 8. Moving on

After a batch passes its completion gates (`SKILL.md` §2 H), go straight to the next one. Report
progress at natural milestones (a feature group done), not after every routine change.

## 9. Final report (whole run)

- **Summary:** the screens improved, grouped by feature.
- **Fixes:** the shared fixes and where they apply.
- **Images:** a before → after gallery (key variants).
- **Scores:** gate and rubric changes per screen (same coverage before and after).
- **Tests:** the tests run and their results.
- **Limitations:** what remains (not evaluated, pre-existing issues not safely fixable).
- **Decisions:** the open L3 decisions, each with a recommendation.
- **Owner summary** in Vietnamese.
