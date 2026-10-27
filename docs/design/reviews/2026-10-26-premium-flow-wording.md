# Wording — flow nâng cấp Premium · 26/10/2026

> Cập nhật theo yêu cầu tiếp theo của chủ sản phẩm: đã sửa trực tiếp flow Figma 1134:3884 để review trước khi triển khai bố cục Premium v2. Xem mục cuối; phần báo cáo bên dưới ghi lại đợt sửa code trước đó.

## Kết quả và phạm vi

Đã đọc [flow Figma 1134:3884](https://www.figma.com/design/sJLG1fAXKDnDr9YI6Yx8ex/Child-Life?node-id=1134-3884): PZ01/PZ01B chọn gói, PZ01F toàn trang, PZ02 chi tiết thanh toán và PZ11–PZ16 sáu quyền lợi. Đã đọc ảnh toàn flow, context đầy đủ của PZ01F và từng sheet chi tiết; tên layer bị rút gọn không được coi là câu chữ thực tế.

**Đã áp dụng 30 ID song ngữ trong app**: tiêu đề theo điểm vào, sáu thẻ quyền lợi, bảng so sánh và tên gói. Dùng `tool/premium_paywall_wording.py` và `flutter gen-l10n`; giữ nguyên biến, metadata, giá, hạn mức, quyền và hành vi mua. [Danh sách trước/sau đầy đủ](assets/2026-10-26-premium-wording/copy-changes.json).

Figma thể hiện phương án danh sách với sheet chi tiết; Flutter hiện dùng carousel và bảng so sánh (`paywall_v2.dart`). Đây là đợt **REFINE wording (L1)**, không đổi bố cục hoặc tạo thêm màn thanh toán. Phần “Bản wording cho bố cục Figma” dưới đây cung cấp câu chữ cho các vị trí chưa có trong Flutter, không khẳng định các sheet đó đã được triển khai. Figma được đọc, không bị chỉnh sửa, theo quy ước nguồn chính trong `CLAUDE.md` (D-104).

## Người đọc và vấn đề

Ba mẹ cần biết Premium thêm gì, dùng chung thế nào, khoản nào trả theo năm/tháng và Free vẫn làm được gì. Người có quyền quản lý gói mới đăng ký; thành viên khác gửi lời nhờ nâng cấp theo luồng hiện có.

| Vấn đề | Trước → sau | Lý do |
|---|---|---|
| Câu mở đầu khó xác định việc cần làm | “Những năm đầu của con, giữ trọn vẹn hơn” → “Nâng cấp lên Premium” | Gọi đúng mục đích, giảm áp lực cảm xúc |
| “4 video” dễ lẫn số video có thể xem hoặc số bản nháp | “4 video mỗi tháng” → “4 lượt xuất video mỗi tháng” | Preview và xuất là hai việc khác nhau |
| Câu bán hàng vượt thao tác thực tế | “đổi phong cách chỉ với một chạm” → “Thêm tên, ảnh và lời nhắn theo mẫu bạn chọn” | Không hứa số chạm không được bảo đảm |
| Lumi dễ bị hiểu là tự ghi luôn | “ghi nhanh bằng một câu nói” → “soạn bản ghi để bạn xem lại rồi lưu” | Xác nhận của người dùng là bước có thật |
| Hai thẻ Lumi/Nhịp dễ bị hiểu là hai hạn mức riêng | “Dùng chung 200 credit Lumi/tháng” trên thẻ Nhịp | Nói rõ dùng cùng một quỹ credit |
| Người chăm sóc dễ lẫn tổng thành viên hoặc người thân chỉ xem | “6 người cùng chăm” → “6 người có quyền ghi · Free: 3” | Hạn mức là chỗ ghi, không phải tổng người xem album |
| “thấy ngay” và “không dừng giữa chừng” là bảo đảm quá mức | Mô tả việc ghi/xem nhật ký và dung lượng dùng chung | Không hứa mạng hoặc upload luôn thành công |

Các con số trên là ví dụ theo cấu hình hiện tại. App vẫn lấy số từ `PlanOffer`/`getFamilyPlan`, không hardcode hạn mức mới. Đối chiếu D-074 (IAP làm sau), D-081, D-101 và `docs/product/premium-v2-plan.md` (shared pools, export quota, miễn phí vẫn có nhật ký chung).

## Bản wording cho bố cục Figma

Phần dưới là bản đề xuất theo đúng vị trí trong flow được liên kết. Các mục tương ứng trong Flutter đã cập nhật qua 30 ID; câu mới dành riêng cho layout/sheet chưa có chỉ nằm trong tài liệu này. Giá và số lượng là dữ liệu cấu hình, không phải câu cố định để chép vào mã.

### PZ01 / PZ01B / PZ01F — Chọn gói

| Vị trí | Câu đề xuất |
|---|---|
| Tiêu đề | Nâng cấp lên Premium |
| Dòng dẫn | Thêm lượt video, credit Lumi và dung lượng cho cả nhà. |
| Tên gói | Gói năm / Gói tháng |
| Giá năm | `{giá_năm}/năm` |
| Quy đổi dưới giá năm | Tương đương khoảng `{giá_quy_đổi}/tháng` |
| Thanh toán gói năm | Thanh toán `{giá_năm}` mỗi năm |
| Thanh toán gói tháng | Thanh toán `{giá_tháng}` mỗi tháng |
| Dùng chung | Một gói cho cả nhà · tối đa `{số_người}` người có quyền ghi |
| Nhóm quyền lợi | Premium có gì? |
| Video kỷ niệm | `{số_lượt}` lượt xuất video mỗi tháng |
| Mẫu thiệp & video cao cấp | Chọn mẫu cho từng dịp, thêm ảnh và lời nhắn của bạn |
| Hỏi Lumi | `{credit}` credit/tháng · cả nhà dùng chung |
| Nhìn lại nhịp bú, ngủ | Tóm tắt nhật ký, kèm thời gian so sánh và nguồn |
| Dung lượng | `{GB}` GB cho ảnh và video của cả nhà |
| Cùng ghi nhật ký chăm con | Tối đa `{số_người}` người có quyền ghi · Free: `{free}` |
| Dòng tổng | Thanh toán hôm nay |
| CTA năm | Đăng ký gói năm · `{giá_năm}` |
| CTA tháng | Đăng ký gói tháng · `{giá_tháng}` |
| Khôi phục | Khôi phục giao dịch |

Giữ cơ sở so sánh của phần tiết kiệm (so với trả gói tháng trong 12 tháng). Không biến giá quy đổi/tháng thành khoản bị thu mỗi tháng của gói năm. Thuế, tự gia hạn, điều kiện huỷ, Điều khoản và Quyền riêng tư giữ nguyên nội dung đã có; đợt này không biên tập điều khoản pháp lý. Khi IAP chưa mở, app vẫn dùng trạng thái “Bước thanh toán sắp mở”, không thực hiện giao dịch.

### PZ02 — Chi tiết thanh toán

| Vị trí | Câu đề xuất |
|---|---|
| Tiêu đề | Chi tiết thanh toán |
| Tên gói | Premium · Gói năm / Premium · Gói tháng |
| Giá quy đổi gói năm | Tương đương mỗi tháng |
| Dòng tiết kiệm | Tiết kiệm so với 12 tháng trả theo tháng |
| Dòng thuế | Thuế / Đã gồm trong giá — giữ nguyên |
| Tổng | Thanh toán hôm nay |
| CTA | Đăng ký gói năm / Đăng ký gói tháng |

Nội dung tự gia hạn và thời điểm huỷ hiện có được giữ nguyên để tránh thay đổi ý nghĩa pháp lý. Sheet này chưa có trong Flutter; đây là bản câu chữ đề xuất, chưa được render trong layout Figma.

### PZ11–PZ16 — Chi tiết quyền lợi

Mỗi sheet dùng cùng một nút đóng **“Quay lại chọn gói”** thay cho “Đã hiểu”, nếu nút thực tế đóng sheet và trở về màn chọn gói. Không thêm chức năng mới hoặc tự chuyển người dùng sang đăng ký.

| Sheet | Tiêu đề | Nội dung chi tiết đề xuất | So sánh |
|---|---|---|---|
| PZ11 | Video kỷ niệm | Chọn ảnh, thêm lời nhắn và nhạc theo mẫu. Xem trước miễn phí; dùng lượt khi xuất thành công. Tải video về hoặc chia sẻ sau khi xuất. | Free: `{free}` lượt dùng thử, không cấp lại. Premium: `{premium}` lượt xuất mỗi tháng. |
| PZ12 | Mẫu thiệp & video cao cấp | Chọn mẫu cho từng dịp. Thêm tên, ảnh và lời nhắn của bạn. Chọn tiếng Việt hoặc tiếng Anh khi mẫu hỗ trợ. | Free: mẫu cơ bản, xem trước mẫu cao cấp. Premium: toàn bộ mẫu cao cấp. |
| PZ13 | Hỏi Lumi | Hỏi về nhật ký và xem dữ liệu Lumi dùng để trả lời. Nhờ Lumi soạn bản ghi để bạn kiểm tra trước khi lưu. Credit dùng chung cho cả nhà, được cấp mỗi tháng. | Free: `{free}` credit dùng thử một lần. Premium: `{premium}` credit mỗi tháng. |
| PZ14 | Nhìn lại nhịp bú, ngủ | Xem tóm tắt từ nhật ký đã ghi. Có khoảng thời gian so sánh và nguồn để xem lại. Dùng chung credit Lumi với phần hỏi đáp. | Free: dùng credit trải nghiệm khi còn và khi tính năng được mở cho gia đình. Premium: dùng cùng quỹ `{premium}` credit Lumi/tháng. |
| PZ15 | Thêm chỗ lưu ảnh và video | `{GB}` GB dùng chung cho ảnh và video của cả gia đình. Xem mức sử dụng trong Gói của gia đình. Mua thêm dung lượng: Sắp có. | Free: `{free}` GB. Premium: `{premium}` GB. |
| PZ16 | Cùng ghi nhật ký chăm con | Cùng ghi cữ bú, giấc ngủ và xem cập nhật trong nhật ký. Quyền xem và ghi theo vai trò của từng người. Người thân chỉ xem album không tính vào số chỗ ghi. | Free: `{free}` người có quyền ghi. Premium: `{premium}` người có quyền ghi. |

Không chép “Đến mỗi dịp bản nháp đã sẵn sàng”, “Tự lưu chạy đều, không dừng giữa chừng” hoặc “Ai ghi gì, cả nhà thấy ngay” thành bảo đảm vô điều kiện. Tự lưu có quyền truy cập, mạng, nền hệ điều hành và dung lượng; quyền xem nhật ký phụ thuộc vai trò. Không bổ sung chẩn đoán hoặc kết luận y khoa qua phần marketing.

## Tinh giản và tự rà

| Thành phần | Phân loại | Quyết định |
|---|---|---|
| Tên quyền lợi, đơn vị và hạn mức | Essential | REWRITE để rõ việc và đơn vị, giữ biến từ cấu hình |
| Câu “trọn vẹn”, “xứng với tháng đầu” | Contextual | REWRITE theo tác vụ, không suy đoán bé đang ở tháng đầu |
| Số lần chạm hoặc thời gian cập nhật tuyệt đối | Redundant/không bảo đảm | REMOVE khỏi lời hứa, giữ mô tả chức năng |
| Chú thích Lumi và Nhịp cùng quỹ credit | Essential | MERGE vào dòng hạn mức, không thêm một đoạn dài |
| Cảnh báo, hậu quả mất gói, giá/gia hạn, phạm vi quyền | Essential | PRESERVE; không dùng đợt copy để thay business/legal |
| Bố cục carousel hiện có | Giữ cấu trúc | REFINE nội dung, không cần A/B layout cho yêu cầu wording |

Tự rà trên ảnh mới: tiêu đề chính rõ hơn; vẫn một CTA đăng ký; không thêm subtitle vào app; dòng hạn mức đọc được; Free vẫn được nhắc rõ; vi/en giữ cùng ý; Light/Night care đạt ở cỡ chữ mặc định. Không đo thời gian hoàn thành hoặc tỷ lệ chuyển đổi. Cỡ chữ 200%, tên rất dài và screen reader chưa đánh giá trong đợt này.

## Bằng chứng và kiểm tra

- Trước khi sửa: `tool/golden_freshness.sh test/golden/premium_v2_golden_test.dart` — **80 Current**, không có baseline lỗi thời.
- Chỉ cập nhật golden các case `^(pw|cards_)` trong suite liên quan: **40 render**, 36 PNG thực sự thay đổi (gói add-on không đổi).
- Đã mở contact sheet của toàn bộ 36 PNG thay đổi trong vi/en × Light/Night care, gồm sáu thẻ và bảy điểm vào paywall. Không có cắt chữ mới thấy ở 375×812, cỡ chữ mặc định.
- Vòng render đầu phát hiện số lượng tiếng Anh hiện dấu `#` do cách gen-l10n xử lý plural. Đã đổi sang biến `{n}` trong từng nhánh, render lại và bổ sung bài kiểm tra số 0/1/4/200 để chặn tái diễn.
- Chạy lại toàn suite Premium v2 không update baseline: **80/80**.
- Các tests `premium_v2_test`, `premium_test`, `premium_purchase_test`, `premium_paywall_copy_test`: **65/65**.
- `flutter gen-l10n`: đạt. `flutter analyze` module Premium và hai file test liên quan: đạt.
- Kiểm tra ngoài test: 30 ID mỗi locale thay đổi; tập biến và metadata giữ nguyên; không thay các key ngoài đợt copy so với snapshot bắt đầu. Giữ các thay đổi chưa commit của phiên khác trong ARB và các file khác.

[Trước: màn nâng cấp](assets/2026-10-26-premium-wording/before_pw06_explore_light_vi.png) → [Sau: màn nâng cấp](../../../apps/mobile/test/golden/goldens/pv2/pw06_explore_light_vi.png).

[Trước: thẻ video/thiệp/Lumi](assets/2026-10-26-premium-wording/before_cards_a_light_vi.png) → [Sau](../../../apps/mobile/test/golden/goldens/pv2/cards_a_light_vi.png).

[Trước: thẻ nhịp/dung lượng/người ghi](assets/2026-10-26-premium-wording/before_cards_b_light_vi.png) → [Sau](../../../apps/mobile/test/golden/goldens/pv2/cards_b_light_vi.png).

Đánh giá gates trong phạm vi copy: G1 ý nghĩa, G3 giữ dữ liệu, G4 quyền, G5 không tăng claim, G6 tương tác hiện có đạt theo mã/tests; G2 đạt ở ảnh mặc định, chưa kết luận với screen reader hoặc 200%. Score cho phần copy đã render: clarity 4/5, localisation 4/5, content necessity 4/5; accessibility Not evaluated đầy đủ. Không có lỗi High mới còn mở sau vòng sửa plural. Không có thay đổi L3 hoặc phát hành app trong đợt này.

## Tóm tắt cho chủ sản phẩm

Ba mẹ thấy rõ Premium thêm lượt xuất video, quỹ credit dùng chung, dung lượng và chỗ cho người ghi. Câu chữ nói đúng việc app làm, không hứa “ngay”, “không dừng” hay “một chạm”. Đã áp dụng phần tương ứng trong app; bản wording cho các sheet riêng của phương án Figma ở trên được phân biệt với nội dung đã triển khai.

## Figma đã cập nhật — chờ chủ sản phẩm review

Chủ sản phẩm đã yêu cầu rõ: “sửa trong figma rồi tôi review rồi bạn sẽ triển khai luồng premium v2 này”. Yêu cầu này cho phép ghi Figma cho flow đang xét, vượt quy ước read-only trước đó trong CLAUDE.md; không coi là cho phép sửa toàn bộ file hoặc triển khai ngay.

Đã cập nhật **215 text nodes** trong **10 frame** thuộc [flow 1134:3884](https://www.figma.com/design/sJLG1fAXKDnDr9YI6Yx8ex/Child-Life?node-id=1134-3884). Frame được đặt tên “Premium v2 · Chọn gói & quyền lợi · Review wording”; nhãn canvas ghi “wording chờ review”.

- Đồng bộ câu chữ ở màn năm/tháng, bản toàn trang, màn thanh toán và sáu sheet quyền lợi, bao gồm phần nền phía sau sheet.
- Giá chính gói năm là **599.000đ/năm**; giá quy đổi **khoảng 49.900đ/tháng** ở dòng phụ. Không thay số tiền, chu kỳ hoặc nội dung pháp lý.
- Làm rõ lượt xuất video, credit dùng chung, phạm vi người có quyền ghi; bỏ lời hứa “một chạm”, cập nhật “ngay” hoặc upload không gián đoạn.
- Nút đóng sáu sheet là “Quay lại chọn gói”. Điều chỉnh xuống dòng và căn đáy các sheet để giữ nội dung trong khung 375×812.
- Chỉ override text của instance trong flow; component gốc ngoài flow giữ nguyên. Không đổi liên kết prototype, không tạo hoặc xóa màn.

Kiểm tra: đối chiếu **528 text nodes** với bản trước và tập thay đổi dự kiến, **0 sai khác ngoài dự kiến**; cả bảy sheet có bounds nằm trong màn hình. Đã mở ảnh xuất mới và xem cả 10 màn. Vòng cuối rút gọn nhãn Free của Nhịp thành “Dùng credit trải nghiệm”, rồi xuất và xem lại ảnh.

[Bản trước theo node ID](assets/2026-10-26-premium-wording/figma-before.json) · [Node đã sửa](assets/2026-10-26-premium-wording/figma-write.json) · [Xác minh cuối](assets/2026-10-26-premium-wording/figma-verification.json) · [Ảnh Figma sau sửa](assets/2026-10-26-premium-wording/figma-after.png).

**Trạng thái: chờ chủ sản phẩm review Figma.** Chưa triển khai thêm bố cục danh sách, sheet hoặc luồng thanh toán Premium v2 trong lượt này. Các thay đổi copy trong app từ lượt trước vẫn ở working tree; không xóa hoặc rollback chúng. Việc triển khai flow theo bản Figma sẽ tiếp tục sau khi chủ sản phẩm duyệt.

## Review vòng 2 — Free, quyền lợi nâng cao và dùng chung gia đình

Theo ba góp ý tiếp theo của chủ sản phẩm, đã sửa trực tiếp Figma:

1. Free trong sheet Video ghi **“Chỉ mẫu cơ bản · 2 lượt xuất dùng thử”**; Premium ghi **“Mọi mẫu · 4 lượt xuất/tháng”**. Giữ hạn mức trải nghiệm đã có theo D-101 và giới hạn nó ở mẫu cơ bản; không cấp quyền dùng mẫu Premium cho Free. Sheet Mẫu cao cấp cũng đổi ô Free thành **“Chỉ mẫu cơ bản”**. Không suy diễn góp ý này thành huỷ mọi lượt video hoặc credit Lumi của Free.
2. Quyền lợi thứ tư được làm rõ là **“Gợi ý cá nhân & nhịp nâng cao”**, tương ứng `personalization.cross_module` và `rhythm.advanced`: gợi ý theo tuổi, nhu cầu, phản hồi; nhịp bú/ngủ từ nhật ký khi đủ dữ liệu. Trước đó mô tả quá hẹp thành tóm tắt tuần bằng Lumi. Bảng so sánh giờ ghi Free **“Theo tuổi & lịch tham khảo”**, Premium **“Gợi ý riêng & nhịp nâng cao”**. Không dùng credit trải nghiệm để diễn đạt quyền truy cập nhịp nâng cao. Phần AI vẫn theo quyền và credit Lumi riêng, không gộp mọi gợi ý thành tác vụ AI.
3. Bỏ cả 10 bản của khối “cả nhà dùng chung” nằm riêng trong gói năm. Đưa thông tin dùng chung lên dưới tiêu đề: **“Cả nhà dùng chung, dù chọn gói năm hay gói tháng.”** Tránh ngụ ý gói tháng bị giới hạn dùng riêng.

Đã giữ phần danh sách đang được chỉnh thêm trên PZ01 và đồng bộ wording tương ứng, không xoá danh sách đó. Căn đáy bảy sheet vẫn trong 375×812; đã mở ảnh xuất mới, xem cả hai lựa chọn gói, bản toàn trang, sheet Video và quyền lợi nâng cao. [Ảnh sau review vòng 2](assets/2026-10-26-premium-wording/figma-review-2.png) · [Node đã sửa/xoá](assets/2026-10-26-premium-wording/figma-review-2-write.json).

Vẫn **chờ review Figma**, chưa đổi code app, backend, cấu hình hạn mức hoặc phát hành trong vòng góp ý này.

## Review vòng 3 — gộp thiệp và video

Theo xác nhận “ok gộp đi”, đã gộp hai quyền lợi Video và Mẫu cao cấp thành **Thiệp & video kỷ niệm** trên Figma. Phạm vi L2: gộp trình bày, giữ chức năng thiệp và video cùng hạn mức riêng cho xuất video.

- Tất cả 10 danh sách lặp trong flow (kể cả danh sách chủ sản phẩm thêm trên PZ01) còn **5 mục**. Dòng mô tả mới: “Toàn bộ mẫu cao cấp · 4 lượt xuất video/tháng”.
- Sheet PZ11 `1085:18506` chứa cả hình minh hoạ thiệp và video, tái dùng artwork hiện có. Hai chức năng được giải thích riêng; 4 lượt chỉ dành cho xuất video.
- Gỡ sheet trùng PZ12 `1085:18655`, thu gọn khoảng trống trên canvas, cập nhật nhãn 1/5…5/5, dots và các link trước/sau/vuốt. Kiểm tra **55 link**, không có destination bị mất hoặc link tới PZ12 đã gỡ.
- Cả sáu sheet còn lại (thanh toán + năm quyền lợi) nằm trong màn hình 375×812. Đã mở ảnh mới của cả chín frame và bản toàn trang; không thấy cắt chữ mới.
- Các component gốc ngoài flow giữ nguyên. Chỉ artwork local được clone vào thẻ gộp.

Để prototype chuyển màn hợp lệ qua Plugin API, container Frame cũ `1134:3884` được thay bằng **Section `1153:5491`**, giữ vị trí canvas và ID các màn còn lại. API từ chối cập nhật NAVIGATE giữa các frame lồng trong một frame khác; lần ghi bị từ chối không commit, sau khi chuyển container sang Section thì các link được cập nhật thành công. Link review tổng mới: [Premium v2 · 5 quyền lợi](https://www.figma.com/design/sJLG1fAXKDnDr9YI6Yx8ex/Child-Life?node-id=1153-5491). [Sheet gộp](https://www.figma.com/design/sJLG1fAXKDnDr9YI6Yx8ex/Child-Life?node-id=1085-18506).

[Bản dựng flow sau gộp](assets/2026-10-26-premium-wording/figma-merged-flow.png) · [Sheet gộp](assets/2026-10-26-premium-wording/figma-merged-sheet.png) · [Xác minh](assets/2026-10-26-premium-wording/figma-merge-verification.json).

Lưu ý cho bước triển khai sau review: lúc đọc canvas ở vòng này, ô Free đã được sửa thành **“Chỉ mẫu cơ bản · 2 lượt/tháng”**. Đã giữ nguyên thay đổi đó trên Figma. Runtime/D-101 trước đó là hai lượt trải nghiệm một lần; không tự thay entitlement, nguồn hoặc backend trong đợt gộp này. Cần đối chiếu bản cuối được chủ sản phẩm duyệt trước khi triển khai hạn mức.

Vẫn đang ở bước **review Figma trước triển khai Premium v2**.

## Review vòng 4 — không giới hạn lượt, phân biệt chất lượng video (D-124)

Chủ sản phẩm đổi chính sách: **không giới hạn lượt xuất video cho cả Free và Premium**. Free dùng mẫu cơ bản và xuất **720p**; Premium dùng cả mẫu cao cấp và xuất **Full HD 1080p**. Quyết định được lưu tại D-124 trong business map, thay phần giới hạn số lượt video của D-101. Credit Lumi, số người và dung lượng vẫn là các quyền lợi độc lập.

Đã sửa 14 text nodes trong Figma, gồm 10 bản dòng quyền lợi và các vị trí trong sheet gộp:

- Dòng danh sách: “Toàn bộ mẫu cao cấp · Video Full HD 1080p”.
- Dòng nổi bật trong thẻ: “Xuất video không giới hạn lượt”.
- Chi tiết: “Không giới hạn lượt xuất: Free 720p, Premium Full HD 1080p.”
- Free: “Mẫu cơ bản · Video 720p”.
- Premium: “Mọi mẫu · Full HD 1080p”.

Kiểm tra sau ghi không còn câu hạn mức số lượt video cũ trong section review. Sheet vẫn vừa khung 375×812; đã xuất và mở [ảnh sheet mới](assets/2026-10-26-premium-wording/figma-unlimited-video-sheet.png). Yêu cầu xuất thêm ảnh toàn trang gặp giới hạn số lần gọi của Figma MCP; không có thay đổi nào sau ảnh sheet đã xem. [Các node đã cập nhật](assets/2026-10-26-premium-wording/figma-unlimited-video-write.json).

Chỉ Figma và tài liệu quyết định được cập nhật. Code/contract/renderer/quota ledger chưa đổi; việc triển khai theo chính sách mới vẫn chờ duyệt thiết kế. Chính sách số lượt không tự loại bỏ giới hạn đồng thời, giới hạn đầu vào và cơ chế xử lý lỗi của tác vụ render.
