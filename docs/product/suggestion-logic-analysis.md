# Gợi ý mỗi ngày · "Ý tưởng hôm nay" — phân tích và đề xuất logic mới

31/10/2026 · Nguồn: code hiện tại (`packages/contracts/src/personalization.ts`, `firebase/functions/src/personalization-v2.ts`, `firebase/functions/src/rhythm.ts`, `firebase/functions/src/engagement-sources.ts`, `apps/mobile/lib/features/today/today_for_baby.dart`), gói nội dung đã xuất bản trên dev (`rc_20261031_01`, giống `content/rhythm/content.seed.json`) và một mô phỏng chạy đúng hàm `recommend()` hiện tại.

Trạng thái: **P1 xong, đã deploy dev, chưa commit** (31/10/2026). Chủ sản phẩm đã chốt Q1–Q5 (**D-154**): Q1–Q3 và Q5 theo đề xuất; Q4 chọn **giữ lời mời Premium của D-153** cho gói Free, bỏ phương án ý tưởng theo tuổi cho Free. Q5 đã làm và đã deploy dev (`ideasMaxAgeDays`, dòng "Hiện mới có gợi ý cho con đến 3 tuổi."). P2–P4 chưa làm.

P1 gồm:
- `packages/contracts/src/daily-suggestion.ts`: `pickDailySuggestion`, `rollExposure`, `recordDailyPick`, `exposureAnswer`, `dailyRankingWeights` `rank-v2`.
- 6 ngưỡng mới trong `config/rhythm`, sửa được ở portal → Nhịp lớn lên → Điều kiện gợi ý.
- `personalizedDay` và các câu trả lời (`updatePersonalization`) đọc và ghi `babies/{b}/personalization/exposure`.
- ENG-06 dùng chung lựa chọn của ngày.

Kết quả kiểm thử của chính hàm thật trên gói nội dung, 30 ngày, gia đình không bấm gì:
- ≥ 15 ý khác nhau;
- lặp trong 7 ngày ≤ 3 lần;
- 0–24 tháng không ngày nào ý chính là thẻ kiểm tra hoặc thẻ cho ba mẹ.

Kết quả check-in của Nhịp và Lumi vẫn dùng rank-v1.

---

## 0. Tóm tắt

- **Nội dung không thiếu, logic chọn mới là vấn đề.** Mỗi ngày bé có 23–49 hoạt động hợp tuổi, nhưng một gia đình chỉ thấy **1 hoạt động** (nếu không bấm gì) hoặc **2–3 hoạt động xoay vòng** (nếu có tương tác) trong suốt cả khung tuổi. Từ 0 đến 36 tháng, một gia đình chỉ gặp **6/77** hoạt động.
- **Gợi ý lặp lại được chọn gần như theo thứ tự chữ cái.** Ví dụ, bé từ 0 đến 12 tháng mà ba mẹ không bấm gì thì ngày nào cũng gặp *"Nếu gia đình cho con ngủ chung giường"*. Đây là lời khuyên an toàn, không phải việc làm cùng con. Push "Gợi ý mỗi ngày" (ENG-06) cũng nhắc đúng tên đó mỗi ngày.
- **Năm nguyên nhân:**
  1. Hoà điểm thì xếp theo id.
  2. Chỉ nhớ "đã hiện" khi người dùng bấm "Mình sẽ thử" hoặc "Để sau".
  3. "Có ích" làm hoạt động dính lên đầu.
  4. Thẻ kiểm tra an toàn được xếp chung với hoạt động.
  5. Tín hiệu sở thích gần như không phân biệt được gì.
- **Đề xuất (rank-v2):**
  - Ổn định trong một ngày, đổi giữa các ngày.
  - Có nhật ký "đã hiện" cho từng bé.
  - Không lặp lại trong một khoảng cách đủ dài.
  - Sau khi đã thử thì nghỉ 7 ngày; hoạt động "Có ích" quay lại sau một tuần.
  - Thẻ kiểm tra an toàn và thẻ dành cho ba mẹ thành **thẻ phụ**, tối đa 1 lần mỗi 4 ngày, không bao giờ làm ý tưởng chính.
  - Dùng các tín hiệu đã có sẵn nhưng chưa dùng: giai đoạn tham khảo, hoạt động vừa hợp tuổi, độ hẹp của khung tuổi.
