# Living Header mobile — 27/10/2026

## Kết quả

Đã triển khai header Hôm nay theo Figma, gồm lời chào theo buổi, hình nền, chọn bé, thông báo, Night care và trạng thái trông bé. Tab bar, dock và các mục nội dung bên dưới giữ nguyên chức năng. Header cuộn cùng nội dung; không còn thanh chọn bé ghim riêng như trước.

Cài đặt giao diện nằm cuối danh sách Hôm nay, mở màn hình riêng có xem trước. Chọn hoạ tiết, ảnh đại diện thật hoặc ảnh từ Kỷ niệm; bấm Áp dụng mới lưu, quay lại bỏ bản nháp. Hình nền lưu trên thiết bị, tách theo tài khoản và bé; không lưu URL ảnh có thời hạn. Quyết định chủ sản phẩm được ghi tại D-128 trong business-map.md.

“Ai đang trông bé” cố định trong header, chỉ có bật/tắt, không kéo sắp xếp hoặc ghim. Ẩn làm header ngắn đi 96 điểm ở cỡ chữ mặc định. Header vẫn tăng chiều cao khi chữ lớn. Chế độ adaptive dùng tuỳ chọn hiển thị trong Tuỳ chỉnh Hôm nay; chế độ cũ dùng công tắc tại Cài đặt giao diện.

## Nguồn và phạm vi

- Figma được chủ sản phẩm chỉ định: section `1187:15786`, photo preview `1195:17039` trong file Child Life.
- Đã chỉnh trực tiếp gradient ảnh trên cả Light và Night care. Giữ ảnh gốc; kéo rộng vùng chuyển trong suốt, làm mềm chân ảnh. Night care dùng nền trung tính để tránh dải màu lệch với ảnh thật.
- SVG hoạ tiết lấy từ Figma; ảnh nền lấy qua nguồn ảnh và quyền truy cập hiện có của ứng dụng. Không thay đổi quyền chăm bé hoặc lịch sử bàn giao.
- Tự đổi sáng/chiều/tối theo giờ của bé; sinh nhật theo ngày sinh được phép xem. Chưa tự bật mốc tuổi như “6 tuần”: lịch mốc này chưa được xác định, không tự đặt thêm quy tắc sản phẩm.

## Nội dung và cấu trúc

Phân loại **RESTRUCTURE** giới hạn trong header theo bố cục chủ sản phẩm đã chọn. Gộp lời chào và thanh chọn bé vào cùng một vùng; chuyển trạng thái trông bé lên header; chuyển lựa chọn hình nền sang màn hình riêng; bỏ điều khiển sắp xếp/ghim trạng thái trông bé. Đổi lại, header có hình nền chiếm nhiều chiều cao hơn bản cũ và đẩy các thẻ nhật ký xuống; lựa chọn ẩn trạng thái giảm chiều cao đó.

## Bằng chứng và kiểm tra

Ảnh mới được render từ mã hiện tại, vi/en × Light/Night care. Các ảnh `before` được render trước thay đổi cùng fixture. Xem [ảnh trước/sau tiếng Việt](assets/2026-10-27-living-mobile/before-after-vi.jpg), [tiếng Anh](assets/2026-10-27-living-mobile/before-after-en.jpg), bốn contact sheet `header-review-*` và `affected-diffs-*` trong cùng thư mục.

- 26 kiểm thử chức năng đạt: lựa chọn chỉ lưu khi Áp dụng; Back bỏ bản nháp; đọc lại cài đặt; dữ liệu cục bộ hỏng có fallback; ẩn thu gọn header; không còn drag/pin; lỗi tải trạng thái không hiển thị sai là chưa ai nhận trông bé; các kiểm thử adaptive/care/home liên quan.
- 28 golden mới đạt: sáng/chiều/tối, ảnh thật, ẩn trạng thái, chữ 200%, màn hình cài đặt, đủ bốn tổ hợp ngôn ngữ/giao diện.
- 120 golden liên quan được cập nhật có chủ đích; đã xem các khác biệt. Ảnh ax10 trước/sau được lưu riêng.
- Phân tích tĩnh 11 file thay đổi/kiểm thử: không có vấn đề.
- Chạy lại toàn bộ golden: **1.962 đạt, 28 không khớp**. Toàn bộ golden header mới và các baseline liên quan đã cập nhật đều đạt. Không ghi đè 28 baseline ngoài phạm vi header: `hn/home_for_baby` (4), `flow_audit/paywall_price_unknown` (4), `flow_audit/storage_v2_member_full` (4), `pm/mo02_beta` (4), `pm/pr02_error` (4), `mm/mm01_photos` (2), `mm/mm03_nudge` (2), `mm/mm10_choose` (2), `rh/ms01_milestone` tiếng Việt (2). Không kết luận bộ golden toàn ứng dụng đã đạt.

## Review cuối

Gates trong phạm vi header: G1 ý nghĩa sản phẩm pass (C); G2 truy cập thao tác pass (R/C); G3 lưu dữ liệu pass (C/test); G4 quyền pass ở kiểm tra mã (C, chưa kiểm tra backend trực tiếp); G5 không thêm khẳng định AI/sức khoẻ (C); G6 tác vụ chính pass (R/C/test). Bộ kiểm tra toàn ứng dụng còn các khác biệt ngoài phạm vi như trên.

| Chiều đánh giá | Điểm | Bằng chứng / giới hạn |
|---|---:|---|
| Rõ mục đích | 4 | R: chọn hình nền và Áp dụng rõ |
| Thứ bậc thông tin | 4 | R: lời chào và trạng thái trong một vùng |
| Dễ quét nội dung | 4 | R: trạng thái một dòng ở cỡ thường, xuống dòng khi chữ lớn |
| Rõ thao tác | 4 | R/C/test: chọn, xem trước, Áp dụng, Back |
| Điều hướng | 4 | C/test: màn riêng, không thay tab bar |
| Nhất quán thị giác | 4 | R: dùng token, component và hoạ tiết nguồn |
| Wording và bản dịch | 4 | R: vi/en đủ bốn biến thể |
| Trạng thái và độ tin cậy | 4 | C/test: loading/error tách khỏi chưa có người; ảnh mất quyền về hoạ tiết |
| Tiếp cận và thích nghi | 3 | R/C: chữ 200%, header tăng chiều cao; chưa thử VoiceOver/thiết bị |
| Bản sắc sản phẩm | 4 | R: hình nền theo buổi, ngôn ngữ chăm bé |
| Sự cần thiết của nội dung | 4 | R/C: bỏ điều khiển sắp xếp trạng thái, lựa chọn hình nền tách màn |

Các vấn đề đã xử lý: dải tối cứng bên trái ảnh gây lệch tông (R, Medium/P2/L1, foundations); trạng thái trông bé bị lẫn trong danh sách có thể sắp xếp (C/test, Medium/P2/L2, patterns); lỗi tải có thể bị hiểu nhầm là chưa ai nhận trông bé (C/test, Medium/P1/L1, components). Không còn phát hiện chặn trong phạm vi đã kiểm tra.

Chưa đánh giá: thiết bị thật, VoiceOver/TalkBack, mọi ảnh người dùng có thể chọn, ảnh dọc/ngang cực đoan, tên bé cực dài, và sinh nhật bằng golden riêng. Chưa cài bản này lên điện thoại. Gradient có nền che phía chữ để giữ độ đọc; cần kiểm tra thực tế thêm với ảnh riêng của gia đình.
