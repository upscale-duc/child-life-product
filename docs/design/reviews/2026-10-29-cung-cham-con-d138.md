# Cùng Chăm Con ↔ Chăm sóc, Báo cáo, Lịch sử thay đổi (29/10/2026)

Quyết định: **D-138** trong `docs/product/business-map.md`. Chủ sản phẩm trả lời ngày 29/10:

- Lịch và Chăm sóc là một nguồn ghi chép.
- Xong việc "Ngủ" thì bắt đầu hẹn giờ ngủ.
- Các việc khác hiện thành một dòng trong ngày ở Lịch sử.
- Báo cáo làm đủ, luật huy hiệu do engineering soạn.

Figma: 11 `1353:22754`, 12 `1382:22199`, nút biểu đồ `1380:22479`, 20 `1360:23617`.

## Đã làm

### Xong việc là ghi luôn

Áp dụng ở mọi chỗ đánh dấu xong: lịch 04, khối Hôm nay 14, "Đến giờ rồi" 15, Home người hỗ trợ 16 và 17.

- **Bú bình:** mở màn ghi Bú bình, điền sẵn số ml đã lên lịch. Lưu thì bản ghi vào Nhịp hôm nay và Lịch sử, việc thành "xong". Đóng màn mà không lưu thì việc vẫn mở.
- **Bú mẹ, Hút sữa, Thay tã:** cũng mở màn ghi tương ứng như trên.
- **Ngủ:** bắt đầu hẹn giờ ngủ rồi đánh dấu xong. Khi dừng hẹn giờ, giấc ngủ thành bản ghi.
- **Các việc khác** (Tắm, Nằm sấp, Vitamin, Đọc sách, Đi dạo…): đánh dấu xong. Lịch sử ở bộ lọc "Tất cả" hiện thêm một dòng, ví dụ "18:32 Tắm · Việc trong lịch · Ba làm". Dòng này không cộng vào số liệu Bú, Ngủ, Tã.
- Thông báo "Đã ghi · Bú bình 90 ml · Hoàn tác" của màn ghi được giữ. Không hiện thêm thông báo "đã xong" thứ hai.

### Số ml dự kiến

- Khi thêm hoặc sửa việc **Bú bình** hay **Hút sữa**, có hàng "Lượng": Chưa định, 60, 90, 120, 150, 180 ml.
- Thẻ việc hiện "Bú bình · 120 ml".
- Số ml được giữ khi việc lặp "Mọi ngày" và khi tạo lịch "Giống hôm qua".

### Nút biểu đồ và màn 11 "Cùng nhau chăm"

- Thanh tiêu đề lịch có nút biểu đồ mở màn Báo cáo.
- Chọn Tuần, Tháng hoặc Năm (tuần bắt đầu thứ Hai).
- Vòng tròn chia phần trăm theo người, kèm tổng số việc.
- Ba ô số liệu: **tim** (tạm là 0, chờ tính năng thả tim ở bước 5), **ngày liền** (số ngày liên tiếp có ít nhất một việc xong, đếm ngược tối đa 60 ngày), **đúng nhịp** (phần trăm việc xong trong khoảng ±30 phút so với giờ hẹn).
- **Huy hiệu tuần này** tính trên 7 ngày gần nhất. Huy hiệu đã đạt xếp trước, có avatar người đạt; chưa đạt có ổ khoá.
- Nút "Khoe cả nhà" mở Thẻ chia sẻ (12).

### Thẻ chia sẻ (12)

- Thẻ gồm: Child Life, Tuần 44, "Tuần này cả nhà cùng chăm Teddy", vòng tròn, tối đa 3 huy hiệu đã đạt. Dòng "lời cảm ơn" chỉ hiện khi có tim.
- **Story:** chia sẻ ảnh thẻ 1080 px.
- **Sao chép:** chép đoạn tóm tắt.
- **Khác:** mở bảng chia sẻ của máy, gửi ảnh kèm chữ.

### Màn 20 "Lịch sử thay đổi"

