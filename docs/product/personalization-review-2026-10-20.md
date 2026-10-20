# Review cá nhân hoá Child Life — 20/10/2026

**Đã hợp nhất vào [kế hoạch cá nhân hoá v2](personalization-v2-plan.md) ngày 20/10/2026 theo yêu cầu
người dùng.** Dùng bản v2 để theo dõi phạm vi, thứ tự triển khai và câu hỏi còn mở. Bản review này giữ
lại nhận định và bằng chứng tại thời điểm kiểm tra; lộ trình bên dưới là đề xuất đầu vào, không phải kế hoạch song song.

Đánh giá từ code trong workspace và kế hoạch `personalization-v2-plan.md`. Đây là đề xuất sản phẩm, chưa phải quyết định D-xxx hay cam kết triển khai. Không kiểm tra phiên bản đang chạy trên thiết bị hoặc dữ liệu Firebase trực tiếp. Các thay đổi Lumi đang có trong workspace được xem là code hiện tại, không suy ra đã phát hành.

## Nhận định chính

Nền tảng đã có: sở thích riêng của từng người, nội dung theo tuổi, gợi ý theo nhu cầu vừa ghi nhận, phản hồi sau khi thử, phân tích giấc ngủ và các quy tắc ăn dặm. Giá trị tiếp theo nên là **giảm việc phải nhớ, giúp chọn một việc phù hợp lúc này và giúp người chăm tiếp nắm tình hình**.

Bản v2 ngày 19/10 đã đề xuất đúng các mảng nhật ký → nhịp sinh hoạt, sổ tay, feed chung và phản hồi. Review này bổ sung điều kiện để chúng hữu ích, sửa thứ tự ưu tiên và nêu các hành vi code cần xem lại. Chưa có nghiên cứu người dùng để kết luận mức độ hữu ích thực tế.

## Phát hiện từ code

| Mức | Phát hiện và bằng chứng                                                                                                                                                                                                                         | Ảnh hưởng                                                                                                                                                                                               | Hướng xử lý                                                                                                                              |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| P1  | `firebase/functions/src/rhythm.ts:570` chọn recommendation mới nhất thuộc trạng thái active; `rhythm_home.dart:134` không kiểm tra tuổi của recommendation. Luồng đọc này chưa kiểm tra lại tuổi phù hợp hoặc trạng thái xuất bản của activity. | Gợi ý từ nhu cầu trước có thể tiếp tục nằm trong mục hôm nay khi không có check-in mới; nội dung thay đổi điều kiện có thể vẫn được tham chiếu. Đây là rủi ro từ đọc code, chưa tái hiện trên thiết bị. | Có hạn dùng theo loại gợi ý; kiểm tra eligibility khi đọc; tách việc đang thử với lời mời bắt đầu mới. Kiểm tra cache/offline tương ứng. |
| P1  | `digestTime` được lưu trong preferences, hiển thị ở cài đặt; tìm toàn bộ `apps/mobile/lib` và `firebase/functions/src` chưa thấy consumer lập lịch digest. `rhythm_local.dart` có nhắc giai đoạn và check-in buổi tối riêng.                    | Người dùng chọn giờ nhưng chưa nhận đúng giá trị được hứa.                                                                                                                                              | Kết nối lựa chọn với một bản tin có ích, có quyền thông báo và công tắc rõ ràng; hoặc bỏ câu hỏi cho tới khi tính năng sẵn sàng.         |
| P1  | `feedbackMemory()` gộp phản hồi mọi tác giả theo bé; `not_suitable` loại activity cho bé (`personalization.ts:300,416`).                                                                                                                        | Một người không thích hoặc không có thời gian có thể làm cả nhà mất gợi ý. Đây là hành vi có chủ đích theo brief, cần cải tiến sản phẩm thay vì coi là lỗi đơn thuần.                                   | Phân biệt “hôm nay bận”, “tôi không thích” và “không phù hợp với bé”; chỉ loại toàn gia đình khi đúng phạm vi, cho xem và khôi phục.     |
| P2  | `fewer` loại chủ đề khỏi carousel (`today_for_baby.dart`, `rankForBabyCards`), nhưng trong `recommend()` chỉ ảnh hưởng điểm sở thích (`personalization.ts:401`).                                                                                | “Ít kiểu này hơn” tạo trải nghiệm khác nhau giữa các vùng gợi ý.                                                                                                                                        | Quy định rõ giảm tần suất hay ẩn chủ đề, dùng thống nhất; nội dung quan trọng có lý do riêng để vẫn xuất hiện.                           |
| P2  | Carousel chung mới nhận milestone và library. Ăn dặm có engine riêng; nhịp, dinh dưỡng, nhắc việc chưa cùng một cơ chế chọn ưu tiên ở đây.                                                                                                      | Từng module có thể đúng nhưng tổng thể vẫn nhiều lời nhắc hoặc thiếu việc quan trọng nhất.                                                                                                              | Ghép kết quả của các engine bằng một lớp điều phối; giữ luật chuyên môn ở module nguồn.                                                  |
| P2  | `NextActionAnswer.sleep` là insight nhật ký trong luồng cá nhân hoá; các event funnel `checkinSaved`, `nextActionShown`, `suggestionStarted`, `feedbackSaved`, `capabilityGateSeen` chưa có nơi gọi trong Dart khi tìm theo tên.                | Chưa thấy được người dùng nhận, thử và được giúp ra sao. Lumi hiện có thêm khả năng đọc dữ liệu; không nên diễn giải điều này thành toàn ứng dụng chỉ biết giấc ngủ.                                    | Hoàn thiện đo lường tối thiểu và kết nối dữ liệu nhật ký vào Home; không gửi dữ liệu trẻ vào analytics.                                  |

