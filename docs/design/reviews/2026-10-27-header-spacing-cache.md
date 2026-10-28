# Hôm nay — khoảng cách header và ảnh nền đã lưu · 2026-10-27

Giữ chiều cao và cách cắt của vùng ảnh; đưa trạng thái trông bé và toàn bộ nội dung theo sau lên tối đa 24 pt. Khi chữ lớn hoặc lời chào dài cần thêm chỗ, nội dung được phép cao lên thay vì chồng chữ. Ảnh nền đã chọn được lưu riêng trên máy, nạp và giải mã trước `runApp` khi có phiên đăng nhập và bản lưu hợp lệ. Người dùng không phải đợi API ảnh mới thấy nền đã lưu.

## Phạm vi và đánh giá

Dashboard Hôm nay; ba mẹ/người chăm sóc muốn thấy tình trạng bé và ghi nhanh. **REFINE, L1/L2**: thứ tự, các đích đến, quyền, cỡ chữ, lời chào, tab bar và nút ghi nhanh giữ nguyên. D-130 ghi nhận yêu cầu lưu ảnh. Figma không thay đổi.

| Nội dung | Phân loại | Xử lý |
|---|---|---|
| Bé đang chọn, thông báo, chế độ tối | Essential | Preserve |
| Lời chào | Contextual | Preserve vị trí và kích thước |
| Ảnh bé/họa tiết | Contextual | Preserve chiều cao, cách cắt và gradient |
| Trạng thái trông bé | Essential khi bật | Relocate lên tối đa 24 pt; giữ vùng bấm thực |
| Khoảng trống dưới lời chào | Redundant | Giảm bằng cách cho nội dung đi lên vùng nền cuối đã mờ |
| Gợi ý ảnh, nhịp hôm nay, các khối xếp hạng | Essential/contextual theo trạng thái | Đi lên cùng nhau; giữ thứ tự và tùy chỉnh |
| Xem trước ở Cài đặt giao diện | Contextual | Phản ánh vị trí trạng thái mới, khung preview giữ nguyên |

## Bằng chứng và kết quả

- Fresh render trước thay đổi: 24 header khớp baseline; 4 settings lệch do fixture dùng giờ thực. Đã cố định giờ cho settings để tránh đổi lời chào theo giờ chạy test.
- Bộ render mới: ảnh thật + gợi ý ảnh, ẩn trông bé, chữ 200%, lời chào tối ngắn + không gợi ý ảnh; vi/en × Light/Night care, tổng cộng 16 ảnh.
- Đã xem trước/sau cả 12 cặp có fixture đối chiếu, 4 ảnh trường hợp tối ngắn và toàn bộ 116 diff golden liên quan (10 trang contact sheet). Ảnh bên phải giữ nguyên pixel ở vùng không bị nội dung đi lên phủ qua; test đo kích thước artwork và vị trí lời chào giữ nguyên ở 100%/200% và bật/ẩn trạng thái.
- Cửa sổ nhỏ 375×812: mặc định trạng thái và nội dung theo sau lên 24 pt; khi ẩn trạng thái và lời chào ba dòng, dịch ít hơn để đủ chỗ. 200% tự tăng chiều cao nên không ép dịch khi không còn khoảng trống.
- Hit testing: bấm được dòng trông bé và phần đầu nội dung nằm trên nền cuối header, không dùng phép dịch hình ảnh để giả vị trí nút.

Ảnh đối chiếu: [có trạng thái và gợi ý ảnh](assets/2026-10-27-header-spacing/review_photo.png), [ẩn trạng thái](assets/2026-10-27-header-spacing/review_hidden.png), [chữ 200%](assets/2026-10-27-header-spacing/review_large.png), [lời chào tối ngắn](assets/2026-10-27-header-spacing/review_evening.png). Các diff: `assets/2026-10-27-header-spacing/golden-diffs-{1..10}.png`.

## Ảnh nền khi mở lại

