import { Img } from 'remotion';
import { frameState, type Layer, cssColor } from './design';
import { progress } from './animation';
import { useTheme } from './theme';
import { asset, DeviceFrame } from './shared';
import assets from './assets.json';
export const Journey = ({ layer, frame }: { layer: Layer; frame: number }) => {
  const theme = useTheme();
  const hero = frameState('S01', theme === 'dark' ? 'HERO_DARK' : 'HERO').find(
    (l) => l.name === 'Illustration/Journey',
  )!;
  const landscape = hero.children!.find((l) => l.name === 'Accent/Landscape')!;
  const end = progress(frame, 196, 240);
  const render = (l: Layer) => {
    let opacity = l.opacity,
      dx = 0,
      dy = 0,
      scale = 1;
    if (l.name === 'Accent/Sun') {
      dy = 50 * (1 - progress(frame, 0, 30));
      opacity = 0.6 + 0.4 * progress(frame, 0, 30);
    }
    if (l.name === 'Accent/SunHalo') opacity = progress(frame, 0, 30);
    if (l.name.startsWith('Accent/Cloud/')) dx = 20 * Math.min(frame / 240, 1);
    if (l.name.startsWith('Card/Stage/')) {
      const i = ['0-12m', '1-3y', '3-6y', '6-12y'].indexOf(l.name.split('/')[2]);
      const t = [24, 45, 62, 80][i];
      const p = progress(frame, t, t + 14);
      opacity = p * (i === 0 ? 1 : 0.9) * (1 - end * (i === 0 ? 0 : 0.85));
      scale = 0.6 + 0.4 * p;
    }
    if (l.name.startsWith('Card/StageChip/')) {
      const i = ['0–12 tháng', '1–3 tuổi', '3–6 tuổi', '6–12 tuổi'].indexOf(l.name.split('/')[2]);
      const t = [30, 51, 68, 86][i];
      opacity = progress(frame, t, t + 12) * (1 - end * (i === 0 ? 0 : 0.85));
    }
    if (l.name.startsWith('Card/Float/')) {
      const i = l.name.includes('BuBinh') ? 0 : l.name.includes('VideoDayThang') ? 1 : 2;
      const p = progress(frame, 100 + i * 10, 118 + i * 10);
      opacity = p * (i === 2 ? 0.85 : 1) * (1 - end);
      dy = 16 * (1 - p) + (frame >= 130 ? 4 * Math.sin(((frame - 130) * Math.PI) / 30) : 0);
    }
    const key = `journey:${theme}:${l.name}`;
    const meta = (assets as Record<string, { file: string; width?: number; height?: number }>)[key];
    if (!meta || opacity <= 0) return null;
    const vector = meta.file.endsWith('.svg');
    const reveal = l.name === 'Accent/Path' || l.name === 'Accent/PathDash';
    const p = progress(frame, 20, 90);
    return (
      <div
        key={l.name}
        data-layer={l.name}
        style={{
          position: 'absolute',
          left: l.x + dx,
          top: l.y + dy,
          width: l.w,
          height: l.h,
          opacity,
          transform: `scale(${scale})`,
          transformOrigin: 'center',
          clipPath: reveal
            ? `polygon(0 100%,0 ${100 - p * 100}%,${p * 100}% 0,${p * 100}% 100%)`
            : undefined,
        }}
      >
        {vector ? (
          <div
            style={{
              width: meta.width,
              height: meta.height,
              transform: `scale(${l.w / (meta.width ?? l.w)},${l.h / (meta.height ?? l.h)})`,
              transformOrigin: 'top left',
            }}
          >
            <Img src={asset(key)} />
          </div>
        ) : (
          <DeviceFrame name={key} />
        )}
      </div>
    );
  };
  const stops = landscape.gradient
    ?.map((s) => `${cssColor(s.color)} ${s.position * 100}%`)
    .join(',');
  return (
    <div
      style={{
        position: 'relative',
        width: hero.w,
        height: hero.h,
        transform: `scale(${layer.w / hero.w},${layer.h / hero.h})`,
        transformOrigin: 'top left',
      }}
    >
      <div
        style={{
          position: 'absolute',
          left: landscape.x,
          top: landscape.y,
          width: landscape.w,
          height: landscape.h,
          borderRadius: landscape.cornerRadius,
          overflow: 'hidden',
          background: `linear-gradient(to bottom,${stops ?? '#fff5d9,#e0f5f0'})`,
        }}
      >
        {landscape.children!.map(render)}
      </div>
      {hero.children!.filter((l) => l.name !== 'Accent/Landscape').map(render)}
    </div>
  );
};
