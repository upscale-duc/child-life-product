# Adaptive Experience (one app, content re-ordered by age + goals): spec extracted from final Figma

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only), page **"v1.0 - improvement"**, section **"Adaptive Experience"** `930:11858` (canvas y 38330, 2450 × 8630), read 2026-10-24. No Figma node was modified.

**Method.** `get_design_context` ×1 per frame (screenshot excluded; 24 screen frames, 6 note frames, the Lumi button instance `917:85394` and the Caregiver nav variant `917:2886`), `get_metadata` ×2 (section `930:11858`, saved locally and split; component set `917:3012`), `get_screenshot` ×26. No rate limit was hit, no frame failed, no write tool was used. Rendered `<p>` text is authoritative; several layer names are stale (flagged as **layer ≠ text**). Glosses in parentheses are engineering drafts. **(prototype link)** = the node renders as `<a … cursor-pointer>`; the MCP never exposes the target, so targets are **(inferred)**.

**Theme.** Every frame is **Light** (`cloud #f6fcfb` page). There is **no Night care twin** in this section. The "Đêm" pill (Night care toggle) appears on 0–1 Today frames only (AX10, AX30, AX33, AX40).
**Mock data.** One parent, **Mai** ("M", Mẹ), manages **Teddy** (2 tháng; born 17/08/2026), **Na** (4 tuổi; born 12/03/2022) and **Bin** (9 tuổi), and is a **Người thân** of **Bơ** (2 tuổi). Family has 5 members. Storage 3,4 / 10 GB. Spending Na Oct 2.450.000 ₫ (6 khoản), Bin Oct 4.800.000 ₫ (9 khoản). Mock "today" ≈ 23/10/2026.
**Screenshots.** One per frame in [`img/ax/`](img/ax/) named by code (`AX10.png` …), plus `AX00.png` (matrix) and `NavBar-v2-Adaptive.png` (component set).

## Frame list

Section labels (text nodes) and rows, top to bottom:

| Label node | Label text | y |
|---|---|---|
| `916:12928` | Label · AX · Adaptive Experience — tổng quan | 0 |
| `911:12234` | Label · AX · Adaptive Experience — Hôm nay theo độ tuổi (chỉ chức năng V1) | 1350 |
| `912:12491` | Label · AX · Khám phá — mọi chức năng V1, xếp theo tuổi | 2700 |
| `913:12521` | Label · AX · Onboarding — thêm bé ở mọi độ tuổi, chọn mục tiêu, gợi ý Hôm nay | 4725 |
| `914:12632` | Label · AX · Đổi bé, nhiều độ tuổi trong một gia đình, chuyển giai đoạn, Hồ sơ | 6075 |
| `915:12764` | Label · AX · Empty states — lần đầu vào app, theo độ tuổi | 7425 |

| Code | Node | Layer name | Size | Nav (active) | Lumi | FAB + | Note | Screenshot |
|---|---|---|---|---|---|---|---|---|
| AX00 | `916:12929` | Ma trận ưu tiên theo tuổi & quy tắc | 1660 × 1232 | — | — | — | — | `img/ax/AX00.png` |
| AX10 | `911:12235` | Hôm nay · 0–1 tuổi (Teddy 2 tháng) | 375 × 968 | Parent (Hôm nay) | ✓ | ✓ | — | `img/ax/AX10.png` |
| AX11 | `911:84650` | Hôm nay · 1–3 tuổi (Bơ 2 tuổi) | 375 × 1001 | Parent (Hôm nay) | ✓ | ✓ | — | `img/ax/AX11.png` |
| AX12 | `911:84772` | Hôm nay · 3–6 tuổi (Na 4 tuổi) | 375 × 1293 | Parent (Hôm nay) | ✓ | ✓ | — | `img/ax/AX12.png` |
| AX13 | `911:84905` | Hôm nay · 6–12 tuổi (Bin 9 tuổi) | 375 × 1076 | Parent (Hôm nay) | ✓ | ✓ | — | `img/ax/AX13.png` |
| AX14 | `912:12365` | Tuỳ chỉnh Hôm nay (Na 4 tuổi) | 375 × 927 | none (pushed/modal) | — | — | — | `img/ax/AX14.png` |
| AX20 | `912:12492` | Khám phá · 0–1 tuổi (Teddy) | 375 × 1568 | Parent (Khám phá) | ✓ | **no** | — | `img/ax/AX20.png` |
| AX21 | `912:12697` | Khám phá · 3–6 tuổi (Na) | 375 × 1601 | Parent (Khám phá) | ✓ | **no** | — | `img/ax/AX21.png` |
| AX01 | `913:12522` | Thêm bé · thông tin cơ bản | 375 × 812 | none | — | — | — | `img/ax/AX01.png` |
| AX02 | `913:12570` | Thêm bé · tuổi ngoài năm đầu (Na 4 tuổi) | 375 × 812 | none | — | — | — | `img/ax/AX02.png` |
| AX03 | `913:12628` | Mục tiêu gia đình · 0–1 tuổi (Teddy) | 375 × 838 | none | — | — | — | `img/ax/AX03.png` |
| AX04 | `913:12715` | Mục tiêu gia đình · 3–6 tuổi (Na) | 375 × 861 | none | — | — | — | `img/ax/AX04.png` |
| AX05 | `913:12802` | Chọn theo dõi · khi chọn mục tiêu chăm sóc | 375 × 812 | none | — | — | — | `img/ax/AX05.png` |
| AX06 | `913:12873` | Gợi ý Hôm nay · Na 4 tuổi | 375 × 812 | none | — | — | — | `img/ax/AX06.png` |
| AX30 | `914:12633` | Chọn bé (switcher) | 375 × 812 | Parent (Hôm nay), under scrim | ✓ | ✓ | `914:12751` | `img/ax/AX30.png` |
| AX31 | `914:12753` | Đang chuyển sang Na | 375 × 812 | Parent (Hôm nay) | ✓ | ✓ | `914:12801` | `img/ax/AX31.png` |
| AX32 | `914:12803` | Đổi sang bé mà bạn là Người thân (Bơ) | 375 × 812 | **Relative** (Kỷ niệm) | **no** | **no** | `914:12844` | `img/ax/AX32.png` |
| AX33 | `914:12846` | Teddy tròn 1 tuổi · gợi ý sắp xếp lại | 375 × 900 | Parent (Hôm nay) | ✓ | ✓ | `914:12956` | `img/ax/AX33.png` |
| AX34 | `914:12958` | Hồ sơ (tab) | 375 × 956 | Parent (Hồ sơ) | ✓ | **no** | — | `img/ax/AX34.png` |
| AX40 | `915:12765` | Hôm nay · lần đầu · 0–1 tuổi (Teddy) | 375 × 891 | Parent (Hôm nay) | ✓ | ✓ | `915:12878` | `img/ax/AX40.png` |
| AX41 | `915:12880` | Hôm nay · lần đầu · 1–3 tuổi (Bơ) | 375 × 961 | Parent (Hôm nay) | ✓ | ✓ | `915:12976` | `img/ax/AX41.png` |
| AX42 | `915:12978` | Hôm nay · lần đầu · 3–6 tuổi (Na) | 375 × 1120 | Parent (Hôm nay) | ✓ | ✓ | — | `img/ax/AX42.png` |
| AX43 | `915:13078` | Hôm nay · lần đầu · 6–12 tuổi (Bin) | 375 × 1135 | Parent (Hôm nay) | ✓ | ✓ | — | `img/ax/AX43.png` |
| AX44 | `915:13175` | Kỷ niệm · trống (Na) | 375 × 812 | Parent (Kỷ niệm) | ✓ | ✓ | — | `img/ax/AX44.png` |
| AX45 | `915:13229` | Khám phá · tìm chưa có (Na) | 375 × 812 | Parent (Khám phá) | ✓ | **no** | `915:13289` | `img/ax/AX45.png` |

Pattern (inferred): the **FAB "+" shows on Hôm nay and Kỷ niệm** only; Khám phá and Hồ sơ have the Lumi button alone (it moves down to y = nav − 66 when the FAB is absent). Relative: neither.

---

## AX00 · Ma trận ưu tiên theo tuổi & quy tắc `916:12929`

(Transcribed earlier; included verbatim as supplied.)

**Title:** "Một ứng dụng, một thanh điều hướng — nội dung xếp lại theo tuổi + mục tiêu, chỉ dùng chức năng V1"
**Subtitle:** "Nav: Hôm nay · Kỷ niệm · Khám phá · Hồ sơ + nút Lumi tách riêng. Người thân: Kỷ niệm · Hồ sơ. Người chăm bé: Hôm nay · Khám phá · Hồ sơ."

