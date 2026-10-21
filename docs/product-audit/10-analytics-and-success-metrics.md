# Analytics & success metrics

Cập nhật 21/10/2026: các mô tả baseline/proxy gốc giữ snapshot audit; instrumentation đã sửa xem [implementation report](11-implementation-report.md). Phần ENG bổ sung cuối file là thiết kế mới, chưa triển khai hoặc có số liệu delivery.

Đây là measurement design cho bước triển khai, **không phải kết quả kinh doanh**. Không truy cập analytics production hoặc user research; không đặt baseline, % uplift hoặc revenue forecast giả.

## Những gì đã có

| Nguồn hiện tại                               | Ý nghĩa thực tế                                                                                                    | Không được suy ra                                                                       |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------- |
| `familyActivity` + `statsDaily`              | Activity/cohort theo family, calendar VN; device heartbeat hoặc domain writes; platforms/features                  | User DAU; người mở app đã tương tác từng bé; causal retention lift                      |
| `appEventsDaily` + appEvents allowlist       | Counters aggregate, fixed dimensions; Auto Save setup/permission/actions, gates, personalization, paywall, summary | Unique users/families, funnel conversion theo người, event delivery exactly once        |
| `contentStatsDaily` + PersonalizationMetrics | Content/version answers và eligible aggregates hiện có                                                             | Một impression→outcome conversion đã liên kết theo household nếu chưa có denominator đó |
| `assistantTasks`, quotaOps, staff Assistant  | Attempts, outcomes, modelCalls, credit reserve/commit/release, estimated costs                                     | Provider tokens/invoice cost hoặc mọi call đã được vendor tính tiền                     |
| Media/job/data/deletion state                | Operational truth cho ready/filed/failed/verified                                                                  | `createdAt` là upload success; renderer completed là user có video trong Memories       |
| PersonalImpression + digest events           | Client viewport seen; scheduled/opened event nếu client báo                                                        | OS delivered, người đã đọc nội dung, sustained engagement                               |

