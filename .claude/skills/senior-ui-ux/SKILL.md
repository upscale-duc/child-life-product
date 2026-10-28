---
name: senior-ui-ux
description: Master product-design workflow for meaningful Flutter UI/UX changes and reviews in Child Life (apps/mobile). Routes to the five cl-* skills for screen structure, components, copy, foundations and rendered review. Small local fixes use targeted checks; screen work uses autonomous audit, simplify, design, implement and review with current visual evidence reused across phases. A/B prototypes are conditional on unresolved structural trade-offs. L1/L2 changes preserve behaviour and proceed autonomously; isolate L3 product decisions for the owner. Respect audit-only requests. Flutter is the current UI and copy authority; Figma is optional history.
---

# Senior product design pass — master skill (Child Life)

The owner's standard (2026-10-25): screens changed "như software developer" read badly — walls
of text, numbers in sentences, duplicated blocks, chips that contradict each other, labels that
mean something else. Every meaningful UI change goes through this skill **before** code and is
checked **as an image** after.

**Operating mode (D-109): autonomous.** Act as a trusted senior product designer and Flutter UI
engineer. Audit, decide, implement, render, review and iterate on your own. Interrupt the owner
only for a genuine product decision (L3, §3). Never for a choice between design alternatives, and
never because a redesign is visually large.

**Target.** MB Bank's information design (clear hierarchy, scan-first, action-first, meaningful
density, clear status, frequent actions within reach), wearing Child Life's own identity (warm,
calm, family-centred, minimal but not empty, readable at 3 a.m. in Night care). Borrow the
information design, never MB Bank's colours, branding or financial patterns.

**Design the experience before choosing widgets.**

**Preserving product behaviour does not mean preserving the existing layout (D-112).** The code is
the truth about behaviour, never proof of good UX. Challenge weak layouts, keep strong ones, and
don't stop at overflow and copy fixes when the hierarchy or composition is the problem.

## 0. Authority (D-104 … D-112, `docs/product/business-map.md`)

- **The Flutter app is the source of truth** for current UI and copy: the code in
  `apps/mobile/lib` and the ARB catalogs in `lib/l10n`. Goldens in `test/golden/goldens` are
  test baselines: evidence of the current UI only after a fresh run confirms them (D-111).
- **Figma (`sJLG1fAXKDnDr9YI6Yx8ex`) is optional history.**
  - It may explain why something is the way it is.
  - It is never a reason to restore an older look or older copy.
  - It is never a prerequisite for designing a screen.
- **Product requirements and owner decisions stay valid unless superseded.** Check
  `business-map.md` before changing behaviour.
- **Tokens grow only from real need** (D-106) and **cards share rules, not one look** (D-107).

## 1. Skill system and routing

This skill is the entry point and works on its own. Load an **available** skill when the route
needs it. All five specialised skills are available; if one is ever missing, fall back to this
file and the code it points to. Never block work on a missing skill.

| Skill | Owns | Status | Until it exists, use |
|---|---|---|---|
| `cl-design-foundations` | tokens, safe colour pairs, type roles, spacing / radius, elevation, motion, Night care, a11y foundations | **available** (`.claude/skills/cl-design-foundations/`) | — |
| `cl-components` | catalogue, selection, cards, actions, forms and feedback components, reuse and extension, missing-component protocol | **available** (`.claude/skills/cl-components/`) | — |
| `cl-screen-patterns` | archetypes, hierarchy, scan-first, action-first, density, dashboards, timelines, insights, forms and flows, galleries, states, responsive validation, screen audit | **available** (`.claude/skills/cl-screen-patterns/`) | — |
| `cl-ux-writing` | bilingual vi / en copy, voice and tone, glossary, CTAs, numbers in text, AI and personalisation wording, ARB and localisation, copy audit | **available** (`.claude/skills/cl-ux-writing/`) | — |
| `cl-design-review` | independent audits, gate-first rubric, R/C/H evidence, visual verification with goldens, a11y review, before/after, report template | **available** (`.claude/skills/cl-design-review/`) | — |

Load the skills a task needs, in order, skipping any that are missing:

