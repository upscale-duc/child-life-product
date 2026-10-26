# Review workflow

**Understand → Inspect → Audit → Prioritise → Decide → Classify → Verify → Report**

This runs **inside** the master's autonomous workflow (`senior-ui-ux` §2:
Discover → Verify sources → Fresh render → Audit → Simplify → Structure → Design → Implement →
Re-render → Review → Iterate → Verify, then Report; D-109 … D-111):

| Master phase | Review phases |
|---|---|
| Discover / Verify sources / Fresh render / Audit | A–D (B starts with the freshness check) |
| Simplify | C's content-necessity check (dimension 11) feeds the Essential / Contextual / Redundant table |
| Structure / Design / Implement / Render | E–F decide and classify; the fix itself uses `cl-screen-patterns`, `cl-components`, `cl-ux-writing`, `cl-design-foundations` |
| Review / Iterate | C–G on the rendered change, repeated until the completion gates pass |
| Report | H |

**Two modes:**

- **Autonomous (default):** L1 / L2 findings are implemented and re-reviewed without owner
  approval.
- **Audit-only** (only when the request says so): stop after H, change nothing.

L3 items are never implemented by a review; they are isolated and reported.

## A. Understand: what is the parent trying to do?

Write down, before looking for visual issues:

| Item | Source |
|---|---|
| Screen name + file | `apps/mobile/lib/features/<feature>/…` |
| Archetype | `cl-screen-patterns` → `screen-archetypes.md` (A–I) |
| User role(s) | Parent / co-parent, caregiver, relative (and what each may do: `docs/product/business-map.md` §5, Rules) |
| Primary job and expected next action | Interview the screen, not the code |
| Current state(s) in scope | Loaded, empty, offline, first run … |
| Child age band | 0–1 / 1–3 / 3–6 / 6–12 (adaptive bands) |
| Business rules and decisions | D-, R-, P-, Q- ids that govern it |
| Feature status | Implemented / Approved · Planned / Proposed / Deprecated (`cl-ux-writing` glossary) |
| Available evidence | Which goldens, which variants, what can't be rendered |

## B. Inspect

- **Freshness first (D-111):** run `tool/golden_freshness.sh` on the screen's golden tests and
  classify every image Current / Outdated / Unverified / Historical (`visual-verification.md`
  §0). Audit on fresh renders; a stored image is never assumed current.

1. **Rendered first:** list and open the goldens for the screen (`visual-verification.md` §1–2).
   Note which locale × theme × state × role variants exist.
2. **Code:** the screen file, its sections, the components used, how async data is read (`.when` vs
   `.value ??`), role branches, flags.
3. **Copy:** the ARB keys used (`grep -n "l10n\.\w*" <file>`), vi + en values and descriptions.
4. **Rules:** the decisions that constrain behaviour.
5. **Record what you could not inspect:** text scale, long names, small screens, devices, motion.

Code alone never confirms visual quality. Goldens alone never confirm behaviour.

## C. Audit

- **Apply the rubric** (`ux-quality-rubric.md`) and the specialised checks:
  - `visual-hierarchy-review.md`;
  - `interaction-and-usability-review.md`;
  - `content-and-localization-review.md`;
  - `states-and-trust-review.md`;
  - `accessibility-review.md`.
- **Check the critical gates first.**
- **Then content necessity & information density** (dimension 11), before any visual polish:
  list what can be removed, merged, rewritten or relocated, and confirm Essential content is
  present.
- **Every finding:** a concrete problem + a plausible user consequence + an evidence level
  (R / C / H).
- **Separate** confirmed problems, potential problems (H) and missing evidence.

## D. Prioritise

Per finding:

- UX severity (Blocker / High / Medium / Low);
- implementation priority (P0–P3);
- confidence.

Rules are in `issue-severity-and-prioritization.md`. Functional confusion and trust issues outrank
cosmetics.

## E. Decide

For each important finding, **one** concrete solution (no menus of alternatives for the owner):

- what should change;
- why;
- the expected user benefit (no invented metrics);
- trade-offs;
- the autonomy level (L1 / L2 / L3).

Reuse the existing patterns, components and terms; name the skill that owns the fix.

## F. Classify (`senior-ui-ux` §3, D-109)

| Level | Covers | What happens |
|---|---|---|
| **L1 polish** | Spacing, type, overflow, contrast, card styling, icon sizing, state presentation, copy within approved terms, responsive layout | Implement |
| **L2 redesign** | Section order and hierarchy within a screen, card composition, fewer CTAs, density, layout restructure (major screens included), consolidating visuals, clearer affordances to the same destinations | Implement, **if** meaning, reachability, destinations, permissions, preferences and existing decisions are unchanged |
| **L3 owner decision** | Business logic; feature removal; new capability; Adaptive ranking; Customization behaviour; permissions; behaviour-changing navigation; entitlements and pricing; canonical terms; new tokens or design-system direction; legal / privacy / consent; material AI or health claims; ambiguity that could misrepresent data | Keep current behaviour, report with a recommendation; continue the rest |

Every level still needs verified business meaning. If meaning can't be confirmed, mark the item
`Needs behavior verification` and don't implement it until it is checked. Owner decisions on L3
items are recorded as D-xxx in `business-map.md`.

## G. Verify (after implementation)

Same fixture, locale, theme, viewport, text scale, state and role, before and after
(`before-after-evaluation.md`). Outcome: Improved / No meaningful change / Regressed / Inconclusive,
with evidence. Tests passing ≠ improved.

## H. Report

Use `review-report-template.md`:

- a quick single-screen review, or a multi-screen audit;
- always with evidence coverage, the scorecard with gates, findings, and a Vietnamese
  owner summary.

## Scope control

- Review the screen asked about. Note adjacent problems briefly; don't expand into a redesign.
- Don't repeat the full pattern audit (`cl-screen-patterns` → `screen-pattern-audit.md`); cite
  its finding ids when they apply.
- Never change production code, ARB, tokens or golden baselines during a review.
