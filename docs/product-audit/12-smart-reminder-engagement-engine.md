# Smart Reminder & Engagement Engine

Bổ sung ngày 21/10/2026 theo đề xuất của chủ sản phẩm. Đây là **luồng công việc riêng sau P0 an toàn dữ liệu**. Code local hiện được ghi nhận trong [implementation evidence](17-engagement-implementation.md); chưa deploy/activate hoặc kiểm chứng delivery trên thiết bị thật. Các bản sửa 1–10 nằm trong [báo cáo implementation](11-implementation-report.md); không bao gồm engine này.

Mục tiêu là nhắc khi gia đình có một việc hữu ích có thể hoàn tất: chọn lưu ảnh, làm kỷ niệm, xem lại tuần hoặc phối hợp chăm sóc. Thành công được đo bằng việc hoàn tất đó, không chỉ bằng số thông báo hay lượt mở app.

## Quyết định V1 và bộ refinement hiện hành

Cập nhật theo quyết định chủ sản phẩm: **ENG-00–06 cùng thuộc V1**, hoàn thiện và kiểm chứng trước khi phát hành cùng app. Không còn phase limited-user pilot riêng; thay bằng **Production Launch with Measurement**. Late Onboarding & Memory Backfill là scenario cốt lõi, hỗ trợ join ở 1/3/6/9/12 tháng, xét actual age/historical photos/completed keepsakes; retrospective creation trong app không tạo outdated push. Event/Portal measurement specification phải xong trước implementation engine. Không deploy/thay production config trước implementation và release approval.

Kiến trúc, privacy safeguards, adapters, ENG definitions và physical-device/safety gates dưới đây giữ nguyên. Cadence/copy/retention mới cần duyệt theo [audit refinement](12-smart-reminder-audit.md). Chi tiết mới ở [rules](13-engagement-rules.md), [plan & tickets](14-notification-implementation-plan.md), [journeys/backfill](15-engagement-journeys.md), [campaigns](16-memory-campaigns.md). P0/P1 là thứ tự engineering trong V1, không chuyển ENG-03–06 qua sau launch.

## Phạm vi và ưu tiên

**P0 sản phẩm** = ưu tiên đầu tiên của luồng engagement sau khi P0 về quyền riêng tư, render và xóa dữ liệu qua release gate. Không dùng nhãn này để vượt qua gate an toàn dữ liệu. Các con số/cadence mới trong tài liệu là đề xuất sản phẩm, chưa phải SLA hoặc kết quả thử nghiệm.

| ID     | Hạng mục                             | Ví dụ và việc cần bổ sung                                                                                                                                            | Ưu tiên             |
| ------ | ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| ENG-00 | Nền điều phối và kiểm chứng delivery | Chung điều kiện được nhắc, chống trùng, lịch, giờ yên tĩnh, hủy khi không còn phù hợp, deep link và đo từng bước. Tận dụng notification centre và scheduler hiện có. | Nền bắt buộc cho V1 |
| ENG-01 | Pending Photos Reminder              | Phát hiện 8 ảnh, sau 24 giờ vẫn chưa chọn lưu thì mời quay lại review; số ảnh phải được kiểm tra lại lúc nhắc.                                                       | **P0 sản phẩm**     |
| ENG-02 | Memory Milestone                     | Sắp đầy tháng, gợi ý làm video từ ảnh phù hợp; dừng khi đã tạo hoặc người dùng bỏ qua.                                                                               | **P0 sản phẩm**     |
| ENG-03 | Weekly Memory Digest                 | “Tuần này có những khoảnh khắc mới”; mở trang nhìn lại tuần với ảnh/video đã ready và story đã saved.                                                                | P1                  |
| ENG-04 | Care Reminder                        | Cải thiện nhắc theo lịch ăn/ngủ người dùng đã cấu hình: đúng người, đúng lịch, tự dừng khi đã hoàn tất.                                                              | P1 cải thiện        |
| ENG-05 | Family Engagement                    | Có ảnh được chia sẻ hoặc lời nhắn mới trong gia đình; gom các sự kiện gần nhau, mở đúng nội dung còn được phép xem.                                                  | P1                  |
| ENG-06 | Lumi Insight                         | Mời xem một nhận xét có nguồn từ dữ liệu đủ mới; không gửi khi không đủ căn cứ hoặc không còn quyền.                                                                 | P1                  |

## Đã có gì và còn thiếu gì

