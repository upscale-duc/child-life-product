# Figma extraction notes (evidence)

Read-only transcription of the final Child Life Figma file `sJLG1fAXKDnDr9YI6Yx8ex`, made on 2026-10-10 through the Figma MCP (`get_design_context`, `get_metadata`, `get_variable_defs`, `get_motion_context`, `get_screenshot`). No Figma node was modified.

These files are the evidence behind the R-/Q-/G- items in [`../../product/business-map.md`](../../product/business-map.md). Rendered text from `get_design_context` is authoritative; several layer names in Figma are stale and are flagged where they differ.

| File | Figma scope |
|---|---|
| `01-onboarding-auth-profile-family.md` | Sections 1, 2, 3 (+13a Night care schedule), 4, 4b |
| `02-today-care-history-widgets.md` | Sections 5 and 6, Components widgets `73:399`; stats computation rules |
| `03-roles-reminders-offline-caregiver.md` | Sections 7, 8, 9, 12; permission matrix evidence |
| `04-memories-albums-upload.md` | Section 10. The first part was written while the MCP was rate-limited; its "NOT READ" list is superseded by batches A, B and C appended in the same file (all 31 frames read). |
| `05-relative-me-storage.md` | Sections 11 and 13. Metadata-only notes in the first part are superseded by the gap-fill pass appended at the end (all 12 frames re-read in full). |
| `06-story-links-website.md` | Section 14 and the Website page (landing desktop + mobile). |
| `07-foundations-components-motion.md` | Foundations, Components, Cover, Logo; motion findings. The logo sheet screenshot referenced as `figma-notes/img/…` is `img/logo_sheet_35-240.png` here. |
| `08-admin-portal.md` | Admin portal `253:18` as of 2026-10-10 (A01–A12, sidebar). |
| `18-admin-portal-v1.md` | Admin portal `253:18` section **v1.0** (2026-10-11): A01–A01d, A13–A21, C01–C04, sidebar v1.0, delta for A02–A12, 44 logic gaps; v1.1 frames listed only. |
| `19-spending.md` | Page **v1.1**, cluster "Chi tiêu" 8a–8o (2026-10-12): Care tile, month view, add expense, stats (6 months / since birth), history, detail, budget, recurring, first use, vaccination cost prompt, family spending permissions, categories (list / add-edit / delete). Screenshots in `img/v11/`. |
| `20-v11-content-features.md` | Page **v1.1** `304:18` (2026-10-12), every cluster except spending: A Today/Me changes (new tab bar, "Dành cho bé hôm nay", Customise rows), 2 Thẻ theo tuổi, 3 Mốc phát triển, 4 Thư viện chăm bé, 5 Ăn dặm, 6 Wonder Week, 7 Sơ cứu (7a–7i + TH01–TH24), 9 Dinh dưỡng theo giai đoạn, the `photo_demo` first-aid image sheet; consolidated data model, admin-portal gaps and open questions. Screenshots in `img/v11/`. |
| `21-care-utilities-tabs.md` | Page **v1.0 - improvement** `345:35701`, row y 9079 (2026-10-12): CS2a Chăm sóc `450:6424`, CS2b Tiện ích `450:6597`, CS2c Tiện ích · người chăm `450:6873`, and the "Tab chính · đề xuất" row R1–R5 (`456:6246`…`456:7022`). New dock Hôm nay · Kỷ niệm · Chăm sóc · Tiện ích (Gia đình removed; labels under every tab), Tiện ích sections Cho bé / Gia đình, Gia đình row in Tôi, diff vs current app, open questions. Screenshots in `img/v11/`. |
| `22-landing-v4-home.md` | Landing **v4 home** `459:3538` (2026-10-12, desktop only): new sections Sức khoẻ (vaccines, WHO growth), Tiện ích cho ba mẹ (Sơ cứu, Chi tiêu, Gia đình & chia sẻ), Theo cách của bạn (Tuỳ chỉnh Hôm nay); 5-link nav; 8 FAQ; mobile proposal; copy claims vs the map (§12) |
| `24-app-update.md` | Page **v1.0 - improvement** `345:35701`, row "UP · Cập nhật ứng dụng" (2026-10-12): UP1 bắt buộc cập nhật, UP2 có bản mới (sheet), UP3/UP4 có gì mới, UP5 banner on Hôm nay, UP6 Tôi · phiên bản; copy, sizes, tokens and what the design leaves open (D-061, P-143). |
| `25-landing-v5-home.md` | Landing **v5 home** `475:3726` (2026-10-12): new dark section "Trên cổ tay" (Apple Watch: copy, 4 bullets, three watch mocks W01 / W03 / W07), 6-link nav (+ "Apple Watch"), 9th FAQ; every other section pixel-identical to v4 (`22`); mobile proposal, watch-app parity and claim checks. |
| `26-feedback-rating.md` | Page **v1.0 - improvement** `345:35701`, row "FB · Góp ý & đánh giá" `477:6397` (2026-10-13): FB1 Tôi · Góp ý `477:6398`, FB2 Góp ý `477:6493`, FB3 Đã gửi `477:6549`, FB4 chụp màn hình · báo lỗi nhanh `477:6564`, FB5 hỏi đánh giá `477:6608`; copy, sizes, tokens and what the design leaves open (D-065, P-145). |

Coverage: all 154 Light screens were read in full; Night care twins were checked structurally and by spot-check screenshots (copy and behaviour identical, colours differ). The MCP page listing shows only Cover and Logo; Foundations `17:467`, Components `7:4`, Screens `26:2` and Website `210:759` were reached by node id (Q-032 asks the owner to confirm there are no other pages).

The Figma MCP on this seat has a per-minute call limit; re-reads should be batched with ~90 s back-off.
