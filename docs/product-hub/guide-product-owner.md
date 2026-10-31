# Sản phẩm · Hướng dẫn cho chủ sản phẩm

Mục **Sản phẩm** trong portal giúp anh/chị hiểu toàn bộ Child Life từ bằng chứng: tính năng nào
có, làm gì, đang ở đâu, thuộc gói nào, tài liệu nào nói gì — và chỗ nào còn thiếu hoặc mâu thuẫn.

## Bốn tab

| Tab | Dùng để |
|---|---|
| **Tổng quan** | Xem nhanh số tính năng theo trụ cột và vòng đời, độ đầy đủ tri thức, xung đột, quyết định gần đây. Bấm vào một con số để mở danh sách đã lọc. |
| **Tính năng** | Danh mục 49 tính năng, lọc theo trụ cột, vòng đời, gói, độ đầy đủ, kiểm chứng. Mở một tính năng để xem trang đặc tả. |
| **Gói & quyền** | Free / Premium theo tính năng và quyền, gói mặc định trong mã và gói đang đặt. **Chỉ xem**; đổi ở Tính năng & Premium. |
| **Nguồn tri thức** | Thư viện tài liệu trong repo (mức tin cậy, revision) và hàng **Chờ duyệt** các thay đổi từ đồng bộ. |

## Đọc trạng thái của một tính năng

Bốn ô riêng, không gộp: **Vòng đời** (đã xây, đang làm…), **Triển khai** (có mã, một phần, chưa
thấy mã), **Kiểm chứng** (đã đọc mã, kiểm thử đạt, đã kiểm trên máy), **Phát hành**. Hiện chưa
tính năng nào "Đã phát hành" vì app chưa go-live.

**Độ đầy đủ** là điểm cố định trên 9 phần (vấn đề, giá trị, luồng, quy tắc, trường hợp biên, gói,
tham chiếu kỹ thuật, chỉ số, quyết định). Phần đã duyệt tính đủ, bản nháp 40 %, phần đã cũ mất một
nửa; còn xung đột thì tối đa 69. Số lượng tài liệu không làm tăng điểm. Bên dưới điểm là "Việc nên
làm tiếp".

## Viết và duyệt nội dung

- Người có quyền **Sửa** bấm **Viết/Sửa** ở một phần, nhập tiếng Việt (tiếng Anh không bắt buộc) và
  nguồn (mỗi dòng một nguồn: `D-150`, đường dẫn tài liệu, `tệp:dòng`), rồi **Lưu nháp**.
- Một **người khác** có quyền **Duyệt** bấm **Duyệt**. Riêng Owner được tự duyệt (D-155).
- Khi tài liệu nguồn thay đổi sau đó, phần đã duyệt **không bị ghi đè**; nó hiện "Nguồn đã đổi sau
  khi duyệt" để anh/chị xem lại.

## Duyệt đồng bộ

Kỹ sư chạy công cụ đồng bộ; một bộ thay đổi xuất hiện ở **Nguồn tri thức › Chờ duyệt**. Mở nó để
xem tài liệu mới/đổi/chuyển/xoá (có so sánh trước–sau), xung đột mới, tính năng và quyết định.
**Duyệt và áp dụng** thì tri thức mới có hiệu lực; **Từ chối** thì mọi thứ giữ nguyên.

## Xung đột

Khi tài liệu nói khác mã (ví dụ `plans-credits-analysis.md` nêu Free / Plus / Pro, còn mã chỉ có
Miễn phí · Premium · Beta), hệ thống hiện **cả hai** với mức tin cậy và ngày, **không tự chọn**.
Quyết định cuối cùng vẫn ghi trong `business-map.md`.

## Chưa có ở giai đoạn này

Tải tài liệu lên (PDF/DOCX), Copilot hỏi đáp AI, Hành trình, Cơ hội & Quyết định, số liệu sử dụng.
