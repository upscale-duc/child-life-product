# Child Life — Product & Technical Audit

Ngày chốt audit: **20/10/2026, Asia/Ho_Chi_Minh**. Snapshot: commit `637c918` **cộng working tree đọc trong phiên 20/10/2026**; workspace có thay đổi song song, xem provenance trong inventory. Đây là audit code/workspace, không phải chứng nhận bản đang chạy trên production.

Cập nhật 21/10/2026: đã triển khai bản sửa cho mười ưu tiên đầu tiên trong workspace; xem [báo cáo implementation và giới hạn kiểm chứng](11-implementation-report.md). Các nhận định bên dưới giữ nguyên theo snapshot audit ban đầu. Bổ sung theo đề xuất chủ sản phẩm: [Smart Reminder & Engagement Engine](12-smart-reminder-engagement-engine.md) là workstream riêng sau P0 an toàn dữ liệu; hai ưu tiên đầu là Pending Photos Reminder và Memory Milestone. Đây là kế hoạch, chưa triển khai hoặc xác nhận delivery thực tế.

Child Life đã có nền tảng sản phẩm sâu ở cả năm trụ cột. Ưu tiên phù hợp là làm chắc vòng **ghi nhận → hiểu đúng dữ liệu → giữ lại kỷ niệm → chia sẻ có kiểm soát → quay lại**, thay vì xây thêm module hoặc phát triển Chapter 02–04.

## Những gì đã làm tốt

