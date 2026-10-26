# Care: autonomous UI/UX improvement (2026-10-25)

Workflow: `senior-ui-ux` §2 (D-109 autonomy; D-110 Simplify; D-111 fresh renders). Hôm nay
(Today) was out of scope; Version A is being implemented in a separate session. Images are in
`assets/care-2026-10-25/`.

## Tóm tắt cho chủ sản phẩm (VI)

- **Đã sửa, đã render và đã xem ảnh:** Lịch sử và Thống kê không còn hiện "Chưa ghi…" trong lúc
  đang tải (có khung tải đúng hình dạng); tiếng Anh hết lỗi "1 feeds", "420 ml" không còn bị
  ngắt dòng giữa số và đơn vị.
- **Chữ cỡ lớn (200 %):** trước đây gần như mọi màn Chăm sóc bị tràn chữ (đồng hồ ngủ, hút / bú
  mẹ, Ghi nhanh, Thay tã, Lịch sử, Chăm sóc, Nhập giấc ngủ, chi tiết bản ghi). Giờ cả 18 màn kiểm
  tra (vi + en) không còn tràn; vài chỗ ngắt chữ còn lại được liệt kê ở §6.
- **Chăm sóc:** "3 mũi quá hạn" được tô ấm kèm biểu tượng thay vì chữ xám mờ.
- **Gọn hơn (D-110):** bỏ phụ đề lặp lại tiêu đề ("Mọi lần đã ghi", "Cân nặng, chiều dài"), bỏ
  chú thích dài ở sheet Ghi giấc ngủ, bỏ câu thừa ở ngày trống; ghi chú "giấc qua đêm" chỉ hiện
  khi giấc thực sự qua đêm. Nút Thay tã ghi rõ "Lưu lần thay tã".
- **Không thay đổi:** cách tính, cách lưu, đồng bộ, quyền, điều hướng, thứ tự Adaptive.
- **Cần chủ sản phẩm quyết:** không có quyết định L3 mới từ đợt này (xem §8).

## 1. Screen inventory

| Screen / sheet | Code | Archetype | Goldens |
|---|---|---|---|
| Chăm sóc hub | `features/care/care_hub_screen.dart` | Overview / index | `s4/v1i_care_hub*` |
| Ghi nhanh | `care_sheets.dart` `showQuickLog` | Action sheet | `s4/19a_quick_log` |
| Bú bình / Bú mẹ / Hút sữa / Thay tã sheets | `care_sheets.dart` | Sheet form | `s4/22_bottle`, `23_breast`, `23a_pump`, `24_diaper` |
| Timers (sleep, breast, pump) | `timer_screens.dart` `TimerScreen` | Live state | `s5/25_sleep_timer`, `23b`, `23c`, `9c_timer_offline` |
| Ghi giấc ngủ chooser | `timer_screens.dart` | Action sheet | `s5/25a_sleep_chooser` |
| Nhập giấc ngủ | `ManualSleepScreen` | Form | `s5/26_manual_sleep` |
| Giấc ngủ trùng nhau | `OverlapScreen` | Decision | `s5/27_overlap` |
| Record detail | `care_screens.dart` `RecordDetailScreen` | Detail | `s4/21_record_detail`, `12e_view_only` |
| Tăng trưởng | `care_screens.dart` `GrowthScreen` | Form | `s4/28_growth` |
| Lịch sử (all / feed / pump / sleep / diaper / growth) | `history_screen.dart` | Timeline | `s6/20*`, `12d_history_caregiver` |
| Thống kê bú / ngủ | `stats_screens.dart` | Insights | `s6/20g*`, `20h*` |

Shared pieces touched: `ClTopBar`, `ClBabySwitcher` (`core/widgets/cl_navigation.dart`),
`ClSyncStatus` (`cl_status.dart`), `ClChoiceTile`, `ClDayPill` (`cl_choices.dart`), `ClTimeRow`
(`cl_inputs.dart`). `DayRhythm` (History summary) lives in `today_screen.dart` and was **not**
edited (another session owns that file).

## 2. Baseline findings (fresh renders)

Baselines were confirmed fresh first (168 / 168 care, history and timer goldens matched the code).
A 200 % text probe (`test/design_explorations/care_probe/care_scale_probe_test.dart`, 18 screens ×
vi / en) was added because no golden covers text scale.

