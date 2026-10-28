# Cùng Chăm Con — bước 1 (28/10/2026)

Quyết định: D-135 (`docs/product/business-map.md`), phân tích `docs/design/explorations/cung-cham-con/ANALYSIS-2026-10-28.md` §10 bước 1. Figma `1349:22026` chỉ dùng làm tham khảo (D-104).

## Tóm tắt cho chủ sản phẩm

- **Khám phá → Gia đình & trợ lý → Cùng Chăm Con** mở lịch chung của bé theo ngày (`/care/together`). Cùng nuôi và Người chăm sóc thấy mục này. Người thân chỉ thấy khi có quyền "Chăm sóc hằng ngày".
- **Lịch trong ngày (04/04b):**
  - Có dải 7 ngày để xem lại. Từ hôm kia trở về trước chỉ xem, không sửa.
  - Thẻ tóm tắt: trước khi có việc nào xong thì ghi "9 việc · Bắt đầu 07:00". Khi đã có việc xong thì hiện vòng tiến độ 3/8, "Còn 5 việc" và việc tiếp theo.
  - Việc được nhóm theo **Sáng / Chiều / Tối**. Đây là nhóm theo giờ, không phải ca.
  - Mỗi thẻ việc có: giờ, tên việc, người làm (chạm để giao) và vòng tròn để đánh dấu đã làm. Việc kế tiếp có viền mint.
  - Việc đã xong ghi rõ ai làm, ví dụ "Ba đã làm" cho một việc Mẹ được giao. Việc bỏ qua bị gạch ngang.
- **Cùng nuôi:**
  - "Giao cả buổi": giao mọi việc của một buổi cho một hoặc nhiều người.
  - "Thêm việc" ở từng buổi.
  - Chạm thẻ để sửa (06b): đổi việc, giờ, người làm, chọn "Chỉ hôm nay / Mọi ngày", bỏ qua hôm nay, xoá.
  - Vuốt trái thẻ để hiện Sửa/Xoá. Lần đầu có tooltip "Vuốt sang trái để sửa hoặc xoá · Đã hiểu", dùng đúng kiểu tooltip của tour Hôm nay.
- **Người chăm sóc:** chỉ đánh dấu đã làm. Không thêm, giao, sửa hay vuốt được.
- **Hôm nay chưa có lịch (04-0):**
  - Cùng nuôi chọn một trong ba cách: "Dùng lịch mọi ngày (n việc)", "Giống hôm qua (n việc)" hoặc "Tự thêm việc".
  - Người chăm sóc thấy "Khi ba mẹ lên lịch, việc sẽ hiện ở đây."
- Đánh dấu một việc là xong **không** tạo bản ghi trong nhật ký chăm sóc, đúng như D-135. Việc nối hai phần này là bước sau.

## Dữ liệu và server

- **Firestore** (chỉ server ghi; ai đọc được chăm sóc thì đọc được lịch):
  - `babies/{b}/carePlanDays/{yyyy-mm-dd}` (có `revision`) và `…/items/{pi_…}`
  - `carePlanTemplate/{pt_…}` (các việc "Mọi ngày")
  - `carePlanHistory` (ai sửa gì, lúc nào; dùng cho màn 20 sau này)
- **Callable** (`firebase/functions/src/care-plan.ts`, schema ở `packages/contracts/src/care-plan.ts`):
  - `startCarePlanDay` (mọi ngày / hôm qua / trống; gọi lặp lại không tạo trùng; bỏ người đã rời gia đình)
  - `saveCarePlanItem` (hôm nay hoặc mọi ngày)
  - `deleteCarePlanItem` (hôm nay hoặc mọi ngày; gọi lặp lại vô hại)
  - `assignCarePlanItems` (một việc hoặc cả buổi)
  - `setCarePlanItemStatus` (đã làm / chưa làm / bỏ qua)
- **Quyền mặc định theo vai trò:**
  - Cùng nuôi: quản lý lịch.
  - Người chăm sóc: chỉ đánh dấu đã làm.
  - Người thân: không có quyền với lịch, và không được giao việc.
  - Quyền chỉnh theo từng người (màn 13) là bước sau.
- **Giới hạn:**
  - Chỉ sửa được từ hôm qua tới 6 ngày tới, theo múi giờ của bé.
  - Tối đa 40 việc mỗi ngày và 6 người cho một việc.

## Simplify (so với Figma)

