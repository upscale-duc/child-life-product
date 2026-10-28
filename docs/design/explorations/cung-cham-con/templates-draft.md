# Lịch mẫu Cùng Chăm Con — bản nháp chờ duyệt (D-136 #1)

**Trạng thái:** engineering soạn ngày 28/10/2026, **chưa được chủ sản phẩm duyệt**. Chỉ hiện trên bản dev (app: `AppEnvironment.dev`; server: `carePlanTemplatesOffered()` từ chối ngoài dev). Code: `packages/contracts/src/care-plan-drafts.ts` (`templateDraft`). Khi duyệt xong: sửa nội dung trong file đó nếu cần, bỏ chữ "(chờ duyệt)" ở `cpTemplatesSection`, và bỏ giới hạn dev ở hai chỗ trên.

## Nguyên tắc chung

- Chỉ có **bú, ngủ và vài việc nhẹ nhàng** (nằm sấp, tắm, đọc sách, đi dạo, đánh răng). **Không có thuốc, vitamin hay liều** (FLOW §4), không có thay tã (thay tã theo bé, không theo giờ).
- Giờ là điểm bắt đầu để gia đình sửa. Mẫu tạo **bản nháp**, chỉ thành lịch khi có người bấm "Dùng lịch này".
- Bú dùng việc **Bú mẹ** hoặc **Bú bình** theo loại nhà mình ghi nhiều hơn trong 7 ngày qua (mặc định Bú bình).
- Dưới danh sách có dòng: "Lịch mẫu không phải lịch y tế. Bú và ngủ luôn có thể khác dự kiến."

## EASY 3.5 (khoảng 6 tuần – 4 tháng)

Bú mỗi ~3,5 giờ; ngủ sau một quãng thức ngắn. Nguồn: Tracy Hogg, *Secrets of the Baby Whisperer* (2001) và *The Baby Whisperer Solves All Your Problems* (2005), phần lịch EASY 3 giờ / 4 giờ và biến thể 3,5 giờ hay được cộng đồng dùng.

| Giờ | Việc |
|---|---|
| 07:00 | Bú |
| 08:30 | Ngủ |
| 10:30 | Bú |
| 12:00 | Ngủ |
| 14:00 | Bú |
| 15:30 | Ngủ |
| 17:30 | Bú |
| 18:30 | Tắm |
| 19:00 | Ngủ (đêm) |
| 22:00 | Bú (cữ đêm sớm) |

## EASY 4 (khoảng 4 – 6 tháng)

Bú mỗi ~4 giờ, ba giấc ngày, ngủ đêm khoảng 19:00–19:30. Nguồn như trên.

| Giờ | Việc |
|---|---|
| 07:00 | Bú |
| 09:00 | Ngủ |
| 11:00 | Bú |
| 13:00 | Ngủ |
| 15:00 | Bú |
| 17:00 | Ngủ (giấc ngắn) |
| 18:15 | Tắm |
| 18:45 | Bú |
| 19:30 | Ngủ (đêm) |

## Lịch cơ bản theo tuổi

Tuổi lấy từ ngày sinh của bé (không có thì dùng nhóm 3–6 tháng). Nguồn tham khảo: AAP HealthyChildren.org — *How Often and How Much Should Your Baby Eat?* (bé sơ sinh bú khoảng mỗi 2–3 giờ, 8–12 lần/ngày; khoảng 2 tháng mỗi 3–4 giờ); *Starting Solid Foods* (ăn dặm quanh 6 tháng); AASM/AAP khuyến nghị giấc ngủ theo tuổi (4–12 tháng 12–16 giờ/24 giờ kể cả giấc ngày; 1–2 tuổi 11–14 giờ); AAP về nằm sấp khi thức và đọc sách cho trẻ từ sớm.

| Nhóm tuổi | Việc |
|---|---|
| Dưới 3 tháng | Bú 07:00, 10:00, 13:00, 16:00, 19:00, 22:00 (chỉ là mốc nhắc, bé vẫn bú theo nhu cầu) · Nằm sấp 09:00 · Tắm 18:30 |
| 3 – 6 tháng | Bú 07:00, 10:30, 14:00, 17:30, 21:30 · Ngủ 09:00, 12:30, 16:00, 19:30 · Nằm sấp 10:00 · Tắm 18:30 |
| 6 – 12 tháng | Bú 07:00, 11:00, 15:00, 19:00 · Ăn dặm 08:30, 17:00 · Ngủ 09:30, 14:00, 19:30 · Tắm 18:30 · Đọc sách 19:15 |
| Từ 12 tháng | Ăn 07:30, 12:00, 18:00 · Ngủ trưa 12:30 · Đi dạo 16:30 · Tắm 19:00 · Đánh răng 19:30 · Đọc sách 19:40 · Ngủ 20:00 |

## Cần chủ sản phẩm quyết khi duyệt

- Giữ tên "EASY" (tên phương pháp của một tác giả) hay đổi thành mô tả trung tính ("Bú mỗi 3,5 giờ").
- Nhóm "dưới 3 tháng" có nên có mẫu không, vì bé sơ sinh bú theo nhu cầu.
- Có cần chuyên gia nội dung (như Thư viện) xem lại trước khi bật cho prod.
