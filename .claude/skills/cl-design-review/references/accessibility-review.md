# Accessibility review

The foundations (targets, contrast pairs, type, motion) are in `cl-design-foundations` →
`accessibility.md` and `colors-and-themes.md` (computed contrast table). Screen-level adaptation is
in `cl-screen-patterns` → `responsive-and-accessibility.md`. This file is the **review procedure**.

## 1. Four kinds of check: label which one you did

| Kind | What it can establish | How |
|---|---|---|
| **Static code** | Widgets used (`ClPressable` ⇒ 44 pt), semantics labels present, `header: true`, `ExcludeSemantics`, `liveRegion`, fixed heights around text, colour-only status, `context.motion` use | Read the screen and component code |
| **Rendered visual** | Contrast of what is drawn (compare to token pairs), truncation and wrapping in vi / en, Night care readability, selected states visible | Goldens: Light / Night × vi / en |
| **Automated test** | Behaviour asserted in widget tests: semantics (`tester.getSemantics` / `ensureSemantics`) or Flutter guideline matchers (`meetsGuideline(androidTapTargetGuideline)`, `textContrastGuideline`) | **Verified 2026-10-25: no test uses the guideline matchers;** two tests touch semantics. Adding them is an authorised test change; until then this column is usually empty |
| **Manual device** | VoiceOver / TalkBack order and wording, focus order, Dynamic Type at 200 %, Reduce Motion, one-handed reach | Only if actually performed. Otherwise **Not evaluated** |

**Passing golden tests proves only that pixels didn't change.** It says nothing about
accessibility.

## 2. Checklist

| Item | Pass when | Typical evidence |
|---|---|---|
| Touch targets | ≥ 44 × 44 pt, spaced ≥ 8 | C (`ClPressable`, `minSize`) |
| Contrast | Pairs from the safe list in both palettes; text over photos has a scrim | R + the computed token table |
| Text scaling | Essential values and actions survive 200 %: no clipping, no truncation of values | **Usually Not evaluated** (no text-scale goldens except assistant tests) |
| Semantics | Tiles and rows read as one sentence; icon-only controls labelled; decorative icons excluded | C |
| Reading order | Title → state → sections (headers marked) → actions | C; device for confirmation |
| Focus order | Fields in visual order; sheet focus trapped; return focus after close | C + device |
| Form labels | Visible labels (not placeholder-only); errors announced (`liveRegion`) | C + R |
| Selected states | Exposed (`ClPressable(selected:)`); visible without colour alone | C + R |
| Colour-independent meaning | Status = icon + words | R |
| Reduced motion | Animations through `context.motion`; carousels don't auto-advance | C |
| Keyboard and sheets | Primary visible above the keyboard; sheets dismissible; no trapped states | C + H |
| Long content | Long names and 3+ babies don't break headers or chips | Usually Not evaluated (no fixtures) |
| Night care | Readable, calm, no bright panels; warm (not red) attention | R (`*_nightCare_*`) |

## 3. Required variants for substantial screen changes

| Variant | Status to report |
|---|---|
| vi + Light | Verified / Not evaluated |
| vi + Night care | Verified / Not evaluated |
| en + Light | Verified / Not evaluated |
| en + Night care | Verified / Not evaluated |
| Increased text scale (≥ 1.5×, ideally 2×) | Verified / **Unverified (no harness)** |
| Long child and member names | Verified / Unverified (no fixture) |
| Small screen (≤ 360 pt) | Verified / Unverified (goldens are 375 × 812) |
| Relevant empty / error / loading states | Verified / Not evaluated |
| Relevant roles (parent, caregiver, relative) | Verified / Not evaluated |

Report unverified variants as such. Never "probably fine". Never invent test results.

## 4. Severity cues

| Severity | Examples |
|---|---|
| Blocker / gate G2 | A critical action unreachable by screen reader or at large text; a primary control below 44 pt with no alternative |
| High | Essential value truncated; status by colour only on a safety or overdue item; contrast fail on primary text |
| Medium | Missing semantics on secondary controls; reading order slightly off |
| Low | Decorative image announced |
