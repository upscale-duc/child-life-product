# Premium 48 · Phase 1 · Bản dùng thử

Ngày: 20/10/2026. Chủ sản phẩm chốt mục lục theo tên nhóm và logo như hiện tại.
Phase 1 gồm đúng C01, C02, V01, V02; chưa bắt đầu phase 2.

## Bốn mẫu

| ID PDF | ID catalog | Tên | Tư liệu |
|---|---|---|---|
| C01 | `card_premium48_01` | Ngày con đến | 1 ảnh |
| C02 | `card_premium48_02` | Lần đầu ôm con / Một cái ôm muốn nhớ | 1 ảnh |
| V01 | `video_premium48_01` | Ngày con đến | 5 ảnh, 5 cảnh, 35 giây |
| V02 | `video_premium48_02` | Lần đầu ôm con / Một cái ôm muốn nhớ | 4 ảnh, 5 cảnh, 35 giây; cảnh kết chủ động dùng lại ảnh cái ôm |

Nhóm: **Chào con / Hello, Little One**. Mỗi mẫu có copy VI/EN riêng. C02/V02 dùng câu
trung tính cho đến khi người dùng xác nhận “lần đầu”. Logo giữ corner/endCard của video
và brand layer của thiệp theo D-068 #10. Các mẫu cũ và quyền Premium giữ nguyên.

## Cách review

Mở `artifacts/premium48-phase1/index.html` để xem đủ bốn mẫu, đổi VI/EN và 4:5/9:16.
Trong app dev mới: Kỷ niệm → Câu chuyện → Thiệp cột mốc hoặc Video kỷ niệm → chọn
Ngày con đến / Lần đầu ôm con (★ Cao cấp, các mẫu mới ở đầu danh sách).
Với video, chọn đủ 5 hoặc 4 ảnh rồi tiếp tục tới editor mới.

Thử bằng ảnh riêng, tên dài, xóa ngày/giờ, thay người kể, đổi ngôn ngữ thành phẩm,
xác nhận/bỏ xác nhận lần đầu, sửa lời nhắn, đổi tỷ lệ và xem trước trước khi lưu.
Ở video, mỗi cảnh có căn ảnh, thu phóng và chọn giữ trọn ảnh/lấp đầy khung;
nhạc mặc định có thể đổi hoặc tắt. Ngôn ngữ app giữ nguyên khi đổi ngôn ngữ thành phẩm.

PNG/JPEG: thiệp 4:5 là 2400×3000; 9:16 là 2160×3840. Video 1080×1350 hoặc
1080×1920, H.264/yuv420p, 30 fps, 1050 frame; AAC stereo 48 kHz khi có nhạc.
Thiệp xem chuyển động 4 giây trong app; file PNG/JPEG là bản tĩnh đầy đủ.

## Phần đã làm

- Schema cá nhân hóa có kiểu dữ liệu, field nguồn, copy theo locale, fallback và giới hạn;
  thay token có kiểm tra. Không đưa mã thực thi vào JSON.
- Story beats tách khỏi slot ảnh. V02 dùng mapping `[0,1,2,3,2]`, không tự lặp ảnh để bù thiếu slot.
- Snapshot đóng băng copy, crop, tỷ lệ, reduced motion và artwork có tên theo hash cho job.
  Preview cá nhân và server dùng cùng composition.
- Thiệp reflow metadata khi thiếu ngày/giờ/nơi; text đo bằng font thật, giảm có giới hạn,
  chặn xuất khi không vừa thay vì cắt tên âm thầm.
- Editor riêng cho các template có metadata mới; các editor cũ giữ luồng hiện tại.
- 4 SVG gốc và 2 score gốc được tổng hợp cho bản thử; manifest nguồn/quyền đi kèm.
- Script publish dev thêm/đổi đúng 4 ID bằng atomic compare-and-set, bảo toàn mẫu cũ,
  track cũ, chính sách Premium và bản nháp của staff. Lưu snapshot trước publish trong artifacts.
- Portal có preview copy theo locale và phần chỉnh cấu hình cá nhân hóa có schema validation.

## Giới hạn cần đánh giá khi dùng thử

- Đầu vào video của phase 1 hiện là ảnh. Clip thay slot, voiceover/ducking và xuất motion-card MP4
  chưa được thêm; không có nút hoặc lời quảng cáo cho các đầu ra này trong bản thử.
