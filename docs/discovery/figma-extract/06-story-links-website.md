# F — Story (Câu chuyện), share links & Website — spec extraction
Figma file sJLG1fAXKDnDr9YI6Yx8ex (read-only). Extracted 2026-10-10.
Sources: get_design_context (Light frames, visible text verbatim) for 204:84, 205:18, 205:100, 206:18, 206:136, 206:212, 206:264, 208:56 (sheet of 208:18), 208:104, 208:36164, 208:36210, 208:36267, 207:122 (StoryCard variant), Website 219:1413, 231:162, 220:1801, 220:1918, 232:627, 221:2845, 221:3347, 221:3443, 221:3455, 233:818 (mobile hero); get_metadata 207:225; get_motion_context 219:1391 & 233:804 (both empty).
NOT fetched via design_context (Figma MCP per-minute rate limit hit repeatedly; read from local metadata layer names instead): 208:312 (14j share sheet), 208:37714 (14n template sheet — covered via 208:104 + 207:122), Website Nav 219:1392, Footer 221:3488, mobile sections other than hero. Night variants spot-checked via metadata only (text layer structure identical to Light for 14k/14l/14m).
CAUTION: many text-layer NAMES in this file are stale versus the visible text (e.g. Website eyebrow, CTA, FAQ answers, 14m subtitles). Only visible text (from design_context) is quoted as verbatim below; metadata-only items are marked "(metadata)".
No annotation/sticky-note nodes exist in section 14 or the Website page; section 14 has only frame-title labels (e.g. 208:36209 "14k Liên kết xem riêng · có hạn, không tải, mật mã").

# PART 1 — Screens §14 · Câu chuyện: gợi ý, tự viết, sửa, lưu & chia sẻ (section label 204:83)
Frame labels (verbatim): 14a "Danh sách · 1 ảnh, nhiều ảnh, video, thư, nháp" · 14b "Sửa nháp AI · chạm từng khối để sửa" · 14c "Sửa đoạn · bàn phím + nút AI" · 14d "Chạm ảnh · đổi, thêm, chú thích, bỏ" · 14e "Sắp xếp khối · kéo thả" · 14f "Xem trước · chọn ai đọc · Lưu" · 14g "Đã lưu · đọc · Sửa / Chia sẻ" · 14h "Chia sẻ · chỉ sau khi đã lưu" · 14i "Thiệp ảnh · 5 mẫu: 1 ảnh, 3 ảnh, 4 ảnh, thư, tối" · 14j "Thiệp · bảng chia sẻ iOS" · 14k "Liên kết xem riêng · có hạn, không tải, mật mã" · 14l "Người nhận xem trên web" · 14m "Quản lý liên kết · thu hồi (từ Tôi)" · 14n "Bộ mẫu thiệp (component StoryCard) · 1 ảnh · 3 ảnh · 4 ảnh · thư · đêm".
Related outside §14: 11i "Đọc câu chuyện · Thương & Nhắn ba mẹ" (208:36344, family reader view: meta "Mẹ chia sẻ với gia đình · hôm nay", reply bar "Thương · 4" + "Nhắn ba mẹ…" — metadata); onboarding 26:211 "Khoảnh khắc thành chuyện" / "Một ảnh thành thẻ kỷ niệm ngay. Cuối tuần có nhật ký của bé." and 26:277 "Đúng người, đúng quyền" / "Bà được xem ảnh, cô trông trẻ được ghi cữ bú. Bạn quyết định ai thấy gì." (metadata names).

