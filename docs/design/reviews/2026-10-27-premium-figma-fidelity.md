# Premium v2 — correction against the approved Figma

Đã làm lại màn chọn gói, chi tiết thanh toán và năm sheet quyền lợi theo bản Figma chủ sản phẩm chỉ định. Bản trước lệch rõ ở thứ tự nút đóng/khôi phục, kiểu chữ, lựa chọn gói, nhóm quyền lợi và cấu trúc sheet. Ảnh đối chiếu bên dưới là render Flutter từ code, không phải ảnh Figma dùng thay màn hình.

- [Trước / Figma / Flutter](assets/2026-10-27-premium-figma/plans-comparison.png)
- [Tám trạng thái sau sửa](assets/2026-10-27-premium-figma/native-flow.png)
- [Đối chiếu năm sheet](assets/2026-10-27-premium-figma/benefits-comparison.png)
- [Ảnh Figma gốc lấy trong phiên này](assets/2026-10-27-premium-figma/figma-flow.png)

## Authority and scope

Owner instruction on 2026-10-27: “ko hề giống figma 1 xíu nào. làm y chang figma đi”. This explicitly makes [section 1153:5491](https://www.figma.com/design/sJLG1fAXKDnDr9YI6Yx8ex/Child-Life?node-id=1153-5491) the visual reference for this correction. It overrides the general repository preference for treating Figma as historical material. Figma was read and illustrations exported; the design file was not edited.

Classification: **RESTRUCTURE / L2 correction to an explicitly approved design**. No alternative redesign was introduced. The reference already resolves the layout choice; generating another proposed layout would contradict the owner's instruction.

Reference frames: yearly `1085:18016`, monthly `1085:18136`, full scroll `1085:18256`, payment `1085:18376`, memories `1085:18506`, Lumi `1085:18822`, rhythm `1085:18962`, storage `1085:19108`, writers `1085:19257`. Natural viewport: 375 × 812. The tall reference is represented by scrollable content rather than a fixed 1333-point phone screen.

## Changes and content decisions

| Element | Decision and resulting implementation |
|---|---|
| Header | Restore left, 34-point close visual right with 44-point target; left-aligned gold crest; centered 24-point regular Playfair title and shared-family subtitle. |
| Plan choice | 22-point corners, exact padding, 26-point regular Playfair price, billing suffix, trailing 24-point radio, floating savings badge. Prices, annual equivalent and saving remain configuration driven. |
| Feature focus above plans | Removed from the plan layout to match Figma. Feature-specific introductions and explicit Premium labels remain at gated entry points. |
| Five benefits | One clipped rounded group, 40-point icon backgrounds, 14-point semibold titles, 12-point supporting copy and separators. No duplicated benefit list. |
| Footer | Flat top border, fixed payment summary, gold CTA with selected plan and actual total, Figma legal wording and terms action. The summary retains a 44-point hit target while its visual row occupies the reference geometry. |
| Payment details | Handle, serif heading, aligned price/equivalent/saving/tax rows, total, renewal explanation and selected-plan action. No fabricated future renewal date. |
| Five detail sheets | Full-width dark surface, 32-point top corners, handle, pager/dots, 300-point feature card, three checkmarked explanations, side-by-side Free/Premium tiles and return action. |
| Illustration panels | Exported only the decorative 276 × 156 panels at 3×. Headlines, bullets, plan comparisons, limits and actions remain live Flutter text/widgets. English retains localized native illustration examples. |
| Reading and operation | Corrected inherited line heights to match the Figma card geometry. Pager visuals remain 32 points, with 44-point touch targets. Horizontal swiping still switches benefits. Large text scrolls without truncating the content or removing the return action. |
| Scrolled header | Gains an opaque surface after scrolling so the content does not show through restore/close. Scroll position remains intact when opening/closing details. |
| Modal dim | 60% black, as measured from the Figma `Dim` layer. Shared route still owns drag, motion, keyboard avoidance and dismissal. |

`ClSheetRoute` gained opt-in `customSurface` and `scrimColor` parameters for branded sheets. Default presentation and padding remain unchanged. Premium opts in through `showPremiumDetails`; it does not reimplement the shared dismissal mechanics.

The five PNGs in `apps/mobile/assets/premium/*-demo-vi.png` originate from nodes `1154:5536`, `I1090:18613;1019:16930`, `I1090:18680;1019:16944`, `I1090:18753;1019:16965`, and `I1090:18828;1019:16988`. Export size: 828 × 468. These are illustrative examples, excluded from semantics, with no account data or live controls embedded in them. The text generator `tool/premium_flow_strings.py` retains the reviewed bilingual strings and typed placeholders.

## Preserved product rules

D-124 remains unchanged: unlimited exports on both plans; Free HD 720p/basic templates, Premium Full HD 1080p/premium templates. D-125 introductions remain before the gated action. Cancelling an introduction preserves the selected HD option and the draft. Role, unknown-plan and service-error paths do not become purchase promises. The family manager controls purchases. Closed billing explains availability, including Restore; it does not simulate a successful transaction.

## Evidence and review

**Before:** the yearly paywall was freshly rendered with a passing baseline before edits. Its image is under `before/`. The copied older memories-detail image is historical and is not used to claim a fresh before/after score for every sheet.

**After:** 124 golden cases freshly rendered and then verified again without updating baselines: vi/en × Light/Night care, yearly/monthly, payment, all five details, 200% text, entry points, member and family-plan states. Eight principal Vietnamese states also have reproducible 3× Flutter captures under `retina/`; the contact sheet downsamples these for viewing. Opened the principal captures, contact sheets and large-text render for visual review. The harness now enables shadows before constructing painters, avoiding cached unblurred shadows. Exported panels retain their own 28% black fill without a second dark background underneath.

The comparison deliberately shows real platform differences: the fixture uses Google Play while the Figma example uses App Store; production picks the actual store. Native OS status indicators and device-frame rounding are not painted into app content. The background behind a modal reflects the user's real scroll position. Font rasterization varies between Figma and Flutter; the shipped fonts, weights, sizes and line heights are specified explicitly. No claim of a zero-difference pixel comparison or physical-device verification is made.

Gates within the rendered/tested scope: G1 business meaning, G3 draft preservation, G4 permissions, G5 AI claims and G6 flow usability passed by code/tests and rendered inspection. G2 passed for visible/touch operation and 200% text; VoiceOver/TalkBack operation was not evaluated.

| Dimension | After | Evidence / limit |
|---|---|---|
| Task clarity | 4 | R/C: shared plans, period and actual charge are visible. |
| Information hierarchy | 4 | R: reference header → plans → grouped benefits → fixed action. |
| Scanability and density | 4 | R: five grouped benefits; detail comparisons are parallel. |
| Interaction clarity | 4 | R/C: radios, explicit disclosure, pager, return and close. |
| Navigation and flow | 4 | C: monthly selection survives detail navigation and swiping. |
| Visual coherence | 4 | R: approved Figma composition, assets, dimensions and type roles. |
| Content and localization | 4 | R/C: both locales rendered; allowance placeholders and plurals tested. |
| States and trust | 3 | C/R: unknown prices, role and billing availability covered; no live store purchase. |
| Accessibility and adaptability | 3 | R/C: 44-point controls, large-text scroll, both palettes; screen reader untested. |
| Product identity | 4 | R: approved calm dark/gold Premium treatment and family sharing message. |
| Content necessity | 4 | R/C: redundant focus block removed; essential price/period/legal content retained. |

These are implementation self-review scores, not user-research results. Before/after comparison is limited to the freshly verified main paywall rather than inventing equivalent before coverage for all states.

## Verification and release status

- 124 Premium golden cases passed after updates and again in a fresh comparison run.
- 46 Premium v2, wording and core widget tests passed, including selected-period retention, detail swiping, Free quality introduction, roles, unknown plan and shared sheet dismissal.
- 83 purchase/quota/showcase regression cases passed in a separate run; showcase baselines were not overwritten.
- Eight 3× review captures passed the existing golden comparisons while being exported.
- Targeted Flutter analysis of four production files and the two changed tests passed. Python string-generator syntax and scoped `git diff --check` passed.
- A wider legacy `premium_test.dart` run has one independent mismatch: the beta-template test still expects “Dùng mẫu miễn phí” at line 164. This correction does not change that gate or its Free-template label. Its baseline/assertion was not rewritten to hide the mismatch.

Capture command, from `apps/mobile`:

```sh
flutter test test/golden/premium_v2_golden_test.dart \
  --dart-define=PREMIUM_CAPTURE_DIRECTORY=../../docs/design/reviews/assets/2026-10-27-premium-figma/retina \
  --name '(pw06_explore|pw_monthly|payment_details|detail_memories|detail_lumi|detail_rhythm|detail_storage|detail_seats) light vi'
```

The correction is in mobile app source and review artifacts. No app binary, backend, or new portal release was deployed for this visual correction. The earlier admin portal deployment does not distribute this native consumer UI.
