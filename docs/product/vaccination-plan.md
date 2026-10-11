# Sổ tiêm chủng — review and plan (2026-10-11)

Source: Figma `345:35701` cluster "Label · Tiêm chủng" (VX 0 – VX 9a), extracted in
`docs/discovery/figma-extract/17-vaccination.md`. Owner request: "review và lên kế hoạch và triển khai
thêm tính năng sổ tiêm chủng trong mục chăm sóc".

## Review (what the design asks for)
- A vaccination book per baby, opened from a new **"Tiêm chủng"** tile (2nd tile in Chăm sóc, also for
  caregivers), subtitle "Mũi tiếp theo 17/11".
- A fixed reference schedule: 14 rows / 30 doses from birth to 24 months, planned at DOB + N months.
- Two views (Theo vắc xin matrix · Theo tháng tuổi timeline), a "next shot" card, the counter
  "Đã tiêm N / 30 mũi", statuses Đã tiêm · Sắp tới · Quá hạn · Chưa tới.
- First-time setup (tick the doses already given, dates optional), a milestone page with the 6in1 /
  5in1 choice, a full record form and a quick tick, a dose detail with edit / delete, a vaccine info
  page, overdue handling (đã tiêm rồi · dời lịch · không tiêm mũi này), and a lock-screen reminder the
  evening before with actions.
- The design leaves 13 questions open (programme / route for 11 rows, what "30" counts, polio on the
  5in1 path, next-dose rule, reminder lead times, baby name in the push, permissions, photos, …).

## Decisions taken as engineering defaults (P-133, owner to confirm)
1. **Schedule** = the 30 doses drawn, as versioned reference data in `packages/contracts`
   (`vaccine-schedule.ts`), generated into Dart. Programme and route for the undrawn rows are filled from
   the Vietnamese EPI / common service practice and **flagged for medical review**; every screen keeps the
   design's banner "Lịch tham khảo, có thể thay đổi theo chỉ định của bác sĩ" (R-012: no medical inference,
   no warnings about minimum ages or intervals).
2. **5in1 path** adds a "Bại liệt" row (2 · 3 · 4 tháng, uống) only when the family picks 5in1; the
   counter's total follows the plan ("/ 30" on the 6in1 path, "/ 33" on the 5in1 path). The choice is made
   for the series and can be changed until its first dose is recorded.
3. **Declined** ("Không tiêm mũi này") is its own state: grey dot with a cross, left out of the total,
   undoable from the dose page.
4. **Dates:** each dose is planned at DOB + its month of age (calendar months; a 31st falls back to the
   month's last day) in the baby's zone. A given date cannot be in the future; "Dời lịch" sets a new
   planned date for that dose. Later doses stay on their age milestones (catch-up is the doctor's call).
   Overdue = the day after the planned date.
5. **Who:** Cùng nuôi record, edit and delete; Người chăm sóc record and edit what they recorded (as
   D-022); relatives with "Chăm sóc hằng ngày" only view. The plan (6in1/5in1, reminders, recipients)
   is Cùng nuôi only.
6. **Reminders:** a server push like rule reminders (D-051): to the chosen recipients (default all Cùng
   nuôi + Người chăm sóc), **3 days before and the evening before at 19:00** in the baby's zone; a
   rescheduled dose gets the evening-before one. Actions: Xem lịch tiêm · Nhắc lại sáng mai (07:00) ·
   Dời lịch. The copy leaves out the baby's name (R-120): "Ngày mai có lịch tiêm của bé".
7. **Photos** of the book / slip: optional, one per dose (VX 3 / VX 6) plus up to 10 of the whole
   book (VX 0, also on VX 1 for Cùng nuôi), re-encoded to a ≤1600 px JPEG without EXIF, at
   `babies/{id}/vaccines/{id}.jpg`. Storage Rules: whoever reads care reads them, Cùng nuôi and Người
   chăm sóc add them (≤4 MB), Cùng nuôi delete them. Never in Kỷ niệm, story links or exports. Not yet
   counted in family storage (the usage reconcile only counts Kỷ niệm media).

## Build steps (each one committed and pushed)
1. **Data:** schedule catalogue (TS → Dart generator), dose + plan shapes in contracts, Firestore Rules
   with tests.
2. **App:** tile, routes, book (matrix + timeline + view sheet), setup, milestone, record (full + quick),
   dose detail, vaccine info, overdue sheet; vi / en strings; widget tests and goldens (Light + Night).
3. **Reminders:** scheduler Function + push + iOS lock-screen actions; recipients row; deploy to dev.
4. **Photos:** upload, Storage Rules, viewer. (Done; the Storage Rules emulator tests wait on the
   wedged local Storage emulator.)
5. Device run on the owner's iPhone.