## Các tính năng nên ưu tiên

### 1. “Điều hữu ích nhất lúc này” — P1

Một thẻ chính, tối đa hai thẻ phụ cho thử nghiệm đầu. Mỗi thẻ có: việc gì, vì sao xuất hiện, làm trong bao lâu, một hành động và cách bỏ qua. Thứ tự kế thừa brief: hỗ trợ sức khoẻ → nhắc việc gia đình đã đặt → nhu cầu hiện tại → nhịp của bé → nội dung phát triển/kỷ niệm.

Ví dụ minh hoạ: “Bạn có 3 phút? Chọn một trò chơi ngắn trong thư viện cho giai đoạn của bé.” Bấm là mở đúng hoạt động; không bắt người dùng tìm lại trong danh mục.

Điều kiện nhận: thẻ đã làm không trở lại dưới dạng việc chưa làm; một sự kiện không tạo nhiều thẻ từ nhiều module; đổi bé không lẫn dữ liệu; thiếu thông tin vẫn có nội dung theo tuổi với lý do đúng nguồn.

### 2. “Hôm nay nhà mình thế nào?” — P1, bổ sung cho v2

Cho chọn nhanh, không bắt buộc: chỉ có vài phút / đang bận / người khác chăm / sinh hoạt khác thường. Đây là hoàn cảnh tạm thời, tự hết hạn, không trở thành hồ sơ tính cách của người dùng.

Kết hợp mục tiêu tuần do gia đình chọn, ví dụ “bàn giao dễ hơn” hoặc “có một lúc chơi cùng con”. Chỉ hỏi thêm khi câu trả lời thay đổi được gợi ý. “Đang bận” làm giảm lượng nội dung và ưu tiên thao tác ngắn.

Điều kiện nhận: không thêm biểu mẫu onboarding dài; giới hạn thời gian của activity phải thực sự được dùng để lọc; luôn có nút bỏ qua và đổi lại.

### 3. “Nhịp riêng của con” có mức độ chắc chắn — P1 sau nền tảng dữ liệu

Phát triển A1–A4 của v2: dùng lịch sử của chính bé để trình bày một khoảng thường gặp, kèm số ngày có dữ liệu và ngày cập nhật. Tránh hiển thị một thời điểm chính xác khiến người dùng hiểu thành lịch phải theo.

Ví dụ giao diện minh hoạ: “Trong những ngày có ghi đủ, khoảng cách giữa các lần ghi bú thường nằm trong khoảng …”. Phải phân biệt thời điểm được ghi với thời điểm thực tế và giải thích khi dữ liệu chưa đủ.

