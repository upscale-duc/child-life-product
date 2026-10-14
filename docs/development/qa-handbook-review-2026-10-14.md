# QA handbook review — 2026-10-14

The owner asked (2026-10-14) for a review of the whole business since the handbook was written
(2026-10-11, P-132) and an update of its cases, **including notifications**. Seven reviewers covered
one area each (business map D-051…D-070, P-133…P-150, plans, code and ARB labels). Their drafts were
merged into `firebase/functions/src/qa-catalog.ts`.

## Result

- **Size:** 154 → **290 cases**, 17 → **24 modules**, 47 of them smoke. Of the existing cases, 77 were
  rewritten under the same id, so results stay comparable.
- **New modules:**

  | Module | Prefix | Cases | Covers |
  | --- | --- | --- | --- |
  | Sổ tiêm chủng | VAX | 9 | P-133 |
  | Chi tiêu | SPEND | 13 | P-140, D-055…D-057, D-060 |
  | Sơ cứu | AID | 11 | D-058 |
  | Tự lưu kỷ niệm | AUTO | 12 | D-066, D-070 |
  | Thiệp cột mốc & video kỷ niệm | KEEP | 9 | D-068 |
  | Thông báo & email | NOTI | 14 | every push, on-device notification and email |
  | Trợ giúp, góp ý & cập nhật app | HELP | 10 | D-065, D-061 in the app |

- **Rewritten modules:**
  - Sign-in (D-064, D-067), with "Dùng email" gone from the sign-in sheet.
  - Family and invites (D-059), now under Tiện ích → "Thành viên & chia sẻ" since D-069 removed the tab.
  - Today, Chăm sóc, Tiện ích and stats.
  - Reminders (D-051).
  - Widgets.
  - Memories, stories and offline.
  - Tôi and data export, which now goes only through the email link.
  - Website v3–v5.
  - The portal (ADM-001…036, every v1.0 screen):
    - the idle sign-out case now checks the kept session (D-062);
    - roles are renamed to Admin / Kỹ sư;
    - deletion re-runs need a second person (P-139).
- **Not added: Apple Watch** (P-142). The watch app is not in the dev build yet and has not been tried
  on a device.
- **Edited copies are not updated.** A built-in case already edited on the portal keeps its edited copy,
  so these updates do not reach it on that environment.

## Fixed in the portal during the review

- **Role editor and matrix:** the "Nội dung · Sơ cứu" row was missing, so the `content` function could
  not be seen or set. A test now checks that every staff function has a row.
- **Action log:** Sơ cứu, Mẫu kỷ niệm and Cập nhật ứng dụng actions showed raw ids. They now have vi/en
  labels.
- **Old role names:** copy that still said "trưởng nhóm" / "Kỹ thuật" now says Admin / Owner / Kỹ sư,
  and the QA start page describes invited staff.
- **Reference CSV import:** row errors are now words, not parser codes (D-012).
- **Handbook text:** the portal module description no longer promises a 30-minute sign-out.

## Likely defects found (not fixed; app / server owners)

**Reminders, notifications and permissions**

- The app never asks Người thân or Người chăm sóc for notification permission. On iOS and Android 13+
  they silently get no pushes, rule and vaccine reminders included.
- A family-notice tap always opens Kỷ niệm and never switches to that baby (messages and storage too).
- "Vào ngay" identities never register for pushes.
- The sleep reminder can ring while the baby is asleep (the server ignores a running timer; D-051 says
  it should not).
- Caregivers see "Nhắc nhở" in "Tạo nhanh", but Rules refuse their reminder: a success toast, then a
  failure.

**Vaccines**

- Caregivers see "Cần ngày sinh…" until a Cùng nuôi opens the book, and no vaccine reminders are sent
  for that baby.
- Unticking everyone in "Ai nhận nhắc lịch tiêm?" sends reminders to everyone.

**Sơ cứu**

- Without "Thông tin bé" it does not know the baby's age: CPR opens on "Dưới 1 tuổi" and the index is
  not sorted by age.
- The "Đang gọi 115" bar never resets.

**Invites**

- An invite link opened offline lands on "Không tìm thấy lời mời" instead of the D-059 fallback.
- Used, revoked or declined links give the same message, and each attempt counts toward the code
  lockout.
- The one-tap join toast points to "Gia đình" for a rename that lives in Tôi → "Hồ sơ của bạn".

**Spending import**

- The undo label probably reads "còn 6 ngày" right after an import.
- The email's "Xem kết quả" opens the website home.
- An offline file import can spin for minutes.

**Kỷ niệm 2.0 and stories**

- `retryMemoryStory` skips the active-job, daily-cap, quota and flag checks.
- "Sửa thiệp" saves a second card instead of replacing the first.
- A failed story save shows the photo-library copy.
- The story push opens Kỷ niệm, not the story.

**Emails**

- The ownership offer uses the sender's language.
- The staff invite and staff ownership-request emails are always Vietnamese.
- The storage-grant email goes to the requester, while R-186 says the owner.
- Reply time is 2 working days in Góp ý but 1 in the support email.

**Reference data**

- Only the bottle table reaches the app.
- Growth and vaccine versions published on the portal are not read (the app and the reminder job use
  the bundled schedule).

## Owner decisions needed

- **Tôi screen:** rows drawn in Figma but not built: "Các bé", "Gia đình", "Liên kết chia sẻ", "quản
  lý hồ sơ".
- **Kỷ niệm 2.0:** should cards and videos appear in Nhật ký? The plan says no; the build shows them.
  Undrawn screens are not built: MM13 "Lưu nháp", MM16, the MM09 edit pencil.
- **Business map:** the "Tabs" row of the permission matrix and the P-127 / P-128 texts are out of date
  (D-069; the returning screen now has "Tôi có mã mời"). Mailed invites, accept / decline, "Nhập mã mời"
  from a profile and revoke-from-row have no D-id.
- **Notification copy:** the footnote "Thông báo không bao giờ kèm ảnh hay tên bé." is wrong for local
  notifications that show the nickname.

## Dev prerequisites for the new cases

- **Accounts and push:** an APNs key, `RESEND_API_KEY` on dev, and QA access to support@childlife.app.
  Google sign-in is not configured on dev, and Apple is not configured on Android.
- **Tự lưu:** add the QA families under "Tính năng & phát hành › Ai được dùng" (AUTO-008). Release
  builds follow the flag.
- **Shared dev settings:** app-update cases (HELP-008…010, ADM-033) block or prompt every dev phone, so
  they need a test window and a restore. Flags, Sơ cứu content and the bottle table are shared the
  same way; each case says to warn the team and restore.
- **Not reproducible yet:** there is no tool to force a failed video render (MM14) or to prepare a failed
  deletion job (ADM-010).

The reviewers' full drafts, including every open question, were kept in the session scratchpad. The
items above are the ones that matter for the product.