- **Kết quả mô phỏng 30 ngày:**
  - Từ 1 lên **20–30** ý khác nhau.
  - Tỉ lệ lặp trong 7 ngày giảm từ 97% xuống **0–17%**.
  - Ý tưởng chính không còn ngày nào là thẻ kiểm tra an toàn (trước đây có thể là 30/30 ngày).
  - Trong 0–36 tháng: gặp **77/77** nội dung (65 hoạt động chính, 12 thẻ phụ), thay vì 6/77.
- **Lộ trình:**
  - **P1:** chỉ sửa code, sửa phần lớn vấn đề.
  - **P2:** thêm loại nội dung trên portal.
  - **P3:** dùng thêm tín hiệu từ nhật ký và giai đoạn.
  - **P4:** bù nội dung còn thiếu.
  - Chi tiết ở §10.

---

## 1. Logic hiện tại chạy thế nào

```
Hôm nay mở app
  └─ personalDayProvider ──callable──► personalizedDay()          personalization-v2.ts:498
        ├─ cần `personalization.cross_module` (Premium, group A); không có → không có ý tưởng
        ├─ ứng viên = activities đã xuất bản − bị loại (Ẩn / Không hợp / Đã biết / Loại cho bé)
        │             − đang tạm ẩn (Để sau 2 ngày; Đã thử, Có ích: hết hôm nay)
        │             − nếu "bận / vài phút": chỉ hoạt động ≤ 5 phút
        ├─ need = check-in hôm nay (ngủ / bú / dỗ / kỹ năng mới→mốc), hoặc trọng tâm tuần "chơi"
        ├─ recommend()                                              personalization.ts:397
        │     điểm = 3·need + 2·sở thích + 1·đã có ích − 2·mới hiện (≤ 2 ngày) − 4·không hợp
        │     hoà điểm → sắp theo id (a→z)                          personalization.ts:261
        └─ activityIds = [chính, phụ, phụ]  (bận: chỉ 1)
  └─ ENG-06 "Gợi ý mỗi ngày" gọi lại personalizedDay, nêu tên activityIds[0]   engagement-sources.ts:688
```

Hai điểm quan trọng:

- **"Mới hiện" không phải là "đã hiện".** `feedbackMemory` chỉ đặt `lastShown` khi người dùng bấm `started` (Mình sẽ thử) hoặc `not_today` (Để sau). Hệ thống không ghi lại việc một ý tưởng đã hiện ra (`personalization.ts:328`).
- **Phản hồi chỉ được đọc khi có `rhythm.advanced`** (`personalization-v2.ts:594`). Gói Free cũng không có ý tưởng hôm nay vì `cross_module`, nên toàn bộ phần xếp hạng hiện chỉ chạy cho Premium.

---

## 2. Đo thực tế (mô phỏng 30 ngày, hàm `recommend()` thật, gói nội dung đã xuất bản)

Sở thích dùng trong mô phỏng là sở thích suy ra từ mục tiêu gợi ý sẵn cho bé 0–1 tuổi (`track_care` + `memories` → sleep, feeding, nutrition, moments).

Ba kiểu người dùng:
- **Bỏ qua:** chỉ xem, không bấm gì.
- **Thỉnh thoảng:** cứ 3 ngày bấm "Mình sẽ thử" một lần.
- **Tích cực:** ngày nào cũng thử, cách một ngày bấm "Có ích".

| Bé | Người dùng | Ý khác nhau | Lặp trong 7 ngày | Ngày mà ý tưởng là thẻ kiểm tra an toàn |
|---|---|---|---|---|
| 3 tuần | bỏ qua | 1 | 97% | 30/30 |
| 1,5 tháng | thỉnh thoảng | 2 | 93% | 10/30 |
| 6,5 tháng | tích cực | 2 | 93% | 16/30 |
| 16 tháng | bỏ qua | 1 | 97% | 0 |
| 2,5 tuổi | tích cực | 2 | 93% | 0 |
| 0–36 tháng | thỉnh thoảng | **6 / 77** hoạt động | 99% | 122 ngày |

