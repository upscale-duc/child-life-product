# Living Header — chỉnh nhẹ chiều cao và độ rõ ảnh · 27/10/2026

Theo phản hồi sau khi cài lên Duckie: header đẩy nhật ký xuống thấp, ảnh thật bị lớp phủ làm mờ. Chủ sản phẩm yêu cầu sửa Figma trước, sau đó làm rõ chỉ giảm nhẹ để giữ vùng ảnh.

## Thiết kế đã chỉnh trên Figma

Phân loại REFINE: giữ nguyên cấu trúc và thao tác, chỉ giảm khoảng trống và điều chỉnh lớp phủ. Nguồn trực tiếp: section `1187:15786`, bộ component `1190:16431`, file `sJLG1fAXKDnDr9YI6Yx8ex`.

- Header thường 360 → **312pt** gồm status bar 40pt: giảm 48pt, khoảng 13%. Giữ lời chào 30/36, hàng chọn bé và vùng ảnh thật. Riêng biến thể mốc tuổi có lời phụ dài cao 322pt.
- Nội dung Hôm nay bắt đầu 352 → **304pt**. Tab bar, FAB và nội dung giữ nguyên vị trí/chức năng thiết kế tương ứng; không đổi thứ tự các phần.
- Bỏ lớp phủ màu toàn ảnh; lớp phủ dịu giảm còn **4% Light / 12% Night care**. Gradient giữ vùng trái dễ đọc rồi chuyển sang trong suốt ở vùng mặt bé; chỉ fade đoạn cuối chân ảnh. Không blur ảnh.
- Dùng biến màu hiện có. Sửa cả master Light, các instance Night, ảnh Kỷ niệm và preview liên quan. Đã xem render mới đủ 5 thời điểm × 2 nền × Light/Night; kèm màn Hôm nay và preview cài đặt.
- Phát hiện một header sinh nhật khác (`1219:16535`) đang chồng lên header ảnh của HH02N. Đã ẩn instance chồng, không xoá, để màn Night photo hiển thị đúng ảnh và trạng thái của nó.
- Sửa dòng chú thích hình nền theo quyết định lưu riêng trên thiết bị. Spec ghi rõ ẩn trạng thái sẽ bỏ hàng cùng khoảng cách, không sắp xếp/ghim.

Bằng chứng: [Light](assets/2026-10-27-header-refinement/light-after.png), [Night](assets/2026-10-27-header-refinement/night-after.png), [tất cả biến thể Light](assets/2026-10-27-header-refinement/variations.png), [Night](assets/2026-10-27-header-refinement/variations-night.png).

Giới hạn: đây là bản sửa Figma để chủ sản phẩm review, **chưa áp dụng kích thước/gradient mới vào Flutter hoặc cài lại app**. Chưa kiểm tra bản thiết kế mới ở tiếng Anh hoặc chữ 200%; phải thực hiện khi triển khai mobile. Render cho thấy nội dung được kéo lên 48pt và mặt bé rõ hơn, không kết luận về mọi ảnh người dùng.

## Lỗi đã nhận ca nhưng vẫn báo chưa ai nhận

C: mobile coi ca từ 24 giờ trở lên là hết hiệu lực (`dutyAge`). Máy chủ trước đây bỏ qua mọi lần nhận ca nếu UID vẫn là cùng người đó, kể cả ca đã hết hiệu lực. Phản hồi callable còn trả giờ hiện tại dù không ghi gì. Vì thế thao tác có thể báo thành công trong khi dữ liệu cũ vẫn khiến header hiển thị “Chưa ai nhận trông bé”.

Đã sửa `firebase/functions/src/care-duty.ts`: cùng người nhận lại ca hết hiệu lực sẽ ghi giờ bắt đầu mới; bấm lại ca còn hiệu lực vẫn giữ giờ cũ; phản hồi callable trả trạng thái thực sự được lưu. Không đổi quyền nhận/kết thúc ca hoặc ngưỡng 24 giờ.

Kiểm tra: bộ integration Firestore emulator `handover-send.integration.test.ts` đạt **10/10** (có nhận lại sau 24 giờ và retry ca mới); kiểm tra kiểu Functions đạt; Prettier đạt. Test mới đã thất bại với mã trước khi sửa.

Đã triển khai riêng `functions:setCareDuty` lên **child-life-dev** bằng script dự án. Cloud Run xác nhận revision mới ready và nhận 100% traffic. Lần upload đầu lỗi mạng, lần thử lại thành công. Chưa thao tác nhận ca bằng tài khoản thật của gia đình; không thay đổi dữ liệu chăm bé để kiểm tra. App dev hiện tại nhận bản sửa backend, không cần cài lại cho lỗi này.
