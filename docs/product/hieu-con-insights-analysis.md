# Hiểu con · Điều đáng chú ý — phân tích để xây dựng

30/10/2026 · Nguồn: Figma trang `1104:1883` "AI Insights · Hiểu con" (bản phân tích `1104:1884` và 9 màn AI01–AI07, AI01N, AI03N; chỉ đọc), code hiện tại trong `apps/mobile`, `firebase/functions`, `packages/contracts`, `business-map.md` và audit `docs/audits/2026-10-29-lumi-ca-nhan-hoa-nhip.md`.

Trạng thái: **phân tích, chưa có code.** Đã chốt: **Hiểu con là Premium** (D-150, 31/10/2026). Các mục còn lại ở §9 đã chốt theo đề xuất (D-151, 31/10/2026). P1 (server), P2 (app) và P3 (Lumi, phản hồi, Tổng kết tuần) đã xong, chưa commit, chưa deploy; xem §10.

---

## 0. Tóm tắt

- **Ý tưởng đúng và đáng làm.** Phần lớn "nguyên liệu" đã có trong app: bản ghi chăm sóc có người ghi và trạng thái sửa/xoá, bộ tính giấc ngủ và cữ bú, tiêu chí chất lượng ngày của Nhịp lớn lên, so sánh 7 ngày với 7 ngày trước (Chuẩn bị đi khám), Tổng kết tuần, công cụ đọc dữ liệu của Lumi và engine Gợi ý thông minh. Việc còn thiếu là **một lớp insight dùng chung**: các phép tính đang nằm rải rác ở 4–5 chỗ.
- **Đã chốt: Premium (D-150).** Figma đề xuất Free; chủ sản phẩm chọn Premium, khớp với audit 29/10 (W3, F6) và với D-140/D-141. Cách làm ở §3 C1.
- **Còn 3 xung đột cần gỡ trước khi code:**
  1. **Ba định nghĩa "đêm".** Thống kê dùng 18:00–06:00 (R-086), Sắp tới và Lumi dùng 19:00–06:00 (P-167), còn `routinePatterns` coi ngày là 06:00–19:00. Insight nói "đêm" thì phải có **một** định nghĩa.
  2. **Tên "Hiểu con" đã bị dùng.** Đó là tên nhóm "Hiểu con & phát triển" trong Khám phá (D-069, D-139). Audit Premium 30/10 cũng đánh dấu câu "Hiểu con hơn mỗi ngày" là MERGE.
  3. **Tuần tuổi hay tuần lịch.** Figma viết "Tuần 6 của Teddy" (tuần tuổi). Tổng kết tuần hiện tại chạy theo tuần lịch Thứ Hai–Chủ Nhật và báo vào 20:30 Chủ Nhật.
- **Kiến trúc đề xuất:** server tính và lưu insight thành tài liệu Firestore có bằng chứng; app hiển thị bản đó, kể cả khi offline. App tự ẩn ngay một insight khi nhật ký nguồn bị sửa, rồi server tính lại. Lumi đọc **cùng** tài liệu đó. Chi tiết và lý do ở §5.
- **Lộ trình:** P0 chốt quyết định → P1 nền tảng (một định nghĩa đêm, một bộ tính, schema insight, S1/S2/F3) → P2 các màn → P3 Lumi, Tổng kết tuần và push → P4 phần còn lại của danh mục và Portal (§8).

---

## 1. Figma đang đề xuất gì

| Màn | Nội dung | Ghi chú |
| --- | --- | --- |
| AI01 / AI01N | Thẻ "Điều đáng chú ý" ở **đầu** Hôm nay, trên "Nhịp hôm nay". Gồm tiêu đề, câu có số, biểu đồ 14 cột (đêm thiếu ghi là cột nét đứt) và dòng "Dựa trên 6/7 đêm có ghi". | Đẩy các ô ghi nhanh xuống dưới. |
| AI02 | Màn **Hiểu con** gồm các tab "Tuần này / Tháng này". Tiếp theo là thẻ insight lớn và thẻ insight nhỏ; mục "Theo từng việc" (Giấc ngủ, Bú, Thay tã, Nhịp trong ngày); mục "Nhìn lại" (ảnh và 42 khoảnh khắc); hàng Tổng kết tuần 6; nút "Hỏi Lumi về tuần này" kèm "Dùng 1 lượt hỗ trợ AI"; và dòng miễn trừ y khoa. | |
| AI03 / AI03N | Chi tiết một insight: số lớn kèm chip "+30 phút", biểu đồ tuần trước so với gần đây. Khối "Dựa trên" gồm 6/7 đêm có ghi (đêm 20/10 không tính), cách định nghĩa đêm, cơ sở so sánh và người ghi. Có nút "Xem thống kê giấc ngủ" (primary), "Hỏi Lumi về điều này" và khối phản hồi Có ích / Chưa có ích / Không hiện loại này nữa. | Bằng chứng truy được, đúng tinh thần. |
| AI04 | Chưa đủ dữ liệu: tiến độ theo từng việc (Giấc ngủ 2/5 đêm, Bú 3/3, Tã 3/3) và "Đã ghi hôm nay". | |
| AI05 | Thống kê giấc ngủ có một dòng insight trong ngữ cảnh. | Bố cục Thống kê trong Flutter đã khác (xem §6). |
| AI06 | Tổng kết tuần 6: ảnh lớn, "Điều đáng chú ý nhất", "Cả tuần" (gồm Kỷ niệm và Cùng chăm), nút "Xem lại kỷ niệm tuần này" và nút Hỏi Lumi. | Màn này đã có trong Flutter (`WeekSummaryScreen`). |
| AI07 | Lumi mở với chip "Đang hỏi về …". Câu trả lời có số liệu kèm nguồn "Từ 13 đêm có ghi". Với câu "Vì sao…?", Lumi từ chối suy nguyên nhân và gợi ý hỏi bác sĩ. Màn có pill "Còn 17/20 lượt". | Pill này mâu thuẫn với D-076 #12 (xem §3). |

Nguyên tắc trong bản phân tích Figma đều tốt và nên giữ:

- Số do thuật toán tính; AI chỉ diễn đạt.
- V1 chỉ có Level 1–2: không dự đoán, không chẩn đoán, không nói nguyên nhân.
- Phân biệt "không có hoạt động" với "không có ghi nhận".
- Mỗi insight có bằng chứng và bị thu hồi khi dữ liệu nguồn đổi.
- Hôm nay hiện tối đa 1 thẻ mỗi ngày.
- Không emoji; không so ai ghi ít hơn ai.
- Năm loại câu không được lẫn: sự kiện, tóm tắt, xu hướng, dự đoán, AI diễn giải.

---

## 2. Những gì đã có sẵn và sẽ được tái dùng

