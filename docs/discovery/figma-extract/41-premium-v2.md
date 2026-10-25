# Figma extraction — Premium v2 (page `958:13863`)

Source: Figma `sJLG1fAXKDnDr9YI6Yx8ex`, page **"Premium v2"** `958:13863`. Extracted read-only on 2026-10-25 with `get_design_context` (one call per frame; rendered `<p>` text and component props are authoritative, layer names are often stale and are flagged where they differ), `get_metadata` (Carousel set and PW01 layout) and `get_screenshot` (one PNG per screen, in [`img/pv/`](img/pv/), named after the screen id). Paywall frames PW01–PW08 and E10 returned more than 60 KB of code; their text was extracted from the saved output by script and diffed against PW01, so only the differences are listed for PW02–PW08. No Figma node was modified.

**Precedence.** PV00 is the page's own "nguồn chung" (single source for app, website, Portal and backend) dated **24/10/2026**, and PV00B says "Thay thế: trang Premium (P/L/M/F/B), v2.0 PR01–PR04, gói website V8 — Premium v2 là bản hiện hành." So this page **supersedes** the v2.0 Premium screens in [`30-personalization-premium.md`](30-personalization-premium.md) (PR01–PR04, MO02–MO04, the "Premium exploration" PW01/PW02 appendix) and the Free/Plus/Pro tiers of the website Lumi page ([`33`](33-landing-lumi-page.md), [`36`](36-landing-v8-lumi-and-stages.md)). Where a copied use-case screen here (E01–E13) still carries old copy, PV00 wins; every such clash is listed under "Open questions and inconsistencies".

**Theme.** Mixed. E01–E04 (Moments copies) are drawn in **Night care** tokens; E05–E13, Section E (PV30–PV33), Section F (PV40–PV45) are **Light**; the Premium sheet / inline card / paywalls (PW01–PW10) use a fixed **dark premium style** (gradient `#172624`→`#0d1414`, gold `#e9c77b`, CTA gold gradient `#f2d494`→`#d9a857` with ink `#1a1408`, Playfair Display headlines) on both Light and Night screens. Portal PT01–PT04 are desktop 1440. No English frame exists on this page.

**Relation to the map.** Touches D-072 (only the owner buys/manages), D-074 (store payments later), D-075 #1 (one credit pool), D-081 (credits out of main screens), D-089 (one "Tính năng & Premium" hub), P-152 / P-159 (quota fixtures) and Q-071 (SKUs, price, quotas). The new numbers here (Free 30 one-time credits / 2 one-time videos / 1 GB / 3 seats; Premium 200 credits & 4 videos per month / 10 GB / 6 seats; 59.000đ/599.000đ; add-ons 20/50 GB) answer most of Q-071 **as a design proposal**; they are not yet owner decisions in the map.

## Frame list

| Section | Id · name | Node | Theme | Screenshot |
|---|---|---|---|---|
| A · nguồn chung | PV00 · Premium v2 · Quyền lợi & chính sách (nguồn chung) | `958:13864` | board | `img/pv/PV00.png` |
| | PV00B · Hành trình, điểm chạm, lộ trình & kiểm thử | `959:13863` | board | `img/pv/PV00B.png` |
| | PV00C · Entry point Premium — danh sách đầy đủ | `990:15677` | board | `img/pv/PV00C.png` |
| B · Moments & Lumi (label `991:15657`) | E01 · Mẫu video cao cấp · từ MM04 · Mẫu video | `991:15659` | Night | `img/pv/E01.png` |
| | E02 · Thiệp cao cấp · từ MM10 · Thiệp cột mốc | `991:15842` | Night | `img/pv/E02.png` |
| | E03 · Hết lượt tạo video · từ MM07 · Hoàn thiện video | `991:16004` | Night | `img/pv/E03.png` |
| | E04 · Bản nháp mẫu cao cấp · từ MM15 · Tab Câu chuyện | `991:16140` | Night | `img/pv/E04.png` |
| | E05 · Lumi gần hết lượt · từ CH20 · F | `991:16331` | Light | `img/pv/E05.png` |
| | E06 · Lumi hết lượt · từ CH21 · F | `991:16403` | Light | `img/pv/E06.png` |
| | E07 · Premium hết credit · từ CH24 · F | `991:16464` | Light + dark sheet | `img/pv/E07.png` |
| | Notes E01–E07 | `991:15840`, `991:16002`, `991:16138`, `991:16329`, `991:16401`, `991:16462`, `991:16524` | | |
| C · Dung lượng, Gia đình, Tài khoản (label `991:15658`) | E08 · Dung lượng sắp đầy · từ 13c | `991:16526` | Light | `img/pv/E08.png` |
| | E09 · Dung lượng đã đầy · từ 13d | `991:16648` | Light | `img/pv/E09.png` |
| | E10 · Tải lên khi hết dung lượng · từ 13f | `991:16770` | Light | `img/pv/E10.png` |
| | E11 · Tự lưu không đủ dung lượng · từ AS18 | `991:17105` | Light | `img/pv/E11.png` |
| | E12 · Hết chỗ người chăm sóc · từ 14a Gia đình · Light | `991:17198` | Light | `img/pv/E12.png` |
| | E13 · Tôi · chủ động · từ 13a Tôi · Ba/Mẹ | `991:17327` | Light | `img/pv/E13.png` |
| | Notes E08–E13 | `991:16646`, `991:16768`, `991:17103`, `991:17196`, `991:17325`, `991:17451` | | |
| D · Paywall (label `988:15538`) | Component · Premium · Thẻ tính năng (6 variants) | `1019:17008` | dark | `img/pv/C-the-tinh-nang.png` |
| | Component · Premium · Carousel (6 variants) | `1020:17765` | dark | `img/pv/C-carousel.png` |
| | Component · Premium · Chọn gói (Năm / Tháng) | `1020:17820` | dark | `img/pv/C-chon-goi.png` |
| | Component · Gợi ý Premium (Sheet / Inline) | `990:15676` | dark | `img/pv/C-goi-y-premium.png` |
| | PW01 · Paywall Premium · Video | `1021:17681` | dark | `img/pv/PW01.png` |
| | PW02 · Paywall Premium · Thiệp cao cấp | `1021:17915` | dark | `img/pv/PW02.png` |
| | PW03 · Paywall Premium · Lumi | `1021:18298` | dark | `img/pv/PW03.png` |
| | PW04 · Paywall Premium · Dung lượng (Free 1 GB) | `1021:18681` | dark | `img/pv/PW04.png` |
| | PW05 · Paywall Premium · Người chăm sóc | `1021:19064` | dark | `img/pv/PW05.png` |
| | PW06 · Paywall Premium · Chủ động khám phá | `1021:19447` | dark | `img/pv/PW06.png` |
| | PW07 · Paywall Premium · Thành viên không quản lý gói | `1021:19679` | dark | `img/pv/PW07.png` |
| | PW08 · Paywall Premium · toàn trang (tham khảo cuộn) | `1021:19904` | dark, 375×1153 | `img/pv/PW08.png` |
| | PW10 · Mua thêm dung lượng (gia đình đang có Premium) | `998:18711` | dark | `img/pv/PW10.png` |
| | Notes PW01, PW06 | `1025:5304`, `1025:5306` | | |
| E · Thanh toán (label `967:14614`) | PV30 · Thanh toán · bảng xác nhận App Store | `967:14615` | Light | `img/pv/PV30.png` |
| | PV31 · Thanh toán · đang xác nhận | `967:14659` | Light | `img/pv/PV31.png` |
| | PV32 · Thanh toán · chưa hoàn tất | `967:14675` | Light | `img/pv/PV32.png` |
| | PV33 · Khôi phục gói sau khi đổi máy | `967:14708` | Light | `img/pv/PV33.png` |
| | Notes PV30–PV33 | `967:14657`, `967:14673`, `967:14706`, `967:14747` | | |
| F · Quản lý gói (label `968:14661`) | PV40 · Gói của gia đình · Plus (người quản lý) | `968:14662` | Light | `img/pv/PV40.png` |
| | PV40B · Gói của gia đình · Free | `968:14762` | Light | `img/pv/PV40B.png` |
| | PV41 · Lịch sử sử dụng (không lộ nội dung) | `968:14830` | Light | `img/pv/PV41.png` |
| | PV42 · Huỷ gia hạn · điều gì sẽ xảy ra | `968:14894` | Light | `img/pv/PV42.png` |
| | PV43 · Đã về Free · trạng thái cụ thể (không xoá âm thầm) | `969:14706` | Light | `img/pv/PV43.png` |
| | PV44 · Chọn người giữ quyền ghi (3 chỗ) | `969:14774` | Light | `img/pv/PV44.png` |
| | PV45 · Gói của gia đình · thành viên xem | `969:14841` | Light | `img/pv/PV45.png` |
| | Notes PV40–PV45 | `968:14760`, `968:14828`, `968:14892`, `968:14959`, `969:14772`, `969:14839`, `969:14897` | | |
| G · Portal web (label `970:14739`) | PT01 · Portal · Tổng quan thương mại | `970:14740` | 1440 | `img/pv/PT01.png` |
| | PT02 · Portal · Gia đình · kiểm tra quyền lợi & điều chỉnh | `971:14739` | 1440 | `img/pv/PT02.png` |
| | PT03 · Portal · Cấu hình quyền lợi (có version) | `971:14886` | 1440 | `img/pv/PT03.png` |
| | PT04 · Portal · Job video lỗi & lượt cần hoàn | `971:14984` | 1440 | `img/pv/PT04.png` |

Section label frames (`991:15657`, `991:15658`, `988:15538`, `967:14614`, `968:14661`, `970:14739`) were not opened (their ids and roles come from the brief); there is **no PW09** and no E14 screen (E14 is a rule row in PV00C, drawn as PW07). Ids referenced but absent from this page: PV20, PV21, PV22, PV23 (old paywall ids in PV00B and Note · PV40B).

## Section A — Nguồn chung


### PV00 · Premium v2 · Quyền lợi & chính sách (nguồn chung) — `958:13864`

Board frame, white surface, radius 32, padding 48. Title (Bold 40, ink):

- **Premium v2 · Thiết kế trải nghiệm nâng cấp**
- Sub (Medium 16, ink-muted): "Một nguồn quyền lợi chung cho app, website, Portal và backend · 24/10/2026. Giai đoạn ra mắt: Free + Premium. Hành trình: nhận giá trị → hiểu Premium → nâng cấp → quay lại đúng việc đang làm → tiếp tục nhận giá trị mỗi tháng."

**H · 1 — "1 · Bảng quyền lợi — Free + Premium (giai đoạn ra mắt)"**
Sub: "Hai gói cho dễ hiểu. Một gói Premium, hai cách thanh toán (tháng/năm). Có thể thêm dung lượng 20 GB hoặc 50 GB. Không bán credit riêng lẻ."

Table `1000:16859` (header on surface-2, 13 px, columns 320/420/420/360) — verbatim:

| Quyền lợi | Free | Premium | Khoá cấu hình |
|---|---|---|---|
| Credit Lumi | 30 credit trải nghiệm một lần | 200 credit/tháng | lumiCredits |
| Dung lượng | 1 GB | 10 GB · mua thêm 20 GB / 50 GB | storageBytes · storageAddOns |
| Xuất video | 2 lượt trải nghiệm một lần | 4 lượt/tháng | videoExports |
| Mẫu thiệp & video | Mẫu cơ bản · xem trước mẫu cao cấp | Toàn bộ mẫu cao cấp | premiumTemplates |
| Người chăm sóc | 3 người | 6 người | caregiverSeats |
| Người thân xem album | Không giới hạn theo gói | Không giới hạn theo gói | — |
| Chăm sóc, tăng trưởng, sức khoẻ | Đầy đủ | Đầy đủ | — |
| Giá Việt Nam | 0đ | 59.000đ/tháng · 599.000đ/năm | price.vn |
| Giá quốc tế (tham chiếu) | $0 | $5,99/tháng · $49,99/năm (≈ $4,17/tháng) | price.intl |
| Mua thêm dung lượng (chỉ Premium) | — | +20 GB: 39.000đ/tháng · 399.000đ/năm ($1,99 / $19,99)<br>+50 GB: 79.000đ/tháng · 799.000đ/năm ($3,99 / $39,99) | storageAddOns |
| Credit lẻ | Không bán | Không bán — credit đi theo gói | — |

Three rule cards (cloud fill, radius 20, w 500, bullets in mint-text):

**2 · Dùng chung gia đình**
- Một gói cho một gia đình. Người mua là người quản lý gói; chỉ người này thấy thanh toán, đổi hoặc huỷ gói.
- Quyền lợi áp cho mọi bé và thành viên của gia đình đó; không lan sang gia đình khác mà thành viên cũng tham gia.
- Credit Lumi và lượt video là quỹ chung. Lịch sử dùng hiện theo người và tác vụ, không hiện nội dung hội thoại.
- Thành viên không quản lý: thấy quyền lợi, nút "Nhờ {người quản lý} nâng cấp" (lời nhắn soạn sẵn, không kèm nội dung đang làm).
- Người thân (chỉ xem Kỷ niệm) không tính vào chỗ người chăm sóc.

**3 · Cách tính lượt**
- Credit Lumi: giữ chỗ khi bắt đầu → trừ khi thành công → hoàn khi lỗi/huỷ. Mỗi yêu cầu có idempotency key, không trừ lặp.
- Tác vụ lớn hiện chi phí ngay trên nút trước khi chạy ("Nhìn lại 7 ngày · 5 credit"). Không nói token, model, API.
- Video: 1 lượt = 1 lần xuất thành công. Chọn mẫu, chỉnh, xem trước không tốn lượt (preview dựng trên máy). Xuất lại đúng bản đã xuất không tính thêm.
- Hạn mức cấp lại theo ngày gia hạn, không cộng dồn. Không bán credit lẻ — credit chỉ đi theo gói Premium.
- Nâng gói giữa kỳ: cấp ngay hạn mức gói mới cho kỳ hiện tại ⚑ cần chốt cách bù.

**4 · Huỷ, hạ gói & dữ liệu**
- Huỷ gia hạn: giữ Premium tới hết kỳ đã trả, sau đó về Free. Không xoá gì.
- Vượt dung lượng: chặn tải lên mới; xem, tải về, xuất dữ liệu vẫn được. Gợi ý dọn hoặc nâng lại.
- Vượt chỗ người chăm sóc: không xoá thành viên; người quản lý chọn ai giữ quyền ghi, người còn lại tạm chỉ xem.
- Bản nháp dùng mẫu Premium được giữ; xuất cần Premium hoặc đổi mẫu cơ bản. Video đã xuất giữ nguyên.
- Dung lượng mua thêm dùng tới hết kỳ đã trả. Kỷ niệm, nhật ký, video đã xuất luôn truy cập & xuất được ở mọi gói.

**H · 5 — "5 · Cấu hình backend (một nguồn, có version)"** (monospace-style block, Medium 13, verbatim):

```
entitlements: { version: "2.0-launch", plans: {
  free:    { lumiCreditsOneTime: 30, videoExportsTrial: 2, storageGB: 1, caregiverSeats: 3, premiumTemplates: false },
  premium: { lumiCreditsPerCycle: 200, videoExportsPerCycle: 4, storageGB: 10, caregiverSeats: 6, premiumTemplates: true,
             price: { vn: { month: 59000, year: 599000 }, intl: { month: 5.99, year: 49.99 } } } },
  storageAddOns: [ { gb: 20, vn: [39000, 399000], usd: [1.99, 19.99] }, { gb: 50, vn: [79000, 799000], usd: [3.99, 39.99] } ],
  creditTopUps: false   // không bán credit lẻ
}
```

Footer (Medium 14, ink-muted): "Không đưa nội dung chat hoặc dữ liệu sức khoẻ vào dashboard thương mại. Chi phí AI/render/storage ghi theo tác vụ và gia đình (id ẩn danh)."

Note: headings jump 1 → 2/3/4 (cards) → 5; there is no visible section numbered otherwise. "Credit lẻ" row and `creditTopUps: false` agree.

### PV00B · Hành trình, điểm chạm, lộ trình & kiểm thử — `959:13863`

Lead (Bold 22): "Đầu ra đầu tiên: một gia đình Free tạo được video đầu tiên, dùng thử Lumi trên dữ liệu của bé, mua Premium thành công, tiếp tục việc đang làm và nhận được bản nháp kỷ niệm tiếp theo."

