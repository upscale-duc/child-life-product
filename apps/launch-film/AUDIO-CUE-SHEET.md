# Child Life — cue sheet V2.1 (preview, chưa duyệt bằng tai)

90s · 30fps · 2700f · không voice-over. Video dùng nền sáng; Night care chỉ được trình diễn trong S09. Nhạc được cắt thành các đoạn riêng từ “Dream Culture” (Kevin MacLeod, CC BY 4.0), chỉnh 70→76 BPM giữ cao độ. Source offset và mọi cue nằm trong `src/audio/cues.ts`.

| Cảnh         | Thời gian | Nhạc                                                          | Cue gắn với hành động                                                 |
| ------------ | --------- | ------------------------------------------------------------- | --------------------------------------------------------------------- |
| S01 Vision   | 0–8s      | Piano mở thưa; chừa khoảng cho thông điệp                     | 0.80s chặng đầu; 2.07s một chặng tương lai; các chặng còn lại im lặng |
| S02 Intro    | 8–12s     | Vào câu nhạc có nhịp rõ, cut tại đầu ô nhịp nguồn             | Không thêm SFX cho chữ/logo                                           |
| S03 Care     | 12–21s    | Hạ nền quanh thao tác Lưu                                     | 14.20s soft tap; 14.67s dấu xác nhận toast                            |
| S04 QuickLog | 21–30s    | Câu nhạc mới cho cụm thiết bị                                 | 21.33s widget tap; 24s air ngắn cho lock screen; 25.40s xác nhận Siri |
| S05 Grow     | 30–38s    | Giữ nhịp nhưng thưa hiệu ứng                                  | 35s một nốt ấm khi milestone vào; không đánh tiếng từng chấm biểu đồ  |
| S06 Remember | 38–49s    | Mở rộng năng lượng khi ảnh thành kỷ niệm, tăng nhẹ gần 43.67s | 38.40s tiếng giấy cho cả cụm ảnh; 43.67s swell mềm cho thành phẩm     |
| S07 Family   | 49–56s    | Câu nhạc nhẹ hơn; một nhịp thở sau cao trào                   | 55s air nhỏ cho thẻ bàn giao; không gắn tiếng cho từng người          |
| S08 Lumi     | 56–67s    | Hai nhịp nội dung; hạ nền quanh chuyển nhịp                   | 57.60s dấu ghi nhận; 62.60s dấu trả lời; khoảng lắng ở giữa           |
| S09 Today    | 67–75s    | Dừng 0.4s trước câu mới, giảm năng lượng để xem UI            | 68.47s nhấc thẻ; 69.67s tap chuyển Night care; nền phim vẫn sáng      |
| S10 Personal | 75–82s    | Tiếp tục câu nhạc nhẹ, giữ không gian đọc                     | Không SFX                                                             |
| S11 Brand    | 82–90s    | Dùng **câu kết thật** ở cuối bản nhạc gốc, fade 86–90s        | 82.40s dấu âm logo mềm; để đuôi nhạc và khoảng trống cuối             |

## Cách sửa bằng prompt

Mỗi cue có `id`, `sceneId`, `localFrame`, `duration`, `sourceFrom`, `volume`, `fadeIn`, `fadeOut`, `purpose`. Track nhạc và SFX độc lập, hiển thị trong timeline Remotion. Preview cảnh tự lấy đúng đoạn âm thanh theo mốc tổng. Không giữ âm lượng đều suốt phim.

SFX là tổng hợp DSP nguyên bản, không dùng recording/sample bên ngoài. Bảy asset được dựng bằng `scripts/make-sfx.mjs`; mã nguồn và waveform có CC0 dedication. Các tiếng tap, giấy và air dùng envelope mềm, headroom trước khi mix. Các nốt tonal và logo vẫn cần nghe duyệt trong ngữ cảnh bài nhạc.

## Kiểm tra và giới hạn

Preview chưa phải bản sound design đã được nghe/chốt. Môi trường công cụ hiện tại không trả âm thanh cho agent nghe trực tiếp. Có thể kiểm tra timing cùng hình, codec, loudness, sample peak và fade, nhưng các phép đo không thay thế việc nghe. Cần nghe video bằng loa và tai nghe trước khi duyệt cảm giác, chất liệu và chuyển câu nhạc. Không tự ghi trạng thái “đã nghe” chỉ vì render thành công.
