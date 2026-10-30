# Nhịp lớn lên: hồ sơ tiền duyệt cho chuyên gia (2026-10-30)

**Đây không phải chứng nhận chuyên môn.** Claude Code rà soát theo yêu cầu của chủ sản phẩm
(2026-10-30: "duyệt hộ toàn bộ nội dung chưa duyệt"). Mọi mục **vẫn giữ `review: null`**. Lý do: D-058 và
`rhythmActSchema` yêu cầu một người có chuyên môn ký trước khi xuất bản trên prod. Nhãn
"Nội dung minh hoạ · chờ chuyên môn duyệt" vẫn hiện như cũ. Hồ sơ này giúp người duyệt đọc nhanh và ký.

## 1. Phạm vi và kết quả

| Gói                              | Số mục                          | Trạng thái trước                                                                                 | Đã làm hôm nay                                                           | Kết quả kiểm tra tự động                                |
| -------------------------------- | ------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------ | ------------------------------------------------------- |
| `content.seed.json` · activities | 53                              | Tiền duyệt AI 2026-10-16 ([rhythm.md](rhythm.md)), 72 chỗ sửa và 16 hoạt động mới **đã áp dụng** | Soát lại 15 điểm an toàn chính: còn 14, thiếu 1 (tuổi hiệu chỉnh, mục 3) | Seed test đạt                                           |
| `content.seed.json` · ageCards   | 35                              | Như trên                                                                                         | Như trên                                                                 | Đạt                                                     |
| `content.seed.json` · health     | 8 dấu hiệu, 5 bước, số khẩn cấp | Như trên                                                                                         | Không sửa                                                                | Đạt                                                     |
| `reference.seed.json`            | 10 giai đoạn                    | Như trên                                                                                         | Ghi rủi ro tên gọi (mục 3)                                               | Đạt                                                     |
| `toddler-v2.draft.json`          | 24                              | **Chưa ai rà**                                                                                   | **Viết lại toàn bộ** (mục 2)                                             | `activitySchema` 24/24; test `personalization-v2` 10/10 |

Điểm an toàn đã có trong seed:

- ngủ chung giảm rủi ro;
- mật ong trước 12 tháng;
- võng và nôi điện;
- than sưởi trong phòng kín;
- đuối nước (`act_water_safety_home`);
- bé bú mẹ dưới 6 tháng không cần thêm nước;
- món dễ hóc (nhãn, vải, thạch);
- giới thiệu chất gây dị ứng;
- vòng dâu tằm;
- nhiệt kế đo nách;
- hạ thân nhiệt dưới 35,5 °C;
- không lau rượu;
- không dùng aspirin.

## 2. Gói 12–36 tháng (`toddler-v2.draft.json`): những gì đã sửa

**Lỗi của bản cũ**

- **Mỗi hoạt động chỉ có 2 bước.** Bộ seed yêu cầu 3–5 bước.
- **Lời an toàn chung chung cho mọi mục** ("Có người lớn bên cạnh; dừng khi con không thoải mái"):
  - phần ăn thiếu cảnh báo hóc nghẹn cho bé tập đi;
  - phần cảm xúc thiếu lúc nào cần hỏi bác sĩ.
- **8 mục trùng với hoạt động đã có:**

  | Hoạt động nháp      | Trùng với            |
  | ------------------- | -------------------- |
  | `quiet_book`        | `choose_book`        |
  | `picture_chat`      | `act_read_together`  |
  | `point_name`        | `act_name_and_point` |
  | `small_choices`     | `act_two_choices`    |
  | `name_feeling`      | `act_big_feelings`   |
  | `pause_together`    | `near_upset`         |
  | `next_bedtime_step` | `finish_play`        |
  | `stay_at_meal`      | `eat_together`       |

  Khi gợi ý có 3 ngày nghỉ, mục trùng làm gia đình thấy lặp sớm.

- **Phần tóm tắt không nói vì sao nên thử** ("Một bước nhỏ trước giờ ngủ").

