# Child Life — Launch Film V2.1

React + TypeScript + Remotion local trong pnpm workspace. Nguồn: [Figma V2](https://www.figma.com/design/sJLG1fAXKDnDr9YI6Yx8ex/Child-Life?node-id=824-1883), [S01 mới](https://www.figma.com/design/sJLG1fAXKDnDr9YI6Yx8ex/Child-Life?node-id=836-17931). Chỉ đọc/export Figma, không sửa thiết kế.

**90 giây · 30fps · 2700f · 11 cảnh · không voice-over.** Nền phim sáng; Night care được trình diễn như tính năng trong S09, không có bản dark riêng.

## Chạy local

Từ gốc repo (Node 22.12–22.x, pnpm 11.20):

```sh
pnpm install --filter child-life-launch-film
pnpm --filter child-life-launch-film run studio
pnpm --filter child-life-launch-film run scene S01
pnpm --filter child-life-launch-film run scene S08
pnpm --filter child-life-launch-film run scene S09-Vertical
pnpm --filter child-life-launch-film run render
pnpm --filter child-life-launch-film run render:vertical
pnpm --filter child-life-launch-film run typecheck
```

- Studio ngang: http://localhost:3010/ChildLifeLaunchV2
- Studio dọc: http://localhost:3010/ChildLifeLaunchV2Vertical
- Preview cảnh: `/S01` … `/S11`, hoặc `/S01-Vertical` … `/S11-Vertical`.
- MP4 preview hiện hành: `out/child-life-launch-v21-sound-design-preview.mp4`.
- Bản cũ 60s được giữ nguyên trong `out/`.

Bật âm thanh trong Studio để review. Lần đầu render trên máy khác, Remotion có thể tải Chrome Headless Shell.

Render một cảnh hoặc đoạn liên quan:

```sh
cd apps/launch-film
pnpm exec remotion render src/index.ts S08 out/S08-lumi-review.mp4 --codec=h264
pnpm exec remotion render src/index.ts ChildLifeLaunchV2 out/S09-night-care-review.mp4 --frames=2010-2249 --codec=h264
pnpm exec remotion still src/index.ts S01 out/S01-hero.png --frame=150
```

## Điểm chỉnh qua prompt

- `src/scenes/`: mỗi cảnh một component; số cảnh theo Figma. Semantic key trong `src/timeline.ts` giữ identity qua các lần đánh số lại.
- `src/timeline.ts`: thứ tự, điểm bắt đầu, thời lượng và chuyển cảnh.
- `src/animation.ts`: motion theo frame, giữ các mốc đọc và trạng thái START/MID/HERO/END.
- `src/Journey.tsx`: các layer độc lập của S01 hành trình mới.
- `src/design.ts` + `design/v2/figma-design.json`: copy, typography, màu, geometry và handoff từ Figma.
- `src/brand.ts`, `src/shared.tsx`: brand tokens, font local có delayRender, typography, thiết bị, sheet, ảnh và biểu đồ dùng chung.
- `src/assets.json`: mapping file local ↔ node/context Figma; scale export và điều chỉnh alpha root nếu cần.
- `src/audio/cues.ts`: **cue sheet thực thi** — cue ID, scene ID, frame bắt đầu, source offset, volume, fade, mục đích.
- `src/audio/SoundDesign.tsx`: track nhạc/SFX độc lập, envelope và khoảng lắng; preview cảnh lấy đúng đoạn trong toàn phim.

Chuyển động và âm lượng đều theo frame; không dùng CSS animation hoặc timer để quyết định trạng thái khi render.

## Âm thanh và quyền sử dụng

Đọc [AUDIO-CUE-SHEET.md](AUDIO-CUE-SHEET.md) trước khi chỉnh. Nhạc “Dream Culture” — Kevin MacLeod, CC BY 4.0; được biên tập thành các đoạn mở/phát triển/điểm nhấn/kết. SFX là tổng hợp DSP nguyên bản, có CC0 dedication, không dùng recording/sample hoặc dịch vụ trả phí. Nguồn và credit: [MUSIC-CREDITS.md](MUSIC-CREDITS.md). Ảnh: [PHOTO-CREDITS.md](PHOTO-CREDITS.md).

Dựng lại asset audio trên macOS arm64:

```sh
pnpm --filter child-life-launch-film run sound:prepare
```

Preview **chưa được agent nghe trực tiếp** vì công cụ không cung cấp đường nghe. Kiểm tra đo mức âm không thay thế review bằng tai; cần nghe cùng hình trước khi duyệt chất liệu, nhạc và transition.

## Tiếp tục phiên sau

Đọc [DECISIONS.md](DECISIONS.md). Giữ nguyên phần người dùng đã duyệt. Chỉ sửa cảnh/cue liên quan; cập nhật decision log khi chốt. Render đoạn khi cần; render cả phim khi được yêu cầu hoặc thay đổi toàn timeline. Bản dọc dùng HERO_9x16; chuyển động giữa các mốc được suy ra theo handoff vì Figma không có START/MID/END dọc.

Đã dùng [Remotion Agent Skills chính thức](https://www.remotion.dev/docs/ai/skills) (best-practices/create/markup/audio/sfx/render/Studio), cùng skill Figma design-to-code và figma-use. Giữ Remotion 4.0.529 đồng bộ với renderer có sẵn; không nâng cấp ứng dụng sản phẩm.
