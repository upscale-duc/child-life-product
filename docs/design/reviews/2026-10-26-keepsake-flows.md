# Review & cải thiện luồng thiệp / video · 26/10/2026

Đã tinh chỉnh hai luồng từ Kỷ niệm theo `senior-ui-ux`, với năm skill chuyên biệt. Giữ nguyên cách chọn mẫu, nội dung từ portal, thứ tự ảnh, điều kiện số ảnh, crop, quyền xem, quota, Premium, nơi lưu và các đích điều hướng.

## Người dùng và mục tiêu

- Người dùng: Cùng nuôi, đang chọn ảnh của bé để làm thiệp hoặc video; có thể dùng chữ lớn, bị gián đoạn hoặc mở bàn phím.
- Trong 5 giây: biết đang chọn/chỉnh gì, đã đủ ảnh chưa và bước tiếp theo là gì.
- Trong 30 giây: chọn đúng mẫu/ảnh, sửa lời nhắn, kiểm tra quyền xem rồi lưu/tạo.
- Trạng thái: có ảnh, thiếu ảnh, bàn phím, mẫu cá nhân hoá chưa đủ thông tin, video đang tạo, hoàn tất và lỗi.

## Phân loại cấu trúc

| Màn | Quyết định | Lý do |
|---|---|---|
| Chọn mẫu thiệp / video | REFINE | Gallery phù hợp để so sánh mẫu. Sửa chữ lớn, tên mẫu và các bộ chọn; giữ gallery, preview và cách chuyển tab |
| Chỉnh thiệp | REFINE | Canvas → công cụ → tuỳ chọn đã đúng. Sửa khả năng đọc/thao tác, thông báo ảnh thiếu và vị trí nút lưu |
| Chọn ảnh video | REFINE | Cảnh → ảnh gợi ý → tiếp tục đã đúng. Làm rõ hành động thêm ảnh, nhãn cảnh và tiến độ |
| Hoàn thiện video | REFINE | Preview → nội dung → thứ tự ảnh → nhạc/quyền xem → tạo là hợp lý. Sửa nhãn/ngày, bỏ badge thừa |
| Thiệp / video cá nhân hoá | REFINE | Giữ toàn bộ trường, xác nhận và thông tin sáng tạo. Đưa hành động và lý do chưa lưu được vào footer |
| Video đang tạo / lỗi | REFINE / KEEP | Giữ thông báo, retry, sửa lựa chọn và đường về Kỷ niệm; phần trăm tiến độ luôn nằm trên một dòng trong vòng tròn |
| Video sẵn sàng | REFINE | Giữ preview và ba hành động; sửa nhãn trạng thái, chiều cao nút khi chữ lớn |

Đánh giá sáu chiều: luồng thông tin và đích hành động hiện tại phù hợp; các vấn đề quan sát được tập trung ở khả năng đọc, co giãn, nội dung thừa và phản hồi thiếu ảnh. Không có bằng chứng cần thay cấu trúc luồng, nên không tạo hai phương án RESTRUCTURE/REDESIGN.

## Evidence

- 40 ảnh **before** từ mã nguồn trước sửa: năm màn × vi/en × Light/Night care × 100%/200%.
- 96 ảnh **after**: 12 trường hợp × hai ngôn ngữ × hai giao diện × hai cỡ chữ. Bàn phím mô phỏng 300 px, có assertion nút lưu nằm trên vùng bàn phím.
- Probe ở 375 × 812, cùng fixtures trước/sau; goldens hiện có dùng safe area riêng của harness. Chỉ so sánh trực tiếp các probe cùng điều kiện.
- R = quan sát render; C = xác nhận từ code / kiểm thử; H = chưa xác nhận.
- Các ô màu là ảnh tổng hợp. Không phải lỗi tải ảnh; không dùng chúng để kết luận về ảnh thật, chất lượng crop hoặc cảm xúc thành phẩm.
- Lời nhắn tiếng Việt trên thiệp ở probe tiếng Anh là nội dung draft do người dùng nhập, được giữ nguyên có chủ đích.
- Không đánh giá trên thiết bị thật: VoiceOver/TalkBack, bàn phím hệ điều hành thật, haptic/motion, tên rất dài, ảnh thật, native export/share/save, Firebase/Cloud Run/push thật.

[Xem gallery trước/sau theo màn, ngôn ngữ, giao diện và cỡ chữ](assets/2026-10-26-keepsake-flows/index.html).

## Gates và nhận xét

