# Premium 48 · Phase 2 · Bản review dev

Ngày 20/10/2026: chủ sản phẩm cho phép phase 2, yêu cầu nhiều asset hơn để tránh nhàm chán,
và hỏi khả năng vẽ bằng Figma hoặc tự vẽ. Phạm vi vẫn C03, C04, V03, V04: 2 thiệp + 2 video.

## Bộ vector đầu tiên

Đã vẽ 20 SVG gốc, chia hai bộ theo art direction PDF. Các layer dùng path, shape và màu;
không dùng clipart tải ngoài hoặc chữ VI/EN nằm chết trong hình. Số 01 là hình vector.

| Bộ | Asset | Vai trò |
|---|---|---|
| C03/V03 · Đưa con về nhà | Nhà giấy, chìa khóa, đường chấm, hai cánh cửa tách rời, khung cửa vòm, thẻ hành trình, phong bì, chậu cây, mái nhà ôm ảnh | Chuyến về nhà; cửa mở ở lề; ảnh kết nằm trong hình nhà |
| C04/V04 · Một tháng làm quen | Washi xé, washi ô kẻ, góc giấy gập, tab tuần, số 01, nét bút chì, góc giữ ảnh, túi kỷ niệm, dải giấy, đường khâu | Scrapbook; ảnh đặt dần lên trang; số 01 dành cho kết |

- Nguồn SVG: `design/keepsake-art/p48-home-*.svg`, `p48-scrap-*.svg`.
- Manifest: `design/keepsake-art/premium48-phase2-manifest.json`.
- Script tái tạo: `pnpm --filter child-life-scripts exec tsx src/draw-premium48-phase2.ts`.
- Bảng xem: `artifacts/premium48-phase2/assets.html`; kiểm tra cả 20 SVG bằng Sharp đã đạt.
- Mỗi cảnh chọn asset theo chức năng, tránh đặt cả bộ trang trí lên mọi ảnh. Viền/asset cửa
  giữ vùng ảnh trung tâm trong suốt, không thực hiện chuyển động trên mặt bé.

## Figma

