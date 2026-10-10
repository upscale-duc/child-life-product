# H · Admin portal ("Child Life · Vận hành") — staff ops console

Read-only transcription of Figma file `sJLG1fAXKDnDr9YI6Yx8ex`, canvas **"Admin portal" `253:18`**, made 2026-10-10 through the Figma MCP (`get_design_context` and `get_screenshot`). No Figma node was modified. Rendered text is authoritative. Layer names match the rendered text on this page. Vietnamese copy is verbatim, followed by an English gloss in *(italics)*.

This page **answers most of Q-001** in `business-map.md`. The business map said that no portal or dashboard design exists. This canvas holds a 12-screen desktop staff portal (1440 px wide) plus a sidebar component set.

## How each frame was read

| Node | Name | Read method | Status |
|---|---|---|---|
| `253:467` | Admin/Sidebar (component set, 7 variants) | `get_design_context` on variant `253:19` (Active=Tổng quan); variant `253:83` (Active=Hỗ trợ) seen inside A03; other variants checked in A05/A07/A08/A10/A11 screenshots | Full |
| `264:1150` | A01 Đăng nhập | `get_design_context` whole frame | Full |
| `254:151` | A02 Tổng quan | `get_design_context` on Main `254:216` | Full |
| `255:220` | A03 Hỗ trợ | `get_design_context` whole frame | Full |
| `256:293` | A04 Mở rộng dung lượng | `get_design_context` on Main `256:358` | Full |
| `256:559` | A05 Mở rộng dung lượng · Duyệt | `get_design_context` on modal `256:826` + frame screenshot (background = A04) | Full |
| `257:423` | A06 Yêu cầu dữ liệu | `get_design_context` on Main `257:488` | Full |
| `257:708` | A07 Yêu cầu dữ liệu · Chạy lại | `get_design_context` on modal `257:994` + frame screenshot (background = A06) | Full |
| `260:570` | A08 Hệ thống · Dung lượng & media | `get_design_context` on Main `260:635` | Full |
| `261:643` | A09 Hệ thống · AI gợi ý câu chuyện | `get_design_context` on Main `261:708` | Full |
| `263:711` | A10 Tính năng & phát hành | `get_design_context` on Main `263:776` | Full |
| `263:954` | A11 Tính năng · Xác nhận tắt | `get_design_context` on modal `263:1198` + frame screenshot (background = A10) | Full |
| `264:866` | A12 Nhật ký thao tác | `get_design_context` on Main `264:931` | Full |

**Annotation scan:** the local metadata dump (`portal.xml`) shows only 13 top-level children on the canvas: the sidebar set and the 12 frames. There are **no top-level text, sticky or annotation nodes**. All "rules" on this page are in-UI helper notes (lock-icon notes), quoted below.

Canvas layout: A01 sits left of the grid at x = −1540. The other frames form 2 columns, one row per section: A02|A03, A04|A05, A06|A07, A08|A09, A10|A11, A12. Sidebar set above at y = −1200.

---

## Global shell — `253:467` Admin/Sidebar

Dark teal sidebar (300 px wide, `#163d44`). It has 7 variants, `Active=` Tổng quan / Hỗ trợ / Mở rộng dung lượng / Yêu cầu dữ liệu / Hệ thống & AI / Tính năng & phát hành / Nhật ký thao tác. The only change between variants is which item has a white pill. On the active item, its count badge also turns ink-on-white instead of yellow.

| Element | Copy | Behaviour |
|---|---|---|
| Logo | **Child Life** / "Vận hành" *(Operations)* | — |
| Nav 1 | "Tổng quan" *(Overview)* | → A02 |
| Nav 2 | "Hỗ trợ" *(Support)* + badge **12** | → A03; badge = open tickets (matches "Tất cả · 12") |
| Nav 3 | "Mở rộng dung lượng" *(Storage expansion)* + badge **4** | → A04; badge = pending requests |
| Nav 4 | "Yêu cầu dữ liệu" *(Data requests)* + badge **3** | → A06; badge = 3. A06 shows "Đang chạy 3" (2 exports and 1 deletion running) plus 1 failed job. The exact badge semantic is unclear (see the gaps section) |
| Section label | "HỆ THỐNG" *(SYSTEM)* | — |
| Nav 5 | "Hệ thống & AI" *(System & AI)* | → A08 (tab Dung lượng & media) / A09 (tab AI) |
| Nav 6 | "Tính năng & phát hành" *(Features & releases)* | → A10 |
| Nav 7 | "Nhật ký thao tác" *(Action log / audit log)* | → A12 |
| Env pill | "● Production" (yellow) | Environment indicator (inferred: staging/dev variants would differ) |
| User card | avatar "L", "Linh Trần", "Vận hành · Hỗ trợ" *(Operations · Support)* | Signed-in staff member and their role(s). No menu or logout control is drawn |

---

## A01 · Đăng nhập — `264:1150` (Sign in)

**Purpose:** staff sign-in. It is internal-only and separate from consumer auth.

Left brand panel (dark):
- "Child Life" / "Vận hành"
- Headline: "Chăm sóc người dùng, mà không chạm vào kỷ niệm của họ." *(Care for users without touching their memories.)*
- Three ✓ promises (they work as product-level privacy guarantees):
  1. "Không xem được ảnh, video, chú thích hay ghi chép" *(Cannot view photos, videos, captions or care records)*
  2. "Mọi thao tác đều cần lý do và được ghi nhật ký" *(Every action requires a reason and is logged)*
  3. "Chỉ thấy email đã che và mã gia đình ẩn danh" *(Only sees masked emails and anonymised family codes)*
- Footer: "Công cụ nội bộ · chỉ dành cho nhân viên Child Life" *(Internal tool · Child Life staff only)*

Right card "Đăng nhập":
- Sub: "Dùng tài khoản công ty, sau đó nhập mã xác minh 2 bước." *(Use your company account, then enter the 2-step verification code.)*
- Secondary button "Tiếp tục với tài khoản công ty" *(Continue with company account)*. This is a corporate SSO step. The provider is not named, and Google SSO is **not** stated.
- Signed state chip (mint, ✓): "linh.tran@tencongty.vn" *(company account resolved, placeholder domain "tencongty.vn" = "companyname.vn")*
- "Mã xác minh 2 bước" *(2-step code)*: 6 single-digit boxes, shown as 4 8 2 1 _ _ with focus on the 5th box
- Helper: "Mở ứng dụng xác thực trên điện thoại để lấy mã." *(Open the authenticator app on your phone to get the code.)* This means TOTP, not SMS.
- Primary "Đăng nhập" *(Sign in)*
- Foot (clock icon): "Tự đăng xuất sau 30 phút không hoạt động" *(Auto sign-out after 30 minutes of inactivity)*

**Auth method (confirmed):**
- Step 1: company IdP SSO.
- Step 2: mandatory TOTP 2FA from an authenticator app (6 digits).
- Idle timeout: 30 minutes.

**Not shown:** allow-list or role provisioning, error states (wrong code, account not allowed), recovery, lockout, password fields (none exist).

---

## A02 · Tổng quan — `254:151` (Overview dashboard)

**Purpose:** a system-wide aggregate dashboard and a "needs attention" inbox.

Header:
- "Tổng quan" / "Số liệu gộp toàn hệ thống · không chứa ảnh, chú thích hay ghi chép của gia đình nào" *(System-wide aggregate figures · contains no photos, captions or records of any family)*
- Segmented time window "7 ngày" / **"30 ngày"** (selected) / "90 ngày"
- Button "Xuất CSV" *(Export CSV)*. It exports the aggregate metrics (inferred).

KPI tiles (window = selected segment, 30 days shown):

| KPI | Value | Delta copy | Definition (from UI / inferred) |
|---|---|---|---|
| "Gia đình hoạt động" *(Active families)* | 1.284 | "↑ 24% so với 30 ngày trước" *(vs previous 30 days)* | A family with ≥1 care record **or** ≥1 memory in the window. The chart subtitle defines it per day: "Có ít nhất 1 lần ghi hoặc 1 kỷ niệm" *(at least 1 log or 1 memory)*. For the 30-day tile: active at least once in 30 days (inferred) |
| "Tài khoản mới" *(New accounts)* | 1.336 | "↑ 12%" | Accounts created in the window |
| "Hoàn thành thiết lập" *(Setup completed)* | 69% | "↑ 0,6 điểm" *(+0.6 pp)* | Share of new accounts that finished onboarding. The definition is inferred: likely "Tạo hồ sơ bé" (66% in funnel) or a composite. **Not defined in UI** |
| "Gia đình có từ 2 người chăm" *(Families with ≥2 carers)* | 41% | "↑ 3,2 điểm" | Share of (active?) families with ≥2 members who log care (inferred) |

