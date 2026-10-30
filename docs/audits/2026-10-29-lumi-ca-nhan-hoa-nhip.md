# Lumi · Gợi ý cá nhân hoá · Nhịp của con — hiện trạng, review và đề xuất "wow"

Ngày 29/10/2026 · nhánh `s2-onboarding` @ `8e53ea55` · **chỉ audit và đề xuất**: không sửa code, ARB hay nội dung.
Nguồn: `docs/product/lumi-plan.md` (§13), `docs/assistant/*`, `docs/product/personalization-v2-plan.md`,
`docs/development/personalization-v2-review-2026-10-20.md`, `docs/product/premium-personalization-plan.md`,
`docs/product-audit/06-lumi-audit.md`, `content/rhythm/`, code ở `apps/mobile/lib/features/{assistant,rhythm,adaptive,ai}`
và `firebase/functions/src/{assistant*,rhythm*,personalization*}`. Không chạy thử trên máy thật, không gọi model.

---

## 1. Hiện trạng: đang có gì

### 1.1 Lumi (trợ lý)

| Mảng                         | Đang có                                                                                                                                                                                                                         | Bằng chứng                                        |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| Cách hoạt động               | Nói hoặc gửi ảnh → app hiểu → **soạn bản nháp** → người dùng xem lại → bấm lưu mới ghi. Model chỉ đọc và soạn; mọi thao tác ghi đi qua endpoint cố định                                                                         | `docs/assistant/architecture.md`                  |
| Ghi qua chat                 | Bú bình, bú mẹ, ngủ, hút sữa, tã, tăng trưởng, timer ("đang ngủ từ 10 phút trước"), ghi nhận, chi tiêu (cả ngoại tệ), nhắc việc (cả ngày, cả người nhận)                                                                        | `firebase/functions/src/assistant-tools.ts:56-76` |
| **Chưa** ghi được            | Bữa ăn dặm (`meal: available: false`), mũi tiêm, mốc phát triển, album, nhắc lặp lại                                                                                                                                            | `assistant-tools.ts:69`; lumi-plan §13.1 L5       |
| Đọc dữ liệu                  | 16 công cụ: tóm tắt chăm sóc, giấc ngủ, ngày hôm nay, tã, hút sữa, tăng trưởng, timer, mũi tiêm tới, nhắc hôm nay, chi tiêu tháng, ăn dặm, mốc, giai đoạn, thư viện, sơ cứu                                                     | `packages/contracts/src/assistant-reads.ts:5-21`  |
| Ảnh                          | Hoá đơn → chi tiêu; ghi chú viết tay → bản nháp                                                                                                                                                                                 | slice A3                                          |
| An toàn                      | Dấu hiệu nguy hiểm được bắt **trước** model, miễn phí, chuyển sang hướng dẫn sức khoẻ; không chẩn đoán, không liều thuốc                                                                                                        | `assistant-tools.ts:83+`                          |
| Chia sẻ                      | Một cuộc trò chuyện chung mỗi bé cho Cùng nuôi + người chăm sóc; chi tiêu luôn riêng (D-075)                                                                                                                                    |                                                   |
| Credit                       | Một quỹ chung cho mọi AI (chat, bàn giao, giải thích); Free 30 credit một lần, Premium theo tháng (D-101); không hiện credit ngoài trang "Chi tiết" (D-081)                                                                     |                                                   |
| Chất lượng                   | Live eval 21/10: 18/18 câu của chủ sản phẩm, 10/13 câu đọc; e2e giả lập 340/341                                                                                                                                                 | `docs/assistant/eval-2026-10-21-l10.md`           |
| **Chưa làm** (theo kế hoạch) | **L8** ô nhập "đang trả lời…" và mặc định "bây giờ"; **L6** "Bé dậy chưa?"; **L4** gợi ý bước tiếp sau khi lưu và lối vào từ timer/Lịch sử/Ăn dặm; **L5** ghi cho các module còn lại; **L9b** chọn model; **L9c** dọn bộ đọc cũ | lumi-plan §13.1 (không thấy commit nào sau 22/10) |

### 1.2 Gợi ý cá nhân hoá (Personalization v2, P-172)

