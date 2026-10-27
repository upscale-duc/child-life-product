# Portal — wording và UI/UX · 26/10/2026

## Kết quả

Đã rà 24 mục điều hướng chính và các tab/biểu mẫu liên quan, sửa trực tiếp trong React portal. Viết lại **384 chuỗi tiếng Việt, 52 chuỗi tiếng Anh**, thêm 26 ID song ngữ cho mô tả tìm trang, bảng cuộn và múi giờ. Các giá trị đã rõ được giữ lại; đây không phải tuyên bố đã viết lại toàn bộ hơn 5.000 ID mỗi ngôn ngữ.

Người dùng ở đây là nhân viên vận hành, biên tập, chuyên gia và quản trị viên. Mục tiêu: hiểu số liệu/trạng thái đang xem, tìm đúng trang, biết hành động tiếp theo và hậu quả của hành động. Phụ huynh hưởng lợi gián tiếp từ nội dung và thao tác vận hành chính xác hơn.

- Dùng tiếng Việt cụ thể thay cho thuật ngữ kỹ thuật lẫn Anh/Việt; nút gọi đúng kết quả hành động.
- Trạng thái gửi thông báo tách rõ: dịch vụ đã nhận ≠ đã hiện trên thiết bị; dùng mẫu mặc định ≠ ngừng gửi thông báo.
- Print Studio ưu tiên danh sách đơn; nhu cầu và cấu hình mở khi cần. Các tính năng vẫn có thể truy cập.
- Bảng và tab dùng được bằng bàn phím; sửa tràn ngang trang Tính năng ở 390px; nhãn biểu mẫu gắn với ô nhập và lỗi.
- Tìm trang có mô tả ngắn và tìm được bằng tiếng Việt không dấu.

[Xem ảnh so sánh theo màn hình](assets/2026-10-26-portal/index.html) · [Các chuỗi trước/sau](assets/2026-10-26-portal/copy-changes.json) · [Manifest kiểm tra](assets/2026-10-26-portal/manifest.json).

## Nguồn và phạm vi bằng chứng

Nguồn chính: `apps/portal/src/Shell.tsx`, `ui.tsx`, `content-kit.tsx`, `components/ui/tabs.tsx`, `styles.css`, các `messages*.ts`, và toàn bộ `screens/`. Đối chiếu contracts, kiểm tra nghiệp vụ hiện có và quyết định trong `docs/product/business-map.md`; giữ nhóm/thứ tự điều hướng đã được quyết định. Skills dùng: senior-ui-ux, cl-design-review, cl-screen-patterns, cl-components, cl-design-foundations và cl-ux-writing; áp dụng quy trình đánh giá vào React/shadcn hiện có, không port widget Flutter vào portal.

| Bằng chứng | Phạm vi thực tế |
|---|---|
| R — trình duyệt thật | Google Chrome headless, React thật, dữ liệu mẫu từ unit tests; không dùng Figma hoặc ảnh cũ để kết luận giao diện hiện tại |
| Ảnh cuối | 61 route/tab/biểu mẫu × vi/en × sáng/tối = 244 ảnh; thêm 5 ảnh 390px và 6 ảnh bố cục tương đương zoom 200% = 255 |
| Kiểm tra ảnh | Xem contact sheet phần đầu của 61 màn hình tiếng Việt; xem ảnh đầy đủ các màn chính và mẫu vi/en, sáng/tối, nhỏ/zoom; không khẳng định đã đọc từng dòng của cả 255 ảnh |
| C — mã và kiểm tra | 729 bài kiểm tra, gồm nghiệp vụ hiện có, 6 kiểm tra thành phần/trạng thái và 397 kiểm tra giữ biến/định dạng song ngữ |
| Tương tác browser | 10 kiểm tra: không tràn trang 390px, chuyển tab/phím, tìm không dấu và mở trang, mở/sửa cấu hình in, trạng thái tải/lỗi, liên kết nhãn biểu mẫu, mở editor thông báo |
| Vai trò | Ảnh chủ yếu owner; quyền admin/analyst/expert/support/tester dựa vào bộ kiểm tra hiện có, không phải ảnh mọi tổ hợp quyền |
| Chưa kiểm tra | Trình đọc màn hình, OS font scaling, mọi tên cực dài, mọi trạng thái offline; đăng nhập Firebase, gửi thông báo, xuất dữ liệu, thanh toán hoặc cập nhật dữ liệu thật |