| Hàng | 0–1 tuổi · Teddy | 1–3 tuổi · Bơ | 3–6 tuổi · Na | 6–12 tuổi · Bin |
|---|---|---|---|---|
| Lời chào | Chào buổi sáng, Teddy · Nhịp hôm nay của con | Hôm nay con lại khám phá thêm điều mới | Hôm nay của Na thế nào? | Cùng lưu lại hành trình của Bin |
| Hôm nay · thứ tự mặc định | 1 Nhịp hôm nay (ghi nhanh) 2 Nhắc nhở 3 Kỷ niệm gần đây 4 Tăng trưởng | 1 Kỷ niệm gần đây 2 Ghi nhanh ngủ, tã 3 Nhắc nhở (tiêm) 4 Tăng trưởng | 1 Lưu khoảnh khắc hôm nay 2 Video & thiệp 3 Chi tiêu 4 Nhắc nhở 5 Cả nhà cùng xem | 1 Kỷ niệm / nhật ký 2 Nhắc nhở 3 Chi tiêu 4 Tăng trưởng |
| Ghi nhanh mặc định | Bú bình, bú mẹ, ngủ, tã (+ hút sữa nếu bật) | Ngủ, tã (gợi ý) · bú, hút sữa nếu cần | Không gợi ý sẵn · thêm từ Tuỳ chỉnh bất cứ lúc nào | (same) |
| Khám phá · "Gợi ý cho bé" (mọi mục khác vẫn hiện bên dưới) | Theo dõi bú/ngủ/tã · Thống kê · Tăng trưởng · Tiêm chủng | Kỷ niệm · Theo dõi ngủ/tã · Tiêm chủng · Tăng trưởng | Kỷ niệm · Video & thiệp · Chi tiêu · Nhắc nhở | Kỷ niệm · Nhắc nhở · Chi tiêu · Tăng trưởng |
| Mục tiêu gợi ý sẵn (onboarding) | Theo dõi bú/ngủ/tã · Lưu giữ kỷ niệm | Lưu giữ kỷ niệm · Tăng trưởng & tiêm chủng | Lưu giữ kỷ niệm · Chi tiêu · Cả nhà | Lưu giữ kỷ niệm · Nhắc nhở · Chi tiêu |
| Lần đầu (empty) | Ghi hoạt động đầu tiên · Lưu khoảnh khắc đầu tiên | Khoảnh khắc đầu tiên · Tìm lại ảnh cũ (Beta) | Khoảnh khắc đầu tiên · Tìm lại ảnh cũ · Chi tiêu · Mời người thân | Nhật ký đầu tiên · Tìm lại ảnh cũ · Nhắc nhở · Chi tiêu |
| Lumi gợi ý hỏi | Lần bú cuối lúc mấy giờ? | Tuần này Bơ ngủ trưa thế nào? | Tháng này đã chi cho Na bao nhiêu? | Tuần tới Bin có lịch gì? |

**Quy tắc** (nodes `918:13395`, `916:13022`…`916:13027`):
- • Không khoá tính năng theo tuổi: mọi chức năng V1 dùng được cho bé ở mọi độ tuổi. Tuổi + mục tiêu chỉ quyết định thứ tự gợi ý trên Hôm nay/Khám phá và nhãn "Gợi ý cho …".
- • Cá nhân hoá những gì đang có — không giả vờ có tính năng chưa làm. Chặng 1–3, 3–6, 6–12 chỉ xuất hiện ở thẻ "Cùng con lớn lên · Đang phát triển" trong Khám phá.
- • Xếp hạng widget = mục tiêu (35%) + tuổi (25%) + tần suất dùng (20%) + hoạt động gần đây (10%) + ưu tiên sản phẩm (10%) — trọng số khởi tạo để thử nghiệm.
- • Ưu tiên tuyệt đối: widget phải thuộc chức năng đã phát hành · ghim không bị di chuyển · đã ẩn không tự hiện lại · thiếu dữ liệu thì dùng mặc định theo tuổi + mục tiêu.
- • Không tự ẩn khi bé sang giai đoạn mới: chỉ đề xuất 1 lần ở 12, 36, 72 tháng (AX33). Lịch sử luôn giữ.
- • Mỗi bé một ngữ cảnh: đổi bé → xoá nội dung bé cũ, hiện bé mới, giữ tab nếu vai trò cho phép. Mục tiêu và tuỳ chỉnh Hôm nay lưu theo từng bé.
- • Tuổi tính từ ngày sinh theo múi giờ của bé. Không có màn chọn "chế độ tuổi".

**Matrix vs the drawn screens** (details in §Open questions): AX12 Hôm nay and AX14 follow the 3–6 order; **AX06 swaps 4/5** (Cả nhà before Nhắc nhở). AX11 (1–3) matches. AX13 (6–12) matches. AX10 (0–1) matches. AX03/AX04 goals match the "Mục tiêu gợi ý sẵn" row. AX41 (Bơ, empty) shows Ghi nhanh ngủ/tã although the 1–3 preset goals contain no care goal (AX41 note says Ghi nhanh needs the care goal).

---

## Shared chrome

- **Screen frame**: 375 wide, radius 40, page `cloud #f6fcfb`. Content column `px 16`, `pt 52`, `pb 120`, `gap 14`. StatusBar 40 ("9:41" / "•••").
- **Top row** (gap 8): **Child switcher** pill — `surface #fff`, radius 999, `pl 4 pr 12 py 4`, avatar 30 (photo, round), name SemiBold 15 `ink #173d44` in the form **"{tên} · {tuổi}"** ("Teddy · 2 tháng", "Bơ · 2 tuổi", "Na · 4 tuổi", "Bin · 9 tuổi", "Teddy · 12 tháng"), `Icon/chevron-down` 16. AX10's switcher is a **(prototype link)** → AX30 (inferred). Then a spacer; on 0–1 frames a **"Đêm"** pill (`surface`, radius 999, `px 12 py 7`, `Icon/today` 16 + "Đêm" SemiBold 13 `ink`). No avatar/"Tôi" button any more: the profile moved to the Hồ sơ tab.
- **Greeting**: Bold 26/1.25 `ink`; sub-line Medium 14/1.45 `ink-muted #55707a`.
- **Section header**: Bold 17 `ink` + spacer + optional link SemiBold 14 `mint-text #06716d`.
- **Widget card**: `surface`, radius 20, `px 16 py 14`, gap 12, `shadow-card` (0/1/2 `#173D440F` + 0/8/24 `#173D4414`; code renders drop-shadow 0 8 12 / 0 1 1). Header: icon chip (`p 8`, radius 12, soft fill per module) + title Bold 16 `ink` + subtitle Medium 12 `ink-muted` + optional trailing link SemiBold 13 `mint-text`.
  - Icon chip fills: Kỷ niệm/khoảnh khắc `peach-soft #ffe3da`; Nhắc nhở `sunshine-soft #fff4d6`; Tăng trưởng `care-growth-soft #fdede2`; Chi tiêu / Cả nhà / Lumi / Tìm lại ảnh `mint-soft #e6f7f5`; Bú bình `care-bottle-soft #e5f1fb`; Bú mẹ `care-breast-soft #fceaf0`; Hút sữa `care/pump/soft #f5eafa`; Ngủ `care-sleep-soft #edeefc`; Tã `care-diaper-soft #e7f4e3`; Sơ cứu `error-soft #fbe9ea`; Thống kê `care-sleep-soft` with grid icon in `care-sleep-ink #4447a8`; "Cùng con lớn lên" `surface-2 #eef6f5`.
- **Quick-log tile** ("Ghi nhanh"): equal-width tiles, gap 8, radius 16, `px 10 py 12`, gap 6; header icon 16 + label Bold 13; status Medium 11/1.35 `ink-muted`; a white round "+" (`p 4`, `Icon/plus` 14). Empty variant: status "Chưa ghi" and a pill CTA (`surface`, `px 10 py 5`, `Icon/plus` 12 + "Ghi lần đầu" Bold 11).
- **Buttons** (component `Button` 8:33): primary h56 `mint-deep #087f7b` / `on-mint-deep #fff`, Medium 17/24; secondary h52 `surface-2` / `ink`; radius `radius-pill`.
- **"Tuỳ chỉnh Hôm nay"** link at the end of every populated Today: centred, `py 10`, `Icon/sliders` 16 + SemiBold 14 `mint-text`. On AX12 it is a **(prototype link)** → AX14 (inferred).
- **List group** (Khám phá, Hồ sơ, AX05/AX06/AX14): `surface`, radius 16, rows `px 14 py 12` gap 12, title SemiBold 15 `ink`, subtitle Medium 12/1.4 `ink-muted`, trailing `Icon/chevron-right` 16. No separators drawn. Note D-096 now gives page cards `shadow-card`.
- **Onboarding chrome** (AX01–AX06): top row back button (`surface` circle `p 8`, `Icon/back` 20) · centred step "Bước n/N" SemiBold 13 `ink-muted` · right slot ("Bỏ qua" SemiBold 14 `mint-text` on goal steps; blank otherwise). Bottom bar at y 714 (AX03 740, AX04 763), `cloud` bg, `pt 12 pb 30 px 16`, primary button. The bottom bar is the **(prototype link)**.
- **Note frames** (`Note · AXnn`): `#fff5c7`, radius 10, `px 12 py 10`, Medium 12/1.45 `#4d400d`, under their screen.

