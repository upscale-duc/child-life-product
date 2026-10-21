# Premium 48 · Phase 6 · Bản review dev

Chủ sản phẩm cho phép phase tiếp theo ngày **21/10/2026**, yêu cầu assets, ảnh demo và
nhạc mới. Phạm vi đúng **C11/C12/V11/V12: hai thiệp và hai video**. Tên demo tiếng Anh
**Oliver / Emma**, giữ tên nhóm và logo như các phase trước. Dừng sau phase 6.
Nguồn PDF trang 19–20, 53–56 là brief; không phải lệnh tự triển khai phase 7.

| ID  | Tên VI / EN                                    | Đầu vào | Hình ảnh / chuyển động                                                |
| --- | ---------------------------------------------- | ------- | --------------------------------------------------------------------- |
| C11 | Con làm được rồi / You Did It                  | 3 ảnh   | Ba khung theo đường đi chấm, nhãn mốc, một ngôi sao giấy              |
| C12 | Một thế giới để khám phá / A World to Discover | 2 ảnh   | Cửa sổ tròn, kính ngắm nhỏ, ba chấm nối, lá giấy ở biên               |
| V11 | Con làm được rồi / You Did It                  | 5 ảnh   | Ba dấu bước, đường chấm dừng ở mốc chính, một ngôi sao mở nhẹ         |
| V12 | Một thế giới để khám phá / A World to Discover | 5 ảnh   | Khung tròn mở rộng, lá chuyển động tại lề, dissolve giữa các góc nhìn |

Nhóm cả bốn mẫu **Lần đầu / Little Firsts**. IDs `card_premium48_11`,
`card_premium48_12`, `video_premium48_11`, `video_premium48_12`. Composition
`PremiumYouDidIt`, `PremiumWorldToDiscover`. Video 35 giây/1050 frame, 30 fps,
poster frame 990; năm cảnh 210 frame, crossfade 12 frame trong duration.
VI/EN × 4:5/9:16 compose riêng. Logo corner/endcard và brand layer giữ nguyên hệ thống.

## Dữ liệu, lời kể và thao tác

- C11/V11 **bắt buộc `milestoneName`** do chủ ảnh nhập (tối đa 48 ký tự), không suy
  từ tuổi, hồ sơ hay metadata. Gợi ý chỉ được điền khi bấm dùng gợi ý; lúc mở editor
  trường này để trống. Server từ chối mốc trống, kể cả chuỗi toàn khoảng trắng.
- `momentPhotoConfirmed` mặc định false. Không có ảnh đúng khoảnh khắc đạt mốc thì
  title, headline và các cảnh đầu đổi sang lời nhớ lại, không khẳng định đây là lần
  thử hoặc khoảnh khắc đạt mốc thật. Mốc vẫn hiện trên nhãn riêng.
- `momentDate` không biết thì bỏ dòng ngày và thay toàn câu có ngày. Không suy ngày
  từ EXIF, ngày upload hoặc thời điểm mở editor; không tự khẳng định lần đầu.
- C12/V12 thiếu `discovery` thì dùng toàn câu “một điều mới / something new”. Thiếu
  ảnh vật khám phá cho phép chọn góc khác của bé; `objectPhotoConfirmed` false bỏ
  lời khẳng định đang chạm vật hoặc có âm thanh/màu sắc cụ thể.
- V12 `companionConfirmed` mặc định false, chỉ dùng “Mình cùng con…” khi chủ ảnh
  xác nhận ảnh cảnh 4 có người đi cùng. Không thêm vật, người hoặc chuyển động mặt
  bằng AI. Tên thật của người dùng giữ từ hồ sơ/trường nhập, không tự dịch sang Anh.
- Hai video dùng đúng năm input độc lập, map **`[[0],[1],[2],[3],[4]]`**, không xoay
  vòng để bù ảnh thiếu. Crop mỗi cảnh độc lập, có chọn cover/contain.
- Reduced motion dừng path reveal, trượt ảnh 12px, bung sao, leaf drift và circle
  reveal; vẫn giữ thời gian đọc và crossfade. Font preflight chặn chữ tràn trước xuất.
- Portal xem được C11 có field bắt buộc bằng gợi ý mẫu từ catalog, không lỗi resolve;
  lựa chọn mốc của người dùng vẫn là thao tác trong editor.

## Bộ hình và âm thanh mới

- **20 SVG gốc**: mười `p48-milestone-*` (đường chấm, sao giấy, góc ảnh, nhãn mốc,
  ba dấu bước, tab ngày, nếp giấy và nét kết); mười `p48-discover-*` (cửa sổ tròn,
  lá đôi, nhánh lá, kính ngắm, ba chấm, tab sổ, khung rộng, đường nhìn, hạt giấy và loop).
- Palette ivory/teal/mango và mist/leaf/earth. Chữ/tên/ngày tách khỏi vector. WebP
  được đóng băng bằng hash trong catalog/job; grain nền chung được dùng lại.