Các ảnh `before/`, `baseline/`, `candidate-A/`, `iteration-1/` được giữ làm lịch sử. Một số ảnh đầu có fixture thiếu (đặc biệt Print Studio và Bảng tham chiếu); đó **không phải bằng chứng lỗi production**. Print Studio dùng A với dữ liệu đầy đủ làm mốc so sánh bố cục. Một lần chạy tương tác bị HMR làm tải lại trang lúc format harness; chạy lại khi nguồn ổn định đạt đủ 10/10.

Dữ liệu analytics mẫu còn thưa; vài tab dùng lại metric của tổng quan, nên biểu đồ rỗng trong harness không chứng minh production thiếu dữ liệu. Kiểm tra logic/chỉ số cụ thể dựa thêm vào tests và contracts.

## Phân loại cấu trúc và scorecard từng mục

Thang 0–5 theo rubric của cl-design-review, chỉ cho phạm vi đã thấy. Đây là nhận định thiết kế, không phải điểm đo từ nghiên cứu người dùng. Các cột: T = rõ tác vụ, H = phân cấp, S = dễ quét, I = điều khiển, N = điều hướng, V = nhất quán thị giác, C = wording/song ngữ, Tr = trạng thái/tin cậy, A = thích ứng/truy cập, P = nhận diện Child Life, D = cần thiết/mật độ. Nêu giới hạn trên cho mọi điểm; A không quá 3 vì chưa kiểm tra screen reader. Không tính điểm trung bình để che điểm thấp.

| Mục / route | Việc cần làm và quyết định | T | H | S | I | N | V | C | Tr | A | P | D |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Tổng quan `/` | Hiểu tình hình và việc cần xử lý; REFINE nhãn, giữ nhóm số liệu |4|4|4|3|4|4|4|3|3|4|4|
| Phân tích `/analytics` | Đọc chỉ số đúng kỳ/mẫu số; REFINE thuật ngữ, ngày và chú giải |4|4|3|4|4|4|4|3|3|4|4|
| Gia đình `/families` | Tra gia đình và dung lượng; REFINE bảng, diễn đạt |4|4|4|3|4|4|4|3|3|4|4|
| Hỗ trợ `/support` | Tìm và xử lý yêu cầu; REFINE trạng thái, hướng dẫn |4|4|4|3|4|4|4|3|3|4|4|
| Mở rộng dung lượng `/storage` | Duyệt yêu cầu; REFINE nhãn/giải thích, giữ quyền duyệt |4|4|4|3|4|4|4|3|3|4|4|
| Yêu cầu dữ liệu `/jobs` | Phân biệt tác vụ xuất/xoá; REFINE trạng thái và đơn vị |4|4|4|3|4|4|4|3|3|4|4|
| Thông báo `/notifications` | Soạn mẫu, theo dõi gửi; REFINE wording/tab; cài đặt vẫn nhiều trường |4|4|3|4|4|4|4|4|3|4|3|
| Sơ cứu `/first-aid` | Biên tập/duyệt tình huống; REFINE nhãn, giữ quy trình duyệt |4|4|4|3|4|4|4|3|3|4|4|
| Nhịp lớn lên `/rhythm` | Soạn và kiểm tra mô hình; REFINE thuật ngữ, giữ cảnh báo |4|4|3|3|4|4|4|3|3|4|4|
| Mẫu kỷ niệm `/keepsakes` | Quản lý mẫu/tệp; REFINE từ ngữ, giữ gallery |4|4|4|3|4|4|4|3|3|4|4|
| Print Studio `/print-studio` | Xử lý đơn in; RESTRUCTURE đơn trước, phần ít dùng thu gọn |4|4|4|4|4|4|4|4|3|4|4|
| Thư viện chăm bé `/articles` | Soạn và duyệt bài; REFINE trường/bộ lọc, giữ editor và preview |4|4|4|4|4|4|4|3|3|4|4|
| Nội dung theo giai đoạn `/stages` | Soạn nội dung theo tuổi; REFINE nhãn và đơn vị |4|4|4|4|4|4|4|3|3|4|4|
| Mốc phát triển `/milestones` | Soạn mốc và độ tuổi; REFINE lời dẫn, giữ cấu trúc |4|4|4|4|4|4|4|3|3|4|4|
| Dinh dưỡng `/nutrition` | Quản lý giai đoạn/vi chất/quy tắc; REFINE diễn đạt, giữ cảnh báo |4|4|3|4|4|4|4|3|3|4|4|
| Ăn dặm `/solids` | Quản lý thực phẩm/công thức; REFINE nhãn, tuổi/đơn vị rõ hơn |4|4|3|4|4|4|4|3|3|4|4|
| Duyệt nội dung `/content-review` | Chọn mục cần duyệt; KEEP bố cục, dùng cải tiến shared |4|4|4|3|4|4|4|3|3|4|4|
| Bảng tham chiếu `/reference` | Kiểm tra bảng dùng trong app; REFINE nhãn staff, giữ dữ liệu |4|4|4|4|4|4|4|3|3|4|4|
| Hệ thống & AI `/system` | Theo dõi tác vụ/chi phí; REFINE từ kỹ thuật và đơn vị |4|4|3|4|4|4|4|3|3|4|4|
| Tính năng & Premium `/features` | Kiểm tra phạm vi bật; REFINE chữ, màu và overflow |4|4|3|4|4|4|4|3|3|4|3|
| Cập nhật ứng dụng `/app-update` | Cấu hình và xem trước; KEEP bố cục, cải thiện shared/tab |4|4|3|4|4|4|4|3|3|4|3|
| Nhân sự `/staff` | Xem vai trò/quyền; REFINE giải thích, không đổi quyền |4|4|4|3|4|4|4|3|3|4|4|
| Nhật ký `/audit` | Tra thao tác; KEEP bố cục, cải thiện bảng/tìm kiếm |4|4|4|3|4|4|4|3|3|4|4|
| Sổ tay kiểm thử `/qa` | Chọn lượt/ca kiểm thử; REFINE hướng dẫn, giữ quy trình |4|4|3|3|4|4|4|3|3|4|3|