### NavBar v2 · Adaptive (component set `917:3012`, instance e.g. `917:85369`)

Component description: "Adaptive IA (24.10.2026): Hôm nay · Kỷ niệm · Khám phá · Hồ sơ. Lumi + nút thêm nổi bên phải, tách khỏi thanh tab."

- Floating pill: x 16, w 343, h 68, `nav-bar #173d44`, radius 999, `p 6` (Explore variants `px 4 py 6`), `shadow-nav` (0/12/30 `#173D4440`).
- Tab: flex 1, column, gap 3, `px 2 py 6`, radius 20. Icon 20 + label 11/16, tracking 0.2. **Active**: fill `nav-active #fff`, label Bold `on-nav-active #173d44`, icon in `ink`. **Inactive**: no fill, label Medium `nav-icon #b9cfcf`, icon stroke `nav-icon`.
- Tabs and icons: **Hôm nay** (`Icon/today`), **Kỷ niệm** (`Icon/memories`), **Khám phá** (`Icon/grid`, 4 rounded squares), **Hồ sơ** (`Icon/profile`). Labels are always shown.
- Variants (9): `Role=Parent` × Active Today / Memories / Explore / Profile (4 tabs); `Role=Caregiver` × Today / Explore / Profile (3 tabs: Hôm nay · Khám phá · Hồ sơ); `Role=Relative` × Memories / Profile (2 tabs: Kỷ niệm · Hồ sơ). Screenshot `img/ax/NavBar-v2-Adaptive.png`.
- Non-active tabs in some instances render as `<a>` (prototype links), e.g. AX10 Khám phá/Hồ sơ.

### Lumi button (`917:85394`, instance of `Chat/Nút trợ lý` 628:9074, "Trạng thái = Mặc định")

64 × 64 at x 297, 12 px above the FAB (y = FAB − 74). Halo ("Hào quang") 60; speech-bubble 54 with radii 27/27/8 (bottom-right)/27, gradient 135° `#2bc4b5` → `#086b73` → `#545cdb`, 1.5 px `rgba(255,255,255,.45)` border, shadow 0 8 18 −2 `rgba(31,77,153,.35)`, inner highlight; `Logo/Mark` 24 inside; two "Sao AI" sparkles (16 and 9). No label. Description (verbatim): "Nút nổi mở Trợ lý chat. Dùng Logo/Mark Child Life + huy hiệu AI. Đặt ngay trên nút ghi nhanh (+), căn giữa theo trục dọc của nút +, cách 12px. Không che nút +. Hết lượt: vẫn mở được chat để xem lịch sử/ghi trực tiếp. Đang xử lý: vòng gradient chạy quanh nút khi trợ lý đang đọc/soạn trả lời ở nền."

### FAB · Thêm (`917:85409`)

60 × 60 circle at x 299, `mint #2cbfb3`, shadow 0 12 16 `rgba(23,61,68,.18)`, `Icon/plus` 26 white. No label. Sits 8 px above the nav (y = nav − 52). What it opens is not drawn (inferred: the existing quick-add sheet).

---

## Hôm nay theo tuổi

### AX10 · Hôm nay · 0–1 tuổi (Teddy 2 tháng) `911:12235`
1. Top: switcher "Teddy · 2 tháng" (prototype link) · "Đêm".
2. **"Chào buổi sáng, Teddy ☀️"** / "Nhịp hôm nay của con, ghi nhanh trong một chạm."
3. Section **"Nhịp hôm nay"** · link **"Xem lịch sử"**.
4. Ghi nhanh, 3 tiles: **"Bú bình"** — "2 giờ 15 phút trước" · **"Ngủ"** — "đang ngủ · 42 phút" · **"Tã"** — "1 giờ 25 phút trước"; each with "+". (No Bú mẹ tile although the matrix and AX05 turn it on — see Q.)
5. Widget **"Nhắc nhở"** — "3 đang bật" — link "Tất cả"; rows "Bú bình" · "15:00"; "Tiêm mũi 6 trong 1" · "Thứ Bảy 8:30".
6. Widget **"Kỷ niệm gần đây"** — "Tuần 9 · 12 ảnh" — link "Xem tất cả"; 3 photos 98 × 98 radius 12.
7. Widget **"Tăng trưởng"** — "Đo lần cuối 3 ngày trước" — link "Ghi số đo"; value Bold 20 **"5,4 kg · 58 cm"**.
8. **"Tuỳ chỉnh Hôm nay"**.
9. Lumi · FAB · Nav (Hôm nay active).

### AX11 · Hôm nay · 1–3 tuổi (Bơ 2 tuổi) `911:84650`
1. Switcher "Bơ · 2 tuổi" (no Đêm pill).
2. **"Chào buổi sáng, Bơ ☀️"** / "Hôm nay con lại khám phá thêm điều mới."
3. Widget **"Kỷ niệm gần đây"** — "Tuần này · 8 ảnh" — "Xem tất cả"; 3 photos; primary button **"Thêm khoảnh khắc"**.
4. Section **"Ghi nhanh"** · link **"Lịch sử"**.
5. 2 tiles: **"Ngủ trưa"** — "hôm qua 1 giờ 40 phút" · **"Tã"** — "sáng nay 7:10".
6. **"Nhắc nhở"** — "2 sắp tới" — "Tất cả"; "Tiêm nhắc sởi – rubella" · "12/11"; "Khám răng" · "Thứ Bảy 9:00".
7. **"Tăng trưởng"** — "Đo lần cuối 1 tháng trước" — "Ghi số đo"; **"12,1 kg · 86 cm"**.
8. "Tuỳ chỉnh Hôm nay". Lumi · FAB · Nav.

Note: the sleep tile is labelled **"Ngủ trưa"** (nap) for 1–3, "Ngủ" for 0–1.

### AX12 · Hôm nay · 3–6 tuổi (Na 4 tuổi) `911:84772`
1. Switcher "Na · 4 tuổi".
2. **"Hôm nay của Na thế nào?"** / "Lưu lại một khoảnh khắc nhỏ — mai này sẽ thành câu chuyện lớn."
3. Widget **"Lưu khoảnh khắc hôm nay"** (`Icon/camera`) — "Ảnh, video hoặc vài dòng nhật ký"; photo 150 h radius 14; primary **"Thêm khoảnh khắc"**.
4. Widget **"Tạo từ kỷ niệm của Na"** (`Icon/spark`) — "Video, thiệp từ ảnh bạn chọn"; two `surface-2` tiles radius 14 `p 12`: **"Video kỷ niệm"** / "Từ ảnh của bạn" · **"Thiệp"** / "Dịp đáng nhớ".
5. Widget **"Chi tiêu tháng này"** (`Icon/drop`) — "Tháng 10 · 6 khoản" — link **"Thêm"**; Bold 22 **"2.450.000 ₫"**; stacked bar h 8 radius 999 (segments `care-sleep-accent #6c6fd8` 186.6, `care-bottle-accent #3b8fd9` 77.75, `care-diaper-accent #5daa4e` 46.65 of 311); legend "Giữ trẻ & học · Quần áo · Khác".
6. **"Nhắc nhở"** — "1 sắp tới" — "Tất cả"; "Họp phụ huynh" · "Thứ Sáu 17:00".
7. Widget **"Cả nhà cùng xem"** (`Icon/family`) — body Medium 13 "Ông bà xem được những kỷ niệm bạn chia sẻ với gia đình."; overlapping avatars 32 (−8): "M" `#ffdbcc`, "B" `#d1e5ff`, "BN" `#ede3ff` (raw hex, not tokens); secondary button **"Mời người thân"**.
8. "Tuỳ chỉnh Hôm nay" (prototype link → AX14). Lumi · FAB · Nav.

No Ghi nhanh row (matches "Không gợi ý sẵn").

