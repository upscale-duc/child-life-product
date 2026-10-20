# Review bộ 48 template Premium — 20/10/2026

Trạng thái review ban đầu: **đã review tài liệu và đối chiếu mã nguồn**.

Cập nhật theo chủ sản phẩm sau review: **giữ mục lục theo tên nhóm, giữ logo như cũ và bắt đầu phase 1 (C01, C02, V01, V02)**. Các nhận xét về hai điểm này bên dưới là phát hiện tại thời điểm review, không còn là câu hỏi mở. Phase tiếp theo vẫn chờ chủ sản phẩm dùng thử và xác nhận.
Khung phase bên dưới là đề xuất để lập kế hoạch chi tiết, chưa phải lịch giao hàng.

Nguồn: `Child-Life-Premium-48-Templates-VI-EN.pdf`, Production edition 1.0,
20 October 2026, 80 trang, tại `/Users/duckie2910/Downloads/Child-Life-Premium-48-Templates-VI-EN.pdf`.
Số trang trong review là số trang PDF. Đã đọc nội dung cả 80 trang và xem sơ đồ ở
trang 9, 30, 34, 76; chưa có asset/render thành phẩm để đánh giá chất lượng thực tế.

## 1. Yêu cầu của chủ sản phẩm và phạm vi review

Yêu cầu trực tiếp trong phiên này:

- Review tài liệu **trước khi lên kế hoạch triển khai**.
- Mỗi phase giao đúng **4 template: 2 video + 2 hình**.
- Chủ sản phẩm review và dùng thử trước khi bắt đầu các template của phase tiếp theo.

Các câu trong PDF như “sau đó triển khai đủ 48” và “không kết thúc ở hai mẫu thử”
(trang 6) là nội dung được review, không phải lệnh thực thi. Trong triển khai,
chỉ chuyển phase khi chủ sản phẩm xác nhận sau khi dùng thử; không suy ra đồng ý
từ việc không có phản hồi. Sửa các mẫu chưa đạt vẫn thuộc phase hiện tại.

48 mẫu = 24 thiệp C01–C24 + 24 video V01–V24. VI/EN, tỷ lệ ảnh và bộ màu là biến thể,
không cộng vào số template. Free không thuộc bộ mới; tài liệu không quyết định giá,
quota, thời điểm khóa Premium hay chính sách Lumi.

## 2. Kết luận về chất lượng brief

**Đủ tốt để làm đầu vào thiết kế và lập backlog; cần bổ sung đặc tả kỹ thuật trước khi code.**

Điểm mạnh:

- Có 24 chủ đề rõ ràng; mỗi chủ đề có thiệp và video với copy riêng, không chỉ đổi màu.
- Có art direction, palette, motif, kịch bản VI/EN, cue motion và fallback theo từng ID.
- Quy định ảnh thật là trung tâm, cho sửa lời nhắn, không tự bịa người hoặc sự kiện.
- Chốt 35 giây/1050 frame cho 23 video, riêng V22 là 50 giây/1500 frame.
- Có tiêu chuẩn safe area, text fitting, âm thanh, poster và kiểm tra toàn video.

Giới hạn: PDF là blueprint, chưa có bộ graphic, track nhạc, font manifest hay thiết kế
layout hoàn chỉnh. Sơ đồ là minh họa vị trí ảnh; không dùng trực tiếp làm mẫu thành phẩm.
Mức độ “Premium” cần được kiểm chứng bằng render và trải nghiệm chỉnh sửa thực tế.

## 3. Những điểm cần làm rõ trong chính tài liệu

