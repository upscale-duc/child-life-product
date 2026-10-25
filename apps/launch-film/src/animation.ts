import { Easing, interpolate, spring } from 'remotion';
import { frameState, type Layer, type State } from './design';
import { timeline, type SceneId } from './timeline';
import type { Theme } from './theme';
import assets from './assets.json';
const clamp = { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' } as const;
export const progress = (f: number, a: number, b: number) =>
  interpolate(f, [a, Math.max(a + 1, b)], [0, 1], {
    ...clamp,
    easing: Easing.bezier(0.3, 0, 0, 1),
  });
const soft = (f: number, start: number, duration: number) =>
  spring({
    frame: f - start,
    fps: 30,
    durationInFrames: duration,
    config: { stiffness: 120, damping: 20, mass: 1 },
  });
const mix = (a: Layer, b: Layer, t: number): Layer => ({
  ...(t < 0.5 ? a : b),
  x: a.x + (b.x - a.x) * t,
  y: a.y + (b.y - a.y) * t,
  w: a.w + (b.w - a.w) * t,
  h: a.h + (b.h - a.h) * t,
  opacity: a.opacity + (b.opacity - a.opacity) * t,
  rotation: a.rotation + (b.rotation - a.rotation) * t,
  cornerRadius: (a.cornerRadius ?? 0) + ((b.cornerRadius ?? 0) - (a.cornerRadius ?? 0)) * t,
});
const hidden = (l: Layer): Layer => ({ ...l, opacity: 0 });
function blend(a: Layer[], b: Layer[], t: number): Layer[] {
  const names = [...new Set([...a, ...b].map((l) => l.name))];
  return names.map((n) => {
    const aa = a.find((l) => l.name === n),
      bb = b.find((l) => l.name === n);
    return mix(aa ?? hidden(bb!), bb ?? hidden(aa!), t);
  });
}
function states(id: SceneId, keys: [number, State][], f: number): Layer[] {
  let i = 0;
  while (i < keys.length - 2 && f >= keys[i + 1][0]) i++;
  return blend(
    frameState(id, keys[i][1]),
    frameState(id, keys[i + 1][1]),
    progress(f, keys[i][0], keys[i + 1][0]),
  );
}
export function sceneLayers(
  id: SceneId,
  f: number,
  vertical = false,
  theme: Theme = 'light',
): Layer[] {
  const info = timeline.find((s) => s.id === id)!;
  const role = (
    {
      S01: 'Vision',
      S02: 'S02',
      S03: 'S03',
      S04: 'QuickLog',
      S05: 'S04',
      S06: 'S05',
      S07: 'S06',
      S08: 'Lumi',
      S09: 'Today',
      S10: 'S07',
      S11: 'S08',
    } as const
  )[id];
  // V2.1 shortens only holds; the original animation clocks remain intact.
  if (id === 'S02' && f >= 96) f += 30;
  if (id === 'S06' && f >= 270) f += 30;
  if (id === 'S09' && f >= 150) f += 30;
  let layers: Layer[] = [];
  switch (role) {
    case 'S02':
      layers = states(
        id,
        [
          [0, 'START'],
          [26, 'HERO'],
          [126, 'HERO'],
          [150, 'END'],
        ],
        f,
      );
      break;
    case 'S03':
      layers = states(
        id,
        [
          [0, 'START'],
          [30, 'MID'],
          [72, 'MID'],
          [96, 'HERO'],
          [220, 'HERO'],
          [270, 'END'],
        ],
        f,
      );
      break;
    case 'S04':
      layers = states(
        id,
        [
          [0, 'START'],
          [28, 'HERO'],
          [126, 'HERO'],
          [156, 'END'],
          [240, 'END'],
        ],
        f,
      );
      break;
    case 'S05':
      layers = states(
        id,
        [
          [0, 'START'],
          [100, 'START'],
          [130, 'MID'],
          [170, 'MID'],
          [218, 'HERO'],
          [300, 'HERO'],
          [360, 'END'],
        ],
        f,
      );
      break;
    case 'S06':
      layers = states(
        id,
        [
          [0, 'START'],
          [44, 'HERO'],
          [170, 'HERO'],
          [210, 'END'],
        ],
        f,
      );
      break;
    case 'S07':
      layers = states(
        id,
        [
          [0, 'START'],
          [64, 'HERO'],
          [170, 'HERO'],
          [210, 'END'],
        ],
        f,
      );
      break;
    case 'S08':
      layers = states(
        id,
        [
          [0, 'START'],
          [40, 'HERO'],
          [75, 'HERO'],
          [114, 'END'],
          [240, 'END'],
        ],
        f,
      );
      break;
  }
  if (role === 'Vision')
    layers = states(
      id,
      [
        [0, 'START'],
        [130, 'HERO'],
        [196, 'HERO'],
        [240, 'END'],
      ],
      f,
    );
  if (role === 'QuickLog')
    layers = states(
      id,
      [
        [0, 'START'],
        [54, 'HERO'],
        [210, 'HERO'],
        [270, 'END'],
      ],
      f,
    );
  if (role === 'Lumi')
    layers = states(
      id,
      [
        [0, 'START'],
        [24, 'START'],
        [66, 'MID'],
        [150, 'MID'],
        [216, 'HERO'],
        [290, 'HERO'],
        [330, 'END'],
      ],
      f,
    );
  if (role === 'Today')
    layers = states(
      id,
      [
        [0, 'START'],
        [74, 'HERO'],
        [180, 'HERO'],
        [270, 'END'],
      ],
      f,
    );
  if (role === 'Vision' && f >= 224) {
    layers = layers.map((l) =>
      l.name === 'Illustration/Journey' ? { ...l, opacity: 1 - progress(f, 224, 240) } : l,
    );
    const photo = frameState('S02', 'START').find((l) => l.name.startsWith('Photo/'))!;
    const from = { ...photo, x: 822, y: 400, w: 276, h: 276, cornerRadius: 138, opacity: 0 };
    layers.push(mix(from, { ...photo, opacity: 1 }, progress(f, 224, 240)));
    const sun = frameState('S02', 'START').find((l) => l.name === 'Accent/Sun');
    if (sun) layers.push({ ...sun, opacity: progress(f, 230, 240) });
  }
  const get = (state: State, name: string) => frameState(id, state).find((l) => l.name === name)!;
  if (role === 'S02') {
    const start = get('HERO', 'AppScreen/NhatKy'),
      end = get('END', 'AppScreen/HomNay');
    const rect = mix(start, end, progress(f, 126, 150));
    layers = layers.filter((l) => !l.name.startsWith('AppScreen/'));
    layers.splice(
      2,
      0,
      {
        ...rect,
        name: 'AppScreen/NhatKy',
        opacity: (0.35 + 0.65 * progress(f, 0, 24)) * (1 - progress(f, 138, 150)),
      },
      { ...rect, name: 'AppScreen/HomNay', opacity: progress(f, 138, 150) },
    );
  }
  if (role === 'S03') {
    const start = get('START', 'AppScreen/HomNay'),
      mid = get('MID', 'AppScreen/GhiBuBinh'),
      hero = get('HERO', 'AppScreen/DaGhi'),
      end = get('END', 'AppScreen/DaGhi');
    const rect =
      f < 72
        ? mix(start, mid, progress(f, 0, 30))
        : f < 220
          ? mix(mid, hero, progress(f, 72, 96))
          : mix(hero, end, progress(f, 220, 270));
    layers = layers.filter((l) => !l.name.startsWith('AppScreen/'));
    layers.splice(
      2,
      0,
      { ...rect, name: 'AppScreen/HomNay', opacity: 1 - progress(f, 72, 84) },
      {
        ...rect,
        name: 'AppScreen/GhiBuBinh',
        opacity: progress(f, 12, 24) * (1 - progress(f, 72, 84)),
      },
      { ...rect, name: 'AppScreen/DaGhi', opacity: progress(f, 72, 84) },
    );
  }
  if (role === 'S05') {
    layers = layers.filter((l) => !l.name.startsWith('Headline'));
    const textState: State = f < 112 ? 'START' : f < 170 ? 'MID' : 'HERO';
    layers.push(...frameState(id, textState).filter((l) => l.name.startsWith('Headline')));
  }
  if (role === 'S08') {
    const previous = frameState('S10', 'END').find((l) => l.name === 'Accent/Sun')!;
    const sunEnd = { ...previous, x: 781.6, y: 138.7, w: 21.4, h: 21.4, opacity: 0 };
    layers = layers.filter((l) => l.name !== 'Accent/Sun');
    layers.splice(1, 0, mix(previous, sunEnd, progress(f, 0, 20)));
  }
  // Timings override Figma's still-state opacity so each editing unit has its own entrance.
  layers = layers.map((l) => {
    let opacity = l.opacity;
    let dy = 0;
    let enter: number | undefined;
    let exit: number | undefined;
    if (l.characters !== undefined) {
      const second = l.name === 'Headline/2';
      enter =
        role === 'Vision'
          ? 30
          : role === 'S02'
            ? second
              ? 60
              : 30
            : role === 'S03'
              ? 20
              : role === 'S04'
                ? 10
                : role === 'S05'
                  ? f < 112
                    ? second
                      ? 45
                      : 12
                    : second
                      ? 200
                      : 112
                  : role === 'S08'
                    ? l.name === 'SupportingText'
                      ? 84
                      : 28
                    : 30;
      if (role === 'Vision') enter = l.name === 'SupportingText' ? 96 : second ? 50 : 36;
      if (role === 'QuickLog' || role === 'Today') enter = second ? 42 : 30;
      if (role === 'Lumi') enter = f < 170 ? (second ? 48 : 30) : second ? 198 : 180;
      exit = role === 'S05' ? (f < 112 ? 100 : 300) : role === 'S02' ? 126 : info.exit;
      opacity = progress(f, enter, enter + 18) * (1 - progress(f, exit, exit + 8));
      dy = 24 * (1 - progress(f, enter, enter + 18)) - 16 * progress(f, exit, exit + 8);
    }
    if (role === 'S02' && l.name === 'Logo')
      opacity = progress(f, 8, 26) * (1 - progress(f, 126, 150));
    if (role === 'S03') {
      const chip = ['Card/Chip · Bú', 'Card/Chip · Ngủ', 'Card/Chip · Thay tã'].indexOf(l.name);
      if (chip >= 0) {
        enter = [40, 96, 110][chip];
        opacity = progress(f, enter, enter + 14) * (1 - progress(f, 220, 245));
        dy = 8 * (1 - progress(f, enter, enter + 14));
      }
      if (l.name === 'Accent/TapRing') opacity = progress(f, 60, 64) * (1 - progress(f, 72, 80));
      if (l.name === 'Accent/TileGlow') opacity = progress(f, 84, 96) * (1 - progress(f, 108, 120));
      if (l.name === 'Card/SavedToast') opacity = progress(f, 80, 92) * (1 - progress(f, 220, 245));
    }
    if (role === 'S04' && l.name === 'Card/GrowthChart' && f < 18) opacity *= progress(f, 0, 18);
    if (role === 'S04' && l.name === 'Headline') opacity *= 1 - progress(f, 222, 240);
    if (role === 'S05' && l.name.startsWith('Photo/')) {
      const i = Number(l.name.match(/Photo0(\d)/)?.[1] ?? 1) - 1;
      opacity *= progress(f, i * 4, i * 4 + 24);
      dy += 90 * (1 - progress(f, i * 4, i * 4 + 30));
    }
    if (role === 'S06' && l.name.startsWith('Card/Member/')) {
      const i = ['Me', 'Ba', 'NguoiCham', 'BaNoi'].indexOf(l.name.split('/')[2]);
      enter = 48 + i * 10;
      opacity *= progress(f, enter, enter + 18);
      dy = 16 * (1 - progress(f, enter, enter + 18));
    }
    if (role === 'S08' && l.name === 'Logo') opacity = progress(f, 10, 28);
    if (role === 'S08' && l.name === 'CTA') opacity = progress(f, 96, 114);
    if (role === 'Lumi' && l.characters !== undefined) {
      const out = f < 170 ? 150 : 290;
      opacity = progress(f, enter!, enter! + 18) * (1 - progress(f, out, out + 20));
    }
    if (role === 'QuickLog') {
      const chips = [
        'Card/Chip · Widget',
        'Card/Chip · Apple Watch',
        'Card/Chip · Màn hình khoá',
        'Card/Chip · Siri',
      ];
      const i = chips.indexOf(l.name);
      if (i >= 0) opacity *= progress(f, 60 + i * 8, 72 + i * 8);
      if (l.name === 'AppScreen/AppleWatch') {
        opacity *= progress(f, 70, 100);
        dy += 60 * (1 - progress(f, 70, 100));
      }
      if (l.name === 'AppScreen/LockScreen') opacity *= progress(f, 90, 120);
      if (l.name === 'Card/Siri') opacity = progress(f, 120, 150);
      if (l.name === 'Accent/TapRing') opacity = progress(f, 10, 14) * (1 - progress(f, 18, 22));
    }
    if (role === 'Today' && l.name === 'Card/GoiYHomNay') opacity *= progress(f, 44, 74);
    return {
      ...l,
      y: l.y + dy,
      opacity,
      textEnter: enter,
      siriAnswer: role === 'QuickLog' && f >= 210,
    };
  });
  const heroBase = frameState(id, 'HERO'),
    dark = frameState(id, 'HERO_DARK');
  if (theme === 'dark')
    layers = layers.map((l) => {
      const t = dark.find((t) => t.name === l.name),
        b = heroBase.find((t) => t.name === l.name);
      return t
        ? {
            ...l,
            color: t.color ?? l.color,
            x: l.x + (b ? t.x - b.x : 0),
            y: l.y + (b ? t.y - b.y : 0),
            children: l.name === 'Illustration/Journey' ? t.children : l.children,
          }
        : l;
    });
  if (vertical) {
    const hero = frameState(id, 'HERO'),
      v = frameState(id, 'HERO_9x16');
    layers = layers.map((l) => {
      const target = v.find((t) => t.name === l.name),
        base = hero.find((t) => t.name === l.name);
      if (l.name === 'Background') return { ...l, w: 1080, h: 1920 };
      if (target) {
        return {
          ...l,
          x: target.x + (base ? ((l.x - base.x) * 1080) / 1920 : 0),
          y: target.y + (base ? (l.y - base.y) * 0.6 : 0),
          w: target.w * (base ? l.w / base.w : 1),
          h: target.h * (base ? l.h / base.h : 1),
          fontSize: target.fontSize ?? l.fontSize,
          characters: target.characters ?? l.characters,
          letterSpacing: target.letterSpacing ?? l.letterSpacing,
          textAlignHorizontal: target.textAlignHorizontal ?? l.textAlignHorizontal,
          cornerRadius: target.cornerRadius ?? l.cornerRadius,
        };
      }
      // Figma has no vertical START/MID/END. Retain the same beats in the vertical canvas.
      return {
        ...l,
        x: l.x * 0.5,
        y: 540 + l.y * 0.6,
        w: l.w * 0.5,
        h: l.h * 0.5,
        fontSize: l.fontSize ? l.fontSize * 0.65 : undefined,
      };
    });
  }
  return layers.map((l) => {
    const scoped = l.name === 'AppScreen/HomNayV2' ? `${id}:` : '';
    const variant = l.name === 'AppScreen/HomNayV2' && id === 'S09' && f >= 225 ? ':END' : '';
    const key = `v2:${theme}:${scoped}${l.name}${variant}`;
    const fallback = `v2:light:${scoped}${l.name}${variant}`;
    const map = assets as Record<string, unknown>;
    const result = { ...l, assetKey: map[key] ? key : map[fallback] ? fallback : l.name };
    if (id === 'S09' && (l.name === 'AppScreen/HomNayV2' || l.name === 'Card/GoiYHomNay')) {
      const amount = progress(f, 80, 98) * (1 - progress(f, 138, 156));
      const nightKey = `v2:dark:${scoped}${l.name}`;
      return {
        ...result,
        alternateAssetKey: nightKey,
        alternateMix: amount,
        opacity: l.name.startsWith('AppScreen/') ? l.opacity + (1 - l.opacity) * amount : l.opacity,
      };
    }
    return result;
  });
}
