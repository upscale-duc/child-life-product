# Review report template

Use it for a **quick review** (one screen; sections 1–4 + 8, short) or a **comprehensive audit**
(several screens; all sections, one scorecard per screen). Leave out sections that have no content
(e.g. §6 without an implementation); **don't invent open questions** to fill §7.

Save reports in `docs/design/reviews/YYYY-MM-DD-<screen>.md` when the owner wants them kept; quick
reviews can stay in chat.

```markdown
# Design review — <Screen> (<archetype>) · <date>

## 1. Executive summary
- Screen: <name> (`<file>`), archetype <A–I>, roles reviewed: <…>
- User job: <one sentence>
- Overall assessment: <verdict line from the rubric, gates first>
- Top problems: <2–4 bullets, each with its consequence>
- Main recommendation: <one sentence>

## 2. Evidence coverage
| Source | Inspected |
|---|---|
| Code | <files:lines> |
| Automated golden coverage | <command/result, locale × palette × state> |
| Visually inspected | <paths, variants and regions actually opened> |
| Reused / sampled evidence | <current render set; sampling rationale and omissions> |
| Visually inspected locales | vi ✓/✗ · en ✓/✗ |
| Visually inspected themes | Light ✓/✗ · Night care ✓/✗ |
| States | <loaded, first run, offline, …> |
| Roles / age bands | <…> |
| Not evaluated | <text scale, long names, small screen, device, screen reader, motion …> |

## 3. Scorecard
Critical gates: G1 <pass/fail/n.e.> · G2 … · G3 … · G4 … · G5 … · G6 …
| # | Dimension | Score (0–5 / Not evaluated) | Coverage | Note |
|---|---|---|---|---|
| 1 | Task clarity | | | |
| … | | | | |
| 10 | Product identity | | | |
Verdict: <…>  (mean shown only alongside gates and lowest dimensions, excluding "Not evaluated")

## 4. Findings
| ID | Screen | User job | Observed issue | Evidence (R/C/H) | Reference | User impact | Severity | Priority | Improvement (done / ready / owner decision) | Autonomy (L1/L2/L3) | Confidence |
|---|---|---|---|---|---|---|---|---|---|---|---|

## 5. Recommended improvements
Grouped by status and dependency: "done in this change (L1 / L2)", "ready to implement (L1 / L2, audit-only)", "owner decision (L3)", "depends on ClCard".

## 6. Before / after verification   (only with implementation evidence)
| Variant | Before | After | Outcome | Notes |

## 7. Open questions   (only genuine decisions or verifications)

## 8. Tóm tắt cho chủ sản phẩm (tiếng Việt, không dùng thuật ngữ kỹ thuật)
- Vấn đề là gì?
- Vì sao quan trọng với ba mẹ?
- Nên thay đổi gì?
- Phụ huynh sẽ thấy khác biệt gì?
```

**Writing rules:**

- **Each finding:** a concrete element + problem + consequence. No "improve spacing", "cleaner",
  "more modern", "more premium".
- **Quote rendered text exactly;** cite golden paths and file:line.
- **Map cross-skill findings** to their existing ids (e.g. `cl-ux-writing` audit #1,
  `cl-screen-patterns` audit #4) instead of re-describing them.
- **Recommendations name the owning skill** for the fix (patterns, components, writing,
  foundations).
- **No invented metrics or test results.**

A full worked example is in `docs/design/reviews/2026-10-25-today-adaptive.md`.