- Một nguồn ảnh đang áp dụng cho từng tài khoản/bé; metadata nhỏ trong preferences, ảnh ở `media-v2/<uid>/babies_<baby>_header_<hash>`, cùng vùng xóa cache hiện tại.
- Nạp bản lưu và giải mã vào Flutter image cache trước `runApp` cho bé đã chọn. Nếu chưa có bé được ghi nhớ, nạp các bản lưu của đúng tài khoản. Phiên đăng nhập khôi phục muộn thì nạp bất đồng bộ; không chặn app bằng mạng.
- Trong lúc metadata đang tải hoặc mất mạng, dùng ảnh đã lưu phù hợp lựa chọn. Khi biết ảnh bị xóa/không còn được xem hoặc avatar đổi phiên bản, bỏ ảnh cũ. Hủy preview giữ nguyên cache của lựa chọn đã áp dụng. Apply hoàn tất các thao tác ghi cache đã bắt đầu.
- Đọc cache luôn kiểm tra tài khoản, bé, quyền và hạn truy cập. Xóa dữ liệu tương ứng khi đổi tài khoản/mất quyền; bản ghi đang tải không được quay lại sau khi bị xóa.
- Giữ chính sách hiện tại: chỉ Cùng nuôi có cache ảnh bé trên đĩa. Các vai trò khác tiếp tục tải qua quyền hiện có. Không lưu signed URL, không đưa ảnh vào preferences.

## Kiểm tra

- 42 kiểm tra chức năng qua: header, cache, care duty, Adaptive Today, local privacy, privacy guard và account scope. Có kiểm tra khởi động lại từ đĩa đã giải mã, cache lỗi, trạng thái metadata chưa về, ảnh bị gỡ và preview → Apply.
- Analyze các nguồn/test liên quan: không có vấn đề.
- Toàn bộ golden sau thay đổi: **2.018 qua / 28 lệch có sẵn**, cùng 28 trường hợp ngoài phạm vi như lượt chạy trước. Không cập nhật 28 baseline này (`home_for_baby`, giá Premium chưa biết, dung lượng thành viên đầy, Beta/lỗi Premium, một số Kỷ niệm và mốc phát triển). 116 baseline hiện có được cập nhật cho vị trí header và phần nền phía sau các sheet; thêm 16 golden Hôm nay.
- G1 ý nghĩa, G2 vùng bấm bị tác động, G3 giữ lựa chọn, G4 kiểm tra cache theo quyền, G5 không đổi lời khuyên, G6 bố cục: không thấy lỗi mới trong phạm vi đã kiểm tra. Không coi đây là kiểm thử toàn bộ chức năng hay toàn bộ khả năng tiếp cận của app.

## Tự đánh giá và giới hạn

Đã cải thiện khoảng cách mà vẫn giữ không gian cho ảnh. Không thu nhỏ chữ, bỏ chức năng, đổi thứ tự Adaptive hay thêm phần giải thích. Khi chữ 200% thì ưu tiên đủ chỗ đọc thay vì giữ mức dịch 24 pt. Các hàng, nút và khoảng cách còn đọc được trong các render đã xem.

Chưa đo thời gian khởi động trên máy thật hoặc kiểm tra VoiceOver, Android và tên bé rất dài trong lượt này. Cache có thể bị hệ điều hành dọn: lần đầu sau nâng cấp/chọn ảnh, hoặc sau khi cache bị dọn, vẫn cần tải ảnh thành công một lần. Việc mở lại offline/giải mã sẵn được xác nhận bằng test, chưa thao tác đổi mạng trên dữ liệu thật của Duckie.

Đã cài và mở bản dev release trên Duckie’s iPhone 14 Pro Max qua kết nối wireless. `flutter run --flavor dev --release --no-resident -d 00008120-001E28542E68C01E` kết thúc mã 0; Xcode build 50,6 giây, cài và mở 15,4 giây. Log: `/tmp/duckie-header-spacing-cache-install.log`. Không thay đổi dữ liệu chăm bé thật để kiểm thử.