Màn đăng nhập cũng được rà và chụp vi/en × sáng/tối. Các mục KEEP/REFINE không cần đổi bố cục lớn: nhóm nội dung, bảng/editor/preview đang khớp công việc; phần gây khó hiểu chủ yếu nằm ở lời dẫn, nhãn và thành phần chung. Các trang cấu hình chuyên sâu vẫn dài khi mở toàn bộ trường; không khẳng định đã loại bỏ mọi thao tác dài.

Critical gates trong phạm vi C/R đã kiểm tra: G1 ý nghĩa nghiệp vụ **pass**; G2 truy cập hành động **pass có giới hạn** (keyboard và viewport được kiểm tra, screen reader chưa đánh giá); G3 mất dữ liệu **pass C** (giữ luồng xác nhận/lưu hiện có, không thử xoá thật); G4 quyền **pass C/tests**; G5 AI/sức khoẻ **pass C** (không viết lại lời khuyên y khoa hay thêm claim); G6 tác vụ chính **pass có giới hạn** (tương tác mẫu + tests, chưa xác minh vận hành với backend thật). Không có gate mới thất bại được phát hiện. Không có lỗi Blocker/High mới còn mở trong phạm vi này.

## Findings và nội dung được tinh giản

| ID | Vấn đề và ảnh hưởng | Bằng chứng | Mức / ưu tiên / tự chủ | Đã xử lý |
|---|---|---|---|---|
| P01 | Thuật ngữ pha Anh/Việt và trạng thái ngắn khiến nhân viên phải đoán | C/R, catalogs + ảnh analytics/notifications/system | Medium / P1 / L1 | REWRITE dùng từ cụ thể, giữ định nghĩa, mẫu số, cửa sổ quan sát |
| P02 | “Tạm dừng” mẫu dễ bị hiểu là không gửi thông báo | C, TemplateEditor + cơ chế fallback; R editor published | High / P1 / L1 | REWRITE nút/trạng thái “Dùng bản mặc định”, lời xác nhận nói vẫn gửi; tạm dừng gửi đến thiết bị giữ riêng |
| P03 | Bảng Print Studio không có class trình bày; số liệu nhu cầu và cấu hình lấn nhiệm vụ xử lý đơn | R candidate A, C PrintStudio | Medium / P1 / L2 | RESTRUCTURE + RELOCATE đơn trước, nhu cầu/cấu hình thu gọn, style bảng thống nhất |
| P04 | Trang Tính năng tràn ngang ở 390px do vị trí phần tử ẩn của heading trong bảng | R/C, probe + styles | High / P1 / L1 | Chặn tràn ở vùng bảng bằng containing block, giữ cuộn bảng; kiểm tra browser 390px đạt |
| P05 | Nhãn/helper/lỗi ở Field chưa gắn trực tiếp ô nhập; tab chưa có phím mũi tên nhất quán | C/R, shared components | Medium / P1 / L1 | Liên kết label/description/error; roving focus + Home/End; TableScroll có vùng được đặt tên và focus |
| P06 | Tìm trang chỉ dựa tên, khó tìm khi không biết thuật ngữ menu | C/R, Shell | Medium / P2 / L1 | Thêm mô tả ngắn, từ khoá không dấu; không thêm destination |
| P07 | Tính năng tắt dùng màu lỗi khiến trạng thái bình thường giống sự cố | R/C, FeatureHub | Low / P2 / L1 | Đổi về màu trung tính, vẫn có chữ trạng thái và switch |
| P08 | Print Studio có progress và lỗi chung nhưng thiếu retry chuẩn của portal | C và ảnh trạng thái mẫu | Medium / P2 / L1 | Tái dùng Loaded/ErrorState và “Thử lại”; không gọi đây là lỗi loading-as-empty của bản cũ |