- G1: nội dung nơi lưu và quyền xem được giữ; câu trước khi lưu thiệp dùng tương lai/hành động, không báo đã lưu. Không đổi request hoặc quota.
- G2: các nút được kiểm tra trong render 100%/200%; nút lưu thiệp có kiểm tra vị trí trên bàn phím mô phỏng. Screen reader thật chưa đánh giá.
- G3: không đổi cách lưu/giữ draft, xoá, retry hoặc upload. Không khẳng định độ bền dữ liệu ngoài phạm vi kiểm thử.
- G4: giữ nguyên điều kiện Cùng nuôi, feature flags, Premium và audience; các kiểm thử liên quan được chạy.
- G5: không có thay đổi AI / health claims.
- G6: luồng chọn mẫu → chỉnh/chọn ảnh → submit/điều hướng được kiểm tra với fake services. Xuất ảnh native và dựng video server thật chưa đánh giá.

Không có gate failure mới được phát hiện trong phạm vi kiểm tra. Trước sửa, các lỗi tràn ở 200% tạo rủi ro đọc/thao tác; sau sửa, probe không còn layout exception.

## Findings đã xử lý

| ID | Màn / điểm chạm | Vấn đề và ảnh hưởng | Evidence / tham chiếu | Severity / priority | Mức |
|---|---|---|---|---|---|
| K01 | Chỉnh thiệp | Công cụ có chiều cao cố định; chữ lớn tràn, tiếng Anh vỡ giữa từ. Đo nhãn và cuộn ngang khi cần, để chữ nguyên vẹn | R+C; `before/card_edit_*_2.0x.png`; `_EditState`, `_ToolTile` | High / P1 | L1 |
| K02 | Thiệp thiếu ảnh | Nút lưu bị khoá nhưng không nêu lý do; mặc định mở Bố cục. Nay mở Ảnh khi draft chưa sẵn sàng, báo chính xác số ảnh cần thêm | R+C; `before/card_missing_*`; `_EditState` | Medium / P1 | L1 |
| K03 | Canvas thiệp | Text scaling làm thay đổi chữ bên trong toạ độ thành phẩm, có thể cắt nội dung xuất. Chữ artwork theo tỷ lệ canvas; controls vẫn theo cỡ chữ hệ thống | R+C; `keepsake_card_view.dart`, `after/card_edit_*_2.0x.png` | High / P1 | L1 |
| K04 | Hướng dẫn căn ảnh | Overlay che ảnh, xuất hiện cả lúc đang chọn bố cục. Chỉ hiện dưới canvas khi đang dùng công cụ Ảnh | R+C; `_EditState` | Medium / P2 | L1 |
| K05 | Nút lưu | Cho phép phần chỉnh sửa cuộn khi không đủ chiều cao; footer giữ nút lưu và nơi lưu/quyền xem, nằm trên bàn phím mô phỏng | R+C; `after/card_keyboard_*`; assertion `getBottomRight(save).dy <= 512` | High / P1 | L1 |
| K06 | Nguồn ảnh video | “Thư viện máy” trông như tab nhưng thực tế mở picker rồi quay về danh sách cũ. Đổi sang nút “Thêm ảnh từ máy”, cùng hành động upload/chọn cảnh như trước | R+C; `MemoryStoryPhotosScreen`, kiểm thử chọn ảnh | Medium / P1 | L1 |
| K07 | Cảnh và tiến độ | Nhãn cảnh/tuỳ chọn và thanh đếm ảnh tràn ở 200%. Đo chiều cao nhãn, tăng bề rộng cảnh theo cỡ chữ, cho summary xuống dòng; nút bỏ ảnh đủ 44 pt | R+C; `before/video_photos_*_2.0x.png`; `_SceneStrip`, `_SceneCard`, `_BottomBar` | High / P1 | L1 |
| K08 | Hoàn thiện video | “Ngày mốc” dính sát ngày; badge điền sẵn lặp lại thông tin. Đổi label/value thành hai dòng và bỏ badge | R+C; `before/video_finish_*`; `_Fact`, `_FinishState` | Medium / P1 | L1 |
| K09 | Mẫu cá nhân hoá | Preview và lưu/tạo nằm cuối biểu mẫu dài, hai nút cùng mức nhấn mạnh. Footer cố định, preview nhẹ hơn, lý do chưa lưu được ngay cạnh nút | R+C; `before/premium_card_*`; `PremiumKeepsakeEditor` | Medium / P1 | L2 |
| K10 | Chọn mẫu | Tab Thiệp/Video tràn; tên video bị nhãn “Gợi ý” chiếm chỗ; bộ chọn tỷ lệ mất thông tin ở chữ lớn. Tab/bộ chọn cuộn ngang, tên video đứng riêng và được xuống dòng | R+C; `after/*_templates_*`; `KeepsakeKindTabs`, `_VideoTemplateTile` | High / P1 | L1 |
| K11 | Video sẵn sàng | Badge trạng thái và chiều cao cố định của nút kết quả không co giãn theo nhãn. Cho chữ xuống dòng và nút tăng chiều cao | R+C; `MemoryStoryJobScreen`, `KeepsakeActionTile`, `after/video_ready_*` | Medium / P1 | L1 |
| K13 | Mẫu cá nhân hoá / hồ sơ tải trễ | Controllers khởi tạo trước khi hồ sơ đến nên tên/ngày sinh không được điền. Nay cập nhật đúng nguồn hồ sơ một lần, giữ mọi chỉnh sửa hoặc thao tác xoá của ba mẹ, không tự đoán ngày | R+C; `before/premium_card_*`; `_fillProfile`; sáu tests `late profile fills…` | Medium / P1 | L1 |
| K12 | Kiểm tra hình ảnh | File keepsake golden thiếu `@Tags(['golden'])`, lệnh freshness chuẩn không chạy test. Bổ sung tag và coverage tiếng Anh cho ba màn chỉnh/chọn ảnh/hoàn thiện | C; `test/golden/keepsake_golden_test.dart` | Medium / P1 | L1 |

