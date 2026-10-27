# Living Header — Figma review, 27/10/2026

Đã sửa trực tiếp section `1187:15786` trong file Child Life. Phạm vi là thiết kế Figma; không sửa Flutter, backend hay deploy.

## Kết quả

- Bỏ nút bút đổi nền khỏi 10 biến thể hero. Hàng **Cài đặt giao diện** nằm cuối danh sách Hôm nay, trước khoảng an toàn thanh điều hướng.
- HH04 thay sheet cũ bằng màn riêng: preview có thể chỉnh sửa, chọn Hoạ tiết / Ảnh bé, chọn ảnh từ Kỷ niệm, Áp dụng. HH05 và HH09 thể hiện hai trạng thái ảnh; HH08 chọn ảnh; HH10 là kết quả đã áp dụng.
- Prototype nối entry → lựa chọn → preview → áp dụng; mở cài đặt theo nền hiện tại. Quay lại rời bản đang xem thử. Các nút bên trong preview chỉ minh hoạ.
- Trạng thái trông bé có ba biến thể: chưa ai nhận, người khác đang trông, bạn đang trông. Ví dụ Ba có giờ nhận ca và chi tiết HH07. Dùng avatar chữ khi chưa có ảnh người chăm; không dùng ảnh em bé làm ảnh Ba.

## Nguồn và tái sử dụng

- Code: `features/appearance/appearance_screen.dart`, `features/care/care_duty.dart`, `features/today/today_screen.dart`, và ARB tiếng Việt. Ca trông là trạng thái nhận ca chủ động; không suy đoán từ nhật ký. Chỉ tự kết thúc ca của mình.
- Không có Code Connect trong repo. Đã kiểm tra các thư viện Figma và tìm Settings row / Icon/image; không có kết quả phù hợp. Tái sử dụng component hero, button, status bar, icon và ảnh trong chính file.
- Giữ Be Vietnam Pro, text/effect styles hiện có, các biến màu Light / Night care và Size. Không tạo bộ token hay thư viện mới.

## Kiểm chứng

- Render mới trên Figma: entry cuối list, preview hoạ tiết và ảnh, chọn ảnh, ba trạng thái trông bé, chi tiết ca, Night care.
- Audit: không có liên kết trỏ tới node không tồn tại; text của ba màn cài đặt không vượt khung cha; cả 10 nút đổi nền cũ đã ẩn.
- Hàng cài đặt không bị dock che. Vùng chạm entry 76pt; chip hiện trên Today 44pt. Component chính trạng thái đang trông 60pt.
- Đây là kiểm chứng Figma. Chưa chạy app/goldens, screen reader, tiếng Anh hoặc text scale 200% cho thiết kế mới.

## Trước khi triển khai

- Giữ giả định thiết kế gốc: hình nền theo từng bé, cả nhà cùng thấy. Quyền ai được đổi nền và các mốc tuổi của ngày đặc biệt vẫn cần chốt; không thay đổi chính sách trong lần sửa này.
- Prototype mô phỏng điều hướng/chọn ảnh. Nhận/kết thúc ca, liên kết bàn giao và công tắc ngày đặc biệt chưa mô phỏng ghi dữ liệu.
- Chưa có tính năng đổi icon ứng dụng trong phạm vi này.

Node IDs và ảnh kiểm chứng: `assets/2026-10-27-living-header/`.