| Task | Route |
|---|---|
| New screen | this → patterns → components → writing → foundations → review |
| Improve an existing screen | this → review (audit first) → the relevant skills |
| Add or change a section / card | this → patterns → components → writing → review |
| Improve content hierarchy | this → patterns → writing → review |
| Restructure or compose a screen; choose an archetype; design states, dashboards, timelines, charts, flows or galleries | this → patterns (→ components, writing, foundations) → review |
| Rewrite UI copy (ARB, push, toast) | writing → review |
| Name a feature or term; add ARB keys; fix plurals or localisation; AI / insight wording | writing |
| Build or change a reusable widget (`lib/core/widgets`) | components → foundations → review |
| Choose a component; about to write a new widget, card or row class | components (→ foundations for values) |
| Fix spacing, typography or colour | foundations → review |
| Challenge a layout; restructure or redesign a screen; compare design directions | this → `references/structural-evaluation.md` → patterns / components → prototypes in `test/design_explorations/` → review |
| Simplify a screen, settings or onboarding; "too much text", "cluttered" | this → `references/content-simplification.md` → writing + patterns → review |
| Audit a screen / owner says "không tốt" | this → review → fix L1 / L2 findings → review (audit-only only when the request says so) |
| Improve several screens or the whole app | this → `references/multi-screen-execution.md` → per batch: review → patterns / components / writing / foundations → review |
| Verify an implemented UI change (before / after goldens); score a screen; check a11y, Night care or vi / en layout | review |
| Backend, rules or functions only | none |

## 2. Autonomous workflow: Discover → Verify sources → Fresh render → Audit → Simplify → Structure → Design → Implement → Re-render → Review → Iterate → Verify

This is the default for meaningful UI/UX improvement tasks (D-109 … D-111). It ends with a Report.
For a small local fix, use the relevant checks directly; no full screen audit, Simplify table
or structural exploration is required. Keep essential content, behaviour and targeted rendered review.

**Render and inspection authority:** `cl-design-review/references/visual-verification.md` →
Visual evidence policy. Reuse one current render set across these phases; they are review
activities, not instructions to repeat tool calls. Automated coverage and visual coverage are
reported separately.
**Simplify always runs before visual redesign:** decide what stays visible before deciding how
it looks. **Source code is the implementation truth; a fresh render is the visual truth:** never
audit or redesign from a stored screenshot alone.

### A. Discover (understand, then look)

Write down first:

1. **Who** opens this screen (Cùng nuôi, Người chăm sóc, Người thân; a tired parent at 3 a.m.,
   a grandparent taking over), with which role, and in what moment.
2. **What** they are trying to get done.
3. **What** they must understand in **5 seconds**, and the next two things in 30 seconds.
4. **What** the most useful next action is.
5. **Which states** matter here (§4).

**Role-aware rule.** Never show the reader a state that belongs to someone else, such as a
sender's "Mình sẽ thử" or "Đã nhận bàn giao" shown to the person who gave it.

**Verify sources (D-111).** Read the current code first: routes, the screen and its widgets,
the ARB keys (vi / en), the fixtures. Find the goldens and any other images of the screen, and
classify each one **Current / Outdated / Unverified / Historical** (`cl-design-review` →
`visual-verification.md` §0). Stored images are never assumed current.

**Fresh evidence (reuse first).** If no render set remains current for the relevant inputs, run
`apps/mobile/tool/golden_freshness.sh <the screen's golden tests>` (no baseline is written):
passing baselines are Current; for each failing one the fresh render is
`test/golden/failures/<name>_testImage.png`. States without a golden: a probe test outside
`test/golden/`, or the simulator. Investigate every Outdated baseline (another session's change,
a regression, fixture drift) before relying on it; never update a baseline you didn't change.
If nothing can be rendered, mark the visual evidence Unverified and keep its findings H.

Then inspect, fresh renders first:

- **Fresh renders:** select readable images and variants by the central Visual evidence policy.
- **The code:** the screen and its components, the tokens, the ARB keys (vi / en).
- **The rules:** the business decisions in `docs/product/business-map.md`.
- **States and behaviour:** loading, empty and error states; permissions and interaction
  behaviour.

Look things up in this order: the existing screen; the closest archetype (§4); its reference
implementation; the goldens; the showcase (`lib/features/showcase/`). Figma is optional history
(`docs/discovery/figma-extract/`).

### B. Audit and prioritise

Use `cl-design-review` (gates, the rubric including **content necessity & information density**,
severity Blocker–Low, priority P0–P3). Fix trust, usability and accessibility problems before
decorative polish. Classify each change L1 / L2 / L3 (§3).

