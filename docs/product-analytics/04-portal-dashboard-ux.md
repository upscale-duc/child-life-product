# Portal dashboard UX/UI specification

**Thiết kế để review, chưa là UI đã implement.** Dùng existing Portal theo D-063/P-137. Theo scope cập nhật, section thứ sáu là **Chi phí vận hành / Operational Cost**; IAP, revenue, MRR, paid conversion/churn và Free/Plus/Pro filter nằm backlog, không hiển thị KPI giả hoặc chiếm chỗ V1.

## Navigation và design-system reuse

Existing entry `/analytics`, `/analytics/features` với Growth/Features trong [`Analytics.tsx`](../../apps/portal/src/screens/Analytics.tsx). Đề xuất subroutes mới dưới existing analytics route, không tạo app/deploy khác:

| Section VI / EN                              | Proposed path            | Câu hỏi chính / metric IDs                                                       |
| -------------------------------------------- | ------------------------ | -------------------------------------------------------------------------------- |
| Tổng quan / Executive Overview               | `/analytics`             | Bao nhiêu người/gia đình đang dùng, có nhận giá trị? A01–A12, C07 summary        |
| Thu hút & quay lại / Acquisition & Retention | `/analytics/acquisition` | Đăng ký→onboarding→activation; cohorts nào quay lại? A01/A05–A10/A13/A14         |
| Kỷ niệm / Memories                           | `/analytics/memories`    | Ảnh qua review có ready? Video/story/template nào hoàn tất? M01–M15              |
| Nhắc thông minh / Smart Engagement           | `/analytics/engagement`  | ENG-01–06 đủ điều kiện→thực hiện, suppression/fatigue ra sao? E01–E06            |
| Sử dụng tính năng / Feature Adoption         | `/analytics/features`    | Care/Grow/Remember/Family/Lumi/Personalization/Engagement có giá trị gì? F01–F07 |
| Chi phí vận hành / Operational Cost          | `/analytics/cost`        | Credits, provider tokens/coverage, render/storage và blended cost? C01–C08       |

Giữ `/analytics/features`; root chuyển Overview sau approved migration, saved links/query filters versioned. Existing Assistant/Premium operations tiếp tục riêng theo quyền; analytics drill-down không link thẳng tới family/job identities. Reuse `context.ts`, `Shell.tsx`, existing navigation/breadcrumb/locale/theme và API loading patterns.

Reuse [`ui.tsx`](../../apps/portal/src/ui.tsx): `Page`, `Panel`, `Kpi`, `Segmented`, `SelectMenu`, `TableScroll`, `Loaded`, `Empty`, `LineChart`, `HBars`; existing shadcn/Radix `components/ui`, Recharts chart container/tooltips. Tokens từ [`index.css`](../../apps/portal/src/index.css), `@child-life/design-tokens`, Be Vietnam Pro và light/dark/system theme. Không hardcode palette mới hoặc migrate toàn Portal stylesheet để làm analytics.

Chỉ thêm thin reusable components thiếu: metric definition popover, confidence/coverage badge, funnel stage table, accessible cohort heatmap, custom range picker, insufficient/unavailable state. Extend wrappers hiện hành; không cài chart/design framework thứ hai.

## Shared page composition

```text
Existing Sidebar | Analytics > section          Locale · Theme · Staff menu
                 Title + definition scope       Export aggregates [if allowed]
                 [7d] [30d] [90d] [Custom] [Compare]  [Filters]
                 Date range · reporting timezone · As of · Coverage status
                 KPI row (4–6 cards)
                 Primary chart/funnel            One contextual breakdown
                 Detail table / cohort panel (progressive disclosure)
                 Data quality + Definitions + Suggested checks
```

Desktop ≥1200px: 4–6 KPI grid theo space, two-column primary/chart detail; tablet 768–1199px: 2 KPI columns, charts stacked, filter drawer, table scroll. Dưới768px: one-column safe fallback, không giả mobile là priority của staff console. Giữ existing shell responsive. Spacing theo tokens/tailwind spacing hiện hành; chart min width không đẩy toàn page tràn viewport.

Không quá hai charts chính trên initial section view; tables/details mở theo nhu cầu. KPI luôn có unit/window label, current value, numerator/denominator khi rate, previous-period delta hoặc reason unavailable, và definition icon. Chi phí tăng không được tô xanh như tăng outcome; semantic tone theo metric direction, kèm text chứ không chỉ màu.

## Filters và comparison contract