### AX13 · Hôm nay · 6–12 tuổi (Bin 9 tuổi) `911:84905`
1. Switcher "Bin · 9 tuổi".
2. **"Cùng lưu lại hành trình của Bin"** / "Những ngày đi học, những chuyến đi, những điều con tự hào."
3. **"Kỷ niệm gần đây"** — "Tháng này · 15 ảnh · 2 nhật ký" — "Xem tất cả"; 3 photos; **secondary** button **"Viết nhật ký hôm nay"**.
4. **"Nhắc nhở"** — "2 sắp tới" — "Tất cả"; "Đóng học phí học kỳ" · "5/11"; "Tiêm nhắc bạch hầu – uốn ván" · "Tháng 12".
5. **"Chi tiêu tháng này"** — "Tháng 10 · 9 khoản" — "Thêm"; **"4.800.000 ₫"**; bar (217.7 / 31.1 / 62.2); "Giữ trẻ & học · Y tế & tiêm chủng · Khác".
6. **"Tăng trưởng"** — "Đo lần cuối 4 tháng trước" — "Ghi số đo"; **"31 kg · 134 cm"**.
7. "Tuỳ chỉnh Hôm nay". Lumi · FAB · Nav.

### AX14 · Tuỳ chỉnh Hôm nay (Na 4 tuổi) `912:12365`
No nav, no Lumi/FAB (full-screen modal, inferred from the close icon).
1. Top: close button (`surface` circle, `Icon/close` 20; layer "back") · spacer · **"Xong"** Bold 15 `mint-text`.
2. **"Tuỳ chỉnh Hôm nay"** (Bold 26) / "Sắp xếp, ghim hoặc ẩn. Gợi ý dựa trên tuổi của Na và mục tiêu bạn chọn."
3. Label Bold 13 `ink-muted` **"Mục tiêu của gia đình"**; chips (`mint-soft`, `mint-text`, SemiBold 12, `px 12 py 6`, radius 999): **"Lưu giữ kỷ niệm"**, **"Chi tiêu cho con"**, **"Cả nhà cùng xem"**, and a `surface-2` chip **"Sửa"** with `Icon/edit` 12 (opens goal editing, inferred = AX04 content).
4. Label **"Đang hiện"**; group of rows, each: drag handle (`Icon/grid` 16 `ink-muted`) · title · optional subtitle · `Icon/bookmark` 16 (pin; filled/dark = pinned, outline = not) · Toggle (on = `mint-deep` track):
   - **"Lưu khoảnh khắc hôm nay"** — "Ghim · luôn ở đầu" — bookmark **filled** — on
   - **"Tạo từ kỷ niệm"** — "Video, thiệp" — on
   - **"Chi tiêu tháng này"** — "Theo mục tiêu "Chi tiêu cho con"" — on
   - **"Nhắc nhở"** — on
   - **"Cả nhà cùng xem"** — on
5. Label **"Đã ẩn"**; rows with toggle **off**:
   - **"Ghi nhanh: ngủ, tã"** — "Ẩn theo gợi ý tuổi · bật lại bất cứ lúc nào"
   - **"Tăng trưởng"**
6. Centred link SemiBold 14 `mint-text` **"Khôi phục gợi ý theo tuổi của Na"**.

Behaviour implied: drag to reorder within "Đang hiện"; pin keeps a widget first ("luôn ở đầu"); the toggle moves a row between "Đang hiện" and "Đã ẩn"; subtitles explain *why* a widget is there ("Theo mục tiêu …") or hidden ("Ẩn theo gợi ý tuổi"). Whether hidden rows keep their pin state is not shown (bookmark drawn on hidden rows too).

---

## Khám phá

### AX20 · Khám phá · 0–1 tuổi (Teddy) `912:12492`
1. Switcher "Teddy · 2 tháng" (no Đêm pill on Khám phá).
2. **"Khám phá"** (Bold 26).
3. Search field (component Field, empty zero-width label): `surface`, 1 px `control-border #7e959a`, radius 14, `px 14 py 13`, `Icon/search` 18, placeholder Medium 15 `ink-muted` **"Tìm tính năng, ví dụ: tiêm, chi tiêu, sơ cứu"**.
4. Section **"Gợi ý cho Teddy lúc này"** (layer ≠ text: "Section · Hợp với Teddy lúc này"); group:
   - **"Theo dõi bú, ngủ, tã"** — "Ghi nhanh, hẹn giờ ngủ, hút sữa"
   - **"Thống kê & lịch sử"** — "Bú, ngủ, tã theo ngày"
   - **"Tăng trưởng"** — "Cân nặng, chiều cao"
   - **"Tiêm chủng"** — "Lịch mũi tiêm của con"
5. Section **"Dùng suốt hành trình của con"**; group:
   - **"Kỷ niệm & album"** — "Ảnh, video, nhật ký"
   - **"Video & thiệp kỷ niệm"** — "Tạo từ ảnh bạn chọn"
   - **"Tự lưu kỷ niệm"** — "Gợi ý ảnh có Teddy từ thư viện máy" — badge **"Beta"** (`sunshine #ffd166`, SemiBold 11 `ink`, `px 8 py 3`)
   - **"Chi tiêu cho con"** — "Theo tháng, danh mục, người chi"
   - **"Nhắc nhở"** — "Việc của bé, nhắc cả nhà"
   - **"Gia đình & chia sẻ"** — "Thành viên, vai trò, lời mời"
   - **"Lumi"** — "Hỏi, ghi nhanh bằng một câu nhắn"
6. Section **"An toàn"**; **"Sơ cứu trẻ em"** — "25 tình huống · gọi 115 một chạm".
7. Card **"Cùng con lớn lên"** (white, **1 px dashed** `separator #dce8e7`, radius 20, `Icon/star` on `surface-2`) — "Đang phát triển · chưa có trong app"; body "Child Life đang xây thêm cho các chặng 1–3, 3–6 và 6–12 tuổi. Mọi kỷ niệm, chi tiêu và lịch sử của Teddy vẫn được giữ trọn."; chips "1–3 tuổi" "3–6 tuổi" "6–12 tuổi" (`surface-2`); secondary button **"Báo tôi khi có"**.
8. Lumi (no FAB) · Nav (Khám phá active; Hôm nay is a prototype link).

### AX21 · Khám phá · 3–6 tuổi (Na) `912:12697`
1. Switcher "Na · 4 tuổi". **"Khám phá"**.
2. Search placeholder **"Tìm tính năng, ví dụ: chi tiêu, tiêm, kỷ niệm"** (examples re-ordered by age).
3. **"Gợi ý cho Na lúc này"**: "Kỷ niệm & album" — "Ảnh, video, nhật ký"; "Video & thiệp kỷ niệm" — **"Sinh nhật, ngày đầu đi học…"**; "Chi tiêu cho con" — **"Giữ trẻ & học, quần áo…"**; "Nhắc nhở" — **"Lịch học, khám, tiêm nhắc"**.
4. **"Sức khoẻ & an toàn"**: "Tăng trưởng" — "Cân nặng, chiều cao"; "Tiêm chủng" — **"Mũi nhắc theo lịch"**; "Sơ cứu trẻ em" — **"Hướng dẫn cho trẻ từ 1 tuổi"**.
5. **"Gia đình & trợ lý"**: "Gia đình & chia sẻ" — **"Ông bà xem kỷ niệm được chia sẻ"**; "Lumi" — **"Hỏi về lịch, kỷ niệm, chi tiêu của Na"**; "Tự lưu kỷ niệm" — "Gợi ý ảnh có Na từ thư viện máy" — "Beta".
6. **"Theo dõi chăm sóc"** (layer ≠ text: "Section · Công cụ cho em bé"): "Theo dõi bú, ngủ, tã" — "Ghi nhanh, hẹn giờ ngủ, hút sữa"; "Thống kê & lịch sử" — "Bú, ngủ, tã theo ngày".
7. "Cùng con lớn lên" card, same copy with "của Na"; "Báo tôi khi có".
8. Lumi · Nav (Khám phá).

**Khám phá rule (inferred from AX20/AX21):** the same full V1 catalogue in every age; only the top "Gợi ý cho {tên} lúc này" group, the section grouping/names, row subtitles and search examples change. Baby tools are never removed, they move down ("Theo dõi chăm sóc"). Explore has no "Tiện ích"/"Chăm sóc" split any more (replaces the R1–R5 dock of `21-care-utilities-tabs.md`).

---

## Onboarding (thêm bé ở mọi độ tuổi)

### AX01 · Thêm bé · thông tin cơ bản `913:12522`
1. Back · **"Bước 1/4"** · (blank).
2. **"Giới thiệu về bé nhé"** / "Child Life dùng ngày sinh để gợi ý những gì hợp với con lúc này."
3. Photo picker: 64 circle, `surface`, **dashed** `control-border`, `Icon/camera` 22 · **"Ảnh của bé"** SemiBold 15 / "Tuỳ chọn · thêm sau cũng được".
4. Field **"Tên gọi"** — value "Teddy" — help "1–40 ký tự".
5. Field **"Ngày sinh"** — `Icon/cake` — "17/08/2026" — help **"Teddy được 2 tháng 6 ngày"** (live age).
6. Field **"Múi giờ"** — "Việt Nam (GMT+7)" — chevron-right (picker).
7. Bottom bar **"Tiếp tục"**.
Fields: label SemiBold 13 `ink-muted`, box `surface` 1 px `control-border` radius 14 `px 14 py 13`, value Medium 15 `ink`, help Medium 12 `ink-muted`.