| Thành phần | Ở đâu | Tái dùng thế nào | Lỗ hổng |
| --- | --- | --- | --- |
| Bản ghi chăm sóc | `babies/{b}/records`. Dart: `care_models.dart:84` `CareRecord`. Contracts: `care.ts:43-72` | Nguồn duy nhất. Có `author` cố định lúc ghi (D-024), `updatedAt`, `deleted` (xoá mềm 30 ngày) | Không lưu ngày/đêm (tính lúc đọc). Sleep chỉ có `occurredAt`/`endedAt` |
| Tổng ngày trên server | `functions/src/care.ts:242` → `babies/{b}/days/{date}` (`summarizeDay`) | Dùng cho D1 và F2 | Thiếu giấc liền dài nhất, giờ vào giấc và số cữ đêm |
| Thống kê | `care_calc.dart` (`feedStats` :412, `sleepStats` ~:680, `isNightHour` :289 = 18–06). Màn: `stats_screens.dart` | AI05 chỉ thêm một dòng insight vào màn sẵn có | **Lỗi có sẵn:** `stats_screens.dart:1308` coi mọi thay đổi là "grew", nhưng câu `nightLongestInsight` lại ghi "tăng từ X lên Y" (`app_vi.arb:3655`). Khi giảm, câu vẫn nói "tăng" |
| Chất lượng ngày (Nhịp lớn lên) | `rhythm_calc.dart:343` `dayQuality`: ngày đã hết, không có timer mở, không chồng lấn, có giấc ngủ, không có khoảng trống trên 6 giờ | Chính là bộ lọc "có ghi" mà Figma cần | Rule mặc định cứng trên máy. App **không đọc** `config/rhythm`, nên sửa trên Portal không tới được điện thoại |
| NL07 "Nhịp riêng của con" | `rhythm_calc.dart:433` `sleepBaseline`, `rhythm_own.dart:388` `SleepFactsBlock`. Bản server: `functions/src/rhythm.ts:204` `sleepFacts` | Figma muốn NL07 dùng chung insight S1–S4 | Hiện chỉ so tổng giờ ngủ, với ngưỡng 60 phút hoặc 15 % |
| So sánh 7 ngày với 7 ngày trước | `visit_report.dart:61` `visitWeeks` (U1, khoá sau `rhythm.advanced`) | Cửa sổ "7 ngày trọn vẹn" là logic đúng | Thêm một bản tính trùng nữa |
| Khoảng cách cữ bú | `contracts/personalization-v2.ts:203` `routinePatterns`: P25–P75 trong 14 ngày, ≥ 5 mẫu trong 3 ngày | Gần như chính là F1 | |
| Sắp tới (W1 cũ) | `rhythm/coming_up.dart` (đêm 19–06) | Mẫu tính trên máy cho thẻ Hôm nay có khoá Premium | |
| Tổng kết tuần | `rhythm_week.dart` (`WeekFacts` :88, tuần Thứ Hai–Chủ Nhật), `week_screen.dart:63`. Báo local 20:30 Chủ Nhật (`rhythm_local.dart`) | AI06 là thêm một khối "Điều đáng chú ý nhất" | Tuần lịch, không phải tuần tuổi |
| Lumi | `openAssistant` (`assistant_screens.dart:81`), `AssistantModuleEntry.ask`. Công cụ đọc `sleep_facts`, `care_summary`… (`contracts/assistant-reads.ts:5`). Lượt dùng: `assistant-usage.ts:81` | Câu hỏi về insight đi qua công cụ đọc sẵn có | `startTaskRequestSchema` (`contracts/assistant.ts:1257`) **không có trường ngữ cảnh** như mã insight; app chỉ gửi `prefill` dạng chữ |
| Gợi ý thông minh | `contracts/engagement.ts` (dailyCap 1, weeklyCap 3, giờ yên tĩnh 22–07, fatigue), ENG-01…06 | Push "Tổng kết tuần sẵn sàng" | Không có phản hồi Có ích. Tên `LUMI_INSIGHT` / `eng.lumi_insight` **đang dùng cho ENG-06** |
| Phản hồi | `recFeedback` (D-102: Có ích / Chưa rõ / Không hợp) | Mẫu cho khối phản hồi của AI03 | |
| Xếp hạng Hôm nay | `adaptive_engine.dart` (`WidgetId` :78, `bandDefaults` :117, `rankToday` :405) và bản mirror `contracts/adaptive.ts` | Thẻ mới cần một `WidgetId` ở cả hai phía | |
| Khám phá | `explore_screen.dart:136`, `careHubSections` | Thêm một hàng | **Không có** nhóm "Theo dõi bé" như Figma viết. Nhóm gần nhất là "Chăm hằng ngày" |
| Quyền | `rhythm_access.dart:33` `familyCan`. `history.read` gồm cả **người thân có `viewDailyCare`** | | Figma muốn V1 ẩn với người thân, nên cần một điều kiện riêng |

**Kết luận:** không thiếu dữ liệu, mà thiếu **một nguồn sự thật cho phép tính**. Hiện có ít nhất 5 bộ tính giấc ngủ và cữ bú độc lập: Thống kê, Nhịp lớn lên (cả app lẫn server), Tổng kết tuần, Chuẩn bị đi khám và Sắp tới, mỗi bộ có ngưỡng và định nghĩa đêm riêng. Nếu thêm insight thành bộ thứ 6, cùng một con số sẽ hiện khác nhau giữa Hôm nay, Thống kê và Lumi. Đó là cách nhanh nhất để mất lòng tin vào một tính năng mà giá trị nằm ở sự đáng tin.

---

## 3. Xung đột và lỗ hổng (xếp theo mức nặng)

**C1. Free hay Premium: đã chốt Premium (D-150).**
- Figma đề xuất Free. Chủ sản phẩm chọn Premium, khớp audit 29/10 (W3, F6) và nhất quán với Sắp tới (D-140) và Chuẩn bị đi khám (D-141).
- **Khoá:** dùng capability sẵn có `rhythm.advanced`. Không tạo entitlement mới, vì entitlement mới cũng là L3.
- **Free vẫn giữ mọi thứ đang Free:** số liệu và câu sẵn có của Thống kê, Tổng kết tuần, phần cơ bản của NL07. Premium không được lấy đi tính năng Free đang có.
- **Lời mời (D-147, D-125):**
  - Khám phá: hàng "Hiểu con" mang nhãn "Có trong Premium", mở paywall.
  - Thống kê: dòng insight thay bằng lời mời *chỉ khi* thật sự có insight. Không hiện số, giống cách thẻ Sắp tới mời ("không hiện giờ").
  - Hôm nay: xem Q-HC-1 bên dưới.
  - Chỉ mời khi lý do khoá là `PREMIUM_REQUIRED`. Nếu chưa biết gói hoặc bị khoá vì lý do khác thì không hiện gì.
