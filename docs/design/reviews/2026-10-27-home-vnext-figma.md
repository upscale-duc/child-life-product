# Home thao tác nhanh — Figma review

Updated 2026-10-27. Design only; no mobile implementation or installation in this task.

Editable section: https://www.figma.com/design/sJLG1fAXKDnDr9YI6Yx8ex/Child-Life?node-id=1294-17312

## Scope

22 frames, 430 × 932, covering 11 cases in Light and Night care: idle, active sleep, suggested memories, active sleep plus suggestions, hidden caregiver with pattern background, offline/pending, empty diary, loading, load failure, three-line afternoon greeting, and three-line morning greeting with a longer name and suggestions.

The original Home remains unchanged. The baseline clone is 375 × 812, so comparisons do not imply an equivalent viewport or measured performance improvement.

## Owner refinements

- Six full-size care cards, including pumping and growth. Removed the separate “Hoạt động khác” section.
- Headings and content share one section. Section gap 16 pt, heading/content gap 8 pt, card gap 12 pt.
- Original mini-art component instances scaled to 28 pt, within 36 pt circular backgrounds.
- Bottle presets: 60 ml, 90 ml, Khác. Design assumption: presets open a prefilled form and still require Save.
- Four-tab navigation retained; Lumi is separate to its right, with + above Lumi.
- Removed the middle “Tuỳ chỉnh Hôm nay” link; retained bottom appearance settings.
- Background follows `LivingHeaderView` in `apps/mobile/lib/features/today/living_header.dart`: portrait begins at 28% width; base overlay .25, cloud overlay .28 Light/.35 Night, with corresponding horizontal and bottom alpha ramps. No added blur. Editable vector strips represent the ramps in Figma.
- Three-line greeting examples: “Một ngày của / Teddy thế nào / rồi?” and “Chào ngày mới / cùng bé Minh / Khôi”. Header grows by one 36 pt line; caregiver status moves down accordingly, maintaining a 12 pt gap.

## Verification and limits

Viewed fresh renders of all 22 frames after the refinements. Structural checks passed for all frame dimensions, six-card counts, section/title/grid gaps, and removal of redundant links. Loading, empty, error, pending and active-sleep treatments remain distinct.

Suggested memories follow the six care cards and require scrolling in the initial viewport. Floating navigation and actions overlay the scrolling content; lower content must remain reachable by scrolling. Runtime accessibility, text scaling, actual scrolling and API behavior require app implementation and device verification. No Flutter tests were run for this Figma-only change.

Three-line examples: Light afternoon `1310:34607`, Night afternoon `1310:34986`, Light morning `1310:35367`, Night morning `1310:35759`.