### AX02 · Thêm bé · tuổi ngoài năm đầu (Na 4 tuổi) `913:12570`
1. Back · **"Bước 1/3"**.
2. **"Giới thiệu về bé nhé"** (no sub-line here).
3. Avatar Na 64 · "Ảnh của bé" / "Tuỳ chọn · thêm sau cũng được".
4. **"Tên gọi"** "Na" (no "1–40 ký tự" help). **"Ngày sinh"** "12/03/2022" — "Na được 4 tuổi 7 tháng". **No "Múi giờ" field** (see Q).
5. Info card (`mint-soft`, radius 20, `p 14`, gap 10; layer "Info · mọi tính năng mở cho mọi tuổi"): Bold 14 **"Mọi tính năng của Child Life đều dùng được cho Na."**; Medium 13 `ink-muted` "Gợi ý cho tuổi của Na — bạn sẽ thấy trước trên Hôm nay:"; white chips "Kỷ niệm & album", "Video & thiệp", "Chi tiêu", "Nhắc nhở", "Tăng trưởng", "Tiêm chủng"; Medium 12 "Theo dõi bú, ngủ, tã, sơ cứu, Lumi… luôn có trong Khám phá khi bạn cần."
6. **"Tiếp tục"**.

### AX03 · Mục tiêu gia đình · 0–1 tuổi (Teddy) `913:12628`
1. Back · **"Bước 2/4"** · **"Bỏ qua"**.
2. **"Bạn muốn Child Life giúp gì cho Teddy?"** / Medium 13 "Chọn tất cả những gì bạn quan tâm · đổi được bất cứ lúc nào".
3. Goal rows (cards `surface` radius 16 `px 14 py 12`; **selected = 2 px `mint-deep` border + filled `mint-deep` checkbox 20 radius 7 with `Icon/check`**; unselected = 1.5 px `control-border` empty box). Pre-selected rows carry a badge (`sunshine-soft`, SemiBold 10 `ink`, `px 8 py 2`) **"Gợi ý cho 2 tháng"** above the title:
   - ✓ "Gợi ý cho 2 tháng" **"Theo dõi bú, ngủ, tã"** — "Ghi nhanh và xem nhịp của con"
   - ✓ "Gợi ý cho 2 tháng" **"Lưu giữ kỷ niệm"** — "Ảnh, video, nhật ký, thiệp"
   - ☐ **"Tăng trưởng & tiêm chủng"** — "Số đo, lịch tiêm"
   - ☐ **"Cả nhà cùng chăm & cùng xem"** — "Mời ba/mẹ, ông bà, người chăm"
   - ☐ **"Chi tiêu cho con"** — "Biết tiền đã chi vào đâu"
   - ☐ **"Nhắc nhở việc của bé"** — "Không quên việc quan trọng"
4. Centred SemiBold 13 `mint-text` **"Đã chọn 2 mục"**.
5. **"Tiếp tục"**.

### AX04 · Mục tiêu gia đình · 3–6 tuổi (Na) `913:12715`
1. Back · **"Bước 2/3"** · "Bỏ qua".
2. **"Bạn muốn Child Life giúp gì cho Na?"** / same sub-line.
3. Same 6 goals **re-ordered by suggestion**, badge **"Gợi ý cho 4 tuổi"**:
   - ✓ "Lưu giữ kỷ niệm" · ✓ "Chi tiêu cho con" · ✓ "Cả nhà cùng chăm & cùng xem" · ☐ "Tăng trưởng & tiêm chủng" · ☐ "Nhắc nhở việc của bé" · ☐ "Theo dõi bú, ngủ, tã" (layer ≠ text: "Row · Theo dõi ngủ, tã"; icon `Icon/sleep` on `care-sleep-soft` instead of the feed icon).
4. **"Đã chọn 3 mục"**. "Tiếp tục".

### AX05 · Chọn theo dõi · khi chọn mục tiêu chăm sóc `913:12802`
1. Back · **"Bước 3/4"** · (no "Bỏ qua").
2. **"Bạn muốn ghi những gì cho Teddy?"** / "Chỉ hiện những ô bạn chọn trên Hôm nay. Đổi lại trong Hồ sơ › Tuỳ chỉnh theo dõi."
3. Group of toggle rows (icon chip + title + Toggle):
   - **"Bú bình"** on · **"Bú mẹ"** on · **"Hút sữa"** **off** · **"Ngủ"** on · **"Tã"** on · **"Tăng trưởng"** on
4. **"Tiếp tục"**.
Shown only when "Theo dõi bú, ngủ, tã" is a selected goal (frame name). Step 4/4 for Teddy (the 0–1 version of AX06) is **not drawn**.

### AX06 · Gợi ý Hôm nay · Na 4 tuổi `913:12873`
1. Back · **"Bước 3/3"**.
2. **"Hôm nay của Na sẽ ưu tiên"** / "Dựa trên tuổi của Na và mục tiêu bạn chọn."
3. Ordered group; each row: rank pill (`mint-soft`, Bold 14 `mint-text`, `px 10 py 4`) · title · "Vì: …" reason · drag handle `Icon/grid` 16 (trailing):
   1. **"Lưu khoảnh khắc hôm nay"** — "Vì: Lưu giữ kỷ niệm"
   2. **"Tạo video, thiệp từ kỷ niệm"** — "Vì: Lưu giữ kỷ niệm"
   3. **"Chi tiêu tháng này"** — "Vì: Chi tiêu cho con"
   4. **"Cả nhà cùng xem"** — "Vì: Cả nhà cùng chăm & cùng xem"
   5. **"Nhắc nhở"** — "Vì: Luôn có"
4. Banner (`surface-2`, radius 14, `Icon/sliders` 16): "Kéo để đổi thứ tự. Sửa bất cứ lúc nào trong "Tuỳ chỉnh Hôm nay"."
5. Primary **"Vào Hôm nay của Na"**.

**Step counts:** 0–1 with a care goal = 4 steps (info → goals → tracking → preview); 3–6 = 3 (info → goals → preview). The count must be computed from the chosen goals (AX05 depends on the care goal, not on age).

---

## Đổi bé, nhiều độ tuổi, chuyển giai đoạn, Hồ sơ

### AX30 · Chọn bé (switcher) `914:12633`
Background: Teddy Today (switcher "Teddy · 2 tháng", "Đêm", "Chào buổi sáng, Teddy ☀️", tiles Bú bình "2 giờ trước", Ngủ "42 phút", Tã "1 giờ trước"), Lumi, FAB, nav; **scrim** `scrim rgba(12,23,25,.32)` over all.
Bottom sheet (`surface`, top radii 28, `px 16 pb 34`, gap 10, y 305; `SheetHeader`: grabber 40 × 5 `separator`, title SemiBold 24/32 **"Chọn bé"**, close 44 "Đóng"):
- Selected row (`mint-soft` fill, radius 16, `px 12 py 10`): avatar 44 · **"Teddy · 2 tháng"** / "Bạn: Mẹ · quản lý hồ sơ" · filled check.
- **"Na · 4 tuổi"** / "Bạn: Mẹ · quản lý hồ sơ" (prototype link → AX31).
- **"Bin · 9 tuổi"** / "Bạn: Mẹ · quản lý hồ sơ".
- Label Bold 12 `ink-muted` **"Bạn được mời vào"**.
- **"Bơ · 2 tuổi"** / **"Người thân · chỉ xem kỷ niệm được chia sẻ"** · chevron-right (prototype link → AX32).
- Disabled row (text `ink-muted`, `surface-2` chip with `Icon/plus`): **"Thêm bé"** / **"Đã đủ 3 hồ sơ bạn quản lý (giới hạn Beta)"**.

**Note · AX30** `914:12751`: "Mỗi bé là một ngữ cảnh riêng: Hôm nay, Kỷ niệm, Khám phá xếp lại theo tuổi + mục tiêu của bé đó. Vai trò hiển thị ngay dưới tên. Thứ tự: bé bạn quản lý (theo tuổi tăng dần) rồi bé bạn được mời."

### AX31 · Đang chuyển sang Na `914:12753`
- Switcher already "Na · 4 tuổi"; body = 4 `surface-2` skeleton blocks radius 20 (h 34, 220, 150, 150); no greeting.
- Toast (dark `ink #173d44`, radius 16, `px 16 py 12`, centred at y 690, above the nav): avatar 22 + SemiBold 14 white **"Đang xem Na · 4 tuổi"**.
- Lumi · FAB · nav (Hôm nay kept).

