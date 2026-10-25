# Trạng thái — 22/10/2026

## Nguồn và phạm vi

- Figma file `sJLG1fAXKDnDr9YI6Yx8ex`, page `807:1883` là nguồn chính. Đã đọc metadata, context HERO cho cả 8 cảnh, HERO_9x16, các MID và panel handoff bằng Figma MCP; chỉ đọc/export, không sửa canvas.
- Handoff người dùng được lưu ở `design/user-handoff.md`. Snapshot geometry/copy/motion nằm trong `design/figma-design.json`; context tham chiếu nằm trong `design/context-*.txt`.
- Project tách tại `apps/launch-film`, dùng chung pnpm workspace. Các thay đổi đang có ở landing, mobile, portal, renderer không bị sửa.

## Thông số theo thiết kế

- 1920×1080; bản dọc 1080×1920; 30fps; 1800 frame / 60 giây.
- S01 150f; S02 150f; S03 270f; S04 240f; S05 360f; S06 210f; S07 210f; S08 210f.
- Chữ tiếng Việt và tagline tiếng Anh giữ nguyên. CTA “Khám phá Child Life”, URL childlife.app. Không dùng badge cửa hàng.
- Font Be Vietnam Pro local, các weight 400/500/600/700. Logo, màu, ảnh và UI từ Figma.
- Không thêm Lumi, paywall, đánh giá sức khoẻ, dải WHO, lời khuyên y khoa hoặc nội dung mới.

## Quyết định kỹ thuật của bản đầu — chưa phải người dùng đã duyệt

- 8 component riêng và 18 composition: 2 toàn phim + 8 cảnh ngang + 8 cảnh dọc.
- Keyframe START/MID/HERO/END làm mốc; text/card/chip có timing riêng theo handoff. Sheet Bú bình tách vùng y431–812 bằng clipping của asset gốc; growth chart giữ vector đường và các điểm riêng.
- Chuyển động frame-based, easing gentle và spring soft. Bridge AppScreen/Photo/Sun/Band dùng cùng cây layer ngoài Series.
- S01 END có x=1180 nhưng S02 START có x=1260: chọn vị trí S02 START cho điểm kết thúc bridge để tránh giật tại cut. S07 END sun 420px nhưng S08 START 300px: dùng 420px ở đầu S08, rồi thu vào vị trí mặt trời của logo. Các HERO không thay đổi vì quyết định này.
- Figma chỉ có HERO_9x16, không có START/MID/END dọc: giữ HERO dọc, suy ra chuyển động đầu/giữa/cuối theo cùng timing. Đây là điểm cần review khi chỉnh bản dọc.
- Dùng ảnh placeholder đúng Figma cho bản đầu; không tự thay ảnh. Đã thêm nhạc nền theo yêu cầu tiếp theo của người dùng; chưa thêm SFX.
- PNG chủ yếu @2x. DaGhi, AlbumGioTam và VideoPreview hiện @1x ở kích thước layer của phim do delivery ảnh lớn qua MCP bị bỏ khỏi response; vẫn lưu nguồn để xuất lại. A1–A3 gốc là raster theo handoff. Không gọi bản đầu là chất lượng phát hành.

## Chưa có phần được duyệt

Bản v1 là bản đầu để người dùng review. Không mặc định coi các quyết định kỹ thuật là phê duyệt nội dung/motion. Khi có yêu cầu chỉnh, ghi rõ cảnh, thay đổi và phần người dùng đã duyệt vào đây.

## Còn thiếu cho bản phát hành

1. Ảnh em bé/gia đình đã cấp quyền, độ phân giải cao; hiện ảnh từ Figma chỉ khoảng 220px.
2. Nếu cần độ nét UI cao hơn: A1–A3 @3x từ source screens và xuất lại ba asset @1x.
3. Nhạc nền đã có: “Dream Culture” — Kevin MacLeod, CC BY 4.0; credit ở MUSIC-CREDITS.md. Có thể thay track nếu người dùng yêu cầu.
4. Xác nhận phát hành trước khi đổi CTA sang “Tải Child Life” hoặc thêm store badges.

## Kiểm chứng bản đầu

- TypeScript: pass.
- 18 composition được CLI đăng ký thành công.
- Đã render và xem khung hình đại diện của 8 cảnh ngang/dọc, cùng các trạng thái sheet, polaroid, timeline và CTA; đã sửa thứ tự layer và độ đậm tagline.
- MP4 ngang render đủ 1800 frame. ffprobe xác nhận H.264, 1920×1080, 30/1 fps, 60.000 giây, 1800 frame, 11,178,679 byte.
- Studio đang chạy ở http://localhost:3010/ChildLifeLaunch; HTTP 200. Lệnh Studio đã mở browser hệ thống.
- Bản dọc đã render khung hình kiểm tra, chưa xuất toàn bộ MP4.

## Cập nhật theo yêu cầu: thêm nhạc — 22/10/2026

- Người dùng yêu cầu “nhớ thêm nhạc vào”. Đã thêm piano/percussion Dream Culture, chỉnh 70 → 76 BPM, giữ cao độ, normalize -20 LUFS với trần -2 dBTP. Tăng âm lượng nhẹ tại cao trào Remember 32.7s; fade-out 54–60s. Không thay hình, copy hoặc timing.
- Audio local dùng chung cho ngang/dọc và preview cảnh với đúng điểm bắt đầu; volume dựa trên frame Remotion.
- Bản mới: `out/child-life-launch-v2-music.mp4`; bản v1 im lặng được giữ lại.
- Giấy phép CC BY 4.0, nguồn chính và mirror tải được lưu trong MUSIC-CREDITS.md. Giữ credit khi phân phối video.

- Kiểm chứng bản có nhạc: TypeScript pass; render hoàn tất; ffprobe xác nhận H.264 1920×1080/30fps/1800 frame và AAC stereo 48kHz. Đã decode audio kiểm tra có tín hiệu giữa phim và fade xuống cuối. Video dài 60s; container có 53ms padding AAC.