| Mảng                     | Đang có                                                                                                                                                                      |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Hôm nay                  | Một thẻ chính + tối đa 2 thẻ phụ, gộp từ nhịp, nhắc việc, ăn dặm, dinh dưỡng, mốc, mũi tiêm, kỷ niệm. Sức khoẻ luôn đứng đầu                                                 |
| Vòng thử ý tưởng (D-102) | "Mình sẽ thử" → hỏi giờ nhắc → "Sẽ thử · tối nay" → sáng hôm sau "Con thế nào?" (Có ích / Chưa rõ / Không hợp)                                                               |
| Bộ chọn gợi ý            | `recommend()`: nhu cầu từ ghi nhận ×3 + sở thích ×2 + từng có ích ×1 − vừa gợi ý − không hợp; nghỉ 3 ngày                                                                    |
| Gợi ý mỗi ngày (D-099)   | Push từ server đúng giờ đã chọn, chỉ khi có điều mới                                                                                                                         |
| Sổ tay nhà mình          | Điều gia đình tự xác nhận; Lumi đọc ghi chú chung khi tư vấn                                                                                                                 |
| Hoàn cảnh hôm nay        | "Hôm nay mình có bao lâu", trọng tâm tuần, ngày khác thường; tự hết hạn                                                                                                      |
| Tóm tắt tuần             | Chủ nhật: số liệu tuần, ngày ghi đủ, cả nhà cùng chăm (không xếp hạng), đã thử gì, một ý tưởng tuần tới                                                                      |
| **Kho nội dung**         | **53 hoạt động + 35 thẻ "Tuần này của bé", tất cả `review: null`** (chưa chuyên gia nào duyệt); 24 hoạt động 12–36 tháng vẫn là bản nháp (`content/rhythm/SEED-NOTES.md` §0) |

### 1.3 Nhịp của con / Nhịp lớn lên

| Mảng                     | Đang có                                                                                               | Free / Premium                     |
| ------------------------ | ----------------------------------------------------------------------------------------------------- | ---------------------------------- |
| Lịch tham khảo giai đoạn | 10 giai đoạn theo **ngày dự sinh**, nhãn "Wonder Weeks", luôn viết "có thể…", "một số bé…"            | Free                               |
| Ghi nhận (check-in)      | Hôm nay con thế nào → một gợi ý → phản hồi                                                            | Free (gợi ý theo nhu cầu: Premium) |
| Nhịp riêng của con       | Khoảng cách giữa các cữ bú và độ dài giấc ngày, **chỉ từ những ngày ghi đủ**; "thiếu ghi ≠ bé ngủ ít" | Premium ("Hỗ trợ phù hợp")         |
| So sánh giấc ngủ         | Mấy ngày gần đây so với mức thường của con                                                            | Premium                            |
| Từ nhịp → nhắc           | Khoảng cách cữ bú mở trình tạo nhắc "sau cữ gần nhất" (người dùng tự lưu)                             |                                    |
| Bàn giao                 | Ước tính giờ cữ tiếp (`handover_now.dart:105-116`)                                                    |                                    |

**Premium đang "bán" phần này thế nào** (ARB `pv2Card*`):

- **Lumi:** "Hỏi Lumi về nhật ký của con", demo là "Đến 14:20: 3 cữ bú bình · 390 ml".
- **Hiểu nhịp con:** "Gợi ý cá nhân & nhịp nâng cao".

---

## 2. Review: điểm mạnh

1. **Đáng tin hơn hầu hết app cùng loại.**
   - Lumi không tự ghi.
   - Số liệu do server tính; model chỉ diễn đạt lại.
   - Đường sức khoẻ được ưu tiên và miễn phí.
   - App luôn nói "thường" chứ không "nên", và không so con với bé khác.
   - "Thiếu ghi ≠ 0".

   Đây là nền móng đúng cho sản phẩm về trẻ em, đừng đánh đổi.

2. **Ghi bằng lời nói đúng cách cha mẹ nói.** "Đang ngủ từ 10 phút trước" được hiểu thành timer bắt đầu trong quá khứ (D-088). Đây là khoảnh khắc "wow" thật, nhất là lúc nửa đêm.
3. **Dữ liệu đã đủ giàu để làm nhiều hơn.** Đã có nhật ký chăm sóc, khoảng cữ bú, giấc ngủ, tăng trưởng (WHO), mũi tiêm, ăn dặm, mốc, kỷ niệm và sổ tay. Phần lớn "wow" bên dưới không cần dữ liệu mới.

## 3. Review: vì sao chưa đủ "wow" để trả tiền

