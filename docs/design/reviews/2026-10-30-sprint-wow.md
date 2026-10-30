# Sprint wow (D-140): Sắp tới, Bé dậy chưa?, Lumi ghi "bây giờ", Nhắc cữ tiếp

2026-10-30 · nguồn: `docs/audits/2026-10-29-lumi-ca-nhan-hoa-nhip.md` §4 (W1, W2) · chủ sản phẩm: "làm sprint wow đi".

## Tóm tắt cho chủ sản phẩm

| Việc                          | Đã làm                                                                                                                                                                                                                                       | Chưa làm                                                                                                                                                                   |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Nội dung chưa duyệt**       | Rà soát lại seed: 14/15 điểm an toàn chính đã có. **Viết lại 24 hoạt động 12–36 tháng**: 3 bước mỗi mục, lời an toàn cụ thể, thay 8 mục trùng. Hồ sơ cho chuyên gia ký: `docs/product/content-review-2026-10/rhythm-prereview-2026-10-30.md` | **Không đánh dấu "đã duyệt"**: mọi mục vẫn `review: null`, vì cần chuyên gia thật ký (D-058). Ba việc chờ quyết: tuổi hiệu chỉnh, tên "Wonder Weeks", cách nói về cai bình |
| **W1 "Sắp tới"** trên Hôm nay | "Cữ bú tiếp · khoảng 14:10–14:40" và "Giấc ngủ tiếp · khoảng 14:50–15:20" (hoặc "Bé dậy · khoảng 15:00" khi đang ngủ ngày). Tính từ 14 ngày nhật ký của chính bé, không tốn thêm lượt đọc, chạy được offline                                 | Chỉ hiện cho gia đình có Premium (`rhythm.advanced`). Gia đình Free **không thấy gì, cũng không có lời mời nâng cấp**, vì chưa mua được (COM-01)                           |
| **L6 "Bé dậy chưa?"**         | Thông báo trên máy người bật đếm giấc ngủ, đúng giờ theo các giấc trước của bé. Không hỏi ban đêm hay trong giờ yên lặng. Có công tắc trong Cài đặt thông báo. Chạm vào mở màn đếm giờ                                                       | Các nút "Dậy rồi / Dậy lúc… / Vẫn ngủ" ngay trên thông báo, và lần hỏi thứ hai                                                                                             |
| **L8 Lumi ghi "bây giờ"**     | "bé bú 120ml" ghi ngay, không hỏi giờ. "bú mẹ 15 phút" là vừa xong. "sáng nay / hồi nãy / hôm qua" vẫn hỏi. **Sửa thêm một lỗi có sẵn**: "hồi nãy bé bú 120ml" đi qua model từng bị ghi thành giờ hiện tại một cách lặng lẽ                  | Dòng trạng thái phía trên ô nhập ("Đang trả lời: …"). Ô nhập hiện vẫn hiện gợi ý "Trả lời câu hỏi…"                                                                        |
| **L4 "Nhắc cữ tiếp"**         | Trên thẻ cữ bú vừa lưu qua Lumi (trong 3 giờ, Cùng nuôi): mở nhắc "sau cữ gần nhất" với khoảng cách của bé                                                                                                                                   | Chip cho các loại khác: thẻ ngủ, tăng trưởng, chi tiêu đã có sẵn liên kết "Mở nhật ký" / "Mở bản ghi"                                                                      |

**Chưa deploy.** Phần server của L8 (`assistant-text.ts`, `assistant-understanding.ts`) chỉ có hiệu lực trên dev sau khi chạy `scripts/deploy.sh dev functions`. Phần app chạy ngay khi build.

## Thiết kế (W1)

- **Hiện:** câu trả lời in đậm, là giờ đồng hồ "khoảng …" (mục §5.4 của skill: dự đoán luôn "khoảng"). Dưới đó là mốc tính ("Cữ gần nhất 11:40", "Dậy lúc 12:20") và nguồn ("Theo nhật ký 14 ngày gần đây") để người đọc tin được.
- **Bỏ:** thanh tiến trình hay đếm ngược, để không biến "thường" thành áp lực "phải".
- **Vị trí:** ngay dưới các ô ghi nhanh trong "Nhịp hôm nay". Các ô vẫn là thao tác chính (D-105), thứ tự Adaptive không đổi.
- **Thành phần:** dùng lại `AxCard`, icon và màu care có sẵn; không thêm token, không thêm widget riêng (D-106, D-107).
- **Không hiện khi:** chưa đủ dữ liệu (dưới 5 khoảng trên 3 ngày, hoặc dải rộng hơn ×2), mốc gần nhất cũ hơn 6 giờ, đang bú mẹ bằng timer, giấc tiếp theo rơi vào buổi tối, hoặc đang ngủ đêm.
- **Ảnh đã xem:** `test/golden/goldens/coming_up/` gồm awake/asleep × Light/Night × vi/en, thêm chữ 200% (awake, Light). Chữ 200% xuống dòng gọn, không tràn.