Nguồn: [E09 · `AutoSaveController.approve / recordUploaded`](../../apps/mobile/lib/features/auto_save/auto_save_controller.dart#L835); [E14 · `createMemory / processUpload / purgeMediaBin`](../../firebase/functions/src/memories.ts#L157); [E18 · `completeKeepsakeJob`](../../firebase/functions/src/keepsake-jobs.ts#L604); [E35 · `personalizedDay / updatePersonalization / reservePersonalizedDigest`](../../firebase/functions/src/personalization-v2.ts#L398); [E45 · `assistantPool / assistantUsage / recentUsage`](../../firebase/functions/src/assistant-usage.ts#L78); [E47 · `staff estimates modelCalls × unit cost`](../../firebase/functions/src/assistant-staff.ts#L223); [E48 · `dayWrites / markDeviceActivity / familyActivity`](../../firebase/functions/src/analytics.ts#L163); [E49 · `appEvents / appEventDims / recordAppEventSchema`](../../packages/contracts/src/account.ts#L260); [E50 · `PersonalImpression / personalEvent`](../../apps/mobile/lib/features/rhythm/personalization_events.dart#L25).

Personalization v2 đã bổ sung events/sink/viewport impression; không đưa lại phát hiện cũ “events chưa có consumer” vào backlog. Khoảng hở là semantics, authority, dedup, denominator và thực nghiệm hiệu quả.

## MET-01: các proxy dễ gây kết luận sai

- AutoSaveApproved và savedByMonth là **queued**, chưa cloud ready; xem MEM-06.
- `dayWrites` count media theo `createdAt`, không filter ready và count stories không phân biệt draft/saved; đây là usage/write activity, không phải completed memory/story outcome.
- `markDeviceActivity` mark tất cả family memberships của người đó; chưa chứng minh người ấy mở từng baby/family. Server membership expiry không nên bị bỏ qua khi gọi metric “active authorized family”.
- Aggregate event ratios không phải conversion theo unique entity; một power user hoặc retry có thể đóng góp nhiều lần.
- Digest scheduled không phải delivered; notification opened là event khác. Revoked/offline device có thể giữ scheduled generic notice.
- VN operational reporting day khác baby-local/monthly credit window; dashboard cần ghi timezone và metric version.

Các nhận định trên dựa implementation [E09 · `AutoSaveController.approve / recordUploaded`](../../apps/mobile/lib/features/auto_save/auto_save_controller.dart#L835); [E35 · `personalizedDay / updatePersonalization / reservePersonalizedDigest`](../../firebase/functions/src/personalization-v2.ts#L398); [E48 · `dayWrites / markDeviceActivity / familyActivity`](../../firebase/functions/src/analytics.ts#L163); [E49 · `appEvents / appEventDims / recordAppEventSchema`](../../packages/contracts/src/account.ts#L260); [E50 · `PersonalImpression / personalEvent`](../../apps/mobile/lib/features/rhythm/personalization_events.dart#L25); audit chưa đo mức sai lệch thực tế.

## Kết quả giá trị chính đề xuất

**Tỷ lệ household trong nhóm đủ điều kiện có ít nhất một kết quả hữu ích được xác nhận trong tuần.** Các kết quả phải tách loại: ready memory được xem, saved story được giữ/chia sẻ, completed care/handover task, hoặc activity được người dùng báo helpful. “Mở app” và “mở card” không tự tính là helpful.

Mẫu số là households eligible trong cohort/tuần đã định nghĩa, không chỉ người trả lời. Nếu khảo sát usefulness tự nguyện, báo **response rate và respondent-level helpfulness riêng**; không coi người im lặng là không được giúp hoặc là thành công. Các loại outcome không cộng lại thành một unique-household metric khi chưa có cách dedup được phép.

Current aggregate-only client events **chưa tính được đầy đủ metric này**. Hai lựa chọn để implementation review: server aggregate trực tiếp từ operational outcomes/cohort có policy cho phép; hoặc pilot consented survey/report riêng. Không thêm identifiers vào client analytics chỉ để nối funnel.

## Danh mục metrics và công thức

| ID  | Metric / mẫu số / cửa sổ                                                                                                             | Source & authority                                                                            | Hạn chế / mục tiêu gate                                                                                      |
| --- | ------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| M01 | Setup completion: families có active first baby / setup starts trong cùng cohort window                                              | Operational createBaby + client start aggregates; muốn conversion unique cần cohort authority | Start counters chưa unique; báo coverage trước khi chia tỷ lệ                                                |
| M02 | First value: eligible new families có care record confirmed hoặc memory ready trong 7 ngày / eligible new families                   | Domain server terminal states; tách Care và Remember                                          | 7 ngày là cửa sổ phân tích đề xuất, không là target thành công                                               |
| M03 | Time to first memory ready: first-ready minus profile createdAt, p50/p90                                                             | Server timestamps, per-cohort aggregation                                                     | Không trộn app install time hay queue bytes uploaded; no unsupported performance SLA                         |
| M04 | Upload success: ready / (ready + terminal failed) theo media cohort; pending reported separately                                     | processUpload transitions, versioned observer                                                 | Cancel là riêng; unresolved upload không biến mất khỏi mẫu số                                                |
| M05 | Upload recovery: failed items cuối cùng ready sau retry / retry-eligible failed items                                                | Operational attempts and final state, idempotent                                              | Existing item IDs cần operational correlation, không đưa vào app analytics                                   |
| M06 | Auto Save acceptance: approved suggestion items / reviewed suggestion items                                                          | Local batch counters + unsent flush semantics                                                 | Item vs group denominator rõ; không gọi là face precision hoặc upload success                                |
| M07 | Photo quality: false suggestion/reassign và missed-photo proxy trong approved pilot                                                  | Existing reject/missed counters + consented manual evaluation                                 | AutoSaveMissed chỉ proxy local, không đo recall toàn thư viện; lý do có thể không phải bé                    |
| M08 | Render success/time: filed output / jobs accepted; p50/p90 accepted→filed                                                            | keepsakeJobs + deterministic media ID/server commit                                           | Report queued/rendering/failed/cancelled; completed-before-filed riêng                                       |
| M09 | First/Repeat keepsake: eligible families có saved/ready artifact theo tuần/tháng                                                     | Server outcome + approved cohort rollup                                                       | Template selected/opened chưa đủ; tách card vs video vs written story                                        |
| M10 | Family activation: accepted invite / valid issued invite cohort; first allowed action sau accept                                     | family invite/member/domain operational records                                               | Invite expired/revoked/declined riêng; action phù hợp role, không bắt relative ghi Care                      |
| M11 | Collaboration value: work completed sau claim và handover acknowledged                                                               | careWork/reminder/ack states, server                                                          | Claim chưa completed; verify two-person task semantics trước count useful                                    |
| M12 | Connected use: eligible families hoàn tất ≥2 trụ cột trong cùng tuần / eligible active cohort                                        | Operational aggregate, fixed pillar mapping                                                   | Không cộng independent app event counts thành households; avoid inflating bằng auto-generated draft          |
| M13 | D7/D30 retained family: cohort đủ thời gian quan sát có qualifying value-day trong cửa sổ đã chốt / cohort đủ tuổi                   | Versioned operational activity vs value-retention series tách biệt                            | Current familyActivity chỉ activity; báo exact-day hay rolling definition, không đổi định nghĩa giữa chart   |
| M14 | Chapter continuity: eligible families 11–13m còn đọc/ghi history / families qua boundary và đủ observation window                    | Server coarse age cohort + authorized actions                                                 | Chưa dùng để mở Chapter 02 khi sample ít hoặc instrumentation thiếu                                          |
| M15 | Lumi task usefulness: useful ready outcome / supported authorized tasks; tách rules/model/read/write                                 | AssistantTask outcome + confirm writer                                                        | Declined/health/rejected/no-credit/timeout riêng; user correction rate là diagnostic, không tự là model fail |
| M16 | Lumi model quality: correct intent/time/source/safety on locked cases / total labeled cases                                          | Revision-specific offline/live eval, LUM-02                                                   | Eval accuracy không phải production success; nêu model/prompt/locale/sample size                             |
| M17 | AI cost: observed-token cost estimate / useful model-backed tasks; unknown usage rate                                                | LUM-01 call telemetry + rate version + provider reconciliation                                | Estimate và actual invoice khác; credits không đổi; không gán usage missing = 0                              |
| M18 | Premium conversion: verified purchase / eligible exposed household cohort; resume success sau verify                                 | Billing server verified + capability/resume                                                   | paywallSeen/raw purchaseStarted không unique conversion; refund/grant expiry riêng                           |
| M19 | Digest: scheduled count, opened count, opt-out riêng                                                                                 | Local schedule/open callback, server lease                                                    | Không trình bày delivery hoặc CTR chuẩn nếu chưa có delivered denominator                                    |
| M20 | Privacy/reliability guardrails: late child writes, stale artifact publish, unauthorized cached reads, unverified deletion completion | Regression probes/operational invariant counters                                              | Mục tiêu invariant = không vi phạm; đây là tiêu chí an toàn, không là số đo incident hiện tại                |

## Event plan — giữ first-party, fixed dimensions

Tất cả tên mới dưới đây là **proposed**; chưa gọi từ app/backend trong audit. Dùng events đang có khi đúng semantics thay vì tạo event song song. Không dựa event client để quyết định quota/entitlements hoặc truth hoàn tất.

| Milestone/event                                                                            | Nguồn                                | Dimensions cho phép                                                                 | Dedup / error handling                                                                                |
| ------------------------------------------------------------------------------------------ | ------------------------------------ | ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Existing `autoSaveSetupStarted/Done`, Access*, Suggested/Approved/Unticked/Rejected/Missed | Client local + batch counters        | Event name, count; platform/locale nếu allowlist được mở sau                        | Offline flush retry cần event batch id local/outbox; server ledger id riêng nếu chọn exactly-once     |
| Proposed `memoryReady`, `uploadTerminalFailed`, `uploadCancelled`                          | Server transition status             | source manual/auto/share/generated nếu source authority có; media kind; error code  | Once per media terminal generation; nguyên tắc chưa có source thì unknown, không infer sai            |
| Proposed `keepsakeJobFiled/Failed`                                                         | Server committed filing/failure      | artifact kind, template/composition version, fixed outcome code                     | Logical job + attempt khác nhau, retries không count saved artifacts lần hai                          |
| Proposed `milestoneMemoryLinked`                                                           | Server relation commit/outbox settle | origin reference/custom/rhythm, completion code                                     | Once per link; không send milestone id/name/date                                                      |
| Existing `nextActionShown/feedCardAnswered/personalizationOutcome`                         | Client + server state reconciliation | Reason và fixed answer enums hiện có                                                | Viewport/dedup rule version; helpful sau tried; personal vs shared semantics rõ                       |
| Existing `digestScheduled/digestOpened`                                                    | Client lease/schedule/open           | Fixed reason/status, platform                                                       | Same notice logical slot; cancel/replan không nhân scheduled unique nếu cùng slot; no delivered claim |
| Proposed `familyInviteIssued/Accepted`, `familyFirstAction`                                | Server operational aggregation       | role, channel fixed enum, coarse elapsed bucket                                     | Invite/first action logical record dedup, không user/member IDs trong aggregate payload               |
| Proposed `aiCallUsage`                                                                     | Server internal operations           | returned model, operation, prompt/schema version, status, usage-known, token counts | Call/attempt trace private TTL; aggregate emitted once, usage unknown retained                        |
| Existing paywall/purchase events + verified server billing outcomes                        | Client context + billing             | origin templates/rhythm/plan, verified outcome, store platform                      | Store event ledger authority; không raw transaction/store token                                       |
| Proposed `recapOpened/Saved/Shared`                                                        | Client open + server saved/shared    | rangeKind week/month, coarse source-count bucket, locale, fallback                  | Stage D only; no source IDs/narrative/private care facts                                              |

Raw source ids có trong read cards hoặc operational docs để giải thích nguồn là **dữ liệu sản phẩm có quyền**, không chuyển sang analytics. Không gửi nickname, DOB, exact event dates, UID/family/baby IDs, PhotoKit ids, Storage paths, face prints, photo hashes, health signs, care amounts, spending values, chat text, prompt hoặc media.

Để đo unique households/cohort bằng dữ liệu operational đã có, cần design access/retention + approved aggregate boundary. Không giả danh pseudonymous identifiers là anonymous. Khi cell ít người, suppress/merge buckets theo ngưỡng policy được duyệt; chưa tự chọn con số ngưỡng pháp lý.

## Rollout measurement và success gates

1. **A — invariant baseline:** giữ current raw operational counters, xác định metric version; test synthetic flows và repeated trigger; security/privacy invariant pass trước mở rộng.
2. **B — instrumentation validation:** reconcile ready/filed/quota/deletion counters với synthetic operational snapshots; dashboard tách pending/failed/fallback và unknown usage. Chỉ bắt đầu baseline sau reconciliation.
3. **C — Production Launch with Measurement:** sau implementation/release approval, phát hành V1 cùng app, không limited-user pilot riêng; cohort có eligibility/locale/platform/role xác định; đọc dữ liệu đủ một cửa sổ D7/D30 mới kết luận tương ứng. Đo usefulness tự nguyện; report response rate, sample size và missingness.
4. **D — value experiment:** thử một cải tiến rõ, ví dụ recovery hoặc story locale, giữ concurrent changes được ghi lại. Không gán causal retention/revenue chỉ từ before/after không kiểm confounding.

Release gate kỹ thuật đề xuất: không P0 mở; server terminal outcomes idempotent; no PII schema violations trong test; logging không raw child content; all code/device gates ở roadmap. Product success thresholds chỉ chốt sau baseline + mục tiêu owner; không lấy pass rate unit test hay vanity engagement thay user value.

Không có số liệu thực nào trong file này về DAU/retention/revenue/cost per family hoặc research. Các lợi ích trong bảng ưu tiên là giả thuyết cần xác minh.

## Smart Reminder & Engagement measurement

Workstream [ENG-00–06](12-smart-reminder-engagement-engine.md) cùng thuộc V1, phải đo riêng từng bước theo **Production Launch with Measurement**, không limited-user pilot riêng. Mục tiêu là giúp gia đình hoàn tất việc hữu ích; chưa có baseline hoặc số liệu chứng minh reminder làm tăng retention.

### Phân biệt các trạng thái

| Trạng thái                             | Authority và ý nghĩa                                                                                      | Không được suy ra                                                                 |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| Eligible opportunity                   | Nguồn còn hợp lệ + quyền/setting/độ mới đã kiểm tra; dedup theo cơ hội logic, không đếm lại mỗi lần scan. | Mọi gia đình đều đủ điều kiện; chưa chắc được gửi vì cap/quiet hours.             |
| Deferred / suppressed                  | Hoãn vì thời gian/cap hoặc bỏ vì đã xử lý, hết quyền, opt-out, thiếu nguồn; reason enum cố định.          | Delivery failure hoặc người dùng không quan tâm.                                  |
| Scheduled                              | OS/local scheduler chấp nhận kế hoạch; hoặc đã giữ slot hợp lệ.                                           | Điện thoại đã hiển thị.                                                           |
| Dispatch attempted / provider accepted | Đã thử gửi và push service chấp nhận token, tách retry/attempt với intent logic.                          | `sent`/`pushed` là delivered hoặc unique người nhận.                              |
| Delivery observed / unknown            | Chỉ observed khi có receipt/phép quan sát phù hợp; báo độ phủ chứng cứ theo platform/trạng thái.          | Không có receipt là thất bại, hoặc test trên một máy là delivery rate production. |
| Opened                                 | Callback/deep link hợp lệ; tách notification open khỏi mở thẻ trong app.                                  | Người dùng đã lưu ảnh, tạo video, đọc hết hoặc thấy hữu ích.                      |
| Value completed                        | Server xác nhận ready/filed/care completed; lượt xem hay usefulness là metric riêng có authority riêng.   | Draft/enqueue/render completed là saved; mở app là hoàn tất.                      |

Không báo CTR theo delivered nếu không có mẫu số delivered đáng tin cậy. Có thể báo opened / scheduled hoặc opened / provider accepted với tên **tỷ lệ phản hồi proxy**, tách channel, platform, cửa sổ và mức missingness. Không gộp hai mẫu số thành một tỷ lệ.

### Metrics bổ sung

W là cửa sổ attribution theo từng use case, phải chốt trước implementation/release V1. Chỉ tính cohort đã có đủ thời gian quan sát W; so sánh exposed, in-app và không gửi riêng. Một thao tác xảy ra sau thông báo chỉ là attribution theo định nghĩa, chưa chứng minh nhân quả.

| ID  | Use case             | Kết quả và mẫu số đề xuất                                                                                                                    | Guardrail                                                                                                                         |
| --- | -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| M21 | Pending Photos       | Episode đủ 24 giờ có ít nhất một ảnh được chọn lưu rồi server ready trong W / eligible pending-review episodes. Số ảnh được xử lý báo riêng. | Không lấy approved/queued làm ready; không coi ảnh đang upload là pending review; dismiss/snooze/cancel riêng.                    |
| M22 | Memory Milestone     | Dịp đủ điều kiện có video filed trong W / eligible occasion episodes; open, chọn ảnh và render start báo riêng.                              | Tách artifact đã có trước lời nhắc, job lỗi và retry; không nhân dịp vì nhiều thiết bị hoặc đổi locale.                           |
| M23 | Weekly Memory Digest | Tuần đủ điều kiện được mở xem nội dung / eligible family-week episodes; story saved hoặc video filed từ luồng đó là kết quả riêng.           | Chỉ nội dung được phép xem và còn mới; không coi story draft tự sinh là user value đã nhận.                                       |
| M24 | Care Reminder        | Lịch đến hạn được ghi/hoàn tất/ack theo semantics đã chốt trong W / due authorized reminder occurrences.                                     | Hoàn tất trước hạn, snooze, bỏ qua và quá hạn riêng; không yêu cầu relative thực hiện hành động ngoài quyền.                      |
| M25 | Family Engagement    | Nội dung chia sẻ/lời nhắn thực sự được mở xem / eligible recipient-event groups; có thể đo phản hồi hợp lệ riêng.                            | Không coi provider accepted là đã đọc; không tự phát hành seen receipt cho người gửi; tôn trọng mute và gom nhóm.                 |
| M26 | Lumi Insight         | Insight được mở xem nguồn; useful / phản hồi đã trả lời, kèm response rate / eligible insight episodes.                                      | Không đánh đồng open với usefulness hoặc chất lượng y khoa; tách thiếu dữ liệu, stale và model fallback.                          |
| M27 | Chất lượng điều phối | Suppressed/deferred/expired/retried/duplicate, opt-out và số nhắc chủ động theo recipient-day; delivery coverage theo platform/channel.      | Lịch care và thông báo giao dịch tách proactive engagement; unknown giữ unknown; không claim global cap nếu chỉ có local counter. |

### Instrumentation và quyền riêng tư

- Tái sử dụng các terminal outcomes đã có nếu đúng nghĩa. Chúng chưa tự cung cấp attribution cho ENG; không gọi kết quả `productOutcomesDaily` hiện tại là conversion sau reminder.
- Các tên ví dụ ban đầu như `engagementEligible`, `engagementScheduled`, `engagementProviderAccepted`, `engagementOpened`, `engagementSuppressed`, `engagementValueCompleted` là **proposed**, chưa phải events đang phát. Dimensions chỉ fixed kind/channel/platform/locale/policy version/reason/outcome enums.
- Intent/receipt và liên kết attribution thuộc operational store được kiểm soát quyền/retention. Nếu cần nối intent → upload batch → ready, phải thiết kế tham chiếu opaque do server kiểm tra; không gửi PhotoKit ID, face print, source text hoặc child facts lên analytics. Local pending chỉ cho biết trạng thái cục bộ, không tự là server truth.
- Dedup theo cơ hội/cửa sổ/recipient, giữ attempts riêng. Một family có nhiều người/thiết bị không tự thành nhiều household; unique family/cohort chỉ báo khi có aggregate operational đúng và policy phù hợp.
- Đo guardrails từ đầu: opt-out, dismiss, snooze, lời nhắc trùng, nội dung hết hạn, mở sai quyền và scheduled notice không hủy khi revoke. Thử nghiệm chỉ đánh giá uplift khi có thiết kế đối chứng và cửa sổ đủ dài; chưa đặt target giả.

**Gate trước baseline:** dùng fixture tổng hợp đối soát các trạng thái và terminal outcomes, rồi chạy [ma trận delivery trên thiết bị thật](12-smart-reminder-engagement-engine.md#delivery-gate-kiểm-chứng-riêng). Chưa có bằng chứng này thì delivery vẫn chưa kiểm chứng; không lấp bằng số test emulator đã pass.

### V1 event/Portal gate và late-onboarding cohorts

[Event dictionary, bốn funnel definitions, Portal contract và tickets ENG-T01/T02](14-notification-implementation-plan.md) là refinement canonical; snake_case event names trong đó thay các ví dụ naming chưa chốt bên trên. Hoàn tất specification, privacy review, aggregate API/UI contracts và known-count fixtures **trước notification engine implementation**. Tái sử dụng `productOutcomesDaily` nhưng không coi total counts hiện tại là attributed conversion.

Late onboarding cần current/retrospective và age-at-join bands 1/3/6/9/12 tháng; history/media/keepsakes xác minh đủ. Không giả không có memory ở ngày sinh là activation failure; backfill filed đo riêng, overdue milestone không dispatch. Ready→Story→rendered funnel là Memory Story video; share sheet opened không phải share completed.

Portal bắt buộc hiển thị eligible denominators, immature windows, observed/unknown delivery, opt-out/fatigue/cap/duplicate/expiry, và no-data/insufficient-data states. Không tạo demo baseline trên production, không hứa growth target hoặc significance từ N nhỏ. Randomized concurrent control sau launch chỉ là thiết kế tùy chọn cần approval riêng; không mandatory holdout/pilot để release. So sánh observational opt-in/opt-out không chứng minh causal lift.