| #   | Vấn đề                                                                                                                                                                                                                                    | Tác động                                    | Mức        |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | ---------- |
| R1  | **Lumi chủ yếu nhắc lại điều app đã hiện miễn phí.** Demo Premium "3 cữ · 390 ml" trùng thẻ Hôm nay. Người dùng không thấy lý do trả tiền                                                                                                 | Chuyển đổi Premium thấp                     | Cao        |
| R2  | **Chỉ nhìn về quá khứ, không nhìn trước.** Câu hỏi lớn nhất của cha mẹ bé 0–12 tháng là "**khi nào** con đói hay buồn ngủ tiếp?". App đã tính khoảng cữ bú nhưng chỉ dùng trong Bàn giao và trình tạo nhắc; chưa có khoảng thức theo tuổi | Bỏ lỡ giá trị hằng ngày rõ nhất             | Cao        |
| R3  | **Phần lớn gợi ý cần check-in**, tức là thêm việc cho người đang mệt. Nhịp riêng chỉ có giấc ngủ và khoảng cữ bú                                                                                                                          | Ít người dùng đều đặn                       | Cao        |
| R4  | **Kho nội dung mỏng và chưa duyệt.** 53 hoạt động; bé 13–24 tháng chỉ 3–5 lựa chọn mỗi nhu cầu nên hết sau khoảng 2 tuần. Toàn bộ `review: null`, mà quy định prod (D-058) cấm xuất bản khi chưa có người duyệt ký                        | **Chặn ra mắt** phần gợi ý; gợi ý lặp lại   | **Chặn**   |
| R5  | **Lumi bị động.** "Bé dậy chưa?" (L6), bước tiếp sau khi lưu (L4) và ô nhập rõ trạng thái (L8) chưa làm. Ăn dặm, tiêm, mốc chưa ghi qua chat (L5)                                                                                         | Lumi thành một màn riêng, không phải trợ lý | Trung bình |
| R6  | **Năm "trí tuệ" rời rạc**: Lumi, Gợi ý, Nhịp, Bàn giao, Tóm tắt tuần (và Cùng Chăm Con). Thẻ Premium lại tách "Lumi" và "Hiểu nhịp con" như hai thứ chồng nhau                                                                            | Người dùng không hiểu mình được gì          | Trung bình |
| R7  | **"Wonder Weeks" là thương hiệu**, và nghiên cứu độc lập (de Weerth & van Geert, 1998) không xác nhận các giai đoạn cố định; chính seed đã trích nghiên cứu này                                                                           | Rủi ro pháp lý (nhãn hiệu) và uy tín        | Trung bình |
| R8  | **Pháp lý và chi phí chưa xong**: đồng ý gửi dữ liệu sang OpenAI (Q-070), chưa có thanh toán (COM-01), Free chỉ 30 credit một lần rồi hết                                                                                                 | Không bật được cho người thật               | **Chặn**   |
| R9  | **Chưa có lượt thử trên máy thật** cho L1b/L7/L9/L10 và cá nhân hoá v2 (lumi-plan §13.3, review v2 "no physical-device notification verification")                                                                                        | Rủi ro chất lượng khi ra mắt                | Trung bình |

---

## 4. Đề xuất: làm gì để "wow" và thật sự có ích

Nguyên tắc giữ nguyên: dữ liệu của chính bé; "thường" không "nên"; không chẩn đoán; không so bé khác; một việc chính; người dùng bấm mới ghi.
Mọi đề xuất dưới đây là **tính năng mới, tức quyết định L3 của chủ sản phẩm** (D-109). Chưa làm gì.

### Tầng 1 — "Wow" hằng ngày (nên làm trước)

**W1. "Sắp tới của con": nhìn trước cữ bú và giấc ngủ tiếp theo** · Premium · cỡ M

- Thẻ trên Hôm nay (và sau này widget, Live Activity): "Cữ tiếp **thường** khoảng 14:10–14:40 · theo 7 ngày gần đây của con", "Con đã thức 1 giờ 20 phút · **thường** bắt đầu buồn ngủ sau khoảng 1 giờ 30".
- Dùng khoảng cữ bú đã tính (A1–A2) và độ dài giấc. Thêm **khoảng thức theo tuổi** từ nội dung đã duyệt, rồi tinh chỉnh dần theo dữ liệu của con.
- Thiếu dữ liệu: dùng mốc tham khảo theo tuổi và ghi rõ "tham khảo".
- Kèm **L6 "Bé dậy chưa?"**: timer ngủ đang chạy lâu hơn mức thường thì gửi đúng một thông báo nhẹ.
- _Vì sao wow:_ đây là câu hỏi cha mẹ tự hỏi chục lần mỗi ngày; app trả lời trước khi họ hỏi.
- Đo: tỷ lệ mở thẻ, ghi cữ trong ±30 phút của khoảng dự kiến, giữ chân D7 của nhóm có thẻ.