- Figma Personal Duckie: [Phase 6 · Original assets](https://www.figma.com/design/8xApPL1XnwD4n1bpr0dPhq?node-id=32-3).
  Page `32:2`, board `32:3`, **61 vector, 0 image paint, 0 text tràn**; đã xem screenshot.
  Giữ nguyên các page trước và file V1 read-only. Manifest/ID trong
  `design/keepsake-art/premium48-phase6-manifest.json` và `premium48-phase6-figma.json`.
- **10 ảnh mới**, năm ảnh bước đi/kỷ niệm ngoài trời của Tatiana Syrikova cho V11,
  năm ảnh bé chú ý đồ chơi của Polesie Toys cho V12. C11 dùng ảnh 0/1/3; C12 ảnh 7/6.
  Đã xem ảnh và crop. Tác giả, source, license tại
  `design/sample-photos/premium48-phase6-licence.json`; gallery có credits/link nguồn.
  Stock chỉ minh họa, không khẳng định cùng gia đình hoặc quá trình đạt mốc thật.
  Demo không xác nhận ảnh mốc thật, vật/companion và để trống ngày.
- **Từng bước của con / Your Little Steps** — marimba/guitar **96 BPM**, tăng nhẹ ở
  cảnh 3; **Qua đôi mắt con / Through Your Eyes** — guitar harmonics/gõ gỗ **82 BPM**.
  Hai bản tự tổng hợp mới, không sample/soundfont/bản thu ngoài; có đổi hoặc tắt nhạc.

## Bản review và QA

Gallery `artifacts/premium48-phase6/index.html`, tám PNG/JPEG, tám MP4/poster, hai M4A,
20 SVG zip, credits mười ảnh. PNG 2400×3000 / 2160×3840; video 1080×1350 / 1080×1920.

- Contracts phases 1–6 **126 test đạt**, gồm mốc bắt buộc, ảnh mốc thật/nhớ lại,
  discovery/object/companion fallback, ngày không rõ và parity TS/Dart.
- Renderer **32 test đạt**, backend job **15 integration test đạt** trên Firestore emulator.
- Flutter **75 test liên quan đạt**, gồm mốc không tự điền, nhập mốc, xác nhận ảnh
  cập nhật preview, chọn locale, crop và font thật. Tám PNG bằng đúng renderer Flutter.
- Portal **15 test đạt**, gồm inline preview C11 có trường bắt buộc trong VI/EN và
  preview locale. Analyze Flutter, typecheck renderer/scripts/portal và lint phần mới đạt.

## Triển khai dev

- Functions `staffKeepsakes`, `staffKeepsakesDraft`, `staffKeepsakesAct`,
  `requestMemoryStory`, `onKeepsakeJobWritten` đã cập nhật thành công trên child-life-dev.
- Portal https://child-life-dev-admin.web.app và player
  https://child-life-dev-keepsake.web.app đã deploy; SHA-256 bundle public khớp build,
  cả hai có phase 6. Receipt `artifacts/premium48-phase6/hosting-qa.json`.
- Cloud Build **289e972b-4ffa-46a4-a43b-08aff17c282f SUCCESS**, image
  `renderer:premium48-phase6-20261021`. Revision **keepsake-renderer-00013-tdg**,
  100% traffic; giữ service private, cấu hình và IAM cũ.
- Tám bản review đủ 1050 frame và không frame đen; V11 **−15.84 LUFS /
  −4.68 dBTP**, V12 **−16.13 LUFS / −6.67 dBTP**. Đã chỉnh và xem lại crop demo V12
  để đầu/mặt nằm gọn trong cửa sổ tròn. Đã đo lại toàn bộ tám file trước publish.

- Catalog **ks_p48_phase6_1792594347088** đã xuất bản: thêm đúng bốn mẫu, giữ 52
  template trước, nhạc cũ, Premium access `everyone` và draft staff. Tổng catalog 56
  gồm legacy; riêng bộ Premium 48 hoàn thành 24 mẫu qua sáu phase.
- Public **28/28 video** có MP4/poster VI/EN tải được, gồm V11/V12;
  `artifacts/premium48-phase6/public-coverage.json`.
- Gallery và các file đã xuất bản đủ locale/định dạng, 20 asset, 10 ảnh mới và hai nhạc
  riêng; receipt `artifacts/premium48-phase6/handoff-qa.json`.
- Hai lượt xuất thật trên server dev đã hoàn thành và lưu vào kỷ niệm: V11 tiếng
  Việt 9:16 có nhạc (68,6 giây xử lý), V12 tiếng Anh 4:5 tắt nhạc và reduced motion
  (49,2 giây xử lý). Cả hai đủ 1050 frame / 35 giây, đúng kích thước; V12 không có
  audio track. Đã xem frame kết với tên Oliver/Emma và ngày nhập 20/09/2026.
  Receipt, MP4 và ảnh kiểm tra tại `artifacts/premium48-phase6/dev-smoke/`;
  `report.json` xác nhận completed/filed, `media-qa.json` xác nhận file tải về.
  Family thử và toàn bộ ảnh/video trên storage thử đã được dọn sạch.

## Giới hạn dùng thử

Chỉ dev. Video nhận ảnh; thay bằng clip, voiceover/ducking chưa có. Thiệp preview
chuyển động 4 giây trong app nhưng xuất PNG/JPEG tĩnh. Chưa nghiệm thu bản in, thao
tác tay Android/iPhone hoặc mọi trạng thái Light/Night. Nhạc tổng hợp cần chủ sản phẩm
nghe và review. Không tự mở phase tiếp theo.
