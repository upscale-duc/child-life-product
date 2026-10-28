# Home — ghi trực tiếp từ card · 2026-10-28

## Kết quả

Home dashboard cho người cùng nuôi/người chăm sóc: giảm thao tác ghi cữ bú và thay tã khi đang chăm bé. Phân loại REFINE: giữ bố cục đã duyệt; đổi hành vi nút theo yêu cầu rõ ràng của chủ sản phẩm (D-132, thay phần preset mở form của D-131).

| Nút | Trước | Sau |
|---|---|---|
| Lượng sữa | 60 / 90 ml mở form, cần Lưu | Hai lượng theo bảng tuổi hiện có; ưu tiên hai lượng khác nhau vừa lưu của người dùng. Chạm ghi ngay. |
| Khác | Mở form nhập | Giữ form; lượng đã lưu được nhớ cho lần sau. |
| Ướt / Bẩn / Cả hai | Mở form | Ghi ngay, có Hoàn tác. |
| Bên trái / Bên phải | Mở form nhập phút | Bắt đầu timer bú mẹ tương ứng. Phiên đang chạy vẫn mở phiên đó. |

Giữ loại sữa đã dùng gần nhất, luồng nhập tay, lịch sử, quyền truy cập, trạng thái đồng bộ và hàng đợi offline hiện có. Các lượng nhớ được lưu riêng theo tài khoản + bé trên thiết bị; dọn khi đổi tài khoản hoặc mất quyền truy cập. Không thêm bảng lượng sữa hay khuyến nghị sức khỏe mới. Khi không được xem ngày sinh, dùng fallback hiện có thay vì đọc dữ liệu riêng tư.

## Simplify và review

| Thành phần | Quyết định | Lý do |
|---|---|---|
| Form xác nhận lại preset | REMOVE khỏi thao tác nhanh | Người dùng đã chọn đủ thông tin. |
| Hai lượng + Khác | PRESERVE | Hai thao tác thường dùng, vẫn nhập được lượng bất kỳ. |
| Thời điểm, đơn vị, chờ đồng bộ | PRESERVE | Phân biệt bản ghi vừa lưu tại máy với dữ liệu đã đồng bộ. |
| Đã ghi + Hoàn tác | PRESERVE | Phản hồi tức thì và sửa thao tác nhầm. |
| Card, icon, bóng Light, palette Night care | PRESERVE | Không cần thay thiết kế để sửa luồng thao tác. |

Gates G1–G6: không phát hiện lỗi mới qua code, widget tests và render trong phạm vi này. Không coi kiểm thử giả lập là xác nhận đồng bộ thực tế giữa hai máy.

| Finding | Evidence | Mức độ | Xử lý |
|---|---|---|---|
| Preset vẫn yêu cầu nhập/lưu lại, trái với ý định ghi nhanh | C: test hành vi và `today_screen.dart` | High / P1, owner-authorized L3 | Đã chuyển sang ghi trực tiếp / khởi chạy timer. |
| Ghi từ card không được đóng route Home | C: regression đẩy Home lên navigation stack | High / P1 | Tách tùy chọn đóng sheet trong `commitRecord`; test route vẫn còn. |
| Chạm hai lần có thể ghi trùng | C: regression double-tap | Medium / P1 | Chặn lặp trong 1 giây; lỗi cho phép thử lại ngay. |
| Kết quả lạc quan phải biến mất khi lưu lỗi | C: repository từ chối write | High / P1 | Xóa preview, báo lỗi và cho thử lại. |
| Lượng vừa nhập cần còn sau khi mở lại | C: Save 105 ml → reload provider từ prefs → nút 105 ml ghi trực tiếp | Medium / P1 | Đã kiểm tra. |

## Bằng chứng và xác minh

- Trước sửa: `golden_freshness.sh test/golden/home_quick_actions_golden_test.dart`: 16 Current.
- Sau sửa: đã mở 32 render Home/header Light + Night care × vi/en, gồm tên dài và chữ 200%. Lượng trên card thay đổi theo dữ liệu đã ghi; bố cục không đổi.
- Đã mở 32 isolated diffs của Home trong các harness care/timer/adaptive/hn: khác biệt chỉ ở lượng trên nút. Chỉ cập nhật các baseline Home bị tác động.
- Thêm và mở 8 render trạng thái ghi trực tiếp offline: Light/Night × vi/en × 100/200%. Chờ đồng bộ, lượng vừa ghi và Hoàn tác đều hiện; nút ở chữ lớn xếp dọc, không overflow.
- `flutter analyze` các source và test thay đổi: không có vấn đề.
- 112 feature/privacy tests qua (Home quick actions, care, timer, care hub, personalization, root privacy guard); chạy lại 20 Home/privacy tests sau chỉnh scope: qua.
- 72 golden cases liên quan qua: Home/header 32, backdrop Home 32, feedback 8.
- Full golden suite: 2042 qua, 28 lỗi có từ trước (Premium 8, premium flow audit 8, keepsake 6, home_for_baby 4, milestone 2). Giữ nguyên baseline của các lỗi ngoài phạm vi.
- Không thay backend, Firestore rules hoặc bảng tuổi đã xuất bản.

Các render:

- [Home Light vi](../../../apps/mobile/test/golden/goldens/hv/afternoon_light_vi.png)
- [Home Night vi](../../../apps/mobile/test/golden/goldens/hv/afternoon_nightCare_vi.png)
- [Ghi offline Light vi](../../../apps/mobile/test/golden/goldens/direct_care/offline_light_vi_1.0.png)
- [Ghi offline Night en, chữ 200%](../../../apps/mobile/test/golden/goldens/direct_care/offline_nightCare_en_2.0.png)

Chưa đánh giá: VoiceOver/TalkBack và thao tác thực trên hai máy cùng lúc. Chưa có xác nhận runtime mạng thật cho bản thay đổi này; widget tests dùng fake repository. Lượng nhớ là tùy chọn trên thiết bị, không phải cấu hình dùng chung cả nhà.

Bản dev đã build release và cài thành công lên iPhone Duckie qua `devicectl` (`/tmp/quick-direct-duckie-device-install.log`); lệnh Flutter install/launch tự động trước đó thất bại nên không dùng nó làm bằng chứng cài thành công.
Máy đang khóa nên không khởi chạy tự động được; lần thử lại trả `Locked`. Cần mở khóa và mở Child Life Dev để thử trên máy.
