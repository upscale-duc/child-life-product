# Premium — owner-updated Figma revision, 27/10/2026

Đã cập nhật wording và bố cục sheet quyền lợi theo bản Figma mới của chủ sản phẩm. Thẻ chỉ giữ ảnh minh hoạ, nhãn và tiêu đề; bỏ nội dung lặp và hai ô so sánh Free/Premium. Swipe paging, chiều cao cố định và nút quay lại luôn trong tầm thao tác được giữ.

- [Figma / Flutter, năm quyền lợi](assets/2026-10-27-premium-revision/figma-flutter.png)
- [Trước / sau: thiệp-video và nhịp](assets/2026-10-27-premium-revision/before-after.png)
- [Tiếng Anh và chữ 200%](assets/2026-10-27-premium-revision/after-light-en.png)
- [Night care, tiếng Việt](assets/2026-10-27-premium-revision/after-nightCare-vi.png)

## Authority and scope

Owner supplied the newly edited [Premium section 1153:5491](https://www.figma.com/design/sJLG1fAXKDnDr9YI6Yx8ex/Child-Life?node-id=1153-5491) and requested updating the implementation. This instruction supersedes the general repository treatment of Figma as historical material for this task. Figma was read only. High-fidelity contexts and screenshots were fetched for the full page, payment, and all five detail frames.

Classification: **REFINE / L1–L2** against the owner's specified revision; the composition choice is already resolved by the supplied design. Audience: family members comparing benefits, with purchases restricted to the manager. Five-second answer: the benefit and what the selected plan includes; primary next action: return to plan selection.

Current code, ARB, plan models, storage-add-on CTA, and existing tests were inspected. All 124 Premium goldens passed a fresh comparison run before edits; the saved before images are Current evidence. Existing components, PremiumPalette, fonts, five Vietnamese illustration panels and shared sheet route are reused. Panel geometry remains 276 × 156; the local 828 × 468 PNGs remain non-empty and occupy their original design slots. No screenshot replaces a live screen.

## Simplify and implementation

| Element | Action |
|---|---|
| Card description and allowance in benefit details | REMOVE from detail presentation; the three bullets already explain them. Preserve the fuller card for other existing uses. Semantics follow the visible compact content. |
| Free/Premium comparison tiles | REMOVE from these five sheets, following the updated design. Video quality choices and introductions at gated entry points remain unchanged. |
| Benefit wording | REWRITE to the latest Vietnamese copy, with matching English: Lumi heading, rhythm heading, closing bullets and list labels. |
| Lumi credits and caregiver count | PRESERVE configured values with typed placeholders and English plurals; never hard-code 200 or 6 in product copy. |
| Sheet frame | REFINE to 552pt, the latest tallest Figma detail (Lumi), across all five pages. Preserve the prior owner's paging animation, stable header/footer and Reduce Motion support. Content scrolls vertically at large text. |
| Storage purchase promise | PRESERVE “Sắp có” / “Coming soon”: its current CTA still calls `showPaymentSoon`. Removing it would claim an available purchase that the app cannot complete. |

The string generator also drops its obsolete, unused `asOutBodyPremium` entry so required localization metadata generation completes. Current `asOutBodyPremium2` and other active callers are unchanged.

## Rendered review

Viewed the five Vietnamese Figma/Flutter comparisons, all five details and a 200% text example in English, and both Night care contact sheets. Verdict: **Improved** for this revision: fewer duplicate blocks, the owner’s revised headings and bullets, and a shorter stable sheet. No new overflow or lost return action was observed. Font rasterization differs; the implementation is not claimed pixel-identical.

Intentional differences from individual Figma frames: all pages share the tallest sheet height to satisfy the earlier explicit anti-jump requirement; shorter pages therefore retain extra space. Native OS status indicators are not painted into Flutter content. The storage availability qualifier is retained as explained above. The payment reference's example renewal date is not fabricated in live copy.

Gates within the reviewed scope: G1 business meaning, G3 draft retention, G4 permissions and G5 claims preserved by code; G2 action access and G6 paging/return flow passed rendered and interaction checks. No newly introduced blocker/high finding remains. Physical-device purchase, VoiceOver/TalkBack and long-name testing were not performed.

| Dimension | Result and evidence |
|---|---|
| Task clarity | 4 — R: benefit heading, bullets and return action. |
| Hierarchy | 4 — R: image/title → explanation → action. |
| Scanability | 4 — R: duplicate card paragraphs and comparison boxes removed. |
| Interaction clarity | 4 — R/C: pager, swipe and return retained. |
| Navigation | 4 — C: selected period survives sheet navigation. |
| Visual coherence | 4 — R: updated Figma content and reused Premium assets. |
| Localization | 4 — R/C: vi/en, configured counts and plurals. |
| States/trust | 4 — C: billing availability and unknown-plan handling preserved. |
| Accessibility | 3 — R/C: 44pt controls, 200% scroll, Reduce Motion; screen readers untested. |
| Product identity | 4 — R: existing Premium gold/dark treatment. |
| Content necessity | 4 — R/C: concise detail cards without duplicated allowances. |

Scores are implementation self-review, not user-research results.

## Verification and release status

- 29 Premium interaction/copy tests passed, including both paging modes, 375×640 at 200% text, selected-plan retention, quality introductions and config-driven counts.
- 124 Premium golden cases passed after updating affected baselines, then passed a fresh comparison without baseline writes.
- Targeted Flutter analysis passed for production view and both affected test files.
- String-generator Python syntax and scoped `git diff --check` passed.

Updated mobile source and review artifacts only. No new device installation, portal deployment or store release in this task.