| # | Finding | Evidence | Severity | Level |
|---|---|---|---|---|
| C1 | History / Stats show the empty day ("Chưa ghi…", zeros) while records load | C `history_screen.dart`, `stats_screens.dart` (`.value ?? []`); R after the fix | High (trust, G1 risk) | L1 |
| C2 | en "1 feeds"; "420 / ml" wraps between number and unit | R `s6/20_history_light_en`, `20a_history_feed_nightCare_en` | Blocker (grammar) | L1 |
| C3 | At 200 % text: 16 of 18 probed screens overflow (timer clocks run across the ring, sync pill pushed off-screen, Ghi nhanh / Thay tã labels clipped, day strip clipped, "Lịch / sử" title squeezed, record-detail labels one letter per line, hub tiles break words "Remind/ers") | R `05_text200_before_*.png` | High (a11y, G2 risk for "Kết thúc giấc ngủ" area) | L1 / L2 |
| C4 | "3 mũi quá hạn" on the hub is muted grey: the one attention item looks like a caption | R `s4/v1i_care_hub_light_vi` | Medium | L2 |
| C5 | Diaper sheet primary is a bare "Lưu" while siblings say "Lưu cữ bú", "Lưu hút sữa", "Lưu giấc ngủ" | R `s4/24_diaper` | Low | L1 |
| C6 | Redundant / contextual copy (Simplify): hub subtitles "Mọi lần đã ghi", "Cân nặng, chiều dài"; sleep-chooser footnote on switching modes; empty-day line about back-logging; overnight note shown on every manual sleep | R `s4/v1i_care_hub`, `s5/25a_sleep_chooser`, `s6/20e_history_empty`, `s5/26_manual_sleep` | Low | L1 |

Strengths kept: bottle prefill + presets, one primary per sheet, timer sync pill, offline / pending
states, overlap screen's "nothing merged or overwritten", the role notes in History and record
detail.

## 3. Simplify table (D-110)

| Element | Class | Action |
|---|---|---|
| Hub "Lịch sử · Mọi lần đã ghi" | Redundant (restates title) | REMOVE (key deleted) |
| Hub "Tăng trưởng · Cân nặng, chiều dài" | Redundant | REMOVE (key deleted) |
| Hub "Thống kê · Bú, ngủ theo ngày" | Contextual but decision-relevant (no diaper stats) | PRESERVE |
| Hub reminders / vaccine / solids / nutrition status lines | Essential status | PRESERVE (overdue drawn warm) |
| Sleep chooser footnote "Đổi cách bất cứ lúc nào…" | Redundant: each option says what it does | REMOVE (key deleted) |
| Empty day "Nếu quên ghi lúc đó…" | Redundant: the button says "Ghi bù …" | REMOVE (key deleted) |
| Manual sleep overnight note | Contextual: only for overnight sleeps | RELOCATE to the overnight state |
| Record detail "Mọi người trong gia đình thấy… Người ghi và Cùng nuôi được sửa" | Essential (permissions) | PRESERVE |
| History caregiver lock note | Essential (permissions) | PRESERVE |
| Timer "Cả nhà đang thấy / Chỉ trên máy này" | Essential (sync) | PRESERVE |
| Bottle "đã điền theo lần trước", "Gợi ý cho bé 3 tuần" | Essential (prefill disclosure, basis) | PRESERVE |

## 4. Implemented changes

| Change | Files | Level |
|---|---|---|
| Content-shaped skeletons while records load (History day, Stats); a11y label "Đang tải ghi chép" | `history_screen.dart` `_DaySkeleton`, `stats_screens.dart` `_StatsSkeleton` | L1 |
| en ICU plurals and no-break spaces (`rhythmFeeds`, `rhythmBreast`, `minutesAndFeeds`, `milkDayTip`, `breastDayTip`, `lastNightInsight`, `lastNightBreastInsight`) | `tool/care_ux_strings.py`, ARB | L1 |
| Top bar: a lone trailing pill takes the remaining width and ellipsises instead of running off-screen; the bar may grow past 44 pt only at large text | `cl_navigation.dart` `ClTopBar` | L1 (shared) |
| Min heights instead of fixed heights: baby chip, sync pill, choice tile, quick-log tile, month chip, manual-sleep hero | `cl_navigation.dart`, `cl_status.dart`, `cl_choices.dart`, `care_sheets.dart`, `history_screen.dart`, `timer_screens.dart` | L1 |
| Timer readouts fit their ring / discs; total time scales down to the width | `timer_screens.dart` | L1 |
| Day pill content scales inside the fixed pill | `cl_choices.dart` `ClDayPill` | L1 |
| Large text: Ghi nhanh 2 per row; hub one column; `ClTimeRow` and record-detail rows stack value under label; History title + month chip wrap | `care_sheets.dart`, `care_hub_screen.dart`, `cl_inputs.dart`, `care_screens.dart`, `history_screen.dart` | L2 |
| Record value on one line ("120 ml") | `care_screens.dart` | L1 |
| Hub overdue vaccines: warm pill (sunshineSoft + ink + alert icon) | `care_hub_screen.dart` | L2 |
| "Lưu lần thay tã" / "Save diaper change" | `care_sheets.dart`, ARB `saveDiaper` | L1 |
| Simplify removals and the overnight-only note (§3); hub `_Tile.subtitle` optional | `care_hub_screen.dart`, `timer_screens.dart`, `history_screen.dart` | L1 |
| Manual-sleep "Teddy đang ngủ? Bắt đầu hẹn giờ" as one wrapping paragraph | `timer_screens.dart` | L1 |

