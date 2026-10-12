# Admin portal v1.0 — review and plan (2026-10-11)

Source: Figma `253:18` "Admin portal", section **v1.0** (28 frames), extracted in
[`../discovery/figma-extract/18-admin-portal-v1.md`](../discovery/figma-extract/18-admin-portal-v1.md)
(the 2026-10-10 baseline is `08-admin-portal.md`). Owner request: "lên kế hoạch để triển khai lại portal
admin như design … v1.0, phân tích thêm và bổ sung nếu design chưa logic chặt chẽ; edit mobile nếu cần
thiết cho data thống kê; cập nhật docs; giữ phần developer trước đó".

Status: **built on branch `s2-onboarding` (2026-10-11), committed 2026-10-12 and deployed to dev** — the owner answered Q-040 …
Q-046 in **D-053** (no 2FA, no family suspension, any email domain, first Owner nvduc2910@gmail.com,
defaults for the rest) and asked to build it. What was built, the tests and what is left are in
[`../development/slice-reports/S15b.md`](../development/slice-reports/S15b.md). Proposals P-134 … P-139
and design gaps G-085 … G-091 are in [`business-map.md`](business-map.md). The section **v1.1** (B01–B10:
Bài viết, Duyệt nội dung, Thẻ theo tuổi, Mốc phát triển, Wonder Week) is out of scope here.

The QA handbook ("Phát triển › Sổ tay kiểm thử", P-132, built 2026-10-11) is **kept** as is: a
"PHÁT TRIỂN" section below the v1.0 nav, a "Kiểm thử" role, and its own row in the permission matrix.

---

## 1. What the v1.0 design changes

| Area                | Frames                                                             | Built today (S15)                                               | v1.0 asks for                                                                                                                                                                                                       | Work                                                                            |
| ------------------- | ------------------------------------------------------------------ | --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| Shell               | Sidebar `253:467` (11 variants)                                    | 7 items, 1 section, user menu (G-079)                           | Tổng quan, **Phân tích**, VẬN HÀNH (**Gia đình**, Hỗ trợ, Mở rộng dung lượng, Yêu cầu dữ liệu, **Dữ liệu tham chiếu**), HỆ THỐNG (Hệ thống & AI, Tính năng & phát hành, **Nhân sự & phân quyền**, Nhật ký thao tác) | New IA, permission-driven visibility, keep user menu and PHÁT TRIỂN             |
| Sign-in             | A01 · A01b · A01c · A01d                                           | Password + email link (D-043, D-044)                            | Same two paths, a wrong-password state with "Còn 3 lần thử…", a link-sent state                                                                                                                                     | Copy and state updates; no attempt counter (P-135)                              |
| Existing screens    | A02–A12                                                            | Built                                                           | **Content unchanged** (only the sidebar instance)                                                                                                                                                                   | Re-skin into the new shell; reconcile metric definitions with Phân tích (P-137) |
| Analytics           | A13 Tăng trưởng & giữ chân · A14 Tính năng                         | — (A02 has 4 KPIs, funnel `firstOpen: null`)                    | DAU / WAU / MAU, stickiness, D30, active-family chart, acquisition channel, platform split, weekly cohorts; feature usage, storage, devices & versions; CSV export                                                  | **Mobile heartbeat + nightly rollups** (P-137) and two screens                  |
| Families            | A15 Danh sách · A16 Chi tiết · A17 Chuyển chủ                      | — (families appear only inside tickets / requests)              | Directory with KPIs, status tabs, filters, paging; detail with members, counts, info, related tickets; suspend; resend invite; staff-initiated ownership transfer                                                   | Read model + 2 screens + transfer flow; privacy rules (P-136)                   |
| Reference data      | C01 Chiều dài · C02 Lượng sữa · C03 Nhập CSV · C04 Lịch tiêm chủng | — (all bundled in the app)                                      | Versioned tables with draft → approval → in use; CSV import with validation and diff                                                                                                                                | **Reference service + mobile client with bundled fallback** (P-138)             |
| Staff & permissions | A18 Thành viên · A19 Vai trò & quyền · A20 Mời · A21 Sửa vai trò   | Fixed roles in custom claims, accounts by script (P-121, P-125) | 7 roles, configurable per-function levels, in-portal invitations, time-boxed access, 2FA status                                                                                                                     | **RBAC v2** (P-134) and provisioning (P-135)                                    |
| Audit               | A12 (unchanged)                                                    | 4 categories                                                    | Promises reasons for family / staff / reference actions and logging of views                                                                                                                                        | New categories and filters (P-139)                                              |

