# Product Introduction V2 — bản dựng Remotion

Nguồn: Figma `844:1883` (Child Life — Product Introduction V2) + handoff trong thư mục này (`README.md`, `script.en.md`, `storyboard.md`, `audio-cues.md`, `assets.md`, `timeline.json`). Chỉ đọc/export Figma.

## Chạy

```sh
pnpm --filter child-life-launch-film run studio:intro      # Studio: ProductIntroV2/ChildLifeIntroV2, PI01…PI10
pnpm --filter child-life-launch-film run render:intro      # out/intro/child-life-intro-v2.mp4
pnpm --filter child-life-launch-film run sfx:intro         # dựng lại SFX (DSP, CC0)
EDGE_TTS=/path/to/edge-tts pnpm --filter child-life-launch-film run vo:make -- en   # dựng lại VO tạm (en | vi)
pnpm --filter child-life-launch-film run render:intro:vi   # out/intro/child-life-intro-v2-vi.mp4
```

## Cấu trúc

| File | Vai trò |
|---|---|
| `src/intro/timeline.ts` | Phim **căn theo giọng đọc**: mỗi cảnh = lead + các câu VO (+ khoảng nghỉ) + tail. Đổi VO → cả phim tự căn lại. |
| `src/intro/choreo.ts` | Biên đạo từng cảnh: mỗi layer/chữ neo vào một câu VO (`s.cue('PI06b')`). |
| `src/intro/engine.tsx` | Nội suy START/HERO/END của layer cùng tên (vị trí, kích thước, xoay, opacity), spring/ease, pop-in, float nhẹ. |
| `src/intro/Thread.tsx` | `Accent/Thread` một nét duy nhất phía trên Series: vẽ dần (PI01), morph `threadPath`, nối qua mọi điểm cắt. |
| `src/intro/Extras.tsx` | Tương tác nhỏ: tap “+” widget, Siri “Saved”, vòng sáng Lumi, nút play “thở”. |
| `src/intro/audio/cues.ts` | **Cue sheet thực thi**: nhạc (đoạn nguồn, căn ô nhịp), SFX01–SFX11, mỗi cue neo vào VO/biên đạo. |
| `src/intro/audio/IntroAudio.tsx` | 3 stem độc lập (VO / nhạc / SFX), nhạc duck −6 dB khi có giọng. |
| `src/intro/layers.json` + `public/intro/layers/*.svg` | 63 layer export SVG từ Figma (đã bỏ nền frame, giữ bóng đổ), kèm toạ độ gốc. |
| `scripts/vo-script.json` | Câu VO, khoảng nghỉ, tốc độ đọc từng câu. |

## Âm thanh

- **VO tạm** (scratch): giọng neural `en-US-AvaNeural` qua `edge-tts`, mỗi câu một clip để giữ đúng khoảng nghỉ `[0.3s]…[0.8s]` của script. Chỉ dùng để duyệt nhịp; thay bằng bản thu thật (giữ id câu) rồi chạy lại `vo:make` hoặc thả wav vào `public/intro/vo/` và cập nhật `vo.json`. Quyền thương mại của giọng TTS này chưa được xác nhận.
- **Nhạc**: “Dream Culture” — Kevin MacLeod, CC BY 4.0 (xem `MUSIC-CREDITS.md`, cần ghi credit khi phát hành). Phân tích: D major, 76 BPM, downbeat 0.80 + 3.158·k s. Dựng 6 đoạn: mở piano → pulse vào đúng “And a lot to keep track of” → lắng (PI04) → câu mới trên “Meet Child Life” → mở rộng → cao trào PI09 rồi lắng ngay sau “treasure later” → câu kết thật của bản nhạc ngân dưới end card.
- **SFX**: tổng hợp DSP gốc (CC0), các nốt chime chỉ dùng D/F#/A cho hợp giọng nhạc. Không whoosh, không chuông thông báo dồn dập, không tiếng gõ phím cho Lumi.

## Giới hạn hiện tại

- Agent không nghe được âm thanh; mức âm được đo, nhưng cảm giác mix cần nghe duyệt bằng tai.
- Ảnh trong Figma là bản xem trước 960px (assets.md) — đủ cho preview; bản phát hành nên thay ảnh gốc.
- Các câu PI01/PI06/PI07 vẫn là **ĐỀ XUẤT**; các claim Siri, thẻ bàn giao, keepsake miễn phí cần product xác nhận (script.en.md).

## Bản tiếng Việt (`ChildLifeIntroV2-VI`)

- Cùng hình, nhạc, SFX; nhịp tự căn theo VO tiếng Việt (`scripts/vo-script.vi.json` → `src/intro/vo.vi.json`, giọng `vi-VN-HoaiMyNeural`, bản tạm). ~96,9 s.
- Chữ trên màn hình: `src/intro/i18n.tsx` (`tr()`); câu dài tự co cỡ chữ để không đè ảnh (`maxWidth`).
- Các layer Figma có chữ tiếng Anh (ghi chú PI02–05/PI10, bong bóng tin nhắn, chip chặng PI01, CTA) được dựng lại bằng code với màu/kích thước đọc từ SVG (`cardStyles.json`). UI app vốn đã là tiếng Việt.
- **Giữ nguyên tiếng Anh**: thẻ Siri (“Hey Siri… Log a bottle feed, 120 ml.”) vì Siri chưa hỗ trợ tiếng Việt — cần owner quyết.
- Lời dịch do engineering soạn (dựa script.en.md + câu chữ landing `vi.ts`: “Đang có trong app / Chặng tiếp theo / Trong tương lai”, “Cùng con lớn lên, đồng hành từng bước”, “Sắp có trên iPhone và Android”) — cần owner duyệt (D-012).

## Giọng ElevenLabs

```sh
export ELEVENLABS_API_KEY=...          # đặt trong shell của bạn, không commit
VO_PROVIDER=elevenlabs ELEVENLABS_VOICE_ID=<voice id EN> node scripts/make-vo.mjs en
VO_PROVIDER=elevenlabs ELEVENLABS_VOICE_ID=<voice id VI> node scripts/make-vo.mjs vi
pnpm run render:intro && pnpm run render:intro:vi
```

- Model mặc định `eleven_multilingual_v2` (đọc được cả EN và VI); đổi bằng `ELEVENLABS_MODEL` hoặc khối `elevenlabs` trong `vo-script*.json` (`voiceId`, `model`, `settings`).
- Mỗi câu gửi kèm `previous_text`/`next_text` để giọng liền mạch giữa các clip; `rate` từng câu được đổi sang `speed`.
- Bản thô lưu ở `design/vo-raw/elevenlabs[/vi]` (không lẫn với bản edge). Muốn tạo lại một câu: thêm id câu, ví dụ `… make-vo.mjs vi PI04c`.
- Quyền dùng thương mại: cần gói ElevenLabs trả phí (Starter trở lên) cho video phát hành.
