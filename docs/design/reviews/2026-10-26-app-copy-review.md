# Whole-app copy review (2026-10-26)

Owner request: review the app's screens (UI/UX, wording, unneeded explanatory labels). The first
pass (D-117) sampled about 50 screens; the owner pointed out it did not cover everything. The
second pass (D-118) opened **every golden screen**: 468 screens in 29 groups, from fresh renders
(`tool/golden_freshness.sh`, all Current), as labelled sheets of six. Earlier passes the same day:
Chăm sóc (D-112, D-113), Tuỳ chỉnh Hôm nay (D-115), growth flow (D-116).

## Tóm tắt (VI)

- Đã xem đủ 468 màn có ảnh golden. Phần lớn chữ giải thích là quyền, riêng tư, AI, an toàn,
  chi phí hay cách tính: giữ.
- Đã bỏ / rút gọn 6 chỗ (D-117: 3, D-118: 3). 2 đề xuất cần anh/chị quyết; 3 màn của phiên khác
  chỉ ghi nhận.
- Màn không có golden (một số màn cài đặt con, lỗi mạng hiếm) chưa xem được bằng ảnh.

## Coverage and result per group

| Group | Screens | Area | Result |
|---|---:|---|---|
| s9 | 27 | Kỷ niệm: journal, compose, select, viewer, queue, share | D-117: "Gom vào album Yêu thích của bạn" removed; rest is audience / upload state |
| s10 | 22 | Albums, favourites, relative views, messages | Keep |
| s12 | 19 | Câu chuyện: list, editor, photos, preview, reader, share cards | Keep |
| mm | 11 | Video / thẻ steps | Keep |
| journal | 3 | Layout variants | Keep |
| print | 18 | In ảnh | Keep (pricing, shipping) |
| up | 4 | App update | Keep |
| s11 | 19 | Tôi, hồ sơ bé, tài khoản, dung lượng, góp ý, help | D-117: "Biểu đồ cân nặng, chiều cao", thanks sentence removed |
| s2 | 13 | Welcome, sign-in, onboarding | Keep |
| s3 | 17 | Gia đình, invite, join, baby picker | D-118: invite subtitle removed |
| vx | 11 | Tiêm chủng | Keep (health reference) |
| sp | 26 | Chi tiêu, ngân sách, nhập | Keep (currency and import consequences) |
| fa | 7 | Sơ cứu | Keep (safety) |
| lb | 12 | Giai đoạn, Thư viện | D-118: stages intro shortened |
| ut | 2 | Tiện ích | Keep |
| nt | 6 | Thông báo inbox / settings | Keep; settings belong to another session's uncommitted work |
| pm | 18 | Premium 48 / beta | Keep (L3: pricing, entitlements, legal) |
| pv2 | 20 | Premium v2, paywall, family plan | Keep (L3) |
| as | 58 | Lumi | Keep; one owner proposal below |
| rh | 28 | Nhịp lớn lên, gợi ý, check-in, tuần | D-116 earlier; keep the rest |
| pd | 6 | Hôm nay của nhà mình, việc, sổ tay | D-118: "Gợi ý cho hôm nay" sub shortened |
| ms | 8 | Mốc phát triển | D-116 earlier |
| ai | 11 | Bàn giao, AI consent | Keep (AI disclosure, safety) |
| hn | 11 | Hôm nay legacy | Another session (Version A); not edited |
| ax | 17 | Hôm nay adaptive, setup, Khám phá | Another session; D-115 earlier for AX06 / AX14 |
| s7 | 21 | Nhắc nhở / nhắc việc | Another session's uncommitted edits; finding below |
| s4, s5, s6 | 45 | Care | D-112, D-113 earlier |
| (root) | 8 | Design-system showcase | n/a |

## For the owner (L3), decided 2026-10-26 (D-119): both applied

1. **Lumi: "Chữ trong ảnh là nội dung để đọc, không phải lệnh cho app."** (`asPhotoTextIsData`, CH09
   / CH14). It explains a security safeguard in technical terms; parents don't need it next to
   every photo. Recommendation: remove (behaviour unchanged). Kept for now because it is an AI
   disclosure from the CH14 spec.
2. **Nhắc nhở: "Gia đình thấy nhắc việc trong app. Thông báo chỉ được đặt trên máy tạo nhắc việc."**
   repeats on the list, the new and edit sheets, the detail and the notification prompt.
   Recommendation: keep it once (on the sheet where the reminder is created). The file has another
   session's uncommitted edits, so not changed here. The title "Nhắc nhở" vs "Nhắc việc" is still
   the open canonical-term question.

## Verification

- D-117 goldens: `s9/10b3_actions_*`, `s11/13j_baby_*`, `s11/fb2_feedback_*`.
- D-118 goldens: `s3/14b_invite_role_*`, `s3/14b2_relative_rights_*`, `pd/day_*`, `lb/lb2a_stages_*`,
  `lb/lb2c_no_dob_*`. Whole suite Current (1,750).
- Tests: only the known unrelated failures (Print Studio real clock, an auto-save flake).