Chủ sản phẩm đã chọn **Personal Duckie — Duc N.'s team**. Đã tạo file riêng:
[Child Life · Premium 48 · Phase 2 Assets](https://www.figma.com/design/8xApPL1XnwD4n1bpr0dPhq?node-id=2-2).

Đã nhập đủ 20 SVG bằng `createNodeFromSvg`, giữ thành vector có thể chỉnh sửa. Bảng asset
chia hai nhóm, có palette và ghi chú công dụng; chữ dùng font Lora / Be Vietnam Pro / Inter.
Kiểm tra thực tế: **118 vector, 0 image paint**, đủ 20 asset, nhãn không tràn ô. Screenshot
đã xem tại `artifacts/premium48-phase2/figma-assets.png` (board 2000×2811).

Mapping nguồn SVG ↔ node Figma ở `design/keepsake-art/premium48-phase2-figma.json`.
Script chuẩn bị import: `scripts/src/prepare-premium48-figma.ts` (không tự ghi Figma;
chặn import lặp khi board đã tồn tại). File V1 được giữ read-only theo CLAUDE.md.

## Tiêu chí cho bốn template tiếp theo

- C03: 2 ảnh như hai cửa sổ; C04: 3 ảnh theo nhịp thời gian, dải giấy câu kết.
- V03/V04: 5 ảnh, 5 cảnh, 35 giây/1050 frame. Phân biệt motion đường đi/cửa giấy và
  scrapbook/ảnh đặt lên trang; giữ safe area, logo theo quyết định chủ sản phẩm.
- Không có ảnh hành trình: câu chuyện không tự nhận có chuyến đi. Không có ảnh ngày sinh:
  mở bằng ảnh sớm nhất người dùng chọn, không tự khẳng định ngày chụp.
- Cả phone và portal phải có MP4 và ảnh bìa VI/EN riêng. Đầu ra 4:5/9:16, text fitting,
  crop từng ảnh/cảnh và nhạc cần thử lại với bố cục mới.
- Editor đã được mở rộng để quản lý riêng từng ảnh của C03/C04: chọn ô ảnh, lấy từ thiết bị
  hoặc Kỷ niệm, pan/zoom từng ô, không lặp ảnh để bù slot trống. Viền chọn chỉ hiện trong
  editor; không xuất vào PNG/JPEG. Thiệp preview 4 giây cho ảnh vào theo thứ tự.

## Bốn mẫu triển khai

| ID PDF | ID catalog | Tư liệu | Đặc điểm |
|---|---|---|---|
| C03 | `card_premium48_03` | 2 ảnh | Hai cửa sổ, nhà giấy/chìa khóa/đường chấm; ngày về nhà tùy chọn |
| C04 | `card_premium48_04` | 3 ảnh | Scrapbook, washi riêng cho hai ảnh đầu, chân dung thứ ba và số 01 |
| V03 | `video_premium48_03` | 5 ảnh, 5 cảnh | Thẻ hành trình, đường nối ảnh, cửa giấy ở lề, ảnh kết trong hình ngôi nhà |
| V04 | `video_premium48_04` | 5 ảnh, 5 cảnh | Collage tăng dần, ảnh cũ trở lại theo mapping khai báo `[[0],[1,0],[2,1],[3,2,1],[4]]` |

Hai video có composition riêng, 35 giây/1050 frame, crossfade 12 frame trong duration;
giữ logo corner/endCard. Personal preview và server dùng cùng composition, copy/crop/tỷ lệ
được đóng băng trong job. Asset server lấy bằng tên WebP có hash; không phụ thuộc SVG đang
thay đổi trong thư viện. Clip-path cửa vòm/mái nhà khớp viền ở cả 4:5 và 9:16.

Chưa xác nhận có ảnh hành trình thì V03 mở bằng câu trung tính và cảnh 2 là “Một ngày đáng nhớ”.
Chưa xác nhận ảnh đầu được chụp ngày sinh thì V04 dùng “Những ngày đầu bên con”. Mọi câu
có thể sửa theo locale; không suy đoán ngày chụp từ thời điểm upload.

## Ảnh và nhạc demo mới

Theo yêu cầu bổ sung của chủ sản phẩm ngày 20/10: **10 ảnh mới**, hai bộ riêng, không dùng
lại 18 ảnh demo trong catalog cũ. Đã đối chiếu URL nguồn và SHA-256 của file; đủ 10 ảnh
khác nhau và không trùng file cũ. C03/V03 dùng cảnh mẹ và bé trong nhà, góc phòng;
C04/V04 dùng chân dung sơ sinh, tay bé và người chăm.

Nguồn từng ảnh, tác giả, Pexels License/CC0 và ghi nhận sử dụng demo nằm ở
`design/sample-photos/premium48-phase2-licence.json`; gallery credits ở
`artifacts/premium48-phase2/photo-credits.html`. Ảnh minh họa không khẳng định cùng một
bé/gia đình hoặc là diễn tiến thời gian thật. Ảnh không lưu vào repository.

Hai score gốc tổng hợp: “Đường về nhà” (nylon-style plucks 78 BPM, chuông gỗ ở kết) và
“Từng chút một” (acoustic-style plucks + piano mềm 76 BPM, thêm lớp từ cảnh 4), không dùng
sample/nhạc bên ngoài. Mục tiêu mix −16 LUFS, true peak ≤ −1 dBTP; đổi hoặc tắt nhạc được.

## Bản review và kiểm tra

- Gallery: `artifacts/premium48-phase2/index.html`, đổi VI/EN và 4:5/9:16; 8 PNG/JPEG thiệp
  và 8 MP4 video. PNG: 2400×3000 hoặc 2160×3840; MP4: 1080×1350 hoặc 1080×1920.
- Contracts: 41 test của phase 1/2 đạt. Renderer: 26 test đạt. Backend: 15 integration test
  job đạt trên Firestore emulator. Portal: 10 test đạt, gồm chọn MP4/ảnh bìa theo locale.
- Flutter: 81 test chức năng liên quan và 2 test render/đối chiếu copy đạt. Đã tải font thật,
  xuất thiệp bằng đúng Flutter renderer, kiểm tra cả bốn thiệp phase 1/2 trong VI/EN × hai tỷ lệ.
  `flutter analyze` không lỗi; bản iPhone debug build thành công.
- Media QA: đủ 8 MP4 H.264 4:2:0, 1050 frame/30 fps, AAC stereo 48 kHz; báo cáo trong
  `media-qa.json`. Nhạc và black-frame QA ở `audio-black-qa.json`.
- Giữ lại template cũ, preview VI/EN cũ, nhạc, quyền Premium và draft staff; publisher chỉ
  thêm/đổi đúng bốn ID, atomic compare-and-set. Snapshot trước publish trong artifacts.

## Triển khai dev và lượt xuất thật

Hoàn tất ngày 20/10/2026, chỉ ở `child-life-dev`:

- Catalog `ks_p48_phase2_1792496120046`: thêm đúng C03/C04/V03/V04, giữ 36 mẫu cũ;
  quyền Premium vẫn `everyone`. Snapshot và kết quả ở `catalog-before.json`, `published.json`.
- Portal: https://child-life-dev-admin.web.app; player: https://child-life-dev-keepsake.web.app.
  Functions staff/catalog/request/job và renderer đã cập nhật. Cloud Run revision
  `keepsake-renderer-00009-57k`, image `renderer:premium48-phase2-approved-20261020`.
- Kiểm tra công khai MP4 và poster VI/EN: **20/20 video** toàn catalog đạt;
  báo cáo `artifacts/premium48-phase2/public-coverage.json`.
- Hai job thật qua request core, renderer riêng và trigger lưu Kỷ niệm đều `completed`:
  V03 VI/9:16 có nhạc (1080×1920), V04 EN/4:5 tắt nhạc + reduced motion (1080×1350).
  Cả hai đủ 1050 frame; bản tắt nhạc không có audio track. File tải xuống và báo cáo ở
  `artifacts/premium48-phase2/dev-smoke/`.
- Storage trả lỗi 500 tạm thời khi dọn cuối smoke; đã thử lại và xác nhận không còn
  document hoặc file của gia đình thử. Script cleanup được thêm retry từng file.
- Mix cuối: V03 −16.12 LUFS / −5.72 dBTP; V04 −15.89 LUFS / −5.07 dBTP.
  Không phát hiện đoạn đen ở hai video.
- Bản iOS dev debug mới đã build, cài và mở thành công trên iPhone 14 Pro Max
  (`devicectl` xác nhận bundle `dev.hsba.app`). Lần đầu máy khóa; lần thử lại lúc 18:49
  đã mở được. Chưa ghi nhận nghiệm thu thao tác tay. Editor khóa các nút đổi ảnh/ngày/
  câu chữ/nhạc trong lúc xuất để tránh thay đổi nội dung giữa chừng.
- Lượt kiểm tra cuối sau khóa nút: `flutter analyze` không lỗi, 4 test editor đạt.

Mỗi phase sau cần chọn bộ ảnh demo mới và đối chiếu nguồn/hash với catalog đã có;
không tiếp tục dùng lại bộ ảnh cũ cho tất cả template.

## Giới hạn bản dùng thử

Đầu vào video hiện là ảnh; clip thay slot và voiceover/ducking chưa có. Thiệp xuất PNG/JPEG
tĩnh, chưa xuất motion-card MP4. Chưa QA bản in vật lý hoặc nghiệm thu thao tác end-to-end
trên Android. Nhạc cần chủ sản phẩm nghe và đánh giá cùng chuyển động. Chỉ triển khai dev,
không tự bắt đầu phase 3 trước review của chủ sản phẩm.
