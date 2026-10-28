# Cùng Chăm Con theo Figma (29/10/2026)

Chủ sản phẩm nhận xét bản cũ "chưa giống Figma một chút nào". Theo D-137, Cùng Chăm Con phải khớp section Figma `1349:22026` (22 màn). Lần này đã chụp lại từng màn qua Figma MCP rồi so với ảnh render mới của app (D-111).

## Đã làm theo Figma

| Màn | Figma | Đã đổi trong app |
|---|---|---|
| Khung chung | CCC/TaskRow, CCC/Person, CCC/Art | Thanh tiêu đề gọn: "‹ Cùng Chăm Con" và nút cài đặt hình thanh trượt. Avatar Ba, Mẹ, Bà, Ông, Cô Lan lấy từ Figma (`person-*.svg`). Tranh Tắm, Đọc sách; Vitamin dùng giọt nước. "+ Thêm việc" và "+ Giao" viền đứt. "Giao cả ca". |
| 04 Lịch chung, đầu ngày | 1380:21966 | Thẻ vàng có mặt bé, "Hôm nay có 9 việc", "Việc đầu tiên 07:00 · Bú bình" và "Ba · 4" từng người. Việc kế tiếp có nền mint. |
| 04b Đang làm | 1380:22470 | Vòng tiến độ, "Còn 5 việc nữa thôi, cả nhà cố lên!", "Cô Lan xong 2 ♡". Chỉ ghi nhận người đã làm. Bỏ dòng "Ba đã làm" dưới từng việc. |
| 04-0 Chưa có lịch | 1390:21780 | Hình bé, "Tạo nhanh trong 1 chạm…". Hai lựa chọn là cách đã chọn ("Đã chọn") và "Giống hôm qua" (chỉ số việc, theo yêu cầu chủ sản phẩm). Rồi "Đổi cách khác →" và "Tạo lịch hôm nay". |
| 01 Chọn cách | 1377:21908 / 22022 / 22151 | Màn "Lên lịch cho Teddy": Theo nhịp (Gợi ý), Theo EASY (chip tuổi, "Hợp tuổi"), Khác (Theo tuổi, Dùng lịch mọi ngày, Giống hôm qua, Tự tạo). Nút chính "Xem trước lịch" khi tạo bản nháp, "Tạo lịch" khi không. |
| 02 Gợi ý cho Teddy | 1388:21646 | Trang riêng "Lịch hôm nay": hình bé, "Theo nhịp 7 ngày qua · Đổi cách", dải giờ 6h–22h (cữ bú là chấm, giấc ngủ là vạch). Giờ nằm ở cột trái. Gợi ý vuốt một dòng. "Giờ chỉ là gợi ý, con vẫn dẫn nhịp". "Dùng lịch này" ghim dưới. |
| 05 Giao việc | 1381:22083 | Tiêu đề có biểu tượng ca, dòng "4 việc · 07:00 – 10:30". Mỗi người một thẻ có avatar và "Bà nội · 1 việc hôm nay". Chọn một người, có "Nhiều người", nút "Giao cho Cô Lan". |
| 06 Thêm việc | 1381:22208 | Ô tìm việc, 4 ô "Hay dùng cho bé …", nhóm Ăn uống, Chơi & vận động, Sức khoẻ & vệ sinh, "+ Tạo việc riêng". Giờ đi kèm ca. "Ai làm" có avatar. Nút "Thêm vào lịch". |
| 06b Sửa / xoá | 1360:23266 | Đầu sheet có tranh, tên việc và "Ca sáng". Nhóm Giờ, Người làm, Áp dụng. "Bỏ qua hôm nay cũng được [Bỏ qua]". Lưu và Xoá. Không đổi loại việc ở đây. |
| 13 Cài đặt | 1354:22802 | "Cài đặt". Thẻ Nhắc việc: Nhắc trước (5 phút / 10 / 15 / Tắt) và nhắc trong giờ yên lặng. Thẻ Lịch: Tự tạo lịch mỗi sáng. |
| 14 Home bố mẹ | 1383:22120 | Một thẻ: "n việc cần làm · Tất cả ›", việc kế tiếp có huy hiệu "Phân việc", nút "✓ Đã làm". |
| 15 Đến giờ rồi | 1390:21919 | Huy hiệu "Đến giờ rồi" và "Phân việc", giờ to, "Mẹ nhờ Ba nhé" có avatar. "Đã làm" nằm cạnh "Để sau 10′". "Xem cả lịch hôm nay →". Server ghi thêm `assignedBy` khi giao việc. |
| 16 Home người hỗ trợ | 1356:22960 | Avatar và "Chào Cô Lan". Thẻ ca màu mint. Ba ô ghi nhanh Bú bình, Ngủ, Thay tã. "Việc của tôi" kèm số. Thẻ ghi chú. "Bàn giao cho bố mẹ". |