- Mở từ Cài đặt › Lịch › Lịch sử thay đổi.
- Hiện 30 ngày, nhóm theo Hôm nay, Hôm qua, rồi theo ngày. Mỗi dòng có avatar người làm và biểu tượng nhỏ cho loại thay đổi.
- Các loại dòng: "Bú bình 13:00 → 13:30", "Thêm “Đọc sách” 20:00 · mọi ngày", "Giao 3 việc cho Cô Lan", "Xoá “Thay tã” 15:30 · chỉ ngày đó", "Lên lịch Theo nhịp 7 ngày qua", "Tự tạo bản nháp buổi sáng".
- Đánh dấu xong hoặc bỏ đánh dấu không phải là sửa lịch, nên không hiện ở đây.
- **Hoàn tác** có ở thay đổi mới nhất của một việc, nếu đó là thêm việc hoặc đổi giờ, trên hôm nay hoặc hôm qua, và chỉ người quản lý lịch thấy.

## Luật huy hiệu (chủ sản phẩm đã duyệt 29/10/2026)

Tính trên 7 ngày gần nhất. Huy hiệu cá nhân trao cho người làm nhiều nhất trong số người đạt mốc. Code: `apps/mobile/lib/features/care_plan/care_plan_report_calc.dart` › `CarePlanBadgeRules`.

| Huy hiệu | Luật nháp |
|---|---|
| Siêu tắm | Tắm ≥ 3 lần |
| Cú đêm | ≥ 3 việc xong trong 22:00 – 05:00 |
| Kể chuyện | Đọc sách ≥ 3 lần |
| Bình sữa vàng | Bú bình hoặc bú mẹ ≥ 10 lần |
| Tã thần tốc | Thay tã ≥ 10 lần |
| Ông bà siêu sao | Ông hoặc bà làm ≥ 5 việc |
| Đúng giờ 7 ngày (cả nhà) | 7 ngày liền đều có việc xong, và ≥ 80 % đúng nhịp |
| Đồng đội ăn ý (cả nhà) | ≥ 3 người, mỗi người ≥ 3 việc |
| Vitamin đều đặn (cả nhà) | Vitamin xong ≥ 5 ngày |

## Còn lại và giới hạn

- **Ghi ở Chăm sóc tự đánh dấu xong việc trong lịch** (chủ sản phẩm duyệt 29/10): bản ghi Bú bình / Bú mẹ / Hút sữa / Tã / Ngủ đánh dấu xong việc cùng loại còn mở gần giờ nhất trong ngày, trong ±1 giờ, người làm là người ghi (`onRecordForCarePlan`). Nếu chính người đó vừa đánh dấu một việc cùng loại trong 5 phút (bản ghi đến từ lịch) thì không đánh dấu thêm.
- **Bỏ đánh dấu xong không xoá bản ghi.** Muốn xoá thì dùng "Hoàn tác" trên thông báo hoặc xoá ở Lịch sử.
- **Tim:** hiện 0 cho tới khi có tính năng thả tim (màn 10, bước 5).
- **"Xem tất cả huy hiệu":** chưa có màn riêng nên chưa hiện liên kết.
- **Story** chia sẻ ảnh qua bảng chia sẻ của máy, chưa gửi thẳng vào Instagram Story.
- **Báo cáo đọc từ `carePlanHistory`** (tối đa 5000 dòng). Cả năm thì vẫn đủ, nhưng nếu dữ liệu nhiều có thể cần chuyển sang tổng hợp ở server.

## Kiểm chứng

- **Golden mới** `care_plan_report/*`, 12 ảnh: report_week, share_card, change_history.
- **Golden cập nhật:**
  - `care_plan/*`: thêm "· 120 ml" và nút biểu đồ.
  - `care_plan_today/settings*`: thêm dòng Lịch sử thay đổi.
- **Ảnh đã xem:** report light vi, share light vi và night en, change_history light vi, plan_underway, settings.
- **Test hành vi:**
  - Việc Bú bình mở màn ghi với 120 ml; đóng mà không lưu thì không đánh dấu xong.
  - Thêm việc Bú bình gửi đi `amountMl`.
  - Lịch sử hiện dòng Tắm, không lặp lại Bú bình, và ẩn dòng này ở bộ lọc Bú.
  - Tính toán báo cáo: hoàn tác, ngày liền, đúng nhịp, huy hiệu, phần trăm cộng đủ 100.
