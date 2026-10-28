# Cùng Chăm Con — bước 4 (28/10/2026)

Quyết định: D-136 (chủ sản phẩm trả lời 3 câu hỏi bước 4) và D-135 trong `docs/product/business-map.md`. Phân tích: `docs/design/explorations/cung-cham-con/ANALYSIS-2026-10-28.md` §1, §6, §10 bước 4. Nội dung lịch mẫu: `docs/design/explorations/cung-cham-con/templates-draft.md`. Các bước trước: `2026-10-28-cung-cham-con-step1.md` … `step3.md`.

## Tóm tắt cho chủ sản phẩm

- **Chọn cách lên lịch (01a/01b/01c) gộp vào màn "Hôm nay chưa có lịch" (04-0)**, không thêm màn mới. Bố mẹ thấy:
  1. **Theo nhịp của bé** · "Bú và ngủ, từ 7 ngày ghi gần đây". Chỉ hiện khi đủ 7/7 ngày trước đó đều có ghi bú và ngủ (D-136 #2).
  2. Dùng lịch mọi ngày, Giống hôm qua (như cũ).
  3. **Lịch mẫu (chờ duyệt):** Lịch cơ bản theo tuổi, EASY 3.5, EASY 4, kèm dòng "Lịch mẫu không phải lịch y tế…". **Chỉ có trên bản dev**; server cũng từ chối ngoài dev (D-136 #1). EASY chỉ hiện khi bé **dưới 6 tháng** (D-136 #4); bé lớn hơn chỉ thấy Lịch cơ bản theo nhóm tuổi của mình.
  4. Tự thêm việc.
- **Bản nháp (02):** "Theo nhịp của bé" và lịch mẫu tạo **bản nháp**. Trên đầu lịch có khối "Bản nháp · chưa nhắc ai", nút chính **Dùng lịch này** và liên kết **Đổi cách khác**. Trong bản nháp vẫn sửa, thêm, giao việc như lịch thường, nhưng chưa có vòng đánh dấu và chưa có viền "việc kế tiếp".
  - Người hỗ trợ và người thân **không thấy bản nháp** (thấy "Khi ba mẹ lên lịch, việc sẽ hiện ở đây").
  - Việc trong bản nháp không lên Hôm nay, không lên thẻ ca người hỗ trợ, không được nhắc (N1), không tính vào "Còn n việc chờ bố mẹ" của bàn giao.
  - "Đổi cách khác" liệt kê các cách còn lại (bỏ cách vừa dùng) và "Giữ bản nháp này". Chọn cách khác thì thay bản nháp; đã "Dùng lịch này" thì lịch không bị thay.
- **Tự tạo lịch mỗi sáng + N5 (D-136 #3):** trong cài đặt Cùng Chăm Con có phần **Cả nhà · Tự tạo lịch mỗi sáng**, chỉ người quản lý lịch thấy, **mặc định tắt**. Khi bật: từ **06:30** giờ của bé (sau giờ yên lặng mặc định 22:00–06:00), nếu hôm nay chưa có lịch, server tạo **bản nháp** theo cách nhà mình lên lịch gần nhất, rồi gửi mỗi người quản lý lịch một push: "Lịch của Teddy đã sẵn · 8 việc · bắt đầu 07:00 Bú bình. Xem rồi chọn Dùng lịch này nhé." Chạm push mở lịch ngày đó.

## Simplify

| Phần | Quyết định | Lý do |
|---|---|---|
| Màn 01a/01b/01c riêng | Gộp vào 04-0 | Cùng một câu hỏi "bắt đầu hôm nay thế nào"; bớt một màn và một lần chạm |
| Màn 02 Xem trước riêng | Dùng chính màn lịch ở trạng thái nháp | Xem trước mà sửa được ngay; không có hai bản giao diện của cùng danh sách việc |
| 01c "Tự tạo, chỉ hỏi 2 mốc giờ" | Không làm; giữ "Tự thêm việc" | Hai mốc giờ không đủ tạo việc cụ thể; thêm việc từng buổi đã có |
| "Theo nhịp" khi chưa đủ dữ liệu | Ẩn hẳn | D-110: không hiện lựa chọn không dùng được |
| Việc thay tã trong bản nháp | Không tạo | Thay tã theo bé, không theo giờ |

## Dữ liệu và server

- `carePlanDays/{date}` có `status: draft | published` (không có = đang dùng), `source` là cách tạo. Việc trong bản nháp có `draft: true`; `ringCareTaskReminders` bỏ qua chúng.
- `startCarePlanDay` nhận thêm `rhythm`, `basic`, `easy35`, `easy4`. Bốn cách này tạo bản nháp; ngày nháp bắt đầu lại bằng cách khác thì thay việc. Lỗi `not-enough-data` (chưa đủ 7/7 ngày) và `template-unavailable` (ngoài dev). Cách tạo (trừ `empty`) được lưu ở `carePlanSettings/family.method`.
- Mới: `publishCarePlanDay` (Dùng lịch này, người quản lý), `setCarePlanAutoDraft` (người quản lý), scheduler `draftCarePlanMornings` mỗi 15 phút (06:30–11:00 giờ của bé; `draftedFor` + giao dịch + id thông báo `cpr-{bé}-{ngày}` để không lặp).
- Thông báo: kind `carePlanReady`, đích `CARE_PLAN_READY`, template `care.plan_ready` (số việc + việc đầu trong danh mục, không có tên tự gõ). Giờ yên lặng: giữ lại.
- Thuật toán "Theo nhịp" (`care-plan-drafts.ts`): với bú và ngủ, lấy nửa giờ có nhiều ngày nhất có sự kiện trong ±30 phút (ít nhất nửa số ngày), đặt việc ở trung vị (làm tròn 5 phút), bỏ các sự kiện gần đó (bú 90 phút, ngủ 60 phút), lặp lại; tối đa 10 cữ bú, 6 giấc. Bú mẹ hay bú bình theo loại ghi nhiều hơn.
- Rules: `carePlanSettings` đọc như lịch, không ai ghi từ app. Index field override `carePlanSettings.autoDraft` (collection group).
- **Sửa lỗi bước 3:** bố mẹ bấm "Đã nhận" trên một bản bàn giao **cũ** từng kết thúc cả ca **mới** của người hỗ trợ. Giờ chỉ kết thúc ca bắt đầu trước lúc gửi bản đó.

## Kiểm chứng

- **Golden:** `care_plan/plan_draft_*` và `care_plan/change_way_*` mới (8 ảnh); `care_plan/start_parent_*` cập nhật (4 ảnh: thêm "Theo nhịp của bé" và Lịch mẫu, vì golden chạy ở môi trường dev).
  - `care_plan_today/settings_*` cập nhật (4 ảnh): Ba là người quản lý lịch nên thấy phần "Cả nhà · Tự tạo lịch mỗi sáng"; đã xem light vi, night en.
  - Đã xem: start_parent light vi, night en; plan_draft light vi (bản đầu còn viền "việc kế tiếp" trên thẻ 07:00, đã sửa) và night en; change_way light vi. Không tràn chữ, Night care đủ tương phản.
- **Test hành vi:** `care_plan_test.dart` 19 (thêm 6: Theo nhịp chỉ khi đủ 7 ngày; lịch mẫu; bản nháp Dùng lịch này, không có vòng; Đổi cách khác / Giữ bản nháp; người hỗ trợ không thấy bản nháp; chữ 200 % vi/en). `care_plan_today_test.dart`: bản nháp không lên Hôm nay; công tắc Tự tạo lịch mỗi sáng chỉ cho người quản lý. `notifications_test`: 22 đích.
- **Emulator** (cổng riêng, vì emulator khác đang giữ 8080): `care-plan-draft.integration.test.ts` 10 test (thuật toán, 7/7 ngày, bản nháp không nhắc tới khi dùng, Đổi cách khác, quyền, tự tạo mỗi sáng + N5 một lần, không động vào ngày đã có), cộng care-plan, reminders, rules, handover-send (thêm test ca mới không bị kết thúc): 49 pass.
- **Bộ test mobile đầy đủ:** 33 lỗi, đúng danh sách đã có từ trước (bước 2, 3); 4 golden settings lệch do thay đổi này đã cập nhật.
- **TS:** contracts 925, functions 510, portal 729; typecheck, eslint, prettier sạch. `flutter analyze` sạch.

## Còn lại và giới hạn

- **Lịch mẫu chờ duyệt nội dung** (`templates-draft.md`), chỉ trên dev. Khi duyệt: bỏ "(chờ duyệt)" và giới hạn dev.
- **"Theo nhịp" phía app dựa vào dấu theo ngày** (`days/{date}`: có bú, có ngủ); server đếm theo giờ bắt đầu. Một giấc bắt đầu từ tối hôm trước có thể làm app hiện lựa chọn mà server từ chối; khi đó có toast "Chưa đủ 7 ngày có ghi cả bú và ngủ".
- **Lịch mỗi sáng dùng cách gần nhất** nhà mình chọn; chưa có chỗ chọn riêng cách cho buổi sáng.
- **Đã deploy dev (28/10):** `scripts/deploy.sh dev` (VERIFY=0, vì gcloud chạy Python 3.9): rules, indexes, startCarePlanDay, saveCarePlanItem, publishCarePlanDay, setCarePlanAutoDraft, draftCarePlanMornings, ringCareTaskReminders, sendHandover, markHandover. Gọi publishCarePlanDay / setCarePlanAutoDraft không đăng nhập trả JSON 401, tức callable vẫn khoẻ.
- **Chưa kiểm** push N5 thật trên máy, VoiceOver/TalkBack.
- Golden 04-0 chỉ có bản dev (có Lịch mẫu); bản prod không có golden riêng, logic ẩn đã có test.