Behaviour unchanged: save / undo, timer lifecycle, calculations, sync, permissions, routes and
filters. Thresholds for the large-text layouts: text scale > 1.3.

## 5. Before / after

- `01_history_en_plural_before_after.png`: "4 feeds · 420 / ml", "1 feeds" → "4 feeds · / 420 ml",
  "1 feed" (Light en; Night care en).
- `02_loading_skeletons_after.png`: new History (vi Light, en Night) and Stats loading states.
- `03_hub_overdue_and_manual_sleep_before_after.png`: hub Night vi before / after, hub Light en
  after; manual sleep before / after (sub-pixel).
- `04_simplify_hub_chooser_empty_after_vs_before.png`: hub after; sleep chooser before / after;
  empty day before (vi) / after (en Night).
- `05_text200_before_{a,b}.png` vs `06_text200_after_{a,b}.png`: 200 % text, the same 10 screens.

New baselines: `s6/20i_history_loading_*`, `s6/20j_sleep_stats_loading_*`. Updated (inspected):
`s6/20_history_*_en`, `20a_history_feed_*_en`, `12d_history_caregiver_*_en`, `20e_history_empty_*`,
`s4/v1i_care_hub_*`, `s4/24_diaper_*`, `s5/25a_sleep_chooser_*`, `s5/26_manual_sleep_*`.

## 6. Review results

Gates: G1–G6 pass on the changed screens (loading no longer reads as empty; no action removed;
roles unchanged). Content necessity (dimension 11): improved on hub, sleep chooser, empty day,
manual sleep. 200 % probe after the fix: **no overflow on any of the 18 screens × vi / en**; the
images were opened. One probe case, the sleep chooser, rendered Today without opening the sheet at
200 %, so the chooser sheet at 200 % is **unverified**.

Remaining (not fixed, reported):

| Item | Why it stays | Severity |
|---|---|---|
| `DayRhythm` summary at 200 %: "Breastfeed/ing", "2 / change…" break mid-word | Lives in `today_screen.dart`, owned by the Version A session right now | Medium |
| en `ScreenHeading` "Teddy is br/eastfeedin/g" at 200 % | A single word wider than the screen at 200 %; needs a shared heading rule | Low |
| Pump timer primary "Done · enter am…" truncates at 200 % | `ClButton` is single-line by design (`cl-design-foundations` known weak point) | Medium |
| Growth en "Head circu/mference" at 200 % | Two-column field labels | Low |
| Sleep ring readout at 200 % renders at about the 100 % size | The ring has a fixed size; scaling the ring itself is a larger change | Low |
| Errors loading History / Stats still fall through to the data view | No error-state design yet for care ranges | Medium |

## 7. Tests

- `flutter analyze` (care, core, tests): no issues.
- `flutter test --exclude-tags golden`: all pass after updating three tests to the new copy
  (`care_test.dart` no-break spaces and "Lưu lần thay tã", `history_test.dart`).
- Golden suite (whole, because shared widgets changed): every diff attributed; the only failures
  left are `pd/notes_editor_*` (another session's change, see `docs/design/golden-baseline-audit.md`).
- 200 % probe: `flutter test --update-goldens test/design_explorations/care_probe/care_scale_probe_test.dart`
  (writes only to that folder; overflow log `overflows_2.0.txt`).

## 8. Outstanding L3 decisions

None introduced by this pass. Still open from earlier audits: the canonical term for reminders
("Nhắc việc" vs "Nhắc nhở"), "Premium" vs "Cao cấp".
