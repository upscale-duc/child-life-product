# Cùng Chăm Con — bước 3 (28/10/2026)

Quyết định: D-135 (Q1, Q2, Q3, Q9) trong `docs/product/business-map.md`. Phân tích: `docs/design/explorations/cung-cham-con/ANALYSIS-2026-10-28.md` §3, §4, §6.1 (N4), §10 bước 3. Các bước trước: `2026-10-28-cung-cham-con-step1.md`, `…-step2.md`. Figma 16, 17 chỉ dùng làm tham khảo (D-104).

## Tóm tắt cho chủ sản phẩm

- **Hôm nay của người hỗ trợ khi có việc trong ngày (16, RESTRUCTURE):** Cô Lan được giao việc hôm nay thì thấy một Hôm nay riêng, gồm theo thứ tự:
  1. Lời chào ngắn "Chào Cô Lan", không có Living Header lớn.
  2. **Thẻ ca:** vòng việc đã làm (1/3), khung giờ "08:30 – 13:00" (từ việc đầu tới việc cuối của cô ấy, Q2), "Còn 2 việc trong ca". Bên dưới là nút **Bắt đầu ca**; khi đã bắt đầu thì thành "Đang trông từ 07:05" (chạm vào mở sheet ca để kết thúc).
  3. **Ghi 1 chạm:** chính các ô Nhịp hôm nay đang có (D-132), không dùng 3 ô trơn của Figma.
  4. **Việc của tôi:** các việc của cô ấy, có vòng đánh dấu; việc kế tiếp có viền.
  5. **Ghi chú cho bố mẹ:** 4 tag (Ăn ngon, Quấy nhẹ, Ngủ sâu, Cười nhiều; bỏ "Đi ngoài" vì nhật ký tã đã có) và ô "Viết thêm…". Ghi chú chỉ lưu trên máy này, theo ngày.
  6. **Bàn giao cho bố mẹ:** nút tinted ở cuối, mở Bàn giao.

  Các phần khác (Dành cho bé, Tuần này, Nhắc việc, Hôm nay, Tuỳ chỉnh) được ẩn khi đang có ca và vẫn tới được từ Khám phá. Người hỗ trợ không có việc hôm nay thì vẫn thấy Hôm nay như cũ. Bố mẹ không đổi gì. Tab không đổi (Q9).
- **Bàn giao của người hỗ trợ (17, có AI, Q3):**
  - Người hỗ trợ được tạo bản tóm tắt AI. Đồng ý dùng AI, lượt AI chung của gia đình và các cổng giữ nguyên. Bản tóm tắt vẫn chỉ tạo khi chạm (D-127 Q5).
  - Đầu màn có hàng "**Bàn giao cho Mẹ và Ba** · Hết ca 13:00", thay cho hàng "Đang trông".
  - Khi đang trong ca, hai ô Bú gần nhất/Tã gần nhất đổi thành **Trong ca**: Bú "3 cữ · 240 ml", Ngủ "0 phút", Tã "2 lần · đi ngoài 1".
  - **Việc còn lại hôm nay:** mọi việc chưa xong trong ngày, ghi ai làm, có vòng đánh dấu.
  - **Lời nhắn:** điền sẵn từ ghi chú trong ca ("Ăn ngon · Cười nhiều. Khăn sạch ở ngăn trên"), chạm để sửa. Bỏ bước mở sheet ghi chú riêng.
  - Một nút chính **Gửi cho bố mẹ**: gửi một lần tới mọi Cùng nuôi đang hoạt động. Sau khi gửi, nút thành trạng thái chung "Đã gửi cho Mẹ và Ba · 17:00 / Ba đã nhận bàn giao · 17:05".
- **Bố mẹ nhận (17):**
  - Khung trên cùng: "Cô Lan gửi cho cả nhà · 17:00" kèm lời nhắn.
  - Có cả "Trong ca" của người hỗ trợ (tính từ giờ bắt đầu ca lưu trong bản gửi) và "Việc còn lại hôm nay", để bố mẹ tick ngay việc còn lại.
  - Nút là "**Tôi đã nhận bàn giao**", không bao giờ là "Tôi nhận trông bé" (Q1).
  - Một người bấm là đủ: người kia thấy "Ba đã nhận bàn giao · 17:05" thay cho nút. Lúc đó ca của người hỗ trợ kết thúc.
- **Push N4:** "Bàn giao cho cả nhà · Cô Lan vừa gửi lời bàn giao cho cả nhà · Còn 2 việc chờ bố mẹ". "2 việc" là số việc chưa xong hôm nay không phải của người gửi. Push không chứa lời nhắn hay dữ liệu về bé. Chạm vào mở đúng bản bàn giao đó (`CARE_HANDOVER`).
- **Ca trông (Q1):**
  - Chỉ người hỗ trợ (vai trò Người chăm sóc) bắt đầu, nhận hoặc kết thúc ca.
  - Ba và Mẹ không còn nút "Tôi trông bé" hay "Ba và Mẹ cùng trông", và server cũng từ chối (`not-a-carer`).
  - Bố mẹ nhận bàn giao 1–1 chỉ là đã đọc, không nhận ca. Dữ liệu `careDuty` cũ vẫn giữ.

## Dữ liệu và server

- `generateSummary`: `canGenerateSummary(member, kind)` (contracts). Cùng nuôi được tạo mọi loại; Người chăm sóc được tạo `handover`. Cổng `ai.assistance` kiểm theo `rhythm.feedback` của người hỗ trợ. `listSummaries` trả số lượt AI của gia đình cho cả người hỗ trợ.
- `sendHandover`: thêm `toParents: true` (loại trừ với `recipientUid`), chỉ dành cho Người chăm sóc.
  - Tạo một `handoverSends` cho mỗi Cùng nuôi đang hoạt động, với `family: true`, `openTasks`, `shiftSince`, `receivedBy: null`.
  - Tạo một thông báo gia đình `handover_family_{summaryId}` có `context {family, openTasks}`.
  - Kết quả có thêm `sendIds`.