Panel **"Gia đình hoạt động mỗi ngày"** *(Daily active families)*: "Có ít nhất 1 lần ghi hoặc 1 kỷ niệm". Area line chart 10/9 → 9/10, y-axis 0 / 500 / 1.000 / 1.500, last point **1.284**. The last daily value equals the 30-day KPI, which is inconsistent unless the KPI is "latest day" (see the gaps section).

Panel **"Cần xử lý"** *(Needs action)*, count **4**. Each item has a severity pill, a source module (right) and a chevron. Clicking an item deep-links to that module (inferred from the chevron):

| Severity pill | Module | Text |
|---|---|---|
| "Lỗi" *(Error, red)* | Yêu cầu dữ liệu | "1 lần xoá tài khoản thất bại, cần chạy lại" *(1 account deletion failed, needs re-run)* |
| "Cao" *(High, orange)* | Mở rộng dung lượng | "4 gia đình xin mở rộng dung lượng, chờ duyệt" *(4 families requested more storage, awaiting approval)* |
| "Chú ý" *(Warning, amber)* | Hệ thống & AI | "Video xử lý chậm: trung vị 2 phút 10 giây, ngưỡng 2 phút" *(Slow video processing: median 2 min 10 s, threshold 2 min)* |
| "Chờ" *(Waiting, teal)* | Hỗ trợ | "5 yêu cầu hỗ trợ chưa ai nhận quá 4 giờ" *(5 support tickets unclaimed for more than 4 hours)* |

So the alert severity scale is Lỗi > Cao > Chú ý > Chờ. Implied SLAs: support claim within 4 h, video processing median ≤ 2 min.

Panel **"Hành trình bắt đầu dùng"** *(Getting-started funnel)*: "Theo tài khoản mới · 30 ngày" *(by new accounts · 30 days)*. Bars show count and % of step 1:
- "Mở app lần đầu" *(First app open)* 1.920 · 100%
- "Tạo tài khoản" *(Create account)* 1.540 · 80%
- "Xác minh email" *(Verify email)* 1.470 · 77%
- "Tạo hồ sơ bé" *(Create baby profile)* 1.260 · 66%
- "Ghi việc đầu tiên" *(First care log)* 1.046 · 54%
- "Mời người cùng chăm" *(Invite a co-carer)* 612 · 32%

Note: "Mở app lần đầu" counts devices/installs **before** account creation. This requires a pre-auth anonymous analytics event (inferred).

Panel **"Lượt ghi chăm sóc mỗi tuần"** *(Weekly care logs)*: "Chỉ đếm số lần ghi" *(counts only the number of logs)*. Legend: Bú *(feeding)* / Ngủ *(sleep)* / Tã *(diaper)*. Stacked bars for weeks T35–T40, y-axis 0–40k (≈21k→27k). Only counts by care type are shown, never payloads.

**Interactive:** time segment, Xuất CSV, the four "Cần xử lý" items.
**Child data visible:** none. Aggregates only.

---

## A03 · Hỗ trợ — `255:220` (Support inbox)

**Purpose:** a ticket inbox. Staff reply to users using account metadata and diagnostics that the user consented to send.

Header:
- "Hỗ trợ" / "Trả lời người dùng bằng thông tin tài khoản và chẩn đoán họ đồng ý gửi" *(Answer users using account info and diagnostics they agreed to send)*
- Search: "Mã yêu cầu, email đã che…" *(Ticket ID, masked email…)*. Search runs on masked email, not full email.

List panel. Segmented filter: **"Tất cả · 12"** (selected) / "Chưa nhận · 5" *(Unclaimed)* / "Đang xử lý · 4" *(In progress)* / "Chờ người dùng · 3" *(Waiting on user)*. The fourth status "Đã đóng" *(Closed)* appears on rows but has no tab. The counts 5+4+3 = 12, so "Tất cả" counts open tickets only (inferred).

Ticket rows (title, status pill, then "ID · category · masked email", then age):

