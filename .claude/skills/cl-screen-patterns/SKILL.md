---
name: cl-screen-patterns
description: Screen composition and information architecture for Child Life (Flutter, apps/mobile). Use when designing, restructuring, reviewing or "improving" a whole screen or section — Today / dashboards, care history and timelines, stats and insights, logging sheets and forms, onboarding and multi-step flows, memories galleries, settings, Premium / paywall, Lumi and AI summaries — and when deciding what goes first, what to group, what to hide behind a tap, which archetype fits, how the layout handles empty / loading / error / offline / pending / role / multi-child / long-content states, or how numbers and charts should be presented. Routed from senior-ui-ux; uses cl-components for widgets, cl-design-foundations for values, cl-ux-writing for wording.
---

# Child Life screen patterns

**The goal is meaningful density, clarity and effortless interaction, not minimalism.** A screen
may be rich, compact or detailed when its job needs it. Dashboards, galleries, insights and forms
should feel different; consistency comes from foundations and components, not one layout. The
Flutter app is the source of truth (D-104), and **rendered UI is the final evidence:** look at the
goldens, not just the Dart.

## Ten questions for any screen

1. **Who** uses it (role, moment, tired or at night), and what is their **primary job**?
2. What must they understand in **5 seconds**: the takeaway, the current state, the next action?
3. What should they **do next**? There is one dominant action (D-105); cards and rows with one
   destination are tappable as a whole.
4. What deserves the **most attention**? One hero at most; a heading + compact list is often
   better.
5. What belongs **together**? Group by the reader's question, not by data type.
6. What can be **disclosed later**? Detail, history, AI and methodology can. Safety, consent,
   cost, data-loss and overdue items stay visible.
7. Which **archetype** fits (`references/screen-archetypes.md`), and which reference screen
   implements it?
8. How does it look in **every state** (`references/screen-states.md`)?
9. How does it adapt to **little and lots of data**, several children, roles and age bands?
10. Does it hold in **vi + en × Light + Night care**, at large text, with long names?

## Non-negotiables

- **Product design before widgets.** Write the job and the 5-second answer first.
- **Verified behaviour only.** Don't invent functionality, sync states or rules.
  - Saved locally ≠ visible to the family. For care records, pending = `hasPendingWrites`.
  - Media "uploaded" ≠ ready.
  - Never show stale data as current; never claim success early.
- **Respect the existing engines.** Adaptive Today order comes from `rankToday`
  (`features/adaptive/adaptive_engine.dart`, D-097); legacy order from `TodayLayout`. Don't add a
  third.
- **Both Today paths:** patterns must hold in the legacy and the adaptive path while both exist.
- **Numbers answer questions.** Every number has a period and a basis; predictions stay
  approximate; AI is labelled and kept apart from facts; no invented clinical thresholds.
- **Density never comes from smaller text.**
- **The current layout is not the design (D-112).** When grouping, order or composition causes
  friction, compare compositions (grid vs grouped list vs timeline vs sections by frequency) as
  rendered prototypes and pick on evidence (`senior-ui-ux/references/structural-evaluation.md`).
  Equal visual weight for unequal importance or frequency is a hierarchy defect.
- **Every element earns its place (D-110).** Simplify before structuring: no card inside a card,
  no decorative container around one row, no heading that repeats the title, no restating
  subtitles, contextual help only where it applies. Essential content stays visible
  (`references/compact-and-decluttered.md`).
- **Modes are visible:** browse vs select vs fill; a selection control never looks like "add".
- **Implementation status matters:** use `cl-ux-writing`'s glossary statuses. Proposed features
  (e.g. new remember-2 templates, Plus / Pro tiers) aren't designed into the app as if they
  existed.

## Workflow inside `senior-ui-ux`

| Phase | Use |
|---|---|
| Inspect | A **fresh render** of the current screen (`apps/mobile/tool/golden_freshness.sh`; goldens are baselines, not proof of the current UI, D-111), then the archetype reference |
| Simplify | `compact-and-decluttered.md` (structure) + `cl-ux-writing` → `simplifying-copy.md` (words) |
| Structure | `information-hierarchy.md` + the archetype file |
| Compose | `cl-components` for widgets |
| Write | `cl-ux-writing` for the words |
| Review | `screen-pattern-audit.md` rubric items + `responsive-and-accessibility.md` §6 |

**Autonomy (`senior-ui-ux` §3, D-109):**

- **Done without asking the owner:**
  - L1: layout fixes (truncation, grouping, spacing, skeletons, empty states);
  - L2: restructuring a screen's hierarchy and composition, major screens included, as long as
    every feature stays reachable and destinations, permissions, preferences, Adaptive ranking
    and Customization behave as before.
- **L3, owner decision:** changing a navigation destination or flow behaviour, the ranking, or a
  canonical term. Isolate it and continue.

## References

| File | Load when |
|---|---|
| `references/screen-archetypes.md` | Starting or restructuring any screen: nine archetypes with jobs, hierarchy, density, actions, states, references |
| `references/information-hierarchy.md` | Deciding order, emphasis, grouping, density form, disclosure |
| `references/dashboards-and-overviews.md` | Today, Care hub, Explore, Family, Me; adaptive ranking; dynamic composition |
| `references/timelines-and-history.md` | Chronological screens, day grouping, durations, overlaps, filters, large datasets |
| `references/insights-and-data-visualization.md` | Stats, charts, trends, predictions, AI insights, missing or small data |
| `references/forms-and-multistep-flows.md` | Logging sheets, defaults, validation, save / undo, onboarding and wizard flows |
| `references/galleries-and-memories.md` | Photos, journal, albums, Memory Story video, milestone cards, selection modes |
| `references/screen-states.md` | Loading, empty, error, offline, pending, processing, role, first run, multi-child, subscription |
| `references/responsive-and-accessibility.md` | Small or large phones, text scale, long strings and names, screen-reader order, validation matrix |
| `references/compact-and-decluttered.md` | Every screen change (Simplify stage): compact presentation, honest progressive disclosure, containers / headings / dividers / icons / badges, settings and onboarding rules, forms and lists |
| `references/screen-pattern-audit.md` | Strengths to keep, 17 findings with evidence levels, and the highest-impact screens |

## Before finishing a screen change

- [ ] Job, 5-second answer and next action written down; visible in the first viewport.
- [ ] Archetype chosen; the reference screen consulted; no third ordering engine.
- [ ] One hero at most; sections grouped by the reader's question; nothing duplicated.
- [ ] Simplify stage done: no redundant text, nested cards, repeated headings or decorative
      icons / badges; Essential content still visible.
- [ ] Every reachable state designed; no loading-as-empty; no stale-as-current.
- [ ] Rendered and looked at: vi / en × Light / Night care, plus text scale and long names where
      possible. Unverifiable checks reported as such.
