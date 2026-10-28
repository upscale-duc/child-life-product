# Premium — chuẩn bị giá trước khi chọn gói · 2026-10-28

Sửa lỗi cục bộ theo D-134; dùng `senior-ui-ux` và chính sách bằng chứng D-133. Giữ bố cục Premium và mức giá đã cấu hình. Người dùng cần vào màn chọn gói với giá đọc được, không gặp gói thiếu giá do một lần gọi API chậm.

## Nguyên nhân và thay đổi

C (code): `familyPlanV2Provider` trước đây tự hủy khi rời màn hình, gọi lại `getFamilyPlan` khi mở và trả null khi lỗi. `PaywallScreen` lấy giá trực tiếp từ kết quả đó, không preload hoặc cache giá.

- Home tải trước giá khi tính năng Premium v2 bật, không chặn nội dung Home.
- Giữ kết quả gói thành công trong bộ nhớ tối đa 10 phút, refresh khi đang được dùng. Phụ thuộc session để không giữ câu trả lời của tài khoản trước.
- Chỉ lưu hai giá tháng/năm vào thiết bị, tách theo tài khoản + bé + tiền tệ; hạn 24 giờ. Không lưu thêm quyền, số dư, lịch sử hoặc ghế chăm sóc. Dọn cache cùng local privacy guard khi đổi tài khoản/mất quyền.
- Giá đã lưu được dùng ngay trong lúc API tải lại/lỗi. Đồng hồ hết hạn vẫn chạy khi màn hình đang mở; cache quá hạn hoặc hỏng không được dùng. Phản hồi mới chủ động bỏ giá thắng cache cũ.
- App resume hoặc kết nối trở lại kích hoạt cập nhật. Mở Premium sau lần tải lỗi cũng thử lại.
- API có timeout 12 giây. Chưa có giá hợp lệ thì hiển thị trạng thái chuẩn bị giá hoặc lỗi + Thử lại trước màn chọn gói. Nút đóng vẫn hoạt động. Mọi route dùng PaywallScreen đều đi qua điều kiện này; người đã Premium/thành viên không quản lý vẫn thấy luồng riêng hiện có.
- Giá không được đoán hoặc lấy từ hằng số dự phòng. Real-store billing vẫn trì hoãn theo D-074; cache chỉ phục vụ hiển thị, không cấp quyền hoặc thay quyết định checkout.

## Review kết quả

KEEP bố cục lựa chọn gói, REFINE trạng thái chuẩn bị. Không cần A/B: lỗi nằm ở vòng đời dữ liệu, không có đánh đổi bố cục chưa giải quyết.

| Vấn đề | Evidence | Mức độ | Kết quả |
|---|---|---|---|
| Lần mạng lỗi khiến giá trống mỗi lần vào | C: provider, regression delayed/error fetch | High / P1 | Tải trước, giữ kết quả và cache giá. |
| Chọn gói trước khi biết giá | C: widget test chưa có cache; R: loading/retry renders | High / P1 | Chỉ hiện phần chọn gói khi có giá. |
| Cache có thể sai tài khoản/tiền tệ hoặc quá cũ | C: isolation, expiry, removal tests | High / P1 | Phân vùng, giới hạn tuổi, xóa khi config bỏ giá. |
| Nội dung lỗi nhắc lại tiêu đề | R: vòng review đầu | Low / P2 | Rút body còn “Kiểm tra kết nối rồi thử lại.” |

Gates trong phạm vi thay đổi: không phát hiện lỗi mới. Không tuyên bố đã xác minh mua hàng hoặc khả năng đọc màn hình bằng thiết bị thực.

## Bằng chứng

- Trước sửa: `golden_freshness.sh test/golden/premium_v2_golden_test.dart`: 124 Current.
- Sau sửa: 140 golden cases Premium v2 + chuẩn bị giá qua, bao gồm 16 case mới Light/Night × vi/en: cached, loading, retry, retry 200%. Cập nhật có chủ đích 4 baseline `paywall_price_unknown` của flow audit để phản ánh gate trước chọn gói.
- Visual inspection đại diện theo D-133: cached Night vi, loading Light vi, retry Light en, retry Night vi ở 200%. Copy lỗi được rút gọn rồi render/review lại các region bị ảnh hưởng. Những tổ hợp còn lại có kiểm tra tự động, không được coi là đã xem trực quan riêng từng ảnh.
- 63 feature/app tests qua: Premium v2, 8 cache/preparation regressions, account lifetime, root privacy guard, navigation. Có kiểm tra preload một request, cold read, chậm/lỗi có cache, retry không cache, config bỏ giá, tách tài khoản/bé/tiền tệ, corrupt/expired cache và hết hạn trong khi màn mở.
- `flutter analyze` các source/test thay đổi: không có vấn đề.
- Full golden suite: 2070 qua, 24 lỗi có từ trước ngoài phạm vi (storage_v2_member_full 4, Premium 8, keepsake 6, home_for_baby 4, milestone 2). Không cập nhật các baseline ngoài phạm vi này.
- `git diff --check`: qua.

Ảnh hiện tại:

- [Giá đã chuẩn bị](../../../apps/mobile/test/golden/goldens/premium_price/cached_nightCare_vi.png)
- [Lần đầu đang tải](../../../apps/mobile/test/golden/goldens/premium_price/loading_light_vi.png)
- [Thử lại](../../../apps/mobile/test/golden/goldens/premium_price/retry_light_en.png)
- [Thử lại ở chữ 200%](../../../apps/mobile/test/golden/goldens/premium_price/retry_large_nightCare_vi.png)

Giới hạn: lần cài đầu chưa có cache và đang mất mạng không thể cung cấp giá thật ngay lập tức; màn chọn gói chờ dữ liệu thay vì hiện giá đoán. Cache có thể phản ánh giá được tải trong 24 giờ qua; cập nhật mạng thành công thay thế nó. Chưa kiểm chứng mạng chậm thực trên thiết bị hoặc mua hàng Apple/Google; tests dùng API giả lập. Không thay backend hoặc mức giá bán.

Đã build và cài/khởi chạy bản dev release trên iPhone Duckie thành công (`flutter run --flavor dev --release --no-resident`, exit 0). Log: `/tmp/premium-prices-duckie-install.log`.
