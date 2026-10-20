# Premium 48 · Phase 4 · Bản review dev

Chủ sản phẩm cho phép triển khai phase tiếp theo ngày 20/10/2026, yêu cầu asset,
ảnh demo, thumbnail và nhạc mới. Phạm vi đúng **C07/C08/V07/V08: 2 thiệp + 2 video**.
Nguồn PDF trang 15–16, 45–48; quyết định trong phiên giữ tên nhóm và logo như cũ.
Không tự mở phase 5 hoặc production.

## Bốn mẫu

| ID | Tên | Tư liệu | Bố cục / chuyển động |
|---|---|---|---|
| C07 | Trang tháng của con / Your Monthly Chapter | 3 ảnh | Hero + hai ảnh nhỏ, tab số tháng, ba dòng ghi nhớ |
| C08 | Ngày ấy, bây giờ / Then & Now | 2 ảnh | Hai khung bằng nhau, hai nhãn ngày, khoảng ngày khi biết cả hai ngày |
| V07 | Trang tháng của con / Your Monthly Chapter | 5 ảnh | Số tháng matte mở, ảnh chuyển từ lưới sang hero, kết đủ năm ảnh trên trang tháng |
| V08 | Ngày ấy, bây giờ / Then & Now | 2 ảnh | Match frame bằng khung, push-in 2%, timeline 1.5 giây, wipe giấy; không morph |

Catalog IDs `card_premium48_07`, `card_premium48_08`, `video_premium48_07`,
`video_premium48_08`; composition `PremiumMonthlyChapter`, `PremiumThenNow`.
Nhóm **Lớn từng ngày / Growing Every Day**. Video 35 giây/1050 frame/30 fps, năm cảnh
210 frame, crossfade 12 frame nằm trong duration; poster frame 990. VI/EN × 4:5/9:16
compose riêng; giữ logo như các phase trước.

## Dữ liệu và chỉnh sửa

- C07/V07 yêu cầu chọn tháng **01–12** bằng dropdown; không suy từ ngày upload.
  Server từ chối 0, 13, số thập phân hoặc giá trị giả. Số tháng chuẩn hóa hai chữ số.
- Thiếu `discovery` thay toàn câu bằng “Thêm những điều mới mỗi ngày / Something new,
  every day”; thiếu `memoryLine` bỏ dòng tương ứng. Không có điểm thành tích.
- C08/V08 yêu cầu đúng hai ảnh được chọn. Có cả hai ngày ISO hợp lệ, ngày sau không
  trước ngày đầu thì tính số ngày UTC; xử lý cả 0 ngày, 1 ngày, ngày nhuận và DST.
  Có 1 ngày tiếng Anh dùng `day`, các số khác `days`. Thiếu một ngày thì chỉ dùng
  “Ngày ấy / Then”, “Bây giờ / Now”, không tính thời gian. Ngày đảo ngược bị chặn.
- `elapsedDays` và `elapsedUnit` là dữ liệu dẫn xuất từ `dateRange`; không nhận như
  trường nhập và không cho override để giả khoảng ngày. Không suy ngày từ EXIF/upload.
- V08 beat map **`[[0],[0],[0,1],[1],[0,1]]`**, chỉ hai input; crop cảnh cận thứ hai
  độc lập với cảnh đầu. Ảnh phụ khi ghép dùng crop của ảnh tương ứng, không tự đoán mặt.
- V07 beat map **`[[0],[1,0],[2],[3,1],[4,0,1,2,3]]`**: reprise khai báo rõ, cho tối đa
  năm slot trong một beat để kết đủ trang. Thiếu tư liệu không tự lặp để bù.
- Reduced motion dừng matte, zoom, shared-position, mở gáy và wipe; giữ nhịp đọc/crossfade.
  Chữ dài có preflight và thông báo trước xuất, không cắt tên âm thầm.

## Asset, ảnh và nhạc mới

- **20 SVG gốc mới**, mười motif `p48-chapter-*` và mười `p48-compare-*`; không ghi đè
  asset phase 1–3. Tab tháng/index rail, khung hero/ảnh phụ, gáy, divider, caption strip,
  crop marks, folio và masthead; timeline, hai anchor, góc giấy, wipe, matched frame,
  date tag, nét nối, ngoặc đôi và mép giấy. Số tháng/ngày là text riêng.
- Manifest `design/keepsake-art/premium48-phase4-manifest.json`; generator
  `scripts/src/draw-premium48-phase4.ts`. WebP có hash đóng băng trong catalog/job;
  grain chung được dùng lại đúng vai trò texture nền.