| ID | Title | Category | Masked email | Status | Age |
|---|---|---|---|---|---|
| CL-1042 (selected) | "Không tải được video lên album" *(Can't upload video to album)* | Kỷ niệm & media | n***@gmail.com | Chưa nhận | 12 phút trước |
| CL-1041 | "Muốn chuyển quyền chủ tài khoản cho chồng" *(Wants to transfer account ownership to husband)* | Gia đình & vai trò | t***@yahoo.com | Chưa nhận | 40 phút trước |
| CL-1039 | "Lời mời bà nội báo hết hạn" *(Grandma's invite says expired)* | Lời mời | h***@gmail.com | Đang xử lý | 1 giờ trước |
| CL-1036 | "Ghi bú lúc mất mạng không thấy trên máy vợ" *(Feed logged offline not visible on wife's phone)* | Đồng bộ | q***@icloud.com | Chờ người dùng | 3 giờ trước |
| CL-1033 | "Đã xoá tài khoản nhưng vẫn nhận email" *(Deleted account but still getting email)* | Tài khoản | m***@gmail.com | Đang xử lý | hôm qua |
| CL-1030 | "Hỏi cách xin thêm dung lượng" *(How to request more storage)* | Dung lượng | p***@gmail.com | Đã đóng | hôm qua |
| CL-1028 | "Thiệp câu chuyện hiện sai ảnh bìa" *(Story card shows wrong cover)* | Câu chuyện | v***@gmail.com | Đã đóng | 2 ngày trước |

Ticket categories seen: Kỷ niệm & media, Gia đình & vai trò, Lời mời, Đồng bộ, Tài khoản, Dung lượng, Câu chuyện.

Detail panel (CL-1042):
- Meta "CL-1042 · Kỷ niệm & media · gửi 12 phút trước" *(sent 12 min ago)*. Title "Không tải được video lên album". Primary button **"Nhận xử lý"** *(Claim / take ownership)*.
- "Người dùng viết" *(User wrote)*: "Mình chọn video 2 phút của con mà app cứ báo "chưa tải được". Ảnh thì vẫn lên bình thường." *(I picked my child's 2-minute video but the app keeps saying "not uploaded yet". Photos upload fine.)* The user's free text is shown verbatim, so it can contain child info that the user typed themselves.
- Tiles: "Vai trò" = **Chủ tài khoản** *(Account owner)*; "Gia đình" = **2 bé · 5 người** *(2 babies · 5 people)*; "Dung lượng gia đình" = **8,2 GB / 10 GB** with a bar.
- "Chẩn đoán" *(Diagnostics)* key-values:
  - "Ứng dụng" = "iOS 1.0.3 · iPhone 13"
  - "Sự kiện gần nhất" *(Latest event)* = "Tải video bị ngắt giữa chừng do mạng yếu · 3 lần trong 20 phút" *(video upload interrupted mid-way by weak network · 3 times in 20 minutes)*
  - "Đồng bộ" *(Sync)* = "Bình thường · lần cuối 2 phút trước" *(Normal · last 2 min ago)*
- "Thao tác được phép" *(Allowed actions)*. The actions depend on the ticket's context (inferred):
  - "⟳ Thử xử lý lại video" *(Retry video processing)*. This re-queues the media job for that upload without exposing the media.
  - "✉ Gửi hướng dẫn tải qua Wi-Fi" *(Send Wi-Fi upload guide)*. This sends a canned help message.
- Lock note: "Hỗ trợ không mở được ảnh, video, chú thích hay ghi chép chăm sóc. Mọi thao tác đều được ghi vào nhật ký." *(Support cannot open photos, videos, captions or care records. Every action is logged.)*
- Composer: placeholder "Trả lời người dùng…" *(Reply to user…)*, "Mẫu trả lời" *(Reply templates)*, primary "Gửi" *(Send)*.

**States shown:** the unclaimed ticket selected. **Not shown:** claimed or assigned view (assignee name), conversation thread history, close/resolve control, how a user creates a ticket (no in-app "contact support" form transcribed. The mobile app has "Trợ giúp & liên hệ", R-123), diagnostics consent UI on mobile, and reply channel (email vs in-app).

**Child data visible:** baby **count** only (2 bé). No baby names, DOB, media, captions or care records. The masked email is the only user identifier.

---

## A04 · Mở rộng dung lượng — `256:293` (Storage-expansion queue)

**Purpose:** review family storage-expansion requests sent from the mobile "Xin thêm dung lượng" flow (R-122, `195:18`).

Header:
- "Mở rộng dung lượng" / "Gia đình dùng gần hết 10 GB và nhắn xin thêm. Duyệt dựa trên số liệu, không xem nội dung." *(Families near 10 GB ask for more. Approve based on metrics, without viewing content.)*
- Segmented: **"Chờ duyệt · 4"** *(Pending)* / "Đã duyệt" *(Approved)* / "Từ chối" *(Declined)*

KPI tiles:
- "Chờ duyệt" **4**: "Cũ nhất gửi 2 ngày trước" *(Oldest sent 2 days ago, amber)*
- "Gia đình dùng trên 80%" *(Families above 80%)* **42**: "Đã nhận nhắc trong app" *(Already received in-app reminder)*
- "Đã mở rộng tháng này" *(Expanded this month)* **11**: "+ 85 GB tổng cộng" *(+85 GB in total)*
- "Thời gian duyệt (trung vị)" *(Median approval time)* **5 giờ**: "Mục tiêu dưới 24 giờ" *(Target under 24 h)*

Table **"Yêu cầu chờ duyệt"** *(Pending requests)*, note "Mã gia đình đã ẩn danh" *(Family codes are anonymised)*. Columns: Mã *(ID)* | Gia đình *(Family)* | Đang dùng *(Using)* | Xin thêm *(Requested)* | Lời nhắn *(Message)* | Gửi lúc *(Sent)* | actions.

| ID | Family (code / composition) | Usage | Requested | Message (user free text) | Sent |
|---|---|---|---|---|---|
| MR-118 (selected) | F-7Q2K · 2 bé · 6 người | 9,6 GB / 10 GB · 96% (orange) | +10 GB | "Con thứ hai mới sinh, cả nhà quay video nhiều." *(Second child just born, whole family films a lot.)* | 2 ngày trước |
| MR-121 | F-3M8D · 1 bé · 4 người | 9,1 GB / 10 GB · 91% (orange) | +10 GB | "Muốn giữ hết video sinh nhật của bé." | hôm qua |
| MR-122 | F-9X1A · 1 bé · 3 người | 8,6 GB / 10 GB · 86% (teal) | **+5 GB** | "Sắp hết chỗ, mình muốn thêm một chút." | 5 giờ trước |
| MR-124 | F-2B6T · 3 bé · 8 người | 9,9 GB / 10 GB · 99% (orange) | +20 GB | "Nhà có ba bé, ông bà cũng tải ảnh lên." | 40 phút trước |

Each row has "Từ chối" *(Decline, secondary)* and "Duyệt" *(Approve, primary → A05)*. The bar colour rule is orange for ≥ 90% and teal below (inferred from 86% teal / 91% orange).

Panel **"F-7Q2K · số liệu dung lượng"** *(storage metrics)*: "Chỉ siêu dữ liệu, không có nội dung" *(Metadata only, no content)*.
- Stacked bar legend: "Ảnh 5,1 GB" / "Video 4,2 GB" / "Khác 0,3 GB" *(Other)* / "Còn trống 0,4 GB" *(Free)*
- "Tốc độ tăng" *(Growth rate)* = "Khoảng 0,8 GB mỗi tháng · hết chỗ sau khoảng 2 tuần" *(≈0.8 GB/month · full in ≈2 weeks)*
- "Lần mở rộng trước" *(Previous expansion)* = "Chưa có" *(None)*
- "Tài khoản tạo" *(Account created)* = "Tháng 3, 2025"
- "Người gửi" *(Requester)* = "Ba mẹ · chủ tài khoản" *(Parent · account owner)*

Panel **"Hướng dẫn duyệt"** *(Approval guidelines)*:
- "+5 GB": "Gia đình 1 bé, dùng ổn định" *(1-baby family, steady use)*
- "+10 GB": "Có từ 2 bé hoặc nhiều video" *(2+ babies or lots of video)*
- "Tuỳ chỉnh" *(Custom)*: "Trên 20 GB cần trưởng nhóm duyệt" *(Over 20 GB needs team-lead approval)*
- Lock note: "Duyệt chỉ thay đổi dung lượng. Không mở ảnh, video hay ghi chép của gia đình." *(Approval only changes quota. Does not open the family's photos, videos or records.)*

Note on the "2 bé" panel vs the "1 tuần" rate: the 0,4 GB free at 0,8 GB/month would be about 2 weeks. This is consistent.

**Child data visible:** baby count, member count, and bytes by media type. No media, no names.

---

## A05 · Mở rộng dung lượng · Duyệt — `256:559` (Approve dialog)

A04 is dimmed behind modal `256:826`. The sidebar user is still Linh Trần · Vận hành · Hỗ trợ.

- Title "Duyệt thêm dung lượng cho F-7Q2K" *(Approve extra storage for F-7Q2K)*; sub "Đang dùng 9,6 GB / 10 GB · 2 bé · 6 người"
- Option chips: "+5 GB" / **"+10 GB"** (selected, pre-set to the requested amount, inferred) / "Tuỳ chỉnh" *(Custom)*. The custom input state is not drawn.
- Field **"Lý do (ghi vào nhật ký thao tác)"** *(Reason, written to the audit log)*: "Gia đình 2 bé, tốc độ tăng khoảng 0,8 GB/tháng."
- Field **"Lời nhắn gửi gia đình"** *(Message to the family)*: "Chúng mình đã thêm 10 GB cho gia đình bạn. Chúc cả nhà thêm thật nhiều khoảnh khắc đẹp bên con!" *(We've added 10 GB for your family…)*
  - Helper: "Gửi qua thông báo trong app và email của chủ tài khoản" *(Sent via in-app notification and the account owner's email)*
- Summary "Dung lượng mới" *(New quota)* **"10 GB → 20 GB"**
- Buttons "Huỷ" *(Cancel)* / **"Duyệt và báo gia đình"** *(Approve and notify family)*

**Rules:** a reason is required for the audit log. Whether it is mandatory is implied by A01 ("Mọi thao tác đều cần lý do"); this field is not marked "bắt buộc" here, unlike A11. The quota is cumulative: the new value is the old one plus the grant. The family gets an in-app notification and an email to the owner.

**Not drawn:**
- the decline dialog (A12 proves a decline has a reason: "Từ chối mở rộng +20 GB … Đã mở rộng 2 lần trong tháng, hẹn xem lại sau 30 ngày.")
- the team-lead approval flow for amounts over 20 GB (who, how, and whether a second person approves)
- an error state

---

## A06 · Yêu cầu dữ liệu — `257:423` (Data-request jobs)

**Purpose:** monitor export and deletion jobs that users requested. Staff can see status and re-run failed jobs. Staff can **never** download the exports.

Header:
- "Yêu cầu dữ liệu" / "Theo dõi việc xuất và xoá dữ liệu theo yêu cầu của người dùng. Nhân viên không mở được nội dung bên trong." *(Track user-requested data exports and deletions. Staff cannot open the content inside.)*

KPIs:
- "Đang chạy" *(Running)* **3**: "2 xuất · 1 xoá" *(2 exports · 1 deletion)*
- "Thất bại trong 24 giờ" *(Failed in 24 h)* **1**: "Cần chạy lại" *(Needs re-run, red)*
- "Thời gian xuất (trung vị)" *(Median export time)* **6 phút**: "30 ngày qua" *(last 30 days)*
- "Xoá xong đúng hạn" *(Deletions completed on time)* **100%**: "18 / 18 yêu cầu". The deadline itself is not stated.

Toolbar: segmented **"Tất cả"** / "Xuất dữ liệu" *(Exports)* / "Xoá dữ liệu" *(Deletions)*. Right side: "Link tải tệp xuất tự hết hạn sau 24 giờ" *(Export download links expire after 24 h)*.

Columns: Mã | Loại *(Type)* | Người yêu cầu · phạm vi *(Requester · scope)* | Tạo lúc *(Created)* | Tiến độ *(Progress)* | Trạng thái *(Status)* | action.

| ID | Type / subtype | Requester · scope | Created | Progress text | Status | Action |
|---|---|---|---|---|---|---|
| DJ-2231 | "Xuất ghi chép chăm sóc" *(Export care records)* / "Tệp CSV" | t***@gmail.com · 1 bé | 10:42 hôm nay | full bar, "Link hết hạn sau 22 giờ" *(link expires in 22 h)* | **Sẵn sàng** *(Ready, teal)* | Nhật ký |
| DJ-2230 | "Xuất toàn bộ ảnh, video" *(Export all photos & videos)* / "Tệp ZIP" | k***@gmail.com · Chủ tài khoản · 2 bé | 10:15 hôm nay | 63%, "1,2 GB / 1,9 GB" | **Đang chuẩn bị** *(Preparing, blue)* | Nhật ký |
| DJ-2228 | "Xoá hồ sơ bé" *(Delete baby profile)* / "Theo yêu cầu ba mẹ" *(at parents' request)* | l***@yahoo.com · 1 bé · 3 người liên quan *(3 people affected)* | 09:58 hôm nay | 40%, "Đã khoá ghi, đang xoá" *(writes locked, deleting)* | **Đang xoá** *(Deleting, blue)* | Nhật ký |
| DJ-2226 | "Xoá tài khoản" *(Delete account)* / "Đã chuyển quyền chủ" *(ownership already transferred)* | v***@gmail.com · 1 gia đình | 08:20 hôm nay | 70% red, "Dừng ở bước xoá ảnh, video" *(stopped at deleting photos/videos)* | **Thất bại** *(Failed, red)* | **Chạy lại** *(Re-run, primary → A07)* |
| DJ-2222 | "Xuất ghi chép chăm sóc" / "Tệp JSON" | a***@gmail.com · 1 bé | Hôm qua 21:03 | grey full, "Người dùng chưa tải" *(user didn't download)* | **Hết hạn** *(Expired, grey)* | Nhật ký |
| DJ-2210 | "Xoá tài khoản" / "Thành viên" *(member, non-owner)* | m***@gmail.com · 1 gia đình | 2/10 | full teal, "Xong sau 3 giờ 12 phút" *(done after 3 h 12 min)* | **Hoàn tất** *(Completed, teal)* | Nhật ký |

Button **"Nhật ký"** *(Log)* opens the job's step log. The target is not drawn (inferred: a per-job step log, or A12 filtered to the job).

Notes (lock icon):
1. "Nhân viên không tải được tệp xuất của người dùng, chỉ xem trạng thái và chạy lại." *(Staff cannot download users' export files; they can only view status and re-run.)*
2. "Chỉ chủ tài khoản xuất được toàn bộ ảnh, video. Quyền được kiểm tra lại ngay trước khi tải." *(Only the account owner can export all photos and videos. Permission is re-checked right before download.)*
3. "Trong lúc xoá, gia đình tạm không ghi được. Không hứa xoá tức thì, không hứa khôi phục." *(During deletion the family temporarily cannot write. No promise of instant deletion, no promise of recovery.)*

**Data-request types (confirmed):**
- Export: care records as CSV or JSON, scoped per baby.
- Export: all photos and videos as ZIP. Owner only.
- Deletion: baby profile, at parent request.
- Deletion: account, with subtypes owner (after transferring ownership) and member.

There is **no "access request / DSAR view"** type and no "rectification" type. Exports are user-initiated in the app (inferred, since the column is "Người yêu cầu"). The mobile export UI is **not** in the mobile Figma extract.

**Child data visible:** baby count and people count only.

---

## A07 · Yêu cầu dữ liệu · Chạy lại — `257:708` (Re-run dialog)

A06 is dimmed behind modal `257:994`. The sidebar user is Linh Trần, while A12 records the re-run by Minh Phạm · Kỹ thuật (mock inconsistency).

- Title "Chạy lại xoá tài khoản DJ-2226?" *(Re-run account deletion DJ-2226?)*
- Sub: "Lần trước dừng ở bước xoá ảnh, video vì mất kết nối tới kho lưu trữ. Các bước đã xong sẽ được bỏ qua." *(Last run stopped at deleting photos/videos due to lost connection to storage. Completed steps will be skipped.)*
- Step list (deletion pipeline, in order):
  1. ✓ "Khoá ghi của gia đình" *(Lock family writes)*
  2. ✓ "Xoá ghi chép chăm sóc" *(Delete care records)*
  3. ✗ "Xoá ảnh, video · dừng ở 70%" *(Delete photos/videos · stopped at 70%)*
  4. ○ "Xoá tài khoản và email" *(Delete account and email)*
  5. ○ "Gửi email xác nhận đã xoá" *(Send deletion-confirmation email)*
- Field "Lý do (ghi vào nhật ký thao tác)" (focused): "Kho lưu trữ đã ổn định lại lúc 09:40." *(Storage was stable again at 09:40.)*
- Clock note: "Người dùng chỉ nhận email khi việc xoá hoàn tất." *(The user only gets an email once deletion completes.)*
- "Huỷ" / "⟳ Chạy lại"

**Re-run semantics (confirmed):** the job is resumable and idempotent per step. Completed steps are skipped, and the job resumes at the failed step. The re-run needs a reason that is logged. No user email is sent on failure or partial progress.

---

## A08 · Hệ thống · Dung lượng & media — `260:570` (System: storage & media)

Header:
- "Hệ thống & AI" / "Dung lượng, xử lý ảnh, video và AI gợi ý câu chuyện · số liệu gộp" *(Storage, photo/video processing and AI story suggestions · aggregate figures)*
- Tabs: **"Dung lượng & media"** (selected) / "AI gợi ý câu chuyện" (→ A09)

KPIs:
- "Ảnh, video đã lưu" *(Photos & videos stored)* **1,82 TB**: "↑ 6,4% tuần này" *(this week)*
- "Gia đình dùng trên 80%" **42**: "Đã nhắc trong app" *(Reminded in app)*
- "Video chờ xử lý" *(Videos awaiting processing)* **18**: "Trung vị 2 phút 10 giây" *(median 2 min 10 s, amber)*
- "Tải lên lỗi · 24 giờ" *(Upload failures · 24 h)* **0,6%**: "↓ 0,2 điểm" *(green)*

Panel **"Dung lượng mỗi gia đình"** *(Usage per family)*, note "Hạn mức 10 GB" *(quota 10 GB)*. Histogram:

| Bucket | Families | Share |
|---|---|---|
| Dưới 1 GB | 820 | 49% |
| 1 – 3 GB | 410 | 25% |
| 3 – 6 GB | 260 | 16% |
| 6 – 8 GB | 130 | 8% |
| 8 – 10 GB | 38 | 2% (orange) |
| Đã mở rộng *(expanded)* | 11 | <1% (purple) |

Total 1,669 families.

Panel **"Video chờ xử lý · 24 giờ qua"** *(Video queue · last 24 h)* with status pill "Trên ngưỡng" *(Above threshold, amber)*. Line chart 0h→23h, y-axis 0–20, dashed line **"Ngưỡng 15 video"** *(threshold 15 videos)*, last point 18.

Table **"Gần hết dung lượng"** *(Near quota)*, note "Mã gia đình đã ẩn danh". Columns: Gia đình | Số bé *(babies)* | Đã dùng *(Used)* | Nhắc gần nhất *(Last reminder)* | Yêu cầu mở rộng *(Expansion request)* | (lock).

| Family | Babies | Used | Last reminder | Request status |
|---|---|---|---|---|
| F-2B6T | 3 bé | 9,9 GB · 99% | Hôm nay 09:10 | Đang chờ duyệt *(Pending)* |
| F-7Q2K | 2 bé | 9,6 GB · 96% | Hôm nay 07:45 | Đang chờ duyệt |
| F-3M8D | 1 bé | 9,1 GB · 91% | Hôm qua | Đang chờ duyệt |
| F-5K2P | 1 bé | 8,7 GB · 87% | 7/10 | Chưa gửi *(Not sent)* |
| F-8H4W | 2 bé | 8,3 GB · 83% | 6/10 | Chưa gửi |

Every row has "🔒 Không xem được ảnh" *(Cannot view photos)*. This is an explicit disabled affordance. There are **no actions on this screen**: staff cannot proactively grant quota from here, and the row has no click target drawn.

---

## A09 · Hệ thống · AI gợi ý câu chuyện — `261:643` (System: AI story suggestions)

Same header as A08. The tab **"AI gợi ý câu chuyện"** is selected.

KPIs:
- "Bản nháp tạo · 7 ngày" *(Drafts generated · 7 days)* **3.420**: "↑ 8% so với tuần trước"
- "Được lưu thành câu chuyện" *(Saved as a story)* **46%**: "Phần lớn sau khi ba mẹ sửa" *(mostly after parents edit)*
- "Chi phí mỗi bản nháp" *(Cost per draft)* **210 đ** (VND): "Đã dùng 62% ngân sách tháng" *(62% of the monthly budget used)*
- "Báo nội dung chưa phù hợp" *(Inappropriate-content reports)* **2**: "Đã xử lý cả 2" *(both handled)*

Panel **"Bản nháp mỗi ngày"** *(Drafts per day)*: "Đang bật cho 50% gia đình" *(enabled for 50% of families)*. Line 27/9 → 9/10, y-axis 0–600, last point **489**.

Panel **"Ba mẹ làm gì với bản nháp"** *(What parents do with drafts)*, "7 ngày qua":
- "Sửa rồi lưu" *(Edit then save)* 28%
- "Lưu ngay" *(Save as-is)* 18%
- "Để đó" *(Leave it)* 41%
- "Xoá" *(Delete)* 13%
- Caption: "Gần một nửa bản nháp được giữ lại — phần lớn sau khi ba mẹ chỉnh lời cho đúng giọng mình." *(Almost half of drafts are kept — mostly after parents adjust the wording to their own voice.)*

Panel **"Ngân sách AI · tháng 10"** *(AI budget · October)*: "Cập nhật 10 phút trước" *(updated 10 min ago)*.
- "9,3 triệu đ" / "/ 15 triệu đ" *(9.3 M of 15 M VND)*
- Bar at 62% with an amber tick at 80%. "62% đã dùng · ngày 10/31" *(62% used · day 10 of 31)*. "Cảnh báo ở 80%" *(Alert at 80%)*.
- Spark note: "Nếu chạm 100%, AI tự tạm dừng gợi ý mới. Câu chuyện đã lưu không bị ảnh hưởng." *(At 100% the AI automatically pauses new suggestions. Saved stories are unaffected.)*

Panel **"Giữ an toàn cho dữ liệu của bé"** *(Keeping the baby's data safe)*. All rows are ✓ and display-only:
- "Gửi ảnh cho AI" *(Send photos to AI)* → "Không · chỉ gửi ghi chép trong tuần" *(No · only the week's records are sent)*
- "Tên thật của bé" *(Baby's real name)* → "Không · dùng biệt danh" *(No · nickname used)*
- "Nhà cung cấp AI lưu dữ liệu" *(AI provider retains data)* → "Không lưu" *(No retention)*
- "Bản nháp mỗi bé" *(Drafts per baby)* → "Tối đa 3 mỗi tuần" *(max 3 per week)*
- Footnote: "Thiết lập đề xuất — cần đội kỹ thuật và pháp lý xác nhận." *(Proposed settings — need engineering and legal confirmation.)*

**Controls on this screen:** none, apart from the tab. Rollout control lives in A10.

**AI metrics (confirmed):** volume (drafts per 7 days, per day), save rate, outcome mix, cost per draft (VND), monthly budget with an 80% alert and a 100% automatic pause, content-report count. The failure rate ("Lỗi tạo bản nháp 0,4%") is shown on A10, not here.

---

## A10 · Tính năng & phát hành — `263:711` (Feature flags & rollout)

Header:
- "Tính năng & phát hành" / "Bật, tắt và mở dần tính năng. Mọi thay đổi cần lý do và được ghi vào nhật ký thao tác." *(Turn on, turn off and gradually roll out features. Every change requires a reason and is logged.)*

Panel **"Công tắc tính năng"** *(Feature switches)*. Lock note: "Công tắc chỉ bật hoặc tắt tính năng, không thay đổi quyền xem của ai. Khi tắt tải lên, gia đình vẫn ghi chăm sóc, xem kỷ niệm cũ, xuất và xoá dữ liệu bình thường." *(Switches only turn features on/off and never change anyone's viewing rights. When upload is off, families can still log care, view old memories, and export/delete data normally.)*

Columns: Tính năng *(Feature)* | Phạm vi *(Scope)* | Sửa gần nhất *(Last edited)* | Bật *(On)*.

| Display name | Description | Flag key | Scope | Last edit | State |
|---|---|---|---|---|---|
| "Tải ảnh, video mới" *(Upload new photos/videos)* | "Tắt khi kho lưu trữ gặp sự cố" *(turn off when storage has an incident)* | `media_upload` | Tất cả *(All)* | Minh · 29/9 | ON |
| "Tải video" *(Video upload)* | "Video trong album và kỷ niệm" | `video_upload` | Tất cả | Minh · 29/9 | ON |
| "AI gợi ý câu chuyện" | "Bản nháp câu chuyện mỗi tuần" *(weekly story drafts)* | `ai_story_drafts` | pill **"Mở dần · 50%"** *(Gradual rollout · 50%)* | Linh · 2/10 | ON |
| "Chia sẻ thiệp ra ngoài" *(External card sharing)* | "Link riêng, thiệp ảnh qua mạng xã hội" *(private link, image card via social)* | `story_share_link` | Tất cả | Linh · 1/10 | ON |
| "Gửi lời mời mới" *(Send new invites)* | "Mời người chăm, người thân" | `invites` | Tất cả | — | ON |
| "Widget màn hình khoá" *(Lock-screen widget)* | "Ghi nhanh không cần mở app" *(quick log without opening app)* | `lock_widgets` | Tất cả | — | ON |
| "Night care tự bật" *(Night care auto-on)* | "Tự chuyển giao diện tối theo giờ" *(auto dark UI by schedule)* | `night_auto` | pill **"Thử nội bộ"** *(Internal testing)* | Linh · 8/10 | **OFF** |

The scope values seen are "Tất cả" *(All)*, "Mở dần · N%" *(Gradual · N%)* and "Thử nội bộ" *(Internal testing)*. There is **no platform (iOS/Android) or app-version targeting** column.

Right column:
- Panel **"Mở dần · AI gợi ý câu chuyện"** *(Rollout · AI story suggestions)*:
  - Step ladder "10%" → "25%" → **"50%"** (current, filled) → "100%" (next, grey). Passed steps are mint.
  - Guard metrics, each ✓ with a threshold:
    - "Báo nội dung chưa phù hợp" → "0,06% · dưới 0,1%" *(below 0.1%)*
    - "Chi phí" → "62% ngân sách tháng"
    - "Lỗi tạo bản nháp" *(Draft generation errors)* → "0,4% · dưới 1%"
  - Primary button **"Mở cho 100% gia đình"** *(Open to 100% of families)*. This advances the ladder. It probably requires a reason (inferred from header copy). No dialog is drawn.
- Panel **"Giới hạn hiện tại"** *(Current limits)*:
  - "Dung lượng mỗi gia đình" → "10 GB · mở rộng khi cần" *(expand when needed)*
  - "Độ dài video" *(Video length)* → **"Không giới hạn"** *(Unlimited)*
  - "Link tải dữ liệu đã xuất" → "Hết hạn sau 24 giờ"
- Panel **"Thay đổi gần đây"** *(Recent changes)*:
  - "Mở “AI gợi ý câu chuyện” lên 50%" — "Linh · 2/10 · Chi phí ổn định sau 1 tuần ở 25%" *(cost stable after 1 week at 25%)*
  - "Tắt rồi bật lại “Tải video”" — "Minh · 29/9 · Hàng xử lý quá tải 40 phút" *(processing queue overloaded 40 min)*

**Feature-flag semantics (confirmed):**
- Flags are global kill switches (boolean). Some have a percentage rollout by family ("50% gia đình"), so the bucketing unit is the **family** (inferred from the copy).
- Some have an internal-only cohort.
- Toggling never changes permissions.
- Turning off upload degrades the app gracefully (see A11).
- Every change needs a reason and is logged.
- Rollout steps are 10 / 25 / 50 / 100% with guard metrics.

---

## A11 · Tính năng · Xác nhận tắt — `263:954` (Confirm feature off)

A10 is dimmed behind modal `263:1198`. The sidebar user is Linh Trần, while A12 shows the real off/on was done by Minh Phạm · Kỹ thuật.

- Red alert icon. Title "Tắt “Tải video” cho tất cả gia đình?" *(Turn off "Video upload" for all families?)*
- Sub: "Gia đình vẫn xem được video cũ. Video đang tải dở sẽ chờ và tự tải tiếp khi bật lại." *(Families can still view old videos. In-progress uploads will wait and resume automatically when re-enabled.)*
- Impact row "Ảnh hưởng" *(Impact)* = "~1.284 gia đình đang hoạt động" *(~1,284 active families)*
- Field **"Lý do (bắt buộc, ghi vào nhật ký)"** *(Reason, mandatory, logged)* (focused): "Hàng xử lý video quá tải hơn 40 phút, tạm dừng để xử lý tồn đọng." *(Video queue overloaded > 40 min, pausing to clear backlog.)*
- Checkbox (checked) **"Báo cho gia đình trong app"** *(Notify families in app)*, with preview: "Tải video đang tạm dừng một chút, chúng mình sẽ mở lại sớm." *(Video upload is paused for a bit, we'll reopen soon.)*
- "Huỷ" / **"Tắt tính năng"** *(Turn off feature, destructive red)*

**Client contract implied:**
- While `video_upload` is off, the app keeps queued or in-flight video uploads locally (state "waiting") and auto-resumes them when the flag returns.
- Old videos remain viewable.
- An optional in-app banner or notice is broadcast.

---

## A12 · Nhật ký thao tác — `264:866` (Staff audit log)

Header:
- "Nhật ký thao tác" / "Mọi thao tác của nhân viên được ghi lại. Nhật ký chỉ thêm, không sửa hay xoá được." *(Every staff action is recorded. The log is append-only and cannot be edited or deleted.)*
- Button "Xuất CSV"

Filters:
- Search "Mã yêu cầu, mã gia đình, người làm…" *(Request ID, family code, actor…)*
- Segmented "Tất cả" / "Hỗ trợ" / "Dung lượng" / "Dữ liệu" / "Tính năng"
- Date dropdown "7 ngày qua" *(Last 7 days)*

Columns: Thời gian *(Time)* | Người làm *(Actor, name + role)* | Thao tác *(Action + category pill)* | Đối tượng *(Target ID, monospace)* | Lý do *(Reason)*.

| Time | Actor · role | Action | Category | Target | Reason |
|---|---|---|---|---|---|
| 10:52 hôm nay | Linh Trần · Vận hành | "Duyệt mở rộng +10 GB" | Dung lượng | F-7Q2K | "Gia đình 2 bé, tốc độ tăng 0,8 GB/tháng." |
| 10:40 hôm nay | Hà Nguyễn · Hỗ trợ | "Nhận xử lý yêu cầu hỗ trợ" *(Claim ticket)* | Hỗ trợ | CL-1042 | "—" (no reason) |
| 09:44 hôm nay | Minh Phạm · Kỹ thuật | "Chạy lại xoá tài khoản" | Dữ liệu | DJ-2226 | "Kho lưu trữ đã ổn định lại lúc 09:40." |
| 09:12 hôm nay | Hà Nguyễn · Hỗ trợ | "Gửi hướng dẫn tải qua Wi-Fi" | Hỗ trợ | CL-1039 | "Người dùng hỏi lại về lời mời." |
| Hôm qua 17:30 | Linh Trần · Vận hành | "Từ chối mở rộng +20 GB" *(Decline +20 GB)* | Dung lượng | F-1C9R | "Đã mở rộng 2 lần trong tháng, hẹn xem lại sau 30 ngày." *(Already expanded twice this month; review again in 30 days.)* |
| 2/10 14:05 | Linh Trần · Vận hành | "Mở “AI gợi ý câu chuyện” lên 50%" | Tính năng | ai_story_drafts | "Chi phí ổn định sau 1 tuần ở 25%." |
| 29/9 21:18 | Minh Phạm · Kỹ thuật | "Bật lại “Tải video”" | Tính năng | video_upload | "Đã xử lý xong hàng tồn." *(Backlog cleared.)* |
| 29/9 20:38 | Minh Phạm · Kỹ thuật | "Tắt “Tải video”" | Tính năng | video_upload | "Hàng xử lý quá tải 40 phút." |

Lock note: "Nhật ký không chứa nội dung của gia đình — chỉ mã, thao tác và lý do. Lưu tối thiểu 2 năm (đề xuất)." *(The log contains no family content — only IDs, action and reason. Retain at least 2 years (proposed).)*

**Audit requirements (confirmed):**
- Every staff mutation is logged (approve, decline, claim, help macro, re-run, flag change).
- The log is append-only and immutable.
- Each entry has time, actor (name + role), action, category, target ID and reason.
- Entries contain no family content.
- Retention is at least 2 years (proposed).
- The log can be exported to CSV.
- Staff sign-ins and read/lookups are **not** shown as logged events (see the gaps section).

---

## Staff roles & permission matrix (confirmed)

Role labels seen:
- **"Vận hành"** *(Operations)*: Linh Trần. The sidebar shows the combined label "Vận hành · Hỗ trợ".
- **"Hỗ trợ"** *(Support)*: Hà Nguyễn.
- **"Kỹ thuật"** *(Engineering)*: Minh Phạm.
- **"trưởng nhóm"** *(team lead)*: mentioned in A04 guidance only.

Only one sidebar user is drawn (Linh). The design does **not** show role-based hiding of nav items or disabled controls. Every screen is shown to the same Vận hành · Hỗ trợ user.

| Action | Evidence of who did it | Rule shown | Matrix status |
|---|---|---|---|
| View aggregates (A02, A08, A09) | any staff (Linh) | aggregates only | Confirmed for Vận hành; others (inferred) all staff |
| Claim ticket / send help macro / reply | Hà Nguyễn · Hỗ trợ (A12); Linh in A03 | "Thao tác được phép" list per ticket | Confirmed Hỗ trợ |
| Retry video processing (support) | button in A03 | logged | Hỗ trợ (inferred) |
| Approve or decline storage ≤ 20 GB | Linh Trần · Vận hành (A12) | reason logged; message to family | Confirmed Vận hành |
| Approve storage > 20 GB / custom | — | "Trên 20 GB cần trưởng nhóm duyệt" | Team lead. Mechanism (second approver vs role gate) **not drawn** |
| Re-run data job | Minh Phạm · Kỹ thuật (A12); Linh in A07 UI | reason logged | Kỹ thuật confirmed; Vận hành shown in UI (conflict) |
| Download user export | nobody | "Nhân viên không tải được tệp xuất" | **Forbidden to all staff** |
| Open photo, video, caption or care record | nobody | A01, A03, A04, A08 lock notes | **Forbidden to all staff** |
| Toggle a kill switch | Minh Phạm · Kỹ thuật (29/9) | reason mandatory; optional in-app notice | Kỹ thuật confirmed |
| Advance rollout % | Linh Trần · Vận hành (2/10) | guard metrics; reason logged | Vận hành confirmed |
| Edit global limits (10 GB, video length, link TTL) | — | display only | Not editable in design |
| View or export audit log | Linh (sidebar) | append-only | all staff (inferred) |

**Two-person rules:** none drawn. The only escalation is "> 20 GB → trưởng nhóm duyệt". No four-eyes rule is shown on deletion re-runs or kill switches.

---

## Business rules confirmed (verbatim evidence)

1. **Privacy boundary:**
   - "Không xem được ảnh, video, chú thích hay ghi chép" (A01 `264:1167`)
   - "Hỗ trợ không mở được ảnh, video, chú thích hay ghi chép chăm sóc. Mọi thao tác đều được ghi vào nhật ký." (A03 `255:419`)
   - "Duyệt chỉ thay đổi dung lượng. Không mở ảnh, video hay ghi chép của gia đình." (A04 `256:558`)
   - "Không xem được ảnh" per row (A08)
   - "Số liệu gộp toàn hệ thống · không chứa ảnh, chú thích hay ghi chép của gia đình nào" (A02 `254:232`)
2. **Pseudonymisation:**
   - "Chỉ thấy email đã che và mã gia đình ẩn danh" (A01 `264:1177`)
   - "Mã gia đình đã ẩn danh" (A04 `256:390`, A08 `260:743`)
   - Emails rendered `x***@domain`; families rendered `F-XXXX`.
3. **Reason + audit:**
   - "Mọi thao tác đều cần lý do và được ghi nhật ký" (A01 `264:1172`)
   - "Lý do (ghi vào nhật ký thao tác)" (A05 `256:838`, A07 `257:1025`)
   - "Lý do (bắt buộc, ghi vào nhật ký)" (A11 `263:1211`)
   - Exception: claiming a ticket is logged with reason "—" (A12 `264:1017`).
4. **Audit log immutability:** "Nhật ký chỉ thêm, không sửa hay xoá được." (A12 `264:940`). Retention: "Lưu tối thiểu 2 năm (đề xuất)." (A12 `264:1149`)
5. **Staff auth:**
   - "Dùng tài khoản công ty, sau đó nhập mã xác minh 2 bước." (`264:1183`)
   - "Mở ứng dụng xác thực trên điện thoại để lấy mã." (`264:1206`)
   - "Tự đăng xuất sau 30 phút không hoạt động" (`264:1212`)
6. **Storage grants:**
   - Guidance "+5 GB · Gia đình 1 bé, dùng ổn định", "+10 GB · Có từ 2 bé hoặc nhiều video", "Tuỳ chỉnh · Trên 20 GB cần trưởng nhóm duyệt" (A04 `256:545–553`)
   - Approval SLA target "Mục tiêu dưới 24 giờ" (`256:385`)
   - Grant is additive "10 GB → 20 GB" (`256:849`)
   - Notification "Gửi qua thông báo trong app và email của chủ tài khoản" (`256:845`)
   - Decline precedent: "Đã mở rộng 2 lần trong tháng, hẹn xem lại sau 30 ngày." (`264:1080`)
7. **Near-full reminder:** families above 80% "Đã nhận nhắc trong app" (A04 `256:377`). This is consistent with mobile R-121 (≥ 80%).
8. **Exports:**
   - "Link tải tệp xuất tự hết hạn sau 24 giờ" (A06 `257:520`; A10 `263:944`)
   - "Chỉ chủ tài khoản xuất được toàn bộ ảnh, video. Quyền được kiểm tra lại ngay trước khi tải." (`257:702`)
   - "Nhân viên không tải được tệp xuất của người dùng, chỉ xem trạng thái và chạy lại." (`257:697`)
   - Formats: CSV, JSON (care), ZIP (media).
9. **Deletion:**
   - "Trong lúc xoá, gia đình tạm không ghi được. Không hứa xoá tức thì, không hứa khôi phục." (`257:707`)
   - Pipeline order: lock writes → delete care → delete media → delete account and email → confirmation email (`257:1002–1022`)
   - "Các bước đã xong sẽ được bỏ qua." (`257:997`)
   - "Người dùng chỉ nhận email khi việc xoá hoàn tất." (`257:1032`)
   - Account deletion for an owner requires ownership transfer first: "Đã chuyển quyền chủ" (`257:619`). This is consistent with R-046.
10. **Feature flags:**
    - "Công tắc chỉ bật hoặc tắt tính năng, không thay đổi quyền xem của ai. Khi tắt tải lên, gia đình vẫn ghi chăm sóc, xem kỷ niệm cũ, xuất và xoá dữ liệu bình thường." (`263:789`)
    - "Video đang tải dở sẽ chờ và tự tải tiếp khi bật lại." (`263:1205`)
11. **AI budget and safety:**
    - "Nếu chạm 100%, AI tự tạm dừng gợi ý mới. Câu chuyện đã lưu không bị ảnh hưởng." (`261:803`)
    - "Cảnh báo ở 80%" (`261:798`)
    - "Gửi ảnh cho AI · Không · chỉ gửi ghi chép trong tuần"; "Tên thật của bé · Không · dùng biệt danh"; "Nhà cung cấp AI lưu dữ liệu · Không lưu"; "Bản nháp mỗi bé · Tối đa 3 mỗi tuần" (`261:807–826`). These are flagged "Thiết lập đề xuất — cần đội kỹ thuật và pháp lý xác nhận." (`261:827`)
    - Rollout guards "dưới 0,1%" content reports, "dưới 1%" generation errors (`263:918`, `263:928`)
12. **Ops thresholds:**
    - Support "chưa ai nhận quá 4 giờ" (`254:319`)
    - Video median threshold "ngưỡng 2 phút" (`254:309`)
    - Video queue threshold "Ngưỡng 15 video" (`260:728`)
13. **Limits:** "Độ dài video · Không giới hạn" (`263:941`); "Dung lượng mỗi gia đình · 10 GB · mở rộng khi cần" (`263:938`).

---

## Entities & fields implied

- **StaffUser**:
  - name, company email (SSO identity), role(s) {Vận hành, Hỗ trợ, Kỹ thuật, trưởng nhóm}
  - TOTP enrolment
  - session with 30-minute idle timeout
  - environment (Production)
- **SupportTicket**:
  - id `CL-####`, title, category {Kỷ niệm & media, Gia đình & vai trò, Lời mời, Đồng bộ, Tài khoản, Dung lượng, Câu chuyện}
  - requester masked email, user message (free text), createdAt
  - status {Chưa nhận, Đang xử lý, Chờ người dùng, Đã đóng}, assignee (inferred)
  - replies, reply template id
  - attached diagnostics snapshot
- **DiagnosticsSnapshot** (consented): app platform + version, device model, recent event summaries (e.g. upload interruptions with count/window), sync health + last sync time. Also account role (Chủ tài khoản), family composition (babies count, members count), family storage used/quota.
- **StorageRequest**:
  - id `MR-###`, familyCode `F-XXXX`, requested amount {+5, +10, +20, custom}, user message, sentAt
  - requester role ("Ba mẹ · chủ tài khoản")
  - status {Chờ duyệt, Đã duyệt, Từ chối}
  - decision: grantedBytes, staff reason, family message, decidedBy, decidedAt
- **FamilyStorageMetrics** (metadata only):
  - bytes by type {Ảnh, Video, Khác}, free, quota
  - growth rate (GB/month) and projected time to full
  - previous expansions, account createdAt
  - last near-full reminder at, babies count, members count
- **DataJob**:
  - id `DJ-####`, type {export_care (CSV | JSON), export_media (ZIP), delete_baby, delete_account (owner-after-transfer | member)}
  - requester masked email, scope (N bé / N người liên quan / 1 gia đình), createdAt
  - progress (bytes or %), current step, failure step + cause
  - status {Đang chuẩn bị, Sẵn sàng, Hết hạn, Đang xoá, Thất bại, Hoàn tất}
  - downloadLinkExpiresAt (24 h), downloaded flag
  - steps[] {name, state}, duration
  - deadline (for "đúng hạn"; value unknown)
- **FeatureFlag**:
  - key (`media_upload`, `video_upload`, `ai_story_drafts`, `story_share_link`, `invites`, `lock_widgets`, `night_auto`)
  - display name, description, enabled
  - scope {all, percentage (family-bucketed), internal}, rollout step ladder
  - lastEditedBy/at
  - guard metrics + thresholds
  - optional user-facing notice text on toggle
- **GlobalLimits**: family quota 10 GB, max video length (none), export link TTL 24 h. The weekly AI draft cap per baby (3) is proposed.
- **AIBudget**: month, spent VND, budget VND, alert threshold 80%, hard stop 100%, updatedAt. Also cost per draft.
- **AIDraftStats**: drafts per day/week, outcome {edited+saved, saved as-is, left, deleted}, inappropriate-content reports (count, handled), generation error rate.
- **OpsAlert** ("Cần xử lý"): severity {Lỗi, Cao, Chú ý, Chờ}, source module, text, deep link.
- **AuditEntry**: time, actor (name, role), action, category {Hỗ trợ, Dung lượng, Dữ liệu, Tính năng}, target ID, reason. Immutable, retained ≥ 2 years.
- **Analytics aggregates**: active families (daily, windowed), new accounts, setup completion, families with ≥ 2 carers, onboarding funnel events (first open → account → verify email → baby profile → first log → invite), weekly care-log counts by type, media bytes stored, upload failure rate, video queue depth and median processing latency, storage histogram.

---

## State machines

**Storage request** (A04/A05/A08/A12):
`Chưa gửi` (family above 80%, no request; displayed in A08) → `Chờ duyệt` / "Đang chờ duyệt" (sent from mobile 13e) → `Đã duyệt` (quota += grant; in-app + email to owner) | `Từ chối` (reason logged; the user-facing decline message is not drawn).

Amounts over 20 GB or custom amounts need a team-lead step. Where that step sits is not drawn (inferred: an extra "chờ trưởng nhóm" sub-state).

**Data job: export** (A06):
`Đang chuẩn bị` (progress in bytes) → `Sẵn sàng` (link valid 24 h; "Link hết hạn sau N giờ") → `Hết hạn` ("Người dùng chưa tải") | downloaded (state not drawn).

Failure for exports is not drawn (inferred: `Thất bại` → re-run as for deletion).

**Data job: deletion** (A06/A07):
`Đang xoá` ("Đã khoá ghi, đang xoá") with steps: lock writes → delete care → delete media → delete account + email → confirmation email. The job ends as `Hoàn tất` ("Xong sau 3 giờ 12 phút") or `Thất bại` ("Dừng ở bước …").

From `Thất bại`, "Chạy lại" (with a reason) resumes at the failed step and skips completed steps, returning to `Đang xoá`. A queued or pending state before start is not drawn.

**Feature flag** (A10/A11):
- `OFF` ⇄ `ON` (each change needs a reason + audit; optional in-app notice).
- Scope ladder: `Thử nội bộ` → `Mở dần 10%` → `25%` → `50%` → `100% / Tất cả`. Promotion is gated by guard metrics: content reports < 0.1%, generation errors < 1%, budget headroom.
- Separately, `ai_story_drafts` auto-pauses new suggestions at 100% of the AI budget. This is a system-driven pause, not a staff toggle.

**Support ticket** (A03):
`Chưa nhận` → (Nhận xử lý) `Đang xử lý` ⇄ `Chờ người dùng` → `Đã đóng`.

The A02 alert fires when `Chưa nhận` lasts more than 4 h. Reopen, close and auto-close transitions are not drawn.

---

## Integration points with the mobile app / backend

1. **Storage request ingestion:** mobile 13e "Xin thêm dung lượng" (R-122, `195:18`) creates `StorageRequest` (+10 / +20 / Khác + optional message). The portal's approve call writes `family.quotaBytes`, so WaitingQuota uploads resume (business-map §8 "Grant storage"). Notifications go to the owner through an in-app notice + email.
   - **Mismatch:** mobile copy says "Quản trị Child Life sẽ trả lời qua email". The portal also sends an in-app notice.
   - **Mismatch:** mobile does not offer "+5 GB", but MR-122 requests +5 GB.
2. **Near-full reminders:** a backend job flags families above 80% and sends the in-app reminder (R-121). The portal reads "Nhắc gần nhất".
3. **Support tickets + diagnostics:** the mobile app needs a ticket-submit entry (likely "Trợ giúp & liên hệ", R-123) with a **diagnostics consent** step. It sends app version, device model, recent upload/sync event summaries and sync status. Telemetry must exclude child data (brief §05). Staff replies reach the user via a channel not specified (inferred: email and/or in-app).
4. **Support remote actions:** "Thử xử lý lại video" re-enqueues the media-processing job for the user's upload. "Gửi hướng dẫn tải qua Wi-Fi" sends a canned message.
5. **Data jobs:** the mobile app must offer (not in the mobile Figma extract):
   - export care (CSV/JSON) per baby
   - export all media ZIP (owner only, permission re-checked at download)
   - delete baby (13l `requestBabyDeletion`)
   - delete account
   
   The backend runs a resumable step pipeline:
   - It locks family writes during deletion, so the client must handle a "writes locked" state.
   - It emails the user only on completion.
   - It provides 24-hour signed download links that are not accessible to staff.
6. **Feature flags (remote config):** the clients read `media_upload`, `video_upload`, `ai_story_drafts` (family-bucketed %), `story_share_link`, `invites`, `lock_widgets`, `night_auto` (internal cohort).
   - Upload-off behaviour: keep items queued locally and auto-resume.
   - Optional in-app notice push/banner.
   - The server must enforce the flags too (inferred).
7. **AI pipeline:** the weekly draft scheduler uses records only (no photos), the nickname not the real name, and a no-retention provider. It is capped at 3 drafts per baby per week, has a budget meter with an 80% alert and a 100% automatic pause, and tracks error rate and content reports.
   - The mobile app needs a "báo nội dung chưa phù hợp" (report inappropriate) action on AI drafts. This action is not in the mobile Figma.
8. **Analytics events:** first_open (pre-auth), account_created, email_verified, baby_created, first_care_log, invite_sent/accepted, care_log counts by type, memory created, draft outcome (edited_saved / saved / ignored / deleted), upload failure, video processing latency. All must exclude content.
9. **Staff identity:** company SSO + TOTP. Business-map Q-001 proposed "Google SSO + allow-list + custom claims", but **Google is not named in Figma**.
10. **Audit:** every portal mutation writes an immutable `AuditEntry`. Retention is at least 2 years (proposed).

---

## Open questions / gaps (with node ids)

1. **SSO provider and allow-list** (`264:1185`): "tài khoản công ty" is not named (Google Workspace vs Microsoft). The allow-list, role provisioning, TOTP enrolment, recovery, lockout and error states are not drawn.
2. **Role-based access** (`253:467`): only one user (Vận hành · Hỗ trợ) is drawn, and every screen is visible to them. Should Hỗ trợ see flags or data jobs? Can Vận hành toggle kill switches? A07/A11 show Linh, while A12 attributes those actions to Minh · Kỹ thuật.
3. **Team-lead approval for over 20 GB** (`256:553`): how is it enforced (role gate vs second approver)? No UI. Also, is the "+20 GB" request MR-124 itself "trên 20 GB"? The threshold reads "Trên 20 GB", so it is exclusive.
4. **Decline dialog and user message** (`256:425`): not drawn. Is a decline message sent to the family? What text?
5. **Custom amount input** (`256:836`): not drawn. Is there a maximum quota?
6. **+5 GB request option** (MR-122 `256:469`): mobile 13e offers only +10 / +20 / Khác. Either mobile gains +5 or the row is a "Khác" (custom) request.
7. **A08 list omits F-9X1A** (`260:740`): F-9X1A is pending at 86% but missing from "Gần hết dung lượng". Is the list top-N, or is it a mock error? A04 says 4 pending; A08 shows 3 "Đang chờ duyệt".
8. **Video threshold definitions** (`254:309` vs `260:728`): there are two thresholds, median processing time 2 min and queue depth 15. Which one triggers the A02 alert?
9. **"Gia đình hoạt động" KPI vs chart** (`254:235`, `254:267`): the 30-day KPI equals the last daily point (1.284). Define KPI = latest-day DAU vs 30-day MAU. A11 "~1.284 gia đình đang hoạt động" uses the same number.
10. **"Hoàn thành thiết lập" definition** (`254:241`): 69% does not match any funnel step (Tạo hồ sơ bé = 66%).
11. **Sidebar badge "Yêu cầu dữ liệu · 3"** (`253:54`): running jobs (3), or items needing action (1 failed)?
12. **Ticket intake and consent** (`255:294`): there is no mobile "contact support" form or diagnostics-consent screen in the mobile Figma. The reply channel (email/in-app) is unspecified. Assignee display, history thread and close action are not drawn. The tab counts exclude "Đã đóng".
13. **User free text** (`255:379`, `256:421`): ticket and request messages may contain child names or health details that the parent typed. Is this an accepted exception to "không xem ghi chép"? Should messages be redacted or have retention limits?
14. **Read/lookup auditing** (`264:965`): the log shows only mutations. Are views of tickets or family metrics also logged? Are staff sign-ins logged?
15. **Claim without reason** (`264:1017`): "—" conflicts with "Mọi thao tác đều cần lý do". Confirm the exemption list (claim, reply).
16. **CL-1039 action/reason mismatch** (`264:1051–1059`): "Gửi hướng dẫn tải qua Wi-Fi" on an invite ticket with reason "Người dùng hỏi lại về lời mời". This looks like mock data. Confirm whether macros are per category.
17. **Data-request types** (`257:510`): no "access/view my data" (DSAR) type, no export of stories, memories metadata or account data. Is account-data export needed for PDPD/GDPR? The deadline behind "Xoá xong đúng hạn" is not stated. The mobile UI for requesting exports is not designed.
18. **Export failure and re-run for exports** (`257:510`): only deletion failure is drawn. Can staff re-trigger an expired export, or must the user request again?
19. **"Nhật ký" per job** (`257:559`): the destination is not drawn.
20. **Deletion pipeline completeness** (`257:998`): the steps omit stories, links, albums, derived assets, reminders, Live Activity / widget cleanup and quota release, which are listed in business-map §8 "Delete baby". It is unclear whether the 5 steps are a simplification.
21. **AI "no photos" vs mobile "AI viết nháp từ 9 ảnh"** (`261:811` vs mobile R-131 `205:18`): if photos are not sent, how is the draft "from 9 photos"? Possibly metadata/captions only. Needs engineering and legal confirmation, as the footnote `261:827` itself says.
22. **AI cost arithmetic** (`261:728` vs `261:791`, `261:751`): 9.3 M đ ÷ 210 đ ≈ 44k drafts in 10 days, but the chart shows ≈ 490/day. These look like placeholder numbers.
23. **AI cap "Tối đa 3 mỗi tuần"** (`261:826`) vs mobile single "Gợi ý tuần này" card (R-130): what are the 3 drafts?
24. **Content report flow** (`261:730`, `263:918`): there is no "Báo nội dung chưa phù hợp" action in the mobile design and no staff review queue in the portal. "Đã xử lý cả 2" means nothing without a handling UI.
25. **Flag targeting** (`263:790`): there is no platform, app-version or region targeting. The bucketing unit (family vs user) is inferred from "50% gia đình". Should `night_auto` be a server flag at all, given it is "Thử nội bộ" and OFF? The cohort definition for "Thử nội bộ" is unknown.
26. **"Mở cho 100% gia đình" confirmation** (`263:929`): no reason dialog is drawn, although the header says every change needs a reason.
27. **`media_upload` last edit "Minh · 29/9"** (`263:808`): A12 shows only `video_upload` changes that day. Either a log entry is missing or this is mock data.
28. **Global limits editability** (`263:933`): display-only? "Độ dài video · Không giới hạn" combined with the 10 GB quota should be confirmed against mobile upload rules.
29. **CSV exports from A02/A12** (`254:224`, `264:932`): is exporting the audit log itself logged, and which roles may do it?
30. **Environment pill** (`253:74`): are there staging/test variants? Is the "Production" label shown to support staff?
31. **Logout and profile menu** (`253:82`): no control is drawn.
32. **Empty, loading and error states:** none drawn for any list (no pending requests, no tickets, job list empty, MCP/API failure).
