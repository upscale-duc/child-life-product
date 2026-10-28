# Cùng Chăm Con — flow nối vào app hiện tại

**Chốt thiết kế 28/10/2026:** dùng tài liệu đính kèm và phần summary cuối cùng của chủ sản phẩm. **Bố mẹ cùng chăm, không phân ca/nhận ca/bàn giao giữa vợ chồng. Ca và bàn giao chỉ dành cho ông bà/bảo mẫu hỗ trợ.** Sáng/Chiều/Tối là nhóm công việc để chọn nhanh. Cả hai phần dùng chung lịch sinh hoạt và Care Log.

**Mở thiết kế:** [frame Cùng Chăm Con](https://www.figma.com/design/sJLG1fAXKDnDr9YI6Yx8ex/Child-Life?node-id=1317-20330) · [toàn bộ hành trình trong app](https://www.figma.com/design/sJLG1fAXKDnDr9YI6Yx8ex/Child-Life?node-id=1329-21181) · [bắt đầu prototype từ Khám phá](https://www.figma.com/proto/sJLG1fAXKDnDr9YI6Yx8ex/Child-Life?node-id=1316-19908&starting-point-node-id=1316%3A19908).

Figma là **thiết kế đề xuất có lớp chỉnh sửa và điểm nối**, chưa phải tính năng đã triển khai trong app. Dữ liệu minh họa là Teddy, 4 tháng, ngày 28/10. Các trạng thái minh họa góc nhìn Ba/Mẹ/Cô Lan/Bà Hoa; prototype không giả lập đăng nhập, nhập liệu, lưu server hay phát thông báo thật.

**Home đã nối lại theo màn chủ sản phẩm cung cấp:** [Home hiện tại — Living Header / Night care](https://www.figma.com/design/sJLG1fAXKDnDr9YI6Yx8ex/Child-Life?node-id=1192-16419) → [Home đề xuất có Cùng Chăm Con](https://www.figma.com/design/sJLG1fAXKDnDr9YI6Yx8ex/Child-Life?node-id=1316-20140). Giữ Living Header, gợi ý chọn ảnh, bốn ô Nhịp hôm nay, Lumi, nút thêm và thanh điều hướng từ chính màn này. Chip “Chưa ai nhận trông bé” được đổi thành entry lịch chung ở góc nhìn bố mẹ; thêm thẻ việc cá nhân phía trên gợi ý ảnh. Ba trạng thái vuốt và Home không có người hỗ trợ dùng cùng bố cục 375 px; không sửa màn nguồn. Home người hỗ trợ là giao diện riêng theo brief, có ca chăm sóc thực sự.

## 1. Hai thành phần, một dữ liệu chung

| Cùng nhau chăm — Ba/Mẹ | Người hỗ trợ chăm sóc — Ông bà/Bảo mẫu |
|---|---|
| Lịch ngày chung, nhóm Sáng/Chiều/Tối | Lịch làm việc theo ca, ví dụ Cô Lan 07:00–17:00 |
| Giao một/nhiều việc cho Ba, Mẹ hoặc cả hai | Giao người hỗ trợ việc phù hợp trong ca |
| Làm giúp nhau tự nhiên; không cần nhận việc/đổi ca trước khi ghi | Home/widget tập trung việc được giao, ghi nhanh, ghi chú |
| Ai thực hiện thì Care Log ghi đúng người, cập nhật việc liên kết | Bàn giao cho bố mẹ khi kết thúc ca; có tóm tắt, lưu ý, việc chưa làm |
| Thả tim, cảm ơn, báo cáo đồng hành | Báo cáo hoạt động và xác nhận bố mẹ đã đọc thông tin |

“Bà” là quan hệ, không tự cấp quyền. Bà ở role Người chăm sóc được phân việc; Người thân chỉ xem không tự được nhận việc hoặc sửa log. Chế độ giao diện đơn giản cũng không tự nâng quyền.

## 2. Người dùng đi trong app như thế nào

| Bước | Màn thật / slot đang có | Hành vi thiết kế và đích quay về | Frame minh họa |
|---|---|---|---|
| 1 | Khám phá → nhóm Gia đình & trợ lý; Gia đình từ `/utilities/family`; Lumi từ `/assistant` | Thêm **Cùng Chăm Con** tại Gia đình và Lumi, cùng mở một bé/ngày. Giữ thành viên, quyền, lời mời. Khám phá vẫn là điểm tìm thấy hai mục này | `explore`, `family`, `lumi` |
| 2 | Hôm nay: slot “Ai đang chăm”, Nhắc việc, Tuỳ chỉnh Hôm nay | **Nhắc việc chăm con** hiển thị việc sắp tới của chính người xem và tổng số, lật dọc. Ba thấy tắm 18:30, đọc sách 20:00, ru ngủ 20:30. Không có việc thì nghỉ ngơi; ẩn/hiện trong Tuỳ chỉnh | `home`, `homeNext`, `homeIdle`, `homeCustom` |
| 3 | Lịch sử chăm sóc và tuổi onboarding đang có | Đã có lịch hôm nay → mở ngay. Chưa có: đủ dữ liệu → xem bản nháp; thiếu dữ liệu → chọn lịch cơ bản/EASY 3.5/EASY 4/tự tạo. Cả hai nhánh cùng về xem trước, chỉ áp dụng khi gia đình chọn | `draftKnown`, `method`, `preview`, `nextDay` |
| 4 | Nhắc việc có assignee; careWork có nhận/trả/xong | Lịch chung gồm ba **buổi**. Chọn một/nhiều việc hoặc avatar nhóm buổi để giao nhanh; có **Ba và Mẹ cùng làm**. Parent không có bước nhận ca hoặc đổi ca | `plan`, `selectTasks`, `assignShift`, `editTask` |
| 5 | Form bú/ngủ/tã, timer và Care Log hiện có | Mở form từ việc → nhập giờ/lượng thực tế → lưu một log và cập nhật một việc. Ghi ngoài kế hoạch luôn được. Timer mới bắt đầu chỉ là đang diễn ra | `task`, `logActual`, `logDiaper`, `taskSleep`, `sleepRunning`, `actual` |
| 6 | Ba thực hiện việc Mẹ dự kiến phụ trách | Ví dụ Mẹ phụ trách bú 13:00, Ba ghi 13:10/120 ml: không đổi người phụ trách trước, log ghi **Ba thực hiện**, lịch sử giữ kế hoạch ban đầu | `logParent`, `actual`, `history` |
| 7 | Home/Widget Người chăm sóc | Cô Lan thấy ca 07:00–17:00, việc gần nhất, ghi nhanh và ghi chú. Không phải đọc báo cáo của bố mẹ để làm việc | `careHome`, `support`, `widgets` |
| 8 | Bàn giao `/rhythm/handover` | Chỉ hiện entry Home khi gia đình có người hỗ trợ có quyền chăm sóc. Thêm việc chưa làm của ngày, giữ nhật ký/safety/nguồn/AI hiện có. **Cô Lan → bố mẹ**, không phải Ba → Mẹ. Bố mẹ chỉ xác nhận đã nhận thông tin | `handover`, `receive`, `received` |
| 9 | Nhắc việc `/care/reminders` | Việc chăm con xuất hiện với tag **Cùng Chăm Con** cạnh việc **Cá nhân**. Dùng cùng id/projection; ghi ở Home, lịch hay Nhắc việc đều cập nhật cùng việc | `reminders` |
| 10 | Tuần này của Teddy → `/rhythm/week` | Entry nói về tuần hiện tại. Vào trong xem các tuần trước. Báo cáo đồng hành có Tuần/Tháng/Năm, ghi nhận yêu thương, preview chia sẻ | `week`, `report`, `reportMonth`, `reportYear`, `share` |
| 11 | Cài đặt thông báo, Quiet hours, Tuỳ chỉnh Hôm nay | Mặc định nhắc trước 5 phút, chọn 5/10/15 hoặc tắt theo loại. Gộp cập nhật hoàn thành; chọn nhận lời cảm ơn; tắt tự chuẩn bị nháp/ngày mới độc lập với ẩn card Home | `notifications`, `settings`, `homeCustom` |

**Route mới đề xuất:** `/care/together?date=...&view=together|helpers`, lấy bé từ selected membership; route task mang `planItemId`. Đây là đề xuất cho triển khai, không phải route đã có. Điểm vào Gia đình/Lumi/Home cùng dùng màn này, không tạo ba checklist. Route việc cũ `/rhythm/day/handover` cần giữ deep link và mở cùng dữ liệu/ngữ cảnh khi nâng cấp. Back từ form quay về nguồn mở form, không tự nhảy sang một Home khác.

**Nguồn Flutter để triển khai:** `features/today/today_screen.dart` (careDuty/tiles/ReminderPeek/TodayHandoverRow), `today/today_for_baby.dart` (weekly), `family/family_screen.dart`, `utilities/utilities_screen.dart` (utMembers), `assistant/assistant_entry.dart`, `rhythm/personalization_sources.dart` (hiện `.take(1)` việc), `rhythm/personal_day_pages.dart`, `reminders/reminder_screens.dart`, `ai/handover_screen.dart`, `today/today_personalize.dart`. Đây là các slot thật đã đối chiếu, không phải một ứng dụng Tasks riêng.

## 3. Plan và Actual liên kết ra sao

- **Một PlanDay/bé/ngày**, ngày theo timezone bé, có draft/published và revision. Sáng/Chiều/Tối là `timeGroup`, **không** là shift của bố mẹ.
- **PlanItem** có giờ dự kiến, assignee(s), ghi chú và stable id. Giao cả buổi chỉ cập nhật những item được chọn. Hai người cùng làm vẫn là một việc.
- **Actual/Care Log** giữ giờ/lượng/thời gian và người thực hiện thật. Author/người nhập và người thực hiện không được đánh tráo. Ghi từ task có `planItemId`; ghi độc lập có thể gợi ý liên kết để người dùng xác nhận, không tự đoán trùng việc.
- Sau log được server xác nhận, cập nhật item liên kết; không tạo hai log khi đi qua Home và Nhắc việc. Retry cần idempotency. Log offline hiện chờ đồng bộ, chưa nói cả nhà đã thấy.
- Bắt đầu timer chưa phải hoàn thành giấc ngủ. Hoàn thành nhắc việc thuốc không được tự suy thành một lần đã dùng thuốc. Hút sữa không tính là bé đã bú.
- Sửa/xóa kế hoạch không sửa/xóa log thật. Bỏ qua/để sau không bị ghi thành đã thực hiện. Lịch sử lưu bản kế hoạch, ai sửa, thời gian và actual.
- **HelperShift** chỉ có cho người hỗ trợ: giờ bắt đầu/kết thúc, ghi chú và receipt bàn giao. Không tự thay phân công của bố mẹ hoặc tạo một ParentShift sau khi họ xác nhận.

**Khác biệt backend quan trọng:** `markHandover(received)` hiện có gọi cập nhật careDuty người nhận; không dùng nguyên hành vi đó cho nút **Đã nhận thông tin** trong thiết kế mới. Cần tách acknowledge thông tin bàn giao người hỗ trợ khỏi việc tạo/đổi ca, đồng thời giữ route cũ và các dữ liệu đã có. Care Log → hoàn thành item cũng cần tích hợp/transaction mới; không buộc bố mẹ làm thao tác nhận việc chỉ để phù hợp state machine cũ.

## 4. Giảm mental load mà không biến thành chấm công

| Quy tắc | Thể hiện trong thiết kế |
|---|---|
| Không ép đúng giờ/đủ số | Giờ dự kiến, actual riêng, không điểm trễ, không % cữ đúng giờ; “3 điều nhỏ”, không KPI chăm con |
| Ghi nhận công sức | Thả tim/cảm ơn tự nguyện cho một cập nhật; báo cáo gia đình chung, không xếp hạng vợ/chồng hoặc 45%–55% công sức |
| Thông báo thân thương | “Ba ơi, vài phút nữa mình cùng bên Teddy nhé.” Không mặc định Mẹ đuối sức hay làm người kia thấy có lỗi |
| Hoàn thành cập nhật cho người cùng chăm | Một event server-ack; không gửi lại cho người vừa làm, gộp đợt, tôn trọng tắt/quiet hours. Mọi cập nhật vẫn xem được trong app |
| Lịch mẫu linh hoạt | Tuổi/lịch sử chỉ chuẩn bị nháp; gia đình chọn/chỉnh/tắt. EASY là lựa chọn tham khảo, không mặc định phù hợp theo một tuổi và không sinh thuốc/liều |
| Ngày mới | Chuẩn bị nháp trước, nhắc một lần, chưa tự áp kế hoạch. Tắt auto-draft và nhắc ngày mới được |
| Widget/action nhanh | Parent: việc tiếp theo, việc chung. Helper: việc/ghi nhanh/ghi chú/bàn giao. Màn khóa ẩn chi tiết, kiểm lại account/quyền/revision trước lưu; dữ liệu cần lượng/ngữ cảnh phải mở form |
| Chia sẻ social | Xem trước và chủ động dùng share sheet; mặc định ẩn tên/ảnh/số liệu. Không tự đăng hoặc chia sẻ dữ liệu sức khỏe |

Tiêu chí “đủ dữ liệu” để tạo nháp cần xác định khi triển khai (độ mới, độ phủ loại ghi nhận, lịch sử thực có); số 7 ngày trong mockup là dữ liệu minh họa, không phải ngưỡng y khoa đã được phê duyệt. Không dùng số ghi nhận để suy công bằng, chất lượng nuôi con hoặc sức khỏe bé.

## 5. Những gì giữ lại và những gì phải thêm

**Giữ:** roles/invites và owner protection, Care Log/forms/timers, assignee + reminderId, careWork và kiểm revision khi phù hợp, nguồn/stale/health/AI trong Bàn giao, quiet hours/dedup, Adaptive/legacy Home order/pin/hidden, entry deep link đang có. Không làm mất cùng ghi chăm sóc hoặc quyền lịch sử của các vai trò.

**Thêm theo brief:** lịch ngày/nhóm buổi và revision, gán nhiều người/chọn nhiều việc, Plan–Actual completion, quyền thêm/sửa/xóa kế hoạch cho từng caregiver, helper schedule/receipt riêng, Home carousel + widget theo vai trò, auto-draft ngày mới, reaction/cảm ơn, projection nhắc việc có tag và báo cáo/chia sẻ. Các phần này đang ở mức thiết kế, chưa ghi Firebase, phát push hoặc chạy widget native.

**Hai đường đọc cùng dữ liệu:** `Cùng nhau chăm` ưu tiên lịch chung và phối hợp; `Người hỗ trợ` ưu tiên ca hỗ trợ, hoạt động và bàn giao. Không tạo hai Care Log, không sao chép việc giữa Lumi và Gia đình.

## 6. Kiểm chứng và giới hạn

- Đã chạy lại **8/8 golden Home hiện tại**: Ba/Mẹ và Người chăm sóc × Light/Night × vi/en; chỉ đối chiếu, không sửa baseline. Đối chiếu điểm vào từ code và màn Figma `912:12697` đúng là Khám phá, không nhầm là một Home độc lập.
- Thiết kế Figma dùng component và biến Color/Size/text styles sẵn có, lớp text/icon/container chỉnh sửa được; không nhập ảnh chụp nguyên màn làm UI.
- Màn chính có Light/Night × vi/en. Đã mở render màn chính bốn biến thể và các flow rủi ro: Ba ghi giúp Mẹ, helper schedule, bàn giao thông tin, Home hai vai trò. Các màn phụ khác kiểm theo mẫu, không tuyên bố đã kiểm mắt toàn bộ mọi variant.
- Prototype có điểm bắt đầu từ Khám phá, Home Ba, Home người hỗ trợ và lịch chung. Back, Plan/Actual, báo cáo Tuần/Tháng/Năm và ba trạng thái swipe Home được nối. Sau khi nối lại Home: 321 reaction, 3 thao tác drag, không có đích Navigate không hợp lệ hoặc phần tử tràn ngang trong auto-layout theo kiểm tra cấu trúc. Đã xem render Home 375 px sau chỉnh sửa. Bấm các action dữ liệu là chuyển tới trạng thái minh họa, không phải lưu dữ liệu thật. Gửi lời mời/share sheet/OS settings và quyền OS là ngoài phạm vi prototype.
- Figma yêu cầu đích Navigate là frame cấp cao. Vì vậy Section **Cùng Chăm Con · Flow trong app** chứa các screen frame đồng cấp; frame chính tên chính xác **Cùng Chăm Con**, bản đồ hành trình nằm cùng Section. Đây là một khu thiết kế liên kết, không phải các file/tài liệu độc lập.
- Chưa kiểm VoiceOver/TalkBack, chữ 200% trong triển khai mới, native iOS/Android, delivery push hoặc transaction multi-device. Những kiểm tra của prototype Flutter cũ không được tính thành kết quả của thiết kế mới.
