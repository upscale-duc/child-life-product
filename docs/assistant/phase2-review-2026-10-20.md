# Lumi Phase 2 — bàn giao review (20/10/2026)

Trạng thái: đã triển khai trong workspace, chờ Claude review. Theo yêu cầu tiếp theo của owner ngày 20/10/2026, đã deploy backend dev và cài / mở bản release dev trên iPhone Duckie. Chưa deploy prod; chưa kiểm tra thủ công toàn bộ các luồng trên thiết bị thật. Phạm vi là Phase 2 / L3 của `docs/product/lumi-plan.md` §5; không mở rộng các thao tác ghi thuộc Phase 3.

## Hành vi đã bổ sung

- Tổng hợp ngày: bú bình, bú mẹ, giấc ngủ đã kết thúc, tã, hút sữa, bản ghi gần nhất của từng loại và timer đang chạy. Giấc ngủ qua nửa đêm chỉ tính phần nằm trong ngày của bé.
- Tã và hút sữa: hôm nay, hôm qua hoặc 7 ngày; liên kết Lịch sử giữ nguyên bộ lọc.
- Tăng trưởng: số đo gần nhất riêng cho cân nặng / chiều dài / vòng đầu, thay đổi so với lần đo trước và percentile WHO ở **tuổi khi đo**. Dùng cùng bảng LMS với ứng dụng, không suy đoán giới tính, không chẩn đoán.
- Timer: đọc ngủ / bú mẹ / hút sữa, chọn đúng hoạt động được hỏi; thời lượng là snapshot tại thời điểm gửi, mở timer để xem trực tiếp.
- Tiêm chủng: đọc lựa chọn của gia đình, lịch quốc gia / bản tham chiếu đã xuất bản, bỏ mũi đã tiêm hoặc từ chối, giữ ngày đã dời lịch. Quốc gia chưa có lịch được ghi rõ là dùng lịch Việt Nam tham khảo.
- Nhắc việc: các việc trong ngày, cả ngày / có giờ, trạng thái và người phụ trách; bổ sung lần nhắc kế tiếp trong ngày của quy tắc đang bật.
- Chi tiêu: tổng tháng và danh mục, tách riêng từng loại tiền; ngân sách / phần còn lại của tháng hiện tại nếu đã thiết lập. Không cộng các bé khác và không quy đổi tiền.
- Ăn dặm: nguyên liệu đã thử, lần thử và dấu hiệu sau ăn từ nhật ký thật; bỏ bữa đã xoá, gộp tên tự nhập trùng tên / từ đồng nghĩa trong danh mục.
- `meal_ideas`: dùng thực phẩm đã thử để xếp món, đối chiếu nguyên liệu / nhóm dị nguyên từng có dấu hiệu, thực phẩm đã ẩn / được cho ăn lại, tuổi, cách cho ăn và nội dung đã được duyệt. Bộ công thức cũ cũng nhận các alias nguyên liệu, không còn placeholder trả mảng rỗng.
- Mốc: mốc đã ghi nhận và mốc tham khảo quanh tuổi / sắp tới theo cùng cửa sổ lịch với module Mốc; Giai đoạn chọn theo tuổi và audience.
- Thư viện: tối đa 3 bài đã xuất bản, lọc tuổi và quốc gia, xếp theo chủ đề. `countries` là metadata tuỳ chọn của bài / công thức: thiếu hoặc rỗng = dùng chung quốc tế; có danh sách = chỉ khớp quốc gia đó. Không cần di trú dữ liệu cũ.
- Sơ cứu: giữ nhánh hỗ trợ sức khoẻ miễn phí trước model và consent; thêm hướng dẫn từ pack đã xuất bản, mở `/utilities/first-aid` thay vì `/rhythm/health`. Nội dung chưa duyệt được gắn nhãn; số khẩn cấp trong thẻ dựa trên quốc gia đã cấu hình.

## Cấu trúc để review

| Phần                                                    | Tệp chính                                                                                                                                                           |
| ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Tên công cụ, nhận diện câu hỏi, schema `read_card`      | `packages/contracts/src/assistant-reads.ts`                                                                                                                         |
| Schema understanding, quyền riêng tư của task           | `packages/contracts/src/assistant-understanding.ts`, `assistant.ts`                                                                                                 |
| Metadata quốc gia                                       | `packages/contracts/src/content.ts`, `solids.ts`                                                                                                                    |
| Đọc dữ liệu / kiểm quyền từng module                    | `firebase/functions/src/assistant-reads.ts`                                                                                                                         |
| Nhật ký ăn dặm / đối chiếu nguyên liệu                  | `firebase/functions/src/assistant-solids.ts`, `assistant-care.ts`                                                                                                   |
| WHO và generator từ dữ liệu app                         | `firebase/functions/src/assistant-growth.ts`, `scripts/generate-assistant-growth.mjs`                                                                               |
| Đường đi miễn phí / model fallback / chuyển luồng riêng | `firebase/functions/src/assistant.ts`, `assistant-worker.ts`, `assistant-model.ts`                                                                                  |
| DTO, thẻ, allowlist link, chọn đúng bé khi mở module    | `apps/mobile/lib/features/assistant/assistant_models.dart`, `assistant_cards.dart`, `assistant_read_links.dart`, `assistant_screens.dart`, `assistant_widgets.dart` |