**Note · AX31** `914:12801`: "Đổi bé: xoá ngay nội dung của bé cũ, hiện tên/ảnh bé mới rồi mới tải dữ liệu (theo brief). Giữ nguyên tab đang mở nếu vai trò cho phép. Hiệu ứng: crossfade 200 ms, không trượt cả màn."

### AX32 · Đổi sang bé mà bạn là Người thân (Bơ) `914:12803`
- Switcher "Bơ · 2 tuổi".
- **"Kỷ niệm của Bơ"** / "Những khoảnh khắc ba mẹ Bơ chia sẻ với gia đình."
- Banner (`mint-soft`, radius 14, `Icon/eye` 16, Medium 13 `mint-text`): **"Bạn là Người thân của Bơ: xem và thả tim kỷ niệm được chia sẻ. Không xem lịch sử chăm sóc."**
- 2 rows × 3 photos 108 × 108 radius 12 (no heart affordance drawn).
- Nav **Role=Relative**: "Kỷ niệm" (active) · "Hồ sơ". **No Lumi, no FAB.**

**Note · AX32** `914:12844`: "Vai trò quyết định tab: Người thân chỉ có Kỷ niệm · Hồ sơ (không Hôm nay, Khám phá, Lumi). Người chăm bé: Hôm nay · Khám phá (công cụ chăm sóc, sơ cứu) · Hồ sơ. Tab ẩn không thay cho kiểm tra quyền."

### AX33 · Teddy tròn 1 tuổi · gợi ý sắp xếp lại `914:12846`
1. Switcher **"Teddy · 12 tháng"** · "Đêm".
2. Card (`sunshine-soft`, radius 20, `p 16`, gap 12; layer "Gợi ý · chuyển giai đoạn"): "🎂" (20) + Bold 17 **"Teddy tròn 1 tuổi rồi!"**; Medium 13 `ink` "Nhiều gia đình bớt ghi bú từ lúc này. Muốn Hôm nay gọn hơn không?"; three pre-checked options (filled `mint-deep` check + Medium 13):
   - ☑ **"Đưa Kỷ niệm lên đầu Hôm nay"**
   - ☑ **"Ẩn Bú bình khỏi Ghi nhanh · vẫn có trong Khám phá"**
   - ☑ **"Giữ Ngủ, Tã trong Ghi nhanh"**
   - buttons side by side: primary **"Áp dụng"** (h56) · secondary **"Giữ như cũ"** (h52).
3. **"Nhịp hôm nay"** · "Xem lịch sử"; tiles Bú bình "sáng nay 7:00" · Ngủ "trưa 1 giờ 30" · Tã "9:10".
4. (No other widgets drawn.) Lumi · FAB · nav.

**Note · AX33** `914:12956`: "Không tự ẩn hay chuyển dữ liệu khi bé sang giai đoạn mới — chỉ đề xuất, một lần cho mỗi mốc (12, 36, 72 tháng). Lịch sử bú vẫn xem được. Hoàn tác trong Tuỳ chỉnh Hôm nay."

### AX34 · Hồ sơ (tab) `914:12958`
1. Me row: avatar 56 "M" (`#ffdbcc`, Bold 20) · Bold 20 **"Mai"** / Medium 13 **"Mẹ · quản lý hồ sơ Teddy, Na, Bin"**. (No child switcher on Hồ sơ.)
2. **"Các bé"** · link **"Thêm"**; group: avatar 36 · **"Teddy"** — "2 tháng · mục tiêu & Hôm nay"; **"Na"** — "4 tuổi · mục tiêu & Hôm nay"; **"Bin"** — "9 tuổi · mục tiêu & Hôm nay". (Bơ, the invited child, is not listed.)
3. **"Gia đình"**: **"Thành viên & chia sẻ"** — "5 người · vai trò, lời mời"; **"Mời người thân"** (`Icon/plus`) — "Ông bà xem kỷ niệm được chia sẻ".
4. **"Cài đặt"** (icon chips `surface-2`): **"Tuỳ chỉnh theo dõi"** (`Icon/sliders`) — "Theo từng bé"; **"Thông báo"** (`Icon/clock`) — "Nhắc nhở, kỷ niệm, giờ yên lặng"; **"Dung lượng"** (`Icon/cloud-off`) — "3,4 / 10 GB"; **"Hỗ trợ & dữ liệu"** (`Icon/alert`) — "Xuất dữ liệu, xoá tài khoản".
5. Lumi (no FAB) · nav (Hồ sơ active).
Not on this screen: Premium/Gói, Góp ý (FB1), phiên bản (UP6), Night care schedule, language, sign-out — see Q.

---

## Empty states (lần đầu)

### AX40 · Hôm nay · lần đầu · 0–1 tuổi (Teddy) `915:12765`
1. Switcher "Teddy · 2 tháng" · "Đêm".
2. **"Chào Teddy 👋"** / "Bắt đầu bằng một việc nhỏ — không cần mời ai trước."
3. Section **"Ghi hoạt động đầu tiên"**; tiles Bú bình / Ngủ / Tã — each "Chưa ghi" + pill **"Ghi lần đầu"**.
4. Widget **"Lưu khoảnh khắc đầu tiên"** (`Icon/camera`) — "Ảnh hoặc vài dòng về hôm nay"; illustration block `peach-soft` h 120 radius 16 with "👶" 44; primary **"Thêm khoảnh khắc"**.
5. Widget **"Nhắc nhở"** — "Chưa có nhắc nhở nào"; secondary **"Tạo nhắc nhở đầu tiên"**.
6. Lumi · FAB · nav. (No "Tuỳ chỉnh Hôm nay" link on empty Today.)

**Note · AX40** `915:12878`: "Theo brief: Hôm nay mở với "Ghi hoạt động đầu tiên" và "Lưu khoảnh khắc đầu tiên", không bắt mời người. Hỏi quyền thông báo sau khi tạo nhắc đầu tiên; quyền ảnh khi chọn ảnh."

### AX41 · Hôm nay · lần đầu · 1–3 tuổi (Bơ) `915:12880`
1. Switcher "Bơ · 2 tuổi".
2. **"Chào Bơ 👋"** / "Bắt đầu lúc nào cũng kịp — giữ lại từ hôm nay, tìm lại cả những ngày đã qua."
3. **"Lưu khoảnh khắc đầu tiên của Bơ"** — "Ảnh, video hoặc nhật ký"; "🧸"; **"Thêm khoảnh khắc"**.
4. **"Tìm lại ảnh của Bơ từ thư viện máy"** (`Icon/spark`, `mint-soft`) — **"Tự lưu kỷ niệm · Beta miễn phí"**; body "Gợi ý ảnh, video có Bơ kể cả những năm trước. Bạn duyệt trước, không tự tải lên."; secondary **"Thiết lập · 1 phút"**.
5. **"Ghi nhanh"**; tiles **"Ngủ"** and **"Tã"** — "Chưa ghi" / "Ghi lần đầu". (Here "Ngủ", not "Ngủ trưa" as in AX11.)
6. Lumi · FAB · nav (Parent).

**Note · AX41** `915:12976`: "Ghi nhanh chỉ hiện khi đã bật trong "Chọn theo dõi" (mục tiêu chăm sóc). Không hiện bú/hút sữa cho 1–3 tuổi trừ khi gia đình tự bật."

### AX42 · Hôm nay · lần đầu · 3–6 tuổi (Na) `915:12978`
1. Switcher "Na · 4 tuổi".
2. **"Chào Na 👋"** / "Mỗi khoảnh khắc là một câu chuyện. Bắt đầu từ hôm nay nhé."
3. **"Lưu khoảnh khắc đầu tiên của Na"** — "Một bức vẽ, một buổi đi chơi, một câu nói ngộ nghĩnh"; "🎨"; **"Thêm khoảnh khắc"**.
4. **"Tìm lại ảnh của Na từ thư viện máy"** — "Tự lưu kỷ niệm · Beta miễn phí"; "Gợi ý ảnh, video có Na kể cả những năm trước. Bạn duyệt trước, không tự tải lên."; **"Thiết lập · 1 phút"**.
5. **"Chi tiêu cho Na"** (`Icon/drop`) — "Chưa có khoản chi nào"; secondary **"Ghi khoản chi đầu tiên"**.
6. **"Cả nhà cùng xem"** — **"Chỉ mình bạn trong gia đình của Na"**; secondary **"Mời người thân"**.
7. Lumi · FAB · nav.

