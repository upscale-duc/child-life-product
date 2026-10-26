# Simplifying copy (D-110)

The copy part of the Simplify stage. The model (Essential / Contextual / Redundant; REMOVE,
MERGE, REWRITE, RELOCATE, PRESERVE) lives in `senior-ui-ux` →
`references/content-simplification.md`. This file holds the writing rules.

**Order of preference:** delete → merge → rewrite. Rewrite only text that has to stay.

## 1. Six rules

1. **No automatic subtitles.** A title-only row or card is fine when its meaning is clear. Never
   add a subtitle to make a card "look complete".
2. **Don't repeat the title.**
   - ✗ "Lịch sử chăm sóc / Xem lại lịch sử các hoạt động chăm sóc bé."
   - ✓ "Lịch sử chăm sóc"
3. **Don't explain obvious actions.**
   - ✗ "Ghi lần bú / Nhấn vào đây để ghi lại lần bú của bé."
   - ✓ "Ghi lần bú"
4. **No internal product language.** Don't show ranking reasons, priority labels, implementation
   details, technical feature categories or algorithm words ("Vì: Luôn có", "điểm ưu tiên",
   "tín hiệu sử dụng") unless the parent genuinely needs them.
5. **Don't swap clarity for icons.** Removing text never means replacing a label with an
   ambiguous icon. Keep the word when the icon could be misread.
6. **Preserve meaningful feedback.** Save confirmations, errors with a way forward, loading,
   sync status, validation, permission explanations, destructive warnings, unsaved changes,
   units and timer state are Essential. Shorten them only if the meaning survives exactly
   (`ui-copy-patterns.md` §5).

## 2. Labels and actions

- **Shortest natural wording that is still accurate.** "Vào Hôm nay của Cam" → "Khám phá Hôm nay".
- **A verb that names the result** for buttons ("Lưu lần thay tã", not "Lưu" when sibling sheets
  name theirs); a noun phrase for rows and settings ("Nhắc chọn ảnh").
- **Setting names say what the switch controls**, from the parent's side, not the system's.
  Verify the notification or setting semantics in code before renaming; never imply a switch
  controls others unless it does.
- **No "Nhấn để…", "Chạm vào đây để…"** on elements that already look tappable. Keep an
  interaction hint only when the gesture is non-obvious (long-press, drag, swipe) and true.

## 3. Descriptions and helper text

- **Keep a description only if it changes a decision** (what the setting controls, what happens
  to data, who will see it, what it costs).
- **Show helper text only when it applies.** A note about overnight sleep belongs on an overnight
  sleep, an offline explanation on the offline state, validation on the invalid field.
- **Long explanations** (how personalisation works, why a number is computed a certain way) move
  to contextual help, an info sheet or first-use guidance. What the control does stays visible.
- **Empty states:** a title plus one action is often enough. Add a body line only if it tells
  the parent something they can't infer (why it is empty, what will appear).

## 4. Both languages

- Simplify **both** vi and en in the same change; same meaning, certainty and placeholders.
- Vietnamese: natural spoken phrasing, no calques ("Vào …", "Thực hiện …"). English: native, not
  word-for-word.
- Removing a string from the UI: remove its usage; delete the ARB key only when no code reads
  it (both files, then `flutter gen-l10n`).

## 5. Checklist

- [ ] Can any text be removed entirely?
- [ ] Is every subtitle necessary (not restating the title, not decoration)?
- [ ] Are labels short, natural and non-repetitive?
- [ ] No technical or internal concepts exposed without need?
- [ ] Essential information (units, status, errors, consequences) preserved?
- [ ] vi and en both concise and natural, same meaning, no truncation?
