# Cùng Chăm Con — bước 2 (28/10/2026)

Quyết định: D-135 (`docs/product/business-map.md`). Phân tích: `docs/design/explorations/cung-cham-con/ANALYSIS-2026-10-28.md` §2, §6, §10 bước 2. Bước 1: `2026-10-28-cung-cham-con-step1.md`. Figma 14, 15, 13 chỉ dùng làm tham khảo (D-104).

## Tóm tắt cho chủ sản phẩm

- **Hôm nay (bố mẹ):**
  - Chip "Ai đang trông bé" đã rời Living Header. Header luôn gọn như kiểu "ẩn" trước đây.
  - Khối đầu tiên dưới header là **"n việc cần làm"** + "Tất cả ›". Khối này chỉ có các việc chung của Cùng Chăm Con được giao cho **người đang xem**, chưa xong, trong hôm nay. Nhắc việc riêng (Nhắc việc · n) vẫn nằm riêng ở dưới, không đổi (D-135 Q4).
  - Thẻ hiện việc kế tiếp: giờ, tên việc và nút **"Đã làm"** (có Hoàn tác). Chạm thẻ hoặc "Tất cả" mở lịch chung.
  - Không còn việc nào thì cả khối ẩn hẳn, không có thẻ "Nghỉ chút nhé" (D-110). Người thân không được giao việc nên không thấy khối này.
- **Tuỳ chỉnh / Cài đặt giao diện:** công tắc "Ai đang trông bé" đổi tên thành **"Việc chăm con cần làm"** (en "Care tasks to do"). Vẫn dùng khoá `duty` / `WidgetId.careDuty`, nên ai đã tắt thì vẫn tắt. Khung xem trước header không còn phần chip.
- **Ai đang trông (D-135 Q1):** khi một **người hỗ trợ** (vai trò Người chăm sóc) đang trong ca, hàng Bàn giao trên Hôm nay ghi "**Cô Lan đang trông · đến 13:00**". Giờ "đến" là giờ việc cuối cùng của cô ấy hôm nay (Q2). Không có việc nào còn lại thì ghi "· từ 08:20". Ba và Mẹ không bao giờ hiện là "đang trông". Không ai trong ca thì không hiện gì. Có bàn giao mới gửi cho mình thì dòng "Mới" vẫn được ưu tiên.
- **"Đến giờ rồi" (15):** sheet này hiện khi mở app (hoặc quay lại app) mà có việc của mình đã tới giờ, tính từ 5 phút trước tới 1 giờ sau giờ việc. Sheet cũng hiện khi chạm vào push nhắc việc.
  - Một việc: hình, giờ, tên việc, **Đã làm** / **Để sau 10 phút** / "Xem cả lịch hôm nay".
  - Nhiều việc tới giờ cùng lúc (push gộp): liệt kê các việc, nút chính "Đã làm cả n việc".
  - Mỗi việc chỉ hiện một lần trên mỗi máy. "Để sau 10 phút" cho việc đó hiện lại khi mở app sau 10 phút.
  - Sheet không chồng lên tour lần đầu, lời hỏi quyền thông báo (D-098), một sheet đang mở hay một màn đang mở trong tab. Nếu đang bị che thì chờ rồi xem lại. Push đã chạm thì vẫn hiện trên màn đang mở (quy tắc 23/10).
  - Push cho một việc đã xong hoặc đã bỏ qua: mở lịch chung kèm toast "Việc này đã xong hoặc đã được bỏ qua".
- **Push N1 (server gửi):**
  - Gửi cho từng người được giao, trước giờ việc theo **"Nhắc trước"** của chính người đó (5 / 10 / 15 phút / Tắt, mặc định 5).
  - Các việc cách nhau dưới 15 phút gộp thành một push, ví dụ "5 phút nữa Teddy cần bạn rồi nè · 09:00 Vitamin · 09:10 Bú bình".
  - Chạy mỗi phút. Mỗi việc chỉ nhắc một lần cho mỗi phiên bản (`itemId + revision`). Đổi giờ hoặc đổi người làm thì nhắc lại theo giờ mới, cho người mới.
  - **Giờ yên lặng:** mặc định vẫn nhắc. Ai tắt "Nhắc cả trong giờ yên lặng" thì push bị giữ lại, nhưng vẫn có trong hộp thông báo.
  - Nội dung push chỉ có giờ và tên việc trong danh mục. Tên việc tự gõ hiện là "Việc riêng", vì đó là chữ gia đình tự gõ và có thể ghi tên thuốc.
- **Cài đặt (phần của mỗi người, 13):**
  - Lịch chung có nút chuông → **"Nhắc việc chăm con"**: chọn Nhắc trước 5 / 10 / 15 phút / Tắt, và bật/tắt "Nhắc cả trong giờ yên lặng". Dòng này ghi rõ Không làm phiền của điện thoại vẫn có thể chặn thông báo, vì app không vượt qua được nên không hứa.
  - Thông báo › Nhắc việc bạn đặt có thêm hàng **"Việc chăm con · Trước 5 phút"**, mở đúng màn đó. Chỉ có một nơi lưu, nên hai chỗ không bao giờ mâu thuẫn.