Nhãn “Chọn ảnh” trên canvas mẫu cá nhân hoá cũng dùng màu mực của template, để không kế thừa chữ sáng của Night care trên nền artwork sáng (R+C, `PremiumKeepsakeEditor`, L1 / Medium / P1).

## Simplify

| Thành phần | Class | Action | Vì sao |
|---|---|---|---|
| Badge “Điền sẵn từ hồ sơ” ở video | Redundant | REMOVE | Tên bé và ngày đã hiện ngay bên cạnh |
| Footnote điền sẵn ở thiệp | Contextual | REWRITE | Dành vùng này cho nơi lưu/quyền xem hoặc lý do thiếu ảnh, giúp quyết định trước khi lưu |
| Hướng dẫn kéo/căn ảnh | Contextual | RELOCATE | Đặt ngoài artwork, chỉ hiện khi chỉnh ảnh |
| Source segmented video | Essential action, misleading presentation | REWRITE | Picker là hành động thêm ảnh, không phải chế độ lọc |
| Số ảnh, giới hạn tối thiểu, cảnh tuỳ chọn | Essential | PRESERVE | Không thay điều kiện tiến tới bước tiếp theo |
| Quyền xem, thời gian tạo, loading, lỗi, retry, quota | Essential | PRESERVE | Giữ nguyên hành vi và ý nghĩa |
| Tên mẫu và nhãn Premium/Gợi ý | Essential / Contextual | PRESERVE | Tách cách trình bày để không che tên mẫu |

## Scorecard trong phạm vi có bằng chứng

Các điểm là nhận định thiết kế dựa trên render/code, không phải kết quả usability test. So sánh trước/sau áp dụng cho năm màn có cùng fixtures và coverage; không lấy trung bình với các mục chưa đánh giá.

| Chiều | Trước → Sau | Ghi chú |
|---|---|---|
| Task clarity | 3 → 4 | Thiếu ảnh có lý do và công cụ phù hợp |
| Information hierarchy | 3 → 4 | Preview sáng tác là trọng tâm; hành động tạo/lưu nổi bật hơn preview phụ |
| Scanability / density | 3 → 4 | Bỏ badge thừa, tách ngày và nhãn, summary linh hoạt |
| Interaction clarity | 2 → 4 | Picker thể hiện đúng là hành động, nhãn công cụ rõ |
| Navigation / flow | 3 → 3 | Giữ luồng, đích đến và điều kiện tiến bước; hồi quy bằng widget tests |
| Visual coherence | 3 → 4 | Dùng nút/sheet sẵn có, chiều cao linh hoạt |
| Content / localisation | 3 → 4 | Ba chuỗi mới vi/en, plural tiếng Anh; nội dung draft được giữ |
| States / trust | 3 → 4 | Thiếu ảnh rõ; không dùng câu “đã lưu” trước khi lưu |
| Accessibility / adaptability | 2 → 3 | 200% và bàn phím mô phỏng đã render; chưa có screen reader/device nên không chấm cao hơn |
| Product identity | 4 → 4 | Giữ token, artwork portal, chất ấm áp và hai giao diện |
| Content necessity | 3 → 4 | Giảm lặp, giữ thông tin thiết yếu |

## Tự đánh giá sau sửa

