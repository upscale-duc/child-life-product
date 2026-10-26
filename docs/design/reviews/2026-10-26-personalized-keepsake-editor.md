# Personalised keepsake editor · 2026-10-26

## Outcome and scope

The parent has already chosen a template and, for video, photos. Their job is to personalise the moment, check the result and create it. The supplied screenshot shows the birth video editor (`Ngày con đến`). This revision **RESTRUCTURES** the shared card/video editor rather than polishing the long form again.

Implemented in `apps/mobile/lib/features/keepsakes/premium_keepsake_editor.dart`. The previous review (`2026-10-26-keepsake-flows.md`) is historical: its REFINE classification did not resolve the owner's difficulty with the long personalised form.

[Interactive before / A / final gallery](assets/2026-10-26-personalized-editor/index.html).

## Evidence and initial audit

Fresh baseline: 16 captures of the actual editor, vi/en × Light/Night care × 100/200%, two template types from `premium48.json`. Baseline source was snapshotted before editing. Earlier review images and the supplied screenshot are context, not proof of the current source. All captures use 375 × 812, the actual providers with test overrides and synthetic media.

| Dimension | Observed problem (R/C) | Structural decision |
|---|---|---|
| Information architecture | Language, ratio and motion precede the baby's details; wording, crops and music follow in one long list | Separate Details, Wording and Photos/Music; output options in a sheet |
| Visual hierarchy | In the video editor, export settings dominate the first viewport | Lead with baby/moment information |
| Composition | Each unrelated topic extends the same scroll surface | Keep section navigation outside the scrolling body |
| Interaction efficiency | Reaching wording or music requires passing unrelated fields | Direct access to each topic; no compulsory step sequence |
| Content simplification | Group name and copy heading repeat context; permanent counters add noise | Remove repeated headings; use shared text fields |
| Visual quality | Long labels truncate at 200%; empty date/time fields have unclear controls | Wrapping labels, calendar/clock affordances and labelled clear buttons |

Findings: the mixed long form is High/P1/L2 (R/C); export settings preceding essential details are Medium/P1/L2 (R/C); persistent counters and repeated headings are Low/P2/L1 (R/C). The expected reduction in search/scroll effort is a design inference, not a measured usability result.

## Content simplification

| Element | Class | Action |
|---|---|---|
| Template name | Essential | Preserve in the app bar |
| Template group name | Redundant | Remove from editor body |
| Required details, choices, confirmations and date ranges | Essential | Preserve in Details |
| Known birth date | Essential context | Preserve, including explicit clearing and unknown values |
| Optional birth time/place | Contextual | Relocate into More details; retain entered values and expansion state |
| Editable wording | Essential capability | Relocate into Wording; retain per-language overrides |
| Copy section heading | Redundant beside Wording | Remove; keep restore-default action |
| Counters on every resting text field | Contextual | Use shared fields with hard maximums and existing validation |
| Language, ratio, gentle motion | Contextual | Relocate to Options sheet available from every section |
| Card artwork, photo slots/sources/crops | Essential | Preserve in Photos |
| Video scene crops/change photos/music | Essential | Preserve in Photos & music |
| Preview / create | Essential | Pin at the bottom; hide Preview while keyboard is open to preserve editing space |
| Blocking reason | Essential feedback | Preserve; make it a link to photos, details or wording as applicable |

Only optional `birthTime` / `placeName` are collapsed, and only when not required. Other template-specific fields and confirmations remain visible. No guessed birth date or automatic confirmation is introduced.

## Rendered alternatives and choice

A: refine the original form by moving language/ratio/motion into a collapsed group after the wording. The underlying form remains continuous. Real Flutter captures are in `assets/2026-10-26-personalized-editor/A/`; the exploration patch is in `apps/mobile/test/design_explorations/personalized_editor/candidate_a.patch`.

B: three directly selectable sections, optional details collapsed, output settings in a separate sheet, primary actions pinned. Real Flutter prototype captures are in `B/`. The final implementation further replaces editable raw text controls with `ClTextField`, wraps date/time labels, uses Child Life icons, simplifies Preview wording and adapts the footer to the keyboard.

| Criterion | Weight | A | B |
|---|---:|---|---|
| Primary task efficiency | 25% | Less initial clutter, but unrelated topics still require scrolling | Direct topic access; prefilled baby details immediately visible |
| Hierarchy | 20% | Details move up for video; card artwork still pushes details below the fold | Clear current topic and stable primary action |
| Clarity / simplicity | 20% | One mixed form remains | One topic at a time; optional detail clearly marked |
| Interaction | 15% | Fewer mode switches, more scrolling | Adds a section tap when changing topic; retains data without required next/back steps |
| Visual quality | 10% | Resting counters and long underline form remain | Shared fields and explicit selection state |
| Consistency / accessibility | 10% | Long labels still truncate | Sections wrap at 200%; labels wrap; final controls remain reachable |