Ba hoạt động gặp nhiều nhất trong 0–36 tháng: `act_bedtime_routine` (285 ngày), `act_brush_first_teeth` (243 ngày), `act_v2_choose_book` (242 ngày).

---

## 3. Vấn đề, xếp theo mức nặng

| # | Vấn đề | Bằng chứng | Hệ quả cho người dùng |
|---|---|---|---|
| **V1** | Hoà điểm xếp theo id, không có yếu tố ngày | `rankCandidates`, `personalization.ts:261` | Cùng một ý mỗi ngày; thẻ trông như bị "đơ". |
| **V2** | Không có nhật ký "đã hiện" | `feedbackMemory`, `personalization.ts:328` | Người không bấm gì (phần đông) không bao giờ được đổi. |
| **V3** | Cửa sổ "mới hiện" chỉ 3 ngày, cố định | `addDaysIso(today, -2)`, `personalization.ts:411` | Người có tương tác xoay vòng 3 ý; 30–49 ứng viên còn lại không bao giờ lộ ra. |
| **V4** | "Có ích" xoá dấu "mới hiện" và cộng 1 điểm | `personalization.ts:333`, `rankingWeights.helpful` | Hoạt động có ích dính lên đầu mỗi ngày: thưởng hoá thành phạt. |
| **V5** | "Đã thử" chỉ ẩn tới hết hôm nay, không ghi vào phản hồi chung của nhà | `updatePersonalization` `until`, `householdFeedback` không có `tried` | Thử xong, mai lại thấy đúng ý đó. |
| **V6** | Thẻ kiểm tra an toàn, thẻ cho ba mẹ và hoạt động làm cùng con cùng tranh một chỗ | 12/77 mục là kiểm tra (ngủ chung, ghế ô tô, nước, nắng muỗi, hóc, trời nóng, vitamin D, ngồi bô) hoặc cho ba mẹ | "Ý tưởng hôm nay" thành lời nhắc an toàn lặp đi lặp lại; thẻ kiểm tra cần được hiện **một lần đúng lúc**, không phải mỗi ngày. |
| **V7** | Sở thích suy từ mục tiêu quá rộng | Mục tiêu gợi ý sẵn của bé 0–1 tuổi khớp 23/29 (bé 45 ngày) và 33/50 (bé 500 ngày) ứng viên | Hệ số 2 điểm gần như cộng cho tất cả, nên chẳng phân biệt được gì. |
| **V8** | Có tín hiệu nhưng chưa dùng | Giai đoạn tham khảo có `activityIds` (3–6 mỗi giai đoạn, `rhythm.ts:105`); `timeOfDay`; khung tuổi; mẫu nhật ký (`routinePatterns`) | Gợi ý không bám được "tuần này bé đang thế nào". |
| **V9** | Ý phụ không đa dạng | `secondary = relevant.slice(1, 3)` | Có thể ra 3 ý đều về giấc ngủ. |
| **V10** | Gói Free không có ý tưởng hôm nay | `crossModule`, `personalization-v2.ts:604` | Có 77 hoạt động đã duyệt mà người dùng Free không thấy trên Hôm nay. Đây là quyết định gói (Q4). |
| **V11** | ENG-06 nêu cùng một tên mỗi ngày | `engagement-sources.ts:695` | Push lặp lại khiến người dùng tắt thông báo. Sửa V1–V3 thì hết. |
| V12 | Thẻ nhỏ "Thư viện" lấy 2 bài mới nhất theo tuổi | `library_today.dart:23` | Cùng 2 bài trong nhiều tuần. Mức nhẹ hơn. |

---

## 4. Thế nào là gợi ý "bổ ích"

Tiêu chí dùng để chấm logic mới:

1. **Làm được ngay:** ý tưởng chính là việc làm cùng con, trong thời gian ba mẹ có. Không phải bài đọc, không phải danh sách kiểm tra.
2. **Đúng lúc:** đúng tuổi, ưu tiên điều vừa mới hợp tuổi, đúng giai đoạn tham khảo, đúng nhu cầu ba mẹ vừa báo.
3. **Mới mẻ nhưng không lộn xộn:** giữ nguyên trong ngày, đổi giữa các ngày, không lặp trong khoảng cách hợp lý; việc nhà mình thấy có ích thì quay lại có nhịp.
4. **Tôn trọng phản hồi:** Ẩn, Không hợp, Đã biết là vĩnh viễn; Để sau là nghỉ ngắn; Đã thử là nghỉ một tuần; Có ích là quay lại sau một tuần.
5. **An toàn có chỗ riêng:** thẻ kiểm tra hiện một lần khi vừa hợp tuổi, tối đa một lần mỗi tháng cho tới khi ba mẹ bấm "Đã biết"; không bao giờ chiếm chỗ ý tưởng chính.
6. **Giải thích được:** mỗi lựa chọn có lý do (đã có `reasonCode`) và kiểm thử lặp lại được, cùng đầu vào cho cùng kết quả.

---

## 5. Logic đề xuất: rank-v2

### 5.1 Lọc cứng (trước khi tính điểm)

| Điều kiện | Hiện tại | Đề xuất |
|---|---|---|
| Đúng tuổi, vùng, ngôn ngữ, đã xuất bản | ✔ | giữ |
| Ẩn / Không hợp / Đã biết / Loại cho bé | ✔ | giữ |
| Bận, vài phút → ≤ 5 phút | ✔ | giữ |
| Đã hiện gần đây | không có | ẩn nếu đã hiện trong **G ngày**; G = trong khoảng [2, 7], bằng số hoạt động hợp lệ chia 4, để nhóm ứng viên nhỏ không bao giờ trống |
| Đã thử | chỉ ẩn hôm nay | ẩn **7 ngày** |
| Có ích | dính lên đầu | ẩn 7 ngày, sau đó được cộng điểm "nhà mình thích" |
| Để sau | 2 ngày (`cooldownDays` 3 khi đọc từ phản hồi) | giữ |
| Thẻ kiểm tra / cho ba mẹ | như hoạt động thường | **không làm ý tưởng chính**; thẻ kiểm tra: tối đa 1 lần mỗi 30 ngày cho tới khi "Đã biết"; thẻ cho ba mẹ: tối đa 1 lần mỗi 10 ngày |

### 5.2 Điểm

```
điểm = 3 · khớp nhu cầu hôm nay            (check-in, trọng tâm tuần)
     + 1 · khớp sở thích                   (giảm từ 2: đang quá rộng, V7)
     + 1 · nằm trong giai đoạn tham khảo   (activityIds của stage hiện tại; P3)
     + 1 · vừa hợp tuổi (< 14 ngày)        ("mới với tuổi của con")
     + 0,5 · khung tuổi hẹp (≤ 120 ngày)   (đúng lúc hơn hoạt động kéo dài cả năm)
     + 0,5 · chưa từng hiện                (mới mẻ)
     + 1 · nhà mình thấy có ích (> 7 ngày trước)
     − min(3, số lần hiện mà không ai phản hồi)   (mệt: lướt qua 3 lần thì lùi lại)
     + 0,9 · h(bé, ngày, hoạt động)        (h ∈ [0, 1): SHA-256 → số; ổn định trong ngày,
                                            đổi theo ngày; thay cho sắp theo id)
```

- Giữ hệ số 3 cho nhu cầu vì đó là tín hiệu mạnh nhất: ba mẹ tự nói hôm nay cần gì.
- Phần ngẫu nhiên có giới hạn (dưới 1 điểm), nên không bao giờ vượt được một tín hiệu thật. Nó chỉ chọn giữa các mục ngang điểm.

### 5.3 Chọn

1. **Ý tưởng chính:** hoạt động loại "làm cùng con" có điểm cao nhất.
2. **Hai ý phụ:** hai hoạt động tiếp theo mà nhu cầu chính **khác** nhu cầu chính của ý tưởng chính (V9).
3. **Thẻ phụ:** nếu đã 4 ngày chưa hiện thẻ phụ, một thẻ kiểm tra hoặc thẻ cho ba mẹ có điểm cao nhất thay cho ý phụ thứ hai. Chỗ này không đổi luật "một thẻ chính" của D-102.
4. **Ghi lại** lựa chọn của ngày (§7) để cả nhà cùng thấy một ý, push ENG-06 nêu đúng ý đó, và ngày mai biết hôm nay đã hiện gì.