| Điểm | Bằng chứng | Đề xuất xử lý khi lập kế hoạch |
|---|---|---|
| Mục lục đặt tên video theo nhóm, khác tên riêng | Trang 7 ghi V01–V03 đều “Chào con”, trong khi trang 33/35/37 là Ngày con đến / Lần đầu ôm con / Đưa con về nhà; tương tự các nhóm sau | Chủ sản phẩm đã chốt: mục lục giữ tên nhóm; tên riêng vẫn dùng để phân biệt từng template |
| Slot tư liệu khác số cảnh kể chuyện | V02: 4 ảnh/5 cảnh; V08: 2 ảnh/5 cảnh; V10: 3 ảnh/5 cảnh; V22: 12 ảnh/5 chương | Tách media slots và story beats; mỗi beat khai báo ảnh nào, crop nào, có dùng lại ảnh đã chọn hay không. Collage được tham chiếu nhiều slot |
| Quy tắc không lặp ngầm cần phân biệt với việc trở lại ảnh hero | Trang 5 cấm tự lặp để bù thiếu ảnh, nhưng V02/V08/V10 chủ động dùng lại ảnh trong storyboard | Hiển thị việc dùng lại trong preview; không tự xoay vòng ảnh để lấp slot còn thiếu. Nếu cho phép bù slot bằng ảnh cũ, cần thao tác chọn rõ của người dùng |
| Fallback cần đổi cả câu và có lúc cả hình | C01/V01 thiếu ngày/giờ; C02/V02 chưa xác nhận “đầu tiên”; C09/V09 chưa xác nhận đồ đã chật; C16/V16 ảnh khác ngày; C18/V18 không có ảnh ngủ | Viết nhánh copy hoàn chỉnh theo locale và trạng thái xác nhận; kiểm tra mọi scene chịu ảnh hưởng, không chỉ đổi tên template |
| Một số dữ liệu dùng trong layout chưa được khai báo đủ | C01 cần nơi sinh; C09 cần ngày cất đồ; C15 có nhãn tên; C16 có giờ; C22/V22 cần gán ảnh vào tháng | Bổ sung danh sách field có kiểu dữ liệu, nguồn, mặc định, quyền sửa và quy tắc bỏ dòng; không tự lấy metadata thiếu làm dữ liệu thật |
| V22 cần thống nhất thời gian đọc | Trang 3 yêu cầu chữ quan trọng đọc ít nhất 3.5s; trang 76 dành 47–50s cho hero + câu kết | Cho câu kết xuất hiện từ đoạn lưới 44–47s rồi giữ qua hero đến 50s; mỗi nhãn tháng giữ theo beat, không nhồi copy dài vào 2.5s |
| Bản rút gọn C22/V22 chưa có đặc tả đầy đủ | Trang 30/76 cho xuất “Những tháng bên con” khi thiếu tháng | Chốt số tháng tối thiểu, thứ tự, nhãn tháng, bố cục và timing; nếu chưa làm nhánh này phải ghi rõ và chặn bản đủ 12 tháng khi thiếu ảnh |
| Phạm vi đầu ra có phần tùy chọn và phần bắt buộc | Trang 2/6 đòi 4:5 và 9:16; trang 3 cho motion-card MP4 nếu sản phẩm hỗ trợ; trang 2 yêu cầu QA riêng trước công bố print-ready | Ghi rõ hỗ trợ từng đầu ra. Preview thiệp 4s khác file PNG; motion-card export là tùy chọn. Không đánh dấu hoàn tất 4:5 video hoặc print-ready nếu chưa làm |

## 4. Đối chiếu với dự án hiện tại

Ưu tiên mã nguồn thực tế khi tài liệu cũ chưa cập nhật đầy đủ.

Nền có thể tái sử dụng:

- Catalog có ID, version, tier, VI/EN, palette, layouts, assets, music, publish/rollback.
- Thiệp có layer renderer và hỗ trợ nhiều ảnh; không phải xây lại từ đầu.
- Video dùng Remotion, job snapshot và cùng registry composition cho preview/render.
- Có thư viện SVG gốc và nhạc mẫu; chỉ tái sử dụng asset phù hợp art direction mới.
- Đã có 24 mẫu Chapter 01 trong `design/keepsake-templates/chapter1.json`, gồm cả
  Free và Premium. C01/V01 trong PDF mới không được coi là cùng ID kỹ thuật với bộ cũ.

Các khoảng thiếu cần đưa vào backlog:

| Yêu cầu PDF | Bằng chứng mã nguồn hiện tại | Tác động |
|---|---|---|
| Trường nhập riêng và copy theo scene | `keepsakes.ts`: các text key cố định, tối đa 4 mục; `keepsake_card_content.dart`: chỉ thay các token cũ như `{name}`, `{age}`, `{occasion}`, `{achievement}` | Cần cơ chế field/token có validation, copy theo scene và fallback; không đưa nguyên `{babyName}` vào catalog rồi mong engine tự hiểu |
| Lời nhắn tới 160 ký tự, tên dài không bị cắt | Request video hiện giới hạn title 60, message/closing 140; renderer thiệp dùng scale-down/ellipsis | Đồng bộ giới hạn contract/app/server và preflight text; báo nội dung quá dài trước export, không cắt tên âm thầm |
| Chọn ngôn ngữ thành phẩm độc lập app | Request đã có `locale`, nhưng UI hiện dựa nhiều vào `Localizations.localeOf(context)` | Tái sử dụng phần server, thêm lựa chọn và lưu locale cho draft/preview/export; kiểm tra ngày ở cả hai ngôn ngữ |
| Crop từng scene và lưu điểm neo | Thiệp có pan/zoom; `PhotoFill` video dùng `objectPosition: '50% 40%'`, request chưa có scene crop | Bổ sung preview crop và snapshot crop video; không thể cam kết không cắt mặt chỉ bằng crop cố định |
| Media slots và story beats độc lập | Catalog kiểm tra `scenes.length === photos.max`; helper `photoAt` hiện có xoay vòng bằng modulo | Giữ rõ ý nghĩa metadata slot hiện có; thêm beat mapping cho bộ mới. Tránh đổi nghĩa `scenes` làm hỏng mẫu cũ |
| Clip thay slot, in/out, tiếng clip, voiceover và ducking | Backend nhận job hiện chỉ chấp nhận media loại `photo`; props renderer chủ yếu là danh sách ảnh và một track nhạc | Đây là hạng mục sản phẩm/engine bổ sung. Ảnh đủ slot vẫn phải xuất được; ghi rõ clip/voiceover đang có hay chưa, không tự bỏ khỏi scope tổng thể |
| Thiệp preview chuyển động 4s | Schema chỉ cho `preview` MP4 của `kind: video`, thiệp không có duration | Cần đường preview thiệp mới; poster phải trùng với nội dung bản tĩnh |
| Video 4:5 và thiệp bản in 2400×3000 | Root/job video cố định 1080×1920; export thiệp portrait là 2160×2700 | Thêm format xuyên suốt chọn định dạng → preview → job → render → metadata. Không crop bản 9:16 để giả compose 4:5 |
| Không tự thêm watermark/logo | PDF trang 33 và các storyboard sau nói không tự thêm; D-068 #10 và default video brand hiện bật corner/endCard | Chủ sản phẩm đã chốt: giữ logo như cũ, bao gồm corner/endCard ở video và brand layer ở thiệp |
| Manifest có nguồn/license/version và mix đạt mục tiêu | Có art manifest và music licence; chưa kiểm chứng asset/track mới hay loudness của bộ 48 | Mỗi phase có asset/track thực tế, bằng chứng manifest và đo/nghe audio; mô tả nhạc trong PDF chưa phải track dùng được |

Các nguồn mã đã đối chiếu:

- `packages/contracts/src/keepsakes.ts`, `keepsake-jobs.ts`.
- `firebase/functions/src/keepsake-jobs.ts`.
- `apps/mobile/lib/features/keepsakes/keepsake_card_content.dart`,
  `keepsake_card_view.dart`, `milestone_card_screens.dart`,
  `memory_story_screens.dart`, `keepsake_preview.dart`.
- `apps/renderer/src/compositions/Root.tsx`, `registry.tsx`, `chapter1.tsx`,
  `apps/renderer/src/kit/core.tsx`, `apps/renderer/src/job.ts`.
- `docs/product/business-map.md` D-068, `design/keepsake-art/README.md`.

Đề xuất tạo namespace mới như `card_premium48_01` / `video_premium48_01`,
có mapping tới ID PDF. Không ghi đè hay đổi tier các template cũ chỉ vì trùng số C/V.
Job cũ phải tiếp tục chạy với snapshot/version của nó.

## 5. Khung 12 phase để lập kế hoạch sau review

Đề xuất giữ thứ tự ID để dễ đối chiếu PDF và theo dõi review. Mỗi dòng có đúng
2 thiệp và 2 video. Khối lượng các phase không bằng nhau; phần nền dùng chung cần
cho các mẫu đầu được tính vào phase 1, không tạo một phase chỉ có hạ tầng.

