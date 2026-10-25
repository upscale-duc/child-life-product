# Print Studio — luồng hiện hành, 25/10/2026

Nguồn: [Child Life · section 956:13899](https://www.figma.com/design/sJLG1fAXKDnDr9YI6Yx8ex/Child-Life?node-id=956-13899). Figma được đọc trực tiếp cả màn hình và prototype, không chỉnh sửa. Quyết định của chủ sản phẩm: **không cọc; nhận yêu cầu đặt hàng và liên hệ xác nhận, vận hành in/giao thủ công để thử nhu cầu**. Quyết định này thay thế cọc 50%.

## Luồng được triển khai lại

- Kỷ niệm → Kỷ vật PS03 → Chi tiết PS15 → Xem thiết kế PS11 → Tuỳ chọn PS14 → **một trang đặt hàng PS30N** → Thành công PS33 → Theo dõi PS34.
- PS30N gộp sản phẩm/số lượng, bản in đã duyệt, địa chỉ nhận, lựa chọn thanh toán, gói quà và tổng tiền. Không dùng tiến trình xác nhận → giao hàng → thanh toán cũ. Các màn PS30/31/32 cũ nằm trong nhóm “Đã thay thế — không dùng” của Figma.
- Địa chỉ lần đầu hoặc chỉnh sửa mở sheet, lưu xong trở về chính trang đặt hàng. Huỷ sheet không ghi địa chỉ mới. Ngoài Việt Nam chuyển sang phương án tải file.
- COD được chọn sẵn. Chuyển khoản là lựa chọn của khách để nhân sự liên hệ, không thu tiền trong app hoặc tạo mã QR khi chưa có thông tin tài khoản được cấu hình. Gói quà tính một lần trên đơn, độc lập với loại khung/hộp quà cao cấp.
- PS20 → PS21: xem spread, chọn trang, thư viện ảnh theo tháng, bộ lọc, kéo ảnh vào trang trái/phải, sửa ảnh/chữ/bố cục PS22 → PS24 → cùng PS30N. Xem toàn màn hình hỗ trợ dọc một trang, ngang hai trang, vuốt và ẩn/hiện điều khiển.
- Chi tiết sản phẩm có gallery góc nhìn/mặt sau/chân đỡ và phóng to. Chính sách mở thành trang riêng. Đánh giá hiển thị dữ liệu thật; không lấy đánh giá, số sao hoặc nội dung khách mẫu của Figma làm dữ liệu thương mại.

## Bố cục và file in

Màu, typography, kích thước cảnh 300 px, thẻ phong cách, nhóm chỉnh sửa từng khung, segments 42 px, radio/chất liệu và footer được đối chiếu với design context. SVG viền/chân đỡ lấy từ thiết kế; bóng SVG filter được raster hoá để Flutter hiển thị. Các ảnh mẫu Figma chỉ dùng trong test; ảnh sản phẩm trong ứng dụng lấy từ Kỷ niệm.

Bố cục `portrait/collage/text`, danh sách ảnh của từng trang và phụ đề được lưu trong bản nháp và snapshot đơn. Registry ảnh dùng chung; chỉnh ảnh của một trang thay slot riêng của trang đó. `pagePhotos` được serialize thành map theo chỉ số trang để Firestore không nhận nested arrays; contract vẫn đọc đầu vào mảng và chuẩn hoá. Khung thông tin không có ảnh vẫn xuất được. Renderer dựng PDF từ ảnh gốc với font/bố cục tương ứng, 300 DPI và bleed; không chụp screenshot ứng dụng làm file sản xuất.

## Vận hành thủ công

Trạng thái: `pendingConfirmation → confirmed → printing → shipped → delivered`, hoặc `cancelled`. Thành công nghĩa là **đã nhận yêu cầu**, chưa tự chuyển sang in. Nhân sự xác nhận tổng tiền, ngày nhận và cách thanh toán với khách; có thể ghi báo giá đã thống nhất. Portal hiện lựa chọn thanh toán, gói quà, thiệp, địa chỉ và PDF. Chỉ cho chuyển sang in khi file sản xuất sẵn sàng.

Request ID giữ nguyên khi retry; thao tác đang gửi chặn bấm lặp. Nhận đơn và dựng PDF là hai tác vụ độc lập, có lease/retry và xử lý file lỗi. Quyền ba mẹ, media cùng bé, vùng giao, hạn ngày nhận và catalog version được kiểm tra ở server. Ghi chú nhà in/liên hệ lưu riêng và audit, không đưa dữ liệu bé vào log hoặc analytics.

Môi trường dev `child-life-dev` đã tạo catalog thử nếu chưa có: bật nhận đơn, bốn loại sản phẩm, giá dự kiến, COD không cọc. Script chỉ tạo khi document chưa tồn tại, không ghi đè cấu hình sẵn có. Production chưa thay đổi.

## Bằng chứng đối chiếu

Ảnh so sánh đặt cạnh nhau, cùng chiều rộng 375 px, bỏ 40 px status bar của Figma (ứng dụng dùng status bar hệ điều hành):

- [PS11 xem thiết kế](../discovery/figma-extract/img/print-studio-2026-10-25/preview-comparison.png)
- [PS14 tuỳ chọn](../discovery/figma-extract/img/print-studio-2026-10-25/options-comparison.png)
- [PS30N đặt hàng](../discovery/figma-extract/img/print-studio-2026-10-25/checkout-comparison.png)
- [PS21 sách](../discovery/figma-extract/img/print-studio-2026-10-25/book-comparison.png)

Bản chụp dùng ảnh fixture Figma, có thể khác trạng thái trang/ảnh đang chọn và dữ liệu cá nhân hoá. Đây là bằng chứng để xem xét giao diện, không phải kết luận “pixel perfect”.

## Kiểm chứng và giới hạn

- Widget: luồng PS15 → PS11 → PS14 → PS30N → PS33 → theo dõi; nhập địa chỉ lần đầu; retry/bấm lặp; sách và xoay toàn màn hình; chính sách; serialization ảnh/trang. Golden lưu trong `apps/mobile/test/golden/goldens/print/current_*.png`.
- Renderer: các phong cách, khung thông tin không ảnh, trang sách/collage/chữ, PDF/bleed/300 DPI. Emulator: quyền, catalog, nhận đơn khi Storage lỗi, worker/retry, vận hành thủ công, gói quà/lựa chọn thanh toán, info-only export và rules.
- Smoke test thiết bị: `apps/mobile/integration_test/print_studio_dev_smoke_test.dart`, dùng phiên dev có sẵn, không tạo bé/ảnh hoặc gửi đơn thử vào dữ liệu gia đình.
- Chưa xác nhận toàn bộ E2E iOS + Android, bản in vật lý, tải ảnh/video đánh giá và làm mờ mặt. Không đánh dấu coverage Figma hoàn tất trước khi các điều kiện thiết bị thật được kiểm chứng.

Kiểm tra ngày 25/10: `flutter analyze` không có issue; 12 widget/flow test qua ở vi/en và Light/Night care; 510 backend test qua (1 test khác được skip); 10 test Print Studio/rules trên emulator qua. Chín Cloud Run service đã phục vụ revision mới, `latestCreatedRevisionName = latestReadyRevisionName`; bảy callable trả JSON `401 UNAUTHENTICATED` khi probe không đăng nhập, portal HTTP 200. Kiểm tra thiết bị và cài release được ghi bổ sung sau khi chạy thực tế.

Transition bổ sung theo yêu cầu chủ sản phẩm: prototype reactions dùng `SMART_ANIMATE / EASE_OUT / 300ms` giữa các bước và `350ms` cho chế độ xem sách; `get_motion_context` không có keyframe tracks. Các bước dùng chung route nay crossfade 300ms, sheet có animation khi mở/đóng, thẻ lựa chọn đổi viền/màu mềm, điều khiển sách fade và vùng sách đổi padding trong 350ms. Giảm chuyển động dùng fade 150ms. Chỉ một `PopScope` đăng ký trên route; màn đang rời đi không nhận chạm, focus hoặc semantics. Ba test motion kiểm tra frame trung gian khi đi tiếp/quay lại, Reduce Motion và việc gõ/chỉnh dữ liệu không khởi động lại chuyển cảnh. Tổng 15 widget/flow/motion test đã qua.

Kiểm tra cuối: 16 test widget/flow/motion qua, thêm ca lưu bản nháp mới khi chưa chỉnh sửa. Ảnh golden được repaint với bóng thật để đối chiếu, không dùng chế độ bỏ blur của Flutter test. Nút lưu chủ động ghi snapshot ngay cả khi thiết kế mới chưa có thay đổi.

Thiết bị thật: smoke test với phiên ba mẹ hiện có trên iPhone Duckie đã tới chi tiết → thiết kế → tuỳ chọn → checkout (COD mặc định), không gửi đơn. Nhánh sách chưa được xác nhận trọn vẹn trên thiết bị: lượt đầu bị kịch bản điều hướng dùng lại route, lượt chạy lại không khám phá được Dart VM Service. Đã điều chỉnh test để mở route mới và chờ fullscreen đóng thật sự; không ghi nhận lượt này là E2E thành công.