**Selected B, L2.** The dominant criteria (task efficiency, hierarchy and clarity) favour direct topic access. No invented weighted numeric total or completion-time claim. Trade-off: the card canvas is now in Photos instead of permanently above the form. Preview stays accessible from every section with valid inputs.

## Implementation and behaviour checks

- Controllers and per-language wording overrides remain in editor state when sections unmount.
- Async profile prefill still respects edits and explicit clearing.
- Existing required fields, option membership, confirmations, date range ordering, character limits, brace checks and renderer fit gates remain enforced.
- Invalid field data links to Details; invalid copy links to Wording; missing photos links to Photos. Long-content feedback remains available; the exact offending renderer layer is not highlighted.
- Photo slots, crops, music and output preferences retain their previous payload semantics. Video requests retain parents-only audience and the same routes.
- Before saving a card from another section, the editor selects Photos, resets scroll to the artwork and waits for the painted frame before export.
- No new routes, persistence promises, entitlements, permissions or server changes. No Skills or shared component implementation changed in this revision.

During verification, expanded optional fields exposed a PageStorage key collision with a nested text-field scroll offset. Replaced the expansion PageStorage key with a normal key and explicit editor-owned expansion state. Wording reset controls and crop fit selectors were also corrected for 200% text. The render harness now verifies that opening More details actually mounts the optional inputs.

## Final review

Gate verdict for covered evidence: G1 pass (C), G2 pass for rendered controls and simulated keyboard (R/C; screen reader not evaluated), G3 pass for section switching (C/tests; process termination not evaluated), G4 unchanged (C; no new Rules audit), G5 not applicable, G6 pass for editor/request interactions (R/C/tests; native export/cloud rendering not evaluated).

| Quality dimension | Score | Evidence / limits |
|---|---:|---|
| Task clarity | 4 | vi/en, both themes, normal/large text |
| Information hierarchy | 4 | Details first; clearly selected topic |
| Scanability and density | 4 | Main birth form has two visible fields and optional disclosure |
| Interaction clarity | 4 | Selected sections, explicit pick/clear, stable create action |
| Navigation and flow | 4 | Direct section switching; request payload exercised |
| Visual coherence | 4 | Shared fields, semantic colours, consistent sources |
| Content and localisation | 4 | vi/en copy; remote template labels retained and wrapped |
| States and trust | 3 | Missing photos, async prefill and input preservation covered; native/cloud failure paths unverified here |
| Accessibility and adaptability | 3 | 200%, both themes, keyboard insets covered; screen reader/physical device unverified |
| Product identity | 4 | Child Life type, surfaces, colours and restrained controls |
| Content necessity | 4 | Repeated headings/counters removed; essential controls retained |

Self-critique: the primary task and current topic are clear; baby details win initial attention; repeated group/copy headings are removed; controls use a consistent visual system; direct topic access replaces scanning a mixed form; both locales and themes fit; large text wraps; topic changes cost one tap; controllers preserve edits; the fresh before/after demonstrates a substantive structural change. At 200% some optional/media content still requires scrolling, and the app bar Options icon requires discovery. These are remaining trade-offs, not claims of measured user performance.

## Verification

- Broad focused regression run: **363 passed**, including 104 new editor render/interaction variants, 96 prior keepsake flow variants, 17 personalised-editor behaviour tests, and existing memory story/card/quota/purchase/navigation coverage.
- Final editor-only render/behaviour run after the shortened Preview label and stricter optional-field interaction check: **121 passed** (104 rendered states + 17 behaviour tests).
- A final targeted check also passed all **16 optional-detail variants**, including scrolling to and hit-testing the birthplace input at 200%.
- `flutter analyze --no-pub`: no new errors; one existing duplicate import warning in `test/app/safe_navigation_test.dart:61`.
- `git diff --check` passes for the changed editor and behaviour tests.
- Existing golden baselines were not overwritten. This personalised editor had no dedicated stored golden; fresh probe screenshots supply visual evidence.
- Native photo picker, native JPG encoding/sharing, actual audio playback and server-side rendering were not exercised on a physical device. Keyboard screenshots reserve 300px rather than drawing a platform keyboard. Media is synthetic; these images do not establish photographic crop quality.

## Tóm tắt cho chủ sản phẩm

Màn hình không còn dồn mọi thứ thành một biểu mẫu dài. Ba mẹ mở từng mục Thông tin, Lời nhắn hoặc Ảnh & nhạc; giờ sinh và nơi sinh chỉ mở khi cần. Ngôn ngữ, tỷ lệ và chuyển động nằm trong Tuỳ chỉnh. Nút tạo luôn ở dưới; khi nhập, phần xem trước tạm ẩn để có thêm chỗ sửa. Dữ liệu đã nhập được giữ khi đổi mục.