**W2. Ghi một chạm thật sự nhanh bằng giọng nói ban đêm** · Free (ghi) / Premium (hiểu câu phức tạp) · cỡ S–M

- Hoàn tất L8: mặc định là "bây giờ" và không hỏi lại giờ khi nói "bé bú 120ml".
- L4: sau khi lưu, gợi ý bước tiếp ("Bắt đầu đếm giấc ngủ?").
- Nút micro trên màn khoá và trên timer. Night care: chữ to, màu dịu.
- _Vì sao wow:_ tay bế con, giọng thì thầm, xong trong 3 giây.

**W3. "Lumi nhận ra": phát hiện khuôn mẫu từ nhật ký của chính con** · Premium · cỡ M–L

- Mỗi tuần tối đa một phát hiện, chọn từ **danh sách mẫu đã duyệt**, không để model tự suy. Ví dụ:
  - "3 tuần gần đây, ngày con ngủ ngày dài hơn thì tối con vào giấc sớm hơn."
  - "Cữ bú đêm đã giãn từ ~2g30 lên ~3g30 trong 2 tuần."
  - "Từ khi bắt đầu ăn dặm, số cữ bú bình giảm 1."
- Bắt buộc có: đủ số ngày ghi đủ, ghi rõ "quan sát, không phải nguyên nhân", nút "Xem dữ liệu".
- _Vì sao wow:_ "app hiểu con mình". Thứ cha mẹ không tự thấy được khi mệt.

### Tầng 2 — Có ích rõ, đáng trả tiền

**U1. "Chuẩn bị đi khám": báo cáo một chạm cho bác sĩ** · Premium · cỡ M

- PDF hoặc trang chia sẻ có hạn gồm:
  - biểu đồ cân nặng, chiều dài, vòng đầu theo WHO;
  - bú, ngủ, tã 7–14 ngày;
  - mũi tiêm đã và sắp tiêm;
  - ghi nhận, triệu chứng cha mẹ đã ghi;
  - danh sách câu hỏi cha mẹ muốn hỏi (Lumi giúp gom từ chat và sổ tay).
- Chỉ trình bày dữ liệu, không diễn giải y khoa. Dùng lại các bộ đọc và đường xuất dữ liệu đã có.
- _Vì sao có ích:_ giải quyết đúng khoảnh khắc lo lắng; bác sĩ thấy số liệu thay vì trí nhớ. Dễ giải thích giá trị Premium.

**U2. "Hỏi về hành trình của con"** · Premium · cỡ M

- "Lần đầu con lật là khi nào?", "Tháng trước con nặng bao nhiêu?", "Cho xem ảnh con ăn dặm lần đầu."
- Thêm công cụ đọc kỷ niệm (theo ngày, caption, mốc), tôn trọng quyền xem. Mở thẳng ảnh hoặc mốc.
- _Vì sao wow:_ Lumi trở thành trí nhớ của gia đình, không chỉ nhật ký.

**U3. "Thư của con" hằng tuần / hằng tháng: recap cảm xúc** · Premium (Free bản rút gọn) · cỡ M

- Ghép Tóm tắt tuần (số liệu) với Kỷ niệm (ảnh) và mốc thành một trang đẹp:
  - "Tuần thứ 14 của Na: lần đầu cười thành tiếng, ngủ dài nhất 5 giờ, ông bà xem 23 ảnh."
- Chia sẻ cho người thân theo quyền xem. Recap tháng là cơ hội đã được audit 20/10 chỉ ra.
- Dùng lại `weekly summary`, renderer video và thiệp.
- _Vì sao wow:_ lý do mở app vào Chủ nhật; ông bà chờ đón; lan truyền tự nhiên.

**U4. Khi con "khác mọi ngày": giải thích và một việc nhỏ** · Premium · cỡ S–M

- Khi nhịp lệch rõ so với mức thường của con (đã có "Mấy ngày con khác"), Lumi đưa ra:
  - (1) lý do thường gặp theo tuổi, từ nội dung đã duyệt;
  - (2) một việc nhỏ để thử;
  - (3) khi nào nên hỏi bác sĩ, theo đường sức khoẻ.
