# Before / after evaluation

Use it after an implementation has been made (L1 / L2 autonomously, L3 after the owner's decision). The question is
whether the change actually improved the experience, judged on rendered evidence.

## 1. Hold everything constant

Compare **the same**:

- screen;
- role;
- child;
- data fixture;
- locale;
- theme;
- viewport;
- text scale;
- state.

If any of these differs, say so: the comparison is **Inconclusive** for the affected question.

**How (no baseline overwrite):**

- **Before** = the current pre-edit render. A committed golden may be historical; label it:
  `git show HEAD:apps/mobile/test/golden/goldens/<path>.png`
  redirected into a scratch file outside the repo, or the PR's base image.
- **After** = the golden produced by the change:
  - before the change updates baselines, run the comparison and open
    `apps/mobile/test/golden/failures/<name>_testImage.png`;
  - after the implementation updates the touched baselines, use the new PNG (inspect and attribute differences under the central visual policy).
- **Compare matched pairs** selected by `visual-verification.md` → Visual evidence policy.
  Reuse existing images/observations and link evidence; no duplicate galleries per phase.

## 2. Evaluation questions (answer each with evidence)

1. Is the primary takeaway easier to find (first fixation, five-second test)?
2. Is the next action clearer (one dominant, a label that names the result)?
3. Is there less redundant content?
4. Are important values easier to scan (size, units, no truncation)?
5. Is interaction ambiguity reduced (modes, whole-card taps, select vs add)?
6. Are error, loading and pending states more accurate (C: the code path, R: the variant golden)?
7. Does the layout work in both languages (no new wrapping or truncation)?
8. Any accessibility regressions (targets, contrast, semantics in code, text-scale if renderable)?
9. Does it still feel like Child Life (warm, calm, care colours used meaningfully)?
10. Did any useful information disappear? (Compare element by element.)

## 3. Outcome

| Outcome | When |
|---|---|
| **Improved** | The targeted finding is resolved in every inspected variant, and no new Medium-or-worse issue appears |
| **No meaningful change** | The finding persists or the change is cosmetic only |
| **Regressed** | A new issue of equal or higher severity, lost information, or a failed gate |
| **Inconclusive** | Not comparable (different fixture, missing variants) or the question needs a device or user test |

Each outcome lists:

- the image paths compared;
- the variants covered;
- the findings resolved or introduced;
- the re-scored rubric dimensions (same coverage as before).

## 4. Honesty rules

- **A cleaner-looking screen isn't automatically more usable.** Tie the outcome to the
  questions above.
- **Never claim measured improvements** (task time, comprehension, conversion, retention,
  performance) unless they were measured. Say "expected benefit" for reasoning, "measured" only
  for measurements.
- **Tests passing and the code changing** are not evidence of improvement.
- **Report unverified variants** (text scale, long names, devices) as unverified, after as well as
  before.
