# Home thao tác nhanh — triển khai mobile

## Kết quả

Triển khai frame [1294:17376](https://www.figma.com/design/sJLG1fAXKDnDr9YI6Yx8ex/Child-Life?node-id=1294-17376), theo các điều chỉnh của chủ sản phẩm. Home giữ tab bar, Lumi, cache ảnh và các quyền hiện có. Sáu loại thẻ dùng giao diện mới khi được bật trong danh sách theo dõi; không tự bật lại loại mà gia đình đã ẩn. Shadow Light vẫn dùng `cl.shadows.tile`; Night care giữ palette hiện tại.

Người dùng chính là ba mẹ/người chăm đang muốn biết lần chăm gần nhất và ghi nhanh. Phân loại **REFINE theo thiết kế đã được chủ sản phẩm chọn**: giữ dashboard hai cột, đích đến và mô hình dữ liệu; thay nội dung thẻ, nhóm section và khoảng cách. Không mở lại lựa chọn thiết kế A/B đã chốt trên Figma.

## Thay đổi

| Thành phần | Xử lý | Lý do |
|---|---|---|
| Header | Hạ chiều cao tối thiểu; nhóm điều khiển, lời chào, trạng thái theo nội dung | Bỏ khoảng trống đẩy nhật ký xuống |
| Lời chào | Tối đa 3 dòng, tên dài có ellipsis; toàn văn vẫn có trong cây semantics | Giữ giới hạn chiều cao và tránh chạm trạng thái chăm bé |
| Thẻ chăm sóc | Icon gốc 28 pt trên nền tròn 36 pt; thêm các nút nhanh | Nhận diện hoạt động và chọn ngay giá trị thường dùng |
| Metadata | Giữ giá trị, thời điểm, tác giả, chờ đồng bộ và thông tin đo | Giảm kích cỡ trình bày nhưng không làm mất trạng thái quan trọng |
| Tiêu đề và nội dung | Cùng một nhóm; khoảng cách 8 pt; các section cách 16 pt | Gắn đúng tiêu đề với nội dung, khoảng cách đồng đều |
| Section dẫn đầu | Không cộng thêm 16 pt trên nhóm Nhịp nếu nó đứng đầu | Header đã có khoảng kết thúc; tránh khoảng trống kép |
| Gợi ý ảnh | Sau nhóm chăm sóc; vẫn hiển thị khi nhóm chăm sóc bị ẩn | Ưu tiên thao tác chăm bé, không làm mất gợi ý |
| Tuỳ chỉnh | Chuyển lối vào ở đầu xuống cuối; giữ cả tuỳ chỉnh nội dung và giao diện | Không lặp nút quản lý ở phía trên |
| Chữ lớn | Một cột khi text scale > 1.3, thẻ và nút tăng chiều cao theo chữ | Tránh tách vụn tên thẻ và cắt nhãn nút |

## Logic nút

- Bú bình: 60 ml / 90 ml ghi đè giá trị gợi ý vào **form mới**, Khác mở form hiện tại. Chỉ ghi nhật ký khi bấm Lưu.
- Bú mẹ: Bên trái / Bên phải chọn sẵn bên trong form; vẫn có cả hai bên, nhập thời lượng và hẹn giờ trong form.
- Tã: Ướt / Bẩn / Cả hai chọn sẵn loại, vẫn cần Lưu.
- Ngủ: Bắt đầu ngủ dùng `openOrStartTimer`, giữ xử lý phiên cạnh tranh và lỗi hiện có; chạm phần thẻ vẫn mở lựa chọn ngủ đang diễn ra/nhập giấc đã xong.
- Khi timer ngủ/bú mẹ/hút sữa đang chạy, các lựa chọn tạo mới được thay bằng Xem phiên đang chạy.
- Hút sữa / Tăng trưởng mở form hiện tại; bấm giữ thẻ vẫn xem lần ghi gần nhất. Người thân chỉ xem không có nút ghi.

## Bằng chứng và review

Trước thay đổi, fresh render xác nhận 44 baseline header/Home hiện có khớp code. Hai ảnh so sánh giữ từ đúng cây làm việc trước khi sửa:

- [Có ảnh nền và gợi ý ảnh — trước/sau](assets/2026-10-27-home-vnext/review-photo_light_vi.png)
- [Lời chào tối, ẩn trạng thái — trước/sau](assets/2026-10-27-home-vnext/review-evening_no_banner_nightCare_vi.png)
- [Chữ 200% sau vòng sửa cuối](assets/2026-10-27-home-vnext/large-final.png)

Đã mở 7 trang đối chiếu cho 136 golden thay đổi, 3 trang gồm 60 biến thể header/Home và 8 ảnh chữ lớn sau khi đổi sang một cột. Rà trực tiếp các ảnh Home sáu thẻ ở 430 × 932, Light/Night, tiếng Việt/Anh; fixture cũ ở 375 × 812. Ảnh gợi ý dùng dữ liệu fixture, không ghi dữ liệu chăm bé thật.

Kiểm tra asset: tái sử dụng đúng sáu SVG `mini-bottle`, `mini-drop`, `mini-moon`, `mini-diaper`, `mini-pump`, `mini-ruler` từ `assets/illustrations`, tất cả có dữ liệu; slot 28 × 28 trong nền tròn 36 × 36. Ảnh nền là dữ liệu động và giữ cơ chế cache hiện tại; không dùng screenshot Figma làm asset.

Vòng tự phản biện phát hiện chữ 200% bị xuống dòng vụn trong hai cột. Đã đổi một cột, render lại và xem cả 8 biến thể. Preset không tự ghi, trạng thái tải/lỗi không biến thành ngày trống, và danh sách vẫn có khoảng cuộn cuối do shell cung cấp. Không phát hiện Blocker/High mới trong phạm vi bằng chứng render + test; chưa kiểm tra thao tác VoiceOver/TalkBack và hiệu năng thực tế.

Critical gates: **G1 pass** (nhãn và hành vi khớp test); **G2 chưa đánh giá đầy đủ** (nút và chữ 200% đã kiểm tra, thao tác screen reader chưa thử); **G3 pass** (preset không tự lưu, giữ Save/Undo); **G4 pass** trong role fixtures; **G5 không đánh giá** (không sửa nội dung AI/y tế); **G6 pass** trong render và feature tests. Kết luận trong phạm vi này: cải thiện nhiệm vụ chính; cần owner review trực tiếp trên máy, không suy rộng thành chứng nhận accessibility hoàn chỉnh.

| Chiều đánh giá | Điểm / 5 | Bằng chứng và giới hạn |
|---|---|---|
| Rõ nhiệm vụ | 4 | R: tiêu đề hoạt động và nút ghi trong thẻ |
| Thứ bậc thông tin | 4 | R: header gọn, chăm sóc trước gợi ý ảnh |
| Dễ quét và mật độ | 4 | R: số liệu ngắn, hàng thẻ đồng đều; metadata dài vẫn tăng chiều cao |
| Rõ tương tác | 4 | R+C: preset có nhãn, test xác nhận chọn đúng và không tự lưu |
| Điều hướng và luồng | 4 | C: giữ route/form, timer và nút tuỳ chỉnh cuối màn hình |
| Nhất quán thị giác | 4 | R+C: token hiện có, shadow Light, gap 16/8/12 |
| Nội dung và bản dịch | 4 | R+C: vi/en; nhãn mới qua ARB, English là bản kỹ thuật để owner review |
| Trạng thái và tin cậy | 4 | R+C: tải/lỗi/offline/read-only/timer được kiểm tra |
| Tiếp cận và thích ứng | 3 | R+C: mục tiêu chạm tối thiểu 44, chữ 200% một cột; screen reader chưa kiểm tra trên máy |
| Nhận diện Child Life | 4 | R: icon gốc, màu care và bóng hiện tại |
| Sự cần thiết của nội dung | 4 | R: bỏ art lớn cuối thẻ và lối tuỳ chỉnh trùng; giữ metadata cần thiết |

Không chấm các năng lực thiết bị chưa đo như độ mượt, khả năng thao tác một tay hay hiệu suất. Không có quyết định L3 còn chờ.

## Xác minh

- `flutter analyze`: không có vấn đề; kiểm tra lại phần thay đổi cuối.
- 163 feature tests qua: care, timer, preset mới, quyền chỉ xem, header, cache ảnh, tuỳ chỉnh, layout và Tự lưu.
- 436 golden tests trong các file ảnh hưởng qua sau cập nhật có chọn lọc; 8 biến thể chữ lớn qua sau vòng sửa cuối.
- Toàn bộ golden: **2.034 qua / 28 lệch có sẵn ngoài phạm vi**. Đối chiếu danh sách xác nhận cả 28 đã xuất hiện trước khi cập nhật baseline. Giữ nguyên baseline của `home_for_baby`, mốc phát triển và các trường hợp Premium/Kỷ niệm liên quan.
- `git diff --check` sạch trong các file liên quan.

Log kiểm tra: `/tmp/home-vnext-feature-final.log`, `/tmp/home-vnext-golden-final.log`, `/tmp/home-vnext-analyze-clean.log`. Danh sách ảnh: [manifest](assets/2026-10-27-home-vnext/manifest.json).

## Cài thiết bị

Bản dev release cuối, gồm sửa bố cục chữ lớn, đã cài và mở thành công qua wireless trên Duckie’s iPhone 14 Pro Max, UDID `00008120-001E28542E68C01E`. Lệnh `flutter run --flavor dev --release --no-resident --device-timeout 45 -d 00008120-001E28542E68C01E` kết thúc mã 0: Xcode build 47,8 giây, cài và mở 15,2 giây. Log `/tmp/duckie-home-vnext-final-install.log`. Không deploy backend hoặc phát hành store trong thay đổi này.