Nếu người dùng bấm Để sau, Ẩn hoặc Đã biết trên ý tưởng chính trong ngày: chọn lại từ danh sách đã tính và ghi đè lựa chọn của ngày. Hiện tại app cũng đã gọi lại server sau mỗi phản hồi (`updatePersonalization` → `invalidate`).

### 5.4 Lý do hiển thị (`reasonCode`)

Giữ các lý do hiện có: `SELF_REPORTED_NEED`, `WEEKLY_FOCUS`, `INTEREST`, `PREVIOUS_HELPFUL`, `AGE_CONTENT`. Thêm:

- `NEW_FOR_AGE`: "Mới hợp với tuổi của con".
- `STAGE`: "Hợp với giai đoạn tuần này", từ P3.

`PREVIOUS_HELPFUL` lúc này mang nghĩa "nhà mình thấy có ích, thử lại nhé" và chỉ xuất hiện sau ít nhất 7 ngày. Câu chữ (ARB) đi qua `cl-ux-writing`.

---

## 6. Kết quả mô phỏng của rank-v2, và tự phản biện

Bảng dưới dùng cùng gói nội dung, cùng sở thích và ba kiểu người dùng như §2. Bản mẫu dùng tạm một bảng phân loại 12 mục kiểm tra / cho ba mẹ.

| Bé | Người dùng | Hiện tại: ý khác nhau / lặp 7 ngày | rank-v2: ý khác nhau / lặp 7 ngày | Số nhóm nhu cầu được phủ |
|---|---|---|---|---|
| 3 tuần | bỏ qua | 1 / 97% | **20 / 7%** | 1 → 5 |
| 1,5 tháng | thỉnh thoảng | 2 / 93% | **20 / 10%** | 2 → 5 |
| 6,5 tháng | tích cực | 2 / 93% | **13 / 27%** | 1 → 4 |
| 16 tháng | bỏ qua | 1 / 97% | **30 / 0%** | 1 → 6 |
| 2,5 tuổi | thỉnh thoảng | 2 / 93% | **23 / 3%** | 2 → 4 |
| 0–36 tháng | thỉnh thoảng | 6/77 | **77/77** (65 chính, 12 thẻ phụ, 180 lần hiện thẻ phụ) | 3 → 6 |

Ví dụ 10 ngày, bé 1,5 tháng, ba mẹ không bấm gì:
- **Hiện tại:** "ngủ chung giường" × 10 ngày.
- **rank-v2:**
  - ý tưởng chính lần lượt: phân biệt ngày đêm → nằm sấp trên ngực → bế áp da → quấn khăn → ngậm bắt vú → đi dạo → tiếng ồn trắng → vỗ ợ hơi → giảm kích thích trước giấc đêm → tắm ấm;
  - thẻ phụ vào ngày 1, 5 và 9: vitamin D, ngủ chung an toàn, trời nóng.

**Tự phản biện:**

- *Người dùng tích cực vẫn lặp 27%.* Đây là chủ ý: việc đã thử hoặc thấy có ích quay lại sau 7 ngày, giống một thói quen tốt. Nếu thấy nhiều quá thì nâng thời gian nghỉ sau "Có ích" lên 10–14 ngày; đó là một tham số.
- *Nhóm ứng viên nhỏ (bé 3 tuần có khoảng 14 hoạt động làm cùng con) nên vẫn lặp sau khoảng 2 tuần.* Đây là giới hạn của nội dung chứ không phải của logic (§8).
- *Ngẫu nhiên có thể bị cảm là lộn xộn.* Đã giảm bằng cách giữ nguyên trong ngày, có lý do hiển thị, và tín hiệu thật luôn thắng phần ngẫu nhiên.
- *Thẻ kiểm tra bị lùi xuống làm thẻ phụ thì có thể ít người thấy hơn.* Bù lại bằng cách hiện ngay khi vừa hợp tuổi, nhắc lại mỗi tháng cho tới khi bấm "Đã biết", và không bao giờ bị phần ngẫu nhiên đẩy ra. Mục nào thật sự khẩn cấp (sức khoẻ) vẫn đi đường riêng: ngày ốm thì thẻ sức khoẻ thay thế toàn bộ phần này, như hiện nay.
- *Vì sao không dùng ML hay bandit?* Chưa có người dùng thật (D-144). Luật minh bạch, kiểm thử được và chỉnh trên portal hợp với giai đoạn này hơn. Khi có dữ liệu thì §9 cho biết nên học từ đâu.

