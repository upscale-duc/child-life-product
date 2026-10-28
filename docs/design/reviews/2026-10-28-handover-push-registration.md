# Bàn giao báo sai trạng thái thông báo

## Chẩn đoán

Hai ảnh của owner cho thấy quyền thông báo iOS và công tắc thông báo của Child Life Dev đều bật. Kiểm tra chỉ đọc trên dev xác nhận lần bàn giao gần nhất có `handovers = true`, nhưng tài khoản nhận có **0 device endpoint**. Không lưu tên, UID, token hoặc nội dung bàn giao vào báo cáo/log chẩn đoán.

`sendHandover` trả `pushable = hasDevice && handovers`. Vì vậy `false` không có nghĩa người nhận đã tắt quyền thông báo. Câu cũ `aiSentNoPush` suy diễn sai nguyên nhân.

Code còn chặn đăng ký thiết bị khi `session.isAnonymous`, dù R-030 cho phép thành viên được mời dùng “Vào ngay”. Đây là một đường tái hiện xác định trong code/test; chưa xác minh được loại tài khoản thật của người nhận qua Auth. Ngoài ra, listener token chỉ được gắn sau lần `getToken()` thành công, nên token đến muộn có thể bị bỏ lỡ tới lần resume tiếp theo.

## Bản sửa

- Đăng ký endpoint cho mọi phiên đã xác thực có membership đang hoạt động, bao gồm “Vào ngay”. Giữ nguyên bộ lọc tài khoản chính thức của engagement và phạm vi heartbeat hoạt động; không tăng quyền đọc dữ liệu hoặc tự xin quyền OS.
- Nghe token refresh trước khi chờ APNs/FCM; retry khi quyền vừa bật trong app hoặc app trở lại foreground. Thử lại bước ghi device row nếu lần đầu thất bại.
- Chặn kết quả đăng ký cũ ghi về tài khoản trước khi account/language thay đổi.
- Thay copy vi/en bằng xác nhận bàn giao đã lưu trong app, thông báo trên máy có thể chưa đến và lựa chọn chia sẻ thêm; không khẳng định người nhận tắt thông báo.
- Render 200% phát hiện chữ nằm ngoài góc pill của toast dài. Dùng `ClRadius.card` tại cỡ chữ lớn, giữ nguyên pill ở cỡ mặc định. Không đổi cách gửi, dedupe hoặc quyền bàn giao.

## Review và kiểm tra

Phân loại KEEP cho luồng bàn giao, REFINE cho copy và hình dạng toast ở chữ lớn. G1 (đúng ý nghĩa nghiệp vụ) được xác minh bằng code và integration test; G2 kiểm tra render/nút chia sẻ, chưa thử screen reader; G3/G4 giữ luồng lưu/quyền hiện có; G5 không đánh giá (không đổi AI/y tế); G6 kiểm tra qua fakes/emulator, push thực tế chưa xác minh.

- 84 mobile tests qua: đăng ký cho tài khoản tạm của các vai trò, bàn giao và cài đặt thông báo.
- 16 integration tests bàn giao qua trên Firestore emulator, gồm case bật handovers nhưng không có endpoint, sau đó thêm token thì `pushable` chuyển sang true với cùng sendId.
- 8 golden mới qua và đã mở: vi/en × Light/Night × 100%/200%. Cỡ mặc định chạy luồng gửi thật qua repository fake; 200% dùng toast probe vì trang Bàn giao hiện có overflow header độc lập với thay đổi này.
- Toàn bộ golden: **2.042 qua / 28 lệch có sẵn ngoài phạm vi**, không cập nhật các baseline đó.
- Analyze các file thay đổi sạch; `git diff --check` sạch.
- 29 core tests về widget/toast, bảo vệ dữ liệu trên máy và heartbeat qua.
- Golden: `apps/mobile/test/golden/goldens/handover_delivery/`.

Hạn chế: không chủ động gửi bàn giao hoặc push đến người khác để test. Cần app bản mới chạy trên máy nhận và xác nhận endpoint/token xuất hiện, sau đó owner thử lại luồng gửi. Đây là cập nhật mobile, không cần deploy Functions.

## Thiết bị

Bản dev đã cài lên iPad bằng `devicectl`; mở tự động bị iOS từ chối vì máy khóa. Đã nhờ owner mở khóa và mở Child Life Dev. Bản sửa đã cài và mở thành công trên Duckie: lệnh Flutter kết thúc mã 0, build 59,9 giây, cài/mở 19,6 giây (`/tmp/handover-push-duckie-install.log`). Endpoint người nhận vẫn chưa xuất hiện khi iPad chưa chạy app; không kết luận push thực tế đã được khôi phục.

Log: `/tmp/handover-push-tests.log`, `/tmp/handover-push-integration.log`, `/tmp/handover-push-goldens4.log`, `/tmp/handover-push-golden-suite.log`, `/tmp/handover-push-check-final.log`.