| Hạng mục             | Bằng chứng code hiện tại                                                                                                                                                                                                                                                                                      | Khoảng bổ sung                                                                                                                                                                                                                                  |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Pending Photos       | [`autoSaveNote` và `backgroundCheck`](../../apps/mobile/lib/features/auto_save/auto_save_controller.dart) nhắc khi phát hiện ảnh **mới**, giới hạn theo ngày và xử lý giờ ban đêm. Tự nhận diện này hiện thuộc Tự lưu trên iOS.                                                                               | Chưa thấy vòng nhắc lại dựa trên ảnh tồn đọng đủ 24 giờ. Cần lưu thời điểm phát hiện, snooze/dismiss và đối soát trạng thái pending/queued/ready. Không mặc định Android đã có cùng khả năng phát hiện ảnh.                                     |
| Memory Milestone     | [`keepsake_nudges.dart`](../../apps/mobile/lib/features/keepsakes/keepsake_nudges.dart) có thẻ trong app trước/sau mốc, thông báo vào ngày mốc và nhắc nhìn lại; gắn với dịp/thiệp, có dismiss.                                                                                                               | Kết nối chủ động tới luồng tạo **video**, kiểm tra ảnh đủ điều kiện, job đang chạy và thành phẩm đã có; phối hợp với các lời nhắc khác. Không xây lại hệ thống mốc từ đầu.                                                                      |
| Weekly Memory Digest | [`stories.ts`](../../firebase/functions/src/stories.ts) có nguồn và story tuần; [`personalization_digest.dart`](../../apps/mobile/lib/features/rhythm/personalization_digest.dart) có cơ chế đặt trước slot cho **gợi ý cá nhân hóa hằng ngày**.                                                              | Story tuần không đồng nghĩa đã có weekly memory notification. Daily personalization digest cũng không thay thế digest kỷ niệm tuần. Cần xác định tuần, nội dung mới và hành động sau khi mở.                                                    |
| Care Reminder        | [`reminder_notifications.dart`](../../apps/mobile/lib/features/reminders/reminder_notifications.dart) và [`reminder-rules.ts`](../../firebase/functions/src/reminder-rules.ts) có lịch local, rule reminders và xử lý hành động.                                                                              | Kiểm chứng thực tế đúng giờ/người, sửa lịch, ghi xong trước giờ nhắc, nhiều thiết bị và khởi động lại; giữ semantics của lịch do người dùng đặt.                                                                                                |
| Family Engagement    | [`notifications.ts`](../../firebase/functions/src/notifications.ts), [`albums.ts`](../../firebase/functions/src/albums.ts) và [notification contracts](../../packages/contracts/src/notifications.ts) có inbox, loại shared/album/story/message, setting và push.                                             | Điều phối/gom nhóm để tránh nhiều thông báo cho cùng một đợt chia sẻ, không nhắc chính người tạo, hủy nội dung đã bị thu hồi. Chỉ nhắc **hành động mà role được phép làm**; không giả định ông bà luôn có quyền upload hoặc đã có seen receipt. |
| Lumi Insight         | [Personalization digest](../../apps/mobile/lib/features/rhythm/personalization_digest.dart) có opt-in, slot/thiết bị và giới hạn hiệu lực; [personalization server](../../firebase/functions/src/personalization-v2.ts) và [AI summary](../../firebase/functions/src/ai-summary.ts) là nguồn có thể tận dụng. | Chọn insight có nguồn, đúng quyền, đủ mới; tránh lặp với digest đã có. Nếu cần model mới, vẫn qua LUM-02 về chất lượng và giới hạn chi phí.                                                                                                     |
| Delivery             | [`notifyUsers`](../../firebase/functions/src/notifications.ts) ghi inbox và số token được push service chấp nhận; [native Tự lưu](../../apps/mobile/ios/Runner/AutoSave.swift) và [local reminders](../../apps/mobile/lib/features/reminders/reminder_notifications.dart) đặt lịch qua OS.                    | `sent`, `pushed`, `autoSaveNotified` hay `digestScheduled` không chứng minh thiết bị đã hiện thông báo. Còn thiếu bằng chứng physical-device delivery và các trường hợp restart/kill/revoke.                                                    |

## Luồng quyết định chung

