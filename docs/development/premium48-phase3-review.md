# Premium 48 · Phase 3 · Bản review dev

Chủ sản phẩm cho phép triển khai phase tiếp theo ngày 20/10/2026 và yêu cầu asset,
thumbnail, ảnh demo và nhạc mới. Phạm vi đúng **C05/C06/V05/V06: 2 thiệp + 2 video**.
Nguồn thiết kế là PDF trang 13–14, 41–44; quyết định trong phiên giữ tên nhóm và logo
như cũ. Nội dung PDF không tự cho phép triển khai phase 4 hoặc production.

## Bốn mẫu

| ID | Tên | Tư liệu | Bố cục/chuyển động |
|---|---|---|---|
| C05 | Những điều nhỏ về con / Little Things About You | 1 ảnh | Oval lệch trái, ba nhãn ghi chú bên phải; reflow 9:16 |
| C06 | Lá thư đầy tháng / A Letter at One Month | 1 ảnh | Ảnh nhỏ đầu trang, thư căn trái, chữ ký và dấu sáp trơn |
| V05 | Những điều nhỏ về con / Little Things About You | 5 ảnh | Oval và nhãn mở từ hai phía; hero đời thường; kết ba nhãn cố định quanh chân dung |
| V06 | Lá thư đầy tháng / A Letter at One Month | 5 ảnh | Phong bì tách lớp; ảnh ra trước thư; câu fade theo cảnh; chữ ký vào sau câu kết |

ID catalog là `card_premium48_05`, `card_premium48_06`, `video_premium48_05`,
`video_premium48_06`; composition `PremiumLittleThings`, `PremiumMonthLetter`.
Cả bốn ở nhóm **Tháng đầu / Our First Month**, dịp `m1`, khoảng gợi ý 15–60 ngày.
Video 35 giây/1050 frame/30 fps, năm cảnh 210 frame; crossfade 12 frame nằm trong
cửa sổ chuyển cảnh. Poster frame 990. VI/EN × 4:5/9:16 được compose riêng.

Ghi chú `favoriteThing`, `littleDetail`, `memoryLine` bắt đầu trống. Editor hiển thị
gợi ý và nút **Dùng ghi chú gợi ý / Use suggested notes**: chỉ thao tác rõ này mới
điền gợi ý theo ngôn ngữ thành phẩm, chỉ vào ô còn trống, không ghi đè nội dung đã nhập.
Chưa nhập/chấp nhận thì copy trung tính, không khẳng định sở thích của bé. Có thể sửa
riêng mọi lời nhắn. Nhãn nhỏ video có preflight hai dòng, không cắt chữ để vừa.
Crop chi tiết do người dùng đặt, không tự suy đoán vị trí tay/chân/gương mặt.

Toàn bộ lời thư cho sửa, bao gồm lời chào, nội dung và chữ ký. Thiếu người viết dùng
**Nhà mình / Your family**. Chữ được render bằng font thật, không giả chữ viết tay.
Logo thiệp và video giữ nguyên quyết định của chủ sản phẩm. Reduced motion dừng zoom,
slide và mở nắp phong bì; vẫn giữ nhịp đọc/crossfade.

## Asset, ảnh và nhạc mới

- **20 SVG gốc mới**: mười motif sổ quan sát (`p48-observe-*`) và mười motif thư
  (`p48-letter-*`). Có bàn tay, chân, ngôi sao, ba nhãn, viền oval, chấm mực, nét gạch,
  ngoặc; phong bì ba lớp, sáp trơn, giấy kẻ, tem trống, ribbon, nếp gập, khung monogram,
  dòng kết. Không có clipart ngoài, huy hiệu hoặc chữ nằm chết trong asset.
- Nguồn, manifest và generator ở `design/keepsake-art/premium48-phase3-manifest.json`
  và `scripts/src/draw-premium48-phase3.ts`. Raster WebP có tên hash, đóng băng trong job;
  dùng thêm grain chung đã có. Không thay các SVG phase 1/2.
