# Child Life — Product Design Skill Architecture

Status 2026-10-25 (step 9 + D-110): the six skills run in **autonomous mode** with a mandatory
Simplify stage (D-109: L1 / L2 without
routine owner approval, L3 isolated for the owner). Hôm nay (Adaptive) follows Version A (D-108),
not yet implemented. Step 8: **all six skills are implemented**: `senior-ui-ux` (master),
`cl-design-foundations`, `cl-components`, `cl-ux-writing`, `cl-screen-patterns` and
`cl-design-review`. That the review skill exists doesn't mean every production screen has been
reviewed. Reviews so far: `docs/design/reviews/2026-10-25-today-adaptive.md` (one full review + a
six-screen calibration) and the two read-only audits inside `cl-ux-writing` and
`cl-screen-patterns`.

Background reading:

- [design-system-discovery.md](design-system-discovery.md) — what the app's design system is.
- [skill-gap-analysis.md](skill-gap-analysis.md) — why the skills are structured this way.

Decisions: D-104 … D-107 in [`business-map.md`](../product/business-map.md).

This document describes the *system*. The working rules live in the skills; they are not repeated
here.

## 1. Design philosophy

- **Information design from MB Bank:**
  - strong hierarchy;
  - scan-first layouts;
  - action-first interaction;
  - meaningful density;
  - clear status;
  - frequent actions within reach.
- **Identity from Child Life:**
  - warm, calm, family-centred;
  - minimal but not empty;
  - emotionally meaningful;
  - readable during night care.
- **Never copied from MB Bank:** its colours, branding or financial patterns.
- **Design the experience before choosing widgets.** Seven questions come first: who, their goal,
  the 5-second understanding, what deserves attention, the next action, what to simplify or
  disclose later, and which existing pattern fits. Widgets come after.

## 2. Skill architecture

```
senior-ui-ux                 master · entry point · process spine · works alone      [live]
 ├── cl-design-foundations   tokens, colour pairs, type, spacing/radius, elevation,
 │                           motion, Night care, a11y foundations                    [live]
 ├── cl-components           catalogue, selection, cards (ClCard proposal), actions,
 │                           forms & feedback, missing-component protocol            [live]
 ├── cl-screen-patterns      archetypes, hierarchy, dashboards, timelines, insights,
 │                           forms & flows, galleries, states, screen audit          [live]
 ├── cl-ux-writing           bilingual vi/en copy, tone, glossary, numbers in text,
 │                           AI wording, ARB & localisation, copy audit              [live]
 └── cl-design-review        gate-first rubric, R/C/H evidence, visual verification,
                             a11y review, before/after, report template              [live]
```

**Conventions for every skill:**

- **Small SKILL.md.** It holds the triggers and the always-needed rules; detail goes in
  `references/*.md`, loaded on demand.
- **One home per rule.** Every other skill links to that home rather than restating it.
- **Cite code paths, don't paste code,** so a skill stays valid as the code evolves.
- **Every rule is checkable,** either on a rendered image or mechanically.
- **Scope is Flutter (`apps/mobile`).** The portal and landing page may reuse the workflow, but not
  the `Cl*` rules.

## 3. Responsibilities and boundaries

| Skill | Owns | Does not own |
|---|---|---|
| `senior-ui-ux` | The autonomous workflow, routing, the L1 / L2 / L3 autonomy policy, multi-screen execution, protected systems, decision recording, the 5-second framing, and "numbers become visuals" as a principle. It also holds **interim rules** (its §4–§6) until each specialised skill exists. | Detailed catalogues, glossaries, rubrics (these move out as the skills are created) |
| `cl-design-foundations` | Token roles and safe pairings, the type-role map, spacing and radius ladders, icon sizes, elevation (D-096), motion and haptics (D-048 pointers), Night care, a11y minimums, the token change procedure (D-106), the Premium palette exception | Which widget to use; screen layout |
| `cl-components` | The verified catalogue of core `Cl*` widgets and de facto shared widgets; selection trees; which component serves each action, form and feedback need; the **proposed** `ClCard` family spec (D-107, not implemented); the missing-component protocol; the duplication audit and migration table; the component quality checklist | Token values; screen composition and the layout of states; wording |
| `cl-screen-patterns` | Nine screen archetypes with reference screens and goldens; information hierarchy and density; dashboards (respecting Adaptive `rankToday`, D-097); timelines; insights and charts (facts vs suggestions vs AI); forms and multi-step flows; galleries and selection modes; the screen-state model (verified sync and upload distinctions); responsive and a11y validation matrix; the screen audit with evidence levels | Widget choice; token values; wording; final quality scoring |
| `cl-ux-writing` | Bilingual voice and tone; vi / en parity; the glossary (verified / recommended / owner-decision terms); copy patterns incl. notifications and push; numbers, dates and units in text; AI and personalisation wording; ARB and localisation conventions (the `tool/*_strings.py` workflow); the copy audit and writing rubric | Layout; visuals; component choice; Lumi prompts (server) |
| `cl-design-review` | The review workflow (Understand → Inspect → Audit → Prioritise → Decide → Classify → Verify → Report; implementation loop by default, audit-only on request); the 11-dimension rubric (dimension 11: content necessity & information density, D-110) with critical gates G1–G6 and `Not evaluated`; R / C / H evidence; severity vs priority vs approval; golden-based visual verification (no baseline updates); before / after evaluation; the report template | Fixing: it recommends, and the other skills own the fix; restating their rules |

