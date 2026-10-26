# Care: structural redesign with workflow v2 (2026-10-25)

Workflow v2 (D-112): fresh render → classify KEEP / REFINE / RESTRUCTURE / REDESIGN → rendered A / B
prototypes for structural problems → autonomous selection → implement → re-render → self-critique →
tests. Prototypes and renders: `docs/design/explorations/care-v2/` (`assets/` every variant,
`compare/` side-by-side sheets). Harness:
`apps/mobile/test/design_explorations/care_v2/care_v2_exploration.dart` (+ `care_v2_prototypes.dart`).

## Tóm tắt cho chủ sản phẩm (VI)

- **Chăm sóc:** đổi từ lưới 11 thẻ to bằng nhau (gần 2 màn hình) sang **danh sách theo nhóm**:
  mỗi nhóm một khung, mỗi chức năng một dòng có trạng thái và mũi tên. Cả trang giờ vừa khoảng
  một màn hình. "3 mũi quá hạn" vẫn nổi bật màu ấm. Thứ tự và nhóm giữ đúng như anh/chị đã quyết
  (D-069, D-083, D-085).
- **Nhập giấc ngủ:** chọn **giờ bắt đầu và kết thúc trước**, thời lượng hiện ngay bên dưới như
  dòng tổng; bỏ thẻ lớn 140 pt chỉ để hiện "1 giờ". Giấc qua đêm có nhãn "Qua đêm" và ghi chú.
- **Đồng hồ ngủ:** bỏ chữ "Đang ngủ" và "Từ 13:37" trong vòng tròn vì tiêu đề ngay trên đã nói;
  vòng chỉ còn mặt trăng và giờ.
- **Giữ nguyên:** Lịch sử và Ghi nhanh vốn đã tốt (chỉ có những sửa lỗi của đợt trước).
- **Đã quyết (D-113, 2026-10-26):** "Chăm hằng ngày" xếp theo tần suất dùng (Lịch sử, Thống kê
  lên đầu), mục "Sớm ra mắt" xuống cuối mỗi nhóm.

## A. Before assessment (fresh renders)

Baselines were confirmed fresh before the audit (`tool/golden_freshness.sh`: all Care goldens
Current). "Before" renders: `assets/*_before_*`.

| Screen | Main goal | Problems observed | Decision | Reasoning |
|---|---|---|---|---|
| **Chăm sóc hub** | Get to the right care tool quickly; notice what needs attention | 11 equal-weight 2-column cards (~1,300 pt, two screens) for 11 links; icon + title + subtitle per card leaves most of each card empty; 4 of 11 cards are "Sớm ra mắt" teasers with the same weight as live tools; overdue status competes with captions | **RESTRUCTURE** | Composition (grid of cards) is wrong for a list of destinations; hierarchy flat. Behaviour (destinations, search, roles) is fine |
| **Lịch sử** | See what happened on a day; find an entry | Few: horizontally scrolling filter chips; duration entries drawn as tinted bubbles inside the day card | **KEEP** (refined in the previous pass) | Day strip → filters → summary with 24 h strip → part-of-day timeline with group totals is clear, dense and scannable; a restructure would add risk without a visible benefit |
| **Ghi nhanh** | Log the next activity in one tap | Growth (monthly) has the same weight as feeds; long-press for manual sleep is undiscoverable | **KEEP** | Six large one-handed tiles in care colours work; weighting tiles by frequency would need usage data or Adaptive behaviour (L3). 200 % was fixed in the previous pass |
| **Sleep: timer** | See elapsed time, end the sleep | The ring repeats the heading ("Đang ngủ") and the subtitle ("Từ 13:37") | **REFINE** | Action hierarchy (End primary, edit start secondary, cancel plain) is right; only redundancy |
| **Sleep: manual entry** | Enter start and end | A 140 pt card for the derived duration sits **above** the inputs; inputs (the task) come second | **RESTRUCTURE** | Order contradicts the task: result before input |
| Sleep: chooser sheet | Pick timer vs manual | — | **KEEP** | Footnote removed in the previous pass (D-110) |