| Control          | Behavior                                                                                                                                                               |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 7/30/90/custom   | Default30 closed reporting days; custom đề xuất ≤366 days, from≤to, không future; date-range inclusive UI → half-open server instant range. Không silently clamp query |
| Platform         | All/iOS/Android; U/F có thể overlap cross-platform. Tooltip “Không cộng iOS + Android thành tổng”; total exact dedup union                                             |
| Locale           | All/VI/EN, app locale tại activity hoặc frozen cohort locale được metric khai báo; Portal language khác filter                                                         |
| Chapter          | All + approved Chapter IDs, unknown riêng; chưa mapping thì unavailable với explanation, không giả các Chapter chưa launch có0 adoption                                |
| Plan             | **Không hiển thị trong V1**; Free/Plus/Pro để backlog IAP                                                                                                              |
| Context/age band | Section-level current/retrospective và frozen onboarding age bands. Không exact DOB/custom baby-age slider hoặc family search                                          |
| Compare previous | Adjacent equal-length days, same filters/version/maturity. Incomplete previous → unavailable, không green/red fabricated delta                                         |
| Drill-down       | Click chart stage/cohort opens aggregate breakdown table với cohort/window/denominator preserved, không raw event/family details                                       |

Filters lưu versioned shareable query string bằng closed enums; không IDs/content trong URL. Backend trả `appliedFilters`, `unsupportedFilters` theo metric; unsupported filter không được âm thầm bỏ. UI hiển thị “Không áp dụng bộ lọc này / Filter not supported”, không trình bày global cost như iOS-only. Khi combo vượt query/privacy budget, đề nghị bỏ bớt filter, giữ previous approved view rõ trạng thái.

Không default filter selection làm small-cell probe lặp; API privacy controls trong [06](06-data-architecture.md) áp dụng cả chart/drill-down/export. Debounce filter changes, abort obsolete requests, cache by normalized approved query + metric version + snapshot. Khi source thiếu locale/Chapter, metric unavailable cho breakdown đó, không gán unknown vào VI hoặc Chapter01.

## 1. Executive Overview

KPI đầu: New users(range), Active users(range distinct), Active families(range distinct), Activation7d(mature registration cohort), First Memory7d(creator cohort), WMF(last closed ISO week). Unit/time badges tránh nhầm counts theo range với weekly metric. Có “Chi tiết hoạt động” panel compact cho DAU/WAU/MAU users **và** family metrics được label rõ; không đổi units mà giữ cùng tên.

Primary line: active users/families, chọn một series family/user và1/7/30 rolling, shared date axis. Secondary panel: D1/D7/D30 mature user retention (N/D, waiting state khi chưa đủ ngày). Operational cost summary chỉ khi có quyền/source; partial/unknown rõ, không revenue card. Link tới section đã filter.

“Nên kiểm tra tiếp / Suggested checks” tối đa3 rows: evidence→question→aggregate detail. Thứ tự ưu tiên data-quality/privacy/cap violations, rồi stage drop-off đủ data, rồi cost unknown coverage. Đây là rule-based review suggestions, không AI tự phán nguyên nhân hay uplift. Ví dụ “Ready coverage còn thiếu → kiểm tra upload attribution”, không kết luận notification kém khi delivery unknown.

## 2. Acquisition & Retention

KPI: registrations, completed onboarding, activation7d, time to first meaningful action với completion coverage. Registration trend theo R, known channel/unknown breakdown bên cạnh. Onboarding funnel: account→primary context→permission choice→complete→qualified action; denial/skip quyền không tự làm thất bại onboarding.

Retention heatmap: choose strict D1/D7/D30 users hoặc weekly family T0..T12; column label, denominator, metric version rõ. Cell tooltip N/D/window/completeness; hatch immature, suppressed small-cell hiển thị khác zero. Cohort entry/platform/locale/age band snapshot, không thay denominator theo outcome. Late/early onboarding bảng so sánh descriptive, không coi late join thiếu early-life data là inactive.

## 3. Memories Analytics

KPI: eligible Auto Save users, setup adoption, cloud-ready photos, historical import ready, filed Story/card/video (separate counts), unresolved review proxy. Capability selector iOS scan vs manual import; denominator không toàn app users.

Primary funnel `discovered → review visible → approved → cloud ready`, display counts theo P và switch E rõ unit. Click stage xem skipped/rejected/queued/processing/error/unknown/source gone. Second funnel `ready media-set → video started → rendered → filed → optional share result`; text Story ở branch draft→saved, card có own filed branch.

Below-fold tabs: Templates (opens/requests/completions per ID/version), Render reliability (jobs vs attempts), Historical/backfill (actual age bands/current vs retrospective), Sharing/repeat. Không ranking theo opens rồi gọi “most valuable”; default filed families/eligible opportunities, unavailable/no exposure denominator giữ rõ.

## 4. Smart Engagement Analytics

Kind selector ENG-01..06, overall coordinator quality ENG-00 luôn có. KPI eligible users/families/opportunities (units explicit), action-completed/eligible, opt-out, fatigue affected, delivery-observation coverage. Flow columns: eligible→decision→scheduled→attempted→provider accepted/dispatch unknown→opened→completed; no fake Delivered column.