---

## 7. Dữ liệu và kiến trúc

- **Nhật ký đã hiện, mỗi bé một tài liệu:** `babies/{b}/personalization/exposure`.

  ```
  { day: { date, primary, secondary[], extra, rankVersion },
    items: { [activityId]: { lastShown, shown, ignored, lastTried, lastHelpful } } }
  ```

  - Chỉ chứa id hoạt động, ngày và số đếm. Không có dữ liệu của con, nên hợp quy tắc log.
  - Kích thước bị chặn theo số hoạt động trong gói nội dung (khoảng 80 mục).
- **Ghi:** `personalizedDay` ghi một lần mỗi ngày cho mỗi bé, trong một transaction.
  - Người mở app đầu tiên trong ngày quyết định ý của ngày; người khác mở sau thì dùng lại lựa chọn đó.
  - `updatePersonalization` (đã chạy transaction) ghi thêm `lastTried`, `lastHelpful` và đánh dấu "đã phản hồi".
  - "Lướt qua" (`ignored`) được tính khi chọn ý của ngày mới: nếu ý chính hôm qua không có phản hồi nào thì `ignored + 1`.
- **Hàm thuần trong contracts:** `recommendV2(input) → outcome`, nhận `exposure` và `today`. Không gọi `Date.now`, không dùng số ngẫu nhiên thật, nên kiểm thử lặp lại được. Trọng số có phiên bản `rank-v2` trong `rankingWeights`. `config/rhythm` thêm các ngưỡng: khoảng cách G, thời gian nghỉ sau thử / có ích, nhịp thẻ phụ. Các ngưỡng này sửa ở portal → Nhịp lớn lên → Điều kiện gợi ý.
- **Dùng chung:** `rhythm.ts` `rank()` (đường check-in cũ) và ENG-06 cùng gọi `recommendV2`. ENG-06 đọc `exposure.day.primary`, nên push luôn nêu đúng ý đang hiện trên app.
- **Chi phí:** thêm 1 lần đọc mỗi lần gọi và 1 lần ghi mỗi bé mỗi ngày. Không đáng kể.

---

## 8. Nội dung cần đi cùng

Logic mới làm lộ ra chỗ nội dung mỏng: trước đây không ai thấy vì không ai được gặp tới đó.

1. **Trường `kind` cho hoạt động** (P2): `activity | check | parent`. Cần thêm vào schema (`activitySchema`), portal (bộ soạn Hoạt động gợi ý) và gói nội dung. Đồng thời sửa nhãn nhu cầu bị gán sai: ghế ô tô đang gắn "bonding", che nắng chống muỗi gắn "play, bonding", an toàn nước gắn "play".
2. **2–3 tuổi:** 0 hoạt động cho nhu cầu "Gắn kết"; chỉ 3 hoạt động "Mốc phát triển".
3. **Hoạt động ≤ 5 phút:** "Dỗ con" lúc 6–12 tháng chỉ có 2; "Mốc phát triển" lúc 0–3 tháng chỉ có 2.
4. **Bé 0–1 tháng:** khoảng 14 hoạt động làm cùng con. Thêm khoảng 8 hoạt động thì lần lặp đầu tiên lùi từ khoảng 2 tuần ra khoảng 1 tháng.
5. **Con trên 3 tuổi:** chưa có nội dung (Q5).

---

## 9. Đo lường

Sự kiện đã có: `personalEvent` (`feedCardAnswered`, …). Cần thêm sự kiện "đã hiện" kèm `rankVersion`, chỉ chứa id, không có dữ liệu của con.

