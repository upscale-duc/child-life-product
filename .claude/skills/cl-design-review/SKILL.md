---
name: cl-design-review
description: Independent, evidence-based UI/UX quality review for Child Life (Flutter, apps/mobile). Use when auditing or reviewing an existing screen or a proposed / implemented UI change, when the owner says a screen is "không tốt" or hard to use, when asked to verify a change with rendered goldens (before/after), score a screen, check accessibility, Night care or vi/en layout, or decide whether an improvement is actually better. Gate-first rubric (11 dimensions, 0–5 or Not evaluated), R/C/H evidence levels, separate severity / priority / autonomy level (L1 / L2 / L3), golden-based visual verification (audit-only never touches baselines; implementations update only the goldens they change), and a report template with a Vietnamese owner summary. Final review stage of senior-ui-ux.
---

# Child Life design review

**Review whether the interface helps a parent or caregiver get the job done:** understandable,
useful, efficient, trustworthy, accessible, and warm. Visual consistency comes second. The Flutter
app, ARB and rendered goldens are the evidence for the current UI (D-104); approved decisions
define intended behaviour. **Figma is never required.**

**Two modes (D-109):**

- **Inside the autonomous workflow** (the default): the review is the quality loop of an
  implementation. L1 / L2 findings are fixed directly, re-rendered and re-reviewed until the
  completion gates pass (`senior-ui-ux` §2).
- **Audit-only** (when the request says audit / review only): stop at the report, change nothing.

**In both modes**, L3 items (`senior-ui-ux` §3) are isolated and reported for the owner, never
implemented.

## Workflow

**Understand → Inspect → Audit → Prioritise → Decide → Classify → Verify → Report**
(`references/review-workflow.md`). It is the Review stage (and Iterate loop) of the master
workflow, and the whole of an audit-only request.

1. **Understand.** The parent's job first: screen, archetype, role, state, age band, rules, the
   expected next action, and the available evidence.
2. **Inspect.** Follow `references/visual-verification.md` → Visual evidence policy, the single
   authority for render frequency, reuse and image selection. Reuse current evidence or run
   `tool/golden_freshness.sh`; classify images Current / Outdated / Unverified / Historical.
   Inspect selected variants, code, ARB and rules. Record automatic versus visual coverage.
3. **Audit.** Critical gates, then **content necessity & information density** (dimension 11:
   what can be removed, merged or relocated; what Essential content must stay), then the rest of
   the rubric, then the specialised checks.
4. **Prioritise.** Severity, priority and autonomy level are separate labels; trust and confusion
   outrank cosmetics.
5. **Decide.** One concrete change per finding: what, why, the expected benefit, trade-offs, the
   owning skill. No menus of alternatives for the owner.
   Classify the screen KEEP / REFINE / RESTRUCTURE / REDESIGN (D-112,
   `senior-ui-ux/references/structural-evaluation.md`); for unresolved structural trade-offs, compare
   rendered prototypes and choose; self-critique reuses the current final render set.
6. **Classify.** L1 / L2: implement (or, in audit-only mode, mark "ready to implement"). L3:
   isolate, keep current behaviour, report as an owner decision with a recommendation.
7. **Verify.** Before / after with identical fixtures and variants. Tests passing ≠ improved.
8. **Report.** `references/review-report-template.md`, including a Vietnamese owner summary.

## Non-negotiables

- **Gates override scores.** A failed gate means the verdict "Fails critical gate":
  - G1 business meaning;
  - G2 critical action access;
  - G3 data loss;
  - G4 permissions;
  - G5 AI and health claims;
  - G6 primary task.

  A hypothesis alone only puts a gate "at risk".
- **No fabricated scores.** Missing evidence → `Not evaluated`, never a neutral 3. Accessibility
  from default goldens alone can't exceed 3.
- **Evidence levels on every finding:** **R** rendered, **C** code-confirmed, **H** hypothesis.
  Never upgrade H without evidence.
- **Concrete findings only:** the element + the problem + the user consequence. No "improve
  spacing", "cleaner", "more modern", "more premium".
- **Verified business meaning:** don't reinterpret behaviour. If unsure, mark it
  `Needs behavior verification`.
- **Coverage follows the central Visual evidence policy.** Keep automated vi/en × Light/Night
  coverage; report visual selection, sampling and omissions separately. Missing variants remain
  unverified.
- **Audit-only never changes anything:** no production code, ARB, tokens or baselines, and no
  `--update-goldens`.
- **Inside an implementation,** update only the goldens of the screens the change touches, and
  attribute every diff; visually inspect the selection required by the central policy.
- **Fresh renders are the visual truth (D-111).** Findings from Outdated or Unverified images are
  H at most and say so.
- **No invented metrics or test results.**
- **No universal layout:** judge against the screen's archetype (`cl-screen-patterns`).

## Where the rules come from (don't restate them, verify them)

| Area | Authority | Review procedure |
|---|---|---|
| Composition, hierarchy, states model | `cl-screen-patterns` | `references/visual-hierarchy-review.md`, `references/states-and-trust-review.md` |
| Components and interactions | `cl-components` | `references/interaction-and-usability-review.md` |
| Copy, terms, localisation, AI wording | `cl-ux-writing` | `references/content-and-localization-review.md` |
| Tokens, contrast, type, motion, a11y basics | `cl-design-foundations` | `references/accessibility-review.md` |

## References

| File | Load when |
|---|---|
| `references/review-workflow.md` | Running any review; phase checklists |
| `references/ux-quality-rubric.md` | Scoring: anchors, examples, critical gates, evidence completeness, verdict format |
| `references/visual-hierarchy-review.md` | First fixation, competitors, squint and 5-second tests, the hierarchy checklist |
| `references/interaction-and-usability-review.md` | One-handed, night, roles, multi-child; actions, modes, forms, undo, back |
| `references/content-and-localization-review.md` | Checking vi / en copy on a screen against `cl-ux-writing` |
| `references/states-and-trust-review.md` | Loading vs empty, local vs shared, uploaded vs ready, cached, AI vs fact |
| `references/accessibility-review.md` | Static / rendered / automated / device checks; the required variants matrix |
| `references/visual-verification.md` | Golden locations, naming, commands, failure diffs, missing coverage, evidence levels, golden limits |
| `references/before-after-evaluation.md` | Judging an implemented change: Improved / No change / Regressed / Inconclusive |
| `references/issue-severity-and-prioritization.md` | Blocker–Low, P0–P3, autonomy level L1 / L2 / L3, confidence |
| `references/review-report-template.md` | Writing the report (quick or full) |

**Worked example:** `docs/design/reviews/2026-10-25-today-adaptive.md` (a full review of adaptive
Today plus a six-screen calibration).

## Before you hand in a review

- [ ] The job and archetype stated; evidence coverage table complete, with the "Not evaluated"
      list.
- [ ] Gates reported before scores; no score without evidence.
- [ ] Content necessity reviewed before visual polish; each redundant element named with its
      action (REMOVE / MERGE / REWRITE / RELOCATE).
- [ ] Every finding: R / C / H, a reference (golden path or file:line), consequence, severity,
      priority, autonomy level, confidence.
- [ ] Proposals preserve verified meaning, or are marked `Needs behavior verification`.
- [ ] vi / en and Light / Night care both covered or explicitly not.
- [ ] Audit-only: nothing changed. Implementation: only the intended goldens changed, and every diff
      was attributed; visual coverage follows the central policy.
- [ ] The Vietnamese owner summary, in plain words.