- `markHandover('received')` trên bản gửi `family`: đánh dấu đã nhận mọi bản cùng summary và cùng người gửi (`receivedBy`), rồi kết thúc ca của người gửi. Người hỗ trợ nhận bàn giao 1–1 thì vào ca như trước.
- `canTakeDuty` chỉ còn cho `caregiver`.
- Thông báo: template mới `ai.handover_family` (`actor_name`, `count`) cho kind `handoverSent`. `noticeCopy` / `noticeTemplate` nhận `context`.

## Simplify

| Phần | Quyết định | Lý do |
|---|---|---|
| Living Header trên Home người hỗ trợ | Bỏ, thay bằng lời chào ngắn | Người trông cần ca và việc, không cần ảnh nền (ANALYSIS §4) |
| 3 ô ghi trơn của Figma 16 | Dùng ô Nhịp hôm nay có sẵn | Có bú mẹ, "lần trước", timer và preset D-132 |
| Tag "Đi ngoài" | Bỏ | Nhật ký tã đã ghi (§3.2) |
| Sheet ghi chú trước khi gửi | Bỏ với người hỗ trợ; Lời nhắn nằm ngay trên màn | Bớt một bước |
| Chọn người nhận khi người hỗ trợ gửi | Bỏ | Ba và Mẹ như nhau, cả hai cùng nhận (Q1) |
| Chip "+ Giao" ở việc chưa ai làm trong Bàn giao | Ẩn | Chip đó là thao tác của người quản lý lịch, không phải của màn này |
| "Ba và Mẹ cùng trông" | Bỏ khỏi giao diện và server | Q1 |

## Kiểm chứng

- **Golden mới `goldens/care_plan_shift/`:** 3 trạng thái × Light/Night × vi/en = 12 ảnh: Home người hỗ trợ, Bàn giao người hỗ trợ gửi, Mẹ đọc sau khi Ba đã nhận.
  - Đã xem: helper_home light vi (bản đầu thiếu nút Bàn giao vì fixture chưa bật cờ, đã sửa) và night en, handover_helper light vi (đã sửa ô Ngủ, chip "+ Giao", tiêu đề Lời nhắn) và night en, family_received light vi / night en.
- **Golden cập nhật:** `ai/su01_*` 44 ảnh (hàng "Đang trông" thành hàng người nhận; người hỗ trợ được tạo), `cd/*` 16 ảnh (bố mẹ không còn nút nhận ca; take_pending giờ là của người hỗ trợ), `hn/home_caregiver_*` 4 ảnh (hàng Bàn giao mời tạo). `cd/together_pending_*` bị xoá. `hn/home_for_baby_*` và `rh/ms01_*` lệch từ trước (cũng lệch ở HEAD sạch), giữ nguyên.
- **Test hành vi:** `care_plan_shift_test.dart` 7 test pass:
  - Home ca: chào, thẻ, việc của tôi, ghi chú, Bắt đầu ca.
  - Đang trong ca; bố mẹ giữ Hôm nay cũ; ghi chú lưu trên máy và thành lời nhắn.
  - Gửi cho cả bố mẹ kèm lời nhắn.
  - Người kia đã nhận thì không có nút thứ hai; bố mẹ chỉ "Tôi đã nhận bàn giao".

  Đã cập nhật theo D-135: `ai_summary_test` (người hỗ trợ tạo khi chạm; Home luôn có hàng Bàn giao) và `care_duty_test`.
- **Emulator:** 119 test pass:
  - `handover-send`: ca chỉ cho người hỗ trợ; gửi cho bố mẹ, push N4 (vi/en, không lộ lời nhắn); chỉ người hỗ trợ gửi được; người nhận đầu tiên chốt cho cả hai và kết thúc ca; `shiftSince`.
  - `ai-summary`: người hỗ trợ tạo bàn giao bằng lượt chung, không tạo được loại khác.
  - care-plan, notifications, albums.
- **TS:** contracts 925, functions 510, portal 729; typecheck, eslint sạch. `flutter analyze` sạch.
- **Bộ test mobile đầy đủ:** 33 lỗi, đúng 33 lỗi đã có từ trước (cùng danh sách ở bước 2, đã đối chiếu với HEAD sạch `07709660`). Bước này không gây lỗi mới.

- **Deploy dev (28/10):** `scripts/deploy.sh dev` (VERIFY=0, vì gcloud chạy Python 3.9): generateSummary, listSummaries, sendHandover, markHandover, setCareDuty, deliverFamilyNotice. Gọi sendHandover / generateSummary không đăng nhập trả JSON 401, tức callable vẫn khoẻ.

## Còn lại và giới hạn

- **Ghi chú trong ca chỉ trên một máy.** Người hỗ trợ đổi máy giữa ca thì mất ghi chú; không đồng bộ.
- **"Trong ca" tính tới lúc mở màn**, không dừng ở lúc gửi.
- **Ca bắt đầu bằng tay ("Bắt đầu ca")**, không tự bắt đầu theo giờ việc đầu tiên. Tự bắt đầu sẽ là thay đổi hành vi (L3) nếu muốn.
- **Bàn giao bố mẹ → người hỗ trợ** vẫn như D-093: chọn một người, vẫn có sheet ghi chú.
- **Chưa kiểm** trên máy thật: push N4 thật, VoiceOver/TalkBack.
