# Structural evaluation and design exploration (D-112)

> **Preserving product behaviour does not mean preserving the existing layout.**

Business rules, permissions, data semantics, navigation contracts and established capabilities
stay. Information hierarchy, grouping, composition, component structure, density, emphasis,
interaction presentation, disclosure, action placement and responsive behaviour may all be
redesigned autonomously when the evidence justifies it. The current widget tree is the truth about
**behaviour**, never proof of good UX. Fixing overflow and copy on a weak layout is not done.

## 1. Classify every screen under review

| Decision | When | What happens |
|---|---|---|
| **KEEP** | The layout already serves the primary task well | Fix verified defects only |
| **REFINE** | The structure is sound; spacing, type, alignment, copy, a11y, consistency or states need work | L1 / L2 fixes in place |
| **RESTRUCTURE** | The information architecture or layout adds friction: wrong grouping or order, competing elements, weak action hierarchy, needless scrolling, poor density, wrong composition (grid vs list vs timeline) | Explore A / B (§3), pick, implement |
| **REDESIGN** | The interaction model or composition substantially undermines usability | Explore A / B (§3) with a genuinely different structure, pick, implement |

Never pick RESTRUCTURE or REDESIGN by default. Each decision names the observed problems (with
fresh-render evidence) and the expected user benefit. A well-designed screen is kept: **don't
confuse activity with improvement.**

## 2. Six dimensions (assess each, on fresh renders)

| Dimension | Ask |
|---|---|
| **A. Information architecture** | Organised around the user's goals? Related items grouped? The most important thing discoverable? Secondary details de-emphasised? Too many decisions at once? |
| **B. Visual hierarchy** | One focal point? Primary action dominant? Equal emphasis where importance differs? Does type carry importance? Balanced? |
| **C. Layout composition** | Is the layout right for the content (list, grid, timeline, grouped section)? Are cards and containers useful? Nested surfaces? Spacing consistent without dead space? |
| **D. Interaction efficiency** | Taps for the primary task? Common actions in reach? Discoverable controls? Needless confirmations? One-handed comfort? |
| **E. Content simplification** | Remove before rearranging (`content-simplification.md`): repeated subtitles, obvious explanations, content that belongs only to a state; structure instead of text |
| **F. Visual quality** | Calm, warm, polished? Consistent with Child Life? Colour with meaning? Contrast? One product, not unrelated cards? |

These complement the `cl-design-review` rubric (gates, 11 dimensions); the classification and the
six dimensions are recorded in the report's before assessment.

## 3. Exploration (RESTRUCTURE / REDESIGN only)

- **Two meaningfully different directions:**
  - **A — Refined existing:** improve the current structure with minimal disruption;
  - **B — Structural alternative:** different grouping, hierarchy, component composition or
    interaction presentation.

  Variants that differ only in colour, spacing or radius don't count.
- **Both preserve behaviour:** same capabilities, destinations, permissions, data, preferences;
  every existing action stays reachable and discoverable.
- **Owner-set orders and groupings are decisions, not layout.** Check `business-map.md` before
  reordering (e.g. D-069 / D-083 / D-085 fix the order of Chăm sóc's sections and rows). A
  composition change (grid → list) is L2; changing a decided order is L3: keep it and report the
  recommendation. Tests that assert an order usually cite the decision.
- **Render real Flutter prototypes**, isolated from production, on production-like fixtures and
  the real providers (read-only): `apps/mobile/test/design_explorations/<topic>/` (pattern:
  `today_v2/`), output in that folder. Render vi / en × Light / Night care, plus 200 % text for
  the candidates. Open every image.
- **Select autonomously** (L1 / L2), using judgement aided by these weights:

  | Criterion | Weight |
  |---|---:|
  | Primary task efficiency | 25 % |
  | Information hierarchy | 20 % |
  | Clarity and simplicity | 20 % |
  | Interaction quality | 15 % |
  | Visual quality | 10 % |
  | Consistency and accessibility | 10 % |

  No fabricated usability numbers. If the evidence is inconclusive, choose the lower-risk
  direction and record the uncertainty. Never ask the owner to choose between directions; L3 only
  for business logic, removed capabilities, permissions, data semantics, new features, material
  navigation behaviour or product strategy.
- **KEEP / REFINE screens** don't get alternatives; the report says why a larger change isn't
  needed.

## 4. Self-critique after implementing (mandatory)

Render the real screen again and review it as an independent designer:

1. Is the primary task immediately clear?
2. Is the most important content visually dominant?
3. Is anything repeated?
4. Too many cards, labels or colours?
5. Can the task be done more efficiently?
6. Does it work in vi and en?
7. In Light and Night care?
8. At large text sizes?
9. Did the change add interaction friction?
10. Is it meaningfully better than the original (show the before / after)?

A material issue means another iteration, even when the tests pass.

## 5. Report

`cl-design-review` template plus, per screen: the main goal, problems, classification and
reasoning; for structural changes the A / B renders, strengths, weaknesses and the selection;
before / after renders (vi / en, Light / Night care, relevant states, large text).