1. **Có cơ hội hữu ích:** ảnh đang chờ, mốc sắp tới, tuần có nội dung mới, lịch đã đặt hoặc sự kiện chia sẻ hợp lệ.
2. **Kiểm tra quyền và điều kiện:** đúng UID/bé/role, dữ liệu chưa xóa, nguồn đủ mới, setting phù hợp, thiết bị còn hợp lệ. Không coi một lần đọc cache cũ là quyền gửi mãi mãi.
3. **Tạo một intent logic:** cùng cơ hội và cửa sổ thời gian chỉ có một intent; retry, đổi locale/token hoặc đổi policy version không tự tạo một lời nhắc trùng.
4. **Điều phối:** áp dụng giờ yên tĩnh, snooze/dismiss, hạn mức và ưu tiên. Có thể hoãn, gom hoặc chỉ hiện trong app; không phải ứng viên nào cũng phải thành push.
5. **Kiểm tra lại trước dispatch:** đã lưu ảnh, đang upload/render, đã làm video, đã ghi chăm sóc hoặc mất quyền thì hủy/giảm nội dung nhắc tương ứng.
6. **Gửi qua adapter hiện có:** local notification hoặc push/inbox. Ghi riêng scheduled, dispatch attempted, provider accepted, failed, expired và cancelled.
7. **Mở an toàn:** cả cold start và app đang mở đều kiểm tra phiên/quyền trước deep link. Nếu nguồn đã mất, hiển thị trạng thái phù hợp; không mở nội dung gia đình cũ.
8. **Xác nhận giá trị:** memory ready, keepsake filed, care record/acknowledgement hoặc xem nội dung thật sự. Mở thông báo hoặc tạo draft chưa phải hoàn tất.

## Hai hạng mục P0 sản phẩm

### ENG-01 — Pending Photos Reminder

- Mốc 24 giờ tính từ **lúc ảnh được phát hiện và đưa vào danh sách review**, không từ ngày chụp. Ảnh cũ vừa nhập vào thư viện không được xem là đã tồn đọng nhiều tháng.
- Chỉ nhắc phần còn đang chờ quyết định. Ảnh đang queued/uploading/processing không bị nhắc “chưa lưu”; lỗi tải có luồng phục hồi riêng. Ảnh đã ready, đã từ chối hoặc bỏ qua không quay lại chỉ vì scheduler chạy lại.
- Khi mở review, người dùng được chọn lưu, bỏ qua hoặc để sau. Dismiss/snooze phải được lưu; không nhắc lại ngay sau khi người dùng vừa xử lý.
- Copy màn hình khóa mặc định chung, ví dụ “Bạn có ảnh đang chờ chọn lưu”; số lượng và ảnh cụ thể hiển thị sau khi mở app và xác nhận quyền. Copy thực tế cần VI/EN qua hệ thống localization.
- Candidate/PhotoKit ID/face data nằm trên thiết bị, theo UID. Server không đọc thư viện ảnh để tự phát hiện “8 ảnh”. Nếu cần phối hợp nhiều thiết bị, chỉ dùng reservation operational tối thiểu; không chuyển PhotoKit ID hay face print sang analytics.
- OS có thể hoãn background scan và local notification. “Sau 24 giờ” là lúc **đủ điều kiện nhắc**, không hứa đúng phút khi app bị kill/offline. Android cần thiết kế nguồn pending phù hợp hoặc bổ sung capability riêng trước khi tuyên bố tương đương iOS.
- Acceptance: phát hiện 8 → qua 24 giờ → chỉ nhắc một cơ hội hợp lệ; đã lưu 5 thì review còn 3; nếu 8 ảnh đang chờ upload thì không nhắc chọn lưu lại; restart/snooze/retry không nhân bản lời nhắc; logout/revoke hủy kế hoạch cũ.

### ENG-02 — Memory Milestone