- **Kỹ thuật:**
  - Server chỉ tính insight cho hộ có `rhythm.advanced`, để tiết kiệm và không lưu dữ liệu không dùng.
  - Nếu chọn thẻ mời "có điều đáng chú ý" cho Free, server vẫn phải tính, nhưng chỉ lưu `kind`; số liệu không rời server.
  - Firestore rules kiểm tra entitlement khi đọc tài liệu insight đầy đủ.
- **Hỏi Lumi** vẫn tính lượt như hiện nay; câu "tính thế nào" đi đường quy tắc (C5).
- **Q-HC-1 (cần chốt):** hộ Free có thấy thẻ mời trên Hôm nay khi có một điều đáng chú ý (chỉ tên loại, ví dụ "Có một thay đổi về giấc ngủ đêm của Teddy tuần này", không có số) không?
  - Đề xuất: **có, tối đa 1 lần mỗi tuần.** Đây là lời mời dễ hiểu giá trị nhất, mà không giấu thông tin an toàn. Insight không phải cảnh báo sức khoẻ, và dấu hiệu nguy hiểm vẫn luôn miễn phí (audit 29/10).
  - Không làm thì Free chỉ thấy lời mời ở Khám phá.

**C2. Ba định nghĩa "đêm" (L3 nhỏ: thuật ngữ và quy tắc).**
- Thống kê 18–06 (R-086), Sắp tới và Lumi 19–06 (P-167 #10), `routinePatterns` coi ngày là 06–19.
- AI03 ghi rõ "Đêm từ 18:00 đến 06:00", AI05 ghi "Đêm 18:00–06:00".
- Đề xuất: một hằng số `careNightWindow` trong contracts, mặc định **18:00–06:00**, theo R-086 vì đó là nơi phụ huynh *nhìn thấy* chữ "đêm". Sắp tới và Lumi chuyển sang hằng số này.
- Về sau có thể cho mỗi gia đình chọn (bé ngủ lúc 20:00 thì 18:00 là sớm). Đó là tuỳ chỉnh mới, cần quyết riêng.

**C3. Tên tính năng (L3: thuật ngữ chuẩn).**
- "Hiểu con" đang là tên nhóm "Hiểu con & phát triển" trong Khám phá, chứa Wonder Weeks, Giai đoạn và Mốc.
- Nếu đặt một hàng "Hiểu con" vào nhóm "Hiểu con & phát triển", người dùng sẽ thấy cùng một chữ ở hai cấp với hai nghĩa.
- Các phương án:
  - (a) Giữ "Hiểu con" cho tính năng và đổi tên nhóm (ví dụ "Phát triển & giai đoạn").
  - (b) Đặt tên tính năng là **"Nhịp của {tên}"** hoặc "Điều đáng chú ý".
  - (c) Đặt tên **"Tuần này của {tên}"**. Tên này đã dùng cho thẻ Nhịp lớn lên (D-141 #1), nên không chọn.
- Đề xuất **(a)**, vì "Hiểu con" là lời hứa thương hiệu mạnh (audit F6). Nhãn thẻ giữ "Điều đáng chú ý".

**C4. Tuần tuổi hay tuần lịch.**
- Figma W1 viết "mỗi tuần tuổi". `SummaryWeek` hiện là Thứ Hai–Chủ Nhật và báo 20:30 Chủ Nhật (R-120: không tên, không số).
- Tuần tuổi hợp cảm xúc ("Tuần thứ 6 của Teddy"), nhưng mỗi bé một ngày khác nhau. Gia đình hai con sẽ có hai ngày tổng kết, và việc so với tuần trước bị lệch so với Thống kê (vốn chạy theo 7 ngày gần nhất).
- Đề xuất: **giữ tuần lịch** cho số liệu, dùng tuần tuổi chỉ ở **tiêu đề** ("Tuần 19–25/10 · bé được 6 tuần"). Cần chủ sản phẩm xác nhận.

**C5. Lumi chưa nhận ngữ cảnh có cấu trúc.**
- `startTaskRequestSchema` chỉ có chữ, `scope`, `intentHint` và ảnh. Chip "Đang hỏi về" của AI07 cần thêm trường `context: {kind: 'insight', id}`.
- Server đọc lại tài liệu insight theo `id` và quyền của người hỏi, **không tin số app gửi lên**.
- Về lượt:
  - D-088 quy định "đọc thẻ 0 lượt". Câu "Điều này được tính thế nào?" trả lời được hoàn toàn từ bằng chứng, nên đề xuất đi đường quy tắc nhanh với **0 lượt** (D-145).
  - Câu hỏi mở ("vì sao", "so tháng trước") đi model và tốn 1 lượt.
  - Dòng "Hỏi Lumi dùng 1 lượt" khi đó chỉ đúng cho câu hỏi mở.
- Pill "Còn 17/20 lượt" trong AI07 **trái D-076 #12** (chat ẩn pill lượt còn lại). Con số 20 cũng cũ: `premium_v2` cho Free 30 lượt một lần.

**C6. Sức khoẻ và độ tuổi (L3: tuyên bố sức khoẻ).**
- Với trẻ sơ sinh dưới 4–6 tuần, "đêm bú ít cữ hơn" (F3) hay "ngủ liền dài hơn" (S1) **không phải lúc nào cũng là tin tốt**: bé sơ sinh thường cần được cho bú mỗi 2–3 giờ.
- Câu Figma trung tính ("dài hơn", "ít cữ hơn"), nhưng đặt ở đầu Hôm nay, kèm màu tím và biểu đồ đi lên, người đọc sẽ hiểu là khen.
- Đề xuất:
  - Tắt F3 chiều *giảm* và S1 chiều *dài hơn* ở bé dưới 6 tuần (theo tuổi hiệu chỉnh D-141 #1), hoặc chỉ hiện trong màn chi tiết, không lên Hôm nay.
  - Nhờ người duyệt nội dung đã có (D-141) xem bộ mẫu câu và ngưỡng tuổi.
  - Không bao giờ dùng màu xanh/đỏ hay chữ "tốt hơn / kém hơn".
- D-143 mở Adaptive cho trẻ 0–12 tuổi, trong khi danh mục chỉ dành cho Chương 1 (0–1 tuổi). Với trẻ lớn ít ghi bú/ngủ, tính năng phải **tự ẩn**, không hiện "chưa đủ dữ liệu" mãi.

**C7. Thẻ đầu Hôm nay so với các quyết định Hôm nay đã có.**
- Đã có: Living Header (D-128), Compact Home (D-131), "Dành cho bé hôm nay" với một hero (D-102), Sắp tới (D-140), xếp hạng Adaptive (D-108 giữ ranking không đổi).
- Đặt insight lên đầu (AI01) thì ô ghi nhanh tụt xuống. Lúc 3 giờ sáng, việc chính là **ghi**, không phải đọc insight.
- Đề xuất:
  - Thẻ là một `WidgetId` mới trong Adaptive, mặc định **ngay sau ô ghi nhanh**.
  - Trong Night care hoặc giờ đêm, thẻ thu gọn thành một dòng (hoặc ẩn).
  - Thẻ không chiếm chỗ hero của "Dành cho bé hôm nay".
- Thay đổi ranking là L3 theo CLAUDE.md, nên cần chốt.

**C8. Quyền xem.**
- Người thân có `viewDailyCare` đang đọc được lịch sử chăm sóc. Figma muốn V1 ẩn insight với người thân, nên phải thêm điều kiện "không phải relative" ở app **và** trong Firestore rules.
- Người chăm sóc không thấy M1 hay Kỷ niệm.
- Ảnh hero và số khoảnh khắc trong AI02/AI06 phải theo quyền xem của **người đọc** (đúng tinh thần D-149 #1).

**C9. Ngưỡng trên Portal phải thật sự tới nơi tính.** Nhịp lớn lên đã có bài học: Portal sửa `config/rhythm` nhưng điện thoại không đọc. Nếu insight tính trên server (§5) thì ngưỡng đọc thẳng từ `config/insights`, không gặp lại lỗi này.

**C10. Phản hồi và chống spam.**
- Engine Gợi ý thông minh không có Có ích. Nên tái dùng mẫu `recFeedback`, tách theo người × loại insight.
- dailyCap 1 **dùng chung** với ENG-06 (Gợi ý mỗi ngày, D-099). Push "Tổng kết tuần sẵn sàng" sẽ tranh suất với gợi ý hằng ngày, nên cần chốt thứ tự ưu tiên.
- Báo local 20:30 Chủ Nhật đang tồn tại song song. Chỉ giữ **một** kênh: đề xuất giữ báo local (chạy offline, không tốn suất cap) và cho nó trỏ vào màn có insight.

**C11. Lỗi có sẵn nên sửa ngay, độc lập với tính năng này (L1).** `stats_screens.dart:1308`: khi giấc đêm dài nhất **giảm**, màn vẫn hiện "tăng từ X lên Y". Đây cũng là ví dụ về kiểu lỗi mà insight phải tránh: câu xu hướng phải lấy chiều từ dữ liệu.

---

## 4. Logic đề xuất cho engine insight

### 4.1 Đường ống

```
records (sửa/xoá mềm) ─► chuẩn hoá theo múi giờ của bé
   ─► gán đêm/ngày (careNightWindow) ─► kiểm tra độ phủ từng đêm/ngày
   ─► chỉ số mỗi đêm/ngày ─► cửa sổ "gần đây" và "cơ sở"
   ─► bộ phát hiện theo danh mục (ngưỡng theo tuổi, từ config)
   ─► lọc: dữ liệu tối thiểu · cùng chiều · cooldown · chống lặp · tuổi · đã tắt loại
   ─► xếp hạng ─► tài liệu Insight (số + bằng chứng + phiên bản quy tắc)
   ─► bề mặt: Hôm nay · Hiểu con · Thống kê · NL07 · Tổng kết tuần · Lumi
```

### 4.2 Định nghĩa cần chốt (phần dễ sai nhất)

- **Đêm D** là khoảng `[D 18:00, D+1 06:00)` theo múi giờ của bé. Thị trường toàn cầu (D-142) có giờ mùa hè, nên phải tính bằng múi giờ IANA, **không** cộng 12 giờ.
- **Đêm có ghi (hợp lệ):** đêm đã kết thúc, không có timer ngủ đang mở, không có bản ghi chồng lấn, và các bản ghi ngủ trong đêm không để trống quá 4 giờ liên tục (tiếp cách làm của `dayQuality`, ngưỡng nằm trong config). Một giấc 30 phút lúc 18:30 rồi không có gì nữa thì **không** tính là "có ghi". Đây chính là "không có ghi nhận ≠ không ngủ".
- **Khoảng ngủ liền (S1)** là **một** bản ghi sleep, không gộp hai giấc cách nhau vài phút. Gộp giấc sẽ "bịa" ra một giấc dài mà phụ huynh không ghi. Một giấc vắt qua 06:00 thuộc đêm mà nó bắt đầu.
- **Giờ vào giấc đêm (S3):** giờ bắt đầu của giấc đầu tiên ≥ 90 phút, bắt đầu trong khoảng `[18:00, 02:00)`. Độ đều đo bằng **IQR** (khoảng tứ phân vị) của số phút kể từ 18:00. IQR chịu được một đêm bất thường tốt hơn độ lệch chuẩn.
- **Giấc ngày (S4):** sleep ≥ 10 phút, bắt đầu trong khoảng 06:00–18:00.
- **Cửa sổ:** "gần đây" là 7 đêm/ngày **đã kết thúc** gần nhất, không tính đêm nay; "cơ sở" là 7 đêm/ngày liền trước. Giá trị hiển thị là trung bình của các đêm hợp lệ, đúng câu Figma "TB 6 đêm gần đây".
- **Điều kiện xu hướng (theo Figma, giữ nguyên làm giá trị khởi đầu):** |Δ trung bình| ≥ ngưỡng, **và** ít nhất 3 đêm gần đây cùng phía so với trung bình cơ sở, **và** ≥ 5/7 đêm hợp lệ ở *cả hai* cửa sổ. Thiếu điều kiện cuối thì hiện trạng thái "chưa đủ" với tiến độ (AI04), không so sánh.
- **Bú bình (F2)** chỉ tính ml trên những ngày có bú bình. Nếu số cữ bú mẹ thay đổi ≥ 1 cữ/ngày giữa hai tuần thì **không** phát insight F2, vì lượng sữa bình tăng có thể chỉ do bú mẹ giảm, và câu khi đó gây hiểu sai. Không bao giờ cộng phút với ml (Figma và R-086).
- **Làm tròn:** câu xu hướng dùng "khoảng" và làm tròn 5 phút / 10 ml. Con số chính xác ở dòng tóm tắt. Không làm tròn chip "+30 phút" thành con số khác với câu.

### 4.3 Vòng đời

- **Sinh:** mỗi sáng sau khi đêm kết thúc (06:30 giờ của bé), và khi nhật ký trong cửa sổ bị sửa.
- **Thu hồi ngay:** insight lưu `windowStart`, `windowEnd` và `computedAt`. Nếu app thấy bất kỳ bản ghi nào trong cửa sổ có `updatedAt > computedAt` (sửa, xoá, hoặc thêm bù), thẻ **ẩn ngay, kể cả offline** và không hiện số cũ. Server tính lại khi nhận được thay đổi.
- **Hết hạn:** trên Hôm nay sau 3 ngày hoặc khi có insight mới cùng loại; trong Hiểu con sau 7 ngày.
- **Cooldown 7 ngày** mỗi loại. Một insight chiều ngược lại ("ngắn hơn") trong lúc cooldown chỉ hiện trong màn Hiểu con, không lên Hôm nay. Như vậy không có chuyện tuần này "dài hơn", tuần sau "ngắn hơn" cùng nhảy lên đầu Hôm nay.
- **Xếp hạng:** điểm = (|Δ| / ngưỡng, chặn trên ở 3) × độ phủ × ưu tiên loại (ngủ > bú > khác) × hệ số phản hồi của người xem. Hôm nay lấy 1 thẻ; Hiểu con lấy tối đa 3.
- **Phản hồi:**
  - "Chưa có ích" giảm trọng số của loại đó cho người đó.
  - "Không hiện loại này nữa" tắt loại đó (bật lại được trong cài đặt).
  - Phản hồi là của người, không phải của cả nhà.

### 4.4 Danh mục: rà từng mục

| Mã | Nhận xét | Đề xuất V1 |
| --- | --- | --- |
| S1 | Giá trị nhất, phụ huynh quan tâm nhất | **P1**. Có khoá tuổi dưới 6 tuần (C6) |
| S2 | Trùng ý với NL07 (so tổng giờ ngủ) | **P1**. NL07 chuyển sang đọc S2 |
| S3 | Hay nhưng phụ thuộc định nghĩa giờ vào giấc | P4 |
| S4 | Giấc ngày dễ bị ghi thiếu | P4. Yêu cầu ngày hợp lệ theo `dayQuality` |
| F1 | Là Level 1 (ổn định), không phải thay đổi, nên ít "đáng chú ý". Đã có `routinePatterns` | P4. Chỉ đưa vào Tổng kết tuần, không lên Hôm nay |
| F2 | Rủi ro hiểu sai khi bú hỗn hợp | P4. Có điều kiện bú mẹ ổn định (§4.2) |
| F3 | Có giá trị cảm xúc cao ("đêm bớt dậy") nhưng nhạy cảm ở trẻ sơ sinh | **P1**. Có khoá tuổi |
| D1 | Chỉ mô tả, không ngưỡng: đúng | Chỉ nằm ở "Theo từng việc", không là "Điều đáng chú ý" |
| R1 | Dùng lại `usualMorningMinutes` của Sắp tới | P4 |
| M1 | Đếm theo quyền xem của người đọc | P3, cùng Tổng kết tuần |
| W1 | Là thông báo, không phải insight | P3 (C4, C10) |

---

## 5. Công nghệ: tính ở đâu

### Các phương án

| | A. Chỉ trên máy (như Sắp tới, Tổng kết tuần) | B. Server tính, lưu tài liệu (đề xuất) |
| --- | --- | --- |
| Offline | Luôn tươi | Hiện bản đã tính kèm "Cập nhật lúc …" (Figma đã thiết kế đúng trạng thái này) |
| Nhất quán giữa các máy, giữa Ba và Mẹ | Mỗi máy có thể tính khác (dữ liệu chưa đồng bộ) | Một bản duy nhất |
| Lumi giải thích | Phải tính lại trên server, nên dễ lệch số | Đọc **cùng** tài liệu |
| Push, Portal, phân tích, ngưỡng theo config | Khó, ngưỡng nằm cứng trong app (bài học C9) | Tự nhiên |
| Cooldown và phản hồi giữa các máy | Phải đồng bộ thêm | Có sẵn |
| Chi phí | 0 | Nhỏ: một lần tính mỗi bé mỗi ngày, cộng các lần tính lại khi sửa nhật ký; khoảng ≤ 500 bản ghi/14 ngày; không gọi LLM |

**Chọn B**, cộng thêm hai việc trên máy:
1. Việc ẩn ngay khi nhật ký trong cửa sổ đổi (§4.3), để không bao giờ hiện số cũ.
2. Các số mô tả "Theo từng việc" và "Đã ghi hôm nay" tiếp tục tính trên máy bằng `care_calc` có sẵn, vì chúng cần tươi từng phút.

### Thành phần

1. **`packages/contracts/src/insights.ts`**
   - `careNightWindow`, `insightKinds`, schema `insightSchema`:

     ```
     { id, babyId, kind, ruleVersion, window{start,end}, baseline{start,end},
       value, baselineValue, delta, unit, direction,
       coverage{valid,total}, excluded[{date, reason}],
       points[{date, value|null}], authors[{name, relation}],
       computedAt, expiresAt, surfaces[], ageBand }
     ```

   - `insightRulesSchema` gồm ngưỡng theo nhóm tuổi.
   - Các hàm tính viết **thuần** (không I/O) để test bằng bảng dữ liệu.
2. **Cloud Functions** (`firebase/functions/src/insights.ts`)
   - `insightScheduler` chạy hằng giờ, chọn những bé đang ở khoảng 06:xx giờ địa phương và có hoạt động trong 3 ngày gần nhất. Mẫu có sẵn: `dailySuggestionScheduler`.
   - Trigger `onWrite` của `records`: nếu `occurredAt` nằm trong 14 ngày gần nhất thì đánh dấu bé cần tính lại, gom lại và tính sau tối thiểu 10 phút để tránh tính lại sau mỗi lần ghi.
   - Ghi vào `babies/{b}/insights/{kind}_{windowEnd}`.
   - Đọc ngưỡng từ `config/insights` và flag `insights` (công tắc tắt khẩn).
3. **Firestore rules:** đọc khi có `history.read` **và không phải relative** (V1, C8); chỉ server ghi. Phản hồi ghi vào `babies/{b}/insightFeedback/{uid}_{kind}` (chỉ chủ phản hồi). Thêm test vào `pnpm test:rules`.
4. **Flutter**
   - `features/insights/`: repository đọc insight theo stream (Firestore cache cho offline) và hàm `isStale(insight, recentRecords)`.
   - Các màn: Hiểu con, chi tiết, trạng thái chưa đủ dữ liệu.
   - Thẻ Hôm nay qua `WidgetId.insight` (cả `adaptive_engine.dart` lẫn `contracts/adaptive.ts`).
   - Dòng insight trong `SleepStatsScreen`/`FeedStatsScreen`; khối mới trong `WeekSummaryScreen`.
   - **Component:** D-107 đã gọi tên "insight / statistics" là một mục đích của `ClCard`. Đây là nhu cầu thật đầu tiên dùng ở 4+ chỗ, nên làm biến thể insight trong `lib/core/widgets`, không làm `HcCard` riêng.
   - Biểu đồ so sánh 2 tuần (cột nhạt so với cột đậm, đêm thiếu ghi là ô nét đứt): tái dùng chart của `SleepFactsBlock` hoặc Thống kê nếu được, và thêm `Semantics` đọc thành câu ("6 trên 7 đêm có ghi, trung bình 2 giờ 52 phút").
5. **Lumi**
   - Thêm `context` vào `startTaskRequestSchema` (C5). Server nạp insight và bằng chứng làm dữ kiện có nguồn.
   - Mẫu trả lời quy tắc cho "tính thế nào" (0 lượt).
   - Prompt cấm nêu nguyên nhân hoặc chẩn đoán và phải trích "từ N đêm có ghi · ngày".
   - Viết case eval mới. Theo memory dự án, chỉ chạy model thật cho case mới hoặc đổi, khoảng 25 lượt gọi.
6. **Push:** giữ báo local Chủ Nhật nhưng trỏ vào màn có insight (C10), hoặc làm ENG-07 nếu chủ sản phẩm muốn server. **Không** dùng lại tên `LUMI_INSIGHT`, vì nó đang thuộc ENG-06.
7. **Portal:** tab "Insights" để sửa ngưỡng theo tuổi, giả lập trên dữ liệu mẫu và xem số liệu hiện/mở/có ích/tắt. Làm sau khi chốt danh mục (Figma cũng đề xuất vậy).
8. **Phân tích:** sự kiện `insight_shown/opened/feedback/muted/ask_lumi` chỉ mang `kind`, `ageBand`, `surface`; **không** mang số liệu hay tên bé (CLAUDE.md, Security).

### Hợp nhất bộ tính (việc nền quan trọng nhất)

- Chuyển các định nghĩa đêm, độ phủ và "giấc liền dài nhất" vào `contracts/insights.ts`.
- Server Nhịp lớn lên (`rhythm.ts sleepFacts`) và Chuẩn bị đi khám (`visitWeeks`) dần đọc từ đó.
- Phía Dart, các chỗ còn tính trên máy (Thống kê, Tổng kết tuần) phải chạy **cùng một bộ dữ liệu kiểm thử JSON** với bản TS, để hai bên không lệch. Dự án đã có cặp `summarizeDay` ↔ `DayTotals.of` theo kiểu này.

---

## 6. Nhận xét UI/UX trên các màn Figma

Phạm vi áp dụng theo D-137:
- Màn **mới** (thẻ AI01, AI02, AI03, AI04, chip ngữ cảnh của AI07) làm theo Figma.
- Màn **đã có và đã được cải thiện trong Flutter** (Thống kê ở AI05, Tổng kết tuần ở AI06, chat Lumi) giữ bố cục Flutter, chỉ thêm phần insight.
- Mọi chỗ lệch khỏi Figma được liệt kê dưới đây để chủ sản phẩm xem.

| Màn | Tốt | Nên đổi (và lý do) |
| --- | --- | --- |
| AI01 | Câu có số và đơn vị; "Dựa trên 6/7 đêm có ghi" thay cho "độ tin cậy"; không emoji | Vị trí đầu trang (C7). Câu thân thẻ lặp lại tiêu đề ("dài hơn"), nên rút còn "TB 2 giờ 52 phút · tuần trước 2 giờ 21 phút" (D-110) |
| AI02 | Thứ bậc rõ: một insight lớn, một nhỏ, rồi mô tả; dòng miễn trừ y khoa | Tab "Tháng này" chưa có danh mục (chỉ M1), nên V1 bỏ tab hoặc đưa vào Premium (C1). "Chưa đủ dữ liệu" của "Nhịp trong ngày" đang tô màu cảnh báo, nên dùng màu trung tính vì đó không phải lỗi. Thẻ ảnh "Nhìn lại" rất lớn, dễ lấn phần chính. Màn dài khoảng 1 700 pt, có thể gom "Nhìn lại" và Tổng kết tuần thành một hàng |
| AI03 | Khối "Dựa trên" là điểm mạnh nhất: minh bạch, có người ghi, có đêm bị loại và lý do; phản hồi 3 lựa chọn | Hai nút lớn: theo D-105 chỉ "Xem thống kê" là primary, Hỏi Lumi để dạng tonal (đã đúng). Thêm "0 lượt" cho câu "tính thế nào" (C5). Legend chỉ phân biệt bằng độ đậm của màu, nên cần thêm nhãn chữ trên trục (12–18/10, 19–25/10; Figma đã có, giữ lại) |
| AI04 | Trạng thái chưa đủ dữ liệu có tiến độ và nói điều cần làm | Dòng "Bú 3/3 · đang theo dõi" với thanh đầy dễ hiểu thành "xong", trong khi Bú chưa có insight nào. Nên ghi "đủ dữ liệu" kèm thời điểm sẽ có |
| AI05 | Insight nằm ngay chỗ phụ huynh đang xem | Màn Thống kê Flutter hiện tại giữ nguyên. Chỉ thay `_Insight` hiện có bằng dòng insight dùng chung, đồng thời sửa C11 |
| AI06 | "Điều đáng chú ý nhất" là khối duy nhất cần thêm | Ảnh hero và "Kỷ niệm 12 khoảnh khắc" theo quyền của người đọc. "Cùng chăm: Mẹ, Ba và Bà nội ghi 96 lần" chấp nhận được vì không xếp hạng ai |
| AI07 | Chip "Đang hỏi về"; câu "vì sao" từ chối suy nguyên nhân đúng chuẩn | Bỏ pill lượt (D-076 #12). Gợi ý "So với tháng trước thì sao?" cần dữ liệu 8 tuần; nếu không đủ, Lumi phải nói rõ là chưa đủ |

**Accessibility (bắt buộc):**
- Biểu đồ có `Semantics` dạng câu.
- Cột đêm thiếu ghi có nhãn, không chỉ có nét đứt.
- Chip "+30 phút" đọc thành "dài hơn 30 phút".
- Mọi thứ hiển thị đúng ở cỡ chữ 200 %.
- Đủ 4 tổ hợp Light/Night care × vi/en.

---

## 7. Kiểm thử

- **Dữ liệu tổng hợp 14 ngày** (dùng chung cho TS và Dart): đủ đêm; thiếu 1 hay 3 đêm; timer đang mở; giấc chồng lấn; giấc vắt qua 06:00; sửa một bản ghi cũ; xoá rồi hoàn tác; bú hỗn hợp; đổi giờ mùa hè (múi giờ châu Âu/Mỹ); bé dưới 6 tuần; bé 3 tuổi chỉ ghi lẻ tẻ.
- **Quy tắc:** người thân không đọc được; người chăm sóc không thấy M1; không ai ghi được insight.
- **Golden:** AI01–AI04 và các khối mới ở AI05/AI06, đủ 4 tổ hợp Light/Night × vi/en. Chỉ cập nhật đúng các baseline đã đổi.
- **Lumi:** fake suite đầy đủ. Model thật chỉ chạy cho các case insight mới.
- **Engine:** cooldown, chống lặp, thu hồi khi sửa nhật ký, hết hạn, đúng 1 thẻ mỗi ngày.

---

## 8. Lộ trình đề xuất

| Giai đoạn | Nội dung | Ra được gì |
| --- | --- | --- |
| **P0** | Chủ sản phẩm chốt §9 | |
| **P1 · Nền** | Sửa C11. `careNightWindow` dùng chung. `contracts/insights.ts` (schema, độ phủ, S1/S2/F3, ngưỡng). Function tính, lưu, thu hồi, kèm rules. Dữ liệu kiểm thử chung | Insight đúng, có bằng chứng, chưa có UI |
| **P2 · Bề mặt** | Biến thể insight của `ClCard`. AI03 chi tiết, AI02 Hiểu con, AI04 chưa đủ, thẻ Hôm nay (`WidgetId`), dòng trong Thống kê, NL07 đọc S2. Khoá `rhythm.advanced` và các lời mời Premium (D-150, D-147), có test `premium_invites_test.dart` | Tính năng nhìn thấy được, end-to-end trên dev |
| **P3 · Kết nối** | `context` cho Lumi kèm câu trả lời quy tắc 0 lượt. Khối insight trong Tổng kết tuần, M1, push tuần | Hỏi Lumi về điều này; Tổng kết tuần mới |
| **P4 · Mở rộng** | S3, S4, F1, F2, R1. `config/insights` và tab trên Portal. Sự kiện phân tích. Tab "Tháng này" và lịch sử insight | Đủ danh mục V1 |

Ứng dụng chưa go-live (D-144), nên không cần rollout từng đợt. Flag `insights` chỉ để làm công tắc tắt khẩn.

---

## 9. Quyết định của chủ sản phẩm (L3)

Đã chốt toàn bộ: Premium ở D-150, các mục còn lại "theo đề xuất" ở D-151 (31/10/2026).

| # | Quyết định | Đã chốt |
| --- | --- | --- |
| 1 | ~~Free hay Premium (C1)~~ | **Đã chốt: Premium** (D-150), khoá bằng `rhythm.advanced`, kèm lời mời theo D-147 |
| 1b | Thẻ mời trên Hôm nay cho hộ Free (Q-HC-1) | Có: chỉ tên loại insight, không số, tối đa 1 lần mỗi tuần |
| 2 | Định nghĩa "đêm" dùng chung (C2) | 18:00–06:00 cho toàn app, kể cả Sắp tới và Lumi |
| 3 | Tên tính năng và tên nhóm trong Khám phá (C3) | Tính năng "Hiểu con"; nhóm đổi thành "Phát triển & giai đoạn"; nhãn thẻ "Điều đáng chú ý"; thêm vào glossary |
| 4 | Tuần tuổi hay tuần lịch (C4) | Số liệu theo tuần lịch Thứ Hai–Chủ Nhật, tuần tuổi chỉ ở tiêu đề |
| 5 | Vị trí thẻ trên Hôm nay (C7) | `WidgetId` mới ngay sau ô ghi nhanh; thu gọn trong Night care |
| 6 | Khoá tuổi và duyệt mẫu câu (C6) | Tắt S1 "dài hơn" và F3 "ít hơn" trên Hôm nay ở bé dưới 6 tuần (tuổi hiệu chỉnh); người duyệt nội dung xem bộ câu |
| 7 | Người thân (C8) | V1 không xem (theo Figma) |
| 8 | Lượt Lumi (C5) | "Tính thế nào" 0 lượt; câu hỏi mở 1 lượt; không hiện pill lượt |
| 9 | Kênh thông báo tuần (C10) | Giữ báo local Chủ Nhật, trỏ vào màn có insight, không tốn suất dailyCap |

---

## 10. Trạng thái triển khai

**P1 xong (31/10/2026), chưa commit, chưa deploy lên dev.**

| Việc | File | Kiểm thử |
| --- | --- | --- |
| C11: câu xu hướng lấy chiều từ dữ liệu (thêm `nightLongestShorter`) | `apps/mobile/lib/features/care/stats_screens.dart`, ARB vi/en | `test/features/history_test.dart` ("a shorter longest night never reads tăng") |
| Một giờ đêm 18:00–06:00 (D-151 #1) | contracts `careNightWindow` (`care.ts`), `routinePatterns` (`personalization-v2.ts`); app `careNightFromHour/ToHour` (`care_calc.dart`), `coming_up.dart`; `lumi-plan.md` §7.1 | `coming_up_test.dart` (lần hỏi lại dừng lúc 18:00), `personalization-v2` (unit + integration) |
| Bộ tính insight S1/S2/F3: đêm theo múi giờ (an toàn khi đổi giờ mùa hè), đêm hợp lệ (timer mở, chồng lấn, không có giấc, khoảng trống > 4 giờ), so 7 với 7 đêm, ≥ 3 đêm cùng phía, chặn tuổi < 6 tuần, cooldown 7 ngày, 1 thẻ mỗi ngày, Free chỉ có tên loại | `packages/contracts/src/insights.ts` | `packages/contracts/test/insights.test.ts` (17) |
| Server tính và lưu `babies/{b}/insights/current`; hàng đợi `insightQueue/{babyId}` (sửa đêm đã tính thì 10 phút, còn lại 06:30 sáng hôm sau, bé không ghi 3 ngày thì rời hàng đợi); `insightScheduler` 15 phút; trigger nằm trong `onCareRecordWrite` | `firebase/functions/src/insights.ts`, `index.ts` | `firebase/tests/insights.integration.test.ts` (7) |
| Rules: cha mẹ và người chăm sóc đọc; người thân không đọc; không ai ghi từ app; hàng đợi chỉ server dùng | `firebase/firestore.rules` | `firebase/tests/insights.rules.test.ts` (4) |

**Ghi chú kỹ thuật:**
- Chưa có flag `insights` riêng. Phần số liệu đã bị khoá bởi `rhythm.advanced`, và capability này đã có công tắc tắt `personalization`.
- Hộ Free vẫn được tính, để server biết loại insight cho lời mời; số liệu không bao giờ được ghi vào tài liệu của hộ Free.
- Ngưỡng đọc từ `config/insights` (gộp đè lên giá trị mặc định); tab chỉnh trên Portal để ở P4.

**P2 xong (31/10/2026), chưa commit.**

| Việc | File | Kiểm thử |
| --- | --- | --- |
| Đọc `insights/current` và kiểm tra "cũ": ẩn số khi một bản ghi trong cửa sổ được lưu sau lần tính (server lưu thêm `windowEnd`); `CareRecord.updatedAt`; quyền xem: Premium đầy đủ, Free thấy lời mời, người thân không thấy | `lib/features/insights/insight_models.dart`, `insight_repository.dart`, `care/care_models.dart` | `test/features/insights_test.dart` (14) |
| AI01: thẻ Hôm nay (`WidgetId.insight`, ngay sau ô ghi nhanh; ở Night care bỏ biểu đồ), lời mời Free chỉ nêu loại thay đổi | `insight_widgets.dart`; `adaptive_engine.dart`, contracts `adaptive.ts`, rules `validWidgetList`, `today_screen.dart`, `experience_repository.dart` | `adaptive_wire_parity_test`, `adaptive_engine_test`, golden `insights/today_*`, `invite_*` |
| AI02 Hiểu con, AI03 chi tiết, AI04 chưa đủ đêm; route `/care/insights` và `/care/insights/{kind}` | `insight_screens.dart`, `app/router.dart`, `route_guard.dart` | golden `insights/screen_*`, `detail_*`, `sparse_*` (Light/Night × vi/en, kèm bản chữ 200 %) |
| AI05: dòng insight trong Thống kê giấc ngủ và Thống kê bú | `care/stats_screens.dart` | `insights_test.dart` |
| Hàng "Hiểu con" trong Chăm hằng ngày (Free thấy "Có trong Premium"); nhóm "Hiểu con & phát triển" đổi thành "Phát triển & giai đoạn" | `care/care_hub_screen.dart`, ARB | golden `s4/v1i_care_hub_*`, `ax/ax20_explore_0_1_*` (đã cập nhật) |
| 50 chuỗi vi/en | `tool/insight_strings.py` | |

**Khác Figma (D-137), có chủ đích:**
- Không có tab "Tháng này", vì chưa có danh mục insight theo tháng.
- Không có thẻ ảnh "Nhìn lại" (M1).
- Chưa có "Hỏi Lumi" và khối phản hồi Có ích / Chưa có ích (để P3).
- Dòng nhóm/khoảng ngày nằm dưới tiêu đề lớn, không nằm trên: `MePage` đặt tiêu đề lên đầu.
- Dòng "chưa đủ đêm" chỉ có một thanh tiến độ cho số đêm, vì bộ tính chỉ dựa vào đêm.
- "Theo từng việc" hiện "Chưa có ghi trong 7 ngày qua" khi không có ghi nhận, thay vì "TB 0".

**Giới hạn:** app không thấy được bản ghi bị xoá (danh sách đang theo dõi đã bỏ nó). Insight chỉ cập nhật khi server tính lại, khoảng 10 phút sau.

**Golden lỗi thời từ trước, không do thay đổi này:** `hn/home_*` (baseline từ 35ed262c, trước khi D-139 đổi các ô trên Hôm nay) và `care_plan_today/today_tasks_*`. Không cập nhật.

**P3 xong (31/10/2026), chưa commit.**

| Việc | File | Kiểm thử |
| --- | --- | --- |
| Lumi giải thích insight theo đường quy tắc, **0 lượt**, không gọi model: công cụ đọc mới `insight_basis`, nhận diện qua cụm "Điều đáng chú ý" / "Worth noticing"; quyền giống màn Hiểu con (không cho người thân, Premium mới thấy số); thẻ ghi số liệu, các đêm không tính, khung đêm, tuần so sánh, người ghi, và câu "dữ liệu chưa cho biết nguyên nhân" | contracts `assistant-reads.ts`; functions `assistant-insight.ts`, `assistant-reads.ts` | `packages/contracts/test/assistant-reads.test.ts`, `firebase/functions/test/assistant-insight.test.ts` |
| Nút "Hỏi Lumi về điều này" trên màn chi tiết (chỉ khi gia đình bật Lumi): mở chat với câu hỏi điền sẵn, kèm dòng "Câu hỏi này không tốn lượt hỗ trợ AI" | `insight_screens.dart` | `insights_test.dart`, golden `insights/detail_lumi_*` |
| Phản hồi riêng từng người, lưu ở `users/{uid}/insightPrefs/{babyId}`: Có ích / Chưa có ích (theo từng insight); "Không hiện loại thông tin này nữa" ẩn loại đó ở mọi nơi, có Hoàn tác. Rules, index collection-group và phần dọn dữ liệu khi xoá bé đã có | `insight_repository.dart`, `insight_screens.dart`; `firestore.rules`, `firestore.indexes.json`, functions `account.ts` | `insights_test.dart`, `firebase/tests/insights.rules.test.ts` |
| AI06 "Điều đáng chú ý nhất" trong Tổng kết tuần (Premium; insight nào có các đêm gần đây kết thúc trong tuần đó) | `insight_widgets.dart` (`WeekInsightBlock`), `rhythm/week_screen.dart` | `insights_test.dart`; golden Tổng kết tuần không đổi |

**Khác đề xuất ban đầu, có chủ đích:**
- **Không có chip "Đang hỏi về" và không thêm trường `context` vào `startTaskRequestSchema`.** Câu hỏi điền sẵn tự nêu chủ đề, và đường quy tắc trả lời được mà không cần ngữ cảnh. Làm vậy tránh sửa luồng `startTask` mà một session khác đang làm.
- **Câu hỏi tiếp theo đi đường Lumi thường.** Lumi đọc `sleep_facts` / `care_summary`, hoặc gọi model và tốn 1 lượt.
- **NL07 chưa chuyển sang đọc S2.** Theo D-150, phần cơ bản của Nhịp lớn lên vẫn Free, còn S2 là Premium; ghép hai thứ sẽ lấy mất tính năng Free.
- **Thông báo Chủ Nhật không đổi.** Nó đã mở Tổng kết tuần, và màn này giờ có khối insight (D-151 #8).

**Chưa kiểm:**
- Chưa chạy eval Lumi với model thật. Đường mới không gọi model, nhưng danh sách công cụ đọc mà model thấy có thêm `insight_basis`.
- Chưa thử trên máy thật.

**Golden lệch không do thay đổi này:** `rh/ms01_milestone_*_vi` (0,12 %, một nhãn trên màn Mốc, file đang có sửa đổi của session khác).

**Bản cũ: Tiếp theo, P2 (app):**
- Repository đọc `insights/current` cùng kiểm tra "cũ": ẩn ngay khi một bản ghi trong cửa sổ có `updatedAt > computedAt`.
- Biến thể insight của `ClCard`.
- Các màn AI03, AI02, AI04.
- `WidgetId` mới cho Hôm nay, kèm lời mời cho hộ Free.
- Dòng insight trong Thống kê; NL07 đọc S2.
- Đổi tên nhóm trong Khám phá.