**Classify each screen KEEP / REFINE / RESTRUCTURE / REDESIGN (D-112)** across six dimensions
(information architecture, visual hierarchy, layout composition, interaction efficiency, content
simplification, visual quality): `references/structural-evaluation.md`. The decision names the
observed problems and the expected benefit; never pick a structural change by default.

### C. Simplify (mandatory, D-110)

Follow `references/content-simplification.md`:

- classify every visible element as **Essential / Contextual / Redundant**;
- give each one action: **REMOVE, MERGE, REWRITE, RELOCATE or PRESERVE**;
- audit visual structure the same way (cards, nested containers, dividers, icons, badges,
  duplicate CTAs, oversized gaps).

Prefer deleting over rewriting when the information itself is unnecessary. Minimalism never
overrides correctness: units, status, sync, timer state, warnings, validation, errors and
permission consequences stay.

### D. Structure

Arrange what survived (`cl-screen-patterns`): archetype, order by the reader's question,
grouping, progressive disclosure for genuinely contextual content, one dominant primary.

### E. Design (and explore when the structure is the problem)

- **KEEP / REFINE:** design the fixes directly.
- **RESTRUCTURE / REDESIGN:** select a direction autonomously; render A/B prototypes only
  for a material unresolved trade-off (`references/structural-evaluation.md` §3).

Then build the selected solution with the specialised skills:

- widgets from `cl-components`;
- copy from `cl-ux-writing`;
- values from `cl-design-foundations`.

**Rules:**

- Alternatives are for structural problems only (above), and they are yours to choose: never
  ask the owner to pick between design options. Record the reasoning in the report.
- Don't compensate for an unclear layout with more explanatory text.
- Reuse first; extend only by the component protocol.

### F. Implement

Build directly in Flutter with the design system (no Figma or HTML mockup needed):

- **Behaviour:** preserve product behaviour (§3 and §7: systems never rebuilt by visual work).
- **Strings:** every user-facing string goes through ARB (vi template, en with the same ids,
  via a `tool/*_strings.py` script). Remove keys only when no code uses them.
- **Shared tree:**
  - respect other sessions' uncommitted work in the shared tree;
  - never overwrite or reformat files you aren't changing;
  - sequence after edits in progress on the same files.

### G. Re-render

- Render the affected final state once and inspect the selection required by the central Visual
  evidence policy. Reuse an already-current set; add text-scale/long-content checks when relevant.
- Update only intended baselines after inspecting the selected fresh results. Keep automated
  Light/Night × vi/en coverage, and report visual coverage separately.
- Compare against current pre-edit evidence; committed images may be historical, so label them.
  Missing variants remain unverified.

Never update baselines during an audit-only request, and never update baselines you didn't mean
to change. Attribute every golden diff; select visual inspection using the central policy.

### H. Review

Run `cl-design-review` on the rendered result:

- the critical gates;
- content necessity first, then the rest of the rubric (hierarchy, scanability, interaction,
  accessibility, localisation, coherence);
- regression risk to destinations, roles and preferences.

### I. Iterate

**Self-critique is mandatory for meaningful screen changes (D-112):** reuse the current final
render set and answer the ten questions in
`references/structural-evaluation.md` §4 as an independent designer, including "is it
meaningfully better than the original?" with the before / after side by side.

Fix anything your change introduced (a gate, a Blocker or High, an overflow, a lost action, a
removed piece of Essential content) before calling it done. Passing tests isn't completion.
Pre-existing High issues that can't be fixed safely are reported, never hidden.

### J. Verify, then report

Run the relevant automated tests: `flutter analyze`, `flutter test`, and the touched golden tests
on macOS. When shared widgets changed, run the whole golden suite and attribute every diff.

Write the report for the owner:

- the screens improved and problems fixed;
- what was removed, merged or relocated (Simplify table);
- before → after images;
- review findings;
- tests run;
- remaining limitations;
- any isolated L3 decisions.

Use `cl-design-review`'s template, with a Vietnamese owner summary.

**Completion gates:**

- no newly introduced gate failure;
- no unresolved Blocker or High introduced by the change;
- every element on the changed screens passed the Simplify stage;
- actions and destinations preserved;
- automated vi/en × Light/Night covered; visual selection and omissions recorded;
- rendered images inspected;
- relevant tests passing;
- limitations documented;
- no fabricated accessibility or usability results.

## 3. Autonomy levels (D-109)

