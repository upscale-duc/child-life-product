# Render review và giới hạn kiểm chứng

Ngày 28/10/2026. Phạm vi: review chức năng hiện có và thiết kế prototype; **không triển khai tính năng vào ứng dụng**.

## Kết quả tự động

| Kiểm tra | Kết quả | Phạm vi |
|---|---|---|
| Baseline Gia đình + Bàn giao | **12/12 pass** | `family_golden_test.dart`, `ai_golden_test.dart`, filter `14a_family|su01_create|su01_carer|su01_sent|su01_received`. Các case thật được chọn: Family, create và received × 4 variants |
| Baseline vòng đời việc | **4/4 pass** | `personal_day_golden_test.dart --name handover`; không update baseline |
| Analyze prototype | **No issues found** | `flutter analyze test/design_explorations/care_coordination` |
| Render + tương tác prototype | **78/78 pass** | Lệnh renderer trong README; chỉ ghi ảnh proposal ở docs |
| Flutter web | Biên dịch và phục vụ bằng web-server | Entry độc lập, không gọi Firebase; không coi đây là kiểm thử trình duyệt hoặc native end-to-end |

78 case gồm: 40 main renders (10 màn × vi/en × Light/Night), 5 trạng thái overview (offline/empty/loading/error/relative), 20 probe chữ 200% (10 màn × vi/en), 4 probe tên dài ở chữ 200% × locale/palette, 9 case tương tác. Tất cả kiểm tra không có exception layout trong fixture được chạy.

Tương tác kiểm: đổi người và giờ giao việc phản ánh trên overview; gửi không nhận ca; nhận ca đổi người đang chăm và mở việc; nhận việc → xong → undo; bú không lưu lượng trống; lịch không lặp thao tác áp dụng trong phiên; caregiver không có control phân công; offline chặn nhận ca; khóa ẩn chi tiết; action nhanh ở trạng thái chờ đồng bộ; lời cảm ơn không có nút gửi lại; trả lại việc đã nhận. Đây là state machine trong bộ nhớ của mockup, không kiểm transaction hoặc delivery thật.

Log của lượt chạy nằm ngoài repository tại `/tmp/childlife-coordination-{baseline,work-baseline,analyze,render,web}.log`. Artefact bền vững là nguồn renderer, PNG, PDF và tài liệu. Không thay ảnh baseline app để làm test pass. Chạy đối chiếu trực tiếp thay vì script freshness có bước dọn thư mục failures chung, nhằm tránh đụng evidence phiên khác.

## Evidence được xem bằng image viewer

| Nhóm | Đã xem trực tiếp | Giới hạn |
|---|---|---|
| Hiện tại: Gia đình | `goldens/s3/14a_family_*` cả 4 locale/palette | Fixture cố định 08/10, không phải dữ liệu live |
| Hiện tại: Bàn giao create | `goldens/ai/su01_create_*` cả 4 | Render dài 375 × 1240 trong harness hiện có |
| Hiện tại: Bàn giao received | `su01_received_light_vi` | Các variant khác pass tự động; không tuyên bố xem đủ bằng mắt |
| Hiện tại: việc chăm sóc | `pd/handover_light_vi`, `pd/handover_nightCare_en` | Hai variant còn lại được tự động đối chiếu |
| Màn chính proposal | `overview_*` cả 4 locale/palette | Đã kiểm lại sau chỉnh cách hiển thị người đang chăm |
| Flow phụ | assignment/outgoing/incoming/simple/routine/family Light vi; simple Night en; notifications Light vi + Night en; gratitude/quickAction Light vi | Variant khác được render tự động; phần chưa mở được ghi là **chưa kiểm bằng mắt**, không suy là đã visual-verify đầy đủ |
| Text lớn | `incoming_text200_vi`, `assignment_text200_en`, `long_name_nightCare_en` | Các probe còn lại có coverage tự động; chưa kiểm tất cả vùng sau cuộn |
| Risk states | `quick_unlocked_light_vi`, `quick_pending_light_vi` | Minh họa trong Flutter; không phải screenshot notification native |

Bộ ảnh app đã chạy pass được phân loại **Current tại thời điểm kiểm**. Bộ proposal là **Current đối với nguồn prototype của lượt này**, không phải UI đã ship. Tất cả source, component, theme, fonts và viewport được chỉ định bởi renderer cùng repo hiện tại. Nếu input liên quan đổi, evidence tương ứng phải tạo lại. Không dùng ảnh Figma hoặc screenshot cũ làm hiện trạng.

Các ảnh: [màn chính](assets/overview_light_vi.png), [flow board](assets/flow-board.png), [giải pháp rủi ro](assets/risk-solutions-board.png). PDF và board được ghép từ PNG Flutter, không vẽ lại giao diện bằng công cụ tạo ảnh.

## Gate-first review

| Gate | Kết quả trong phạm vi prototype | Chưa được chứng minh |
|---|---|---|
| G1 — Ý nghĩa trạng thái | Pass cho các kịch bản mock: gửi khác nhận; chờ đồng bộ khác gia đình đã thấy; phân việc khác nhận việc | Projection thật khi dữ liệu đổi giữa hai thiết bị |
| G2 — Hành động quan trọng | Pass cho phân việc/nhận/xong/nhận ca trong mock; CTA không overflow ở text probes | Safety, mời/thu hồi, kết thúc/cùng chăm của app đầy đủ không được mock này thay thế; phải giữ integration hiện có |
| G3 — Mất dữ liệu | **Not evaluated** cho sản phẩm | Prototype không lưu dữ liệu. Persistence, retry, cache, logout/revoke cần test thật |
| G4 — Quyền | C: control phân công/invite bị ẩn với viewer phù hợp trong prototype | Không thay thế security Rules/callable tests hoặc thực thi quyền native action |
| G5 — AI/sức khỏe | Pass trong nội dung mới: không chẩn đoán, không sinh liều/lịch y tế; lượng bú không dùng mặc định | Không audit lại toàn bộ health/AI feature |
| G6 — Việc chính | Pass cho tương tác mock được test | Chưa đo task success với người dùng, chưa kiểm app thật iOS/Android |