1. Nhiệm vụ chính rõ: chọn ảnh/chỉnh thiệp/hoàn thiện có tiêu đề và hành động tương ứng.
2. Nội dung chính nổi bật: artwork giữ tỷ lệ, controls không che ảnh.
3. Không lặp badge điền sẵn; gesture hint chỉ hiện khi cần.
4. Không thêm card, màu hoặc token mới.
5. Giữ số bước; giảm việc dò nguyên nhân nút bị khoá và cuộn tìm nút tạo/lưu.
6. vi/en được render; không ép dịch nội dung draft của người dùng.
7. Light/Night care đều được render.
8. Cỡ chữ 200% có kiểm tra layout; nhãn dài có chỗ hoặc cuộn ngang.
9. Bàn phím mô phỏng không che nút lưu; kiểm thử giữ thứ tự ảnh, crop và routing.
10. Cải thiện quan sát được: hết các layout exception ở ma trận probe, ảnh không còn bị gesture overlay che, thiếu ảnh có hướng xử lý. Không tuyên bố cải thiện conversion, thời gian hoàn thành hay sự hài lòng đo được.

## Validation

- **257 tests passed** trong lần chạy kết hợp các widget tests, navigation, Premium/quota/purchase, liên kết cột mốc và 96 probe layout; có sáu ca hồ sơ đến trễ cho thiệp/video, gồm giữ tên đã nhập hoặc đã xoá. Các chỉnh sửa nhỏ sau đó được kiểm tra lại ở đúng trường hợp liên quan.
- **32 golden comparisons passed**, không dùng `--update-goldens` ở lượt xác minh. Gồm các màn giữ nguyên và các màn đã đổi, cùng trạng thái resume sau Premium/quota.
- **22 golden variants được cập nhật/thêm** đúng phạm vi: MM06, MM07, MM09, MM11, MO03 card resumed, MO04 finish quota. Sáu ảnh tiếng Anh MM06/MM07/MM11 là coverage mới. Đã mở và so sánh các ảnh thay đổi với HEAD.
- Probe tiếng Việt/Anh × Light/Night care × 100%/200% không còn layout exception; riêng bàn phím có kiểm tra vị trí nút lưu trên vùng 300 px. Kiểm tra bổ sung video cá nhân hoá dùng đúng số ảnh template yêu cầu.
- `flutter gen-l10n` và `git diff --check` chạy qua.
- `flutter analyze --no-pub`: không có error; còn một warning import trùng đã có sẵn ở `test/app/safe_navigation_test.dart:61`. Không sửa file này trong đợt UI/UX.
- Trước khi sửa, lượt golden đầy đủ đã có **4 mismatch** tại `mm01_photos_{light,nightCare}` và `mm03_nudge_{light,nightCare}` do entry Kỷ niệm đang được thay đổi trong shared tree (2.11%, 1.96%, 2.25%, 2.01%). Chúng được giữ nguyên; không cập nhật baseline ngoài màn đã sửa chỉ để làm test xanh. Lượt xác minh 32 cases tách riêng các mismatch đã biết này.
- Các ô vuông icon Material trong probe mẫu cá nhân hoá là giới hạn font của test harness; chưa xác minh biểu diễn của chúng trên thiết bị thật.

Tái chạy từ `apps/mobile`:

```sh
flutter test test/design_explorations/keepsake_flows/flow_review_test.dart test/features/memory_story_test.dart test/features/keepsake_test.dart test/features/premium48_editor_test.dart test/features/keepsake_live_test.dart test/features/premium_quota_test.dart test/features/premium_purchase_test.dart test/features/milestones/ms01_card_flow_test.dart test/app/safe_navigation_test.dart
flutter test --tags golden test/golden/keepsake_golden_test.dart test/golden/premium_golden_test.dart --name 'mm10_choose|mm11_edit|cards_all_formats|mm15_stories|mm06_photos|mm07_finish|mm08_rendering|mm09_ready|mm14_failed|mo03_card_resumed|mo04_finish_quota'
```

Đặt `KEEPSAKE_REVIEW=after` khi chạy probe để xuất lại gallery. Ảnh before là bằng chứng lịch sử của lần kiểm tra này, không tạo lại từ mã đã sửa.

## Tóm tắt cho chủ sản phẩm

Ba mẹ thấy rõ cần chọn thêm ảnh nào/số lượng bao nhiêu, chỉnh nội dung thuận tiện khi mở bàn phím, và tìm được nút lưu/tạo trong các mẫu dài. Chữ lớn không còn phá bố cục thành phẩm hoặc làm nhãn công cụ vỡ vụn. Video hiển thị ngày, thứ tự ảnh và quyền xem dễ đọc hơn. Các lựa chọn và hành vi sản phẩm được giữ nguyên.