- Không chẩn đoán.

### Tầng 3 — Hoàn thiện nền để những thứ trên có ý nghĩa

| #   | Việc                                                                                                                                                              | Vì sao                                                       |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| F1  | **Duyệt nội dung bởi chuyên gia** (nhi khoa / điều dưỡng / phát triển trẻ): 53 + 35 + 24 mục, khoảng thức theo tuổi, mẫu "Lumi nhận ra"                           | Không có thì prod không xuất bản được (R4), và gợi ý lặp lại |
| F2  | **Mở rộng kho hoạt động** lên khoảng 150–200, đủ 5–10 lựa chọn mỗi nhu cầu mỗi giai đoạn, kèm phiên bản 2–5 phút                                                  | Hết lặp sau 2 tuần                                           |
| F3  | **Gợi ý không cần check-in**: suy nhu cầu từ nhật ký (giấc ngắn dần, cữ dày lên) và hỏi xác nhận bằng một chạm                                                    | Giảm việc cho cha mẹ (R3)                                    |
| F4  | L5: ăn dặm, mũi tiêm, mốc ghi được qua Lumi                                                                                                                       | Lumi phủ cả app (D-088)                                      |
| F5  | **Đổi tên và nguồn lịch giai đoạn**: bỏ nhãn "Wonder Weeks", dùng mốc phát triển CDC/WHO làm khung chính                                                          | R7                                                           |
| F6  | **Gộp thành một câu chuyện Premium "Hiểu con"**: Lumi = giao diện, Nhịp = dữ liệu, Gợi ý = hành động. Viết lại thẻ Premium theo W1/U1/W3, bỏ demo "3 cữ · 390 ml" | R1, R6                                                       |
| F7  | Pháp lý Q-070, thanh toán (COM-01), lượt thử máy thật (R9)                                                                                                        | Điều kiện để bật cho người thật                              |

### Đề xuất ranh giới Free / Premium (cần chủ sản phẩm quyết)

| Free (luôn có ích)                                                                                                                 | Premium ("hiểu con" và "lo trước")                                                                                                                            |
| ---------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Ghi bằng lời nói câu đơn giản, số liệu hôm nay, đường sức khoẻ, nhắc việc, lịch tham khảo, Tóm tắt tuần cơ bản, một gợi ý mỗi ngày | W1 Sắp tới của con, W3 Lumi nhận ra, U1 Chuẩn bị đi khám, U2 Hỏi về hành trình, U3 Thư của con đầy đủ, U4 giải thích khi con khác, Lumi không giới hạn hợp lý |

**Không** đặt Premium lên an toàn hay sức khoẻ: dấu hiệu nguy hiểm, sơ cứu và cảnh báo luôn miễn phí.

---

## 5. Thứ tự đề nghị

1. **Điều kiện bắt buộc:** F1 (thuê người duyệt nội dung), F7 (Q-070, thanh toán hoặc quyết định ra mắt miễn phí), lượt thử máy thật cho Lumi L10 và v2.
2. **Sprint "wow" đầu:** W1 + L6, W2 (L8 + L4). Dùng dữ liệu đã có nên nhanh thấy giá trị.
3. **Sprint Premium:** U1 Chuẩn bị đi khám, U3 Thư của con, F6 viết lại thẻ Premium.
4. **Sau khi có dữ liệu thật:** W3 Lumi nhận ra, U2, U4, F2, F3, F4, F5.

Thước đo chung:

- D7 và D30 của nhóm dùng W1;
- tỷ lệ "Có ích" trên gợi ý đã thử;
- tỷ lệ mở Thư của con và số lượt chia sẻ;
- chuyển đổi xem paywall → mua;
- chi phí AI trên mỗi gia đình hoạt động.

Chỉ đo khi `product_analytics` đã bật (ANA-01 trong audit trước).

## 6. Giới hạn của review này

- Không chạy app trên máy, không render giao diện, không gọi model thật; mọi nhận định về trải nghiệm dựa trên code, tài liệu và các review đã có.
- Không đánh giá độ chính xác chuyên môn của nội dung. Đó chính là việc F1 cần chuyên gia.
- Mốc thời gian và số đề xuất (ví dụ 150–200 hoạt động) là ước lượng để thảo luận, không phải cam kết.
