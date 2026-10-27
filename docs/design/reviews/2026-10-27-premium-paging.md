# Premium benefit paging

Owner request: swipe should animate like paging, with a fixed sheet height to prevent the screen jumping.

Changed `apps/mobile/lib/features/premium/paywall_v2.dart`. Classification: **REFINE / L1 interaction fix**. The existing approved Premium artwork, copy, prices, five benefits and destinations are preserved. No new product decision or alternate screen design is needed.

## Before → after

- Before: a horizontal `GestureDetector` replaced the entire visible content after release. Each page's intrinsic height moved the sheet top and return button.
- After: a `PageView` follows the finger and snaps to a page. Arrow buttons animate to the adjacent page with `ClMotion.quick` / `ClCurves.quick`. Paging cycles across the same five benefits, including last → first.
- One 692.4-point sheet, based on the tallest approved original detail, is used for every page. The shared route constrains it to the available height on smaller screens.
- Grabber, pager and return button stay outside the sliding body. The header reserves the tallest localized title at the current text scale, so its height also stays stable.
- Long page content scrolls vertically and retains its own scroll position. The return button remains visible at 200% text.
- Reduce Motion makes arrow navigation immediate and removes the dot transition. Finger-driven paging remains directly manipulable.

Content simplification: **PRESERVE** all five explanations and Free/Premium comparisons; **REPLACE** the manual swipe recognizer with native paging; **RELOCATE** the return action outside the page scroll area. No added explanatory text or controls.

## Rendered review

The old memories/Lumi baselines were freshly verified before editing and copied into `assets/2026-10-27-premium-paging/before/`.

- [Before/after height comparison](assets/2026-10-27-premium-paging/fixed-height-comparison.png)
- [All five pages, large text and English/Night care samples](assets/2026-10-27-premium-paging/paging-review.png)

Opened and inspected default Vietnamese pages, English Night care and 200% vi/en renders. Sheet top, header and return action align across pages. The tallest/large-text content can scroll inside the fixed frame. Purpose, information hierarchy, content and identity retain the previous approved design. Interaction/navigation improve through continuous motion and stable controls. Accessibility evidence covers 44-point buttons, fixed action access, text scaling, a short 375×640 viewport and Reduce Motion; VoiceOver/TalkBack and user-study outcomes remain unverified.

## Verification

- 27 Premium v2 widget tests passed, including new checks for fractional page position during a drag and arrow animation, identical sheet/footer rectangles throughout all five pages and wrapping, and immediate Reduce Motion navigation at 200% text on a short viewport.
- Updated only the 24 affected detail goldens, then verified all 124 Premium goldens without updating baselines: vi/en × Light/Night care, including 200% text.
- Targeted Flutter analysis and scoped `git diff --check` passed.
- No billing, server, entitlement, copy or shared sheet-route changes in this follow-up.

Signed iOS Release-dev build completed (112.0 MB). Installed `dev.hsba.app` on Duckie's iPhone 14 Pro Max on 2026-10-27 at 12:14 Asia/Ho_Chi_Minh; CoreDevice confirmed a successful app launch. Physical gesture/visual review remains for the owner; the automated paging checks above are Flutter widget evidence.