**Verdict:** đủ làm cơ sở thiết kế và lập ticket tích hợp; **chưa đủ để gọi tính năng production-ready**. Không có claim đã gửi thông báo, đã ghi Firebase, đã hoàn thành native widget hoặc đã kiểm nhiều thiết bị.

## Rubric cho màn chính proposal

Điểm là nhận định thiết kế dựa render/code trong coverage đã nêu, không phải kết quả nghiên cứu người dùng. Không dùng điểm để chứng minh retention hoặc đo công bằng.

| Chiều | Đánh giá /5 | Evidence và giới hạn |
|---|---:|---|
| Nội dung cần thiết (đánh giá trước) | 4 | R: người/việc/giờ/CTA có mục đích; lịch và chi tiết được đẩy sang màn riêng |
| Task clarity | 4 | R: biết người đang chăm, việc tiếp theo và bàn giao |
| Information hierarchy | 4 | R: người chăm → việc → ghi nhận gần nhất; không có nhiều hero |
| Scanability | 4 | R: hàng công việc gộp giờ/người/trạng thái; không đoạn giải thích dài |
| Interaction clarity | 4 | R+C: một primary; nhận/trả/xong và undo riêng |
| Navigation/flow | 3 | C: demo đi được flow; entry app thật và các destination ngoài phạm vi chưa tích hợp |
| Visual coherence | 4 | R+C: reuse component và token hiện có; hai palette |
| Content/localisation | 3 | R+C: catalogue vi/en riêng; số liệu cố định. Dữ liệu động/plurals production chưa làm |
| States/trust | 3 | C+R: cache/empty/loading/error/role có probe; backend và native chưa kiểm |
| Accessibility/adaptability | 3 | R+C: text 200%, tên dài, tap targets từ component; chưa VoiceOver/TalkBack hay kiểm contrast số học toàn bộ |
| Product identity | 4 | R: ngôn từ bình tĩnh, palette Child Life, không xếp hạng hay tạo áp lực |

Không tính điểm trung bình. Khả năng dùng bằng một tay trên thiết bị thật, chuyển động, haptics, background execution, performance và nghiên cứu gia đình Việt Nam: **Not evaluated**.

## Self-critique và iteration

1. Việc chính rõ: điều phối người/việc/ca. Không biến Gia đình thành một dashboard đầy số.
2. Ưu tiên người đang chăm và việc tiếp theo; ghi nhận gần nhất là bối cảnh.
3. Đã bỏ heading/CTA “Cùng chăm bé” lặp ở Gia đình, bỏ số đếm và lời giải thích dư.
4. Dùng card nhóm danh sách, không tạo card cho mỗi việc; Night care vẫn phân biệt bề mặt.
5. Đã sửa “Việc của tôi”: nhận/xong là primary ở đáy; “Xem bàn giao” thành một dòng contextual.
6. Màn chính đã xem đủ vi/en; copy mới dùng ARB riêng. Màn phụ có sampling, không tuyên bố coverage mắt đầy đủ.
7. Màn chính đã xem đủ hai palette. Màn phụ rủi ro được chọn Night en để kiểm độ dài/độ tương phản.
8. Chữ lớn và tên dài xuống dòng; viewport nhỏ cần cuộn nhiều. Không thu nhỏ chữ để nhét màn.
9. Giữ “nhận việc” trước “xong” theo model hiện có; action nhanh chỉ áp dụng fixture việc đã nhận. Nhận ca cần mở đủ ngữ cảnh.
10. So với UI trước: rõ hơn ở người thực hiện và trách nhiệm; không khẳng định tốt hơn ở safety/AI/administration vì prototype chỉ bao phủ lớp phối hợp. Ảnh trước khác fixture với proposal, nên so sánh cấu trúc, không so sánh số liệu hoặc pixel như cùng một ngày.

Các chỉnh sửa sau review: căn người chăm sang trái; bỏ caption Gia đình dư; giữ một primary ở Việc của tôi; khôi phục nhận/trả việc từ vòng đời hiện có; tách scenario cảm ơn (người xem là Cùng nuôi) để không dẫn người chăm vào tự cảm ơn mình; bổ sung lỗi lượng nhập và trạng thái chờ đồng bộ; không hứa push tức thời sau phân công.

## Giới hạn cần giữ khi handoff

- CC07 chỉ là phần đề xuất nối flow; invitation sheet trong demo là placeholder. Giữ nguyên toàn bộ quản lý thành viên và pending invites thật.
- CC03/04 không thay thế safety/AI/history/source links hiện có. Không gọi các phần chưa vẽ là đã hoàn thiện.
- CC06 là template cố định, không có engine tự sinh/lặp, chỉnh mọi giờ hoặc chống trùng trên server.
- CC08 là mô hình presentation và preference mock, không map/ghi settings thật; cần đối chiếu key/category có sẵn trước triển khai.
- CC09 là scenario người thân trong nhóm Cùng nuôi xem việc Cô Lan đã xong; chưa có social feed hay delivery.
- CC10 dùng một switch để minh họa OS lock, không có quyền mở khóa thiết bị hay thực thi native action.
- Thao tác nhập/bú/tã chỉ đổi trạng thái demo; không tạo care record thật. Thuốc không nằm trong quick complete.
- Không commit, deploy, publish hoặc cập nhật product decision trong lượt làm việc này. Các thay đổi có sẵn của phiên khác được giữ nguyên.
