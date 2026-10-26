# UX quality rubric

Ten dimensions, each scored **0–5**, or **`Not evaluated`** when the evidence doesn't cover it.
**Critical gates are checked first and override any score.**

## 1. Anchors (all dimensions)

| Score | Meaning |
|---|---|
| **0** | Critical failure: the dimension makes the task impossible or misleading |
| **1** | Major problems: most users hit them; workarounds needed |
| **2** | Noticeable friction: users succeed, but slowly or with doubt |
| **3** | Acceptable: works; minor issues |
| **4** | Strong: clear and efficient; only polish left |
| **5** | Excellent: a reference other screens should copy |

## 2. Dimensions, with Child Life examples

| # | Dimension | Measures | Example 5 (from the app) | Example ≤ 2 |
|---|---|---|---|---|
| 1 | **Task clarity** | Is the purpose and the 5-second answer obvious? | History: title + day strip + "Đã ghi hôm nay" summary (`s6/20_history`) | A screen whose title is a feature name and whose first viewport is promos |
| 2 | **Information hierarchy** | Do the most important information and action win attention? | Handover: state hero → latest → "Tiếp theo" → AI collapsed (`ai/su01_ai`) | Three equally loud cards, the overdue item last |
| 3 | **Scanability and density** | Can meaning be extracted without reading paragraphs? | Sleep stats tiles + bars (`s6/20h_sleep_stats`) | Four numbers in one sentence; a wall of explanation |
| 4 | **Interaction clarity** | Are controls, gestures and modes obvious? | Bottle sheet: presets, defaults, one primary (`s4/22_bottle`) | Select vs add look alike; a button inside a tappable card |
| 5 | **Navigation and flow** | Can the task finish without unneeded steps or dead ends? | Quick log → sheet → toast + undo | Links that go somewhere unexpected; a back that signs out unannounced |
| 6 | **Visual coherence** | Do type, spacing, grouping and components work together (`cl-design-foundations`, `cl-components`)? | Me: grouped rows, consistent values (`s11/13a_me_parent`) | Mixed radii and paddings; nested shadows; off-system widgets |
| 7 | **Content and localisation** | Is copy accurate and natural in vi **and** en (`cl-ux-writing`)? | Handover predictions with basis in both languages | "1 feeds"; vi / en meaning differs; system words where plain is accurate |
| 8 | **States and trust** | Are loading, empty, offline, sync, AI, permission and stale states accurate? | Offline Today: banner + per-tile "Chờ đồng bộ" (`s4/9a_today_offline`) | Loading shown as "no records"; "shared" before upload processing |
| 9 | **Accessibility and adaptability** | Targets, contrast, semantics, text scale, long content, Night care | Core rows that wrap at 200 % | Truncated key values; colour-only status; fixed heights around text |
| 10 | **Product identity** | Does it feel like Child Life: warm, calm, family-centred, trustworthy? | Memories journal with author, time and audience | Alarm-red for routine overdue items; pressure in Premium; clinical tone |
| 11 | **Content necessity & information density** (D-110; review right after the gates, before visual polish) | Does every visible element help the reader understand, decide or act? Is anything redundant, decorative or repeated; is anything Essential missing? | Bottle sheet: one prefill note, presets, one primary, nothing restating the title (`s4/22_bottle`) | Subtitles that restate titles; "Vì: Luôn có" ranking reasons; a paragraph above a group of switches; a card inside a card; an icon beside every row |

## 3. Critical gates (pass / fail / not evaluated)

A **fail on any gate** makes the overall verdict **"Fails critical gate"**, whatever the scores.
Report gates **before** scores.

| Gate | Fails when |
|---|---|
| **G1 Business meaning** | The UI states something the implementation doesn't do (saved vs shared, uploaded vs ready, an action that doesn't exist), or reinterprets a rule |
| **G2 Critical action access** | A primary or safety action (log, save, call 115, cancel a timer, restore) can't be reached, read or operated, including via a screen reader or at 200 % text |
| **G3 Data-loss risk** | An irreversible loss can happen without a warning or undo, or the UI hides that something wasn't saved |
| **G4 Permissions** | A role sees or is offered actions the rules deny, or another person's state is shown as theirs |
| **G5 AI and health claims** | AI or an insight presents interpretation as fact, predicts with false certainty, diagnoses, or uses invented clinical thresholds |
| **G6 Primary task usability** | The screen's main job can't reasonably be completed (a broken flow, a blocked control, unreadable essential data) |

**Gate evidence:**

- **R** or **C** can fail a gate.
- **H** alone can't. It becomes "gate at risk, needs verification".

## 4. Evidence completeness

For each dimension record its **coverage**: which locales, themes, states, roles and text scales
were actually seen.

- **No evidence for a dimension** → `Not evaluated`. Never a neutral 3.
- **Partial evidence** → score what was seen and state the coverage ("3, vi + en Light only").
- **Accessibility from default goldens only** can't score above 3, and must say "text scale /
  screen reader not evaluated".
- **Don't average across `Not evaluated`.**

## 5. Summary format

```
Critical gates: G1 pass · G2 pass · G3 pass · G4 not evaluated · G5 pass · G6 pass
Scores (coverage): 1 Task 4 (vi/en, L/N) · 2 Hierarchy 3 · 3 Scan 3 · 4 Interaction 3 · 5 Flow Not evaluated ·
  6 Coherence 3 · 7 Content 2 · 8 States 2 (code) · 9 A11y 2 (default text only) · 10 Identity 4
Lowest dimensions: 7, 8, 9
Verdict: Acceptable with High-severity issues   |   Fails critical gate (G1)   |   Strong
```

**Rules:**

- **The verdict follows the gates first, then the lowest important dimensions.** A mean may be
  shown, but **never alone** and never including `Not evaluated`.
- **Scores describe the screen as rendered and coded now,** not as intended.
- **Re-score after an implementation** only with the same coverage (`before-after-evaluation.md`).

## 6. Content necessity & information density (dimension 11)

Mandatory on every review, **before** visual polish is judged (`senior-ui-ux` →
`references/content-simplification.md`).

- **Content:** Can any text be removed entirely? Are subtitles necessary? Are labels repetitive?
  Is the language natural for parents? Are technical or internal concepts exposed? Is Essential
  information (units, status, sync, timer state, warnings, errors, consequences) preserved?
- **Layout:** Unnecessary cards or nested containers? Logical grouping? Intentional spacing?
  Actions easy to find? Easy to scan?
- **Interaction:** Primary action obvious? Controls understandable? Interaction hints necessary
  and accurate? Consequential actions clear?
- **Accessibility:** Essential controls labelled? Large text readable? Targets 44 pt? Meaning
  without colour alone? Does simplification keep screen-reader meaning?
- **Localisation:** vi and en both concise and natural, same meaning, no truncation?

Anchors: **5** nothing to remove, nothing Essential missing; **3** a few redundant lines or one
decorative container; **1** walls of explanation, repeated headings and subtitles everywhere;
**0** Essential information removed or buried (also a G1 / G6 risk). A finding here names the
element, its class (Redundant / Contextual) and the action (REMOVE / MERGE / REWRITE / RELOCATE).