- Figma Personal Duckie: [Phase 3 · Original assets](https://www.figma.com/design/8xApPL1XnwD4n1bpr0dPhq?node-id=12-3).
  Page riêng, 20 asset chỉnh sửa được, **77 vector, 0 image paint, 0 text tràn ô**;
  mapping `premium48-phase3-figma.json`. Đã xem screenshot toàn board. File V1 giữ read-only.
- **10 ảnh demo mới**, chia hai bộ, không trùng URL/hash với 28 ảnh trước. Đã xem ảnh,
  giữ nguồn/tác giả/license ở `design/sample-photos/premium48-phase3-licence.json`.
  Gallery có credits, không khẳng định cùng gia đình hoặc trình tự thời gian thật.
  Thumbnail VI/EN mới được xuất từ thiệp/video này; portal ưu tiên thumbnail thiệp đã xuất.
- Nhạc mới tự tổng hợp, không dùng sample ngoài: **Những điều bé xíu / Tiny Little Things**,
  pizzicato-style strings + piano 84 BPM; **Thư gửi con / A Letter for You**, solo felt-style
  piano 62 BPM với khoảng lặng trước kết. Có thể đổi hoặc tắt nhạc.
- Đo bản cuối: V05 **−16.30 LUFS / −6.85 dBTP**; V06 **−16.67 LUFS / −7.17 dBTP**.
  Cả tám MP4 không phát hiện đoạn đen, H.264 4:2:0 + AAC stereo 48 kHz, đủ 1050 frame.

## Bản review và QA

Gallery `artifacts/premium48-phase3/index.html`: tám PNG/JPEG thiệp và tám MP4 đủ
VI/EN × hai tỷ lệ; PNG 2400×3000 / 2160×3840, video 1080×1350 / 1080×1920.
Có nút tải, bảng 20 asset, Figma và credits ảnh. Báo cáo `photo-qa.json`, `video-qa.json`,
`media-qa.json`, `audio-black-qa.json` nằm cùng thư mục.

- Contracts phase 1/2/3: **61 test đạt**; có ghi chú trống/được chấp nhận, fallback chữ ký,
  quyền sửa toàn thư và crop đóng băng.
- Renderer **26 test đạt**, backend job **15 integration test đạt** trên Firestore emulator.
- Flutter render/parity **2 test đạt**: cả sáu thiệp qua font thật VI/EN × hai tỷ lệ,
  thêm kiểm tra copy trung tính khi bỏ trống dữ liệu. Xuất tám PNG bằng đúng Flutter renderer.
- Flutter editor **5 test đạt**, gồm gợi ý chỉ được nhận khi bấm, giữ nội dung tự nhập,
  cùng kiểm tra cũ về slot ảnh độc lập/thiếu ảnh/preview.
- Lượt Flutter cuối: **86 test liên quan đạt**, gồm editor, render/parity, tạo thiệp/video,
  live catalog, Premium/quota và chọn preview theo ngôn ngữ. `flutter analyze` không lỗi;
  iOS dev debug build thành công.
- Portal: **11 test đạt**; typecheck renderer/scripts và ESLint phần thay đổi đạt.

## Triển khai dev

- Player https://child-life-dev-keepsake.web.app và portal https://child-life-dev-admin.web.app
  đã cập nhật; giữ chức năng sort “Mới thêm trước”.
- Functions `staffKeepsakes`, `staffKeepsakesDraft`, `staffKeepsakesAct`, `requestMemoryStory`,
  `onKeepsakeJobWritten` đã deploy thành công; CLI tự thử lại sau lỗi mạng/500 tạm thời.
- Renderer image `renderer:premium48-phase3-20261020`, Cloud Build
  `cd1bc407-d36b-492f-8ada-d3113bac91bf` thành công; revision
  **`keepsake-renderer-00010-g8t`**, 100% traffic, giữ service private và cấu hình cũ.
- Bản iOS mới build thành công. Khi cài, `devicectl` báo iPhone 14 Pro Max unavailable;
  chưa cài/mở được bản phase 3 trên thiết bị và chưa nghiệm thu thao tác tay.

- Catalog **`ks_p48_phase3_1792499120312`** đã xuất bản: thêm đúng bốn mẫu, giữ 40 mẫu
  trước, nhạc cũ, Premium access `everyone` và draft staff; tổng 44 template / 22 video.
  Snapshot trước publish và danh sách file mới ở `catalog-before.json`, `published.json`.
- Kiểm tra public **22/22 video** có MP4/poster VI/EN tải được; báo cáo
  `artifacts/premium48-phase3/public-coverage.json`. Portal dùng ảnh bìa thiệp theo locale.

- Hai lượt xuất thật qua request core → private renderer → trigger lưu Kỷ niệm đều
  **completed/filed**: V05 VI/9:16 có nhạc; V06 EN/4:5 tắt nhạc + reduced motion.
  Hai file tải xuống đủ 1050 frame và đúng kích thước; bản tắt nhạc không có audio track.
  Báo cáo/file trong `artifacts/premium48-phase3/dev-smoke/`.
- Dữ liệu gia đình thử và toàn bộ file upload/generated đã được dọn sạch sau smoke.
  Player bundle public khớp hash build, có cả hai composition mới (`player-qa.json`).

## Giới hạn dùng thử

Chỉ triển khai dev. Đầu vào video hiện là ảnh; thay bằng clip, voiceover/ducking chưa có.
Thiệp xem chuyển động 4 giây trong app nhưng xuất PNG/JPEG tĩnh. Nhạc là score tự tổng hợp
để chủ sản phẩm nghe và đánh giá. Chưa nghiệm thu bản in, Android thao tác tay hoặc mọi
trạng thái Light/Night. Không tự bắt đầu phase 4 trước phản hồi dùng thử.