## Dữ liệu và server

- **Việc trong lịch** có thêm `dueAt` (giờ của việc theo múi giờ của bé) và `revision` riêng. `revision` tăng khi đổi giờ hoặc đổi người làm (`saveCarePlanItem`, `assignCarePlanItems`); `startCarePlanDay` tạo việc với `revision: 1`. Phiên bản đã nhắc cho từng người lưu ở `reminded.{uid}`.
- **Scheduler `ringCareTaskReminders`** (mỗi phút, `firebase/functions/src/care-plan-reminders.ts`):
  - Truy vấn collection group `items`: `status == open`, `dueAt` trong 30 phút tới. Có index mới.
  - Chỉ lấy việc nằm dưới `carePlanDays`, vì album cũng có sub-collection `items`.
  - Bỏ qua người đã rời gia đình hoặc đã thành người thân (D-018).
  - Đánh dấu `reminded` trong một transaction trước khi gửi. Notice id là `ct-{itemId}-r{revision}`.
  - Gửi qua `notifyUsers`: hộp thông báo, ledger và chống trùng.
- **Contracts:**
  - Kind `careTaskDue` (nhóm Chăm sóc), destination `CARE_TASK_DUE` (`/care/together`, babyId + date + items), template `care.task_due` (`minutes`, `task_line`, `baby_name`).
  - Producer `care.plan`.
  - `Notice.quietHours` cho phép từng người chọn giữ hoặc vẫn gửi trong giờ yên lặng.
  - Mặc định của kind là "rings" (`ringsInQuietHours`).
- **Cài đặt cá nhân:** `users/{uid}/settings/carePlan` = `{leadMinutes: 0|5|10|15, quietHours: bool}`. Chủ tài khoản tự ghi, Rules kiểm `validCarePlanPrefs`.
- **Portal:** nhãn cho kind và producer mới.

## Simplify (so với Figma 14 / 15 / 13)

| Phần | Quyết định | Lý do |
|---|---|---|
| Chip "Ai đang trông bé" trong header | Bỏ (D-135 Q1) | Người hỗ trợ đang trông được ghi ở hàng Bàn giao |
| Tag "Phân việc" trên thẻ việc ở Home | Bỏ | Cả khối đều là việc được phân (ANALYSIS §2) |
| Chip người làm trên thẻ ở Home | Bỏ | Mọi việc trong khối đều là của người đang xem |
| Vuốt dọc để lật sang việc sau (14) | Không làm | Bấm "Đã làm" là việc kế tiếp hiện lên, tiêu đề vẫn ghi đủ số việc. Thao tác vuốt khó phát hiện và không cần |
| "Mẹ nhờ Ba nhé" (người giao) trong sheet 15 | Chưa có | Lịch chưa lưu ai là người giao việc. Thêm khi có dữ liệu thật, không đoán |
| "Để sau 10′" | "Để sau 10 phút" | Font của app không có ký tự ′, nên bản render mất đơn vị. Viết rõ "phút" |
| Thẻ "Nghỉ chút nhé" khi hết việc | Không hiện trên Home | D-110. Thẻ này chỉ dành cho widget (bước 6) |
| "Gộp việc gần nhau" là tuỳ chọn riêng (§6.2) | Luôn gộp (< 15 phút), ghi rõ dưới "Nhắc trước" | Bớt một công tắc. Gộp chỉ giảm số push, không làm mất việc nào |

## Component

- Dùng lại `CarePlanTaskCard`, `CarePlanArt` (bước 1), `ClSectionHeader`, `ClButton` (tinted ở Home; primary/secondary/plain trong sheet), `showClSheet`, `ClOptionRow`, `MeRow` + `ClToggle`, `MePage`. Không có widget dùng chung mới và không có token mới.
- Mới trong tính năng (`features/care_plan/`): `care_plan_today.dart` (section, sheet, gate, dòng người hỗ trợ đang trông) và `care_plan_settings.dart`.

## Kiểm chứng

- **Golden mới `goldens/care_plan_today/`:** 5 trạng thái × Light/Night × vi/en = 20 ảnh. Trạng thái: Hôm nay có khối việc, sheet một việc, sheet nhiều việc, cài đặt, cài đặt đã Tắt.
  - Đã mở xem: today_tasks light vi / night en, due_one light vi (trước và sau khi sửa "10 phút"), due_many light en / night en, settings light vi.