**Ownership in one line each:**

| Skill | Responsibility |
|---|---|
| `senior-ui-ux` | Overall product design workflow |
| `cl-design-foundations` | Visual tokens and design foundations |
| `cl-components` | Component selection and evolution |
| `cl-ux-writing` | Bilingual content and localisation |
| `cl-screen-patterns` | Screen composition and information architecture |
| `cl-design-review` | Final visual and UX quality assessment, evidence-based audits, before / after verification |

**Boundary rule.** When two skills seem to own a rule, the more specific one does (writing over
patterns for wording; foundations over components for values). The master skill's table records
where each rule lives.

## 4. Routing rules

The routing table lives in `senior-ui-ux` §1 and is the single copy. In summary:

| Task | Route |
|---|---|
| New screen | master → patterns → components → writing → foundations → review |
| Improve an existing screen | master → review (audit first) → relevant skills |
| Content hierarchy | master → patterns → writing → review |
| Copy only | writing → review |
| Reusable widget | components → foundations → review |
| Spacing, typography or colour fix | foundations → review |
| Audit, or "không tốt" | master → review → fix L1 / L2 (audit-only when asked) |
| Screen composition, states, charts, flows, galleries | master → patterns → review |
| Verify an implemented change (before / after) | review |
| Improve several screens / the whole app | master → multi-screen batches |
| Backend only | none |

**Every meaningful UI change ends in `cl-design-review`** (gates, rubric, before / after on
rendered goldens). If a skill were ever missing, `senior-ui-ux` keeps short essentials for it;
UI work never waits.

## 5. Autonomous workflow (D-109 … D-111)

**Discover → Verify sources → Fresh render → Audit → Simplify → Structure → Design → Implement →
Re-render → Review → Iterate → Verify**, then Report. **Fresh render = visual truth** (D-111):
stored screenshots and goldens are classified Current / Outdated / Unverified / Historical and
never assumed current; `apps/mobile/tool/golden_freshness.sh` renders the current code without
writing baselines (`cl-design-review/references/visual-verification.md` §0). Details are in `senior-ui-ux` §2. **Simplify** (D-110) is mandatory and
runs before any visual redesign: every visible element is classified Essential / Contextual /
Redundant and gets one action (REMOVE, MERGE, REWRITE, RELOCATE, PRESERVE), for words and for
visual structure. The canonical model is `senior-ui-ux/references/content-simplification.md`;
each specialised skill holds only its part (copy: `cl-ux-writing/references/simplifying-copy.md`;
structure, settings, onboarding: `cl-screen-patterns/references/compact-and-decluttered.md`;
optional content slots: `cl-components/references/component-selection.md` §5; philosophy:
`cl-design-foundations`; review dimension 11 "Content necessity & information density":
`cl-design-review/references/ux-quality-rubric.md`).

- **Discover / Audit** look things up in this order:
  1. the existing screen;
  2. the closest archetype;
  3. its reference implementation;
  4. the goldens;
  5. the component showcase.

  It also checks business decisions, vi / en, Light / Night care, states and permissions. Figma
  is optional history.
- **Design** picks **one** solution with the specialised skills. No menus of alternatives for the
  owner.
- **Implement** goes straight to Flutter, preserving behaviour (§6 protected systems), with
  strings through ARB.
- **Render** regenerates only the touched goldens and opens every PNG (all four variants, plus
  text scale and long names where a harness exists).
- **Review** runs `cl-design-review` (gates, rubric, regression of destinations, roles and
  preferences, tests).
- **Iterate** fixes what the change introduced; passing tests isn't completion.
- **Report** gives before → after images, findings, tests, limits and isolated L3 decisions, with
  a Vietnamese owner summary.

