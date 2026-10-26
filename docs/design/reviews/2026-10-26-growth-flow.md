# Growth flow review (2026-10-26)

Scope (owner): Nhịp lớn lên, gợi ý, Wonder Weeks (giai đoạn, lịch), tóm tắt tuần, Bàn giao, Mốc
phát triển. Workflow v2 (D-110 … D-112): fresh render first (256 / 256 baselines Current in
`rhythm`, `rhythm_week`, `personal_day`, `milestone`, `ai`, `hn` goldens), then simplify, then
structure. Decision record: D-116.

## Tóm tắt (VI)

- Bỏ các dòng giải thích lặp lại; giữ mọi lưu ý về sức khoẻ / tham khảo là duy nhất.
- Không đổi bố cục màn nào: các màn này đã có cấu trúc tốt, vấn đề là chữ thừa.

## Classification

| Screen | Decision | Why |
|---|---|---|
| Nhịp lớn lên (NL01) | REFINE | Two clear layers (Lịch tham khảo vs Nhịp riêng của con); the tinted sub-panels inside the own-rhythm card are panels, not nested cards. Redundant wording only |
| Giai đoạn (NL04), Lịch tham khảo (NL03) | REFINE | Staff-facing model version shown to parents |
| Tóm tắt tuần | REFINE | Subtitles restating the section; a sleep note repeating the tile |
| Mốc phát triển list / detail | REFINE | Lead explains the obvious; detail said "tham khảo / hỏi bác sĩ" three times |
| Bàn giao | KEEP | Facts → next → how to help → summary → safety; every line earns its place |
| Gợi ý, Hoạt động, Check-in, digest settings | KEEP | Short, decision-relevant copy; source lines are the required attribution |

## Changes (before → after)

| Where | Before | After | Action |
|---|---|---|---|
| NL01 calendar card | "Dự kiến 12/10 – 21/10 · còn 4 ngày đến giai đoạn" | "… · còn 4 ngày" | REWRITE |
| NL01 calendar card | "Theo ngày dự sinh ước tính 21/09 · chỉ để tham khảo, mỗi bé một khác" | "… · mỗi bé một khác" (pill says LỊCH THAM KHẢO) | MERGE |
| NL04 Nguồn & duyệt | "Mô hình ref_20261015_01" | removed | REMOVE (internal) |
| NL03 footer | "… chưa được chứng minh chính xác cho từng bé. Mô hình ref_…" | without the version | REMOVE (internal) |
| Tóm tắt tuần | "Từ nhật ký của cả nhà", "Từ ghi nhận và nhật ký của nhà mình" | removed | REMOVE |
| Tóm tắt tuần | "Ngủ trung bình chỉ tính những ngày được ghi đủ … Ngày thiếu ghi không bị tính là 0." | removed on screen; kept in "Chia sẻ" text | REMOVE / RELOCATE |
| Mốc phát triển | "Ghi lại khi bạn thấy bé làm được. Mỗi bé có nhịp riêng." | "Mỗi bé có nhịp riêng." | REMOVE |
| Mốc detail | "Khoảng tuổi chỉ để tham khảo … hỏi bác sĩ của bé." under the doctor card | only when the milestone has no doctor card | RELOCATE |

Preserved: "Không phải xác nhận một giai đoạn Wonder Weeks", "Kỹ năng không bắt buộc khớp …",
"Một số bé không có thay đổi rõ …", the WHO / AAP / NHS attribution, "Không có dấu hiệu sức khoẻ…",
"Thông tin là ghi nhận của gia đình, không phải chẩn đoán", "Không chấm điểm, không so sánh…".

## Verification

- Goldens updated after inspection: `rh/nl01_free_*`, `rh/nl01_advanced_*`, `rh/nl03_calendar_*`,
  `rh/nl04_stage_*`, `rh/week_free_*`, `rh/week_advanced_*`, `rh/week_video_*`, `ms/3a_list_*`,
  `ms/3b_detail_*`, `ms/3c_record_*`; whole suite 1,750 / 1,750 Current.
- Self-critique caught an empty line left in "Nguồn & duyệt" when a model has no extra source:
  fixed and re-rendered.
- Tests updated to the new copy: `rhythm_overview_test.dart`, `milestones_test.dart`.