- Memories có nhận diện/gom ảnh trên iOS, review do người dùng quyết định, hàng đợi bền vững, upload nền hai nền tảng, quota, thùng rác, album và quyền xem thực thi ở server. [E05 · `autoSaveSupported / AutoSaveNative`](../../apps/mobile/lib/features/auto_save/auto_save_native.dart#L9); [E06 · `AutoSaveTuning / matchBaby / groupAndRank`](../../apps/mobile/lib/features/auto_save/auto_save_engine.dart#L118); [E09 · `AutoSaveController.approve / recordUploaded`](../../apps/mobile/lib/features/auto_save/auto_save_controller.dart#L835); [E10 · `UploadQueue.enqueue / cancel / FileQueueStore`](../../apps/mobile/lib/features/memories/upload_queue.dart#L777); [E11 · `BackgroundTransport`](../../apps/mobile/lib/features/memories/background_uploads.dart#L20); [E14 · `createMemory / processUpload / purgeMediaBin`](../../firebase/functions/src/memories.ts#L157); [E29 · `uploadAllowed / canSee / shared`](../../firebase/storage.rules#L32).
- Memory Story video, story dạng bài viết và thiệp là **ba khả năng khác nhau đã có**. Có Remotion registry, snapshot input, retry, quota reservation, editor VI/EN và quản trị template qua duyệt nội dung. [E17 · `requestMemoryStory / retryMemoryStory / sweepKeepsakeJobs`](../../firebase/functions/src/keepsake-jobs.ts#L105); [E19 · `runJob / finish / progress`](../../apps/renderer/src/job.ts#L86); [E21 · `stories / storyOf`](../../apps/renderer/src/compositions/registry.tsx#L37); [E22 · `keepsakeAct / keepsakeDraft / keepsakeUploadAsset`](../../firebase/functions/src/keepsake-content.ts#L177); [E23 · `PremiumKeepsakeEditor / _save`](../../apps/mobile/lib/features/keepsakes/premium_keepsake_editor.dart#L34); [E26 · `weekSources / suggestStory / suggestForAll / saveStory`](../../firebase/functions/src/stories.ts#L220).
- Care/Grow/Remember đã nối bằng hồ sơ bé, milestones, thẻ Home và personalization v2. Handover, sổ tay, claim việc, feedback sau khi thử và digest đều đã có code; không đưa vào danh sách “cần xây mới”. [E31 · `_MemorySheet._save / createMilestoneMemory`](../../apps/mobile/lib/features/milestones/milestone_sheets.dart#L352); [E33 · `TodayForBabySection / forBabyCardsProvider`](../../apps/mobile/lib/features/today/today_for_baby.dart#L45); [E34 · `personalizedSourceCardsProvider`](../../apps/mobile/lib/features/rhythm/personalization_sources.dart#L22); [E35 · `personalizedDay / updatePersonalization / reservePersonalizedDigest`](../../firebase/functions/src/personalization-v2.ts#L398).
- Family có invitation code/link/email, guest→account, ba role theo bé, quyền bổ sung, expiry/revoke, nhiều bé và các membership khác gia đình. [E03 · `membershipsProvider / sessionProvider`](../../apps/mobile/lib/app/session.dart#L51); [E04 · `SelectedBabyId / HomeShell`](../../apps/mobile/lib/features/home/home_shell.dart#L50); [E27 · `createInvite / acceptInvite / updateMember / removeMember`](../../firebase/functions/src/family.ts#L101); [E28 · `activeMember / canReadCare / assistantSharer`](../../firebase/firestore.rules#L18).
- Lumi có luồng rules miễn phí, đọc dữ liệu nhiều module, context theo bé, output có schema, draft cần xác nhận, hướng xử lý sức khỏe riêng và credit ledger. [E41 · `openAiModelGateway / buildUnderstandRequest`](../../firebase/functions/src/assistant-model.ts#L767); [E43 · `worker health / rules / model / settle pipeline`](../../firebase/functions/src/assistant-worker.ts#L444); [E44 · `assistantRead / allowsAssistantRead / read cards`](../../firebase/functions/src/assistant-reads.ts#L954); [E45 · `assistantPool / assistantUsage / recentUsage`](../../firebase/functions/src/assistant-usage.ts#L78).

## Phần chưa hoàn chỉnh

**Ba rủi ro P0 trước khi mở rộng rollout:**

1. **FAM-01 — dữ liệu cục bộ chưa có ranh giới tài khoản đầy đủ.** Cache media trả dữ liệu từ đĩa trước kiểm tra phiên; queue và Auto Save dùng file chung trên install; sign-out chỉ gỡ device/sign-out Auth. Code xác nhận thiếu cơ chế ở các đường đọc này; chưa tái hiện UI rò dữ liệu trên thiết bị. [E08 · `AutoSaveStore / AutoSaveState / LedgerState`](../../apps/mobile/lib/features/auto_save/auto_save_store.dart#L446); [E10 · `UploadQueue.enqueue / cancel / FileQueueStore`](../../apps/mobile/lib/features/memories/upload_queue.dart#L777); [E12 · `StorageMediaBytes.read / playable / file`](../../apps/mobile/lib/features/memories/media_bytes.dart#L33); [E13 · `signOutThisDevice / PushRegistration._leave`](../../apps/mobile/lib/features/memories/push_registration.dart#L368); [E59 · `LostAccessScreen / avatar invalidation`](../../apps/mobile/lib/features/family/join_screens.dart#L788).
2. **MEM-01 — fencing video mới bảo vệ document, chưa bảo vệ bytes.** Đã tái hiện: worker cũ trả `stale` nhưng vẫn ghi lên canonical object path của worker mới. Firestore thật trên emulator, object store giả; không phải quan sát sự cố production. [E19 · `runJob / finish / progress`](../../apps/renderer/src/job.ts#L86).
3. **CON-01 — hoàn tất render có thể tạo dữ liệu khi bé đang bị xóa.** Đã tái hiện `completeKeepsakeJob` trả `filed` và tạo media với `baby.state=deleting`. [E18 · `completeKeepsakeJob`](../../firebase/functions/src/keepsake-jobs.ts#L604); [E30 · `babyStep / accountStep / runDeletionJob / runExport`](../../firebase/functions/src/account.ts#L480).

Nhóm P1: lịch sử bị giới hạn 1.000 memory/5.000 media; ngày video cố định `05:00Z`; tính tháng tuổi khác nhau ở cuối tháng; Auto Save đánh dấu “uploaded” khi mới enqueue; Lumi chỉ ước tính chi phí; story tự động luôn VI; liên kết mốc→memory chưa bền vững. Chi tiết và bằng chứng ở [gap matrix](08-gap-analysis.md).

## Phần chưa tìm thấy

- Recap tháng thống nhất Care + Grow + Remember, có nguồn và thao tác chọn lọc quyền trước chia sẻ. Đã có weekly stories, weekly summaries, thiệp/trang tháng và dữ liệu chi tiêu tháng; chúng không phải cùng tính năng recap này. [E26 · `weekSources / suggestStory / suggestForAll / saveStory`](../../firebase/functions/src/stories.ts#L220); [E35 · `personalizedDay / updatePersonalization / reservePersonalizedDigest`](../../firebase/functions/src/personalization-v2.ts#L398); [E44 · `assistantRead / allowsAssistantRead / read cards`](../../firebase/functions/src/assistant-reads.ts#L954).
- Một policy Chapter thống nhất dùng cho Home, capabilities, content và thông điệp hỗ trợ tuổi. Đã có stage content tới 36 tháng và mô hình DOB tới 18 năm; Chapter 02–04 vẫn là roadmap trên landing. [E36 · `maxBabyAgeYears / baby profile contracts`](../../packages/contracts/src/baby.ts#L45); [E37 · `ageInUnit / stageFor / stageBuckets`](../../packages/contracts/src/content.ts#L538); [E39 · `lbAgeIn / lbStageFor / LbAgeBand`](../../apps/mobile/lib/features/library/content_calc.dart#L8); [E40 · `futureStage.band / journey.stages`](../../apps/landing/src/content/vi.ts#L628).
- Fingerprint media bền vững giữa các thiết bị/đường nhập; ledger chống lặp hiện theo Photos asset id cục bộ. [E08 · `AutoSaveStore / AutoSaveState / LedgerState`](../../apps/mobile/lib/features/auto_save/auto_save_store.dart#L446); [E09 · `AutoSaveController.approve / recordUploaded`](../../apps/mobile/lib/features/auto_save/auto_save_controller.dart#L835); [E10 · `UploadQueue.enqueue / cancel / FileQueueStore`](../../apps/mobile/lib/features/memories/upload_queue.dart#L777); [E14 · `createMemory / processUpload / purgeMediaBin`](../../firebase/functions/src/memories.ts#L157).

“Chưa tìm thấy” là kết quả tìm trong phạm vi repo, không khẳng định không tồn tại trên hệ thống bên ngoài.

## Mười thay đổi có ảnh hưởng cao nhất

| Thứ tự | ID     | Thay đổi                                                                            | Giá trị chính                               |
| ------ | ------ | ----------------------------------------------------------------------------------- | ------------------------------------------- |
| 1      | FAM-01 | Tách local state theo UID; xóa/invalidate cache, queue, face data khi logout/revoke | Quyền riêng tư gia đình                     |
| 2      | MEM-01 | Object output theo lease; chỉ publish output của worker thắng                       | Video đúng và không bị ghi đè               |
| 3      | CON-01 | Chặn claim/file khi bé xóa; phối hợp purge với worker đang chạy                     | Xóa dữ liệu đáng tin                        |
| 4      | MEM-02 | Cursor pagination theo ngày/tuổi/album                                              | Ký ức lâu năm vẫn tìm thấy                  |
| 5      | CON-02 | Lưu date-only và chuyển instant theo múi giờ bé                                     | Timeline, mốc, recap đúng ngày              |
| 6      | CH-01  | Một quy tắc tuổi cuối tháng cho mọi module                                          | Cá nhân hóa nhất quán                       |
| 7      | MEM-06 | Tách queued/uploaded/ready trong ledger và trạng thái hoàn tất                      | Không “đã lưu” khi file chưa đến            |
| 8      | LUM-01 | Token/model/call telemetry thực tế, tách khỏi credit thương mại                     | Kiểm soát chi phí AI                        |
| 9      | MET-01 | Funnel dựa trên hoàn tất thật, mẫu số/cohort rõ                                     | Quyết định retention và doanh thu có căn cứ |
| 10     | MEM-03 | Story tự động và metadata đúng VI/EN                                                | Giá trị cảm xúc và khả năng chia sẻ         |

## Thứ tự triển khai đề nghị

1. Chốt bản workspace và đóng ba P0; giữ gate đã khôi phục; đo/reproduce hồi quy trước rollout rộng.
2. Hoàn thiện tính đúng dữ liệu: lịch sử, ngày/tuổi, trạng thái upload, link mốc. Thiết lập funnel và cost metrics song song.
3. Đóng vòng Chapter 01: story VI/EN, chất lượng chọn ảnh/template, thử trên thiết bị và đánh giá Lumi với prompt/model hiện tại.
4. Chỉ sau release gate Chapter 01 mới thử recap tháng ở nhóm nhỏ. Giữ Chapter 02–04 ở mức policy/continuity, không phát triển tính năng mới cho các chặng đó.

## Mức kiểm chứng

Đã chạy lại: **598 contracts; 474 Functions (1 skip); 234 portal; 24 renderer; 319 Flutter; 218 integration/Rules** đạt sau xử lý cấu hình emulator. Hai phép tái hiện rủi ro nêu trên cũng đạt điều kiện quan sát. Workspace TypeScript typecheck đạt. Lượt đầu `flutter analyze` có **1 error + 1 info**; thay đổi song song ngoài audit đã sửa, chạy lại báo **No issues found**. QA-01 đã đóng, không nằm trong mười việc còn mở. Renderer dùng fake render/store trong test job, không phải render Remotion thực bằng ảnh gia đình.

Không deploy, không sửa code production, Figma, schema, giá hay credits. Chưa truy cập Firebase thật, store billing thật, analytics production, máy iOS/Android hay model trả phí. Xem [inventory và nhật ký kiểm chứng](01-current-product-inventory.md), [UX journeys](07-ux-journey-audit.md), [thiết kế/roadmap](09-implementation-roadmap.md), [metrics](10-analytics-and-success-metrics.md).

## Smart Engagement V1 — quyết định bổ sung

ENG-00–06 và Late Onboarding & Memory Backfill cùng thuộc V1: hoàn thiện, kiểm chứng rồi phát hành cùng app theo **Production Launch with Measurement**, không limited-user pilot riêng. Account mới không đồng nghĩa bé sơ sinh; join ở 1/3/6/9/12 tháng cần historical-photo/keepsake context và retrospective creation trong app, không outdated milestone push. Event/Portal measurement phải hoàn tất trước engine; privacy, automated/device tests, flags/kill switches và release approval vẫn bắt buộc. Không deploy/config production trong lượt cập nhật spec này. Xem [roadmap V1](09-implementation-roadmap.md#smart-reminder--engagement-workstream) và [implementation plan](14-notification-implementation-plan.md).