- Figma Personal Duckie: [Phase 4 · Original assets](https://www.figma.com/design/8xApPL1XnwD4n1bpr0dPhq?node-id=16-3).
  Page riêng, 20 asset chỉnh sửa được, **65 vector, 0 image paint, 0 text tràn ô**.
  Mapping `premium48-phase4-figma.json`, screenshot đã xem. File V1 giữ read-only.
- **7 ảnh mới**, không trùng URL/hash với 38 ảnh demo trước: năm ảnh cho V07 và cặp
  ảnh riêng cho V08. C07 dùng ảnh 0/2/4; C08 dùng 5/6. Manifest có nguồn/tác giả/license
  ở `design/sample-photos/premium48-phase4-licence.json`. Đã xem ảnh và crop.
  Demo C08/V08 để trống ngày, không khẳng định khoảng thời gian thật từ ảnh stock;
  gallery có credits và không khẳng định các ảnh là diễn tiến của cùng gia đình.
- Nhạc mới tự tổng hợp, không sample ngoài: **Trang tháng / Monthly Pages**, piano/guitar
  88 BPM; **Giữa hai khoảnh khắc / Between Two Moments**, piano arpeggio 72 BPM với dây
  mềm từ khi ảnh sau xuất hiện. Có thể đổi hoặc tắt nhạc.
- Đo bản cuối: V07 **−16.03 LUFS / −5.96 dBTP**; V08 **−15.50 LUFS / −6.08 dBTP**.
  Đủ tám MP4 H.264 4:2:0, AAC stereo 48 kHz, 1050 frame, không đoạn đen.

## Bản review và QA

Gallery `artifacts/premium48-phase4/index.html`: tám PNG/JPEG thiệp, tám MP4 và poster,
đủ hai ngôn ngữ × hai tỷ lệ. PNG 2400×3000 / 2160×3840, MP4 1080×1350 / 1080×1920.
Có bảng 20 asset, SVG zip, Figma và credits bảy ảnh. Báo cáo `photo-qa.json`,
`video-qa.json`, `media-qa.json`, `audio-black-qa.json` cùng thư mục.

- Contracts phase 1–4: **82 test đạt**, gồm tháng hợp lệ, ngày thiếu/đảo/ngày nhuận/DST,
  interval dẫn xuất, chống giả giá trị và mapping hai ảnh/năm ảnh.
- Renderer **27 test đạt**, backend job **15 integration test đạt** trên Firestore emulator.
- Flutter cuối: **88 test liên quan đạt**, gồm chọn tháng trong editor, parity copy/ngày
  UTC, cả tám thiệp VI/EN × hai tỷ lệ với font thật, dữ liệu trống/ngày đầy đủ, tên dài,
  slot độc lập, preview và chọn locale. Tám PNG xuất bằng đúng renderer Flutter.
- Portal **11 test đạt**; typecheck renderer/scripts, ESLint phần thay đổi đạt.
  `flutter analyze` không lỗi; bản iOS dev debug build thành công.

## Triển khai dev

- Functions `staffKeepsakes`, `staffKeepsakesDraft`, `staffKeepsakesAct`, `requestMemoryStory`,
  `onKeepsakeJobWritten` cập nhật thành công.
- Portal https://child-life-dev-admin.web.app và player https://child-life-dev-keepsake.web.app
  đã deploy, giữ sort “Mới thêm trước”, preview MP4 và poster theo locale.
- Cloud Build **`cb27fa58-160c-4efa-9135-e7a48a667989`** thành công. Image
  `renderer:premium48-phase4-20261020`; revision **`keepsake-renderer-00011-vjv`**,
  100% traffic, giữ service private và cấu hình cũ.
- Bản iOS dev debug build và cài thành công lên iPhone 14 Pro Max; `devicectl` xác nhận
  bundle `dev.hsba.app`; đã mở app thành công lúc 21:44. Chưa ghi nhận nghiệm thu
  thao tác tay trên thiết bị.

- Catalog **`ks_p48_phase4_1792507380200`** đã xuất bản: thêm đúng bốn ID, giữ 44 mẫu
  trước, nhạc cũ, Premium access `everyone` và draft staff. Tổng catalog 48 template gồm
  legacy; riêng bộ Premium 48 mới hoàn thành 16 mẫu qua phase 1–4, không phải đủ bộ 48.
- Portal/player public khớp hash build, player có cả hai composition mới;
  báo cáo `artifacts/premium48-phase4/hosting-qa.json`.

- Public **24/24 video** có MP4/poster VI/EN tải được; báo cáo
  `artifacts/premium48-phase4/public-coverage.json`.

- Hai job thật qua request core → private renderer → lưu Kỷ niệm đều **completed/filed**:
  V07 VI/9:16 có nhạc, V08 EN/4:5 tắt nhạc + reduced motion. V08 dùng hai ảnh và ngày
  01/07–01/10/2026 (92 ngày) của gia đình thử; khác demo public để trống ngày.
- Hai file tải xuống đủ 1050 frame và đúng kích thước; bản tắt nhạc không có audio track.
  Báo cáo/file ở `artifacts/premium48-phase4/dev-smoke/`. Đã dọn sạch toàn bộ document
  và file upload/generated của gia đình thử sau smoke.

## Giới hạn dùng thử

Chỉ dev. Video hiện nhận ảnh; thay bằng clip, voiceover/ducking chưa có. Thiệp xem
chuyển động 4 giây trong app nhưng xuất PNG/JPEG tĩnh. Nhạc tự tổng hợp cần chủ sản phẩm
nghe và đánh giá. Chưa nghiệm thu bản in, Android thao tác tay hoặc mọi trạng thái
Light/Night. Chỉ chuyển phase 5 sau khi chủ sản phẩm review và cho phép.