| Level | What | Owner approval |
|---|---|---|
| **L1: autonomous polish** | Removing redundant subtitles, helper lines and decorative elements; shortening labels; spacing and alignment; typography; text overflow; colour contrast; card styling; icon sizing; loading / empty / error presentation without behaviour change; bilingual copy within approved terminology; responsive layout | None |
| **L2: autonomous redesign** | Reorganising sections; information hierarchy; card composition; fewer competing CTAs; simpler widget presentation; density; restructured layouts (including major screens such as Hôm nay, Kỷ niệm, Chăm sóc, paywall); consolidating duplicated visuals; merging redundant groups; progressive disclosure of contextual content; simpler settings, onboarding, forms and lists; clearer navigation affordances to the **same** destinations; redesigning existing widgets with the same function | None, **while** business meaning is unchanged, every feature stays reachable, destinations / permissions / user preferences are unchanged, and existing product decisions are respected |
| **L3: owner decision** | Business logic; removing a feature; new product capabilities; Adaptive ranking; User Customization behaviour; permissions; navigation destinations or flows that change behaviour; subscription, entitlement or pricing; canonical terminology; new design tokens or a new design-system direction; legal, privacy or consent wording; material changes to AI or health claims; unresolved ambiguity that could misrepresent user data | Required |

**Rules:**

- **A visually substantial redesign is not, by itself, a reason to ask.** The test is behaviour
  and meaning, not size.
- **Isolate L3.** Keep the current behaviour for the L3 item, mark it "Owner decision" in the
  report with the trade-off in two or three lines, and **continue** with the L1 / L2 work around
  it. Never block a screen or a batch on one unrelated decision.
- **When unsure whether something is L2 or L3,** check `business-map.md` and the code. Treat it
  as L3 only if the change could alter what the product does or claims.
- **Record decisions.** When the owner decides an L3 item (a pattern, term, token, behaviour),
  add a D-xxx row to `docs/product/business-map.md`:
  - check the last id first, because other sessions add rows;
  - insert the row by hand (no prettier);
  - cite code paths and goldens.

  L1 / L2 work needs no D-row; its record is the report and the commit.

### Multi-screen work

For "improve all Care screens" or "review the whole app", follow
`references/multi-screen-execution.md`:

1. inventory;
2. group;
3. baseline;
4. cross-screen inconsistencies;
5. prioritise by impact and frequency;
6. small verified batches, each starting with the Simplify stage (§2 C);
7. shared fixes once;
8. render and regression-test each batch;
9. continue without routine approvals.

## 4. Screen archetypes, hierarchy, actions and states (→ `cl-screen-patterns`)

**Load `cl-screen-patterns`.** It owns the nine screen archetypes with their reference screens,
information hierarchy, dashboards (incl. Adaptive ranking), timelines, insights and charts,
forms and flows, galleries, the screen-state model, responsive and a11y validation, and the screen
audit. Its non-negotiables, in case it isn't loaded:

- **Start from the closest archetype and its reference screen,** never a blank page or a feature
  kit. Dashboard `features/today/today_screen.dart`; history `features/care/history_screen.dart`;
  stats `features/care/stats_screens.dart`; sheet form `features/care/care_sheets.dart`; flow
  `features/onboarding/setup_screens.dart`; gallery `features/memories/memories_screen.dart`;
  settings `features/me/me_screen.dart`; Premium `features/premium/paywall_v2.dart`.
- **Hierarchy:**
  - one hero at most, and a heading + compact list is often better;
  - order by urgency for the reader's role;
  - group by the reader's question;
  - density from grouping, never from smaller text;
  - disclose detail, but keep safety, consent, cost and overdue items visible.
- **Actions (D-105):**
  - one dominant primary per screen or sheet, in the thumb zone;
  - a card or row with one destination is tappable as a whole;
  - labels name the destination;
  - frequent actions are reachable;
  - undo for reversible saves; confirm for irreversible ones.
- **States:**
  - design every reachable state;
  - no loading-as-empty, no stale-as-current, no success before it is true;
  - saved locally ≠ visible to the family.

## 5. Copy, numbers and the design system (pointers + essentials)

Each specialised skill owns the detail; these subsections keep only the essentials the master
needs if a skill isn't loaded. §5.1–5.2 moved to `cl-screen-patterns` (§4 above).

### 5.3 Copy (→ `cl-ux-writing`)