Six dimensions, in short: the hub fails **layout composition** and **visual hierarchy**; manual
sleep fails **information architecture** (order); the timer has a **content simplification**
issue; History and Ghi nhanh are strong on all six.

## B. Design exploration

### Chăm sóc hub (`compare/hub_before_A_B_light_vi.png`)

| | Direction A: refined grid | Direction B: grouped list |
|---|---|---|
| Structure | Same sections, compact 2-column tiles (icon beside title, status under it); teasers gathered in a "Sớm ra mắt" group | One card per section, one row per destination (tinted icon, title, status line, chevron); teasers keep a "Sớm ra mắt" badge |
| Strengths | Keeps the tile feel; shorter than today | Whole hub in about one screen; status reads as a second line; overdue pill stands out; rows are full-width targets; matches Me / settings rows |
| Weaknesses | Titles and statuses wrap in half-width tiles ("Nhắc nhở / 2 nhắc đang / bật"); still equal weight; 200 % breaks words | Less "card" warmth; at 200 % a trailing pill crushed the title (fixed: the pill sits under the title) |

Weighted judgement: task efficiency, hierarchy and clarity clearly favour **B**; interaction equal;
visual quality A slightly; consistency B (shared row pattern). **Selected: B.** The prototype also
tried a frequency order (History, Stats first) and moved teasers last; **not shipped**: the order is
an owner decision (D-069, D-083, D-085, enforced by `care_hub_test.dart` and
`solids_screens_test.dart`), so it is reported as L3 below.

### Manual sleep (`compare/manual_before_A_B.png`)

| | Direction A: refined | Direction B: inputs first |
|---|---|---|
| Structure | Same order; the duration card shrinks to one tinted line above the inputs | Start / End rows first, duration as the group's total row |
| Strengths | Minimal change | Order follows the task; the result sits where the eye ends; one surface instead of two |
| Weaknesses | Result still before input | Duration is less of a "hero" (it was never the task) |

**Selected: B.** Overnight state checked separately (`compare/manual_after_variants.png`): "Qua đêm"
chip next to the label, the long duration wraps under it, the overnight note follows.

## C. Implementation

| File | Change |
|---|---|
| `apps/mobile/lib/features/care/care_hub_screen.dart` | `_Grid` → one `ClCardGroup` per section; `_Tile` → full-width row (36 pt tinted icon, title, status or warm overdue pill under the title, chevron or "Sớm ra mắt" badge); the large-text single-column branch is gone (rows wrap by nature); order unchanged |
| `apps/mobile/lib/features/care/timer_screens.dart` | `ManualSleepScreen`: hero card removed; duration (+ "Qua đêm" chip) is the total row of the Start / End group. `SleepRing`: label and start time removed from the visible ring (kept in its semantics label, now including the start time) |

Copy removed: the ring's "Đang ngủ" / "Asleep" and "Từ 13:37" / "Since 13:37" (repeated the heading).
No ARB change. Behaviour preserved: same destinations, search, caregiver rule (no Tăng trưởng),
teaser toast, timer actions, manual save / validation / timer link.

## D. Visual evidence (all actual Flutter renders)

- `compare/hub_after_all_variants.png`: Light vi / en, Night care vi / en.
- `compare/hub_200_before_after.png`: 200 % text, before / after.
- `compare/manual_after_variants.png`: Light vi, Night en, overnight Light vi / Night en, 200 %.
- `compare/timer_before_after.png`: Light vi before / after, Night en before / after, 200 %.
- `compare/history_quicklog_kept.png`: the KEEP screens as they are now.
- Loading states (History / Stats skeletons) are in the previous report
  (`care-autonomous-improvement.md`).

## Self-critique (after re-rendering)

