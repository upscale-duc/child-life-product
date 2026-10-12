# H2 · Admin portal v1.0 ("Child Life · Vận hành") — new screens and delta

Read-only transcription of Figma file `sJLG1fAXKDnDr9YI6Yx8ex`, canvas **"Admin portal" `253:18`**, section **"v1.0"**, made 2026-10-11 through the Figma MCP (`get_metadata` dump saved earlier, `get_design_context` on small containers and modals, `get_screenshot` of each frame's Main). No Figma node was modified. Rendered text is authoritative. Vietnamese copy is verbatim, followed by an English gloss in *(italics)*.

This file extends [`08-admin-portal.md`](08-admin-portal.md) (2026-10-10, A01–A12). It covers the new v1.0 frames (A01 variants, A13–A21, C01–C04), the new sidebar, and a delta for every frame 08 already transcribed. The v1.1 section (B01–B10) is listed at the end only.

**Layer names are not reliable here.** The metadata dump cuts text layer names at 30 characters, and at least one name is stale: A08 `260:666` is named "Hạn mức 10 GB · mở rộng theo y…" but renders "Hạn mức 10 GB". Every truncated string below was re-read with `get_design_context` or from a screenshot.

## How each frame was read

| Node | Name | Read method | Status |
|---|---|---|---|
| `253:467` | Admin/Sidebar (component set, 16 variants) | `get_design_context` on variant `253:19`; screenshot of the whole set (11 v1.0 variants visible) | Full for v1.0; v1.1 variants: names only (they sit outside the set's bounds, and a screenshot of `315:46970` came back 1×1 px) |
| `265:949` | A01 Đăng nhập · Mật khẩu | `get_design_context` whole frame | Full |
| `265:1044` | A01b Đăng nhập · Sai mật khẩu | `get_design_context` on card `265:1067`; brand panel has the same text as A01 (metadata diff) | Full |
| `265:1144` | A01c Đăng nhập · Link qua email | `get_design_context` on card `265:1167`; brand panel same as A01 | Full |
| `265:1228` | A01d Đăng nhập · Đã gửi link | `get_design_context` on card `265:1251`; brand panel same as A01 | Full |
| `407:3393` | A13 Phân tích · Tăng trưởng & giữ chân | `get_design_context` on Main `407:3483` (with screenshot) | Full |
| `407:50391` | A14 Phân tích · Tính năng | metadata text + `get_design_context` on `407:50528` + screenshot of Main `407:50481` | Full |
| `407:50747` | A15 Gia đình · Danh sách | metadata text + `get_design_context` on `407:50844` + screenshot of Main `407:50837` | Full |
| `408:3669` | A16 Gia đình · Chi tiết | metadata text + `get_design_context` on `408:3783`, `408:3976` + screenshot of Main `408:3759` | Full |
| `408:50672` | A17 Gia đình · Chuyển chủ gia đình | `get_design_context` on modal `408:50906` (with screenshot); background Main `408:50674` has the same text as A16 (metadata diff) | Full |
| `347:47483` | C01 Dữ liệu tham chiếu · Chiều dài | metadata text + `get_design_context` on `347:47589`, `347:47757`, `347:47762` + screenshot of Main `347:47579` | Full |
| `347:47796` | C02 Dữ liệu tham chiếu · Lượng sữa gợi ý | metadata text + `get_design_context` on `347:47918` + screenshot of Main `347:47892` | Full |
| `347:48046` | C03 Dữ liệu tham chiếu · Nhập CSV | `get_design_context` on modal `347:48275` (with screenshot); background Main `347:48048` has the same text as C01 | Full |
| `394:50015` | C04 Dữ liệu tham chiếu · Lịch tiêm chủng | metadata text + `get_design_context` on `394:50121`, `394:50346` + screenshot of panel `394:50138` | Full (tab-bar selection not rendered; see C04) |
| `408:51014` | A18 Nhân sự · Thành viên | metadata text + `get_design_context` on `408:51110`, `408:51340` + screenshot of Main `408:51104` | Full |
| `409:3977` | A19 Nhân sự · Vai trò & quyền | metadata text + `get_design_context` on `409:4077`, `409:4427` + screenshot of Main `409:4067` (whole matrix readable) | Full |
| `409:51027` | A20 Nhân sự · Mời thành viên | `get_design_context` on modal `409:51381` (with screenshot); background has the same text as A18 | Full |
| `409:51488` | A21 Nhân sự · Sửa vai trò | metadata text + `get_design_context` on `409:51592`, `409:51755` + screenshot of Main `409:51578` | Full |
| `254:151` … `264:866` | A02–A12 (existing) | metadata text compared against 08; screenshots of Mains `254:216`, `255:285`, `256:358`, `257:488`, `260:635`, `261:708`, `263:776`, `264:931` and modals `256:826`, `257:994`, `263:1198`; `get_design_context` on `260:664` (stale layer name) | Full (delta check) |

**Counts:** 28 v1.0 frames plus the sidebar set. All 28 were read in full. The 10 v1.1 frames were not read (names from the metadata only, as instructed).

**Structure check for the existing frames.** None of A02–A12 contains a node created after the 08 transcription. Every node id is below `265:0`, and every text matches 08. Only their `Admin/Sidebar` instances render differently, because the component changed. The 08 A01 frame `264:1150` is **no longer on the canvas**. Four frames `265:949`–`265:1228` replace it.

**Annotation scan.** The canvas has no sticky notes or annotation frames. The only top-level text nodes are section labels `409:51760`–`409:51778`, read from their layer names: "Label · v1.0", "Label · Tổng quan & phân tích", "Label · Gia đình", "Label · Hỗ trợ", "Label · Mở rộng dung lượng", "Label · Yêu cầu dữ liệu", "Label · Dữ liệu tham chiếu", "Label · Hệ thống & AI", "Label · Tính năng & phát hành", "Label · Nhân sự & phân quyền", "Label · Nhật ký thao tác", "Label · v1.1", "Label · Bài viết", "Label · Duyệt nội dung", "Label · Thẻ theo tuổi", "Label · Mốc phát triển", "Label · Wonder Week", "Label · Đăng nhập", "Label · Sidebar". All rules on this page are in-UI helper notes, quoted below.

**Canvas layout (v1.0).** There is one row per section, in sidebar order:
- Sidebar set at y −2660.
- Đăng nhập column at x −1540: A01, A01b, A01c, A01d stacked.
- Tổng quan & phân tích (y 0): A02 | A13 | A14.
- Gia đình (1540): A15 | A16 | A17.
- Hỗ trợ (2860): A03.
- Mở rộng dung lượng (4113): A04 | A05.
- Yêu cầu dữ liệu (5475): A06 | A07.
- Dữ liệu tham chiếu (6719): C01 | C02 | C03 | C04.
- Hệ thống & AI (8139): A08 | A09.
- Tính năng & phát hành (9449): A10 | A11.
- Nhân sự & phân quyền (10670): A18 | A19 | A20 | A21.
- Nhật ký thao tác (12072): A12.
- v1.1 starts at y 13554.

---

## 1. Global shell — `253:467` Admin/Sidebar (v1.0)

Dark teal sidebar, 300 px wide (`#163d44`), unchanged in style. Read from variant `253:19` (Active=Tổng quan).

| # | Element | Copy | Icon | Badge | Variant (Active=) |
|---|---|---|---|---|---|
| — | Logo | **Child Life** / "Vận hành" *(Operations)* | app icon | — | — |
| 1 | Nav | "Tổng quan" *(Overview)* | today | — | `253:19` |
| 2 | Nav | "Phân tích" *(Analytics)* — **new** | chart | — | `405:4122` |
| — | Section label | "VẬN HÀNH" *(OPERATIONS)* — **new** | — | — | — |
| 3 | Nav | "Gia đình" *(Families)* — **new** | family | — | `405:4189` |
| 4 | Nav | "Hỗ trợ" *(Support)* | mail | **12** (yellow) | `253:83` |
| 5 | Nav | "Mở rộng dung lượng" *(Storage expansion)* | upload | **4** | `253:147` |
| 6 | Nav | "Yêu cầu dữ liệu" *(Data requests)* | journal | **3** | `253:211` |
| 7 | Nav | "Dữ liệu tham chiếu" *(Reference data)* — **new** | ruler | — | `347:47283` |
| — | Section label | "HỆ THỐNG" *(SYSTEM)* | — | — | — |
| 8 | Nav | "Hệ thống & AI" *(System & AI)* | spark | — | `253:275` |
| 9 | Nav | "Tính năng & phát hành" *(Features & releases)* | sliders | — | `253:339` |
| 10 | Nav | "Nhân sự & phân quyền" *(Staff & permissions)* — **new** | shield | — | `405:4256` |
| 11 | Nav | "Nhật ký thao tác" *(Action log)* | clock | — | `253:403` |
| — | Env pill | "● Production" (yellow) | — | — | — |
| — | User card | avatar "L", "Linh Trần", **"Admin · Vận hành"** | — | — | — |

**Variants (16).**
- v1.0: the 11 listed above. The only change between them is which item has the white pill.
- v1.1: `315:46970` Bài viết, `315:47038` Thẻ theo tuổi, `315:47106` Mốc phát triển, `315:47173` Wonder Week, `315:47240` Duyệt nội dung. They are 300 × 1080, taller than the v1.0 960, which implies extra content rows. They sit at x ≥ 3780, outside the set's 3680 px width, and do not render. Their nav was not read.

No sign-out, profile or language control is drawn (08 gap 31 and G-079 still apply). No role-based hiding of items is drawn.

**Delta vs 08:**
- Four new items: Phân tích, Gia đình, Dữ liệu tham chiếu and Nhân sự & phân quyền.
- New section label "VẬN HÀNH" above Gia đình. Tổng quan and Phân tích sit above it, with no label.
- 7 variants → 11 v1.0 variants (+5 v1.1).
- The user role line changed from "Vận hành · Hỗ trợ" to **"Admin · Vận hành"**.
- Badges are unchanged (12 / 4 / 3). The new items carry no badge.

---

## 2. A01 · Đăng nhập — four frames (replaces 08's `264:1150`)

The left brand panel is identical in all four frames (`265:950` and twins) and unchanged from 08:
- "Child Life" / "Vận hành"
- Headline "Chăm sóc người dùng, mà không chạm vào kỷ niệm của họ." *(Care for users without touching their memories.)*
- Three ✓ promises:
  - "Không xem được ảnh, video, chú thích hay ghi chép" *(Cannot view photos, videos, captions or records)*
  - "Mọi thao tác đều cần lý do và được ghi nhật ký" *(Every action requires a reason and is logged)*
  - "Chỉ thấy email đã che và mã gia đình ẩn danh" *(Only sees masked emails and anonymous family codes)*
- Footer "Công cụ nội bộ · chỉ dành cho nhân viên Child Life" *(Internal tool · Child Life staff only)*

### A01 · Mật khẩu — `265:949` (password)

Card "Đăng nhập" `265:972`:
- Sub "Chỉ dành cho nhân viên Child Life." *(Child Life staff only.)*
- Field **"Tên đăng nhập"** *(Username)*: value "linh.tran" (a username, not an email).
- Field **"Mật khẩu"** *(Password)*: value "••••••••••" with an eye icon (show/hide). The field is focused (mint border). Inline link **"Quên mật khẩu?"** *(Forgot password?)* sits on the label row.
- Primary **"Đăng nhập"** *(Sign in)*.
- Divider "hoặc" *(or)*.
- Secondary (mail icon) **"Gửi link đăng nhập qua email"** *(Send a sign-in link by email)* → A01c.
- Foot (clock) "Tự đăng xuất sau 30 phút không hoạt động" *(Auto sign-out after 30 minutes of inactivity)*.

### A01b · Sai mật khẩu — `265:1044` (wrong password)

Same card, with a red error block `265:1112` (alert icon) above the fields: **"Tên đăng nhập hoặc mật khẩu chưa đúng. Còn 3 lần thử trước khi tài khoản tạm khoá 15 phút."** *(Username or password is incorrect. 3 attempts left before the account is locked for 15 minutes.)* The password field has a red border and holds "••••••". The username "linh.tran" is kept.

### A01c · Link qua email — `265:1144` (email link request)

Card `265:1167`:
- Back link (back icon) **"Đăng nhập bằng mật khẩu"** *(Sign in with password)* → A01.
- Title **"Nhận link đăng nhập"** *(Get a sign-in link)*.
- Sub "Nhập email công việc, chúng mình gửi một link đăng nhập dùng được một lần." *(Enter your work email; we send a one-time sign-in link.)*
- Field **"Email công việc"** *(Work email)* with a mail icon: "linh.tran@tencongty.vn". The field is focused.
- Primary **"Gửi link đăng nhập"** *(Send sign-in link)* → A01d.
- Helper "Chỉ email đã được cấp quyền mới nhận được link." *(Only authorised emails receive a link.)*
- Foot "Tự đăng xuất sau 30 phút không hoạt động".

### A01d · Đã gửi link — `265:1228` (link sent)

Card `265:1251`, centred:
- Mail icon in a mint circle.
- Title **"Kiểm tra hộp thư"** *(Check your inbox)*.
- Sub "Link đăng nhập đã gửi tới l***@tencongty.vn. Link dùng được một lần trong 15 phút." *(The sign-in link was sent to l***@tencongty.vn. It works once, within 15 minutes.)*
- Disabled secondary (retry icon) **"Gửi lại sau 45 giây"** *(Resend in 45 seconds)*, a countdown.
- Link **"Đăng nhập bằng mật khẩu"**.
- Tip (lock icon) "Mở link trên chính máy này. Nếu không thấy email, hãy xem thư mục Spam." *(Open the link on this same device. If you don't see the email, check Spam.)*

**Controls:**
- Đăng nhập (password)
- eye toggle
- Quên mật khẩu? (target not drawn)
- Gửi link đăng nhập qua email → A01c → Gửi link đăng nhập → A01d
- Gửi lại (45 s cooldown)
- Đăng nhập bằng mật khẩu (back)

**Data implied:**
- StaffUser {login id (username?) and/or work email, password, authorised flag}
- failed-attempt counter with lockout (3 remaining → 15 min)
- one-time email link (single use, 15 min TTL, same-device)
- resend throttle (45 s)
- idle-timeout session (30 min)

**Not drawn:** password reset flow, lockout-reached state, expired or used link state, "email not authorised" response (A01d is shown regardless, which is good for enumeration), second-factor step.

**Delta vs 08 A01:**
- **Removed:**
  - "Dùng tài khoản công ty, sau đó nhập mã xác minh 2 bước."
  - "Tiếp tục với tài khoản công ty"
  - the company-account chip "linh.tran@tencongty.vn"
  - "Mã xác minh 2 bước" with its 6 code boxes
  - "Mở ứng dụng xác thực trên điện thoại để lấy mã."
- **Added:** username/password form, "Chỉ dành cho nhân viên Child Life.", "Quên mật khẩu?", the "hoặc" divider, the email magic-link path (A01c, A01d), and the lockout error copy (A01b).
- **Kept:** brand panel and 30-minute idle sign-out.
- **Business map:** this now matches **D-043**: email + password or email magic link, no TOTP. It drops the SSO and TOTP that R-180 and D-008 described.

---

## 3. Phân tích (Analytics)

Both frames share a header (`407:3489` / `407:50487`):
- "Phân tích" / "Số liệu gộp và ẩn danh · không chứa ảnh, ghi chép hay thông tin của bé" *(Aggregated, anonymous figures · no photos, records or baby information)*
- Button (journal icon) "Xuất CSV" *(Export CSV)*

The filter row has:
- Segmented "Tăng trưởng & giữ chân" *(Growth & retention)* / "Tính năng" *(Features)* / "Kỹ thuật" *(Engineering)*
- Dropdown "Nền tảng: Tất cả" *(Platform: All)*
- Dropdown "Khoảng: 30 ngày" *(Range: 30 days)*

The **"Kỹ thuật" tab has no frame.**

### A13 · Tăng trưởng & giữ chân — `407:3393`

Segment "Tăng trưởng & giữ chân" is selected.

KPI tiles:

| KPI | Value | Delta |
|---|---|---|
| "Hoạt động ngày" *(Daily active)* | 1.284 | "↑ 9% so với kỳ trước" *(vs previous period)* |
| "Hoạt động tuần" *(Weekly active)* | 2.310 | "↑ 7%" |
| "Hoạt động tháng" *(Monthly active)* | 3.050 | "↑ 11%" |
| "Gắn bó ngày/tháng" *(Daily/monthly stickiness)* | 42% | "↑ 2 điểm" *(+2 pp)* |
| "Giữ chân ngày 30" *(Day-30 retention)* | 38% | "↓ 1 điểm" (amber) |

DAU/MAU = 1.284 / 3.050 = 42.1%, which matches the stickiness tile. The tiles do not say whether the unit is a family or a user. The panels say "gia đình" *(family)*.

Panel **"Gia đình hoạt động"** *(Active families)*:
- Tag toggles "Ngày" (selected, mint) / "Tuần" / "Tháng".
- Line chart with a teal line and soft area fill.
- x axis 10/9, 17/9, 24/9, 1/10, 9/10. y axis 0 / 500 / 1.000 / 1.500.
- End-point dot labelled **1.284**. The series rises from about 1.000 to about 1.300.

Panel **"Nguồn gia đình mới"** *(Sources of new families)*, "30 ngày". Horizontal bars, value and share:
- "KÊNH" *(CHANNEL)*:
  - "Lời mời người thân" *(Relative's invitation)* 480 · 36%
  - "Kho ứng dụng" *(App store)* 588 · 44%
  - "Website" 268 · 20%
- "NỀN TẢNG" *(PLATFORM)*:
  - "iOS" 775 · 58%
  - "Android" 561 · 42% (blue bar)
- Both groups total 1.336.

Panel **"Giữ chân theo tuần đăng ký"** *(Retention by sign-up week)*, "% gia đình còn hoạt động sau N tuần" *(% of families still active after N weeks)*. A teal heat-map: darker means higher, and empty cells are grey.

| Nhóm *(Cohort)* | Gia đình | T0 | T1 | T2 | T3 | T4 | T5 | T6 | T7 |
|---|---|---|---|---|---|---|---|---|---|
| Tuần 33 | 412 | 100% | 71% | 58% | 52% | 47% | 44% | 42% | 41% |
| Tuần 34 | 438 | 100% | 73% | 60% | 53% | 49% | 46% | 44% | |
| Tuần 35 | 455 | 100% | 72% | 61% | 55% | 50% | 47% | | |
| Tuần 36 | 470 | 100% | 75% | 63% | 57% | 52% | | | |
| Tuần 37 | 492 | 100% | 76% | 64% | 58% | | | | |
| Tuần 38 | 516 | 100% | 78% | 66% | | | | | |
| Tuần 39 | 540 | 100% | 79% | | | | | | |
| Tuần 40 | 561 | 100% | | | | | | | |

**Controls:** the three tabs, the two filters, the Ngày/Tuần/Tháng toggle and Xuất CSV. Nothing is clickable inside the tables.

**Data implied:**
- per-family activity by day, with a definition of "hoạt động" (A02 uses "Có ít nhất 1 lần ghi hoặc 1 kỷ niệm")
- DAU / WAU / MAU and the previous period
- family sign-up week and activity in each following week (cohorts)
- acquisition channel per new family: invite vs app store vs website, which needs install attribution
- platform per family
- the same aggregates filtered by platform

### A14 · Tính năng — `407:50391`

Segment "Tính năng" is selected.

KPI tiles:
- "Lần ghi chăm sóc / ngày" *(Care logs per day)* **18.420**, "↑ 6%"
- "Kỷ niệm tải lên / tuần" *(Memories uploaded per week)* **6.310**, "↑ 12%"
- "Câu chuyện đã tạo / tuần" *(Stories created per week)* **412**, "↑ 18%"
- "Gia đình mời người thân" *(Families that invited relatives)* **41%**, "↑ 3,2 điểm"

Panel **"Mức độ dùng tính năng"** *(Feature usage)*, "% trên gia đình hoạt động tuần" *(% of weekly-active families)*. Columns: Tính năng | Gia đình dùng *(families using, bar + %)* | Lượt / ngày *(uses per day)* | So với kỳ trước *(vs previous period)*.

| Feature (sub) | Families using | Uses / day | vs previous |
|---|---|---|---|
| "Bú bình · bú mẹ" / "Nhật ký chăm sóc" *(Bottle · breastfeeding / care log)* | 88% | 9.640 | ↑ 4% |
| "Ngủ" *(Sleep)* | 71% | 4.120 | ↑ 2% |
| "Tã" *(Diaper)* | 64% | 3.380 | → 0% |
| "Hút sữa" *(Pumping)* | 22% | 1.280 | ↑ 9% |
| "Cân nặng · chiều dài" / "Biểu đồ tăng trưởng" *(Weight · length / growth chart)* | 37% | 210 | ↑ 14% |
| "Lịch tiêm chủng" / "Bản cải tiến v1.0" *(Vaccination schedule / v1.0 improvement)* | 19% | 96 | "Mới" *(New)* |
| "Kỷ niệm ảnh · video" *(Photo/video memories)* | 58% | 900 | ↑ 12% |
| "Câu chuyện AI" *(AI stories)* | 14% | 59 | ↓ 3% (red) |
| "Nhắc bú" *(Feeding reminders)* | 26% | — | ↑ 5% |

Bú + Ngủ + Tã + Hút sữa = 18.420, the KPI. Kỷ niệm 900/day ≈ 6.300/week, which matches. Câu chuyện AI 59/day ≈ 413/week, which also matches.

Panel **"Dung lượng & media"** *(Storage & media)*:
- Bars:
  - "Ảnh" *(Photos)* **2,9 TB** 60%
  - "Video" **1,7 TB** 35% (blue)
  - "Khác" *(Other)* **0,2 TB** 5% (grey)
- Key-values:
  - "Gói 10 GB" *(10 GB plan)* → "2.874 gia đình"
  - "Đã mở rộng" *(Expanded)* → "176 gia đình"
  - "Dùng trên 80%" *(Using over 80%)* → "86 gia đình"

Panel **"Thiết bị & phiên bản"** *(Devices & versions)*:
- "iOS 1.0.3" 1.402 · 46%
- "iOS 1.0.2" 366 · 12%
- "Android 1.0.3" 1.037 · 34% (blue)
- "Android 1.0.1" 245 · 8%
- Total 3.050.

**Controls:** tabs, filters, Xuất CSV. Rows are not clickable.

**Data implied:**
- per-feature event counts per day: care logs by type, growth entries, vaccination entries, memories, AI stories, reminder use
- families using each feature, as a share of weekly-active families
- storage bytes by media type
- families on the base plan vs expanded vs over 80%
- app platform and version distribution, which needs per-device or per-session telemetry

### Not drawn (A13 and A14)

- the "Kỹ thuật" tab
- empty, loading and error states
- the CSV contents
- a date picker beyond "30 ngày"
- definitions or tooltips for any metric

---

## 4. Gia đình (Families)

### A15 · Danh sách — `407:50747` (family list)

Header:
- "Gia đình" / "Tra cứu tài khoản gia đình để hỗ trợ · email được che, không xem được ảnh và ghi chép" *(Look up family accounts for support · emails are masked, photos and records cannot be viewed)*
- Search "Mã gia đình, email đã che…" *(Family code, masked email…)*

KPI tiles:
- "Tổng gia đình" *(Total families)* **3.050**, "↑ 268 trong 30 ngày" *(+268 in 30 days)*
- "Hoạt động 7 ngày" *(Active in 7 days)* **2.310**, "76%"
- "Có từ 2 người chăm" *(With ≥ 2 carers)* **41%**, "↑ 3,2 điểm"
- "Gần đầy dung lượng" *(Near full)* **86**, "Trên 80% gói" *(over 80% of plan, amber)*

Filter row:
- Segmented **"Tất cả · 3.050"** (selected) / "Hoạt động · 2.310" *(Active)* / "Ít hoạt động · 712" *(Low activity)* / "Tạm khoá · 4" *(Suspended)*
- Dropdowns "Nền tảng: Tất cả" and "Dung lượng: Tất cả" *(Storage: All)*

Columns: Gia đình | Thành viên *(Members)* | Bé *(Babies)* | Dung lượng *(Storage)* | Nền tảng | Hoạt động gần nhất *(Last activity)* | Trạng thái *(Status)*.

| Family (line 1 / line 2) | Members | Babies | Storage | Platform | Last activity | Status |
|---|---|---|---|---|---|---|
| **"Nhà Bông · FAM-20931"** / "Chủ: n***@gmail.com" *(Owner: …)* (row highlighted) | 5 người / 2 người chăm | 2 | 8,2 / 10 GB (amber bar) | iOS | 12 phút trước | Hoạt động (teal) |
| "Nhà Mít · FAM-20918" / "Chủ: t***@yahoo.com" | 2 người / Chỉ cha mẹ *(parents only)* | 1 | 3,1 / 10 GB | Android | 1 giờ trước | Hoạt động |
| "Nhà Su · FAM-20877" / "Chủ: h***@gmail.com" | 4 người / 1 lời mời chờ *(1 pending invite)* | 1 | **19,4 / 20 GB** (red bar) | iOS | hôm qua | Hoạt động |
| "Nhà Bơ · FAM-20852" / "Chủ: q***@icloud.com" | 3 người / 1 người chăm | 1 | 1,2 / 10 GB | iOS · Android | 5 ngày trước | Ít hoạt động (amber) |
| "Nhà Na · FAM-20811" / "Chủ: m***@gmail.com" | 1 người / Chưa mời ai *(no one invited)* | 1 | 0,4 / 10 GB | Android | 12 ngày trước | Ít hoạt động |
| "Nhà Cốm · FAM-20790" / "Chủ: p***@gmail.com" | 3 người / 1 người chăm | 2 | 6,8 / 10 GB | iOS | 3 giờ trước | Hoạt động |
| "FAM-20744" (no name) / "Chủ: v***@outlook.com" | 2 người | 1 | 2,2 / 10 GB | Android | 28 ngày trước | Tạm khoá (red) |

Footer: "Hiển thị 1–7 trong 3.050" *(Showing 1–7 of 3,050)*, buttons "Trước" *(Previous)* / "Sau" *(Next)*.

**Controls:** search, status tabs, two filters, pagination. Clicking a row opens A16 (inferred from the highlighted first row, which is the family shown in A16).

**Data implied:**
- family code (format `FAM-#####`) and family display name ("Nhà …")
- owner masked email
- member count, carer count, pending-invite count
- baby count
- used / quota bytes (the quota can be 20 GB after expansion)
- platforms of members
- last activity
- status {Hoạt động, Ít hoạt động, Tạm khoá}

### A16 · Chi tiết — `408:3669` (family detail)

- Breadcrumb "Gia đình › FAM-20931".
- Title **"Nhà Bông"**. Sub "Tạo 12/03/2026 · iOS, Android · gói 10 GB" *(Created 12/03/2026 · iOS, Android · 10 GB plan)*.
- Header buttons:
  - (mail icon) **"Gửi lại lời mời"** *(Resend invitation)*
  - (family icon) **"Chuyển chủ gia đình"** *(Transfer family ownership)* → A17
  - (lock icon, red filled) **"Tạm khoá"** *(Suspend)*

Panel **"Thành viên"** *(Members)*, "5 người · tối đa 10" *(5 people · max 10)*. Columns: Thành viên | Vai trò *(Role)* | Trạng thái | Gần nhất *(Most recent)*.

| Member (email / relationship) | Role tag | Status | Last seen / device |
|---|---|---|---|
| n***@gmail.com / Mẹ *(Mum)* | "Chủ gia đình" *(Family owner, mint)* | Hoạt động | 12 phút / iPhone · 1.0.3 |
| t***@gmail.com / Bố *(Dad)* | "Cha mẹ" *(Parent)* | Hoạt động | 2 giờ / Android · 1.0.3 |
| b***@gmail.com / Bà ngoại *(Maternal grandma)* | "Người chăm" *(Carer)* | Hoạt động | hôm qua / iPad · 1.0.2 |
| g***@gmail.com / Cô giữ trẻ *(Nanny)* | "Người chăm" | Hoạt động | 3 giờ / Android · 1.0.3 |
| h***@gmail.com / Bà nội *(Paternal grandma)* | "Người chăm" | **"Lời mời hết hạn"** *(Invitation expired, amber)* | "Gửi 9 ngày trước" *(sent 9 days ago)* |

Panel **"Hồ sơ bé & hoạt động"** *(Baby profiles & activity)*, "Chỉ số đếm, không có nội dung" *(Counts only, no content)*:
- Baby tiles (generic icon):
  - "Bé thứ nhất" / "7 tháng tuổi · tên được ẩn" *(First baby / 7 months old · name hidden)*
  - "Bé thứ hai" / "3 tuổi · tên được ẩn" *(Second baby / 3 years old · name hidden)*
- Metrics:
  - "Lần ghi 7 ngày" *(Logs, 7 days)* **142**
  - "Ảnh · video 7 ngày" **18**
  - "Câu chuyện" *(Stories)* **3**
  - "Đồng bộ" *(Sync)* **2 phút trước**

Panel **"Thông tin"** *(Info)*:
- "Mã" *(Code)* → FAM-20931
- "Chủ gia đình" → n***@gmail.com
- "Khu vực" *(Region)* → "Việt Nam · Tiếng Việt"
- "Gói" *(Plan)* → "10 GB · miễn phí" *(free)*
- "Dung lượng" → 8,2 / 10 GB (amber bar)

Panel **"Hỗ trợ liên quan"** *(Related support)*:
- "Không tải được video" / "CL-1042 · 12 phút trước" / status "Chưa nhận" *(Unclaimed)*
- "Xin thêm dung lượng" *(Asked for more storage)* / "CL-0977 · 3 tuần trước" / "Đã đóng" *(Closed)*

Note (lock icon, `408:3980`): **"Email đầy đủ chỉ mở khi có lý do. Mọi lượt xem và thao tác được ghi vào nhật ký."** *(The full email opens only with a reason. Every view and action is logged.)* No "reveal email" control is drawn.

**Controls:** the three header buttons and the breadcrumb. Ticket rows probably link to A03 (inferred).

**Data implied:**
- family createdAt, platforms, plan
- members: masked email, relationship label, family-level role, status (active or invite expired), last seen, device model and app version
- member cap (10)
- babies: ordinal, age (needs DOB)
- counts of logs, media and stories over 7 days
- last sync
- region / language
- linked tickets
- a full-email reveal permission and a view-audit trail

The A03 ticket CL-1042 (n***@gmail.com, "2 bé · 5 người", "8,2 GB / 10 GB") matches this family.

### A17 · Chuyển chủ gia đình — `408:50672` (transfer ownership, modal over A16)

Modal `408:50906`:
- Title **"Chuyển chủ gia đình"**. Sub "Nhà Bông · FAM-20931 · chủ hiện tại n***@gmail.com" *(current owner …)*.
- Group "Chủ gia đình mới" *(New owner)*, radio cards:
  - ● (selected) "t***@gmail.com · Bố" / "Cha mẹ · hoạt động 2 giờ trước" *(Parent · active 2 hours ago)*
  - ○ (disabled, 60% opacity) "b***@gmail.com · Bà ngoại" / "Người chăm · cần đổi vai trò thành Cha mẹ trước" *(Carer · must change role to Parent first)*
  - ○ (disabled) "g***@gmail.com · Cô giữ trẻ" / "Người chăm · cần đổi vai trò thành Cha mẹ trước"
  - The expired invitee (Bà nội) is not listed.
- Field **"Lý do"** *(Reason)*: "Chủ gia đình yêu cầu qua Hỗ trợ · CL-1046" *(Owner requested via Support · CL-1046)*. It is not marked mandatory.
- Steps box:
  1. "Chủ hiện tại nhận email xác nhận" *(The current owner receives a confirmation email)*
  2. "Quyền chỉ chuyển khi họ đồng ý trong 48 giờ" *(Ownership moves only if they agree within 48 hours)*
  3. "Cả hai người nhận thông báo khi hoàn tất" *(Both people are notified when done)*
- Buttons "Huỷ" *(Cancel)* / **"Gửi yêu cầu xác nhận"** *(Send confirmation request)*.

**Data implied:**
- eligible new owners: members whose family role is "Cha mẹ"
- a pending transfer {from, to, reason, ticket ref, expiresAt +48 h, state}
- a confirmation email to the current owner
- notifications to both people
- an audit entry

**Not drawn:**
- the pending-transfer state on A16
- expiry or cancel
- the result
- the case where the current owner cannot confirm
- "Gửi lại lời mời" and "Tạm khoá" dialogs

---

## 5. Dữ liệu tham chiếu (Reference data)

The header is shared by C01–C03:
- "Dữ liệu tham chiếu" / "Bảng chuẩn để app so sánh số đo của bé và gợi ý chọn nhanh. Thay đổi chỉ áp dụng sau khi được duyệt." *(Standard tables the app uses to compare the baby's measurements and offer quick picks. Changes apply only after approval.)*
- Buttons (upload icon) "Nhập CSV" *(Import CSV)* → C03, and primary (arrow icon) **"Gửi duyệt"** *(Submit for approval)*.

The tab bar in C01–C03 has three tabs, "Cân nặng" *(Weight)* / "Chiều dài" *(Length)* / "Lượng sữa gợi ý" *(Suggested milk amounts)*, plus a status pill "● Bản đang dùng · v2026.09" *(Version in use · v2026.09)*.

### C01 · Chiều dài — `347:47483` (length)

Tab "Chiều dài" is selected.

Panel:
- Segmented "Bé trai" *(Boy, selected)* / "Bé gái" *(Girl)*, and "Theo tuần" *(By week, selected)* / "Theo tháng" *(By month)*.
- Count "0–13 tuần · 14 dòng" *(0–13 weeks · 14 rows)*.
- Table: Tuổi *(Age)* | Ngưỡng dưới *(Lower threshold)* | Trung vị *(Median)* | Ngưỡng trên *(Upper threshold)*, with an edit (pencil) icon per row.

| Tuổi | Ngưỡng dưới | Trung vị | Ngưỡng trên |
|---|---|---|---|
| Mới sinh *(Newborn)* | 46,3 | 49,9 | 53,4 |
| 1 tuần | 47,5 | 51,1 | 54,7 |
| 2 tuần | 48,8 | 52,3 | 55,9 |
| 3 tuần | 49,8 | 53,4 | 57,0 |
| 4 tuần | 50,8 | 54,4 | 58,0 |
| 5 tuần | 51,7 | 55,3 | 58,9 |
| 6 tuần | 52,4 | 56,0 | 59,7 |

Only 7 of the 14 rows are drawn, with no scroll or pagination. The values are the WHO length-for-age boys P3 / median / P97, which the UI does not label.

Note (alert icon): "Nhập đúng số liệu từ bảng WHO gốc. App dùng ngưỡng dưới và ngưỡng trên để đánh giá số đo của bé." *(Enter the exact figures from the original WHO table. The app uses the lower and upper thresholds to assess the baby's measurement.)*

Panel **"Cách app đánh giá"** *(How the app assesses)*:
- "● Bình thường" *(Normal, teal)* · "Trong khoảng" *(Within range)* — "“Trong khoảng bình thường theo chuẩn WHO.”" *(Within the WHO normal range.)*
- "● Dưới mức" *(Below, amber)* · "< ngưỡng dưới" — "“Thấp hơn khoảng thường gặp ở tuổi này. Bạn nên trao đổi với bác sĩ.”" *(Lower than usual for this age. You should talk to a doctor.)*
- "● Trên mức" *(Above, purple)* · "> ngưỡng trên" — "“Cao hơn khoảng thường gặp ở tuổi này. Bạn nên trao đổi với bác sĩ.”"
- Key-values:
  - "Đơn vị" *(Unit)* → cm
  - "Nguồn" *(Source)* → "WHO Child Growth Standards"
  - "Rà soát" *(Reviewed by)* → "Thu Hà · Nhóm chuyên môn" *(… · Expert team)*

**Controls:**
- three tabs
- sex and unit segments
- per-row edit (inline editor not drawn)
- Nhập CSV
- Gửi duyệt (approval screen not drawn)

### C02 · Lượng sữa gợi ý — `347:47796` (suggested bottle amounts)

Tab "Lượng sữa gợi ý" is selected.

Note (heart icon): "Đây là các nút chọn nhanh khi ghi bú bình, không phải khuyến nghị. Ba mẹ luôn nhập được lượng bất kỳ; app ưu tiên hiện lượng lần trước." *(These are quick-pick buttons for logging a bottle, not recommendations. Parents can always enter any amount; the app shows the last amount first.)*

Columns: Độ tuổi *(Age band)* | Nút chọn nhanh *(Quick-pick buttons)* | Bước tăng khi chỉnh *(Adjustment step)* | Trạng thái.

| Độ tuổi | Quick picks | Step | Status |
|---|---|---|---|
| 0–2 tuần | 30 ml · 45 ml · 60 ml · 90 ml | 5 ml | Đang dùng *(In use)* |
| 2–4 tuần | 60 · 90 · 120 · 150 ml | 10 ml | Đang dùng |
| 1–2 tháng | 90 · 120 · 150 · 180 ml | 10 ml | Đang dùng |
| 2–4 tháng | 120 · 150 · 180 · 210 ml | 10 ml | **Chờ duyệt** *(Pending approval, amber)* |
| 4–6 tháng | 150 · 180 · 210 · 240 ml | 10 ml | **Nháp** *(Draft, grey)* |

Button "+ Thêm khoảng tuổi" *(Add age band)*. There is no right-hand panel.

### C03 · Nhập CSV — `347:48046` (CSV import modal over C01)

Modal `347:48275`:
- Title **"Nhập bảng chiều dài"** *(Import length table)*. Sub "Bé trai · theo tuần. Bản mới cần nhóm chuyên môn duyệt trước khi app dùng." *(Boy · by week. A new version must be approved by the expert team before the app uses it.)*
- Drop zone (upload icon): "who-length-boys-weeks.csv" / "14 dòng · 4 cột" *(14 rows · 4 columns)*.
- Validation list:
  - ✓ "Cột: tuổi, ngưỡng dưới, trung vị, ngưỡng trên" *(Columns: age, lower, median, upper)*
  - ✓ "Đơn vị cm, tuổi tính theo tuần" *(Unit cm, age in weeks)*
  - ✓ "Ngưỡng dưới < trung vị < ngưỡng trên ở mọi dòng" *(Lower < median < upper in every row)*
  - ⓘ "Khác bản đang dùng 2 dòng · xem trước thay đổi" *(Differs from the version in use in 2 rows · preview the changes)*
- Buttons "Huỷ" / **"Xem trước thay đổi"** *(Preview changes; target not drawn)*.

### C04 · Lịch tiêm chủng — `394:50015` (vaccination schedule)

- Header "Dữ liệu tham chiếu" / "Lịch tiêm chủng tham khảo để app gợi ý mốc tiêm và nhắc lịch. Thay đổi cần được nhóm chuyên môn duyệt." *(Reference vaccination schedule the app uses to suggest dose dates and reminders. Changes need expert-team approval.)*
- Buttons "Nhập CSV" and "Thêm mũi" *(Add dose)*. There is no "Gửi duyệt".
- The tab bar has **four** tabs: Cân nặng / Chiều dài / Lượng sữa gợi ý / **"Lịch tiêm chủng"**. The tab-bar selection was not rendered; "Lịch tiêm chủng" is presumably selected.
- Pill "● Bản đang dùng · v2026.10".

Panel:
- Filters "Nơi tiêm: Tất cả" *(Where given: All)* and "Loại: Tất cả" *(Type: All)*.
- Count "24 mũi · 0–24 tháng" *(24 doses · 0–24 months)*.
- Columns: Mốc tuổi *(Age)* | Vắc xin *(Vaccine)* | Mũi *(Dose)* | Nơi tiêm | Ghi chú hiển thị *(Displayed note)* | Mũi kế tiếp *(Next dose)*.

| Mốc tuổi | Vắc xin | Mũi | Nơi tiêm | Ghi chú hiển thị | Mũi kế tiếp |
|---|---|---|---|---|---|
| Sơ sinh | Vitamin K | 1 | Bệnh viện *(Hospital)* | "Thường tiêm ngay sau sinh" *(Usually given right after birth)* | — |
| Sơ sinh | Lao (BCG) | 1 | Bệnh viện | *(blank)* | — |
| Sơ sinh | Viêm gan B | **Sơ sinh** | Bệnh viện | *(blank)* | — |
| 2 tháng | 6in1 | 1 | Dịch vụ *(Paid service)* | "Chọn 6in1 hoặc 5in1 + Bại liệt" *(Choose 6in1 or 5in1 + polio)* | +1 tháng |
| 2 tháng | 5in1 + Bại liệt | 1 | Trạm y tế *(Health station)* | "Thay thế cho 6in1" *(Alternative to 6in1)* | +1 tháng |
| 2 tháng | Rota | 1 | Dịch vụ | "Dạng uống" *(Oral)* | +1 tháng |
| 2 tháng | Phế cầu *(Pneumococcal)* | 1 | Dịch vụ | *(blank)* | +1 tháng |
| 6 tháng | Cúm *(Flu)* | 1 | Dịch vụ | "Mũi 2 cách 4 tuần, nhắc lại hằng năm" *(Dose 2 four weeks later, yearly booster)* | +4 tuần |
| 9 tháng | Sởi đơn *(Measles)* | 1 | Trạm y tế | "Hoặc Sởi 3in1 ở dịch vụ" *(Or MMR at a paid clinic)* | — |

The blank note cells are text layers named "Text" that render empty (`394:50215`, `394:50233`, `394:50305`). Only 9 of the 24 doses are drawn, with no pagination.

Note (heart icon): "Đây là dữ liệu tham khảo. App luôn nhắc ba mẹ làm theo chỉ định của bác sĩ và cơ sở tiêm chủng." *(This is reference data. The app always reminds parents to follow their doctor's and vaccination site's instructions.)*

### Data implied (C01–C04)

- ReferenceDataset {kind: weight | length | bottle | vaccines, sex, unit, granularity week/month, version label (v2026.09 / v2026.10), status (in use / pending / draft), reviewer, source}
- rows:
  - growth: age, lower, median, upper
  - bottle: age band, 4 quick picks, step
  - vaccines: age, vaccine, dose, site, displayed note, next-dose interval
- CSV import: parse, validate, diff vs the version in use
- approval workflow: submit, approve by the expert team, publish
- delivery to the apps

### Not drawn (C01–C04)

- the Cân nặng tab
- the "Theo tháng" view
- inline edit
- the approval queue and approve screen
- preview diff
- import errors
- version history and rollback
- vaccine "Thêm mũi" form
- empty, loading and error states

---

## 6. Nhân sự & phân quyền (Staff & permissions)

### A18 · Thành viên — `408:51014` (staff members)

Header:
- "Nhân sự & phân quyền" / "Tài khoản nội bộ Child Life · đăng nhập bằng email công ty và xác thực 2 lớp" *(Child Life internal accounts · sign in with company email and two-factor authentication)*
- Primary (plus icon) **"Mời thành viên"** *(Invite member)* → A20

KPI tiles:
- "Thành viên" *(Members)* **14**, "3 nhóm vai trò chính" *(3 main role groups)*
- "Quyền nhạy cảm" *(Sensitive permissions)* **4**, "Owner · Admin · Vận hành"
- "Chưa bật 2 lớp" *(2FA not enabled)* **1**, "Khoá đăng nhập sau 3 ngày" *(Sign-in locked after 3 days, amber)*
- "Lời mời đang chờ" *(Pending invitations)* **2**, "Hết hạn sau 7 ngày" *(Expire after 7 days)*

Filter row:
- Segmented **"Thành viên · 14"** (selected) / "Vai trò · 7" *(Roles)* → A19 / "Lời mời · 2" *(Invitations; no frame)*
- Search "Tên, email…" *(Name, email…)*
- Dropdown "Vai trò: Tất cả"

Columns: Thành viên | Vai trò | Phạm vi *(Scope)* | Xác thực 2 lớp *(2FA)* | Gần nhất | Trạng thái.

| Member | Role tag | Scope | 2FA | Last | Status |
|---|---|---|---|---|---|
| M · Minh Phạm · minh@childlife.vn | Owner (yellow) | "Toàn bộ · thanh toán" *(Everything · billing)* | ✓ Bật *(On)* | 2 giờ trước | Hoạt động |
| L · Linh Trần · linh@childlife.vn | Admin (mint) | "Toàn bộ trừ thanh toán" *(Everything except billing)* | ✓ Bật | Đang trực tuyến *(Online now)* | Hoạt động |
| Q · Quang Đỗ · quang@childlife.vn | Admin | "Toàn bộ trừ thanh toán" | ✓ Bật | hôm qua | Hoạt động |
| H · Hà Vũ · ha@childlife.vn | Vận hành | "Gia đình, dung lượng, yêu cầu dữ liệu" *(Families, storage, data requests)* | ✓ Bật | 30 phút trước | Hoạt động |
| T · Thảo Lê · thao@childlife.vn | Hỗ trợ | "Hỗ trợ, gia đình (che email)" *(Support, families (masked email))* | ✓ Bật | 5 phút trước | Hoạt động |
| A · An Ngô · an@childlife.vn | Hỗ trợ | "Hỗ trợ, gia đình (che email)" | ⓘ **Chưa bật** *(Off, red)* | 3 ngày trước | **"Cần bật 2 lớp"** *(Must enable 2FA, amber)* |
| B · Bình Trịnh · binh@childlife.vn | Phân tích *(Analytics)* | "Chỉ xem số liệu gộp" *(Aggregates only)* | ✓ Bật | hôm qua | Hoạt động |
| M · Mai Hồ · mai@childlife.vn | Chuyên gia *(Expert)* | "Duyệt dữ liệu tham chiếu" *(Approves reference data)* | ✓ Bật | 4 ngày trước | Hoạt động |
| K · Khoa Lý · khoa@childlife.vn | Kỹ sư *(Engineer)* | "Hệ thống, tính năng" *(System, features)* | ✓ Bật | 1 giờ trước | **"Tạm ngưng"** *(Paused, grey)* |

Only 9 of the 14 members are drawn. There is no pagination and no row action or menu.

**Data implied:** StaffUser {name, company email (@childlife.vn), role (one per person as drawn), scope summary, 2FA enrolled, last seen / online, status {Hoạt động, Cần bật 2 lớp, Tạm ngưng}}; invitations {email, role, expiresAt 7 d}; a policy that locks sign-in after 3 days without 2FA.

### A19 · Vai trò & quyền — `409:3977` (roles & permission matrix)

- Header "Nhân sự & phân quyền" / "Mỗi vai trò chỉ có quyền đủ dùng cho công việc · thay đổi quyền được ghi vào nhật ký" *(Each role has only the permissions its work needs · permission changes are logged)*.
- Buttons "+ Tạo vai trò" *(Create role)* and primary "+ Mời thành viên".
- Segmented "Thành viên · 14" / **"Vai trò · 7"** (selected) / "Lời mời · 2".
- Legend "Mức quyền" *(Permission level)*: **"Toàn quyền"** *(Full, dark teal fill)* · **"Duyệt"** *(Approve, yellow)* · **"Sửa"** *(Edit, mint)* · **"Xem"** *(View, grey)* · **"Xem · che"** *(View · masked, light grey)*.

The full matrix is transcribed verbatim in §8.

Note (lock icon, `409:4431`): **"Owner là vai trò hệ thống, luôn có ít nhất 2 người. Khoá gia đình, chuyển chủ, xuất hoặc xoá dữ liệu đều cần nhập lý do và được ghi vào nhật ký."** *(Owner is a system role and always has at least 2 people. Locking a family, transferring ownership, exporting or deleting data all require a reason and are logged.)*

**Controls:** Tạo vai trò (no frame), Mời thành viên → A20, tabs. Clicking a role column header probably opens A21 (inferred).

### A20 · Mời thành viên — `409:51027` (invite modal over A18)

Modal `409:51381`:
- Title **"Mời thành viên"**. Sub "Chỉ email công ty @childlife.vn" *(Company emails @childlife.vn only)*.
- Field **"Email"** (focused): "dung@childlife.vn".
- Group **"Vai trò"**, a 2-column grid of radio cards. Single choice; Owner is not offered.
  - "Admin" / "Toàn bộ trừ thanh toán"
  - "Vận hành" / "Gia đình, dung lượng, dữ liệu"
  - **● "Hỗ trợ"** (selected) / "Trả lời hỗ trợ, tra cứu gia đình" *(Answer support, look up families)*
  - "Phân tích" / "Chỉ xem số liệu gộp"
  - "Chuyên gia" / "Duyệt dữ liệu tham chiếu"
  - "Kỹ sư" / "Hệ thống, tính năng"
- Group **"Thời hạn quyền"** *(Access duration)*: segmented **"Không giới hạn"** *(Unlimited, selected)* / "30 ngày" / "Đến ngày…" *(Until date…)*.
- Note (lock icon): "Lời mời hết hạn sau 7 ngày. Lần đăng nhập đầu bắt buộc bật xác thực 2 lớp." *(The invitation expires after 7 days. 2FA must be enabled at first sign-in.)*
- Buttons "Huỷ" / (mail icon) **"Gửi lời mời"** *(Send invitation)*.

There is no reason field.

### A21 · Sửa vai trò — `409:51488` (edit role)

- Breadcrumb "Nhân sự & phân quyền › Vai trò › Hỗ trợ".
- Title **"Vai trò · Hỗ trợ"**. Sub "4 thành viên · sửa lần cuối bởi Linh Trần, 2 tuần trước" *(4 members · last edited by Linh Trần, 2 weeks ago)*.
- Buttons "Huỷ" / **"Lưu thay đổi"** *(Save changes)*.

Left panel **"Vai trò"**, with counts:
- Owner 🔒 1
- Admin 🔒 2
- Vận hành 3
- **Hỗ trợ 4** (selected)
- Chuyên gia 1
- Phân tích 2
- Kỹ sư 1

Owner and Admin carry a lock icon (not editable).

Right panel **"Quyền theo chức năng"** *(Permissions by function)*, "Áp dụng ngay cho 4 người" *(Applies immediately to 4 people)*. Each row has a segmented control "— / Xem / Sửa / Duyệt". The selected value is in bold:

| Section | Function (sub) | Selected |
|---|---|---|
| VẬN HÀNH | "Hỗ trợ" / "Trả lời người dùng, thao tác được phép" *(Reply to users, allowed actions)* | **Sửa** |
| | "Gia đình · tra cứu" / "Email luôn được che" *(Email always masked)* | **Xem** |
| | "Gia đình · chuyển chủ, tạm khoá" / "Chỉ Vận hành trở lên" *(Vận hành and above only)* | **—** (whole control disabled) |
| | "Mở rộng dung lượng" | **Xem** |
| | "Yêu cầu dữ liệu" | **Xem** |
| | "Dữ liệu tham chiếu" | **Xem** |
| HỆ THỐNG | "Tổng quan & phân tích" | **Xem** |
| | "Hệ thống & AI" | **—** |
| | "Nhật ký thao tác" / "Chỉ thao tác của chính mình" *(Own actions only)* | **—** |

Note (lock icon, `409:51759`): **"Quyền xem email đầy đủ, xuất hoặc xoá dữ liệu không thể cấp cho vai trò Hỗ trợ."** *(The permissions to view full emails, export or delete data cannot be granted to the Hỗ trợ role.)*

**Not drawn (A18–A21):**
- member row actions: change role, suspend or reactivate, remove, reset 2FA
- the Lời mời tab
- the Tạo vai trò form
- a confirmation or reason on Lưu thay đổi
- what happens when time-boxed access ends
- 2FA enrolment screens
- empty, loading and error states

---

## 7. Existing frames — delta vs 08-admin-portal.md

| Frame | Delta |
|---|---|
| A01 `264:1150` | **Removed from the canvas.** Replaced by A01–A01d (§2). |
| A02 Tổng quan `254:151` | **Unchanged.** Header, the 4 KPIs (1.284 / 1.336 / 69% / 41%), the daily chart, "Cần xử lý" (4 items), the funnel and weekly care logs match 08 word for word (screenshot). Axis labels not in 08: x 10/9, 15/9, 20/9, 25/9, 30/9, 5/10, 9/10; bars y 0/10k/20k/30k/40k, weeks T35–T40. Only the sidebar instance changed. |
| A03 Hỗ trợ `255:220` | **Unchanged** (all 7 tickets, the CL-1042 detail, diagnostics, allowed actions, lock note, composer). Sidebar only. |
| A04 Mở rộng dung lượng `256:293` | **Unchanged.** Still uses F-XXXX codes (F-7Q2K, F-3M8D, F-9X1A, F-2B6T), the "Tuỳ chỉnh · Trên 20 GB cần trưởng nhóm duyệt" guidance and "Mã gia đình đã ẩn danh". Sidebar only. |
| A05 Duyệt `256:559` | **Unchanged.** Modal identical. Background Main `256:624` has the same text as A04 `256:358`. |
| A06 Yêu cầu dữ liệu `257:423` | **Unchanged** (4 KPIs, 6 jobs DJ-2231…DJ-2210, 3 lock notes). Sidebar only. The "Đang chuẩn bị" pill is clipped by the "Nhật ký" button on DJ-2230 (visual only). |
| A07 Chạy lại `257:708` | **Unchanged.** Modal identical. Background same as A06. Still no second-approver step. |
| A08 Dung lượng & media `260:570` | **Unchanged.** `260:666` renders "Hạn mức 10 GB"; its layer name is stale. Axis labels not in 08: x 0h, 3h, 6h, 9h, 12h, 15h, 18h, 21h, 23h; y 0/5/10/15/20. |
| A09 AI gợi ý câu chuyện `261:643` | **Unchanged.** Axis labels not in 08: x 27/9, 30/9, 3/10, 6/10, 9/10; y 0/200/400/600. |
| A10 Tính năng & phát hành `263:711` | **Unchanged** (7 flags, rollout ladder, limits, recent changes). Still no vaccination flag. |
| A11 Xác nhận tắt `263:954` | **Unchanged.** Modal identical. Background same as A10. |
| A12 Nhật ký thao tác `264:866` | **Unchanged** (8 entries, filters "Tất cả / Hỗ trợ / Dung lượng / Dữ liệu / Tính năng", note). Its actor roles now contradict A18; see gaps 18 and 42. |
| Sidebar instance in every A02–A12 frame | Now shows the v1.0 nav (§1) and "Linh Trần · Admin · Vận hành". |

---

## 8. Permission and role evidence

### 8.1 A19 permission matrix (verbatim, `409:4080`)

Column headers with headcount: **Owner** "1 người", **Admin** "2 người", **Vận hành** "3 người", **Hỗ trợ** "4 người", **Chuyên gia** "1 người", **Phân tích** "2 người", **Kỹ sư** "1 người". The headcounts total 14, which matches A18.

| Chức năng *(Function)* (sub) | Owner | Admin | Vận hành | Hỗ trợ | Chuyên gia | Phân tích | Kỹ sư |
|---|---|---|---|---|---|---|---|
| **TỔNG QUAN** | | | | | | | |
| "Tổng quan & phân tích" / "Số liệu gộp, ẩn danh" | Xem | Xem | Xem | Xem | — | Xem | Xem |
| **VẬN HÀNH** | | | | | | | |
| "Gia đình · tra cứu" / "Email che, không xem ảnh hay ghi chép" | Xem | Xem | Xem | Xem · che | — | — | — |
| "Gia đình · chuyển chủ, tạm khoá" / "Cần lý do" | Duyệt | Duyệt | Sửa | — | — | — | — |
| "Hỗ trợ" / "Trả lời, thao tác được phép" | Xem | Toàn quyền | Sửa | Sửa | — | — | Xem |
| "Mở rộng dung lượng" | Duyệt | Duyệt | Sửa | Xem | — | — | — |
| "Yêu cầu dữ liệu · xuất, xoá" / "Xoá cần người thứ hai duyệt" *(Deletion needs a second person's approval)* | Duyệt | Duyệt | Sửa | Xem | — | — | — |
| "Dữ liệu tham chiếu" / "WHO, lượng sữa, tiêm chủng" | Xem | Toàn quyền | Sửa | Xem | Duyệt | — | — |
| **HỆ THỐNG** | | | | | | | |
| "Hệ thống & AI" | Toàn quyền | Toàn quyền | Xem | — | — | — | Sửa |
| "Tính năng & phát hành" | Duyệt | Toàn quyền | Xem | — | — | — | Sửa |
| "Nhân sự & phân quyền" / "Chỉ Owner đổi vai trò Owner, Admin" *(Only Owner changes Owner and Admin roles)* | Toàn quyền | Sửa | — | — | — | — | — |
| "Nhật ký thao tác" | Xem | Xem | Xem | — | — | — | Xem |
| **NỘI DUNG** · tag "v1.1" (row greyed) | | | | | | | |
| "Bài viết, thẻ theo tuổi, mốc, Wonder Week" / "Thêm vai trò Biên tập ở v1.1" *(An Editor role will be added in v1.1)* | Xem | Toàn quyền | — | — | Duyệt | — | — |

### 8.2 Other role statements in the design

- **Role scopes** in A18 and A20 (two wordings):
  - Owner "Toàn bộ · thanh toán"
  - Admin "Toàn bộ trừ thanh toán"
  - Vận hành "Gia đình, dung lượng, yêu cầu dữ liệu" (A18) / "Gia đình, dung lượng, dữ liệu" (A20)
  - Hỗ trợ "Hỗ trợ, gia đình (che email)" (A18) / "Trả lời hỗ trợ, tra cứu gia đình" (A20)
  - Phân tích "Chỉ xem số liệu gộp"
  - Chuyên gia "Duyệt dữ liệu tham chiếu"
  - Kỹ sư "Hệ thống, tính năng"
- **Hỗ trợ role settings** (A21): Hỗ trợ = Sửa; Gia đình tra cứu = Xem ("Email luôn được che"); chuyển chủ / tạm khoá not grantable ("Chỉ Vận hành trở lên"); Mở rộng dung lượng, Yêu cầu dữ liệu, Dữ liệu tham chiếu and Tổng quan = Xem; Hệ thống & AI = —; Nhật ký = — ("Chỉ thao tác của chính mình").
- **Hard limits:**
  - "Quyền xem email đầy đủ, xuất hoặc xoá dữ liệu không thể cấp cho vai trò Hỗ trợ." (`409:51759`)
  - "Chỉ Owner đổi vai trò Owner, Admin" (`409:4357`)
  - "Owner là vai trò hệ thống, luôn có ít nhất 2 người." (`409:4431`)
  - Owner and Admin are locked in A21.
- **Reasons and audit:**
  - "Khoá gia đình, chuyển chủ, xuất hoặc xoá dữ liệu đều cần nhập lý do và được ghi vào nhật ký." (`409:4431`)
  - "Cần lý do" (`409:4189`)
  - "thay đổi quyền được ghi vào nhật ký" (`409:4079`)
  - "Email đầy đủ chỉ mở khi có lý do. Mọi lượt xem và thao tác được ghi vào nhật ký." (`408:3980`)
  - A17 field "Lý do"
- **Two-person rule:** "Xoá cần người thứ hai duyệt" (`409:4260`). It is the first one in the design; no approval UI is drawn.
- **Staff identity rules:**
  - company email @childlife.vn (`409:51384`)
  - 2FA mandatory at first sign-in (`409:51368`), with a lock after 3 days without it (`408:51124`)
  - invitation TTL 7 days
  - time-boxed access "Không giới hạn / 30 ngày / Đến ngày…"
- **Expert review:** "Bản mới cần nhóm chuyên môn duyệt trước khi app dùng." (C03 `347:48278`); "Thay đổi cần được nhóm chuyên môn duyệt." (C04 `394:50123`); "Rà soát · Thu Hà · Nhóm chuyên môn" (C01 `347:47795`).

### 8.3 Design roles vs business map §5.1 and the built code

| Design role (A19) | Nearest §5.1 / `packages/contracts/src/staff.ts` role | Note |
|---|---|---|
| Owner | — (closest: trưởng nhóm `lead`) | New. Billing scope; the product has no billing. |
| Admin | — (closest: trưởng nhóm `lead`) | New. "Toàn bộ trừ thanh toán". |
| Vận hành | Vận hành `ops` | Same name. Design gives "Sửa", not approval, on storage and data jobs; Owner and Admin "Duyệt". |
| Hỗ trợ | Hỗ trợ `support` | Same name. Masked family lookup. |
| Kỹ sư | Kỹ thuật `eng` | Renamed. A12 still says "Kỹ thuật". Design gives no access to data jobs, but the code lets `eng` re-run them (`jobs.rerun`). |
| Chuyên gia | — | New: reference-data approver. |
| Phân tích | — | New: aggregates only. |
| — | trưởng nhóm `lead` | Missing from v1.0 roles, yet A04 still cites it (P-120). |
| — | Kiểm thử `qa` (P-132) | Missing. The QA handbook ("Phát triển › Sổ tay kiểm thử", built nav `qa`) has no design. |

---

## 9. Logic gaps and inconsistencies

### Privacy and pseudonymisation (R-181, R-182)

1. **Family names reach staff.** "Nhà Bông · FAM-20931", "Nhà Mít", "Nhà Su", "Nhà Bơ", "Nhà Na", "Nhà Cốm" (A15 `407:50886`…`407:50936`), the title "Nhà Bông" (A16 `408:3784`) and the A17 sub (`408:50909`).
   - The product has no family-name field: the business map §3 has no such field, and `family.ts` holds only a baby nickname.
   - "Nhà <x>" reads as the baby's nickname. That contradicts "mã gia đình ẩn danh" (A01 `265:969`, R-182) and A16's own "tên được ẩn" (`408:3911`).
   - FAM-20744 has no name (`407:50946`), so when a name exists is also undefined.
2. **Baby ages from the DOB.** "7 tháng tuổi · tên được ẩn" and "3 tuổi · tên được ẩn" (`408:3911`, `408:3919`) appear under "Chỉ số đếm, không có nội dung" (`408:3904`). Age is derived from the date of birth, which is child data (CLAUDE.md, R-181), not a count.
3. **Full-email reveal.** "Email đầy đủ chỉ mở khi có lý do…" (`408:3980`) and "Quyền xem email đầy đủ … không thể cấp cho vai trò Hỗ trợ" (`409:51759`) imply a reveal permission for other roles.
   - This contradicts A01 "Chỉ thấy email đã che…" (`265:969`) and R-182.
   - There is no reveal control, no A19 matrix row, no reason dialog and no A12 category for it.
4. **Device and region data beyond consented diagnostics.**
   - A16 lists device and app version for every member ("iPhone · 1.0.3", "iPad · 1.0.2", `408:50635`, `408:50653`) and "Khu vực · Việt Nam · Tiếng Việt" (`408:3948`).
   - A03 limits device information to diagnostics "họ đồng ý gửi" (`255:294`, D-038).
   - The product does not collect a region.
5. **View auditing is promised but not shown.** "Mọi lượt xem … được ghi vào nhật ký" (`408:3980`) has no counterpart in A12 (`264:866`), which shows mutations only and has no "Gia đình" category. What counts as a "view" (list page, detail open) is undefined.
6. **Kỹ sư can read tickets.** A19 gives Kỹ sư "Xem" on Hỗ trợ (`409:4231`). Ticket messages are user free text that may contain child details (P-124), and engineers have no stated need for them.

### Family codes and lookup

7. **Two family-code formats.**
   - "FAM-20931" appears in A15–A17. "F-7Q2K" appears in A04, A05 `256:827`, A08 and A12 (F-7Q2K, F-1C9R), and is what `familyCode()` builds (`firebase/functions/src/staff.ts:121`, hash-based F-XXXX).
   - FAM-##### looks sequential: it is enumerable and leaks sign-up order and volume. It also collides with the QA case ids "FAM-001…" in `qa-catalog.ts`.
   - The same family appears inconsistently. CL-1042 (A03: n***@gmail.com, "2 bé · 5 người", 8,2 GB) is FAM-20931 in A15/A16, but A03 shows no code. A04's F-7Q2K (2 bé · 6 người, 9,6 GB) has no FAM- counterpart.
8. **Search by masked email.** A15 "Mã gia đình, email đã che…" (`407:50841`) and A03 search on masked emails, which are not unique: n***@gmail.com matches many people. Whether staff may type a full email to find a match without seeing it is undefined.

### Staff sign-in and provisioning (D-008, D-043, P-125, D-044)

9. **2FA contradiction.**
   - A01 (all four variants) has no second factor, which matches **D-043**.
   - A18 says the opposite: "…đăng nhập bằng email công ty và xác thực 2 lớp" (`408:51112`), "Chưa bật 2 lớp · 1 · Khoá đăng nhập sau 3 ngày" (`408:51122`–`408:51124`), a "Xác thực 2 lớp" column and the status "Cần bật 2 lớp" (`408:51239`).
   - A20 also says "Lần đăng nhập đầu bắt buộc bật xác thực 2 lớp." (`409:51368`).
   - The design also conflicts with itself: 2FA is mandatory at first sign-in, yet there is a 3-day grace period. No enrolment or challenge screen is drawn.
10. **Username vs email.**
   - A01 asks for "Tên đăng nhập" = "linh.tran" (`265:1017`), but staff accounts are Firebase email/password (D-043), and A18 shows "linh@childlife.vn" (`408:51168`).
   - The domains differ: A01c "linh.tran@tencongty.vn" (`265:1219`) and A01d "l***@tencongty.vn" vs A20 "Chỉ email công ty @childlife.vn" (`409:51384`).
11. **Lockout and link rules are not in the business map.**
   - "Còn 3 lần thử trước khi tài khoản tạm khoá 15 phút." (`265:1111`): Firebase Auth has no per-account attempt counter, so this needs a blocking function or a custom store. A remaining-attempts count must also appear for unknown usernames, or it enables enumeration.
   - "Quên mật khẩu?" (`265:1019`) has no target.
   - The link rules "dùng được một lần trong 15 phút", "Gửi lại sau 45 giây" and "Mở link trên chính máy này" (`265:1294`, `265:1300`, `265:1306`) need confirming against the built D-044 flow.
12. **In-portal staff invitations.**
   - A20 invites staff from the portal, with a role and a "Thời hạn quyền" (`409:51356`). D-043 and P-125 say staff accounts are "created only by an admin script".
   - What happens when a 30-day or dated grant ends (auto-revoke? notice?) is undefined.
   - The invitation has no reason field, although A19 says "thay đổi quyền được ghi vào nhật ký" (`409:4079`) (R-183).

### Staff roles (§5.1, P-120, P-132)

13. **The role set differs from §5.1 and the code.**
   - The design has Owner / Admin / Vận hành / Hỗ trợ / Chuyên gia / Phân tích / Kỹ sư (`409:4104`–`409:4128`).
   - §5.1 and `packages/contracts/src/staff.ts` have Vận hành / Hỗ trợ / Kỹ thuật / trưởng nhóm / Kiểm thử.
   - There is no trưởng nhóm, yet A04 still says "Trên 20 GB cần trưởng nhóm duyệt" (`256:553`, P-120).
   - "Kỹ thuật" is renamed "Kỹ sư", but A12 still uses "Kỹ thuật".
   - Kiểm thử and the QA handbook (P-132) are absent from the sidebar and the matrix.
14. **Owner headcount.** "Owner … luôn có ít nhất 2 người" (`409:4431`) vs "Owner · 1 người" (`409:4105`), A21 "Owner 1" (`409:51603`), and only Minh Phạm in A18.
15. **A18 KPIs disagree with A19.**
   - "Quyền nhạy cảm 4 · Owner · Admin · Vận hành" (`408:51119`–`408:51120`), but A19 counts Owner 1 + Admin 2 + Vận hành 3 = **6**.
   - "3 nhóm vai trò chính" (`408:51116`) vs "Vai trò · 7".
   - "Thành viên 14" but only 9 rows, with no pagination.
16. **Owner is weaker than Admin, and "Duyệt" is undefined.**
   - Owner has "Xem" on Hỗ trợ and Dữ liệu tham chiếu and "Duyệt" on Tính năng, where Admin has "Toàn quyền".
   - "Duyệt" is never defined: does it mean approving another person's request, or performing the action?
   - With "Xoá cần người thứ hai duyệt" (`409:4260`), A06 and A07 still draw no approval step: A07 goes straight to "⟳ Chạy lại".
17. **A19 and A21 use different level sets and rows.**
   - A19's legend has 5 levels (`409:4091`–`409:4099`). A21's control has 4 ("— / Xem / Sửa / Duyệt"), with no "Toàn quyền" and no "Xem · che".
   - A21 lacks the "Tính năng & phát hành" and "Nhân sự & phân quyền" rows.
   - A21 sets Hỗ trợ's "Gia đình · tra cứu" to "Xem", where A19 says "Xem · che".
   - A21's "Nhật ký thao tác · Chỉ thao tác của chính mình" (`409:51742`) has "—" selected, which contradicts its own subtitle.
   - A21 groups "Tổng quan & phân tích" under HỆ THỐNG, while A19 has a TỔNG QUAN section.
18. **The same people carry different roles in different frames.**
   - The sidebar shows "Linh Trần · Admin · Vận hành" (`253:80`): two roles. A18 shows Admin only, and A20 picks one role (radio).
   - A12 actors are "Linh Trần · Vận hành", "Hà Nguyễn · Hỗ trợ" and "Minh Phạm · Kỹ thuật". A18 has Minh as Owner and Hà **Vũ** as Vận hành, and no Hà Nguyễn.
   - A10's "Sửa gần nhất · Minh" contradicts Owner's "Duyệt" on Tính năng.
   - C01's reviewer "Thu Hà · Nhóm chuyên môn" (`347:47795`) is not a staff member; the only Chuyên gia is Mai Hồ.
19. **Staff exports.** A19's "Yêu cầu dữ liệu · xuất, xoá" and its note "…xuất hoặc xoá dữ liệu đều cần nhập lý do" imply staff can start exports and deletions. R-187 and A06 say staff only monitor and re-run user-requested jobs, and that "Nhân viên không tải được tệp xuất".

### Family actions with no business rule

20. **"Tạm khoá" (suspend family).**
   - It appears as the A16 button `408:3781`, the A15 tab "Tạm khoá · 4" and status `407:50954`, and the A19 row "Gia đình · chuyển chủ, tạm khoá · Cần lý do".
   - Nothing defines it: grounds; the effect on members' sign-in, logging, uploads, invites and export or deletion rights; notice to the family; duration; or unlocking.
   - No dialog, reason field, mobile-app state or A12 category is drawn.
   - It is a red primary button next to routine actions.
21. **Staff-initiated ownership transfer (A17).**
   - In the product, transfer is an owner power: R-046, P-001 and P-003 (13n). The new owner must be **Cùng nuôi of every baby** in the family. The modal checks only the family-level "Cha mẹ" role ("cần đổi vai trò thành Cha mẹ trước", `408:50876`), not each baby.
   - "Quyền chỉ chuyển khi họ đồng ý trong 48 giờ" (`408:50895`): "họ" is ambiguous. Is it the current owner, by the step-1 email, or the new owner?
   - There is no path for an owner who has lost access, which is the main reason support would intervene.
   - The reason cites "CL-1046" (`408:50887`), which is not in A03; the matching A03 ticket is CL-1041 (`255:318`).
   - Expiry, cancel and what the family sees are not drawn.
22. **"Gửi lại lời mời" (resend invitation, A16 `408:3769`).** Invitations are per baby and created by a Cùng nuôi (P-002). Staff resending the expired invite (`408:50616`, "Gửi 9 ngày trước") act on the family's behalf. The target member, channel, whether a new code is made, and the reason or audit entry are not drawn.
23. **Family-role vocabulary differs from the product.**
   - A16 uses "Chủ gia đình / Cha mẹ / Người chăm" (`408:50581`, `408:50589`, `408:50597`) at family level. The product uses per-baby "Cùng nuôi / Người chăm sóc / Người thân" (§2.1) and "chủ hồ sơ".
   - The portal has no "Người thân".
   - The labels "Bố", "Bà ngoại", "Bà nội" and "Cô giữ trẻ" are outside the product's label set (Mẹ, Ba, Bà, Ông, Bảo mẫu, Họ hàng…, R-020).
   - "5 người · tối đa 10" (`408:3789`) is a member cap the business map does not have.
   - A15 says "2 người chăm" for FAM-20931, while A16 lists 3 "Người chăm" (one an expired invite). Whether invitees count as members is undefined.

### Numbers that do not add up across screens

24. **Active families.** A02 "Gia đình hoạt động 1.284 · ↑ 24% so với 30 ngày trước" (`254:235`) vs A13 "Hoạt động ngày 1.284 · ↑ 9% so với kỳ trước" (`407:3514`): same value, different label and delta. A11 also says "~1.284 gia đình đang hoạt động" (08 gap 9 still open).
25. **Total families.**
   - A13 "Hoạt động tháng 3.050" = A15 "Tổng gia đình 3.050" = A14 2.874 + 176. That means every family was active in the last 30 days, yet A15 has "Ít hoạt động · 712" and FAM-20744 was last active 28 days ago.
   - The A08 histogram totals 1.669 families.
   - A15's tabs add up to 2.310 + 712 + 4 = **3.026 ≠ 3.050**.
26. **Storage.**
   - A08 "Ảnh, video đã lưu 1,82 TB" vs A14 2,9 + 1,7 + 0,2 = **4,8 TB**.
   - A04 and A08 count "Đã mở rộng 11" vs A14 "Đã mở rộng 176 gia đình".
   - A04 and A08 count "Gia đình dùng trên 80% 42" vs A14 and A15 "86".
   - Bar colours differ: A15 is amber at 82% and red at 97%; A04 is orange at ≥ 90%.
27. **New families and accounts.**
   - A02 "Tài khoản mới 1.336" equals A13's channel and platform totals (1.336).
   - A15 says "↑ 268 trong 30 ngày", the same number as A13's "Website 268".
   - A13 cohorts for weeks 37–40 total 2.109 families.
   - A02's funnel says "Tạo tài khoản 1.540".
28. **Retention.** "Giữ chân ngày 30 · 38%" (`407:3530`) vs cohort T4 (about day 28–35) at 47–52% (`407:3640`, `407:3661`, `407:3682`, `407:3703`).
29. **Care-log volume.** A14's 18.420 logs per day is about 129k per week, against A02's "Lượt ghi chăm sóc mỗi tuần" of about 27k for T40.
30. **Stories.** A14 "Câu chuyện đã tạo / tuần 412" (and AI stories 59/day) vs A09 "Bản nháp tạo · 7 ngày 3.420" × 46% saved ≈ 1.570 per week.
31. **One number, two definitions.** A14 "Gia đình mời người thân 41% · ↑ 3,2 điểm" (`407:50523`) vs A02 and A15 "Có từ 2 người chăm 41% · ↑ 3,2 điểm" vs the A02 funnel "Mời người cùng chăm 32%". "Người thân" is a different role from carers.
32. **Unit of the device and platform splits.** A14's version split totals 3.050, the family count, but versions belong to devices, and families can be "iOS · Android" (A15 `407:51038`). The same question applies to A13's "Nền tảng" split and filter.

### Metrics that need data the product does not collect

33. **Analytics data.**
   - Mobile has no analytics SDK (`apps/mobile/pubspec.yaml` has only Crashlytics), and the built overview returns `firstOpen: null`.
   - A13 needs daily activity history per family (DAU / WAU / MAU, cohorts), an acquisition channel per family (app store vs website needs install attribution) and a platform per family.
   - A14 needs per-feature event counts, including reminder use ("Nhắc bú"), and per-device app versions. A16 needs per-member device and last-seen data.
   - "Hoạt động" must be defined once for families and members (A02: "Có ít nhất 1 lần ghi hoặc 1 kỷ niệm").
   - The no-child-data rule (CLAUDE.md) needs a review of any new events.
34. **Missing tab and unclear exports.** The Phân tích "Kỹ thuật" tab (`407:3497`) has no frame. For "Xuất CSV" on A13 and A14: what is exported, who may export it (the Phân tích role?), and is the export audited?

### Reference data (C01–C04)

35. **Reference data is bundled in the apps today.**
   - WHO LMS tables: `apps/mobile/lib/features/care/who_growth_data.g.dart` (D-049).
   - Vaccine schedule: `packages/contracts/src/vaccines.ts`, `vaccineScheduleVersion = 1` (P-133).
   - Bottle quick picks: `bottle_suggestions.dart` (P-126).
   - Portal-managed versions ("Bản đang dùng · v2026.09" `347:47601`, "v2026.10" `394:50135`) need runtime delivery, client caching and an offline fallback, staged rollout and rollback, and a rule for how a new version affects statuses and reminders already shown to families. None of this is drawn.
36. **The approval model is mixed.**
   - Versions are per dataset (the pill), but C02 statuses are per row: "Đang dùng / Chờ duyệt / Nháp" (`347:47932`–`347:47980`).
   - C01 "Gửi duyệt" (`347:47587`) has no approval screen. The approver is presumably the Chuyên gia ("Duyệt", `409:4299`; C03 "…nhóm chuyên môn duyệt", `347:48278`).
   - C04 offers "Thêm mũi" but no "Gửi duyệt".
   - Not drawn: who publishes after approval, whether two drafts can coexist, and the preview ("Xem trước thay đổi", `347:48273`).
37. **C01 does not match the app's growth model.**
   - The app interpolates WHO LMS values by day. C01 stores weekly or monthly rows of Ngưỡng dưới / Trung vị / Ngưỡng trên, which cannot drive the LMS computation.
   - Editable rows (pencil icons) on a WHO standard sit badly with "Nhập đúng số liệu từ bảng WHO gốc" (`347:47761`).
   - The thresholds are not labelled; the values are P3 and P97 (D-049).
   - "0–13 tuần · 14 dòng" (`347:47617`) but only 7 rows are drawn, and the Cân nặng tab is missing.
   - C01's status copy differs from the shipped strings. C01 has "Dưới mức" / "Trên mức" and "…Bạn nên trao đổi với bác sĩ." The app ARB has `whoBelow` "Dưới mức tham chiếu" and "…Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới." Which one is the source?
38. **C02 differs from P-126 and the code.**
   - C02's first band is "0–2 tuần · 30/45/60/90". The code has "< 7 days 30/45/60/75" and "7–27 days 60/90/120/150".
   - Band edges overlap or are ambiguous ("0–2 tuần", "2–4 tuần", "1–2 tháng").
   - "Bước tăng khi chỉnh" (5 ml / 10 ml) is not in the app.
   - The table stops at 6 months, with the 4–6 tháng row still "Nháp".
39. **C03 validation is drawn only in the all-pass case.** Not drawn:
   - the failure state and row-level errors
   - duplicate or missing ages and gaps
   - decimal comma vs point (the vi locale writes "46,3")
   - encoding and BOM, size limit, header language
   - monotonic-with-age checks
   - how the file's sex, unit and granularity are bound (only implied by the open tab)
   - import shapes for C02 and C04
40. **C04 does not match the mobile schedule.**
   - "24 mũi · 0–24 tháng" (`394:50150`) vs mobile VX "30 mũi" (17-vaccination.md) and the contracts' 30 doses plus the 5in1 polio row.
   - Only 9 rows are drawn, with no pagination.
   - "Viêm gan B · Mũi: Sơ sinh" (`394:50229`) puts an age in the dose column.
   - Three note cells are blank (layers "Text").
   - "Mũi kế tiếp" uses relative intervals ("+1 tháng", "+4 tuần"); P-133 plans doses at "DOB + N calendar months".
   - The site tags Bệnh viện / Dịch vụ / Trạm y tế do not map to the code's programmes epi / service / hospital / choice.
   - C01–C03 show 3 tabs; C04 shows 4.
   - Editing the schedule after families have planned doses has no defined effect on existing plans and reminders.
   - A10 has no vaccination flag, although A14 lists the feature as "Mới".

### Reasons and audit (R-183)

41. **Actions without a reason field or confirmation:**
   - A16 "Gửi lại lời mời" and "Tạm khoá" (no dialog at all)
   - A17 "Lý do" exists but is not marked mandatory
   - A20 invitation (no reason)
   - A21 "Lưu thay đổi", "Áp dụng ngay cho 4 người" (`409:51628`), with no reason and no confirmation
   - C01 inline edits and "Gửi duyệt"
   - A10 "Mở cho 100% gia đình" (08 gap 26, still open)
42. **A12 is not updated for v1.0.** Its filters "Tất cả / Hỗ trợ / Dung lượng / Dữ liệu / Tính năng" (`264:866`) lack:
   - Gia đình: suspend, transfer, resend invitation, full-email reveal, views
   - Nhân sự: invitations, role edits
   - Dữ liệu tham chiếu: imports, approvals
   - analytics exports
   - staff sign-ins

### States and controls implied but not drawn

43. **Undrawn states and controls (G-078):**
   - empty, loading and error states for A13–A21 and C01–C04
   - pagination for A18 (9 of 14), C01 (7 of 14) and C04 (9 of 24)
   - A18 member actions (change role, suspend or reactivate "Tạm ngưng" `408:51284`, revoke, reset 2FA) and the "Lời mời · 2" tab
   - the "Tạo vai trò" form
   - A16 for a deleted or being-deleted family
   - the pending-transfer state
   - success, undo and error toasts
44. **Sidebar visibility and controls.**
   - The four new items (Phân tích, Gia đình, Dữ liệu tham chiếu, Nhân sự & phân quyền) have no role-based visibility drawn. Only one user exists, while A19 hides most functions from Phân tích, Chuyên gia and Kỹ sư.
   - Sign-out, profile and language controls are still missing (G-079).
   - Only a "Production" environment pill is drawn.

---

## 10. v1.1 section (out of scope — names from the metadata dump only)

| Node | Frame | Purpose (from layer text) |
|---|---|---|
| `316:1460` | B01 Bài viết · Danh sách | Article list for the in-app care library ("Nội dung cho Thư viện chăm bé"), with counts (in app, pending, drafts, due for 12-month review), filters by library, topic, age, status, reviewer and language, and "Nhập từ HTML" / "Bài viết mới". |
| `317:1558` | B02 Bài viết · Soạn thảo | Block editor for one article (rich text / HTML, cover image, callout box), settings (library, topic, age range), autosave, "Xem trước trên app", "Gửi duyệt". |
| `317:43747` | B03 Duyệt nội dung | Content review queue across articles, age cards, milestones and Wonder Weeks ("Chờ duyệt · 5 / Đã duyệt · 2 / Cần rà soát lại · 3"), with a checklist and sources. |
| `317:43979` | B04 Duyệt · Xuất bản | The same queue at the publish step (Nháp → Chờ duyệt → Đã duyệt → Xuất bản). |
| `319:2030` | B05 Thẻ theo tuổi · Danh sách | Age cards shown automatically by baby age, with 0–24-month coverage ("14 / 16 khoảng có thẻ") and gaps listed. |
| `319:2345` | B06 Thẻ theo tuổi · Soạn thẻ | Card editor: age window, title (60 characters), up to 3 "what baby is doing" and 3 "try this" points, related articles and milestones, audience (Bố mẹ / Người chăm / Gia đình), app preview. |
| `319:44574` | B07 Mốc phát triển · Danh sách | Reference milestones by group (Vận động, Giao tiếp, Nhận thức, Cảm xúc – xã hội), with age ranges and "Ba mẹ đã ghi" counts. Note: the app does not judge early or late. |
| `319:44815` | B08 Mốc phát triển · Soạn mốc | Milestone editor: group, order, age range, how to recognise it, illustration, expert review ("Thu Hà · Nhóm chuyên môn", re-review after 12 months), sources. |
| `319:45028` | B09 Wonder Week · Danh sách | 10 Wonder Week phases on a 0–80-week timeline, with signs and what baby is learning. |
| `319:45287` | B10 Wonder Week · Soạn giai đoạn | Phase editor: weeks counted from the due date, signs, a reminder 3 days ahead with notification title and body, app preview. |

The sidebar has five v1.1 variants (`315:46970`, `315:47038`, `315:47106`, `315:47173`, `315:47240`), and A19 has a greyed "NỘI DUNG · v1.1" row that promises a "Biên tập" (Editor) role.