- Dùng mốc và múi giờ của bé; phân biệt tuổi đã hoàn tất với “tháng thứ N”. Tận dụng cửa sổ gợi ý trước mốc hiện có, không tạo một lịch mốc song song.
- Khi đủ ảnh và có template/capability phù hợp, mở thẳng vào bước chọn ảnh hoặc mẫu video cho dịp đó. Không tự chọn ảnh riêng tư để chia sẻ, không tự render hoặc trừ quota/credits chỉ vì tới ngày mốc.
- Có job đang queued/rendering hoặc đã có video hoàn tất cho dịp thì không mời tạo lại cùng video. Job lỗi dẫn tới retry/recovery; không tạo thêm render request âm thầm.
- Dismiss/snooze áp dụng theo bé và dịp, không bị reset bởi đổi ngôn ngữ hoặc token. Xử lý nhiều bé/nhiều thiết bị và người cùng nuôi để tránh cả nhà bị nhắc trùng cùng một việc.
- D-068 #9 hiện ghi “always suggest” cho nudges cũ. Việc thêm công tắc/cadence của kênh mới là **thay đổi policy cần chốt riêng khi triển khai**; đề xuất này không tự đổi quyết định cũ hoặc bật push mới cho người đã có app.
- Acceptance: gợi ý trước đầy tháng → mở đúng dịp/locale → người dùng chủ động tạo → video filed thì dừng; đổi múi giờ, đã dismiss, thiếu ảnh, template bị gỡ hoặc mất quyền đều có hành vi rõ.

## Nền điều phối ENG-00

- **Một policy chung, nhiều adapter:** tái sử dụng notification centre, native local scheduler và digest reservation. Không tạo thêm một scheduler riêng cho mỗi use case rồi để chúng gửi độc lập.
- **Tách loại nhắc:** care do người dùng cấu hình và sự kiện giao dịch gia đình giữ policy hiện có. Lời mời chủ động như pending photos, milestone, weekly digest và Lumi cùng chia sẻ ngân sách làm phiền. Không để engagement cap làm mất một lịch chăm sóc người dùng đã đặt.
- **Đề xuất cadence V1, cần duyệt:** tối đa một lời nhắc chủ động/người/ngày trên mọi bé và thiết bị (refinement đề xuất thêm rolling cap 1/24h và 3/7d, xem A-01), ưu tiên cơ hội sắp hết hạn; đây là cấu hình thử nghiệm cần chốt, không phải cam kết đang được thực thi. Phù hợp hướng giới hạn trong Q-082; không tự đổi trạng thái quyết định đó.
- **Offline và nhiều thiết bị:** cần active-device lease/slot chung nếu muốn bảo đảm cap toàn tài khoản. Khi không xác minh được slot còn hiệu lực, ưu tiên thẻ trong app hoặc hoãn system notification; không tuyên bố global exactly-once chỉ bằng bộ đếm local.
- **Giờ và độ mới:** lưu `eligibleAt`, `dueAt`, `expiresAt`, source generation và timezone có authority. Giờ tĩnh hoãn trong cửa sổ còn ích; quá hạn thì expire, không gửi dồn toàn bộ lúc bật máy lại.
- **Hủy và chống lặp:** hủy khi source đã được xử lý/xóa, revoke/logout, đổi setting, đổi lịch hoặc có người hoàn tất việc. Claim intent/outbox có lease; timeout, token rotation và retry không tạo thêm logical notification.
- **Setting/locale:** không tự opt-in chỉ vì có `digestTime`; theo setting hiện có và chốt riêng kênh mới. Payload không chứa ảnh, text lời nhắn, chi tiết care, prompt hay nhận xét sức khỏe; nội dung cụ thể được tải sau kiểm tra quyền.
- **Dữ liệu đề xuất, chưa có schema mới:** intent/outbox server chứa tham chiếu operational tối thiểu, kind, logical slot, policy version, state/reason và TTL; local candidate lưu discovery time, snooze/dismiss theo UID. Chốt retention và Rules trước code; không thêm định danh gia đình vào aggregate analytics.
- **Hệ thống dừng được:** feature flag theo loại nhắc, kill switch, giới hạn retry và expiry; tắt engagement không làm ngừng care reminder hoặc thông báo video đã sẵn sàng.

## Weekly, Care, Family và Lumi — điều kiện P1

- **Weekly Memory Digest:** tuần theo múi giờ bé; chỉ nhắc khi có nội dung mới được phép xem, không gửi digest rỗng hoặc lặp cùng tuần. Story tự sinh dạng draft chưa được tính là kỷ niệm đã lưu. Gộp với các digest khác khi trùng slot.
- **Care Reminder:** lịch ăn/ngủ do người dùng chủ động đặt, không suy ra một chỉ định chăm sóc từ AI. Kiểm tra assignee, thời gian, quiet-hours exception hiện có, snooze và hoàn tất trên thiết bị khác. Đã ghi đúng hoạt động thì dừng nhắc theo rule tương ứng.
- **Family Engagement:** dựa trên sự kiện chia sẻ/lời nhắn thật và setting của người nhận, không dựa suy đoán “ông bà chưa xem”. Có thể gom một đợt ảnh; không phát lại thông báo cũ chỉ để tăng tương tác. Đối chiếu role trước khi viết copy “ông bà vừa thêm ảnh”.
- **Lumi Insight:** dùng nguồn được kiểm tra và đủ mới, có link giải thích trong app, không tạo một kênh cạnh tranh với personal digest hiện có. Sparse data/low confidence → không nhắc; không chẩn đoán, hứa kết quả sức khỏe hoặc sinh nội dung trả phí chỉ để có push.