| Nội dung / cấu trúc | Phân loại | Hành động và lý do |
|---|---|---|
| Tên nút, lỗi, trợ giúp khó hiểu | Essential | REWRITE: rõ việc, kết quả, đơn vị, bước tiếp theo |
| Khoảng ngày, múi giờ, cơ sở tính chỉ số | Essential | PRESERVE: ngày dễ đọc, vẫn tính theo timezone hợp đồng |
| Cảnh báo, quyền, nháp/xuất bản, chưa lưu, xóa dữ liệu | Essential | PRESERVE: giữ điều kiện và hậu quả, không giấu sau phần thu gọn |
| Nhu cầu và danh mục/giao hàng Print Studio | Contextual | RELOCATE: giữ nút mở có tên; không cạnh tranh với danh sách đơn |
| Ghi chú lặp hoặc chỉ lộ thuật ngữ nội bộ | Redundant/Contextual | REWRITE/MERGE vào nhãn hoặc hướng dẫn đúng nơi; không thêm lời giải thích lặp trên đầu trang |
| Nút xoá bộ lọc khi chưa lọc | Redundant | REMOVE khi không có bộ lọc; luôn hiện số kết quả |
| Màu đỏ của tính năng đang tắt | Redundant | REMOVE dấu hiệu “lỗi”; trạng thái chữ giữ nguyên |
| Nội dung mẫu app, tư vấn y khoa, chính sách, giá trị contracts | Essential | PRESERVE; không sửa chuyên môn hoặc business semantics qua một đợt polish |

## A/B Print Studio và vòng tự rà

A là bố cục cũ đã sửa wording, vẫn hiển thị nhu cầu và toàn bộ cấu hình. B đặt đơn gần đây trước, hai nhóm phụ thu gọn, có khoảng cách và bảng đúng thành phần hiện có. [A vi/sáng](assets/2026-10-26-portal/candidate-A/print-studio_vi_light_1440.png) → [B vi/sáng](assets/2026-10-26-portal/after/print-studio_vi_light_1440.png); các bản en/tối có trong gallery.