## 14a 204:84 Câu chuyện · danh sách (Light)
- Header: BabySwitcher "Teddy · 3 tuần"; buttons View (Icon/sliders, 204:89) + Add (+, mint, 204:91). Title "Câu chuyện".
- AI suggestion card 204:96: tag (spark) "Gợi ý tuần này"; title "Tuần Teddy biết cười"; sub "Từ 9 ảnh · bạn sửa trước khi lưu"; CTA pill "Xem bản nháp". Stacked 3 photo thumbs.
- Filter chips: "Tất cả" (active) · "Bản nháp · 2" · "Đã chia sẻ".
- Card variants:
  - "Story · 1 ảnh" 204:137: full photo w/ gradient, overlay title "Đêm đầu ngủ một mạch" + italic subtitle "4 tiếng không thức giấc"; meta "Mẹ kể · 3 ngày trước" + family icon (audience) + heart count "4".
  - "Story · nhiều ảnh" 204:161: collage 1 big + 2 small, last has "+6"; title "Tuần Teddy biết cười"; italic excerpt "“Sáng thứ Hai, khi mẹ vừa hát xong câu ru quen thuộc, Teddy bỗng nhoẻn miệng cười…”"; milestone tag (star, sunshine-soft) "Lần đầu cười"; meta "Mẹ kể · hôm nay" family icon, heart 6.
  - "Story · video" 204:207: video thumb w/ play button + duration "1:12"; title "Lần đầu nắm tay ba"; meta "Ba kể · tuần trước" family icon, heart 3.
  - "Story · thư" 204:234 (letter, cream bg #fbf6ed): badges "Bản nháp" + (lock) "Chỉ ba mẹ"; title "Thư gửi Teddy tuổi 18"; italic body "Con yêu, khi con đọc những dòng này, có lẽ con đã cao hơn mẹ rồi. Mẹ muốn kể con nghe về đêm đầu tiên…"; meta "Mẹ viết · sửa lần cuối hôm qua". (No heart count on draft.)
  - "Story · nháp AI" 204:247 (dashed border, compact row): thumb; title "Lần đầu gặp ông bà"; tag (spark) "Nháp từ gợi ý · chưa lưu"; chevron.
- FAB "Viết" (edit icon) 204:301 = write own story. Floating memory tabs: "Nhật ký" · "Ảnh" · "Album" · "Câu chuyện"(active). TabDock: Today / Kỷ niệm (active) / Family / Me(avatar "M").
- Author verb: "kể" for stories, "viết" for letters. Audience icon: family icon = Gia đình; lock = Chỉ ba mẹ.

## 14b 205:18 Sửa bản nháp từ gợi ý (Light)
- Top bar: "Huỷ" · title "Bản nháp" · "Lưu nháp".
- Tip (spark, mint-soft) 205:28: "AI viết nháp từ 9 ảnh. Chạm vào bất kỳ đoạn, ảnh hay tiêu đề nào để sửa."
- Cover photo with chip (camera) "Đổi ảnh bìa".
- Title block "Tuần Teddy biết cười"; meta line "1 – 8 tháng 10 · 9 ảnh · mốc Lần đầu cười" (date range · photo count · milestone).
- Text block (selected: mint-soft bg + 2px mint-deep border): "Sáng thứ Hai, khi mẹ vừa hát xong câu ru quen thuộc, Teddy bỗng nhoẻn miệng cười. Cả nhà đứng yên mấy giây, sợ chỉ cần thở mạnh là nụ cười sẽ biến mất."
- Floating Block toolbar 205:70 (dark pill) on selected block: "Sửa" (edit) · "Viết lại" (retry icon) · "Ấm hơn" (spark).
- Photo block: 2 photos side by side.
- Text block: "Chiều hôm đó, ba bế con ra ban công. Nắng nhạt, gió nhẹ, và con lại cười lần nữa — lần này nhìn thẳng vào ba."
- Dashed add row: "Thêm đoạn · ảnh · mốc" (block types: text paragraph, photo, milestone).
- Bottom: secondary "Sắp xếp" + primary "Xem trước & lưu".

## 14c 205:100 Sửa đoạn văn (Light)
- Top: "Huỷ" · "Sửa đoạn" · "Xong".
- Editor (white, 2px mint border) text: "Sáng thứ Hai, khi mẹ vừa hát xong câu ru “Ầu ơ ví dầu”, Teddy bỗng nhoẻn miệng cười. Cả nhà đứng yên mấy giây, sợ chỉ cần thở mạnh là nụ cười sẽ biến mất." (cursor at end)
- Editor meta: left (mint) "Đã sửa · không còn là văn AI"; right "42 từ" (word count).
- Section label "Gợi ý cho đoạn này"; suggestion card italic "“…Teddy bỗng nhoẻn miệng cười, như thể con cũng thuộc lời ru ấy.”"; chips "Dùng câu này" (mint) · "Gợi ý khác".
- AI bar above keyboard 205:176: "Viết lại" (retry) · "Ngắn hơn" (spark) · "Ấm hơn" (spark) · "Hoàn tác" (clock icon = undo).
- System keyboard (placeholder).

## 14d 206:18 Chạm vào ảnh trong bài (Light)
- Same draft editor as 14b; photo block (2 photos) selected w/ mint border. Bottom sheet over scrim.
- Sheet title "Ảnh trong câu chuyện" (SheetHeader w/ close "Đóng").
- Options: "Đổi ảnh" — "Chọn từ Kỷ niệm của Teddy"; "Thêm ảnh vào nhóm này" — "Tối đa 4 ảnh một nhóm"; "Thêm chú thích" — "Hiện nhỏ dưới ảnh"; "Đặt làm ảnh bìa".
- Destructive (error-soft): "Bỏ khỏi câu chuyện" — "Ảnh vẫn còn trong Kỷ niệm".
- => Photos in a story are references to Memory media of that baby (picked from Kỷ niệm), photo group max 4, per-photo caption, cover photo selection; removing from story does not delete memory.

## 14e 206:136 Sắp xếp khối (Light)
- Top: "Huỷ" · "Sắp xếp" · "Xong".
- Hint 206:142: "Giữ ≡ và kéo để đổi thứ tự. Vuốt trái để xoá khối."
- Rows (each with ≡ handle): "Ảnh bìa" (thumb) · title "Tuần Teddy biết cười" · "Sáng thứ Hai, khi mẹ vừa hát xong câu ru…" (Đoạn 1) · "Chiều hôm đó, ba bế con ra ban công…" (Đoạn 2, lifted/rotated 1.5° dragging w/ shadow-lift) · "Nhóm ảnh" 2 thumbs "2 ảnh" · "Mốc" star "Lần đầu cười".
- => Block types: cover photo, title, paragraph, photo group, milestone. Cover and title are reorderable rows too (as drawn).

## 14f 206:212 Xem trước & lưu (Light)
- Full-bleed cover photo; back pill "Sửa tiếp". Story sheet (cream #fbf6ed): label "XEM TRƯỚC", title "Tuần Teddy biết cười", body "Sáng thứ Hai, khi mẹ vừa hát xong câu ru “Ầu ơ ví dầu”, Teddy bỗng nhoẻn miệng cười…"
- Save bottom sheet over scrim: title "Lưu câu chuyện".
- Audience 2 cards: (lock) "Chỉ ba mẹ" — "Riêng tư"; (family) "Gia đình" — "Cả nhà cùng đọc" (SELECTED in mock).
- Row "Báo cho gia đình" — "1 thông báo chung" + Toggle ON.
- Primary "Lưu câu chuyện". Footnote 206:259: "Lưu xong mới chia sẻ ra ngoài được."

## 14g 206:264 Câu chuyện đã lưu (Light) — reader view for parent after save
- Cover photo hero; top: back (circle), "Sửa" (edit icon, white pill), "Chia sẻ" (upload icon, mint primary).
- Toast 206:320 (check): "Đã lưu · đã báo cho gia đình".
- Meta (family icon): "Mẹ kể · hôm nay · Gia đình" (author · relative date · audience).
- Title "Tuần Teddy biết cười"; milestone chip (star, sunshine-soft): "Lần đầu cười · 5 thg 10" (milestone + date).
- Paragraph: "Sáng thứ Hai, khi mẹ vừa hát xong câu ru “Ầu ơ ví dầu”, Teddy bỗng nhoẻn miệng cười. Cả nhà đứng yên mấy giây, sợ chỉ cần thở mạnh là nụ cười sẽ biến mất."
- Photo group 2 photos.
- Pull-quote (Lora italic 20, mint-text) 206:301: "“Như thể con cũng thuộc lời ru ấy.”" => QUOTE block type exists in rendered story (from accepted suggestion?) (inferred — editor didn't show an explicit quote block option).
- Paragraph: "Chiều hôm đó, ba bế con ra ban công. Nắng nhạt, gió nhẹ, và con lại cười lần nữa — lần này nhìn thẳng vào ba."
- Bottom React bar: heart chip (peach-soft) "Bà nội, Ông ngoại thương" (reactions list by name).

## 14h 208:18 Chia sẻ câu chuyện (Light) — sheet 208:56 over the saved story (14g background repeated)
- SheetHeader "Chia sẻ".
- Section "Trong gia đình": row (family icon) "Gia đình đang đọc" — "Đã báo cả nhà · chạm để đổi" + check (current audience; tap to change audience).
- Section "Ra ngoài": "Thiệp ảnh" (camera) — "Đẹp để đăng Facebook, Instagram, Zalo"; "Liên kết xem riêng" (link) — "Có hạn · không cần cài app".
- Note (alert) 208:100: "Chỉ ba mẹ thấy mục “Ra ngoài”. Mặc định ẩn tên thật và ngày sinh."

## 14i 208:104 Thiệp ảnh · chọn mẫu (Light)
- Top: "Huỷ" · "Thiệp ảnh" · "Tiếp".
- Large preview StoryCard 208:109 (304×380 => 4:5 ratio; export 1080×1350). Page dots (5) under preview (swipe between templates).
- Template strip (5) with labels: "1 ảnh" (selected; name "Một khoảnh khắc"), "3 ảnh" ("Ba khung"), "4 ảnh" ("Bốn góc"), "Chữ" ("Lá thư"), "Tối" ("Đêm dịu").
- Template contents (StoryCard variants, component 207:225 set; instances in 14n 208:37714):
  - Một khoảnh khắc (1 ảnh): cream #faf5ec; polaroid photo rotated 3°, handwritten (Dancing Script) caption "Lần đầu cười · 5.10" (milestone · d.m); quote italic "“Như thể con cũng thuộc lời ru ấy.”"; small caps line "TEDDY · 3 TUẦN TUỔI"; brand "Child Life" bottom-right.
  - Ba khung (3 ảnh): title "Tuần Teddy biết cười"; handwritten sub "mùa thu, tháng mười"; 3 tilted photos; italic text "Mẹ hát xong câu ru, con bỗng nhoẻn miệng cười. Cả nhà đứng yên, sợ nụ cười biến mất."; "Child Life".
  - Bốn góc (4 ảnh): white bg 2×2 grid; title "Tuần Teddy biết cười"; "1 – 8 tháng 10 · 3 tuần tuổi"; "Child Life".
  - Lá thư (Chữ): lined paper; handwritten "Gửi Teddy,"; small photo; body "Sáng thứ Hai, mẹ vừa hát xong câu ru quen thuộc thì con bỗng nhoẻn miệng cười. Cả nhà đứng yên mấy giây, sợ chỉ cần thở mạnh là nụ cười sẽ biến mất."; signature "— Mẹ, mùa thu 2026"; "Child Life".
  - Đêm dịu (Tối): dark #1e262c, photo top fade; title "Đêm đầu ngủ một mạch"; quote "“Bốn tiếng không thức giấc — mẹ dậy mà vẫn thấy lạ.”" (gold #d6b478); "Child Life".
- Options panel: "Câu trích" → "“Như thể con cũng thuộc…” ›" (pick quote); "Ảnh" → "Ảnh bìa ›" (pick photo); "Hiện tuổi thay ngày sinh" Toggle ON (default ON in mock).
- Card shows baby nickname + age ("TEDDY · 3 TUẦN TUỔI"), never DOB when toggle on. Branding "Child Life" watermark on every template.

## 14j 208:312 Thiệp · gửi đi (Light) — from metadata only (not fetched, quota)
- StoryCard preview + iOS share sheet 208:339. Head: card thumb + "Tuần Teddy biết cười" + "Ảnh 1080 × 1350". Apps row: "Zalo", "Messenger", "Facebook", "Instagram", "Thêm". Actions: "Lưu hình ảnh", "Sao chép". => Export = single image 1080×1350 (4:5), native OS share sheet.

## 14k 208:36164 Liên kết xem riêng (Light)
- Top: "Quay lại" · "Liên kết xem riêng".
- Link card: (link icon) "childlife.app/s/k7Q2-teddy" + chip "Sao chép". => URL pattern childlife.app/s/{token}-{nickname slug} (inferred: short random token + display nickname slug).
- "Hết hạn sau" segmented: "24 giờ" · "7 ngày" (SELECTED default in mock) · "30 ngày".
- Settings:
  - "Ẩn tên thật & ngày sinh" — "Chỉ hiện “Teddy” và số tuần tuổi" — Toggle ON (default).
  - "Cho tải ảnh về" — "Tắt: người xem chỉ xem, không lưu" — Toggle OFF (default).
  - "Hỏi mật mã 4 số" — "Gửi mật mã riêng cho người nhận" — Toggle OFF (default).
- Note (eye): "Bạn thấy được số lượt xem và thu hồi bất cứ lúc nào."
- Primary "Sao chép & chia sẻ".
- Note: link is shown already generated before pressing the primary (inferred: link created on entering screen or on Sao chép; settings editable before share).

## 14l 208:36210 Người nhận mở liên kết (web) (Light) — mobile Safari, cream bg
- Address bar (lock) "childlife.app".
- Cover photo; title "Tuần Teddy biết cười"; meta "Teddy · 3 tuần tuổi · Mai chia sẻ" (nickname · age in weeks · sharer first name + "chia sẻ").
- Paragraph: "Sáng thứ Hai, khi mẹ vừa hát xong câu ru quen thuộc, Teddy bỗng nhoẻn miệng cười. Cả nhà đứng yên mấy giây, sợ chỉ cần thở mạnh là nụ cười sẽ biến mất." (NB: mock shows pre-edit wording — inconsistency vs saved 14g which has “Ầu ơ ví dầu”.)
- 3-photo row (107px squares).
- Expiry notice (clock): "Liên kết hết hạn ngày 15 thg 10 · không tải ảnh được" (expiry date + download-disabled state).
- Sticky bottom app banner: app icon, "Child Life" / "Lưu giữ kỷ niệm của bé cùng gia đình", button "Tải app".
- NOT shown: milestone chip, pull-quote, reactions, author role ("Mẹ kể"), audience, reply bar, DOB/real name. No passcode prompt / wrong code / expired / revoked web states designed in this section (only this one happy-path frame + Night variant 208:37578).

## 14m 208:36267 Đã chia sẻ ra ngoài (Light) — entry from Tôi (Me)
- Back pill + "Tôi"; title "Đã chia sẻ ra ngoài".
- Section "Đang mở": rows (thumb, title, sub, red-soft chip "Thu hồi"):
  - "Tuần Teddy biết cười" — "12 lượt xem · còn 6 ngày"
  - "Giờ tắm đầu tiên" — "3 lượt xem · còn 23 giờ"
- Section "Thiệp ảnh đã lưu": "Ngày đầu về nhà" — "Ảnh · không thu hồi được" (no action).
- Section "Đã hết hạn": "Đêm đầu ngủ một mạch" — red text "Hết hạn 2 thg 10" (row at 60% opacity, no action).
- (Layer names are stale: "Liên kết · 12 lượt xem · còn 6…", "Đã lưu ảnh · 20 thg 9 · không…" — visible text above is authoritative.)
- Not designed: revoke confirmation dialog, "Đã thu hồi" section/state, link detail/edit settings after creation, per-viewer analytics.

# WEBSITE (page 210:759) — only 2 top-level frames: 219:1391 "Landing · Desktop v2" (1440×7734) and 233:804 "Landing · Mobile v2" (375×9273). NO portal/dashboard/admin, NO recipient-web frames on this page.
NOTE: many text-layer NAMES are stale vs visible text (e.g. eyebrow layer named "Ứng dụng chăm bé & lưu kỷ niệm" displays "●  Miễn phí cho cả gia đình"). Visible text below is authoritative where fetched.

## Nav 219:1392 (desktop; from metadata)
- Logo/Lockup Horizontal; links "Chăm con" · "Kỷ niệm" · "Gia đình" · "Ban đêm" · "Hỏi đáp" (in-page anchors, inferred); CTA button "Tải miễn phí".
- Mobile nav 233:805: logo + button "Tải app" only (no links / no hamburger).

## Hero 219:1413 (desktop, fetched)
- Eyebrow pill: "●  Miễn phí cho cả gia đình"
- H1 (57px bold, 3 lines, lines 2–3 mint): "Cùng chăm con." / "Giữ từng khoảnh khắc" / "con lớn lên."
- Sub: "Một không gian riêng tư cho cả nhà: cùng chăm con, lưu ảnh, video, câu chuyện và nhìn lại hành trình con lớn lên."
- Store badges (black): "Tải trên App Store", "Tải trên Google Play"; caption "Miễn phí trên iPhone và Android."
- Proof: avatar stack M · B · L · H + "Ba mẹ, người chăm và ông bà — ai cũng có chỗ của mình bên con"
- Visual: two tilted phones showing real app snapshots ("Snapshot · 7a Hôm nay · Người chăm sóc · Light", "Snapshot · 10d Kỷ niệm · Album · Light") over mint circle; floating chips "Bú bình · 120 ml / Mẹ ghi · 2 phút trước" and "Bà nội thương ảnh của Teddy / vừa xong".

## Thao tác nhanh 231:162 (desktop, fetched)
- Eyebrow "Khi bận tay"; H2 "Tay bế con, vẫn ghi lại được trong một chạm."; sub "Không cần mở app, không cần nhớ giờ. Chạm ngay trên màn hình điện thoại là xong — để bạn ở bên con lâu hơn một chút."
- Stage label "Ngay trên màn hình điện thoại": widgets (Medium: "Teddy", "Thứ Năm, 8 tháng 10", "Đã thức 2 giờ", "Dậy lúc 13:05 · ngủ 7g50 hôm nay", tiles Bú bình 45 phút / Bú mẹ 3g 35p / Ngủ thức 2g / Thay tã 1g 25p, "Gần đây" list 14:20 Bú bình · 120 ml Mẹ; 13:40 Thay tã · Ướt Cô Lan; 11:45 Ngủ 1 giờ 20 phút Ba; "Hôm nay: 2 cữ bình 240 ml · 1 lần bú mẹ · 2 tã"); small widget "+ 120 ml" quick-add; confirmation "Bú bình · Vừa xong · Đã ghi 120 ml · Bạn" with "Hoàn tác" / "Sửa"; arrow "→" caption "Một chạm là đã ghi xong".
- Lock screen "Cả khi điện thoại đang khoá": 9:41, Thứ Năm, 8 tháng 10; Live Activity "Child Life · Cả nhà đang thấy · Teddy đang ngủ · Từ 21:42 · Ba bắt đầu · 1:27:06 · [Thức dậy] [Sửa giờ bắt đầu]"; lock circular widgets.
- 3 steps: "1 Chạm một lần — Ngay khi vừa cho bé bú xong"; "2 Tự lưu lại cho bạn — Lỡ chạm nhầm cũng sửa được ngay"; "3 Cả nhà thấy ngay — Không ai phải hỏi lại "con ăn chưa?""
- Mobile 233:860: same content stacked (widget stage then lock-screen visual then steps). Layer names in mobile differ (e.g. step 1 name "Ngay trên màn hình chính hoặc…", step 3 "Ba, mẹ, người chăm cùng một nh…") — names may be stale; mobile text not fetched.

## Chăm sóc 220:1801 (desktop, fetched)
- Eyebrow "Chăm sóc mỗi ngày"; H2 "Nhìn là hiểu một ngày của con."; sub "Con đã bú bao nhiêu, ngủ được bao lâu, thay tã lúc nào — tất cả hiện rõ trong một màn hình. Không cần nhớ, không phải đoán, kể cả lúc 3 giờ sáng."
- Bullets: (plus) "Cả ngày của con trong một cái nhìn" — "Dễ nhận ra nhịp ăn ngủ của bé"; (clock) "Đếm giờ giúp bạn khi bé ngủ, khi bú mẹ" — "Liếc điện thoại là biết"; (journal) "Có sẵn số liệu khi đưa con đi khám" (no sub).
- Visual panel: CareTiles "Bú bình 120 ml · 45 phút trước · Mẹ ghi", "Giấc ngủ Đang ngủ · 01:27:06 · từ 21:42 · Ba bắt đầu"; DayRhythm "Đã ghi hôm nay": Bú bình 2 cữ · 240 ml; Bú mẹ 1 cữ · 15 phút; Ngủ (đã xong) 7 giờ 50; Thay tã 2 lần; 24h strip 0h/6h/12h/18h/24h; legend Ngủ/Bú bình/Bú mẹ/Tã; chip (clock) "Vẫn đếm giờ khi bạn tắt màn hình".

## Cùng chăm 220:1918 (desktop, fetched)
- Eyebrow "Cùng chăm"; H2 "Cả nhà cùng chăm, không ai phải hỏi lại."; sub "Ai cho bé bú, ai thay tã, ai ru ngủ — cả nhà đều thấy. Đổi ca cho nhau nhẹ nhàng, không cần nhắn tin hỏi "con ăn lúc mấy giờ?"."
- Bullets: (check) "Biết con đã được chăm đến đâu"; (family) "Đi làm vẫn yên tâm khi bé ở nhà với bà, với cô"; (cloud-off) "Không có mạng vẫn ghi được, không mất gì".
- Visual: Illustration/Family (M, B, Bà, L avatars) + FloatChip "Bạn chọn quyền"; feed card "Vừa ghi": "Bú bình 120 ml — Ba · 13:05"; "Thay tã — Người chăm · 14:20"; "Ngủ 1 giờ 20 — Mẹ · 15:40".
- Layout: copy left, visual right (alternates vs Chăm sóc).

## Tuổi thơ 232:627 (desktop, fetched; white bg; anchor "Kỷ niệm")
- Eyebrow "Kỷ niệm"; H2 (centered) "Nơi lưu giữ trọn tuổi thơ của con."; sub "Ảnh, video và những câu chuyện nhỏ được xếp theo từng tháng tuổi của con. Không lạc giữa hàng nghìn ảnh trong điện thoại, không sợ mất — mở ra là thấy con lớn lên."
- Timeline (horizontal, gradient mint→peach, alternating tilted polaroid cards): "Ngày đầu / Về nhà"; "5 tuần / Lần đầu cười"; "4 tháng / Lần đầu lẫy"; "9 tháng / Chiếc răng đầu tiên"; "1 tuổi / Sinh nhật đầu tiên"; "2 tuổi / Những bước chạy"; "3 tuổi / Ngày đầu đi học"; end "…và mọi năm sau nữa".
- 3 tiles:
  1. "Ảnh của con, gọn gàng một chỗ" — "Không còn lẫn với ảnh chụp màn hình hay hoá đơn. Đánh dấu những tấm bạn thương nhất để tìm lại trong vài giây." (art: photo grid + chip "Yêu thích · 48")
  2. "Câu chuyện của con" — "Từ những gì bạn đã ghi, app gợi ý thành một câu chuyện nhỏ. Bạn sửa vài chữ cho đúng giọng mình, rồi gửi tặng người thân." (art: two StoryCard instances — Lá thư & Một khoảnh khắc)
  3. "Ông bà ở xa vẫn thấy cháu lớn" — "Có ảnh mới là ông bà được báo và thả tim ngay. Không cần gửi lẻ từng tấm qua tin nhắn." (art: notifications "Bà nội thương ảnh của Teddy · vừa xong"; "Ông ngoại đã xem 12 ảnh mới · 5 phút trước"; "Cô Lan thương câu chuyện · hôm qua")
- NB: "Ông ngoại đã xem 12 ảnh mới" implies per-viewer "seen" signal shown to parents (inferred feature; check app screens).
- Mobile 233:1072 (2136 tall): timeline presumably vertical/stacked (not fetched).

## Night care 221:2845 (desktop, fetched; dark card #0c1719; anchor "Ban đêm")
- Eyebrow "Cho những đêm thức giấc"; H2 "Dịu mắt cho những cữ bú lúc nửa đêm."; sub "Buổi tối, màn hình tự dịu lại: nền tối ấm, chữ to, không chói mắt. Bé ngủ tiếp, bạn cũng dễ ngủ lại."
- Checks: "Tự bật vào giờ bạn chọn, không cần nhớ" (layer name "Tự chuyển theo lịch, ví dụ 21:00 – 6:00"); "Nút to, một tay vẫn bấm được khi đang bế con".
- Visual: starfield + moon; Night-mode Live Activity ("Child Life · Cả nhà đang thấy · Teddy đang ngủ · Từ 21:42 · Ba bắt đầu · 1:27:06 · Thức dậy · Sửa giờ bắt đầu"); small widgets "Đang ngủ 1:27:06 Từ 21:42 · Ba [Thức dậy]" and "Bú bình 45 phút trước 120 ml · Mẹ ghi [+ 120 ml]"; lock circular widgets "45p" (feed) and "1:27" (sleep).

## Quyền xem 221:3347 (desktop, fetched; anchor "Gia đình"?)
- Eyebrow "Riêng tư"; H2 "Ảnh của con, chỉ người nhà mới thấy."; sub "Mỗi người trong nhà thấy đúng phần cần thấy. Bạn luôn là người quyết định."
- Role cards (check = allowed, lock = not):
  - M "Ba mẹ" — "Người quyết định mọi thứ": ✓ Chăm con "Thấy và ghi mọi việc chăm con"; ✓ Kỷ niệm "Giữ mọi ảnh, video, câu chuyện"; ✓ Mời người thân "Mời ai, cho xem gì — do bạn chọn".
  - C "Người chăm" — "Bảo mẫu, cô giúp việc": ✓ Chăm con "Ghi lại việc chăm bé trong ngày"; ✓ Kỷ niệm "Gửi ảnh bé cho ba mẹ, không xem album riêng"; 🔒 Mời người thân "Không".
  - B "Người thân" — "Ông bà, cô chú": 🔒 Chăm con "Không thấy chuyện ăn ngủ hằng ngày"; ✓ Kỷ niệm "Xem ảnh và câu chuyện ba mẹ chia sẻ"; 🔒 Mời người thân "Không".
- Notes: (lock) "Ảnh mới mặc định chỉ ba mẹ thấy. Muốn khoe cả nhà, bạn chỉ cần chọn "Gia đình"." ; (eye) "Ảnh của con không hiện trên màn hình khoá, và đường link gửi đi sẽ tự hết hạn."
- NB: caregiver "Gửi ảnh bé cho ba mẹ, không xem album riêng" = caregiver can upload photos during shift but not browse albums (layer name was "Thêm ảnh trong ca, không thấy…"). Product-plan says caregiver "Cannot see Memories" — consistent re viewing, but adds upload capability. Relative-role landing card says "Không thấy chuyện ăn ngủ hằng ngày" (default; plan allows parents to grant extra view).

## CTA 221:3443 (desktop, fetched; mint-deep card)
- H2 (white, 2 lines): "Bớt phải nhớ." / "Thêm thời gian bên con."
- Sub: "Miễn phí trên iPhone và Android. Mời cả nhà chỉ trong một phút."
- White store badges "Tải trên App Store" / "Tải trên Google Play"; caption "Miễn phí cho cả gia đình".
- NO email/waitlist form. (Stale layer name "Đăng ký để là những gia đình đ…" suggests an earlier waitlist concept — superseded by visible text.)

## Hỏi đáp 221:3455 (desktop, fetched)
- H2 "Câu hỏi thường gặp"; sub "Còn điều gì băn khoăn? Cứ nhắn cho chúng tôi nhé." (mobile 233:1448 shows only the title)
- Accordion (chevron-down = expanded, plus = collapsed):
  1. Q "Child Life dành cho bé từ mấy tuổi?" — A "Từ ngày con chào đời. Những năm đầu, app giúp bạn chăm con mỗi ngày; khi con lớn hơn, đây là nơi giữ lại ảnh và câu chuyện của con."
  2. Q "Có mất phí không?" — A "Không. Cả gia đình dùng miễn phí, đủ chỗ cho hàng nghìn ảnh của con. Cần thêm chỗ, bạn chỉ cần nhắn cho chúng tôi."
  3. Q "Ông bà không rành điện thoại có dùng được không?" — collapsed, NO answer text in design.
  4. Q "Ai được xem ảnh và thông tin của con?" — collapsed, NO answer text.
  5. Q "Có dùng được trên Android không?" — collapsed, NO answer text (frame layer named "Có cần ghi đủ mỗi ngày không?" — stale).
- (Stale layer names for answers: "Phù hợp nhất với bé từ sơ sinh…", "Miễn phí. Cả gia đình dùng chu…" — visible text above is authoritative.)

## Footer 221:3488 (metadata)
- Divider; Logo lockup + "© 2026 Child Life"; links "Quyền riêng tư" · "Điều khoản" · "Liên hệ" (no targets defined in design; no social links, no newsletter).
- Mobile 233:1477: logo, links row, then © line below.

## Mobile v2 233:804 layout differences (metadata)
- Nav: logo + "Tải app" button only (no section links).
- All two-column sections stack (copy then visual). Hero shows store badges + caption (layer "Miễn phí cho cả gia đình · 10…" — stale? not fetched); proof avatar row absent in mobile metadata (no M/B/L/H nodes in 233:818).
- Quyền xem: role cards stack vertically (1375 tall). CTA card: title, sub, store badges (no caption under badges). FAQ: no subtitle line. Footer stacked.
- Desktop motion context: none ({"nodes":[]}) — no keyframe animations defined.

---------------------------------------------------------------------
# Business rules confirmed (verbatim evidence)
1. AI draft is a suggestion the parent must edit/approve before saving — 204:125 "Từ 9 ảnh · bạn sửa trước khi lưu"; 205:28 "AI viết nháp từ 9 ảnh. Chạm vào bất kỳ đoạn, ảnh hay tiêu đề nào để sửa."; draft row tag 204:259 "Nháp từ gợi ý · chưa lưu".
2. AI drafts are built from the baby's own saved content (photos + milestone + date range) — 205:45 "1 – 8 tháng 10 · 9 ảnh · mốc Lần đầu cười"; Website 232:832 "Từ những gì bạn đã ghi, app gợi ý thành một câu chuyện nhỏ. Bạn sửa vài chữ cho đúng giọng mình, rồi gửi tặng người thân."
3. Suggestion cadence is weekly — 204:122 "Gợi ý tuần này" (+ onboarding "Cuối tuần có nhật ký của bé." metadata).
4. Edited text is flagged as no longer AI text — 205:109 "Đã sửa · không còn là văn AI".
5. AI per-block actions: toolbar 205:70 "Sửa" · "Viết lại" · "Ấm hơn"; keyboard AI bar 205:176 "Viết lại" · "Ngắn hơn" · "Ấm hơn" · "Hoàn tác"; per-paragraph suggestion "Gợi ý cho đoạn này" with "Dùng câu này" / "Gợi ý khác".
6. Photos in a story come from the baby's Memories; removing them does not delete memories — 206:107 "Chọn từ Kỷ niệm của Teddy"; 206:132 "Ảnh vẫn còn trong Kỷ niệm".
7. Photo group max 4 — 206:113 "Tối đa 4 ảnh một nhóm"; per-photo caption 206:120 "Hiện nhỏ dưới ảnh"; cover selectable 206:126 "Đặt làm ảnh bìa" / 205:40 "Đổi ảnh bìa".
8. Blocks reorderable & deletable — 206:142 "Giữ ≡ và kéo để đổi thứ tự. Vuốt trái để xoá khối."
9. Audience at save: two scopes — 206:237/238 "Chỉ ba mẹ" "Riêng tư"; 206:245/246 "Gia đình" "Cả nhà cùng đọc".
10. Family notification is ONE generic notification, toggleable — 206:249/250 "Báo cho gia đình" "1 thông báo chung"; toast 206:319 "Đã lưu · đã báo cho gia đình".
11. External sharing only after save — 206:259 "Lưu xong mới chia sẻ ra ngoài được." (frame label "Chia sẻ · chỉ sau khi đã lưu").
12. External sharing is parents-only; real name & DOB hidden by default — 208:100 "Chỉ ba mẹ thấy mục “Ra ngoài”. Mặc định ẩn tên thật và ngày sinh."
13. Audience changeable after save from Share sheet — 208:77 "Đã báo cả nhà · chạm để đổi".
14. Card shows age instead of DOB (toggle, default ON) — 208:306 "Hiện tuổi thay ngày sinh"; card text "TEDDY · 3 TUẦN TUỔI".
15. Card export is a single image 1080×1350 shared via OS share sheet — 208:367 "Ảnh 1080 × 1350" (metadata); targets "Zalo", "Messenger", "Facebook", "Instagram", "Thêm"; actions "Lưu hình ảnh", "Sao chép" (metadata).
16. Saved cards cannot be revoked — 208:36303 "Ảnh · không thu hồi được".
17. Private link: expiry choices exactly "24 giờ" / "7 ngày" / "30 ngày" (7 ngày selected in mock) — 208:36179.
18. Link option defaults (as drawn): "Ẩn tên thật & ngày sinh" ON — "Chỉ hiện “Teddy” và số tuần tuổi"; "Cho tải ảnh về" OFF — "Tắt: người xem chỉ xem, không lưu"; "Hỏi mật mã 4 số" OFF — "Gửi mật mã riêng cho người nhận".
19. View count + revoke anytime — 208:36206 "Bạn thấy được số lượt xem và thu hồi bất cứ lúc nào."; 14m rows "12 lượt xem · còn 6 ngày" + "Thu hồi".
20. Recipient needs no app — 208:94 "Có hạn · không cần cài app"; recipient page shows expiry + download state 208:36229 "Liên kết hết hạn ngày 15 thg 10 · không tải ảnh được".
21. Link management lives under Me (Tôi) — 14m back label "Tôi", title "Đã chia sẻ ra ngoài", groups "Đang mở" / "Thiệp ảnh đã lưu" / "Đã hết hạn".
22. Website: new photos default to parents-only; links auto-expire; nothing on lock screen — 221:3437 "Ảnh mới mặc định chỉ ba mẹ thấy. Muốn khoe cả nhà, bạn chỉ cần chọn "Gia đình"."; 221:3442 "Ảnh của con không hiện trên màn hình khoá, và đường link gửi đi sẽ tự hết hạn."
23. "Never invent events" — NOT present as UI copy anywhere in §14 or Website (no "không bịa"/source-accuracy disclaimer). Only implied by "Từ 9 ảnh" and editing flow; rule exists in product plan only.

# Entities & fields implied
- Story: id, babyId, familyId, kind {story | letter} (letter = "Thư", authored "Mẹ viết", cream style) (inferred from 204:234), origin {aiSuggestion | manual ("Viết" FAB)}, status {draft | saved}, title, subtitle? (14a 1-photo card shows "4 tiếng không thức giấc" — inferred subtitle/lead line), coverMediaId, blocks[] (ordered), audience {parentsOnly | family}, notifyFamily (bool, at save), authorMemberId + author relationship label for byline ("Mẹ kể", "Ba kể", "Mẹ viết"), dateRange (start/end), sourceMediaIds[] / sourceMemoryIds[], milestoneRefs[], createdAt, updatedAt ("sửa lần cuối hôm qua"), savedAt, reactionCount + reactors ("Bà nội, Ông ngoại thương"), sharedExternally flag (filter "Đã chia sẻ"), revision (for edit after save).
- StoryBlock: id, type {title, cover, paragraph, photoGroup(1–4 photos, each with optional caption), milestone(name + date e.g. "Lần đầu cười · 5 thg 10"), quote (pull-quote seen in 14g; source: accepted suggestion — inferred), video? (list card "Story · video" 1:12 implies a video cover/block — editor never shows adding video: gap)}, text, aiGenerated flag / editedByUser ("Đã sửa · không còn là văn AI"), wordCount (UI "42 từ"), order.
- AiSuggestion / StoryDraftJob: id, babyId, period (week), sourceMediaIds (count "9 ảnh"), milestone, status (pending/ready/failed — failure UI not designed), generated title/blocks, per-paragraph alternatives ("Gợi ý khác"), undo stack ("Hoàn tác"), rewrite ops {rewrite, shorter, warmer}.
- StoryCard export: storyId, template {Một khoảnh khắc | Ba khung | Bốn góc | Lá thư | Đêm dịu} (UI labels "1 ảnh" "3 ảnh" "4 ảnh" "Chữ" "Tối"), quoteText (pick from story), photo(s) (default "Ảnh bìa"), showAgeInsteadOfDob (default ON), output 1080×1350 image, savedAt ("Thiệp ảnh đã lưu" list), branding "Child Life", irrevocable.
- ShareLink: id, token (URL childlife.app/s/{token}-{slug}, e.g. k7Q2-teddy), storyId, createdBy (parent), expiryOption {24h, 7d, 30d}, expiresAt, hideRealNameAndDob (default true), allowDownload (default false), passcodeEnabled (default false), passcode (4 digits, hashed — inferred), viewCount, status {active, expired, revoked}, revokedAt, createdAt, sharerDisplayName ("Mai chia sẻ").
- Recipient projection (web): title, cover, nickname + age in weeks ("Teddy · 3 tuần tuổi"), sharer first name, paragraphs, photos (download per flag), expiry text, app banner. Excludes: real name, DOB, author role, reactions, milestone chip (not shown), audience, comments.
- Notification: one generic family notification per saved story (if toggle on).

# State machines
## Story
- (none) → AI suggestion offered [weekly "Gợi ý tuần này" card] → user taps "Xem bản nháp" → DRAFT (unsaved AI draft: "Nháp từ gợi ý · chưa lưu", dashed card) → "Lưu nháp" → DRAFT (saved draft; filter "Bản nháp · 2"; badge "Bản nháp") ; "Huỷ" discards unsaved changes (confirmation not designed).
- Manual path: FAB "Viết" → DRAFT (letter/story; e.g. "Thư gửi Teddy tuổi 18" draft with "Chỉ ba mẹ" badge — drafts may carry an intended audience).
- DRAFT → "Xem trước & lưu" → PREVIEW ("XEM TRƯỚC", back "Sửa tiếp") → choose audience + notify → "Lưu câu chuyện" → SAVED(audience=parentsOnly|family) [+ family notified once if toggle on & audience=family].
- SAVED → "Sửa" → editing (same editor; re-save — re-notify behavior not designed) ; SAVED → "Chia sẻ" → change family audience ("chạm để đổi") or external share (parents only).
- Delete story: NOT designed in §14 (gap).
## Share link
- CREATE (screen 14k shows URL pre-generated; settings editable; "Sao chép & chia sẻ") → ACTIVE (viewCount increments; "còn N ngày/giờ") → EXPIRED at expiresAt ("Đã hết hạn" / "Hết hạn 2 thg 10") ; ACTIVE → "Thu hồi" → REVOKED (UI after revoke not designed; inferred row moves out of "Đang mở").
- Recipient: open URL → [if passcode] enter 4-digit code (NOT designed) → content view (14l) ; wrong code / expired / revoked / not found pages NOT designed.
## Story card
- choose template + quote + photo + age toggle → "Tiếp" → OS share sheet → saved/shared image → listed under "Thiệp ảnh đã lưu" ("không thu hồi được"); terminal (no revoke).

# Landing requirements
- Single marketing landing page, desktop (1440) + mobile (375) designs; Light only; no motion/keyframe data in Figma (both frames return no motion nodes) → use subtle default motion only.
- Sections in order: Nav, Hero, Thao tác nhanh ("Khi bận tay"), Chăm sóc, Cùng chăm, Tuổi thơ ("Kỷ niệm"), Night care, Quyền xem ("Riêng tư"), CTA, Hỏi đáp, Footer.
- Nav desktop links "Chăm con" · "Kỷ niệm" · "Gia đình" · "Ban đêm" · "Hỏi đáp" → in-page anchors (inferred mapping: Chăm con→Chăm sóc/Thao tác nhanh, Kỷ niệm→Tuổi thơ, Gia đình→Cùng chăm or Quyền xem, Ban đêm→Night care, Hỏi đáp→FAQ). CTA "Tải miễn phí" (desktop) / "Tải app" (mobile) → store links (inferred: device-detect or scroll to CTA).
- CTAs: App Store + Google Play badges in Hero and CTA band. No email/waitlist form, no sign-up, no login, no contact form anywhere.
- FAQ: accordion; only Q1 & Q2 have answers in design; Q3–Q5 answers missing.
- Footer: logo, "© 2026 Child Life", links "Quyền riêng tư", "Điều khoản", "Liên hệ" (targets undefined → need privacy & terms pages + contact mechanism).
- Imagery: uses real app screenshots (Snapshot 7a Hôm nay · Người chăm sóc; 10d Kỷ niệm · Album) and component illustrations (widgets, Live Activity, StoryCard, CareTile, DayRhythm).
- Performance targets from brief apply (LCP ≤2.5 s, CLS ≤0.1, INP ≤200 ms).
- PORTAL/DASHBOARD/ADMIN: NOT present on Website page (only 2 frames). RECIPIENT WEB: not on Website page; only one recipient frame exists in Screens §14 (14l 208:36210 + Night 208:37578), drawn at mobile width in Safari.

# Open questions / gaps (with node ids)
1. Recipient web states missing: passcode entry, wrong passcode, too many attempts, expired, revoked, not found, desktop layout, download UI when allowed (only 208:36210 happy path, download disabled).
2. Passcode delivery: 208:36201 "Gửi mật mã riêng cho người nhận" — is the code generated or user-chosen? Where is it displayed/copied after creation? Not designed (208:36164 shows toggle off only).
3. Link creation timing: 208:36173 shows URL before "Sao chép & chia sẻ" — create on screen open (risk orphan links) or on tap? Can settings be edited after creation? (no edit UI in 208:36267).
4. Revoke: no confirmation dialog nor post-revoke state ("Đã thu hồi" section absent) in 208:36267.
5. Does a link reflect later story edits/deletions or a frozen snapshot? Story deletion / source memory deleted or made private → effect on links & drafts not designed (plan requires compliance).
6. Recipient content projection: 208:36210 omits milestone chip & pull-quote and uses pre-edit paragraph text ("câu ru quen thuộc" vs saved "“Ầu ơ ví dầu”" in 206:285) — confirm intended projection (likely mock inconsistency).
7. Sharer identity on recipient page: "Mai chia sẻ" (208:36218) reveals parent's first name even when real baby name hidden — confirm.
8. AI: no failure/loading/empty state, no generation trigger UI other than weekly card; no accuracy/source disclaimer; which sources allowed (photos only? notes? care records?) and visibility (parents-only memories included?) not stated. "Gợi ý tuần này" schedule and per-baby limits undefined.
9. Video in stories: list card 204:207 shows a video story (1:12) but editor (205:18, 206:18 "Thêm đoạn · ảnh · mốc") has no video block — clarify.
10. Letter ("Thư") type: 204:234 — how created (FAB "Viết" → choice?) not designed; Add (+) button 204:91 and View/filter (sliders) 204:89 destinations not designed in §14.
11. Re-notification on edit after save, and who may edit (author only vs any parent) — not designed (206:312 "Sửa").
12. Draft auto-save vs explicit "Lưu nháp" (205:22); "Huỷ" discard confirmation.
13. 14j share sheet (208:312) not fetched in full (rate limit) — copy taken from layer names.
14. Website FAQ answers missing for 221:3473, 221:3478, 221:3483 (frame named "Có cần ghi đủ mỗi ngày không?" but displays "Có dùng được trên Android không?").
15. Website footer link targets (221:3503–3505) & store URLs undefined; privacy/terms pages not designed.
16. Website copy vs plan: Quyền xem caregiver "Kỷ niệm — Gửi ảnh bé cho ba mẹ, không xem album riêng" (221:3395) implies caregiver photo upload; plan says caregiver cannot see Memories — confirm upload capability exists in app screens.
17. Website "Ông ngoại đã xem 12 ảnh mới" (232:845) implies seen-receipts for family viewers — confirm exists in app.
18. Story saved with audience "Chỉ ba mẹ" — can it still be shared externally (plan: yes, parents only)? Card/link from a parents-only story not explicitly addressed.
19. Night care variants: verified structurally identical (metadata) for 14k/14l/14m; no behavior differences found; visual tokens only.