Điều kiện nhận: ghi thiếu không được hiểu thành bé ăn/ngủ ít; bản ghi trùng, timer quên tắt và ngày ghi thiếu không làm méo kết quả; tạm dừng dự báo khi gia đình báo sinh hoạt khác thường. Không biến suy đoán thành nhắc việc nếu người dùng chưa chọn. Luật liên quan sức khoẻ giữ quy trình duyệt chuyên môn hiện có.

### 4. “Bàn giao trong 30 giây” — P1, mở rộng thứ đã có

Tái sử dụng handover hiện tại, thêm trạng thái tác nghiệp: lần ghi gần nhất, việc gia đình đã đặt sắp tới, ghi chú cần biết và xác nhận đã nhận bàn giao. Người nhận chỉ thấy phần được phân quyền.

Một việc có trạng thái rõ “chưa nhận / đã nhận / hoàn tất” để giảm hai người cùng làm hoặc cùng nghĩ người kia làm. Thời điểm và tên người xác nhận phải rõ; offline hiển thị trạng thái chờ đồng bộ. Đây là mở rộng phối hợp, không chỉ thêm một đoạn AI tóm tắt.

Điều kiện nhận: kiểm tra hai thiết bị nhận cùng một việc, đổi quyền, sửa/xoá bản ghi sau bàn giao; không tự giao việc hay tự gửi thông báo tới người khác từ nội dung trò chuyện.

### 5. “Sổ tay nhà mình” có quyền sửa và thời hạn — P2

Giữ E1–E3 của v2, thêm nguồn ghi chú, ai xác nhận, ngày cập nhật, thời hạn nếu là thông tin tạm thời và phạm vi áp dụng. Tách sự thật gia đình ghi, sở thích của một người và ràng buộc cần tránh.

Lumi đề nghị lưu từ lời người dùng, cho xem nội dung và xác nhận trước. Thông tin cũ hoặc mâu thuẫn cần được hỏi lại khi liên quan; không tự chọn một phiên bản. Ghi chú tự do không tự trở thành ràng buộc chuyên môn.

Điều kiện nhận: người dùng xem được “điều đang dùng để cá nhân hoá”, sửa/xoá/khôi phục theo quyền; không lưu nhận xét suy đoán về tính cách hoặc cảm xúc; chuyển bé không dùng nhầm ghi chú.

### 6. “Sau khi thử” và “Tuần này điều gì hữu ích?” — P2

Tách “định thử”, “đã thử”, “đã làm xong” và “thấy có ích”. Hỏi lại đúng thời điểm, tối đa một câu, có “chưa thử”. Không tính bấm mở là đã làm, không tính không trả lời là không thích.

Tổng kết tuần cho xem: gia đình đã chọn gì, đã thử gì, muốn giữ gì cho tuần sau. Nếu kèm số liệu nhật ký, mô tả quan sát; không kết luận một hoạt động đã làm bé ngủ hoặc ăn tốt hơn từ dữ liệu trước/sau.

Điều kiện nhận: mỗi lần bỏ qua chỉ cần tối đa hai thao tác; có phản hồi “đã biết rồi”, “không có thời gian”, “không hợp với bé” và hệ thống thay đổi đúng phạm vi.

## Điều chỉnh kế hoạch v2

- Đưa độ mới của recommendation, phạm vi feedback và đo lường tối thiểu vào đợt đầu.
- Dời dự báo nhịp sinh hoạt sang sau khi xác minh dữ liệu đủ tin cậy. Năm mẫu có thể là điều kiện để bắt đầu xem xét, chưa tự chứng minh một dự báo hữu ích.
- Với thông báo, thử bản tin tuỳ chọn, giới hạn tổng theo người qua các bé/module và không gửi khi không có gì mới. Không xếp thêm bản tin thứ Hai lên tổng kết Chủ nhật nếu nội dung trùng.
- Với local notification, không hứa “luôn là việc mới nhất” khi app không mở. Cần thời hạn cho nội dung đã lập lịch; khi mở phải kiểm tra lại dữ liệu. Nếu cần kiểm tra tại giờ gửi, đánh giá server push theo quyền và hạ tầng hiện có.
- Bổ sung hoạt động ngắn và nội dung cho giai đoạn còn mỏng song song với feed. Engine không bù được thư viện thiếu nội dung phù hợp.
- Chưa nên chốt timeline 12 tuần của v2 thành cam kết; còn phụ thuộc kiểm tra dữ liệu, UX phối hợp nhiều người, duyệt nội dung và kiểm thử thiết bị.