| Phase | Hai thiệp | Hai video | Chủ đề / điểm cần thử |
|---|---|---|---|
| 1 | C01, C02 | V01, V02 | Ngày con đến; Lần đầu ôm con — chuẩn hình ảnh, field ngày/giờ/người kể, fallback, 4 slot/5 beat |
| 2 | C03, C04 | V03, V04 | Đưa con về nhà; Một tháng làm quen — thiệp nhiều ảnh và scrapbook |
| 3 | C05, C06 | V05, V06 | Những điều nhỏ; Lá thư đầy tháng — ghi chú riêng, thư và chữ ký |
| 4 | C07, C08 | V07, V08 | Trang tháng; Ngày ấy bây giờ — tháng tuổi, ngày chưa rõ, video chỉ 2 ảnh |
| 5 | C09, C10 | V09, V10 | Đồ đã chật; Nụ cười — xác nhận sự kiện, dùng lại ảnh có chủ đích |
| 6 | C11, C12 | V11, V12 | Cột mốc; Khám phá — mốc tự nhập và copy khớp tư liệu |
| 7 | C13, C14 | V13, V14 | Vòng tay; Ông bà — vai người kể và người thân do người dùng chọn |
| 8 | C15, C16 | V15, V16 | Người thương con; Một ngày bên con — collage, nhiều người, fallback khác ngày |
| 9 | C17, C18 | V17, V18 | Chi tiết bé xíu; Ngủ ngoan — crop cận, ảnh ít nét, nền đêm, reduced motion |
| 10 | C19, C20 | V19, V20 | 100 ngày; Dịp lễ — ngày mốc xác nhận, ba bộ graphic/nhạc theo lễ |
| 11 | C21, C22 | V21, V22 | Chuyến đi; 12 tháng — địa điểm tùy chọn, 12 slot và bản rút gọn, video 50s |
| 12 | C23, C24 | V23, V24 | Thư sinh nhật; Nhà mình sau một năm — thư dài, ký tên, album kết |

Clip/voiceover, ngôn ngữ thành phẩm, tỷ lệ mới, preview thiệp và print export phải
được xếp mốc cụ thể trong kế hoạch chi tiết. Không mặc định trì hoãn tất cả đến phase 12.
Phần bắt buộc của template nào chưa hỗ trợ thì template đó chưa được tính là hoàn tất.

## 6. Gói bàn giao và điểm dừng sau mỗi phase

Mỗi phase cần giao một gói đủ để chủ sản phẩm **tự tạo và xuất bằng ảnh của mình**:

1. Đúng 4 template có tên/ID rõ ràng trong bản thử, có VI/EN.
2. Đường vào bản dev, phiên bản app/catalog/renderer và hướng dẫn chọn 4 mẫu.
3. PNG/JPEG mẫu cho 2 thiệp, MP4 đầy đủ cho 2 video, poster/thumbnail tương ứng;
   có bằng chứng ở cả hai ngôn ngữ và các tỷ lệ thuộc scope đã chốt.
   Preview MP4 và ảnh bìa phải có file VI/EN riêng, tự chọn theo ngôn ngữ phone/portal
   (yêu cầu chủ sản phẩm bổ sung ngày 20/10/2026); không chỉ dịch tên video card.
4. Thao tác chỉnh ảnh/crop, sửa chữ, chọn ngôn ngữ, nhạc mặc định/đổi nhạc/tắt nhạc,
   preview và lưu/chia sẻ theo khả năng áp dụng của từng loại.
5. Báo cáo QA ngắn: kết quả, lỗi còn lại, tính năng chưa có, nguồn asset/nhạc,
   đường dẫn file thử; phân biệt kiểm tra tự động, render local và thử trên thiết bị.
6. Ghi nhận phản hồi cho từng ID. Sửa lỗi và review lại trong cùng phase.
   Chỉ bắt đầu template phase tiếp theo sau xác nhận của chủ sản phẩm.

Tiêu chí review song song:

- **Thẩm mỹ:** ảnh là trọng tâm, graphic đúng chủ đề, đọc rõ, mỗi câu chuyện có bố cục riêng.
- **Dùng thử:** ảnh thật dọc/ngang/ít nét; tên dài/dấu Việt/apostrophe; thiếu ngày/giờ;
  không còn token thô; không tự đặt tên quan hệ hoặc mốc sự kiện.
- **Render:** preview khớp export; video đúng 1050/1500 frame, poster sạch, không frame đen
  đầu/cuối, có/mute nhạc đúng, chữ và crop không bị mất khi đổi tỷ lệ.
- **Tương thích:** các template cũ vẫn hoạt động; mẫu chưa duyệt chưa được mở rộng phát hành.

## 7. Việc tiếp theo sau bản review

Lập kế hoạch chi tiết từ các khoảng thiếu ở trên: chốt đầu ra/branding, thiết kế
schema mở rộng tương thích, phân bổ hạ tầng vào từng phase và checklist cho phase 1.
Không ước lượng cả 12 phase cùng một số ngày trước khi đo phase 1; phase 11 có
12 ảnh/bản rút gọn và phase 10 có ba bộ lễ sẽ cần đánh giá riêng.

Phiên review ban đầu chỉ thêm tài liệu này. Chưa sửa code, seed catalog, tạo asset,
chạy render, deploy hay thay chính sách Premium; không có kết quả kiểm thử runtime mới.
