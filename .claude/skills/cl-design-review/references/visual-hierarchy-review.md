# Visual hierarchy review

The authority for composition is `cl-screen-patterns` (`information-hierarchy.md`,
`screen-archetypes.md`); foundation values come from `cl-design-foundations`. This file is the
**review method**.

## 1. Procedure (on the rendered image)

1. **First fixation:** look at the PNG for 3 seconds. What did you see first, second, third?
2. **Compare with the job:**
   - Is the first thing what the parent needs first (the job from the workflow, phase A)?
   - If not, that is a hierarchy finding.
3. **Count competitors:**
   - How many elements are visually "loud": large type, a saturated fill, a filled button, an
     illustration?
   - More than one loud element per viewport region needs a reason.
4. **Squint test:**
   - Blur mentally, or zoom the image out.
   - Do groups read as groups?
   - Does the primary action still stand out?
   - Does a flat screen (everything the same weight) appear?
5. **Five-second test:** can you name the purpose, the relevant state and the next action?
   - **Not** "is everything above the fold"; long screens are fine if the start orients.
   - **No hero is required;** a title + compact list can pass.
6. **Then the details** (§2).

## 2. Checklist

| Element | Ask | Typical finding |
|---|---|---|
| Page title | Does it say where I am (or greet meaningfully)? | A greeting that addresses the wrong person |
| Hero | Is there at most one, and is it the right answer? | Two hero-sized cards competing |
| Important values | Big, tabular, with a unit and period? | A value buried in a sentence; units wrap away from the number |
| Section grouping | Does each section answer one question; is the heading what's inside? | Grouping by data type instead of the reader's question |
| Card density | Would grouped rows be clearer than cards? | One card per row; cards inside cards |
| Text hierarchy | ≤ 3 levels per card; sizes from the scale | Extra 13 / 15 pt sizes; bold everywhere |
| Spacing rhythm | Sibling sections share one gap; groups separate more than items | Gaps that vary per section |
| Colour emphasis | Accent = meaning (care colour, attention); warm for attention, danger only for danger | Error red for routine overdue items; several accent families in one section |
| Primary vs secondary actions | One dominant primary; secondaries quieter (D-105) | A filled button inside every card |
| Visual noise | Do borders, shadows, icons and illustrations carry meaning? | Decorative art on data rows; shadows on inset items |
| Repetition | The same fact twice (title and subtitle; a sentence and a chart) | A summary sentence restating a chart |
| Progressive disclosure | Are detail, AI and history behind a tap, while safety and status stay visible? | An empty placeholder taking a third of the viewport |

## 3. What not to do

- **Don't enforce one universal layout** across archetypes. Galleries should feel different from
  stats.
- **Don't demand a hero** or everything above the fold.
- **Never suggest smaller text** to fit more.
- **Don't write generic feedback** ("improve spacing", "cleaner", "more modern", "more premium").
  Name the element, the problem and the consequence. "The reminder time is ellipsised ('còn 2 n…'),
  so a parent can't tell when the vaccine is due" is a finding; "the reminders card looks
  cramped" is not.

## 4. Evidence

Hierarchy findings need **R** (an image). Code can explain the cause (**C**), e.g. a one-line row
with right-aligned meta, but can't by itself show that attention lands in the wrong place.
