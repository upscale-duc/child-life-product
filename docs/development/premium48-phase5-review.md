# Premium 48 · Phase 5 · Bản review dev

Chủ sản phẩm cho phép phase 5 ngày 20/10/2026, yêu cầu nhạc/asset mới và tên bé tiếng Anh.
Phạm vi đúng **C09/C10/V09/V10: hai thiệp, hai video**; giữ tên nhóm và logo như cũ.
PDF trang 17–18, 49–52 là brief, không phải lệnh tự mở phase khác. Dừng sau phase 5.

| ID  | Tên VI / EN                                   | Đầu vào | Hình ảnh                                                     |
| --- | --------------------------------------------- | ------- | ------------------------------------------------------------ |
| C09 | Những món đồ đã chật / The Things You Outgrew | 3 ảnh   | Hero bé, hai ảnh chi tiết, nhãn vải và đường chỉ             |
| C10 | Nụ cười muốn giữ / A Smile to Keep            | 1 ảnh   | Ảnh cười lớn, cung nắng sau viền, ngày tùy chọn              |
| V09 | Những món đồ đã chật / The Things You Outgrew | 5 ảnh   | Nhãn vải, chỉ nối ảnh, khung cặp bé/món đồ, hộp ký ức        |
| V10 | Nụ cười muốn giữ / A Smile to Keep            | 3 ảnh   | Mở tĩnh, tia nắng 18 frame, cặp phản ứng/nụ cười, reprise rõ |

Nhóm C09/V09 **Lớn từng ngày / Growing Every Day**; C10/V10 **Lần đầu / Little Firsts**.
IDs `card_premium48_09`, `card_premium48_10`, `video_premium48_09`, `video_premium48_10`.
Composition `PremiumOutgrownKeepsake`, `PremiumSmileToKeep`. Video 35 giây/1050 frame,
30 fps, poster frame 990. Tám MP4/poster và tám PNG/JPEG, VI/EN × 4:5/9:16 compose riêng.

## Copy, dữ liệu và chuyển động

- C09/V09 có `outgrownConfirmed`, mặc định chưa xác nhận. Headline/title đổi sang
  **Món đồ muốn giữ / A Keepsake to Keep**; toàn bộ lời kể không khẳng định đồ đã chật,
  từng vừa bé hoặc là kỷ vật từ những ngày đầu khi chưa được xác nhận.
- `itemName` tùy chọn; thiếu dùng “Món đồ bé xíu / A tiny keepsake” và tiêu đề trung tính.
  `storedDate` tùy chọn, không suy từ ngày upload hay EXIF. Không biết ngày thì bỏ nhãn
  ngày và không khẳng định hành động đã cất đồ trong lời kết thiệp.
- C10/V10 không khẳng định lần đầu. `momentDate` không biết thì thay cả câu kết, bỏ nhãn
  ngày. `reactionConfirmed` chỉ dùng lời “Mọi ánh nhìn…” khi chủ ảnh xác nhận; nếu ảnh
  thứ ba là ảnh cận an toàn thì dùng câu ngắm nụ cười trung tính.
- V09 beat map `[[0],[1],[2],[3,0],[4]]`. V10 `[[0],[1],[2,1],[1],[1]]`: chỉ ba ảnh đầu
  vào, trở lại ảnh cười theo kịch bản. Không tự lặp để bù thiếu tư liệu.
- Cảnh mở V10 tĩnh, tia nắng ở ngoài ảnh mở 18 frame khi ảnh cười xuất hiện; không
  animate môi. V09 mask nhãn vải và nét chỉ nằm ở mép. Reduced motion bỏ các motion
  graphic, giữ thời gian đọc và crossfade 12 frame trong 1050 frame.
- Tên demo **Noah** (C09/V09), **Lily** (C10/V10) giữ giống nhau trong cả hai locale.
  Tên riêng của người dùng vẫn lấy từ hồ sơ/trường nhập, không tự đổi hoặc dịch tên.

## Art, ảnh và nhạc mới

- **20 SVG gốc**: mười `p48-wardrobe-*` (móc áo, nhãn vải, chỉ nối, viền may, hộp/nắp hộp,
  vải gấp, nút áo, tab ngày, divider), mười `p48-smile-*` (cung nắng, khung ảnh, nét cong,
  quạt tia, vòng tĩnh, giấy caption, ngoặc phản ứng, tab ngày, hạt giấy, tia kết).
- Palette cotton/denim/ochre và vanilla/coral/plum; text luôn tách khỏi SVG. WebP đóng
  băng bằng hash trong catalog và job; grain nền dùng lại đúng vai trò texture.