### AX43 · Hôm nay · lần đầu · 6–12 tuổi (Bin) `915:13078`
1. Switcher "Bin · 9 tuổi".
2. **"Chào Bin 👋"** / "Cùng lưu lại hành trình đi học, những chuyến đi và điều con tự hào."
3. **"Bắt đầu cuốn nhật ký của Bin"** (`Icon/camera`) — "Ảnh, video hoặc vài dòng về hôm nay"; "📒"; primary **"Viết nhật ký hôm nay"**; centred link SemiBold 14 `mint-text` **"Hoặc thêm ảnh"**.
4. **"Tìm lại ảnh của Bin từ thư viện máy"** — "Tự lưu kỷ niệm · Beta miễn phí"; "Gợi ý ảnh, video có Bin kể cả những năm trước. Bạn duyệt trước, không tự tải lên."; **"Thiết lập · 1 phút"**.
5. **"Nhắc nhở"** — **"Lịch học, khám răng, tiêm nhắc…"**; **"Tạo nhắc nhở đầu tiên"**.
6. **"Chi tiêu cho Bin"** — "Chưa có khoản chi nào"; **"Ghi khoản chi đầu tiên"**.
7. Lumi · FAB · nav.

### AX44 · Kỷ niệm · trống (Na) `915:13175`
1. Switcher "Na · 4 tuổi".
2. **"Kỷ niệm"** (Bold **28**, vs 26 elsewhere).
3. Card (`surface`, radius 24, `px 20 py 28`, centred): "🖼️" 56; Bold 18 **"Chưa có kỷ niệm nào của Na"**; Medium 13 `ink-muted` **"Thêm ảnh, video hoặc vài dòng nhật ký. Mặc định chỉ ba mẹ thấy."**
4. Primary **"Thêm kỷ niệm"**; secondary **"Tìm lại ảnh cũ của Na · Beta"**.
5. Lumi · FAB · nav (Kỷ niệm active).

### AX45 · Khám phá · tìm chưa có (Na) `915:13229`
1. Switcher "Na · 4 tuổi". **"Khám phá"** (Bold 28).
2. Search field with typed value **"học tập"** (Medium 15 `ink`) and a clear `Icon/close` 16.
3. No-result card (`surface`, radius 20, `px 20 py 24`, centred): "🌱" 40; Bold 17 **"Chưa có tính năng học tập"**; Medium 13 **"Child Life đang phát triển thêm cho trẻ 3–6 tuổi. Hiện bạn có thể lưu bức vẽ, bài làm của Na vào Kỷ niệm."**
4. Secondary **"Lưu vào Kỷ niệm"**; centred link **"Báo tôi khi có"**.
5. Lumi (no FAB) · nav (Khám phá).

**Note · AX45** `915:13289`: "Trung thực: không giả vờ có chức năng. Gợi ý đường dùng được ngay bằng chức năng V1. "Báo tôi khi có" ghi nhận quan tâm theo nhóm tuổi (analytics, không thông báo marketing nếu chưa đồng ý)."

---

## Navigation graph

Solid = prototype link seen in the code; *(inferred)* = from labels/layout.

```
Onboarding (thêm bé)
  AX01/AX02 Thông tin cơ bản ──Tiếp tục──▶ AX03/AX04 Mục tiêu (Bỏ qua → skip goals, inferred: age defaults)
  AX03 ──Tiếp tục [goal "Theo dõi bú, ngủ, tã" chosen]──▶ AX05 Chọn theo dõi ──▶ (step 4/4 Gợi ý Hôm nay, not drawn)
  AX04 ──Tiếp tục [no care goal]──▶ AX06 Gợi ý Hôm nay ──"Vào Hôm nay của Na"──▶ AX12 (or AX42 when empty, inferred)
  Back on each step → previous step (inferred)

Tabs (Parent): Hôm nay (AX10–AX13, AX40–AX43, AX33) · Kỷ niệm (AX44) · Khám phá (AX20, AX21, AX45) · Hồ sơ (AX34)
  Caregiver: Hôm nay · Khám phá · Hồ sơ       Relative: Kỷ niệm (AX32) · Hồ sơ
  Lumi button → Trợ lý chat (31-chat-assistant.md)        FAB + → quick add (inferred, not drawn)

Hôm nay
  Child switcher ──▶ AX30 sheet "Chọn bé"
      row managed child (Na) ──▶ AX31 skeleton + toast "Đang xem Na · 4 tuổi" ──▶ AX12 (same tab kept)
      row invited child (Bơ, Người thân) ──▶ AX32 (tab forced to Kỷ niệm: Hôm nay not allowed)
      "Thêm bé" (disabled at 3) ──▶ AX01 (inferred, when allowed)
  "Tuỳ chỉnh Hôm nay" ──▶ AX14 (X / "Xong" → back; "Sửa" goals → goal editor ≈ AX04, inferred)
  "Xem lịch sử" / "Lịch sử" ──▶ care history (inferred)   "Tất cả" ──▶ reminders   "Xem tất cả" ──▶ Kỷ niệm
  "Ghi số đo" ──▶ growth entry   "Thêm" (Chi tiêu) ──▶ add expense   "Thêm khoảnh khắc" ──▶ add moment
  "Mời người thân" ──▶ invite   "Thiết lập · 1 phút" ──▶ Tự lưu setup (27-auto-save.md)
  Stage card (AX33) "Áp dụng" ──▶ re-ordered Today; "Giữ như cũ" ──▶ dismiss for this milestone

Khám phá rows ──▶ each module; "Báo tôi khi có" ──▶ records interest (no navigation)
  search no result (AX45) "Lưu vào Kỷ niệm" ──▶ add moment
Hồ sơ: child row ──▶ per-child "mục tiêu & Hôm nay" (not drawn); "Thêm" ──▶ AX01; "Tuỳ chỉnh theo dõi" ──▶ AX05-like screen (not drawn);
  "Thành viên & chia sẻ" / "Mời người thân" / "Thông báo" / "Dung lượng" / "Hỗ trợ & dữ liệu" ──▶ existing screens
```

## Consolidated cross-screen rules

1. **One nav, role-shaped** (AX00, AX32 note, NavBar v2): Parent 4 tabs Hôm nay · Kỷ niệm · Khám phá · Hồ sơ; Caregiver 3 (no Kỷ niệm); Relative 2 (no Hôm nay, Khám phá, Lumi). Hidden tabs never replace server-side permission checks.
2. **Lumi is a floating button outside the tab bar**, 12 px above the FAB; FAB only on Hôm nay and Kỷ niệm (drawn pattern). Relative: no Lumi.
3. **No feature locked by age**; age + goals only order suggestions and set "Gợi ý cho …" labels (AX00, AX02 info card, AX20/21).
4. **Honesty**: only released V1 features are suggested; future stages appear only as the dashed "Cùng con lớn lên · Đang phát triển · chưa có trong app" card and in no-result search (AX45), with "Báo tôi khi có" recorded as analytics interest per age group, no marketing push without consent.
5. **Widget ranking** = goal 35% + age 25% + usage frequency 20% + recent activity 10% + product priority 10% (initial weights for experiment). **Hard constraints** override the score: released feature only; pinned stays put ("Ghim · luôn ở đầu"); hidden never comes back by itself; missing data → age + goal defaults.
6. **Per-child context**: goals, Today layout (order, pins, hidden) and tracked activities are stored per child; switching child clears old content immediately, shows the new name/photo, then loads (skeleton + toast), crossfade 200 ms, keeps the current tab if the role allows.
7. **Switcher order**: managed children by age ascending, then invited children under "Bạn được mời vào"; role shown under each name ("Bạn: Mẹ · quản lý hồ sơ", "Người thân · chỉ xem kỷ niệm được chia sẻ").
8. **Beta limit**: 3 managed child profiles per person ("Đã đủ 3 hồ sơ bạn quản lý (giới hạn Beta)").
9. **Age** from date of birth in the child's time zone; shown as "2 tháng" / "12 tháng" / "2 tuổi" / "4 tuổi"; onboarding helper "được 2 tháng 6 ngày" / "4 tuổi 7 tháng"; no "age mode" picker.
10. **Stage transition**: suggest once per milestone at 12, 36, 72 months; never auto-hide or move data; options pre-checked; "Áp dụng" / "Giữ như cũ"; undo through Tuỳ chỉnh Hôm nay; history always kept.
11. **Quick log** shows only activities turned on in "Chọn theo dõi" (care goal); 1–3 never gets bú/hút sữa unless the family turns them on; 3–6 and 6–12 have no quick log by default.
12. **Onboarding**: goals pre-selected by age with "Gợi ý cho {tuổi}" badge, multi-select, skippable ("Bỏ qua"), editable later; tracking step only with the care goal; preview step explains each widget's reason ("Vì: …", "Vì: Luôn có" for Nhắc nhở) and allows drag reorder.
13. **First run**: Today starts with the first log / first moment, never forces invites; notification permission after the first reminder; photo permission when choosing a photo.
14. **Privacy defaults**: new memories visible to parents only ("Mặc định chỉ ba mẹ thấy"); Tự lưu proposes photos, the parent reviews first, no automatic upload.
15. **Relative** sees and hearts shared memories only, never care history.

