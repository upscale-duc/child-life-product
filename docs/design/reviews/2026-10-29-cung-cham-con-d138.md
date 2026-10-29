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

## Luật huy hiệu (bản nháp, chờ duyệt)

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

- **Ghi ở Chăm sóc không tự đánh dấu xong việc trong lịch.** Chủ sản phẩm không yêu cầu chiều này.
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