- Figma Personal Duckie: [Phase 5 · Original assets](https://www.figma.com/design/8xApPL1XnwD4n1bpr0dPhq?node-id=22-3).
  Page `22:2`, board `22:3`, 20 asset, **87 vector, 0 image paint, 0 text tràn**. Đã xem
  screenshot. Các page phase trước và file V1 không bị sửa.
- **8 ảnh mới**, khác URL/hash với 45 ảnh trước. V09 năm ảnh quần áo/sinh hoạt; V10
  ba ảnh picnic cùng bộ của Helena Lopes. C09 dùng ảnh 3/0/2 để mặt bé hiện rõ; C10 ảnh 6.
  Source/tác giả/license trong `design/sample-photos/premium48-phase5-licence.json`.
- Stock chỉ minh họa; tên demo không phải danh tính thật. Demo không khẳng định món đồ
  là cùng một món qua các ảnh, đã chật hoặc đã cất; để trống ngày và không khẳng định
  phản ứng người thân. Credit/link nguồn có trong gallery.
- Hai bản nhạc gốc tổng hợp mới, không sample hay soundfont ngoài:
  **Sợi chỉ ký ức / Threads to Remember**, nylon guitar 70 BPM;
  **Nắng trong nụ cười / Sunshine in Your Smile**, ukulele/piano 92 BPM, glockenspiel một
  lần ở cảnh nụ cười. Có thể đổi nhạc hoặc tắt nhạc. Manifest nhạc trong publisher.

## QA và dev

Gallery `artifacts/premium48-phase5/index.html`, 20 SVG zip, credits tám ảnh và hai M4A.
PNG 2400×3000 / 2160×3840, MP4 1080×1350 / 1080×1920.

- Contracts phase 1–5: 103 test đạt; gồm nhánh xác nhận/không xác nhận, ngày chưa biết,
  field giả, mapping reprise và parity VI/EN/Dart.
- Renderer 28 test và backend 15 integration test đạt trên Firestore emulator.
- Flutter 74 test liên quan đạt, gồm thao tác xác nhận đồ đã chật cập nhật preview, crop
  các slot, chọn locale, font thật và xuất tám PNG bằng renderer Flutter. Analyze sạch.
- Portal 11 test đạt. Portal deploy từ worktree riêng, giữ sort newest; player có hai composition mới.

## Triển khai và kiểm tra file thực tế

- Functions `staffKeepsakes`, `staffKeepsakesDraft`, `staffKeepsakesAct`,
  `requestMemoryStory`, `onKeepsakeJobWritten` cập nhật thành công trên child-life-dev.
- Portal https://child-life-dev-admin.web.app và player
  https://child-life-dev-keepsake.web.app đã deploy. Bundle public khớp SHA-256 build;
  `artifacts/premium48-phase5/hosting-qa.json`.
- Cloud Build `8e55fb86-258d-4455-ac91-548c7747660b` SUCCESS. Image
  `renderer:premium48-phase5-20261020`; revision `keepsake-renderer-00012-8n2`, 100%
  traffic, giữ service private và cấu hình/IAM cũ.
- Catalog **ks_p48_phase5_1792512235607**: thêm đúng bốn template, giữ 48 template cũ,
  nhạc cũ, Premium access `everyone` và draft staff. Catalog tổng 52 có cả legacy;
  bộ Premium 48 mới hoàn thành 20 mẫu qua năm phase.
- Tám MP4 đủ 1050 frame, 35 giây video, H.264 4:2:0, AAC stereo 48 kHz; không frame đen.
  V09 **−16.08 LUFS / −5.44 dBTP**; V10 **−16.35 LUFS / −6.72 dBTP**.
  `audio-black-qa.json`, `video-qa.json`, `photo-qa.json` trong gallery.
- Public **26/26 video** có MP4/poster VI/EN tải được, gồm hai video phase 5;
  `artifacts/premium48-phase5/public-coverage.json`.
- Hai job thật qua request core → private renderer → lưu Kỷ niệm đều **completed/filed**:
  V09 VI/9:16 có nhạc, xác nhận đã chật và có ngày cất; V10 EN/4:5 tắt nhạc + reduced
  motion, có ngày ghi nhận. Tên Noah/Lily giữ đúng locale.
- Hai file tải từ server đều 1050 frame, 35 giây video, đúng kích thước; V09 có một
  track audio, V10 không có track audio. Đã xem frame kết với field ngày có dữ liệu,
  không tràn chữ. Báo cáo/file `artifacts/premium48-phase5/dev-smoke/`.
- Đã dọn sạch document và file upload/generated của gia đình test sau smoke. Không
  tạo Auth account, push token hay gửi thông báo tới người dùng thật.
- App đang cài từ phase 4 đọc template từ catalog; phase 5 không cần thay parser/editor
  mobile. Đã kiểm tra bằng Flutter test; không coi đó là nghiệm thu thao tác tay thiết bị.

## Giới hạn dùng thử

Chỉ dev, không production. Đầu vào video hiện là ảnh; clip/voiceover/ducking chưa có.
Thiệp có preview chuyển động 4 giây trong app, xuất PNG/JPEG tĩnh. Chưa nghiệm thu bản
in, thao tác tay Android hoặc mọi trạng thái Light/Night. Chủ sản phẩm nghe và review
nhạc tổng hợp trước khi cho phép phase tiếp theo.