| Tiêu chí | Trọng số | Nhận định từ bản dựng |
|---|---:|---|
| Hiệu quả tác vụ chính |25%| B đưa đơn và nút Mở đơn lên vùng đầu |
| Phân cấp |20%| B tách xử lý hằng ngày khỏi cấu hình ít dùng |
| Rõ/rút gọn |20%| B giảm nội dung mặc định; A vẫn dài dù wording tốt hơn |
| Tương tác |15%| B thêm một lần mở cho cấu hình; đã xác minh mở và sửa được |
| Thị giác |10%| B có bảng/các nhóm cách nhau, không dính chữ như A |
| Nhất quán/truy cập |10%| B dùng Section/Loaded chung, trạng thái có ngữ nghĩa; chưa kiểm tra screen reader |

Chọn B (L2), không cần quyết định sản phẩm mới. Đây là phán đoán từ layout, không có số liệu thời gian hoàn thành hay thử nghiệm người dùng. Vòng đầu B còn để nhu cầu trước đơn; sau xem ảnh đã chuyển đơn lên đầu và render lại. Một nhãn “Sức khoẻ” của Nhịp lớn lên được giữ đúng nghĩa sau kiểm tra nguồn; không đổi nó thành nhịp sinh hoạt.

Tự rà 10 câu: (1) công việc chính rõ ở heading/bảng/CTA; (2) đơn in thắng thông tin cấu hình; (3) không thêm lại title/subtitle trùng header; (4) màu lỗi dành cho lỗi thật; (5) tìm không dấu và keyboard giảm cản trở; (6–7) đã render vi/en, sáng/tối; (8) chỉ xác minh bố cục zoom tương đương, font scaling chưa đánh giá; (9) thêm thao tác mở cho nhóm ít dùng, giữ nguyên khả năng chỉnh sửa; (10) A/B cho thấy cải thiện phân cấp, không tuyên bố hiệu quả đo được. Các trang chuyên sâu còn dày được ghi nhận ở scorecard thay vì chấm tối đa.

## Kiểm tra cuối và giới hạn

- `pnpm --filter child-life-portal test`: **729/729**, 21 files. 397 cases kiểm tra các biến và ICU của copy song ngữ, không chỉ snapshot giá trị mới.
- Baseline detached HEAD `1be24ba8`: **325 pass, 1 fail** do expectation sidebar admin cũ thiếu Print Studio đã tồn tại. Sửa expectation đúng sidebar hiện có; không đổi quyền expert hay ẩn bài kiểm tra.
- `pnpm --filter child-life-portal run build:dev`: typecheck và build đạt. Vẫn có cảnh báo bundle >500kB vốn có; chưa thực hiện tối ưu chia bundle trong đợt wording này.
- ESLint `apps/portal/src` và `test/readability.test.tsx`, cùng `git diff --check`: đạt.
- Browser interactions **10/10**; batch ảnh cuối **255**, không ghi nhận pageerror/console error hoặc tràn ngang trang. Bảng rộng vẫn có thể cuộn bên trong vùng của nó.
- [Hướng dẫn tái dựng](../../../apps/portal/test/design-review/README.md) và scripts được giữ trong test harness. Ảnh trước và các vòng thử giữ nguyên, không cập nhật golden unrelated.

Các thay đổi nằm ở UI/copy. Chưa deploy. Không gửi thông báo, không sửa dữ liệu thật và không thay giá/quyền/quy trình duyệt. Không có quyết định L3 cần chặn đợt này. Kết quả đạt cho phạm vi đã kiểm tra; chưa chứng nhận toàn bộ accessibility hoặc mọi tình huống vận hành live.

## Triển khai theo yêu cầu tiếp theo

Ngày 26/10/2026, đã chạy `scripts/deploy.sh dev hosting:admin` và phát hành lên [portal dev](https://child-life-dev-admin.web.app). Chỉ target hosting admin được deploy. Nguồn portal khớp checksum của bản đã kiểm tra trước deploy. HTTP 200; HTML và JS/CSS đang phục vụ khớp từng byte với build local; route `/print-studio` trả đúng SPA. [Bằng chứng deploy](assets/2026-10-26-portal/deployment.json).

Smoke test trên Chrome sau deploy: màn đăng nhập hiển thị, không có pageerror; chưa thực hiện luồng đăng nhập hoặc thao tác dữ liệu thật.
