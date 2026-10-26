# Issue severity and prioritisation

Three independent labels per finding:

- **UX severity:** how badly it hurts the user;
- **implementation priority:** how soon to fix it;
- **autonomy level:** whether Claude Code implements it (L1 / L2) or the owner decides (L3).

**Never collapse them into one.**

## 1. UX severity (justify it with evidence + a consequence)

| Level | Definition | Child Life examples |
|---|---|---|
| **Blocker** | A critical gate fails, or the primary task or a safety action is impossible or misleading | A critical action unreachable at large text; "shared with family" while only saved locally; AI states a diagnosis; data can be lost without warning |
| **High** | An important task is significantly impaired or trust is damaged | An important reminder time unreadable (truncated); loading displayed as "no records"; an en plural broken on a main summary; a role offered an action it can't take |
| **Medium** | Noticeable friction or inconsistency that users work around | Two names for one concept across Today variants; a selection bar covering items; a non-tappable chip that looks tappable |
| **Low** | Minor polish with little effect on the task | A spacing or decorative inconsistency; a spelling variant; a summary sentence that restates a chart |

## 2. Implementation priority

| Level | Meaning |
|---|---|
| **P0** | Immediate: fix before or with the next release |
| **P1** | The next improvement cycle |
| **P2** | Planned improvement |
| **P3** | Backlog |

**Weigh:**

- severity;
- **frequency** (Today and logging are daily, onboarding once);
- **reach** (all roles or one);
- **safety or trust risk**;
- **confidence** (R / C over H);
- dependencies (e.g. the `ClCard` family, an owner term decision);
- effort.

**Rules:**

- Severity ≠ priority. A frequent High issue (Today reminders truncation) can come before a rare
  Blocker in an optional flow, subject to product judgement.
- **Never downgrade a genuine safety-critical issue** (health, emergency, data loss, permissions)
  because it is rare. Safety Blockers are P0.
- Low-confidence (H) findings get a verification task first, not a fix.
- Cosmetic consistency (e.g. hand-rolled card radii) never outranks confusion or trust issues.

## 3. Autonomy level (from `senior-ui-ux` §3, D-109)

| Level | Applies to | Owner approval |
|---|---|---|
| **L1** | Spacing, alignment, typography, overflow and truncation, contrast, card styling, icon sizing, loading / empty / error presentation without behaviour change, copy within approved terminology, responsive layout, test-only coverage | No |
| **L2** | Section reorganisation, hierarchy, card composition, fewer competing CTAs, simpler presentation, density, layout restructure (major screens included), consolidating duplicated visuals, clearer affordances to the same destinations, redesigning existing widgets with the same function | No, while business meaning, reachability, destinations, permissions, preferences and existing decisions are unchanged |
| **L3** | Business logic, feature removal, new capability, Adaptive ranking, Customization behaviour, permissions, behaviour-changing navigation, entitlements and pricing, canonical terminology, new tokens or design-system direction, legal / privacy / consent, material AI or health claims, ambiguity that could misrepresent data | **Yes.** Isolate it and continue the rest |
| **Needs behavior verification** | Any change whose meaning can't yet be confirmed against the code or rules | Verify first, then classify |

The autonomy level is independent of severity and priority. A Blocker can be L1 (fix now
without asking); a Low can be L3 (a term change).

## 4. Confidence

| Level | When |
|---|---|
| **High** | R and / or C, with an unambiguous consequence |
| **Medium** | R or C, but the user consequence is inferred |
| **Low** | H only, or the intent may be deliberate (ask) |