Table theo reminder type: cohort N, W, scheduled/attempted/accepted/opened/completed N và rates, suppression/cancel/expiry reasons, maturity/unknown. Lifecycle counts không ép giảm đơn điệu vì direct in-app completion có thể không push-open. Dismiss/snooze/fatigue panel phân biệt explicit choice với response unknown. Retrospective milestone không có outdated push rows; vẫn có in-app completion cohort.

Experiment comparison tab chỉ xuất hiện khi approved assignment thực có data. Show unit/arm/sample/maturity/exposure/guardrails, intent-to-treat denominators. No assignment → “Chưa có thử nghiệm / No experiment assigned”, không dựng control từ người deny permission. Tránh causal lift label từ before/after.

## 5. Feature Adoption

Seven module rows: Care, Grow, Remember, Family, Lumi, Personalization, Smart Engagement. Mỗi module có eligible families, exposure/open, meaningful action, coverage và trend; chỉ meaningful metric là primary adoption. Growth values/health topics không vào table.

Cross-module matrix chỉ aggregate family overlaps trên cùng period, same coverage; cell dedup và privacy. Chapter/age context toggle rõ cohort-entry vs event-time, mapping unavailable không fake. Family subpanel: active caregivers, invite accepted, authorized content view/replies; “có thành viên người thân” giữ legacy description, không gọi collaboration rate.

## 6. Operational Cost

KPI: committed credits (commercial units), observed input/output/cache tokens, known usage coverage, rated AI estimate(currency), render/storage metering coverage, blended cost/active family khi đủ dữ liệu. Không cộng credits với currency/tokens hoặc rates giữa nguồn thiếu coverage.

Cost table columns: service, period, observed usage, estimated amount, reconciled amount, currency, cost basis, rate/source version, known/unknown coverage, freshness. Chỉ một basis/workload vào total; actual replaces estimate sau reconciliation, không stack cả hai. Existing Assistant model tables reused/cross-linked ở aggregate scope, không show chat/task IDs.

Render output duration không gọi compute billable time; storage quota bytes không coi invoice. Cost source thiếu → unavailable, chưa0. Total partial có label “Chi phí đã biết / Known costs only”; blended ratio không là chi phí riêng từng gia đình. Revenue/MRR/churn/paid plans không placeholder chart trong V1; backlog link chỉ trong docs/runbook.

## States, copy và accessibility

| State                     | VI / EN                                                                | Required behavior                                                                           |
| ------------------------- | ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Loading                   | Đang tải số liệu / Loading metrics                                     | Stable skeleton, accessible progress, giữ title/filters; không flash zero                   |
| Empty valid period        | Chưa có dữ liệu / No data yet                                          | Explain source start/range; no synthetic series; export header+empty metadata nếu permitted |
| Unavailable source/filter | Chưa đo được chỉ số này / This metric is not available                 | Reason source/coverage/filter; no0 or implied success                                       |
| Insufficient              | Chưa đủ dữ liệu để hiển thị / Insufficient data to display             | Privacy/sample/maturity reason riêng, không lộ hidden N qua tooltip/export                  |
| Provisional/immature      | Đang chờ hoàn tất cửa sổ đo / Observation window is still open         | Watermark/cutoff/version visible; no final retention/converted label                        |
| Stale/partial             | Dữ liệu cập nhật đến… / Data available through…                        | Timezone/source coverage, retry action theo quyền; no production mutation button            |
| Permission denied         | Bạn chưa có quyền xem mục này / You do not have access to this section | Existing permission UX, backend enforcement; no hidden data in network/cache                |
| Error                     | Không tải được dữ liệu. Thử lại / Could not load metrics. Retry        | Fixed coarse error, preserve filters, no raw server/source details                          |

All strings qua `messages.ts` VI/EN parity; preserve approved metric semantics. Keyboard controls, visible focus, definition popover focus/escape, text alternatives/table for charts, contrast in light/dark, no color-only heatmap meaning. Chart/table formatting theo UI locale, source timezone/currency explicit. Date picker/popovers dùng existing Radix primitives.

CSV: only server-approved aggregates, snapshot/query/filter/version/unit/N/D/maturity/freshness/cost basis included; same suppression as UI, no hidden small-cell values, formula-injection escaping bằng existing formatter review. Export permission và audit bắt buộc; cost exports thêm cost permission. Không xuất raw IDs hoặc synthetic fixture rows từ production endpoint.

## UX acceptance

Đúng sáu sections, desktop/tablet light/dark, VI/EN, all filters supported status, previous period and drill-down preserve denominator; tooltips đọc được metric ID/definition/W; no-data/unknown/insufficient khác0. Synthetic fixtures hiển thị **DỮ LIỆU KIỂM THỬ / TEST DATA** ở isolated test build, không production toggle demo. Working-system acceptance sau spec approval phải nối app/backend events thật tới aggregate→API→UI, không chỉ các chart từ fixtures.
