# v1.1 content features (Hôm nay, Thẻ theo tuổi, Mốc, Thư viện, Ăn dặm, Wonder Week, Sơ cứu, Dinh dưỡng): spec extracted from final Figma

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only). Node **`304:18`** is the whole canvas/page **"v1.1"**, not a single frame. Read 2026-10-12. Only `get_metadata` (once, on `304:18`), `get_design_context` (once per frame) and `get_screenshot` (once, on `photo_demo`) were called. No Figma node was modified.

**What this page is.** It holds every v1.1 app screen: 90 phone frames in 9 clusters, plus one asset sheet. The clusters are:
- **A** the Today/Me changes;
- **2** age cards, **3** developmental milestones, **6** Wonder Week (together, the "Hiểu con" content);
- **4** the care library, **5** solid food (ăn dặm);
- **7** child first aid, with 24 situation pages;
- **8** spending (already in [`19-spending.md`](19-spending.md), not repeated here);
- **9** nutrition by stage.

Clusters 2, 6 and 9 are labelled **"(nội dung từ portal)"** (content from the portal). That makes this page the app-side counterpart of the admin portal's v1.1 section (B01–B10 in [`18-admin-portal-v1.md`](18-admin-portal-v1.md) §10).

**How it was read**
- `get_metadata` on `304:18` returned the full layer tree (≈ 685 kB). The top-level frames and labels below come from it.
- Each of the 75 non-spending frames got exactly one `get_design_context`, split across six read passes (parts A–F, kept as the sections below). The 15 spending frames were read earlier for `19-spending.md`. **No call failed and no rate limit was hit.**
- Strings are the rendered text from `get_design_context`, never layer names (`get_metadata` cuts names at 30 characters). Where a layer name disagrees with the rendered text, it is flagged.
- **Prototype links:** a node with a prototype interaction is rendered as `<a … cursor-pointer>` and marked **(prototype link)**. Only clusters 7, 8 and 9 carry any (7a, 7b, the TH pages' back and call buttons, 9a–9g). Clusters A, 2, 3, 4, 5 and 6 have **no prototype wiring at all**, so their navigation is inferred.
- **Annotations:** the only `data-annotation` on the page is the copy-pasted v1.0 annotation on A1 (Today). No other frame has one. Intent comes from frame names, cluster labels, copy and component descriptions.
- "(inferred)" marks anything the design does not state literally.
- **Screenshots:** `docs/discovery/figma-extract/img/v11/<node id with : → ->.png`. There is one per frame (90, including spending's 15) plus `443-4088.png` (the asset sheet).
- **Night care:** only **A7** (Today) is drawn in Night care. Every other frame is Light (`cloud #f6fcfb`).

**Mock scenarios (they conflict across clusters)**
| Cluster | Baby / age / "now" |
|---|---|
| A, 2, 3, 4, 6 | **Teddy**, born 17/09/2026, due date 21/09/2026, **3 weeks**; now Thu **08/10/2026** (6e/6f: Mon 12/10). Matches `17-vaccination.md`. |
| 5, 7 | **bé Na · 7 tháng** (born ≈ late 02/2026); 7h "7,8 kg" |
| 8 (spending) | Teddy **7 months**, now 12/10/2026 |
| 9 | Teddy **7 months**, 7,8 kg / 68,5 cm, now 12/10/2026; 9e Teddy 6 months, 6,2 kg; 9g vitamin A taken 01/06/2026 (≈ 3 months, below the 6–36-month eligibility) |
| TH01–TH24 | no baby, age or date; illustrations show an infant (TH01–TH06) and a preschool boy (others) |

Family: Mẹ **Mai** (the user, "M"), **Ba Tuấn**, the caregiver **Cô Lan** ("L"), and ông bà. A second baby, **Na**, appears in Tôi and in clusters 5 and 7.

## Frame list (canvas order, by row)
Cluster labels (top-level text nodes):
- `315:43766` "Label · Hôm nay · Tôi"
- `310:42549` "Label · 2 · Thẻ theo tuổi (nội dung từ portal)"
- `311:1183` "Label · 3 · Mốc phát triển"
- `312:1445` "Label · 4 · Thư viện chăm bé"
- `313:1680` "Label · 5 · Ăn dặm (bé Na · 7 tháng)"
- `315:2505` "Label · 6 · Wonder Week (nội dung từ portal)"
- `429:53390` "Label · 7 · Sơ cứu trẻ em (v1.1)"
- `433:54377` "Label · 7 · Sơ cứu · chi tiết 24 tình huống". The older label `429:53391` "… chi tiết 17 tình huống" overlaps it at the same position and is stale.
- `437:3182` "Label · 8 · Chi tiêu cho bé (v1.1)"
- `440:3766` "Label · 9 · Dinh dưỡng theo giai đoạn (nội dung từ portal)"

No label is numbered 1; the unnumbered "Hôm nay · Tôi" cluster probably plays that role (inferred). The A series skips A3 and A6, and whether those frames were deleted or never drawn is not known.

| y | x | Node | Name | Size | Screenshot |
|---|---|---|---|---|---|
| 100 | 0 | 308:18 | A1 · Hôm nay | 375 × 1480 | `img/v11/308-18.png` |
| 100 | 415 | 308:40577 | A2 · Tuỳ chỉnh Hôm nay | 375 × 812 | `img/v11/308-40577.png` |
| 100 | 830 | 308:40785 | A4 · Tôi (từ avatar) | 375 × 812 | `img/v11/308-40785.png` |
| 100 | 1245 | 315:43767 | A5 · Hôm nay · người chăm | 375 × 1288 | `img/v11/315-43767.png` |
| 100 | 1660 | 315:44134 | A7 · Hôm nay · Night care | 375 × 1480 | `img/v11/315-44134.png` |
| 1750 | 0 | 310:42550 | 2a · Thẻ theo tuổi | 375 × 812 | `img/v11/310-42550.png` |
| 1750 | 415 | 310:42649 | 2b · Chi tiết giai đoạn | 375 × 1312 | `img/v11/310-42649.png` |
| 1750 | 830 | 310:42762 | 2c · Thiếu ngày sinh | 375 × 812 | `img/v11/310-42762.png` |
| 3500 | 0 | 311:1184 | 3a · Mốc phát triển | 375 × 1060 | `img/v11/311-1184.png` |
| 3500 | 415 | 311:1308 | 3b · Chi tiết mốc | 375 × 812 | `img/v11/311-1308.png` |
| 3500 | 830 | 311:1364 | 3c · Ghi nhận mốc | 375 × 812 | `img/v11/311-1364.png` |
| 3500 | 1245 | 311:1436 | 3d · Đã lưu mốc | 375 × 812 | `img/v11/311-1436.png` |
| 3500 | 1660 | 311:41672 | 3e · Tạo kỷ niệm từ mốc | 375 × 812 | `img/v11/311-41672.png` |
| 3500 | 2075 | 311:41752 | 3f · Mốc đã gắn kỷ niệm | 375 × 812 | `img/v11/311-41752.png` |
| 3500 | 2490 | 311:41795 | 3g · Tạo mốc riêng | 375 × 812 | `img/v11/311-41795.png` |
| 4850 | 0 | 312:1446 | 4a · Thư viện chăm bé | 375 × 1150 | `img/v11/312-1446.png` |
| 4850 | 415 | 312:1574 | 4b · Tìm & lọc | 375 × 812 | `img/v11/312-1574.png` |
| 4850 | 830 | 312:1679 | 4c · Bộ lọc | 375 × 812 | `img/v11/312-1679.png` |
| 4850 | 1245 | 312:42000 | 4d · Bài viết | 375 × 1600 | `img/v11/312-42000.png` |
| 4850 | 1660 | 312:42116 | 4e · Đã lưu bài viết | 375 × 812 | `img/v11/312-42116.png` |
| 4850 | 2075 | 312:42236 | 4f · Bài đã lưu | 375 × 812 | `img/v11/312-42236.png` |
| 6700 | 0 | 313:1681 | 5a · Bật theo dõi ăn dặm | 375 × 812 | `img/v11/313-1681.png` |
| 6700 | 415 | 313:1746 | 5b · Ăn dặm · Nhật ký | 375 × 1000 | `img/v11/313-1746.png` |
| 6700 | 830 | 313:1872 | 5c · Ghi bữa ăn | 375 × 1000 | `img/v11/313-1872.png` |
| 6700 | 1245 | 314:1786 | 5d · Lịch sử bữa ăn | 375 × 1000 | `img/v11/314-1786.png` |
| 6700 | 1660 | 314:1901 | 5e · Món đã thử | 375 × 1000 | `img/v11/314-1901.png` |
| 6700 | 2075 | 314:1987 | 5f · Thư viện ăn dặm | 375 × 1000 | `img/v11/314-1987.png` |
| 6700 | 2490 | 314:2095 | 5g · Bài ăn dặm (công thức) | 375 × 975 | `img/v11/314-2095.png` |
| 6700 | 2905 | 314:2169 | 5h · Hôm nay · thẻ ăn dặm | 375 × 812 | `img/v11/314-2169.png` |
| 8000 | 0 | 315:2506 | 6a · Wonder Week · thiết lập | 375 × 812 | `img/v11/315-2506.png` |
| 8000 | 415 | 315:2566 | 6b · Lịch dự kiến | 375 × 1250 | `img/v11/315-2566.png` |
| 8000 | 830 | 315:2684 | 6c · Chi tiết giai đoạn | 375 × 1218 | `img/v11/315-2684.png` |
| 8000 | 1245 | 315:2804 | 6d · Thông báo trước 3 ngày | 375 × 812 | `img/v11/315-2804.png` |
| 8000 | 1660 | 315:2833 | 6e · Ghi biểu hiện thực tế | 375 × 812 | `img/v11/315-2833.png` |
| 8000 | 2075 | 315:2972 | 6f · Ghi chép của nhà mình | 375 × 812 | `img/v11/315-2972.png` |
| 9620 | 0 | 429:2424 | 7a · Chăm sóc · lối vào Sơ cứu | 375 × 1411 | `img/v11/429-2424.png` |
| 9620 | 415 | 433:2879 | 7b · Sơ cứu | 375 × 2524 | `img/v11/433-2879.png` |
| 9620 | 830 | 428:2346 | 7c · Sơ cứu · Tìm kiếm | 375 × 812 | `img/v11/428-2346.png` |
| 9620 | 1245 | 427:2048 | 7d · Hóc dị vật · dưới 1 tuổi | 375 × 1842 | `img/v11/427-2048.png` |
| 9620 | 1660 | 429:2573 | 7e · Hóc dị vật · từ 1 tuổi | 375 × 1651 | `img/v11/429-2573.png` |
| 9620 | 2075 | 429:2711 | 7f · Từng bước · Vỗ lưng | 375 × 822 | `img/v11/429-2711.png` |
| 9620 | 2490 | 429:2779 | 7g · Từng bước · Ấn ngực | 375 × 822 | `img/v11/429-2779.png` |
| 9620 | 2905 | 429:2848 | 7h · Gọi 115 | 375 × 822 | `img/v11/429-2848.png` |
| 9620 | 3320 | 434:3155 | 7i · CPR · Ép ngực (nhịp) | 375 × 869 | `img/v11/434-3155.png` |
| 11800 | 0 | 433:3201 | 7 · TH01 · Hồi sức tim phổi (CPR) | 375 × 1842 | `img/v11/433-3201.png` |
| 11800 | 415 | 433:3343 | 7 · TH02 · Sặc sữa | 375 × 1831 | `img/v11/433-3343.png` |
| 11800 | 830 | 433:3483 | 7 · TH03 · Ngừng thở ở trẻ sinh non | 375 × 1200 | `img/v11/433-3483.png` |
| 11800 | 1245 | 433:3566 | 7 · TH04 · Co giật | 375 × 1749 | `img/v11/433-3566.png` |
| 11800 | 1660 | 433:3699 | 7 · TH05 · Sốc phản vệ | 375 × 1278 | `img/v11/433-3699.png` |
| 11800 | 2075 | 433:3793 | 7 · TH06 · Uống nhầm thuốc, hoá chất | 375 × 1889 | `img/v11/433-3793.png` |
| 11800 | 2490 | 433:3920 | 7 · TH07 · Tai nạn giao thông | 375 × 1791 | `img/v11/433-3920.png` |
| 11800 | 2905 | 433:4047 | 7 · TH08 · Chảy máu cam | 375 × 1480 | `img/v11/433-4047.png` |
| 11800 | 3320 | 433:4149 | 7 · TH09 · Vết thương chảy máu | 375 × 1186 | `img/v11/433-4149.png` |
| 11800 | 3735 | 433:4234 | 7 · TH10 · Băng bó cơ bản | 375 × 1418 | `img/v11/433-4234.png` |
| 11800 | 4150 | 433:4332 | 7 · TH11 · Bỏng nước sôi | 375 × 1252 | `img/v11/433-4332.png` |
| 11800 | 4565 | 433:4423 | 7 · TH12 · Bong gân | 375 × 1141 | `img/v11/433-4423.png` |
| 14000 | 0 | 433:53311 | 7 · TH13 · Gãy xương | 375 × 1428 | `img/v11/433-53311.png` |
| 14000 | 415 | 433:53417 | 7 · TH14 · Tổn thương ở mắt | 375 × 1366 | `img/v11/433-53417.png` |
| 14000 | 830 | 433:53511 | 7 · TH15 · Chó cắn | 375 × 1229 | `img/v11/433-53511.png` |
| 14000 | 1245 | 433:53604 | 7 · TH16 · Ong đốt | 375 × 1141 | `img/v11/433-53604.png` |
| 14000 | 1660 | 433:53682 | 7 · TH17 · Kiến ba khoang | 375 × 1141 | `img/v11/433-53682.png` |
| 14000 | 2075 | 433:53759 | 7 · TH18 · Côn trùng vào tai | 375 × 1099 | `img/v11/433-53759.png` |
| 14000 | 2490 | 433:53833 | 7 · TH19 · Rắn cắn | 375 × 1275 | `img/v11/433-53833.png` |
| 14000 | 2905 | 433:53925 | 7 · TH20 · Say nắng, say nóng | 375 × 1417 | `img/v11/433-53925.png` |
| 14000 | 3320 | 433:54033 | 7 · TH21 · Đo thân nhiệt | 375 × 1354 | `img/v11/433-54033.png` |
| 14000 | 3735 | 433:54128 | 7 · TH22 · Ngộ độc thực phẩm | 375 × 1173 | `img/v11/433-54128.png` |
| 14000 | 4150 | 433:54201 | 7 · TH23 · Nhiễm lạnh | 375 × 1174 | `img/v11/433-54201.png` |
| 14000 | 4565 | 433:54284 | 7 · TH24 · Vàng da sơ sinh | 375 × 1143 | `img/v11/433-54284.png` |
| 15770 | 0 | 437:3596 | 8a · Chăm sóc · ô Chi tiêu | 375 × 1411 | `img/v11/437-3596.png` — see `19-spending.md` |
| 15770 | 415 | 437:3183 | 8b · Chi tiêu · tháng này | 375 × 1339 | `img/v11/437-3183.png` — see `19-spending.md` |
| 15770 | 830 | 437:3759 | 8c · Thêm khoản chi | 375 × 880 | `img/v11/437-3759.png` — see `19-spending.md` |
| 15770 | 1245 | 438:3382 | 8d · Thống kê · 6 tháng | 375 × 1281 | `img/v11/438-3382.png` — see `19-spending.md` |
| 15770 | 1660 | 438:3586 | 8e · Thống kê · từ khi sinh | 375 × 1101 | `img/v11/438-3586.png` — see `19-spending.md` |
| 15770 | 2075 | 438:52517 | 8f · Lịch sử chi tiêu | 375 × 943 | `img/v11/438-52517.png` — see `19-spending.md` |
| 15770 | 2490 | 438:52658 | 8g · Chi tiết khoản chi | 375 × 812 | `img/v11/438-52658.png` — see `19-spending.md` |
| 15770 | 2905 | 438:52717 | 8h · Ngân sách tháng | 375 × 965 | `img/v11/438-52717.png` — see `19-spending.md` |
| 15770 | 3320 | 438:53053 | 8i · Khoản định kỳ | 375 × 812 | `img/v11/438-53053.png` — see `19-spending.md` |
| 15770 | 3735 | 438:53127 | 8j · Chi tiêu · lần đầu | 375 × 812 | `img/v11/438-53127.png` — see `19-spending.md` |
| 15770 | 4150 | 438:53200 | 8k · Tiêm chủng · ghi chi phí | 375 × 812 | `img/v11/438-53200.png` — see `19-spending.md` |
| 15770 | 4565 | 438:53271 | 8l · Gia đình · quyền xem chi tiêu | 375 × 812 | `img/v11/438-53271.png` — see `19-spending.md` |
| 15770 | 4980 | 439:3641 | 8m · Danh mục chi tiêu | 375 × 916 | `img/v11/439-3641.png` — see `19-spending.md` |
| 15770 | 5395 | 439:3794 | 8n · Thêm / sửa danh mục | 375 × 812 | `img/v11/439-3794.png` — see `19-spending.md` |
| 15770 | 5810 | 439:3894 | 8o · Xoá danh mục | 375 × 900 | `img/v11/439-3894.png` — see `19-spending.md` |
| 17500 | 0 | 440:3934 | 9a · Chăm sóc · ô Dinh dưỡng | 375 × 1411 | `img/v11/440-3934.png` |
| 17500 | 415 | 440:3767 | 9b · Dinh dưỡng · giai đoạn hiện tại | 375 × 1715 | `img/v11/440-3767.png` |
| 17500 | 830 | 440:4105 | 9c · Lượng sữa theo giai đoạn | 375 × 1099 | `img/v11/440-4105.png` |
| 17500 | 1245 | 440:4217 | 9d · Vi chất · Sắt | 375 × 1033 | `img/v11/440-4217.png` |
| 17500 | 1660 | 441:3917 | 9e · Gợi ý theo tăng trưởng · dưới chuẩn | 375 × 1017 | `img/v11/441-3917.png` |
| 17500 | 2075 | 441:4018 | 9f · Các giai đoạn dinh dưỡng | 375 × 953 | `img/v11/441-4018.png` |
| 17500 | 2490 | 441:4100 | 9g · Lịch uống vitamin A | 375 × 812 | `img/v11/441-4100.png` |

**Not a screen:** `443:4088` **"photo_demo"** (9416 × 6344, at x −10286, y 12256, off to the left of the page). It holds 31 rounded-rectangle image fills, each 1536 × 1024 (3:2), named in English with a running number: "Infant CPR Chest Compressions-1", "Pastel clay child CPR demonstration-2", "Gentle head tilt and chin lift-3", … "Two sleeping newborns, soft skin comparison-31", "Wrong nosebleed posture-14". It is the **source sheet for the first-aid illustrations** (`Illus/FA/*`): soft 3D clay-style children and carers on pastel yellow, mint and peach backgrounds. Some images have a ✓ or ✗ badge baked into the bitmap. Screenshot: `img/v11/443-4088.png`.

## Cluster map and cross-cluster findings
- **Tab bar changes (A1).** "NavBar v1.1" has the tabs Today · Memories · Family · **Utilities** (Icon/grid). The **Care tab is gone** from the dock. The caregiver dock is Today · Family · Utilities. Yet 7a, 8a and 9a still draw the **"Chăm sóc"** hub with the old TabDock. So "Utilities" is probably the Care hub renamed (inferred, open question).
- **Care hub (7a / 8a / 9a)** is drawn from three different bases, and no frame shows them combined:
  - 7a adds a red full-width entry banner, **"Sơ cứu trẻ em · 25 tình huống · dùng khi không có mạng"**.
  - 8a adds the **Chi tiêu** tile.
  - 9a adds a **Dinh dưỡng · Giai đoạn 6–8 tháng** tile.
  - All three still list **Wonder Week, Thẻ theo tuổi, Mốc phát triển, Thư viện chăm bé, Ăn dặm** under **"Sớm ra mắt"** (coming soon), even though this page designs all five.
- **Today (A1)** gains a "Dành cho bé hôm nay" section with a Wonder Week countdown card and an age card ("Hướng dẫn · 2 bài viết · 3 mốc"). The Customise sheet (A2) gains the rows Wonder Week, Thẻ theo tuổi and Ăn dặm hôm nay, plus a "+ Ăn dặm" tile, which makes **solids a 7th tracker kind**. 5h shows the "Ăn dặm hôm nay" card.
- **First-aid index vs detail pages.** 7b lists **25 situations** in 4 groups: Khẩn cấp 8, Vết thương & bỏng 7, Côn trùng & động vật 5, Sức khoẻ 5. They are covered by **TH01–TH24** plus **Hóc dị vật** (choking), whose detail is 7d (under 1 year) and 7e (from 1 year), with step mode in 7f and 7g. The CPR metronome is 7i and the call sheet is 7h. The red emergency treatment ("Gọi 115" pill and bottom button) is on TH01–TH07 and also on **TH19 Rắn cắn and TH20 Say nắng**. Those two sit in the non-emergency groups of 7b.
- **Editorial content shares one review promise.** Every content screen says it was written or reviewed by "đội chuyên môn Child Life" / "chuyên gia y tế". Only 2b, 4d, 5f, 5g and 9c show a review or update month ("09/2026"). Only 9c ("Nguồn: AAP, WHO") and 9d ("Nguồn: WHO 2023, AAP") name sources. The first-aid pages show neither. See the consolidated questions at the end.
- **Raw colours.** First aid uses `#db4a45` (red) and `#fcebe8` (red soft) with no token. 9d uses a slash-named token, `care/pump/soft #f5eafa`.

---

## Part A: v1.1 "Hôm nay · Tôi" and "Thẻ theo tuổi" clusters

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only), page **v1.1**. Read 2026-10-12, with one `get_design_context` call per frame and no other Figma calls. No Figma node was modified.

- Screenshots: `docs/discovery/figma-extract/img/v11/<id with : → ->.png` (308-18, 308-40577, 308-40785, 315-43767, 315-44134, 310-42550, 310-42649, 310-42762). `310-42550.png` already existed (08:47) and was overwritten with this pass's render.
- **Prototype links:** none of the 8 frames has a `<a … cursor-pointer>` node. All navigation below is **inferred**.
- **Mock scenario:** baby **Teddy · 3 tuần** (Teddy · 3 weeks), "now" is **Thứ Năm, 8 tháng 10** (Thursday 8 October; 15:05 on the DayRhythm "Now" line). This matches the vaccination cluster (born 17/9/2026), but not the spending cluster (7 months). The parent user is **Mai** ("M", Mẹ), the caregiver is **Cô Lan** ("L"), the father is "Ba". A second baby, **Na**, appears only in Tôi ("Teddy, Na").

---

### Cluster "Label · Hôm nay · Tôi" (y 100)

#### What changed versus v1.0-improvement (16-v1-improvement.md, cluster 8)
1. **NavBar v1.1 (new tab model).** The instance is named "NavBar v1.1". Parent tabs, in order: **Tab/Today** (active, label "Hôm nay"), **Tab/Memories**, **Tab/Family**, **Tab/Utilities** (Icon/grid: four 8 px rounded squares, `nav-icon #b9cfcf`). In v1.0-improvement and in the current code (`ClTab { today, memories, care, family }`) the order was Today · Memories · **Care** · Family. v1.1 replaces the "Care" tab with **"Utilities"** (Icon/grid) and moves it to the end. The label of the Utilities tab is not drawn (only the active tab shows a label). The caregiver dock (A5) is Today · Family · Utilities (no Memories). Which screen the Utilities tab opens is not in this cluster; it may be the old "Chăm sóc" hub renamed (inferred; see the spending cluster's 8a "Chăm sóc" screen).
2. **New Today section "Dành cho bé hôm nay"** (For baby today). It sits between ReminderPeek and the "Hôm nay · Lịch sử" DayRhythm. The layer group is "Sắp tới & cho bé" (Upcoming & for baby). It holds two new cards:
   - **Wonder Week card** ("Card · Wonder Week sắp tới"): countdown pill "Còn 3 ngày", title "Wonder Week 1 sắp bắt đầu", and body with expected weeks and a disclaimer.
   - **Age card on Today** ("Card · Thẻ theo tuổi"): age label, a headline, 2 tip bullets, and a footer link "Hướng dẫn · 2 bài viết · 3 mốc" pointing to stage detail 2b (inferred).
3. **Customise sheet grows from 3 to 6 section rows.** New rows: **Wonder Week** ("Hiện trước 3 ngày khi sắp tới"), **Thẻ theo tuổi** ("Gợi ý theo tuổi của bé") and **Ăn dặm hôm nay** ("Bật theo dõi ăn dặm để hiện"). The Ăn dặm row is drawn disabled (muted text, toggle OFF). The tile chips get a 7th, **unselected "+ Ăn dặm"** chip, which implies **solids as a 7th tracker kind**. That kind is not among today's `trackerKinds` (bottle, breast, sleep, diaper, pump, growth).
4. **Today header, tiles, ReminderPeek and DayRhythm** are unchanged from v1.0-improvement 370:1248, with the same values and the same copy-pasted annotation.
5. **Tôi (A4)** is identical to v1.0-improvement 370:1898. Nothing in it is new.
6. **No milestone, library or solid-food entry tiles appear on Today itself.** Milestones and articles are reached only through the age card footer ("3 mốc", "2 bài viết"). Solid food appears only as the off toggle and chip in A2.

---

### 308:18 — A1 · Hôm nay (Today, parent, Light)

**Annotation (frame, verbatim, unchanged from v1.0):** "Thẻ lớn = vừa ghi vừa xem: chạm thẻ → mở sheet ghi mục đó (1 chạm); dòng dưới là lần cuối (bao lâu trước · chi tiết · ai ghi). Ngủ khi timer chạy → CareTile Tone=Active hiện thời gian đang chạy. Tăng trưởng: hàng riêng, + mở màn nhập số đo. "Lịch sử" → dòng thời gian."
(Gloss: big tiles both log and show; tapping a tile opens that type's log sheet in one tap; the lines below are the last entry (how long ago · detail · who logged). While the sleep timer runs, CareTile Tone=Active shows the running time. Growth gets its own row, and + opens the measurement screen. "Lịch sử" opens the timeline.) As in v1.0, Growth actually shares Row 3 with Pump and has no "+".

**Text (reading order)**
- StatusBar "9:41" / "•••"
- Header: UserAvatar "M" · BabySwitcher "Teddy · 3 tuần" + chevron · spacer · Night care toggle (moon, Icon/sleep)
- "Thứ Năm, 8 tháng 10" (Thursday, 8 October)
- Title row: "Hôm nay" (Today) · pill [Icon/sliders] "Tuỳ chỉnh" (Customise)
- Care tiles (2 × 3):
  - "Bú bình" (Bottle) "120 ml" / "45 phút trước" (45 min ago) / "Mẹ ghi" (logged by Mum)
  - "Bú mẹ" (Breastfeed) "15 phút" / "Kết thúc 3 giờ 35 phút trước" (Ended 3 h 35 min ago) / "Mẹ ghi"
  - "Giấc ngủ" (Sleep) "Đã thức 2 giờ" (Awake 2 h) / "Dậy lúc 13:05" (Woke at 13:05) / "Ba ghi" (logged by Dad)
  - "Thay tã" (Diaper) "Tã ướt" (Wet) / "1h 25p trước" / "Cô Lan ghi" (logged by Ms Lan)
  - "Hút sữa" (Pump) "90 ml" / "2 giờ trước" / "Mẹ ghi"
  - "Tăng trưởng" (Growth) "4,3 kg" / "54,5 cm" / "+0,4 kg · hôm nay"
- ReminderPeek: "Nhắc việc · 3" / "Tiêm 6 trong 1" (6-in-1 shot) / "Thứ Bảy 08:30 · còn 2 ngày" (Saturday 08:30 · 2 days left) / chevron
- **NEW** section title "Dành cho bé hôm nay" (For baby today; Bold 17 ink)
  - **NEW Wonder Week card:** pill "Còn 3 ngày" (3 days left) · chevron-right · title "Wonder Week 1 sắp bắt đầu" (Wonder Week 1 is about to start) · body "Dự kiến tuần 4–5 · Bé bắt đầu cảm nhận rõ hơn âm thanh, ánh sáng, mùi vị. Mỗi bé mỗi khác, chỉ để tham khảo." (Expected weeks 4–5 · Baby starts to sense sound, light and smell/taste more clearly. Every baby is different; for reference only.)
  - **NEW age card:** [Icon/cake on sunshine-soft] "3 tuần tuổi" (3 weeks old) / "Bé nhìn theo mặt người và nghe giọng quen" (Baby follows faces and hears familiar voices) · ✓ "Nói chuyện, hát nhẹ khi bé thức" (Talk and sing softly while baby is awake) · ✓ "Cho bé nằm sấp vài phút khi có người lớn bên cạnh" (A few minutes of tummy time with an adult nearby) · footer "Hướng dẫn · 2 bài viết · 3 mốc" (Guide · 2 articles · 3 milestones) + Icon/arrow-right
- SectionHeader "Hôm nay" · link "Lịch sử" (History)
- DayRhythm "Đã ghi hôm nay": "Bú bình 2 cữ · 240 ml", "Bú mẹ 1 cữ · 15 phút", "Ngủ (đã xong) 7 giờ 50", "Thay tã 2 lần"; axis 0h/6h/12h/18h/24h; legend Ngủ · Bú bình · Bú mẹ · Tã. The track is the same as in v1.0 (sleep 00:00–06:30 and 11:45–13:05, feeds 08:00 and 14:20, breastfeed 11:30–11:45, diapers 09:10 and 13:40, now 15:05).
- TabDock: NavBar v1.1 [Today active "Hôm nay" · Memories · Family · Utilities(grid)] + QuickLogButton (+)

**Layout / components / tokens**
- Frame 375 × 1480, `cloud #f6fcfb`, border 1 px `separator #dce8e7`, radius 44. Content px 16, pt 4, pb 120. The TabDock sits at y 1386.
- UserAvatar: local pill, `card-peach #ffa58d`, Bold 14, text colour `care-bottle-ink #1d5f99` (odd: blue M on peach; v1.0 had the same).
- CareTile (54:530) with mini 3D art; tile shadow `0 10 22 -4 rgba(18,46,51,.16)` + `0 2 4 rgba(18,46,51,.1)`; edge `card-edge rgba(255,255,255,.85)`. Soft fills: bottle #e5f1fb, breast #fceaf0, sleep #edeefc, diaper #e7f4e3, pump `care/pump/soft #f5eafa`, growth #fdede2. Inks: bottle #1d5f99, breast #a33a5e, sleep #4447a8, diaper #2f6b24, pump #7b3a94, growth #9a4a14.
- ReminderPeek (128:665): white, radius 18, `sunshine-soft #fff4d6` 40 px circle with Icon/clock.
- **Wonder Week card** (local frame, not a component): `care-sleep-soft #edeefc`, radius 20, px 16, py 14, gap 8, no shadow. Pill: white, radius 999, SemiBold 12 `care-sleep-ink #4447a8`. Title Bold 17 and body Medium 13 / 1.45, both `care-sleep-ink`. Chevron 16 px.
- **Age card** (local frame): `surface` white, radius 20, shadow-card, px 16, py 14, gap 10. Icon chip `sunshine-soft #fff4d6` p 8 radius 12 holds Icon/cake 18. Age label Medium 12 `ink-muted #55707a`; headline SemiBold 15 `ink #173d44`. Bullets use Icon/check 14 with Medium 13 / 1.45 `ink-muted`. Footer is SemiBold 13 `mint-text #06716d` with Icon/arrow-right 16.
- SectionHeader (9:140), DayRhythm Filter=All (48:409), TabDock (10:169), QuickLogButton (44:363): component descriptions are unchanged from v1.0 (see 16-v1-improvement.md).
- NavBar v1.1: `nav-bar #173d44` pill, p 6. Active tab is `nav-active` white with `on-nav-active #173d44` Medium 14. Inactive tabs are 52 w, icon 22, with `nav-icon #b9cfcf` on the grid icon.

**Visual:** This is the v1.0 Today screen with a new lavender Wonder Week banner and a white tip card with a cake icon, inserted under the reminder card. The dock now shows a four-square grid icon at the far right in place of the Care hand-heart icon.

**Navigation (all inferred, no prototype links)**
- Wonder Week card / chevron → Wonder Week detail or calendar (not in this cluster).
- Age card / "Hướng dẫn · 2 bài viết · 3 mốc" → 2b Chi tiết giai đoạn (310:42649) for the current stage.
- "Tuỳ chỉnh" → A2. UserAvatar → A4. Utilities tab → utilities hub (not drawn here). Everything else is as in v1.0.

**Notes / not shown**
- No empty, dismissed or "Wonder Week in progress" variant of the Wonder Week card. The "Còn 3 ngày" countdown matches the A2 row "Hiện trước 3 ngày khi sắp tới", so the card appears 3 days before a leap starts (inferred rule).
- Teddy is 3 weeks old and Wonder Week 1 is "Dự kiến tuần 4–5". Weeks are counted from birth; the design does not say whether due date or DOB is the basis (classic Wonder Weeks uses the due date).
- The age card shows 2 bullets. Stage detail 2b has 3 "Ba mẹ có thể thử" items, and these 2 are its first two. The footer claims "3 mốc", but 2b lists 2 milestone rows plus "Xem tất cả" (See all).
- The headline differs between screens: Today says "Bé nhìn theo mặt người **và** nghe giọng quen", list 2a says "Nhìn theo mặt người, nghe giọng quen", and 2b says "Bé nhìn theo mặt người, nghe giọng quen". There are three variants of one stage title.

### 308:40577 — A2 · Tuỳ chỉnh Hôm nay (Customise Today sheet)

**Annotation:** the same A1 annotation, copy-pasted again (nothing specific to the sheet).

**Text (reading order)**
- Background: A1 content (812 tall) under the scrim.
- SheetHeader "Tuỳ chỉnh Hôm nay" (Customise Today) + close
- "Bật, tắt và kéo để sắp xếp những gì hiện trên Hôm nay." (Turn on, turn off and drag to arrange what shows on Today.)
- Rows (drag handle ≡ · title / subtitle · Toggle):
  1. "Ô theo dõi nhanh" / "Bú, ngủ, tã, hút sữa, tăng trưởng" — ON
  2. "Nhắc việc sắp tới" / "3 nhắc đang bật" — ON
  3. **NEW** "Wonder Week" / "Hiện trước 3 ngày khi sắp tới" (Shows 3 days before it starts) — ON
  4. **NEW** "Thẻ theo tuổi" / "Gợi ý theo tuổi của bé" (Suggestions for baby's age) — ON
  5. **NEW** "Ăn dặm hôm nay" (Solids today) / "Bật theo dõi ăn dặm để hiện" (Turn on solids tracking to show this) — **OFF, disabled look** (title and subtitle both `ink-muted`; toggle image is the OFF variant)
  6. "Nhịp trong ngày" / "Biểu đồ 24 giờ" — ON
- "Ô theo dõi hiển thị" (Visible tracking tiles)
- Chips (selected: mint-soft + check): "Bú bình", "Bú mẹ", "Ngủ", "Thay tã", "Hút sữa", "Tăng trưởng"; **NEW unselected chip** "+ Ăn dặm" (white, 1 px `control-border #7e959a`, Icon/plus, `ink-muted` text)
- Buttons: secondary "Đặt lại" (Reset, h 52 `surface-2`) · primary "Xong" (Done, h 56 `mint-deep #087f7b`)

**Layout / components / tokens**
- Scrim `rgba(12,23,25,.32)`. Sheet white, top radius 28, **top y 62** (v1.0: y 286; the sheet is now nearly full height because it has 6 rows), px 16, pb 34, gap 12.
- SheetHeader (37:293), Toggle (23:262) and Button (8:33) descriptions are as in v1.0. Rows are local frames inside a white "Group" (radius 16), row px 14, py 12. The handle is 3 bars, 14 × 2, `ink-muted`. Title SemiBold 15, subtitle Medium 12 / 1.4.
- This frame shows the **unselected chip style** for the first time: white, `control-border` outline, plus icon.

**Visual:** A tall sheet with six drag rows. Five toggles are on (teal) and the greyed "Ăn dặm hôm nay" toggle is off. Below are seven chips, the last an outlined "+ Ăn dặm", then the two buttons.

**Navigation (inferred):** opened from "Tuỳ chỉnh". Toggles show or hide sections, handles reorder them, chips pick tiles, "Đặt lại" resets and "Xong" saves. The "Ăn dặm hôm nay" row probably cannot be toggled until solids tracking is on, via the "+ Ăn dặm" chip or Tuỳ chỉnh theo dõi (inferred from its subtitle).

**Notes / not shown**
- The sheet has 6 rows, but A1 shows only 5 Today sections. With Ăn dặm off, the order A1 draws (tiles · reminders · [WW + age card grouped under "Dành cho bé hôm nay"] · rhythm) matches rows 1, 2, 3+4, 6. **Wonder Week and the age card are separate reorderable rows, yet A1 renders them under one section title.** The design does not say what happens to that title if the user separates them.
- The "Ăn dặm hôm nay" Today card is never drawn anywhere in this cluster.
- Does tapping "+ Ăn dặm" add solids as a tracker for the baby (changing `baby.trackers`) or only show a tile? Not stated.

### 308:40785 — A4 · Tôi (từ avatar) (Me, opened from the avatar)

**Annotation:** none.

**Content is identical to v1.0-improvement 370:1898**: same strings, the same 375 × 812 frame at radius 40, and no dock. Values:
- back button · "Tôi" (Me)
- Profile: avatar "M" (`peach-soft #ffe3da`, SemiBold 28 `on-warm #173d44`) · "Mai" (SemiBold 24) · "mai.nguyen@gmail.com" · "Mẹ · chủ hồ sơ của Teddy, Na" (Mum · profile owner of Teddy, Na) · chevron
- Storage card (white, radius 20, shadow-tile): "Dung lượng" (Storage) · "3,2 GB / 10 GB". Bar on `separator`: `mint-deep` 74.64 px + `peach #ffa58d` 24.88 px. Legend "● Teddy 2,4 GB" (`mint-text`) and "● Na 0,8 GB" (`on-warm`). "Dùng chung cho tất cả các bé của bạn" (Shared across all your babies)
- Group 1: [cake] "Hồ sơ các bé" / "Teddy, Na" · "2" · › ; [today/sun] "Thông báo" · "Bật" · › ; [globe] "Giao diện" · "Tự động" · ›
- Group 2: [link] "Đã chia sẻ ra ngoài" / "2 liên kết đang mở" · › ; [lock] "Tài khoản & đăng nhập" / "Email, Apple, đổi máy" · › ; [mail] "Trợ giúp & liên hệ" · ›
- Card: "Đăng xuất" (Sign out), SemiBold 14 `error #a12b32`

**Layer name ≠ text:** the row frame is "Các bé của bạn" (Your babies), but the rendered title is "Hồ sơ các bé".
**Visual:** unchanged from v1.0.
**Navigation (inferred):** back → Today; rows → their sub-screens, as in v1.0.
**Notes:** v1.1 adds nothing to Me. There is no row for bookmarks or saved articles (2b has a bookmark button), language, Wonder Week or content preferences, or solids. The Thông báo row still uses the sun icon. R-123 already covers this screen.

### 315:43767 — A5 · Hôm nay · người chăm (Today, caregiver) — diff against A1

**Annotation:** the same as A1 (copy-pasted).

Frame 375 × 1288 (A1 is 1480). TabDock at y 1194. Differences from A1:
1. **UserAvatar "L"** on `care-diaper-soft #e7f4e3`; the text is still `care-bottle-ink`. This is caregiver Cô Lan.
2. **"Dành cho bé hôm nay" holds only the Wonder Week card.** The **age card ("Thẻ theo tuổi") is absent** for the caregiver.
3. **Dock: Today (active) · Family · Utilities.** No Memories tab, consistent with the v1.0 caregiver rule.
4. Everything else is identical to A1: the header, "Teddy · 3 tuần", the night toggle, the date, "Tuỳ chỉnh", all **6 tiles including Tăng trưởng** and Hút sữa, ReminderPeek "Nhắc việc · 3 / Tiêm 6 trong 1", and DayRhythm.

**Notes / inconsistencies**
- In v1.0-improvement the caregiver's Care tab had **no Tăng trưởng tile** and the reminder line read "2 nhắc giao cho bạn". Here the caregiver's Today shows a Growth tile and "Nhắc việc · 3" (not the assigned-to-you count). Either this is copy-paste from A1 or caregivers see growth on Today; owner to confirm.
- Why the caregiver sees Wonder Week but not the age card is not explained. A role rule may exist (age cards for parents only?) or the omission may be accidental.
- The caregiver still has "Tuỳ chỉnh". Whether their customise sheet lists Thẻ theo tuổi is not drawn.

### 315:44134 — A7 · Hôm nay · Night care (Today, Night care theme) — diff against A1

**Annotation:** the same as A1 (copy-pasted).

**Content is identical to A1** (all strings, both new cards, and the dock with Memories and Utilities). Frame 375 × 1480, TabDock at y 1386. Only the tokens change (Night care values):

| Token | Light (A1) | Night (A7) |
|---|---|---|
| cloud (page) | #f6fcfb | #0c1719 |
| separator (frame border) | #dce8e7 | #26393e |
| surface | white | #15242a |
| surface-2 | #eef6f5 | #1c2e33 |
| ink | #173d44 | #e6f2f1 |
| ink-muted | #55707a | #9db3b4 |
| mint-text | #06716d | #3fd0c3 |
| mint-deep (QuickLog) | #087f7b | #3fd0c3 |
| card-peach (avatar) | #ffa58d | #3a2620 |
| sunshine-soft | #fff4d6 | #3a3115 |
| care-bottle soft / ink / accent | #e5f1fb / #1d5f99 / #3b8fd9 | #16314a / #9ccbf5 / #5aa6e8 |
| care-breast soft / ink / accent | #fceaf0 / #a33a5e / #e07a9a | #3a1f2a / #f5b3c8 / #e88aa8 |
| care-sleep soft / ink / accent | #edeefc / #4447a8 / #6c6fd8 | #23244a / #bdbff7 / #8a8deb |
| care-diaper soft / ink / accent | #e7f4e3 / #2f6b24 / #5daa4e | #1e3320 / #a8da9c / #74bf63 |
| care/pump soft / ink | #f5eafa / #7b3a94 | #33203d / #e2b8f2 |
| care-growth soft / ink | #fdede2 / #9a4a14 | #3a2617 / #f7c29a |
| card-edge | rgba(255,255,255,.85) | rgba(255,255,255,.06) |
| nav-bar | #173d44 | #1c2e33 |
| nav-active / on-nav-active | white / #173d44 | #3fd0c3 / #062a2c |
| nav-icon | #b9cfcf | #9db3b4 |
| tile shadow | rgba(18,46,51,.16/.10) | "Night care/shadow-tile": #00000073 0/10/24 −4 + #00000059 0/2/4 |

- The Wonder Week card uses the Night `care-sleep-soft #23244a` with `care-sleep-ink #bdbff7`. The age card is `surface #15242a`, its icon chip is `sunshine-soft #3a3115`, and its footer is `mint-text #3fd0c3`.
- **Artefacts:** ReminderPeek, the age card and DayRhythm keep the Light drop-shadow `rgba(23,61,68,…)`, which is barely visible on dark. The Night care toggle still shows the same moon icon on `surface-2`, with no "on" state indication.
- The mini 3D art is the same SVG (fixed colours, as the description says). The BabyFace and some icons use Night-specific asset ids (re-tinted strokes).

---

### Cluster "Label · 2 · Thẻ theo tuổi (nội dung từ portal)" (y 1750)
(Age cards, with content from the portal.) The cluster label itself says the content comes **from the portal**: editorial content managed in an admin portal.

### 310:42550 — 2a · Thẻ theo tuổi (Age cards, stage list)

**Annotation:** none.

**Text (reading order)**
- StatusBar · back button · spacer · BabySwitcher "Teddy" + chevron
- Title (Bold 28): "Thẻ theo tuổi" (Age cards)
- "Gợi ý ngắn theo từng giai đoạn, được soạn và rà soát bởi đội chuyên môn." (Short suggestions for each stage, written and reviewed by the expert team.)
- Stage rows (photo 52 × 52 · age range · title · chevron):
  1. "0–2 tuần" / "Làm quen với thế giới mới" (Getting to know the new world). **Past stage:** the title is in `ink-muted`.
  2. "3–4 tuần" + pill **"Bé đang ở đây"** (Baby is here) / "Nhìn theo mặt người, nghe giọng quen" (Follows faces, hears familiar voices). **Current stage:** highlighted.
  3. "1–2 tháng" / "Nụ cười đầu tiên đáp lại ba mẹ" (First smile in response to parents)
  4. "2–3 tháng" / "Giữ đầu vững hơn khi nằm sấp" (Holds head steadier during tummy time)
  5. "3–4 tháng" / "Với tay, nắm đồ chơi" (Reaches for and grasps toys)

**Layout / components / tokens**
- Frame 375 × 812, `cloud`, radius 40, no dock (pushed screen). Content pt 52, px 16, gap 14.
- Stage row (local frame "Stage · <range>"): white, 1 px `separator`, radius 18, p 14, gap 12. **Current stage:** `sunshine-soft #fff4d6` fill with a 1.5 px `sunshine #ffd166` border. Its "Bé đang ở đây" pill is white radius 999, SemiBold 11 `ink`.
- Range SemiBold 12 `ink-muted`; title SemiBold 15 `ink` (past: `ink-muted`).
- Photo: 52 px, radius 14, `surface-2`, holding **Illustration/Photo (131:758): "Illustrated baby photo placeholder (privacy-safe). Use instead of real photos in mockups."** The instances alternate blue gradient (#dcebfa → #a9cbef) and peach gradient (#ffe3d8 → #f7b9a5) backgrounds with PNG photos of a baby.

**Visual:** A simple vertical list of five rounded white rows, each with a small baby photo thumbnail. The current stage, 3–4 tuần, glows yellow with a "Bé đang ở đây" tag. The first row looks faded.

**Navigation (inferred):** back → Today or the Utilities hub. Row → 2b for that stage. BabySwitcher → switch baby, which recomputes the current stage.

**Notes / not shown**
- The list stops at "3–4 tháng". Whether it continues (scroll, or to 12 or 24 months and beyond) is not shown. Stage granularity is irregular: 0–2 weeks, 3–4 weeks, then monthly.
- Future stages are drawn as tappable (chevron, normal ink), so the user can read ahead (inferred).
- No Night variant, loading, empty (no stages published) or offline state is drawn here (offline appears in 2c).

### 310:42649 — 2b · Chi tiết giai đoạn (Stage detail)

**Annotation:** none.

**Text (reading order)**
- back button · spacer · bookmark button (Icon/bookmark, white circle)
- Hero photo (343 × 180, radius 24, Illustration/Photo cropped)
- Chips: "3–4 tuần" (`sunshine-soft`) · "Teddy · 3 tuần" (`surface-2`)
- Title (Bold 26 / 1.25): "Bé nhìn theo mặt người, nghe giọng quen" (Baby follows faces, hears familiar voices)
- Card "Bé đang thế nào" (How baby is doing; Bold 17), bullets with Icon/eye:
  - "Nhìn rõ nhất ở khoảng cách 20–30 cm" (Sees best at 20–30 cm)
  - "Quay về phía giọng nói quen thuộc" (Turns towards familiar voices)
  - "Giờ thức dài hơn một chút" (Awake periods a little longer)
- Card "Ba mẹ có thể thử" (Parents can try), bullets with Icon/heart:
  - "Nói chuyện, hát nhẹ khi bé thức"
  - "Cho bé nằm sấp vài phút khi có người lớn bên cạnh"
  - "Để bé nhìn mặt bạn thật gần" (Let baby look at your face up close)
- Section "Mốc thường gặp" (Common milestones) + link "Xem tất cả" (See all)
  - [Icon/star on mint-soft] "Nhìn theo mặt người" / "Tham khảo: 0–2 tháng" (Reference: 0–2 months) · pill **"Đã ghi"** (Recorded; mint-soft, mint-text)
  - [Icon/star on peach-soft] "Mỉm cười đáp lại" (Smiles back) / "Tham khảo: 1–3 tháng" · pill **"+ Ghi mốc"** (Record milestone; surface-2, Icon/plus 12)
- Section "Bài viết liên quan" (Related articles)
  - [photo 56] "Nằm sấp: bắt đầu thế nào cho nhẹ nhàng" (Tummy time: how to start gently) / "Phát triển · 4 phút đọc" (Development · 4 min read) · ›
  - [photo 56] "Giấc ngủ của bé sơ sinh" (Newborn sleep) / "Giấc ngủ · 6 phút đọc" (Sleep · 6 min read) · ›
- Footnote (Medium 12 `ink-muted`): "Nội dung do đội chuyên môn Child Life soạn và rà soát · Cập nhật 09/2026. Mỗi bé phát triển theo nhịp riêng." (Content written and reviewed by the Child Life expert team · Updated 09/2026. Every baby develops at their own pace.)

**Layout / components / tokens**
- Frame 375 × 1312, `cloud`, radius 40, no dock. Content pt 52, px 16, gap 16.
- Content cards: white, radius 20, shadow-card, px 16, py 14, gap 10. Bullet icon 16 (`Icon/eye` 22:153, `Icon/heart` 7:19) with Medium 14 / 1.5 `ink`.
- Milestone rows and article rows sit in white groups at radius 16, row px 14, py 12. The milestone icon chip is p 8, radius 12, with tints alternating `mint-soft #e6f7f5` / `peach-soft #ffe3da` and Icon/star (22:194).
- Article thumbnails are 56 px, radius 12, Illustration/Photo on teal (#cfefea → #8fd6cb) and lilac (#ede3f8 → #c8b1e8) gradients.
- Section headers are Bold 17 `ink`; the link is SemiBold 14 `mint-text`.

**Visual:** A magazine-style detail page. A large baby photo sits at the top, followed by stage and age chips, a big headline, and two white tip cards (eye icons, heart icons). A milestone list shows one "Đã ghi" tag and one "+ Ghi mốc" button. Then come two article rows with thumbnails and a small provenance footnote.

**Navigation (inferred)**
- back → 2a or Today. Bookmark → save this stage card (no saved-items screen exists anywhere in this cluster).
- "Xem tất cả" → milestone list (Mốc phát triển feature, not in this cluster).
- "+ Ghi mốc" → record-milestone flow (per baby; probably a sheet with date, maybe photo and note, inferred). "Đã ghi" → view the recorded milestone.
- Article row → article reader (Thư viện chăm bé, not in this cluster).

**Notes / not shown**
- **Milestone reference windows are wider than the stage.** The 3–4 week stage links milestones with "Tham khảo: 0–2 tháng" and "1–3 tháng". Milestones are therefore separate catalog items linked to stages, not owned by them.
- **"Đã ghi" on "Nhìn theo mặt người"** means Teddy already has this milestone recorded: per-baby milestone data exists in the mock.
- The Today card says "3 mốc" but only 2 milestones are listed here.
- "Cập nhật 09/2026" means content carries a last-reviewed date. "Đội chuyên môn Child Life" is a reviewer claim (ties to Q-039).
- No Night variant. There is no share action, and no list of sources or references (only the team attribution).

### 310:42762 — 2c · Thiếu ngày sinh (Missing date of birth, plus offline banner)

**Annotation:** none.

**Text (reading order)**
- Header: UserAvatar "M" · BabySwitcher "Teddy" (no age, because the DOB is unknown) · spacer · white round button with **Icon/today (sun)**, 18 px
- Title (Bold 32): "Hôm nay"
- Card "Thẻ theo tuổi · thiếu ngày sinh": [Icon/cake on sunshine-soft] **"Thêm ngày sinh của bé"** (Add baby's date of birth) · "Để Child Life gợi ý đúng theo tuổi, nhắc Wonder Week và mốc phát triển." (So Child Life can suggest by age, remind about Wonder Weeks and milestones.) · tinted Button "Thêm ngày sinh" (Add date of birth; h 56, `mint-soft` fill, `mint-text`)
- Banner (`surface-2`, radius 14, Icon/cloud-off 16): "Không có kết nối. Thẻ theo tuổi đang hiện bản đã lưu trên máy." (No connection. Age cards are showing the copy saved on this device.)
- TabDock: NavBar v1.1 (Today active · Memories · Family · Utilities) + QuickLogButton

**Layout / components / tokens**
- Frame 375 × 812, `cloud`, radius 40 (A1 is 44 with a border), pt 52, gap 14. This Today layout is simplified: no date line, no "Tuỳ chỉnh", no tiles, no reminder, no DayRhythm.
- Card: white, radius 20, shadow-card, px 16, py 14, gap 10. Title Bold 16, body Medium 14 / 1.45 `ink-muted`. The button is the Button (8:33) "Tinted" variant.
- Banner: Medium 13 / 1.45 `ink-muted`.
- Header style differs from A1. The night button is white with a sun icon 18 px (A1: `surface-2` 44 px with a moon), the same inconsistency v1.0 had between Today and Care. The BabySwitcher shows "Teddy" with no age.

**Visual:** A nearly empty Today screen. One white prompt card with a cake icon and a big pale-mint "Thêm ngày sinh" button, then a grey offline note with a crossed-out cloud icon.

**Navigation (inferred):** "Thêm ngày sinh" → edit baby profile, DOB field (or a DOB sheet; the SheetHeader default title "Ngày sinh" exists in the library). After saving, the Today age card and Wonder Week appear.

**Notes / not shown**
- **This frame combines two states**: missing DOB and offline with cached age cards. Each probably applies independently (inferred). Offline with a known DOB is not drawn.
- **The current app requires a DOB**: `createBabyRequestSchema.dateOfBirth: z.iso.date()` (packages/contracts/src/baby.ts:93). A baby without a DOB therefore cannot be created today, so either DOB becomes optional in v1.1 (pregnancy or "not yet born", imports, invitee-created babies?) or this state is defensive. Owner to confirm.
- The offline banner confirms that **age-card content is cached on the device** for offline reading.
- Where the rest of Today (tiles etc.) went in this frame is unexplained. It is probably cropped to focus on the card (inferred), not a real "no DOB → no tiles" rule.

---

#### Data model implied

**Per baby (user data)**
| Field | Type | Example from design |
|---|---|---|
| baby.nickname | string | "Teddy", "Na" |
| baby.dateOfBirth | date, **optional per 2c** (required today) | implied 17/9/2026 ("3 tuần" on 8/10) |
| baby.ageLabel (derived) | string | "3 tuần", "3 tuần tuổi", "Teddy · 3 tuần" |
| baby.currentStageId (derived from DOB) | ref → AgeStage | the "3–4 tuần" stage, "Bé đang ở đây" |
| baby.trackers | enum[] (+ **solids**, new) | bottle, breast, sleep, diaper, pump, growth; solids off |
| milestoneRecord (per baby) | { milestoneId, date?, note?, photo?, recordedBy } | "Nhìn theo mặt người" → "Đã ghi" |
| nextWonderWeek (derived) | { leapNumber, startWeek, endWeek, daysUntil } | 1, 4, 5, "Còn 3 ngày" |

**Per user (or per user and baby) preferences**
| Field | Type | Example |
|---|---|---|
| todayLayout.sections | ordered list of {id, visible} | quickTiles ✓, reminders ✓, wonderWeek ✓, ageCard ✓, solidsToday ✗, dayRhythm ✓ |
| todayLayout.tiles | set of tracker kinds | 6 selected, solids not selected |
| bookmarks | list of {type: stage/article, id} | bookmark icon on 2b |

**Editorial (portal)**
| Entity | Fields (from the UI) | Example |
|---|---|---|
| AgeStage | id, ageFrom/ageTo (weeks or months), rangeLabel ("3–4 tuần"), title (list form), headline (detail form), shortHeadline for Today?, heroImage, thumbImage, "Bé đang thế nào" bullets[] (icon eye), "Ba mẹ có thể thử" bullets[] (icon heart), todayTips[] (subset, 2), linkedMilestoneIds[], linkedArticleIds[], reviewedBy ("đội chuyên môn Child Life"), updatedAt ("09/2026"), locale (vi/en), status | 5 stages drawn: 0–2 tuần … 3–4 tháng |
| Milestone | id, title ("Mỉm cười đáp lại"), referenceWindow ("1–3 tháng" → min/max months), icon/tint, linked stages | 2 drawn |
| Article | id, title, category ("Phát triển", "Giấc ngủ"), readMinutes (4, 6), thumbnail, body (not drawn) | 2 drawn |
| WonderWeek (leap) | leapNumber (1), expectedWeekFrom/To (4–5), summary ("Bé bắt đầu cảm nhận rõ hơn âm thanh, ánh sáng, mùi vị."), disclaimer ("Mỗi bé mỗi khác, chỉ để tham khảo."), showDaysBefore (3, maybe config) | WW 1 |

Counts in the Today card footer ("2 bài viết · 3 mốc") are derived from the stage's links.

#### Static vs per-baby vs editorial
- **Static app copy (ARB):** "Dành cho bé hôm nay", "Còn {n} ngày", "Wonder Week {n} sắp bắt đầu" (template), "Dự kiến tuần {a}–{b}" (template), "Hướng dẫn · {n} bài viết · {m} mốc", "{n} tuần tuổi", "Thẻ theo tuổi", the 2a intro line (arguably editorial), "Bé đang ở đây", "Bé đang thế nào", "Ba mẹ có thể thử", "Mốc thường gặp", "Xem tất cả", "Tham khảo: {range}", "Đã ghi", "Ghi mốc", "Bài viết liên quan", "{n} phút đọc", the 2c prompt, "Thêm ngày sinh", the offline banner, all the A2 rows and subtitles, "+ Ăn dặm", and all of A4.
- **Per-baby data:** age, current stage, days until the next leap, milestone "Đã ghi" status, tracker set (solids), the tiles' values, reminders, DayRhythm, storage per baby.
- **Editorial (portal):** stage titles and headlines, the bullets in both cards, the Today tips, stage images, milestone names and reference windows, article titles, categories, read times and thumbnails, the Wonder Week summary text and week windows, "Cập nhật 09/2026" and the reviewer line. The WW disclaimer and the footnote's "Mỗi bé phát triển theo nhịp riêng" could be static or editorial.

#### Admin-portal candidates
- **Age stages:** list with ordering, age window (from/to in days, weeks or months; mixed granularity), list title, detail headline, optional Today short headline, bullets "Bé đang thế nào" and "Ba mẹ có thể thử" (ordered; flag which go on Today, 2 shown), hero and thumbnail images, linked milestones and articles (ordered), vi/en locale pair (D-012), review workflow (draft → reviewed by expert → published, plus reviewer name and "updatedAt" shown as "Cập nhật MM/YYYY"), and whether the stage is published.
- **Milestones catalog:** title, reference window (min to max months), icon or tint, category, linked stages, ordering, locale, review.
- **Articles (Thư viện chăm bé):** title, category (Phát triển, Giấc ngủ, …), read time (computed or manual), thumbnail, body, sources, reviewer, updatedAt, locale, related stages.
- **Wonder Weeks / leaps:** number, expected week window, summary text, disclaimer, lead time ("Hiện trước 3 ngày" could be a `config/limits` value), locale, review.
- **Images:** a media library for stage heroes, thumbnails and article images. The design uses real-looking baby photos, so licensing and consent are needed.
- **Offline:** content must be versioned so the app can cache it ("bản đã lưu trên máy") and refresh.

#### Images and illustrations used
- **Illustration/Photo (131:758)** "Illustrated baby photo placeholder (privacy-safe)": 2a thumbnails (52 px), the 2b hero (343 × 180, cropped) and article thumbnails (56 px). The PNGs are **photographic** baby images on pastel gradient frames (blue #dcebfa → #a9cbef, peach #ffe3d8 → #f7b9a5, teal #cfefea → #8fd6cb, lilac #ede3f8 → #c8b1e8). In production these are **editorial photos** supplied by the portal.
- **Illustration/BabyFace (25:323)** in the BabySwitcher. **Illustration/Mini/** Bottle, Drop, Moon, Diaper, Pump and Ruler on the CareTiles (fixed-colour 3D objects).
- Icons: Icon/cake (age card, 2c), Icon/check (Today tips, chips), Icon/arrow-right, Icon/chevron-right, Icon/eye, Icon/heart, Icon/star (milestones), Icon/plus ("Ghi mốc", "+ Ăn dặm"), Icon/bookmark (new usage), Icon/cloud-off, Icon/grid (new Utilities tab), Icon/today, Icon/sleep, Icon/sliders, Icon/clock, and Icon/globe, link, lock and mail (Tôi).
- The Wonder Week card has no illustration, only the `care-sleep` lavender tint. No emoji.

#### Open questions / gaps
1. **Tab model:** NavBar v1.1 shows Today · Memories · Family · **Utilities (grid)**. Is "Chăm sóc" renamed "Tiện ích" and moved last, and what is its label? This conflicts with the current `ClTab { today, memories, care, family }` and with v1.0-improvement.
2. **The caregiver Today (A5)** omits the age card but keeps Wonder Week, all 6 tiles including Growth, and "Nhắc việc · 3". Is this a deliberate role rule (age cards for parents only? caregivers see growth?) or copy-paste?
3. **DOB optional?** 2c requires babies without a DOB, but the contract requires `dateOfBirth`. When can a DOB be missing?
4. **Wonder Week basis:** is it counted from DOB or the due date? Teddy is 3 weeks old and the card says "Dự kiến tuần 4–5". Is the lead time ("Hiện trước 3 ngày") fixed or configurable? No in-progress, after-leap or dismissed card states are drawn, and the Wonder Week detail screen is not in this cluster.
5. **Solids ("Ăn dặm"):** this is a new tracker kind and a "Ăn dặm hôm nay" Today section, but the section's card is not drawn here. Does "+ Ăn dặm" change `baby.trackers` (affecting the whole family) or only the user's Today?
6. **Today layout scope:** is it per user, per baby or per device (open since v1.0)? Wonder Week and age card are separate reorderable rows but render under one "Dành cho bé hôm nay" header. What is the header rule when they are apart or one is hidden?
7. **Copy drift:** one stage has three headline variants (Today, 2a, 2b). Does the portal hold one headline or several? Today's "3 mốc" does not match the 2 milestones in 2b.
8. **Stage range and granularity:** 2a stops at 3–4 tháng. What is the full range (12 months, 24, or beyond, per the landing's Chặng 2–4)?
9. **Milestone recording flow** ("+ Ghi mốc"), the "Xem tất cả" milestone list, the article reader, and **bookmarks** (where saved items live; there is no Tôi row) are all undesigned in this cluster.
10. **Expert review claim** ("được soạn và rà soát bởi đội chuyên môn", "Cập nhật 09/2026"): who the reviewers are and whether sources are shown. This ties to Q-039.
11. **Night care:** there are no Night frames for 2a–2c. In A7 several cards keep Light shadows, and the night toggle has no active state.
12. **Header inconsistency persists:** A1, A5 and A7 use a moon on `surface-2` 44 px; 2c uses a sun on white 18 px. 2c also lacks the date line and "Tuỳ chỉnh".
13. **Images:** the stage and article photos look like real baby photos. Image rights and consent for editorial images are needed (and the placeholder description says "privacy-safe" illustrations).

#### Coverage
8/8 frames read with one `get_design_context` each: 308:18, 308:40577, 308:40785, 315:43767, 315:44134, 310:42550, 310:42649, 310:42762. No call failed and no rate limit was hit. The 308:40577 response was truncated after the screenshot (the code was complete). All 8 screenshots were saved under `docs/discovery/figma-extract/img/v11/`.

---

## Part B: Mốc phát triển (3a–3g) and Wonder Week (6a–6f), extracted from the final Figma

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only), page **"v1.1"**, clusters **"Label · 3 · Mốc phát triển"** (row y 3500) and **"Label · 6 · Wonder Week (nội dung từ portal)"** (row y 8000). Read 2026-10-12. Only `get_design_context` was called, once per frame (13 calls, sequential). No Figma node was modified.

**How it was read**
- Strings are the rendered text from `get_design_context`, never layer names. Where a layer name differs from the rendered text, it is flagged.
- **Prototype links:** none of the 13 frames contain an `<a … cursor-pointer>` node, so **no prototype interaction is wired** in either cluster. Every navigation below is **(inferred)** from copy and frame order.
- **Annotations:** no `data-annotation` on any frame.
- Screenshots: `docs/discovery/figma-extract/img/v11/<node-id with : → ->.png` (13 files: `311-1184`, `311-1308`, `311-1364`, `311-1436`, `311-41672`, `311-41752`, `311-41795`, `315-2506`, `315-2566`, `315-2684`, `315-2804`, `315-2833`, `315-2972`).
- **Night care:** no Night variant drawn. All app frames are Light (`cloud #f6fcfb`). 6d is an iOS lock screen.

**Mock scenario**
- Baby **Teddy**, **born 17/09/2026** (6a: "Teddy sinh 17/09/2026 · sớm 4 ngày"), **due date 21/09/2026**. This matches the vaccination cluster (`17-vaccination.md`).
- "Today" is **Thursday 08/10/2026** in 3c–3f, 6b, 6c and 6d (6b: "Còn 3 ngày" before 11/10; 6d lock screen "Thứ Năm, 8 tháng 10"). In 6e and 6f it is **Monday 12/10/2026**.
- Family: **Mẹ** (the user; "Bạn"), **"Ba Tuấn"**, a parent named **"Mai"** (3e "Chỉ bố mẹ · Mai, Ba Tuấn", so Mẹ = Mai, inferred), plus ông bà and cô chú who have been invited.
- **Age inconsistency:** 3d–3f say "lúc Teddy **3 tuần 4 ngày**" on 08/10/2026. From DOB 17/09 that is 21 days, so **3 tuần 0 ngày**. "3 tuần 4 ngày" would need DOB 13/09. From the due date 21/09 it is 17 days (2 tuần 3 ngày). Neither basis gives the drawn value.
- Weekday checks: Thứ Năm 08/10/2026 ✓, Chủ Nhật 04/10/2026 ✓, Thứ Hai 21/09/2026 ✓, Thứ Hai 12/10/2026 ✓, Chủ Nhật 11/10 ✓.

### Frame list
| Cluster | Node | Name | Size (metadata / render) |
|---|---|---|---|
| 3 | 311:1184 | 3a · Mốc phát triển | 375 × 1060 |
| 3 | 311:1308 | 3b · Chi tiết mốc | 375 × 812 |
| 3 | 311:1364 | 3c · Ghi nhận mốc | 375 × 812 (sheet over 3b) |
| 3 | 311:1436 | 3d · Đã lưu mốc | 375 × 812 |
| 3 | 311:41672 | 3e · Tạo kỷ niệm từ mốc | 375 × 812 (sheet over 3d) |
| 3 | 311:41752 | 3f · Mốc đã gắn kỷ niệm | 375 × 812 |
| 3 | 311:41795 | 3g · Tạo mốc riêng | 375 × 812 |
| 6 | 315:2506 | 6a · Wonder Week · thiết lập | 375 × 812 |
| 6 | 315:2566 | 6b · Lịch dự kiến | 375 × 1250 |
| 6 | 315:2684 | 6c · Chi tiết giai đoạn | 375 × 1218 |
| 6 | 315:2804 | 6d · Thông báo trước 3 ngày | 375 × 812 |
| 6 | 315:2833 | 6e · Ghi biểu hiện thực tế | 375 × 812 (sheet over 6c) |
| 6 | 315:2972 | 6f · Ghi chép của nhà mình | 375 × 812 |

### Shared chrome (both clusters)
- **StatusBar** (11:135: "Placeholder iOS status bar for screen mockups.") "9:41" / "•••".
- **Top row:** a round white `back` button (`surface`, p 8, radius 999, Icon/back 20 px), a spacer and **BabySwitcher** "Teddy" (45:321: "Baby switcher chip: avatar + name (+ chevron when the family has more than one baby). Shows whose log you are viewing."; `surface-2 #eef6f5`, pl 4 / pr 12 / py 4, Illustration/BabyFace 32 px (25:323 "Small baby avatar for headers."), Medium 16 `ink`, 16 px chevron). In 3g the button holds **Icon/close** instead of back (the layer is still named "back").
- **Page:** `cloud #f6fcfb`, frame radius 40; content pt 52, px 16, pb 120, gap 14.
- **Title:** Bold 28 `ink #173d44`.
- **Section header:** Bold 17 `ink` + spacer.
- **List group:** white `surface`, radius 16, rows px 14 / py 12, gap 12. Icon chip: p 8, radius 12, 18 px icon, on a *soft* tint. Title SemiBold 15 `ink`. Subline Medium 12/1.4 `ink-muted #55707a`. Optional trailing chevron (16 px).
- **Content card:** white, radius 20, px 16 / py 14, drop shadow 0/8/12 rgba(23,61,68,.08) + 0/1/1 .06 (`shadow-card`: #173D440F 0/1/2 + #173D4414 0/8/24). Header Bold 16 `ink`, body Medium 14/1.55 `ink`.
- **Chip:** radius 999, px 12 / py 6, SemiBold 13. Filter chip selected: `ink` background, white text. Unselected: white with 1 px `separator #dce8e7`.
- **Field:** label SemiBold 13 `ink-muted`; box white, 1 px `control-border #7e959a`, radius 14, px 14 / py 13, Medium 15/1.45 `ink`. The date box has Icon/cake 18 px and Icon/chevron-down 16 px.
- **Dashed add tile:** 1 px dashed `control-border`, radius 16 (rows) / 14 (photo slot 76 × 76, Icon/camera 18 px), with Icon/plus 16 px and SemiBold 15 `mint-text #06716d`.
- **Button** (8:33; description quoted in `19-spending.md`): primary h56 `mint-deep #087f7b` / `on-mint-deep` white, Medium 17 (Text/body-strong 17/24). Plain variant h44 with `mint-text`. Several labels break the "1–2-word verb" rule: "Đánh dấu đã quan sát", "Lưu để theo dõi", "Xem lịch dự kiến", "Ghi lại biểu hiện của bé", "Lưu ghi chép".
- **Sheet** (3c, 3e, 6e): `scrim rgba(12,23,25,0.32)` over the parent frame. White sheet, top radius 28, px 16, pb 34, gap 12–14. **SheetHeader** (37:293: "Bottom-sheet header: grabber, title (24/32 semibold), close (44px, label "Đóng").").
- **Toggle** (23:262: "iOS switch. On: mint-deep track. Off: separator track. White knob.").
- **Icons:** Icon/back, close, spark, check, star, heart, chevron-right, chevron-down, ruler, family, plus, cake, camera and alert. All carry "Line icon (24px, 1.8 stroke) — placeholder drawing; production uses SF Symbols. Recolour by overriding the stroke with a text-colour token." (star, ruler, cake and camera have the shorter "… placeholder; production uses SF Symbols.").
- **Illustration/Photo** (131:758: "Illustrated baby photo placeholder (privacy-safe). Use instead of real photos in mockups."). Tones seen: Peach (gradient #FFE3D8→#F7B9A5), Sun (#FFF1C9→#F9D77E), Mint (#CFEFEA→#8FD6CB, 3g) and Lavender (#EDE3F8→#C8B1E8, 6a).
- **No TabDock** on any frame (all are pushed screens).

---

## Cluster 3 · Mốc phát triển (Milestones)

### 311:1184 — 3a · Mốc phát triển (Milestones list)
**Annotation:** none.

**Text (reading order)**
- Top: back · BabySwitcher "Teddy".
- Title: "Mốc phát triển" (Developmental milestones)
- Summary card (`peach-soft #ffe3da`, radius 20, px 16 / py 14). Photo 56 px (radius 16, Illustration/Photo Peach). "Teddy đã có 2 mốc" (Teddy has 2 milestones; Bold 17). "Ghi lại khi bạn thấy bé làm được. Mỗi bé có nhịp riêng." (Record it when you see baby do it. Every baby has their own pace.; Medium 13/1.45 muted).
- Filter chips (horizontal, overflow off the right edge, so it scrolls, inferred): **"Tất cả"** (All; selected) · "Vận động" (Motor) · "Giao tiếp" (Communication) · "Nhận thức" (Cognitive) · "Cảm xúc – xã hội" (Social-emotional) · "Mốc riêng" (Own milestones).
- Section "Đã quan sát" (Observed):
  1. Icon/spark on `care-sleep-soft #edeefc` · "Nhìn theo mặt người" (Follows faces) / "Nhận thức" · badge ✓ "05/10" (`mint-soft #e6f7f5`, Icon/check 12, SemiBold 12 `mint-text`)
  2. Icon/star on `sunshine-soft #fff4d6` · "Lần đầu tắm cùng ba" (First bath with Dad) / "Mốc riêng" · badge ✓ "01/10"
- Section "Gợi ý quanh tuổi của bé" (Suggestions around baby's age). Rows have a chevron and no date:
  1. Icon/heart on `peach-soft` · "Mỉm cười đáp lại" (Social smile) / "Giao tiếp · tham khảo 1–3 tháng" (Communication · reference 1–3 months)
  2. Icon/ruler on `care-growth-soft #fdede2` · "Giữ đầu khi nằm sấp" (Holds head up on tummy) / "Vận động · tham khảo 1–4 tháng"
  3. Icon/heart on `peach-soft` · "Ê a, tạo âm thanh" (Coos, makes sounds) / "Giao tiếp · tham khảo 2–4 tháng"
  4. Icon/family on `mint-soft` · "Nhận ra giọng ba mẹ" (Recognises parents' voices) / "Cảm xúc – xã hội · tham khảo 0–3 tháng"
- Dashed button: "+ Tạo mốc riêng" (Create own milestone).

**Layout / tokens:** described under Shared chrome. Group colour mapping (inferred from the rows): Giao tiếp = peach-soft + heart; Vận động = care-growth-soft + ruler; Nhận thức = care-sleep-soft + spark; Cảm xúc – xã hội = mint-soft + family; Mốc riêng = sunshine-soft + star.

**Visual:** a soft peach summary card with a baby photo heads two white list groups. Observed rows end in mint date pills, and suggestions end in chevrons. A dashed "create" tile sits at the bottom with a lot of empty space below it.

**Navigation (inferred):** suggestion row → 3b. "Tạo mốc riêng" → 3g. Observed row → 3d/3f. Filter chips filter both sections. Entry point: the "Mốc phát triển" tile on the Care tab, which is "Sớm ra mắt" in `16-v1-improvement.md` / `19-spending.md` 8a.

**Notes / not shown**
- "Mỗi bé có nhịp riêng" plus "tham khảo" ranges match B07's note that the app does not judge early or late.
- Not drawn: an empty state (0 milestones); whether **upcoming/older** reference milestones outside the age window are reachable (only 4 suggestions are shown, with no "Xem tất cả"); a filtered state; Night care; a caregiver or relative view; deleting or editing an observed milestone.
- The observed row badge shows the date only (no year, no age).

### 311:1308 — 3b · Chi tiết mốc (Milestone detail)
**Annotation:** none.

**Text (reading order)**
- Top: back · BabySwitcher.
- Hero photo 343 × 170, radius 24 (Illustration/Photo Peach). This is **editorial**: one illustration per reference milestone (B08 "illustration").
- Chips: "Giao tiếp" (`peach-soft` bg, **`care-bottle-ink #1d5f99`** text, an unusual pairing) · "Tham khảo 1–3 tháng" (Reference 1–3 months; `surface-2`, `ink`).
- Title (Bold 28): "Mỉm cười đáp lại"
- Card "Cách nhận biết" (How to recognise it): "Bé cười khi nhìn thấy mặt bạn hoặc nghe bạn nói chuyện — không phải nụ cười lúc đang ngủ. Thường đi kèm ánh mắt nhìn thẳng và tay chân cử động." (Baby smiles on seeing your face or hearing you talk, not a smile while asleep. Usually with direct eye contact and moving arms and legs.)
- Banner (`surface-2`, radius 14, Icon/heart 16): "Khoảng tuổi chỉ để tham khảo. Mỗi bé có nhịp riêng — nếu bạn băn khoăn, hãy hỏi bác sĩ của bé." (Age ranges are for reference only. Every baby has their own pace. If you are worried, ask your baby's doctor.; Medium 13 muted)
- Primary Button: "Đánh dấu đã quan sát" (Mark as observed)
- Plain Button: "Lưu để theo dõi" (Save to follow)

**Visual:** a large photo header, a category chip and an age-range chip, then a big title, a white explainer card, a grey reassurance banner and two stacked actions.

**Navigation (inferred):** "Đánh dấu đã quan sát" → 3c sheet. "Lưu để theo dõi" → adds it to a watch or bookmark list (no state drawn). Back → 3a.

**Notes / not shown:** "Lưu để theo dõi" implies a third per-baby state (**following / saved**) besides suggested and observed. That state is not drawn in 3a (no "Đang theo dõi" section). No sources or reviewer credit appear on the detail screen, although B08 has expert review and sources.

### 311:1364 — 3c · Ghi nhận mốc (Record a milestone, sheet)
**Annotation:** none.

**Background:** an identical copy of 3b under the scrim.

**Sheet text (reading order)**
- SheetHeader: "Đã quan sát" (Observed) + close.
- Subtitle (SemiBold 15 muted): "Mỉm cười đáp lại"
- Field "Ngày bé làm được" (Date baby did it): Icon/cake · "Thứ Năm, 08/10/2026" · chevron-down.
- Field "Ghi chú" (Note; box h 84): "Bé cười khi mẹ hát bài “Cả nhà thương nhau” sau cữ bú sáng." (Baby smiled when Mum sang "Cả nhà thương nhau" after the morning feed.)
- Label "Ảnh (không bắt buộc)" (Photos (optional)). Two 76 px thumbnails (radius 14; Peach and Sun tones) and a dashed add slot with Icon/camera.
- Primary Button: "Lưu mốc" (Save milestone).

**Visual:** a tall white sheet over the dimmed detail page, with a date picker, a multiline note, a photo strip and a full-width save button.

**Navigation (inferred):** "Lưu mốc" → 3d. Close → 3b. Date box → date picker (not drawn; the range is presumably DOB → today, as in R-103). Camera slot → photo source chooser (as Memories 10a2, inferred).

**Notes / not shown:** no character counter on the note (3g has "14/80 ký tự" for the name only). No maximum photo count. No audience choice: milestone photos are not given a visibility here (see Open questions). No validation for future dates.

### 311:1436 — 3d · Đã lưu mốc (Milestone saved)
**Annotation:** none.

**Text (reading order)**
- Top: back · BabySwitcher.
- Chips: "✓ Đã quan sát" (`mint-soft`, Icon/check 14, SemiBold 13 `mint-text`) · "Giao tiếp" (`peach-soft` / `care-bottle-ink`).
- Title: "Mỉm cười đáp lại"
- Meta (Medium 14 muted): "Thứ Năm, 08/10/2026 · lúc Teddy 3 tuần 4 ngày · Mẹ ghi" (Thu 08/10/2026 · when Teddy was 3 weeks 4 days · recorded by Mum)
- Photos: two 167 × 200 tiles (radius 18; Peach, Sun).
- Note (Medium 15/1.55 `ink`): "Bé cười khi mẹ hát bài “Cả nhà thương nhau” sau cữ bú sáng."
- Card "Create memory" (`peach-soft`, radius 20, p 16). "Giữ khoảnh khắc này trong Kỷ niệm?" (Keep this moment in Memories?; Bold 16). "Tạo kỷ niệm với ảnh và ghi chú này, gắn mốc “Mỉm cười đáp lại”." (Create a memory with these photos and this note, tagged with the milestone "Mỉm cười đáp lại".; Medium 13 muted). Primary Button "Tạo kỷ niệm" (Create memory).

**Visual:** the reference photo is replaced by the family's own two photos. A peach call-to-action card invites saving the moment to Memories.

**Navigation (inferred):** "Tạo kỷ niệm" → 3e. Back → 3a (now 3 milestones).

**Notes / not shown:** no edit or delete action for the observation (no ••• menu). The "Lưu để theo dõi" state is gone after observing. There is no toast for "Đã lưu mốc" (the frame name implies the save just happened). The age in the meta line is wrong for the mock DOB (see Mock scenario).

### 311:41672 — 3e · Tạo kỷ niệm từ mốc (Create memory from milestone, sheet)
**Annotation:** none.

**Background:** a copy of 3d under the scrim.

**Sheet text (reading order)**
- SheetHeader: "Kỷ niệm mới" (New memory) + close.
- Photos: two 110 × 130 tiles (radius 16; Peach, Sun). These are the same photos as the milestone.
- Field "Chú thích" (Caption): "Lần đầu Teddy cười đáp lại mẹ 💛" (First time Teddy smiled back at Mum 💛). This is **not** the milestone note; it is either generated or user-edited (inferred).
- Tag chips: "☆ Mốc · Mỉm cười đáp lại" (`peach-soft`, Icon/star 14, `care-bottle-ink`) · "🎂 08/10/2026" (`surface-2`, Icon/cake 14, `ink`).
- Label "Ai được xem" (Who can see).
- Radio group (`surface-2` rows, radio 22 px):
  - ◉ "Cả gia đình" (Whole family) / "Ông bà, cô chú đã được mời" (Grandparents, aunts and uncles who were invited)
  - ○ "Chỉ bố mẹ" (Parents only) / "Mai, Ba Tuấn"
- Primary Button: "Lưu kỷ niệm" (Save memory).

**Visual:** a sheet over the dimmed saved-milestone page, with the photos, an editable caption, two read-only tag chips, a two-option audience radio and a save button.

**Navigation (inferred):** "Lưu kỷ niệm" → 3f with a toast. Close → 3d.

**Notes / not shown**
- **Copy differs from Memories.** Memories (04, R-103/R-112) use "Gia đình" / "**Chỉ ba mẹ**". Here the labels are "Cả gia đình" / "**Chỉ bố mẹ**" (bố vs ba). ARB keys need one canonical label.
- The default is "Cả gia đình", which matches D-001 (shareable by default).
- Missing compared with Memories compose (10h, `185:…`): there is no "Báo cho gia đình" (notify family) toggle, no album picker, and no date mode. The milestone and date chips look read-only, with no chevron.
- No caption counter (memories `captionMax` 2000).

### 311:41752 — 3f · Mốc đã gắn kỷ niệm (Milestone linked to a memory)
**Annotation:** none.

**Text (reading order)**
- The same as 3d down to the note (chips "✓ Đã quan sát", "Giao tiếp"; title; meta; 2 photos; note).
- Instead of the CTA card, a white row (radius 18). 48 px photo thumbnail (radius 12, Peach) · "Đã lưu trong Kỷ niệm" (Saved in Memories; SemiBold 15) / "Cả gia đình xem được · 2 ảnh" (Whole family can see · 2 photos; Medium 12 muted) · chevron-right.
- Toast (bottom, `ink` pill, px 16 / py 12, Icon/check 16 white): "Đã tạo kỷ niệm" (Memory created; SemiBold 14 white).

**Visual:** the milestone detail now carries a compact link row to the memory, with a dark confirmation toast near the bottom.

**Navigation (inferred):** the link row → the memory in Memories (10f viewer or the timeline entry).

**Notes / not shown:** what happens to the link row if the memory is deleted (the 30-day bin, R-111) or its audience changes. Whether a milestone can link to more than one memory (only one row is drawn).

### 311:41795 — 3g · Tạo mốc riêng (Create own milestone)
**Annotation:** none.

**Text (reading order)**
- Top: **close (X)** · BabySwitcher. **Layer name ≠ icon:** the button layer is "back" but holds Icon/close.
- Title: "Mốc riêng" (Own milestone)
- Lead (Medium 14/1.45 muted): "Những lần đầu tiên chỉ nhà mình có — ghi lại theo cách của bạn." (Firsts only your family has. Record them your way.)
- Field "Tên mốc" (Milestone name): "Lần đầu về quê" (First trip to the home town) · counter **"14/80 ký tự"** (14/80 characters; Medium 12 muted).
- Field "Ngày" (Date): Icon/cake · "Chủ Nhật, 04/10/2026" · chevron-down.
- Field "Ghi chú" (box h 84): "Cả nhà về Nam Định thăm ông bà. Teddy ngủ suốt chặng đường." (The family went to Nam Định to visit the grandparents. Teddy slept the whole way.)
- Photos: one 76 px thumbnail (Mint tone; looks like hands) and a dashed camera slot. There is **no "Ảnh (không bắt buộc)" label** here, unlike 3c.
- Row (white, radius 16): "Tạo kỷ niệm cùng lúc" (Create a memory at the same time) / "Lưu ảnh và ghi chú vào Kỷ niệm" (Save the photos and note to Memories) · **Toggle ON**.
- Primary Button: "Lưu mốc".

**Visual:** a full-screen form (not a sheet) with name, date, note, photo strip, a "also create memory" switch and save.

**Navigation (inferred):** close → 3a. "Lưu mốc" → a 3d-like detail for the custom milestone, or → 3f if the toggle is on (not drawn). Group is fixed to "Mốc riêng" (no group or category picker).

**Notes / not shown**
- **Name limit conflict:** the design says 80 characters, but `packages/contracts/src/memories.ts` has `milestoneNameMax: 60` (the 10h4 custom-milestone name).
- With the toggle on, the audience of the auto-created memory is not chosen here. Presumably it uses the default "Gia đình" (D-001, inferred).
- **This duplicates Memories 10h4 "Tạo mốc mới"** (name + date, "Mốc mới được lưu cho cả nhà dùng lại lần sau.", R-105). 3g adds a note, photos and the memory toggle. They should resolve to one entity (see Open questions).

#### Data model implied (cluster 3)
| Entity / field | Type | Example from design |
|---|---|---|
| **ReferenceMilestone** (editorial, portal B07/B08) | | |
| · id / slug | string | (p_<slug> per `milestoneIdSchema`, inferred) |
| · title (vi/en) | string | "Mỉm cười đáp lại" |
| · group | enum {van_dong, giao_tiep, nhan_thuc, cam_xuc_xa_hoi} | "Giao tiếp" |
| · ageRangeMonths {from, to} | int, int | 1–3 ("tham khảo 1–3 tháng") |
| · howToRecognise | text (~200 chars) | "Bé cười khi nhìn thấy mặt bạn…" |
| · illustration | image | hero 343 × 170 photo |
| · order (within group) | int | (B08 "order") |
| · status / review (reviewer, reviewedAt, reReviewDue, sources) | portal-only | B08 "Thu Hà · Nhóm chuyên môn", 12-month re-review |
| · icon/tint per group | derived from group | heart/peach, ruler/growth, spark/sleep, family/mint |
| **BabyMilestone** (per baby: an observation of a reference milestone, or a custom one) | | |
| · babyId | id | Teddy |
| · referenceId? or custom name | id \| string (≤ 80 per design, ≤ 60 per code) | "Mỉm cười đáp lại" / "Lần đầu về quê" |
| · kind | enum {reference, custom} | "Mốc riêng" chip/subline for custom |
| · state | enum {suggested (derived), following ("Lưu để theo dõi"), observed} | "✓ Đã quan sát" |
| · observedOn | date | 08/10/2026 |
| · ageAtObservation | derived (DOB → date) | "3 tuần 4 ngày" |
| · note | text (optional) | "Bé cười khi mẹ hát bài…" |
| · photos | media[] (optional, 0..n) | 2 photos |
| · recordedBy | memberId → role label | "Mẹ ghi" |
| · memoryId? | link to Memory | "Đã lưu trong Kỷ niệm" |
| **Summary** | derived count | "Teddy đã có 2 mốc" |
| **Memory** (existing, `04` / contracts) | | caption "Lần đầu Teddy cười đáp lại mẹ 💛", milestoneRef {id, name, date}, audience {Gia đình, Chỉ ba mẹ}, mediaItems (the same 2 photos) |

#### How milestones link to Memories (kỷ niệm)
- **Today (V1, built):** a Memory carries one optional `milestoneRef {id, name, date}`, denormalised onto the memory and its items (`packages/contracts/src/memories.ts`, `milestoneRefSchema`). IDs are `ms_<hex>` for family-created ones and `p_<slug>` for age presets (10h3). Memories show a "★ <name> · <date>" chip (10f viewer, 10h compose). The Album tab gathers "Gom từ mốc bạn đã gắn" collections (R-107). The rule is "Mỗi kỷ niệm 1 mốc" (one milestone per memory, 10h3).
- **v1.1 adds the reverse direction:** a milestone can exist on its own, with date, note and photos, before any memory exists (3c/3d). From there, "Tạo kỷ niệm" (3d → 3e) builds a Memory **pre-filled** with the milestone's photos, a caption, the milestone tag and its date, and an audience chosen in the sheet. The milestone then shows a back-link row "Đã lưu trong Kỷ niệm · Cả gia đình xem được · 2 ảnh" (3f). 3g's toggle "Tạo kỷ niệm cùng lúc" does both in one step.
- **Implementation implications (inferred):**
  1. Milestone photos must be uploaded somewhere before a memory exists. Either they are Memory media held "private to the milestone", or the milestone stores its own media that are **re-used** (not copied) by the memory. 3e reuses the same two photos, which points to shared media IDs.
  2. 10h3 presets ("Lần đầu cười", "Lần đầu tắm", "Ngẩng đầu", "Lần đầu đi dạo", "Đầy tháng", "Lần đầu gặp ông bà") are **"firsts"**. 3a reference milestones ("Mỉm cười đáp lại", "Giữ đầu khi nằm sấp" …) are **developmental** with groups and age ranges. "Lần đầu cười" ≈ "Mỉm cười đáp lại" and "Ngẩng đầu" ≈ "Giữ đầu khi nằm sấp" overlap. The `p_<slug>` presets must either become the B07 reference set or stay a separate list.
  3. Custom milestones are family-shared in 10h4 (R-105). In 3a they appear as "Mốc riêng" per baby. Is the scope family or baby?
  4. Tagging a memory with a reference milestone in 10h3 should probably also mark the milestone observed (and vice versa). This is not designed.

#### Static vs per-baby vs editorial (cluster 3)
- **Static app copy (ARB):** screen titles, the "Teddy đã có {n} mốc" template, "Ghi lại khi bạn thấy bé làm được. Mỗi bé có nhịp riêng.", section headers ("Đã quan sát", "Gợi ý quanh tuổi của bé"), group names (also editorial taxonomy, but fixed, so best kept as an enum plus ARB), "tham khảo {a}–{b} tháng", "Cách nhận biết" header, the reassurance banner, button labels, sheet titles, field labels, "Mốc riêng" lead, "{n}/80 ký tự", "Giữ khoảnh khắc này trong Kỷ niệm?" and its body template, audience labels, "Đã lưu trong Kỷ niệm", "{audience} xem được · {n} ảnh", toast "Đã tạo kỷ niệm", "Tạo kỷ niệm cùng lúc" / "Lưu ảnh và ghi chú vào Kỷ niệm".
- **Per-baby user data:** observed / following state, date, note, photos, recorder, custom milestone name, linked memoryId, count.
- **Editorial (portal B07/B08):** reference milestone title, group, age range, "Cách nhận biết" text, illustration, order, review/sources, locale.

#### Admin-portal candidates (cluster 3), cross-referenced to `18-admin-portal-v1.md` §10
| App field | Portal B07/B08 (names from the metadata dump) | Status |
|---|---|---|
| Title "Mỉm cười đáp lại" | milestone name | ✓ |
| Group chip (4 groups) | "group (Vận động, Giao tiếp, Nhận thức, Cảm xúc – xã hội)" | ✓ exact match |
| "tham khảo 1–3 tháng" | "age range" | ✓ (unit: months in app; check portal unit) |
| Ordering of suggestions | "order" | ✓ |
| "Cách nhận biết" body | "how to recognise it" | ✓ |
| Hero photo (3b) | "illustration" | ✓ (needs image upload, crop 343 × 170 ≈ 2:1) |
| (not shown in app) | expert review "Thu Hà · Nhóm chuyên môn", re-review after 12 months, sources | portal-only. Consider a "Nội dung từ đội chuyên môn" footer on 3b as 6c has |
| (not shown in app) | "Ba mẹ đã ghi" counts in B07 | an aggregate across families; needs a server counter, privacy review (no child data) |
| Reassurance banner | B07 note "the app does not judge early or late" | static copy |
| Locale | vi/en | D-012: editorial content needs vi + en versions, or a vi-only fallback rule |
| Related items | B06 age cards link "related articles and milestones" | milestone IDs must be stable and referenceable |
- Missing from both designs: the group icon and tint (hard-coded per group, inferred); how many suggestions show and the window rule (age ± ?); publish state (Nháp → Chờ duyệt → Đã duyệt → Xuất bản, B04) gating what the app shows.

#### Images and illustrations used (cluster 3)
- **Illustration/Photo** (131:758, privacy-safe placeholder): Peach (3a summary, 3b/3c hero, 3c/3d/3e/3f user photos, 3f thumbnail), Sun (3c/3d/3e second user photo, a teddy-bear-and-basket image), Mint (3g, hands). The **3b/3c hero is an editorial photo** (a parent nose-to-nose with a baby). The others stand for user photos.
- **Illustration/BabyFace** (25:323) in the BabySwitcher.
- Line icons: spark, star, heart, ruler, family (group icons); check, chevron-right, chevron-down, plus, cake, camera, close, back.
- Emoji: 💛 in the 3e caption (user text).
- No gradients other than the Illustration/Photo tone backgrounds.

---

## Cluster 6 · Wonder Week (nội dung từ portal)

### 315:2506 — 6a · Wonder Week · thiết lập (setup)
**Annotation:** none.

**Text (reading order)**
- Top: back · BabySwitcher.
- Title: "Wonder Week"
- Hero photo 343 × 150, radius 22 (Illustration/Photo, **Lavender** #EDE3F8→#C8B1E8; a crying or yawning newborn). Editorial, inferred.
- Lead (Medium 15/1.5 muted): "Những giai đoạn bé phát triển nhanh — có thể quấy, bám ba mẹ hơn. Lịch chỉ là dự kiến, mỗi bé mỗi khác." (Phases when baby develops quickly and may be fussier and clingier. The calendar is only an estimate; every baby is different.)
- Section "Tính lịch theo" (Calculate the calendar from; Bold 17).
- Radio card selected (`mint-soft`, radius 16, p 14): ◉ "Ngày dự sinh" (Due date) / "Thường được dùng để tính Wonder Week" (Usually used to calculate Wonder Weeks).
- Radio card (white): ○ "Ngày sinh" (Date of birth) / "Dùng khi không nhớ ngày dự sinh" (Use when you don't remember the due date).
- Field "Ngày dự sinh": Icon/cake · "Thứ Hai, 21/09/2026" · chevron-down. Helper (Medium 12 muted): "Teddy sinh 17/09/2026 · sớm 4 ngày" (Teddy born 17/09/2026 · 4 days early).
- Primary Button: "Xem lịch dự kiến" (See the expected calendar).

**Visual:** a lavender-toned photo header, an explainer, two big radio cards with the selected one tinted mint, a date field with a computed helper and a CTA.

**Navigation (inferred):** CTA → 6b. Entry from the "Wonder Week" Care tile (currently "Sớm ra mắt"). Shown the first time only (inferred); "Đổi" on 6b returns here.

**Notes / not shown**
- **A new per-baby field: due date (ngày dự sinh).** The baby profile today has DOB only (onboarding `01`). Open: whether the due date is stored on the baby profile (shared with the family, and editable from Hồ sơ bé) or only in Wonder Week settings.
- "sớm 4 ngày" is computed. Copy for "muộn N ngày" and "đúng ngày" is not drawn.
- When "Ngày sinh" is chosen, presumably the field hides and the DOB is used (not drawn).

### 315:2566 — 6b · Lịch dự kiến (Expected calendar)
**Annotation:** none. Height 1250 (scrolls).

**Text (reading order)**
- Top: back · BabySwitcher.
- Title: "Lịch dự kiến" (Expected calendar)
- Row (white, radius 16): Icon/alert on `care-sleep-soft` · "Nhắc trước 3 ngày" (Remind 3 days before) / "Khi một giai đoạn sắp bắt đầu" (When a phase is about to start) · **Toggle ON**.
- Meta: chip "Theo ngày dự sinh 21/09" (Based on due date 21/09; `surface-2`, SemiBold 12) · spacer · link "Đổi" (Change; SemiBold 14 `mint-text`).
- Timeline "Now" marker: 10 px `mint-deep` dot · "Hôm nay · Teddy tuần 3 (tính theo dự sinh)" (Today · Teddy week 3 (counted from due date); SemiBold 13 `mint-text`).
- Leap cards (rail number pill + card):
  | # | Header (weeks) | Title | Range | Style |
  |---|---|---|---|---|
  | 1 | "Tuần 4–5" | "Cảm giác thay đổi" (Changing sensations) | "Dự kiến 11/10 – 18/10" | **upcoming/current:** number pill `care-sleep-accent #6c6fd8` / white; card `care-sleep-soft #edeefc`, text `care-sleep-ink #4447a8`; badge "Còn 3 ngày" (3 days left; white pill, SemiBold 11) |
  | 2 | "Tuần 7–9" | "Nhận ra hình mẫu" (Patterns) | "Dự kiến 02/11 – 23/11" | future: pill `surface-2` / `ink-muted`; card white + 1 px `separator` |
  | 3 | "Tuần 11–12" | "Chuyển động mượt mà" (Smooth transitions) | "Dự kiến 30/11 – 14/12" | future |
  | 4 | "Tuần 14–19" | "Sự kiện" (Events) | "Dự kiến 21/12 – 01/02" | future |
  | 5 | "Tuần 22–26" | "Mối quan hệ" (Relationships) | "Dự kiến 15/02 – 22/03" | future |
  | 6 | "Tuần 33–37" | "Phân loại" (Categories) | "Dự kiến 03/05 – 07/06" | future |
  | 7 | "Tuần 41–46" | "Trình tự" (Sequences) | "Dự kiến 28/06 – 09/08" | future |
- Footer (Medium 13 muted, centred): "+ 3 giai đoạn đến 76 tuần" (+ 3 phases up to week 76).

**Date arithmetic.** For leaps 2–7 the dates follow exactly **start = dueDate + 7 × (startWeek − 1) days; end = dueDate + 7 × endWeek days**. Check: 21/09 + 42 = 02/11 and + 63 = 23/11; + 70 = 30/11 and + 84 = 14/12; + 91 = 21/12 and + 133 = 01/02; + 147 = 15/02 and + 182 = 22/03; + 224 = 03/05 and + 259 = 07/06; + 280 = 28/06 and + 322 = 09/08. **Leap 1 breaks the rule:** the formula gives 12/10 – 26/10, but 11/10 – 18/10 is drawn. That suits "Còn 3 ngày" from 08/10 but is 8 days long, not two weeks. The end date also overlaps the start of the 2-week window inconsistently. "Tuần 3" today: 08/10 − 21/09 = 17 days → week 3 (days 14–20) ✓. Ranges cross the year (01/02, 22/03 …) without a year. Leaps 4–7 fall in 2027, so the year is ambiguous.

**Visual:** a vertical timeline. The next phase is highlighted in lavender with a countdown badge, and later phases are outlined white cards with grey numbers. The reminder toggle sits at the top.

**Navigation (inferred):** a leap card → 6c. "Đổi" → 6a. The toggle turns the 3-day reminder on or off for this user (6c shows recipients "Bạn, Ba Tuấn").

**Notes / not shown:** no states for a phase in progress (6f shows "Đang diễn ra · ngày 2" in the hero) or past (done or greyed). The "+ 3 giai đoạn" footer is not tappable or expandable as drawn (inferred). Is the timeline capped at 76 or 80 weeks (B09 says 0–80)? Premature babies are not handled beyond the due-date choice.

### 315:2684 — 6c · Chi tiết giai đoạn (Phase detail)
**Annotation:** none. Height 1218.

**Text (reading order)**
- Top: back · BabySwitcher.
- Hero (`care-sleep-soft`, radius 24, p 18). Chips "Wonder Week 1" (white / `care-sleep-ink`, SemiBold 12) and "Còn 3 ngày" (`care-sleep-accent` / white). Title "Cảm giác thay đổi" (Bold 26 `care-sleep-ink`). "Dự kiến 11/10 – 18/10" (Medium 14 `care-sleep-ink`).
- Card "Tuần tuổi" (Age in weeks) + right "Tuần 4–5" (Bold 15 `care-sleep-ink`). Scale of 8 week bars (8 px, radius 4, gap 3). Weeks 1–2 and 6–8 are `surface-2`. **Week 3 is `mint-deep`** with label Bold 11 `mint-text` (today). **Weeks 4–5 are `care-sleep-accent`** (the leap). Caption: "Teddy đang ở tuần 3 (tính theo ngày dự sinh)" (Teddy is in week 3 (counted from the due date)).
- Card "Biểu hiện thường gặp" (Common signs), Icon/alert 16 bullets: "Quấy khóc nhiều hơn thường ngày" (Cries more than usual) · "Muốn được bế, bám ba mẹ" (Wants to be held, clings to parents) · "Giấc ngủ và cữ bú có thể xáo trộn" (Sleep and feeds may be disrupted).
- Card "Bé đang học gì" (What baby is learning), Icon/spark bullets: "Cảm nhận rõ hơn âm thanh, ánh sáng, mùi" (Senses sound, light and smell more clearly) · "Tỉnh táo và quan sát lâu hơn" (Stays alert and watches for longer) · "Phản ứng nhiều hơn với thế giới xung quanh" (Reacts more to the world around).
- Card "Ba mẹ có thể" (Parents can), Icon/heart bullets: "Ôm ấp, da kề da khi bé quấy" (Cuddle, skin-to-skin when baby fusses) · "Giảm bớt kích thích: ánh sáng dịu, tiếng ồn nhỏ" (Reduce stimulation: soft light, low noise) · "Nghỉ ngơi và chia ca chăm cùng người thân" (Rest and share care shifts with family).
- Row (white): "Nhắc trước 3 ngày" / "Bạn, Ba Tuấn" (You, Dad Tuấn) · **Toggle ON**.
- Primary Button: "Ghi lại biểu hiện của bé" (Record baby's signs).
- Footnote (Medium 12/1.45 muted): "Nội dung từ đội chuyên môn Child Life. Thời điểm chỉ là dự kiến; nếu bé khác thường, hãy hỏi bác sĩ." (Content from the Child Life expert team. Timing is only an estimate; if baby seems unusual, ask a doctor.)

**Visual:** a lavender hero with a countdown, a mini 8-week bar showing today against the leap window, and three white editorial cards with distinct bullet icons (alert, spark, heart). Then a reminder switch, a CTA and a small provenance line.

**Navigation (inferred):** CTA → 6e sheet. Back → 6b. A segmented "Giai đoạn / Ghi chép · n" control appears in 6f, but **not here**, though 6f's "Giai đoạn" tab presumably equals this content.

**Notes / not shown:** the reminder toggle here is per phase or global? In 6b it is global with subline "Khi một giai đoạn sắp bắt đầu". Here the subline lists recipients "Bạn, Ba Tuấn", which suggests **reminders go to both parents** (who chooses? Q-039 "choosing who is reminded"). The scale window (weeks 1–8) must shift per leap (inferred). No hero illustration here, though 6a has one.

### 315:2804 — 6d · Thông báo trước 3 ngày (Notification 3 days before)
**Annotation:** none.

**Text (reading order)**
- Lock-screen background: gradient #2E525C → #122129 (top to bottom); not a token.
- "Thứ Năm, 8 tháng 10" (SemiBold 17 white) · "08:30" (Bold 84 white).
- Notification (white 82 %, radius 22, px 14 / py 12): **Logo/App Icon** 20 px (35:239: "App icon 1024 full-bleed cho phương án 2 (iOS tự bo góc). Light / Dark / Tinted.") · "CHILD LIFE" (SemiBold 12 muted) · "bây giờ" (now). Title "Wonder Week 1 sắp bắt đầu" (Wonder Week 1 is about to start; Bold 15 `ink`). Body "Dự kiến từ 11/10 · Xem bé đang học gì và cách đồng hành." (Expected from 11/10 · See what baby is learning and how to support them.; Medium 14/1.4).
- Caption (12, white 70 %): "Chạm để mở giai đoạn trong Child Life" (Tap to open the phase in Child Life).

**Visual:** a standard iOS lock screen with a single Child Life notification card.

**Navigation (inferred):** tap → 6c for that leap (deep link).

**Notes / not shown**
- Delivery is at **08:30 local**, 3 days before the leap start. The time-of-day rule is not stated.
- **Privacy:** the notification body has no baby name ("Wonder Week 1 sắp bắt đầu"), which is consistent with R-171 "Ảnh của con không hiện trên màn hình khoá" and the no-child-data rule. With 2+ babies the notification does not say which baby. Recommend a nickname-free "bé" or an opt-in.
- B10 has a "notification title and body" per phase. So title and body are **editorial per leap**, with placeholders for the date (inferred).
- Push vs local: R-091 makes care reminders local notifications on the creating device. This reminder targets "Bạn, Ba Tuấn" (multiple members), which implies **server push (FCM)** or a local schedule on each member's device.

### 315:2833 — 6e · Ghi biểu hiện thực tế (Record actual signs, sheet)
**Annotation:** none.

**Background:** a copy of 6c (hero still says "Còn 3 ngày", although the sheet date is 12/10, after the 11/10 start; mock inconsistency).

**Sheet text (reading order)**
- SheetHeader: "Biểu hiện của Teddy" (Teddy's signs) + close.
- Field "Ngày": Icon/cake · "Thứ Hai, 12/10/2026" · chevron-down.
- Label: "Bạn thấy bé thế nào? (gợi ý từ giai đoạn này)" (How does baby seem to you? (suggestions from this phase)).
- Multi-select chips (wrap, gap 8). Selected: `care-sleep-soft`, Icon/check 14, SemiBold 13 `care-sleep-ink`. Unselected: white with 1 px `control-border`, `ink`.
  - ✓ "Quấy nhiều hơn" (Fussier) · ✓ "Bám ba mẹ" (Clingy) · "Ngủ xáo trộn" (Disrupted sleep) · "Bú thay đổi" (Feeding changed) · ✓ "Tỉnh táo lâu hơn" (Alert for longer) · "Không thấy khác" (No difference)
- Field "Ghi chú" (box h 96): "Tối nay bé khóc lâu hơn, chỉ chịu nằm trên ngực mẹ. Ban ngày nhìn theo đèn rất lâu." (Tonight baby cried longer and would only lie on Mum's chest. During the day stared at the lamp for a long time.)
- Row (`surface-2`, radius 14): "Chia sẻ với gia đình" (Share with family) / "Ông bà xem được trong mục này" (Grandparents can see it in this section) · **Toggle OFF**.
- Primary Button: "Lưu ghi chép" (Save note).

**Visual:** a sheet with a date, a wrap of lavender multi-select chips, a note box, a share switch (off) and save.

**Navigation (inferred):** save → 6f (the "Ghi chép" tab, count +1). Close → 6c.

**Notes / not shown**
- The sign chips are **editorial per leap** ("gợi ý từ giai đoạn này"). They are short labels distinct from the "Biểu hiện thường gặp" sentences in 6c, so the portal needs both: long sentence and short chip label (inferred). "Không thấy khác" is probably a fixed option, and should be exclusive with the others (not stated).
- **Visibility default is private to parents** (toggle off), unlike Memories (D-001 default Gia đình). "Ông bà xem được trong mục này" implies relatives can open the Wonder Week section. This conflicts with the relative role's limited scope (R-119: relatives see Gia đình memories, not care data unless enabled).
- No photos on a WW note. No edit or delete.

### 315:2972 — 6f · Ghi chép của nhà mình (Our family's notes)
**Annotation:** none.

**Text (reading order)**
- Top: back · BabySwitcher.
- Hero (`care-sleep-soft`, radius 24, px 18 / py 16). Chip "Đang diễn ra · ngày 2" (In progress · day 2; white / `care-sleep-ink`). Title "Cảm giác thay đổi" (Bold 24). "Wonder Week 1 · dự kiến 11/10 – 18/10" (Medium 13).
- Segmented (`surface-2`, radius 14, p 4): "Giai đoạn" (Phase; Medium 14 muted) | **"Ghi chép · 2"** (Notes · 2; selected, white radius 10, SemiBold 14 `ink`).
- Note card 1 (white, radius 20, shadow): "Thứ Hai 12/10" (Bold 14) · "Mẹ ghi" (Recorded by Mum; Medium 12 muted). Tags (`care-sleep-soft` / `care-sleep-ink`, SemiBold 12, px 8 / py 3): "Quấy nhiều hơn", "Bám ba mẹ", "Tỉnh táo lâu hơn". Text "Tối nay bé khóc lâu hơn, chỉ chịu nằm trên ngực mẹ. Ban ngày nhìn theo đèn rất lâu."
- Note card 2: "Chủ Nhật 11/10" · "Ba Tuấn ghi". Tag "Ngủ xáo trộn". Text "Giấc trưa ngắn, dậy 3 lần." (Short nap, woke 3 times.)
- Dashed button: "+ Thêm ghi chép" (Add note).

**Visual:** a lavender hero showing the phase in progress, a two-tab switch, and reverse-chronological note cards with lavender tags and author labels.

**Navigation (inferred):** the "Giai đoạn" tab → 6c content. "Thêm ghi chép" → 6e. Note card → edit (not drawn).

**Notes / not shown:** day counting: 12/10 is "ngày 2" with a start of 11/10, so the start day is day 1. Notes are per baby and per leap. The design does not say whether notes recorded before the window (in the 3-day pre-period) or after it belong to the leap. There is no share or visibility indicator on the cards (6e has a share toggle). There is no link from a note into Memories or Care logs (for example, sleep data that could corroborate "Ngủ xáo trộn").

#### Data model implied (cluster 6)
| Entity / field | Type | Example |
|---|---|---|
| **WonderWeekPhase** (editorial, portal B09/B10) | | |
| · number | int 1..10 | 1 |
| · title (vi/en) | string | "Cảm giác thay đổi" |
| · weekStart, weekEnd (from the due date) | int, int | 4, 5 (B10 "weeks counted from the due date") |
| · commonSigns[] | string[] (3 shown) | "Quấy khóc nhiều hơn thường ngày" |
| · learning[] ("Bé đang học gì") | string[] (3) | "Cảm nhận rõ hơn âm thanh, ánh sáng, mùi" |
| · parentTips[] ("Ba mẹ có thể") | string[] (3) | "Ôm ấp, da kề da khi bé quấy" |
| · signChips[] (short tags for 6e) | string[] (5 + fixed "Không thấy khác") | "Quấy nhiều hơn", "Bú thay đổi" |
| · reminder {daysBefore: 3, title, body} | int, string, string | "Wonder Week 1 sắp bắt đầu" / "Dự kiến từ {date} · Xem bé đang học gì và cách đồng hành." |
| · illustration? | image | 6a hero (lavender); none on 6c |
| · review/sources/status | portal-only | "Nội dung từ đội chuyên môn Child Life" |
| **BabyWonderWeekSettings** (per baby) | | |
| · basis | enum {dueDate, birthDate} | dueDate |
| · dueDate | date | 21/09/2026 |
| · (derived) earlyLateDays | int | "sớm 4 ngày" |
| **WonderWeekReminderPref** (per member × baby, inferred) | bool | ON; recipients "Bạn, Ba Tuấn" |
| **Derived per baby:** currentWeek ("tuần 3"), phase windows (start/end dates), countdown ("Còn 3 ngày"), in-progress day ("ngày 2") | | |
| **WonderWeekNote** (per baby, per phase) | | |
| · babyId, phaseNumber | id, int | Teddy, 1 |
| · date | date | 12/10/2026 |
| · signs[] | chip ids | ["quay_nhieu_hon","bam_ba_me","tinh_tao_lau_hon"] |
| · note | text | "Tối nay bé khóc lâu hơn…" |
| · sharedWithFamily | bool (default false) | off |
| · createdBy | memberId → "Mẹ ghi" / "Ba Tuấn ghi" | |
| · count per phase | derived | "Ghi chép · 2" |

#### Static vs per-baby vs editorial (cluster 6)
- **Static app copy:** "Wonder Week" title, the 6a lead, "Tính lịch theo", radio labels and sublines, "Teddy sinh {dob} · sớm/muộn {n} ngày", "Xem lịch dự kiến", "Lịch dự kiến", "Nhắc trước 3 ngày" / "Khi một giai đoạn sắp bắt đầu", "Theo ngày dự sinh {dd/MM}", "Đổi", "Hôm nay · {name} tuần {n} (tính theo dự sinh)", "Tuần {a}–{b}", "Dự kiến {d1} – {d2}", "Còn {n} ngày", "+ {n} giai đoạn đến {w} tuần", "Wonder Week {n}", "Tuần tuổi", the three card headers (or editorial, if the portal allows renaming), "{name} đang ở tuần {n} (tính theo ngày dự sinh)", the CTA, the provenance footnote, the sheet title "Biểu hiện của {name}", "Bạn thấy bé thế nào? (gợi ý từ giai đoạn này)", "Chia sẻ với gia đình" / "Ông bà xem được trong mục này", "Lưu ghi chép", "Đang diễn ra · ngày {n}", "Giai đoạn" / "Ghi chép · {n}", "{member} ghi", "Thêm ghi chép", "Chạm để mở giai đoạn trong Child Life" (mock only).
- **Per-baby user data:** basis, due date, reminder on/off per member, notes (date, signs, text, share flag, author).
- **Editorial (portal B09/B10):** phase number, title, week window, common signs, learning points, parent tips, sign chips, reminder title/body, illustration, review/sources, locale.

#### Admin-portal candidates (cluster 6), cross-referenced to `18-admin-portal-v1.md` §10
| App field | Portal B09/B10 | Status |
|---|---|---|
| 10 phases, numbered | B09 "10 Wonder Week phases on a 0–80-week timeline" | ✓ (app footer says "đến 76 tuần") |
| Week window "Tuần 4–5" | B10 "weeks counted from the due date" | ✓ the app adds a birth-date fallback, so the portal should state that windows are due-date-relative |
| "Biểu hiện thường gặp" | B09/B10 "signs" | ✓ |
| "Bé đang học gì" | B09 "what baby is learning" | ✓ |
| **"Ba mẹ có thể"** | **not listed** in the B09/B10 summary | **gap**: check B10 for a tips field (the metadata dump may simply not name it) |
| **6e sign chips** (short labels) | **not listed** | **gap**: the portal needs a short-label list per phase, or chips are derived from "signs" |
| Notification title + body | B10 "a reminder 3 days ahead with notification title and body" | ✓ (days-before fixed at 3 in the app copy; the portal may make it configurable) |
| App preview | B10 "app preview" | ✓ (6c layout) |
| Review / provenance | B03/B04 review queue covers Wonder Weeks | ✓ + the app footnote "Nội dung từ đội chuyên môn Child Life" |
| Illustration | not listed | 6a hero only, probably static app art |
| Locale | — | vi/en per D-012 |

#### Images and illustrations used (cluster 6)
- **Illustration/Photo, Lavender tone** (#EDE3F8→#C8B1E8) in the 6a hero: a crying newborn. It looks **editorial** (stock-like) and is used once.
- **Logo/App Icon** (35:239) on the 6d notification.
- Lock-screen gradient #2E525C→#122129 (mock only).
- Line icons: alert (signs bullets, reminder chip), spark (learning bullets), heart (parent-tip bullets), check (selected chips), cake (date field), plus, back, close, chevron-down.
- Palette: Wonder Week reuses the **care-sleep** family (`care-sleep-soft #edeefc`, `care-sleep-accent #6c6fd8`, `care-sleep-ink #4447a8`), and the landing (`12-landing-v3-new-sections.md`) does the same. Today is marked in `mint-deep #087f7b`.

---

### Open questions / gaps (both clusters)
1. **Two milestone systems.** The V1 Memories presets (10h3 "Lần đầu cười", "Ngẩng đầu" …, ids `p_<slug>`) and the custom milestones (10h4, family-wide, R-105) overlap with the v1.1 reference milestones (B07 groups and age ranges) and with "Mốc riêng" (3g). Decide one Milestone model: are presets replaced by the B07 reference set? Are custom milestones per family or per baby? Does tagging a memory with a reference milestone mark it observed, and vice versa?
2. **Milestone photo storage and visibility.** 3c attaches photos before any memory exists, with no audience choice. Who can see a milestone and its photos (parents only? relatives?). Are they Memory media (quota, `config/limits`) or separate? Does deleting the linked memory remove them?
3. **Name length:** 3g "{n}/80 ký tự" vs `milestoneNameMax: 60` in `packages/contracts/src/memories.ts`.
4. **Audience copy:** 3e "Cả gia đình" / "Chỉ bố mẹ" vs Memories "Gia đình" / "Chỉ ba mẹ". 3e also lacks "Báo cho gia đình" and the album picker that compose has.
5. **"Lưu để theo dõi"** (3b): a "following" state with no list or section drawn in 3a.
6. **Age copy:** "lúc Teddy 3 tuần 4 ngày" on 08/10 does not match DOB 17/09 (= 3 tuần) or due date 21/09.
7. **Due date** is a new baby field (6a). Should it be stored on the baby profile (edited in Hồ sơ bé, visible to all members) or as a Wonder Week setting? Copy is needed for "muộn N ngày" / "đúng ngày dự sinh". What happens to the calendar when the basis changes after notes exist?
8. **Leap 1 dates** (11/10–18/10) break the formula that leaps 2–7 follow exactly (start = due + 7·(wStart−1), end = due + 7·wEnd). Ask the owner or editor whether windows are computed from week numbers or stored as day offsets in the portal. Recommend day offsets (`startDay`, `endDay`).
9. **Timeline length:** "+ 3 giai đoạn đến 76 tuần" (app) vs "0–80-week timeline" (B09). Leap dates have no year (they cross into 2027).
10. **Reminder delivery:** 08:30 local, 3 days before, to "Bạn, Ba Tuấn". Is this server push (FCM, multi-member) or local per device (R-091)? Who decides the recipients (Q-039)? Is the toggle per member or per baby? Is it per phase (6c) or global (6b)? With 2+ babies the notification does not say which baby.
11. **Wonder Week note visibility:** the default is off ("Ông bà xem được trong mục này"). Can relatives (R-119) or caregivers open Wonder Week at all? There is no visibility indicator on 6f cards.
12. **Portal fields missing from the B09/B10 summary:** "Ba mẹ có thể" tips and the short sign-chip labels for 6e. Confirm against the B10 frame when it is extracted.
13. **"Wonder Week(s)" naming / IP:** "The Wonder Weeks" is a commercial brand with a published leap schedule and leap names (Changing sensations, Patterns …). The app copies the brand name and the leap titles. Owner and legal should confirm licensing or rename. This also concerns the landing FAQ "Lịch Wonder Week có đúng với mọi bé không?" (G-065 / `13-landing-v3-changes.md`).
14. **Medical / content review:** both clusters make developmental claims. They need the B03/B04 review flow, sources, and the 12-month re-review before they are visible in the app. Is there a fallback when a phase or milestone is unpublished?
15. **Missing states (both clusters):** empty (no milestones; Wonder Week not set up), loading/offline, past phase, a phase in progress on 6b, caregiver/relative views, Night care, edit/delete for an observation or note, multi-baby notification copy, and a date-picker range (DOB → today for milestones).
16. **Prototype wiring:** none of the 13 frames has prototype links, so all flows above are inferred.
17. **No D/R/P entries** exist yet in `business-map.md` for milestones v1.1 or Wonder Week (also noted in `12-landing-v3-new-sections.md` §10 / Q-039).

#### Coverage
13 / 13 frames read with one `get_design_context` each (311:1184, 311:1308, 311:1364, 311:1436, 311:41672, 311:41752, 311:41795, 315:2506, 315:2566, 315:2684, 315:2804, 315:2833, 315:2972). 0 failed calls, no rate-limit errors, no `get_metadata` or `get_screenshot` needed (every response included the screenshot). 13 PNGs saved under `docs/discovery/figma-extract/img/v11/`.

---

## Part C — Thư viện chăm bé (4a–4f) and Ăn dặm (5a–5h), Figma v1.1

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only), page **"v1.1"**. Read 2026-10-12. One `get_design_context` call per frame (14 calls, run one after another). No `get_metadata` or `get_screenshot` call was needed. No Figma node was modified.

**Method**
- Strings are the rendered `<p>` text, never layer names. Where a layer name disagrees with the rendered text, it is flagged **Layer name ≠ text**.
- **Annotations:** none of the 14 frames has a `data-annotation`.
- **Prototype links:** none of the 14 frames has a single `<a … cursor-pointer>` node. **The whole cluster has no prototype wiring.** Every target in "Navigation" below is *(inferred)*.
- Screenshots: `docs/discovery/figma-extract/img/v11/<node-id with : → ->.png` (14 files).
- "(inferred)" marks anything the design does not state literally.

**Mock scenario**
- Cluster 4 is about baby **Teddy, 3 weeks old** ("Hợp với Teddy · 3 tuần"). Articles were saved on 28/09 and 02/10 and "hôm nay". Reviews are dated "09/2026".
- Cluster 5 is about baby **Na**. "Now" is **Thursday 08/10/2026**: the week strip shows T5 8 selected, and 5d says "Hôm nay · Thứ Năm 08/10". That matches the page scenario of 8/10/2026.
- Na's age is "7 tháng 2 tuần" (5h), and filters say "6–7 tháng". From that, Na was born around 17–24/02/2026 *(inferred)*. She first ate solid food on 28/09 (Gạo).
- The BabySwitcher shows a chevron, so the family has more than one baby (Teddy and Na, *(inferred)*). The user is "M" (Mẹ).
- **Light mode only.** There is no Night variant. Every page uses `cloud #f6fcfb`, frame radius 40, content pt 52, px 16, gap 14.

### Frame list
| Node | Name | Size (from code/screenshot) |
|---|---|---|
| 312:1446 | 4a · Thư viện chăm bé | 375 × 1150 |
| 312:1574 | 4b · Tìm & lọc | 375 × 812 |
| 312:1679 | 4c · Bộ lọc | 375 × 812 |
| 312:42000 | 4d · Bài viết | 375 × 1600 |
| 312:42116 | 4e · Đã lưu bài viết | 375 × 812 |
| 312:42236 | 4f · Bài đã lưu | 375 × 812 |
| 313:1681 | 5a · Bật theo dõi ăn dặm | 375 × 812 |
| 313:1746 | 5b · Ăn dặm · Nhật ký | 375 × 1000 |
| 313:1872 | 5c · Ghi bữa ăn | 375 × 1000 |
| 314:1786 | 5d · Lịch sử bữa ăn | 375 × 1000 |
| 314:1901 | 5e · Món đã thử | 375 × 1000 |
| 314:1987 | 5f · Thư viện ăn dặm | 375 × 1000 |
| 314:2095 | 5g · Bài ăn dặm (công thức) | 375 × ~975 |
| 314:2169 | 5h · Hôm nay · thẻ ăn dặm | 375 × 812 |

### Shared chrome and components (both clusters)
- **StatusBar** (11:135, "Placeholder iOS status bar for screen mockups.") shows "9:41" / "•••".
- **Back button:** white round, p 8, Icon/back 20.
- **BabySwitcher** (45:321): "Baby switcher chip: avatar + name (+ chevron when the family has more than one baby). Shows whose log you are viewing." Here it uses a `surface-2 #eef6f5` background and Illustration/BabyFace 32 (25:323, "Small baby avatar for headers."). It appears only in cluster 5, never in cluster 4.
- **Illustration/Photo** (131:758): "Illustrated baby photo placeholder (privacy-safe). Use instead of real photos in mockups." Each instance is a 143° two-stop gradient with a raster photo laid over it. The rasters are **real-looking stock photos**: a crying newborn, a sleeping baby, mother and baby, toys, and a teddy bear with a basket. They stand in for editorial cover images.
  - Gradient pairs seen: lavender #ede3f8→#c8b1e8, blue #dcebfa→#a9cbef, mint #cfefea→#8fd6cb, peach #ffe3d8→#f7b9a5, yellow #fff1c9→#f9d77e, navy #2b3a55→#16233a.
- **Section header:** Bold 17 `ink #173d44`, with an optional link on the right in SemiBold 14 `mint-text #06716d` ("Xem thêm" / "Xem tất cả").
- **List group:** `surface` white, radius 16. Rows have px 14, py 12, gap 12. Each row has a thumbnail (64 / 56 / 52 / 48 px, radius 14 or 12), a title in SemiBold 15 `ink`, a meta line in Medium 12 lh 1.4 `ink-muted #55707a`, and a trailing icon (Icon/bookmark 18 or Icon/chevron-right 16).
- **Card:** white, radius 20, `shadow-card` (#173D440F 0/1/2 + #173D4414 0/8/24).
- **Pill chip:** radius 999, px 12, py 6, SemiBold 13.
- **Segmented control:** `surface-2` track, radius 14, p 4. The selected segment is white, radius 10, SemiBold 14 `ink`. Other segments are Medium 14 `ink-muted`.
- **Search field:** white, 1 px `control-border #7e959a`, radius 14, px 14, py 12, Icon/search 18. Placeholder is Medium 15 `ink-muted`; typed text is `ink`.
- **SheetHeader** (37:293): "Bottom-sheet header: grabber, title (24/32 semibold), close (44px, label "Đóng")." The sheet itself is white with top radius 28, px 16, pb 34, gap 12, over `scrim rgba(12,23,25,0.32)`.
- **Button** (8:33): "Pill button, label = 1–2-word verb (Lưu, Bắt đầu, Kết thúc, Chỉnh giờ, Mời, Thử lại). Primary h56 mint-deep/on-mint-deep, one per screen in the thumb zone. Secondary h52 surface-2. …" Text style is Text/body-strong (Medium 17/24). These labels break the "1–2-word verb" rule: "Bắt đầu theo dõi", "Ghi vào nhật ký", "Xem 8 bài".
- **Toggle** (23:262): "iOS switch. On: mint-deep track. Off: separator track. White knob."
- **Banner:** radius 14, px 14, py 12, a 16 px icon, Medium 13 lh 1.45 text. Two tints are used: `mint-soft #e6f7f5` with `mint-text` (info or update), and `surface-2` with `ink-muted` (soft medical disclaimer, Icon/heart).
- **Article bar** (4d, 4e, 5g): a fixed bottom bar. White, 1 px `separator #dce8e7` border, pt 12, pb 30, px 16, gap 10. Pills use `surface-2`, px 14, py 10, SemiBold 13.
- **Icons:** all carry "Line icon (24px, 1.8 stroke) — placeholder…; production uses SF Symbols."
  - Used here: back, bookmark (outline and filled), search, close, sliders, chevron-down, chevron-right, check, link, alert, feed, sleep, star, diaper, spark, plus, journal, heart, clock, cake, camera, retry, today, memories, family, grid.

---

### 312:1446 — 4a · Thư viện chăm bé (Care library home)
**Annotation:** none.

**Text (reading order)**
- Top: back · spacer · pill **"Đã lưu"** (Saved). The pill is white, r 999, px 12, py 8, with Icon/bookmark 16 and SemiBold 14 `ink`.
- Title (Bold 28): "Thư viện chăm bé" (Baby-care library)
- Search placeholder: "Tìm: ngủ ngày, nấc, hăm tã…" (Search: daytime sleep, hiccups, diaper rash…)
- Topic grid, 3 × 2. Each tile is 107.6 wide, p 12, r 16, gap 8, with a 20 px icon and a SemiBold 13 label:
  | Label | English | Background | Text | Icon |
  |---|---|---|---|---|
  | Bú & sữa | Feeding & milk | `care-bottle-soft #e5f1fb` | `care-bottle-ink #1d5f99` | Icon/feed |
  | Giấc ngủ | Sleep | `care-sleep-soft #edeefc` | `care-sleep-ink #4447a8` | Icon/sleep |
  | Mọc răng | Teething | `sunshine-soft #fff4d6` | `ink` | Icon/star |
  | Sốt & ốm vặt | Fever & minor illness | `error-soft #fbe9ea` | `error #a12b32` | Icon/alert |
  | Chăm hằng ngày | Daily care | `care-diaper-soft #e7f4e3` | `care-diaper-ink #2f6b24` | Icon/diaper |
  | Phát triển | Development | `mint-soft #e6f7f5` | `mint-text #06716d` | Icon/spark |
- Section "Hợp với Teddy · 3 tuần" (Right for Teddy · 3 weeks) + link "Xem thêm" (See more).
- Horizontal carousel of **ArticleCard**s. Each card is white, r 18, shadow-card, 220 wide, with a Photo 220 × 120, a title in SemiBold 15 and a meta line in Medium 12 muted:
  1. "Giấc ngủ của bé sơ sinh" (Newborn sleep) / "Giấc ngủ · 6 phút" (Sleep · 6 min)
  2. "Bé nấc, ọc sữa sau bú" (Baby hiccups, spits up after feeds) / "Bú & sữa · 4 phút"
  3. "Tắm cho bé tại nhà" (Bathing baby at home) / "Chăm hằng ngày · 5 phút" (off-screen)
- Section "Mới cập nhật" (Recently updated). It has no link.
- List group. Rows have a Photo 64 and an outline Icon/bookmark 18:
  - "Hăm tã: nhận biết và chăm sóc" (Diaper rash: recognising and caring) / "Chăm hằng ngày · 5 phút đọc" (5-min read)
  - "Khi bé sốt: những điều ba mẹ cần biết" (When baby has a fever: what parents need to know) / "Sốt & ốm vặt · 7 phút đọc"
  - "Vắt và trữ sữa mẹ" (Expressing and storing breast milk) / "Bú & sữa · 6 phút đọc"

**Layout / components / tokens:** described above. There is no TabDock and no BabySwitcher. pb is 120, but the content ends at about y 810, so the 1150 frame has empty space at the bottom.

**Visual:** A light mint page. A grid of six pastel topic tiles sits under the search field, then a horizontal row of large photo cards and a white list of recently updated articles with bookmark icons.

**Navigation (all inferred):**
- "Đã lưu" → 4f.
- Search field and topic tiles → 4b, with the matching topic filter applied.
- Cards and rows → 4d.
- Row bookmark → toggles the saved state.
- "Xem thêm" → 4b, filtered by Teddy's age.
- Entry point: the "Thư viện chăm bé" tile on the Care tab. That tile is "Sớm ra mắt" in 8a (`19-spending.md`).

**Notes / not shown**
- Reading-time format is inconsistent: the carousel says "6 phút", the list says "5 phút đọc", and 4d says "6 phút đọc".
- There is no language or library indicator, no empty state, no offline state, and no caregiver variant.
- The personalised row is keyed to Teddy's age. There is no BabySwitcher, so it is unclear which baby the row follows when the family has more than one.

---

### 312:1574 — 4b · Tìm & lọc (Search & filter results)
**Annotation:** none.

**Text (reading order)**
- Top: back only.
- Search field (filled): "ngủ" (sleep) + Icon/close 16 (clear).
- Filter row:
  - Pill **"Bộ lọc · 2"** (Filters · 2): `ink #173d44` background, white text, Icon/sliders 14.
  - Removable chip "Giấc ngủ" (`care-sleep-soft` / `care-sleep-ink`, leading Icon/close 12).
  - Removable chip "0–3 tháng" (0–3 months; `surface-2` / `ink`, leading close).
- Meta row: "8 bài viết" (8 articles; SemiBold 14 `ink`) · spacer · sort "Liên quan nhất" (Most relevant; SemiBold 14 `mint-text`) + Icon/chevron-down 14.
- Result list. Rows have a Photo 64 and a bookmark. The meta line format is "Topic · age range · minutes":
  - "Giấc ngủ của bé sơ sinh" / "Giấc ngủ · 0–3 tháng · 6 phút"
  - "Phân biệt ngày và đêm cho bé" (Helping baby tell day from night) / "Giấc ngủ · 0–3 tháng · 4 phút"
  - "Tư thế ngủ cho bé" (Sleep positions for baby) / "Giấc ngủ · 0–12 tháng · 3 phút"
  - "Bé hay giật mình khi ngủ" (Baby startles in sleep) / "Giấc ngủ · 0–3 tháng · 4 phút"
  - "Quấn chũn: khi nào và cách nào" (Swaddling: when and how) / "Giấc ngủ · 0–3 tháng · 5 phút"

**Visual:** Same list style as 4a. A dark "Bộ lọc · 2" pill leads a row of tinted removable chips.

**Navigation (inferred):**
- "Bộ lọc · 2" → 4c.
- Chip × → removes that filter.
- Sort → a sort menu (not drawn).
- Row → 4d.

**Notes / not shown**
- "8 bài viết" but only 5 rows are drawn; the rest is scroll *(inferred)*.
- "Tư thế ngủ cho bé" (0–12 tháng) matches the 0–3 filter, so the age filter matches on **range overlap**.
- The search term is not highlighted in results.
- Other sort options are not drawn. Neither are a no-results state or a "Hỏi nhanh" result row.

---

### 312:1679 — 4c · Bộ lọc (Filter sheet)
**Annotation:** none.

The background is a copy of 4b. A scrim covers it, and the sheet starts at y 209.

**Text (reading order)**
- SheetHeader: "Bộ lọc" (Filters) + close.
- Group labels are SemiBold 13 `ink-muted`. Chips are multi-select *(inferred)*.
  - Unselected chip: white, 1 px `control-border`, SemiBold 13 `ink`.
  - Selected chip: `mint-deep #087f7b`, Icon/check 14, `on-mint-deep` white.
- **"Chủ đề"** (Topic): Bú & sữa · **✓ Giấc ngủ** · Mọc răng · Sốt & ốm vặt · Chăm hằng ngày · Phát triển
- **"Độ tuổi"** (Age): **✓ 0–3 tháng** · 3–6 tháng · 6–12 tháng · 1–2 tuổi (1–2 years)
- **"Dạng nội dung"** (Content type): "Bài viết" (Article) · "Hướng dẫn từng bước" (Step-by-step guide) · "Hỏi nhanh" (Quick Q&A)
- **"Thời gian đọc"** (Reading time): "Dưới 3 phút" (Under 3 min) · "3–6 phút" · "Trên 6 phút" (Over 6 min)
- Buttons side by side: secondary "Đặt lại" (Reset; `surface-2`, h 52) and primary **"Xem 8 bài"** (See 8 articles; `mint-deep`, h 56). The count is live *(inferred)*.

**Visual:** A white bottom sheet with four groups of outlined pill chips. Selected chips are filled teal with a check. Two buttons sit at the bottom.

**Navigation (inferred):**
- "Xem 8 bài" → applies the filters, back to 4b.
- "Đặt lại" → clears all.
- Close → dismisses without applying.

**Notes / not shown**
- There is no **library** filter here (Chăm bé vs Ăn dặm), although the admin portal B01 filters by library.
- There is no language filter.
- Age bands are 0–3 / 3–6 / 6–12 months / 1–2 years. They stop at 24 months.
- The 3–6 band and the 6–12 band share boundary values; the inclusive or exclusive rule is not drawn.
- Two of the three "Dạng nội dung" values (Hướng dẫn từng bước, Hỏi nhanh) have no reader layout drawn.

---

### 312:42000 — 4d · Bài viết (Article reader)
**Annotation:** none.

**Text (reading order)**
- Top: back · spacer · round white button with Icon/link 18 (share or copy link). **Layer name ≠ icon:** the layer is "more".
- Cover Photo: h 190, r 22 (lavender gradient, crying newborn).
- Chips (no icons): "Giấc ngủ" (`care-sleep-soft` / `care-sleep-ink`) · "0–3 tháng" (`surface-2`) · "6 phút đọc" (`surface-2`).
- Title (Bold 28, lh 1.25): "Giấc ngủ của bé sơ sinh"
- Byline: Icon/check 14 + Medium 13 muted, "Đội chuyên môn Child Life · rà soát 09/2026" (Child Life expert team · reviewed 09/2026).
- **Body blocks:**
  1. Paragraph (Regular 16, lh 1.6, `ink`): "Trong những tuần đầu, bé ngủ nhiều nhưng chia thành nhiều giấc ngắn, cả ngày lẫn đêm. Đây là điều bình thường khi bé đang làm quen với nhịp sống mới." (In the first weeks baby sleeps a lot but in many short stretches, day and night. This is normal while baby adjusts.)
  2. Heading (Bold 19, lh 1.3): "Nhận biết bé buồn ngủ" (Recognising sleepy cues)
  3. Bullet list. Each bullet is a 6 × 15 dot SVG with gap 10 and Regular 16 text:
     - "Ngáp, dụi mắt, kéo tai" (Yawning, rubbing eyes, pulling ears)
     - "Nhìn xa xăm, ít phản ứng" (Staring off, less responsive)
     - "Quấy khóc dù vừa bú no" (Fussing even after a full feed)
  4. Figure: Photo h 160, r 16 (navy gradient, sleeping baby) + caption in Medium 12 muted: "Phòng ngủ tối, yên tĩnh giúp bé dễ vào giấc." (A dark, quiet room helps baby fall asleep.)
  5. Heading: "Tạo nhịp ngày – đêm" (Building a day–night rhythm)
  6. Paragraph: "Ban ngày để phòng sáng tự nhiên và trò chuyện với bé khi thức. Ban đêm giữ ánh sáng dịu, cho bú nhẹ nhàng và hạn chế chơi đùa." (By day keep the room naturally bright and talk to baby when awake. At night keep light dim, feed gently, limit play.)
  7. **Callout** (`sunshine-soft #fff4d6`, r 16, px 16, py 14): Icon/alert 16 + Bold 15 "Khi nào nên hỏi bác sĩ" (When to ask a doctor). Body in Medium 14, lh 1.55: "Nếu bạn thấy bé khác thường hoặc bạn đang lo lắng, hãy liên hệ bác sĩ hoặc cơ sở y tế gần nhất." (If baby seems unusual or you are worried, contact a doctor or the nearest health facility.)
- Section "Bài viết liên quan" (Related articles). It has no link.
- Related rows (Photo 52, r 12, chevron-right):
  - "Phân biệt ngày và đêm cho bé" / "Giấc ngủ · 4 phút"
  - "Tư thế ngủ cho bé" / "Giấc ngủ · 3 phút"
- Feedback card (white, r 16, px 16, py 14): SemiBold 14 "Bài viết có hữu ích?" (Was this article helpful?) · chips "Có" (Yes) / "Chưa" (Not yet), both `surface-2`.
- Article bar (fixed, y 1520): "Lưu" (Save; Icon/bookmark 14) · "Chia sẻ" (Share; Icon/link 14) · spacer · "Aa" (text size).

**Visual:** A long-form reader. Large rounded cover photo, small chips, a big title, a verified-style byline, then body text with headings, a bullet list, an inline photo, a yellow "ask a doctor" callout, related articles, a helpfulness poll and a sticky bottom bar.

**Navigation (inferred):**
- Back → 4a/4b/4f.
- Top link icon and "Chia sẻ" → system share sheet. They duplicate each other.
- "Lưu" → 4e state.
- "Aa" → text-size control (not drawn).
- Related rows → another 4d.
- "Có"/"Chưa" → records feedback (no confirmation drawn).

**Notes / not shown**
- There are **no sources or references** shown to the reader, although admin B03 has sources.
- There is no named author or reviewer (only "Đội chuyên môn Child Life").
- Neither "published" nor "updated" date is shown, only "rà soát" (reviewed).
- There is no general medical disclaimer beyond the callout.
- There are no related recipes, milestones or age cards.
- Neither the "Aa" sheet nor the post-feedback state is drawn.

---

### 312:42116 — 4e · Đã lưu bài viết (Article saved state)
**Annotation:** none.

**Text:** Identical to 4d, shown at 375 × 812. The differences are:
- The bar's save pill becomes **"Đã lưu"** (Saved): `mint-soft #e6f7f5` background, `mint-text #06716d`, with a filled Icon/bookmark (different SVG).
- **Toast** (`ink #173d44`, r 999, px 16, py 12, centred at y 672, above the bar): Icon/check 16 + SemiBold 14 white, "Đã lưu · xem trong Thư viện › Đã lưu" (Saved · see it in Library › Saved).

**Visual:** The 4d reader's first screen, with a dark pill toast floating above the bottom bar and the save pill turned teal.

**Navigation (inferred):**
- Tapping the toast → 4f.
- Tapping "Đã lưu" again → unsave (not drawn).

**Notes / not shown:** There is no undo in the toast and no unsave confirmation. The top-right link button is unchanged.

---

### 312:42236 — 4f · Bài đã lưu (Saved articles)
**Annotation:** none.

**Text (reading order)**
- Top: back.
- Title (Bold 28): "Đã lưu" (Saved)
- Segmented: **"Chăm bé"** (Baby care; selected) | "Ăn dặm" (Solid food). One saved list therefore spans both libraries.
- List (Photo 56, r 12, chevron-right). The meta line format is "Topic · lưu <date>":
  - "Giấc ngủ của bé sơ sinh" / "Giấc ngủ · lưu hôm nay" (saved today)
  - "Vắt và trữ sữa mẹ" / "Bú & sữa · lưu 02/10"
  - "Hăm tã: nhận biết và chăm sóc" / "Chăm hằng ngày · lưu 28/09"
- Banner (`mint-soft`, Icon/retry 16, Medium 13 `mint-text`): "Bài “Quấn chũn đúng cách” đã được đội chuyên môn cập nhật. Mở để xem bản mới." (The article "Swaddling correctly" has been updated by the expert team. Open it to see the new version.)

**Visual:** A short white list of saved articles under a two-way segmented control, followed by a mint banner about an updated article.

**Navigation (inferred):**
- Row → 4d.
- Banner → the updated article.
- "Ăn dặm" segment → saved recipes and guides from 5f/5g (not drawn).

**Notes / not shown**
- The banner title "Quấn chũn đúng cách" does not match the 4b article "Quấn chũn: khi nào và cách nào", and that article is **not in the saved list** above it.
- The banner implies the app tracks **content versions** and notifies the reader about saved items that were updated.
- Not drawn: unsave (swipe or button), empty state, the "Ăn dặm" tab contents, sorting (most recent first, *(inferred)*).

---

### 313:1681 — 5a · Bật theo dõi ăn dặm (Turn on solid-food tracking)
**Annotation:** none.

**Text (reading order)**
- Top: back · spacer · BabySwitcher "Na" (with chevron).
- Hero Photo: h 200, r 24 (yellow gradient, teddy bear and wicker basket).
- Title (Bold 28): "Theo dõi ăn dặm" (Track solid food)
- Subtitle (Medium 15, lh 1.5, muted): "Ghi nhanh từng bữa, xem lại những món bé đã thử và đọc hướng dẫn từ đội chuyên môn." (Log each meal quickly, review the foods baby has tried and read guidance from the expert team.)
- Three benefit rows. Each has an icon chip (`care-bottle-soft #e5f1fb`, r 12, p 8, 18 px icon) and Medium 15 text:
  - Icon/plus: "Ghi bữa, món, lượng chỉ vài chạm" (Log meal, dish, amount in a few taps)
  - Icon/journal: "Lịch sử bữa ăn và danh sách món đã thử" (Meal history and the list of foods tried)
  - Icon/bookmark: "Thư viện ăn dặm: công thức, cách bắt đầu" (Solid-food library: recipes, how to start)
- Settings row (white, r 16): SemiBold 15 "Hiện “Ăn dặm hôm nay” trên Hôm nay" (Show "Solid food today" on Today) + **Toggle ON**.
- Banner (`surface-2`, Icon/heart, Medium 13 muted): "Hỏi bác sĩ của bé khi nào nên bắt đầu ăn dặm và cách phù hợp với bé." (Ask your baby's doctor when to start solids and which way suits your baby.)
- Primary Button: **"Bắt đầu theo dõi"** (Start tracking).

**Visual:** An onboarding screen with a large warm photo, a title, three icon bullet points, one toggle row, a soft medical note and a full-width teal button.

**Navigation (inferred):**
- "Bắt đầu theo dõi" → 5b.
- Entry point: the "Ăn dặm" tile on the Care tab (listed as "Sớm ra mắt" in 8a) or the Today customise sheet.

**Notes / not shown**
- No age gate is drawn (Na is 7 months), and there is no warning for a baby under 4 or 6 months.
- No start date, no allergy profile and no preferred method (Truyền thống / BLW) is asked.
- The enable setting is per baby (BabySwitcher present, *(inferred)*). It is unclear whether caregivers see or log solids.

---

### 313:1746 — 5b · Ăn dặm · Nhật ký (Solid food · Diary)
**Annotation:** none.

**Text (reading order)**
- Top: back · BabySwitcher "Na".
- Title (Bold 28): "Ăn dặm" (Solid food)
- Segmented: **"Nhật ký"** (Diary; selected) | "Thư viện ăn dặm" (Solid-food library).
- Week strip: 7 white cells, r 14, py 8, gap 6. Each cell has a weekday in Medium 11 muted, a date in Bold 16 `ink`, and a 5 px dot when the day has meals.
  - T2 5 •, T3 6 •, T4 7 •, **T5 8** (selected: `mint-deep` background, white text and dot), T6 9, T7 10, CN 11.
  - Future days have muted text and no dot.
- Section "Hôm nay · 2 bữa" (Today · 2 meals).
- **Meal cards.** Each is white, r 20, shadow-card, px 16, py 14. The top row has a Photo 56 (r 14), a slot and time line (Medium 12 muted), a dish name (Bold 16) and an "amount · reaction" line (Medium 13 muted). Under that is a row of ingredient chips (`surface-2`, r 999, px 10, py 4, SemiBold 12).
  1. "Bữa sáng · 08:10" (Breakfast · 08:10) / **"Cháo bí đỏ"** (Pumpkin congee) / "4 thìa · Bé thích" (4 spoons · Baby liked it) / chips "Gạo" (rice), "Bí đỏ" (pumpkin)
  2. "Bữa trưa · 11:30" (Lunch · 11:30) / **"Khoai lang nghiền"** (Mashed sweet potato) / "½ chén · Bình thường" (½ bowl · Normal) / chip **✦ "Khoai lang"**. This chip marks a first try: `sunshine-soft #fff4d6` with Icon/spark 12.
- Legend (Medium 12 muted): "✦ Lần đầu bé thử" (✦ First time baby tried it)
- Section "Món đã thử · 14" (Foods tried · 14) + link "Xem tất cả" (See all).
- Tried chips (white, 1 px `separator`, r 999, px 10, py 5, SemiBold 12): Gạo · Bí đỏ · Cà rốt (carrot) · Khoai lang (sweet potato) · Bơ (avocado) · Chuối (banana) · Táo (apple) · Bông cải (broccoli) · Đậu Hà Lan (peas) · "+5". 9 + 5 = 14 ✓.
- FAB (`mint-deep`, r 999, px 20, py 14, shadow, bottom right): Icon/plus 18 + Bold 16 white **"Ghi bữa"** (Log meal).

**Visual:** A diary page with a horizontal week strip (today highlighted in teal), two white meal cards with small photos and ingredient chips, a row of outlined "tried food" chips and a floating "Ghi bữa" button.

**Navigation (inferred):**
- Week cell → that day's meals.
- Meal card → meal detail or edit (not drawn).
- "Xem tất cả" → 5e.
- FAB → 5c.
- "Thư viện ăn dặm" segment → 5f.
- Back → Care tab.

**Notes / not shown**
- Meal photos are stock images (a teddy bear, a mother with baby), **not food**. Whether a meal photo is the user's own photo (the 5c note mentions "ảnh") or a recipe image is unclear.
- The legend uses the "✦" glyph, but the chip uses Icon/spark. They are different shapes.
- The weekday cells render left-aligned in the screenshot (text set to `w-full`), probably a layout slip.
- Not drawn: empty day, who logged a meal, any allergy or reaction marker on cards or the strip, and navigating to earlier weeks.

---

### 313:1872 — 5c · Ghi bữa ăn (Log a meal sheet)
**Annotation:** none.

The background is a copy of 5b. A scrim covers it, and the sheet starts at y 275.

**Text (reading order)**
- SheetHeader: "Ghi bữa ăn" (Log a meal) + close.
- Segmented meal slot (5 options): "Sáng" (Morning) · "Trưa" (Midday) · **"Chiều"** (Afternoon; selected) · "Tối" (Evening) · "Phụ" (Snack).
- Fields. Labels are SemiBold 13 muted. Boxes are white, 1 px `control-border`, r 14, px 14, py 13, Medium 15 `ink`.
  - "Giờ" (Time): Icon/clock, "16:20". "Ngày" (Date): Icon/cake, "Hôm nay" (Today). These two sit side by side.
  - "Món" (Dish): "Cháo cà rốt thịt gà" (Carrot & chicken congee)
- "Nguyên liệu" (Ingredients) chips:
  - Existing chips "Gạo" and "Cà rốt" (`surface-2`, leading Icon/close 12, so removable).
  - First-try chip **"Thịt gà · lần đầu"** (Chicken · first time; `sunshine-soft` + Icon/spark).
  - Add chip "Thêm" (Add; white, 1 px `control-border`, Icon/plus).
- "Lượng bé ăn" (How much baby ate), single select, px 10, py 8: "Vài thìa" (A few spoons) · **"½ chén"** (½ bowl; selected `mint-deep` / white) · "1 chén" (1 bowl) · "Tự nhập" (Enter manually).
- "Bé ăn thế nào" (How baby took it), three equal pills: **"Thích"** (Liked; selected, shown as `mint-soft` / `mint-text`) · "Bình thường" (Normal) · "Chưa hợp" (Not a fit yet).
- "Ghi chú (không bắt buộc)" (Note, optional): placeholder "Thêm ghi chú hoặc ảnh…" (Add a note or photo…) + Icon/camera 16.
- Primary Button: **"Lưu bữa"** (Save meal).

**Visual:** A tall white sheet over the diary. It has a five-way meal-slot control, time and date fields, a dish field, removable ingredient chips (one highlighted yellow as a first try), amount pills, reaction pills, a note field with a camera icon and a full-width save button.

**Navigation (inferred):**
- "Lưu bữa" → back to 5b/5d. The new meal appears in 5d at 16:20 ✓.
- Ingredient "Thêm" → ingredient picker (not drawn).
- "Tự nhập" → free amount input (not drawn).
- Date → date picker.
- Camera → photo picker.

**Notes / not shown**
- The first-try flag is **computed** by the app: chicken is not in the tried list *(inferred)*.
- The selected style differs between groups: amount uses `mint-deep`, reaction uses `mint-soft`.
- Slot labels differ between screens: 5c says "Sáng / Trưa", 5b says "Bữa sáng / Bữa trưa".
- The date field uses Icon/cake (the birthday icon).
- 5b's "4 thìa" (4 spoons) is not one of the amount presets, so it must come from "Tự nhập".
- No field for allergy or reaction symptoms, texture, who fed baby, or a recipe link (5g's "Ghi vào nhật ký" may prefill it, *(inferred)*).
- Not drawn: validation, an edit or delete variant, and how ingredients are suggested (free text or catalogue).

---

### 314:1786 — 5d · Lịch sử bữa ăn (Meal history)
**Annotation:** none.

**Text (reading order)**
- Top: back · BabySwitcher "Na".
- Title (Bold 28): "Lịch sử bữa ăn" (Meal history)
- Segmented: **"Bữa ăn"** (Meals; selected) | "Món đã thử" (Foods tried).
- Day groups. Headers are SemiBold 13 muted; each group is white, r 16. Rows have a Photo 48 (r 12), a dish name, a "time · amount · reaction" line and a chevron.
  - **"Hôm nay · Thứ Năm 08/10"** (Today · Thursday 08/10):
    - "Cháo cà rốt thịt gà" — "16:20 · ½ chén · Thích"
    - "Khoai lang nghiền" — "11:30 · ½ chén · Bình thường"
    - "Cháo bí đỏ" — "08:10 · 4 thìa · Thích"
  - **"Thứ Tư 07/10"** (Wednesday 07/10):
    - "Bơ nghiền chuối" (Mashed avocado & banana) — "11:15 · Vài thìa · Thích"
    - "Cháo bí đỏ" — "08:00 · 3 thìa · Bình thường"
  - **"Thứ Ba 06/10"** (Tuesday 06/10):
    - "Cà rốt hấp nghiền" (Steamed mashed carrot) — "11:00 · Vài thìa · Chưa hợp"

**Visual:** A plain day-grouped list with small photo thumbnails, newest day first and newest meal first.

**Navigation (inferred):**
- Row → meal detail or edit (not drawn).
- "Món đã thử" → 5e.
- Entry: "Xem tất cả" or the Nhật ký page.

**Notes / not shown**
- Today now has 3 meals after the 5c save, consistent with 5b's "2 bữa" before saving.
- Rows show neither the meal slot nor ingredients, and have no first-try marker.
- The amounts mix preset values ("Vài thìa", "½ chén") and free counts ("4 thìa", "3 thìa").
- Not drawn: 05/10 (it has a dot in 5b), date range filter, export, delete.

---

### 314:1901 — 5e · Món đã thử (Foods tried)
**Annotation:** none.

**Text (reading order)**
- Header as in 5d (title "Lịch sử bữa ăn"). Segmented: "Bữa ăn" | **"Món đã thử"** (selected).
- Food-group filter chips (horizontal scroll, the last one clipped):
  - **"Tất cả · 14"** (All · 14): selected, `ink` background, white text.
  - "Rau củ · 6" (Vegetables · 6) · "Tinh bột · 3" (Starches · 3) · "Đạm · 2" (Protein · 2) · "Trái cây · 3" (Fruit · 3). Unselected chips are white with 1 px `separator`.
  - 6 + 3 + 2 + 3 = 14 ✓, so each food belongs to exactly one group.
- List (white, r 16). Rows have no photo: food name in SemiBold 15, then "Lần đầu <date> · N lần" (First tried <date> · N times) in Medium 12 muted, and a reaction tag on the right (px 8, py 3, r 999, SemiBold 12). "Thích" uses `mint-soft` / `mint-text`; "Bình thường" and "Chưa hợp" use `surface-2` / `ink-muted`.
  | Food | English | First tried | Times | Tag |
  |---|---|---|---|---|
  | Thịt gà | Chicken | hôm nay (today) | 1 | Thích |
  | Khoai lang | Sweet potato | hôm nay | 1 | Bình thường |
  | Bơ | Avocado | 07/10 | 2 | Thích |
  | Chuối | Banana | 07/10 | 3 | Thích |
  | Cà rốt | Carrot | 06/10 | 2 | Chưa hợp |
  | Bí đỏ | Pumpkin | 01/10 | 6 | Thích |
  | Gạo | Rice | 28/09 | 9 | Thích |
- Footnote (Medium 12 muted): "Đây là ghi chép của gia đình bạn, không phải đánh giá hay khuyến nghị dinh dưỡng." (This is your family's record, not a nutrition assessment or recommendation.)

**Visual:** A compact list of foods with first-tried dates, counts and soft reaction tags under a row of food-group filter chips.

**Navigation (inferred):**
- Chip → filter by group.
- Row → food detail (not drawn; nor is any chevron).

**Notes / not shown**
- Sorted by first-tried date, newest first *(inferred)*.
- **Which reaction is shown is undefined.** Cà rốt shows "Chưa hợp" (from 06/10), but today's carrot-and-chicken congee was "Thích". The tag could be the first, the worst or the most frequent reaction.
- "Chưa hợp" is styled as neutral, not as a warning.
- **There is no allergy or reaction-symptom field anywhere** (rash, vomiting, etc.). There is also no "avoid" or "allergen" flag, and no allergen badges (egg, peanut, fish…).
- Count mismatch: 5b says "Món đã thử · 14" *before* chicken was saved, and 5e says 14 *including* chicken. One of them should be 15.
- Bơ shows "2 lần", but only one avocado meal is visible in 5d (others may be off-screen).
- The 5 foods outside the 9 in 5b's chip list are not listed by name here either; the list is cut at 7 rows.
- Food-group taxonomy: Rau củ, Tinh bột, Đạm, Trái cây. It probably needs more groups (Sữa/chế phẩm, Chất béo…), *(inferred)*.

---

### 314:1987 — 5f · Thư viện ăn dặm (Solid-food library)
**Annotation:** none.

**Text (reading order)**
- Top: back · BabySwitcher "Na". Title "Ăn dặm". Segmented: "Nhật ký" | **"Thư viện ăn dặm"** (selected).
- Search placeholder: "Tìm món, nguyên liệu, hướng dẫn…" (Search dishes, ingredients, guides…)
- Filter chips (horizontal scroll):
  - "Bộ lọc" (Filters; white, 1 px `separator`, Icon/sliders).
  - **"6–7 tháng"** and **"Công thức"** (Recipes): both selected, `mint-soft` / `mint-text`. "6–7 tháng" is probably pre-set from Na's age *(inferred)*.
  - "Truyền thống" (Traditional, spoon-fed) and "BLW" (baby-led weaning): unselected.
- Featured card (white, r 20, shadow-card): Photo h 150 (yellow gradient, teddy bear) · eyebrow in SemiBold 12 `mint-text`, "Hướng dẫn · Bắt đầu" (Guide · Getting started) · title in Bold 17, "Những bữa ăn dặm đầu tiên: chuẩn bị gì?" (The first solid meals: what to prepare?) · meta in Medium 12 muted, "6 phút đọc · cập nhật 09/2026" (6-min read · updated 09/2026).
- Section "Công thức · 6–7 tháng" (Recipes · 6–7 months) + "Xem tất cả".
- Recipe rows (Photo 56, chevron):
  - "Cháo bí đỏ cho bé mới tập" (Pumpkin congee for beginners) / "Công thức · 15 phút"
  - "Khoai lang nghiền mịn" (Smooth mashed sweet potato) / "Công thức · 20 phút"
  - "Bơ nghiền chuối" (Mashed avocado & banana) / "Công thức · 5 phút"

**Visual:** The library tab of the solid-food section. A search field, filter chips with two active, a large featured guide card and a short recipe list.

**Navigation (inferred):**
- Recipe row → 5g.
- Featured card → a guide article (4d layout, *(inferred)*).
- "Bộ lọc" → filter sheet (not drawn; the 4c pattern presumably).
- "Xem tất cả" → full recipe list.

**Notes / not shown**
- The selected filter-chip style is `mint-soft` with no ×, while 4b uses an `ink` "Bộ lọc · N" pill with removable tinted chips. The two are inconsistent.
- In recipe rows, "N phút" means preparation time, while in articles it means reading time. Both use the same "Category · N phút" format.
- The age band "6–7 tháng" is a one-month band, while the care library uses 0–3 / 3–6 / 6–12 / 1–2 tuổi. The two libraries need separate age taxonomies, or a range model.
- The featured card says "cập nhật" (updated) while articles say "rà soát" (reviewed). Two different date semantics.

---

### 314:2095 — 5g · Bài ăn dặm (công thức) (Recipe detail)
**Annotation:** none.

**Text (reading order)**
- Top: back · spacer · round white button with Icon/bookmark 18. **Layer name ≠ icon:** the layer is "more". This button duplicates "Lưu" in the bar. There is no BabySwitcher.
- Cover Photo: h 190, r 22 (yellow gradient, teddy bear, not food).
- Chips: **"Công thức"** (`care-bottle-soft #e5f1fb` / `care-bottle-ink #1d5f99`) · "6–7 tháng" (`surface-2`) · Icon/clock 12 + "15 phút" (`surface-2`).
- Title (Bold 26, lh 1.25): "Cháo bí đỏ cho bé mới tập"
- **Ingredients card** (white, r 20, shadow, px 16, py 14, gap 8): Bold 17 "Nguyên liệu" (Ingredients). Rows are Icon/check 14 + Medium 15:
  - "Gạo tẻ" (plain rice)
  - "Bí đỏ" (pumpkin)
  - "Nước sạch" (clean water)
  - **No quantities are given.**
- Heading (Bold 19): "Cách làm" (Method). Steps have a number badge (`mint-soft`, r 999, px 9, py 3, Bold 13 `mint-text`) and Regular 15 text, lh 1.55:
  1. "Vo gạo, nấu cháo thật nhừ." (Rinse the rice and cook the congee until very soft.)
  2. "Hấp chín bí đỏ, nghiền mịn." (Steam the pumpkin until cooked and mash it smooth.)
  3. "Trộn bí với cháo, để nguội bớt trước khi cho bé ăn." (Mix the pumpkin into the congee and let it cool a little before feeding.)
- Banner (`surface-2`, Icon/heart, Medium 13 muted): "Độ đặc, lượng và thời điểm thử món mới tuỳ từng bé — hãy hỏi bác sĩ nếu bạn còn băn khoăn." (Texture, amount and when to try new foods vary by baby — ask a doctor if you're unsure.)
- Byline (Medium 12 muted, no check icon here): "Đội chuyên môn Child Life · rà soát 09/2026"
- Article bar (fixed): "Lưu" pill (Icon/bookmark) · primary Button (flex-1, h 56) **"Ghi vào nhật ký"** (Log to diary).

**Visual:** A recipe page with the same cover, chip and title pattern as the article reader. A white ingredients card with check marks, then numbered steps, a soft medical note, the byline and a sticky bar with save and a large "log to diary" button.

**Navigation (inferred):**
- "Ghi vào nhật ký" → 5c, prefilled with dish "Cháo bí đỏ" and its ingredients.
- "Lưu" or top bookmark → saved; appears under 4f's "Ăn dặm" tab.
- Back → 5f.

**Notes / not shown.** Fields a recipe needs that are **not drawn**:
- servings / yield
- ingredient quantities and units
- texture stage (độ đặc: nghiền mịn / lợn cợn / cắt miếng)
- method tag (Truyền thống / BLW), although 5f filters by it
- allergens or "first-try caution" ingredients
- prep vs cook time (only one total "15 phút")
- tools, storage and reheating, nutrition notes
- sources, related recipes or guides, feedback ("Bài viết có hữu ích?") and "Aa", all of which 4d has

---

### 314:2169 — 5h · Hôm nay · thẻ ăn dặm (Today with the solid-food card)
**Annotation:** none.

**Text (reading order)**
- Top:
  - UserAvatar "M" (`card-peach #ffa58d`, Bold 14 `care-bottle-ink`) · BabySwitcher "Na" · spacer.
  - Round white "night" button with Icon/today 18 (sun; the Night care toggle, *(inferred)*).
- Title row: Bold 32 "Hôm nay" (Today) · spacer · pill "Tuỳ chỉnh" (Customize; white, 1 px `separator`, Icon/sliders 14).
- **Card "Ăn dặm hôm nay"** (Solid food today). White, r 20, shadow, px 16, py 14, gap 12.
  - Icon chip: `care-bottle-soft`, Icon/feed 18.
  - Medium 12 muted: "Ăn dặm hôm nay · 2 bữa" (Solid food today · 2 meals).
  - SemiBold 15: "Gần nhất: Khoai lang nghiền · 11:30" (Latest: mashed sweet potato · 11:30).
  - Bottom row: chip `sunshine-soft` + Icon/spark, "Lần đầu: Khoai lang" (First time: sweet potato) · spacer · `mint-deep` pill with Icon/plus, "Ghi bữa" (Log meal).
- **Card "Thẻ theo tuổi"** (Age card; layer name). Icon chip `sunshine-soft` + Icon/cake. Medium 12 muted: "7 tháng 2 tuần" (7 months 2 weeks). SemiBold 15: "Bé tập ngồi vững, thích cầm nắm" (Baby is learning to sit steadily and loves grasping).
- **TabDock** (10:169) with **NavBar v1.1** (`nav-bar #173d44`):
  - Tab/Today is active: white pill, "Hôm nay", `on-nav-active #173d44`.
  - The other tabs are Tab/Memories, Tab/Family and **Tab/Utilities** (Icon/grid, `nav-icon #b9cfcf`).
  - QuickLogButton 68 `mint-deep` (44:363: "Ghi nhanh (+): opens the quick-log chooser (Bú · Ngủ · Tã · Tăng trưởng)…"). Uses `shadow-nav` #173D4440 0/12/30.

**Visual:** The Today tab for Na with only two cards: a solid-food summary card with a yellow first-try chip and a teal "Ghi bữa" pill, and a one-line age card. Below that is empty space down to the dark tab dock.

**Navigation (inferred):**
- "Ghi bữa" → 5c.
- Card body → 5b.
- Age card → age-card detail (admin B05/B06 content).
- "Tuỳ chỉnh" → Today customise (it holds the 5a toggle).

**Notes / not shown**
- This card is the one the 5a toggle turns on ("Hiện “Ăn dặm hôm nay” trên Hôm nay").
- The card reflects the state before the 16:20 save: "2 bữa", latest 11:30.
- The quick-log chooser (Bú · Ngủ · Tã · Tăng trưởng) does not include solid food.
- **NavBar v1.1 has a "Utilities" (grid) tab** where v1.0.1 (8a) had a "Chăm sóc" tab. This is a navigation change: it is unclear whether the care library and solid food live under Utilities.
- Other Today cards (feeds, sleep and so on) are not drawn here.
- "Thẻ theo tuổi" is the age-card feature, listed as "Sớm ra mắt" in 8a.

---

### Cluster 4 — Thư viện chăm bé

#### Data model implied
**Article** (editorial, from the CMS):
| Field | Type | Example from design |
|---|---|---|
| id / slug | string | (for share link, *(inferred)*) |
| library | enum `cham_be` \| `an_dam` | Chăm bé (4f segment) |
| contentType | enum `article` \| `step_guide` \| `quick_qa` (+ `recipe`, `guide` in ăn dặm) | "Bài viết", "Hướng dẫn từng bước", "Hỏi nhanh" |
| title | string (localised) | "Giấc ngủ của bé sơ sinh" |
| topic | ref Topic | Giấc ngủ |
| ageRange | {fromMonths, toMonths} | 0–3 tháng, 0–12 tháng |
| readingMinutes | int | 6 |
| coverImage | image (16:9-ish, 343 × 190 crop; thumbnails 64/56/52 square) | crying newborn photo |
| byline / owner | string or ref (team) | "Đội chuyên môn Child Life" |
| reviewedAt | month-year | 09/2026 ("rà soát") |
| updatedAt / version | timestamp/int | drives "Mới cập nhật" and the 4f "đã được cập nhật" banner |
| body | ordered blocks | see below |
| related | ref[] Article | 2 items |
| sources | list (*not shown in app*) | — (admin B03) |
| locale | vi / en | (*not shown*) |
| status | draft / pending / approved / published (admin) | — |

**Body block types seen:** `paragraph`, `heading` (one level, Bold 19), `bulletList` (string[]), `figure` {image, caption}, `callout` {variant: warning/doctor, icon alert, title, body}.

**Topic** (editorial taxonomy): {id, label, icon, softToken, inkToken, order}. Six topics: Bú & sữa, Giấc ngủ, Mọc răng, Sốt & ốm vặt, Chăm hằng ngày, Phát triển.

**Filter facets** (static app config or editorial): age bands {0–3, 3–6, 6–12 tháng, 1–2 tuổi}; content types; reading-time buckets {<3, 3–6, >6}; sort {Liên quan nhất, …}.

**SavedItem** (per user, *(inferred)*: per user rather than per baby): {userId, contentId, library, savedAt ("lưu 02/10"), seenVersion (for the update banner)}.

**ArticleFeedback** (per user): {contentId, helpful: yes | not_yet, at}.

**Search:** a free-text query over title, body and tags (placeholder: "ngủ ngày, nấc, hăm tã").

#### Static vs per-baby vs editorial
- **Static app copy:** screen titles; "Đã lưu"; search placeholders; filter group labels; "Đặt lại"; "Xem N bài"; "Bài viết có hữu ích?" "Có/Chưa"; "Lưu/Đã lưu/Chia sẻ/Aa"; toast; "Bài viết liên quan"; "Mới cập nhật"; the "Hợp với {baby} · {age}" template; the update-banner template.
- **Per-baby:** only the personalisation row "Hợp với Teddy · 3 tuần" (driven by the baby's age).
- **Per-user:** saved list and saved dates, feedback, text-size preference.
- **Editorial (portal/CMS):** articles (all fields and blocks), topics (labels, icons, colours, order), cover and figure images, related links, reviewed date, which items are "Hợp với" for an age (or computed from ageRange), "Mới cập nhật" ordering, and the "Khi nào nên hỏi bác sĩ" callouts.

#### Admin-portal candidates
- **Articles** (B01 list / B02 editor):
  - Fields: title, library, topic, contentType, age range, reading time (auto from length?), cover image, body blocks (paragraph, heading, bullet list, figure with caption, callout), related articles, locale vi/en, status, reviewer, reviewedAt, 12-month re-review due, sources.
  - The B01 filters (library, topic, age, status, reviewer, language) and "Nhập từ HTML" fit this model. The app's 4c filter does not expose library or language.
- **Topics:** a CRUD list with icon and colour-token pair, ordering and locale labels. 4a hard-codes six; they should be editorial or a fixed enum, an owner decision.
- **Review** (B03/B04): drives "rà soát 09/2026". The "updated" banner (4f) needs a "significant update" flag on publish, so trivial edits do not notify readers.
- **Featured / "Mới cập nhật" / "Hợp với <age>" placement:** manual pinning or automatic ordering.
- **Feedback analytics:** "Có/Chưa" counts per article, to feed B01.
- **Images:** a cover library with crops (190 hero, 120 card, 64/56/52 thumbnails). Alt text is needed for accessibility (*not drawn*).

#### Images and illustrations used
- **Illustration/Photo** (131:758) everywhere. The rasters are photographic stock images; the gradients are placeholders behind them. These are **editorial cover photos**:
  - crying newborn (lavender)
  - sleeping baby (blue)
  - sleeping baby on navy
  - mother and baby (peach)
  - toys flat-lay (mint)
  - teddy bear and basket (yellow)
  - hand and fabric (mint)
- In-article figure photo (navy, sleeping baby).
- Icons: Icon/feed, sleep, star, alert, diaper, spark (topics); bookmark (outline and filled); link; check (byline, toast); alert (callout); retry (update banner); sliders; search; close; chevron-down/right; back.
- No emoji. The bullet list uses a dot SVG.

#### Open questions / gaps
1. **Sources/references** are reviewed in the admin portal (B03), but the reader (4d) shows none. Should the app show "Nguồn tham khảo"? (Health-content credibility; Q-039 asks who reviews.)
2. **Reviewer identity:** is it "Đội chuyên môn Child Life" only, or a named expert (B08 shows "Thu Hà · Nhóm chuyên môn")? What does the check icon in the byline certify?
3. Only the **Article** layout is drawn. There is no layout for **"Hướng dẫn từng bước"** or **"Hỏi nhanh"**.
4. Reading-time label is inconsistent ("6 phút" / "6 phút đọc"). Is it computed or entered?
5. **Library and language filters** exist in admin but not in the app filter. Does the app search only the current library? Is English content shown to `en` users, and what is the fallback when an article has no English version (D-012)?
6. **Update banner (4f):** which edits trigger it? The banner's article title does not match the list, and the article is not in the saved list (a design error).
7. **Saved items:** per user or per baby? Shared across the family? (*Inferred:* per user.)
8. **Share ("Chia sẻ"/link icon):** what does it share — a public web URL (needs a public article page, cf. story-links) or plain text? Do both the top-right icon and the bar button stay?
9. "Aa" text size: per-app setting or reader-only? Not drawn.
10. Personalisation "Hợp với Teddy · 3 tuần" in a multi-baby family: which baby, given there is no BabySwitcher?
11. Entry point: 8a lists "Thư viện chăm bé" under "Sớm ra mắt", and NavBar v1.1 (5h) replaces the Care tab with "Utilities". Where does the library live in v1.1?
12. Offline, empty search, error and caregiver states are not drawn.
13. Content-type and age-band taxonomies: are the age bands fixed app config or editorial? Care uses 0–3/3–6/6–12/1–2 tuổi; Ăn dặm uses "6–7 tháng".

---

### Cluster 5 — Ăn dặm (bé Na · 7 tháng)

#### Data model implied
**SolidsSettings** (per baby):
| Field | Type | Example |
|---|---|---|
| enabled | bool | after "Bắt đầu theo dõi" |
| showOnToday | bool | Toggle ON ("Hiện “Ăn dặm hôm nay” trên Hôm nay") |
| startedAt | date | (*inferred*; first food 28/09) |

**MealEntry** (per baby, user data; this is child data, so it must stay out of logs and analytics per CLAUDE.md):
| Field | Type | Example |
|---|---|---|
| id | string | |
| babyId | ref | Na |
| slot | enum `sang` \| `trua` \| `chieu` \| `toi` \| `phu` | Chiều; shown as "Bữa sáng/Bữa trưa" in 5b |
| at | datetime (date + time) | Hôm nay 16:20 |
| dishName | string (free text) | "Cháo cà rốt thịt gà" |
| ingredients | FoodRef[] | Gạo, Cà rốt, Thịt gà |
| firstTryFoods | derived: ingredients not tried before this meal | Thịt gà ("· lần đầu") |
| amount | enum `vai_thia` \| `nua_chen` \| `mot_chen` \| custom {value, unit (thìa/chén/…)} | ½ chén; "4 thìa", "3 thìa" (custom) |
| reaction | enum `thich` \| `binh_thuong` \| `chua_hop` | Thích |
| note | string? (optional) | placeholder "Thêm ghi chú hoặc ảnh…" |
| photo | image? | camera icon in the note field; 5b/5d thumbnails |
| recipeId | ref? | (*inferred*, from 5g "Ghi vào nhật ký") |
| createdBy / createdAt | user, ts | (*not shown*) |

**TriedFood** (per baby; derived from meals or stored):
| Field | Type | Example |
|---|---|---|
| food | ref Food (or free-text name) | Cà rốt |
| foodGroup | enum `rau_cu` \| `tinh_bot` \| `dam` \| `trai_cay` (…) | Rau củ |
| firstTriedAt | date | 06/10 ("Lần đầu 06/10"; "hôm nay") |
| timesTried | int | 2 ("2 lần") |
| reaction (summary) | enum Thích / Bình thường / Chưa hợp | Chưa hợp (aggregation rule undefined) |
| **allergyReaction** | — | **not in the design.** No symptom, severity, "suspected allergy" or "avoid" flag. |

**Food** (catalogue; editorial or seed data, *(inferred)*): {id, name vi/en, group, allergen flags?, earliest age?}. Needed so that "Thịt gà" maps to "Đạm" and so first-try detection works on free-text ingredients.

**Recipe** (editorial):
| Field | Type | Example | Drawn? |
|---|---|---|---|
| title | string | "Cháo bí đỏ cho bé mới tập" | yes |
| contentType | `recipe` | "Công thức" chip | yes |
| ageRange | months | 6–7 tháng | yes |
| totalMinutes | int | 15 phút | yes |
| coverImage | image | (placeholder photo) | yes |
| ingredients | {name, foodRef} list | Gạo tẻ, Bí đỏ, Nước sạch | yes (no qty) |
| ingredient quantity / unit | — | — | **no** |
| steps | ordered string[] | 3 steps | yes |
| tip / disclaimer banner | string | "Độ đặc, lượng và thời điểm…" | yes (generic) |
| reviewer + reviewedAt | | "Đội chuyên môn Child Life · rà soát 09/2026" | yes |
| feedingMethod | enum Truyền thống / BLW | (filter in 5f) | **no on detail** |
| texture | enum | — | **no** |
| servings | int | — | **no** |
| allergens | list | — | **no** |
| prep vs cook time, storage, tools, nutrition | | — | **no** |
| related, sources | | — | **no** |

**Solids guide** (editorial article in library `an_dam`): {eyebrow "Hướng dẫn · Bắt đầu", title, readingMinutes, updatedAt "cập nhật 09/2026", cover}. Presumably uses the 4d block model.

**AgeCard** (editorial, B05/B06): {ageWindow, headline "Bé tập ngồi vững, thích cầm nắm", icon cake}. The age label "7 tháng 2 tuần" is computed from the baby's DOB.

**Today card "Ăn dặm hôm nay"** (derived): mealCountToday (2), latest {dish, time}, firstTryToday list, plus the "Ghi bữa" action.

#### Static vs per-baby vs editorial
- **Static app copy:**
  - 5a: title, subtitle, three benefit lines, toggle label, doctor banner, button.
  - Screen titles; segment labels; meal-slot labels; amount presets; reaction labels; field labels; "Lần đầu bé thử" legend; "Lần đầu <date> · N lần" template.
  - The 5e footnote ("không phải đánh giá hay khuyến nghị dinh dưỡng"); FAB "Ghi bữa"; "Ghi vào nhật ký".
  - Food-group names (or editorial); filter chips "Truyền thống", "BLW".
- **Per-baby user data:** enable and showOnToday settings; meals (slot, time, dish, ingredients, amount, reaction, note, photo); tried-foods list and counts; week-strip dots; the Today card summary.
- **Editorial:** recipes; solids guides (the featured card); Food catalogue and groups *(inferred)*; age-band tagging ("6–7 tháng"); feeding-method tags; the recipe disclaimer (could be static); age cards on Today; 5a hero image (or static).

#### Admin-portal candidates
- **Recipes:** a CRUD list in the "Ăn dặm" library.
  - Editor fields: title, cover, age range, total time (ideally prep and cook), feeding method (Truyền thống/BLW), texture stage, servings, ingredient list with quantity, unit and food link (so "Ghi vào nhật ký" can prefill ingredients and first-try detection works), ordered steps (optionally with images), allergen flags, tip/disclaimer, related guides, reviewer, reviewedAt, sources, locale vi/en, status.
  - Workflow through the B03 review queue.
- **Solids guides:** same model as care articles, library `an_dam`, with eyebrow subcategory "Bắt đầu".
- **Food catalogue:** name vi/en, synonyms for search, food group, allergen flag, suggested minimum age, ordering. Drives the 5e group chips and the 5c ingredient picker.
- **Age bands / feeding-method taxonomy** for the 5f filters; featured slot ordering.
- **Age cards** (5h): already B05/B06.
- **Locale:** every editorial string vi + en (D-012).

#### Images and illustrations used
- Illustration/Photo stock photos on hero (5a), meal cards (5b, 5d), featured guide (5f), recipe rows and cover (5f, 5g). **None of them show food.** They are the same teddy, mother-and-baby and hand photos as cluster 4. Production needs real food photography for recipes, and a decision on whether user meal photos appear as thumbnails.
- Illustration/BabyFace (BabySwitcher).
- Icons: plus, journal, bookmark, heart (doctor/disclaimer banners), spark (first try), clock, cake (date field; age card), camera, sliders, search, chevron-right, check (ingredient list), feed (Today card), today/memories/family/grid (NavBar).
- The "✦" glyph in the 5b legend. Tokens: `sunshine-soft #fff4d6` = first try; `mint-soft` = Thích / selected filters; `care-bottle-soft #e5f1fb` = solids/feed accent and the "Công thức" chip.

#### Open questions / gaps
1. **Allergy and reaction tracking is missing.** There are only three "how baby ate" values (Thích/Bình thường/Chưa hợp).
   - Is a symptom/allergy record (rash, vomiting, swelling, time after eating, severity, "tạm tránh" flag) in V1.1?
   - If so, where does it show in 5c and 5e?
   - What safety copy goes with it (e.g. call emergency services for breathing problems)?
   - Owner decision needed.
2. **First-try detection:** is it computed from the food catalogue, or from a free-text ingredient match? How are synonyms and dish names handled ("Cà rốt" vs "Cà rốt hấp")? Is there a per-ingredient override?
3. **Tried-food reaction summary:** which reaction is shown (first, latest, worst)? Cà rốt shows "Chưa hợp" while the latest carrot meal is "Thích".
4. **Count mismatch:** 5b says 14 tried before chicken was saved, and 5e says 14 including chicken.
5. **Amount model:** presets ("Vài thìa", "½ chén", "1 chén") plus "Tự nhập". What units does "Tự nhập" allow (thìa, chén, ml, g)? 5b/5d show "4 thìa" and "3 thìa".
6. **Meal slot naming:** "Sáng/Trưa/Chiều/Tối/Phụ" (5c) vs "Bữa sáng/Bữa trưa" (5b). Is the slot inferred from the time?
7. **Recipe structure is thin:**
   - No quantities, servings, texture, allergens, BLW/traditional tag or prep/cook split. Should the CMS capture them even if the V1.1 UI does not show them?
   - Should "Ghi vào nhật ký" prefill dish and ingredients, and link `recipeId`?
8. **Library age bands:** "6–7 tháng" (solids) vs 0–3/3–6/6–12 (care). Is there one age-range model with free month ranges?
9. **Quick-log:** the QuickLogButton chooser lists Bú · Ngủ · Tã · Tăng trưởng only. Should "Ăn dặm" be added when tracking is on?
10. **Entry and IA:** 5a has no visible entry point. 8a lists "Ăn dặm" as "Sớm ra mắt", and NavBar v1.1 shows a "Utilities" tab instead of "Chăm sóc". Where do the solid-food diary and the library live? Also: can a solid-food entry appear in the existing Lịch sử/Thống kê?
11. **Age gating / safety:** should the app warn when enabling for a baby under 4–6 months? 5a only says "Hỏi bác sĩ…".
12. **Roles:** can caregivers (Người chăm) log meals or see the diary? Who logged each meal is not shown. Offline logging is not drawn.
13. **Meal photos:** the note says "hoặc ảnh". Do user photos become meal thumbnails (5b/5d)? This is child-related media: decide storage, privacy and retention, as for memories.
14. **Edit/delete meal, meal detail and food detail** screens are not drawn. Neither are the 5f filter sheet or the full recipe list ("Xem tất cả").
15. **Saved recipes:** 4f has an "Ăn dặm" segment, but its contents are not drawn.
16. **Night care** variants are not drawn for either cluster. CLAUDE.md requires Light + Night for done rows.

#### Coverage
I read all 14 frames with exactly one `get_design_context` each: 312:1446, 312:1574, 312:1679, 312:42000, 312:42116, 312:42236, 313:1681, 313:1746, 313:1872, 314:1786, 314:1901, 314:1987, 314:2095 and 314:2169. Every call returned inline code and a screenshot, so I needed no `get_metadata` or `get_screenshot`. No call failed and no rate limit was hit. 14 PNGs were saved to `docs/discovery/figma-extract/img/v11/`. No frame has a `data-annotation` or a prototype link.

---

## Part D: Sơ cứu trẻ em (7a–7i) and Dinh dưỡng theo giai đoạn (9a–9g)

Figma `sJLG1fAXKDnDr9YI6Yx8ex`, page "v1.1", read 2026-10-12. Only `get_design_context` was called, once per frame (16 calls, no failures, no rate limit). No Figma node was modified. Screenshots are saved as `docs/discovery/figma-extract/img/v11/<id with : → ->.png` (16 files).

Conventions are the same as `19-spending.md`. Strings are the rendered text, with an English gloss in parentheses. **(prototype link)** marks a node rendered as `<a … cursor-pointer>`; every link target is **inferred**. "(inferred)" marks anything the design does not state. **Annotations:** none of the 16 frames has a `data-annotation`. **Night care:** no Night variant is drawn; every frame is Light (`cloud #f6fcfb`).

**Mock scenario seen**
- Cluster 7 uses **"bé Na · 7 tháng"** (7b: "Sắp xếp theo tuổi bé Na · 7 tháng"; 7h: "Bé Na · 7 tháng tuổi · 7,8 kg"). It has no BabySwitcher, so nothing shows Teddy.
- Cluster 9 uses **Teddy**, at **7 months** in the 6–8-month stage, 7,8 kg and 68,5 cm, last measured 05/10. "Today" is **12/10/2026** (9c tooltip "12/10 · 720 ml"). This matches the spending cluster but contradicts the "Teddy is 3 weeks old" scenario in `17-vaccination.md`.
- 9e is a separate scenario: Teddy at **6 months, 6,2 kg**, below the normal range.
- 9g says "Đã uống 01/06/2026" (taken 01/06/2026). A baby who is 7 months old in October 2026 was about 3 months old in June, which is below the stated 6–36-month eligibility.
- 9a's Tiêm chủng tile still reads "Mũi tiếp theo 17/11" (Next shot 17/11).

**Colour tokens new in these clusters (raw hex, no token):** first-aid red `#db4a45` (text, buttons, number chips) and first-aid soft `#fcebe8` (emergency card, banner, "Khẩn cấp" tag, "Không được làm" card). The design also uses existing tokens: `error-soft #fbe9ea` (only inside the Sặc sữa icon), `sunshine #ffd166`, `sunshine-soft #fff4d6`, `care-bottle-accent #3b8fd9`, `care-bottle-ink #1d5f99`, `care-bottle-soft #e5f1fb`, `care-breast-soft #fceaf0`, and **`care/pump/soft #f5eafa`**. That last token is written with slashes (`var(--care\/pump\/soft)`), unlike every other kebab-case token. This is a token-naming inconsistency to flag.

---

### 429:2424 — 7a · Chăm sóc · lối vào Sơ cứu (Care tab with the First-aid entry)

**Annotation:** none.

**Diff against 8a (437:3596, `19-spending.md`).** The structure, chrome, tokens, TabDock (top 1318), the "Sớm ra mắt" grid and "Cài đặt" are identical except for these differences:
1. **New entry banner** between the search field and "Chăm hằng ngày": "Entry · Sơ cứu" **(prototype link)** → 7b. It is a full-width row, not a grid tile.
   - Background `#fcebe8`, radius 20, padding 14, gap 12.
   - Icon chip: `#db4a45`, radius 14, padding 10, **Icon/plus** 20 px (white per the screenshot).
   - Title "Sơ cứu trẻ em" (Child first aid): Bold 16, `#db4a45`.
   - Subline "25 tình huống · dùng khi không có mạng" (25 situations · works offline): Medium 12, `ink-muted`.
   - Icon/chevron-right 16.
2. **No "Chi tiêu" tile.** The "Chăm hằng ngày" grid has **5 tiles** in this order: Nhắc nhở, Tiêm chủng, Thống kê, Lịch sử, Tăng trưởng. Each has the same subline as 8a. None is a prototype link.
3. Nothing else differs. "Sớm ra mắt" has the same 5 tiles (Wonder Week, Thẻ theo tuổi, Mốc phát triển, Thư viện chăm bé, Ăn dặm). "Cài đặt" has "Tuỳ chỉnh theo dõi" and "Thông báo" / "Nhắc nhở, gia đình".

**Visual:** a soft-red full-width banner sits directly under the search field and is the most prominent element above the fold. The red is not a design-system token.

**Navigation:** banner → 7b (prototype link). There are no other links.

**Notes / not shown:**
- 7a and 9a were drawn from different bases. 7a has no Chi tiêu tile and 9a has no Sơ cứu banner, so the combined V1.1 Care tab (banner + 7 tiles) is **not drawn** (inferred: banner + Chi tiêu + Dinh dưỡng).
- No caregiver or Night variant is drawn.
- The banner uses Icon/plus as a "medical cross" stand-in.

---

### 433:2879 — 7b · Sơ cứu (First-aid index)

**Annotation:** none. Frame 375 × 2524. No TabDock; this is a pushed screen.

**Text (reading order)**
- **Top:**
  - Round white back button (Icon/back 20) **(prototype link)** → 7a.
  - Spacer.
  - Round white "save" button with **Icon/bookmark** 20. It is not linked; inferred to be "saved situations / favourites".
- **Title** "Sơ cứu" (First aid), Bold 30.
- **Subtitle** "Bình tĩnh, làm theo từng bước. Dùng được cả khi không có mạng." (Stay calm, follow step by step. Works even offline.), Medium 15 `ink-muted`, line-height 1.45.
- **Emergency card "Khẩn cấp"** (background `#fcebe8`, radius 20, padding 16, gap 10):
  - "Bé không thở, tím tái hoặc bất tỉnh?" (Baby not breathing, turning blue or unconscious?): Bold 16, `#db4a45`.
  - **"Gọi 115"** (Call 115) **(prototype link)** → 7h (inferred): full-width pill, `#db4a45`, py 15, Icon/phone 20, Bold 16 white.
  - **"Bắt đầu hồi sức tim phổi (CPR)"** (Start CPR) **(prototype link)** → 7i or the CPR detail (inferred): full-width white pill, py 13, Bold 15 `#db4a45`.
- **Search field** **(prototype link)** → 7c: white, 1 px `control-border #7e959a`, radius 14, Icon/search 18, placeholder "Hóc, sốt, bỏng, khó thở…" (Choking, fever, burns, trouble breathing…).
- **Filter chips** (one row, clipped at the right edge; horizontal scroll inferred; not linked):
  - Selected chip "Tất cả" (All): background `ink`, text `surface`, SemiBold 13.
  - Unselected chips (white, 1 px `separator #dce8e7` border): "Khẩn cấp" (Urgent), "Vết thương & bỏng" (Wounds & burns), "Côn trùng & động vật" (Insects & animals), "Sức khoẻ" (Health). The last chip is cut off.
- **Section "Khẩn cấp"** (Bold 17) with subline **"Sắp xếp theo tuổi bé Na · 7 tháng"** (Sorted for baby Na's age · 7 months), Medium 13 muted.
- **Section bodies:**
  - Khẩn cấp: a 2-column card grid. Each card is white, radius 20, shadow-card, padding 14, gap 8: Icon/FA 44 px, title Bold 15, subline Medium 12 line-height 1.4. Cards in one row stretch to equal height.
  - The other three sections ("Vết thương & bỏng", "Côn trùng & động vật", "Sức khoẻ"): a white list group, radius 16. Each row has Icon/FA 40 px, title SemiBold 15, subline Medium 12, and Icon/chevron-right 16.
- **Every card and row is a (prototype link)** to its detail frame.

#### Situation index (exact order; 25 items = "25 tình huống")
| # | Group (section) | Layout | Title (rendered) | Subline (rendered) | Icon layer | Notes |
|---|---|---|---|---|---|---|
| 1 | Khẩn cấp | grid r1 left | Hồi sức tim phổi (CPR) | Bé bất tỉnh, không thở hoặc thở ngáp (unconscious, not breathing or gasping) | Icon/FA/Hồi sức tim phổi | card layer "Card · Hồi sức tim phổi (CPR)" |
| 2 | Khẩn cấp | grid r1 right | Hóc dị vật (Choking on a foreign body) | Bé ho sặc, không khóc, không thở được (coughing/choking, can't cry, can't breathe) | Icon/FA/Hóc dị vật | → 7d/7e |
| 3 | Khẩn cấp | grid r2 left | Sặc sữa (Milk aspiration) | Sữa trào lên, bé ho sặc, tím tái (milk comes up, coughing, turning blue) | Icon/FA/Sặc sữa | the only icon drawn inline: `error-soft` circle with a bottle (rects `#b2bdc2` border, `#f5a385`, `#f7ebd6`) |
| 4 | Khẩn cấp | grid r2 right | Ngừng thở (sơ sinh) (Apnoea, newborn) | Bé ngừng thở, da tái hoặc tím (stops breathing, pale or blue skin) | Icon/FA/Ngừng thở | **Layer name ≠ text:** "Card · Ngừng thở ở trẻ sinh non" (apnoea in preterm infants) |
| 5 | Khẩn cấp | grid r3 left | Co giật (Seizure) | Người cứng, giật tay chân, mắt đảo, có thể do sốt cao (stiff, jerking limbs, eyes rolling, may be from high fever) | Icon/FA/Co giật | 7c shows "Co giật do sốt" with a different icon |
| 6 | Khẩn cấp | grid r3 right | Sốc phản vệ (Anaphylaxis) | Khó thở, khò khè, sưng mặt, phát ban (trouble breathing, wheeze, facial swelling, rash) | Icon/FA/Sốc phản vệ | |
| 7 | Khẩn cấp | grid r4 left | Uống nhầm thuốc, hoá chất (Swallowed medicine/chemicals) | Thuốc người lớn, nước tẩy, chất lạ (adult medicine, bleach, unknown substances) | Icon/FA/Uống nhầm hoá chất | |
| 8 | Khẩn cấp | grid r4 right | Tai nạn giao thông (Traffic accident) | Bé bị ngã xe, va chạm (fell off a vehicle, collision) | Icon/FA/Tai nạn giao thông | |
| 9 | Vết thương & bỏng | list | Chảy máu cam (Nosebleed) | Máu chảy từ một hoặc hai bên mũi | Icon/FA/Chảy máu cam | |
| 10 | Vết thương & bỏng | list | Vết thương chảy máu (Bleeding wound) | Đứt tay, trầy, có dị vật đâm vào (cuts, grazes, embedded object) | Icon/FA/Vết thương chảy máu | |
| 11 | Vết thương & bỏng | list | Băng bó cơ bản (Basic bandaging) | Vết trầy, đứt tay nhỏ | Icon/FA/Băng bó cơ bản | |
| 12 | Vết thương & bỏng | list | Bỏng nước sôi (Scalds) | Nước sôi, canh nóng, hơi nóng (boiling water, hot soup, steam) | Icon/FA/Bỏng nước sôi | |
| 13 | Vết thương & bỏng | list | Bong gân (Sprain) | Ngã, trượt chân, khớp sưng đau | Icon/FA/Bong gân | |
| 14 | Vết thương & bỏng | list | Gãy xương (Fracture) | Sưng, biến dạng, đau dữ dội sau ngã | Icon/FA/Gãy xương | |
| 15 | Vết thương & bỏng | list | Tổn thương ở mắt (Eye injury) | Bụi, dị vật, sưng đỏ, chảy máu ở mắt | Icon/FA/Tổn thương mắt | |
| 16 | Côn trùng & động vật | list | Chó cắn (Dog bite) | Vết cắn, vết cào của chó, mèo (bites/scratches from dogs, cats) | Icon/FA/Chó cắn | |
| 17 | Côn trùng & động vật | list | Ong đốt (Bee sting) | Sưng đỏ, đau rát tại chỗ | Icon/FA/Ong đốt | |
| 18 | Côn trùng & động vật | list | Kiến ba khoang (Rove beetle / Paederus) | Vết đỏ rát, phồng rộp | Icon/FA/Kiến ba khoang | |
| 19 | Côn trùng & động vật | list | Côn trùng vào tai (Insect in the ear) | Bé ngứa, đau, quấy, ôm tai | Icon/FA/Côn trùng vào tai | |
| 20 | Côn trùng & động vật | list | Rắn cắn (Snake bite) | Có hai vết răng nanh rõ (two clear fang marks) | Icon/FA/Rắn cắn | |
| 21 | Sức khoẻ | list | Say nắng, say nóng (Sunstroke / heat illness) | Chóng mặt, nhức đầu, người nóng sau khi ở ngoài nắng | Icon/FA/Say nắng | |
| 22 | Sức khoẻ | list | Đo thân nhiệt (Taking temperature) | Cách đo đúng và khi nào cần đi khám (how to measure, when to see a doctor) | Icon/FA/Đo thân nhiệt | a how-to, not an emergency |
| 23 | Sức khoẻ | list | Ngộ độc thực phẩm (Food poisoning) | Nôn, đau bụng, tiêu chảy | Icon/FA/Ngộ độc thực phẩm | |
| 24 | Sức khoẻ | list | Nhiễm lạnh (Cold exposure / hypothermia) | Run, tay chân lạnh, tái | Icon/FA/Nhiễm lạnh | |
| 25 | Sức khoẻ | list | Vàng da sơ sinh (Newborn jaundice) | Phân biệt sinh lý và bệnh lý (physiological vs pathological) | Icon/FA/Vàng da sơ sinh | |

**Layout / components / tokens:** described above. The Icon/FA/* icons are SVG assets with **no component description**. In the screenshot each one is a colourful flat pictogram in a soft-tinted circle. They are a new icon family, separate from the line-icon set.

**Visual:** a calm header, a red emergency block with two actions, a search field, chips, then a 2-column grid of urgent cards followed by three grouped lists.

**Navigation:**
- Back → 7a.
- "Gọi 115" → 7h (inferred).
- "Bắt đầu hồi sức tim phổi (CPR)" → CPR flow (7i or its detail, inferred).
- Search → 7c.
- Each of the 25 cards/rows → its detail frame.

**Notes / not shown:**
- How "Sắp xếp theo tuổi" (sorted by age) changes the order is not shown. The order above is for a 7-month-old. Inferred: age-irrelevant items (e.g. "Vàng da sơ sinh", "Ngừng thở (sơ sinh)") would move down for older babies, but here they are not moved.
- The filter chips duplicate the section headings. Filtered states are not drawn.
- The saved/bookmark list is not drawn.
- No source/review footer appears on the index (one appears on detail pages).

---

### 428:2346 — 7c · Sơ cứu · Tìm kiếm (search)

**Annotation:** none. Frame 375 × 812 (screenshot). **No prototype links** in this frame.

**Text (reading order)**
- **Top:** focused search field (white, **2 px `mint-deep` border**, radius 14, px 14 py 12). It contains Icon/search 18, the typed query **"sốt"** (fever; Medium 15 `ink`), a spacer and Icon/close 16 (clear). To its right, "Huỷ" (Cancel), SemiBold 15 `mint-text`. There is no back button.
- "3 tình huống" (3 situations), Medium 13 muted.
- **Results:** white group, radius 16, same row style as 7b.
  1. "Co giật do sốt" (Febrile seizure) / "Sốt cao, người cứng, giật tay chân" (high fever, stiff, jerking limbs). Icon/FA/Co giật do sốt: a thermometer on a pink circle, a **different asset** from 7b's Icon/FA/Co giật.
  2. "Ngộ độc thực phẩm" / "Đi viện khi sốt cao trên 39°C, lừ đừ" (go to hospital if fever above 39 °C, lethargic).
  3. "Nhiễm lạnh" / "Trẻ có thể sốt nhẹ, mệt mỏi, run" (may have a mild fever, tired, shivering).
- "Tìm nhanh" (Quick search), Bold 15.
- Chips (white, separator border, SemiBold 13, lower-case): khó thở (trouble breathing), tím tái (turning blue), chảy máu (bleeding), nôn (vomiting), phát ban (rash), côn trùng (insects).

**Visual:** a results list in the 7b row style plus a wrap of suggestion chips. There is no keyword highlight in the results.

**Navigation:** none drawn. Inferred: rows → detail, "Huỷ" → 7b, a chip fills the query.

**Notes / not shown:**
- Result sublines are **different from 7b**. They look like the passage that matched the query (a search snippet from the article body), and the title "Co giật do sốt" ≠ 7b "Co giật". So search covers body text, and each situation has synonyms or alternative titles (inferred).
- Vietnamese diacritic-insensitive matching is not shown.
- No-results state and recent searches are not drawn.
- "Tìm nhanh" chips: whether they are fixed or editorial is not stated.

---

### 427:2048 — 7d · Hóc dị vật · dưới 1 tuổi (Choking, under 1 year)

**Annotation:** none. Frame about 375 × 1844 (bottom bar at y 1743.75).

**Text (reading order)**
- **Top:** back **(prototype link)** → 7b; spacer; small "Gọi 115" pill (`#db4a45`, px 14 py 8, Icon/phone 16, Bold 14 white). The pill is not linked here.
- **Tags:** "Khẩn cấp" (background `#fcebe8`, Bold 12 `#db4a45`) and "Dùng được khi không có mạng" (Available offline; `surface-2`, Bold 12 muted).
- Title "Hóc dị vật", Bold 30, line-height 1.2. Subline "Bé ho sặc, không khóc, không thở được" (same as the 7b card), Medium 15 muted.
- **Illus/FA/Vỗ lưng** (back blows): raster PNG 343 × 214.375, radius 24. A 3D-rendered mother holds an infant face-down along her forearm and strikes its back.
- **Banner** (`sunshine-soft`, radius 14, Icon/alert 16): "Nếu bé còn ho, khóc được: để bé tự ho ra, không vỗ, theo dõi sát." (If baby can still cough or cry: let them cough it out, don't strike, watch closely.)
- **Segmented control** (`surface-2`, radius 14, padding 4): **"Dưới 1 tuổi"** selected (white, radius 10, SemiBold 14) | "Từ 1 tuổi" **(prototype link)** → 7e.
- Section "Làm theo các bước" (Follow the steps), Bold 17.
- **Step cards** (white, radius 20, shadow-card, padding 16, gap 12). Each has a number circle (30 px `mint-deep`, Bold 15 `on-mint-deep`), a title (Bold 17) and body text (Medium 15, line-height 1.5).
  1. **"Vỗ lưng 5 lần"** (5 back blows): "Đặt bé nằm sấp dọc cẳng tay, đầu thấp hơn ngực, đỡ cằm bé. Dùng gót bàn tay vỗ mạnh 5 lần giữa hai bả vai."
     - Count row (indented 42): 5 outlined circles (26 px, 1.5 px `mint-deep` border, Bold 12 `mint-text`, "1"–"5") + "lần" (times), Medium 13 muted.
  2. **"Ấn ngực 5 lần"** (5 chest thrusts): "Lật bé nằm ngửa, đầu thấp. Đặt 2 ngón tay giữa ngực, ngay dưới đường nối hai núm vú, ấn mạnh 5 lần."
     - Same count row, plus **Illus/FA/Ấn ngực** PNG 311 × 194.375, radius 24.
  3. **"Lặp lại đến khi dị vật ra"** (Repeat until the object comes out): "Xen kẽ 5 lần vỗ lưng và 5 lần ấn ngực. Bé lả đi, không thở: gọi 115 ngay."
- **"Không được làm"** (Don't) card: background `#fcebe8`, radius 20, padding 16. The header has an X in a red circle (`#db4a45`, padding 3, Icon/close 14) and the title in Bold 16 `#db4a45`. Bullets (6 × 13 dot SVG), Medium 15:
  - "Thò tay vào miệng bé để móc dị vật" (Reaching into the mouth to hook the object out)
  - "Dốc ngược bé lên" (Holding baby upside down)
- **"Đưa bé đi viện ngay khi"** (Take baby to hospital immediately if) card: `sunshine-soft`, radius 20. The header has Icon/alert in a `sunshine #ffd166` circle, Bold 16 `ink`. Bullets:
  - "Bé tím tái, lả đi, ngừng thở: gọi 115"
  - "Đã lấy được dị vật nhưng bé vẫn ho, khó thở"
- **Footer** (Medium 12 muted): "Nội dung tham khảo, không thay thế chẩn đoán của bác sĩ. Được chuyên gia y tế rà soát qua Child Life." (Reference content, not a substitute for a doctor's diagnosis. Reviewed by medical experts via Child Life.)
- **Bottom bar** (white, shadow 0 −4 8 0.08, pt 12 pb 30 px 16, gap 10):
  - Primary **Button "Làm theo từng bước"** (Follow step by step; h56, Text/body-strong Medium 17) **(prototype link)** → 7f.
  - Red "Gọi 115" pill (px 20 py 15, Icon/phone 20, Bold 16). Not linked.

**Layout / components:** the Button (8:33) label breaks the "1–2-word verb" rule. New patterns: tag pills, step card with optional counter and illustration, Don't card, Go-to-hospital card, segmented age switch.

**Visual:** a long reading page with a hero illustration, numbered step cards, red and yellow warning blocks, and a sticky bottom bar with "step mode" and "call".

**Navigation:**
- Back → 7b.
- "Từ 1 tuổi" → 7e.
- "Làm theo từng bước" → 7f.
- Neither "Gọi 115" button is linked in this frame; elsewhere they lead to 7h.

**Notes / not shown:** the count dots in reading mode are static (they are not filled). Step mode (7f) makes them tappable.

---

### 429:2573 — 7e · Hóc dị vật · từ 1 tuổi (Choking, 1 year and over)

**Annotation:** none. Frame about 375 × 1653 (bottom bar at y 1552.75).

**Text (reading order):** same as 7d except for the following.
- The segmented control has **"Từ 1 tuổi" selected**, and "Dưới 1 tuổi" is a **(prototype link)** → 7d.
- Hero image: still **Illus/FA/Vỗ lưng** (the same PNG as 7d, an infant back blow). This is wrong for this age (flag).
- Banner: unchanged, "…không vỗ…".
- **Steps** (no count rows):
  1. "Đứng sau lưng bé" (Stand behind the child): "Quỳ hoặc đứng phía sau, vòng tay ôm eo, để bé hơi cúi người về trước." Includes **Illus/FA/Ép bụng** (abdominal thrust) PNG 311 × 194.375: a woman kneels behind a toddler boy.
  2. "Đặt nắm tay trên rốn" (Fist above the navel): "Nắm tay đặt trên rốn, dưới xương ức. Tay kia ôm lấy nắm tay."
  3. "Ấn mạnh vào trong, lên trên" (Thrust hard in and up): "Ấn nhanh, dứt khoát. Lặp lại đến khi dị vật bật ra."
- "Không được làm", "Đưa bé đi viện ngay khi" and the footer are word-for-word the same as 7d.
- Bottom bar is the same ("Làm theo từng bước" + "Gọi 115").

**Navigation:**
- "Dưới 1 tuổi" → 7d is the only link.
- Back and "Làm theo từng bước" are not linked in this copy.

**Notes / not shown:**
- No thrust count is given for ≥ 1 year. 7d gives 5 + 5.
- The ≥ 1 year step mode is not drawn.
- The default tab selection is not stated. Inferred: from the baby's age (7b sorts by age).

---

### 429:2711 — 7f · Từng bước · Vỗ lưng (Step mode, back blows)

**Annotation:** none. Frame 375 × about 823. The bottom bar frame is h 42 at y 780.38, but its buttons are 52 or 56 px tall and overflow it, which is a design artefact.

**Text (reading order)**
- **Top:** round white **close** button (Icon/close 20; not linked) | spacer | small "Gọi 115" pill (not linked).
- **Progress:** 3 segments (h 6, radius 3, gap 6). Segment 1 is `mint-deep`; segments 2–3 are `surface-2`.
- "Hóc dị vật · dưới 1 tuổi · Bước 1/3" (Choking · under 1 · Step 1/3), SemiBold 13 muted.
- Illus/FA/Vỗ lưng, 343 × 214.375, radius 24.
- Title **"Vỗ lưng 5 lần"**, Bold 28. Body (Medium **18**, line-height 1.5) is the same as step 1 of 7d.
- **Counter card** (white, radius 20, shadow, px 16 py 14, gap 10):
  - "Chạm để đếm" (Tap to count), Medium 14 muted | **"3 / 5"**, Bold 16 `ink`.
  - Dots: 5 × **44 px** circles, gap 10. Dots 1–3 are filled `mint-deep` with Bold 16 `on-mint-deep`; dots 4–5 are outlined (2 px `mint-deep`) with Bold 16 `mint-text`.
- Footnote, centred, Medium 12 muted: **"Màn hình luôn sáng trong khi bạn làm theo hướng dẫn."** (The screen stays on while you follow the guide.)
- **Bottom bar** (`cloud`):
  - Secondary Button **"Quay lại"** (Back; h52 `surface-2`) at **opacity 40 % = disabled on step 1**.
  - Primary **"Bước tiếp"** (Next step; h56) **(prototype link)** → 7g.

**Visual:** full-screen guided mode with large type, a big illustration and large tap targets for counting.

**Navigation:** "Bước tiếp" → 7g. Close is not linked; inferred to go back to 7d.

**Notes / not shown:**
- What happens when the count reaches 5 is not shown (auto-advance? haptic?).
- Step 3/3 ("Lặp lại…") in step mode is not drawn.
- How the loop of back blows and chest thrusts is presented is not drawn.

---

### 429:2779 — 7g · Từng bước · Ấn ngực (Step mode, chest thrusts)

**Annotation:** none. Same layout as 7f.

**Text:**
- Progress: 2 of 3 filled. Label "Hóc dị vật · dưới 1 tuổi · Bước 2/3".
- **Illus/FA/Ấn ngực** (343 × 214.375): a woman kneels and presses two fingers on a supine infant's chest, with a teal arrow.
- Title **"Ấn ngực 5 lần"**. Body: "Lật bé nằm ngửa, đầu thấp. Đặt 2 ngón tay giữa ngực, ngay dưới đường nối hai núm vú, ấn mạnh 5 lần."
- Counter **"1 / 5"** (dot 1 filled). Same footnote.
- Bottom: "Quay lại" **enabled** (no opacity) and "Bước tiếp". Neither is linked.

**Navigation:** the top **"Gọi 115"** pill is a **(prototype link)** → 7h. Close is not linked.

**Notes:** "Bước tiếp" on step 2 would lead to step 3/3 (not drawn).

---

### 429:2848 — 7h · Gọi 115 (Call 115 sheet)

**Annotation:** none. Frame 375 × 822.375. **No prototype links.**

**Background:** a copy of 7g (step 2/3, 1/5) under a full-frame **Scrim** (`rgba(12,23,25,0.32)`).

**Sheet** (white, top radius 28, px 16, pb 34, gap 14, top at y 309.38):
- **SheetHeader** (37:293) title **"Gọi cấp cứu 115"** (Call emergency 115), with close.
- **Baby context row** (`surface-2`, radius 16, px 14 py 12):
  - Avatar: `card-peach #ffa58d` circle, padding 9, with **Icon/cake** 20. It is not Illustration/BabyFace.
  - **"Bé Na · 7 tháng tuổi · 7,8 kg"** (Baby Na · 7 months old · 7.8 kg), SemiBold 15.
  - **"Đang xử lý: Hóc dị vật"** (Currently handling: choking), Medium 13 muted.
- **"Nói rõ với tổng đài"** (Tell the operator clearly), Bold 15.
- **Checklist** (24 px `mint-deep` numbered circles, Bold 12; text Medium 15):
  1. "Bé mấy tuổi, chuyện gì đã xảy ra" (Baby's age, what happened)
  2. "Bé còn thở, còn tỉnh không" (Is baby still breathing, conscious?)
  3. "Địa chỉ chính xác, điểm dễ nhận biết" (Exact address, landmarks)
  4. "Số điện thoại để gọi lại" (A call-back phone number)
- **"Gọi 115"**: full-width red pill (`#db4a45`, px 20 py 15, Icon/phone 20, Bold 16 white). It is the primary action.
- Secondary Button (h52 `surface-2`) **"Báo cho cả nhà"** (Notify the whole family).
- Footnote, centred, Medium 12 muted: **"Cả nhà nhận thông báo kèm vị trí của bạn."** (The family gets a notification with your location.)

**Emergency number and call behaviour:**
- The number is **115**. It is the only number anywhere in the cluster.
- The sheet is an interstitial before dialling: the user reads the checklist, then taps "Gọi 115". Inferred: this opens the OS dialler with `tel:115`; there is no in-app calling.
- It is opened from any "Gọi 115" button. The 7g top pill is linked to it.
- "Báo cho cả nhà" sends a **push to all family members with the user's location**. This implies location permission and sharing location in a notification, which is a privacy- and permission-relevant new capability (inferred).
- The baby's age, weight and current situation are pre-filled, to read out to the operator.

**Visual:** a bottom sheet over the dimmed step screen. Red is used only for the call button.

**Notes / not shown:**
- No confirmation before dialling, and no post-call state.
- Location-permission prompt, family notification copy and recipients are not shown.
- Behaviour offline (calling works, but the family push needs network) and outside Vietnam (e.g. 112/911) is not stated.
- Whether weight comes from the latest growth log is inferred (7,8 kg = 9b's latest weight).

---

### 434:3155 — 7i · CPR · Ép ngực (nhịp) (CPR chest compressions, metronome)

**Annotation:** none. Frame 375 × about 869 (bottom bar at y 827.38). No motion data is exposed in the design context.

**Text (reading order)**
- **Top:** close (not linked) | small "Gọi 115" **(prototype link)** → 7h.
- **Progress:** **4 segments**, 3 filled.
- **"Hồi sức tim phổi · dưới 1 tuổi · Bước 3/4 · Chu kỳ 2"** (CPR · under 1 · Step 3/4 · Cycle 2), SemiBold 13 muted.
- **Illus/FA/Ép tim sơ sinh** (infant CPR) PNG 343 × 214.375, radius 24. An adult does two-finger compressions on an infant lying on a mat, with a down arrow; a toddler watches.
- Title **"Ép ngực 30 lần"** (30 chest compressions), Bold 28.
- Body (Medium 17, line-height 1.5): **"2 ngón tay giữa ngực, ấn sâu khoảng 4 cm. Ấn theo nhịp tiếng bíp."** (Two fingers mid-chest, press about 4 cm deep. Press with the beep.)
- **Counter card** (white, radius 24, shadow, px 18 py 16, gap 16, row):
  - **Ring** 96 px: a track ellipse plus a progress-arc ellipse. The arc is ≈ 60 % (18/30), a `mint-deep` arc on a light track per the screenshot. Centre text **"18"** (Bold 30 `ink`) over **"/ 30"** (Medium 12 muted).
  - **Info column** (gap 8):
    - **Beat row:** a 12 px red dot (`#db4a45`, radius 6), inferred to pulse on each beat, + **"110 nhịp/phút"** (110 beats/min), Bold 17.
    - "Tiếng bíp và rung theo nhịp" (Beep and vibration on the beat), Medium 13 muted.
    - Pill (`mint-soft`): **"Tiếp: thổi ngạt 2 lần"** (Next: 2 rescue breaths), Bold 12 `mint-text`.
- Footnote, centred: **"Màn hình luôn sáng. Dừng ép không quá 10 giây."** (Screen stays on. Don't pause compressions for more than 10 seconds.)
- **Bottom bar:** secondary **"Tạm dừng"** (Pause; h52) | primary **"Bé đã thở lại"** (Baby is breathing again; h56). Neither is linked.

**Rhythm and timer data:**
| Item | Value |
|---|---|
| Compression rate | **110 /min** (beat interval ≈ 545 ms); inside the usual 100–120 range |
| Compressions per set | **30**; counter shows the current count (18) with a ring |
| Breaths per set | **2** ("Tiếp: thổi ngạt 2 lần"), i.e. 30:2 |
| Cycle counter | "Chu kỳ 2" (cycle 2); no total or target is shown |
| Step structure | 4 steps; this is step 3 (the other 3 are not drawn; inferred: check response/call → open airway → compressions → breaths) |
| Depth | "khoảng 4 cm" (about 4 cm), infant two-finger technique |
| Feedback | audio beep **and** haptic vibration on each beat; pulsing red dot (inferred); screen kept awake |
| Pause limit | ≤ 10 s (copy only; no timer drawn) |
| Set duration | 30 ÷ 110/min ≈ 16.4 s (derived) |

**Navigation:** "Gọi 115" → 7h.

**Notes / not shown:**
- The breaths step (4/4), how a cycle ends, and the auto-advance from 30 compressions to breaths are not drawn.
- The pause state, the "Bé đã thở lại" outcome (recovery position?), and the ≥ 1 year variant (rate, depth 5 cm, one hand) are not drawn.
- Whether counting is automatic (driven by the metronome) or by tap is not stated. Inferred: automatic, since there is no "Chạm để đếm" here, unlike 7f.
- No mute control for the sound.

---

### 440:3934 — 9a · Chăm sóc · ô Dinh dưỡng (Care tab with the Nutrition tile)

**Annotation:** none. Frame 375 × 1411.

**Diff against 8a (437:3596):** the same as 8a plus **one 7th tile** in "Chăm hằng ngày".
- **Tile order:**
  1. Nhắc nhở
  2. Tiêm chủng
  3. Thống kê
  4. Lịch sử
  5. Tăng trưởng
  6. Chi tiêu ("4,2 tr tháng này")
  7. **Dinh dưỡng** (new)
- **Dinh dưỡng tile:** **(prototype link)** → 9b. Icon chip `care-bottle-soft #e5f1fb` with **Icon/spark**; the asset is stroked blue, different from the greyed Wonder Week spark. Title "Dinh dưỡng" (Nutrition). Subline **"Giai đoạn 6–8 tháng"** (Stage 6–8 months).
- The Chi tiêu tile is also a (prototype link), as in 8a.
- The grid is now 4 rows; the last row holds Dinh dưỡng alone.
- **No Sơ cứu banner** (the 7a entry is absent).
- "Sớm ra mắt" is unchanged, and **"Ăn dặm" is still listed as coming soon** although 9b talks about solids.
- "Cài đặt" is unchanged.
- TabDock is at y 1318. The frame was not lengthened, so the dock overlaps the Cài đặt group in the screenshot.

**Visual:** a seventh white tile with a blue spark.

**Navigation:** Dinh dưỡng → 9b. Chi tiêu → 8b.

**Notes / not shown:**
- The tile subline is the current stage label, from the baby's age.
- Tile state for babies older than 36 months, or before the profile has a DOB, is not drawn.
- Reusing Icon/spark (Wonder Week's icon) for Nutrition could confuse users.

---

### 440:3767 — 9b · Dinh dưỡng · giai đoạn hiện tại (Nutrition, current stage)

**Annotation:** none. Frame 375 × 1715.

**Text (reading order)**
- **Top:** back **(prototype link)** → 9a | spacer | BabySwitcher "Teddy".
- Title "Dinh dưỡng", Bold 28.
- **Stage card** (`care-growth-soft #fdede2`, radius 24, padding 18, gap 8):
  - "7 tháng · giai đoạn 6–8 tháng" (7 months · 6–8-month stage), SemiBold 13 `care-growth-ink #9a4a14`.
  - **"Bắt đầu ăn dặm"** (Starting solids), Bold 26.
  - "Sữa vẫn là nguồn dinh dưỡng chính. Thêm 2–3 bữa ăn dặm mỗi ngày, tăng dần độ đặc." (Milk is still the main source. Add 2–3 solid meals a day, gradually thicker.) Medium 14, line-height 1.5.
  - Link "Xem các giai đoạn" (See the stages), SemiBold 13 `mint-text` **(prototype link)** → 9f.
- **Milk card "Sữa"** **(prototype link)** → 9c. White, radius 20, shadow, padding 16.
  - Header: chip `care-bottle-soft` + Icon/feed; "Sữa mỗi ngày" (Milk per day), Bold 16; "Tham khảo cho bé bú bình" (Reference for bottle-fed babies), Medium 12 muted; chevron.
  - **Range bar** (311 × 46):
    - Track `surface-2`, h 10, radius 5.
    - Reference band `care-bottle-soft` with a 1 px `care-bottle-accent #3b8fd9` border, **600–900 ml**.
    - Marker: 16 px ellipse at **720 ml**.
    - Labels "600" and "900 ml" below (Medium 11 muted); "720 ml" above (Bold 11 `care-bottle-ink`).
    - The scale works out to 0.2827 px/ml, so the track spans **0–1100 ml** (derived).
  - Body (Medium 13 muted): "Teddy trung bình 720 ml/ngày (7 ngày qua) · 4–5 cữ, 180–240 ml mỗi cữ. Bú mẹ: cho bú theo nhu cầu." (Teddy averages 720 ml/day over the last 7 days · 4–5 feeds of 180–240 ml. Breastfeeding: on demand.)
- **Growth card** **(prototype link)**. Target inferred: the existing Tăng trưởng / WHO screen, or 9e when below range.
  - Chip `care-growth-soft` + Icon/ruler; "Tăng trưởng so với chuẩn WHO" (Growth vs the WHO standard), Bold 16; "Lần đo gần nhất 05/10" (Last measured 05/10); chevron.
  - Two tiles (`surface-2`, radius 14, padding 12):
    - "Cân nặng" (Weight) **"7,8 kg"** (Bold 18) + tag "Trong khoảng chuẩn" (Within the normal range; `mint-soft`, Bold 11 `mint-text`).
    - "Chiều dài" (Length) **"68,5 cm"** + the same tag.
- **Section "Cần chú ý ở giai đoạn này"** (Pay attention at this stage). White group, radius 16; rows have a 34 px chip, title SemiBold 15, subline Medium 12, chevron.
  - **Sắt** (Iron) **(prototype link)** → 9d. Chip `care/pump/soft #f5eafa` + Icon/drop. Subline "Dự trữ từ lúc sinh giảm dần · thịt, trứng, gan" (Stores from birth run down · meat, egg, liver).
  - **Kẽm** (Zinc). Chip `care-diaper-soft` + Icon/star. "Hỗ trợ tăng trưởng · thịt, cá, trứng". Not linked.
  - **Vitamin D**. Chip `care-bottle-soft` + Icon/sunrise. "Hỏi bác sĩ nếu bé bú mẹ hoàn toàn" (Ask a doctor if exclusively breastfed). Not linked.
  - **Vitamin A** **(prototype link)** → 9g. Chip `care-breast-soft #fceaf0` + Icon/heart. "Uống bổ sung tại trạm y tế" (Supplement given at the health station). Tag `sunshine-soft` **"1–2/12"** (next campaign window, 1–2 December).
- **Section "Một ngày tham khảo"** (A sample day). White, radius 20, rows py 10, chips `surface-2`, no chevrons:
  - Sáng (Morning) / "Sữa · 180–240 ml" (Icon/feed)
  - Trưa (Noon) / "Ăn dặm · bột/cháo rây + thịt, rau" (Solids · porridge + meat, veg; Icon/spark)
  - Chiều (Afternoon) / "Sữa · 180–240 ml"
  - Tối (Evening) / "Ăn dặm · 2–3 thìa đến ½ bát nhỏ" (2–3 spoons to ½ small bowl)
  - Đêm (Night) / "Sữa theo nhu cầu" (Milk on demand; Icon/sleep)
- **Section "Gợi ý cho Teddy"** (Suggestions for Teddy). Two cards (`mint-soft`, radius 20, px 16 py 14; title Bold 15 `mint-text`, body Medium 13):
  - "Mỗi ngày một món giàu sắt" (One iron-rich dish a day): "Thịt bò, gan gà, lòng đỏ trứng nghiền vào bột. Kèm rau quả giàu vitamin C giúp hấp thu sắt."
  - "Tăng dần độ đặc" (Gradually thicker): "Từ bột loãng sang cháo rây, nghiền thô khi bé quen. Chưa thêm muối, đường, nước mắm."
- **Footer** (Medium 12 muted): "Nội dung tham khảo theo WHO và Bộ Y tế, chuyên gia Child Life rà soát. Không thay thế tư vấn của bác sĩ. Thuốc, vi chất dạng uống: theo chỉ định bác sĩ." (Reference content per WHO and the Ministry of Health, reviewed by Child Life experts. Not a substitute for a doctor's advice. Oral medicines and micronutrients: only as prescribed.)

**Visual:** a peach hero card, then milk and growth summary cards, a nutrient list, a sample-day timeline and mint suggestion cards.

**Navigation:**
- Back → 9a.
- "Xem các giai đoạn" → 9f.
- Milk card → 9c.
- Growth card → growth (inferred).
- Sắt → 9d.
- Vitamin A → 9g.
- Kẽm and Vitamin D have chevrons but are not linked (detail not drawn).

**Notes / not shown:**
- Breastfed-only and mixed-feeding variants of the milk card are not drawn. The copy covers breastfeeding with one sentence.
- Wording when the average is outside 600–900 ml is not drawn.
- Wording when there is no bottle data in the last 7 days is not drawn.
- **"Gợi ý cho Teddy"** looks personalised, but the content is generic for the stage. Inferred: rules select tips (see 9e footer "quy tắc chuyên gia nhập từ portal").

---

### 440:4105 — 9c · Lượng sữa theo giai đoạn (Milk amount by stage)

**Annotation:** none. **Layer name ≠ text:** the frame is "Lượng sữa theo giai đoạn"; the title reads "Lượng sữa" (Milk amount).

**Text (reading order)**
- **Top:** back **(prototype link)** → 9b | BabySwitcher.
- Title "Lượng sữa", Bold 28. Subtitle (Medium 14 muted): "Tham khảo cho bé bú bình. Mỗi bé mỗi khác: cho bé bú theo dấu hiệu đói, no. Bú mẹ: theo nhu cầu." (For bottle-fed babies. Every baby differs: feed by hunger and fullness cues. Breastfeeding: on demand.)
- **Chart card "14 ngày qua"** (Last 14 days):
  - Header: SemiBold 17, with subline "Vùng màu: khoảng tham khảo 600–900 ml" (Shaded band: reference range 600–900 ml).
  - Chart 311 × 206: y labels 0 / 500 / 1000 (Medium 10 muted), `separator` gridlines, a `care-bottle-soft` band from 600 to 900.
  - **14 bars** (w 12, radius 5, `care-bottle-accent` at 55 % opacity); today's bar is at full opacity.
  - X labels on alternate days: 29, 1, 3, 5, 7, 9, 11, plus **12** in Bold `ink`. The other days hold zero-width-space placeholders.
  - **Tooltip** (`ink` background, radius 10): "12/10 · 720 ml", SemiBold 11 white.
  - Scale 0.13636 px/ml. **Bar values (29/9 → 12/10):** 690, 740, 700, 760, 720, 680, 730, 710, 750, 700, 720, 690, 740, 720 ml.
  - The last-7-day mean is 718.6, which 9b shows as "720" ✓ (rounded to 10 ml).
- **Section "Theo giai đoạn"** (By stage). Group rows: stage label (Bold 14, w 92) | amount (SemiBold 15) | detail (Medium 12 muted).
  | Stage | Amount | Detail |
  |---|---|---|
  | Tuần đầu (First week) | 30–60 ml/cữ | 8–12 cữ |
  | 1 tháng | 90–120 ml/cữ | 6–8 cữ · tối đa ~960 ml/ngày (max ~960 ml/day) |
  | 2–5 tháng | 120–180 ml/cữ | 5–6 cữ |
  | **6–8 tháng** (highlighted row `care-bottle-soft`, white tag **"Hiện tại"** (Current) Bold 11 `care-bottle-ink`) | 180–240 ml/cữ | 4–5 cữ · + 2–3 bữa ăn dặm |
  | 9–11 tháng | ~600–800 ml/ngày | 3–4 cữ · + 3 bữa, 1–2 bữa phụ |
  | 12–24 tháng | ~400–500 ml/ngày | Sữa là bữa phụ · 3 bữa chính (milk is a snack · 3 main meals) |
- **Banner** (`surface-2`, Icon/alert): "Bé thường xuyên bú nhiều hoặc ít hơn khoảng này: trao đổi với bác sĩ nhi." (If baby often drinks more or less than this range, talk to a paediatrician.)
- **Footer:** **"Nguồn: AAP, WHO · số liệu nhập từ Child Life portal, chuyên gia rà soát 09/2026."** (Source: AAP, WHO · figures entered from the Child Life portal, expert-reviewed 09/2026.)

**Visual:** a bar chart with a reference band, then a stage table with the current stage highlighted.

**Navigation:** back → 9b only.

**Notes / not shown:**
- The 9b "600–900" range has no explicit row in the table. The 6–8-month row gives 180–240 × 4–5 = 720–1200 ml, which does not match 600–900 (gap).
- The units mix per-feed amounts (ml/cữ) and per-day amounts (ml/ngày).
- The bars presumably sum the bottle logs per day (bottle + pumped?). Which feed types count is not stated.
- Bar tap / tooltip behaviour is inferred.

---

### 440:4217 — 9d · Vi chất · Sắt (Micronutrient, iron)

**Annotation:** none.

**Text (reading order)**
- **Top:** back **(prototype link)** → 9b | BabySwitcher.
- **Head:** chip `care/pump/soft #f5eafa`, radius 18, padding 14, Icon/drop 28 (purple stroke). Next to it, **"Sắt"** (Bold 28) and "Quan trọng từ 6 tháng" (Important from 6 months; Medium 14 muted).
- **"Vì sao cần"** (Why it's needed) card (white, radius 20, padding 16, no shadow): "Lượng sắt dự trữ từ lúc sinh giảm dần sau 4–6 tháng. Sắt giúp tạo máu và phát triển não bộ." (Iron stores from birth fall after 4–6 months. Iron helps make blood and develop the brain.)
- **Section "Thực phẩm giàu sắt cho bé"** (Iron-rich foods for baby). Static chips: Thịt bò (beef), Gan gà (chicken liver), Lòng đỏ trứng (egg yolk), Cá (fish), Đậu, đỗ (beans, pulses), Rau xanh đậm (dark greens), Ngũ cốc tăng cường sắt (iron-fortified cereal).
- **Tip** card (`mint-soft`): "Mẹo" (Tip) / "Ăn kèm rau quả giàu vitamin C (cam, cà chua, bông cải) giúp hấp thu sắt tốt hơn." (Eat with vitamin-C-rich fruit and veg — orange, tomato, broccoli — to absorb iron better.)
- **Section "Theo giai đoạn"**. Rows have no icon or chevron, and the current stage is not highlighted:
  - 0–4 tháng / "Bé đủ sắt dự trữ, chưa cần thêm" (enough stores, nothing extra needed)
  - 4–6 tháng / "Bé bú mẹ: hỏi bác sĩ về bổ sung sắt" (breastfed: ask the doctor about iron supplements)
  - 6–23 tháng / "Mỗi ngày có thịt, cá hoặc trứng" (meat, fish or egg every day)
  - 12 tháng / "Bác sĩ có thể kiểm tra thiếu máu" (the doctor may check for anaemia)
- **Banner** (`sunshine-soft`): "Sắt dạng thuốc chỉ dùng theo chỉ định của bác sĩ. Thừa sắt có thể gây hại." (Iron medicine only on prescription. Too much iron can be harmful.)
- **Footer:** "Nguồn: WHO 2023, AAP · chuyên gia Child Life rà soát."

**Visual:** an article template with a header icon, a "why" card, food chips, a tip, an age table, a warning and the sources.

**Navigation:** back only.

**Notes:**
- This frame is the **template for a micronutrient article** (iron here; zinc and vitamin D are presumably the same template).
- "12 tháng" is a milestone that overlaps 6–23 tháng.
- There is no per-baby content apart from the BabySwitcher.

---

### 441:3917 — 9e · Gợi ý theo tăng trưởng · dưới chuẩn (Growth-based suggestions, below range)

**Annotation:** none.

**Text (reading order)**
- **Top:** back **(prototype link)** | BabySwitcher.
- Title **"Cân nặng của Teddy"** (Teddy's weight), Bold 26.
- **Chart card** (white, radius 20, shadow, padding 16):
  - Header: "Theo chuẩn WHO · bé trai" (WHO standard · boy), SemiBold 14 | **"6,2 kg · 6 tháng"** (6.2 kg · 6 months), Bold 14 `care-bottle-ink`.
  - Chart: a single flattened SVG named "WHO" (311 × 150) with no axes or labels. It shows a `mint-soft` band (normal range), a dashed teal median and Teddy's blue line with 6 dots, all under the band by the end.
  - Legend: `mint-soft` swatch "Khoảng chuẩn" (Normal range); blue line "Teddy".
- **Banner** (`sunshine-soft`, Icon/alert): **"2 lần đo gần nhất của Teddy thấp hơn khoảng chuẩn. Đây không phải chẩn đoán. Hãy cho bé đi khám dinh dưỡng để bác sĩ đánh giá."** (Teddy's 2 most recent measurements are below the normal range. This is not a diagnosis. Take baby for a nutrition check so a doctor can assess.)
- **Section "Gợi ý trong lúc chờ khám"** (Suggestions while you wait for the appointment). Group rows with `mint-soft` chips; no chevrons, not linked:
  - "Duy trì sữa đều đặn" (Keep milk regular) / "Không giảm cữ sữa khi bắt đầu ăn dặm" (Don't cut milk feeds when starting solids). Icon/feed.
  - "Bữa ăn dặm đặc dần, đủ chất" (Thicker, nutritious solids) / "Thêm thịt, cá, trứng và một ít dầu ăn vào bột" (Add meat, fish, egg and a little oil to porridge). Icon/spark.
  - "Ghi lại bữa ăn và cữ bú" (Log meals and feeds) / "Mang theo khi đi khám để bác sĩ dễ đánh giá" (Bring them to the appointment). Icon/journal.
  - "Đo lại sau 2 tuần" (Re-measure in 2 weeks) / "Đo cùng giờ, cùng cân" (Same time of day, same scale). Icon/ruler.
- **Actions:**
  - Primary Button **"Nhắc đo lại sau 2 tuần"** (Remind me to re-measure in 2 weeks; h56).
  - Secondary **"Xuất báo cáo cho bác sĩ"** (Export a report for the doctor; h52).
  - Neither is linked.
- **Footer:** **"Gợi ý chung theo quy tắc chuyên gia nhập từ portal, không thay thế chẩn đoán."** (General suggestions from expert rules entered in the portal; not a diagnosis.)

**WHO measurement and threshold implied:**
- **Measurement:** **weight-for-age** (the title "Cân nặng", the "6,2 kg" label), on the **WHO boys** chart (sex-specific).
- **Threshold:** "below the normal range". The existing app defines the normal range as **P3–P97**: `app_vi.arb` growth-standard strings describe it as "Within the WHO normal range (3rd–97th percentile)" and "Under the 3rd percentile (20d)". So the lower edge is P3 (inferred; the band is not labelled).
  - Check: WHO boys at 6 months have P3 ≈ 6.4 kg and a median ≈ 7.9 kg, so 6.2 kg < P3 ✓.
- **Trigger rule:** the **2 most recent measurements** are both below the lower edge. One low reading does not trigger it (inferred).
- **Follow-up:** a re-measurement reminder in **14 days**.

**Visual:** a growth curve with a yellow caution banner, non-alarming tips, and two actions.

**Navigation:** back only. The entry point is not drawn. Inferred: the 9b growth card, or "Gợi ý cho Teddy", switches to this when the rule fires, or a notification opens it.

**Notes / not shown:**
- Length-for-age and weight-for-length variants are not drawn. An above-range (> P97) variant is not drawn, though the frame name "· dưới chuẩn" (below range) suggests siblings exist.
- The chart in 9e is a single flattened SVG. The app's existing WHO chart (`growth_standards_screen.dart`) should be reused.
- The report-export format is not shown.
- The scenario conflicts with 9b (Teddy 7 months, 7,8 kg, in range).

---

### 441:4018 — 9f · Các giai đoạn dinh dưỡng (Nutrition stages)

**Annotation:** none. **Layer name ≠ text:** the frame is "Các giai đoạn dinh dưỡng"; the title reads "Các giai đoạn" (Stages).

**Text (reading order)**
- **Top:** back **(prototype link)** → 9b | BabySwitcher.
- Title "Các giai đoạn", Bold 28.
- **Vertical timeline.** Each stage row has a rail SVG (14 × 94) and a card (radius 18, px 16 py 14, gap 4): age (SemiBold 12 muted), title (Bold 16), detail (Medium 13 muted, line-height 1.45).
- **Rail states:** past = filled grey-teal dot + line; **current = `mint-deep` dot**; future = hollow dot + line.
- **The current card** has a `care-growth-soft` background, with the age in `care-growth-ink`.

| Age | Title | Detail | State |
|---|---|---|---|
| 0–1 tháng | Những ngày đầu (The first days) | Bú mẹ hoàn toàn theo nhu cầu · 8–12 cữ | past |
| 1–3 tháng | Bú đều nhịp (Regular feeding) | Cữ dài dần · bú mẹ hoặc sữa công thức | past |
| 4–5 tháng | Chuẩn bị ăn dặm (Getting ready for solids) | Vẫn chỉ cần sữa · quan sát dấu hiệu sẵn sàng | past |
| **6–8 tháng** | **Bắt đầu ăn dặm** (Starting solids) | 2–3 bữa/ngày · chú ý sắt, kẽm | **current** |
| 9–11 tháng | Ăn thô hơn (Coarser food) | 3 bữa + 1–2 bữa phụ · thức ăn cầm tay (finger food) | future |
| 12–23 tháng | Ăn cùng gia đình (Eating with the family) | 3 bữa + 2 bữa phụ · sữa ~400–500 ml | future |
| 24–36 tháng | Tự lập bữa ăn (Independent eating) | Đa dạng nhóm thực phẩm · hạn chế đồ ngọt | future |

**Visual:** a progress-style timeline with the current stage tinted peach.

**Navigation:** back only. The cards are not linked; inferred that a past or future stage could open its own 9b-style page.

**Notes:**
- The stage boundaries **differ** between screens: 9f (0–1, 1–3, 4–5, 6–8, 9–11, 12–23, 24–36), 9c (Tuần đầu, 1 tháng, 2–5, 6–8, 9–11, 12–24) and 9d (0–4, 4–6, 6–23, 12).
- The age range (0–36 months) matches the vitamin A eligibility.
- No source footer on this page.

---

### 441:4100 — 9g · Lịch uống vitamin A (Vitamin A schedule)

**Annotation:** none. Frame 375 × 812.

**Background page**
- Back **(prototype link)** | BabySwitcher.
- Title "Vitamin A", Bold 28. Text (Medium 15): "Trẻ 6–36 tháng được uống vitamin A miễn phí 2 lần mỗi năm tại trạm y tế phường, xã." (Children 6–36 months get free vitamin A twice a year at the ward/commune health station.)
- **Group:**
  - "Đợt tháng 6" (June round): a `mint-deep` check circle (Icon/check 14) and the subline "Ngày 1–2/6 · Đã uống 01/06/2026" (1–2 June · Taken 01/06/2026).
  - "Đợt tháng 12" (December round): a `sunshine-soft` chip with Icon/clock and the subline "Ngày 1–2/12/2026 · trạm y tế phường" (1–2/12/2026 · ward health station).

**Sheet** (over the Scrim, white, top radius 28, top at y 449):
- SheetHeader **"Nhắc uống vitamin A"** (Vitamin A reminder).
- Medium 14 muted: **"Nhắc trước 1 ngày, lúc 8:00 sáng 30/11. Lịch cụ thể theo thông báo của trạm y tế địa phương."** (Reminder 1 day before, 8:00 am on 30/11. The exact schedule follows the local health station's announcement.)
- **Group:**
  - "Người nhận" (Recipients) / "Mẹ, Bố", with Icon/family and a chevron. Inferred: the chevron opens a member picker.
  - "Thêm vào lịch điện thoại" (Add to phone calendar), with Icon/today and a **Toggle ON** (23:262).
- Primary Button **"Đặt nhắc"** (Set reminder).

**Visual:** a short info page with two campaign rounds and a reminder sheet open.

**Navigation:** back only. Nothing in the sheet is linked.

**Notes / not shown:**
- The "Đã uống" (taken) status is per-baby. How it is recorded (a tap on the June row?) is not drawn.
- The campaign dates (1–2/6 and 1–2/12) are national campaign days, editorial and set per year.
- "1 day before at 8:00" looks like a fixed default; there is no time picker.
- The calendar export needs OS calendar permission.
- The mock is inconsistent: the dose was given at about 3 months old, but eligibility starts at 6 months.

---

### Cluster 7 (Sơ cứu)

#### Data model implied
| Entity / field | Type | Example from design |
|---|---|---|
| **FirstAidSituation**.id / slug | string | hoc-di-vat (inferred) |
| .title | localized string | "Hóc dị vật"; search title can differ ("Co giật do sốt") |
| .summary (card subline) | localized string | "Bé ho sặc, không khóc, không thở được" |
| .group | enum: Khẩn cấp · Vết thương & bỏng · Côn trùng & động vật · Sức khoẻ | 8 / 7 / 5 / 5 items |
| .icon | asset ref (Icon/FA/*) | Icon/FA/Hóc dị vật |
| .order (within group) + age relevance | int + age window | "Sắp xếp theo tuổi bé Na · 7 tháng" |
| .isUrgent / tags | bool / tag list | "Khẩn cấp", "Dùng được khi không có mạng" |
| .keywords / synonyms | string[] | sốt → Co giật do sốt, Ngộ độc thực phẩm, Nhiễm lạnh |
| .variants[] (by age) | list {label, ageMin, ageMax} | "Dưới 1 tuổi" / "Từ 1 tuổi" |
| variant.heroImage | raster asset | Illus/FA/Vỗ lưng (PNG) |
| variant.preWarning | string | "Nếu bé còn ho, khóc được: …" |
| variant.steps[] | {n, title, body, image?, repeatCount?} | {1, "Vỗ lưng 5 lần", …, count 5} |
| variant.donts[] | string[] | "Thò tay vào miệng bé để móc dị vật", "Dốc ngược bé lên" |
| variant.goToHospitalIf[] | string[] | "Bé tím tái, lả đi, ngừng thở: gọi 115" |
| disclaimer / reviewer | string + review metadata | "Được chuyên gia y tế rà soát qua Child Life." |
| **CprProtocol** (per age band) | rate, compressions, breaths, depth, steps | 110/min, 30, 2, ~4 cm, 4 steps |
| **Guided session** (local only) | currentStep, tapCount, cycle, paused | Bước 1/3, 3/5; Bước 3/4 · Chu kỳ 2 |
| **EmergencyCall** context | babyName, ageMonths, weightKg, situation | "Bé Na · 7 tháng tuổi · 7,8 kg", "Đang xử lý: Hóc dị vật" |
| **FamilyAlert** | sender, babyId, situation, location (lat/lng), sentAt, recipients | "Cả nhà nhận thông báo kèm vị trí của bạn." |
| Saved situations (bookmark) | per-user list | top-right Icon/bookmark in 7b (inferred) |
| Emergency number | string, per country | "115" |

#### Static vs per-baby vs editorial
- **Static app copy:**
  - Screen chrome: "Sơ cứu", the subtitle, "Làm theo các bước", "Không được làm", "Đưa bé đi viện ngay khi", "Chạm để đếm".
  - Step-mode footnotes, the 115 sheet checklist, the "Báo cho cả nhà" copy, the tags.
  - The number 115 (could be config).
- **Per-baby / per-session:**
  - Age used for sorting and for the default age tab ("bé Na · 7 tháng").
  - 7h baby context (name, age, weight from the latest growth log, current situation).
  - The CPR age band (under 1 / from 1).
  - Guided-session counters (ephemeral, on device).
  - The family alert with location (sent to the family).
- **Editorial (portal):**
  - All 25 situations: title, summary, group, order, age relevance, keywords, variants, steps, images, don'ts, hospital criteria, disclaimer and review info.
  - CPR parameters per age band.
  - The "Tìm nhanh" chips (probably).
  - The filter categories.

#### Admin-portal candidates
- **Situations list:**
  - CRUD with group (4 categories), per-group order, an urgent flag (grid vs list), age relevance windows for "sort by age", and an icon from the FA icon set.
  - Locale vi/en with the same ids (D-012).
- **Situation body:** age variants, each with a hero image, pre-warning, ordered steps (title, body, optional image, optional repeat count for the tap counter), don'ts, go-to-hospital criteria, and whether the variant supports guided "step mode".
- **Search:** synonyms/keywords per situation, alternative titles, curated "Tìm nhanh" chips.
- **CPR protocol per age band:** rate (110), compressions (30), breaths (2), depth (4 cm), step list, pause limit (10 s).
- **Review metadata:** reviewer, review date and sources per situation. 7d only says "Được chuyên gia y tế rà soát qua Child Life"; 9c shows the stronger "rà soát 09/2026" pattern.
- **Offline bundle:** content must be cached on device ("dùng khi không có mạng"). The portal needs a versioned publish and a client sync.
- **Emergency number per country/locale** (115 for VN).

#### Images and illustrations used
- **Illus/FA/*** raster PNGs, 3D-rendered characters in an editorial, Pixar-like style: Vỗ lưng (infant back blows), Ấn ngực (infant chest thrusts), Ép bụng (toddler abdominal thrust), Ép tim sơ sinh (infant CPR). These are editorial images needed per step/variant, and they need alt text.
- **Icon/FA/*** SVG pictograms (25 + "Co giật do sốt"): colourful icons in tinted circles, with no component description. Sặc sữa is built from rectangles on `error-soft`.
- Line icons: Icon/plus (entry), back, bookmark, phone, search, close, alert, chevron-right, cake (7h avatar), check.
- No BabyFace in cluster 7. 7h uses Icon/cake on `card-peach` as the baby avatar.

#### Open questions / gaps
1. **115 behaviour:** does it dial `tel:115` directly, or always open the 7h sheet first (one extra tap in an emergency)? What about non-VN locales (112/911)?
2. **"Báo cho cả nhà":** sending the user's location is a new data type (privacy, consent, location permission, retention). Who receives it (all members, caregivers)? Does it work offline (it can't)? Push copy is not drawn.
3. **Content governance:** the medical content needs a named reviewer and a review date. 7d's footer has no date or source, unlike 9c/9d.
4. **CPR:** rate fixed at 110 or configurable? Are compressions auto-counted by the metronome or tapped? Steps 1, 2 and 4, the ≥ 1 year variant, the pause state and the "Bé đã thở lại" outcome are missing. Sound when the phone is on silent, and haptics on Android?
5. **7e uses the infant back-blow hero image** for ≥ 1 year (wrong image). There is no thrust count for ≥ 1 year.
6. **Sort by age:** the rule and the age windows per situation are not specified. The 7-month order looks the same as a default order.
7. **Bookmark (7b top-right):** no saved list is designed.
8. The **Care tab with banner + Chi tiêu + Dinh dưỡng** is never drawn together (7a vs 9a), and no caregiver or Night variants exist.
9. Search: diacritic-insensitive matching, the no-result state, and whether search covers step text (7c snippets suggest it does).
10. Mock baby "bé Na · 7 tháng" (cluster 5) vs Teddy elsewhere.

---

### Cluster 9 (Dinh dưỡng theo giai đoạn)

#### Data model implied
| Entity / field | Type | Example from design |
|---|---|---|
| **NutritionStage**.id | string | 6-8m |
| .ageMinMonths / .ageMaxMonths | int | 6 / 8 (9f covers 0–36) |
| .label | string | "6–8 tháng" |
| .title | string | "Bắt đầu ăn dặm" |
| .summary (hero) | string | "Sữa vẫn là nguồn dinh dưỡng chính. …" |
| .timelineDetail | string | "2–3 bữa/ngày · chú ý sắt, kẽm" |
| .milkGuide | {perFeedMl range, feedsPerDay range, perDayMl range?, maxPerDayMl?, note} | 180–240 ml/cữ, 4–5 cữ, "+ 2–3 bữa ăn dặm"; 1 tháng "tối đa ~960 ml/ngày" |
| .dailyReferenceRangeMl | range | 600–900 ml (9b, 9c band) |
| .sampleDay[] | {slot: Sáng/Trưa/Chiều/Tối/Đêm, kind: milk/solids/sleep, text} | Trưa · "Ăn dặm · bột/cháo rây + thịt, rau" |
| .focusNutrients[] | ref Nutrient + stage subline + tag? | Sắt "Dự trữ từ lúc sinh giảm dần · thịt, trứng, gan"; Vitamin A tag "1–2/12" |
| .tips[] ("Gợi ý cho {baby}") | {title, body} | "Mỗi ngày một món giàu sắt" |
| sources, reviewedAt | string, month | "AAP, WHO", "09/2026" |
| **Nutrient** (Sắt, Kẽm, Vitamin D, Vitamin A) | {name, icon, tint, importanceLine, why, foods[], tip, byStage[{ageLabel, text}], warning, sources} | 9d |
| **SupplementCampaign** (Vitamin A) | {name, eligibleAge 6–36 m, rounds[{month, dayRange, year}], place} | June 1–2/6, Dec 1–2/12/2026, "trạm y tế phường" |
| per-baby **SupplementDose** | {babyId, campaign, round, takenOn} | "Đã uống 01/06/2026" |
| **Reminder** (campaign) | {babyId, fireAt, recipients[], addToCalendar} | 30/11 08:00, "Mẹ, Bố", toggle on |
| per-baby **milk intake** (derived from bottle logs) | ml/day series, 7-day avg | 720 ml/ngày; 14 bars 680–760 |
| per-baby **growth status** (derived) | latest weight/length, date, WHO band status | 7,8 kg / 68,5 cm, 05/10, "Trong khoảng chuẩn" |
| **GrowthRule** (portal "quy tắc chuyên gia") | {measure: weight-for-age, sex-specific WHO, condition: last N=2 below P3 (inferred), suggestions[], recheckDays 14, actions} | 9e |
| Re-measure reminder | {babyId, dueAt = +14 d} | "Nhắc đo lại sau 2 tuần" |
| Doctor report export | file | "Xuất báo cáo cho bác sĩ" |

#### Static vs per-baby vs editorial
- **Static app copy:** section headings ("Cần chú ý ở giai đoạn này", "Một ngày tham khảo", "Theo giai đoạn", "Gợi ý trong lúc chờ khám"), "Trong khoảng chuẩn", "Hiện tại", button labels, chart legends.
- **Per-baby (computed from logs/profile):**
  - Age and current stage ("7 tháng · giai đoạn 6–8 tháng", the 9a tile subline, the "Hiện tại" highlight, the current dot in the timeline).
  - Bottle average and 14-day bars (720 ml).
  - Latest growth values and band status.
  - The 9e trigger and the plotted points.
  - Vitamin A dose taken.
  - Reminders and recipients.
  - The baby name in "Gợi ý cho Teddy" / "Cân nặng của Teddy".
- **Editorial (portal; 9c says so explicitly: "số liệu nhập từ Child Life portal"; 9e: "quy tắc chuyên gia nhập từ portal"):**
  - Stages and their copy, milk tables and reference ranges.
  - Sample day, nutrient articles, food chips, tips.
  - Growth-rule suggestions, Vitamin A campaign dates.
  - Sources and review dates.
  - The WHO standard tables themselves are reference data (already in `who_growth_data.g.dart`).

#### Admin-portal candidates
- **Stages:** ordered list with age windows (one canonical set; today 9c, 9d and 9f disagree), title, summary, timeline line, milk guide numbers, daily reference range, sample day (5 slots), focus nutrients with stage-specific sublines and an optional tag, tips, locale vi/en, sources, reviewer and review date, publish status.
- **Nutrients:** articles (iron, zinc, vitamin D, vitamin A …) with an icon/tint, importance line, why, food chips, tip, by-age rows, warning and sources.
- **Supplement campaigns:** vitamin A rounds per year (dates), eligibility age, place text, default reminder offset and time (1 day before, 08:00).
- **Growth rules:** measurement (weight/length/weight-for-length), threshold (percentile/z-score), consecutive count (2), suggestion list, recheck interval (14 d), which CTA to show, disclaimer.
- **Milk reference ranges** for the 9b range bar and the 9c chart band (600–900).
- A review workflow: 9c shows "chuyên gia rà soát 09/2026", so each item needs a reviewer and a reviewed-at month, displayed in the footer.

#### Images and illustrations used
- No photos or raster illustrations in cluster 9.
- Illustration/BabyFace in the BabySwitcher.
- Line icons: spark (tile and solids slots), feed, ruler, drop (iron), star (zinc), sunrise (vit D), heart (vit A), sleep, journal, alert, check, clock, family, today, back, chevron.
- Charts: 9b range bar (shapes); 9c bar chart (shapes); 9e WHO chart flattened to one SVG; 9f timeline rail SVGs (3 states).
- Tints used: `care-growth-soft` (stage hero / current), `care-bottle-soft` (milk), `care/pump/soft` (iron), `care-diaper-soft`, `care-breast-soft`, `mint-soft` (tips), `sunshine-soft` (warnings / campaign tag).

#### Open questions / gaps
1. **Stage boundaries disagree** across 9c (Tuần đầu, 1 tháng, 2–5, 6–8, 9–11, 12–24), 9d (0–4, 4–6, 6–23, 12) and 9f (0–1, 1–3, 4–5, 6–8, 9–11, 12–23, 24–36). Which is canonical in the portal? Are per-article age rows free text?
2. **600–900 ml vs 180–240 ml × 4–5 feeds (720–1200 ml)** for 6–8 months: the reference range and the table disagree.
3. **9e trigger:** confirm the measurement (weight-for-age only, or length and weight-for-length too?), the threshold (P3, or −2 SD?), "2 consecutive" readings, an above-range variant, the entry point, and the copy when the user has no doctor visit. This is health-sensitive wording, so it needs owner review and probably a guard against showing it for premature babies (corrected age).
4. **Doctor report export:** format, contents, and where it is shared from. It overlaps with the existing export (R-187 / P-123)?
5. **Vitamin A:** how "Đã uống" is recorded; whether the dates come from the portal per year or are fixed 1–2/6 and 1–2/12; local station variance ("theo thông báo của trạm y tế địa phương"); reminder recipients (members picker); the calendar permission flow.
6. **Kẽm and Vitamin D** rows have chevrons but no link or detail; presumably the 9d template.
7. **"Ăn dặm" is still "Sớm ra mắt"** in 9a although nutrition covers solids. Do the solids log and library stay out of scope?
8. **Milk card for breastfed babies:** there is no ml data. Is the range bar hidden? Which feed types (bottle formula, expressed milk) count toward ml/day?
9. Mock inconsistencies: Teddy 7 months (9b), 6 months below range (9e), a dose at about 3 months (9g), 3 weeks old (vaccination cluster).
10. The combined Care tab and Night variants are not drawn.

---

#### Coverage
Frames read (16/16), one `get_design_context` call each, all succeeded first time and every one returned a screenshot:
- Cluster 7: 429:2424, 433:2879, 428:2346, 427:2048, 429:2573, 429:2711, 429:2779, 429:2848, 434:3155.
- Cluster 9: 440:3934, 440:3767, 440:4105, 440:4217, 441:3917, 441:4018, 441:4100.

Failed calls: none. Rate limit: not hit. Screenshots were copied to `docs/discovery/figma-extract/img/v11/` (429-2424, 433-2879, 428-2346, 427-2048, 429-2573, 429-2711, 429-2779, 429-2848, 434-3155, 440-3934, 440-3767, 440-4105, 440-4217, 441-3917, 441-4018, 441-4100 .png). `get_metadata` was not called, so canvas x positions were not recorded.

---

## Part E: Sơ cứu (first aid), situation detail pages TH01–TH12

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only), page **"v1.1"**, row at canvas y 11800 labelled **"Label · 7 · Sơ cứu · chi tiết 24 tình huống"** (`433:54377`). An older label that overlaps it (`429:53391`) says "17 tình huống". Read 2026-10-12. I made one `get_design_context` call per frame (12 calls, no failures, no rate limits) and called no Figma write tool.

**What this row is.** These are 12 editorial first-aid pages that all use one template. They split into two kinds:
- **Emergency** (TH01–TH07): tag "Khẩn cấp", a red "Gọi 115" pill at the top, and a red "Gọi 115" button in the bottom bar.
- **Non-emergency** (TH08–TH12): tag "Vết thương & bỏng", a bookmark ("save") button at the top, and only "Làm theo từng bước" in the bottom bar.

The label promises **24** situations. This row holds TH01–TH12; TH13–TH24 are in the next row (part F below).

**Method notes**
- Strings are the rendered text from the `<p>` nodes. I found no layer name that disagrees with its rendered text. One image layer name doesn't match its bitmap (TH06, flagged below).
- Prototype links appear as `<a … cursor-pointer>` in the generated code. They are marked **(prototype link)**. All targets are **inferred**.
- **Annotations:** no frame in this row has a `data-annotation`.
- Screenshots: `docs/discovery/figma-extract/img/v11/433-3201.png` … `433-4423.png` (12 files).
- **Mock scenario:** none. No baby name, no age, no date and no family member appears in any frame, so the pages are not personalised. TH01–TH06 show an **infant** in the illustrations. TH07–TH12 show a **preschool boy (about 3–5 years, inferred)** in a blue T-shirt. Neither matches Teddy (3 weeks old) or "bé Na · 7 tháng".
- **Night care:** none of the frames is drawn in Night care. All are Light (`cloud #f6fcfb`).
- Frame heights are not in the code. I estimated them as bottom bar top + 98 px (pt 12 + button 56 + pb 30) and marked them "(inferred)".

### Frame list (canvas order)
| Node | Name | Kind | Est. height (inferred) |
|---|---|---|---|
| 433:3201 | 7 · TH01 · Hồi sức tim phổi (CPR) | Emergency | ≈1842 |
| 433:3343 | TH02 · Sặc sữa | Emergency | ≈1831 |
| 433:3483 | TH03 · Ngừng thở ở trẻ sinh non | Emergency | ≈1200 |
| 433:3566 | TH04 · Co giật | Emergency | ≈1749 |
| 433:3699 | TH05 · Sốc phản vệ | Emergency | ≈1278 |
| 433:3793 | TH06 · Uống nhầm thuốc, hoá chất | Emergency | ≈1889 |
| 433:3920 | TH07 · Tai nạn giao thông | Emergency | ≈1791 |
| 433:4047 | TH08 · Chảy máu cam | Non-emergency | ≈1480 |
| 433:4149 | TH09 · Vết thương chảy máu | Non-emergency | ≈1186 |
| 433:4234 | TH10 · Băng bó cơ bản | Non-emergency | ≈1418 |
| 433:4332 | TH11 · Bỏng nước sôi | Non-emergency | ≈1252 |
| 433:4423 | TH12 · Bong gân | Non-emergency | ≈1141 |

---

### 433:3201 — 7 · TH01 · Hồi sức tim phổi (CPR) (Infant CPR) — full transcription

**Annotation:** none.

**Text (reading order)**
1. StatusBar "9:41" / "•••".
2. Top row: round **back** button **(prototype link)** · spacer · red pill **"Gọi 115"** (Call 115) with Icon/phone **(prototype link)**.
3. Tags: **"Khẩn cấp"** (Emergency) · **"Dùng được khi không có mạng"** (Works offline).
4. Title: **"Hồi sức tim phổi (CPR)"** (Cardiopulmonary resuscitation (CPR)).
5. Subtitle (when to use): "Bé bất tỉnh, không thở hoặc thở ngáp" (Baby is unconscious, not breathing or only gasping).
6. Hero illustration `Illus/FA/Ép tim sơ sinh` (infant chest compressions): a mother doing two-finger compressions on a baby, with a toddler watching.
7. Warning banner (Icon/alert): "Gọi 115 và bật loa ngoài trước khi bắt đầu. Có người khác: nhờ gọi giúp." (Call 115 and turn on the speaker before you start. If someone else is there, ask them to call.)
8. Segmented control (age variant): **"Dưới 1 tuổi"** (Under 1 year; selected) | "Từ 1 tuổi" (1 year and over).
9. Section header: "Làm theo các bước" (Follow the steps).
10. Step 1: **"Mở đường thở"** (Open the airway) / "Một tay đặt lên trán, ngửa nhẹ đầu, nâng cằm. Có vật cản thấy rõ trong miệng: lấy ra." (One hand on the forehead, tilt the head back slightly, lift the chin. If you can clearly see something blocking the mouth, remove it.) + step illustration `Illus/FA/Mở đường thở` (opening the airway).
11. Step 2: **"Thổi ngạt 5 lần"** (Give 5 rescue breaths) / "Miệng bạn trùm cả miệng và mũi bé. Thổi nhẹ, đều, nhìn ngực bé phồng lên." (Cover the baby's mouth and nose with your mouth. Blow gently and evenly; watch the chest rise.)
12. Step 3: **"Ép ngực 30 lần"** (30 chest compressions) / "2 ngón tay giữa ngực, ngay dưới đường nối hai núm vú. Ấn sâu khoảng 4 cm, 100–120 lần/phút." (Two fingers in the middle of the chest, just below the nipple line. Press about 4 cm deep, 100–120 per minute.) + rhythm chips **"× 30"** (mint) and **"100–120 lần/phút"** (100–120/min; neutral).
13. Step 4: **"Thổi ngạt 2 lần, lặp lại"** (2 rescue breaths, repeat) / "Cứ 30 lần ép ngực, thổi 2 lần. Tiếp tục đến khi bé thở lại hoặc nhân viên y tế tới." (After every 30 compressions give 2 breaths. Keep going until the baby breathes again or medical staff arrive.)
14. Don't box **"Không được làm"** (Do not): "Dừng ép ngực quá 10 giây" (Pause compressions for more than 10 seconds) · "Ép trên bụng hoặc đầu xương ức" (Press on the belly or the tip of the breastbone).
15. Seek-care box **"Đưa bé đi viện ngay khi"** (Take the baby to hospital right away if): "Luôn gọi 115, kể cả khi bé đã thở lại" (Always call 115, even if the baby is breathing again).
16. Disclaimer: "Nội dung tham khảo, không thay thế chẩn đoán của bác sĩ. Được chuyên gia y tế rà soát qua Child Life." (Reference content; it does not replace a doctor's diagnosis. Reviewed by medical experts through Child Life.)
17. Bottom bar: primary Button **"Làm theo từng bước"** (Follow step by step) · red button **"Gọi 115"**.

**Layout / components / tokens**
- **Frame:** 375 wide, radius 40, background `cloud #f6fcfb`. The content column is absolute at top 0, with padding top 52, sides 16, bottom 120 and a vertical **gap of 16**. **StatusBar** (11:135, "Placeholder iOS status bar for screen mockups.") overlays it.
- **Top row:** gap 10.
  - Back: `surface` white, p 8, radius 999, Icon/back 20 (7:39, "Line icon (24px, 1.8 stroke) — placeholder drawing; production uses SF Symbols…").
  - **Gọi 115 pill:** background raw **`#db4a45`** (no token), px 14 py 8, radius 999, gap 8, Icon/phone 16 white, label Bold 14 white.
- **Tags:** gap 6. Each pill is px 10 py 4, radius 999, Bold 12.
  - "Khẩn cấp": background raw **`#fcebe8`** (no token), text `#db4a45`.
  - "Dùng được khi không có mạng": `surface-2 #eef6f5` background, `ink-muted #55707a` text.
- **Title:** Bold 30, line height 1.2, `ink #173d44`. **Subtitle:** Medium 15, line height 1.45, `ink-muted`.
- **Hero image:** 343 × 214.375 (1.6 : 1), radius 24, `object-cover`, PNG bitmap.
- **Banner:** `sunshine-soft #fff4d6`, radius 14, px 14 py 12, gap 10, Icon/alert 16 (7:53), text Medium 13 / 1.45 `ink`.
- **Segmented:** track `surface-2`, p 4, radius 14, gap 2. Each segment is flex 1, px 10 py 8, radius 10.
  - Selected: `surface` white background, SemiBold 14 `ink`.
  - Unselected: no background, Medium 14 `ink-muted`.
- **Section header:** Bold 17 `ink`, plus a spacer (no trailing link).
- **Step card ("Bước n"):** `surface` white, radius 20, p 16, drop shadow `0 8 12 rgba(23,61,68,.08)` + `0 1 1 rgba(23,61,68,.06)`. This differs from the file's `shadow-card` style (0/1/2 + 0/8/24); use `shadow-card` (inferred).
  - Row gap 12. The number badge is a 30 px circle in `mint-deep #087f7b`, with Bold 15 `on-mint-deep` white.
  - Text column gap 4: title Bold 17 `ink`, body Medium 15 / 1.5 `ink`.
  - Optional step image 311 × 194.375, radius 24, 12 below the row.
  - Optional chip row with pl 42 (aligned to the text) and gap 8:
    - Chip "× 30": `mint-soft #e6f7f5` background, `mint-text #06716d` text.
    - Chip "100–120 lần/phút": `surface-2` background, `ink-muted` text, Bold 12 pill.
- **Don't box:** background `#fcebe8` (raw), radius 20, p 16, gap 10.
  - Header: a `#db4a45` circle (p 3) holding Icon/close 14 (7:63) white, then "Không được làm" Bold 16 `#db4a45`.
  - Items: a 6 × 13 bullet dot (red) and Medium 15 / 1.5 `ink` text, gap 10.
- **Seek-care box:** `sunshine-soft #fff4d6`, radius 20, p 16, gap 10.
  - Header: a `sunshine #ffd166` circle (p 3) holding Icon/alert 14, then "Đưa bé đi viện ngay khi" Bold 16 `ink`.
  - Items: dark bullet dot and Medium 15 / 1.5 `ink` text.
- **Disclaimer:** Medium 12 / 1.5 `ink-muted`.
- **Bottom bar:** absolute, `surface` white, shadow `0 -4 8 rgba(0,0,0,.08)`, pt 12 pb 30 px 16, gap 10.
  - **Button** (8:33, "Pill button… Primary h56 mint-deep/on-mint-deep, one per screen in the thumb zone… Press: scale 0.97…"): flex 1, h 56, `mint-deep`, px `space-6` 24, radius `radius-pill`, label `Text/body-strong` Medium 17 / 24 `on-mint-deep`.
  - Red **Gọi 115** button: `#db4a45`, px 20 py 15, radius 999, Icon/phone 20, Bold 16 white.
- **Tokens used:** `cloud`, `surface`, `surface-2`, `ink`, `ink-muted`, `mint-deep`, `on-mint-deep`, `mint-soft`, `mint-text`, `sunshine`, `sunshine-soft`, `space-2`, `space-6`, `radius-pill`. **Not tokens:** `#db4a45` (danger) and `#fcebe8` (danger-soft).

**Visual.** This is a long, calm reading page on mint-white. The large 3D-rendered illustration at the top is soft and Pixar-like, with a pastel mint background. Steps are white cards numbered with teal circles. A pink "Do not" box and a yellow "When to go to hospital" box close the page. Red is used only for the 115 actions and the "Khẩn cấp" / "Không được làm" accents, so the call action stands out.

**Navigation**
- back **(prototype link)** → Sơ cứu hub / situation list (inferred; not in this row).
- Top "Gọi 115" **(prototype link)** → phone dialer with `tel:115`, or a call confirmation (inferred; no target frame drawn).
- **Bottom bar:** on TH01 the `cursor-pointer` sits on the **Bottom bar container**. The "Làm theo từng bước" Button and the "Gọi 115" button inside it are rendered as `<a>` without their own cursor. My reading is that the whole bar carries one interaction, most likely "Làm theo từng bước" → a guided one-step-per-screen mode (inferred; that mode is not drawn in this row). On TH02–TH07 the bottom "Gọi 115" is its own link and "Làm theo từng bước" is not a link at all.
- The segmented "Từ 1 tuổi" is not a prototype link. Its content (child CPR, e.g. heel of one hand, about 5 cm) is **not drawn**.

**Notes / not shown**
- The "Từ 1 tuổi" content, the guided step mode, the call confirmation, and the Night care variant are not drawn.
- No sources line, reviewer name or "updated" date is drawn. Only the generic disclaimer line appears.
- The rescue-breath order (5 breaths first, then 30:2) and the depth (4 cm) are medical content for the reviewer to confirm. They are not engineering decisions.

---

### Other situations (text in reading order + differences from the template)

Every frame below shares TH01's chrome: StatusBar, back **(prototype link)**, the tags row, title, subtitle, hero, the "Làm theo các bước" header, step cards, the disclaimer (always the same text: "Nội dung tham khảo, không thay thế chẩn đoán của bác sĩ. Được chuyên gia y tế rà soát qua Child Life.") and the bottom bar. Only the differences are listed.

#### 433:3343 — TH02 · Sặc sữa (Choking on milk) — emergency
- Tags: "Khẩn cấp" · "Dùng được khi không có mạng". Top: "Gọi 115" pill **(prototype link)**.
- Title "Sặc sữa". Subtitle: "Sữa trào lên, bé ho sặc, tím tái" (Milk comes back up; the baby coughs, chokes, turns blue).
- Hero: `Illus/FA/Nằm nghiêng vỗ lưng` (side-lying, back pats).
- No banner, no segmented control.
- Steps:
  1. "Nghiêng bé, đầu thấp" (Turn the baby on the side, head low) / "Đặt bé nằm nghiêng, đầu thấp hơn thân. Khum tay vỗ nhẹ giữa hai bả vai để sữa chảy ra." (Lay the baby on the side, head lower than the body. With a cupped hand, pat gently between the shoulder blades so the milk drains out.)
  2. "Kích thích bé khóc" (Make the baby cry) / "Nếu bé không khóc, búng nhẹ vào lòng bàn chân." (If the baby isn't crying, flick the sole of the foot gently.) + image `Illus/FA/Kích thích lòng bàn chân` (stimulating the sole).
  3. "Nếu vẫn tím tái" (If still blue) / "Đỡ chắc cằm, lật úp bé trên cẳng tay, đầu hơi cúi. Vỗ giữa hai bả vai." (Support the chin firmly, turn the baby face-down along your forearm, head slightly down. Pat between the shoulder blades.) + image `Illus/FA/Vỗ lưng` (back blows).
  4. "Lau sạch miệng" (Wipe the mouth clean) / "Khi bé khóc lại, dùng khăn mềm lau sữa còn sót." (Once the baby cries again, wipe away remaining milk with a soft cloth.)
- Không được làm: "Bế bé dựng đứng ngay, sữa có thể vào sâu hơn" (Picking the baby up upright straight away; milk can go deeper).
- Đưa bé đi viện ngay khi: "Bé tím tái, không khóc, thở yếu: gọi 115" (Baby is blue, not crying, breathing weakly: call 115) · "Sau đó bé thở khò khè, sốt, bú kém" (Afterwards the baby wheezes, has a fever, feeds poorly).
- Links: back, top Gọi 115, **bottom Gọi 115 (prototype link)**. "Làm theo từng bước" is not a link.

#### 433:3483 — TH03 · Ngừng thở ở trẻ sinh non (Apnoea in premature babies) — emergency
- Tags: "Khẩn cấp" · "Dùng được khi không có mạng". Top: "Gọi 115" pill.
- Title "Ngừng thở ở trẻ sinh non". Subtitle: "Bé ngừng thở, da tái hoặc tím" (Baby stops breathing; skin pale or blue).
- Hero: `Illus/FA/Kích thích lòng bàn chân`. This is **the same bitmap as TH02 step 2**.
- No banner, no segmented control, no step images. **No "Không được làm" box.**
- Steps:
  1. "Giữ đầu, cổ, thân thẳng" (Keep head, neck and body in line) / "Đặt bé nằm ngửa, ngửa nhẹ đầu, nâng cằm." (Lay the baby on the back, tilt the head slightly, lift the chin.)
  2. "Kích thích bé" (Stimulate the baby) / "Gãi lòng bàn chân hoặc xoa nhẹ bụng." (Scratch the sole of the foot or rub the tummy gently.)
  3. "Theo dõi đến khi bé thở đều" (Watch until breathing is regular) / "Nếu bé chưa khóc, búng nhẹ lòng bàn chân. Chờ đến khi bé khóc và thở đều trở lại." (If the baby hasn't cried yet, flick the sole gently. Wait until the baby cries and breathes regularly again.)
- Đưa bé đi viện ngay khi: "Bé không thở lại, không phản ứng: gọi 115, làm hồi sức tim phổi (CPR)" (Baby doesn't start breathing or respond: call 115 and do CPR). This cross-references TH01 as plain text, not a link.
- Links: back, top Gọi 115, bottom Gọi 115.

#### 433:3566 — TH04 · Co giật (Seizure) — emergency
- Tags: "Khẩn cấp" · "Dùng được khi không có mạng". Top: "Gọi 115" pill.
- Title "Co giật". Subtitle: "Người cứng, giật tay chân, mắt đảo, có thể do sốt cao" (Body stiff, arms and legs jerking, eyes rolling; may be caused by high fever).
- Hero: `Illus/FA/Nằm nghiêng an toàn` (safe side-lying position).
- No banner, no segmented control, no step images.
- Steps (5):
  1. "Dọn vật sắc nhọn xung quanh" (Clear away sharp objects) / "Để bé trên mặt phẳng an toàn." (Keep the baby on a safe flat surface.)
  2. "Đặt bé nằm nghiêng" (Lay the baby on the side) / "Giúp đờm dãi chảy ra, không chảy ngược vào đường thở." (Lets saliva drain out instead of back into the airway.)
  3. "Kê vật mềm dưới đầu" (Put something soft under the head) / "Khăn hoặc gối mỏng để đầu không va đập. Nới bớt quần áo." (A towel or thin pillow so the head doesn't knock. Loosen clothing.)
  4. "Ghi lại thời gian" (Note the time) / "Bấm giờ lúc bắt đầu và kết thúc cơn giật để báo bác sĩ." (Time when the seizure starts and ends to tell the doctor.)
  5. "Đưa bé đi khám" (Take the baby to a doctor) / "Khi hết cơn giật. Bé sốt: dùng thuốc hạ sốt theo chỉ định bác sĩ." (Once the seizure is over. If feverish: give fever medicine as prescribed by a doctor.)
- **New block: seizure timer card ("Bấm giờ").** It is a white card, radius 20, px 16 py 14, with the step-card shadow.
  - Left: an icon tile in `sunshine-soft`, radius 12, p 8, holding **Icon/clock** 20 (22:173, "Line icon (24px, 1.8 stroke) — placeholder; production uses SF Symbols.").
  - Middle: "Bấm giờ cơn giật" (Time the seizure; SemiBold 15) over **"00:00"** (Bold 22).
  - Right: primary Button **"Bắt đầu"** (Start; h 56, not a prototype link).
- Không được làm: "Cho bất cứ thứ gì vào miệng bé, kể cả khăn" (Putting anything in the baby's mouth, even a cloth) · "Cho uống thuốc, uống nước khi đang giật" (Giving medicine or water during the seizure) · "Cố giữ chặt hay hạn chế cử động của bé" (Holding the baby down or restricting movement).
- Đưa bé đi viện ngay khi: "Cơn giật kéo dài trên 5 phút hoặc nhiều cơn liên tiếp: gọi 115" (Seizure lasts over 5 minutes or several in a row: call 115) · "Bé khó thở, tím tái, không tỉnh lại sau cơn" (Trouble breathing, blue, doesn't come round after the seizure).
- Links: back, top Gọi 115, bottom Gọi 115. The timer's "Bắt đầu" is **not** a link. Its running and stopped states are not drawn.

#### 433:3699 — TH05 · Sốc phản vệ (Anaphylaxis) — emergency
- Tags: "Khẩn cấp" · "Dùng được khi không có mạng". Top: "Gọi 115" pill.
- Title "Sốc phản vệ". Subtitle: "Khó thở, khò khè, sưng mặt, phát ban" (Trouble breathing, wheezing, swollen face, rash).
- Hero: `Illus/FA/Nằm ngửa kê cao chân` (lying on the back, legs raised).
- **Banner:** "Gọi 115 ngay khi nghi ngờ sốc phản vệ." (Call 115 as soon as you suspect anaphylaxis.)
- No segmented control, no step images.
- Steps:
  1. "Nằm ngửa, kê cao chân" (Lie on the back, legs raised) / "Nếu bé nôn, cho nằm nghiêng để tránh sặc." (If the baby vomits, turn on the side to avoid choking.)
  2. "Thông đường thở" (Clear the airway) / "Dùng khăn mềm lau nhẹ đờm dãi, chất nôn trong miệng." (Gently wipe saliva and vomit from the mouth with a soft cloth.)
  3. "Theo dõi nhịp thở" (Watch the breathing) / "Ở cạnh bé đến khi nhân viên y tế tới. Làm theo hướng dẫn của tổng đài." (Stay with the baby until medical staff arrive. Follow the dispatcher's instructions.)
- Không được làm: "Để nhiều người vây quanh bé" (Letting many people crowd around the baby).
- Đưa bé đi viện ngay khi: "Khó thở, khò khè, tím tái, lả đi: gọi 115" (Trouble breathing, wheezing, blue, going limp: call 115).
- Links: back, top Gọi 115, bottom Gọi 115.

#### 433:3793 — TH06 · Uống nhầm thuốc, hoá chất (Swallowed medicine or chemicals) — emergency
- Tags: "Khẩn cấp" · "Dùng được khi không có mạng". Top: "Gọi 115" pill.
- Title "Uống nhầm thuốc, hoá chất". Subtitle: "Thuốc người lớn, nước tẩy, chất lạ" (Adult medicine, bleach or cleaners, unknown substances).
- Hero: `Illus/FA/Hoá chất` (chemicals: mother with a bag of bottles and two toddlers, green check badge).
- No banner, no segmented control.
- Steps:
  1. "Gọi 115 ngay" (Call 115 now) / "Giữ bình tĩnh, làm theo hướng dẫn của tổng đài." (Stay calm and follow the dispatcher's instructions.)
  2. "Bé tỉnh: cho ngồi" (Baby awake: sit them up) / "Bé lơ mơ, bất tỉnh: đặt nằm nghiêng để tránh sặc." (Drowsy or unconscious: lay on the side to avoid choking.) + image `Illus/FA/Nằm nghiêng an toàn` (**the same bitmap as the TH04 hero**).
  3. "Súc miệng bằng nước sạch" (Rinse the mouth with clean water) / "Cho bé súc miệng rồi nhổ ra. Chỉ cho uống khi nhân viên y tế hướng dẫn." (Have the child rinse and spit. Only give drinks when medical staff say so.)
  4. "Mang theo vỏ thuốc, chai hoá chất" (Bring the medicine packet or chemical bottle) / "Giúp bác sĩ biết bé đã uống gì, bao nhiêu." (Helps the doctor know what and how much was swallowed.) + image layer `Illus/FA/Mang theo vỏ thuốc`. **Layer name ≠ image:** it uses the same bitmap as the hero `Illus/FA/Hoá chất` (asset `fe122`).
- Không được làm: "Tự gây nôn, móc họng cho bé" (Making the child vomit or putting fingers down the throat) · "Tự cho uống thuốc giải, sữa hay nước khi chưa được hướng dẫn" (Giving antidotes, milk or water before being told to).
- Đưa bé đi viện ngay khi: "Luôn đưa bé đến cơ sở y tế, kể cả khi bé có vẻ bình thường" (Always take the child to a medical facility, even if they seem fine).
- Links: back, top Gọi 115, bottom Gọi 115.

#### 433:3920 — TH07 · Tai nạn giao thông (Traffic accident) — emergency
- Tags: "Khẩn cấp" · "Dùng được khi không có mạng". Top: "Gọi 115" pill.
- Title "Tai nạn giao thông". Subtitle: "Bé bị ngã xe, va chạm" (Child fell from a vehicle or was hit).
- Hero: `Illus/FA/Không di chuyển` (do not move: child lying on the road, warning triangle, mother kneeling).
- No banner, no segmented control.
- Steps (5):
  1. "Đảm bảo an toàn, gọi 115" (Make the scene safe, call 115) / "Chỉ đưa bé ra khỏi vùng nguy hiểm nếu thật cần thiết." (Only move the child out of danger if truly necessary.)
  2. "Gọi tên, kiểm tra hơi thở" (Call the child's name, check breathing) / "Bé không thở: làm hồi sức tim phổi (CPR)." (Not breathing: do CPR.) This cross-references TH01 as plain text.
  3. "Giữ yên đầu, cổ, lưng" (Keep head, neck and back still) / "Nghi chấn thương: không di chuyển đầu, cổ hay bất kỳ bộ phận nào của bé." (If injury is suspected, don't move the head, neck or any part of the body.)
  4. "Cầm máu" (Stop the bleeding) / "Ép băng hoặc khăn sạch lên vết thương. Có dị vật: không rút ra, ép băng quanh dị vật." (Press a bandage or clean cloth on the wound. If something is stuck in it, don't pull it out; press around it.) + image `Illus/FA/Ép gạc cầm máu` (pressing gauze).
  5. "Giữ ấm, ở cạnh bé" (Keep warm, stay close) / "Đắp chăn mỏng nếu trời lạnh. Nói chuyện để bé tỉnh táo." (Cover with a light blanket if cold. Talk to keep the child alert.)
- Không được làm: "Bế xốc hoặc gập người bé. Cần 2–3 người cùng nâng bé lên ván cứng" (Yanking the child up or bending the body. Use 2–3 people to lift onto a rigid board) · "Cho bé ăn uống khi bị chấn thương bụng" (Giving food or drink with a belly injury).
- Đưa bé đi viện ngay khi: "Mọi tai nạn giao thông đều cần đưa bé đi khám" (Every traffic accident needs a medical check).
- Links: back, top Gọi 115, bottom Gọi 115.

#### 433:4047 — TH08 · Chảy máu cam (Nosebleed) — **non-emergency variant**
- **Top row:** back **(prototype link)** · spacer · **"save"** round white button with **Icon/bookmark** 20 (not a link). **No Gọi 115 pill.**
- **Tags:** **"Vết thương & bỏng"** (Wounds & burns; `sunshine-soft` background, `ink` Bold 12) · "Dùng được khi không có mạng".
- Title "Chảy máu cam". Subtitle: "Máu chảy từ một hoặc hai bên mũi" (Bleeding from one or both nostrils).
- Hero: `Illus/FA/Cúi đầu bóp mũi` (lean forward, pinch the nose). The bitmap has a **green check badge** ("correct").
- No banner, no segmented control, no step images.
- Steps:
  1. "Ngồi, đầu hơi cúi" (Sit, head tilted slightly forward) / "Máu chảy ra ngoài, không chảy vào họng." (Blood runs out, not down the throat.)
  2. "Bóp cánh mũi 10 phút" (Pinch the nostrils for 10 minutes) / "Ép nhẹ cánh mũi bên chảy máu. Chảy cả hai bên: kẹp chặt hai cánh mũi. Bé thở bằng miệng." (Press gently on the bleeding side. If both sides bleed, pinch both firmly. The child breathes through the mouth.)
  3. "Sau khi cầm máu" (After the bleeding stops) / "Nhắc bé không xì mũi mạnh, không cạy vảy máu." (Remind the child not to blow hard or pick the scab.)
- Không được làm: "Ngửa đầu bé ra sau" (Tilting the head back) · "Nhét bông vào mũi" (Stuffing cotton into the nose). **Different from the template: the Don't box contains an image**, `Illus/FA/Ngửa đầu (sai)` (head tilted back, wrong), 311 × 194.375, with a **red X badge**.
- Đưa bé đi viện ngay khi: "Sau 10 phút máu vẫn chảy" (Still bleeding after 10 minutes).
- **Bottom bar:** only "Làm theo từng bước" (full width, no gap, not a link). No Gọi 115.
- Links: back only.

#### 433:4149 — TH09 · Vết thương chảy máu (Bleeding wound) — non-emergency
- Top: back + bookmark. Tags: "Vết thương & bỏng" · "Dùng được khi không có mạng".
- Title "Vết thương chảy máu". Subtitle: "Đứt tay, trầy, có dị vật đâm vào" (Cuts, grazes, something stuck in the skin).
- Hero: `Illus/FA/Ép gạc cầm máu` (the **same bitmap as TH07 step 4**).
- **Segmented control, used for a condition variant rather than age:** **"Không có dị vật"** (No object stuck in; selected) | "Có dị vật" (Object stuck in). The "Có dị vật" content is not drawn.
- Steps (no images):
  1. "Ép gạc sạch" (Press clean gauze) / "Ép ngay băng gạc hoặc vải sạch lên vết thương để cầm máu." (Press gauze or clean cloth on the wound right away to stop bleeding.)
  2. "Nâng cao vùng bị thương" (Raise the injured part) / "Giữ bé ở tư thế thoải mái." (Keep the child comfortable.)
  3. "Quấn băng vừa phải" (Bandage firmly but not tight) / "Không quấn quá chặt để máu vẫn lưu thông." (Don't wrap too tight, so blood still circulates.)
- **No "Không được làm" box.**
- Đưa bé đi viện ngay khi: "Máu chảy nhiều, không cầm được" (Heavy bleeding that won't stop) · "Vết thương sâu, rộng hoặc có dị vật" (Deep or wide wound, or something stuck in it).
- Bottom bar: only "Làm theo từng bước". Links: back only.

#### 433:4234 — TH10 · Băng bó cơ bản (Basic bandaging) — non-emergency
- Top: back + bookmark. Tags: "Vết thương & bỏng" · "Dùng được khi không có mạng".
- Title "Băng bó cơ bản". Subtitle: "Vết trầy, đứt tay nhỏ" (Grazes, small cuts).
- Hero: `Illus/FA/Quấn băng` (bandaging; green check badge). No banner, no segmented control, no step images.
- Steps:
  1. "Chuẩn bị" (Get ready) / "Băng y tế, băng thun hoặc gạc sạch. Rửa tay sạch." (Medical bandage, elastic bandage or clean gauze. Wash your hands.)
  2. "Rửa và lau khô" (Clean and dry) / "Rửa vết thương bằng nước sạch hoặc dung dịch sát trùng, lau khô nhẹ." (Rinse the wound with clean water or antiseptic and pat dry.)
  3. "Đặt gạc phủ kín vết thương" (Cover the wound with gauze) / "Gạc sạch, che hết miệng vết thương." (Clean gauze covering the whole wound.)
  4. "Quấn băng từ dưới lên" (Wrap from the bottom up) / "Quấn đều, vừa tay. Cố định bằng băng keo y tế." (Wrap evenly and snugly. Secure with medical tape.)
- Không được làm: "Quấn quá chặt làm sưng, tím đầu ngón" (Wrapping so tight the fingertips swell or turn blue).
- Đưa bé đi viện ngay khi: "Vết thương sưng, đỏ, chảy mủ hoặc bé đau nhiều" (Wound is swollen, red, oozing pus, or the child is in a lot of pain) · "Thay băng khi băng bị ướt, bẩn" (Change the bandage when it is wet or dirty). **Copy issue:** the second item is aftercare advice, not a reason to go to hospital.
- Bottom bar: only "Làm theo từng bước". Links: back only.

#### 433:4332 — TH11 · Bỏng nước sôi (Scald from boiling water) — non-emergency
- Top: back + bookmark. Tags: "Vết thương & bỏng" · "Dùng được khi không có mạng".
- Title "Bỏng nước sôi". Subtitle: "Nước sôi, canh nóng, hơi nóng" (Boiling water, hot soup, steam).
- Hero: `Illus/FA/Xả nước mát` (cool running water). No banner, no segmented control, no step images.
- Steps:
  1. "Xả nước mát 15–20 phút" (Cool running water for 15–20 minutes) / "Giúp hạ nhiệt, giảm sưng và đau." (Cools the burn and reduces swelling and pain.)
  2. "Che bằng gạc sạch" (Cover with clean gauze) / "Gạc mỏng hoặc vải sạch, giảm nguy cơ nhiễm trùng." (Thin gauze or clean cloth, lowers infection risk.)
  3. "Chỉ bôi thuốc theo hướng dẫn" (Only apply medicine as advised) / "Hỏi bác sĩ hoặc dược sĩ trước khi bôi bất kỳ thuốc nào." (Ask a doctor or pharmacist before applying anything.)
- Không được làm: "Bôi kem đánh răng, mỡ trăn hay chất không rõ nguồn gốc" (Applying toothpaste, python fat or unknown substances).
- Đưa bé đi viện ngay khi: "Bỏng rộng, sâu, phồng rộp lớn" (Large or deep burn, big blisters) · "Bỏng ở mặt, tay, bộ phận sinh dục" (Burn on the face, hands or genitals).
- Bottom bar: only "Làm theo từng bước". Links: back only.

#### 433:4423 — TH12 · Bong gân (Sprain) — non-emergency
- Top: back + bookmark. Tags: "Vết thương & bỏng" · "Dùng được khi không có mạng". (The category tag is shared with wounds and burns even though a sprain is neither; see questions.)
- Title "Bong gân". Subtitle: "Ngã, trượt chân, khớp sưng đau" (Fall or slip; swollen, painful joint).
- Hero: `Illus/FA/Chườm lạnh mắt cá` (cold pack on the ankle). No banner, no segmented control, no step images.
- Steps:
  1. "Kiểm tra vùng bị thương" (Check the injured area) / "Sưng, bầm tím, biến dạng? Nghi gãy xương, trật khớp: đưa đi viện ngay." (Swelling, bruising, deformity? If you suspect a fracture or dislocation, go to hospital now.)
  2. "Nghỉ và chườm lạnh" (Rest and cold pack) / "15–20 phút mỗi lần, lặp lại sau 2–3 giờ trong 1–2 ngày đầu. Bọc khăn, không chườm đá trực tiếp." (15–20 minutes at a time, repeat every 2–3 hours for the first 1–2 days. Wrap in a cloth; never put ice directly on skin.)
  3. "Băng nhẹ, kê cao" (Light bandage, elevate) / "Quấn băng thun vừa phải, dùng gối đỡ vùng bị thương." (Wrap an elastic bandage moderately and prop the area on a pillow.)
- **No "Không được làm" box.**
- Đưa bé đi viện ngay khi: "Đau, sưng không giảm sau 48 giờ" (Pain and swelling not better after 48 hours).
- Bottom bar: only "Làm theo từng bước". Links: back only.

---

#### Situation page template

The blocks are listed in page order. "All" means all 12 frames (TH01–TH12).

| # | Block | Spec summary | Used by |
|---|---|---|---|
| 1 | **StatusBar** + frame chrome | 375 wide, radius 40, `cloud` background; content column with padding 52 / 16 / 120 and gap 16 | All |
| 2 | **Top row: back** | round white 36 px, Icon/back 20, (prototype link) | All |
| 3a | **Top row: "Gọi 115" pill** (call 115) | `#db4a45`, Icon/phone 16, Bold 14 white, (prototype link) | TH01–TH07 (emergency) |
| 3b | **Top row: bookmark "save"** | round white, Icon/bookmark 20, no link | TH08–TH12 (non-emergency) |
| 4a | **Category tag "Khẩn cấp"** (emergency) | `#fcebe8` background, `#db4a45` text, Bold 12 pill | TH01–TH07 |
| 4b | **Category tag "Vết thương & bỏng"** (wounds & burns) | `sunshine-soft` background, `ink` text | TH08–TH12 |
| 4c | **Offline tag "Dùng được khi không có mạng"** (works offline) | `surface-2` / `ink-muted` | All |
| 5 | **Title** | Bold 30 / 1.2 | All |
| 6 | **Subtitle: symptoms / when to use** | Medium 15 / 1.45 muted | All |
| 7 | **Hero illustration** | 343 × 214.375, radius 24, PNG; some carry a ✓ badge | All (TH03 reuses TH02's step image, TH09 reuses TH07's step image) |
| 8 | **Warning banner** (sunshine, Icon/alert 16, 13 px text): the "call 115 first" message | TH01 "Gọi 115 và bật loa ngoài trước khi bắt đầu. Có người khác: nhờ gọi giúp."; TH05 "Gọi 115 ngay khi nghi ngờ sốc phản vệ." | TH01, TH05 |
| 9a | **Segmented: age variant** | "Dưới 1 tuổi" / "Từ 1 tuổi" | TH01 |
| 9b | **Segmented: condition variant** | "Không có dị vật" / "Có dị vật" | TH09 |
| 10 | **Section header "Làm theo các bước"** (follow the steps) | Bold 17 | All |
| 11 | **Numbered step cards** | white radius 20 p 16; 30 px `mint-deep` number; title Bold 17 + body Medium 15 / 1.5 | All. Counts: TH01 4, TH02 4, TH03 3, TH04 5, TH05 3, TH06 4, TH07 5, TH08 3, TH09 3, TH10 4, TH11 3, TH12 3 |
| 11a | **Step image** (inside the card) | 311 × 194.375, radius 24 | TH01 (s1), TH02 (s2, s3), TH06 (s2, s4), TH07 (s4) |
| 11b | **Step chips** (rhythm / count) | mint "× 30" + neutral "100–120 lần/phút" | TH01 (s3) |
| 12 | **Seizure timer card** | Icon/clock tile, "Bấm giờ cơn giật", "00:00", Button "Bắt đầu" | TH04 |
| 13 | **Don't list "Không được làm"** | `#fcebe8` box, red close badge, bullet list | TH01, TH02, TH04, TH05, TH06, TH07, TH08, TH10, TH11. **Missing in TH03, TH09, TH12** |
| 13a | **Don't image** ("wrong" illustration with a red ✗ badge inside the Don't box) | 311 × 194.375 | TH08 |
| 14 | **Seek-care list "Đưa bé đi viện ngay khi"** (take to hospital if); this is the "when to call 115" block. Items may end in ": gọi 115" | `sunshine-soft` box, sunshine alert badge, bullet list (1–2 items) | All |
| 15 | **Disclaimer / review line** | the same sentence on every page; no named reviewer, no sources, no updated date | All |
| 16a | **Bottom bar: "Làm theo từng bước" + "Gọi 115"** | `mint-deep` Button (flex) + red call button | TH01–TH07 |
| 16b | **Bottom bar: "Làm theo từng bước" only** | full-width Button | TH08–TH12 |

**Blocks that are not drawn:** a named reviewer, sources / citations, an "updated" date, an age-applicability badge, related-situation links, a share button, and an in-page link to CPR (TH03 and TH07 mention CPR as plain text only).

**Emergency switch.** One boolean drives the top-right control (Gọi 115 vs bookmark), the category tag colour and the bottom-bar layout (inferred). The data should therefore carry `isEmergency` (or `severity`) rather than per-page layout.

---

#### Data model implied

`FirstAidSituation` (editorial):
| Field | Type | Example from the design |
|---|---|---|
| `id` / `code` | string | "TH01" |
| `order` | int | 1 (label: 24 situations in total) |
| `category` | enum / ref → `FirstAidCategory` | "Khẩn cấp", "Vết thương & bỏng" |
| `isEmergency` | bool | true (TH01–TH07) |
| `offlineAvailable` | bool (always true in the design) | "Dùng được khi không có mạng" |
| `title` | localized string | "Hồi sức tim phổi (CPR)" |
| `summary` (symptoms / when to use) | localized string | "Bé bất tỉnh, không thở hoặc thở ngáp" |
| `heroImage` | `{assetId, alt, badge?: correct\|wrong}` | `Illus/FA/Ép tim sơ sinh` |
| `banner?` | `{text, tone: warning}` | "Gọi 115 ngay khi nghi ngờ sốc phản vệ." |
| `variantSelector?` | `{kind: age\|condition, options: [{id, label, steps, donts?, seekCare?}], default}` | age: "Dưới 1 tuổi" / "Từ 1 tuổi"; condition: "Không có dị vật" / "Có dị vật" |
| `steps[]` | `{n, title, body, image?, chips[]?}` | {3, "Ép ngực 30 lần", "2 ngón tay…", chips ["× 30" mint, "100–120 lần/phút" neutral]} |
| `tool?` | enum (`seizureTimer`) + label | "Bấm giờ cơn giật", "00:00", "Bắt đầu" |
| `donts[]` | localized strings | "Dừng ép ngực quá 10 giây" |
| `dontImage?` | asset (wrong badge) | `Illus/FA/Ngửa đầu (sai)` |
| `seekCareIf[]` | localized strings, optional `call115` flag | "Cơn giật kéo dài trên 5 phút…: gọi 115" |
| `emergencyNumber` | string (config, not per page; inferred) | "115" |
| `review` | `{reviewedBy?, reviewedAt?, sources[]?}`; **not drawn**, only the generic line | "Được chuyên gia y tế rà soát qua Child Life." |
| `locale`, `version`, `status` | for publishing (inferred) | vi / en |
| `ageWindow?` | `{minMonths, maxMonths}` (inferred; not drawn) | infant vs toddler illustrations |
| `relatedSituations[]?` | refs (inferred) | TH03 / TH07 → TH01 |

Per-user state (inferred): `savedSituations` (bookmark; non-emergency pages only) and a **seizure timer** session (start/stop times; whether it is stored or logged is not drawn).

#### Static vs per-baby vs editorial
- **Static app copy (ARB):**
  - The headers "Làm theo các bước", "Không được làm", "Đưa bé đi viện ngay khi".
  - The buttons "Làm theo từng bước", "Gọi 115", "Bắt đầu", and the timer label "Bấm giờ cơn giật" / "00:00".
  - The offline tag "Dùng được khi không có mạng" and the disclaimer sentence (unless the reviewer is named per page).
  - The category tag labels could live in ARB or come from the CMS taxonomy (choose one).
- **Per-baby:** nothing is drawn. **Inferred:** the default segment ("Dưới 1 tuổi") could be picked from the selected baby's age. Situations could be filtered or ordered by age. Bookmarks and seizure-timer records could be per user.
- **Editorial (portal/CMS, medically reviewed):** title, summary, hero and step images, banner, variants, steps, chips, don'ts, seek-care items, category, emergency flag, order, review metadata, and the vi/en text.

#### Admin-portal candidates
- A **situation list** with CRUD, explicit ordering (TH01…TH24), a category, an emergency flag, publish/draft status, and versioning.
- A **category taxonomy** ("Khẩn cấp", "Vết thương & bỏng", others for TH13–TH24), with tag tone and order.
- A **step editor**: an ordered list of steps, each with an optional image and optional chips (label + tone). Plus a don't list (with an optional "wrong" image), a seek-care list, an optional banner, and **variant tabs** (age or condition) that each hold their own steps.
- An **illustration library** for the FA images: reusable across situations, with alt text (vi/en), a ✓ / ✗ badge flag, and a 1.6 : 1 crop for heroes and steps. The design already reuses bitmaps in several places.
- A **locale parity check** so vi and en have the same structure (D-012).
- A **medical review workflow**: reviewer, review date, source citations, and a "needs re-review" flag when text changes. The page currently claims review without any metadata.
- **Offline publishing**: a bundle or snapshot version that the app downloads and caches with its images, because every page promises offline use.
- **Age windows / applicability** per situation or variant (inferred).
- **Emergency number per region** (115 in VN), held in `config/` rather than in the copy (inferred).

#### Images and illustrations used
All are **PNG bitmaps in a soft 3D, Pixar-style look** with pastel backgrounds (mint, peach, butter yellow). They look like commissioned or AI-generated editorial art, not icons. There are 15 distinct bitmaps (asset hash in brackets):
| Layer name | Asset | Where |
|---|---|---|
| Illus/FA/Ép tim sơ sinh | b737c | TH01 hero |
| Illus/FA/Mở đường thở | 0ffa9 | TH01 step 1 |
| Illus/FA/Nằm nghiêng vỗ lưng | 90726 | TH02 hero |
| Illus/FA/Kích thích lòng bàn chân | 90a20 | TH02 step 2; **TH03 hero** |
| Illus/FA/Vỗ lưng | beeaf | TH02 step 3 |
| Illus/FA/Nằm nghiêng an toàn | 519a0 | TH04 hero; **TH06 step 2** |
| Illus/FA/Nằm ngửa kê cao chân | ac2eb | TH05 hero |
| Illus/FA/Hoá chất | fe122 | TH06 hero; **TH06 step 4** (layer "Mang theo vỏ thuốc") |
| Illus/FA/Không di chuyển | 3c800 | TH07 hero |
| Illus/FA/Ép gạc cầm máu | 9cc67 | TH07 step 4; **TH09 hero** |
| Illus/FA/Cúi đầu bóp mũi | c2cde | TH08 hero (✓ badge baked in) |
| Illus/FA/Ngửa đầu (sai) | f4952 | TH08 Don't box (✗ badge baked in) |
| Illus/FA/Quấn băng | 20689 | TH10 hero (✓ badge baked in) |
| Illus/FA/Xả nước mát | 300d8 | TH11 hero |
| Illus/FA/Chườm lạnh mắt cá | 2b70f | TH12 hero |

- Some bitmaps have the ✓ / ✗ badges baked into the image (TH06 hero, TH08, TH10), which blocks localization and accessibility.
- Icons: Icon/back, Icon/phone (16 / 20), Icon/alert, Icon/close, Icon/clock, Icon/bookmark, and bullet-dot SVGs (red for don'ts, dark for seek-care).
- No emoji, no gradients, no BabyFace avatar.

#### Open questions / gaps
1. ~~Only 12 of the 24 situations are drawn.~~ (Resolved during assembly: TH13–TH24 are drawn in the row at y 14000, part F, and 7b lists 25 = TH01–TH24 + Hóc dị vật 7d/7e.) The label says "chi tiết 24 tình huống" and the older label says 17. Where are TH13–TH24, and what is the final list and category set?
2. **"Làm theo từng bước" target:** the guided step-by-step mode is not drawn in this row. The button is a prototype hotspot only on TH01 (on the bar container) and is never a link on TH02–TH12.
3. **"Gọi 115" behaviour:** does it dial directly, or ask for confirmation first? What happens for en-locale or non-VN users (should the number be region config)? Should emergency pages also offer "Gọi 115" on a lock-screen or offline shortcut?
4. **Variant content not drawn:** TH01 "Từ 1 tuổi" (child CPR) and TH09 "Có dị vật". Does the age segment default to the selected baby's age?
5. **Review metadata:** no named reviewer, sources, or "updated" date on any page; only "Được chuyên gia y tế rà soát qua Child Life." Who reviews, and must sources be shown? This matters for medical liability and app-store health-content rules.
6. **Offline promise:** "Dùng được khi không có mạng" appears on every page. If the content comes from a CMS, the app needs a prefetch / cache and version strategy (text plus 15 images), or the content must ship bundled in the app.
7. **Bookmark (save):** shown only on non-emergency pages and never a link. Is it per user or per family, and where is the saved list?
8. **Seizure timer:** only the idle state ("00:00", "Bắt đầu") is drawn. Running and stopped states, background behaviour, and whether the result is logged to care history are all unknown.
9. **Colour tokens:** `#db4a45` and `#fcebe8` are raw hex. A `danger` / `danger-soft` token pair with Night-care values is needed. No Night-care variant is drawn, even though night-time use is likely for emergencies.
10. **Copy and content issues for the owner or medical reviewer:**
    - TH10's seek-care list includes "Thay băng khi băng bị ướt, bẩn", which is aftercare, not a hospital trigger.
    - TH03, TH09 and TH12 have no Don't list (is that intended?).
    - TH12 "Bong gân" is tagged "Vết thương & bỏng".
    - TH02 "Sặc sữa" is under emergency, while nosebleed is not (fine, but confirm the severity rules).
    - Medical values (5 initial breaths, 4 cm depth, 100–120 per minute, 10 minutes, 15–20 minutes, 48 hours, 5 minutes) need reviewer sign-off.
11. **Image reuse and mismatches:** TH03's hero is TH02's step image, TH09's hero is TH07's step image, and TH06 step 4 reuses the hero under a different layer name. Are dedicated images planned?
12. **Cross-links:** should "làm hồi sức tim phổi (CPR)" in TH03 and TH07 link to TH01?
13. **Age relevance:** TH07–TH12 show a preschool child, while the app's mock baby is 3 weeks old. Should situations carry an age window and be ordered or filtered by the baby's age?
14. **Shadow:** the step cards use a drop shadow (0/8/12 + 0/1/1) that differs from `shadow-card` (0/1/2 + 0/8/24). Assume `shadow-card`.

#### Coverage
12 of 12 frames read with `get_design_context` (one call each, no failures, no rate limits). 12 screenshots saved to `docs/discovery/figma-extract/img/v11/433-{3201,3343,3483,3566,3699,3793,3920,4047,4149,4234,4332,4423}.png`. I did not read the label nodes `433:54377` and `429:53391` (their text came from the task). I made no `get_metadata` calls.

---

## Part F — Sơ cứu (first aid) situation detail pages TH13–TH24

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only), page **"v1.1"**, cluster **7 · Sơ cứu**, row at canvas y 14000, frames 433:53311 … 433:54284. Read 2026-10-12 with one `get_design_context` per frame (clientFrameworks flutter, clientLanguages dart). No Figma write tool was called. Screenshots: `docs/discovery/figma-extract/img/v11/<node-id with : → ->.png` (rendered by the MCP at 269 px wide, i.e. ~0.72× of the 375 px frame).

Strings are the rendered text from the generated code (never layer names). English glosses in parentheses are engineering drafts. "(inferred)" marks anything not literally drawn. `<a … cursor-pointer>` nodes are marked **(prototype link)**; targets are never in the code, so all targets are inferred.

**Shared template** (identical across TH13–TH24 unless the frame section says otherwise; Part E documents the template and TH01–TH12 in full):
- Page `cloud #f6fcfb`, frame radius 40, Content column pt 52 / px 16 / pb 120 / gap 16, width 375.
- **StatusBar** (11:135 "Placeholder iOS status bar for screen mockups.").
- **Top row**: round white `back` (p 8, Icon/back 20 px) — **(prototype link)** → first-aid list / previous screen (inferred); spacer; round white `save` button with **Icon/bookmark** 20 px (NOT a prototype link; bookmark/save the situation, inferred).
- **Tags** row (pill, px 10 py 4, Bold 12): category tag on a category tint (e.g. `sunshine-soft #fff4d6` + `ink`) and a constant offline tag "Dùng được khi không có mạng" (Works without internet) on `surface-2 #eef6f5` + `ink-muted #55707a`.
- **Title** Bold 30 `ink #173d44`, lh 1.2.
- **Lead / symptom line** Medium 15 `ink-muted`, lh 1.45.
- **Hero illustration** 343 × ~214 (16:10), radius 24, `object-cover` raster image, layer "Illus/FA/<name>" (FA = first aid). 3D-style cartoon child render on a pastel background (editorial asset).
- **Section header** "Làm theo các bước" (Follow the steps), Bold 17 `ink`.
- **Step card** ("Bước N"): `surface` white, radius 20, p 16, shadow (drop 0/8/12 rgba(23,61,68,.08) + 0/1/1 .06 = `shadow-card`); number disc 30 px `mint-deep #087f7b` with Bold 15 `on-mint-deep` white numeral; gap 12; step title Bold 17 `ink`; step body Medium 15 `ink` lh 1.5.
- **"Không được làm" (Do NOT) box**: bg raw `#fcebe8`, radius 20, p 16, gap 10; header = red disc `#db4a45` (p 3) with Icon/close 14 px + "Không được làm" Bold 16 raw `#db4a45`; bullets = 6×13 dot + Medium 15 `ink`. **Raw hex, no tokens** for the red (`#fcebe8`, `#db4a45`).
- **"Đưa bé đi viện ngay khi" (Take baby to hospital immediately if) box**: `sunshine-soft #fff4d6`, radius 20, p 16; header = `sunshine #ffd166` disc with Icon/alert 14 px + Bold 16 `ink`; bullets as above. The "gọi 115" (call 115) text lives inside these bullets — there is **no separate call-115 button** on these frames.
- **Disclaimer / reviewer line** Medium 12 `ink-muted`, lh 1.5: "Nội dung tham khảo, không thay thế chẩn đoán của bác sĩ. Được chuyên gia y tế rà soát qua Child Life." (Reference content, not a substitute for a doctor's diagnosis. Reviewed by medical professionals via Child Life.) No source list, reviewer name or "updated on" date is drawn.
- **Bottom bar**: `surface` white, shadow 0/−4/8 rgba(0,0,0,.08), pt 12 / pb 30 / px 16; primary **Button** (8:33) h56 `mint-deep`, radius pill, Medium 17 white label "Làm theo từng bước" (Follow step by step) — not a prototype link in the code (inferred target: a step-by-step / one-step-per-screen guided mode).
- Text style seen: `Text/body-strong` (Be Vietnam Pro Medium 17/24). Effect `shadow-card`.
- Component descriptions (unchanged from earlier extracts): Icon/back 7:39, Icon/close 7:63, Icon/alert 7:53 ("Line icon (24px, 1.8 stroke) — placeholder drawing; production uses SF Symbols…"), StatusBar 11:135, Button 8:33 (the "1–2-word verb" rule is broken by "Làm theo từng bước").
- No TabDock, no BabySwitcher, no baby name or age anywhere — these pages are not per-baby.
- No Night care variant drawn; all frames Light.

---

### 433:53311 — 7 · TH13 · Gãy xương (Broken bone)
**Annotation:** none.

**Text (reading order)**
- Top: back **(prototype link)** · bookmark (save).
- Tags: "Vết thương & bỏng" (Wounds & burns; `sunshine-soft` + `ink`) · "Dùng được khi không có mạng" (Works without internet).
- Title: "Gãy xương" (Broken bone)
- Lead: "Sưng, biến dạng, đau dữ dội sau ngã" (Swelling, deformity, severe pain after a fall)
- Hero: Illus/FA/Nẹp cố định (splint) — boy lying on a blue mat with a pillow, a wooden splint strapped to his lower leg, cream background.
- "Làm theo các bước" (Follow the steps)
  1. "Quan sát vết thương" (Look at the injury) — "Biến dạng, sưng, bầm tím, đau dữ dội, không cử động được." (Deformity, swelling, bruising, severe pain, cannot move it.)
  2. "Cố định tạm bằng nẹp" (Temporarily immobilise with a splint) — "Dùng thanh thẳng (gậy, thước) đặt dọc chi bị gãy, quấn vải giữ cố định." (Use a straight stick (rod, ruler) along the broken limb and wrap cloth to hold it.)
  3. "Có vết thương hở: cầm máu" (Open wound: stop the bleeding) — "Lau nhẹ, băng vừa phải để máu vẫn lưu thông." (Wipe gently, bandage moderately so blood still circulates.)
  4. "Đưa bé đến bệnh viện" (Take baby to hospital) — "Thuốc giảm đau chỉ dùng theo chỉ định bác sĩ." (Only use painkillers as prescribed by a doctor.)
- "Không được làm" (Do not): • "Nắn chỉnh xương bị gãy" (Try to straighten the broken bone) • "Di chuyển tay, chân hay vùng bé đang đau" (Move the arm, leg or area that hurts)
- "Đưa bé đi viện ngay khi" (Go to hospital immediately if): • "Nghi gãy xương: luôn đưa bé đi viện" (Suspected fracture: always take baby to hospital) • "Nghi chấn thương đầu, cổ, lưng: gọi 115" (Suspected head, neck or back injury: call 115)
- Disclaimer: "Nội dung tham khảo, không thay thế chẩn đoán của bác sĩ. Được chuyên gia y tế rà soát qua Child Life."
- Bottom bar Button: "Làm theo từng bước" (Follow step by step)

**Layout / components / tokens:** exactly the shared template above (this is the reference frame). Frame height ≈ 1430 (bottom bar at y 1330.38 + 100). Section frame "Section · Làm theo các bước" has a trailing spacer (room for a right-side link that is not drawn).

**Visual:** long scrolling article: tags, big title, a warm 3D illustration, four white numbered step cards, a pink "do not" box, a yellow "go to hospital" box, small grey disclaimer, sticky teal button.

**Navigation:** back **(prototype link)** → first-aid list (inferred). Bookmark and bottom button have no prototype link.

**Notes / not shown:** category of a fracture is "Vết thương & bỏng" (Wounds & burns). Step 3 is conditional ("Có vết thương hở:" prefix) but uses the same step card — no conditional block type.

---

### 433:53417 — 7 · TH14 · Tổn thương ở mắt (Eye injury)
**Annotation:** none.

**Text (reading order)**
- Top: back **(prototype link)** · bookmark.
- Tags: "Vết thương & bỏng" (Wounds & burns) · "Dùng được khi không có mạng".
- Title: "Tổn thương ở mắt" (Eye injury)
- Lead: "Bụi, dị vật, sưng đỏ, chảy máu ở mắt" (Dust, foreign body, red swelling, bleeding in the eye)
- Hero: Illus/FA/Rửa mắt (eye rinse) — woman pouring water from a cup over a boy's eye, mint background.
- **Segmented** (2 options): "Có dị vật" (Foreign body; selected) · "Sưng, chảy máu" (Swelling, bleeding).
- "Làm theo các bước" — steps shown are for the selected variant "Có dị vật":
  1. "Không chạm tay vào mắt" (Don't touch the eye) — "Nhắc bé không dụi mắt." (Remind baby not to rub the eye.)
  2. "Nghiêng đầu, xối nước nhẹ" (Tilt the head, rinse gently) — "Mắt bị dị vật ở phía dưới. Xối nước sạch nhẹ nhàng, không xả mạnh." (Affected eye facing down. Pour clean water gently, not forcefully.)
  3. "Không ra: đi khám ngay" (Doesn't come out: see a doctor now) — "Che nhẹ mắt bằng gạc sạch, đưa bé đến bác sĩ." (Cover the eye lightly with clean gauze, take baby to a doctor.)
- "Không được làm": • "Xoa, dụi mắt" (Rub the eye) • "Tự nhỏ thuốc hay dung dịch không rõ nguồn gốc" (Put in drops or solutions of unknown origin yourself)
- "Đưa bé đi viện ngay khi": • "Mắt lồi, nhìn mờ hoặc mất thị lực, đau dữ dội" (Bulging eye, blurred or lost vision, severe pain) • "Dị vật không ra, máu không ngừng chảy" (Foreign body won't come out, bleeding won't stop)
- Disclaimer (standard text).
- Button: "Làm theo từng bước".

**Layout / components / tokens:** template + a new **Segmented** block between hero and steps: `surface-2 #eef6f5` track, radius 14, p 4, gap 2; selected segment `surface` white radius 10, px 10 py 8, SemiBold 14 `ink`; unselected Medium 14 `ink-muted`. Same segmented control style as Chi tiêu 8c/8d. Bottom bar at y 1268.38 (frame ≈ 1368 tall).

**Visual:** as template; the segmented control makes the article two-variant. Hero shows a caregiver rinsing a child's eye.

**Navigation:** back **(prototype link)**. The unselected segment "Sưng, chảy máu" is **not** a prototype link, and the steps for that variant are **not drawn** anywhere in this row.

**Notes / not shown:** the "do not" and "go to hospital" boxes appear to be shared by both variants (inferred — whether they change per variant is not stated). Variant B ("Sưng, chảy máu") content is missing; editorial must author it.

---

### 433:53511 — 7 · TH15 · Chó cắn (Dog bite)
**Annotation:** none.

**Text (reading order)**
- Top: back **(prototype link)** · bookmark.
- Tags: "Côn trùng & động vật" (Insects & animals; `sunshine-soft` + `ink` — same tint as "Vết thương & bỏng") · "Dùng được khi không có mạng".
- Title: "Chó cắn" (Dog bite)
- Lead: "Vết cắn, vết cào của chó, mèo" (Bites and scratches from dogs, cats)
- Hero: Illus/FA/Rửa xà phòng (soap wash) — boy washing his forearm under a tap, a puppy sitting beside, cream background.
- "Làm theo các bước"
  1. "Rửa xà phòng 10–15 phút" (Wash with soap for 10–15 minutes) — "Dưới vòi nước chảy. Đây là bước quan trọng nhất." (Under running water. This is the most important step.)
  2. "Sát trùng" (Disinfect) — "Dùng cồn 70 độ hoặc dung dịch iod." (Use 70 % alcohol or iodine solution.)
  3. "Băng lại, đi tiêm phòng" (Bandage, go get vaccinated) — "Đưa bé đến cơ sở y tế để được tư vấn tiêm vắc xin." (Take baby to a health facility for vaccination advice.)
- "Không được làm": • "Nặn máu ở vết cắn" (Squeeze blood out of the bite) • "Đắp lá hay thuốc không rõ nguồn gốc" (Apply leaves or medicine of unknown origin)
- "Đưa bé đi viện ngay khi": • "Mọi vết cắn đều cần đưa bé đi khám" (Every bite needs a doctor visit) — single bullet.
- Disclaimer (standard). Button "Làm theo từng bước".

**Layout / components / tokens:** template, no extra blocks. 3 steps; 2 do-not bullets; 1 hospital bullet. Bottom bar y 1131.38 (frame ≈ 1231).

**Visual:** template; illustration pairs the washing action with the animal (dog) as context.

**Navigation:** back **(prototype link)** only.

**Notes / not shown:** title says "Chó cắn" but the lead covers cats too. No "gọi 115" line. Rabies is implied ("tiêm phòng") but not named. Step 3 could deep-link to Tiêm chủng (vaccination) but no link is drawn.

---

### 433:53604 — 7 · TH16 · Ong đốt (Bee sting)
**Annotation:** none.

**Text (reading order)**
- Top: back **(prototype link)** · bookmark.
- Tags: "Côn trùng & động vật" (Insects & animals) · "Dùng được khi không có mạng".
- Title: "Ong đốt" (Bee sting)
- Lead: "Sưng đỏ, đau rát tại chỗ" (Red swelling, burning pain at the spot)
- Hero: Illus/FA/Khều ngòi ong (flicking out the stinger) — adult hand scraping a card across a sad boy's arm, cartoon bee flying in the corner, cream background.
- "Làm theo các bước"
  1. "Khều ngòi ra" (Flick the stinger out) — "Dùng nhíp hoặc thẻ cứng khều nhẹ. Không bóp, không nặn." (Use tweezers or a hard card to flick it gently. Don't pinch or squeeze.)
  2. "Rửa và chườm lạnh" (Wash and cool) — "Rửa bằng nước sạch, xà phòng. Chườm túi đá bọc khăn 10–15 phút." (Wash with clean water and soap. Apply an ice pack wrapped in a towel for 10–15 minutes.)
  3. "Sát khuẩn nhẹ" (Gently disinfect) — "Bôi dung dịch sát khuẩn như cồn 70 độ." (Apply an antiseptic such as 70 % alcohol.)
- **No "Không được làm" box** on this frame.
- "Đưa bé đi viện ngay khi": • "Phát ban, khó thở, sưng lớn, nôn: dấu hiệu sốc phản vệ, gọi 115" (Rash, difficulty breathing, major swelling, vomiting: signs of anaphylaxis, call 115)
- Disclaimer (standard). Button "Làm theo từng bước".

**Layout / components / tokens:** template minus the do-not box (so the do-not block is optional). Bottom bar y 1043.38 (frame ≈ 1143).

**Visual:** template; shortest of the TH13–TH16 pages.

**Navigation:** back **(prototype link)** only.

**Notes / not shown:** step 1 body contains a "do not" ("Không bóp, không nặn") inline instead of in a do-not box — authoring inconsistency. Anaphylaxis = the "call 115" trigger.

---

### 433:53682 — 7 · TH17 · Kiến ba khoang (Rove beetle / Paederus "three-section ant")
**Annotation:** none.

**Text (reading order)**
- Top: back **(prototype link)** · bookmark.
- Tags: "Côn trùng & động vật" · "Dùng được khi không có mạng".
- Title: "Kiến ba khoang" (Rove beetle, Paederus)
- Lead: "Vết đỏ rát, phồng rộp" (Red burning mark, blistering)
- Hero: Illus/FA/Gạt kiến (brushing the insect off) — adult hand sweeping a sheet of paper over an insect on a boy's forearm, with a green check-mark badge, cream background. The check badge marks the "right way" (illustration carries a do/don't cue).
- "Làm theo các bước"
  1. "Thổi hoặc gạt kiến đi" (Blow or brush the insect away) — "Dùng giấy gạt nhẹ. Không đập, không bắt bằng tay." (Brush gently with paper. Don't swat or pick it up by hand.)
  2. "Rửa ngay dưới vòi nước" (Wash under running water right away) — "Nếu lỡ chạm hoặc chà xát, rửa sạch bằng xà phòng." (If touched or rubbed, wash thoroughly with soap.)
  3. "Hỏi dược sĩ về thuốc bôi" (Ask a pharmacist about a cream) — "Không tự bôi thuốc khi chưa có hướng dẫn." (Don't apply medicine without guidance.)
- **No "Không được làm" box.**
- "Đưa bé đi viện ngay khi": • "Vết thương lan rộng, phồng rộp nhiều, gần mắt" (Wound spreads, many blisters, near the eyes)
- Disclaimer (standard). Button "Làm theo từng bước".

**Layout / components / tokens:** template minus do-not box; bottom bar y 1043.38 (frame ≈ 1143), same height as TH16.

**Visual:** template.

**Navigation:** back **(prototype link)** only.

**Notes / not shown:** no "gọi 115". Don'ts are again inline in step bodies.

---

### 433:53759 — 7 · TH18 · Côn trùng vào tai (Insect in the ear)
**Annotation:** none.

**Text (reading order)**
- Top: back **(prototype link)** · bookmark.
- Tags: "Côn trùng & động vật" · "Dùng được khi không có mạng".
- Title: "Côn trùng vào tai" (Insect in the ear)
- Lead: "Bé ngứa, đau, quấy, ôm tai" (Baby itchy, in pain, fussy, holding the ear)
- Hero: Illus/FA/Đèn pin vào tai (torch into the ear) — adult hands shining a small torch into a boy's ear, **dark navy background** (only dark hero in this row; conveys "darkened room").
- "Làm theo các bước"
  1. "Tắt đèn, chiếu đèn pin" (Turn off the lights, shine a torch) — "Đưa bé vào chỗ tối, chiếu đèn vào ống tai để côn trùng bò ra theo ánh sáng." (Take baby somewhere dark, shine the light into the ear canal so the insect crawls out toward the light.)
  2. "Chưa ra: đi khám" (Still not out: see a doctor) — "Đưa bé đến bác sĩ tai mũi họng." (Take baby to an ENT doctor.)
- "Không được làm": • "Dùng tăm, que hay vật nhọn ngoáy tai" (Use toothpicks, sticks or sharp objects to dig in the ear)
- "Đưa bé đi viện ngay khi": • "Bé đau nhiều, chảy máu hoặc dịch ở tai" (Baby in a lot of pain, blood or fluid from the ear)
- Disclaimer (standard). Button "Làm theo từng bước".

**Layout / components / tokens:** template; 2 steps (fewest so far), 1 do-not bullet, 1 hospital bullet. Bottom bar y 1001.38 (frame ≈ 1101).

**Visual:** template with a dark hero image.

**Navigation:** back **(prototype link)** only.

**Notes / not shown:** no "gọi 115". "Làm theo từng bước" for a 2-step guide is arguably unnecessary — whether the button hides below N steps is not stated.

---

### 433:53833 — 7 · TH19 · Rắn cắn (Snake bite) — **emergency variant**
**Annotation:** none.

**Text (reading order)**
- Top: back **(prototype link)** · spacer · **red pill "Gọi 115"** (Call 115) with Icon/phone 16 px — **(prototype link)**. It **replaces the bookmark button** (no save on this page).
- Tags: "Côn trùng & động vật" · "Dùng được khi không có mạng".
- Title: "Rắn cắn" (Snake bite)
- Lead: "Có hai vết răng nanh rõ" (Two clear fang marks)
- Hero: Illus/FA/Rắn cắn băng nhẹ (snake bite, light bandage) — boy lying on a green mat, bandage on his lower leg, woman kneeling to calm him, small green snake in the corner, cream background.
- "Làm theo các bước"
  1. "Trấn an, giữ bé nằm yên" (Calm baby, keep them lying still) — "Hạn chế cử động để nọc độc lan chậm hơn." (Limit movement so venom spreads more slowly.)
  2. "Băng nhẹ, tháo trang sức" (Light bandage, remove jewellery) — "Quấn gạc nhẹ quanh vết cắn. Tháo quần áo chật, trang sức ở vùng bị cắn." (Wrap gauze loosely around the bite. Remove tight clothing and jewellery near the bite.)
  3. "Đưa đi viện ngay" (Go to hospital right away) — "Ghi nhớ hình dạng, màu sắc của rắn." (Remember the snake's shape and colour.)
- "Không được làm": • "Garo hay buộc chặt" (Apply a tourniquet or tie tightly) • "Chườm đá, bôi thuốc lên vết cắn" (Apply ice or medicine to the bite)
- "Đưa bé đi viện ngay khi": • "Mọi vết rắn cắn đều cần đưa bé đi viện ngay" (Every snake bite needs hospital immediately)
- Disclaimer (standard).
- Bottom bar (gap 10): primary Button "Làm theo từng bước" (flex) + **red pill "Gọi 115"** (px 20 py 15, Icon/phone 20 px, Bold 16 white) — **(prototype link)**.

**Layout / components / tokens:**
- New **Call-115 button**, two sizes: header pill (bg raw `#db4a45`, px 14 py 8, radius 999, gap 8, Icon/phone 16 px white, Bold 14 **raw `text-white`** — not a token) and bottom-bar pill (px 20 py 15 ≈ 50 h — shorter than the 56 h primary Button beside it, Icon/phone 20 px, Bold 16 white). Not the Button component (8:33); a raw `<a>` frame. **Icon/phone** is a new icon (two asset variants, 16 px and 20 px; no component description returned).
- Bottom bar becomes a 2-button row. Bottom bar y 1177.38 (frame ≈ 1277).

**Visual:** same article template, but red "Gọi 115" appears twice — top right and bottom right — signalling a life-threatening situation.

**Navigation:** back **(prototype link)**; both "Gọi 115" **(prototype link)** → native dialer `tel:115` (inferred; Figma probably links to a confirm/overlay frame, target unknown). "Làm theo từng bước" not linked.

**Notes / not shown:** a per-situation flag (e.g. `emergency: true` / `showCall115`) must drive the red buttons and the absence of bookmark (inferred). No confirmation step before dialling is drawn. Whether 115 is locale-dependent (other countries) is not addressed.

---

### 433:53925 — 7 · TH20 · Say nắng, say nóng (Sunstroke, heatstroke) — **emergency variant**
**Annotation:** none.

**Text (reading order)**
- Top: back **(prototype link)** · red pill "Gọi 115" **(prototype link)** (no bookmark).
- Tags: **"Sức khoẻ"** (Health; **`mint-soft #e6f7f5` + `mint-text #06716d`** — a second category tint) · "Dùng được khi không có mạng".
- Title: "Say nắng, say nóng" (Sunstroke, heatstroke)
- Lead: "Chóng mặt, nhức đầu, người nóng sau khi ở ngoài nắng" (Dizziness, headache, hot body after being out in the sun)
- Hero: Illus/FA/Làm mát cơ thể (cooling the body) — boy lying under a tree in the shade, woman fanning him, cartoon sun top right, light background.
- "Làm theo các bước"
  1. "Đưa bé vào chỗ mát" (Move baby somewhere cool) — "Nơi thoáng gió. Tình trạng không khá lên: gọi 115." (A breezy place. If not improving: call 115.)
  2. "Làm mát cơ thể" (Cool the body) — "Cởi bớt quần áo, quạt mát. Đắp khăn mát ở nách, bẹn, cổ." (Remove some clothes, fan. Put cool cloths on armpits, groin, neck.)
  3. "Cho uống nước" (Give water) — "Nước hoặc dung dịch điện giải, chỉ khi bé tỉnh táo và uống được." (Water or electrolyte solution, only if baby is alert and can drink.)
  4. "Đưa đi khám, tiếp tục làm mát" (Go to the doctor, keep cooling) — "Đo nhiệt độ thường xuyên, chườm mát cả trên đường đi." (Check temperature often, keep cool compresses on the way.)
- "Không được làm": • "Cho bé uống khi đang lơ mơ" (Give drinks while baby is drowsy/semi-conscious)
- "Đưa bé đi viện ngay khi": • "Bé lơ mơ, hôn mê: gọi 115, làm hồi sức tim phổi nếu bé ngừng thở" (Drowsy, unconscious: call 115, do CPR if baby stops breathing) • "Sốt cao, nôn, co giật" (High fever, vomiting, seizures)
- Disclaimer (standard).
- Bottom bar: "Làm theo từng bước" + red "Gọi 115" **(prototype link)**.

**Layout / components / tokens:** emergency template (as TH19). Bottom bar y 1319.38 (frame ≈ 1419).

**Visual:** emergency template; mint "Sức khoẻ" tag instead of yellow.

**Navigation:** back, both "Gọi 115" **(prototype link)**. "hồi sức tim phổi" (CPR) is plain text, not a link — a cross-link to a CPR situation (likely in TH01–TH12, inferred) would be expected but is not drawn.

**Notes / not shown:** "gọi 115" also appears inline in step 1 body and a hospital bullet; inline 115 mentions are plain text.

---

### 433:54033 — 7 · TH21 · Đo thân nhiệt (Taking body temperature) — **how-to / monitoring variant**
**Annotation:** none.

**Text (reading order)**
- Top: back **(prototype link)** · bookmark.
- Tags (three): "Sức khoẻ" (Health; `mint-soft` + `mint-text`) · **"Theo dõi"** (Monitoring; `surface-2` + `ink-muted`, same neutral style as the offline tag) · "Dùng được khi không có mạng".
- Title: "Đo thân nhiệt" (Taking body temperature)
- Lead: "Cách đo đúng và khi nào cần đi khám" (How to measure correctly and when to see a doctor)
- Hero: Illus/FA/Đo nhiệt độ (measuring temperature) — boy sitting cross-legged with a thermometer under his arm, a callout bubble showing a digital thermometer, mint background.
- "Làm theo các bước"
  1. "Chọn nhiệt kế" (Choose a thermometer) — "Nhiệt kế điện tử hoặc hồng ngoại. Vệ sinh trước và sau khi đo." (Digital or infrared thermometer. Clean before and after use.)
  2. "Đo đúng cách" (Measure correctly) — "Điện tử: kẹp dưới nách 1–2 phút. Hồng ngoại: đo ở trán hoặc tai, vùng đo sạch, khô." (Digital: under the armpit for 1–2 minutes. Infrared: forehead or ear, the area clean and dry.)
  3. "Đợi 15 phút sau khi ăn uống" (Wait 15 minutes after eating or drinking) — "Giữ cố định nhiệt kế khi đo cho trẻ nhỏ." (Hold the thermometer steady for young children.)
- **New box "Khi nào cần đi khám"** (When to see a doctor) — same yellow style as the hospital box (`sunshine-soft`, `sunshine` disc, Icon/alert). **Age-banded** bullets:
  • "Dưới 3 tháng: từ 38°C đưa đi viện ngay" (Under 3 months: from 38 °C go to hospital immediately)
  • "3 tháng – 3 tuổi: trên 38,5°C theo dõi sát, hỏi bác sĩ về thuốc hạ sốt" (3 months – 3 years: above 38.5 °C monitor closely, ask a doctor about fever reducers)
  • "Trên 3 tuổi: sốt kéo dài, mệt nhiều, có dấu hiệu bất thường" (Over 3 years: prolonged fever, very tired, unusual signs)
- "Đưa bé đi viện ngay khi": • "Sốt kèm co giật, khó thở, li bì: gọi 115" (Fever with seizures, difficulty breathing, lethargy: call 115)
- **No "Không được làm" box.**
- Disclaimer (standard). Button "Làm theo từng bước" (bookmark variant; no red 115 buttons even though a bullet says "gọi 115").

**Layout / components / tokens:** template + a second yellow callout with a different heading — so the callout heading is free text, not fixed. Two yellow boxes stacked look identical apart from the title. Number formatting uses Vietnamese decimal comma "38,5°C" and no space before °C. Bottom bar y 1256.38 (frame ≈ 1356).

**Visual:** template; "how-to" rather than an emergency; mint hero.

**Navigation:** back **(prototype link)** only.

**Notes / not shown:** age bands are content only — no personalisation to the current baby's age is drawn (could highlight the matching band for Teddy, inferred opportunity). No link to logging a temperature in Chăm sóc / a fever tracker. Thresholds (38 °C, 38,5 °C, 3 months, 3 years) are medical content that must be reviewed.

---

### 433:54128 — 7 · TH22 · Ngộ độc thực phẩm (Food poisoning)
**Annotation:** none.

**Text (reading order)**
- Top: back **(prototype link)** · bookmark.
- Tags: "Sức khoẻ" (Health; mint) · "Dùng được khi không có mạng".
- Title: "Ngộ độc thực phẩm" (Food poisoning)
- Lead: "Nôn, đau bụng, tiêu chảy" (Vomiting, stomach ache, diarrhoea)
- Hero: Illus/FA/Uống nước bù (rehydration drink) — boy wrapped in a blanket sipping from a glass held by an adult hand, mint background.
- "Làm theo các bước"
  1. "Bù nước cho bé" (Rehydrate baby) — "Cho uống nhiều nước, dung dịch bù nước theo hướng dẫn của bác sĩ, dược sĩ." (Give plenty of water and rehydration solution as directed by a doctor or pharmacist.)
  2. "Không tự dùng thuốc cầm tiêu chảy" (Don't give anti-diarrhoea medicine yourself) — "Có thể gây biến chứng nguy hiểm." (It can cause dangerous complications.)
  3. "Theo dõi sát" (Monitor closely) — "Số lần nôn, đi ngoài, lượng nước bé uống." (Number of vomits, stools, amount of fluid drunk.)
- **No "Không được làm" box** (the don't is step 2 instead — a "don't" authored as a step).
- "Đưa bé đi viện ngay khi": • "Sốt cao trên 39°C, lừ đừ, tim đập nhanh" (High fever above 39 °C, listless, fast heartbeat) • "Nôn kéo dài trên 12 giờ" (Vomiting lasting more than 12 hours)
- Disclaimer (standard). Button "Làm theo từng bước".

**Layout / components / tokens:** template minus do-not box. Bottom bar y 1075.38 (frame ≈ 1175).

**Visual:** template; mint hero.

**Navigation:** back **(prototype link)** only.

**Notes / not shown:** step 3 ("count vomits, stools, fluids") maps naturally onto the app's care log (Tã / diaper, Bú / feed) but no link to logging is drawn. No "gọi 115".

---

### 433:54201 — 7 · TH23 · Nhiễm lạnh (Getting chilled / mild hypothermia)
**Annotation:** none.

**Text (reading order)**
- Top: back **(prototype link)** · bookmark.
- Tags: "Sức khoẻ" (mint) · "Dùng được khi không có mạng".
- Title: "Nhiễm lạnh" (Getting chilled)
- Lead: "Run, tay chân lạnh, tái" (Shivering, cold hands and feet, pale)
- Hero: Illus/FA/Quấn chăn ấm (wrapped in a warm blanket) — smiling boy wrapped in a lilac star-print blanket next to a steaming mug, peach background.
- "Làm theo các bước"
  1. "Đưa vào chỗ ấm" (Move somewhere warm) — "Tránh gió lạnh. Bé bị ướt: thay ngay quần áo khô." (Avoid cold wind. If baby is wet: change into dry clothes immediately.)
  2. "Làm ấm từ từ" (Warm up gradually) — "Quấn chăn ấm, khăn mềm. Túi chườm ấm không đặt trực tiếp lên da." (Wrap in a warm blanket, soft towel. Don't put a hot-water bag directly on the skin.)
  3. "Cho uống nước ấm" (Give a warm drink) — "Nước ấm hoặc sữa ấm." (Warm water or warm milk.)
- **No "Không được làm" box.**
- "Đưa bé đi viện ngay khi": • "Run rẩy, tái nhợt không cải thiện khi đã làm ấm" (Shivering, pallor not improving after warming) • "Lả đi, khó thở, không phản ứng" (Limp, difficulty breathing, unresponsive)
- Disclaimer (standard). Button "Làm theo từng bước".

**Layout / components / tokens:** template minus do-not box. Bottom bar y 1076.38 (frame ≈ 1176).

**Visual:** template; warm peach hero.

**Navigation:** back **(prototype link)** only.

**Notes / not shown:** "Lả đi, khó thở, không phản ứng" is arguably a call-115 situation, but no 115 text or button — emergency flag is per situation, not per bullet. Step 3 "sữa ấm" (warm milk) has no age caveat for newborns (content review point).

---

### 433:54284 — 7 · TH24 · Vàng da sơ sinh (Newborn jaundice) — **comparison / information variant (no steps)**
**Annotation:** none.

**Text (reading order)**
- Top: back **(prototype link)** · bookmark.
- Tags: "Sức khoẻ" (mint) · "Theo dõi" (Monitoring; neutral) · "Dùng được khi không có mạng".
- Title: "Vàng da sơ sinh" (Newborn jaundice)
- Lead: "Phân biệt sinh lý và bệnh lý" (Telling physiological from pathological)
- Hero: Illus/FA/So sánh vàng da (jaundice comparison) — two sleeping newborn faces side by side, left normal pink skin, right yellow skin, cream background. Only hero in this row that is a **comparison image** rather than an action scene; looks like a realistic 3D render of babies (not the cartoon boy) — editorial image with medical accuracy implications.
- **No "Làm theo các bước" section and no step cards.**
- **New positive box "Vàng da sinh lý"** (Physiological jaundice): bg `mint-soft #e6f7f5`, radius 20, p 16; header = `mint-deep` disc with **Icon/check** (7:45) 14 px + Bold 16 `mint-text #06716d`; bullets with a mint dot:
  • "Vàng nhẹ ở mặt, cổ, ngực, bụng trên rốn" (Mild yellow on face, neck, chest, belly above the navel)
  • "Xuất hiện 48–72 giờ sau sinh" (Appears 48–72 hours after birth)
  • "Tự hết trong 1 tuần (sinh non: 2 tuần)" (Clears by itself within 1 week (premature: 2 weeks))
  • "Bé bú tốt, lên cân đều" (Baby feeds well, gains weight steadily)
- **Red box re-titled "Cần đi khám ngay"** (Needs a doctor now) — same style as "Không được làm" (`#fcebe8`, `#db4a45` disc + Icon/close, red heading) but used for **warning signs**, not don'ts:
  • "Vàng đậm toàn thân và cả mắt" (Deep yellow all over the body and in the eyes)
  • "Xuất hiện ngay ngày đầu sau sinh" (Appears on the very first day after birth)
  • "Kéo dài quá 1 tuần (sinh non: 2 tuần)" (Lasts more than 1 week (premature: 2 weeks))
  • "Bỏ bú, nôn, sốt, lừ đừ, phân bạc màu" (Refuses feeds, vomiting, fever, listless, pale stools)
- "Đưa bé đi viện ngay khi": • "Nghi vàng da bệnh lý: đưa bé đi khám ngay" (Suspected pathological jaundice: take baby to a doctor now)
- Disclaimer (standard).
- **No bottom bar / no "Làm theo từng bước" button** (nothing to step through). Frame has no bottom-bar node; content ends after the disclaimer.

**Layout / components / tokens:** template header + three callout boxes (positive/mint, negative/red, warning/yellow). Callout box = one component with a **tone** (positive `mint-soft`/`mint-deep`/`mint-text`/Icon/check; negative `#fcebe8`/`#db4a45`/Icon/close; warning `sunshine-soft`/`sunshine`/Icon/alert) and a free-text heading. Dots: three asset variants (mint 382d6, red 4b9d6, ink bb8a3).

**Visual:** comparison page: two baby faces, then green "normal" list, red "see a doctor" list, yellow box, disclaimer. No sticky button.

**Navigation:** back **(prototype link)** only.

**Notes / not shown:** this is the most baby-age-relevant page for the mock baby (Teddy is ~3 weeks in other clusters) — no personalisation or "your baby is X days old" hint is drawn. "Phân bạc màu" (pale stool) suggests a stool-colour card that is not drawn. Red box ("Cần đi khám ngay") and yellow box ("Đưa bé đi viện ngay khi") overlap in meaning.

---

### Template summary (TH13–TH24)

| Frame | Category tag | Extra tags | Steps | Do-not box | Other callouts | Hospital bullets | "gọi 115" text | Red Gọi 115 buttons | Bottom button | Segmented | Hero (Illus/FA/…) | Frame h ≈ |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| TH13 Gãy xương | Vết thương & bỏng | — | 4 | 2 | — | 2 | yes (bullet) | no | yes | — | Nẹp cố định | 1430 |
| TH14 Tổn thương ở mắt | Vết thương & bỏng | — | 3 | 2 | — | 2 | no | no | yes | 2 options | Rửa mắt | 1368 |
| TH15 Chó cắn | Côn trùng & động vật | — | 3 | 2 | — | 1 | no | no | yes | — | Rửa xà phòng | 1231 |
| TH16 Ong đốt | Côn trùng & động vật | — | 3 | — | — | 1 | yes (bullet) | no | yes | — | Khều ngòi ong | 1143 |
| TH17 Kiến ba khoang | Côn trùng & động vật | — | 3 | — | — | 1 | no | no | yes | — | Gạt kiến | 1143 |
| TH18 Côn trùng vào tai | Côn trùng & động vật | — | 2 | 1 | — | 1 | no | no | yes | — | Đèn pin vào tai | 1101 |
| TH19 Rắn cắn | Côn trùng & động vật | — | 3 | 2 | — | 1 | no (buttons only) | **header + bottom** | yes | — | Rắn cắn băng nhẹ | 1277 |
| TH20 Say nắng, say nóng | Sức khoẻ | — | 4 | 1 | — | 2 | yes (step + bullet) | **header + bottom** | yes | — | Làm mát cơ thể | 1419 |
| TH21 Đo thân nhiệt | Sức khoẻ | Theo dõi | 3 | — | "Khi nào cần đi khám" (yellow, age bands) | 1 | yes (bullet) | no | yes | — | Đo nhiệt độ | 1356 |
| TH22 Ngộ độc thực phẩm | Sức khoẻ | — | 3 | — | — | 2 | no | no | yes | — | Uống nước bù | 1175 |
| TH23 Nhiễm lạnh | Sức khoẻ | — | 3 | — | — | 2 | no | no | yes | — | Quấn chăn ấm | 1176 |
| TH24 Vàng da sơ sinh | Sức khoẻ | Theo dõi | **0** | — | "Vàng da sinh lý" (mint), "Cần đi khám ngay" (red) | 1 | no | no | **none** | — | So sánh vàng da | ~1100 (no bar) |

Category tag tints: "Vết thương & bỏng" and "Côn trùng & động vật" both `sunshine-soft` + `ink`; "Sức khoẻ" `mint-soft` + `mint-text`; "Theo dõi" and "Dùng được khi không có mạng" `surface-2` + `ink-muted`.

#### Block types seen
1. **Header row** — back (always a prototype link) + either **bookmark/save** (normal) or **red "Gọi 115" pill** (emergency: TH19, TH20). Never both.
2. **Tag row** — 1 category tag (tinted per category) + 0–1 secondary tag ("Theo dõi") + constant offline tag "Dùng được khi không có mạng".
3. **Title** (Bold 30) and **lead/symptom line** (Medium 15 muted).
4. **Hero image** — 343 × 214.375 (16:10), radius 24, raster `Illus/FA/<name>`.
5. **Segmented variant switch** (TH14 only) — 2 options splitting one situation into sub-scenarios; only option 1's content is drawn.
6. **Section header** "Làm theo các bước" (fixed copy).
7. **Numbered step card** — number disc + title (Bold 17) + body (Medium 15). 2–4 per page; 0 on TH24. Step titles sometimes carry a condition prefix ("Có vết thương hở:", "Không ra:", "Chưa ra:").
8. **Callout box with tone + heading + bullet list**:
   - negative/red (`#fcebe8`, `#db4a45`, Icon/close): heading "Không được làm" (TH13–15, 18–20) or "Cần đi khám ngay" (TH24);
   - warning/yellow (`sunshine-soft`, `sunshine`, Icon/alert): heading "Đưa bé đi viện ngay khi" (all 12) or "Khi nào cần đi khám" (TH21);
   - positive/mint (`mint-soft`, `mint-deep`, Icon/check): heading "Vàng da sinh lý" (TH24).
9. **Disclaimer/reviewer line** — identical fixed text on all 12.
10. **Sticky bottom bar** — primary "Làm theo từng bước" (11 of 12), plus red "Gọi 115" pill on emergency pages; absent on TH24.
11. **Inline "gọi 115" text** in steps/bullets — plain text, never a link.

Not seen in this row: sources/citations list, named reviewer, "updated on" date, age-applicability label, related-situations links, video, share button, step images, timers.

#### Data model implied

**FirstAidSituation** (editorial, global — not per baby)
| Field | Type | Example from design |
|---|---|---|
| id / code | string | "TH13" (frame names; code likely internal) |
| slug | string | "gay-xuong" (inferred) |
| order | int | 13 (inferred from TH numbering) |
| categoryId | ref → Category | "Vết thương & bỏng" |
| secondaryTags | string[] / enum | ["Theo dõi"] (TH21, TH24) |
| offlineAvailable | bool (always true here) | tag "Dùng được khi không có mạng" |
| title | localized string | "Gãy xương" |
| lead | localized string | "Sưng, biến dạng, đau dữ dội sau ngã" |
| heroImage | image ref + alt text | Illus/FA/Nẹp cố định (343×214, 16:10) |
| isEmergency / showCall115 | bool | true for TH19, TH20 (drives header + bottom red buttons, hides bookmark) |
| emergencyNumber | string | "115" (VN; locale-dependent, inferred) |
| variants | Variant[] (≥1) | TH14: "Có dị vật", "Sưng, chảy máu" |
| blocks (per variant or shared) | Block[] ordered | see below |
| hasStepMode | bool / derived (steps.length > 0) | false for TH24 |
| disclaimer | localized string (global, not per page) | standard text |
| reviewStatus / reviewer / reviewedAt / sources | (not drawn; required by "Được chuyên gia y tế rà soát") | — |
| locale | vi / en | Vietnamese drawn only |

**Variant**: `{ label: "Có dị vật", steps: Step[], callouts?: Callout[] }` — whether callouts are per variant is unknown.

**Step**: `{ index: 1, title: "Quan sát vết thương", body: "Biến dạng, sưng, …" }` (no image, no timer, no condition field — conditions are in the title text).

**Callout**: `{ tone: negative|warning|positive, heading: "Không được làm" | "Đưa bé đi viện ngay khi" | "Khi nào cần đi khám" | "Cần đi khám ngay" | "Vàng da sinh lý", bullets: string[] }`. Heading is free text (or a preset with override).

**Category**: `{ name: "Côn trùng & động vật", tint: sunshine-soft|mint-soft, order }`. Seen: "Vết thương & bỏng", "Côn trùng & động vật", "Sức khoẻ".

**Per-user**: **Bookmark/SavedSituation** `{ userId, situationId, savedAt }` (bookmark button; per user or per family, inferred).

No per-baby field is shown on any page.

#### Static vs per-baby vs editorial
- **Static app copy (ARB):** "Làm theo các bước", "Làm theo từng bước", "Gọi 115", "Dùng được khi không có mạng", default callout headings ("Không được làm", "Đưa bé đi viện ngay khi"), the disclaimer sentence (could be editorial if it must name the reviewer), back/bookmark a11y labels.
- **Editorial (portal/CMS, per locale):** situation title, lead, category, secondary tags, hero image + alt, variants, steps, callout headings when non-default, bullets, emergency flag, ordering, reviewer/sources/dates (needed but not drawn).
- **Per-user:** bookmark state. **Per-baby:** nothing drawn (possible future: highlight age band in TH21 / jaundice relevance in TH24 by baby age).
- **Offline:** the whole corpus must ship bundled or be cached on device ("Dùng được khi không có mạng" on every page) — includes hero images.

#### Admin-portal candidates
- **Situations list** (create/edit/reorder/publish/unpublish), with code (TH01…), category, tags, emergency toggle (+ number per locale), offline flag.
- **Rich structured editor**: variants (tabs), ordered steps (title + body), callouts (tone + heading + bullets), lead, title.
- **Categories** (name, tint token, order) and **secondary tags** ("Theo dõi").
- **Hero image library** (Illus/FA/*): upload 16:10 asset, alt text per locale, art-direction review (medical accuracy, e.g. jaundice skin tones).
- **Medical review workflow**: reviewer name/credentials, review date, sources/citations, next-review date, version history — required to justify the "Được chuyên gia y tế rà soát qua Child Life" claim.
- **Locale** vi/en parity check (D-012) per situation.
- **Age applicability** (e.g. TH24 newborn-only, TH21 age bands) — optional field for filtering/personalisation.
- **Offline bundle publishing** — versioned content pack the app downloads/caches.

#### Images and illustrations used
- **Hero rasters (editorial, 3D cartoon renders, one per page):** Illus/FA/Nẹp cố định, Rửa mắt, Rửa xà phòng, Khều ngòi ong, Gạt kiến (with green check badge), Đèn pin vào tai (dark navy bg), Rắn cắn băng nhẹ, Làm mát cơ thể, Đo nhiệt độ, Uống nước bù, Quấn chăn ấm, So sánh vàng da (two realistic newborn faces, normal vs yellow). Same recurring boy character (brown hair, blue T-shirt) in 11 of 12; adult carers shown as a woman in a coral top or hands only. Backgrounds: cream/yellow, mint, peach, navy.
- **Icons:** Icon/back (7:39), Icon/bookmark, Icon/close (7:63), Icon/alert (7:53), Icon/check (7:45), **Icon/phone** (new, 16 and 20 px, white, no description returned). Bullet dots: 6×13 SVG in three colours (red, ink, mint).
- No emoji, no gradients, no BabyFace avatars, no photos of real people.

#### Open questions / gaps
1. **"Làm theo từng bước" target** — the guided step-by-step mode is not drawn in this row (maybe in TH01–TH12 / template frames). What does it look like, and is it offered for 2-step pages (TH18)?
2. **Emergency rule** — what makes a situation "emergency" (red Gọi 115 header + bottom)? TH19/TH20 have it; TH13 (head/neck injury → 115), TH16 (anaphylaxis → 115) and TH21 ("gọi 115") do not. Editorial flag or derived from content?
3. **Gọi 115 behaviour** — direct `tel:115`, or confirmation sheet? Locale/country handling for en users outside VN?
4. **Segmented variants (TH14)** — content for "Sưng, chảy máu" is missing; are callouts shared across variants?
5. **Bookmark** — where do saved situations appear (list, Today, offline)? Per user or per family? Hidden on emergency pages by design?
6. **Medical review metadata** — disclaimer claims expert review but no reviewer, sources or updated date are drawn; is that acceptable for store/medical-content policies?
7. **Callout semantics** — red box means "don't" on most pages but "needs a doctor now" on TH24; yellow means "go to hospital" and "when to see a doctor". Define a fixed tone→meaning mapping or allow free headings?
8. **Raw colours** — `#fcebe8`, `#db4a45` and `text-white` are not tokens; need a `danger` / `danger-soft` / `on-danger` token and a Night care mapping. No Night care variant drawn.
9. **Personalisation by baby age** (TH21 bands, TH24 newborn) — in scope or not?
10. **Cross-links** — CPR mention (TH20), vaccination after dog bite (TH15), logging vomits/stools (TH22), temperature logging (TH21) are not linked.
11. **Offline packaging** — bundle in app vs downloadable pack; image weight of 24 heroes.
12. **Content consistency** — "do not" items authored inside steps (TH16, TH17, TH22) vs in the red box; style guide needed.

#### Coverage
12 of 12 frames read with one `get_design_context` each (433:53311, 53417, 53511, 53604, 53682, 53759, 53833, 53925, 54033, 54128, 54201, 54284); 0 failures, 0 rate-limit errors; no `get_metadata` or `get_screenshot` needed. 12 screenshots saved to `docs/discovery/figma-extract/img/v11/433-53311.png` … `433-54284.png` (269–350 px wide renders returned by the MCP). No `data-annotation` on any frame.

---

## Consolidated: data model, content ownership, admin portal, images, questions

This part pulls together the per-cluster sections above. Field-level tables are in each cluster's "Data model implied".

### Data entities the v1.1 design needs

**Editorial (portal / CMS; all localised vi + en with the same ids, D-012; all with status, reviewer, reviewedAt and sources)**
| Entity | Key fields shown in the app | Clusters |
|---|---|---|
| AgeStage (thẻ theo tuổi) | age window (weeks or months; "3–4 tuần", "1–2 tháng"), list title, detail headline, short headline for Today (three variants drawn), hero and thumb image, "Bé đang thế nào" bullets, "Ba mẹ có thể thử" bullets, Today tips (2), linked milestones, linked articles, "Cập nhật MM/YYYY" | A1, 2a–2b, 5h |
| ReferenceMilestone | title, group (Vận động / Giao tiếp / Nhận thức / Cảm xúc – xã hội), reference age range in months, "Cách nhận biết" text, illustration (≈ 2:1), order | 2b, 3a–3b |
| WonderWeekPhase | number 1–10, title, week window from the due date (leap 1 does not follow the week formula; store day offsets), common signs, "Bé đang học gì", "Ba mẹ có thể", short sign chips for logging, reminder title and body, days before (3) | A1, 6b–6e |
| Article | library (chăm bé / ăn dặm), content type (Bài viết / Hướng dẫn từng bước / Hỏi nhanh / Công thức), topic, age range, reading minutes, cover image, byline and "rà soát MM/YYYY", body blocks (paragraph, heading, bullet list, figure with caption, "Khi nào nên hỏi bác sĩ" callout), related articles, version (drives the "đã được cập nhật" banner) | 4a–4f, 5f |
| Topic | label, icon, soft and ink tint, order (6 topics: Bú & sữa, Giấc ngủ, Mọc răng, Sốt & ốm vặt, Chăm hằng ngày, Phát triển) | 4a, 4c |
| Recipe | title, age range ("6–7 tháng"), total minutes, cover, ingredients (names only, no quantity), ordered steps, disclaimer, reviewer and month, feeding method (Truyền thống / BLW, filter only) | 5f–5g |
| Food (catalogue, inferred) | name, food group (Rau củ / Tinh bột / Đạm / Trái cây …), allergen flag?, minimum age? Needed for first-try detection and the 5e groups | 5c, 5e |
| FirstAidSituation | code (TH01…), group (4), order and age relevance ("Sắp xếp theo tuổi bé"), emergency flag (red Gọi 115), offline tag, title, card subline, lead, Icon/FA pictogram, hero Illus/FA image, variants (age: "Dưới 1 tuổi" / "Từ 1 tuổi"; condition: "Có dị vật"…), pre-warning banner, ordered steps (title, body, optional image, chips, tap-count), "Không được làm" bullets, "Đưa bé đi viện ngay khi" bullets, special blocks (seizure timer, jaundice comparison), keywords and synonyms for search, disclaimer | 7a–7i, TH01–TH24 |
| CprProtocol (per age band) | 110 compressions/min, 30:2, ≈ 4 cm, pause ≤ 10 s, 4 steps, cycle count | 7i |
| NutritionStage | age window, label, title, summary, timeline line, milk guide (ml per feed, feeds per day, daily reference range, max), sample day (Sáng/Trưa/Chiều/Tối/Đêm), focus nutrients with stage sublines and tags, tips, sources, review month | 9b, 9c, 9f |
| Nutrient | name, icon and tint, importance line, why, food chips, tip, by-age rows, warning, sources | 9d |
| SupplementCampaign | vitamin A: eligible 6–36 months, rounds (1–2/6, 1–2/12), place, default reminder (day before, 08:00) | 9g |
| GrowthRule ("quy tắc chuyên gia nhập từ portal") | measurement (WHO weight-for-age, by sex), condition (last 2 measurements below range; P3 inferred), suggestions, recheck days (14), CTAs | 9e |
| Emergency number | "115", per country (inferred config) | 7b, 7h, TH |

**Per baby (child data: never in logs, analytics or crash keys)**
| Entity | Fields |
|---|---|
| Baby (new fields) | **dueDate** (6a; Wonder Week basis), Wonder Week basis (dueDate or birthDate), **solids tracker enabled** (5a) + show on Today, DOB possibly optional (2c) |
| BabyMilestone | referenceId or custom name (≤ 80 in the design, ≤ 60 in the code), kind, state (following / observed), observedOn, derived age at observation, note, photos[], recordedBy, memoryId (link to Kỷ niệm) |
| WonderWeekNote | phase, date, sign chips[], note, sharedWithFamily (off by default), createdBy |
| MealEntry | slot (Sáng/Trưa/Chiều/Tối/Phụ), date and time, dish name, ingredients[] (FoodRef), derived first-try, amount (Vài thìa / ½ chén / 1 chén / custom value and unit), reaction (Thích / Bình thường / Chưa hợp), note, photo, recipeId? |
| TriedFood | food, group, first date, times tried, summary reaction (no allergy record anywhere) |
| SupplementDose | campaign, round, takenOn |
| Reminders (new kinds) | Wonder Week 3 days ahead (several recipients), vitamin A round, re-measure in 14 days (9e) |
| Derived only | current age stage, next or current leap and countdown, milk ml/day and 7-day average, growth band status, "Teddy đã có N mốc", Today "Ăn dặm hôm nay" summary |

**Per user (or member)**
- Today layout: section order and visibility, plus tiles. A2 has 6 rows: quick tiles, reminders, Wonder Week, age card, solids today, day rhythm.
- Saved items: articles, recipes and first-aid situations, with seenVersion for the update banner.
- Article feedback (Có / Chưa).
- Reader text size ("Aa").
- Wonder Week reminder opt-in.
- Family alert with location (7h "Báo cho cả nhà"). This is a new data type: sender, baby, situation, lat/lng, recipients.

### Static vs per-baby vs editorial (summary)
- **Static app copy (ARB):**
  - Screen titles, section headers, field labels, buttons, empty and offline banners.
  - Templates such as "Còn {n} ngày", "Hướng dẫn · {n} bài viết · {m} mốc", "Hợp với {baby} · {age}", "Lần đầu {date} · {n} lần".
  - Fixed callout headings ("Không được làm", "Đưa bé đi viện ngay khi"), "Gọi 115", "Dùng được khi không có mạng".
  - The milestone group names (a fixed enum).
- **Per-baby:** everything in the per-baby table above, plus the age-driven choices: which stage is "Bé đang ở đây", the default first-aid age variant, the first-aid sort order, and the current nutrition stage.
- **Editorial:**
  - Every content body in clusters 2, 3 (reference milestones), 4, 5 (recipes and guides), 6, 7 and 9.
  - Their images, and the taxonomies: topics, food groups, age bands, first-aid groups. Whether the taxonomies are editorial or fixed is an owner decision.
  - The disclaimers. They could be static, but they must name the reviewer if one is shown.

### Admin portal: what the content needs vs what B01–B10 cover
| Content | Portal frames today (`18-admin-portal-v1.md` §10, names only) | Gap |
|---|---|---|
| Articles (care library + solids guides) | B01 list, B02 editor (inferred), B03 review queue | Library/language filters exist in admin, not in the app. "Significant update" flag for the 4f banner. Alt text. Sources are shown in admin only. |
| Age cards | B05 list ("14 / 16 khoảng có thẻ"), B06 editor (title 60 chars, 3 + 3 points, related articles and milestones, audience Bố mẹ / Người chăm / Gia đình) | The app shows 3 headline variants per stage and a Today tip subset. The audience field explains why A5 (caregiver) has no age card. |
| Reference milestones | B07 list (4 groups, "Ba mẹ đã ghi" counts), B08 editor (review, 12-month re-review, sources) | Must be merged with the V1 memory presets `p_<slug>` (10h3) and custom milestones (10h4). The cross-family count needs privacy review. |
| Wonder Week | B09 list (10 phases, 0–80 weeks), B10 editor (weeks from due date, signs, reminder title and body, preview) | "Ba mẹ có thể" tips and the short sign chips are not in the B09/B10 summary. The app timeline ends at week 76. |
| Recipes, food catalogue | **none** | A Recipe editor: quantities, servings, texture, allergens, BLW tag, steps with images, food links. A Food catalogue with groups and allergens. |
| First aid (25 situations, CPR protocol, icons, illustrations) | **none** | A structured editor (variants, steps, callouts, emergency flag, keywords), an FA icon and illustration library, emergency number per country, and an offline content pack. |
| Nutrition stages, nutrients, vitamin A campaigns, growth rules | **none** (9c and 9e say "nhập từ Child Life portal") | Stage editor with milk numbers, nutrient articles, campaign dates per year, growth-rule thresholds. |
| Review workflow | B03 review queue covers articles, age cards, milestones and Wonder Weeks; A19 promises a "Biên tập" (Editor) role in v1.1 | Extend it to first aid, nutrition and recipes. Decide what the app displays: reviewer name, month, sources. |
| Images | none drawn as a media library | One media library with crops: 343 × 190 / 180 / 170 heroes, 52–64 px thumbs, 16:10 first-aid heroes. Alt text per locale. Licensing for the photographic images. |

### Images and illustrations used
- **Illustration/Photo** (131:758): "Illustrated baby photo placeholder (privacy-safe)". Used in clusters 2, 3, 4, 5 and 6. The rasters on its 143° pastel gradients (lavender, blue, mint, peach, yellow, navy) are **photographic stock baby images**: a crying newborn, a sleeping baby, a mother nose-to-nose with a baby, toys, a teddy bear with a basket, hands. They stand in for **editorial cover and hero photos**, and in 3c–3f for user photos. None of the recipe or meal images shows food.
- **Illus/FA/*** (first aid): 3D clay-style PNGs on pastel backgrounds, sourced from the `photo_demo` sheet (31 images). Some are reused across pages (TH02 → TH03, TH07 → TH09, TH04 → TH06; 7e reuses the infant back-blow image for 1 year and over). ✓ / ✗ badges are baked into some bitmaps (TH06 hero, TH08, TH10, TH17).
- **Icon/FA/*** (first aid): a new family of colourful flat pictograms in tinted circles (25 plus "Co giật do sốt" in search). They have no component description.
- **Illustration/BabyFace** (25:323) in the BabySwitcher. **Illustration/Mini/*** 3D objects on the Today CareTiles (unchanged).
- **Line icons** (SF Symbols in production): new uses are Icon/grid (Utilities tab), bookmark (filled and outline), phone, cake, eye, spark, drop, sunrise and journal.
- **Charts** drawn as shapes or flattened SVG: 9b range bar, 9c 14-day milk bars with the reference band, 9e WHO weight-for-age chart, 9f stage rail, 6b leap timeline.
- **Logo/App Icon** (35:239) on the 6d lock-screen notification.
- No emoji in the UI. The only emoji is 💛 in a user caption in 3e.

### Open questions (cross-cluster; per-cluster lists above have the detail)
1. **Navigation model.** NavBar v1.1 replaces Care with "Utilities" (grid), but 7a, 8a and 9a still draw the "Chăm sóc" hub and mark five of this page's features "Sớm ra mắt". What is the v1.1 IA, the tab label, and the combined hub (banner + Chi tiêu + Dinh dưỡng)?
2. **Scope.** Which clusters are V1.1, and which stay "Sớm ra mắt"? There are no D/R/P entries yet in `business-map.md` for age cards, milestones v1.1, the library, solids, Wonder Week, first aid or nutrition (Q-039 already flags the landing promises).
3. **Content review and liability.** Who reviews, which name and date are shown, and must sources be shown? This is uneven today: 2b, 4d, 5f, 5g and 9c show a month, 9c and 9d show sources, and first aid shows neither. Medical values (CPR 110/min and 30:2, milk ml, the P3 rule) need sign-off.
4. **Offline.** First aid promises "Dùng được khi không có mạng" on every page, and 2c shows a cached-content banner. Is content bundled in the app, or a versioned pack synced from the portal? What image weight is acceptable?
5. **Baby data model.** New `dueDate`. DOB optional (2c vs the required field in `createBabyRequestSchema`). Solids as a 7th tracker kind (family-wide or per-user Today?). The Wonder Week basis.
6. **Milestones vs memories.** Unify the V1 presets (`p_<slug>`), custom milestones (family-wide, R-105, 60 chars) and v1.1 reference and "Mốc riêng" milestones (per baby, 80 chars). Decide milestone photo storage and visibility before a memory exists.
7. **Push and family delivery.**
   - Wonder Week reminders go to several members ("Bạn, Ba Tuấn") and vitamin A reminders to "Mẹ, Bố". The "Báo cho cả nhà" alert sends the user's location.
   - R-091 says reminders are local to the creating device. Decide consent, location permission and recipients.
   - Notification copy must not leak child data (CLAUDE.md).
8. **Gọi 115.** Does it dial directly or open the 7h sheet first? What number is used for non-VN users? What is the emergency-page rule (TH19 and TH20 get the red buttons; TH13, TH16 and TH21 mention 115 only in text)?
9. **Safety gaps.** There is no allergy or reaction-symptom tracking in solids. Recipes have no allergens. The 9e growth rule needs corrected age for preterm babies.
10. **Taxonomy drift.**
    - Age bands differ across features: care library 0–3 / 3–6 / 6–12 / 1–2 tuổi; solids "6–7 tháng"; nutrition stages disagree between 9c, 9d and 9f.
    - Milk reference 600–900 ml vs 180–240 ml × 4–5 feeds.
    - Wonder Week ends at 76 weeks in the app vs 80 in the portal.
11. **"Wonder Weeks" brand and leap names.** This may need a licensing check, or a rename.
12. **States not drawn.**
    - Night care, except A7.
    - Caregiver and relative views, except A5.
    - Empty, error and loading states. Edit and delete for milestones, notes and meals.
    - The guided step mode beyond 7f/7g/7i.
    - Second variants: TH01 "Từ 1 tuổi", TH09 "Có dị vật", TH14 "Sưng, chảy máu".
    - The saved-items lists for first aid and recipes. The library's "Hướng dẫn từng bước" and "Hỏi nhanh" layouts.
13. **Mock ages conflict** across clusters (Teddy 3 weeks vs 7 months; Na 7 months), so the per-cluster numbers cannot all be one scenario.
14. **Tokens.** First-aid reds `#db4a45` / `#fcebe8` need `danger` / `danger-soft` / `on-danger` tokens with Night values. `care/pump/soft` is slash-named.

### Coverage
- `get_metadata` ×1 on `304:18`.
- `get_design_context` ×75, one per non-spending frame: part A 8, part B 13, part C 14, part D 16, part E 12, part F 12. 2a (`310:42550`) was read twice (once while testing the output format), so 76 calls were made in all.
- `get_screenshot` ×1 (`443:4088`).
- 0 failed calls, 0 rate-limit errors, no Figma write tools.
- All 90 frame screenshots and the asset sheet are in `img/v11/`. The 15 spending frames are covered by `19-spending.md`.
- Not read: the label text nodes (their names come from the metadata) and the 31 individual images inside `photo_demo` (names from the metadata, one screenshot of the sheet).

---

## Part G — Sơ cứu revision 2 (hands-free), 2026-10-12

Figma `sJLG1fAXKDnDr9YI6Yx8ex` (read-only), page **"v1.1"** (canvas `304:18`), cluster 7. Re-read on 2026-10-12 after the designer's "hands-free" revision. The designer's rule is that nothing in an emergency needs a tap. Step mode is gone, the counters are now static labels, the bottom bar is "Gọi 115" plus "Đọc to", the CPR page plays a metronome on its own, and 7h became an in-call state.

**Method.** `get_metadata` ×1 on `304:18` (saved and split per frame locally). `get_design_context` ×6: 7d `446:4290`, 7e `446:4394`, 7h `446:54981`, TH01 `446:4492`, TH02 `446:4604`, TH08 `446:5152`. `get_screenshot` ×10: the six above plus 7b `433:2879`, TH04 `446:4763`, TH19 `446:54503`, TH24 `446:54895`. 0 failures, 0 rate limits, no Figma write tool. For the other 20 TH pages, I compared the metadata only: every text layer's first 30 characters against Parts D–F, plus the bottom-bar, top-row, tag and block structure. Strings are the rendered text. Glosses in parentheses are engineering drafts. **(prototype link)** = `<a … cursor-pointer>`; targets are never exposed, so every target is inferred. **Annotations:** no `data-annotation` on any frame. **Night care:** none drawn; every frame is Light (`cloud #f6fcfb`).

**Designer note `claude/first-aid-v1.1.md`.** It is **not in the file**. No text, sticky or annotation frame on page v1.1 mentions it, and no layer name contains "claude", "note" or "first-aid". (Calling `get_metadata` without a node id lists only the pages "Cover" `0:1` and "Logo" `33:2`, yet `304:18` still resolves. I searched only v1.1.) There is nothing to transcribe.

Screenshots (overwritten or new) in `img/v11/`: `433-2879.png`, `446-4290.png`, `446-4394.png`, `446-4492.png`, `446-4604.png`, `446-4763.png`, `446-5152.png`, `446-54503.png`, `446-54895.png`, `446-54981.png`. Old PNGs for ids that no longer exist are left in place as history.

### G.1 Frame inventory: deleted, re-created, new

**Every detail page was re-created under a new id.** None of the old `427:*`, `429:2573…2848`, `433:3201…4423`, `433:53311…54284` or `434:3155` ids exists any more. Only 7a, 7b and 7c keep their ids.

| Frame | Old id (Parts D–F) | Current id | Status | Canvas (x, y) | Size |
|---|---|---|---|---|---|
| 7a · Chăm sóc · lối vào Sơ cứu | 429:2424 | 429:2424 | unchanged (metadata only) | 0, 9620 | 375 × 1411 |
| 7b · Sơ cứu | 433:2879 | 433:2879 | unchanged (same layers, same size; screenshot identical to the old one) | 415, 9620 | 375 × 2524 |
| 7c · Sơ cứu · Tìm kiếm | 428:2346 | 428:2346 | unchanged (metadata only) | 830, 9620 | 375 × 812 |
| 7d · Hóc dị vật · dưới 1 tuổi | 427:2048 | **446:4290** | redone | 1245, 9620 | 375 × 1835.75 |
| 7e · Hóc dị vật · từ 1 tuổi | 429:2573 | **446:4394** | redone | 1660, 9620 | 375 × 1650.75 |
| 7f · Từng bước · Vỗ lưng | 429:2711 | — | **deleted** | | |
| 7g · Từng bước · Ấn ngực | 429:2779 | — | **deleted** | | |
| 7h · Gọi 115 (sheet) | 429:2848 | — | **deleted**, replaced by ↓ | | |
| **7h · Đang gọi 115 (quay lại app)** (Calling 115, back in the app) | — | **446:54981** | **new** | 2075, 9620 | 375 × 2122.75 |
| 7i · CPR · Ép ngực (nhịp) | 434:3155 | — | **deleted** (the metronome moved into TH01) | | |
| TH01 · Hồi sức tim phổi (CPR) | 433:3201 | **446:4492** | redone (+ metronome card) | 0, 11800 | 375 × 1964.75 |
| TH02 · Sặc sữa | 433:3343 | 446:4604 | redone | 415, 11800 | 375 × 1831.125 |
| TH03 · Ngừng thở ở trẻ sinh non | 433:3483 | 446:4695 | redone | 830, 11800 | 375 × 1200.375 |
| TH04 · Co giật | 433:3566 | 446:4763 | redone | 1245, 11800 | 375 × 1749.375 |
| TH05 · Sốc phản vệ | 433:3699 | 446:4880 | redone | 1660, 11800 | 375 × 1278.375 |
| TH06 · Uống nhầm thuốc, hoá chất | 433:3793 | 446:4964 | redone | 2075, 11800 | 375 × 1889.125 |
| TH07 · Tai nạn giao thông | 433:3920 | 446:5055 | redone | 2490, 11800 | 375 × 1790.75 |
| TH08 · Chảy máu cam | 433:4047 | 446:5152 | redone | 2905, 11800 | 375 × 1479.75 |
| TH09 · Vết thương chảy máu | 433:4149 | 446:5231 | redone | 3320, 11800 | 375 × 1186.375 |
| TH10 · Băng bó cơ bản | 433:4234 | 446:5304 | redone | 3735, 11800 | 375 × 1418.375 |
| TH11 · Bỏng nước sôi | 433:4332 | 446:5389 | redone | 4150, 11800 | 375 × 1252.375 |
| TH12 · Bong gân | 433:4423 | 446:5467 | redone | 4565, 11800 | 375 × 1141.375 |
| TH13 · Gãy xương | 433:53311 | 446:54054 | redone | 0, 14000 | 375 × 1428.375 |
| TH14 · Tổn thương ở mắt | 433:53417 | 446:54143 | redone | 415, 14000 | 375 × 1366.375 |
| TH15 · Chó cắn | 433:53511 | 446:54230 | redone | 830, 14000 | 375 × 1229.375 |
| TH16 · Ong đốt | 433:53604 | 446:54308 | redone | 1245, 14000 | 375 × 1141.375 |
| TH17 · Kiến ba khoang | 433:53682 | 446:54372 | redone | 1660, 14000 | 375 × 1141.375 |
| TH18 · Côn trùng vào tai | 433:53759 | 446:54436 | redone | 2075, 14000 | 375 × 1099.375 |
| TH19 · Rắn cắn | 433:53833 | 446:54503 | redone | 2490, 14000 | 375 × 1275.375 |
| TH20 · Say nắng, say nóng | 433:53925 | 446:54585 | redone | 2905, 14000 | 375 × 1417.375 |
| TH21 · Đo thân nhiệt | 433:54033 | 446:54674 | redone | 3320, 14000 | 375 × 1354.375 |
| TH22 · Ngộ độc thực phẩm | 433:54128 | 446:54759 | redone | 3735, 14000 | 375 × 1173.375 |
| TH23 · Nhiễm lạnh | 433:54201 | 446:54827 | redone | 4150, 14000 | 375 × 1174.375 |
| TH24 · Vàng da sơ sinh | 433:54284 | 446:54895 | redone (**now has a bottom bar**) | 4565, 14000 | 375 × 1143.375 |

Labels are unchanged: `429:53390` "Label · 7 · Sơ cứu trẻ em (v1.1)" at y 9550, and the two overlapping row labels `433:54377` "… chi tiết 24 tình huống" and `429:53391` "… chi tiết 17 tình huống" (stale) at y 11730.

**Not drawn anywhere (searched by layer name):**
- a read-aloud "reading" or "paused" state, or any step highlight;
- a metronome paused or muted state;
- a collapsed "Nói với tổng đài" card;
- a call-ended state;
- an in-call variant for any page other than CPR;
- a notes or annotation frame.

### G.2 Shared changes (every page)

**Removed everywhere:** the primary Button "Làm theo từng bước" (Follow step by step) and so the whole guided step mode (7f/7g/7i). The "Gọi cấp cứu 115" interstitial sheet is gone too. Also gone are its "Báo cho cả nhà" (Notify the whole family) button and its location-push footnote.

**Unchanged everywhere** (except where noted below): the top row, tags, title, lead, hero, banner, segmented control, "Làm theo các bước" header, step cards, "Không được làm" / "Đưa bé đi viện ngay khi" / other callout boxes, and the disclaimer. Styles, tokens and raw hex are as documented in Parts E/F.
- Emergency pages keep the small top-right red **"Gọi 115"** pill (`#db4a45`, px 14 py 8, Icon/phone 16, Bold 14 white) as a **(prototype link)**.
- Normal pages keep the bookmark "save" button (not a link).

#### New bottom bar A — emergency pages
Used on 7d, 7e, TH01–TH07, TH19, TH20 (11 frames), plus the 7h variant below.
- Container: absolute at the bottom, `surface` white, shadow `0 −4 8 rgba(0,0,0,.08)`, pt 12 / pb 30 / px 16, **gap 10**, items centred, height **94** (was ≈ 98–100).
- **"Gọi 115"** (Call 115), big red pill **(prototype link)** on every emergency frame. Values:
  - flex 1 → **277 × 50**;
  - background raw **`#db4a45`**, radius 999, px 20 py 15, gap 8;
  - **Icon/phone 20** (white, asset `82062`) + "Gọi 115" Bold 16 white (raw `text-white`).
  - It is now the bar's primary element. Before, it was a secondary button beside "Làm theo từng bước".
- **"Đọc to"** (Read aloud), small square-ish pill, **not** a prototype link. Values:
  - **56 × 52**, `surface` white, **1 px `control-border #7e959a`**, radius 999, px 16 py 14;
  - **Icon/speaker 22** (new icon, asset `e88bc`, no component description returned);
  - **icon only**, with no visible label (needs an a11y label such as "Đọc to hướng dẫn"; inferred).
- Behaviour per the designer: "Gọi 115" **dials immediately** (`tel:115`, no sheet). Returning to the app shows the 7h state. "Đọc to" reads the guide aloud. Neither behaviour can be seen in Figma (prototype targets are not exposed).

#### New bottom bar B — normal pages
Used on TH08–TH18 and TH21–TH24 (15 frames).
- Same container (pt 12 / pb 30 / px 16, height 94).
- One full-width button **"Đọc to hướng dẫn"** (Read the guide aloud), **343 × 52**:
  - `surface` white, 1 px `control-border #7e959a`, radius 999, px 20 py 14, gap 8, centred;
  - **Icon/speaker 22** + label **Bold 16 `ink #173d44`**;
  - **not** a prototype link.
- It is an outlined, secondary-looking button, not the mint-deep primary Button (8:33). The bar has no primary action any more.
- **TH24 gained this bar** (before, it had no bottom bar because it has no steps). Read-aloud therefore applies to the callout lists too (inferred).

#### Read-aloud states
**Only the idle state is drawn**, on both sizes. Nothing shows "reading", "paused" or "stop", a progress indicator, a highlighted step, or auto-scroll.
- What the designer describes: the app reads the steps aloud and scrolls along with them.
- **Inferred:**
  - while reading, the button toggles to a stop or pause icon;
  - the step card being read is highlighted, for example with a mint-deep outline or `mint-soft` fill;
  - the page auto-scrolls to keep that card in view;
  - the reading order is title → lead → banner → steps → "Không được làm" → "Đưa bé đi viện ngay khi". Whether the disclaimer is read is unknown.
- None of this is in Figma.

#### Static count labels (replacing the tap-to-count dots and chips)
- Style (same as the old TH01 chip):
  - row "Nhịp" with pl 42 (aligned to the step text), gap 8;
  - pill px 10 py 4, radius 999, **Bold 12**;
  - count chip `mint-soft #e6f7f5` / `mint-text #06716d`;
  - rate chip `surface-2 #eef6f5` / `ink-muted #55707a`.
- **7d step 1** "Vỗ lưng 5 lần": **"× 5 lần"** (× 5 times). It replaces the 5 outlined 26 px circles plus "lần".
- **7d step 2** "Ấn ngực 5 lần": **"× 5 lần"**, placed **above** the step illustration. It replaces the 5 circles.
- **TH01 step 3** "Ép ngực 30 lần" (also in 7h): **"× 30 lần"** + **"100–120 lần/phút"** as two separate chips. Before, they were "× 30" + "100–120 lần/phút". The designer's summary "× 30 lần · 100–120 lần/phút" is drawn as two chips, not one string.
- No other page has count chips.

### G.3 446:54981 — 7h · Đang gọi 115 (quay lại app) (Calling 115, back in the app) — NEW

**What it is.** This is the CPR page (a copy of TH01) as it looks after the user tapped "Gọi 115", the phone dialled 115, and the user switched back to the app during the call. It replaces the old "Gọi cấp cứu 115" sheet; there is no longer any screen before dialling. **(inferred):** the same in-call state applies to every emergency page; only CPR is drawn.

**Text (reading order)**
1. StatusBar "9:41" / "•••".
2. Top row: back **(prototype link)** · spacer. The top-right **"Gọi 115" pill is still in the layer tree but `hidden`** (`446:54987`), so there is no call pill during a call.
3. Tags: "Khẩn cấp" · "Dùng được khi không có mạng".
4. Title "Hồi sức tim phổi (CPR)". Lead "Bé bất tỉnh, không thở hoặc thở ngáp".
5. Hero `Illus/FA/Ép tim sơ sinh`.
6. **Metronome card "Nhịp ép"**, the same as TH01 (see G.4).
7. **NEW card "Nói với tổng đài"** (Tell the operator):
   - Header: **"Nói với tổng đài"** · spacer · **Icon/chevron-down 16** (asset `9d6a9`).
   - Row **"Bé"** (Baby) → **"Teddy · 7 tháng · 7,8 kg"** (Teddy · 7 months · 7.8 kg).
   - Row **"Tình trạng"** (Condition) → **"Không thở, không phản ứng"** (Not breathing, not responding).
   - Row **"Địa chỉ"** (Address) → **"Vị trí hiện tại · đã gửi kèm"** (Current location · sent along).
8. Banner (sunshine-soft, Icon/alert): "Gọi 115 và bật loa ngoài trước khi bắt đầu. Có người khác: nhờ gọi giúp." (unchanged).
9. Segmented "Dưới 1 tuổi" (selected) | "Từ 1 tuổi". Neither segment is a link here.
10. "Làm theo các bước" and steps 1–4. The text is identical to TH01, including the "× 30 lần" and "100–120 lần/phút" chips on step 3 and the `Illus/FA/Mở đường thở` image on step 1.
11. "Không được làm": "Dừng ép ngực quá 10 giây" · "Ép trên bụng hoặc đầu xương ức".
12. "Đưa bé đi viện ngay khi": "Luôn gọi 115, kể cả khi bé đã thở lại".
13. Disclaimer (standard).
14. A stray empty text node `446:55111` (" ", 4 px) after the disclaimer. It is a design artefact; ignore it.
15. **Bottom bar (in-call variant):**
    - **"Đang gọi 115 · 00:42"** (Calling 115 · 00:42), call-status pill;
    - · the small **"Đọc to"** speaker button (56 × 52, as in bar A).

**"Đang gọi" pill** (`446:55092`)
- Specs:
  - takes the "Gọi 115" slot: flex 1 → **277 × 50**;
  - background raw **`#299966`** (green; no token in the code);
  - radius 999, px 20 py 15, gap 8;
  - **Icon/phone 20** white + "Đang gọi 115 · 00:42" **Bold 16 white**.
- It is **not** a prototype link.
- **(inferred):**
  - "00:42" is the elapsed call time (mm:ss), ticking every second;
  - tapping it returns to the system call screen, or does nothing;
  - the bar reverts to the red "Gọi 115" when the call ends.
- **Not drawn:** call ended, call failed, or a long call (≥ 1 h).

**"Nói với tổng đài" card** (`446:55093`)
- Card:
  - **343 × 121**, `surface` white, **1 px `control-border #7e959a`**, radius 20, px 16 py 14, vertical gap 8;
  - placed **between the metronome card and the banner**, near the top, so it is visible without scrolling (inferred intent).
- Header: "Nói với tổng đài" **Bold 15 `ink`**, spacer, Icon/chevron-down 16.
- Rows: each is label **Medium 13 `ink-muted`**, left · flexible spacer · value **SemiBold 13 `ink`**, right-aligned, one line, row gap 10.
- Fields:
  - **Bé**: the selected baby's name · age · latest weight. The designer's "age, weight" are merged into this one row. Source (inferred): the baby profile plus the latest growth log (7,8 kg matches 9b).
  - **Tình trạng**: a short condition phrase per situation. Here it is the CPR wording. Inferred: an editorial field per situation, e.g. `operatorSummary`.
  - **Địa chỉ**: "Vị trí hiện tại · đã gửi kèm". It implies the app got the device location and "sent it along". **To whom is not stated.** A `tel:` call cannot carry data to 115. Inferred: shown to the user to read out, and/or shared with family. This is a privacy/permission question; see G.7.
- **States:**
  - Only **expanded** is drawn. The chevron points **down** while expanded, which is ambiguous.
  - **(inferred):** collapsed = header row only (≈ 47 px tall), chevron toggles, and the default is expanded during a call.
  - The designer calls it "collapsible". The collapsed state is not drawn.
- Mock scenario changed: the old 7h sheet said "Bé Na · 7 tháng tuổi · 7,8 kg", and this card says **Teddy**.

**Navigation:** back **(prototype link)** only.

### G.4 446:4492 — TH01 · Hồi sức tim phổi (CPR) — redone with the auto metronome

**Text (reading order):** the same as Part E (433:3201), plus the new metronome card after the hero. The changes are:
- **New card "Nhịp ép"** (Compression rhythm), `446:4514`, placed between the hero and the banner:
  - 343 × 107, background raw **`#fcebe8`**, radius 20, px 16 py 14, gap 14, items centred.
  - **Beat disc "ring"**:
    - **56 px** solid circle, raw **`#db4a45`**;
    - centre text **"110"** Bold 18 white (the rate in beats/min; no unit shown);
    - a drop shadow `0 0 0 rgba(219,74,69,.35)`, with 0 blur and 0 spread, so it is invisible. **Inferred:** a placeholder for a pulsing halo that expands on each beat.
  - Text column (gap 3):
    - **"Nhịp ép đang phát · tự động"** (Compression beat playing · automatic), **Bold 15 `#db4a45`**.
    - `Bật loa, đặt điện thoại cạnh bé. Ép theo tiếng bíp. Sau mỗi 30 lần, app đọc "thổi ngạt 2 lần".`, **Medium 13 / 1.45 `ink`**. Gloss: Turn on the speaker, put the phone next to the baby. Press with the beep. After every 30, the app says "2 rescue breaths".
  - **Not interactive.** There is no link, no pause, no mute, no stop and no volume control.
  - Removed versus 7i: no compression count (18/30), no progress ring, no cycle counter, and no "Tiếp: thổi ngạt 2 lần" pill.
- **Step 3 chips:** "× 30" → **"× 30 lần"**. "100–120 lần/phút" is unchanged.
- **Bottom bar:** bar A ("Gọi 115" **(prototype link)** + "Đọc to"). Before, it was "Làm theo từng bước" + "Gọi 115", with the hotspot on the bar container. The prototype link now sits on "Gọi 115" itself.
- Everything else is word-for-word the same as Part E: the banner, segmented control (with "Từ 1 tuổi" still not drawn and not a link), steps 1–4, don'ts, seek-care and disclaimer.

**Metronome behaviour.** Per the designer; nothing below is drawn.

| Item | Value |
|---|---|
| Start | **automatically when the page opens**; no tap |
| Rate | **110 /min** (the disc says "110"), beat interval ≈ 545 ms |
| Output | beep through the **loudspeaker** ("Bật loa") |
| Breath prompt | every **30** beats the app **speaks "thổi ngạt 2 lần"** (2 rescue breaths) |
| Pause for breaths | not stated. **Inferred:** the beat pauses for about 2 breaths (≈ 3–5 s) and then resumes; or it never pauses (the designer says only "every 30 beats the app says…"). Needs a decision. |
| Visual sync | **inferred:** the disc pulses on each beat (the shadow placeholder) |
| Haptics / screen-on | no longer stated. 7i's "Tiếng bíp và rung theo nhịp" and "Màn hình luôn sáng…" copy is gone. Inferred: keep the wakelock and drop vibration (the phone lies beside the baby). |
| Stop | not drawn. **Inferred:** leaving the page stops it; no other control. |
| Interaction with read-aloud | not drawn. On TH01 both the metronome and "Đọc to" produce audio. Inferred: TTS ducks or pauses the beat, or reading is disabled while the beat plays. |
| During a 115 call (7h) | the card still says "đang phát", so the beat keeps playing while the user is on the phone (inferred). |
| Age variant | "Từ 1 tuổi" is not drawn. Inferred: the same 110/min. |

**Copy tension (flag).** The banner still says "Gọi 115 và bật loa ngoài **trước khi bắt đầu**" (… before you start), but the beat already starts on page open.

### G.5 446:4290 — 7d · Hóc dị vật · dưới 1 tuổi — redone

**Text (reading order):**
- Top: back **(prototype link)** · red "Gọi 115" pill **(prototype link)**.
- Tags "Khẩn cấp" · "Dùng được khi không có mạng". Title "Hóc dị vật". Lead "Bé ho sặc, không khóc, không thở được". Hero `Illus/FA/Vỗ lưng`.
- Banner: "Nếu bé còn ho, khóc được: để bé tự ho ra, không vỗ, theo dõi sát."
- Segmented: **"Dưới 1 tuổi"** (selected) | "Từ 1 tuổi" **(prototype link)** → 7e.
- "Làm theo các bước":
  1. "Vỗ lưng 5 lần" / "Đặt bé nằm sấp dọc cẳng tay, đầu thấp hơn ngực, đỡ cằm bé. Dùng gót bàn tay vỗ mạnh 5 lần giữa hai bả vai." + chip **"× 5 lần"**.
  2. "Ấn ngực 5 lần" / "Lật bé nằm ngửa, đầu thấp. Đặt 2 ngón tay giữa ngực, ngay dưới đường nối hai núm vú, ấn mạnh 5 lần." + chip **"× 5 lần"** + `Illus/FA/Ấn ngực` (asset `74615`).
  3. "Lặp lại đến khi dị vật ra" / "Xen kẽ 5 lần vỗ lưng và 5 lần ấn ngực. Bé lả đi, không thở: gọi 115 ngay."
- "Không được làm": "Thò tay vào miệng bé để móc dị vật" · "Dốc ngược bé lên".
- "Đưa bé đi viện ngay khi": "Bé tím tái, lả đi, ngừng thở: gọi 115" · "Đã lấy được dị vật nhưng bé vẫn ho, khó thở".
- Disclaimer (standard).
- Bottom bar A: "Gọi 115" **(prototype link)** + "Đọc to".

**Changes vs Part D (427:2048):**
- The count-dot rows became "× 5 lần" chips.
- "Làm theo từng bước" was removed.
- The top and bottom "Gọi 115" are now **both prototype links**; before, neither was linked.
- **Text: no change.**

### G.6 446:4394 — 7e · Hóc dị vật · từ 1 tuổi — redone

**Text:** the same as Part D. Segmented "Dưới 1 tuổi" **(prototype link)** → 7d | **"Từ 1 tuổi"** (selected). Steps:
1. "Đứng sau lưng bé" (+ `Illus/FA/Ép bụng`, asset `816ba`)
2. "Đặt nắm tay trên rốn"
3. "Ấn mạnh vào trong, lên trên"

There are still **no count chips**: no thrust count for ≥ 1 year. The don'ts, seek-care, banner and disclaimer are the same as 7d. Bottom bar A.

**Changes:**
- Bar A replaces "Làm theo từng bước" + "Gọi 115".
- Back, the top "Gọi 115" and the bottom "Gọi 115" are now **prototype links** (in Part D only the segment was linked).
- **Text: no change.**
- **Still open:** the hero is still the infant back-blow image `Illus/FA/Vỗ lưng`, which is wrong for ≥ 1 year (flagged in Part D).

### G.7 TH02–TH24 — what changed

Results of the full-text check (design_context: TH02, TH08) plus the metadata check (all others):

| Group | Frames | Top row | Bottom bar | Other change |
|---|---|---|---|---|
| Emergency | TH01–TH07, TH19, TH20 | back + red "Gọi 115" pill (link) | **bar A**: "Gọi 115" (link) + "Đọc to" icon button | TH01 only: metronome card + "× 30 lần" |
| Normal | TH08–TH18, TH21–TH23 | back + bookmark | **bar B**: "Đọc to hướng dẫn" full width | none |
| Information | TH24 | back + bookmark | **bar B (new; before: no bar)** | none |

- **TH04 seizure timer** (`446:4823` "Bấm giờ") is **unchanged**: Icon/clock tile, "Bấm giờ cơn giật", "00:00", Button "Bắt đầu" (Start). It still needs a tap to start, which conflicts with the hands-free principle (flag). Its running and stopped states are still not drawn.
- **TH02** (full read): text is word-for-word the same as Part E. The top and bottom "Gọi 115" are links.
- **TH08** (full read): text is the same as Part E, including the "Ngửa đầu (sai)" image inside the Don't box. Only back is linked; neither "save" nor "Đọc to hướng dẫn" is a link.
- **Content text:** **no step, callout, banner, title, lead, tag or disclaimer text changed on any of the 26 detail frames.**
  - 7d, 7e, TH01, TH02, TH08 and 7h were checked in full.
  - The other 20 pages were checked on the first 30 characters of every text layer, plus layer counts and block order. A change after the 30th character of a string would not be caught on those 20.
  - Block lists and frame heights match Parts E/F; the deltas are explained by the 94-px bar and TH01's +123-px metronome card.
  - Image layers and assets are the same.
- **Strings added:**
  - "Nhịp ép đang phát · tự động"
  - the metronome body
  - "× 5 lần"
  - "× 30 lần"
  - "Đọc to hướng dẫn"
  - "Nói với tổng đài", "Bé", "Tình trạng", "Địa chỉ"
  - "Teddy · 7 tháng · 7,8 kg"
  - "Không thở, không phản ứng"
  - "Vị trí hiện tại · đã gửi kèm"
  - "Đang gọi 115 · 00:42"
- **Strings removed** (they were in Parts D–E):
  - "Làm theo từng bước";
  - from 7f/7g: "Hóc dị vật · dưới 1 tuổi · Bước n/3", "Chạm để đếm", "3 / 5", "Màn hình luôn sáng trong khi bạn làm theo hướng dẫn.", "Quay lại", "Bước tiếp";
  - from 7i: "Hồi sức tim phổi · dưới 1 tuổi · Bước 3/4 · Chu kỳ 2", "2 ngón tay giữa ngực, ấn sâu khoảng 4 cm. Ấn theo nhịp tiếng bíp.", "110 nhịp/phút", "Tiếng bíp và rung theo nhịp", "Tiếp: thổi ngạt 2 lần", "Màn hình luôn sáng. Dừng ép không quá 10 giây.", "Tạm dừng", "Bé đã thở lại";
  - from the old 7h sheet: "Gọi cấp cứu 115", "Bé Na · 7 tháng tuổi · 7,8 kg", "Đang xử lý: Hóc dị vật", "Nói rõ với tổng đài" and its 4 checklist items, "Báo cho cả nhà", "Cả nhà nhận thông báo kèm vị trí của bạn.".
- **7b** (`433:2879`): unchanged. Its "Bắt đầu hồi sức tim phổi (CPR)" button pointed at 7i (inferred), which no longer exists. **Inferred:** it now opens TH01, where the metronome starts on its own. The "Gọi 115" button on 7b presumably dials directly as well.

### G.8 Tokens and components introduced

| Item | Value | Note |
|---|---|---|
| Icon/speaker | 22 px, asset `e88bc` | new icon; no component description |
| Icon/chevron-down | 16 px, asset `9d6a9` | used in the operator card |
| Call-active green | raw **`#299966`** | not a token. Needs e.g. `success` / `call-active` + `on-…` + a Night value |
| Danger pair (unchanged) | raw `#db4a45` / `#fcebe8`, now also on the metronome card | still no `danger` / `danger-soft` tokens |
| Outlined pill button | `surface` + 1 px `control-border` + radius 999 + Bold 16 `ink` | used for "Đọc to"; not the Button component 8:33 |
| Info card with key/value rows | `surface` + 1 px `control-border`, radius 20, rows Medium 13 muted / SemiBold 13 ink | "Nói với tổng đài" |
| Count chip | `mint-soft` / `mint-text` Bold 12 pill; rate chip `surface-2` / `ink-muted` | now the only count UI |

### G.9 Open questions raised by revision 2
1. **Read-aloud states and highlight are not drawn.** For idle → reading → paused/stopped: which icon or label, and does tapping again stop or pause? How is the current step highlighted? Does auto-scroll follow the reading? What is read (callouts? disclaimer?) Which TTS voice and language, vi or en (D-012)? Is a Vietnamese voice available **offline** on every device, given the page promises "Dùng được khi không có mạng"?
2. **Metronome control.** It starts on page open, with no visible stop or mute, so opening TH01 just to read about CPR makes it beep. Is that acceptable? Is there a pause for the 2 breaths? What happens when the app is backgrounded, when a 115 call is active (iOS/Android may duck app audio or route it to the earpiece during a cellular call), or when it plays at the same time as read-aloud?
3. **In-call detection.** "Đang gọi 115 · 00:42" needs call-state observation. On iOS that is CallKit `CXCallObserver`; on Android it needs `READ_PHONE_STATE` or a fallback. A fallback is to time from the tap and show the state until the user dismisses it. Should the state show on every emergency page or only on the one that started the call? What are the end, failed and long-call states?
4. **"Địa chỉ · Vị trí hiện tại · đã gửi kèm".** "Sent along" to whom? A `tel:` call can't transmit location. If it goes to the family (the old "Báo cho cả nhà"), that is a push with location and needs explicit consent, location permission and a privacy review. If it is only shown for the user to read out, the copy "đã gửi kèm" is wrong. The address text itself (a reverse-geocoded street) is not drawn.
5. **"Tình trạng" source.** Is it a per-situation editorial string (portal field) or a fixed ARB string? Only the CPR value is drawn.
6. **Collapsed operator card** is not drawn. What is the default state, and what is the chevron direction in each state?
7. **TH04 seizure timer** still requires "Bắt đầu". Should it auto-start or be removed under the no-tap rule?
8. **Banner copy** "trước khi bắt đầu" conflicts with the auto-start metronome (TH01, 7h).
9. **Non-emergency pages lost their primary action.** The bar now holds only an outlined secondary button. Intended?
10. **Designer note** `claude/first-aid-v1.1.md` is not in the Figma. Ask the designer for it, since it may hold the read-aloud and in-call rules not drawn here.
11. Unchanged carry-overs:
    - 7e hero image;
    - "Từ 1 tuổi" CPR content and TH09/TH14 second variants are still not drawn;
    - no Night care variant;
    - stale "17 tình huống" label.

### G.10 Coverage
- `get_metadata` ×1 (`304:18`), plus ×1 without a node id (page list).
- `get_design_context` ×6: `446:4290`, `446:4394`, `446:4492`, `446:4604`, `446:5152`, `446:54981`.
- `get_screenshot` ×10: `433:2879`, `446:4290`, `446:4394`, `446:4492`, `446:4604`, `446:4763`, `446:5152`, `446:54503`, `446:54895`, `446:54981`.
- 0 failures, 0 rate-limit errors, no Figma write tools.
