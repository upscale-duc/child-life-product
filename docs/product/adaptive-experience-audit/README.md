# Adaptive Experience Audit: Child Life across childhood (2026-10-30)

An audit-only package. No production code, Figma, flags, schema or baseline was changed.

**Snapshot:** branch `s2-onboarding`, HEAD `83343e85`, plus a working tree with other sessions' uncommitted changes (assistant, keepsakes, vaccines, rhythm). Findings cite code as it reads in that tree. Remote Firebase state (which families have which flags on) was **not** read, so every statement about rollout is about code defaults.

**Builds on, does not repeat:**
- [Adaptive Experience plan](../adaptive-experience-plan.md) (D-097): the engine, goals, bands, AX screens, phases A–E. Most of what this brief asks for is already designed and built there.
- [Product & technical audit, 2026-10-20](../../product-audit/00-executive-summary.md): data integrity P0s, CH-01/CH-02, memory campaigns, late onboarding.
- [Business map](../business-map.md) D-097 … D-141.

| # | Document | What it answers |
|---|---|---|
| 01 | [Executive summary](01-executive-summary.md) | Maturity, top findings, the 15 strategic questions |
| 02 | [Current product audit](02-current-product-audit.md) | Inventory with code references and the findings register (AXA-xx) |
| 03 | [Age-based needs matrix](03-age-based-needs-matrix.md) | What families need at CH01–CH04, evidence vs hypothesis |
| 04 | [Feature × age matrix](04-feature-age-matrix.md) | KEEP / ADAPT / EXTEND / BUILD / DEFER / RECONSIDER per feature |
| 05 | [Onboarding audit](05-onboarding-audit.md) | Current flow, friction, age-aware variant, progressive profiling |
| 06 | [Adaptive Today & navigation](06-adaptive-today-and-navigation.md) | Five reference Todays, IA option A/B/C |
| 07 | [Feature personalization spec](07-feature-personalization-spec.md) | Level 0–3 per feature |
| 08 | [Content & UX writing](08-content-ux-writing-strategy.md) | Terminology across ages, bilingual matrix |
| 09 | [Lumi & insights](09-lumi-insights-strategy.md) | Rules vs recommendation vs AI, context, safety |
| 10 | [Memories across childhood](10-memories-across-childhood.md) | Memories as the cross-age anchor |
| 11 | [Personalization architecture](11-personalization-architecture.md) | Layers, gaps, pseudocode, tests, migration |
| 12 | [Prioritized roadmap](12-prioritized-roadmap.md) | P0–P3, phases 0–4, acceptance criteria |
| 13 | [UX/UI design brief](13-ux-ui-design-brief.md) | Screens, variants, components, edge cases |
| 14 | [Decision log](14-decision-log.md) | Proposed decisions, open questions (L3 for the owner) |

**Labels used throughout:** **Fact** = read in code or docs, with a path. **Finding** = a problem with evidence. **Proposal** = a recommendation. **Hypothesis** = needs validation with families or data. Priorities are P0–P3 ([12 §1](12-prioritized-roadmap.md)); confidence is High / Medium / Low.

Content in this package about child development is product framing drawn from public guidance (WHO, CDC, AAP). It has **not** been reviewed by a clinician, and it must not ship as advice without review (D-073 pattern, D-141 §4).