**Load `cl-ux-writing`.** It owns bilingual voice and tone, the glossary, copy patterns,
numbers in text, AI / personalisation wording, ARB conventions and the copy audit. Its
non-negotiables, in case it isn't loaded:

- vi and en are both native-quality, with the same meaning, certainty and placeholders;
- glossary terms only; changing a canonical term needs the owner (§3);
- plain words on everyday surfaces, precise technical terms where they are more accurate;
- never change verified business meaning;
- buttons are verbs that name the result;
- every string goes through ARB (both files, `@description`), with en plurals.

### 5.4 Numbers become visuals (principle; patterns in `cl-screen-patterns`)

- **Use a visual when it improves scanning, comparison or a decision.** Keep numbers in a natural
  sentence when that is clearer ("Bé ngủ từ 20:30 đến 06:00" is fine).
- **Every number answers a question,** with its period and basis. Predictions are approximate
  ("khoảng"). AI is labelled and kept apart from facts. No invented clinical thresholds.
- **Attention uses the warm palette** (sunshine / peach soft + `colors.ink`); danger only for real
  danger; never colour alone.
- **Forms by question:**
  - stat tiles for how much;
  - a range or delta for "compared with usual";
  - relative + clock for when;
  - a 24 h strip for a day;
  - 7 bars for a week;
  - "khoảng" + a progress bar for what's next.

  Details and references: `cl-screen-patterns` → `insights-and-data-visualization.md`; wording:
  `cl-ux-writing` → `numbers-dates-and-units.md`.

### 5.5 Build with the design system (→ `cl-design-foundations`, `cl-components`)

**Foundations: load `cl-design-foundations`.** It owns tokens, safe colour pairs, type roles,
spacing, radius, surfaces, motion, Night care, accessibility and the token-evolution protocol
(D-106). Its non-negotiables, in case it isn't loaded:

- no new raw colour, size, radius or spacing literals;
- `ink` (never `onWarm`) on `sunshineSoft` / `peachSoft`;
- no text on `mint`;
- colour never carries meaning alone;
- 44 pt targets;
- check Night care on every change.

**Components: load `cl-components`.** It owns the verified component catalogue, the selection
trees, the proposed `ClCard` family (not implemented), actions, forms and feedback, and the
missing-component protocol. Its non-negotiables, in case it isn't loaded:

- reuse the closest *suitable* component (D-107);
- never start a new feature-prefixed kit or a private duplicate card or row;
- no `showModalBottomSheet`, `AlertDialog`, `SnackBar`, bare spinners or Material `Icons.*`;
- a card or row with one destination is tappable as a whole.

## 6. Review (→ `cl-design-review`)

**Load `cl-design-review`.** It owns the review workflow, the gate-first rubric, the R / C / H
evidence levels, severity vs priority vs approval, golden-based visual verification, before /
after evaluation and the report template. Its quick check, in case it isn't loaded:

- [ ] **Content necessity:** every visible element earns its place; no subtitle that restates
      its title, no text explaining an obvious action, no decorative container; Essential
      content (units, status, warnings, errors) kept.
- [ ] **Gates:** no misleading business meaning (loading as empty, local as shared, uploaded as
      ready, AI as fact); critical actions reachable; no silent data loss; permissions respected;
      no unsupported health or AI claims; the primary task works.
- [ ] Purpose, current state and next action are discoverable quickly. A hero isn't required,
      and not everything must fit above the fold.
- [ ] One dominant primary; labels match destinations; modes (select vs add) visible.
- [ ] Rendered review follows the central Visual evidence policy; automated coverage, visual
      coverage and unverified variants are distinguished.
- [ ] Every finding has evidence (R / C / H) and a user consequence; nothing scored without
      evidence.

## 7. Product systems that visual work never rebuilds

Improve their **presentation** only. Any change to how they behave is L3:

- Adaptive Experience and Adaptive ranking (`rankToday`, `adaptiveTodayProvider`, band defaults,
  goals, usage / recency signals);
- User Customization (manual order, pinned, hidden, shown, the Customize screen and its entry
  point), and preferences across age transitions;
- widget visibility and age-based defaults;
- permissions and roles;
- navigation behaviour and destinations;
- care-tracking logic, reminders, sync and offline behaviour;
- subscription entitlements and pricing;
- AI business logic and health claims.

A prototype or redesign consumes these systems' outputs read-only (e.g. it draws exactly the
widgets `adaptiveTodayProvider` returns, in that order).