- **Golden cập nhật do thay đổi này:** 195 ảnh + 4 ảnh bị xoá (`lh/hidden_*`, trường hợp này không còn). Để quy được từng khác biệt về đúng nguyên nhân, đã chạy cùng bộ test trên một worktree sạch ở HEAD `07709660`. Ở HEAD chỉ có 4 golden lệch từ trước (`hn/home_for_baby_*`); 4 ảnh này giữ nguyên, không cập nhật.
  - Hôm nay ở mọi nơi có header (`s4`, `s5`, `s7`, `ax`, `hn`, `hv`, `ths`, `lh`): chip rời header nên nội dung dịch lên. Đã xem `s4/19_today` trước/sau.
  - `care_plan/*`: thêm nút chuông trên thanh tiêu đề. Đã xem plan_fresh night vi.
  - `nt/en07_*`: thêm hàng "Việc chăm con". Đã xem en07_settings light vi.
  - `ax/ax14_customize_*`, `hn/customize_*_en`: công tắc đổi tên.
- **Test hành vi** `test/features/care_plan_today_test.dart` (13 test pass):
  - Khối chỉ có việc của mình, số việc, việc kế tiếp, Đã làm + toast.
  - Ẩn khi công tắc tắt, khi đã hết việc, và với người thân.
  - Khoảng "tới giờ" từ −5 tới +60 phút.
  - Sheet khi mở app: Đã làm, mỗi máy chỉ một lần. Để sau 10 phút thì hiện lại sau 10 phút.
  - Không chồng lên tour, lên màn đang mở trong tab, hay việc đã hiện.
  - Push: hiện cả khi không ở màn gốc của tab. Push cho việc đã xong thì mở lịch kèm toast.
  - Cài đặt lưu Nhắc trước và giờ yên lặng; Tắt thì ẩn giờ yên lặng.
  - Dòng người hỗ trợ đang trông; không bao giờ hiện Ba/Mẹ hay "chưa ai".
  - Chữ 200 % vi/en không tràn.
  - Thêm: `notifications_test` CARE_TASK_DUE (đặt yêu cầu mở sheet, chặn id sai); `living_header_test` không còn chip, công tắc bật/tắt khối việc.
- **Firebase emulator:**
  - `care-plan-reminders.integration.test.ts`: 7 test pass. Mặc định 5 phút, một lần, chạy lại không gửi trùng; nhắc trước theo từng người, Tắt; gộp < 15 phút; đổi giờ hoặc người làm thì nhắc lại, việc đã xong thì không; không gửi người thân, không lộ tên tự gõ; giờ yên lặng theo từng người (bị giữ vẫn vào hộp thư); nội dung khi không có tên bé.
  - `care-plan.rules.test.ts`: thêm 2 test cho `settings/carePlan`. `care-plan.integration`, `reminder-rules.integration`, `notifications.rules`, `handover`: 62/62 pass.
- **TS:** contracts 925, functions 510, portal 729 pass; typecheck sạch. `flutter analyze` sạch.
- **Bộ test mobile đầy đủ:** 34 test lỗi khi chạy cả bộ. 1 lỗi là assertion trong test mới của chính bước này, đã sửa và chạy lại pass. 33 lỗi còn lại cũng lỗi y hệt trên worktree sạch ở HEAD `07709660`, nên có từ trước (print studio, premium, keepsake, solids, flow_audit storage, rhythm ms01, hn home_for_baby, và care_flow_errors / history / me_test trên Hôm nay). Bước này không gây thêm lỗi nào.
- **Deploy dev (28/10):** `scripts/deploy.sh dev` (VERIFY=0, vì `gcloud` đang chạy Python 3.9) gồm: firestore rules, indexes, scheduler mới `ringCareTaskReminders` và 5 callable của lịch. Gọi `saveCarePlanItem` không đăng nhập trả JSON 401, tức callable vẫn khoẻ.

## Còn lại và giới hạn

- **Nút trên thông báo** (Xong, Nhắc lại 10 phút) chưa có. Chạm push mở sheet, và sheet có đủ hai nút này.
- **"Để sau 10 phút" chỉ chạy trên máy này:** sheet hiện lại khi mở app sau 10 phút. Server không gửi lại push sau 10 phút.
- **Push cũ không bị thu hồi** khi lịch đổi. Trên iOS, push mới của cùng việc thay push cũ (`collapseId`). Push cũ cũng hết hạn sau giờ việc 30 phút.
- **"Đã làm" chưa ghi vào nhật ký chăm sóc**, kể cả việc cần số liệu như bú bình: chỉ đánh dấu xong, như bước 1 (D-135). Nối với form/preset D-132 thuộc bước 5.
- **Việc tạo ở bước 1 trước lần deploy này** chưa có `dueAt`, nên không được nhắc cho tới khi được sửa hoặc giao lại. Chỉ ảnh hưởng dữ liệu thử trên dev.
- **Chưa kiểm:** push thật trên máy (iOS/Android), VoiceOver/TalkBack. Hàng Bàn giao có dòng người hỗ trợ đang trông chưa có golden riêng; logic đã có test.
- **Đề xuất cho sau (không phải L3 đang chờ):** lưu người giao việc để sheet ghi được "Mẹ nhờ Ba nhé".