| Phần trong Figma | Quyết định | Lý do |
|---|---|---|
| Chip đếm việc theo từng người ("Ba · 4", "Cô Lan xong 2") ở thẻ tóm tắt | Bỏ | D-135 Q8 không so người với người. Số việc của mỗi người vẫn có trong sheet Giao việc, nơi cần để chia việc |
| "Còn 7 việc nữa thôi, cả nhà cố lên!" | Thay bằng "Còn 5 việc" kèm việc tiếp theo | Trả lời đúng câu hỏi của người đọc, không thêm lời cổ vũ |
| Avatar minh hoạ người trong chip | Chỉ hiện tên ("Ba và Mẹ") | App chưa có avatar minh hoạ cho từng người. Chữ cái đầu đặt cạnh tên chỉ nói lại tên |
| Biểu đồ và nút cài đặt trên thanh tiêu đề | Chưa làm | Đích đến (báo cáo 11, cài đặt 13) thuộc các bước sau |
| "Giao cả ca" | Đổi thành "Giao cả buổi" | D-135: Sáng/Chiều/Tối không phải ca |
| Nút + nổi (04b) | Không thêm | Đã có "Thêm việc" ở từng buổi. Việc "ghi ngoài lịch" thuộc phần nhật ký chăm sóc |

## Component

- **`ClTourTip`:** `step`, `body` và nút bỏ qua giờ là tuỳ chọn, nên tooltip một bước dùng chung bong bóng của tour Hôm nay. Các chỗ đang gọi không đổi gì.
- **Mới: `ClSwipeActions`** (`core/widgets/cl_swipe.dart`): vuốt trái để hiện các hành động; mỗi hành động cũng là custom action cho trình đọc màn hình.
  - Vuốt chỉ là lối tắt: Sửa/Xoá luôn có trong sheet khi chạm thẻ.
  - Chưa có mục trong showcase, vì một hàng ở trạng thái đóng không cho thấy gì. Trạng thái mở cũng chưa có golden riêng.
- **Thẻ việc, chip người làm, vòng đánh dấu, vòng tiến độ:** để trong `features/care_plan/care_plan_widgets.dart` để Home (bước 2) dùng lại, không tạo bộ widget riêng nữa.

## Kiểm chứng

- **Golden mới `test/golden/goldens/care_plan/`:** 8 trạng thái × Light/Night × vi/en = 32 ảnh. Trạng thái: lịch mới, đang làm, người chăm sóc, 04-0 cho cha mẹ, 04-0 cho người chăm sóc, Giao cả buổi, Thêm việc, Sửa việc.
  - Đã mở xem bằng mắt: plan_fresh/underway (light vi), plan_underway night en, plan_caregiver light vi, assign_group light vi, add_task light vi, start_parent light en, start_caregiver night vi, edit_task night vi và light en.
- **Test hành vi `test/features/care_plan_test.dart`:** 13 test pass.
  - Đánh dấu đã làm và hoàn tác.
  - Phân quyền Người chăm sóc.
  - 04-0 cho cha mẹ và người chăm sóc.
  - Thêm việc "Mọi ngày".
  - Giao cả buổi bị khoá khi chưa chọn ai.
  - Bỏ qua và xoá việc "Mọi ngày".
  - Tooltip chỉ hiện một lần.
  - Khám phá theo vai trò.
  - Chữ 200 % (vi/en) không tràn.
- **Firebase emulator:**
  - `firebase/tests/care-plan.integration.test.ts`: 11 test pass (ngày theo múi giờ của bé, bắt đầu ngày, mọi ngày / hôm qua, quyền, người được giao, xoá theo phạm vi, giao cả buổi, đã làm / bỏ qua, lịch sử).
  - `care-plan.rules.test.ts`: 2 test pass.
- `flutter analyze` sạch; typecheck và eslint phía TS sạch.

## Còn lại và giới hạn

- **Không có mạng:** thao tác báo lỗi bằng toast. Chưa có hàng đợi offline như nhật ký chăm sóc.
- **Hình minh hoạ:** Tắm, Đọc sách và các việc ngoài nhóm chăm sóc dùng icon trên nền màu. Figma có hình riêng (CCC/Art), cần xuất SVG sau.
- **Chưa làm (các bước sau):**
  - Home (section Việc cần làm, sheet "Đến giờ rồi"), push nhắc việc, cài đặt 13.
  - Home người hỗ trợ và bàn giao theo ca.
  - Chọn cách lên lịch 01/02 và tự tạo lịch mỗi sáng.
  - Cảm ơn và lịch sử thay đổi 20.
  - Widget, báo cáo.
- **Chưa deploy dev:** callable và rules mới cần `scripts/deploy.sh dev functions,firestore` trước khi dùng thật trên máy.
- **Chưa kiểm:** VoiceOver/TalkBack trên máy thật.