**H — "Điểm chạm — Premium nằm trong việc đang làm, không có "khu Premium" riêng"**
Sub: "Lối vào dùng đúng flow & màn hình use case hiện có (bản sao trên trang này, gốc không sửa). Không thêm màn lối vào mới. Không đặt vương miện/ổ khoá khắp app."

Table `959:13868` (verbatim):

| Vị trí | UI/UX | Khi nào giới thiệu Premium | Màn hiện có → paywall |
|---|---|---|---|
| Onboarding | Chọn bé, mục tiêu, mời người cùng chăm → hành động đầu tiên | Không chặn bằng paywall | — (không paywall) |
| Hôm nay | Việc cần làm, nhịp bé, một gợi ý kỷ niệm phù hợp | Khi có bản nháp/thành phẩm liên quan | — (không thêm màn) |
| Lumi | Gợi ý từ dữ liệu thật; số dư ở header | Khi sắp hết hoặc không đủ credit | CH20, CH21 → PV21 · CH24 → PV40 |
| Thư viện template | Thành phẩm thật, số ảnh, thời lượng | Khi chọn mẫu Premium ngoài trải nghiệm | MM04, MM10 → PV20 |
| Preview video | Ảnh của bé và kết quả trước; chỉnh rõ ràng | Trước khi xuất nếu thiếu quyền/lượt | MM05 → PV20 → … → MM07 |
| Gia đình | Quyền thành viên, người quản lý gói | Khi cần thêm chỗ chăm sóc | — (chưa có màn hiện có) |
| Dung lượng | Mức dùng, cách dọn, xuất dữ liệu | Khi gần đầy | 13c, 13d, 13f → PV22 → 13b |
| Tài khoản | Gói gia đình, hạn mức, gia hạn, mua thêm | Người dùng chủ động tìm | PV40 · cần lối vào trong 13a Tôi |

(Stale: this table still points at PV20/PV21/PV22 — paywall ids that do not exist on this page; the paywalls are now PW01–PW10. Gia đình says "chưa có màn hiện có" but E12 now covers it.)

**H — "Paywall Premium: một màn cho toàn bộ tính năng, mở đúng tính năng theo entry point"**
Sub: "Style premium tối. Headline ngắn + lý do theo entry; carousel 6 thẻ (thẻ đang cần ở giữa, hai bên nhỏ hơn, vuốt có hiệu ứng) — thẻ + chỉ báo luôn nằm trên footer. Mỗi thẻ: một demo kể chuyện + tiêu đề + một câu lợi ích + một dòng hạn mức. Bảng Free và Premium ở phần cuộn. Footer chỉ chọn Năm/Tháng + CTA; mua thêm 20/50 GB ở màn riêng PW10. Danh sách entry: PV00C."

Table `959:13917`:

| Paywall | Headline | Mở ở thẻ · entry |
|---|---|---|
| PW01 | Giữ tháng này của Teddy thành một câu chuyện | Video · E01, E03, E04 |
| PW02 | Một tấm thiệp xứng với 1 tháng của Teddy | Thiệp · E02 |
| PW03 | Tiếp tục hỏi Lumi về Teddy | Lumi · E05, E06 (không bán credit lẻ) |
| PW04 | Thêm chỗ cho những kỷ niệm tiếp theo | Dung lượng · E08–E11 |
| PW05 | Để bà ngoại cùng chăm Teddy | Người chăm sóc · E12 |
| PW06 | Những năm đầu của con, giữ trọn vẹn hơn | Video (tổng quan) · E13 · PW07 thành viên |

(E07 is not listed in this table — see PV00C.)

Three cards:

**Lộ trình triển khai**
- A · Chốt chính sách: quyền lợi, trial, quota, hạ gói, dữ liệu → không còn mâu thuẫn tài liệu (PV00).
- B · Đo chi phí: benchmark Lumi, video, storage → biết chi phí trung bình & người dùng nhiều.
- C · Hành trình Premium: Moments, Lumi, paywall, quản lý gói → chạy xuyên suốt trên máy thật.
- D · Thương mại: billing, ledger, Portal, restore/refund → đúng trong mọi trạng thái.
- E · Beta có đo lường với gia đình thật.
- F · Mở bán có kiểm soát: Free + Premium (+ dung lượng); chỉ mở thêm gói khi đủ dữ liệu chi phí.

**Kiểm thử bằng nhiệm vụ**
- 1. Tạo video đầy tháng bằng ảnh thật.
- 2. Dùng Lumi hỏi nhật ký và hiểu chi phí.
- 3. Nâng Premium rồi tiếp tục bản nháp.
- 4. Tìm xem gia đình còn bao nhiêu lượt.
- 5. Khôi phục gói sau khi đổi máy.
- 6. Hạ gói và tìm lại video cũ.
- Quan sát: kẹt ở đâu, có hiểu số tiền sẽ trả, làm được bằng một tay khi bế bé không.

**Chỉ số & engine mẫu**
- Hoàn thành tác vụ · thời gian thao tác · bỏ dở · nâng cấp · quay lại tạo thành phẩm tiếp theo · chi phí phục vụ / gia đình. Đăng ký nhiều nhưng tháng sau không dùng lại chưa phải thành công.
- Danh mục 48 mẫu; kiểm chứng engine bằng 6 mẫu đại diện: một ảnh · nhiều ảnh · thư dài · Then & Now hai ảnh · clip · tổng kết 12 tháng. Cấu hình có tên chưa phải mẫu đã sản xuất xong.
- Thay thế: trang Premium (P/L/M/F/B), v2.0 PR01–PR04, gói website V8 — Premium v2 là bản hiện hành.

### PV00C · Entry point Premium — danh sách đầy đủ — `990:15677`

Lead (Medium 16, ink-muted): "Mỗi entry point dùng màn hình use case hiện có. Khi chạm tính năng cần Premium → hiện gợi ý (Sheet hoặc Inline, cùng style Premium) → mở Paywall Premium với tính năng đó lên đầu và gắn nhãn “Bạn đang cần”. Mua xong quay lại đúng màn trước, giữ nguyên lựa chọn."

Table `990:15679` (verbatim):

| # | Nhóm | Entry point (màn hiện có) | Khi nào hiện gợi ý | Kiểu | Paywall mở ở | Sau khi mua |
|---|---|---|---|---|---|---|
| E01 | Moments · video | MM04 Mẫu video · thư viện — chạm mẫu “Cao cấp” | Chọn/dùng mẫu cao cấp khi gia đình Free | Sheet | PW01 · Video | MM07 Hoàn thiện video (mẫu + ảnh giữ nguyên) |
| E02 | Moments · thiệp | MM10 Thiệp cột mốc · chọn mẫu — mẫu “Cao cấp” | Chọn mẫu thiệp cao cấp | Sheet | PW02 · Thiệp | MM11 Thiệp · chỉnh sửa |
| E03 | Moments · lượt video | MM07 Hoàn thiện video — bấm “Tạo video” | Đã dùng 2 lượt xuất video trải nghiệm (Free). Premium hết 4 lượt/tháng: báo ngày cấp lại, không bán thêm lượt | Sheet | PW01 · Video | MM08 Đang tạo video |
| E04 | Moments · bản nháp | MM15 Tab Câu chuyện — “Làm tiếp” bản nháp | Bản nháp dùng mẫu cao cấp sau khi hết/hạ gói | Sheet | PW01 · Video | MM07 với bản nháp cũ |
| E05 | Lumi | CH20 Chat · Free gần hết · ước tính trước tác vụ | Tác vụ cần nhiều lượt hơn số còn lại | Có sẵn (Xem Premium) | PW03 · Lumi | CH23 Tiếp tục tác vụ |
| E06 | Lumi | CH21 Chat · Free hết lượt | Hết lượt tháng; câu hỏi được giữ | Có sẵn (Nâng cấp & tiếp tục) | PW03 · Lumi | CH23 Tiếp tục câu hỏi |
| E07 | Lumi · đã Premium | CH24 Chat · Premium hết lượt | Hết 200 credit tháng; không bán credit lẻ | Sheet thông tin (Đã hiểu · Xem mức dùng) | — (không paywall) | CH24, ghi trực tiếp vẫn dùng |
| E08 | Dung lượng · Premium | 13c Dung lượng · sắp đầy (≥ 80%) | ≥ 80% của 10 GB: thông báo trong màn, chưa bật paywall | Inline: “Thêm dung lượng” · “Quản lý ảnh/video” | PW10 · Mua thêm 20/50 GB | 13b Dung lượng |
| E09 | Dung lượng · Premium | 13d Dung lượng · đã đầy | Đầy 10 GB: giữ hàng đợi tải lên; xem/tải/xoá nội dung cũ vẫn được | Inline | PW10 · Mua thêm 20/50 GB | 13b, tự tải tiếp hàng đợi |
| E10 | Dung lượng · Free | 13f Kỷ niệm · hết dung lượng — chạm banner | Hết 1 GB của Free khi tải lên; mục mới giữ trên máy | Sheet | PW04 · Dung lượng | 13f, tự tải tiếp |
| E11 | Dung lượng · Free | AS18 Tự lưu kỷ niệm · không đủ dung lượng | Tự lưu dừng vì hết 1 GB | Sheet | PW04 · Dung lượng | AS12 Tự lưu kỷ niệm |
| E12 | Gia đình | 14a Gia đình — mời người chăm sóc | Đã dùng hết chỗ người chăm sóc | Sheet | PW05 · Người chăm sóc | 14a, gửi tiếp lời mời |
| E13 | Tài khoản | 13a Tôi — thẻ Premium dưới “Dung lượng” | Luôn có (chủ động tìm hiểu) | Inline | PW06 · Khám phá | 13a / Gói của gia đình |
| E14 | Mọi entry | Thành viên không phải người quản lý gói | Bất kỳ entry nào ở trên | Như entry gốc | PW07 · Nhờ người quản lý | Màn gốc |

Rules (bulleted, Medium 14):
- • Không vương miện/ổ khoá khắp app — chỉ nhãn “Cao cấp” sẵn có trên mẫu.
- • Gợi ý chỉ hiện khi người dùng chạm vào tính năng cần Premium (không tự bật lúc mở app).
- • Luôn có lựa chọn thay thế: mẫu miễn phí, ghi trực tiếp, dọn dung lượng, mời người thân (chỉ xem).
- • Health & ghi chăm sóc cơ bản không bao giờ bị chặn.

Notes: E06 says "Hết lượt tháng" for Free, but PV00 says Free Lumi credit is one-time (30, not monthly). E14 has no screen frame on this page beyond PW07.


## Section B — Moments & Lumi entry points (label `991:15657`)

All E-frames are copies of existing use-case screens ("bản sao …", original untouched) with the Premium suggestion added. Note ids name the original node.


### E01 · Mẫu video cao cấp · từ MM04 · Mẫu video — `991:15659`

375×812, radius 40, **drawn in Night care** (cloud `#0c1719`, surface `#15242a`, ink `#e6f2f1`, mint `#2cbfb3`). Copy of MM04 with a dim (`rgba(0,0,0,.5)`) and the "Gợi ý Premium · Sheet" instance.

Underlying MM04:
- Top: back (circle), search (circle).
- Title "Video kỷ niệm" (Bold 28); sub "Chọn một mẫu, Child Life lo phần còn lại."
- Card "Gợi ý cho Teddy": thumbnail (badge "Miễn phí", big "1", "Tháng đầu tiên của Teddy", "0:45 · 8 ảnh"); chip (cake) "Hợp với 1 tháng tuổi"; title "Tháng đầu tiên"; body "Ấm áp, nhẹ nhàng, có lời nhắn của ba mẹ ở cuối video."; button "Xem mẫu →".
- Category chips: "Tất cả" (selected, mint) · "7 ngày đầu" · "Tháng đầu tiên" · "100 ngày yêu thương" · "Nửa năm".
- Grid 3×2: "7 ngày đầu đời" 0:30 · 5 ảnh [Miễn phí] · "100 ngày yêu thương" 0:50 · 10 ảnh [★ Cao cấp] · "Nửa năm bên con" 0:45 · 8 ảnh [Miễn phí] · "Sinh nhật đầu tiên" 1:00 · 12 ảnh [★ Cao cấp] · "Khoảnh khắc nhỏ" 0:30 · 6 ảnh [Miễn phí] · "Ngủ ngoan nhé" 0:40 · 7 ảnh [★ Cao cấp]. Badge tokens: Miễn phí = white 92 % on `#1a1f26`; Cao cấp = sunshine `#ffd166` + star.
- StatusBar 9:41.

Sheet "Gợi ý Premium · Sheet" (top 531, gradient `#172624`→`#0d1414`, border `rgba(233,199,123,.3)`, top radius 28):
- grab handle
- Crest (gold `#e9c77b`): "◆" "CHILD LIFE PREMIUM" (Bold 9, tracking 1.62)
- Headline (Playfair Display 23, white 92 %): **Mẫu “100 ngày yêu thương” thuộc Premium**
- Body (13, white 62 %): "Xem trước miễn phí. Premium mở toàn bộ mẫu cao cấp và 4 lượt xuất video mỗi tháng."
- CTA (gold gradient `#f2d494`→`#d9a857`, ink `#1a1408`, glow): **Xem Premium**
- Text button (white 75 %): "Dùng mẫu miễn phí tương tự"

Note `991:15840` (yellow note `#fff5c7`, ink `#4d400d`, 12 px): "E01 · Chạm mẫu “Cao cấp” → Sheet → PW01 · bản sao 528:57407"

### E02 · Thiệp cao cấp · từ MM10 · Thiệp cột mốc — `991:15842`

Night care. Copy of MM10 + dim + "Gợi ý Premium · Sheet".

Underlying MM10:
- Back button. Title "Thiệp cột mốc" (Bold 26). Label "Chọn dịp".
- Occasion chips (wrap): "1 tháng" (selected, mint, inner pill "Gợi ý") · "7 ngày" · "100 ngày" · "Lần đầu cười" (heart) · "Lần đầu biết lẫy" (star) · "Biết bò" · "Bước đi đầu tiên" · "Sinh nhật 1 tuổi" (cake).
- Segmented: "Dọc 4:5" (selected) · "Vuông" · "Story 9:16".
- Card grid 2×2 (each card "1 tháng", "Teddy", "14.11.2026"): "Tròn trịa" [Miễn phí] · "Toàn ảnh" [Miễn phí] (date line "Teddy · 14.11.2026") · "Hồng phấn" [★ Cao cấp] · "Đêm sao" [★ Cao cấp] (dark navy `#1c2938`, gold `#fad173` title).

Sheet:
- "◆ CHILD LIFE PREMIUM"
- Headline: **Mẫu thiệp “Hồng phấn” thuộc Premium**
- Body: "Premium mở toàn bộ mẫu thiệp & video cao cấp. Ảnh và lời nhắn bạn đã chọn sẽ được giữ."
- CTA **Xem Premium**
- Text button "Chọn mẫu miễn phí"

Note `991:16002`: "E02 · Chạm thiệp “Cao cấp” → Sheet → PW02 · bản sao 530:9515"

Mock check: Teddy is "1 tháng" with card date 14.11.2026 while PV00 is dated 24/10/2026 — future date on a card is plausible only if date = birthday+1 month in the future (inconsistent with "now" in other frames; see questions).

### E03 · Hết lượt tạo video · từ MM07 · Hoàn thiện video — `991:16004`

Night care. Copy of MM07 + dim + sheet.

Underlying MM07:
- Back. Title "Hoàn thiện video" (Bold 24).
- Summary: thumbnail "1" / "Tháng đầu tiên"; chip (check) "Điền sẵn từ hồ sơ của bé"; rows "Bé — Teddy · 1 tháng", "Ngày mốc — 14.11.2026".
- Field "Tiêu đề" (edit icon): "Tháng đầu tiên của Teddy".
- Field "Lời nhắn cuối video": "Một tháng qua, con dạy ba mẹ biết yêu thương nhiều hơn."
- "6 ảnh · thứ tự xuất hiện" · right "Giữ và kéo để đổi"; strip of 6 photos + add (plus) tile.
- Group rows: (clock) "Nhạc nền" / "Ru con nhẹ nhàng" · action "Đổi"; (lock) "Ai xem được" / "Chỉ ba mẹ · lưu vào Kỷ niệm" ›.
- Bottom bar: primary Button h56 mint-deep **Tạo video**; caption "Mất khoảng 1–2 phút · bạn có thể rời màn hình".

