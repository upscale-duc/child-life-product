# Compact and decluttered screens (D-110)

The structure part of the Simplify stage (`senior-ui-ux` → `references/content-simplification.md`).
Copy rules are in `cl-ux-writing` → `simplifying-copy.md`.

**Simple without being simplistic; informative without overwhelming.** Density comes from
removing what doesn't help and grouping what does, never from smaller text, tighter targets or
hidden values.

## 1. Compact information presentation

- **Value-first rows** (label + value on one line, wrapping at large text) over cards that hold
  one fact each.
- **A heading + compact list** usually beats a grid of large cards with an icon, a title and a
  restating subtitle.
- **Status as a short value** ("Đang bật", "3 mũi quá hạn") next to its name, not a sentence
  under it.
- **Numbers as visuals** only where they help scanning (`insights-and-data-visualization.md`).

## 2. Progressive disclosure, honestly

- Disclose **contextual** content (advanced explanations, rare instructions, technical
  background) where it is needed: in the state it explains, an info sheet, first-use guidance, or
  the error state.
- **Never hide Essential content** (safety, consent, cost, overdue items, what a setting
  controls) and never add a tap only to make the screen shorter.
- A helper line that applies to one state appears **only in that state** (e.g. the overnight
  note only on an overnight sleep).

## 3. Containers, headings and dividers

- **One level of card.** No card inside a card; no decorative container around a single row.
  A container must communicate a grouping.
- **No repeated headings:** a section heading that repeats the screen title, or a card title that
  repeats its section heading, goes.
- **Dividers** only between rows of one group; spacing separates groups.
- **Icons** only where they speed recognition (care types, status). A generic icon beside every
  row is noise.
- **Badges** only for real state (overdue, new, coming soon); never decorative.
- **One dominant primary**; remove duplicate CTAs that go to the same place (D-105).

## 4. Settings screens

Optimise for quick scanning and confident decisions:

- clear section headings; short setting names; consistent switches; concise status values;
- what each switch controls stays visible in a few words where the name alone is ambiguous;
- longer explanations (how proactive suggestions work) → one short line or contextual help, not a
  paragraph above the group;
- no repeated description under every row; no nested cards; consistent grouping;
- verify the semantics in code before renaming or regrouping; never imply that a switch
  controls others unless it does; enabling / suppressing behaviour stays exactly the same.

## 5. Onboarding

- One purpose and one primary action per screen; a short natural heading; minimal support text.
- No long introductory paragraphs, no repeated descriptions under list items, no technical
  explanation of personalisation, no stack of instruction cards, no unnecessary secondary CTA.
- Explain what the parent should do next, never the product's internal architecture.
- **Reference: Today Adaptive onboarding.** Rows like "Chi tiêu tháng này / Vì: Chi tiêu cho con",
  "Nhắc nhở / Vì: Nhắc nhở việc của bé", "Ghi nhanh / Vì: Luôn có" expose ranking reasons:
  show a clean ordered list of the existing widget names. If reordering is supported, show a drag
  handle and one concise instruction. Ranking and Customization behaviour and every user control
  stay unchanged (L3 otherwise).

## 6. Forms and lists

- Field labels and units stay; helper text only when the field is ambiguous or validation needs
  it; errors under the field that caused them.
- Pre-filled values say so once ("theo lần trước"), not in every field.
- Lists: one line per item where possible; secondary meta only if it helps tell items apart.

## 7. Don't overdo it

- Keep 44 pt targets, readable type, Night care contrast and breathing room
  (`cl-design-foundations`).
- Don't force every screen into the same dense layout; archetypes differ
  (`screen-archetypes.md`).
- Removing text must not leave an icon-only control whose meaning is unclear.