**Bản mới (version 2, vẫn `status: draft`, `review: null`)**

- **24 mục**, mỗi mục 3 bước. Phân bổ: ngủ 6, ăn 6, xoa dịu 5, chơi và tập nói 7. Tuổi 365–1.095 ngày, thời lượng ≤ 5 phút.
- **8 mục trùng được thay bằng chủ đề seed chưa có:**

  | Mục mới                                 | Nguồn                                          |
  | --------------------------------------- | ---------------------------------------------- |
  | Tắt màn hình trước giờ ngủ              | WHO 2019                                       |
  | Uống sữa xong rồi lên giường            | AAP răng miệng, NHS cốc                        |
  | Món mới, mời lại nhiều lần              | AAP dinh dưỡng bé tập đi                       |
  | Một món đồ an ủi                        | AAP: không đồ mềm trong chỗ ngủ trước 12 tháng |
  | Thổi cho dịu lại                        |                                                |
  | Chào tạm biệt rõ ràng (lo khi xa ba mẹ) |                                                |
  | Phụ ba mẹ một việc nhỏ                  |                                                |
  | Tập tự cởi một món                      |                                                |

- **Lời an toàn theo chủ đề:**
  - **Ăn:** ngồi khi ăn; cắt dọc nho, cà chua bi, nhãn, vải; không hạt nguyên, bỏng ngô, kẹo cứng, thạch cốc.
  - **Cảm xúc:** không quát hay đánh; hỏi bác sĩ nếu cơn rất thường xuyên, con tự làm đau mình hoặc nín thở đến tím tái.
  - **Chơi:** đồ to hơn miệng con, không pin cúc áo hay nam châm.
  - **Ngủ:** chỗ ngủ an toàn như mọi đêm.
- **Nguồn:** chỉ dùng các link đã có trong seed (AAP, NHS, WHO, UNICEF, CDC), 1–2 nguồn mỗi mục, đều https.

## 3. Việc người duyệt cần quyết (không tự sửa được)

1. **Tuổi hiệu chỉnh cho bé sinh non.** Thẻ "Tuần này của bé" dùng tuổi thật. Với bé sinh non, mốc phát triển nên tính theo tuổi hiệu chỉnh đến 24 tháng (tiền duyệt 16/10, mục 7). Đây là D3, đang để mở. **Đề xuất:** dùng tuổi hiệu chỉnh khi có ngày dự sinh.
2. **Tên "Wonder Weeks" của lịch giai đoạn.** Đây là nhãn hiệu thương mại. Nghiên cứu độc lập (de Weerth & van Geert, 1998, đã trích trong seed) không xác nhận các giai đoạn cố định. **Đề xuất:** đổi tên thành "Lịch tham khảo giai đoạn", hoặc thay bằng mốc CDC/WHO.
3. **Cai bình.** Bản mới viết "từ khoảng 12 tháng, chuyển dần sang cốc" (theo NHS/AAP). Cần xác nhận cách nói phù hợp với gia đình Việt.
4. **"Không quá 1 giờ màn hình mỗi ngày cho bé 2–3 tuổi"** (WHO 2019): xác nhận có nêu số cụ thể không.

## 4. Mẫu ký duyệt (người duyệt điền)

| Gói                      | Người duyệt (họ tên, chức danh, đơn vị) | Ngày | Kết luận (đạt / đạt khi sửa / không đạt) | Ghi chú |
| ------------------------ | --------------------------------------- | ---- | ---------------------------------------- | ------- |
| Activities (53)          |                                         |      |                                          |         |
| Age cards (35)           |                                         |      |                                          |         |
| Health pack              |                                         |      |                                          |         |
| Reference calendar       |                                         |      |                                          |         |
| Toddler 12–36 tháng (24) |                                         |      |                                          |         |

Khi ký xong: nhập vào portal (Nội dung → Nhịp lớn lên). Người thứ hai có quyền "Nội dung · Duyệt" ghi
`review` và xuất bản (D-058). Không sửa `review` trực tiếp trong file seed.