## Thứ tự triển khai đề nghị

| Đợt | Phạm vi                                                                          | Kết quả cần chứng minh trước khi mở rộng                                                |
| --- | -------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| 1   | Độ mới/eligibility, phạm vi feedback, đo lường, khép kín lựa chọn giờ nhận gợi ý | Gợi ý đúng ngữ cảnh, bỏ qua có tác dụng, không gửi trùng/cũ; quan sát được funnel thật. |
| 2   | Feed một việc chính, hoàn cảnh tạm thời, nhịp riêng có chất lượng dữ liệu        | Gia đình tìm được việc hữu ích nhanh; người ít ghi nhật ký vẫn nhận giá trị.            |
| 3   | Bàn giao có trạng thái, sổ tay, theo dõi sau khi thử và tổng kết tuần            | Người chăm tiếp hiểu việc cần làm; không phải kể lại; phản hồi cải thiện lần sau.       |

Đề xuất giữ miễn phí các tính năng giúp đọc lại dữ liệu của gia đình, kiểm soát gợi ý, phối hợp cơ bản và hỗ trợ sức khoẻ. Phần phân tích dài hạn và tổng hợp AI có thể đánh giá cho gói nâng cao sau khi chứng minh giá trị; đây chưa phải quyết định giá.

## Đo tính hữu ích

Chỉ số chính đề nghị: tỷ lệ gia đình tham gia beta xác nhận có ít nhất một tình huống cụ thể được ứng dụng giúp trong tuần. Ghi rõ mẫu số, số người trả lời và nhóm sử dụng; chưa gán chỉ tiêu phần trăm khi chưa có baseline.

Chỉ số hỗ trợ:

- Thời gian tìm thấy và thực hiện việc cần làm trong bài kiểm tra tác vụ.
- Tỷ lệ xem → định thử → xác nhận đã thử → thấy có ích; báo cáo cả tỷ lệ trả lời.
- Tỷ lệ gợi ý sai hoàn cảnh, lặp, quá cũ và bị ẩn; phân tách theo nhóm tính năng.
- Tỷ lệ tắt thông báo, số thông báo/người/ngày và phản hồi về làm phiền.
- Tỷ lệ bàn giao được người nhận hiểu đúng mà không phải hỏi lại, đo bằng thử nghiệm tác vụ/phỏng vấn.
- Khác biệt giữa gia đình ghi nhiều/ít và có một/nhiều người chăm.

Thử với 20–30 gia đình trong hai tuần có thể giúp tìm vấn đề định tính; chưa đủ tự chứng minh hiệu quả dài hạn. Không tối ưu số bản ghi hoặc thời gian ở trong app làm mục tiêu chính. Thiết kế analytics theo quy tắc không chứa dữ liệu trẻ; nghiên cứu tự nguyện dùng cơ chế đồng ý riêng, không nối danh tính bé vào event.

## Kiểm chứng và tài liệu tham khảo

Đã chạy `pnpm --filter @child-life/contracts exec vitest run test/rhythm.test.ts test/rhythm-content-seed.test.ts`: **2 file, 49 test đạt**. Đây là kiểm tra engine/seed hiện có; chưa xác minh trải nghiệm, luồng notification, Rules hay hành vi đa thiết bị. Không sửa code ứng dụng trong review này.

Các khuyến nghị UX ở trên là suy luận áp dụng cho Child Life từ code và các nguyên tắc sau; không phải bằng chứng rằng tính năng đã hiệu quả với người dùng Child Life:

- [Google PAIR — User Needs + Defining Success](https://pair.withgoogle.com/chapter/user-needs/): bắt đầu từ vấn đề và lợi ích người dùng, cân nhắc lúc nào quy tắc đơn giản đủ dùng.
- [Google PAIR — Feedback + Control](https://pair.withgoogle.com/chapter/feedback-controls/): phản hồi cần tác dụng dễ hiểu và quyền điều chỉnh.
- [Google PAIR — Explainability + Trust](https://pair.withgoogle.com/chapter/explainability-trust/): giải thích dữ liệu, giới hạn và mức độ không chắc chắn trong bối cảnh quyết định.