Các câu hỏi được nhận diện toàn bộ bằng luật chạy trước cổng model, không cần provider, `assistant_live` hay lượt còn lại; vẫn yêu cầu consent trừ nhánh sức khoẻ. Câu pha trộn với ghi nhật ký / câu lạ đi qua understanding. Các công cụ đọc được model chọn vẫn dùng cùng kiểm quyền và dữ liệu thật; đã bỏ lời diễn đạt bằng model sau khi đọc số liệu. Prompt/schema version: `assistant-understand-v2`.

Admin SDK không dựa vào quyền của client: kiểm quyền trước khi đọc collection. Quyền xem chăm sóc không cấp quyền xem nhắc việc, mốc cá nhân hay toàn bộ chi tiêu. Chỉ có quyền ghi chi tiêu của mình không được xem tổng toàn bộ. Mốc cá nhân chỉ cho Cùng nuôi; cả mốc và chi tiêu luôn ở luồng riêng. Nếu model mới phát hiện đây là câu hỏi riêng tư, transaction chuyển task và tin nhắn của nó trước khi ghi kết quả vào hội thoại.

Thẻ có thời điểm snapshot, source ids, ghi chú độ bao phủ và liên kết do server tạo. Client kiểm tra allowlist đường dẫn và query; không nhận URL ngoài, query đổi bé hoặc điều hướng tuỳ ý. Khi mở module, ứng dụng chọn bé gắn với task trước, thay vì dùng nhầm bé đang được chọn ở Hôm nay.

## Kiểm chứng

- Contracts: toàn bộ suite.
- Functions: toàn bộ suite; có một test bị skip sẵn trong suite.
- Firestore emulator: `assistant-reads.integration.test.ts` và năm bộ hồi quy assistant / care / text / timers / speed. Không dùng model thật, không phát sinh chi phí model.
- Flutter: tất cả `test/features/assistant*_test.dart` và `lumi_test.dart`; bao gồm thẻ Light / Night care và điều hướng chọn đúng bé.
- TypeScript workspace typecheck, Flutter analyze, ESLint và Prettier cho phần thay đổi.

Kết quả cuối: **568 contracts**, **474 functions** (1 test skip sẵn), **136 kiểm thử tích hợp** trên emulator, **243 kiểm thử Flutter của Lumi** đều qua. `flutter analyze`, ESLint và Prettier cho phần thay đổi đều qua. Workspace `pnpm typecheck` và Functions build cũng đều qua.

Các test mới nằm ở:

- `packages/contracts/test/assistant-reads.test.ts`
- `firebase/functions/test/assistant-reads.test.ts`
- `firebase/tests/assistant-reads.integration.test.ts`
- `apps/mobile/test/features/assistant_reads_test.dart`

## Khi đưa lên dev sau review

Cần bản mobile hiểu `read_card`; app cũ sẽ dùng cơ chế placeholder cho part chưa hỗ trợ. Nên đưa mobile và Functions của thay đổi này lên cùng đợt kiểm tra. Không thêm Firestore index hay Rules: các truy vấn dùng index đã có và kiểm quyền ở server.

Kiểm tra thiết bị thật còn lại là bước xác nhận bản phát hành: iOS / Android, tiếng Việt / Anh, mạng chậm / reconnect và mở từng module từ chat. Chưa chạy live model eval cho prompt v2; các phép tính, quyền đọc, đường đi miễn phí và model fallback đã có kiểm thử tự động. Những giới hạn này không được ghi là “đã kiểm tra trên dev”.

## Deploy lên máy Duckie (20/10/2026)

- Môi trường: `child-life-dev`; chỉ cập nhật `startTask`, `submitClarification`, `runAssistantTask`. Firebase CLI báo deploy thành công; Cloud Functions xác nhận cả ba `ACTIVE`.
- Revisions: `starttask-00016-bof`, `submitclarification-00014-vep`, `runassistanttask-00014-tid`.
- Smoke backend: POST warm-up của `startTask` trả HTTP 200, `{"result":{"warm":true}}`; không truy cập dữ liệu gia đình hoặc gọi model.
- Thiết bị: **Duckie’s iPhone 14 Pro Max**. Đã build bằng `flutter build ios --flavor dev --release`, kiểm tra chữ ký, bundle `dev.hsba.app`, Firebase project `child-life-dev`.
- Đã cài đè và mở **Child Life Dev**, phiên bản `1.0.0 (1)` bằng `devicectl`; không gỡ app, không xoá dữ liệu.
- SHA-256 binary Runner: `1c491cbe709ce88e841f6ade5fb30c86a71da974824e6bf23038f46aa618765a`.
- Xác nhận cài / khởi động là kiểm tra thiết bị của lượt deploy này; chưa thay thế kiểm tra các câu hỏi Lumi bằng tài khoản thật, Android, reconnect hoặc live model eval.