- **Emulator:** 35 test care-plan, thêm hai test mới cho `amountMl` và `oldTime`.

## Thông báo N1 và trạng thái chờ (30/10/2026)

Figma `1353:22588` (4 thông báo N1–N4). Chủ sản phẩm báo: việc sắp tới chỉ nhắc trong app, không có push.

### Vì sao không thấy push (dữ liệu dev, 30/10)

- Server gửi đúng giờ. Hàm `ringCareTaskReminders` chạy mỗi phút; hôm nay việc 13:00 được nhắc lúc 12:50 (nhắc trước 10 phút) và Apple đã nhận.
- Ngày 29/10: hai lần Apple từ chối token cũ của máy (sau khi cài bản mới), hai lần không có máy nào đăng ký token. Mở app sau khi cài là token mới được đăng ký.
- Lịch hôm nay được tạo lúc 12:42, nên các việc 09:00–11:00 đã qua giờ và không được nhắc.
- Khi app đang mở, iOS không hiện banner cho push của server.

### Đã làm

- **N1 theo Figma:** "Ba ơi, 5 phút nữa Teddy cần Ba rồi nè" / "Vitamin · Bú bình". Tên người nhận theo cách cả nhà gọi (Ba, Mẹ, Ông, Bà, hoặc tên tự đặt như "Cô Lan"), placeholder `recipient_name`; tên bé theo D-094.
- **Nút trên thông báo:**
  - **Xong:** việc không cần ghi (Vitamin, Tắm…) được đánh dấu xong ngay, không mở app.
  - Việc Bú bình, Bú mẹ, Hút sữa, Thay tã thì mở app vào màn ghi, còn Ngủ thì mở app vào hẹn giờ ngủ (D-138).
  - **Nhắc lại 10 phút:** thông báo hiện lại sau 10 phút trên chính máy đó.
  - Có trên cả iOS (category `CL_CARE_TASK` / `CL_CARE_TASK_APP`) và Android (app tự vẽ, `Push.kt`).
- **iOS khi app đang mở:** N1 vẫn hiện banner.
- **Trạng thái chờ:**
  - Sheet "Giao cho…" giữ mở, nút xác nhận hiện loading cho tới khi server lưu xong; lỗi thì báo và giữ lựa chọn.
  - Xoá việc hiện vòng chờ toàn màn (`withClProgress`).

### Chưa làm

- **N2 "Teddy no bụng rồi, nhờ có Mẹ đó!" + Thả tim, N3 "Mẹ thả tim cho Ba", màn 10 Vừa xong:** thuộc bước 5, cần frame 10 và một công tắc riêng cho từng người.
- **Icon việc trong thông báo** (ảnh nhỏ bên trái): cần Notification Service Extension (iOS) và ảnh lớn trên Android. Hiện thông báo chỉ có chữ.
- **N4** đã có từ bước 3. Câu chữ hiện là "Cô Lan vừa bàn giao cho cả nhà"; Figma ghi "gửi lời bàn giao". Phần này để cho đợt sửa câu chữ thông báo đang chạy song song.
- **Widget `1356:23340`:** chưa đọc được frame vì Figma đang chặn quyền MCP.

## N2, N3 và màn 10 Vừa xong (30/10/2026, chủ sản phẩm: "Làm N2/N3 luôn")

Màn 10 dựng theo cấu trúc frame `1353:22683` đã lưu (MCP Figma đang bị chặn nên không render được frame), câu chữ theo analysis 28/10 §6.1.

