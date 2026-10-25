# Trạng thái đang làm — V2.1, 22/10/2026

## Chỉ dẫn hiện hành của người dùng

- Cập nhật toàn bộ video theo Figma V2, page `824:1883`, và S01 mới `836:17931` (V2.1). Chỉ đọc/export Figma, không sửa canvas.
- Hướng music-driven product motion; **không voice-over**. Nhạc có mở/phát triển/cao trào/kết, khoảng lắng, SFX chọn lọc theo hành động. Audio track độc lập; cue tập trung để sửa qua prompt.
- **Không làm phiên bản dark riêng.** Video giữ nền sáng; lồng ghép Night care như tính năng trong S09 (màn Hôm nay + thẻ gợi ý chuyển sang Night care rồi trở lại). Các frame dark Figma chỉ là nguồn cho UI feature này. Không đăng ký composition dark.
- Không mua nhạc hoặc dùng dịch vụ trả phí. Giữ bản MP4 cũ.

## Timeline Figma mới nhất

1920×1080; bản dọc 1080×1920; 30fps; 2700f/90s.

| ID  | Nội dung                      | Thời gian | Frames |
| --- | ----------------------------- | --------- | ------ |
| S01 | Vision / hành trình           | 0–8s      | 240    |
| S02 | Intro                         | 8–12s     | 120    |
| S03 | Care                          | 12–21s    | 270    |
| S04 | QuickLog                      | 21–30s    | 270    |
| S05 | Grow                          | 30–38s    | 240    |
| S06 | Remember                      | 38–49s    | 330    |
| S07 | Family / bàn giao             | 49–56s    | 210    |
| S08 | Lumi                          | 56–67s    | 330    |
| S09 | Today + Night care feature    | 67–75s    | 240    |
| S10 | Personal / Tuần này của Teddy | 75–82s    | 210    |
| S11 | Brand / CTA                   | 82–90s    | 240    |

Các scene semantic key (`vision`, `grow`, `remember`…) trong timeline giữ identity qua lần đánh số lại của Figma. Snapshot cũ nằm ở `design/figma-design.json`; nguồn mới và changelog/handoff ở `design/v2/figma-design.json`. Nội dung text, geometry và màu đọc từ Figma. Không tự đổi thông điệp. CTA: “Khám phá Child Life”, “childlife.app · Sắp có trên iPhone & Android”; hold cuối >4s.

## Triển khai

- S01: Journey có layer mây/mặt trời/đồi/đường, chặng, chip và thẻ nổi riêng; camera zoom vào vòng 0–12 tháng. Chỉ 0–12 tháng là đang có; các chặng còn lại giữ đúng nhãn tương lai.
- Các cảnh mới: QuickLog (Widget, Apple Watch, lock screen, Siri); Lumi (ghi hộ và hỏi nhật ký); Today; bàn giao; Tuần này của Teddy; bộ ba điện thoại cuối.
- Handoff cũ còn vài dòng timing chuyển cảnh 60s; tiêu đề panel + ghi chú V2.1 + tên frame mới có ưu tiên. Rút thời gian giữ S02/S06/S09, không rút thời gian đọc mới.
- Vertical chỉ có HERO, không có bộ START/MID/END dọc. Dùng geometry HERO dọc và suy ra motion theo timing ngang.
- Một số PNG giới hạn delivery MCP ở kích thước thấp hơn @2x; scale thực tế có trong mapping. Không coi bản preview là xuất bản cuối về chất lượng ảnh.
- Có frame Figma Night care S03 bị collapse chiều cao các tile ngay trong source; không dùng frame đó để tạo phiên bản riêng. Night care feature dùng UI Hôm nay V2 của S09.
- Các thẻ “Để ý tuần này” có nội dung nằm ngoài bounds của node cha trong Figma; đã xuất layer nội dung thật và giữ offset theo thiết kế, không xuất bitmap trong suốt.

## Audio và trạng thái review

- Cue sheet đã lập trước khi dựng: `AUDIO-CUE-SHEET.md`.
- Nhạc Dream Culture — Kevin MacLeod, CC BY 4.0, nguồn local, tempo 76 BPM; cắt thành 8 câu/đoạn riêng. Đoạn kết dùng đuôi kết thật của recording, không cắt ngang một câu đang phát triển. Nguồn và credit trong `MUSIC-CREDITS.md`.
- SFX nguyên bản bằng DSP, không dùng recording/sample bên ngoài; asset và code có CC0 dedication. Cue riêng cho save/widget/Siri/milestone/photos/handover/Lumi/Night care/logo. Không thêm tiếng cho mọi layer.
- Preview đang chờ người dùng nghe/duyệt. **Agent không có khả năng nghe trực tiếp trong môi trường công cụ này**; không được ghi đã nghe thực tế từ kết quả đo/render. Các nốt tonal và mối nối nhạc cần nghe cùng hình để chốt.
- Chưa có cue âm thanh nào được người dùng duyệt cụ thể. Khi sửa chỉ đổi cue được nêu, giữ các phần đã duyệt về sau.

## Nguồn và tiếp tục phiên mới

`README.md` có lệnh chạy. `src/audio/cues.ts` là điểm sửa audio; `src/timeline.ts` là timeline; `src/animation.ts` là motion; `src/Journey.tsx` là mở đầu mới; `src/assets.json` là mapping nguồn. Credits ảnh ở `PHOTO-CREDITS.md`. Trạng thái V1 được lưu trong `design/v1-decisions.md`.