---

## 2. Design review — where the design is not tight, and what we propose

The extraction lists 44 gaps (§9 of `18-admin-portal-v1.md`). They group into eight decisions. Each one
below gives the problem, the engineering default we will build unless the owner decides otherwise, and
the ids it creates.

### 2.1 Privacy of the families directory (gaps 1–8, 23) → P-136, Q-044

- **Problem.**
  - A15–A17 show family names ("Nhà Bông") that the product does not have. They read as the baby's nickname.
  - Baby ages are shown under "Chỉ số đếm". Age is derived from the date of birth.
  - Per-member device and region are shown.
  - A full-email reveal is promised, and so is a log of views.
  - Codes look like "FAM-20931": sequential and enumerable, and they collide with the QA case ids `FAM-001…`. Every other screen uses the hashed "F-7Q2K".
- **Default (P-136).**
  - No family name and no baby age: a family is its code; babies are "Bé thứ nhất / thứ hai" with counts only.
  - Keep the hashed `F-XXXX` code from `familyCode()`, so A03 / A04 / A08 / A12 and the directory agree.
  - Members:
    - masked email;
    - the product's relationship label and per-baby role ("Chủ hồ sơ", "Cùng nuôi", "Người chăm sóc", "Người thân" — not "Cha mẹ / Người chăm");
    - status: active, invite pending, invite expired;
    - last active, as relative time;
    - platform and app version only, never the device name (it can hold a person's name).
  - "Khu vực" becomes "Ngôn ngữ", taken from the device language. The product does not collect a region.
  - **No full-email reveal in v1.0.** Replies already go by email from the server, so staff never need the address. The lock note becomes "Email luôn được che".
  - Opening a family detail writes an audit entry (`family.view`, category "Gia đình").
  - Search is by family code, or by an exact email that the server matches by hash and never echoes back. A masked-email search matches many people.
  - No member cap ("tối đa 10" is not a rule).
- **Owner question Q-044:** is a full-email reveal ever needed (Owner / Admin only, reason + audit, 60 s)?

### 2.2 Family actions with no business rule (gaps 20–22) → P-136, Q-041, Q-046

- **Suspend ("Tạm khoá")** has no grounds, effect, notice or unlock. **Default:** not built until Q-041 is answered.
  - If kept, the proposed effect is "sharing is paused": no new invites, external links or uploads; care logging, reading, export and deletion keep working.
  - The family sees a banner in the app.
  - Reason required, audited, reversible. Suspending and unsuspending need "Gia đình · chuyển chủ, tạm khoá: Duyệt".
- **Staff-initiated ownership transfer (A17)** reuses the owner flow (P-001 / P-003, `offerOwnership` / `answerOwnership`):
  - Staff opens a request with a mandatory reason and ticket code.
  - The current owner gets an email and an in-app sheet, and must confirm within 48 h.
  - On confirmation, the standard offer goes to the chosen member. The candidate must be **Cùng nuôi of every baby** in the family; the design checks a family-level "Cha mẹ" role instead.
  - Both are notified; A16 shows "Đang chờ chủ hiện tại xác nhận · còn 31 giờ" with "Huỷ yêu cầu".
  - An owner who has lost access is **out of scope** (Q-046: a legal / manual process).
- **"Gửi lại lời mời"** — not built. Invitations are per baby and created by a Cùng nuôi (P-002). Staff creating access on a family's behalf is a risk, and the family can re-invite in two taps.

### 2.3 Staff roles and the permission matrix (gaps 13–19) → P-134

- **Problem.**
  - The design's 7 roles (Owner, Admin, Vận hành, Hỗ trợ, Chuyên gia, Phân tích, Kỹ sư) replace §5.1's Vận hành / Hỗ trợ / Kỹ thuật / trưởng nhóm, but A04 still asks for a trưởng nhóm.
  - Kiểm thử is missing.
  - Owner is weaker than Admin in places, and its "billing" scope does not exist in V1.
  - "Duyệt" is undefined.
  - Two matrices (A19, A21) disagree.
  - "Owner always ≥ 2" vs 1 drawn.
- **Default (P-134).** Roles and levels live server-side (`staffRoles`, `staffMembers`). The ID token only carries `staff: true` and a roles version. Every callable resolves the member's levels and checks the function it needs.
  - **Levels, in order:**
    - `—` (none)
    - `Xem · che` (view with masking)
    - `Xem` (view)
    - `Sửa` (do the routine action)
    - `Duyệt` (do the sensitive action, and approve someone else's request)
    - `Toàn quyền` (Duyệt + configure the function)
  - **Functions** (rows): Tổng quan & phân tích · Phân tích · xuất CSV · Gia đình · tra cứu · Gia đình · chuyển chủ, tạm khoá · Hỗ trợ · Mở rộng dung lượng · Yêu cầu dữ liệu · theo dõi, chạy lại · Dữ liệu tham chiếu · Hệ thống & AI · Tính năng & phát hành · Nhân sự & phân quyền · Nhật ký thao tác · **Phát triển · Sổ tay kiểm thử**. Staff never start exports or deletions (R-187), so the design's "Yêu cầu dữ liệu · xuất, xoá" is renamed.
  - **System roles** (locked):
    - **Owner** = Admin + manage Owner / Admin. At least 1 is enforced; a banner warns while there are fewer than 2.
    - **Admin** = everything except Owner management.
    - **Kiểm thử** = the QA handbook only (P-132).
  - **Editable roles:**
    - **Vận hành** — family lookup, transfer / suspend at Sửa, storage grants up to 20 GB at Sửa (P-120 becomes "Mở rộng dung lượng: Duyệt" for over 20 GB / custom), data jobs at Sửa.
    - **Hỗ trợ** — tickets at Sửa, families at Xem · che. It can never be granted reveal, export or delete.
    - **Kỹ sư** — renamed from Kỹ thuật: system, features, data-job re-run. No ticket access: the design gives Xem, but ticket text may hold child details (P-124).
    - **Phân tích** — aggregates and CSV export.
    - **Chuyên gia** — approves reference data.
  - **Migration:** `lead` → Admin, `ops` → Vận hành, `support` → Hỗ trợ, `eng` → Kỹ sư, `qa` → Kiểm thử. The first Owner is set by the bootstrap script.
  - Saving a role needs a reason, shows "Áp dụng ngay cho N người" as a confirmation, and is audited.
  - "Tạo vai trò" creates an editable role from a template.

### 2.4 Staff sign-in and provisioning (gaps 9–12) → P-135, Q-040, Q-043

- **Problem.**
  - A01 has no second factor, which matches D-043.
  - A18 / A20 make 2FA mandatory, but with a 3-day grace period.
  - Invitations and time-boxed access in the portal conflict with "accounts by script only" (P-125).
  - "Còn 3 lần thử…" needs a per-account counter that Firebase Auth does not have, and showing it enables account enumeration.
  - "Tên đăng nhập" vs email.
- **Default (P-135).**
  - Keep D-043 (no 2FA): the 2FA column, KPI and status are hidden until Q-040 says otherwise. TOTP would need the Identity Platform upgrade.
  - Invitations are sent from the portal ("Nhân sự & phân quyền: Sửa"):
    - company-domain allow-list in `config/staff` (domain per Q-043);
    - 7-day TTL;
    - the sign-in email link binds the invitation on first sign-in;
    - access "Không giới hạn / 30 ngày / Đến ngày…" is revoked by a scheduled job, which sets the member to "Hết hạn" and revokes refresh tokens;
    - reason and audit.
  - `create-staff.mjs` stays only as break-glass for the first Owner.
  - Wrong password shows the generic error and Firebase's own throttling ("Thử lại sau ít phút"), never a count of remaining attempts.
  - The field is "Email", per D-043.
  - Email-link copy follows what Firebase enforces; "15 phút / một lần" stays only if we enforce it in the link handler.

### 2.5 One definition per metric (gaps 24–33) → P-137, Q-042

- **Problem.** The same numbers disagree across screens:
  - 1.284 with two deltas;
  - monthly active = total families;
  - 1,82 TB vs 4,8 TB storage;
  - 11 vs 176 expanded families;
  - D30 38% vs a cohort at 47–52%.
- The data does not exist yet: no analytics SDK, the funnel's `firstOpen` is null, and there is no install attribution.
- **Default (P-137)** — first-party and aggregate-only, no analytics SDK:
  - **Hoạt động** (family, day) = at least one member opened the app that day (device heartbeat) **or** wrote a record or memory. A02, A13, A15 and A16 all use it, with a tooltip.
  - **DAU / WAU / MAU** = distinct active families in 1 / 7 / 30 days, Vietnam time. **Gắn bó** = DAU ÷ MAU.
  - **D30** = share of the families created 30 days ago (±3 days) that were active between day 28 and day 32.
  - **Cohorts** = ISO week of family creation; Tn = active at least once in week n.
  - **Acquisition channel:**
    - "Lời mời người thân": the account's first membership came from redeeming an invite. Known server-side.
    - "Website": Android only, from the Play install referrer on the landing store links.
    - "Kho ứng dụng & khác": everything else, including all of iOS, which cannot be attributed without a third-party SDK.
    - Q-042 asks whether to add an onboarding question instead.
  - **Platform of a family** = platform(s) of its members' devices active in 30 days ("iOS · Android" when both). **Versions** count active devices, not families; the panel says "thiết bị".
  - **Feature usage** counts writes, not views. "Biểu đồ tăng trưởng" becomes "Ghi số đo", from growth records. "Lịch tiêm chủng" counts dose records. "Nhắc bú" counts families with an active reminder.
  - **Storage** totals come from one source (`families.usedBytes` by type); "Đã mở rộng" = families with quota above the base 10 GB.
  - The **"Kỹ thuật"** tab is hidden until designed (G-086). **Xuất CSV** exports the aggregates on screen, needs "Phân tích · xuất CSV" and is audited.

### 2.6 Reference data (gaps 35–40) → P-138, Q-045

- **Problem.**
  - The app bundles all three datasets: WHO LMS (D-049), bottle quick picks (P-126) and the vaccine schedule (P-133).
  - C01 edits P3 / median / P97 rows, which cannot drive LMS.
  - C02 has per-row statuses inside a versioned dataset.
  - C04 has 24 doses vs the shipped 30, and different site tags.
  - Nothing defines how a new version reaches the apps or what it does to doses already planned.
  - Import errors, approval and rollback are not drawn.
- **Default (P-138):**
  - Four datasets: `growth.weight`, `growth.length`, `bottle.quickPicks`, `vaccines.schedule`.
  - **Version-level status:** `Nháp → Chờ duyệt → Đang dùng → Đã thay`. Rows changed in a draft are highlighted against the version in use; per-row statuses are dropped.
  - A draft is created by "Dữ liệu tham chiếu: Sửa". It is approved by a **different** person with "Duyệt" (Chuyên gia, or Admin / Owner). Approval publishes. Rollback = re-publish an earlier version, with a reason.
  - **Delivery:** publishing writes `publicConfig/reference_{dataset}`, readable by anyone, like flags. The app reads it through the Firestore cache, validates it, and falls back to the bundled copy. The bundled copy is regenerated from the latest published version at each release.
  - **Growth:**
    - The app moves from LMS to the published P3 / P50 / P97 table, linearly interpolated by day. Weekly 0–13 weeks, monthly to 60 months.
    - The bundled default is generated from today's LMS data, so results do not change.
    - WHO rows are **locked by default**: replaced only by CSV import of a new WHO release, with no pencil edits (Q-045).
    - Status copy stays the shipped ARB strings (D-049), shown read-only in "Cách app đánh giá".
  - **Bottle:**
    - Bands with explicit `[fromDay, toDay)`, 4 picks and a step.
    - The app keeps "last amount first" and adds the ± step.
    - Version 1 = today's P-126 table, so the design's 0–2 tuần row is a proposal for the expert to approve.
  - **Vaccines:**
    - Version 1 = the shipped 30-dose contracts schedule.
    - Site tags map to the programmes: Trạm y tế = epi, Dịch vụ = service, Bệnh viện = hospital, Tuỳ chọn = choice.
    - "Mũi kế tiếp" is derived from P-133's DOB + N months, not stored.
    - A new version changes only doses not yet given: planned dates are recomputed and reminders rescheduled. Recorded doses never change.
    - C04's "Thêm mũi" adds a row to a draft.
  - **CSV import:**
    - One template per dataset and sex / granularity, bound to the open tab.
    - UTF-8 with or without BOM; decimal point or comma.
    - Checks: required columns, units, ages strictly increasing with no duplicates or gaps, P3 < P50 < P97, values within ±30% of the version in use.
    - Row-level errors are listed. A valid file becomes a draft, and the diff is previewed before saving.

### 2.7 Reasons, two-person rule and audit (gaps 41–42) → P-139

- Every new mutation takes a reason of 3–500 characters and writes `staffAudit` (R-183):
  - invite, revoke, change role, save role;
  - transfer, suspend;
  - draft, approve, publish, rollback;
  - CSV export.
- The **two-person rule** ("Xoá cần người thứ hai duyệt") applies where staff touch deletion: re-running a failed **deletion** step (A07) needs a second person with "Yêu cầu dữ liệu: Duyệt" to approve it. Reference publishing is two-person by construction.
- A12 gains the categories "Gia đình", "Nhân sự", "Dữ liệu tham chiếu" and "Phân tích", plus staff sign-ins. The QA handbook stays outside the audit (P-132).

### 2.8 States the design leaves out (gaps 43–44) → G-085 … G-091

- Engineering supplies these with existing components, to go to design review (G):
  - empty / loading / error states and pagination for every new table;
  - member row actions, the "Lời mời" tab and the "Tạo vai trò" form;
  - the pending-transfer and suspended states;
  - the reference approval queue, diff preview, import errors and version history;
  - the two-person approval in A07;
  - the mobile banner and confirmation sheets.
- The sidebar shows only what the signed-in member may open. It keeps the user menu (G-079) and the Dev / Production pill.

---

## 3. Architecture

### 3.1 Contracts (`packages/contracts`)

- `staff-rbac.ts`: functions, levels, system roles, role / member / invitation schemas, `levelAtLeast()`. This replaces the fixed `staffMatrix`; `staffCan()` stays as a thin wrapper during migration.
- `analytics.ts`: `StatsDaily`, `CohortWeek` and the shapes of the A13 / A14 answers.
- `reference.ts`: dataset ids, row schemas, version status, CSV templates and validators (shared by the portal preview and the server).
- `families-staff.ts`: directory row, detail and transfer request shapes.

### 3.2 Firestore (all callable-only, deny-by-default rules)

| Collection                                    | Purpose                                                                                                                                                                                                        |
| --------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `staffMembers/{uid}`                          | name, email, roleIds, status (active · paused · expired), accessUntil, lastSeenAt, invitedBy                                                                                                                   |
| `staffRoles/{roleId}`                         | name, system flag, levels per function, updatedBy / at                                                                                                                                                         |
| `staffInvites/{id}`                           | email hash, roleIds, accessUntil, expiresAt (7 d), state                                                                                                                                                       |
| `familyDirectory/{familyId}`                  | read model: code, owner masked email, member / carer / pending-invite counts, baby count, used / quota, platforms, lastActiveAt, status, createdAt. Kept by triggers on families, members, invites and devices |
| `familyTransfers/{id}`                        | staff-opened ownership requests: from, to, reason, ticket, expiresAt (48 h), state                                                                                                                             |
| `familyActivity/{familyId}`                   | the last 400 activity days (Vietnam dates), createdWeek, platforms                                                                                                                                             |
| `statsDaily/{date}` · `statsWeekly/{isoWeek}` | DAU / WAU / MAU, new families by channel and platform, feature counts, storage, versions; cohort rows                                                                                                          |
| `referenceData/{dataset}/versions/{id}`       | rows, status, author, approver, notes; `publicConfig/reference_{dataset}` holds the version in use                                                                                                             |

### 3.3 Functions

- `staffMe`: resolved permissions for the shell (visibility).
- Staff: `staffMembers` · `staffInvite` · `staffUpdateMember` · `staffRoles` · `staffSaveRole`.
- Families: `staffFamilies` (paged, filters, code or hashed-email search) · `staffFamily` (writes `family.view`) · `staffOpenTransfer` · `staffCancelTransfer` · `staffSuspendFamily` (only if Q-041 is yes).
- Analytics: `staffAnalytics` (growth | features, range, platform) · `staffExportAnalytics`.
- Reference data: `staffReference` · `staffReferenceDraft` · `staffReferenceImport` (validate + diff) · `staffReferenceSubmit` · `staffReferenceApprove` · `staffReferenceRollback`.
- Scheduled jobs:
  - `rollupDaily` (00:30 Vietnam): familyActivity, statsDaily, versions, storage;
  - `rollupWeekly` (Monday): cohorts;
  - `expireStaffAccess` (hourly);
  - `expireFamilyTransfers` (hourly);
  - a one-off `backfillActivity`, which approximates history from `createdAt` of records and memories.
- Triggers keep `familyDirectory` current. Every write path checks levels through one `requireLevel(staff, fn, level)`.

### 3.4 Portal (`apps/portal`)

- **Router:** path segments (`/families/F-7Q2K`, `/analytics/features`, `/reference/vaccines`, `/staff/roles/support`) instead of today's exact-path map.
- **Shell:** v1.0 nav with sections and permission-driven visibility from `staffMe`, the user menu, and PHÁT TRIỂN › Sổ tay kiểm thử.
- **Shared UI:**
  - paged `DataTable` (sticky header, empty / loading / error);
  - `KpiDelta` (unit, delta in % or points, tooltip);
  - cohort `Heatmap`;
  - existing `LineChart` / `HBars`;
  - `ReasonDialog` (exists);
  - `LevelSegment` for the matrix.
- **Screens:** Analytics (A13, A14), Families (A15, A16, A17 dialog), Reference (C01–C04, import modal, review queue, history), Staff (A18–A21, invite modal); new A12 filters; A02 on the shared metric definitions; A01 copy and states.

---

## 4. Mobile changes (data for statistics, reference data)

Coordinate with the vaccination work on this branch (`features/vaccines`, P-133). Vaccine schedule delivery waits until that work has landed.

1. **Activity heartbeat.**
   - On app foreground, at most once per local day per device, `push_registration.dart` sets `lastActiveAt`, `osVersion` and a coarse `model` ("iPhone", "iPad", "Android phone", "Android tablet") on `users/{uid}/devices/{deviceId}`.
   - Rules `validDevice` allow the new fields.
   - No event stream and no SDK: the app adds no new data about the child.
2. **Reference data client.**
   - `core/reference/reference_repository.dart` reads `publicConfig/reference_*` (Firestore offline cache), validates it, and falls back to the bundled copy (`tool/` generates Dart from the published version).
   - `who_growth.dart`, `growth_chart.dart` and `growth_standards_screen.dart` evaluate against the table, with a "WHO · v2026.09" label in 20i.
   - `bottle_suggestions.dart` uses bands and the ± step.
   - Vaccines read the schedule dataset; planned dates are recomputed for doses not yet given.
3. **Acquisition (Android).**
   - On first launch, the Play install referrer is read once and sent to a callable `recordAcquisition` (channel: website · store · unknown).
   - The invite channel is set server-side on redemption. iOS sends nothing.
4. **Staff-initiated ownership confirmation.** The current owner gets an in-app sheet (and an email deep link) "Child Life Hỗ trợ đề nghị chuyển chủ hồ sơ cho t***@… · Đồng ý / Không đồng ý". This reuses the 13n ownership UI and P-003 rules.
5. **Suspended family** (only if Q-041): a banner on Hôm nay and Tôi, and invites, links and uploads disabled with the reason "Gia đình đang tạm khoá chia sẻ · liên hệ Hỗ trợ".
6. Strings vi / en (D-012), Light and Night care, widget tests and goldens for each new state.

---

## 5. Delivery phases

| Phase | Content                                                                                                                                      | Depends on                       | Size | Done when                                                                                                                                                                                     |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------- | ---- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0     | Owner answers Q-040 … Q-046 and confirms P-134 … P-139                                                                                       | —                                | —    | Decisions recorded as D-xxx                                                                                                                                                                   |
| 1     | RBAC v2 + shell IA + A18–A21 + invitations + migration script; QA handbook kept under PHÁT TRIỂN                                             | 0 (Q-040, Q-043)                 | L    | Every A02–A12 action follows the new matrix (incl. P-120 as "Duyệt"); the five old roles migrate with no access change; Kiểm thử still sees only the handbook; integration + rules tests      |
| 2     | Families: `familyDirectory` read model, A15 / A16, `family.view` audit, A17 transfer (server + mobile sheet)                                 | 1                                | M    | Directory pages over 3k seeded families in < 1 s; no name, age or full email anywhere in responses (asserted by tests); transfer completes, expires and cancels end to end on iOS and Android |
| 3     | Analytics: mobile heartbeat (app release), rollups, backfill, A13 / A14, A02 on shared definitions, CSV export                               | 1; app release for the heartbeat | L    | Seeded dataset reconciles across A02 / A13 / A14 / A15 (one test fixture); definitions shown as tooltips; export audited                                                                      |
| 4     | Reference data: service, C01–C04, import, approval, rollback, mobile client (growth, bottle; vaccines after P-133 lands)                     | 1; vaccination branch merged     | L    | App results unchanged with the bundled v1; a published v2 reaches a device offline-first and rolls back; two-person approval enforced                                                         |
| 5     | Hardening: undrawn states (G-085 … G-091), A12 categories, QA handbook cases ADM-016+, e2e on emulators, dev deploy, docs and checklist rows | 1–4                              | M    | Coverage rows filled with code and test paths; QA smoke run recorded in the handbook                                                                                                          |

**Order.** Phase 1 first, because every new screen checks permissions. Phases 2 and 4 can run in parallel after it. Phase 3 starts its mobile part early, because data accrues only from the app release that ships the heartbeat; the backfill gives an approximate history before that.

---

## 6. Risks

- **Concurrent mobile work.** The vaccination branch touches `who_growth_data.g.dart`, `growth_standards_screen.dart` and `features/vaccines`. Merge it before Phase 4 mobile work.
- **Rollup cost.** Nightly scans are bounded by active devices, not by families. Collection-group `count()` is used for feature counts; budgets are checked in Phase 3 on a 100k-record seed.
- **Attribution.** iOS cannot separate store from website without a third-party SDK, which the privacy stance rules out (Q-042).
- **2FA.** Enforcing TOTP needs the Identity Platform upgrade (billing; owner approval needed, Q-040).
- **Reference data safety.** A bad table changes advice shown to parents. Mitigated by two-person approval, range checks, rollback and bundled fallback.

## 7. Docs touched by this plan

- `docs/discovery/figma-extract/18-admin-portal-v1.md` (new evidence) and its README row.
- `docs/product/business-map.md`: P-134 … P-139, Q-040 … Q-046, G-085 … G-091.
- `docs/product/figma-coverage-checklist.md` §G: rows for A01b–A01d, A13–A21, C01–C04 (☐).
- `docs/development/implementation-plan.md`: slice **S15b — Admin portal v1.0** with these phases.