1. Primary task clear: yes on all three changed screens.
2. Most important content dominant: hub overdue pill yes; manual inputs yes; timer readout yes.
3. Repetition: removed in the ring; hub subtitles were simplified in the previous pass.
4. Too many cards / colours: hub went from 11 cards to 3 groups; tinted icons kept for
   recognition.
5. Efficiency: hub fits about one screen (was two).
6. vi / en: checked; English rows wrap ("Expected / developmental phases") without collisions.
7. Light / Night care: checked; the overdue pill keeps ink on sunshineSoft.
8. Large text: hub rows and manual rows wrap; first iteration of B crushed the title next to the
   trailing pill → moved the pill under the title.
9. New friction: none found; every row is a single full-width target.
10. Better than the original: yes for hub and manual sleep (side-by-side sheets); the timer is a
    small, safe refinement.

Iterations: hub pill placement (200 %), manual duration row alignment (it centred until made
full width), hub order reverted to the owner's after the tests flagged D-069 / D-085.

## E. Verification

- `flutter analyze` (care): no issues.
- `flutter test --exclude-tags golden`: **2,533 passed**.
- `tool/golden_freshness.sh` (whole suite): **1,746 / 1,746 Current**.
- Baselines updated after inspection: `s4/v1i_care_hub_*`, `s4/v1i_care_hub_caregiver_*`,
  `s5/25_sleep_timer_*`, `s5/9c_timer_offline_*`, `s5/26_manual_sleep_*` (20 files).
- 200 % probe (`care_scale_probe_test.dart`): no overflow on 18 screens × vi / en.

**Remaining issues:** frequency order of the hub (L3, below); long-press for manual sleep in
Ghi nhanh is undiscoverable (manual entry is reachable from the sleep chooser and the timer link,
so no capability is hidden); the earlier `DayRhythm` 200 % word breaks (Today-owned file).

**L3, decided:** the owner approved the frequency order on 2026-10-26 (D-113): Lịch sử · Thống kê ·
Nhắc nhở · Tiêm chủng · Tăng trưởng · Ăn dặm · Dinh dưỡng, teasers last in every group. Implemented,
tests updated (`care_hub_test.dart`, `solids_screens_test.dart`), baselines re-rendered.

## F. Design skill improvements

- `senior-ui-ux`: principle "preserving behaviour ≠ preserving the layout"; Audit classifies
  KEEP / REFINE / RESTRUCTURE / REDESIGN; Design explores A / B for structural problems; mandatory
  self-critique; new reference `references/structural-evaluation.md` (six dimensions, decisions,
  exploration rules, weights, owner-set orders are L3, self-critique, report).
- `cl-design-review`: the Decide step classifies the screen and compares rendered prototypes.
- `cl-screen-patterns`: "the current layout is not the design"; equal weight for unequal
  importance is a hierarchy defect.
- `cl-components`: restructuring a shared component with the same function is L2; fix it once.
- `cl-ux-writing`: copy follows structure in a redesign.
- `cl-design-foundations`: redesigns reuse tokens.
- Recorded as D-112 in `docs/product/business-map.md`; `CLAUDE.md` updated.

Future tasks start from a fresh render, decide whether the structure itself is the problem, and
must show A / B renders before restructuring; the order check against owner decisions caught a
real conflict in this pass.

## Correction (2026-10-26): renders vs the live product

The owner pointed out that every Chăm sóc feature is live. The "Sớm ra mắt" rows in the hub
renders above came from the default care fixture (no published stages or articles, `rhythm` flag
off, no nutrition stage), not from what families see. The code's teaser fallback is unchanged
(kept for content not yet published). Added `s4/v1i_care_hub_live` (golden) and
`assets/hub_live_current_*` (exploration): the hub as families see it, with no teasers and
Dinh dưỡng showing "Giai đoạn 0–1 tháng". `cl-design-review/references/visual-verification.md` §0
now requires fixtures that match the live product state. D-113 order applies unchanged.