Sheet:
- "◆ CHILD LIFE PREMIUM"
- Headline: **Bạn đã dùng 2 lượt xuất video trải nghiệm**
- Body: "Premium có 4 lượt xuất video mỗi tháng. Bản nháp này vẫn được giữ."
- CTA **Xem Premium**
- Text button "Lưu bản nháp, để sau"

Note `991:16138`: "E03 · Bấm “Tạo video” khi hết lượt → PW01 · bản sao 530:9248"

Not drawn: the Premium-member variant of E03 (PV00C: "Premium hết 4 lượt/tháng: báo ngày cấp lại, không bán thêm lượt") — no frame shows that sheet.

### E04 · Bản nháp mẫu cao cấp · từ MM15 · Tab Câu chuyện — `991:16140`

Night care. Copy of MM15 (Kỷ niệm → Câu chuyện) + dim + sheet (top 559).

Underlying MM15:
- Header: avatar "D" (card-peach), BabySwitcher "Teddy" ⌄, filter (sliders), add (+, mint).
- Large scroll tabs (Bold 30): "Ảnh" · "Album" · "Nhật ký" · **"Câu chuyện"** (active).
- Create tiles: (camera) "Video kỷ niệm" · (star) "Thiệp cột mốc".
- Section "Video kỷ niệm" · "2 video": "Tháng đầu tiên" ▶ 0:45 · "Chỉ ba mẹ"; "7 ngày đầu đời" ▶ 0:30 · "Chỉ ba mẹ"; dashed draft tile (edit) "Bản nháp" / "100 ngày · 3/10 ảnh" · link "Làm tiếp" (mint-text).
- Section "Thiệp cột mốc" · "3 thiệp": "1 tháng" Teddy; "7 ngày" "Teddy · "; "Lần đầu cười" "Teddy · " (date strings empty in the mock).
- Floating nav (Hôm nay · **Kỷ niệm** (selected pill) · Chăm sóc · Tiện ích grid).

Sheet:
- "◆ CHILD LIFE PREMIUM"
- Headline: **Bản nháp này dùng mẫu cao cấp**
- Body: "Bản nháp vẫn còn. Nâng cấp Premium để xuất, hoặc đổi sang mẫu cơ bản."
- CTA **Xem Premium**
- Text button "Đổi sang mẫu miễn phí"

Note `991:16329`: "E04 · “Làm tiếp” bản nháp sau khi hết/hạ gói → PW01 · bản sao 532:9453"

Mock check: the draft is "100 ngày · 3/10 ảnh" (a premium template "100 ngày yêu thương" in E01) — consistent. The draft has only 3/10 photos, so "xuất" would still be blocked by MM12 (not enough photos) after upgrading.

### E05 · Lumi gần hết lượt · từ CH20 · F — `991:16331`

**Light** (cloud `#f6fcfb`, ink `#173d44`) — unlike E01–E04. Straight copy of CH20 (no added sheet; the existing "Xem Premium" button is the entry).

- StatusBar 9:41.
- Chat/Đầu trang: back · "Chọn bé" chip (cake) "Teddy · 3 tuần" ⌄ · spacer · history (clock) · new (edit).
- Mức dùng row: Chat/Mức dùng pill (sunshine-soft) **"Còn 2/20 lượt · làm mới 01/11"** · right link "Chi tiết" (mint-text).
- Conversation:
  - outgoing attachment (Chat/Tệp đính kèm, paper thumbnail) label "Ảnh bảng note · chưa gửi"
  - warning bubble (sunshine-soft, w 300): **"Đọc ảnh này cần khoảng 3 lượt, bạn còn 2."** / "Bạn có thể nhập tay, đợi làm mới 01/11, hoặc nâng cấp để tiếp tục ngay. Ảnh chưa được gửi đi." · buttons **Xem Premium** (mint-deep) · "Nhập tay" (surface).
- Chat/Ô nhập: camera · placeholder "Hỏi, ghi nhanh hoặc gửi ảnh…" · send.

Note `991:16401`: "E05 · Màn hiện có, nút “Xem Premium” → PW03 · bản sao 616:9663"

**Contradiction:** the copy says "lượt", "Còn 2/20 lượt" and "làm mới 01/11" (the v2.0 model: Free 20 lượt/tháng, monthly refresh). PV00 now says Free = "30 credit trải nghiệm một lần" (no refresh) and Lumi units are "credit". The CH20 copy needs updating to the PV00 model (e.g. "Còn 2/30 credit", no refresh date) or PV00 is wrong.

### E06 · Lumi hết lượt · từ CH21 · F — `991:16403`

**Light.** Straight copy of CH21.

- StatusBar; Chat/Đầu trang "Teddy · 3 tuần".
- Mức dùng pill (error-soft, error ink `#a12b32`): **"Đã dùng hết 20/20 lượt · làm mới 01/11"** · "Chi tiết".
- Outgoing bubble (mint-deep): "Hôm nay con bú thế nào?"
- Card "Hết lượt" (surface, w 300): **"Bạn đã dùng hết lượt hỗ trợ AI tháng này."** / "Câu hỏi của bạn được giữ lại. Bạn vẫn ghi trực tiếp và xem nhật ký miễn phí." · buttons (surface-2, full width) "Mở nhật ký hôm nay" · "Ghi cữ bú" · primary (mint-deep) **"Nâng cấp & tiếp tục câu hỏi"**.
- Info strip (heart): "Hướng dẫn sức khoẻ thiết yếu vẫn mở, không cần lượt."
- Chat/Ô nhập state "Hết lượt" (surface-2, camera 40 % opacity): placeholder "Đã hết lượt AI tháng này".

Note `991:16462`: "E06 · Màn hiện có, “Nâng cấp & tiếp tục câu hỏi” → PW03 · bản sao 616:9773"

**Contradiction:** same as E05 — "20/20 lượt", "tháng này", "làm mới 01/11" vs PV00 Free = 30 one-time credits. Also the user-facing word "hỗ trợ AI" vs PV00 rule "Không nói token, model, API" (AI is allowed, but Lumi is the product name elsewhere).

### E07 · Premium hết credit · từ CH24 · F — `991:16464`

**Light** underlying CH24 + dim + **dark** Premium sheet (sheet keeps its own dark gradient in both modes).

Underlying CH24:
- Chat/Đầu trang "Teddy · 3 tuần"; Mức dùng pill (variant goi=Premium, mức=Hết, error-soft): **"Đã dùng hết lượt · làm mới 14/11"** · "Chi tiết".
- Card "Hết lượt": **"Hộ đã dùng hết lượt hỗ trợ AI kỳ này."** / "Làm mới 14/11. Bạn vẫn ghi trực tiếp, xem nhật ký, dùng mẫu Premium và quota xuất video riêng." · button "Xem chi tiết mức dùng".
- Ô nhập (Hết lượt): "Hết lượt AI · vẫn ghi trực tiếp được".

Sheet (info, no paywall):
- "◆ CHILD LIFE PREMIUM"
- Headline: **Lumi đã dùng hết 200 credit tháng này**
- Body: "Credit mới được cấp ngày 14/11. Trong lúc chờ, bạn vẫn ghi trực tiếp và xem nhật ký bình thường."
- Gold CTA (layer still named "CTA · Xem Premium"): **Đã hiểu**
- Text link: "Xem mức dùng của gia đình"

Note `991:16524`: "E07 · Đã có Premium → mua thêm, không mở paywall · bản sao 616:9936"

**Contradictions:** note says "mua thêm" but PV00/PV00C say credit is never sold ("Không bán credit lẻ") and the sheet offers no purchase. Underlying card says "Hộ" (household) and "quota" (jargon) — elsewhere the copy says "gia đình". Mixed units in one screen: "lượt" (pill/card) vs "credit" (sheet). Renewal 14/11 implies the cycle anchors on the purchase day (14th), consistent with PV00 "cấp lại theo ngày gia hạn".

## Section C — Dung lượng, Gia đình, Tài khoản (label `991:15658`)

### E08 · Dung lượng sắp đầy · từ 13c Dung lượng · sắp đầy — `991:16526`

**Light.** Copy of 13c with an inline dark Premium card inserted at the bottom ("Thông báo dung lượng" `999:16873`). Frame taller than 812 (TabDock at y 917).

Underlying 13c:
- Back + "Tôi". Title "Dung lượng" (Text/large-title 32).
- Big number (Numbers/numeral-xl 52) "8,2 GB" + "/ 10 GB".
- Bar: mint-deep segment + peach segment.
- Caption: "Dùng chung cho tất cả các bé · ảnh ba và mẹ tải lên đều tính vào đây"
- Warn card (sunshine-soft, alert icon, on-warm ink): "Sắp đầy · 82%" / "Video chiếm nhiều chỗ nhất. Xoá bớt video dài hoặc liên hệ quản trị để mở rộng."
- "Theo bé": Teddy "312 ảnh · 24 video" 6,1 GB ›; Na "96 ảnh · 6 video" 2,1 GB ›.
- "Theo loại": Video "Xem video lớn nhất" 5,7 GB ›; Ảnh 2,3 GB ›; "Câu chuyện & ghi chú" 40 MB ›.

Inserted inline card (gradient `#172926`→`#292414`, gold border 40 %, radius 20):
- "◆ CHILD LIFE PREMIUM"
- Title (Bold 16): **Nhà mình sắp hết chỗ lưu kỷ niệm**
- Body: "Đã dùng 82% của 10 GB. Thêm 20 GB hoặc 50 GB, dùng chung cho cả gia đình."
- Actions: gold pill **Thêm dung lượng** · text "Quản lý ảnh/video"

TabDock: old NavBar variant (Today · Memories · Family · **Tôi** active with avatar "M") + QuickLogButton (+). (Old 4-tab dock with Family, not the v1.0-improvement Hôm nay · Kỷ niệm · Chăm sóc · Tiện ích dock used in E04.)