## Kiểm chứng đã chạy

| Kiểm tra                                                                               | Kết quả                                                                                                                 |
| -------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `flutter analyze`                                                                      | Không lỗi                                                                                                               |
| Unit: `coming_up_test` (13), `wake_check_test` (3), L4 trong `assistant_chat_test` (2) | Đạt                                                                                                                     |
| Test Lumi phía app (assistant, replay)                                                 | 967 + 2 đạt                                                                                                             |
| Toàn bộ Flutter không golden                                                           | Còn 8 lỗi **có sẵn từ trước** (SY-1, history, me, solids, print ×4; đã ghi trong audit 29/10). Không có lỗi mới         |
| Golden mới `coming_up/`                                                                | 10 ảnh                                                                                                                  |
| Golden cập nhật có chủ đích                                                            | `nt/en07_*` ×8, do thêm dòng công tắc                                                                                   |
| Golden lệch **không phải của sprint**                                                  | `direct_care/offline_*` ×4: "Chờ đồng bộ" xuống dòng do commit `93997789`/`f03c7573` của phiên khác; **không cập nhật** |
| Functions unit                                                                         | 510 đạt (+1 bỏ qua)                                                                                                     |
| Test tích hợp Lumi (emulator)                                                          | 214 đạt                                                                                                                 |
| Lumi e2e với model giả                                                                 | Đạt hết (EXIT 0), gồm 4 ca L8 mới                                                                                       |
| Contracts `personalization-v2` (gói 12–36 tháng)                                       | 10 đạt                                                                                                                  |
| Portal                                                                                 | 729 đạt                                                                                                                 |
| Model thật (live eval)                                                                 | **Chưa chạy**: cần anh/chị đồng ý chi phí (khoảng 4–6 lượt cho các ca mới)                                              |
| Máy thật iOS/Android                                                                   | **Chưa chạy**                                                                                                           |

## L6 phần hai: nút trên thông báo (30/10)

- **Dậy rồi**: mở app, lưu giấc ngủ kết thúc **đúng lúc chạm nút** (không phải lúc app mở xong), hiện thông báo "Đã lưu" có Hoàn tác.
- **Dậy lúc…**: mở màn đếm giờ, hỏi giờ dậy (không sớm hơn giờ bắt đầu), rồi lưu.
- **Vẫn ngủ**: không mở app. Hỏi lại **một lần** sau nửa thời lượng giấc thường của bé (ít nhất 30 phút), và chỉ khi lần đó vẫn chưa sang ban đêm hay giờ yên lặng. Lần hỏi thứ hai không có nút "Vẫn ngủ".
- Nút chỉ tác động lên đúng giấc đã hỏi. Nếu giấc đó đã kết thúc hoặc đã bắt đầu giấc khác, app chỉ mở màn đếm giờ.
- **iOS**: các nút được đăng ký cùng chỗ với nút nhắc theo quy tắc (`RuleNotifications.swift`), vì plugin thông báo sẽ xoá các nút đó nếu tự đăng ký. "Vẫn ngủ" chạy trong nền với hai plugin (thông báo, bộ nhớ máy).
- **Chưa làm**: lần hỏi đầu nhắc rằng có thể tắt trong Cài đặt thông báo; không kêu, không rung khi đang bật Chăm đêm. Chưa thử trên máy thật.

## Ghi chú

- **23 ca e2e cũ đã cập nhật.**
  - 5 ca lỗi thiết bị (người dùng đã chọn "Vừa xong") nay không còn câu hỏi, giờ ghi giữ nguyên.
  - 18 ca kiểm tra cơ chế hỏi–đáp được thêm "hồi nãy" để câu hỏi vẫn xuất hiện. 15 ca trong số đó nay tốn 1 lượt gọi model, vì bộ đọc quy tắc cố ý chuyển "hồi nãy" cho model.
  - 6 test tích hợp đổi câu thành "sáng nay bé bú 120ml" để vẫn đi đường quy tắc miễn phí.
- **`br-05` lộ ra chỗ lệch giữa hai đường** khi người dùng gõ giờ cho cữ bú mẹ có thời lượng: đường quy tắc hiểu là giờ bắt đầu, đường model hiểu là giờ kết thúc. Đã thống nhất theo đường quy tắc: giờ gõ tay là giờ bắt đầu, chip "Vừa xong" là giờ kết thúc.
- **Một phiên khác đang viết lại câu chữ thông báo** (`tool/notification_copy_strings.py`, theo yêu cầu "thân thiện ko được cộc lốc") và đã đổi câu "Bé dậy chưa?". Script của sprint này đã dùng cùng câu đó để hai bên không đè nhau.