| Chỉ số | Mục tiêu khi ra mắt |
|---|---|
| Số ý khác nhau / người / 30 ngày | ≥ 15 |
| Tỉ lệ lặp trong 7 ngày (người không tương tác) | ≤ 10% |
| Tỉ lệ có phản hồi trên ý chính | theo dõi, so rank-v1 với rank-v2 |
| "Mình sẽ thử" → "Đã thử" | theo dõi |
| Ẩn / Không hợp / Đã biết trên ý chính | không tăng |
| Tỉ lệ mở push ENG-06; tỉ lệ tắt ENG-06 | mở tăng, tắt không tăng |

Kiểm thử bất biến (contracts):
- cùng đầu vào cho cùng kết quả;
- không lặp trong G ngày khi nhóm ứng viên đủ lớn;
- thẻ kiểm tra / cho ba mẹ không bao giờ là ý chính;
- đã thử thì nghỉ 7 ngày; có ích thì quay lại sau ≥ 7 ngày;
- ngày ốm và chế độ bận giữ nguyên hành vi hiện tại;
- `reasonCode` khớp với tín hiệu đã thắng.

---

## 10. Lộ trình

| Giai đoạn | Việc | Cần |
|---|---|---|
| **P1** (code, khoảng 2–3 ngày) | `recommendV2` trong contracts; nhật ký `exposure`; lựa chọn của ngày dùng chung cho cả nhà; thời gian nghỉ sau thử / có ích; ý phụ đa dạng; ENG-06 đọc lựa chọn của ngày; bảng `kind` tạm trong code cho 12 mục kiểm tra / cho ba mẹ; kiểm thử ở §9; deploy dev | Q1–Q3 |
| **P2** (portal và nội dung) | Trường `kind` trong schema, portal và gói nội dung; sửa nhãn nhu cầu; bỏ bảng tạm | Q1 |
| **P3** (tín hiệu) | Cộng điểm theo giai đoạn tham khảo (`activityIds`); suy nhu cầu từ nhật ký (đêm thức nhiều → ngủ) với Premium; cân `timeOfDay` theo lúc mở app ("Tối nay"); thẻ nhỏ Thư viện xoay theo tuần | sau P1 |
| **P4** (nội dung) | Bù các chỗ ở §8, mục 2–5 | Q5 |
| ~~Q4~~ | Không làm: gói Free giữ lời mời Premium (D-153, D-154 Q4) | — |

---

## 11. Quyết định của chủ sản phẩm (L3)

| # | Câu hỏi | Đề xuất |
|---|---|---|
| **Q1** | Cho thẻ kiểm tra an toàn và thẻ dành cho ba mẹ thành **thẻ phụ** (tối đa 1 lần mỗi 4 ngày; thẻ kiểm tra hiện khi vừa hợp tuổi, nhắc lại mỗi tháng tới khi "Đã biết"), không bao giờ là ý tưởng chính? | **Có** |
| **Q2** | Ý tưởng của ngày **dùng chung cho cả nhà** (người mở đầu tiên quyết định, người khác thấy cùng ý), hay mỗi người một ý theo sở thích riêng? | **Dùng chung.** Ba và mẹ nói về cùng một việc, hợp tinh thần Cùng chăm. Phản hồi của mỗi người vẫn là của riêng người đó. |
| **Q3** | Nhịp lặp: sau "Đã thử" nghỉ 7 ngày; "Có ích" quay lại sau 7 ngày; không lặp trong tối đa 7 ngày. Tất cả chỉnh được ở portal. | **Theo đề xuất** |
| **Q4** | Gói Free có "Ý tưởng hôm nay" không? Hiện tại thì không (V10). | **Có, theo tuổi và có xoay vòng.** Premium giữ phần cá nhân hoá (nhu cầu, nhật ký, phản hồi, giai đoạn). Lý do: 77 hoạt động đã duyệt là giá trị cốt lõi để người dùng Free quay lại mỗi ngày, và là lý do để nâng cấp. **Đã chốt (31/10): không.** Gói Free giữ lời mời Premium của D-153. |
| **Q5** | Con trên 3 tuổi: viết nội dung mới, hay ẩn "Ý tưởng hôm nay" kèm một dòng giải thích? | **Ẩn kèm một dòng** cho tới khi có gói nội dung 3–6 tuổi. |