**Contradictions:** the warn card still says "liên hệ quản trị để mở rộng" (pre-Premium copy) right above a card that sells +20/+50 GB. Mock numbers: 6,1 + 2,1 = 8,2 GB ✓; 5,7 + 2,3 + 0,04 ≈ 8,04 ≠ 8,2 GB (by type doesn't sum). 8,2/10 = 82 % ✓.

### E09 · Dung lượng đã đầy · từ 13d Dung lượng · đã đầy — `991:16648`

**Light.** Copy of 13d + inserted inline Premium card.

Underlying 13d:
- Back + "Tôi". "Dung lượng". Big "10 GB" (error red) "/ 10 GB". Bar error + peach (full).
- Caption: "Dùng chung cho tất cả các bé · ảnh ba và mẹ tải lên đều tính vào đây"
- Full card (error-soft, cloud-off icon): "Đã dùng hết 10 GB" / "Tạm dừng tải ảnh, video. 3 mục mới được giữ trên máy, không mất. Ghi chép chăm sóc vẫn lưu bình thường."
- Theo bé: Teddy "312 ảnh · 24 video" 7,4 GB; Na "96 ảnh · 6 video" 2,6 GB.
- Theo loại: Video "Xem video lớn nhất" 7,0 GB; Ảnh 2,8 GB; "Câu chuyện & ghi chú" 40 MB.

Inline card:
- "◆ CHILD LIFE PREMIUM"
- **Đã dùng hết 10 GB**
- "Ảnh, video mới đang chờ trong hàng đợi và sẽ tự tải tiếp sau khi thêm dung lượng. Vẫn xem, tải và xoá nội dung cũ bình thường."
- **Thêm dung lượng** · "Quản lý ảnh/video"

TabDock: old 4-tab NavBar, Tôi active.

Mock check: per-baby counts identical to E08 (312 ảnh · 24 video / 96 · 6) but sizes grew (6,1→7,4; 2,1→2,6) — counts should change too. 7,4+2,6 = 10 ✓; 7,0+2,8+0,04 = 9,84 ≠ 10.

### E10 · Tải lên khi hết dung lượng · từ 13f Kỷ niệm · hết dung lượng — `991:16770`

**Light** underlying 13f + dim + dark sheet. (design_context was >50 KB; text extracted from the saved output.)

Underlying 13f (Kỷ niệm · Nhật ký):
- Header: BabySwitcher "Teddy · 3 tuần"; actions View / Add. Title "Nhật ký".
- UploadPill (error state, "!" badge on a media tile): **"Hết dung lượng 10 GB"** / progress / "3 mục giữ trên máy · chạm để xem".
- Week "Tuần thứ 3" · "1 – 8 tháng 10 · 13 ảnh, 3 video":
  - Mẹ · "Hôm nay · 9:20" — "Ngủ trưa ngon lành sau giờ tắm." — react "Bà nội, Ông ngoại thương"
  - Ba · "Hôm qua · 19:05" — "Lần đầu nắm chặt ngón tay ba." — video 0:42 — "2 lượt thương"
  - Mẹ · "Thứ Ba, 6 thg 10" — "Bà nội sang thăm, mang theo đôi tất len tự đan." (2 photos)
  - Mẹ · "Thứ Hai, 5 thg 10" — "Đêm qua con ngủ một mạch 4 tiếng. Mẹ dậy mà vẫn thấy lạ." (note)
  - Mẹ · "Thứ Hai, 5 thg 10" — milestone "★ Lần đầu cười · 5 thg 10" — grid (videos 0:24, 0:12; favourite; private)
- Week "Tuần thứ 2" · "24 – 30 tháng 9 · 6 ảnh": Ba · "Chủ nhật, 20 thg 9" — "★ Ngày đầu về nhà · 20 thg 9" — grid.
- Floating memory tabs: **Nhật ký** · Ảnh · Album · Câu chuyện.
- TabDock (old NavBar; Kỷ niệm active; avatar M).

Sheet:
- "◆ CHILD LIFE PREMIUM"
- Headline: **Hết 1 GB của gói Free**
- Body: "3 ảnh, video mới vẫn an toàn trên máy. Premium có 10 GB cho cả nhà, tự tải tiếp sau khi nâng cấp."
- CTA **Xem Premium**
- Text button "Quản lý ảnh/video"

**Contradictions:** the underlying pill says "Hết dung lượng 10 GB" while the sheet (a Free family) says 1 GB — the copied 13f was not adjusted. Mock dates: "1 – 8 tháng 10" is 8 days for one week; "20 thg 9" entry sits under "24 – 30 tháng 9"; "Thứ Ba, 6 thg 10" 2026 is a Tuesday ✓, "Thứ Hai, 5 thg 10" ✓, "Chủ nhật, 20 thg 9" 2026 ✓. A 3-week-old baby has "Tuần thứ 3" yet milestones "Lần đầu cười" and "Ngày đầu về nhà" 20/9 → born ≤ 20/9, i.e. ~5 weeks by 24/10.

### E11 · Tự lưu không đủ dung lượng · từ AS18 · Không đủ dung lượng — `991:17105`

**Light** underlying AS18 + dim + dark sheet (top 559).

Underlying AS18:
- Back. Title "Kiểm tra trước khi tải" (Bold 26). Strip of 6 thumbnails + "+9".
- Group: "Nguồn" — "Thư viện ảnh trên máy · 15 mục (13 ảnh, 2 video)"; "Bé" — "Teddy" ›; "Lưu vào" — "Dòng thời gian, theo ngày chụp · Album: không" ›.
- "Ai thấy": card selected (mint-soft, 2 px mint-deep border, lock) "Chỉ ba mẹ" / "Mặc định cho Tự lưu"; card (family) "Gia đình" / "Cả nhà cùng xem".
- Row "Báo cho gia đình" — "Tắt · không gửi thông báo" + Toggle (off).
- Banner (error-soft, alert): "Không đủ dung lượng: 15 mục cần 186 MB, gia đình còn 40 MB. Bạn có thể tải trước 3 ảnh vừa đủ, phần còn lại vẫn giữ trên máy." · link "Xem dung lượng".
- Card "Dung lượng sau khi tải" — "9,96 / 10 GB" + red progress.
- Bottom bar: primary **Tải trước 3 ảnh vừa đủ**; caption "Mục chưa tải vẫn ở trong máy và trong danh sách gợi ý."

Sheet:
- "◆ CHILD LIFE PREMIUM"
- Headline: **Tự lưu kỷ niệm đang tạm dừng**
- Body: "Gói Free đã dùng hết 1 GB. Premium có 10 GB cho cả nhà, Tự lưu chạy tiếp ngay."
- CTA **Xem Premium**
- Text button "Quản lý ảnh/video"

**Contradictions:** underlying says "9,96 / 10 GB" and "còn 40 MB" (a 10 GB family) while the sheet says a Free family used all of 1 GB — same un-adjusted copy issue as E10. PV00C says "Tự lưu dừng vì hết 1 GB", but AS18 is a pre-upload check ("Kiểm tra trước khi tải"), not "paused"; headline "đang tạm dừng" doesn't match the screen underneath.

### E12 · Hết chỗ người chăm sóc · từ 14a Gia đình · Light — `991:17198`

**Light** underlying 14a + dim + dark sheet (top 530).

Underlying 14a:
- Header: BabySwitcher "Teddy · 3 tuần" · Night care toggle (sleep icon).
- Eyebrow "Những người cùng chăm Teddy"; title "Gia đình" (large-title).
- Members card (shadow-card):
  - M · "Mai" · "Mẹ · Cùng nuôi" · badge "Bạn"
  - M · "Minh" · "Ba · Cùng nuôi" ›
  - L · "Cô Lan" · "Bảo mẫu · Người chăm sóc" ›
  - H · "Bà nội Hoa" · "Bà · Người thân" ›
- SectionHeader "Đang chờ nhận lời (1)"; Pending card: "?" · "ba.ngoai@gmail.com" · "Bà ngoại · hết hạn 15 thg 10" · "Gửi lại".
- Primary Button (+) **Mời người cùng chăm**.
- TabDock (old NavBar, **Gia đình** active).

Sheet:
- "◆ CHILD LIFE PREMIUM"
- Headline: **Gia đình đã dùng 3/3 chỗ người chăm sóc**
- Body: "Premium có 6 chỗ người chăm sóc. Hoặc mời bà làm người thân — xem album không giới hạn."
- CTA **Xem Premium**
- Text button "Mời làm người thân"

Frame annotation (stale, copied from a Hôm nay frame): "Thẻ lớn = vừa ghi vừa xem: chạm thẻ → mở sheet ghi mục đó (1 chạm); dòng dưới là lần cuối (bao lâu trước · chi tiết · ai ghi). Ngủ khi timer chạy → CareTile Tone=Active hiện thời gian đang chạy. Tăng trưởng: hàng riêng, + mở màn nhập số đo. “Lịch sử” → dòng thời gian."

Seat arithmetic implied: Mai + Minh (Cùng nuôi) + Cô Lan (Người chăm sóc) = 3; Bà nội Hoa (Người thân) not counted (PV00 rule). So **co-parents count as caregiver seats** ("Người chăm sóc" seat = any member with write access). The pending invite to Bà ngoại has already expired ("hết hạn 15 thg 10" < 24/10) yet shows "Gửi lại" — does an expired/pending invite hold a seat? Not specified.

### E13 · Tôi · chủ động · từ 13a Tôi · Ba/Mẹ — `991:17327`

**Light.** 13a with the "Gợi ý Premium · Inline" instance inserted under the Dung lượng card.

- Title "Tôi". Profile: avatar "M" (peach-soft), "Mai", "mai.nguyen@gmail.com", "Mẹ · chủ hồ sơ của Teddy, Na" ›.
- Storage card (shadow-tile): "Dung lượng" · "3,2 GB / 10 GB"; bar; legend "● Teddy 2,4 GB" "● Na 0,8 GB"; "Dùng chung cho tất cả các bé của bạn".
- **Inline Premium card** (gradient `#172926`→`#292414`, gold border): "◆ CHILD LIFE PREMIUM" / **Child Life Premium** / "4 video mỗi tháng, 200 credit Lumi, mẫu cao cấp và 10 GB cho cả nhà · từ 59.000đ/tháng." / gold pill **Xem Premium ›**.
- Group: (cake) "Hồ sơ các bé" — "Teddy, Na" — "2" ›; (today) "Thông báo" — "Bật" ›; (globe) "Giao diện" — "Tự động" ›.
- Group: (link) "Đã chia sẻ ra ngoài" — "2 liên kết đang mở" ›; (lock) "Tài khoản & đăng nhập" — "Email, Apple, đổi máy" ›; (mail) "Trợ giúp & liên hệ" ›.
- "Đăng xuất" (error).
- TabDock (old NavBar, Tôi active).

**Contradictions:** a Free family (shown the upsell) has "3,2 GB / 10 GB" — Free is 1 GB. "từ 59.000đ/tháng" — the yearly plan is 599.000đ/năm ≈ 49.917đ/tháng, so "từ" should be the lower effective monthly or say "59.000đ/tháng". No row for "Gói của gia đình" (PV00C E13 return target "13a / Gói của gia đình"; PV00B "PV40 · cần lối vào trong 13a Tôi") — for a Premium family this card must become the entry to PV40.

#### Section C notes (verbatim)

- `991:16646` "E08 · Inline thay thẻ “Liên hệ quản trị” → PW04 · bản sao 194:267"
- `991:16768` "E09 · Inline → PW04 · bản sao 194:377"
- `991:17103` "E10 · Chạm banner hết dung lượng → PW04 · bản sao 195:177"
- `991:17196` "E11 · → PW04 · bản sao 483:54740"
- `991:17325` "E12 · Mời người chăm sóc khi hết chỗ → PW05 · bản sao 116:11226"
- `991:17451` "E13 · Inline dưới thẻ Dung lượng → PW06 · bản sao 194:78"

**Conflict:** notes E08/E09 send the Premium family to **PW04** (the Free→Premium paywall, "Dung lượng" card) while PV00C sends them to **PW10** (mua thêm 20/50 GB). PV00C is newer in intent (PW10 exists only for add-ons); E08's note also says the inline card *replaces* "Liên hệ quản trị", but the frame still shows the old warn card above it.

## Section D — Paywall Premium (label `988:15538`)

### Component · Premium · Thẻ tính năng — `1019:17008`

Component set, prop `Tính năng` = Video | Thiệp | Lumi | Nhịp | Dung lượng | Người chăm (6 variants). Card w 300, radius 26, gradient `#293d38`→`#1a2624`, border gold `rgba(233,199,123,.55)` 1.2 px, gold glow + deep shadow. Structure: **Demo** panel (276×156, black 28 %, radius 18) + **Text** block: eyebrow (gold Bold 9, tracking 1.44) · title (Playfair Display 17) · benefit (Medium 12, white 66 %) · limit line (gold SemiBold 11).

| Variant | Demo content (verbatim) | Eyebrow | Title | Benefit | Limit line |
|---|---|---|---|---|---|
| Video | 3 scenes: "Một tháng trước, nhà mình đón con." (Playfair italic on cream) · photo with chip "Ngày đầu về nhà" · end scene "Một tháng bên Teddy."; timeline "▸ 0:12 / 0:35" · "♪ bật tiếng" | VIDEO KỶ NIỆM | Những ảnh rời, thành câu chuyện | Chọn ảnh, thêm lời nhắn, giữ lại những tháng ngày bên con. | 4 video mỗi tháng |
| Thiệp | 3 prints: minimal portrait "Teddy" / "100 NGÀY · 25.11.2026"; playful info "Chào con yêu!" / "Teddy" / "100 ngày" / "NGÀY SINH" "17.08.2026" / "CÂN NẶNG · CHIỀU DÀI" "3,2 kg · 50 cm" / "Cảm ơn con đã đến bên ba mẹ"; timeless collage "Teddy" / "25.11.2026"; style chips "Tối giản" · "Đáng yêu" · "Cổ điển" | MẪU CAO CẤP | Thiệp dành riêng cho con | Thêm tên, lời thương và đổi phong cách chỉ với một chạm. | Toàn bộ mẫu cao cấp · Việt – Anh |
| Lumi | user bubble (gold) "Hôm nay con bú thế nào?"; answer "Đến 14:20: 3 cữ bú bình · 390 ml" / "Cữ gần nhất 13:10 · 120 ml (Ba ghi)" / "Theo nhật ký đã ghi · Xem nguồn" | LUMI MỖI THÁNG | Hỏi một câu, Lumi tóm tắt giúp | Hỏi về cữ bú, giấc ngủ, hoặc ghi nhanh bằng một câu nói. | 200 credit mỗi tháng |
| Nhịp | "Tuần này (13–19/10), giấc đêm đã ghi trung bình 9 giờ 10 — dài hơn 25 phút so với tuần trước (6–12/10)."; bars "8g45 Tuần trước" / "9g10 Tuần này"; "Theo nhật ký đã ghi · Xem nguồn" | HIỂU NHỊP CON | Lumi nhìn lại tuần giúp bạn | Một câu nhận xét rõ ràng, từ nhật ký cả nhà đã ghi. | Gồm trong 200 credit mỗi tháng |
| Dung lượng | 5 photo thumbs; rows "✓ Đã tự lưu 12 ảnh mới hôm nay · 09:41", "↑ 3 video đang tải lên · không cần chờ · 68%" | DUNG LƯỢNG | Ảnh mới cứ thế được lưu | Tự lưu kỷ niệm chạy đều mỗi ngày, không phải xoá bớt cuối tháng. | 10 GB cho cả nhà · cần thêm thì mua 20/50 GB riêng |
| Người chăm | rows "Mẹ · 09:10 · Đã ghi cữ bú 120 ml", "Ba · 10:30 · Bắt đầu giấc ngủ", "Bà ngoại · Đã xem cập nhật · 10:32"; footnote "Cùng chăm đã có ở Free; Premium tăng số người tham gia." | CẢ NHÀ CÙNG CHĂM | Cả nhà cùng chăm, không hỏi lại | Ai ghi gì, mọi người đều thấy ngay trong nhật ký chung. | Thêm chỗ cho tối đa 6 người cùng chăm (Free: 3) |

Checks: 8g45 → 9g10 = +25 min ✓. "13–19/10" 2026 is Tue–Mon (a Mon–Sun week would be 12–18/10). Thiệp demo: born 17.08.2026 + 100 days = 25.11.2026 ✓, but E02/E03 make Teddy 1 month on 14.11.2026 (born 14.10.2026) — two different birthdays for Teddy on one page. "Bà ngoại · Đã xem cập nhật" in the Người chăm demo shows a viewer (relative), who per PV00 does not take a caregiver seat — the demo blurs "người chăm" vs "người thân". The Dung lượng card markets "Tự lưu" (an AS beta feature) as a Premium benefit.

### Component · Premium · Carousel — `1020:17765`

Too large for design_context → metadata. Component set, prop `Đang xem` = Video | Thiệp | Lumi | Nhịp | Dung lượng | Người chăm (`1020:16865`, `1020:17015`, `1020:17165`, `1020:17315`, `1020:17465`, `1020:17615`), each 375 wide (h 285.86; 298.86 for Dung lượng / Người chăm). Inside: six "Card · …" instances of Thẻ tính năng — the current one 270 wide centred (x 52.5), the others 228 wide (≈ 0.84 scale) lined up to the right; "dots" row (82×6) with the active dot a 22×6 pill and the rest 6×6. Copy = the Thẻ tính năng variants above. (Only the Video variant's metadata was opened; the other five follow the same layout per their sizes.)

### Component · Premium · Chọn gói — `1020:17820`

Bottom footer (375, top radius 28, gradient `rgba(18,28,26,.98)`→`#0a1212`, gold border 25 %). Prop `Kỳ` = Năm (default) | Tháng.

- Two period tiles (radius 18): selected = gold 12 % fill + 1.5 px `#e9c77b` border, gold label; unselected = white 5 % + white 12 % border.
  - "Theo năm" + badge **−15%** · "599.000đ" (Playfair 20) · "≈ 49.900đ/tháng"
  - "Theo tháng" · "59.000đ" · "mỗi tháng"
- CTA (gold gradient): Năm → **Đăng ký Premium · 599.000đ/năm**; Tháng → **Đăng ký Premium · 59.000đ/tháng**
- Legal (10 px, white 45 %): Năm → "Thanh toán 599.000đ hôm nay · tự gia hạn mỗi năm · huỷ trong App Store bất cứ lúc nào · Điều khoản · Quyền riêng tư"; Tháng → "Thanh toán 59.000đ hôm nay · tự gia hạn mỗi tháng · huỷ trong App Store bất cứ lúc nào · Điều khoản · Quyền riêng tư"

Checks: 59.000 × 12 = 708.000; 599.000 is −15,4 % ✓; 599.000/12 = 49.917 → "≈ 49.900đ" (rounded down; "≈ 49.917" or "≈ 50.000" would be more honest). Legal line names **App Store only** — no Google Play variant, no free-trial wording (PV00B task "Chốt chính sách: … trial" — no trial is drawn anywhere).

### Component · Gợi ý Premium — `990:15676`

Prop `Kiểu` = Sheet (default, `990:15657`) | Inline (`990:15668`). Used by E01–E04, E07, E10–E12 (Sheet) and E08, E09, E13 (Inline, E08/E09 as detached "Thông báo dung lượng" copies).

- **Sheet** (375, top radius 28, gradient `#172624`→`#0d1414`, gold border 30 %, pb 34): grab handle · Crest "◆ CHILD LIFE PREMIUM" · headline (Playfair 23) default "Mẫu “100 ngày yêu thương” thuộc Premium" · body (13, white 62 %) default "Xem trước miễn phí. Dùng mẫu và xuất video khi nhà mình có Premium." · full-width gold CTA **Xem Premium** · secondary text (SemiBold 14, white 75 %) default "Dùng mẫu miễn phí tương tự".
- **Inline** (343, radius 20, gradient `#172926`→`#292414`, gold border 40 %): Crest · title (Bold 16) default "Thêm chỗ cho những kỷ niệm tiếp theo" · body (12) default "Premium có dung lượng lớn hơn cho cả nhà." · small gold pill **Xem Premium ›**.

Note the component default body differs from the E01 instance ("Xem trước miễn phí. Premium mở toàn bộ mẫu cao cấp và 4 lượt xuất video mỗi tháng.") — instances override text. No variant for: a non-manager member (PW07 path), offline, or Light theme (always dark, also on Light screens).

### PW01 · Paywall Premium · Video — `1021:17681`

375×812, dark premium style (output >60 KB; text extracted from the saved design_context, layout from metadata). Two background glows ("Glow · mint" top-left, "Glow · gold" top-right). Layers, top to bottom:

- **Top** (fixed, 88): close (×) 34 px circle at left · text button **Khôi phục** at right. StatusBar.
- **Scroll** (content height 1226):
  - Head (y 92): Crest "◆ CHILD LIFE PREMIUM" · headline (Playfair, 2 lines) **Giữ tháng này của Teddy thành một câu chuyện** · reason line (layer "Lý do · chỉ khi đến từ entry point"): "Mẫu “100 ngày yêu thương” và 10 ảnh bạn chọn vẫn được giữ."
  - Carousel instance "Carousel · Video" (y 207): Video card centred, then Thiệp, Lumi, Nhịp, Dung lượng, Người chăm; dots. (Card copy = Thẻ tính năng table.)
  - Compare (y 505): "Free và Premium"; table "Bảng so sánh" (335 wide, 3 columns Quyền lợi | Free | Premium):

    | Quyền lợi | Free | Premium |
    |---|---|---|
    | Credit Lumi | 30 credit trải nghiệm một lần | 200 credit/tháng |
    | Dung lượng | 1 GB | 10 GB · mua thêm khi cần |
    | Xuất video + tag **Bạn đang cần** | 2 lượt trải nghiệm một lần | 4 lượt/tháng |
    | Mẫu thiệp & video | Mẫu cơ bản · xem trước mẫu cao cấp | Toàn bộ mẫu cao cấp |
    | Người chăm sóc | 3 người | 6 người |
    | Người thân xem album | Không giới hạn | Không giới hạn |

  - "Cam kết" chips: "Huỷ bất cứ lúc nào" · "Không bán credit lẻ" · "Kỷ niệm luôn là của bạn".
- **Premium · Chọn gói** footer pinned at y 584 (h 228), Kỳ = Năm: "Theo năm −15% 599.000đ ≈ 49.900đ/tháng" (selected) · "Theo tháng 59.000đ mỗi tháng" · CTA **Đăng ký Premium · 599.000đ/năm** · "Thanh toán 599.000đ hôm nay · tự gia hạn mỗi năm · huỷ trong App Store bất cứ lúc nào · Điều khoản · Quyền riêng tư".

Carousel ends at y ≈ 493 < footer 584, so card + dots sit above the footer as PV00B requires. "Bạn đang cần" marks the entry's row (PV00C). The in-paywall table drops PV00's "Chăm sóc, tăng trưởng, sức khoẻ: Đầy đủ", price rows and the add-on row, and shortens "Không giới hạn theo gói" → "Không giới hạn", "10 GB · mua thêm 20 GB / 50 GB" → "10 GB · mua thêm khi cần".

### PW02 · Paywall Premium · Thiệp cao cấp — `1021:17915`

Same shell as PW01 (output >100 KB; strings extracted and diffed against PW01). Differences only:
- Headline: **Thiệp xứng với tháng đầu của Teddy**
- Reason: "Mẫu “Hồng phấn” và ảnh bạn chọn vẫn được giữ."
- Carousel `Đang xem=Thiệp` (Thiệp card centred).
- "Bạn đang cần" on row **Mẫu thiệp & video**.
- Footer Kỳ = Năm, CTA "Đăng ký Premium · 599.000đ/năm".

PV00B lists PW02's headline as "Một tấm thiệp xứng với 1 tháng của Teddy" — the frame says "Thiệp xứng với tháng đầu của Teddy".

### PW03 · Paywall Premium · Lumi — `1021:18298`

Differences from PW01:
- Headline: **Tiếp tục hỏi Lumi về Teddy**
- Reason: "“Hôm nay con bú thế nào?” đang chờ · đã dùng hết 30 credit trải nghiệm."
- Carousel `Đang xem=Lumi`; layout classes show neighbour cards at **opacity 35 %** and cards two away at **opacity 0** (only centre ± 1 visible).
- "Bạn đang cần" on row **Credit Lumi**.
- Footer Năm.

This paywall uses the PV00 model (30 one-time credits), contradicting E05/E06 underneath ("20/20 lượt · làm mới 01/11").

### PW04 · Paywall Premium · Dung lượng (Free 1 GB) — `1021:18681`

- Headline: **Thêm chỗ cho kỷ niệm tiếp theo** (PV00B: "Thêm chỗ cho những kỷ niệm tiếp theo"; Gợi ý Inline default uses the PV00B wording)
- Reason: "Đã dùng 1 / 1 GB · 3 mục mới vẫn an toàn trên máy."
- Carousel `Đang xem=Dung lượng`; "Bạn đang cần" on row **Dung lượng**. Footer Năm.

### PW05 · Paywall Premium · Người chăm sóc — `1021:19064`

- Headline: **Để bà ngoại cùng chăm Teddy**
- Reason: "Gia đình đã dùng 3 / 3 chỗ người chăm sóc của gói Free."
- Carousel `Đang xem=Người chăm`; "Bạn đang cần" on row **Người chăm sóc**. Footer Năm.

### PW06 · Paywall Premium · Chủ động khám phá — `1021:19447`

- Headline: **Những năm đầu của con, giữ trọn vẹn hơn**
- **No reason line**; carousel default (Video centred); **no "Bạn đang cần"** tag. Footer Năm.

Note `1025:5306` (Note · PW06), verbatim: "Mở chủ động (Tôi › Premium / Gói của gia đình › Xem các gói): KHÔNG có dòng lý do, headline chung, carousel mở ở thẻ Video, không gắn “Bạn đang cần” trong bảng."

### PW07 · Paywall Premium · Thành viên không quản lý gói — `1021:19679`

- Headline: **Giữ tháng này của Teddy thành một câu chuyện** (same as PW01 — PW07 is shown for a video entry)
- Reason: "Mẫu này có trong Premium — gói dùng chung của cả nhà."
- Carousel Video; "Bạn đang cần" on **Xuất video**.
- Footer replaced (no period picker, no price): avatar "D" · **Gói của nhà do Duy quản lý** · "Chỉ Duy có thể nâng cấp cho cả nhà" · gold CTA **Nhờ Duy nâng cấp** (layer "CTA · Nhờ Duy nâng cấp") · privacy line "Duy chỉ nhận lời nhắn ngắn, không thấy bản nháp hay câu hỏi của bạn."
- Top bar still shows "Khôi phục" (a member restoring purchases that are not theirs — unclear).

Not drawn: what Duy receives (push/in-app/Zalo?), the confirmation after "Nhờ Duy nâng cấp", rate limiting, and the member's view after Duy upgrades. In 14a (E12) the current user is Mai (Mẹ) and the other parent is "Minh"; "Duy" appears only as avatar "D" (E04) and here — the manager's identity differs between frames.

### PW08 · Paywall Premium · toàn trang (tham khảo cuộn) — `1021:19904`

Full-length reference of the PW06 state (background gradient `#13211f`→`#0e1716`, footer at y ≈ 925 so the whole scroll is visible): headline "Những năm đầu của con, giữ trọn vẹn hơn", no reason, no "Bạn đang cần", carousel Video, same comparison table, footer Năm. Only difference from PW06: the Cam kết row shows **two chips** — "Huỷ bất cứ lúc nào" · "Kỷ niệm luôn là của bạn" ("Không bán credit lẻ" absent).

### PW10 · Mua thêm dung lượng (gia đình đang có Premium) — `998:18711`

Dark (gradient `#13211f`→`#0e1716`, mint and gold glows). (There is no PW09 on the page.)
- Top: close (×) · "Khôi phục".
- Crest "◆ CHILD LIFE PREMIUM"; headline (Playfair 30): **Thêm chỗ cho những ngày con lớn lên.**
- Card "Đang dùng": "Đã dùng" · **9,6 / 10 GB** · gold bar · "12 ảnh mới đang chờ — tự tải tiếp ngay sau khi thêm dung lượng."
- Option (selected, gold border): **Thêm 20 GB** · "Tổng 30 GB cho cả nhà" · **399.000đ/năm** · "hoặc 39.000đ/tháng"
- Option: **Thêm 50 GB** · "Tổng 60 GB cho cả nhà" · **799.000đ/năm** · "hoặc 79.000đ/tháng"
- Footnote: "Dùng chung cho cả gia đình · gia hạn cùng kỳ với Premium · huỷ bất cứ lúc nào."
- Bottom: CTA **Thêm 20 GB · 399.000đ/năm** · text "Quản lý ảnh/video".

Gaps: no month/year picker although monthly prices are shown; "gia hạn cùng kỳ với Premium" implies the add-on period follows the Premium period (so a monthly-Premium family would pay 39.000đ/tháng, and the yearly price shown first is wrong for them); no legal/auto-renew line (Chọn gói has one); can a family hold both add-ons (+70 GB)? can they switch 20→50? No "Bạn đang cần".

Note `1025:5304` (Note · PW01), verbatim: "Dòng lý do (vd “Mẫu … và 10 ảnh bạn chọn vẫn được giữ.”) CHỈ hiện khi người dùng đến từ một entry point cần Premium (E01–E13) — nói đúng việc đang dở và cam kết giữ nguyên. Headline + thẻ mở đầu cũng theo entry."

## Section E — Thanh toán (label `967:14614`; owner: in-app purchase comes later)

### PV30 · Thanh toán · bảng xác nhận App Store — `967:14615`

**Light.** Background screen (dimmed 45 %): video card "Gửi con, hai tháng" (300 h, photo + gradient) and line **Giữ tháng này của Teddy thành một câu chuyện.** — a Light, pre-PW01 paywall background (not the dark PW01).

System sheet mock "Sheet · App Store (hệ thống)" (top 482, white, top radius 24):
- "App Store" · close (×)
- App row (mint tile, heart): **Child Life Premium · Gia đình** / "Gói thuê bao · tự gia hạn hằng năm"
- Rows: "Giá — 599.000đ / năm" · "Bắt đầu — Hôm nay" · "Tài khoản — duy•••@icloud.com"
- (eye icon) "Nhấn hai lần nút sườn để xác nhận"

Product display name "Child Life Premium · Gia đình" (store SKU name). Buyer is Duy (Apple ID duy•••@icloud.com) → Duy becomes "người quản lý gói" (consistent with PW07). Only the iOS sheet is drawn; no Google Play billing sheet.

### PV31 · Thanh toán · đang xác nhận — `967:14659`

**Light.** Same dimmed background as PV30 ("Gửi con, hai tháng" / "Giữ tháng này của Teddy thành một câu chuyện."). Bottom sheet (white, top 633): spinner (ellipse arc 44) · **Đang kích hoạt Premium cho gia đình…** · "Đang xác minh giao dịch với App Store. Bản nháp “Gửi con, hai tháng” vẫn được giữ."

No cancel / timeout / "Ask to Buy" (pending approval) / network-lost state drawn. Draft title "Gửi con, hai tháng" vs E03's "Tháng đầu tiên của Teddy" — different mock project.

### PV32 · Thanh toán · chưa hoàn tất — `967:14675`

**Light.** Same dimmed background. Sheet (top 456):
- alert icon on sunshine-soft circle
- **Chưa kích hoạt được Premium**
- "Kết nối bị gián đoạn khi xác nhận. Nếu App Store đã ghi nhận thanh toán, Premium sẽ tự kích hoạt khi có mạng — bạn không cần mua lại."
- Primary **Thử lại** · secondary (surface-2, h52) **Khôi phục giao dịch**
- "Bản nháp của bạn vẫn còn nguyên."

On-canvas annotation card "Cancelled variant" (top 110): **Nếu người dùng tự huỷ ở App Store:** / "Đóng bảng, quay về paywall, không hiện lỗi."

Implies: pending/unfinished transactions are re-checked on reconnect (StoreKit transaction listener) and entitlement is server-granted when the receipt arrives.

### PV33 · Khôi phục gói sau khi đổi máy — `967:14708`

**Light**, full screen.
- Header: back · **Khôi phục giao dịch**
- Card "Found": (check) **Đã tìm thấy gói của bạn**; rows "Gói — Premium · theo năm" · "Gia hạn — 24/10/2027" · "Gắn với — Gia đình của Teddy"; primary **Xong**.
- Info "Other": **Gói đang gắn với gia đình khác?** / "Một Apple ID chỉ gắn với một gia đình. Liên hệ hỗ trợ để chuyển — không tự chuyển quyền lợi."
- Info "None": **Không tìm thấy giao dịch?** / "Kiểm tra đúng Apple ID đã mua; gói có thể do người khác trong nhà quản lý."

Implies a binding **store account (Apple ID / original transaction) → one family**, immutable from the client; transfer only via support (admin action). Renewal 24/10/2027 = purchase 24/10/2026 (PV00 date) yearly ✓. But E07 says credits renew "14/11" — a different anchor for the same family (or a monthly family).

#### Section E notes (verbatim)

- `967:14657` "PV30 · Bảng hệ thống iOS (minh hoạ). Tổng tiền và chu kỳ đã nêu rõ ở paywall trước khi tới đây."
- `967:14673` "PV31 · Backend xác minh receipt/transaction rồi mới cấp quyền lợi. Không cho bấm mua lần hai."
- `967:14706` "PV32 · Lỗi/mất kết nối: không hù doạ, nói rõ có bị trừ tiền không, có đường khôi phục."
- `967:14747` "PV33 · Từ Tài khoản › Gói của gia đình, hoặc link dưới paywall. Ba kết quả: tìm thấy, gắn gia đình khác, không tìm thấy."

Section E is drawn on a Light, older-style paywall background ("Gửi con, hai tháng"), not on the dark PW01–PW08. Success state (after PV31) is not drawn here — PV40B (Section F) is the post-purchase screen.

## Section F — Quản lý gói (label `968:14661`)

### PV40 · Gói của gia đình · Plus (người quản lý) — `968:14662`

**Light.** (Layer name still says "Plus" — a removed tier; content says Premium.)
- Header: back · **Gói của gia đình**
- Plan card (mint-soft): **Premium** + tag "Đang dùng" · "Người quản lý: Duy (bạn) · dùng chung cho 5 thành viên"
- Hạn mức card (shadow-card):
  - "Lumi" — "còn 132 / 200 credit" (mint bar ≈ 66 %) — "Cấp lại 24/11 · mua thêm: 0"
  - "Video kỷ niệm" — "còn 3 / 4 lượt" (sunshine bar 75 %) — "Cấp lại 24/11"
  - "Dung lượng" — "6,2 / 10 GB" (sleep-accent bar ≈ 25 %) — "Ảnh 10,9 GB · video 1,5 GB"
- Key–value group: "Bổ sung tiếp — 24/11/2026 · mỗi tháng theo ngày đăng ký" · "Gia hạn — 24/10/2027 · 599.000đ/năm" · "Nếu huỷ — Premium còn tới 24/10/2027; sau đó về Free. Kỷ niệm, nhật ký, video đã xuất vẫn xem và tải được."
- Action group: (spark) "Mua thêm dung lượng" › (layer "Row · Mua thêm credit Lumi") · (clock) "Lịch sử sử dụng" / "Theo người và tác vụ" › · (link) "Quản lý gia hạn" / "Mở App Store" › · "Khôi phục giao dịch" ›

**Inconsistencies:** "mua thêm: 0" and the row layer "Mua thêm credit Lumi" are leftovers of credit top-ups that PV00 forbids. Storage breakdown "Ảnh 10,9 GB · video 1,5 GB" = 12,4 GB > "6,2 / 10 GB", and the bar is ≈ 25 % not 62 %. Yearly plan, but quotas refill monthly on the subscription day (24th) — confirms "cycle" = monthly even for yearly billing. "5 thành viên" vs seat cap 6 (does it include relatives?). No add-on row is shown when an add-on is active.

### PV40B · Gói của gia đình · Free — `968:14762`

**Light.**
- Header: back · **Gói của gia đình**
- Plan card (surface): **Free** + tag "Đang dùng" (surface-2, muted) · "Người quản lý: Duy (bạn)"
- Hạn mức card:
  - "Lumi · trải nghiệm" — "còn 2 / 30 credit" (sunshine bar) — "Credit trải nghiệm dùng một lần, không cấp lại"
  - "Video · trải nghiệm" — "đã dùng 2 / 2" (full bar) — "Đã xuất “Hai tháng của Teddy”"
  - "Dung lượng" — "0,9 / 1 GB" (≈ 92 % bar)
- Upsell (mint-soft): **Mỗi tháng, thêm một câu chuyện của Teddy** / "Premium cấp lại Lumi và lượt video mỗi tháng, mở bộ mẫu Premium và thêm dung lượng cho cả nhà." / primary **Xem các gói** (→ PW06 per Note · PW06)
- Group: (spark) "Mua thêm dung lượng" › (layer "Row · Mua thêm credit Lumi") · "Khôi phục giao dịch" ›

**Contradictions:** a Free family is offered "Mua thêm dung lượng" though PV00 says add-ons are "chỉ Premium". A Free family already has a "Người quản lý" (Duy) — so the manager role exists before any purchase (= family owner?). This screen follows PV00 (30 one-time credits) unlike E05/E06. "Đã xuất “Hai tháng của Teddy”" lists only one of the two exports.

### PV41 · Lịch sử sử dụng (không lộ nội dung) — `968:14830`

**Light.**
- Header: back · **Lịch sử sử dụng**
- Filter chips: "Tất cả" (selected, mint-soft) · "Lumi" · "Video" · "Cấp & hoàn"
- Month label "Tháng 10"
- Ledger list (avatar initial · title · "who · when" · amount):
  - M · **Lumi · Nhìn lại 7 ngày** · "Mai · 24/10 21:14" · **−5**
  - D · **Video · Gửi con, hai tháng** · "Duy · 24/10 20:02" · **−1 lượt**
  - H · **Cấp hạn mức tháng** · "Hệ thống · 24/10" · **+200** (mint-text)
  - H · **Hoàn credit · lỗi kết nối** · "Hệ thống · 22/10" · **+2** (mint-text)
  - B · **Lumi · Tóm tắt hôm nay** · "Bà ngoại · 21/10" · **−1**
- Privacy note (lock): "Chỉ hiện người, loại tác vụ và số lượng. Nội dung câu hỏi và trả lời không hiển thị ở đây."

Implies a family-level ledger with entry kinds: `lumi_debit` (task label, member, amount), `video_debit` (project title, member, 1 lượt), `cycle_grant` (system, +200), `refund` (system, reason "lỗi kết nối", +n). Units mixed in one list (credit vs "lượt"). Video entries show the project title ("Gửi con, hai tháng") — a child-content string inside a billing/usage view (fine for family members, but must never reach the commercial dashboard per PV00 footer). "Bà ngoại" spends Lumi credits → either Bà ngoại is a caregiver (seat) or relatives can use Lumi; PV00 says relatives only view Kỷ niệm. The grant on 24/10 (+200) is the purchase day; "Video · 24/10 20:02" debit is before or after the grant? (no time on the grant). No pagination / older months / export.

### PV42 · Huỷ gia hạn · điều gì sẽ xảy ra — `968:14894`

**Light.**
- Header: back · **Huỷ gia hạn Premium**
- Lead (Bold 22): **Premium vẫn dùng được tới hết 24/10/2027.**
- Section "Sau ngày đó, nhà mình về Free"
- Rows:
  - (check, mint-soft) **Giữ nguyên** — "Kỷ niệm, nhật ký, 14 video đã xuất, thành viên"
  - (cloud-off, sunshine-soft) **Dung lượng 6,2 GB > 1 GB** — "Không xoá; tạm dừng tải ảnh mới cho tới khi dọn hoặc nâng lại" (layer name still "Dung lượng 12,4 GB > 5 GB")
  - (family) **5 người chăm sóc > 3 chỗ** — "Không xoá ai; bạn chọn 3 người giữ quyền ghi"
  - (star) **2 bản nháp dùng mẫu Premium** — "Giữ bản nháp; xuất cần Premium hoặc đổi mẫu cơ bản" (layer "2 bản nháp dùng mẫu Plus")
- Bottom bar: primary **Giữ Premium** · secondary **Tiếp tục huỷ trong App Store**

Stale layer names reveal the previous model (Free 5 GB, "Plus" tier). PV40 says "dùng chung cho 5 thành viên"; here "5 người chăm sóc" — so all 5 members are counted as caregiver seats (no relatives?), consistent with E12's counting of co-parents as seats. "14 video đã xuất" for a family that bought Premium on 24/10/2026 is impossible at 4/month + 2 trial within the mock timeline. The "chọn 3 người giữ quyền ghi" picker is not drawn (when? at expiry? before?).

### PV43 · Đã về Free · trạng thái cụ thể (không xoá âm thầm) — `969:14706`

**Light.**
- Header: back · **Gói của gia đình**
- Banner (surface-2, alert): "Nhà mình đã về Free từ 24/10/2027. Không có gì bị xoá."
- State cards:
  - (cloud-off) **Vượt dung lượng · 6,2 / 1 GB** — "Mọi ảnh, video vẫn xem và tải về được. Tạm dừng tải ảnh mới cho tới khi dưới 5 GB." — links "Dọn bớt" · "Xuất dữ liệu" · "Nâng lại Premium" (layer "State · Vượt dung lượng · 12,4 / 5 GB")
  - (family) **Vượt chỗ người chăm sóc · 5 / 3** — "Chọn 3 người giữ quyền ghi chăm sóc. Hai người còn lại tạm chỉ xem, không bị xoá." — link "Chọn người"
  - (star) **2 bản nháp dùng mẫu Premium** — "Bản nháp được giữ. Xuất cần Premium, hoặc đổi sang mẫu cơ bản." — link "Mở bản nháp" (layer "… mẫu Plus")
  - (camera) **14 video đã xuất** — "Vẫn ở Kỷ niệm › Kỷ vật, xem và tải về như cũ." — link "Xem video"

**Bug:** "Tạm dừng tải ảnh mới cho tới khi dưới **5 GB**" — the Free limit is now 1 GB (title says "6,2 / 1 GB"); leftover from the 5 GB model. "Kỷ niệm › Kỷ vật" names a Kỷ niệm sub-tab ("Kỷ vật") that doesn't match the tabs drawn in E04/E10 (Ảnh · Album · Nhật ký · Câu chuyện). Who sees this screen (manager only, or every member)? What a "tạm chỉ xem" caregiver sees is not drawn.

### PV44 · Chọn người giữ quyền ghi (3 chỗ) — `969:14774`

**Light.** Background "Gói của gia đình" header, dim 45 %, sheet "Sheet · Chọn người" (top 291):
- **Ai giữ quyền ghi chăm sóc?**
- "Free có 3 chỗ. Người không chọn vẫn xem được mọi thứ và quay lại khi nhà mình nâng gói."
- Rows (avatar · name · role · checkbox):
  - D · **Duy (bạn)** · "Ba · người quản lý" · ☑
  - M · **Mai** · "Mẹ" · ☑
  - C · **Cô Hạnh** · "Bảo mẫu" · ☑
  - Ô · **Ông nội** · "Người chăm sóc" · ☐
  - B · **Bà nội** · "Người chăm sóc" · ☐
- Primary **Lưu · 3/3**

Seat model confirmed: parents + nanny + grandparents with write access all count; manager is pre-checked (can the manager be unchecked? not shown). Family cast differs from E12 (Ba = Minh, Bảo mẫu = Cô Lan, Bà nội Hoa = Người thân) — here Ba = Duy, Bảo mẫu = Cô Hạnh, Bà nội = Người chăm sóc. What happens if the manager never chooses (default rule)? Not drawn.

### PV45 · Gói của gia đình · thành viên xem — `969:14841`

**Light.** Non-manager member's view.
- Header: back · **Gói của gia đình**
- Plan card (mint-soft): **Premium** + tag "Cả nhà dùng chung" · "Quản lý bởi Duy"
- Hạn mức: "Lumi — còn 132 / 200 credit — Cấp lại 24/11" · "Video kỷ niệm — còn 3 / 4 lượt — Cấp lại 24/11" · "Dung lượng — 6,2 / 10 GB" (no breakdown)
- Info (lock): "Chỉ Duy có thể đổi, gia hạn hoặc huỷ gói. Bạn vẫn dùng mọi quyền lợi Premium."
- Row (clock): "Lịch sử sử dụng của tôi" ›

Members see the family's shared quotas but only **their own** usage history (manager sees everyone's in PV41). No renewal date / price / cancel info shown to members; no "Khôi phục giao dịch". No relative (viewer) variant; no member-on-Free variant (would show PW07's "Nhờ Duy nâng cấp").

#### Section F notes (verbatim)

- `968:14760` "PV40 · Trả lời 6 câu: gói nào · ai quản lý · còn bao nhiêu · khi nào bổ sung · khi nào gia hạn · nếu huỷ thì sao. Ba thanh riêng, không gộp thành một đồng hồ credit. Số liệu minh hoạ."
- `968:14828` "PV40B · Trạng thái Free: rõ cái gì là trải nghiệm một lần. “Xem các gói” → PV23."
- `968:14892` "PV41 · Ledger hiển thị: giữ chỗ → trừ khi thành công → hoàn khi lỗi. Không có nội dung chat/sức khoẻ."
- `968:14959` "PV42 · Nói trước hậu quả cụ thể theo dữ liệu của gia đình. Huỷ thực hiện trong App Store (iOS không cho huỷ trong app)."
- `969:14772` "PV43 · Mỗi trạng thái có hành động cụ thể. Không xoá thành viên/kỷ niệm âm thầm. “Chọn người” → PV44."
- `969:14839` "PV44 · Người quản lý chủ động chọn; không có lựa chọn mặc định âm thầm. Người không được chọn nhận thông báo nhẹ “tạm chỉ xem”."
- `969:14897` "PV45 · Thành viên thấy hạn mức chung, không thấy giá, phương thức thanh toán hay lịch sử của người khác."

Stale: PV40B note targets **PV23** (old v2.0 paywall id; does not exist on this page) — Note · PV06 says "Gói của gia đình › Xem các gói" opens PW06. PV41 note mentions a "giữ chỗ" (hold) state, but the drawn ledger has no pending/held rows. PV44 "không có lựa chọn mặc định âm thầm" conflicts with PV44's own pre-checked boxes (Duy, Mai, Cô Hạnh) — unless those were the manager's choice.

## Section G — Portal web 1440 (label `970:14739`)

### PT01 · Portal · Tổng quan thương mại — `970:14740`

Desktop 1440. Sidebar (ink `#173d44`, 240): "Child Life Portal" · nav **Tổng quan thương mại** (active, white 14 %) · "Gia đình" · "Cấu hình quyền lợi" · "Job video & hoàn lượt" · "Giao dịch" · "Audit log".

Main:
- Head: **Tổng quan thương mại** / "Tháng 10/2026 · dữ liệu minh hoạ · không chứa nội dung chat hay dữ liệu sức khoẻ" · range chips "7 ngày" · **"30 ngày"** (selected) · "12 tháng".
- KPI tiles (6): "Gia đình Free — 12.480 — +8% so với tháng trước" · "Gia đình Premium — 1.126 — Chuyển đổi 8,3%" (layer "KPI · Gia đình Plus") · "Mua thêm dung lượng — 86 — +20 GB: 61 · +50 GB: 25" · "Doanh thu gộp — {…} ₫ — Theo giá store" · "Tiền thực nhận — {…} ₫ — Sau phí App Store/Play" · "Chi phí phục vụ / Premium — {…} ₫ — AI + render + storage" (layer "… / Plus").
- Panel **Doanh thu, thực nhận và chi phí phục vụ**: grouped bars T5–T10 (mint-deep / mint / sunshine), legend "Doanh thu gộp" · "Thực nhận" · "Chi phí phục vụ".
- Panel **Chi phí phục vụ theo gói (trung bình / gia đình / tháng)** (560 wide): table Gói | Lumi | Render | Storage | Tổng — rows "Free", "Premium", "Premium · p95" (all `{…}`), "Dung lượng thêm" (— — — —); footnote "p95 = gia đình dùng nhiều nhất · đo ở chặng B trước khi chốt hạn mức".
- Panel **Hạn mức & mua thêm**: "Gia đình Premium hết credit Lumi trước kỳ — 14%" · "Gia đình Premium dùng hết lượt video — 22%" · "Mua thêm dung lượng / gia đình ≥ 80% — 31%" (layer "Mua thêm credit / gia đình hết credit") · "Free hết credit trải nghiệm → mở paywall Lumi — 46%".
- Panel **Gia hạn, huỷ & hoàn tiền**: "Đến kỳ gia hạn — 312" · "Gia hạn thành công — 271 · 87%" · "Huỷ gia hạn — 29" · "Lỗi thanh toán (đang retry của store) — 12" · "Hoàn tiền — 4".
- Panel **Cần xử lý** (sunshine-soft): "Job video lỗi (24 giờ) — 7" · "Lượt/credit đang giữ cần hoàn — 34" · "Giao dịch chưa khớp quyền lợi — 2" · link "Mở Job video & hoàn lượt ›".

Checks: 1.126 / (12.480 + 1.126) = 8,28 % ✓; 61 + 25 = 86 ✓; 271 / 312 = 86,9 % ✓; 271 + 29 + 12 = 312 ✓. Revenue figures are placeholders `{…} ₫`. "Sau phí App Store/Play" → Google Play is expected although no Android purchase UI is drawn. KPI "Gia đình Premium" counts families, not subscriptions (a family could hold two subscriptions?).

### PT02 · Portal · Gia đình · kiểm tra quyền lợi & điều chỉnh — `971:14739`

Sidebar as PT01 with **Gia đình** active.

- Head: **Gia đình fam_8X2Q…** / "Chỉ dữ liệu thương mại & quyền lợi · không có nội dung kỷ niệm, chat, sức khoẻ" · search "Tìm theo mã gia đình / mã giao dịch".
- Panel **Quyền lợi hiện hành**: tags "Premium · năm" (layer "Tag · Plus · năm") · "entitlements v2.0-draft" · "Khớp giao dịch ✓"; rows "Nguồn — App Store · txn 2000000…4417" · "Người quản lý — member_01 (ẩn danh)" · "Kỳ hiện tại — 24/10/2026 – 24/10/2027" · "Cấp lại hạn mức — 24/11/2026" · "Lumi — 132 / 200 · mua thêm 0" · "Video — 3 / 4 lượt" · "Dung lượng — 6,2 / 10 GB" · "Người chăm sóc — 3 / 5".
- Panel **Ledger (30 ngày)**: table Thời gian | Tác vụ | Thay đổi | Trạng thái | Idempotency:

  | Thời gian | Tác vụ | Thay đổi | Trạng thái | Idempotency |
  |---|---|---|---|---|
  | 24/10 21:14 | lumi.review7d | −5 | Đã trừ | rq_91af… |
  | 24/10 20:02 | video.export | −1 lượt | Đã trừ | job_77c2… |
  | 24/10 00:00 | cycle.grant | +200 | Cấp | cyc_1024 |
  | 22/10 08:31 | lumi.quickAnswer | +2 | Hoàn (lỗi) | rq_55d0… |
  | 22/10 08:30 | lumi.quickAnswer | −2 | Giữ chỗ | rq_55d0… |

- Panel **Điều chỉnh thủ công**: "Loại — Cộng credit Lumi" · "Số lượng — +10" · "Lý do (bắt buộc)" "Bù cho job video lỗi job_6a1e… (ticket #4821)" · "Cần người thứ hai duyệt nếu > 50 credit hoặc đổi gói." · primary **Gửi điều chỉnh**.
- Panel **Audit**: Thời gian | Người thao tác | Hành động — "24/10 09:12 · ops.lan · Xem quyền lợi"; "21/10 16:40 · ops.minh · +2 credit · lỗi kết nối · duyệt bởi ops.lan"; "18/10 10:05 · system · Khớp giao dịch App Store".

**Inconsistencies:** tag "entitlements **v2.0-draft**" vs PV00 `version: "2.0-launch"`. "Người chăm sóc 3 / 5" — Premium cap is 6 (PV00) and PV42 says the family has 5 caregivers (5/6 expected). "mua thêm 0" (no credit sales). Ledger shows refund +2 as an automatic "Hoàn (lỗi)" on 22/10 08:31 while Audit shows a *manual* "+2 credit · lỗi kết nối" by ops.minh on 21/10 16:40 — one day *before* the failure; the PV41 member view attributes it to "Hệ thống · 22/10". "Khớp giao dịch App Store" on 18/10 precedes the 24/10 purchase (PV33/PV40). `cycle.grant` at 24/10 00:00 for a purchase made on 24/10 (store time vs local midnight?). The adjustment compensates a *video* job with *Lumi credits* — cross-unit compensation is undefined. A manual "Cộng credit Lumi" contradicts nothing in PV00 (grants ≠ sales) but needs a reason code list.

### PT03 · Portal · Cấu hình quyền lợi (có version) — `971:14886`

Sidebar with **Cấu hình quyền lợi** active.

- Head: **Cấu hình quyền lợi** / "Một nguồn cho app, backend, website · thay đổi tạo version mới, cần 2 người duyệt" · tags "Đang chạy: v1.3" · "Bản nháp: v2.0-draft" (sunshine-soft).
- Panel **Gói & hạn mức · v2.0-launch** (layer "… · v2.0-draft"):

  | Khoá | Free | Premium |
  |---|---|---|
  | lumiCredits | 30 (một lần) | 200 / tháng |
  | videoExports | 2 (một lần) | 4 / tháng |
  | premiumTemplates | false | true |
  | storageGB | 1 | 10 (+20 / +50 add-on) |
  | caregiverSeats | 3 | 6 |
  | price.vn | 0 | 59.000 / 599.000 |
  | price.intl | 0 | $5,99 / $49,99 |
  | creditTopUps | false | false |

- Panel **Chi phí tác vụ (credit)**: Tác vụ | Credit — `lumi.quickAnswer` 1 · `lumi.voiceLog` 1 · `lumi.writeCaption` 2 · `lumi.review7d` 5; footnote "Chi phí thật (₫) ghi riêng theo tác vụ, không hiển thị cho người dùng."
- Panel **Thay đổi so với v1.3**: "+ Free/Premium thay cho Free/Plus/Pro · + Credit Lumi đi theo gói, không bán lẻ · + Add-on dung lượng 20/50 GB · + caregiverSeats 3/6 · + videoExports theo kỳ" · primary **Gửi duyệt v2.0** · secondary **So sánh JSON**.

**Inconsistencies:** version label triple — panel title "v2.0-launch", tag "Bản nháp: v2.0-draft", PV00 `"2.0-launch"`, PT02 family tag "v2.0-draft" (a family can't be on a draft that isn't running; "Đang chạy: v1.3"). Add-on prices (39.000/399.000, 79.000/799.000, $1,99/$19,99, $3,99/$39,99) are in PV00 config but **not in this table**. PT02 ledger debits `lumi.quickAnswer` **−2** while the cost table says **1**. No task for "read a photo" (E05 "Đọc ảnh này cần khoảng 3 lượt") and no `video.export` row (video counts in lượt, not credits). No effective date / rollout % / which families stay on old version (grandfathering).

### PT04 · Portal · Job video lỗi & lượt cần hoàn — `971:14984`

Sidebar with **Job video & hoàn lượt** active.

- Head: **Job video & hoàn lượt** / "Retry an toàn, không xuất trùng · lượt chỉ trừ khi thành công" · filter chips "Lỗi · 7" (error-soft) · "Đang giữ lượt · 34" (sunshine-soft) · "Đang chạy · 12".
- KPIs: "Thời gian dựng p50 — 38 giây" · "Thời gian dựng p95 — 2 phút 10" · "Tỉ lệ lỗi 24h — 0,9% — 7 / 780 job" · "Chi phí render trung bình — {…} ₫ — / video".
- Panel **Job cần xử lý**: Job | Gia đình | Mẫu | Lỗi | Lần thử | Lượt/credit | Hành động

  | Job | Gia đình | Mẫu | Lỗi | Lần thử | Lượt/credit | Hành động |
  |---|---|---|---|---|---|---|
  | job_6a1e… | fam_8X2Q… | Thư gửi con | Render timeout | 3/3 | 1 lượt · giữ | Hoàn · Retry |
  | job_51b0… | fam_K2ZP… | Lớn thêm rồi | Ảnh nguồn bị xoá | 1/3 | 1 lượt · giữ | Hoàn |
  | job_49aa… | fam_77QD… | Then & Now | Font thiếu glyph | 2/3 | 1 lượt thử · giữ | Retry |
  | lumi rq_55d0… | fam_8X2Q… | — | Provider 503 | 1/1 | 2 credit · đã hoàn | — |

  Footnote: "Hoàn tự động sau 3 lần thử thất bại; hoàn thủ công cần lý do và ghi audit. Retry dùng cùng idempotency key nên không xuất trùng hay trừ lặp."

Checks: 7 / 780 = 0,90 % ✓. **Inconsistencies:** job_6a1e… has failed 3/3 yet is still "giữ" (footnote says auto-refund after 3 failures). PT02 compensates the same job_6a1e… with "+10 credit Lumi" instead of refunding the video lượt. "Video kỷ niệm" in E03 promises "Mất khoảng 1–2 phút" while p95 = 2 phút 10. "1 lượt thử" = a Free trial export (distinct balance). PV00 says video "1 lượt = 1 lần xuất thành công" but PT02/PT04 show lượt held ("giữ") before success — consistent with the hold→debit→refund model (PV00 states it only for Lumi). Rows for "Ảnh nguồn bị xoá" offer only Hoàn (no Retry) — implies a non-retryable error class.


## What changed versus the v2.0 Premium design (`30-personalization-premium.md`)

| Screen here | Earlier counterpart (file 30 / 33 / 36) | What changed |
|---|---|---|
| PV00 | PR01 paywall + annotations `595:7034…`; Q-071; website Free/Plus/Pro (33/36) | **Plans:** two benefit groups A/B and states Free/Beta/Pending/Premium/Expired → **Free + Premium only** (no Beta tier, no Plus/Pro; PT03 "Free/Premium thay cho Free/Plus/Pro"). **Prices:** `{giá từ cửa hàng}` placeholders (PR01), US$4.99/39.99 (exploration), 79.000đ/179.000đ Plus/Pro (website) → **59.000đ/tháng · 599.000đ/năm; $5,99 · $49,99**. **Credits:** AI 1/baby/day + video fixture 1/5 (P-152), assistant pool Free 20/month · Premium 200/period (P-159), website 30/300/1.000 → **Free 30 credit một lần (không cấp lại), Premium 200/tháng; no credit top-ups**. **Video:** Free 1 / Premium 5 per period → **Free 2 one-time trial exports, Premium 4/month**. **Storage:** 10 GB for everyone (05 §13) → **Free 1 GB, Premium 10 GB, add-ons +20/+50 GB (Premium only)**. **Caregiver seats:** not limited before → **Free 3, Premium 6; relatives unlimited, not counted**. **Naming:** "Gói của hộ" / "hộ" → "Gói của gia đình" / "gia đình" (E07 still says "Hộ"); "Cao cấp" kept as template badge. |
| PV00B | v2.0 navigation graph; PR01 entry A/B | Paywall is one screen with a 6-card carousel opened on the entry's card, not two benefit groups; Premium lives inside use-case screens ("không có khu Premium riêng" — conflicts with D-089's "Tính năng & Premium" hub). Adds roadmap A–F and task-based testing. |
| PV00C | v2.0 entry points H01, PS01F, MO02, PR04 | 14 entry points E01–E14; personalisation entries (H01 "Hỗ trợ phù hợp…", PS01F) are **gone** — no personalisation/Nhịp group is sold any more. |
| E01, E02 | MO02 "Mở với Premium" gate (Light) | Gate is now the dark "Gợi ý Premium · Sheet" over the real MM04/MM10 copy, with a free-alternative button. |
| E03, E04 | MO04 quota card "Lượt xuất video kỳ này 3 / 5" | Free trial 2 exports, Premium 4/month; D-081 removed the quota card from the video screen; draft-with-premium-template after downgrade now explicit. |
| E05–E07 | CH20/CH21/CH24 (file 31) | Copied unchanged — still "20 lượt", monthly refresh — so they contradict PV00 (30 one-time credits). E07 new info sheet "Lumi đã dùng hết 200 credit tháng này". |
| E08–E11 | 13c/13d/13f, AS18 (files 05, 27) | 13c "liên hệ quản trị để mở rộng" is replaced (per note) by an inline Premium card selling +20/+50 GB; Free limit 1 GB in sheets. |
| E12 | 14a Gia đình (file 01/03) | New seat limit 3/3 with "mời làm người thân" alternative. |
| E13 | 13a Tôi | Inline Premium card under Dung lượng ("từ 59.000đ/tháng"). |
| PW01–PW08 | PR01 (Light, two groups A/B, "Bạn đang xem"), exploration PW01/PW02 | Dark premium style; carousel of 6 feature cards; comparison table Free vs Premium; tag renamed "Bạn đang cần"; real prices; −15 % yearly badge; Terms/Privacy and auto-renew line now present (gap noted in file 30); "Cam kết" chips. PW07 non-manager variant is new. |
| PW10 | — | New: storage add-on purchase. |
| PV30–PV33 | PR02 + component Mua/Trạng thái (Pending/Success/Error/Restore) | Split into App Store sheet, verifying, failed/interrupted (+ cancelled rule), restore with 3 outcomes (found / bound to another family / not found). Success screen not redrawn. |
| PV40, PV40B, PV45 | PR03 "Gói của hộ" (Free/Beta/Pending/Premium/Expired cards) | Renamed "Gói của gia đình"; three separate quota bars; manager vs member views; Beta and Pending cards gone; purchaser "Mẹ" → manager "Duy (Ba)". |
| PV41 | MO04 job list, QuotaLedger | New member-facing usage ledger "theo người và tác vụ". |
| PV42–PV44 | PR04 "Hết gói · lịch sử vẫn giữ" | Concrete downgrade consequences (storage over limit, seats over limit, premium drafts) and the seat picker. |
| PT01–PT04 | Portal B05/B06, PN01–PN04 (file 30 part C; 18) | New commercial portal: overview KPIs, family lookup with ledger + manual adjustment + audit, versioned entitlements config, video job/refund queue. Sidebar differs from the existing admin sidebar (`315:47173`). |

## Entitlement / policy matrix (plan × capability × limit)

Source PV00 table and config block (authoritative), cross-checked with PW comparison table, PT03 and Thẻ tính năng.

| Capability | Config key | Free | Premium | Storage add-on | Notes / evidence |
|---|---|---|---|---|---|
| Credit Lumi | `lumiCredits` (`lumiCreditsOneTime` / `lumiCreditsPerCycle`) | **30 credit, one time, never refilled** (PV40B "không cấp lại") | **200 credit / month**, refilled on the subscription day, no carry-over | — | Family pool; hold → debit on success → refund on error/cancel; idempotency key. Costs (PT03): quickAnswer 1, voiceLog 1, writeCaption 2, review7d 5. No top-ups (`creditTopUps: false`). |
| Xuất video | `videoExports` (`videoExportsTrial` / `videoExportsPerCycle`) | **2 exports, one time** | **4 / month**, refilled on the subscription day, not sold | — | 1 lượt = 1 successful export; template choice, edits, preview free (on-device preview); re-export of the same version free. |
| Mẫu thiệp & video cao cấp | `premiumTemplates` | basic templates; **preview** premium | all premium templates | — | Drafts using a premium template survive downgrade; export needs Premium or switch to a basic template. |
| Dung lượng | `storageBytes` / `storageGB` | **1 GB** | **10 GB** | **+20 GB** (39.000đ/tháng · 399.000đ/năm · $1,99/$19,99) or **+50 GB** (79.000đ/tháng · 799.000đ/năm · $3,99/$39,99) — Premium only | Over limit: new uploads blocked/queued on device; view, download, delete, export always allowed. Add-on lasts to end of paid period; "gia hạn cùng kỳ với Premium" (PW10). |
| Người chăm sóc (write access) | `caregiverSeats` | **3** | **6** | — | Seats = members with write access (parents count: E12, PV44). Over limit after downgrade: nobody removed; manager picks who keeps write, others become view-only. |
| Người thân xem album | — | unlimited | unlimited | — | Relatives (view Kỷ niệm only) never take a seat. |
| Chăm sóc, tăng trưởng, sức khoẻ, ghi chép | — | full | full | — | Never blocked ("Health & ghi chăm sóc cơ bản không bao giờ bị chặn"); essential health guidance needs no credit (E06). |
| Giá VN | `price.vn` | 0đ | 59.000đ/tháng · 599.000đ/năm (−15 %, ≈ 49.900đ/tháng) | see above | Store-billed (App Store drawn; Play implied by PT01). |
| Giá quốc tế (tham chiếu) | `price.intl` | $0 | $5,99/tháng · $49,99/năm (≈ $4,17/tháng) | see above | |
| Credit lẻ | `creditTopUps` | không bán | không bán — credit đi theo gói | — | PT02 still allows ops to *grant* credits manually with reason + 2nd approver > 50. |
| Quản lý gói | — | manager only | manager only | manager only | One plan per family; buyer = manager; only manager sees payment, change, cancel; members see shared quotas and their own history (PV45). |
| Mid-cycle upgrade | — | — | "cấp ngay hạn mức gói mới cho kỳ hiện tại ⚑ cần chốt cách bù" | — | Open. |

## Entry points (PV00C, as drawn)

| Id | Source screen (copy of) | Trigger | Suggestion style | Paywall | After purchase returns to |
|---|---|---|---|---|---|
| E01 | MM04 Mẫu video · thư viện (E01 `991:15659`) | Free family taps a "Cao cấp" template | Sheet "Mẫu “…” thuộc Premium" · alt "Dùng mẫu miễn phí tương tự" | PW01 · Video | MM07 Hoàn thiện video, template + photos kept |
| E02 | MM10 Thiệp cột mốc · chọn mẫu | Taps a "Cao cấp" card template | Sheet · alt "Chọn mẫu miễn phí" | PW02 · Thiệp | MM11 Thiệp · chỉnh sửa |
| E03 | MM07 Hoàn thiện video — "Tạo video" | Free used 2 trial exports (Premium out of 4/month: info only, refill date, no sale — not drawn) | Sheet "Bạn đã dùng 2 lượt xuất video trải nghiệm" · alt "Lưu bản nháp, để sau" | PW01 · Video | MM08 Đang tạo video |
| E04 | MM15 Câu chuyện — "Làm tiếp" a draft | Draft uses a premium template after Premium ended/downgraded | Sheet "Bản nháp này dùng mẫu cao cấp" · alt "Đổi sang mẫu miễn phí" | PW01 · Video | MM07 with the old draft |
| E05 | CH20 Chat · Free gần hết | Task needs more credits than remain | existing bubble button "Xem Premium" (+ "Nhập tay") | PW03 · Lumi | CH23 Tiếp tục tác vụ |
| E06 | CH21 Chat · Free hết lượt | Out of credits; question kept | existing "Nâng cấp & tiếp tục câu hỏi" | PW03 · Lumi | CH23 Tiếp tục câu hỏi |
| E07 | CH24 Chat · Premium hết lượt | Premium used 200 credits | Info sheet "Đã hiểu" · "Xem mức dùng của gia đình" | **none** | stays on CH24; direct logging still works |
| E08 | 13c Dung lượng · sắp đầy | Premium ≥ 80 % of 10 GB | Inline card "Thêm dung lượng" · "Quản lý ảnh/video" | PW10 (PV00C) — note says PW04 | 13b Dung lượng |
| E09 | 13d Dung lượng · đã đầy | Premium 10 GB full; uploads queued | Inline | PW10 (PV00C) — note says PW04 | 13b, queue resumes |
| E10 | 13f Kỷ niệm · hết dung lượng (banner) | Free 1 GB full on upload; items kept on device | Sheet "Hết 1 GB của gói Free" | PW04 · Dung lượng | 13f, auto-resume upload |
| E11 | AS18 Tự lưu · không đủ dung lượng | Auto-save stopped at 1 GB | Sheet "Tự lưu kỷ niệm đang tạm dừng" | PW04 · Dung lượng | AS12 Tự lưu kỷ niệm |
| E12 | 14a Gia đình — mời người chăm sóc | Seats full (3/3) | Sheet · alt "Mời làm người thân" | PW05 · Người chăm sóc | 14a, invite continues |
| E13 | 13a Tôi — card under "Dung lượng" | Always (user explores) | Inline "Child Life Premium … từ 59.000đ/tháng" | PW06 · Khám phá | 13a / Gói của gia đình |
| E14 | any of the above | Viewer is a member, not the manager | as the original entry | PW07 · Nhờ người quản lý | the original screen |
| (PV40B) | Gói của gia đình · Free — "Xem các gói" | user opens plan page | button | PW06 (Note · PW06; Note · PV40B says "PV23") | — |
| (PV40/PV40B) | "Mua thêm dung lượng" row | user | row | PW10 (inferred) | — |
| (PV00B) | Onboarding, Hôm nay | — | **no paywall** | — | — |

## Navigation graph

```
MM04 ─tap Cao cấp─▶ E01 sheet ─Xem Premium─▶ PW01 ─Đăng ký─▶ PV30 App Store sheet ─▶ PV31 verifying ─ok─▶ MM07 (template + photos kept)
                         └─Dùng mẫu miễn phí tương tự─▶ MM04 (free template)            └─fail─▶ PV32 ─Thử lại─▶ PV31 | ─Khôi phục giao dịch─▶ PV33
MM10 ─tap Cao cấp─▶ E02 ─▶ PW02 ─▶ … ─▶ MM11                                            user cancels in store ─▶ back to PWxx, no error
MM07 ─Tạo video (no trial left)─▶ E03 ─▶ PW01 ─▶ … ─▶ MM08 · ─Lưu bản nháp, để sau─▶ MM15
MM15 ─Làm tiếp (premium draft)─▶ E04 ─▶ PW01 ─▶ … ─▶ MM07 · ─Đổi sang mẫu miễn phí─▶ MM07 basic
CH20 ─Xem Premium─▶ PW03 ─▶ … ─▶ CH23 (task resumes) · ─Nhập tay─▶ manual entry
CH21 ─Nâng cấp & tiếp tục câu hỏi─▶ PW03 ─▶ … ─▶ CH23 · ─Mở nhật ký hôm nay / Ghi cữ bú─▶ log screens
CH24 (Premium) ─▶ E07 info sheet ─Đã hiểu─▶ CH24 · ─Xem mức dùng của gia đình─▶ PV40 (or PV45 for a member)
13c/13d (Premium) ─Thêm dung lượng─▶ PW10 ─Thêm 20 GB─▶ store ─▶ 13b (queue resumes) · ─Quản lý ảnh/video─▶ 13e/largest videos
13f / AS18 (Free) ─▶ E10 / E11 sheet ─▶ PW04 ─▶ … ─▶ 13f / AS12 (auto-resume)
14a ─Mời người cùng chăm (3/3)─▶ E12 ─▶ PW05 ─▶ … ─▶ 14a invite · ─Mời làm người thân─▶ relative invite
13a Tôi ─Xem Premium ›─▶ PW06 ;  13a ─(entry needed)─▶ PV40 / PV40B / PV45
any entry, viewer ≠ manager ─▶ PW07 ─Nhờ Duy nâng cấp─▶ prefilled message to manager ─▶ back to origin
PWxx ─Khôi phục─▶ PV33 ;  PWxx ─×─▶ origin unchanged
PV40 ─Mua thêm dung lượng─▶ PW10 · ─Lịch sử sử dụng─▶ PV41 · ─Quản lý gia hạn─▶ App Store subscriptions (PV42 shown first) · ─Khôi phục giao dịch─▶ PV33
PV40B ─Xem các gói─▶ PW06 · ─Mua thêm dung lượng─▶ ? (Free) · ─Khôi phục─▶ PV33
PV42 ─Giữ Premium─▶ PV40 · ─Tiếp tục huỷ trong App Store─▶ App Store ;  expiry ─▶ PV43 ─Chọn người─▶ PV44 ─Lưu · 3/3─▶ PV43
PV43 ─Dọn bớt─▶ storage clean-up · ─Xuất dữ liệu─▶ export · ─Nâng lại Premium─▶ PW06? · ─Mở bản nháp─▶ MM15 · ─Xem video─▶ Kỷ niệm › Kỷ vật
PV45 ─Lịch sử sử dụng của tôi─▶ PV41 (own rows)
Portal: PT01 ─Mở Job video & hoàn lượt ›─▶ PT04 ; PT01 sidebar ─▶ PT02 (Gia đình) · PT03 (Cấu hình quyền lợi) · Giao dịch / Audit log (not drawn)
```

## Consolidated rules

1. Two plans only at launch: Free and Premium; one Premium product, monthly or yearly; storage add-ons 20 GB / 50 GB; no credit sales (PV00, PT03).
2. One plan per family; the buyer is the manager; only the manager sees payment and can change or cancel; benefits apply to every baby and member of that family and never leak to another family the member also belongs to (PV00 §2).
3. Credits and video exports are a shared family pool; usage history is shown by person and task, never conversation content (PV00 §2, PV41).
4. Relatives (view Kỷ niệm only) do not take caregiver seats; seats are counted on members with write access (PV00 §2, E12, PV44).
5. Non-managers see benefits and a "Nhờ {người quản lý} nâng cấp" button that sends a prefilled message without what they were doing (PV00 §2, PW07).
6. Lumi credit: hold at start → debit on success → refund on error/cancel; idempotency key per request, no double debit (PV00 §3, PT02, PT04).
7. Big tasks show their cost on the button before running ("Nhìn lại 7 ngày · 5 credit"); never mention tokens, models, API (PV00 §3) — conflicts with D-081.
8. Video: 1 lượt = 1 successful export; template, edit and on-device preview are free; re-exporting the same version is free (PV00 §3).
9. Quotas refill on the renewal day, no carry-over; yearly plans still refill monthly on the subscription day (PV00 §3, PV40 "mỗi tháng theo ngày đăng ký").
10. Cancel renewal: Premium stays to the end of the paid period, then Free; nothing is deleted (PV00 §4, PV42, PV43).
11. Over storage: block new uploads (keep them queued on device, auto-resume after upgrade); view, download, delete, export always allowed (PV00 §4, E09, E10, PV43).
12. Over seats: nobody is removed; the manager actively chooses who keeps write access, the rest become view-only and get a gentle "tạm chỉ xem" notice; no silent default (PV00 §4, PV43, PV44 + note).
13. Drafts on premium templates are kept; export needs Premium or a basic template; exported videos are kept (PV00 §4, E04, PV42, PV43).
14. Add-on storage lasts to the end of the paid period; memories, logs and exported videos stay accessible and exportable on every plan (PV00 §4).
15. Premium suggestions only appear when the user touches a Premium feature; never on app open; no crowns/locks across the app — only the existing "Cao cấp" template badge (PV00C).
16. Every suggestion offers a free alternative (free template, direct logging, clean up storage, invite as relative) (PV00C, E01–E12).
17. Health and basic care logging are never blocked (PV00C, E06).
18. Onboarding and Hôm nay never show a paywall (PV00B).
19. The paywall opens on the entry's card, tags the matching table row "Bạn đang cần", and shows a reason line only when opened from an entry; the proactive paywall (PW06) has none (Notes PW01, PW06).
20. After purchase the user returns to the exact previous screen with selections kept (PV00C).
21. Purchase: backend verifies the receipt/transaction before granting; the buy button cannot be pressed twice (Note PV31). Interrupted: tell whether money was taken, give a restore path, no scary copy (Note PV32). User cancels in store: close the sheet, back to the paywall, no error (PV32 annotation).
22. One store account (Apple ID) is bound to one family; moving it needs support, never automatic (PV33).
23. Cancelling happens in the App Store (iOS cannot cancel in-app); consequences are shown first (PV42 + note).
24. Members see shared quotas but not price, payment method or others' history (Note PV45).
25. PV40 answers six questions with three separate bars, never one merged credit gauge (Note PV40).
26. Commercial dashboards never show chat content or health data; AI/render/storage costs are logged per task and family with anonymous ids (PV00 footer, PT01, PT02).
27. Entitlements config is one versioned source for app, backend and website; every change creates a new version and needs two approvers (PV00 §5, PT03).
28. Manual adjustments need a mandatory reason and audit; a second approver above 50 credits or for plan changes (PT02).
29. Failed video jobs: auto-refund after 3 failed attempts; manual refund needs a reason and audit; retries reuse the idempotency key so no duplicate export or debit (PT04).
30. Template engine is validated on 6 representative templates out of a catalogue of 48; a named config is not a finished template (PV00B).

## Data the screens imply

**Family subscription (server-owned, one per family)**
| Field | Evidence |
|---|---|
| `families/{f}/subscription.plan` = `free` \| `premium` | PV40/PV40B/PV45 |
| `period` = `month` \| `year`; `currentPeriodStart/End` (24/10/2026 – 24/10/2027) | PT02, PV40 |
| `cycleAnchorDay` (24) and `nextGrantAt` (24/11/2026) — monthly grants even on yearly | PV40, PT02 |
| `autoRenew`, `cancelAtPeriodEnd`, `renewsAt`, `downgradedAt` (24/10/2027) | PV42, PV43 |
| `managerUid` (buyer; "Duy (bạn)"), `managerDisplayName` for members ("Quản lý bởi Duy") | PV40, PV45, PW07 |
| `store` = `app_store` \| `play`; `originalTransactionId` ("txn 2000000…4417"), `storeAccountHash` (Apple ID bound to one family) | PT02, PV33 |
| `entitlementsVersion` ("2.0-launch" / "v2.0-draft") | PV00, PT02, PT03 |
| `matchState` ("Khớp giao dịch ✓" / "Giao dịch chưa khớp quyền lợi") | PT01, PT02 |
| `billingIssue` (store retry / grace) | PT01 "Lỗi thanh toán (đang retry của store)" |
| `refunds[]` | PT01 "Hoàn tiền" |
| `storageAddOn` = none \| `20gb` \| `50gb`, own period/renewal | PW10, PT01 |

**Balances (per family)**
- `lumiCredits`: Free `oneTimeRemaining` (30 → 2); Premium `cycleRemaining`/`cycleLimit` (132/200), `held`.
- `videoExports`: Free `trialRemaining` (2 → 0), Premium `cycleRemaining` (3/4), `held`.
- `storageUsedBytes` / `storageLimitBytes` (base + add-on); per baby and per type breakdown (13c/13d).
- `seats`: `writeMembers` count vs `caregiverSeats`; `viewOnlyBecauseOverLimit` flag per member; pending invites (unclear whether they hold a seat).

**Ledger entries (`families/{f}/ledger/{id}`)** — kind `hold` \| `debit` \| `refund` \| `grant` (`cycle.grant`, trial grant) \| `adjust` (manual); `unit` `credit` \| `videoExport`; `amount`; `task` (`lumi.quickAnswer`, `lumi.voiceLog`, `lumi.writeCaption`, `lumi.review7d`, `video.export`); `memberUid` or `system`; `idempotencyKey` (`rq_…`, `job_…`, `cyc_…`); `status` (Giữ chỗ / Đã trừ / Cấp / Hoàn (lỗi)); `reason` (refund/adjust); `createdAt`. Member view shows person · task label · amount only (PV41); manager sees all rows, members their own (PV45).

**Render jobs** — `jobId`, `familyId`, `templateId` (Thư gửi con, Lớn thêm rồi, Then & Now), `error` (Render timeout, Ảnh nguồn bị xoá, Font thiếu glyph, Provider 503), `attempts` n/3, `holdRef`, action Hoàn / Retry; p50/p95 render time and render cost per video (PT04).

**Entitlements config (versioned)** — PV00 §5 block: `plans.free{lumiCreditsOneTime 30, videoExportsTrial 2, storageGB 1, caregiverSeats 3, premiumTemplates false}`, `plans.premium{lumiCreditsPerCycle 200, videoExportsPerCycle 4, storageGB 10, caregiverSeats 6, premiumTemplates true, price{vn{month 59000, year 599000}, intl{month 5.99, year 49.99}}}`, `storageAddOns[{gb 20, vn[39000,399000], usd[1.99,19.99]}, {gb 50, vn[79000,799000], usd[3.99,39.99]}]`, `creditTopUps false`; plus `taskCosts` (PT03); `version`, `status` (running v1.3 / draft v2.0), approvals (2 people), diff ("So sánh JSON"). Maps onto `config/flags,limits` → `publicConfig/*` (CLAUDE.md conventions).

**Upgrade context (client)** — entry id (E01…E14), the item in progress (template id, draft id, pending Lumi question, upload queue, pending invite), so the paywall headline/reason/card and the return target can be restored after purchase (PV00C, Note PW01).

**Manager request** — "Nhờ Duy nâng cấp": member → manager message, prefilled, no content of the draft/question (PW07).

**Audit (portal)** — time, operator (ops.lan, ops.minh, system), action (view entitlements, adjustment with approver, transaction match) (PT02).

**Commercial aggregates (portal, no content)** — families Free/Premium, conversion, add-on counts, gross / net revenue, cost per Premium family (AI + render + storage), p95 family cost, quota-exhaustion rates, renewals/cancellations/billing retries/refunds, jobs failed in 24 h, holds awaiting refund, unmatched transactions (PT01).

## Open questions and inconsistencies

**Prices and numbers**
1. Yearly "≈ 49.900đ/tháng" — 599.000/12 = 49.917đ; also E13 "từ 59.000đ/tháng" should be the lower effective yearly price or drop "từ".
2. Add-on prices exist in PV00 config but not in PT03's table; PW10 shows "399.000đ/năm hoặc 39.000đ/tháng" with no period picker while its footnote says "gia hạn cùng kỳ với Premium" — is the add-on period forced to the Premium period? Can a family hold both add-ons (+70 GB) or switch 20↔50?
3. `lumi.quickAnswer` costs 1 credit (PT03) but PT02's ledger debits −2; no cost entry for reading a photo (E05 "Đọc ảnh này cần khoảng 3 lượt", P-159 photo 3).
4. Mid-cycle upgrade "cấp ngay hạn mức gói mới … ⚑ cần chốt cách bù" (PV00 §3); also Free → Premium: do unused Free trial credits/exports carry over?
5. Version label: PV00 "2.0-launch", PT03 panel "v2.0-launch" vs tag "Bản nháp: v2.0-draft" and "Đang chạy: v1.3", PT02 family on "v2.0-draft".
6. Seats: PT02 "Người chăm sóc 3 / 5" vs Premium cap 6 and PV42 "5 người chăm sóc"; PV40 "5 thành viên".
7. Mock arithmetic: PV40 storage "Ảnh 10,9 GB · video 1,5 GB" vs "6,2 / 10 GB"; E08/E09 per-type sums ≠ totals; E13 Free family "3,2 GB / 10 GB"; PV42/PV43 "14 video đã xuất" impossible within the timeline; Teddy's birthday differs (17.08.2026 in Thẻ tính năng vs 1 month on 14.11.2026 in E02/E03); "Tuần thứ 3 · 1 – 8 tháng 10"; Portal audit dates precede the purchase.

**Copy contradictions**
8. E05/E06 (copied CH20/CH21) still say "Còn 2/20 lượt · làm mới 01/11", "hết lượt hỗ trợ AI tháng này" — PV00/PW03/PV40B say Free = 30 one-time credits, no refresh. Which wins for CH20/CH21/CH22 copy and the Lumi unit word ("lượt" vs "credit")?
9. E07: note says "Đã có Premium → mua thêm", the sheet sells nothing (PV00: no credit sales); underlying CH24 says "Hộ … kỳ này … quota" vs "gia đình … tháng này … credit".
10. E08/E09 notes → PW04, PV00C → PW10; E08 still shows "liên hệ quản trị để mở rộng" above the add-on card.
11. E10/E11 underlying screens show a 10 GB family ("Hết dung lượng 10 GB", "9,96 / 10 GB") under a "Hết 1 GB của gói Free" sheet; E11's "Tự lưu đang tạm dừng" sits on a pre-upload check screen.
12. PV43 "Tạm dừng tải ảnh mới cho tới khi dưới 5 GB" (Free is 1 GB); stale "Plus" in layer names (PV40, PV42, PV43, PT01, PT02) and "mua thêm: 0" / "Mua thêm credit Lumi" rows.
13. PV00 "show cost on the button (… · 5 credit)" and "số dư ở header" (PV00B) vs D-081 (credits out of main screens, no "dùng N lượt" notes). PV00B "không có khu Premium riêng" vs D-089 "Tính năng & Premium" hub.
14. PV40B offers "Mua thêm dung lượng" to a Free family though add-ons are Premium-only; Note PV40B targets "PV23" (absent).
15. PV00B touchpoint table cites PV20/PV21/PV22 (absent) and says Gia đình has "chưa có màn hiện có" although E12 covers it; PV00B headline list differs from frames for PW02 and PW04; E07 has no PV00B row.
16. "Bà ngoại" spends Lumi credits in PV41 (relatives are view-only per PV00) and appears as "Đã xem cập nhật" in the Người chăm card; family cast differs between E12 (Mai/Minh/Cô Lan/Bà nội Hoa = Người thân) and PV40–PV45 (Duy = Ba manager, Mai, Cô Hạnh, Ông nội/Bà nội = Người chăm sóc).
17. Legal footer says "huỷ trong App Store" only; PT01 mentions "App Store/Play". No Android billing, restore or manage-subscription UI.

**Missing states**
18. Offline: paywall, PW10, PV40 and quota bars with no network; E-sheets when entitlements can't be fetched.
19. Night care: only E01–E04 are Night; no Night versions of E05–E13, PV30–PV45; the dark premium surfaces' contrast on Light screens is untested.
20. English: no EN frames; Playfair Display + Vietnamese; English drafts needed for ~150 strings (D-012).
21. Relative and caregiver views: what a relative sees when touching a premium template or a full storage; what a "tạm chỉ xem" caregiver sees; PW07 only drawn for video.
22. Pending payment: Ask to Buy / deferred, SCA, PV31 timeout; success screen after PV31 (return to the origin is described, not drawn); billing retry / grace period / account hold (PT01 counts them, app shows nothing); refund revocation (what happens to quotas already used and premium exports after a store refund).
23. Premium-family variants of E03 (4/4 used, refill date) and E12 (6/6 seats), and E07 for a member; add-on expiry while over the base 10 GB.
24. Multi-family members: a member in two families, one Premium — which family's pool is charged when acting on a baby; switching families in the Lumi header.
25. Free-tier lifecycle: once the 30 credits and 2 exports are gone are they ever regranted (new baby, reinstall, after downgrade from Premium)? Does a downgraded family get the Free trial again?
26. Seat picker timing: before expiry or at expiry; what if the manager never chooses (note forbids a silent default — then who can write in the meantime?); can the manager uncheck themself; do pending invites hold seats; seat check on accepting an invite.
27. Manager transfer: manager leaves the family or loses the Apple ID; PV33 says support only — no in-app transfer, no co-manager.
28. Restore by a non-manager member (PW07 and PW06 show "Khôi phục"); restore on Android; Apple Family Sharing for the subscription.
29. "Nhờ Duy nâng cấp": channel (push/in-app/Zalo), rate limit, manager's landing screen, what the member sees after the manager pays.
30. Cross-unit compensation: PT02 compensates a failed *video* job with *Lumi credits*; PT04 job_6a1e… is 3/3 failed but still "giữ" although auto-refund is after 3 failures.
31. Portal: Giao dịch and Audit log pages are in the sidebar but not drawn; version rollout (effective date, grandfathering of v1.3 families, rollback); who may approve; how a config change reaches `publicConfig` and the website.
32. Template catalogue: which of the 48 templates are Cao cấp, and the "Việt – Anh" claim on premium cards.
33. Trial: PV00B roadmap "A · Chốt chính sách: quyền lợi, trial…" — no free trial or intro offer is drawn; is the one-time Free allowance the only "trial"?