**Multi-screen work** follows `senior-ui-ux/references/multi-screen-execution.md`:

1. inventory;
2. group by feature and shared component;
3. baseline;
4. cross-screen inconsistencies;
5. prioritise by impact × frequency;
6. small verified batches;
7. shared fixes once;
8. render and regression-test each batch;
9. continue without routine approvals.

## 6. Autonomy levels and protected systems (D-109)

| Level | Scope | Owner |
|---|---|---|
| **L1 polish** | Spacing, alignment, typography, overflow, contrast, card styling, icon sizing, state presentation without behaviour change, copy within approved terms, responsive layout | No approval |
| **L2 redesign** | Section order within a screen, hierarchy, composition, fewer CTAs, density, layout restructure (major screens included), consolidated visuals, new shared components from existing tokens, clearer affordances to the same destinations | No approval while meaning, reachability, destinations, permissions, preferences and decisions are unchanged |
| **L3 decision** | Business logic, feature removal, new capability, Adaptive ranking, Customization behaviour, permissions, behaviour-changing navigation, entitlements and pricing, canonical terms, new tokens or design-system direction, legal / privacy / consent, material AI or health claims, ambiguity about user data | Required; isolate it and continue the rest |

**Protected systems:** visual work never rebuilds them, it only presents them.

- Adaptive Experience and ranking;
- User Customization (order, pinned, hidden, the Customize screen);
- visibility and age defaults;
- permissions;
- navigation behaviour;
- care tracking, reminders, sync and offline;
- entitlements;
- AI logic.

**Completion gates:**

- no new gate failure;
- no new Blocker or High;
- actions and destinations preserved;
- vi / en and Light / Night care covered;
- rendered images inspected;
- tests passing;
- limits documented;
- nothing fabricated.

## 7. Figma versus Flutter authority (D-104)

| Question | Authority |
|---|---|
| How does the current UI look and read? | The Flutter app: code, ARB, goldens |
| What does a new screen look like? | Designed in code through `senior-ui-ux`; no Figma frame needed |
| What features and rules does the product have? | `business-map.md` requirements and decisions (unchanged unless superseded) |
| Which V1 features were originally scoped? | Figma `sJLG1fAXKDnDr9YI6Yx8ex` + `figma-coverage-checklist.md` (history, kept) |
| Why was something built this way? | D-/R-/P- ids, widget doc comments, Figma as context |
| Code differs from Figma | Code wins; Figma is never restored automatically |

## 8. Future implementation order

1. ✅ **`cl-design-foundations`** (done in step 4: `SKILL.md` + six `references/`; it absorbed
   `senior-ui-ux` §5.5's foundation rules). Every other skill cites tokens and safe pairs. It also takes over
   the two design rules currently kept only in user memory (`ink` on soft warm fills; no
   secondary button in an info notice).
2. ✅ **`cl-components`** (done in step 5: `SKILL.md` + six `references/`; it replaced
   `senior-ui-ux` §5.5's interim component rules). The catalogue and the missing-component protocol stop new feature kits
   from forming. It also specifies the `ClCard` family (D-107) as a design, not as code.
3. ✅ **`cl-ux-writing`** (done in step 6: `SKILL.md` + eight `references/`; it replaced
   `senior-ui-ux` §5.3 and softened the old "never two numbers in a sentence" rule). Open owner
   decisions are listed in its glossary and audit: the canonical terms for a care entry, reminders,
   the assistant's name, the caregiver and relative role names, household vs family, and UK vs US
   English.
4. ✅ **`cl-screen-patterns`** (done in step 7: `SKILL.md` + ten `references/`; it replaced
   `senior-ui-ux` §4 and §5.1–5.2 and the state list of §5.4, which keeps only the "numbers become
   visuals" principle). Its audit names the highest-impact screens (Hôm nay, History + Stats,
   Memories selection) and an evidence gap: no text-scale or long-name goldens.
5. ✅ **`cl-design-review`** (done in step 8: `SKILL.md` + eleven `references/` + a sample review in
   `docs/design/reviews/`; it replaced `senior-ui-ux` §6's interim checklist with a gate-first
   pointer).
6. **Pilot on Hôm nay** (both the legacy and adaptive paths): an audit, then the full flow, with
   before → after goldens.
7. **Then trim `senior-ui-ux`.** Each interim section becomes a one-line pointer once its skill
   exists. Optionally add a reminder hook or a CI ratchet, with the owner's OK.

Promoting shared widgets into `lib/core/widgets` (`ClCard`, `ClNotice`, `ClStatTile`,
`ClDateTimeSheet`, an async-state wrapper …) is product code work, separate from writing the
skills.