- **N2 "Teddy no bụng rồi, nhờ có Mẹ đó!" / "Bú bình · Cảm ơn Mẹ nhé!":**
  - Gửi khi một việc hôm nay thành "xong", bất kể đánh dấu từ đâu: lịch, Hôm nay, nút trên thông báo, hay ghi ở Chăm sóc. Trigger `onCarePlanItemWrite`.
  - Người nhận: những người cùng chăm khác (Cùng nuôi, Người chăm sóc). Không gửi cho người vừa làm, không gửi người thân.
  - Không ghi số ml (D-135 Q7).
  - Tên bé theo "Hiện tên bé" của từng người (D-094). Thông báo tôn trọng giờ yên lặng.
  - Việc của ngày cũ thì không báo.
  - Nút **Thả tim** gửi tim ngay, không cần mở app (iOS `CL_CARE_DONE`, Android tự vẽ).
- **Màn 10:**
  - Có hình việc trong vòng tròn, avatar người làm và các trái tim, rồi tới dòng "Ba vừa tắm cho Teddy" và giờ làm.
  - Ba nút: tim (kèm số tim), Cảm ơn, Tuyệt. Ba lời nhanh: "Cảm ơn Ba!", "Ba giỏi quá", "Thương Ba".
  - Nút chính "Gửi cho Ba".
  - Tim đã gửi thì không rút lại. Người làm mở màn này thì chỉ thấy "2 tim từ cả nhà".
- **N3 "Mẹ thả tim cho Ba ❤️" / “Cảm ơn Ba đã tắm cho Teddy nha!”:**
  - Gửi cho người đã làm. Nhiều tim cho cùng một việc gộp thành một thông báo trên màn khoá.
  - Chạm vào thì mở lịch của ngày đó.
- **Công tắc "Khi người khác làm xong"** ở Cài đặt › Nhắc việc, của từng người, mặc định bật. Công tắc này tắt cả N2 lẫn N3.
- **Báo cáo:** ô "tim" giờ đếm tim thật trong khoảng đang xem. Lịch sử thay đổi (20) không liệt kê lượt thả tim.

Khác Figma:
- Bỏ "sớm 5 phút" dưới giờ làm, vì lịch không chấm giờ giấc (D-135 Q8).
- Nhãn nút chính không có trong metadata, nên tôi đặt là "Gửi cho Ba".
- Lời nhắn là các câu chọn sẵn, không có ô gõ tự do. Nhờ vậy thông báo chỉ trích câu của app.

## Widget Cùng Chăm Con (30/10/2026, Figma `1356:23340` theo ảnh chủ sản phẩm gửi)

- **Việc của Ba (vừa, 4×2):**
  - Việc kế tiếp của mình ("09:00 · Vitamin D3"), có nút ✓.
  - Dưới cùng: vòng tiến độ "Cả nhà 2/10" và mặt cả nhà.
  - Hết việc của mình thì hiện "Nghỉ chút nhé".
- **Cả nhà cùng chăm (nhỏ, 2×2):**
  - Vòng "2/10 · Còn 8 việc".
  - Khi mình không còn việc nào: nền vàng, em bé ngủ, "Nghỉ chút nhé".
- **Việc của Cô Lan (lớn, 4×4):**
  - Tối đa 5 việc còn mở của mình, kèm số việc. Việc đầu được tô màu.
  - Mỗi dòng có vòng tròn để đánh dấu xong.
- **Người hỗ trợ chưa có việc:** dùng widget "Ghi nhanh" đã có, đúng như hình thứ tư.
- **Nút ✓:**
  - Việc không cần ghi thì xong ngay trên widget.
  - Bú bình, Bú mẹ, Hút sữa, Thay tã thì mở app vào màn ghi; Ngủ thì mở hẹn giờ (D-138).
- **Cập nhật:**
  - iOS đọc lại lịch từ Firestore mỗi lần widget làm mới, nên thấy được việc người khác vừa đánh dấu.
  - Android cập nhật khi app ghi lại dữ liệu hoặc khi bấm trên widget.

Cách hiểu thiết kế, chờ chủ sản phẩm xem:
- Ô vàng "Nghỉ chút nhé" là trạng thái của widget nhỏ khi mình không còn việc, không phải một widget riêng.
- Widget lớn dùng cho bất kỳ ai được giao việc, không chỉ người hỗ trợ.