## Delivery: gate kiểm chứng riêng

Không đồng nhất “backend đã nhận yêu cầu gửi” với “điện thoại đã hiện thông báo”. Với platform/trạng thái không có receipt đáng tin cậy, delivery là **unknown**. Một lượt test thấy thông báo không chứng minh tỷ lệ delivery production.

| Gate             | Ca phải thử bằng dữ liệu tổng hợp trên iOS/Android thật                                      | Bằng chứng cần ghi                                                                                     |
| ---------------- | -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| Quyền OS         | Cho phép, từ chối, tắt trong Settings, đổi setting trong app                                 | Quyết định gửi/không gửi đúng; hướng dẫn hoặc inbox phù hợp                                            |
| Vòng đời app     | Foreground, background, khóa máy, terminate/relaunch; phân biệt force-stop và OS termination | Backend/local scheduling record, quan sát có/không hiện, opened callback; ghi các hạn chế của platform |
| Thời gian/mạng   | Qua 24 giờ, DST, đổi múi giờ, quiet hours, offline rồi online, source hết hạn                | Không nhắc trước hạn; không gửi dồn nội dung cũ; thời điểm thực tế so với thời điểm đủ điều kiện       |
| Vòng đời dữ liệu | Lưu/bỏ qua ảnh, queued/processing/ready/unreadable, job render lỗi/hoàn tất, đã ghi care     | Hủy hoặc thay lời nhắc đúng; không báo hoàn tất khi mới enqueue                                        |
| Phiên/gia đình   | A → logout → B, revoke/expire/đổi role, xóa bé, hai thiết bị hoặc hai người cùng hoàn tất    | Không hiện/mở dữ liệu cũ; dedup/cap và cancel hoạt động đúng                                           |
| Đích đến         | Tap khi app đang mở/cold start, nhiều bé, VI/EN, nguồn đã xóa                                | Đúng màn hình và quyền; trạng thái fallback rõ; không lấy open làm bằng chứng đã hoàn tất              |

Mỗi case ghi revision app/backend/config, OS/device, loại nhắc, điều kiện và kết quả expected/observed. Dùng screenshot/test trace với dữ liệu tổng hợp; không đưa token, nội dung trẻ hoặc operational IDs vào analytics/log chung. Test planner, emulator và mock FCM vẫn cần, nhưng không thay gate thiết bị.

## Đo lường và thứ tự bàn giao V1

Xem [bổ sung measurement ENG](10-analytics-and-success-metrics.md#smart-reminder--engagement-measurement) và [roadmap ENG](09-implementation-roadmap.md#smart-reminder--engagement-workstream).

1. **V1-A — measurement/design first:** hoàn tất event/cohort/attribution và Portal requirements/fixtures trước engine; giữ P0 privacy/render/deletion gates và policy approval.
2. **V1-B — full implementation:** ENG-00–06, gồm late onboarding/backfill; reuse capabilities, không cần limited-user pilot trước app launch.
3. **V1-C — validation & release approval:** automated/Rules/integration, iOS/Android physical-device matrix theo capability, privacy/Portal/kill-switch/rollback validation; all ENG IDs đủ acceptance. Không lấy code patch hoặc emulator pass thay device gate.
4. **V1-D — Production Launch with Measurement:** sau approval mới phát hành cùng app; thu actual baseline/cohort outcomes/guardrails, không giả statistical significance khi N nhỏ. Không deploy hoặc đổi production config trong lượt refinement này.

Trạng thái: **tài liệu và acceptance đã mở rộng; chưa triển khai engine mới, chưa xác nhận delivery thực tế, chưa deploy**. Không tự bật bất kỳ kênh mới nào. [Roadmap V1](09-implementation-roadmap.md#smart-reminder--engagement-workstream) và [engineering tickets](14-notification-implementation-plan.md) là lịch bàn giao hiện hành.