## Data the screens imply

- **Child profile**: `name` (1–40), `birthDate`, `timeZone` (AX01; e.g. "Việt Nam (GMT+7)"), optional `photo`. Derived age bucket `0–1 | 1–3 | 3–6 | 6–12` and display age.
- **Per-child goals** (multi-select, ordered by suggestion): `trackCare` ("Theo dõi bú, ngủ, tã"), `memories` ("Lưu giữ kỷ niệm"), `growthVaccines` ("Tăng trưởng & tiêm chủng"), `family` ("Cả nhà cùng chăm & cùng xem"), `spending` ("Chi tiêu cho con"), `reminders` ("Nhắc nhở việc của bé"); plus `goalsSetAt`/`skipped` (inferred from "Bỏ qua"). Whose goals — per person or shared by the family for that child — is open (Q).
- **Per-child tracked activities** (AX05, Hồ sơ › Tuỳ chỉnh theo dõi "Theo từng bé"): `bottle`, `breast`, `pump`, `sleep`, `diaper`, `growth` booleans.
- **Per-child Today layout** (AX14, AX06): ordered widget ids (`moment_today`, `create_from_memories`, `spending_month`, `reminders`, `family_view`, `quick_log`, `recent_memories`, `growth`, `rhythm_today`…), `pinned` set, `hidden` set, provenance per widget (`goal:<id>` / `age` / `always`) for the "Vì: …" / "Theo mục tiêu …" / "Ẩn theo gợi ý tuổi" subtitles, and a "restore age defaults" action.
- **Ranking inputs**: per-child usage frequency and recent activity per module; product priority (config, likely `config/limits` or a new `config/adaptive` mirrored to `publicConfig/*`, inferred).
- **Stage-transition prompt state** per child: milestones 12/36/72 months each `shown`/`applied`/`kept` with timestamp, so it is offered once; which options were applied (for undo).
- **"Báo tôi khi có" interest**: analytics event with age group and source (Khám phá card / search term), no child data; marketing consent separate.
- **Switcher**: list of children with the viewer's role per child, managed vs invited; per-person count of managed profiles vs Beta limit 3.
- **Feature flags** (inferred): Tự lưu "Beta" badge, "Beta miễn phí" copy; Sơ cứu availability by environment (D-058).

## Open questions and inconsistencies

1. **AX06 order vs matrix/AX12/AX14**: AX06 ranks 4 "Cả nhà cùng xem", 5 "Nhắc nhở"; AX00, AX12 and AX14 put Nhắc nhở 4th and Cả nhà 5th. Which is right?
2. **Goal name drift**: onboarding goal "Cả nhà cùng chăm & cùng xem" (AX03/AX04/AX06) vs chip "Cả nhà cùng xem" (AX14) — same goal or the widget name? Matrix calls it "Cả nhà".
3. **AX41 contradicts its own note**: Bơ (1–3) preset goals (Lưu giữ kỷ niệm · Tăng trưởng & tiêm chủng) have no care goal, yet the empty Today shows Ghi nhanh Ngủ/Tã; note says Ghi nhanh only appears after "Chọn theo dõi". AX11 also shows "Ghi nhanh ngủ, tã (gợi ý)". Is 1–3 quick log a default suggestion or opt-in?
4. **AX14 "Ghi nhanh: ngủ, tã — Ẩn theo gợi ý tuổi"** for Na: is that a default-hidden row (consistent with "Không gợi ý sẵn") or an auto-hide (which rule 5/10 forbids)? Need the wording rule: hidden by default ≠ hidden later.
5. **AX10 has no "Bú mẹ" tile** though AX05 turns Bú mẹ on and the matrix lists "Bú bình, bú mẹ, ngủ, tã". Max tiles per row / overflow not specified.
6. **Sleep label**: "Ngủ trưa" (AX11, 1–3) vs "Ngủ" (AX41, 1–3, empty). Is the label age-dependent?
7. **AX02 has no "Múi giờ" field** and no "1–40 ký tự" help, while AX01 has both; rule 9 needs the child's time zone. Default to the device zone?
8. **Step counters**: AX01 "1/4" and AX02 "1/3" are decided on the first step, before goals are chosen — but the extra step depends on the goal (AX05 title). What does a 0–1 parent who unticks the care goal see? A 3–6 parent who ticks it?
9. **Step 4/4 for 0–1** (Gợi ý Hôm nay · Teddy) is not drawn; nor the goal editor behind "Sửa" (AX14) or the per-child "mục tiêu & Hôm nay" screen (AX34).
10. **Where goals live**: AX00 says "lưu theo từng bé"; is it per person × child (Mẹ and Ba different Today) or shared for the family? P-127 (business-map) made Today customisation per device — conflicts with per-child storage.
11. **Persona clash**: Bơ is a managed child in AX11/AX41 (Parent nav, "Tuỳ chỉnh Hôm nay") but an invited Người thân child in AX30/AX32/AX34. Fine as separate examples, but confirm a 1–3 managed child example.
12. **Ranking vs explicit order**: what happens when a user drags widgets (AX06/AX14) — does the score stop applying entirely, or only pinned items are fixed? Rule says only "ghim không bị di chuyển".
13. **Stage milestones**: 12, 36, 72 months only; nothing at 144 (12 tuổi) or after 12 years. What happens past 12 years (matrix ends at 6–12)? Also, AX33 is drawn at "12 tháng" — is the age display "12 tháng" or "1 tuổi" at exactly 1 year (title says "tròn 1 tuổi")?
14. **AX33 options are pre-checked** — is applying pre-checked changes acceptable as "đề xuất", and is the card dismissible without a choice? Where does it sit if Today has a pinned widget ("ghim không bị di chuyển" vs card at the top)?
15. **Night care**: no Night twin for any frame; the "Đêm" pill appears only for 0–1. Is Night care unavailable/hidden for older ages, or just not drawn? (Night care rules apply to tokens like `sunshine-soft` cards — see memory note on ink on soft warm fills.)
16. **Caregiver**: nav variant exists, but no Caregiver Today/Khám phá screen and no rule for what a caregiver's Today shows (goals are the parent's?). Does a caregiver see "Tuỳ chỉnh Hôm nay"? Lumi for caregivers (D-072 says caregivers may check in but not generate summaries)?
17. **Relative**: AX32 says "thả tim" but no heart is drawn; the Relative Hồ sơ tab is not drawn; can a relative switch to a managed child's Today via the switcher only if they manage one?
18. **Multiple children of different ages**: the switcher handles it, but there is no cross-child view (e.g. reminders for all children), and Lumi's scope when switching (per child?) is not stated. Push copy already names the baby (D-094).
19. **Offline / loading / error**: only the switch skeleton (AX31) is drawn; no offline Today, failed ranking load, or what Today shows before goals are known (rule: age defaults).
20. **FAB on Khám phá/Hồ sơ** is absent — intentional? Then quick add from those tabs goes only through Lumi.
21. **Hồ sơ content gaps**: no Premium/Gói (v2.0 PR03), Góp ý (FB1), app version (UP6), language, Night care schedule, sign-out, which today live in "Tôi". Is Hồ sơ the renamed Tôi, and where do these go?
22. **"Khám phá" name collision**: R-007's welcome tour button is also "Khám phá"; and the new tab replaces "Chăm sóc" + "Tiện ích" of the R1–R5 proposal (`21-care-utilities-tabs.md`). Confirm the R row is superseded.
23. **Sơ cứu subtitles differ by age**: "25 tình huống · gọi 115 một chạm" (Teddy, 2 months) vs "Hướng dẫn cho trẻ từ 1 tuổi" (Na). Is there infant-specific first aid, and is first aid shown on prod (D-058)?
24. **Beta limit "3 hồ sơ bạn quản lý"**: no such limit is recorded in `config/limits` / business map; is it per person or per family, and what about invited children?
25. **Raw colours**: avatar fills `#ffdbcc`, `#d1e5ff`, `#ede3ff` and note colours are hard-coded, not tokens; `care/pump/soft` uses a slash token name unlike the dashed others.
26. **"Báo tôi khi có"** has no confirmation state drawn (button after tap, toast, consent prompt for marketing).
27. **Search**: only a no-result state; no result list, no synonyms ("học tập" → nothing); what is searchable (feature names only, or content)?
28. **Kỷ niệm tab populated** for the adaptive IA is not drawn (only empty AX44); assume existing Kỷ niệm screens.
29. **Spending bar colours** reuse care accents (`care-sleep-accent`, `care-bottle-accent`, `care-diaper-accent`) for categories "Giữ trẻ & học", "Quần áo"/"Y tế & tiêm chủng", "Khác" — category→colour mapping should come from the spending categories (19-spending.md), not care tokens.
30. **English copy**: none in Figma; every string above needs an en draft for review (D-012).