- PNG có đúng kích thước yêu cầu, nhưng chưa làm QA bản in vật lý; chưa công bố print-ready.
- Nhạc là score gốc tổng hợp cho review, chưa phải bản thu nhạc cụ thương mại. Chủ sản phẩm
  cần nghe và đánh giá chất lượng cùng chuyển động.
- Sample photos lấy từ bộ CC0 đã được chủ sản phẩm chấp nhận ở phiên trước, dùng để minh họa
  thiết kế; không khẳng định các ảnh là cùng một bé/gia đình. Nguồn ở
  `design/sample-photos/licence.json` và `apps/renderer/preview-credits.md`.
- Chưa được chủ sản phẩm nghiệm thu. Không tự bắt đầu phase 2, không đổi giá/quota hay phát hành prod.

## Kiểm chứng

- Contracts: 21 test riêng phase 1 đạt; renderer: 24 test đạt; backend job: 13 test
  integration đạt trên Firestore emulator. Flutter: 81 test liên quan đạt, analyze không lỗi.
  Portal: 10 test đạt, gồm chọn MP4 và ảnh bìa theo ngôn ngữ.
- Đã render đủ 8 MP4 VI/EN × 4:5/9:16 của V01/V02, kiểm tra 1050 frame/30 fps;
  8 PNG thiệp xuất bằng Flutter với font thật. Gallery ở `artifacts/premium48-phase1/index.html`.
- Dev smoke thực tế: V01 VI 9:16 có nhạc và V02 EN 4:5 tắt nhạc/reduced motion đều
  xuất 35 giây, lưu thành công vào Kỷ niệm, giữ đúng format. Gia đình và media QA đã xóa
  trong `finally`; báo cáo ở `artifacts/premium48-phase1/dev-smoke/report.json`.
- Đã sửa `.gcloudignore` để đưa font/artwork của bundle vào container; Cloud Run dev
  revision `keepsake-renderer-00008-nnq` chạy thành công cả hai job trên.
- Functions liên quan, portal admin và player đã deploy **dev**. Bản app simulator đã build,
  cài và khởi chạy. Bản iPhone đã build và cài lên iPhone 14 Pro Max đang kết nối;
  `devicectl` xác nhận mở app thành công. Flutter launch qua wireless trả lỗi nên dùng
  công cụ thiết bị Xcode trực tiếp. Chưa nghiệm thu bằng thao tác end-to-end trên điện thoại thật.

## Preview tiếng Anh cho toàn bộ catalog

Theo yêu cầu bổ sung của chủ sản phẩm: tất cả **18 video đang có** cần MP4 tiếng Anh,
bao gồm 16 mẫu cũ và 2 mẫu phase 1. Đây là hoàn thiện ngôn ngữ của catalog hiện tại;
không thêm mẫu phase 2.

- `previews`/`thumbs` lưu asset riêng theo `vi`/`en`; phone và portal lấy đúng locale.
  Portal đổi URL và remount video khi đổi ngôn ngữ; upload preview cũng lưu đúng locale.
- Phone không phát MP4 Việt khi catalog có map locale nhưng thiếu bản Anh; lúc đó dùng
  composition với copy tiếng Anh. Hai mẫu mới còn có nút VI/EN ngay màn xem mẫu,
  và giữ lựa chọn khi mở editor.
- Đã render 16 MP4 Anh cho mẫu cũ bằng copy English và nhãn tuổi English. Gallery đủ
  18 mẫu ở `artifacts/keepsake-english/index.html`; QA codec/frame/copy trong `media-qa.json`.
  MP4 preview cũ xuất 720×1280; bản xuất cá nhân giữ độ phân giải theo renderer.
- Script `scripts/src/english-keepsake-previews.ts` có `--prepare`, `--publish`, `--verify`,
  chỉ chấp nhận `--project child-life-dev`. Publish kiểm tra version từng mẫu, lưu backup,
  atomically cập nhật public catalog và version cao nhất, bảo toàn draft staff và MP4 Việt.
  `--verify` kiểm tra URL công khai của MP4/ảnh bìa VI/EN sau publish.
- Đã publish catalog dev `ks_video_en_1792492830256`: 18/18 video có bản Anh riêng;
  snapshot và danh sách asset ở `artifacts/keepsake-english/published.json`.
- Đã kiểm tra công khai đủ 72 URL (MP4 và ảnh bìa × VI/EN × 18 mẫu) bằng HTTP Range;
  tất cả truy cập được. Chi tiết ở `artifacts/keepsake-english/public-coverage.json`.