## Khác Figma vì đã có quyết định (giữ nguyên)

- **EASY chỉ cho bé dưới 6 tháng (D-136 #4).** Figma 01 có EASY 3, 2-3-4, 5-6 và chỉ cảnh báo khi lệch tuổi (01b). App chỉ có EASY 3.5 và EASY 4, ẩn với bé từ 6 tháng.
- **Theo nhịp chỉ khi đủ 7/7 ngày (D-136 #2).**
- **Lịch mẫu chỉ có trên dev, chờ duyệt nội dung (D-136 #1).** Đã bỏ chữ "(chờ duyệt)" khỏi giao diện để giống Figma. Giới hạn dev và dòng "Lịch mẫu không phải lịch y tế…" vẫn giữ.
- **Bản nháp chỉ thành lịch khi bấm "Dùng lịch này" (D-136 #3).** Đây là màn 02.

## Cần chủ sản phẩm quyết (L3, chưa làm)

1. **01 thêm EASY 3, 2-3-4, 5-6 và cảnh báo lệch tuổi (01b) thay vì ẩn.** Việc này đổi D-136 #4 và cần soạn nội dung mẫu mới.
2. **01 "Theo nhịp" có chip số liệu ("Bú ~3g30/cữ", "3 giấc ngày", "Ngủ đêm 19:30").** Cần tính thêm từ 7 ngày ghi. Đây là phần giải thích có tính chất sức khoẻ.
3. **01c "Tự tạo" hỏi giờ bé thức dậy và ngủ đêm, rồi "Khung theo tuổi / Trống".** Đây là cách tạo lịch mới.
4. **02 "Dùng lịch này cho: Chỉ hôm nay / Mỗi ngày / Chọn ngày".** Đây là cách áp dụng lịch mới, nhất là "Chọn ngày". Mỗi việc có lý do "thường ~07:05" cũng cần lưu thêm dữ liệu.
5. **05 "Hay nhận ca sáng".** Cần đếm lịch sử ai hay nhận ca nào.
6. **06 "Ghi ngay" (ghi việc ngoài lịch ngay trong sheet).** Đây là đường ghi mới.
7. **13 "Gộp việc gần nhau" thành công tắc, và "Quyền với lịch" theo từng người.** Đây là tuỳ chọn và quyền mới. "Lịch sử thay đổi" thuộc bước 5.
8. **17 Bàn giao.** App đang dùng màn tóm tắt AI (D-093) có trạng thái bé, cữ tới, "Gọi 115", "Sơ cứu". Figma 17 chỉ có: người giao → bố mẹ, 3 ô số liệu, "Việc còn lại trong ngày" và lời nhắn. Làm theo Figma nghĩa là bỏ phần AI và phần an toàn cho người hỗ trợ.
9. **16 bỏ chọn bé và Night care khỏi đầu trang (Figma chỉ có chuông).** App vẫn giữ nút Night care, vì không có chỗ khác để bật.
10. **Nút báo cáo (biểu đồ) trên thanh tiêu đề.** Thuộc màn 11 (bước 6), chưa có màn nên chưa hiện.

Màn 03 (push N5), 09, 10, 11, 12, 18, 20 thuộc bước 5 và 6, chưa làm trong đợt này.

## Kiểm chứng

- Golden đã render lại và xem: `care_plan/*` 40 ảnh, `care_plan_today/*` 20 ảnh, `care_plan_shift/*` 12 ảnh, Light / Night × vi / en. Đã sửa một lỗi nhìn thấy trên ảnh: gợi ý vuốt có chữ trùng màu nền.
- Test hành vi: `care_plan_test` 21, `care_plan_today_test`, `care_plan_shift_test`, `today_home_layout_test`, `notifications_test` (84 pass). Chữ 200 % không tràn, kể cả 01 và khối Home.
- Server: thêm `assignedBy` trong `saveCarePlanItem` / `assignCarePlanItems`. Emulator: 33 test care-plan pass. **Chưa deploy dev.**
- Chưa kiểm trên máy thật và VoiceOver.
